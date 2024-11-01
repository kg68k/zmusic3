*-------------------------------------------------------
*	ＺＰＣＮＶ３.Ｒ Ver.3.00
*
*	(C)  ZENJI SOFT
*-------------------------------------------------------
	.include	doscall.mac
	.include	iocscall.mac
	.include	table.mac
	.include	z_global.mac
	.include	zmid.mac
	.include	zmd.mac
	.include	zpcnv.mac
	.include	error.mac

	.list
	.text
CMN_EXECUTE:	equ	$70
*-------- program start --------
	lea	$10(a0),a0	*メモリブロックの変更
	lea.l	user_sp(pc),a1
	suba.l	a0,a1
	pea	(a1)
	pea	(a0)
	DOS	_SETBLOCK
	addq.w	#8,sp
	tst.l	d0
	bmi	mem_error

	lea	work(pc),a6
	lea.l	user_sp(pc),sp	*スタック設定
	move.l	a3,env_bak-work(a6)

	move.l	#1024+1024+92+92,-(sp)	*ワーク確保
	DOS	_MALLOC
	addq.w	#4,sp
	move.l	d0,v_buffer-work(a6)
	bmi	mem_error
	add.l	#1024,d0
	move.l	d0,temp_buffer-work(a6)
	add.l	#1024,d0
	move.l	d0,open_fn-work(a6)
	add.l	#92,d0
	move.l	d0,filename-work(a6)

	pea	zpcnv3_opt(pc)		*'zpcnv3_opt'
	bsr	search_env
	addq.w	#4,sp
	tst.l	d0
	beq	@f
	move.l	a2,-(sp)
	move.l	d0,a2
	bsr	chk_optsw		*オプションスイッチ
	move.l	(sp)+,a2
@@:
	tst.b	(a2)+		*パラメータある?
	beq	print_hlp

	bsr	_skip_spc	*最初のファイル名までスキップ

	move.b	(a2),d0
	beq	print_hlp

	bsr	chk_optsw		*オプションスイッチ
	bsr	_skip_spc		*最初のファイル名までスキップ
	tst.b	(a2)
	beq	print_hlp

	lea	s_name(pc),a3
gets_lp:				*ソースファイル名のゲット
	move.b	(a2)+,d0
	bsr	chk_kanji
	bpl	@f
	move.b	d0,(a3)+		*漢字ケース
	move.b	(a2)+,(a3)+
	bra	gets_lp
@@:
	cmpi.b	#' ',d0
	bls	@f
	move.b	d0,(a3)+
	bra	gets_lp
@@:
	subq.w	#1,a2
	clr.b	(a3)			*end code
					*拡張子'CNF'セット
	lea	s_name(pc),a3
	clr.b	d1
	cmpi.w	#'..',(a3)
	bne	@f
	addq.w	#2,a3
@@:
	move.l	a3,d3
setfnlp:
	move.b	(a3)+,d0
	bsr	chk_kanji
	bpl	@f
	addq.w	#1,a3
	bra	setfnlp
@@:
	cmpi.b	#'.',d0
	bne	@f
	st.b	d1
	bra	setfnlp
@@:
	cmpi.b	#' ',d0
	bhi	setfnlp
	subq.w	#1,a3
	cmpi.b	#'.',-1(a3)	*ラストの文字が.だけか
	beq	@f
	tst.b	d1		*拡張子省略かどうか
	bne	set_edc_	*省略しなかった
	bra	set_kkc
@@:
	subq.w	#1,a3
set_kkc:
	move.b	#'.',(a3)+	*拡張子をセット
	move.b	#'C',(a3)+
	move.b	#'N',(a3)+
	move.b	#'F',(a3)+
	clr.b	(a3)
set_edc_:
	*(a3)=ソースネームの終端コード
	bsr	_skip_spc
	tst.b	(a2)		*終端コード？
	bne	get_dest_name	出力ファイル名の取りだし
mk_default_nm:			*デフォルトのファイル名を作る
	* < d3.l=始端アドレス
	* X d0/a0,a3
	move.l	d3,a3
	move.l	d3,a0
mdnlp:
	move.b	(a3)+,d0
	beq	do_mdn
	bsr	chk_kanji
	bpl	@f
	addq.w	#1,a3
	bra	mdnlp
@@:
	cmpi.b	#'\',d0
	beq	@f
	cmpi.b	#':',d0
	bne	mdnlp
@@:
	move.l	a3,a0
	bra	mdnlp
do_mdn:
	move.l	a0,a3
	lea	d_name(pc),a0
mdf_lp:
	move.b	(a3)+,d0
	bsr	chk_kanji
	bpl	@f
	move.b	d0,(a0)+
	move.b	(a3)+,(a0)+
	bra	mdf_lp
@@:
	cmpi.b	#' ',d0
	bls	exit_mdf
	cmpi.b	#'.',d0
	beq	exit_mdf
	move.b	d0,(a0)+
	bra	mdf_lp
get_dest_name:			*セーブファイル名のゲット
	cmpi.b	#'.',(a2)
	bne	@f
	cmpi.b	#'.',1(a2)
	bne	@f
	addq.w	#2,a2		*skip '..'
@@:
	lea	d_name(pc),a0
	moveq.l	#0,d1
getd_lp:
	move.b	(a2)+,d0
	bsr	chk_kanji
	bpl	@f
	move.b	d0,(a0)+
	move.b	(a2)+,(a0)+
	bra	getd_lp
@@:
	cmpi.b	#' ',d0
	bls	exit_mdf
	cmpi.b	#'.',d0
	beq	exit_mdf
	move.b	d0,(a0)+
	bra	getd_lp
exit_mdf:			*拡張子
	move.b	#'.',(a0)+
	move.b	#'Z',(a0)+
	move.b	#'P',(a0)+
	move.b	#'D',(a0)+
	clr.b	(a0)+
do_cnv_ope:
	bsr	print_title

	lea	s_name(pc),a2
	bsr	fopen
	tst.l	d5
	bmi	ropen_error	*ソースファイル読み込めず

	move.w	#32,-(sp)
	pea	d_name(pc)
	DOS	_CREATE
	addq.w	#6,sp
	move.w	d0,sfh-work(a6)	*save file handle
	bmi	wopen_error	*セーブファイル名に異常有り

	bsr	read		*d3=size/a5=address
	move.l	d3,d4
	move.l	a5,a4		*top addr
	add.l	a4,d4		*end addr
	move.l	a4,zms_addr-work(a6)
	move.l	#1,line_number-work(a6)
	move.l	a4,line_ptr-work(a6)
	move.l	a4,line_locate-work(a6)
	moveq.l	#0,d0				*グローバルワーク初期化
	move.l	d0,n_of_err-work(a6)
	move.l	d0,err_stock_addr-work(a6)
	move.l	d0,err_stock_size-work(a6)
	move.l	d0,zms_file_id-work(a6)
	move.l	d0,include_depth-work(a6)

	lea	compiling(pc),a1	*'COMPILING'
	bsr	prta1
	lea	s_name(pc),a1		*書きだしファイル名表示
	bsr	prta1
	bsr	PTT			*...

	moveq.l	#100,d2				*ファイルネームバッファ確保
	move.l	#ID_TEMP,d3			*filename...(0),
	jsr	get_mem-work(a6)		*インクルードしたファイルの読み込みアドレス
	tst.l	d0				*親ソースの最終ドレス
	bmi	m_out_of_memory			*親ソースのコンパイルアドレス(exit_sec)
	move.l	d2,erfn_size-work(a6)
	move.l	a0,erfn_addr-work(a6)
	clr.l	erfn_now-work(a6)
*	clr.l	erfn_recent0-work(a6)
*	clr.l	erfn_recent1-work(a6)

	move.l	#$1_0000,d2			*デフォルトバッファサイズ=64kb
	bsr	get_mem
	tst.l	d0
	bmi	mem_error
	move.l	a0,zmd_addr-work(a6)		*保存
	move.l	d2,zmd_size-work(a6)		*保存
	add.l	a0,d2
	move.l	d2,zmd_end-work(a6)
	* global	d4:ソースリストの最終アドレス＋1
	*		a0:共通コマンドのコンパイル結果格納先アドレス
	*		a4:現在走査中のソース
cmpl_lp:
	move.l	sp,sp_buf-work(a6)		*スタック保存
	move.l	a4,line_ptr-work(a6)
	bsr	skip_spc
	cmp.l	a4,d4
	bls	compile_end			*終了
	bsr	chk_num
	bpl	goto_reg_adpcm_data_by_no	*数値ならばADPCM登録(V2形式)
	moveq.l	#0,d0
	move.b	d0,now_cmd-work(a6)	*初期化
	move.b	(a4)+,d0
	bsr	chk_kanji
	bpl	@f
				*全角スキップ
	cmp.l	a4,d4		*1バイト目でファイル終端にきていないかチェック
	bls	m_kanji_break_off
	addq.w	#1,a4		*全角の2バイト目をスキップ
	bra	cmpl_lp
@@:
	cmpi.b	#$0a,d0		*改行
	beq	inc_line
	cmpi.b	#$1a,d0		*ファイル終端
	beq	compile_end	*終了
	cmpi.b	#' ',d0
	bls	cmpl_lp		*SPC以下(spcやtabその他のコントロールコード)なら無視
	cmpi.b	#'#',d0		*＃印のコマンド
	beq	shp_com
	cmpi.b	#'.',d0		*＃印のコマンド
	beq	shp_com
	cmpi.b	#'/',d0		*コメント行
	beq	skip_comment
	bra	m_syntax_error

