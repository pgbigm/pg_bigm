# pg_bigm 1.2 Document

## Overview

The pg_bigm module provides full text search capability in
[PostgreSQL](http://www.postgresql.org/). This module allows a user to
create **2-gram** (bigram) index for faster full text search.

The [pg_bigm project](https://github.com/pgbigm/pg_bigm) provides the
following one module.

| Module  | Description                                                    | Source Archive File Name    |
|---------|----------------------------------------------------------------|-----------------------------|
| pg_bigm | Module that provides full text search capability in PostgreSQL | pg_bigm-x.y-YYYYMMDD.tar.gz |

The x.y and YYYYMMDD parts of the source archive file name are replaced
with its release version number and date, respectively. For example, x.y
is 1.1 and YYYYMMDD is 20131122 if the file of the version 1.1 was
released on November 22, 2013.

The license of pg_bigm is [The PostgreSQL
License](http://opensource.org/licenses/postgresql) (same as BSD
license).

## Comparison with pg_trgm

The
[pg_trgm](http://www.postgresql.jp/document/current/html/pgtrgm.html)
contrib module which provides full text search capability using 3-gram
(trigram) model is included in PostgreSQL. The pg_bigm was developed
based on the pg_trgm. They have the following differences:

<table>
<colgroup>
<col style="width: 33%" />
<col style="width: 33%" />
<col style="width: 33%" />
</colgroup>
<thead>
<tr class="header">
<th>Functionalities and Features</th>
<th>pg_trgm</th>
<th>pg_bigm</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td>Phrase matching method for full text search</td>
<td data-nowrap="">3-gram</td>
<td>2-gram</td>
</tr>
<tr class="even">
<td>Available index</td>
<td data-nowrap="">GIN and GiST</td>
<td>GIN only</td>
</tr>
<tr class="odd">
<td>Available text search operators</td>
<td data-nowrap="">LIKE (~~), ILIKE (~~*), ~, ~*</td>
<td>LIKE only</td>
</tr>
<tr class="even">
<td>Full text search for non-alphabetic language<br />
(e.g., Japanese)</td>
<td data-nowrap="">Not supported (*1)</td>
<td>Supported</td>
</tr>
<tr class="odd">
<td>Full text search with 1-2 characters keyword</td>
<td data-nowrap="">Slow (*2)</td>
<td>Fast</td>
</tr>
<tr class="even">
<td>Similarity search</td>
<td data-nowrap="">Supported</td>
<td>Supported (version 1.1 or later)</td>
</tr>
<tr class="odd">
<td>Maximum indexed column size</td>
<td data-nowrap="">238,609,291 Bytes (~228MB)</td>
<td data-nowrap="">107,374,180 Bytes (~102MB)</td>
</tr>
</tbody>
</table>

-   (\*1) You can use full text search for non-alphabetic language by
    commenting out KEEPONLYALNUM macro variable in
    contrib/pg_trgm/pg_trgm.h and rebuilding pg_trgm module. But pg_bigm
    provides faster non-alphabetic search than such a modified pg_trgm.
-   (\*2) Because, in this search, only sequential scan or index full
    scan (not normal index scan) can run.

pg_bigm 1.1 or later can coexist with pg_trgm in the same database, but
pg_bigm 1.0 cannot.

## Tested platforms

pg_bigm has been built and tested on the following platforms:

| Category | Module Name                                                     |
|----------|-----------------------------------------------------------------|
| OS       | Linux, Mac OS X                                                 |
| DBMS     | PostgreSQL 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 10, 11, 12, 13, 14, 15, 16 |

pg_bigm requires PostgreSQL 9.1 or later.

## Install

### Install PostgreSQL

From the [official site of PostgreSQL](http://www.postgresql.org/)
download the source archive file "postgresql-X.Y.Z.tar.gz (please
replace X.Y.Z with actual version number)" of PostgreSQL, and then build
and install it.

    $ tar zxf postgresql-X.Y.Z.tar.gz
    $ cd postgresql-X.Y.Z
    $ ./configure --prefix=/opt/pgsql-X.Y.Z
    $ make
    $ su
    # make install
    # exit

-   --prefix : Specify the PostgreSQL installation directory. This is
    optional. By default, PostgreSQL is installed in /usr/local/pgsql.

If PostgreSQL is installed from RPM, the postgresql-devel package must
be installed to build pg_bigm.

### Install pg_bigm

Download the source archive file of pg_bigm from
[here](https://github.com/pgbigm/pg_bigm/releases),
and then build and install it.

    $ tar zxf pg_bigm-x.y-YYYYMMDD.tar.gz
    $ cd pg_bigm-x.y-YYYYMMDD
    $ make USE_PGXS=1 PG_CONFIG=/opt/pgsql-X.Y.Z/bin/pg_config
    $ su
    # make USE_PGXS=1 PG_CONFIG=/opt/pgsql-X.Y.Z/bin/pg_config install
    # exit

-   USE_PGXS : USE_PGXS=1 must be always specified when building
    pg_bigm.
-   PG_CONFIG : Specify the path to
    [pg_config](http://www.postgresql.org/docs/current/static/app-pgconfig.html)
    (which exists in the bin directory of PostgreSQL installation). If
    the PATH environment variable contains the path to pg_config,
    PG_CONFIG doesn't need to be specified.

### Load pg_bigm

Create the database cluster, modify postgresql.conf, start PostgreSQL
server and then load pg_bigm into the database.

    $ initdb -D $PGDATA --locale=C --encoding=UTF8

    $ vi $PGDATA/postgresql.conf
    shared_preload_libraries = 'pg_bigm'

    $ pg_ctl -D $PGDATA start
    $ psql -d <database name>
    =# CREATE EXTENSION pg_bigm;
    =# \dx pg_bigm
                        List of installed extensions
      Name   | Version | Schema |              Description
    ---------+---------+--------+---------------------------------------
     pg_bigm | 1.1     | public | text index searching based on bigrams
    (1 row)

-   Replace $PGDATA with the path to database cluster.
-   pg_bigm supports all PostgreSQL encoding and locale.
-   In postgresql.conf,
    [shared_preload_libraries](http://www.postgresql.org/docs/devel/static/runtime-config-client.html#GUC-SHARED-PRELOAD-LIBRARIES)
    or
    [session_preload_libraries](http://www.postgresql.org/docs/devel/static/runtime-config-client.html#GUC-SESSION-PRELOAD-LIBRARIES)
    (available in PostgreSQL 9.4 or later) must be set to 'pg_bigm' to
    preload the pg_bigm shared library into the server.
    -   In PostgreSQL 9.1,
        [custom_variable_classes](http://www.postgresql.org/docs/9.1/static/runtime-config-custom.html#GUC-CUSTOM-VARIABLE-CLASSES)
        also must be set to 'pg_bigm'.
-   [CREATE
    EXTENSION](http://www.postgresql.org/docs/current/static/sql-createextension.html)
    pg_bigm needs to be executed in all the databases that you want to
    use pg_bigm in.

## Uninstall

### Delete pg_bigm

Unload pg_bigm from the database and then uninstall it.

    $ psql -d <database name>
    =# DROP EXTENSION pg_bigm CASCADE;
    =# \q

    $ pg_ctl -D $PGDATA stop
    $ su

    # cd <pg_bigm source directory>
    # make USE_PGXS=1 PG_CONFIG=/opt/pgsql-X.Y.Z/bin/pg_config uninstall
    # exit

-   pg_bigm needs to be unloaded from all the databases that it was
    loaded into.
-   [DROP
    EXTENSION](http://www.postgresql.org/docs/current/static/sql-dropextension.html)
    pg_bigm needs to be executed with CASCADE option to delete all the
    database objects which depend on pg_bigm, e.g., pg_bigm full text
    search index.

### Reset postgresql.conf

Delete the following pg_bigm related settings from postgresql.conf.

-   shared_preload_libraries or session_preload_libraries
-   custom_variable_classes (only PostgreSQL 9.1)
-   pg_bigm.\* (parameters which begin with pg_bigm)

## Full text search

### Create Index

You can create an index for full text search by using GIN index.

The following example creates the table *pg_tools* which stores the name
and description of PostgreSQL related tool, inserts four records into
the table, and then creates the full text search index on the
*description* column.

    =# CREATE TABLE pg_tools (tool text, description text);

    =# INSERT INTO pg_tools VALUES ('pg_hint_plan', 'Tool that allows a user to specify an optimizer HINT to PostgreSQL');
    =# INSERT INTO pg_tools VALUES ('pg_dbms_stats', 'Tool that allows a user to stabilize planner statistics in PostgreSQL');
    =# INSERT INTO pg_tools VALUES ('pg_bigm', 'Tool that provides 2-gram full text search capability in PostgreSQL');
    =# INSERT INTO pg_tools VALUES ('pg_trgm', 'Tool that provides 3-gram full text search capability in PostgreSQL');

    =# CREATE INDEX pg_tools_idx ON pg_tools USING gin (description gin_bigm_ops);

-   **gin** must be used as an index method. GiST is not available for
    pg_bigm.
-   **gin_bigm_ops** must be used as an operator class.

You can also create multicolumn pg_bigm index and specify GIN related
parameters then, as follows.

    =# CREATE INDEX pg_tools_multi_idx ON pg_tools USING gin (tool gin_bigm_ops, description gin_bigm_ops) WITH (FASTUPDATE = off);

### Execute full text search

You can execute full text search by using LIKE pattern matching.

    =# SELECT * FROM pg_tools WHERE description LIKE '%search%';
      tool   |                             description                             
    ---------+---------------------------------------------------------------------
     pg_bigm | Tool that provides 2-gram full text search capability in PostgreSQL
     pg_trgm | Tool that provides 3-gram full text search capability in PostgreSQL
    (2 rows)

-   The search keyword must be specified as the pattern string that LIKE
    operator can handle properly, as discussed in
    [likequery](#likequery).

### Execute similarity search

You can execute similarity search by using =% operator.

The following query returns all values in the tool column that are
sufficiently similar to the word 'bigm'. This similarity search is
basically fast because it can use the full text search index. It
measures whether two strings are sufficiently similar to by seeing
whether their similarity is higher than or equal to the value of
[pg_bigm.similarity_limit](#pg_bigmsimilarity_limit). This means, in this
query, that the values whose similarity with the word 'bigm' is higher
than or equal to 0.2 are only 'pg_bigm' and 'pg_trgm' in the tool
column.

    =# SET pg_bigm.similarity_limit TO 0.2;

    =# SELECT tool FROM pg_tools WHERE tool =% 'bigm';
      tool   
    ---------
     pg_bigm
     pg_trgm
    (2 rows)

Please see [bigm_similarity](#bigm_similarity) function for details of
how to calculate the similarity.

## Functions

### likequery

likequery is a function that converts the search keyword (argument #1)
into the pattern string that LIKE operator can handle properly.

-   Argument #1 (text) - search keyword
-   Return value (text) - pattern string that was converted from
    argument #1 so that LIKE operator can handle properly

If the argument #1 is NULL, the return value is also NULL.

This function does the conversion as follows:

-   appends % (single-byte percent) into both the beginning and the end
    of the search keyword.
-   escapes the characters % (single-byte percent), \_ (single-byte
    underscore) and \\ (single-byte backslash) in the search keyword by
    using \\ (single-byte backslash).

In pg_bigm, full text search is performed by using LIKE pattern
matching. Therefore, the search keyword needs to be converted into the
pattern string that LIKE operator can handle properly. Usually a client
application should be responsible for this conversion. But, you can save
the effort of implementing such a conversion logic in the application by
using likequery function.

    =# SELECT likequery('pg_bigm has improved the full text search performance by 200%');
                                 likequery                             
    -------------------------------------------------------------------
     %pg\_bigm has improved the full text search performance by 200\%%
    (1 row)

Using likequery, you can rewrite the full text search query which was
used in the example in "Execute full text search" into:

    =# SELECT * FROM pg_tools WHERE description LIKE likequery('search');
      tool   |                             description                             
    ---------+---------------------------------------------------------------------
     pg_bigm | Tool that provides 2-gram full text search capability in PostgreSQL
     pg_trgm | Tool that provides 3-gram full text search capability in PostgreSQL
    (2 rows)

### show_bigm

show_bigm returns an array of all the 2-grams in the given string
(argument #1).

-   Argument #1 (text) - character string
-   Return value (text\[\]) - an array of all the 2-grams in argument #1

A 2-gram that show_bigm returns is a group of two consecutive characters
taken from a string that blank character has been appended into the
beginning and the end. For example, the 2-grams of the string "ABC" are
"(blank)A" "AB" "BC" "C(blank)".

    =# SELECT show_bigm('full text search');
                                show_bigm                             
    ------------------------------------------------------------------
     {" f"," s"," t",ar,ch,ea,ex,fu,"h ","l ",ll,rc,se,"t ",te,ul,xt}
    (1 row)

### bigm_similarity

bigm_similarity returns a number that indicates how similar the two
strings (argument #1 and #2) are.

-   Argument #1 (text) - character string
-   Argument #2 (text) - character string
-   Return value (real) - the similarity of two arguments

This function measures the similarity of two strings by counting the
number of 2-grams they share. The range of the similarity is zero
(indicating that the two strings are completely dissimilar) to one
(indicating that the two strings are identical).

    =# SELECT bigm_similarity('full text search', 'text similarity search');
     bigm_similarity 
    -----------------
            0.571429
    (1 row)

Note that each argument is considered to have one space prefixed and
suffixed when determining the set of 2-grams contained in the string for
calculation of similarity. For example, though the string "ABC" contains
the string "B", their similarity is 0 because there are no 2-grams they
share as follows. On the other hand, the string "ABC" and "A" share one
2-gram "(blank)A" as follows, so their similarity is higher than 0. This
is basically the same behavior as pg_trgm's similarity function.

-   The 2-grams of the string "ABC" are "(blank)A" "AB" "BC" "C(blank)".
-   The 2-grams of the string "A" are "(blank)A" "A(blank)".
-   The 2-grams of the string "B" are "(blank)B" "B(blank)".

<!-- -->

    =# SELECT bigm_similarity('ABC', 'A');
     bigm_similarity 
    -----------------
                0.25
    (1 row)

    =# SELECT bigm_similarity('ABC', 'B');
     bigm_similarity 
    -----------------
                   0
    (1 row)

Note that bigm_similarity IS case-sensitive, but pg_trgm's similarity
function is not. For example, the similarity of the strings "ABC" and
"abc" is 1 in pg_trgm's similarity function but 0 in bigm_similarity.

    =# SELECT similarity('ABC', 'abc');
     similarity 
    ------------
              1
    (1 row)

    =# SELECT bigm_similarity('ABC', 'abc');
     bigm_similarity 
    -----------------
                   0
    (1 row)

### pg_gin_pending_stats

pg_gin_pending_stats is a function that returns the number of pages and
tuples in the pending list of GIN index (argument #1).

-   Argument #1 (regclass) - Name or OID of GIN index
-   Return value #1 (integer) - Number of pages in the pending list
-   Return value #2 (bigint) - Number of tuples in the pending list

Note that the return value #1 and #2 are 0 if the argument #1 is the GIN
index built with FASTUPDATE option disabled because it doesn't have a
pending list. Please see [GIN Fast Update
Technique](http://www.postgresql.org/docs/current/static/gin-implementation.html#GIN-FAST-UPDATE)
for details of the pending list and FASTUPDATE option.

    =# SELECT * FROM pg_gin_pending_stats('pg_tools_idx');
     pages | tuples
    -------+--------
         1 |      4
    (1 row)

## Parameters

### pg_bigm.last_update

pg_bigm.last_update is a parameter that reports the last updated date of
the pg_bigm module. This parameter is read-only. You cannot change the
value of this parameter at all.

    =# SHOW pg_bigm.last_update;
     pg_bigm.last_update
    ---------------------
     2013.11.22
    (1 row)

### pg_bigm.enable_recheck

pg_bigm.enable_recheck is a parameter that specifies whether to perform
Recheck which is an internal process of full text search. The default
value is on, i.e., Recheck is performed. Not only superuser but also any
user can change this parameter value in postgresql.conf or by using SET
command. This parameter must be enabled if you want to obtain the
correct search result.

PostgreSQL and pg_bigm internally perform the following processes to get
the search results:

-   retrieve the result candidates from full text search index.
-   choose the correct search results from the candidates.

The latter process is called Recheck. The result candidates retrieved
from full text search index may contain wrong results. Recheck process
gets rid of such wrong results.

For example, imagine the case where two character strings "He is
awaiting trial" and "It was a trivial mistake" are stored in a table.
The correct search result with the keyword "trial" is "He is awaiting
trial". However, "It was a trivial mistake" is also retrieved as the
result candidate from the full text search index because it contains all
the 2-grams ("al", "ia", "ri", "tr") of the search keyword "trial".
Recheck process tests whether each candidate contains the search keyword
itself, and then chooses only the correct results.

How Recheck narrows down the search result can be observed in the result
of EXPLAIN ANALYZE.

    =# CREATE TABLE tbl (doc text);
    =# INSERT INTO tbl VALUES('He is awaiting trial');
    =# INSERT INTO tbl VALUES('It was a trivial mistake');
    =# CREATE INDEX tbl_idx ON tbl USING gin (doc gin_bigm_ops);
    =# SET enable_seqscan TO off;
    =# EXPLAIN ANALYZE SELECT * FROM tbl WHERE doc LIKE likequery('trial');
                                                       QUERY PLAN                                                    
    -----------------------------------------------------------------------------------------------------------------
     Bitmap Heap Scan on tbl  (cost=12.00..16.01 rows=1 width=32) (actual time=0.041..0.044 rows=1 loops=1)
       Recheck Cond: (doc ~~ '%trial%'::text)
       Rows Removed by Index Recheck: 1
       ->  Bitmap Index Scan on tbl_idx  (cost=0.00..12.00 rows=1 width=0) (actual time=0.028..0.028 rows=2 loops=1)
             Index Cond: (doc ~~ '%trial%'::text)
     Total runtime: 0.113 ms
    (6 rows)

In this example, you can see that Bitmap Index Scan retrieved two rows
from the full text search index but Bitmap Heap Scan returned only one
row after Recheck process.

It is possible to skip Recheck process and get the result candidates
retrieved from the full text search index as the final results, by
disabling this parameter. In the following example, wrong result "It was
a trivial mistake" is also returned because the parameter is disabled.

    =# SELECT * FROM tbl WHERE doc LIKE likequery('trial');
             doc          
    ----------------------
     He is awaiting trial
    (1 row)

    =# SET pg_bigm.enable_recheck = off;
    =# SELECT * FROM tbl WHERE doc LIKE likequery('trial');
               doc            
    --------------------------
     He is awaiting trial
     It was a trivial mistake
    (2 rows)

This parameter must be enabled if you want to obtain the correct search
result. On the other hand, you may need to set it to off, for example,
for evaluation of Recheck performance overhead or debugging, etc.

### pg_bigm.gin_key_limit

pg_bigm.gin_key_limit is a parameter that specifies the maximum number
of 2-grams of the search keyword to be used for full text search. If
it's set to zero (default), all the 2-grams of the search keyword are
used for full text search. Not only superuser but also any user can
change this parameter value in postgresql.conf or by using SET command.

PostgreSQL and pg_bigm basically use all the 2-grams of search keyword
to scan GIN index. However, in current implementation of GIN index, the
more 2-grams are used, the more performance overhead of GIN index scan
is increased. In the system that large search keyword is often used,
full text search is likely to be slow. This performance issue can be
solved by using this parameter and limiting the maximum number of
2-grams to be used.

On the other hand, the less 2-grams are used, the more wrong results are
included in the result candidates retrieved from full text search index.
Please note that this can increase the workload of Recheck and decrease
the performance.

### pg_bigm.similarity_limit

pg_bigm.similarity_limit is a parameter that specifies the threshold
used by the similarity search. The similarity search returns all the
rows whose similarity with the search keyword is higher than or equal to
this threshold. Value must be between 0 and 1 (default is 0.3). Not only
superuser but also any user can change this parameter value in
postgresql.conf or by using SET command.

## Limitations

### Indexed Column Size

The size of the column indexed by bigm GIN index cannot exceed
107,374,180 Bytes (\~102MB). Any attempt to enter larger values will
result in an error.

    =# CREATE TABLE t1 (description text);
    =# CREATE INDEX t1_idx ON t1 USING gin (description gin_bigm_ops);
    =# INSERT INTO t1 SELECT repeat('A', 107374181);
    ERROR:  out of memory

pg_trgm also has this limitation. However, the maximum size in the case
of trgm indexed column is 238,609,291 Bytes (\~228MB).

*****

Copyright (c) 2017-2024, pg_bigm Development Group

Copyright (c) 2012-2016, NTT DATA Corporation
