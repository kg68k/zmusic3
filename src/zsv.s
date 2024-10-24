*************************************************
*						*
*		　　ＺＳＶ．Ｒ	 		*
*						*
*		PROGRAMMED BY Z.N		*
*						*
*************************************************
	.include	zmcall.mac
	.include	zmd.mac
	.include	iocscall.mac
	.include	doscall.mac
	.include	label.mac
	.include	zmid.mac
	.include	z_global.mac
	.include	table.mac
	.include	version.mac
	.offset		0
	.include	common.mac

DO_NOT_DEFINE_WORK_LABEL: .equ 1
	.offset		0
	.include	zm_stat.mac

	.text
	.cpu	68000
trn:		equ	32	*キャラクタ画面の縦の文字数
*zsv_v_code:	equ	$01	*バージョンＩＤ
*zsv_v_code_:	equ	$04	*バージョンＩＤ端数
disp_max:	equ	10
palet00:	equ	$00
palet10:	equ	$10
palet20:	equ	$20
palet30:	equ	$30
palet40:	equ	$40
palet50:	equ	$50
palet60:	equ	$60
palet70:	equ	$70
palet80:	equ	$80
palet90:	equ	$90
paleta0:	equ	$a0
paletb0:	equ	$b0
paletc0:	equ	$c0
paletd0:	equ	$d0
palete0:	equ	$e0
paletf0:	equ	$f0
dtsz:		equ	256	*ZSVが必要とする1トラック当たりのワークサイズ
			*(表示パラメータ数(22)+PM･SW/AM･SWトラックステータス(1))*2=50
*dsl:	equ	def_scr_e-def_scr
opm_data_size:	equ	1024	*((11op_reg*4ops)+5ch_reg)*8chs)*2 bytes=784+α
b_disp_mod:	equ	0
b_disp_vol:	equ	1
KRPT:		equ	20	*キーリピート開始までのディレイタイム

Z_MUSIC	macro	func		*ドライバへのファンクションコール
	moveq.l	func,d0
	trap	#3
	endm

_version	macro
	dc.b	(v_code/16)+$30,'.',($0f.and.v_code)+$30,v_code_+$30
	endm

*zsv_version	macro
*	dc.b	' ',$f3,(zsv_v_code/16)+$30,$f3,'.',$f3,($0f.and.zsv_v_code)+$30,$f3,zsv_v_code_+$30
**	dc.b	$f3,'h'
*	endm

draw	macro	x,y
	lea	$e00000+x+$80*y*8,a1
	endm

bitsns	macro	n		*IOCS	_BITSNSと同等に機能する
	move.b	$800+n.w,d0
	endm

reduce_vol	macro	reg
	* < reg.w=-32768～+32767
	* > reg.w=0～+127
	local	rav0
	local	rav1
	tst.w	reg
	bpl	rav0
	moveq.l	#0,reg
	bra	rav1
rav0:
	cmpi.w	#127,reg
	ble	rav1
	move.w	#127,reg
rav1:
	endm
*-----------------------------------------------
*		プログラムスタート
*-----------------------------------------------
	lea	mysp(pc),sp
	lea	zsv_work(pc),a6
	move.l	a3,env_bak-zsv_work(a6)	*環境変数アドレス格納

	lea	font_data(pc),a1
	move.l	a1,font_addr-zsv_work(a6)
	lea	__opn_fn(pc),a1
	move.l	a1,open_fn-zsv_work(a6)

	lea	end_of_prog(pc),a1	*program end address+1
	lea	$10(a0),a0		*メモリブロックの変更
	suba.l	a0,a1
	pea	(a1)
	pea	(a0)
	DOS	_SETBLOCK
	addq.w	#8,sp
	tst.l	d0
	bmi	out_of_memory
	suba.l	a1,a1
	IOCS	_B_SUPER
	move.l	d0,ssp-zsv_work(a6)

	move.l	#$10000,-(sp)
	DOS	_MALLOC
	addq.w	#4,sp
	tst.l	d0
	bmi	out_of_memory
	add.l	#$10000,d0
	move.l	d0,sp

	move.w	#2,-(sp)
	pea	title_mes(pc)
	DOS	_FPUTS
	addq.w	#6,sp

	tst.b	$0cbc.w			*MPUが68000ならキャッシュフラッシュ必要無し
	bne	@f
	move.w	#RTS,cache_flush-zsv_work(a6)
@@:
*	move.l	#$1_0000,-(sp)	*!debug
*	DOS	_MALLOC		*!debug
*	addq.w	#4,sp		*!debug
*	tst.l	d0		*!debug
*	bmi	out_of_memory	*!debug
*	move.l	d0,adr-zsv_work(a6)	*!debug

	pea	zmsc3_fader(pc)	*フェーダースピードの取得
	bsr	search_env
	addq.w	#4,sp
	tst.l	d0
	beq	2f
	move.l	a2,-(sp)
	move.l	d0,a2
	bsr	chk_num
	bmi	1f
	bsr	get_num
	tst.l	d1
	bpl	@f
	neg.l	d1
@@:
	cmpi.l	#65535,d1
	bhi	1f
	move.w	d1,fadeout_speed-zsv_work(a6)
	move.w	d1,fadein_speed-zsv_work(a6)
	bsr	skip_sep
	bsr	chk_num
	bmi	1f
	bsr	get_num
	tst.l	d1
	bpl	@f
	neg.l	d1
@@:
	cmpi.l	#65535,d1
	bhi	1f
	move.w	d1,fadein_speed-zsv_work(a6)
1:
	move.l	(sp)+,a2
2:
	pea	zsv_opt(pc)		*'zsv_opt'
	bsr	search_env
	addq.w	#4,sp
	tst.l	d0
	beq	@f
	move.l	a2,-(sp)
	move.l	d0,a2
	bsr	chk_optsw		*オプションスイッチ
	move.l	(sp)+,a2
@@:
	tst.b	(a2)+
	beq	go_mon
	pea	go_mon(pc)
chk_optsw:
chkoptswlp:
	move.b	(a2)+,d0
	cmpi.b	#' ',d0
	bcs	@f
	cmpi.b	#'-',d0
	beq	chk_sw
	cmpi.b	#'/',d0
	beq	chk_sw
	bra	chkoptswlp
@@:
	rts
chk_sw:
	move.b	(a2)+,d0
	andi.b	#$df,d0
	cmpi.b	#'F',d0
	beq	read_font
	cmpi.b	#'I',d0		*マスク初期化禁止スイッチ
	beq	non_mask
	cmpi.b	#'J',d0		*メッセージ表示モード
	beq	japanese_mode
	cmpi.b	#'P',d0		*パンポット表示モード
	beq	lr_pan_mode
	cmpi.b	#'R',d0		*モジュレーションリアルタイム表示モード
	beq	realtime_mode
	cmpi.b	#'V',d0		*音量／ベロシティグラフ表示モード
	beq	volvelo_mode
	bra	print_hlp

non_mask:
	clr.b	init_mask-zsv_work(a6)
	bra	chkoptswlp

japanese_mode:
	move.b	#1,lang-zsv_work(a6)	*日本語モード
	bra	chkoptswlp

lr_pan_mode:
	eori.b	#1,pan_mode-zsv_work(a6)
	bra	chkoptswlp

realtime_mode:
	bchg.b	#b_disp_mod,disp_mode-zsv_work(a6)
	bra	chkoptswlp

volvelo_mode:
	bchg.b	#b_disp_vol,disp_mode-zsv_work(a6)
	bra	chkoptswlp

read_font:
reglist	reg	d1-d2/d5/a1
	movem.l	reglist,-(sp)
	lea	filename(pc),a1
	bsr	skip_spc
	moveq.l	#0,d1
	moveq.l	#0,d2
1:
	move.b	(a2)+,d0
	cmpi.b	#'.',d0
	bne	@f
	bset.l	#31,d2
@@:
	cmpi.b	#' ',d0
	bls	1f
	move.b	d0,(a1)+
	addq.w	#1,d1
	tst.l	d2
	bpl	@f
	addq.w	#1,d2
	cmpi.w	#4,d2		*'.'も含めて拡張子は3文字まで
	beq	1f
@@:
	cmpi.w	#96,d1
	bcs	1b
1:
	clr.b	(a1)+
	move.l	a2,-(sp)
	lea	filename(pc),a2
	bsr	fopen
	move.l	(sp)+,a2
	tst.l	d5
	bmi	file_not_found

	move.l	#2048+1024,-(sp)	*+1024は念のため(2048～2079:はパレットテーブル)
	DOS	_MALLOC
	addq.w	#4,sp
	move.l	d0,font_addr-zsv_work(a6)
	bmi	out_of_memory

	move.l	#2048+1024,-(sp)		*push size
	move.l	font_addr(pc),-(sp)	*push addr
	move.w	d5,-(sp)		*file handle
	DOS	_READ
	lea	10(sp),sp
	cmpi.l	#2080,d0
	seq	ext_palet-zsv_work(a6)

	move.w	d5,-(sp)	*close
	DOS	_CLOSE
	addq.l	#2,sp

	movem.l	(sp)+,reglist
	bra	chkoptswlp

print_hlp:			*ヘルプ
	lea	hlp_mes(pc),a1
	bsr	bil_prta1

	move.w	#1,-(sp)
	DOS	_EXIT2

bil_prta1:				*日本語対応
	tst.b	lang-zsv_work(a6)	*0:英語か 1:日本語か
	beq	prta1
@@:					*次のメッセージをゲット
	tst.b	(a1)+
	bne	@b
prta1:					*non_disp!=0のときはRTS
	* x d0.l
	move.w	#2,-(sp)
	pea	(a1)
	DOS	_FPUTS
	addq.w	#6,sp
	rts

go_mon:
	bsr	chk_drv		*ドライバ常駐チェック
	bsr	init		*画面初期化
	IOCS	_OS_CUROF
				*96×33にする
	move.w	#$0020,$00e8000c
	move.w	#$0230,$00e8000e
	move.w	#trn,$972.w	*IOCSワークへ直接書き込む

*	clr.w	$e82202		*テキストパレットの設定(black)
*	clr.w	$e82204		*テキストパレットの設定(black)

	bsr	key_bind_db	*キーバインド展開

	bsr	make_scrn

	moveq.l	#-1,d1
	Z_MUSIC	#ZM_ZMUSIC_MODE
	add.b	#$30,d0
*	move.b	zm_ver(pc),d0
*	lsr.b	#4,d0
*	add.b	#$30,d0
	lea	trk_seq_tbl(pc),a2
	move.b	d0,(a2)
	move.b	#'.',1(a2)
	move.b	zm_ver(pc),d0
	andi.b	#$0f,d0
	add.b	#$30,d0
	move.b	d0,2(a2)
	move.b	zm_ver+1(pc),d0
	andi.b	#$0f,d0
	add.b	#$30,d0
	move.b	d0,3(a2)
	clr.b	4(a2)
	draw	81,4
	moveq.l	#palet30,d1
	bsr	cgwr

	Z_MUSIC	#ZM_GET_TIMER_MODE	* > d0.l=timer type(0:tm_a  1:tm_b  2:tm_m)
	move.l	#'OPM-',(a2)
	move.b	#'A',4(a2)
	clr.b	5(a2)
	move.l	#$ffff0363,FF_timer-zsv_work(a6)
	move.l	#$ffff0000,SL_timer-zsv_work(a6)
	subq.b	#1,d0
	bne	@f
	move.b	#'B',4(a2)
	move.l	#$ffff00f6,FF_timer-zsv_work(a6)
	move.l	#$ffff0000,SL_timer-zsv_work(a6)
	bra	disp_tmrmode
@@:
	subq.b	#1,d0
	bne	disp_tmrmode
	move.l	#'YM38',(a2)
	move.w	#'02',4(a2)
	clr.b	6(a2)
	move.l	#$ffff0138,FF_timer-zsv_work(a6)
	move.l	#$ffff1fff,SL_timer-zsv_work(a6)
disp_tmrmode:
	draw	72,5
	bsr	cgwr

	moveq.l	#0,d1
	Z_MUSIC	#ZM_GET_PLAY_WORK
	lea	_seq_wk_tbl(pc),a4
	move.l	a0,(a4)+		*_seq_wk_tbl
	Z_MUSIC	#ZM_GET_TRACK_TABLE	*_play_trk_tbl
	move.l	a0,(a4)+
	Z_MUSIC	#ZM_GET_BUFFER_INFORMATION
	move.l	a0,(a4)+		*_common_buffer
	Z_MUSIC	#ZM_GET_ZMSC_STATUS
	move.l	a0,(a4)+		*_zmusic_stat
	move.l	wk_size(a0),_wk_size-zsv_work(a6)	*トラックワークの1トラック当たりのサイズ
	lea	cf(a0),a0
	move.l	a0,_cf-zsv_work(a6)		*fm音源のコネクション情報
	moveq.l	#0,d1
	move.l	d1,a1
	Z_MUSIC	#ZM_SET_MASTER_CLOCK
	move.l	a0,(a4)+		*_key

	movea.l	$84.w,a0	*PCM8の有無
	cmpi.l	#'MPCM',-8(a0)
	seq.b	mpcm_flg-zsv_work(a6)

	tst.b	init_mask-zsv_work(a6)	*マスク保存するかどうか
	beq	@f
	moveq.l	#0,d1
	move.l	d1,a1
	Z_MUSIC	#ZM_MASK_TRACKS
	Z_MUSIC	#ZM_MASK_CHANNELS
@@:
	lea	global_data(pc),a0	*ワーク初期化
	move.w	#(data_end-global_data)/4-1,d0
@@:
	clr.l	(a0)+
	dbra	d0,@b
*		    G     R     B   I
	lea	$e82200,a0
	lea	std_palet(pc),a1
	moveq.l	#16-1,d0
	tst.b	ext_palet-zsv_work(a6)
	beq	@f
	move.l	font_addr-zsv_work(a6),a1
	add.w	#2048,a1
@@:
	move.w	(a1)+,(a0)+
	dbra	d0,@b
main_lp:					*メインルーチン
	lea	global_data(pc),a4
*	move.l	_trk_buffer_top(pc),d0
	move.l	_common_buffer(pc),a5
	move.l	(a5),d0
	bne	@f
	lea	dummy_data(pc),a5
	move.l	#-1,-(sp)			*disp_barで使用
	bra	disp_title
@@:
	move.l	d0,a5
	move.l	z_total_count-8(a5),-(sp)	*disp_barで使用
disp_title:					*タイトル表示
	move.l	z_title_offset-8(a5),d0
	lea	z_title_offset-8+4(a5,d0.l),a2
	lea	string(pc),a1
	moveq.l	#0,d0
	moveq.l	#0,d1
	moveq.l	#96-1,d3
@@:						*チェックサムを取る
	move.b	(a2)+,d2
	beq	@f
	cmpi.b	#' ',d2
	bcs	@f
	move.b	d2,(a1)+
	add.b	d2,d0
	eor.b	d2,d1
	dbra	d3,@b
@@:
	lsl.w	#8,d1
	or.w	d1,d0
	tas.b	(a4)+
	addq.w	#1,a4
	beq	@f
	cmp.w	(a4),d0
	bne	@f
	addq.w	#2,a4
	bra	disp_meter1
@@:
	clr.b	(a1)				*endcode
	lea	string(pc),a1
	move.w	d0,(a4)+
	bne	@f
	lea	no_title(pc),a1	*タイトル無しの場合の文字列
@@:
	moveq.l	#3,d1		*atr
	moveq.l	#0,d2		*x
	moveq.l	#0,d3		*y
	moveq.l	#96-1,d4	*len
	IOCS	_B_PUTMES
disp_meter1:
	moveq.l	#0,d0
	move.l	_meter(pc),a1
	move.b	(a1),d0		*METER分子
	tas.b	(a4)+
	beq	@f
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	disp_meter2
@@:
	move.b	d0,(a4)+
	bsr	num_to_str
	draw	7,2
	lea	suji+8(pc),a2
	moveq	#palet30,d1
	bsr	cgwr
disp_meter2:
	moveq.l	#0,d0
	move.l	_meter(pc),a1
	move.b	1(a1),d0		*METER分母
	tas.b	(a4)+
	beq	@f
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	disp_key
@@:
	move.b	d0,(a4)+
	bsr	num_to_str
	draw	10,2
	lea	suji+8(pc),a2
	moveq	#palet30,d1
	bsr	cgwr
disp_key:				*KEYの表示
	move.l	_meter(pc),a1
	moveq.l	#0,d0
	move.w	4(a1),d0		*KEY(調号)
	tas.b	(a4)+
	addq.w	#1,a4			*even
	beq	@f
	cmp.w	(a4),d0
	bne	@f
	addq.w	#2,a4
	bra	disp_usedchs
@@:
	move.w	d0,(a4)+
	lea	KEY_v_tbl(pc),a1
	moveq.l	#36-1,d1
dklp:
	cmp.w	(a1)+,d0
	beq	@f
	dbra	d1,dklp
	lea	non_key(pc),a2
	bra	do_dk
@@:
	moveq.l	#36-1,d0
	sub.w	d1,d0
	lsl.w	#3,d0
	lea	KEY_tbl(pc),a2
	add.w	d0,a2
do_dk:
	moveq.l	#palet30,d1
	draw	19,2
	bsr	cgwr
disp_usedchs:				*使用チャンネル数の表示
	draw	6,4
	moveq.l	#if_max+2-1,d2
	btst.b	#b_disp_mod,disp_mode-zsv_work(a6)
	bne	realtime_usedchs
	lea	z_nof_fm_ch-8(a5),a3
usedchslp:
	moveq.l	#0,d0
	move.b	(a3)+,d0
	tas.b	(a4)+
	beq	@f
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	next_usedchs
@@:
	move.b	d0,(a4)+
	bsr	num_to_str
	lea	suji+7(pc),a2
	moveq	#palet30,d1
	bsr	cgwr
next_usedchs:
	add.w	#11,a1
	dbra	d2,usedchslp
	bra	disp_pltm1
realtime_usedchs:			*リアルタイムケース
	lea	dev_tbl(pc),a3
rltusvclp0:
	move.w	(a3)+,d4
	moveq.l	#0,d3
	movea.l	_play_trk_tbl(pc),a0
rltusvclp1:
	move.w	(a0)+,d0
	cmpi.w	#-1,d0
	beq	disp_rltusvc
	move.l	_seq_wk_tbl(pc),a2	*a2=track work addr
	mulu	_wk_size(pc),d0
	add.l	d0,a2
	tst.b	p_track_stat(a2)
	bne	rltusvclp1
	tst.b	p_mask_mode(a2)
	bne	rltusvclp1
	cmp.w	p_type(a2),d4
	bne	rltusvclp1
	tst.w	d4
	bmi	1f
	move.b	p_how_many(a2),d0
	addq.b	#1,d0
	add.b	d0,d3
	bra	rltusvclp1
1:
	moveq.l	#max_note_on-1,d0
	lea	p_note(a2),a2
@@:
	tst.l	(a2)+
	bmi	rltusvclp1
	addq.w	#1,d3
	dbra	d0,@b
	bra	rltusvclp1
disp_rltusvc:
	move.l	d3,d0
	tas.b	(a4)+
	beq	@f
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	next_rltusvc
@@:
	move.b	d0,(a4)+
	bsr	num_to_str
	lea	suji+7(pc),a2
	moveq	#palet30,d1
	bsr	cgwr
next_rltusvc:
	add.w	#11,a1
	dbra	d2,rltusvclp0
disp_pltm1:				*演奏経過時間
	Z_MUSIC	#ZM_GET_PLAY_TIME
	tas.b	(a4)+
	addq.w	#1,a4
	beq	@f
	cmp.l	(a4),d0
	bne	@f
	addq.w	#4,a4
	bra	disp_pltm2
@@:
	move.l	d0,(a4)+
	moveq.l	#palet30,d1
	lea	suji+8(pc),a2
	draw	55,2
	move.l	d0,d2
	andi.l	#$ff,d0
	bsr	num_to_str
	bsr	cgwr
	move.l	d2,d0
	lsr.w	#8,d0
	andi.l	#$ff,d0
	draw	52,2
	bsr	num_to_str
	bsr	cgwr
	move.l	d2,d0
	swap	d0
	andi.l	#$ff,d0
	draw	49,2
	bsr	num_to_str
	bsr	cgwr
disp_pltm2:
	move.l	z_play_time-8(a5),d0
	tas.b	(a4)+
	addq.w	#1,a4
	beq	@f
	cmp.l	(a4),d0
	bne	@f
	addq.w	#4,a4
	bra	disp_prsntdt
@@:
	move.l	d0,(a4)+
	moveq.l	#palet30,d1
	lea	suji+8(pc),a2
	draw	64,2
	move.l	d0,d2
	andi.l	#$ff,d0
	bsr	num_to_str
	bsr	cgwr
	move.l	d2,d0
	lsr.w	#8,d0
	andi.l	#$ff,d0
	draw	61,2
	bsr	num_to_str
	bsr	cgwr
	move.l	d2,d0
	swap	d0
	andi.l	#$ff,d0
	draw	58,2
	bsr	num_to_str
	bsr	cgwr
disp_prsntdt:				*日付表示
	DOS	_GETDATE
	tas.b	(a4)+
	addq.w	#1,a4
	beq	@f
	cmp.l	(a4),d0
	bne	@f
	addq.w	#4,a4
	bra	disp_prsnttm
@@:
	move.l	d0,(a4)+
	moveq.l	#palet30,d1
	lea	suji+8(pc),a2
	draw	80,2
	move.l	d0,d2
	andi.l	#31,d0
	bsr	num_to_str
	bsr	cgwr
	move.l	d2,d0
	lsr.w	#5,d0
	andi.l	#$0f,d0
	draw	77,2
	bsr	num_to_str
	bsr	cgwr
	move.l	d2,d0
	rol.w	#7,d0
	andi.l	#$7f,d0
	add.w	#1980,d0
	draw	72,2
	lea	suji+6(pc),a2
	bsr	num_to_str
	bsr	cgwr
	move.l	d2,d0
	swap	d0
	lsl.w	#2,d0
	lea	DAY_tbl(pc),a2
	add.w	d0,a2
	draw	83,2
	bsr	cgwr
disp_prsnttm:
	DOS	_GETTIM2
	tas.b	(a4)+
	addq.w	#1,a4
	beq	@f
	cmp.l	(a4),d0
	bne	@f
	addq.w	#4,a4
	bra	disp_agogik
@@:
	tas.b	f_wait-zsv_work(a6)	*点滅
	move.l	d0,(a4)+
	moveq.l	#palet30,d1
	lea	suji+8(pc),a2
	draw	94,2
	move.l	d0,d2
	andi.l	#63,d0
	bsr	num_to_str
	bsr	cgwr
	move.l	d2,d0
	lsr.w	#8,d0
	andi.l	#63,d0
	draw	91,2
	bsr	num_to_str
	bsr	cgwr
	move.l	d2,d0
	swap	d0
	andi.l	#31,d0
	draw	88,2
	bsr	num_to_str
	bsr	cgwr
disp_agogik:				*アゴーギク振幅の表示
	moveq.l	#-1,d1			*ask tempo
	Z_MUSIC	#ZM_TEMPO
	moveq.l	#0,d5
	move.w	d0,d5
agogik_base:	equ	agogik_work-pmod_param
	move.l	_zmusic_stat(pc),a5
	lea.l	agogik_base(a5),a5
	moveq.l	#0,d0
	tst.b	p_pmod_sw(a5)
	beq	@f
	btst.b	#b_pmod_first,p_pmod_flg(a5)	*!3/26
	beq	@f				*!3/26
	btst.b	#b_disp_mod,disp_mode-zsv_work(a6)
	bne	agkrltm
	moveq.l	#0,d1			*振幅表示
	move.b	p_pmod_n(a5),d1
	bmi	@f
	move.w	p_pmod_dpt_now(a5),d0
	btst.b	d1,p_pmod_omt(a5)
	beq	@f
	add.w	d1,d1
*	move.w	p_pmod_pitch(a5),d0
*	ext.l	d0
*	add.l	d0,d5
	move.w	p_pmod_dpt_tbl(a5,d1.w),d0
	ext.l	d0
	bra	@f
agkrltm:				*リアルタイム表示ケース
	move.w	p_pmod_pitch(a5),d0
	ext.l	d0
	add.l	d0,d5
	cmpi.l	#1,d5
	bge	@f			*テンポなので1以下は1
	moveq.l	#1,d5
@@:
	tas.b	(a4)+
	addq.w	#1,a4
	beq	@f
	cmp.w	(a4),d0
	bne	@f
	addq.w	#2,a4
	bra	disp_tempo
@@:
	move.w	d0,(a4)+
	bsr	num_to_str
	draw	7,3
	lea	suji+4(pc),a2
	move.b	d0,(a2)			*1文字目
	moveq	#palet30,d1
	bsr	cgwr
disp_tempo:				*テンポの表示
	move.l	d5,d0
	tas.b	(a4)+
	addq.w	#1,a4
	beq	@f
	cmp.w	(a4),d0
	bne	@f
	addq.w	#2,a4
	bra	disp_agkwf
@@:
	move.w	d0,(a4)+
	bsr	num_to_str
	draw	33,2
	lea	suji+4(pc),a2
	moveq	#palet30,d1
	bsr	cgwr
disp_agkwf:				*波形タイプ表示
	moveq.l	#0,d0
	move.b	p_pmod_sw(a5),d2
	beq	@f
	btst.b	#b_pmod_first,p_pmod_flg(a5)	*!3/26
	beq	@f				*!3/26
	move.w	p_pmod_wf(a5),d0
@@:
	tas.b	(a4)+
	addq.w	#1,a4
	beq	@f
	cmp.w	(a4),d0
	bne	@f
	addq.w	#2,a4
	bra	disp_agkvrnt
@@:
	move.w	d0,(a4)+
	bpl	agkprstwf		*プリセット波形
	andi.w	#$7fff,d0
	addq.l	#8,d0			*USER波形は8番から始まるから
	bsr	num_to_str
	lea	suji+5(pc),a2
	bra	@f
agkprstwf:
	lea	DUMMY_wf(pc),a2		*スイッチオフの時の波形名
	tst.b	d2
	beq	@f
	lea	WAVE_tbl(pc),a2
	lsl.w	#3,d0
	add.w	d0,a2
@@:
	draw	19,3
	moveq	#palet30,d1
	bsr	cgwr
disp_agkvrnt:				*増減値表示
	moveq.l	#0,d0
	tst.b	p_pmod_sw(a5)
	beq	@f
	btst.b	#b_pmod_first,p_pmod_flg(a5)	*!3/26
	beq	@f				*!3/26
	btst.b	#b_pmod_dpn,p_pmod_flg(a5)
	beq	@f
	move.w	p_pmod_dpndpt(a5),d0
	ext.l	d0
@@:
	tas.b	(a4)+
	addq.w	#1,a4
	beq	@f
	cmp.w	(a4),d0
	bne	@f
	addq.w	#2,a4
	bra	disp_repeat
@@:
	move.w	d0,(a4)+
	bsr	num_to_str
	draw	33,3
	lea	suji+4(pc),a2
	move.b	d0,(a2)
	moveq	#palet30,d1
	bsr	cgwr
disp_repeat:				*繰り返し回数の表示
	moveq.l	#-1,d1			*ask
	Z_MUSIC	#ZM_LOOP_CONTROL
	cmp.l	#-1,d0
	bne	@f
	moveq.l	#0,d0			*error case
@@:
	tas.b	(a4)+
	addq.w	#1,a4
	beq	@f
	cmp.w	(a4),d0
	bne	@f
	addq.w	#2,a4
	bra	disp_bar
@@:
	move.w	d0,(a4)+
	bsr	num_to_str
	draw	49,3
	lea	suji+5(pc),a2
	moveq	#palet30,d1
	bsr	cgwr
disp_bar:				*進行バーの表示
	move.l	(sp)+,d2
	bne	@f
	moveq.l	#1,d2			*0のままだと｢0で除算しました｣が出るから
@@:
	move.l	_zmusic_stat(pc),a5
	move.l	zmusic_int(a5),d0
	cmp.l	d2,d0			*1度演奏終了している
	bls	@f
	move.l	d2,d0
@@:
	move.l	#41*8,d1
	bsr	kake		*>d1=d0*d1
	bsr	wari		*>d1=d1/d2
	tas.b	(a4)+
	addq.w	#1,a4
	beq	@f
	cmp.l	(a4),d1
	bne	@f
	addq.w	#4,a4
	bra	disp_mstrfdr
@@:
	move.l	(a4),d3		*src
	cmp.l	d3,d1
	bcc	@f
	bsr	clear_box
	moveq.l	#0,d3
@@:
	move.l	d3,d1
	addq.l	#1,d3
	move.l	d3,(a4)+	*dest
	bsr	draw_edge
disp_mstrfdr:			*MASTER FADER
	lea	mstfd_fm_spd2(a5),a0
	draw	6,5
	lea	$e00000+9+$80*5*8+$80*7,a3	*x=9,y=5
	moveq.l	#if_max+2-1,d2
mstfdrlp:				*(here will be patched)
	bsr.w	set_mstrfdr_ofs
	moveq.l	#if_max+2-1,d3
	sub.l	d2,d3
	cmp.w	#2,d3			*FM,ADPCMの場合は直値
	bcs	@f
	subq.w	#2,d3
	lea	midi_if_tbl(a5),a2
	move.b	(a2,d3.w),d3		*d3=(0,2,4,6,-1)
	andi.w	#$7f,d3			*実は未使用IFも$80+(0,2,4,6)として格納されている
	addq.w	#4,d3
	lsl.w	#2,d3			*x4
	bra	1f
