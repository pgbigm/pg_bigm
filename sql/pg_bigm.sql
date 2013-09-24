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
