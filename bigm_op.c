/*-------------------------------------------------------------------------
 *
 * Portions Copyright (c) 2017-2024, pg_bigm Development Group
 * Portions Copyright (c) 2013-2016, NTT DATA Corporation
 * Portions Copyright (c) 2004-2012, PostgreSQL Global Development Group
 *
 * Changelog:
 *	 2013/01/09
 *	 Support full text search using bigrams.
 *	 Author: NTT DATA Corporation
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include <ctype.h>

#include "bigm.h"

#include "catalog/pg_type.h"
#include "tsearch/ts_locale.h"
#include "utils/array.h"
#include "utils/memutils.h"

PG_MODULE_MAGIC;

/* Last update date of pg_bigm */
#define	BIGM_LAST_UPDATE	"2015.09.10"

/* GUC variable */
bool	bigm_enable_recheck = false;
int		bigm_gin_key_limit = 0;
char	*bigm_last_update = NULL;

PG_FUNCTION_INFO_V1(show_bigm);
Datum		show_bigm(PG_FUNCTION_ARGS);

PG_FUNCTION_INFO_V1(bigmtextcmp);
Datum		bigmtextcmp(PG_FUNCTION_ARGS);

PG_FUNCTION_INFO_V1(likequery);
Datum		likequery(PG_FUNCTION_ARGS);

void		_PG_init(void);
void		_PG_fini(void);

void
_PG_init(void)
{
	/* Define custom GUC variables */
	DefineCustomBoolVariable("pg_bigm.enable_recheck",
							 "Recheck that heap tuples fetched from index "
							 "match the query.",
							 NULL,
							 &bigm_enable_recheck,
							 true,
							 PGC_USERSET,
							 0,
							 NULL,
							 NULL,
							 NULL);

	DefineCustomIntVariable("pg_bigm.gin_key_limit",
							"Sets the maximum number of bi-gram keys allowed to "
							"use for GIN index search.",
							"Zero means no limit.",
							&bigm_gin_key_limit,
							0,
							0, INT_MAX,
							PGC_USERSET,
							0,
							NULL,
							NULL,
							NULL);

	/* Can't be set in postgresql.conf */
	DefineCustomStringVariable("pg_bigm.last_update",
							   "Shows the last update date of pg_bigm.",
							   NULL,
							   &bigm_last_update,
							   BIGM_LAST_UPDATE,
							   PGC_INTERNAL,
							   GUC_REPORT | GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE,
							   NULL,
							   NULL,
							   NULL);

	EmitWarningsOnPlaceholders("pg_bigm");
}

void
_PG_fini(void)
{
}

static int
comp_bigm(const void *a, const void *b, void *arg)
{
	int			res;
	bool	   *haveDups = (bool *) arg;

	res = CMPBIGM(a, b);

	if (res == 0)
		*haveDups = true;

	return res;
}

static int
unique_array(bigm *a, int len)
{
	bigm	   *curend,
			   *tmp;

	curend = tmp = a;
	while (tmp - a < len)
		if (CMPBIGM(tmp, curend))
		{
			curend++;
			if (curend != tmp)
				memcpy(curend, tmp, BIGMSIZE);
			tmp++;
		}
		else
			tmp++;

	return curend + 1 - a;
}

#define iswordchr(c)	(!t_isspace(c))

/*
 * Finds first word in string, returns pointer to the word,
 * endword points to the character after word
 */
static char *
find_word(char *str, int lenstr, char **endword, int *charlen)
{
	char	   *beginword = str;

	while (beginword - str < lenstr && !iswordchr(beginword))
		beginword += pg_mblen(beginword);

	if (beginword - str >= lenstr)
		return NULL;

	*endword = beginword;
	*charlen = 0;
	while (*endword - str < lenstr && iswordchr(*endword))
	{
		*endword += pg_mblen(*endword);
		(*charlen)++;
	}

	return beginword;
}

#ifdef USE_WIDE_UPPER_LOWER
static void
cnt_bigram(bigm *bptr, char *str, int bytelen)
{
	CPBIGM(bptr, str, bytelen);
}
#endif

/*
 * Adds bigrams from words (already padded).
 */
