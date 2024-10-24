*-------------------------------------------------------
*		 Z-MUSIC.X演奏制御プログラム
*
*		    ＺＰ.Ｒ Version 3.0
*
*		PROGRAMMED  BY  Z.NISHIKAWA
*
*-------------------------------------------------------
	.include	iocscall.mac
	.include	doscall.mac
	.include	LzzConst.mac
	.include	zmd.mac
	.include	zmcall.mac
	.include	zmid.mac
	.include	z_global.mac
	.include	label.mac
	.include	version.mac

DO_NOT_DEFINE_WORK_LABEL: .equ 1
	.offset	0
	.include	zm_stat.mac

	.offset		0
	.include	common.mac
	.text
	.list
	.lall
max_p:		equ	128	*juke boxで演奏出来る最大曲数
fn_size:	equ	92	*１ファイルネームバッファの大きさ
setup1:		equ	fn_size*0
setup2:		equ	fn_size*1
setup3:		equ	fn_size*2
setup4:		equ	fn_size*3

Z_MUSIC	macro	func		*ドライバへのファンクションコール
	moveq.l	func,d0
	trap	#3
	endm

bitsns	macro	n		*IOCS	_BITSNSと同等に機能する
	move.b	$800+n.w,d0
	endm

sftsns	macro	dreg
	move.w	$810.w,dreg
	endm

top:
	bra	program_start
version_id:	ds.b	8	*バージョン情報格納エリア
				*常駐部分
start:
int_entry_j:				*割り込みエントリーその１(JUKE BOX)
*reglist	reg	d0-d5/a0-a3/a5-a6
reglist	reg	d0-d7/a0-a6
	movem.l	reglist,-(sp)
	lea	zp_work(pc),a6
	subq.w	#1,blank_count-zp_work(a6)	*ブランクタイム処理
	bcs	@f
	bne	quit_int_j
@@:
	move.w	#1,blank_count-zp_work(a6)

	btst.b	#3,$e84080
	bne	quit_int_j		*DMAが活動中は何も処理をしない(念のため)
	cmpi.b	#-1,music_no-zp_work(a6)
	beq	quit_int_j		*なにも演奏するものがない

	tas.b	_int_flag-zp_work(a6)
	bne	quit_int_j

	tst.b	hajimete-zp_work(a6)
	bmi	chk_next

	lea	key_tbl_jk(pc),a0
	lea	$800.w,a1

	bsr	key_inp			*[shift]+[opt1]
	beq	@f
	bsr	jk_im_next
	bra	chk_next
@@:
	clr.b	sft_opt1-zp_work(a6)

	bsr	key_inp			*[shift]+[opt2]
	beq	@f
	bsr	jk_fo_next
	bra	chk_next
@@:
	clr.b	sft_opt2-zp_work(a6)

	bsr	key_inp			*[shift]+[ctrl]
	beq	@f
	bsr	jk_stop_cont
	bra	chk_next
@@:
	clr.b	sft_ctrl-zp_work(a6)

	bsr	key_inp			*[shift]+[xf4]
	beq	@f
	bsr	jk_im_play_again
	bra	chk_next
@@:
	clr.b	jk_im_play_k-zp_work(a6)

	bsr	key_inp			*[shift]+[xf5]
	beq	@f
	bsr	jk_fo_play_again
	bra	chk_next
@@:
	clr.b	jk_fo_play_k-zp_work(a6)

	bsr	key_inp			*[ctrl]+[opt1]
	beq	@f
	bsr	jk_im_back
	bra	chk_next
@@:
	clr.b	ctrl_opt1-zp_work(a6)

	bsr	key_inp			*[ctrl]+[opt2]
	beq	@f
	bsr	jk_fo_back
	bra	chk_next
@@:
	clr.b	ctrl_opt2-zp_work(a6)
chk_next:				*次の曲へ移るかどうかチェック
	tst.b	fdr_flg-zp_work(a6)	*マスターフェーダーを実行中か
	beq	2f
	bpl	1f				*演奏の停止
	Z_MUSIC	#ZM_GET_FADER_STATUS
	tst.b	d0
	bpl	@f				*マスターフェーダーは中止あるいは完了した
	btst.l	#1,d0
	beq	2f				*マスターフェーダーはまだ動作中
	move.b	#1,fdr_flg-zp_work(a6)		*次は演奏停止
	move.w	blank_time(pc),blank_count-zp_work(a6)	*ブランクタイムを設定
	bra	bye_int
1:						*演奏停止フェーズ
	suba.l	a1,a1
	Z_MUSIC	#ZM_STOP
@@:
	clr.b	fdr_flg-zp_work(a6)			*pl:マスターフェーダーは終了していた
	move.w	#$ffff,next_flg-zp_work(a6)		*いよいよ次の曲へ
	move.w	blank_time(pc),blank_count-zp_work(a6)	*ブランクタイムを設定
	bra	bye_int
2:
	tst.b	next_flg-zp_work(a6)			*フラグが寝てるから次の曲へ移らない
	beq	bye_int

	tst.b	hajimete-zp_work(a6)
	bpl	@f
	bsr	hajimete_ope
	bra	set_param
@@:
	clr.b	next_flg-zp_work(a6)
	not.b	next_flg2-zp_work(a6)
	bpl	set_param
	bsr	goto_fadeout	*next_flg2=$ff : フェードアウトを行う
	bra	bye_int		*next_flg2=$00 : 次の曲を演奏する
set_param:
	moveq.l	#0,d4
	move.b	music_no(pc),d4
	move.l	d4,d5
	add.w	d4,d4
	add.w	d4,d4		*4倍
	lea	data_addr_tbl(pc),a5
	add.w	d4,a5
	addq.b	#1,music_no-zp_work(a6)
	tst.l	4(a5)
	bne	@f
	move.b	one_loop(pc),music_no-zp_work(a6)	*始めに戻す
@@:
	move.l	(a5),a5
	move.l	a5,a3		*save a5 into a3
	move.l	(a5),d0
	beq	ope_zmd		*ZMDデータのみだから即演奏
_jkbx_lp:
	move.l	d0,a5

	move.l	4(a5),d3
	bne	ope_mdd		*case:MDD
	tst.l	12(a5)		*address mode?
	beq	zpd_adr_mode
	lea.l	8(a5),a1	*a1=top address
zpd_header_check:
	move.l	(a1)+,d1		*ZPD ID
	cmpi.l	#ZPD_PDX,d1
	beq	@f
	addq.w	#8,a1			*header skip
@@:
	Z_MUSIC	#ZM_SET_ZPD_TABLE	*ZPDテーブルの登録
	bra	more_?
zpd_adr_mode:
	move.l	12(a5),a1		*a1.l=top address
	bra	zpd_header_check
ope_mdd:
	* < d3.l=MDD size
	move.l	d3,d2		*d2=size
	tst.l	12(a5)		*address mode?
	beq	mdd_adr_mode
	lea.l	8(a5),a1	*MDD address
mdd_header_check:
	move.l	(a1)+,d1	*d1=I/F number
	cmp.l	#SMFHED,(a1)
	beq	@f
	moveq.l	#0,d2		*ascii mode
@@:
	Z_MUSIC	#ZM_MIDI_TRANSMISSION
	bra	more_?
mdd_adr_mode:
	move.l	12(a5),a1
	bra	mdd_header_check
more_?:
	move.l	(a5),d0
	bne	_jkbx_lp
ope_zmd:
	lea	loop_tbl(pc),a0
	moveq.l	#0,d2
	move.b	(a0,d5.w),d2		*d3.b=次の曲のループ回数
	lea	event_table(pc),a1	*ジャンプ先
	move.l	d2,4(a1)		*ループ回数セット
	moveq.l	#%0011_1000,d1
	Z_MUSIC	#ZM_OBTAIN_EVENTS	*飛先やループ回数を登録

	lea	trk_seq_tbl(pc),a1			*マスターフェーダー初期化
	move.l	#$ffff_07_00+fader_dflt_spd,(a1)	*dev,omt,spd.h
	move.l	#$00_80_80_00,4(a1)			*spd.l,start,end,dummy
	Z_MUSIC	#ZM_MASTER_FADER

	lea.l	8+8(a3),a1	*header skipped ZMD address
	moveq.l	#0,d2		*高速応答モードで演奏
	Z_MUSIC	#ZM_PLAY_ZMD
bye_int:
	clr.b	_int_flag-zp_work(a6)
quit_int_j:
	movem.l	(sp)+,reglist
	rts

jk_im_next:
	tst.b	sft_opt1-zp_work(a6)
	bne	@f
	st.b	sft_opt1-zp_work(a6)
	move.w	#$ffff,next_flg-zp_work(a6)	*next_flg=$ff	*強制的に次の曲へ移る
@@:						*next_flg2=$ff	*すぐに…
	rts

jk_fo_next:
	tst.b	sft_opt2-zp_work(a6)
	bne	@f
	st.b	sft_opt2-zp_work(a6)
	move.w	#$ff00,next_flg-zp_work(a6)	*next_flg=$ff	*強制的に次の曲へ移る
@@:						*next_flg2=$00	*フェードアウトしてから…
	rts

jk_stop_cont:				*一時停止？
	tst.b	sft_ctrl-zp_work(a6)
	bne	@f
	st.b	sft_ctrl-zp_work(a6)
	not.b	stop_cont-zp_work(a6)
	bne	jk_stop
	suba.l	a1,a1
	Z_MUSIC	#ZM_CONT
@@:
	rts

jk_stop:
	suba.l	a1,a1
	Z_MUSIC	#ZM_STOP
	rts

jk_im_play_again:
	tst.b	jk_im_play_k-zp_work(a6)
	bne	@f
	st.b	jk_im_play_k-zp_work(a6)
	Z_MUSIC	#ZM_PLAY_AGAIN
@@:
	rts

jk_fo_play_again:
	tst.b	jk_fo_play_k-zp_work(a6)
	bne	@f
	st.b	jk_fo_play_k-zp_work(a6)
	move.w	#$ff00,next_flg-zp_work(a6)
	subq.b	#1,music_no-zp_work(a6)
	bcs	jk_no_rev
@@:
	rts

jk_im_back:
	tst.b	ctrl_opt1-zp_work(a6)
	bne	@b
	st.b	ctrl_opt1-zp_work(a6)
	move.w	#$ffff,next_flg-zp_work(a6)	*next_flg=$ff	*強制的に次の曲へ移る
	bra	@f				*next_flg2=$ff	*すぐに…
jk_fo_back:
	tst.b	ctrl_opt2-zp_work(a6)
	bne	@b
	st.b	ctrl_opt2-zp_work(a6)
	move.w	#$ff00,next_flg-zp_work(a6)	*next_flg=$ff	*強制的に次の曲へ移る
@@:						*next_flg2=$00	*フェードアウトしてから…
	subq.b	#2,music_no-zp_work(a6)
	bcc	@f
jk_no_rev:
	move.b	juke_max(pc),d0
	addq.b	#1,d0
	add.b	d0,music_no-zp_work(a6)
	move.b	music_no-zp_work(a6),d0
	cmp.b	juke_max(pc),d0
	bls	@f
	clr.b	music_no-zp_work(a6)
@@:
	rts

hajimete_ope:			*初めての時はここへ
	clr.b	hajimete-zp_work(a6)
	clr.b	next_flg-zp_work(a6)
	rts

goto_fadeout:			*フェードアウトをする
	lea	trk_seq_tbl(pc),a1
	move.l	#$ffff_07_00,d0			*dev,omt,(spd.h)
	move.b	fadeout_speed(pc),d0		*spd.h
	move.l	d0,(a1)				*dev,omt,spd.h
	move.l	#$00_80_00_00,4(a1)		*(spd.l),start,end,dummy
	move.b	fadeout_speed+1(pc),4(a1)	*spd.l
	Z_MUSIC	#ZM_MASTER_FADER
	st.b	fdr_flg-zp_work(a6)
	rts

set_next_flg_ed:		*演奏が終了するとZ-MUSICからここへ来る
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	move.l	a0,-(sp)
	lea	next_flg(pc),a0	*next_flg=$ff
	move.w	#$ffff,(a0)	*next_flg2=$ff フェードアウトしないで次へ行くようにマーク
	move.w	blank_time(pc),blank_count-next_flg(a0)	*ブランクタイムを再設定
	move.l	(sp)+,a0
	move.w	(sp)+,sr
	rts

set_next_flg_lp:		*ループ条件が満たされるとZ-MUSICからここへ来る
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	move.l	a0,-(sp)
	lea	next_flg(pc),a0	*next_flg=$ff
	move.w	#$ff00,(a0)	*next_flg2=$00	フェードアウトへ
	move.l	(sp)+,a0
	move.w	(sp)+,sr
	rts

int_entry_k:			*割り込みエントリーその２(DEBUG MODE)
*reglist	reg	d0-d1/a0-a1/a6
reglist	reg	d0-d7/a0-a6
	movem.l	reglist,-(sp)
	lea	zp_work(pc),a6
	tas.b	_int_flag-zp_work(a6)
	bne	quit_int_k

	Z_MUSIC	#ZM_GET_ZMSC_STATUS		*>a0.l=zmusic_stat
	bclr.b	#pf_PLAY,perform_flg(a0)
	beq	@f
	clr.b	stop_mode-zp_work(a6)
@@:
	lea	key_tbl_db(pc),a0
	lea	$800.w,a1

	bsr	key_inp
	beq	@f
	bsr	_PLAY		*演奏開始(xf4)
	bra	__exit
@@:
	clr.b	play_k-zp_work(a6)

	bsr	key_inp
	beq	@f
	bsr	_PAUSE		*一時停止(opt1)
	bra	__exit
@@:
	clr.b	stop_k-zp_work(a6)

	bsr	key_inp
	beq	@f
	bsr	_CONT		*一時停止解除(opt2)
	bra	__exit
@@:
	clr.b	cont_k-zp_work(a6)

	bsr	key_inp
	beq	@f
	bsr	_FF		*早送り(xf5)
	bra	__exit
@@:
	bsr	key_inp
	beq	@f
	bsr	_SLOW		*低速演奏
	bra	__exit
@@:
	bsr	key_inp		*FADEOUT(xf1)
	beq	@f
	bsr	_FADEOUT
	bra	__exit
@@:
	clr.b	fadeout_k-zp_work(a6)

	bsr	key_inp		*FADE IN(xf2)
	beq	@f
	bsr	_FADE_IN
	bra	__exit
@@:
	clr.b	fadein_k-zp_work(a6)
chk_FF:
	tst.b	_FF_flg-zp_work(a6)	*早送り終了か?
	beq	chk_SLOW
	lea	trk_seq_tbl(pc),a1
	move.l	#$ffff_07_00+fader_dflt_spd,(a1)	*dev,omt,spd.h
	move.l	#$00_80_80_00,4(a1)			*spd.l,start,end,dummy
	Z_MUSIC	#ZM_MASTER_FADER
	clr.b	_FF_flg-zp_work(a6)
	bra	@f
chk_SLOW:
	tst.b	_SLOW_flg-zp_work(a6)	*低速演奏か?
	beq	__exit
@@:
	moveq.l	#0,d1
	Z_MUSIC	#ZM_CONTROL_TEMPO	*通常テンポに戻す
	clr.b	_SLOW_flg-zp_work(a6)
__exit:
	clr.b	_int_flag-zp_work(a6)
quit_int_k:
	movem.l	(sp)+,reglist
	rts

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
	tas.b	stop_k-zp_work(a6)
	bmi	@f
	tas.b	stop_mode-zp_work(a6)
	bmi	do_cont
	suba.l	a1,a1
	Z_MUSIC	#ZM_STOP
@@:
	rts

_CONT:				*一時停止解除
	tas.b	cont_k-zp_work(a6)
	bmi	@f
*	tst.b	stop_mode-zp_work(a6)
*	beq	@f		*演奏は停止していない
do_cont:
	suba.l	a1,a1
	Z_MUSIC	#ZM_CONT
	clr.b	stop_mode-zp_work(a6)
@@:
	rts

_PLAY:				*演奏開始
	tas.b	play_k-zp_work(a6)
	bmi	@f
	Z_MUSIC	#ZM_PLAY2
	clr.b	stop_mode-zp_work(a6)
@@:
	rts

_FADE_IN:
	tas.b	fadein_k-zp_work(a6)
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
	tas.b	fadeout_k-zp_work(a6)
	bmi	@f
	lea	trk_seq_tbl(pc),a1
	move.l	#$ffff_07_00,d0			*dev,omt,(spd.h)
	move.b	fadeout_speed(pc),d0		*spd.h
	move.l	d0,(a1)				*dev,omt,spd.h
	move.l	#$00_80_00_00,4(a1)		*(spd.l),start,end,dummy
	move.b	fadeout_speed+1(pc),4(a1)	*spd.l
	Z_MUSIC	#ZM_MASTER_FADER
@@:
	rts

_FF:				*早送り
	tst.b	_SLOW_flg-zp_work(a6)			*低速演奏か?
	bne	@f
	tas.b	_FF_flg-zp_work(a6)
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
	tst.b	_FF_flg-zp_work(a6)	*早送り終了か?
	bne	@f
	tas.b	_SLOW_flg-zp_work(a6)
	bne	@f
	moveq.l	#-1,d1
	Z_MUSIC	#ZM_CONTROL_TEMPO
	move.l	SL_timer(pc),d1
	Z_MUSIC	#ZM_SET_TIMER_VALUE
@@:
	rts

release_zp:					*演奏制御解除部
	ori.w	#$0700,sr
	lea	zp_work(pc),a6
	suba.l	a1,a1
	move.l	rel_zp_mark(pc),d1
	Z_MUSIC	#ZM_APPLICATION_RELEASER	*解放ルーチンの登録解除
	move.l	a0,d0
	beq	unable_to_rel

	Z_MUSIC	#ZM_GET_ZMSC_STATUS		*>a0.l=zmusic_stat
	bclr.b	#7,external_applications(a0)	*Debug mode off
	bne	kctrl_release
*juke_release:
	bclr.b	#6,external_applications(a0)	*Juke box off
	beq	unable_to_rel			*解除出来ない

	moveq.l	#0,d1
	lea	int_entry_j(pc),a1
	Z_MUSIC	#ZM_SET_INT_SERVICE
	tst.l	d0
	bne	unable_to_rel			*解除出来ない

	moveq.l	#0,d1				*dummy
	Z_MUSIC	#ZM_INIT			演奏中のデータのメモリが解放されるから

	move.l	data_addr_tbl(pc),d0
	beq	rlszp00
	move.l	d0,-(sp)
	DOS	_MFREE
	addq.w	#4,sp
rlszp00:
	lea	release_mes(pc),a1
	move.l	a0work(pc),a0		*解放アドレス
	moveq.l	#0,d0			*no error
	move.b	d0,version_id-release_mes(a1)
exit_rlszp:
	rts

kctrl_release:
	moveq.l	#0,d1
	lea	int_entry_k(pc),a1
	Z_MUSIC	#ZM_SET_INT_SERVICE
	tst.l	d0
	beq	rlszp00
unable_to_rel:				*解除不能ケース
	lea	release_er_mes(pc),a1
	suba.l	a0,a0
	moveq.l	#-1,d0
	bra	exit_rlszp

	if	(debug.and.1)
debug2:					*デバグ用ルーチン(レジスタ値を表示／割り込み対応)
	move.w	sr,db_work2		*save sr	(サブルーチン_get_hex32が必要)
	ori.w	#$700,sr		*mask int
	movem.l	d0-d7/a0-a7,db_work

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

