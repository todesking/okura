Okura
=====

**Pure Ruby な形態素解析エンジン**

動作環境
--------
Ruby 1.9 の以下のバージョンで動作確認済
+ 1.9.2-p180
+ 1.9.3-p374
+ 1.9.3-p385


特徴
----

+ MeCab 互換形式の辞書フォーマットを使用 (コンパイル後のバイナリフォーマットは異なります)
+ Pure Ruby なので Windows でも Heroku みたいなとこでも動く (ことを目標にしています｡まだテストしてない｡)


使い方
------

okura コマンドで辞書構築とコンソールが使える

```
okura compile {辞書の場所} {コンパイル済み辞書の出力先}
okura console {コンパイル済み辞書の場所}
```


辞書
----
辞書はMeCab用のものが使用できます｡
+ http://sourceforge.jp/projects/naist-jdic/releases/
にあるmecab-naist-jdicで動作確認しています｡