goto_reg_adpcm_data_by_no	*数値ならばADPCM登録(V2形式)
	move.l	line_number-work(a6),d0		*compile_end以降で使用
	bsr	do_wrt_cmn_l
	move.l	line_ptr-work(a6),d0
	bsr	do_wrt_cmn_l
	bra	reg_adpcm_data_by_no	*数値ならばADPCM登録(V2形式)

inc_line:
	pea	cmpl_lp(pc)
cr_line:
	addq.l	#1,line_number-work(a6)
	move.l	a4,line_locate-work(a6)
	move.l	a4,line_ptr-work(a6)
	rts

skip_comment:			*case:コメント行(改行を見付けるまでループ)
	pea	cmpl_lp(pc)
do_skip_comment:
	move.w	d0,-(sp)
skcmlp:
	cmp.l	a4,d4
	bls	exit_skcmt	*終了
	move.b	(a4)+,d0
	bsr	chk_kanji	*漢字かどうかチェック
	bpl	@f
	cmp.l	a4,d4
	bls	exit_skcmt	*終了
	move.b	(a4)+,d0
	bra	skcmlp
@@:
	cmpi.b	#$0a,d0		*行終端でコメント終了
	bne	skcmlp
	subq.w	#1,a4
exit_skcmt:
	move.l	a4,line_ptr-work(a6)
	move.w	(sp)+,d0
	rts

find_end:			*終端 ')' '}' を見付ける処理
	bsr	skip_spc
@@:
	cmp.l	a4,d4
	beq	m_illegal_command_line
	cmp.b	#'}',(a4)+
	bne	m_illegal_command_line
	bra	cmpl_lp

shp_com:				*#コマンド系(.コマンド系)
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_command_line_break_off
	cmpi.b	#'!',(a4)
	beq	skip_comment		*#!はコメント
	lea	shp_com_tbl-work(a6),a1
	bsr	get_com_no
	bmi	m_syntax_error		*そのようなコマンドはない
	bsr	skip_spc		*skip separater(パラメータ無しのコマンドもあるから)
	add.w	d0,d0
	add.w	d0,d0
	move.l	sc_jmp_tbl(pc,d0.w),d1
tokurei:					*特例ケース
	tst.w	d0				*include fileならばポインタなし
	beq	@f
	cmpi.w	#$14,d0
	beq	@f
	move.l	line_number-work(a6),d0		*compile_end以降で使用
	bsr	do_wrt_cmn_l
	move.l	line_ptr-work(a6),d0
	bsr	do_wrt_cmn_l
@@:
	jmp	sc_jmp_tbl(pc,d1.l)

sc_jmp_tbl:					*＃コマンドのジャンプテーブル
	dc.l	include_file-sc_jmp_tbl		*$00 特例
	dc.l	reg_16bitpcm_timbre-sc_jmp_tbl	*$04 cmn_zmd
	dc.l	reg_16bitpcm_tone-sc_jmp_tbl	*$08 cmn_zmd
	dc.l	reg_8bitpcm_timbre-sc_jmp_tbl	*$0c cmn_zmd
	dc.l	reg_8bitpcm_tone-sc_jmp_tbl	*$10 cmn_zmd
	dc.l	set_adpcm_bank-sc_jmp_tbl	*$14 特例
	dc.l	reg_adpcm_timbre-sc_jmp_tbl	*$18 cmn_zmd
	dc.l	reg_adpcm_tone-sc_jmp_tbl	*$1c cmn_zmd
	dc.l	erase-sc_jmp_tbl		*$20 cmn_zmd
	dc.l	reg_adpcm_data_by_kc-sc_jmp_tbl	*$24 cmn_zmd
	dc.l	execute-sc_jmp_tbl		*$28 特例(ZPCNV3.R専用ZMSコマンド)
sc_jmp_tbl_end:					*特例ケースはラベル「tokurei:」を併せて変更

reglist	reg	d1-d2/a3
get_com_no:			*コマンド文字列->数値変換
	* < a1=com_tbl
	* < a4=pointer
	* < d4.l=area border addr.
	* > d0=#cmd number
	* minus error
	* X a1
	movem.l	reglist,-(sp)
	bsr	skip_spc2
	moveq.l	#0,d2
wc_lp01:
	tst.b	(a1)
	bmi	exit_err_wc
	bsr	do_get_cmd_num
	beq	exit_wc
@@:
	tst.b	(a1)+		*次のコマンド名へ
	bne	@b
	addq.b	#1,d2		*cmd number
	bra	wc_lp01
exit_err_wc:
	moveq.l	#-1,d0		*couldn't find it...
	movem.l	(sp)+,reglist
	rts
exit_wc:
	move.l	d2,d0		*d0=cmd number
	movem.l	(sp)+,reglist
	rts

do_get_cmd_num:			*実際に文字列を捜す
	* < a1=source str addr
	* > eq=get it!
	* > mi=can't found
	move.l	a1,-(sp)
	move.l	a4,d1		*save a4 to d1
@@:
	cmp.l	a4,d4
	bls	not_same_dgscn	*途中で終わった
	move.b	(a4)+,d0
	jsr	mk_capital-work(a6)	*小文字→大文字
	cmp.b	(a1)+,d0
	bne	not_same_dgscn
	tst.b	(a1)		*終了
	bne	@b
	move.l	(sp)+,a1
	moveq.l	#0,d0		*right!
	rts
not_same_dgscn:
	move.l	d1,a4		*get back a4
	move.l	(sp)+,a1
	moveq.l	#-1,d0		*error!
	rts

execute:				*「外部コマンド実行」コンパイル
	moveq.l	#CMN_EXECUTE,d0
	bsr	do_wrt_cmn_b
	moveq.l	#0,d3
	bsr	skip_eq
	cmpi.b	#'{',(a4)
	bne	@f
	addq.w	#1,a4
	moveq.l	#-1,d3
@@:
	move.l	a0,a2			*チェックで使用
	bsr	skip_spc2
exefnstr_lp:				*filename,option転送
	move.b	(a4),d0
	bsr	chk_kanji		*漢字かどうかチェック
	bmi	@f
	cmpi.b	#$0d,d0
	beq	set_exfnedcd
	cmpi.b	#$0a,d0
	beq	set_exfnedcd
	bsr	do_wrt_cmn_b
	addq.w	#1,a4
	cmp.l	a4,d4
	bhi	exefnstr_lp
	bra	m_illegal_command_line
@@:					*漢字ケース
	bsr	do_wrt_cmn_b
	addq.w	#1,a4
	cmp.l	a4,d4
	bls	m_string_break_off
	move.b	(a4)+,d0
	bsr	do_wrt_cmn_b
	cmp.l	a4,d4
	bhi	exefnstr_lp
	bra	m_illegal_command_line
set_exfnedcd:
	cmp.l	a2,a0
	beq	m_illegal_command_line
	moveq.l	#0,d0
	bsr	do_wrt_cmn_b
	tst.b	d3
	bne	find_end
	bra	cmpl_lp

	.include	pcmproc.s
	.include	include.s

do_wrt_cmn_b:			*共通コマンドエリアにbyte書き込み(共通コマンド時)
	* < d0.b=data
	move.b	d0,(a0)+
	bra	chk_membdr_cmn

do_wrt_cmn_w:			*共通コマンドエリアにword書き込み(共通コマンド時)
	* < d0.w=data
	rol.w	#8,d0
	move.b	d0,(a0)+
	bsr	chk_membdr_cmn
	rol.w	#8,d0
	move.b	d0,(a0)+
	bra	chk_membdr_cmn

do_wrt_cmn_l:			*共通コマンドエリアにlong word書き込み(共通コマンド時)
	* < d0.l=data
	rol.l	#8,d0
	move.b	d0,(a0)+
	bsr	chk_membdr_cmn

	rol.l	#8,d0
	move.b	d0,(a0)+
	bsr	chk_membdr_cmn

	rol.l	#8,d0
	move.b	d0,(a0)+
	bsr	chk_membdr_cmn

	rol.l	#8,d0
	move.b	d0,(a0)+

chk_membdr_cmn:			*メモリ境界チェック(共通コマンド時)
	* < a0.l
	* - all
	* x d0
	cmp.l	zmd_end(pc),a0
	bcs	exit_cmz	*no error
	movem.l	d2-d3/a1,-(sp)
	move.l	zmd_addr(pc),a1
	suba.l	a1,a0
	move.l	a0,d3
	move.l	zmd_size(pc),d2
	add.l	#$1_0000,d2
	bsr	enlarge_mem
	tst.l	d0
	bmi	m_out_of_memory
	move.l	d2,zmd_size-work(a6)
	move.l	a0,zmd_addr-work(a6)
	add.l	a0,d2
	move.l	d2,zmd_end-work(a6)
	add.l	d3,a0
	movem.l	(sp)+,d2-d3/a1
exit_cmz:
	rts

compile_end:			*テーブルの整理
	tst.l	include_depth-work(a6)		*includeしたファイルが
	bne	pop_include_ope			*コンパイル終了したに過ぎない

	tst.l	n_of_err-work(a6)
	bne	error_occurred

	moveq.l	#0,d0
	bsr	do_wrt_cmn_l		*endcode
	bsr	do_wrt_cmn_l		*endcode
	moveq.l	#-1,d0
	bsr	do_wrt_cmn_b		*endcode

	bsr	OK

	move.l	sp,sp_buf-work(a6)	*スタック保存
	move.l	zmd_addr(pc),a2
	* < a2=comn data addr
	* X d0-d2,a0-a2/a5
