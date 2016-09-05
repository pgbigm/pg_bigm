-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION pg_bigm UPDATE TO '1.2'" to load this file. \quit

/* triConsistent function is available only in 9.4 or later */
DO $$
DECLARE
    pgversion INTEGER;
BEGIN
    SELECT current_setting('server_version_num')::INTEGER INTO pgversion;
    IF pgversion >= 90400 THEN
        CREATE FUNCTION gin_bigm_triconsistent(internal, int2, text, int4, internal, internal, internal)
        RETURNS "char"
        AS 'MODULE_PATHNAME'
        LANGUAGE C IMMUTABLE STRICT;
        ALTER OPERATOR FAMILY gin_bigm_ops USING gin ADD
            FUNCTION        6    (text, text) gin_bigm_triconsistent (internal, int2, text, int4, internal, internal, internal);
    END IF;
END;
$$;

/* Label whether the function is deemed safe for parallelism */
DO $$
DECLARE
    pgversion INTEGER;
BEGIN
    SELECT current_setting('server_version_num')::INTEGER INTO pgversion;
    IF pgversion >= 90600 THEN
        EXECUTE 'ALTER FUNCTION show_bigm(text) PARALLEL SAFE';
        EXECUTE 'ALTER FUNCTION bigm_similarity(text, text) PARALLEL SAFE';
        EXECUTE 'ALTER FUNCTION bigm_similarity_op(text, text) PARALLEL SAFE';
        EXECUTE 'ALTER FUNCTION gin_extract_value_bigm(text, internal) PARALLEL SAFE';
        EXECUTE 'ALTER FUNCTION gin_extract_query_bigm(text, internal, int2, internal, internal, internal, internal) PARALLEL SAFE';
        EXECUTE 'ALTER FUNCTION gin_bigm_consistent(internal, int2, text, int4, internal, internal, internal, internal) PARALLEL SAFE';
        EXECUTE 'ALTER FUNCTION gin_bigm_compare_partial(text, text, int2, internal) PARALLEL SAFE';
        EXECUTE 'ALTER FUNCTION bigmtextcmp(text, text) PARALLEL SAFE';
        EXECUTE 'ALTER FUNCTION likequery(text) PARALLEL SAFE';
        EXECUTE 'ALTER FUNCTION pg_gin_pending_stats(index regclass) PARALLEL SAFE';
        EXECUTE 'ALTER FUNCTION gin_bigm_triconsistent(internal, int2, text, int4, internal, internal, internal) PARALLEL SAFE';
    END IF;
END;
$$;
