/*-------------------------------------------------------------------------
 *
 * Portions Copyright (c) 2017-2022, pg_bigm Development Group
 * Portions Copyright (c) 2013-2016, NTT DATA Corporation
 * Portions Copyright (c) 2007-2012, PostgreSQL Global Development Group
 *
 * Changelog:
 *	 2013/01/09
 *	 Support full text search using bigrams.
 *	 Author: NTT DATA Corporation
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include "bigm.h"

#include "access/gin.h"
#include "access/gin_private.h"
#include "access/itup.h"
#if PG_VERSION_NUM >= 120000
#include "access/relation.h"
#endif
#include "access/skey.h"
#if PG_VERSION_NUM < 130000
#include "access/tuptoaster.h"
#endif
#include "access/xlog.h"
#if PG_VERSION_NUM > 90500
#include "catalog/pg_am.h"
#endif
#include "catalog/pg_type.h"
#include "funcapi.h"
#include "mb/pg_wchar.h"
#include "storage/bufmgr.h"
#include "storage/bufpage.h"
#include "tsearch/ts_locale.h"
#include "utils/array.h"
#include "utils/builtins.h"
#include "utils/rel.h"


PG_FUNCTION_INFO_V1(gin_extract_value_bigm);
PG_FUNCTION_INFO_V1(gin_extract_query_bigm);
PG_FUNCTION_INFO_V1(gin_bigm_consistent);
PG_FUNCTION_INFO_V1(gin_bigm_compare_partial);
PG_FUNCTION_INFO_V1(pg_gin_pending_stats);

/* triConsistent function is available only in 9.4 or later */
#if PG_VERSION_NUM >= 90400
PG_FUNCTION_INFO_V1(gin_bigm_triconsistent);
#endif

/*
 * The function prototypes are created as a part of PG_FUNCTION_INFO_V1
 * macro since 9.4, and hence the declaration of the function prototypes
 * here is necessary only for 9.3 or before.
 */
#if PG_VERSION_NUM < 90400
Datum		gin_extract_value_bigm(PG_FUNCTION_ARGS);
Datum		gin_extract_query_bigm(PG_FUNCTION_ARGS);
Datum		gin_bigm_consistent(PG_FUNCTION_ARGS);
Datum		gin_bigm_compare_partial(PG_FUNCTION_ARGS);
Datum		pg_gin_pending_stats(PG_FUNCTION_ARGS);
#endif

Datum
gin_extract_value_bigm(PG_FUNCTION_ARGS)
{
	text	   *val = (text *) PG_GETARG_TEXT_P(0);
	int32	   *nentries = (int32 *) PG_GETARG_POINTER(1);
	Datum	   *entries = NULL;
	BIGM	   *bgm;
	int32		bgmlen;

	*nentries = 0;

	bgm = generate_bigm(VARDATA(val), VARSIZE(val) - VARHDRSZ);
	bgmlen = ARRNELEM(bgm);

	if (bgmlen > 0)
	{
		bigm	   *ptr;
		int32		i;

		*nentries = bgmlen;
		entries = (Datum *) palloc(sizeof(Datum) * bgmlen);

		ptr = GETARR(bgm);
		for (i = 0; i < bgmlen; i++)
		{
			text	   *item = cstring_to_text_with_len(ptr->str, ptr->bytelen);

			entries[i] = PointerGetDatum(item);
			ptr++;
		}
	}

	PG_RETURN_POINTER(entries);
}