pcd_lp01:
	bsr	get_cm_l		*エラー時に対策
	move.l	d0,line_number-work(a6)
	bsr	get_cm_l
	move.l	d0,line_ptr-work(a6)
	move.l	d0,line_locate-work(a6)
	clr.b	OVW_flag-work(a6)
	move.b	(a2)+,d0
	bmi	assemble_zpd		*共通コマンドエンド
	cmp.b	#CMN_REGISTER_PCM,d0
	beq	cmn_register_pcm	*adpcm data cnf
	cmp.b	#CMN_ERASE_PCM,d0
	beq	cmn_erase_pcm		*erase adpcm
	cmp.b	#CMN_EXECUTE,d0
	beq	cmn_execute		*execute external command
	bra	t_undefined_zmd_code

cmn_register_pcm:
	bsr	get_cm_l
	move.l	d0,d1		*flag of option existance/reg note number
	bsr	disp_kctmb
	bsr	get_cm_l
	move.l	d0,d2		*d2.l=data type.b/original key code
	tst.l	d1
	bpl	@f
	lea	proc(pc),a1		*'PROCESSING'
	bsr	prta1
@@:
	movea.l	a2,a1
	bsr	pcm_read
	move.l	a0,a2		*a2=更新された
	lea	ovw_reg_mes(pc),a1
	tst.b	OVW_flag-work(a6)	*上書きがあったか無かったか
	bne	@f
	lea	reg_mes(pc),a1
@@:
	bsr	prta1		*bank
	bra	pcd_lp01

cmn_erase_pcm:
	bsr	get_cm_w
	move.w	d0,d1		*d1.w=note number to erase
	bsr	disp_kctmb
	suba.l	a1,a1		*a1.l=0:erase_mode
	bsr	pcm_read
	lea	ers_mes(pc),a1	*erased
	bsr	prta1
	bra	pcd_lp01

cmn_execute:				*「外部コマンド実行」実行
	lea	executing(pc),a1
	bsr	prta1

	move.l	a2,a1
	bsr	prta1

	bsr	RET

	move.l	#2048,d2
	bsr	get_temp_buf		*d2サイズ分確保(>a1.l=data area)
	bmi	t_out_of_memory
	move.l	a1,a3
@@:					*コマンドラインのコピー
	move.b	(a2)+,(a3)+
	bne	@b
	movem.l	d0-d7/a0-a7,prsv_work-work(a6)
	clr.l	-(sp)
	pea	1024(a1)		*使い捨てとなるわけだからどこでもいい
	pea	(a1)			*command line
	move.w	#2,-(sp)		*mode
	DOS	_EXEC
	addq.w	#2,sp
	clr.w	-(sp)			*mode
	DOS	_EXEC
	lea	14(sp),sp
	movem.l	prsv_work(pc),d0-d7/a0-a7
	bsr	free_mem
	bra	pcd_lp01

disp_kctmb:			*ノート番号/音色番号表示
	* < d0.w=note/timbre number
reglist	reg	d0/d2/a1
	movem.l	reglist,-(sp)
	lea	tone_mes(pc),a1
	tst.w	d0
	bpl	@f
	lea	timbre_mes(pc),a1
	andi.l	#$7fff,d0
	move.l	d0,d2
	andi.l	#$7f,d2
	lsr.l	#7,d0
	bsr	num_to_str
	bsr	prta1		*TIMBRE
	move.w	#' ',-(sp)
	DOS	_PUTCHAR
	addq.w	#2,sp
	lea	suji(pc),a1
	bsr	prta1		*bank
	move.w	#':',-(sp)
	DOS	_PUTCHAR
	addq.w	#2,sp
	move.l	d2,d0
	addq.l	#1,d0		*inc
	bsr	num_to_str
	lea	suji(pc),a1
	bsr	prta1		*timbre number
	bra	1f
@@:
	andi.l	#$7fff,d0
	move.l	d0,d2
	andi.l	#$7f,d2
	lsr.l	#7,d0
	addq.l	#1,d0		*inc
	bsr	num_to_str
	bsr	prta1		*NOTE
	move.w	#' ',-(sp)
	DOS	_PUTCHAR
	addq.w	#2,sp
	lea	suji(pc),a1
	bsr	prta1		*bank
	move.w	#':',-(sp)
	DOS	_PUTCHAR
	addq.w	#2,sp
	divu	#12,d2
	move.w	d2,d0
	lsl.w	#2,d0
	pea	octntbl(pc,d0.w)
	swap	d2
	move.w	d2,d0		*0-11
	lsl.w	#2,d0
	lea	kc0_11(pc,d0.w),a1
	bsr	prta1		*KC
	move.l	(sp)+,a1
	bsr	prta1		*ocatve
1:
	bsr	PTT		*...
	movem.l	(sp)+,reglist
	rts

kc0_11:
	dc.b	'C ',0,0
	dc.b	'C#',0,0
	dc.b	'D ',0,0
	dc.b	'D#',0,0
	dc.b	'E ',0,0
	dc.b	'F ',0,0
	dc.b	'F#',0,0
	dc.b	'G ',0,0
	dc.b	'G#',0,0
	dc.b	'A ',0,0
	dc.b	'A#',0,0
	dc.b	'B ',0,0

octntbl:
	dc.b	'-1',0,0
	dc.b	'0 ',0,0
	dc.b	'1 ',0,0
	dc.b	'2 ',0,0
	dc.b	'3 ',0,0
	dc.b	'4 ',0,0
	dc.b	'5 ',0,0
	dc.b	'6 ',0,0
	dc.b	'7 ',0,0
	dc.b	'8 ',0,0
	dc.b	'9 ',0,0

get_cm_w:
	move.b	(a2)+,d0
	lsl.w	#8,d0
	move.b	(a2)+,d0
	rts

get_cm_l:
	move.b	(a2)+,d0
	lsl.w	#8,d0
	move.b	(a2)+,d0
	swap	d0
	move.b	(a2)+,d0
	lsl.w	#8,d0
	move.b	(a2)+,d0
	rts

	.include	pcm_read.s

t_dat_ok:
	moveq.l	#0,d0
clr_adpb?:
	rts

assemble_zpd:
	tst.l	n_of_err-work(a6)
	bne	error_occurred2

	lea	saving(pc),a1		*'CREATING'
	bsr	prta1
	lea	d_name(pc),a1		*書きだしファイル名表示
	bsr	prta1
	bsr	PTT			*...

	move.w	sfh(pc),d5		*file handle

	moveq.l	#16,d4			*offset=8
	move.l	d4,-(sp)		*ヘッダ書き込み
	pea	zpdhdr(pc)
	move.w	d5,-(sp)
	DOS	_WRITE
	lea	10(sp),sp
	cmp.l	#16,d0
	bne	write_error

	moveq.l	#0,d6			*total count
	move.w	adpcm_n_max(pc),d2
	beq	@f
	subq.w	#1,d2			*for dbra
	moveq.l	#0,d1
	move.l	adpcm_tbl(pc),a0
	bsr	do_asm_zpd_tbl
@@:
	move.w	adpcm_n_max2(pc),d2
	beq	@f
	subq.w	#1,d2			*for dbra
	move.w	#$8000,d1
	move.l	adpcm_tbl2(pc),a0
	bsr	do_asm_zpd_tbl
@@:
	clr.w	-(sp)			*write total count
	move.l	#12,-(sp)
	move.w	d5,-(sp)
	DOS	_SEEK
	addq.w	#8,sp

	rept	4
	rol.l	#8,d6
	move.w	d5,-(sp)		*total count
	move.w	d6,-(sp)
	DOS	_FPUTC
	addq.w	#4,sp
	endm

*	moveq.l	#16,d1			*offset

	move.w	adpcm_n_max(pc),d2
	beq	@f
	subq.w	#1,d2			*for dbra
	move.l	adpcm_tbl(pc),a0
	bsr	do_asm_pcm_data
@@:
	move.w	adpcm_n_max2(pc),d2
	beq	@f
	subq.w	#1,d2			*for dbra
	move.l	adpcm_tbl2(pc),a0
	bsr	do_asm_pcm_data
@@:
	move.l	date_buf(pc),-(sp)
	move.w	d5,-(sp)
	DOS	_FILEDATE
	addq.w	#6,sp

	DOS	_ALLCLOSE

	bsr	OK

	lea	no_er_mes(pc),a1
	bsr	prta1

	pea	0.w
	DOS	_MFREE
	addq.w	#4,sp

	DOS	_EXIT

do_asm_zpd_tbl:				*テーブルの集配
	* < d1.w=$0000:tone/$8000:timbre
	* < d2.w=adpcm_n_maxX
	* < a0.l=adpcm_tableX
	* < d4.l=offset
	* < d5.w=file handle
	* < d6.l=total count of data
	* x d0,d2,d3,d4,a1,a2,a3
	move.l	a0,a3
	move.l	d2,d3
asmzpdlp:
	tst.b	(a0)
	beq	asmzpd_next
	lea.l	adt_name(a0),a2		*名前バッファを使わせてもらう
	addq.l	#1,d6			*inc total count
	move.l	d4,d0
	add.l	#adt_addr+2,d0
	move.l	adt_size(a0),-(sp)
	move.l	adt_addr(a0),-(sp)
	move.l	d0,-(sp)
	add.l	#adt_name+2,d4
	bcs	mem_error

	rept	2
	rol.w	#8,d1
	move.w	d5,-(sp)		*note/timbre number
	move.w	d1,-(sp)
	DOS	_FPUTC
	addq.w	#4,sp
	endm

	move.l	#adt_name,-(sp)		*テーブル書き込み(without name)
	pea	(a0)
	move.w	d5,-(sp)
	DOS	_WRITE
	lea	10(sp),sp
	cmp.l	#32,d0
	bne	write_error
