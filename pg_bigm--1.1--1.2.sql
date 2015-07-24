-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION pg_bigm UPDATE TO '1.2'" to load this file. \quit

CREATE FUNCTION gin_bigm_triconsistent(internal, int2, text, int4, internal, internal, internal)
RETURNS "char"
AS 'MODULE_PATHNAME'
LANGUAGE C IMMUTABLE STRICT;

ALTER OPERATOR FAMILY gin_bigm_ops USING gin ADD
        FUNCTION        6       gin_bigm_triconsistent (internal, int2, text, int4, internal, internal, internal);