key_tbl_db:	dc.b	$0e,$0b,$0e,$2e,$0e,$3e,$0e,$1b,$0e,$7a,$0e,$5a,$0e,$6a
key_tbl_jk:	dc.b	$0e,$2e,$0e,$3e,$0e,$1e,$0e,$0b,$0e,$1b,$1e,$2e,$1e,$3e
juke_max:	dc.b	0
play_k:		dc.b	0
stop_k:		dc.b	0
stop_mode:	dc.b	0
cont_k:		dc.b	0
fadein_k:	dc.b	0
fadeout_k:	dc.b	0
hajimete:	dc.b	$ff	*初めてかどうか($ff=yes)
stop_cont:	dc.b	0
sft_ctrl:	dc.b	0
sft_opt1:	dc.b	0
sft_opt2:	dc.b	0
jk_im_play_k:	dc.b	0
jk_fo_play_k:	dc.b	0
ctrl_opt1:	dc.b	0
ctrl_opt2:	dc.b	0
one_loop:	dc.b	0	*すべての曲を演奏したあとどうするか(0:初めに戻る,$ff:なにも演奏しない)
lang:		dc.b	0	*言語モード(0:English,1:Japanese)
release_mes:	dc.b	'ZP3.R has been released from your system.',13,10,0
		dc.b	'ZP3.Rの常駐を解除しました',13,10,0
release_er_mes:	dc.b	'ZP3.R is unable to release.',13,10,0
		dc.b	'ZP3.Rは解除出来ません',13,10,0
		.even
next_flg:	dc.b	$ff	*次の曲へ移るかどうかフラグ	!!!順序変更禁止
next_flg2:	dc.b	$00	*フェードアウトフラグ		!!!順序変更禁止
music_no:	dc.b	0	*次回に演奏すべきデータナンバー
fdr_flg:	dc.b	0	*フェーダーを実行しているか $ff:yes $01:演奏を停止する
loop_tbl:	dcb.b	max_p,0
_FF_flg:	dc.b	0
_SLOW_flg:	dc.b	0
_int_flag:	dc.b	0
	.even
fadeout_speed:	dc.w	fader_dflt_spd*256
fadein_speed:	dc.w	fader_dflt_spd*256
blank_time:	dc.w	480
blank_count:	dc.w	480
trk_seq_tbl:	ds.b	100
FF_timer:	dc.l	-1	*$ffff0000+高速タイマ(M:$c0,B:$f8,A:$399)
SL_timer:	dc.l	-1	*$ffff0000+低速タイマ(M:$c0,B:$f8,A:$399)
rel_zp_mark:	ds.l	1
a0work:		ds.l	1
*real_ch_tbl:	ds.l	1
*results:	ds.l	1
*timer_value:	ds.w	1
event_table:	ds.l	3
data_addr_tbl:	dcb.l	max_p+1,0	*address0.l,address1.l,...

end:

program_start:
	lea	zp_work(pc),a6
	move.l	a0,a0work-zp_work(a6)	*メモリ管理ポインタ
	move.l	a3,env_bak-zp_work(a6)

	lea	end_of_prog(pc),a1	*program end address+1
	lea	$10(a0),a0		*メモリブロックの変更
	suba.l	a0,a1
	pea	(a1)
	pea	(a0)
	DOS	_SETBLOCK
	addq.w	#8,sp
	tst.l	d0
	bmi	out_mem

	move.l	#(fn_size+3)*max_p+1,-(sp)
	DOS	_MALLOC
	addq.w	#4,sp
	move.l	d0,zpdnm_buf-zp_work(a6)
	bmi	out_mem

	move.l	#(fn_size+7)*max_p+1,-(sp)
	DOS	_MALLOC
	addq.w	#4,sp
	move.l	d0,mddnm_buf-zp_work(a6)
	bmi	out_mem

	suba.l	a1,a1		*スーパーバイザへ
	IOCS	_B_SUPER
	move.l	d0,ssp-zp_work(a6)

	tst.b	$0cbc.w				*MPUが68000ならキャッシュフラッシュ必要無し
	bne	@f
	move.w	#RTS,cache_flush-zp_work(a6)
@@:						*ＰＣＭドライバ
	move.l	#92,-(sp)	*ワーク確保
	DOS	_MALLOC
	addq.w	#4,sp
	move.l	d0,open_fn-zp_work(a6)
	bmi	out_mem

	pea	$10000
	DOS	_MALLOC
	addq.w	#4,sp
	move.l	d0,mysp-zp_work(a6)
	bmi	out_mem
	add.l	#$10000,d0
	move.l	d0,sp		*スタックの設定

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
	bhi	illegal_fader_speed
	move.w	d1,fadeout_speed-zp_work(a6)
	move.w	d1,fadein_speed-zp_work(a6)
	bsr	skip_sep
	bsr	chk_num
	bmi	1f
	bsr	get_num
	tst.l	d1
	bpl	@f
	neg.l	d1
@@:
	cmpi.l	#65535,d1
	bhi	illegal_fader_speed
	move.w	d1,fadein_speed-zp_work(a6)
1:
	move.l	(sp)+,a2
2:
	pea	zp3_opt(pc)		*'zp3_opt'
	bsr	search_env
	addq.w	#4,sp
	tst.l	d0
	beq	@f
	move.l	a2,-(sp)
	move.l	d0,a2
	bsr	chk_optsw		*オプションスイッチ
	move.l	(sp)+,a2
@@:
	tst.b	(a2)+		*スイッチ文字列
	beq	print_hlp

	bsr	chk_optsw		*オプションスイッチ
	tst.b	(a2)
	bne	m_play_
	bra	print_hlp

chk_optsw:			*オプションのチェック
chk_optsw_lp:
	bsr	skip_spc	*スペースのスキップ
	move.b	(a2)+,d0
	beq	@f
	cmpi.b	#'-',d0		*スイッチ指定がある
	beq	go_chk_sw
	cmpi.b	#'/',d0		*スイッチ指定がある。
	beq	go_chk_sw
@@:
	subq.w	#1,a2		*スイッチ無しは演奏開始と解釈
	rts

go_chk_sw:
	bsr	skip_spc	*スペースのスキップ
	move.b	(a2)+,d0
	beq	print_hlp
	move.l	d0,d1
	bsr	mk_capital	*小文字/大文字変換
	cmpi.b	#'0',d0
	beq	alt_zmusic_mode
	cmpi.b	#'2',d0
	beq	v2_compatible_mode
	cmpi.b	#'3',d0
	beq	v3_mode
	cmpi.b	#'!',d1		*SE演奏開始
	beq	m_play_fx
	cmpi.b	#'b',d1		*ジュークボックス.
	beq	juke_box	*ループ有り
	cmpi.b	#'e',d1		*enable track.
	beq	enable_tracks
	cmpi.b	#'i',d1		*Z-MUSICと楽器の初期化.
	beq	init_zmsc
	cmpi.b	#'m',d1		*Mute track.
	beq	mask_tracks
	cmpi.b	#'o',d1		*Enable track.
	beq	output_level_tracks
	cmpi.b	#'A',d0		*取り込んだMIDIデータの書き出し.
	beq	midi_input
	cmpi.b	#'B',d0		*ジュークボックス.
	beq	juke_box2	*ループ無し.
	cmpi.b	#'C',d0		*演奏再開.
	beq	m_cont
	cmpi.b	#'D',d0		*受信MIDIインターフェースの指定.
	beq	set_midi_if
	cmpi.b	#'E',d0		*Enable ch.
	beq	enable_ch
	cmpi.b	#'F',d0		*Fadeout.
	beq	fadeout
	cmpi.b	#'G',d0		*非表示モード.
	beq	set_non_disp
	cmpi.b	#'I',d0		*Z-MUSICと楽器の初期化.
	beq	init_zmsc2
	cmpi.b	#'J',d0		*日本語表示.
	beq	japanese_mode
	cmpi.b	#'K',d0		*デバッグツールの常駐.
	beq	zp_key_ctrl
	cmpi.b	#'M',d0		*Mute ch.
	beq	mask_ch
	cmpi.b	#'O',d0		*set ch output level.
	beq	output_level_ch
	cmpi.b	#'P',d0		*演奏開始.
	beq	m_play
	cmpi.b	#'Q',d0		*ステップタイム等の計算.
	beq	m_total
	cmpi.b	#'R',d0		*ジュークボックス終了(解除).
	beq	release
	cmpi.b	#'S',d0		*演奏停止.
	beq	m_stop
	cmpi.b	#'V',d0		*ジュークボックスのインターバル.
	beq	set_juke_interval
	cmpi.b	#'W',d0		*同期演奏.
	beq	synchro_play
	cmpi.b	#'X',d0		*MIDIデータを楽器へ転送.
	beq	midi_send
	cmpi.b	#'Y',d0		*Self Recording
	beq	self_record
	bra	print_hlp

set_midi_if:
	bsr	chk_drv		*ドライバ常駐チェック
	bmi	no_drv		*ドライバが組み込まれてない
	bsr	chk_num
	bmi	ask_mdif
	bsr	get_num
	move.l	d1,d2		*in
	move.l	d1,d3		*out
	bsr	skip_sep
	bsr	chk_num
	bmi	@f
	bsr	get_num
	move.l	d1,d3
@@:
	move.l	d2,d1
	subq.l	#1,d1
	bcs	illegal_if
	cmpi.l	#if_max-1,d1
	bgt	illegal_if
	Z_MUSIC	#ZM_CURRENT_MIDI_IN
	tst.l	d0
	bmi	illegal_if
	move.l	d3,d1
	subq.l	#1,d1
	bcs	illegal_if
	cmpi.l	#if_max-1,d1
	bgt	illegal_if
	Z_MUSIC	#ZM_CURRENT_MIDI_OUT
	tst.l	d0
	bmi	illegal_if
print_mdif:
	lea	crntmidiin(pc),a1
	bsr	bil_prta1
	move.l	d2,d0
	bmi	@f
	bsr	num_to_str		*< d0.l=1-3
	lea	suji(pc),a1
	bra	1f
@@:
	lea	none_mdif(pc),a1
1:
	bsr	prta1
	lea	CRLF(pc),a1
	bsr	prta1
	lea	crntmidiout(pc),a1
	bsr	bil_prta1
	move.l	d3,d0
	bmi	@f
	bsr	num_to_str		*< d0.l=1-3
	lea	suji(pc),a1
	bra	1f
@@:
	lea	none_mdif(pc),a1
1:
	bsr	prta1
	lea	CRLF(pc),a1
	bsr	prta1
	st.b	no_error_mark-zp_work(a6)
	bra	chk_optsw_lp

ask_mdif:
	moveq.l	#-1,d1
	Z_MUSIC	#ZM_CURRENT_MIDI_IN
	move.l	d0,d2
	addq.w	#1,d2
	moveq.l	#-1,d1
	Z_MUSIC	#ZM_CURRENT_MIDI_OUT
	move.l	d0,d3
	addq.w	#1,d3
	bra	print_mdif

set_non_disp
	st.b	non_disp-zp_work(a6)
	move.w	#RTS,prta1-zp_work(a6)
	bsr	cache_flush
	bra	chk_optsw_lp

cache_flush:				*キャッシュのフラッシュ
	movem.l	d0-d1,-(sp)
	moveq.l	#3,d1
	IOCS	_SYS_STAT
	movem.l	(sp)+,d0-d1
	rts

japanese_mode:				*日本語表示
	move.b	#1,lang-zp_work(a6)	*日本語モード
	bra	chk_optsw_lp

alt_zmusic_mode:
	bsr	chk_drv		*ドライバ常駐チェック
	bmi	no_drv		*ドライバが組み込まれてない
	moveq.l	#-1,d1
	Z_MUSIC	#ZM_ZMUSIC_MODE
	cmpi.l	#2,d0
	beq	v3_mode
	cmpi.l	#3,d0
	beq	v2_compatible_mode
	bra	illegal_ver_mode

v2_compatible_mode:
	bsr	chk_drv		*ドライバ常駐チェック
	bmi	no_drv		*ドライバが組み込まれてない
	moveq.l	#2,d1
	Z_MUSIC	#ZM_ZMUSIC_MODE
	tst.l	d0
	bmi	illegal_ver_mode
*	st.b	v2_compatch-zp_work(a6)
	lea	v2_mode_mes(pc),a1
	bsr	prta1
	st.b	no_error_mark-zp_work(a6)
	bra	chk_optsw_lp

v3_mode:
	bsr	chk_drv		*ドライバ常駐チェック
	bmi	no_drv		*ドライバが組み込まれてない
	moveq.l	#3,d1
	Z_MUSIC	#ZM_ZMUSIC_MODE
	tst.l	d0
	bmi	illegal_ver_mode
	lea	v3_mode_mes(pc),a1
	bsr	prta1
	st.b	no_error_mark-zp_work(a6)
	bra	chk_optsw_lp

set_juke_interval:
	bsr	chk_num
	bmi	print_hlp
	bsr	get_num
	cmp.l	#65535,d1
	bhi	interval_too_long
	move.w	d1,blank_count-zp_work(a6)
	move.w	d1,blank_time-zp_work(a6)
	bra	chk_optsw_lp

zp_key_ctrl:			*演奏制御機能の常駐(ZP -K)
	bsr	kep_chk		*常駐check
	bpl	jb_already	*既に常駐してます
	bsr	chk_drv		*ドライバ常駐チェック
	bmi	no_drv		*ドライバが組み込まれてない

	bsr	key_bind_db

	ori.w	#$0700,sr

	moveq.l	#-1,d1
	suba.l	a1,a1
	Z_MUSIC	#ZM_SET_INT_SERVICE
	tst.l	d0
	bne	other_prog			*既に他のプログラムが使用中

	lea	release_zp(pc),a1
	Z_MUSIC	#ZM_APPLICATION_RELEASER	*解放ルーチンの登録
	move.l	d0,rel_zp_mark-zp_work(a6)
	move.l	a0,d0
	beq	occupied_unsuccessful

	Z_MUSIC	#ZM_GET_ZMSC_STATUS		*>a0.l=zmusic_stat
	tas.b	external_applications(a0)	*Debug mode included

	Z_MUSIC	#ZM_GET_TIMER_MODE	* > d0.l=timer type(0:tm_a  1:tm_b  2:tm_m)
	move.l	#$ffff0380,FF_timer-zp_work(a6)
	move.l	#$ffff0000,SL_timer-zp_work(a6)
	subq.b	#1,d0
	bne	@f
	move.l	#$ffff00f7,FF_timer-zp_work(a6)
	move.l	#$ffff0000,SL_timer-zp_work(a6)
	bra	dbgmd00
@@:
	subq.b	#1,d0
	bne	dbgmd00
	move.l	#$ffff0100,FF_timer-zp_work(a6)
	move.l	#$ffff1fff,SL_timer-zp_work(a6)
dbgmd00:
	ori.w	#$0700,sr
	move.l	#192*65536+77,d1		*mst_clk=192,テンポ=77
	lea	int_entry_k(pc),a1
	Z_MUSIC	#ZM_SET_INT_SERVICE

	lea	debug_mes(pc),a1
	bsr	bil_prta1

	bsr	set_verid

	move.l	ssp(pc),a1	*ユーザーモードへ
	IOCS	_B_SUPER

	bsr	free_work

	clr.w	-(sp)
	move.l	#end-top,-(sp)
	DOS	_KEEPPR		*常駐終了

set_verid:
	move.l	#'ＺＰ',version_id-zp_work(a6)
	move.l	#'.R'*65536+v_code*256+v_code_+ver_type,version_id+4-zp_work(a6)
	rts

free_work:			*汎用ワークの解放
	move.l	mysp(pc),-(sp)
	DOS	_MFREE
	addq.w	#4,sp

	move.l	open_fn(pc),-(sp)
	DOS	_MFREE
	addq.w	#4,sp

	move.l	zpdnm_buf(pc),-(sp)
	DOS	_MFREE
	addq.w	#4,sp

	move.l	mddnm_buf(pc),-(sp)
	DOS	_MFREE
	addq.w	#4,sp

	rts

release:			*演奏制御終了(常駐解除)
	bsr	kep_chk		*常駐check
	bmi	not_kep		*常駐していない
	bsr	chk_drv		*ドライバ常駐チェック
	bmi	no_drv		*ドライバが組み込まれてない

	move.l	a2work(pc),d3
	sub.l	a0work(pc),d3	*calc offset

	lea	release_zp(pc),a1
	add.l	d3,a1
	jsr	(a1)		*>d0.l=error code a1.l=message,x:a6

	lea	zp_work(pc),a6
	move.l	d0,d1		*戻り値保存
	move.l	a1,d0
	beq	@f
	bsr	bil_prta1
@@:
	tst.l	d1
	bmi	err_exit	*error
	move.l	a0,d0
	beq	exit
	pea	$10(a0)		*解放
	DOS	_MFREE
	addq.w	#4,sp
exit:				*/Wの時パッチが当たる,同期演奏の時パッチが当たる
	NOP
	bsr	print_err_code

	move.l	ssp(pc),a1	*ユーザーモードへ
	IOCS	_B_SUPER

	DOS	_EXIT		*終了

exit2:				*エラーで終了
	bsr	bil_prta1
err_exit:
	tst.b	temp_flg-zp_work(a6)
	beq	@f
	pea	temp_name(pc)	*残ってしまった
	DOS	_DELETE		*テンポラリ削除
	addq.w	#4,sp
@@:
	tst.b	ocpy_int_service-zp_work(a6)
	beq	@f
	moveq.l	#0,d1
	lea	zmint_entry(pc),a1
	Z_MUSIC	#ZM_SET_INT_SERVICE	*占有していたら解放
@@:
	move.l	ssp(pc),a1	*ユーザーモードへ
	IOCS	_B_SUPER

	move.w	#-1,-(sp)
	DOS	_EXIT2

kep_chk:			*分身が常駐しているか
	* > eq=exists
	* > ne=none
	* > a2work分身のアドレス
	* - all
reglist	reg	a0/a2
	movem.l	reglist,-(sp)
	bsr	print_title
	move.l	a0work-zp_work(a6),a0
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
	lea	version_id+8-top+$100(a2),a1
	cmpa.l	8(a2),a1
	bhi	klop_nxt	*比較対象のメモリブロックが小さすぎるので対象外
	subq.w	#8,a1		*!Thanks to E.Tachibana
*	cmpa.l	a0work-zp_work(a6),a2
*	beq	klop_nxt	*自分自身じゃ意味無い
*	lea	version_id-top+$100(a2),a1
	cmp.l	#'ＺＰ',(a1)+
	bne	klop_nxt
	cmp.w	#'.R',(a1)+
	bne	klop_nxt
	cmp.w	#v_code*256+v_code_+ver_type,(a1)+
	bne	wrong_ver
	move.l	a2,a2work-zp_work(a6)
	movem.l	(sp)+,reglist
	moveq.l	#0,d0		*分身の存在を確認
	rts
klop_nxt:
	move.l	a2,a0
	bra	klop1		*どんどんさかのぼる
err_chk:			*分身は無かった
	movem.l	(sp)+,reglist
	moveq.l	#-1,d0
	rts
wrong_ver:			*バージョンが違う
	movem.l	(sp)+,reglist
	moveq.l	#1,d0
	rts

juke_box2:
	st.b	one_loop-zp_work(a6)
