Z-MUSIC Ver.3.02C
			[はじめに]


・97年1月中旬にソフトバンクより『Z-MUSICシステム ver.3.0』(ISBN4-7973-0184-8,
  元Oh!X編集部編,定価6,800円(税込み))が発売になりました。
　冊子マニュアル,5"FD2枚+CDROM1枚という構成です。
　ムック版にはオンラインでは配布不可能な(AD)PCMデータが2000種類以上、
  100種類以上のフリーソフト(収録を許可して下さった作者の方々に感謝いたします)、
  100曲以上のサンプル曲を収録しています。


			[実行方法]


  Z-MUSIC用演奏データである「ZMS」ファイルを演奏するには以下のようにします。

	A>ZMSC3				(マネージャ常駐)
	A>ZMC -L			(コンパイラ常駐)
	A>ZP3 filename

　コンパイラ(ZMC)へのパスが通っている場合は

	A>ZMSC3				(マネージャ常駐)
	A>ZP3 filename.ZMS

として、コンパイラを常駐しなくても演奏が出来ます。

　演奏時になんらかのエラーが発生した場合は

	A>ZMC filename

　としてコンパイルしてみてください。エラー箇所が表示されます。
　　リダイレクトして

	A>ZMC filename > err
	A>ED err

　としてエラーファイルを生成し、これからタグジャンプしてソースを
　修正することもできます。

　　なお、

	A>ZMC filename

　としてコンパイルに成功するとZMDファイルが出力されます。これを
　演奏する場合もコンパイラは不要ですので

	A>ZMSC3				(マネージャ常駐)
	A>ZP3 filename

　として演奏が行えます。


			[制限事項]


・現在以下の不具合が分かっています。

1.波形メモリ	
  振幅を与えることが出来るようになった関係で、波形メモリを使用した曲では
  演奏した感じが異なる場合がある。

2.絶対音長1
  Z-MUSIC ver.2.0以前ではOPMDRV.Xとの互換を保つために絶対音長1に対して
  強制的に「タイ／スラー」指定として処理していたが汎用性を考え、これを
  取り止めた。

※以上2点の動作相違点は

	A>ZMSC3.X -2

として常駐するか

	A>ZP3.R -2 filename.zms

として演奏させることにより解消することが出来ます。


			[注意]


・ZMUSIC Ver.2.0以前用の周辺ツールはまったく使用できません。
  バージョンチェックが不十分なツールは確実に暴走してしまいます。


			[MPCM.Xについて]


・MPCM.Xはwachoman氏の作品です。音量音程変換機能を搭載しています。
　MPCM.XとZMUSIC Ver.3.0上で、PCM8.X対応のZMUSIC Ver.2.0の曲を
  演奏させる時は

A>MPCM.X
A>ZMSC3.X

　のように先にMPCMを常駐させてからZMSC3.Xを常駐させてください。

※負荷がかかると音切れを起こすことがあります。


			[転載について]


・転載は無断で自由に行って構いませんが、転載先で発生した動作不具合報告は
  なるべく報告お願いします。

・アーカイヴ内容の改変は、内容を減らす場合に限っては自由に行って結構です。
  (サンプル曲やドキュメント類をアーカイヴから削除する、など)


			[アフターサポートについて]


・Z-MUSIC Ver.3.0が意図した動作をしない場合は、その問題を生じる演奏データを
  添付してください。データまるごとでもいいのですが、なるべくなら状況を再現
  出来るようにまとめた小さなものにしていただけるとたすかります。
　なお、意見、要望、バグ報告は報告は


●Z-MUSICホームページ		(http://www.z-z-z.gr.jp/zmusic/)

にお願いします。

			[付属ファイルについて]


　このアーカイヴにはZ-MUSICの基本プログラム以外に
 
1) EDZCOM.BAT
2) EDRCOM.BAT
3) OMAKE.LZH
4) ZM3MACRO.LZH
5) MINTPATCH.LZH

が収録されています。

　1),2)はテキストエディタEDR,EDZ用のバッチファイルで、EDR,EDZ使用中にF2キーを

押せば自動的に編集中のZMSを演奏することが出来ます。

(以下そのバッチファイルの内容)
------------------------------------------------------------------------------
echo off
echo %1.%2 を演奏します。
ZP3 %1.%2
------------------------------------------------------------------------------

  3)はFM音源の音色やZSV.Rの拡張フォントなどを、4)はデータ作成の際に便利な
マクロ(阿吽作)を、5)はファイラーMINTのZMUSIC Ver.3.0対応パッチ(MZL作)を
収録しています。
　それぞれの具体的な使い方については各アーカイヴに含まれる説明ドキュメントを
参照してください。


		[Z-MUSIC Ver.3.0対応アプリケーション]


　現在、Z-MUSIC Ver.3.0対応のアプリケーションには以下のようなものがあります。
(作者敬称略)

・PCM8A.X Ver.1.01以降
  機能:MPCM.Xの互換機能を持つポリフォニックADPCMドライバ。
  作者:Philly
  所在:NIFTY-SERVE(FSHARP)

・ZMR.X
　機能:Z-MUSIC Ver.3.0用の演奏データを演奏しながらSMF(Format1)にコンバートする。
　作者:じんべ
　所在:http://www.imasy.or.jp/~jimbe/

・Z2M3.X
  機能:ZMS→SMFコンバータ
　作者:やぎ
　所在:http://www2s.biglobe.ne.jp/~yyagi/


・ZMEMINFO.X
  機能:Z-MUSIC Ver.3.0のメモリ使用状況を表示する
　作者:じんべ
　所在:http://www.imasy.or.jp/~jimbe/

・ZII.X
　機能:1/10秒毎にZ-MUSIC Ver.3の演奏情報を表示する
　作者:じんべ
　所在:http://www.imasy.or.jp/~jimbe/

・ZMC_SMF.X
　機能:SMF→ZMDコンバータ
　作者:じんべ
　所在:http://www.imasy.or.jp/~jimbe/

・SMFTOZ3S.X
  機能:SMF→ZMSコンバータ
　作者:じんべ
　所在:http://www.imasy.or.jp/~jimbe/

・ZMC_RCP.X
  機能:RCP→ZMDコンバータ
　作者:じんべ
　所在:http://www.imasy.or.jp/~jimbe/

・ZSY.X
　機能:ZMSファイルのトータルステップタイムと小節数を表示する
　作者:ｶｼｭｱﾝﾇ
　所在:MIYA-NET(048-650-1234)

・楽譜エディタ
　機能:楽譜入力方式のシーケンス・ソフトウェア
  作者:(U)
  所在:MIYA-NET(048-650-1234)

・MMDSP.R
　機能:ビジュアルプレイヤ&演奏データセレクタ
　作者:ちとら(Miahmie,Gao)
　所在:MIYA-NET(048-650-1234)


			[謝辞]


・バグ情報を提供してくれた

	阿吽,TTN,Wachoman,ENG,マッチュン,MZL
	立花えりりん,じんべ,kuny,MASA,やぎ
	田村彰啓,DKハヤト,りすとらん,島田彰,酒匂
	SF-2

　各氏(敬称略,順不同)に感謝します。
------------------------------------------------------------------------------
FILENAME:ZM302C_X.LZH