Datum
gin_extract_query_bigm(PG_FUNCTION_ARGS)
{
	text	   *val = (text *) PG_GETARG_TEXT_P(0);
	int32	   *nentries = (int32 *) PG_GETARG_POINTER(1);
	StrategyNumber strategy = PG_GETARG_UINT16(2);

	bool	  **pmatch = (bool **) PG_GETARG_POINTER(3);
	Pointer   **extra_data = (Pointer **) PG_GETARG_POINTER(4);

	/* bool   **nullFlags = (bool **) PG_GETARG_POINTER(5); */
	int32	   *searchMode = (int32 *) PG_GETARG_POINTER(6);
	Datum	   *entries = NULL;
	BIGM	   *bgm;
	int32		bgmlen = 0;
	bigm	   *ptr;
	int32		i;
	bool		removeDups;

	switch (strategy)
	{
		case LikeStrategyNumber:
		{
			char	   *str = VARDATA(val);
			int			slen = VARSIZE(val) - VARHDRSZ;
			bool	   *recheck;

			/*
			 * For wildcard search we extract all the bigrams that every
			 * potentially-matching string must include.
			 */
			bgm = generate_wildcard_bigm(str, slen, &removeDups);
			bgmlen = ARRNELEM(bgm);

			/*
			 * Check whether the heap tuple fetched by index search needs to
			 * be rechecked against the query. If the search word consists of
			 * one or two characters and doesn't contain any space character,
			 * we can guarantee that the index test would be exact. That is,
			 * the heap tuple does match the query, so it doesn't need to be
			 * rechecked.
			 */
			*extra_data = (Pointer *) palloc(sizeof(bool));
			recheck = (bool *) *extra_data;
			if (bgmlen == 1 && !removeDups)
			{
				const char *sp;

				*recheck = false;
				for (sp = str; (sp - str) < slen;)
				{
					if (t_isspace(sp))
					{
						*recheck = true;
						break;
					}

					sp += IS_HIGHBIT_SET(*sp) ? pg_mblen(sp) : 1;
				}
			}
			else
				*recheck = true;
			break;
		}
		case SimilarityStrategyNumber:
		{
			bgm = generate_bigm(VARDATA(val), VARSIZE(val) - VARHDRSZ);
			bgmlen = ARRNELEM(bgm);
			break;
		}
		default:
			elog(ERROR, "unrecognized strategy number: %d", strategy);
			bgm = NULL;			/* keep compiler quiet */
			break;
	}

	*nentries = (bigm_gin_key_limit == 0) ?
		bgmlen : Min(bigm_gin_key_limit, bgmlen);
	*pmatch = NULL;

	if (*nentries > 0)
	{
		entries = (Datum *) palloc(sizeof(Datum) * *nentries);
		ptr = GETARR(bgm);
		for (i = 0; i < *nentries; i++)
		{
			text	   *item;

			if (ptr->pmatch)
			{
				if (*pmatch == NULL)
					*pmatch = (bool *) palloc0(sizeof(bool) * *nentries);
				(*pmatch)[i] = true;
			}
			item = cstring_to_text_with_len(ptr->str, ptr->bytelen);
			entries[i] = PointerGetDatum(item);
			ptr++;
		}
	}

	/*
	 * If no bigram was extracted then we have to scan all the index.
	 */
	if (*nentries == 0)
		*searchMode = GIN_SEARCH_MODE_ALL;

	PG_RETURN_POINTER(entries);
}

Datum
gin_bigm_consistent(PG_FUNCTION_ARGS)
{
	bool	   *check = (bool *) PG_GETARG_POINTER(0);
	StrategyNumber strategy = PG_GETARG_UINT16(1);

	/* text    *query = PG_GETARG_TEXT_P(2); */
	int32		nkeys = PG_GETARG_INT32(3);

	Pointer    *extra_data = (Pointer *) PG_GETARG_POINTER(4);
	bool	   *recheck = (bool *) PG_GETARG_POINTER(5);
	bool		res;
	int32		i;
	int32		ntrue;

	switch (strategy)
	{
		case LikeStrategyNumber:

			/*
			 * Don't recheck the heap tuple against the query if either
			 * pg_bigm.enable_recheck is disabled or the search word is the
			 * special one so that the index can return the exact result.
			 */
			Assert(extra_data != NULL);
			*recheck = bigm_enable_recheck &&
				(*((bool *) extra_data) || (nkeys != 1));

			/* Check if all extracted bigrams are presented. */
			res = true;
			for (i = 0; i < nkeys; i++)
			{
				if (!check[i])
				{
					res = false;
					break;
				}
			}
			break;
		case SimilarityStrategyNumber:
			/* Count the matches */
			*recheck = bigm_enable_recheck;
			ntrue = 0;
			for (i = 0; i < nkeys; i++)
			{
				if (check[i])
					ntrue++;
			}

			/*--------------------
			 * If DIVUNION is defined then similarity formula is:
			 * c / (len1 + len2 - c)
			 * where c is number of common bigrams and it stands as ntrue in
			 * this code.  Here we don't know value of len2 but we can assume
			 * that c (ntrue) is a lower bound of len2, so upper bound of
			 * similarity is:
			 * c / (len1 + c - c)  => c / len1
			 * If DIVUNION is not defined then similarity formula is:
			 * c / max(len1, len2)
			 * And again, c (ntrue) is a lower bound of len2, but c <= len1
			 * just by definition and, consequently, upper bound of
			 * similarity is just c / len1.
			 * So, independently on DIVUNION the upper bound formula is the same.
			 */
			res = (nkeys == 0) ? false :
				((((float4) ntrue) / ((float4) nkeys)) >=
				  (float4) bigm_similarity_limit);
			break;
		default:
			elog(ERROR, "unrecognized strategy number: %d", strategy);
			res = false;		/* keep compiler quiet */
			break;
	}

	PG_RETURN_BOOL(res);
}