juke_box:			*ジュークボックス処理
	bsr	kep_chk		*常駐check
	bpl	jb_already	*既に常駐してます
	bsr	chk_drv		*ドライバ常駐チェック
	bmi	no_drv		*ドライバが組み込まれてない
	bsr	read_lzz	*LZZ.Rがあれば読み込んでおく
	moveq.l	#0,d1		*dummy
	Z_MUSIC	#ZM_INIT	*m_init
	move.l	#ID_ZMD,d3
	Z_MUSIC	#ZM_FREE_MEM2	*全ZMDメモリブロックの解放
	bsr	skip_spc
	lea	setup_fn(pc),a0
	move.l	a0,sfp-setup_fn(a0)
	moveq.l	#0,d0
	move.b	d0,setup1(a0)	*ワーク初期化
	move.b	d0,setup2(a0)
	move.b	d0,setup3(a0)
	move.b	d0,setup4(a0)
	move.l	zpdnm_buf(pc),a0
	bsr	clr_nm_buf
	move.l	mddnm_buf(pc),a0
	bsr	clr_nm_buf
*	lea	filename(pc),a0
*	bsr	setsulp
	lea	JUK_kaku(pc),a1
	bsr	set_fn
jkbx_lp:			*セットアップファイルがあるなら最大４つまで指定可能
	cmpi.b	#',',d0
	bne	exec_setup_jb
	bsr	set_stup	*get setup filename
	add.l	#fn_size,sfp-zp_work(a6)
	bra	jkbx_lp
exec_setup_jb:			*セットアップファイルの実行
	lea	setup_fn(pc),a2
exec_stjblp:
	tst.b	(a2)
	beq	exec_jkbx
	pea	(a2)
	pea	(a2)
	bsr	fopen
	tst.l	d5
	bmi	file_not_found
	bsr	read		*>d3=data size,a5=data address
	move.l	(sp)+,a2
	bsr	chk_ext_type	*>a2.l=dest. filename
	bsr	self_output	*自己出力
	pea	(a5)
	DOS	_MFREE
	addq.w	#4,sp
	move.l	(sp)+,a2
	lea	fn_size(a2),a2
	bra	exec_stjblp
exec_jkbx:			*juke fileの解釈
	lea	filename(pc),a2
	bsr	fopen
	tst.l	d5
	bmi	file_not_found
	bsr	read		*(ret:d3=data size,a5=data address)
*	move.l	d3,d4
	move.l	a5,a2
	move.l	a5,list_adr-zp_work(a6)	*あとでmfreeする時に使用

	pea	$40000			*とりあえず256kB
	DOS	_MALLOC
	addq.w	#4,sp
	move.l	d0,data_addr_tbl-zp_work(a6)
	bmi	out_mem			*メモリ不足error
	move.l	d0,a5			*データアドレス
	lea	loop_tbl(pc),a1		*曲の繰り返し回数
	lea	data_addr_tbl(pc),a3	*data table
	moveq.l	#0,d6			*how many data
	moveq.l	#0,d7			*total size
	move.l	d7,last_zpd_addr-zp_work(a6)
jkbx_lp01:				*演奏データの読み込み
	move.b	(a2),d0
	beq	exit_jkbx_lp
	cmpi.b	#$1a,d0
	beq	exit_jkbx_lp		*ファイル終端発見
	cmpi.b	#' ',d0
	bhi	get_lpc
	addq.w	#1,a2
	bra	jkbx_lp01
get_lpc:				*ループカウンタゲット
	bsr	chk_num
	bmi	set_l2
	bsr	get_num
	bra	set_l_a1
set_l2:
	moveq.l	#1,d1
set_l_a1:
	bsr	skip_sep
	move.b	d1,(a1)+	*ループ回数セット
	bsr	set_fn2
	pea	(a2)
	lea	filename(pc),a2
	move.l	a5,(a3)+	*set zmd address
	move.l	a5,hozon_a5-zp_work(a6)
	clr.l	(a5)+		*end mark
	clr.l	(a5)+		*dummy
	movem.l	d3/d7/a5,preserve_d3d7a5-zp_work(a6)	*コンパイルが発生した場合に使用する
	moveq.l	#0,d0
	bsr	read_data	*曲データ読み込み > d3.l=size > a5.l=addr
	cmpi.l	#'ZDF0',(a5)
	beq	case_ZDF_jk
	cmpi.l	#ZmuSiC0,(a5)	*ＩＤチェック
	bne	jkbx_compile
	move.l	4(a5),d0
	clr.b	d0
	cmp.l	#ZmuSiC1,d0
	bne	unid_error
	cmpi.b	#$30,7(a5)
	bcs	version_error	*バージョン不適合
czj0:				*< d3.l=size < a5.l=addr
	move.l	a5,zmd_addr-zp_work(a6)
	addq.l	#1,d3
	bclr.l	#0,d3
	add.l	d3,a5
rd_zpd_lp:
	pea	(a5)
	move.l	zmd_addr(pc),a5
	move.w	#$00ff,zpd_scan-zp_work(a6)	*clr.b	zpd_scan-zp_work(a6)
						*st.b	mdd_scan-zp_work(a6)
	bsr	embed_with_dummy		*get zpd filename(& get mdd filename)
	move.l	(sp)+,a5

	tst.b	zpd_scan-zp_work(a6)
	beq	read_mdd??
read_zpd:					*ZPDデータの読み込み
	lea	filename(pc),a0
	lea	ZPD_kaku(pc),a2
	bsr	kakuchoshi
	lea	filename(pc),a0
	move.l	zpdnm_buf(pc),a2
	moveq.l	#3,d5
	bsr	chk_same_nm		*同じものをすでに読んでいないか(>d0.l=result code)
	bmi	do_r_zpd		*読んでいない
	move.l	d0,a0
	move.b	(a0)+,d1
	lsl.l	#8,d1
	move.b	(a0)+,d1
	lsl.l	#8,d1
	move.b	(a0)+,d1
	lsl.l	#8,d1
	move.b	(a0)+,d1
	cmp.l	last_zpd_addr(pc),d1
	beq	rd_zpd_lp		*同じものが２回続く場合は省略
	move.l	d1,last_zpd_addr-zp_work(a6)
	move.l	hozon_a5(pc),a0
	move.l	a5,hozon_a5-zp_work(a6)
	move.l	a5,(a0)			*set link param.
	add.l	#16,d7
	move.l	d7,-(sp)
	move.l	data_addr_tbl(pc),-(sp)
	DOS	_SETBLOCK
	addq.w	#8,sp
	tst.l	d0
	bmi	out_mem			*OUT OF MEMORY
	clr.l	(a5)+			*END MARK
	clr.l	(a5)+			*ZPD MARK
	clr.l	(a5)+			*mark address mode
	move.l	d1,(a5)+		*set data address
	bra	rd_zpd_lp

do_r_zpd:
	move.l	d0,-(sp)
	move.l	hozon_a5(pc),a0
	move.l	a5,hozon_a5-zp_work(a6)
	move.l	a5,(a0)		*set link param.
	clr.l	(a5)+		*end code
	clr.l	(a5)+		*zpd mark
	lea	filename(pc),a2
	moveq.l	#4,d0
	bsr	read_data		*ZPDデータ読み込み

	cmpi.l	#ZPDV2_0,4(a5)		*$10,'ZmA'
	bne	1f
	moveq.l	#0,d0			*v2 mark
	cmpi.l	#ZPDV2_1,4+4(a5)	*'dpCm'
	beq	@f
	bra	unid_error
1:
	moveq.l	#2,d0			*PDX mark
	cmpi.l	#ZPDV3_0,4(a5)		*$1a,'Zma'
	bne	@f			*PDXとみなす
	cmpi.l	#ZPDV3_1,4+4(a5)	*'DPcM'
	bne	unid_error
	moveq.l	#1,d0			*v3 mark
@@:
	move.l	a5,last_zpd_addr-zp_work(a6)
	move.l	d0,(a5)			*ZPD　ID格納

	move.l	(sp)+,a0	*ファイルネームバッファ／アドレスバッファへ登録
	move.l	a5,d0
	bsr	wrt_d02a0
	addq.l	#1,d3
	bclr.l	#0,d3
	add.l	d3,a5
	bra	rd_zpd_lp

read_mdd??:				*MDDデータの読み込み

rd_mdd_lp:
	pea	(a5)
	move.l	zmd_addr(pc),a5
	move.w	#$ff00,zpd_scan-zp_work(a6)	*st.b	zpd_scan-zp_work(a6)
						*clr.b	mdd_scan-zp_work(a6)
	bsr	embed_with_dummy		*get zpd filename(& get mdd filename)
	move.l	(sp)+,a5

	tst.b	mdd_scan-zp_work(a6)
	beq	prepare_next
read_mdd:
	lea	mddfilename(pc),a0
	lea	MID_kaku(pc),a2
	bsr	kakuchoshi
	lea	mddfilename(pc),a0
	move.l	mddnm_buf(pc),a2
	moveq.l	#7,d5
	bsr	chk_same_nm		*同じものをすでに読んでいないか(>d0.l=result code)
	bmi	do_r_mdd		*読んでいない
	move.l	d0,a0
	move.b	(a0)+,d1
	lsl.l	#8,d1
	move.b	(a0)+,d1
	lsl.l	#8,d1
	move.b	(a0)+,d1
	lsl.l	#8,d1
	move.b	(a0)+,d1
	move.l	hozon_a5(pc),a2
	move.l	a5,hozon_a5-zp_work(a6)
	move.l	a5,(a2)			*set link param.
	add.l	#16,d7
	move.l	d7,-(sp)
	move.l	data_addr_tbl(pc),-(sp)
	DOS	_SETBLOCK
	addq.w	#8,sp
	tst.l	d0
	bmi	out_mem			*OUT OF MEMORY
	clr.l	(a5)+			*end mark
	move.b	(a0)+,(a5)+		*save size(MDD mark)
	move.b	(a0)+,(a5)+
	move.b	(a0)+,(a5)+
	move.b	(a0)+,(a5)+
	clr.l	(a5)+			*mark address mode
	move.l	d1,(a5)+		*set data address
	bra	rd_mdd_lp

do_r_mdd:
	move.l	d0,-(sp)
	move.l	hozon_a5(pc),a0
	move.l	a5,hozon_a5-zp_work(a6)
	move.l	a5,(a0)		*set link param.
	clr.l	(a5)+		*end code
	addq.w	#4,a5		*dummy(あとでサイズが入る)
	lea	mddfilename(pc),a2
	moveq.l	#4,d0
	bsr	read_data	*>d3.l=mem.block size,d0.l=mdd true size
	cmpi.l	#'ZDF0',4(a5)
	bne	chk_mdd_jk
	bsr	case_ZDF_jk2	*>d0.l=mdd true size
chk_mdd_jk:
	move.l	mdd_dest_if(pc),(a5)
	move.l	d0,-4(a5)	*save size(MDD mark)

	move.l	(sp)+,a0
	move.l	a5,d0
	bsr	wrt_d02a0	*save address
	move.l	-4(a5),d0
	bsr	wrt_d02a0	*save size
	addq.l	#1,d3
	bclr.l	#0,d3
	add.l	d3,a5
	bra	rd_mdd_lp
prepare_next:
	move.b	d6,juke_max-zp_work(a6)
	addq.b	#1,d6
	cmpi.b	#max_p,d6
	bhi	too_many	*曲データ多すぎ

	move.l	(sp)+,a2
	bra	jkbx_lp01

jkbx_compile:				*読み込まれたZMSをコンパイルする
	lea	filename(pc),a2		*< d3.l=size < a5.l=addr
	bsr	chk_ext_type		*MDD/MIDだった
	bmi	not_performance_data	*演奏データではない
	bsr	compile_zms		*< d3.l=size < a5.l=addr
	move.l	a5,a2			*a2=addr
	move.l	d3,d5			*d5=size
	beq	1f
					*起動コンパイラケース
	bsr	copy_to_jkbxbuf
	pea	(a2)
	DOS	_MFREE
	addq.w	#4,sp
	bra	czj0
1:					*常駐コンパイラ使用ケース
	cmpi.l	#ZmuSiC0,(a2)		*$1a,'Zmu'
	beq	@f
	move.l	z_zmd_size-8(a2),d5	*d5=zmd size
	bra	1f
@@:
	move.l	z_zmd_size(a2),d5	*d5=zmd size
1:
	bsr	copy_to_jkbxbuf
	move.l	a1,-(sp)
	move.l	a2,a1
	Z_MUSIC	#ZM_FREE_MEM
	move.l	(sp)+,a1
	bra	czj0

copy_to_jkbxbuf:			*コンパイル結果をJUKE BOXバッファへコピー
	* < a2.l=addr
	* < d5.l=size
	* > d3.l=size(入力のd5.lに等しくなる)
	* > d7.l=total buffer size
	* - a2
	movem.l	preserve_d3d7a5(pc),d3/d7/a5
	move.l	d5,d3
	add.l	d5,d7

	addq.l	#1,d7			*.even
	bclr.l	#0,d7

	addq.l	#8,d7			*listワークのために8バイト余分に
	move.l	d7,-(sp)
	move.l	data_addr_tbl(pc),-(sp)
	DOS	_SETBLOCK
	addq.w	#8,sp
	tst.l	d0
	bmi	out_mem			*OUT OF MEMORY

	movem.l	a0/a2,-(sp)
	move.l	a5,a0
@@:
	move.b	(a2)+,(a0)+
	subq.l	#1,d5
	bne	@b
	movem.l	(sp)+,a0/a2
	rts

exit_jkbx_lp:
	move.l	list_adr(pc),-(sp)
	DOS	_MFREE
	addq.w	#4,sp

	ori.w	#$0700,sr

	bsr	key_bind_jk
				*常駐処理
	moveq.l	#-1,d1
	suba.l	a1,a1
	Z_MUSIC	#ZM_SET_INT_SERVICE
	tst.l	d0
	bne	other_prog	*すでに他のプログラムが使用中

	lea	release_zp(pc),a1
	Z_MUSIC	#ZM_APPLICATION_RELEASER	*解放ルーチンの登録
	move.l	d0,rel_zp_mark-zp_work(a6)
	move.l	a0,d0
	beq	occupied_unsuccessful

	Z_MUSIC	#ZM_GET_ZMSC_STATUS
	bset.b	#6,external_applications(a0)	*juke mode included

	lea	juke_mes(pc),a1
	bsr	bil_prta1

	move.l	lzz_adr(pc),d0		*LZZを解放
	beq	@f
	move.l	d0,-(sp)
	DOS	_MFREE
	addq.w	#4,sp
@@:
	lea	event_table(pc),a1
	lea	set_next_flg_ed(pc),a2
	move.l	a2,(a1)+		*3:Jump after if performance comes to an end.(0:off)
	clr.l	(a1)+			*4:Loop time value(0:off/1-256)上位16ビットは0に初期化しておくこと
	lea	set_next_flg_lp(pc),a2
	move.l	a2,(a1)+		*5:Jump after n times loop

	move.l	#192*65536+77,d1		*mst_clk=192,テンポ=77
	lea	int_entry_j(pc),a1
	Z_MUSIC	#ZM_SET_INT_SERVICE

	bsr	set_verid

	move.l	ssp(pc),a1		*ユーザーモードへ
	IOCS	_B_SUPER

	bsr	free_work

	clr.w	-(sp)
	move.l	#end-top,-(sp)
	DOS	_KEEPPR			*常駐終了

read_data:
	* < d0.l=付加情報サイズ
	* < a2.l=filename
	* < a5.l=address 
	* < d7.l=total buffer size
	* > d3.l=size
	* x d0,d5
	move.l	d4,-(sp)
	move.l	d0,d4
	bsr	fopen
	tst.l	d5
	bmi	file_not_found
	* < d5.l=file handle
	move.w	#2,-(sp)	*ファィルの長さを調べる
	clr.l	-(sp)
	move.w	d5,-(sp)
	DOS	_SEEK
 	addq.w	#8,sp		*d0.l=file length
	move.l	d0,d3		*d3=length
	beq	fsize0		*file size=0
	add.l	d3,d7

	addq.l	#1,d7		*.even
	bclr.l	#0,d7

	addq.l	#8,d7		*listワークのために8バイト余分に
	add.l	d4,d7		*付加情報のためにd4バイト余分に
	move.l	d7,-(sp)
	move.l	data_addr_tbl(pc),-(sp)
	DOS	_SETBLOCK
	addq.w	#8,sp
	tst.l	d0
	bmi	out_mem		*OUT OF MEMORY

	clr.w	-(sp)		*ファイルポインタを元に戻す
	clr.l	-(sp)
	move.w	d5,-(sp)
	DOS	_SEEK
	addq.w	#8,sp

	move.l	d3,-(sp)	*push size
	pea	(a5,d4.l)	*push addr
	move.w	d5,-(sp)	*file handle
	DOS	_READ
	lea	10(sp),sp

	cmp.l	d0,d3
	bne	read_err	*読み込み失敗

	move.l	d0,d4
	move.w	d5,-(sp)	*close
	DOS	_CLOSE
	addq.l	#2,sp
	move.l	d4,d0
	move.l	(sp)+,d4
	rts

wrt_d02a0:
	rol.l	#8,d0
	move.b	d0,(a0)+
	rol.l	#8,d0
	move.b	d0,(a0)+
	rol.l	#8,d0
	move.b	d0,(a0)+
	rol.l	#8,d0
	move.b	d0,(a0)+
	rts

clr_nm_buf:
	movem.l	d0-d1,-(sp)
	moveq.l	#0,d0
	move.w	#94*max_p,d1	*94*max_p+1-1だから
cnb_lp:
	move.b	d0,(a0)+
	dbra	d1,cnb_lp
	movem.l	(sp)+,d0-d1
	rts

chk_same_nm:
	* < a0.l=find source
	* < a2.l=find destination
	* < d5.l=number of skip bytes
	* > d0.l=result
	* destination format name strings(.b)...,(0,addr(.l))
	movem.l	d1-d2/a0/a2,-(sp)
_wc_lp01:
	bsr	do_get_cmd_num
	cmpi.l	#-1,d0
	bne	_exit_wc
_wc_lp02:
	tst.b	(a2)+		*次のコマンド名へ
	bne	_wc_lp02
	add.l	d5,a2		*skip addr
	tst.b	(a2)
	bne	_wc_lp01
_wc_lp03:			*バッファに登録
	move.b	(a0)+,d0
	bsr	mk_capital
	move.b	d0,(a2)+
	bne	_wc_lp03
				*case error
	subq.w	#1,a2
	move.l	a2,d0
	moveq.l	#-1,d1		*set minus
	movem.l	(sp)+,d1-d2/a0/a2
	rts
_exit_wc:			*case ok
	moveq.l	#0,d1		*dummy
	movem.l	(sp)+,d1-d2/a0/a2
	rts

do_get_cmd_num:			*実際に文字列を捜す
	* < a0=source str addr
	* > d0=-1 can't found
	move.l	a0,d1
	move.l	a2,d2
@@:
	move.b	(a0)+,d0
	bsr	mk_capital	*小文字→大文字
	cmp.b	(a2)+,d0
	bne	@f
	tst.b	(a2)		*終了?
	bne	@b
	move.l	a2,d0
	rts
@@:
	move.l	d1,a0
	move.l	d2,a2
	moveq.l	#-1,d0		*error!
	rts

case_ZDF_jk:			*juke box用ZDF展開
	* < a5.l=ZDF address
	* > d7.l=calculated total size
	* - all except result parameters
	sub.l	d3,d7
	movem.l	d0-d3/d5/a0-a4,-(sp)

	move.l	lzz_adr(pc),d0
	beq	cant_use_lzz
	move.l	d0,a0

	lea	bufadr(pc),a4

	pea	(a4)			*情報テーブル
	pea	(a5)			*ZDF addr
	jsr	_ref_data(a0)
	addq.w	#8,sp
	tst.l	d0
	bmi	lzz_err

	move.w	ZNumOfData(a4),d5