static bigm *
make_bigrams(bigm *bptr, char *str, int bytelen, int charlen)
{
	char	   *ptr = str;

	if (charlen < 2)
	{
#ifdef USE_WIDE_UPPER_LOWER
		cnt_bigram(bptr, ptr, pg_mblen(str));
#else
		CPBIGM(bptr, ptr, 1);
#endif
		bptr->pmatch = true;
		bptr++;
		return bptr;
	}

#ifdef USE_WIDE_UPPER_LOWER
	if (pg_database_encoding_max_length() > 1)
	{
		int			lenfirst = pg_mblen(str),
					lenlast = pg_mblen(str + lenfirst);

		while ((ptr - str) + lenfirst + lenlast <= bytelen)
		{
			cnt_bigram(bptr, ptr, lenfirst + lenlast);

			ptr += lenfirst;
			bptr++;

			lenfirst = lenlast;
			lenlast = pg_mblen(ptr + lenfirst);
		}
	}
	else
#endif
	{
		Assert(bytelen == charlen);

		while (ptr - str < bytelen - 1 /* number of bigrams = strlen - 1 */ )
		{
			CPBIGM(bptr, ptr, 2);
			ptr++;
			bptr++;
		}
	}

	return bptr;
}

BIGM *
generate_bigm(char *str, int slen)
{
	BIGM	   *bgm;
	char	   *buf;
	bigm	   *bptr;
	int			len,
				charlen,
				bytelen;
	char	   *bword,
			   *eword;

	/*
	 * Guard against possible overflow in the palloc requests below.
	 * We need to prevent integer overflow in the multiplications here.
	 */
	if ((Size) slen > (MaxAllocSize - VARHDRSZ) / sizeof(bigm) - 1 ||
		(Size) slen > MaxAllocSize - 4)
		ereport(ERROR,
				(errcode(ERRCODE_PROGRAM_LIMIT_EXCEEDED),
				 errmsg("out of memory")));

	bgm = (BIGM *) palloc(VARHDRSZ + sizeof(bigm) * (slen + 1));
	SET_VARSIZE(bgm, VARHDRSZ);

	if (slen + LPADDING + RPADDING < 2 || slen == 0)
		return bgm;

	bptr = GETARR(bgm);

	buf = palloc(sizeof(char) * (slen + 4));

	if (LPADDING > 0)
	{
		*buf = ' ';
		if (LPADDING > 1)
			*(buf + 1) = ' ';
	}

	eword = str;
	while ((bword = find_word(eword, slen - (eword - str), &eword, &charlen)) != NULL)
	{
		bytelen = eword - bword;
		memcpy(buf + LPADDING, bword, bytelen);

		buf[LPADDING + bytelen] = ' ';
		buf[LPADDING + bytelen + 1] = ' ';

		/*
		 * count bigrams
		 */
		bptr = make_bigrams(bptr, buf, bytelen + LPADDING + RPADDING,
							charlen + LPADDING + RPADDING);
	}

	pfree(buf);

	if ((len = bptr - GETARR(bgm)) == 0)
		return bgm;

	/*
	 * Make bigrams unique.
	 */
	if (len > 1)
	{
		bool		haveDups = false;

		qsort_arg((void *) GETARR(bgm), len, sizeof(bigm), comp_bigm, (void *) &haveDups);
		if (haveDups)
			len = unique_array(GETARR(bgm), len);
	}

	SET_VARSIZE(bgm, CALCGTSIZE(len));

	return bgm;
}

/*
 * Extract the next non-wildcard part of a search string, ie, a word bounded
 * by '_' or '%' meta-characters, non-word characters or string end.
 *
 * str: source string, of length lenstr bytes (need not be null-terminated)
 * buf: where to return the substring (must be long enough)
 * *bytelen: receives byte length of the found substring
 * *charlen: receives character length of the found substring
 *
 * Returns pointer to end+1 of the found substring in the source string.
 * Returns NULL if no word found (in which case buf, bytelen, charlen not set)
 *
 * If the found word is bounded by non-word characters or string boundaries
 * then this function will include corresponding padding spaces into buf.
 */