/* triConsistent function is available only in 9.4 or later */
#if PG_VERSION_NUM >= 90400
Datum
gin_bigm_triconsistent(PG_FUNCTION_ARGS)
{
	GinTernaryValue  *check = (GinTernaryValue *) PG_GETARG_POINTER(0);
	StrategyNumber strategy = PG_GETARG_UINT16(1);

	/* text    *query = PG_GETARG_TEXT_P(2); */
	int32		nkeys = PG_GETARG_INT32(3);
	Pointer    *extra_data = (Pointer *) PG_GETARG_POINTER(4);
	GinTernaryValue	res = GIN_MAYBE;
	int32		i,
				ntrue;

	switch (strategy)
	{
		case LikeStrategyNumber:
			/*
			 * Don't recheck the heap tuple against the query if either
			 * pg_bigm.enable_recheck is disabled or the search word is the
			 * special one so that the index can return the exact result.
			 */
			res = (bigm_enable_recheck &&
				   (*((bool *) extra_data) || (nkeys != 1))) ?
				GIN_MAYBE : GIN_TRUE;

			/* Check if all extracted bigrams are presented. */
			for (i = 0; i < nkeys; i++)
			{
				if (check[i] == GIN_FALSE)
				{
					res = GIN_FALSE;
					break;
				}
			}
			break;
		case SimilarityStrategyNumber:
			/* Count the matches */
			ntrue = 0;
			for (i = 0; i < nkeys; i++)
			{
				if (check[i] != GIN_FALSE)
					ntrue++;
			}

			/*
			 * See comment in gin_bigm_consistent() about upper bound formula
			 */
			res = (nkeys == 0) ? GIN_FALSE :
				(((((float4) ntrue) / ((float4) nkeys)) >=
				  (float4) bigm_similarity_limit) ? GIN_MAYBE : GIN_FALSE);

			if (res != GIN_FALSE && !bigm_enable_recheck)
				res = GIN_TRUE;
			break;
		default:
			elog(ERROR, "unrecognized strategy number: %d", strategy);
			res = GIN_FALSE;		/* keep compiler quiet */
			break;
	}

	PG_RETURN_GIN_TERNARY_VALUE(res);
}
#endif	/* PG_VERSION_NUM >= 90400 */

Datum
gin_bigm_compare_partial(PG_FUNCTION_ARGS)
{
	text	   *arg1 = PG_GETARG_TEXT_PP(0);
	text	   *arg2 = PG_GETARG_TEXT_PP(1);
	char	   *a1p;
	char	   *a2p;
	int			mblen1;
	int			mblen2;
	int			res;

	a1p = VARDATA_ANY(arg1);
	a2p = VARDATA_ANY(arg2);

	mblen1 = pg_mblen(a1p);
	mblen2 = pg_mblen(a2p);

	if (mblen1 != mblen2)
		PG_RETURN_INT32(1);

	res = memcmp(a1p, a2p, mblen1) ? 1 : 0;
	PG_RETURN_INT32(res);
}

/*
 * Report both number of pages and number of heap tuples that
 * are in the pending list.
 */
Datum
pg_gin_pending_stats(PG_FUNCTION_ARGS)
{
	Oid			indexOid = PG_GETARG_OID(0);
	Relation	indexRel;
	Buffer		metabuffer;
	Page		metapage;
	GinMetaPageData *metadata;
	Datum		values[2];
	bool		isnull[2];
	HeapTuple	tuple;
	TupleDesc	tupdesc;

	indexRel = relation_open(indexOid, AccessShareLock);

	if (indexRel->rd_rel->relkind != RELKIND_INDEX ||
		indexRel->rd_rel->relam != GIN_AM_OID)
		ereport(ERROR,
				(errcode(ERRCODE_WRONG_OBJECT_TYPE),
				 errmsg("relation \"%s\" is not a GIN index",
						RelationGetRelationName(indexRel))));

	/*
	 * Reject attempts to read non-local temporary relations; we would be
	 * likely to get wrong data since we have no visibility into the owning
	 * session's local buffers.
	 */
	if (RELATION_IS_OTHER_TEMP(indexRel))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("cannot access temporary indexes of other sessions")));

	/*
	 * Obtain statistic information from the meta page
	 */
	metabuffer = ReadBuffer(indexRel, GIN_METAPAGE_BLKNO);
	LockBuffer(metabuffer, GIN_SHARE);
	metapage = BufferGetPage(metabuffer);
	metadata = GinPageGetMeta(metapage);

	/*
	 * Construct a tuple descriptor for the result row. This must match this
	 * function's pg_bigm--x.x.sql entry.
	 */
 #if PG_VERSION_NUM >= 120000
	tupdesc = CreateTemplateTupleDesc(2);
#else
	tupdesc = CreateTemplateTupleDesc(2, false);
#endif
	TupleDescInitEntry(tupdesc, (AttrNumber) 1,
					   "pages", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 2,
					   "tuples", INT8OID, -1, 0);
	tupdesc = BlessTupleDesc(tupdesc);

	/* pages */
	values[0] = Int32GetDatum(metadata->nPendingPages);
	isnull[0] = false;

	/* tuples */
	values[1] = Int64GetDatum(metadata->nPendingHeapTuples);
	isnull[1] = false;

	UnlockReleaseBuffer(metabuffer);
	relation_close(indexRel, AccessShareLock);

	tuple = heap_form_tuple(tupdesc, values, isnull);
	PG_RETURN_DATUM(HeapTupleGetDatum(tuple));
}