@@:
	lsl.w	#3,d3			*x8
1:
	move.l	#128,d0
	tst.b	fader_flag(a5)		*Check FADER FLAG
	bpl	check_mstfdlvl		*動いていなかった
	lea	master_fader_tbl(a5),a2
@@:
	move.w	(a2)+,d1	*実際にFADERが動いているか
	bmi	check_mstfdlvl
	cmp.w	d3,d1
	bne	@b
	moveq.l	#0,d0
	move.b	fd_lvlb(a0,d3.w),d0
	cmpi.b	#128,d0		*129以上は128へ
	bls	check_mstfdlvl
	move.b	#128,d0
check_mstfdlvl:
	tas.b	(a4)+
	beq	@f
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	next_mstfdr
@@:
	moveq.l	#0,d1
	move.b	(a4),d1		*前回の位置
	bsr	draw_mixbar	*<a3.l=addr,d1=previous,d0=now
	move.b	d0,(a4)+
	bsr	num_to_str
	lea	suji+7(pc),a2
	moveq	#palet30,d1
	bsr	cgwr
next_mstfdr:
	add.w	#11,a1
	add.w	#11,a3
	dbra	d2,mstfdrlp
***********************************************************************************************
	tst.w	scr_x-zsv_work(a6)
	beq	disp_trkprms
	move.l	_zmusic_stat(pc),a5
	lea	_opm(a5),a5
	lea	opm_data(pc),a4
	move.l	#$e00000+96+$80*8*2,base_tadr-zsv_work(a6)
dispopm_clka:
	move.b	$11(a5),d1
	andi.w	#3,d1
	moveq.l	#0,d0
	move.b	$10(a5),d0
	lsl.w	#2,d0
	or.b	d1,d0
	tas.b	(a4)+
	addq.w	#1,a4
	beq	@f
	cmp.w	(a4),d0
	bne	@f
	addq.w	#2,a4
	bra	dispopm_clkb
@@:
	move.w	d0,(a4)+
	bsr	num_to_str
	lea	suji+6(pc),a2
	moveq.l	#palet30,d1
	move.l	base_tadr(pc),a1
	addq.w	#7,a1
	bsr	cgwr
dispopm_clkb:
	moveq.l	#0,d0
	move.b	$12(a5),d0
	tas.b	(a4)+
	beq	@f
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	dispopm_r14
@@:
	move.b	d0,(a4)+
	bsr	num_to_str
	lea	suji+7(pc),a2
	moveq.l	#palet30,d1
	move.l	base_tadr(pc),a1
	add.w	#18,a1
	bsr	cgwr
dispopm_r14:
	move.b	$14(a5),d0
	tas.b	(a4)+
	beq	@f
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	dispopm_ne
@@:
	move.b	d0,(a4)+
	lea	suji(pc),a2
	moveq.l	#palet30,d1
	move.l	base_tadr(pc),a1
	add.w	#26,a1
	lsl.b	#2,d0
	moveq.l	#6-1,d2
1:
	move.w	#'0'*256,(a2)
	tst.b	d0
	bpl	@f
	move.b	#'1',(a2)
@@:
	bsr	cgwr
	add.b	d0,d0
	addq.w	#1,a1
	dbra	d2,1b
dispopm_ne:
	add.l	#$80*8,base_tadr-zsv_work(a6)
	move.b	$0f(a5),d0
	rol.b	#1,d0
	andi.w	#1,d0
	tas.b	(a4)+
	beq	@f
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	dispopm_nfrq
@@:
	move.b	d0,(a4)+
	bsr	num_to_str
	lea	suji+9(pc),a2
	moveq.l	#palet30,d1
	move.l	base_tadr(pc),a1
	addq.w	#4,a1
	bsr	cgwr
dispopm_nfrq:
	move.b	$0f(a5),d0
	andi.w	#63,d0
	tas.b	(a4)+
	beq	@f
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	dispopm_wf
@@:
	move.b	d0,(a4)+
	bsr	num_to_str
	lea	suji+8(pc),a2
	moveq.l	#palet30,d1
	move.l	base_tadr(pc),a1
	add.w	#11,a1
	bsr	cgwr
dispopm_wf:
	add.l	#$80*8,base_tadr-zsv_work(a6)
	move.b	$1b(a5),d0
	andi.w	#3,d0
	tas.b	(a4)+
	beq	@f
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	dispopm_lfrq
@@:
	move.b	d0,(a4)+
	bsr	num_to_str
	lea	suji+9(pc),a2
	moveq.l	#palet30,d1
	move.l	base_tadr(pc),a1
	addq.w	#4,a1
	bsr	cgwr
dispopm_lfrq:
	move.b	$18(a5),d0
	tas.b	(a4)+
	beq	@f
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	dispopm_pmd
@@:
	move.b	d0,(a4)+
	bsr	num_to_str
	lea	suji+7(pc),a2
	moveq.l	#palet30,d1
	move.l	base_tadr(pc),a1
	add.w	#11,a1
	bsr	cgwr
dispopm_pmd:
	move.b	opm_pmd-_opm(a5),d0
	andi.w	#127,d0
	tas.b	(a4)+
	beq	@f
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	dispopm_amd
@@:
	move.b	d0,(a4)+
	bsr	num_to_str
	lea	suji+7(pc),a2
	moveq.l	#palet30,d1
	move.l	base_tadr(pc),a1
	add.w	#19,a1
	bsr	cgwr
dispopm_amd:
	move.b	$19(a5),d0
	andi.w	#127,d0
	tas.b	(a4)+
	beq	@f
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	dispopm_chprms
@@:
	move.b	d0,(a4)+
	bsr	num_to_str
	lea	suji+7(pc),a2
	moveq.l	#palet30,d1
	move.l	base_tadr(pc),a1
	add.w	#27,a1
	bsr	cgwr
dispopm_chprms:
	moveq.l	#0,d4
	moveq.l	#8-1,d7
	add.l	#$80*8*2,base_tadr-zsv_work(a6)
dispopmlp:
	move.w	#palet20,palet_tbl-zsv_work(a6)	*偶数トラック色
	btst.l	#0,d7
	bne	@f
	move.w	#palet30,palet_tbl-zsv_work(a6)	*奇数トラック色
@@:					*これから表示しようとしているトラックは
	move.b	$20(a5,d4.w),d0
	tas.b	(a4)+
	beq	@f
	andi.w	#7,d0		*AL
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	dispopm_fb
@@:
	move.b	d0,(a4)+
	bsr	num_to_str2
	lea	suji+9(pc),a2
	move.w	palet_tbl(pc),d1
	move.l	base_tadr(pc),a1
	addq.w	#8,a1
	bsr	cgwr
dispopm_fb:
	move.b	$20(a5,d4.w),d0
	tas.b	(a4)+
	beq	@f
	lsr.w	#3,d0
	andi.w	#7,d0		*FB
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	dispopm_pms
@@:
	move.b	d0,(a4)+
	bsr	num_to_str2
	lea	suji+9(pc),a2
	move.w	palet_tbl(pc),d1
	move.l	base_tadr(pc),a1
	add.w	#13,a1
	bsr	cgwr
dispopm_pms:
	move.b	$38(a5,d4.w),d0
	tas.b	(a4)+
	beq	@f
	lsr.w	#4,d0
	andi.w	#7,d0		*PMS
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	dispopm_ams
@@:
	move.b	d0,(a4)+
	bsr	num_to_str2
	lea	suji+9(pc),a2
	move.w	palet_tbl(pc),d1
	move.l	base_tadr(pc),a1
	add.w	#19,a1
	bsr	cgwr
dispopm_ams:
	move.b	$38(a5,d4.w),d0
	tas.b	(a4)+
	beq	@f
	andi.w	#3,d0		*AMS
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	dispopm_pan
@@:
	move.b	d0,(a4)+
	bsr	num_to_str2
	lea	suji+9(pc),a2
	move.w	palet_tbl(pc),d1
	move.l	base_tadr(pc),a1
	add.w	#25,a1
	bsr	cgwr
dispopm_pan:
	move.b	$20(a5,d4.w),d0
	tas.b	(a4)+
	beq	@f
	rol.b	#2,d0
	andi.w	#3,d0		*PAN
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	dispopm_ops
@@:
	move.b	d0,(a4)+
	bsr	num_to_str2
	lea	suji+9(pc),a2
	move.w	palet_tbl(pc),d1
	move.l	base_tadr(pc),a1
	add.w	#31,a1
	bsr	cgwr
dispopm_ops:
	add.l	#$80*8*2,base_tadr-zsv_work(a6)
	moveq.l	#4-1,d6		*オペレータ数
	lea	op_ofs(pc),a0
dispopmopslp:
	move.l	d4,d5
	add.w	#$80,d5		*KS/AR
	add.w	(a0),d5
	move.b	(a5,d5.w),d0
	tas.b	(a4)+
	beq	@f
	andi.w	#31,d0
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	dispopm_dr
@@:
	move.b	d0,(a4)+
	bsr	num_to_str2
	lea	suji+8(pc),a2
	move.w	palet_tbl(pc),d1
	move.l	base_tadr(pc),a1
	addq.w	#1,a1
	bsr	cgwr
dispopm_dr:
	move.l	d4,d5
	add.w	#$a0,d5		*AMS-EN DR(1DR)
	add.w	(a0),d5
	move.b	(a5,d5.w),d0
	tas.b	(a4)+
	beq	@f
	andi.w	#31,d0
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	dispopm_sr
@@:
	move.b	d0,(a4)+
	bsr	num_to_str2
	lea	suji+8(pc),a2
	move.w	palet_tbl(pc),d1
	move.l	base_tadr(pc),a1
	addq.w	#4,a1
	bsr	cgwr
dispopm_sr:
	move.l	d4,d5
	add.w	#$c0,d5		*DT2 SR(2DR)
	add.w	(a0),d5
	move.b	(a5,d5.w),d0
	tas.b	(a4)+
	beq	@f
	andi.w	#31,d0
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	dispopm_rr
@@:
	move.b	d0,(a4)+
	bsr	num_to_str2
	lea	suji+8(pc),a2
	move.w	palet_tbl(pc),d1
	move.l	base_tadr(pc),a1
	addq.w	#7,a1
	bsr	cgwr
dispopm_rr:
	move.l	d4,d5
	add.w	#$e0,d5		*SL(1DL) RR
	add.w	(a0),d5
	move.b	(a5,d5.w),d0
	tas.b	(a4)+
	beq	@f
	andi.w	#15,d0
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	dispopm_sl
@@:
	move.b	d0,(a4)+
	bsr	num_to_str2
	lea	suji+8(pc),a2
	move.w	palet_tbl(pc),d1
	move.l	base_tadr(pc),a1
	add.w	#10,a1
	bsr	cgwr
dispopm_sl:
	move.l	d4,d5
	add.w	#$e0,d5		*SL(1DL) RR
	add.w	(a0),d5
	move.b	(a5,d5.w),d0
	tas.b	(a4)+
	beq	@f
	lsr.b	#4,d0
	andi.w	#15,d0
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	dispopm_tlv
@@:
	move.b	d0,(a4)+
	bsr	num_to_str2
	lea	suji+8(pc),a2
	move.w	palet_tbl(pc),d1
	move.l	base_tadr(pc),a1
	add.w	#13,a1
	bsr	cgwr
dispopm_tlv:
	move.l	d4,d5
	add.w	#$60,d5		*TL
	add.w	(a0),d5
	move.b	(a5,d5.w),d0
	tas.b	(a4)+
	beq	@f
	andi.w	#127,d0
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	dispopm_ks
@@:
	move.b	d0,(a4)+
	bsr	num_to_str2
	lea	suji+7(pc),a2
	move.w	palet_tbl(pc),d1
	move.l	base_tadr(pc),a1
	add.w	#16,a1
	bsr	cgwr
dispopm_ks:
	move.l	d4,d5
	add.w	#$80,d5		*KS
	add.w	(a0),d5
	move.b	(a5,d5.w),d0
	tas.b	(a4)+
	beq	@f
	rol.b	#2,d0
	andi.w	#3,d0
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	dispopm_ml
@@:
	move.b	d0,(a4)+
	bsr	num_to_str2
	lea	suji+9(pc),a2
	move.w	palet_tbl(pc),d1
	move.l	base_tadr(pc),a1
	add.w	#20,a1
	bsr	cgwr
dispopm_ml:
	move.l	d4,d5
	add.w	#$40,d5		*DT1 ML
	add.w	(a0),d5
	move.b	(a5,d5.w),d0
	tas.b	(a4)+
	beq	@f
	andi.w	#15,d0
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	dispopm_dt1
@@:
	move.b	d0,(a4)+
	bsr	num_to_str2
	lea	suji+8(pc),a2
	move.w	palet_tbl(pc),d1
	move.l	base_tadr(pc),a1
	add.w	#22,a1
	bsr	cgwr
dispopm_dt1:
	move.l	d4,d5
	add.w	#$40,d5		*DT1 ML
	add.w	(a0),d5
	move.b	(a5,d5.w),d0
	tas.b	(a4)+
	beq	@f
	lsr.b	#4,d0
	andi.w	#7,d0
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	dispopm_dt2
@@:
	move.b	d0,(a4)+
	bsr	num_to_str2
	lea	suji+9(pc),a2
	move.w	palet_tbl(pc),d1
	move.l	base_tadr(pc),a1
	add.w	#26,a1
	bsr	cgwr
dispopm_dt2:
	move.l	d4,d5
	add.w	#$c0,d5		*DT2 SR(2DR)
	add.w	(a0),d5
	move.b	(a5,d5.w),d0
	tas.b	(a4)+
	beq	@f
	rol.b	#2,d0
	andi.w	#3,d0
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	dispopm_ame
@@:
	move.b	d0,(a4)+
	bsr	num_to_str2
	lea	suji+9(pc),a2
	move.w	palet_tbl(pc),d1
	move.l	base_tadr(pc),a1
	add.w	#29,a1
	bsr	cgwr
dispopm_ame:
	move.l	d4,d5
	add.w	#$a0,d5		*AMS-EN DR(1DR)
	add.w	(a0),d5
	move.b	(a5,d5.w),d0
	tas.b	(a4)+
	beq	@f
	rol.b	#1,d0
	andi.w	#1,d0
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	next_dispopm
@@:
	move.b	d0,(a4)+
	bsr	num_to_str2
	lea	suji+9(pc),a2
	move.w	palet_tbl(pc),d1
	move.l	base_tadr(pc),a1
	add.w	#31,a1
	bsr	cgwr
next_dispopm:
	add.l	#$80*8,base_tadr-zsv_work(a6)
	addq.w	#2,a0
	dbra	d6,dispopmopslp
	addq.w	#1,d4
	dbra	d7,dispopmlp
***********************************************************************************************
disp_trkprms:				*トラックパラメータ表示セクション
	moveq.l	#0,d7
	move.w	disp_start(pc),d7	*表示開始トラック(この値から10トラック分の表示となる)
	moveq.l	#10-1,d6		*loop counter
	lea	track_data(pc),a4
	move.l	#$e00000+0+$80*6*8,base_tadr-zsv_work(a6)	*表示アドレス0,6
dstp_lp00:
	pea	dtsz(a4)
	movea.l	_play_trk_tbl(pc),a0
	move.l	#palet30*65536+palet30,palet_tbl-zsv_work(a6)	*偶数トラック色
	move.w	#palet40,palet_tbl+4-zsv_work(a6)		*KON
	move.l	#$4_0000,plane-zsv_work(a6)			*鍵盤書き込みプレーンオフセット
	btst.l	#0,d7
	bne	@f
	move.l	#palet20*65536+palet20,palet_tbl-zsv_work(a6)	*奇数トラック色
@@:					*これから表示しようとしているトラックは
	move.w	(a0)+,d0		*演奏されているのかチェック
	cmpi.w	#-1,d0
	beq	no_disp_case		*なし
	cmp.w	d0,d7
	bne	@b
	lea	no_disp_tbl(pc),a1
	bclr.b	#7,(a1,d6.w)		*no_disp_caseを実行したことがあるかフラグ初期化
	beq	@f
	clr.b	(a4)			*デッド→アクティヴのケースに対応
@@:
	move.l	_seq_wk_tbl(pc),a5	*a5=track work addr
	mulu	_wk_size(pc),d0
	add.l	d0,a5

	move.l	p_type(a5),d4
	move.b	p_mask_mode(a5),d0		*トラックマスクか
	bne	get_trstat			*MASK
	move.l	_zmusic_stat(pc),a1		*チャンネルマスクか
	move.l	d4,d1
	bmi	gttrst_md
	swap	d1
	tst.w	d1
	bne	gttrst_ad
gttrst_fm:
	btst.b	d4,ch_mask_fm+1(a1)		*FMのチャンネルマスク状態チェック
	sne	d0
	bra	get_trstat
gttrst_ad:					*ADPCMチャンネルマスク状態チェック
	move.w	ch_mask_ad(a1),d0
	bra	@f
gttrst_md:					*MIDIチャンネルマスク状態チェック
	swap	d1
	lea	ch_mask_m0(a1),a1
	add.w	d1,d1
	move.w	(a1,d1.w),d0
@@:
	btst.l	d4,d0
	sne	d0
get_trstat:
	lsl.w	#8,d0
	bmi	@f
	move.b	p_track_stat(a5),d0
	beq	do_drtrpr
@@:
	move.w	#paleta0,palet_tbl+0-zsv_work(a6)	*ノンアクティヴトラックはダーク色
	move.w	#palet10,palet_tbl+4-zsv_work(a6)	*KON
	clr.l	plane-zsv_work(a6)			*鍵盤書き込みプレーンオフセット
do_drtrpr:				*track statの変化吟味
	tas.b	(a4)+
	addq.w	#1,a4
	beq	draw_trkttl
	cmp.w	(a4),d0			*ステータスに変更が見られた
	bne	@f
	addq.w	#2,a4
	bra	get_trkdev
@@:					*コピーする
	move.w	d0,(a4)
	beq	@f
	bsr	copy_plane2		*アクティヴ→ノンアクティヴ
	bra	get_trkmode
@@:
	bsr	copy_plane1		*ノンアクティヴ→アクティヴ
	bra	get_trkmode
draw_trkttl:				*初めての表示の時はパラメタタイトルを描画
	move.w	d0,(a4)
	bsr	do_draw_trkprms
get_trkmode:				*モード
	bsr	clr_track_data

	move.l	base_tadr(pc),a1
	add.w	#46+$80*8*2,a1			*トリムを消す
	moveq.l	#palet70,d1
	lea	trim_vanish(pc),a2
	bsr	cgwr
	add.w	#$80*8,a1
	bsr	cgwr
	addq.w	#1,a2
	add.w	#$80*8,a1
	bsr	cgwr
	add.w	#$80*8,a1
	bsr	cgwr
	add.w	#48-$80*8*3,a1
	bsr	cgwr
	addq.w	#1,a2
	add.w	#$80*8+1,a1
	bsr	cgwr

	move.l	base_tadr(pc),a1
	add.w	#23,a1
	moveq.l	#paletf0,d1
	lea	trkmd_Vanish(pc),a2
	bsr	cgwr
	lea	trkmd_NORMAL(pc),a2
	move.w	palet_tbl(pc),d1
	or.w	palet_tbl+4(pc),d1
	move.w	(a4)+,d0
	beq	@f
*	move.w	palet_tbl(pc),d1
	moveq.l	#paletf0,d1		*flash palet
	lea	trkmd_PTRN(pc),a2
	cmpi.b	#ID_PATTERN,d0		*PATTERN
	beq	@f
	lea	trkmd_DEAD(pc),a2
	tst.b	d0
	bmi	@f			*DEAD
	lea	trkmd_END(pc),a2
	btst.l	#_ID_END,d0
	bne	@f			*END
	lea	trkmd_MASK(pc),a2
	tst.w	d0
	bmi	@f			*MASK
	lea	trkmd_STOP(pc),a2
	btst.l	#_ID_PLAY_STOP,d0
	bne	@f			*STOP
	lea	trkmd_SYNC(pc),a2
	btst.l	#_ID_SYNC,d0
	bne	@f			*SYNC
	lea	trkmd_REC(pc),a2
	btst.l	#_ID_REC,d0
	bne	@f			*REC
	lea	trkmd_SE(pc),a2
@@:
	bsr	cgwr
get_trkdev:				*デバイス
	tas.b	(a4)+
	addq.w	#1,a4
	beq	@f
	cmp.l	(a4),d4
	bne	@f
	addq.w	#4,a4
	bra	disp_chfdr
@@:
	moveq.l	#paletf0,d1
	lea	ch_vanish(pc),a2
	move.l	base_tadr(pc),a1
	addq.w	#6,a1
	bsr	cgwr			*消す
	move.l	d4,d0
	move.l	d4,d1
	move.l	d0,(a4)+
	bmi	gtrkdv_md
	swap	d0
	cmpi.w	#DEV_PATTERN,d0
	beq	disp_chfdr
	tst.w	d0			*ADPCM?
	bne	gtrkdv_ad
	lea	ch_fm(pc),a2		*FM
	add.b	#'1',d1
	move.b	d1,5(a2)
	moveq.l	#palet90,d1
	bsr	cgwr
	bra	disp_chfdr
gtrkdv_ad:
	lea	ch_ad(pc),a2		*ADPCM
	move.b	#'0',5(a2)
	addq.b	#1,d1
	cmp.w	#9,d1
	bls	@f
	sub.w	#10,d1
	move.b	#'1',5(a2)
@@:
	add.b	#'0',d1
	move.b	d1,6(a2)
	moveq.l	#paletc0,d1
	bsr	cgwr
	bra	disp_chfdr
gtrkdv_md:
	lea	ch_md(pc),a2		*MIDI
	move.w	p_midi_if(a5),d0	*swap	d0
	add.b	#'1',d0
	move.b	d0,5(a2)		*dev
	move.b	#'0',7(a2)
	addq.b	#1,d1
	cmp.w	#9,d1
	bls	@f
	move.b	#'1',7(a2)
	sub.b	#10,d1
@@:
	add.b	#'0',d1
	move.b	d1,8(a2)
	moveq.l	#palete0,d1
	bsr	cgwr
disp_chfdr:
	move.l	_zmusic_stat(pc),a2
	lea	ch_fm_fdp(a2),a0
	bsr	ch_odr_no		*>d3.w=ID
	move.l	#128,d0
	btst.b	#6,fader_flag(a2)		*Check CH FADER FLAG
	beq	check_chfdlvl
	lea	ch_fader_tbl(a2),a2
@@:
	move.w	(a2)+,d1	*実際にFADERが動いているか
	bmi	check_chfdlvl	*動いていなかった
	cmp.w	d3,d1
	bne	@b
	moveq.l	#0,d0
	lsl.w	#fd_wkl_,d3
	move.b	fd_lvlb(a0,d3.w),d0
	cmpi.b	#128,d0		*129以上は128へ
	bls	check_chfdlvl
	move.b	#128,d0
check_chfdlvl:
	tas.b	(a4)+
	beq	@f
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	get_trkwkadr
@@:
	moveq.l	#0,d1
	move.b	(a4),d1		*前回の位置
	move.l	base_tadr(pc),a1
	lea	95+$80*3*8+$80*7(a1),a3	*x=95,y=3
	bsr	draw_mixbar	*<a3.l=addr,d1=previous,d0=now
	move.b	d0,(a4)+
	bsr	num_to_str
	lea	suji+7(pc),a2
	move.w	palet_tbl(pc),d1
	add.w	#93,a1
	bsr	cgwr
get_trkwkadr:				*(Here will be patched)
	move.l	a4,trkwkadr_adr-zsv_work(a6)
*	move.b	p_velo(a5),velo_buf+1-zsv_work(a6)
	move.b	-1(a4),chfdr_buf+1-zsv_work(a6)	*CH FADERの値をコピー(disp_attackで使用)
	move.l	p_now_pointer(a5),d0
	move.l	d0,a0
	tas.b	(a4)+
	addq.w	#1,a4
	beq	@f
	cmp.l	(a4),d0
	bne	@f
	addq.w	#8,a4			*ポインタ.lのあとにZMD.w,VELOCITY.w
	bra	disp_attack
@@:
	move.l	d0,(a4)+
	bsr	get_hex32
	move.l	base_tadr(pc),a1
	add.w	#31,a1
	lea	suji(pc),a2
	move.w	palet_tbl(pc),d1
	bsr	cgwr
					*ZMD 表示
	move.w	(a4),d5
	moveq.l	#0,d0
	move.b	(a0)+,d0
	move.w	d0,(a4)+
	bsr	get_hex
	move.l	base_tadr(pc),a1
	add.w	#40,a1
	lea	suji(pc),a2
	move.w	palet_tbl(pc),d1
	bsr	cgwr
	addq.w	#3,a1
	tst.b	d0			*NOTEかその他の特殊コマンドか
	bmi	disp_cmd
	bsr	make_note		*NOTE文字列作成
	lea	suji(pc),a2
	bsr	cgwr
	movem.l	d0/d5/a4,-(sp)
	bsr	get_st_gt_vl		*d1=step,d2=gate,d3=velocity
	movem.l	(sp)+,d0/d5/a4
*	move.b	d3,velo_buf+1-zsv_work(a6)
	move.l	d2,-(sp)
	move.l	d1,d0
	bsr	num_to_str
	addq.w	#5,a1
	move.w	palet_tbl(pc),d1
	lea	suji+5(pc),a2
	bsr	cgwr			*step
	addq.w	#6,a1
	move.l	(sp)+,d0
	cmp.l	#TIE_GATE,d0
	beq	@f
	bsr	num_to_str
	lea	suji+5(pc),a2
	bsr	cgwr			*gate
	bra	1f
@@:					*タイ
	lea	TIE_str(pc),a2
	bsr	cgwr
1:
	addq.w	#6,a1
	moveq.l	#0,d0
disp_nn_velo:
	move.b	d3,d0
	move.w	d0,(a4)+		*VELOCITY.w
	bsr	num_to_str
	lea	suji+7(pc),a2
	bsr	cgwr			*velocity
	addq.w	#3,a1
	tst.b	d5			*前がノート系でなければエリア消去する
	bpl	disp_calm
	lea	Vanish_cmd(pc),a2
	bsr	cgwr
disp_attack:				*アタックレベルグラフ表示
	moveq.l	#0,d2
	move.b	(a4),d2			*前のアタックレベル
	move.b	1(a4),d3		*count
	cmpi.w	#paleta0,palet_tbl-zsv_work(a6)	*ノンアクティヴならば不要
	beq	disp_calm
	bclr.b	#b_keyon,p_onoff_bit(a5)
	beq	disp_calm
	tst.b	d2
	bpl	@f
	moveq.l	#0,d2
@@:
	moveq.l	#0,d1
	move.b	p_vol(a5),d1
	mulu	-2(a4),d1		*velo_buf
	lsr.w	#8,d1
	lsr.w	#2,d1			*1024
	mulu	chfdr_buf(pc),d1	*FADER考慮
	lsr.w	#7,d1
	move.b	d1,(a4)			*保存
	move.l	base_tadr(pc),a1
	lea	95+$80*5*8+$80*7(a1),a3
	bsr	draw_attack		*<a3.l=address,d1.l=level(now),d2=level(previous)
	bra	disp_bank

disp_cmd:				*ノート番号以外のZMD
	sub.b	#$80,d0
	cmpi.w	#$05,d0
	bhi	other_cmd
	add.w	d0,d0
	move.w	@f(pc,d0.w),d0
	jmp	@f(pc,d0.w)
@@:
	dc.w	_rest-@b		*$80
	dc.w	_wait-@b		*$81
	dc.w	_track_delay-@b		*$82
	dc.w	_mx_key-@b		*$83
	dc.w	_portament-@b		*$84
	dc.w	_portament-@b		*$85

other_cmd:
	addq.w	#2,a4			*skip VELOCITY.w
	lea	Vanish_nn(pc),a2
	bsr	cgwr
	bra	disp_calm

_portament:				*ポルタメント
	moveq.l	#0,d0
	move.b	(a0)+,d0
	move.l	d0,d3
	andi.l	#$7f,d0
	bsr	make_note		*NOTE文字列作成
	lea	suji(pc),a2
	bsr	cgwr			*note
	moveq.l	#0,d2
	move.b	(a0)+,d2		*dest.note
	tst.b	d3
	bpl	@f
	bsr	skip_@v			*skip delay
@@:
	tst.b	d2
	bpl	@f
	bsr	skip_@v			*skip port.time
@@:
	move.l	d2,-(sp)
	movem.l	d0/d5/a4,-(sp)
	bsr	get_st_gt_vl		*d1=step,d2=gate,d3=velocity
	movem.l	(sp)+,d0/d5/a4
