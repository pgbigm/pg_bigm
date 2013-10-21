CREATE EXTENSION pg_bigm;

\pset null '(null)'

SET standard_conforming_strings = on;
SET escape_string_warning = off;
SET enable_seqscan = off;
SET pg_bigm.enable_recheck = on;
SET pg_bigm.gin_key_limit = 0;
SET pg_bigm.similarity_limit = 0.02;

-- tests for likequery
SELECT likequery('ポスグレの全文検索');
SELECT likequery('pg_bigmは検索性能を200%向上させました');

-- tests for show_bigm
SELECT show_bigm('木');
SELECT show_bigm('検索');
SELECT show_bigm('インデックスを作成');
SELECT show_bigm('pg_bigmは検索性能を200%向上させました');

-- tests for creation of full-text search index
CREATE INDEX test_bigm_idx ON test_bigm USING gin (col1 gin_bigm_ops);

\copy test_bigm(col1) from 'data/bigm_ja.csv' with csv

EXPLAIN (COSTS off) SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('値');
EXPLAIN (COSTS off) SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('最大');
EXPLAIN (COSTS off) SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('ツール');
EXPLAIN (COSTS off) SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('全文検索');

SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('値');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('最大');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('ツール');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('インデックスを作成');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('3-gramの全文検索');

-- check that the search results don't change if enable_recheck is disabled
-- in order to check that index full search is NOT executed
SET pg_bigm.enable_recheck = off;
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('値');
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery ('最大');
SET pg_bigm.enable_recheck = on;

SELECT col1 FROM test_bigm WHERE col1 LIKE '%最大%';

-- tests for pg_bigm.enable_recheck
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery('東京都');
SET pg_bigm.enable_recheck = off;
SELECT col1 FROM test_bigm WHERE col1 LIKE likequery('東京都');

SELECT bigm_similarity('東京都', ' 東京都 ');
SELECT bigm_similarity('東京都', '東京と京都');
SELECT bigm_similarity('東京と京都', '東京都');
SET pg_bigm.enable_recheck = on;

-- tests for text similarity search
EXPLAIN (COSTS off) SELECT col1 FROM test_bigm WHERE col1 =% '値';
EXPLAIN (COSTS off) SELECT col1 FROM test_bigm WHERE col1 =% '最大';
EXPLAIN (COSTS off) SELECT col1 FROM test_bigm WHERE col1 =% 'ツール';
EXPLAIN (COSTS off) SELECT col1 FROM test_bigm WHERE col1 =% '全文検索';

SELECT count(*), min(bigm_similarity(col1, '値')) FROM test_bigm WHERE col1 =% '値';
SELECT count(*), max(bigm_similarity(col1, '値')) FROM test_bigm WHERE NOT col1 =% '値';
SELECT count(*), min(bigm_similarity(col1, '最大')) FROM test_bigm WHERE col1 =% '最大';
SELECT count(*), max(bigm_similarity(col1, '最大')) FROM test_bigm WHERE NOT col1 =% '最大';
SELECT count(*), min(bigm_similarity(col1, 'ツール')) FROM test_bigm WHERE col1 =% 'ツール';
SELECT count(*), max(bigm_similarity(col1, 'ツール')) FROM test_bigm WHERE NOT col1 =% 'ツール';
SELECT count(*), min(bigm_similarity(col1, 'インデックスを作成')) FROM test_bigm WHERE col1 =% 'インデックスを作成';
SELECT count(*), max(bigm_similarity(col1, 'インデックスを作成')) FROM test_bigm WHERE NOT col1 =% 'インデックスを作成';
SELECT count(*), min(bigm_similarity(col1, '3-gramの全文検索')) FROM test_bigm WHERE col1 =% '3-gramの全文検索';
SELECT count(*), max(bigm_similarity(col1, '3-gramの全文検索')) FROM test_bigm WHERE NOT col1 =% '3-gramの全文検索';
