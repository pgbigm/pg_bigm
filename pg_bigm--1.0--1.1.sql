-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION pg_bigm UPDATE TO '1.1'" to load this file. \quit

ALTER EXTENSION pg_bigm DROP OPERATOR CLASS gin_trgm_ops USING gin;
DROP OPERATOR CLASS gin_trgm_ops USING gin;