*	move.b	d3,velo_buf+1-zsv_work(a6)
	move.l	d1,-(sp)
	move.l	d2,d0
	bsr	num_to_str
	addq.w	#5,a1
	move.w	palet_tbl(pc),d1
	lea	suji+5(pc),a2
	bsr	cgwr			*gate
	move.l	(sp)+,d0
	bsr	num_to_str
	addq.w	#6,a1
	lea	suji+5(pc),a2
	bsr	cgwr			*step
	addq.w	#6,a1
	moveq.l	#0,d0
	move.b	d3,d0
	move.w	d0,(a4)+		*VELOCITY.w
	bsr	num_to_str
	lea	suji+7(pc),a2
	bsr	cgwr			*velocity
	addq.w	#3,a1
	lea	Portament_nn(pc),a2
	bsr	cgwr
	add.w	#14,a1
	move.l	(sp)+,d0
	andi.l	#$7f,d0
	bsr	make_note
	lea	suji(pc),a2
	bsr	cgwr			*note
	bra	disp_attack

_mx_key:				*MXキー
	moveq.l	#0,d0
	move.b	(a0)+,d0
	move.l	d0,d3
	andi.l	#$7f,d0
	bsr	make_note		*NOTE文字列作成
	lea	suji(pc),a2
	bsr	cgwr			*note
	bsr	get_st
	bsr	calc_gate		*d1.w=step,d2.w=gate
	move.l	d1,-(sp)
	move.l	d2,d0
	bsr	num_to_str
	addq.w	#5,a1
	move.w	palet_tbl(pc),d1
	lea	suji+5(pc),a2
	bsr	cgwr			*gate
	move.l	(sp)+,d0
	bsr	num_to_str
	addq.w	#6,a1
	lea	suji+5(pc),a2
	bsr	cgwr			*step
	addq.w	#6,a1
	tst.b	d3
	bmi	@f
	lea	dummy_velo(pc),a0	*ダミーベロシティにポイントさせる
	movem.l	d0/d5/a4,-(sp)
	bsr	get_def_velo		*>d3.b=velocity
	movem.l	(sp)+,d0/d5/a4
	bra	disp_nn_velo
@@:
	movem.l	d0/d5/a4,-(sp)
	bsr	get_def_velo		*>d3.b=velocity
	movem.l	(sp)+,d0/d5/a4
	bra	disp_nn_velo

_track_delay:				*トラックディレイ
_wait:					*ウェイト
	lea	Wait_nn(pc),a2
	bsr	cgwr
	bsr	get_st			*d1=step
	move.l	d1,-(sp)
	addq.w	#5,a1
	move.w	palet_tbl(pc),d1
	lea	Dummy_gate(pc),a2
	bsr	cgwr			*gate
	bra	rest00
_rest:					*休符
	lea	Rest_nn(pc),a2
	bsr	cgwr
	bsr	get_st_gt		*d1=step,d2=gate
	move.l	d1,-(sp)
	move.l	d2,d0
	bsr	num_to_str
	addq.w	#5,a1
	move.w	palet_tbl(pc),d1
	lea	suji+5(pc),a2
	bsr	cgwr			*gate
rest00:
	move.l	(sp)+,d0
	bsr	num_to_str
	addq.w	#6,a1
	lea	suji+5(pc),a2
	bsr	cgwr			*step
	addq.w	#6,a1
	addq.w	#2,a4			*skip VELOCITY.W
	lea	Rest_velo(pc),a2
	bsr	cgwr
	add.w	#3,a1
	tst.b	d5			*前がノート系でなければエリア消去する
	bpl	disp_calm
	lea	Vanish_cmd(pc),a2
	bsr	cgwr
disp_calm:				*グラフ減衰
	moveq.l	#0,d2
	move.b	(a4),d2			*前のアタックレベル
	move.b	1(a4),d3		*count
	tst.b	d2
	bmi	disp_bank		*すでにゼロ
	cmp.b	1(a5),d3
	beq	disp_bank
	move.b	1(a5),1(a4)
	move.l	base_tadr(pc),a3
	add.w	#95+$80*5*8+$80*7,a3
	bsr	draw_release		*<a3.l=address,d2.l=level
	subq.b	#1,d2
	move.b	d2,(a4)
disp_bank:			*音色バンク
	addq.w	#2,a4		*disp_attack,disp_calmのワークをスキップ
sbo_patch:			*(here will be patched)
	bsr.w	set_bank_ofs
	moveq.l	#0,d0
	move.w	p_bank_msb(a5),d0
	tas.b	(a4)+
	addq.w	#1,a4
	beq	@f
	cmp.w	(a4),d0
	bne	@f
	addq.w	#2,a4
	bra	disp_timbre
@@:
	move.w	d0,(a4)+
	cmpi.w	#-1,d0
	beq	disp_timbre
	move.b	bank_mode(pc),d1
	bne	@f
	lsr.w	#8,d0			*上位7ビットのみ表示(mode=0)
	tst.b	d0			*下位７ビットチェック
	bmi	disp_timbre
	bra	2f
@@:
	subq.b	#1,d1
	beq	1f
					*mode=2の場合
	moveq.l	#0,d0			*7bit:7bit-7bit
	move.b	p_bank_msb(a5),d0
	bsr	num_to_str
	lea	suji+7(pc),a2
	move.b	#':',3(a2)
	clr.b	4(a2)
	move.l	base_tadr(pc),a1
	add.w	#$80*1*8+7,a1
	move.w	palet_tbl(pc),d1
	bsr	cgwr
	moveq.l	#0,d0
	move.b	p_bank_lsb(a5),d0
	bsr	num_to_str
	lea	suji+7(pc),a2
	move.b	#'-',3(a2)
	clr.b	4(a2)
	addq.w	#4,a1
	bsr	cgwr
	bra	disp_timbre
1:					*14ビット表示(mode=1)
	move.w	d0,d1
	andi.w	#$7f00,d0
	andi.w	#$7f,d1
	lsr.w	d0
	or.b	d1,d0
2:
	bsr	num_to_str
	lea	suji+5(pc),a2
	move.b	#'-',5(a2)
	clr.b	6(a2)
	move.l	base_tadr(pc),a1
	add.w	#$80*1*8+7,a1
	move.w	palet_tbl(pc),d1
	bsr	cgwr
disp_timbre:				*(here will be patched)
	bsr.w	set_timbre_ofs
	moveq.l	#0,d0
	move.w	p_pgm(a5),d0
	tas.b	(a4)+
	addq.w	#1,a4
	beq	@f
	cmp.w	(a4),d0
	bne	@f
	addq.w	#2,a4
	bra	disp_velo
@@:
	move.w	d0,(a4)+
	move.l	base_tadr(pc),a1
	add.w	#$80*1*8+7,a1
	tst.b	bank_mode-zsv_work(a6)
	bne	@f			*lsb表示モードの時にlsbが-1ならば
					*mode=0(上位7bit)
	tst.b	-5(a4)			*check lsb
	bmi	1f
@@:					*mode=1(14bit) or 2(7:7:7)
	cmpi.w	#-1,-6(a4)		*check bank
	beq	1f
	addq.w	#6,a1
	cmpi.b	#2,bank_mode-zsv_work(a6)
	bne	@f
					*mode=2(7bit:7bit:7bit表示モードならば)
	addq.w	#2,a1
	addq.w	#1,d0
	bsr	num_to_str
	lea	suji+7(pc),a2
	move.w	palet_tbl(pc),d1
	bsr	cgwr
	bra	disp_velo
@@:
	addq.w	#1,d0
	bsr	num_to_str
	lea	suji+5(pc),a2
	move.w	palet_tbl(pc),d1
	bsr	cgwr
	bra	disp_velo
1:					*５桁表示
	addq.w	#1,d0
	bsr	num_to_str
	lea	suji+5(pc),a2
	move.w	palet_tbl(pc),d1
	bsr	cgwr
	addq.w	#5,a1
	lea	timbre_bkspc(pc),a2
	bsr	cgwr
disp_velo:				*(here will be patched)
	bsr.w	set_velo_ofs
	moveq.l	#0,d0
	move.b	p_velo(a5),d0
	btst.b	#b_disp_mod,disp_mode-zsv_work(a6)
	beq	1f
	btst.b	#b_disp_vol,disp_mode-zsv_work(a6)
	beq	@f
	move.l	trkwkadr_adr-zsv_work(a6),a1
	move.w	8(a1),d0
	bra	1f
@@:
	lea	p_vseq_param(a5),a1
	move.b	p_arcc_origin(a1),d0
1:
	tas.b	(a4)+
	beq	@f
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	disp_dtn
@@:
	move.b	d0,(a4)+
	btst.b	#b_disp_vol,disp_mode-zsv_work(a6)
	bne	@f
	bsr	num_to_str
	move.l	base_tadr(pc),a1
	add.w	#$80*8*1+39,a1
	lea	Vanish_volvelo(pc),a2
	moveq.l	#paletf0,d1
	bsr	cgwr
	lea	suji+7(pc),a2
	move.w	palet_tbl(pc),d1
	bsr	cgwr
	bra	disp_dtn
@@:
	move.l	base_tadr(pc),a1
	add.w	#$80*8*1+39,a1
	lea	Vanish_volvelo(pc),a2
	moveq.l	#paleta0,d1
	bsr	cgwr
	move.w	#palet50,d1
	tst.w	p_type(a5)
	bne	2f
	cmpi.w	#7,d4
	bne	@f
	move.l	_zmusic_stat(pc),a2
	tst.b	$0f+_opm(a2)
	bpl	@f
	bsr	draw_hbar_fm_noise
	bra	1f
@@:
	bsr	draw_hbar_fm		*< d0.b=0-127
	bra	1f
2:
	bsr	draw_hbar		*< d0.b=0-127
1:
disp_dtn:				*detune
	move.w	p_detune(a5),d0
	ext.l	d0
	move.l	d0,d5
	tas.b	(a4)+
	addq.w	#1,a4
	beq	@f
	cmp.w	(a4),d0
	bne	@f
	addq.w	#2,a4
	bra	disp_pitch
@@:
	move.w	d0,(a4)+
	bsr	num_to_str
	move.l	base_tadr(pc),a1
	add.w	#$80*8*1+50,a1
	lea	suji+4(pc),a2
	move.b	d0,(a2)			*1文字目
	move.w	palet_tbl(pc),d1
	bsr	cgwr
disp_pitch:				*ピッチベンダー
*	moveq.l	#0,d0
*	tst.b	p_port_flg(a5)	*ポルタメントチェック
*	bne	@f
*	tst.b	p_bend_sw(a5)	*オートベンドチェック
*	beq	1f
*@@:
	move.w	p_port_pitch(a5),d0
	ext.l	d0
1:
	add.l	d0,d5
	tas.b	(a4)+
	addq.w	#1,a4
	beq	@f
	cmp.w	(a4),d0
	bne	@f
	addq.w	#2,a4
	bra	disp_hold
@@:
	move.w	d0,(a4)+
	move.l	base_tadr(pc),a1
	bsr	num_to_str
	add.w	#$80*8*1+63,a1
	lea	suji+4(pc),a2
	move.b	d0,(a2)			*1文字目
	move.w	palet_tbl(pc),d1
	bsr	cgwr
disp_hold:				*ダンパー
	moveq.l	#0,d0
	move.b	p_damper(a5),d0
	tas.b	(a4)+
	beq	@f
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	disp_trmode
@@:
	moveq.l	#0,d1
	move.b	(a4),d1
	move.b	d0,(a4)+
	move.l	base_tadr(pc),a1
	lea	94+$80*2*8+$80*7(a1),a3	*x=48,y=2
	bsr	draw_pedal
	bsr	num_to_str
	add.w	#$80*8*1+85,a1
	lea	suji+7(pc),a2
	move.w	palet_tbl(pc),d1
	bsr	cgwr
disp_trmode:
	move.b	p_track_mode(a5),d0
	tas.b	(a4)+
	beq	@f
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	disp_aftc
@@:
	move.b	d0,(a4)+
	move.l	base_tadr(pc),a1
	lea	94+$80*3*8(a1),a3	*x=48,y=3
	bsr	draw_lamp
disp_aftc:				*アフタータッチ
	moveq.l	#-1,d0
	tst.b	p_aftc_sw(a5)
	beq	@f
	btst.b	#b_aftc_first,p_aftc_flg(a5)	*!3/26
	beq	@f				*!3/26
	btst.b	#b_disp_mod,disp_mode-zsv_work(a6)
	bne	aftrltm
	moveq.l	#0,d1			*振幅表示
	move.b	p_aftc_n(a5),d1
	bmi	@f
	btst.b	d1,p_aftc_omt(a5)
	beq	@f
	moveq.l	#0,d0
	move.b	p_aftc_tbl(a5,d1.w),d0
	bra	@f
aftrltm:				*リアルタイム表示ケース
	moveq.l	#0,d0
	move.b	p_aftc_level(a5),d0
@@:
	tas.b	(a4)+
	beq	@f
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	disp_vib
@@:
	move.b	d0,(a4)+
	bpl	@f
	lea	aftc_off(pc),a2
	bra	do_dspaft
@@:
	bsr	num_to_str
	lea	suji+7(pc),a2
do_dspaft:
	move.l	base_tadr(pc),a1
	lea	76+$80*1*8(a1),a1
	move.w	palet_tbl(pc),d1
	bsr	cgwr
disp_vib:				*ビブラート振幅の表示
	moveq.l	#0,d0
	tst.b	p_pmod_sw(a5)
	beq	@f
	btst.b	#b_pmod_first,p_pmod_flg(a5)	*!3/26
	beq	@f				*!3/26
	btst.b	#b_disp_mod,disp_mode-zsv_work(a6)
	bne	pmdrltm
	moveq.l	#0,d1			*振幅表示
	move.b	p_pmod_n(a5),d1
	bmi	@f
	move.w	p_pmod_dpt_now(a5),d0
	btst.b	d1,p_pmod_omt(a5)	*省略の場合は前回のものを継続
	beq	@f
	add.w	d1,d1
	move.w	p_pmod_pitch(a5),d0
	ext.l	d0
	btst.b	#0,p_pmod_mode(a5)
	bne	1f
					*(64range→683range)
	asl.l	#5,d0			*32倍
	divs	#3,d0			*/3	(pmd*8192)/(64*12)
	ext.l	d0
1:
	add.l	d0,d5
	move.w	p_pmod_dpt_tbl(a5,d1.w),d0
	ext.l	d0
	bra	@f
pmdrltm:				*リアルタイム表示ケース
	move.w	p_pmod_pitch(a5),d0
	ext.l	d0
	btst.b	#0,p_pmod_mode(a5)
	bne	1f
					*(64range→683range)
	asl.l	#5,d0			*32倍
	divs	#3,d0			*/3	(pmd*8192)/(64*12)
	ext.l	d0
1:
	add.l	d0,d5
@@:
	tas.b	(a4)+
	addq.w	#1,a4
	beq	@f
	cmp.w	(a4),d0
	bne	@f
	addq.w	#2,a4
	bra	disp_pmdwf
@@:
	move.w	d0,(a4)+
	bsr	num_to_str
	move.l	base_tadr(pc),a1
	add.w	#$80*2*8+60,a1
	lea	suji+4(pc),a2
	move.b	d0,(a2)			*1文字目
	move.w	palet_tbl(pc),d1
	bsr	cgwr
disp_pmdwf:				*波形タイプ表示
	moveq.l	#0,d0
	move.b	p_pmod_sw(a5),d2
	beq	@f
	btst.b	#b_pmod_first,p_pmod_flg(a5)	*!3/26
	beq	@f				*!3/26
	move.w	p_pmod_wf(a5),d0
@@:
	tas.b	(a4)+
	addq.w	#1,a4
	beq	@f
	cmp.w	(a4),d0
	bne	@f
	addq.w	#2,a4
	bra	disp_pmdvrnt
@@:
	move.w	d0,(a4)+
	bpl	pmdprstwf		*プリセット波形
	andi.w	#$7fff,d0
	addq.l	#8,d0			*USER波形は8番から始まるから
	bsr	num_to_str
	lea	suji+5(pc),a2
	bra	@f
pmdprstwf:
	lea	DUMMY_wf(pc),a2		*スイッチオフの時の波形名
	tst.b	d2
	beq	@f
	lea	WAVE_tbl(pc),a2
	lsl.w	#3,d0
	add.w	d0,a2
@@:
	move.l	base_tadr(pc),a1
	add.w	#$80*2*8+72,a1
	move.w	palet_tbl(pc),d1
	bsr	cgwr
disp_pmdvrnt:				*増減値表示
	moveq.l	#0,d0
	tst.b	p_pmod_sw(a5)
	beq	@f
	btst.b	#b_pmod_first,p_pmod_flg(a5)	*!3/26
	beq	@f				*!3/26
	btst.b	#b_pmod_dpn,p_pmod_flg(a5)
	beq	@f
	move.w	p_pmod_dpndpt(a5),d0
	ext.l	d0
@@:
	tas.b	(a4)+
	addq.w	#1,a4
	beq	@f
	cmp.w	(a4),d0
	bne	@f
	addq.w	#2,a4
	bra	disp_pitchbar
@@:
	move.w	d0,(a4)+
	bsr	num_to_str
	lea	suji+4(pc),a2
	move.b	d0,(a2)
	move.l	base_tadr(pc),a1
	add.w	#$80*2*8+86,a1
	move.w	palet_tbl(pc),d1
	bsr	cgwr
disp_pitchbar:
	cmpi.l	#-16384,d5	*範囲縮小
	bge	@f
	move.l	#-16384,d5
	bra	1f
@@:
	cmpi.l	#16383,d5
	ble	1f
	move.l	#16383,d5
1:
	tas.b	(a4)+
	addq.w	#1,a4
	beq	@f
	cmp.l	(a4),d5
	bne	@f
	addq.w	#4,a4
	bra	disp_arcc
@@:
	move.l	(a4),d1
	move.l	d5,(a4)+
	move.l	base_tadr(pc),a1
	lea	48+$80*3*8+$80*7(a1),a3	*x=48,y=3
	bsr	draw_bender		*<a3.l=addr,d1=previous,d0=now
disp_arcc:				*ARCC振幅表示
	moveq.l	#0,d0
	move.b	p_vol(a5),d0
	move.w	d0,volume_val-zsv_work(a6)	*FM/ADPCM ARCC VOLUME考慮用
	move.b	p_pan(a5),d0
	bpl	@f
	moveq.l	#-1,d0
@@:
	move.w	d0,panpot_val-zsv_work(a6)	*ADPCM ARCC PAN考慮用
	moveq.l	#arcc_max-1,d5
	move.l	base_tadr(pc),a1
	add.w	#$80*2*8+6,a1
	lea	p_arcc_param(a5),a0
disparcc_lp:
	pea	$80*8(a1)
	moveq.l	#0,d0
	tst.b	p_arcc_sw(a0)
	beq	1f
	btst.b	#b_arcc_first,p_arcc_flg(a0)	*!3/26
	beq	1f				*!3/26
	btst.b	#b_disp_mod,disp_mode-zsv_work(a6)
	bne	arccrltm		リアルタイム
	moveq.l	#0,d1			*振幅表示
	move.b	p_arcc_n(a0),d1
	bmi	1f
	move.b	p_arcc_level(a0),d2
	move.b	p_arcc_dpt_now(a0),d0
	btst.b	d1,p_arcc_omt(a0)	*省略の場合は前回のものを継続
	beq	@f
	move.b	p_arcc_dpt_tbl(a0,d1.w),d0
	bra	@f
arccrltm:				*リアルタイム表示ケース
	move.b	p_arcc_level(a0),d0
1:
	move.l	d0,d2
@@:
	tas.b	(a4)+
	beq	@f
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	disp_arccbar
@@:
	move.b	d0,(a4)+
	ext.w	d0
	ext.l	d0
	bsr	num_to_str
	lea	suji+6(pc),a2
	move.b	d0,(a2)			*1文字目
	move.w	palet_tbl(pc),d1
	bsr	cgwr
disp_arccbar:
	tas.b	(a4)+
	beq	@f
	cmp.b	(a4),d2
	bne	@f
	addq.w	#1,a4
	bra	1f
@@:
	move.b	(a4),d1
	move.b	d2,(a4)+
	lea	40+$80*15(a1),a3
	btst.l	#0,d5
	bne	@f
	sub.w	#$80*8,a3
	addq.w	#1,a3			*表示位置座標補正
@@:
	bsr	draw_arccbar		*ARCCの棒グラフ表示
1:
	ext.w	d2
	move.b	p_arcc(a0),d1
	tst.w	p_type(a5)
	bne	1f
	tst.b	d1
	bmi	disp_arccwf		*特殊なARCCの場合
	beq	2f			*p_arcc未設定の場合
	move.l	_zmusic_stat(pc),a3
	lea	_opm-zmusic_stat(a3),a3
	move.b	$20(a3,d4.w),d0		*AF
	andi.w	#7,d0
	move.b	@f(pc,d0.w),d0
	and.b	d1,d0
	bne	2f
	bra	disp_arccwf
@@:
	dc.b	%1000		*AL0
	dc.b	%1000		*AL1
	dc.b	%1000		*AL2
	dc.b	%1000		*AL3
	dc.b	%1010		*AL4
	dc.b	%1110		*AL5
	dc.b	%1110		*AL6
	dc.b	%1111		*AL7
1:
	cmpi.b	#MIDI_VOL,d1
	bne	3f
2:
	add.w	d2,volume_val-zsv_work(a6)
	bra	disp_arccwf
3:
	cmpi.b	#MIDI_PAN,d1
	bne	disp_arccwf
	add.w	d2,panpot_val-zsv_work(a6)
disp_arccwf:				*波形タイプ表示
	add.w	#10,a1
	moveq.l	#0,d0
	move.b	p_arcc_sw(a0),d2
	beq	@f
	btst.b	#b_arcc_first,p_arcc_flg(a0)	*!3/26
	beq	@f				*!3/26
	move.w	p_arcc_wf(a0),d0
@@:
	tas.b	(a4)+
	addq.w	#1,a4
	beq	@f
	cmp.w	(a4),d0
	bne	@f
	addq.w	#2,a4
	bra	disp_arccvrnt
@@:
	move.w	d0,(a4)+
	bpl	arccprstwf		*プリセット波形
	andi.w	#$7fff,d0
	addq.l	#8,d0			*USER波形は8番から始まるから
	bsr	num_to_str
	lea	suji+5(pc),a2
	bra	@f
arccprstwf:
	lea	DUMMY_wf(pc),a2		*スイッチオフの時の波形名
	tst.w	p_type(a5)
	bpl	1f
	tst.b	p_arcc_mode(a0)
	bmi	@f			*MIDIでノーマルARCCの場合は波形表示無し
1:
	tst.b	d2
	beq	@f
	lea	WAVE_tbl(pc),a2
	lsl.w	#3,d0
	add.w	d0,a2
@@:
	move.w	palet_tbl(pc),d1
	bsr	cgwr
disp_arccvrnt:				*増減値表示
	add.w	#14,a1
	moveq.l	#0,d0
	tst.b	p_arcc_sw(a0)
	beq	@f
	btst.b	#b_arcc_first,p_arcc_flg(a0)	*!3/26
	beq	@f				*!3/26
	btst.b	#b_arcc_dpn,p_arcc_flg(a0)
	beq	@f
	move.w	p_arcc_dpndpt(a0),d0
	ext.l	d0
@@:
	tas.b	(a4)+
	addq.w	#1,a4
	beq	@f
	cmp.w	(a4),d0
	bne	@f
	addq.w	#2,a4
	bra	disp_ctrl
@@:
	move.w	d0,(a4)+
	bsr	num_to_str
	lea	suji+4(pc),a2
	move.b	d0,(a2)
	move.w	palet_tbl(pc),d1
	bsr	cgwr
disp_ctrl:
	add.w	#12,a1
	moveq.l	#-1,d0
	tst.b	p_arcc_sw(a0)
	beq	@f
	btst.b	#b_arcc_first,p_arcc_flg(a0)	*!3/26
	beq	@f				*!3/26
	moveq.l	#0,d0
	move.b	p_arcc(a0),d0
@@:
	tas.b	(a4)+
	beq	@f
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	next_disp_arcc
@@:
	move.b	d0,(a4)+
	moveq.l	#paletf0,d1
	lea	Vanish_ctrl(pc),a2
	bsr	cgwr
	lea	DUMMY_ctrl(pc),a2		*スイッチオフの時のコントロール名
	tst.b	d0
	bmi	do_disp_ctrl
	tst.w	p_type(a5)
	beq	@f
	bsr	num_to_str		*MIDI/ADPCMの場合は普通にコントロール番号を表示する
	lea	suji+7(pc),a2
	move.b	#' ',3(a2)		*後ろスペース追加
	clr.b	4(a2)
	bra	do_disp_ctrl
@@:					*FM
	tst.b	d0
	bmi	disp_fm_arcc
	bne	@f
	move.l	_cf(pc),a2
	move.b	(a2,d4.w),d0
@@:
	lea	arcc_op(pc),a2		*通常のオペレータコントロール
	moveq.l	#arcc_max-1,d2
dispoplp:
	move.w	palet_tbl(pc),d1
	lsr.b	d0
	bcc	@f
	or.w	palet_tbl+4(pc),d1		*ON mark atr
@@:
	bsr	cgwr
	addq.w	#1,a1
	addq.w	#2,a2
	dbra	d2,dispoplp
	bra	next_disp_arcc
disp_fm_arcc:
	andi.w	#$7f,d0
	lea	fm_arcc_tbl(pc),a2
	move.l	d0,d1
	add.w	d0,d0
	add.w	d0,d0
	add.w	d1,d0		*5倍
	add.w	d0,a2
do_disp_ctrl:
	move.w	palet_tbl(pc),d1
	bsr	cgwr
next_disp_arcc:
	move.l	(sp)+,a1
	lea	__arcc_len(a0),a0
	dbra	d5,disparcc_lp
disp_vol:
	move.w	p_type(a5),d2
	bpl	1f
					*MIDI
	move.l	_common_buffer(pc),a3
	lea	mm0_adr-trk_buffer_top(a3),a3
	lsl.w	#2,d2
	move.l	(a3,d2.w),a3
	move.w	d4,d2
	mulu	#chwklen,d2
	moveq.l	#0,d0
	move.b	__b0+7(a3,d2.l),d0
	bra	2f
1:					*FM,ADPCM
	moveq.l	#0,d0
	move.w	volume_val(pc),d0
2:
	btst.b	#b_disp_mod,disp_mode-zsv_work(a6)
	bne	@f
	moveq.l	#0,d0
	move.b	p_vol(a5),d0
@@:
	reduce_vol	d0
vol_chk:				*(here will be patched)
	bsr.w	set_vol_ofs
	tas.b	(a4)+
	beq	@f
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	disp_pan
@@:
	move.b	d0,(a4)+
	btst.b	#b_disp_vol,disp_mode-zsv_work(a6)
	bne	@f
	bsr	num_to_str
	move.l	base_tadr(pc),a1
	add.w	#$80*8*1+26,a1
	lea	Vanish_volvelo(pc),a2
	moveq.l	#paletf0,d1
	bsr	cgwr
	lea	suji+7(pc),a2
	move.w	palet_tbl(pc),d1
	bsr	cgwr
	bra	disp_pan
@@:
	move.l	base_tadr(pc),a1
	add.w	#$80*8*1+26,a1
	lea	Vanish_volvelo(pc),a2
	moveq.l	#palet60,d1
	bsr	cgwr
	move.w	#palet90,d1
	tst.w	p_type(a5)
	bne	2f
	cmpi.w	#7,d4
	bne	@f
	move.l	_zmusic_stat(pc),a2
	tst.b	$0f+_opm(a2)
	bpl	@f
	bsr	draw_hbar_fm_noise
	bra	1f
@@:
	bsr	draw_hbar_fm		*< d0.b=0-127
	bra	1f
2:
	bsr	draw_hbar		*< d0.b=0-127
1:
disp_pan:
	move.w	p_type(a5),d2
	beq	@f
	bpl	1f
				*MIDI
	move.l	_common_buffer(pc),a3
	lea	mm0_adr-trk_buffer_top(a3),a3
	lsl.w	#2,d2
	move.l	(a3,d2.w),a3
	move.w	d4,d2
	mulu	#chwklen,d2
	moveq.l	#0,d0
	move.b	__b0+10(a3,d2.l),d0
	bra	pan_chk
@@:					*FM
	move.l	_zmusic_stat(pc),a3
	lea	_opm-zmusic_stat(a3),a3
	moveq.l	#0,d0
	move.b	$20(a3,d4.w),d0		*AF
	rol.b	#2,d0
	andi.w	#$3,d0
	move.b	@f(pc,d0.w),d0
	bra	pan_chk
@@:
	dc.b	-1,0,127,64
1:					*ADPCM
	moveq.l	#0,d0
	move.w	panpot_val(pc),d0
	bpl	@f
	moveq.l	#-1,d0
	bra	pan_chk
@@:
	reduce_vol	d0
pan_chk:				*(here will be patched)
	bsr.w	set_pan_ofs
	tas.b	(a4)+
	beq	@f
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	disp_vseq
@@:
	move.b	d0,(a4)+
	bpl	@f
	move.l	base_tadr(pc),a1	*OFF case
	lea	$80*8*2+92(a1),a1
	bsr	draw_pan_scale
	move.l	base_tadr(pc),a1	*OFF case
	add.w	#$80*8*1+93,a1
	lea	off_str(pc),a2
	move.w	palet_tbl(pc),d1
	bsr	cgwr
	bra	disp_vseq
@@:
	move.l	base_tadr(pc),a1
	lea	$80*8*2+92(a1),a3
	move.w	palet_tbl(pc),d1
	bsr	draw_pan		*トリム表示
	add.w	#$80*8*1+93,a1
	tst.b	pan_mode-zsv_work(a6)	*パンの表示モードチェック
	bne	@f
	bsr	num_to_str
	lea	suji+7(pc),a2
	bsr	cgwr
	bra	disp_vseq