static const char *
get_wildcard_part(const char *str, int lenstr,
				  char *buf, int *bytelen, int *charlen)
{
	const char *beginword = str;
	const char *endword;
	char	   *s = buf;
	bool		in_leading_wildcard_meta = false;
	bool		in_trailing_wildcard_meta = false;
	bool		in_escape = false;
	int			clen;

	/*
	 * Find the first word character, remembering whether preceding character
	 * was wildcard meta-character.  Note that the in_escape state persists
	 * from this loop to the next one, since we may exit at a word character
	 * that is in_escape.
	 */
	while (beginword - str < lenstr)
	{
		if (in_escape)
		{
			if (iswordchr(beginword))
				break;
			in_escape = false;
			in_leading_wildcard_meta = false;
		}
		else
		{
			if (ISESCAPECHAR(beginword))
				in_escape = true;
			else if (ISWILDCARDCHAR(beginword))
				in_leading_wildcard_meta = true;
			else if (iswordchr(beginword))
				break;
			else
				in_leading_wildcard_meta = false;
		}
		beginword += pg_mblen(beginword);
	}

	/*
	 * Handle string end.
	 */
	if (beginword - str >= lenstr)
		return NULL;

	/*
	 * Add left padding spaces if preceding character wasn't wildcard
	 * meta-character.
	 */
	*charlen = 0;
	if (!in_leading_wildcard_meta)
	{
		if (LPADDING > 0)
		{
			*s++ = ' ';
			(*charlen)++;
			if (LPADDING > 1)
			{
				*s++ = ' ';
				(*charlen)++;
			}
		}
	}

	/*
	 * Copy data into buf until wildcard meta-character, non-word character or
	 * string boundary.  Strip escapes during copy.
	 */
	endword = beginword;
	while (endword - str < lenstr)
	{
		clen = pg_mblen(endword);
		if (in_escape)
		{
			if (iswordchr(endword))
			{
				memcpy(s, endword, clen);
				(*charlen)++;
				s += clen;
			}
			else
			{
				/*
				 * Back up endword to the escape character when stopping at an
				 * escaped char, so that subsequent get_wildcard_part will
				 * restart from the escape character.  We assume here that
				 * escape chars are single-byte.
				 */
				endword--;
				break;
			}
			in_escape = false;
		}
		else
		{
			if (ISESCAPECHAR(endword))
				in_escape = true;
			else if (ISWILDCARDCHAR(endword))
			{
				in_trailing_wildcard_meta = true;
				break;
			}
			else if (iswordchr(endword))
			{
				memcpy(s, endword, clen);
				(*charlen)++;
				s += clen;
			}
			else
				break;
		}
		endword += clen;
	}

	/*
	 * Add right padding spaces if next character isn't wildcard
	 * meta-character.
	 */
	if (!in_trailing_wildcard_meta)
	{
		if (RPADDING > 0)
		{
			*s++ = ' ';
			(*charlen)++;
			if (RPADDING > 1)
			{
				*s++ = ' ';
				(*charlen)++;
			}
		}
	}

	*bytelen = s - buf;
	return endword;
}

/*
 * Generates bigrams for wildcard search string.
 *
 * Returns array of bigrams that must occur in any string that matches the
 * wildcard string.  For example, given pattern "a%bcd%" the bigrams
 * " a", "bcd" would be extracted.
 *
 * Set 'removeDups' to true if duplicate bigrams are removed.
 */
