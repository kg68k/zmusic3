/*エラーメッセージ関係・ソース・ジェネレート・プログラム
dim str j(300)[256],e(300)[256]
str buf[256]
int fh,t
i=0
/*	SYSTEM 関係	*/
e(i)="OUT OF MEMORY"
j(i)="メモリが不足しています"        :i=i+1
e(i)="UNIDENTIFIED FILE"
j(i)="ZMUSICシステムのファイルではありません"        :i=i+1
e(i)="ILLEGAL VERSION NUMBER"
j(i)="バージョン番号が違います"        :i=i+1
e(i)="ILLEGAL FILENAME"
j(i)="ファイル名が異常です"        :i=i+1
e(i)="MISSING FILENAME"
j(i)="ファイル名がありません"        :i=i+1
e(i)="FILE NOT FOUND"
j(i)="ファイルが見つかりません"                :i=i+1
e(i)="ILLEGAL FILE SIZE"
j(i)="ファイルのサイズが異常です"                :i=i+1
e(i)="READ ERROR"
j(i)="ディスクからの読み込みに失敗しました"        :i=i+1
e(i)="TOO MANY INCLUDE FILES"
j(i)="インクルードファイルが多すぎます"        :i=i+1
e(i)="NO ZMD ERROR"
j(i)="汎用バッファ内にはZMUSICが扱えるZMDがありません"        :i=i+1
e(i)="UNIDENTIFIED MEMORY"
j(i)="ZMUSICシステムに無関係のメモリブロックです"        :i=i+1
e(i)="COMPILER NOT AVAILABLE"
j(i)="コンパイラが常駐していないのでコンパイルは出来ません"        :i=i+1
e(i)="COMPILE ERROR"
j(i)="コンパイラでエラーが発生しました"        :i=i+1
e(i)="NO APPLICATION REGISTERED"
j(i)="アプリケーションは登録されていません"        :i=i+1
e(i)="ILLEGAL RESULT CODE"
j(i)="リザルトコードが異常です"        :i=i+1
e(i)="ILLEGAL ZMD CODE"
j(i)="規定外のZMDを参照しました"        :i=i+1
e(i)="ILLEGAL FUNCTION NUMBER"
j(i)="規定外のファンクションコールを参照しました"        :i=i+1
e(i)="NO PERFORMANCE DATA"        
j(i)="演奏データが存在しません"        :i=i+1
e(i)="UNMANAGEABLE DATA SEQUENCE"        
j(i)="未対応のデータ構造です"        :i=i+1
e(i)="THE DEVICE ALREADY OCCUPIED"        
j(i)="すでにそのデバイスは占有されています"        :i=i+1
e(i)="RECUSIVE INCLUDE ERROR"
j(i)="同じファイルをインクルードしようとしました"			        :i=i+1
e(i)="ILLEGAL MEMORY BLOCK SIZE"
j(i)="メモリブロックサイズが異常です"			        :i=i+1
e(i)="`3"        
j(i)="~3"			        :i=i+1
/*	CHANNEL 関係	*/
e(i)="ILLEGAL CHANNEL"
j(i)="規定外のチャンネル番号を指定しました"        :i=i+1
e(i)="`4"        
j(i)="~4"			        :i=i+1
e(i)="`5"        
j(i)="~5"			        :i=i+1
e(i)="`6"        
j(i)="~6"			        :i=i+1
/*	トラック関係	*/
e(i)="ILLEGAL TRACK NUMBER"
j(i)="規定外のトラック番号を指定しました"        :i=i+1
e(i)="TRACK COMMAND ERROR"
j(i)="演奏データ登録コマンドの使用法に誤りがあります"        :i=i+1
e(i)="TOO MANY TRACKS"
j(i)="トラック数が多すぎます"        :i=i+1
e(i)="ILLEGAL TRACK SIZE"
j(i)="トラックサイズが異常です"        :i=i+1
/*e(i)="ILLEGAL TRACK STAT"
/*j(i)="未定義のトラック状態を設定しようとしました"        :i=i+1
/*e(i)="ILLEGAL TRACK MODE"
/*j(i)="未定義のトラックのモードを設定しようとしました"        :i=i+1
e(i)="ILLEGAL TRACK VOLUME"
j(i)="トラック音量の値が異常です"        :i=i+1
e(i)="ILLEGAL TRACK FREQUENCY"
j(i)="トラック処理頻度値が異常です"        :i=i+1
e(i)="UNDEFINED TRACK REFERRED"
j(i)="未定義のトラックを参照しました"        :i=i+1
e(i)="TRACK NUMBER REDESIGNATION"
j(i)="同一のトラックが重複して指定されています"        :i=i+1
e(i)="`7"        
j(i)="~7"			        :i=i+1
e(i)="`8"        
j(i)="~8"			        :i=i+1
e(i)="`9"        
j(i)="~9"			        :i=i+1
/*	パターントラック関係	*/
e(i)="PATTERN NAME REDEFINITION"
j(i)="パターン名が重複しています"        :i=i+1
e(i)="PATTERN NAME TOO LONG"
j(i)="パターン名が長すぎます"        :i=i+1
e(i)="PATTERN NAME CANNOT BE OMITTED"
j(i)="パターン名は省略できません"        :i=i+1
e(i)="NULL PATTERN ERROR"
j(i)="空のパターンは定義できません"        :i=i+1
e(i)="PATTERN NOT AVAILABLE"
j(i)="パターンは使用できません"        :i=i+1
e(i)="UNDEFINED PATTERN"
j(i)="未定義のパターンを指定しました"        :i=i+1
e(i)="ILLEGAL COMMAND IN PATTERN"
j(i)="パターンに含められないコマンドを使用しました"        :i=i+1
e(i)="`A"       
j(i)="~A"			        :i=i+1
e(i)="`B"        
j(i)="~B"			        :i=i+1
e(i)="`C"        
j(i)="~C"			        :i=i+1
/*	音色関係	*/
e(i)="ILLEGAL BANK NUMBER"
j(i)="規定外のバンク番号を指定しました"        :i=i+1
e(i)="ILLEGAL TIMBRE NUMBER"
j(i)="規定外の音色番号を指定しました"        :i=i+1
e(i)="ILLEGAL TONE NUMBER"
j(i)="規定外のトーン番号を指定しました"        :i=i+1
e(i)="NO TIMBRE PARAMETERS"
j(i)="FM音源音色のパラメータはありません"        :i=i+1
e(i)="ILLEGAL TIMBRE PARAMETER"
j(i)="規定外の音色パラメータが設定されています"        :i=i+1
e(i)="TIMBRE PARAMETER SHORTAGE"
j(i)="音色パラメータが不足しています"        :i=i+1
e(i)="TIMBRE NAME TOO LONG"
j(i)="音色名が長すぎます"        :i=i+1
e(i)="EMPTY TIMBRE NUMBER"
j(i)="空の音色番号を参照しました"        :i=i+1
e(i)="`D"        
j(i)="~D"			        :i=i+1
e(i)="`E"        
j(i)="~E"			        :i=i+1
e(i)="`F"        
j(i)="~F"			        :i=i+1
/*	ノートナンバー関係	*/
e(i)="ILLEGAL NOTE NUMBER"
j(i)="規定外のノートナンバーを指定しました"        :i=i+1
e(i)="ILLEGAL NOTE LENGTH"
j(i)="音長値が規定範囲外です"        :i=i+1
e(i)="EMPTY NOTE NUMBER"
j(i)="空のノート番号を参照しました"        :i=i+1
e(i)="TOO MANY NOTES"
j(i)="音符が多すぎます"        :i=i+1
e(i)="`G"        
j(i)="~G"			        :i=i+1
e(i)="`H"        
j(i)="~H"			        :i=i+1
e(i)="`I"        
j(i)="~I"			        :i=i+1
/*	ADPCM/WAVE関係	*/
e(i)="PROCESSING SIZE TOO LARGE"
j(i)="加工処理サイズが大きすぎます"        :i=i+1
e(i)="UNDEFINED PPC"
j(i)="未定義のPCM加工コマンドです"        :i=i+1
e(i)="UNDEFINED LOOP TYPE"
j(i)="未定義のADPCM/PCMループタイプが指定されています"        :i=i+1
e(i)="ILLEGAL FREQUENCY VALUE"
j(i)="周波数の値が規定外です"        :i=i+1
e(i)="CUT OFF LEVEL TOO BIG"
j(i)="切り捨てレベルが大きすぎます"        :i=i+1
e(i)="WAVE COMMAND ERROR"
j(i)="波形メモリ登録コマンドエラーです"        :i=i+1
e(i)="ILLEGAL WAVE NUMBER"
j(i)="波形番号が異常です"        :i=i+1
e(i)="ILLEGAL WAVE VALUE"
j(i)="波形メモリ値が規定外です"                         :i=i+1
e(i)="ILLEGAL LOOP START POINT"
j(i)="ループ開始ポイントの位置が異常です"        :i=i+1
e(i)="ILLEGAL LOOP END POINT"
j(i)="ループ終了ポイントの位置が異常です"        :i=i+1
e(i)="`J"        
j(i)="~J"			        :i=i+1
e(i)="`K"        
j(i)="~K"			        :i=i+1
e(i)="`L"        
j(i)="~L"			        :i=i+1
/*	デバイス関係	*/
e(i)="DEVICE OFFLINE"
j(i)="そのデバイスは未接続です"        :i=i+1
e(i)="ILLEGAL INTERFACE NUMBER"
j(i)="インターフェース番号(名前)が規定外です"        :i=i+1
e(i)="ILLEGAL DEVICE ID"        
j(i)="デバイスIDの値が規定外です"        :i=i+1
e(i)="DEVICE ID REDESIGNATION"
j(i)="同一デバイスが重複して指定されています"        :i=i+1
e(i)="`M"        
j(i)="~M"			        :i=i+1
e(i)="`N"        
j(i)="~N"			        :i=i+1
e(i)="`O"        
j(i)="~O"			        :i=i+1
/*	MIDI楽器関係	*/
e(i)="ILLEGAL PART NUMBER"
j(i)="パート番号が異常です"        :i=i+1
e(i)="ILLEGAL MODEL ID"
j(i)="モデルIDの値が規定外です"        :i=i+1
e(i)="ILLEGAL MAKER ID"
j(i)="メーカーIDの値が規定外です"        :i=i+1
e(i)="ILLEGAL MAP NUMBER"
j(i)="マップ番号が規定外です"        :i=i+1
e(i)="ILLEGAL PARTIAL NUMBER"
j(i)="パーシャル番号が規定外です"        :i=i+1
e(i)="ILLEGAL PATCH NUMBER"
j(i)="パッチ番号が規定外です"        :i=i+1
e(i)="`P"        
j(i)="~P"			        :i=i+1
e(i)="`Q"        
j(i)="~Q"			        :i=i+1
e(i)="`R"        
j(i)="~R"			        :i=i+1
/*	一般的エラー
e(i)="SYNTAX ERROR"
j(i)="文法エラーです"        :i=i+1
e(i)="ASSIGN COMMAND ERROR"
j(i)="チャンネル／トラック・割り当てコマンドの使用法に誤りがあります"        :i=i+1
e(i)="ILLEGAL OCTAVE"
j(i)="規定外のオクターブを指定しました"        :i=i+1
e(i)="ILLEGAL PITCH VALUE"
j(i)="ピッチの値が規定外です"        :i=i+1
e(i)="ILLEGAL VOLUME VALUE"
j(i)="音量の値が規定外です"        :i=i+1
e(i)="ILLEGAL VELOCITY VALUE"
j(i)="ベロシティの値が規定外です"        :i=i+1
e(i)="ILLEGAL AFTERTOUCH VALUE"
j(i)="アフタータッチの値が規定外です"        :i=i+1
e(i)="ILLEGAL PANPOT VALUE"
j(i)="パンポットの値が規定外です"        :i=i+1
e(i)="ILLEGAL DAMPER VALUE"
j(i)="ダンパーの値が規定外です"        :i=i+1
e(i)="`S"        
j(i)="~S"			        :i=i+1
e(i)="`T"        
j(i)="~T"			        :i=i+1
e(i)="`U"        
j(i)="~U"			        :i=i+1
/*	書式関係	*/
e(i)="ILLEGAL COMMAND LINE"
j(i)="コマンド書式に誤りがあります"        :i=i+1
e(i)="ILLEGAL COMMAND ORDER"
j(i)="コマンドの使用順序が規定外です"        :i=i+1
e(i)="INAPPROPRIATE COMMAND"
j(i)="不適切なコマンドが使用されています"        :i=i+1
e(i)="PARAMETER BREAK OFF"
j(i)="パラメータが途中で終わっています"        :i=i+1
e(i)="PARAMETER SHORTAGE"
j(i)="パラメータが少なすぎます"        :i=i+1
e(i)="MISSING OPERAND"
j(i)="パラメータがあるべきところに有りません"        :i=i+1
e(i)="UNEXPECTED OPERAND"
j(i)="予期しないパラメータが設定されました"        :i=i+1
e(i)="ILLEGAL PARAMETERS COMBINATION"
j(i)="パラメータの組み合わせが規定外です"        :i=i+1
e(i)="REASSIGNMENT ERROR"
j(i)="同一トラックを複数のチャンネルに割り当てようとしました"        :i=i+1
e(i)="ILLEGAL NESTING ERROR"
j(i)="括弧の対応に誤りがあります"        :i=i+1
e(i)="PARAMETER CANNOT BE OMITTED"
j(i)="このパラメータの省略はできません"        :i=i+1
e(i)="COMMAND LINE BREAK OFF"
j(i)="コマンドラインが途中で終了しています"        :i=i+1
e(i)="ILLEGAL OPERAND"
j(i)="規定外のオペランドです"        :i=i+1
e(i)="ILLEGAL PARAMETER FORMAT"
j(i)="パラメータのフォーマットが規定外です"        :i=i+1
e(i)="`V"
j(i)="~V"				:i=i+1
e(i)="`W"
j(i)="~W"			        :i=i+1
e(i)="`X"
j(i)="~X"			        :i=i+1
/*	連符関係	*/
e(i)="EMPTY BRACE ERROR"
j(i)="{}の中身が空です"        :i=i+1
e(i)="ILLEGAL COMMAND IN BRACE"
j(i)="{}の中には含められないコマンドを使用しました"        :i=i+1
e(i)="TOO MANY PARAMETERS"
j(i)="パラメータの数が多すぎます"        :i=i+1
e(i)="GROUP NOTES COMMAND ERROR"
j(i)="連符コマンドの使用法に誤りがあります"        :i=i+1
e(i)="`Y"
j(i)="~Y"			        :i=i+1
e(i)="`Z"
j(i)="~Z"			        :i=i+1
e(i)="`a"
j(i)="~a"			        :i=i+1
/*	文字列関係	*/
e(i)="KANJI BREAK OFF"
j(i)="全角文字が1バイトのみで終わっています"        :i=i+1
e(i)="ILLEGAL STRING LENGTH"
j(i)="文字列の長さが異常です"        :i=i+1
e(i)="STRING BREAK OFF"
j(i)="文字列の終端が見つかりません"        :i=i+1
e(i)="STRING TOO LONG"
j(i)="文字列が長すぎます"        :i=i+1
e(i)="`b"        
j(i)="~b"			        :i=i+1
e(i)="`c"        
j(i)="~c"			        :i=i+1
e(i)="`d"        
j(i)="~d"			        :i=i+1
/*	その他	*/
e(i)="ILLEGAL DATA SIZE"
j(i)="データサイズが異常です"        :i=i+1
e(i)="DELAY TOO LONG"
j(i)="ディレイが長すぎます"        :i=i+1
e(i)="ILLEGAL DELAY"
j(i)="ディレイが規定外です"        :i=i+1
e(i)="HOLD TIME TOO LONG"
j(i)="ホールドタイムが長すぎます"        :i=i+1
e(i)="BEND TIME TOO LONG"
j(i)="ピッチベンドタイムが長すぎます"        :i=i+1
e(i)="ILLEGAL BEND RANGE"
j(i)="ピッチベンド幅が有効範囲を超えています"        :i=i+1
e(i)="OFFSET TOO LONG"
j(i)="オフセットが長すぎます"        :i=i+1
e(i)="SIZE TOO LARGE"
j(i)="サイズが大きすぎます"        :i=i+1
e(i)="ILLEGAL PARAMETER VALUE"
j(i)="データが規定外です"        :i=i+1
e(i)="ILLEGAL CHARACTER"
j(i)="この文字は使用できません"        :i=i+1
e(i)="ILLEGAL SWITCH VALUE"
j(i)="規定外のスイッチを設定しようとしました"        :i=i+1
e(i)="ILLEGAL CATEGORY EVENT"
j(i)="規定外の種類のイベントを設定しようとしました"        :i=i+1
e(i)="UNKNOWN EVENT CLASS"
j(i)="未知のイベントデータを設定しました"        :i=i+1
e(i)="KEY TRANSPOSE OUT OF RANGE"
j(i)="キートランスポーズが有効範囲を超えて設定されました"     :i=i+1
e(i)="ILLEGAL EFFECT PARAMETER"
j(i)="エフェクターへのパラメータが規定外です"     :i=i+1
e(i)="ILLEGAL NOISE PARAMETER"
j(i)="ノイズパラメータが規定外です"     :i=i+1
e(i)="UNDEFINED ZMD CODE"
j(i)="未定義のZMDです"     :i=i+1
e(i)="ERROR IN DIVISION"
j(i)="音長計算の割り算で商が0になりました"     :i=i+1
e(i)="ILLEGAL TIME VALUE"
j(i)="時間の値が規定外です"     :i=i+1
e(i)="`e"        
j(i)="~e"			        :i=i+1
e(i)="`f"        
j(i)="~f"			        :i=i+1
e(i)="`g"        
j(i)="~g"			        :i=i+1
/*	テンポ関係	*/
e(i)="TEMPO COMMAND ERROR"
j(i)="テンポコマンドの使用法に誤りがあります"        :i=i+1
e(i)="ILLEGAL TEMPO VALUE"
j(i)="テンポの値が規定外です"        :i=i+1
e(i)="`h"        
j(i)="~h"			        :i=i+1
/*	繰り返し関係	*/
e(i)="ILLEGAL REPEAT TIME"
j(i)="繰り返し回数が規定外です"        :i=i+1
e(i)="DISORDERLY REPEAT STRUCTURE"
j(i)="繰り返し構造が異常です"        :i=i+1
e(i)="`i"        
j(i)="~i"			        :i=i+1
e(i)="`j"        
j(i)="~j"			        :i=i+1
/*	調号関係	*/
e(i)="TOO MANY SIGNS"
j(i)="臨時記号が多すぎます"        :i=i+1
e(i)="ILLEGAL SIGN"
j(i)="未知の臨時記号が設定されました"        :i=i+1
e(i)="UNKNOWN KEY DECLARED"
j(i)="未知の調号が設定されました"        :i=i+1
e(i)="`k"        
j(i)="~k"			        :i=i+1
e(i)="`l"        
j(i)="~l"			        :i=i+1
e(i)="`m"        
j(i)="~m"			        :i=i+1
/*	ポルタメント	*/
e(i)="PORTAMENT TIME TOO LONG"
j(i)="ポルタメントタイムが長すぎます"        :i=i+1
e(i)="PORTAMENT COMMAND ERROR"
j(i)="ポルタメントコマンドの使用法に誤りがあります"        :i=i+1
e(i)="`n"        
j(i)="~n"			        :i=i+1
e(i)="`o"        
j(i)="~o"			        :i=i+1
/*	和音	*/
e(i)="CHORD COMMAND ERROR"
j(i)="和音コマンドの使用法に誤りがあります"        :i=i+1
e(i)="`p"        
j(i)="~p"			        :i=i+1
e(i)="`q"        
j(i)="~q"			        :i=i+1
e(i)="`r"        
j(i)="~r"			        :i=i+1
/*	レジスタパラメータエラー	*/
e(i)="ILLEGAL REGISTER NUMBER"
j(i)="レジスタ番号が規定外です"        :i=i+1
e(i)="UNKNOWN REGISTER NAME"
j(i)="未知のレジスタ名を指定しました"        :i=i+1
e(i)="ILLEGAL CONTROL NUMBER"
j(i)="規定外のコントロールを指定しました"        :i=i+1
e(i)="`s"        
j(i)="~s"			        :i=i+1
e(i)="`t"        
j(i)="~t"			        :i=i+1
/*	各種モード	*/
e(i)="ILLEGAL MODE VALUE"
j(i)="モード値が規定外です"        :i=i+1
e(i)="UNDEFINED MODE"
j(i)="未定義のモードを設定しようとしました"        :i=i+1
e(i)="ILLEGAL TIE MODE"
j(i)="規定外のタイモードを設定しようとしました"        :i=i+1
e(i)="ILLEGAL RESERVATION"
j(i)="規定外の予約を行おうとしました"        :i=i+1
e(i)="`u"        
j(i)="~u"			        :i=i+1
e(i)="`v"        
j(i)="~v"			        :i=i+1
e(i)="`w"        
j(i)="~w"			        :i=i+1
/*	モジュレーション関係	*/
e(i)="ILLEGAL DEPTH VALUE"
j(i)="振幅が規定外です"        :i=i+1
e(i)="SPEED TOO SLOW"
j(i)="スピードが遅すぎます"        :i=i+1
e(i)="ILLEGAL SPEED VALUE"
j(i)="スピードが規定外です"        :i=i+1
e(i)="ILLEGAL ARCC CONTROL"
j(i)="規定外のARCCコントロールを設定しました"       :i=i+1
e(i)="ILLEGAL RESET VALUE"
j(i)="リセット値が規定外です"       :i=i+1
e(i)="ILLEGAL WAVE ORIGIN"
j(i)="規定外の波形の基準点を設定しました"       :i=i+1
e(i)="UNDEFINED PHASE TYPE"
j(i)="未定義の位相タイプを指定しました"			        :i=i+1
e(i)="`y"        
j(i)="~y"			        :i=i+1
e(i)="`z"        
j(i)="~z"			        :i=i+1
/*	フェーダー関係	*/
e(i)="ILLEGAL FADER LEVEL"
j(i)="規定外のフェーダーレベルを設定しようとしました"        :i=i+1
e(i)="ILLEGAL FADER SPEED"
j(i)="規定外のフェーダースピードを設定しようとしました"        :i=i+1
e(i)="`ｱ"        
j(i)="~ｱ"			        :i=i+1
e(i)="`ｲ"        
j(i)="~ｲ"			        :i=i+1
e(i)="`ｳ"        
j(i)="~ｳ"			        :i=i+1
/*	拍子/クロック
e(i)="ILLEGAL MASTER CLOCK"
j(i)="マスタークロックの値が規定外です"        :i=i+1
e(i)="ILLEGAL METER"
j(i)="規定外の拍子を設定しようとしました"        :i=i+1
e(i)="`ｴ"        
j(i)="~ｴ"			        :i=i+1
e(i)="`ｵ"        
j(i)="~ｵ"			        :i=i+1
/*	マクロ	*/
/*e(i)="MACRO NAME REDEFINITION"
/*j(i)="マクロ名が重複しています"        :i=i+1
e(i)="MACRO NAME TOO LONG"
j(i)="マクロ名が長すぎます"        :i=i+1
e(i)="MACRO NAME CANNOT BE OMITTED"
j(i)="マクロ名は省略できません"        :i=i+1
e(i)="`ｶ"        
j(i)="~ｶ"			        :i=i+1
e(i)="`ｷ"        
j(i)="~ｷ"			        :i=i+1
e(i)="`ｸ"
j(i)="~ｸ"			        :i=i+1
/*	ゲートタイム	*/
e(i)="ILLEGAL GATE RANGE"
j(i)="規定外のゲートタイムレンジを設定しようとしました"        :i=i+1
e(i)="ILLEGAL GATE TIME"
j(i)="規定外のゲートタイムを設定しようとしました"        :i=i+1
e(i)="`ｹ"
j(i)="~ｹ"			        :i=i+1
e(i)="`ｺ"
j(i)="~ｺ"			        :i=i+1
/*	ウォーニング	*/
e(i)="SURPLUS IN DIVISION"                        /*warning
j(i)="音長計算の割り算であまりが発生しました"        :i=i+1        /*warning
e(i)="ZMD DIRECTLY EMBEDDED"                        /*warning
j(i)="ZMDを直接埋め込みました"        :i=i+1        /*warning
e(i)="ILLEGAL FREQUENCY NUMBER"                        /*warning
j(i)="周波数番号が規定外です"        :i=i+1        /*warning
e(i)="SYNC AND JUMP CONTROL ARE USED AT THE SAME TIME"
j(i)="同期制御とジャンプ制御を同時に行っています":i=i+1
e(i)="`ｼ"
j(i)="~ｼ"			        :i=i+1
e(i)="`ｽ"
j(i)="~ｽ"			        :i=i+1
/*
fh=fopen("ZMERRMES.S","c")
/*
fwrites("err_mes_tbl_j:"+chr$(&HD)+chr$(&HA),fh)
for ii=0 to i-1
buf="	dc.w	j"+right$("000"+str$(ii),3)+"-err_mes_tbl_j"+chr$(&HD)+chr$(&HA)
fwrites(buf,fh)
next
/*
fwrites(chr$(&h9)+"ifndef no_english"+chr$(&HD)+chr$(&HA),fh)
fwrites("err_mes_tbl_e:"+chr$(&HD)+chr$(&HA),fh)
for ii=0 to i-1
buf="	dc.w	e"+right$("000"+str$(ii),3)+"-err_mes_tbl_e"+chr$(&HD)+chr$(&HA)
fwrites(buf,fh)
next
fwrites(chr$(&h9)+"endif"+chr$(&HD)+chr$(&HA),fh)
/*
fwrites("***** JAPANESE *****"+chr$(&HD)+chr$(&HA),fh)
for ii=0 to i-1
buf="j"+right$("000"+str$(ii),3)+":	dc.b	"+chr$(34)+j(ii)+chr$(34)+",0"+chr$(&HD)+chr$(&HA)
print buf;:fwrites(buf,fh)
next
/*
fwrites(chr$(&h9)+"ifndef no_english"+chr$(&HD)+chr$(&HA),fh)
fwrites("***** ENGLISH *****"+chr$(&HD)+chr$(&HA),fh)
for ii=0 to i-1
buf="e"+right$("000"+str$(ii),3)+":	dc.b	"+chr$(34)+e(ii)+chr$(34)+",0"+chr$(&HD)+chr$(&HA)
print buf;:fwrites(buf,fh)
next
fwrites(chr$(&h9)+"endif"+chr$(&HD)+chr$(&HA),fh)
fwrites(chr$(&h9)+".even"+chr$(&HD)+chr$(&HA),fh)
fcloseall()
/*
fh=fopen("ERROR.MAC","c")
fwrites("	.offset	0"+chr$(&HD)+chr$(&HA),fh)
fwrites(""+chr$(&HD)+chr$(&HA),fh)
/*
for ii=0 to i-1
buf=""
for jj=1 to len(e(ii))
if mid$(e(ii),jj,1)=" " then buf=buf+"_" else buf=buf+mid$(e(ii),jj,1)
next
buf=buf+":"
jj=len(buf):t=1
/*if        jj<32        then t=1
if        jj<24        then t=2
if        jj<16        then t=3
if        jj<8         then t=4
for jj=1 to t:buf=buf+chr$(9):next
buf=buf+"ds.b     1       *("+str$(ii)+")"+j(ii)+chr$(&HD)+chr$(&HA)
print buf;:fwrites(buf,fh)
next
fcloseall()
/*
fh=fopen("ERROR.LST","c")
for ii=0 to i-1
fwrites("エラーID:",fh):fwrites(str$(ii)+chr$(13)+chr$(10),fh)
fwrites("エラーメッセージ(ENGLISH):"+e(ii)+chr$(13)+chr$(10),fh)
fwrites("エラーメッセージ(日本語) :"+j(ii)+chr$(13)+chr$(10),fh)
next
fcloseall()