@@:
	moveq.l	#0,d1
	moveq.l	#' ',d2
	cmpi.b	#64,d0
	beq	disppan		*M
	bcs	@f
	move.l	d0,d1		*R
	moveq.l	#'R',d2
	sub.b	#64,d1
	bra	disppan
@@:				*L
	move.l	d0,d1
	bne	@f
	moveq.l	#1,d1		*L64→L63
@@:
	moveq.l	#'L',d2
	sub.b	#64,d1
	neg.b	d1
disppan:
	move.l	d1,d0
	bsr	num_to_str
	lea	suji+7(pc),a2
	move.b	d2,(a2)
	move.w	palet_tbl(pc),d1
	bsr	cgwr
disp_vseq:
	lea	p_vseq_param(a5),a0
	moveq.l	#0,d0
	tst.b	p_arcc_sw(a0)
	beq	@f
	btst.b	#b_arcc_first,p_arcc_flg(a0)	*!3/26
	beq	@f				*!3/26
	btst.b	#b_disp_mod,disp_mode-zsv_work(a6)
	bne	vseqrltm
	moveq.l	#0,d1			*振幅表示
	move.b	p_arcc_n(a0),d1
	bmi	@f
	move.b	p_arcc_dpt_tbl(a0,d1.w),d0
	bra	@f
vseqrltm:				*リアルタイム表示ケース
	move.b	p_arcc_level(a0),d0
@@:
	tas.b	(a4)+
	beq	@f
	cmp.b	(a4),d0
	bne	@f
	addq.w	#1,a4
	bra	disp_vseqwf
@@:
	move.b	d0,(a4)+
	ext.w	d0
	ext.l	d0
	bsr	num_to_str
	lea	suji+6(pc),a2
	move.b	d0,(a2)			*1文字目
	move.l	base_tadr(pc),a1
	add.w	#62+$80*3*8,a1
	move.w	palet_tbl(pc),d1
	bsr	cgwr
disp_vseqwf:				*波形タイプ表示
	moveq.l	#0,d0
	move.b	p_arcc_sw(a0),d2
	beq	@f
	btst.b	#b_arcc_first,p_arcc_flg(a0)	*!3/26
	beq	@f				*!3/26
	move.w	p_arcc_wf(a0),d0
@@:
	tas.b	(a4)+
	addq.w	#1,a4
	beq	@f
	cmp.w	(a4),d0
	bne	@f
	addq.w	#2,a4
	bra	disp_vseqvrnt
@@:
	move.w	d0,(a4)+
	bpl	vseqprstwf		*プリセット波形
	andi.w	#$7fff,d0
	addq.l	#8,d0			*USER波形は8番から始まるから
	bsr	num_to_str
	lea	suji+5(pc),a2
	bra	@f
vseqprstwf:
	lea	DUMMY_wf(pc),a2		*スイッチオフの時の波形名
	tst.b	d2
	beq	@f
	lea	WAVE_tbl(pc),a2
	lsl.w	#3,d0
	add.w	d0,a2
@@:
	move.w	palet_tbl(pc),d1
	move.l	base_tadr(pc),a1
	add.w	#72+$80*3*8,a1
	bsr	cgwr
disp_vseqvrnt:				*増減値表示
	moveq.l	#0,d0
	tst.b	p_arcc_sw(a0)
	beq	@f
	btst.b	#b_arcc_first,p_arcc_flg(a0)	*!3/26
	beq	@f				*!3/26
	btst.b	#b_arcc_dpn,p_arcc_flg(a0)
	beq	@f
	move.w	p_arcc_dpndpt(a0),d0
	ext.l	d0
@@:
	tas.b	(a4)+
	addq.w	#1,a4
	beq	@f
	cmp.w	(a4),d0
	bne	@f
	addq.w	#2,a4
	bra	disp_kbd
@@:
	move.w	d0,(a4)+
	bsr	num_to_str
	lea	suji+4(pc),a2
	move.b	d0,(a2)
	move.w	palet_tbl(pc),d1
	move.l	base_tadr(pc),a1
	add.w	#86+$80*3*8,a1
	bsr	cgwr
disp_kbd:				*鍵盤表示
	move.l	base_tadr(pc),a1
	add.w	#$80*8*4,a1
	add.l	plane(pc),a1		*書き込み座標決定
	lea	p_note(a5),a2

	movem.l	a2/a4,-(sp)
	move.l	a2,d3
erase_nt_lp1:
	move.w	(a4)+,d0		*d0.hb=marker,d0.lb=note num.
	bpl	exit_ersntm
	ext.w	d0
	moveq.l	#max_note_on-1,d2
	move.l	d3,a2
erase_nt_lp2:
	tst.b	k_velo(a2)
	bmi	@f
	cmp.b	(a2),d0			*同じか
	beq	erase_nt_lp1
@@:
	addq.w	#k_note_len,a2
	dbra	d2,erase_nt_lp2
	bsr	erase_key
	move.l	a4,a0
@@:
	move.w	(a0)+,-4(a0)
	bmi	@b
	subq.w	#2,a4
	bra	erase_nt_lp1
exit_ersntm:
	movem.l	(sp)+,a2/a4
	moveq.l	#max_note_on-1,d2
	move.l	a4,d3
draw_nt_lp1:
	moveq.l	#0,d0
	move.b	(a2),d0
	bmi	next_drwntm		*つぎへ
	move.l	d3,a4
@@:					*同じものが描かれていないかチェック
	move.w	(a4)+,d1
	bpl	@f
	cmp.b	d0,d1
	beq	next_drwntm		*同じものが描かれています
	bra	@b
@@:
	clr.w	(a4)			*endcode
	move.b	d0,-(a4)
	tas	-(a4)
	bsr	draw_key
next_drwntm:
	addq.w	#k_note_len,a2
	dbra	d2,draw_nt_lp1
next_dsptrkprms:
	add.l	#$80*8*6,base_tadr-zsv_work(a6)
	addq.w	#1,d7
	move.l	(sp)+,a4
	dbra	d6,dstp_lp00

	bclr.b	#7,f_wait-zsv_work(a6)
	beq	k_chk

*	move.l	adr(pc),a0			*!debug
*	move.l	x_count-zsv_work(a6),(a0)+	*!debug
*	move.l	a0,adr-zsv_work(a6)		*!debug
*	subq.l	#1,adr_cnt-zsv_work(a6)		*!debug
*	beq	go_calc_debug			*!debug
*	bsr	disp_percentage
*	clr.l	x_count-zsv_work(a6)

	move.l	flash_palet(pc),d0
	swap	d0
	move.l	d0,flash_palet-zsv_work(a6)
	move.w	d0,$e8221e
k_chk:				*キーチェック
@@:
	bitsns	$6
	btst.l	#5,d0		*[SPC]が押されたか
	bne	@b

	btst.l	#1,d0		*[,]
	beq	@f
	tas.b	mod_k-zsv_work(a6)
	bne	__m
	bchg.b	#b_disp_mod,disp_mode-zsv_work(a6)
	bra	__m
@@:
	clr.b	mod_k-zsv_work(a6)
__m:
	btst.l	#6,d0		*[HOME]
	beq	@f
	tas.b	home_k-zsv_work(a6)
	bne	__mskrst
	suba.l	a1,a1
	moveq.l	#1,d1
	Z_MUSIC	#ZM_MASK_TRACKS
	bra	main_lp
@@:
	clr.b	home_k-zsv_work(a6)
__mskrst:
	tst.b	d0		*[DEL]
	bpl	@f
	tas.b	del_k-zsv_work(a6)
	bne	__bank
	suba.l	a1,a1
	moveq.l	#0,d1
	Z_MUSIC	#ZM_MASK_TRACKS
	bra	main_lp
@@:
	clr.b	del_k-zsv_work(a6)
__bank:				*[B]
	bitsns	$5
	btst.l	#6,d0
	beq	@f
	tas.b	bank_k-zsv_work(a6)
	bne	__volvelo
	move.b	bank_mode(pc),d0
	addq.b	#1,d0			*mode=0-2
	cmpi.b	#2,d0
	bls	1f
	moveq.l	#0,d0
1:
	move.b	d0,bank_mode-zsv_work(a6)
	lea	track_data(pc),a4
	moveq.l	#disp_max-1,d2
bnklp:
	move.w	bank_ofs(pc),d0
	clr.b	(a4,d0.w)	*チェックビットクリア(bank)
	move.w	timbre_ofs(pc),d0
	clr.b	(a4,d0.w)	*チェックビットクリア(timbre)
	lea	dtsz(a4),a4	*track_dataの構造を変えたら変更する
	dbra	d2,bnklp
	bra	main_lp
@@:
	clr.b	bank_k-zsv_work(a6)
__volvelo:
	btst.l	#5,d0		*[V]
	beq	@f
	tas.b	vol_k-zsv_work(a6)
	bne	1f
	bchg.b	#b_disp_vol,disp_mode-zsv_work(a6)
	lea	track_data(pc),a4
	moveq.l	#disp_max-1,d2
vlklp:
	move.w	vol_ofs(pc),d0
	clr.b	(a4,d0.w)	*チェックビットクリア(vol)
	move.w	velo_ofs(pc),d0
	clr.b	(a4,d0.w)	*チェックビットクリア(velo)
	lea	dtsz(a4),a4	*track_dataの構造を変えたら変更する
	dbra	d2,vlklp
	bra	main_lp
@@:
	clr.b	vol_k-zsv_work(a6)
1:
__pan:
	bitsns	$3
	btst.l	#2,d0		*[P]
	beq	@f
	tas.b	pan_k-zsv_work(a6)
	bne	1f
	eori.b	#1,pan_mode-zsv_work(a6)
	lea	track_data(pc),a4
	moveq.l	#disp_max-1,d2
pnklp:
	move.w	pan_ofs(pc),d0
	clr.b	(a4,d0.w)	*チェックビットクリア(pan)
	lea	dtsz(a4),a4	*track_dataの構造を変えたら変更する
	dbra	d2,pnklp
	bra	main_lp
@@:
	clr.b	pan_k-zsv_work(a6)
1:					*スクロール
	bitsns	$0e
	btst.l	#3,d0			*[OPT.2]がONなら無視
	bne	__arrow_u
	bitsns	$7
	btst.l	#3,d0			*[←]
	beq	1f
	tst.w	scr_x-zsv_work(a6)
	beq	@f
	subq.w	#8,scr_x-zsv_work(a6)
	bsr	do_scroll
	bra	main_lp
@@:
	clr.b	opmmap_flg-zsv_work(a6)
	bra	main_lp
1:
	btst.l	#5,d0			*[→]
	beq	1f
	cmpi.w	#256,scr_x-zsv_work(a6)
	beq	1f
	addq.w	#8,scr_x-zsv_work(a6)
	bsr	do_scroll
	tas.b	opmmap_flg-zsv_work(a6)
	bmi	main_lp
	bsr	draw_opmmap_ttl
	bra	main_lp
1:
__arrow_u:				*カーソル
	tst.w	scr_x-zsv_work(a6)
	bne	__mask
	bitsns	$0e
	btst.l	#3,d0			*[OPT.2]がONなら無視
	bne	__mask
	bitsns	$7
	btst.l	#4,d0			*[↑]
	beq	1f
	tst.w	disp_start-zsv_work(a6)
	beq	__roll_u
	tas	arwu_k-zsv_work(a6)
	beq	@f
	btst.b	#0,arwu_k-zsv_work(a6)
	bne	@f
	cmpi.b	#KRPT,arwu_krcnt-zsv_work(a6)
	bcs	2f
	bset.b	#0,arwu_k-zsv_work(a6)
@@:
	subq.w	#1,disp_start-zsv_work(a6)
	bsr	init_track_data_u
	move.w	#$00_ff,arwu_krcnt-zsv_work(a6)	*st.b	arwu_krwork-zsv_work(a6)
	bsr	clr_track_area_u
	bra	main_lp
2:
	bsr	arwu_krc_ope
	bra	arrow_d
1:
	move.l	#$ff,arwu_k-zsv_work(a6)		*arwu_krcnt=0,arwu_krwork=$ff
arrow_d:
	bitsns	$7
	btst.l	#6,d0			*[↓]
	beq	1f
	cmp.w	#tr_max-10,disp_start-zsv_work(a6)
	beq	__roll_u
	tas.b	arwd_k-zsv_work(a6)
	beq	@f
	btst.b	#0,arwd_k-zsv_work(a6)
	bne	@f
	cmpi.b	#KRPT,arwd_krcnt-zsv_work(a6)
	bcs	2f
	bset.b	#0,arwd_k-zsv_work(a6)
@@:
	addq.w	#1,disp_start-zsv_work(a6)
	bsr	init_track_data_d
	move.w	#$00_ff,arwd_krcnt-zsv_work(a6)	*st.b	arwd_krwork-zsv_work(a6)
	bsr	clr_track_area_d
	bra	main_lp
2:
	bsr	arwd_krc_ope
	bra	__roll_u
1:
	move.l	#$ff,arwd_k-zsv_work(a6)	*arwd_krcnt=0,arwd_krwork=$ff
__roll_u:				*ROLL UP
	bitsns	$7
	btst.l	#1,d0			*[ROLL.UP]
	beq	1f
	tst.w	disp_start-zsv_work(a6)
	beq	__mask
	tas.b	rlu_k-zsv_work(a6)
	beq	@f
	btst.b	#0,rlu_k-zsv_work(a6)
	bne	@f
	cmpi.b	#KRPT,rlu_krcnt-zsv_work(a6)
	bcs	2f
	bset.b	#0,rlu_k-zsv_work(a6)
@@:
	cmp.w	#10,disp_start-zsv_work(a6)
	bcc	@f
	move.w	#10,disp_start-zsv_work(a6)
@@:
	sub.w	#10,disp_start-zsv_work(a6)
	bsr	init_track_data
	move.w	#$00_ff,rlu_krcnt-zsv_work(a6)	*st.b	rlu_krwork-zsv_work(a6)
	bra	main_lp
2:
	bsr	rlu_krc_ope
	bra	__roll_d
1:
	move.l	#$ff,rlu_k-zsv_work(a6)		*rlu_krcnt=0,rlu_krwork=$ff
__roll_d:
	bitsns	$7
	btst.l	#0,d0			*[ROLL.DOWN]
	beq	1f
	cmp.w	#tr_max-10,disp_start-zsv_work(a6)
	beq	__mask
	tas.b	rld_k-zsv_work(a6)
	beq	@f
	btst.b	#0,rld_k-zsv_work(a6)
	bne	@f
	cmpi.b	#KRPT,rld_krcnt-zsv_work(a6)
	bcs	2f
	bset.b	#0,rld_k-zsv_work(a6)
@@:
	cmp.w	#tr_max-20,disp_start-zsv_work(a6)
	bcs	@f
	move.w	#tr_max-20,disp_start-zsv_work(a6)
@@:
	add.w	#10,disp_start-zsv_work(a6)
	bsr	init_track_data
	move.w	#$00_ff,rld_krcnt-zsv_work(a6)	*st.b	rld_krwork-zsv_work(a6)
	bra	main_lp
2:
	bsr	rld_krc_ope
	bra	__mask
1:
	move.l	#$ff,rld_k-zsv_work(a6)		*rld_krcnt=0,rld_krwork=$ff
__mask:					*[F1]～[F5]
	move.w	disp_start(pc),d3
	moveq.l	#3,d2
1:
	bitsns	$c
	btst.l	d2,d0
	beq	@f
	bset.b	d2,mask_k-zsv_work(a6)
	bne	2f
	lea	trk_seq_tbl+6(pc),a1
	move.l	#$0001_ffff,-(a1)
	move.w	d3,-(a1)
	Z_MUSIC	#ZM_MASK_TRACKS
	bra	2f
@@:
	bclr.b	d2,mask_k-zsv_work(a6)
2:
	addq.w	#1,d3
	addq.w	#1,d2
	cmpi.b	#7,d2
	bls	1b
__mask2:				*[F6]～[F10]
	moveq.l	#0,d2
1:
	bitsns	$d
	btst.l	d2,d0
	beq	@f
	bset.b	d2,mask2_k-zsv_work(a6)
	bne	2f
	lea	trk_seq_tbl+6(pc),a1
	move.l	#$0001_ffff,-(a1)
	move.w	d3,-(a1)
	Z_MUSIC	#ZM_MASK_TRACKS
	bra	2f
@@:
	bclr.b	d2,mask2_k-zsv_work(a6)
2:
	addq.w	#1,d3
	addq.w	#1,d2
	cmpi.b	#4,d2
	bls	1b
__fm_mask:				*[F]
	bitsns	$4
	btst.l	#1,d0
	beq	1f
	tas	fmmsk_k-zsv_work(a6)
	bne	__ad_mask
	move.l	_seq_wk_tbl(pc),a2	*a2=track work addr
	movea.l	_play_trk_tbl(pc),a4
@@:
	move.w	(a4)+,d0		*演奏されているのかチェック
	cmpi.w	#-1,d0
	beq	__ad_mask
	move.w	d0,d1
	mulu	_wk_size(pc),d0
	tst.w	p_type(a2,d0.l)
	bne	@b
	lea	trk_seq_tbl+6(pc),a1
	move.l	#$0001_ffff,-(a1)
	move.w	d1,-(a1)
	Z_MUSIC	#ZM_MASK_TRACKS
	bra	@b
1:
	clr.b	fmmsk_k-zsv_work(a6)
__ad_mask:				*[9]
	bitsns	$8
	btst.l	#5,d0
	beq	1f
	tas	admsk_k-zsv_work(a6)
	bne	__md_mask
	move.l	_seq_wk_tbl(pc),a2	*a2=track work addr
	movea.l	_play_trk_tbl(pc),a4
@@:
	move.w	(a4)+,d0		*演奏されているのかチェック
	cmpi.w	#-1,d0
	beq	__md_mask
	move.w	d0,d1
	mulu	_wk_size(pc),d0
	cmpi.w	#1,p_type(a2,d0.l)
	bne	@b
	lea	trk_seq_tbl+6(pc),a1
	move.l	#$0001_ffff,-(a1)
	move.w	d1,-(a1)
	Z_MUSIC	#ZM_MASK_TRACKS
	bra	@b
1:
	clr.b	admsk_k-zsv_work(a6)
__md_mask:
	bitsns	$0e
	btst.l	#3,d0			*[OPT.2]がONなら無視
	bne	__k_ctrl
	bitsns	$8
	move.b	d0,d5
	andi.w	#%0100_0000,d5
	andi.w	#%0000_0111,d0
	lsr.w	#3,d5
	or.b	d0,d5
	lea	mdmsk_k(pc),a3
	moveq.l	#4-1,d2
	move.w	#$8003,d3
__mdmsk_lp:				*[/][*][-][+]
	btst.l	d2,d5
	beq	1f
	tas	(a3)+
	bne	next_mdmsk
	move.l	_seq_wk_tbl(pc),a2	*a2=track work addr
	movea.l	_play_trk_tbl(pc),a4
@@:
	move.w	(a4)+,d0		*演奏されているのかチェック
	cmpi.w	#-1,d0
	beq	next_mdmsk
	move.w	d0,d1
	mulu	_wk_size(pc),d0
	cmp.w	p_type(a2,d0.l),d3
	bne	@b
	lea	trk_seq_tbl+6(pc),a1
	move.l	#$0001_ffff,-(a1)
	move.w	d1,-(a1)
	Z_MUSIC	#ZM_MASK_TRACKS
	bra	@b
1:
	clr.b	(a3)+
next_mdmsk:
	subq.w	#1,d3
	dbra	d2,__mdmsk_lp
********************************演奏制御系キーコントロール
__k_ctrl:
	move.l	_zmusic_stat(pc),a0
	tst.b	external_applications(a0)
	bmi	__esc		*ZP -Dが組み込まれていた場合

	lea	key_tbl_db(pc),a0
	lea	$800.w,a1

	bsr	key_inp
	beq	@f
	bsr	_PLAY		*演奏開始(xf4)
	bra	__esc
@@:
	clr.b	play_k-zsv_work(a6)

	bsr	key_inp
	beq	@f
	bsr	_PAUSE		*一時停止(opt1)
	bra	__esc
@@:
	clr.b	stop_k-zsv_work(a6)

	bsr	key_inp
	beq	@f
	bsr	_CONT		*一時停止解除(opt2)
	bra	__esc
@@:
	clr.b	cont_k-zsv_work(a6)

	bsr	key_inp
	beq	@f
	bsr	_FF		*早送り(xf5)
	bra	__esc
@@:
	bsr	key_inp
	beq	@f
	bsr	_SLOW		*低速演奏
	bra	__esc
@@:
	bsr	key_inp		*FADEOUT(xf1)
	beq	@f
	bsr	_FADEOUT
	bra	__esc
@@:
	clr.b	fadeout_k-zsv_work(a6)

	bsr	key_inp		*FADE IN(xf2)
	beq	@f
	bsr	_FADE_IN
	bra	__esc
@@:
	clr.b	fadein_k-zsv_work(a6)
chk_FF:
	tst.b	_FF_flg-zsv_work(a6)	*早送り終了か?
	beq	chk_SLOW
	lea	trk_seq_tbl(pc),a1
	move.l	#$ffff_07_00+fader_dflt_spd,(a1)	*dev,omt,spd.h
	move.l	#$00_80_80_00,4(a1)			*spd.l,start,end,dummy
	Z_MUSIC	#ZM_MASTER_FADER
	clr.b	_FF_flg-zsv_work(a6)
	bra	@f
chk_SLOW:
	tst.b	_SLOW_flg-zsv_work(a6)	*低速演奏か?
	beq	__esc
@@:
	moveq.l	#0,d1
	Z_MUSIC	#ZM_CONTROL_TEMPO	*通常テンポに戻す
	clr.b	_SLOW_flg-zsv_work(a6)
__esc:
	bitsns	$7
	btst.l	#2,d0		*[UNDO]
	bne	all_end
	bitsns	$0
	btst.l	#1,d0		*[ESC]が押されたかどうか
	bne	all_end
	bra	main_lp

krc_ope	macro	XX,YY
	* x d0
	move.b	$e88001,d0
*	andi.b	#$80,d0			*h_w
	andi.b	#$10,d0			*v_w
	cmp.b	XX(pc),d0	*キーリピート処理
	beq	@f
	move.b	d0,XX-zsv_work(a6)
	addq.b	#1,YY-zsv_work(a6)
@@:
	rts
	endm

arwu_krc_ope:	krc_ope	arwu_krwork,arwu_krcnt
arwd_krc_ope:	krc_ope	arwd_krwork,arwd_krcnt
rlu_krc_ope:	krc_ope	rlu_krwork,rlu_krcnt
rld_krc_ope:	krc_ope	rld_krwork,rld_krcnt

key_inp:			*キー入力
	* > nz key on
	* > ze key off
	move.b	(a0)+,d0	*key group
	move.b	d0,d1
	andi.w	#$0f,d0
	lsr.b	#4,d1		*key status bit
	btst.b	d1,(a1,d0.w)
	beq	@f
	move.b	(a0)+,d0	*key group
	move.b	d0,d1
	andi.w	#$0f,d0
	lsr.b	#4,d1		*key status bit
	btst.b	d1,(a1,d0.w)
	rts
@@:
	addq.w	#1,a0
	moveq.l	#0,d0
	rts

_PAUSE:				*一時停止
	tas.b	stop_k-zsv_work(a6)
	bmi	@f
	tas.b	stop_mode-zsv_work(a6)
	bmi	do_cont
	suba.l	a1,a1
	Z_MUSIC	#ZM_STOP
@@:
	rts

_CONT:				*一時停止解除
	tas.b	cont_k-zsv_work(a6)
	bmi	@f
*	tst.b	stop_mode-zsv_work(a6)
*	beq	@f		*演奏は停止していない
do_cont:
	suba.l	a1,a1
	Z_MUSIC	#ZM_CONT
	clr.b	stop_mode-zsv_work(a6)
@@:
	rts

_PLAY:				*演奏開始
reglist	reg	d0-d1/a1-a2
	tas.b	play_k-zsv_work(a6)
	bmi	1f
	movem.l	reglist,-(sp)
	Z_MUSIC	#ZM_PLAY2
	clr.b	stop_mode-zsv_work(a6)
	lea	global_data(pc),a1
	lea	mstrfdr_ofs(pc),a2
	moveq.l	#if_max+2-1,d1
@@:
	move.w	(a2)+,d0
	clr.b	(a1,d0.w)				*チェックビットクリア(master_fader)
	dbra	d1,@b
	bsr	draw_mixbar_scale
	movem.l	(sp)+,reglist
1:
	rts

_FADE_IN:
	tas.b	fadein_k-zsv_work(a6)
	bmi	@f
	lea	trk_seq_tbl(pc),a1
	move.l	#$ffff_07_00,d0			*dev,omt,(spd.h)
	move.b	fadein_speed(pc),d0		*spd.h
	move.l	d0,(a1)				*dev,omt,spd.h
	move.l	#$00_00_80_00,4(a1)		*(spd.l),start,end,dummy
	move.b	fadein_speed+1(pc),4(a1)	*spd.l
	Z_MUSIC	#ZM_MASTER_FADER
@@:
	rts

_FADEOUT:
	tas.b	fadeout_k-zsv_work(a6)
	bmi	@f
	lea	trk_seq_tbl(pc),a1
	move.l	#$ffff_07_00,d0			*dev,omt,spd.h
	move.b	fadeout_speed(pc),d0		*(spd.h)
	move.l	d0,(a1)				*dev,omt,spd.h
	move.l	#$00_80_00_00,4(a1)		*(spd.l),start,end,dummy
	move.b	fadeout_speed+1(pc),4(a1)	*spd.l
	Z_MUSIC	#ZM_MASTER_FADER
@@:
	rts

_FF:				*早送り
	tst.b	_SLOW_flg-zsv_work(a6)			*低速演奏か?
	bne	@f
	tas.b	_FF_flg-zsv_work(a6)
	bne	@f
	lea	trk_seq_tbl(pc),a1
	move.l	#$ffff_07_00+fader_dflt_spd,(a1)	*dev,omt,spd.h
	move.l	#$00_40_40_00,4(a1)			*spd.l,start,end,dummy
	Z_MUSIC	#ZM_MASTER_FADER
	moveq.l	#-1,d1
	Z_MUSIC	#ZM_CONTROL_TEMPO
	move.l	FF_timer(pc),d1				*M:$c0,B:$f8,A:$399
	Z_MUSIC	#ZM_SET_TIMER_VALUE
@@:
	rts

_SLOW:					*低速演奏
	tst.b	_FF_flg-zsv_work(a6)	*早送り終了か?
	bne	@f
	tas.b	_SLOW_flg-zsv_work(a6)
	bne	@f
	moveq.l	#-1,d1
	Z_MUSIC	#ZM_CONTROL_TEMPO
	move.l	SL_timer(pc),d1
	Z_MUSIC	#ZM_SET_TIMER_VALUE
@@:
	rts

ch_odr_no:			*チャンネルフェーダーテーブル用オーダー値取りだし
	* < d0.hw=type,d0.lw=ch
	* > d3.w=チャンネルフェーダーテーブル用オーダー値
	move.w	p_type(a5),d0
	tst.w	d0
	beq	con_fm
	bmi	con_midi
				*ADPCM
	moveq.l	#16,d3
	add.w	d4,d3
	rts
con_fm:				*FM
	move.w	d4,d3
	rts
con_midi:			*MIDI
	moveq.l	#32,d3
	lsl.w	#4,d0		*16倍
	add.w	d0,d3
	add.w	d4,d3
	rts

do_scroll:
	movem.l	d0-d3,-(sp)
	moveq.l	#8,d1
	move.w	scr_x-zsv_work(a6),d2
	move.w	scr_y-zsv_work(a6),d3
	IOCS	_SCROLL
	movem.l	(sp)+,d0-d3
	rts

*clr_track_area:				*トラック情報エリアの全消去
*	movem.l	d0-d1/a0,-(sp)
*	move.w	$e8002a,-(sp)
*	move.w	#$01_00+paletf0,$e8002a		*同時アクセス
*
*	lea	$e00000+$80*16,a0
*	move.w	#(trn)*16-1,d0
*1:
*	moveq.l	#24-1,d1
*2:
*	clr.l	(a0)+
*	dbra	d1,2b
*	lea	32(a0),a0
*	dbra	d0,1b
*	move.w	(sp)+,$e8002a			*同時アクセス解除
*	movem.l	(sp)+,d0-d1/a0
*	rts

clr_track_area_u:				*トラック情報エリアの消去
	* < d0.l=表示トラック番号(0-9)
	movem.l	d0-d1/a1,-(sp)
@@:
	btst.b	#4,$e88001		*非表示期間を狙う
	bne	@b
	move.w	$e8002a,-(sp)
	move.w	#$00_0f,$e8002a
	move.w	#$77_83,d0
	moveq	#6*9*2-1,d1
@@:
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	bsr	h_wait
	move.w	d0,$e8002c
	bset.b	#3,$e80481
	move.w	(sp)+,sr
	sub.w	#$01_01,d0
	dbra	d1,@b

	move.w	sr,-(sp)
	ori.w	#$0700,sr
	bsr	h_wait
	bclr.b	#3,$e80481
	move.w	(sp)+,sr

	move.w	#$01_00+paletf0,$e8002a
	draw	0,6
	move.w	#8*6-1,d1
