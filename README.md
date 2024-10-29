# ZMUSIC SYSTEM Ver.3系ソースコード

西川善司氏の作成されたZMUSIC SYSTEM Ver.3.0系のソースコードです。  
改造版をブランチにコミットします。

PCやネット上で扱いやすくするために、このリポジトリ内のテキストファイルは以下の変更がされています。
* 文字コードをUTF-8に変更。
* 改行をLFに変更。
* ファイル末尾の`EOF`制御記号を削除。
* ファイル名の整理(小文字化、数字のゼロ詰めなど)。
* ファイル拡張子の整理(ドキュメント.txt、ソース.s、マクロ.mac)。

ビルドにおける可搬性の向上のため、以下の変更がされています。
* バッチファイル削除、Makefile追加。
* その他、同一ファイルを生成するための調整。


## Manual

* [まえがき](manual/zm00.txt)
* [MEASURE &nbsp;1: イントロダクション](manual/zm01.txt)
* [MEASURE &nbsp;2: ZMSC3.X/ZMC.Xのオプション・スイッチ](manual/zm02.txt)
* [MEASURE &nbsp;3: X-BASIC用外部関数MUSICZ3.FNC](manual/zm03.txt)
* [MEASURE &nbsp;4: ZMSコマンド](manual/zm04.txt)
* [MEASURE &nbsp;5: MMLコマンド](manual/zm05.txt)
* [MEASURE &nbsp;6: ZPCONV3.RとZPLK.R)](manual/zm06.txt)
* [MEASURE &nbsp;7: ZP3.R](manual/zm07.txt)
* [MEASURE &nbsp;8: ZVT.X](manual/zm08.txt)
* [MEASURE &nbsp;9: スタンダードMIDIファイルとローランドエクスクルーシブ](manual/zm09.txt)
* [MEASURE 10: ZMUSIC Ver.3.0のファンクションコール](manual/zm10.txt)
* [MEASURE 11: エラー](manual/zm11.txt)
* [MEASURE 12: ZMD/ZPDフォーマット](manual/zm12.txt)
* [MEASURE 13: ワークエリアとワークビュアZSV.R](manual/zm13.txt)
* [MEASURE 14: 効果音モードと外部プログラムとの同期](manual/zm14.txt)
* [MEASURE 15: MPCM.X](manual/zm15.txt)
* [MEASURE 16: C言語ライブラリ](manual/zm16.txt)
* [用語解説](manual/glossary.txt)

<!-- -->
* 非公式情報: [既知の不具合](https://github.com/kg68k/x68.memo/blob/main/tool/bugs.md#z-music-ver302c)


## Build

X680x0上でビルドする際には、ソースファイルのUTF-8からShift_JISへの変換が必要です。

### u8tosjを使用する方法

あらかじめ、[u8tosj](https://github.com/kg68k/u8tosj)をインストールしておいてください。

トップディレクトリで`make`を実行してください。以下の処理が行われます。
1. `build/`ディレクトリの作成。
3. `src/`内のファイルをShift_JISに変換して`build/`へ保存。

次に、カレントディレクトリを`build/`に変更し、`make`を実行してください。
実行ファイルが作成されます。

### u8tosjを使用しない方法

`src/`内のファイルを適当なツールで適宜Shift_JISに変換してから`make`を実行してください。
UTF-8のままでは正しくビルドできませんので注意してください。

## zmsc3lib.a

zmsc3lib.aのビルドについては、ZM302_L.LZHに含まれるZMSC3LIB.A、ZMSC3LIB.L
と同一のファイルを生成するために処理が多くなっています。

ライブラリの改造版を作る場合は、src/lib/Makefileの下記部分のコメントアウトを逆にして
libzmsc3.aをベースとして作成することをおすすめします。
```Makefile
#TARGET = libzmsc3.a
TARGET = ZMSC3LIB.A ZMSC3LIB.L
```


## License
ZM1.MAN「１．３．  著作権について」の項より引用:

>   法律上、日本では著作権の放棄ができませんので、著作権は作者西川善司に  
> 保留されます。しかし、プログラムの性質上、「ＺＭＵＳＩＣ」のオリジナルを  
> 開発した私、西川善司は「ＺＭＵＳＩＣ」及びこれらを支援するプログラム  
> (サブルーチンを含む)全ての使用権に関するライセンス権を放棄します。  
> よってとくに断らずに商的利用が出来ます。つまり市販だろうが同人だろうが勝手に  
> 「ＺＭＳＣ３．Ｘ」を組み込んだソフトを販売してもいいということです。  


## Author
ZMUSICの作者は西川善司氏です。  

このリポジトリの作成はTcbnErikによるものです。  
https://github.com/kg68k/zmusic3