zjklp0:
	add.l	ZSize(a4),d7		*展開後のサイズ
	add.l	#8+1,d7		*list構造のwork size, +1は.even処理用
	bclr.l	#0,d7		*.even
	lea	ZNext(a4),a4
	subq.w	#1,d5
	bne	zjklp0
	subq.l	#8,d7		*ZMDの部分はコール以前に考慮済み

	move.l	a5,a1		*DMA転送のための下準備
	add.l	d3,a1
*	subq.w	#1,a1		*source
	move.l	d3,d2		*size
	add.l	d3,d7
	move.l	data_addr_tbl(pc),a2
	add.l	d7,a2
*	subq.w	#1,a2		*destination

	move.l	d7,-(sp)	*あらかじめメモリは確保しておく
	move.l	data_addr_tbl(pc),-(sp)
	DOS	_SETBLOCK
	addq.w	#8,sp
	tst.l	d0
	bmi	out_mem		*OUT OF MEMORY

	bsr	trans_a1_a2_dec

	lea	bufadr(pc),a4

	sub.l	d3,a2
	addq.w	#1,a2		*a2=zdf先頭アドレス

	pea	(a4)		*情報テーブル
	pea	(a2)		*ZDF addr
	jsr	_ref_data(a0)
	addq.w	#8,sp
	tst.l	d0
	bmi	lzz_err

	move.w	ZNumOfData(a4),d3
zjklp1:
	move.l	ZSize(a4),-(sp)		*展開後のサイズ分メモリ確保
	DOS	_MALLOC
	addq.w	#4,sp
	tst.l	d0
	bmi	out_mem			*OUT OF MEMORY
	move.l	d0,a1

	pea	(a1)			*push extract
	move.l	ZTopAdr(a4),-(sp)
	jsr	_ext_data(a0)
	addq.w	#8,sp
	tst.l	d0
	bmi	lzz_err

	move.l	ZSize(a4),d2
	move.l	a5,a2

	bsr	trans_a1_a2_inc

	move.l	d2,d0
	addq.l	#1,d0
	bclr.l	#0,d0		*.even
	add.l	d0,a5

	move.w	ZKind(a4),d0	*get data type
	bne	zjk00
				*ZMD data
	cmpi.w	#1,d3		*ZMD１個だけならば
	beq	zjkfr
	movem.l	d5/a2/a5,-(sp)
	move.l	a2,a5
	move.l	d3,d5
	move.l	a4,a2
	bsr	erase_zpd_mdd	*adpcm_block_data,midi_dumpをつぶす
	movem.l	(sp)+,d5/a2/a5
	addq.w	#8,a5
	bra	zjkfr
zjk00:
	subq.w	#8,a2
	cmpi.w	#$20,d0		*ZPD?
	bne	zjk01
				*case:ZPD
	move.l	hozon_a5(pc),a3
	move.l	a5,hozon_a5-zp_work(a6)
	move.l	a2,(a3)		*set link param.
	clr.l	(a2)+		*end code
	clr.l	(a2)+		*zpd mark
	bra	zjkfr
zjk01:				*case:MDD
	move.l	hozon_a5(pc),a3
	move.l	a5,hozon_a5-zp_work(a6)
	move.l	a2,(a3)		*set link param.
	clr.l	(a2)+		*end code
	move.l	d2,(a2)+	*set size
zjkfr:
	pea	(a1)
	DOS	_MFREE
	addq.w	#4,sp

	lea	ZNext(a4),a4
	subq.w	#1,d3
	bne	zjklp1

	movem.l	(sp)+,d0-d3/d5/a0-a4

	sub.l	d3,d7
	move.l	d7,-(sp)	*あらかじめメモリは確保しておく
	move.l	data_addr_tbl(pc),-(sp)
	DOS	_SETBLOCK
	addq.w	#8,sp
	tst.l	d0
	bmi	out_mem		*OUT OF MEMORY

	cmpi.w	#1,bufadr+ZNumOfData-zp_work(a6)
	bne	prepare_next
					*ZMDが１個だけの時は
	move.l	hozon_a5(pc),a5
	addq.w	#8,a5
	move.l	bufadr+ZSize(pc),d3
	bra	czj0

case_ZDF_jk2:			*juke box用ZDF展開(MDD展開専用)
	* < a5.l=ZDF address
	* > d7.l=calculated total size
	* > d0.l=mdd true size
	* - all except result parameters
	sub.l	d3,d7
	movem.l	d0-d3/d5/a0-a2/a4,-(sp)

	move.l	lzz_adr(pc),d0
	beq	cant_use_lzz
	move.l	d0,a0

	lea	bufadr(pc),a4

	pea	(a4)			*情報テーブル
	pea	(a5)			*ZDF addr
	jsr	_ref_data(a0)
	addq.w	#8,sp
	tst.l	d0
	bmi	lzz_err

	cmpi.w	#1,ZNumOfData(a4)
	bne	unid_error_zdf		*MDDデータではあり得ない構造です。
	cmpi.w	#$41,ZKind(a4)
	bne	unid_error_zdf		*MDDデータではない。

	add.l	ZSize(a4),d7		*展開後のサイズ
	addq.l	#1,d7
	bclr.l	#0,d7			*.even

	move.l	a5,a1			*DMA転送のための下準備
	add.l	d3,a1
*	subq.w	#1,a1			*source
	move.l	d3,d2			*size
	add.l	d3,d7
	move.l	data_addr_tbl(pc),a2
	add.l	d7,a2
*	subq.w	#1,a2			*destination

	move.l	d7,-(sp)		*あらかじめメモリは確保しておく
	move.l	data_addr_tbl(pc),-(sp)
	DOS	_SETBLOCK
	addq.w	#8,sp
	tst.l	d0
	bmi	out_mem			*OUT OF MEMORY

	bsr	trans_a1_a2_dec

	lea	bufadr(pc),a4

	sub.l	d3,a2
	addq.w	#1,a2			*a2=zdf先頭アドレス

	pea	(a4)			*情報テーブル
	pea	(a2)			*ZDF addr
	jsr	_ref_data(a0)
	addq.w	#8,sp
	tst.l	d0
	bmi	lzz_err

	move.l	ZSize(a4),-(sp)		*展開後のサイズ分メモリ確保
	DOS	_MALLOC
	addq.w	#4,sp
	tst.l	d0
	bmi	out_mem			*OUT OF MEMORY
	move.l	d0,a1

	pea	(a1)			*push extract
	move.l	ZTopAdr(a4),-(sp)
	jsr	_ext_data(a0)
	addq.w	#8,sp
	tst.l	d0
	bmi	lzz_err

	move.l	ZSize(a4),d2
	move.l	a5,a2

	bsr	trans_a1_a2_inc

	pea	(a1)
	DOS	_MFREE
	addq.w	#4,sp

	movem.l	(sp)+,d0-d3/d5/a0-a2/a4

	sub.l	d3,d7
	move.l	d7,-(sp)	*あらかじめメモリは確保しておく
	move.l	data_addr_tbl(pc),-(sp)
	DOS	_SETBLOCK
	addq.w	#8,sp
	tst.l	d0
	bmi	out_mem		*OUT OF MEMORY

	move.l	bufadr+ZSize(pc),d0
	rts

read_lzz:
	movem.l	d0-d1/d5/a2,-(sp)
	clr.l	lzz_adr-zp_work(a6)

	bsr	fopen2
	tst.l	d5
	bmi	rl00
	move.w	d5,-(sp)		*close
	DOS	_CLOSE
	addq.l	#2,sp

	pea	$ffff.w
	DOS	_MALLOC
	andi.l	#$00ffffff,d0
	move.l	d0,d1
	move.l	d0,(sp)
	DOS	_MALLOC			* lzz 読み込みのためのメモリ確保
	addq.l	#4,sp
	tst.l	d0
	bmi	out_mem

	movea.l	d0,a2			* a2=LZZの存在アドレス
	add.l	d0,d1			* リミットアドレス
	move.l	d1,-(sp)
	move.l	d0,-(sp)
	move.l	open_fn(pc),-(sp)
	move.b	#1,(sp)
	move.w	#3,-(sp)
	DOS	_EXEC			* ロード
	lea	14(sp),sp
	tst.l	d0
	bmi	rl00

	cmpi.l	#'LzzR',_LzzCheck(a2)	* lzzかチェック
	bne	rl00

	move.l	_LzzSize(a2),-(sp)
	pea	(a2)
	DOS	_SETBLOCK		* メモリブロックを必要な大きさに縮小
	addq.l	#8,sp

	move.l	a2,lzz_adr-zp_work(a6)
rl00:
	movem.l	(sp)+,d0-d1/d5/a2
	rts

trans_a1_a2_dec:
	movem.l	d2/a1-a2,-(sp)
@@:
	move.b	-(a1),-(a2)
	subq.l	#1,d2
	bne	@b
	movem.l	(sp)+,d2/a1-a2
	rts

trans_a1_a2_inc:
	movem.l	d2/a1-a2,-(sp)
@@:
	move.b	(a1)+,(a2)+
	subq.l	#1,d2
	bne	@b
	movem.l	(sp)+,d2/a1-a2
	rts

synchro_play:
	move.w	#RTS,exit-zp_work(a6)
	bsr	cache_flush
	moveq.l	#-1,d1
	Z_MUSIC	#ZM_INTERCEPT_PLAY
	bsr	m_play
	moveq.l	#-1,d1			*move.l	if_number(pc),d1
	Z_MUSIC	#ZM_MIDI_REC
sync_wait:
	moveq.l	#0,d2
	moveq.l	#-1,d1			*move.l	if_number(pc),d1
	Z_MUSIC	#ZM_MIDI_INP1

	cmpi.b	#$fa,d0		*start message
	bne	@f
	moveq.l	#0,d1		*release interception & play
	bra	bye_sync_play
@@:
	bitsns	$0
	btst.l	#1,d0
	beq	sync_wait	*取り消し
	moveq.l	#1,d1		*release interception
bye_sync_play:
	Z_MUSIC	#ZM_INTERCEPT_PLAY
	move.w	#NOP,exit-zp_work(a6)
	bsr	cache_flush
	bsr	init_kbuf
	bra	exit

m_play_fx:			*効果音サイド演奏開始
	st.b	normal_play-zp_work(a6)
	bsr	chk_drv		*ドライバ常駐チェック
	bmi	no_drv		*ドライバが組み込まれてない
@@:
	move.b	(a2)+,d0
	beq	print_hlp	*ファイル名無しの場合は…
	cmpi.b	#' ',d0
	bls	@b
	subq.w	#1,a2
	bra	init_mpwk

m_play_:			*'-P'なしの場合の演奏開始
	* < a2.l=command line address
	clr.b	normal_play-zp_work(a6)
	bsr	chk_drv		*ドライバ常駐チェック
	bmi	no_drv		*ドライバが組み込まれてない
@@:
	move.b	(a2)+,d0
	beq	just_m_p	*ファイル名無しの場合は…
	cmpi.b	#' ',d0
	bls	@b
	subq.w	#1,a2
	bra	init_mpwk

m_play:				*演奏開始
	* < a2.l=command line address
	clr.b	normal_play-zp_work(a6)
	bsr	chk_drv		*ドライバ常駐チェック
	bmi	no_drv		*ドライバが組み込まれてない
@@:
	move.b	(a2)+,d0
	beq	just_m_p	*ファイル名無しの場合は…
	cmpi.b	#' ',d0
	bls	@b
	subq.w	#1,a2

	bsr	chk_num		*数字?
	bpl	trk_play
init_mpwk:
	lea	setup_fn(pc),a0
	move.l	a0,sfp-zp_work(a6)
	moveq.l	#0,d0
	move.b	d0,retry-zp_work(a6)
	move.b	d0,setup1(a0)		*ワーク初期化
	move.b	d0,setup2(a0)
	move.b	d0,setup3(a0)
	move.b	d0,setup4(a0)
	bsr	get_org_fn
	lea	ZMD_kaku(pc),a1
	bsr	set_fn			*>d0.lw=chr,d0.hw=拡張子タイプ
	lea	filename(pc),a1
	move.w	d0,-(sp)
	swap	d0
	tst.w	d0			*ZMDだったならzmd_nameとして登録
	bne	@f
	move.l	a1,zmd_name-zp_work(a6)
	bra	mply00
@@:
	subq.w	#1,d0			*cmpi.w	#1,d0
	bne	mply00
	move.l	a1,zms_name-zp_work(a6)
mply00:
	move.w	(sp)+,d0
m_pl_lp:			*セットアップファイルがあるなら最大４つまで指定可能
	cmpi.b	#',',d0
	bne	exec_setup
	bsr	set_stup
	add.l	#fn_size,sfp-zp_work(a6)
	bra	m_pl_lp
exec_setup:			*セットアップファイルの実行
	lea	setup_fn(pc),a2
exec_stlp:
	tst.b	(a2)
	beq	exec_play
	pea	(a2)
	pea	(a2)
	bsr	fopen
	tst.l	d5
	bmi	file_not_found
	bsr	read		*>d3=data size,a5=data address
	move.l	(sp)+,a2
	bsr	chk_ext_type	*>a2.l=dest. filename
	bsr	self_output	*自己出力
	move.l	(sp)+,a2
	lea	fn_size(a2),a2
	bra	exec_stlp
exec_play:
	lea	filename(pc),a2
	move.l	a2,filename0-zp_work(a6)	*便宜上のソースファイル名として保存
	bsr	fopen
	tst.l	d5
	bpl	do_exc_pl
	bsr	skip_peri2
excpl0:				*ZMDでだめならZMS
	move.b	(a2)+,d0
	beq	file_not_found2
	cmpi.b	#'.',d0
	bne	excpl0
	moveq.l	#0,d0
	move.b	retry(pc),d0
	cmpi.b	#6,d0
	bhi	file_not_found2
	add.w	d0,d0
	move.w	kktbl(pc,d0.w),d0
	lea	kktbl(pc,d0.w),a5
	move.b	(a5)+,(a2)+
	move.b	(a5)+,(a2)+
	move.b	(a5)+,(a2)+
	move.b	(a5)+,(a2)+
	addq.b	#1,retry-zp_work(a6)
	bra	exec_play
kktbl:
	dc.w	ZMD_kaku-kktbl	*0
	dc.w	ZMS_kaku-kktbl	*1
	dc.w	OPM_kaku-kktbl	*2
	dc.w	ZDF_kaku-kktbl	*3
	dc.w	MID_kaku-kktbl	*4
	dc.w	MDD_kaku-kktbl	*5
	dc.w	ZPD_kaku-kktbl	*6

skip_peri0:
	cmpi.b	#'.',(a0)+
	beq	skip_peri0
	subq.w	#1,a0
	rts

skip_peri2:
	cmpi.b	#'.',(a2)+
	beq	skip_peri2
	subq.w	#1,a2
	rts

do_exc_pl:				*読み込みと演奏(実行)
	move.b	retry-zp_work(a6),d0	*リトライ回数を検査
	beq	@f			*リトライなし
	subq.b	#1,d0			*cmpi.b	#1,d0
	bne	@f
	move.l	a2,zmd_name-zp_work(a6)	*zmdの名前として登録
	bra	doplyrd
@@:
	subq.b	#1,d0
	bne	doplyrd
	move.l	a2,zms_name-zp_work(a6)	*zmsの名前として登録
doplyrd:
	bsr	read		*>d3:data size,a5=data address
	cmpi.l	#'ZDF0',(a5)	*ZDF?
	beq	case_ZDF
	cmpi.l	#ZmuSiC0,(a5)	*ZMD以外
	bne	go_on_p
	cmpi.l	#ZmuSiC1+v_code,4(a5)	*ZMD以外
	bne	go_on_p
				*以下、ZMDの場合
	bsr	stop_free_zmd
	bra	do_exc_pl0

go_on_p:			*演奏開始(ZMS/OPMへの出力)
	lea	filename(pc),a2
	bsr	chk_ext_type
	bpl	@f
	bsr	self_output	*MID/MDDケース(<d3.l=size, a5=data address, a2=out name)
	bra	exit
@@:
	bsr	stop_free_zmd
	bsr	compile_zms	*>d3=data size,a5=data address
do_exc_pl0:
	move.l	z_title_offset(a5),d0
	beq	@f		*なし
	tst.b	non_disp-zp_work(a6)
	bne	@f
	move.w	#2,-(sp)	*コメント表示
	pea	z_title_offset+4(a5,d0.l)
	DOS	_FPUTS
	addq.w	#6,sp
@@:				*ZMD演奏開始
	tst.b	normal_play-zp_work(a6)
	bne	@f
	move.l	d3,d2		*size
	lea	8(a5),a1	*z_common_offsetから
	Z_MUSIC	#ZM_PLAY_ZMD
	bra	exit
@@:				*効果音演奏
	move.l	d3,d2
	bne	@f
	lea	8(a5),a1	*データ転送なしケース
	bra	1f
@@:
	move.l	#ID_ZMD,d3
	Z_MUSIC	#ZM_GET_MEM
	tst.l	d0
	bmi	out_mem
	lea	8(a0),a1	*z_common_offsetから
@@:
	move.l	(a5)+,(a0)+
	subq.l	#4,d2
	bne	@b
1:
	Z_MUSIC	#ZM_PLAY_ZMD_SE
	bra	exit

stop_free_zmd:
reglist	reg	d0/d3/a0/a1
	tst.b	normal_play-zp_work(a6)
	bne	@f
	movem.l	reglist,-(sp)
	suba.l	a1,a1
	Z_MUSIC	#ZM_STOP

	move.l	#ID_ZMD,d3
	Z_MUSIC	#ZM_FREE_MEM2	*古いZMDを全部解放
	movem.l	(sp)+,reglist
@@:
	rts

case_ZDF:
	* < d3=size
	* < a5.l=data address
	bsr	read_lzz
	move.l	lzz_adr(pc),a3
	lea	bufadr(pc),a2
	pea	(a2)
	pea	(a5)
	jsr	_ref_data(a3)
	addq.w	#8,sp
	tst.l	d0
	bmi	lzz_err

	moveq.l	#0,d3
	move.l	d3,a5
	move.w	ZNumOfData(a2),d5
lzze_lp:
	move.l	ZSize(a2),-(sp)
	DOS	_MALLOC
	addq.w	#4,sp
	tst.l	d0
	bmi	out_mem		*OUT OF MEMORY
	move.l	d0,a1

	pea	(a1)		*push extract
	move.l	ZTopAdr(a2),-(sp)
	jsr	_ext_data(a3)
	addq.w	#8,sp
	tst.l	d0
	bmi	lzz_err

	move.w	ZKind(a2),d0	*get data type
	bne	lzze0		*ZMD以外なら
	move.l	ZSize(a2),d3	*get zmd size
	move.l	a1,a5		*get zmd addr.
	cmpi.w	#1,d5		*ZMDだけならば
	beq	do_exc_pl0	*メインへ帰還して演奏
	bsr	erase_zpd_mdd	*adpcm_block_data,midi_dumpをつぶす
	bra	lzze2
lzze0:				*ZMDデータ以外のものの実行
	movem.l	d3/a2/a5,-(sp)
	move.l	a1,a5
	move.l	ZSize(a2),d3
	lea	ZMS(pc),a2
	cmpi.b	#ZDF_ZMS,d0	*case:ZMS
	beq	lzze1
	cmpi.w	#ZDF_PCM,d0	*case:ZPD
	beq	lzze1
	cmpi.w	#$41,d0
	bne	unid_error_zdf		*わけわかんないファイルです。
	lea	MIDI(pc),a2
lzze1:
	bsr	self_output
	pea	(a1)
	DOS	_MFREE
	addq.w	#4,sp
	movem.l	(sp)+,d3/a2/a5
lzze2:
	lea	ZNext(a2),a2
	subq.w	#1,d5
	bne	lzze_lp
	tst.l	d3
	bne	do_exc_pl0
	bra	exit

erase_zpd_mdd:				*ZPD登録/MDD登録コマンドの書きつぶし
	* < d5.w=num of data
	* < a5.l=zmd address
	* < a2.l=bufadr
	movem.l	d0-d7/a0-a6,-(sp)
	lea	ZNext(a2),a2
	subq.w	#1,d5
ezm_lp:
	move.w	ZKind(a2),d0
	cmpi.w	#$20,d0
	bne	ezm1
	move.w	#$00_ff,zpd_scan-zp_work(a6)	*clr.b	zpd_scan-zp_work(a6)
						*st.b	mdd_scan-zp_work(a6)
	bra	ezm2
ezm1:
	cmpi.w	#$41,d0
	bne	unid_error_zdf			*わけわかんないファイルです。
	move.w	#$ff_00,zpd_scan-zp_work(a6)	*st.b	zpd_scan-zp_work(a6)
						*clr.b	mdd_scan-zp_work(a6)
ezm2:
	bsr	embed_with_dummy	*ダミーでかきつぶす
	lea	ZNext(a2),a2
	subq.w	#1,d5
	bne	ezm_lp
	movem.l	(sp)+,d0-d7/a0-a6
	rts

just_m_p:			*単にm_play()を実行する。
	Z_MUSIC	#ZM_PLAY2
	bra	exit

trk_play:
	bsr	get_trk_seq	*> a1.l=track_seqtbl
	Z_MUSIC	#ZM_PLAY
	bra	exit

.include	embeddmy.s

init_zmsc:
	bsr	chk_drv		*ドライバ常駐チェック
	bmi	no_drv		*ドライバが組み込まれてない
	moveq.l	#0,d1		*dummy
	Z_MUSIC	#ZM_INIT
	move.l	#ID_ZMD,d3
	Z_MUSIC	#ZM_FREE_MEM2	*ZMDメモリブロックの解放
	bra	exit

init_zmsc2:
	bsr	chk_drv		*ドライバ常駐チェック
	bmi	no_drv		*ドライバが組み込まれてない
	moveq.l	#0,d1		*dummy
	Z_MUSIC	#ZM_INIT
	move.l	#ID_ZMD,d3
	Z_MUSIC	#ZM_FREE_MEM2
	move.l	#ID_ZPD,d3
	Z_MUSIC	#ZM_FREE_MEM2
	move.l	#ID_ZPD_TBL,d3
	Z_MUSIC	#ZM_FREE_MEM2
	move.l	#ID_WAVE,d3
	Z_MUSIC	#ZM_FREE_MEM2
	move.l	#ID_WAVE_TBL,d3
	Z_MUSIC	#ZM_FREE_MEM2
	move.l	#ID_ERROR,d3
	Z_MUSIC	#ZM_FREE_MEM2
	move.l	#ID_FMSND,d3
	Z_MUSIC	#ZM_FREE_MEM2
	bra	exit

chk_ext_type:				*拡張子タイプの検査
	* < a2.l=filename address
	* > a2.l=出力先デバイス名
	* minus:mdd,mid or zpd (演奏データではない)
	* zero:zms or ???
	* X d0
reglist	reg	d0/a1
	movem.l	reglist,-(sp)
	move.l	a2,filename0-zp_work(a6)	*保存
	bsr	skip_peri2
cm_lp0
	move.b	(a2)+,d0
	beq	exit_cet
	cmpi.b	#'.',d0
	bne	cm_lp0
chk_mdd:
	move.l	a2,a1
	move.b	(a2)+,d0
	bsr	mk_capital
	cmpi.b	#'M',d0
	bne	chk_mid
	move.b	(a2)+,d0
	bsr	mk_capital
	cmpi.b	#'D',d0
	bne	chk_mid
	move.b	(a2)+,d0
	bsr	mk_capital
	cmpi.b	#'D',d0
	bne	chk_mid
yes_mid:
	lea	MIDI(pc),a2
	moveq.l	#-1,d0
	movem.l	(sp)+,reglist
	rts
chk_mid:
	move.l	a1,a2
	move.b	(a2)+,d0
	bsr	mk_capital
	cmpi.b	#'M',d0
	bne	chk_zpd
	move.b	(a2)+,d0
	bsr	mk_capital
	cmpi.b	#'I',d0
	bne	chk_zpd
	move.b	(a2)+,d0
	bsr	mk_capital
	cmpi.b	#'D',d0
	beq	yes_mid
chk_zpd:
	move.l	a1,a2
	move.b	(a2)+,d0
	bsr	mk_capital
	cmpi.b	#'Z',d0
	bne	exit_cet
	move.b	(a2)+,d0	*ZPD?
	bsr	mk_capital
	cmpi.b	#'P',d0
	bne	exit_cet
	move.b	(a2)+,d0
	bsr	mk_capital
	cmpi.b	#'D',d0
	bne	exit_cet
	moveq.l	#-1,d0
	lea	ZMS(pc),a2
	movem.l	(sp)+,reglist
	rts
exit_cet:
	moveq.l	#0,d0
	lea	ZMS(pc),a2
	movem.l	(sp)+,reglist
	rts

m_total:			*合計値計算
	* < a2.l=command line address
	bsr	chk_drv		*ドライバ常駐チェック
	bmi	no_drv		*ドライバが組み込まれてない
	Z_MUSIC	#ZM_GET_BUFFER_INFORMATION
	move.l	a0,_common_buffer-zp_work(a6)
m_ttlp00:
	move.b	(a2)+,d0
	beq	do_clc			*ファイル名無しの場合は…
	cmpi.b	#' ',d0
	bls	m_ttlp00
	subq.w	#1,a2

	bsr	get_org_fn
	lea	ZMD_kaku(pc),a1
	bsr	set_fn
	clr.b	retry-zp_work(a6)
exc_clc_opn:
	lea	filename(pc),a2
	bsr	fopen
	tst.l	d5
	bpl	do_ex_clc
	bsr	skip_peri2
excclc0:				*ZMDでだめならZMS
	move.b	(a2)+,d0
	beq	file_not_found2
	cmpi.b	#'.',d0
	bne	excclc0
	moveq.l	#0,d0
	move.b	retry(pc),d0
	cmpi.b	#3,d0
	bhi	file_not_found2
	add.w	d0,d0
	lea	kktbl(pc),a5
	move.w	(a5,d0.w),d0
	lea	(a5,d0.w),a5
	move.b	(a5)+,(a2)+
	move.b	(a5)+,(a2)+
	move.b	(a5)+,(a2)+
	addq.b	#1,retry-zp_work(a6)
	bra	exc_clc_opn
do_ex_clc:
	moveq.l	#0,d1		*dummy
	Z_MUSIC	#ZM_INIT
	move.l	#ID_ZMD,d3
	Z_MUSIC	#ZM_FREE_MEM2	*ZMDメモリブロックの解放
	bsr	read		*>d3:data size,a5=data address
	move.l	d3,d2		*d2.l=size
	cmpi.l	#'ZDF0',(a5)	*ZDF?
	beq	case_ZDF_clc
	cmpi.l	#ZmuSiC0,(a5)	*MDD OR ZMS
	bne	go_on_clc
	move.l	4(a5),d0
	clr.b	d0
	cmp.l	#ZmuSiC1,d0
	bne	unid_error
	cmpi.b	#$30,7(a5)
	bcs	version_error	*バージョン不適合
	bra	go_on_clc_zmd

go_on_clc:				*ZMSの演奏開始
	lea	filename(pc),a2
	bsr	chk_ext_type
	bmi	not_performance_data	*演奏データではない
	bsr	compile_zms		*> a5.l=zmd addr, d3=size
go_on_clc_zmd:				*ZMD演奏開始
	lea	8(a5),a1		*< a1.l=data address
	move.l	d3,d2
	Z_MUSIC	#ZM_PLAY_ZMD		*< d2.l=size
	tst.l	d0
	bne	exit
do_clc:
	moveq.l	#ZM_COMPILER,d1
	lea	-1.w,a1			*detect mode
	Z_MUSIC	#ZM_HOOK_FNC_SERVICE
	move.l	_common_buffer(pc),a1
	move.l	trk_buffer_top(a1),d0
	beq	exit
	move.l	d0,a1			*a1.l=現在演奏中のZMD ADDRESS
	cmpi.l	#ZmuSiC0,(a1)		*$1a,'Zmu'
	beq	@f
	move.l	z_zmd_size-8(a1),d2	*d2=zmd size
	bra	1f
@@:
	move.l	z_zmd_size(a1),d2	*d2=zmd size
1:
	move.l	a0,d0
	bne	@f
	bsr	call_calc_total		*コンパイラ起動して計算させる
	bra	exit
@@:					*常駐コンパイラを用いて計算させる
	Z_MUSIC	#ZM_CALC_TOTAL
	tst.l	d0
	bne	err_in_calc		*なんらかのエラーが発生したので計算は行なわれなかった
	bsr	disprslt		*結果のディスプレイ < d2.l=zmd size
	bra	exit

case_ZDF_clc:
	* < d3=size
	* < a5.l=data address
	bsr	read_lzz
	move.l	lzz_adr(pc),a3
	lea	bufadr(pc),a2
	pea	(a2)
	pea	(a5)
	jsr	_ref_data(a3)
	addq.w	#8,sp
	tst.l	d0
	bmi	lzz_err

	move.l	ZSize(a2),-(sp)
	DOS	_MALLOC
	addq.w	#4,sp
	tst.l	d0
	bmi	out_mem		*OUT OF MEMORY
	move.l	d0,a1

	pea	(a1)		*push extract
	move.l	ZTopAdr(a2),-(sp)
	jsr	_ext_data(a3)
	addq.w	#8,sp
	tst.l	d0
	bmi	lzz_err

	move.l	ZSize(a2),d3	*get zmd size
	move.l	a1,a5		*get zmd addr.
	move.w	ZKind(a2),d0	*get data type
	beq	go_on_clc_zmd	*メインへ帰還
	cmpi.w	#ZDF_ZMS,d0		*ZMS?
	beq	go_on_clc		*yes
	bra	not_performance_data	*no:演奏データではない

	.include	disprslt.s

free_mem:
	Z_MUSIC	#ZM_FREE_MEM
	rts

prta1_:
	pea	(a1)
	DOS	_PRINT
	addq.w	#4,sp
	rts

mask_tracks:			*トラック・マスク
	* < a2.l=command line address
	bsr	chk_drv		*ドライバ常駐チェック
	bmi	no_drv		*ドライバが組み込まれてない
msk_lp00:
	move.b	(a2)+,d0
	beq	reset_tr_mask
	cmpi.b	#' ',d0
	bls	msk_lp00
	subq.w	#1,a2

	bsr	chk_num		*数字?
	bmi	reset_tr_mask
	moveq.l	#-1,d3
	bsr	get_mask_trk
	Z_MUSIC	#ZM_MASK_TRACKS
	bra	exit

reset_tr_mask:			*mask取り消し
	moveq.l	#0,d1
	move.l	d1,a1
	Z_MUSIC	#ZM_MASK_TRACKS
	bra	exit

enable_tracks:			*トラック・マスク解除
	* < a2.l=command line address
	bsr	chk_drv		*ドライバ常駐チェック
	bmi	no_drv		*ドライバが組み込まれてない
slp_lp00:
	move.b	(a2)+,d0
	beq	reset_tr_mask
	cmpi.b	#' ',d0
	bls	slp_lp00
	subq.w	#1,a2

	bsr	chk_num		*数字?
	bmi	reset_tr_mask
	moveq.l	#0,d3		*enable
	bsr	get_mask_trk
	Z_MUSIC	#ZM_MASK_TRACKS
	bra	exit

get_mask_trk:			*トラック番号を取得してテーブルへ
	* < d3.w=mode
	* > a1.l=track_seqtbl
	* - all
reglist	reg	d1-d2/a0
	movem.l	reglist,-(sp)
	lea	track_seqtbl(pc),a0
	move.l	a0,a1
	moveq.l	#0,d2
gmt_lp:
	bsr	chk_num
	bmi	@f		*error case
	bsr	get_num
	subq.w	#1,d1
	cmpi.w	#tr_max-1,d1
	bhi	illegal_p
	move.w	d1,(a0)+	*track
	move.w	d3,(a0)+	*mode
	addq.w	#1,d2
	cmpi.w	#128,d2
	bhi	too_many_trks
	bsr	skip_sep
	bra	gmt_lp
@@:
	move.w	#-1,(a0)+
	movem.l	(sp)+,reglist
	rts

mask_ch:			*チャンネル・マスク
	* < a2.l=command line address
	bsr	chk_drv		*ドライバ常駐チェック
	bmi	no_drv		*ドライバが組み込まれてない
msk_lp01:
	move.b	(a2)+,d0
	beq	reset_ch_mask
	cmpi.b	#' ',d0
	bls	msk_lp01
	subq.w	#1,a2

	moveq.l	#-1,d3
	bsr	get_mask_ch
	Z_MUSIC	#ZM_MASK_CHANNELS
	bra	exit

reset_ch_mask:			*mask取り消し
	moveq.l	#0,d1
	move.l	d1,a1
	Z_MUSIC	#ZM_MASK_CHANNELS
	bra	exit

enable_ch:			*チャンネル・マスク解除
	* < a2.l=command line address
	bsr	chk_drv		*ドライバ常駐チェック
	bmi	no_drv		*ドライバが組み込まれてない
slp_lp01:
	move.b	(a2)+,d0
	beq	reset_ch_mask
	cmpi.b	#' ',d0
	bls	slp_lp01
	subq.w	#1,a2

	moveq.l	#0,d3		*enable
	bsr	get_mask_ch
	Z_MUSIC	#ZM_MASK_CHANNELS
	bra	exit

get_mask_ch:			*トラック番号を取得してテーブルへ
	* < d3.w=mode
	* > a1.l=track_seqtbl
	* - all
reglist	reg	d1-d2/a0
	movem.l	reglist,-(sp)
	lea	track_seqtbl(pc),a0
	move.l	a0,a1
	moveq.l	#0,d1
gmc_lp:
	bsr	skip_spc
	tst.b	(a2)
	beq	exit_gmc
	bsr	get_str_ch	*>d2.l=device code
	move.l	d2,(a0)+	*track
	move.w	d3,(a0)+	*mode
	addq.w	#1,d1
	cmpi.w	#128,d1
	bhi	too_many_trks
	bsr	skip_sep
	bra	gmc_lp
exit_gmc:
	move.l	#-1,(a0)+
	movem.l	(sp)+,reglist
	rts

output_level_tracks:		*出力設定
	* < a2.l=command line address
	bsr	chk_drv		*ドライバ常駐チェック
	bmi	no_drv		*ドライバが組み込まれてない
sopl_lp00:
	move.b	(a2)+,d0
	beq	reset_sopl
	cmpi.b	#' ',d0
	bls	sopl_lp00
	subq.w	#1,a2

	bsr	chk_num		*数字?
	bmi	reset_sopl

	bsr	get_num		*get level
	bsr	skip_sep
	bsr	chk_num
	bpl	@f
	lea	track_seqtbl(pc),a0	*全トラック設定ケース
	move.l	a0,a1
	move.l	#$ffff_03_00,(a0)+	*-1:all,03=omt,00=dummy speed
	clr.b	(a0)+			*00=dummy speed
	move.b	d1,(a0)+
	move.b	d1,(a0)+
	Z_MUSIC	#ZM_SET_TR_OUTPUT_LEVEL
	bra	exit
@@:					*設定ケース
	move.l	d1,d3
	bsr	get_otptlv_trk		*>a1.l=trk seq.
	bmi	exit
	Z_MUSIC	#ZM_SET_TR_OUTPUT_LEVEL
	bra	@b

reset_sopl:
	lea	track_seqtbl(pc),a0
	move.l	a0,a1
	move.l	#$ffff_03_00,(a0)+	*-1:all,03=omt,00=dummy
	move.l	#$80<<16+$80<<8,(a0)+
	Z_MUSIC	#ZM_SET_TR_OUTPUT_LEVEL
	bra	exit

get_otptlv_trk:			*トラック番号を取得してテーブルへ
	* < d3.w=level
	* > a1.l=track_seqtbl
	* > minus:error
	* - all
reglist	reg	d1/a0
	movem.l	reglist,-(sp)
	lea	track_seqtbl(pc),a0
	move.l	a0,a1
	bsr	chk_num
	bmi	@f		*error case
	bsr	get_num
	subq.w	#1,d1
	cmpi.w	#tr_max-1,d1
	bhi	illegal_p
	move.w	d1,(a0)+	*track
	bsr	skip_sep
	move.b	#3,(a0)+	*omt
	clr.b	(a0)+		*speed
	clr.b	(a0)+
	move.b	d3,(a0)+	*start
	move.b	d3,(a0)+	*end
	moveq.l	#0,d1		*zero flag on
@@:
	movem.l	(sp)+,reglist
	rts

output_level_ch:		*チャンネル出力設定
	* < a2.l=command line address
	bsr	chk_drv		*ドライバ常駐チェック
	bmi	no_drv		*ドライバが組み込まれてない
csopl_lp00:
	move.b	(a2)+,d0
	beq	reset_csopl
	cmpi.b	#' ',d0
	bls	csopl_lp00
	subq.w	#1,a2

	bsr	chk_num		*数字?
	bmi	reset_csopl

	bsr	get_num		*get level
	bsr	skip_sep
	tst.b	(a2)
	bne	@f
	lea	track_seqtbl(pc),a0	*全チャンネル設定ケース
	move.l	a0,a1
	move.l	#$ffff_ffff,(a0)+	*-1:all device,-1:all ch
	move.w	#$03_00,(a0)+		*omt,spd_h=0
	move.w	d1,(a0)+		*spd_l=0,start
	move.b	d1,(a0)+		*end
	Z_MUSIC	#ZM_SET_CH_OUTPUT_LEVEL
	bra	exit
@@:					*設定ケース
	move.l	d1,d3
	bsr	get_otptlv_ch		*>a1.l=trk seq.
	bmi	exit
	Z_MUSIC	#ZM_SET_CH_OUTPUT_LEVEL
	bra	@b

reset_csopl:
	lea	track_seqtbl(pc),a0
	move.l	a0,a1
	move.l	#$ffff_ffff,(a0)+	*-1:all,03=omt,00=dummy
	move.l	#$03_0000_80,(a0)+
	move.b	#$80,(a0)+
	Z_MUSIC	#ZM_SET_CH_OUTPUT_LEVEL
	bra	exit

get_otptlv_ch:			*チャンネル番号を取得してテーブルへ
	* < d3.w=level
	* > a1.l=track_seqtbl
	* > minus:error
	* - all
reglist	reg	d1-d2/a0
	movem.l	reglist,-(sp)
	lea	track_seqtbl(pc),a0
	move.l	a0,a1
	tst.b	(a2)
	beq	err_exit_goc
	bsr	get_str_ch	*>d2.l=device code
	move.l	d2,(a0)+	*device
	move.b	#3,(a0)+	*omt
	clr.b	(a0)+		*speed
	clr.b	(a0)+
	move.b	d3,(a0)+	*start
	move.b	d3,(a0)+	*end
	bsr	skip_sep
	moveq.l	#0,d1		*zero flag on
	movem.l	(sp)+,reglist
	rts
err_exit_goc:
	moveq.l	#-1,d1		*minus flag on
	movem.l	(sp)+,reglist
	rts

get_str_ch:				*文字でチャンネルアサイン
	* < (a2)=str addr.
	* > (a2)=next
	* > d2.l=typ,ch value
	* - all
	movem.l	d0-d1,-(sp)
	moveq.l	#0,d1
	bsr	skip_spc
	move.b	(a2)+,d0
	beq	illegal_ch
	andi.b	#$df,d0
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
	bcs	illegal_ch
	cmpi.l	#15,d1
	bhi	illegal_ch
	bra	gsc00
@@:				*チャンネル番号省略ケース
	move.b	adpcm_default_ch-zp_work(a6),d1
	addq.b	#1,adpcm_default_ch-zp_work(a6)
gsc00:
	moveq.l	#1,d2
	swap	d2
	move.w	d1,d2
	movem.l	(sp)+,d0-d1
	rts
gsc_case_fm:			*FM
	bsr	srch_num
	bmi	illegal_ch
	bsr	get_num
	subq.l	#1,d1
	bcs	illegal_ch
	cmpi.l	#7,d1
	bhi	illegal_ch
	move.l	d1,d2
	movem.l	(sp)+,d0-d1
	rts
gsc_case_md:
	move.l	#-1,d2		*default type(-1 means current)
	cmpi.b	#'M',d0
	bne	illegal_if
	bsr	srch_num
	bmi	illegal_ch
	bsr	get_num
	bsr	skip_spc
	move.b	(a2),d0		*前のパラメータがインターフェース番号で
	beq	illegal_ch
	cmpi.b	#':',d0		*今度の数値がチャンネル番号?
	beq	@f
	cmpi.b	#'-',d0
	bne	mdch_chk_gsc
@@:				*get ch num
	addq.w	#1,a2
	bsr	chk_num
	bmi	illegal_ch
	move.l	d1,d2		*save I/F to d2
	bsr	get_num		*get ch no.(有効範囲は後でチェック
	subq.l	#1,d2
	bcs	illegal_if
	cmpi.l	#if_max-1,d2
	bhi	illegal_if
	ori.w	#$8000,d2
	swap	d2
mdch_chk_gsc:
	subq.l	#1,d1
	bcs	illegal_ch
	cmpi.l	#15,d1
	bhi	illegal_ch
	move.w	d1,d2
	movem.l	(sp)+,d0-d1
	rts

srch_num:			*数字までスキップ
	* X d0
	move.w	d0,-(sp)
srch_num_lp:
	move.b	(a2)+,d0
	beq	@f		*コマンドの途中でファイルの最後に来た
	cmpi.b	#'{',d0
	beq	sn_err		*コマンドの途中で改行
	cmpi.b	#'}',d0
	beq	sn_err
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
	subq.w	#1,a2
	move.w	(sp)+,d0
	move.w	#CCR_ZERO,ccr
	rts
sn_err:
	subq.w	#1,a2
@@:
	move.w	(sp)+,d0
	move.w	#CCR_NEGA,ccr
	rts

kakuchoshi:			*拡張子を設定
	* < a0=filename address
	* < a2=拡張子アドレス
	* X a0
	bsr	skip_peri0
	moveq.l	#fn_size-1,d0
kkchs_lp:
	move.b	(a0)+,d0
	beq	do_kkchs
	cmpi.b	#'.',d0
	beq	find_period
	dbra	d0,kkchs_lp
do_kkchs:
	subq.l	#1,a0
	move.b	#'.',(a0)+
	move.b	(a2)+,(a0)+
	move.b	(a2)+,(a0)+
	move.b	(a2)+,(a0)+
	clr.b	(a0)
	rts
find_period:
	cmpi.b	#' ',(a0)
	bls	do_kkchs	*'.'はあっても拡張子がないケース
	rts

get_org_fn:
	movem.l	a0/a2,-(sp)
	lea	org_fn(pc),a0
gef0:
	move.b	(a2)+,(a0)+
	bne	gef0
	movem.l	(sp)+,a0/a2
	rts

set_fn:				*ファイルネームのセット
	* < a1.l=拡張子source	*拡張子の種別をかえす
	* < a2.l=source filename
	* > d0.lw=last chr
	* > d0.hw=拡張子タイプ(0-6,-1)
	movem.l	d1/a0/a1-a3,-(sp)
	lea	filename(pc),a0
@@:
	cmpi.b	#'.',(a2)
	bne	@f
	move.b	(a2)+,(a0)+
	bra	@b
@@:
	clr.b	d1
setfnlp:
	move.b	(a2)+,d0
	cmpi.b	#'.',d0
	bne	chk_sp_
	st.b	d1
	lea	1(a0),a3	*拡張子の３文字が存在するアドレス
chk_sp_:
	cmpi.b	#' ',d0
	bls	exit_setfn
	cmpi.b	#',',d0
	beq	exit_setfn
	move.b	d0,(a0)+
	bra	setfnlp
exit_setfn:
	tst.b	d1		*拡張子省略かどうか
	bne	set_edc_	*省略しなかった
	move.b	#'.',(a0)+	*拡張子をセット
	move.l	a0,a3
	move.b	(a1)+,(a0)+
	move.b	(a1)+,(a0)+
	move.b	(a1)+,(a0)+
set_edc_:
	clr.b	(a0)
	lea	ext_tbl(pc),a1
	move.l	a3,a2
	move.w	d0,-(sp)
	bsr	get_com_no2
	swap	d0
	move.w	(sp)+,d0	*d0.hw=ext type,d0.lw=last chr
	movem.l	(sp)+,d1/a0/a1-a3
	rts

reglist	reg	d1-d2
get_com_no2:			*コマンド文字列->数値変換
	* < a1=com_tbl
	* < a2=source
	* > d0=#cmd number
	* minus error
	* X a1,a3
	movem.l	reglist,-(sp)
	bsr	skip_spc	
	moveq.l	#0,d2
wc_lp01:
	tst.b	(a1)
	bmi	exit_err_wc
	bsr	do_get_cmd_num2
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

do_get_cmd_num2:		*実際に文字列を捜す
	* < a1=source str addr
	* > eq=get it!
	* > mi=can't found
	move.l	a1,-(sp)
	move.l	a2,d1		*save a2 to d1
@@:
	move.b	(a2)+,d0
	beq	not_same_dgscn2	*途中で終わった
	jsr	mk_capital-zp_work(a6)	*小文字→大文字
	cmp.b	(a1)+,d0
	bne	not_same_dgscn2
	tst.b	(a1)		*終了
	bne	@b
	move.l	(sp)+,a1
	moveq.l	#0,d0		*right!
	rts
not_same_dgscn2:
	move.l	d1,a2		*get back a2
	move.l	(sp)+,a1
	moveq.l	#-1,d0		*error!
	rts

set_fn2:			*ファイルネームのセット(case:juke box)
	* < a2.l=source		*拡張子省略したら拡張子セット
	* > d0.b=last chr
	bsr	skip_peri2
	movem.l	d1/a0,-(sp)
	lea	filename(pc),a0
	clr.b	d1
setfn2lp:
	move.b	(a2)+,d0
	cmpi.b	#'.',d0
	bne	chk_sp_2
	st.b	d1
chk_sp_2:
	cmpi.b	#' ',d0
	bls	exit_setfn2
	cmpi.b	#',',d0
	beq	exit_setfn2
	move.b	d0,(a0)+
	bra	setfn2lp
exit_setfn2:
	tst.b	d1		*拡張子省略かどうか
	bne	set_edc_2	*省略しなかった
	move.b	#'.',(a0)+	*拡張子をセット
	move.b	#'Z',(a0)+
	move.b	#'M',(a0)+
	move.b	#'D',(a0)+
set_edc_2:
	clr.b	(a0)
	movem.l	(sp)+,d1/a0
	rts

set_stup:
	* < a2.l=command line address
	* > d0.b=last chr
	* X a0
	move.l	sfp(pc),a0
setsulp:
	move.b	(a2)+,d0
	cmpi.b	#' ',d0
	bls	exit_setsu
	cmpi.b	#',',d0
	beq	exit_setsu
	move.b	d0,(a0)+
	bra	setsulp
exit_setsu:
	clr.b	(a0)
	rts

m_stop:				*演奏停止
	bsr	chk_drv		*ドライバ常駐チェック
	bmi	no_drv		*ドライバが組み込まれてない

	bsr	chk_num	*数字?
	bpl	trk_stop

	suba.l	a1,a1		*m_stop_all
	Z_MUSIC	#ZM_STOP	*m_stop
	bra	exit

trk_stop:
	bsr	get_trk_seq	*> a1.l=track_seqtbl
	Z_MUSIC	#ZM_STOP
	bra	exit

m_cont:				*演奏停止
	bsr	chk_drv		*ドライバ常駐チェック
	bmi	no_drv		*ドライバが組み込まれてない

	bsr	chk_num	*数字?
	bpl	trk_cont

	suba.l	a1,a1		*m_cont_all
	Z_MUSIC	#ZM_CONT	*m_cont
	bra	exit

trk_cont:
	bsr	get_trk_seq	*> a1.l=track_seqtbl
	Z_MUSIC	#ZM_CONT
	bra	exit

fadeout:			*fadeout
	bsr	chk_drv		*ドライバ常駐チェック
	bmi	no_drv		*ドライバが組み込まれてない

	bsr	chk_num		*数字?
	bpl	get_f_spd
	move.w	#$00_80,d2		*end=$00,start=$80
	moveq.l	#fader_dflt_spd,d1	*deafult speed
	bra	gfs00

get_f_spd:
	bsr	get_num
	move.w	#$00_80,d2		*end=$00,start=$80
	tst.l	d1
	bne	@f
	move.w	#$80_80,d2
	bra	gfs00
@@:
	bpl	@f
	neg.l	d1
	move.w	#$80_00,d2		*end=$80,start=$00
@@:
	cmpi.l	#255,d1			*check speed
	bhi	illegal_fader_speed
gfs00:
	lea	track_seqtbl(pc),a1	*param. tbl
	move.l	a1,a0
	move.w	#-1,(a0)+		*all
	move.b	#%0000_0111,(a0)+
	move.b	d1,(a0)+
	clr.b	(a0)+
	move.b	d2,(a0)+		*start level
	rol.w	#8,d2			*end level
	move.b	d2,(a0)+
	Z_MUSIC	#ZM_MASTER_FADER
	bra	exit

	dc.b	'独立'
zmint_entry:
	move.l	a0,-(sp)
	lea	zmint_count(pc),a0
	addq.l	#1,(a0)
	move.l	(sp)+,a0
	rts

self_record:
	bsr	chk_drv		*ドライバ常駐チェック
	bmi	no_drv		*ドライバが組み込まれてない
	st.b	self_rec_mode-zp_work(a6)
	move.w	#RTS,exit-zp_work(a6)
	bsr	cache_flush
	move.l	a2,reg_buf-zp_work(a6)
	bra	1f

midi_input:			*MIDIデータの取り込み
	* < a2.l=command line address
	bsr	chk_drv		*ドライバ常駐チェック
	bmi	no_drv		*ドライバが組み込まれてない
	clr.b	self_rec_mode-zp_work(a6)
m_oplp00:
	move.b	(a2)+,d0
	bne	@f
1:
	lea	dummy_bmd(pc),a2	*ダミーファイルネーム
	bra	1f
@@:
	cmpi.b	#' ',d0
	bls	m_oplp00
	subq.w	#1,a2
1:
	lea	MID_kaku(pc),a1
	bsr	set_fn

	lea	filename(pc),a0
	lea	bmdoutname(pc),a1
@@:
	move.b	(a0)+,(a1)+
	bne	@b

	move.l	#192*65536+200,d1	*mst_clk=192,テンポ=200
	lea	zmint_entry(pc),a1
	Z_MUSIC	#ZM_SET_INT_SERVICE
	tst.l	d0
	bne	other_prog		*既に他のプログラムが使用中
	st.b	ocpy_int_service-zp_work(a6)

	pea	$ffff.w			*最大確保
	DOS	_MALLOC
	addq.w	#4,sp
	andi.l	#$00ffffff,d0
	tst.b	self_rec_mode-zp_work(a6)
	beq	@f
	lsr.l	#1,d0			*自己記録モード時は最大メモリの半分を確保
@@:					*(残りは演奏曲データバッファ用として取っておく)
	move.l	d0,d4
	move.l	d0,-(sp)
	DOS	_MALLOC
	addq.l	#4,sp
	move.l	d0,midi_rec_buf-zp_work(a6)
	bmi	out_mem
	move.l	d0,a4			*バッファアドレス
	add.l	a4,d4			*最終アドレス
	move.l	#'MThd',(a4)+		*header
	move.l	#$0000_0006,(a4)+	*header size
	move.l	#$0000_0001,(a4)+	*format 0
	move.w	#$0030,(a4)+		*分解能48
	move.l	#'MTrk',(a4)+		*track header
	clr.l	(a4)+

	lea	rec_st_mes(pc),a1
	bsr	bil_prta1

	moveq.l	#-1,d1			*move.l	if_number(pc),d1	*I/F number 0-2,-1
	Z_MUSIC	#ZM_MIDI_REC
	lea	zmint_count(pc),a1
	move.l	(a1),d3			*初期値
	move.l	d3,d6
	moveq.l	#0,d5			*work reg.(最上位ビットはあふれフラグとして使用)
	moveq.l	#0,d7
	move.l	#$00ff_5103,(a4)+	*テンポイベント
	move.w	#$0493,(a4)+		*$0493e0=tempo 200
	move.b	#$e0,(a4)+
	move.l	a4,a2
	clr.b	(a4)+			*delta=00
	move.l	#$f7_8080_80,(a4)+	*event=$f7,count.hw=$8080,count.lw=$80_**
	clr.b	(a4)+			*count.lw=$**_00
	move.l	a4,a3
minplp00:				*SMF作成ルーチンスタート
	moveq.l	#-1,d2
	tst.b	self_rec_mode-zp_work(a6)
	beq	@f
	bmi	1f
	movem.l	d1/a0-a1,-(sp)
	moveq.l	#0,d1
	move.l	d1,a1			*d1=a1=0
	Z_MUSIC	#ZM_PLAY_STATUS
	movem.l	(sp)+,d1/a0-a1
	move.l	d0,d2			*1:演奏中 0:演奏終了
	bra	@f
1:
	bclr.b	#7,self_rec_mode-zp_work(a6)
	movem.l	d0-d7/a0-a6,-(sp)
	move.l	reg_buf(pc),a2
	bsr	m_play
	move.w	#NOP,exit-zp_work(a6)
	bsr	cache_flush
	movem.l	(sp)+,d0-d7/a0-a6
@@:
	bitsns	$0
	btst.l	#1,d0
	bne	rec_exit
	move.l	(a1),d0
	sub.l	d3,d0			*デルタタイム発生か
*	beq	1f
					*デルタタイム発生
	tst.l	d7			*データ有ったか
	bne	@f
					*データがないならば
	add.l	d3,d0			*元通りにして
	move.l	d6,d3			*前のタイマ値にして
	move.l	a2,a4			*アドレスも戻して
	sub.l	d3,d0			*デルタタイム再計算
	tst.l	d2
	bne	set_delta
	cmp.l	#192,d0			*演奏が終了してなんのデータ受信もないならば
	bhi	rec_exit		*しばらくして受信処理自動終了
	bra	set_delta
@@:
	moveq.l	#4-1,d1			*データカウント数書き込み
@@:
	move.l	d7,d2
	andi.b	#$7f,d2
	or.b	d2,-(a3)
	lsr.l	#7,d7
	dbra	d1,@b
set_delta:
	move.l	a4,a2			*preserve
	bsr	setval			*set delta time
	move.l	d3,d6			*preserve
	add.l	d0,d3
	cmp.l	a4,d4
	bls	out_mem
	move.b	#$f7,(a4)+		*F7 Stat
	cmp.l	a4,d4
	bls	out_mem
	move.b	#$80,(a4)+		*length
	cmp.l	a4,d4
	bls	out_mem
	move.b	#$80,(a4)+
	cmp.l	a4,d4
	bls	out_mem
	move.b	#$80,(a4)+
	cmp.l	a4,d4
	bls	out_mem
	clr.b	(a4)+
	move.l	a4,a3			*backup
	moveq.l	#0,d7			*count
1:
	moveq.l	#-1,d1			*move.l	if_number(pc),d1	*I/F number 0-2,-1
	moveq.l	#0,d2			*MIDI_INP1 (single mode ID)
	Z_MUSIC	#ZM_MIDI_INP1
	tst.w	d0			*データ無し
	bmi	minplp00
	tst.l	d0
	bpl	@f
	bset.l	#31,d5			*dropマーク
@@:					*データ有り
	cmp.l	a4,d4
	bls	out_mem
	move.b	d0,(a4)+
	addq.l	#1,d7
	bra	minplp00
rec_exit:
	move.l	(a1),d0
	sub.l	d3,d0			*d0.l=delta
*!2/10	beq	1f
					*デルタタイム発生
	tst.l	d7			*データ有ったか
	bne	@f
					*データがないならば
	add.l	d3,d0			*元通りにして
	move.l	d6,d3			*前のタイマ値にして
	move.l	a2,a4			*アドレスも戻して
	sub.l	d3,d0			*デルタタイム再計算
	bra	1f
@@:
	moveq.l	#4-1,d1			*データカウント数書き込み
@@:
	move.l	d7,d2
	andi.b	#$7f,d2
	or.b	d2,-(a3)
	lsr.l	#7,d7
	dbra	d1,@b
1:					*end of track書き込み
	move.l	a4,a2			*preserve
	bsr	setval
	cmp.l	a4,d4
	bls	out_mem
	st.b	(a4)+			*#$ff
	cmp.l	a4,d4
	bls	out_mem
	move.b	#$2f,(a4)+
	cmp.l	a4,d4
	bls	out_mem
	clr.b	(a4)+			*$00
	move.l	a4,a2
	bsr	init_kbuf

	moveq.l	#0,d1
	lea	zmint_entry(pc),a1
	Z_MUSIC	#ZM_SET_INT_SERVICE
	clr.b	ocpy_int_service-zp_work(a6)

	tst.l	d5
	bmi	data_drop_err		*読みこぼした

	moveq.l	#-1,d1			*move.l	if_number(pc),d1
	Z_MUSIC	#ZM_MIDI_REC_END

	bsr	optmz_rcdt0

	move.l	midi_rec_buf(pc),a4
	sub.l	a4,a2		*data count
	move.l	a2,d0
	cmpi.l	#22+7,d0	*#22=header size分,#7=tempo size分
	bls	no_data_rec	*なにも記録されていない
	sub.l	#22,d0
	move.l	d0,18(a4)	*track data length
				*ファイルの書き出し
	lea	saving_mes(pc),a1	*書き出し中
	bsr	bil_prta1
	lea	bmdoutname(pc),a1
	bsr	prta1
	lea	CRLF(pc),a1
	bsr	prta1

	move.w	#32,-(sp)
	pea	bmdoutname(pc)
	DOS	_CREATE
	addq.w	#6,sp
	move.l	d0,d5		*d5.w=file handle
	bmi	write_err

	pea	(a2)		*data size
	pea	(a4)		*data addr
	move.w	d5,-(sp)
	DOS	_WRITE
	lea	10(sp),sp
	cmp.l	a2,d0
	bne	write_err

	move.w	d5,-(sp)
	DOS	_CLOSE
	addq.w	#2,sp

	bra	exit

optmz_rcdt0:				*データ最適化 PASS1
	* < a2.l=end addr
	* > a2.l=end addr
	move.l	a2,d4			*データの最後尾
	move.l	midi_rec_buf(pc),a4	*src
	add.w	#22+7,a4		*#22=header size分,#7=tempo size分
	move.l	a4,a2			*dest
minpoptlp:				*最適化処理
	cmp.l	a4,d4
	bls	1f
	bsr	getval
	bsr	setval2		*delta time
	move.b	(a4)+,d0
	move.b	d0,(a2)+	*event
	cmpi.b	#$ff,d0
	bne	@f
	move.b	(a4)+,(a2)+	*meta event number
@@:
	bsr	getval
	bsr	setval2		*count
	tst.l	d0
	beq	minpoptlp
@@:
	move.b	(a4)+,(a2)+
	subq.l	#1,d0
	bne	@b
	bra	minpoptlp
1:
	rts

getval:
	* > d0.l=data
	* - all
	move.l	d1,-(sp)
	moveq.l	#0,d0
	moveq.l	#0,d1
	move.b	(a4)+,d1
	bpl	1f
@@:
	andi.b	#$7f,d1
	or.b	d1,d0
	lsl.l	#7,d0
	move.b	(a4)+,d1
	bmi	@b
1:
	or.b	d1,d0
	move.l	(sp)+,d1
	rts

setval:
	* < d0.l=data
	* - all
	movem.l	d0-d1,-(sp)
	moveq.l	#4-1,d1
	rol.l	#4,d0
1:
	rol.l	#7,d0
	andi.b	#$7f,d0
	bne	@f
	tst.l	d1
	bgt	2f
@@:
	bset.l	#31,d1
	tst.w	d1
	beq	@f
	tas.b	d0
@@:
	cmp.l	a4,d4
	bls	out_mem
	move.b	d0,(a4)+
2:
	dbra	d1,1b
	movem.l	(sp)+,d0-d1
	rts

setval2:
	* < d0.l=data
	* - all
	movem.l	d0-d1,-(sp)
	moveq.l	#4-1,d1
	rol.l	#4,d0
1:
	rol.l	#7,d0
	andi.b	#$7f,d0
	bne	@f
	tst.l	d1
	bgt	2f
@@:
	bset.l	#31,d1
	tst.w	d1
	beq	@f
	tas.b	d0
@@:
	move.b	d0,(a2)+
2:
	dbra	d1,1b
	movem.l	(sp)+,d0-d1
	rts

init_kbuf:			*キーバッファクリア
	move.l	d0,-(sp)
	clr.w	-(sp)
	DOS	_KFLUSH
	addq.w	#2,sp
	move.l	(sp)+,d0
	rts

midi_send:			*MIDIデータの楽器への転送
	* < a2.l=command line address
	bsr	chk_drv		*ドライバ常駐チェック
	bmi	no_drv		*ドライバが組み込まれてない
m_sdlp00:
	move.b	(a2)+,d0
	beq	print_hlp	*ファイル名無しの場合は…
	cmpi.b	#' ',d0
	bls	m_sdlp00
	subq.w	#1,a2

	lea	MID_kaku(pc),a1
	bsr	set_fn

	lea	trns_mes(pc),a1
	bsr	bil_prta1

	lea	filename(pc),a2
	bsr	fopen
	tst.l	d5
	bmi	file_not_found
	bsr	read
	lea	MIDI(pc),a2
	pea	exit(pc)

self_output:
	* < a2=output device name
	* < d3=size
	* < a5=data address
	* - all
reglist	reg	d0/d5/a0-a1
	movem.l	reglist,-(sp)

	moveq.l	#ZM_COMPILER,d1
	lea	-1.w,a1			*detect mode
	Z_MUSIC	#ZM_HOOK_FNC_SERVICE
	move.l	a0,d0
	bne	@f			*常駐しているコンパイラを利用
	lea	MIDI(pc),a0
	cmp.l	a2,a0
	beq	@f			*'MIDI'や
	cmp.b	#$1a,(a5)		*オブジェクトならば自己出力
	bls	@f
	bsr	compile_zms		*ZMSならばコンパイラでコンパイル
@@:					*< d3:data size,a5=data address
	move.w	#%0_000_01,-(sp)	*zmusicへ出力しちゃう
	pea	(a2)
	DOS	_OPEN
	addq.w	#6,sp
	move.l	d0,d5		*d5.w=file handle

	move.l	d3,-(sp)	*size
	pea	(a5)		*data address
	move.w	d5,-(sp)
	DOS	_WRITE
	lea	10(sp),sp

	move.w	d5,-(sp)
	DOS	_CLOSE
	addq.w	#2,sp

	movem.l	(sp)+,reglist
	rts

compile_zms:				*アドレス指定によるコンパイル
	* < (filename0)には便宜上のソースファイル名
	* < a5.l=zms address
	* < d3.l=size
	* > a5.l=zmd address
	* > d3.l=size
reglist	reg	d0-d2/a0-a2
	movem.l	reglist,-(sp)

	moveq.l	#ZM_COMPILER,d1
	lea	-1.w,a1			*detect mode
	Z_MUSIC	#ZM_HOOK_FNC_SERVICE
	move.l	a0,d0
	bne	use_linked_compiler

	bsr	make_temp_name

	move.w	d0,-(sp)
	DOS	_CLOSE
	addq.w	#2,sp

	lea	zmc_cmd(pc),a1
	move.l	#'ZMC ',(a1)+
	tst.b	lang-zp_work(a6)
	beq	@f
	move.b	#'-',(a1)+
	move.b	#'J',(a1)+
	move.b	#' ',(a1)+
@@:
	moveq.l	#-1,d1
	Z_MUSIC	#ZM_ZMUSIC_MODE
	cmpi.l	#2,d0
	bne	@f
*	tst.b	v2_compatch-zp_work(a6)
*	beq	@f
	move.b	#'-',(a1)+
	move.b	#'2',(a1)+
	move.b	#' ',(a1)+
@@:
	move.b	#'-',(a1)+		*なし
	move.b	#'G',(a1)+
	move.b	#' ',(a1)+
	move.b	#'-',(a1)+
	move.b	#'!',(a1)+
	move.l	a5,d0
	bsr	num_to_str		*address
	lea	suji(pc),a0
@@:
	move.b	(a0)+,(a1)+
	bne	@b
	move.b	#',',-1(a1)		*区切りspc
	move.l	d3,d0
	bsr	num_to_str		*address
	lea	suji(pc),a0
@@:
	move.b	(a0)+,(a1)+
	bne	@b
	move.b	#' ',-1(a1)		*区切りspc
zz:
	move.l	filename0(pc),a0
@@:
	move.b	(a0)+,(a1)+
	bne	@b			*ソースファイル名(便宜上)

	move.b	#' ',-1(a1)		*区切りspc

	lea	temp_name(pc),a0
@@:
	move.b	(a0)+,(a1)+
	bne	@b			*オブジェクト名

	bsr	call_zmc
	tst.l	d0
	bne	err_in_zmc		*コンパイル失敗

	pea	(a5)			*ZMSは捨てる
	DOS	_MFREE
	addq.w	#4,sp

	lea	temp_name(pc),a2
	bsr	fopen
	tst.l	d5
	bmi	temp_file_err
	bsr	read			*> d3:data size,a5=data address

	pea	temp_name(pc)
	DOS	_DELETE			*テンポラリ削除
	addq.w	#4,sp

	clr.b	temp_flg-zp_work(a6)

	movem.l	(sp)+,reglist
	rts

use_linked_compiler:			*常駐中のコンパイラを使ってZMSをコンパイル
	moveq.l	#0,d1
	move.l	d3,d2
	move.l	a5,a1
	Z_MUSIC	#ZM_COMPILER		*コンパイル実行ルーチンへ
	tst.l	d0
	bne	err_in_zmc		*エラーがあった
	move.l	a0,d0
	beq	err_in_zmc		*エラーがあった
	move.l	a0,a5			*zmd address
	moveq.l	#0,d3			*zmd dummy size

	pea	(a1)			*ZMSは捨てる
	DOS	_MFREE
	addq.w	#4,sp

	move.l	a0,a1
	Z_MUSIC	#ZM_CALC_TOTAL

	tst.l	d0			*97/4/16
	bne	@f			*なんらかのエラーが発生したので計算は行なわれなかった
	move.l	a0,a1
	Z_MUSIC	#ZM_FREE_MEM
@@:
	movem.l	(sp)+,reglist
	rts

call_calc_total:			*ステップタイム等の計算
	* < a1.l=zmd address
	* < d2.l=zmd size
	movem.l	d0/a0-a2,-(sp)

	lea	zmc_cmd(pc),a0
	move.l	#'ZMC ',(a0)+
	move.l	#'-#  ',(a0)+
	move.l	a1,d0
	bsr	num_to_str		*address
	lea	suji(pc),a1
@@:
	move.b	(a1)+,(a0)+
	bne	@b
	move.b	#',',-1(a0)		*区切りspc

	move.l	d2,d0
	bsr	num_to_str		*size
	lea	suji(pc),a1
@@:
	move.b	(a1)+,(a0)+
	bne	@b
	move.b	#' ',-1(a0)		*区切りspc

	lea	filename(pc),a1
@@:
	move.b	(a1)+,(a0)+
	bne	@b			*コンパイラの実行

	bsr	call_zmc
	tst.l	d0
	bne	err_in_zmc		*コンパイル失敗

	movem.l	(sp)+,d0/a0-a2
	rts

call_zmc:				*コンパイラの実行
	* < (zmc_cmd)=コマンドライン
	movem.l	d1-d7/a0-a7,reg_buf-zp_work(a6)
	clr.l	-(sp)
	pea	track_seqtbl(pc)	*使い捨てバッファ
	pea	zmc_cmd(pc)		*filename
	move.w	#2,-(sp)		*mode
	DOS	_EXEC
	tst.l	d0
	bmi	no_zmc_err		*ZMCがない
	addq.w	#2,sp
	clr.w	-(sp)			*mode
	DOS	_EXEC
	lea	14(sp),sp
	movem.l	reg_buf(pc),d1-d7/a0-a7
	rts

ZMS:		dc.b	'ZMS',0
MIDI:		dc.b	'MIDI',0
	.even

get_trk_seq:			*トラック番号を取得してテーブルへ
	* > a1.l=track_seqtbl
	* - all
reglist	reg	d1-d2
	movem.l	reglist,-(sp)
	lea	track_seqtbl(pc),a1
	moveq.l	#0,d2
bps_lp:
	bsr	chk_num
	bmi	exit_bps
	bsr	get_num
	subq.w	#1,d1
	cmpi.w	#tr_max-1,d1
	bhi	illegal_p
	addq.w	#1,d2
	cmpi.w	#128,d2
	bhi	too_many_trks
	move.w	d1,(a1)+
	bsr	skip_sep
	bra	bps_lp
exit_bps:
	move.w	#-1,(a1)+
	lea	track_seqtbl(pc),a1
	movem.l	(sp)+,reglist
	rts

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

mk_capital:			*小文字→大文字(英字以外の場合はそのままthrough out)
	* < d0.b=letter chr
	cmpi.b	#'a',d0
	bcs	exit_mkcptl
	cmpi.b	#'z',d0
	bhi	exit_mkcptl
	andi.w	#$df,d0		*わざと.w
exit_mkcptl:
	rts

fopen2:				*LZZ.Rの検索
	* > d5=file handle (error:d5<0)
	* - all 
	movem.l	d0-d2/a0-a3,-(sp)

	lea	lzz(pc),a0
	move.l	open_fn(pc),a1
	move.b	(a0)+,(a1)+
	move.b	(a0)+,(a1)+
	move.b	(a0)+,(a1)+
	move.b	(a0)+,(a1)+
	move.b	(a0)+,(a1)+
	move.b	(a0)+,(a1)+
	subq.w	#6,a0

	clr.w	-(sp)
	pea     (a0)
	DOS	_OPEN
	addq.w	#6,sp
	move.l	d0,d5		*d5.w=file handle
	bpl	exit_fopen	*no problem

	pea	path(pc)
	bsr	search_env
	addq.w	#4,sp
	tst.l	d0
	beq	exit_fopen
	move.l	d0,a1
	bra	fo0

make_temp_name:				*テンポラリファイルの名前を作成
reglist	reg	a0-a1
	movem.l	reglist,-(sp)
	lea	temp_name(pc),a1

	pea	temp_path(pc)
	bsr	search_env
	addq.w	#4,sp
	tst.l	d0
	beq	1f
	move.l	d0,a0
@@:
	move.b	(a0)+,(a1)+
	bne	@b
	subq.w	#1,a1

	cmpi.b	#'\',-1(a1)
	beq	1f
	move.b	#'\',(a1)+
1:
	lea	temp_name_src(pc),a0
@@:
	move.b	(a0)+,(a1)+
	bne	@b

	subq.w	#1,a1

	move.w	#32,-(sp)
	pea	temp_name(pc)
	DOS	_MAKETMP		*tempファイル作成
	addq.w	#6,sp

	st.b	temp_flg-zp_work(a6)

	movem.l	(sp)+,reglist
	rts

work:	set	zp_work
	.include	fopen.s

read:
	* < d5.l=file handle
	* > a5=data address
	* > d3.l=size
	* X d0
	move.w	#2,-(sp)	*ファィルの長さを調べる
	clr.l	-(sp)
	move.w	d5,-(sp)
	DOS	_SEEK
 	addq.w	#8,sp		*d0.l=file length
	move.l	d0,d3		*d3=true length
	ble	fsize0		*file size=0
	addq.l	#1,d0		*for end code

	move.l	d0,-(sp)
	DOS	_MALLOC
	addq.w	#4,sp
	tst.l	d0
	bmi	out_mem		*OUT OF MEMORY
	move.l	d0,a5
	clr.b	(a5,d3.l)	*endcode

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
	bmi	read_err	*読み込み失敗

	move.w	d5,-(sp)	*close
	DOS	_CLOSE
	addq.l	#2,sp
	rts

key_bind_jk:
	movem.l	d0-d2/d4/a0/a4,-(sp)

	pea	zp_key(pc)
	bsr	search_env
	addq.w	#4,sp
	tst.l	d0
	beq	quit_zk_jk

	move.l	d0,a2
	lea	key_tbl_jk(pc),a0
	moveq.l	#14-1,d2
@@:
	bsr	get_num
	bsr	skip_sep
	ror.b	#4,d1
	move.b	d1,(a0)+
	dbra	d2,@b
quit_zk_jk:
	movem.l	(sp)+,d0-d2/d4/a0/a4
	rts

key_bind_db:
	movem.l	d0-d2/a0/a2,-(sp)

	pea	zp_key(pc)
	bsr	search_env
	addq.w	#4,sp
	tst.l	d0
	beq	quit_zk_db

	move.l	d0,a2
	lea	key_tbl_db(pc),a0
	moveq.l	#14-1,d2
@@:
	bsr	get_num
	bsr	skip_sep
	ror.b	#4,d1
	move.b	d1,(a0)+
	dbra	d2,@b
quit_zk_db:
	movem.l	(sp)+,d0-d2/a0/a2
	rts

chk_drv:
	* > eq=kept
	* > mi=error
	bsr	print_title
	move.l	$8c.w,a0
	subq.w	#8,a0
	cmpi.l	#'ZmuS',(a0)+
	bne	@f
	cmpi.w	#'iC',(a0)+
	bne	@f
	cmpi.b	#$30,(a0)+
	bcs	version_error
	move.l	#ID_ERROR,d3
	Z_MUSIC	#ZM_FREE_MEM2	*古いERROR、全部解放
	moveq.l	#0,d0
	rts
@@:
	moveq.l	#-1,d0
	rts

print_title:			*タイトル表示
	movem.l	d0/a1,-(sp)
	lea	title_mes(pc),a1
	bsr	prta1
	clr.b	title_mes-zp_work(a6)
	movem.l	(sp)+,d0/a1
	rts

other_prog:			*他のプログラムがZ-MUSIC割り込みを使用中
	lea	other_mes(pc),a1
	bra	exit2

occupied_unsuccessful:		*アプリケーション登録が出来なかった
	lea	occunsc_mes(pc),a1
	bra	exit2

print_hlp:			*簡易ヘルプ表示
	tst.b	no_error_mark-zp_work(a6)
	bne	exit
	bsr	print_title
	lea	hlp_mes(pc),a1
	bra	exit2

no_drv:				*ドライバが組み込まれていません
	lea	no_drv_mes(pc),a1
	bra	exit2

lzz_not_found:
	lea	lzz_nf_mes(pc),a1
	bra	exit2

cant_use_lzz:
	lea	cant_use_lzz_mes(pc),a1
	bra	exit2

lzz_err:
	lea	lzz_err_mes(pc),a1
	bra	exit2

illegal_p:
	lea	illegal_p_mes(pc),a1
	bra	exit2

too_many_trks:			*トラック番号が多すぎる
	lea	toomanytr_mes(pc),a1
	bra	exit2

fsize0:				*ファイルサイズがゼロ
	move.l	a2,a1		*filename
	bsr	print_fnm2
	lea	fsize0_mes(pc),a1
	bra	exit2

unid_error:			*未確認ファイル
	bsr	print_fnm
	lea	unid_mes(pc),a1
	bra	exit2

not_performance_data:		*演奏データではない
	bsr	print_fnm
	lea	notpfmdt_mes(pc),a1
	bra	exit2

unid_error_zdf:			*未確認ファイル(ZDF)
	bsr	print_fnm
	lea	unidzdf_mes(pc),a1
	bra	exit2

juke_error:			*既定外コマンドの使用
	bsr	print_fnm
	lea	juke_er_mes(pc),a1
	bra	exit2

out_mem:			*メモリ不足
	lea	out_mem_mes(pc),a1
	bra	exit2

read_err:			*読み込み失敗
	lea	read_err_mes(pc),a1
	bra	exit2

file_not_found2:
	lea	org_fn(pc),a2
file_not_found:			*ファイルが無い
	move.l	a2,a1		*filename
	bsr	print_fnm2
	lea	fnf_err_mes(pc),a1
	bra	exit2

illegal_fader_speed:			*データ多すぎ
	lea	fdr_spd_er_mes(pc),a1
	bra	exit2

version_error:				*バージョン番号不一致
	lea	version_mes(pc),a1
	bra	exit2

temp_file_err:			*テンポラリファイルが破壊された?
	lea	tempfiler_mes(pc),a1
	bra	exit2

no_zmc_err:			*コンパイラが見つからない
	lea	no_zmc_er_mes(pc),a1
	bra	exit2

err_in_zmc:			*コンパイラでエラーが発生
	lea	err_zmc_mes(pc),a1
	bra	exit2

err_in_calc:			*計算に失敗
	lea	err_calc_mes(pc),a1
	bra	exit2

interval_too_long:		*ジュークボックスのブランクタイムが長すぎる
	lea	itvl_lng_mes(pc),a1
	bra	exit2

data_drop_err:	
	lea	drop_er_mes(pc),a1
	bra	exit2

illegal_ch:			*チャンネルの指定がおかしい
	lea	illegal_ch_mes(pc),a1
	bra	exit2

illegal_if:			*インターフェースの指定がおかしい
	lea	illegal_if_mes(pc),a1
	bra	exit2

illegal_ver_mode:		*バージョン切り換え失敗
	lea	illegal_v_mes(pc),a1
	bra	exit2

no_data_rec:			*なにも受信されなかった
	lea	nul_rec_mes(pc),a1
	bra	exit2

too_many:			*データ多すぎ
	lea	too_many_mes(pc),a1
	bra	exit2

not_kep:			*JUKE BOXは常駐していない
	lea	not_kep_mes(pc),a1
	bra	exit2

jb_already:			*JUKE BOXは既に常駐しています
	lea	already_mes(pc),a1
	bra	exit2

write_err:			*書き出し失敗
	DOS	_ALLCLOSE

	pea	filename(pc)
	DOS	_DELETE
	addq.w	#4,sp

	lea	write_err_mes(pc),a1
	bra	exit2

print_err_code:				*エラーがあればそれらを表示
	tst.b	non_disp-zp_work(a6)
	bne	exit_pec		*表示なし
	moveq.l	#-1,d1
	Z_MUSIC	#ZM_STORE_ERROR		*>d0.l=n of err,a0.l=error tbl
	move.l	d0,d2			*n of err
	beq	exit_pec		*エラーなし
	move.l	a0,a5			*error tbl
	move.l	#$0001_0000,d1		*output into buffer
	move.b	lang(pc),d1		*language
	move.l	zmd_name(pc),a1		*zmdの名前
	suba.l	a2,a2			*sourceアドレスなし(今後対応するかも)
	move.l	zms_name(pc),a3		*zmsの名前
	Z_MUSIC	#ZM_PRINT_ERROR
	pea	(a0)			*非表示でも表示
	DOS	_PRINT
	addq.w	#4,sp
	move.l	a0,a1
	Z_MUSIC	#ZM_FREE_MEM
	move.l	a5,a1
	Z_MUSIC	#ZM_FREE_MEM
exit_pec:
	rts

print_fnm:
	lea	filename(pc),a1
print_fnm2:
	tst.b	non_disp-zp_work(a6)
	bne	@f
	move.w	#2,-(sp)
	pea	(a1)
	DOS	_FPUTS
	addq.w	#6,sp

	move.w	#2,-(sp)
	pea	chon(pc)
	DOS	_FPUTS
	addq.w	#6,sp
@@:
	rts

bil_prta1:				*日本語対応
	tst.b	lang-zp_work(a6)	*0:英語か 1:日本語か
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

num_to_str:	*レジスタの値を文字数列にする
	* < d0.l=value
	* > (suji)=ascii data
	* > (suji2)=ascii data
	* - all(except d0)
	movem.l	d1-d4/a0-a1,-(sp)
	clr.b	d4
	lea	suji(pc),a0
	lea	exp_tbl(pc),a1
	moveq.l	#10-1,d1
ex_loop0:
	moveq.l	#0,d2
	move.l	(a1)+,d3
ex_loop1:
	sub.l	d3,d0
	bcs	xbcd_str
	addq.b	#1,d2
	bra	ex_loop1
xbcd_str:
	add.l	d3,d0
	move.b	d2,d3
	or.b	d4,d3
	bne	nml_ktset
*	move.b	#$20,(a0)+
	bra	nml_lp_ope
nml_ktset:
	st	d4
	add.b	#'0',d2
	move.b	d2,(a0)+
nml_lp_ope:
	dbra	d1,ex_loop0
	lea	suji(pc),a1
	cmpa.l	a1,a0
	bne	@f
	move.b	#'0',(a0)+
@@:
	clr.b	(a0)		*end flg
				*桁揃え処理
	sub.l	a1,a0		*a0=len
	move.l	a0,d0
	divu	#3,d0
	swap	d0
	lea	suji2(pc),a0
	subq.w	#1,d0
	bcs	soroe01
@@:
	move.b	(a1)+,(a0)+
	dbra	d0,@b
soroe01:
	swap	d0
soroelp:
	subq.w	#1,d0
	bcs	exit_soroe
	beq	@f
	move.b	#',',(a0)+
@@:
	move.b	(a1)+,(a0)+
	move.b	(a1)+,(a0)+
	move.b	(a1)+,(a0)+
	bra	soroelp
exit_soroe:
	clr.b	(a0)		*end code
	movem.l	(sp)+,d1-d4/a0-a1
	rts

get_hex32:			*値→16進数文字列(8bytes)
	* < d0=data value
	* > (a1)=suji(ascii numbers)
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
	bls	its_hex32
	addq.b	#7,d1
its_hex32:
	move.b	d1,-(a1)
	lsr.l	#4,d0
	dbra	d4,gh_lp32
	movem.l	(sp)+,d0-d1/d4/a1
	rts

	.data
zp_work:
title_mes:
	dc.b	'Z-MUSIC PLAYER '
	dc.b	$F3,'V',$F3,'E',$F3,'R',$F3,'S',$F3,'I',$F3,'O',$F3,'N'
	version
	test
	dc.b	' (C) 1991,98 '
	dc.b	'ZENJI SOFT',13,10,0
hlp_mes:
	dc.b	'< USAGE > '
	dc.b	' ZP3.R [COMMAND] [FILENAME][,SETUP-FILE1…4]',13,10
	dc.b	'< COMMAND SWITCHES >',13,10
	dc.b	'-a<filename>                   To record MIDI data and create SMF.',13,10
	dc.b	'-b<filename>[,setup1…4]       To include juke box function.',13,10
	dc.b	'-c[track number(s),…]         Make track(s) continue playing',13,10
	dc.b	'-d<MIDI I/F number>            Change the current MIDI interface.',13,10
	dc.b	'-E[channel(s),…]              Enable channel(s).',13,10
	dc.b	'-e[track number(s),…]         Enable track(s).',13,10
	dc.b	'-f[speed]                      Track fader control.',13,10
	dc.b	'                               Negative speed value makes fader up.',13,10
	dc.b	'-i                             Initialize Z-MUSIC and all instruments.',13,10
	dc.b	'-j                             Messages will be displayed in Japanese.',13,10
	dc.b	'-k                             To include performance control function.',13,10
	dc.b	'-M[channel(s),…]              Mask channel(s)',13,10
	dc.b	'-m[track number(s),…]         Mask track(s)',13,10
	dc.b	'-O[level[,channel(s),…]]      Set channel output level.',13,10
	dc.b	'-o[level[,track number(s),…]] Set track output level.',13,10
	dc.b	'-p[filename[,setup1…4]]       Start to play performance data(ZMD,ZMS,OPM,ZDF)',13,10
	dc.b	'-p[track number(s),…]         Make track(s) start playing',13,10
	dc.b	'-q[filename]                   Start to play performance data,',13,10
	dc.b	'                               and display the information about it.',13,10
	dc.b	'-r                             Release ZP3.R',13,10
	dc.b	'-s[track number(s),…]         Make track(s) stop playing',13,10
	dc.b	'-v<interval length>            Set blank time of juke box.',13,10
	dc.b	'-w[filename[,setup1…4]]       Start to play the performance data',13,10
	dc.b	'                               as soon as MIDI IN receives $FA.',13,10
	dc.b	'-x<filename>                   Send MIDI dump data to MIDI instrument(s).',13,10
	dc.b	'-y<filename>                   Record MIDI data and Start to play performance data',13,10
	dc.b	'                               at the same time.',13,10
	dc.b	0
	dc.b	'< 使用方法 > '
	dc.b	' ZP3.R [コマンド] [ファイル名][,ｾｯﾄｱｯﾌﾟﾌｧｲﾙ1…4]',13,10
	dc.b	'< コマンドスイッチ >',13,10
	dc.b	'-a<ファイル名>                   MIDIデータを受信しSMFを作成する',13,10
	dc.b	'-b<ファイル名>[,ｾｯﾄｱｯﾌﾟﾌｧｲﾙ1…4] ジュークボックス機能を組み込む',13,10
	dc.b	'-c[トラック番号,…]              指定トラックの演奏を再開する',13,10
	dc.b	'-d<MIDI I/F number>              カレントMIDIインターフェースを指定する',13,10
	dc.b	'-E[チャンネル名,…]              チャンネルマスクを解除する',13,10
	dc.b	'-e[トラック番号,…]              トラックマスクを解除する',13,10
	dc.b	'-f[スピード]                     フェーダーを操作する。',13,10
	dc.b	'                                 負値のスピードはフェーダーを上げていく指定になる',13,10
	dc.b	'-i                               Z-MUSIC本体および接続中のデバイスを初期化する',13,10
	dc.b	'-j                               日本語メッセージ表示',13,10
	dc.b	'-k                               演奏制御機能を組み込む',13,10
	dc.b	'-M[チャンネル名,…]              指定チャンネルをマスクする',13,10
	dc.b	'-m[トラック番号,…]              指定トラックをマスクする',13,10
	dc.b	'-O[レベル[,チャンネル名,…]]     指定チャンネルの出力レベルを設定する',13,10
	dc.b	'-o[レベル[,トラック番号,…]]     指定トラックの出力レベルを設定する',13,10
	dc.b	'-p[ファイル名[,ｾｯﾄｱｯﾌﾟﾌｧｲﾙ1…4]] 指定ファイル(ZMD,ZMS,OPM,ZDF)の演奏を開始する',13,10
	dc.b	'-p[トラック番号,…]              指定トラックの演奏を開始する',13,10
	dc.b	'-q[ファイル名]                   指定ファイルの演奏を開始し演奏データのステータスを表示する',13,10
	dc.b	'-r                               ZP3.Rの常駐を解除する',13,10
	dc.b	'-s[トラック番号(s),…]           指定トラックの演奏を停止する',13,10
	dc.b	'-v<インターバルの長さ>           ジュークボックスのブランクタイムを設定する',13,10
	dc.b	'-w[ファイル名[,ｾｯﾄｱｯﾌﾟﾌｧｲﾙ1…4]] MIDI INが$FAを受信したと同時に演奏を開始する',13,10
	dc.b	'-x<ファイル名>                   MIDIダンプデータを送信する',13,10
	dc.b	'-y<ファイル名>                   レコーディング開始と同時に',13,10
	dc.b	'                                 指定ファイル(ZMD,ZMS,OPM,ZDF)の演奏を開始する',13,10
	dc.b	0
other_mes:	dc.b	'Z-MUSIC Interrapt Service has already been used by other applications.',13,10,0
		dc.b	'Z-MUSIC割り込みサービスは既に他のプログラムが利用中です',13,10,0
drop_er_mes:	dc.b	'MIDI receiver program dropped data.',13,10,0
		dc.b	'MIDI受信プログラムがデータを取りこぼしました',13,10,0
occunsc_mes:	dc.b	'Z-MUSIC refused ZP3.R registration.',13,10,0
		dc.b	'Z-MUSICにZP3.Rの登録を拒否されました',13,10,0
no_drv_mes:	dc.b	'Z-MUSIC is not included.',13,10,0
		dc.b	'Z-MUSICが組み込まれていません',13,10,0
fsize0_mes:	dc.b	'Illegal file size.',13,10,0
		dc.b	'ファイルサイズが異常です',13,10,0
itvl_lng_mes:	dc.b	'Blank time too long.',13,10,0
		dc.b	'ブランクタイムが長すぎます',13,10,0
illegal_p_mes:	dc.b	'Illegal parameter error.',13,10,0
		dc.b	'値が規定外です',13,10,0
illegal_ch_mes:	dc.b	'Illegal channel ID error.',13,10,0
		dc.b	'チャンネルIDが規定外です',13,10,0
illegal_if_mes:	dc.b	'Illegal interface ID error.',13,10,0
		dc.b	'インターフェースIDが規定外です',13,10,0
illegal_v_mes:	dc.b	'Fail in switching Z-MUSIC version mode.',13,10,0
		dc.b	'Z-MUSICバージョンモードの切り換えに失敗しました',13,10,0
toomanytr_mes:	dc.b	'Too many track numbers error.',13,10,0
		dc.b	'トラック番号が多すぎます',13,10,0
out_mem_mes:	dc.b	'Out of memory.',13,10,0
		dc.b	'メモリが不足しています',13,10,0
read_err_mes:	dc.b	'File read error.',13,10,0
		dc.b	'ファイルの読み込みに失敗しました',13,10,0
fnf_err_mes:	dc.b	'File not found.',13,10,0
		dc.b	'ファイルが見つかりませんでした',13,10,0
too_many_mes:	dc.b	'Too many filenames are written in index-file.',13,10,0
		dc.b	'インデックスファイル中に記述されたファイル名が多すぎます',13,10,0
unid_mes:	dc.b	'Unidentified file.',13,10,0
		dc.b	'認識できないファイルです',13,10,0
notpfmdt_mes:	dc.b	'This is not a performance data.',13,10,0
		dc.b	'これは演奏データではありません',13,10,0
unidzdf_mes:	dc.b	'Unidentified ZDF file.',13,10,0
		dc.b	'認識できないZDFファイルです',13,10,0
juke_er_mes:	dc.b	'This data contains an unsupportable external file reference.',13,10,0
		dc.b	'未対応の外部ファイル参照を含んでいます',13,10,0
version_mes:	dc.b	'Version number mismatch.',13,10,0
		dc.b	'バージョン番号が不一致です',13,10,0
midi_bd_mes:	dc.b	'MIDI is Unable to use.',13,10,0
		dc.b	'MIDIは使用できません',13,10,0
juke_mes:	dc.b	'Juke-box starts on a task.',13,10,0
		dc.b	'ジュークボックスを開始します',13,10,0
debug_mes:	dc.b	'Performance Control Function has been included.',13,10,0
		dc.b	'演奏制御機能が常駐しました',13,10,0
not_kep_mes:	dc.b	'ZP3.R is not kept in your system.',13,10,0
		dc.b	'ZP3.Rは常駐していません',13,10,0
already_mes:	dc.b	'ZP3.R has already been kept.',13,10,0
		dc.b	'ZP3.Rは既に常駐しています',13,10,0
lzz_nf_mes:	dc.b	"LZZ.R couldn't be found.",13,10,0
		dc.b	'LZZ.Rが見つかりません',13,10,0
cant_use_lzz_mes:	dc.b	"LZZ.R couldn't be used.",13,10,0
			dc.b	'LZZ.Rを利用することができませんでした',13,10,0
lzz_err_mes:	dc.b	"Error in LZZ.R.",13,10,0
		dc.b	'LZZ.R内でエラーが発生しました',13,10,0
write_err_mes:	dc.b	'File write error.',13,10,0
		dc.b	'ファイルの書き出しに失敗しました',13,10,0
fdr_spd_er_mes:	dc.b	'Illegal fader speed.',13,10,0
		dc.b	'フェーダースピードの値が異常です',13,10,0
tempfiler_mes:	dc.b	'Temporary file was broken.',13,10,0
		dc.b	'テンポラリファイルが異常です',13,10,0
no_zmc_er_mes:	dc.b	'Fail in execution of Z-MUSIC MML COMPILER.',13,10,0
		dc.b	'Z-MUSIC MMLコンパイラの起動に失敗しました',13,10,0
err_zmc_mes:	dc.b	'Error in execution of Z-MUSIC MML COMPILER.',13,10,0
		dc.b	'Z-MUSIC MMLコンパイラでエラーが発生しました',13,10,0
err_calc_mes:	dc.b	'Fail in a calculation of total step time.',13,10,0
		dc.b	'トータルステップタイムの計算に失敗しました',13,10,0
nul_rec_mes:	dc.b	'No data was received.',13,10,0
		dc.b	'データは受信されませんでした',13,10,0
rec_st_mes:	dc.b	'Recording start. Press [ESC] to stop.',13,10,0
		dc.b	'受信を開始します。[ESC]キーで終了します',13,10,0
saving_mes:	dc.b	'Now writing ',0
		dc.b	'現在加工保存処理実行中です',13,10,0
trns_mes:	dc.b	'Now transmitting.',13,10,0
		dc.b	'現在送信中です',13,10,0
v2_mode_mes:	dc.b	'Z-MUSIC switched to Ver.2.0 mode',13,10,0
		dc.b	'Z-MUSICはVer.2.0モードに切り替わりました',13,10,0
v3_mode_mes:	dc.b	'Z-MUSIC switched to Ver.3.0 mode',13,10,0
		dc.b	'Z-MUSICはVer.3.0モードに切り替わりました',13,10,0
crntmidiin:	dc.b	'Current MIDI Interface (IN)  : ',0
		dc.b	'カレントMIDIインターフェース (IN) : ',0
crntmidiout:	dc.b	'                       (OUT) : ',0
		dc.b	'                            (OUT) : ',0
none_mdif:	dc.b	'NOT READY',0
non_disp:	dc.b	0
chon:		dc.b	' ... ',0
zp3_opt:	dc.b	'zp3_opt',0
zmsc3_fader:	dc.b	'zmsc3_fader',0
path:		dc.b	'path',0
lzz:		dc.b	'lzz.r',0
zp_key:		dc.b	'zp3_keyctrl',0
zp_juk:		dc.b	'zp3_jukectrl',0
dummy_bmd:	dc.b	'ZMUSIC.MID',0
*sep_:		dc.b	':',0
*SPC2:		dc.b	'  ',0
CRLF:		dc.b	13,10,0
ext_tbl:
ZMD_kaku:	dc.b	'ZMD',0
ZMS_kaku:	dc.b	'ZMS',0
OPM_kaku:	dc.b	'OPM',0
ZDF_kaku:	dc.b	'ZDF',0
MID_kaku:	dc.b	'MID',0
MDD_kaku:	dc.b	'MDD',0
ZPD_kaku:	dc.b	'ZPD',0
JUK_kaku:	dc.b	'JUK',0
temp_name_src:	dc.b	'ZMSC????.ZMD',0
temp_path:	dc.b	'temp',0
adpcm_default_ch:	dc.b	0	*ADPCM CH 初期値
no_error_mark:		dc.b	0	*-1:正常にZP3.Rが終了したとみなしてよい
normal_play:		dc.b	0	*0:通常演奏,-1:効果音演奏
temp_flg:		dc.b	0	*テンポラリファイルの状態[0]:存在せず 1:存在する
*v2_compatch:		dc.b	0	*V2コンパチコンパイルか(0:no 1:yes)
ocpy_int_service:	dc.b	0	*ZM_SET_INT_SERVICEを占有したか([0]=no,1=yes)
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

zms_name:	dc.l	0
zmd_name:	dc.l	0
*if_number:	dc.l	-1		*MIDI入力のデフォルトインターフェース
zmint_count:	dc.l	0
	.bss
zpdfilename:
filename:	ds.b	fn_size
mddfilename:	ds.b	fn_size
setup_fn:	ds.b	fn_size*4
prog_name:	ds.b	fn_size
org_fn:		ds.b	fn_size
bmdoutname:	ds.b	fn_size
suji:		ds.b	11		*数値表示用
suji2:		ds.b	15		*数値表示用(桁揃え)
retry:		ds.b	1
self_rec_mode:	ds.b	1		*0:rec,1:self
	.even
zpd_scan:	ds.b	1	*0
mdd_scan:	ds.b	1	*1
mdd_dest_if:	ds.l	1	*2

preserve_d3d7a5:	ds.l	3
midi_rec_buf:		ds.l	1
open_fn:		ds.l	1
fopen_name:		ds.l	1
_common_buffer:		ds.l	1
env_bak:		ds.l	1
_seq_wk_tbl:		ds.l	1
zmd_addr:		ds.l	1
hozon_a5:		ds.l	1
last_zpd_addr:		ds.l	1
lzz_adr:		ds.l	1
bufadr:			ds.b	5*10+2
a2work:			ds.l	1
list_adr:		ds.l	1
track_seqtbl:		ds.w	(128+1)*3	*一応128トラック分確保
zmc_cmd:		ds.b	1024
temp_name:		ds.b	256		*dc.b	'ZMSC????.ZMD',0
ssp:			ds.l	1
sfp:			ds.l	1
mysp:			ds.l	1
filename0:		ds.l	1
reg_buf:		ds.l	16
zpdnm_buf:		ds.l	1
mddnm_buf:		ds.l	1
end_of_prog:
	.end