ctalp00_u:
	moveq.l	#96/4-1,d0
@@:
	clr.l	(a1)+
	dbra	d0,@b
	add.w	#$80-96,a1
	dbra	d1,ctalp00_u

	move.w	(sp)+,$e8002a
	movem.l	(sp)+,d0-d1/a1
	rts

clr_track_area_d:				*トラック情報エリアの消去
	* < d0.l=表示トラック番号(0-9)
@@:
	btst.b	#4,$e88001		*非表示期間を狙う
	bne	@b
	movem.l	d0-d1/a1,-(sp)
	move.w	$e8002a,-(sp)
	move.w	#$00_0f,$e8002a
	move.w	#$18_0c,d0
	moveq	#6*9*2-1,d1
@@:
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	bsr	h_wait
	move.w	d0,$e8002c
	bset.b	#3,$e80481
	move.w	(sp)+,sr
	add.w	#$01_01,d0
	dbra	d1,@b

	move.w	sr,-(sp)
	ori.w	#$0700,sr
	bsr	h_wait
	bclr.b	#3,$e80481
	move.w	(sp)+,sr

	move.w	#$01_00+paletf0,$e8002a
	draw	0,60
	move.w	#8*6-1,d1
ctalp00_d:
	moveq.l	#96/4-1,d0
@@:
	clr.l	(a1)+
	dbra	d0,@b
	add.w	#$80-96,a1
	dbra	d1,ctalp00_d

	move.w	(sp)+,$e8002a
	movem.l	(sp)+,d0-d1/a1
	rts

h_wait:
	tst.b	$e88001
	bpl	h_wait
@@:
	tst.b	$e88001
	bmi	@b
	rts

copy_plane1:				*ノンアクティヴ→アクティヴ
	move.w	$e8002a,-(sp)
	move.l	base_tadr(pc),a1
	moveq.l	#8*6-1,d3
y_cpylp00:
	moveq.l	#96-1,d2
y_cpylp01:				*%1010→%0011(%0010),%0001→%0100
	cmp.w	#8*5,d3			*コピー対象外エリア定義
	bls	@f
	cmp.w	#96-32,d2
	bhi	next_y_cpylp01
@@:
	cmp.w	#8*4,d3
	bhi	@f
	cmp.w	#8*2,d3
	bls	@f
	cmp.w	#1,d2
	bls	next_y_cpylp01
	cmp.w	#46,d2
	bls	@f
	cmp.w	#49,d2
	bls	next_y_cpylp01
@@:
	cmp.w	#8*2,d3
	bhi	@f
	tst.w	d2
	beq	next_y_cpylp01
	cmp.w	#47,d2
	bls	@f
	cmp.w	#49,d2
	bls	next_y_cpylp01
@@:
	clr.w	$e8002a
*	move.b	(a1),d1			*kon
	clr.b	(a1)
	add.l	#$2_0000,a1
	move.b	(a1),d0
	add.l	#$2_0000*2,a1
	clr.b	(a1)
	sub.l	#$2_0000,a1
*	move.b	d1,(a1)
	sub.l	#$2_0000*2,a1
	move.w	palet_tbl(pc),d1
	ori.w	#$01_00,d1
	move.w	d1,$e8002a
	move.b	d0,(a1)
next_y_cpylp01:
	addq.w	#1,a1
	dbra	d2,y_cpylp01
	add.w	#$80-96,a1
	dbra	d3,y_cpylp00
	move.w	(sp)+,$e8002a
	rts

copy_plane2:				*アクティヴ→ノンアクティヴ
	move.l	base_tadr(pc),a1
	lea	95+$80*5*8+$80*7(a1),a3
	moveq.l	#15,d2
@@:
	bsr	draw_release
	dbra	d2,@b
	move.w	$e8002a,-(sp)
	moveq.l	#8*6-1,d3
y_cpylp10:
	moveq.l	#96-1,d2
y_cpylp11:				*%0011(%0010)→%1010,%0100→%0001
	cmp.w	#8*5,d3			*コピー対象外エリア定義
	bls	@f
	cmp.w	#96-32,d2
	bhi	next_y_cpylp11
@@:
	cmp.w	#8*4,d3
	bhi	@f
	cmp.w	#8*2,d3
	bls	@f
	cmp.w	#1,d2
	bls	next_y_cpylp11
	cmp.w	#46,d2
	bls	@f
	cmp.w	#49,d2
	bls	next_y_cpylp11
@@:
	cmp.w	#8*2,d3
	bhi	@f
	tst.w	d2
	beq	next_y_cpylp11
	cmp.w	#47,d2
	bls	@f
	cmp.w	#49,d2
	bls	next_y_cpylp11
@@:
	clr.w	$e8002a
	clr.b	(a1)
	add.l	#$2_0000,a1
	move.b	(a1),d0
	add.l	#$2_0000,a1
*	move.b	(a1),d1			*kon
	clr.b	(a1)
	sub.l	#$2_0000*2,a1
*	move.b	d1,(a1)
	move.w	#$01_00+paleta0,$e8002a
	move.b	d0,(a1)
next_y_cpylp11:
	addq.w	#1,a1
	dbra	d2,y_cpylp11
	add.w	#$80-96,a1
	dbra	d3,y_cpylp10
	move.w	(sp)+,$e8002a
	rts

no_disp_case:				*非表示トラック
	lea	no_disp_tbl(pc),a1
	tas	(a1,d6.w)		*すでに表示したことがある
	bne	next_dsptrkprms
	move.w	#paleta0,palet_tbl-zsv_work(a6)
	pea	next_dsptrkprms(pc)

do_draw_trkprms:			*パラメータタイトル表示
	move.l	base_tadr(pc),a1	*消去
	move.w	$e8002a,-(sp)
	move.w	#$01_00+paletf0,$e8002a
	move.w	#8*6-1,d1
ddtlp:
	moveq.l	#96/4-1,d0
@@:
	clr.l	(a1)+
	dbra	d0,@b
	add.w	#$80-96,a1
	dbra	d1,ddtlp
	move.w	(sp)+,$e8002a

	move.l	base_tadr(pc),a1
	move.w	palet_tbl(pc),d1
	bsr	draw_trkprms
	move.l	d7,d0
	addq.w	#1,d0
	bsr	num_to_str
	lea	suji+5(pc),a2
	move.w	#palet50,d1		*palet_tbl(pc),d1
	bsr	cgwr
	lea	colon(pc),a2
	addq.w	#5,a1
	move.w	palet_tbl+2(pc),d1
	bsr	cgwr
	add.w	#11,a1
	lea	Status(pc),a2
	bsr	cgwr
	add.w	#$80*8-16,a1
	lea	Timbre(pc),a2
	move.w	palet_tbl(pc),d1
	bsr	cgwr
	lea	$80*1*8+46(a1),a1
	bsr	draw_mixbar_scale3
	addq.w	#1,a1
	bsr	draw_mixbar_scale3
	addq.w	#1,a1
	bsr	draw_mixbar_scale2
	lea	44(a1),a1
	bsr	draw_pan_scale
	addq.w	#2,a1
	bsr	draw_hold_scale
	addq.w	#1,a1
	bsr	draw_mixbar_scale2
	add.w	#$80*16,a1
	bra	draw_level_scale

draw_key:			*鍵盤描画
	* < d0.w=note num
	movem.l	d0-d1/a0/a3,-(sp)
	move.w	$e8002a,-(sp)
	clr.w	$e8002a			*アクセスモード設定
	lsl.w	#2,d0
	lea	kon_ptn1(pc),a0
	add.w	d0,a0
	move.w	(a0)+,d0		*offset
	lea	48(a1,d0.w),a3		*48=offset,a3.l=表示開始アドレス
	moveq.l	#10-1,d1
@@:					*鍵盤の上部分表示
	move.b	(a0),d0
	or.b	d0,(a3)+
	move.b	1(a0),d0
	or.b	d0,(a3)+
	add.w	#$80-2,a3
	dbra	d1,@b

	lea	(kon_ptn2-kon_ptn1)-2(a0),a0
	move.w	(a0)+,d0		*offset
	bmi	exit_drwky
	lea	48(a1,d0.w),a3		*48=offset,a3.l=表示開始アドレス
	add.w	#$80*10,a3
	moveq.l	#5-1,d1
@@:					*鍵盤の下部分表示
	move.b	(a0),d0
	or.b	d0,(a3)+
	move.b	1(a0),d0
	or.b	d0,(a3)+
	add.w	#$80-2,a3
	dbra	d1,@b
exit_drwky:
	move.w	(sp)+,$e8002a
	movem.l	(sp)+,d0-d1/a0/a3
	rts

erase_key:			*鍵盤消去
	* < a1.l=plane addr.
	* < d0.w=note num
	movem.l	d0-d1/a0/a3,-(sp)
	move.w	$e8002a,-(sp)
	clr.w	$e8002a			*アクセスモード設定
	lsl.w	#2,d0
	lea	kon_ptn1(pc),a0
	add.w	d0,a0
	move.w	(a0)+,d0		*offset
	lea	48(a1,d0.w),a3		*48=offset,a3.l=表示開始アドレス
	moveq.l	#10-1,d1
@@:					*鍵盤の上部分表示
	move.b	(a0),d0
	not.b	d0
	and.b	d0,(a3)+
	move.b	1(a0),d0
	not.b	d0
	and.b	d0,(a3)+
	add.w	#$80-2,a3
	dbra	d1,@b

	lea	(kon_ptn2-kon_ptn1)-2(a0),a0
	move.w	(a0)+,d0		*offset
	bmi	exit_ersky
	lea	48(a1,d0.w),a3		*48=offset,a3.l=表示開始アドレス
	add.w	#$80*10,a3
	moveq.l	#5-1,d1
@@:					*鍵盤の下部分表示
	move.b	(a0),d0
	not.b	d0
	and.b	d0,(a3)+
	move.b	1(a0),d0
	not.b	d0
	and.b	d0,(a3)+
	add.w	#$80-2,a3
	dbra	d1,@b
exit_ersky:
	move.w	(sp)+,$e8002a
	movem.l	(sp)+,d0-d1/a0/a3
	rts

all_end:			*終了
	bsr	init

	clr.w	-(sp)
	move.w	#14,-(sp)
	DOS	_CONCTRL
	addq.w	#4,a7

	clr.w	-(sp)
	DOS	_KFLUSH
	addq.w	#2,sp

	move.l	ssp(pc),a1
	IOCS	_B_SUPER
	DOS	_EXIT

init:					*画面初期化
	move.w	#$0010,d1
	IOCS	_CRTMOD

	move.b	#-$02,d1
	IOCS	_CONTRAST
	IOCS	_B_CURON
	moveq.l	#0,d1
	move.l	#$005f001e,d2
	IOCS	_B_CONSOL
	IOCS	_MS_CUROF
	moveq.l	#0,d1
	move.l	#$02ff01ff,d2
	IOCS	_MS_LIMIT
	moveq.l	#$ff,d1
	IOCS	_SKEY_MOD
	IOCS	_OS_CURON
	pea.l	init_color(pc)
	DOS	_PRINT
	addq.w	#4,a7
txt_cls:					*テキスト画面の全プレーンクリア
	move.w	$e8002a,-(sp)
	move.w	#$01_00+paletf0,$e8002a		*同時アクセス

	lea	$e00000,a0
	move.w	#(trn+1)*16-1,d0
clr_loop0:
	moveq.l	#32-1,d1
clr_loop1:
	clr.l	(a0)+
	dbra	d1,clr_loop1
*	lea	32(a0),a0
	dbra	d0,clr_loop0

	move.w	(sp)+,$e8002a			*同時アクセス解除
	rts

chk_drv:			*デバイス名のcheck
	* > eq=no error
	* > mi=error
	move.l	$8c.w,a0
	subq.w	#8,a0
	cmpi.l	#'ZmuS',(a0)+
	bne	no_zmusic_error
	cmpi.w	#'iC',(a0)+
	bne	no_zmusic_error
	move.w	(a0),zm_ver-zsv_work(a6)
	cmpi.b	#$30,(a0)+
	bcs	version_error
	rts

set_mstrfdr_ofs:
	* < d2.w=counter
reglist	reg	d2/a1/a2/a4
	movem.l	reglist,-(sp)
	lea	global_data(pc),a1
	suba.l	a1,a4
	add.w	d2,d2
	lea	mstrfdr_ofs(pc),a2
	move.w	a4,(a2,d2.w)
	tst.w	d2
	bne	@f
	move.l	#NOP_NOP,mstfdrlp-zsv_work(a6)	*ラストのみ自己書き換え
	bsr	cache_flush
@@:
	movem.l	(sp)+,reglist
	rts

set_bank_ofs:
reglist	reg	a1/a4
	movem.l	reglist,-(sp)
	move.l	#NOP_NOP,sbo_patch-zsv_work(a6)	*一回目の実行時のみ自己書き換え
	lea	track_data(pc),a1
	suba.l	a1,a4
	move.w	a4,bank_ofs-zsv_work(a6)
	bsr	cache_flush
	movem.l	(sp)+,reglist
	rts

set_timbre_ofs:
reglist	reg	a1/a4
	movem.l	reglist,-(sp)
	move.l	#NOP_NOP,disp_timbre-zsv_work(a6)	*一回目の実行時のみ自己書き換え
	lea	track_data(pc),a1
	suba.l	a1,a4
	move.w	a4,timbre_ofs-zsv_work(a6)
	bsr	cache_flush
	movem.l	(sp)+,reglist
	rts

set_pan_ofs:
reglist	reg	a1/a4
	movem.l	reglist,-(sp)
	move.l	#NOP_NOP,pan_chk-zsv_work(a6)	*一回目の実行時のみ自己書き換え
	lea	track_data(pc),a1
	suba.l	a1,a4
	move.w	a4,pan_ofs-zsv_work(a6)
	bsr	cache_flush
	movem.l	(sp)+,reglist
	rts

set_vol_ofs:
reglist	reg	a1/a4
	movem.l	reglist,-(sp)
	move.l	#NOP_NOP,vol_chk-zsv_work(a6)	*一回目の実行時のみ自己書き換え
	lea	track_data(pc),a1
	suba.l	a1,a4
	move.w	a4,vol_ofs-zsv_work(a6)
	bsr	cache_flush
	movem.l	(sp)+,reglist
	rts

set_velo_ofs:
reglist	reg	a1/a4
	movem.l	reglist,-(sp)
	move.l	#NOP_NOP,disp_velo-zsv_work(a6)	*一回目の実行時のみ自己書き換え
	lea	track_data(pc),a1
	suba.l	a1,a4
	move.w	a4,velo_ofs-zsv_work(a6)
	bsr	cache_flush
	movem.l	(sp)+,reglist
	rts

clr_track_data:				*データ内容の初期化
	* < d7.l=現在の表示トラック
	* - all
	movem.l	d0/a1,-(sp)
	move.l	d7,d0
	sub.w	disp_start(pc),d0
	mulu	#dtsz,d0
	lea	track_data(pc),a1
	lea	4(a1,d0.l),a1
	move.w	#dtsz/4-1-1,d0
@@:
	clr.l	(a1)+
	dbra	d0,@b
	movem.l	(sp)+,d0/a1
	rts

init_track_data:
	movem.l	d0/a0,-(sp)
	lea	track_data(pc),a0	*ワーク初期化
	move.w	#(data_end-track_data)/4-1,d0
@@:
	clr.l	(a0)+
	dbra	d0,@b
	bsr	init_no_disp_tbl
	movem.l	(sp)+,d0/a0
	rts

init_no_disp_tbl:
	clr.l	no_disp_tbl+0-zsv_work(a6)
	clr.l	no_disp_tbl+4-zsv_work(a6)
	clr.w	no_disp_tbl+8-zsv_work(a6)
	rts

init_track_data_u:
	movem.l	d0/a0-a1,-(sp)
	lea	track_data+dtsz*9(pc),a0
	lea	track_data+dtsz*10(pc),a1
	move.w	#(dtsz*9)/4-1,d0
@@:
	move.l	-(a0),-(a1)
	dbra	d0,@b

	move.w	#dtsz/4-1,d0
@@:
	clr.l	-(a1)
	dbra	d0,@b
	bsr	init_no_disp_tbl
	movem.l	(sp)+,d0/a0-a1
	rts

init_track_data_d:
	movem.l	d0/a0-a1,-(sp)
	lea	track_data+dtsz*1(pc),a0
	lea	track_data+dtsz*0(pc),a1
	move.w	#(dtsz*9)/4-1,d0
@@:
	move.l	(a0)+,(a1)+
	dbra	d0,@b

	move.w	#dtsz/4-1,d0
@@:
	clr.l	(a1)+
	dbra	d0,@b
	bsr	init_no_disp_tbl
	movem.l	(sp)+,d0/a0-a1
	rts

kake:			*32ビット×32ビット=32ビット
	* < d0.l X d1.l
	* > d1.l
	* - d0-d4
	movem.l	d0/d2-d4,-(sp)
	move.l	d0,d2
	move.l	d1,d3
	swap	d2
	swap	d3

	move.w	d1,d4
	mulu	d0,d1
	mulu	d3,d0
	mulu	d2,d3
	mulu	d4,d2
	exg	d0,d3

	add.l	d3,d2

	move.w	d2,d3
	swap	d3
	clr.w	d3

	clr.w	d2
	addx.w	d3,d2
	swap	d2

	add.l	d3,d1
	addx.l	d2,d0
	movem.l	(sp)+,d0/d2-d4
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

calc_gate:				*ゲートタイムの計算
	* < d1.l=step time
	* > d2.l=gate time
	* - d1
	moveq.l	#0,d2
	move.w	p_Q_gate(a5),d2
	bmi	@f			*case:@Q
	mulu	d1,d2
	beq	err_cg
	lsr.l	#8,d2			*/256
	rts
@@:
	add.w	d1,d2
	bgt	exit_cg			*正常なケース
err_cg:					*step-@Q<=0のケース/@Q=0のケース
	move.w	d1,d2
exit_cg:
	rts

skip_@v:				*値のスキップ
	* > d1=step
	tst.b	(a0)+
	bpl	@f
	addq.w	#1,a0
@@:
	rts

get_st:					*ステップの取りだし
	* > d1=step
	moveq.l	#0,d1
	move.b	(a0)+,d1
	bpl	@f
	add.b	d1,d1			*最上位ビット殺す
	lsl.w	#7,d1
	move.b	(a0)+,d1		*get word step
@@:
	rts

get_st_gt:				*ステップ、ゲートの取りだし
	* > d1=step
	* > d2=gate
	moveq.l	#0,d1
	move.b	(a0)+,d1
	bpl	@f
	add.b	d1,d1			*最上位ビット殺す
	lsl.w	#7,d1
	move.b	(a0)+,d1		*get word step
@@:
	moveq.l	#0,d2
	move.b	(a0)+,d2
	bpl	exit_gsg		*0～127
	add.b	d2,d2			*最上位ビット殺す
	lsl.w	#7,d2
	move.b	(a0)+,d2		*get word gate
exit_gsg:
	rts

get_st_gt_vl:				*ステップ、ゲート、ベロシティの取りだし
	* > d1.l=step
	* > d2.l=gate
	* > d3.l=velocity param.(最上位bitが1の場合はデフォルト指定だった事を意味する)
	* x d0,d5
	moveq.l	#0,d1			*get step
	move.b	(a0)+,d1
	bpl	@f
	add.b	d1,d1			*最上位ビット殺す
	lsl.w	#7,d1
	move.b	(a0)+,d1		*get word step
@@:


	moveq.l	#0,d2			*get gate
	move.b	(a0)+,d2
	bpl	get_def_velo		*0～127
	add.b	d2,d2			*最上位ビット殺す
	lsl.w	#7,d2
	move.b	(a0)+,d2		*get word gate
	tst.w	d2
	bne	get_def_velo
	move.w	#TIE_GATE,d2
get_def_velo:				*ベロシティ取りだし部
	moveq.l	#0,d5
	move.b	p_velo(a5),d5
*aftc_on?:				*アフタータッチシーケンス?
	tst.b	p_aftc_sw(a5)
	beq	vseq_on?
	btst.b	#b_aftc_first,p_aftc_flg(a5)	*!3/26
	beq	vseq_on?			*!3/26
	tst.w	p_aftc_1st_dly(a5)	*始めにディレイがある時はdefault velocity
	bne	vseq_on?
	btst.b	#0,p_aftc_omt(a5)
	beq	vseq_on?
	tst.l	d4
	bmi	vseq_on?


















	btst.b	#0,p_aftc_rltv(a5)
	beq	@f
	moveq.l	#0,d0
	move.b	p_aftc_tbl(a5),d0
	ori.w	#$8000,d0
	swap	d0			*相対マーク
	or.l	d0,d5			*d5.hwに相対値を持っていっておく
	bra	vseq_on?
@@:
	move.b	p_aftc_tbl(a5),d5
vseq_on?:				*エンハンスド・ベロシティ・シーケンス?
	tst.b	p_vseq_param+p_arcc_sw(a5)
	beq	get_velo
	btst.b	#b_arcc_first,p_vseq_param+p_arcc_flg(a5)	*!3/26
	beq	get_velo					*!3/26
	lea	p_vseq_param(a5),a4	*エンハンスド・ベロシティ・シーケンス処理



	move.b	p_arcc_level(a4),d5
	ext.w	d5
	moveq.l	#0,d0
	move.b	p_arcc_origin(a4),d0	*SPECIAL ENHANCED VELOCITY SEQUENCEの場合
	add.w	d0,d5
get_velo:
	moveq.l	#0,d3
	move.b	(a0)+,d3
	bpl	1f			*直接指定のケース
	cmpi.b	#128,d3
	beq	@f			*デフォルト選択の場合
	sub.b	#192,d3			*相対ケース
	ext.w	d3
	add.w	d5,d3
	bra	2f
@@:
	move.w	d5,d3
2:
	bset.l	#31,d3			*デフォルト選択/相対指定であるマーク
	reduce_vol	d3
1:
	tst.l	d4
	bmi	2f
	tst.l	d5
	bpl	1f
	swap	d5
	tst.b	d5
	bpl	@f
	add.b	d5,d3
	bpl	1f
	clr.b	d3
	bra	1f
@@:
	add.b	d5,d3
	bpl	1f
	move.b	#127,d3			*わざと.b
1:

2:
	rts

make_note:				*ノートナンバーをノート記号へ変換
	* < d0.l=note num
	movem.l	d0-d1/a1,-(sp)
	lea	suji(pc),a1
	move.l	#'    ',(a1)
	clr.b	4(a1)
	divu	#12,d0
	moveq.l	#$2f,d1
	add.b	d1,d0
	cmp.b	d1,d0
	bhi	@f
	move.l	#$2d310000,2(a1)	*'-1',0,0
	bra	dnd0
@@:
	move.b	d0,2(a1)
dnd0:
	swap	d0
	add.w	d0,d0
	move.w	nn(pc,d0.w),(a1)
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

get_hex:			*値→16進数文字列
	* < d0=data value
	* < a1=格納したいアドレス
	* > (a1)=ascii numbers
	* - all
	movem.l	d0-d1/a1,-(sp)
	lea	suji+2(pc),a1
	clr.b	(a1)

	move.b	d0,d1
	andi.b	#$0f,d1
	add.b	#$30,d1
	cmpi.b	#'9',d1
	bls	@f
	addq.b	#7,d1
@@:
	move.b	d1,-(a1)
	lsr.l	#4,d0
	move.b	d0,d1
	andi.b	#$0f,d1
	add.b	#$30,d1
	cmpi.b	#'9',d1
	bls	@f
	addq.b	#7,d1
@@:
	move.b	d1,-(a1)
	lsr.l	#4,d0
	movem.l	(sp)+,d0-d1/a1
	rts

get_hex32:			*値→16進数文字列(4bytes)
	* < d0=data value
	* > (suji)=ascii numbers
	* - all
	movem.l	d0-d1/d4/a1,-(sp)
	lea	suji+8(pc),a1
	clr.b	(a1)
	moveq.l	#8-1,d4
gh_lp32:
	move.b	d0,d1
	andi.b	#$0f,d1
	add.b	#$30,d1
	cmpi.b	#'9',d1
	bls	@f
	addq.b	#7,d1
@@:
	move.b	d1,-(a1)
	lsr.l	#4,d0
	dbra	d4,gh_lp32
	movem.l	(sp)+,d0-d1/d4/a1
	rts

num_to_str:	*レジスタの値を文字数列にする
	* < d0.l=value
	* > (suji)=ascii data
	* > d0.b=１文字目のキャラクタ(' ' or '-')
	* - all
	movem.l	d1-d5/a0-a1,-(sp)
	moveq.l	#' ',d5
	clr.b	d4
	tst.l	d0
	bpl	@f
	moveq.l	#'-',d5
	neg.l	d0
@@:
	lea	suji(pc),a0
	lea	exp_tbl(pc),a1
	moveq.l	#10-1,d1
1:
	moveq.l	#0,d2
	move.l	(a1)+,d3
2:
	sub.l	d3,d0
	bcs	@f
	addq.b	#1,d2
	bra	2b
@@:
	add.l	d3,d0
	move.b	d2,d3
	or.b	d4,d3
	bne	@f
	move.b	#'0',(a0)+	*' '
	bra	3f
@@:
	st	d4
	add.b	#'0',d2
	move.b	d2,(a0)+
3:
	dbra	d1,1b
	tst.b	d4
	bne	@f
	move.b	#'0',-1(a0)
@@:
	clr.b	(a0)		*end flg
	move.l	d5,d0
	movem.l	(sp)+,d1-d5/a0-a1
	rts

num_to_str2:	*レジスタの値を文字数列にする
	* < d0.l=value
	* > (suji)=ascii data
	* > d0.b=１文字目のキャラクタ(' ' or '-')
	* - all
	movem.l	d1-d5/a0-a1,-(sp)
	moveq.l	#' ',d5
	clr.b	d4
	tst.l	d0
	bpl	@f
	moveq.l	#'-',d5
	neg.l	d0
@@:
	lea	suji(pc),a0
	lea	exp_tbl(pc),a1
	moveq.l	#10-1,d1
1:
	moveq.l	#0,d2
	move.l	(a1)+,d3
2:
	sub.l	d3,d0
	bcs	@f
	addq.b	#1,d2
	bra	2b
@@:
	add.l	d3,d0
	move.b	d2,d3
	or.b	d4,d3
	bne	@f
	move.b	#' ',(a0)+	*' '
	bra	3f
@@:
	st	d4
	add.b	#'0',d2
	move.b	d2,(a0)+
3:
	dbra	d1,1b
	tst.b	d4
	bne	@f
	move.b	#'0',-1(a0)
@@:
	clr.b	(a0)		*end flg
	move.l	d5,d0
	movem.l	(sp)+,d1-d5/a0-a1
	rts

no_zmusic_error:		*ZMUSICがない。
	lea	z_err_mes(pc),a1
	bra	@f

file_not_found:			*ファイルが見つかりません
	lea	fnf_err_mes(pc),a1
	bra	@f

version_error:			*バージョン番号不一致
	lea	version_mes(pc),a1
@@:
	move.w	#2,-(sp)
	pea	(a1)
	DOS	_FPUTS
	addq.w	#6,sp
	move.l	ssp(pc),a1
	IOCS	_B_SUPER
	move.w	#1,-(sp)
	DOS	_EXIT2

out_of_memory:			*メモリ不足
	move.w	#2,-(sp)
	pea	mem_mes(pc)
	DOS	_FPUTC
	addq.w	#6,sp
	move.w	#1,-(sp)
	DOS	_EXIT2

make_scrn:				*画面作成
					*初期画面の作成
	bsr	draw_cmnprms		*コモンパラメータ
	bsr	draw_box
	bsr	draw_mixbar_scale
	bra	draw_logo

draw_mixbar_scale:			*スケール描画(MASTER)
	movem.l	d0/d1-d3/a1,-(sp)
*	move.w	$e8002a,-(sp)
*	move.w	#$01_00+palet80,$e8002a		*同時アクセスON
	draw	9,4
	moveq.l	#if_max+2-1,d2
dmslp:
	pea	(a1)
	moveq.l	#8-1,d0
	move.l	#$6_0000,d1
	move.l	#$4_0000,d3
@@:
	move.b	#%0001_1000,(a1,d1.l)
	clr.b	(a1,d3.l)
	clr.b	(a1)
	lea	$80(a1),a1
	clr.b	(a1,d1.l)
	clr.b	(a1,d3.l)
	clr.b	(a1)
	lea	$80(a1),a1
	dbra	d0,@b
	move.l	(sp)+,a1
	add.w	#11,a1
	dbra	d2,dmslp
*	move.w	(sp)+,$e8002a
	movem.l	(sp)+,d0/d1-d3/a1
	rts

draw_mixbar_scale2:			*スケール描画(CH)
	* < a1.l=draw_address
	movem.l	d0/a1,-(sp)
	move.w	$e8002a,-(sp)
	move.w	#$01_00+palet80,$e8002a		*同時アクセスON
	moveq.l	#8-1,d0
@@:
	move.b	#%0001_1000,(a1)
	lea	$80(a1),a1
	clr.b	(a1)
	lea	$80(a1),a1
	dbra	d0,@b
	move.w	(sp)+,$e8002a
	movem.l	(sp)+,d0/a1
	rts

