CREATE EXTENSION pg_bigm;

\pset null '(null)'

SET standard_conforming_strings = on;
SET escape_string_warning = off;
SET enable_seqscan = off;
SET pg_bigm.enable_recheck = on;
SET pg_bigm.gin_key_limit = 0;

-- tests for pg_bigm.last_update
SHOW pg_bigm.last_update;
SET pg_bigm.last_update = '2013.09.18';

-- tests for likequery
SELECT likequery(NULL);
SELECT likequery('');
SELECT likequery('  ');
SELECT likequery('aBc023#*^&');
SELECT likequery('\_%');

-- tests for show_bigm
SELECT show_bigm(NULL);
SELECT show_bigm('');
SELECT show_bigm('i');
SELECT show_bigm('ab');
SELECT show_bigm('aBc023$&^');
SELECT show_bigm('\_%');
SELECT show_bigm('  ');
SELECT show_bigm('pg_bigm improves performance by 200%');

-- tests for creation of full-text search index
CREATE TABLE test_bigm (col1 text, col2 text);
CREATE INDEX test_bigm_idx ON test_bigm
			 USING gin (col1 gin_bigm_ops, col2 gin_bigm_ops);

\copy test_bigm from 'data/bigm.csv' with csv

-- tests pg_gin_pending_stats
SELECT * FROM pg_gin_pending_stats('test_bigm_idx');
VACUUM;
SELECT * FROM pg_gin_pending_stats('test_bigm_idx');

-- tests for full-text search
EXPLAIN (COSTS off) SELECT * FROM test_bigm WHERE col1 LIKE likequery('a');
EXPLAIN (COSTS off) SELECT * FROM test_bigm WHERE col1 LIKE likequery('am');
EXPLAIN (COSTS off) SELECT * FROM test_bigm WHERE col1 LIKE likequery('XML');
EXPLAIN (COSTS off) SELECT * FROM test_bigm WHERE col1 LIKE likequery('bigm');

SELECT col1 FROM test_bigm WHERE col1 LIKE likequery(NULL);
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery('');

SELECT col1 FROM test_bigm WHERE col1 LIKE likequery('%');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery('\');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery('_');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery('\dx');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery('pg_bigm');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery('200%');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery('  ');

SELECT col1 FROM test_bigm WHERE col1 LIKE likequery('Y');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery('pi');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery('GIN');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery('gin');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery('Tool');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery('performance');

-- check that the search results don't change if enable_recheck is disabled
-- in order to check that index full search is NOT executed
SET pg_bigm.enable_recheck = off;
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery('Y');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery('pi');
SET pg_bigm.enable_recheck = on;

EXPLAIN (COSTS off) SELECT col1 FROM test_bigm WHERE col1 LIKE '%bigm%';
SELECT col1 FROM test_bigm WHERE col1 LIKE '%Tool%';
EXPLAIN (COSTS off) SELECT col1 FROM test_bigm WHERE col1 LIKE '%\%';
SELECT col1 FROM test_bigm WHERE col1 LIKE '%\%';
EXPLAIN (COSTS off) SELECT col1 FROM test_bigm WHERE col1 LIKE 'pg\___gm%';
SELECT col1 FROM test_bigm WHERE col1 LIKE 'pg\___gm%';

-- tests for pg_bigm.enable_recheck
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery('trial');
SET pg_bigm.enable_recheck = off;
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery('trial');

-- tests for pg_bigm.gin_key_limit
SELECT count(*) FROM test_bigm WHERE col1 LIKE likequery('she tore');
SET pg_bigm.gin_key_limit = 6;
SELECT count(*) FROM test_bigm WHERE col1 LIKE likequery('she tore');
SET pg_bigm.gin_key_limit = 5;
SELECT count(*) FROM test_bigm WHERE col1 LIKE likequery('she tore');
SET pg_bigm.gin_key_limit = 4;
SELECT count(*) FROM test_bigm WHERE col1 LIKE likequery('she tore');
SET pg_bigm.gin_key_limit = 3;
SELECT count(*) FROM test_bigm WHERE col1 LIKE likequery('she tore');
SET pg_bigm.gin_key_limit = 2;
SELECT count(*) FROM test_bigm WHERE col1 LIKE likequery('she tore');
SET pg_bigm.gin_key_limit = 1;
SELECT count(*) FROM test_bigm WHERE col1 LIKE likequery('she tore');

SET pg_bigm.enable_recheck = on;
SET pg_bigm.gin_key_limit = 0;

-- tests with standard_conforming_strings disabled
SET standard_conforming_strings = off;
SELECT likequery('\\_%');
SELECT show_bigm('\\_%');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery('\\');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery('\\dx');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery('200%');

-- tests for full text search with multi-column index
-- keyword exists only in col1. Query on col2 must not return any rows.
EXPLAIN (COSTS off) SELECT * FROM test_bigm WHERE col2 LIKE likequery('queries');
SELECT * FROM test_bigm WHERE col2 LIKE likequery('queries');
-- keyword exists only in col2. All rows with keyword in col2 are returned.
EXPLAIN (COSTS off) SELECT * FROM test_bigm WHERE col2 LIKE likequery('meta');
SELECT * FROM test_bigm WHERE col2 LIKE likequery('meta');
-- keyword exists in both columns. Query on col1 must not return rows with keyword in col2 only.
EXPLAIN (COSTS off) SELECT * FROM test_bigm WHERE col1 LIKE likequery('bigm');
SELECT * FROM test_bigm WHERE col1 LIKE likequery('bigm');

-- tests for bigm_similarity
SELECT bigm_similarity('wow', NULL);
SELECT bigm_similarity('wow', '');

SELECT bigm_similarity('wow', 'WOWa ');
SELECT bigm_similarity('wow', ' WOW ');
SELECT bigm_similarity('wow', ' wow ');

SELECT bigm_similarity('---', '####---');

-- tests for drop of pg_bigm
DROP EXTENSION pg_bigm CASCADE;
SELECT likequery('test');