asmzpdname:
	tst.b	adt_name(a0)
	beq	@f
	move.w	d5,-(sp)		*name出力
	pea	adt_name(a0)
	DOS	_FPUTS
	addq.w	#6,sp
@@:
	move.w	d5,-(sp)		*endcode
	clr.w	-(sp)
	DOS	_FPUTC
	addq.w	#4,sp
	lea	adt_name(a0),a1
@@:
	addq.l	#1,d4
	bcs	mem_error
	tst.b	(a1)+
	bne	@b

	btst.l	#0,d4			*偶数に揃える
	beq	memo_rwofst
	addq.l	#1,d4
	bcs	mem_error
	move.w	d5,-(sp)		*endcode
	clr.w	-(sp)
	DOS	_FPUTC
	addq.w	#4,sp
memo_rwofst:
	move.l	(sp)+,(a2)+		*書き換えるべきファイルオフセットをメモ
	btst.b	#0,adt_attribute(a0)	*ポインタコピーの場合はデータそのものの出力は無し
	bne	@f
	move.l	(sp)+,(a2)+		*アドレス
	move.l	(sp)+,(a2)+		*サイズ
	bra	asmzpd_next
@@:
	move.l	(sp)+,d0		*アドレス
	bsr	scan_src_ptr		*> a1.l=該当テーブル
	sub.l	adt_addr(a1),d0
	move.l	d0,(a2)+		*ポイントオフセットアドレス
	move.l	(sp)+,(a2)+		*サイズ
	move.l	a1,(a2)+		*該当テーブルを保存
asmzpd_next:
	addq.w	#1,d1
	lea	adpcm_tbl_size(a0),a0
	dbra	d2,asmzpdlp
	rts

scan_src_ptr:
	* < d0.l=検索キー(アドレス)
	* > a1.l=該当アドレス
reglist	reg	d0-d1/d3/a3
	movem.l	reglist,-(sp)
	suba.l	a1,a1			*a1=0(dummy)
	move.w	adpcm_n_max(pc),d3
	beq	@f
	subq.w	#1,d3			*for dbra
	move.l	adpcm_tbl(pc),a3
	bsr	do_scan_src_ptr
@@:
	move.l	a1,d1
	suba.l	a1,a1			*a1=0(dummy)
	move.w	adpcm_n_max2(pc),d3
	beq	@f
	subq.w	#1,d3			*for dbra
	move.l	adpcm_tbl2(pc),a3
	bsr	do_scan_src_ptr
@@:
	cmp.l	a1,d1
	bls	@f
	move.l	d1,a1			*後半の検索結果を該当データとする
@@:
	move.l	a1,d0			*ただし0(dummy)のままではエラー
	beq	pointer_error
	movem.l	(sp)+,reglist
	rts

do_scan_src_ptr:
ssplp:
	tst.b	(a3)
	beq	@f
	tst.b	adt_attribute(a3)	*ポインタコピーによる登録なので検索対象外
	bne	@f
	cmp.l	a3,a0
	beq	@f
	cmp.l	adt_addr(a3),d0
	bcs	@f
	move.l	a3,a1
@@:
	lea	adpcm_tbl_size(a3),a3
	dbra	d3,ssplp
1:
	rts

do_asm_pcm_data:			*PCM DATAのアセンブル
	* < d2.w=adpcm_n_maxX
	* < a0.l=adpcm_tableX
	* < d4.l=offset
	* < d5.w=file handle
	* x d0,d2,d3,d4,a1,a2
dapdlp:
	tst.b	(a0)
	beq	dapd_next
	lea	adt_name(a0),a2
	move.l	(a2)+,d1		*rewrite offset
	clr.w	-(sp)
	move.l	d1,-(sp)
	move.w	d5,-(sp)
	DOS	_SEEK
	addq.w	#8,sp

	btst.b	#0,adt_attribute(a0)
	beq	1f
					*ポインタコピーの場合
	move.l	(a2)+,d3		*ポイントオフセットアドレス
	addq.w	#4,a2
	move.l	(a2)+,a1		*該当テーブル
	add.l	adt_addr(a1),d3
	addq.l	#4,d1
	sub.l	d1,d3
	rept	4
	rol.l	#8,d3
	move.w	d5,-(sp)		*offset to pcm data
	move.w	d3,-(sp)
	DOS	_FPUTC
	addq.w	#4,sp
	endm
	bra	dapd_next
1:
	addq.l	#4,d1
	move.l	d4,d3
	addq.l	#1,d3
	bclr.l	#0,d3			*.even
	sub.l	d1,d3
	rept	4
	rol.l	#8,d3
	move.w	d5,-(sp)		*offset to pcm data
	move.w	d3,-(sp)
	DOS	_FPUTC
	addq.w	#4,sp
	endm

	clr.w	-(sp)
	move.l	d4,-(sp)
	move.w	d5,-(sp)
	DOS	_SEEK
	addq.w	#8,sp

	btst.l	#0,d4			*.even
	beq	@f
	addq.l	#1,d4
	move.w	d5,-(sp)
	clr.w	-(sp)			*dummy
	DOS	_FPUTC
	addq.w	#4,sp
@@:
	move.l	d4,adt_addr(a0)		*ポインタ登録方式のためにデータ部分のオフセット保存
	move.l	(a2)+,d1		*addr
	move.l	(a2)+,d3		*size
	move.l	d3,-(sp)
	move.l	d1,-(sp)
	move.w	d5,-(sp)
	DOS	_WRITE			*データ部分の書きだし
	lea	10(sp),sp
	cmp.l	d0,d3
	bne	dev_full		*全部書き出せなかったということはデバイスフル

	add.l	d3,d4
	bcs	mem_error
dapd_next:
	lea	adpcm_tbl_size(a0),a0
	dbra	d2,dapdlp
	rts

error_occurred:				*エラー表示
	bsr	RET			*とりあえず改行
	move.l	err_stock_addr(pc),a0
	moveq.l	#0,d1
	move.b	errmes_lang-work(a6),d1
	move.l	n_of_err(pc),d2
	lea	s_name(pc),a3
	move.l	zms_addr(pc),a2
	suba.l	a1,a1
	bsr	do_prt_err_mes
	move.l	a0,a1
	bsr	free_mem
	bra	go_bye			*エラー終了

error_occurred2:			*エラー表示
	bsr	RET			*とりあえず改行
	move.l	err_stock_addr(pc),a0
	moveq.l	#0,d1
	move.b	errmes_lang-work(a6),d1
	move.l	n_of_err(pc),d2
	suba.l	a3,a3			*src name=0
	move.l	a3,a2			*src addr=0
	lea	d_name(pc),a1
	bsr	do_prt_err_mes
	move.l	a0,a1
	bsr	free_mem
	bra	go_bye			*エラー終了

PUTCHAR	macro
	DOS	_PUTCHAR
	endm

PRINT	macro
	DOS	_PRINT
	endm

	.include	prterrms.s

t_offset_too_long:	m_err	OFFSET_TOO_LONG
t_processing_size_too_large:	m_err	PROCESSING_SIZE_TOO_LARGE
t_empty_note_number:	m_err	EMPTY_NOTE_NUMBER
t_illegal_tone_number:	m_err	ILLEGAL_TONE_NUMBER
t_illegal_timbre_number:	m_err	ILLEGAL_TIMBRE_NUMBER
*t_illegal_note_no:	m_err	ILLEGAL_NOTE_NUMBER
t_illegal_parameters_combination:	m_err	ILLEGAL_PARAMETERS_COMBINATION

t_undefined_zmd_code:	err	UNDEFINED_ZMD_CODE
t_out_of_memory:	err	OUT_OF_MEMORY
t_file_not_found:			*ファイルネームをサブ情報としてもつ
	move.l	#FILE_NOT_FOUND,d0
	bra	@f

t_illegal_file_size:			*ファイルネームをサブ情報としてもつ
	move.l	#ILLEGAL_FILE_SIZE,d0
	bra	@f

t_read_error:				*ファイルネームをサブ情報としてもつ
	move.l	#READ_ERROR,d0
@@:
	move.l	d0,-(sp)
	bsr	set_err_code
	move.l	fopen_name(pc),d0
	bsr	set_err_code		*set error code(fopenで最後に取り扱ったfilename)
	moveq.l	#0,d0
	bsr	set_err_code		*set error code(dummy)
	bsr	set_err_code		*set error code(dummy)
	bra	inc_n_of_err

