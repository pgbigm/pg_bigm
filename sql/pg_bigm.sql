CREATE EXTENSION pg_bigm;

\pset null '(null)'

SHOW pg_bigm.last_update;
SET pg_bigm.last_update = '2013.09.18';

SET standard_conforming_strings = on;

-- tests for likequery
SELECT likequery (NULL);
SELECT likequery ('');
SELECT likequery ('aBc023#*^&');
SELECT likequery ('ポスグレの全文検索');
SELECT likequery ('\_%');
SELECT likequery ('pg_bigmは検索性能を200%向上させました。');

-- tests for show_bigm
SELECT show_bigm (NULL);
SELECT show_bigm ('');
SELECT show_bigm ('i');
SELECT show_bigm ('ab');
SELECT show_bigm ('aBc023$&^');
SELECT show_bigm ('\_%');
SELECT show_bigm ('pg_bigm improves performance by 200%');
SELECT show_bigm ('木');
SELECT show_bigm ('検索');
SELECT show_bigm ('インデックスを作成');
SELECT show_bigm ('pg_bigmは検索性能を200%向上させました');

-- tests for full-text search
CREATE TABLE test_bigm (doc text, tag text);

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

CREATE INDEX test_bigm_idx ON test_bigm USING gin (doc gin_bigm_ops);
SET enable_seqscan = off;

EXPLAIN (COSTS off) SELECT doc FROM test_bigm WHERE doc LIKE likequery ('a');
EXPLAIN (COSTS off) SELECT doc FROM test_bigm WHERE doc LIKE likequery ('am');
EXPLAIN (COSTS off) SELECT doc FROM test_bigm WHERE doc LIKE likequery ('GIN');
EXPLAIN (COSTS off) SELECT doc FROM test_bigm WHERE doc LIKE likequery ('bigm');

SELECT doc FROM test_bigm WHERE doc LIKE likequery (NULL);
SELECT doc FROM test_bigm WHERE doc LIKE likequery ('');

SELECT doc FROM test_bigm WHERE doc LIKE likequery ('%');
SELECT doc FROM test_bigm WHERE doc LIKE likequery ('\');
SELECT doc FROM test_bigm WHERE doc LIKE likequery ('_');
SELECT doc FROM test_bigm WHERE doc LIKE likequery ('\dx');
SELECT doc FROM test_bigm WHERE doc LIKE likequery ('pg_bigm');
SELECT doc FROM test_bigm WHERE doc LIKE likequery ('200%');

SELECT doc FROM test_bigm WHERE doc LIKE likequery ('w');
SELECT doc FROM test_bigm WHERE doc LIKE likequery ('by');
SELECT doc FROM test_bigm WHERE doc LIKE likequery ('GIN');
SELECT doc FROM test_bigm WHERE doc LIKE likequery ('tool');
SELECT doc FROM test_bigm WHERE doc LIKE likequery ('Tool');
SELECT doc FROM test_bigm WHERE doc LIKE likequery ('performance');

EXPLAIN (COSTS off) SELECT doc FROM test_bigm WHERE doc LIKE likequery ('使');
EXPLAIN (COSTS off) SELECT doc FROM test_bigm WHERE doc LIKE likequery ('検索');
EXPLAIN (COSTS off) SELECT doc FROM test_bigm WHERE doc LIKE likequery ('ツール');
EXPLAIN (COSTS off) SELECT doc FROM test_bigm WHERE doc LIKE likequery ('全文検索');

SELECT doc FROM test_bigm WHERE doc LIKE likequery ('使');
SELECT doc FROM test_bigm WHERE doc LIKE likequery ('検索');
SELECT doc FROM test_bigm WHERE doc LIKE likequery ('ツール');
SELECT doc FROM test_bigm WHERE doc LIKE likequery ('インデックスを作成');
SELECT doc FROM test_bigm WHERE doc LIKE likequery ('3-gramの全文検索');

-- check that the search results don't change if enable_recheck is disabled
-- in order to check that index full search is NOT executed
SET pg_bigm.enable_recheck = off;
SELECT doc FROM test_bigm WHERE doc LIKE likequery ('w');
SELECT doc FROM test_bigm WHERE doc LIKE likequery ('by');
SELECT doc FROM test_bigm WHERE doc LIKE likequery ('使');
SELECT doc FROM test_bigm WHERE doc LIKE likequery ('検索');
SET pg_bigm.enable_recheck = on;

EXPLAIN (COSTS off) SELECT doc FROM test_bigm WHERE doc LIKE '%bigm%';
SELECT doc FROM test_bigm WHERE doc LIKE '%Tool%';
SELECT doc FROM test_bigm WHERE doc LIKE '%検索%';

EXPLAIN (COSTS off) SELECT doc FROM test_bigm WHERE doc LIKE '%\%';
SELECT doc FROM test_bigm WHERE doc LIKE '%\%';

EXPLAIN (COSTS off) SELECT doc FROM test_bigm WHERE doc LIKE 'pg\___gm%';
SELECT doc FROM test_bigm WHERE doc LIKE 'pg\___gm%';
