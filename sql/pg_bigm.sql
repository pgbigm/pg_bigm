CREATE EXTENSION pg_bigm;

\pset null '(null)'

SHOW pg_bigm.last_update;
SET pg_bigm.last_update = '2013.09.18';

SET standard_conforming_strings = on;

SELECT likequery (NULL);
SELECT likequery ('');
SELECT likequery ('aBc023#*^&');
SELECT likequery ('ポスグレの全文検索');
SELECT likequery ('\_%');
SELECT likequery ('pg_bigmは検索性能を200%向上させました。');