m_file_not_found:			m_err	FILE_NOT_FOUND
m_too_many_include_files:		m_err	TOO_MANY_INCLUDE_FILES
m_recusive_include_error:		m_err	RECUSIVE_INCLUDE_ERROR
m_missing_filename:			m_err	MISSING_FILENAME
m_syntax_error:				m_err	SYNTAX_ERROR
m_kanji_break_off:			m_err	KANJI_BREAK_OFF
m_illegal_command_line:			m_err	ILLEGAL_COMMAND_LINE
m_illegal_parameter_format:		m_err	ILLEGAL_PARAMETER_FORMAT
m_command_line_break_off:		m_err	COMMAND_LINE_BREAK_OFF
m_illegal_tone_number:			m_err	ILLEGAL_TONE_NUMBER
m_parameter_cannot_be_omitted:		m_err	PARAMETER_CANNOT_BE_OMITTED
m_illegal_bank_number:			m_err	ILLEGAL_BANK_NUMBER
m_illegal_operand:			m_err	ILLEGAL_OPERAND
m_parameter_shortage:			m_err	PARAMETER_SHORTAGE
m_string_break_off:			m_err	STRING_BREAK_OFF
m_illegal_nesting_error:		m_err	ILLEGAL_NESTING_ERROR
m_undefined_ppc:			m_err	UNDEFINED_PPC
m_illegal_pitch_value:			m_err	ILLEGAL_PITCH_VALUE
m_illegal_parameters_combination:	m_err	ILLEGAL_PARAMETERS_COMBINATION
m_missing_operand:			m_err	MISSING_OPERAND
m_illegal_frequency_value:		m_err	ILLEGAL_FREQUENCY_VALUE
m_illegal_volume_value:			m_err	ILLEGAL_VOLUME_VALUE
m_undefined_loop_type:			m_err	UNDEFINED_LOOP_TYPE
m_illegal_timbre_number:		m_err	ILLEGAL_TONE_NUMBER
m_illegal_note_number:			m_err	ILLEGAL_NOTE_NUMBER
m_illegal_octave:			m_err	ILLEGAL_OCTAVE
m_unexpected_operand:			m_err	UNEXPECTED_OPERAND
m_illegal_filename:			m_err	ILLEGAL_FILENAME
m_cut_off_level_too_big:		m_err	CUT_OFF_LEVEL_TOO_BIG
m_illegal_repeat_time:			m_err	ILLEGAL_REPEAT_TIME

m_out_of_memory:					*コンパイル時
	move.l	sp_buf(pc),sp
	move.l	#ZM_ZPCNV*65536+OUT_OF_MEMORY,d0
	bsr	set_err_code_for_compile		*メモリ不足の場合は即座に
	addq.l	#1,n_of_err-work(a6)			*inc error count
	bra	compile_end				*コンパイル処理を打ち切る

m_error_code_exit:		*その値がエラーコード
	bsr	set_err_code_for_compile
	addq.l	#1,n_of_err-work(a6)	*inc error count
	move.l	sp_buf(pc),sp	*スタック補正
				*エラーの発生した行を飛ばして
	cmp.l	a4,d4		*次の行のコンパイルに望む
	bls	compile_end	*終了
doscanedcdlp:
	bsr	skip_spc
	cmp.l	a4,d4		*次の行のコンパイルに望む
	bls	compile_end	*終了
	move.b	(a4)+,d0
	bsr	chk_kanji
	bpl	@f
	addq.w	#1,a4
	bra	doscanedcdlp
@@:
	cmpi.b	#'/',d0
	bne	@f
	bsr	do_skip_comment
	bra	doscanedcdlp
@@:
	cmp.b	#$0a,d0
	beq	1f
	cmpi.b	#$1a,d0
	bne	doscanedcdlp
1:
	subq.w	#1,a4
	bra	cmpl_lp

t_error_code_exit:			*d0.lがそのままエラーコード
	* < d0.l=error code
	move.l	d0,-(sp)
	bsr	set_err_code		*set error code
	moveq.l	#0,d0
	bsr	set_err_code		*set error code(dummy)
	bsr	set_err_code		*set error code(dummy)
	bsr	set_err_code		*set error code(dummy)
inc_n_of_err:
	addq.l	#1,n_of_err-work(a6)
	bsr	do_fclose		*openしているファイルがあればそれを閉じる
	suba.l	a0,a0			*error mark
	move.l	(sp)+,d0
	bset.l	#31,d0			*error mark
	move.l	sp_buf-work(a6),sp
	bra	error_occurred2		*処理中断して終了処理へ

set_err_code_for_compile:
	bsr	set_err_code
	move.l	include_depth(pc),d0
	beq	@f
	move.l	zms_file_id(pc),d0		*filename[n]
@@:
	bsr	set_err_code
	move.l	line_number(pc),d0		*追加エラー情報
	bsr	set_err_code
	move.l	line_ptr(pc),d0
	sub.l	line_locate(pc),d0

set_err_code:					*エラーコードのストック
	* < d0.l=error code
	* - all
reglist	reg	d0-d5/a0-a1
	movem.l	reglist,-(sp)
	move.l	d0,d4			*main info
	move.l	err_stock_now(pc),d1
	move.l	err_stock_addr(pc),d0
	bne	case_erstk_enlg
	move.l	#256,d2			*初期値は256バイト
	bsr	get_mem
	tst.l	d0
	bmi	exit_sec
	move.l	d2,err_stock_size-work(a6)
	move.l	a0,err_stock_addr-work(a6)
store_ercd:
	move.l	d0,a0
	add.l	d1,a0
store_ercd_:
	move.l	d4,(a0)+		*エラー情報格納
	sub.l	err_stock_addr(pc),a0
	move.l	a0,err_stock_now-work(a6)
exit_sec:
	movem.l	(sp)+,reglist
do_exit_sec:
	rts
case_erstk_enlg:			*メモリ領域拡大の場合
	cmp.l	err_stock_size(pc),d1	*d1.l=現在の書き込み目的オフセット
	bcs	store_ercd
	move.l	d0,a1
	move.l	err_stock_size(pc),d2
	add.l	#256,d2			*もう256バイト確保
	move.l	d2,err_stock_size-work(a6)
	bsr	enlarge_mem
	tst.l	d0
	bmi	exit_sec		*out_of_memoryケース
	move.l	a0,err_stock_addr-work(a6)
	add.l	d1,a0
	bra	store_ercd_

.include	fopen.s

read:				*CNFファイルの読み込み
	* < d5.l=file handle
	* > a5=data address
	* > d3.l=size
	* X d0
	move.w	#2,-(sp)	*ファィルの長さを調べる
	clr.l	-(sp)
	move.w	d5,-(sp)
	DOS	_SEEK
 	addq.w	#8,sp		*d0.l=file length
	move.l	d0,d3		*d3=length
	ble	file_len_error

	move.l	d0,-(sp)
	DOS	_MALLOC
	addq.w	#4,sp
	tst.l	d0
	bmi	mem_error	*OUT OF MEMORY
	move.l	d0,a5

	clr.w	-(sp)		*ファイルポインタを元に戻す
	clr.l	-(sp)
	move.w	d5,-(sp)
	DOS	_SEEK
	addq.w	#8,sp

	move.l	d3,-(sp)	*push size
	pea	(a5)		*push addr
	move.w	d5,-(sp)	*file handle
	DOS	_READ
	lea	10(sp),sp
	tst.l	d0
	bmi	read_error0	*読み込み失敗

	clr.l	-(sp)
	move.w	d5,-(sp)
	DOS	_FILEDATE
	addq.w	#6,sp
	move.l	d0,date_buf-work(a6)

	move.w	d5,-(sp)	*close
	DOS	_CLOSE
	addq.l	#2,sp
	rts

get_mem:
	* < d2.l=memory size
	* > d0.l=memory block address (or error code/ depends on _MALLOC)
	* > d2.l=long word border size
	* > a0.l=data address
	* - all
	addq.l	#3,d2
	andi.w	#$fffc,d2	*make it long word border
	move.l	d2,-(sp)
	DOS	_MALLOC
	addq.w	#4,sp
	tst.l	d0
	bmi	@f
	move.l	d0,a0
@@:
	rts

enlarge_mem:			*メモリブロックの拡大縮小
	* < d2.l=new memory size
	* < a1.l=now address
	* > d0.l=address (0:done it, error/ depends on _MALLOC)
	* > d2.l=long word border size
	* > a0.l=address
	* - all
	movem.l	a1-a2,-(sp)
	addq.l	#3,d2
	andi.w	#$fffc,d2	*Make it long word border
	move.l	a1,a0
	move.l	d2,-(sp)
	pea	(a1)
	DOS	_SETBLOCK
	addq.w	#8,sp
	tst.l	d0
	beq	exit_enlmm	*no error
	move.l	d2,-(sp)	*SETBLOCK出来ない時は新たにメモリ確保
	DOS	_MALLOC
	addq.w	#4,sp
	tst.l	d0
	bmi	exit_enlmm	*error
	move.l	d0,a0
	move.l	a0,a2
	pea	(a1)
	move.l	d2,d0
@@:				*旧メモリ内容を新メモリエリアへ複写
	move.l	(a1)+,(a2)+
	subq.l	#4,d0
	bhi	@b
	DOS	_MFREE		*メモリ開放
	addq.w	#4,sp
exit_enlmm:
	movem.l	(sp)+,a1-a2
	rts

free_mem:
	* < a1.l=data address
	* > d0.l=0 no error
	* - a1
	pea	(a1)
	DOS	_MFREE
	addq.w	#4,sp
	tst.l	d0
	bne	@f		*case error
	moveq.l	#0,d0
@@:
	rts

mk_capital:			*小文字→大文字(英字以外の場合はそのままthrough out)
	* < d0.b=letter chr
	cmpi.b	#'a',d0
	bcs	exit_mkcptl
	cmpi.b	#'z',d0
	bhi	exit_mkcptl
	andi.w	#$df,d0		*わざと.w
exit_mkcptl:
	rts

_skip_spc:
@@:
	tst.b	(a2)
	beq	@f
	cmpi.b	#' ',(a2)+	*最初のファイル名までスキップ
	bls	@b
	subq.w	#1,a2