BIGM *
generate_wildcard_bigm(const char *str, int slen, bool *removeDups)
{
	BIGM	   *bgm;
	char	   *buf;
	bigm	   *bptr;
	int			len,
				charlen,
				bytelen;
	const char *eword;

	*removeDups = false;

	/*
	 * Guard against possible overflow in the palloc requests below.
	 * We need to prevent integer overflow in the multiplications here.
	 */
	if ((Size) slen > (MaxAllocSize - VARHDRSZ) / sizeof(bigm) - 1 ||
		(Size) slen > MaxAllocSize - 4)
		ereport(ERROR,
				(errcode(ERRCODE_PROGRAM_LIMIT_EXCEEDED),
				 errmsg("out of memory")));

	bgm = (BIGM *) palloc(VARHDRSZ + sizeof(bigm) * (slen + 1));
	SET_VARSIZE(bgm, VARHDRSZ);

	if (slen + LPADDING + RPADDING < 2 || slen == 0)
		return bgm;

	bptr = GETARR(bgm);

	buf = palloc(sizeof(char) * (slen + 4));

	/*
	 * Extract bigrams from each substring extracted by get_wildcard_part.
	 */
	eword = str;
	while ((eword = get_wildcard_part(eword, slen - (eword - str),
									  buf, &bytelen, &charlen)) != NULL)
	{
		/*
		 * count bigrams
		 */
		bptr = make_bigrams(bptr, buf, bytelen, charlen);
	}

	pfree(buf);

	if ((len = bptr - GETARR(bgm)) == 0)
		return bgm;

	/*
	 * Make bigrams unique.
	 */
	if (len > 1)
	{
		bool		haveDups = false;

		qsort_arg((void *) GETARR(bgm), len, sizeof(bigm), comp_bigm, (void *) &haveDups);
		if (haveDups)
		{
			*removeDups = true;
			len = unique_array(GETARR(bgm), len);
		}
	}

	SET_VARSIZE(bgm, CALCGTSIZE(len));

	return bgm;
}

Datum
show_bigm(PG_FUNCTION_ARGS)
{
	text	   *in = PG_GETARG_TEXT_P(0);
	BIGM	   *bgm;
	Datum	   *d;
	ArrayType  *a;
	bigm	   *ptr;
	int			i;

	bgm = generate_bigm(VARDATA(in), VARSIZE(in) - VARHDRSZ);
	d = (Datum *) palloc(sizeof(Datum) * (1 + ARRNELEM(bgm)));

	for (i = 0, ptr = GETARR(bgm); i < ARRNELEM(bgm); i++, ptr++)
	{
		text	   *item = cstring_to_text_with_len(ptr->str, ptr->bytelen);

		d[i] = PointerGetDatum(item);
	}

	a = construct_array(
						d,
						ARRNELEM(bgm),
						TEXTOID,
						-1,
						false,
						'i'
		);

	for (i = 0; i < ARRNELEM(bgm); i++)
		pfree(DatumGetPointer(d[i]));

	pfree(d);
	pfree(bgm);
	PG_FREE_IF_COPY(in, 0);

	PG_RETURN_POINTER(a);
}

Datum
likequery(PG_FUNCTION_ARGS)
{
	text	   *query = PG_GETARG_TEXT_PP(0);
	const char *str;
	int			len;
	const char *sp;
	text	   *result;
	char	   *rp;
	int			mblen;

	str = VARDATA_ANY(query);
	len = VARSIZE_ANY_EXHDR(query);

	if (len == 0)
		PG_RETURN_NULL();

	result = (text *) palloc((Size) len * 2 + 2 + VARHDRSZ);
	rp = VARDATA(result);
	*rp++ = '%';

	for (sp = str; (sp - str) < len;)
	{
		if (ISWILDCARDCHAR(sp) || ISESCAPECHAR(sp))
		{
			*rp++ = '\\';
			*rp++ = *sp++;
		}
		else if (IS_HIGHBIT_SET(*sp))
		{
			mblen = pg_mblen(sp);
			memcpy(rp, sp, mblen);
			rp += mblen;
			sp += mblen;
		}
		else
			*rp++ = *sp++;
	}

	*rp++ = '%';
	SET_VARSIZE(result, rp - VARDATA(result) + VARHDRSZ);

	PG_RETURN_TEXT_P(result);
}

Datum
bigmtextcmp(PG_FUNCTION_ARGS)
{
	text	   *arg1 = PG_GETARG_TEXT_PP(0);
	text	   *arg2 = PG_GETARG_TEXT_PP(1);
	char	   *a1p = VARDATA_ANY(arg1);
	char	   *a2p = VARDATA_ANY(arg2);
	int			len1 = VARSIZE_ANY_EXHDR(arg1);
	int			len2 = VARSIZE_ANY_EXHDR(arg2);

	PG_RETURN_INT32(bigmstrcmp(a1p, len1, a2p, len2));
}