draw_mixbar_scale3:			*DEPTHスケール描画(CH)
	* < a1.l=draw_address
	movem.l	d0/a1,-(sp)
	move.w	$e8002a,-(sp)
	move.w	#$01_00+palet80,$e8002a		*同時アクセスON
	moveq.l	#16-1,d0
@@:
	move.b	#%0001_1000,(a1)
	lea	$80(a1),a1
	clr.b	(a1)
	lea	$80(a1),a1
	dbra	d0,@b
	move.w	(sp)+,$e8002a
	movem.l	(sp)+,d0/a1
	rts

draw_hold_scale:			*HOLD/@Rスケール描画
	* < a1.l=draw_address
	movem.l	d0/a1-a2,-(sp)
	move.w	$e8002a,-(sp)
	move.w	#$01_00+palet80,$e8002a		*同時アクセスON
	moveq.l	#4-1,d0
@@:
	move.b	#%0111_1110,(a1)
	lea	$80(a1),a1
	clr.b	(a1)
	lea	$80(a1),a1
	dbra	d0,@b
	lea	lamp_pat(pc),a2
	moveq.l	#8-1,d0
@@:
	move.b	(a2)+,(a1)
	lea	$80(a1),a1
	dbra	d0,@b
	move.w	(sp)+,$e8002a
	movem.l	(sp)+,d0/a1-a2
	rts

draw_pan_scale:					*PANPOTスケール描画
	* < a1.l=draw_address
	movem.l	d0-d1/a1-a2,-(sp)
	move.w	$e8002a,-(sp)
	move.w	palet_tbl(pc),d1
	ori.w	#$01_00,d1
	move.w	d1,$e8002a		*同時アクセスON
	moveq.l	#16-1,d0
	lea	pantrim0(pc),a2
@@:
	move.b	(a2)+,(a1)+
	move.b	(a2)+,(a1)+
	lea	$80-2(a1),a1
	dbra	d0,@b
	move.w	(sp)+,$e8002a
	movem.l	(sp)+,d0-d1/a1-a2
	rts

draw_logo:				*LOGO描画
	movem.l	d0-d1/a1-a2,-(sp)
	move.w	$e8002a,-(sp)
	move.w	#$01_00+palet90,$e8002a		*同時アクセスON
	draw	86,4
	moveq.l	#3-1,d1
	lea	logo_z(pc),a2
dllp:
	pea	2(a1)
	moveq.l	#16-1,d0
@@:
	move.b	(a2)+,(a1)+
	move.b	(a2)+,(a1)+
	lea	$80-2(a1),a1
	dbra	d0,@b
	move.l	(sp)+,a1
	dbra	d1,dllp

	draw	92,4
	lea	zsv_ver(pc),a2
	moveq.l	#palet90,d1
	bsr	cgwr

	move.w	(sp)+,$e8002a
	movem.l	(sp)+,d0-d1/a1-a2
	rts

draw_level_scale:				*LEVELスケール描画
	* < a1.l=draw_address
	movem.l	d0/a1,-(sp)
	move.w	$e8002a,-(sp)
	move.w	#$01_00+paleta0,$e8002a		*同時アクセスON
	moveq.l	#8-1,d0
@@:
	st.b	(a1)
	lea	$80(a1),a1
	clr.b	(a1)
	lea	$80(a1),a1
	dbra	d0,@b
	move.w	(sp)+,$e8002a
	movem.l	(sp)+,d0/a1
	rts

draw_mixbar:
	*< d0.l=now(0-128)
	*< d1.l=previous(0-128)
	*< a3.l=addr
	movem.l	d0-d1/a1/a3,-(sp)
	move.l	a3,a1
	lsr.l	#3,d1
	add.w	d1,d1
	add.w	mixbar_pos_tbl(pc,d1.w),a3
	move.w	$e8002a,-(sp)
	move.w	#$01_00+palet50,$e8002a	*同時アクセスON
	clr.b	(a3)			*前のトリムを削除
	lsr.l	#3,d0
	add.w	d0,d0
	add.w	mixbar_pos_tbl(pc,d0.w),a1
	move.b	#%0111_1110,(a1)
	move.w	(sp)+,$e8002a
	movem.l	(sp)+,d0-d1/a1/a3
	rts

mixbar_pos_tbl:
	dc.w	-$000,-$080,-$100,-$180,-$200,-$280,-$300,-$380
	dc.w	-$400,-$480,-$500,-$580,-$600,-$680,-$700,-$780
	dc.w	-$780

draw_bender:
	*< d5.l=now(-8192～+8191,-768～+768)
	*< d1.l=previous(-8192～+8191,-768～+768)
	*< a3.l=addr
	movem.l	d1/d5/a1/a3,-(sp)
	tst.w	p_type(a5)
	bpl	1f
	cmpi.l	#8191,d5
	ble	@f
	move.l	#8191,d5
@@:
	cmpi.l	#-8192,d5
	bge	@f
	move.l	#-8192,d5
@@:
	add.l	#8192,d5		*0-16383
	lsr.l	#8,d5
	lsr.l	#2,d5

	cmpi.l	#8191,d1
	ble	@f
	move.l	#8191,d1
@@:
	cmpi.l	#-8192,d1
	bge	@f
	move.l	#-8192,d1
@@:
	add.l	#8192,d1		*0-16383
	lsr.l	#8,d1
	lsr.l	#2,d1
	bra	do_draw_bender
1:
	cmpi.l	#768,d5
	ble	@f
	move.l	#768,d5
@@:
	cmpi.l	#-768,d5
	bge	@f
	move.l	#-768,d5
@@:
	add.l	#768,d5
	divu	#96,d5

	cmpi.l	#768,d1
	ble	@f
	move.l	#768,d1
@@:
	cmpi.l	#-768,d1
	bge	@f
	move.l	#-768,d1
@@:
	add.l	#768,d1
	divu	#96,d1
do_draw_bender:
	move.l	a3,a1
	add.w	d1,d1
	add.w	bender_pos_tbl(pc,d1.w),a3
	move.w	$e8002a,-(sp)
	move.w	#$01_00+palet50,$e8002a	*同時アクセスON
	clr.b	(a3)			*前のトリムを削除
	add.w	d5,d5
	add.w	bender_pos_tbl(pc,d5.w),a1
	move.b	#%0111_1110,(a1)
	move.w	(sp)+,$e8002a
	movem.l	(sp)+,d1/d5/a1/a3
	rts

bender_pos_tbl:
	dc.w	-$000,-$080,-$100,-$180,-$200,-$280,-$300,-$380
	dc.w	-$400,-$480,-$500,-$580,-$600,-$680,-$700,-$780
	dc.w	-$780
*	dc.w	-$800,-$880,-$900,-$980,-$a00,-$a80,-$b00,-$b80
*	dc.w	-$c00,-$c80,-$d00,-$d80,-$e00,-$e80,-$f00,-$f80
*	dc.w	-$f80

draw_pedal:
	*< d0.l=now(0-127)
	*< d1.l=previous(0-127)
	*< a3.l=addr
	move.w	$e8002a,-(sp)
	move.w	#$01_00+palet50,$e8002a	*同時アクセスON
	movem.l	d0-d3,-(sp)
	lsr.w	#4,d1
	lsr.w	#4,d0
	moveq.l	#1,d2
	cmp.w	d0,d1
	bls	@f
	moveq.l	#-1,d2
@@:
	move.l	d1,d3
drwpdllp:
	movem.l	d0-d1/a1/a3,-(sp)
	move.l	a3,a1
	tst.w	d2
	bpl	@f
	add.w	d3,d3
	add.w	pedal_pos_tbl(pc,d3.w),a3
	clr.b	(a3)			*前のトリムを削除
@@:
	add.w	d1,d1
	btst.l	#1,d1
	beq	@f
	add.w	pedal_pos_tbl(pc,d1.w),a1
	move.b	#%0111_1110,(a1)
@@:
	movem.l	(sp)+,d0-d1/a1/a3
	cmp.w	d0,d1
	beq	@f
	move.l	d1,d3
	add.w	d2,d1
	bra	drwpdllp
@@:
	movem.l	(sp)+,d0-d3
	move.w	(sp)+,$e8002a
	rts

pedal_pos_tbl:
	dc.w	-$000,-$080,-$100,-$180,-$200,-$280,-$300,-$380
*	dc.w	-$400,-$480,-$500,-$580,-$600,-$680,-$700,-$780

draw_lamp:
	*< d0.l=value($80 or not)	$80...NO OFF
	*< a3.l=addr
	movem.l	d0-d1/a1/a3,-(sp)
	move.w	$e8002a,-(sp)
	move.l	a3,a1
	move.w	#$01_00+paletf0,$e8002a	*同時アクセスON
	moveq.l	#8-1,d1
@@:
	clr.b	(a1)			*前のトリムを削除
	lea	$80(a1),a1
	dbra	d1,@b

	move.w	#$01_00+palet90,d1
	tst.b	d0
	bmi	@f
	move.w	#$01_00+palet60,d1
@@:
	move.w	d1,$e8002a		*同時アクセスON
	lea	lamp_pat(pc),a1
	moveq.l	#8-1,d1
@@:
	move.b	(a1)+,(a3)
	lea	$80(a3),a3
	dbra	d1,@b

	move.w	(sp)+,$e8002a
	movem.l	(sp)+,d0-d1/a1/a3
	rts

draw_pan:
	*< d0.w=now(0-128)
	*< a3.l=addr
	movem.l	d0-d1/a1/a3,-(sp)
	mulu	#18,d0
	divu	#127,d0
	lsl.w	#5,d0
	lea	pantrim_tbl(pc),a1
	add.w	d0,a1
	move.w	$e8002a,-(sp)
	ori.w	#$01_00,d1
	move.w	d1,$e8002a		*同時アクセスON
	moveq.l	#16-1,d0
@@:
	move.b	(a1)+,(a3)+
	move.b	(a1)+,(a3)+
	add.w	#$80-2,a3
	dbra	d0,@b
	move.w	(sp)+,$e8002a
	movem.l	(sp)+,d0-d1/a1/a3
	rts

draw_arccbar:
	*< d2.w=now(-128～+127)
	*< d1.w=previous(-128～+127)
	*< a3.l=addr
	movem.l	d1-d2/a1/a3,-(sp)
	ext.w	d2
	add.w	#128,d2
	lsr.w	#4,d2
	ext.w	d1
	add.w	#128,d1
	lsr.w	#4,d1
	move.l	a3,a1
	add.w	d1,d1
	add.w	arcc_pos_tbl(pc,d1.w),a3
	move.w	$e8002a,-(sp)
	move.w	#$01_00+palet50,$e8002a	*同時アクセスON
	clr.b	(a3)			*前のトリムを削除
	add.w	d2,d2
	add.w	arcc_pos_tbl(pc,d2.w),a1
	move.b	#%0111_1110,(a1)
	move.w	(sp)+,$e8002a
	movem.l	(sp)+,d1-d2/a1/a3
	rts

arcc_pos_tbl:
	dc.w	-$000,-$080,-$100,-$180,-$200,-$280,-$300,-$380
	dc.w	-$400,-$480,-$500,-$580,-$600,-$680,-$700,-$780
*	dc.w	-$780

disp_percentage:
	movem.l	d0-d3/a1,-(sp)
	move.w	$e8002a,-(sp)
	move.w	$e8002e,-(sp)

	clr.w	$e8002a
	draw	96,4
	moveq.l	#4-1,d3
dsppcntlp2:
	pea	(a1)
	moveq.l	#16-1,d2
dsppcntlp1:
	move.w	#$00,ccr
	roxl.w	-(a1)
	roxl.w	-(a1)
	roxl.w	-(a1)
	roxl.w	-(a1)
	add.w	#$80+8,a1
	dbra	d2,dsppcntlp1
	move.l	(sp)+,a1
	add.l	#$02_0000,a1
	dbra	d3,dsppcntlp2

	lea	$e00000+94+$80*5*8+7*$80,a1
	move.l	x_count(pc),d0
	lsr.l	#5,d0		*<<4+>>9=>>5
	cmpi.l	#15,d0
	bls	@f
	moveq.l	#15,d0
@@:
	add.w	d0,d0
	add.w	d0,d0
	move.w	#$fffe,$e8002e
@@:
	pea	(a1)
	add.w	percent_pos_tbl+2(pc,d0.w),a1
	move.w	percent_pos_tbl+0(pc,d0.w),$e8002a	*同時アクセスON
	move.w	#-1,(a1)
	move.l	(sp)+,a1
	subq.w	#4,d0
	bne	@b
	move.w	(sp)+,$e8002e

	move.l	x_count(pc),d0
	cmp.l	cpu_power(pc),d0
	beq	@f
	mulu	#100,d0
	lsr.l	#8,d0
	lsr.l	#1,d0
	bsr	num_to_str
	moveq.l	#palet30,d1
	draw	84,5
	lea	suji+7(pc),a2
	bsr	cgwr
@@:
	move.w	(sp)+,$e8002a
	movem.l	(sp)+,d0-d3/a1
	rts

percent_pos_tbl:
	dc.w	$0300+palet90,-$000,$0300+palet90,-$080,$0300+palet90,-$100,$0300+palet90,-$180
	dc.w	$0300+paletc0,-$200,$0300+paletc0,-$280,$0300+paletc0,-$300,$0300+paletc0,-$380
	dc.w	$0300+palet40,-$400,$0300+palet40,-$480,$0300+palet40,-$500,$0300+palet40,-$580
	dc.w	$0300+palet40,-$600,$0300+palet40,-$680,$0300+palet40,-$700,$0300+palet40,-$780

draw_attack:
	*< d1.l=now(0-15)
	*< d2.l=previous(0-15)
	*< a3.l=addr
	move.w	$e8002a,-(sp)
	movem.l	d1-d4,-(sp)
	moveq.l	#1,d3
	cmp.w	d1,d2
	bls	@f
	moveq.l	#-1,d3
@@:
	move.l	d2,d4
drwatklp:
	movem.l	d1-d2/a1/a3,-(sp)
	move.l	a3,a1
	add.w	d4,d4
	add.w	d4,d4
	bne	@f
	moveq.l	#4,d4
@@:
	add.w	d2,d2
	add.w	d2,d2
	bne	@f
	moveq.l	#4,d2
@@:
	tst.w	d3
	bpl	@f
	add.w	attack_pos_tbl+2(pc,d4.w),a3
	move.w	#$01_00+paletf0,$e8002a		*同時アクセスON
	clr.b	(a3)				*前のトリムを削除
	cmp.w	d2,d4
	beq	@f
	btst.l	#2,d4
	beq	@f
	move.w	#$01_00+paleta0,$e8002a		*同時アクセスON
	st.b	(a3)
@@:
	add.w	attack_pos_tbl+2(pc,d2.w),a1
	move.w	#$01_00+paletf0,$e8002a		*同時アクセスON
	clr.b	(a1)				*前のトリムを削除
	btst.l	#2,d2
	beq	@f
	move.w	attack_pos_tbl(pc,d2.w),$e8002a	*同時アクセスON
	st.b	(a1)
@@:
	movem.l	(sp)+,d1-d2/a1/a3
	cmp.w	d1,d2
	beq	@f
	move.l	d2,d4
	add.w	d3,d2
	bra	drwatklp
@@:
	movem.l	(sp)+,d1-d4
	move.w	(sp)+,$e8002a
	rts

attack_pos_tbl:
	dc.w	$0100+palet40,-$000,$0100+palet40,-$080,$0100+palet40,-$100,$0100+palet40,-$180
	dc.w	$0100+palet40,-$200,$0100+palet40,-$280,$0100+palet40,-$300,$0100+palet40,-$380
	dc.w	$0100+paletc0,-$400,$0100+paletc0,-$480,$0100+paletc0,-$500,$0100+paletc0,-$580
	dc.w	$0100+palet90,-$600,$0100+palet90,-$680,$0100+palet90,-$700,$0100+palet90,-$780

draw_release:				*アタックグラフ減衰表示
	*< d2.l=now(0-15)
	*< a3.l=addr
	move.w	$e8002a,-(sp)
	movem.l	d2/a3,-(sp)
	add.w	d2,d2
	bne	@f
	moveq.l	#2,d2
@@:
	add.w	release_pos_tbl(pc,d2.w),a3
	move.w	#$01_00+paletf0,$e8002a		*同時アクセスON
	clr.b	(a3)
	btst.l	#1,d2
	beq	@f
	move.w	#$01_00+paleta0,$e8002a		*同時アクセスON
	st.b	(a3)
@@:
	movem.l	(sp)+,d2/a3
	move.w	(sp)+,$e8002a
	rts

release_pos_tbl:
	dc.w	-$000,-$080,-$100,-$180,-$200,-$280,-$300,-$380
	dc.w	-$400,-$480,-$500,-$580,-$600,-$680,-$700,-$780

draw_box:			*ボックス描画
	movem.l	d0-d1/a1-a2,-(sp)
	move.w	$e8002a,-(sp)
	move.w	#$01_00+palet30,$e8002a	*同時アクセスON
	lea	$e00000+54+$80*3*8,a1
	lea	$e00000+54+$80*3*8+$80*6,a2
	move.b	#$01,(a1)+
	move.b	#$01,(a2)+
	moveq.l	#41-1,d0
@@:
	st.b	(a1)+
	st.b	(a2)+
	dbra	d0,@b

	lea	$e00000+54+$80*3*8+$80,a1
	moveq.l	#5-1,d0
@@:
	move.l	#$01000000,(a1)+
	rept	9
	clr.l	(a1)+
	endm
	move.w	#$01,(a1)+
	add.w	#$80-42,a1
	dbra	d0,@b
	move.w	(sp)+,$e8002a
	movem.l	(sp)+,d0-d1/a1-a2
	rts

clear_box:				*ボックスデリート
	movem.l	d0-d1/a1-a2,-(sp)
	move.w	$e8002a,-(sp)
	move.w	#$01_00+palet40,$e8002a	*同時アクセスON

	lea	$e00000+54+$80*3*8+$80,a1
	moveq.l	#5-1,d0
@@:
	rept	10
	clr.l	(a1)+
	endm
	clr.w	(a1)+
	add.w	#$80-42,a1
	dbra	d0,@b
	move.w	(sp)+,$e8002a
	movem.l	(sp)+,d0-d1/a1-a2
	rts

draw_edge:			*縦棒
	* < d1.l=ptr
	* - all
	movem.l	d0-d2/a1,-(sp)
	move.l	d1,d0
	lsr.l	#3,d1
	lea	$e00000+$40000+55+$80*3*8+$80,a1	*x=55,y=3
	add.w	d1,a1
	andi.w	#7,d0
	move.b	ptn(pc,d0.w),d0

	move.w	$e8002a,-(sp)
	clr.w	$e8002a			*同時アクセスOFF
	moveq.l	#5-1,d1
@@:
	or.b	d0,(a1)
	add.w	#$80,a1
	dbra	d1,@b
	move.w	(sp)+,$e8002a
	movem.l	(sp)+,d0-d2/a1
	rts
ptn:	dc.b	$80,$40,$20,$10,$08,$04,$02,$01

draw_cmnprms:				*コモンパラメータのタイトル
	draw	0,2
	lea	common1_tbl(pc),a2
	moveq	#palet30,d1
	bsr	cgwr

	draw	0,3
	lea	common2_tbl(pc),a2
	moveq	#palet30,d1
	bsr	cgwr

	draw	0,4
	lea	common3_tbl(pc),a2
	moveq	#palet30,d1
	bsr	cgwr

	draw	0,5
	lea	common4_tbl(pc),a2
	moveq	#palet30,d1
	bra	cgwr

draw_opmmap_ttl:
reglist	reg	d0-d3/a0-a2
	movem.l	reglist,-(sp)
	move.w	$e8002a,-(sp)
	move.w	#$01_00+paletf0,$e8002a		*同時アクセス

	lea	$e00000+96,a0
	move.w	#(trn+1)*16-1,d0
1:
	moveq.l	#8-1,d1
2:
	clr.l	(a0)+
	dbra	d1,2b
	lea	96(a0),a0
	dbra	d0,1b
	move.w	(sp)+,$e8002a

	lea	opm_data(pc),a1
	move.w	#1024/4-1,d0
@@:
	clr.l	(a1)+
	dbra	d0,@b

	draw	96,2
	lea	FMttlg0(pc),a2
	moveq.l	#palet30,d1
	bsr	cgwr

	draw	96,3
	lea	FMttlg1(pc),a2
	bsr	cgwr

	draw	96,4
	lea	FMttlg2(pc),a2
	bsr	cgwr

	draw	96,6
	moveq.l	#8-1,d2
	moveq.l	#'1',d3
1:
	moveq.l	#palet30,d1
	btst.l	#0,d2
	beq	@f
	moveq.l	#palet20,d1
@@:
	lea	FMttl0(pc),a2
	bsr	cgwr
	moveq.l	#palet90,d1
	lea	FMchn(pc),a2
	move.l	d3,d0
	move.b	d3,2(a2)
	addq.w	#1,a1
	bsr	cgwr
	add.w	#$80*8*6-1,a1
	addq.w	#1,d3
	dbra	d2,1b

	draw	96,7
	lea	FMttl1(pc),a2
	moveq.l	#8-1,d2
1:
	moveq.l	#palet30,d1
	btst.l	#0,d2
	beq	@f
	moveq.l	#palet20,d1
@@:
	bsr	cgwr
	add.w	#$80*8*6,a1
	dbra	d2,1b
	movem.l	(sp)+,reglist
	rts

draw_trkprms:				*トラックパラメータのタイトル
	* < d1.l=palet
	* < a1.l=addr
	* - all
	movem.l	a1-a2,-(sp)
	lea	track_tbl1(pc),a2
	bsr	cgwr
	add.w	#$80*8,a1

	lea	track_tbl2(pc),a2
	bsr	cgwr
	add.w	#$80*8,a1

	lea	track_tbl3(pc),a2
	bsr	cgwr
	add.w	#$80*8,a1

	lea	track_tbl4(pc),a2
	bsr	cgwr
	add.w	#$80*8,a1

	movem.l	d0-d1/a1,-(sp)		*KEYBOARD
	move.w	$e8002a,-(sp)
	ori.w	#$01_00,d1	*同時アクセスON
	move.w	d1,$e8002a	*アクセスモード設定
	add.w	#48,a1
	moveq.l	#10-1,d0
drwkblp0:
	moveq.l	#12-1,d1
	lea	kbd_ptn1(pc),a2
	pea	(a1)
@@:
	move.l	(a2)+,(a1)+
	dbra	d1,@b
	move.l	(sp)+,a1
	add.w	#$80,a1
	dbra	d0,drwkblp0

	moveq.l	#5-1,d0
drwkblp1:
	moveq.l	#12-1,d1
	lea	kbd_ptn2(pc),a2
	pea	(a1)
@@:
	move.l	(a2)+,(a1)+
	dbra	d1,@b
	move.l	(sp)+,a1
	add.w	#$80,a1
	dbra	d0,drwkblp1

*	moveq.l	#12-1,d1
*	lea	kbd_ptn3(pc),a2
*@@:
*	move.l	(a2)+,(a1)+
*	dbra	d1,@b

	move.w	(sp)+,$e8002a
	movem.l	(sp)+,d0-d1/a1

	lea	track_tbl5(pc),a2
	bsr	cgwr
	add.w	#$80*8,a1

	lea	track_tbl6(pc),a2
	bsr	cgwr
	movem.l	(sp)+,a1-a2
	rts

cgwr:				*8*8文字書き込み
	* < d1.w=attr(0000_0000～1111_0000)
	* < a1.l=write address
	* < a2.l=str address
	movem.l	d0-d1/a1-a3,-(sp)
	move.w	$e8002a,-(sp)
	ori.w	#$01_00,d1	*同時アクセスON
	move.w	d1,$e8002a	*アクセスモード設定
cgwrlp:
	moveq.l	#0,d0
	move.b	(a2)+,d0
	bmi	next_cgwr
	beq	exit_cgwr
	pea	(a1)
	lsl.w	#3,d0
	move.l	font_addr(pc),a3	*CG ADR
	add.w	d0,a3
	moveq.l	#8-1,d1
@@:
	move.b	(a3)+,(a1)
	lea	$80(a1),a1
	dbra	d1,@b
	move.l	(sp)+,a1
next_cgwr:
	addq.w	#1,a1
	bra	cgwrlp
exit_cgwr:
	move.w	(sp)+,$e8002a
	movem.l	(sp)+,d0-d1/a1-a3
	rts

draw_hbar_fm_noise:
	move.b	hbvtbl_n(pc,d0.w),d0
	bra	draw_hbar

hbvtbl_n:
		.dc.b	  0,  1,  8, 16, 20, 26, 30, 35, 39, 43
		.dc.b	 47, 51, 54, 57, 59, 61, 63, 65, 67, 68
		.dc.b	 70, 71, 72, 73, 75, 76, 77, 78, 79, 80
		.dc.b	 81, 82, 83, 84, 84, 85, 86, 87, 88, 89
		.dc.b	 89, 90, 91, 92, 92, 93, 94, 94, 95, 96
		.dc.b	 96, 97, 98, 98, 99,100,100,101,102,102
		.dc.b	103,103,104,104,105,105,106,106,107,107
		.dc.b	108,108,109,109,110,110,111,111,111,112
		.dc.b	112,113,113,113,114,114,114,115,115,116
		.dc.b	116,116,117,117,117,118,118,118,119,119
		.dc.b	119,120,120,120,121,121,121,122,122,122
		.dc.b	123,123,123,123,124,124,124,124,125,125
		.dc.b	125,125,126,126,126,126,127,127

draw_hbar_fm:				*FM音源ケース
	move.b	hbvtbl(pc,d0.w),d0
draw_hbar:				*8*8文字書き込み
	* < d0.w=0-127
	* < d1.w=attr(0000_0000～1111_0000)
	* < a1.l=write address
reglist	reg	d0-d1/a1/a3
	movem.l	reglist,-(sp)
	move.w	$e8002a,-(sp)
	ori.w	#$01_00,d1		*同時アクセスON
	move.w	d1,$e8002a		*アクセスモード設定
	lea	hbar_data(pc),a3
	tst.w	d0
	beq	@f
	andi.w	#$fffc,d0
	lea	4(a3,d0.w),a3
@@:
	clr.b	(a1)+
	clr.b	(a1)+
	clr.b	(a1)+
	clr.b	(a1)+
	lea	$80-4(a1),a1
	moveq.l	#5-1,d1
@@:
	move.b	(a3),(a1)+
	move.b	1(a3),(a1)+
	move.b	2(a3),(a1)+
	move.b	3(a3),(a1)+
	lea	$80-4(a1),a1
	dbra	d1,@b
	clr.b	(a1)+
	clr.b	(a1)+
	clr.b	(a1)+
	clr.b	(a1)+
	move.w	(sp)+,$e8002a
	movem.l	(sp)+,reglist
	rts

hbvtbl:
	.dc.b	  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
	.dc.b	  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
	.dc.b	  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
	.dc.b	  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
	.dc.b	  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
	.dc.b	  0,  0,  1,  1,  1,  1,  1,  1,  2,  2
	.dc.b	  2,  2,  3,  3,  3,  4,  4,  5,  5,  6
	.dc.b	  6,  7,  7,  8,  8,  9, 10, 10, 11, 12
	.dc.b	 13, 14, 15, 16, 17, 18, 19, 20, 22, 23
	.dc.b	 24, 26, 27, 29, 30, 32, 34, 36, 38, 40
	.dc.b	 42, 44, 46, 48, 50, 52, 55, 57, 60, 62
	.dc.b	 65, 68, 72, 74, 77, 81, 84, 88, 91, 94
	.dc.b	 98,102,106,110,114,118,122,127

key_bind_db:
	movem.l	d0-d2/d4/a0/a2,-(sp)

	pea	zp_key(pc)
	bsr	search_env
	addq.w	#4,sp
	tst.l	d0
	beq	quit_zk_db

	moveq.l	#$7f,d4
	move.l	d0,a2
	lea	key_tbl_db(pc),a0
	moveq.l	#14-1,d2
@@:
	bsr	get_num
	ror.b	#4,d1
	move.b	d1,(a0)+
	dbra	d2,@b
quit_zk_db:
	movem.l	(sp)+,d0-d2/d4/a0/a2
	rts

work:	set	zsv_work
	.include	fopen.s

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

chk_num:			*数字かどうかチェック
	* > eq=number
	* > mi=not num
	move.l	d0,-(sp)
	bsr	skip_spc
	move.b	(a2),d0
	cmpi.b	#'%',d0
	beq	yes_num
	cmpi.b	#'$',d0
	beq	yes_num
	cmpi.b	#'-',d0
	beq	yes_num
	cmpi.b	#'+',d0
	beq	yes_num
	cmpi.b	#'0',d0
	bcs	not_num
	cmpi.b	#'9',d0
	bhi	not_num
yes_num:
	move.l	(sp)+,d0
	move.w	#CCR_ZERO,ccr
	rts
not_num:
	move.l	(sp)+,d0
	move.w	#CCR_NEGA,ccr
	rts

get_num:			*数字文字列を数値へ
	* < (a2)=number strings
	* > d1.l=value
	* > a2=next
	* - all