@@:
	rts

skip_sep2:			*セパレータ','を1個だけスキップする
	movem.l	d0-d1,-(sp)	*(スペース/タブは複数スキップ、改行はスキップしない)
	moveq.l	#0,d1
skip_sep2_lp:
	cmp.l	a4,d4
	bls	exit_ss2l
	move.b	(a4)+,d0
	cmpi.b	#' ',d0
	beq	skip_sep2_lp
	cmpi.b	#09,d0
	beq	skip_sep2_lp
	cmpi.b	#',',d0
	bne	@f
	tas.b	d1
	beq	skip_sep2_lp
	bra	1f
@@:
*	cmpi.b	#':',d0
*	beq	exit_ss2l
*	cmpi.b	#'=',d0		*OPMD CNF FILEのケース
*	beq	exit_ss2l
1:
	subq.w	#1,a4
exit_ss2l:
	move.l	a4,line_ptr-work(a6)
	movem.l	(sp)+,d0-d1
	rts

skip_spc2:			*スペース/TABをスキップする
	move.w	d0,-(sp)	*(複数のスペース/TABをスキップ、改行はスキップしない)
sksp2_lp:
	cmp.l	a4,d4
	bls	exit_sksp2
	move.b	(a4)+,d0
	cmpi.b	#'/',d0
	bne	@f
	bsr	do_skip_comment
	bra	sksp2_lp
@@:
	cmpi.b	#' ',d0
	beq	sksp2_lp
	cmpi.b	#09,d0		*skip tab
	beq	sksp2_lp
	subq.w	#1,a4
exit_sksp2:
	move.l	a4,line_ptr-work(a6)
	move.w	(sp)+,d0
	rts

skip_plus:			*PLUSをスキップする
	move.w	d0,-(sp)
skpllp:
	cmp.l	a4,d4
	bls	exit_skpl
	move.b	(a4)+,d0
	cmpi.b	#'/',d0
	bne	@f
	bsr	do_skip_comment
	bra	skpllp
@@:
	btst.b	#0,now_cmd-work(a6)	*(tN)でのMMLコンパイル中か
	bne	@f
	cmpi.b	#$0d,d0
	beq	skpllp
	cmpi.b	#$0a,d0
	bne	@f
	bsr	cr_line
	bra	skpllp
@@:
	cmpi.b	#'+',d0
	beq	skpllp
	subq.w	#1,a4
exit_skpl:
	move.l	a4,line_ptr-work(a6)
	move.w	(sp)+,d0
	rts

skip_eq:			*'='をスキップする(スペースやタブも)
	move.w	d0,-(sp)
skip_eq_lp:
	cmp.l	a4,d4
	bls	exit_eql
	move.b	(a4)+,d0
	cmpi.b	#'/',d0
	bne	@f
	bsr	do_skip_comment
	bra	skip_eq_lp
@@:
	cmpi.b	#' ',d0
	beq	skip_eq_lp
	cmpi.b	#09,d0
	beq	skip_eq_lp
	cmpi.b	#'=',d0		*OPMD CNF FILEのケース
	beq	skip_eq_lp
	cmpi.b	#':',d0
	beq	skip_eq_lp
	btst.b	#0,now_cmd-work(a6)	*(tN)でのMMLコンパイル中か
	bne	@f
	cmpi.b	#$0d,d0
	beq	skip_eq_lp
	cmpi.b	#$0a,d0
	bne	@f
	bsr	cr_line
	bra	skip_eq_lp
@@:
	subq.w	#1,a4
exit_eql:
	move.l	a4,line_ptr-work(a6)
	move.w	(sp)+,d0
	rts

skip_sep:			*セパレータを1個だけスキップする
	move.w	d0,-(sp)	*(スペース/タブ/改行は複数スキップする)
skip_sep_lp:
	cmp.l	a4,d4
	bls	exit_ssl
	move.b	(a4)+,d0
	cmpi.b	#'/',d0
	bne	@f
	bsr	do_skip_comment
	bra	skip_sep_lp
@@:
	cmpi.b	#' ',d0
	beq	skip_sep_lp
	cmpi.b	#09,d0
	beq	skip_sep_lp
	cmpi.b	#',',d0
	beq	exit_ssl
*	cmpi.b	#':',d0
*	beq	exit_ssl
*	cmpi.b	#'=',d0		*OPMD CNF FILEのケース
*	beq	exit_ssl
	btst.b	#0,now_cmd-work(a6)	*(tN)でのMMLコンパイル中か
	bne	@f
	cmpi.b	#$0d,d0
	beq	skip_sep_lp
	cmpi.b	#$0a,d0
	bne	@f
	bsr	cr_line
	bra	skip_sep_lp
@@:
	subq.w	#1,a4
exit_ssl:
	move.l	a4,line_ptr-work(a6)
	move.w	(sp)+,d0
	rts

skip_spc:			*スペースをスキップする
	move.w	d0,-(sp)	*(複数のスペース/タブをスキップ、改行もスキップ)
sksplp:
	cmp.l	a4,d4
	bls	exit_sksp
	move.b	(a4)+,d0
	cmpi.b	#'/',d0
	bne	@f
	bsr	do_skip_comment
	bra	sksplp
@@:
	cmpi.b	#' ',d0
	beq	sksplp
	cmpi.b	#09,d0		*skip tab
	beq	sksplp
	btst.b	#0,now_cmd-work(a6)	*(tN)でのMMLコンパイル中か
	bne	@f			*ne:yes
	cmpi.b	#$0d,d0
	beq	sksplp
	cmpi.b	#$0a,d0
	bne	@f
	bsr	cr_line
	bra	sksplp
@@:
	subq.w	#1,a4
exit_sksp:
	move.l	a4,line_ptr-work(a6)
	move.w	(sp)+,d0
	rts

skip_spc0:			*スペースをスキップする(chk_num専用)
	move.w	d0,-(sp)	*(複数のスペース/タブをスキップ、改行もスキップ
sksplp0:			*ただし、テンポラリ的にスキップ)
	cmp.l	a4,d4
	bls	exit_sksp0
	move.b	(a4)+,d0
	cmpi.b	#'/',d0
	bne	@f
	bsr	do_skip_comment
	bra	sksplp0
@@:
	cmpi.b	#' ',d0
	beq	sksplp0
	cmpi.b	#09,d0			*skip tab
	beq	sksplp0
	btst.b	#0,now_cmd-work(a6)	*(tN)でのMMLコンパイル中か
	bne	@f			*ne:yes
	cmpi.b	#$0d,d0
	beq	sksplp0
	cmpi.b	#$0a,d0
	beq	sksplp0
@@:
	subq.w	#1,a4
exit_sksp0:
*	move.l	a4,line_ptr-work(a6)
	move.w	(sp)+,d0
	rts

chk_num:			*数字かどうかチェック(2進,16進数値の有無に付いても検知)
	* > eq=number
	* > mi=not num
reglist	reg	d0/a4
	movem.l	reglist,-(sp)
chknumlp:
	bsr	skip_spc0
	cmp.l	a4,d4
	bls	not_num
	move.b	(a4),d0
	cmpi.b	#'%',d0
	beq	bin_numchk
	cmpi.b	#'$',d0
	beq	hex_numchk
	cmpi.b	#'-',d0
	beq	@f
	cmpi.b	#'+',d0
	bne	chknum0
@@:				*もう一度検査へ
	addq.w	#1,a4
	bra	chknumlp
chknum0:
	cmpi.b	#'0',d0
	bcs	not_num
	cmpi.b	#'9',d0
	bhi	not_num
yes_num:
	movem.l	(sp)+,reglist
	move.w	#CCR_ZERO,ccr
	rts

bin_numchk:			*2進ケース
	addq.w	#1,a4		*skip %
	bsr	skip_spc0
	cmp.l	a4,d4
	bls	not_num
	move.b	(a4),d0
	cmpi.b	#'0',d0
	beq	yes_num
	cmpi.b	#'1',d0
	beq	yes_num
not_num:
	movem.l	(sp)+,reglist
	move.w	#CCR_NEGA,ccr
	rts

hex_numchk:			*16進ケース
	addq.w	#1,a4		*skip $
	bsr	skip_spc0
	cmp.l	a4,d4
	bls	not_num
	move.b	(a4),d0
	cmpi.b	#'0',d0
	bcs	not_num
	cmpi.b	#'9',d0
	bls	yes_num
	bsr	mk_capital
	cmpi.b	#'A',d0
	bcs	not_num
	cmpi.b	#'F',d0
	bhi	not_num
	bra	yes_num

chk_kanji:
	tst.b	d0
	bpl	@f		*normal characters
	cmpi.b	#$a0,d0		*漢字か
	bcs	cknj_yes
	cmpi.b	#$df,d0
	bls	@f
cknj_yes:
	move.w	#CCR_NEGA,ccr	*yes
	rts
@@:
	move.w	#CCR_ZERO,ccr	*no
	rts

get_num:			*数字文字列を数値へ
	* < (a4)=number strings
	* < d4=end of text addr.
	* > d1.l=value
	* > a4=next
	* - all
reglist	reg	d0/d2-d3
	bsr	skip_spc	*' ',tabなどをskip
	cmp.l	a4,d4
	beq	num_ret
	movem.l	reglist,-(sp)
	cmpi.b	#'-',(a4)
	seq	d2   		*'-'ならマーク
	bne	get_num0
	addq.w	#1,a4		*skip '-'
