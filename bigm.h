/*-------------------------------------------------------------------------
 *
 * Portions Copyright (c) 2017-2022, pg_bigm Development Group
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
#ifndef __BIGM_H__
#define __BIGM_H__

#include "access/itup.h"
#include "storage/bufpage.h"
#include "utils/builtins.h"

/* GUC variable */
extern bool bigm_enable_recheck;
extern int	bigm_gin_key_limit;
extern double bigm_similarity_limit;
extern char	*bigm_last_update;

/* options */
#define LPADDING		1
#define RPADDING		1

/* operator strategy numbers */
#define LikeStrategyNumber			1
#define SimilarityStrategyNumber	2

typedef struct
{
	bool		pmatch;			/* partial match is required? */
	int8		bytelen;		/* byte length of bi-gram string */

	/*
	 * Bi-gram string; we assume here that the maximum bytes for a character
	 * are four.
	 */
	char		str[8];
}	bigm;

#define BIGMSIZE	sizeof(bigm)

static inline int
bigmstrcmp(char *arg1, int len1, char *arg2, int len2)
{
	int			i;
	int			len = Min(len1, len2);

	for (i = 0; i < len; i++, arg1++, arg2++)
	{
		if (*arg1 == *arg2)
			continue;
		if (*arg1 < *arg2)
			return -1;
		else
			return 1;
	}

	return (len1 == len2) ? 0 : ((len1 < len2) ? -1 : 1);
}

#define CMPBIGM(a,b) ( bigmstrcmp(((bigm *)a)->str, ((bigm *)a)->bytelen, ((bigm *)b)->str, ((bigm *)b)->bytelen) )

#define CPBIGM(bptr, s, len) do {		\
	Assert(len <= 8);				\
	memcpy(bptr->str, s, len);		\
	bptr->bytelen = len;			\
	bptr->pmatch = false;			\
} while(0);

#define ISESCAPECHAR(x) (*(x) == '\\')	/* Wildcard escape character */
#define ISWILDCARDCHAR(x) (*(x) == '%' || *(x) == '_')	/* Wildcard
														 * meta-character */
typedef struct
{
	int32		vl_len_;		/* varlena header (do not touch directly!) */
	char		data[1];
}	BIGM;

#define CALCGTSIZE(len) (VARHDRSZ + len * sizeof(bigm))
#define GETARR(x)		( (bigm *)( (char*)x + VARHDRSZ ) )
#define ARRNELEM(x) ( ( VARSIZE(x) - VARHDRSZ )/sizeof(bigm) )

extern BIGM *generate_bigm(char *str, int slen);
extern BIGM *generate_wildcard_bigm(const char *str, int slen, bool *removeDups);

#endif   /* __BIGM_H__ */
