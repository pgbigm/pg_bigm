-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION pg_bigm UPDATE TO '1.2'" to load this file. \quit

/* triConsistent function is available only in 9.4 or later */
DO $$
DECLARE
    pgversion TEXT;
BEGIN
    SELECT current_setting('server_version_num') INTO pgversion;
    IF pgversion >= '90400' THEN
        CREATE FUNCTION gin_bigm_triconsistent(internal, int2, text, int4, internal, internal, internal)
        RETURNS "char"
        AS 'MODULE_PATHNAME'
        LANGUAGE C IMMUTABLE STRICT;
        ALTER OPERATOR FAMILY gin_bigm_ops USING gin ADD
            FUNCTION        6    (text, text) gin_bigm_triconsistent (internal, int2, text, int4, internal, internal, internal);
    END IF;
END;
$$;