get_num0:
	bsr	skip_plus
	bsr	skip_spc

	cmpi.b	#'$',(a4)
	beq	get_hexnum_
	cmpi.b	#'%',(a4)
	beq	get_binnum_

	moveq.l	#0,d1
	moveq.l	#0,d0
num_lp01:
	cmp.l	a4,d4
	bls	num_exitt
	move.b	(a4)+,d0
*	cmpi.b	#'_',d0
*	beq	num_lp01
	sub.b	#$30,d0
	bmi	num_exit
	cmp.b	#9,d0
	bhi	num_exit

	add.l	d1,d1
	move.l	d1,d3
	lsl.l	#2,d1
	add.l	d3,d1		*d1=d1*10
	add.l	d0,d1		*d1=d1+d0
	bra	num_lp01
num_exit:
	subq.w	#1,a4
num_exitt:
	tst.b	d2
	beq	@f
	neg.l	d1
@@:
	movem.l	(sp)+,reglist
num_ret:
	rts
get_hexnum_:			*16進数
	moveq.l	#0,d0
	moveq.l	#0,d1
	cmp.l	a4,d4
	bls	num_exitt
	addq.w	#1,a4
	bsr	skip_spc
__num_lp01_:
	cmp.l	a4,d4
	bls	num_exitt
	move.b	(a4)+,d0
*	cmpi.b	#'_',d0
*	beq	__num_lp01_
	bsr	mk_capital
	sub.b	#$30,d0
	bmi	num_exit
	cmp.b	#9,d0
	bls	calc_hex_
	cmpi.b	#17,d0
	bcs	num_exit
	cmpi.b	#22,d0
	bhi	num_exit
	subq.b	#7,d0
calc_hex_:
	lsl.l	#4,d1
	or.b	d0,d1
	bra	__num_lp01_
get_binnum_:			*2進数
	moveq.l	#0,d0
	moveq.l	#0,d1
	cmp.l	a4,d4
	bls	num_exitt
	addq.w	#1,a4
	bsr	skip_spc
b__num_lp01_:
	cmp.l	a4,d4
	bls	num_exitt
	move.b	(a4)+,d0
*	cmpi.b	#'_',d0
*	beq	b__num_lp01_
	cmpi.b	#'0',d0
	beq	calc_b_num__
	cmpi.b	#'1',d0
	bne	num_exit
calc_b_num__:
	sub.b	#$30,d0
	add.l	d1,d1
	or.b	d0,d1
	bra	b__num_lp01_

mk_note_num:				*ノート表示
	movem.l	d0-d1/a1,-(sp)
	lea	suji(pc),a1
	move.b	#'(',(a1)+
	divu	#128,d0
	add.b	#$31,d0			*bank
	move.b	d0,(a1)+
	move.b	#':',(a1)+
	clr.w	d0
	swap	d0
	divu	#12,d0
	moveq.l	#$2f,d1
	add.b	d1,d0
	cmp.b	d1,d0
	bhi	@f
	move.b	#'-',2(a1)
	move.b	#'1',3(a1)
	move.b	#')',4(a1)
	clr.b	5(a1)
	bra	dnd0
@@:
	move.b	d0,2(a1)
	move.b	#')',3(a1)
	move.b	#' ',4(a1)
	clr.b	5(a1)
dnd0:
	swap	d0
	add.w	d0,d0
	move.b	nn(pc,d0.w),(a1)+
	move.b	nn+1(pc,d0.w),(a1)+
	movem.l	(sp)+,d0-d1/a1
	rts

nn:	dc.b	'C '
	dc.b	'C#'
	dc.b	'D '
	dc.b	'D#'
	dc.b	'E '
	dc.b	'F '
	dc.b	'F#'
	dc.b	'G '
	dc.b	'G#'
	dc.b	'A '
	dc.b	'A#'
	dc.b	'B '

chk_optsw:				*オプションスイッチ
	* < a2.l=cmd line
optsw_lp:
	move.b	(a2)+,d0
	cmpi.b	#'/',d0
	beq	@f
	cmpi.b	#'-',d0
	bne	exit_optsw
@@:
	bsr	_skip_spc
	move.b	(a2)+,d0
	beq	print_hlp
	bsr	mk_capital
	cmpi.b	#'J',d0			*日本語表示
	beq	japanese_mode
*	cmpi.b	#'H',d0
*	beq	print_hlp
*	cmpi.b	#'?',d0
*	beq	print_hlp
	bra	print_hlp
exit_optsw:
	subq.w	#1,a2
	rts
japanese_mode:				*日本語表示
	st.b	errmes_lang-work(a6)
	bra	optsw_lp

get_string:
	* < d1.w=最大文字数-1
	* > d3.l=文字数
	moveq.l	#0,d3
	bsr	skip_spc
tmtlp:
	cmp.l	a4,d4
	bls	m_string_break_off		*文字列が途中で終わっている
	move.b	(a4)+,d0
	bsr	chk_kanji		*漢字かどうかチェック
	bpl	@f
	bsr	do_wrt_cmn_b
	addq.w	#1,d3			*ins str len
	subq.w	#1,d1
	bcs	exit_gtstr
	cmp.l	a4,d4
	bls	m_string_break_off	*文字列が中途半端
	move.b	(a4)+,d0
	bra	tmtstr_next
@@:
	cmp.b	#$0a,d0
	bne	@f
	bsr	cr_line			*改行
	bra	exit_gtstr
