-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION pg_bigm" to load this file. \quit

CREATE FUNCTION show_bigm(text)
RETURNS _text
AS 'MODULE_PATHNAME'
LANGUAGE C STRICT IMMUTABLE;

CREATE FUNCTION bigm_similarity(text, text)
RETURNS float4
AS 'MODULE_PATHNAME'
LANGUAGE C STRICT IMMUTABLE;

CREATE FUNCTION bigm_similarity_op(text,text)
RETURNS bool
AS 'MODULE_PATHNAME'
LANGUAGE C STRICT STABLE;  -- stable because depends on pg_bigm.similarity_limit

CREATE OPERATOR =% (
        LEFTARG = text,
        RIGHTARG = text,
        PROCEDURE = bigm_similarity_op,
        COMMUTATOR = '=%',
        RESTRICT = contsel,
        JOIN = contjoinsel
);

-- support functions for gin
CREATE FUNCTION gin_extract_value_bigm(text, internal)
RETURNS internal
AS 'MODULE_PATHNAME'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION gin_extract_query_bigm(text, internal, int2, internal, internal, internal, internal)
RETURNS internal
AS 'MODULE_PATHNAME'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION gin_bigm_consistent(internal, int2, text, int4, internal, internal, internal, internal)
RETURNS bool
AS 'MODULE_PATHNAME'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION gin_bigm_compare_partial(text, text, int2, internal)
RETURNS bool
AS 'MODULE_PATHNAME'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION bigmtextcmp(text, text)
RETURNS int4
AS 'MODULE_PATHNAME'
LANGUAGE C STRICT IMMUTABLE;

-- create the operator class for gin
CREATE OPERATOR CLASS gin_bigm_ops
FOR TYPE text USING gin
AS
        OPERATOR        1       pg_catalog.~~ (text, text),
        OPERATOR        2       =% (text, text),
        FUNCTION        1       bigmtextcmp (text, text),
        FUNCTION        2       gin_extract_value_bigm (text, internal),
        FUNCTION        3       gin_extract_query_bigm (text, internal, int2, internal, internal, internal, internal),
        FUNCTION        4       gin_bigm_consistent (internal, int2, text, int4, internal, internal, internal, internal),
        FUNCTION        5       gin_bigm_compare_partial (text, text, int2, internal),
        STORAGE         text;

CREATE FUNCTION likequery(text)
RETURNS text
AS 'MODULE_PATHNAME'
LANGUAGE C STRICT IMMUTABLE;

CREATE FUNCTION pg_gin_pending_stats(index regclass, OUT pages int4, OUT tuples int8)
RETURNS record
AS 'MODULE_PATHNAME'
LANGUAGE C STRICT IMMUTABLE;
