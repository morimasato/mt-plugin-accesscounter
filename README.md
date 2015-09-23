# Access Counter for Movable Type
アクセスランキングを表示できます。ブログ記事のアクセス数をカウントします。アクセス数順で指定した数のブログ記事を一覧することができます。

ブログ記事のランキング表示は、MTEntries のモディファイア sort\_by に accessed\_count を指定します。

```
<mt:Entries sort_by="accessed_count">
...
</mt:Entries>
```

## 動作要件

* Movable Type 5.1（またはそれ以降）

## インストール
1. ファイルを解凍します。
2. mt-plugin-accesscounter/`AccessCounter` を `/path/to/mt/plugins` にコピーしてください。
3. `/path/to/mt/plugins`/AccessCounter/AccessCounter.cgi の権限を、755 に設定します。

## ブログのプラグイン設定画面

1. ブログを選択します。[ツール]→[プラグイン]のメニューを選んで、AccessCounter をクリックします。
1. [設定]をクリックして、AccessCounter の設定を行います。
1. 設定が終わったら、[変更を保存]をクリックします。
1. [再構築]を実行します。

![・トラッキング...このブログのトラッキングを開始します。<br>・除外IPアドレス... トラッキングしないリモートIPアドレスを設定します。](https://github.com/morimasato/mt-plugin-accesscounter/wiki/images/fig1.gif "")

## アクセスカウントの確認

ブログ記事の編集画面の右下に アクセスカウント が表示されています。

![・トラッキング...このブログのトラッキングを開始します。<br>・除外IPアドレス... トラッキングしないリモートIPアドレスを設定します。](https://github.com/morimasato/mt-plugin-accesscounter/wiki/images/fig2.gif "")


## テンプレート編集

MTEntries のモディファイア sort\_by に accessed\_count を指定します。
サンプルコードをウィジェットに登録すると、サイドバーに表示できます。

```
<mt:If tag="BlogEntryCount">
    <mt:Entries sort\_by="accessed\_count" sort\_order="descend" limit="10">
        <mt:EntriesHeader>
<div class="widget-recent-entries widget-archives widget">
    <h3 class="widget-header">アクセスランキング</h3>
    <div class="widget-content">
        <ul>
        </mt:EntriesHeader>
            <$mt:setvar name="rank" value="1" op="++"$>
            <li><a href="<$mt:EntryPermalink$>">#<$mt:var name="rank"$> <$mt:EntryTitle$></a></li>
        <mt:EntriesFooter>
        </ul>
    </div>
</div>
        </mt:EntriesFooter>
    </mt:Entries>
</mt:If>
```

## ライセンス
MIT License (MIT)
