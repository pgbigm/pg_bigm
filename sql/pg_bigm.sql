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
SELECT likequery('aBc023#*^&');
SELECT likequery('ポスグレの全文検索');
SELECT likequery('\_%');
SELECT likequery('pg_bigmは検索性能を200%向上させました。');

-- tests for show_bigm
SELECT show_bigm(NULL);
SELECT show_bigm('');
SELECT show_bigm('i');
SELECT show_bigm('ab');
SELECT show_bigm('aBc023$&^');
SELECT show_bigm('\_%');
SELECT show_bigm('pg_bigm improves performance by 200%');
SELECT show_bigm('木');
SELECT show_bigm('検索');
SELECT show_bigm('インデックスを作成');
SELECT show_bigm('pg_bigmは検索性能を200%向上させました');

-- tests for creation of full-text search index
CREATE TABLE test_bigm (col1 text, col2 text);
CREATE INDEX test_bigm_idx ON test_bigm USING gin (col1 gin_bigm_ops);

INSERT INTO test_bigm VALUES ('pg_trgm - Tool that provides 3-gram full text search capability in PostgreSQL', 'pg_trgm');
INSERT INTO test_bigm VALUES ('pg_bigm - Tool that provides 2-gram full text search capability in PostgreSQL', 'pg_bigm');
INSERT INTO test_bigm VALUES ('pg_bigm has improved the full text search performance by 200%','pg_bigm performance');
INSERT INTO test_bigm VALUES ('You can create an index for full text search by using GIN index.', 'full text search');
INSERT INTO test_bigm VALUES ('\dx displays list of installed extensions', 'meta command');
INSERT INTO test_bigm VALUES ('\w FILE outputs the current query buffer to the file specified', 'meta command');
INSERT INTO test_bigm VALUES ('pg_trgm - PostgreSQLで3-gramの全文検索を使えるようにするツール', 'pg_trgm');
INSERT INTO test_bigm VALUES ('pg_bigm - PostgreSQLで2-gramの全文検索を使えるようにするツール', 'pg_bigm');
INSERT INTO test_bigm VALUES ('pg_bigmは検索性能を200%向上させました。', 'pg_bigm 検索性能');
INSERT INTO test_bigm VALUES ('GINインデックスを利用して全文検索用のインデックスを作成します。', '全文検索');
INSERT INTO test_bigm VALUES ('And she tore the dress in anger');
INSERT INTO test_bigm VALUES ('She sells sea shells on the sea shore');
INSERT INTO test_bigm VALUES ('Those orchids are very special to her');
INSERT INTO test_bigm VALUES ('Did you not see the wet floor sign?');
INSERT INTO test_bigm VALUES ('The stylist refused them politely');
INSERT INTO test_bigm VALUES ('You will get into deep trouble for staying out late');
INSERT INTO test_bigm VALUES ('He is awaiting trial');
INSERT INTO test_bigm VALUES ('It was a trivial mistake');
INSERT INTO test_bigm VALUES ('ここは東京都');
INSERT INTO test_bigm VALUES ('東京と京都に行く');

-- tests pg_gin_pending_stats
SELECT * FROM pg_gin_pending_stats('test_bigm_idx');
VACUUM;
SELECT * FROM pg_gin_pending_stats('test_bigm_idx');

-- tests for full-text search
EXPLAIN (COSTS off) SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('a');
EXPLAIN (COSTS off) SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('am');
EXPLAIN (COSTS off) SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('GIN');
EXPLAIN (COSTS off) SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('bigm');

SELECT col1 FROM test_bigm WHERE col1 LIKE likequery (NULL);
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('');

SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('%');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('\');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('_');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('\dx');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('pg_bigm');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('200%');

SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('w');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('by');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('GIN');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('tool');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('Tool');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('performance');

EXPLAIN (COSTS off) SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('使');
EXPLAIN (COSTS off) SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('検索');
EXPLAIN (COSTS off) SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('ツール');
EXPLAIN (COSTS off) SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('全文検索');

SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('使');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('検索');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('ツール');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('インデックスを作成');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('3-gramの全文検索');

-- check that the search results don't change if enable_recheck is disabled
-- in order to check that index full search is NOT executed
SET pg_bigm.enable_recheck = off;
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('w');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('by');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('使');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('検索');
SET pg_bigm.enable_recheck = on;

EXPLAIN (COSTS off) SELECT col1 FROM test_bigm WHERE col1 LIKE '%bigm%';
SELECT col1 FROM test_bigm WHERE col1 LIKE '%Tool%';
SELECT col1 FROM test_bigm WHERE col1 LIKE '%検索%';

EXPLAIN (COSTS off) SELECT col1 FROM test_bigm WHERE col1 LIKE '%\%';
SELECT col1 FROM test_bigm WHERE col1 LIKE '%\%';

EXPLAIN (COSTS off) SELECT col1 FROM test_bigm WHERE col1 LIKE 'pg\___gm%';
SELECT col1 FROM test_bigm WHERE col1 LIKE 'pg\___gm%';

-- tests for pg_bigm.enable_recheck
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery('trial');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery('東京都');

SET pg_bigm.enable_recheck = off;
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery('trial');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery('東京都');

-- tests for pg_bigm.gin_key_limit
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery('she tore');
SET pg_bigm.gin_key_limit = 6;
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery('she tore');
SET pg_bigm.gin_key_limit = 5;
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery('she tore');
SET pg_bigm.gin_key_limit = 4;
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery('she tore');
SET pg_bigm.gin_key_limit = 3;
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery('she tore');
SET pg_bigm.gin_key_limit = 2;
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery('she tore');
SET pg_bigm.gin_key_limit = 1;
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery('she tore');

SET pg_bigm.enable_recheck = on;
SET pg_bigm.gin_key_limit = 0;

-- tests with standard_conforming_strings disabled
SET standard_conforming_strings = off;
SELECT likequery('\\_%');
SELECT show_bigm('\\_%');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('\\');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('\\dx');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('200%');

-- tests for full text search with multi-column index
CREATE INDEX test_bigm_multi_idx ON test_bigm USING gin (col1 gin_bigm_ops, col2 gin_bigm_ops);
-- keyword exists only in col1. Query on col2 must not return any rows.
EXPLAIN (COSTS off) SELECT * FROM test_bigm WHERE col2 LIKE likequery('query');
SELECT * FROM test_bigm WHERE col2 LIKE likequery('query');
-- keyword exists only in col2. All rows with keyword in col2 are returned.
EXPLAIN (COSTS off) SELECT * FROM test_bigm WHERE col2 LIKE likequery('meta');
SELECT * FROM test_bigm WHERE col2 LIKE likequery('meta');
-- keyword exists in both columns. Query on col2 must not return rows with keyword in col1 only.
EXPLAIN (COSTS off) SELECT * FROM test_bigm WHERE col2 LIKE likequery('bigm');
SELECT * FROM test_bigm WHERE col2 LIKE likequery('bigm');

-- tests for bigm_similarity
SELECT bigm_similarity('wow', NULL);
SELECT bigm_similarity('wow', '');

SELECT bigm_similarity('wow', 'WOWa ');
SELECT bigm_similarity('wow', ' WOW ');
SELECT bigm_similarity('wow', ' wow ');

SELECT bigm_similarity('---', '####---');

SELECT bigm_similarity('東京都', ' 東京都 ');
SELECT bigm_similarity('東京都', '東京と京都');
SELECT bigm_similarity('東京と京都', '東京都');

-- tests for drop of pg_bigm
DROP EXTENSION pg_bigm CASCADE;
SELECT likequery('test');
