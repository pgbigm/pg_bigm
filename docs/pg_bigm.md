# pg_bigm 1.2 ドキュメント

## 概要

pg_bigm(ピージーバイグラム)は、[PostgreSQL](http://www.postgresql.org/)上で全文検索機能を提供するモジュールです。このモジュールを使うことで、ユーザは全文検索用のインデックスを作成でき、高速に文字列検索を行えるようになります。このモジュールは、2-gram(バイグラム)と呼ばれる方法で、文字列から全文検索用のインデックスを作成します。

[pg_bigmプロジェクト](https://github.com/pgbigm/pg_bigm)では以下の1つのモジュールを提供します。

| モジュール名 | 概要                                           | ソースアーカイブファイル名  |
|--------------|------------------------------------------------|-----------------------------|
| pg_bigm      | PostgreSQL上で全文検索機能を提供するモジュール | pg_bigm-x.y-YYYYMMDD.tar.gz |

ソースアーカイブファイル名のx.yとYYYYMMDDの部分は、それぞれ、そのファイルのバージョン番号とリリース年月日です。
例えば、2013年11月22日リリースのバージョン1.1のファイルでは、x.yは1.1、YYYYMMDDは20131122です。

pg_bigmのライセンスは[The PostgreSQL License](http://opensource.org/licenses/postgresql)(BSDに似たライセンス)です。

## pg_trgmとの違い

PostgreSQLには、[pg_trgm](http://www.postgresql.jp/document/current/html/pgtrgm.html)という3-gram(トライグラム)の全文検索モジュールがcontribに付属されています。
pg_bigmは、pg_trgmをベースに開発されています。
pg_trgmとpg_bigmでは、機能や特徴に以下の違いがあります。

<table>
<colgroup>
<col style="width: 33%" />
<col style="width: 33%" />
<col style="width: 33%" />
</colgroup>
<thead>
<tr class="header">
<th>機能や特徴</th>
<th>pg_trgm</th>
<th>pg_bigm</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td>全文検索インデックスの作成方法</td>
<td data-nowrap="">3-gram</td>
<td>2-gram</td>
</tr>
<tr class="even">
<td>利用できるインデックスの種類</td>
<td data-nowrap="">GINとGiST</td>
<td>GINのみ</td>
</tr>
<tr class="odd">
<td>利用できるテキスト検索演算子</td>
<td data-nowrap="">LIKE (~~)、ILIKE (~~*)、~、~*</td>
<td>LIKEのみ</td>
</tr>
<tr class="even">
<td>日本語検索</td>
<td data-nowrap="">未対応(*1)</td>
<td>対応済</td>
</tr>
<tr class="odd">
<td>検索キーワード1～2文字での検索</td>
<td data-nowrap="">低速<br />
(検索時に全文検索インデックスを使えない(*2))</td>
<td>高速<br />
(検索時に全文検索インデックスを使える)</td>
</tr>
<tr class="even">
<td>類似文字列の検索</td>
<td data-nowrap="">対応済</td>
<td>対応済(バージョン1.1以降)</td>
</tr>
<tr class="odd">
<td>インデックス作成が可能な列の最大サイズ</td>
<td data-nowrap="">238,609,291Byte (約228MB)</td>
<td data-nowrap="">107,374,180 Bytes (約102MB)</td>
</tr>
</tbody>
</table>

-   (\*1)
    ソースコード内の[マクロ変数を変更することで日本語検索に対応](http://lets.postgresql.jp/documents/technical/text-processing/3#contains)できます。しかし、日本語検索の性能はpg_bigmに比べて低速です。
-   (\*2)
    全文検索インデックスを使える場合もありますが、その場合はフルインデックススキャンが走るため検索性能は非常に低くなります。

pg_bigmのバージョン1.1以降では、pg_trgmとpg_bigmを同じデータベース内で共存させることが可能です。しかし、バージョン1.0では共存できないため、pg_bigmを登録するデータベースには、pg_trgmを同時に登録しないでください。

## 動作確認環境

pg_bigmは、以下の環境で動作確認をしています。

| カテゴリ | モジュール名                                                    |
|----------|-----------------------------------------------------------------|
| OS       | Linux, Mac OS X                                                 |
| DBMS     | PostgreSQL 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 10, 11, 12, 13, 14, 15 |

pg_bigmは、PostgreSQL9.1以降に対応しています。9.0以前には未対応です。

## インストール

### PostgreSQLのインストール

[PostgreSQLのオフィシャルサイト](http://www.postgresql.org/)からPostgreSQLのソースアーカイブファイルpostgresql-X.Y.Z.tar.gz(X.Y.Zは実際のバージョン番号に置き換えてください)をダウンロードし、ビルドとインストールを行います。

    $ tar zxf postgresql-X.Y.Z.tar.gz
    $ cd postgresql-X.Y.Z
    $ ./configure --prefix=/opt/pgsql-X.Y.Z
    $ make
    $ su
    # make install
    # exit

-   --prefix :
    インストール先ディレクトリを指定します。このオプション指定は必須ではありません。未指定時のインストール先は/usr/local/pgsqlです。

RPMからPostgreSQLをインストールしてもpg_bigmは利用可能です。
この場合、postgresql-develパッケージをインストールしなければならないことに注意してください。

### pg_bigmのインストール

[ここ](https://github.com/pgbigm/pg_bigm/releases)からpg_bigmのソースアーカイブファイルをダウンロードし、ビルドとインストールを行います。

    $ tar zxf pg_bigm-x.y-YYYYMMDD.tar.gz
    $ cd pg_bigm-x.y-YYYYMMDD
    $ make USE_PGXS=1 PG_CONFIG=/opt/pgsql-X.Y.Z/bin/pg_config
    $ su
    # make USE_PGXS=1 PG_CONFIG=/opt/pgsql-X.Y.Z/bin/pg_config install
    # exit

-   USE_PGXS :
    PostgreSQL関連モジュールをコンパイルするときのオマジナイです。USE_PGXS=1の指定が必須です。
-   PG_CONFIG :
    [pg_config](http://www.postgresql.jp/document/current/html/app-pgconfig.html)コマンド(PostgreSQLインストール先のbinディレクトリに存在)のパスを指定します。pg_configにPATHが通っているのであれば、このオプション指定は不要です。

### pg_bigmの登録

データベースクラスタの作成後、postgresql.confを編集、PostgreSQLを起動し、pg_bigmをデータベースに登録します。

    $ initdb -D $PGDATA --locale=C --encoding=UTF8

    $ vi $PGDATA/postgresql.conf
    shared_preload_libraries = 'pg_bigm'

    $ pg_ctl -D $PGDATA start
    $ psql -d <データベース名>
    =# CREATE EXTENSION pg_bigm;
    =# \dx pg_bigm
                        List of installed extensions
      Name   | Version | Schema |              Description
    ---------+---------+--------+---------------------------------------
     pg_bigm | 1.1     | public | text index searching based on bigrams
    (1 row)

-   $PGDATAは、データベースクラスタのパスを決めて、そのパスで置き換えてください。
-   pg_bigmは、PostgreSQLで利用できるすべてのエンコーディングとロケールをサポートしています。
-   postgresql.confで、[shared_preload_libraries](http://www.postgresql.jp/document/current/html/runtime-config-client.html#GUC-SHARED-PRELOAD-LIBRARIES)または[session_preload_libraries](http://www.postgresql.jp/document/current/html/runtime-config-client.html#GUC-SESSION-PRELOAD-LIBRARIES)(PostgreSQL9.4以降で利用可能)に'pg_bigm'を設定して、pg_bigmの共有ライブラリをサーバにプリロードしなければなりません。
    -   PostgreSQL9.1では、[custom_variable_classes](http://www.postgresql.jp/document/9.1/html/runtime-config-custom.html#GUC-CUSTOM-VARIABLE-CLASSES)も'pg_bigm'に設定しなければなりません。
-   pg_bigmの登録には、[CREATE
    EXTENSION](http://www.postgresql.jp/document/current/html/sql-createextension.html)を使います。
    CREATE
    EXTENSIONはデータベース単位でモジュールを登録するため、pg_bigmを利用したいデータベースすべてにおいて登録が必要です。

pg_bigmのインストールは以上で終わりです。

## アンインストール

### pg_bigmの削除

pg_bigmについて、データベースからの登録解除とアンインストールを行います。

    $ psql -d <データベース名>
    =# DROP EXTENSION pg_bigm CASCADE;
    =# \q

    $ pg_ctl -D $PGDATA stop
    $ su

    # cd <pg_bigmのソースディレクトリ>
    # make USE_PGXS=1 PG_CONFIG=/opt/pgsql-X.Y.Z/bin/pg_config uninstall
    # exit

-   pg_bigmを登録したすべてのデータベースで登録解除する必要があります。
-   pg_bigmに依存するDBオブジェクト(例えば、pg_bigmを使った全文検索インデックス)を削除する必要があるため、[DROP
    EXTENSION](http://www.postgresql.jp/document/current/html/sql-dropextension.html)にはCASCADEを指定します。

### postgresql.confの設定削除

postgresql.confの以下の設定を削除します

-   shared_preload_librariesまたはsession_preload_libraries
-   custom_variable_classes (PostgreSQL9.1のみ)
-   pg_bigm.\* (pg_bigm.から名前が始まるパラメータ)

## 全文検索機能

### インデックスの作成

GINインデックスを利用して全文検索用のインデックスを作成します。

以下の実行例では、PostgreSQL関連ツールの名前と説明を管理するテーブルpg_toolsを作成し、4件データを投入します。その後、ツールの説明に対して全文検索用のインデックスを作成します。

    =# CREATE TABLE pg_tools (tool text, description text);

    =# INSERT INTO pg_tools VALUES ('pg_hint_plan', 'PostgreSQLでHINT句を使えるようにするツール');
    =# INSERT INTO pg_tools VALUES ('pg_dbms_stats', 'PostgreSQLの統計情報を固定化するツール');
    =# INSERT INTO pg_tools VALUES ('pg_bigm', 'PostgreSQLで2-gramの全文検索を使えるようにするツール');
    =# INSERT INTO pg_tools VALUES ('pg_trgm', 'PostgreSQLで3-gramの全文検索を使えるようにするツール');

    =# CREATE INDEX pg_tools_idx ON pg_tools USING gin (description gin_bigm_ops);

-   インデックスメソッドにはginの指定が必須です。
    pg_bigmでは、pg_trgmとは異なりインデックス作成にGiSTを使えません。
-   演算子クラスにはgin_bigm_opsの指定が必須です。

また、以下の実行例のように、全文検索用のマルチカラムインデックスを作成したり、作成時にGINインデックスのパラメータを指定することもできます。

    =# CREATE INDEX pg_tools_multi_idx ON pg_tools USING gin (tool gin_bigm_ops, description gin_bigm_ops) WITH (FASTUPDATE = off);

### 全文検索の実行

pg_bigmでは、LIKE演算子の中間一致検索により全文検索を行います。

    =# SELECT * FROM pg_tools WHERE description LIKE '%全文検索%';
      tool   |                     description
    ---------+------------------------------------------------------
     pg_bigm | PostgreSQLで2-gramの全文検索を使えるようにするツール
     pg_trgm | PostgreSQLで3-gramの全文検索を使えるようにするツール
    (2 rows)

-   検索文字列は[likequery](#likequery)に記載されているとおり、全文検索用に変換されなければなりません。

### 類似度検索の実行

pg_bigmでは、=% 演算子を使って類似度検索を行います。

以下の実行例では、文字列「bigm」に似た文字列のtool列を検索しています。この類似度検索も、全文検索と同様にインデックスにより高速に実行されます。文字列どうしが似ているかどうかは、それら文字列の類似度が[pg_bigm.similarity_limit](#pg_bigmsimilarity_limit)の設定値以上かどうかで判断されます。この実行例では、文字列「bigm」との類似度が0.2以上だった「pg_bigm」と「pg_trgm」のtool列だけが検索結果となります。

    =# SET pg_bigm.similarity_limit TO 0.2;

    =# SELECT tool FROM pg_tools WHERE tool =% 'bigm';
      tool   
    ---------
     pg_bigm
     pg_trgm
    (2 rows)

類似度の計算方法や注意点については、類似度を計算する関数[bigm_similarity](#bigm_similarity)を参照してください。

## 提供関数

### likequery

likequeryは、全文検索できるように、検索文字列(引数1)をLIKE演算子のパターンに変換する関数です。

-   引数1(text) - 検索文字列
-   戻り値(text) - 全文検索用に、引数1をLIKE演算子のパターンに変換した文字列

引数1がNULLの場合、戻り値はNULLです。

変換は、具体的には以下を行います。

-   検索文字列の先頭と末尾に%(半角パーセント)を追加
-   検索文字列内の%(半角パーセント)、\_(半角アンダースコア)、\\(半角バックスラッシュ)を\\(半角バックスラッシュ)でエスケープ

pg_bigmでは、LIKE演算子の中間一致検索により全文検索を行います。このため、上記のとおり検索文字列を変換して、LIKE演算子に渡す必要があります。この変換は、通常、クライアントアプリケーション側で実装しなければなりません。しかし、likequeryを利用することで、その実装の手間を省くことができます。

    =# SELECT likequery('pg_bigmは検索性能を200%向上させました。');
                      likequery
    ---------------------------------------------
     %pg\_bigmは検索性能を200\%向上させました。%
    (1 row)

「全文検索の実行」の実行例の検索SQLは、likequeryを使うことで、以下のように書き換えられます。

    =# SELECT * FROM pg_tools WHERE description LIKE likequery('全文検索');
      tool   |                     description
    ---------+------------------------------------------------------
     pg_bigm | PostgreSQLで2-gramの全文検索を使えるようにするツール
     pg_trgm | PostgreSQLで3-gramの全文検索を使えるようにするツール
    (2 rows)

### show_bigm

show_bigmは、文字列(引数1)のすべての2-gram文字列を配列として表示する関数です。

-   引数1(text) - 文字列
-   戻り値(text\[\]) - 引数1のすべての2-gram文字列から構成される配列

2-gram文字列とは、文字列の先頭と末尾に空白文字を追加した上で、文字列を1文字ずつずらしながら、2文字単位で抽出した文字列のことです。例えば、文字列「ABC」の2-gram文字列は、「(空白)A」「AB」「BC」「C(空白)」の4つになります。

    =#  SELECT show_bigm('PostgreSQLの全文検索');
                                show_bigm
    -----------------------------------------------------------------
     {の全,全文,文検,検索,"索 "," P",Lの,Po,QL,SQ,eS,gr,os,re,st,tg}
    (1 row)

### bigm_similarity

bigm_similarityは、文字列(引数1)と文字列(引数2)の類似度(文字列がどの程度似ているかを示す数値)を返却する関数です。

-   引数1(text) - 文字列
-   引数2(text) - 文字列
-   戻り値(real) - 引数1と引数2の文字列の類似度

この関数は、各文字列の2-gram文字列から一致するものの個数を数えることで類似度を計算します。
類似度は0(2つの文字列にまったく類似性がないことを示す)から1(2つの文字列が同一であることを示す)までの範囲です。

    =# SELECT bigm_similarity('PostgreSQLの全文検索', 'postgresの検索');
     bigm_similarity 
    -----------------
              0.4375
    (1 row)

類似度計算に使われる2-gram文字列は、文字列の先頭と末尾に空白文字が追加された上で作成されることに注意してください。
このため、例えば、文字列「B」は文字列「ABC」に含まれますが、下記のとおり一致する2-gram文字列がないため類似度は0になります。
一方、文字列「A」は、下記のとおり一致する2-gram文字列があるため類似度は0より大きくなります。
これは、pg_trgmのsimilarity関数と基本的に同じ挙動です。

-   文字列「ABC」の2-gram文字列は「(空白)A」「AB」「BC」「C(空白)」
-   文字列「A」の2-gram文字列は「(空白)A」「A(空白)」
-   文字列「B」の2-gram文字列は「(空白)B」「B(空白)」

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

bigm_similarityは、英字の大文字と小文字を区別することに注意してください。
一方、pg_trgmのsimilarity関数は、英字の大文字と小文字を区別しません。
例えば、「ABC」と「abc」の類似度は、pg_trgmのsimilarity関数では1ですが、bigm_similarityでは0です。

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

pg_gin_pending_statsは、GINインデックス(引数1)の待機リストに含まれているデータのページ数とタプル数を返却する関数です。

-   引数1(regclass) - GINインデックスの名前もしくはOID
-   戻り値1(integer) -
    GINインデックス(引数1)の待機リストに含まれているデータのページ数
-   戻り値2(bigint) -
    GINインデックス(引数1)の待機リストに含まれているデータのタプル数

FASTUPDATEオプション無効で作成されたGINインデックスが引数1の場合、そのGINインデックスは待機リストを持たないため、戻り値1と2は0となることに注意してください。
GINインデックスの待機リストとFASTUPDATEオプションの詳細は、[GIN高速更新手法](http://www.postgresql.jp/document/current/html/gin-implementation.html#GIN-FAST-UPDATE)を参照してください。

    =# SELECT * FROM pg_gin_pending_stats('pg_tools_idx');
     pages | tuples
    -------+--------
         1 |      4
    (1 row)

## パラメータ

### pg_bigm.last_update

pg_bigm.last_updateは、pg_bigmモジュールの最終更新日付を報告するパラメータです。このパラメータは読み取り専用です。
postgresql.confやSET文で設定値を変更することはできません。

    =# SHOW pg_bigm.last_update;
     pg_bigm.last_update
    ---------------------
     2013.11.22
    (1 row)

### pg_bigm.enable_recheck

pg_bigm.enable_recheckは、全文検索の内部処理であるRecheckを行うかどうか指定するパラメータです。デフォルト値はonで、Recheckを行います。このパラメータは、postgresql.confとSET文(スーパーユーザに限らずどのユーザからでも)で設定値を変更できます。全文検索において正しい検索結果を得るには、このパラメータは有効化されていなければなりません。

pg_bigmを使った全文検索では、内部的には以下2つの処理で検索結果が取得されます。

-   全文検索インデックスからの検索結果候補の取得
-   検索結果候補からの正しい検索結果の選択

この後者の処理がRecheckと呼ばれます。全文検索インデックスからの検索結果の取得では、必ずしも正しい結果ばかりが得られるとは限りません。誤った結果が含まれる可能性があります。この誤った結果を取り除くのがRecheckになります。

例えば、テーブルに「ここは東京都」「東京と京都に行く」の2つの文字列が格納されている状況を想像してください。検索文字列「東京都」で検索した場合、正しい結果は「ここは東京都」です。しかし、全文検索インデックスからの結果取得では、「東京と京都に行く」も結果候補として取得できてしまいます。これは、検索文字列の2-gram文字列である「東京」と「京都」が「東京と京都に行く」に含まれているためです。
Recheckは、結果候補それぞれについて検索文字列「東京都」が含まれるのか再チェックを行い、正しい結果だけを選択します。

このRecheckによる検索結果の絞り込みの様子は、EXPLAIN
ANALYZEの結果から確認できます。

    =# CREATE TABLE tbl (doc text);
    =# INSERT INTO tbl VALUES('ここは東京都');
    =# INSERT INTO tbl VALUES('東京と京都に行く');
    =# CREATE INDEX tbl_idx ON tbl USING gin (doc gin_bigm_ops);
    =# SET enable_seqscan TO off;
    =# EXPLAIN ANALYZE SELECT * FROM tbl WHERE doc LIKE likequery('東京都');
                                                       QUERY PLAN
    -----------------------------------------------------------------------------------------------------------------
     Bitmap Heap Scan on tbl  (cost=12.00..16.01 rows=1 width=32) (actual time=0.022..0.023 rows=1 loops=1)
       Recheck Cond: (doc ~~ '%東京都%'::text)
       ->  Bitmap Index Scan on tbl_idx  (cost=0.00..12.00 rows=1 width=0) (actual time=0.015..0.015 rows=2 loops=1)
             Index Cond: (doc ~~ '%東京都%'::text)
     Total runtime: 0.059 ms
    (5 rows)

Bitmap Index
Scanのrowsは2となっており、全文検索インデックスからは2件結果を取得しています。
Recheck実行後のBitmap Heap
Scanのrowsは1となっており、2件の結果候補から1件に絞り込まれた様子を確認できます。

pg_bigm.enable_recheckを無効化することで、Recheckをスキップさせ、全文検索インデックスから取得した結果候補をそのまま最終的な検索結果とすることができます。以下の実行例では、このパラメータの無効化により、誤った検索結果の「東京と京都に行く」を得られています。

    =# SELECT * FROM tbl WHERE doc LIKE likequery('東京都');
         doc
    --------------
     ここは東京都
    (1 row)

    =# SET pg_bigm.enable_recheck TO off;
    =# SELECT * FROM tbl WHERE doc LIKE likequery('東京都');
           doc
    ------------------
     ここは東京都
     東京と京都に行く
    (2 rows)

このパラメータは、正しい検索結果を得る必要がある運用時には必ずonに設定されていなければなりません。一方、Recheckのオーバーヘッドを評価するなど、デバッグ時にoffに設定しても構いません。

### pg_bigm.gin_key_limit

pg_bigm.gin_key_limitは、検索文字列の2-gram文字列のうち最大で何個を全文検索インデックスの検索に使うか指定するパラメータです。設定値が0(デフォルト値)の場合は、検索文字列のすべての2-gram文字列をインデックス検索に使います。このパラメータは、postgresql.confとSET文(スーパーユーザに限らずどのユーザからでも)で設定値を変更できます。

pg_bigmの全文検索では、基本的に、検索文字列のすべての2-gram文字列を使ってGINインデックスを検索します。ただし、現在のGINインデックスの実装では、検索に使う2-gram文字列の個数が多いほどインデックス検索の負荷は高くなります。このため、検索文字列の文字数が多く、2-gram文字列の個数が多くなりやすいシステムでは、検索性能は劣化しやすいです。
pg_bigm.gin_key_limitによりGINインデックスの検索に使う2-gram文字列の最大数を制限することで、この性能問題を解決できます。

ただし、インデックス検索に使う2-gram文字列の個数が減ると、インデックスから取得した検索結果候補にはより多くの誤った結果が含まれることになります。このため、Recheckの負荷が高まり、逆に、より性能劣化する可能性もあるため注意が必要です。

### pg_bigm.similarity_limit

pg_bigm.similarity_limitは、類似度検索の閾値を指定するパラメータです。類似度検索では、検索条件の文字列との類似度がこの閾値以上の行が検索結果となります。設定値は0以上1以下の小数点数で、デフォルト値は0.3です。このパラメータは、postgresql.confとSET文(スーパーユーザに限らずどのユーザからでも)で設定値を変更できます。

## 制約

### インデックス作成が可能な列の最大サイズ

pg_bigmでは、列サイズが107,374,180Byte
(約102MB)を越える列へインデックスを作成できません。制限を越える大きさのデータを挿入するとエラーを起こします。

    =# CREATE TABLE t1 (description text);
    =# CREATE INDEX t1_idx ON t1 USING gin (description gin_bigm_ops);
    =# INSERT INTO t1 SELECT repeat('A', 107374181);
    ERROR:  out of memory

この制約はpg_trgmにも存在しますが、pg_trgmでは最大238,609,291Byte
(約228MB)までインデックスの作成が可能です。

*****

Copyright (c) 2017-2024, pg_bigm Development Group

Copyright (c) 2012-2016, NTT DATA Corporation
