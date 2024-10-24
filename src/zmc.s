*残されたやるべきこと
*使われていないFM音色などを吐き出す処理
*[繰り返しコマンド/gosubはﾄﾗｯｸﾊﾟﾀｰﾝﾃﾞｰﾀとしては登録できない(演奏時のZMD書き換えがあるから)]
******************************************************************************
*[リストは基本的に非常駐(使い捨て)のコンパイラの姿を呈し、常駐時に自己書き換えで変身する]
*-------------------------------------------------------
*	ZMUSIC VERSION 3.0 MML COMPILER
*-------------------------------------------------------

	.cpu		68000
	.nlist
	.include	doscall.mac
	.include	iocscall.mac
	.include	table.mac
	.include	z_global.mac
	.include	label.mac
	.include	zmd.mac
	.include	zmid.mac
	.include	zmcall.mac
	.include	error.mac
	.include	zclabel.mac
	.include	zcmacro.mac
	.list
	.text
	.lall
stack:		equ	$4000
t_trk_no_max:	equ	128		*(t1,...)で一度に書けるトラック番号の数
OCTAVE_UP:	equ	'<'
OCTAVE_DOWN:	equ	'>'
DIRECT_LEN:	equ	'*'
max_macro_param:	equ	255	*マクロに与えることのできるパラメータ数の上限値

begin_of_prog:
device_driver0:
	dc.l	-1
	dc.w	$8020			*char,ioctrl不可,raw
	dc.l	strategy_entry0
	dc.l	interrupt_entry0
dev_name0:
	dc.b	' Z-MUSIC'
pack_ptr0:
	dc.l	0
func_tbl0:
	dc.l	dev_init-func_tbl0	*0  初期化
	dc.l	not_com-func_tbl0	*1  エラー
	dc.l	not_com-func_tbl0	*2  無効
	dc.l	not_com-func_tbl0	*3  (ioctrlによる入力)
	dc.l	not_com-func_tbl0	*4  (入力)
	dc.l	ok_com-func_tbl0	*5  １バイト先読み入力
	dc.l	ok_com-func_tbl0	*6  入力ステータスチェック
	dc.l	ok_com-func_tbl0	*7  入力バッファクリア
	dc.l	dev_out-func_tbl0	*8  出力(verify off)
	dc.l	dev_out-func_tbl0	*9  出力(verify on)
	dc.l	ok_com-func_tbl0	*10 出力ステータスチェック
	dc.l	ok_com-func_tbl0	*11 無効
	dc.l	not_com-func_tbl0	*12 ioctrlによる出力

interrupt_entry0:
	movem.l	d0/a4-a5,-(sp)
	movea.l	pack_ptr0(pc),a5
	moveq.l	#0,d0			*d0.l=com code
	move.b	2(a5),d0
	add.w	d0,d0
	add.w	d0,d0
	move.l	func_tbl0(pc,d0.w),d0
	jsr	func_tbl0(pc,d0.l)	*jump tableで参照したところへ…
	move.b	d0,3(a5)		*終了ステータスをセット
	lsr.w	#8,d0
	move.b	d0,4(a5)
	movem.l	(sp)+,d0/a4-a5
	rts

strategy_entry0:
	move.l	a5,pack_ptr0
	rts

not_com:
	move.w	#$5003,d0	*無視/中止,無効
	rts
dev_out:
ok_com:
	clr.w	d0		*no error
	rts

version_id:
		dc.b	'ZCmPlR'	*ID
ver_num:	dc.b	v_code		*ZMUSIC COMPILER VERSION NUMBER
		dc.b	v_code_+ver_type

*-----------------------------------------------------------------------------
compiler:				*COMPILE
	*   cmd=$02
	* < d1.l=mode
	*	d0-d6:検出するエラーの最大/0:∞,1-127
	*	d12:V2モードか(0:no,1:yes)
	*	d15:エラーテーブルリストを作成して出力するか(0:no,1:yes)
	* < d2.l=size
	* < a1.l=source address	(a1=d2=0でコンパイラ解除)
	*-------
	* > d0.l=num. of error
	* > a0.l=error table (if required/to be free)
	*	(error code.w,error line.l)
	*-------
	* > d0.l=0:no error
	* > a0.l=object address
	*   0(a0)～7(a0)=ZMD standard header
	*   8(a0)～ZMD
	*   (ウォーニングがあればZMDデータの後ろにくっついている)
	*------- release compiler case
	* > d0.l=0:no error/nz error
	lea	work,a6
	move.l	sp,sp_buf-work(a6)		*スタック保存
	move.l	d1,compile_option-work(a6)	*save mode
	move.l	d2,d4
	add.l	a1,d4				*d4=end addr
	beq	release_compiler
	move.l	a1,a4				*a4=source addr

	move.l	#1,line_number-work(a6)
	move.l	a4,line_ptr-work(a6)
	move.l	a4,line_locate-work(a6)
	moveq.l	#0,d0				*グローバルワーク初期化
	move.l	d0,n_of_err-work(a6)
	move.l	d0,n_of_warn-work(a6)
	move.l	d0,ti_link_offset-work(a6)
	move.l	d0,compile_phase-work(a6)	*compile_phase,compile_status,n_of_track
	move.l	d0,err_stock_addr-work(a6)
	move.l	d0,err_stock_size-work(a6)
	move.l	d0,ptn_addr-work(a6)
	move.l	d0,macro_addr-work(a6)
	move.l	d0,mcrnm_hash_tbl-work(a6)
	move.l	d0,chgsrc_addr-work(a6)
	move.l	d0,now_cmd-work(a6)		*now_cmd,ptn_cmd,adpcm_bank
	move.l	d0,zms_file_id-work(a6)
	move.l	d0,include_depth-work(a6)
	move.l	d0,pmr_addr-work(a6)
	move.w	d0,list_mode-work(a6)		*list_mode,fxgt_mode,v2_compatch,dummy
	btst.l	#12,d1
	beq	@f
	move.b	#1,v2_compatch-work(a6)
@@:
	move.l	#$0000_01_00,step_input-work(a6)	*step_input,assign_done
							*jump_cmd_ctrl,velo_vol_ctrl
	move.l	#$1016_1016,dev_mdl_ID-work(a6)		*デバイスID,モデルID初期値初期化
	move.w	#$1016,dev_mdl_ID+4-work(a6)
	move.l	#$01_00_08_03,auto_comment-work(a6)	*auto_comment,seq_cmd,gate_range,gate_shift
	move.b	#ZM_COMPILER,zmc_call-work(a6)
	move.l	t_trk_no-work(a6),a0
	move.w	#-1,(a0)

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

	move.l	#2048,d2			*制御コマンド格納バッファ確保(m_play他)
	move.l	#ID_TEMP,d3
	jsr	get_mem-work(a6)
	tst.l	d0
	bmi	m_out_of_memory
	move.l	a0,ctrl_addr-work(a6)
	move.l	d2,ctrl_size-work(a6)
	add.l	a0,d2
	move.l	d2,ctrl_end-work(a6)
	clr.l	ctrl_now-work(a6)

	move.l	#ta_size*100,d2			*トラック番号再割り振り用ワークエリア
	move.l	#ID_TEMP,d3
	jsr	get_mem-work(a6)
	tst.l	d0
	bmi	m_out_of_memory			*type(.l),offset(.l)
	move.l	a0,trkn_addr-work(a6)		*source trk n(.l),destination trk n(.l)
	move.l	d2,trkn_size-work(a6)
	add.l	a0,d2
	move.l	d2,trkn_end-work(a6)
	clr.l	trkn_now-work(a6)

	move.w	#16,trk_n_max-work(a6)		*トラック管理テーブル
	move.l	#tpt_tsize*16,d2		*構造はzclabel.macを参照のこと
	move.l	#ID_TEMP,d3			*ID
	jsr	get_mem-work(a6)
	tst.l	d0
	bmi	m_out_of_memory
	move.l	a0,trk_ptr_tbl-work(a6)		*enlarge or get?

	move.l	#2048,d2			*トラック情報テーブル用ワークバッファ
	move.l	#ID_TEMP,d3			*ワーク構成(リスト構造)
	jsr	get_mem-work(a6)		*[tr.no]w,[next_tit_offset/0=this is last]l,
	tst.l	d0				*[p_track_stat]b,[p_track_mode]b,
	bmi	m_out_of_memory			*[p_trkfrq]b,[p_trkfrqwk]b,
	move.l	a0,trk_inf_tbl-work(a6)		*[p_type]w,[p_ch]w,
	move.l	d2,tit_size-work(a6)		*[comment length]l
	moveq.l	#0,d0				*[comment.....],0.b
	move.l	d0,tit_now-work(a6)		*[tr.no+1]w.......and so on
	move.w	d0,(a0)				*初期化

	move.l	#$1_0000,d2			*デフォルトバッファサイズ=64kb
	move.l	#ID_ZMD,d3			*ここが出力される
	jsr	get_mem-work(a6)
	tst.l	d0
	bmi	m_out_of_memory
	move.l	a0,zmd_addr-work(a6)		*保存
	move.l	d2,zmd_size-work(a6)		*保存
	add.l	a0,d2
	move.l	d2,zmd_end-work(a6)
	clr.l	zmd_now-work(a6)

	move.l	#ZmuSiC0,d0			*header
	bsr	do_wrt_cmn_l
	move.l	#ZmuSiC1+v_code,d0
	bsr	do_wrt_cmn_l

	moveq.l	#(z_header_size-z_comn_offset)/4-1,d2
	moveq.l	#0,d0
@@:						*インフォメーションエリアの初期化#1
	bsr	do_wrt_cmn_l
	dbra	d2,@b
	* global	d4:ソースリストの最終アドレス＋1
	*		a4:現在走査中のソース
cmpl_lp:
	tst.l	macro_now-work(a6)
	beq	@f
	bsr	consider_macro			*マクロに基づきソース変換
@@:
	move.l	sp,sp_buf-work(a6)		*スタック保存
	move.l	a4,line_ptr-work(a6)
	bsr	skip_spc
	cmp.l	a4,d4
	bls	compile_end	*終了
	tst.b	list_mode-work(a6)		*現在の実行モードが.listか.nlistか
	beq	@f
	lea	list_str-work(a6),a1
	jsr	get_com_no-work(a6)
	smi	list_mode-work(a6)
	bmi	skip_comment
	bra	cmpl_lp
@@:
	jsr	chk_num-work(a6)
	bpl	reg_adpcm_data_by_no	*数値ならばADPCM登録(V2形式)
	moveq.l	#0,d0
	move.b	d0,now_cmd-work(a6)	*初期化
	move.b	(a4)+,d0
	beq	compile_end	*終了
	jsr	chk_kanji-work(a6)
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
	cmpi.b	#'(',d0		*文字列と判断して
	bne	m_syntax_error
				*case:'('
	bsr	skip_spc
	cmpi.b	#' ',(a4)
	bls	cmpl_lp
	cmp.l	a4,d4
	bls	compile_end
	move.b	(a4)+,d0
	move.l	d0,d1
	jsr	mk_capital-work(a6)
	subi.b	#$41,d0		*ABC..Z→0,1,2,..,25
	bmi	not_alphabet	*case:smaller than 'A'
	cmpi.b	#25,d0
	bhi	not_alphabet	*case:bigger than 'Z'

	add.w	d0,d0
	move.w	cmn_j_tbl(pc,d0.w),d0
	jmp	cmn_j_tbl(pc,d0.w)

t_undef:	equ	m_syntax_error
cmn_j_tbl:
	dc.w	t_assign-cmn_j_tbl	*a チャンネル／トラック・アサイン
	dc.w	t_bsch-cmn_j_tbl	*b ベースチャンネル設定	(no zmd)
	dc.w	t_cont-cmn_j_tbl	*c	ctrl
	dc.w	t_jump-cmn_j_tbl	*d	no zmd
	dc.w	t_skip-cmn_j_tbl	*e
	dc.w	t_mfader-cmn_j_tbl	*f	ctrl
	dc.w	t_undef-cmn_j_tbl	*g
	dc.w	t_undef-cmn_j_tbl	*h
	dc.w	t_init-cmn_j_tbl	*i
	dc.w	t_undef-cmn_j_tbl	*j
	dc.w	t_undef-cmn_j_tbl	*k
	dc.w	t_undef-cmn_j_tbl	*l
	dc.w	t_skip-cmn_j_tbl	*m	t_alloc
	dc.w	t_undef-cmn_j_tbl	*n
	dc.w	t_tempo-cmn_j_tbl	*o
	dc.w	t_play-cmn_j_tbl	*p	ctrl
	dc.w	t_skip-cmn_j_tbl	*q	t_total
	dc.w	t_skip-cmn_j_tbl	*r	t_rec
	dc.w	t_stop-cmn_j_tbl	*s	ctrl
	dc.w	t_trk-cmn_j_tbl		*t
	dc.w	t_velovol-cmn_j_tbl	*u	no zmd
	dc.w	t_vset-cmn_j_tbl	*v
	dc.w	t_undef-cmn_j_tbl	*w
	dc.w	t_midi_trns-cmn_j_tbl	*x
	dc.w	t_undef-cmn_j_tbl	*y
	dc.w	t_set_mclk-cmn_j_tbl	*z

not_alphabet:
	cmpi.b	#'@',d1		*AL/FB分離フォーマット
	beq	t_vset_2
	bra	m_syntax_error

inc_line:
	pea	cmpl_lp(pc)
cr_line:
	addq.l	#1,line_number-work(a6)
crl_patch:			*DISPLAY LINE MODEではパッチ(bsr.s disp_line)
	nop
	move.l	a4,line_locate-work(a6)
	move.l	a4,line_ptr-work(a6)
	rts

disp_line:
	movem.l	d0/a1,-(sp)
	move.w	#$0d,-(sp)
	DOS	_PUTCHAR
	addq.w	#2,sp
	move.l	line_number-work(a6),d0
	jsr	num_to_str-work(a6)
	lea	suji-work(a6),a1
	jbsr	prta1-work(a6)
	lea	crld_ctr-work(a6),a1
	jsr	prta1-work(a6)
	movem.l	(sp)+,d0/a1
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

compile_end:					*コンパイル終了→ZMD作成
	tst.l	include_depth-work(a6)		*includeしたファイルが
	bne	pop_include_ope			*コンパイル終了したに過ぎない

	move.b	compile_status-work(a6),d0	*d7をチェック
	bpl	@f
	btst.l	#6,d0				*d6をチェック
	beq	@f
	clr.l	line_number-work(a6)
	bsr	m_sync_and_jump_control_are_used_at_the_same_time
@@:
	st.b	compile_phase-work(a6)
	tst.l	n_of_err-work(a6)
	bne	@f
	bsr	free_erfn
	bra	_asmhed_cmpled
@@:
	move.l	err_stock_addr-work(a6),d0	*エラーリスト集配処理
	move.l	d0,a2
	move.l	err_stock_size-work(a6),d2
	add.l	a2,d2
	add.l	err_stock_now-work(a6),a2	*a2=実際に使われた終端アドレスに相当する
	move.l	erfn_now-work(a6),d3
	beq	asmhed_cmpled
	move.l	erfn_addr-work(a6),a5		*アドレスリストを作るための先頭アドレス
	move.l	a5,a1
	add.l	a5,d3				*ソースファイルネーム格納領域最終アドレス
asmerfn_lp00:
	move.l	a2,d1				*ファイルネーム格納アドレス
	sub.l	err_stock_addr-work(a6),d1
asmerfn_lp01:
	cmp.l	a2,d2
	bhi	store_asmerfn
	bsr	enlarge_err_stk			*err_stock_addr領域拡大
	bpl	store_asmerfn
@@:						*エラーケース
	tst.b	(a1)+
	bne	@b
	move.l	a1,d0
	addq.l	#1,d0
	bclr.l	#0,d0
	move.l	d0,a1				*.even
	bra	error_asmerfn
store_asmerfn:
	move.b	(a1)+,(a2)+			*includeしたファイル名のストア
	bne	asmerfn_lp01
	move.l	a1,d0
	addq.l	#1,d0
	bclr.l	#0,d0
	move.l	d0,a1				*.even

	move.l	a2,d0
	addq.l	#1,d0
	bclr.l	#0,d0
	move.l	d0,a2				*.even

	sub.l	a2,d0
	move.l	d0,(a2)+			*内容のアドレス

	move.l	(a1),a3				*読み込んだファイルのアドレス
	move.l	4(a1),d0			*読み込んだファイルの長さ
	beq	aserfn_next
asmerfn_lp02:					*内容のコピー
	cmp.l	a2,d2
	bhi	@f
	bsr	enlarge_err_stk			*err_stock_addr領域拡大
	bmi	error_asmerfn
@@:
	move.l	(a3)+,(a2)+
	subq.l	#4,d0
	bne	asmerfn_lp02
aserfn_next:
	pea	size_of_isi(a1)
	move.l	(a1),a1
	jsr	free_mem-work(a6)	*解放
	move.l	(sp)+,a1
	move.l	d1,(a5)+
	cmp.l	a1,d3			*すべてのソースファイルネームを集配したか
	bhi	asmerfn_lp00
asmerfn2:				*エラーリストのfilename[n]に実行アドレスをセット
	move.l	err_stock_addr-work(a6),a1
	move.l	a1,d1
	add.l	err_stock_now-work(a6),d1	*最終アドレス
	sub.l	a1,a2			*エラーリスト領域のサイズ
	move.l	a2,err_stock_size-work(a6)
	move.l	erfn_addr-work(a6),a2	*ファイルネームアドレス格納リスト
aserfn2_lp:
	tst.l	(a1)+			*error number
	bpl	@f			*next_aserfn2
	move.l	(a1),d0			*filename[n]
	subq.l	#1,d0
	bcs	@f
	lsl.l	#2,d0
	move.l	(a2,d0.l),d0
	add.l	err_stock_addr-work(a6),d0
	move.l	d0,(a1)			*ファイルネーム格納アドレス設定
@@:
	add.w	#12,a1
next_aserfn2:
	cmp.l	a1,d1
	bhi	aserfn2_lp

asmhed_cmpled:				*ヘッダの集配処理
	tst.l	n_of_err-work(a6)	*エラーが有ったか
	bne	compile_err_end		*あった
_asmhed_cmpled:
	move.l	zmd_addr-work(a6),a1
	lea	z_header_size(a1),a2
	cmp.l	a2,a0
	beq	cped_ctrl		*共通コマンドはなし
	move.l	#z_header_size-(z_comn_offset+4),z_comn_offset(a1)

	moveq.l	#-1,d0			*set end code
	jsr	do_wrt_zmd_b-work(a6)
	move.l	a0,d0
	andi.b	#1,d0			*even
	beq	cped_ctrl
	moveq.l	#-1,d0			*set end code
	jsr	do_wrt_zmd_b-work(a6)	*even処理ヒットケース
cped_ctrl:				*制御コマンド・アセンブル
	tst.l	ctrl_now-work(a6)
	beq	cped_trkdt		*制御コマンドなかった
	moveq.l	#-1,d0			*set end code
	jsr	do_wrt_ctrl_b-work(a6)
	move.l	zmd_addr-work(a6),a1
	lea	z_ctrl_offset+4(a1),a1
	move.l	ctrl_addr-work(a6),a2
	move.l	a0,d0
	sub.l	a1,d0
	move.l	d0,-(a1)		*制御コマンド部分へのオフセットをセット

	move.l	ctrl_now-work(a6),d1
	add.l	a2,d1			*制御コマンド部分転送
	addq.l	#3,d1
	andi.w	#$fffc,d1		*make it long word border
	sub.l	a2,d1			*d1.l=制御コマンド部分size
	add.l	d1,a0
	jsr	chk_membdr_zmd-work(a6)	*バッファが足りなければ拡張する
	sub.l	d1,a0
	move.l	a0,ctrl_now-work(a6)	*TR番号再割り振りの時に使うのでここに格納しておく
@@:
	move.l	(a2)+,(a0)+
	subq.l	#4,d1
	bne	@b
cped_trkdt:
	moveq.l	#0,d1			*d1.l=ダミーサイズ
	moveq.l	#0,d2
	moveq.l	#0,d3
	move.w	n_of_track-work(a6),d0	*演奏データトラック数
	beq	get_zmdsz		*no performance data
	subq.w	#1,d0			*for dbra
	move.l	trk_ptr_tbl-work(a6),a2
cpedlp00:
	move.l	tpt_now(a2),d4		*全トラックの演奏データサイズも加算
	beq	cped_next
	addq.l	#3+1,d4			*+1はエンドコード($ff)分
	andi.w	#$fffc,d4		*make it long word border
	add.l	d4,d1			*全トラックの演奏データサイズも加算
	bcs	m_illegal_track_size	*over flow
					*トラック番号再割り振り処理
	move.l	trkn_now-work(a6),d4
	beq	cped00
	move.l	trkn_addr-work(a6),a1
cpedlp01:
	tst.l	tpt_trkno(a2)
	bmi	@f
	move.l	tpt_trkno(a2),a3
	cmp.l	ta_trk_n(a1),a3		*目的のトラック番号か調べる
	bne	@f
	tst.l	ta_type(a1)
	bne	1f
					*MML系
	move.l	trk_ptr_tbl-work(a6),a3
	add.l	ta_tpt_n(a1),a3
	move.l	tpt_addr(a3),a3
	add.l	ta_offset(a1),a3
	bra	2f
1:					*CTRL系
	move.l	ctrl_now-work(a6),a3
	add.l	ta_offset(a1),a3
2:
	move.l	#-1,ta_trk_n(a1)	*done mark
	ror.w	#8,d3
	move.b	d3,(a3)+
	ror.w	#8,d3
	move.b	d3,(a3)+
@@:
	add.w	#ta_size,a1
	sub.l	#ta_size,d4
	bne	cpedlp01
cped00:
	addq.w	#1,d3
cped_next:
	lea	tpt_tsize(a2),a2
	dbra	d0,cpedlp00
	tst.l	d3			*有効トラックがない
	beq	get_zmdsz

	move.l	zmd_addr-work(a6),a1
	lea	z_trk_offset+4(a1),a1
	move.l	a0,d0
	sub.l	a1,d0
	move.l	d0,-(a1)		*トラック情報テーブル部分へのオフセットをセット

	move.l	d3,d0
	subq.w	#1,d0
	jsr	do_wrt_zmd_w-work(a6)	*総トラック数
	move.l	d3,d2
	lsl.l	#ti_size_,d2		*トラック情報テーブルが占有するサイズを予め計算
	add.l	d2,d1
	move.l	d3,d0
	addq.l	#2,d1			*DUMMY '//' SIZE 97/06/24
	lsl.l	#tx_size_,d0		*トラック追加情報が占有するサイズを予め計算
	add.l	d0,d1			*これを加算

	move.l	trk_inf_tbl-work(a6),a1	*トラックコメントのサイズも加算
	move.l	d3,d0
	subq.w	#1,d0			*for dbra
	move.l	trk_ptr_tbl-work(a6),a2
addticmlp:
	move.l	tpt_now(a2),d4		*全トラックの演奏データサイズも加算
	bne	1f
	addq.w	#1,d0			*減算無効化
	bra	2f
1:
	move.l	tit_cmt_len(a1),d4
	addq.l	#3,d4
	andi.w	#$fffc,d4		*make it long word border
	add.l	d4,d1
	bcs	m_illegal_track_size	*over flow
2:
	addq.w	#tit_next,a1
	add.l	(a1)+,a1
	lea	tpt_tsize(a2),a2
	dbra	d0,addticmlp
get_zmdsz:
	move.l	zmd_addr-work(a6),a1
	lea	(a0,d1.l),a2
	suba.l	a1,a2			*a2.l=ZMD本体のサイズ
	move.l	a2,z_zmd_size(a1)	*ZMDのサイズを格納

	add.l	err_stock_size-work(a6),d1	*ウォーニングコードテーブルサイズ分
	addq.l	#4,d1			*ウォーニング数格納領域分
	add.l	d1,a0			*予め使用するメモリ量を計算して確保
	jsr	fix_zmd_size-work(a6)	*ZMDサイズ確定
	sub.l	d1,a0			*a0.l=トラック情報テーブルの書き込み先アドレス
	move.w	n_of_track-work(a6),d3
	beq	mk_wn_tbl		*トラック数ゼロの場合
	subq.w	#1,d3			*for dbra
	lea	2(a0,d2.l),a1		*a1.l=トラックデータの書き込み先アドレス
	move.l	trk_inf_tbl-work(a6),a2
	move.l	trk_ptr_tbl-work(a6),a4
asm_zmd_lp:				*演奏データのアセンブル
	move.l	tpt_now(a4),d4		*サイズ(do_copy_dataで使用)
	beq	asm_zmd_next		*空ならば次へ
	move.l	tit_stat_mode(a2),(a0)+	*ti_track_stat,ti_track_mode,ti_trkfrq,ti_trkfrqwk
	move.l	tit_type_ch(a2),(a0)+	*ti_type,ti_ch
	addq.w	#4,a0
	move.l	a1,d0
	add.l	#tx_size,d0
	move.l	tit_cmt_len(a2),d1	*コメントサイズ
	move.l	d1,d2
	addq.l	#3,d2
	andi.w	#$fffc,d2		*convert it into long word border
	add.l	d2,d0
	move.l	d0,a5			*演奏データが格納されるべきアドレス
	sub.l	a0,d0
	move.l	d0,-4(a0)		*演奏データまでのオフセットをセット
	addq.w	#4,a0
	move.l	a1,d0
	sub.l	a0,d0
	move.l	d0,-4(a0)		*トラック追加情報までのオフセットをセット
	move.w	#'//',(a0)		*97/06/24

	clr.l	(a1)+			*total_step
	clr.l	(a1)+			*checksum
	clr.l	(a1)+			*n_of_measure
	move.l	d1,(a1)+		*comment length
	beq	do_copy_play_data	*トラックコメント無し
	lea	tit_comment(a2),a3
@@:					*トラックコメント転送
	move.l	(a3)+,(a1)+
	subq.l	#4,d2
	bne	@b
do_copy_play_data:			*演奏データの転送
	move.l	a5,a1
	move.l	tpt_addr(a4),a3		*演奏データの格納アドレス
	add.l	d4,a5
	addq.l	#3+1,d4			*+1はend code分
	andi.w	#$fffc,d4		*make it long word border
@@:
	move.l	(a3)+,(a1)+		*転送
	subq.l	#4,d4
	bne	@b
@@:
	st.b	(a5)+			*play_end_zmdを終端にセット
	cmp.l	a5,a1
	bne	@b
asm_zmd_next:
	addq.w	#tit_next,a2
	add.l	(a2)+,a2
	lea	tpt_tsize(a4),a4
	dbra	d3,asm_zmd_lp
mk_wn_tbl:
	move.l	zmd_addr-work(a6),a1
	add.l	z_zmd_size(a1),a1
	move.l	n_of_warn-work(a6),(a1)+	*ウォーニングコードの数
	move.l	err_stock_addr-work(a6),a2
	move.l	err_stock_size-work(a6),d2
	beq	free_mmwk
@@:					*ウォーニングコードテーブル転送
	move.l	(a2)+,(a1)+
	subq.l	#4,d2
	bne	@b
free_mmwk:				*ワーク解放
	bsr	free_work_area		*ワークエリア解放
	move.l	err_stock_addr-work(a6),d0
	beq	@f
	move.l	d0,a1
	jsr	free_mem-work(a6)	*エラー(ウォーニング)コードテーブル解放
@@:
	move.l	zmd_addr-work(a6),a0	*data addr
	tst.l	z_trk_offset(a0)	*演奏データがあるならばデフォルトパラメータを設定する
	beq	exit_cmpled
	tst.w	z_tempo(a0)
	bne	exit_cmpled
	move.w	#120,z_tempo(a0)
exit_cmpled:
	moveq.l	#0,d0				*no error mark
	rts

free_erfn:					*erfn_addr中のバッファを解放
reglist	reg	d0/d3/a0-a1
	movem.l	reglist,-(sp)
	move.l	erfn_now-work(a6),d3
	beq	exit_free_erfn
	move.l	erfn_addr-work(a6),a0
	add.l	a0,d3
@@:					*ファイル名文字列スキップ
	tst.b	(a0)+
	bne	@b
	move.l	a0,d0
	addq.l	#1,d0
	bclr.l	#0,d0
	move.l	d0,a0			*even
	move.l	(a0),a1
	add.l	err_stock_addr-work(a6),a1
	pea	size_of_isi(a0)
	jsr	free_mem
	move.l	(sp)+,a0
	cmp.l	a0,d3			*すべてのソースファイルネームを集配したか
	bhi	@b
exit_free_erfn:
	movem.l	(sp)+,reglist
	rts

error_asmerfn:					*エラーケース
	move.l	a1,a2
errasmerfnlp:
	move.l	(a2),a1
	jsr	free_mem-work(a6)
	add.l	#size_of_isi,a2
	cmp.l	a2,d3				*すべてのソースファイルネームを集配したか
	bls	exit_errasmerfnlp
@@:						*filename skip
	tst.b	(a2)+
	bne	@b
	move.l	a2,d0
	addq.l	#1,d0
	bclr.l	#0,d0
	move.l	d0,a2				*.even
	bra	errasmerfnlp
exit_errasmerfnlp:
	move.l	#1,n_of_err-work(a6)
	clr.l	n_of_warn-work(a6)
	move.l	err_stock_addr-work(a6),a1
	move.l	#ZM_COMPILER*65536+OUT_OF_MEMORY,(a1)
compile_err_end:			*エラー終了
	bsr	free_work_area		*ワークエリア解放
	suba.l	a0,a0			*a0=0
	move.l	n_of_err-work(a6),d0	*ウォーニングの数とエラーの数を合計して
	add.l	n_of_warn-work(a6),d0	*持って帰る
	tst.w	compile_option+2-work(a6)	*エラーテーブル作成要求有るか
	bpl	@f
	move.l	err_stock_addr-work(a6),a0
@@:
	rts

free_work_area:
	* x d3,a1,a2
	bsr	free_erfn

	move.l	erfn_addr-work(a6),a1
	jsr	free_mem-work(a6)

	move.l	ctrl_addr-work(a6),a1	*制御コマンドバッファ解放
	jsr	free_mem-work(a6)

	move.l	trkn_addr-work(a6),a1	*トラック番号再割り振り用ワーク解放
	jsr	free_mem-work(a6)

	move.l	trk_inf_tbl-work(a6),a1	*トラック情報テーブル解放
	jsr	free_mem-work(a6)

	move.l	mcrnm_hash_tbl-work(a6),d0	*ハッシュテーブル解放
	beq	@f
	move.l	d0,a1
	jsr	free_mem-work(a6)
@@:
	move.l	ptn_addr-work(a6),d0	*パターントラック管理テーブル解放
	beq	@f
	move.l	d0,a1
	jsr	free_mem-work(a6)
@@:
	move.l	macro_addr-work(a6),d0	*マクロ文字列バッファ解放
	beq	@f
	move.l	d0,a1
	jsr	free_mem-work(a6)
@@:
	move.l	pmr_addr-work(a6),d0	*マクロ変換情報バッファ解放
	beq	@f
	move.l	d0,a1
	jsr	free_mem-work(a6)
@@:
	move.l	chgsrc_addr-work(a6),d0	*変換ソースバッファ解放
	beq	@f
	move.l	d0,a1
	jsr	free_mem-work(a6)
@@:
	move.l	trk_ptr_tbl-work(a6),a2	*トラックバッファ管理テーブル解放
	move.w	n_of_track-work(a6),d3
	beq	free_tpt
	subq.w	#1,d3			*for dbra
fwalp0:
	move.l	tpt_addr(a2),a1		*トラックバッファ解放
	jsr	free_mem-work(a6)
	move.l	tpt_rept_addr(a2),d0	*繰り返しコマンドワーク解放
	beq	@f
	move.l	d0,a1
	jsr	free_mem-work(a6)
@@:
	move.l	tpt_sgcd_addr(a2),d0	*反復記号コマンドワーク解放
	beq	@f
	move.l	d0,a1
	jsr	free_mem-work(a6)
@@:
	move.l	tpt_fgmap_addr(a2),d0	*反復記号フラグワークマップ解放
	beq	@f
	move.l	d0,a1
	jsr	free_mem-work(a6)
@@:
	move.l	tpt_renp_addr(a2),d0
	beq	@f
	move.l	d0,a1
	jsr	free_mem-work(a6)
@@:
	lea	tpt_tsize(a2),a2
	dbra	d3,fwalp0
free_tpt:
	move.l	trk_ptr_tbl-work(a6),a1	*トラックバッファ管理テーブル解放
	jsr	free_mem-work(a6)
	clr.l	trk_ptr_tbl-work(a6)	*初期化
	rts

enlarge_err_stk:				*err_stock_addr領域拡大
	* < a2.l=now address
	* > a2.l=new address
	* > d2.l=new end address
	* > eq:no error
	* > mi:error
	movem.l	d0-d1/d3/a0-a1,-(sp)
	move.l	err_stock_addr-work(a6),a1
	move.l	a2,d1
	sub.l	a1,d1
	move.l	d1,d2
	add.l	#65536,d2			*64kbバイト拡張
	move.l	d2,err_stock_size-work(a6)
	jsr	enlarge_mem-work(a6)
	tst.l	d0
	bmi	@f				*メモリ不足
	lea	(a0,d1.l),a2
	move.l	a0,err_stock_addr-work(a6)
	move.l	err_stock_size-work(a6),d2
	add.l	a0,d2
	moveq.l	#0,d0
@@:
	movem.l	(sp)+,d0-d1/d3/a0-a1
	rts
*-----------------------------------------------------------------------------
release_compiler:			*コンパイラの解放処理
	lea	work,a6			*わざと
	move.l	a0work-work(a6),d0
	beq	rc_release_err0

	moveq.l	#-1,d1
	Z_MUSIC	#ZM_OCCUPY_COMPILER	*コンパイラが占有されているか
	tst.l	d0
	bne	rc_release_err1		*されてた

	suba.l	a1,a1			*a1.l=0
	move.l	rel_cmplr_mark-work(a6),d1
	Z_MUSIC	#ZM_APPLICATION_RELEASER	*解放ルーチン登録取消
	move.l	a0,d0
	beq	rc_release_err0

	moveq.l	#ZM_COMPILER,d1
	suba.l	a1,a1			*vacant mark
	Z_MUSIC	#ZM_HOOK_FNC_SERVICE

	moveq.l	#ZM_OCCUPY_COMPILER,d1
	suba.l	a1,a1			*vacant mark
	Z_MUSIC	#ZM_HOOK_FNC_SERVICE

	moveq.l	#ZM_CALC_TOTAL,d1
	suba.l	a1,a1			*vacant mark
	Z_MUSIC	#ZM_HOOK_FNC_SERVICE

	move.l	zmc_work-work(a6),-(sp)
	DOS	_MFREE
	addq.w	#4,sp

	bsr	kill_ZMC		*デバイス名をシステムワークより除去
	bmi	rc_release_err0

	lea	kaijo-work(a6),a1
	move.l	a0work-work(a6),a0
	moveq.l	#0,d0			*no error
bye_rlscmplr:
	tst.b	errmes_lang-work(a6)	*0:英語か 1:日本語か
	beq	exit_rlscmplr
@@:					*次のメッセージをゲット
	tst.b	(a1)+
	bne	@b
exit_rlscmplr:
	rts

rc_release_err0:			*解除不能
	lea	kaijo_er-work(a6),a1
	suba.l	a0,a0
	moveq.l	#-1,d0			*error
	bra	bye_rlscmplr

rc_release_err1:			*占有されている
	lea	kaijo_er-work(a6),a1
	suba.l	a0,a0
	moveq.l	#1,d0			*error
	bra	bye_rlscmplr

kill_ZMC:				*デバイス名の除去
	* > eq=no error
	* > mi=error
	lea	$6800,a0		*デバイス名”ＯＰＭ”を強制的に削除する
KO_lp01:
	lea	NUL-work(a6),a2
	bsr	do_find
	cmpa.l	a2,a0
	bcc	KO_err
	cmpi.w	#$8024,-18(a0)		*本当にNULか
	bne	KO_lp01

	lea	-22(a0),a1
	move.l	a1,nul_address-work(a6)

	lea	dev_name0(pc),a2
	bsr	rmk_heap		*ヒープ調査(return:a1,a0)
	bmi	KO_err
	move.l	device_driver0(pc),(a0)	*ヒープを再構成して自分は抜ける

	moveq.l	#0,d0
	rts
KO_err:
	moveq.l	#-1,d0
	rts

do_find:			*特定のデバイス名を探し出す
	move.b	(a2),d0
dfn_lp01:			*一文字目が見付かるまでループ
	cmp.b	(a0)+,d0
	bne	dfn_lp01

	move.l	a0,d0		*save a0 to d0
	lea	1(a2),a1
	moveq.l	#7-1,d1
dfn_lp02:
	cmpm.b	(a0)+,(a1)+
	bne	next_dfn
	dbra	d1,dfn_lp02
	rts
next_dfn:
	movea.l	d0,a0		*get back a0
	bra	do_find

rmk_heap:
	* < a1.l=NUL
	* < a2.l=抜けたいデバイス名
	* > a0.l=探し出したデバイス名のアドレスの1つ前のデバイスのアドレス
	* d0,a0,a1,a2
	lea	-14(a2),a3
KO_lp02:
	bsr	same_dev?
	bne	@f
	cmp.l	a1,a3
	bne	@f
	moveq.l	#0,d0		*Hit!
	rts
@@:
	cmpi.l	#-1,(a1)	*最後尾に来てしまったか
	beq	err_KO
	movea.l	a1,a0		*一つ前のをキープ(戻り値になる)
	move.l	(a1),a1		*次へ
	bra	KO_lp02
err_KO:
	moveq.l	#-1,d0
	rts

same_dev?:			*同じ名前かどうか
	* < a2.l=source name
	* > mi=not same
	* > eq=same
	movem.l	a1-a2,-(sp)
	lea	14(a1),a1
	moveq.l	#8-1,d1
@@:
	cmpm.b	(a1)+,(a2)+
	bne	@f
	dbra	d1,@b
	moveq.l	#0,d0
	movem.l	(sp)+,a1-a2
	rts
@@:
	moveq.l	#-1,d0
	movem.l	(sp)+,a1-a2
	rts


t_skip:			*閉じ括弧を見つけるまでループ(V2コマンドをエラー出力なしでスキップ)
tskplp:
	cmp.l	a4,d4
	bls	m_illegal_command_line
	move.b	(a4)+,d0
	cmpi.b	#$0a,d0
	bne	@f
	bsr	cr_line
	bra	tskplp
@@:
	cmpi.b	#')',d0
	bne	tskplp
	bra	cmpl_lp		*恐らく次は$0a

find_end:			*終端 ')' '}' を見付ける処理
	bsr	skip_spc
	moveq.l	#')',d0
	tst.b	now_cmd-work(a6)
	bpl	@f
	moveq.l	#'}',d0
@@:
	cmp.l	a4,d4
	bls	m_illegal_command_line
	cmp.b	(a4)+,d0
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
	cmpi.b	#(sc_jmp_tbl-scjt_comment)/2,d0			*comment文のケース
	beq	@f
	bsr	skip_spc		*skip separater(パラメータ無しのコマンドもあるから)
	bra	set_kkt
@@:					*(tst.l	d4はやらない)
	bsr	skip_spc1		*skip separater
set_kkt:
	tas.b	now_cmd-work(a6)
	add.w	d0,d0
	add.w	d0,d0
	move.l	sc_jmp_tbl(pc,d0.w),d0
	jmp	sc_jmp_tbl(pc,d0.l)

sc_jmp_tbl:					*＃コマンドのジャンプテーブル
	dc.l	reg_16bitpcm_timbre-sc_jmp_tbl
	dc.l	reg_16bitpcm_tone-sc_jmp_tbl
	dc.l	reg_8bitpcm_timbre-sc_jmp_tbl
	dc.l	reg_8bitpcm_tone-sc_jmp_tbl
	dc.l	set_adpcm_bank-sc_jmp_tbl
	dc.l	adpcm_block_data-sc_jmp_tbl
	dc.l	adpcm_list-sc_jmp_tbl
	dc.l	reg_adpcm_timbre-sc_jmp_tbl
	dc.l	reg_adpcm_tone-sc_jmp_tbl
	dc.l	pcm_tune_setup-sc_jmp_tbl
	dc.l	assign-sc_jmp_tbl
	dc.l	adpcm_list-sc_jmp_tbl
	dc.l	call-sc_jmp_tbl
scjt_comment:	dc.l	comment-sc_jmp_tbl
	dc.l	continue-sc_jmp_tbl
	dc.l	current_midi_in-sc_jmp_tbl
	dc.l	current_midi_out-sc_jmp_tbl
	dc.l	define-sc_jmp_tbl
	dc.l	dummy-sc_jmp_tbl
	dc.l	erase_tone-sc_jmp_tbl
	dc.l	erase_timbre-sc_jmp_tbl
	dc.l	erase-sc_jmp_tbl
	dc.l	exclusive-sc_jmp_tbl
	dc.l	fixed_gatetime-sc_jmp_tbl
	dc.l	fm_master_volume-sc_jmp_tbl
	dc.l	fm_vset-sc_jmp_tbl
	dc.l	fm_tune_setup-sc_jmp_tbl
	dc.l	fm_vset-sc_jmp_tbl
	dc.l	gatetime_resolution-sc_jmp_tbl
	dc.l	gm_system_on-sc_jmp_tbl
	dc.l	gs_chorus-sc_jmp_tbl
	dc.l	gs_display-sc_jmp_tbl
	dc.l	gs_drum_setup-sc_jmp_tbl
	dc.l	gs_drum_setup-sc_jmp_tbl
	dc.l	gs_drum_name-sc_jmp_tbl
	dc.l	gs_reset-sc_jmp_tbl
	dc.l	gs_partial_reserve-sc_jmp_tbl
	dc.l	gs_part_setup-sc_jmp_tbl
	dc.l	gs_part_setup-sc_jmp_tbl
	dc.l	gs_print-sc_jmp_tbl
	dc.l	gs_reset-sc_jmp_tbl
	dc.l	gs_reverb-sc_jmp_tbl
	dc.l	gs_partial_reserve-sc_jmp_tbl
	dc.l	halt-sc_jmp_tbl
	dc.l	include_file-sc_jmp_tbl
	dc.l	initialize-sc_jmp_tbl
	dc.l	curb_jump-sc_jmp_tbl
	dc.l	key-sc_jmp_tbl
	dc.l	length_mode-sc_jmp_tbl
	dc.l	list-sc_jmp_tbl
	dc.l	m1_effect_setup-sc_jmp_tbl
	dc.l	m1_setup-sc_jmp_tbl
	dc.l	m1_part_setup-sc_jmp_tbl
	dc.l	m1_print-sc_jmp_tbl
	dc.l	m1_setup-sc_jmp_tbl
	dc.l	master_clock_cmd-sc_jmp_tbl
	dc.l	master_fader-sc_jmp_tbl
	dc.l	meter-sc_jmp_tbl
	dc.l	midi_data-sc_jmp_tbl
	dc.l	midi_dump-sc_jmp_tbl
	dc.l	mt32_common-sc_jmp_tbl
	dc.l	mt32_drum_setup-sc_jmp_tbl
	dc.l	mt32_reset-sc_jmp_tbl
	dc.l	mt32_partial_reserve-sc_jmp_tbl
	dc.l	mt32_partial-sc_jmp_tbl
	dc.l	mt32_part_setup-sc_jmp_tbl
	dc.l	mt32_patch-sc_jmp_tbl
	dc.l	mt32_partial_reserve-sc_jmp_tbl
	dc.l	mt32_print-sc_jmp_tbl
	dc.l	mt32_reset-sc_jmp_tbl
	dc.l	mt32_reverb-sc_jmp_tbl
	dc.l	mt32_drum_setup-sc_jmp_tbl
	dc.l	nlist-sc_jmp_tbl
	dc.l	reg_adpcm_data_by_kc-sc_jmp_tbl
	dc.l	pattern-sc_jmp_tbl
	dc.l	pcm_tune_setup-sc_jmp_tbl
	dc.l	performance_time-sc_jmp_tbl
	dc.l	play-sc_jmp_tbl
	dc.l	print-sc_jmp_tbl
	dc.l	relative_velocity-sc_jmp_tbl
	dc.l	roland_exclusive-sc_jmp_tbl
	dc.l	gs_chorus-sc_jmp_tbl
	dc.l	gs_display-sc_jmp_tbl
	dc.l	gs_drum_setup-sc_jmp_tbl
	dc.l	gs_drum_setup-sc_jmp_tbl
	dc.l	gs_drum_name-sc_jmp_tbl
	dc.l	gs_reset-sc_jmp_tbl
	dc.l	gs_partial_reserve-sc_jmp_tbl
	dc.l	gs_part_setup-sc_jmp_tbl
	dc.l	gs_part_setup-sc_jmp_tbl
	dc.l	gs_print-sc_jmp_tbl
	dc.l	gs_reverb-sc_jmp_tbl
	dc.l	gs_reset-sc_jmp_tbl
	dc.l	gs_partial_reserve-sc_jmp_tbl
	dc.l	sc88_mode-sc_jmp_tbl
	dc.l	sc88_mode-sc_jmp_tbl
	dc.l	sc88_reverb-sc_jmp_tbl
	dc.l	sc88_chorus-sc_jmp_tbl
	dc.l	sc88_delay-sc_jmp_tbl
	dc.l	sc88_equalizer-sc_jmp_tbl
	dc.l	sc88_part_setup-sc_jmp_tbl
	dc.l	sc88_part_setup-sc_jmp_tbl
	dc.l	sc88_drum_setup-sc_jmp_tbl
	dc.l	sc88_drum_setup-sc_jmp_tbl
	dc.l	sc88_drum_name-sc_jmp_tbl
	dc.l	sc88_user_inst-sc_jmp_tbl
	dc.l	sc88_user_drum-sc_jmp_tbl
	dc.l	send_to_m1-sc_jmp_tbl
	dc.l	midi_dump-sc_jmp_tbl
	dc.l	stop-sc_jmp_tbl
	dc.l	tempo-sc_jmp_tbl
	dc.l	track_fader-sc_jmp_tbl
	dc.l	track_mask-sc_jmp_tbl
	dc.l	track-sc_jmp_tbl
	dc.l	u220_common-sc_jmp_tbl
	dc.l	u220_drum_inst-sc_jmp_tbl
	dc.l	u220_drum_setup-sc_jmp_tbl
	dc.l	u220_part_setup-sc_jmp_tbl
	dc.l	u220_print-sc_jmp_tbl
	dc.l	u220_setup-sc_jmp_tbl
	dc.l	u220_timbre-sc_jmp_tbl
	dc.l	wave_form-sc_jmp_tbl
	dc.l	wave_form-sc_jmp_tbl
	dc.l	yamaha_exclusive-sc_jmp_tbl
	dc.l	yamaha_exclusive-sc_jmp_tbl
	dc.l	zpd_equ-sc_jmp_tbl
sc_jmp_tbl_end:

assign:					*トラック・アサイン(.assign)
*	jsr	check_relation_cmn-work(a6)	*コマンド関係チェック
	clr.l	assign_bracket-work(a6)
	bsr	get_asgn_trk		*トラック番号取りだし
	bsr	skip_sep
	bsr	skip_eq
	cmp.l	a4,d4
	bls	@f
	cmpi.b	#'{',(a4)
	bne	@f
	addq.w	#1,a4		*skip '{'
	move.l	#' { }',assign_bracket-work(a6)
@@:
	bsr	get_asgn_ch		*チャンネル番号取りだし
go_assign:
	bsr	check_trchrng		*トラック-チャンネル整合性チェック
	lea	line_backup-work(a6),a2
	move.l	line_number-work(a6),(a2)+
	move.l	line_locate-work(a6),(a2)+
	move.l	line_ptr-work(a6),(a2)+
	move.l	n_of_err-work(a6),(a2)+
gaslp00:
	movem.l	d4/a4,-(sp)
	move.l	asgn_trk_s-work(a6),d5
	move.l	asgn_ch_s-work(a6),d2
	bsr	do_assign		*実際のアサイン処理へ
	move.l	asgn_trk_s-work(a6),d0
	cmp.l	asgn_trk_e-work(a6),d0
	beq	exit_asgn
	move.l	n_of_err-work(a6),d0
	cmp.l	line_backup+12-work(a6),d0
	bne	exit_asgn		*エラーが発生している
	movem.l	(sp)+,d4/a4
	move.l	line_backup+8-work(a6),line_ptr-work(a6)
	move.l	line_backup+4-work(a6),line_locate-work(a6)
	move.l	line_backup+0-work(a6),line_number-work(a6)

	move.l	asgn_trk_s-work(a6),d0
	cmp.l	asgn_trk_e-work(a6),d0
	bcs	@f
	subq.l	#1,asgn_trk_s-work(a6)
	bra	1f
@@:
	addq.l	#1,asgn_trk_s-work(a6)
1:
	move.l	asgn_ch_s-work(a6),d0
	cmp.l	asgn_ch_e-work(a6),d0
	bcs	@f
	subq.l	#1,asgn_ch_s-work(a6)
	bra	gaslp00
@@:
	addq.l	#1,asgn_ch_s-work(a6)
	bra	gaslp00
exit_asgn:
	addq.w	#8,sp			*movem.l d4/a4,-(sp)を無効に
	tst.l	assign_bracket-work(a6)
	beq	cmpl_lp
	bra	find_end

t_assign:			*チャンネル・アサイン(Ach,tr)
*	jsr	check_relation_cmn-work(a6)	*コマンド関係チェック
	move.l	#' ( )',assign_bracket-work(a6)
	bsr	get_asgn_ch
	bsr	skip_sep
	bsr	get_asgn_trk
	bra	go_assign

get_asgn_trk:				*トラック番号取得
	* x d1
	bsr	chk_num
	bpl	@f
	bsr	srch_num		*TRnなどの接頭文字列をスキップする
	bmi	m_assign_command_error
@@:
	bsr	get_num			*TR番号取りだし(ただし65535はパターントラック専用番号)
	subq.l	#1,d1
	cmpi.l	#tr_max-1,d1
	bhi	m_illegal_track_number
	move.l	d1,asgn_trk_s-work(a6)
	move.l	d1,asgn_trk_e-work(a6)
	bsr	chk_num
	bmi	@f
	bsr	get_num			*TR1-2のようなケースに対応
	neg.l	d1
	bmi	m_illegal_track_number
	subq.l	#1,d1
	cmpi.l	#tr_max-1,d1
	bhi	m_illegal_track_number
	move.l	d1,asgn_trk_e-work(a6)
@@:
	rts

get_asgn_ch:			*チャンネル取得
	* x a1,d1-d2
	bsr	chk_num		*数値指定か文字指定か
	bmi	1f
				*数値指定(V2互換考慮)
	bsr	get_num
	subq.l	#1,d1
	cmpi.l	#31,d1
	bhi	m_illegal_channel
	lsl.w	#2,d1
	lea	real_ch_tbl-work(a6),a1
	move.l	(a1,d1.w),d2
	move.l	d2,asgn_ch_s-work(a6)
	move.l	d2,asgn_ch_e-work(a6)
	bsr	chk_num
	bmi	2f
	bsr	get_num		*FM1-2のようなケースに対応
	neg.l	d1
	bmi	m_illegal_channel
	subq.l	#1,d1
	cmpi.l	#31,d1
	bhi	m_illegal_channel
	lsl.w	#2,d1
	lea	real_ch_tbl-work(a6),a1
	move.l	(a1,d1.w),asgn_ch_e-work(a6)
	bra	2f
1:				*文字列指定ケース
	bsr	get_str_ch	*> d2=type,ch
	bne	m_error_code_exit
	move.l	d2,asgn_ch_s-work(a6)
	move.l	d2,asgn_ch_e-work(a6)
	bsr	chk_num
	bmi	2f
	bsr	get_num		*FM1-2のようなケースに対応
	neg.l	d1
	bmi	m_illegal_channel
	subq.l	#1,d1
	move.w	d1,d2
	move.l	d2,asgn_ch_e-work(a6)
	swap	d2
	tst.w	d2		*チャンネル番号の正当性チェック
	bne	1f
	cmpi.l	#8-1,d1		*FM
	bhi	m_illegal_channel
	bra	2f
1:
	cmpi.l	#16-1,d1	*MIDI&ADPCM
	bhi	m_illegal_channel
2:
	rts

check_trchrng:			*整合性チェック
	move.l	asgn_trk_e-work(a6),d0
	move.l	asgn_trk_s-work(a6),d1
	cmp.l	d1,d0
	bcc	@f
	exg.l	d0,d1
@@:
	sub.l	d1,d0		*d0.l=変化幅
	move.l	d0,-(sp)

	move.l	asgn_ch_e-work(a6),d0
	move.l	asgn_ch_s-work(a6),d1
	cmp.l	d1,d0
	bcc	@f
	exg.l	d0,d1
@@:
	sub.l	d1,d0		*d0.l=変化幅
	cmp.l	(sp)+,d0
	bne	m_assign_command_error	*チャンネルとトラックの変化幅が合わない
	rts

do_assign:				*トラック/チャンネルアサイン
	* < d2=ch,d5=tr
	move.l	#$0080_0000,d6		*trk vol=128,trk freq=0(means 1)
	moveq.l	#0,d1			*stat,mode,frq,frqwk=0
	tst.l	assign_bracket-work(a6)
	beq	check_reasgn
					*trk vol
	bsr	skip_sep
	bsr	chk_num			*もう数値はない
	bmi	@f
	bsr	get_num			*トラック音量値取りだし
	cmpi.l	#1024,d1
	bhi	m_illegal_track_volume
	move.l	d1,d6
	swap	d6
@@:					*trk freq.
	moveq.l	#0,d1			*d1=default
	bsr	skip_sep
	bsr	chk_num			*もう数値はない
	bmi	@f
	bsr	get_num			*割り込み頻度値取りだし
	subq.l	#1,d1
	cmpi.l	#255,d1
	bhi	m_illegal_track_frequency
	move.w	d1,d6
	lsl.w	#8,d1
@@:
	bsr	skip_sep		*skip ,
	* < d1=frquency,d2=ch,d5=tr
	lea	track_stat_cmdln-work(a6),a1
	bsr	get_com_no		*get track stat > (0/1)
	bpl	@f
	moveq.l	#0,d0			*default
@@:
	swap	d1
	move.w	d0,d1
	beq	@f
	move.w	#$80+ID_REC,d1
@@:
	bsr	skip_sep		*skip ,
	lea	track_mode_cmdln-work(a6),a1
	bsr	get_com_no		*get track mode > (0/1)
	bpl	@f
	moveq.l	#0,d0			*default
@@:
	tst.l	d0
	beq	@f
	moveq.l	#$80,d0			*no key off
@@:
	lsl.w	#8,d1
	move.b	d0,d1
	swap	d1			*stat,mode,frq,frqwk
check_reasgn:
	move.l	trk_inf_tbl-work(a6),a1
	move.l	ti_link_offset-work(a6),d0	*リンク・オフセット=0の時は
	beq	new_gtr_fst		*だぶりチェック省略
	move.l	d0,a2
@@:
	cmp.w	(a1)+,d5		*既に登録済み
	beq	m_reassignment_error
	move.l	(a1)+,d0
	beq	new_gtr			*新規に登録
	add.l	d0,a1
	bra	@b
new_gtr:				*2回目以降の登録
	move.l	tit_now-work(a6),d0
	sub.l	a2,d0
	add.l	trk_inf_tbl-work(a6),a2
	move.l	d0,-(a2)		*set link offset
new_gtr_fst:				*1回目の登録(link処理無し)
	move.w	d5,d0
	jsr	set_tit_w-work(a6)	*register trk no.
	addq.w	#1,n_of_track-work(a6)	*トラック数増加
	beq	m_too_many_tracks	*オーバーフロー(トラック数が多すぎる)
	moveq.l	#0,d0
	jsr	set_tit_l-work(a6)	*4bytes reserving for offset space
	move.l	tit_now-work(a6),ti_link_offset-work(a6)	*keep
	move.l	d1,d0
	jsr	set_tit_l-work(a6)	*stat,mode,frq,frqwk
	move.l	d2,d0
	jsr	set_tit_l-work(a6)	*p_type,p_ch
	moveq.l	#0,d0
	jsr	set_tit_l-work(a6)	*4bytes reserving for string length

	move.l	assign_bracket-work(a6),d1	*終端文字パターン
	beq	mark_usedev		*{}パターンではない
	bsr	skip_sep
	cmp.l	a4,d4
	bls	m_illegal_command_line
	cmp.b	(a4),d1			*コメントがあるか
	beq	mark_usedev		*no
	move.l	tit_now-work(a6),a5	*keep
	moveq.l	#0,d2			*ネスト構造考慮
	moveq.l	#0,d3			*文字列カウンタ
ngflp:					*文字列取得
	move.b	(a4)+,d0
	bsr	chk_kanji		*漢字かどうかチェック
	bpl	@f
	jsr	set_tit-work(a6)
	addq.l	#1,d3			*inc str length
	cmp.l	a4,d4
	bls	m_string_break_off
	move.b	(a4)+,d0
	bra	ngflp_next
@@:
	swap	d1
	cmp.b	d1,d0			*{}のネストも考慮する
	bne	@f
	addq.l	#1,d2
@@:
	swap	d1
	cmp.b	d1,d0			*}が有って文字列終わった
	bne	@f
	subq.l	#1,d2
	bcs	1f			*終わり
@@:
	cmp.b	#$0a,d0
	bne	ngflp_next
	bsr	cr_line			*改行
ngflp_next:
	jsr	set_tit-work(a6)
	addq.l	#1,d3			*inc str length
	cmp.l	a4,d4
	bhi	ngflp
	cmp.l	#$0000_000a,d1
	bne	m_string_break_off
1:
	subq.w	#1,a4			*終端文字')','}'までポインタを戻す
	moveq.l	#0,d0			*str end code
	jsr	set_tit-work(a6)
	btst.b	#0,tit_now+3-work(a6)	*オフセットポインタの最下位ビットを検査
	beq	@f
	moveq.l	#0,d0			*str end code(.even)
	jsr	set_tit-work(a6)
@@:
	add.l	trk_inf_tbl-work(a6),a5
	move.l	d3,-(a5)		*set string length
*- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
mark_usedev:
	* < d2.l=type,ch		*使用したデバイスのマーキング
	* x d0,a1
	move.l	zmd_addr-work(a6),a1
	move.l	d2,d0
	swap	d0
	tst.w	d0
	bmi	mkudv_md
	bne	mkudv_ad
*mkudv_fm:			*FM
	addq.b	#1,z_nof_fm_ch(a1)
	bra	dotrkalc
mkudv_ad:			*ADPCM
	addq.b	#1,z_nof_ad_ch(a1)
	bra	dotrkalc
mkudv_md:			*MIDI
	andi.w	#$7fff,d0	*d0=midi if no.(0-2)
	cmpi.w	#$7fff,d0
	bne	@f
	moveq.l	#0,d0
@@:
	addq.b	#1,z_nof_md1_ch(a1,d0.w)
dotrkalc:

alloc_trk_buf:				*トラックバッファの確保
	* < d5.l=trk number(0-65534,65535)
	* < d6.w=track frequency(0-255)
	* - all
reglist	reg	d0-d3/a0-a2/a5
	movem.l	reglist,-(sp)
	moveq.l	#0,d1
	move.w	n_of_track-work(a6),d1
	cmp.w	trk_n_max-work(a6),d1
	bcs	do_scr_tbf		*トラックバッファ確保処理へ
	movem.l	d0-d2/a0-a1,-(sp)	*トラックバッファ管理テーブルの更新/追加登録
	andi.l	#$ffff,d1
	addq.l	#8,d1			*上限を増やす
	cmpi.l	#tr_max,d1
	bls	@f
	move.l	#tr_max,d1
@@:
	move.l	d1,d2
	mulu	#tpt_tsize,d2
	move.l	trk_ptr_tbl-work(a6),a1
	jsr	enlarge_mem-work(a6)
	tst.l	d0
	bmi	m_out_of_memory
@@:
	move.l	a0,trk_ptr_tbl-work(a6)
	move.w	d1,trk_n_max-work(a6)
	movem.l	(sp)+,d0-d2/a0-a1
do_scr_tbf:				*トラックバッファの確保
	subq.l	#1,d1
	mulu	#tpt_tsize,d1
	move.l	trk_ptr_tbl-work(a6),a2
	add.l	d1,a2
	move.l	#10240,d2		*1トラック当たりのデフォルトトラックバッファサイズ
	move.l	#ID_TEMP,d3
	jsr	get_mem-work(a6)
	tst.l	d0
	bmi	m_out_of_memory
	move.l	a2,a5
	move.l	d5,(a2)+		*trk number
	move.l	a0,(a2)+		*addr
	move.l	d2,(a2)+		*size
	clr.l	(a2)+			*ptr
	move.l	d6,(a2)+		*tpt_trkvol,tpt_trkfrq
	bsr	init_compile_work
	movem.l	(sp)+,reglist
	rts

init_compile_work:			*コンパイルワークの初期化
	* < a5.l=trk N compile work addr
	* - all
reglist	reg	d0-d1/a1
	movem.l	reglist,-(sp)
	moveq.l	#0,d0
	move.l	d0,tpt_mode_flg(a5)
	move.l	d0,tpt_key_sig+0(a5)	*tpt_key_sig+0,1,2,3
	move.l	d0,tpt_key_sig+4(a5)	*tpt_key_sig+4,5,6,dummy
	move.l	d0,tpt_velo_n(a5)	*tpt_velo_n,tpt_n_of_velo
	move.l	d0,tpt_velo_n_chd(a5)	*tpt_velo_n_chd,tpt_n_of_velo_chd
	move.l	d0,tpt_chord_dly(a5)	*tpt_chord_dly,tpt_echo_dly
	move.l	d0,tpt_rept_max(a5)
	move.l	d0,tpt_sgcd_max(a5)
	move.l	d0,tpt_fgmap_max(a5)
	move.l	d0,tpt_rept_addr(a5)
	move.l	d0,tpt_sgcd_addr(a5)
	move.l	d0,tpt_fgmap_addr(a5)
	move.l	d0,tpt_renp_addr(a5)
	move.l	d0,tpt_port_dly(a5)	*tpt_port_dly,tpt_port_hold
	move.l	#$00_00_00_ff,tpt_echo_loop(a5)	*tpt_echo_loop,tpt_echo_switch,tpt_echo_vdec
	move.l	#-1,tpt_note_buf(a5)

	move.l	zmd_addr-work(a6),a1
	move.w	z_master_clock(a1),d0
	bne	@f
	move.w	#192,d0
	move.w	d0,z_master_clock(a1)
@@:
	lsr.w	#2,d0
	move.w	d0,tpt_note_len(a5)		*Lコマンドのデフォルト値
	move.b	gate_range-work(a6),d0
	move.w	d0,tpt_gate_time(a5)		*Qコマンドのデフォルト値
	move.l	#$05_7f_01_01,tpt_octave(a5)	*tpt_octave,tpt_last_velo,
						*tpt_rltv_velo,tpt_rltv_vol
	move.l	#$80808080,d0			*ベロシティシーケンス初期化
	moveq.l	#(velo_max/4)-1,d1
	lea	tpt_velo(a5),a1
@@:
	move.l	d0,(a1)+
	dbra	d1,@b

	lea	tpt_velo_chd(a5),a1		*和音ベロシティシーケンス初期化
	moveq.l	#16/4-1,d1
@@:
	move.l	d0,(a1)+
	dbra	d1,@b
	bsr	init_tptnttbl
	movem.l	(sp)+,reglist
	rts

get_str_ch:				*文字でチャンネルアサイン
	* < (a4)=str addr.
	* > (a4)=next
	* > d2.l=typ,ch value
	* > d0.l=err result(z:no err)
	* x d1
	moveq.l	#0,d1
	bsr	skip_spc
	cmp.l	a4,d4
	bls	exit_err_gsc0	*m_assign error
	move.b	(a4)+,d0
	jsr	mk_capital-work(a6)
	cmpi.b	#'F',d0
	beq	gsc_case_fm
	cmpi.b	#'A',d0
	beq	gsc_case_ad
	cmpi.b	#'P',d0
	bne	gsc_case_md
gsc_case_ad:			*ADPCM
	bsr	srch_num
	bmi	@f
	bsr	get_num
	subq.l	#1,d1
	cmpi.l	#15,d1
	bhi	exit_err_gsc1
	bra	gsc00
@@:				*チャンネル番号省略ケース
	move.b	adpcm_default_ch-work(a6),d1
	addq.b	#1,adpcm_default_ch-work(a6)
gsc00:
	moveq.l	#1,d2
	swap	d2
	move.w	d1,d2
	moveq.l	#0,d0		*no err
	rts
gsc_case_fm:			*FM
	bsr	srch_num
	bmi	exit_err_gsc1	*illegal ch
	bsr	get_num
	subq.l	#1,d1
	cmpi.l	#7,d1
	bhi	exit_err_gsc1
	move.l	d1,d2
	moveq.l	#0,d0		*no err
	rts
gsc_case_md:
	move.l	#-1,d2		*default type(-1 means current)
	cmpi.b	#'M',d0
	bne	exit_err_gsc2	*?? device error
	bsr	srch_num
	bmi	exit_err_gsc1	*illegal ch
	bsr	get_num
	bsr	skip_spc
	cmp.l	a4,d4
	bls	exit_err_gsc0	*m_assign error
	move.b	(a4),d0		*前のパラメータがインターフェース番号で
	cmpi.b	#':',d0		*今度の数値がチャンネル番号?
	beq	@f
	cmpi.b	#'-',d0
	bne	mdch_chk_gsc
@@:				*get ch num
	addq.w	#1,a4
	bsr	chk_num
	bmi	exit_err_gsc1
	move.l	d1,d2		*save I/F to d2
	bsr	get_num		*get ch no.(有効範囲は後でチェック
	subq.l	#1,d2
	cmpi.l	#if_max-1,d2
	bhi	exit_err_gsc2	*illegal_interface_number
	ori.w	#$8000,d2
	swap	d2
mdch_chk_gsc:
	subq.l	#1,d1
	cmpi.l	#15,d1
	bhi	exit_err_gsc1	*illegal ch
	move.w	d1,d2
	moveq.l	#0,d0
	rts
exit_err_gsc0:			*m_assign error
	move.l	#ZM_COMPILER*65536+ASSIGN_COMMAND_ERROR,d0
	rts
exit_err_gsc1:			*illegal ch
	move.l	#ZM_COMPILER*65536+ILLEGAL_CHANNEL,d0
	rts
exit_err_gsc2:			*illegal interface number
	move.l	#ZM_COMPILER*65536+ILLEGAL_INTERFACE_NUMBER,d0
	rts

srch_num:			*数字までスキップ
	* X d0
	move.w	d0,-(sp)
srch_num_lp:
	cmp.l	a4,d4
	bls	@f		*コマンドの途中でファイルの最後に来た
	move.b	(a4)+,d0
*	tst.b	now_cmd-work(a6)
*	bpl	@f
	cmpi.b	#'{',d0
	beq	sn_err		*コマンドの途中で改行
	cmpi.b	#'}',d0
	beq	sn_err
*	bra	snchk_cmma
*@@:
	cmpi.b	#'(',d0
	beq	sn_err
	cmpi.b	#')',d0
	beq	sn_err
snchk_cmma:
	cmpi.b	#',',d0
	beq	sn_err
	cmpi.b	#'$',d0
	beq	its_num
	cmpi.b	#'%',d0
	beq	its_num
	cmpi.b	#'0',d0
	bcs	srch_num_lp
	cmpi.b	#'9',d0
	bhi	srch_num_lp
its_num:
	subq.w	#1,a4
	move.w	(sp)+,d0
	move.w	#CCR_ZERO,ccr
	rts
sn_err:
	subq.w	#1,a4
@@:
	move.w	(sp)+,d0
	move.w	#CCR_NEGA,ccr
	rts

t_bsch:				*ベースチャンネル切り換え
	tst.b	assign_done-work(a6)
	bne	m_illegal_command_order		*コマンドの順番がまずい
*	jsr	check_relation_cmn-work(a6)	*コマンド関係チェック
	moveq.l	#0,d1
	bsr	chk_num		*(b)だけの時はFM基準
	bmi	@f
	bsr	get_num
@@:
	lea	real_ch_tbl-work(a6),a1
	tst.l	d1
	beq	fmbs_mode	*FMチャンネルベースモード
				*MIDIチャンネルベースモード
	move.l	#$8000_0000,d0
	moveq.l	#16-1,d1
@@:
	move.l	d0,(a1)+
	addq.w	#1,d0
	dbra	d1,@b

	moveq.l	#0,d0
	moveq.l	#8-1,d1
@@:
	move.l	d0,(a1)+
	addq.w	#1,d0
	dbra	d1,@b

	move.l	#$0001_0000,d0
	moveq.l	#8-1,d1
@@:
	move.l	d0,(a1)+
	addq.w	#1,d0
	dbra	d1,@b
	bra	find_end
fmbs_mode:
	moveq.l	#0,d0
	moveq.l	#8-1,d1
@@:
	move.l	d0,(a1)+
	addq.w	#1,d0
	dbra	d1,@b

	move.l	#$0001_0000,(a1)+	*ADPCM1

	move.l	#$8000_0000,d0
	moveq.l	#16-1,d1
@@:
	move.l	d0,(a1)+
	addq.w	#1,d0
	dbra	d1,@b

	move.l	#$0001_0001,d0		*ADPCM2-8
	moveq.l	#7-1,d1
@@:
	move.l	d0,(a1)+
	addq.w	#1,d0
	dbra	d1,@b
	bra	find_end

continue:					*.CONTINUE
*	jsr	check_relation_cmn-work(a6)	*コマンド関係チェック
	moveq.l	#0,d3
	bsr	chk_num
	bpl	@f
	bsr	skip_eq
	cmp.l	a4,d4
	bls	@f
	cmpi.b	#'{',(a4)
	bne	@f
	moveq.l	#-1,d3
	addq.w	#1,a4			*skip '{'
	bra	@f
t_cont:					*演奏継続(C)
*	jsr	check_relation_cmn-work(a6)	*コマンド関係チェック
	moveq.l	#-1,d3
@@:
	moveq.l	#CTRL_CONT,d0	*コマンドコード
	bsr	getset_trk_seq	*トラックパラメータをセット
	move.l	zmd_addr-work(a6),a1
	move.l	z_ctrl_flag(a1),d0
	bset.l	#CTRL_CONT/4,d0
	move.l	d0,z_ctrl_flag(a1)
	tst.b	d3
	bne	find_end
	bra	cmpl_lp

curb_jump:					*.JUMP
	tst.b	assign_done-work(a6)
	bne	m_illegal_command_order		*コマンドの順番がまずい
*	jsr	check_relation_cmn-work(a6)	*コマンド関係チェック
	bsr	skip_eq
	moveq.l	#0,d3
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	cmp.l	#'{',(a4)
	bne	@f
	moveq.l	#-1,d3
	addq.w	#1,a4			*skip '{'
@@:
	lea	en_ds_tbl-work(a6),a1
	bsr	get_com_no
	bmi	m_undefined_mode
	move.b	d0,jump_cmd_ctrl-work(a6)
	tst.b	d3
	bne	find_end
	bra	cmpl_lp

t_jump:						*[!]コマンドの有効／無効化スイッチ
	tst.b	assign_done-work(a6)
	bne	m_illegal_command_order		*コマンドの順番がまずい
*	jsr	check_relation_cmn-work(a6)	*コマンド関係チェック
	bsr	chk_num
	bpl	@f
	not.b	jump_cmd_ctrl-work(a6)
	bra	find_end
@@:
	bsr	get_num
	tst.l	d1
	sne	jump_cmd_ctrl-work(a6)
	bra	find_end

play:						*.PLAY
*	jsr	check_relation_cmn-work(a6)	*コマンド関係チェック
	moveq.l	#0,d3
	bsr	chk_num
	bpl	@f
	bsr	skip_eq
	cmp.l	a4,d4				*.playだけの時は無視する
	bls	cmpl_lp
	cmpi.b	#'{',(a4)
	bne	@f
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_illegal_command_line
	cmpi.b	#'}',(a4)
	beq	find_end			*(p)だけの時は無視する
	moveq.l	#-1,d3
	addq.w	#1,a4				*skip '{'
	bra	@f
t_play:						*演奏開始(P)
*	jsr	check_relation_cmn-work(a6)	*コマンド関係チェック
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_illegal_command_line
	cmpi.b	#')',(a4)
	beq	find_end			*(p)だけの時は無視する
	moveq.l	#-1,d3
@@:
	moveq.l	#CTRL_PLAY,d0	*コマンドコード
	bsr	getset_trk_seq	*トラックパラメータをセット
	move.l	zmd_addr-work(a6),a1
	move.l	z_ctrl_flag(a1),d0
	bset.l	#CTRL_PLAY/4,d0
	move.l	d0,z_ctrl_flag(a1)
	tst.b	d3
	bne	find_end
	bra	cmpl_lp

stop:						*.STOP
*	jsr	check_relation_cmn-work(a6)	*コマンド関係チェック
	moveq.l	#0,d3
	bsr	chk_num
	bpl	@f
	bsr	skip_eq
	cmpi.b	#'{',(a4)
	bne	@f
	moveq.l	#-1,d3
	addq.w	#1,a4			*skip '{'
	bra	@f
t_stop:					*演奏停止(C)
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#-1,d3
@@:
	moveq.l	#CTRL_STOP,d0		*コマンドコード
	bsr	getset_trk_seq		*トラックパラメータをセット
	move.l	zmd_addr-work(a6),a1
	move.l	z_ctrl_flag(a1),d0
	bset.l	#CTRL_STOP/4,d0
	move.l	d0,z_ctrl_flag(a1)
	tst.b	d3
	bne	find_end
	bra	cmpl_lp

getset_trk_seq:					*トラック番号をパラメータにしている制御コマンドの書き込み
	* < d0.w=ctrl command code
	* x d0,d1,d2
	jsr	do_wrt_ctrl_w-work(a6)		*write cmd code
gtslp00:
	cmp.l	a4,d4
	bls	exit_gts
	bsr	chk_num
	bmi	exit_gts
	bsr	get_num
	move.l	d1,d2
	subq.l	#1,d2
	cmpi.l	#tr_max-1,d2
	bhi	m_illegal_track_number		*illegal track number
	move.l	d2,d1
	bsr	chk_num
	bmi	gtslp01
	bsr	get_num
	neg.l	d1
	bmi	m_illegal_track_number		*illegal track number
	subq.l	#1,d1
	cmpi.l	#tr_max-1,d1
	bhi	m_illegal_track_number		*illegal track number
gtslp01:
	movem.l	d1-d2,-(sp)
	move.l	d2,d1
	jsr	check_trk_no-work(a6)
	move.l	d1,d0
	jsr	reg_trkn_ctrl-work(a6)
	jsr	do_wrt_ctrl_w-work(a6)
	movem.l	(sp)+,d1-d2
	cmp.l	d1,d2
	beq	1f
	bhi	@f
	addq.l	#1,d2
	bra	gtslp01
@@:
	subq.l	#1,d2
	bra	gtslp01
1:
	bsr	skip_sep
	bra	gtslp00
exit_gts:
	moveq.l	#-1,d0				*end code
	jmp	do_wrt_ctrl_w-work(a6)

t_mfader:				*(Fn)(マスターフェーダー)
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CTRL_MFADER,d0		*コマンドコード
	jsr	do_wrt_ctrl_w-work(a6)
	moveq.l	#-1,d0			*ALL DEVICES TO BE CONTROLLED
	jsr	do_wrt_ctrl_w-work(a6)
	moveq.l	#-1,d3			*goto find end mark
	bsr	chk_num
	bmi	mfade_all
	bsr	get_num
	move.l	#$0000_0080,d2		*start.h,end.l
	tst.l	d1			*check speed
	bne	@f
	move.l	#$0080_0080,d2		*解除ケース
	bra	setmfdrspd
@@:
	bpl	@f
	neg.l	d1
	swap	d2
@@:
	cmpi.l	#fader_spd_max,d1
	bhi	m_illegal_speed_value
setmfdrspd:
	moveq.l	#%0000_0111,d0
	jsr	do_wrt_ctrl_b-work(a6)	*omt
	move.l	d1,d0
	jsr	do_wrt_ctrl_w-work(a6)	*speed
	move.w	d2,d0
	jsr	do_wrt_ctrl_b-work(a6)	*start level
	swap	d2
	move.w	d2,d0
	jsr	do_wrt_ctrl_b-work(a6)	*end level
	bra	exit_mstrfdr

master_fader:				*.MASTER_FADER
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#0,d3			*end mark flag
	bsr	skip_eq
	cmp.l	a4,d4
	bls	mfade_all
	cmpi.b	#'{',(a4)
	bne	@f
	moveq.l	#-1,d3			*end mark flag
	addq.w	#1,a4			*skip '{'
@@:
	bsr	skip_spc
	tst.l	d3
	beq	@f
	cmp.l	a4,d4
	bls	m_illegal_command_line
	cmpi.b	#'}',(a4)
	beq	mfade_all
@@:
	cmp.l	a4,d4
	bls	mfade_all
mstfdrlp:
	bsr	skip_spc
	lea	mstrfadr_dev-work(a6),a1	*デバイス名テーブル
	bsr	get_com_no			*> d0
	bmi	exit_mstrfdr
	subq.l	#1,d0
	bcs	setmstrfdrdev
	add.w	d0,d0
	move.w	mstrfdrdvid(pc,d0.w),d0
setmstrfdrdev:
	move.w	d0,d2
	moveq.l	#CTRL_MFADER,d0		*コマンドコード
	jsr	do_wrt_ctrl_w-work(a6)
	move.w	d2,d0
	jsr	do_wrt_ctrl_w-work(a6)
	bsr	get_spd_str_end			*スピード/スタートレベル/エンドレベル取得
	bra	mstfdrlp
exit_mstrfdr:
	move.l	zmd_addr-work(a6),a1
	move.l	z_ctrl_flag(a1),d0
	bset.l	#CTRL_MFADER/4,d0
	move.l	d0,z_ctrl_flag(a1)
	tst.b	d3
	bne	find_end
	bra	cmpl_lp

mstrfdrdvid:
	dc.w	0	*FM
	dc.w	1	*ADPCM
	dc.w	$8000	*MIDI1
	dc.w	$8001	*MIDI2
	dc.w	$8002	*MIDI3

mfade_all:				*全パラメータ省略で全デバイス操作対象モード
					*(全パラメータデフォルト値でフェードアウト)
	moveq.l	#CTRL_MFADER,d0		*コマンドコード
	jsr	do_wrt_ctrl_w-work(a6)
	moveq.l	#-1,d0			*'all' mark
	jsr	do_wrt_ctrl_w-work(a6)
	moveq.l	#%0000_0111,d0		*omt
	jsr	do_wrt_ctrl_b-work(a6)
	moveq.l	#fader_dflt_spd,d0	*speed
	jsr	do_wrt_ctrl_w-work(a6)
	moveq.l	#128,d0			*start level
	bsr	do_wrt_ctrl_b
	moveq.l	#0,d0			*end level
	bsr	do_wrt_ctrl_b
	bra	exit_mstrfdr

get_spd_str_end:
	* x d0
reglist	reg	d1-d3/d5
	movem.l	reglist,-(sp)
	moveq.l	#0,d2				*omt
	bsr	skip_sep
						*get speed
	moveq.l	#fader_dflt_spd,d1		*default speed
	bsr	chk_num
	bmi	@f
	bsr	get_num
	cmpi.l	#fader_spd_max,d1
	bhi	m_illegal_speed_value
	bset.l	#0,d2
@@:
	move.l	d1,d3			*d3.l=speed

	bsr	skip_sep
					*get start level
	bsr	chk_num
	bmi	@f
	bsr	get_num
	cmpi.l	#128,d1
	bhi	m_illegal_fader_level
	bset.l	#1,d2
@@:
	move.l	d1,d5

	bsr	skip_sep
					*get end level
	bsr	chk_num
	bmi	@f
	bsr	get_num
	cmpi.l	#128,d1
	bhi	m_illegal_fader_level
	bset.l	#2,d2
@@:
	move.l	d2,d0
	jsr	do_wrt_ctrl_b-work(a6)	*omt
	lsr.b	#1,d2
	bcc	@f
	move.l	d3,d0
	jsr	do_wrt_ctrl_w-work(a6)	*speed
@@:
	lsr.b	#1,d2
	bcc	@f
	move.l	d5,d0
	jsr	do_wrt_ctrl_b-work(a6)	*start level
@@:
	lsr.b	#1,d2
	bcc	@f
	move.l	d1,d0			*end level
	jsr	do_wrt_ctrl_b-work(a6)
@@:
	bsr	skip_sep
	movem.l	(sp)+,reglist
	rts

track_fader:				*.TRACK_FADER
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#0,d3
	bsr	skip_eq
	cmp.l	a4,d4
	bls	tfade_all
	cmpi.b	#'{',(a4)
	bne	@f
	moveq.l	#-1,d3
	addq.w	#1,a4			*skip '{'
@@:
	bsr	skip_spc
	tst.l	d3
	beq	@f
	cmp.l	a4,d4
	bls	m_illegal_command_line
	cmpi.b	#'}',(a4)
	beq	tfade_all
@@:
	cmp.l	a4,d4
	bls	tfade_all
trkfdrlp:
	bsr	chk_num
	bpl	@f
	lea	trkfadr_dev-work(a6),a1
	bsr	get_com_no		*> d0
	bmi	exit_trkfdr
	moveq.l	#-1,d1			*全トラック指定
 	bra	settrkfdrtrk
@@:
	bsr	get_num
	subq.l	#1,d1
	cmpi.l	#tr_max-1,d1
	bhi	m_illegal_track_number
	jsr	check_trk_no-work(a6)
settrkfdrtrk:
	moveq.l	#CTRL_TFADER,d0		*コマンドコード
	bsr	do_wrt_ctrl_w
	move.l	d1,d0
	jsr	reg_trkn_ctrl-work(a6)
	bsr	do_wrt_ctrl_w		*track number
	bsr	get_spd_str_end
	bra	trkfdrlp
exit_trkfdr:
	move.l	zmd_addr-work(a6),a1
	move.l	z_ctrl_flag(a1),d0
	bset.l	#CTRL_TFADER/4,d0
	move.l	d0,z_ctrl_flag(a1)
	tst.b	d3
	bne	find_end
	bra	cmpl_lp

tfade_all:				*全パラメータ省略で全トラック操作対象モード
					*(全トラックデフォルト値でフェードアウト)
	moveq.l	#CTRL_TFADER,d0		*コマンドコード
	bsr	do_wrt_ctrl_w
	moveq.l	#-1,d0			*'all' mark
	bsr	do_wrt_ctrl_w
	moveq.l	#%0000_0111,d0		*omt
	jbsr	do_wrt_ctrl_b-work(a6)
	moveq.l	#fader_dflt_spd,d0	*speed
	bsr	do_wrt_ctrl_w
	moveq.l	#128,d0			*start level
	bsr	do_wrt_ctrl_b
	moveq.l	#0,d0			*end level
	bsr	do_wrt_ctrl_b
	bra	exit_trkfdr

check_ctrl_trk:			*指定されたトラックパラメータがダブっていないかチェック
	* < d1.w=track number
	* < d0.l=比較対象が何バイト後に再び出現するか
	* < a1.l=trackパラメータが格納されている先頭オフセットアドレス
	* x d0
	movem.l	d2-d3/a1,-(sp)
	move.l	ctrl_now-work(a6),d2
	cmp.l	d2,a1
	beq	exit_chkctrltrk
	move.l	ctrl_addr-work(a6),d0
	add.l	d0,d2		*limit address
	add.l	d0,a1		*scanning start address
@@:
	move.w	(a1)+,d3
	add.w	d0,a1		*next
	cmpi.w	#-1,d3
	beq	m_track_number_redesignation	*全トラック指定がすでになされていればエラー
	cmp.w	d0,d1
	beq	m_track_number_redesignation	*重複指定されている
	cmp.l	a1,d2
	bhi	@b
exit_chkctrltrk:
	movem.l	(sp)+,d2-d3/a1
	rts

track_mask:				*.TRACK_MASK
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CTRL_MASK,d0		*コマンドコード
	bsr	do_wrt_ctrl_w
	moveq.l	#0,d3
	bsr	skip_eq
	cmp.l	a4,d4
	bls	maskoff_all
	cmpi.b	#'{',(a4)
	bne	@f
	moveq.l	#-1,d3
	addq.w	#1,a4			*skip '{'
@@:
	moveq.l	#0,d2			*指定されたデバイスのマーカー
trkmsklp:
	bsr	chk_num
	bpl	@f
	lea	msktrk_dev-work(a6),a1
	bsr	get_com_no		*> d0
	bmi	exit_trkmsklp
	moveq.l	#-1,d1			*全トラック指定
 	bra	setmsktrktrk
@@:
	bsr	get_num
	subq.l	#1,d1
	cmpi.l	#tr_max-1,d1
	bhi	m_illegal_track_number
	jsr	check_trk_no-work(a6)
setmsktrktrk:
	moveq.l	#2,d0			*skip interval
	bsr	check_ctrl_trk		*ダブりチェック
	move.l	d1,d0
	jsr	reg_trkn_ctrl-work(a6)
	bsr	do_wrt_ctrl_w		*get track number

	bsr	skip_sep

	bsr	chk_num
	bpl	@f
	lea	msktrk_mode-work(a6),a1	*モード
	bsr	get_com_no		*> d0
	bmi	m_illegal_mode_value	*モード値が規定外
	move.l	d0,d1
	subq.w	#1,d1			*0-2 → -1,0,+1
 	bra	setmsktrkmode
@@:
	bsr	get_num
	cmpi.l	#-1,d1
	blt	m_illegal_mode_value	*モード値が規定外
	cmpi.l	#1,d1
	bgt	m_illegal_mode_value	*モード値が規定外
setmsktrkmode:
	move.l	d1,d0
	bsr	do_wrt_ctrl_w		*mode(-1,0,+1)

	bsr	skip_sep

	moveq.l	#-1,d2			*正常に設定されたトラックが１つ以上はあるMARK
	bra	trkmsklp

exit_trkmsklp:
	tst.l	d2			*トラックが一つでも選択されたか
	beq	maskoff_all
	moveq.l	#-1,d0
	bsr	do_wrt_ctrl_w		*end code
exit_trkmsk:
	move.l	zmd_addr-work(a6),a1
	move.l	z_ctrl_flag(a1),d0
	bset.l	#CTRL_MASK/4,d0
	move.l	d0,z_ctrl_flag(a1)
	tst.b	d3
	bne	find_end
	bra	cmpl_lp

maskoff_all:				*全パラメータ省略で全トラック操作対象モード
					*(全トラックマスク解除)
	moveq.l	#-1,d0			*'all' mark
	bsr	do_wrt_ctrl_w
	moveq.l	#0,d0			*enable
	bsr	do_wrt_ctrl_w
	bra	exit_trkmsk

relative_velocity:			*.RELATIVE_VELOCITY
*	bsr	check_relation_cmn	*コマンド関係チェック
	bsr	skip_eq
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	moveq.l	#0,d3
	cmpi.b	#'{',(a4)
	bne	@f
	addq.w	#1,a4
	moveq.l	#-1,d3
@@:
	lea	rltvvlcty_tbl-work(a6),a1
	bsr	get_com_no
	bmi	m_undefined_mode
	cmpi.w	#1,d0
	sls	velo_vol_ctrl-work(a6)
	tst.b	d3
	bne	find_end
	bra	cmpl_lp

t_velovol:				*相対ベロシティの記号エクスチェンジ
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#0,d1
	bsr	chk_num			*(u)だけの時は_が相対音量
	bmi	@f
	bsr	get_num
@@:
	tst.l	d1
	sne	velo_vol_ctrl-work(a6)
	bra	find_end

list:					*.LIST
	clr.b	list_mode-work(a6)
	bra	cmpl_lp

nlist:
	st.b	list_mode-work(a6)
	bra	cmpl_lp

master_clock_cmd:			*.MASTER_CLOCK
	tst.b	assign_done-work(a6)
	bne	m_illegal_command_order	*コマンドの順番がまずい
*	bsr	check_relation_cmn	*コマンド関係チェック
	bsr	chk_num
	bpl	@f
	bsr	skip_eq
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	cmpi.b	#'{',(a4)+
	seq	d2
	bne	m_parameter_cannot_be_omitted
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
@@:
	moveq.l	#0,d2
	bsr	get_num
	cmpi.l	#max_note_len,d1
	bhi	m_illegal_master_clock
	bra	@f

t_set_mclk:				*(Zn)全音符の絶対音長設定
	moveq.l	#1,d2			*終端カッコチェックの有無フラグ(1:checkあり)
	tst.b	assign_done-work(a6)
	bne	m_illegal_command_order	*コマンドの順番がまずい
*	bsr	check_relation_cmn	*コマンド関係チェック
	move.w	#192,d1
	bsr	chk_num			*(Z)だけの時は192
	bmi	@f
	bsr	get_num
@@:
	move.l	zmd_addr-work(a6),a1
	move.w	d1,z_master_clock(a1)	*情報ブロックにも書き込む
	tst.b	d2
	bne	find_end
	bra	cmpl_lp

meter:					*.METER
*	bsr	check_relation_cmn	*コマンド関係チェック
	bsr	chk_num
	bpl	@f
	bsr	skip_eq
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	cmpi.b	#'{',(a4)+
	seq	d2
	bne	m_parameter_cannot_be_omitted
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
@@:
	bsr	get_num
	cmpi.l	#255,d1
	bhi	m_illegal_meter
	move.l	d1,d3
	beq	m_illegal_meter
	bsr	skip_spc3
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	cmpi.b	#'/',(a4)
	bne	@f
	addq.w	#1,a4			*skip '/'
@@:
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
	bsr	get_num
	cmpi.l	#255,d1
	bhi	m_illegal_meter
	lsl.w	#8,d3
	move.b	d1,d3
	beq	m_illegal_meter
	move.l	zmd_addr-work(a6),a1
	move.w	d3,z_meter(a1)		*情報ブロックにも書き込む
	tst.b	d2
	bne	find_end
	bra	cmpl_lp

mml_meter:				*[METER]
*	bsr	check_relation_cmn	*コマンド関係チェック
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
	bsr	get_num
	cmpi.l	#255,d1
	bhi	m_illegal_meter
	move.l	d1,d3
	beq	m_illegal_meter
	bsr	skip_spc3
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	cmpi.b	#'/',(a4)
	bne	@f
	addq.w	#1,a4			*skip '/'
@@:
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
	bsr	get_num
	cmpi.l	#255,d1
	bhi	m_illegal_meter
	lsl.w	#8,d3
	move.b	d1,d3
	beq	m_illegal_meter
	moveq.l	#seq_cmd_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#METER_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#2,d0
	bsr	do_wrt_trk_b
	move.l	d3,d0
	bra	do_wrt_trk_w

performance_time:				*.PERFORMANCE_TIME
*	bsr	check_relation_cmn		*コマンド関係チェック
	moveq.l	#0,d2
	bsr	chk_num
	bpl	@f
	bsr	skip_eq
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	cmpi.b	#'{',(a4)+
	seq	d2
	bne	m_parameter_cannot_be_omitted
	bsr	chk_num			*get hour
	bmi	m_parameter_cannot_be_omitted
@@:
	bsr	get_num
	cmpi.l	#65535,d1
	bhi	m_illegal_time_value
	move.l	d1,d3
	bsr	skip_eq
	bsr	chk_num			*get minute
	bmi	m_parameter_cannot_be_omitted
	bsr	get_num
	cmpi.l	#59,d1
	bhi	m_illegal_time_value
	lsl.l	#8,d3
	move.b	d1,d3
	bsr	skip_eq
	bsr	chk_num			*get second
	bmi	m_parameter_cannot_be_omitted
	bsr	get_num
	cmpi.l	#59,d1
	bhi	m_illegal_time_value
	lsl.l	#8,d3
	move.b	d1,d3
	move.l	zmd_addr-work(a6),a1
	move.l	d3,z_play_time(a1)		*情報ブロックに書き込む
	tst.b	d2
	bne	find_end
	bra	cmpl_lp

t_vset:					*音色セット(v)
*	bsr	check_relation_cmn	*コマンド関係チェック
	bsr	init_fmsndnm
	moveq.l	#CMN_VSET,d0
	bsr	do_wrt_cmn_b
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted	*数字がないのでエラー
	bsr	get_num
	cmpi.l	#fmsnd_reg_max,d1
	bhi	m_illegal_timbre_number
	subq.l	#1,d1
	bcs	m_illegal_timbre_number
	move.l	d1,d0			*timbre number
	bsr	do_wrt_cmn_w
	bsr	skip_sep
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
	bsr	get_num			*get v offset(dummy)
	moveq.l	#0,d0			*dummy
	bsr	do_wrt_cmn_b
	lea	std_55-work(a6),a1
	bsr	get_timbre_55_params
	lea	v_buffer-work(a6),a1
	move.b	$04(a1),d0	*0)LFRQ
	bsr	do_wrt_cmn_b

	move.b	$05(a1),d0	*1)PMD
	tas.b	d0
	bsr	do_wrt_cmn_b
	move.b	$06(a1),d0	*2)AMD
	bsr	do_wrt_cmn_b
				*3)SYNC/OM/WF
	move.b	$01(a1),d0	*OM
	lsl.b	#3,d0
	tst.b	$03(a1)		*SYNC
	beq	@f
	tas.b	d0
@@:
	or.b	$02(a1),d0	*WF
	bsr	do_wrt_cmn_b

	move.b	$09(a1),d0	*PAN
	ror.b	#2,d0
	or.b	(a1),d0		*AF
	bsr	do_wrt_cmn_b	*4)PAN/AF

	move.b	$07(a1),d0	*PMS
	lsl.b	#4,d0
	or.b	$08(a1),d0	*AMS
	bsr	do_wrt_cmn_b	*5)
op_param:
************************************************
	move.b	$13(a1),d0
	lsl.b	#4,d0
	or.b	$12(a1),d0
	bsr	do_wrt_cmn_b	*6)OP1:DT1/MUL

	move.b	$29(a1),d0
	lsl.b	#4,d0
	or.b	$28(a1),d0
	bsr	do_wrt_cmn_b	*7)OP3:DT1/MUL

	move.b	$1e(a1),d0
	lsl.b	#4,d0
	or.b	$1d(a1),d0
	bsr	do_wrt_cmn_b	*8)OP2:DT1/MUL

	move.b	$34(a1),d0
	lsl.b	#4,d0
	or.b	$33(a1),d0
	bsr	do_wrt_cmn_b	*9)OP4:DT1/MUL
************************************************
	move.b	$10(a1),d0	*10)OP1:TL
	bsr	do_wrt_cmn_b

	move.b	$26(a1),d0	*11)OP3:TL
	bsr	do_wrt_cmn_b

	move.b	$1b(a1),d0	*12)OP2:TL
	bsr	do_wrt_cmn_b

	move.b	$31(a1),d0	*13)OP4:TL
	bsr	do_wrt_cmn_b

	move.b	$11(a1),d0
	ror.b	#2,d0
	or.b	$0b(a1),d0
	bsr	do_wrt_cmn_b	*14)OP1:KS/AR

	move.b	$27(a1),d0
	ror.b	#2,d0
	or.b	$21(a1),d0
	bsr	do_wrt_cmn_b	*15)OP3:KS/AR

	move.b	$1c(a1),d0
	ror.b	#2,d0
	or.b	$16(a1),d0
	bsr	do_wrt_cmn_b	*16)OP2:KS/AR

	move.b	$32(a1),d0
	ror.b	#2,d0
	or.b	$2c(a1),d0
	bsr	do_wrt_cmn_b	*17)OP4:KS/AR
************************************************
	move.b	$15(a1),d0
	ror.b	#1,d0
	or.b	$0c(a1),d0
	bsr	do_wrt_cmn_b	*18)OP1:AME/1DR

	move.b	$2b(a1),d0
	ror.b	#1,d0
	or.b	$22(a1),d0
	bsr	do_wrt_cmn_b	*19)OP3:AME/1DR

	move.b	$20(a1),d0
	ror.b	#1,d0
	or.b	$17(a1),d0
	bsr	do_wrt_cmn_b	*20)OP2:AME/1DR

	move.b	$36(a1),d0
	ror.b	#1,d0
	or.b	$2d(a1),d0
	bsr	do_wrt_cmn_b	*21)OP4:AME/1DR
************************************************
	move.b	$14(a1),d0
	ror.b	#2,d0
	or.b	$0d(a1),d0
	bsr	do_wrt_cmn_b	*22)OP1:DT2/2DR

	move.b	$2a(a1),d0
	ror.b	#2,d0
	or.b	$23(a1),d0
	bsr	do_wrt_cmn_b	*23)OP3:DT2/2DR

	move.b	$1f(a1),d0
	ror.b	#2,d0
	or.b	$18(a1),d0
	bsr	do_wrt_cmn_b	*24)OP2:DT2/2DR

	move.b	$35(a1),d0
	ror.b	#2,d0
	or.b	$2e(a1),d0
	bsr	do_wrt_cmn_b	*25)OP4:DT2/2DR
************************************************
	move.b	$0f(a1),d0
	lsl.b	#4,d0
	or.b	$0e(a1),d0
	bsr	do_wrt_cmn_b	*26)OP1:D1L/RR

	move.b	$25(a1),d0
	lsl.b	#4,d0
	or.b	$24(a1),d0
	bsr	do_wrt_cmn_b	*27)OP3:D1L/RR

	move.b	$1a(a1),d0
	lsl.b	#4,d0
	or.b	$19(a1),d0
	bsr	do_wrt_cmn_b	*28)OP2:D1L/RR

	move.b	$30(a1),d0
	lsl.b	#4,d0
	or.b	$2f(a1),d0
	bsr	do_wrt_cmn_b	*29)OP4:D1L/RR
************************************************
tt:
	move.l	temp_buffer-work(a6),a1
	moveq.l	#16-1,d1	*音色名の最大長
@@:				*音色名転送
	move.b	(a1)+,d0
	bsr	do_wrt_cmn_b
	dbeq	d1,@b
	move.l	zmd_addr-work(a6),a1
	move.l	z_cmn_flag(a1),d0
	bset.l	#CMN_VSET/4,d0
	move.l	d0,z_cmn_flag(a1)
	bra	find_end

fm_vset:					*.FM_VSET
*	bsr	check_relation_cmn	*コマンド関係チェック
	bsr	init_fmsndnm
	moveq.l	#CMN_VSET,d0
	bsr	do_wrt_cmn_b
	bsr	get_pgm_number		*> d1.w=timbre number
	move.l	d1,-(sp)
	moveq.l	#'{',d1
	bsr	get_timbre_name
	bsr	skip_eq
	cmp.l	a4,d4
	bls	m_timbre_parameter_shortage
	move.l	(sp)+,d1
	cmpi.b	#'{',(a4)
	bne	tvst00
	addq.w	#1,a4
	bra	tvst00

get_pgm_number:					*音色番号取得(FM音源のみ対応のサブルーチン)
	* > d1.w=timbre number(0-????)
	* x d2
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted	*音色番号の省略はできない
	bsr	get_num				*get 1st number
	bsr	skip_spc
	cmp.l	a4,d4
	bls	2f				*case:@n
	move.b	(a4),d0
	cmpi.b	#':',d0
	beq	@f
	cmp.b	#',',d0
	bne	2f
@@:
	addq.w	#1,a4				*skip ,
	bsr	chk_num
	bmi	2f				*m_illegal_command_line
	cmpi.l	#16383,d1
	bhi	m_illegal_bank_number
	move.l	d1,d2
	bsr	get_num				*get 2nd number
	bsr	skip_spc
	cmp.l	a4,d4
	bls	1f				*case:@b,n
	cmpi.b	#',',(a4)
	bne	1f
	cmpi.l	#127,d1
	bhi	m_illegal_bank_number
	cmpi.l	#127,d2
	bhi	m_illegal_bank_number
	lsl.l	#7,d2
	add.l	d1,d2
	bsr	skip_sep			*skip ,
	bsr	chk_num
	bmi	1f				*m_illegal_command_line
	bsr	get_num				*get 3rd number
1:						*case:@b1,b2,n
	subq.l	#1,d1
	cmpi.l	#127,d1
	bhi	m_illegal_timbre_number		*illegal sound number
	lsl.l	#7,d2
	add.l	d2,d1
	cmp.l	#fmsnd_reg_max-1,d1
	bhi	m_illegal_timbre_number		*illegal sound number
	rts
2:						*@n(音色番号が１つしか指定されていない場合)
	subq.l	#1,d1
	cmp.l	#fmsnd_reg_max-1,d1
	bhi	m_illegal_timbre_number		*illegal sound number
	rts

init_fmsndnm:
	move.l	temp_buffer-work(a6),a1
	move.l	#'    ',d0
	move.l	d0,(a1)+
	move.l	d0,(a1)+
	move.l	d0,(a1)+
	move.l	d0,(a1)+
	rts

get_timbre_name:
	* < d1.b=end character
	* > d3.l=文字列長
	* > d0.b=最後のキャラクター
	move.l	temp_buffer-work(a6),a1
	moveq.l	#0,d3			*str len
	bsr	skip_spc
tmbnmlp:				*get timbre name
	cmp.l	a4,d4
	bls	exit_tmbnmlp
	move.b	(a4)+,d0
	bsr	chk_kanji
	bpl	@f
	move.b	d0,(a1)+		*以下、漢字の場合
	addq.w	#1,d3
	cmpi.w	#fmsndname_len,d3
	bhi	m_timbre_name_too_long
	cmp.l	a4,d4
	bls	m_kanji_break_off	*漢字が途中で終わっている
	move.b	(a4)+,d0
	bra	st_tmbnmchr
@@:
	cmp.b	d1,d0
	beq	exit_tmbnmlp
	cmpi.b	#' ',d0
	bcs	exit_tmbnmlp
st_tmbnmchr:
	move.b	d0,(a1)+
	addq.w	#1,d3
	cmpi.w	#fmsndname_len,d3
	bls	tmbnmlp
	bra	m_timbre_name_too_long	*パターン名が長すぎます
exit_tmbnmlp:
	rts

t_vset_2:				*ｱﾙｺﾞﾘｽﾞﾑﾌｨｰﾄﾞﾊﾞｯｸ分離系モード
*	bsr	check_relation_cmn	*コマンド関係チェック
	bsr	init_fmsndnm
	moveq.l	#CMN_VSET,d0
	bsr	do_wrt_cmn_b
	bsr	chk_num
	bmi	m_illegal_timbre_number	*数字がないのでエラー
	bsr	get_num
	cmpi.l	#fmsnd_reg_max,d1
	bhi	m_illegal_timbre_number	*数字がないのでエラー
	subq.l	#1,d1
	bcs	m_illegal_timbre_number
	bsr	skip_sep
tvst00:
	bsr	chk_num
	bmi	m_timbre_parameter_shortage
	move.l	d1,d0
	bsr	do_wrt_cmn_w		*timbre number
	moveq.l	#0,d0			*dummy
	bsr	do_wrt_cmn_b
	lea	v_buffer+46-work(a6),a1	*テーブルにデフォルト値設定
	move.b	#$0f,(a1)+		*OM
	move.b	#$03,(a1)+		*PAN
	moveq.l	#7-1,d0
@@:
	clr.b	(a1)+
	dbra	d0,@b
	lea	alfb_55-work(a6),a1	*最大値テーブル
	bsr	get_timbre_55_params

	lea	v_buffer-work(a6),a1

	move.b	50(a1),d0		*0)LFRQ
	bsr	do_wrt_cmn_b

	move.b	51(a1),d0		*1)PMD
	tas.b	d0
	bsr	do_wrt_cmn_b
	move.b	52(a1),d0		*2)AMD
	bsr	do_wrt_cmn_b
					*3)SYNC/OM/WF
	move.b	46(a1),d0		*OM
	lsl.b	#3,d0
	tst.b	49(a1)			*SYNC
	beq	@f
	tas.b	d0
@@:
	or.b	48(a1),d0		*WF
	bsr	do_wrt_cmn_b

	move.b	47(a1),d0		*PAN
	ror.b	#2,d0
	move.b	45(a1),d1		*FB
	lsl.b	#3,d1
	or.b	d1,d0
	or.b	44(a1),d0		*AL
	bsr	do_wrt_cmn_b

	move.b	53(a1),d0		*PMS
	lsl.b	#4,d0
	or.b	54(a1),d0		*AMS
	bsr	do_wrt_cmn_b

	lea	-11(a1),a1		*-11はつじつま合わせ
	bra	op_param

get_timbre_55_params:			*音色パラメータをテンポラリ・バッファに
	* < a1=parameter max list
	movem.l	d0-d3/a0-a1,-(sp)
	moveq.l	#55-1,d3		*一時的に格納する
	lea	v_buffer-work(a6),a0
	bsr	skip_sep
t_vset_lp:
	cmp.l	a4,d4
	bls	@f			*m_parameter_shortage	*パラメータが不足している
	bsr	chk_num
	bmi	@f			*m_parameter_shortage	*パラメータが不足している
	bsr	get_num
	moveq.l	#0,d0
	move.b	(a1)+,d0
	cmp.l	d0,d1
	bhi	m_illegal_timbre_parameter
	move.b	d1,(a0)+
	bsr	skip_sep
	dbra	d3,t_vset_lp
@@:
	movem.l	(sp)+,d0-d3/a0-a1
	rts

fm_master_volume:			*.FM_MASTER_VOLUME(ダミー)
*	bsr	check_relation_cmn	*コマンド関係チェック
	bsr	skip_eq
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	cmpi.b	#'{',(a4)
	seq	d2
	bne	@f
	addq.w	#1,a4
@@:
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
	bsr	get_num
	tst.b	d2
	bne	find_end
	bra	cmpl_lp

pcm_tune_setup:				*PCMチューンセットアップ
	moveq.l	#CMN_PCM_TUNE_SETUP,d2
	bra	@f
fm_tune_setup:				*FMチューンセットアップ
	moveq.l	#CMN_FM_TUNE_SETUP,d2
@@:
*	bsr	check_relation_cmn	*コマンド関係チェック
	bsr	skip_eq
	move.l	#128,d1			* < d1.l=required n of data
	suba.l	a1,a1			* < a1.l=no limit check
	jsr	get_arry_params-work(a6)	*> arry_stock,d1.l=usable n of data
	move.l	d2,d0
	bsr	do_wrt_cmn_b
	move.l	arry_stock-work(a6),a1
	moveq.l	#128-1,d1
@@:
	move.b	(a1)+,d0
	bsr	do_wrt_cmn_b
	dbra	d1,@b
	bra	cmpl_lp

fixed_gatetime:				*.FIXED_GATETIME
*	bsr	check_relation_cmn	*コマンド関係チェック
	bsr	skip_eq
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	moveq.l	#0,d3			*fxgt>step
	move.b	(a4)+,d0
	cmpi.b	#'>',d0
	beq	@f
	cmpi.b	#'<',d0			*fxgt>step
	bne	m_illegal_command_line
	moveq.l	#-1,d3
@@:
	bsr	skip_eq
	lea	fxgt_str-work(a6),a1
	jsr	get_com_no-work(a6)
	bmi	m_illegal_command_line
	move.b	d3,fxgt_mode-work(a6)
	bra	cmpl_lp

gatetime_resolution:			*.GATE_RANGE(Qコマンドのレンジ設定)/非ZMD
*	bsr	check_relation_cmn	*コマンド関係チェック
	bsr	skip_eq
	moveq.l	#0,d3
	cmp.b	#'{',(a4)
	bne	@f
	addq.w	#1,a4
	moveq.l	#-1,d3
@@:
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
	bsr	get_num
	moveq.l	#8,d0
	moveq.l	#3,d2
@@:
	cmp.b	d0,d1
	beq	@f
	addq.b	#1,d2
	add.b	d0,d0
	bcc	@b
	bra	m_illegal_gate_range
@@:
	move.b	d1,gate_range-work(a6)
	move.b	d2,gate_shift-work(a6)
	tst.b	d3
	bne	find_end
	bra	cmpl_lp

	.include	include.s

halt:					*停止
*	bsr	check_relation_cmn	*コマンド関係チェック
	bsr	skip_eq
	moveq.l	#60,d1
	moveq.l	#0,d2
	bsr	chk_num
	bpl	@f
	cmp.l	a4,d4
	bls	1f
	cmpi.b	#'{',(a4)
	bne	1f
	moveq.l	#-1,d2
	addq.w	#1,a4			*skip '{'
	bsr	chk_num
	bmi	1f
@@:
	bsr	get_num
1:
	moveq.l	#CMN_HALT,d0
	bsr	do_wrt_cmn_b
	move.l	d1,d0
	bsr	do_wrt_cmn_l
	move.l	zmd_addr-work(a6),a1
	move.l	z_cmn_flag(a1),d0
	bset.l	#CMN_HALT/4,d0
	move.l	d0,z_cmn_flag(a1)
	tst.b	d2
	bne	find_end
	bra	cmpl_lp

initialize:				*.INITIALIZE(イニシャライズ)
*	bsr	check_relation_cmn	*コマンド関係チェック
	bsr	skip_eq
	moveq.l	#0,d1
	moveq.l	#0,d2
	bsr	chk_num
	bpl	@f
	cmp.l	a4,d4
	bls	do_wrt_init
	cmpi.b	#'{',(a4)
	bne	do_wrt_init
	moveq.l	#-1,d2
	addq.w	#1,a4			*skip '{'
	bsr	chk_num
	bmi	do_wrt_init
	bra	@f

t_init:					*(iN)イニシャライズ
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#0,d1
	moveq.l	#-1,d2
	bsr	chk_num
	bmi	do_wrt_init
@@:
	bsr	get_num			*'2'とすればv2コンパチモードに以降出来る
do_wrt_init:				*'3'とすればv3モードに以降出来る
	clr.b	adpcm_default_ch-work(a6)
	cmpi.b	#2,d1
	bne	@f
	st.b	v2_compatch-work(a6)
@@:
	moveq.l	#CMN_INIT,d0
	bsr	do_wrt_cmn_b
	move.l	d1,d0
	bsr	do_wrt_cmn_b
	move.l	zmd_addr-work(a6),a1
	move.l	z_cmn_flag(a1),d0
	bset.l	#CMN_INIT/4,d0
	move.l	d0,z_cmn_flag(a1)
	tst.b	d2
	bne	find_end
	bra	cmpl_lp

length_mode:				*.LENGTH_MODE
*	bsr	check_relation_cmn	*コマンド関係チェック
	bsr	skip_eq
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	moveq.l	#0,d3
	cmpi.b	#'{',(a4)
	bne	@f
	addq.w	#1,a4
	moveq.l	#-1,d3
@@:
	bsr	chk_num
	bpl	@f
	lea	iptmd_tbl-work(a6),a1
	bsr	get_com_no
	bmi	m_undefined_mode
	tst.l	d0
	sne	step_input-work(a6)
	tst.b	d3
	bne	find_end
	bra	cmpl_lp
@@:
	bsr	get_num
	tst.l	d1
	sne	step_input-work(a6)
	tst.b	d3
	bne	find_end
	bra	cmpl_lp

key:					*.KEY
*	bsr	check_relation_cmn	*コマンド関係チェック
	bsr	chk_num
	bpl	@f
	bsr	skip_eq
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	cmpi.b	#'{',(a4)
	seq	d3
	bne	1f			*bne m_parameter_cannot_be_omitted
	addq.w	#1,a4
	bsr	chk_num
	bpl	@f
1:
	bsr	string_key_case		*文字列による指定
	bra	do_set_key
@@:
	bsr	get_num
	cmpi.l	#7,d1
	bhi	m_too_many_signs	*記号の個数が多すぎる
	bsr	skip_sep
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	move.b	(a4)+,d0
	cmpi.b	#'#',d0			*recog. signs
	beq	get_mjmn
	cmpi.b	#'+',d0
	beq	get_mjmn
	cmpi.b	#'b',d0
	beq	@f
	cmpi.b	#'-',d0
	bne	m_illegal_sign		*未定義の記号
@@:
	neg.l	d1
get_mjmn:				*調の取得
	bsr	skip_sep
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	lea	MJMN_tbl-work(a6),a1
	bsr	get_com_no
	bmi	m_unknown_key_declared	*未知の調を宣言している
	lsl.w	#8,d1
	move.b	d0,d1
do_set_key:
	move.l	zmd_addr-work(a6),a1
	move.w	d1,z_key(a1)		*情報ブロックにも書き込む
	tst.b	d3
	bne	find_end
	bra	cmpl_lp

string_key_case:			*文字列による指定の場合
	lea	KEY_tbl-work(a6),a1	*cmd tbl
	bsr	get_com_no		*>d0.w=com no.
	bmi	m_unknown_key_declared	*未知の調を宣言している
	add.w	d0,d0
	move.w	KEY_v_tbl(pc,d0.w),d1
	rts

KEY_v_tbl:
	dc.b	0,0,1,0,2,0,3,0,4,0,5,0,6,0,6,0,7,0,7,0
	dc.b	0,0,-1,0,-2,0,-2,0,-3,0,-3,0,-4,0,-4,0,-5,0,-5,0,-6,0,-6,0,-7,0,-7,0
	dc.b	0,1,1,1,2,1,3,1,3,1,4,1,4,1,5,1,5,1,6,1,6,1,7,1,7,1
	dc.b	0,1,-1,1,-2,1,-3,1,-4,1,-5,1,-5,1,-6,1,-6,1,-7,1,-7,1

mml_key:				*.KEY
	bsr	chk_num
	bpl	@f
	bsr	string_key_case		*文字列による指定
	bra	mml_do_set_key
@@:
	bsr	get_num
	cmpi.l	#7,d1
	bhi	m_too_many_signs	*記号の個数が多すぎる
	bsr	skip_sep
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	move.b	(a4)+,d0
	cmpi.b	#'#',d0			*recog. signs
	beq	1f
	cmpi.b	#'+',d0
	beq	1f
	cmpi.b	#'b',d0
	beq	@f
	cmpi.b	#'-',d0
	bne	m_illegal_sign		*未定義の記号
@@:
	neg.l	d1
1:					*調の取得
	bsr	skip_sep
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	lea	MJMN_tbl-work(a6),a1
	bsr	get_com_no
	bmi	m_unknown_key_declared	*未知の調を宣言している
	lsl.w	#8,d1
	move.b	d0,d1
mml_do_set_key:
	moveq.l	#seq_cmd_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#KEY_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#2,d0
	bsr	do_wrt_trk_b
	move.l	d1,d0
	bra	do_wrt_trk_w

t_midi_trns:				*MIDI DATA TRANSFER (x)
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	moveq.l	#-1,d0
	bsr	do_wrt_cmn_b		*出力先(-1:current)
	addq.w	#0+1+4+1,a0		*0(str)+1(strlen)+4(datalen)+1(at least 1 data)
	bsr	chk_membdr_cmn		*一応、最低必要分メモリは確保
	subq.w	#0+1+4+1,a0
	moveq.l	#0,d0			*文字列なし
	move.b	d0,exclusive_flg-work(a6)
	bsr	do_wrt_cmn_b		*コメントバイト数=0
	bsr	skip_sep
	cmp.l	a4,d4
	bls	m_parameter_break_off	*パラメータが途中で終わっています
	bra	secure_mdtdtln

roland_exclusive:			*Roland EXCLUSIVE
	moveq.l	#-1,d2
	bsr	chk_num
	bmi	@f
	bsr	get_num		*get dev ID
	cmpi.l	#127,d1
	bhi	m_illegal_device_id
	move.l	d1,d2
@@:
	bsr	skip_sep
	moveq.l	#-1,d3
	bsr	chk_num
	bmi	@f
	bsr	get_num		*get model ID
	cmpi.l	#127,d1
	bhi	m_illegal_model_id
	move.l	d1,d3
@@:
	move.b	#MKID_ROLAND,exclusive_flg-work(a6)	*(頭に$f0,$41,尻にchecksum,$f7がつく)
	bsr	skip_sep
	bra	_midi_data

yamaha_exclusive:			*YAMAHA EXCLUSIVE
	moveq.l	#-1,d2
	bsr	chk_num
	bmi	@f
	bsr	get_num		*get dev ID
	cmpi.l	#127,d1
	bhi	m_illegal_device_id
	move.l	d1,d2
@@:
	bsr	skip_sep
	moveq.l	#-1,d3
	bsr	chk_num
	bmi	@f
	bsr	get_num		*get model ID
	cmpi.l	#127,d1
	bhi	m_illegal_model_id
	move.l	d1,d3
@@:
	move.b	#MKID_YAMAHA,exclusive_flg-work(a6)	*(頭に$f0,$43,尻にchecksum,$f7がつく)
	bsr	skip_sep
	bra	_midi_data

exclusive:					*EXCLUSIVE MIDI DATA TRANSFER (.EXCLUSIVE)
	st.b	exclusive_flg-work(a6)		*(頭に$f0,尻に$f7がつくだけ)
	bra	_midi_data
midi_data:					*MIDI DATA TRANSFER (.MIDI_DATA)
	clr.b	exclusive_flg-work(a6)
_midi_data:
	moveq.l	#-1,d1				*出力先(-1:current(default))
	bsr	chk_num
	bmi	@f
	bsr	get_num				*get I/F number
	subq.l	#1,d1				*0-2
	cmpi.l	#if_max-1,d1
	bhi	m_illegal_interface_number
@@:
	tst.b	exclusive_flg-work(a6)
	ble	go_midi_data			*roland,yamaha以外はスキップ
	tst.l	d1				*以下roland_exclusiveケース(exclusive_flg=1)
	bpl	@f
	move.l	d2,d0				*roland_exclusiveの場合はI/Fを省略した場合は
	or.l	d3,d0				*dev,mdlの省略はできない
	bmi	m_parameter_cannot_be_omitted
	move.b	d2,d5
	lsl.w	#8,d5
	move.b	d3,d5
	bra	go_midi_data
@@:						*インターフェース番号明記ケース
	move.l	d1,d0				*roland exclusiveの場合はデバイスIDと
	add.w	d0,d0				*モデルIDを省略時の時のために保存しておく
	lea	dev_mdl_ID-work(a6),a1
	add.w	d0,a1
	tst.l	d2
	bmi	@f
	move.b	d2,(a1)			*save devID
@@:
	tst.l	d3
	bmi	@f
	move.b	d3,1(a1)		*save mdlID
@@:
	move.w	(a1),d5			*d5=dev,mdl
go_midi_data:
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	move.l	d1,d0				*I/F number(0-2)
	bsr	do_wrt_cmn_b			*出力先
	bsr	get_mdtr_str			*コメント取得
secure_mdtdtln:
	move.l	zmd_now-work(a6),a1		*>a1.l=データ長格納先オフセットアドレス
	bsr	do_wrt_cmn_l			*データ長
	moveq.l	#0,d3
	move.b	exclusive_flg-work(a6),d1	*Exclusiveか
	beq	1f
	moveq.l	#$f0,d0
	bsr	do_wrt_cmn_b			*Header of Exclusive
	moveq.l	#2,d3				*HOX&EOX
	tst.b	d1				*Roland Exc.か
	ble	1f
	move.l	d1,d0
	bsr	do_wrt_cmn_b			*MAKER ID($41 or $43)
	move.w	d5,d0
	bsr	do_wrt_cmn_w			*dev,mdl
	cmpi.b	#MKID_YAMAHA,d1
	beq	@f
	moveq.l	#$12,d0
	bsr	do_wrt_cmn_b			*Data Set cmd
	moveq.l	#7,d3				*HOX,MAKER,DEV,MDL,DT1,...,checksum,EOX
	bra	1f
@@:
	move.l	zmd_now-work(a6),a2		*>a2.l=データ長格納先オフセットアドレス
	bsr	do_wrt_cmn_w			*データ長
	moveq.l	#8,d3				*HOX,MAKER,DEV,MDL,LENGTH,...,checksum,EOX
1:
	moveq.l	#0,d2				*sum
mdtr_lp:
	bsr	skip_sep
	cmp.l	a4,d4
	bls	m_parameter_break_off	*パラメータが不足している
	cmpi.b	#'"',(a4)
	bne	@f
	bsr	set_str_to_cmn		*文字列データ
	bra	mdtr_lp
@@:
	cmpi.b	#"'",(a4)
	bne	@f
	bsr	set_str_to_cmn		*文字列データ
	bra	mdtr_lp
@@:
	bsr	chk_num
	bmi	exit_mdtr		*データもう無し
	bsr	get_num
	bsr	sstc_do_wrt_cmn_b
	bra	mdtr_lp
exit_mdtr:
	move.b	exclusive_flg-work(a6),d1
	beq	set_mdtr_size
	bmi	1f
	cmpi.b	#MKID_YAMAHA,d1
	bne	@f
	move.l	d3,d0		*ヤマハの場合は転送バイト数もチェックサムに考慮
	sub.l	#8+3,d0		*転送バイト数の有効性に付いては後でチェック(3はアドレス分)
	move.w	d0,-(sp)
	andi.w	#$7f,d0
	add.b	d0,d2
	move.w	(sp)+,d0
	lsr.w	#7,d0
	andi.w	#$7f,d0
	add.b	d0,d2
@@:
	moveq.l	#$80,d0
	andi.b	#$7f,d2
	sub.b	d2,d0				*d0=Roland check sum value
	andi.b	#$7f,d0
	bsr	do_wrt_cmn_b			*checksum
1:
	moveq.l	#$f7,d0
	bsr	do_wrt_cmn_b			*End of Exclusive
set_mdtr_size:
	tst.l	d3
	beq	m_parameter_shortage
	add.l	zmd_addr-work(a6),a1
	rept	4
	rol.l	#8,d3
	move.b	d3,(a1)+	*データ長を格納
	endm
	cmpi.b	#MKID_YAMAHA,d1
	bne	@f
	add.l	zmd_addr-work(a6),a2
	sub.l	#8+3,d3
	ble	m_parameter_shortage
	cmpi.l	#16384,d3
	bhi	m_too_many_parameters
	move.w	d3,d0
	lsr.w	#7,d0
	andi.w	#$7f,d0
	move.b	d0,(a2)+	*データ長を格納
	andi.w	#$7f,d3
	move.b	d3,(a2)+	*データ長を格納
@@:
	move.l	zmd_addr-work(a6),a1
	move.l	z_cmn_flag(a1),d0
	bset.l	#CMN_MIDI_TRANSMISSION/4,d0
	move.l	d0,z_cmn_flag(a1)
	bra	find_end

get_mdtr_str:					*コメント取得
	* > 0(a0)=comment length:0-255
	* > 1(a0)...=comment string(no endcode)
	* X d1,d3,a1
	moveq.l	#0,d3				*文字列長=0
	move.l	zmd_now-work(a6),a1		*>a1.l=文字長格納先オフセットアドレス
	bsr	do_wrt_cmn_b			*コメントバイト数(この時点ではdummy)
	bsr	skip_eq
	cmp.l	a4,d4
	bls	m_parameter_break_off		*パラメータが途中で終わっています
	cmpi.b	#'{',(a4)			*文字列はなし
	bne	@f
	addq.w	#1,a4				*skip {
	bra	get_mdtr_data
@@:
	move.w	#255-1,d1			*文字数
	bsr	get_string			*コメント取得 > d3.l=文字数
get_mdtr_data:
	add.l	zmd_addr-work(a6),a1
	move.b	d3,(a1)				*文字長格納
	rts

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

set_str_to_cmn:				*文字列をソースより摘出してZMD化
	* < d1.l=data
	* < d2.b=sum
	* < d3.l=data length
	* > d2.b=sum
	* > d3.l=added data length
	* - all				*(必ず"で囲まれている)
reglist	reg	d0/d5
	movem.l	reglist,-(sp)
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	cmpi.b	#'"',(a4)
	beq	@f
	cmpi.b	#"'",(a4)
	bne	m_string_break_off
@@:
	move.b	(a4)+,d5		*文字列終端記号
	moveq.l	#0,d0
sstclp00:
	cmp.l	a4,d4
	bls	exit_sstclp00
	move.b	(a4)+,d0
	move.l	d0,d1
	bsr	chk_kanji
	bpl	@f
	bsr	sstc_do_wrt_cmn_b
	cmp.l	a4,d4
	bls	m_kanji_break_off	*漢字が途中で終わっている
	move.b	(a4)+,d1
	bsr	sstc_do_wrt_cmn_b
	bra	sstclp00
@@:
	cmp.b	d5,d1
	beq	exit_sstclp00
	cmpi.b	#$0d,d1			*$0dは無視
	beq	sstclp00
	cmpi.b	#$0a,d1
	beq	@f
	bsr	sstc_do_wrt_cmn_b
	bra	sstclp00
@@:
	bsr	cr_line
	moveq.l	#$0d,d1
	bsr	sstc_do_wrt_cmn_b
	moveq.l	#$0a,d1
	bsr	sstc_do_wrt_cmn_b
	tst.b	d1
	bne	sstclp00
exit_sstclp00:
	movem.l	(sp)+,reglist
	rts

sstc_do_wrt_cmn_b:
	* < d1.l=data
	* < d2.b=sum
	* < d3.l=data length
	* > d2.b=sum
	* > d3.l=added data length
	tst.b	exclusive_flg-work(a6)
	beq	@f
	cmpi.l	#$7f,d1			*exclusiveならば$f0..$f7間は必ず7bit以下
	bhi	1f
@@:
	cmpi.l	#$ff,d1			*生データ送信ならば8bit以下
	bhi	1f
	move.b	d1,d0
	add.b	d0,d2
	bsr	do_wrt_cmn_b
	addq.l	#1,d3			*inc data len
	rts
1:					*255より大きい値は7ビット毎に分けて送信
	move.b	d1,d0
	andi.b	#$7f,d0
	add.b	d0,d2
	bsr	do_wrt_cmn_b
	addq.l	#1,d3			*inc data len
	lsr.l	#7,d1
	bne	1b
	rts

midi_dump:				*.MIDI_DUMP(MIDIダンプファイル送信)
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#-1,d1			*-1:default interface
	moveq.l	#0,d2
	bsr	chk_num
	bpl	@f
	bsr	skip_eq
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	cmp.b	#'{',(a4)
	seq	d2
	bne	set_mddpifn
					*'{'で始まっているケース
	addq.w	#1,a4			*skip '{'
	bsr	chk_num
	bmi	set_mddpifn
@@:					*インターフェース番号取得
	bsr	get_num			*get I/F number
	subq.l	#1,d1			*0-2
	cmpi.l	#if_max-1,d1
	bhi	m_illegal_interface_number
	bsr	skip_sep
set_mddpifn:
	moveq.l	#CMN_MIDI_DUMP,d0
	bsr	do_wrt_cmn_b
	move.l	d1,d0
	bsr	do_wrt_cmn_b
	bsr	set_fn_to_cmn		*ファイルネームのZMD化
	move.l	zmd_addr-work(a6),a1
	move.l	z_cmn_flag(a1),d0
	bset.l	#CMN_MIDI_DUMP/4,d0
	move.l	d0,z_cmn_flag(a1)
	tst.b	d2
	bne	find_end
	bra	cmpl_lp

zpd_equ:				*.ZPD(ZPD組み込み命令)
adpcm_block_data:			*.ADPCM_BLOCK_DATA(ZPD組み込み命令)
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_BLOCK_PCM,d0
	bsr	do_wrt_cmn_b
	bsr	skip_eq
	bsr	set_fn_to_cmn		*ファイルネームのZMD化
	move.l	zmd_addr-work(a6),a1
	move.l	z_cmn_flag(a1),d0
	bset.l	#CMN_BLOCK_PCM/4,d0
	move.l	d0,z_cmn_flag(a1)
	bra	cmpl_lp

adpcm_list:				*.ADPCM_LIST(ADPCM定義ファイル読み込み)
call:					*.CALL(外部ZMS読み込み)
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_READ_SUB,d0
	bsr	do_wrt_cmn_b
	bsr	set_fn_to_cmn		*ファイルネームのZMD化
	move.l	zmd_addr-work(a6),a1
	move.l	z_cmn_flag(a1),d0
	bset.l	#CMN_READ_SUB/4,d0
	move.l	d0,z_cmn_flag(a1)
	bra	cmpl_lp

	.include	pcmproc.s

comment:				*.COMMENT(コメント文)
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_COMMENT,d0
	move.l	a0,a2
	bsr	do_wrt_cmn_b
	bsr	set_cmt_to_cmn		*文字列のZMD化
	move.l	zmd_addr-work(a6),a1
	move.l	z_cmn_flag(a1),d0
	bset.l	#CMN_COMMENT/4,d0
	bne	@f
	sub.l	a1,a2			*初めのコメントはタイトルとみなす
	sub.w	#z_title_offset+4-1,a2
	move.l	a2,z_title_offset(a1)
@@:
	move.l	d0,z_cmn_flag(a1)
	bra	cmpl_lp

set_cmt_to_cmn:				*コメントをソースより摘出してZMD化
	* - all				*{}で囲まれている可能性があるケース
reglist	reg	d0-d3
	movem.l	reglist,-(sp)
	bsr	skip_eq
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	cmpi.b	#'{',(a4)
	seq	d1
	bne	@f
	addq.w	#1,a4
@@:
	moveq.l	#0,d3
_sftclp00:
	cmp.l	a4,d4
	bls	_exit_sftclp00
	move.b	(a4)+,d0
	bsr	chk_kanji
	bpl	@f
	bsr	do_wrt_cmn_b
	cmp.l	a4,d4
	bls	m_kanji_break_off	*漢字が途中で終わっている
	move.b	(a4)+,d0
	bsr	do_wrt_cmn_b
	bra	_sftclp00
@@:
	tst.b	d1
	beq	1f
	cmpi.b	#'{',d0
	bne	@f
	addq.l	#1,d3
	bra	1f
@@:
	cmpi.b	#'}',d0
	bne	1f
	subq.l	#1,d3
	bcs	_exit_sftclp00
1:
	cmpi.b	#$0d,d0			*$0dは無視
	beq	_sftclp00
	cmpi.b	#$0a,d0
	beq	@f
	bsr	do_wrt_cmn_b
	bra	_sftclp00
@@:
	bsr	cr_line
	moveq.l	#$0d,d0
	bsr	do_wrt_cmn_b
	moveq.l	#$0a,d0
	bsr	do_wrt_cmn_b
	tst.b	d1
	bne	_sftclp00
_exit_sftclp00:
	moveq.l	#0,d0
	bsr	do_wrt_cmn_b
	movem.l	(sp)+,reglist
	rts

set_fn_to_cmn:				*ファイル名をソースより摘出してZMD化
	* - all				*{}で囲まれている可能性があるケース
reglist	reg	d0-d3
	movem.l	reglist,-(sp)
	bsr	skip_eq
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	cmp.b	#'{',(a4)
	seq	d1
	bne	@f
	addq.w	#1,a4
@@:
	moveq.l	#0,d3
sftclp00:
	cmp.l	a4,d4
	bls	exit_sftclp01
	move.b	(a4)+,d0
	bsr	chk_kanji
	bpl	@f
	bsr	do_wrt_cmn_b
	cmp.l	a4,d4
	bls	m_kanji_break_off	*漢字が途中で終わっている
	move.b	(a4)+,d0
	bsr	do_wrt_cmn_b
	bra	sftclp00
@@:
	cmpi.b	#' ',d0			*ファイル名にスペースはあり得ないから無視
	beq	sftclp00
	bhi	@f
	subq.w	#1,a4			*CTRLコードは戻る
	bra	exit_sftclp01
@@:
	cmp.b	#'{',d0			*始端チェック
	bne	@f
	addq.l	#1,d3
@@:
	cmp.b	#'}',d0			*終端チェック
	bne	@f
	subq.l	#1,d3
	bcs	exit_sftclp00		*{}ネストまで考慮
@@:
	bsr	do_wrt_cmn_b
	bra	sftclp00
exit_sftclp00:
	moveq.l	#0,d1
exit_sftclp01:
	bsr	skip_spc
	tst.b	d1			*'{'はなかった
	beq	@f
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_illegal_command_line	*'}'がなかった
	cmpi.b	#'}',(a4)+
	bne	m_illegal_command_line	*'}'がなかった
@@:
	moveq.l	#0,d0
	bsr	do_wrt_cmn_b
	movem.l	(sp)+,reglist
	rts

fnstr_chk:			*その文字がファイルネームとして使えるか
	* < d0.b=data
	* > eq=can't use
	* > ne=able to use
	* - all
	tst.b	d0
	bmi	@f
	movem.l	d0-d1,-(sp)
	move.l	d0,d1
	lsr.b	#3,d1
	ext.w	d1
	andi.b	#7,d0
	btst.b	d0,fnstr_tbl(pc,d1.w)
	movem.l	(sp)+,d0-d1
@@:
	rts

fnstr_tbl:	dc.b	%00000000,%00000000	*00～0f
		dc.b	%00000000,%00000000	*10～1f
		dc.b	%01111010,%01000011	*20～2f
		dc.b	%11111111,%00000111	*30～3f
		dc.b	%11111111,%11111111	*40～4f
		dc.b	%11111111,%11010111	*50～5f
		dc.b	%11111111,%11111111	*60～6f
		dc.b	%11111111,%11101111	*70～7f

current_midi_in:			*.CURRENT_MIDI_IN
*	bsr	check_relation_cmn	*コマンド関係チェック
	bsr	skip_eq
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	cmpi.b	#'{',(a4)
	seq	d2
	bne	@f
	addq.w	#1,a4
@@:
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
	bsr	get_num
	subq.l	#1,d1			*d1=0-2
	cmpi.l	#if_max-1,d1
	bhi	m_illegal_interface_number
	moveq.l	#CMN_CRNT_MIDI_IN,d0
	bsr	do_wrt_cmn_b
	move.l	d1,d0
*	move.b	d1,cmi_work-work(a6)
	bsr	do_wrt_cmn_b
	move.l	zmd_addr-work(a6),a1
	move.l	z_cmn_flag(a1),d0
	bset.l	#CMN_CRNT_MIDI_IN/4,d0
	move.l	d0,z_cmn_flag(a1)
	tst.b	d2
	bne	find_end
	bra	cmpl_lp

current_midi_out:			*.CURRENT_MIDI_OUT
*	bsr	check_relation_cmn	*コマンド関係チェック
	bsr	skip_eq
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	cmpi.b	#'{',(a4)
	seq	d2
	bne	@f
	addq.w	#1,a4
@@:
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
	bsr	get_num
	subq.l	#1,d1			*d1=0-2
	cmpi.l	#if_max-1,d1
	bhi	m_illegal_interface_number
	moveq.l	#CMN_CRNT_MIDI_OUT,d0
	bsr	do_wrt_cmn_b
	move.l	d1,d0
*	move.b	d1,cmo_work-work(a6)
	bsr	do_wrt_cmn_b
	move.l	zmd_addr-work(a6),a1
	move.l	z_cmn_flag(a1),d0
	bset.l	#CMN_CRNT_MIDI_OUT/4,d0
	move.l	d0,z_cmn_flag(a1)
	tst.b	d2
	bne	find_end
	bra	cmpl_lp

dummy:					*.DUMMY(ダミー)
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_DUMMY,d0
	bsr	do_wrt_cmn_b
	move.l	zmd_addr-work(a6),a1
	move.l	z_cmn_flag(a1),d0
	bset.l	#CMN_DUMMY/4,d0
	move.l	d0,z_cmn_flag(a1)
	bra	cmpl_lp

define:					*マクロ定義(.define)
	tst.l	macro_addr-work(a6)
	bne	@f
	bsr	get_macro_work	*macro name length(.b),n of param.s(.b),macro name(.str)
@@:				*macro contents length(.l),macro contents(.str)
	moveq.l	#0,d1			*d0.l=dummy endcode
	bsr	get_macro_name		*> d3.b=len of str
	addq.w	#1,d3			*endcode分

	moveq.l	#0,d2
dfnlp00:				*パラメータ個数チェック
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_illegal_command_line	*中断されている
	move.b	(a4),d0
	bsr	chk_kanji
	bmi	1f
	cmpi.b	#'%',d0
	bne	1f
	addq.w	#1,a4			*skip '%'
	bsr	chk_num
	bmi	@f
	bsr	get_num			*get dummy number
@@:
	bsr	skip_sep
	addq.w	#1,d2
	cmpi.w	#max_macro_param,d2
	bhi	m_too_many_parameters
	bra	dfnlp00
1:
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_illegal_command_line	*中断されている
	cmpi.b	#'{',(a4)+
	bne	m_illegal_command_line	*中断されている

	move.l	macro_now-work(a6),d1		*文字列ポインタ
	move.l	macro_addr-work(a6),a1

	bsr	chk_dfn_limit
	move.b	d3,(a1,d1.l)			*マクロ名の長さ
	addq.l	#1,d1
	bsr	chk_dfn_limit
	move.b	d2,(a1,d1.l)			*パラメータの数
	addq.l	#1,d1

	movem.l	d1-d2,-(sp)
	move.l	temp_buffer-work(a6),a2
	subq.w	#1,d3			*for dbra
@@:
	bsr	chk_dfn_limit
	move.b	(a2)+,(a1,d1.l)		*マクロ名書き込み
	addq.l	#1,d1
	dbra	d3,@b

	addq.l	#4,d1			*+4はマクロ内容サイズ分
	bsr	chk_dfn_limit

	move.l	d1,d5

	move.l	d1,-(sp)
	bsr	skip_spc
	moveq.l	#0,d3
dfnlp01:					*マクロ内容登録
	move.l	a4,line_ptr-work(a6)
	bsr	chk_dfn_limit
	cmp.l	a4,d4
	bls	m_illegal_command_line	*中断されている
	move.b	(a4)+,d0
	bsr	chk_kanji
	bpl	1f
	move.b	d0,(a1,d1.l)		*漢字1文字目
	addq.l	#1,d1
	bsr	chk_dfn_limit
	cmp.l	a4,d4
	bls	m_illegal_command_line	*中断されている
	move.b	(a4)+,d0
	bra	st_dfn
1:
*	cmpi.b	#'%',d0
*	bne	1f
*	subq.b	#1,d2			*パラメータ個数チェック
*	bcs	m_illegal_parameter_format
1:
	cmpi.b	#'}',d0
	bne	@f
	subq.l	#1,d3			*ネスト構造吟味
	bcs	1f			*exit
@@:
	cmpi.b	#'{',d0
	bne	st_dfn
	addq.l	#1,d3			*ネスト構造吟味
st_dfn:
	move.b	d0,(a1,d1.l)
	cmpi.b	#$0a,d0
	bne	@f
	bsr	cr_line
@@:
	addq.l	#1,d1
	bra	dfnlp01
1:
*	tst.b	d2			*パラメータが個数文無い
*	bne	m_illegal_parameter_format
	bsr	chk_dfn_limit
	clr.b	(a1,d1.l)		*endcode
	addq.l	#1,d1
	move.l	d1,d0
	sub.l	d5,d0

	move.b	d0,-1(a1,d5.l)		*マクロの内容サイズを登録
	lsr.l	#8,d0
	move.b	d0,-2(a1,d5.l)
	lsr.l	#8,d0
	move.b	d0,-3(a1,d5.l)
	lsr.l	#8,d0
	move.b	d0,-4(a1,d5.l)
mcrn_reorder:				*並べ変え
	move.l	macro_now-work(a6),d2
	move.l	d1,macro_now-work(a6)
	move.l	d2,d5
	add.l	a1,d5			*d5.l=limit addr.
	move.b	2(a1,d2.l),d3		*d3.b=今回登録したマクロの1文字目
	move.l	d1,d6
	sub.l	d2,d6			*d0.l=今回の登録内容サイズ
	move.l	a1,a2
mcrodr_lp:
	cmp.b	2(a2),d3
	bls	@f
	moveq.l	#0,d0
	move.b	(a2)+,d0		*d0.b=name len
	addq.w	#1,a2			*skip (n of param)
	add.l	d0,a2
	move.l	a2,d7			*d7.l=name
	move.b	(a2)+,d0
	lsl.w	#8,d0
	move.b	(a2)+,d0
	swap	d0
	move.b	(a2)+,d0
	lsl.w	#8,d0
	move.b	(a2)+,d0
	move.l	a2,a3			*a3.l=content
	add.l	d0,a2
	cmp.l	a2,d5
	bne	mcrodr_lp
	bra	exit_mcrodr
@@:
	move.l	a2,a5
@@:
	cmp.l	a5,d5			*sentinel case
	beq	exit_mcrodr		*(連続しているので並べ変える必要はないとする)
	moveq.l	#0,d0
	move.b	(a5)+,d0		*d0.b=name len
	addq.w	#1,a5			*skip (n of param)
	add.l	d0,a5
	move.b	(a5)+,d0
	lsl.w	#8,d0
	move.b	(a5)+,d0
	swap	d0
	move.b	(a5)+,d0
	lsl.w	#8,d0
	move.b	(a5)+,d0
	add.l	d0,a5
	cmp.b	2(a5),d3
	beq	@b
	sub.l	a1,a2			*a2=copy end offset
	move.l	d1,d2			*d2=copy source offset
	add.l	d6,d1			*d1=copy dest. offset
	move.l	d1,-(sp)
	bsr	chk_dfn_limit
@@:					*移動
	move.b	-1(a1,d2.l),-1(a1,d1.l)
	subq.l	#1,d1
	subq.l	#1,d2
	cmp.l	d2,a2
	bcs	@b
	move.l	(sp)+,d1
	add.l	d6,d2
@@:					*今回の内容を定位置にセット
	move.b	-1(a1,d1.l),-1(a1,d2.l)
	subq.l	#1,d1
	subq.l	#1,d2
	subq.l	#1,d6
	bne	@b
	movem.l	(sp)+,d0-d2		*d0-d1はこのケースでは使わない
	move.l	d7,a1
	move.l	a3,a2
	bra	@f
exit_mcrodr:
	movem.l	(sp)+,d0-d2
	lea	(a1,d0.l),a2		*macro contents
	lea	(a1,d1.l),a1		*macro name
@@:
	tst.l	include_depth-work(a6)		*includeしたファイルか
	bne	cmpl_lp

	clr.l	macro_now-work(a6)

*do_chg_src:				*マクロでソースを変換
	* < d2.l=n of params
	* < a1.l=macro name str
	* < a2.l=macro contents str
	* < a4.l=src addr.
	* < d4.l=src limiter
	* - a2
reglist	reg	d1-d3/d5-d6/a0-a3
	movem.l	reglist,-(sp)
	lea	line_backup-work(a6),a0
	move.l	line_number-work(a6),(a0)+
	move.l	line_locate-work(a6),(a0)+
	move.l	line_ptr-work(a6),(a0)+
	move.l	a4,line_locate-work(a6)
	move.l	a4,line_ptr-work(a6)
	move.l	a4,pmr_rvs_start-work(a6)
	clr.l	pmr_cr-work(a6)
	move.l	chgsrc_addr-work(a6),d5		*d5=あとで解放するのに使用
	bsr	get_chgsrc_buffer
	move.l	chgsrc_addr-work(a6),a3
	moveq.l	#0,d1
chgmcrlp00:
	cmp.l	a4,d4
	bls	exit_chgsrc
	move.b	(a4),d0
	cmpi.b	#'/',d0
	bne	@f
	bsr	do_skip_comment
	bra	chgmcrlp00
@@:
	jsr	mk_capital-work(a6)
	cmp.b	(a1),d0			*マクロ名の1文字目と比較
	bne	non_chg_src
	move.l	a4,pmr_ptr0-work(a6)	*マクロ変換開始ポイント
	bsr	check_macro_name	*文字列検査
	bmi	non_chg_src		*minus:not match
	move.l	a4,pmr_ptr1-work(a6)	*マクロ変換開始ポイント
	move.l	d1,pmr_ofs-work(a6)	*マクロ変換開始ポイント
					*パラメータ採りだし
	move.l	d2,d6
	movem.l	d2/a0-a2,-(sp)
	move.l	#4096,d2
	move.l	#ID_TEMP,d3
	jsr	get_mem-work(a6)
	tst.l	d0
	bmi	m_out_of_memory
	moveq.l	#0,d3
	move.w	d3,(a0)			*(endcode=0)*2
	bsr	skip_spc_mcr
	subq.w	#1,d6			*for dbra
	bcs	dochgmcrsrc		*パラメータ無し
chgmcrlp01:
	cmp.l	a4,d4
	bls	m_illegal_command_line	*中断されている
	move.b	(a4)+,d0
	bsr	chk_kanji
	bpl	@f
	bsr	chk_mcrprm_limit
	move.b	d0,(a0,d3.l)
	addq.l	#1,d3
	cmp.l	a4,d4
	bls	m_illegal_command_line	*中断されている
	move.b	(a4)+,d0
	bra	1f
@@:
	cmpi.b	#$0a,d0
	bne	@f
	bsr	cr_line
	bra	1f
@@:
	cmpi.b	#',',d0
	beq	@f
	cmpi.b	#' ',d0
	bls	@f
1:					*パラメータ文字列格納
	bsr	chk_mcrprm_limit
	move.b	d0,(a0,d3.l)
	addq.l	#1,d3
	bra	chgmcrlp01
@@:					*パラメータ区切り
	bsr	chk_mcrprm_limit
	clr.b	(a0,d3.l)		*end code #1
	addq.l	#1,d3
	dbra	d6,chgmcrlp01
	bsr	chk_mcrprm_limit
	clr.b	(a0,d3.l)		*end code #2
dochgmcrsrc:				*マクロ変換
	move.l	a0,a1			*a1.l(解放時に使用)
	bsr	preserve_macro_result1	*< d1.l,a3.l
dochgmcrsrclp:
	move.b	(a2)+,d0
	bsr	chk_kanji
	bpl	@f
	bsr	chk_chgsrc_limit
	move.b	d0,(a3,d1.l)
	addq.l	#1,d1
	move.b	(a2)+,d0
	bra	7f
@@:
	tst.b	d0
	beq	exit_dochgmcrsrclp
	cmpi.b	#'%',d0
	bne	1f
	movem.l	d1/d4/a4,-(sp)
	move.l	a2,a4
	moveq.l	#-1,d4
	bsr	chk_num			*%1等の数値付き識別子に対応
	bmi	6f
	move.l	a1,a0
	bsr	get_num
	move.l	a4,a2
2:
	subq.l	#1,d1
	bne	3f
6:
	movem.l	(sp)+,d1/d4/a4
	bra	@f
3:
	tst.b	(a0)
	beq	5f
4:
	tst.b	(a0)+
	bne	4b
	tst.b	(a0)			*まだ残りあり
	bne	2b
5:
	movem.l	(sp)+,d1/d4/a4		*もうあとがない
	bra	dochgmcrsrclp
@@:
	tst.b	(a0)			*%に対応するパラメータないのでパラメータ置換処理なし
	beq	dochgmcrsrclp
@@:					*%等のキャラクタを実際のパラメータ値へ変換
	bsr	chk_chgsrc_limit
	move.b	(a0)+,(a3,d1.l)
	beq	dochgmcrsrclp
	addq.l	#1,d1
	bra	@b
1:					*単に複写
	cmpi.b	#$0a,d0
	bne	7f
	add.l	#1,pmr_cr-work(a6)	*ずれた
7:
	bsr	chk_chgsrc_limit
	move.b	d0,(a3,d1.l)
	addq.l	#1,d1
	bra	dochgmcrsrclp
exit_dochgmcrsrclp:
	bsr	preserve_macro_result2	*< d1.l,a3.l
	jsr	free_mem-work(a6)	*パラメータバッファ解放(< a1.l=ptr)
	bsr	revise_ln_tbl
	movem.l	(sp)+,d2/a0-a2
	bra	chgmcrlp00		*終了

non_chg_src:				*以下変換しないテキストの場合
	move.b	(a4)+,d0
	bsr	chk_kanji
	bpl	@f
	bsr	chk_chgsrc_limit
	move.b	d0,(a3,d1.l)
	addq.l	#1,d1
	cmp.l	a4,d4
	bls	exit_chgsrc
	move.b	(a4)+,d0
	bra	1f
@@:
	cmpi.b	#$0a,d0
	bne	1f
	bsr	cr_line
1:
	bsr	chk_chgsrc_limit
	move.b	d0,(a3,d1.l)
	addq.l	#1,d1
	bra	chgmcrlp00
exit_chgsrc:
	bsr	chk_chgsrc_limit
	clr.b	(a3,d1.l)		*endcode

	move.l	a3,a4
	move.l	a4,d4
	add.l	d1,d4
	tst.l	d5
	beq	@f
	move.l	d5,a1
	jsr	free_mem-work(a6)
@@:
	lea	line_backup-work(a6),a1
	move.l	(a1)+,d0
	sub.l	pmr_cr-work(a6),d0
	move.l	d0,line_number-work(a6)
	move.l	(a1)+,line_locate-work(a6)
	move.l	(a1)+,line_ptr-work(a6)
	movem.l	(sp)+,reglist
	bra	cmpl_lp

pmr_len:	equ	4*2+4*3
reglist	reg	d0-d3/a0-a1
preserve_macro_result1:
	* < a3.l=addr
	* < d1.l=offset
	movem.l	reglist,-(sp)
	tst.l	pmr_addr-work(a6)
	bne	@f
	move.l	#4096,d2		*!UNKO
	move.l	#ID_TEMP,d3
	jsr	get_mem-work(a6)
	tst.l	d0
	bmi	m_out_of_memory
	clr.l	pmr_now-work(a6)
1:
	move.l	a0,pmr_addr-work(a6)
	move.l	d2,pmr_size-work(a6)
@@:
	move.l	pmr_now-work(a6),d2
	move.l	pmr_addr-work(a6),a1
	add.l	#pmr_len,d2
	cmp.l	pmr_size-work(a6),d2
	bcs	@f
	add.l	#4096,d2
	jsr	enlarge_mem-work(a6)
	tst.l	d0
	bpl	1b
	bra	m_out_of_memory
@@:
	lea	-pmr_len(a1,d2.l),a1
	add.l	a3,d1
	move.l	d1,(a1)+
	addq.w	#4,a1			*preserve_macro_result2で埋められる
	move.l	line_number-work(a6),(a1)+
	move.l	line_locate-work(a6),(a1)+
	move.l	pmr_ptr1-work(a6),(a1)+	*マクロ変換開始ポイント
	movem.l	(sp)+,reglist
	rts

preserve_macro_result2:
	* < a3.l=addr
	* < d1.l=offset
reglist	reg	d0-d2/a1
	movem.l	reglist,-(sp)
	move.l	line_ptr-work(a6),d0
	move.l	pmr_now-work(a6),d2
	move.l	pmr_addr-work(a6),a1
	add.l	a3,d1
	move.l	d1,4(a1,d2.l)
	add.l	#pmr_len,d2
	move.l	d2,pmr_now-work(a6)
	movem.l	(sp)+,reglist
	rts

get_true_ln:			*マクロ変換によってずれた行番号を補正する
	* < a4.l=エラー発生アドレス
reglist	reg	d2/a1
	movem.l	reglist,-(sp)
	move.l	pmr_addr-work(a6),a1
	move.l	pmr_now-work(a6),d2
	add.l	a1,d2
1:
	cmp.l	d2,a1
	bcc	exit_gtl
	cmp.l	(a1),a4
	bcs	@f
	cmp.l	4(a1),a4
	bhi	@f
	move.l	8(a1),line_number-work(a6)
	move.l	12(a1),line_locate-work(a6)
	move.l	16(a1),line_ptr-work(a6)
	bra	exit_gtl
@@:
	lea	pmr_len(a1),a1
	bra	1b
exit_gtl:
	movem.l	(sp)+,reglist
	rts

revise_ln_tbl:		*テーブル内のアドレス値の補正
	* < 変換サイズ=(pmr_ofs)-d1.l
	* < d4.l=old(src) end
	* < a3.l=new addr
	* < a4.l=src ptr
reglist	reg	d0-d2/a1-a5
	movem.l	reglist,-(sp)
	move.l	pmr_ptr0-work(a6),a2
	move.l	pmr_rvs_start-work(a6),a5
	move.l	pmr_addr-work(a6),a1
	move.l	pmr_now-work(a6),d2
	move.l	pmr_ofs-work(a6),d0
	sub.l	d0,d1		*d1.l=変換サイズ
	add.l	a1,d2
stltlp:
	cmp.l	d2,a1
	bcc	exit_stlt
	cmp.l	(a1),a5
	bhi	next_stlt
	cmp.l	4(a1),d4
	bcs	next_stlt
	cmp.l	(a1),a2
	bls	@f
	move.l	(a1),d0
	sub.l	a5,d0
	add.l	a3,d0
	add.l	d1,d0
	move.l	d0,(a1)
@@:
	cmp.l	4(a1),a4
	bhi	next_stlt
	move.l	4(a1),d0
	sub.l	a5,d0
	add.l	a3,d0
	add.l	d1,d0
	move.l	d0,4(a1)
next_stlt:
	lea	pmr_len(a1),a1
	bra	stltlp
exit_stlt:
	movem.l	(sp)+,reglist
	rts

skip_spc_mcr:			*スペースをスキップする
	move.w	d0,-(sp)	*(複数のスペース/タブをスキップ、改行はスキップなし)
1:
	cmp.l	a4,d4
	bls	@f
	move.b	(a4),d0
	cmpi.b	#' ',d0
	beq	@f
	bhi	1f
	cmpi.b	#$0a,d0
	beq	1f
	cmpi.b	#$0d,d0
	beq	1f
	cmpi.b	#$09,d0
	bne	1f
@@:				*skipされるのはSPC&TAB
	addq.w	#1,a4
	bsr	chk_mcrprm_limit
	move.b	d0,(a0,d3.l)
	addq.l	#1,d3
	bra	1b
1:
	move.w	(sp)+,d0
	rts

consider_macro:					*溜まっていた変換予定マクロを一気に処理
	* < a4.l=src addr.
	* < d4.l=src limiter
	* - all
reglist	reg	d0-d3/d5-d7/a0-a3/a5
	tst.l	include_depth-work(a6)		*includeしたファイルか
	bne	exit_csdrmcr
	movem.l	reglist,-(sp)
	lea	line_backup-work(a6),a0
	move.l	line_number-work(a6),(a0)+
	move.l	line_locate-work(a6),(a0)+
	move.l	line_ptr-work(a6),(a0)+
	move.l	a4,line_locate-work(a6)
	move.l	a4,line_ptr-work(a6)
	move.l	a4,a4_preserve-work(a6)
	move.l	a4,pmr_rvs_start-work(a6)
	clr.l	pmr_cr-work(a6)
	move.l	chgsrc_addr-work(a6),d5		*d5=あとで解放するのに使用
	bsr	get_chgsrc_buffer
	move.l	chgsrc_addr-work(a6),a3
	moveq.l	#0,d1		*d1.l=0の時はまだなにも変換していないというフラグの意味もある
	bsr	reorder_macro
_chgmcrlp00:
	cmp.l	a4,d4
	bls	_exit_chgsrc
	move.l	a4,d3
	moveq.l	#0,d0
	move.b	(a4),d0
	cmpi.b	#'/',d0
	bne	@f
	bsr	do_skip_comment
	bra	_chgmcrlp00
@@:
	jsr	mk_capital-work(a6)
	move.l	d0,d2
	lsl.w	#3,d2
	move.l	mcrnm_hash_tbl-work(a6),a5
	move.l	(a5,d2.l),d7		*検索すべき個数
	beq	2f
	move.l	4(a5,d2.l),a5
1:
	moveq.l	#0,d6
	move.b	(a5)+,d6		*name len
	moveq.l	#0,d2
	move.b	(a5)+,d2		*d2.l=n of params
	move.l	a5,a1			*a1.l=name
	add.l	d6,a5
	move.b	(a5)+,d6
	lsl.w	#8,d6
	move.b	(a5)+,d6
	swap	d6
	move.b	(a5)+,d6
	lsl.w	#8,d6
	move.b	(a5)+,d6
	move.l	a5,a2			*a2.l=macro contents
	add.l	d6,a5
	cmp.b	(a1),d0			*マクロ名の1文字目と比較
	bne	@f
	move.l	a4,pmr_ptr0-work(a6)	*マクロ変換開始ポイント
	bsr	check_macro_name	*文字列検査
	bpl	_chgmcr_foundit
@@:
	subq.l	#1,d7
	bne	1b
2:
	bsr	chk_kanji
	bpl	1f
	tst.l	d1
	beq	@f
	bsr	chk_chgsrc_limit
	move.b	(a4)+,(a3,d1.l)		*全角コピー
	addq.l	#1,d1
	cmp.l	a4,d4
	bls	m_kanji_break_off
	bsr	chk_chgsrc_limit
	move.b	(a4)+,(a3,d1.l)		*全角コピー
	addq.l	#1,d1
	bra	_chgmcrlp00		*minus:not match
@@:
	addq.w	#2,a4			*全角スキップ
	bra	_chgmcrlp00		*minus:not match
1:
	tst.l	d1
	beq	1f
	bsr	chk_chgsrc_limit
	move.b	(a4)+,d0
	cmpi.b	#$0a,d0
	bne	@f
	bsr	cr_line
@@:
	move.b	d0,(a3,d1.l)		*半角コピー
	addq.l	#1,d1
	bra	_chgmcrlp00
1:
	addq.w	#1,a4			*半角スキップ
	bra	_chgmcrlp00
_chgmcr_foundit:
	move.l	a4,pmr_ptr1-work(a6)	*マクロ変換開始ポイント
	move.l	d1,pmr_ofs-work(a6)	*マクロ変換開始ポイント
	move.l	a4,d7			*preserve a4
	move.l	a4_preserve-work(a6),a4
	cmp.l	a4,d3
	beq	exit_mcrsrccpylp
	tst.l	d1			*既に一回やっている
	bne	exit_mcrsrccpylp
mcrsrccpylp:
	move.b	(a4)+,d0
	bsr	chk_kanji
	bpl	@f
	bsr	chk_chgsrc_limit	*その時点までのソースのコピーを作成
	move.b	d0,(a3,d1.l)
	addq.l	#1,d1
	bcs	m_out_of_memory
	cmp.l	a4,d3
	beq	m_kanji_break_off
	move.b	(a4)+,d0
	bra	1f
@@:
	cmpi.b	#$0a,d0
	bne	1f
	bsr	cr_line
1:
	bsr	chk_chgsrc_limit
	move.b	d0,(a3,d1.l)
	addq.l	#1,d1
	bcs	m_out_of_memory
	cmp.l	a4,d3
	bne	mcrsrccpylp
exit_mcrsrccpylp:
	move.l	d7,a4			*get back a4

	move.l	d2,d6
	movem.l	d2/a0-a2,-(sp)
	move.l	#4096,d2		*使い捨て(ルーチン最後に解放)
	move.l	#ID_TEMP,d3
	jsr	get_mem-work(a6)
	tst.l	d0
	bmi	m_out_of_memory
	moveq.l	#0,d3
	move.w	d3,(a0)			*(endcode=0)*2
	bsr	skip_spc_mcr
	subq.w	#1,d6			*for dbra
	bcs	_dochgmcrsrc		*パラメータ無し
_chgmcrlp01:
	cmp.l	a4,d4
	bls	m_illegal_command_line	*中断されている
	move.b	(a4)+,d0
	bsr	chk_kanji
	bpl	@f
	bsr	chk_mcrprm_limit
	move.b	d0,(a0,d3.l)
	addq.l	#1,d3
	cmp.l	a4,d4
	bls	m_illegal_command_line	*中断されている
	move.b	(a4)+,d0
	bra	1f
@@:
	cmpi.b	#$0a,d0
	bne	@f
	bsr	cr_line
	bra	1f
@@:
	cmpi.b	#',',d0
	beq	@f
	cmpi.b	#' ',d0
	bls	@f
1:					*パラメータ文字列格納
	bsr	chk_mcrprm_limit
	move.b	d0,(a0,d3.l)
	addq.l	#1,d3
	bra	_chgmcrlp01
@@:					*パラメータ区切り
	bsr	chk_mcrprm_limit
	clr.b	(a0,d3.l)		*end code #1
	addq.l	#1,d3
	dbra	d6,_chgmcrlp01
	bsr	chk_mcrprm_limit
	clr.b	(a0,d3.l)		*end code #2
_dochgmcrsrc:				*マクロ変換
	move.l	a0,a1			*a1.l(解放時に使用)
	bsr	preserve_macro_result1	*< d1.l,a3.l
_dochgmcrsrclp:
	move.b	(a2)+,d0
	bsr	chk_kanji
	bpl	@f
	bsr	chk_chgsrc_limit
	move.b	d0,(a3,d1.l)
	addq.l	#1,d1
	move.b	(a2)+,d0
	bra	7f
@@:
	tst.b	d0
	beq	_exit_dochgmcrsrclp
	cmpi.b	#'%',d0
	bne	1f
	movem.l	d1/d4/a4,-(sp)
	move.l	a2,a4
	moveq.l	#-1,d4
	bsr	chk_num			*%1等の数値付き識別子に対応
	bmi	6f
	move.l	a1,a0
	bsr	get_num
	move.l	a4,a2
2:
	subq.l	#1,d1
	bne	3f
6:
	movem.l	(sp)+,d1/d4/a4
	bra	@f
3:
	tst.b	(a0)
	beq	5f
4:
	tst.b	(a0)+
	bne	4b
	tst.b	(a0)
	bne	2b
5:
	movem.l	(sp)+,d1/d4/a4
	bra	_dochgmcrsrclp
@@:
	tst.b	(a0)
	beq	_dochgmcrsrclp
@@:					*%等のキャラクタを実際のパラメータ値へ変換
	bsr	chk_chgsrc_limit
	move.b	(a0)+,(a3,d1.l)
	beq	_dochgmcrsrclp
	addq.l	#1,d1
	bra	@b
1:
	cmpi.b	#$0a,d0
	bne	7f
	add.l	#1,pmr_cr-work(a6)	*ずれた
7:
	bsr	chk_chgsrc_limit
	move.b	d0,(a3,d1.l)
	addq.l	#1,d1
	bra	_dochgmcrsrclp
_exit_dochgmcrsrclp:
	bsr	preserve_macro_result2	*< d1.l,a3.l
	jsr	free_mem-work(a6)	*パラメータバッファ解放(< a1.l=ptr)
	bsr	revise_ln_tbl
	movem.l	(sp)+,d2/a0-a2
	move.l	a4,a4_preserve-work(a6)
	bra	_chgmcrlp00		*終了

_exit_chgsrc:
	tst.l	d1
	beq	1f			*置換は行われなかった
	bsr	chk_chgsrc_limit
	clr.b	(a3,d1.l)		*endcode

	move.l	a3,a4
	move.l	a4,d4
	add.l	d1,d4
	tst.l	d5
	beq	@f
	move.l	d5,a1
	jsr	free_mem-work(a6)
@@:
	lea	line_backup-work(a6),a1
	move.l	(a1)+,d0
	sub.l	pmr_cr-work(a6),d0
	move.l	d0,line_number-work(a6)
	move.l	(a1)+,line_locate-work(a6)
	move.l	(a1)+,line_ptr-work(a6)
	bra	2f
1:
	move.l	a4_preserve-work(a6),a4
2:
	movem.l	(sp)+,reglist
	clr.l	macro_now-work(a6)
exit_csdrmcr:
	rts

reorder_macro:			*マクロ一覧からハッシュ表を作成
reglist	reg	d0-d3/d7/a0-a2/a5
	movem.l	reglist,-(sp)
	move.l	mcrnm_hash_tbl-work(a6),d0
	move.l	d0,a0
	bne	@f
	move.l	#8*256,d2	*使い捨て(ルーチン最後に解放)
	move.l	#ID_TEMP,d3
	jsr	get_mem-work(a6)
	tst.l	d0
	bmi	m_out_of_memory
	move.l	a0,mcrnm_hash_tbl-work(a6)
@@:
	move.l	macro_addr-work(a6),d7
	move.l	d7,a5
	add.l	macro_now-work(a6),d7
	moveq.l	#0,d1
reodrmcr_lp:				*マクロ一覧
	cmp.l	a5,d7
	bls	2f
	move.l	a5,a2
	moveq.l	#0,d0
	move.b	(a5)+,d0	*d0.l=macro name length
	addq.w	#1,a5		*skip n of params
	move.l	a5,a1		*a1.l=macro name
	add.l	d0,a5
	move.b	(a5)+,d0
	lsl.w	#8,d0
	move.b	(a5)+,d0
	swap	d0
	move.b	(a5)+,d0
	lsl.w	#8,d0
	move.b	(a5)+,d0	*d0.l=macro contents length
	add.l	d0,a5		*a5=next
@@:
	cmp.b	(a1),d1
	beq	count_reodrmcr
	bhi	allzero_reodrmcr
	clr.l	(a0)+		*目的のキャラクターになるまでテーブルクリア
	clr.l	(a0)+
	addq.b	#1,d1
	bne	@b
	bra	exit_reodrmcr
2:
	clr.l	(a0)+		*もうあとがないので後ろは全部クリア
	clr.l	(a0)+
	addq.b	#1,d1
	bne	reodrmcr_lp
exit_reodrmcr:
	movem.l	(sp)+,reglist
	rts

allzero_reodrmcr:
	clr.l	(a0)+
	clr.l	(a0)+
	addq.b	#1,d1
	bne	@b
	bra	exit_reodrmcr

count_reodrmcr:
	move.l	a2,4(a0)
	moveq.l	#1,d2
	cmp.l	a5,d7
	bls	@f
1:
	move.l	a5,a2		*preserve hot start 
	moveq.l	#0,d0
	move.b	(a5)+,d0	*d0.l=macro name length
	addq.w	#1,a5		*skip n of params
	move.l	a5,a1
	add.l	d0,a5
	move.b	(a5)+,d0
	lsl.w	#8,d0
	move.b	(a5)+,d0
	swap	d0
	move.b	(a5)+,d0
	lsl.w	#8,d0
	move.b	(a5)+,d0	*d0.l=macro contents length
	add.l	d0,a5		*a5=next
	cmp.b	(a1),d1
	bne	@f
	addq.l	#1,d2
	cmp.l	a5,d7
	bhi	1b
@@:
	move.l	d2,(a0)		*個数
	addq.w	#8,a0
	addq.b	#1,d1
	beq	exit_reodrmcr
	bra	reodrmcr_lp

check_macro_name:			*実際に文字列を捜す
	* < a1=source str addr
	* > eq=get it!
	* > mi=can't found
	* - all
	movem.l	d0-d1/a1,-(sp)
	move.l	a4,d1		*save a4 to d1
cmn_lp:
	cmp.l	a4,d4
	bls	2f		*途中で終わった
	move.b	(a4)+,d0
	bsr	chk_kanji
	bpl	@f
	cmp.b	(a1)+,d0
	bne	2f
	cmp.l	a4,d4
	bls	2f		*途中で終わった
	move.b	(a4)+,d0
	bra	1f
@@:
	jsr	mk_capital-work(a6)	*小文字→大文字
1:
	cmp.b	(a1)+,d0
	bne	2f
	tst.b	(a1)		*終了
	bne	cmn_lp
	moveq.l	#0,d0		*right!
	movem.l	(sp)+,d0-d1/a1
	rts
2:
	move.l	d1,a4		*get back a4
	moveq.l	#-1,d0		*error!
	movem.l	(sp)+,d0-d1/a1
	rts

chk_mcrprm_limit:		*マクロパラメータ格納バッファ拡張処理
	cmp.l	d2,d3
	bcs	@f
	movem.l	d0/a1,-(sp)
	move.l	a0,a1
	add.l	#4096,d2
	jsr	enlarge_mem-work(a6)
	tst.l	d0
	bmi	m_out_of_memory
	movem.l	(sp)+,d0/a1
@@:
	rts

chk_chgsrc_limit:
	cmp.l	chgsrc_size-work(a6),d1
	bcs	@f
	bsr	spread_chgsrc_buffer
	move.l	chgsrc_addr-work(a6),a3
@@:
	rts

chk_dfn_limit:
	cmp.l	macro_size-work(a6),d1
	bcs	@f
	bsr	spread_macro_work
	move.l	macro_addr-work(a6),a1
@@:
	rts

get_macro_work:				*macroワーク確保
	* > d0.l=tpt_sgcd_max
reglist	reg	d1-d3/a0-a1
	movem.l	reglist,-(sp)
	move.l	#256*10,d2
	move.l	#ID_TEMP,d3
	jsr	get_mem-work(a6)
	tst.l	d0
	bmi	m_out_of_memory
	move.l	a0,macro_addr-work(a6)
	move.l	d2,macro_size-work(a6)	*work limit addr
	clr.l	macro_now-work(a6)
	movem.l	(sp)+,reglist
	rts

spread_macro_work:			*macroワーク拡張
reglist	reg	d0-d2/a0-a1
	movem.l	reglist,-(sp)
	move.l	macro_addr-work(a6),a1
	move.l	macro_size-work(a6),d2
	add.l	#256*10,d2
	jsr	enlarge_mem-work(a6)
	tst.l	d0
	bmi	m_out_of_memory
	move.l	a0,macro_addr-work(a6)
	move.l	d2,macro_size-work(a6)	*work limit addr
	movem.l	(sp)+,reglist
	rts

get_chgsrc_buffer:			*変換後のソース格納バッファ確保
	* > d0.l=tpt_sgcd_max
reglist	reg	d1-d3/a0-a1
	movem.l	reglist,-(sp)
	move.l	#65536,d2
	move.l	#ID_TEMP,d3
	jsr	get_mem-work(a6)
	tst.l	d0
	bmi	m_out_of_memory
	move.l	a0,chgsrc_addr-work(a6)
	move.l	d2,chgsrc_size-work(a6)	*work limit addr
	movem.l	(sp)+,reglist
	rts

spread_chgsrc_buffer:			*変換後のソース格納バッファ拡張
reglist	reg	d0-d2/a0-a1
	movem.l	reglist,-(sp)
	move.l	chgsrc_addr-work(a6),a1
	move.l	chgsrc_size-work(a6),d2
	add.l	#65536,d2
	jsr	enlarge_mem-work(a6)
	tst.l	d0
	bmi	m_out_of_memory
	move.l	a0,chgsrc_addr-work(a6)
	move.l	d2,chgsrc_size-work(a6)	*work limit addr
	movem.l	(sp)+,reglist
	rts

gxn_len:	equ	240		*文字列最大長
get_XXX_name	macro	X,Y,MP		*続く文字列(240文字以内)をtemp_bufferに格納する
	* < MP=0:MACRO,1:PATTERN
	* < d1.b=end character
	* > d3.l=文字列長
	* > d0.b=最後のキャラクター
reglist	reg	d2/a1
	movem.l	reglist,-(sp)
	move.l	temp_buffer-work(a6),a1
	moveq.l	#0,d2			*始めの位置文字かフラグ [0]=no,$80=yes
	moveq.l	#0,d3			*str len
	bsr	skip_spc
1:					*get pattern name
	cmp.l	a4,d4
	bls	m_string_break_off
	.if	(MP=0)
	tas.b	d2
	bpl	@f
	cmpi.b	#'%',(a4)		*マクロ名のあと、' 'なしで%を指定した場合に対応
	beq	3f
@@:
	.endif
	move.b	(a4)+,d0
	bsr	chk_kanji
	bpl	@f
	move.b	d0,(a1)+		*以下、漢字の場合
	addq.w	#1,d3
	cmpi.w	#gxn_len,d3		*gxn_len文字分の識別文字列,1文字分の文字長
	bhi	X			*パターン名が長すぎます
	cmp.l	a4,d4
	bls	m_kanji_break_off	*漢字が途中で終わっている
	move.b	(a4)+,d0
	bra	2f
@@:
	cmpi.b	#'=',d0
	bne	@f
	cmp.b	#'{',d1			*endcodeが'{'の場合か
	bne	2f
	cmp.l	a4,d4			*={ は一組で考える
	bls	m_illegal_command_line
	cmp.b	(a4),d1
	bne	2f
	addq.w	#1,a4			*skip '={'
	bra	3f
@@:
	cmp.b	d1,d0
	beq	3f
	cmpi.b	#',',d0
	beq	3f
	cmpi.b	#'{',d0			*この文字はパターン名には使用できない
	beq	m_illegal_character
	.if	(MP)
	cmpi.b	#']',d0			*この文字はパターン名には使用できない
	beq	m_illegal_character
	.endif
	cmpi.b	#' ',d0
	bhi	@f
	bsr	skip_spc
	tst.b	d1			*0ならばendcodeチェック省略
	beq	3f
	cmp.b	(a4)+,d1
	bne	m_illegal_command_line
	bra	3f
@@:
	jsr	mk_capital-work(a6)
2:
	move.b	d0,(a1)+
	addq.w	#1,d3
	cmpi.w	#gxn_len,d3		*gxn_len文字分の識別文字列,1文字分の文字長
	bls	1b
	bra	X			*パターン名が長すぎます
3:
	tst.w	d3
	beq	Y			*パターン名が省略されている
	clr.b	(a1)+			*end code
	movem.l	(sp)+,reglist
	rts
	endm

get_macro_name:
	get_XXX_name	m_macro_name_too_long,m_macro_name_cannot_be_omitted,0

secure_ptn_tbl:					*パターントラック関連ワークの確保
	move.l	trk_inf_tbl-work(a6),a1		*トラック情報テーブルへの登録
	move.l	ti_link_offset-work(a6),d0	*リンク・オフセット=0の時は
	beq	new_gtr_fst_ptn			*だぶりチェック省略
	move.l	d0,a2
@@:
	addq.w	#2,a1
	move.l	(a1)+,d0
	beq	new_gtr_ptn		*新規に登録
	add.l	d0,a1
	bra	@b
new_gtr_ptn:				*2回目以降の登録
	move.l	tit_now-work(a6),d0
	sub.l	a2,d0
	add.l	trk_inf_tbl-work(a6),a2
	move.l	d0,-(a2)		*set link offset
new_gtr_fst_ptn:			*1回目の登録(link処理無し)
	moveq.l	#-1,d0
	bsr	set_tit_w		*register trk no.
	addq.w	#1,n_of_track-work(a6)	*トラック数増加
	beq	m_too_many_tracks	*オーバーフロー(トラック数が多すぎる)
	moveq.l	#0,d0
	bsr	set_tit_l		*4bytes reserving for offset space
	move.l	tit_now-work(a6),ti_link_offset-work(a6)	*keep
	move.l	#ID_PATTERN*256*256*256,d0
	bsr	set_tit_l		*stat,mode,frq,dummy
	move.l	#DEV_PATTERN*65536,d0
	bsr	set_tit_l		*p_type,p_ch
	moveq.l	#16,d0
	bsr	set_tit_l		*コメント長=16文字
	move.l	#'<PAT',d0		*コメント
	bsr	set_tit_l		*<PATTERN TRACK>,0
	move.l	#'TERN',d0
	bsr	set_tit_l
	move.l	#' TRA',d0
	bsr	set_tit_l
	move.l	#'CK>'*256,d0
	bsr	set_tit_l

	bsr	get_pattern_tbl

	moveq.l	#-1,d5				*-1:パターントラック専用トラック番号
	moveq.l	#0,d6				*トラック精度(1:標準)
	bra	alloc_trk_buf

pattern:					*パターントラック書き込み(.pattern)
	tst.l	ptn_addr-work(a6)
	bne	@f
	bsr	secure_ptn_tbl
@@:
	moveq.l	#'{',d1
	bsr	get_pattern_name		*>d3.b=len of str
	bsr	find_pattern_name		*パターン名のだぶりチェック
	bmi	m_pattern_name_redefinition	*パターン名の重複定義

	move.l	ptn_addr-work(a6),a1
	move.l	ptn_size-work(a6),d2
	cmp.l	ptn_now-work(a6),d2
	bhi	@f
	bsr	spread_pattern_tbl
@@:
	move.l	ptn_now-work(a6),d0
	lea	(a1,d0.l),a2			*a2.l=新規登録アドレス
	moveq.l	#0,d5
	bsr	chk_num	
	bmi	1f
	bsr	get_num
	cmpi.l	#255,d1
	bhi	m_illegal_track_frequency
	move.l	d1,d5
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_illegal_command_line
	move.b	(a4),d0
	cmpi.b	#'=',d0
	bne	@f
	addq.w	#1,a4
	bsr	skip_spc
	cmp.l	a4,d4			*={ は一組で考える
	bls	m_illegal_command_line
	move.b	(a4),d0
@@:
	cmpi.b	#'{',d0
	bne	1f
	addq.w	#1,a4			*skip '={'
1:
	moveq.l	#-1,d1
	bsr	set_current_trk		*カレントトラックを「パターントラック」にする
	move.l	current_trk_ptr-work(a6),a5
	move.l	a2,tpt_ptn_work(a5)	*パターンサイズを計算する時に使う
	move.l	tpt_now(a5),(a2)+	*offsetアドレスセット
	move.w	#128,tpt_trkvol(a5)	*!97/5/19
	bsr	init_compile_work	*ワーク初期化
	addq.w	#4,a2			*今回のパターンサイズ格納アドレス分スキップ
	move.w	d5,tpt_trkfrq(a5)	*track frequency
	move.l	temp_buffer-work(a6),a1
	move.b	d3,(a2)+		*文字長
	subq.w	#1,d3
@@:
	move.b	(a1)+,(a2)+		*パターン名書き込み
	dbra	d3,@b
	bsr	skip_spc
	addq.l	#1,n_of_ptn-work(a6)
	add.l	#256,ptn_now-work(a6)
	st.b	ptn_cmd-work(a6)
	bra	go_mml_cmpl

get_pattern_tbl
	movem.l	d0/d2-d3/a0,-(sp)
	move.l	#256*10,d2				*パターン管理バッファ確保
	move.l	#ID_TEMP,d3			*最初は10個分
	jsr	get_mem-work(a6)		*offset.l,length(b),string....:total:256
	tst.l	d0
	bmi	m_out_of_memory
	move.l	a0,ptn_addr-work(a6)
	move.l	d2,ptn_size-work(a6)
	moveq.l	#0,d0
	move.l	d0,ptn_now-work(a6)
	move.l	d0,n_of_ptn-work(a6)
	movem.l	(sp)+,d0/d2-d3/a0
	rts

spread_pattern_tbl:
	* < a1.l=old ptn_addr
	* < d2.l=old ptn_size
	* > a1.l=new ptn_addr
	* > d2.l=new ptn_size
	movem.l	d0/a0,-(sp)
	add.l	#256*10,d2			*10個追加
	jsr	enlarge_mem-work(a6)
	tst.l	d0
	bmi	m_out_of_memory
	move.l	a0,ptn_addr-work(a6)
	move.l	d2,ptn_size-work(a6)		*new work limit
	move.l	a0,a1
	movem.l	(sp)+,d0/a0
	rts

get_pattern_name:
	get_XXX_name	m_pattern_name_too_long,m_pattern_name_cannot_be_omitted,1

find_pattern_name:			*パターン名の検索
	* > ne	:hit!(>a2.l=exact address)
	* > zero:miss
	* - all
	movem.l	d0-d1/a1,-(sp)
	move.l	ptn_addr-work(a6),d2
	move.l	n_of_ptn-work(a6),d1		*d1=number of pattern(1-?)
	beq	exit_fndptnnm
	move.l	d2,a2
mlptnlp00:
	move.l	a2,d2			*copy
	move.l	temp_buffer-work(a6),a1
	addq.l	#8,a2			*(オフセットアドレス+サイズ格納領域)分飛ばす
	moveq.l	#0,d5
	move.b	(a2)+,d5
	subq.w	#1,d5			*for dbra
mlptnlp01:
	move.b	(a1)+,d0
	bsr	chk_kanji
	bpl	@f
	cmp.b	(a2)+,d0
	bne	2f
	subq.w	#1,d5			*for dbra
	bmi	2f
	move.b	(a1)+,d0
	bra	1f
@@:
	jsr	mk_capital-work(a6)
1:
	cmp.b	(a2)+,d0
	bne	2f
	dbra	d5,mlptnlp01		*テーブルに格納されている文字列をすべて比較して等しく
	tst.b	(a1)+			*なおかつ被比較文字列の終端がゼロならば文字列一致
	beq	exit_fndptnnm		*検索パターン発見
2:
	move.l	d2,a2
	lea	256(a2),a2
	subq.l	#1,d1
	bne	mlptnlp00
exit_fndptnnm:
	move.l	d1,d0			*ここでCCRにneかzeroを設定
	move.l	d2,a2
	movem.l	(sp)+,d0-d1/a1
	rts

print:					*.PRINT(コメント文)
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_PRINT,d0
	bsr	do_wrt_cmn_b
	bsr	set_cmt_to_cmn		*文字列のZMD化
	move.l	zmd_addr-work(a6),a1
	move.l	z_cmn_flag(a1),d0
	bset.l	#CMN_PRINT/4,d0
	move.l	d0,z_cmn_flag(a1)
	bra	cmpl_lp

tempo:					*.TEMPO
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#0,d2
	bsr	chk_num
	bpl	@f
	bsr	skip_eq
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	cmpi.b	#'{',(a4)+
	seq	d2
	bne	m_parameter_cannot_be_omitted
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
@@:
	bsr	get_num
	cmpi.l	#65535,d1
	bhi	m_tempo_command_error
	bra	@f
t_tempo:				*(On)テンポ設定
	moveq.l	#1,d2			*終端カッコチェックの有無フラグ(1:checkあり)
*	bsr	check_relation_cmn	*コマンド関係チェック
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
	bsr	get_num
	cmpi.l	#65535,d1
	bhi	m_tempo_command_error
@@:
	move.l	zmd_addr-work(a6),a1
	move.w	d1,z_tempo(a1)		*情報ブロックにも書き込む
	tst.b	d2
	bne	find_end
	bra	cmpl_lp

track:					*トラック書き込み(.track)
*	bsr	check_relation_cmn	*コマンド関係チェック
	move.l	t_trk_no-work(a6),a1
	moveq.l	#t_trk_no_max-1,d2
trklp:					*トラック番号複数記述に対応
	bsr	chk_num
	bpl	@f
	bsr	srch_num
	bmi	go_trkcmpl
@@:
	bsr	get_trknum_seq
	dbra	d2,trklp
	bra	m_track_command_error	*tr_max個以上設定している
*-----------------------------------------------------------------------------
t_trk:					*トラック書き込み(tN)
*	bsr	check_relation_cmn	*コマンド関係チェック
	move.l	t_trk_no-work(a6),a1
	moveq.l	#t_trk_no_max-1,d2
	moveq.l	#0,d3
ttrlp:					*トラック番号複数記述に対応
	bsr	chk_num
	bmi	go_trkcmpl
	bsr	get_trknum_seq
	dbra	d2,ttrlp
	bra	m_track_command_error	*tr_max個以上設定している

get_trknum_seq:				*トラック番号並び取り出し
	bsr	get_num
	tst.l	d1
	bmi	@f
	subq.l	#1,d1
	cmpi.l	#tr_max-1,d1
	bhi	m_illegal_track_number
	move.l	d1,d3
	move.w	d1,(a1)+
	move.w	#-1,(a1)		*endcode
	bra	2f
@@:
	neg.l	d1
	subq.l	#1,d1
	cmpi.l	#tr_max-1,d1
	bhi	m_illegal_track_number
1:
	cmp.w	d1,d3			*(t1-1)のようなケース
	beq	2f
	subq.w	#1,d2
	bcs	m_track_command_error	*tr_max個以上設定している
	move.w	d1,(a1)+
	move.w	#-1,(a1)		*endcode
	cmp.w	d1,d3
	bhi	@f
	subq.w	#1,d1
	bra	1b
@@:
	addq.w	#1,d1
	bra	1b
2:
	bra	skip_sep

go_trkcmpl:
	move.l	t_trk_no-work(a6),a1
	moveq.l	#0,d1
	move.w	(a1)+,d1
	cmpi.w	#-1,d1				*１つも書き込み先トラックが指定されて
	beq	m_parameter_cannot_be_omitted	*いないのならばエラー
	bsr	skip_spc		*以下find_endと同等の処理
	tst.b	now_cmd-work(a6)
	bmi	@f			*.trackコマンドならば終端記号は無し
	cmp.l	a4,d4
	bls	m_illegal_command_line
	cmpi.b	#')',(a4)+		*(tN)
	bne	m_illegal_command_line	*   ^
	bra	do_trkcmpl
@@:
	bsr	skip_eq
	cmp.l	a4,d4
	bls	m_illegal_command_line
	cmpi.b	#'{',(a4)+		*.track	N {
	bne	m_illegal_command_line	*         ^
do_trkcmpl:
	move.l	sp,sp_buf-work(a6)	*スタック保存
	bclr.b	#1,now_cmd-work(a6)	*まずは「MMLコンパイルでない」として初期化
	bsr	set_current_trk		*書き込みトラックの選択(< d1 track number)
go_mml_cmpl:
	or.b	#%0000_0011,now_cmd-work(a6)	*MMLコンパイルしてます,1ライン単位コンパイル
	move.l	current_trk_ptr-work(a6),a5
	lea	line_backup-work(a6),a2
	move.l	line_number-work(a6),(a2)+
	move.l	line_locate-work(a6),(a2)+
	move.l	line_ptr-work(a6),(a2)+
	move.l	n_of_err-work(a6),(a2)+
	move.l	tpt_now(a5),d1
	movem.l	d1/a1/a4,-(sp)		*保存個数を変えたらzcerror.hasの方(go_compile_endなど)
mml_lp_sp_depth:	equ	3	*も変更する
	move.l	sp,sp_buf-work(a6)	*スタック保存
	clr.b	warn_flg-work(a6)	*ON
mml_lp:
	move.l	a4,d7			*戻る場合があるのでとりあえず保存
	clr.b	seq_cmd-work(a6)	*[]系コマンドフラグOFF
	bsr	skip_spc2		*改行までスキップしない
	cmp.l	a4,d4
	bls	mmlc_exit
	move.b	(a4)+,d0
	beq	mmlc_exit		*data end
	bsr	chk_kanji
	bpl	@f
					*全角スキップ
	cmp.l	a4,d4			*1バイト目でファイル終端にきていないかチェック
	bls	m_kanji_break_off
	addq.w	#1,a4			*全角の2バイト目をスキップ
	bra	mml_lp
@@:
	jsr	mk_capital-work(a6)	*d0がalphabetなら大文字にして
	moveq.l	#0,d1
	move.b	d0,d1
	subi.b	#$41,d1		*'A'を引いて
	bmi	not_alpha_cmd	*英字以外のコマンド
	cmpi.b	#25,d1
	bhi	not_alpha_cmd
	btst.b	#c_break,tpt_mode_flg(a5)	*コンパイル中断フラグチェック
	bne	go_skip_mml
	add.w	d1,d1
	move.w	mml_cnv_jmp(pc,d1.w),a2
	jmp	mml_cnv_jmp(pc,a2.w)

mml_cnv_jmp:			*jump table
	dc.w	mml_ag-mml_cnv_jmp	*音階
	dc.w	mml_ag-mml_cnv_jmp	*音階
	dc.w	mml_ag-mml_cnv_jmp	*音階
	dc.w	mml_ag-mml_cnv_jmp	*音階
	dc.w	mml_ag-mml_cnv_jmp	*音階
	dc.w	mml_ag-mml_cnv_jmp	*音階
	dc.w	mml_ag-mml_cnv_jmp	*音階
	dc.w	mml_h-mml_cnv_jmp	*モジュレーションホールド
	dc.w	mml_i-mml_cnv_jmp	*バンクセレクト
	dc.w	mml_j-mml_cnv_jmp	*強制再演奏
	dc.w	mml_k-mml_cnv_jmp	*キートランスポーズ
	dc.w	mml_l-mml_cnv_jmp	*音長
	dc.w	mml_m-mml_cnv_jmp	*モジュレーションモード
	dc.w	mml_n-mml_cnv_jmp	*チャンネルアサイン
	dc.w	mml_o-mml_cnv_jmp	*オクターブ
	dc.w	mml_p-mml_cnv_jmp	*パン
	dc.w	mml_q-mml_cnv_jmp	*ゲートタイム
	dc.w	mml_r-mml_cnv_jmp	*休符
	dc.w	mml_s-mml_cnv_jmp	*波形セレクト
	dc.w	mml_t-mml_cnv_jmp	*テンポ
	dc.w	mml_u-mml_cnv_jmp	*ベロシティ
	dc.w	mml_v-mml_cnv_jmp	*ボリューム
	dc.w	mml_w-mml_cnv_jmp	*同期
	dc.w	mml_x-mml_cnv_jmp	*ローランドエクスクルーシブ
	dc.w	mml_y-mml_cnv_jmp	*Ｙコマンド
	dc.w	mml_z-mml_cnv_jmp	*Ｚコマンド

not_alpha_cmd:			*アルファベット以外のコマンド
	cmpi.b	#'}',d0		*連符エンド(またはコンパイル終了)
	beq	renp_end
	cmpi.b	#'(',d0		*portament
	beq	mml_port
	cmpi.b	#'[',d0		*special seq. cmd
	beq	mml_seq_command
	cmpi.b	#' ',d0
	bls	case_lower_chr
	btst.b	#c_break,tpt_mode_flg(a5)	*コンパイル中断フラグチェック
	bne	go_skip_mml
	cmpi.b	#'/',d0
	bne	@f
go_skip_mml:
	bsr	do_skip_comment	*コメント行をスキップ
	bra	mml_lp
@@:
	cmp.b	#OCTAVE_UP,d0	*octave up
	beq	oct_up
	cmp.b	#OCTAVE_DOWN,d0	*octave down
	beq	oct_dwn
	cmpi.b	#'{',d0		*連符スタート
	beq	renp_start
	cmpi.b	#'@',d0		*@ commands
	beq	cmd_@
	cmpi.b	#'|',d0		*repeat command
	beq	mml_rept_start
	cmpi.b	#':',d0		*repeat start or end
	beq	mml_rept_end
	cmpi.b	#';',d0		*ZMD直接書き込み
	beq	mml_direct_zmd
	cmpi.b	#"'",d0		*和音コマンド
	beq	mml_chord
	cmpi.b	#'_',d0		*相対ボリューム down
	beq	mml_rltv_vol_dwn
	cmpi.b	#'~',d0		*相対ボリューム up
	beq	mml_rltv_vol_up
	cmpi.b	#'`',d0		*強制キーオフ
	beq	mml_kill_note
	cmpi.b	#'=',d0		*特殊コマンドスイッチ
	beq	mml_switch
	cmpi.b	#'\',d0		*fader ctrl
	beq	mml_fader_v2
	cmpi.b	#'?',d0		*poke command
	beq	mml_poke
	cmpi.b	#'"',d0		*スペシャル・タイ・モード
	beq	mml_@j
	cmpi.b	#'.',d0
	beq	goback_cmn_cmpl
	bra	m_syntax_error	*文法エラー

goback_cmn_cmpl:
	tst.b	now_cmd-work(a6)
	bmi	m_syntax_error	*文法エラー(.trackコマンドなのに '}'がないのはおかしい)
	subq.w	#1,a4
	bra	mmlc_exit

case_lower_chr:			*' '以下のキャラクタケース
	cmpi.b	#$0a,d0
	bne	mml_lp
	bsr	cr_line		*改行して次の行もコンパイル
	tst.b	now_cmd-work(a6)
	bmi	mml_lp
	bsr	skip_spc2		*改行までスキップしない
	cmp.l	a4,d4
	bls	mmlc_exit
	move.b	(a4),d0
	cmpi.b	#'.',d0
	beq	mmlc_exit
	cmpi.b	#'#',d0
	beq	mmlc_exit
*	cmpi.b	#'(',d0
*	beq	mmlc_exit
	bra	mml_lp

mmlc_exit:
	btst.b	#c_renp1,tpt_mode_flg(a5)
	bne	m_group_notes_command_error	*連符処理中に帰還はできない
	movem.l	(sp)+,d1/a1-a2
	tst.b	ptn_cmd-work(a6)
	bne	mmlc_exit_ptn		*パターン設定だった
	moveq.l	#0,d1
	move.w	(a1)+,d1		*同時書き込みトラック番号取得
	cmpi.w	#-1,d1
	beq	cmpl_lp
	move.l	n_of_err-work(a6),d0
	cmp.l	line_backup+12-work(a6),d0
	bne	cmpl_lp			*エラーがあるならばコンパイルはしない
	move.l	line_backup+8-work(a6),line_ptr-work(a6)
	move.l	line_backup+4-work(a6),line_locate-work(a6)
	move.l	line_backup+0-work(a6),line_number-work(a6)
	move.l	a2,a4
	bra	do_trkcmpl

mmlc_exit_ptn:			*パターントラック書き込みの終了ケース
	* < d1.l=mml_lp突入前のtpt_now(a5)
	move.l	tpt_now(a5),d2
	cmp.l	d2,d1
	beq	m_null_pattern_error	*パターントラックの「空」はだめ
	move.l	tpt_ptn_work(a5),a2
	sub.l	(a2)+,d2	*パターントラック書き込み前のアドレスと減算してサイズを求める
	move.l	d2,(a2)+	*サイズ格納
	moveq.l	#return_zmd,d0
	bsr	do_wrt_trk_b	*リターンコードセット
	clr.b	ptn_cmd-work(a6)
	bra	cmpl_lp

mml_p:				*パンポット command P
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
	bsr	get_num
	cmpi.l	#3,d1
	bhi	m_illegal_panpot_value
	moveq.l	#panpot_zmd,d0
	bsr	do_wrt_trk_b	*panpot code
	move.b	mmlptbl(pc,d1.w),d0	*0-127レンジへ変換
	bsr	do_wrt_trk_b	*panpot code
	bra	mml_lp
mmlptbl:
	dc.b	128,0,127,64
*-----------------------------------------------------------------------------
mml_slot_separation:			*[SLOT_SEPARATION]
	bsr	chk_num
	bpl	@f
	lea	sltmsk_strv-work(a6),a1
	bsr	get_com_no
	bmi	m_illegal_mode_value	*規定外
	move.l	d0,d1
	bra	1f
@@:
	bsr	get_num
	cmp.l	#%1111,d1
	bhi	m_illegal_mode_value	*規定外
1:
	moveq.l	#slot_mask_zmd,d0
	bsr	do_wrt_trk_b
	lsl.b	#3,d1
	move.l	d1,d0			*mode value
	bra	do_wrt_trk_b
*-----------------------------------------------------------------------------
mml_opm_lfo:				*[OPM.LFO]
	bsr	chk_num			*まずは波形番号とりだし
	bpl	mol_wf_num
	lea	opm_wf_name-work(a6),a1
	bsr	get_com_no
	bmi	@f
	move.l	d0,d1
	bra	set_mol_wf
@@:
	cmp.l	a4,d4
	bls	m_illegal_command_line
	cmpi.b	#',',(a4)
	beq	get_mol_sync
	bra	m_illegal_command_line
mol_wf_num:
	bsr	get_num
	cmpi.l	#3,d1			*波形番号異常
	bhi	m_illegal_wave_number
set_mol_wf:
	moveq.l	#opm_regset_zmd,d0	*cmd
	bsr	do_wrt_trk_b
	moveq.l	#$80+09,d0		*WF
	bsr	do_wrt_trk_b
	move.l	d1,d0			*value
	bsr	do_wrt_trk_b
get_mol_sync:
	bsr	skip_sep
	bsr	chk_num			*シンクロ
	bpl	mol_syc_num
	lea	switch_strv-work(a6),a1
	bsr	get_com_no
	bmi	@f
	move.l	d0,d1
	bra	set_mol_syc
@@:
	cmp.l	a4,d4
	bls	m_illegal_command_line
	cmpi.b	#',',(a4)
	beq	get_mol_spd
	bra	m_illegal_command_line
mol_syc_num:
	bsr	get_num
	cmpi.l	#1,d1			*同期モード値異常
	bhi	m_illegal_switch_value
set_mol_syc:
	moveq.l	#poke_zmd,d0		*cmd
	bsr	do_wrt_trk_b
	moveq.l	#$10,d0			*omt(addr.w,data.b)
	bsr	do_wrt_trk_b
	move.w	#p_sync,d0		*addr. offset
	bsr	do_wrt_trk_w
	move.l	d1,d0			*data value
	bsr	do_wrt_trk_b
get_mol_spd:
	bsr	skip_sep
	bsr	chk_num
	bmi	@f
	bsr	get_num
	cmpi.l	#255,d1
	bhi	m_illegal_speed_value
	moveq.l	#opm_regset_zmd,d0	*cmd
	bsr	do_wrt_trk_b
	moveq.l	#$80+06,d0		*SPD
	bsr	do_wrt_trk_b
	move.l	d1,d0			*value
	bsr	do_wrt_trk_b
@@:
	bsr	skip_sep
	bsr	chk_num
	bmi	@f
	bsr	get_num
	cmpi.l	#127,d1
	bhi	m_illegal_depth_value
	moveq.l	#opm_regset_zmd,d0	*cmd
	bsr	do_wrt_trk_b
	moveq.l	#$80+07,d0		*PMD
	bsr	do_wrt_trk_b
	move.l	d1,d0			*value
	bsr	do_wrt_trk_b
@@:
	bsr	skip_sep
	bsr	chk_num
	bmi	@f
	bsr	get_num
	cmpi.l	#127,d1
	bhi	m_illegal_depth_value
	moveq.l	#opm_regset_zmd,d0	*cmd
	bsr	do_wrt_trk_b
	moveq.l	#$80+08,d0		*AMD
	bsr	do_wrt_trk_b
	move.l	d1,d0			*value
	bsr	do_wrt_trk_b
@@:
	bsr	skip_sep
	bsr	chk_num
	bmi	@f
	bsr	get_num
	cmpi.l	#7,d1
	bhi	m_illegal_depth_value
	moveq.l	#opm_regset_zmd,d0	*cmd
	bsr	do_wrt_trk_b
	moveq.l	#$80+14,d0		*PMS
	bsr	do_wrt_trk_b
	move.l	d1,d0			*value
	bsr	do_wrt_trk_b
@@:
	bsr	skip_sep
	bsr	chk_num
	bmi	@f
	bsr	get_num
	cmpi.l	#3,d1
	bhi	m_illegal_depth_value
	moveq.l	#opm_regset_zmd,d0	*cmd
	bsr	do_wrt_trk_b
	moveq.l	#$80+13,d0		*AMS
	bsr	do_wrt_trk_b
	move.l	d1,d0			*value
	bra	do_wrt_trk_b

mml_opm:				*[OPM]
	lea	opm_op_name-work(a6),a1
	bsr	get_com_no
	bpl	1f
	lea	opm_op_name2-work(a6),a1
	bsr	get_com_no
	bpl	1f
	lea	opm_reg_name-work(a6),a1
	bsr	get_com_no
	bpl	_4x_mmlopm
	lea	opm_reg_name2-work(a6),a1
	bsr	get_com_no
	bpl	_4x_mmlopm
	lea	opm_reg_name3-work(a6),a1
	bsr	get_com_no
	bpl	_4x_mmlopm
	bra	m_unknown_register_name
1:
	move.l	d0,d2
	cmpi.w	#3,d0
	bhi	1f
	lea	opm_reg_name-work(a6),a1
	bsr	get_com_no
	bpl	@f
	lea	opm_reg_name2-work(a6),a1
	bsr	get_com_no
	bpl	@f
	lea	opm_reg_name3-work(a6),a1
	bsr	get_com_no
	bmi	m_unknown_register_name
@@:
	lsl.b	#4,d2
	or.b	d0,d2
	bra	get_rg_data
1:
	tas.b	d2			*OPパラメータがないレジスタは負値に変換
get_rg_data:
	bsr	skip_sep		*skip ','
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
	cmpi.b	#'-',(a4)
	beq	rltv_mml_opm
	cmpi.b	#'+',(a4)
	beq	rltv_mml_opm
	bsr	get_num			*get data
	cmp.l	#$ff,d1
	bhi	m_illegal_parameter_value
	moveq.l	#opm_regset_zmd,d0		*command code
	bsr	do_wrt_trk_b
	move.l	d2,d0
	bsr	do_wrt_trk_b		*reg number
	move.l	d1,d0
	bra	do_wrt_trk_b		*data

rltv_mml_opm:
	bsr	get_num			*get data
	cmp.l	#-128,d1
	blt	m_illegal_parameter_value
	cmp.l	#127,d1
	bgt	m_illegal_parameter_value
	moveq.l	#rltv_opm_regset_zmd,d0	*command code
	bsr	do_wrt_trk_b
	move.l	d2,d0
	bsr	do_wrt_trk_b		*reg number
	move.l	d1,d0
	bra	do_wrt_trk_b		*data

_4x_mmlopm:
	move.l	d0,d2
	move.l	a4,d3			*preserve
	bsr	skip_sep		*パラメータ数チェック
	bsr	chk_num
	bmi	1f
	bsr	get_num
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_illegal_command_line	*']'がない
	cmpi.b	#']',(a4)
	beq	_4x_samvopm		*パラメータ1この場合
1:
	move.l	d3,a4
	moveq.l	#4-1,d3
	lea	opmregop_tbl(pc),a1
_4xmoplp00:
	bsr	skip_sep		*skip ','
	bsr	chk_num
	bmi	next_4xmoplp00
	cmpi.b	#'-',(a4)
	beq	@f
	cmpi.b	#'+',(a4)
	beq	@f
	bsr	get_num			*get data
	cmp.l	#$ff,d1
	bhi	m_illegal_parameter_value
	moveq.l	#opm_regset_zmd,d0		*command code
	bra	1f
@@:					*相対ケース
	bsr	get_num			*get data
	cmp.l	#-128,d1
	blt	m_illegal_parameter_value
	cmp.l	#127,d1
	bgt	m_illegal_parameter_value
	moveq.l	#rltv_opm_regset_zmd,d0	*command code
1:
	bsr	do_wrt_trk_b
	move.l	d2,d0
	add.b	(a1),d0
	bsr	do_wrt_trk_b		*reg number
	move.l	d1,d0
	bsr	do_wrt_trk_b		*data
next_4xmoplp00:
	addq.w	#1,a1
	dbra	d3,_4xmoplp00
	rts

opmregop_tbl:	dc.b	$00,$20,$10,$30

_4x_samvopm
	move.l	d3,a4
	bsr	skip_sep		*skip ','
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
	cmpi.b	#'-',(a4)
	beq	1f
	cmpi.b	#'+',(a4)
	beq	1f
	bsr	get_num			*get data
	cmp.l	#$ff,d1
	bhi	m_illegal_parameter_value
	moveq.l	#4-1,d3
	lea	opmregop_tbl(pc),a1
@@:
	moveq.l	#opm_regset_zmd,d0		*command code
	bsr	do_wrt_trk_b
	move.l	d2,d0
	add.b	(a1)+,d0
	bsr	do_wrt_trk_b		*reg number
	move.l	d1,d0
	bsr	do_wrt_trk_b		*data
	dbra	d3,@b
	rts

1:
	bsr	get_num			*get data
	cmp.l	#-128,d1
	blt	m_illegal_parameter_value
	cmp.l	#127,d1
	bgt	m_illegal_parameter_value
	moveq.l	#4-1,d3
	lea	opmregop_tbl(pc),a1
@@:
	moveq.l	#rltv_opm_regset_zmd,d0	*command code
	bsr	do_wrt_trk_b
	move.l	d2,d0
	add.b	(a1)+,d0
	bsr	do_wrt_trk_b		*reg number
	move.l	d1,d0
	bsr	do_wrt_trk_b		*data
	dbra	d3,@b
	rts

mml_control:			*[CONTROL]
	bsr	chk_num
	bpl	@f
	lea	control_name-work(a6),a1
	bsr	get_com_no
	bmi	m_illegal_control_number
	bra	get_ctrl_data
mml_y:				*Y コマンド
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
@@:
	bsr	get_num		*get register number
	cmp.l	#$ff,d1
	bhi	m_illegal_register_number
get_ctrl_data:
	move.l	d1,d2
	bsr	skip_sep	*skip ','
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
	bsr	get_num		*get data
	cmp.l	#$ff,d1
	bhi	m_illegal_parameter_value
	moveq.l	#reg_set_zmd,d0		*command code
	bsr	do_wrt_trk_b
	move.l	d2,d0
	bsr	do_wrt_trk_b	*reg number
	move.l	d1,d0
	bsr	do_wrt_trk_b	*data
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	rts

mml_h:				*モジュレーション波形のホールド
	moveq.l	#-1,d2
	bsr	chk_num
	bmi	mml_h2
	bsr	get_num
	moveq.l	#pmod_sync_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#$80,d0		*sync
	tst.l	d1		*switch value
	beq	@f
	moveq.l	#$00,d0		*hold
@@:
	bsr	do_wrt_trk_b
	moveq.l	#1,d0
	bsr	do_wrt_trk_w
	move.l	d1,d2
mml_h2:
	bsr	skip_sep	*skip ','
	moveq.l	#-1,d3
	bsr	chk_num
	bmi	1f
	bsr	get_num
	moveq.l	#arcc_sync_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#0,d0		*arcc no.
	bsr	do_wrt_trk_b
	moveq.l	#$80,d0		*sync
	tst.l	d1		*switch value
	beq	@f
	moveq.l	#$00,d0		*hold
@@:
	bsr	do_wrt_trk_b
	moveq.l	#1,d0
	bsr	do_wrt_trk_w
	move.l	d1,d3
1:
	move.l	d2,d0
	and.l	d3,d0
	bmi	m_illegal_parameters_combination	*両方省略はエラー
	bra	mml_lp

mml_m:				*モジュレーションモード選択
	moveq.l	#-1,d2
	bsr	chk_num
	bmi	@f
	bsr	get_num
	cmp.l	#2,d1
	bhi	m_illegal_mode_value	*規定外
	moveq.l	#pmod_mode_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d1,d0			*mode value
	subq.b	#1,d0			*-1,0,+1
	bsr	do_wrt_trk_b
	move.l	d1,d2
@@:
	moveq.l	#-1,d3
	bsr	skip_sep	*skip ','
	bsr	chk_num
	bmi	@f
	bsr	get_num
	cmp.l	#1,d1
	bhi	m_illegal_mode_value	*規定外
	moveq.l	#arcc_mode_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#0,d0			*arcc no.
	bsr	do_wrt_trk_b
	move.l	d1,d0			*mode value
	subq.b	#1,d0			*-1,0
	bsr	do_wrt_trk_b
	move.l	d1,d3
@@:
	move.l	d2,d0
	and.l	d3,d0
	bmi	m_illegal_parameters_combination	*両方省略はエラー
	bra	mml_lp

mml_vibrato_mode:			*[VIBRATO.MODE]
	bsr	chk_num
	bpl	@f
	lea	vib_mode-work(a6),a1
	bsr	get_com_no
	bmi	m_illegal_mode_value	*規定外
	move.l	d0,d1
	bra	do_wrt_mvm
@@:
	bsr	get_num
	cmp.l	#2,d1
	bhi	m_illegal_mode_value	*規定外
do_wrt_mvm:
	moveq.l	#pmod_mode_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d1,d0			*mode value
	subq.b	#1,d0			*-1,0,+1
	bra	do_wrt_trk_b

mml_arcc4_deepen:			*[ARCC4.DEEPEN]
	moveq.l	#arcc_deepen_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#6,d0			*arcc no.
	bsr	do_wrt_trk_b
	moveq.l	#0,d0			*dummy omt
	bsr	do_wrt_trk_b
	lea	do_wrt_trk_b(pc),a2
	bra	@f

mml_arcc3_deepen:			*[ARCC3.DEEPEN]
	moveq.l	#arcc_deepen_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#4,d0			*arcc no.
	bsr	do_wrt_trk_b
	moveq.l	#0,d0			*dummy omt
	bsr	do_wrt_trk_b
	lea	do_wrt_trk_b(pc),a2
	bra	@f

mml_arcc2_deepen:			*[ARCC2.DEEPEN]
	moveq.l	#arcc_deepen_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#2,d0			*arcc no.
	bsr	do_wrt_trk_b
	moveq.l	#0,d0			*dummy omt
	bsr	do_wrt_trk_b
	lea	do_wrt_trk_b(pc),a2
	bra	@f

mml_arcc1_deepen:			*[ARCC1.DEEPEN]
	moveq.l	#arcc_deepen_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#0,d0			*arcc no.
	bsr	do_wrt_trk_b
	moveq.l	#0,d0			*dummy omt
	bsr	do_wrt_trk_b
	lea	do_wrt_trk_b(pc),a2
	bra	@f

mml_velocity_deepen:			*[VELOCITY.DEEPEN]
	moveq.l	#vseq_deepen_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#0,d0			*dummy omt
	bsr	do_wrt_trk_b
	lea	do_wrt_trk_b(pc),a2
@@:
	move.l	tpt_now(a5),d5
	moveq.l	#$80,d6			*ON(omt)
	bsr	chk_num
	bpl	@f
	lea	vibdpn_strv-work(a6),a1
	bsr	get_com_no
	bmi	m_illegal_mode_value	*規定外
	tst.l	d0
	bne	@f
	moveq.l	#$00,d6
@@:					*get speed
	bsr	skip_sep
	bsr	chk_num
	bmi	@f
	bsr	get_num
	move.l	d1,d2
	beq	m_illegal_speed_value	*規定外
	cmp.l	#65535,d2
	bhi	m_illegal_speed_value	*規定外
	ori.b	#$40,d6
@@:					*get depth
	bsr	skip_sep
	bsr	chk_num
	bmi	mvd_get_repeat
	bsr	get_num
	cmpi.l	#-128,d1
	blt	m_illegal_depth_value
	cmpi.l	#127,d1
	bgt	m_illegal_depth_value
	move.l	d1,d3
	ori.b	#$20,d6
	bra	mvd_get_repeat

mml_agogik_deepen:			*[AGOGIK.DEEPEN]
	moveq.l	#agogik_deepen_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#0,d0			*dummy omt
	bsr	do_wrt_trk_b
	lea	do_wrt_trk_w(pc),a2
	bra	@f

mml_vibrato_deepen:			*[VIBRATO.DEEPEN]
	moveq.l	#pmod_deepen_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#0,d0			*dummy omt
	bsr	do_wrt_trk_b
	lea	do_wrt_trk_w(pc),a2
@@:
	move.l	tpt_now(a5),d5
	moveq.l	#$80,d6			*ON(omt)
	bsr	chk_num
	bpl	@f
	lea	vibdpn_strv-work(a6),a1
	bsr	get_com_no
	bmi	m_illegal_mode_value	*規定外
	tst.l	d0
	bne	@f
	moveq.l	#$00,d6
@@:					*get speed
	bsr	skip_sep
	bsr	chk_num
	bmi	mvd_get_dpn
	bsr	get_num
	move.l	d1,d2
	beq	m_illegal_speed_value	*規定外
	cmp.l	#65535,d2
	bhi	m_illegal_speed_value	*規定外
	ori.b	#$40,d6
mvd_get_dpn:				*get depth
	bsr	skip_sep
	bsr	chk_num
	bmi	mvd_get_repeat
	bsr	get_num
	cmpi.l	#-32768,d1
	blt	m_illegal_depth_value
	cmpi.l	#32767,d1
	bgt	m_illegal_depth_value
	move.l	d1,d3
	ori.b	#$20,d6
mvd_get_repeat:				*get repeat time
	bsr	skip_sep
	bsr	chk_num
	bpl	@f
	lea	vibdpnlp_strv-work(a6),a1
	bsr	get_com_no
	bmi	do_wrt_mvd
	moveq.l	#0,d1			*d1=0:loop
	ori.b	#$10,d6
	bra	do_wrt_mvd
@@:
	bsr	get_num
	cmpi.l	#32767,d1
	bhi	m_illegal_repeat_time
	ori.b	#$10,d6
do_wrt_mvd:
	move.l	tpt_addr(a5),a1
	move.b	d6,-1(a1,d5.l)		*set omt
	add.b	d6,d6
	bpl	@f
	move.l	d2,d0			*speed
	bsr	do_wrt_trk_v
@@:
	add.b	d6,d6
	bpl	@f
	move.l	d3,d0			*depth accelarator
	jsr	(a2)			*do_wrt_trk_w/do_wrt_trk_b
@@:
	add.b	d6,d6
	bpl	@f
	move.l	d1,d0
	bra	do_wrt_trk_v
@@:
	rts

mml_velocity_waveform:			*[VELOCITY.WAVEFORM]
	moveq.l	#0,d6			*omt
	bsr	chk_num
	bpl	@f
	lea	wvfm_tbl-work(a6),a1
	bsr	get_com_no
	bmi	m_illegal_wave_number	*規定外
	move.l	d0,d1
	ori.b	#1,d6			*set omt
	bra	1f
@@:
	bsr	get_num
	cmp.l	#wv_reg_max+wv_def_max-1,d1
	bhi	m_illegal_wave_number	*規定外
	ori.b	#1,d6			*set omt
	cmpi.b	#4,d1
	bls	1f
	cmpi.b	#7,d1
	bls	m_illegal_wave_number	*4～7はリザーブ
	subq.w	#8,d1
	ori.w	#$8000,d1		*ユーザー波形マーク
1:
	move.l	d1,d2
	bsr	skip_sep
	bsr	chk_num
	bmi	@f
	bsr	get_num			*基準点取得
	cmpi.l	#127,d1
	bhi	m_illegal_wave_origin
	move.l	d1,d3
	ori.b	#2,d6			*set omt
@@:
	bsr	skip_sep
	bsr	chk_num
	bmi	1f
	ori.b	#4,d6			*set omt
	bsr	get_num			*phase
	suba.l	a1,a1
	tst.l	d1
	beq	1f
	subq.w	#1,a1
1:
do_wrt_cseq_wf:
	tst.l	d6
	beq	m_illegal_parameters_combination	*全部省略はダメ
	moveq.l	#vseq_wf_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d6,d0			*omt
	bsr	do_wrt_trk_b
	lsr.b	#1,d6
	bcc	@f
	move.l	d2,d0			*wf number
	bsr	do_wrt_trk_w
@@:
	lsr.b	#1,d6
	bcc	@f
	move.l	d3,d0			*wf default
	bsr	do_wrt_trk_b
@@:
	lsr.b	#1,d6
	bcc	@f
	move.l	a1,d0			*phase
	bra	do_wrt_trk_b
@@:
	rts

mml_velocity_origin:			*[VELOCITY_ORIGIN]
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
	bsr	get_num			*基準点取得
	cmpi.l	#127,d1
	bhi	m_illegal_wave_origin
	move.l	d1,d3
	moveq.l	#2,d6			*set omt
	bra	do_wrt_cseq_wf

mml_velocity_phase:			*[VELOCITY_PHASE]
	bsr	chk_num
	bmi	@f
	bsr	get_num			*基準点取得
	tst.l	d1
	bra	1f
@@:
	lea	phase_tbl-work(a6),a1
	bsr	get_com_no
	bmi	m_undefined_phase_type
	moveq.l	#0,d1
	tst.l	d0
1:
	beq	@f
	moveq.l	#-1,d1
@@:
	move.l	d1,a1
	moveq.l	#4,d6			*set omt
	bra	do_wrt_cseq_wf

mml_agogik_waveform:			*[AGOGIK.WAVEFORM]
	moveq.l	#agogik_wf_zmd,d2
	bra	@f
mml_vibrato_waveform:			*[VIBRATO.WAVEFORM]
	moveq.l	#pmod_wf_zmd,d2
@@:
	bsr	chk_num
	bpl	@f
	lea	wvfm_tbl-work(a6),a1
	bsr	get_com_no
	bmi	m_illegal_wave_number	*規定外
	move.l	d0,d1
	bra	1f
@@:
	bsr	get_num
	cmp.l	#wv_reg_max+wv_def_max-1,d1
	bhi	m_illegal_wave_number	*規定外
	cmpi.b	#4,d1
	bls	1f
	cmpi.b	#7,d1
	bls	m_illegal_wave_number	*4～7はリザーブ
	subq.w	#8,d1
	ori.w	#$8000,d1		*ユーザー波形マーク
1:
	move.l	d2,d0
	bsr	do_wrt_trk_b
	move.l	d1,d0			*wf number
	bra	do_wrt_trk_w

mml_agogik_switch:			*[AGOGIK.SWITCH]
	move.l	#agogik8_zmd*65536+agogik_sw_zmd,d2
	bra	@f
mml_velocity_switch:			*[VELOCITY.SWITCH]
	move.l	#vseq8_zmd*65536+vseq_sw_zmd,d2
	bra	@f
mml_aftertouch_switch:			*[AFTERTOUCH.SWITCH]
	move.l	#aftertouch_zmd*65536+aftc_sw_zmd,d2
	bra	@f
mml_vibrato_switch:			*[VIBRATO.SWITCH]
	move.l	#pmod8_zmd*65536+pmod_sw_zmd,d2
@@:
	lea	switch_strv3-work(a6),a1
	bsr	get_com_no
	bmi	@f
	move.l	d0,d1			*0-4
	subq.b	#1,d1			*-1,0,1,2,3
	cmpi.b	#2,d1
	bls	do_wrt_mvs
	swap	d2
	move.l	d2,d0			*cmd
	bsr	do_wrt_trk_b
	moveq.l	#0,d0			*mode=omt=0
	bra	do_wrt_trk_w
@@:
	bsr	chk_num
	bmi	m_illegal_switch_value	*規定外
	bsr	get_num
	cmp.l	#-1,d1
	blt	m_illegal_switch_value	*規定外
	cmp.l	#2,d1
	bgt	m_illegal_switch_value	*規定外
do_wrt_mvs:
	move.l	d2,d0			*cmd
	bsr	do_wrt_trk_b
	move.l	d1,d0			*mode value
	bra	do_wrt_trk_b

mml_vibrato_sync:			*[VIBRATO.SYNC]
	bsr	chk_num
	bpl	@f
	lea	vib_sync-work(a6),a1
	bsr	get_com_no
	bmi	m_illegal_mode_value	*規定外
	move.l	d0,d1			*0/1
	bra	1f
@@:
	bsr	get_num
	cmp.l	#%11111,d1
	bhi	m_illegal_mode_value	*規定外
1:
	moveq.l	#pmod_sync_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#0,d0			*mode value
	moveq.l	#5-1,d2
@@:
	lsr.b	#1,d1
	roxl.b	#1,d0
	dbra	d2,@b
	lsl.b	#3,d0
	bra	get_sync_count
*-----------------------------------------------------------------------------
mml_aftertouch_sync:			*[AFTERTOUCH.SYNC]
	bsr	chk_num
	bpl	@f
	lea	vib_sync-work(a6),a1
	bsr	get_com_no
	bmi	m_illegal_mode_value	*規定外
	move.l	d0,d1			*0/1
	bra	1f
@@:
	bsr	get_num
	cmp.l	#%111,d1
	bhi	m_illegal_mode_value	*規定外
1:
	moveq.l	#aftc_sync_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#0,d0			*mode value
	moveq.l	#3-1,d2
@@:
	lsr.b	#1,d1
	roxl.b	#1,d0
	dbra	d2,@b
	lsl.b	#5,d0
	bra	get_sync_count
*-----------------------------------------------------------------------------
mml_agogik_sync:			*[AGOGIK.SYNC]
	bsr	chk_num
	bpl	@f
	lea	agogik_sync-work(a6),a1
	bsr	get_com_no
	bmi	m_illegal_mode_value	*規定外
	move.l	d0,d1
	bra	1f
@@:
	bsr	get_num
	cmp.l	#%0011_1111,d1
	bhi	m_illegal_mode_value	*規定外
1:
	moveq.l	#agogik_sync_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#0,d0			*mode value
	moveq.l	#6-1,d2
@@:
	lsr.b	#1,d1
	roxl.b	#1,d0
	dbra	d2,@b
	lsl.b	#2,d0
get_sync_count:
	bsr	do_wrt_trk_b
	bsr	skip_sep
	moveq.l	#0,d0
	bsr	chk_num
	bmi	do_wrt_trk_w
	bsr	get_num
	cmpi.l	#65535,d1
	bhi	m_illegal_parameter_value
	move.l	d1,d0
	beq	m_illegal_parameter_value
	bra	do_wrt_trk_w
*-----------------------------------------------------------------------------
mml_velocity_sync:			*[VELOCITY.SYNC]
	bsr	chk_num
	bpl	@f
	lea	vseq_sync-work(a6),a1
	bsr	get_com_no
	bmi	m_illegal_mode_value	*規定外
	move.l	d0,d1
	bra	1f
@@:
	bsr	get_num
	cmp.l	#%111,d1
	bhi	m_illegal_mode_value	*規定外
1:
	moveq.l	#vseq_sync_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#0,d0			*mode value
	moveq.l	#3-1,d2
@@:
	lsr.b	#1,d1
	roxl.b	#1,d0
	dbra	d2,@b
	lsl.b	#5,d0
	bra	get_sync_count
*-----------------------------------------------------------------------------
mml_arcc4_mode:				*[ARCC4.MODE]
	moveq.l	#6,d2			*arcc number
	bra	@f
mml_arcc3_mode:				*[ARCC3.MODE]
	moveq.l	#4,d2			*arcc number
	bra	@f
mml_arcc2_mode:				*[ARCC2.MODE]
	moveq.l	#2,d2			*arcc number
	bra	@f
mml_arcc1_mode:				*[ARCC1.MODE]
	moveq.l	#0,d2			*arcc number
@@:
	bsr	chk_num
	bpl	@f
	lea	arccmd_tbl-work(a6),a1
	bsr	get_com_no		*> d0=0:normal,1:special,2:enhanced
	bmi	m_illegal_mode_value	*規定外
	move.l	d0,d1
	cmpi.b	#2,d1
	bcs	do_wrt_mam
	moveq.l	#1,d1			*ENHANCEDはSPECIALと同値に
	bra	do_wrt_mam
@@:
	bsr	get_num
	cmp.l	#1,d1
	bhi	m_illegal_mode_value	*規定外
do_wrt_mam:
	moveq.l	#arcc_mode_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d2,d0			*arcc number(0-3)*2
	bsr	do_wrt_trk_b
	move.l	d1,d0			*mode value
	subq.b	#1,d0			*-1,0
	bra	do_wrt_trk_b

mml_arcc4_switch:			*[ARCC4.SWITCH]
	moveq.l	#6,d2			*arcc number
	bra	@f
mml_arcc3_switch:			*[ARCC3.SWITCH]
	moveq.l	#4,d2			*arcc number
	bra	@f
mml_arcc2_switch:			*[ARCC2.SWITCH]
	moveq.l	#2,d2			*arcc number
	bra	@f
mml_arcc1_switch:			*[ARCC1.SWITCH]
	moveq.l	#0,d2			*arcc number
@@:
	lea	switch_strv3-work(a6),a1
	bsr	get_com_no
	bmi	@f
	move.l	d0,d1			*0-4
	subq.b	#1,d1			*-1,0,1,2,3
	cmpi.b	#2,d1
	bls	do_wrt_mas
	moveq.l	#arcc8_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d2,d0			*arcc number(0-3)*2
	bsr	do_wrt_trk_b
	moveq.l	#0,d0			*mode=omt=0
	bra	do_wrt_trk_w
@@:
	bsr	chk_num
	bmi	m_illegal_switch_value	*規定外
	bsr	get_num
	cmp.l	#-1,d1
	blt	m_illegal_switch_value	*規定外
	cmp.l	#2,d1
	bgt	m_illegal_switch_value	*規定外
do_wrt_mas:
	moveq.l	#arcc_sw_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d2,d0			*arcc number(0-3)*2
	bsr	do_wrt_trk_b
	move.l	d1,d0			*mode value
	bra	do_wrt_trk_b

mml_arcc4_sync:				*[ARCC4_SYNC]
	moveq.l	#6,d2			*arcc number
	bra	@f
mml_arcc3_sync:				*[ARCC3_SYNC]
	moveq.l	#4,d2			*arcc number
	bra	@f
mml_arcc2_sync:				*[ARCC2_SYNC]
	moveq.l	#2,d2			*arcc number
	bra	@f
mml_arcc1_sync:				*[ARCC1_SYNC]
	moveq.l	#0,d2			*arcc number
@@
	bsr	chk_num
	bpl	@f
	lea	arcc_sync-work(a6),a1
	bsr	get_com_no
	bmi	m_illegal_mode_value	*規定外
	move.l	d0,d1
	bra	do_wrt_masy
@@:
	bsr	get_num
	cmp.l	#%11111,d1
	bhi	m_illegal_mode_value	*規定外
do_wrt_masy:
	moveq.l	#arcc_sync_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d2,d0			*arcc number(0-3)
	bsr	do_wrt_trk_b
	moveq.l	#0,d0			*mode value
	moveq.l	#5-1,d2
@@:
	lsr.b	#1,d1
	roxl.b	#1,d0
	dbra	d2,@b
	lsl.b	#3,d0
	bra	get_sync_count
*-----------------------------------------------------------------------------
mml_s:				*モジュレーション波形タイプ
	moveq.l	#-1,d2
	bsr	chk_num
	bmi	mmls_ar
	bsr	get_num
	cmp.l	#wv_reg_max+wv_def_max-1,d1
	bhi	m_illegal_wave_number	*規定外
	cmpi.b	#4,d1
	bls	@f
	cmpi.b	#7,d1
	bls	m_illegal_wave_number	*4～7はリザーブ
	subq.w	#8,d1
	ori.w	#$8000,d1
@@:
	moveq.l	#pmod_wf_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d1,d0			*wf number
	bsr	do_wrt_trk_w
	move.l	d1,d2
mmls_ar:
	moveq.l	#-1,d3
	bsr	skip_sep	*skip ','
	bsr	chk_num
	bmi	mmls_ar2
	bsr	get_num
	cmp.l	#wv_reg_max+wv_def_max-1,d1
	bhi	m_illegal_wave_number	*規定外
	cmpi.b	#4,d1
	bls	@f
	cmpi.b	#7,d1
	bls	m_illegal_wave_number	*4～7はリザーブ
	subq.w	#8,d1
	ori.w	#$8000,d1
@@:
	moveq.l	#arcc_wf_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#0,d0			*arcc no.
	bsr	do_wrt_trk_b
	move.l	d1,d0			*wf number
	bsr	do_wrt_trk_w
	move.l	d1,d3
mmls_ar2:
	move.l	d2,d0
	and.l	d3,d0
	bmi	m_illegal_parameters_combination	*両方省略はダメ
	bra	mml_lp

renp_start:					*連符スタート
	bset.b	#c_renp1,tpt_mode_flg(a5)	*mark	*音長はstep,gateともにワード長に
	bne	m_group_notes_command_error	*連符コマンド内で連符指定はできない
	clr.l	tpt_renp_cnt(a5)
	move.l	a4,tpt_renp_starta4(a5)
	movem.l	d0/d2-d3/a0-a2,-(sp)
	move.l	tpt_renp_addr(a5),d0
	bne	@f
	move.l	#(tpt_tsize+3).and.$ffff_fffc,d2
	move.l	#ID_TEMP,d3
	jsr	get_mem-work(a6)
	tst.l	d0
	bmi	error_irc
	move.l	a0,tpt_renp_addr(a5)
	move.l	a0,a2
	bra	irc00
@@:
	move.l	d0,a2
irc00:
	move.l	a5,a1
	move.w	#((tpt_tsize+3).and.$ffff_fffc)/4-1,d2
@@:
	move.l	(a1)+,(a2)+
	dbra	d2,@b
	movem.l	(sp)+,d0/d2-d3/a0-a2
	bra	mml_lp				*その音符の音長のアドレスを格納する

error_irc:
	clr.b	tpt_mode_flg(a5)
	bra	m_out_of_memory

renp_end:					*連符エンド
	bclr.b	#c_renp2,tpt_mode_flg(a5)
	bne	renp_phase2_end
	bclr.b	#c_renp1,tpt_mode_flg(a5)
	bne	@f
	tst.b	now_cmd-work(a6)
	bmi	mmlc_exit
	bra	m_syntax_error
@@:
	btst.b	#c_break,tpt_mode_flg(a5)	*コンパイル中断フラグチェック
	bne	go_skip_mml
	bsr	chk_num
	bpl	rp_get_l		指定してある時…
	cmp.l	a4,d4
	bls	m_parameter_shortage
	cmpi.b	#DIRECT_LEN,(a4)	*'*'
	bne	@f
	addq.w	#1,a4			*skip '*'
	bsr	get_num			*get 連符音長
	cmpi.l	#max_note_len,d1
	bhi	m_illegal_note_length	*illegal length
	move.l	d1,d0
	bra	_renp_ed1
@@:
	moveq.l	#0,d0
	move.w	tpt_note_len(a5),d0	*音長省略のケース
	bra	_renp_ed1
rp_get_l:				*音長が指定してあるケース
	bsr	get_length
	bsr	futen_ope
	move.l	d1,d0
	andi.l	#$ffff,d0
_renp_ed1:
	move.l	tpt_renp_cnt(a5),d1	*number of keycodes
	beq	m_empty_brace_error	*there is no keycode inside!
	cmp.l	d1,d0
	bcs	m_too_many_notes	*too many keycodes inside!
	divu	d1,d0
	move.l	tpt_renp_addr(a5),a1
	move.l	tpt_renp_starta4(a1),d3	*get renp start addr.
	beq	m_empty_brace_error	*there is no keycode inside!
	exg.l	d3,a4
*!	subq.l	#1,a4
	move.l	a5,a2
	move.w	#((tpt_tsize+3).and.$ffff_fffc)/4-1,d2
@@:
	move.l	(a2),d1			*swap (a1)+,(a2)+
	move.l	(a1),(a2)+
	move.l	d1,(a1)+
	dbra	d2,@b
	move.l	d3,tpt_renp_starta4(a5)
	move.l	d0,tpt_renp_surplus(a5)	*tpt_renp_surplus,tpt_renp_length
	bclr.b	#c_renp1,tpt_mode_flg(a5)
	bset.b	#c_renp2,tpt_mode_flg(a5)
	bra	mml_lp

renp_phase2_end:				*連符処理すべて完了
	move.l	tpt_renp_starta4(a5),a4
	move.l	tpt_renp_addr(a5),a1
	move.w	tpt_velo_n(a5),d0
	move.l	tpt_now(a5),d1
	move.l	a5,a2
	move.w	#((tpt_tsize+3).and.$ffff_fffc)/4-1,d2
@@:
	move.l	(a1)+,(a2)+
	dbra	d2,@b
	move.l	d1,tpt_now(a5)
	move.w	d0,tpt_velo_n(a5)
	bra	mml_lp

*num_of_seq:	equ	(_cmd_tbl_end-_cmd_tbl)/2	*幾つのコマンドがあるか
mml_seq_command:					*[]コマンド
	cmp.l	a4,d4
	bls	m_syntax_error		*error
	cmpi.b	#'/',(a4)
	bne	@f
	addq.w	#1,a4			*[/] case
	bsr	mml_compile_break_off
	bra	1f
@@:
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_syntax_error		*error
	cmpi.b	#'-',(a4)
	beq	case_mml_bar		*[---....]のケース
	lea	seq_com_tbl-work(a6),a1
	move.l	a4,d7			*mml_port_にいくために...
	bsr	get_com_no		*>d0.l=cmd number(0-)
	bmi	mml_port_		*ポルタメントとみなす
	st	seq_cmd-work(a6)
	bsr	skip_spc
	add.w	d0,d0
	move.w	_cmd_tbl(pc,d0.w),d0
	jsr	_cmd_tbl(pc,d0.w)
1:
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_illegal_command_line	*']'がない
	cmpi.b	#']',(a4)+
	bne	m_illegal_command_line	*']'がない
	bsr	chk_num			*']'の後ろに数値があればそれはステップタイムとみなす
	bpl	mml_@w
	cmp.l	a4,d4
	bls	mml_lp
	cmpi.b	#'*',(a4)
	beq	mml_@w
	bra	mml_lp

_cmd_tbl:
	dc.w	mml_jump-_cmd_tbl			*[!]
	dc.w	mml_segno-_cmd_tbl			*[$]
	dc.w	mml_tocoda-_cmd_tbl			*[*]
	dc.w	mml_compile_break_off-_cmd_tbl		*[/]
	dc.w	mml_@detune-_cmd_tbl			*[@DETUNE]
	dc.w	mml_@panpot-_cmd_tbl			*[@PANPOT]
	dc.w	mml_@pitch-_cmd_tbl			*[@PITCH]
	dc.w	mml_@tempo-_cmd_tbl			*[@TEMPO]
	dc.w	mml_@velocity-_cmd_tbl			*[@VELOCITY]
	dc.w	mml_@volume-_cmd_tbl			*[@VOLUME]
	dc.w	mml_jump2-_cmd_tbl			*[@]
	dc.w	mml_aftertouch_delay-_cmd_tbl		*[AFTERTOUCH.DELAY]
	dc.w	mml_aftertouch_level-_cmd_tbl		*[AFTERTOUCH.LEVEL]
	dc.w	mml_aftertouch_switch-_cmd_tbl		*[AFTERTOUCH.SWITCH]
	dc.w	mml_aftertouch_sync-_cmd_tbl		*[AFTERTOUCH.SYNC]
	dc.w	mml_agogik_deepen-_cmd_tbl		*[AGOGIK.DEEPEN]
	dc.w	mml_agogik_delay-_cmd_tbl		*[AGOGIK.DELAY]
	dc.w	mml_agogik_depth-_cmd_tbl		*[AGOGIK.DEPTH]
	dc.w	mml_agogik_depth-_cmd_tbl		*[AGOGIK.LEVEL]
	dc.w	mml_agogik_speed-_cmd_tbl		*[AGOGIK.SPEED]
	dc.w	mml_agogik_switch-_cmd_tbl		*[AGOGIK.SWITCH]
	dc.w	mml_agogik_sync-_cmd_tbl		*[AGOGIK.SYNC]
	dc.w	mml_agogik_waveform-_cmd_tbl		*[AGOGIK.WAVEFORM]
	dc.w	mml_all_sound_off-_cmd_tbl		*[ALL_SOUND_OFF]
	dc.w	mml_arcc1_control-_cmd_tbl		*[ARCC1.CONTROL]
	dc.w	mml_arcc2_control-_cmd_tbl		*[ARCC2.CONTROL]
	dc.w	mml_arcc3_control-_cmd_tbl		*[ARCC3.CONTROL]
	dc.w	mml_arcc4_control-_cmd_tbl		*[ARCC4.CONTROL]
	dc.w	mml_arcc1_deepen-_cmd_tbl		*[ARCC1.DEEPEN]
	dc.w	mml_arcc2_deepen-_cmd_tbl		*[ARCC2.DEEPEN]
	dc.w	mml_arcc3_deepen-_cmd_tbl		*[ARCC3.DEEPEN]
	dc.w	mml_arcc4_deepen-_cmd_tbl		*[ARCC4.DEEPEN]
	dc.w	mml_arcc1_delay-_cmd_tbl		*[ARCC1.DELAY]
	dc.w	mml_arcc2_delay-_cmd_tbl		*[ARCC2.DELAY]
	dc.w	mml_arcc3_delay-_cmd_tbl		*[ARCC3.DELAY]
	dc.w	mml_arcc4_delay-_cmd_tbl		*[ARCC4.DELAY]
	dc.w	mml_arcc1_depth-_cmd_tbl		*[ARCC1.DEPTH]
	dc.w	mml_arcc2_depth-_cmd_tbl		*[ARCC2.DEPTH]
	dc.w	mml_arcc3_depth-_cmd_tbl		*[ARCC3.DEPTH]
	dc.w	mml_arcc4_depth-_cmd_tbl		*[ARCC4.DEPTH]
	dc.w	mml_arcc1_depth-_cmd_tbl		*[ARCC1.LEVEL]
	dc.w	mml_arcc2_depth-_cmd_tbl		*[ARCC2.LEVEL]
	dc.w	mml_arcc3_depth-_cmd_tbl		*[ARCC3.LEVEL]
	dc.w	mml_arcc4_depth-_cmd_tbl		*[ARCC4.LEVEL]
	dc.w	mml_arcc1_mode-_cmd_tbl			*[ARCC1.MODE]
	dc.w	mml_arcc2_mode-_cmd_tbl			*[ARCC2.MODE]
	dc.w	mml_arcc3_mode-_cmd_tbl			*[ARCC3.MODE]
	dc.w	mml_arcc4_mode-_cmd_tbl			*[ARCC4.MODE]
	dc.w	mml_arcc1_origin-_cmd_tbl		*[ARCC1.ORIGIN]
	dc.w	mml_arcc2_origin-_cmd_tbl		*[ARCC2.ORIGIN]
	dc.w	mml_arcc3_origin-_cmd_tbl		*[ARCC3.ORIGIN]
	dc.w	mml_arcc4_origin-_cmd_tbl		*[ARCC4.ORIGIN]
	dc.w	mml_arcc1_phase-_cmd_tbl		*[ARCC1.PHASE]
	dc.w	mml_arcc2_phase-_cmd_tbl		*[ARCC2.PHASE]
	dc.w	mml_arcc3_phase-_cmd_tbl		*[ARCC3.PHASE]
	dc.w	mml_arcc4_phase-_cmd_tbl		*[ARCC4.PHASE]
	dc.w	mml_arcc1_reset-_cmd_tbl		*[ARCC1.RESET]
	dc.w	mml_arcc2_reset-_cmd_tbl		*[ARCC2.RESET]
	dc.w	mml_arcc3_reset-_cmd_tbl		*[ARCC3.RESET]
	dc.w	mml_arcc4_reset-_cmd_tbl		*[ARCC4.RESET]
	dc.w	mml_arcc1_speed-_cmd_tbl		*[ARCC1.SPEED]
	dc.w	mml_arcc2_speed-_cmd_tbl		*[ARCC2.SPEED]
	dc.w	mml_arcc3_speed-_cmd_tbl		*[ARCC3.SPEED]
	dc.w	mml_arcc4_speed-_cmd_tbl		*[ARCC4.SPEED]
	dc.w	mml_arcc1_switch-_cmd_tbl		*[ARCC1.SWITCH]
	dc.w	mml_arcc2_switch-_cmd_tbl		*[ARCC2.SWITCH]
	dc.w	mml_arcc3_switch-_cmd_tbl		*[ARCC3.SWITCH]
	dc.w	mml_arcc4_switch-_cmd_tbl		*[ARCC4.SWITCH]
	dc.w	mml_arcc1_sync-_cmd_tbl			*[ARCC1.SYNC]
	dc.w	mml_arcc2_sync-_cmd_tbl			*[ARCC2.SYNC]
	dc.w	mml_arcc3_sync-_cmd_tbl			*[ARCC3.SYNC]
	dc.w	mml_arcc4_sync-_cmd_tbl			*[ARCC4.SYNC]
	dc.w	mml_arcc1_waveform-_cmd_tbl		*[ARCC1.WAVEFORM]
	dc.w	mml_arcc2_waveform-_cmd_tbl		*[ARCC2.WAVEFORM]
	dc.w	mml_arcc3_waveform-_cmd_tbl		*[ARCC3.WAVEFORM]
	dc.w	mml_arcc4_waveform-_cmd_tbl		*[ARCC4.WAVEFORM]
	dc.w	mml_ch_assign-_cmd_tbl			*[ASSIGN]
	dc.w	mml_auto_portament_switch-_cmd_tbl	*[AUTO_PORTAMENT.SWITCH]
	dc.w	mml_auto_portament-_cmd_tbl		*[AUTO_PORTAMENT]
	dc.w	mml_measure-_cmd_tbl			*[BAR]
	dc.w	mml_bend_range-_cmd_tbl			*[BEND.RANGE]
	dc.w	mml_bend_switch-_cmd_tbl		*[BEND.SWITCH]
	dc.w	mml_bend-_cmd_tbl			*[BEND]
	dc.w	mml_ch_assign-_cmd_tbl			*[CH_ASSIGN]
	dc.w	mml_ch_fader-_cmd_tbl			*[CH_FADER]
	dc.w	mml_ch_pressure-_cmd_tbl		*[CH_PRESSURE]
	dc.w	mml_coda-_cmd_tbl			*[CODA]
	dc.w	mml_comment-_cmd_tbl			*[COMMENT]
	dc.w	mml_control-_cmd_tbl			*[CONTROL]
	dc.w	mml_damper-_cmd_tbl			*[DAMPER]
	dc.w	mml_detune-_cmd_tbl			*[DETUNE]
	dc.w	mml_dc-_cmd_tbl				*[D.C.]
	dc.w	mml_ds-_cmd_tbl				*[D.S.]
	dc.w	mml_do-_cmd_tbl				*[DO]
	dc.w	mml_dummy-_cmd_tbl			*[DUMMY]
	dc.w	mml_echo-_cmd_tbl			*[ECHO]
	dc.w	mml_effect_chorus-_cmd_tbl		*[EFFECT.CHORUS]
	dc.w	mml_effect_delay-_cmd_tbl		*[EFFECT.DELAY]
	dc.w	mml_effect_reverb-_cmd_tbl		*[EFFECT.REVERB]
	dc.w	mml_effect-_cmd_tbl			*[EFFECT]
	dc.w	mml_embed-_cmd_tbl			*[EMBED]
	dc.w	mml_end-_cmd_tbl			*[END]
	dc.w	mml_event-_cmd_tbl			*[EVENT]
	dc.w	mml_exclusive-_cmd_tbl			*[EXCLUSIOVE]
	dc.w	mml_fine-_cmd_tbl			*[FINE]
	dc.w	mml_frequency-_cmd_tbl			*[FREQUENCY]
	dc.w	mml_gm_system_on-_cmd_tbl		*[GM_SYSTEM_ON]
	dc.w	mml_gs_chorus-_cmd_tbl			*[GS_CHORUS]
	dc.w	mml_gs_display-_cmd_tbl			*[GS_DISPLAY]
	dc.w	mml_gs_drum_setup-_cmd_tbl		*[GS_DRUM_SETUP]
	dc.w	mml_gs_drum_setup-_cmd_tbl		*[GS_DRUM_PARAMETER]
	dc.w	mml_gs_drum_name-_cmd_tbl		*[GS_DRUM_NAME]
	dc.w	mml_gs_reset-_cmd_tbl			*[GS_INIT]
	dc.w	mml_gs_partial_reserve-_cmd_tbl		*[GS_PARTIAL_RESERVE]
	dc.w	mml_gs_part_setup-_cmd_tbl		*[GS_PART_SETUP]
	dc.w	mml_gs_part_setup-_cmd_tbl		*[GS_PART_PARAMETER]
	dc.w	mml_gs_print-_cmd_tbl			*[GS_PRINT]
	dc.w	mml_gs_reset-_cmd_tbl			*[GS_RESET]
	dc.w	mml_gs_reverb-_cmd_tbl			*[GS_REVERB]
	dc.w	mml_gs_partial_reserve-_cmd_tbl		*[GS_V_RESERVE]
	dc.w	mml_instrument_id-_cmd_tbl		*[INSTRUMENT_ID]
	dc.w	mml_measure_jump-_cmd_tbl		*[JUMP]
	dc.w	mml_k_signature-_cmd_tbl		*[K.SIGN]
	dc.w	mml_k_remap-_cmd_tbl			*[KEY_REMAP]
	dc.w	mml_k_signature-_cmd_tbl		*[KEY_SIGNATURE]
	dc.w	mml_key-_cmd_tbl			*[KEY]
	dc.w	mml_loop-_cmd_tbl			*[LOOP]
	dc.w	mml_m1_effect_setup-_cmd_tbl		*[M1_EFFECT_SETUP]
	dc.w	mml_m1_setup-_cmd_tbl			*[M1_MIDI_CH]
	dc.w	mml_m1_part_setup-_cmd_tbl		*[M1_PART_SETUP]
	dc.w	mml_m1_print-_cmd_tbl			*[M1_PRINT]
	dc.w	mml_m1_setup-_cmd_tbl			*[M1_SETUP]
	dc.w	mml_master_fader-_cmd_tbl		*[MASTER_FADER]
	dc.w	mml_measure-_cmd_tbl			*[MEASURE]
	dc.w	mml_meter-_cmd_tbl			*[METER]
	dc.w	mml_midi_data-_cmd_tbl			*[MIDI_DATA]
	dc.w	mml_mt32_common-_cmd_tbl		*[MT32_COMMON]
	dc.w	mml_mt32_drum_setup-_cmd_tbl		*[MT32_DRUM_SETUP]
	dc.w	mml_mt32_reset-_cmd_tbl			*[MT32_INIT]
	dc.w	mml_mt32_partial_reserve-_cmd_tbl	*[MT32_PARTIAL_RESERVE]
	dc.w	mml_mt32_partial-_cmd_tbl		*[MT32_PARTIAL]
	dc.w	mml_mt32_part_setup-_cmd_tbl		*[MT32_PART_SETUP]
	dc.w	mml_mt32_patch-_cmd_tbl			*[MT32_PATCH]
	dc.w	mml_mt32_partial_reserve-_cmd_tbl	*[MT32_P_RESERVE]
	dc.w	mml_mt32_print-_cmd_tbl			*[MT32_PRINT]
	dc.w	mml_mt32_reset-_cmd_tbl			*[MT32_RESET]
	dc.w	mml_mt32_reverb-_cmd_tbl		*[MT32_REVERB]
	dc.w	mml_mt32_drum_setup-_cmd_tbl		*[MT32_RHYTHM_SETUP]
	dc.w	mml_mute-_cmd_tbl			*[MUTE]
	dc.w	mml_noise-_cmd_tbl			*[NOISE]
	dc.w	mml_nrpn-_cmd_tbl			*[NRPN]
	dc.w	mml_opm_lfo-_cmd_tbl			*[OPM.LFO]
	dc.w	mml_opm-_cmd_tbl			*[OPM]
	dc.w	mml_panpot-_cmd_tbl			*[PANPOT]
	dc.w	mml_pattern-_cmd_tbl			*[PATTERN]
	dc.w	mml_pcm_mode-_cmd_tbl			*[PCM_MODE]
	dc.w	mml_pitch-_cmd_tbl			*[PITCH]
	dc.w	mml_poke-_cmd_tbl			*[POKE]
	dc.w	mml_polyphonic_pressure-_cmd_tbl	*[POLYPHONIC_PRESSURE]
	dc.w	mml_push_portament-_cmd_tbl		*[PUSH_PORTAMENT]
	dc.w	mml_pull_portament-_cmd_tbl		*[PULL_PORTAMENT]
	dc.w	mml_portament-_cmd_tbl			*[PORTAMENT]
	dc.w	mml_program_bank-_cmd_tbl		*[PROGRAM_BANK]
	dc.w	mml_timbre_split_switch-_cmd_tbl	*[PROGRAM_SPLIT.SWITCH]
	dc.w	mml_timbre_split-_cmd_tbl		*[PROGRAM_SPLIT]
	dc.w	mml_timbre2-_cmd_tbl			*[PROGRAM]
	dc.w	mml_replay-_cmd_tbl			*[REPLAY]
	dc.w	mml_roland_exclusive-_cmd_tbl		*[ROLAND_EXCLUSIVE]
	dc.w	mml_gs_chorus-_cmd_tbl			*[SC55_CHORUS]
	dc.w	mml_gs_display-_cmd_tbl			*[SC55_DISPLAY]
	dc.w	mml_gs_drum_setup-_cmd_tbl		*[SC55_DRUM_SETUP]
	dc.w	mml_gs_drum_setup-_cmd_tbl		*[SC55_DRUM_PARAMETER]
	dc.w	mml_gs_drum_name-_cmd_tbl		*[SC55_DRUM_NAME]
	dc.w	mml_gs_reset-_cmd_tbl			*[SC55_INIT]
	dc.w	mml_gs_partial_reserve-_cmd_tbl		*[SC55_PARTIAL_RESERVE]
	dc.w	mml_gs_part_setup-_cmd_tbl		*[SC55_PART_SETUP]
	dc.w	mml_gs_part_setup-_cmd_tbl		*[SC55_PART_PARAMETER]
	dc.w	mml_gs_print-_cmd_tbl			*[SC55_PRINT]
	dc.w	mml_gs_reverb-_cmd_tbl			*[SC55_REVERB]
	dc.w	mml_gs_reset-_cmd_tbl			*[SC55_RESET]
	dc.w	mml_gs_partial_reserve-_cmd_tbl		*[SC55_V_RESERVE]
	dc.w	mml_sc88_mode-_cmd_tbl			*[SC88_MODE_SET]
	dc.w	mml_sc88_mode-_cmd_tbl			*[SC88_MODE]
	dc.w	mml_sc88_reverb-_cmd_tbl		*[SC88_REVERB]
	dc.w	mml_sc88_chorus-_cmd_tbl		*[SC88_CHORUS]
	dc.w	mml_sc88_delay-_cmd_tbl			*[SC88_DELAY]
	dc.w	mml_sc88_equalizer-_cmd_tbl		*[SC88_EQUALIZER]
	dc.w	mml_sc88_part_setup-_cmd_tbl		*[SC88_PART_SETUP]
	dc.w	mml_sc88_part_setup-_cmd_tbl		*[SC88_PART_PARAMETER]
	dc.w	mml_sc88_drum_setup-_cmd_tbl		*[SC88_DRUM_SETUP]
	dc.w	mml_sc88_drum_setup-_cmd_tbl		*[SC88_DRUM_PARAMETER]
	dc.w	mml_sc88_drum_name-_cmd_tbl		*[SC88_DRUM_NAME]
	dc.w	mml_sc88_user_inst-_cmd_tbl		*[SC88_USER_INST]
	dc.w	mml_sc88_user_drum-_cmd_tbl		*[SC88_USER_DRUM]
	dc.w	mml_segno-_cmd_tbl			*[SEGNO]
	dc.w	mml_send_to_m1-_cmd_tbl			*[SEND_TO_M1]
	dc.w	mml_slot_separation-_cmd_tbl		*[SLOT_SEPARATION]
	dc.w	mml_stop-_cmd_tbl			*[STOP]
	dc.w	mml_synchronize-_cmd_tbl		*[SYNCHRONIZE]
	dc.w	mml_tempo-_cmd_tbl			*[TEMPO]
	dc.w	mml_tie_mode-_cmd_tbl			*[TIE_MODE]
	dc.w	mml_timer-_cmd_tbl			*[TIMER]
	dc.w	mml_program_bank-_cmd_tbl		*[TIMBRE_BANK]
	dc.w	mml_timbre_split_switch-_cmd_tbl	*[TIMBRE_SPLIT.SWITCH]
	dc.w	mml_timbre_split-_cmd_tbl		*[TIMBRE_SPLIT]
	dc.w	mml_timbre2-_cmd_tbl			*[TIMBRE]
	dc.w	mml_tocoda-_cmd_tbl			*[TOCODA]
	dc.w	mml_track_delay-_cmd_tbl		*[TRACK_DELAY]
	dc.w	mml_track_fader-_cmd_tbl		*[TRACK_FADER]
	dc.w	mml_track_mode-_cmd_tbl			*[TRACK_MODE]
	dc.w	mml_u220_common-_cmd_tbl		*[U220_COMMON]
	dc.w	mml_u220_drum_inst-_cmd_tbl		*[U220_DRUM_INST]
	dc.w	mml_u220_drum_setup-_cmd_tbl		*[U220_DRUM_SETUP]
	dc.w	mml_u220_part_setup-_cmd_tbl		*[U220_PART_SETUP]
	dc.w	mml_u220_print-_cmd_tbl			*[U220_PRINT]
	dc.w	mml_u220_setup-_cmd_tbl			*[U220_SETUP]
	dc.w	mml_u220_timbre-_cmd_tbl		*[U220_TIMBRE]
	dc.w	mml_velocity_deepen-_cmd_tbl		*[VELOCITY.DEEPEN]
	dc.w	mml_velocity_delay-_cmd_tbl		*[VELOCITY.DELAY]
	dc.w	mml_velocity_depth-_cmd_tbl		*[VELOCITY.DEPTH]
	dc.w	mml_velocity_depth-_cmd_tbl		*[VELOCITY.LEVEL]
	dc.w	mml_velocity_origin-_cmd_tbl		*[VELOCITY.ORIGIN]
	dc.w	mml_velocity_phase-_cmd_tbl		*[VELOCITY.PHASE]
	dc.w	mml_velocity_speed-_cmd_tbl		*[VELOCITY.SPEED]
	dc.w	mml_velocity_switch-_cmd_tbl		*[VELOCITY.SWITCH]
	dc.w	mml_velocity_sync-_cmd_tbl		*[VELOCITY.SYNC]
	dc.w	mml_velocity_waveform-_cmd_tbl		*[VELOCITY.WAVEFORM]
	dc.w	mml_velocity-_cmd_tbl			*[VELOCITY]
	dc.w	mml_vibrato_deepen-_cmd_tbl		*[VIBRATO.DEEPEN]
	dc.w	mml_vibrato_delay-_cmd_tbl		*[VIBRATO.DELAY]
	dc.w	mml_vibrato_depth-_cmd_tbl		*[VIBRATO.DEPTH]
	dc.w	mml_vibrato_mode-_cmd_tbl		*[VIBRATO.MODE]
	dc.w	mml_vibrato_speed-_cmd_tbl		*[VIBRATO.SPEED]
	dc.w	mml_vibrato_switch-_cmd_tbl		*[VIBRATO.SWITCH]
	dc.w	mml_vibrato_sync-_cmd_tbl		*[VIBRATO.SYNC]
	dc.w	mml_vibrato_waveform-_cmd_tbl		*[VIBRATO.WAVEFORM]
	dc.w	mml_voice_reserve-_cmd_tbl		*[VOICE_RESERVE]
	dc.w	mml_volume-_cmd_tbl			*[VOLUME]
	dc.w	mml_yamaha_exclusive-_cmd_tbl		*[YAMAHA_BULKDUMP]
	dc.w	mml_yamaha_exclusive-_cmd_tbl		*[YAMAHA_EXCLUSIVE]
	dc.w	mml_fine-_cmd_tbl			*[^]
_cmd_tbl_end:
mml_dc:
	moveq.l	#DC_zmd,d1
	bra	@f
mml_do:
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_illegal_command_line	*']'がない
	cmpi.b	#']',(a4)
	beq	@f
	move.l	d7,a4			*ポルタメントとみなす
	addq.w	#4,sp
	bra	mml_port_
@@:
	moveq.l	#DO_zmd,d1
	bra	@f
mml_jump:
	tst.b	jump_cmd_ctrl-work(a6)
	beq	exit_seq_cmd
	moveq.l	#J1_zmd,d1
	bset.b	#6,compile_status-work(a6)	*[@]/[!]を使用したことをマーク
	bra	@f
mml_jump2:
	tst.b	jump_cmd_ctrl-work(a6)
	beq	exit_seq_cmd
	moveq.l	#J2_zmd,d1
	bset.b	#6,compile_status-work(a6)	*[@]/[!]を使用したことをマーク
@@:
	moveq.l	#seq_cmd_zmd,d0		*command code
	bsr	do_wrt_trk_b
	move.l	d1,d0
	bsr	do_wrt_trk_b
	moveq.l	#0,d0
	bra	do_wrt_trk_b
exit_seq_cmd:
	rts

mml_segno:				*[segno]
	moveq.l	#0,d1			*default no.
	bsr	chk_num
	bmi	@f			*[segno]は[segno0]とみなす
	bsr	get_num			*[segno n]ケース
@@:
	moveq.l	#segno_zmd,d0
	bsr	do_wrt_trk_b
	bsr	push_segno_addr		*アドレス登録
	moveq.l	#0,d0
	bra	do_wrt_trk_l

mml_ds:					*[d.s.]
	moveq.l	#0,d1			*default no.
	bsr	chk_num
	bmi	@f			*[d.s.]は[d.s.0]とみなす
	bsr	get_num			*[d.s. n]ケース
@@:
	moveq.l	#ds_zmd,d0
	bsr	do_wrt_trk_b		*cmd
	bsr	pop_segno_addr		*次の[flag]アドレスを[segno]が指すようにする
mlds00:
	bsr	rgst_flag_map		*[loop]処理時に初期化するワークとして登録
	moveq.l	#0,d0
	bsr	do_wrt_trk_b		*flag
	move.l	a1,d0
	move.l	tpt_now(a5),d1
	sub.l	a1,d1
	subq.l	#5,d1			*sizeof[offset(l)]+1=5
	add.l	tpt_addr(a5),a1		*d1.l=segnoからd.s.フラグまでのオフセット
	rept	4
	rol.l	#8,d1
	move.b	d1,(a1)+
	endm
	sub.l	tpt_now(a5),d0		*d0.l=d.s.からsegnoの次までのオフセット
	bra	do_wrt_trk_l		*offset

mml_coda:				*[coda]
	moveq.l	#0,d1			*default no.
	bsr	chk_num
	bmi	@f			*[coda]は[coda0]とみなす
	bsr	get_num			*[coda n]ケース
@@:
	moveq.l	#coda_zmd,d0
	bsr	do_wrt_trk_b
	bsr	pop_coda_addr
	move.l	a1,d0
	sub.l	tpt_now(a5),d0
	subq.l	#4,d0			*d0.l=codaからtoCodaフラグまでのオフセット
	bsr	do_wrt_trk_l
	addq.l	#1,a1			*skip toCodaフラグ
	move.l	a1,d1
	addq.l	#4,d1
	move.l	tpt_now(a5),d0
	sub.l	d1,d0			*d0.l=codaからtoCodaフラグまでの距離
	add.l	tpt_addr(a5),a1
	rept	4
	rol.l	#8,d0
	move.b	d0,(a1)+
	endm
	rts

mml_tocoda:				*[tocoda]
	moveq.l	#0,d1			*default no.
	bsr	chk_num
	bmi	@f			*[tocoda]は[tocoda0]とみなす
	bsr	get_num			*[tocoda n]ケース
@@:
	moveq.l	#tocoda_zmd,d0
	bsr	do_wrt_trk_b		*cmd
	bsr	push_coda_addr		*次の[flag]アドレスを[coda]が指すようにする
	bsr	rgst_flag_map		*[loop]処理時に初期化するワークとして登録
	moveq.l	#0,d0
	bsr	do_wrt_trk_b		*flag
	moveq.l	#0,d0
	bra	do_wrt_trk_l		*offset

reglist	reg	d0-d2/a2
push_segno_addr:			*SGENOのオフセットアドレスのセット
	* < d1.l=segno number
	movem.l	reglist,-(sp)
	moveq.l	#segno_zmd,d2
	bra	@f
push_coda_addr:				*CODAのオフセットアドレスのセット
	* < d1.l=coda number
	movem.l	reglist,-(sp)
	moveq.l	#coda_zmd,d2
@@:
	move.l	tpt_sgcd_max(a5),d0	*ここがゼロならばワークを確保しに行く
	bne	@f
	bsr	get_sgcd_work		*segno/coda処理ワーク確保/> d0.l=tpt_sgcd_max
@@:
	move.l	tpt_sgcd_addr(a5),a2
	add.l	tpt_sgcd_n(a5),a2
	move.l	d2,(a2)+		*type(segno/coda)
	move.l	d1,(a2)+		*number ID
	move.l	tpt_now(a5),(a2)+	*copmiled data addr.
	add.l	#sgcd_wksz,tpt_sgcd_n(a5)
	cmp.l	tpt_sgcd_n(a5),d0
	bhi	@f
	bsr	spread_sgcd_work	*segno/coda処理ワーク拡張
@@:
	movem.l	(sp)+,reglist
	rts

get_sgcd_work:				*segno/coda処理ワーク確保
	* > d0.l=tpt_sgcd_max
reglist	reg	d1-d3/a0-a1
	movem.l	reglist,-(sp)
	move.l	#sgcd_wksz*8,d2
	move.l	#ID_TEMP,d3
	jsr	get_mem-work(a6)
	tst.l	d0
	bmi	m_out_of_memory
	move.l	a0,tpt_sgcd_addr(a5)
	move.l	d2,tpt_sgcd_max(a5)	*work limit addr
	move.l	d2,d0
	clr.l	tpt_sgcd_n(a5)		*ptr
	movem.l	(sp)+,reglist
	rts

spread_sgcd_work:			*segno/coda処理ワーク拡張
reglist	reg	d0-d2/a0-a1
	movem.l	reglist,-(sp)
	move.l	tpt_sgcd_addr(a5),a1
	move.l	tpt_sgcd_max(a5),d2
	add.l	#sgcd_wksz*8,d2
	jsr	enlarge_mem-work(a6)
	tst.l	d0
	bmi	m_out_of_memory
	move.l	a0,tpt_sgcd_addr(a5)
	move.l	d2,tpt_sgcd_max(a5)	*work limit addr
	movem.l	(sp)+,reglist
	rts

reglist	reg	d0-d2/a2
pop_segno_addr:				*segnoアドレスまでのオフセット取りだし
	* < d1.l=segno number
	* > a1.l=next cmd address of segno
	movem.l	reglist,-(sp)
	moveq.l	#segno_zmd,d2
	bra	@f
pop_coda_addr:				*codaアドレスまでのオフセット取りだし
	* < d1.l=coda number
	* > a1.l=next cmd address of coda
	movem.l	reglist,-(sp)
	moveq.l	#coda_zmd,d2
@@:
	tst.l	tpt_sgcd_max(a5)
	beq	m_disorderly_repeat_structure
	move.l	tpt_sgcd_n(a5),d3
	beq	m_disorderly_repeat_structure
	move.l	tpt_sgcd_addr(a5),a2	*repeat work base addr.
ppsca_lp:
	cmp.l	s_sgcd_id(a2),d2
	bne	ppsca_next		*typeが違う
	cmp.l	s_sgcd_no(a2),d1
	bne	ppsca_next		*IDが違う
	move.l	s_sgcd_addr(a2),a1
@@:
	move.l	s_sgcd_id+sgcd_wksz(a2),s_sgcd_id(a2)
	move.l	s_sgcd_no+sgcd_wksz(a2),s_sgcd_no(a2)
	move.l	s_sgcd_addr+sgcd_wksz(a2),s_sgcd_addr(a2)
	lea	sgcd_wksz(a2),a2
	sub.l	#sgcd_wksz,d3
	bne	@b
	sub.l	#sgcd_wksz,tpt_sgcd_n(a5)	*このリピート構造は完結
	movem.l	(sp)+,reglist
	rts
ppsca_next:
	lea	sgcd_wksz(a2),a2
	sub.l	#sgcd_wksz,d3
	bne	ppsca_lp
	bra	m_disorderly_repeat_structure	*ポップ不可

mml_fine:				*[fine]
	moveq.l	#fine_zmd,d0
	bra	do_wrt_trk_b

mml_loop:				*[loop]
	moveq.l	#loop_zmd,d0
	bsr	do_wrt_trk_b
	tst.l	tpt_fgmap_max(a5)
	beq	exit_mllp		*初期化マップ必要なし
	move.l	tpt_fgmap_n(a5),d2
	beq	exit_mllp		*初期化マップ必要なし
	move.l	tpt_fgmap_addr(a5),a1
@@:
	move.l	(a1)+,d0
	sub.l	tpt_now(a5),d0
	subq.l	#4,d0			*オフセット格納領域のサイズ
	bsr	do_wrt_trk_l
	subq.l	#4,d2
	bne	@b
exit_mllp:
	moveq.l	#0,d0			*end mark
	bsr	do_wrt_trk_l
	clr.l	tpt_fgmap_n(a5)		*余り意味はないが
	rts

mml_end:
	tst.b	jump_cmd_ctrl-work(a6)	*m_debug()コマンドによるスイッチング
	beq	mml_lp
	moveq.l	#play_end_zmd,d0	*終了
	bra	do_wrt_trk_b

mml_compile_break_off:			*コンパイル中断
	tst.b	jump_cmd_ctrl-work(a6)	*m_debug()コマンドによるスイッチング
	beq	mml_lp
	bchg.b	#c_break,tpt_mode_flg(a5)
	rts

reglist	reg	d0/a2
rgst_flag_map:				*CODA/SGENOのフラグワーク位置を登録
	movem.l	reglist,-(sp)
	move.l	tpt_fgmap_max(a5),d0	*ここがゼロならばワークを確保しに行く
	bne	@f
	bsr	get_fgmap_work		*登録スペース確保
@@:
	move.l	tpt_fgmap_addr(a5),a2
	add.l	tpt_fgmap_n(a5),a2
	move.l	tpt_now(a5),(a2)	*copmiled data addr.
	addq.l	#4,tpt_fgmap_n(a5)
	cmp.l	tpt_fgmap_n(a5),d0
	bhi	@f
	bsr	spread_fgmap_work	*登録スペース拡張
@@:
	movem.l	(sp)+,reglist
	rts

get_fgmap_work:			*CODA/SGENOのフラグワーク位置を登録するためのワークを確保
reglist	reg	d0-d3/a0-a1
	movem.l	reglist,-(sp)
	move.l	#4*8,d2
	move.l	#ID_TEMP,d3
	jsr	get_mem-work(a6)
	tst.l	d0
	bmi	m_out_of_memory
	move.l	a0,tpt_fgmap_addr(a5)
	move.l	d2,tpt_fgmap_max(a5)	*work limit addr
	clr.l	tpt_fgmap_n(a5)		*ptr
	movem.l	(sp)+,reglist
	rts

spread_fgmap_work:		*CODA/SGENOのフラグワーク位置を登録するためのワークを拡張
reglist	reg	d0-d2/a0-a1
	movem.l	reglist,-(sp)
	move.l	tpt_fgmap_addr(a5),a1
	move.l	tpt_fgmap_max(a5),d2
	add.l	#4*8,d2
	jsr	enlarge_mem-work(a6)
	tst.l	d0
	bmi	m_out_of_memory
	move.l	a0,tpt_fgmap_addr(a5)
	move.l	d2,tpt_fgmap_max(a5)	*work limit addr
	movem.l	(sp)+,reglist
	rts

mml_k_remap:				*[KEY_REMAP]
	bsr	skip_spc		*オクターブスイッチの考慮その1
	cmp.l	a4,d4
	bls	m_illegal_command_line
	lea	krmp_strv-work(a6),a1
	bsr	get_com_no
	bpl	init_tptnttbl
	bsr	get_note_2way_split	*>d1.l=note
	move.l	d1,d2
	bsr	skip_sep
	cmp.l	a4,d4
	bls	m_illegal_command_line
	bsr	get_note_2way_split	*>d1.l=note
	lea	tpt_note_tbl(a5),a1
	move.b	d1,(a1,d2.l)
	rts

init_tptnttbl:
	movem.l	d0-d1/a1,-(sp)
	lea	tpt_note_tbl(a5),a1
	moveq.l	#0,d0
	moveq.l	#128-1,d1
@@:
	move.b	d0,(a1)+
	addq.w	#1,d0
	dbra	d1,@b
	movem.l	(sp)+,d0-d1/a1
	rts

mml_k_signature:		*デフォルト調号指定
	lea	KEY_tbl-work(a6),a1
	bsr	get_com_no
	bmi	mmlksign0
	lsl.w	#3,d0
	lea	mks_tbl(pc,d0.w),a1
	lea	tpt_key_sig(a5),a2
	move.l	(a1)+,(a2)+
	move.l	(a1)+,(a2)+
	rts
mks_tbl:	*	 A, B, C, D, E, F, G, *
		dc.b	00,00,00,00,00,00,00,00	*CMAJOR
		dc.b	00,00,00,00,00,01,00,00	*GMAJOR
		dc.b	00,00,01,00,00,01,00,00	*DMAJOR
		dc.b	00,00,01,00,00,01,01,00	*AMAJOR
		dc.b	00,00,01,01,00,01,01,00	*EMAJOR
		dc.b	01,00,01,01,00,01,01,00	*BMAJOR
		dc.b	01,00,01,01,01,01,01,00	*F+MAJOR
		dc.b	01,00,01,01,01,01,01,00	*F#MAJOR
		dc.b	01,01,01,01,01,01,01,00	*C+MAJOR
		dc.b	01,01,01,01,01,01,01,00	*C#MAJOR

		dc.b	00,00,00,00,00,00,00,00	*CMAJOR
		dc.b	00,-1,00,00,00,00,00,00	*FMAJOR
		dc.b	00,-1,00,00,-1,00,00,00	*B-MAJOR
		dc.b	00,-1,00,00,-1,00,00,00	*BbMAJOR
		dc.b	-1,-1,00,00,-1,00,00,00	*E-MAJOR
		dc.b	-1,-1,00,00,-1,00,00,00	*EbMAJOR
		dc.b	-1,-1,00,-1,-1,00,00,00	*A-MAJOR
		dc.b	-1,-1,00,-1,-1,00,00,00	*AbMAJOR
		dc.b	-1,-1,00,-1,-1,00,-1,00	*D-MAJOR
		dc.b	-1,-1,00,-1,-1,00,-1,00	*DbMAJOR
		dc.b	-1,-1,-1,-1,-1,00,-1,00	*G-MAJOR
		dc.b	-1,-1,-1,-1,-1,00,-1,00	*GbMAJOR
		dc.b	-1,-1,-1,-1,-1,-1,-1,00	*C-MAJOR
		dc.b	-1,-1,-1,-1,-1,-1,-1,00	*CbMAJOR

		dc.b	00,00,00,00,00,00,00,00	*AMINOR
		dc.b	00,00,00,00,00,01,00,00	*EMINOR
		dc.b	00,00,01,00,00,01,00,00	*BMINOR
		dc.b	00,00,01,00,00,01,01,00	*F+MINOR
		dc.b	00,00,01,00,00,01,01,00	*F+MINOR
		dc.b	00,00,01,01,00,01,01,00	*C+MINOR
		dc.b	00,00,01,01,00,01,01,00	*C#MINOR
		dc.b	01,00,01,01,00,01,01,00	*G+MINOR
		dc.b	01,00,01,01,00,01,01,00	*G#MINOR
		dc.b	01,00,01,01,01,01,01,00	*D+MINOR
		dc.b	01,00,01,01,01,01,01,00	*D#MINOR
		dc.b	01,01,01,01,01,01,01,00	*A+MINOR
		dc.b	01,01,01,01,01,01,01,00	*A#MINOR

		dc.b	00,00,00,00,00,00,00,00	*AMINOR
		dc.b	00,-1,00,00,00,00,00,00	*DMINOR
		dc.b	00,-1,00,00,-1,00,00,00	*GMINOR
		dc.b	-1,-1,00,00,-1,00,00,00	*CMINOR
		dc.b	-1,-1,00,-1,-1,00,00,00	*FMINOR
		dc.b	-1,-1,00,-1,-1,00,-1,00	*B-MINOR
		dc.b	-1,-1,00,-1,-1,00,-1,00	*BbMINOR
		dc.b	-1,-1,-1,-1,-1,00,-1,00	*E-MINOR
		dc.b	-1,-1,-1,-1,-1,00,-1,00	*EbMINOR
		dc.b	-1,-1,-1,-1,-1,-1,-1,00	*A-MINOR
		dc.b	-1,-1,-1,-1,-1,-1,-1,00	*AbMINOR

mmlksign0:
	moveq.l	#0,d0
	moveq.l	#0,d3
	lea	tpt_key_sig+8(a5),a2
	move.l	d3,-(a2)
	move.l	d3,-(a2)	*initialize
ksi_lp:
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_illegal_command_line	*']'がない
	move.b	(a4)+,d0
	cmpi.b	#' ',d0
	bcs	m_illegal_command_line	*']'がない
	cmpi.b	#']',d0
	beq	exit_ksi
	cmpi.b	#'+',d0
	beq	@f
	cmpi.b	#'#',d0
	bne	ksi_minus?
@@:				*case #
	addq.b	#1,d3
	bra	ksi_lp
ksi_minus?:
	cmpi.b	#'-',d0
	bne	@f
	subq.b	#1,d3
	bra	ksi_lp
@@:
	cmpi.b	#' ',d0
	beq	ks_sep
	cmpi.b	#',',d0
	bne	@f
ks_sep:
	moveq.l	#0,d3
	bra	ksi_lp
@@:
	jsr	mk_capital-work(a6)
	sub.b	#'A',d0
	bmi	m_unexpected_operand
	cmpi.w	#6,d0
	bhi	m_unexpected_operand
	move.b	d3,(a2,d0.w)	*set
	bra	ksi_lp
exit_ksi:
	subq.w	#1,a4
	rts

mml_pattern:				*[PATTERN]	パターン指定
	moveq.l	#']',d1
	bsr	get_pattern_name	*> d0=last character,d3=str len,temp_buffer=name str
	cmp.b	d0,d1			*文字列の最後は必ず']'でなければならない
	bne	m_illegal_command_line
	subq.w	#1,a4			*辻褄合わせ
					*指定パターン名の検索
	bsr	find_pattern_name	*>a2.l=exact address
	beq	m_undefined_pattern	*未定義のパターンを指定した
	moveq.l	#gosub_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#-1,d0			*track number=-1:pattern track
	bsr	do_wrt_trk_w
	move.l	(a2),d0
	bra	do_wrt_trk_l		*パターンが存在するoffsetアドレス

mml_pcm_mode:				*[PCM_MODE]
	bsr	chk_num
	bpl	@f
	lea	rhythm_timbre_tone-work(a6),a1
	bsr	get_com_no		*0:rhythm,1:timbre,2:tone
	bmi	m_illegal_mode_value
	move.l	d0,d1
	beq	do_wrt_mpm
	subq.l	#1,d1
	beq	mpm00
	moveq.l	#0,d1
	bra	do_wrt_mpm
@@:
	moveq.l	#0,d1
	bsr	chk_num
	bmi	do_wrt_mpm
	bsr	get_num
	tst.l	d1
	beq	do_wrt_mpm
mpm00:
	moveq.l	#4,d1			*b_vtune_mode
do_wrt_mpm:
	moveq.l	#pcm_mode_zmd,d0
	bsr	do_wrt_trk_b
	bra	wrt_data_d1

mml_embed:				*[EMBED]	パターン指定
	moveq.l	#']',d1
	bsr	get_pattern_name	*> d0=last character,d3=str len,temp_buffer=name str
	cmp.b	d0,d1			*文字列の最後は必ず']'でなければならない
	bne	m_illegal_command_line
	subq.w	#1,a4			*辻褄合わせ
					*指定パターン名の検索
	bsr	find_pattern_name	*>a2.l=exact address
	beq	m_undefined_pattern	*未定義のパターンを指定した
	move.l	(a2)+,d0		*offset
	move.l	(a2)+,d2		*size
	moveq.l	#-1,d1
	bsr	get_trk_addr		*>a2.l=addr
	move.l	tpt_addr(a2),a2
	add.l	d0,a2
@@:
	move.b	(a2)+,d0
	bsr	do_wrt_trk_b
	subq.l	#1,d2
	bne	@b
	rts

mml_track_delay:		*[TRACK_DELAY n]
	bsr	chk_num
	bmi	@f
	bsr	get_num
	cmpi.l	#max_note_len,d1
	bhi	m_delay_too_long
	moveq.l	#track_delay_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d1,d0
	bsr	consider_trkfrq_st
	bra	do_wrt_trk_v

mml_comment:				*[COMMENT]
	moveq.l	#skip_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#0,d0			*mode=0(offset)
	bsr	do_wrt_trk_b
	move.l	tpt_now(a5),d5		*あとでoffsetを格納するため
	moveq.l	#0,d0
	bsr	do_wrt_trk_l		*スキップ幅予約
seq_string_param:
	cmp.l	a4,d4
	bls	m_illegal_command_line
	move.b	(a4)+,d0		*最初の1文字のSPC/TABなどはスキップ
	cmpi.b	#' ',d0
	beq	mmlcmtlp		*spc
	cmpi.b	#$09,d0
	beq	mmlcmtlp		*tab
	subq.w	#1,a4
mmlcmtlp:					*']'を発見するまで文字列を格納
	cmp.l	a4,d4
	bls	m_illegal_command_line
	move.b	(a4)+,d0
	bsr	chk_kanji
	bpl	@f
	cmp.l	a4,d4
	bls	m_kanji_break_off
	move.b	(a4)+,d0
	bsr	do_wrt_trk_b
	bra	mmlcmtlp
@@:
	cmpi.b	#']',d0			*endcode
	beq	@f
	bsr	do_wrt_trk_b
	bra	mmlcmtlp
@@:
	subq.w	#1,a4			*辻褄あわせ 97/4/10
	move.l	d5,d1
	addq.l	#4,d1
	move.l	tpt_now(a5),d0
	sub.l	d1,d0
	move.l	tpt_addr(a5),a1		*文字列長=SKIP幅をセット
	add.l	d5,a1
	rol.l	#8,d0
	move.b	d0,(a1)+
	rol.l	#8,d0
	move.b	d0,(a1)+
	rol.l	#8,d0
	move.b	d0,(a1)+
	rol.l	#8,d0
	move.b	d0,(a1)+
	rts

mml_event:				*[EVENT]
	moveq.l	#event_zmd,d0
	bsr	do_wrt_trk_b
	move.l	tpt_now(a5),d5		*あとでoffsetを格納するため
	moveq.l	#0,d0
	bsr	do_wrt_trk_l		*スキップ幅(SIZE)予約
	bsr	chk_num			*get category
	bpl	@f
	lea	category_strv-work(a6),a1
	bsr	get_com_no
	bmi	m_illegal_category_event
	move.l	d0,d1
	bra	get_evntcls
@@:
	bsr	get_num
	cmpi.l	#255,d1
	bhi	m_illegal_category_event
	move.l	d1,d0
get_evntcls:
	move.l	d0,d3			*カテゴリ保存
	bsr	do_wrt_trk_b		*category
	bsr	skip_sep
	bsr	chk_num
	bpl	@f
	add.w	d1,d1
	move.w	classstrvtbl(pc,d1.l),d1
	lea	classstrvtbl(pc,d1.l),a1
	bsr	get_com_no
	bmi	m_unknown_event_class
	bra	get_evntstr
classstrvtbl:
	dc.w	class0_strv-classstrvtbl	*category=0のクラス名テーブル
	dc.w	class1_strv-classstrvtbl	*category=1のクラス名テーブル
	dc.w	class2_strv-classstrvtbl	*category=2のクラス名テーブル
@@:					*get class
	bsr	get_num
	cmpi.l	#255,d1
	bhi	m_unknown_event_class
	move.l	d1,d0
get_evntstr:
	bsr	do_wrt_trk_b		*class
	bsr	skip_sep
	moveq.l	#0,d0
	bsr	do_wrt_trk_w		*dummy(w)
	bsr	get_str_zmd		*>d1.l=文字列長
	tst.l	d3
	bne	1f			*0:word以外はファイルネーム指定ということでサイズ=0
	add.l	#4,d1
	move.l	tpt_addr(a5),a1
	add.l	d5,a1
	rept	4
	rol.l	#8,d1
	move.b	d1,(a1)+		*set jump addr.
	endm
1:
	rts

get_str_zmd:			*文字列取得
	* > d1.l=得た文字列の長さ
	* - all
reglist	reg	d0/d2-d3
	movem.l	reglist,-(sp)
	move.l	tpt_now(a5),d3		*長さを検出するために使う
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	move.b	(a4)+,d2		*end character
	cmpi.b	#"'",d2
	beq	1f
	cmpi.b	#'"',d2
	beq	1f
	moveq.l	#']',d2
1:					*get pattern name
	cmp.l	a4,d4
	bls	3f
	move.b	(a4)+,d0
	bsr	chk_kanji
	bpl	@f
	bsr	do_wrt_trk_b
	cmp.l	a4,d4
	bls	m_kanji_break_off	*漢字が途中で終わっている
	move.b	(a4)+,d0
	bsr	do_wrt_trk_b
	bra	1b
@@:
	cmpi.b	#' ',d0
	bcc	2f
	moveq.l	#' ',d0			*コントロールコードはスペースへ変換
2:
	cmp.b	d2,d0
	beq	3f
	bsr	do_wrt_trk_b
	bra	1b
3:
	moveq.l	#0,d0			*end code
	bsr	do_wrt_trk_b
	move.l	tpt_now(a5),d1
	sub.l	d3,d1			*d1.l=文字列長
	cmpi.b	#']',d2
	bne	@f
	subq.w	#1,a4			*']'が終端なら1つ戻って辻褄あわせ
@@:
	movem.l	(sp)+,reglist
	rts

mml_measure_jump:			*[JUMP]
	bset.b	#6,compile_status-work(a6)	*[JUMP]を使用したことをマーク
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
	bsr	get_num
	moveq.l	#jump_ope3_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d1,d0
	bra	do_wrt_trk_l

case_mml_bar:				*[---....]
	btst.b	#c_renp1,tpt_mode_flg(a5)	*連符内に小節線は使用出来ない
	bne	m_illegal_command_in_brace
@@:
	cmp.l	a4,d4
	bls	m_illegal_command_line
	move.b	(a4)+,d0
	cmpi.b	#'-',d0
	beq	@b
	cmpi.b	#']',d0
	bne	m_illegal_command_line
	moveq.l	#measure_zmd,d0
	bsr	do_wrt_trk_b
	bra	mml_lp

mml_measure:				*[MEASURE]/[BAR]
	btst.b	#c_renp1,tpt_mode_flg(a5)	*連符内に小節線は使用出来ない
	bne	m_illegal_command_in_brace
msrlp:
	cmp.l	a4,d4
	bls	m_illegal_command_line
	move.b	(a4)+,d0
	bsr	chk_kanji
	bpl	@f
	cmp.l	a4,d4
	bls	m_illegal_command_line
	addq.w	#1,a4
	bra	msrlp
@@:
	cmpi.b	#']',d0
	bne	msrlp
	subq.w	#1,a4			*']'に合わせる
	moveq.l	#measure_zmd,d0
	bra	do_wrt_trk_b

mml_rept_start:			*リピート関係の処理 |: or |n or |
	tst.b	ptn_cmd-work(a6)
	bne	m_illegal_command_in_pattern
	btst.b	#c_renp1,tpt_mode_flg(a5)	*連符内にrepeatコマンドは使用出来ない
	bne	m_illegal_command_in_brace
	bsr	skip_spc2
	cmp.l	a4,d4
	bls	m_disorderly_repeat_structure	*繰り返しコマンドの構造が異常
	cmpi.b	#':',(a4)
	bne	rept_skip	*|n case(リピート抜け出し処理へ)
				*以下 |: ケース
	addq.w	#1,a4
	moveq.l	#2,d1		*count省略のケースは２回とみなす
	bsr	chk_num
	bmi	@f
	bsr	get_num
@@:
	subq.l	#1,d1
	cmpi.l	#rept_max-1,d1
	bhi	m_illegal_repeat_time
	bsr	push_rept_start			*mark repeat start address
	moveq.l	#repeat_start_zmd,d0		*repeat start cmd code
	bsr	do_wrt_trk_b
	move.l	d1,d0
	bsr	do_wrt_trk_w			*repeat count
	moveq.l	#0,d0
	bsr	do_wrt_trk_w			*repeat count work
	moveq.l	#0,d0				*initialize
	bsr	set_jmp_exit
	bra	mml_lp

rept_skip:			*ループを抜け出すコマンド |n or |
	bsr	chk_num			*数値なしならば最後のリピート時に抜け出すという
	bmi	rept_skip2		*別コマンドになる(| ケース)
	moveq.l	#repeat_skip_zmd,d0	*cmd code
	bsr	do_wrt_trk_b		*write cmd code
	bsr	get_num
	subq.l	#1,d1
	cmpi.l	#rept_max-1,d1
	bhi	m_illegal_repeat_time	*繰り返し番号が異常
	move.l	d1,d0			*destination repeat count
	bsr	do_wrt_trk_w
rptskp0:
	bsr	pop_rept_start2		*>d0 offset value to rept start cmd
	addq.l	#1,d0			*4(offset size)-3(rept cmdからcnt wkまでのoffset)=1
	bsr	do_wrt_trk_l		*offset address to rept count work
	move.l	tpt_now(a5),d0
	bsr	set_jmp_exit
	moveq.l	#0,d0			*dummy
	bsr	do_wrt_trk_l
	bsr	set_rept_cnt		*回数指定があることを報告
	bra	mml_lp

rept_skip2:
	moveq.l	#repeat_skip2_zmd,d0	*cmd code
	bsr	do_wrt_trk_b		*write cmd code
	bsr	pop_rept_start2		*>d0 offset value to rept start cmd
	addq.l	#1,d0			*4(offset size)-3(rept cmdからcnt wkまでのoffset)=1
	bsr	do_wrt_trk_l		*offset address to rept count work
	move.l	tpt_now(a5),d0
	bsr	set_jmp_exit
	moveq.l	#0,d0			*dummy
	bsr	do_wrt_trk_l
*	bsr	set_rept_cnt		*回数指定があることを報告
	bra	mml_lp

mml_rept_end:				*リピート終了コマンド
	tst.b	ptn_cmd-work(a6)
	bne	m_illegal_command_in_pattern
	cmp.l	a4,d4
	bls	m_syntax_error
	cmpi.b	#'|',(a4)		*本当に終了コマンド?
	bne	m_syntax_error
	addq.w	#1,a4			*skip '|'
	moveq.l	#repeat_end_zmd,d0	*set cmd code
	bsr	do_wrt_trk_b
	bsr	pop_rept_start		*>d0 offset value to rept start cmd
	addq.l	#3,d0			*4(offset size)-1(rept cmdからrept cntまでのoffset)=3
	bsr	do_wrt_trk_l
	bra	mml_lp

push_rept_start:			*リピートスタートアドレスのセット
	* < d1.l=repeat counter
reglist	reg	d0-d1/a2
	movem.l	reglist,-(sp)
	move.l	tpt_rept_max(a5),d0	*ここがゼロならばワークを確保しに行く
	bne	@f
	bsr	get_rept_work		*リピート処理ワーク確保
@@:
	move.l	tpt_rept_addr(a5),a2
	add.l	tpt_rept_n(a5),a2
	move.l	tpt_now(a5),(a2)+	*copmiled data addr.
	move.l	#$0000_0001,(a2)+	*clear flag.w:0 & set dummy repeat counter.w:1
	move.l	d1,(a2)+		*save repeat counter
	add.l	#rept_wksz,tpt_rept_n(a5)
	cmp.l	tpt_rept_n(a5),d0
	bhi	@f
	bsr	spread_rept_work	*リピート処理ワーク拡張
@@:
	movem.l	(sp)+,reglist
	rts

get_rept_work:				*リピート処理ワーク確保
	* > d0.l=tpt_rept_max
reglist	reg	d1-d3/a0-a1
	movem.l	reglist,-(sp)
	move.l	#rept_wksz*8,d2
	move.l	#ID_TEMP,d3
	bsr	get_mem
	tst.l	d0
	bmi	m_out_of_memory
	move.l	a0,tpt_rept_addr(a5)
	move.l	d2,tpt_rept_max(a5)	*work limit addr
	move.l	d2,d0
	clr.l	tpt_rept_n(a5)		*ptr
	movem.l	(sp)+,reglist
	rts

spread_rept_work:			*リピート処理ワーク拡張
reglist	reg	d0-d2/a0-a1
	movem.l	reglist,-(sp)
	move.l	tpt_rept_addr(a5),a1
	move.l	tpt_rept_max(a5),d2
	add.l	#rept_wksz*8,d2
	bsr	enlarge_mem
	tst.l	d0
	bmi	m_out_of_memory
	move.l	a0,tpt_rept_addr(a5)
	move.l	d2,tpt_rept_max(a5)	*work limit addr
	movem.l	(sp)+,reglist
	rts

pop_rept_start:		*リピートスタートアドレスまでのオフセット取りだし
	* > d0.l=repeat start offset address	(リピートスキップのオフセット処理も行う)
reglist	reg	a1-a2
	movem.l	reglist,-(sp)
	tst.l	tpt_rept_max(a5)
	beq	m_disorderly_repeat_structure	*ポップ不可
	move.l	tpt_rept_n(a5),d0
	beq	m_disorderly_repeat_structure	*ポップ不可
	sub.l	#rept_wksz,d0			*(sp--)相当
	move.l	tpt_rept_addr(a5),a2	*repeat work base addr.
	add.l	d0,a2
	move.l	r_rept_exit(a2),d0	*|n や |の未解決オフセット埋め込み処理が必要か
	beq	@f
	move.l	d0,a1			*a1=| or |nコマンドのジャンプオフセットが
	move.l	tpt_now(a5),d0		*書き込まれるべきアドレス
	sub.l	a1,d0
	add.l	tpt_addr(a5),a1
	rept	4
	rol.l	#8,d0
	move.b	d0,(a1)+		*set jump addr.
	endm
	clr.l	r_rept_exit(a2)		*オフセット書き込み終了
@@:
	move.l	tpt_now(a5),d0
	sub.l	r_rept_addr(a2),d0	*d0=repeat開始cmdまでのオフセットアドレス(戻り値)
	tst.w	r_rept_flag(a2)
	beq	@f
	subq.w	#1,r_rept_work(a2)	*dec repeat counter
	bcc	exit_prs
@@:
	sub.l	#rept_wksz,tpt_rept_n(a5)	*このリピート構造は完結
exit_prs:
	movem.l	(sp)+,reglist
	rts

pop_rept_start2:	*リピートスタートアドレスまでのオフセット取りだし(単なる取りだし)
	* > d0.l=repeat start offset address
reglist	reg	a1-a2
	movem.l	reglist,-(sp)
	tst.l	tpt_rept_max(a5)
	beq	m_disorderly_repeat_structure	*ポップ不可
	move.l	tpt_rept_n(a5),d0
	beq	m_disorderly_repeat_structure	*ポップ不可
	sub.l	#rept_wksz,d0			*(sp--)相当
	move.l	tpt_rept_addr(a5),a2	*repeat work base addr.
	add.l	d0,a2
	move.l	r_rept_exit(a2),d0	*|n や |の未解決オフセット埋め込み処理が必要か
	beq	@f
	move.l	d0,a1			*a1=| or |nコマンドのジャンプオフセットが
	move.l	tpt_now(a5),d0		*書き込まれるべきアドレス
	sub.l	a1,d0
	subq.l	#7,d0			*オフセットの値分引く
	add.l	tpt_addr(a5),a1
	rept	4
	rol.l	#8,d0
	move.b	d0,(a1)+		*set jump addr.
	endm
	clr.l	r_rept_exit(a2)		*オフセット書き込み終了
@@:
	move.l	tpt_now(a5),d0
	sub.l	r_rept_addr(a2),d0	*d0=repeat開始cmdまでのオフセットアドレス(戻り値)
	movem.l	(sp)+,reglist
	rts

set_rept_cnt:					*リピートカウンタをセットする
reglist	reg	d0-d1/a2
	movem.l	reglist,-(sp)
	tst.l	tpt_rept_max(a5)
	beq	m_disorderly_repeat_structure	*ポップ不可
	move.l	tpt_rept_n(a5),d0
	beq	m_disorderly_repeat_structure	*ポップ不可
	sub.l	#rept_wksz,d0			*(sp--)相当
	move.l	tpt_rept_addr(a5),a2		*repeat work base addr.
	add.l	d0,a2
	move.w	r_rept_cnt(a2),d1
	tst.w	r_rept_flag(a2)			*すでにセット済みか
	bne	@f
	st.b	r_rept_flag(a2)			*セット終了マーク
	move.w	d1,r_rept_work(a2)		*回数値セット
@@:
	movem.l	(sp)+,reglist
	rts

set_jmp_exit:					*リピート抜け出しオフセット
	* < d0=repeat exit offset address
reglist	reg	d0-d1/a2
	movem.l	reglist,-(sp)
	tst.l	tpt_rept_max(a5)
	beq	m_disorderly_repeat_structure	*ポップ不可
	move.l	tpt_rept_n(a5),d1
	beq	m_disorderly_repeat_structure	*ポップ不可
	sub.l	#rept_wksz,d1			*(sp--)相当
	move.l	tpt_rept_addr(a5),a2		*repeat work base addr.
	move.l	d0,r_rept_exit(a2,d1.l)
	movem.l	(sp)+,reglist
	rts

mml_q:						*Ｑコマンド
	moveq.l	#0,d1
	move.b	gate_range-work(a6),d1
	bsr	chk_num
	bmi	set_q		*パラメータ省略時には最大ゲートが採択される(ex.Q8)
	bsr	get_num
set_q:
	bclr.b	#c_q_sgn,tpt_mode_flg(a5)
	tst.l	d1
	bpl	@f
	bset.b	#c_q_sgn,tpt_mode_flg(a5)
	neg.l	d1
@@:
	moveq.l	#0,d0
	move.b	gate_range-work(a6),d0
	cmp.l	d0,d1
	bhi	m_illegal_gate_time		*illegal q
	move.w	d1,tpt_gate_time(a5)
	bra	mml_lp

mml_o:					*オクターブ
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
	bsr	get_num			*d1=-1～9
	addq.l	#1,d1			*d1=0～10
	cmpi.l	#10,d1
	bhi	m_illegal_octave	*illegal octave
	move.b	d1,tpt_octave(a5)
	bra	mml_lp

oct_up:			*オクターブアップ(ここの仕様を変えたらPORTAMENTの部分のも変える)
	cmpi.b	#10,tpt_octave(a5)
	beq	m_illegal_octave	*illegal octave
	addq.b	#1,tpt_octave(a5)
	bra	mml_lp

oct_dwn:		*オクターブダウン
	tst.b	tpt_octave(a5)
	beq	m_illegal_octave	*illegal octave
	subq.b	#1,tpt_octave(a5)
	bra	mml_lp

mml_l:					*Ｌコマンド
	btst.b	#c_renp1,tpt_mode_flg(a5)	*連符内にLコマンドは使用出来ない
	bne	m_illegal_command_in_brace
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted	*音長が書かれていない
	cmpi.b	#'*',(a4)
	bne	@f		*音楽音長のケース
	addq.w	#1,a4		*skip '*'
get_@l:				*絶対音長
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
	bsr	get_num
	move.l	d1,d0
	bra	consider_lftn
@@:
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted	*no L value
	bsr	get_length
consider_lftn:
	bsr	futen_ope			*<d0.l
	move.w	d1,tpt_note_len(a5)
	bra	mml_lp

mml_k:				*キートランスポーズ
	moveq.l	#0,d1
	bsr	chk_num
	bmi	@f
	bsr	get_num		*get tempo value
@@:
	move.l	d1,d0
	bpl	chk_k_abs
	neg.l	d0
chk_k_abs:			*絶対値で既定範囲内かをチェック
	cmpi.l	#127,d0
	bhi	m_key_transpose_out_of_range
	moveq.l	#key_transpose_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d1,d0		*transpose value
	bsr	do_wrt_trk_b
	bra	mml_lp

mml_@tempo:					*[@TEMPO]
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted	*no T value
	move.b	(a4),d0
	cmpi.b	#'-',d0
	beq	mml_rltv_tm			*相対テンポ
	bsr	chk_num
	bpl	mml_rltv_tp			*相対テンポ
	bra	m_parameter_cannot_be_omitted	*no T value

mml_tempo:			*[TEMPO]
mml_t:				*テンポコマンド
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted	*テンポ値が書かれていない
	move.b	(a4),d0
	cmpi.b	#'-',d0
	beq	mml_rltv_tm
	cmpi.b	#'+',d0
	beq	mml_rltv_tp
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted	*テンポ値の省略不可
	bsr	get_num
	tst.l	d1
	beq	m_illegal_tempo_value
	moveq.l	#tempo_t_zmd,d0
	bsr	do_wrt_trk_b	*write cmd
	move.l	d1,d0
	bsr	do_wrt_trk_w
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	rts
mml_rltv_tp:
	moveq.l	#1,d1
	bra	@f
mml_rltv_tm:
	moveq.l	#-1,d1
@@:
	move.l	a4,d0
	addq.w	#1,a4		*skip +,-
	bsr	chk_num		*パラメータ省略時は+1,-1となる
	bmi	@f
	move.l	d0,a4		*数値は符号から取得
	bsr	get_num
@@:
	moveq.l	#rltv_t_zmd,d0		*relative
	bsr	do_wrt_trk_b
	move.l	d1,d0
	bsr	do_wrt_trk_w
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	rts

mml_@n:					*@N
	lea	v2_ch_tbl-work(a6),a1
	bra	@f
mml_n:					*N
	lea	real_ch_tbl-work(a6),a1
@@:
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted	*no N value
	bsr	get_num
	subq.l	#1,d1
	cmpi.l	#31,d1
	bhi	m_illegal_channel
	lsl.w	#2,d1
	move.b	#asgn_chg_zmd,d0	*cmd
	bsr	do_wrt_trk_b
	move.l	(a1,d1.w),d0
	bsr	do_wrt_trk_l		*set type,ch value
	bra	mml_lp

mml_ch_assign:				*[CH_ASSIGN],[ASSIGN]
	bsr	get_str_ch		*>d2.l=type,ch
	bne	m_error_code_exit	*デバイス名異常
	move.b	#asgn_chg_zmd,d0	*cmd
	bsr	do_wrt_trk_b
	move.l	d2,d0
	bra	do_wrt_trk_l		*set type,ch value

mml_v:						*ボリュームコマンド
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted	*no @V value
	move.b	(a4),d0
	cmpi.b	#'+',d0
	beq	mml_rltv_vol_up2		*相対ボリューム
	cmpi.b	#'-',d0
	beq	mml_rltv_vol_dwn2		*相対ボリューム
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
	bsr	get_num
	mulu	tpt_trkvol(a5),d1
	lsr.l	#7,d1				*/128
	cmpi.l	#16,d1
	bhi	m_illegal_volume_value
	move.b	#volume_zmd,d0			*cmd code
	bsr	do_wrt_trk_b
	move.l	d1,d0
	tas.b	d0				*0-16range mode
	bsr	do_wrt_trk_b			*set v value
	bra	mml_lp

mml_rltv_vol_dwn2:			*相対ボリュームダウン2
	bsr	chk_num
	bmi	rltv_vd2_dflt
	bsr	get_num
	neg.l	d1
	cmp.l	#127,d1
	bhi	m_illegal_volume_value
	move.b	d1,tpt_rltv_vol(a5)
	bra	@f
rltv_vd2_dflt:
	moveq.l	#0,d1
	move.b	tpt_rltv_vol(a5),d1
@@:
	moveq.l	#rltv_vol2_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d1,d0
	neg.b	d0
	bsr	do_wrt_trk_b
	bra	mml_lp

mml_rltv_vol_up2:			*相対ボリュームアップ2
	bsr	chk_num
	bmi	rltv_vu2_dflt
	bsr	get_num
	cmpi.l	#127,d1
	bhi	m_illegal_volume_value
	move.b	d1,tpt_rltv_vol(a5)
	bra	@f
rltv_vu2_dflt:
	moveq.l	#0,d1
	move.b	tpt_rltv_vol(a5),d1
@@:
	moveq.l	#rltv_vol2_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d1,d0
	bsr	do_wrt_trk_b
	bra	mml_lp

mml_instrument_id:		*[INSTRUMENT_ID]
mml_@i:				*MIDI MODULE ID SET
	moveq.l	#127,d5
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted	*MAKER ID 省略できない
	bsr	get_num
	move.l	d1,d2
	cmp.l	d5,d2		*127より大きいとダメ
	bhi	m_illegal_maker_id
	bsr	skip_sep

	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted	*DEVICE ID 省略できない
	bsr	get_num
	move.l	d1,d3
	cmp.l	d5,d3
	bhi	m_illegal_device_id
	bsr	skip_sep

	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted	*MODEL ID 省略できない
	bsr	get_num
	cmp.l	d5,d1
	bhi	m_illegal_model_id

	moveq.l	#ID_set_zmd,d0
	bsr	do_wrt_trk_b
	bsr	wrt_data_d2
	bsr	wrt_data_d3
	bsr	wrt_data_d1
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	rts

mml_@velocity:					*[@VELOCITY]
	bclr.b	#c_vseq,tpt_mode_flg(a5)	*velocity sequence stop
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
	bsr	get_num
	move.l	d1,d0
	bpl	@f
	neg.l	d0
@@:				*絶対値にして変化量レンジ(-127～+127)を検査
	cmp.l	#127,d0
	bhi	m_illegal_velocity_value
	bra	go_wrt_rlvl

mml_velocity:			*[VELOCITY n]
mml_u:				*uコマンド
	bclr.b	#c_vseq,tpt_mode_flg(a5)	*velocity sequence stop
	bsr	skip_spc
	cmp.l	a4,d4
	bls	reset_velo
	move.b	(a4),d0
	moveq.l	#-1,d1		*数値省略の場合
	cmpi.b	#'-',d0
	beq	@f
	cmpi.b	#'+',d0
	bne	mml_last_@uN
	moveq.l	#1,d1		*数値省略の場合
@@:				*相対指定の場合
	move.l	a4,d0
	addq.w	#1,a4
	bsr	chk_num
	bmi	go_wrt_rlvl
	move.l	d0,a4
	bsr	get_num
	move.l	d1,d0
	bpl	@f
	neg.l	d0
@@:				*絶対値にして変化量レンジ(-127～+127)を検査
	cmp.l	#127,d0
	bhi	m_illegal_velocity_value
go_wrt_rlvl:
	moveq.l	#rltv_velo_zmd,d0
	bsr	do_wrt_trk_b
	bsr	wrt_data_d1
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	rts

reset_velo:
	moveq.l	#velocity_zmd,d0
	bsr	do_wrt_trk_b
	move.b	tpt_last_velo(a5),d0
	bsr	do_wrt_trk_b
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	rts

mml_@u:				*@uコマンド
	bclr.b	#c_vseq,tpt_mode_flg(a5)	*velocity sequence stop
	bsr	skip_spc
	cmp.l	a4,d4
	bls	rltv_u_dflt	*デフォルト相対
	move.b	(a4),d0
	cmpi.b	#'+',d0
	beq	relative_up
	cmpi.b	#'-',d0
	beq	relative_um
mml_@uN:
	bsr	chk_num
	bmi	rltv_u_dflt	*デフォルト相対
	bsr	get_num
	move.l	d1,d0
	bpl	@f
	neg.l	d0
@@:
	cmp.l	#127,d0		*計算結果がマイナスになってないか
	bhi	m_illegal_velocity_value
mml_@u_:			*< d1.b=velocity value
	move.b	d1,tpt_last_velo(a5)
	moveq.l	#velocity_zmd,d0
	bsr	do_wrt_trk_b
	bsr	wrt_data_d1
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	rts

rltv_u_dflt:			*@U/Uだけのとき
	move.b	tpt_rltv_velo(a5),d0
	bra	relative_u_
relative_um:
	moveq.l	#-1,d0
	bra	@f
relative_up:
	moveq.l	#1,d0
@@:
	move.l	a4,d1
	addq.w	#1,a4
	bsr	chk_num
	bmi	set_dfrlvu
	move.l	d1,a4
	bsr	get_num
	move.l	d1,d0
	bpl	@f
	neg.l	d1
@@:
	cmpi.l	#127,d1		*絶対値が127を越えてるか
	bhi	m_illegal_velocity_value
set_dfrlvu:
	move.b	d0,tpt_rltv_velo(a5)
relative_u_:
	move.b	tpt_last_velo(a5),d1
	add.b	d0,d1
	bpl	mml_@u_
	moveq.l	#0,d1
	tst.b	d0
	bmi	mml_@u_
	moveq.l	#127,d1
	bra	mml_@u_

mml_last_@uN:
	bsr	chk_num
	bpl	mml_@uN
	move.b	tpt_last_velo(a5),d1
	bra	mml_@u_

mml_exclusive:			*[EXCLUSIVE]
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	cmpi.b	#'{',(a4)
	bne	@f
	addq.w	#1,a4
@@:
	moveq.l	#exclusive_zmd,d0	*send cmd code
	bsr	do_wrt_trk_b
	moveq.l	#-1,d0			*maker ID
	bsr	do_wrt_trk_b
	bra	mmlxentry

mml_yamaha_exclusive:		*[YAMAHA_EXCLUSIVE]
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	cmpi.b	#'{',(a4)
	bne	@f
	addq.w	#1,a4
@@:
	moveq.l	#exclusive_zmd,d0	*send cmd code
	bsr	do_wrt_trk_b
	moveq.l	#MKID_YAMAHA,d0		*maker ID
	bsr	do_wrt_trk_b
	bra	mmlxentry

mml_roland_exclusive:			*[ROLAND_EXCLUSIVE]
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	cmpi.b	#'{',(a4)
	bne	@f
	addq.w	#1,a4
@@:
mml_x:					*ROLAND EXCLUSIVE DATA SEND
	moveq.l	#exclusive_zmd,d0	*send cmd code
	bsr	do_wrt_trk_b
	moveq.l	#MKID_ROLAND,d0		*MAKER ID
	bsr	do_wrt_trk_b
mmlxentry:
	moveq.l	#0,d0			*no comment
	bsr	do_wrt_trk_b		*comment length
go_get_mddt:
	move.l	tpt_now(a5),d5
	bsr	do_wrt_trk_l		*データ長サイズ分ダミーデータの書き込みでリザーブ
	moveq.l	#$7f,d2			*check over $7f
	bsr	wrt_send_data		*>d2.l=data length
	tst.l	d2
	beq	m_parameter_cannot_be_omitted	*値が一個もない時はｴﾗｰ
	move.l	tpt_addr(a5),a1
	add.l	d5,a1
*	addq.l	#1,d2			*check sum分
	rept	4
	rol.l	#8,d2
	move.b	d2,(a1)+		*サイズ書き込み
	endm
*	moveq.l	#$80,d0
*	andi.b	#$7f,d3
*	sub.b	d3,d0			*d0=Roland check sum value
*	andi.b	#$7f,d0
*	bsr	do_wrt_trk_b
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_illegal_command_line
	cmpi.b	#'}',(a4)
	bne	@f
	addq.w	#1,a4
@@:
	rts

wrt_send_data:			*転送データをバッファへ
	* < d2.l=0 data max range(127 or 255)
	* > d2.l=data総数
	* > d3.b=sum
	* X d0-d1,d3,a2
reglist	reg	d0-d1/d5/a2
	movem.l	reglist,-(sp)
	move.l	d2,d5		*limiter
	moveq.l	#0,d2		*init data length
	moveq.l	#0,d3		*init sum
mmlx_lp00:
	bsr	skip_sep
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_parameter_break_off
	tst.b	seq_cmd-work(a6)
	beq	1f		*MMLでは文字列は無し
	cmpi.b	#'"',(a4)
	bne	@f
	bsr	set_str_to_trk
	bra	mmlx_lp00
@@:
	cmpi.b	#"'",(a4)
	bne	1f
	bsr	set_str_to_trk
	bra	mmlx_lp00
1:
	bsr	chk_num
	bmi	exit_mmlx_lp
	bsr	get_num
	bsr	mmlx_do_wrt_trk_b
	bra	mmlx_lp00
exit_mmlx_lp:
	movem.l	(sp)+,reglist
	rts

set_str_to_trk:				*文字列をソースより摘出してZMD化
	* < d1.l=data
	* < d2.l=data length
	* < d3.b=sum
	* > d2.l=data length
	* > d3.b=sum
	* - all				*(必ず"で囲まれている)
reglist	reg	d0/d5
	movem.l	reglist,-(sp)
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	cmpi.b	#'"',(a4)
	beq	@f
	cmpi.b	#"'",(a4)
	bne	m_string_break_off
@@:
	move.b	(a4)+,d5		*文字列終端記号
	moveq.l	#0,d0
msttlp00:
	cmp.l	a4,d4
	bls	exit_msttlp00
	move.b	(a4)+,d0
	move.l	d0,d1
	bsr	chk_kanji
	bpl	@f
	bsr	mmlx_do_wrt_trk_b
	cmp.l	a4,d4
	bls	m_kanji_break_off	*漢字が途中で終わっている
	move.b	(a4)+,d1
	bsr	mmlx_do_wrt_trk_b
	bra	msttlp00
@@:
	cmp.b	d5,d1
	beq	exit_msttlp00
	cmpi.b	#$0d,d1			*$0dは無視
	beq	msttlp00
	cmpi.b	#$0a,d1
	beq	@f
	bsr	mmlx_do_wrt_trk_b
	bra	msttlp00
@@:
	bsr	cr_line
	moveq.l	#$0d,d1
	bsr	mmlx_do_wrt_trk_b
	moveq.l	#$0a,d1
	bsr	mmlx_do_wrt_trk_b
	tst.b	d1
	bne	msttlp00
exit_msttlp00:
	movem.l	(sp)+,reglist
	rts

mmlx_do_wrt_trk_b:
	* < d1.l=data
	* < d2.l=data count
	* < d3.l=sum
	* < d5.l=limiter
	* > d2.l=data count
	* > d3.l=sum
	cmp.l	d5,d1
	bls	@f		*値がd2以下ならそのまま転送
1:				*値がd2以上の時の処理
	move.b	d1,d0
	andi.b	#$7f,d0		*127以下へ
	add.b	d0,d3		*calc total
	bsr	do_wrt_trk_b
	addq.l	#1,d2
	lsr.l	#7,d1
	bne	1b
	rts
@@:
	move.b	d1,d0
	add.b	d0,d3		*calc total
	bsr	do_wrt_trk_b
	addq.l	#1,d2
	rts
*-----------------------------------------------------------------------------
*check_relation_cmn:			*コマンド関係チェック
*	tst.b	pattern_cmd-work(a6)	*MIDIパターン定義中か
*	bne	m_inappropriate_command	*無関係のコマンドを使用している
*	rts

*-----------------------------------------------------------------------------
do_wrt_zmd_w:			*共通コマンドエリアにword書き込み(ZMD作成時)
	* < d0.w=data
	rol.w	#8,d0
	move.b	d0,(a0)+
	bsr	chk_membdr_cmn
	rol.w	#8,d0
do_wrt_zmd_b:			*共通コマンドエリアにbyte書き込み(ZMD作成時)
	move.b	d0,(a0)+
	bra	chk_membdr_cmn

do_wrt_cmn_l:			*共通コマンドエリアにlong word書き込み(共通コマンド時)
	* < d0.l=data
	rol.l	#8,d0
	bsr	do_wrt_cmn_b

	rol.l	#8,d0
	bsr	do_wrt_cmn_b

	rol.l	#8,d0
	bsr	do_wrt_cmn_b

	rol.l	#8,d0
	bra	do_wrt_cmn_b

do_wrt_cmn_w:			*共通コマンドエリアにword書き込み(共通コマンド時)
	rol.w	#8,d0
	bsr	do_wrt_cmn_b

	rol.w	#8,d0
do_wrt_cmn_b:			*共通コマンドエリアにbyte書き込み(共通コマンド時)
	move.l	zmd_now-work(a6),a0
	addq.l	#1,zmd_now-work(a6)
	add.l	zmd_addr-work(a6),a0
	move.b	d0,(a0)+
chk_membdr_cmn:			*メモリ境界チェック(共通コマンド時)
chk_membdr_zmd:			*メモリ境界チェック(ZMD作成時)
	* < a0.l
	* - all
	cmp.l	zmd_end(pc),a0
	bcs	exit_cmz	*no error
	movem.l	d0/d2-d3/a1,-(sp)
	move.l	zmd_addr(pc),a1
	suba.l	a1,a0
	move.l	a0,d3
	move.l	zmd_size(pc),d2
	add.l	#10240,d2
	bsr	enlarge_mem
	tst.l	d0
	bmi	m_out_of_memory
	move.l	d2,zmd_size-work(a6)
	move.l	a0,zmd_addr-work(a6)
	add.l	a0,d2
	move.l	d2,zmd_end-work(a6)
	add.l	d3,a0
	movem.l	(sp)+,d0/d2-d3/a1
exit_cmz:
	rts

fix_zmd_size:			*ZMDサイズ確定(コンパイル最終処理段階)
	* < a0.l=最終アドレス
	* - all
	movem.l	d0/d2-d3/a1,-(sp)
	move.l	zmd_addr(pc),a1
	suba.l	a1,a0
	move.l	a0,d3
	move.l	d3,d2		*d2=確定サイズ
	bsr	enlarge_mem
	tst.l	d0
	bmi	m_out_of_memory
	move.l	d2,zmd_size-work(a6)
	move.l	a0,zmd_addr-work(a6)
	add.l	a0,d2
	move.l	d2,zmd_end-work(a6)
	add.l	d3,a0
	movem.l	(sp)+,d0/d2-d3/a1
	rts
*-----------------------------------------------------------------------------
do_wrt_ctrl_l:			*制御コマンドエリアにword書き込み
	* < d0.l=data
	rol.l	#8,d0
	bsr	do_wrt_ctrl_b

	rol.l	#8,d0
	bsr	do_wrt_ctrl_b

	rol.l	#8,d0
	bsr	do_wrt_ctrl_b

	rol.l	#8,d0
	bra	do_wrt_ctrl_b

do_wrt_ctrl_w:			*制御コマンドエリアにword書き込み
	* < d0.w=data
	rol.w	#8,d0
	bsr	do_wrt_ctrl_b
	rol.w	#8,d0

do_wrt_ctrl_b:			*制御コマンド関連コード書き込み
	* < d0.b=data
	* - all
	* x d0
reglist	reg	d2/a0-a1
	movem.l	reglist,-(sp)
	move.l	ctrl_now(pc),a1
	add.l	ctrl_addr(pc),a1
	move.b	d0,(a1)+
	cmp.l	ctrl_end(pc),a1
	bcs	@f			*no error
	move.l	ctrl_addr(pc),a1
	move.l	ctrl_size(pc),d2
	add.l	#2048,d2		*new size
	bsr	enlarge_mem
	tst.l	d0
	bmi	m_out_of_memory
	move.l	d2,ctrl_size-work(a6)
	move.l	a0,ctrl_addr-work(a6)
	add.l	a0,d2
	move.l	d2,ctrl_end-work(a6)
@@:
	addq.l	#1,ctrl_now-work(a6)
	movem.l	(sp)+,reglist
	rts
*-----------------------------------------------------------------------------
set_tit_w:
	ror.w	#8,d0
	bsr	set_tit
	ror.w	#8,d0
	bra	set_tit

set_tit_l:
	rol.l	#8,d0
	bsr	set_tit
	rol.l	#8,d0
	bsr	set_tit
	rol.l	#8,d0
	bsr	set_tit
	rol.l	#8,d0
set_tit:				*トラック情報テーブルへの情報一時セット
	* < d0.b=data
	* - all
reglist	reg	d0/d2/a0-a1
	movem.l	reglist,-(sp)
	move.l	trk_inf_tbl(pc),a1
	move.l	tit_now(pc),d2
	move.b	d0,(a1,d2.l)
	addq.l	#1,d2
	move.l	d2,tit_now-work(a6)
	cmp.l	tit_size(pc),d2
	bcs	@f			*no error
	add.l	#2048,d2		*new size
	bsr	enlarge_mem
	tst.l	d0
	bmi	m_out_of_memory
	move.l	d2,tit_size-work(a6)
	move.l	a0,trk_inf_tbl-work(a6)
@@:
	movem.l	(sp)+,reglist
	rts
*-----------------------------------------------------------------------------
set_current_trk:				*書き込みトラックのカレントを設定する
	* < d1.l=trk number(0-n)
reglist	reg	d0/a0
	movem.l	reglist,-(sp)
	move.w	n_of_track(pc),d0
	subq.w	#1,d0
	bcs	m_undefined_track_referred	*未定義のトラックを参照した
	move.l	trk_ptr_tbl(pc),a0
@@:
	cmp.l	(a0),d1
	beq	@f
	lea	tpt_tsize(a0),a0
	dbra	d0,@b
	bra	m_undefined_track_referred	*未定義のトラックを参照した
@@:
	move.l	a0,current_trk_ptr-work(a6)
	movem.l	(sp)+,reglist
	rts

get_trk_addr:					*指定トラックのアドレスを得る
	* < d1.l=trk number(0-n)
	* > a2.l=addr
reglist	reg	d0/a0
	movem.l	reglist,-(sp)
	move.w	n_of_track(pc),d0
	subq.w	#1,d0
	bcs	m_undefined_track_referred	*未定義のトラックを参照した
	move.l	trk_ptr_tbl(pc),a0
@@:
	cmp.l	(a0),d1
	beq	@f
	lea	tpt_tsize(a0),a0
	dbra	d0,@b
	bra	m_undefined_track_referred	*未定義のトラックを参照した
@@:
	move.l	a0,a2
	movem.l	(sp)+,reglist
	rts

wrt_data_d1:
	move.l	d1,d0
	bra	do_wrt_trk_b
wrt_data_d2:
	move.l	d2,d0
	bra	do_wrt_trk_b
wrt_data_d3:
	move.l	d3,d0
	bra	do_wrt_trk_b

do_wrt_trk_v:				*可変長データの場合
	move.w	d0,-(sp)
	cmpi.w	#127,d0
	bhi	@f
	bsr	do_wrt_trk_b
	bra	1f
@@:
	ori.w	#$8000,d0
	bsr	do_wrt_trk_w
1:
	move.w	(sp)+,d0
	rts

do_wrt_trk_w:				*カレント・トラックバッファへの書き込み
	rol.w	#8,d0
	bsr	do_wrt_trk_b
	rol.w	#8,d0
	bra	do_wrt_trk_b

do_wrt_trk_l:				*カレント・トラックバッファへの書き込み
	rol.l	#8,d0
	bsr	do_wrt_trk_b
	rol.l	#8,d0
	bsr	do_wrt_trk_b
	rol.l	#8,d0
	bsr	do_wrt_trk_b
	rol.l	#8,d0
do_wrt_trk_b:				*カレント・トラックバッファへの書き込み
	* < d0.b=data
	* - all
reglist	reg	d0/d2/a0-a1
	btst.b	#c_renp1,tpt_mode_flg(a5)
	bne	exit_dwtb
	movem.l	reglist,-(sp)
	move.l	tpt_addr(a5),a1		*addr
	move.l	tpt_now(a5),d2		*offset
	move.b	d0,(a1,d2.l)
	addq.l	#1,d2
	move.l	d2,tpt_now(a5)
	cmp.l	tpt_size(a5),d2		*size
	bcs	@f			*no error
	add.l	#10240,d2		*new size
	bsr	enlarge_mem
	tst.l	d0
	bmi	m_out_of_memory
	move.l	a0,tpt_addr(a5)
	move.l	d2,tpt_size(a5)
@@:
	movem.l	(sp)+,reglist
exit_dwtb:
	rts

secure_trk_bf:				*トラックバッファの最大長を拡張する
	* < d2.l=あと何バイト必要か
	* - all
reglist	reg	d2/a0-a1
	movem.l	reglist,-(sp)
	move.l	current_trk_ptr(pc),a0
	move.l	tpt_addr(a0),a1
	add.l	tpt_now(a0),d2
	cmp.l	tpt_size(a0),d2
	bcs	@f			*no error
	bsr	enlarge_mem
	tst.l	d0
	bmi	m_out_of_memory
	move.l	current_trk_ptr(pc),a1
	move.l	a0,tpt_addr(a1)
	move.l	d2,tpt_size(a1)
@@:
	movem.l	(sp)+,reglist
	rts
	.include	zcerror.s

cmd_@:				*＠コマンド系
	bsr	skip_spc2
	bsr	chk_num
	bpl	mml_timbre	*数字が後ろにあるなら音色切り換えへ
	moveq.l	#0,d0
	move.b	(a4)+,d0
	bsr	mk_capital	*d0がalphabetなら大文字にして
	subi.b	#$41,d0		*'A'を引いて
	bmi	m_syntax_error
	cmpi.b	#25,d0
	bhi	m_syntax_error
	add.w	d0,d0
	move.w	mml_cmd_@_jmp(pc,d0.w),d0
	jmp	mml_cmd_@_jmp(pc,d0.w)

mml_cmd_@_jmp:
	dc.w	mml_@a-mml_cmd_@_jmp		*@A ARCC
	dc.w	mml_@b-mml_cmd_@_jmp		*@B detune
	dc.w	mml_@c-mml_cmd_@_jmp		*@C ARCC cnf
	dc.w	mml_@d-mml_cmd_@_jmp		*@D dumper
	dc.w	mml_@e-mml_cmd_@_jmp		*@E effect control
	dc.w	mml_@f-mml_cmd_@_jmp		*@F FRQ change
	dc.w	mml_@g-mml_cmd_@_jmp		*@G bend range change
	dc.w	mml_@h-mml_cmd_@_jmp		*@H modulation delay
	dc.w	mml_@i-mml_cmd_@_jmp		*@I ID SET
	dc.w	mml_@j-mml_cmd_@_jmp		*@J special tie mode
	dc.w	mml_@k-mml_cmd_@_jmp		*@K detune
	dc.w	mml_@l-mml_cmd_@_jmp		*@L length
	dc.w	mml_@m-mml_cmd_@_jmp		*@M pitch modulation
	dc.w	mml_@n-mml_cmd_@_jmp		*@N assign change
	dc.w	mml_@o-mml_cmd_@_jmp		*@O OPM noise
	dc.w	mml_@p-mml_cmd_@_jmp		*@P midi pan
	dc.w	mml_@q-mml_cmd_@_jmp		*@Q gate
	dc.w	mml_@r-mml_cmd_@_jmp		*@R non key off mode
	dc.w	mml_@s-mml_cmd_@_jmp		*@S modulation speed
	dc.w	mml_@t-mml_cmd_@_jmp		*@T timer value
	dc.w	mml_@u-mml_cmd_@_jmp		*@U velocity
	dc.w	mml_@v-mml_cmd_@_jmp		*@V volume
	dc.w	mml_@w-mml_cmd_@_jmp		*@W wait
	dc.w	mml_@x-mml_cmd_@_jmp		*@X MIDI data send
	dc.w	mml_@y-mml_cmd_@_jmp		*@Y NRPN
	dc.w	mml_@z-mml_cmd_@_jmp		*@Z after touch

mml_timbre:				*音色切り換え@
	bsr	set_bank_get_pgm_number	*>d1.l=timbre number
	move.b	#timbre_zmd,d0
	bra	@f

mml_timbre2:				*音色切り換え[TIMBRE]
	bsr	set_bank_get_pgm_number	*>d1.l=timbre number
	move.b	#timbre2_zmd,d0
@@:
	bsr	do_wrt_trk_b
	move.l	d1,d0
	bsr	do_wrt_trk_w		*set pgm number
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	rts

set_bank_get_pgm_number:
	* > d1.w=timbre number(0-????)
	* x d2
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted	*音色番号の省略はできない
	bsr	get_num				*get 1st number

	bsr	skip_spc
	cmp.l	a4,d4
	bls	2f
	move.b	(a4),d0
	cmpi.b	#':',d0
	beq	@f
	cmp.b	#',',d0
	bne	2f				*case:@n
@@:
	move.l	a4,d2				*保存
	addq.w	#1,a4
	bsr	skip_spc			*skip ,
	bsr	chk_num
	bmi	sbgpn00				*さっきの':'は別コマンドとみなす
	cmpi.l	#16383,d1
	bhi	m_illegal_bank_number
	move.l	d1,d2
	bsr	get_num				*get 2nd number

	bsr	skip_spc
	cmp.l	a4,d4
	bls	1f				*case:@b,n
	cmpi.b	#',',(a4)
	bne	1f
						*case:@b1,b2,n
	cmpi.l	#127,d1
	bhi	m_illegal_bank_number
	cmpi.l	#127,d2
	bhi	m_illegal_bank_number
	moveq.l	#bank_select_zmd,d0		*バンクセレクトも書きだし
	bsr	do_wrt_trk_b
	move.l	d2,d0
	bsr	do_wrt_trk_b
	move.l	d1,d0
	bsr	do_wrt_trk_b

	bsr	skip_sep			*skip ,
	bsr	chk_num
	bmi	m_illegal_command_line
	bsr	get_num				*get 3rd number
	subq.l	#1,d1
	cmpi.l	#127,d1
	bhi	m_illegal_timbre_number		*illegal sound number
	rts
1:						*case:@b,n
	subq.l	#1,d1
	cmpi.l	#127,d1
	bhi	m_illegal_timbre_number		*illegal sound number
	moveq.l	#bank_select_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d2,d0
	lsr.w	#7,d0
	bsr	do_wrt_trk_b
	move.l	d2,d0
	andi.b	#$7f,d0
	bra	do_wrt_trk_b
sbgpn00:
	move.l	d2,a4
2:						*@n(音色番号が１つしか指定されていない場合)
	subq.l	#1,d1
	cmp.l	#fmsnd_reg_max-1,d1
	bhi	m_illegal_timbre_number		*illegal sound number
	rts

mml_@pitch:				*[@PITCH]
	moveq.l	#rltv_@b_zmd,d2
	bra	@f
mml_pitch:				*[PITCH]
	moveq.l	#detune_@b_zmd,d2
@@:
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
	bsr	get_num
	bsr	chk_k_ovf@b
	bmi	m_illegal_pitch_value
	move.l	d2,d0
	bsr	do_wrt_trk_b	*cmd
	move.l	d1,d0
	bra	do_wrt_trk_w

mml_@detune:				*[@DETUNE]
	moveq.l	#rltv_@k_zmd,d2
	bra	@f
mml_detune:				*[DETUNE]
	moveq.l	#detune_@k_zmd,d2
@@:
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
	bsr	get_num
	bsr	chk_k_ovf@k
	bmi	m_illegal_pitch_value
	move.l	d2,d0
	bsr	do_wrt_trk_b	*cmd
	move.l	d1,d0
	bra	do_wrt_trk_w

mml_@k:
	move.l	#detune_@k_zmd*65536+bend_@k_zmd,d7
	lea	chk_k_ovf@k(pc),a2
	bra	get_@b_src

mml_bend:			*[BEND src,dst,delay,hold]
	bsr	chk_num
	bpl	mml_@b
	lea	switch_strv(pc),a1
	bsr	get_com_no
	bmi	m_illegal_switch_value	*規定外
	move.l	d0,d1
	bne	do_wrt_mbs		*ON指定だった場合はbend.switchと同じ扱いにする
mml_@b:				*@bコマンド
	move.l	#detune_@b_zmd*65536+bend_@b_zmd,d7
	lea	chk_k_ovf@b(pc),a2
get_@b_src:
	moveq.l	#0,d5		*d5=omt
	bsr	chk_num
	bmi	@f
	tas.b	d5		*set omt
	bsr	get_num
	jsr	(a2)		*chk over flow
	bmi	m_illegal_pitch_value
	move.l	d1,d2		*d2=src:-8192～8191
@@:
	bsr	skip_sep
	bsr	chk_num		*値が１個だけの時は
	bmi	@f
	ori.b	#$40,d5		*set omt
	bsr	get_num		*destination
	jsr	(a2)		*chk over flow
	bmi	m_illegal_pitch_value
	move.l	d1,d3		*d3=dest.
@@:				*get delay time
	bsr	skip_sep
	bsr	chk_num
	bmi	@f
	ori.w	#$20,d5		*set omt
	bsr	get_num
	cmpi.l	#-32768,d1
	blt	m_delay_too_long	*絶対値が16bit範囲より大きいとエラー
	cmpi.l	#32767,d1
	bgt	m_delay_too_long	*絶対値が16bit範囲より大きいとエラー
	move.l	d1,d6
@@:				*get hold time/port.time
	bsr	skip_sep
	bsr	chk_num
	bmi	do_wrt_bnd
	ori.w	#$10,d5		*set omt
	bsr	get_num
	move.l	d1,d0
	bpl	@f
	neg.l	d0
	cmpi.l	#max_note_len,d0
	bhi	m_hold_time_too_long
	bra	do_wrt_bnd
@@:
	cmpi.l	#max_note_len,d0
	bhi	m_bend_time_too_long
do_wrt_bnd:
	tst.b	d5
	beq	only_@b			*@bだけの場合
	cmpi.b	#$80,d5
	beq	case_set_dtn		*ディチューン設定ケース
	move.l	d7,d0
	bsr	do_wrt_trk_b
	move.b	d5,d0
	bsr	do_wrt_trk_b		*omt
	add.b	d5,d5
	bcc	@f
	move.w	d2,d0
	bsr	do_wrt_trk_w		*source bend value
@@:
	add.b	d5,d5
	bcc	@f
	move.w	d3,d0
	bsr	do_wrt_trk_w		*destination bend value
@@:
	add.b	d5,d5
	bcc	@f
	move.w	d6,d0
	bsr	consider_trkfrq_st	*trkfrqを考慮する
	bsr	do_wrt_trk_w		*delay time
@@:
	add.b	d5,d5
	bcc	exit_dwb
	move.w	d1,d0
	bpl	@f
	neg.w	d0
	bsr	consider_trkfrq_st	*trkfrqを考慮する
	neg.w	d0
	bsr	do_wrt_trk_w		*hold time
	bra	exit_dwb
@@:
	bsr	consider_trkfrq_st	*trkfrqを考慮する
	bsr	do_wrt_trk_w		*hold time
exit_dwb:
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	rts

only_@b:
	moveq.l	#bend_sw_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#0,d0
	bsr	do_wrt_trk_b
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	rts

case_set_dtn:				*ディチューン設定ケース
	swap	d7
	move.l	d7,d0
	bsr	do_wrt_trk_b
	move.l	d2,d0
	bsr	do_wrt_trk_w
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	rts

chk_k_ovf@b:			*ディチューン値のover flowチェック
	* < d1.l=pitch
	cmp.l	#-8192,d1
	blt	@f
	cmp.l	#8191,d1
	ble	exit_k_ovf@b
@@:				*case:over flow
	move.w	#8,ccr		*minus
	rts
exit_k_ovf@k:
exit_k_ovf@b:
	move.w	#0,ccr		*plus
	rts

chk_k_ovf@k:			*デチューン値のover flowチェック
	* < d1.l=pitch
	cmp.l	#-7680,d1
	blt	@f
	cmp.l	#7680,d1
	ble	exit_k_ovf@k
@@:				*case:over flow
	move.w	#8,ccr		*minus
	rts

mml_bend_switch:				*[BEND.SWITCH]
	bsr	chk_num
	bpl	@f
	lea	switch_strv(pc),a1
	bsr	get_com_no
	bmi	m_illegal_switch_value	*規定外
	move.l	d0,d1
	bra	do_wrt_mbs
@@:
	bsr	get_num
	cmp.l	#1,d1
	bhi	m_illegal_switch_value	*規定外
do_wrt_mbs:
	moveq.l	#bend_sw_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d1,d0			*mode value
	bra	do_wrt_trk_b

mml_auto_portament:			*[AUTO_PORTAMENT]
	moveq.l	#-1,d5			*sw=notouch
	bsr	chk_num
	bpl	@f
	lea	switch_strv(pc),a1
	bsr	get_com_no		*> OFF:0, ON:1
	bmi	@f			*規定外ならば無指定とみなす
	move.l	d0,d5
@@:
	bsr	skip_sep
	moveq.l	#0,d6			*omt
	bsr	chk_num
	bmi	@f
	bsr	get_num			*get delay time
	cmpi.l	#-32768,d1
	blt	m_delay_too_long	*絶対値が16bit範囲より大きいとエラー
	cmpi.l	#32767,d1
	bgt	m_delay_too_long	*絶対値が16bit範囲より大きいとエラー
	move.l	d1,d2
	moveq.l	#$80,d6
@@:
	bsr	skip_sep
	bsr	chk_num
	bmi	do_wrt_atport
	bsr	get_num			*get hold time
	move.l	d1,d0
	bpl	@f
	neg.l	d0
	cmpi.l	#max_note_len,d0
	bhi	m_hold_time_too_long
	bra	atprt00
@@:
	cmpi.l	#max_note_len,d0
	bhi	m_portament_time_too_long
atprt00:
	or.b	#$40,d6			*omt
do_wrt_atport:
	moveq.l	#auto_portament_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d5,d0			*sw
	bsr	do_wrt_trk_b
	move.l	d6,d0			*omt
	bsr	do_wrt_trk_b
	tst.b	d6
	bpl	@f
	move.l	d2,d0			*delay
	bsr	consider_trkfrq_st	*trkfrqを考慮する
	bsr	do_wrt_trk_w
@@:
	add.b	d6,d6
	bpl	1f
	move.l	d1,d0			*hold
	bpl	@f
	neg.w	d0
	bsr	consider_trkfrq_st	*trkfrqを考慮する
	neg.w	d0
	bra	do_wrt_trk_w
@@:
	bsr	consider_trkfrq_st	*trkfrqを考慮する
	bra	do_wrt_trk_w
1:
	rts

mml_auto_portament_switch:		*[AUTO_PORTAMENT.SWITCH]
	bsr	chk_num
	bpl	@f
	lea	switch_strv(pc),a1
	bsr	get_com_no		*> OFF:0, ON:1
	bmi	m_illegal_switch_value	*規定外
	move.l	d0,d1
	bra	do_wrt_mfp
@@:
	bsr	get_num
	cmp.l	#1,d1
	bhi	m_illegal_switch_value	*規定外
do_wrt_mfp:
	moveq.l	#auto_portament_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d1,d0			*sw
	bsr	do_wrt_trk_b
	moveq.l	#0,d0			*omt=0
	bsr	do_wrt_trk_b

mml_echo:				*[ECHO]
	bsr	chk_num			*スイッチOFF、またはディレイタイムの取得
	bmi	@f
	bsr	get_length		*> d0.l=length
	move.w	d0,tpt_echo_dly(a5)
	beq	mech_sw_off
	st.b	tpt_echo_switch(a5)	*ON
	bra	get_mech_vdec
@@:
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	move.b	(a4),d0
	cmpi.b	#'*',d0
	bne	@f
	addq.w	#1,a4
	bsr	chk_num
	bmi	m_illegal_switch_value	*規定外
	bsr	get_num
	cmpi.l	#max_note_len,d1
	bhi	m_delay_too_long
	move.w	d1,tpt_echo_dly(a5)	*0ならばOFFにほかならない
	beq	mech_sw_off
	st.b	tpt_echo_switch(a5)	*ON
	bra	get_mech_vdec
@@:					*文字列'OFF'か
	cmpi.b	#',',d0
	beq	get_mech_vdec
	lea	echo_strv(pc),a1
	bsr	get_com_no
	bmi	m_illegal_switch_value	*規定外
mech_sw_off:
	clr.b	tpt_echo_switch(a5)	*OFF
get_mech_vdec:				*減衰音量値
	bsr	skip_sep
	bsr	chk_num
	bmi	get_mech_loop
	bsr	get_num
	cmpi.l	#-128,d1
	blt	m_illegal_volume_value
	cmpi.l	#127,d1
	bgt	m_illegal_volume_value
	move.b	d1,tpt_echo_vdec(a5)
get_mech_loop:				*ループタイム
	bsr	skip_sep
	bsr	chk_num
	bmi	@f
	bsr	get_num
	cmpi.l	#65535,d1
	bhi	m_illegal_repeat_time
	move.w	d1,tpt_echo_loop(a5)
	rts
@@:					*文字列'LOOP'か
	cmp.l	a4,d4
	bls	m_illegal_command_line
	cmp.b	#']',(a4)		*最後のパラメータが省略されているか
	beq	@f
	lea	mechlp_strv(pc),a1
	bsr	get_com_no
	bmi	m_illegal_switch_value
	move.w	d0,tpt_echo_loop(a5)
@@:
	rts

mml_effect_chorus:		*[EFFECT.CHORUS]
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
	bsr	get_num
	cmp.l	#127,d1
	bhi	m_illegal_effect_parameter
	moveq.l	#effect_ctrl_zmd,d0		*cmd code
	bsr	do_wrt_trk_b
	moveq.l	#2,d0
	bsr	do_wrt_trk_b	*omt
	move.l	d1,d0
	bra	do_wrt_trk_b	*value

mml_effect_delay:		*[EFFECT.DELAY]
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
	bsr	get_num
	cmp.l	#127,d1
	bhi	m_illegal_effect_parameter
	moveq.l	#effect_ctrl_zmd,d0		*cmd code
	bsr	do_wrt_trk_b
	moveq.l	#4,d0
	bsr	do_wrt_trk_b	*omt
	move.l	d1,d0
	bra	do_wrt_trk_b	*value

mml_effect_reverb:		*[EFFECT.REVERB]
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
	bsr	get_num
	cmp.l	#127,d1
	bhi	m_illegal_effect_parameter
	moveq.l	#effect_ctrl_zmd,d0		*cmd code
	bsr	do_wrt_trk_b
	moveq.l	#1,d0
	bsr	do_wrt_trk_b	*omt
	move.l	d1,d0
	bra	do_wrt_trk_b	*value

mml_effect:			*[EFFECT]
mml_@e:				*@E エフェクトコントロール
	moveq.l	#1,d2
	moveq.l	#0,d5		*omt
	move.l	temp_buffer(pc),a1
@@:
	bsr	chk_num
	bmi	1f
	bsr	get_num
	cmp.l	#127,d1
	bhi	m_illegal_effect_parameter
	move.b	d1,(a1)+
	or.b	d2,d5
1:
	bsr	skip_spc
	cmp.l	a4,d4
	bls	@f
	cmpi.b	#',',(a4)
	bne	@f
	bsr	skip_sep			*skip ','
	add.b	d2,d2
	bne	@b
@@:
	move.l	temp_buffer(pc),a1
	moveq.l	#effect_ctrl_zmd,d0		*cmd code
	bsr	do_wrt_trk_b
	move.l	d5,d0				*omt
	bsr	do_wrt_trk_b
mml@elp:
	lsr.b	#1,d5
	bcc	@f
	move.b	(a1)+,d0
	bsr	do_wrt_trk_b
@@:
	tst.b	d5
	bne	mml@elp
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	rts

mml_frequency:			*[FREQUENCY]
mml_@f:				*@F ADPCM周波数切り換え
	moveq.l	#4,d1		*default
	bsr	chk_num
	bmi	@f
	bsr	get_num
	cmpi.l	#6,d1
	bls	@f
	bsr	m_illegal_frequency_number
@@:
	moveq.l	#frq_chg_zmd,d0
	bsr	do_wrt_trk_b
	bsr	wrt_data_d1
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	rts

mml_ch_pressure:			*[CH_PRESSURE]
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	cmpi.b	#'-',(a4)
	beq	rltv_ch_prs
	cmpi.b	#'+',(a4)
	beq	rltv_ch_prs
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
	bsr	get_num
	cmpi.l	#127,d1
	bhi	m_illegal_velocity_value
	moveq.l	#ch_pressure_zmd,d0
	bsr	do_wrt_trk_b
	bra	wrt_data_d1

rltv_ch_prs:				*相対CH_PRESSURE
	bsr	get_num
	move.l	d1,d0
	bpl	@f
	neg.l	d0
@@:
	cmpi.l	#127,d0
	bhi	m_illegal_velocity_value
	moveq.l	#rltv_ch_pressure_zmd,d0
	bsr	do_wrt_trk_b
	bra	wrt_data_d1

mml_polyphonic_pressure:			*[POLYPHONIC_PRESSURE]
	move.b	tpt_octave(a5),oct_wk-work(a6)	*一時保存
	bsr	chk_num
	bmi	@f
	bsr	get_num				*数値によるノート指定
	move.l	d1,d2
	bra	chk_plyprsky
@@:						*文字によるノート指定
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_illegal_command_line
	move.b	(a4),d0
	bsr	oct_chk				*オクターブがあれば取得
	bmi	@b
	bsr	get_port_key
	move.l	d0,d2
chk_plyprsky:
	cmpi.l	#127,d2
	bhi	m_illegal_note_number
	move.b	oct_wk(pc),tpt_octave(a5)	*復元
	bsr	skip_sep
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	cmpi.b	#'-',(a4)
	beq	@f
	cmpi.b	#'+',(a4)
	bne	get_prsvel
@@:
	tas.b	d2				*相対ケース
get_prsvel:
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
	bsr	get_num
	move.l	d1,d0
	bpl	@f
	neg.l	d0
@@:
	cmpi.l	#127,d0
	bhi	m_illegal_velocity_value
	moveq.l	#polyphonic_pressure_zmd,d0
	bsr	do_wrt_trk_b		*cmd
	move.l	d2,d0
	bsr	do_wrt_trk_b		*note
	move.l	d1,d0
	bra	do_wrt_trk_b		*velocity

mml_@l:					*@Lコマンド
	btst.b	#c_renp1,tpt_mode_flg(a5)	*連符内にLコマンドは使用出来ない
	bne	m_illegal_command_in_brace
	bra	get_@l

mml_timer:			*[TIMER]
mml_@t:				*@Tコマンド
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	move.b	(a4),d0
	cmpi.b	#'-',d0
	beq	mml_rltv_@tm
	cmpi.b	#'+',d0
	beq	mml_rltv_@tp
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted	*no @T value
	bsr	get_num
	move.b	#tempo_@t_zmd,d0
	bsr	do_wrt_trk_b	*write cmd
	move.l	d1,d0
	bsr	do_wrt_trk_w	*timer value
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	rts

mml_rltv_@tm:
	moveq.l	#-1,d1
	bra	@f
mml_rltv_@tp:
	moveq.l	#1,d1
@@:
	move.l	a4,d0
	addq.w	#1,a4
	bsr	chk_num
	bmi	@f		*no @T value
	move.l	d0,a4
	bsr	get_num
@@:
	moveq.l	#rltv_@t_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d1,d0
	bsr	do_wrt_trk_w
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	rts

mml_panpot:				*[PANPOT]
	bsr	chk_num
	bpl	mml_@p
	cmp.l	a4,d4
	bls	mml_@p
	move.b	(a4)+,d0		*Lnn,Rnnという表記に対応
	bsr	mk_capital
	bsr	chk_num
	bmi	@f
	bsr	get_num
	tst.l	d1			*パラメータは1～63まで
	beq	m_illegal_panpot_value
	cmpi.l	#63,d1
	bhi	m_illegal_panpot_value
	cmpi.b	#'L',d0
	bne	@f
	move.l	d1,d0
	moveq.l	#64,d1
	sub.b	d0,d1			*1-63
	bra	do_wrt_@p
@@:
	cmpi.b	#'R',d0
	bne	@f
	add.b	#64,d1			*65-127
	bra	do_wrt_@p
@@:
	cmpi.b	#'M',d0
	bne	m_illegal_panpot_value
	moveq.l	#64,d1			*64
	bra	do_wrt_@p

mml_@panpot:			*[@PANPOT]
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted	*no value
	move.b	(a4),d0
	cmpi.b	#'-',d0
	beq	mml_rltv_@pm
	bsr	chk_num
	bpl	mml_rltv_@pp
	bra	m_parameter_cannot_be_omitted	*no value

mml_@p:				*@pコマンド
	bsr	skip_spc
	cmp.l	a4,d4
	bls	@f
	move.b	(a4),d0
	cmpi.b	#'+',d0
	beq	mml_rltv_@pp
	cmpi.b	#'-',d0
	beq	mml_rltv_@pm
@@:
	moveq.l	#64,d1
	bsr	chk_num
	bmi	do_wrt_@p
	bsr	get_num
	cmpi.l	#128,d1
	bhi	m_illegal_panpot_value
do_wrt_@p:
	moveq.l	#panpot_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d1,d0
	bsr	do_wrt_trk_b
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	rts

mml_rltv_@pm:
	moveq.l	#-1,d1
	bra	@f
mml_rltv_@pp:
	moveq.l	#1,d1
@@:
	move.l	a4,d0
	addq.w	#1,a4
	bsr	chk_num
	bmi	wrtmml@p	*no @p value
	move.l	d0,a4
	bsr	get_num
	move.l	d1,d0
	bpl	@f
	neg.l	d0
@@:
	cmpi.l	#127,d0
	bhi	m_illegal_panpot_value
wrtmml@p:
	moveq.l	#rltv_pan_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d1,d0
	bsr	do_wrt_trk_b
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	rts

mml_@q:					*@qコマンド
	bsr	chk_num
	bmi	fixedgtsw
	bsr	get_num
	tst.l	d1
	bne	@f
	moveq.l	#0,d1			*0の場合はQ8と同じ
	move.b	gate_range(pc),d1
	bra	set_q
@@:
	bclr.b	#c_q_sgn,tpt_mode_flg(a5)
	tst.l	d1
	bpl	@f
	bset.b	#c_q_sgn,tpt_mode_flg(a5)
	neg.l	d1
@@:
	cmpi.l	#32767,d1
	bhi	m_illegal_gate_time		*illegal @Q
	neg.w	d1
	move.w	d1,tpt_gate_time(a5)
fixedgtsw:
	bsr	skip_sep			*skip ','
	bsr	chk_num
	bmi	mml_lp
	bsr	get_num
	tst.l	d1
	beq	@f
	bset.b	#c_@q,tpt_mode_flg(a5)		*@Q mode switch on (fixed gate time)
	bra	mml_lp
@@:
	bclr.b	#c_@q,tpt_mode_flg(a5)		*@Q mode switch off (normal @Q)
	bra	mml_lp

mml_voice_reserve:				*[VOICE_RESERVE]
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted	*no value
	move.b	(a4),d0
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted	*no value
	bsr	get_num
	subq.l	#1,d1
	cmpi.l	#255,d1
	bhi	m_illegal_reservation		*illegal value
	moveq.l	#voice_reserve_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d1,d0
	bra	do_wrt_trk_b

mml_@volume:					*[@VOLUME n]
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted	*no @V value
	move.b	(a4),d0
	cmpi.b	#'-',d0
	beq	rltv_@volume_dwn		*相対ボリューム
	cmpi.b	#'+',d0
	beq	rltv_@volume_up			*相対ボリューム
	bsr	chk_num
	bpl	rltv_@volume_up			*相対ボリューム
	bra	m_parameter_cannot_be_omitted	*no @V value

mml_volume:					*[VOLUME n]
mml_@v:						*@Vコマンド
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted	*no @V value
	move.b	(a4),d0
	cmpi.b	#'+',d0
	beq	rltv_@volume_up			*相対ボリューム
	cmpi.b	#'-',d0
	beq	rltv_@volume_dwn			*相対ボリューム
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted	*no @V value
	bsr	get_num
	mulu	tpt_trkvol(a5),d1
	lsr.l	#7,d1				*/128
	cmpi.l	#127,d1
	bhi	m_illegal_volume_value		*illegal @V
	moveq.l	#volume_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d1,d0
	bsr	do_wrt_trk_b
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	rts

rltv_@volume_dwn:			*相対ボリュームダウン
@@:
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted	*no @V value
	cmpi.b	#'-',(a4)
	bne	@f
	addq.w	#1,a4
	bra	@b
@@:
	bsr	chk_num
	bmi	1f
	bsr	get_num
	cmp.l	#127,d1
	bhi	m_illegal_volume_value
	move.b	d1,tpt_rltv_vol(a5)
	bra	@f
1:
	moveq.l	#0,d1
	move.b	tpt_rltv_vol(a5),d1
@@:
	moveq.l	#rltv_vol_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d1,d0
	neg.b	d0
	bsr	do_wrt_trk_b
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	rts

rltv_@volume_up:			*相対ボリュームアップ
@@:
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted	*no @V value
	cmpi.b	#'+',(a4)
	bne	@f
	addq.w	#1,a4
	bra	@b
@@:
	bsr	chk_num
	bmi	1f
	bsr	get_num
	cmpi.l	#127,d1
	bhi	m_illegal_volume_value
	move.b	d1,tpt_rltv_vol(a5)
	bra	@f
1:
	moveq.l	#0,d1
	move.b	tpt_rltv_vol(a5),d1
@@:
	moveq.l	#rltv_vol_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d1,d0
	bsr	do_wrt_trk_b
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	rts

mml_midi_data:			*[MIDI_DATA]
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	cmpi.b	#'{',(a4)
	bne	mml_@x
	addq.w	#1,a4
mml_@x:					*MIDI data transmit
	moveq.l	#midi_transmission_zmd,d0		*send cmd code
	bsr	do_wrt_trk_b
	moveq.l	#0,d0			*no comment
	bsr	do_wrt_trk_b		*comment length
	move.l	tpt_now(a5),d5
	bsr	do_wrt_trk_l		*データ長サイズ分ダミーデータの書き込みでリザーブ
	move.l	#$ff,d2			*check over $7f
	bsr	wrt_send_data		*>d2.l=data length
	tst.l	d2
	beq	m_parameter_cannot_be_omitted	*値が一個もない時はｴﾗｰ
	move.l	tpt_addr(a5),a1
	add.l	d5,a1
	rept	4
	rol.l	#8,d2
	move.b	d2,(a1)+		*サイズ書き込み
	endm
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_illegal_command_line
	cmpi.b	#'}',(a4)
	bne	@f
	addq.w	#1,a4
@@:
	rts

mml_nrpn:			*[NRPN]
mml_@y:				*@Y コマンド
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted	*値が一個もない時はｴﾗｰ
	moveq.l	#NRPN_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#$7f,d2			*limit
	bsr	wrt_send_data		*>d2.l=n of data
	cmpi.l	#3,d2			*LSB省略か
	bcs	1f
	beq	@f
	cmpi.l	#4,d2
	bhi	m_too_many_parameters	*データがない
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	rts
@@:
	moveq.l	#-1,d0			*LSBが省略
	bsr	do_wrt_trk_b
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	rts
1:
	cmpi.w	#2,d2
	bcs	m_parameter_shortage
	moveq.l	#-1,d0			*データ全部省略(アドレスの未指定)
	bsr	do_wrt_trk_w
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	rts

mml_aftertouch_level:			*[AFTERTOUCH.LEVEL]
	moveq.l	#aftertouch_zmd,d0
	bsr	do_wrt_trk_b
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	cmpi.b	#',',(a4)
	beq	1f
	lea	switch_strv2(pc),a1
	bsr	get_com_no
	bmi	1f
	subq.b	#1,d0			*-1,0,1,2
	beq	mal_off			*OFF
	bra	@f
1:
	moveq.l	#0,d0			*no touch
@@:
	move.l	tpt_now(a5),d5		*あとでomtを格納するため
	bsr	do_wrt_trk_b		*mode
	moveq.l	#0,d0
	bsr	do_wrt_trk_w		*omt=0,rltvmark=0
	bsr	skip_sep
	bsr	get_@z_prm
	bsr	chk_num
	bpl	m_too_many_parameters	*パラメータ多すぎ
	move.l	tpt_addr(a5),a1
	lea	1(a1,d5.l),a1
	cmpi.w	#1,d6			*パラメータが複数あるか
	bcs	1f
	bne	@f
	move.b	#1,-1(a1)		*1つのときは強制的にoptional mode
@@:
	move.b	d6,(a1)+		*set omt
	beq	@f
	move.b	d3,(a1)+		*set rltvmark
@@:
	rts
1:					*rltvマークはいらない
	subq.l	#1,tpt_now(a5)
	rts

mal_off:
	moveq.l	#0,d0			*mode=0,omt=0 → OFF
	bra	do_wrt_trk_w

mml_@z:					*アフタータッチ @Z
	moveq.l	#aftertouch_zmd,d0
	bsr	do_wrt_trk_b
	move.l	tpt_now(a5),d5		*あとでmode/omtを格納するため
	moveq.l	#0,d0
	bsr	do_wrt_trk_w		*2bytes確保(mode=0,omt=0)
	bsr	do_wrt_trk_b		*1bytes確保(rltvmark=0)
	bsr	get_@z_prm
	bsr	chk_num
	bpl	m_too_many_parameters	*パラメータ多すぎ
	move.l	tpt_addr(a5),a1
	add.l	d5,a1
	moveq.l	#1,d0			*optional mode
	cmpi.w	#1,d6			*パラメータが複数あるか
	bcs	1f
	beq	@f
	moveq.l	#-1,d0			*1/8 mode(複数の場合)
@@:
	move.b	d0,(a1)+		*mode
	move.b	d6,(a1)+		*set omt
	beq	mml_lp
	move.b	d3,(a1)+		*set rltvmark
	bra	mml_lp
1:
	subq.l	#1,tpt_now(a5)
	bra	mml_lp

get_@z_prm:
	* > d6.b=omt
	moveq.l	#0,d6			*omt
	bsr	skip_spc
	cmp.l	a4,d4
	bls	exit_g@zp
	cmpi.b	#',',(a4)
	beq	@f
	bsr	chk_num
	bmi	exit_g@zp	*@zだけの場合はmode=0,omt=0でスイッチオフ
@@:
	moveq.l	#0,d2		*loop counter
	moveq.l	#0,d3		*previous value
mml_aftc_lp01:
	moveq.l	#0,d1
	bsr	chk_num
	bpl	@f
	cmp.l	a4,d4
	bls	exit_g@zp
	cmpi.b	#',',(a4)
	bne	exit_g@zp
	bsr	skip_sep	*skip ','
	bra	next_g@zp
@@:				*levelパラメータ有り
	move.b	(a4),d0
	cmpi.b	#'+',d0
	beq	@f
	cmpi.b	#'-',d0
	bne	1f
@@:				*相対指定ケース
	bsr	get_num
	cmpi.l	#127,d1
	bgt	m_illegal_aftertouch_value
	cmpi.l	#-128,d1
	blt	m_illegal_aftertouch_value
	bset.l	d2,d3			*set rltv mark
	bra	@f
1:				*直値ケース
	bsr	get_num
	cmpi.l	#127,d1
	bhi	m_illegal_aftertouch_value	*値が7bit範囲より大きいとエラー
@@:
	bsr	skip_sep			*skip ','
	* < d1.l=aftertouch level
	bset.l	d2,d6			*set omt
	move.l	d1,d0
	bsr	do_wrt_trk_b	*level書き込み
next_g@zp:
	bsr	chk_num
	bpl	@f
	cmp.l	a4,d4
	bls	exit_g@zp
	cmpi.b	#',',(a4)	*まだパラメータがあるか
	bne	exit_g@zp
@@:
	addq.w	#1,d2
	cmpi.w	#aftc_max,d2
	bcs	mml_aftc_lp01
exit_g@zp:
	rts

mml_r:				*R 休符
	btst.b	#c_renp1,tpt_mode_flg(a5)
	beq	@f
	addq.l	#1,tpt_renp_cnt(a5)	*連符内なら個数をインクリメント
@@:
	moveq.l	#rest_zmd,d2
	bra	knnn

mml_@w:				*@W ウェイト
	btst.b	#c_renp1,tpt_mode_flg(a5)
	beq	@f
	addq.l	#1,tpt_renp_cnt(a5)	*連符内なら個数をインクリメント
@@:
	moveq.l	#0,d1		*音長格納
	moveq.l	#wait_zmd,d2
	bra	knnn

mml_ag:				*キーコード
	* < d1.w=(0～6)*2
	btst.b	#c_renp1,tpt_mode_flg(a5)
	beq	@f
	addq.l	#1,tpt_renp_cnt(a5)	*連符内なら個数をインクリメント
@@:
	lsr.w	#1,d1			*/2
	bsr	get_key			*key codeを得る
	move.b	d0,d2			*save kc
knnn:
	move.l	arry_stock(pc),a3		*今回の結果をストアするワーク
	bclr.b	#c_step,tpt_mode_flg(a5)	*initialize the work
	bclr.b	#c_gate,tpt_mode_flg(a5)	*initialize the work
	move.b	#$80,vl_buf-work(a6)
	move.b	d2,nt_buf-work(a6)
	bmi	@f				*通常音符は
	bsr	velocity_sequence		*ベロシティシーケンス実行
@@:
	bsr	get_ag_length			*音長等のパラメータ取得
	moveq.l	#0,d0
	move.b	nt_buf(pc),d0
	bmi	@f
	tst.w	step_buf-work(a6)		*d3.w=step
	bne	@f
	btst.b	#c_gate,tpt_mode_flg(a5)	*V2コンパチの音長0ノートか
	bne	@f
	bsr	skip_spc
	cmp.l	a4,d4
	bls	v2_len0_note			*YES(ST=0,GT=0)
	cmpi.b	#'&',(a4)			*tieかどうか
	bne	v2_len0_note			*TIEじゃなくて(ST=0,GT=0)
@@:
	bsr	scan_prev_notes			*以前鳴ったものとの比較
	move.w	step_buf(pc),d3			*d3.w=step
	btst.b	#c_renp2,tpt_mode_flg(a5)	*↑連符処理(PASS2)
	beq	chk_wk_echo
	move.w	tpt_renp_length(a5),d3
	tst.w	tpt_renp_surplus(a5)
	beq	@f
	addq.w	#1,d3
	subq.w	#1,tpt_renp_surplus(a5)		*↓連符処理(PASS2)
@@:
	move.w	d3,step_buf-work(a6)
chk_wk_echo:
	tst.b	d0
	bmi	wrt_kc_ag		*@W,Rはエコーなし
	tst.b	tpt_echo_switch(a5)
	beq	wrt_kc_ag
	cmp.w	tpt_echo_dly(a5),d3	*dly方が大きい場合は処理なし
	bhi	echo_case
wrt_kc_ag:
	* < d0.w=note number
	* < d3.w=step_buf
	move.w	d0,(a3)+		*flag=0,note(b)
	bsr	do_wrt_trk_b		*write kc
	move.l	d3,d0
	bsr	consider_trkfrq_st	*trkfrqを考慮する(step)
	jsr	do_wrt_trk_v		*set step time
	cmpi.b	#wait_zmd,d2
	beq	exit_ag			*Gatetime/Velocityなし
	bsr	skip_spc
	cmp.l	a4,d4
	bls	@f
	cmpi.b	#'&',(a4)		*tieかどうか
	bne	@f
	addq.w	#1,a4
	move.w	#TIE_GATE,d0		*tie case
	bra	set_gt
@@:
	move.w	gate_buf(pc),d0
	btst.b	#c_gate,tpt_mode_flg(a5)
	bne	@f
	move.w	step_buf(pc),d0
	bsr	calc_gt			*> d0=gate time
@@:
	* < d0.w=gate time(0-)
	bsr	consider_trkfrq_gt	*trkfrqを考慮する
set_gt:
	move.w	d0,(a3)+		*gate time
	bpl	@f
	move.l	tpt_now(a5),(a3)
	bsr	do_wrt_trk_w		*TIE($8000)
	bra	wrt_vel_ag
@@:
	st.b	-3(a3)			*通常ノートなら書き換えフェーズ考慮不要
	jsr	do_wrt_trk_v		*set gate time
wrt_vel_ag:
	move.l	#-1,4(a3)		*endcode
	cmpi.b	#rest_zmd,d2
	beq	exit_ag			*休符はベロシティなし
	move.b	vl_buf(pc),d0
	bsr	do_wrt_trk_b		*velocity
exit_ag:
	bsr	rewrite_note_gate
	bsr	preserve_this_note	*今回の発音内容を保存
	bra	mml_lp

v2_len0_note:				*V2 音長0ノート
	moveq.l	#len0_note_zmd,d0
	bsr	do_wrt_trk_b
	move.b	nt_buf(pc),d0
	bsr	do_wrt_trk_b
	move.b	vl_buf(pc),d0
	bsr	do_wrt_trk_b		*velocity
	bra	mml_lp

echo_case:				*疑似エコー・プリプロセッシング(単音)
	* < d3.w=step_buf
	bsr	skip_spc
	cmp.l	a4,d4
	bls	@f
	cmpi.b	#'&',(a4)		*tieかどうか
	bne	@f
	addq.w	#1,a4
	move.w	#TIE_GATE,d1
	bra	echo_set_ag
@@:					*タイ/スラーなし
	move.w	gate_buf(pc),d0
	btst.b	#c_gate,tpt_mode_flg(a5)
	bne	@f
	move.w	d3,d0
	bsr	calc_gt			*> d0=gate time
@@:
	* < d0.w=gate time(0-)
	bsr	consider_trkfrq_gt	*trkfrqを考慮する
	move.l	d0,d1			*d1.w=gate
echo_set_ag:
	move.w	tpt_echo_loop(a5),d2
	subq.w	#1,d2			*for dbra
	moveq.l	#0,d5
	move.b	vl_buf(pc),d5
	cmpi.b	#$80,d5
	bne	@f
	move.w	#192,d5			*nuetral:192
@@:
	move.b	tpt_echo_vdec(a5),d6	*減衰量
	ext.w	d6
echopelp:				*ベロシティが絶対値あるいは相対値指定の場合
	tst.w	d1
	beq	@f
	moveq.l	#0,d0
	move.b	nt_buf(pc),d0
	move.w	d0,(a3)+		*flag=0,note(b)
	bra	1f
@@:
	moveq.l	#wait_zmd,d0		*gate=0ならばウェイトとする
1:
	bsr	do_wrt_trk_b		*write kc
	move.w	tpt_echo_dly(a5),d0
	tst.w	d2			*最後ならばd3がstep
	beq	1f
	cmp.w	d0,d3
	bcc	@f
1:
	move.w	d3,d0
@@:
	bsr	do_wrt_trk_v		*step
	move.w	tpt_echo_dly(a5),d0
	tst.w	d1
	beq	echope_next		*gate=0ならばウェイトなので以下の処理いらず
	bpl	@f
	tst.w	d2			*tie case
	bne	2f
	move.w	#TIE_GATE,d0		*タイ時最後ならば
	bra	2f
@@:
	tst.w	d2
	bne	1f
	move.w	d1,d0			*最後は残り全部gate
	bra	2f
1:
	sub.w	d0,d1
2:
	move.w	d0,(a3)+		*gate time
	bpl	@f
	move.l	tpt_now(a5),(a3)+
	bsr	do_wrt_trk_w		*tie
	bra	wrt_vel_ag_ec
@@:
	st.b	-3(a3)			*通常ノートなら書き換えフェーズ考慮不要
	addq.w	#4,a3
	bsr	do_wrt_trk_v		*set gate time
wrt_vel_ag_ec:
	move.l	#-1,(a3)		*endcode
	move.b	d5,d0
	bsr	do_wrt_trk_b		*velocity
	tst.b	d5
	bpl	ech_absvlo
	add.w	d6,d5			*減衰処理
	cmpi.w	#129,d5
	bcc	@f
	move.w	#129,d5
	bra	echope_next
@@:
	cmpi.w	#255,d5
	bls	echope_next
	move.w	#255,d5
	bra	echope_next
ech_absvlo:				*ベロシティが絶対値指定の場合
	add.w	d6,d5			*減衰処理
	bpl	@f
	moveq.l	#0,d5
	bra	echope_next
@@:
	cmp.w	#127,d5
	bls	echope_next
	moveq.l	#127,d5
echope_next:
	sub.w	tpt_echo_dly(a5),d3
	bls	@f
	dbra	d2,echopelp
	tst.w	tpt_echo_loop(a5)	*無限ループケース
	beq	echopelp
@@:
	bsr	rewrite_note_gate
	bsr	preserve_this_note	*今回の発音内容を保存
	bra	mml_lp

get_length:			*get 音長
	* > d0.w=length
	* - all
	movem.l	d1/a1,-(sp)
	bsr	get_num		*>d0.l=number value
	tst.b	step_input-work(a6)
	beq	@f
	move.l	d1,d0		*ステップ入力モードの時はすべての音長が
	bra	exit_gtln	*ステップタイムにて表される
@@:
	tst.l	d1
	beq	m_illegal_note_length	*0は駄目
	moveq.l	#0,d0
	move.l	zmd_addr(pc),a1
	move.w	z_master_clock(a1),d0
	cmp.l	d0,d1
	bhi	m_illegal_note_length	*絶対音長が0以下になってしまう
	divu	d1,d0
	bvs	m_illegal_note_length	*絶対音長が大きすぎる
exit_gtln:
	move.l	d0,d1
	swap	d1
	tst.w	d1
	beq	@f
	bsr	m_surplus_in_division	*余りが発生している
@@:
	andi.l	#$ffff,d0
	cmp.l	#max_note_len,d0
	bhi	m_illegal_note_length	*絶対音長が大きすぎる
	movem.l	(sp)+,d1/a1
	rts

futen_ope:			*符点処理
	* < d0.w=length
	* > d1.w=real length
	move.w	d0,d1
fop__lp:
	* < d1.w=total length
	* < d0.w=futen sorce length
	bsr	skip_spc
	cmp.l	a4,d4
	bls	exit_fto
	cmpi.b	#'.',(a4)
	bne	@f
	addq.w	#1,a4
	btst.b	#c_renp1,tpt_mode_flg(a5)	*連符内に符点指定は出来ない
	bne	m_group_notes_command_error
	lsr.w	#1,d0
	add.w	d0,d1
for_ftlp:
	bmi	m_illegal_note_length
	cmpi.w	#max_note_len,d1
	bhi	m_illegal_note_length
	bra	fop__lp
@@:				*PC98式タイ
	bsr	skip_spc
	cmp.l	a4,d4
	bls	exit_fto
	cmpi.b	#'^',(a4)
	bne	exit_fto
	addq.w	#1,a4		*skip '^'
	bsr	chk_num
	bmi	abstie
	cmpi.b	#'-',(a4)
	bne	@f
	addq.w	#1,a4
	bsr	get_length	*> d0.l
	sub.w	d0,d1
	bmi	m_illegal_note_length
	bra	for_ftlp
@@:
	bsr	get_length	*> d0.l
	add.w	d0,d1
	bmi	m_illegal_note_length
	bra	for_ftlp
abstie:				*絶対音長指定
	bsr	skip_spc
	cmp.l	a4,d4
	bls	exit_fto
	move.b	(a4),d0
	cmp.b	#'*',d0
	bne	onlytie
	addq.w	#1,a4		*skip '*'
	bsr	chk_num
	bmi	m_syntax_error	*no length value
	cmpi.b	#'-',(a4)
	bne	@f
	addq.w	#1,a4
	move.w	d1,-(sp)
	bsr	get_num		*>d1.l=value
	move.w	(sp)+,d0
	sub.w	d1,d0
	bmi	m_illegal_note_length
	move.l	d0,d1
	bra	for_ftlp
@@:
	move.w	d1,-(sp)
	bsr	get_num		*>d1.l=value
	move.l	d1,d0
	add.w	(sp)+,d1
	bmi	m_illegal_note_length
	bra	for_ftlp
onlytie:			*'^'のみの場合
	move.w	tpt_note_len(a5),d0
	add.w	d0,d1
	bra	for_ftlp
exit_fto:
	rts

chk_chogo:			*調号チェック
	* > d1=+1～-1
	* - d0
	move.w	d0,-(sp)
	moveq.l	#0,d1
chk_chogo_lp:
	bsr	skip_spc
	cmp.l	a4,d4
	bls	exit_chk_chogo
	move.b	(a4),d0
	cmpi.b	#'#',d0
	beq	case_sharp
	cmpi.b	#'+',d0
	beq	case_sharp
	cmpi.b	#'-',d0
	bne	exit_chk_chogo
	tst.b	step_input-work(a6)
	beq	case_flat
	addq.w	#1,a4		*ステップ入力モードにおいて「--1」などのケースに対応
	cmp.l	a4,d4
	bls	@f
	move.b	(a4),d0
	cmpi.b	#'0',d0
	bcs	@f
	cmpi.b	#'9',d0
	bhi	@f
	subq.w	#1,a4
exit_chk_chogo:
	move.w	(sp)+,d0
	rts

case_flat:
	addq.w	#1,a4
@@:
	subq.b	#1,d1		*-1
	bra	chk_chogo_lp

case_sharp:
	addq.w	#1,a4
	addq.b	#1,d1		*+1
	bra	chk_chogo_lp

get_key:			*キーコードを得る
	* < d1.w=(a～g:0-6)
	* > d0.l=note number
	* - all except d0-d1
reglist	reg	d2-d3/a1
	movem.l	reglist,-(sp)
	moveq.l	#0,d3
	moveq.l	#0,d0
	move.b	kc_value(pc,d1.w),d0	*d0=0～11(kc)
	bsr	skip_spc2
	cmpi.b	#'!',(a4)
	bne	@f
	addq.w	#1,a4
	bra	gk0
@@:
	add.b	tpt_key_sig(a5,d1.w),d0	*調号考慮
gk0:
	tst.b	step_input-work(a6)
	beq	@f			*step入力モードでは
	bsr	chk_chogo
	move.l	d1,d3			*step入力モード調号
	bsr	chk_num			*音階記号の後に付く数値は
	bmi	@f			*オクターブ
	bsr	get_num			*ex.)C4 = O4C
	addq.l	#1,d1
	cmpi.l	#10,d1
	bhi	m_illegal_octave
	bra	muloctv
@@:
	move.b	tpt_octave(a5),d1
muloctv:
	add.b	d1,d1			*2
	add.b	d1,d1			*4
	move.b	d1,d2			*d2=d1*4
	add.b	d1,d1			*8
	add.b	d2,d1			*12
	add.b	d1,d0			*d0=オクターブを考慮したキー値(0～127)
	bsr	chk_chogo		*♭・♯のチェック
	add.b	d1,d0
	add.b	d3,d0			*step入力モード調号加算
*	add.b	tpt_transpose(a5),d0	*キートランスポーズをチェック
	cmpi.b	#$7f,d0
	bhi	m_illegal_note_number
	lea	tpt_note_tbl(a5),a1
	move.b	(a1,d0.w),d0
	movem.l	(sp)+,reglist
	tst.b	step_input-work(a6)
	beq	@f			*step入力モードでは
	bra	skip_sep2
@@:
	rts
kc_value:	*A  B  C  D  E  F  G
	dc.b	09,11,00,02,04,05,07
	.even

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
	cmpi.b	#',',d0
	beq	skip_eq_lp
	tst.b	seq_cmd-work(a6)
	bne	1f
	btst.b	#0,now_cmd-work(a6)	*(tN)でのMMLコンパイル中か
	bne	@f
1:
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
	tst.b	seq_cmd-work(a6)
	bne	1f
	btst.b	#0,now_cmd-work(a6)	*(tN)でのMMLコンパイル中か
	bne	@f
1:
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
	tst.b	seq_cmd-work(a6)
	bne	1f
	btst.b	#0,now_cmd-work(a6)	*(tN)でのMMLコンパイル中か
	bne	@f			*ne:yes
1:
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
	tst.b	seq_cmd-work(a6)
	bne	1f
	btst.b	#0,now_cmd-work(a6)	*(tN)でのMMLコンパイル中か
	bne	@f			*ne:yes
1:
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

skip_spc1:			*スペースを１個だけスキップする
	move.w	d0,-(sp)	*(スペースやタブも1個だけならスキップ)
sksp1_lp:
	cmp.l	a4,d4
	bls	exit_sksp1
	move.b	(a4)+,d0
	cmpi.b	#'/',d0
	bne	@f
	bsr	do_skip_comment
	bra	sksp1_lp
@@:
	cmpi.b	#09,d0		*skip tab
	beq	exit_sksp1
	cmpi.b	#' ',d0
	beq	exit_sksp1
	subq.w	#1,a4
exit_sksp1:
	move.l	a4,line_ptr-work(a6)
	move.w	(sp)+,d0
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

skip_spc3:			*スペース/TABをスキップする。コメントはスキップしない(.KEY用)
	move.w	d0,-(sp)	*(複数のスペース/TABをスキップ、改行はスキップしない)
@@:
	cmp.l	a4,d4
	bls	@f
	move.b	(a4)+,d0
	cmpi.b	#' ',d0
	beq	@b
	cmpi.b	#09,d0		*skip tab
	beq	@b
	subq.w	#1,a4
@@:
	move.l	a4,line_ptr-work(a6)
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

reglist	reg	d1-d2/a1/a3
get_com_no2:			*コマンド文字列->数値変換
	* < a1=com_tbl
	* < a2=source
	* > d0=#cmd number
	* minus error
	* X a1,a3
	movem.l	reglist,-(sp)
	lea	do_get_cmd_num2(pc),a3
	bra	@f
get_com_no:			*コマンド文字列->数値変換
	* < a1=com_tbl
	* < a4=pointer
	* > d0=#cmd number
	* minus error
	* X a1
	movem.l	reglist,-(sp)
	lea	do_get_cmd_num(pc),a3
@@:
	bsr	skip_spc2
	moveq.l	#0,d2
wc_lp01:
	tst.b	(a1)
	bmi	exit_err_wc
	jsr	(a3)
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
	movem.l	d1/a1,-(sp)
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
	movem.l	(sp)+,d1/a1
	moveq.l	#0,d0		*right!
	rts
not_same_dgscn:
	move.l	d1,a4		*get back a4
	movem.l	(sp)+,d1/a1
	moveq.l	#-1,d0		*error!
	rts

do_get_cmd_num2:		*実際に文字列を捜す
	* < a1=source str addr
	* > eq=get it!
	* > mi=can't found
	movem.l	d1/a1,-(sp)
	move.l	a2,d1		*save a2 to d1
@@:
	move.b	(a2)+,d0
	beq	not_same_dgscn2	*途中で終わった
	jsr	mk_capital-work(a6)	*小文字→大文字
	cmp.b	(a1)+,d0
	bne	not_same_dgscn2
	tst.b	(a1)		*終了
	bne	@b
	movem.l	(sp)+,d1/a1
	moveq.l	#0,d0		*right!
	rts
not_same_dgscn2:
	move.l	d1,a2		*get back a2
	movem.l	(sp)+,d1/a1
	moveq.l	#-1,d0		*error!
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

mml_z:				*velocity sequence
	bsr	skip_spc
	bclr.b	#c_vseq,tpt_mode_flg(a5)	*off vseq
	cmp.l	a4,d4
	bls	mml_lp
	cmpi.b	#',',(a4)
	beq	@f
	bsr	chk_num
	bmi	mml_lp		*数値が一個もない時はスイッチオフ
@@:
	bset.b	#c_vseq,tpt_mode_flg(a5)
	moveq.l	#0,d3
	move.b	tpt_last_velo(a5),d3
	moveq.l	#velo_max-1,d2
	lea	tpt_velo(a5),a2
mml_zlp0:			*相対初期値の取り出し
	tst.b	(a2)+
	bmi	@f
	move.b	-1(a2),d3
@@:
	dbra	d2,mml_zlp0
	lea	tpt_velo(a5),a2
	moveq.l	#velo_max-1,d2
mml_z_lp:
	bsr	skip_spc
	cmp.l	a4,d4
	bls	exit_z_lp
	cmpi.b	#',',(a4)
	beq	z_use_default	*default velocity
	bsr	chk_num
	bmi	exit_z_lp
	cmpi.b	#'+',(a4)
	seq	d5
	beq	@f
	cmpi.b	#'-',(a4)
	seq	d5
@@:
	bsr	get_num
	move.l	d1,d0

	bsr	skip_sep	*skip ','
	tst.b	d5
	beq	@f
				*相対を考慮
	move.l	d3,d0
	add.l	d1,d0
	cmpi.l	#127,d0
	bls	1f
	moveq.l	#0,d0
	tst.l	d1
	bmi	1f
	moveq.l	#127,d0
	bra	1f
@@:
	cmpi.l	#127,d0		*127より大きいとエラー
	bhi	m_illegal_velocity_value
1:
	move.b	d0,(a2)+
	move.l	d0,d3
	dbra	d2,mml_z_lp
	bra	@f
exit_z_lp:
	cmpi.b	#velo_max-2,d2
	bne	@f
	move.b	tpt_velo(a5),d1	*数値が一個の時は@uと同等
	bclr.b	#c_vseq,tpt_mode_flg(a5)	*スイッチオフ
	bra	mml_@u_		*通常のベロシティZMD生成へ
z_use_default:
	bsr	skip_sep	*skip ','
	move.b	#$80,(a2)+	*default velocity code
	dbra	d2,mml_z_lp
@@:
	bsr	chk_num
	bpl	m_too_many_parameters		*パラメータ多すぎ
	clr.w	tpt_velo_n(a5)	*init pointer
	moveq.l	#velo_max-1,d0
	sub.w	d2,d0
	move.w	d0,tpt_n_of_velo(a5)
	bra	mml_lp

velocity_sequence:			*ベロシティシーケンスの実行
	btst.b	#c_vseq,tpt_mode_flg(a5)
	beq	1f
	btst.b	#c_renp1,tpt_mode_flg(a5)	*連符(PASS1)か
	bne	1f
	movem.l	d0-d1/a1,-(sp)
	move.w	tpt_velo_n(a5),d0
	cmp.w	tpt_n_of_velo(a5),d0	*maxで戻る
	bcs	@f
	move.w	#1,tpt_velo_n(a5)
	move.b	tpt_velo(a5),d1
	bra	3f
@@:
	addq.w	#1,tpt_velo_n(a5)
	lea	tpt_velo(a5),a1
	move.b	(a1,d0.w),d1
3:
	bmi	2f
	moveq.l	#velocity_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d1,d0
	bsr	do_wrt_trk_b
2:
	movem.l	(sp)+,d0-d1/a1
1:
	rts

mml_z_chord:					*和音ベロシティシーケンス
	* - all
reglist	reg	d0-d3/a2
	movem.l	reglist,-(sp)
	bsr	skip_spc
	bclr.b	#c_vseq_chd,tpt_mode_flg+1(a5)	*off vseq
	cmp.l	a4,d4
	bls	exit_mzc
	cmpi.b	#',',(a4)
	beq	@f
	bsr	chk_num
	bmi	exit_mzc			*数値が一個もない時はスイッチオフ
@@:
	bset.b	#c_vseq_chd,tpt_mode_flg+1(a5)
	lea	tpt_velo_chd(a5),a2
	moveq.l	#max_note_on-1,d2
	moveq.l	#$80,d1
_mml_z_lp:
	bsr	skip_spc
	cmp.l	a4,d4
	bls	_exit_z_lp
	cmpi.b	#',',(a4)
	beq	_z_use_default	*default velocity
	bsr	chk_num
	bmi	_exit_z_lp
	cmpi.b	#'+',(a4)
	seq	d3
	beq	@f
	cmpi.b	#'-',(a4)
	seq	d3
@@:
	bsr	get_num
	bsr	skip_sep	*skip ','
	tst.b	d3
	beq	@f
				*相対を考慮
	add.l	#192,d1		*-63～63を129～255へ
	cmpi.l	#129,d1
	bcs	m_illegal_velocity_value
	cmpi.l	#255,d1
	bhi	m_illegal_velocity_value
	bra	1f
@@:
	cmpi.l	#127,d1		*127より大きいとエラー
	bhi	m_illegal_velocity_value
1:
	move.b	d1,(a2)+
	dbra	d2,_mml_z_lp
	bra	@f
_z_use_default:
	bsr	skip_sep	*skip ','
	move.b	d1,(a2)+	*default velocity code
	dbra	d2,_mml_z_lp
@@:
	bsr	chk_num
	bpl	m_too_many_parameters		*パラメータ多すぎ
_exit_z_lp:
	clr.w	tpt_velo_n_chd(a5)	*init pointer
	moveq.l	#max_note_on-1,d0
	sub.w	d2,d0
	move.w	d0,tpt_n_of_velo_chd(a5)
exit_mzc:
	movem.l	(sp)+,reglist

velocity_sequence_chord:			*和音ベロシティシーケンスの実行
	btst.b	#c_vseq_chd,tpt_mode_flg+1(a5)
	beq	1f
	btst.b	#c_renp1,tpt_mode_flg(a5)	*連符(PASS1)か
	bne	1f
	movem.l	d0-d1/a1,-(sp)
	move.w	tpt_velo_n_chd(a5),d0
	cmp.w	tpt_n_of_velo_chd(a5),d0	*maxで戻る
	bcs	@f
	move.w	#1,tpt_velo_n_chd(a5)
	move.b	tpt_velo_chd(a5),d1
	bra	3f
@@:
	addq.w	#1,tpt_velo_n_chd(a5)
	lea	tpt_velo_chd(a5),a1
	move.b	(a1,d0.w),d1
3:
	cmpi.b	#$80,d1
	beq	2f
	move.b	d1,vl_buf-work(a6)
2:
	movem.l	(sp)+,d0-d1/a1
1:
	rts

mml_port_:				*ポルタメント #2
	clr.b	seq_cmd-work(a6)
	move.w	#']'*256+portament2_zmd,port_bracket-work(a6)
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_syntax_error	*'['だけで終わっている
	move.b	(a4),d0
	bsr	mk_capital
	cmpi.b	#'A',d0
	bne	@f
	move.l	a4,d2
	addq.w	#1,a4		*skip 'A'
	bsr	chk_num
	bpl	4f
	move.l	d2,-(sp)
	bsr	get_str_ch	*> d2=type,ch
	movem.l	(sp)+,d2	*わざとmovem
	beq	5f
	bra	2f
4:
	bsr	get_num
5:
	bsr	skip_sep	*skip ','
	bsr	chk_num
	bpl	1f
	bra	2f
@@:
	cmpi.b	#'O',d0
	bne	@f
	move.l	a4,d2
	addq.w	#1,a4		*skip 'A'
	bsr	chk_num
	bpl	2f
	bra	1f
@@:
	cmpi.b	#'<',d0
	beq	port_entry
	cmpi.b	#'>',d0
	beq	port_entry
	cmpi.b	#'A',d0
	bcs	1f
	cmpi.b	#'G',d0
	bls	port_entry
1:				*common command
	move.l	d7,a4
	bra	m_syntax_error	*文法エラー
2:				*portament
	move.l	d2,a4
	bra	port_entry

mml_port:			*ポルタメント
	move.w	#')'*256+portament_zmd,port_bracket-work(a6)
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_syntax_error	*'('だけで終わっている
	move.b	(a4),d0
	bsr	mk_capital
	cmpi.b	#'O',d0
	bne	@f
	move.l	a4,d2
	addq.w	#1,a4		*skip 'O'
	bsr	chk_num
	bmi	1f		*(O)case
	bsr	get_num		*get dummy number
	bsr	skip_spc
	cmp.l	a4,d4
	bls	1f		*(O)case
	cmpi.b	#')',(a4)
	beq	1f		*(O)case
	bra	2f
@@:
	cmpi.b	#'A',d0
	bne	@f
	move.l	a4,d2
	addq.w	#1,a4		*skip 'A'
	bsr	chk_num
	bpl	4f
	move.l	d2,-(sp)
	bsr	get_str_ch	*> d2=type,ch
	movem.l	(sp)+,d2	*わざとmovem
	beq	5f
	bra	2f
4:
	bsr	get_num
5:
	bsr	skip_sep	*skip ','
	bsr	chk_num
	bpl	1f
	bra	2f
@@:
	cmpi.b	#'<',d0
	beq	port_entry
	cmpi.b	#'>',d0
	beq	port_entry
	cmpi.b	#'A',d0
	bcs	1f
	cmpi.b	#'G',d0
	bls	port_entry
1:				*common command
	move.l	d7,a4
	bra	mmlc_exit	*共通コマンドとみなしてコンパイルルーチン抜ける
2:				*portament
	move.l	d2,a4
port_entry:
	btst.b	#c_break,tpt_mode_flg(a5)	*コンパイル中断フラグチェック
	bne	go_skip_mml
	bclr.b	#c_step,tpt_mode_flg(a5)
	bclr.b	#c_gate,tpt_mode_flg(a5)
	move.b	#$80,vl_buf-work(a6)
	bsr	velocity_sequence
	btst.b	#c_renp1,tpt_mode_flg(a5)
	beq	@f
	addq.l	#1,tpt_renp_cnt(a5)	*個数=個数+1
@@:
	bsr	skip_spc		*オクターブスイッチの考慮その1
	cmp.l	a4,d4
	bls	m_portament_command_error
	move.b	(a4),d0
	bsr	oct_chk
	bmi	@b
	bsr	get_port_key
	move.l	d0,d3			*save 1st kc
	swap	d3
	bsr	get_port_length		*音長があるならそれを取り出す(>d0)
					*オクターブスイッチの考慮その2
	bsr	skip_sep
@@:
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_portament_command_error
	move.b	(a4),d0
	bsr	oct_chk
	bmi	@b
	bsr	get_port_key
	move.l	d0,d5			*save 2nd kc
	swap	d5
	bsr	get_port_length		*音長があるならそれを取り出す(>d0)
@@:					*最後のオクターブスイッチの考慮
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_portament_command_error
	move.b	(a4),d0
	bsr	oct_chk
	bmi	@b
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_portament_command_error	*終端の')'がない
	move.b	port_bracket-work(a6),d0
	cmp.b	(a4)+,d0
	bne	m_syntax_error			*終端の')'がない
	bsr	skip_spc
	cmp.l	a4,d4
	bls	do_wrt_port
	cmpi.b	#'*',(a4)
	bne	@f
	addq.w	#1,a4				*skip	'*'
@@:
	bsr	chk_num
	bmi	@f				*音長省略のケース
	btst.b	#c_renp1,tpt_mode_flg(a5)
	bne	m_group_notes_command_error	*連符内に音長指定は不可能
	bsr	get_num
	cmp.l	#max_note_len,d1
	bhi	m_illegal_note_length
	move.w	d1,step_buf-work(a6)
@@:					*ディレイがあれば取得
	bsr	skip_sep
	cmp.l	a4,d4
	bls	do_wrt_port
	cmpi.b	#'*',(a4)
	bne	@f
	addq.w	#1,a4			*skip	'*'
@@:
	moveq.l	#0,d1
	move.w	tpt_port_dly(a5),d1
	bsr	chk_num
	bmi	@f			*ディレイはない
	bsr	get_num
@@:
	move.w	d1,tpt_port_dly(a5)
	beq	@f
	cmpi.l	#-32768,d1
	blt	m_delay_too_long	*絶対値が16bit範囲より大きいとエラー
	cmpi.l	#32767,d1
	bgt	m_delay_too_long	*絶対値が16bit範囲より大きいとエラー
	bset.l	#23,d3			*delay有りのマーク
	move.w	d1,d3			*save delay
@@:					*ホールドタイムがあれば取得
	bsr	skip_sep
	cmp.l	a4,d4
	bls	do_wrt_port
	cmpi.b	#'*',(a4)
	bne	@f
	addq.w	#1,a4			*skip	'*'
@@:
	move.w	tpt_port_hold(a5),d1
	ext.l	d1
	bsr	chk_num
	bmi	@f
	bsr	get_num
@@:
	move.w	d1,tpt_port_hold(a5)
	beq	do_wrt_port
	move.l	d1,d0
	bpl	@f
	neg.l	d0
	cmpi.l	#max_note_len,d0
	bhi	m_hold_time_too_long
	bra	mmlport00
@@:
	cmpi.l	#max_note_len,d0
	bhi	m_portament_time_too_long
mmlport00:
	bset.l	#23,d5			*hold有りのマーク
	move.w	d1,d5			*save hold
do_wrt_port:				*ポルタメントコマンドパラメータ・バッファへの書き込み
	* < d3.l=src kc/delay
	* < d5.l=dest kc/hold(port.time)
	move.l	d3,d0
	swap	d0
	andi.w	#$7f,d0
	bsr	scan_prev_notes
	move.w	step_buf(pc),d2		*get step
	move.l	arry_stock(pc),a3	*今回の結果をストアするワーク
	btst.b	#c_renp2,tpt_mode_flg(a5)	*↑連符処理(PASS2)
	beq	chk_pt_echo
	move.w	tpt_renp_length(a5),d2
	tst.w	tpt_renp_surplus(a5)
	beq	@f
	addq.w	#1,d2
	subq.w	#1,tpt_renp_surplus(a5)		*↓連符処理(PASS2)
@@:
	move.w	d2,step_buf-work(a6)
chk_pt_echo:
	tst.b	tpt_echo_switch(a5)
	beq	@f
	cmp.w	tpt_echo_dly(a5),d2	*dly方が大きい場合は処理なし
	bhi	echo_case_port
@@:
	bsr	skip_spc
	cmp.l	a4,d4
	bls	@f
	cmp.b	#'&',(a4)
	bne	@f
	addq.w	#1,a4		*タイのケース
	move.w	#TIE_GATE,d6
	bra	go_dwp
@@:						*ゲートを計算するケース
	move.w	gate_buf(pc),d0
	btst.b	#c_gate,tpt_mode_flg(a5)
	bne	@f				*ゲートはすでに設定済み
	move.w	step_buf(pc),d0
	bsr	calc_gt
@@:
	bsr	consider_trkfrq_gt		*trkfrqを考慮する
	move.l	d0,d6
go_dwp:					*< d6.w=default gate
	move.b	port_zmd-work(a6),d0
	bsr	do_wrt_trk_b
	move.w	d3,d1
	bpl	@f
	add.w	d1,d2			*step+delay
	bra	1f
@@:
	sub.w	d1,d2			*step-delay
1:
	ble	m_delay_too_long
	tst.w	d5			*port.time(pl)? or hold time(mi)?
	beq	dwp0
	bpl	@f
	add.w	d5,d2			*d2=portament time
	bgt	dwp0			*tailの方が大きい場合は
	bra	m_hold_time_too_long	*d5=hold time
@@:
	cmp.w	d2,d5
	bcc	m_portament_time_too_long
	move.w	d5,d2			*d2=portament time
dwp0:
	swap	d3
	swap	d5
	move.l	d3,d0			*src note
	bsr	do_wrt_trk_b
	andi.w	#$7f,d0
	move.w	d0,(a3)+
	move.l	d5,d0			*dest note
	bsr	do_wrt_trk_b
	tst.b	d3
	bpl	1f
	move.w	d1,d0			*delay
	bpl	@f
	move.w	step_buf(pc),d0
	add.w	d1,d0
@@:
	bsr	consider_trkfrq_st	*trkfrqを考慮する
	bsr	do_wrt_trk_v
1:
	tst.b	d5
	bpl	@f
	move.l	d2,d0			*hold
	bsr	consider_trkfrq_st	*trkfrqを考慮する
	bsr	do_wrt_trk_v
@@:
	move.w	step_buf(pc),d0
	bsr	consider_trkfrq_st	*trkfrqを考慮する(step)
	bsr	do_wrt_trk_v		*set step time
	move.l	d6,d0
	move.w	d0,(a3)+
	bmi	@f
	st.b	-3(a3)			*タイでない通常ノートならばゲート書き換えフェーズは不要
	bsr	do_wrt_trk_v		*set gate(normal)
	bra	dwp1
@@:					*タイ
	move.l	tpt_now(a5),(a3)
	bsr	do_wrt_trk_w
dwp1:
	move.l	#-1,4(a3)		*endcode
	move.b	vl_buf(pc),d0
	bsr	do_wrt_trk_b		*velocity
	bsr	rewrite_note_gate
	bsr	preserve_this_note
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	rts

echo_case_port:				*疑似エコー・プリプロセッシング(portament)
	* < d3.l=src kc/delay
	* < d5.l=dest kc/hold(port.time)
	* < d6.w=gate time
	* < d2.w=step_buf
	bsr	skip_spc
	cmp.l	a4,d4
	bls	@f
	cmp.b	#'&',(a4)
	bne	@f
	addq.w	#1,a4		*タイのケース
	move.w	#TIE_GATE,d6
	bra	go_ecp
@@:						*ゲートを計算するケース
	move.w	gate_buf(pc),d0
	btst.b	#c_gate,tpt_mode_flg(a5)
	bne	@f				*ゲートはすでに設定済み
	move.w	d2,d0
	bsr	calc_gt
@@:
	bsr	consider_trkfrq_gt		*trkfrqを考慮する
	move.l	d0,d6
go_ecp:					*< d6.w=default gate
	move.l	d4,-(sp)
	move.w	tpt_echo_loop(a5),d7
	subq.w	#1,d7			*for dbra
	moveq.l	#0,d1
	move.b	vl_buf(pc),d1
	cmpi.b	#$80,d1
	bne	@f
	move.w	#192,d1			*buetral:192//tpt_last_velo(a5),d5	*直前のVelocity適用
@@:
	move.b	tpt_echo_vdec(a5),d4	*減衰量
	ext.w	d4
echopelp_prt:				*ベロシティが絶対値あるいは相対値指定の場合
reglist	reg	d2-d5/d7/a2-a3
	movem.l	reglist,-(sp)
	tst.w	d6			*check gate
	beq	2f			*no more gate
	tst.w	d7			*last
	beq	1f
	move.w	tpt_echo_dly(a5),a2
	cmp.w	a2,d2
	bcc	@f
1:
	move.l	d2,a2
@@:
	move.l	a2,d2
	move.l	d3,a1
	tst.w	d3
	bpl	@f
	add.w	a1,a2			*step+delay
	bra	1f
@@:
	sub.w	a1,a2			*step-delay
1:
	ble	m_delay_too_long
	tst.w	d5			*hold time/port time
	beq	echo_dwp0
	bpl	@f
	add.w	d5,a2			*a2=port time
	bgt	echo_dwp0
	bra	m_hold_time_too_long	*d5=hold time
@@:
	cmp.w	a2,d5
	bcc	m_portament_time_too_long
	move.w	d5,a2
echo_dwp0:
	move.b	port_zmd-work(a6),d0
	bra	@f
2:
	moveq.l	#wait_zmd,d0
@@:
	bsr	do_wrt_trk_b
	tst.w	d6			*case:gate=0
	beq	1f
	swap	d3
	swap	d5
	move.l	d3,d0
	bsr	do_wrt_trk_b		*src note
	andi.w	#$7f,d0
	move.w	d0,(a3)+
	move.l	d5,d0
	bsr	do_wrt_trk_b		*dest. note
	tst.b	d3
	bpl	@f
	move.l	a1,d0			*delay
	bsr	consider_trkfrq_st
	bsr	do_wrt_trk_w
@@:
	tst.b	d5
	bpl	1f
	move.l	a2,d0
	bsr	consider_trkfrq_st
	bsr	do_wrt_trk_v		*hold
1:
	move.l	d2,d0
	bsr	consider_trkfrq_st
	bsr	do_wrt_trk_v		*step
	move.w	tpt_echo_dly(a5),d0
	tst.w	d6
	beq	echope_next_prt		*gate=0ならば以下の処理はいらない
	bpl	@f
	tst.w	d7
	bne	2f
	move.w	#TIE_GATE,d0
	bra	2f
@@:
	tst.w	d7
	bne	1f
	move.w	d6,d0
	bra	2f
1:
	sub.w	d0,d6
2:
	move.w	d0,(a3)+		*gate
	bmi	@f
	st.b	-3(a3)
	bsr	do_wrt_trk_v		*gate
	bra	echo_dwp1
@@:
	move.l	tpt_now(a5),(a3)
	bsr	do_wrt_trk_w
echo_dwp1:
	move.l	#-1,4(a3)		*endcode
	move.b	d1,d0
	bsr	do_wrt_trk_b		*velocity
	tst.b	d1
	bpl	ech_absvlo_prt
	add.w	d4,d1			*減衰処理
	cmpi.w	#129,d1
	bcc	@f
	move.w	#129,d1
	bra	echope_next_prt
@@:
	cmpi.w	#255,d1
	bls	echope_next_prt
	move.w	#255,d1
	bra	echope_next_prt
ech_absvlo_prt:				*ベロシティが絶対値指定の場合
	add.w	d4,d1			*減衰処理
	bpl	@f
	moveq.l	#0,d1
	bra	echope_next_prt
@@:
	cmp.w	#127,d1
	bls	echope_next_prt
	moveq.l	#127,d1
echope_next_prt:
	movem.l	(sp)+,reglist
	sub.w	tpt_echo_dly(a5),d2
	bls	@f
	dbra	d7,echopelp_prt
	tst.w	tpt_echo_loop(a5)	*無限ループケース
	beq	echopelp_prt
*	moveq.l	#wait_zmd,d0
*	bsr	do_wrt_trk_b
*	move.w	d2,d0
*	bsr	do_wrt_trk_v
@@:
	bsr	rewrite_note_gate
	bsr	preserve_this_note	*今回の発音内容を保存
	move.l	(sp)+,d4
	bra	mml_lp

*case_step_shortage_prt:
*	* < d2.w=step
*	moveq.l	#wait_zmd,d0
*	bsr	do_wrt_trk_b
*	move.l	d2,d0
*	bsr	do_wrt_trk_v
*	movem.l	(sp)+,reglist
*	bra	@b

mml_pull_portament:		*ポルタメント[PULL_PORTAMENT...]
	move.b	#portament2_zmd,port_zmd-work(a6)
	bra	@f

mml_push_portament:		*ポルタメント[PUSH_PORTAMENT...]
mml_portament:			*ポルタメント[PORTAMENT...]
	move.b	#portament_zmd,port_zmd-work(a6)
@@:
	bclr.b	#c_step,tpt_mode_flg(a5)
	bclr.b	#c_gate,tpt_mode_flg(a5)
	move.b	#$80,vl_buf-work(a6)
	bsr	velocity_sequence
	btst.b	#c_renp1,tpt_mode_flg(a5)
	beq	@f
	addq.l	#1,tpt_renp_cnt(a5)	*個数=個数+1
@@:
	bsr	skip_spc		*オクターブスイッチの考慮その1
	cmp.l	a4,d4
	bls	m_portament_command_error
	move.b	(a4),d0
	bsr	oct_chk
	bmi	@b
	bsr	get_port_key
	move.l	d0,d3			*save 1st kc
	swap	d3
@@:					*オクターブスイッチの考慮その2
	bsr	skip_sep
	cmp.l	a4,d4
	bls	m_portament_command_error
	move.b	(a4),d0
	bsr	oct_chk
	bmi	@b
	bsr	get_port_key
	move.l	d0,d5				*save 2nd kc
	swap	d5
@@:						*最後のオクターブスイッチの考慮
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_portament_command_error
	move.b	(a4),d0
	bsr	oct_chk
	bmi	@b
	bsr	skip_sep
	bsr	get_abs_length			*音長があるならそれを取り出す(>d0)
						*ディレイがあれば取得
	bsr	skip_sep
	bsr	chk_num
	bmi	@f				*ディレイはない
	bsr	get_num
	cmpi.l	#-32768,d1
	blt	m_delay_too_long		*絶対値が16bit範囲より大きいとエラー
	cmpi.l	#32767,d1
	bgt	m_delay_too_long		*絶対値が16bit範囲より大きいとエラー
	bset.l	#23,d3				*delay有りのマーク
	move.w	d1,d3				*save delay
@@:						*ホールドタイムがあれば取得
	bsr	skip_sep
	bsr	chk_num
	bmi	do_wrt_port			*holdはない
	bsr	get_num
	move.l	d1,d0
	bpl	@f
	neg.l	d0
	cmpi.l	#max_note_len,d0
	bhi	m_hold_time_too_long
	bra	1f
@@:
	cmpi.l	#max_note_len,d0
	bhi	m_portament_time_too_long
1:
	bset.l	#23,d5				*hold有りのマーク
	move.w	d1,d5				*save hold
	bra	do_wrt_port

get_port_key:
	* > d0.b=kc
	bsr	skip_sep
	cmp.l	a4,d4
	bls	m_syntax_error
	move.b	(a4)+,d0
	bsr	mk_capital
	sub.b	#'A',d0
	cmpi.b	#6,d0
	bhi	m_illegal_note_number
	moveq.l	#0,d1
	move.b	d0,d1
	bsr	get_key		*キーコードを得る
	cmpi.b	#127,d0
	bhi	m_illegal_note_number
exit_gpk:
	rts

oct_chk:
	* < d0.b='O' '<' '>' or others
	* > mi=again
	* > eq=no more check
	bsr	mk_capital
	cmpi.b	#'O',d0
	bne	@f
	addq.w	#1,a4		*skip 'O'
	bsr	chk_num
	bmi	m_illegal_octave
	bsr	get_num
	addq.l	#1,d1		*d1=0～10
	cmpi.l	#10,d1
	bhi	m_illegal_octave
	move.b	d1,tpt_octave(a5)
	bra	oct_chk_again
@@:
	cmp.b	#OCTAVE_UP,d0
	bne	@f
	addq.w	#1,a4		*skip '<'
	bsr	do_oup
	bra	oct_chk_again
@@:
	cmp.b	#OCTAVE_DOWN,d0
	bne	@f
	addq.w	#1,a4		*skip '>'
	bsr	do_odwn
	bra	oct_chk_again
@@:
	moveq.l	#0,d0
	rts
oct_chk_again:
	moveq.l	#-1,d0
	rts

do_oup:				*オクターブアップ
	cmpi.b	#10,tpt_octave(a5)
	beq	m_illegal_octave	*illegal octave
	addq.b	#1,tpt_octave(a5)
	rts

do_odwn:			*オクターブダウン
	tst.b	tpt_octave(a5)
	beq	m_illegal_octave	*illegal octave
	subq.b	#1,tpt_octave(a5)
	rts

get_abs_length:					*ステップ、ゲート、ベロシティ取得
	* > d0.w=step time
reglist	reg	d1-d3/a2
	movem.l	reglist,-(sp)
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_illegal_parameter_format
	bsr	chk_oncho
	bpl	2f
	cmpi.b	#'.',(a4)
	bne	1f
	bset.b	#c_step,tpt_mode_flg(a5)	*符点がある場合は音長指定があったのと同等扱い
1:
	move.w	tpt_note_len(a5),d0	*get default length
	bra	3f			*デフォルトステップタイムを得て符点処理へ
2:
	btst.b	#c_renp1,tpt_mode_flg(a5)	*連符内に音長指定は出来ない
	bne	m_group_notes_command_error
	bsr	get_num				*絶対音長指定
	move.l	d1,d0
	bset.b	#c_step,tpt_mode_flg(a5)	*mark
3:
	bsr	futen_ope			*< d0.w=step source
	cmp.l	#max_note_len,d1		*最大値チェック
	bhi	m_illegal_note_length
	move.w	d1,step_buf-work(a6)
	bclr.b	#c_gate,tpt_mode_flg(a5)	*以前のゲートタイム無効化
						*ゲートタイムが有れば取得
	bsr	skip_sep
	cmp.l	a4,d4
	bls	m_illegal_parameter_format
	bsr	chk_oncho
	bmi	@f
	bsr	get_num
	move.l	d1,d0
	bsr	futen_ope			*符点を考慮(< d0.l)
	move.w	d1,gate_buf-work(a6)
	bset.b	#c_gate,tpt_mode_flg(a5)	*flag on
@@:
	bsr	skip_sep			*ベロシティがあればゲット
	cmp.l	a4,d4
	bls	m_illegal_parameter_format
	bsr	chk_num
	bmi	2f
						*ベロシティー
	move.b	(a4),d0
	cmpi.b	#'-',d0				*相対チェック
	beq	@f
	cmpi.b	#'+',d0
	bne	1f		*直値指定
@@:				*相対指定
	bsr	get_num
	add.l	#192,d1		*-63～63を129～255へ
	cmpi.l	#129,d1
	bcs	m_illegal_velocity_value
	cmpi.l	#255,d1
	bhi	m_illegal_velocity_value
	bra	@f
1:
	bsr	get_num
	cmpi.l	#127,d1
	bhi	m_illegal_velocity_value
@@:
	move.b	d1,vl_buf-work(a6)
2:
	movem.l	(sp)+,reglist
	rts

mml_mute:				*[MUTE]
	moveq.l	#kill_note_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#1,d0			*完全消音
	bra	do_wrt_trk_b

mml_stop:				*[STOP]
	moveq.l	#kill_note_zmd,d0
	bsr	do_wrt_trk_b
	bsr	skip_sep2
	cmp.l	a4,d4
	bls	m_illegal_command_line	*']'がない
	cmpi.b	#']',(a4)
	bne	@f
	moveq.l	#2,d0			*完全消音して演奏終了(default)
	bra	do_wrt_trk_b
@@:
	lea	mmlstop_mode-work(a6),a1
	bsr	get_com_no
	bmi	m_illegal_mode_value	*規定外
	moveq.l	#-1,d0			*完全消音して演奏終了
	bra	do_wrt_trk_b

mml_all_sound_off:		*[ALL_SOUND_OFF]
mml_kill_note:			*強制キーオフコマンド
	moveq.l	#kill_note_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#0,d0		*通常消音
	bsr	do_wrt_trk_b
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	rts

mml_chord:					*和音コマンド
	btst.b	#c_renp1,tpt_mode_flg(a5)
	beq	@f
	addq.l	#1,tpt_renp_cnt(a5)		*個数=個数+1
@@:
	moveq.l	#0,d6				*note cnt
	bclr.b	#c_step,tpt_mode_flg(a5)
	move.b	#$80,vl_buf-work(a6)
	bsr	velocity_sequence
	move.b	vl_buf(pc),d5			*d5.b=velocity
	move.b	tpt_octave(a5),oct_wk-work(a6)	*一時保存
	move.l	temp_buffer(pc),a1		*一時的に和音の構成音をここへ格納
	clr.w	tpt_velo_n_chd(a5)		*和音ベロシティシーケンスポインタの初期化
get_chord_lp:					*note(.b),velocity(.b),gate(.w)
	bclr.b	#c_gate,tpt_mode_flg(a5)
	move.b	d5,vl_buf-work(a6)
	bsr	velocity_sequence_chord
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_chord_command_error		*"'"が見つからないで和音が終わった
	move.b	(a4),d0
	cmpi.b	#"'",d0
	beq	exit_gwk			*終端コード発見
	bsr	mk_capital
	cmpi.b	#'Z',d0
	bne	@f
	addq.w	#1,a4				*skip 'Z'
	bsr	mml_z_chord			*和音ベロシティシーケンス
@@:
	bsr	oct_chk				*オクターブがあれば取得
	bmi	get_chord_lp
	bsr	get_port_key
	move.b	d0,(a1)+			*note number
	bsr	get_chord_length		*数値があるならそれを音長に
	moveq.l	#-1,d0				*ゲートタイムは無指定の場合:-1
	btst.b	#c_gate,tpt_mode_flg(a5)
	beq	@f
	move.w	gate_buf(pc),d0
@@:
	move.b	vl_buf(pc),(a1)+		*velocity
	move.w	d0,(a1)+			*gate time(無指定の場合は-1)
@@:
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_chord_command_error		*"'"が見つからないで和音が終わった
	move.b	(a4),d0
	bsr	oct_chk				*オクターブがあれば取得
	bmi	@b
	addq.w	#1,d6
	cmpi.w	#max_note_on,d6
	bhi	m_too_many_notes		*音符が多すぎる
	cmpi.b	#"'",(a4)			*終端コード発見?
	bne	get_chord_lp			*ループする
exit_gwk:
	addq.w	#1,a4				*skip "'"
	tst.w	d6
	beq	m_chord_command_error		*音符が一個もない
	bsr	skip_spc
	cmp.l	a4,d4
	bls	calc_chord_gt
	cmpi.b	#'*',(a4)
	bne	@f
	addq.w	#1,a4				*skip	'*'
@@:
	bsr	chk_num
	bmi	@f
	btst.b	#c_renp1,tpt_mode_flg(a5)
	bne	m_group_notes_command_error	*連符内に音長指定は不可能
	bsr	get_num				*音長取りだし
	cmp.l	#max_note_len,d1
	bhi	m_illegal_note_length
	move.w	d1,step_buf-work(a6)
@@:
	bsr	skip_sep
	cmp.l	a4,d4
	bls	calc_chord_gt
	cmpi.b	#'*',(a4)
	bne	@f
	addq.w	#1,a4			*skip	'*'
@@:
	bsr	chk_num
	bpl	@f
	move.w	tpt_chord_dly(a5),d1	*prev.delay
	ext.l	d1
	bra	1f
@@:
	bsr	get_num			*delay取りだし
1:
	tst.l	d1
	bpl	1f
	move.l	arry_stock(pc),a3
	move.l	d6,d2
	subq.w	#1,d2			*for dbra
@@:
	move.l	-(a1),(a3)+
	dbra	d2,@b
	move.l	temp_buffer(pc),a1
	move.l	arry_stock(pc),a3
	move.l	d6,d2
	subq.w	#1,d2			*for dbra
@@:
	move.l	(a3)+,(a1)+
	dbra	d2,@b
	move.w	d1,tpt_chord_dly(a5)	*new delay
	neg.l	d1			*delayが負の場合は和音構成を逆に
	bra	2f
1:
	move.w	d1,tpt_chord_dly(a5)	*new delay
2:
	cmpi.l	#max_note_len,d1
	bhi	m_delay_too_long
calc_chord_gt:				*ゲートタイムの計算
	btst.b	#c_renp2,tpt_mode_flg(a5)	*↑連符処理(PASS2)
	beq	chk_cd_echo
	move.w	tpt_renp_length(a5),d0
	tst.w	tpt_renp_surplus(a5)
	beq	@f
	addq.w	#1,d0
	subq.w	#1,tpt_renp_surplus(a5)		*↓連符処理(PASS2)
@@:
	move.w	d0,step_buf-work(a6)
chk_cd_echo:
	move.l	temp_buffer(pc),a1	*今回の発音
	move.l	arry_stock(pc),a3	*今回の結果をストアするワーク
	moveq.l	#0,d3			*蓄積step time work
	move.l	d6,d2
	subq.w	#1,d2			*for dbra
	bsr	skip_spc
	cmp.l	a4,d4
	bls	reset_chord_gt
	cmp.b	#'&',(a4)
	bne	reset_chord_gt
	addq.w	#1,a4
	tst.b	tpt_echo_switch(a5)
	beq	@f
	move.w	step_buf(pc),d6
	cmp.w	tpt_echo_dly(a5),d6	*dly方が大きい場合は処理なし
	bhi	echo_case_chord0
@@:
	move.w	step_buf(pc),d0
	bsr	calc_gt_chd
	move.l	d0,d5			*d5=calclated default gate time
do_wrt_chd_lp0:				*以下タイのケース
	moveq.l	#0,d0
	move.b	(a1)+,d0
	move.w	d0,(a3)+		*tnb_note
	bsr	scan_prev_notes
	bsr	do_wrt_trk_b		*note
	move.b	(a1)+,d1		*velo
	tst.w	d2			*ラストか
	bne	@f			*no
					*yes:最後のステップタイムは特別
	move.w	step_buf(pc),d0		*step time work
	sub.w	d3,d0
	bls	m_delay_too_long	*delayが大きすぎるために最後のstep timeが0になった
	bra	wrchgt00
@@:					*ラストじゃないケース
	move.w	tpt_chord_dly(a5),d0
	bpl	@f
	neg.w	d0
@@:
wrchgt00:				*ゲートタイムはこの時点では0
	bsr	consider_trkfrq_st	*trkfrqを考慮する(step)
	bsr	do_wrt_trk_v		*step time
	move.w	(a1)+,d0		*get gate
	cmp.w	#-1,d0			*gate=-1は算出したゲートタイムを使用するケース
	bne	@f
	move.l	d5,d0
	bra	next_wrchgt00
@@:
	sub.w	d3,d0
	bls	m_delay_too_long	*delayが大きすぎる
next_wrchgt00:
	bsr	consider_trkfrq_gt	*trkfrqを考慮する
	move.w	d0,(a3)+		*gate time
	move.l	tpt_now(a5),(a3)+
	move.l	#-1,(a3)
	move.w	#CHORD_TIE_GATE,d0
	bsr	do_wrt_trk_w
	move.b	d1,d0
	bsr	do_wrt_trk_b		*velocity
	move.w	tpt_chord_dly(a5),d0
	bpl	@f
	neg.w	d0
@@:
	add.w	d0,d3
	bmi	m_delay_too_long
	dbra	d2,do_wrt_chd_lp0
	bsr	rewrite_note_gate	*ゲートを書き換える
	bsr	preserve_this_note	*今回の発音内容を保存
	bra	exit_mml_chord

reset_chord_gt:				*ゲートを計算するケース
	tst.b	tpt_echo_switch(a5)
	beq	@f
	move.w	step_buf(pc),d6
	cmp.w	tpt_echo_dly(a5),d6	*dly方が大きい場合は処理なし
	bhi	echo_case_chord1
@@:
	move.w	step_buf(pc),d0
	bsr	calc_gt_chd
	move.l	d0,d5			*d5=calclated default gate time
do_wrt_chd_lp1:
	moveq.l	#0,d0
	move.b	(a1)+,d0
	bsr	scan_prev_notes
	bsr	do_wrt_trk_b	*note
	move.b	(a1)+,d1	*velo
	tst.w	d2
	bne	@f
					*最後のステップタイムは特別
	move.w	step_buf(pc),d0		*step time work
	sub.w	d3,d0
	bls	m_delay_too_long	*delayが大きすぎるために最後のstep timeが0になった
	bra	wrchgt01
@@:
	move.w	tpt_chord_dly(a5),d0
	bpl	@f
	neg.w	d0
@@:
wrchgt01:
	bsr	consider_trkfrq_st	*trkfrqを考慮する(step)
	bsr	do_wrt_trk_v
	move.w	(a1)+,d0
	cmp.w	#-1,d0			*gate=-1は算出したゲートタイムを使用するケース
	bne	@f
	move.l	d5,d0
	bra	wrchgt02
@@:
	sub.w	d3,d0
	bls	m_delay_too_long	*delayが大きすぎる
wrchgt02:
	bsr	consider_trkfrq_gt	*trkfrqを考慮する
	bsr	do_wrt_trk_v		*gate time
	move.b	d1,d0
	bsr	do_wrt_trk_b		*velocity
	move.w	tpt_chord_dly(a5),d0
	bpl	@f
	neg.w	d0
@@:
	tst.w	d2
	beq	@f
	add.w	d0,d3
	bmi	m_delay_too_long
	sub.w	d0,d5
	bls	m_delay_too_long
	dbra	d2,do_wrt_chd_lp1
@@:
	btst.b	#c_renp1,tpt_mode_flg(a5)
	bne	exit_mml_chord
	bsr	rewrite_note_gate	*ゲートを書き換える
	move.l	#-1,tpt_note_buf(a5)	*off
exit_mml_chord:
	move.b	oct_wk(pc),tpt_octave(a5)
	bra	mml_lp

echo_case_chord0:			*擬似エコー・プリプロセッシング和音編(tie)
	* < d2.w=和音数
	* < d6.w=step_buf
	* < a1.l=和音テーブル
	move.w	tpt_echo_loop(a5),d7
	subq.w	#1,d7			*for dbra
	move.w	tpt_echo_dly(a5),d3	*step time work
echopelp0_cd0:
reglist	reg	d2-d3/d6-d7/a1-a3
	movem.l	reglist,-(sp)
	move.b	tpt_echo_vdec(a5),d0
	ext.w	d0
	move.w	d0,a2
echopelp1_cd0:				*<d6.w=step
	moveq.l	#0,d0
	move.b	(a1)+,d0
	move.w	d0,(a3)+		*tnb_note
	bsr	scan_prev_notes
	bsr	do_wrt_trk_b		*note
	moveq.l	#0,d1
	move.b	(a1),d1			*velo
	bpl	ech_absvlo_cd0
	move.l	d1,d0
	cmpi.b	#$80,d0
	bne	@f
	move.w	#192,d0			*neutral
	move.w	#192,d1			*neutral
@@:
	add.w	a2,d0
	cmpi.w	#129,d0
	bcc	@f
	moveq	#129,d0
	bra	echope_next_cd0
@@:
	cmpi.w	#255,d0
	bls	echope_next_cd0
	moveq.l	#255,d0
	bra	echope_next_cd0
ech_absvlo_cd0:
	move.l	d1,d0
	add.w	a2,d0
	bpl	@f
	moveq.l	#0,d0
	bra	echope_next_cd0
@@:
	cmpi.w	#127,d0
	bls	echope_next_cd0
	moveq.l	#127,d0
echope_next_cd0:
	move.b	d0,(a1)+		*次回のベロシティ
	move.w	tpt_chord_dly(a5),d0
	bpl	@f
	neg.w	d0
@@:
	tst.w	d2
	bne	@f
	move.w	d3,d0			*和音構成音の中でラスト
	tst.w	d7			*最後の最後の音か
	beq	1f
	cmp.w	d0,d6
	bcc	@f
1:
	move.w	d6,d0
@@:					*ゲートタイムはこの時点では0
	bsr	consider_trkfrq_st	*trkfrqを考慮する(step)
	bsr	do_wrt_trk_v		*step time

	move.w	d3,d0			*ゲートタイム
	tst.w	d7			*最後の最後の音か
	beq	1f
	cmp.w	d0,d6
	bcc	@f
1:
	move.w	d6,d0
@@:
	move.w	d0,-(sp)
	move.w	tpt_chord_dly(a5),d0
	bpl	@f
	neg.w	d0
@@:
	sub.w	d0,d6
	sub.w	d0,d3
	bls	m_delay_too_long
	move.w	(sp)+,d0
	move.w	d0,(a1)+
	bsr	consider_trkfrq_gt	*trkfrqを考慮する
	move.w	d0,(a3)+		*gate time
	move.l	tpt_now(a5),(a3)+	*tnb_offset
	move.l	#-1,(a3)		*endcode
	tst.w	d7			*
	bne	@f			*
	move.w	#CHORD_TIE_GATE,d0	*最後
@@:					*
	bsr	do_wrt_trk_v
	move.b	d1,d0
	bsr	do_wrt_trk_b		*velocity
	dbra	d2,echopelp1_cd0
	movem.l	(sp)+,reglist
	sub.w	tpt_echo_dly(a5),d6
	bls	@f
	dbra	d7,echopelp0_cd0
	tst.w	tpt_echo_loop(a5)
	beq	echopelp0_cd0
@@:
	bsr	rewrite_note_gate	*ゲートを書き換える
	bsr	preserve_this_note	*今回の発音内容を保存
	bra	exit_mml_chord

echo_case_chord1:			*擬似エコー・プリプロセッシング和音編(not tie)
	* < d2.w=和音数
	* < d6.w=step_buf
	* < a1.l=和音テーブル
	move.w	d6,d0
	bsr	calc_gt_chd
	move.l	d0,d5			*d5=calclated default gate time
	move.w	tpt_echo_loop(a5),d7
	subq.w	#1,d7			*for dbra
	move.w	tpt_echo_dly(a5),d3	*step time work
echopelp0_cd1:
reglist	reg	d2-d3/d5-d7/a1-a3
	movem.l	reglist,-(sp)
	move.b	tpt_echo_vdec(a5),d0
	ext.w	d0
	move.w	d0,a2
echopelp1_cd1:
	moveq.l	#0,d0
	move.b	(a1)+,d0
	bsr	scan_prev_notes
	bsr	do_wrt_trk_b		*note
	moveq.l	#0,d1
	move.b	(a1),d1			*velo
	bpl	ech_absvlo_cd1
	move.l	d1,d0
	cmpi.b	#$80,d0
	bne	@f
	move.w	#192,d0			*neutral
	move.w	#192,d1			*neutral
@@:
	add.w	a2,d0
	cmpi.w	#129,d0
	bcc	@f
	moveq	#129,d0
	bra	echope_next_cd1
@@:
	cmpi.w	#255,d0
	bls	echope_next_cd1
	moveq.l	#255,d0
	bra	echope_next_cd1
ech_absvlo_cd1:
	move.l	d1,d0
	add.w	a2,d0
	bpl	@f
	moveq.l	#0,d0
	bra	echope_next_cd1
@@:
	cmpi.w	#127,d0
	bls	echope_next_cd1
	moveq.l	#127,d0
echope_next_cd1:
	move.b	d0,(a1)+		*次回のベロシティ
	move.w	tpt_chord_dly(a5),d0
	bpl	@f
	neg.w	d0
@@:
	tst.w	d2
	bne	@f
	move.w	d3,d0
	tst.w	d7
	beq	1f
	cmp.w	d0,d6
	bcc	@f
1:
	move.w	d6,d0
@@:
	bsr	consider_trkfrq_st	*trkfrqを考慮する(step)
	bsr	do_wrt_trk_v		*step time

	move.w	(a1)+,d0		*get gate
	cmp.w	#-1,d0			*gate=-1は算出したゲートタイムを使用するケース
	bne	@f
	tst.w	d7
	beq	1f
	move.w	d3,d0
	cmp.w	d0,d5
	bcc	2f
1:
	move.w	d5,d0
	bra	2f
@@:					*指定されたゲートタイムを使うケース
	cmp.w	tpt_echo_dly(a5),d0
	bcs	@f
	sub.w	tpt_echo_dly(a5),d0
	move.w	d0,-2(a1)		*次回のゲートタイム
	move.w	tpt_echo_dly(a5),d0
	bra	2f
@@:
	clr.w	-2(a1)			*gate=0:end
2:
	move.w	d0,-(sp)
	move.w	tpt_chord_dly(a5),d0
	bpl	@f
	neg.w	d0
@@:
	sub.w	d0,d5
	sub.w	d0,d6
	sub.w	d0,d3
	bls	m_delay_too_long
	move.w	(sp)+,d0
	bsr	consider_trkfrq_gt	*trkfrqを考慮する
	bsr	do_wrt_trk_v		*gate time
	move.b	d1,d0
	bsr	do_wrt_trk_b		*velocity
	dbra	d2,echopelp1_cd1
	movem.l	(sp)+,reglist
	sub.w	tpt_echo_dly(a5),d5	*最後のときだけ引く
	bhi	@f
	moveq.l	#0,d5
@@:
	sub.w	tpt_echo_dly(a5),d6
	bls	@f
	dbra	d7,echopelp0_cd1
	tst.w	tpt_echo_loop(a5)
	beq	echopelp0_cd1
@@:
	btst.b	#c_renp1,tpt_mode_flg(a5)
	bne	exit_mml_chord
	bsr	rewrite_note_gate	*ゲートを書き換える
	move.l	#-1,tpt_note_buf(a5)	*off
	bra	exit_mml_chord

scan_prev_notes:			*前回のノート(タイ/スラー)の音と
	* < d0.b=note			*今回発音する音がダブルか
	* - all
	btst.b	#c_renp1,tpt_mode_flg(a5)
	bne	exit_spn0
	movem.l	d1/a2,-(sp)
	lea	tpt_note_buf(a5),a2
@@:
	move.b	tnb_note(a2),d1
	bmi	exit_spn		*endcode case
	tst.b	d0			*!休符やウェイトなどは特別扱い
	bmi	1f			*!
	cmp.b	d1,d0
	bne	next_spn
1:
	st.b	(a2)			*発見! flag on
next_spn:
	addq.w	#8,a2
	bra	@b
exit_spn:
	movem.l	(sp)+,d1/a2
exit_spn0:
	rts

preserve_this_note:			*今回発音した音を保存
	btst.b	#c_renp1,tpt_mode_flg(a5)
	bne	exit_ptn0
	movem.l	a2-a3,-(sp)
	lea	tpt_note_buf(a5),a2	*dest
	move.l	arry_stock(pc),a3	*src
@@:
	tst.b	tnb_note(a3)
	bmi	@f
	move.l	(a3)+,(a2)+
	move.l	(a3)+,(a2)+
	bra	@b
@@:
	move.l	#-1,(a2)+
	movem.l	(sp)+,a2-a3
exit_ptn0:
	rts

rewrite_note_gate:			*ゲートを書き換える
	btst.b	#c_renp1,tpt_mode_flg(a5)
	bne	exit_rng0
	movem.l	a1-a2,-(sp)
	lea	tpt_note_buf(a5),a2
@@:
	tst.b	tnb_note(a2)
	bmi	@f
	tst.b	(a2)			*フラグがONならノートがだぶっているということ
	bne	next_rng
	move.l	tnb_offset(a2),a1
	add.l	tpt_addr(a5),a1
	move.b	tnb_gate+0(a2),(a1)	*ワードゲートタイムセット
	tas.b	(a1)+			*最上位ビット=1(ワードマーク)
	move.b	tnb_gate+1(a2),(a1)	*ワードゲートタイムセット
next_rng:
	addq.w	#8,a2
	bra	@b
@@:
	movem.l	(sp)+,a1-a2
exit_rng0:
	rts

get_ag_length:
get_port_length:
get_chord_length:			*音符の後ろに音長のあるケース
	* > d0.w=step time
reglist	reg	d1-d3/a2
	movem.l	reglist,-(sp)
	bsr	skip_spc
	cmp.l	a4,d4
	bls	get_def_l		*音長省略のケース(デフォルトの取得)
	cmp.b	#'*',(a4)
	bne	1f
					*絶対音長指定
	addq.w	#1,a4			*skip '*'
	bsr	chk_oncho
	bmi	m_syntax_error		*数値がない
	btst.b	#c_renp1,tpt_mode_flg(a5)	*連符内に音長指定は出来ない
	bne	m_group_notes_command_error
	bsr	get_num			*絶対音長指定
	move.l	d1,d0
	bra	2f
get_def_l:
	bsr	skip_spc
	cmp.l	a4,d4
	bls	@f
	cmpi.b	#'.',(a4)
	bne	@f
gdl0:
	bset.b	#c_step,tpt_mode_flg(a5)	*符点がある場合は音長指定があったのと同等扱い
	move.w	tpt_note_len(a5),d0		*get default length
	bra	3f				*デフォルトステップタイムを得て符点処理へ
@@:
	cmpi.b	#'^',(a4)			*97/08/17
	beq	gdl0				*97/08/17
	btst.b	#c_step,tpt_mode_flg(a5)
	bne	4f				*ゲートタイムの取得へ
	move.w	tpt_note_len(a5),d0		*get default length
	bra	3f				*デフォルトステップタイムを得て符点処理へ
1:
	bsr	chk_oncho
	bmi	get_def_l			*音長省略のケース(デフォルトの取得)
	btst.b	#c_renp1,tpt_mode_flg(a5)	*連符内に音長指定は出来ない
	bne	m_group_notes_command_error
	bsr	get_length		*音楽音長
2:
	bset.b	#c_step,tpt_mode_flg(a5)	*mark
3:
	bsr	futen_ope		*< d0.w=step source
	cmp.l	#max_note_len,d1	*最大値チェック
	bhi	m_illegal_note_length
	move.w	d1,step_buf-work(a6)
	bclr.b	#c_gate,tpt_mode_flg(a5)	*以前のゲートタイム無効化
4:						*ゲートタイムが有れば取得
	bsr	skip_sep
	cmp.l	a4,d4
	bls	sv_wl
	bsr	chk_oncho
	bpl	1f
	cmp.b	#'*',(a4)		*直接音長指定?
	bne	mmlag_velo?
	addq.w	#1,a4			*skip '*'
	bsr	chk_oncho
	bmi	m_syntax_error		*数値がない
	bsr	get_num
	move.l	d1,d0
	bra	2f
1:
	bsr	get_length
2:
	bsr	futen_ope		*符点を考慮(< d0.l)
	move.w	d1,gate_buf-work(a6)
	bset.b	#c_gate,tpt_mode_flg(a5)	*flag on
mmlag_velo?:
	bsr	skip_sep		*ベロシティがあればゲット
	cmp.l	a4,d4
	bls	sv_wl
	bsr	chk_num
	bmi	sv_wl
					*ベロシティー
	move.b	(a4),d0
	cmpi.b	#'-',d0			*相対チェック
	beq	@f
	cmpi.b	#'+',d0
	bne	exc_velo_dn	*直値指定
@@:				*相対指定
	bsr	get_num
	add.l	#192,d1		*-63～63を129～255へ
	cmpi.l	#129,d1
	bcs	m_illegal_velocity_value
	cmpi.l	#255,d1
	bhi	m_illegal_velocity_value
	bra	@f
exc_velo_dn:
	bsr	get_num
	cmpi.l	#127,d1
	bhi	m_illegal_velocity_value
@@:
	move.b	d1,vl_buf-work(a6)
sv_wl:
	movem.l	(sp)+,reglist
	rts

mml_@j:					*ＭＩＤＩのスペシャル・タイ・モードの設定
	bsr	chk_num
	bpl	@f
	moveq.l	#0,d1
	bra	mst0
@@:
	bsr	get_num
	cmpi.l	#1,d1
	bhi	m_illegal_tie_mode	*タイモード値が異常です
mst0:
	moveq.l	#tie_mode_zmd,d0
	bsr	do_wrt_trk_b
	bsr	wrt_data_d1
	bra	mml_lp

mml_tie_mode:				*[TIE_MODE]
	bsr	chk_num
	bpl	@f
	lea	tiemd_tbl(pc),a1
	bsr	get_com_no		*>d0=0:normal,1:special,2:enhanced
	bmi	m_illegal_tie_mode	*タイモード値が異常です
	move.l	d0,d1
	cmpi.b	#2,d1
	bcs	_mst0
	moveq.l	#1,d1			*ENHANCEDはSPECIALと同値に
	bra	_mst0
@@:
	bsr	get_num
	cmpi.l	#1,d1
	bhi	m_illegal_tie_mode	*タイモード値が異常です
_mst0:
	moveq.l	#tie_mode_zmd,d0
	bsr	do_wrt_trk_b
	bra	wrt_data_d1

mml_switch:					*=n(特殊コマンドのオンオフスイッチ)
	bsr	chk_num
	bpl	get_sw
	moveq.l	#0,d1
	bra	chk_sw_n
get_sw:
	bsr	get_num
	cmpi.l	#255,d1
	bhi	m_illegal_switch_value
chk_sw_n:
	bclr.b	#c_vseq,tpt_mode_flg(a5)	*ﾍﾞﾛｼﾃｨｼｰｹﾝｽ･ｱｸﾃｨｳﾞ･ｽｲｯﾁ初期化
	btst.l	#sw_vseq,d1
	beq	@f
	bset.b	#c_vseq,tpt_mode_flg(a5)	*ﾍﾞﾛｼﾃｨｼｰｹﾝｽ･ｱｸﾃｨｳﾞ･ｽｲｯﾁ設定
@@:
	moveq.l	#0,d2				*アフタータッチ・シーケンス・スイッチ
	btst.l	#sw_aftc,d1
	beq	@f
	moveq.l	#previous_on,d2
@@:
	moveq.l	#aftc_sw_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d2,d0
	bsr	do_wrt_trk_b

	moveq.l	#0,d2				*オートベンドスイッチ
	btst.l	#sw_bend,d1
	beq	@f
	moveq.l	#previous_on,d2
@@:
	moveq.l	#bend_sw_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d2,d0
	bsr	do_wrt_trk_b

	moveq.l	#0,d2				*ARCC-0スイッチ
	btst.l	#sw_arcc0,d1
	beq	@f
	moveq.l	#previous_on,d2
@@:
	moveq.l	#arcc_sw_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#0,d0				*arcc no.
	bsr	do_wrt_trk_b
	move.l	d2,d0
	bsr	do_wrt_trk_b

	moveq.l	#0,d2				*PMODスイッチ
	btst.l	#sw_pmod,d1
	beq	@f
	moveq.l	#previous_on,d2
@@:
	moveq.l	#pmod_sw_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d2,d0
	bsr	do_wrt_trk_b
	bra	mml_lp

mml_agogik_depth:			*[AGOGIK.DEPTH]
	moveq.l	#agogik8_zmd,d0
	bra	@f

mml_vibrato_depth:			*[VIBRATO.DEPTH]
	moveq.l	#pmod8_zmd,d0
@@:
	bsr	do_wrt_trk_b
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	cmpi.b	#',',(a4)
	beq	1f
	lea	switch_strv2(pc),a1
	bsr	get_com_no
	bmi	1f
	subq.b	#1,d0			*-1,0,1,2
	beq	mvd_off			*OFF
	bra	@f
1:
	moveq.l	#0,d0			*no touch
@@:
	move.l	tpt_now(a5),d5		*あとでomtを格納するため
	bsr	do_wrt_trk_b		*mode
	moveq.l	#0,d0
	bsr	do_wrt_trk_b		*dummy omt
	bsr	skip_sep
	bsr	get_@m_prm
	bsr	chk_num
	bpl	m_too_many_parameters	*パラメータ多すぎ
	move.l	tpt_addr(a5),a1
	add.l	d5,a1
	cmpi.w	#1,d6			*パラメータが複数あるか
	bcs	1f
	bne	@f
	move.b	#1,(a1)			*1つのときは強制的にoptional mode
@@:
	move.b	d6,1(a1)		*set omt
1:
	rts

mvd_off:
	moveq.l	#0,d0			*mode=0,omt=0 → OFF
	bra	do_wrt_trk_w

mml_@m:				*ピッチモジュレーション @M
	moveq.l	#pmod8_zmd,d0
	bsr	do_wrt_trk_b
	move.l	tpt_now(a5),d5	*あとでmode/omtを格納するため
	moveq.l	#0,d0
	bsr	do_wrt_trk_w	*2bytes確保(mode=0,omt=0)
	bsr	get_@m_prm
	bsr	chk_num
	bpl	m_too_many_parameters	*パラメータ多すぎ
	move.l	tpt_addr(a5),a1
	add.l	d5,a1
	move.w	d6,d0
	beq	@f
	moveq.l	#1,d0			*optional mode
	cmpi.w	#1,d6			*パラメータが複数あるか
	bcs	mml_lp
	beq	@f
	moveq.l	#-1,d0			*1/8 mode(複数の場合)
@@:
	move.b	d0,(a1)+		*mode
	move.b	d6,(a1)+		*set omt
	bra	mml_lp

get_@m_prm:
	* > d6.b=omt
	moveq.l	#0,d6		*omt
	bsr	skip_spc
	cmp.l	a4,d4
	bls	exit_g@mp
	cmpi.b	#',',(a4)
	beq	@f
	bsr	chk_num
	bmi	exit_g@mp	*@mだけの場合はmode=0,omt=0でスイッチオフ
@@:
	moveq.l	#0,d2		*loop counter
	moveq.l	#0,d3		*previous value
mml_pmod_lp01:
	moveq.l	#0,d1
	bsr	chk_num
	bpl	@f
	cmp.l	a4,d4
	bls	exit_g@mp
	cmpi.b	#',',(a4)
	bne	exit_g@mp
	bsr	skip_sep	*skip ','
	bra	next_g@mp
@@:				*振幅パラメータ有り
	move.b	(a4),d0
	cmpi.b	#'+',d0
	beq	rltv_pmod_depth
	cmpi.b	#'-',d0
	bne	@f
rltv_pmod_depth:			*相対指定ケース
	bsr	get_num
	add.l	d3,d1
	bra	chk_pmsz
@@:
	bsr	get_num
chk_pmsz:
	cmpi.l	#-32768,d1
	blt	m_illegal_depth_value	*値が16bit範囲より大きいとエラー
	cmpi.l	#32767,d1
	bgt	m_illegal_depth_value	*値が16bit範囲より大きいとエラー
	bsr	skip_sep		*skip ','
	* < d1.l=modulation value
	bset.l	d2,d6		*set omt
	move.l	d1,d0
	bsr	do_wrt_trk_w	*振幅書き込み
	move.l	d1,d3		*save d1 into d3
next_g@mp:
	bsr	chk_num
	bpl	@f
	cmp.l	a4,d4
	bls	exit_g@mp
	cmpi.b	#',',(a4)	*まだパラメータがあるか
	bne	exit_g@mp
@@:
	addq.w	#1,d2
	cmpi.w	#modu_max,d2
	bcs	mml_pmod_lp01
exit_g@mp:
	rts

mml_agogik_delay:			*[AGOGIK.DELAY]
	moveq.l	#agogik_delay8_zmd,d0
	bsr	do_wrt_trk_b
	bra	@f

mml_velocity_delay:			*[VELOCITY.DELAY]
	moveq.l	#vseq_delay8_zmd,d0
	bsr	do_wrt_trk_b
@@:
	move.l	tpt_now(a5),d5		*あとでomtを格納するため
	moveq.l	#0,d0				*omt
	bsr	do_wrt_trk_w
	moveq.l	#1,d6			*0-65535
	bsr	get_@h_prm
	bsr	chk_num
	bpl	m_too_many_parameters	*パラメータ多すぎ
	cmpi.w	#1,d6			*パラメータが複数あるか
	bcs	m_parameter_cannot_be_omitted
	move.l	tpt_addr(a5),a1
	add.l	d5,a1
	ror.w	#8,d6
	move.b	d6,(a1)+
	ror.w	#8,d6
	move.b	d6,(a1)+
	rts

mml_arcc4_delay:			*[ARCC4.DELAY]
	moveq.l	#6,d1
	bra	@f
mml_arcc3_delay:			*[ARCC3.DELAY]
	moveq.l	#4,d1
	bra	@f
mml_arcc2_delay:			*[ARCC2.DELAY]
	moveq.l	#2,d1
	bra	@f
mml_arcc1_delay:			*[ARCC1.DELAY]
	moveq.l	#0,d1
@@:
	moveq.l	#arcc_delay8_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d1,d0			*arcc no.
	bsr	do_wrt_trk_b
	bra	@f

mml_aftertouch_delay:			*[AFTERTOUCH.DELAY]
	moveq.l	#aftc_delay8_zmd,d0
	bsr	do_wrt_trk_b
	bra	@f

mml_vibrato_delay:			*[VIBRATO.DELAY]
	moveq.l	#pmod_delay8_zmd,d0
	bsr	do_wrt_trk_b
@@:
	move.l	tpt_now(a5),d5		*あとでomtを格納するため
	moveq.l	#0,d0			*omt
	bsr	do_wrt_trk_w
	moveq.l	#0,d6			*-32768～32767
	bsr	get_@h_prm
	bsr	chk_num
	bpl	m_too_many_parameters	*パラメータ多すぎ
	cmpi.w	#1,d6			*パラメータが複数あるか
	bcs	m_parameter_cannot_be_omitted
	move.l	tpt_addr(a5),a1
	add.l	d5,a1
	ror.w	#8,d6
	move.b	d6,(a1)+
	ror.w	#8,d6
	move.b	d6,(a1)+
	rts

get_@h_prm:			*ディレイパラメータとりだし
	* < d6.l=effective range 0:-32768～32767,1:0～65535
	* > d6.b=omt
	* - all
reglist	reg	d1-d3/d7
	movem.l	reglist,-(sp)
	move.l	d6,d7
	moveq.l	#0,d6		*omt
	bsr	skip_spc
	cmp.l	a4,d4
	bls	exit_g@hp
	cmpi.b	#',',(a4)
	beq	@f
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
@@:
	moveq.l	#0,d2		*loop counter
	moveq.l	#0,d3		*previous value
mml_gt@h_lp01:
	moveq.l	#0,d1
	bsr	chk_num
	bpl	@f
	cmp.l	a4,d4
	bls	exit_g@hp
	cmpi.b	#',',(a4)
	bne	exit_g@hp
	bsr	skip_sep	*skip ','
	bra	next_g@hp
@@:				*パラメータ有り
	move.b	(a4),d0
	cmpi.b	#'+',d0
	beq	rltv_delay
	cmpi.b	#'-',d0
	bne	@f
rltv_delay:			*相対指定ケース
	bsr	get_num
	add.l	d3,d1
	bra	chk_dlysz
@@:
	bsr	get_num
chk_dlysz:
	tst.l	d2
	beq	@f
	tst.l	d1			*0が設定できるのは最初のディレイだけ
	beq	m_illegal_delay
	bra	1f			*最初以外は1-65535とする
@@:
	tst.l	d7			*check RANGE flag
	beq	@f
1:
	cmpi.l	#max_note_len,d1	*0-65535
	bhi	m_delay_too_long	*絶対値が16bit範囲より大きいとエラー
	bra	1f
@@:					*-32768～32767
	cmpi.l	#-32768,d1
	blt	m_delay_too_long	*絶対値が16bit範囲より大きいとエラー
	cmpi.l	#32767,d1
	bgt	m_delay_too_long	*絶対値が16bit範囲より大きいとエラー
1:
	bsr	skip_sep		*skip ','
	bset.l	d2,d6			*set omt
	move.l	d1,d3			*save d1 into d3
	move.l	d1,d0
	bsr	consider_trkfrq_st	*trkfrqを考慮する
	bsr	do_wrt_trk_w		*ディレイ値書き込み
next_g@hp:
	bsr	chk_num
	bpl	@f
	cmp.l	a4,d4
	bls	exit_g@hp
	cmpi.b	#',',(a4)	*まだパラメータがあるか
	bne	exit_g@hp
@@:
	addq.w	#1,d2
	cmpi.w	#modu_max+1,d2	*最初のディレイ+8個のディレイ=9個のディレイが書ける
	bcs	mml_gt@h_lp01
exit_g@hp:
	movem.l	(sp)+,reglist
	rts

mml_@h:						*モジュレーションディレイ
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted	*パラメータ両方省略はエラー
	cmpi.b	#',',(a4)
	beq	@f				*最初のパラメータが省略
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted	*数字がない
	bsr	get_num
	cmpi.l	#-32768,d1
	blt	m_delay_too_long		*絶対値が16bit範囲より大きいとエラー
	cmpi.l	#32767,d1
	bgt	m_delay_too_long		*絶対値が16bit範囲より大きいとエラー
	moveq.l	#pmod_delay8_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#1,d0				*omt
	bsr	do_wrt_trk_w
	move.l	d1,d0				*delay value
	bsr	consider_trkfrq_st		*trkfrqを考慮する
	bsr	do_wrt_trk_w
@@:
	bsr	skip_sep			*skip ','
	bsr	chk_num
	bmi	mml_lp				*数字がないので省略と見なす
	bsr	get_num
	cmpi.l	#-32768,d1
	blt	m_delay_too_long		*絶対値が16bit範囲より大きいとエラー
	cmpi.l	#32767,d1
	bgt	m_delay_too_long		*絶対値が16bit範囲より大きいとエラー
	moveq.l	#arcc_delay8_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#0,d0				*arcc no.=0
	bsr	do_wrt_trk_b
	moveq.l	#1,d0				*omt
	bsr	do_wrt_trk_w
	move.l	d1,d0				*delay value
	bsr	consider_trkfrq_st		*trkfrqを考慮する
	bsr	do_wrt_trk_w
	bra	mml_lp

mml_arcc4_speed:			*[ARCC4.SPEED]
	moveq.l	#6,d1
	bra	@f
mml_arcc3_speed:			*[ARCC3.SPEED]
	moveq.l	#4,d1
	bra	@f
mml_arcc2_speed:			*[ARCC2.SPEED]
	moveq.l	#2,d1
	bra	@f
mml_arcc1_speed:			*[ARCC1.SPEED]
	moveq.l	#0,d1
@@:
	moveq.l	#arcc_speed8_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d1,d0
	bsr	do_wrt_trk_b		*arcc no.
	bra	@f

mml_agogik_speed:				*[AGOGIK.SPEED]
	moveq.l	#agogik_speed8_zmd,d0
	bsr	do_wrt_trk_b
	bra	@f

mml_velocity_speed:				*[VELOCITY.SPEED]
	moveq.l	#vseq_speed8_zmd,d0
	bsr	do_wrt_trk_b
	bra	@f

mml_vibrato_speed:				*[VIBRATO.SPEED]
	moveq.l	#pmod_speed8_zmd,d0
	bsr	do_wrt_trk_b
@@:
	move.l	tpt_now(a5),d5		*あとでomtを格納するため
	moveq.l	#0,d0				*omt
	bsr	do_wrt_trk_b
	bsr	get_@s_prm
	bsr	chk_num
	bpl	m_too_many_parameters	*パラメータ多すぎ
	cmpi.w	#1,d6			*パラメータが複数あるか
	bcs	m_parameter_cannot_be_omitted
	move.l	tpt_addr(a5),a1
	move.b	d6,(a1,d5.l)		*set omt
	rts

get_@s_prm:			*スピードパラメータとりだし
	* > d6.b=omt
	moveq.l	#0,d6		*omt
	bsr	skip_spc
	cmp.l	a4,d4
	bls	exit_g@sp
	cmpi.b	#',',(a4)
	beq	@f
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
@@:
	moveq.l	#0,d2		*loop counter
	moveq.l	#0,d3		*previous value
mml_gt@s_lp01:
	moveq.l	#0,d1
	bsr	chk_num
	bpl	@f
	cmp.l	a4,d4
	bls	exit_g@sp
	cmpi.b	#',',(a4)
	bne	exit_g@sp
	bsr	skip_sep	*skip ','
	bra	next_g@sp
@@:				*振幅パラメータ有り
	move.b	(a4),d0
	cmpi.b	#'+',d0
	beq	rltv_speed
	cmpi.b	#'-',d0
	bne	@f
rltv_speed:		*相対指定ケース
	bsr	get_num
	add.l	d3,d1
	bra	chk_spdsz
@@:
	bsr	get_num
chk_spdsz:
	tst.l	d1
	beq	m_illegal_speed_value
	cmpi.l	#spd_max,d1
	bhi	m_speed_too_slow	*絶対値が16bit範囲より大きいとエラー
	bsr	skip_sep		*skip ','
	bset.l	d2,d6			*set omt
	move.l	d1,d3			*save d1 into d3
	move.l	d1,d0
	add.w	d0,d0			*2倍
	bsr	consider_trkfrq_st	*trkfrqを考慮する
	bsr	do_wrt_trk_w		*スピード値
next_g@sp:
	bsr	chk_num
	bpl	@f
	cmp.l	a4,d4
	bls	exit_g@sp
	cmpi.b	#',',(a4)	*まだパラメータがあるか
	bne	exit_g@sp
@@:
	addq.w	#1,d2
	cmpi.w	#modu_max,d2
	bcs	mml_gt@s_lp01
exit_g@sp:
	rts

mml_@s:						*モジュレーションスピード
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted	*パラメータ両方省略はエラー
	cmpi.b	#',',(a4)
	beq	@f				*最初のパラメータが省略
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted	*数字がない
	bsr	get_num
	cmpi.l	#spd_max,d1
	bhi	m_speed_too_slow		*規定外
	add.w	d1,d1				*2倍
	beq	m_illegal_speed_value		*規定外
	moveq.l	#pmod_speed8_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#1,d0				*omt
	bsr	do_wrt_trk_b
	move.l	d1,d0				*speed value
	bsr	consider_trkfrq_st		*trkfrqを考慮する
	bsr	do_wrt_trk_w
@@:
	bsr	skip_sep			*skip ','
	bsr	chk_num
	bmi	mml_lp				*数字がないので省略と見なす
	bsr	get_num
	cmpi.l	#spd_max,d1
	bhi	m_speed_too_slow		*規定外
	add.w	d1,d1
	beq	m_illegal_speed_value		*2倍
	moveq.l	#arcc_speed8_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#0,d0				*arcc no.=0
	bsr	do_wrt_trk_b
	moveq.l	#1,d0				*omt
	bsr	do_wrt_trk_b
	move.l	d1,d0				*speed value
	bsr	consider_trkfrq_st		*trkfrqを考慮する
	bsr	do_wrt_trk_w
	bra	mml_lp

mml_velocity_depth:				*[VELOCITY.DEPTH]
	moveq.l	#vseq8_zmd,d0
	bsr	do_wrt_trk_b
	bra	get_8_depth
mml_arcc4_depth:				*[ARCC4.DEPTH]
	moveq.l	#6,d1
	bra	@f
mml_arcc3_depth:				*[ARCC3.DEPTH]
	moveq.l	#4,d1
	bra	@f
mml_arcc2_depth:				*[ARCC2.DEPTH]
	moveq.l	#2,d1
	bra	@f
mml_arcc1_depth:				*[ARCC1.DEPTH]
	moveq.l	#0,d1
@@:
	moveq.l	#arcc8_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d1,d0
	bsr	do_wrt_trk_b			*arcc no.
get_8_depth:
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	cmpi.b	#',',(a4)
	beq	1f
	lea	switch_strv2(pc),a1
	bsr	get_com_no
	bmi	1f
	subq.b	#1,d0			*-1,0,1,2
	beq	mad_off			*OFF
	bra	@f
1:
	moveq.l	#0,d0			*no touch
@@:
	move.l	tpt_now(a5),d5		*あとでomtを格納するため
	bsr	do_wrt_trk_b		*mode
	moveq.l	#0,d0
	bsr	do_wrt_trk_b		*dummy omt
	bsr	skip_sep
	bsr	get_@a_prm
	bsr	chk_num
	bpl	m_too_many_parameters	*パラメータ多すぎ
	move.l	tpt_addr(a5),a1
	add.l	d5,a1
	cmpi.w	#1,d6			*パラメータが複数あるか
	bcs	1f
	bne	@f
	move.b	#1,(a1)			*1つのときは強制的にoptional mode
@@:
	move.b	d6,1(a1)		*set omt
1:
	rts

mad_off:
	moveq.l	#0,d0			*mode=0,omt=0 → OFF
	bra	do_wrt_trk_w

mml_@a:				*ＡＲＣＣ
	moveq.l	#arcc8_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#0,d0
	bsr	do_wrt_trk_b	*arcc no.=0
	move.l	tpt_now(a5),d5	*あとでmode/omtを格納するため
	moveq.l	#0,d0
	bsr	do_wrt_trk_w	*2bytes確保(mode=0,omt=0)
	bsr	get_@a_prm
	bsr	chk_num
	bpl	m_too_many_parameters	*パラメータ多すぎ
	move.l	tpt_addr(a5),a1
	add.l	d5,a1
	moveq.l	#1,d0			*optional mode
	cmpi.w	#1,d6			*パラメータが複数あるか
	bcs	mml_lp
	beq	@f
	moveq.l	#-1,d0			*1/8 mode(複数の場合)
@@:
	move.b	d0,(a1)+		*mode
	move.b	d6,(a1)+		*set omt
	bra	mml_lp

get_@a_prm:
	moveq.l	#0,d6		*omt
	bsr	skip_spc
	cmp.l	a4,d4
	bls	exit_g@ap
	cmpi.b	#',',(a4)
	beq	@f
	bsr	chk_num
	bmi	exit_g@ap	*@aだけの場合はmode=0,omt=0でスイッチオフ
@@:
	moveq.l	#0,d2		*loop counter
	moveq.l	#0,d3		*previous value
mml_arcc_lp01:
	moveq.l	#0,d1
	bsr	chk_num
	bpl	@f
	cmp.l	a4,d4
	bls	exit_g@ap
	cmpi.b	#',',(a4)
	bne	exit_g@ap
	bsr	skip_sep	*skip ','
	bra	next_g@ap
@@:				*振幅パラメータ有り
	move.b	(a4),d0
	cmpi.b	#'+',d0
	beq	rltv_arcc_depth
	cmpi.b	#'-',d0
	bne	@f
rltv_arcc_depth:		*相対指定ケース
	bsr	get_num
	add.l	d3,d1
	bra	chk_arsz
@@:
	bsr	get_num
chk_arsz:
	move.l	d1,d0
	bpl	@f
	neg.l	d0
@@:
	cmpi.l	#-128,d1
	blt	m_illegal_depth_value	*値が8bit範囲より大きいとエラー
	cmpi.l	#127,d1
	bgt	m_illegal_depth_value	*値が8bit範囲より大きいとエラー
	bsr	skip_sep	*skip ','
	* < d1.l=arcc depth
	bset.l	d2,d6		*set omt
	bsr	wrt_data_d1	*振幅書き込み
	move.l	d1,d3		*save d1 into d3
next_g@ap:
	bsr	chk_num
	bpl	@f
	cmp.l	a4,d4
	bls	exit_g@ap
	cmpi.b	#',',(a4)	*まだパラメータがあるか
	bne	exit_g@ap
@@:
	addq.w	#1,d2
	cmpi.w	#modu_max,d2
	bcs	mml_arcc_lp01
exit_g@ap:
	rts

mml_arcc4_reset:		*[ARCC4.RESET]
	moveq.l	#6,d5		*arcc no.
	bra	@f
mml_arcc3_reset:		*[ARCC3.RESET]
	moveq.l	#4,d5		*arcc no.
	bra	@f
mml_arcc2_reset:		*[ARCC2.RESET]
	moveq.l	#2,d5		*arcc no.
	bra	@f
mml_arcc1_reset:		*[ARCC1.RESET]
	moveq.l	#0,d5		*arcc no.
@@:
	moveq.l	#0,d6		*omt
				*get reset value
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
	bsr	get_num
	cmpi.l	#127,d1
	bhi	m_illegal_reset_value
	moveq.l	#asgn_arcc_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d5,d0		*arcc number
	bsr	do_wrt_trk_b
	moveq.l	#%0100_0000,d0	*omt
	bsr	do_wrt_trk_b
	move.l	d1,d0		*reset value
	bra	do_wrt_trk_b

mml_arcc4_origin:		*[ARCC4.ORIGIN]
	moveq.l	#6,d5		*arcc no.
	bra	@f
mml_arcc3_origin:		*[ARCC3.ORIGIN]
	moveq.l	#4,d5		*arcc no.
	bra	@f
mml_arcc2_origin:		*[ARCC2.ORIGIN]
	moveq.l	#2,d5		*arcc no.
	bra	@f
mml_arcc1_origin:		*[ARCC1.ORIGIN]
	moveq.l	#0,d5		*arcc no.
@@:
	moveq.l	#0,d6		*omt
				*get origin value
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
	bsr	get_num
	cmp.l	#127,d1
	bhi	m_illegal_wave_origin
	moveq.l	#asgn_arcc_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d5,d0		*arcc number
	bsr	do_wrt_trk_b
	moveq.l	#%0010_0000,d0	*omt
	bsr	do_wrt_trk_b
	move.l	d1,d0		*origin value
	bra	do_wrt_trk_b

mml_arcc4_control:		*[ARCC4.CONTROL]
	moveq.l	#6,d5		*arcc no.
	bra	@f
mml_arcc3_control:		*[ARCC3.CONTROL]
	moveq.l	#4,d5		*arcc no.
	bra	@f
mml_arcc2_control:		*[ARCC2.CONTROL]
	moveq.l	#2,d5		*arcc no.
	bra	@f
mml_arcc1_control:		*[ARCC1.CONTROL]
	moveq.l	#0,d5		*arcc no.
@@:
	moveq.l	#0,d6		*omt
				*get control number
	bsr	chk_num
	bpl	get_@c_prm
	lea	control_name(pc),a1	*MIDIコントロールパラメータ
	bsr	get_com_no
	bmi	@f
	move.l	d0,d2
	bra	mark_gotarcctrl
@@:
	lea	control_name2(pc),a1	*FM音源パラメータ
	bsr	get_com_no
	bmi	m_illegal_control_number
	move.l	d0,d2
	add.w	#$80,d2
	bra	mark_gotarcctrl

mml_arcc4_phase:		*[ARCC4.PHASE]
	moveq.l	#6,d5		*arcc no.
	bra	@f
mml_arcc3_phase:		*[ARCC3.PHASE]
	moveq.l	#4,d5		*arcc no.
	bra	@f
mml_arcc2_phase:		*[ARCC2.PHASE]
	moveq.l	#2,d5		*arcc no.
	bra	@f
mml_arcc1_phase:		*[ARCC1.PHASE]
	moveq.l	#0,d5		*arcc no.
@@:
	moveq.l	#0,d6		*omt
				*get phase type
	bsr	chk_num
	bmi	@f
	bsr	get_num
	tst.l	d1
	bra	1f
@@:
	lea	phase_tbl(pc),a1
	bsr	get_com_no
	bmi	m_undefined_phase_type
	moveq.l	#0,d1
	tst.l	d0
1:
	beq	@f
	moveq.l	#-1,d1
@@:
	moveq.l	#asgn_arcc_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d5,d0		*arcc number
	bsr	do_wrt_trk_b
	moveq.l	#%0001_0000,d0	*omt
	bsr	do_wrt_trk_b
	move.l	d1,d0		*reset value
	bra	do_wrt_trk_b

mml_@c:				*ARCCコンフィギュレーション
	moveq.l	#0,d5		*arcc no.
get_@c_prm:
	moveq.l	#0,d6		*omt
				*get control number
	bsr	chk_num
	bmi	@f
	bsr	get_num
	cmp.l	#255,d1
	bhi	m_illegal_arcc_control	*規定外のコントロール
	move.l	d1,d2
mark_gotarcctrl:
	tas.b	d6
@@:				*get reset value
	bsr	skip_sep	*skip ','
	bsr	chk_num
	bmi	@f
	bsr	get_num
	cmp.l	#255,d1
	bhi	m_illegal_reset_value
	move.l	d1,d3
	ori.b	#$40,d6
@@:				*get wave basis
	bsr	skip_sep	*skip ','
	bsr	chk_num
	bmi	@f
	bsr	get_num
	cmp.l	#255,d1
	bhi	m_illegal_wave_origin
	move.l	d1,a1
	ori.b	#$20,d6
@@:
	bsr	skip_sep	*get phase
	bsr	chk_num
	bmi	@f
	bsr	get_num
	ori.b	#$10,d6
	tst.l	d1		*0:正位相
	beq	@f
	moveq.l	#-1,d1		*-1:逆位相
@@:
	tst.b	d6
	beq	m_illegal_parameters_combination	*全部省略はダメ
	moveq.l	#asgn_arcc_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d5,d0			*arcc no.
	bsr	do_wrt_trk_b
	move.l	d6,d0			*omt
	bsr	do_wrt_trk_b
	tst.b	d6
	bpl	@f
	move.l	d2,d0			*ctrl n
	bsr	do_wrt_trk_b
@@:
	add.b	d6,d6
	bpl	@f
	move.l	d3,d0			*reset v
	bsr	do_wrt_trk_b
@@:
	add.b	d6,d6
	bpl	@f
	move.l	a1,d0			*middle v
	bsr	do_wrt_trk_b
@@:
	add.b	d6,d6
	bpl	@f
	move.l	d1,d0			*phase
	bsr	do_wrt_trk_b
@@:
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	rts
*-----------------------------------------------------------------------------
mml_arcc4_waveform:			*[ARCC4.WAVEFORM]
	moveq.l	#6,d2
	bra	@f
mml_arcc3_waveform:			*[ARCC3.WAVEFORM]
	moveq.l	#4,d2
	bra	@f
mml_arcc2_waveform:			*[ARCC2.WAVEFORM]
	moveq.l	#2,d2
	bra	@f
mml_arcc1_waveform:			*[ARCC1.WAVEFORM]
	moveq.l	#0,d2
@@:
	bsr	chk_num
	bpl	@f
	lea	wvfm_tbl(pc),a1
	bsr	get_com_no
	bmi	m_illegal_wave_number	*規定外
	move.l	d0,d1
	bra	do_wrt_arccwvfm
@@:
	bsr	get_num
	cmp.l	#wv_reg_max+wv_def_max-1,d1
	bhi	m_illegal_wave_number	*規定外
	cmpi.b	#4,d1
	bls	do_wrt_arccwvfm
	cmpi.b	#7,d1
	bls	m_illegal_wave_number	*4～7はリザーブ
	subq.w	#8,d1
	ori.w	#$8000,d1		*ユーザー波形マーク
do_wrt_arccwvfm:
	moveq.l	#arcc_wf_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d2,d0			*arcc number(0-3)*2
	bsr	do_wrt_trk_b
	move.l	d1,d0			*wf number
	bra	do_wrt_trk_w
*-----------------------------------------------------------------------------
mml_master_fader:		*[MASTER_FADER]
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_illegal_command_line
	cmpi.b	#']',(a4)
	beq	m_illegal_command_line
	lea	mstrfdrdvid,a2
	moveq.l	#0,d2				*指定されたデバイスのマーカー
mmlsetmstrfdrlp:
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_illegal_command_line
	cmpi.b	#']',(a4)
	beq	exit_mmlmstrfdr
	moveq.l	#master_fader_zmd,d0
	bsr	do_wrt_trk_b
	lea	mstrfadr_dev(pc),a1		*デバイス名テーブル
	jsr	get_com_no-work(a6)			*> d0
	bmi	m_illegal_device_id
	subq.l	#1,d0
	bcs	mmlmstrfdrall
	bset.l	d0,d2				*mark
	bne	m_device_id_redesignation	*同一デバイス名が複数回指定されている
	add.w	d0,d0
	move.w	(a2,d0.w),d0
mmlsetmstrfdrdev:
	bsr	do_wrt_trk_w	*device
	bsr	skip_sep
	moveq.l	#0,d5		*off speed value
	moveq.l	#0,d6		*omt
	bsr	chk_num
	bpl	@f
	lea	switch_strv(pc),a1
	jsr	get_com_no-work(a6)		*文字パラメータは"OFF"のみ有効
	bmi	m_illegal_switch_value
	tst.l	d0
	bne	m_illegal_switch_value
	bra	do_wrt_mstfd			*オフ
@@:
	bsr	get_spd_fdlvl	*>d6.b=omt
do_wrt_mstfd:
	move.l	d6,d0
	bsr	do_wrt_trk_b	*omt
	lsr.b	#1,d6
	bcc	@f
	move.l	d5,d0
	bsr	do_wrt_trk_w	*speed(switch)
@@:
	lsr.b	#1,d6
	bcc	@f
	bsr	wrt_data_d2	*start level
@@:
	lsr.b	#1,d6
	bcc	@f
	bsr	wrt_data_d3	*end level
@@:
	bsr	skip_sep
	bra	mmlsetmstrfdrlp
exit_mmlmstrfdr:
	rts

mmlmstrfdrall:					*マスターフェーダー全デバイス設定ケース
	tst.l	d2
	bne	m_device_id_redesignation	*同一デバイス名が複数回指定されている
	moveq.l	#-1,d2				*全デバイス設定したというマーク
	moveq.l	#-1,d0				*全デバイスを操作対象とするマーク
	bsr	do_wrt_trk_w			*device
	bsr	skip_sep
	moveq.l	#0,d5				*off value
	moveq.l	#0,d6				*omt
	bsr	chk_num
	bpl	@f
	lea	switch_strv(pc),a1
	jsr	get_com_no-work(a6)		*文字パラメータは"OFF"のみ有効
	bmi	m_illegal_switch_value
	tst.l	d0
	bne	m_illegal_switch_value
	bra	do_wrt_mstfdall			*オフ
@@:
	bsr	get_spd_fdlvl	*>d6.b=omt
do_wrt_mstfdall:
	move.l	d6,d0
	bsr	do_wrt_trk_b	*omt
	lsr.b	#1,d6
	bcc	@f
	move.l	d5,d0
	bsr	do_wrt_trk_w	*speed(switch)
@@:
	lsr.b	#1,d6
	bcc	@f
	bsr	wrt_data_d2	*start level
@@:
	lsr.b	#1,d6
	bcs	wrt_data_d3	*end level
	rts

mml_ch_fader:			*[CH_FADER]
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_illegal_command_line
	cmpi.b	#']',(a4)
	beq	m_illegal_command_line
mchfd_lp:
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_illegal_command_line
	cmpi.b	#']',(a4)
	beq	exit_mmlchfdr
	lea	chfdr_dev(pc),a1
	jsr	get_com_no-work(a6)	*> d0
	bpl	chfdr_all_case
	jbsr	get_str_ch		*> d2=type,ch
	bne	m_error_code_exit
	swap	d2
	cmpi.w	#-1,d2		*get_str_chでの上位ワード=-1はカレントMIDIを表すから
	bne	@f		*これを有効パラメータに変換する
	move.w	#$7ffd,d2
@@:
	swap	d2
	move.l	d2,d7		*d7=type,ch
mchfd00:
	bsr	skip_sep
	moveq.l	#0,d5		*off value
	moveq.l	#0,d6		*omt
	bsr	chk_num
	bpl	@f
	lea	switch_strv(pc),a1
	jsr	get_com_no-work(a6)	*文字パラメータは"OFF"のみ有効
	bmi	m_illegal_switch_value
	tst.l	d0
	bne	m_illegal_switch_value
	bra	do_wrt_chfdr	*オフ
@@:				*スピード、開始終了レベル取得
	bsr	get_spd_fdlvl	*> d6.b=omt
do_wrt_chfdr:
	moveq.l	#ch_fader_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d7,d0
	bsr	do_wrt_trk_l	*type,ch
	move.l	d6,d0
	bsr	do_wrt_trk_b	*omt
	lsr.b	#1,d6
	bcc	@f
	move.l	d5,d0
	bsr	do_wrt_trk_w	*speed(switch)
@@:
	lsr.b	#1,d6
	bcc	@f
	bsr	wrt_data_d2	*start level
@@:
	lsr.b	#1,d6
	bcc	@f
	bsr	wrt_data_d3	*end level
@@:
	bsr	skip_sep
	bra	mchfd_lp
exit_mmlchfdr:
	rts

chfdr_all_case:			*全xxxCASE
	* < d0.l=com no(0:all,1:FM-all,2:ADPCM-all,3:MIDI1-all,4:MIDI2-all,5:MIDI3-all)
	lsl.w	#2,d0
	move.l	cac_tbl(pc,d0.w),d7
	bne	mchfd00
	moveq.l	#-1,d7
	bsr	chk_num
	bmi	mchfd00		*ALLのみの指定なのでALL-DEVICE,ALL-CHとみなす
	bsr	get_num
	tst.l	d1
	bpl	@f
	neg.l	d1		*絶対値に
@@:
	subq.w	#1,d1
	cmpi.l	#15,d1
	bhi	m_illegal_channel
	move.w	d1,d7		*ALL-DEVICE,CH-xという指定
	bra	mchfd00

cac_tbl:
	dc.l	0		*dummy
	dc.l	$0000_ffff	*fm all
	dc.l	$0001_ffff	*adpcm all
	dc.l	$8000_ffff	*midi1 all
	dc.l	$8001_ffff	*midi2 all
	dc.l	$8002_ffff	*midi3 all

mml_track_fader:		*[TRACK_FADER]
	moveq.l	#0,d5		*off value
	moveq.l	#0,d6		*omt
	bsr	chk_num
	bpl	@f
	lea	switch_strv(pc),a1
	jsr	get_com_no-work(a6)	*文字パラメータは"OFF"のみ有効
	bmi	m_illegal_switch_value
	tst.l	d0
	bne	m_illegal_switch_value
	bra	do_wrt_fdr	*オフ
@@:
	moveq.l	#0,d5		*off value
	moveq.l	#0,d6		*omt
	bsr	get_spd_fdlvl	*> d6.b=omt
	moveq.l	#%111,d6
	bra	do_wrt_fdr

mml_fader_v2:			*\ cmd
	moveq.l	#0,d5		*off value
	moveq.l	#0,d6		*omt
	bsr	get_spd_fdlvl	*> d6.b=omt
	moveq.l	#%111,d6
	lsl.w	#8,d5		*v2との互換性のため
do_wrt_fdr:
	moveq.l	#ch_fader_zmd,d0
	bsr	do_wrt_trk_b
	move.l	#$7ffe_0000,d0	*track-ch
	bsr	do_wrt_trk_l	*type,ch
	move.l	d6,d0
	bsr	do_wrt_trk_b
	lsr.b	#1,d6
	bcc	@f
	move.l	d5,d0
	bsr	do_wrt_trk_w	*speed(switch)
@@:
	lsr.b	#1,d6
	bcc	@f
	bsr	wrt_data_d2	*start level
@@:
	lsr.b	#1,d6
	bcc	@f
	bsr	wrt_data_d3	*end level
@@:
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	rts

get_spd_fdlvl:
	moveq.l	#0,d5		*off value
	moveq.l	#0,d6		*omt
	bsr	chk_num
	bmi	gsf00		*数字がない時はオフ
	bset.l	#0,d6
	move.l	#128,d2		*start level default(for v2 fader param.)
	moveq.l	#0,d3		*end level default(for v2 fader param.)
	bsr	get_num
	move.l	d1,d5		*copy
	bpl	@f
	neg.l	d5		*スピードが負値の場合はデフォルトパラメータでフェードイン
	exg.l	d2,d3		*for v2 fader param.
@@:
	cmpi.l	#fader_spd_max,d5	*speed maxチェック
	bhi	m_illegal_fader_speed
gsf00:
	bsr	skip_sep
	bsr	chk_num
	bmi	@f		*パラメータがこれ以上ない場合はデフォルトでフェードアウト
	bset.l	#1,d6
	bsr	get_num		*get start level
	cmpi.l	#128,d1
	bhi	m_illegal_fader_level
	move.l	d1,d2
@@:
	bsr	skip_sep
	bsr	chk_num
	bmi	@f
	bset.l	#2,d6
	bsr	get_num		*get end level
	cmpi.l	#128,d1
	bhi	m_illegal_fader_level
	move.l	d1,d3
@@:
	rts

mml_noise:			*[NOISE]
	moveq.l	#0,d1
	bsr	chk_num
	bpl	get_@o_n
	lea	noise_strv(pc),a1
	jbsr	get_com_no	*文字パラメータは"OFF"のみ有効
	bpl	@f
	bra	m_illegal_switch_value

mml_@o:				*OPM noise設定
	moveq.l	#0,d1
	bsr	chk_num
	bmi	@f
get_@o_n:
	bsr	get_num
	cmpi.l	#31,d1
	bhi	m_illegal_noise_parameter
	tas.b	d1
@@:
	moveq.l	#reg_set_zmd,d0	*fm reg write cmd
	bsr	do_wrt_trk_b
	moveq.l	#15,d0		*noise reg no.
	bsr	do_wrt_trk_b
	bsr	wrt_data_d1
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	rts

mml_rltv_vol_dwn:			*相対ボリュームダウン
	bsr	chk_num
	bmi	rltv_vd_dflt
	bsr	get_num
	cmp.l	#127,d1
	bhi	m_illegal_volume_value
	move.b	d1,tpt_rltv_vol(a5)
	bra	@f
rltv_vd_dflt:
	moveq.l	#0,d1
	move.b	tpt_rltv_vol(a5),d1
@@:
	moveq.l	#'_',d0
	bsr	rvm			*連続設定されていた場合は最適化
	moveq.l	#rltv_vol_zmd,d0
	tst.b	velo_vol_ctrl-work(a6)	*~_記号を相対ベロシティにアサインしているか
	beq	@f
	moveq.l	#rltv_velo_zmd,d0
@@:
	bsr	do_wrt_trk_b
	move.l	d1,d0
	neg.b	d0
	bsr	do_wrt_trk_b
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	rts

mml_rltv_vol_up:			*相対ボリュームアップ
	bsr	chk_num
	bmi	rltv_vu_dflt
	bsr	get_num
	cmpi.l	#127,d1
	bhi	m_illegal_volume_value
	move.b	d1,tpt_rltv_vol(a5)
	bra	@f
rltv_vu_dflt:
	moveq.l	#0,d1
	move.b	tpt_rltv_vol(a5),d1
@@:
	moveq.l	#'~',d0
	bsr	rvm			*連続設定されていた場合は最適化
	moveq.l	#rltv_vol_zmd,d0
	tst.b	velo_vol_ctrl-work(a6)	*~_記号を相対ベロシティにアサインしているか
	beq	@f
	moveq.l	#rltv_velo_zmd,d0
@@:
	bsr	do_wrt_trk_b
	move.l	d1,d0
	bsr	do_wrt_trk_b
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	rts

rvm:
	* < d0.b='~','_'
	moveq.l	#1,d2
vdlp:
	bsr	skip_spc
	move.l	a4,d3		*save a4
	cmp.l	a4,d4
	bls	@f
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4		*skip ~ or _
	bsr	chk_num
	bpl	@f
	addq.w	#1,d2		*数値がないならば最適化対象となる
	bra	vdlp
@@:
	mulu	d2,d1
	move.l	d3,a4		*get back
	rts

mml_damper:			*[DAMPER]
	bsr	chk_num
	bpl	@f
	lea	switch_strv(pc),a1
	jbsr	get_com_no
	bmi	mml_@d
	move.l	d0,d1
	beq	do_wrt_@d
	moveq.l	#127,d1		*0か127のいずれかにする
	bra	do_wrt_@d
@@:
	bsr	get_num
	cmpi.l	#127,d1
	bhi	m_illegal_damper_value
	bra	do_wrt_@d

mml_@d:				*ダンパー
	moveq.l	#0,d1
	bsr	chk_num
	bmi	do_wrt_@d
	bsr	get_num
	cmpi.l	#127,d1
	bhi	m_illegal_damper_value
	tst.l	d1
	beq	do_wrt_@d
	moveq.l	#127,d1		*0か127かのどちらかに直す
do_wrt_@d:
	moveq.l	#damper_zmd,d0
	bsr	do_wrt_trk_b
	bsr	wrt_data_d1
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	rts

mml_track_mode:			*[TRACK_MODE]
	bsr	chk_num
	bpl	@f
	lea	track_mode_cmdln(pc),a1
	jbsr	get_com_no
	bmi	m_illegal_mode_value
	move.l	d0,d1
	bne	@f
	bra	do_wrt_@r
mml_@r:
	pea	mml_lp(pc)
@@:
	moveq.l	#0,d1
	bsr	chk_num
	bmi	do_wrt_@r
	bsr	get_num
	tst.l	d1
	beq	do_wrt_@r
@@:
	moveq.l	#ID_NO_KEYOFF,d1
do_wrt_@r:
	moveq.l	#track_mode_zmd,d0
	bsr	do_wrt_trk_b
	bra	wrt_data_d1

mml_timbre_split_switch:		*[TIMBRE_SPLIT.SWITCH]
	moveq.l	#timbre_split_zmd,d0
	bsr	do_wrt_trk_b
	bsr	chk_num
	bpl	@f
	lea	switch_strv(pc),a1	*ON/OFF
	jbsr	get_com_no
	bmi	m_illegal_switch_value
	move.l	d0,d1
	beq	1f			*OFF mark(d1=0)
	moveq.l	#$80,d1			*ON mark
	bra	1f
@@:
	bsr	get_num
	tst.l	d1
	beq	@f
	moveq.l	#$80,d1			*ON mark
1:
	move.l	d1,d0
	bra	do_wrt_trk_b		*switch value

mml_timbre_split:			*[TIMBRE_SPLIT]
	moveq.l	#timbre_split_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#$80,d1			*ON mark
	bsr	chk_num
	bpl	@f
	lea	switch_strv(pc),a1	*ON/OFF
	jbsr	get_com_no
	bmi	m_illegal_switch_value
	move.l	d0,d1
	beq	@f			*OFF mark(d1=0)
	moveq.l	#$80,d1			*ON mark
@@:
	move.l	d1,d0
	move.l	tpt_now(a5),d5		*あとでsw/n_of_paramを格納するため
	bsr	do_wrt_trk_b		*dummy
	moveq.l	#0,d3			*n of param
mtmsp_lp:
	bsr	skip_sep
	cmp.l	a4,d4
	bls	m_illegal_command_line
	cmpi.b	#']',(a4)
	beq	exit_mmltmsp

	moveq.l	#-1,d2
	bsr	chk_num			*get bank number
	bmi	m_parameter_cannot_be_omitted
	bsr	get_num
	cmpi.l	#16383,d1
	bhi	m_illegal_bank_number
	move.l	d1,d2			*ひとまず保存
	bsr	skip_spc
	cmp.l	a4,d4
	bls	@f
	cmpi.b	#':',(a4)		*バンクを:で区切って7bit:7bitで表記する場合
	bne	@f
	addq.w	#1,a4
	bsr	chk_num
	bmi	m_illegal_command_line
	bsr	get_num
	cmpi.l	#127,d1
	bhi	m_illegal_bank_number
	cmpi.l	#127,d2
	bhi	m_illegal_bank_number
	lsl.w	#8,d2
	move.b	d1,d2
	bra	1f			*@b1,b2,n
@@:					*@b,n
	add.w	d2,d2
	lsr.b	#1,d2
1:
	swap	d2
	bsr	skip_sep

	bsr	chk_num			*get timbre number
	bmi	m_parameter_cannot_be_omitted
	bsr	get_num
	subq.l	#1,d1
	cmpi.l	#fmsnd_reg_max-1,d1
	bhi	m_illegal_timbre_number
	move.w	d1,d2			*ひとまず保存

	addq.w	#1,d3
	cmpi.w	#n_of_split,d3
	bhi	m_too_many_parameters

	bsr	skip_sep
	moveq.l	#-1,d1			*get range start note number
	bsr	chk_num
	bmi	@f
	bsr	get_num
	bra	do_wrt_stntnmbr
@@:
	cmp.l	a4,d4
	bls	m_illegal_command_line
	cmpi.b	#',',(a4)
	beq	do_wrt_stntnmbr
	bsr	get_note_2way_split	*>d1.l=note number
do_wrt_stntnmbr:
	move.l	d1,d0			*set start note number
	bsr	do_wrt_trk_b
	bsr	skip_sep

	moveq.l	#-1,d1			*get range end note number
	bsr	chk_num
	bmi	@f
	bsr	get_num
	bra	do_wrt_edntnmbr
@@:
	cmp.l	a4,d4
	bls	m_illegal_command_line
	cmpi.b	#',',(a4)
	beq	do_wrt_edntnmbr
	bsr	get_note_2way_split	*>d1.l=note number
do_wrt_edntnmbr:
	move.l	d1,d0			*set end note number
	bsr	do_wrt_trk_b
	move.l	d2,d0			*set bank number & timbre number
	bsr	do_wrt_trk_l
	bra	mtmsp_lp
exit_mmltmsp:
	move.l	tpt_addr(a5),a1
	or.b	d3,(a1,d5.l)		*sw/n_of_paramをセット
	rts

get_note_2way_split:			*音階指定
	* > d1.l=note number
	movem.l	d0/d2,-(sp)
@@:
	cmp.l	a4,d4
	bls	m_parameter_shortage
	move.b	(a4),d0
	jsr	mk_capital-work(a6)
	cmpi.b	#'.',d0		*skip '.'
	beq	@b
	cmpi.b	#'O',d0		*音階、オクターブの順の指定か
	bne	@f
	addq.w	#1,a4		*skip 'o'
	bsr	chk_num
	bmi	m_illegal_octave
	bsr	get_num		*d1=octave num
	cmp.l	a4,d4
	bls	m_parameter_shortage
	moveq.l	#0,d2		*dummy bank
	bsr	get_note_num	*<d1=oct,d2=bank*128
	bmi	m_illegal_note_number
	cmp.l	#adpcm_reg_max,d2
	bcc	m_illegal_note_number
	move.l	d2,d1
	movem.l	(sp)+,d0/d2
	rts
@@:				*RCP系の音階指定(ex.C#4)
	cmpi.b	#'A',d0
	bcs	m_unexpected_operand
	cmpi.b	#'G',d0
	bhi	m_unexpected_operand
	moveq.l	#-1,d1		*dummy octave=-1
	moveq.l	#0,d2		*dummy bank
	bsr	get_note_num2	*< d1.l=dummy,d2=bank*128
	bmi	m_illegal_note_number
	bsr	chk_num
	bmi	m_illegal_note_number
	bsr	get_num		*get octave
	cmp.l	a4,d4
	bls	m_parameter_shortage
	addq.w	#1,d1		*-1～9→0-10
	mulu	#12,d1
	add.w	d1,d2
	cmpi.l	#adpcm_reg_max,d2
	bcc	m_illegal_note_number
	move.l	d2,d1
	movem.l	(sp)+,d0/d2
	rts

mml_bend_range:			*[BEND_RANGE n]
mml_@g:				*ベンドレンジチェンジ
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
	bsr	get_num
	cmpi.l	#127,d1
	bhi	m_illegal_bend_range
	moveq.l	#bend_range_zmd,d0
	bsr	do_wrt_trk_b
	bsr	wrt_data_d1
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	rts

mml_program_bank:		*[PROGRAM_BANK]
mml_i:				*音色バンク切り換え
	moveq.l	#0,d2
	moveq.l	#0,d3
	bsr	chk_num
	bmi	@f
	bsr	get_num
	cmpi.l	#127,d1
	bhi	mk_bank_i	*127以上は2バイトへ
	move.l	d1,d2
@@:
	bsr	skip_sep
	bsr	chk_num
	bmi	do_wrt_i	*第２パラメータがない
	bsr	get_num
	cmpi.l	#127,d1
	bhi	@f		*too big
	move.l	d1,d3
	bra	do_wrt_i
mk_bank_i:			*2バイト目を作る
	move.l	d2,d3
	moveq.l	#127,d0
	and.b	d0,d3
	lsr.w	#7,d2
	and.b	d0,d2
	bsr	skip_sep
	bsr	chk_num
	bpl	m_too_many_parameters
do_wrt_i:
	moveq.l	#bank_select_zmd,d0
	bsr	do_wrt_trk_b
	bsr	wrt_data_d2	*H
	bsr	wrt_data_d3	*L
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	rts

mml_replay:				*[REPLAY]
mml_j:					*強制再演奏
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
	bsr	get_num
	subq.l	#1,d1
	cmpi.l	#tr_max-1,d1
	bhi	m_illegal_track_number
	bsr	check_trk_no
	moveq.l	#forceplay_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d1,d0
	bsr	reg_trkn		*トラック番号セット
	bsr	do_wrt_trk_w
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	rts

check_trk_no:			*トラック番号nが有効かチェック
	* < d1.l=trk number(0～)
	* - all
reglist	reg	d0-d2/a1
	movem.l	reglist,-(sp)
	move.l	trk_inf_tbl(pc),a1
	move.l	tit_size(pc),d2
	add.l	a1,d2
@@:
	cmp.w	(a1)+,d1
	beq	@f
	move.l	(a1)+,d0
	beq	m_undefined_track_referred
	add.l	d0,a1
	cmp.l	d2,a1
	bhi	m_undefined_track_referred
	bra	@b
@@:
	movem.l	(sp)+,reglist
	rts

mml_direct_zmd:					*; コマンド
	btst.b	#c_renp1,tpt_mode_flg(a5)	*連符内には使用出来ない
	bne	m_illegal_command_in_brace
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted	*値が一個もない時はｴﾗｰ
	bsr	m_zmd_directly_embedded
@@:
	bsr	get_num
	cmpi.l	#255,d1
	bhi	m_undefined_zmd_code
	move.l	d1,d0
	bsr	do_wrt_trk_b
	bsr	skip_sep
	bsr	chk_num
	bpl	@b
	bra	mml_lp

mml_dummy:					*[DUMMY]
	moveq.l	#next_cmd_zmd,d0
	bra	do_wrt_trk_b

mml_poke:					*? コマンド
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted	*値が一個もない時はｴﾗｰ
	bsr	get_num				*get addr
	move.l	d1,d2
	bsr	skip_sep			*skip ','
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted	*値がない時はｴﾗｰ
	move.b	(a4),d0
	moveq.l	#poke_zmd,d3			*zmd cmd
	cmpi.b	#'-',d0
	beq	@f
	cmpi.b	#'+',d0
	bne	do_get_data
@@:
	moveq.l	#rltv_poke_zmd,d3
do_get_data:
	bsr	get_num				*get data

	move.l	d3,d0
	bsr	do_wrt_trk_b
	cmpi.l	#255,d2
	bhi	@f
	moveq.l	#$00,d3			*mode
	lea	do_wrt_trk_b(pc),a1
	bra	get_poke_data
@@:
	cmpi.l	#65535,d2
	bhi	@f
	moveq.l	#$10,d3			*mode
	lea	do_wrt_trk_w(pc),a1
	bra	get_poke_data
@@:
	moveq.l	#$30,d3			*mode
	lea	do_wrt_trk_l(pc),a1
get_poke_data:
	cmpi.l	#255,d1
	bhi	@f
	lea	do_wrt_trk_b(pc),a2
	bra	do_wrt_poke
@@:
	cmpi.l	#65535,d1
	bhi	@f
	ori.b	#1,d3			*mode
	lea	do_wrt_trk_w(pc),a2
	bra	do_wrt_poke
@@:
	ori.b	#3,d3			*mode
	lea	do_wrt_trk_l(pc),a2
do_wrt_poke:
	move.l	d3,d0
	bsr	do_wrt_trk_b		*mode
	move.l	d2,d0
	jsr	(a1)			*addr
	move.l	d1,d0
	jsr	(a1)			*data
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	rts

mml_synchronize:		*[SYNCHRONIZE n]
mml_w:				*同期コマンド
	tas.b	compile_status-work(a6)	*MML Wを使用したことをマーク
	bsr	chk_num
	bmi	@f		*同期街コマンドとみなす
	bsr	get_num
	subq.l	#1,d1
	cmpi.l	#tr_max-1,d1
	bhi	m_illegal_track_number
	bsr	check_trk_no
	moveq.l	#send_sync_zmd,d0
	bsr	do_wrt_trk_b
	move.l	d1,d0
	bsr	reg_trkn		*トラック番号セット
	bsr	do_wrt_trk_w
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	rts
@@:
	moveq.l	#waiting_zmd,d0
	bsr	do_wrt_trk_b
	tst.b	seq_cmd-work(a6)
	beq	mml_lp
	rts

reg_trkn_ctrl:				*トラック番号再割り振り用情報登録(CTRL)
	* < d0.l=dest. trk n
reglist	reg	d0/d2/a0-a1
	movem.l	reglist,-(sp)
	move.l	trkn_now(pc),a1
	add.l	trkn_addr(pc),a1
	move.l	#1,(a1)+		*offset type 1=ctrl_addr
	move.l	ctrl_now(pc),(a1)+	*ctrl
	clr.l	(a1)+			*dummy
	move.l	d0,(a1)+		*set trk n
	bra	@f

reg_trkn:				*トラック番号再割り振り用情報登録(MML)
	* < d0.l=dest. trk n
	* < tpt_now(a5)
	movem.l	reglist,-(sp)
	move.l	trkn_now(pc),a1
	add.l	trkn_addr(pc),a1
	clr.l	(a1)+			*offset type 0=tpt_now
	move.l	tpt_now(a5),(a1)+	*set offset addr.
	move.l	a5,d2
	sub.l	trk_ptr_tbl-work(a6),d2
	move.l	d2,(a1)+		*set trk n's tpt offset addr.
	move.l	d0,(a1)+		*set trk n
@@:
	cmp.l	trkn_end(pc),a1
	bcs	@f			*no error
	move.l	trkn_addr(pc),a1
	move.l	trkn_size(pc),d2
	add.l	#ta_size*100,d2		*new size
	bsr	enlarge_mem
	tst.l	d0
	bmi	m_out_of_memory
	move.l	d2,trkn_size-work(a6)
	move.l	a0,trkn_addr-work(a6)
	add.l	a0,d2
	move.l	d2,trkn_end-work(a6)
@@:
	add.l	#ta_size,trkn_now-work(a6)
	movem.l	(sp)+,reglist
	rts

calc_gt_chd:			*ゲートタイムの計算
	move.b	v2_compatch-work(a6),-(sp)
	clr.b	v2_compatch-work(a6)
	bsr	calc_gt
	move.b	(sp)+,v2_compatch-work(a6)
	rts

calc_gt:			*ゲートタイムの計算
	* < d0.w=step time
	* > d0.w=gate time
	* - all
reglist	reg	d1-d3
	tst.w	d0
	beq	bye_calc_gt
	movem.l	reglist,-(sp)
	move.l	d0,d3		*backup
	move.w	tpt_gate_time(a5),d1
	bpl	case_normal_q
				*case:@Q
	neg.w	d1
	btst.b	#c_q_sgn,tpt_mode_flg(a5)
	beq	@f
	add.w	d1,d0		*@Q-nの場合
	bcs	2f
	cmpi.w	#32767,d0
	bhi	2f
	bra	exit_cg
@@:				*@Q+nの場合
	btst.b	#c_@q,tpt_mode_flg(a5)
	bne	1f
	cmp.w	d0,d1
	bcc	exit_cg		*ゲートタイムが負 or 0になる時は計算しない
	sub.w	d1,d0
	bra	exit_cg
1:				*ゲートタイム固定値ケース
	tst.b	v2_compatch-work(a6)
	bne	do_fxgt
	tst.b	fxgt_mode-work(a6)
	beq	@f		*fixed gatetimeの動作モードチェック
do_fxgt:
	cmp.w	d1,d3
	bcc	@f
	move.w	d3,d0		*gt>=stのときgt=stにしてしまう
	bra	exit_cg
@@:
	move.w	d1,d0
	bra	exit_cg
case_normal_q:			*Qケース
	move.l	d0,d2
	mulu	d1,d0
	move.b	gate_shift(pc),d1
	btst.b	#c_q_sgn,tpt_mode_flg(a5)
	beq	@f
	lsr.l	d1,d0		*/gate range
	add.w	d2,d0
	bcs	2f
	cmpi.w	#32767,d0
	bhi	2f
	bra	exit_cg
2:
	move.w	#32767,d0
	bra	exit_cg
@@:
	lsr.l	d1,d0		*/gate range
	bne	exit_cg
	moveq.l	#1,d0		*0の場合は最小値１にしておく
exit_cg:
	movem.l	(sp)+,reglist
bye_calc_gt:
	rts

chk_oncho:			*音長があるかないか
	* < (a4)=data
	* > minus=not oncho
	* > eq=suji
	* X d0
	move.w	d0,-(sp)
	bsr	skip_spc
	cmp.l	a4,d4
	bls	not_oncho
	move.b	(a4),d0
	cmpi.b	#'0',d0
	bcs	chk_o0
	cmpi.b	#'9',d0
	bls	yes_oncho
chk_o0:
	cmpi.b	#'$',d0		*16進数指定
	beq	yes_oncho
not_oncho:
	move.w	(sp)+,d0
	move.w	#CCR_NEGA,ccr
	rts
yes_oncho:
	move.w	(sp)+,d0
	move.w	#CCR_ZERO,ccr
	rts

consider_trkfrq_gt:
	* < d0.w=step time
	* > d0.w=calclated step time
	cmpi.w	#TIE_GATE,d0
	beq	exit_csrtrfr
consider_trkfrq_st:
	* < d0.w=step time
	* > d0.w=calclated step time
	andi.l	#$ffff,d0		*もともとゼロは計算しない
	beq	exit_csrtrfr
	move.w	d1,-(sp)
	move.w	tpt_trkfrq(a5),d1
	beq	1f
	addq.w	#1,d1
	divu	d1,d0
	beq	m_error_in_division	*商が０はエラー
	swap	d0
	tst.w	d0
	beq	@f
	bsr	m_surplus_in_division	*余りが発生している
@@:
	swap	d0
1:
	move.w	(sp)+,d1
exit_csrtrfr:
	rts

wave_form:				*.WAVE_FORM(波形メモリ設定登録)
*	bsr	check_relation_cmn	*コマンド関係チェック
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
	moveq.l	#CMN_WAVE_FORM,d0
	bsr	do_wrt_cmn_b		*cmd code
	bsr	get_num			*get wave number
	cmpi.l	#wv_reg_max+8,d1
	bcc	m_illegal_wave_number	*32767より上はダメ
	cmpi.l	#8,d1
	bcs	m_illegal_wave_number	*7以下はプリセット波形
	move.l	d1,d0
	bsr	do_wrt_cmn_w		*set wave number
	moveq.l	#0,d0			*dummy
	bsr	do_wrt_cmn_l		*size.l
	bsr	do_wrt_cmn_b		*type.b
	bsr	do_wrt_cmn_l		*start.l
	bsr	do_wrt_cmn_l		*end.l
	bsr	do_wrt_cmn_l		*time.l
	bsr	do_wrt_cmn_l		*reserved
	bsr	chk_membdr_cmn		*一応、最低必要分メモリは確保
	move.l	zmd_now-work(a6),a0
	lea	-(4+1+4+4+4+4)(a0),a2	*a2=データ長格納先オフセットアドレス
	lea	-(0+1+4+4+4+4)(a0),a1
	add.l	zmd_addr-work(a6),a1	*a1=loop type格納アドレス

	bsr	skip_sep
	bsr	skip_spc
	moveq.l	#0,d1
	cmp.l	a4,d4
	bls	@f
	move.b	(a4),d0
	cmpi.b	#'1',d0
	bne	@f
	move.b	1(a4),d0
	bsr	mk_capital
	cmpi.b	#'S',d0
	beq	getlpnmstr
@@:
	bsr	chk_num
	bmi	getlpnmstr		*loop type省略
	bsr	get_num			*get loop type
	cmpi.l	#2,d1
	bhi	m_undefined_loop_type
	bra	1f
getlpnmstr:
	pea	(a1)
	lea	wvfm_name-work(a6),a1
	bsr	get_com_no
	move.l	(sp)+,a1
	bmi	1f
	move.l	d0,d1
1:
	move.b	d1,(a1)+

	clr.b	wave_param_flg-work(a6)	*パラメータ省略フラグ初期化
	bsr	skip_sep
	moveq.l	#0,d1
	bsr	chk_num
	bmi	@f			*loop start point 省略
	bsr	get_num			*get loop start point
	add.l	d1,d1
@@:
	move.l	d1,d2			*後で適合性検査で使用
	rept	4
	rol.l	#8,d1
	move.b	d1,(a1)+
	endm

	bsr	skip_sep
	moveq.l	#0,d1
	bsr	chk_num
	bmi	@f			*loop end point 省略
	bsr	get_num			*get loop end point
	addq.l	#1,d1			*次をポイントするようにする
	add.l	d1,d1
	st	wave_param_flg-work(a6)
	cmp.l	d2,d1
	bcs	m_illegal_loop_end_point
@@:
	rept	4
	rol.l	#8,d1
	move.b	d1,(a1)+
	endm

	bsr	skip_sep
	moveq.l	#0,d1
	bsr	chk_num
	bmi	@f			*loop time 省略
	bsr	get_num			*get loop time
@@:
	rept	4
	rol.l	#8,d1
	move.b	d1,(a1)+
	endm

	rept	4			*reserved area
	clr.b	(a1)+
	endm

	jbsr	get_mdtr_str		*文字列取得、書き込み

	move.l	a0,d0
	andi.b	#1,d0
	beq	@f
	moveq.l	#0,d0
	bsr	do_wrt_cmn_b		*.evenに相当
@@:
	moveq.l	#0,d3			*data len
wvst_lp:
	bsr	skip_sep
	cmp.l	a4,d4
	bls	m_parameter_break_off	*パラメータが不足している
	bsr	chk_num
	bmi	exit_wvst		*データもう無し
	bsr	get_num
	move.l	d1,d0
	bpl	@f
	neg.l	d1
@@:
	cmpi.l	#$ffff,d1		*波形の振幅が16ビット範囲を超えていたらエラー
	bhi	m_illegal_wave_value
	bsr	do_wrt_cmn_w
	addq.l	#2,d3			*inc data len
	bra	wvst_lp
exit_wvst:
	tst.l	d3
	beq	m_parameter_shortage
	add.l	zmd_addr(pc),a2
	rept	4
	rol.l	#8,d3
	move.b	d3,(a2)+		*データ長を格納
	endm
	moveq.l	#0,d0			*default
	tst.b	wave_param_flg-work(a6)	*ループ終端省略されていたか
	bne	@f
	addq.w	#1,a2			*skip loop type
	rept	3
	move.b	(a2)+,d0
	lsl.l	#8,d0			*ループ開始オフセットを取得(後続の適合性検査で使用)
	endm
	move.b	(a2)+,d0
	rept	4
	rol.l	#8,d3
	move.b	d3,(a2)+		*ループ終端を設定
	endm
@@:
	cmp.l	d3,d0
	bcc	m_illegal_loop_start_point
	move.l	zmd_addr(pc),a1
	move.l	z_cmn_flag(a1),d0
	bset.l	#CMN_WAVE_FORM/4,d0
	move.l	d0,z_cmn_flag(a1)
	jmp	find_end

sc55_id_set:
	moveq.l	#ID_set_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#$41,d0
	bsr	do_wrt_trk_b
	move.l	d2,d0			*device ID
	bsr	do_wrt_trk_b
	moveq.l	#$45,d0			*SC55
	bra	do_wrt_trk_b

gs_id_set:
	moveq.l	#ID_set_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#$41,d0
	bsr	do_wrt_trk_b
	move.l	d2,d0			*device ID
	bsr	do_wrt_trk_b
	moveq.l	#$42,d0			*GS
	bra	do_wrt_trk_b

mt32_id_set:
	moveq.l	#ID_set_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#$41,d0
	bsr	do_wrt_trk_b
	move.l	d2,d0			*device ID
	bsr	do_wrt_trk_b
	moveq.l	#$16,d0			*MT32
	bra	do_wrt_trk_b

u220_id_set:
	moveq.l	#ID_set_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#$41,d0
	bsr	do_wrt_trk_b
	move.l	d2,d0			*device ID
	bsr	do_wrt_trk_b
	moveq.l	#$2b,d0			*U220
	bra	do_wrt_trk_b

mml_gs_reset:				*[GS_RESET]
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*>d2=DEV ID
	bsr	gs_id_set
	moveq.l	#exclusive_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#MKID_ROLAND,d0
	bsr	do_wrt_trk_b
	moveq.l	#8,d1
	lea	sct_gs_reset(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment
	moveq.l	#4,d0
	bsr	do_wrt_trk_l		*データ長
	move.l	#$40007f_00,d0
	bra	do_wrt_trk_l		*転送データ

gs_reset:				*.GS_RESET(.SC55_INIT)
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*d1=I/F number,d2=DEV ID
	move.l	d1,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#8,d1
	lea	sct_gs_reset(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment
	moveq.l	#11,d0
	bsr	do_wrt_cmn_l		*データ長
	lea	header(pc),a1		*送信パック作成
	move.b	d2,2(a1)
	move.b	#$42,3(a1)
	move.b	#$40,5(a1)
	move.l	#$007f0041,6(a1)
	moveq.l	#11-1,d1
@@:					*データ本体の書き込み
	move.b	(a1)+,d0
	bsr	do_wrt_cmn_b
	dbra	d1,@b
	jmp	cmpl_lp

get_bk_pg_devid_ifn:	*バンク番号、音色番号とデバイスIDとインターフェース番号の取得
	* > d1.b-I/F number(0-2,-1)
	* > d2.b=DEVICE ID(0-127)
	* > d3.hw=bank number(0,1)
	* > d3.lw=pgm number(0-127)
	* - all
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted	*マップナンバーの省略はできない
	bsr	get_num
	cmpi.l	#1,d1
	bhi	m_illegal_map_number
	move.l	d1,d3
	swap	d3

	bsr	skip_sep

	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted	*パートナンバーの省略はできない
	bsr	get_num				*1-128
	subq.l	#1,d1
	cmpi.l	#127,d1
	bhi	m_illegal_note_number
	move.w	d1,d3
	bsr	skip_sep
	moveq.l	#$10,d1			*omitted case value
	bra	get_devid_ifn

get_mp_ky_devid_ifn:	*マップ番号、キー番号とデバイスIDとインターフェース番号の取得
	* > d1.b-I/F number(0-2,-1)
	* > d2.b=DEVICE ID(0-127)
	* > d3.hw=map number(0,1)
	* > d3.lw=key number(0-127)
	* - all
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted	*マップナンバーの省略はできない
	bsr	get_num
	cmpi.l	#1,d1
	bhi	m_illegal_map_number
	move.l	d1,d3
	swap	d3

	bsr	skip_sep

	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted	*パートナンバーの省略はできない
	bsr	get_num
	cmpi.l	#127,d1
	bhi	m_illegal_note_number
	move.w	d1,d3
	bsr	skip_sep
	moveq.l	#$10,d1			*omitted case value
	bra	get_devid_ifn

get_tm_pt_devid_ifn:	*ティンバー番号、パーシャル番号とデバイスIDとインターフェース番号の取得
	* > d1.b-I/F number(0-2,-1)
	* > d2.b=DEVICE ID(0-127)
	* > d3.hw=timbre number(0-63)
	* > d3.lw=key number(0-3)
	* - all
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted	*マップナンバーの省略はできない
	bsr	get_num
	subq.l	#1,d1
	cmpi.l	#63,d1
	bhi	m_illegal_timbre_number
	move.l	d1,d3
	swap	d3

	bsr	skip_sep

	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted	*パートナンバーの省略はできない
	bsr	get_num
	subq.l	#1,d1
	cmpi.l	#3,d1
	bhi	m_illegal_partial_number
	move.w	d1,d3
	bsr	skip_sep
	moveq.l	#$10,d1			*omitted case value
	bra	get_devid_ifn

get_tm_devid_ifn:		*ティンバー番号とデバイスIDとインターフェース番号の取得
	* > d1.b=I/F number(0-2,-1)
	* > d2.b=DEVICE ID(0-127)
	* > d3.b=timbre number(0-63)
	* - all
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted	*パートナンバーの省略はできない
	bsr	get_num
	subq.l	#1,d1
	cmpi.l	#63,d1
	bhi	m_illegal_timbre_number
	move.w	d1,d3

	bsr	skip_sep
	moveq.l	#$10,d1			*omitted case value
	bra	get_devid_ifn

get_map_devid_ifn:		*マップ番号とデバイスIDとインターフェース番号の取得
	* > d1.b=I/F number(0-2,-1)
	* > d2.b=DEVICE ID(0-127)
	* > d3.b=map number(-128～127)
	* - all
	bsr	chk_num
	bpl	@f
	lea	sc88_drmmap_strv-work(a6),a1
	bsr	get_com_no
	bmi	m_illegal_map_number
	tas.b	d0
	move.w	d0,d3
	bra	1f
@@:
	bsr	get_num
	cmpi.l	#1,d1
	bhi	m_illegal_map_number
	move.w	d1,d3			*map number=0,1
1:
	bsr	skip_sep
	moveq.l	#$10,d1			*omitted case value
	bra	get_devid_ifn

get_ptch_devid_ifn:			*パッチ番号とデバイスIDとインターフェース番号の取得
	* > d1.b=I/F number(0-2,-1)
	* > d2.b=DEVICE ID(0-127)
	* > d3.b=timbre number(0-127)
	* - all
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted	*パートナンバーの省略はできない
	bsr	get_num
	subq.l	#1,d1
	cmpi.l	#127,d1
	bhi	m_illegal_patch_number
	move.w	d1,d3

	bsr	skip_sep
	moveq.l	#$10,d1			*omitted case value
	bra	get_devid_ifn

get_tmb_devid_ifn:			*TIMBRE番号とデバイスIDとインターフェース番号の取得
	* > d1.b=I/F number(0-2,-1)
	* > d2.b=DEVICE ID(0-127)
	* > d3.b=timbre number(0-127)
	* - all
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted	*パートナンバーの省略はできない
	bsr	get_num
	subq.l	#1,d1
	cmpi.l	#127,d1
	bhi	m_illegal_timbre_number
	move.w	d1,d3

	bsr	skip_sep
	moveq.l	#$10,d1			*omitted case value
	bra	get_devid_ifn

get_ky_devid_ifn:			*キー番号とデバイスIDとインターフェース番号の取得
	* > d1.b=I/F number(0-2,-1)
	* > d2.b=DEVICE ID(0-127)
	* > d3.b=key(0-127)
	* - all
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted	*パートナンバーの省略はできない
	bsr	get_num
	cmpi.l	#87,d1
	bhi	m_illegal_note_number
	sub.l	#24,d1
	bmi	m_illegal_note_number
	move.w	d1,d3

	bsr	skip_sep
	moveq.l	#$10,d1			*omitted case value
	bra	get_devid_ifn

get_nt_devid_ifn:		*ノート番号とデバイスIDとインターフェース番号の取得
	* > d1.b=I/F number(0-2,-1)
	* > d2.b=DEVICE ID(0-127)
	* > d3.b=note(0-127)
	* - all
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted	*パートナンバーの省略はできない
	bsr	get_num
	cmpi.l	#99,d1
	bhi	m_illegal_note_number
	cmpi.l	#35,d1
	bcs	m_illegal_note_number
	move.w	d1,d3

	bsr	skip_sep
	moveq.l	#$10,d1			*omitted case value
	bra	get_devid_ifn

get_mode_devid_ifn:			*モード値、デバイスIDとインターフェース番号の取得
	* > d1.b=I/F number(0-2,-1)
	* > d2.b=DEVICE ID(0-127)
	* > d3.b=mode(0,1)
	* - all
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted	*モード番号の省略はできない
	bsr	get_num
	subq.l	#1,d1
	cmpi.l	#1,d1
	bhi	m_illegal_mode_value
	move.w	d1,d3

	bsr	skip_sep
	moveq.l	#$10,d1			*omitted case value
	bra	get_devid_ifn

get_pt_devid_ifn:			*パート番号とデバイスIDとインターフェース番号の取得
	* > d1.b=I/F number(0-2,-1)
	* > d2.b=DEVICE ID(0-127)
	* > d3.b=part number(0-5)
	* - all
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted	*パートナンバーの省略はできない
	bsr	get_num
	subq.l	#1,d1
	cmpi.l	#5,d1
	bhi	m_illegal_part_number
	move.w	d1,d3

	bsr	skip_sep
	moveq.l	#$10,d1			*omitted case value
	bra	get_devid_ifn

get_prt_devid_ifn:			*パート番号とデバイスIDとインターフェース番号の取得
	* > d1.b=I/F number(0-2,-1)
	* > d2.b=DEVICE ID(0-127)
	* > d3.b=part number(1-16)
	* - all
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted	*パートナンバーの省略はできない
	bsr	get_num
	tst.l	d1
	beq	m_illegal_part_number
	cmpi.l	#16,d1
	bhi	m_illegal_part_number
	move.w	d1,d3

	bsr	skip_sep
	moveq.l	#$10,d1			*omitted case value
get_devid_ifn:				*デバイスIDとインターフェース番号の取得
	* < d1.l=default device ID
	* > d1.b-I/F number(0-2,-1)
	* > d2.b=DEVICE ID(0-127)
	* - all
	bsr	chk_num
	bmi	@f
	bsr	get_num
	cmpi.l	#127,d1
	bhi	m_illegal_device_id	*デバイスIDが異常です
@@:
	move.l	d1,d2
	bsr	skip_sep
get_ifn:
	* > d1.b-I/F number(0-2,-1)
	tst.b	now_cmd-work(a6)	*MML系コマンドにはインターフェース番号は無関係
	bpl	@f
	moveq.l	#-1,d1			*current midi out
	bsr	chk_num
	bmi	@f
	bsr	get_num
	subq.l	#1,d1				*0-2
	cmpi.l	#if_max-1,d1
	bhi	m_illegal_interface_number
@@:
	rts

wrt_comment:
	* < d1.l=len of comment
	* < a1.l=コメント内容
	* < a2.l=書き込みルーチンエントリアドレス
	* X d0-d1/a1
	tst.b	auto_comment-work(a6)	*自動コメント生成モードか
	beq	gsrst_nocmt
	move.l	d1,d0
	jsr	(a2)		*write str len
	subq.w	#1,d1
	bcs	exit_wrtcmt
@@:
	move.b	(a1)+,d0
	jsr	(a2)		*文字列'GS_RESET'を書き込む
	dbra	d1,@b
exit_wrtcmt:
	rts
gsrst_nocmt:
	moveq.l	#0,d0		*コメントなしならばコメント長=0を
	jmp	(a2)		*設定して帰還

mml_gs_partial_reserve:				*[GS_PARTIAL_RESERVE]
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*>d2=DEV ID
	bsr	gs_id_set
	moveq.l	#exclusive_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#MKID_ROLAND,d0
	bsr	do_wrt_trk_b
	moveq.l	#18,d1
	lea	sct_gs_v_rsv(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_gsptlrsv		*送信パケット生成
	moveq.l	#3+16,d0
	bsr	do_wrt_trk_l		*データ長
	move.l	temp_buffer(pc),a1
	addq.w	#5,a1
	moveq.l	#3+16-1,d1
@@:
	move.b	(a1)+,d0
	bsr	do_wrt_trk_b
	dbra	d1,@b
	rts

gs_partial_reserve:				*.GS_PARTIAL_RESERVE,.SC55_V_RESERVE(SC55ボイスリザーブ)
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*d1=I/F number,d2=DEV ID
	move.l	d1,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#18,d1
	lea	sct_gs_v_rsv(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_gsptlrsv		*送信パケット生成
	move.l	#8+16+2,d0
	bsr	do_wrt_cmn_l		*データ長
	move.l	temp_buffer(pc),a1
	moveq.l	#8+16+2-1,d1
@@:
	move.b	(a1)+,d0
	bsr	do_wrt_cmn_b
	dbra	d1,@b
	jmp	cmpl_lp

do_gsptlrsv:				*GSパーシャルリザーブパラメータ取得&MIDIメッセージ作成
	* < d2=DEV ID
	* > temp_buffer
	* x d0-d3/a1-a2
	move.l	temp_buffer(pc),a2
	move.w	#$f041,(a2)+
	move.b	d2,(a2)+		*set dev ID
	move.b	#$42,(a2)+		*set model id
	move.l	#$12_400110,(a2)+	*cmd,addr
	moveq.l	#16,d1
	suba.l	a1,a1
	bsr	get_arry_params		*{...}で囲まれた数値の取得 (< d1 n of data/> d1=n of data)
	subq.l	#1,d1
	cmpi.l	#15,d1
	bne	m_illegal_parameter_format	*パラメータは必ず16個
	move.l	arry_stock(pc),a1
	move.b	9(a1),d3
	move.b	d3,(a2)+		*copy part 10
	add.b	#$40+$01+$10,d3
	moveq.l	#9-1,d1
@@:
	move.b	(a1)+,d0
	add.b	d0,d3
	move.b	d0,(a2)+	*copy part 1 to 9
	dbra	d1,@b
	addq.w	#1,a1		*skip part 10
	moveq.l	#6-1,d1
@@:
	move.b	(a1)+,d0
	add.b	d0,d3
	move.b	d0,(a2)+	*copy part 11 to 16
	dbra	d1,@b
	bra	calcset_exsm

get_arry_params:				*データ列認識
	* < d1.l=required n of data(この個数よりも少なかった場合は０で埋める/多かったらエラー)
	* < a1.l=limit value table
	* > arry_stock
	* > d1.l=usable n of data
	movem.l	d2-d3/d5-d6/a1-a2,-(sp)
	moveq.l	#0,d5				*default min
	moveq.l	#127,d6				*default max
	move.l	d1,d2
	move.l	arry_stock(pc),a2
	bsr	chk_num
	bpl	@f
	bsr	skip_eq
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	cmpi.b	#'{',(a4)+
	seq	d3				*終端マーク
	bne	m_parameter_cannot_be_omitted
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
gtarprm_lp:
	moveq.l	#0,d1				*省略時の値
	bsr	chk_num
	bpl	@f
	cmp.l	a4,d4
	bls	exit_gtarprm_lp
	cmpi.b	#',',(a4)		*','の場合は値省略とする
	beq	gtarprm_nmldt
	bra	exit_gtarprm_lp		*','以外のものがあるという事はもう数値は
@@:					*続かないという事
	bsr	get_num
	move.l	a1,d0
	beq	1f				*no check
	cmpi.b	#-1,(a1)			*min check
	beq	@f
	move.b	(a1)+,d5
@@:
	cmp.l	d5,d1
	bcs	m_illegal_parameter_value
1:
	move.l	a1,d0
	beq	1f				*no check
	cmpi.b	#-1,(a1)			*max check
	beq	@f
	move.b	(a1)+,d6
@@:
	cmp.l	d6,d1
	bhi	m_illegal_parameter_value
	bsr	skip_sep
1:
gtarprm_nmldt:
	bsr	skip_sep
	subq.l	#1,d2
	bcs	m_too_many_parameters		*パラメータが指定個数以上あってはならない
	move.b	d1,(a2)+
	bra	gtarprm_lp
exit_gtarprm_lp:
	move.l	a2,d1
	sub.l	arry_stock(pc),d1		*実質パラメータ個数
	tst.l	d2
	beq	exit_gtarprm
@@:						*足りないパラメータは0で埋める
	clr.b	(a2)+
	subq.l	#1,d2
	bne	@b
exit_gtarprm:
	tst.b	d3				*終端括弧いらないケース=0
	beq	@f
	cmpi.b	#'}',(a4)+
	bne	m_illegal_command_line		*終端記号が無い
@@:
	movem.l	(sp)+,d2-d3/d5-d6/a1-a2
	rts

mml_gs_reverb:				*[GS_REVERB]([SC55_REVERB])
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*>d2=DEV ID
	bsr	gs_id_set
	moveq.l	#exclusive_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#MKID_ROLAND,d0
	bsr	do_wrt_trk_b
	moveq.l	#9,d1
	lea	sct_gs_reverb(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_gsrvb		*送信パケット生成 > d1.l=packet length
set_rdexml:
	subq.w	#7,d1			*header:5,tail:1,Without Checksum:1
	bcs	m_parameter_cannot_be_omitted	*パラメータは最低１個
	move.l	d1,d0
	bsr	do_wrt_trk_l		*データ長
	move.l	temp_buffer(pc),a1
	addq.w	#5,a1
	subq.w	#1,d1			*for dbra
	bcs	m_parameter_cannot_be_omitted	*パラメータは最低１個
@@:
	move.b	(a1)+,d0
	bsr	do_wrt_trk_b
	dbra	d1,@b
	rts

gs_reverb:				*.GS_REVERB(SC55_REVERB)
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*d1=I/F number,d2=DEV ID
	move.l	d1,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#9,d1
	lea	sct_gs_reverb(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_gsrvb		*送信パケット生成 > d1.l=packet length
set_rdexshp:
	move.l	d1,d0
	bsr	do_wrt_cmn_l		*データ長
	move.l	temp_buffer(pc),a1
	subq.w	#1,d1			*for dbra
	bcs	m_parameter_cannot_be_omitted	*パラメータは最低１個
@@:
	move.b	(a1)+,d0
	bsr	do_wrt_cmn_b
	dbra	d1,@b
	jmp	cmpl_lp

do_gsrvb:				*GSリバーブパラメータ取得&MIDIメッセージ作成
	* < d2=DEV ID
	* > temp_buffer
	* > d1=packet length(1～)
	* x d0-d3/a1-a2
	move.l	temp_buffer(pc),a2
	move.w	#$f041,(a2)+
	move.b	d2,(a2)+		*set dev ID
	move.b	#$42,(a2)+		*set model id
	move.l	#$12_400130,(a2)+	*cmd,addr
	moveq.l	#7,d1
	lea	gsrvb_lmit(pc),a1
	bsr	get_arry_params		*{}で囲まれた数値の取得(< d1 n of data/> d1=n of data)
	subq.l	#1,d1
	bcs	m_parameter_cannot_be_omitted	*パラメータは最低１個
	moveq.l	#$40+$01+$30,d3
	bra	set_arry_data

gsrvb_lmit:	dc.b	0,7,0,7,0,7,0,127,-1
	.even

mml_sc88_reverb:			*[SC88_REVERB]
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*>d2=DEV ID
	bsr	gs_id_set
	moveq.l	#exclusive_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#MKID_ROLAND,d0
	bsr	do_wrt_trk_b
	moveq.l	#11,d1
	lea	sct_sc88_reverb(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_sc88rvb		*送信パケット生成 > d1.l=packet length
	bra	set_rdexml

sc88_reverb:				*.SC88_REVERB
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*d1=I/F number,d2=DEV ID
	move.l	d1,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#11,d1
	lea	sct_sc88_reverb(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_sc88rvb		*送信パケット生成 > d1.l=packet length
	bra	set_rdexshp

do_sc88rvb:				*SC88リバーブパラメータ取得&MIDIメッセージ作成
	* < d2=DEV ID
	* > temp_buffer
	* > d1=packet length(1～)
	* x d0-d3/a1-a2
	move.l	temp_buffer(pc),a2
	move.w	#$f041,(a2)+
	move.b	d2,(a2)+		*set dev ID
	move.b	#$42,(a2)+		*set model id
	move.l	#$12_400130,(a2)+	*cmd,addr
	moveq.l	#8,d1
	lea	sc88rvb_lmit(pc),a1
	bsr	get_arry_params		*{}で囲まれた数値の取得(< d1 n of data/> d1=n of data)
	subq.l	#1,d1
	bcs	m_parameter_cannot_be_omitted	*パラメータは最低１個
	moveq.l	#$40+$01+$30,d3
	bra	set_arry_data

sc88rvb_lmit:	dc.b	0,7,0,7,0,7,0,127,-1
	.even

mml_gs_chorus:				*[GS_CHORUS]([SC55_CHORUS])
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*>d2=DEV ID
	bsr	gs_id_set
	moveq.l	#exclusive_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#MKID_ROLAND,d0
	bsr	do_wrt_trk_b
	moveq.l	#9,d1
	lea	sct_gs_chorus(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_gschrs		*送信パケット生成 > d1.l=packet length
	bra	set_rdexml

gs_chorus:				*.GS_CHORUS(SC55_CHORUS)
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*d1=I/F number,d2=DEV ID
	move.l	d1,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#9,d1
	lea	sct_gs_chorus(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_gschrs		*送信パケット生成 > d1.l=packet length
	bra	set_rdexshp

do_gschrs:				*GSコーラスパラメータ取得&MIDIメッセージ作成
	* < d2=DEV ID
	* > temp_buffer
	* > d1=packet length(1～)
	* x d0-d3/a1-a2
	move.l	temp_buffer(pc),a2
	move.w	#$f041,(a2)+
	move.b	d2,(a2)+		*set dev ID
	move.b	#$42,(a2)+		*set model id
	move.l	#$12_400138,(a2)+	*cmd,addr
	moveq.l	#8,d1
	lea	gschrs_limit(pc),a1
	bsr	get_arry_params		*{}で囲まれた数値の取得(< d1 n of data/> d1=n of data)
	subq.l	#1,d1
	bcs	m_parameter_cannot_be_omitted	*パラメータは最低１個
	moveq.l	#$40+$01+$38,d3
set_arry_data:
	* < d1.w=n of length-1
	move.l	arry_stock(pc),a1
@@:
	move.b	(a1)+,d0
	add.b	d0,d3
	move.b	d0,(a2)+
	dbra	d1,@b
calcset_exsm:
	moveq.l	#$80,d0
	andi.b	#$7f,d3
	sub.b	d3,d0
	andi.b	#$7f,d0
	move.b	d0,(a2)+	*checksum
	move.b	#$f7,(a2)+	*EOX
	move.l	a2,d1
	sub.l	temp_buffer(pc),d1
	rts

gschrs_limit:	dc.b	0,7,0,127,-1
	.even

mml_sc88_chorus:			*[SC88_CHORUS]
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*>d2=DEV ID
	bsr	gs_id_set
	moveq.l	#exclusive_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#MKID_ROLAND,d0
	bsr	do_wrt_trk_b
	moveq.l	#11,d1
	lea	sct_sc88_chorus(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_sc88chrs		*送信パケット生成 > d1.l=packet length
	bra	set_rdexml

sc88_chorus:				*.SC88_CHORUS
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*d1=I/F number,d2=DEV ID
	move.l	d1,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#11,d1
	lea	sct_sc88_chorus(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_sc88chrs		*送信パケット生成 > d1.l=packet length
	bra	set_rdexshp

do_sc88chrs:				*SC88コーラスパラメータ取得&MIDIメッセージ作成
	* < d2=DEV ID
	* > temp_buffer
	* > d1=packet length(1～)
	* x d0-d3/a1-a2
	move.l	temp_buffer(pc),a2
	move.w	#$f041,(a2)+
	move.b	d2,(a2)+		*set dev ID
	move.b	#$42,(a2)+		*set model id
	move.l	#$12_400138,(a2)+	*cmd,addr
	moveq.l	#9,d1
	lea	sc88chrs_limit(pc),a1
	bsr	get_arry_params		*{}で囲まれた数値の取得(< d1 n of data/> d1=n of data)
	subq.l	#1,d1
	bcs	m_parameter_cannot_be_omitted	*パラメータは最低１個
	moveq.l	#$40+$01+$38,d3
	bra	set_arry_data

sc88chrs_limit:	dc.b	0,7,0,127,-1
	.even

mml_sc88_delay:				*[SC88_DELAY]
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*>d2=DEV ID
	bsr	gs_id_set
	moveq.l	#exclusive_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#MKID_ROLAND,d0
	bsr	do_wrt_trk_b
	moveq.l	#10,d1
	lea	sct_sc88_delay(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_sc88delay		*送信パケット生成 > d1.l=packet length
	bra	set_rdexml

sc88_delay:				*.SC88_DELAY
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*d1=I/F number,d2=DEV ID
	move.l	d1,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#10,d1
	lea	sct_sc88_delay(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_sc88delay		*送信パケット生成 > d1.l=packet length
	bra	set_rdexshp

do_sc88delay:				*SC88ディレイパラメータ取得&MIDIメッセージ作成
	* < d2=DEV ID
	* > temp_buffer
	* > d1=packet length(1～)
	* x d0-d3/a1-a2
	move.l	temp_buffer(pc),a2
	move.w	#$f041,(a2)+
	move.b	d2,(a2)+		*set dev ID
	move.b	#$42,(a2)+		*set model id
	move.l	#$12_400150,(a2)+	*cmd,addr
	moveq.l	#11,d1
	lea	sc88delay_limit(pc),a1
	bsr	get_arry_params		*{}で囲まれた数値の取得(< d1 n of data/> d1=n of data)
	subq.l	#1,d1
	bcs	m_parameter_cannot_be_omitted	*パラメータは最低１個
	moveq.l	#$40+$01+$50,d3
	bra	set_arry_data

sc88delay_limit:	dc.b	0,9,0,7,1,$73,1,$78,1,$78,0,127,-1
	.even

mml_sc88_equalizer:			*[SC88_EQUALIZER]
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*>d2=DEV ID
	bsr	gs_id_set
	moveq.l	#exclusive_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#MKID_ROLAND,d0
	bsr	do_wrt_trk_b
	moveq.l	#14,d1
	lea	sct_sc88_equalizer(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_sc88eq		*送信パケット生成 > d1.l=packet length
	bra	set_rdexml

sc88_equalizer:				*.SC88_EQUALIZER
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*d1=I/F number,d2=DEV ID
	move.l	d1,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#14,d1
	lea	sct_sc88_equalizer(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_sc88eq		*送信パケット生成 > d1.l=packet length
	bra	set_rdexshp

do_sc88eq:				*SC88イコライザパラメータ取得&MIDIメッセージ作成
	* < d2=DEV ID
	* > temp_buffer
	* > d1=packet length(1～)
	* x d0-d3/a1-a2
	move.l	temp_buffer(pc),a2
	move.w	#$f041,(a2)+
	move.b	d2,(a2)+		*set dev ID
	move.b	#$42,(a2)+		*set model id
	move.l	#$12_400200,(a2)+	*cmd,addr
	moveq.l	#4,d1
	lea	sc88eq_limit(pc),a1
	bsr	get_arry_params		*{}で囲まれた数値の取得(< d1 n of data/> d1=n of data)
	subq.l	#1,d1
	bcs	m_parameter_cannot_be_omitted	*パラメータは最低１個
	moveq.l	#$40+$02+$00,d3
	bra	set_arry_data

sc88eq_limit:	dc.b	0,1,$34,$4c,0,1,$34,$4c,-1
	.even

mml_gs_part_setup:			*[GS_PART_SETUP]([SC55_PART_SETUP])
	move.l	#$1240_1002,d5		*$12:cmd,$401n02:addr
	bsr	get_prt_devid_ifn	*>d2=DEV ID,d3=part number
	bsr	gs_id_set
	cmpi.w	#10,d3			*パート番号をアドレスへ反映
	bcs	@f
	bhi	mldec_ptn
	moveq.l	#0,d3
	bra	@f
mldec_ptn:
	subq.w	#1,d3
@@:
	lsl.w	#8,d3
	or.w	d3,d5

	moveq.l	#119,d1			*パラメータの個数は最大で119個
	lea	gs_part_setup_limit(pc),a1
	bsr	get_arry_params		*{}で囲まれた数値の取得(< d1 n of data/> d1=n of data)
	move.l	d1,d6
	beq	m_parameter_cannot_be_omitted	*パラメータは最低１個
	move.l	arry_stock(pc),a1
	move.b	(a1),d0			*MIDI CH1-16→0-15
	subq.b	#1,d0
	cmpi.b	#$0f,d0
	bls	@f
	moveq.l	#$10,d0
@@:
	move.b	d0,(a1)			*save ch:0-15
	lea	gsptofs(pc),a3
mgpp_lp:
	moveq.l	#exclusive_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#MKID_ROLAND,d0
	bsr	do_wrt_trk_b
	moveq.l	#13,d1			*文字長
	move.l	a1,-(sp)
	lea	sct_gs_ptstup(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	move.l	(sp)+,a1

	bsr	do_gsptstup		*送信パケット生成 > d1.l=packet length
	subq.w	#7,d1			*header:5,sum:1,tail:1
	move.l	d1,d0
	bsr	do_wrt_trk_l		*データ長
	move.l	temp_buffer(pc),a2
	addq.w	#5,a2
	subq.w	#1,d1			*for dbra
@@:
	move.b	(a2)+,d0
	bsr	do_wrt_trk_b
	dbra	d1,@b
	tst.l	d6
	bne	mgpp_lp
	rts

gs_part_setup:				*.GS_PART_SETUP(SC55_PART_SETUP)
*	bsr	check_relation_cmn	*コマンド関係チェック
	bsr	get_prt_devid_ifn		*d1=I/F number,d2=DEV ID,d3=part number
	move.l	d1,d7

	move.l	temp_buffer(pc),a2
	move.w	#$f041,(a2)+
	move.b	d2,(a2)+		*set dev ID
	move.b	#$42,(a2)+		*set model id

	move.l	#$1240_1002,d5		*$12:cmd,$401n02:addr
	cmpi.w	#10,d3			*パート番号をアドレスへ反映
	bcs	@f
	bhi	dec_ptn
	moveq.l	#0,d3
	bra	@f
dec_ptn:
	subq.w	#1,d3
@@:
	lsl.w	#8,d3
	or.w	d3,d5

	moveq.l	#119,d1			*パラメータの個数は最大で119個
	lea	gs_part_setup_limit(pc),a1
	bsr	get_arry_params		*{}で囲まれた数値の取得(< d1 n of data/> d1=n of data)
	move.l	d1,d6
	beq	m_parameter_cannot_be_omitted	*パラメータは最低１個
	move.l	arry_stock(pc),a1
	move.b	(a1),d0			*MIDI CH1-16→0-15
	subq.b	#1,d0
	cmpi.b	#$0f,d0
	bls	@f
	moveq.l	#$10,d0
@@:
	move.b	d0,(a1)			*save ch:0-15
	lea	gsptofs(pc),a3
gpp_lp:
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	move.l	d7,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#13,d1			*文字長
	move.l	a1,-(sp)
	lea	sct_gs_ptstup(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	move.l	(sp)+,a1

	bsr	do_gsptstup		*送信パケット生成 > d1.l=packet length
	move.l	d1,d0
	bsr	do_wrt_cmn_l		*データ長
	move.l	temp_buffer(pc),a2
	subq.w	#1,d1			*for dbra
@@:
	move.b	(a2)+,d0
	bsr	do_wrt_cmn_b
	dbra	d1,@b
	tst.l	d6
	bne	gpp_lp
	jmp	cmpl_lp

gs_part_setup_limit:
	dc.b	0,17
	rept	17
	dc.b	0,1
	endm
	dc.b	0,2
	dc.b	0,2
	dc.b	$28,$58
	rept	12
	dc.b	0,127
	endm
	dc.b	$0e,$72
	dc.b	$0e,$72
	dc.b	$0e,$50
	rept	5
	dc.b	$0e,$72
	endm
	rept	12
	dc.b	0,127
	endm
	rept	6
	dc.b	$28,$58
	rept	10
	dc.b	0,127
	endm
	endm
	dc.b	-1
	.even

do_gsptstup:				*GSパートセットアップパラメータ取得&MIDIメッセージ作成
	* < d5.l=param. module address
	* < d6.l=実際に入力されたパラメータ数
	* < a1.l=arry_stock+n
	* < a3.l=スキップ点アドレス・テーブル+n
	* > temp_buffer
	* > d1=packet length(1～)
	* > d5.l=next param. module addr
	* > d6.l=残りデータ個数
	* > a1.l=arry_stock+nn
	* > a3.l=スキップ点アドレス・テーブル+nn
	* X a2
	move.l	temp_buffer(pc),a2
	addq.w	#4,a2
	move.l	d5,(a2)+		*set cmd,addr
					*make initial sum
	swap	d5
	move.b	d5,d3
	swap	d5
	ror.w	#8,d5
	add.b	d5,d3
	ror.w	#8,d5
	add.b	d5,d3			*d3=address sum
gsptlp:
	move.b	(a1)+,d0
	add.b	d0,d3
	move.b	d0,(a2)+
	addq.b	#1,d5			*inc addr
	move.w	d5,d0
	andi.w	#$f0ff,d0
	subq.l	#1,d6
	beq	calcset_exsm
	cmp.w	(a3),d0			*スキップ点にきたか
	bne	gsptlp
	move.l	(a3)+,d0
	add.w	d0,d5			*d5.l=next addr
	bra	calcset_exsm

gsptofs:
*	dc.w	$1017,$0000
	dc.w	$1019,$0000
	dc.w	$1023,$000d
	dc.w	$1038,$0008
	dc.w	$104c,$0fb4
	dc.w	$200b,$0005
	dc.w	$201b,$0005
	dc.w	$202b,$0005
	dc.w	$203b,$0005
	dc.w	$204b,$0005
	dc.w	-1

mml_sc88_part_setup:			*[SC88_PART_SETUP]
	move.l	#$1240_1002,d5		*$12:cmd,$401n02:addr
	bsr	get_prt_devid_ifn	*>d2=DEV ID,d3=part number
	bsr	gs_id_set
	cmpi.w	#10,d3			*パート番号をアドレスへ反映
	bcs	@f
	bhi	1f
	moveq.l	#0,d3
	bra	@f
1:
	subq.w	#1,d3
@@:
	lsl.w	#8,d3
	or.w	d3,d5

	moveq.l	#127,d1			*パラメータの個数は最大で127個
	lea	sc88_part_setup_limit(pc),a1
	bsr	get_arry_params		*{}で囲まれた数値の取得(< d1 n of data/> d1=n of data)
	move.l	d1,d6
	beq	m_parameter_cannot_be_omitted	*パラメータは最低１個
	move.l	arry_stock(pc),a1
	move.b	(a1),d0			*MIDI CH1-16→0-15
	subq.b	#1,d0
	cmpi.b	#$0f,d0
	bls	@f
	moveq.l	#$10,d0
@@:
	move.b	d0,(a1)			*save ch:0-15
	lea	sc88ptofs(pc),a3
msps_lp:
	moveq.l	#exclusive_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#MKID_ROLAND,d0
	bsr	do_wrt_trk_b
	moveq.l	#15,d1			*文字長
	move.l	a1,-(sp)
	lea	sct_sc88_ptstup(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	move.l	(sp)+,a1

	bsr	do_gsptstup		*送信パケット生成 > d1.l=packet length
	subq.w	#7,d1			*header:5,sum:1,tail:1
	move.l	d1,d0
	bsr	do_wrt_trk_l		*データ長
	move.l	temp_buffer(pc),a2
	addq.w	#5,a2
	subq.w	#1,d1			*for dbra,sum分除外
@@:
	move.b	(a2)+,d0
	bsr	do_wrt_trk_b
	dbra	d1,@b
	tst.l	d6
	bne	msps_lp
	rts

sc88_part_setup:			*.SC88_PART_SETUP
*	bsr	check_relation_cmn	*コマンド関係チェック
	bsr	get_prt_devid_ifn		*d1=I/F number,d2=DEV ID,d3=part number
	move.l	d1,d7

	move.l	temp_buffer(pc),a2
	move.w	#$f041,(a2)+
	move.b	d2,(a2)+		*set dev ID
	move.b	#$42,(a2)+		*set model id

	move.l	#$1240_1002,d5		*$12:cmd,$401n02:addr
	cmpi.w	#10,d3			*パート番号をアドレスへ反映
	bcs	@f
	bhi	1f
	moveq.l	#0,d3
	bra	@f
1:
	subq.w	#1,d3
@@:
	lsl.w	#8,d3
	or.w	d3,d5

	moveq.l	#127,d1			*パラメータの個数は最大で127個
	lea	sc88_part_setup_limit(pc),a1
	bsr	get_arry_params		*{}で囲まれた数値の取得(< d1 n of data/> d1=n of data)
	move.l	d1,d6
	beq	m_parameter_cannot_be_omitted	*パラメータは最低１個
	move.l	arry_stock(pc),a1
	move.b	(a1),d0			*MIDI CH1-16→0-15
	subq.b	#1,d0
	cmpi.b	#$0f,d0
	bls	@f
	moveq.l	#$10,d0
@@:
	move.b	d0,(a1)			*save ch:0-15
	lea	sc88ptofs(pc),a3
mps_lp:
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	move.l	d7,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#15,d1			*文字長
	move.l	a1,-(sp)
	lea	sct_sc88_ptstup(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	move.l	(sp)+,a1

	bsr	do_gsptstup		*送信パケット生成 > d1.l=packet length
	move.l	d1,d0
	bsr	do_wrt_cmn_l		*データ長
	move.l	temp_buffer(pc),a2
	subq.w	#1,d1			*for dbra
@@:
	move.b	(a2)+,d0
	bsr	do_wrt_cmn_b
	dbra	d1,@b
	tst.l	d6
	bne	mps_lp
	jmp	cmpl_lp

sc88_part_setup_limit:
	dc.b	0,16
	rept	17
	dc.b	0,1
	endm
	dc.b	0,2
	dc.b	0,2
	dc.b	$28,$58
	rept	8
	dc.b	0,127
	endm
	dc.b	0,$5f
	dc.b	0,$5f
	dc.b	0,$7f
	dc.b	0,$7f
	dc.b	0,1
	dc.b	0,1
	rept	23
	dc.b	0,$7f
	endm
	dc.b	$28,$58
	rept	10
	dc.b	0,127
	endm
	dc.b	$40,$58
	rept	10
	dc.b	0,127
	endm
	rept	4
	dc.b	$28,$58
	rept	10
	dc.b	0,127
	endm
	endm
	dc.b	0,2
	dc.b	1,2
	dc.b	0,1
	dc.b	-1
	.even

sc88ptofs:
	dc.w	$1019,$0000
	dc.w	$1025,$0005
	dc.w	$102d,$0003
	dc.w	$1038,$0008
	dc.w	$104c,$0fb4
	dc.w	$2001,$0000
	dc.w	$2002,$0000
	dc.w	$2003,$0000
	dc.w	$2004,$0000
	dc.w	$2005,$0000
	dc.w	$2006,$0000
	dc.w	$2007,$0000
	dc.w	$2008,$0000
	dc.w	$2009,$0000
	dc.w	$200a,$0000
	dc.w	$200b,$0005
	dc.w	$2011,$0000
	dc.w	$2012,$0000
	dc.w	$2013,$0000
	dc.w	$2014,$0000
	dc.w	$2015,$0000
	dc.w	$2016,$0000
	dc.w	$2017,$0000
	dc.w	$2018,$0000
	dc.w	$2019,$0000
	dc.w	$201a,$0000
	dc.w	$201b,$0005
	dc.w	$2021,$0000
	dc.w	$2022,$0000
	dc.w	$2023,$0000
	dc.w	$2024,$0000
	dc.w	$2025,$0000
	dc.w	$2026,$0000
	dc.w	$2027,$0000
	dc.w	$2028,$0000
	dc.w	$2029,$0000
	dc.w	$202a,$0000
	dc.w	$202b,$0005
	dc.w	$2031,$0000
	dc.w	$2032,$0000
	dc.w	$2033,$0000
	dc.w	$2034,$0000
	dc.w	$2035,$0000
	dc.w	$2036,$0000
	dc.w	$2037,$0000
	dc.w	$2038,$0000
	dc.w	$2039,$0000
	dc.w	$203a,$0000
	dc.w	$203b,$0005
	dc.w	$2041,$0000
	dc.w	$2042,$0000
	dc.w	$2043,$0000
	dc.w	$2044,$0000
	dc.w	$2045,$0000
	dc.w	$2046,$0000
	dc.w	$2047,$0000
	dc.w	$2048,$0000
	dc.w	$2049,$0000
	dc.w	$204a,$0000
	dc.w	$204b,$0005
	dc.w	$2051,$0000
	dc.w	$2052,$0000
	dc.w	$2053,$0000
	dc.w	$2054,$0000
	dc.w	$2055,$0000
	dc.w	$2056,$0000
	dc.w	$2057,$0000
	dc.w	$2058,$0000
	dc.w	$2059,$0000
	dc.w	$205a,$0000
	dc.w	$205b,$1FA5
	dc.w	$4001,$0000
	dc.w	$4002,$001e
	dc.w	-1

mml_gs_drum_setup:			*[GS_DRUM_SETUP]([SC55_DRUM_SETUP])
	move.l	#$1241_0100,d5		*$12:cmd,$41m1kk:addr
	bsr	get_mp_ky_devid_ifn	*>d2=DEV ID,d3.hw=map number,d3.lw=key number
	bsr	gs_id_set
	move.b	d3,d5			*map番号,key番号をアドレスへ反映
	swap	d3
	ror.w	#8,d3
	andi.w	#$f000,d3
	or.w	d3,d5

	moveq.l	#8,d1			*パラメータの個数は最大で8個
	lea	gs_drum_setup_limit(pc),a1
	bsr	get_arry_params		*{}で囲まれた数値の取得(< d1 n of data/> d1=n of data)
	move.l	d1,d6
	beq	m_parameter_cannot_be_omitted	*パラメータは最低１個
	move.l	arry_stock(pc),a1
mgds_lp:
	moveq.l	#exclusive_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#MKID_ROLAND,d0
	bsr	do_wrt_trk_b
	moveq.l	#13,d1			*文字長
	move.l	a1,-(sp)
	lea	sct_gs_drmstup(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	move.l	(sp)+,a1

	bsr	do_gsdrmstup		*送信パケット生成
	moveq.l	#5-1,d0			*チェックサムの分は含めない
	bsr	do_wrt_trk_l		*データ長
	lea	exc_addr(pc),a2
	moveq.l	#5-1-1,d1
@@:
	move.b	(a2)+,d0
	bsr	do_wrt_trk_b
	dbra	d1,@b
	tst.l	d6
	bne	mgds_lp
	rts

gs_drum_setup:				*.GS_DRUM_SETUP(SC55_DRUM_SETUP)
*	bsr	check_relation_cmn	*コマンド関係チェック
	bsr	get_mp_ky_devid_ifn	*d1=I/F number,d2=DEV ID,d3.hw=map number,d3.lw=key number
	move.l	d1,d7

	lea	header+2(pc),a2
	move.b	d2,(a2)+		*set dev ID
	move.b	#$42,(a2)+		*set model id

	move.l	#$1241_0100,d5		*$12:cmd,$41m1kk:addr
	move.b	d3,d5			*map番号,key番号をアドレスへ反映
	swap	d3
	ror.w	#8,d3
	andi.w	#$f000,d3
	or.w	d3,d5

	moveq.l	#8,d1			*パラメータの個数は最大で8個
	lea	gs_drum_setup_limit(pc),a1
	bsr	get_arry_params		*{}で囲まれた数値の取得(< d1 n of data/> d1=n of data)
	move.l	d1,d6
	beq	m_parameter_cannot_be_omitted	*パラメータは最低１個
	move.l	arry_stock(pc),a1
gds_lp:
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	move.l	d7,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#13,d1			*文字長
	move.l	a1,-(sp)
	lea	sct_gs_drmstup(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	move.l	(sp)+,a1

	bsr	do_gsdrmstup		*送信パケット生成 > d1.l=packet length
	move.l	#11,d0
	bsr	do_wrt_cmn_l		*データ長
	lea	exc_addr(pc),a2
	moveq.l	#11-1,d1
@@:
	move.b	(a2)+,d0
	bsr	do_wrt_cmn_b
	dbra	d1,@b
	tst.l	d6
	bne	gds_lp
	jmp	cmpl_lp

gs_drum_setup_limit:
	rept	6
	dc.b	0,127
	endm
	dc.b	0,1
	dc.b	0,1
	dc.b	-1
	.even

do_gsdrmstup:				*GSドラムセットアップパラメータ取得&MIDIメッセージ作成
	* < d5.l=param. module address
	* < d6.l=実際に入力されたパラメータ数
	* < a1.l=arry_stock+n
	* > temp_buffer
	* > d1=packet length(1～)
	* > d5.l=next param. module addr
	* > d6.l=残りデータ個数
	* > a1.l=arry_stock+nn
	* X a2
	lea	header+4(pc),a2
	move.l	d5,(a2)+		*set cmd,addr
					*make initial sum
	swap	d5
	move.b	d5,d3
	swap	d5
	ror.w	#8,d5
	add.b	d5,d3
	ror.w	#8,d5
	add.b	d5,d3			*d3=address sum
	move.b	(a1)+,d0
	add.b	d0,d3
	move.b	d0,(a2)+
	add.w	#$0100,d5		*inc addr
	moveq.l	#$80,d0
	andi.b	#$7f,d3
	sub.b	d3,d0
	andi.b	#$7f,d0
	move.b	d0,(a2)+		*sum
	subq.l	#1,d6
	rts

mml_gs_drum_name:			*[GS_DRUM_NAME]([SC55_DRUM_NAME])
	bsr	get_map_devid_ifn	*>d2=DEV ID,d3=map number
	bsr	gs_id_set
	moveq.l	#exclusive_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#MKID_ROLAND,d0
	bsr	do_wrt_trk_b
	moveq.l	#15,d1
	lea	sct_gs_drmname(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_gsdrmnm		*送信パケット生成 > d1.l=packet length
	bra	set_rdexml

gs_drum_name:				*.GS_DRUM_NAME(.SC55_DRUM_NAME)
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	bsr	get_map_devid_ifn	*d1=I/F number,d2=DEV ID,d3=map number
	move.l	d1,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#15,d1
	lea	sct_gs_drmname(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_gsdrmnm		*送信パケット生成 > d1.l=packet length
	bra	set_rdexshp

do_gsdrmnm:				*SC55ドラムセットの名前の設定
	* < d2=DEV ID
	* < d3=MAP NUMBER(0,1/$80+0,1)	$80+はUERケース
	* > temp_buffer
	* > d1=packet length(1～)
	* x d0-d3/a1-a2
	move.l	temp_buffer(pc),a2
	move.w	#$f041,(a2)+
	move.b	d2,(a2)+		*set dev ID
	move.b	#$42,(a2)+		*set model id
	move.l	#$12_410000,d1
	bclr.l	#7,d3
	bne	m_illegal_map_number	*user case
	tst.b	d3			*preset case
	beq	@f
	move.w	#$1000,d1
	moveq.l	#$51,d3			*address sum
	bra	1f
@@:
	moveq.l	#$41,d3			*address sum
1:
	move.l	d1,(a2)+		*cmd,addr
	moveq.l	#12,d1			*最大文字列長
	bsr	get_string_param	*""で囲まれた文字列の取得(< d1 n of data/> d1=n of data)
	moveq.l	#12-1,d1
	bra	set_arry_data

mml_sc88_drum_setup:			*[SC88_DRUM_SETUP]
	move.l	#$1241_0100,d5		*$12:cmd,$41m1kk:addr
	bsr	get_mp_ky_devid_ifn	*>d2=DEV ID,d3.hw=map number,d3.lw=key number
	bsr	gs_id_set
	move.b	d3,d5			*map番号,key番号をアドレスへ反映
	swap	d3
	ror.w	#8,d3
	andi.w	#$f000,d3
	or.w	d3,d5

	moveq.l	#9,d1			*パラメータの個数は最大で9個
	lea	sc88_drum_setup_limit(pc),a1
	bsr	get_arry_params		*{}で囲まれた数値の取得(< d1 n of data/> d1=n of data)
	move.l	d1,d6
	beq	m_parameter_cannot_be_omitted	*パラメータは最低１個
	move.l	arry_stock(pc),a1
msds_lp:
	moveq.l	#exclusive_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#MKID_ROLAND,d0
	bsr	do_wrt_trk_b
	moveq.l	#15,d1			*文字長
	move.l	a1,-(sp)
	lea	sct_sc88_drmstup(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	move.l	(sp)+,a1

	bsr	do_gsdrmstup		*送信パケット生成
	moveq.l	#5-1,d0			*sum分除外
	bsr	do_wrt_trk_l		*データ長
	lea	exc_addr(pc),a2
	moveq.l	#5-1-1,d1
@@:
	move.b	(a2)+,d0
	bsr	do_wrt_trk_b
	dbra	d1,@b
	tst.l	d6
	bne	msds_lp
	rts

sc88_drum_setup:			*.SC88_DRUM_SETUP
*	bsr	check_relation_cmn	*コマンド関係チェック
	bsr	get_mp_ky_devid_ifn	*d1=I/F number,d2=DEV ID,d3.hw=map number,d3.lw=key number
	move.l	d1,d7

	lea	header+2(pc),a2
	move.b	d2,(a2)+		*set dev ID
	move.b	#$42,(a2)+		*set model id

	move.l	#$1241_0100,d5		*$12:cmd,$41m1kk:addr
	move.b	d3,d5			*map番号,key番号をアドレスへ反映
	swap	d3
	ror.w	#8,d3
	andi.w	#$f000,d3
	or.w	d3,d5

	moveq.l	#9,d1			*パラメータの個数は最大で9個
	lea	sc88_drum_setup_limit(pc),a1
	bsr	get_arry_params		*{}で囲まれた数値の取得(< d1 n of data/> d1=n of data)
	move.l	d1,d6
	beq	m_parameter_cannot_be_omitted	*パラメータは最低１個
	move.l	arry_stock(pc),a1
sds_lp:
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	move.l	d7,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#15,d1			*文字長
	move.l	a1,-(sp)
	lea	sct_sc88_drmstup(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	move.l	(sp)+,a1

	bsr	do_gsdrmstup		*送信パケット生成 > d1.l=packet length
	move.l	#11,d0
	bsr	do_wrt_cmn_l		*データ長
	lea	exc_addr(pc),a2
	moveq.l	#11-1,d1
@@:
	move.b	(a2)+,d0
	bsr	do_wrt_cmn_b
	dbra	d1,@b
	tst.l	d6
	bne	sds_lp
	jmp	cmpl_lp

sc88_drum_setup_limit:
	rept	6
	dc.b	0,127
	endm
	dc.b	0,1
	dc.b	0,1
	dc.b	0,127
	dc.b	-1
	.even

mml_gs_print:				*[GS_PRINT]([SC55_PRINT])
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*>d2=DEV ID
	bsr	sc55_id_set
	moveq.l	#exclusive_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#MKID_ROLAND,d0
	bsr	do_wrt_trk_b
	moveq.l	#8,d1
	lea	sct_gs_print(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_gsprt		*送信パケット生成 > d1.l=packet length
	bra	set_rdexml

gs_print:				*.GS_PRINT(SC55_PRINT)
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*d1=I/F number,d2=DEV ID
	move.l	d1,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#8,d1
	lea	sct_gs_print(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_gsprt		*送信パケット生成 > d1.l=packet length
	bra	set_rdexshp

do_gsprt:				*GS文字列出力パラメータ取得&MIDIメッセージ作成
	* < d2=DEV ID
	* > temp_buffer
	* > d1=packet length(1～)
	* x d0-d3/a1-a2
	move.l	temp_buffer(pc),a2
	move.w	#$f041,(a2)+
	move.b	d2,(a2)+		*set dev ID
	move.b	#$45,(a2)+		*set model id
	move.l	#$12_100000,(a2)+	*cmd,addr
	moveq.l	#32,d1			*最大文字列長
	bsr	get_string_param	*""で囲まれた文字列の取得(< d1 n of data/> d1=n of data)
	subq.l	#1,d1
	bcs	m_parameter_cannot_be_omitted	*パラメータは最低１個
	moveq.l	#$10,d3			*address sum
	bra	set_arry_data

mml_sc88_user_inst:			*[SC88_USER_INST]
	move.l	#$1220_0000,d5		*$12:cmd,$20b0pp:addr
	bsr	get_bk_pg_devid_ifn	*>d2=DEV ID,d3.hw=bank number,d3.lw=program number
	bsr	gs_id_set
	move.b	d3,d5			*map番号,key番号をアドレスへ反映
	swap	d3
	ror.w	#8,d3
	andi.w	#$f000,d3
	or.w	d3,d5

	moveq.l	#11,d1			*パラメータの個数は最大で11個
	lea	sc88_user_inst_limit(pc),a1
	bsr	get_arry_params		*{}で囲まれた数値の取得(< d1 n of data/> d1=n of data)
	move.l	d1,d6
	beq	m_parameter_cannot_be_omitted	*パラメータは最低１個
	move.l	arry_stock(pc),a1
	subq.b	#1,2(a1)		*1-128→0-127
msui_lp:
	moveq.l	#exclusive_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#MKID_ROLAND,d0
	bsr	do_wrt_trk_b
	moveq.l	#14,d1			*文字長
	move.l	a1,-(sp)
	lea	sct_sc88_usrinst(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	move.l	(sp)+,a1

	bsr	do_gsdrmstup		*送信パケット生成
	moveq.l	#5-1,d0			*チェックサム分除外
	bsr	do_wrt_trk_l		*データ長
	lea	exc_addr(pc),a2
	moveq.l	#5-1-1,d1
@@:
	move.b	(a2)+,d0
	bsr	do_wrt_trk_b
	dbra	d1,@b
	tst.l	d6
	bne	msui_lp
	rts

sc88_user_inst:				*.SC88_USER_INST
*	bsr	check_relation_cmn	*コマンド関係チェック
	bsr	get_bk_pg_devid_ifn	*d1=I/F number,d2=DEV ID,d3.hw=bank number,d3.lw=program number
	move.l	d1,d7

	lea	header+2(pc),a2
	move.b	d2,(a2)+		*set dev ID
	move.b	#$42,(a2)+		*set model id

	move.l	#$1220_0000,d5		*$12:cmd,$20b0pp:addr
	move.b	d3,d5			*map番号,key番号をアドレスへ反映
	swap	d3
	ror.w	#8,d3
	andi.w	#$f000,d3
	or.w	d3,d5

	moveq.l	#11,d1			*パラメータの個数は最大で11個
	lea	sc88_user_inst_limit(pc),a1
	bsr	get_arry_params		*{}で囲まれた数値の取得(< d1 n of data/> d1=n of data)
	move.l	d1,d6
	beq	m_parameter_cannot_be_omitted	*パラメータは最低１個
	move.l	arry_stock(pc),a1
	subq.b	#1,2(a1)		*1-128→0-127
sui_lp:
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	move.l	d7,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#14,d1			*文字長
	move.l	a1,-(sp)
	lea	sct_sc88_usrinst(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	move.l	(sp)+,a1

	bsr	do_gsdrmstup		*送信パケット生成 > d1.l=packet length
	move.l	#11,d0
	bsr	do_wrt_cmn_l		*データ長
	lea	exc_addr(pc),a2
	moveq.l	#11-1,d1
@@:
	move.b	(a2)+,d0
	bsr	do_wrt_cmn_b
	dbra	d1,@b
	tst.l	d6
	bne	sui_lp
	jmp	cmpl_lp

sc88_user_inst_limit:
	dc.b	1,2
	dc.b	0,127
	dc.b	1,128
	rept	8
	dc.b	0,127
	endm
	dc.b	-1
	.even

mml_sc88_user_drum:			*[SC88_USER_DRUM]
	move.l	#$1221_0100,d5		*$12:cmd,$21d1rr:addr
	bsr	get_mp_ky_devid_ifn	*>d2=DEV ID,d3.hw=map number,d3.lw=key number
	bsr	gs_id_set
	move.b	d3,d5			*map番号,key番号をアドレスへ反映
	swap	d3
	ror.w	#8,d3
	andi.w	#$f000,d3
	or.w	d3,d5

	moveq.l	#12,d1			*パラメータの個数は最大で12個
	lea	sc88_user_drum_limit(pc),a1
	bsr	get_arry_params		*{}で囲まれた数値の取得(< d1 n of data/> d1=n of data)
	move.l	d1,d6
	beq	m_parameter_cannot_be_omitted	*パラメータは最低１個
	move.l	arry_stock(pc),a1
msud_lp:
	moveq.l	#exclusive_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#MKID_ROLAND,d0
	bsr	do_wrt_trk_b
	moveq.l	#14,d1			*文字長
	move.l	a1,-(sp)
	lea	sct_sc88_usrdrum(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	move.l	(sp)+,a1

	bsr	do_gsdrmstup		*送信パケット生成
	moveq.l	#5-1,d0			*チェックサム分除外
	bsr	do_wrt_trk_l		*データ長
	lea	exc_addr(pc),a2
	moveq.l	#5-1-1,d1
@@:
	move.b	(a2)+,d0
	bsr	do_wrt_trk_b
	dbra	d1,@b
	tst.l	d6
	bne	msud_lp
	rts

sc88_user_drum:				*.SC88_USER_DRUM
*	bsr	check_relation_cmn	*コマンド関係チェック
	bsr	get_mp_ky_devid_ifn	*d1=I/F number,d2=DEV ID,d3.hw=map number,d3.lw=ky number
	move.l	d1,d7

	lea	header+2(pc),a2
	move.b	d2,(a2)+		*set dev ID
	move.b	#$42,(a2)+		*set model id

	move.l	#$1221_0100,d5		*$12:cmd,$21d1rr:addr
	move.b	d3,d5			*map番号,key番号をアドレスへ反映
	swap	d3
	ror.w	#8,d3
	andi.w	#$f000,d3
	or.w	d3,d5

	moveq.l	#12,d1			*パラメータの個数は最大で12個
	lea	sc88_user_drum_limit(pc),a1
	bsr	get_arry_params		*{}で囲まれた数値の取得(< d1 n of data/> d1=n of data)
	move.l	d1,d6
	beq	m_parameter_cannot_be_omitted	*パラメータは最低１個
	move.l	arry_stock(pc),a1
sud_lp:
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	move.l	d7,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#14,d1			*文字長
	move.l	a1,-(sp)
	lea	sct_sc88_usrdrum(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	move.l	(sp)+,a1

	bsr	do_gsdrmstup		*送信パケット生成 > d1.l=packet length
	move.l	#11,d0
	bsr	do_wrt_cmn_l		*データ長
	lea	exc_addr(pc),a2
	moveq.l	#11-1,d1
@@:
	move.b	(a2)+,d0
	bsr	do_wrt_cmn_b
	dbra	d1,@b
	tst.l	d6
	bne	sud_lp
	jmp	cmpl_lp

sc88_user_drum_limit:
	rept	6
	dc.b	0,127
	endm
	dc.b	0,1
	dc.b	0,1
	dc.b	0,127
	dc.b	0,2
	dc.b	0,127
	dc.b	0,127
	dc.b	-1
	.even

mml_sc88_drum_name:			*[SC88_DRUM_NAME]
	bsr	get_map_devid_ifn	*>d2=DEV ID,d3=map number
	bsr	gs_id_set
	moveq.l	#exclusive_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#MKID_ROLAND,d0
	bsr	do_wrt_trk_b
	moveq.l	#15,d1
	lea	sct_sc88_drmname(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_sc88drmnm		*送信パケット生成 > d1.l=packet length
	bra	set_rdexml

sc88_drum_name:				*.SC88_DRUM_NAME
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	bsr	get_map_devid_ifn	*d1=I/F number,d2=DEV ID,d3=map number
	move.l	d1,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#15,d1
	lea	sct_sc88_drmname(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_sc88drmnm		*送信パケット生成 > d1.l=packet length
	bra	set_rdexshp

do_sc88drmnm:				*SC88ドラムセットの名前の設定
	* < d2=DEV ID
	* < d3=MAP NUMBER(0,1/$80+0,1)	$80+はUERケース
	* > temp_buffer
	* > d1=packet length(1～)
	* x d0-d3/a1-a2
	move.l	temp_buffer(pc),a2
	move.w	#$f041,(a2)+
	move.b	d2,(a2)+		*set dev ID
	move.b	#$42,(a2)+		*set model id
	move.l	#$12_410000,d1
	bclr.l	#7,d3
	bne	2f			*user case
	tst.b	d3			*preset case
	beq	@f
	move.w	#$1000,d1
	moveq.l	#$51,d3			*address sum
	bra	1f
@@:
	moveq.l	#$41,d3			*address sum
1:
	move.l	d1,(a2)+		*cmd,addr
	moveq.l	#12,d1			*最大文字列長
	bsr	get_string_param	*""で囲まれた文字列の取得(< d1 n of data/> d1=n of data)
	moveq.l	#12-1,d1
	bra	set_arry_data
2:					*USER
	move.l	#$12_210000,d1
	tst.b	d3
	beq	@f
	move.w	#$1000,d1
	moveq.l	#$31,d3			*address sum
	bra	1b
@@:
	moveq.l	#$21,d3			*address sum
	bra	1b

get_string_param2:			*文字列取得({...}の中に設定されるべき場合)
	* < d1.l=required n of data(この個数よりも少なかった場合はSPCで埋める／多かったらエラー)
	* > d1.l=文字列長
	* > arry_stock
	* > d0.b=最後のキャラクター
	* - all
reglist	reg	d0/d2-d3/a1
	movem.l	reglist,-(sp)
	move.l	arry_stock(pc),a1
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	move.b	(a4)+,d2		*end character
	cmpi.b	#"'",d2
	beq	@f
	cmpi.b	#'"',d2
	beq	@f
	bra	m_illegal_character	*始端記号が無い

get_string_param:			*文字列取得
	* < d1.l=required n of data(この個数よりも少なかった場合はSPCで埋める／多かったらエラー)
	* > d1.l=文字列長
	* > arry_stock
	* > d0.b=最後のキャラクター
	* - all
	movem.l	reglist,-(sp)
	move.l	arry_stock(pc),a1
	bsr	skip_eq
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	move.b	(a4)+,d2		*end character
	cmpi.b	#"'",d2
	beq	@f
	cmpi.b	#'"',d2
	beq	@f
	cmpi.b	#'{',d2
	bne	m_illegal_character	*始端記号が無い
	moveq.l	#'}',d2			*'{'で始まったら'}'で終わる
@@:
	move.l	d1,d3
	subq.w	#1,d3			*for dbra
gstplp:					*get pattern name
	cmp.l	a4,d4
	bls	exit_gstplp
	move.b	(a4)+,d0
	bsr	chk_kanji
	bpl	@f
	move.b	d0,(a1)+		*以下、漢字の場合
	subq.w	#1,d3
	bcs	m_string_too_long	*文字列が長すぎる
	cmp.l	a4,d4
	bls	m_kanji_break_off	*漢字が途中で終わっている
	move.b	(a4)+,d0
	bra	st_gstpchr
@@:
	cmp.b	d2,d0
	beq	exit_gstplp
	cmpi.b	#' ',d0
	bcc	st_gstpchr
	moveq.l	#' ',d0			*コントロールコードはスペースへ変換
st_gstpchr:
	move.b	d0,(a1)+
	dbra	d3,gstplp
	cmp.l	a4,d4
	bls	1f
	cmp.b	(a4)+,d2
	bne	m_illegal_command_line
	bra	1f

exit_gstplp:
	sub.w	d3,d1
	subq.w	#1,d1			*戻り値(文字列実際長)
@@:					*指定長に満たない場合はスペースで補填
	move.b	#' ',(a1)+
	dbra	d3,@b
1:
	movem.l	(sp)+,reglist
	rts

mml_gs_display:				*[GS_DISPLAY]([SC55_DISPLAY])
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*>d2=DEV ID
	bsr	sc55_id_set
	moveq.l	#exclusive_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#MKID_ROLAND,d0
	bsr	do_wrt_trk_b
	moveq.l	#10,d1
	lea	sct_gs_dsply(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_gsdsply		*送信パケット生成 > d1.l=packet length
	bra	set_rdexml

gs_display:				*.GS_DISPLAY(SC55_DISPLAY)
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*d1=I/F number,d2=DEV ID
	move.l	d1,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#10,d1
	lea	sct_gs_dsply(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_gsdsply		*送信パケット生成 > d1.l=packet length
	bra	set_rdexshp

do_gsdsply:				*GSデイスプレイパラメータ取得&MIDIメッセージ作成
	* < d2=DEV ID
	* > temp_buffer
	* > d1=packet length(1～)
	* x d0-d3/a1-a2
	move.l	temp_buffer(pc),a2
	move.w	#$f041,(a2)+
	move.b	d2,(a2)+		*set dev ID
	move.b	#$45,(a2)+		*set model id
	move.l	#$12_100100,(a2)+	*cmd,addr
	moveq.l	#16,d1
	suba.l	a1,a1
	bsr	get_arry_params_w	*{}で囲まれた数値の取得(< d1 n of data/> d1=n of data)
	cmpi.l	#16,d1
	bne	m_illegal_parameter_format	*パラメータは必ず16個
	move.l	arry_stock(pc),a1
	moveq.l	#$11,d3			*address sum
	moveq.l	#16-1,d2
@@:
	move.w	(a1)+,d1
	move.b	d1,d0
	lsl.b	#4,d0
	andi.b	#$10,d0
	move.b	d0,48(a2)
	add.b	d0,d3			*calc sum
	move.w	d1,d0
	lsr.w	#1,d0
	andi.b	#$1f,d0
	move.b	d0,32(a2)
	add.b	d0,d3			*calc sum
	move.w	d1,d0
	lsr.w	#6,d0
	andi.b	#$1f,d0
	move.b	d0,16(a2)
	add.b	d0,d3			*calc sum
	rol.w	#5,d1			*same as lsr.w	#11,d1
	andi.b	#$1f,d1
	move.b	d1,(a2)+
	add.b	d1,d3			*calc sum
	dbra	d2,@b
	add.w	#48,a2
	bra	calcset_exsm

get_arry_params_w:				*データ列認識
	* < d1.l=required n of data(この個数よりも少なかった場合は０で埋める/多かったらエラー)
	* < a1.l=limit value table
	* > arry_stock
	* > d1.l=usable n of data
	movem.l	d2-d3/d5-d6/a1-a2,-(sp)
	moveq.l	#0,d5				*default min
	move.l	#65535,d6			*default max
	move.l	d1,d2
	move.l	arry_stock(pc),a2
	bsr	chk_num
	bpl	@f
	bsr	skip_eq
	cmp.l	a4,d4
	bls	m_parameter_cannot_be_omitted
	cmpi.b	#'{',(a4)+
	seq	d3				*終端マーク
	bne	m_parameter_cannot_be_omitted
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
gtarprmw_lp:
	moveq.l	#0,d1				*省略時の値
	bsr	chk_num
	bpl	@f
	cmp.l	a4,d4
	bls	exit_gtarprmw_lp
	cmpi.b	#',',(a4)			*','の場合は値省略とする
	beq	gtarprmw_nmldt
	bra	exit_gtarprmw_lp		*','以外のものがあるという事はもう数値は続かないという事
@@:
	bsr	get_num
	move.l	a1,d0
	beq	1f				*no check
	cmp.l	#-32768,4(a1)			*min check
	beq	@f
	move.l	(a1)+,d5
@@:
	cmp.l	d5,d1
	blt	m_illegal_parameter_value
1:
	move.l	a1,d0
	beq	1f				*no check
	cmp.l	#-32768,4(a1)			*max check
	beq	@f
	move.l	(a1)+,d6
@@:
	cmp.l	d6,d1
	bgt	m_illegal_parameter_value
1:
gtarprmw_nmldt:
	bsr	skip_sep
	subq.l	#1,d2
	bcs	m_too_many_parameters		*パラメータが指定個数以上あってはならない
	move.w	d1,(a2)+
	bra	gtarprmw_lp
exit_gtarprmw_lp:
	move.l	a2,d1
	sub.l	arry_stock(pc),d1		*実質パラメータ個数
	lsr.l	#1,d1				*個数値に変換
	tst.l	d2
	beq	exit_gtarprmw
@@:						*足りないパラメータは0で埋める
	clr.w	(a2)+
	subq.l	#1,d2
	bne	@b
exit_gtarprmw:
	tst.b	d3				*終端括弧いらないケース=0
	beq	@f
	cmpi.b	#'}',(a4)+
	bne	m_illegal_command_line		*終端記号が無い
@@:
	movem.l	(sp)+,d2-d3/d5-d6/a1-a2
	rts

mml_gm_system_on:			*[GM_SYSTEM_ON]
	moveq.l	#midi_transmission_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#12,d1
	lea	sct_gm_syson(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment
	moveq.l	#6,d0
	bsr	do_wrt_trk_l		*データ長
	move.l	#$f07e7f09,d0
	bsr	do_wrt_trk_l		*転送データ
	move.w	#$01f7,d0
	bra	do_wrt_trk_w		*転送データ

gm_system_on:				*.GM_SYSTEM_ON
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	bsr	get_ifn			*d1=I/F number,d2=DEV ID
	move.l	d1,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#12,d1
	lea	sct_gm_syson(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment
	moveq.l	#6,d0
	bsr	do_wrt_cmn_l		*データ長
	move.l	#$f07e7f09,d0
	bsr	do_wrt_cmn_l		*転送データ
	move.w	#$01f7,d0
	bsr	do_wrt_cmn_w		*転送データ
	jmp	cmpl_lp

mml_sc88_mode:				*[SC88_MODE]
	bsr	get_mode_devid_ifn	*>d3=mode
	bsr	gs_id_set
	moveq.l	#exclusive_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#MKID_ROLAND,d0
	bsr	do_wrt_trk_b
	moveq.l	#9,d1
	lea	sct_sc88_mode(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment
	moveq.l	#4,d0
	bsr	do_wrt_trk_l		*データ長
	move.l	#$0000_7f00,d0
	move.b	d3,d0			*mode(0,1)
	bra	do_wrt_trk_l		*転送データ

sc88_mode:				*.SC88_MODE
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	bsr	get_mode_devid_ifn	*d1=I/F number,d2=DEV ID,d3=mode
	move.l	d1,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#9,d1
	lea	sct_sc88_mode(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment
	moveq.l	#11,d0
	bsr	do_wrt_cmn_l		*データ長
	move.l	#$f041_0042,d0
	lsl.w	#8,d2			*dev ID
	or.w	d2,d0
	bsr	do_wrt_cmn_l		*header
	move.l	#$12_00007f,d0
	bsr	do_wrt_cmn_l		*cmd,addr
	tst.b	d3
	bne	@f
	move.w	#$0001,d0		*mode,checksum
	bsr	do_wrt_cmn_w
	moveq.l	#$f7,d0			*EOX
	bsr	do_wrt_cmn_b
	jmp	cmpl_lp
@@:
	move.w	#$0100,d0		*mode,checksum
	bsr	do_wrt_cmn_w
	moveq.l	#$f7,d0			*EOX
	bsr	do_wrt_cmn_b
	jmp	cmpl_lp

mml_mt32_reset:				*[MT32_RESET]
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*>d2=DEV ID
	bsr	mt32_id_set
	moveq.l	#exclusive_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#MKID_ROLAND,d0
	bsr	do_wrt_trk_b
	moveq.l	#10,d1
	lea	sct_mt32reset(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment
	moveq.l	#4,d0
	bsr	do_wrt_trk_l		*データ長
	move.l	#$7f0000_00,d0
	bra	do_wrt_trk_l		*転送データ

mt32_reset:				*.MT32_INIT
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*d1=I/F number,d2=DEV ID
	move.l	d1,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#10,d1
	lea	sct_mt32reset(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment
	moveq.l	#11,d0
	bsr	do_wrt_cmn_l		*データ長
	lea	header(pc),a1		*送信パック作成
	move.b	d2,2(a1)		*dev ID
	move.b	#$16,3(a1)		*model ID
	move.b	#$7f,5(a1)
	move.l	#$0000_0001,6(a1)
	moveq.l	#11-1,d1
@@:					*データ本体の書き込み
	move.b	(a1)+,d0
	bsr	do_wrt_cmn_b
	dbra	d1,@b
	jmp	cmpl_lp

mml_mt32_partial_reserve:		*[MT32_PARTIAL_RESERVE]
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*>d2=DEV ID
	bsr	mt32_id_set
	moveq.l	#exclusive_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#MKID_ROLAND,d0
	bsr	do_wrt_trk_b
	moveq.l	#20,d1
	lea	sct_mt32prsv(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_mt32ptlrsv		*送信パケット生成
	moveq.l	#3+9,d0
	bsr	do_wrt_trk_l		*データ長
	move.l	temp_buffer(pc),a1
	moveq.l	#3+9-1,d1
@@:
	move.b	(a1)+,d0
	bsr	do_wrt_trk_b
	dbra	d1,@b
	rts

mt32_partial_reserve:			*.MT32_PARTIAL_RESERVE(SC55ボイスリザーブ)
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*d1=I/F number,d2=DEV ID
	move.l	d1,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#20,d1
	lea	sct_mt32prsv(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_mt32ptlrsv		*送信パケット生成
	move.l	#8+9+2,d0
	bsr	do_wrt_cmn_l		*データ長
	move.l	temp_buffer(pc),a1
	moveq.l	#8+9+2-1,d1
@@:
	move.b	(a1)+,d0
	bsr	do_wrt_cmn_b
	dbra	d1,@b
	jmp	cmpl_lp

do_mt32ptlrsv:			*MT32パーシャルリザーブパラメータ取得&MIDIメッセージ作成
	* < d2=DEV ID
	* > temp_buffer
	* x d0-d3/a1-a2
	move.l	temp_buffer(pc),a2
	move.w	#$f041,(a2)+
	move.b	d2,(a2)+		*set dev ID
	move.b	#$42,(a2)+		*set model id
	move.l	#$12_10004,(a2)+	*cmd,addr
	moveq.l	#9,d1
	suba.l	a1,a1
	bsr	get_arry_params		*{}で囲まれた数値の取得 (< d1 n of data/> d1=n of data)
	subq.l	#1,d1
	cmpi.l	#8,d1
	bne	m_illegal_parameter_format	*パラメータは必ず９個
	moveq.l	#9-1,d1
	moveq.l	#$14,d3			*address sum
	bra	set_arry_data

mml_mt32_reverb:			*[MT32_REVERB]
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*>d2=DEV ID
	bsr	mt32_id_set
	moveq.l	#exclusive_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#MKID_ROLAND,d0
	bsr	do_wrt_trk_b
	moveq.l	#11,d1
	lea	sct_mt32rvb(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_mt32rvb		*送信パケット生成 > d1.l=packet length
	bra	set_rdexml

mt32_reverb:				*.MT32_REVERB
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*d1=I/F number,d2=DEV ID
	move.l	d1,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#11,d1
	lea	sct_mt32rvb(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_mt32rvb		*送信パケット生成 > d1.l=packet length
	bra	set_rdexshp

do_mt32rvb:				*MT32リバーブパラメータ取得&MIDIメッセージ作成
	* < d2=DEV ID
	* > temp_buffer
	* > d1=packet length(1～)
	* x d0-d3/a1-a2
	move.l	temp_buffer(pc),a2
	move.w	#$f041,(a2)+
	move.b	d2,(a2)+		*set dev ID
	move.b	#$16,(a2)+		*set model id
	move.l	#$12_100001,(a2)+	*cmd,addr
	moveq.l	#3,d1
	lea	mt32rvb_limit(pc),a1
	bsr	get_arry_params		*{}で囲まれた数値の取得(< d1 n of data/> d1=n of data)
	subq.l	#1,d1
	bcs	m_parameter_cannot_be_omitted	*パラメータは最低１個
	moveq.l	#$11,d3
	bra	set_arry_data

mt32rvb_limit:	dc.b	0,3,0,7,0,7,-1
	.even

mml_mt32_part_setup:			*[MT32_PART_SETUP]
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*>d2=DEV ID
	bsr	mt32_id_set
	moveq.l	#exclusive_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#MKID_ROLAND,d0
	bsr	do_wrt_trk_b
	moveq.l	#15,d1
	lea	sct_mt32ptstup(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_mt32ptstup		*送信パケット生成 > d1.l=packet length
	bra	set_rdexml

mt32_part_setup:			*.MT32_PART_SETUP
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*d1=I/F number,d2=DEV ID
	move.l	d1,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#15,d1
	lea	sct_mt32ptstup(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_mt32ptstup		*送信パケット生成 > d1.l=packet length
	bra	set_rdexshp

do_mt32ptstup:				*MT32パートセットアップパラメータ取得&MIDIメッセージ作成
	* < d2=DEV ID
	* > temp_buffer
	* > d1=packet length(1～)
	* x d0-d3/a1-a2
	move.l	temp_buffer(pc),a2
	move.w	#$f041,(a2)+
	move.b	d2,(a2)+		*set dev ID
	move.b	#$16,(a2)+		*set model id
	move.l	#$12_10000d,(a2)+	*cmd,addr
	moveq.l	#9,d1
	suba.l	a1,a1
	bsr	get_arry_params		*{}で囲まれた数値の取得(< d1 n of data/> d1=n of data)
	subq.l	#1,d1
	bcs	m_parameter_cannot_be_omitted	*パラメータは最低１個
	move.l	arry_stock(pc),a1
	moveq.l	#$1d,d3
domt32ptstuplp:
	move.b	(a1)+,d0
	cmpi.b	#$0f,d0
	bls	@f
	moveq.l	#$10,d0			*0-15以外はOFFとみなす
@@:
	add.b	d0,d3
	move.b	d0,(a2)+
	dbra	d1,domt32ptstuplp
	bra	calcset_exsm

mml_mt32_drum_setup:			*[MT32_DRUM_SETUP]
	bsr	get_ky_devid_ifn	*>d2=DEV ID,d3.w=key
	bsr	mt32_id_set
	moveq.l	#exclusive_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#MKID_ROLAND,d0
	bsr	do_wrt_trk_b
	moveq.l	#15,d1
	lea	sct_mt32drmstup(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_mt32drmstup		*送信パケット生成 > d1.l=packet length
	bra	set_rdexml

mt32_drum_setup:			*.MT32_DRUM_SETUP
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	bsr	get_ky_devid_ifn	*d1=I/F number,d2=DEV ID,d3.w=key
	move.l	d1,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#15,d1
	lea	sct_mt32drmstup(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_mt32drmstup		*送信パケット生成 > d1.l=packet length
	bra	set_rdexshp

do_mt32drmstup:				*MT32リズムセットアップパラメータ取得&MIDIメッセージ作成
	* < d2=DEV ID
	* < d3=key number(0-127)
	* > temp_buffer
	* > d1=packet length(1～)
	* x d0-d3/a1-a2
	move.l	#$12_030110,d5
	add.w	d3,d3
	add.w	d3,d3
	add.w	d3,d5
	bclr.l	#7,d5
	beq	@f
	add.w	#$0100,d5
@@:
	move.l	temp_buffer(pc),a2
	move.w	#$f041,(a2)+
	move.b	d2,(a2)+		*set dev ID
	move.b	#$16,(a2)+		*set model id
	move.l	d5,(a2)+		*cmd,addr
	moveq.l	#4,d1
	lea	mt32drmstup_limit(pc),a1
	bsr	get_arry_params		*{}で囲まれた数値の取得(< d1 n of data/> d1=n of data)
	subq.l	#1,d1
	bcs	m_parameter_cannot_be_omitted	*パラメータは最低１個
	swap	d5
	move.b	d5,d3
	swap	d5
	ror.w	#8,d5
	add.b	d5,d3
	ror.w	#8,d5
	add.b	d5,d3			*d3=address sum
	bra	set_arry_data

mt32drmstup_limit:	dc.b	0,127,0,100,0,14,0,1,-1
	.even

mml_mt32_common:			*[MT32_COMMON]
	bsr	get_tm_devid_ifn	*>d2=DEV ID,d3.w=timbre number
	bsr	mt32_id_set
	moveq.l	#exclusive_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#MKID_ROLAND,d0
	bsr	do_wrt_trk_b
	moveq.l	#11,d1
	lea	sct_mt32cmn(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_mt32cmn		*送信パケット生成 > d1.l=packet length
	bra	set_rdexml

mt32_common:				*.MT32_COMMON
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	bsr	get_tm_devid_ifn	*d1=I/F number,d2=DEV ID,d3.w=timbre number
	move.l	d1,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#11,d1
	lea	sct_mt32cmn(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_mt32cmn		*送信パケット生成 > d1.l=packet length
	bra	set_rdexshp

do_mt32cmn:				*MT32コモンパラメータ取得&MIDIメッセージ作成
	* < d2=DEV ID
	* < d3=timbre number(0-63)
	* > temp_buffer
	* > d1=packet length(1～)
	* x d0-d3/a1-a2
	move.l	#$12_080000,d5
	ror.w	#7,d3
	move.w	d3,d5
	move.l	temp_buffer(pc),a2
	move.w	#$f041,(a2)+
	move.b	d2,(a2)+		*set dev ID
	move.b	#$16,(a2)+		*set model id
	move.l	d5,(a2)+		*cmd,addr
	swap	d5
	move.b	d5,d3
	swap	d5
	ror.w	#8,d5
	add.b	d5,d3
	ror.w	#8,d5
	add.b	d5,d3			*d3=address sum
	moveq.l	#10,d1			*10文字分ほしい(足りない分は' 'で埋めてもらえる)
	bsr	get_string_param2
	moveq.l	#10-1,d1
	move.l	arry_stock(pc),a1
@@:
	move.b	(a1)+,d0
	add.b	d0,d3
	move.b	d0,(a2)+		*文字パラメータ
	dbra	d1,@b
	moveq.l	#4,d1
	lea	mt32cmn_limit(pc),a1
	bsr	get_arry_params		*{}で囲まれた数値の取得(< d1 n of data/> d1=n of data)
	move.l	arry_stock(pc),a1
	subq.l	#1,d1
	bcs	m_parameter_cannot_be_omitted	*パラメータは最低１個
@@:
	move.b	(a1)+,d0
	add.b	d0,d3
	move.b	d0,(a2)+
	dbra	d1,@b
	bra	calcset_exsm

mt32cmn_limit:	dc.b	0,12,0,12,0,15,0,1,-1
	.even

mml_mt32_partial:			*[MT32_PARTIAL]
	bsr	get_tm_pt_devid_ifn	*>d2=DEV ID,d3.hw=timbre,d3.lw=partial
	bsr	mt32_id_set
	moveq.l	#exclusive_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#MKID_ROLAND,d0
	bsr	do_wrt_trk_b
	moveq.l	#12,d1
	lea	sct_mt32ptl(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_mt32ptl		*送信パケット生成 > d1.l=packet length
	bra	set_rdexml

mt32_partial:				*.MT32_PARTIAL
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	bsr	get_tm_pt_devid_ifn	*d1=I/F number,d2=DEV ID,d3.hw=timbre,d3.lw=partial
	move.l	d1,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#12,d1
	lea	sct_mt32ptl(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_mt32ptl		*送信パケット生成 > d1.l=packet length
	bra	set_rdexshp

do_mt32ptl:				*MT32パーシャルパラメータ取得&MIDIメッセージ作成
	* < d2=DEV ID
	* < d3.hw=timbre number(0-63)
	* < d3.lw=partial number(0-3)
	* > temp_buffer
	* > d1=packet length(1～)
	* x d0-d3/a1-a2
	move.l	#$12_080000,d5
	move.w	d3,d1
	swap	d3
	ext.w	d3
	ror.w	#7,d3
	move.w	d3,d5
	mulu	#58,d1
	add.w	#$0e,d1
	move.b	d1,d5
	andi.b	#$7f,d5
	add.w	d1,d1
	andi.w	#$7f00,d1
	add.w	d1,d5
	move.l	temp_buffer(pc),a2
	move.w	#$f041,(a2)+
	move.b	d2,(a2)+		*set dev ID
	move.b	#$16,(a2)+		*set model id
	move.l	d5,(a2)+		*cmd,addr
	moveq.l	#58,d1
	lea	mt32ptl_limit(pc),a1
	bsr	get_arry_params		*{}で囲まれた数値の取得(< d1 n of data/> d1=n of data)
	subq.l	#1,d1
	bcs	m_parameter_cannot_be_omitted	*パラメータは最低１個
	swap	d5
	move.b	d5,d3
	swap	d5
	ror.w	#8,d5
	add.b	d5,d3
	ror.w	#8,d5
	add.b	d5,d3			*d3=address sum
	bra	set_arry_data

mt32ptl_limit:
	dc.b	0,96
	dc.b	0,100
	dc.b	0,16
	dc.b	0,1
	dc.b	0,3
	dc.b	0,127
	dc.b	0,100
	dc.b	0,14
	dc.b	0,10
	dc.b	0,3
	dc.b	0,4
	rept	13
	dc.b	0,100
	endm
	dc.b	0,30
	dc.b	0,14
	dc.b	0,127
	dc.b	0,14
	dc.b	0,100
	dc.b	0,100
	dc.b	0,4
	dc.b	0,4
	rept	11
	dc.b	0,100
	endm
	dc.b	0,127
	dc.b	0,12
	dc.b	0,127
	dc.b	0,12
	dc.b	0,4
	dc.b	0,4
	rept	9
	dc.b	0,100
	endm
	dc.b	-1
	.even

mml_mt32_patch:				*[MT32_PATCH]
	bsr	get_ptch_devid_ifn	*>d2=DEV ID,d3.w=patch number
	bsr	mt32_id_set
	moveq.l	#exclusive_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#MKID_ROLAND,d0
	bsr	do_wrt_trk_b
	moveq.l	#10,d1
	lea	sct_mt32ptch(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_mt32ptch		*送信パケット生成 > d1.l=packet length
	bra	set_rdexml

mt32_patch:				*.MT32_PATCH
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	bsr	get_ptch_devid_ifn	*d1=I/F number,d2=DEV ID,d3.w=patch number
	move.l	d1,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#10,d1
	lea	sct_mt32ptch(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_mt32ptch		*送信パケット生成 > d1.l=packet length
	bra	set_rdexshp

do_mt32ptch:				*MT32パッチパラメータ取得&MIDIメッセージ作成
	* < d2=DEV ID
	* < d3=timbre number(0-127)
	* > temp_buffer
	* > d1=packet length(1～)
	* x d0-d3/a1-a2
	move.l	#$12_050000,d5
	lsl.w	#3,d3			*d3=d3*8
	move.b	d3,d5
	andi.b	#$7f,d5
	add.w	d3,d3
	andi.w	#$7f00,d3
	add.w	d3,d5
	move.l	temp_buffer(pc),a2
	move.w	#$f041,(a2)+
	move.b	d2,(a2)+		*set dev ID
	move.b	#$16,(a2)+		*set model id
	move.l	d5,(a2)+		*cmd,addr
	moveq.l	#7,d1
	lea	mt32ptch_limit(pc),a1
	bsr	get_arry_params		*{}で囲まれた数値の取得(< d1 n of data/> d1=n of data)
	subq.l	#1,d1
	bcs	m_parameter_cannot_be_omitted	*パラメータは最低１個
	swap	d5
	move.b	d5,d3
	swap	d5
	ror.w	#8,d5
	add.b	d5,d3
	ror.w	#8,d5
	add.b	d5,d3			*d3=address sum
	bra	set_arry_data

mt32ptch_limit:	dc.b	0,3,0,63,0,48,0,100,0,24,0,3,0,1,-1
	.even

mml_mt32_print:				*[MT32_PRINT]
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*>d2=DEV ID
	bsr	mt32_id_set
	moveq.l	#exclusive_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#MKID_ROLAND,d0
	bsr	do_wrt_trk_b
	moveq.l	#10,d1
	lea	sct_mt32prt(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_mt32prt		*送信パケット生成 > d1.l=packet length
	bra	set_rdexml

mt32_print:				*.MT32_PRINT
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*d1=I/F number,d2=DEV ID
	move.l	d1,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#10,d1
	lea	sct_mt32prt(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_mt32prt		*送信パケット生成 > d1.l=packet length
	bra	set_rdexshp

do_mt32prt:				*MT32文字列出力パラメータ取得&MIDIメッセージ作成
	* < d2=DEV ID
	* > temp_buffer
	* > d1=packet length(1～)
	* x d0-d3/a1-a2
	move.l	temp_buffer(pc),a2
	move.w	#$f041,(a2)+
	move.b	d2,(a2)+		*set dev ID
	move.b	#$16,(a2)+		*set model id
	move.l	#$12_200000,(a2)+	*cmd,addr
	moveq.l	#20,d1			*最大文字列長
	bsr	get_string_param	*""で囲まれた文字列の取得(< d1 n of data/> d1=n of data)
	subq.l	#1,d1
	bcs	m_parameter_cannot_be_omitted	*パラメータは最低１個
	moveq.l	#$10,d3			*address sum
	bra	set_arry_data

mml_u220_setup:				*[U220_SETUP]
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*>d2=DEV ID
	bsr	u220_id_set
	moveq.l	#exclusive_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#MKID_ROLAND,d0
	bsr	do_wrt_trk_b
	moveq.l	#10,d1
	lea	sct_u220stup(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_u220stup		*送信パケット生成 > d1.l=packet length
	bra	set_rdexml

u220_setup:				*.U220_SETUP
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*d1=I/F number,d2=DEV ID
	move.l	d1,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#10,d1
	lea	sct_u220stup(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_u220stup		*送信パケット生成 > d1.l=packet length
	bra	set_rdexshp

do_u220stup:				*U220セットアップパラメータ取得&MIDIメッセージ作成
	* < d2=DEV ID
	* > temp_buffer
	* > d1=packet length(1～)
	* x d0-d3/a1-a2
	move.l	temp_buffer(pc),a2
	move.w	#$f041,(a2)+
	move.b	d2,(a2)+		*set dev ID
	move.b	#$2b,(a2)+		*set model id
	move.l	#$12_000000,d0
	move.l	d0,(a2)+		*cmd,addr
	moveq.l	#7,d1
	lea	u220stup_limit(pc),a1
	bsr	get_arry_params		*{}で囲まれた数値の取得(< d1 n of data/> d1=n of data)
	subq.l	#1,d1
	cmpi.l	#6,d1
	bne	m_illegal_parameter_format	*パラメータは必ず7個
	move.l	arry_stock(pc),a1
	move.l	#$0e07_0a00,d1
	moveq.l	#$0e+$07+$0a,d3			*address sum=0,data sum=$0e+$07+$0a
	moveq.l	#0,d0
	tst.b	(a1)+				*chorus sw
	beq	@f
	moveq.l	#2,d0
@@:
	or.b	d0,d1
	moveq.l	#0,d0
	tst.b	(a1)+				*reverb sw
	beq	@f
	moveq.l	#1,d0
@@:
	or.b	d0,d1
	move.l	d1,(a2)+			*440.0Hz,LCD=10,cho/rvb sw
	add.b	d1,d3				*下位バイトをSUMに加算
	clr.l	(a2)+				*dummy
	move.b	(a1)+,d0			*Rx_ctrl CH
	subq.b	#1,d0
	cmpi.b	#$0f,d0
	bls	@f
	moveq.l	#$10,d0				*規定外値はすべてOFFとみなす
@@:
	bsr	stu2_dt
	clr.b	(a2)+				*dummy
	clr.b	(a2)+				*dummy
	moveq.l	#4-1,d2
@@:
	move.b	(a1)+,d0
	add.b	d0,d3		*add into sum
	move.b	d0,(a2)+	*patch change,timbre change,rythm change,Rx.R.inst Assign
	dbra	d2,@b
	bra	calcset_exsm

u220stup_limit:	dc.b	0,1,0,1,0,127,0,5,0,5,0,5,0,5,-1
	.even

stu2_dtw:			*set data その２
	* < a2.l=buffer address
	* < d0.w=data
	bsr	stu2_dt
	lsr.w	#8,d0
stu2_dt:					*U220送信パケット生成サブルーチン
	* < a2.l=buffer address
	* < d0.b=data
	* < d3.b=sum
	move.b	d0,-(sp)
	andi.b	#$0f,d0
	move.b	d0,(a2)+
	add.b	d0,d3				*sum
	move.b	(sp)+,d0
	lsr.b	#4,d0
	move.b	d0,(a2)+
	add.b	d0,d3				*sum
	rts

mml_u220_part_setup:				*[U220_PART_SETUP]
	bsr	get_pt_devid_ifn	*>d2=DEV ID,d3.w=part number
	bsr	u220_id_set
	moveq.l	#exclusive_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#MKID_ROLAND,d0
	bsr	do_wrt_trk_b
	moveq.l	#15,d1
	lea	sct_u220ptstup(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_u220ptstup		*送信パケット生成 > d1.l=packet length
	bra	set_rdexml

u220_part_setup:				*.U220_PART_SETUP
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	bsr	get_pt_devid_ifn	*d1=I/F number,d2=DEV ID,d3.w=part number
	move.l	d1,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#15,d1
	lea	sct_u220ptstup(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_u220ptstup		*送信パケット生成 > d1.l=packet length
	bra	set_rdexshp

do_u220ptstup:				*U220パートセットアップパラメータ取得&MIDIメッセージ作成
	* < d2=DEV ID
	* < d3=timbre number(0-5)
	* > temp_buffer
	* > d1=packet length(1～)
	* x d0-d3/a1-a2
	move.l	#$12_00003c,d5		cmd,addr
	lsl.w	#4,d3			*d3=d3*16
	add.w	d3,d5
	move.l	d5,d3
	andi.b	#$7f,d3
	add.w	d5,d5
	andi.w	#$7f00,d5
	move.b	d3,d5
	ori.w	#$0600,d5		*d5=exact address
	move.l	temp_buffer(pc),a2
	move.w	#$f041,(a2)+
	move.b	d2,(a2)+		*set dev ID
	move.b	#$2b,(a2)+		*set model id
	move.l	d5,(a2)+		*cmd,addr
	moveq.l	#13,d1
	lea	u220ptstup_limit(pc),a1
	bsr	get_arry_params		*{}で囲まれた数値の取得(< d1 n of data/> d1=n of data)
	subq.l	#1,d1
	cmpi.l	#12,d1
	bne	m_illegal_parameter_format	*パラメータはかならず13個
	swap	d5
	move.b	d5,d3
	swap	d5
	ror.w	#8,d5
	add.b	d5,d3
	ror.w	#8,d5
	add.b	d5,d3			*d3=address sum

	move.l	arry_stock(pc),a1
	move.b	(a1),d0		*timbre number
	subq.b	#1,d0		*1～128→0～127
	move.b	10(a1),d1	*Rx.volume
	lsl.b	#7,d1
	or.b	d1,d0
	bsr	stu2_dt

	move.b	1(a1),d0	*v reserve
	move.b	7(a1),d1	*out assign
	lsl.b	#5,d1
	or.b	d1,d0
	bsr	stu2_dt

	moveq.l	#0,d0
	move.b	2(a1),d0	*midi ch
	subq.b	#1,d0
	cmpi.b	#$0f,d0
	bls	@f
	moveq.l	#$10,d0		*規定外OFFとみなす
@@:
	moveq.l	#0,d1
	move.b	8(a1),d1	*part level
	lsl.w	#5,d1
	or.w	d1,d0
	move.b	9(a1),d1	*part pan
	swap	d1
	lsr.l	#4,d1
	or.w	d1,d0
	bsr	stu2_dtw	*2bytes書き込み

	move.b	3(a1),d0	*k.range low
	move.b	12(a1),d1	*Rx.HOLD
	lsl.b	#7,d1
	or.b	d1,d0
	bsr	stu2_dt

	move.b	4(a1),d0	*k.range hi
	move.b	11(a1),d1	*Rx.PAN
	lsl.b	#7,d1
	or.b	d1,d0
	bsr	stu2_dt

	move.b	5(a1),d0	*velo level
	bsr	stu2_dt
	move.b	6(a1),d0	*velo threshold
	bsr	stu2_dt
	bra	calcset_exsm

u220ptstup_limit:
	dc.b	1,128
	dc.b	0,30
	dc.b	1,17
	rept	2
	dc.b	0,127
	endm
	dc.b	0,1
	dc.b	0,127
	dc.b	0,4
	dc.b	0,127
	dc.b	0,15
	dc.b	0,1
	dc.b	0,1
	dc.b	0,1
	dc.b	-1
	.even

mml_u220_common:			*[U220_COMMON]
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*>d2=DEV ID
	bsr	u220_id_set
	moveq.l	#exclusive_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#MKID_ROLAND,d0
	bsr	do_wrt_trk_b
	moveq.l	#11,d1
	lea	sct_u220cmn(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_u220cmn		*送信パケット生成 > d1.l=packet length
	bra	set_rdexml

u220_common:				*.U220_COMMON
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*d1=I/F number,d2=DEV ID
	move.l	d1,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#11,d1
	lea	sct_u220cmn(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_u220cmn		*送信パケット生成 > d1.l=packet length
	bra	set_rdexshp

do_u220cmn:				*U220コモンパラメータ取得&MIDIメッセージ作成
	* < d2=DEV ID
	* > temp_buffer
	* > d1=packet length(1～)
	* x d0-d3/a1-a2
	move.l	temp_buffer(pc),a2
	move.w	#$f041,(a2)+
	move.b	d2,(a2)+		*set dev ID
	move.b	#$2b,(a2)+		*set model id
	move.l	#$12_000618,d0
	move.l	d0,(a2)+		*cmd,addr
	moveq.l	#18,d1
	lea	u220cmn_limit(pc),a1
	bsr	get_arry_params		*{}で囲まれた数値の取得(< d1 n of data/> d1=n of data)
	subq.l	#1,d1
	cmpi.l	#17,d1
	bne	m_illegal_parameter_format	*パラメータは必ず7個
	move.l	arry_stock(pc),a1
	moveq.l	#$06+$18,d3		*address sum=0,data sum=$06+$18
	moveq.l	#0,d0
	move.b	4(a1),d0	*cho rate
	moveq.l	#0,d1
	move.b	2(a1),d1	*cho level
	lsl.w	#6,d1
	or.w	d1,d0
	move.b	5(a1),d1	*cho depth
	swap	d1		*lsl.l	#16,d1
	lsr.l	#5,d1
	or.w	d1,d0
	bsr	stu2_dtw

	moveq.l	#0,d0
	move.b	8(a1),d0	*rev time
	moveq.l	#0,d1
	move.b	6(a1),d1	*cho FB
	lsl.w	#7,d1
	or.w	d1,d0
	move.b	(a1),d1		*cho type
	swap	d1
	lsr.l	#3,d1
	or.w	d1,d0
	bsr	stu2_dtw

	moveq.l	#0,d0
	move.b	3(a1),d0	*cho delay time
	moveq.l	#0,d1
	move.b	10(a1),d1	*rev FB
	swap	d1
	lsr.l	#5,d1
	or.w	d1,d0
	bsr	stu2_dtw

	moveq.l	#0,d0
	move.b	9(a1),d0	*rev level
	moveq.l	#0,d1
	move.b	11(a1),d1	*pre rev dly time
	lsl.w	#6,d1
	or.w	d1,d0
	move.b	7(a1),d1	*rev type
	swap	d1
	lsr.l	#4,d1
	or.w	d1,d0
	add.w	d0,d0		*lsl.w	#1,d0
	move.b	1(a1),d1	*out mode
	lsr.b	#1,d1
	roxr.w	#1,d0
	bsr	stu2_dtw

	lea	12(a1),a1
	moveq.l	#3-1,d2
@@:
	move.b	(a1)+,d0	*ctrl #1-3
	ror.w	#8,d0
	move.b	(a1)+,d0	*parameter #1-3
	ror.w	#8,d0
	bsr	stu2_dtw
	dbra	d2,@b
	bra	calcset_exsm

u220cmn_limit:
	dc.b	0,4
	dc.b	0,1
	rept	4
	dc.b	0,31
	endm
	dc.b	1,63
	dc.b	0,7
	rept	4
	dc.b	0,31
	endm
	rept	3
	dc.b	0,63
	dc.b	0,18
	endm
	.even

mml_u220_timbre:			*[U220_TIMBRE]
	bsr	get_tmb_devid_ifn	*>d2=DEV ID,d3.w=timbre number
	bsr	u220_id_set
	moveq.l	#exclusive_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#MKID_ROLAND,d0
	bsr	do_wrt_trk_b
	moveq.l	#11,d1
	lea	sct_u220tmb(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_u220tmb		*送信パケット生成 > d1.l=packet length
	bra	set_rdexml

u220_timbre:				*.U220_TIMBRE
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	bsr	get_tmb_devid_ifn	*d1=I/F number,d2=DEV ID,d3.w=timbre number
	move.l	d1,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#11,d1
	lea	sct_u220tmb(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_u220tmb		*送信パケット生成 > d1.l=packet length
	bra	set_rdexshp

do_u220tmb:				*U220ティンバーパラメータ取得&MIDIメッセージ作成
	* < d2=DEV ID
	* < d3=timbre number(0-127)
	* > temp_buffer
	* > d1=packet length(1～)
	* x d0-d3/a1-a2
	move.l	#0,d5
	lsl.w	#6,d3
	move.w	d3,d5
	andi.b	#$7f,d3
	add.l	d5,d5
	move.b	d3,d5
	add.l	#$12_020000,d5		*cmd,addr
	move.l	temp_buffer(pc),a2
	move.w	#$f041,(a2)+
	move.b	d2,(a2)+		*set dev ID
	move.b	#$2b,(a2)+		*set model id
	move.l	d5,(a2)+		*cmd,addr
	swap	d5
	move.b	d5,d3
	swap	d5
	ror.w	#8,d5
	add.b	d5,d3
	ror.w	#8,d5
	add.b	d5,d3			*d3=address sum
	moveq.l	#12,d1			*12文字分ほしい(足りない分は' 'で埋めてもらえる)
	bsr	get_string_param2
	moveq.l	#12-1,d1
	move.l	arry_stock(pc),a1
@@:
	move.b	(a1)+,d0
	add.b	d0,d3
	move.b	d0,(a2)+		*文字パラメータ
	dbra	d1,@b
	moveq.l	#26,d1
	lea	u220tmb_limit(pc),a1
	bsr	get_arry_params		*{}で囲まれた数値の取得(< d1 n of data/> d1=n of data)
	subq.l	#1,d1
	cmpi.l	#25,d1
	bne	m_illegal_parameter_format	*パラメータは最低１個
	move.l	arry_stock(pc),a1
					*音色パラメータ本体
	moveq.l	#0,d0
	move.b	1(a1),d0		*tone #
	subq.b	#1,d0
	moveq.l	#0,d1
	move.b	(a1),d1			*tone Meida
	lsl.w	#7,d1
	or.w	d1,d0
	move.b	17(a1),d1		*detune depth
	swap	d1
	lsr.l	#4,d1
	or.w	d1,d0
	bsr	stu2_dtw

	move.b	3(a1),d0		*level velo sens
	move.b	4(a1),d1		*level ch aft
	lsl.b	#4,d1
	or.b	d1,d0
	bsr	stu2_dt
	move.b	2(a1),d0		*timbre level
	bsr	stu2_dt

	move.b	5(a1),d0		*Env A
	move.b	6(a1),d1		*Env D
	lsl.b	#4,d1
	or.b	d1,d0
	bsr	stu2_dt
	move.b	7(a1),d0		*Env S
	move.b	8(a1),d1		*Env R
	lsl.b	#4,d1
	or.b	d1,d0
	bsr	stu2_dt

	move.b	10(a1),d0		*Pitch fine
	bsr	stu2_dt
	move.b	09(a1),d0		*Pitch coarse
	bsr	stu2_dt

	moveq.l	#0,d0
	move.b	11(a1),d0		*Bend lower
	moveq.l	#0,d1
	move.b	12(a1),d1		*Bend upper
	lsl.w	#5,d1
	or.w	d1,d0
	move.b	15(a1),d1		*Auto Bend depth
	swap	d1
	lsr.l	#7,d1
	or.w	d1,d0
	bsr	stu2_dtw

	moveq.l	#0,d0
	move.b	14(a1),d0		*Pitch poly aft
	moveq.l	#0,d1
	move.b	13(a1),d1		*Pitch ch aft
	lsl.w	#5,d1
	or.w	d1,d0
	move.b	16(a1),d1		*Auto Bend rate
	swap	d1
	lsr.l	#6,d1
	or.w	d1,d0
	bsr	stu2_dtw

	move.b	23(a1),d0		*Mod depth
	lsl.b	#4,d0
	bsr	stu2_dt
	move.b	21(a1),d0		*Vib delay
	move.b	20(a1),d1		*Vib depth
	lsl.b	#4,d1
	or.b	d1,d0
	bsr	stu2_dt

	move.b	18(a1),d0		*Vib rate
	bsr	stu2_dt
	move.b	19(a1),d0		*Vib WF
	bsr	stu2_dt

	move.b	22(a1),d0		*Vib rise
	bsr	stu2_dt
	move.b	24(a1),d0		*Vib ch aft
	move.b	25(a1),d1		*Vib poly aft
	lsl.b	#4,d1
	or.b	d1,d0
	bsr	stu2_dt
	moveq.l	#0,d0			*Dummy
	bsr	stu2_dtw
	bra	calcset_exsm

u220tmb_limit:
	dc.b	0,31
	dc.b	1,128
	dc.b	0,127
	rept	6
	dc.b	1,15
	endm
	dc.b	8,56
	dc.b	14,114
	dc.b	0,15
	dc.b	0,12
	dc.b	0,27
	dc.b	0,27
	dc.b	0,27
	dc.b	0,15
	dc.b	0,15
	dc.b	0,63
	dc.b	0,8
	rept	6
	dc.b	0,15
	endm
	dc.b	-1
	.even

mml_u220_drum_setup:				*[U220_SETUP]
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*>d2=DEV ID
	bsr	u220_id_set
	moveq.l	#exclusive_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#MKID_ROLAND,d0
	bsr	do_wrt_trk_b
	moveq.l	#15,d1
	lea	sct_u220drmstup(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_u220drmstup		*送信パケット生成 > d1.l=packet length
	bra	set_rdexml

u220_drum_setup:				*.U220_SETUP
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*d1=I/F number,d2=DEV ID
	move.l	d1,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#15,d1
	lea	sct_u220drmstup(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_u220drmstup		*送信パケット生成 > d1.l=packet length
	bra	set_rdexshp

do_u220drmstup:			*U220ドラムセットアップパラメータ取得&MIDIメッセージ作成
	* < d2=DEV ID
	* > temp_buffer
	* > d1=packet length(1～)
	* x d0-d3/a1-a2
	move.l	temp_buffer(pc),a2
	move.w	#$f041,(a2)+
	move.b	d2,(a2)+		*set dev ID
	move.b	#$2b,(a2)+		*set model id
	move.l	#$12_000634,d0
	move.l	d0,(a2)+		*cmd,addr
	moveq.l	#7,d1
	lea	u220drmstup_limit(pc),a1
	bsr	get_arry_params		*{}で囲まれた数値の取得(< d1 n of data/> d1=n of data)
	subq.l	#1,d1
	cmpi.l	#6,d1
	bne	m_illegal_parameter_format	*パラメータは必ず7個
	moveq.l	#$06+$34,d3			*address sum
	move.l	arry_stock(pc),a1
	move.b	1(a1),d0		*rythm v rsv
	move.b	(a1),d1			*rythm set number
	lsl.b	#5,d1
	or.b	d1,d0
	bsr	stu2_dt

	move.b	2(a1),d0		*rythm part ch
	subq.b	#1,d0
	cmpi.b	#$0f,d0
	bls	@f
	moveq.l	#$10,d0			*規定外の時はOFFとみなす
@@:
	move.b	6(a1),d1		*rythm part Rx.HOLD
	lsl.b	#5,d1
	or.b	d1,d0
	move.b	5(a1),d1		*rythm part Rx.VOLUME
	lsl.b	#6,d1
	or.b	d1,d0
	bsr	stu2_dt

	move.b	3(a1),d0		*rythm part level
	move.b	4(a1),d1		*rythm part boost sw
	lsl.b	#7,d1
	or.b	d1,d0
	bsr	stu2_dt
	clr.w	(a2)+			*dummy
	bra	calcset_exsm

u220drmstup_limit:	dc.b	0,3,0,30,0,127,0,127,0,1,0,1,0,1,-1
	.even

mml_u220_drum_inst:			*[U220_DRUM_INST]
	bsr	get_nt_devid_ifn	*>d2=DEV ID,d3.w=note number
	bsr	u220_id_set
	moveq.l	#exclusive_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#MKID_ROLAND,d0
	bsr	do_wrt_trk_b
	moveq.l	#14,d1
	lea	sct_u220drminst(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_u220drminst		*送信パケット生成 > d1.l=packet length
	bra	set_rdexml

u220_drum_inst:				*.U220_DRUM_INST
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	bsr	get_nt_devid_ifn	*d1=I/F number,d2=DEV ID,d3.w=note
	move.l	d1,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#14,d1
	lea	sct_u220drminst(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_u220drminst		*送信パケット生成 > d1.l=packet length
	bra	set_rdexshp

do_u220drminst:				*U220リズムインストパラメータ取得&MIDIメッセージ作成
	* < d2=DEV ID
	* < d3=note number(0-127)
	* > temp_buffer
	* > d1=packet length(1～)
	* x d0-d3/a1-a2
	move.l	#$12_110000,d5
	lsl.w	#8,d3
	add.w	d3,d5
	move.l	temp_buffer(pc),a2
	move.w	#$f041,(a2)+
	move.b	d2,(a2)+		*set dev ID
	move.b	#$2b,(a2)+		*set model id
	move.l	d5,(a2)+		*cmd,addr
	moveq.l	#20,d1
	lea	u220drminst_limit(pc),a1
	bsr	get_arry_params		*{}で囲まれた数値の取得(< d1 n of data/> d1=n of data)
	subq.l	#1,d1
	cmpi.l	#19,d1
	bne	m_illegal_parameter_format	*パラメータは必ず20個
	swap	d5
	move.b	d5,d3
	swap	d5
	ror.w	#8,d5
	add.b	d5,d3
	ror.w	#8,d5
	add.b	d5,d3			*d3=address sum
	move.l	arry_stock(pc),a1
	subq.b	#1,1(a1)		*1-128→0-127
@@:
	move.b	(a1)+,d0
	add.b	d0,d3
	move.b	d0,(a2)+
	dbra	d1,@b
	bra	calcset_exsm

u220drminst_limit:
	dc.b	0,31
	dc.b	1,128
	dc.b	0,127
	dc.b	34,98
	dc.b	0,31
	dc.b	0,15
	dc.b	0,1
	dc.b	1,15
	dc.b	1,15
	dc.b	1,15
	dc.b	0,27
	dc.b	14,114
	dc.b	0,27
	dc.b	0,27
	dc.b	0,15
	dc.b	0,27
	dc.b	0,15
	dc.b	0,15
	dc.b	0,3
	dc.b	0,15
	dc.b	-1
	.even

mml_u220_print:				*[U220_PRINT]
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*>d2=DEV ID
	bsr	u220_id_set
	moveq.l	#exclusive_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#MKID_ROLAND,d0
	bsr	do_wrt_trk_b
	moveq.l	#10,d1
	lea	sct_u220prt(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_u220prt		*送信パケット生成 > d1.l=packet length
	bra	set_rdexml

u220_print:				*.U220_PRINT
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	moveq.l	#$10,d1			*omitted case value
	bsr	get_devid_ifn		*d1=I/F number,d2=DEV ID
	move.l	d1,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#10,d1
	lea	sct_u220prt(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment		*コメント書き出し
	bsr	do_u220prt		*送信パケット生成 > d1.l=packet length
	bra	set_rdexshp

do_u220prt:				*U220文字出力パラメータ取得&MIDIメッセージ作成
	* < d2=DEV ID
	* > temp_buffer
	* > d1=packet length(1～)
	* x d0-d3/a1-a2
	move.l	temp_buffer(pc),a2
	move.w	#$f041,(a2)+
	move.b	d2,(a2)+		*set dev ID
	move.b	#$2b,(a2)+		*set model id
	move.l	#$12_000600,(a2)+	*cmd,addr
	moveq.l	#12,d1			*最大文字列長
	bsr	get_string_param	*""で囲まれた文字列の取得(< d1 n of data/> d1=n of data)
	subq.l	#1,d1
	bcs	m_parameter_cannot_be_omitted	*パラメータは最低１個
	moveq.l	#$06,d3			*address sum
	move.l	arry_stock(pc),a1
	moveq.l	#12-1,d1		*12文字に足りない分は' 'で埋めてもらっている
@@:
	move.b	(a1)+,d0
	bsr	stu2_dt
	dbra	d1,@b
	bra	calcset_exsm

mml_m1_setup:				*[M1_SETUP]
do_m1stup:
	* < d2=DEV ID
	* > temp_buffer
	* > d1=packet length(1～)
	* x d0-d3/a1-a2
	moveq.l	#8,d1
	suba.l	a1,a1
	bsr	get_arry_params		*{}で囲まれた数値の取得(< d1 n of data/> d1=n of data)
	cmpi.l	#8,d1
	bne	m_illegal_parameter_format	*パラメータは必ず8個
	move.l	arry_stock(pc),a1
	move.l	temp_buffer(pc),a2
	addq.w	#8,a2
	lea	8(a2),a3
	moveq.l	#8-1,d2		*dbra count
m1_md_lp:
	moveq.l	#03,d1		*ON
	move.b	(a1)+,d0
	subq.b	#1,d0
	cmpi.b	#$0f,d0
	bls	@f
	moveq.l	#0,d0		*一応チャンネル１にする
	moveq.l	#0,d1		*OFF
@@:
	move.b	d0,(a2)+
	move.b	d1,(a3)+
	dbra	d2,m1_md_lp
	rts

m1_setup:				*.M1_SETUP
*	bsr	check_relation_cmn	*コマンド関係チェック
	bsr	do_m1stup		*送信パケット生成 > d1.l=packet length
	jmp	cmpl_lp

mml_m1_part_setup:			*[M1_PART_SETUP]
do_m1ptstup:
	moveq.l	#40,d1
	lea	m1ptstup_limit(pc),a1
	bsr	get_arry_params_w	*{}で囲まれた数値の取得(< d1 n of data/> d1=n of data)
	cmpi.l	#40,d1
	bne	m_illegal_parameter_format	*パラメータは必ず40個
	move.l	arry_stock(pc),a1
	move.l	temp_buffer(pc),a2
	lea	56(a2),a2
	moveq.l	#40-1,d2
@@:
	move.w	(a1)+,d0
	move.b	d0,(a2)+
	dbra	d2,@b
	rts

m1_part_setup:				*.M1_PART_SETUP
*	bsr	check_relation_cmn	*コマンド関係チェック
	bsr	do_m1ptstup		*送信パケット生成 > d1.l=packet length
	jmp	cmpl_lp

m1ptstup_limit:
	rept	8
	dc.l	0,199,0,99,-12,12,-50,50,0,13
	endm
	dc.l	-32768
	.even

mml_m1_effect_setup:			*[M1_EFFECT_SETUP]
do_m1efctstup:
	moveq.l	#25,d1
	lea	m1efctstup_limit(pc),a1
	bsr	get_arry_params_w	*{}で囲まれた数値の取得(< d1 n of data/> d1=n of data)
	cmpi.l	#25,d1
	bne	m_illegal_parameter_format	*パラメータは必ず40個
	move.l	arry_stock(pc),a1
	lea	m1_ef_dflt(pc),a2
	moveq.l	#25-1,d2		*=dbra counter
@@:
	move.w	(a1)+,d0
	move.b	d0,(a2)+
	dbra	d2,@b
	rts

m1_effect_setup:			*.M1_EFFECT_SETUP
*	bsr	check_relation_cmn	*コマンド関係チェック
	bsr	do_m1efctstup		*送信パケット生成 > d1.l=packet length
	jmp	cmpl_lp

m1efctstup_limit:
	dc.l	0,33
	dc.l	0,33
	dc.l	0,100
	dc.l	0,100
	dc.l	0,100
	dc.l	0,100
	dc.l	0,101
	dc.l	0,101
	dc.l	0,%11111
	rept	16
	dc.l	-32767,32767
	endm
	dc.l	-32768
	.even

mml_m1_print:				*[M1_PRINT]
do_m1prt:				*M1文字出力パラメータ取得&MIDIメッセージ作成
	moveq.l	#10,d1			*最大文字列長
	bsr	get_string_param	*""で囲まれた文字列の取得(< d1 n of data/> d1=n of data)
	subq.l	#1,d1
	bcs	m_parameter_cannot_be_omitted	*パラメータは最低１個
	move.l	arry_stock(pc),a1
	move.l	temp_buffer(pc),a2
	lea	20(a2),a2
	moveq.l	#10-1,d1
@@:
	move.b	(a1)+,(a2)+
	dbra	d1,@b
	rts

m1_print:				*.M1_PRINT
*	bsr	check_relation_cmn	*コマンド関係チェック
	bsr	do_m1prt		*送信パケット生成 > d1.l=packet length
	jmp	cmpl_lp

mml_send_to_m1:				*[SEND_TO_M1]
	moveq.l	#midi_transmission_zmd,d0
	bsr	do_wrt_trk_b
	moveq.l	#25,d1
	lea	sct_sndm1(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment
	moveq.l	#$30,d1			*omitted case value
	bsr	get_devid_ifn		*d1=I/F number(dummy),d2=DEV ID
	bsr	do_send_m1		*送信パケット生成 > d1.l=packet length
	moveq.l	#$77,d0
	bsr	do_wrt_trk_l		*データ長
	move.l	temp_buffer(pc),a1
	moveq.l	#$77-1,d1
@@:
	move.b	(a1)+,d0
	bsr	do_wrt_trk_b
	dbra	d1,@b

	moveq.l	#midi_transmission_zmd,d0	*SEQ0に設定する
	bsr	do_wrt_trk_b
	moveq.l	#13,d1
	lea	sct_m1seq0(pc),a1
	lea	do_wrt_trk_b(pc),a2
	bsr	wrt_comment
	moveq.l	#8,d0
	bsr	do_wrt_trk_l		*データ長
	move.l	arry_stock(pc),a1
	moveq.l	#8-1,d1
@@:
	move.b	(a1)+,d0
	bsr	do_wrt_trk_b
	dbra	d1,@b
	rts

send_to_m1:				*.SEND_TO_M1
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	moveq.l	#$30,d1			*omitted case value
	bsr	get_devid_ifn		*d1=I/F number,d2=DEV ID
	move.w	d1,-(sp)
	move.l	d1,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#25,d1
	lea	sct_sndm1(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment
	bsr	do_send_m1		*送信パケット生成 > d1.l=packet length
	moveq.l	#$77,d0
	bsr	do_wrt_cmn_l		*データ長
	moveq.l	#$77-1,d1
@@:
	move.b	(a1)+,d0
	bsr	do_wrt_cmn_b
	dbra	d1,@b

	moveq.l	#CMN_MIDI_TRANSMISSION,d0
	bsr	do_wrt_cmn_b
	move.w	(sp)+,d0
	bsr	do_wrt_cmn_b		*I/F number
	moveq.l	#13,d1
	lea	sct_m1seq0(pc),a1
	lea	do_wrt_cmn_b(pc),a2
	bsr	wrt_comment
	moveq.l	#8,d0
	bsr	do_wrt_cmn_l		*データ長
	move.l	arry_stock(pc),a1
	moveq.l	#8-1,d1
@@:
	move.b	(a1)+,d0
	bsr	do_wrt_cmn_b
	dbra	d1,@b
	jmp	cmpl_lp

do_send_m1:				*設定した各種パラメータをM1へ送信するための
	* < d2.b=m1 id number		*パケットの作成
	* > temp_buffer	parameter packet
	* > arry_stock  mode change packet(GO INTO SEQ0)
	* d0-d2,a1,a2
	move.l	temp_buffer(pc),a1
	move.b	#$f7,$76(a1)		*EOX
	move.l	#$f0420019,(a1)		*header&maker ID,dummy,M1
	move.b	d2,2(a1)		*ID

	move.l	arry_stock(pc),a2	*SEQ-0にするメッセージ作成
	move.l	(a1)+,(a2)+		*HEADER
	move.l	#$4e0600f7,(a2)+	*cmd,mode,bank,EOX

	move.l	#$48_00_0000,(a1)+	*cmd,bank,seq data size
	move.b	#$04,16(a1)		*beat
	move.b	#$78,17(a1)		*tempo/protect
	move.b	#$14,19(a1)		*next song
	clr.b	30(a1)			*nul
	lea	m1_ef_dflt+25(pc),a2
	moveq.l	#25-1,d0
@@:
	move.b	-(a2),31(a1,d0.w)	*エフェクトデータのセット
	dbra	d0,@b

	moveq.l	#96-1,d0			*データ列のならび変え
@@:
	move.l	d0,d1
	divu.w	#7,d1
	add.w	d0,d1
	move.b	(a1,d0.w),1(a1,d1.w)
	dbra	d0,@b

	moveq.l	#0,d2			*MIDIデータへの変換
stmlp:
	moveq.l	#7-1,d1
	moveq.l	#0,d3
@@:
	move.b	1(a1,d1.w),d0
	andi.b	#$7f,1(a1,d1.w)
	lsl.b	#1,d0
	roxl.b	#1,d3
	dbra	d1,@b
	move.b	d3,(a1)
	addq.w	#8,a1
	addq.w	#7,d2
	cmpi.w	#96,d2
	bls	stmlp
	rts

sct_sndm1:	dc.b	'M1 SEQUENCER CONTROL DATA',0
sct_m1seq0:	dc.b	'M1 SEQ-0 MODE',0
	.even
*-----------------------------------------------------------------------------
clc_rest:				*休符のケース($80)
	bsr	get_vlv			*get step
	mulu	clc_trkfrq(pc),d1
	add.l	d1,d5			*st measure
	add.l	d1,d7			*tr total
	tst.b	clc_phase-work(a6)
	ble	@f			*minus or zero
	bsr	calc_play_time
@@:
	bsr	get_vlv
	bra	getzmdlp

clc_track_delay:			*トラックディレイ($84)
clc_wait:				*ウェイトのケース($81)
	bsr	get_vlv			*get step
	mulu	clc_trkfrq(pc),d1
	add.l	d1,d5			*st measure
	add.l	d1,d7			*tr total
	tst.b	clc_phase-work(a6)
	ble	@f			*minus or zero
	bsr	calc_play_time
@@:
	bra	getzmdlp

clc_mx_key:				*MXDRVキーオン($82)
	move.b	(a4)+,d0		*key
	add.b	d0,d4
	bsr	get_vlv			*get step
	mulu	clc_trkfrq(pc),d1
	add.l	d1,d5			*st measure
	add.l	d1,d7			*tr total
	tst.b	clc_phase-work(a6)
	ble	getzmdlp		*minus or zero
	bsr	calc_play_time
	bra	getzmdlp

clc_portament:				*ポルタメント($83)
	move.b	(a4)+,d0		*src note
	add.b	d0,d4
	move.b	(a4)+,d3		*dest note
	add.b	d3,d4
	tst.b	d0
	bpl	@f
	bsr	get_vlv			*delay
@@:
	tst.b	d3
	bpl	@f
	bsr	get_vlv			*get cnt
@@:
	bsr	get_vlv			*step time
	mulu	clc_trkfrq(pc),d1
	add.l	d1,d5			*st measure
	add.l	d1,d7			*tr total
	tst.b	clc_phase-work(a6)
	ble	@f			*minus or zero
	bsr	calc_play_time
@@:
	bsr	get_vlv			*gate time
	add.b	(a4)+,d4		*velocity
	bra	getzmdlp

clc_ch_fader:				*チャンネルフェーダー
	move.b	(a4)+,d0		*type
	lsl.w	#8,d0
	move.b	(a4)+,d0
	add.w	d0,d4
	move.b	(a4)+,d0		*ch
	lsl.w	#8,d0
	move.b	(a4)+,d0
	add.w	d0,d4
ccf00:
	move.b	(a4)+,d0		*omt
	beq	getzmdlp
	add.b	d0,d4
	lsr.b	#1,d0
	bcc	@f
	move.b	(a4)+,d3
	lsl.w	#8,d3
	move.b	(a4)+,d3
	add.w	d3,d4
@@:
	lsr.b	#1,d0
	bcc	@f
	add.b	(a4)+,d4
@@:
	lsr.b	#1,d0
	bcc	getzmdlp
	add.b	(a4)+,d4
	bra	getzmdlp

clc_mstr_fader:				*マスターフェーダー
	move.b	(a4)+,d0		*type
	lsl.w	#8,d0
	move.b	(a4)+,d0
	add.w	d0,d4
	bra	ccf00

clc_bend_@b:				*オートベンド($e0)
clc_bend_@k:				*オートベンド($e1)
	move.b	(a4)+,d0		*omt
	beq	getzmdlp
	bpl	@f
	bsr	ope_word		*src detune
@@:
	add.b	d0,d4			*omt
	add.b	d0,d0			*check omt
	bpl	@f
	bsr	ope_word		*dest detune
@@:
	add.b	d0,d0			*check omt
	bpl	@f
	bsr	ope_word		*delay
@@:
	add.b	d0,d0			*check omt
	bpl	getzmdlp
	bsr	ope_word		*tail
	bra	getzmdlp

clc_auto_portament:			*オートポルタメント
	add.b	(a4)+,d4		*get sw
	move.b	(a4)+,d0		*get omt
	add.b	d0,d4
1:
	tst.b	d0			*check omt
	bpl	@f
	bsr	ope_word
@@:					*skip delay,tail
	add.b	d0,d0
	beq	getzmdlp
	bra	1b

clc_pmod8:				*PMOD振幅(8point)		($e2)
clc_agogik8:				*AGOGIK振幅(8point)		($f0)
	add.b	(a4)+,d4		*get switch
	move.b	(a4)+,d0		*get omt
	beq	getzmdlp		*case:omt=0
clcpm8:
	add.b	d0,d4
clcpm8lp:
	lsr.b	#1,d0
	bcc	@f
	bsr	ope_word		*get depth
@@:
	tst.b	d0
	bne	clcpm8lp
	bra	getzmdlp

clc_arcc_deepen:		*ARCC振幅増加
	add.b	(a4)+,d4	*arcc no.
clc_vseq_deepen:		*VSEQ振幅増加
	move.b	(a4)+,d0	*get omt
	add.b	d0,d4
	tst.b	d0
	bpl	@f
	bsr	get_vlv		*speed
@@:
	add.b	d0,d0
	bpl	@f
	add.b	(a4)+,d4	*depth
@@:
	add.b	d0,d0
	bpl	getzmdlp
	bsr	get_vlv		*repeat time
	bra	getzmdlp

clc_pmod_deepen:		*PMOD振幅増加
clc_agogik_deepen:		*AGOGIK振幅増加
	move.b	(a4)+,d0	*get omt
	add.b	d0,d4
	tst.b	d0
	bpl	@f
	bsr	get_vlv		*speed
@@:
	add.b	d0,d0
	bpl	@f
	bsr	ope_word	*depth
@@:
	add.b	d0,d0
	bpl	getzmdlp
	bsr	get_vlv		*repeat time
	bra	getzmdlp

clc_pmod_speed8:			*PMODスピード(8point)		($e4)
clc_vseq_speed8:			*VSEQスピード(8point)		($ee)
clc_agogik_speed8:			*AGOGIKスピード(8point)		($f2)
	move.b	(a4)+,d0		*get omt
	beq	getzmdlp		*case:omt=0
	add.b	d0,d4
clcps8lp:
	lsr.b	#1,d0
	bcc	@f
	bsr	ope_word		*get depth
@@:
	tst.b	d0
	bne	clcps8lp
	bra	getzmdlp

clc_pmod_delay8:			*PMODディレイ(8point)		($e5)
clc_aftc_delay8:			*ARCCディレイ(8point)		($ec)
clc_vseq_delay8:			*VSEQディレイ(8point)		($ef)
clc_agogik_delay8:			*AGOGIKディレイ(8point)		($f3)
	move.b	(a4)+,d0		*get omt
	lsl.w	#8,d0
	move.b	(a4)+,d0		*get omt
	add.b	d0,d4
cpdl8_lp:
	lsr.w	#1,d0
	bcc	@f
	bsr	ope_word		*get depth
@@:
	tst.w	d0
	bne	cpdl8_lp
	bra	getzmdlp

clc_aftertouch:				*アフタータッチ・シーケンス	($e8)
	add.b	(a4)+,d4		*get switch value
	move.b	(a4)+,d0		*get omt
	beq	getzmdlp		*case:omt=0
	add.b	d0,d4
	add.b	(a4)+,d4		*get rltvmark
1:
	lsr.b	#1,d0
	bcc	@f
	add.b	(a4)+,d4		*get depth
@@:
	tst.b	d0
	bne	1b
	bra	getzmdlp

clc_arcc8:				*ARCC振幅(8point)		($e6)
	add.b	(a4)+,d4		*get arcc number
clc_vseq8:				*エンハンスドベロシティ・シーケンス振幅	($ea)
	add.b	(a4)+,d4		*get switch value
	move.b	(a4)+,d0		*get omt
	beq	getzmdlp		*case:omt=0
	add.b	d0,d4
1:
	lsr.b	#1,d0
	bcc	@f
	add.b	(a4)+,d4		*get depth
@@:
	tst.b	d0
	bne	1b
	bra	getzmdlp

clc_vseq_wf:				*VSEQ波形
	move.b	(a4)+,d0		*get omt
	beq	getzmdlp
	add.b	d0,d4
	lsr.b	#1,d0
	bcc	@f
	add.b	(a4)+,d4		*wave number
	add.b	(a4)+,d4
@@:
	lsr.b	#1,d0
	bcc	@f
	add.b	(a4)+,d4		*default value
@@:
	lsr.b	#1,d0
	bcc	getzmdlp
	add.b	(a4)+,d4		*default value
	bra	getzmdlp

clc_effect_ctrl:			*エフェクト設定			($f4)
	move.b	(a4)+,d0		*get omt
	beq	getzmdlp		*case:omt=0
	add.b	d0,d4
clcvs8lp:
	lsr.b	#1,d0
	bcc	@f
	add.b	(a4)+,d4		*get depth
@@:
	tst.b	d0
	bne	clcvs8lp
	bra	getzmdlp

clc_arcc_speed8:			*ARCCスピード(8point)		($e8)
	add.b	(a4)+,d4		*get arcc number
	bra	clc_pmod_speed8

clc_arcc_delay8:			*ARCCディレイ(8point)		($e9)
	add.b	(a4)+,d4		*get arcc number
	bra	clc_pmod_delay8

clc_event:				*イベント制御
	move.b	(a4)+,d0
	add.b	d0,d4
	lsl.w	#8,d0
	move.b	(a4)+,d0
	add.b	d0,d4
	swap	d0
	move.b	(a4)+,d0
	add.b	d0,d4
	lsl.w	#8,d0
	move.b	(a4)+,d0		*get 4bytes offset
	add.b	d0,d4
	tst.l	d0
	bne	exit_clcevnt
	rept	4
	add.b	(a4)+,d4		*オブジェクトカテゴリ・クラス等をスキップ
	endm
@@:
	tst.b	(a4)+
	bne	@b
	bra	getzmdlp
exit_clcevnt:
	add.l	d0,a4
	bra	getzmdlp

clc_poke:				*ワークエリア直接書き換え	($f5)
clc_rltv_poke:				*ワークエリア直接書き換え	($f6)
	moveq.l	#0,d0
	move.b	(a4)+,d0
	add.b	d0,d4			*checksum
	move.l	d0,d1
	lsr.w	#4,d1			*d1=address count
	andi.w	#$0f,d0			*d0=data count
@@:
	add.b	(a4)+,d4		*checksum
	dbra	d1,@b
@@:
	add.b	(a4)+,d4		*checksum
	dbra	d0,@b
	bra	getzmdlp

clc_timbre_split:			*音色振り分け
	moveq.l	#0,d0
	move.b	(a4)+,d0
	add.w	d0,d4
	add.b	d0,d0			*最上位殺して*2
	beq	getzmdlp
@@:
	add.b	(a4)+,d4		*start note
	add.b	(a4)+,d4		*end note
	add.b	(a4)+,d4		*bank.w
	add.b	(a4)+,d4
	add.b	(a4)+,d4		*timbre.w
	add.b	(a4)+,d4
	subq.w	#2,d0
	bne	@b
	bra	getzmdlp

clc_tempo_t:				*テンポ
	move.b	(a4)+,d1
	lsl.w	#8,d1
	move.b	(a4)+,d1
	add.w	d1,d4
	move.w	d1,clc_tempo-work(a6)
	tst.b	clc_phase-work(a6)
	bne	getzmdlp
	bsr	set_tempo_map		*tempo mapへ登録
	bra	getzmdlp

clc_rltv_t:				*相対テンポ
	move.b	(a4)+,d1
	lsl.w	#8,d1
	move.b	(a4)+,d1
	add.w	d1,d4
	add.w	d1,clc_tempo-work(a6)
	beq	clc_rt_mns		*テンポ0はダメ
	bpl	crt00
	tst.w	d1
	bmi	clc_rt_mns
	move.w	#32767,clc_tempo-work(a6)
	bra	crt00
clc_rt_mns:
	move.w	#1,clc_tempo-work(a6)
crt00:
	move.w	clc_tempo(pc),d1
	tst.b	clc_phase-work(a6)
	bne	getzmdlp
	bsr	set_tempo_map		*tempo mapへ登録
	bra	getzmdlp

set_tempo_map:				*テンポマップ作成
	* < d1.l=tempo value
	move.l	tempo_map_addr(pc),a1
	move.l	(a1)+,d3
	lea	8(a1,d3.l),a0		*end addr
stmplp:
	cmp.l	(a1),d7
	bcs	@f			*元もとセットされていた値より小さいなら
	beq	wrt_tempo_map		*元もとセットされていた値と同じなら
	addq.w	#8,a1			*元もとセットされていた値より大きいなら
	cmp.l	a1,a0
	bne	stmplp
	addq.l	#8,d3
	suba.l	tempo_map_addr(pc),a1
	bsr	enlarge_tempo_map
	adda.l	tempo_map_addr(pc),a1
	bra	wrt_tempo_map
@@:					*潜り込ませる
	addq.l	#8,d3
	move.l	tempo_map_addr(pc),d0
	suba.l	d0,a0
	suba.l	d0,a1
	bsr	enlarge_tempo_map
	move.l	tempo_map_addr(pc),d0
	adda.l	d0,a0
	adda.l	d0,a1
@@:
	move.l	-(a0),8(a0)
	move.l	-(a0),8(a0)
	cmp.l	a1,a0
	bne	@b
wrt_tempo_map:
	move.l	d7,(a1)+		*累積ステップタイム
	move.l	d1,(a1)+		*テンポ値
exit_sttmpmp:
	move.l	tempo_map_addr(pc),a1
	move.l	d3,(a1)
	rts

enlarge_tempo_map:			*テンポマップ拡張
reglist	reg	d0-d3/a0-a1
	movem.l	reglist,-(sp)
	addq.l	#8,d3			*d3は要素を差しているだけなので
	move.l	tempo_map_size(pc),d2	*サイズ値に変換して比較
	cmp.l	d2,d3
	bls	@f
	add.l	#1024,d2		*1kByte分追加確保
	move.l	tempo_map_addr(pc),a1
	bsr	enlarge_mem
	tst.l	d0
	bmi	t_out_of_memory_clc
	move.l	d2,tempo_map_size-work(a6)
	move.l	a0,tempo_map_addr-work(a6)
@@:
	movem.l	(sp)+,reglist
	rts

calc_play_time:				*演奏時間の計算
	* < d1.l=step time
	* x d1,d2,d3,a1
	* - d0
	move.l	tempo_map_addr(pc),a1
	move.l	(a1),a0			*a0.l=tempo map now
cptlp:
	cmp.l	tempo_map_size(pc),a0	*phase2ではtempo_map_sizeは領域終端アドレス
	beq	do_cpt
	cmp.l	8(a0),d7		*次の累積ステップと比較
	bls	do_cpt
	move.l	d7,d2
	sub.l	d1,d2
	move.l	8(a0),d1
*	cmp.l	d2,d1
*	bcs	@f
	sub.l	d2,d1
	bsr	do_cpt
*@@:
	move.l	d7,d1
	addq.w	#8,a0
	sub.l	(a0),d1
	move.l	a0,(a1)
	bra	cptlp

do_cpt:
	move.l	4(a0),d2		*get tempo(まずは累積ステップ境界をまたいだ分に付いて計算)
	mulu	clc_mst_clk(pc),d2	*mst_clk*tempo
	lsl.l	#2,d1			*4
	swap	d1
	clr.w	d1			*65536
	bsr	wari
	add.l	d1,_clc_play_time-work(a6)
	rts

wari:				*32ﾋﾞｯﾄ/32ﾋﾞｯﾄ=32ﾋﾞｯﾄ...32ﾋﾞｯﾄ
	* < d1.l/d2.l=d1.l ...d2.l
	cmpi.l	#$ffff,d2
	bls	divx		*16ビット以下の数値なら１命令で処理
	cmp.l	d1,d2
	beq	div01		*d1=d2商は１
	bls	div02		*１命令では無理なケース

	move.l	d1,d2		*商は０余りはd1.l
	moveq.l	#0,d1
	rts
div01:				*商は１余り０
	moveq.l	#1,d1
	moveq.l	#0,d2
	rts
div02:
	movem.l	d3-d5,-(sp)
	move.l	d2,d3
	clr.w	d3
	swap	d3
	addq.l	#1,d3
	move.l	d1,d4
	move.l	d2,d5
	move.l	d3,d2
	bsr	divx
	move.l	d5,d2
	divu	d3,d2
	divu	d2,d1
	andi.l	#$ffff,d1
div03:
	move.l	d5,d2
	move.l	d5,d3
	swap	d3
	mulu	d1,d2
	mulu	d1,d3
	swap	d3
	add.l	d3,d2
	sub.l	d4,d2
	bhi	div04
	neg.l	d2
	cmp.l	d2,d5
	bhi	div05
	addq.l	#1,d1
	bra	div03
div04:
	subq.l	#1,d1
	bra	div03
div05:
	movem.l	(sp)+,d3-d5
	rts
divx:
	movem.w	d1/d3,-(sp)
	clr.w	d1
	swap	d1
	divu	d2,d1
	move.w	d1,d3
	move.w	(sp)+,d1
	divu	d2,d1
	swap	d1
	moveq.l	#0,d2
	move.w	d1,d2
	move.w	d3,d1
	swap	d1
	move.w	(sp)+,d3
	rts

clc_exclusive:				*エクスクルーシブ転送	($f3)
	add.b	(a4)+,d4		*exclusive mode
clc_midi_transmission:			*MIDIデータ転送		($f4)
	moveq.l	#0,d0
	move.b	(a4)+,d0
	subq.w	#1,d0
	bcs	clc_mdtr0
@@:
	add.b	(a4)+,d4
	dbra	d0,@b
clc_mdtr0:
	move.b	(a4)+,d0
	lsl.w	#8,d0
	move.b	(a4)+,d0
	add.w	d0,d4			*checksum
	swap	d0
	move.b	(a4)+,d0
	lsl.w	#8,d0
	move.b	(a4)+,d0
	add.w	d0,d4			*checksum
@@:
	add.b	(a4)+,d4		*checksum
	subq.l	#1,d0
	bne	@b
	bra	getzmdlp

clc_asgn_arcc:				*ARCCアサイン			($f7)
	add.b	(a4)+,d4		*arcc no.
	move.b	(a4)+,d0		*omt
	add.b	d0,d4
clc_asarlp:				*omt中のビット=1の数だけパラメータが後続する
	add.b	d0,d0
	bcc	@f
	add.b	(a4)+,d4
@@:
	tst.b	d0
	bne	clc_asarlp
	bra	getzmdlp

clc_loop:				*ループ終端
@@:
	move.b	(a4)+,d0
	lsl.w	#8,d0
	move.b	(a4)+,d0		*get offste high
	add.w	d0,d4			*checksum
	swap	d0
	move.b	(a4)+,d0
	lsl.w	#8,d0
	move.b	(a4)+,d0		*get offset low
	add.w	d0,d4			*checksum
	tst.l	d0
	bne	@b
	bra	getzmdlp

clc_msln:				*小節線($fd)
	tst.b	clc_phase-work(a6)
	ble	getzmdlp		*minus or zero
	addq.l	#1,d6			*inc measure no.
	move.l	d5,(a3)+		*step
	clr.w	(a3)+			*checksum
	move.w	d4,(a3)+		*checksum
	moveq.l	#0,d0
	move.w	d4,d0
	swap	d0
	add.l	d0,d4			*上位ワードに総チェックサムとして足し込む
	moveq.l	#0,d5			*init. step
	move.w	d5,d4			*init. checksum
	cmp.l	a5,a3
	bcs	getzmdlp
	move.l	clc_buf_size(pc),d2
	add.l	#1024,d2		*1024バイト分追加確保
	move.l	clc_buf_addr(pc),a1
	bsr	enlarge_mem
	tst.l	d0
	bmi	t_out_of_memory_clc
	sub.l	clc_buf_addr(pc),a3
	lea	(a0,a3.l),a3
	sub.l	clc_buf_addr(pc),a2
	lea	(a0,a2.l),a2
	move.l	a0,clc_buf_addr-work(a6)
	move.l	d2,clc_buf_size-work(a6)
	lea	(a0,d2.l),a5		*領域最終アドレスも更新
	bra	getzmdlp

tmp_buf_addr:	ds.l	1
tmp_buf_size:	ds.l	1
clc_buf_addr:	ds.l	1
clc_buf_size:	ds.l	1
clc_ret_addr:	ds.l	1
clc_seq_flag:	ds.l	1	*d0:d.c. flag / d1:fine flag
*-------seq cmd---------------------------------------------------------------
*0:d.c.  1:do  2:!  3:@	 4:key  5:meter
clc_seq_cmd:
	moveq.l	#0,d0
	move.b	(a4)+,d0			*event number
	add.b	d0,d4
	move.b	(a4)+,d1			*n of param
	add.b	d1,d4
	cmpi.b	#end_of_scc,d0
	bhi	t_undefined_zmd_code_clc
	add.w	d0,d0
	move.w	@f(pc,d0.w),d0
	jmp	@f(pc,d0.w)
@@:
	dc.w	dc_clc-@b	*0
	dc.w	do_clc-@b	*1
	dc.w	skip_scc_np-@b	*2
	dc.w	skip_scc_np-@b	*3
	dc.w	skip_scc_np-@b	*4
	dc.w	skip_scc_np-@b	*5
dc_clc:						*[D.C.]
	btst.b	#0,clc_seq_flag-work(a6)
	bne	getzmdlp			*すでに一回実行した
	cmpi.b	#coda_zmd,(a4)
	beq	@f
	move.l	rcgz_addr(pc),a4
	or.b	#%11,clc_seq_flag-work(a6)
	bra	getzmdlp
@@:
	add.b	(a4)+,d4
	bsr	clc_do_segno_coda		*続く[coda]を認識させる
	move.l	rcgz_addr(pc),a4
	or.b	#%11,clc_seq_flag-work(a6)
	bra	mng_clc_mem
do_clc:						*[do]
	move.l	d7,clc_otlp_step-work(a6)	*[do]までの総ステップタイム保存
	move.b	#1,dlp_clc_flg-work(a6)
	bra	getzmdlp

skip_scc_np:
	tst.b	d1
	beq	getzmdlp
@@:
	add.b	(a4)+,d4			*params
	subq.b	#1,d1
	bne	@b
	bra	getzmdlp
*-------segno-----------------------------------------------------------------
clc_coda:
clc_segno:
	bsr	clc_do_segno_coda
	bra	mng_clc_mem

clc_ds:					*[d.s.]処理([SEGNO]へジャンプ)
	move.l	tmp_buf_addr(pc),a0
@@:
	move.l	(a0)+,d0
	beq	exit_dsop_clc		*error(通常はこんなことはあり得ない)
	cmp.l	a4,d0
	beq	@f
	addq.w	#2,a0
	bra	@b
@@:
	addq.w	#1,a0
	move.b	(a0),d0			*get flag
	bpl	exit_dsop_clc		*[segno]がなかったので無視
	add.b	d0,d0			*check d.s. done flag
	bmi	exit_dsop_clc		*[d.s.]一度処理したことがあるので無視
	bset.b	#6,(a0)			*set d.s. done flag
	bset.b	#1,clc_seq_flag-work(a6)	*set p_fine_flg
	addq.w	#1,a4			*skip flag
	move.b	(a4)+,d1		*get offset(.L)
	lsl.w	#8,d1
	move.b	(a4)+,d1
	add.w	d1,d4
	swap	d1
	move.b	(a4)+,d1
	lsl.w	#8,d1
	move.b	(a4)+,d1
	add.w	d1,d4
	cmpi.b	#coda_zmd,(a4)
	bne	@f
	pea	(a4,d1.l)
	addq.w	#1,a4
	bsr	clc_do_segno_coda
	move.l	(sp)+,a4
	bra	mng_clc_mem
@@:
	adda.l	d1,a4
	bra	getzmdlp
exit_dsop_clc:
	addq.w	#5,a4
	bra	getzmdlp
*-------coda------------------------------------------------------------------
clc_do_segno_coda:
	* - d1
	move.b	(a4)+,d0		*get offset(.L)
	lsl.w	#8,d0
	move.b	(a4)+,d0
	add.w	d0,d4
	swap	d0
	move.b	(a4)+,d0
	lsl.w	#8,d0
	move.b	(a4)+,d0
	add.w	d0,d4
	move.l	tmp_buf_addr(pc),a0
	tst.l	d0			*0の場合はコマンド無視ケース
	beq	exit_dsgcdcl
	lea	(a4,d0.l),a1
@@:				*リピートアドレス登録
	move.l	(a0)+,d2
	beq	@f
	cmp.l	a1,d2
	beq	dsgcdcl0
	addq.w	#2,a0
	bra	@b
@@:
	move.l	a1,-4(a0)	*登録
dsgcdcl0:
	clr.w	(a0)+		*init. work
	tas.b	-(a0)		*set segno flag
	bclr.b	#6,(a0)+	*clr d.s. done flag
	clr.l	(a0)+		*end code
exit_dsgcdcl:
	rts

clc_tocoda:				*[tocoda]処理([coda]へジャンプ)
	move.l	tmp_buf_addr(pc),a0
@@:
	move.l	(a0)+,d0
	beq	exit_tocd_clc
	cmp.l	a4,d0
	beq	@f
	addq.w	#2,a0
	bra	@b
@@:
	addq.w	#1,a0
	move.b	(a0),d0			*get flag
	bpl	exit_tocd_clc		*[coda]がなかったので無視
	add.b	d0,d0			*check tocoda done flag
	bmi	exit_tocd_clc		*[tocoda]一度処理したことがあるので無視
	bset.b	#6,(a0)			*set tocoda done flag
	addq.w	#1,a4			*skip flag
	move.b	(a4)+,d0		*get offset(.L)
	lsl.w	#8,d0
	move.b	(a4)+,d0
	add.w	d0,d4
	swap	d0
	move.b	(a4)+,d0
	lsl.w	#8,d0
	move.b	(a4)+,d0
	add.w	d0,d4
	adda.l	d0,a4
	bra	getzmdlp
exit_tocd_clc:
	addq.w	#5,a4
	bra	getzmdlp
*-------fine------------------------------------------------------------------
clc_fine:					*[fine]処理
	btst.b	#1,clc_seq_flag-work(a6)
	beq	getzmdlp
	bra	clc_next_tr
*-------skip------------------------------------------------------------------
clc_skip:
	moveq.l	#0,d1
	move.b	(a4)+,d1
	add.w	d0,d4
	move.b	(a4)+,d0
	lsl.w	#8,d0
	move.b	(a4)+,d0
	add.w	d0,d4
	swap	d0
	move.b	(a4)+,d0
	lsl.w	#8,d0
	move.b	(a4)+,d0
	add.w	d0,d4
	tst.b	d1
	bne	@f
	adda.l	d0,a4		*相対値ケース
	rts
@@:				*直値ケース
	move.l	d0,a4
	rts
*-------gosub return----------------------------------------------------------
clc_gosub:
	moveq.l	#0,d0
	move.b	(a4)+,d0
	lsl.w	#8,d0
	move.b	(a4)+,d0		*track no.
	add.w	d0,d4
	move.l	clc_trk_base(pc),a1	*トラック情報テーブルの先頭アドレス
	cmpi.w	#65535,d0
	bne	@f
	move.l	clc_ptn_trk(pc),d1	*pattern track
	beq	m_pattern_not_available	*パターントラックは使用できない
	move.l	d1,a1
	bra	gsbcl0
@@:
	lsl.l	#ti_size_,d0
	add.l	d0,a1
gsbcl0:
	move.l	ti_play_data(a1),d0
	lea	ti_play_data+4(a1,d0.l),a1	*performance data top addr
	move.b	(a4)+,d0
	lsl.w	#8,d0
	move.b	(a4)+,d0
	add.w	d0,d4
	swap	d0
	move.b	(a4)+,d0
	lsl.w	#8,d0
	move.b	(a4)+,d0
	add.w	d0,d4
	move.l	a4,clc_ret_addr-work(a6)
	lea	(a1,d0.l),a4
	bra	getzmdlp

clc_return:
	move.l	clc_ret_addr(pc),d0
	beq	getzmdlp
	clr.l	clc_ret_addr-work(a6)
	move.l	d0,a4
	bra	getzmdlp
*-------repeat control command------------------------------------------------
clc_repeat_start:		*|:n処理
	move.l	tmp_buf_addr(pc),a0
@@:				*リピートアドレス登録
	move.l	(a0)+,d2
	beq	@f
	cmp.l	a4,d2
	beq	rpstclc0
	addq.w	#2,a0
	bra	@b
@@:
	move.l	a4,-4(a0)	*登録
rpstclc0:
	clr.w	(a0)+		*init. work
	clr.l	(a0)+		*end code

	move.b	(a4)+,d2
	lsl.w	#8,d2
	move.b	(a4)+,d2
	add.w	d2,d4		*calc checksum(repeat counter)
	addq.w	#2,a4
mng_clc_mem:
	* < a0.l=tmp_buf_addr+x
	sub.l	tmp_buf_addr(pc),a0
	addq.w	#6,a0
	move.l	tmp_buf_size(pc),d2
	cmp.l	d2,a0
	bcs	getzmdlp
	add.l	#1024,d2		*1024バイト分追加確保
	move.l	tmp_buf_addr(pc),a1
	bsr	enlarge_mem
	tst.l	d0
	bmi	t_out_of_memory_clc
	move.l	a0,tmp_buf_addr-work(a6)
	move.l	d2,tmp_buf_size-work(a6)
	bra	getzmdlp

clc_repeat_end:			*:|処理
	move.b	(a4)+,d0
	lsl.w	#8,d0
	move.b	(a4)+,d0	*d0.w=offset value
	add.w	d0,d4		*calc checksum
	swap	d0
	move.b	(a4)+,d0
	lsl.w	#8,d0
	move.b	(a4)+,d0	*d0.w=offset value
	add.w	d0,d4		*calc checksum
	move.l	a4,d2		*現在のアドレスを保存
	suba.l	d0,a4		*a4.l=rept.count

	move.l	tmp_buf_addr(pc),a0
@@:
	move.l	(a0)+,d0
	beq	rpedc0		*error(通常はこんなことはあり得ない)
	cmp.l	a4,d0
	beq	@f
	addq.w	#2,a0
	bra	@b
@@:
	move.b	(a4)+,d0
	lsl.w	#8,d0
	move.b	(a4)+,d0	*希望リピート回数
	cmp.w	(a0),d0		*繰り返し回数とカウンタを比較
	bne	@f		*繰り返しを続行
rpedc0:
	move.l	d2,a4		*リピートしないで次へ
	bra	getzmdlp
@@:
	addq.w	#1,(a0)		*inc 繰り返し回数
	addq.w	#2,a4		*inc rep.work分
	bra	getzmdlp

clc_repeat_skip:		*|n処理
	move.b	(a4)+,d2
	lsl.w	#8,d2
	move.b	(a4)+,d2	*条件成立希望ループ回数値
	add.w	d2,d4		*calc checksum
	move.b	(a4)+,d0
	lsl.w	#8,d0
	move.b	(a4)+,d0
	add.w	d0,d4		*calc checksum
	swap	d0
	move.b	(a4)+,d0	*get count work offset
	lsl.w	#8,d0
	move.b	(a4)+,d0	*d0.l=offset value
	add.w	d0,d4		*calc checksum
	lea	-2(a4),a1
	suba.l	d0,a1		*a1.l=rept.count
	move.l	tmp_buf_addr(pc),a0
@@:
	move.l	(a0)+,d0
	beq	rpskp0		*error(通常はこんなことはあり得ない)
	cmp.l	a1,d0
	beq	@f
	addq.w	#2,a0
	bra	@b
@@:
	cmp.w	(a0),d2		*count workと比較
	bne	@f
	addq.w	#4,a4		*skip jumping offset
	bra	getzmdlp	*|n以降の演奏データを実行する
@@:				*繰り返し処理から脱ける
rpskp0:
	move.b	(a4)+,d0
	lsl.w	#8,d0
	move.b	(a4)+,d0
	add.w	d0,d4		*calc checksum
	swap	d0
	move.b	(a4)+,d0
	lsl.w	#8,d0
	move.b	(a4)+,d0	*d0.l=jumping offset
	add.w	d0,d4		*calc checksum
	adda.l	d0,a4		*オフセットを足して次の|nや:|へ
	bra	getzmdlp

clc_repeat_skip2:		*|処理(nが省略時のケース)
	move.b	(a4)+,d0
	lsl.w	#8,d0
	move.b	(a4)+,d0
	add.w	d0,d4		*calc checksum
	swap	d0
	move.b	(a4)+,d0	*get count work offset
	lsl.w	#8,d0
	move.b	(a4)+,d0	*d0.l=offset value
	add.w	d0,d4		*calc checksum
	lea	-2(a4),a1
	suba.l	d0,a1		*a1.l=rept.count
	move.l	tmp_buf_addr(pc),a0
@@:
	move.l	(a0)+,d0
	beq	rpskp2		*error(通常はこんなことはあり得ない)
	cmp.l	a1,d0
	beq	@f
	addq.w	#2,a0
	bra	@b
@@:
	move.b	(a1)+,d1
	lsl.w	#8,d1
	move.b	(a1)+,d1
	cmp.w	(a0),d1		*count workとリピート回数を比較
	beq	@f
rpskp2:
	addq.w	#4,a4		*skip offset
	bra	getzmdlp	*|以降の演奏データを実行する
@@:				*リピート最後なので脱ける
	move.b	(a4)+,d0
	lsl.w	#8,d0
	move.b	(a4)+,d0
	add.w	d0,d4		*calc checksum
	swap	d0
	move.b	(a4)+,d0
	lsl.w	#8,d0
	move.b	(a4)+,d0	*d0.l=offset
	add.w	d0,d4		*calc checksum
	adda.l	d0,a4		*オフセットを足して:|または次の| or |nへ
	bra	getzmdlp
*-----------------------------------------------------------------------------
calc_total:					*各ﾄﾗｯｸのｽﾃｯﾌﾟﾀｲﾑの合計を求める
	*   cmd=$67
	* < a1.l=ZMD address	(ヘッダはなくても有ってもいい
	*			 ヘッダがある場合はバージョンチェックをする)
	*	=0ならばa0.l=zmlentblを返す
	* > d0.l=0:no error
	* > a0.l=結果格納アドレス(使用後開放すること)(ZCLABEL.MAC参照)
	* > d0.l=n of error
	* > a0.l=error table(使用後開放すること)
	lea	work,a6
	move.l	a1,d0
	bne	@f
	lea	zmlentbl(pc),a0
	moveq.l	#0,d0
	rts
@@:
	move.l	sp,sp_buf-work(a6)		*スタック保存
	move.b	#ZM_CALC_TOTAL,zmc_call-work(a6)
	move.l	a1,zmd_top-work(a6)
	moveq.l	#0,d5
	move.w	d5,clc_phase-work(a6)		*phase 1,dlp_clc_flg
	move.l	d5,clc_play_time-work(a6)
	move.l	d5,clc_ttl_steptime-work(a6)
	move.l	d5,clc_ttl_checksum-work(a6)
	move.l	d5,n_of_err-work(a6)
	move.l	d5,n_of_warn-work(a6)
	move.l	d5,err_stock_addr-work(a6)
	move.l	d5,err_stock_size-work(a6)

	cmpi.l	#ZmuSiC0,(a1)			*$1a,'Zmu'
	bne	1f
	move.l	4(a1),d0
	clr.b	d0
	cmpi.l	#ZmuSiC1,d0			*'Sic',version(.b)
	bne	t_unidentified_file_clc
	cmpi.b	#v_code,7(a1)
	bcs	t_illegal_version_number_clc
	move.w	z_tempo(a1),d5
	tst.l	z_play_time(a1)
	beq	@f
	tas.b	clc_phase-work(a6)		*元々設定されているならば計算不要マーク
@@:
	addq.w	#8,a1				*skip header
	bra	2f
1:						*ヘッダ無しの場合
	move.w	z_tempo-8(a1),d5
	subq.l	#8,zmd_top-work(a6)		*header分差引く
	tst.l	z_play_time-8(a1)
	beq	2f
	tas.b	clc_phase-work(a6)		*元々設定されているならば計算不要マーク
2:
	tst.b	clc_phase-work(a6)
	bmi	@f
	move.l	#1024,d2			*テンポマップ用ワークエリア
	move.l	#ID_TEMP,d3			*phase 1で使用
	bsr	get_mem
	tst.l	d0
	bmi	t_out_of_memory_clc
	move.l	a0,tempo_map_addr-work(a6)	*tempo_map_now(.l),
	move.l	d2,tempo_map_size-work(a6)	*累積ステップタイム(.l),テンポ(.l)
	clr.l	(a0)+				*tempo_map_now=0
	clr.l	(a0)+				*累積step初期化
	move.l	d5,(a0)+			*初期テンポ
@@:
	move.l	#1032,d2			*6の倍数
	move.l	#ID_TEMP,d3			*address-ID(.L),counter(.W)という構造
	bsr	get_mem				*phase 1,2で使用
	tst.l	d0
	bmi	t_out_of_memory_clc
	move.l	a0,tmp_buf_addr-work(a6)	*保存
	move.l	d2,tmp_buf_size-work(a6)	*保存

	move.l	#1024,d2
	move.l	#ID_CALC,d3			*phase 2で使用
	bsr	get_mem
	tst.l	d0
	bmi	t_out_of_memory_clc
	move.l	a0,clc_buf_addr-work(a6)	*保存
	move.l	d2,clc_buf_size-work(a6)	*保存
	lea	1024(a0),a5			*block end addr.

	move.l	a0,a2
	moveq.l	#8-1,d0				*グローバルリザルトの数=8
@@:
	clr.l	(a2)+
	dbra	d0,@b
	move.w	#-1,(a2)			*演奏データがない場合のために初期化
						*演奏時間計算処理用
	move.l	(a1)+,d0			*共通コマンド部までのオフセット
*	beq	@f
*	lea	(a1,d0.l),a0
*	bsr	getset_cmn			*共通コマンド処理
*@@:
	move.l	(a1)+,d0			*演奏トラック情報テーブルまでのオフセット
	beq	clc_ttl_end			*演奏データ無し
	add.l	d0,a1				*a1=trk情報テーブル
	moveq.l	#0,d2
	move.w	(a1)+,d2			*d2=総トラック数-1(0-65535)
	move.l	d2,d0
	lsl.l	#2,d0				*4
	lea	4(a2,d0.l),a3
	move.w	#-1,(a3)+			*エンドコードを前もってセット
	move.l	a1,clc_trk_base-work(a6)	*トラック情報テーブルのベースアドレス
						*PATTERN TRACKのアドレスを取り出す(なければ0)
	move.l	a1,a4
	move.w	d2,d0
@@:
	cmpi.b	#ID_PATTERN,(a4)
	beq	@f
	add.w	#ti_size,a4
	dbra	d0,@b
	suba.l	a4,a4				*パターントラックがない場合は0
@@:
	move.l	a4,clc_ptn_trk-work(a6)
	tst.b	clc_phase-work(a6)
	bmi	clc_ttl_phase		*ステップタイム計算フェーズへ
	movem.l	d2/a1,-(sp)
clc_ttl_lp00:				*< a0.l=結果テーブルの先頭/a3.l=情報ストア領域
	movem.l	d2/a1,-(sp)		*総トラック総チェックサムをあとで格納するため(offset値)
*****************************************テンポマップ作成フェーズ
	move.l	zmd_top(pc),a4		*phase 1
	move.l	z_master_clock(a4),clc_mst_clk-work(a6)	*clc_mst_clk,clc_tempo

	move.l	ti_play_data(a1),d0
	lea	ti_play_data+4(a1,d0.l),a4	*performance data top addr
	moveq.l	#0,d7				*track total
						*特殊処理が必要なZMDの関連ワークの初期化
	move.l	d7,clc_ret_addr-work(a6)
	move.l	d7,clc_seq_flag-work(a6)
	move.l	tmp_buf_addr-work(a6),a0
	move.l	d7,(a0)				*init.
	moveq.l	#0,d0
	move.b	ti_trkfrq(a1),d0
	addq.w	#1,d0
	move.w	d0,clc_trkfrq-work(a6)
	cmpi.w	#DEV_PATTERN,ti_type(a1)
	beq	@f
	bsr	recognize_zmd_ope		*ZMD認識処理
@@:
	movem.l	(sp)+,d2/a1
	add.w	#ti_size,a1			*次のトラックへ
	dbra	d2,clc_ttl_lp00

	move.l	tempo_map_addr(pc),a1		*テンポマップ確定
	move.l	(a1)+,d2
	lea	(a1,d2.l),a0
*	beq	@f				*d2がゼロならば
*	subq.w	#8,a0
*@@:
	move.l	a1,-(a1)			*初期化
	move.l	a0,tempo_map_size-work(a6)	*最終要素アドレスを指すようになる
	tst.l	d2
	beq	@f
	bsr	enlarge_mem
@@:
	movem.l	(sp)+,d2/a1
****************************************ステップタイム計算フェーズ
clc_ttl_phase:
	addq.b	#1,clc_phase-work(a6)	*phase 2
clc_ttl_lp01:				*< a0.l=結果テーブルの先頭/a3.l=情報ストア領域
	move.l	a3,d0
	sub.l	clc_buf_addr(pc),d0
	movem.l	d0/d2/a1,-(sp)		*総トラック総チェックサムをあとで格納するため(offset値)
	move.l	a3,d0
	subq.l	#4,d0
	sub.l	a2,d0
	move.l	d0,(a2)+		*情報までのオフセット値を格納
	add.w	#clc_ttlrsltsz,a3	*tr0 step(l),tr1 step(l),checksum(l),n of mes.(l)

	move.l	zmd_top(pc),a4
	move.w	z_tempo(a4),clc_tempo-work(a6)

	move.l	ti_play_data(a1),d0
	lea	ti_play_data+4(a1,d0.l),a4	*performance data top addr
	moveq.l	#0,d4				*check sum(hw=total,lw=measure)
	moveq.l	#0,d5				*total step in a measure
	moveq.l	#0,d6				*num of measure
	moveq.l	#0,d7				*track total
						*特殊処理が必要なZMDの関連ワークの初期化
	move.l	d7,_clc_play_time-work(a6)
	move.l	d7,clc_ret_addr-work(a6)
	move.l	d7,clc_seq_flag-work(a6)
	move.l	d7,clc_otlp_step-work(a6)	*ループ外の総ステップ初期化
	move.l	tmp_buf_addr-work(a6),a0
	move.l	d7,(a0)				*init.
	moveq.l	#0,d0
	move.b	ti_trkfrq(a1),d0
	addq.w	#1,d0
	move.w	d0,clc_trkfrq-work(a6)
	cmpi.w	#DEV_PATTERN,ti_type(a1)
	beq	@f
	bsr	recognize_zmd_ope		*ZMD認識処理
@@:
	movem.l	(sp)+,d0/d2/a1
	move.l	clc_buf_addr(pc),a0
	add.l	d0,a0
	move.l	d7,d0
	tst.b	dlp_clc_flg-work(a6)		*[do]-[loop]があったか
	beq	@f
	move.l	clc_otlp_step-work(a6),d1
	move.l	d1,(a0)+			*ループ外トラック総ステップ
	sub.l	d1,d0
	move.l	d0,(a0)+			*ループ内トラック総ステップ
	bra	1f
@@:
	move.l	d0,(a0)+			*ループ外トラック総ステップ
	clr.l	(a0)+				*ループ内トラック総ステップ
1:
	cmp.l	clc_ttl_steptime(pc),d7
	bls	@f
	move.l	d7,clc_ttl_steptime-work(a6)
@@:
	moveq.l	#0,d0
	move.w	d4,d0
	swap	d4
	add.w	d4,d0			*端数加算
	add.l	d0,clc_ttl_checksum-work(a6)
	move.l	d0,(a0)+		*トラック総チェックサム
	move.l	d6,(a0)+		*トラック総小節数
	move.l	_clc_play_time(pc),d0
	cmp.l	clc_play_time(pc),d0
	bls	@f
	move.l	d0,clc_play_time-work(a6)
@@:
	add.w	#ti_size,a1		*次のトラックへ
	dbra	d2,clc_ttl_lp01
clc_ttl_end:				*終わり
	move.l	clc_buf_addr(pc),a0
	move.l	zmd_top(pc),a1
	move.l	clc_ttl_steptime(pc),d0
	move.l	d0,z_total_count(a1)
	tst.b	clc_phase-work(a6)
	bmi	1f
	move.l	d0,(a0)+
	move.l	clc_ttl_checksum(pc),(a0)+
	lea	z_play_time+4(a1),a1
	move.w	clc_play_time+2(pc),d0
	mulu	#60,d0
	clr.w	d0
	swap	d0			*d0.b=秒
	divu	#60,d0
	move.l	d0,d1
	clr.w	d0
	swap	d0			*d0.w=秒
	move.b	d0,-(a1)		*write 秒
	andi.l	#$ffff,d1		*d1.w=分
	moveq.l	#0,d0
	move.w	clc_play_time(pc),d0
	add.l	d0,d1
	divu	#60,d1			*d1.w=時間
	move.l	d1,d0
	swap	d0			*d0.w=分
@@:
	move.b	d0,-(a1)		*write 分
	move.w	d1,-(a1)		*write 時間
	move.l	(a1),(a0)+		*total playtime
	bra	clc_exit
1:					*ZMDから結果を取り出す場合
	move.l	z_total_count(a1),(a0)+
	move.l	clc_ttl_checksum(pc),(a0)+
	move.l	z_play_time(a1),(a0)+
clc_exit:
	bsr	rel_clctmpmem
	move.l	clc_buf_addr(pc),a0	*計算結果格納アドレス
	moveq.l	#0,d0			*no error
	rts

rel_clctmpmem:
	tst.b	clc_phase-work(a6)
	bmi	@f
	move.l	tempo_map_addr(pc),a1
	bsr	free_mem		*テンポマップ開放
@@:
	move.l	tmp_buf_addr(pc),a1
	bra	free_mem		*テンポラリ開放

recognize_zmd_ope:			*ZMDの認識処理
	* < a4.l=zmd addr
	move.l	a4,rcgz_addr-work(a6)	*先頭アドレスキープ
getzmdlp:
	moveq.l	#0,d0
	move.b	(a4)+,d0
	bpl	case_clcky		*通常発音音階
	cmpi.b	#$ff,d0			*end of track
	beq	clc_next_tr		*go next track
	add.w	d0,d4			*checksum
	add.b	d0,d0			*最上位ビット殺す
	add.w	d0,d0
	move.l	zmlentbl(pc,d0.w),d0
	beq	t_undefined_zmd_code_clc
	cmpi.l	#$100,d0
	bls	@f
	move.l	d0,a1
	jmp	(a1)			*可変長ZMD
@@:					*固定長ZMD
	subq.w	#2,d0			*minus 1 for dbra, another minus 1 for cmd length
	bcs	getzmdlp
@@:
	move.b	(a4)+,d1
	ext.w	d1
	add.w	d1,d4		*calc sum
	dbra	d0,@b
	bra	getzmdlp
clc_next_tr:
	rts
				*それぞれのZMD長を基本値とし最上位ビット=1の場合は
zmlentbl:			*そのZMDが可変長であることを意味する。7ビットは可変長ZMDに
				*対して便宜上付けた番号
	dc.l	clc_rest			*$80 do_rest
	dc.l	clc_wait			*$81 do_wait
	dc.l	clc_track_delay			*$82 track delay
	dc.l	clc_mx_key			*$83 mx_key
	dc.l	clc_portament			*$84 portament
	dc.l	clc_portament			*$85 portament
	dc.l	0,0
	dc.l	0,0,0,0,0,0,0,0
	dc.l	2,2,2,2,2,2,2,4			*$90～ all 2bytes
	dc.l	2,2,4,2,2,4,2,2 		*～$9f all 2bytes
	dc.l	2,2,2,2,2,2,2,2			*$a0～ all 2bytes
	dc.l	2,2,2,2,2,4,2,2 		*～$af all 2bytes
	dc.l	3,3,3,3,3,5,3,3			*$b0～ all 3bytes
	dc.l	3,3,3,3,3,3,3,3 		*～$bf all 3bytes
	dc.l	3,3,3				*$c0～$c2 all 3bytes
	dc.l	clc_tempo_t			*$c3 tempo
	dc.l	clc_rltv_t			*$c4 relative tempo
	dc.l	clc_seq_cmd			*$c5 [...]
	dc.l	3,3,3				*$c6～$c8 all 3bytes
	dc.l	4,4				*$c9～$ca all 4bytes
	dc.l	5,5				*$cb～$cc all 5bytes
	dc.l	clc_repeat_start		*$cd clc_repeat_start
	dc.l	clc_repeat_end			*$ce clc_repeat_end
	dc.l	5 				*$cf all 5bytes
	dc.l	clc_segno			*$d0 segno
	dc.l	clc_coda			*$d1 coda
	dc.l	clc_skip			*$d2 skip
	dc.l	clc_ds				*$d3 ds
	dc.l	clc_tocoda			*$d4 ToCoda
	dc.l	clc_gosub			*$d5 clc_gosub
	dc.l	clc_ch_fader			*$d6 ch fader
	dc.l	clc_mstr_fader			*$d7 master fader
	dc.l	clc_repeat_skip			*$d8 clc_repeat_skip
	dc.l	clc_repeat_skip2		*$d9 clc_repeat_skip2
	dc.l	clc_pmod_deepen			*$da pmod deepen
	dc.l	clc_arcc_deepen			*$db arcc deepen
	dc.l	clc_vseq_deepen			*$dc vseq deepen
	dc.l	clc_agogik_deepen		*$dd agogik deepen
	dc.l	clc_timbre_split		*$de timbre split
	dc.l	clc_vseq_wf			*$df vseq wf
	dc.l	clc_bend_@b			*$e0 bend @b
	dc.l	clc_bend_@k			*$e1 bend @k
	dc.l	clc_pmod8			*$e2 pmod8
	dc.l	clc_pmod_speed8			*$e3 pmod speed8
	dc.l	clc_pmod_delay8			*$e4 pmod delay8
	dc.l	clc_arcc8			*$e5 arcc8
	dc.l	clc_arcc_speed8			*$e6 arcc speed8
	dc.l	clc_arcc_delay8			*$e7 arcc delay8
	dc.l	clc_aftertouch			*$e8 after touch
	dc.l	clc_aftc_delay8			*$e9 aftc delay8
	dc.l	clc_vseq8			*$ea vseq8
	dc.l	clc_vseq_speed8			*$eb vseq speed8
	dc.l	clc_vseq_delay8			*$ec vseq delay8
	dc.l	clc_agogik8			*$ed agogik8
	dc.l	clc_agogik_speed8		*$ee agogik speed8
	dc.l	clc_agogik_delay8		*$ef agogik delay8
	dc.l	clc_effect_ctrl			*$f0 effect ctrl
	dc.l	clc_poke			*$f1 poke
	dc.l	clc_rltv_poke			*$f2 rltv poke
	dc.l	clc_exclusive			*$f3 roland_exclusive
	dc.l	clc_midi_transmission		*$f4 midi transmission
	dc.l	clc_loop			*$f5 loop
	dc.l	clc_auto_portament		*$f6 オートポルタメント
	dc.l	clc_asgn_arcc			*$f7 ARCCアサイン
	dc.l	clc_event			*$f8 イベント制御
	dc.l	clc_return			*$f9 return
	dc.l	1,1				*$fa～$fb all 1 byte
	dc.l	clc_fine			*$fc fine
	dc.l	1				*$fd all 1 byte
	dc.l	clc_msln			*$fe measure
	dc.l	1				*$ff

case_clcky:				*通常音符
	add.w	d0,d4			*calc check sum
	bsr	get_vlv			*skip step
	mulu	clc_trkfrq(pc),d1
	add.l	d1,d5			*st measure
	add.l	d1,d7			*tr total
	tst.b	clc_phase-work(a6)
	ble	@f			*minus or zero
	bsr	calc_play_time
@@:
	bsr	get_vlv			*skip gate
	move.b	(a4)+,d1
	ext.w	d1
	add.w	d1,d4			*skip velo(calc checksum)
	bra	getzmdlp

get_vlv:				*可変長データ
	* > d1.l=value
	* x d1
	moveq.l	#0,d1
	move.b	(a4)+,d1
	bpl	@f
	add.b	d1,d1			*最上位ビット殺す
	lsl.w	#7,d1
	move.b	(a4)+,d1
@@:
	add.w	d1,d4			*checksum
	rts

ope_word:				*ワード長データ
	* > d1.l=value
	* x d1
	move.b	(a4)+,d1
	lsl.w	#8,d1
	move.b	(a4)+,d1
	add.w	d1,d4			*checksum
	rts

occupy_compiler:			*コンパイラ占有ファンクション
	*   cmd=$6d
	* < d1.l=1	lock Compiler
	* < d1.l=0	unlock Compiler
	* < d1.l=-1	ask status
	* > d0.l	case:d1.l=1,0	d0:以前の占有状態(d1.l=-1のケース参照)
	* > d0.l	case:d1.l=-1	d0=0:free,	d0.l=1:occupied
	tst.l	d1
	bmi	1f
	beq	@f
						*Lock
	addq.b	#1,occupy_flag_c-work(a6)
	bra	1f
@@:						*Unlock
	tst.b	occupy_flag_c-work(a6)
	beq	1f
	subq.b	#1,occupy_flag_c-work(a6)
1:
	moveq.l	#0,d0
	move.b	occupy_flag_c(pc),d0
	rts

occupy_flag_c:	dc.w	0
*-----------------------------------------------------------------------------
_get_mem:
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
get_mem:			*メモリの確保
	* < d2.l=memory size
	* < d3.l=employment
	* > d0.l=memory block address (or error code/ depends on _S_MALLOC)
	* > d2.l=long word border size
	* > a0.l=data address
	* - all
	bra.s	_get_mem	*常駐時はNOPに
	Z_MUSIC	#ZM_GET_MEM
	rts

_enlarge_mem:			*メモリブロックの拡大縮小
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

enlarge_mem:			*メモリブロックの拡大縮小
	* < d2.l=new memory size
	* < a1.l=now address
	* > d0.l=address (0:done it, error/ depends on _S_MALLOC)
	* > d2.l=long word border size
	* > a0.l=address
	* - all
	bra.s	_enlarge_mem		*常駐時はNOPに
	Z_MUSIC	#ZM_ENLARGE_MEM
	rts

_free_mem:
	pea	(a1)
	DOS	_MFREE
	addq.w	#4,sp
	tst.l	d0
	bne	@f		*case error
	moveq.l	#0,d0
@@:
	rts

free_mem:			*メモリブロックの解放
	* < a1.l=data address
	* > d0.l=0 no error
	* - a1
	bra.s	_free_mem		*常駐時はNOPに
	Z_MUSIC	#ZM_FREE_MEM
	rts
*-----------------------------------------------------------------------------
set_err_code_for_compile:
	tst.l	pmr_addr-work(a6)
	beq	@f
	move.l	line_number(pc),-(sp)
	jbsr	get_true_ln			*マクロ変換によってずれた行番号を補正する
	bsr	@f
	move.l	(sp)+,line_number-work(a6)
	rts
@@:
	move.l	d0,-(sp)
	move.l	include_depth(pc),d0
	beq	@f
	move.l	zms_file_id(pc),d0		*filename[n]
@@:
	move.l	d0,-(sp)
	move.l	line_number(pc),d0		*追加エラー情報
	move.l	d0,-(sp)
	move.l	line_ptr(pc),d0
	sub.l	line_locate(pc),d0
	move.l	d0,-(sp)
	move.l	12(sp),d0
	cmp.l	err_cache(pc),d0
	bne	@f
	move.l	8(sp),d0
	cmp.l	err_cache+4(pc),d0
	bne	@f
	move.l	4(sp),d0
	cmp.l	err_cache+8(pc),d0
	bne	@f
	move.l	(sp),d0
	cmp.l	err_cache+12(pc),d0
	bne	@f
	lea	16(sp),sp
	moveq.l	#-1,d0				*Cached mark
	rts
@@:
	move.l	(sp)+,err_cache+12-work(a6)
	move.l	(sp)+,err_cache+8-work(a6)
	move.l	(sp)+,err_cache+4-work(a6)
	move.l	(sp)+,d0
	move.l	d0,err_cache+0-work(a6)
	cmpi.b	#ZM_COMPILER,zmc_call-work(a6)
	bne	set_err_code
	tst.w	compile_option+2-work(a6)	*エラーテーブル作成要求有るか
	bpl	do_exit_sec			*作成しない場合は帰還する
	bsr	set_err_code
	move.l	err_cache+4-work(a6),d0
	bsr	set_err_code
	move.l	err_cache+8-work(a6),d0
	bsr	set_err_code
	move.l	err_cache+12-work(a6),d0
	bsr	set_err_code
	moveq.l	#0,d0				*NORMAL END MARK
	rts

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
	move.l	#ID_ERROR,d3
	bsr	get_mem
	tst.l	d0
	bmi	exit_sec
	move.l	d2,err_stock_size-work(a6)
	move.l	a0,err_stock_addr-work(a6)
	clr.l	err_stock_now-work(a6)
	bra	store_ercd_
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
*-----------------------------------------------------------------------------
t_out_of_memory_clc:		*メモリ不足(CALC_TOTAL)
	move.l	#ZM_CALC_TOTAL*65536+OUT_OF_MEMORY,d0
	bra	@f
*-----------------------------------------------------------------------------
t_illegal_version_number_clc:	*メモリ不足(CALC_TOTAL)
	move.l	#ZM_CALC_TOTAL*65536+ILLEGAL_VERSION_NUMBER,d0
	bra	@f
*-----------------------------------------------------------------------------
t_unidentified_file_clc:	*ZMUSICシステムのファイルではない
	move.l	#ZM_CALC_TOTAL*65536+UNIDENTIFIED_FILE,d0
@@:
	moveq.l	#0,d0
	bsr	set_err_code				*dummy
	bsr	set_err_code				*dummy
	bsr	set_err_code				*dummy
	bra	@f
*-----------------------------------------------------------------------------
t_undefined_zmd_code_clc:		*未定義のZMDである
	move.l	#ZM_CALC_TOTAL*65536+UNDEFINED_ZMD_CODE,d0
	bsr	set_err_code
	move.l	sv_filename(pc),d0	*ファイルネーム
	bsr	set_err_code
	move.l	a4,d0
	subq.l	#1,d0
	sub.l	zmd_top(pc),d0		*未定義ZMDの存在するオフセットアドレス
	bsr	set_err_code
	moveq.l	#0,d0
	move.b	-1(a4),d0		*ZMD内容
	bsr	set_err_code
@@:
	addq.l	#1,n_of_err-work(a6)	*inc error count
	move.l	sp_buf(pc),sp
	bsr	rel_clctmpmem
	move.l	n_of_err-work(a6),d0
	add.l	n_of_warn-work(a6),d0
	move.l	err_stock_addr-work(a6),a0
	rts
*-----------------------------------------------------------------------------
	if	(debug.and.1)
debug2:				*デバグ用ルーチン(レジスタ値を表示／割り込み対応)
	move.w	sr,db_work2	*save sr	(サブルーチン_get_hex32が必要)
	ori.w	#$700,sr	*mask int
	movem.l	d0-d7/a0-a7,db_work

	moveq.l	#%0011,d1
	IOCS	_B_COLOR

	lea	str__(pc),a1

	move.w	#$0d0a,(a1)+	*!
	move.w	#$0d0a,(a1)+	*!
	move.w	#$0d0a,(a1)+

	moveq.l	#8-1,d7
	lea	db_work(pc),a6
dbg2_lp01:
	move.l	(a6)+,d0
	bsr	_get_hex32
	addq.w	#8,a1
	cmpi.b	#4,d7
	bne	@f
	move.b	#' ',(a1)+
@@:
	move.b	#' ',(a1)+
	dbra	d7,dbg2_lp01

	move.b	#$0d,(a1)+
	move.b	#$0a,(a1)+

	moveq.l	#8-1,d7
dbg2_lp02:
	move.l	(a6)+,d0
	bsr	_get_hex32
	addq.w	#8,a1
	cmpi.b	#4,d7
	bne	@f
	move.b	#' ',(a1)+
@@:
	move.b	#' ',(a1)+
	dbra	d7,dbg2_lp02

	move.l	(a7),d0
	bsr	_get_hex32
	addq.w	#8,a1
*	move.b	#$0d,(a1)+
*	move.b	#$0a,(a1)+
	clr.b	(a1)+
	lea	str__(pc),a1
	IOCS	_B_PRINT
*@@:
*	btst.b	#5,$806.w
*	bne	@b

	movem.l	db_work(pc),d0-d7/a0-a7
	move.w	db_work2(pc),sr	*get back sr
	rts

_get_hex32:			*値→16進数文字列(4bytes)
	* < d0=data value
	* < a1=格納したいアドレス
	* > (a1)=ascii numbers
	* - all
	movem.l	d0-d1/d4/a1,-(sp)
	addq.w	#8,a1
	clr.b	(a1)
	moveq.l	#8-1,d4
_gh_lp32:
	move.b	d0,d1
	andi.b	#$0f,d1
	add.b	#$30,d1
	cmpi.b	#'9',d1
	bls	_its_hex32
	addq.b	#7,d1
_its_hex32:
	move.b	d1,-(a1)
	lsr.l	#4,d0
	dbra	d4,_gh_lp32
	movem.l	(sp)+,d0-d1/d4/a1
	rts
		*デバッグ用ワーク
	.even
str__:		ds.b	96*2
		dc.b	'REGI'
db_work:	dcb.l	16,0		*for debug
db_work2:	dc.l	0
tad:		dc.l	$e40000

debug1:
	move.w	sr,-(sp)
	move.l	a0,-(sp)
	move.l	tad(pc),a0
	move.l	d0,(a0)+
	move.l	a0,tad
	move.l	(sp)+,a0
	move.w	(sp)+,sr
@@:
	rts

	endif

play_beep:				*BEEP音を鳴らす
	move.w	sr,-(sp)
	ori.w	#$700,sr
	move.l	d0,-(sp)
	move.w	#$07,-(sp)
	clr.w	-(sp)
	DOS	_CONCTRL
	addq.w	#4,sp
	move.l	(sp)+,d0
	move.w	(sp)+,sr
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

kakuchoshi:			*拡張子を設定
	* < a0=filename address
	* < a1=拡張子アドレス
	* X a0
	bsr	skip_peri
	moveq.l	#91-1,d0
kkchs_lp:
	move.b	(a0)+,d0
	beq	do_kkchs
	cmpi.b	#'.',d0
	beq	find_period
	dbra	d0,kkchs_lp
do_kkchs:
	subq.l	#1,a0
	move.b	#'.',(a0)+
	move.b	(a1)+,(a0)+
	move.b	(a1)+,(a0)+
	move.b	(a1)+,(a0)+
	clr.b	(a0)
	rts
find_period:
	cmpi.b	#' ',(a0)
	bls	do_kkchs	*'.'はあっても拡張子がないケース
	rts

skip_peri:
	* < a0.l=filename addr
@@:
	cmpi.b	#'.',(a0)
	bne	@f
	addq.w	#1,a0
	bra	@b
@@:
	rts

cache_flush:				*キャッシュのフラッシュ
	movem.l	d0-d1,-(sp)
	moveq.l	#3,d1
	IOCS	_SYS_STAT
	movem.l	(sp)+,d0-d1
	rts

	.include	fopen.s

get_filedate:
	clr.l	-(sp)
	move.w	d5,-(sp)
	DOS	_FILEDATE
	addq.w	#6,sp
	rts

	.include	zcwork.s
	.even

dev_init:				*デバイスドライバとしての初期化
	movem.l	d1/a1/a6,-(sp)
	lea	work(pc),a6
	lea	cannot_reg(pc),a1
	bsr	bil_prta1
	movem.l	(sp)+,d1/a1/a6
	jmp	not_com

exec:				*コマンドラインから実行した時
	lea	work(pc),a6
	clr.l	-(sp)
	DOS	_SUPER			*スーパーバイザーへ
	addq.w	#4,sp
	move.l	d0,ssp-work(a6)
	move.l	sp,_sp_buf-work(a6)

	move.l	a0,a0work-work(a6)
	move.l	a1,a1work-work(a6)

	tst.b	$0cbc.w				*MPUが68000ならキャッシュフラッシュ必要無し
	bne	@f
	move.w	#RTS,cache_flush-work(a6)
@@
	lea	$10(a0),a0		*メモリブロックの変更
	suba.l	a0,a1
	pea	(a1)
	pea	(a0)
	DOS	_SETBLOCK
	addq.w	#8,sp

	bsr	get_compile_work	*ワークを確保

	movea.l	a2,a4
	addq.w	#1,a4			*skip length of cmd line
*	move.l	a4,-(sp)

	DOS	_VERNUM
	cmpi.w	#$0300,d0
	bcs	Human_ver_err
	bsr	chk_drv			*CHECK ZMUSIC
	bmi	@f
	cmpi.w	#$2500,(a1)		*version check(2.5より大きくないと駄目)
	scc	zmusic_stat-work(a6)
@@:					*スイッチ処理
	pea	zmc_opt(pc)
	bsr	search_env
	addq.w	#4,sp
	tst.l	d0
	beq	@f
	move.l	a4,-(sp)
	move.l	d0,a4
	bsr	chk_optsw
	move.l	(sp)+,a4
@@:
	clr.b	zmc_opt-work(a6)
	bsr	chk_optsw

	bsr	set_patch
	bsr	set_vect
	bne	register_unsuccessful	*(登録失敗)
	bsr	prt_keep_info
	bsr	set_dev_name
	bmi	unknown_err

	move.l	ssp(pc),a1
	IOCS	_B_SUPER

	clr.w	-(sp)
	move.l	#dev_init-begin_of_prog,-(sp)
	DOS	_KEEPPR			*常駐終了

register_unsuccessful:			*常駐失敗
	lea	occupy_unsuccessful_mes(pc),a1
	bra	err_exit

unknown_err:
	lea	unknown_mes(pc),a1
err_exit:
	bsr	prt_title
	bsr	bil_prta1
err_exit0:
	move.l	ssp(pc),a1
	IOCS	_B_SUPER	*ユーザーモードへ戻る

	move.w	#1,-(sp)
	DOS	_EXIT2

title_mes:			*使い捨てのワーク群(後にグローバルワークとして使用される)
	dc.b	'Z-MUSIC MML COMPILER '
	dc.b	$F3,'I',$F3,'N',$F3,'T',$F3,'E',$F3,'G',$F3,'R',$F3,'A',$F3,'L '
	dc.b	$F3,'V',$F3,'E',$F3,'R',$F3,'S',$F3,'I',$F3,'O',$F3,'N'
	version
	TEST
	dc.b	' (C) 1995,98 '
	dc.b	'ZENJI SOFT',13,10,0
linked_mes:	dc.b	'Z-MUSIC MML COMPILER has succeeded in linking with Z-MUSIC PERFORMANCE MANAGER.',13,10,0
linked_mes_j:	dc.b	'Z-MUSICコンパイラをZ-MUSIC演奏マネージャとリンクしました',13,10,0
out_mem_mes:	dc.b	'Out of memory.',13,10,0
out_mem_mes_j:	dc.b	'メモリが不足しています',13,10,0
os_old_mes:	dc.b	"Z-MUSIC runs on Human68k ver.3.00 and over.",13,10,0
os_old_mes_j:	dc.b	"Z-MUSICはバージョン3.0以上のHuman68kで動作します",13,10,0
kakuho_mes:	dc.b	'kByte(s)',0
not_kep_mes:	dc.b	'Z-MUSIC MML COMPILER is not kept in the system.',13,10,0
not_kep_mes_j:	dc.b	'Z-MUSIC MML コンパイラは常駐していません',13,10,0
rls_er_mes:	dc.b	'Z-MUSIC MML COMPILER is unable to release.',13,10,0
rls_er_mes_j:	dc.b	'Z-MUSIC MML コンパイラの常駐解除はできません',13,10,0
ocp_er_mes:	dc.b	'Z-MUSIC MML COMPILER is occupied by some other application.',13,10,0
ocp_er_mes_j:	dc.b	'Z-MUSIC MML コンパイラは他のアプリケーションに占有されています',13,10,0
ver_er_mes:	dc.b	'Illegal version number. Unable to release.',13,10,0
ver_er_mes_j:	dc.b	'バージョンが異なるため解除は出来ません',13,10,0
nozm_er_mes:	dc.b	'Z-MUSIC PERFORMANCE MANAGER has to be included previously.',13,10,0
nozm_er_mes_j:	dc.b	'Z-MUSIC演奏マネージャが先に常駐していなければなりません',13,10,0
occupy_unsuccessful_mes:
		dc.b	'Fail in registering Z-MUSIC MML COMPILER.',13,10,0
		dc.b	'Z-MUSIC MML コンパイラの登録に失敗しました',13,10,0
unknown_mes:	dc.b	'Unknown error.',13,10,0
unknown_mes_j:	dc.b	'原因不明のエラーが発生しました',13,10,0
create_er_mes:		dc.b	' … File cannot be created.',13,10,0
create_er_mes_j:	dc.b	' … ファイルが作成できません',13,10,0
write_er_mes:	dc.b	' … Write error.',13,10,0
write_er_mes_j:	dc.b	' … 書き込みに失敗しました',13,10,0
read_er_mes:	dc.b	' … Unable to read.',13,10,0
read_er_mes_j:	dc.b	' … 読み出せません',13,10,0
cannot_reg:	dc.b	13,10,'ZMC.X cannot be registered from CONFIG.SYS.',13,10,0
cannot_reg_j:	dc.b	13,10,'ZMC.XはCONFIG.SYSから登録することは出来ません',13,10,0

how_many_err:	dc.b	' ERROR(S)',13,10,0
how_many_err_j:	dc.b	'個のエラーが発生しました',13,10,0
*b_clr_st:	dc.b	$1b,'[J',0
*b_era_st:	dc.b	$1b,'[2K',0
no_err_mes:	dc.b	'Operations are all set.',13,10
		dc.b	'A ',$1b,'[37m','♪SOUND',$1b,'[m mind in a '
		dc.b	$1b,'[37mSOUND',$1b,'[m',' body.',13,10,0
no_err_mes_j:	dc.b	'コンパイル完了',13,10,0
help_mes:	dc.b	'< USAGE >'
		dc.b	' ZMC.X [Optional Switches]',13,10
		dc.b	'< OPTIONAL SWITCHES >',13,10
		dc.b	'-? or H        Display the list of optional switches.',13,10
		dc.b	'-C<filename1>  Compile the music source file(filename1)',13,10
		dc.b	'  [,filename2] into the object file(filename2).',13,10
		dc.b	'-E<n>          Compiling operation will be terminated if the number of errors reaches n.',13,10
		dc.b	'-J             Messages will be displayed in Japanese.',13,10
		dc.b	'-L             Link with Z-MUSIC PERFORMANCE MANAGER.',13,10
		dc.b	'-R             Unlink and release Z-MUSIC MML COMPILER.',13,10
		dc.b	'-T             Restrain the detection of error location.',13,10
		dc.b	'-W             Restrain the output of warning messages.',13,10
		dc.b	0
help_mes_j:	dc.b	'< 使用方法 >'
		dc.b	' ZMC.X [オプションスイッチ]',13,10
		dc.b	'< オプションスイッチ一覧 >',13,10
		dc.b	'-? or H        ヘルプの表示',13,10
		dc.b	'-C<filename1>  ソースファイル(filename1)をコンパイルし',13,10
		dc.b	'  [,filename2] オブジェクトファイル(filename2)を生成する',13,10
		dc.b	'-E<n>          エラーの個数がn個になったらコンパイル処理を中断する',13,10
		dc.b	'-J             日本語メッセージ表示',13,10
		dc.b	'-L             Z-MUSIC演奏マネージャとリンクする',13,10
		dc.b	'-R             Z-MUSIC MML コンパイラの常駐を解除する',13,10
		dc.b	'-T             エラー箇所の検出を省略する',13,10
		dc.b	'-W             ウォーニングメッセージの出力を抑制する',13,10
		dc.b	0
zmc_opt:	dc.b	'zmc_opt',0
	.even

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

prta1_:
	move.l	d0,-(sp)
	pea	(a1)
	DOS	_PRINT
	addq.w	#4,sp
	move.l	(sp)+,d0
	rts

chk_optsw:				*スイッチ処理
	* < cmd_or_dev  0:device / $ff:command
	tst.b	(a4)
	beq	prt_help
chk_optsw_lp:
	move.b	(a4)+,d0
	beq	no_more?
	cmpi.b	#' ',d0
	beq	chk_optsw_lp
	cmpi.b	#'-',d0		*その他スイッチ処理へ
	beq	other_sw
	cmpi.b	#'/',d0
	beq	other_sw
	subq.w	#1,a4
	bra	compile_mode

no_more?:			*もうこれ以上スイッチは無しか
	tst.b	zmc_opt-work(a6)
	beq	@f		*コマンドラインからならもうスイッチはあり得ない
	rts
@@:
	tst.b	get_src_fn-work(a6)	*ファイル名取得したなら
	bne	compile_mode		*コンパイル処理へ
	tst.b	link_switch-work(a6)
	beq	prt_help
	rts

other_sw:			*その他のスイッチ
	move.b	(a4)+,d0
	beq	no_more?
	cmpi.b	#'?',d0		*diplay help message
	beq	prt_help
	cmpi.b	#'#',d0		*絶対アドレス指定TOTAL
	beq	absolute_calc
	cmpi.b	#'!',d0		*絶対アドレス指定COMPILE
	beq	absolute_compile
	cmpi.b	#'2',d0
	beq	set_v2_mode
	bsr	mk_capital	
	cmpi.b	#'C',d0		*compile
	beq	setting_for_compile
	cmpi.b	#'D',d0		*display
	beq	display_line_mode
	cmpi.b	#'E',d0		*set max err num.
	beq	set_err_num
	cmpi.b	#'G',d0		*no display mode
	beq	set_disp_mode
	cmpi.b	#'H',d0		*diplay help message
	beq	prt_help
	cmpi.b	#'J',d0		*エラーメッセージの言語
	beq	set_err_lang
	cmpi.b	#'L',d0		*link
	beq	link_mode
	cmpi.b	#'R',d0		*解除
	beq	release
	cmpi.b	#'T',d0		*エラー箇所レポート機能オフ
	beq	no_report_mode
	cmpi.b	#'W',d0		*Warning検出出力オフ
	beq	no_warn_mode
	bra	prt_help

display_line_mode:
	patch_w2	BSR,crl_patch,disp_line
	bsr	cache_flush
	bra	chk_optsw_lp

set_err_num:				*エラーの個数がこの値を超えたらコンパイル中断
	clr.b	max_err_num-work(a6)	*デフォルト=0(max)
	moveq.l	#-1,d4			*dummy end of cmd line
	jsr	chk_num-work(a6)
	bmi	chk_optsw_lp
	jsr	get_num-work(a6)
	cmpi.l	#127,d1
	bhi	chk_optsw_lp
	move.b	d1,max_err_num-work(a6)
	bra	chk_optsw_lp

set_err_lang:				*エラーメッセージの言語選択
	move.b	#1,errmes_lang-work(a6)	*1:Japanese
	bra	chk_optsw_lp

set_v2_mode:
	st.b	v2_mode-work(a6)
	bra	chk_optsw_lp

set_disp_mode:				*表示モード
	clr.b	disp_mode-work(a6)
	move.l	#$7000_4e75,d0			*moveq.l #0,d0
						*rts
	move.l	d0,prt_title-work(a6)		*タイトル
	move.w	d0,prt_keep_info-work(a6)	*常駐ステータス
	move.w	d0,release_mes-work(a6)		*解除
	bsr	cache_flush
	bra	chk_optsw_lp

no_report_mode:
	move.w	#RTS,scan_line_number-work(a6)
	bsr	cache_flush
	bra	chk_optsw_lp

no_warn_mode:
	patch_w	BRA,m_warn_code_exit,mwce_exit
	bsr	cache_flush
	bra	chk_optsw_lp

link_mode:				*常駐する
	tst.b	zmusic_stat-work(a6)	*ZMUSICが常駐していないのならば無理
	beq	no_zmusic_err
	tas	link_switch-work(a6)
	moveq.l	#0,d1
	Z_MUSIC	#ZM_INIT
	rts

absolute_calc:				*絶対アドレストータルタイム計算
	moveq.l	#-1,d4			*dummy end of cmd line
	jsr	chk_num-work(a6)
	bmi	chk_optsw_lp
	jsr	get_num-work(a6)
	move.l	d1,src_address-work(a6)		*address

	jsr	skip_sep-work(a6)

	jsr	chk_num-work(a6)
	bmi	chk_optsw_lp
	jsr	get_num-work(a6)
	move.l	d1,src_size-work(a6)		*size

	jsr	skip_sep-work(a6)

	move.b	#1,compile_type-work(a6)	*アドレスモードで
	st.b	get_src_fn-work(a6)		*ファイル名取ったとみなす
	move.l	sv_filename(pc),a0
	clr.b	(a0)
	move.l	sr_filename(pc),a0
	clr.b	(a0)
	bra	chk_optsw_lp			*!
*	pea	chk_optsw_lp(pc)
*	bra	get_dest_name

absolute_compile:			*絶対アドレスコンパイル
	moveq.l	#-1,d4			*dummy end of cmd line
	jsr	chk_num-work(a6)
	bmi	chk_optsw_lp
	jsr	get_num-work(a6)
	move.l	d1,src_address-work(a6)		*address

	jsr	skip_sep-work(a6)

	jsr	chk_num-work(a6)
	bmi	chk_optsw_lp
	jsr	get_num-work(a6)
	move.l	d1,src_size-work(a6)		*size

	jsr	skip_sep-work(a6)

	st.b	compile_type-work(a6)	*アドレスモードで
*	st.b	get_src_fn-work(a6)	*ファイル名取ったとみなす
*	pea	chk_optsw_lp(pc)
*	bra	get_dest_name

setting_for_compile:			*コンパイルに向けてのパラメータ設定
	pea	chk_optsw_lp(pc)

get_src_zmd_name:
	tas.b	get_src_fn-work(a6)
	bne	exit_gszn
	moveq.l	#-1,d4			*dummy end of cmd line
	jsr	skip_spc-work(a6)
	move.l	sr_filename(pc),a0
	jsr	copy_fn			*get source file name
	move.l	sr_filename(pc),a0
	lea	ZMS(pc),a1
	bsr	kakuchoshi
	jsr	skip_sep-work(a6)
	move.b	(a4),d0			*何かコマンドラインに残っているか
	beq	mk_default_fn		*デフォルトのファイルネームを持ってくる
	cmpi.b	#'-',d0			*出力ファイルネームではなくて、何か別のものだったら
	beq	exit_gszn		*スイッチ処理ループへ戻る
	cmpi.b	#'/',d0
	beq	exit_gszn
get_dest_name:
	move.l	sv_filename(pc),a0
	jsr	copy_fn			*get destination file name
	move.l	sv_filename(pc),a0
	lea	ZMD(pc),a1
	bsr	kakuchoshi		*拡張子を設定
	jmp	skip_spc-work(a6)
exit_gszn:
	rts				*まだオプション有り

mk_default_fn:				*デフォルトのファイルネームを作る
	movem.l	d0-d1/a0-a1,-(sp)
	move.l	sr_filename(pc),a0
	bsr	skip_peri
mdf_:
	move.l	sv_filename(pc),a1
	moveq.l	#0,d1
	tst.b	(a0)
	bmi	@f
	cmpi.b	#':',1(a0)
	bne	@f
	addq.w	#2,a0
@@:
mdf_lp:
	move.b	(a0)+,d0
	beq	exit_mdf
	jsr	chk_kanji-work(a6)	*漢字かどうかチェック
	bpl	@f
	move.b	d0,(a1)+	*漢字はペア
	move.b	(a0)+,(a1)+
	bra	mdf_lp
@@:
	cmpi.b	#'\',d0
	beq	mdf_
	cmpi.b	#'.',d0
	beq	exit_mdf
*	bsr	mk_capital
mdf0:
	move.b	d0,(a1)+
	bra	mdf_lp
exit_mdf:
	move.b	#'.',(a1)+
	move.b	#'Z',(a1)+
	move.b	#'M',(a1)+
	move.b	#'D',(a1)+
	clr.b	(a1)
	movem.l	(sp)+,d0-d1/a0-a1
	rts

no_zmusic_err:				*ZMUSICが常駐していない
	bsr	play_beep
	lea	nozm_er_mes(pc),a1
	bra	err_exit

Human_ver_err:
	jsr	play_beep-work(a6)
	lea	os_old_mes(pc),a1
	bra	err_exit

resigned:
	bsr	play_beep
	lea	out_mem_mes(pc),a1
	bra	err_exit

set_vect:				*本デバイスドライバを拡張IOCSとして登録
	* > d0.l≠0ならエラー
	tst	zmusic_stat-work(a6)
	beq	prt_help

	moveq.l	#ZM_COMPILER,d1
	lea	-1.w,a1			*detect mode
	Z_MUSIC	#ZM_HOOK_FNC_SERVICE
	move.l	a0,d0
	bne	occupied_unsuccessful	*既に占有されていた

	moveq.l	#ZM_OCCUPY_COMPILER,d1
	lea	-1.w,a1			*detect mode
	Z_MUSIC	#ZM_HOOK_FNC_SERVICE
	move.l	a0,d0
	bne	occupied_unsuccessful	*既に占有されていた

	moveq.l	#ZM_CALC_TOTAL,d1
	lea	-1.w,a1			*detect mode
	Z_MUSIC	#ZM_HOOK_FNC_SERVICE
	move.l	a0,d0
	bne	occupied_unsuccessful	*既に占有されていた

	lea	release_compiler,a1
	Z_MUSIC	#ZM_APPLICATION_RELEASER	*解放ルーチンの登録
	move.l	d0,rel_cmplr_mark-work(a6)
	move.l	a0,d0
	beq	occupied_unsuccessful

	moveq.l	#ZM_COMPILER,d1
	lea	compiler,a1
	Z_MUSIC	#ZM_HOOK_FNC_SERVICE	*外部組み込み

	moveq.l	#ZM_OCCUPY_COMPILER,d1
	lea	occupy_compiler(pc),a1
	Z_MUSIC	#ZM_HOOK_FNC_SERVICE	*外部組み込み

	moveq.l	#ZM_CALC_TOTAL,d1
	lea	calc_total(pc),a1
	Z_MUSIC	#ZM_HOOK_FNC_SERVICE	*外部組み込み
prt_title:				*タイトル表示(-GでRTSに)
	move.l	a1,-(sp)
	tst.b	title_mes-work(a6)
	beq	1f
	lea.l	title_mes(pc),a1
	bsr	prta1
	clr.b	(a1)
1:
	move.l	(sp)+,a1
	moveq.l	#0,d0			*no problem
	rts

occupied_unsuccessful:
	moveq.l	#-1,d0
	rts

set_dev_name:				*コマンドからドライバが実行された場合に
	lea	$6800,a0		*デバイス名を強制的に登録する
fdn_lp01:
	lea	NUL(pc),a2
	jsr	do_find
	cmpa.l	#NUL,a0
	bcc	err_fdn
	cmpi.w	#$8024,-18(a0)	*本当にNULか
	bne	fdn_lp01
	lea	-22(a0),a0
fdn_lp02:
	movea.l	a0,a1
	movea.l	(a1),a0		*最後尾を見付ける
	cmpa.l	#-1,a0
	bne	fdn_lp02
	lea	device_driver0,a0
	move.l	a0,(a1)
	moveq.l	#0,d0
	rts
err_fdn:
	moveq.l	#-1,d0
	rts

set_patch:					*パッチ処理(常駐プログラムとしての変身)
	movem.l	d0-d1/a0,-(sp)
	lea	set_patch_tbl(pc),a0
	move.w	#NOP,d1
@@:
	move.l	(a0)+,d0
	beq	@f
	move.w	d1,(a6,d0.l)
	bra	@b
@@:
exit_chwp:
	bsr	cache_flush
	movem.l	(sp)+,d0-d1/a0
	rts

set_patch_tbl:
	dc.l	get_mem-work
	dc.l	enlarge_mem-work
	dc.l	free_mem-work
	dc.l	0

prt_help:			*簡易ヘルプの表示
*	bsr	prt_title
	lea	help_mes(pc),a1
	bra	err_exit

get_compile_work:			*コンパイルワークを設定
	* X d0 a0
	move.l	#gcw_size,-(sp)
	DOS	_MALLOC
	addq.w	#4,sp
	move.l	d0,zmc_work-work(a6)
	bmi	_out_mem_err
	move.l	d0,a1
	bra	split_wk

get_work_area:			*ワークエリアの確保
open_fn__:	equ	92
sr_fn_size:	equ	1024
arry_stock_len:	equ	1024
temp_buffer_len:	equ	1024
gcw_size:	equ	open_fn__*2+(t_trk_no_max+1)*2+sr_fn_size+open_fn__+arry_stock_len+temp_buffer_len
	lea.l	work_start(pc),a1
split_wk:
	move.l	a1,filename-work(a6)
	clr.b	(a1)
	lea	open_fn__(a1),a1

	move.l	a1,open_fn-work(a6)
	clr.b	(a1)
	lea	open_fn__(a1),a1

	move.l	a1,t_trk_no-work(a6)
	lea	(t_trk_no_max+1)*2(a1),a1

	move.l	a1,sr_filename-work(a6)
	clr.b	(a1)
	lea	sr_fn_size(a1),a1

	move.l	a1,sv_filename-work(a6)
	clr.b	(a1)
	lea	open_fn__(a1),a1

	move.l	a1,temp_buffer-work(a6)
	lea	temp_buffer_len(a1),a1

	move.l	a1,arry_stock-work(a6)
	lea	arry_stock_len(a1),a1

	move.l	a1,dev_end_adr-work(a6)
	move.w	#1,-(sp)
	pea	(a1)
	pea	(a1)
	DOS	_BUS_ERR		*メモリを過剰使用していないか
	lea	10(sp),sp
	tst.l	d0
	rts

prt_keep_info:				*常駐インフォーメーション(-GでRTSに)
	lea	linked_mes(pc),a1
	bra	bil_prta1

release:				*解除処理
	bsr	kep_chk			*常駐check
	bmi	not_kept		*常駐していない
	bne	illegal_ver		*バージョンが違う

	moveq.l	#0,d2			*d2=0
	move.l	d2,a1			*a1=0
	Z_MUSIC	#ZM_COMPILER		*解除(> a0.l=release addr)
	tst.l	d0
	bmi	release_err		*d0=-1:常駐解除失敗
	bne	case_occupied		*d0=1:占有されている

	pea	$10(a0)
	DOS	_MFREE
	addq.w	#4,sp

	bsr	prt_title
	bsr	release_mes

	move.l	ssp-work(a6),a1
	IOCS	_B_SUPER	*ユーザーモードへ戻る

	DOS	_EXIT

release_mes:
	lea	kaijo-work(a6),a1
	bra	bil_prta1

case_occupied:			*ZMUSICは占有されているので解除不可能
	lea	ocp_er_mes(pc),a1
	bra	err_exit

illegal_ver:			*VERSIONが違う
	lea	ver_er_mes(pc),a1
	bra	err_exit

release_err:			*解除不能の状態
	lea	rls_er_mes(pc),a1
	bra	err_exit

not_kept:			*常駐していないのか
	lea	not_kep_mes(pc),a1	*常駐していない
	bra	err_exit

chk_drv:			*デバイス名のcheck
	* > eq=no error
	* > mi=error
	* > (a1).w=version number
	move.l	$8c.w,a1
	subq.w	#8,a1
	cmpi.l	#'ZmuS',(a1)+
	bne	@f
	cmpi.w	#'iC',(a1)+
	bne	@f
	rts
@@:
	moveq.l	#-1,d0
	rts

kep_chk:			*分身が常駐しているか
	* > eq=exists
	* > ne=none
	move.l	a0work-work(a6),a0
@@:				*メモリポインタの先頭を求める
	move.l	(a0),d0
	beq	klop1
	move.l	d0,a0
	bra	@b
klop1:
	move.l	12(a0),d0	*次のメモリ管理ポインタ
	beq	err_chk
	movea.l	d0,a2
	cmpi.b	#$ff,4(a2)	*!Thanks to E.Tachibana
	bne	klop_nxt	*常駐プロセスでない
	lea	version_id+8-begin_of_prog+$100(a2),a1
	cmpa.l	8(a2),a1
	bhi	klop_nxt	*比較対象のメモリブロックが小さすぎるので対象外
	subq.w	#8,a1		*!Thanks to E.Tachibana
	lea	version_id,a0
	cmpm.l	(a1)+,(a0)+
	bne	klop_nxt
	cmpm.w	(a1)+,(a0)+
	bne	klop_nxt
	cmpm.w	(a1)+,(a0)+
	bne	wrong_ver
	move.l	a2,a2work-work(a6)
	moveq.l	#0,d0		*分身の存在を確認
	rts
klop_nxt:
	move.l	a2,a0
	bra	klop1		*どんどんさかのぼる
err_chk:			*分身は無かった
	moveq.l	#-1,d0
	rts
wrong_ver:			*バージョンが違う
	moveq.l	#1,d0
	rts

compile_mode:				*コンパイラ
	bsr	get_src_zmd_name	*ファイル名等の取りだし(取り出していないなら)

*	lea	b_clr_st(pc),a1
*	bsr	prta1
	bsr	prt_title

	bsr	read_source		*ソースファイルのリード(a1=data address/d2=data size)

	tst.b	compile_type-work(a6)
	ble	@f
	move.l	a1,a0
	bra	go_calc			*絶対アドレスで計算
@@:
	move.l	a1,zms_addr-work(a6)

	moveq.l	#0,d1
	move.b	max_err_num(pc),d1	*d1.b=エラーがいくつ発生したらコンパイルを中断するか(0-127)
	ori.w	#ZMC_ERL,d1		*mode
	tst.b	v2_mode-work(a6)
	beq	@f
	ori.w	#ZMC_V2,d1
@@:
	jsr	compiler		*コンパイル実行ルーチンへ(< a1.l=addr,d1.l=mode,d2.l=size)
compiler_end:
	tst.l	d0
	bne	error_occurred		*エラー発生
	move.l	z_zmd_size(a0),d2	*出力ZMDの末端チェック
	tst.l	(a0,d2.l)		*ウォーニングがあるか
	beq	@f
	bsr	warning_occurred	*ウォーニング発生
@@:					*ファイルの書き出し
	* < a0.l=zmd addr d2.l=size
go_calc:				*ステップタイム計算へ
	move.l	sv_filename(pc),a1
	lea	clc_ttl_header+1(pc),a2
@@:					*ファイル名表示
	move.b	(a1)+,d0
	beq	@f
	move.b	d0,(a2)+
	bra	@b
@@:
	movem.l	d2/a0,-(sp)
	move.l	a0,a1
	bsr	calc_total		*> a0.l=information table
	tst.l	d0			*no error case
	beq	@f
	bsr	_error_occurred
	bra	create_zmd		*ZMD保存へ
@@:
	tst.b	disp_mode-work(a6)
	beq	@f
	move.l	(sp),d2			*d2=zmd size
	bsr	disprslt
@@:
create_zmd:
	movem.l	(sp)+,d2/a0

	tst.b	compile_type-work(a6)
	bgt	@f			*calc totalのみ
	move.w	#32,-(sp)
	move.l	sv_filename(pc),-(sp)
	DOS	_CREATE
	addq.w	#6,sp
	move.l	d0,d5			*d5.w=file handle
	bmi	_create_err

	move.l	d2,-(sp)	*data size
	pea	(a0)		*data addr
	move.w	d5,-(sp)
	DOS	_WRITE
	lea	10(sp),sp
	cmp.l	d0,d2
	bne	_write_err

	move.l	date_buf(pc),-(sp)
	move.w	d5,-(sp)
	DOS	_FILEDATE
	addq.w	#6,sp

	bsr	do_fclose
@@:
	tst.b	disp_mode-work(a6)
	beq	@f
	lea	no_err_mes(pc),a1		*no error at all
	bsr	bil_prta1
@@:
	move.l	ssp(pc),a1
	IOCS	_B_SUPER	*ユーザーモードへ戻る

	DOS	_EXIT

	.include	disprslt.s

read_source:			*SOURCE FILEの読み込み
	* > a1.l=data address
	* > d2.l=data size
	tst.b	compile_type-work(a6)
	bne	compile_address	*アドレスモード
	move.l	sr_filename(pc),a4
	clr.w	-(sp)
	pea	(a4)
	DOS	_OPEN
	addq.w	#6,sp
	move.l	d0,d5		*d5.w=file handle
	bpl	1f
@@:
	tst.b	(a4)+
	bne	@b
	subq.l	#4,a4
	cmpi.b	#'Z',(a4)+
	bne	_read_err
	cmpi.b	#'M',(a4)+
	bne	_read_err
	cmpi.b	#'S',(a4)+
	bne	_read_err
	move.b	#'M',-(a4)
	move.b	#'P',-(a4)
	move.b	#'O',-(a4)
	bra	read_source
1:
	bsr	get_fsize	*>d3.l=file size
	bmi	_read_err
	move.l	d3,d2
	addq.l	#1,d3		*endcode分

	move.l	d3,-(sp)	*data size
	DOS	_MALLOC
	addq.w	#4,sp
	tst.l	d0
	bmi	_out_mem_err
	movea.l	d0,a1		*a4=address

	move.l	d4,-(sp)	*size
	pea	(a1)		*address
	move.w	d5,-(sp)
	DOS	_READ
	lea	10(sp),sp
	tst.l	d0
	bmi	_read_err
	clr.b	(a1,d2.l)	*endcode念のため

	bsr	get_filedate
	move.l	d0,date_buf-work(a6)

	bra	do_fclose

compile_address:		*アドレスモード
	move.l	src_address(pc),a1
	move.l	src_size(pc),d2
	rts

warning_occurred:		*ウォーニング表示
	* < d2.l=zmd size
	* < a0.l=zmd addr
	movem.l	d0-d2/a0-a3,-(sp)
	lea	4(a0,d2.l),a0	*(a0,d2.l)はn_of_warn,4(a0,d2.l)がwarn_tbl
	move.b	errmes_lang-work(a6),d1
	move.l	n_of_warn(pc),d2
	move.l	sr_filename(pc),a3
	move.l	zms_addr(pc),a2
	move.l	sv_filename(pc),a1
	bsr	do_prt_err_mes
	movem.l	(sp)+,d0-d2/a0-a3
	rts

error_occurred:				*エラー表示
	* < a0.l=error table
	* - all
	pea	_end(pc)
_error_occurred:			*終了しないエントリ
	movem.l	d0-d2/a0-a3,-(sp)
	move.b	errmes_lang-work(a6),d1
	move.l	n_of_err(pc),d2
	add.l	n_of_warn(pc),d2	*!
	move.l	sr_filename(pc),a3
	move.l	zms_addr(pc),a2
	move.l	sv_filename(pc),a1
	bsr	do_prt_err_mes
	move.l	a0,a1
	bsr	free_mem
	movem.l	(sp)+,d0-d2/a0-a3
	rts

PUTCHAR	macro
	DOS	_PUTCHAR
	endm

PRINT	macro
	DOS	_PRINT
	endm

	.include	prterrms.s
	.include	zmerrmes.s	*エラーメッセージ
	.even

_out_mem_err:
	lea	out_mem_mes(pc),a1
	bra	__end
_read_err:			*READ ERROR
	move.l	sr_filename(pc),a1
	bsr	prta1
	lea	read_er_mes(pc),a1
	bra	__end
_create_err:			*CREATE ERROR
	move.l	sv_filename(pc),a1
	bsr	prta1
	lea	create_er_mes(pc),a1
	bra	__end
_write_err:			*WRITE ERROR
	move.l	sv_filename(pc),a1

	DOS	_ALLCLOSE
	pea	(a1)
	DOS	_DELETE
	addq.w	#4,sp

	bsr	prta1
	lea	write_er_mes(pc),a1
__end:
	bsr	bil_prta1
_end:
	move.l	n_of_err(pc),d0
	beq	err_exit0
	bsr	num_to_str
	lea	suji(pc),a1
	bsr	prta1
	bsr	play_beep	*警告音を鳴らす
	lea	how_many_err(pc),a1
	bra	err_exit	*エラーが発生した

work_start:
end_of_prog:
	.end	exec