reglist	reg	d0/d2-d3
	bsr	skip_spc	*' ',tabなどをskip
	tst.b	(a2)
	beq	num_ret
	movem.l	reglist,-(sp)
	cmpi.b	#'-',(a2)
	seq	d2   		*'-'ならマーク
	bne	get_num0
	addq.w	#1,a2		*skip '-'
get_num0:
	bsr	skip_plus
	bsr	skip_spc

	cmpi.b	#'$',(a2)
	beq	get_hexnum_
	cmpi.b	#'%',(a2)
	beq	get_binnum_

	moveq.l	#0,d1
	moveq.l	#0,d0
num_lp01:
	move.b	(a2)+,d0
	beq	num_exit
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
	subq.w	#1,a2
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
	tst.b	(a2)+
	beq	num_exit
	bsr	skip_spc
__num_lp01_:
	move.b	(a2)+,d0
	beq	num_exit
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
	tst.b	(a2)+
	beq	num_exit
	bsr	skip_spc
b__num_lp01_:
	move.b	(a2)+,d0
	beq	num_exit
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

skip_sep:			*セパレータを1個だけスキップする
	move.w	d0,-(sp)	*(スペース/タブ/改行は複数スキップする)
skip_sep_lp:
	move.b	(a2)+,d0
	cmpi.b	#' ',d0
	beq	skip_sep_lp
	cmpi.b	#09,d0
	beq	skip_sep_lp
	cmpi.b	#',',d0
	beq	exit_ssl
	subq.w	#1,a2
exit_ssl:
	move.w	(sp)+,d0
	rts

skip_spc:			*スペースをスキップする
	move.w	d0,-(sp)
@@:
	move.b	(a2)+,d0
	cmpi.b	#' ',d0
	beq	@b
	cmpi.b	#09,d0		*skip tab
	beq	@b
	subq.w	#1,a2
exit_skip_spc:
	move.w	(sp)+,d0
	rts

skip_plus:			*PLUSをスキップする
	cmpi.b	#'+',(a2)+
	beq	skip_plus
	subq.w	#1,a2
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

cache_flush:				*キャッシュのフラッシュ
	movem.l	d0-d1,-(sp)
	moveq.l	#3,d1
	IOCS	_SYS_STAT
	movem.l	(sp)+,d0-d1
	rts

*go_calc_debug:
*	moveq.l	#30-1,d0
*	moveq.l	#0,d1
*@@:
*	add.l	-(a0),d1
*	dbra	d0,@b
*	divu	#30,d1
*	move.l	d1,x_count-zsv_work(a6)
*	trap	#9

	if	(debug.and.1)
debug2:					*デバグ用ルーチン(レジスタ値を表示／割り込み対応)
	move.w	sr,db_work2-zsv_work(a6)	*save sr	(サブルーチン_get_hex32が必要)
	ori.w	#$700,sr			*mask int
	movem.l	d0-d7/a0-a7,db_work-zsv_work(a6)

	moveq.l	#%0011,d1
	IOCS	_B_COLOR

	lea	str__(pc),a1

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
db_work:	dcb.l	16,0		*for debug
db_work2:	dc.l	0
		dc.b	'REGI'
	endif

	.data
zsv_work:
disp_start:	dc.w	0	*表示開始トラック番号
*velo_buf:	ds.w	1	*Velocity値の一時覚え書き
chfdr_buf:	ds.w	1	*CH FADERの値の一時覚え書き
x_count:	ds.l	1
cpu_power:	ds.l	1
adr_cnt:	dc.l	30
adr:		ds.l	1	*!debug
no_disp_tbl:	ds.b	10	*ZSV.Rの各トラックのステータス(d7:active(1) or dead(0))
FF_timer:	dc.l	-1	*$ffff0000+高速タイマ(M:$c0,B:$f8,A:$399)
SL_timer:	dc.l	-1	*$ffff0000+低速タイマ(M:$c0,B:$f8,A:$399)
mdmsk_k:	dcb.b	4,0
fadeout_speed:	dc.w	fader_dflt_spd*256
fadein_speed:	dc.w	fader_dflt_spd*256
scr_x:		dc.w	0	*表示座標
scr_y:		dc.w	0
op_ofs:		dc.w	$00,$10,$08,$18
dev_tbl:	dc.w	$0000,$0001,$8000,$8001,$8002,$8003
flash_palet:	dc.w	%11111_11111_11111_1,%01111_01111_01111_0
dummy_data:	ds.b	128
arwd_k:		dc.b	0	*		!
		ds.b	1	*		!
arwd_krcnt:	dc.b	0	*h_waitカウンタ	!
arwd_krwork:	dc.b	0	*h_waitkワーク	!
arwu_k:		dc.b	0	*		#
		ds.b	1	*		#
arwu_krcnt:	dc.b	0	*h_waitカウンタ	#
arwu_krwork:	dc.b	0	*h_waitkワーク	#
rlu_k:		dc.b	0	*		%
		ds.b	1	*		%
rlu_krcnt:	dc.b	0	*h_waitカウンタ	%
rlu_krwork:	dc.b	0	*h_waitkワーク	%
rld_k:		dc.b	0	*		$
		ds.b	1	*		$
rld_krcnt:	dc.b	0	*h_waitカウンタ	$
rld_krwork:	dc.b	0	*h_waitkワーク	$


*byte
vol_k:		dc.b	0
pan_k:		dc.b	0
pan_mode:	dc.b	0	*panpotの表示モード(0:value,1:L/R)
disp_mode:	dc.b	0	*d0:pmod/arcc/arcc/veloの表示モード(0:depth,1:realtime)
				*d1:vol/velo表示モード(0:number,1:bar)
mod_k:		dc.b	0
mask_k:		dc.b	0
mask2_k:	dc.b	0
home_k:		dc.b	0
del_k:	dc.b	0
init_mask:	dc.b	1		*マスクを初期化するか
dummy_velo:	dc.b	$80		*Default Velocity code
*v_count:	ds.b	1
fmmsk_k:	ds.b	1
admsk_k:	ds.b	1
bank_k:		ds.b	1
bank_mode:	dc.b	2
play_k:		dc.b	0
stop_k:		dc.b	0
stop_mode:	dc.b	0
cont_k:		dc.b	0
fadein_k:	dc.b	0
fadeout_k:	dc.b	0
_FF_flg:	dc.b	0
_SLOW_flg:	dc.b	0
lang:		dc.b	0	*言語モード(0:English,1:Japanese)
opmmap_flg:	dc.b	0	*[0]非表示 1:表示
ext_palet:	dc.b	0	*外部パレット使用か

z_err_mes:	dc.b	'ZSV.R COULD NOT RECOGNIZE ZMUSIC Ver.3.0.',13,10,0
version_mes:	dc.b	'ZSV.R RUNS ON ZMUSIC SYSTEM VERSION 3.00 AND OVER.',13,10,0
mem_mes:	dc.b	'OUT OF MEMORY.',13,10,0
fnf_err_mes:	dc.b	'FILE NOT FOUND.',13,10,0
title_mes:	dc.b	'ZMUSIC STATUS VIEWER '
		dc.b	$F3,'V',$F3,'E',$F3,'R',$F3,'S',$F3,'I',$F3,'O',$F3,'N'
*		zsv_version
*		test
		version
		TEST
		dc.b	' (C) 1996,98 '
		dc.b	'ZENJI SOFT',13,10,0
zsv_ver:	_version
		dc.b	0
no_title:	dc.b	'NO TITLE',0
init_color:	dc.b	$1b,'[m',$00,$00
colon:		dc.b	':',0
Status:		dc.b	'STATUS:',0
Timbre:		dc.b	'TIMBRE:',0
no_bank:	dc.b	'     ',0
zp_key:		dc.b	'zp3_keyctrl',0
key_tbl_db:	dc.b	$0e,$0b,$0e,$2e,$0e,$3e,$0e,$1b,$0e,$7a,$0e,$5a,$0e,$6a