@@:
	cmpi.b	#'=',d0
	bne	@f
	cmp.l	a4,d4			*={ は一組で考える
	bls	tmtstr_next
	cmpi.b	#'{',(a4)
	bne	tmtstr_next
	addq.w	#1,a4
	bra	exit_gtstr
@@:
	cmp.b	#'{',d0			*文字列終了
	beq	exit_gtstr
tmtstr_next:
	bsr	do_wrt_cmn_b
	addq.w	#1,d3			*ins str len
	dbra	d1,tmtlp
skip_gtstr:				*規定文字数より長い文字列はスキップ
	cmp.l	a4,d4
	bls	m_string_break_off	*文字列が途中で終わっている
	move.b	(a4)+,d0
	bsr	chk_kanji		*漢字かどうかチェック
	bpl	@f
	cmp.l	a4,d4
	bls	m_string_break_off	*文字列が中途半端
	move.b	(a4)+,d0
	bra	skip_gtstr
@@:
	cmp.b	#$0a,d0
	bne	@f
	bsr	cr_line			*改行
	bra	exit_gtstr
@@:
	cmp.b	#'{',d0			*文字列終了
	bne	skip_gtstr
exit_gtstr:
	rts

bye_bye_:			*書きだしファイル名表示
	pea	d_name(pc)
	DOS	_PRINT
	addq.w	#4,sp
	bra	@f

bye_bye:			*ソースファイル名表示
	pea	s_name(pc)
	DOS	_PRINT
	addq.w	#4,sp
@@:
	move.l	line_number(pc),d1
	beq	@f

	pea	TAB(pc)		*行番号表示
	DOS	_PRINT
	addq.w	#4,sp

	move.l	d1,d0
	bsr	num_to_str
	pea	suji(pc)
	DOS	_PRINT		*line number
	addq.w	#4,sp
@@:
	pea	TAB(pc)
	DOS	_PRINT
	addq.w	#4,sp
_bye_bye:			*エラーメッセージだけ
	bsr	bil_prta1_
go_bye:
	DOS	_ALLCLOSE

	move.w	#$07,-(sp)	*beep
	clr.w	-(sp)
	DOS	_CONCTRL
	addq.w	#4,sp

	pea	d_name(pc)	*未完成出力ファイル消去
	DOS	_DELETE
	addq.w	#4,sp

	move.w	#1,-(sp)	*エラー
	DOS	_EXIT2

ropen_error:
	lea	rop_er_mes(pc),a1
	bra	bye_bye

wopen_error:
	lea	wop_er_mes(pc),a1
	bra	bye_bye_

read_error0:
	lea	red_er_mes0(pc),a1
	bra	bye_bye

write_error:
	lea	wrt_er_mes(pc),a1
	bra	bye_bye_

dev_full:
	lea	dev_ful_mes(pc),a1
	bra	_bye_bye		*エラーメッセージだけ

mem_error:				*メモリ不足
	lea	mem_er_mes(pc),a1
	bra	bye_bye

file_len_error:
	lea	fil_er_mes(pc),a1
	bra	bye_bye

pointer_error:
	lea	ptr_er_mes(pc),a1
	bra	bye_bye

print_hlp:				*ヘルプの表示
	bsr	print_title

	lea	hlp_mes(pc),a1
	bsr	bil_prta1

	move.w	#1,-(sp)
	DOS	_EXIT2

print_title:				*タイトルの表示
	pea	(a1)
	lea	title_mes(pc),a1
	bsr	prta1
	move.l	(sp)+,a1
	rts

bil_prta1:				*日本語対応
	tst.b	errmes_lang-work(a6)	*0:英語か 1:日本語か
	beq	prta1
@@:					*次のメッセージをゲット
	tst.b	(a1)+
	bne	@b
prta1:
	move.w	#2,-(sp)
	pea	(a1)
	DOS	_FPUTS
	addq.w	#6,sp
	rts

bil_prta1_:				*日本語対応
	tst.b	errmes_lang-work(a6)	*0:英語か 1:日本語か
	beq	prta1_
@@:					*次のメッセージをゲット
	tst.b	(a1)+
	bne	@b
prta1_:
	pea	(a1)
	DOS	_PRINT
	addq.w	#4,sp
	rts

*SPC:				*print space
*	lea	spc_data(pc),a1
*	bra	prta1
*EQU:
*	lea	equ_data(pc),a1
*	bra	prta1
PTT:
	lea	ptt_data(pc),a1
	bra	prta1
OK:
	lea	ok_data(pc),a1
	bra	prta1
RET:
	lea	CRLF(pc),a1
	bra	prta1

	.data
work:
title_mes:
	dc.b	'Z-MUSIC PCM FILE CONVERTER '
	dc.b	$f3,'V',$F3,'E',$F3,'R',$F3,'S',$F3,'I',$F3,'O',$F3,'N'
	version
	test
	dc.b	' (C) 1991,98 ZENJI SOFT',13,10,0
hlp_mes:
	dc.b	'< USAGE > '
	dc.b	'ZPCNV3.R [Optional Switches] <FILENAME1[.CNF]> [FILENAME2[.ZPD]]',13,10
	dc.b	'< OPTIONAL SWITCHES >',13,10
	dc.b	'-? or H Display the list of optional switches.',13,10
	dc.b	'-J      Messages will be displayed in Japanese.',13,10
	dc.b	0
	dc.b	'< 使用方法 > '
	dc.b	'ZPCNV3.R [オプション] <ファイル名1[.CNF]> [ファイル名2[.ZPD]]',13,10
	dc.b	'< オプション >',13,10
	dc.b	'-? or H ヘルプ表示.',13,10
	dc.b	'-J      日本語メッセージ表示',13,10
	dc.b	0
rop_er_mes:
	dc.b	'File open error. Does the FILENAME1 file surely exist?',13,10,0
	dc.b	'ファイルが開けませんでした。FILENAME1が存在するか確認してください。',13,10,0
wop_er_mes:
	dc.b	'File open error. Check the legitimacy of FILENAME2.',13,10,0
	dc.b	'ファイルが開けませんでした。FILENAME2が適正なファイル名か確認してください。',13,10,0
red_er_mes0:
	dc.b	'File read error. Check the legitimacy of FILENAME1.',13,10,0
	dc.b	'読み込みエラーです。FILENAME1が正常か確認してください。',13,10,0
wrt_er_mes:
	dc.b	'File write error. Check the legitimacy of FILENAME2.',13,10,0
	dc.b	'書き込みエラーです。FILENAME2が正常か確認してください。',13,10,0
dev_ful_mes:
	dc.b	'Device full.',13,10,0
	dc.b	'ディスク容量が不足しています。',13,10,0
mem_er_mes:
	dc.b	'Out of memory.',13,10,0
	dc.b	'メモリが不足しています。',13,10,0
fil_er_mes:
	dc.b	'Illegal File size.',13,10,0
	dc.b	'ファイルサイズが異常です。',13,10,0
ptr_er_mes:
	dc.b	'Illegal pointer error.',13,10,0
	dc.b	'ポインタが異常です。',13,10,0
ers_mes:	dc.b	'ERASED',13,10,0
reg_mes:	dc.b	$1b,'[u',$1b,'[0KOK',13,10,0
ovw_reg_mes:	dc.b	$1b,'[u',$1b,'[0KOVER WRITTEN',13,10,0

compiling:	dc.b	'COMPILING ',0
proc:		dc.b	'PROCESSING',0
saving:		dc.b	'CREATING  ',0
executing:	dc.b	'EXECUTING ',0
no_er_mes:	dc.b	'Operations are all set.',13,10
		dc.b	'A ♪SOUND mind in a SOUND body.',13,10,0
spc_data:	dc.b	' ',0
ptt_data:	dc.b	' ... ',$1b,'[s',0
ok_data:	dc.b	'OK',13,10,0
CRLF:		dc.b	13,10,0
TAB:		dc.b	9,0
		dc.b	9
suji:		ds.b	16
kc_value:	*A  B  C  D  E  F  G
	dc.b	09,11,00,02,04,05,07
zpcnv3_opt:	dc.b	'zpcnv3_opt',0
errmes_lang:	dc.b	0			*日本語モード

shp_com_tbl:	*共通コマンド
	dc.b	'INCLUDE',0
	dc.b	'16BITPCM_TIMBRE',0
	dc.b	'16BITPCM_TONE',0
	dc.b	'8BITPCM_TIMBRE',0
	dc.b	'8BITPCM_TONE',0
	dc.b	'ADPCM_BANK',0
	dc.b	'ADPCM_TIMBRE',0
	dc.b	'ADPCM_TONE',0
	dc.b	'ERASE',0
	dc.b	'O',0
	dc.b	'EXECUTE',0
	dc.b	-1
	.even
exp_tbl:
	dc.l	1000000000
	dc.l	100000000
	dc.l	10000000
	dc.l	1000000
	dc.l	100000
	dc.l	10000
	dc.l	1000
	dc.l	100
	dc.l	10
	dc.l	1

scaleval:
	dc.w	 16,17,19,21,23,25,28
	dc.w	 31,34,37,41,45,50,55
	dc.w	 60,66,73,80,88,97,107
	dc.w	 118,130,143,157,173,190,209
	dc.w	 230,253,279,307,337,371,408
	dc.w	 449,494,544,598,658,724,796
	dc.w	 876,963,1060,1166,1282,1411,1552
levelchg:
	dc.w	-1,-1,-1,-1,2,4,6,8
	dc.w	-1,-1,-1,-1,2,4,6,8

zpdhdr:		dc.l	ZPDV3_0,ZPDV3_1,0,0

adpcm_bank:	dc.w	0
err_stock_addr:	ds.l	1	*エラーを溜めておくところ
err_stock_size:	ds.l	1	*
err_stock_now:	ds.l	1	*
adpcm_tbl:		ds.l	1	*ADPCM DATAのADDRESSテーブル(note)[0]	!!
adpcm_n_max:		ds.w	1	*定義できる最大数(ノート方式)[0]	!!
adpcm_tbl2:		ds.l	1	*ADPCM DATAのADDRESSテーブル2(timbre)[0]	#
adpcm_n_max2:		ds.w	1	*定義できる最大数(音色形式)[0]			#
adpcm_buffer_top:	ds.l	1	*ADPCM DATA BUFFER TOP ADDRESS
adpcm_buffer_size:	ds.l	1	*ADPCM DATA BUFFER SIZE
adpcm_buffer_end:	ds.l	1	*ADPCM DATA BUFFER END ADDRESS
line_number:	ds.l	1	*ソース行番号[0]

	.include	zmerrmes.s

	.bss
rv_p:		ds.b	1
	.even
env_bak:	ds.l	1
date_buf:	ds.l	1
fade_p:		ds.l	1
pitch_p:	ds.l	1
vol_p:		ds.l	1
mix_note:	ds.l	1	*ADPCM登録コマンドワーク
mix_delay:	ds.l	1	*ADPCM登録コマンドワーク
fade_delay:	ds.l	1	*ADPCM登録コマンドワーク
fade_size:	ds.l	1	*ADPCM登録コマンドワーク
cut_offset:	ds.l	1	*ADPCM登録コマンドワーク
cut_size:	ds.l	1	*ADPCM登録コマンドワーク
last_val:	ds.w	1	*0
sfh:		ds.w	1
filename:	ds.l	1
line_ptr:	ds.l	1	*ソース行番号[0]
line_locate:	ds.l	1	*ソース行位置[0]
n_of_err:	ds.l	1	*発生したエラーの数[0]
zms_addr:	ds.l	1	*ZMD格納アドレス
zmd_addr:	ds.l	1	*ZMD格納アドレス
zmd_size:	ds.l	1	*ZMD格納バッファサイズ
zmd_end:	ds.l	1	*ZMD格納バッファ最終アドレス
sp_buf:		ds.l	1	*コンパイル時のスタック保存ワーク
fopen_name:	ds.l	1	*fopenで取り扱った最後のファイル名
csa_regnote:	ds.l	1	*ADPCM登録コマンドワーク
csa_regtype:	ds.l	1	*ADPCM登録コマンドワーク
temp_buffer:	ds.l	1	*一時的な作業エリア(include)
open_fn:	ds.l	1
adnt_regtype:	dc.l	0		*登録タイプ(下3バイト未使用)
adnt_work:	dc.w	0		*変換処理ありかなしか	!!!ファンクション$10用ワーク
adnt_regnote:	dc.w	0		*登録先ノート番号	!!!
adnt_lp_start:	dc.l	0		*loop start offset	!!!
adnt_lp_end:	dc.l	0		*loop end offset	!!!
adnt_lp_time:	dc.l	0		*loop time		!!!
v_buffer:	ds.l	1
erfn_addr:	ds.l	1	*エラーが発生したソースのファイル名の格納領域
erfn_size:	ds.l	1
erfn_now:	ds.l	1
*erfn_recent0:	ds.l	1
*erfn_recent1:	ds.l	1
zms_file_id:	ds.l	1	*ソースファイルネームID([0],1,2,...)
include_depth:	ds.l	1	*インクルードの深さ[0]
reg_n:		ds.w	1
prsv_work:	ds.b	64	*スタック保存
	.even
s_name:		ds.b	92
d_name:		ds.b	92
suji2:		ds.b	16	*数値表示用2
now_cmd:	ds.b	1	*0:複数行に渡る  1:1行で終結
OVW_flag:	ds.b	1	*上書きされたかどうかを表すフラグ
	.even
		ds.l	1024
user_sp:
