package AccessCounter::L10N::ja;

use strict;
use base 'AccessCounter::L10N::en_us';
use vars qw( %Lexicon );

%Lexicon = (

## plugins/AccessCounter/AccessCounter.pl
	'<p>This plugin enables Access Ranking: tally up the accessed count. Additionally, you can sort entries by their accessed count.</p><pre><code>&#60;mt:Entries <strong>sort_by=&#34;accessed_count&#34;</strong>&#62;<br />...<br />&#60;/mt:Entries&#62;</code></pre>' => '<p>アクセスランキングを表示できます。ブログ記事のアクセス数をカウントします。アクセス数順で指定した数のブログ記事を一覧することができます。</p><p>ブログ記事のランキング表示は、MTEntries のモディファイア sort_by に accessed_count を指定します。</p><pre><code>&#60;mt:Entries <strong>sort_by=&#34;accessed_count&#34;</strong>&#62;<br />...<br />&#60;/mt:Entries&#62;</code></pre>',
	'Accessed Count' => 'アクセスカウント',
	'Counts' => 'アクセス数',
	'Last Accessed' => '最終アクセス日時',

## plugins/AccessCounter/tmpl/config.tmpl
	'Tracking' => 'トラッキング',
	'Start Tracking your Blog' => 'このブログのトラッキングを開始します',
	'Deny IP Addresses' => '除外IPアドレス',
);

1;