sp2a0: .macro str,nul
  @esc:=0
  .irpc c,str
    .if (@esc==0).and.('&c'=='\')
      @esc:=1
    .elif (@esc==0).and.('&c'==' ')
      .dc.b $a0
    .else
      .dc.b '&c'
      @esc:=0
    .endif
  .endm
  .dc.b nul
.endm
	*		           1         2         3         4         5         6         7         8         9     
	*	         012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345
common1_tbl:	sp2a0	' METER:  /     KEY:        TEMPO:       PLAYTIME:  :  :  /  :  :            /  /  (   )   :  :',0
common2_tbl:	sp2a0	'AGOGIK:       WAVE:      VARIANT:         REPEAT:',0
common3_tbl:	sp2a0	'FMOPM:     ADPCM:     MIDI1:     MIDI2:     MIDI3:     MIDI4:     SYSTEM:Z-MUSIC\  .',0
common4_tbl:	sp2a0	'FADER:     FADER:     FADER:     FADER:     FADER:     FADER:     TIMER:                              ',0
track_tbl1:	sp2a0	'                       DEAD                                                         CH.FADER:',0
track_tbl2:	sp2a0	'                   VOLUME:    VELOCITY:    DETUNE:       PITCH:       AFTER:    HOLD:   \ PAN:',0
track_tbl3:	sp2a0	'ARCC1:     WAVE:      VARIANT:       CTRL:          VIBRATO:       WAVE:      VARIANT:',0
track_tbl4:	sp2a0	'ARCC2:     WAVE:      VARIANT:       CTRL:       VELOCITY.SEQ:     WAVE:      VARIANT:',0
track_tbl5:	sp2a0	'ARCC3:     WAVE:      VARIANT:       CTRL:',0
track_tbl6:	sp2a0	'ARCC4:     WAVE:      VARIANT:       CTRL:',0

FMttlg0:	dc.b	' CLK-A:     CLK-B:    R14:      ',0
FMttlg1:	dc.b	' NE:  NFRQ:                     ',0
FMttlg2:	dc.b	' WF:  LFRQ:    PMD:    AMD:     ',0
FMttl0:		dc.b	'     AL:  FB:  PMS:  AMS:  PAN: ',0
FMttl1:		dc.b	' AR DR SR RR SL  TL K ML D1 D2 A',0
FMchn:		dc.b	'FM ',0

x_zahyo:
	dc.b	0	*TR
	dc.b	3	*DEVICE
	dc.b	10	*PRG
	dc.b	14	*VOL
	dc.b	18	*VEL
	dc.b	22	*PAN
	dc.b	25	*DETNE
	dc.b	31	*P.MOD
	dc.b	37	*ARC
	dc.b	41	*A.BND
	dc.b	48	*AFT
	dc.b	51	*PRT
	dc.b	58	*FDO
	dc.b	62	*DP
	dc.b	65	*NT1
	dc.b	69	*NT2
	dc.b	73	*NT3
	dc.b	77	*NT4
	dc.b	81	*NT5
	dc.b	85	*NT6
	dc.b	89	*NT7
	dc.b	93	*NT8

ch_fm:		dc.b	'FMOPM    ',0
ch_ad:		dc.b	'ADPCM    ',0
ch_md:		dc.b	'MIDI0 -  ',0
ch_vanish:	dc.b	'         ',0

KEY_tbl:	dc.b	'Cmajor ',0
		dc.b	'Gmajor ',0
		dc.b	'Dmajor ',0
		dc.b	'Amajor ',0
		dc.b	'Emajor ',0
		dc.b	'Bmajor ',0
		dc.b	'F+major',0
		dc.b	'C+major',0
		dc.b	'Cmajor ',0
		dc.b	'Fmajor ',0
		dc.b	'B-major',0
		dc.b	'E-major',0
		dc.b	'A-major',0
		dc.b	'D-major',0
		dc.b	'G-major',0
		dc.b	'C-major',0
		dc.b	'Aminor ',0
		dc.b	'Eminor ',0
		dc.b	'Bminor ',0
		dc.b	'F+minor',0
		dc.b	'C+minor',0
		dc.b	'G+minor',0
		dc.b	'D+minor',0
		dc.b	'A+minor',0
		dc.b	'Aminor ',0
		dc.b	'Dminor ',0
		dc.b	'Gminor ',0
		dc.b	'Cminor ',0
		dc.b	'Fminor ',0
		dc.b	'B-minor',0
		dc.b	'E-minor',0
		dc.b	'A-minor',0
non_key:	dc.b	'-------',0

WAVE_tbl:	dc.b	'SAW  ',0,0,0
		dc.b	'SQR  ',0,0,0
		dc.b	'TRI  ',0,0,0
		dc.b	'S.SAW',0,0,0
		dc.b	'RND  ',0,0,0
DUMMY_wf:	dc.b	'NONE ',0,0,0

DAY_tbl:	dc.b	'SUN',0
		dc.b	'MON',0
		dc.b	'TUE',0
		dc.b	'WED',0
		dc.b	'THU',0
		dc.b	'FRI',0
		dc.b	'SAT',0

trkmd_PTRN:	dc.b	'PATTERN',0
trkmd_NORMAL:	dc.b	'ACTIVE ',0
trkmd_DEAD:	dc.b	'DEAD   ',0
trkmd_END:	dc.b	'END    ',0
trkmd_STOP:	dc.b	'STOP   ',0
trkmd_SYNC:	dc.b	'WAITING',0
trkmd_REC:	dc.b	'RECORD ',0
trkmd_SE:	dc.b	'EFFECT ',0
trkmd_MASK:	dc.b	'MASKED ',0
trkmd_Vanish:	dc.b	'       ',0

trim_vanish:	dc.b	'   ',0
timbre_bkspc:	dc.b	'      ',0
off_str:
aftc_off:	dc.b	'OFF',0
TIE_str:	dc.b	'*****',0
zsv_opt:	dc.b	'zsv_opt',0
zmsc3_fader:	dc.b	'zmsc3_fader',0
hlp_mes:	dc.b	'-I     Start with preserving the mask.',13,10
		dc.b	'-J     Messages will be displayed in Japanese.',13,10
		dc.b	'-P     Display the panpot value from L64-L1,0,R1-R64.',13,10
		dc.b	'-R     Display the modulation value in realtime.',13,10
		dc.b	0
		dc.b	'-I     マスクを保存して起動する',13,10
		dc.b	'-J     日本語メッセージ表示',13,10
		dc.b	'-P     パンポットをL64-1,0,R1-64の範囲で表示する',13,10
		dc.b	'-R     モジュレーションの値をリアルタイム表示する',13,10
		dc.b	0
arcc_op:	dc.b	'1',0
		dc.b	'2',0
		dc.b	'3',0
		dc.b	'4',0
fm_arcc_tbl:	dc.b	'PAN ',0
		dc.b	'PMS ',0
		dc.b	'AMS ',0
		dc.b	'??? ',0
		dc.b	'AMD ',0
		dc.b	'PMD ',0
		dc.b	'SPD ',0
		dc.b	'NSE ',0
Vanish_volvelo:	dc.b	'    ',0
Vanish_ctrl:	dc.b	'    ',0
DUMMY_ctrl:	dc.b	'NONE',0

Question_velo:	dc.b	'???',0
Vanish_nn:	dc.b	'                    '
Vanish_cmd:	dc.b	'                     ',0
Portament_nn:	dc.b	' PORTAMENT TO        ',0
Rest_nn:	dc.b	'REST',0
Rest_velo:	dc.b	'000',0
Dummy_gate	dc.b	'00000',0
Wait_nn:	dc.b	'WAIT',0
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

KEY_v_tbl:
	dc.b	0,0,1,0,2,0,3,0,4,0,5,0,6,0,7,0
	dc.b	0,0,-1,0,-2,0,-3,0,-4,0,-5,0,-6,0,-7,0
	dc.b	0,1,1,1,2,1,3,1,4,1,5,1,6,1,7,1
	dc.b	0,1,-1,1,-2,1,-3,1,-4,1,-5,1,-6,1,-7,1
	.even
		*1       2       3       4       
kbd_ptn1:	*12345678123456781234567812345678
	dc.l	%11100011000111011100011000110001
	dc.l	%11011100011000111011100011000110
	dc.l	%00111011100011000111011100011000
	dc.l	%11000111011100011000111011100011
	dc.l	%00011000111011100011000111011100
	dc.l	%01100011000111011100011000111011
	dc.l	%10001100011000111011100011000111
	dc.l	%01110001100011000111011100011000
	dc.l	%11101110001100011000111011100011
	dc.l	%00011101110001100011000111011100
	dc.l	%01100011101110001100011000111011
	dc.l	%10001100011101110001110000000000
kbd_ptn2:
	dc.l	%11110111101111011110111101111011
	dc.l	%11011110111101111011110111101111
	dc.l	%01111011110111101111011110111101
	dc.l	%11101111011110111101111011110111
	dc.l	%10111101111011110111101111011110
	dc.l	%11110111101111011110111101111011
	dc.l	%11011110111101111011110111101111
	dc.l	%01111011110111101111011110111101
	dc.l	%11101111011110111101111011110111
	dc.l	%10111101111011110111101111011110
	dc.l	%11110111101111011110111101111011
	dc.l	%11011110111101111011110000000000
*kbd_ptn3:
*	dc.l	%11100011000110001100011000110001
*	dc.l	%10001100011000110001100011000110
*	dc.l	%00110001100011000110001100011000
*	dc.l	%11000110001100011000110001100011
*	dc.l	%00011000110001100011000110001100
*	dc.l	%01100011000110001100011000110001
*	dc.l	%10001100011000110001100011000110
*	dc.l	%00110001100011000110001100011000
*	dc.l	%11000110001100011000110001100011
*	dc.l	%00011000110001100011000110001100
*	dc.l	%01100011000110001100011000110001
*	dc.l	%10001100011000110001110000000000
		  *1       2       
kon_ptn1:	   *1234567812345678
	dc.w	00,%1110000000000000	*C
	dc.w	00,%0001110000000000	*C#
	dc.w	00,%0000001100000000	*D
	dc.w	00,%0000000011100000	*D#
	dc.w	00,%0000000000011100	*E
	dc.w	01,%0000000111000000	*F
	dc.w	01,%0000000000111000	*F#
	dc.w	01,%0000000000000110	*G
	dc.w	02,%0000000111000000	*G#
	dc.w	02,%0000000000110000	*A
	dc.w	02,%0000000000001110	*A#
	dc.w	03,%0000000111000000	*B
	dc.w	03,%0000000000011100	*C
	dc.w	04,%0000001110000000	*C#
	dc.w	04,%0000000001100000	*D
	dc.w	04,%0000000000011100	*D#
	dc.w	05,%0000001110000000	*E
	dc.w	05,%0000000000111000	*F
	dc.w	05,%0000000000000111	*F#
	dc.w	07,%1100000000000000	*G
	dc.w	07,%0011100000000000	*G#
	dc.w	07,%0000011000000000	*A
	dc.w	07,%0000000111000000	*A#
	dc.w	07,%0000000000111000	*B
	dc.w	08,%0000001110000000	*C
	dc.w	08,%0000000001110000	*C#
	dc.w	08,%0000000000001100	*D
	dc.w	09,%0000001110000000	*D#
	dc.w	09,%0000000001110000	*E
	dc.w	09,%0000000000000111	*F
	dc.w	11,%1110000000000000	*F#
	dc.w	11,%0001100000000000	*G
	dc.w	11,%0000011100000000	*G#
	dc.w	11,%0000000011000000	*A
	dc.w	11,%0000000000111000	*A#
	dc.w	11,%0000000000000111	*B
	dc.w	13,%0111000000000000	*C
	dc.w	13,%0000111000000000	*C#
	dc.w	13,%0000000110000000	*D
	dc.w	13,%0000000001110000	*D#
	dc.w	13,%0000000000001110	*E
	dc.w	15,%1110000000000000	*F
	dc.w	15,%0001110000000000	*F#
	dc.w	15,%0000001100000000	*G
	dc.w	15,%0000000011100000	*G#
	dc.w	15,%0000000000011000	*A
	dc.w	15,%0000000000000111	*A#
	dc.w	17,%1110000000000000	*B
	dc.w	17,%0000111000000000	*C
	dc.w	17,%0000000111000000	*C#
	dc.w	17,%0000000000110000	*D
	dc.w	17,%0000000000001110	*D#
	dc.w	18,%0000000111000000	*E
	dc.w	18,%0000000000011100	*F
	dc.w	19,%0000001110000000	*F#
	dc.w	19,%0000000001100000	*G
	dc.w	19,%0000000000011100	*G#
	dc.w	19,%0000000000000011	*A
	dc.w	21,%1110000000000000	*A#
	dc.w	21,%0001110000000000	*B
	dc.w	21,%0000000111000000	*C
	dc.w	21,%0000000000111000	*C#
	dc.w	21,%0000000000000110	*D
	dc.w	22,%0000000111000000	*D#
	dc.w	22,%0000000000111000	*E
	dc.w	23,%0000001110000000	*F
	dc.w	23,%0000000001110000	*F#
	dc.w	23,%0000000000001100	*G
	dc.w	24,%0000001110000000	*G#
	dc.w	24,%0000000001100000	*A
	dc.w	24,%0000000000011100	*A#
	dc.w	25,%0000001110000000	*B
	dc.w	25,%0000000000111000	*C
	dc.w	25,%0000000000000111	*C#
	dc.w	27,%1100000000000000	*D
	dc.w	27,%0011100000000000	*D#
	dc.w	27,%0000011100000000	*E
	dc.w	27,%0000000001110000	*F
	dc.w	27,%0000000000001110	*F#
	dc.w	28,%0000000110000000	*G
	dc.w	28,%0000000001110000	*G#
	dc.w	28,%0000000000001100	*A
	dc.w	29,%0000001110000000	*A#
	dc.w	29,%0000000001110000	*B
	dc.w	29,%0000000000000111	*C
	dc.w	31,%1110000000000000	*C#
	dc.w	31,%0001100000000000	*D
	dc.w	31,%0000011100000000	*D#
	dc.w	31,%0000000011100000	*E
	dc.w	31,%0000000000001110	*F
	dc.w	32,%0000000111000000	*F#
	dc.w	32,%0000000000110000	*G
	dc.w	32,%0000000000001110	*G#
	dc.w	33,%0000000110000000	*A
	dc.w	33,%0000000001110000	*A#
	dc.w	33,%0000000000001110	*B
	dc.w	35,%1110000000000000	*C
	dc.w	35,%0001110000000000	*C#
	dc.w	35,%0000001100000000	*D
	dc.w	35,%0000000011100000	*D#
	dc.w	35,%0000000000011100	*E
	dc.w	36,%0000000111000000	*F
	dc.w	36,%0000000000111000	*F#
	dc.w	36,%0000000000000110	*G
	dc.w	37,%0000000111000000	*G#
	dc.w	37,%0000000000110000	*A
	dc.w	37,%0000000000001110	*A#
	dc.w	38,%0000000111000000	*B
	dc.w	38,%0000000000011100	*C
	dc.w	39,%0000001110000000	*C#
	dc.w	39,%0000000001100000	*D
	dc.w	39,%0000000000011100	*D#
	dc.w	40,%0000001110000000	*E
	dc.w	40,%0000000000111000	*F
	dc.w	40,%0000000000000111	*F#
	dc.w	42,%1100000000000000	*G
	dc.w	42,%0011100000000000	*G#
	dc.w	42,%0000011000000000	*A
	dc.w	42,%0000000111000000	*A#
	dc.w	42,%0000000000111000	*B
	dc.w	43,%0000001110000000	*C
	dc.w	43,%0000000001110000	*C#
	dc.w	43,%0000000000001100	*D
	dc.w	44,%0000001110000000	*D#
	dc.w	44,%0000000001110000	*E
	dc.w	44,%0000000000000111	*F
	dc.w	46,%1110000000000000	*F#
	dc.w	46,%0001110000000000	*G
kon_ptn2:
	*           1234567812345678
	dc.w	00,%1111000000000000	*C
	dc.w	-1,%0000000000000000	*C#
	dc.w	00,%0000011110000000	*D
	dc.w	-1,%0000000000000000	*D#
	dc.w	00,%0000000000111100	*E
	dc.w	01,%0000000111100000	*F
	dc.w	-1,%0000000000000000	*F#
	dc.w	01,%0000000000001111	*G
	dc.w	-1,%0000000000000000	*G#
	dc.w	03,%0111100000000000	*A
	dc.w	-1,%0000000000000000	*A#
	dc.w	03,%0000001111000000	*B
	dc.w	03,%0000000000011110	*C
	dc.w	-1,%0000000000000000	*C#
	dc.w	05,%1111000000000000	*D
	dc.w	-1,%0000000000000000	*D#
	dc.w	05,%0000011110000000	*E
	dc.w	05,%0000000000111100	*F
	dc.w	-1,%0000000000000000	*F#
	dc.w	06,%0000000111100000	*G
	dc.w	-1,%0000000000000000	*G#
	dc.w	06,%0000000000001111	*A
	dc.w	-1,%0000000000000000	*A#
	dc.w	08,%0111100000000000	*B
	dc.w	08,%0000001111000000	*C
	dc.w	-1,%0000000000000000	*C#
	dc.w	08,%0000000000011110	*D
	dc.w	-1,%0000000000000000	*D#
	dc.w	10,%1111000000000000	*E
	dc.w	10,%0000011110000000	*F
	dc.w	-1,%0000000000000000	*F#
	dc.w	10,%0000000000111100	*G
	dc.w	-1,%0000000000000000	*G#
	dc.w	11,%0000000111100000	*A
	dc.w	-1,%0000000000000000	*A#
	dc.w	11,%0000000000001111	*B
	dc.w	13,%0111100000000000	*C
	dc.w	-1,%0000000000000000	*C#
	dc.w	13,%0000001111000000	*D
	dc.w	-1,%0000000000000000	*D#
	dc.w	13,%0000000000011110	*E
	dc.w	15,%1111000000000000	*F
	dc.w	-1,%0000000000000000	*F#
	dc.w	15,%0000011110000000	*G
	dc.w	-1,%0000000000000000	*G#
	dc.w	15,%0000000000111100	*A
	dc.w	-1,%0000000000000000	*A#
	dc.w	16,%0000000111100000	*B
	dc.w	16,%0000000000001111	*C
	dc.w	-1,%0000000000000000	*C#
	dc.w	18,%0111100000000000	*D
	dc.w	-1,%0000000000000000	*D#
	dc.w	18,%0000001111000000	*E
	dc.w	18,%0000000000011110	*F
	dc.w	-1,%0000000000000000	*F#
	dc.w	20,%1111000000000000	*G
	dc.w	-1,%0000000000000000	*G#
	dc.w	20,%0000011110000000	*A
	dc.w	-1,%0000000000000000	*A#
	dc.w	20,%0000000000111100	*B
	dc.w	21,%0000000111100000	*C
	dc.w	-1,%0000000000000000	*C#
	dc.w	21,%0000000000001111	*D
	dc.w	-1,%0000000000000000	*D#
	dc.w	23,%0111100000000000	*E
	dc.w	23,%0000001111000000	*F
	dc.w	-1,%0000000000000000	*F#
	dc.w	23,%0000000000011110	*G
	dc.w	-1,%0000000000000000	*G#
	dc.w	25,%1111000000000000	*A
	dc.w	-1,%0000000000000000	*A#
	dc.w	25,%0000011110000000	*B
	dc.w	25,%0000000000111100	*C
	dc.w	-1,%0000000000000000	*C#
	dc.w	26,%0000000111100000	*D
	dc.w	-1,%0000000000000000	*D#
	dc.w	26,%0000000000001111	*E
	dc.w	28,%0111100000000000	*F
	dc.w	-1,%0000000000000000	*F#
	dc.w	28,%0000001111000000	*G
	dc.w	-1,%0000000000000000	*G#
	dc.w	28,%0000000000011110	*A
	dc.w	-1,%0000000000000000	*A#
	dc.w	30,%1111000000000000	*B
	dc.w	30,%0000011110000000	*C
	dc.w	-1,%0000000000000000	*C#
	dc.w	30,%0000000000111100	*D
	dc.w	-1,%0000000000000000	*D#
	dc.w	31,%0000000111100000	*E
	dc.w	31,%0000000000001111	*F
	dc.w	-1,%0000000000000000	*F#
	dc.w	33,%0111100000000000	*G
	dc.w	-1,%0000000000000000	*G#
	dc.w	33,%0000001111000000	*A
	dc.w	-1,%0000000000000000	*A#
	dc.w	33,%0000000000011110	*B
	dc.w	35,%1111000000000000	*C
	dc.w	-1,%0000000000000000	*C#
	dc.w	35,%0000011110000000	*D
	dc.w	-1,%0000000000000000	*D#
	dc.w	35,%0000000000111100	*E
	dc.w	36,%0000000111100000	*F
	dc.w	-1,%0000000000000000	*F#
	dc.w	36,%0000000000001111	*G
	dc.w	-1,%0000000000000000	*G#
	dc.w	38,%0111100000000000	*A
	dc.w	-1,%0000000000000000	*A#
	dc.w	38,%0000001111000000	*B
	dc.w	38,%0000000000011110	*C
	dc.w	-1,%0000000000000000	*C#
	dc.w	40,%1111000000000000	*D
	dc.w	-1,%0000000000000000	*D#
	dc.w	40,%0000011110000000	*E
	dc.w	40,%0000000000111100	*F
	dc.w	-1,%0000000000000000	*F#
	dc.w	41,%0000000111100000	*G
	dc.w	-1,%0000000000000000	*G#
	dc.w	41,%0000000000001111	*A
	dc.w	-1,%0000000000000000	*A#
	dc.w	43,%0111100000000000	*B
	dc.w	43,%0000001111000000	*C
	dc.w	-1,%0000000000000000	*C#
	dc.w	43,%0000000000011110	*D
	dc.w	-1,%0000000000000000	*D#
	dc.w	45,%1111000000000000	*E
	dc.w	45,%0000011110000000	*F
	dc.w	-1,%0000000000000000	*F#
	dc.w	45,%0000000000111100	*G

lamp_pat:
	dc.b	%00000000
	dc.b	%00011000
	dc.b	%00111100
	dc.b	%01111110
	dc.b	%01111110
	dc.b	%00111100
	dc.b	%00011000
	dc.b	%00000000

hbar_data:
	dc.l	%00000000000000000000000000000000
	dc.l	%10000000000000000000000000000000
	dc.l	%11000000000000000000000000000000
	dc.l	%11100000000000000000000000000000
	dc.l	%11110000000000000000000000000000
	dc.l	%11111000000000000000000000000000
	dc.l	%11111100000000000000000000000000
	dc.l	%11111110000000000000000000000000
	dc.l	%11111111000000000000000000000000
	dc.l	%11111111100000000000000000000000
	dc.l	%11111111110000000000000000000000
	dc.l	%11111111111000000000000000000000
	dc.l	%11111111111100000000000000000000
	dc.l	%11111111111110000000000000000000
	dc.l	%11111111111111000000000000000000
	dc.l	%11111111111111100000000000000000
	dc.l	%11111111111111110000000000000000
	dc.l	%11111111111111111000000000000000
	dc.l	%11111111111111111100000000000000
	dc.l	%11111111111111111110000000000000
	dc.l	%11111111111111111111000000000000
	dc.l	%11111111111111111111100000000000
	dc.l	%11111111111111111111110000000000
	dc.l	%11111111111111111111111000000000
	dc.l	%11111111111111111111111100000000
	dc.l	%11111111111111111111111110000000
	dc.l	%11111111111111111111111111000000
	dc.l	%11111111111111111111111111100000
	dc.l	%11111111111111111111111111110000
	dc.l	%11111111111111111111111111111000
	dc.l	%11111111111111111111111111111100
	dc.l	%11111111111111111111111111111110
	dc.l	%11111111111111111111111111111111

std_palet:
	dc.w	%00000_00000_00000_0	*テキストパレットの設定%0000	*black
	dc.w	%01111_00000_00100_0	*テキストパレットの設定%0001	*dark kon
	dc.w	%11100_11000_11100_1	*テキストパレットの設定%0010	*trkprm'
	dc.w	%11100_11100_11100_1	*テキストパレットの設定%0011	*white char
	dc.w	%11111_00000_01000_0	*テキストパレットの設定%0100	*key on
	dc.w	%11000_11111_00000_1	*テキストパレットの設定%0101	*trim'
	dc.w	%11111_00000_10100_0	*テキストパレットの設定%0110	*key on
	dc.w	%11111_00000_10100_1	*テキストパレットの設定%0111	*key on
	dc.w	%10000_10000_10000_1	*テキストパレットの設定%1000	*mix scale
	dc.w	%00000_11111_00000_1	*テキストパレットの設定%1001	*red
	dc.w	%01111_01111_01111_0	*テキストパレットの設定%1010	*dark
	dc.w	%01111_00000_01010_0	*テキストパレットの設定%1011	*dark kon
	dc.w	%11111_11111_00000_1	*テキストパレットの設定%1100	*yellow
	dc.w	%11000_11111_00000_1	*テキストパレットの設定%1101	*trim
	dc.w	%11111_00000_11111_1	*テキストパレットの設定%1110	*cyan
	dc.w	%01111_01111_01111_0	*テキストパレットの設定%1111	*flash

pantrim0:
	.dc.b	$00,$00,$03,$c0,$0c,$30,$10,$08,$20,$04,$20,$04,$40,$02,$40,$02
	.dc.b	$40,$02,$40,$02,$20,$04,$20,$04,$10,$08,$0c,$30,$03,$c0,$00,$00
pantrim_tbl:
	.dc.b	$00,$00,$03,$c0,$0c,$30,$10,$08,$20,$04,$20,$04,$40,$02,$40,$02
	.dc.b	$40,$02,$40,$02,$2c,$04,$3c,$04,$18,$08,$0c,$30,$03,$c0,$00,$00
	.dc.b	$00,$00,$03,$c0,$0c,$30,$10,$08,$20,$04,$20,$04,$40,$02,$40,$02
	.dc.b	$40,$02,$48,$02,$38,$04,$30,$04,$10,$08,$0c,$30,$03,$c0,$00,$00
	.dc.b	$00,$00,$03,$c0,$0c,$30,$10,$08,$20,$04,$20,$04,$40,$02,$40,$02
	.dc.b	$48,$02,$78,$02,$30,$04,$20,$04,$10,$08,$0c,$30,$03,$c0,$00,$00
	.dc.b	$00,$00,$03,$c0,$0c,$30,$10,$08,$20,$04,$20,$04,$40,$02,$78,$02
	.dc.b	$78,$02,$40,$02,$20,$04,$20,$04,$10,$08,$0c,$30,$03,$c0,$00,$00
	.dc.b	$00,$00,$03,$c0,$0c,$30,$10,$08,$20,$04,$30,$04,$78,$02,$48,$02
	.dc.b	$40,$02,$40,$02,$20,$04,$20,$04,$10,$08,$0c,$30,$03,$c0,$00,$00
	.dc.b	$00,$00,$03,$c0,$0c,$30,$10,$08,$30,$04,$38,$04,$48,$02,$40,$02
	.dc.b	$40,$02,$40,$02,$20,$04,$20,$04,$10,$08,$0c,$30,$03,$c0,$00,$00
	.dc.b	$00,$00,$03,$c0,$0c,$30,$18,$08,$3c,$04,$2c,$04,$40,$02,$40,$02
	.dc.b	$40,$02,$40,$02,$20,$04,$20,$04,$10,$08,$0c,$30,$03,$c0,$00,$00
	.dc.b	$00,$00,$03,$c0,$0c,$30,$1c,$08,$26,$04,$20,$04,$40,$02,$40,$02
	.dc.b	$40,$02,$40,$02,$20,$04,$20,$04,$10,$08,$0c,$30,$03,$c0,$00,$00
	.dc.b	$00,$00,$03,$c0,$0e,$30,$16,$08,$23,$04,$20,$04,$40,$02,$40,$02
	.dc.b	$40,$02,$40,$02,$20,$04,$20,$04,$10,$08,$0c,$30,$03,$c0,$00,$00
	.dc.b	$00,$00,$03,$c0,$0d,$b0,$11,$88,$21,$84,$20,$04,$40,$02,$40,$02
	.dc.b	$40,$02,$40,$02,$20,$04,$20,$04,$10,$08,$0c,$30,$03,$c0,$00,$00
	.dc.b	$00,$00,$03,$c0,$0c,$70,$10,$68,$20,$c4,$20,$04,$40,$02,$40,$02
	.dc.b	$40,$02,$40,$02,$20,$04,$20,$04,$10,$08,$0c,$30,$03,$c0,$00,$00
	.dc.b	$00,$00,$03,$c0,$0c,$30,$10,$38,$20,$64,$20,$04,$40,$02,$40,$02
	.dc.b	$40,$02,$40,$02,$20,$04,$20,$04,$10,$08,$0c,$30,$03,$c0,$00,$00
	.dc.b	$00,$00,$03,$c0,$0c,$30,$10,$18,$20,$3c,$20,$34,$40,$02,$40,$02
	.dc.b	$40,$02,$40,$02,$20,$04,$20,$04,$10,$08,$0c,$30,$03,$c0,$00,$00
	.dc.b	$00,$00,$03,$c0,$0c,$30,$10,$08,$20,$0c,$20,$1c,$40,$12,$40,$02
	.dc.b	$40,$02,$40,$02,$20,$04,$20,$04,$10,$08,$0c,$30,$03,$c0,$00,$00
	.dc.b	$00,$00,$03,$c0,$0c,$30,$10,$08,$20,$04,$20,$0c,$40,$1e,$40,$12
	.dc.b	$40,$02,$40,$02,$20,$04,$20,$04,$10,$08,$0c,$30,$03,$c0,$00,$00
	.dc.b	$00,$00,$03,$c0,$0c,$30,$10,$08,$20,$04,$20,$04,$40,$02,$40,$1e
	.dc.b	$40,$1e,$40,$02,$20,$04,$20,$04,$10,$08,$0c,$30,$03,$c0,$00,$00
	.dc.b	$00,$00,$03,$c0,$0c,$30,$10,$08,$20,$04,$20,$04,$40,$02,$40,$02
	.dc.b	$40,$12,$40,$1e,$20,$0c,$20,$04,$10,$08,$0c,$30,$03,$c0,$00,$00
	.dc.b	$00,$00,$03,$c0,$0c,$30,$10,$08,$20,$04,$20,$04,$40,$02,$40,$02
	.dc.b	$40,$02,$40,$12,$20,$1c,$20,$0c,$10,$08,$0c,$30,$03,$c0,$00,$00
	.dc.b	$00,$00,$03,$c0,$0c,$30,$10,$08,$20,$04,$20,$04,$40,$02,$40,$02
	.dc.b	$40,$02,$40,$02,$20,$34,$20,$3c,$10,$18,$0c,$30,$03,$c0,$00,$00
logo_z:	.dc.b	$00,$00,$3f,$fe,$3f,$fc,$00,$78,$00,$f0,$01,$e0,$03,$c0,$07,$80
	.dc.b	$0f,$00,$1f,$fe,$3f,$fe,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
logo_s:	.dc.b	$00,$00,$7f,$fe,$7f,$fe,$70,$00,$70,$00,$7f,$fe,$7f,$fe,$00,$0e
	.dc.b	$00,$0e,$7f,$fe,$7f,$fe,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
logo_v:	.dc.b	$00,$00,$38,$1e,$38,$3c,$38,$78,$38,$f0,$39,$e0,$3b,$c0,$3f,$80
	.dc.b	$3f,$00,$3e,$00,$3c,$00,$38,$00,$30,$00,$00,$00,$00,$00,$00,$00

font_data:
	.dc.b	$00,$00,$00,$00,$00,$00,$00,$00,$e0,$80,$ea,$2a,$ee,$0a,$0a,$00
	.dc.b	$e0,$80,$ea,$2a,$e4,$0a,$0a,$00,$e0,$80,$ea,$8a,$e4,$0a,$0a,$00
	.dc.b	$e0,$80,$ee,$84,$e4,$04,$04,$00,$e0,$80,$ec,$92,$f2,$14,$0a,$00
	.dc.b	$40,$a0,$ea,$aa,$ac,$0a,$0a,$00,$c0,$a0,$c8,$a8,$c8,$08,$0e,$00
	.dc.b	$c0,$a0,$ce,$a8,$ce,$02,$0e,$00,$a0,$a0,$ee,$a4,$a4,$04,$04,$00
	.dc.b	$80,$80,$8e,$88,$ee,$08,$08,$00,$a0,$a0,$ae,$a4,$44,$04,$04,$00
	.dc.b	$e0,$80,$ee,$88,$8e,$08,$08,$00,$e0,$80,$8e,$8a,$ee,$0c,$0a,$00
	.dc.b	$e0,$80,$ee,$2a,$ea,$0a,$0e,$00,$e0,$80,$ee,$24,$e4,$04,$0e,$00
	.dc.b	$c0,$a0,$ae,$a8,$ce,$08,$0e,$00,$c0,$a0,$a4,$ac,$c4,$04,$0e,$00
	.dc.b	$c0,$a0,$ac,$a2,$c4,$08,$0e,$00,$c0,$a0,$ac,$a2,$c4,$02,$0c,$00
	.dc.b	$c0,$a0,$a6,$aa,$ca,$0e,$02,$00,$90,$d0,$ba,$9a,$9c,$0a,$0a,$00
	.dc.b	$e0,$80,$f2,$3a,$f6,$12,$12,$00,$e0,$80,$ec,$8a,$ec,$0a,$0c,$00
	.dc.b	$e0,$80,$92,$9a,$f6,$12,$12,$00,$e0,$80,$f2,$9e,$fe,$12,$12,$00
	.dc.b	$e0,$80,$ec,$2a,$ec,$0a,$0c,$00,$e0,$80,$ee,$88,$e8,$08,$0e,$00
	.dc.b	$00,$08,$04,$fe,$04,$08,$00,$00,$00,$20,$40,$fe,$40,$20,$00,$00
	.dc.b	$10,$38,$54,$10,$10,$10,$10,$00,$10,$10,$10,$10,$54,$38,$10,$00
	.dc.b	$00,$00,$00,$00,$00,$00,$00,$00,$10,$10,$10,$10,$10,$00,$10,$00
	.dc.b	$28,$28,$28,$00,$00,$00,$00,$00,$24,$24,$7e,$24,$7e,$24,$24,$00
	.dc.b	$10,$3c,$50,$38,$14,$78,$10,$00,$00,$62,$64,$08,$10,$26,$46,$00
	.dc.b	$30,$48,$48,$30,$4a,$44,$3a,$00,$30,$10,$20,$00,$00,$00,$00,$00
	.dc.b	$08,$10,$20,$20,$20,$10,$08,$00,$20,$10,$08,$08,$08,$10,$20,$00
	.dc.b	$10,$54,$38,$7c,$38,$54,$10,$00,$00,$10,$10,$7c,$10,$10,$00,$00
	.dc.b	$00,$00,$00,$00,$30,$10,$20,$00,$00,$00,$00,$7c,$00,$00,$00,$00
	.dc.b	$00,$00,$00,$00,$30,$30,$00,$00,$00,$02,$04,$08,$10,$20,$40,$00
	.dc.b	$3c,$42,$46,$5a,$62,$42,$3c,$00,$10,$30,$50,$10,$10,$10,$7c,$00
	.dc.b	$3c,$42,$02,$0c,$30,$40,$7e,$00,$3c,$42,$02,$3c,$02,$42,$3c,$00
	.dc.b	$04,$0c,$14,$24,$7e,$04,$04,$00,$7e,$40,$78,$04,$02,$44,$38,$00
	.dc.b	$1c,$20,$40,$7c,$42,$42,$3c,$00,$7e,$42,$04,$08,$10,$10,$10,$00
	.dc.b	$3c,$42,$42,$3c,$42,$42,$3c,$00,$3c,$42,$42,$3e,$02,$04,$38,$00
	.dc.b	$00,$30,$30,$00,$30,$30,$00,$00,$00,$30,$30,$00,$30,$10,$20,$00
	.dc.b	$0e,$18,$30,$60,$30,$18,$0e,$00,$00,$00,$7e,$00,$7e,$00,$00,$00
	.dc.b	$70,$18,$0c,$06,$0c,$18,$70,$00,$3c,$42,$02,$0c,$10,$00,$10,$00
	.dc.b	$1c,$22,$4a,$56,$4c,$20,$1e,$00,$18,$24,$42,$7e,$42,$42,$42,$00
	.dc.b	$7c,$42,$42,$7c,$42,$42,$7c,$00,$1c,$22,$40,$40,$40,$22,$1c,$00
	.dc.b	$78,$24,$22,$22,$22,$24,$78,$00,$7e,$40,$40,$78,$40,$40,$7e,$00
	.dc.b	$7e,$40,$40,$78,$40,$40,$40,$00,$1c,$22,$40,$4e,$42,$22,$1c,$00
	.dc.b	$42,$42,$42,$7e,$42,$42,$42,$00,$38,$10,$10,$10,$10,$10,$38,$00
	.dc.b	$0e,$04,$04,$04,$04,$44,$38,$00,$42,$44,$48,$70,$48,$44,$42,$00
	.dc.b	$40,$40,$40,$40,$40,$40,$7e,$00,$42,$66,$5a,$5a,$42,$42,$42,$00
	.dc.b	$42,$62,$52,$4a,$46,$42,$42,$00,$18,$24,$42,$42,$42,$24,$18,$00
	.dc.b	$7c,$42,$42,$7c,$40,$40,$40,$00,$18,$24,$42,$42,$4a,$24,$1a,$00
	.dc.b	$7c,$42,$42,$7c,$48,$44,$42,$00,$3c,$42,$40,$3c,$02,$42,$3c,$00
	.dc.b	$7c,$10,$10,$10,$10,$10,$10,$00,$42,$42,$42,$42,$42,$42,$3c,$00
	.dc.b	$42,$42,$42,$24,$24,$18,$18,$00,$42,$42,$42,$5a,$5a,$66,$42,$00
	.dc.b	$42,$42,$24,$18,$24,$42,$42,$00,$44,$44,$44,$38,$10,$10,$10,$00
	.dc.b	$7e,$02,$04,$18,$20,$40,$7e,$00,$3c,$20,$20,$20,$20,$20,$3c,$00
	.dc.b	$44,$28,$7c,$10,$7c,$10,$10,$00,$78,$08,$08,$08,$08,$08,$78,$00
	.dc.b	$10,$28,$44,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$7e,$00
	.dc.b	$20,$10,$08,$00,$00,$00,$00,$00,$00,$00,$3c,$04,$3c,$44,$3a,$00
	.dc.b	$40,$40,$5c,$62,$42,$62,$5c,$00,$00,$00,$3c,$42,$40,$42,$3c,$00
	.dc.b	$02,$02,$3a,$46,$42,$46,$3a,$00,$00,$00,$3c,$42,$7e,$40,$3c,$00
	.dc.b	$0c,$10,$10,$7c,$10,$10,$10,$00,$00,$00,$3a,$46,$46,$3a,$02,$3c
	.dc.b	$40,$40,$5c,$62,$42,$42,$42,$00,$10,$00,$30,$10,$10,$10,$38,$00
	.dc.b	$04,$00,$0c,$04,$04,$04,$44,$38,$40,$40,$44,$48,$50,$68,$44,$00
	.dc.b	$30,$10,$10,$10,$10,$10,$38,$00,$00,$00,$ec,$92,$92,$92,$92,$00
	.dc.b	$00,$00,$5c,$62,$42,$42,$42,$00,$00,$00,$3c,$42,$42,$42,$3c,$00
	.dc.b	$00,$00,$5c,$62,$62,$5c,$40,$40,$00,$00,$3a,$46,$46,$3a,$02,$02
	.dc.b	$00,$00,$5c,$62,$40,$40,$40,$00,$00,$00,$3e,$40,$3c,$02,$7c,$00
	.dc.b	$10,$10,$7c,$10,$10,$12,$0c,$00,$00,$00,$42,$42,$42,$46,$3a,$00
	.dc.b	$00,$00,$42,$42,$42,$24,$18,$00,$00,$00,$82,$92,$92,$92,$6c,$00
	.dc.b	$00,$00,$42,$24,$18,$24,$42,$00,$00,$00,$42,$42,$46,$3a,$02,$3c
	.dc.b	$00,$00,$7e,$04,$18,$20,$7e,$00,$18,$20,$20,$40,$20,$20,$18,$00
	.dc.b	$18,$18,$18,$18,$18,$18,$18,$00,$30,$08,$08,$04,$08,$08,$30,$00
	.dc.b	$00,$7e,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.dc.b	$80,$40,$20,$10,$08,$04,$02,$00,$60,$92,$0c,$00,$00,$00,$00,$00
	.dc.b	$10,$10,$10,$00,$10,$10,$10,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.dc.b	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.dc.b	$10,$78,$26,$38,$14,$20,$1e,$00,$00,$10,$3c,$10,$3c,$5a,$32,$00
	.dc.b	$00,$00,$00,$44,$42,$52,$20,$00,$00,$18,$00,$38,$04,$04,$18,$00
	.dc.b	$00,$18,$00,$3c,$08,$18,$26,$00,$00,$10,$3a,$11,$3c,$52,$22,$00
	.dc.b	$00,$00,$24,$28,$7c,$22,$24,$00,$00,$08,$5c,$6a,$4a,$5c,$08,$00
	.dc.b	$00,$00,$08,$0c,$08,$3c,$3a,$00,$00,$00,$00,$3c,$02,$02,$0c,$00
	.dc.b	$00,$00,$00,$00,$00,$00,$00,$00,$10,$3c,$10,$3e,$55,$59,$32,$00
	.dc.b	$00,$20,$42,$41,$41,$51,$20,$00,$18,$00,$3c,$02,$02,$04,$18,$00
	.dc.b	$18,$00,$3c,$08,$10,$28,$46,$00,$10,$3a,$11,$1e,$31,$51,$22,$00
	.dc.b	$20,$22,$79,$25,$24,$24,$4c,$00,$10,$3c,$08,$7e,$04,$40,$3c,$00
	.dc.b	$0c,$08,$10,$20,$10,$08,$0c,$00,$04,$5e,$44,$44,$44,$64,$08,$00
	.dc.b	$3c,$04,$00,$00,$00,$40,$3e,$00,$10,$3c,$08,$04,$40,$40,$3c,$00
	.dc.b	$20,$20,$20,$22,$22,$24,$18,$00,$04,$7e,$0c,$14,$1c,$04,$08,$00
	.dc.b	$04,$24,$7e,$24,$2c,$20,$1c,$00,$28,$10,$26,$78,$10,$10,$0c,$00
	.dc.b	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$38,$28,$38,$00
	.dc.b	$38,$20,$20,$00,$00,$00,$00,$00,$00,$00,$00,$00,$08,$08,$38,$00
	.dc.b	$00,$00,$00,$00,$20,$10,$08,$00,$00,$00,$30,$30,$00,$00,$00,$00
	.dc.b	$00,$7c,$04,$7c,$04,$08,$10,$00,$00,$00,$7c,$04,$18,$10,$20,$00
	.dc.b	$00,$00,$08,$10,$30,$50,$10,$00,$00,$00,$10,$7c,$44,$04,$18,$00
	.dc.b	$00,$00,$00,$7c,$10,$10,$7c,$00,$00,$00,$08,$7c,$18,$28,$48,$00
	.dc.b	$00,$00,$20,$7c,$24,$28,$20,$00,$00,$00,$00,$38,$08,$08,$7c,$00
	.dc.b	$00,$00,$78,$08,$78,$08,$78,$00,$00,$00,$00,$54,$54,$04,$1c,$00
	.dc.b	$00,$00,$00,$7c,$00,$00,$00,$00,$7c,$04,$14,$18,$10,$10,$20,$00
	.dc.b	$04,$08,$10,$30,$50,$10,$10,$00,$10,$7c,$44,$44,$04,$08,$10,$00
	.dc.b	$00,$7c,$10,$10,$10,$10,$7c,$00,$08,$7c,$08,$18,$28,$48,$08,$00
	.dc.b	$20,$7c,$24,$24,$24,$24,$48,$00,$10,$7c,$10,$7c,$10,$10,$10,$00
	.dc.b	$00,$3c,$24,$44,$04,$08,$30,$00,$20,$3c,$48,$08,$08,$08,$10,$00
	.dc.b	$00,$7c,$04,$04,$04,$04,$7c,$00,$28,$7c,$28,$28,$08,$10,$20,$00
	.dc.b	$00,$60,$04,$64,$04,$08,$70,$00,$00,$7c,$04,$08,$10,$28,$44,$00
	.dc.b	$20,$7c,$24,$28,$20,$20,$1c,$00,$00,$44,$44,$24,$04,$08,$30,$00
	.dc.b	$00,$3c,$24,$54,$0c,$08,$30,$00,$08,$70,$10,$7c,$10,$10,$20,$00
	.dc.b	$00,$54,$54,$54,$04,$08,$10,$00,$38,$00,$7c,$10,$10,$10,$20,$00
	.dc.b	$20,$20,$20,$30,$28,$20,$20,$00,$10,$10,$7c,$10,$10,$20,$40,$00
	.dc.b	$00,$00,$38,$00,$00,$00,$7c,$00,$00,$7c,$04,$28,$10,$28,$40,$00
	.dc.b	$10,$7c,$08,$10,$38,$54,$10,$00,$08,$08,$08,$08,$08,$10,$20,$00
	.dc.b	$00,$10,$08,$44,$44,$44,$44,$00,$40,$40,$7c,$40,$40,$40,$7c,$00
	.dc.b	$00,$7c,$04,$04,$04,$08,$30,$00,$00,$20,$50,$08,$04,$04,$00,$00
	.dc.b	$10,$7c,$10,$10,$54,$54,$10,$00,$00,$7c,$04,$04,$28,$10,$08,$00
	.dc.b	$00,$38,$00,$38,$00,$78,$04,$00,$00,$10,$20,$40,$44,$7c,$04,$00
	.dc.b	$00,$04,$04,$28,$10,$28,$40,$00,$00,$7c,$20,$7c,$20,$20,$1c,$00
	.dc.b	$20,$20,$7c,$24,$28,$20,$20,$00,$00,$38,$08,$08,$08,$08,$7c,$00
	.dc.b	$00,$7c,$04,$7c,$04,$04,$7c,$00,$38,$00,$7c,$04,$04,$08,$10,$00
	.dc.b	$24,$24,$24,$24,$24,$08,$10,$00,$00,$10,$50,$50,$54,$54,$58,$00
	.dc.b	$00,$40,$40,$44,$48,$50,$60,$00,$00,$7c,$44,$44,$44,$44,$7c,$00
	.dc.b	$00,$7c,$44,$44,$04,$08,$10,$00,$00,$60,$00,$04,$04,$08,$70,$00
	.dc.b	$10,$48,$20,$00,$00,$00,$00,$00,$38,$28,$38,$00,$00,$00,$00,$00
	.dc.b	$10,$7e,$10,$17,$20,$28,$47,$00,$08,$3c,$10,$3e,$41,$01,$0e,$00
	.dc.b	$00,$7e,$01,$01,$01,$02,$0c,$00,$00,$7f,$04,$08,$10,$10,$0e,$00
	.dc.b	$10,$10,$16,$18,$20,$40,$3e,$00,$10,$7a,$21,$44,$04,$1e,$1d,$00
	.dc.b	$20,$4f,$40,$40,$40,$50,$4f,$00,$04,$04,$5e,$29,$51,$53,$23,$00
	.dc.b	$10,$10,$76,$19,$31,$33,$53,$00,$00,$1e,$29,$49,$51,$51,$22,$00
	.dc.b	$04,$5e,$44,$44,$44,$5e,$1d,$00,$04,$76,$25,$44,$44,$44,$38,$00
	.dc.b	$10,$08,$10,$08,$25,$45,$18,$00,$00,$10,$28,$44,$03,$01,$00,$00
	.dc.b	$1e,$44,$5e,$44,$44,$5e,$1d,$00,$08,$7e,$08,$3e,$08,$7c,$7a,$00
	.dc.b	$70,$12,$12,$3f,$52,$52,$24,$00,$20,$72,$21,$60,$62,$22,$1c,$00
	.dc.b	$04,$04,$5e,$29,$51,$51,$22,$00,$08,$78,$10,$79,$21,$21,$1e,$00
	.dc.b	$24,$28,$7e,$21,$21,$26,$20,$00,$08,$5e,$69,$49,$49,$5e,$08,$00
	.dc.b	$08,$0e,$08,$08,$3c,$4a,$30,$00,$10,$08,$40,$5e,$61,$01,$0e,$00
	.dc.b	$04,$22,$22,$22,$32,$04,$08,$00,$3c,$08,$10,$3e,$41,$19,$1e,$00
	.dc.b	$20,$26,$6a,$32,$22,$62,$23,$00,$3c,$08,$10,$3e,$41,$01,$1e,$00
	.dc.b	$20,$20,$6e,$31,$21,$61,$22,$00,$08,$08,$10,$10,$38,$25,$46,$00
	.dc.b	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.even
	.bss
suji:		ds.b	20	*一応かならず偶数番地から
k_or_p:		ds.b	1
mpcm_flg:	ds.b	1
no_chk:		ds.b	1
f_wait:		ds.b	1
last_note_buf:	ds.b	16+1
_fader_flag:	ds.b	1	*d7=master fader,d6=ch fader
string:		ds.b	96
filename:	ds.b	96
__opn_fn:	ds.b	100
	.even
trk_seq_tbl:		ds.b	100
_seq_wk_tbl:		ds.l	1	*!
_play_trk_tbl:		ds.l	1	*!
_common_buffer:		ds.l	1	*!
_zmusic_stat:		ds.l	1	*!
_meter:			ds.l	1	*!
env_bak:	ds.l	1	*環境変数格納アドレス
_wk_size:	ds.w	1
zm_ver:		ds.w	1	*Version
_cf:		ds.l	1
panpot_val:	ds.w	1	*パンポット計算結果格納ワーク
volume_val:	ds.w	1	*音量計算結果格納ワーク
bank_ofs:	ds.w	1
trkwkadr_adr:	ds.l	1
timbre_ofs:	ds.w	1
pan_ofs:	ds.w	1
vol_ofs:	ds.w	1
velo_ofs:	ds.w	1
mstrfdr_ofs:	ds.w	if_max+2
palet_tbl:	ds.w	3	*0:char,2:odd or even,4:KON
plane:		ds.l	1	*鍵盤書き込みプレーン
base_tadr:	ds.l	1
fopen_name:	ds.l	1
open_fn:	ds.l	1
font_addr:	ds.l	1	*フォントアドレス
ssp:		ds.l	1
global_data:	ds.b	100
opm_data:	ds.b	opm_data_size
track_data:	ds.b	dtsz*10
data_end:
		ds.b	4096
mysp:
end_of_prog:
