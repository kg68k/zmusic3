*-----------------------------------------------
*	      ＰＣＭファイルリンカ
*
*		  ＺＰＬＫ．Ｒ
*
*		  VERSION 3.00A
*
*		 BY Z.NISHIKAWA
*-----------------------------------------------

	.cpu	68000
	.include	iocscall.mac
	.include	doscall.mac
	.include	z_global.mac

	*ZM302C_X.LZHに入っているZPLK3.Rはバージョン3.02だが
	*ZM302C_S.LZHのソースコードをアセンブルすると3.02Cに
	*なってしまうのでごまかす
	NO_VERSION_SUFFIX: .equ 1
	.include	version.mac

	.text

smax:		equ	32		*記述できるソースファイルの最大数
vmax:		equ	300
lmax:		equ	3		*ループの種類(0,1,2,3)
rmax:		equ	65535		*繰り返し数最大値
cmax:		equ	2		*サブ・コンバージョンタイプ(0,1,2)
tbl_size:	equ	128
loop_type:	equ	0	*loop type.w
rept_time:	equ	2	*repeat time.w
conv_type:	equ	4	*conv type.w
fsize:		equ	8	*file size.l
fname:		equ	32	*filename.b

print	macro	mes
	move.w	#2,-(sp)
	pea	mes
	DOS	_FPUTS
	addq.w	#6,sp
	endm

print2	macro	mes
	pea	mes
	DOS	_PRINT
	addq.w	#4,sp
	endm

bprint	macro	mes
	pea	mes
	bsr	bil_prta1_
	addq.w	#4,sp
	endm

*--------------- PROGRAM START ---------------

	lea	$10(a0),a0		*メモリブロックの変更
	lea.l	user_sp(pc),a1
	suba.l	a0,a1
	pea	(a1)
	pea	(a0)
	DOS	_SETBLOCK
	addq.w	#8,sp
	tst.l	d0
	bmi	out_of_mem

	lea	work(pc),a6
	lea	user_sp(pc),sp		*スタック設定

	move.l	#256,-(sp)
	DOS	_MALLOC
	addq.l	#4,sp
	move.l	d0,open_fn-work(a6)

	move.l	a3,env_bak-work(a6)

	print	title(pc)

	clr.b	d_name-work(a6)
	lea	s_name_tbl(pc),a0
	move.w	#((smax+1)*tbl_size)/4-1,d0
@@:					*ワークの初期化
	clr.l	(a0)+
	dbra	d0,@b

	moveq.l	#smax,d6
	lea	s_name_tbl(pc),a5

	pea	zplk3_opt(pc)		*'zplk3_opt'
	bsr	search_env
	addq.w	#4,sp
	tst.l	d0
	beq	@f
	move.l	a2,-(sp)
	move.l	d0,a2
	bsr	scansw			*オプションスイッチ
	move.l	(sp)+,a2
@@:
	tst.b	(a2)+			*パラメータある?
	beq	show_help
	bsr	scansw
	bra	go_ope

scansw:
	* < d6.w=smax
	* < a5.l=s_name_tbl
chk_coml:
	bsr	skip_spc
	move.b	(a2)+,d0
	beq	exit_scansw
	cmpi.b	#'/',d0
	beq	scan_switch
	cmpi.b	#'-',d0
	beq	scan_switch
get_fname:				*ファイルネームの取得
	subq.w	#1,a2
	move.l	a5,a0
	adda.w	#fname,a5
gflp0:
	move.b	(a2)+,d0
	move.b	d0,(a5)+
	bpl	@f
	move.b	(a2)+,(a5)+		*case kanji
	bra	gflp0
@@:
	bsr	fnstr_chk
	bne	gflp0
	clr.b	-(a5)
	subq.w	#1,a2
	lea.l	tbl_size(a0),a5
	dbra	d6,chk_coml
	bra	too_many_s
exit_scansw:
	rts

scan_switch:			*最終出力形式の設定
	move.b	(a2)+,d0	*get sw name
	beq	exit_scansw
	bsr	mk_capital
	cmpi.b	#'J',d0
	bne	@f
	st.b	errmes_lang-work(a6)
	bra	chk_coml
@@:
	cmpi.b	#'A',d0
	bne	@f
	st.b	adpout_mode-work(a6)
	moveq.l	#-1,d0
	and.b	p16out_mode(pc),d0	*両方のスイッチ・オンは矛盾
	bne	not_support
	bra	chk_coml
@@:				*ピッチベンド
	cmpi.b	#'B',d0
	bne	cutting
	bsr	chk_num
	bpl	@f
	move.b	(a2),d0
	bsr	mk_capital
	cmpi.b	#'P',d0
	bne	unex_error
	addq.w	#1,a2
	bsr	get_frq_rng
	move.l	d1,s_frq_b-work(a6)
	move.l	d2,d_frq_b-work(a6)
	bra	get_ofb
@@:
	bsr	asc_to_n
	cmpi.l	#65535,d1
	bhi	s_illegal
	move.l	d1,s_frq_b-work(a6)
	beq	s_illegal
	bsr	skip_sep	*skip ','
	bsr	chk_num
	bmi	no_d_error
	bsr	asc_to_n
	cmpi.l	#65535,d1
	bhi	d_illegal
	move.l	d1,d_frq_b-work(a6)
	beq	d_illegal
	cmp.l	s_frq_b(pc),d1	*同じでは意味がない。
	beq	d_illegal
get_ofb:			*オフセットポイントの設定
	bsr	skip_sep	*skip ','
	bsr	chk_num
	bpl	@f
	cmpi.b	#',',(a2)
	bne	chk_coml
	bra	get_b_size
@@:
	bsr	asc_to_n
	btst.l	#0,d1
	bne	b_offset_err
	move.l	d1,b_offset-work(a6)
get_b_size:
	bsr	skip_sep
	bsr	chk_num
	bmi	chk_coml
	bsr	asc_to_n
	btst.l	#0,d1
	bne	b_size_err
	move.l	d1,b_size-work(a6)
	beq	b_size_err
	bra	chk_coml
cutting:			*切り出しオプション
	cmpi.b	#'C',d0
	bne	envchg?
				*オフセット値
	bsr	chk_num
	bpl	@f
	cmpi.b	#',',(a2)
	bne	unex_error	*意味不明
	bra	get_cutsize
@@:
	bsr	asc_to_n
	btst.l	#0,d1
	bne	cut_offset_illegal
	move.l	d1,cut_offset-work(a6)
get_cutsize:			*切り出しサイズ
	bsr	skip_sep
	bsr	chk_num
	bmi	chk_coml
	bsr	asc_to_n
	btst.l	#0,d1
	bne	cut_size_illegal
	move.l	d1,cut_size-work(a6)
	or.l	cut_offset(pc),d1
	beq	not_support	*両方のパラメータを省略はできない。
	bra	chk_coml
envchg?:			*エンベロープ変更設定
	cmpi.b	#'F',d0
	bne	impulse?
	st.b	fade_mode-work(a6)
				*オフセット値
	bsr	chk_num
	bpl	@f
	cmpi.b	#',',(a2)
	bne	chk_coml	*意味不明
	bra	get_envlvl
@@:
	bsr	asc_to_n
	btst.l	#0,d1
	bne	env_offset_illegal
	move.l	d1,env_offset-work(a6)
get_envlvl:			*エンベロープ初期／最終音量
	bsr	skip_sep
	bsr	chk_num
	bpl	@f
	cmpi.b	#',',(a2)
	bne	chk_coml	*意味不明
	bra	get_envtype
@@:
	bsr	asc_to_n
	cmpi.l	#127,d1
	bhi	envlvl_illegal
	move.b	d1,env_lvl-work(a6)
get_envtype:			*エンベロープ変更種類
	bsr	skip_sep
	bsr	chk_num
	bmi	chk_coml
	bsr	asc_to_n
	cmpi.l	#1,d1
	bhi	envtype_illegal
	move.b	d1,env_type-work(a6)
	bne	chk_coml
	tst.l	env_offset-work(a6)
	beq	env_offset_illegal	*フェードインでオフセット０はあり得ない
	bra	chk_coml
impulse?:				*たたみ込みを行なうか
	cmpi.b	#'I',d0
	bne	p16otmd?
	st.b	impulse_mode-work(a6)
	bsr	skip_spc
	lea	impulse_name(pc),a1
implp0:
	move.b	(a2)+,d0
	move.b	d0,(a1)+
	bpl	@f
	move.b	(a2)+,(a1)+
	bra	implp0
@@:
	bsr	fnstr_chk
	bne	implp0
	clr.b	-(a1)
	subq.w	#3,a1
	move.b	(a1)+,d0
	bsr	mk_capital
	cmpi.b	#'P',d0
	bne	unid_err
	move.b	(a1)+,d0
	bsr	mk_capital
	cmpi.b	#'C',d0
	bne	impulse_p16?
	move.b	(a1)+,d0
	bsr	mk_capital
	cmpi.b	#'M',d0
	bne	unid_err
	lea	impulse_name(pc),a1
	bsr	read_data2
	pea	(a0)
	move.l	impulse_buff(pc),a0
	move.l	impulse_size(pc),d1
	move.l	d1,d0
	lsl.l	#2,d0
	move.l	d0,impulse_size-work(a6)
	move.l	d0,-(sp)
	DOS	_MALLOC
	addq.l	#4,sp
	move.l	d0,impulse_buff-work(a6)
	bmi	out_of_mem
	move.l	d0,a1
	move.l	d1,d0
	bsr	just_adpcm_to_pcm
	pea	(a0)
	DOS	_MFREE
	addq.w	#4,sp
	move.l	(sp)+,a0
	bra	chk_coml
impulse_p16?:
	cmpi.b	#'1',d0
	bne	unid_err
	cmpi.b	#'6',(a1)+
	bne	unid_err
	lea	impulse_name(pc),a1
	bsr	read_data2
	bra	chk_coml
p16otmd?:
	cmpi.b	#'P',d0
	bne	reverse?
	st.b	p16out_mode-work(a6)
	moveq.l	#-1,d0
	and.b	adpout_mode(pc),d0	*両方のスイッチ・オンは矛盾
	bne	not_support
	bra	chk_coml
reverse?:			*最終逆転
	cmpi.b	#'R',d0
	bne	@f
	st.b	revout_mode-work(a6)
	bra	chk_coml
@@:				*最終音量設定
	cmpi.b	#'V',d0
	bne	@f
	bsr	chk_num
	bmi	no_v_param
	bsr	asc_to_n
	cmpi.l	#vmax,d1
	bhi	v_illegal
	lsl.l	#8,d1
	divu	#100,d1
	move.w	d1,vol_val-work(a6)
	bra	chk_coml
@@:				*最終的に周波数を変換する
	cmpi.b	#'T',d0
	bne	sub_con
	bsr	chk_num
	bpl	@f
	move.b	(a2),d0
	bsr	mk_capital
	cmpi.b	#'P',d0
	bne	unex_error
	addq.w	#1,a2
	bsr	get_frq_rng
	move.l	d1,s_frq-work(a6)
	move.l	d2,d_frq-work(a6)
	bra	get_oft
@@:
	bsr	asc_to_n
	cmpi.l	#65535,d1
	bhi	s_illegal
	move.l	d1,s_frq-work(a6)
	beq	s_illegal
	bsr	skip_sep	*skip ','
	bsr	chk_num
	bmi	no_d_error
	bsr	asc_to_n
	cmpi.l	#65535,d1
	bhi	d_illegal
	move.l	d1,d_frq-work(a6)
	beq	d_illegal
	cmp.l	s_frq(pc),d1	*同じでは意味がない。
	beq	d_illegal
get_oft:			*オフセットポイントの設定
	bsr	skip_sep	*skip ','
	bsr	chk_num
	bpl	@f
	cmpi.b	#',',(a2)
	bne	chk_coml
	bra	get_t_size
@@:
	bsr	asc_to_n
	btst.l	#0,d1
	bne	t_offset_err
	move.l	d1,t_offset-work(a6)
get_t_size:
	bsr	skip_sep
	bsr	chk_num
	bmi	chk_coml
	bsr	asc_to_n
	btst.l	#0,d1
	bne	t_size_err
	move.l	d1,t_size-work(a6)
	beq	t_size_err
	bra	chk_coml
sub_con:			*変換パラメータの設定
	cmpi.b	#'X',d0
	bne	exit_scansw
				*ループタイプ取り出し
	bsr	chk_num
	bpl	@f
	cmpi.b	#',',(a2)
	bne	unex_error	*意味不明
	bra	get_rept
@@:
	bsr	asc_to_n
	cmpi.l	#lmax,d1
	bhi	l_illegal
	bne	@f
	subq.w	#4,d1		*3 -> -1
@@:
	move.w	d1,loop_type(a5)
get_rept:			*ループ回数の取り出し
	bsr	skip_sep
	bsr	chk_num
	bpl	@f
	cmpi.b	#',',(a2)
	bne	unex_error	*意味不明
	bra	get_srccnv
@@:
	bsr	asc_to_n
	tst.l	d1
	beq	r_illegal
	cmpi.l	#rmax,d1
	bhi	r_illegal
	move.w	d1,rept_time(a5)
get_srccnv:			*ソースファイルのサブ・コンバージョン形式
	bsr	skip_sep
	bsr	chk_num
	bmi	chk_coml
	bsr	asc_to_n
	cmpi.l	#cmax,d1
	bhi	t_illegal
	bne	@f
	subq.w	#3,d1		*2 -> -1
@@:
	move.w	d1,conv_type(a5)	*-1,0,1
	beq	chk_coml	*non touch
	bmi	chk_coml	*to pcm
	tst.w	loop_type(a5)
	beq	chk_coml	*forward
	bra	not_support	*ADPCMのリバースやオルタネートは出来ない

get_frq_rng:
	bsr	skip_spc
	moveq.l	#0,d0
	cmpi.b	#'-',(a2)
	bne	@f
	addq.w	#1,a2
	moveq.l	#-1,d0
@@:
	bsr	asc_to_n
	subq.l	#1,d1
	bcs	unex_error	*±0では無意味
	cmpi.l	#143,d1
	bhi	illegal_frq
	add.l	d1,d1
	moveq.l	#0,d2
	move.w	frq_tbl(pc,d1.l),d2
	move.l	#65280,d1
	tst.l	d0
	bmi	@f
	exg.l	d1,d2
@@:
	rts

frq_tbl:
	* for i=1 to 144
	*  frq_tbl=(2^-(i/12))*65280
	* next
	dc.w	61616,58158,54894,51813,48905,46160,43569,41124,38816,36637,34581,32640
	dc.w	30808,29079,27447,25906,24452,23080,21785,20562,19408,18319,17290,16320
	dc.w	15404,14539,13723,12953,12226,11540,10892,10281,9704,9159,8645,8160
	dc.w	7702,7270,6862,6477,6113,5770,5446,5140,4852,4580,4323,4080
	dc.w	3851,3635,3431,3238,3057,2885,2723,2570,2426,2290,2161,2040
	dc.w	1926,1817,1715,1619,1528,1442,1362,1285,1213,1145,1081,1020
	dc.w	963,909,858,810,764,721,681,643,606,572,540,510
	dc.w	481,454,429,405,382,361,340,321,303,286,270,255
	dc.w	241,227,214,202,191,180,170,161,152,143,135,128
	dc.w	120,114,107,101,96,90,85,80,76,72,68,64
	dc.w	60,57,54,51,48,45,43,40,38,36,34,32
	dc.w	30,28,27,25,24,23,21,20,19,18,17,16

go_ope:				*書き出しファイル名の取り出し
	lea	s_name_tbl+tbl_size(pc),a0
	cmpa.l	a0,a5		*ファイル名パラメータが少なすぎる
	bls	show_help
	suba.w	#tbl_size-fname,a5
	move.l	a5,a4
	lea	d_name(pc),a0
@@:
	move.b	(a5)+,(a0)+
	bne	@b
	clr.b	(a4)		*終了コードとする

	lea	s_name_tbl-tbl_size(pc),a5
	moveq.l	#0,d3		*読み込みバッファ最大値
	moveq.l	#0,d4		*サブ・コンバッファ最大値
fsmx_lp:			*最大のファイルサイズはいくつ？
	lea	tbl_size(a5),a5
	tst.b	fname(a5)	*最後かどうか
	beq	get_bff
	lea	fname(a5),a1
	bsr	check_fopen	*>d1.l=fsize
	cmp.l	d3,d1
	bls	@f
	move.l	d1,d3
@@:
	tst.w	conv_type(a5)
	beq	fsmx_lp			*no touch
	bpl	@f
	lsl.l	#2,d1
	bra	fsmx0
@@:
	lsr.l	#2,d1
fsmx0:
	cmp.l	d4,d1
	bls	fsmx_lp
	move.l	d1,d4
	bra	fsmx_lp
get_bff:			*目的のＰＣＭデータを作成する。
	move.l	d3,-(sp)
	DOS	_MALLOC
	addq.l	#4,sp
	move.l	d0,src_temp1-work(a6)
	bmi	out_of_mem

	cmp.l	d3,d4
	bcc	@f
	move.l	d3,d4
@@:
	move.l	d4,-(sp)	*サブ・コンバッファ確保
	DOS	_MALLOC
	addq.l	#4,sp
	move.l	d0,src_temp2-work(a6)
	bmi	out_of_mem
				*テンポラリエリア確保
	move.l	#-1,-(sp)
	DOS	_MALLOC
	addq.w	#4,sp
	andi.l	#$00ffffff,d0
	move.l	d0,a3
	move.l	d0,-(sp)	*取れる限り確保
	DOS	_MALLOC
	addq.w	#4,sp
	move.l	d0,pcm_temp-work(a6)
	bmi	out_of_mem
	move.l	d0,a4		*destination buffer address
	add.l	d0,a3		*mem. block last address

	* < a3.l=mem. block last address
	* < a4.l=mem. destination buffer address
	lea	s_name_tbl(pc),a5
mkpcm_lp01:
	tst.b	fname(a5)		*最後かどうか
	beq	temp_clr		*最後なら次の処理へ
	lea	fname(a5),a1
	bsr	read_data		*d1:size d2:address
	tst.w	conv_type(a5)
	beq	non_tch
	bpl	to_adp
to_p16:					*16bit pcmへ
	move.l	d1,d0			*size
	move.l	d2,a0			*adpcm source
	move.l	src_temp2(pc),a1	*pcm buffer
	lsl.l	#2,d1
	move.l	d1,fsize(a5)		*save size
	move.w	vol_val(pc),d6
	bsr	adpcm_to_pcm
	bra	link_it
to_adp:
	move.l	d1,d0			*size
	move.l	d2,a1			*pcm source
	move.l	src_temp2(pc),a0	*adpcm buffer
	lsr.l	#2,d1
	move.l	d1,fsize(a5)		*save size
	move.l	d0,d1
	btst.l	#0,d1
	bne	size_error		*ＰＣＭデータが奇数サイズということはあり得ない。
	lsr.l	d1
	movem.l	d0/a0/a1,-(sp)
	move.w	vol_val(pc),d2
@@:
	move.w	(a1),d0
	muls	d2,d0			*音量変換
	asr.l	#8,d0
	move.w	d0,(a1)+
	subq.l	#1,d1
	bne	@b
	movem.l	(sp)+,d0/a0/a1
	bsr	pcm_to_adpcm
	bra	link_it
non_tch:
	move.l	d2,a1			*source
	move.l	src_temp2(pc),a2	*destination
	move.l	d1,d2			*size
	move.l	d1,fsize(a5)		*save size
	lsr.l	#2,d1
	andi.l	#$0000_0003,d2
@@:
	tst.l	d1
	beq	@f
1:
	move.l	(a1)+,(a2)+
	subq.l	#1,d1
	bne	1b
@@:
	tst.b	d2
	beq	@f
1:
	move.b	(a1)+,(a2)+
	subq.b	#1,d2
	bne	1b
@@:
link_it:
	move.w	loop_type(a5),d0
	beq	loop_fwd
	bmi	loop_rev
	subq.w	#1,d0
	beq	loop_alt1
*loop_alt2:				*→←
	move.w	rept_time(a5),d2
	bne	@f			*0は１回と見なす
	addq.w	#1,d2
@@:
	move.l	src_temp2(pc),a1	*source
	move.l	a1,d4
	add.l	fsize(a5),d4		*edge address
**	addq.w	#2,a1
	bsr	do_cnv_fwd
	subq.w	#1,d2
	beq	exit_al2

	move.l	src_temp2(pc),d4	*edge address
	move.l	d4,a1
	add.l	fsize(a5),a1		*source
**	subq.w	#2,a1
	bsr	do_cnv_rev
	subq.w	#1,d2
	beq	exit_al2

	dbra	d2,@b
exit_al2:
	bra	next_mkpcm

loop_fwd:
	move.l	src_temp2(pc),a1	*source
	move.l	a1,d4
	add.l	fsize(a5),d4		*edge address
	move.w	rept_time(a5),d2
	beq	@f			*0は１回と見なす
	subq.w	#1,d2
@@:
	bsr	do_cnv_fwd
	dbra	d2,@b
	bra	next_mkpcm

loop_rev:
	move.l	src_temp2(pc),d4	*edge address
	move.l	d4,a1
	add.l	fsize(a5),a1		*source
	move.w	rept_time(a5),d2
	beq	@f			*0は１回と見なす
	subq.w	#1,d2
@@:
	bsr	do_cnv_rev
	dbra	d2,@b
	bra	next_mkpcm

loop_alt1:				*←→
	move.w	rept_time(a5),d2
	bne	@f			*0は１回と見なす
	addq.w	#1,d2
@@:
	move.l	src_temp2(pc),d4	*edge address
	move.l	d4,a1
	add.l	fsize(a5),a1		*source
**	subq.w	#2,a1
	bsr	do_cnv_rev
	subq.w	#1,d2
	beq	exit_al1

	move.l	src_temp2(pc),a1	*source
	move.l	a1,d4
	add.l	fsize(a5),d4		*edge address
**	addq.w	#2,a1
	bsr	do_cnv_fwd
	subq.w	#1,d2
	beq	exit_al1

	dbra	d2,@b
exit_al1:
next_mkpcm:
	lea	tbl_size(a5),a5
	bra	mkpcm_lp01

temp_clr:
	move.l	a4,d1
	move.l	pcm_temp(pc),d4
	sub.l	d4,d1
	move.l	d1,-(sp)		*size
	move.l	d4,-(sp)		*address
	DOS	_SETBLOCK
	addq.w	#8,sp
	tst.l	d0
	bmi	out_of_mem

	move.l	src_temp1(pc),-(sp)	*テンポラリエリア解放
	DOS	_MFREE
	addq.w	#4,sp

	move.l	src_temp2(pc),-(sp)
	DOS	_MFREE
	addq.w	#4,sp
frq_chg?:				*周波数変換
	tst.l	s_frq-work(a6)
	beq	portament?
					*テンポラリエリア確保
	move.l	pcm_temp(pc),a2
	move.l	a2,src_temp1-work(a6)	*交換

	move.l	#-1,-(sp)
	DOS	_MALLOC
	addq.w	#4,sp
	andi.l	#$00ffffff,d0
	move.l	d0,d5
	move.l	d0,-(sp)	*取れる限り確保
	DOS	_MALLOC
	addq.w	#4,sp
	move.l	d0,pcm_temp-work(a6)
	bmi	out_of_mem
	move.l	d0,a1		*a1.l=destination buffer address
	add.l	d0,d5		*d5.l=mem. block end address
				*a2.l=source pcm data address
				*パラメータチェック
	move.l	a2,d0		*push a2
	move.l	t_offset(pc),d1
	add.l	a2,d1		*オフセット値が巨大過ぎないか
	bcs	t_offset_err
	move.l	a4,d4
	sub.l	d1,d4		*オフセットが大きすぎないか
	bcs	t_offset_err
	beq	t_offset_err
	move.l	d0,a2		*pop a2

	move.l	t_offset(pc),d1
	lsr.l	d1
	beq	frq_chg_ope	*オフセットなし
@@:				*元データ転送
	move.w	(a2)+,(a1)+
	cmp.l	a1,d5
	bls	out_of_mem
	subq.l	#1,d1
	bne	@b
frq_chg_ope:
	move.l	t_size(pc),d4
	bne	@f
				*サイズ指定がない場合
	move.l	a4,d4
	sub.l	a2,d4
	bra	do_frqchg
@@:				*サイズ指定がある場合
	move.l	d4,d0
	add.l	a2,d0
	cmp.l	a4,d0		*サイズが大きすぎないか
	bhi	t_size_err
do_frqchg:
	lsr.l	d4		*d4.l=data count
	beq	cant_t_err
	move.l	s_frq(pc),d6	*d6.l=source frq
	move.l	d_frq(pc),d7	*d7.l=destination frq
	bsr	do_ajfr		*周波数変換	> a1.l=destination end address
	tst.l	t_size-work(a6)
	beq	mfreetmp1	*サイズ指定がなかった場合はTAIL処理省略
set_tail_ope:			*元データ転送
	move.l	a4,d1
	sub.l	a2,d1
	lsr.l	d1
	beq	mfreetmp1
@@:
	move.w	(a2)+,(a1)+
	cmp.l	a1,d5
	bls	out_of_mem
	subq.l	#1,d1
	bne	@b
mfreetmp1:
	move.l	a1,a4			*辻褄合わせ
	move.l	pcm_temp(pc),d1
	sub.l	d1,a1

	move.l	src_temp1(pc),-(sp)
	DOS	_MFREE
	addq.w	#4,sp

	pea.l	(a1)			*size
	move.l	d1,-(sp)		*address
	DOS	_SETBLOCK
	addq.w	#8,sp
	tst.l	d0
	bmi	out_of_mem
portament?:				*ポルタメント(オートベンド)
	tst.l	s_frq_b-work(a6)
	beq	truncate?
					*テンポラリエリア確保
	move.l	pcm_temp(pc),a2
	move.l	a2,src_temp1-work(a6)	*交換

	move.l	#-1,-(sp)
	DOS	_MALLOC
	addq.w	#4,sp
	andi.l	#$00ffffff,d0
	move.l	d0,d5
	move.l	d0,-(sp)	*取れる限り確保
	DOS	_MALLOC
	addq.w	#4,sp
	move.l	d0,pcm_temp-work(a6)
	bmi	out_of_mem
	move.l	d0,a1		*a1.l=destination buffer address
	add.l	d0,d5		*d5.l=mem. block end address
				*a2.l=source pcm data address
				*パラメータチェック
	move.l	a2,d0		*push a2
	move.l	b_offset(pc),d1
	add.l	a2,d1		*オフセット値が巨大過ぎないか
	bcs	b_offset_err
	move.l	a4,d4
	sub.l	d1,d4		*オフセットが大きすぎないか
	bcs	b_offset_err
	beq	b_offset_err
	move.l	d0,a2		*pop a2

	move.l	b_offset(pc),d1
	lsr.l	d1
	beq	portament_ope	*オフセットなし
@@:				*元データ転送
	move.w	(a2)+,(a1)+
	cmp.l	a1,d5
	bls	out_of_mem
	subq.l	#1,d1
	bne	@b
portament_ope:
	move.l	b_size(pc),d4
	bne	@f
				*サイズ指定がない場合
	move.l	a4,d4
	sub.l	a2,d4
	bra	do_portament
@@:				*サイズ指定がある場合
	move.l	d4,d0
	add.l	a2,d0
	cmp.l	a4,d0		*サイズが大きすぎないか
	bhi	b_size_err
do_portament:
	lsr.l	d4		*d4.l=data count
	beq	cant_b_err
	move.l	s_frq_b(pc),d6	*d6.l=source frq
	move.l	d_frq_b(pc),d7	*d7.l=destination frq
	bsr	do_autobend	*周波数連続変換	> a1.l=destination end address
	tst.l	b_size-work(a6)
	beq	mfreetmp1_b	*サイズ指定がなかった場合はTAIL処理省略
set_tail_ope_b:			*元データ転送
	move.l	a4,d1
	sub.l	a2,d1
	lsr.l	d1
	beq	mfreetmp1_b
@@:
	move.w	(a2)+,(a1)+
	cmp.l	a1,d5
	bls	out_of_mem
	subq.l	#1,d1
	bne	@b
mfreetmp1_b:
	move.l	a1,a4			*辻褄合わせ
	move.l	pcm_temp(pc),d1
	sub.l	d1,a1

	move.l	src_temp1(pc),-(sp)
	DOS	_MFREE
	addq.w	#4,sp

	pea.l	(a1)			*size
	move.l	d1,-(sp)		*address
	DOS	_SETBLOCK
	addq.w	#8,sp
	tst.l	d0
	bmi	out_of_mem
truncate?:				*切り出し
	move.l	cut_offset(pc),d0
	or.l	cut_size(pc),d0
	beq	rev_ope?

	move.l	pcm_temp(pc),a1
	move.l	a1,a2			*destination
	suba.l	a2,a4
	move.l	cut_offset(pc),d2
	cmp.l	a4,d2
	bhi	cut_offset_illegal
	add.l	d2,a1			*source
	move.l	cut_size(pc),d1
	bne	@f
	move.l	a4,d1
	sub.l	d2,d1
@@:
	cmp.l	a4,d1
	bhi	cut_size_illegal
	lea	(a2,d1.l),a4		*辻褄合わせ
	move.l	d1,-(sp)		*size
@@:
	move.b	(a1)+,(a2)+
	subq.l	#1,d1
	bne	@b
	move.l	pcm_temp(pc),-(sp)	*address
	DOS	_SETBLOCK
	addq.w	#8,sp
	tst.l	d0
	bmi	out_of_mem
rev_ope?:				*逆転再生モード
	tst.b	revout_mode-work(a6)
	beq	dis_ope?

	move.l	pcm_temp(pc),a1
	move.l	a1,src_temp1-work(a6)	*交換
	move.l	a4,d4
	sub.l	a1,d4

	move.l	d4,-(sp)		*size
	DOS	_MALLOC
	addq.w	#4,sp
	move.l	d0,pcm_temp-work(a6)
	bmi	out_of_mem
	move.l	d0,a4
	add.l	d4,a1
	lsr.l	d4
@@:
	move.w	-(a1),(a4)+
	subq.l	#1,d4
	bne	@b

	move.l	src_temp1(pc),-(sp)
	DOS	_MFREE
	addq.w	#4,sp
dis_ope?:				*ディストーションモード
*	tst.b	disout_mode-work(a6)
*	beq	env_chg?
*
*	move.l	a4,d4
*	move.l	pcm_temp(pc),a4
*	sub.l	a4,d4
*	lsr.l	d4
*	move.l	#-512,d1
*	move.l	#512,d2
*dislp:
*	move.w	(a4),d0
*	ext.l	d0
*	asl.l	#5,d0
*	cmp.l	d1,d0
*	bge	@f
*	move.w	d1,(a4)+
*	bra	next_dis
*@@:
*	cmp.l	d2,d0
*	ble	@f
*	move.w	d2,(a4)+
*	bra	next_dis
*@@:
*	move.w	d0,(a4)+
*next_dis:
*	subq.l	#1,d4
*	bne	dislp
env_chg?:
	tst.b	fade_mode-work(a6)
	beq	impulse_compound?

	pea	(a4)
	move.l	pcm_temp(pc),a1
	suba.l	a1,a4		*source data size

	move.l	env_offset(pc),d0
	cmp.l	a4,d0
	bcc	env_offset_illegal
	moveq.l	#0,d5
	tst.b	env_type-work(a6)	*check mode
	bne	@f
				*case:fade in
	move.l	d0,d1		*fade count*2
	move.b	env_lvl(pc),d5		*get in level
	moveq.l	#1,d7
	bra	calc_fio
@@:				*case:fade out
	add.l	d0,a1		*start point
	move.l	a4,d1
	sub.l	d0,d1		*fade count*2
	move.b	#128,d5
	moveq.l	#-1,d7
calc_fio:
	lsr.l	d1		*fade count
	move.l	#128,d0
	sub.b	env_lvl(pc),d0	*get in/end level
	move.l	d1,d3
	bsr	wari		d0.l/d1.l=d0.l...d1.l
	move.w	d0,d2		*step
	move.l	d1,d0
	swap	d0
	clr.w	d0		*d0=あまり*65536
	move.l	d3,d1
	bsr	wari		d0.l/d1.l=d0.l...d1.l
	tst.l	d1
	beq	@f
	addq.w	#1,d0
@@:
	move.l	d3,d1
	* < d0.w=rvs
	* < d1.l=count
	* < d2.w=step
	* < d3.b=rvs work
	* < d5.b=now out level
	* < a1.l=address
	tst.b	d7
	bpl	@f
	neg.b	d2		*case:fade out
@@:
	moveq.l	#0,d3		*init rvs work
fio_lp01:
	move.w	(a1),d6
	muls	d5,d6
	asr.l	#7,d6
	move.w	d6,(a1)+
	add.b	d2,d5		*add step
	add.w	d0,d3		*calc revise param.
	bcc	@f
	add.b	d7,d5
@@:
	subq.l	#1,d1
	bne	fio_lp01

	move.l	(sp)+,a4		*辻褄合わせ
impulse_compound?:			*たたみ込み
	tst.b	impulse_mode-work(a6)
	beq	p16out?

	move.l	pcm_temp(pc),a1
	move.l	a1,src_temp1-work(a6)	*交換
	move.l	a4,d4
	sub.l	a1,d4			*d4=input data size

	move.l	impulse_size(pc),d5
	add.l	d4,d5
	lsl.l	d5
	subq.l	#4,d5
	move.l	d5,-(sp)		*size
	DOS	_MALLOC
	addq.w	#4,sp
	move.l	d0,pcm_temp-work(a6)
	bmi	out_of_mem

	move.l	d0,a4
	move.l	d0,a0			*あとで使用
	move.l	d5,d0			*get size again
	lsr.l	#2,d0
@@:
	clr.l	(a4)+			*zero clear
	subq.l	#1,d0
	bne	@b

	lsr.l	d4			*input data count
imp_lp0:
	move.w	(a1)+,d1
	beq	next_a1_
	move.l	impulse_buff(pc),a2	*impulse data
	move.l	impulse_size(pc),d2	*impulse size
	lsr.l	d2
	move.l	a0,a4
imp_lp1:
	move.w	(a2)+,d0
	muls.w	d1,d0
	add.l	d0,(a4)+
	subq.l	#1,d2
	bne	imp_lp1
next_a1_:
	addq.w	#4,a0
	subq.l	#1,d4
	bne	imp_lp0

	move.l	pcm_temp(pc),a1
	move.l	a1,a4
	move.l	a1,d2
	lsr.l	#2,d5
@@:
	move.l	(a1)+,d0
	swap	d0			*/65536
	move.w	d0,(a4)+
	subq.l	#1,d5
	bne	@b
	move.l	a4,d0
	sub.l	d2,d0

	move.l	d0,-(sp)		*size
	move.l	d2,-(sp)		*address
	DOS	_SETBLOCK
	addq.w	#8,sp
	tst.l	d0
	bmi	out_of_mem

	move.l	impulse_buff(pc),-(sp)
	DOS	_MFREE
	addq.w	#4,sp

	move.l	src_temp1(pc),-(sp)
	DOS	_MFREE
	addq.w	#4,sp
p16out?:				*ＰＣＭコンバート?
	tst.b	p16out_mode-work(a6)
	beq	adpout?

	move.l	pcm_temp(pc),a1
	move.l	a1,src_temp1-work(a6)	*交換

	suba.l	a1,a4
	move.l	a4,d1
	lsl.l	#2,d1
	move.l	d1,-(sp)
	DOS	_MALLOC
	addq.w	#4,sp
	move.l	d0,pcm_temp-work(a6)
	bmi	out_of_mem
	move.l	d0,a0			*destination
	move.l	a4,d0			*adpcm data size
	lea	(a0,d1.l),a4		*辻褄合わせ
	exg.l	a0,a1
	bsr	just_adpcm_to_pcm

	move.l	src_temp1(pc),-(sp)	*ADPCMデータの解放
	DOS	_MFREE
	addq.w	#4,sp
	bra	generate
adpout?:
	tst.b	adpout_mode-work(a6)
	beq	generate

	move.l	pcm_temp(pc),a1
	move.l	a1,src_temp1-work(a6)	*交換

	suba.l	a1,a4
	move.l	a4,d1
	lsr.l	#2,d1
	move.l	d1,-(sp)
	DOS	_MALLOC
	addq.w	#4,sp
	move.l	d0,pcm_temp-work(a6)
	bmi	out_of_mem
	move.l	d0,a0			*destination
	move.l	a4,d0			*pcm data size
	lea	(a0,d1.l),a4		*辻褄合わせ
	bsr	pcm_to_adpcm

	move.l	src_temp1(pc),-(sp)	*PCMデータの解放
	DOS	_MFREE
	addq.w	#4,sp
generate:
	lea	d_name(pc),a0
	move.l	(a0),d0
	andi.l	#$dfdf_dfff,d0
	cmpi.l	#$50434d00,d0
	bne	@f
	move.w	#%0_000_01,-(sp)
	pea	(a0)
	DOS	_OPEN
	addq.w	#6,sp
	tst.l	d0
	bpl	copy_fh
@@:
	move.w	#32,-(sp)
	pea	(a0)
	DOS	_CREATE
	addq.w	#6,sp
	tst.l	d0
	bmi	wopen_error
copy_fh:
	move.w	d0,d5

	move.l	pcm_temp(pc),d1
	suba.l	d1,a4
	pea	(a4)			*size
	move.l	d1,-(sp)		*address
	move.w	d5,-(sp)		*filehandle
	DOS	_WRITE
	lea	10(sp),sp
	tst.l	d0
	bmi	write_error
	cmp.l	a4,d0			*完全にセーブできたか
	bne	device_full

	move.w	d5,-(sp)
	DOS	_CLOSE
	addq.w	#2,sp

	clr.l	-(sp)
	DOS	_MFREE
	addq.w	#4,sp

	print	no_er_mes(pc)

	DOS	_EXIT

do_ajfr:
	* < d4.l=data count
	* < d5.l=mem.block end address
	* < d6.w=source frq
	* < d7.w=destination frq
	* < a1.l=destination pcm data address
	* < a2.l=source pcm data address
	* > a1.l=destination pcm data size
	* X d0-d7
	exg.l	d6,d7
	divu	d6,d7
	move.w	d7,d1		*d1=step
	clr.w	d7
	divu	d6,d7
	swap	d7
	tst.w	d7
	beq	@f
	add.l	#$0001_0000,d7
	clr.w	d7
@@:
	swap	d7		*d7=revise
	moveq.l	#0,d3
	tst.w	d1
	bne	nz_d1
doa_lp00:
	move.w	(a2)+,d0
	add.w	d7,d3
	bcc	@f
	move.w	d0,(a1)+
	cmp.l	a1,d5
	bls	out_of_mem
@@:
	subq.l	#1,d4
	bne	doa_lp00
	bra	exit_doa
nz_d1:
	move.w	d1,d6
	move.w	(a2)+,d0
	move.w	(a2),d2
	cmpi.l	#1,d4		*最後かどうか
	bne	@f
	move.w	d0,d2
@@:
	add.w	d7,d3
	bcc	@f
	addq.w	#1,d6
@@:
	ext.l	d0
	ext.l	d2
	movem.l	d1/d3,-(sp)
	sub.l	d0,d2
	divs	d6,d2
	move.w	d2,d1		*d1=step
	clr.w	d2
	divu	d6,d2
	swap	d2
	tst.w	d2
	beq	@f
	add.l	#$0001_0000,d2
	clr.w	d2
@@:
	swap	d2		*d2=revise
	moveq.l	#0,d3
doa_lp01:
	move.w	d0,(a1)+
	cmp.l	a1,d5
	bls	out_of_mem
@@:
	add.w	d1,d0
	add.w	d2,d3
	bcc	@f
	tst.w	d1
	bpl	doa_pls
	subq.w	#1,d0
	bra	@f
doa_pls:
	addq.w	#1,d0
@@:
	subq.w	#1,d6
	bne	doa_lp01
	movem.l	(sp)+,d1/d3
	subq.l	#1,d4
	bne	nz_d1
exit_doa:
*	move.l	a1,d1
	rts

do_autobend:
	* < d4.l=data count
	* < d5.l=mem.block end address
	* < d6.w=source frq
	* < d7.w=destination frq
	* < a1.l=destination pcm data address
	* < a2.l=source pcm data address
	* > a1.l=destination pcm data size
	* X d0-d7
	exg.l	d6,d7
	move.l	d6,atb_frqsrc-work(a6)
	move.l	d6,atb_frqnow-work(a6)
				*周波数変化率計算
	move.l	d4,d1
	move.l	d7,d0
	sub.l	d6,d0
	bpl	@f
	neg.l	d0
	bsr	wari		*d0.l/d1.l=d0.l...d1.l
	neg.l	d0
	move.l	d0,atb_step-work(a6)		*周波数変化率
	move.l	#-1,atb_sgn-work(a6)
	bra	atb0
@@:
	bsr	wari		*d0.l/d1.l=d0.l...d1.l
	move.l	d0,atb_step-work(a6)		*周波数変化率
	move.l	#1,atb_sgn-work(a6)
atb0:
	swap	d1
	clr.w	d1
	move.l	d1,d0
	move.l	d4,d1
	bsr	wari		*d0.l/d1.l=d0.l...d1.l
	tst.l	d1
	beq	@f
	addq.l	#1,d0		*revise
@@:
	move.w	d0,atb_rvs-work(a6)

	bsr	calc_frqchgrate

	moveq.l	#0,d3
	move.w	d3,atb_rvswk-work(a6)

	tst.b	atb_sgn-work(a6)
	bpl	nz_d1_b
doa_lp00_b:
	move.w	(a2)+,d0
	add.w	d7,d3
	bcc	@f
	move.w	d0,(a1)+
	cmp.l	a1,d5
	bls	out_of_mem
@@:
	bsr	calc_frqchgrate
	subq.l	#1,d4
	bne	doa_lp00_b
	bra	exit_doa_b
nz_d1_b:
	move.w	d1,d6
	move.w	(a2)+,d0
	move.w	(a2),d2
	cmpi.l	#1,d4		*最後かどうか
	bne	@f
	move.w	d0,d2
@@:
	add.w	d7,d3
	bcc	@f
	addq.w	#1,d6
@@:
	ext.l	d0
	ext.l	d2
	movem.l	d1/d3,-(sp)
	sub.l	d0,d2
	divs	d6,d2
	move.w	d2,d1		*d1=step
	clr.w	d2
	divu	d6,d2
	swap	d2
	tst.w	d2
	beq	@f
	add.l	#$0001_0000,d2
	clr.w	d2
@@:
	swap	d2		*d2=revise
	moveq.l	#0,d3
doa_lp01_b:
	move.w	d0,(a1)+
	cmp.l	a1,d5
	bls	out_of_mem
@@:
	add.w	d1,d0
	add.w	d2,d3
	bcc	@f
	tst.w	d1
	bpl	doa_pls_b
	subq.w	#1,d0
	bra	@f
doa_pls_b:
	addq.w	#1,d0
@@:
	subq.w	#1,d6
	bne	doa_lp01_b
	movem.l	(sp)+,d1/d3
	bsr	calc_frqchgrate
	subq.l	#1,d4
	bne	nz_d1_b
exit_doa_b:
*	move.l	a1,d1
	rts

calc_frqchgrate:			*変換パラメータの計算
	movem.l	atb_frqsrc(pc),d6-d7
	add.l	atb_step(pc),d7
	move.w	atb_rvs(pc),d1
	add.w	d1,atb_rvswk-work(a6)
	bcc	@f
	add.l	atb_sgn(pc),d7
@@:
	move.l	d7,atb_frqnow-work(a6)

	divu	d6,d7
	move.w	d7,d1		*d1=step
	clr.w	d7
	divu	d6,d7
	swap	d7
	tst.w	d7
	beq	@f
	add.l	#$0001_0000,d7
	clr.w	d7
@@:
	swap	d7		*d7=revise
	rts

do_cnv_fwd:
	* < d4.l=source edge address
	* < a1.l=source pcm data
	* < a3.l=destination buffer end address
	* < a4.l=destination buffer
	* X a4
	tst.w	conv_type(a5)
	beq	@f
	bpl	do_cnv_fwd_
@@:
	movem.l	d0-d1/a1,-(sp)
	move.w	vol_val(pc),d1
@@:
	move.w	(a1)+,d0
	muls	d1,d0		*音量変換
	asr.l	#8,d0
	move.w	d0,(a4)+
	cmp.l	a3,a4
	bcc	out_of_mem
	cmp.l	a1,d4
	bhi	@b
	movem.l	(sp)+,d0-d1/a1
	rts
do_cnv_fwd_:
	movem.l	d0/a1,-(sp)
@@:
	move.w	(a1)+,(a4)+
	cmp.l	a3,a4
	bcc	out_of_mem
	cmp.l	a1,d4
	bhi	@b
	movem.l	(sp)+,d0/a1
	rts

do_cnv_rev:
	* < d4.l=source edge address
	* < a1.l=source pcm data
	* < a3.l=destination buffer end address
	* < a4.l=destination buffer
	* X a4
	tst.w	conv_type(a5)
	beq	@f
	bpl	do_cnv_rev_
@@:
	movem.l	d0-d1/a1,-(sp)
	move.w	vol_val(pc),d1		*音量変換
@@:
	move.w	-(a1),d0
	muls	d1,d0		*音量変換
	asr.l	#8,d0
	move.w	d0,(a4)+
	cmp.l	a3,a4
	bcc	out_of_mem
	cmp.l	d4,a1
	bhi	@b
	movem.l	(sp)+,d0-d1/a1
	rts
do_cnv_rev_:
	movem.l	d0/a1,-(sp)
@@:
	move.w	-(a1),(a4)+
	cmp.l	a3,a4
	bcc	out_of_mem
	cmp.l	d4,a1
	bhi	@b
	movem.l	(sp)+,d0/a1
	rts

just_adpcm_to_pcm:		*ピッチチェンジやレベルチェンジを
				*行わない単なるADPCM→PCM変換
	* < a0=adpcm data buffer
	* < a1=pcm data buffer
	* < d0.l=adpcm data size
	movem.l	d0-d7/a0-a6,-(sp)
	lea	scaleval(pc),a5
	lea	levelchg(pc),a6
	moveq.l	#0,d3
	moveq.l	#0,d7
	moveq.l	#$0f,d4
	add.l	d0,d0
	lea	last_val(pc),a3
	move.w	d3,(a3)
__atp_lp:
	move.b	(a0),d1
	and.w	d4,d1
	tst.b	d4
	bpl	@f
	lsr.b	#4,d1		*get 4bit data
	addq.w	#1,a0
@@:
	not.b	d4
	bsr	calc_pcm_val	*実際の計算
	move.w	d2,(a1)+	*add pcm data to buffer
	subq.l	#1,d0
	bne	__atp_lp
	movem.l	(sp)+,d0-d7/a0-a6
	rts

adpcm_to_pcm:			*レベルチェンジを
				*行うADPCM→PCM変換
	* < a0=adpcm data buffer
	* < a1=pcm data buffer
	* < d0.l=adpcm data size
	* < d6.w=volume value 0～256
	movem.l	d0-d7/a0-a6,-(sp)
	lea	scaleval(pc),a5
	lea	levelchg(pc),a6
	moveq.l	#0,d3
	moveq.l	#0,d7
	moveq.l	#$0f,d4
	add.l	d0,d0
	lea	last_val(pc),a3
	move.w	d3,(a3)
atp_lp:
	move.b	(a0),d1
	and.w	d4,d1
	tst.b	d4
	bpl	@f
	lsr.b	#4,d1		*get 4bit data
	addq.w	#1,a0
@@:
	not.b	d4
	bsr	calc_pcm_val	*実際の計算
	muls	d6,d2
	asr.l	#8,d2
	move.w	d2,(a1)+	*add pcm data to buffer
	subq.l	#1,d0
	bne	atp_lp
	movem.l	(sp)+,d0-d7/a0-a6
	rts

pcm_to_adpcm:			*ＰＣＭデータをＡＤＰＣＭデータへ変換する
	* < a0=adpcm data buffer
	* < a1=pcm data buffer
	* < d0.l=pcm data size
	* - all

	movem.l	d0-d7/a0-a6,-(sp)

	lea	scaleval(pc),a5
	lea	levelchg(pc),a6

	moveq.l	#0,d6		*scalelevel=0
	moveq.l	#0,d7
	moveq.l	#0,d4
	lsr.l	d0
	lea	last_val(pc),a3
	move.w	d4,(a3)		*clr.w	(a3)
pta_lp:
	move.w	(a1)+,d3	*d3=pcm data

calc_adpcm_val:
	* < d3.w=pcm value
	* < d7.w=scale level
	* > d1.b=adpcm value
	* > d7.w=next scale level
	* X
	sub.w	(a3),d3		*d3=diff
	bmi	case_diff_minus
	moveq.l	#0,d1
	bra	calc_diff
case_diff_minus:
	neg.w	d3
	moveq.l	#8,d1		*d1:become data
calc_diff:
	add.b	d7,d7
	move.w	(a5,d7.w),d2	*=d
	lsr.b	d7

	cmp.w	d3,d2
	bge	_or2
	sub.w	d2,d3
	ori.b	#4,d1
_or2:
	lsr.w	d2
	cmp.w	d3,d2
	bge	_or1
	sub.w	d2,d3
	ori.b	#2,d1
_or1:
	lsr.w	d2
	cmp.w	d3,d2
	bge	chg_scalelvl
	ori.b	#1,d1

chg_scalelvl:
	add.b	d1,d1
	add.w	(a6,d1.w),d7		*scalelevl+=levelchg(adpcm value)
	bmi	rst_sclv_
	cmpi.w	#48,d7
	bls	mk_olv
	moveq.l	#48,d7
	bra	mk_olv
rst_sclv_:
	moveq.l	#0,d7
mk_olv:
	exg	d7,d6
	bsr	calc_pcm_val_
	exg	d6,d7
*-----------------------------------------------------------------------------
	not.b	d4
	bne	set_lower
				*case upper 4bits
	lsl.b	#3,d1
	or.b	d1,d5
	move.b	d5,(a0)+
	bra	check_cnt
set_lower:
	lsr.b	d1
	move.b	d1,d5
check_cnt:
	subq.l	#1,d0
	bne	pta_lp
	movem.l	(sp)+,d0-d7/a0-a6
	rts

calc_pcm_val:
	* < d1.b=adpcm value
	* < d7.w=scale level
	* > d2.w=pcm value
	* > d7.w=next scale level
	* > d1.b=adpcm*2
	* < a3.l=last_val
	* X d3 d2
	add.b	d1,d1
calc_pcm_val_:
	add.b	d7,d7
	move.w	(a5,d7.w),d3	*=d
	lsr.b	d7

	move.w	cpv(pc,d1.w),d2
	jmp	cpv(pc,d2.w)
abc:
	add.w	(a3),d2
*	bsr	chk_ovf
	move.w	d2,(a3)		*d2=pcmdata

	add.w	(a6,d1.w),d7		*scalelevl+=levelchg(adpcm value)
	bmi	rst_sclv
	cmpi.w	#48,d7
	bls	allend
	moveq.l	#48,d7
allend:
	rts
rst_sclv:
	moveq.l	#0,d7
	rts

cpv:
	dc.w	cpv0000-cpv
	dc.w	cpv0001-cpv
	dc.w	cpv0010-cpv
	dc.w	cpv0011-cpv
	dc.w	cpv0100-cpv
	dc.w	cpv0101-cpv
	dc.w	cpv0110-cpv
	dc.w	cpv0111-cpv
	dc.w	cpv1000-cpv
	dc.w	cpv1001-cpv
	dc.w	cpv1010-cpv
	dc.w	cpv1011-cpv
	dc.w	cpv1100-cpv
	dc.w	cpv1101-cpv
	dc.w	cpv1110-cpv
	dc.w	cpv1111-cpv

cpv0000:
	lsr.w	#3,d3
	move.w	d3,d2
	bra	abc
cpv0001:
	lsr.w	#2,d3
	move.w	d3,d2
	lsr.w	d3
	add.w	d3,d2
	bra	abc
cpv0010:
	lsr.w	d3
	move.w	d3,d2
	lsr.w	#2,d3
	add.w	d3,d2
	bra	abc
cpv0011:
	lsr.w	d3
	move.w	d3,d2
	lsr.w	d3
	add.w	d3,d2
	lsr.w	d3
	add.w	d3,d2
	bra	abc
cpv0100:
	move.w	d3,d2
	lsr.w	#3,d3
	add.w	d3,d2
	bra	abc
cpv0101:
	move.w	d3,d2
	lsr.w	#2,d3
	add.w	d3,d2
	lsr.w	d3
	add.w	d3,d2
	bra	abc
cpv0110:
	move.w	d3,d2
	lsr.w	d3
	add.w	d3,d2
	lsr.w	#2,d3
	add.w	d3,d2
	bra	abc
cpv0111:
	move.w	d3,d2
	lsr.w	d3
	add.w	d3,d2
	lsr.w	d3
	add.w	d3,d2
	lsr.w	d3
	add.w	d3,d2
	bra	abc
cpv1000:
	lsr.w	#3,d3
	move.w	d3,d2
	neg.w	d2
	bra	abc
cpv1001:
	lsr.w	#2,d3
	move.w	d3,d2
	lsr.w	d3
	add.w	d3,d2
	neg.w	d2
	bra	abc
cpv1010:
	lsr.w	d3
	move.w	d3,d2
	lsr.w	#2,d3
	add.w	d3,d2
	neg.w	d2
	bra	abc
cpv1011:
	lsr.w	d3
	move.w	d3,d2
	lsr.w	d3
	add.w	d3,d2
	lsr.w	d3
	add.w	d3,d2
	neg.w	d2
	bra	abc
cpv1100:
	move.w	d3,d2
	lsr.w	#3,d3
	add.w	d3,d2
	neg.w	d2
	bra	abc
cpv1101:
	move.w	d3,d2
	lsr.w	#2,d3
	add.w	d3,d2
	lsr.w	d3
	add.w	d3,d2
	neg.w	d2
	bra	abc
cpv1110:
	move.w	d3,d2
	lsr.w	d3
	add.w	d3,d2
	lsr.w	#2,d3
	add.w	d3,d2
	neg.w	d2
	bra	abc
cpv1111:
	move.w	d3,d2
	lsr.w	d3
	add.w	d3,d2
	lsr.w	d3
	add.w	d3,d2
	lsr.w	d3
	add.w	d3,d2
	neg.w	d2
	bra	abc

	.include	fopen.s

read_data:			*ディスクからの読み込み
	* < (a1)=file name
	movem.l	d0/d3/d5/a0-a2,-(sp)

	move.l	a1,a2
	bsr	go_fopen
	tst.l	d5		*d5=file handle
	bpl	@f
	bsr	fopen
	tst.l	d5		*d5=file handle
	bmi	ropen_error
@@:
	bsr	get_fsize
	bmi	size_error	*illegal file size
	move.l	d3,d1		*d1.l=size

	move.l	d1,-(sp)	*size
	move.l	src_temp1(pc),d2
	move.l	d2,-(sp)	*address
	move.w	d5,-(sp)	*file handle
	DOS	_READ
	lea	10(sp),sp
	tst.l	d0
	bmi	read_error

	move.w	d5,-(sp)
	DOS	_CLOSE
	addq.w	#2,sp

	movem.l	(sp)+,d0/d3/d5/a0-a2
	rts

read_data2:			*インパルスデータのディスクからの読み込み
	* < (a1)=file name
	movem.l	d0/d3/d5/a0-a2,-(sp)

	move.l	a1,a2
	bsr	go_fopen
	tst.l	d5		*d5=file handle
	bpl	@f
	bsr	fopen
	tst.l	d5		*d5=file handle
	bmi	ropen_error_
@@:
	bsr	get_fsize
	bmi	size_error	*illegal file size
	move.l	d3,d1		*d1.l=size

	move.l	d1,-(sp)
	DOS	_MALLOC
	addq.l	#4,sp
	move.l	d0,impulse_buff-work(a6)
	bmi	out_of_mem

	move.l	d1,-(sp)		*size
	move.l	impulse_buff(pc),-(sp)	*address
	move.w	d5,-(sp)		*file handle
	DOS	_READ
	lea	10(sp),sp
	move.l	d0,impulse_size-work(a6)
	bmi	read_error

	move.w	d5,-(sp)
	DOS	_CLOSE
	addq.w	#2,sp

	movem.l	(sp)+,d0/d3/d5/a0-a2
	rts

check_fopen:			*ファイルが存在するかのチェック
	* < (a1)=file name
	* > d1.l=size
	movem.l	d0/d3/d5/a0-a2,-(sp)

	move.l	a1,a2
	bsr	go_fopen
	tst.l	d5		*d5=file handle
	bpl	@f
	bsr	fopen
	tst.l	d5		*d5=file handle
	bmi	ropen_error
@@:
	bsr	get_fsize
	bmi	size_error	*illegal file size
	move.l	d3,d1		*d1.l=size

	move.w	d5,-(sp)
	DOS	_CLOSE
	addq.w	#2,sp

	movem.l	(sp)+,d0/d3/d5/a0-a2
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

skip_spc:			*スペースを読み飛ばす(case:command line)
	cmpi.b	#' ',(a2)+
	beq	skip_spc
	subq.w	#1,a2
	rts

skip_sep:			*セパレータをスキップする(スペースやタブも)
	move.l	d0,-(sp)
	bsr	skip_spc
@@:
	move.b	(a2)+,d0
	cmpi.b	#',',d0
	beq	@f
	subq.w	#1,a2
@@:
	move.l	(sp)+,d0
	rts

mk_capital:			*小文字→大文字(英字以外の場合はそのままthrough out)
	* < d0.b=letter chr
	cmpi.b	#'a',d0
	bcs	@f
	cmpi.b	#'z',d0
	bhi	@f
	andi.w	#$df,d0		*わざと.w
@@:
	rts

chk_num:			*数字かどうかチェック(for command line)
	* > eq=number
	* > mi=not num
	bsr	skip_spc
	cmpi.b	#'0',(a2)
	bcs	not_num
	cmpi.b	#'9',(a2)
	bhi	not_num
	move.w	#%0000_0100,ccr	*eq
	rts
not_num:
	move.w	#%0000_1000,ccr	*mi
	rts

asc_to_n:			*数字文字列を数値へ
	* < (a2)=number strings
	* > d1.l=value
	* > a2=next
	* x none
	movem.l	d0/d2-d3,-(sp)
	moveq.l	#0,d1
	moveq.l	#0,d0
	cmpi.b	#'+',(a2)
	bne	@f
	addq.w	#1,a2
@@:
num_lp01:
	move.b	(a2),d0
	sub.b	#$30,d0
	bmi	num_exit
	cmp.b	#9,d0
	bhi	num_exit
	addq.w	#1,a2
	add.l	d1,d1
	move.l	d1,d3
	lsl.l	#2,d1
	add.l	d3,d1		*d1=d1*10
	add.l	d0,d1		*d1=d1+d0
	bra	num_lp01
num_exit:
	movem.l	(sp)+,d0/d2-d3
	rts

wari:				*32ﾋﾞｯﾄ/32ﾋﾞｯﾄ=32ﾋﾞｯﾄ...32ﾋﾞｯﾄ
	* < d0.l/d1.l=d0.l ...d1.l
	cmpi.l	#$ffff,d1
	bls	divx		*16ビット以下の数値なら１命令で処理
	cmp.l	d0,d1
	beq	div01		*d0=d1商は１
	bls	div02		*１命令では無理なケース

	move.l	d0,d1		*商は０余りはd0.l
	moveq.l	#0,d0
	rts
div01:				*商は１余り０
	moveq.l	#1,d0
	moveq.l	#0,d1
	rts
div02:
	movem.l	d3-d5,-(sp)
	move.l	d1,d3
	clr.w	d3
	swap	d3
	addq.l	#1,d3
	move.l	d0,d4
	move.l	d1,d5
	move.l	d3,d1
	bsr	divx
	move.l	d5,d1
	divu	d3,d1
	divu	d1,d0
	andi.l	#$ffff,d0
div03:
	move.l	d5,d1
	move.l	d5,d3
	swap	d3
	mulu	d0,d1
	mulu	d0,d3
	swap	d3
	add.l	d3,d1
	sub.l	d4,d1
	bhi	div04
	neg.l	d1
	cmp.l	d1,d5
	bhi	div05
	addq.l	#1,d0
	bra	div03
div04:
	subq.l	#1,d0
	bra	div03
div05:
	movem.l	(sp)+,d3-d5
	rts
divx:
	movem.w	d0/d3,-(sp)
	clr.w	d0
	swap	d0
	divu	d1,d0
	move.w	d0,d3
	move.w	(sp)+,d0
	divu	d1,d0
	swap	d0
	moveq.l	#0,d1
	move.w	d0,d1
	move.w	d3,d0
	swap	d0
	move.w	(sp)+,d3
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

error_exit:
	clr.w	-(sp)
	DOS	_KFLUSH
	addq.w	#2,sp

	move.w	#1,-(sp)
	DOS	_EXIT2

close_kill:			*書き込もうとしたファイルを消す
	DOS	_ALLCLOSE
	pea	d_name(pc)
	DOS	_DELETE
	addq.w	#4,sp
	rts

show_help:
	bprint	help(pc)
	print	more(pc)
	DOS	_INKEY
	move.l	#$000d_0002,-(sp)
	DOS	_FPUTC
	addq.w	#4,sp
	bprint	help2(pc)
	bra	error_exit

out_of_mem:
	bsr	close_kill
	bprint	out_of_mem_mes(pc)
	bra	error_exit

write_error:
	bsr	close_kill
	bprint	wrt_er_mes(pc)
	bra	error_exit

device_full:
	bsr	close_kill
	bprint	devful_mes(pc)
	bra	error_exit

l_illegal:
	bprint	l_illegal_mes(pc)
	bra	error_exit

r_illegal:
	bprint	r_illegal_mes(pc)
	bra	error_exit

t_illegal:
	bprint	t_illegal_mes(pc)
	bra	error_exit

v_illegal:
	bprint	v_illegal_mes(pc)
	bra	error_exit

too_many_s:
	bprint	too_many_s_mes(pc)
	bra	error_exit

no_v_param:
	bprint	no_v_param_mes(pc)
	bra	error_exit

ropen_error:
	bprint	open_er_mes(pc)
	print	fname(a5)
	print	close_blnkt(pc)
	bra	error_exit

ropen_error_:
	bprint	open_er_mes(pc)
	print	(a1)
	print	close_blnkt(pc)
	bra	error_exit

wopen_error:
	bprint	open_er_mes(pc)
	print	d_name(pc)
	print	close_blnkt(pc)
	bra	error_exit

size_error:
	bprint	size_er_mes(pc)
	bra	error_exit

read_error:
	bprint	read_er_mes(pc)
	bra	error_exit

no_s_error:
	bprint	no_s_mes(pc)
	bra	error_exit

no_d_error:
	bprint	no_d_mes(pc)
	bra	error_exit

s_illegal:
	bprint	s_illegal_mes(pc)
	bra	error_exit

d_illegal:
	bprint	d_illegal_mes(pc)
	bra	error_exit

unex_error:
	bprint	unex_er_mes(pc)
	bra	error_exit

not_support:
	bprint	not_sup_er_mes(pc)
	bra	error_exit

cut_size_illegal:
	bprint	cutsize_er_mes(pc)
	bra	error_exit

cut_offset_illegal:
	bprint	cutoff_er_mes(pc)
	bra	error_exit

env_offset_illegal:
	bprint	envoff_er_mes(pc)
	bra	error_exit

envlvl_illegal:
	bprint	envlvl_er_mes(pc)
	bra	error_exit

envtype_illegal:
	bprint	envtype_er_mes(pc)
	bra	error_exit

t_offset_err:
	bprint	trnoff_er_mes(pc)
	bra	error_exit

t_size_err:
	bprint	trnsize_er_mes(pc)
	bra	error_exit

cant_t_err:
	bprint	cant_t_er_mes(pc)
	bra	error_exit

b_offset_err:
	bprint	bndoff_er_mes(pc)
	bra	error_exit

b_size_err:
	bprint	bndsize_er_mes(pc)
	bra	error_exit

cant_b_err:
	bprint	cant_b_er_mes(pc)
	bra	error_exit

illegal_frq:
	bprint	illegal_fr_mes(pc)
	bra	error_exit

unid_err:
	bprint	unid_mes(pc)
	bra	error_exit

bil_prta1_:				*日本語対応
	movem.l	d0/a1,-(sp)
	move.l	4*2+4(sp),a1
	tst.b	errmes_lang-work(a6)	*0:英語か 1:日本語か
	beq	prta1_
@@:					*次のメッセージをゲット
	tst.b	(a1)+
	bne	@b
prta1_:
	pea	(a1)
	DOS	_PRINT
	addq.w	#4,sp
	movem.l	(sp)+,d0/a1
	rts

	.data
work:
title:	dc.b	'Z-MUSIC PCM FILE LINKER '
	dc.b	$f3,'V',$F3,'E',$F3,'R',$F3,'S',$F3,'I',$F3,'O',$F3,'N'
	version
	test
	dc.b	' (C) 1993,94,95,96 ZENJI SOFT',13,10,0
help:	dc.b	'< USAGE > ZPLK.R <[OPTIONS] SOURCE1> [[OPTIONS] SOURCE2～32] <DESTINATION>',13,10
	dc.b	'< OPTIONAL SWITCHES >',13,10
	dc.b	'-A            Execute ADPCM conversion before generate the destination.',13,10
	dc.b	'-B<s,d>[p,s]  Bend the pitch from s(1～65535)[Hz] to d(1～65535)[Hz].',13,10
	dc.b	'  p           Pitch-bend start point (default=0)',13,10
	dc.b	'  s           Pitch-bend size',13,10
	dc.b	'-C[p]<,s>     Truncate the destination.',13,10
	dc.b	'  p           Truncate start point (default=0)',13,10
	dc.b	'  s           Truncate size',13,10
	dc.b	'-F[s,l,m]     Transform the envelope of the destination.',13,10
	dc.b	'  s           Start point (default=0)',13,10
	dc.b	'  l           IN/END level (0～127, default=0)',13,10
	dc.b	'  m           Transform mode (default=1)',13,10
	dc.b	'              0 Fade in',13,10
	dc.b	'              1 Fade out',13,10
	dc.b	'-I<filename>  Convolute the destination with impulse data.',13,10
	dc.b	'  filename    Filename of the impulse data',13,10
	dc.b	'-J            Messages will be displayed in Japanese.',13,10
	dc.b	0
        dc.b    '< 使用方法 > ZPLK.R <[ｵﾌﾟｼｮﾝ] 入力ﾌｧｲﾙ名1> [[ｵﾌﾟｼｮﾝ] 入力ﾌｧｲﾙ名2～32] <出力ﾌｧｲﾙ名>',13,10
        dc.b    '< オプション >',13,10
        dc.b    '-A         出力ファイルを出力する前にそのデータを16ビットPCMデータと',13,10
        dc.b    '           見なしてADPCMデータへ変換する。',13,10
        dc.b    '-Bs,d,p,s  出力ファイルを出力する前にそのデータを16ビットPCMデータと',13,10
        dc.b    '           見なしてポルタメントを行なう。(連続的に滑らかに周波数変更を行なう。)',13,10
        dc.b    '  s        開始時の周波数をs[Hz]とみなす。ただしsは1～65535。',13,10
        dc.b    '  d        終了時の周波数をd[Hz]とする。ただしdは1～65535。',13,10
        dc.b    '  p        出力ファイルのpバイト目から周波数変換を行なう。省略時はp=0。',13,10
        dc.b    '  s        変換するサイズをsバイトとする。省略時はpで指定された位置から',13,10
        dc.b    '           後ろ全部を変換対象領域とする。pも省略した場合は出力全域に対して',13,10
        dc.b    '           変換処理を施す。',13,10
        dc.b    '-Cp,s      出力ファイルを出力する前にそのデータの任意の一部分を摘出しそれを',13,10
        dc.b    '           出力する。',13,10
        dc.b    '  p        出力ファイルのpバイト目から切り出す。省略時はp=0。',13,10
        dc.b    '  s        切り出すサイズをsバイトとする。省略時はpで指定された位置から',13,10
        dc.b    '           後ろ全部を切り出す。pも省略した場合はエラーとなる。',13,10
        dc.b    '-Fs,l,m    出力ファイルを出力する前にそのデータを16ビットPCMデータと',13,10
        dc.b    '           見なしてエンベロープの形状を変化させる。',13,10
        dc.b    '  s        出力ファイルのsバイト目からエンベロープ形状を変更する。',13,10
        dc.b    '           省略時はs=0。',13,10
        dc.b    '  l        エンベロープ形状初期音量(m=0時)／最終音量(m=1時)を0～127の128段階で',13,10
        dc.b    '           設定する。省略時はl=0。',13,10
        dc.b    '  m        エンベロープの変更パターンを設定する。省略時はm=1',13,10
        dc.b    '           0 フェード・イン・タイプ',13,10
        dc.b    '           1 フェード・アウト・タイプ',13,10
	dc.b	0
help2:
	dc.b	'-P            Execute 16bit PCM conversion before generate the destination.',13,10
	dc.b	'-R            Generate the destination in reversive sequence.',13,10
	dc.b	'-V<n>         Set n(1～300)[%] for an output level.(default=100)',13,10
	dc.b	'-T<i,o>[,p,s] Transform the frequency from i(1～65535)[Hz] to o(1～65535)[Hz].',13,10
	dc.b	'  p           Transformation start point.(default=0)',13,10
	dc.b	'  s           Transformation size',13,10
	dc.b	'-X[l,r,t]     Define SUB-CONVERSION parameter',13,10
	dc.b	'  l           Loop type (default=0)',13,10
	dc.b	'              0 Forward',13,10
	dc.b	'              1 Alternative #1(←→)',13,10
	dc.b	'              2 Alternative #2(→←)',13,10
	dc.b	'              3 Reversive',13,10
	dc.b	'  r           Repeat r(1～65535) times by type l scan.(default=1)',13,10
	dc.b	'  t           Type of the source prior conversion.(default=0)',13,10
	dc.b	'              0 No Conversion',13,10
	dc.b	'              1 Regard the given source as 16bit PCM data,',13,10
	dc.b	'                convert it to ADPCM before link operation.',13,10
	dc.b	'              2 Regard the given source as ADPCM data,',13,10
	dc.b	'                convert it to 16bit PCM data before link operation.',13,10
	dc.b	0
        dc.b    '-Ifilename インバルスデータのファイルネームを与えると出力ファイル出力する前に',13,10
        dc.b    '       　  そのデータとのたたみ込み演算を行なう。ただし、与えられたファイルネームの',13,10
        dc.b    "           拡張子を'.P16'とした場合はそのインパルスデータを16ビットPCMデータ、",13,10
        dc.b    "           '.PCM'とした場合はADPCMデータとしてみなす。",13,10
	dc.b	'-J         日本語メッセージ表示',13,10
        dc.b    '-P         出力ファイルを出力する前にそのデータをADPCMデータと見なして',13,10
        dc.b    '           16ビットPCMデータへ変換する。',13,10
        dc.b    '-R         出力ファイルを出力する前にそのデータを16ビットPCMデータと',13,10
        dc.b    '           見なして逆転させる。',13,10
        dc.b    '-Vn        出力ファイルを出力する前にそのデータの音量をパーセント単位で',13,10
        dc.b    '           指定する。nの範囲は0～300。スイッチ無指定や値省略時は100とする。',13,10
        dc.b    '-Ti,o,p,s  出力ファイルを出力する前にそのデータを16ビットPCMデータと',13,10
        dc.b    '           見なして周波数の変更を行なう。',13,10
        dc.b    '  i        元の周波数をs[Hz]とみなす。ただしsは1～65535。',13,10
        dc.b    '  o        変換後の周波数をd[Hz]とする。ただしdは1～65535。',13,10
        dc.b    '  p        出力ファイルのpバイト目から周波数変換を行なう。省略時はp=0。',13,10
        dc.b    '  s        変換するサイズをsバイトとする。省略時はpで指定された位置から',13,10
        dc.b    '           後ろ全部を変換対象領域とする。pも省略した場合は出力全域に対して',13,10
        dc.b    '           変換処理を施す。',13,10
        dc.b    '-Xl,r,t    リンク制御',13,10
        dc.b    '  l        ループタイプの設定。省略時 l=0。',13,10
        dc.b    '           0 そのまま。',13,10
        dc.b    '           1 清純、逆順の順にループさせる。',13,10
        dc.b    '           2 逆順、清純の順にループさせる。',13,10
        dc.b    '           3 入力ファイルの逆順をループさせる。',13,10
        dc.b    '  r        反復回数の設定。省略時 r=1。範囲1～65535。',13,10
        dc.b    '  t        リンク作業の前に入力ファイルに対して加工を行なう。省略時 t=0。',13,10
        dc.b    '           0 何も行なわない。',13,10
        dc.b    '           1 入力ファイルを16ビットPCMデータと見なしてADPCMデータへ変換する。',13,10
        dc.b    '           2 入力ファイルをADPCMデータと見なして16ビットPCMデータへ変換する。',13,10
	dc.b	0
more:		dc.b	'-more-',0
no_er_mes:	dc.b	$1b,'[mOperations are all set.',13,10
		dc.b	'A ',$1b,'[37m','♪SOUND',$1b,'[m mind in a '
		dc.b	$1b,'[37mSOUND',$1b,'[m',' body.',13,10,0
out_of_mem_mes:	dc.b	'Out of memory.',13,10,0
		dc.b	'メモリ不足です',13,10,0
wrt_er_mes:	dc.b	'File write error.',13,10,0
		dc.b	'ファイル書き出しエラー',13,10,0
devful_mes:	dc.b	'Device full.',13,10,0
		dc.b	'ディスク容量が不足しています',13,10,0
l_illegal_mes:	dc.b	'Illegal loop type parameter.',13,10,0
		dc.b	'ループタイプが規定外です',13,10,0
r_illegal_mes:	dc.b	'Illegal repeat time parameter.',13,10,0
		dc.b	'リピート回数が規定外です',13,10,0
t_illegal_mes:	dc.b	'Undefined prior conversion.',13,10,0
		dc.b	'未定義のサブコンバージョンを指定しました',13,10,0
v_illegal_mes:	dc.b	'ILLEGAL VOLUME PARAMETER.',13,10,0
		dc.b	'音量値が異常です',13,10,0
too_many_s_mes:	dc.b	'Too many source files.',13,10,0
		dc.b	'入力ファイルの数が多すぎます',13,10,0
no_v_param_mes:	dc.b	'NO VOLUME PARAMETER.',13,10,0
		dc.b	'音量値がありません',13,10,0
open_er_mes:	dc.b	'File open error. "',0
		dc.b	'指定ファイルを開けません。"',0
close_blnkt:	dc.b	'"',13,10,0
size_er_mes:	dc.b	'Illegal file size',13,10,0
		dc.b	'ファイルサイズが異常です',13,10,0
read_er_mes:	dc.b	'File read error.',13,10,0
		dc.b	'ファイルの読み込みに失敗しました',13,10,0
no_s_mes:	dc.b	'No source frequency parameter.',13,10,0
		dc.b	'変換元周波数値が指定されていません',13,10,0
no_d_mes:	dc.b	'No destination frequency parameter.',13,10,0
		dc.b	'変換先周波数値が指定されていません',13,10,0
s_illegal_mes:	dc.b	'Illegal source frequency parameter.',13,10,0
		dc.b	'規定外の変換元周波数値が指定されています',13,10,0
d_illegal_mes:	dc.b	'Illegal destination frequency parameter.',13,10,0
		dc.b	'規定外の変換先周波数値が指定されています',13,10,0
unex_er_mes:	dc.b	'Unexpected parameter has established.',13,10,0
		dc.b	'予期しないパラメータを指定しました',13,10,0
not_sup_er_mes:	dc.b	"ZPLK3.R doesn't support the combination of these parameters.",13,10,0
		dc.b	'処理出来ないパラメータの組み合わせが設定されています',13,10,0
cutsize_er_mes:	dc.b	'Illegal truncate offset value.',13,10,0
		dc.b	'規定外の切り出しオフセットを指定しました',13,10,0
cutoff_er_mes:	dc.b	'Illegal truncate size.',13,10,0
		dc.b	'規定外の切り出しサイズを指定しました',13,10,0
envoff_er_mes:	dc.b	'Illegal ENVELOPE-REFORM offset value.',13,10,0
		dc.b	'規定外のエンベロープ加工オフセット値を指定しました',13,10,0
envlvl_er_mes:	dc.b	'Illegal ENVELOPE-REFORM IN/OUT level.',13,10,0
		dc.b	'規定外のエンベロープ加工開始/終了レベルを指定しました',13,10,0
envtype_er_mes:	dc.b	'Illegal ENVELOPE-REFORM type',13,10,0
		dc.b	'規定外のエンベロープ加工種別を指定しました',13,10,0
trnoff_er_mes:	dc.b	'Illegal frequency transformation offset value.',13,10,0
		dc.b	'規定外の周波数変換オフセットを指定しました',13,10,0
trnsize_er_mes:	dc.b	'Illegal frequency transformation size.',13,10,0
		dc.b	'規定外の周波数変換サイズを指定しました',13,10,0
cant_t_er_mes:	dc.b	'Frequency transformation unsuccessful.',13,10,0
		dc.b	'周波数変換処理が失敗しました',13,10,0
bndoff_er_mes:	dc.b	'Illegal PITCH-BEND offset value.',13,10,0
		dc.b	'規定外のピッチベンド・オフセットを指定しました',13,10,0
bndsize_er_mes:	dc.b	'Illegal PITCH-BEND size.',13,10,0
		dc.b	'規定外のピッチベンド・サイズを指定しました',13,10,0
cant_b_er_mes:	dc.b	'PITCH-BEND processing unsuccessful.',13,10,0
		dc.b	'ピッチベンド処理が失敗しました',13,10,0
illegal_fr_mes:	dc.b	'Frequency parameter out of range.',13,10,0
		dc.b	'周波数値が許容範囲を超えています',13,10,0
unid_mes:	dc.b	'Unidentified file.',13,10,0
		dc.b	'正体不明のファイルです',13,10,0

zplk3_opt:	dc.b	'zplk3_opt',0
p16out_mode:	dc.b	0
adpout_mode:	dc.b	0
revout_mode:	dc.b	0
env_lvl:	dc.b	0	*エンベロープ変更の音量パラメータ
env_type:	dc.b	1	*エンベロープ変更の種類
fade_mode:	dc.b	0
impulse_mode:	dc.b	0
errmes_lang:	dc.b	0	*[0]:english,1:Japanese
	.even
vol_val:	dc.w	256
s_frq:		dc.l	0	*source frq
d_frq:		dc.l	0	*destination frq
env_offset:	dc.l	0	*エンベロープ変更の開始ポイント
cut_offset:	dc.l	0	*切り出しオフセット
cut_size:	dc.l	0	*切り出しサイズ
t_offset:	dc.l	0	*ピッチ変更オフセット値
t_size:		dc.l	0	*ピッチ変更サイズ
s_frq_b:	dc.l	0	*pitch bend source frq
d_frq_b:	dc.l	0	*pitch bend destination frq
b_offset:	dc.l	0	*ピッチベンド・オフセット値
b_size:		dc.l	0	*ピッチベンド・サイズ

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

	.even
	.bss	
s_name_tbl:	rept	smax+1
		ds.b	tbl_size
		endm
pcm_temp:	ds.l	1	*PCM BUFFER
src_temp1:	ds.l	1	*SOURCE PCM BUFFER
src_temp2:	ds.l	1	*SUB CONVERTED PCM BUFFER
last_val:	ds.w	1	*ADPCM変換ワーク
atb_step:	ds.l	1	*autobend work
atb_rvs:	ds.w	1	*autobend work
atb_rvswk:	ds.w	1	*autobend work
atb_frqsrc:	ds.l	1	*autobend work
atb_frqnow:	ds.l	1	*autobend work
atb_sgn:	ds.l	1	*autobend work
env_bak:	ds.l	1
impulse_buff:	ds.l	1
impulse_size:	ds.l	1
fopen_name:	ds.l	1	*fopenで取り扱った最後のファイル名
open_fn:	ds.l	1
	.even
d_name:		ds.b	91
impulse_name:	ds.b	91
	.even
		ds.l	1024
user_sp:
