pcm_read:			*ADPCMファイルを読み込む
	*   cmd=$50
	* < (a1)=TONE NAME(最大32bytes),FILENAME(?bytes),0
	*   or
	*   (a1)=TONE NAME(最大32bytes),source data number.l
	* < d1.lw=note number(0～),timbre number($8000+0～)
	* < d1.hw=flag of option existance(plus=なし,minus=あり)
	* < d2.hwhb=登録次元 (-1=ADPCM 1=16bitPCM 2=8bitPCM 0=V2互換)
	* < d2.hwlb=オリジナルキー(0-127)
	*
	* < a1.l=0のときはd1.wで表されるTIMBRE/TONEを消去する
	*
	* > a0.l=next(end) of cmd address
	move.l	a1,d0
	beq	erase_mode
	bsr	clr_adpb?
	moveq.l	#0,d6				*direct reg. or not
	move.l	d2,d7
	rol.l	#8,d7				*d7.b=reading data type default
	tst.b	d7
	bne	@f
	moveq.l	#-1,d7				*無指定の場合はADPCM:-1
@@:
	move.b	d7,readingdata_type-work(a6)
	move.w	d1,d0
	bpl	adrd_nt
						*音色番号登録方式のケース
	andi.w	#$7fff,d0
	cmpi.w	#adpcm_reg_max-1,d0
	bhi	t_illegal_timbre_number
	cmp.w	adpcm_n_max2(pc),d0
	bcs	adrd00
	bsr	spread_adpcm_n2
	bmi	t_out_of_memory
	bra	adrd00
adrd_nt:					*ノート番号登録方式のケース
	cmp.w	#adpcm_reg_max-1,d0
	bcc	t_illegal_tone_number
	cmp.w	adpcm_n_max(pc),d0
	bcs	adrd00
	bsr	spread_adpcm_n
	bmi	t_out_of_memory
adrd00:
	move.l	d1,adnt_work-work(a6)		*加工スイッチと登録ノート番号保存
	move.l	d2,adnt_regtype-work(a6)	*登録タイプ/原音程の属性保存
	clr.l	adnt_lp_start-work(a6)		*ループパラメータ・デフォルト初期化
	move.l	#-1,adnt_lp_end-work(a6)
	clr.l	adnt_lp_time-work(a6)
	clr.l	ppc_cnnct-work(a6)	*ppc_cnnct=0,adnt_loop=0,adntcopy_mode=0,dummy=0
	move.l	sp,adt_sp_buf-work(a6)

	move.l	v_buffer-work(a6),a0	*tone nameを格納
	moveq.l	#adt_name_len-1,d0
@@:
	move.b	(a1)+,(a0)+
	dbeq	d0,@b

	cmpi.b	#1,(a1)		*0=COPY, 1=POINTER COPY
	bls	non_read	*ファイルネーム指定でない場合はワーク間コピー

	move.l	a1,a0		*.p16かどうか検査
@@:
	move.b	(a0)+,d0
	beq	adfop0
	cmpi.b	#'.',d0
	bne	@b
@@:
	move.b	(a0)+,d0
	beq	adfop0
	bsr	mk_capital
	cmpi.b	#'P',d0
	bne	adfop0
	move.b	(a0)+,d0
	beq	adfop0
	cmpi.b	#'1',d0
	beq	@f
	cmpi.b	#'8',d0
	bne	adfop0
	moveq.l	#ID_8bitPCM,d7			*8BitPCM
	bra	adfop0
@@:
	move.b	(a0)+,d0
	beq	adfop0
	cmpi.b	#'6',d0
	bne	adfop0
	moveq.l	#ID_16bitPCM,d7			*16bitPCM
adfop0:
	movea.l	a1,a2
	bsr	fopen
	tst.l	d5
	bmi	t_file_not_found	*ファイル読み込み失敗

	bsr	get_fsize
	bmi	t_illegal_file_size	*d3=lengthが0,minusだったらエラー
	move.l	d3,d2
	move.l	d3,d4			*data size
	tst.b	adnt_work-work(a6)	*加工スイッチ有りか無しか
	bmi	adrd_gtb		*ある
	move.b	adnt_regtype(pc),d0	*ない
	bne	@f
	move.b	d7,adnt_regtype-work(a6)	*加工スイッチがなくて登録タイプも
	bra	direct_reg_case			*指定されていない場合はそのまま登録
@@:
	cmp.b	d0,d7			*読み込んだfiletypeと登録typeが一致していない場合は
	bne	adrd_gtb		*加工処理へ
direct_reg_case:
	bsr	ensure_adpcm_buf	*a1.l=usable address
	bne	t_out_of_memory
	moveq.l	#1,d6			*direct reg.
adrd0:
	ifndef	sv
	move.w	sr,-(sp)
	andi.w	#$f8ff,sr
	endif
	move.l	d4,-(sp)	*push size
	pea	(a1)		*push addr
	move.w	d5,-(sp)	*file handle
	DOS	_READ		*サンプリングデータの読み込み
	lea	10(sp),sp
	ifndef	sv
	move.w	(sp)+,sr
	endif
	tst.l	d0
	bmi	t_read_error

	bsr	do_fclose
@@:				*ファイルネーム終端検索
	tst.b	(a2)+
	bne	@b
	move.l	a2,a4			*a4=cmd line
	tst.b	d6			*直接登録ケースか
	beq	go_adt_process		*no
	bra	exit_smp_read		*yes(<a1,d4)
adrd_gtb:				*加工スイッチあり
	tst.b	adnt_regtype-work(a6)	*登録タイプが未指定ならば
	bne	@f
	st.b	adnt_regtype-work(a6)	*ADPCMタイプへ
@@:
	bsr	get_temp_buf
	bmi	t_out_of_memory
	bra	adrd0

non_read:				*ディスクからでなくてメモリから
	move.b	(a1)+,adntcopy_mode-work(a6)
	moveq.l	#0,d0			*get tone/timbre number
	move.b	(a1)+,d0
	swap	d0
	move.b	(a1)+,d0
	lsl.w	#8,d0
	move.b	(a1)+,d0
	move.l	a1,a4			*a4.l=戻り値になるかも
	bclr.l	#15,d0
	beq	@f
	cmp.w	adpcm_n_max2(pc),d0	*timbre case
	bcc	t_illegal_timbre_number
	move.l	adpcm_tbl2(pc),a2
	bra	chkadnttyp
@@:					*tone case
	cmp.w	adpcm_n_max(pc),d0
	bcc	t_illegal_tone_number
	movea.l	adpcm_tbl(pc),a2
chkadnttyp:
	lsl.l	#adpcm_tbl_size_,d0	*adpcm_tbl_size倍
	adda.l	d0,a2
	move.b	(a2),d7			*check data type
	beq	t_empty_note_number	*typeが0はデータなしを意味する
	move.l	adt_size(a2),d4		*get size
	move.l	d4,d2			*data size

	tst.b	adnt_work-work(a6)	*加工スイッチがあるかないか
	bmi	go_adtprc		*ある
	move.b	adnt_regtype(pc),d0	*ない
	bne	@f
	move.b	d7,adnt_regtype-work(a6)	*加工スイッチがなくて登録タイプも
	bra	adrdnt00			*指定されていない場合はそのまま登録
@@:
	cmp.b	d0,d7			*読み込んだfiletypeと登録typeが一致していない場合は
	bne	go_adtprc		*加工処理へ
adrdnt00:				*コマンドラインがない時はそれを転送するだけ
	tst.b	adntcopy_mode-work(a6)
	beq	@f
	bsr	alteration_ope
	bra	exit_smp_read		*(< a1,d4)
@@:
	bsr	ensure_adpcm_buf	*> a1.l=usable address
	bne	t_out_of_memory
	movea.l	adt_addr(a2),a0		*source
	move.l	a1,a3			*save address
@@:
	move.l	(a0)+,(a3)+
	subq.l	#4,d2			*ロングワード単位で転送
	bne	@b
	bra	exit_smp_read		*(< a1,d4)

alteration_ope:
	* < a4.l=cmd line
	* < d4.l=data size
	* > a1.l=copied data addr
	move.l	adt_addr(a2),a1		*ポインタコピー
	move.b	(a4)+,d0
	cmpi.b	#PPC_ALTERATION,d0
	bne	t_illegal_parameters_combination
	bsr	get_offset_size		*> a0.l=addr d2.l=size
	move.l	a0,a1
	move.l	d2,d4
	rts

go_adtprc:				*加工あり
	tst.b	adnt_regtype-work(a6)	*登録タイプが未指定ならば
	bne	@f
	st.b	adnt_regtype-work(a6)	*ADPCMタイプへ
@@:
	move.l	a1,a4			*save cmd line
	tst.b	adntcopy_mode-work(a6)
	beq	@f
	bsr	alteration_ope
	bra	go_adt_process
@@:
	bsr	get_temp_buf		*> a1.l=buffer address
	bmi	t_out_of_memory
	movea.l	adt_addr(a2),a0		*source
	move.l	a1,a3			*destination
	addq.l	#3,d2
	andi.w	#$fffc,d2
@@:
	move.l	(a0)+,(a3)+
	subq.l	#4,d2			*ロングワード単位で転送
	bne	@b
go_adt_process:				*加工処理
	* < a1.l=data address 
	* < d4.l=data size 
	lea	-(20+adpcm_tbl_size)(sp),sp
	move.l	sp,a5
	cmpi.b	#ID_16bitPCM,d7		*16bitPCMデータか
	beq	@f
	bsr	conv_to_p16		*ADPCMデータはPCMデータに変換しておく(<d7.b=data type)
	beq	@f
	bra	t_out_of_memory
	* < a4.l=cmd line
	* < a1.l=data address
	* < d4.l=size
buf1_addr:	equ	0
buf1_size:	equ	4
buf2_addr:	equ	8
buf2_size:	equ	16
buf3:		equ	20		*後ろにadpcm_tbl_size分取る
adt_process:
	lea	-(20+adpcm_tbl_size)(sp),sp
	move.l	sp,a5
@@:
	move.l	a1,buf1_addr(a5)
	move.l	d4,buf1_size(a5)
	tst.b	adnt_work-work(a6)	*加工スイッチ有りか無しか
	bpl	proc_end
prclp00:
	moveq.l	#0,d0
	move.b	(a4)+,d0
	beq	proc_end
	tst.b	adntcopy_mode-work(a6)
	beq	@f
	cmp.b	#$10,d0			*ポインタコピーモードでは.LOOP以外の使用は許されない
	bne	t_illegal_parameters_combination
@@:
	move.w	adrdjtbl(pc,d0.w),d0
	jmp	adrdjtbl(pc,d0.w)

adt_sp_buf:	ds.l	1
adrdjtbl:
	* 各サブルーチンには
	* < a4.l=command line
	* < a1.l=data address/d4.l=data sizeで
	* エントリーしa4,a1,d4を更新する
	dc.w	proc_end-adrdjtbl	*$00 終了
	dc.w	pitch_ope-adrdjtbl	*$02
	dc.w	vol_ope-adrdjtbl	*$04
	dc.w	mix_ope-adrdjtbl	*$06
	dc.w	truncate_ope-adrdjtbl	*$08
	dc.w	reverse_ope-adrdjtbl	*$0a
	dc.w	fade_ope-adrdjtbl	*$0c
	dc.w	bend_ope-adrdjtbl	*$0e
	dc.w	loop_set-adrdjtbl	*$10
	dc.w	connect_ope-adrdjtbl	*$12
	dc.w	delete_ope-adrdjtbl	*$14
	dc.w	distortion_ope-adrdjtbl	*$16
	dc.w	smooth_ope-adrdjtbl	*$18
*	dc.w	execute_ope-adrdjtbl	*$1a

pitch_ope:				*音程変換
	* < a1.l=data address
	* < d4.l=temp size(領域のサイズではなくてデータのサイズ)
	bsr	get_offset_size		*> a0.l=start addr,d2.l=ope size,d0.l=offset
	move.l	a1,a2			*source
	move.l	d0,d3			*offset
	bsr	get_temp_buf2		*>a1.l=destination address
	beq	t_out_of_memory		*>d0.l=block end addr
	move.l	d0,d5			*block end address
	move.l	a1,-(sp)

	move.l	d4,d1
	sub.l	d3,d1
	sub.l	d2,d1
	move.l	d1,-(sp)		*tail size

	tst.l	d3			*先頭部分の転送
	beq	1f
@@:
	move.w	(a2)+,(a1)+
	subq.l	#2,d3
	bne	@b
1:
	moveq.l	#0,d6
	move.b	(a4)+,d6
	lsl.w	#8,d6
	move.b	(a4)+,d6		*src frq
	moveq.l	#0,d7
	move.b	(a4)+,d7
	lsl.w	#8,d7
	move.b	(a4)+,d7		*dst frq

	move.l	d2,d4
	* < d4.l=pcm data size
	* < d5.l=mem.block end address
	* < d6.w=source frq
	* < d7.w=destination frq
	* < a1.l=destination pcm data address
	* < a2.l=source pcm data address
	* > d0.l=destination pcm data size
	lsr.l	d4
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
				*ピッチアップケース
	moveq.l	#0,d0		*buffer
	moveq.l	#0,d1		*counter
doa_lp00:
	addq.l	#1,d1
	move.w	(a2)+,d2
	ext.l	d2
	add.l	d2,d0
	add.w	d7,d3
	bcc	3f
	tst.l	d0
	bmi	1f
	bsr	wari		*d0/d1=d0...d1(平均値演算)
	cmpi.l	#32767,d0
	bls	@f
	move.w	#32767,d0
@@:
	move.w	d0,(a1)+
	bra	2f
1:
	neg.l	d0
	bsr	wari
	neg.l	d0
	neg.l	d1
	cmpi.l	#-32768,d0
	bge	@f
	move.w	#-32768,d0
@@:
	move.w	d0,(a1)+
2:
	move.l	d1,d0		*Dithering(あまりを次回へ持ち越し)
	moveq.l	#0,d1
	cmp.l	a1,d5
	bls	t_out_of_memory
3:
	subq.l	#1,d4
	bne	doa_lp00
	bra	exit_doa
nz_d1:				*ピッチダウンケース
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
	bls	t_out_of_memory
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
	move.l	(sp)+,d1		*tail転送
	beq	1f
@@:
	move.w	(a2)+,(a1)+
	subq.l	#2,d1
	bne	@b
1:
	move.l	a1,d4
	move.l	buf1_addr(a5),a1
	bsr	free_mem
	move.l	(sp)+,a1
	sub.l	a1,d4			*d4=new size
	move.l	d4,d2
	bsr	enlarge_mem		*setblock
	tst.l	d0
	bmi	t_out_of_memory
	move.l	a1,buf1_addr(a5)
	move.l	d4,buf1_size(a5)
	bra	prclp00

smooth_ope:			*スムージング
	bsr	get_offset_size	*> a0.l=start addr,d2.l=ope size,d0.l=offset
	move.b	(a4)+,d6
	lsl.w	#8,d6
	move.b	(a4)+,d6	*get repeat time
smthlp:
	movem.l	d2/a0,-(sp)
	move.w	(a0),d1		*backup value
	ext.l	d1
@@:
	move.w	(a0),d0
	ext.l	d0
	add.l	d0,d1
	asr.l	#1,d1
	move.w	d1,(a0)+
	move.l	d0,d1
	subq.l	#2,d2
	bcs	@f		*!98.4.1
	bne	@b
@@:
	movem.l	(sp)+,d2/a0
	dbra	d6,smthlp
	bra	prclp00

vol_ope:			*音量変換
	bsr	get_offset_size
	moveq.l	#0,d0
	move.b	(a4)+,d0
	lsl.w	#8,d0
	move.b	(a4)+,d0	*get level
	lsl.l	#7,d0		*d0=d0*128
	divu	#100,d0		*d0=0～999→0～127872
	andi.l	#$ffff,d0	*(128を基準としたパーセンテージ)
@@:
	move.w	(a0),d1
	muls	d0,d1
	asr.l	#7,d1
	move.w	d1,(a0)+
	subq.l	#2,d2
	bcs	prclp00		*!98.4.1
	bne	@b
	bra	prclp00

distortion_ope:			*ディストーション
	bsr	get_offset_size
	moveq.l	#0,d0
	move.b	(a4)+,d0
	lsl.w	#8,d0
	move.b	(a4)+,d0	*get mul level
	move.l	#0,d6
	move.b	(a4)+,d6
	lsl.w	#8,d6
	move.b	(a4)+,d6	*get cut off level
	move.l	d6,d5
	neg.l	d5

	lsl.l	#7,d0		*d0=d0*128
	divu	#100,d0		*d0=0～999→0～127872
	andi.l	#$ffff,d0	*(128を基準としたパーセンテージ)
distlp:
	move.w	(a0),d1
	ext.l	d1
	bpl	@f
	neg.l	d1		*データ負の場合
	bsr	kake
	lsr.l	#7,d1
	neg.l	d1
	bra	1f
@@:				*データ正の場合
	bsr	kake
	lsr.l	#7,d1
1:
	cmp.l	d6,d1
	ble	@f
	move.l	d6,d1
	bra	1f
@@:
	cmp.l	d5,d1
	bge	1f
	move.l	d5,d1
1:
	move.w	d1,(a0)+
	subq.l	#2,d2
	bcs	prclp00		*!98.4.1
	bne	distlp
	bra	prclp00

get_offset_size:		*オフセット計算とサイズ計算、パラメータチェック
	* < parameter address
	* > a0.l=operation start address
	* > d2.l=operation size
	* > d0.l=offset value
	move.b	(a4)+,d0
	lsl.w	#8,d0
	move.b	(a4)+,d0
	swap	d0
	move.b	(a4)+,d0
	lsl.w	#8,d0
	move.b	(a4)+,d0	*get offset
	move.b	adnt_regtype(pc),d1
	cmpi.b	#ID_8bitPCM,d1
	bcs	@f
	add.l	d0,d0		*2倍
@@:
	tst.b	d1		*ID_adPCM
	bpl	@f
	add.l	d0,d0		*4倍
@@:
	cmp.l	d4,d0
	bcs	@f
	tst.l	d0
	bpl	t_offset_too_long	*offsetが大きすぎ
	add.l	d4,d0
	bmi	t_offset_too_long	*offsetが大きすぎ
@@:
	lea	(a1,d0.l),a0		*source

	move.b	(a4)+,d2
	lsl.w	#8,d2
	move.b	(a4)+,d2
	swap	d2
	move.b	(a4)+,d2
	lsl.w	#8,d2
	move.b	(a4)+,d2	*get cut size
	tst.l	d2		*サイズ０は特殊ケース
	bne	@f
	move.l	d4,d2
	sub.l	d0,d2
	bra	exit_gos
@@:
	cmpi.b	#ID_8bitPCM,d1
	bcs	@f
	add.l	d2,d2		*2倍
@@:
	tst.b	d1
	bpl	@f
	add.l	d2,d2		*4倍
@@:
	move.l	d0,d1
	add.l	d2,d1			*パラメータがおかしくないか
	cmp.l	d4,d1
	bhi	t_processing_size_too_large	*加工サイズが大きすぎる
exit_gos:
	rts

truncate_ope:
	* a1.l 更新されない
	* d4.l 更新される
	bsr	get_offset_size		*>a0.l=op start addr, d2.l=op size
	move.l	d2,d4			*PCM size
	move.l	a1,a2			*destination
@@:
	move.w	(a0)+,(a2)+
	subq.l	#2,d2
	bcs	@f		*!98.4.1
	bne	@b
@@:
	move.l	d4,d2
	bsr	enlarge_mem	*setblock
	tst.l	d0
	bmi	t_out_of_memory
	move.l	d4,buf1_size(a5)
	bra	prclp00

delete_ope:				*削除
	* a1.l 更新されない
	* d4.l 更新される
	bsr	get_offset_size		*>a0.l=destination, d2.l=delete size
	lea	(a0,d2.l),a2		*source
	move.l	d4,d1
	sub.l	d0,d1
	sub.l	d2,d4			*new size
	sub.l	d2,d1
	beq	1f
@@:
	move.w	(a2)+,(a0)+
	subq.l	#2,d1
	bcs	1f		*!98.4.1
	bne	@b
1:
	move.l	d4,d2
	bsr	enlarge_mem	*setblock
	tst.l	d0
	bmi	t_out_of_memory
	move.l	d4,buf1_size(a5)
	bra	prclp00

reverse_ope:				*リバース
	* d4,a1 見掛け上更新されない
	bsr	get_offset_size		*>a0.l=op start addr, d2.l=op size
	move.l	a0,a3
	bsr	get_temp_buf		*d2サイズ分確保(>a1.l=data area)
	bmi	t_out_of_memory
	move.l	a1,buf2_addr(a5)
	move.l	d2,d1
	add.l	d2,a0			*source
	move.l	a1,a2			*destination
@@:					*リバース処理
	move.w	-(a0),(a1)+
	subq.l	#2,d2
	bcs	@f			*!98.4.1
	bne	@b
@@:					*リバースした内容を元のバッファへ逆転送
	move.w	(a2)+,(a3)+
	subq.l	#2,d1
	bcs	@f			*!98.4.1
	bne	@b
@@:
	move.l	buf2_addr(a5),a1
	bsr	free_mem		*buf2作業領域を開放
	move.l	(a5),a1			*get buf1 addr
	bra	prclp00

fade_ope:				*フェードイン／アウト
	bsr	get_offset_size		*>a0.l=op start addr, d2.l=op size
	moveq.l	#0,d5
	move.b	(a4)+,d5	*start level H
	lsl.w	#8,d5
	move.b	(a4)+,d5	*start level L
	moveq.l	#0,d0
	move.b	(a4)+,d0	*end level H
	lsl.w	#8,d0
	move.b	(a4)+,d0	*end level L
	sub.l	d5,d0
	bmi	@f
				*正のケース(フェードイン)
	move.l	d2,d1		*d1=op size
	bsr	wari		*d0.l/d1.l=d0.l ...d1.l
	move.l	d0,d6		*d6=answer
	swap	d1
	clr.w	d1
	move.l	d1,d0
	move.l	d2,d1		*get op size
	bsr	wari		*d0.l/d1.l=d0.l ...d1.l
	swap	d6
	move.w	d0,d6
	addq.l	#1,d6
	bra	do_fader
@@:				*負のケース(フェードアウト)
	neg.l	d0
	move.l	d2,d1		*d1=op size
	bsr	wari		*d0.l/d1.l=d0.l ...d1.l
	move.l	d0,d6		*d6=answer
	swap	d1
	clr.w	d1
	move.l	d1,d0
	move.l	d2,d1		*d1=op size
	bsr	wari		*d0.l/d1.l=d0.l ...d1.l
	swap	d6
	move.w	d0,d6
	neg.l	d6
do_fader:			*フェーダー処理
	* < d5.l=(fixed) start level
	* < d2.l=operation size
	* < d6.l=step
	* < a0=data address
	swap	d5
@@:
	move.w	(a0),d1
	swap	d5
	muls	d5,d1
	asr.l	#7,d1
	move.w	d1,(a0)+
	swap	d5
	add.l	d6,d5		*add step
	subq.l	#2,d2
	bcs	prclp00		*!98.4.1
	bne	@b
	bra	prclp00

*execute_ope:
*	move.l	#2048,d2
*	bsr	get_temp_buf		*d2サイズ分確保(>a1.l=data area)
*	bmi	t_out_of_memory
*	move.l	a1,a2
*@@:					*コマンドラインのコピー
*	move.b	(a4)+,(a2)+
*	bne	@b
*	ifndef	sv
*	move.w	sr,-(sp)
*	andi.w	#$f8ff,sr
*	endif
*	movem.l	d0-d7/a0-a7,prsv_work-work(a6)
*	clr.l	-(sp)
*	pea	1024(a1)		*使い捨てとなるわけだからどこでもいい
*	pea	(a1)			*command line
*	move.w	#2,-(sp)		*mode
*	DOS	_EXEC
*	addq.w	#2,sp
*	clr.w	-(sp)			*mode
*	DOS	_EXEC
*	lea	14(sp),sp
*	movem.l	prsv_work(pc),d0-d7/a0-a7
*	ifndef	sv
*	move.w	(sp)+,sr
*	endif
*	bsr	free_mem
*	bra	prclp00

mix_ope:			*ミックス処理
	tst.b	(a4)
	sne	d7			*ミックスするデータを後で開放するか(-1=yes)
	beq	non_read_mix		*ファイルネームがない場合は登録済みノートから
					*ミックスするデータは外部ファイル
	bsr	read_and_get_p16
	tst.l	d0
	beq	get_mix_size
	rts				*case error

non_read_mix:				*登録済みノートでミックス
	bsr	get_p16_from_adbf
	tst.l	d0
	beq	get_mix_size
	rts				*error case
get_mix_size:				*ミックスして出来るデータのサイズ
	move.l	d4,d1			*orig size
	move.l	adt_size(a3),d2		*mix note size
					*データサイズ決定処理
	move.l	d6,d0			*d6=offset
	bpl	@f
	neg.l	d0			*オフセットがマイナスの場合
	exg.l	d1,d2			*演算の都合上交換
@@:
	add.l	d0,d2
	cmp.l	d1,d2
	bcc	@f
	move.l	d1,d2
@@:
	move.l	d2,buf2_size(a5)
	move.l	d2,d4			*新たなサイズ
	bsr	get_temp_buf		*d2サイズ分確保(>a1.l=data area)
	bmi	t_out_of_memory
	move.l	a1,buf2_addr(a5)
	tst.l	d6
	bmi	mins_mixdly		*マイナスディレイの場合は直接ミックスデータをバッファへ
					*プラスディレイ
	move.l	buf1_addr(a5),a0	*orig data address
	move.l	buf1_size(a5),d0	*orig data size
	sub.l	d0,d2
@@:					*初めorigでバッファを埋める
	move.w	(a0)+,(a1)+
	subq.l	#2,d0
	bne	@b
	tst.l	d2			*余白無し
	beq	do_plsmix
@@:					*余白分を0で埋める
	clr.w	(a1)+
	subq.l	#2,d2
	bne	@b
do_plsmix:
	move.l	buf2_addr(a5),a1	*dest address
	add.l	d6,a1			*offset加算
	move.l	adt_addr(a3),a0		*mix data
	move.l	adt_size(a3),d2
@@:
	move.w	(a0)+,d0
	add.w	d0,(a1)+
	subq.l	#2,d2
	bne	@b
	bra	exit_mixope

mins_mixdly:				*ディレイがマイナスの時
	move.l	adt_addr(a3),a0
	move.l	adt_size(a3),d0
	sub.l	d0,d2
@@:					*初めミックスデータでバッファを埋める
	move.w	(a0)+,(a1)+
	subq.l	#2,d0
	bne	@b
	tst.l	d2			*余白無し
	beq	do_mnsmix
@@:
	clr.w	(a1)+
	subq.l	#1,d2
	bne	@b
do_mnsmix:
	move.l	buf2_addr(a5),a1	*dest address
	sub.l	d6,a1			*オフセットを足している(-(-ofsset))
	move.l	buf1_addr(a5),a0	*orig data
	move.l	buf1_size(a5),d2
@@:
	move.w	(a0)+,d0
	add.w	d0,(a1)+
	subq.l	#2,d2
	bne	@b
exit_mixope:
	move.l	buf1_addr(a5),a1
	bsr	free_mem		*元のデータ領域を開放
	move.l	buf2_addr(a5),a1
	move.l	a1,buf1_addr(a5)	*新規データをテンポラリと扱う
	tst.b	d7			*開放処理が必要か
	beq	prclp00
	move.l	a1,a0
	move.l	adt_addr(a3),a1		*外部ファイル領域を開放
	bsr	free_mem
	move.l	a0,a1
	bra	prclp00

read_and_get_p16:			*データを読みだして16bitPCMに変換する
	* < a4.l=ファイルネーム
	* > a3.l=temp base addr
	* > a4.l=次のコマンドコードを指す
	* > a1.l=destination data address
	* > d2.l=destination data size
	* > d6.l=offset value
	* > d0.l=0 no error
	* x d3,d5,a0
	* - d4
	lea	buf3(a5),a3
	move.b	readingdata_type(pc),(a3)	*data type(default)
	move.l	a4,a0				*.p16かどうか検査
@@:
	move.b	(a0)+,d0
	beq	adfop0_ragp
	cmpi.b	#'.',d0
	bne	@b
	move.b	(a0)+,d0
	beq	adfop0_ragp
	bsr	mk_capital
	cmpi.b	#'P',d0
	bne	adfop0_ragp
	move.b	(a0)+,d0
	beq	adfop0_ragp
	cmpi.b	#'1',d0
	bne	@f
	move.b	(a0)+,d0
	beq	adfop0_ragp
	cmpi.b	#'6',d0
	bne	adfop0_ragp
	move.b	#ID_16bitPCM,(a3)
	bra	adfop0_ragp
@@:
	cmpi.b	#'8',d0
	bne	adfop0_ragp
	move.b	#ID_8bitPCM,(a3)
adfop0_ragp:
	movea.l	a4,a2
	bsr	fopen
	tst.l	d5
	bmi	t_file_not_found	*ファイル読み込み失敗

	bsr	get_fsize
	bmi	t_illegal_file_size	*d3=lengthが0,minusだったらエラー
	move.l	d3,adt_size(a3)

	move.l	d3,d2
	bsr	get_temp_buf		*d2サイズ分確保(>a1.l=data area)
	bmi	t_out_of_memory
	move.l	a1,adt_addr(a3)

	ifndef	sv
	move.w	sr,-(sp)
	andi.w	#$f8ff,sr
	endif
	move.l	d2,-(sp)		*push size
	pea	(a1)			*push addr
	move.w	d5,-(sp)		*file handle
	DOS	_READ			*サンプリングデータの読み込み
	lea	10(sp),sp
	ifndef	sv
	move.w	(sp)+,sr
	endif
	tst.l	d0
	bmi	t_read_error

	bsr	do_fclose
					*ADPCMならば16bitPCMにする
	tst.b	(a3)			*PCMならば処理不要
	bpl	1f
	move.l	a1,a0			*source
	pea	(a0)			*後で開放する
	move.l	d2,-(sp)		*push size
	lsl.l	#2,d2			*new size
	move.l	d2,adt_size(a3)
	bsr	get_temp_buf		*> a1.l=data area, d0.l=border
	bmi	t_out_of_memory
	move.l	a1,adt_addr(a3)
	move.l	(sp)+,d0		*size
	bsr	just_adpcm_to_pcm
	move.l	(sp)+,a1
	bsr	free_mem		*元のデータ領域を開放
	bra	2f
1:					*8bitPCMを16bitPCMに変換する
	cmpi.b	#ID_8bitPCM,(a3)
	bne	2f
	move.l	a1,a0			*source
	pea	(a0)			*後で開放する
	move.l	d2,-(sp)		*push size
	add.l	d2,d2			*new size
	move.l	d2,adt_size(a3)
	bsr	get_temp_buf		*> a1.l=data area, d0.l=border
	bmi	t_out_of_memory
	move.l	a1,adt_addr(a3)
	move.l	(sp)+,d6		*size
@@:
	move.b	(a0)+,d0
	ext.w	d0
	move.w	d0,(a1)+
	subq.l	#1,d6
	bne	@b
	move.l	(sp)+,a1
	bsr	free_mem		*元のデータ領域を開放
2:
	move.l	(a5),a1
@@:					*ファイルネーム終端検索
	tst.b	(a4)+
	bne	@b

	move.b	(a4)+,d6
	lsl.w	#8,d6
	move.b	(a4)+,d6
	swap	d6
	move.b	(a4)+,d6
	lsl.w	#8,d6
	move.b	(a4)+,d6		*get offset
	cmpi.b	#ID_8bitPCM,adnt_regtype-work(a6)
	bcs	@f
	add.l	d6,d6		*2倍
@@:
	tst.b	adnt_regtype-work(a6)	*ID_adPCM
	bpl	@f
	add.l	d6,d6		*4倍
@@:
	move.l	adt_size(a3),d0
	cmp.l	d0,d6
	bcs	@f
	tst.l	d6
	bpl	t_offset_too_long
	add.l	d0,d6		*負値オフセットに対応
	bmi	t_offset_too_long
@@:
	tst.b	(a4)+
	beq	@f
	subq.w	#1,a4
reglist	reg	d1-d7/a0-a3/a5-a6
	movem.l	reglist,-(sp)
	move.l	adt_addr(a3),a1
	move.l	adt_size(a3),d4
	bsr	adt_process
*	tst.l	d0
*	bne	ragp_t_error_code_exit		*d0そのものがエラーコード(これを持って帰還)
	move.l	a1,adt_addr(a3)
	move.l	d4,adt_size(a3)
	movem.l	(sp)+,reglist
@@:
	moveq.l	#0,d0
	rts
*ragp_t_error_code_exit:
*	movem.l	(sp)+,reglist
*	bra	t_error_code_exit

get_p16_from_adbf:			*登録済みノートからデータを取り出す
	* < a4.l=note num. addr
	* > a4.l=次のコマンドコードを指す
	* > a0.l=destination data address
	* > d2.l=destination data size
	* > d7.l=開放フラグ
	* > d6.l=offset value
	* > d0.l=0 no error
	* x a0,a3
	* - d4
	addq.w	#2,a4
	moveq.l	#0,d0
	move.b	(a4)+,d0
	lsl.w	#8,d0
	move.b	(a4)+,d0		*get note number
	bclr.l	#15,d0
	beq	@f
	cmp.w	adpcm_n_max2(pc),d0
	bcc	t_illegal_timbre_number
	move.l	adpcm_tbl2(pc),a3
	bra	calc_gpfa
@@:
	cmp.w	adpcm_n_max(pc),d0
	bcc	t_illegal_tone_number
	movea.l	adpcm_tbl(pc),a3
calc_gpfa:
	lsl.l	#adpcm_tbl_size_,d0	*adpcm_tbl_size倍
	add.l	d0,a3			*a3=destination parameter pointer
	move.l	adt_addr(a3),a0		*source
	move.l	adt_size(a3),d2		*size
	tst.b	(a3)			*check type
	beq	t_empty_note_number	*空っぽの時
	bpl	@f			*case 16bitPCM
	lsl.l	#2,d2			*new size
	bsr	get_temp_buf		*> a1.l=data area,d0.l=border
	bmi	t_out_of_memory
	move.l	adt_size(a3),d0		*size
	bsr	just_adpcm_to_pcm	*< a0=src,a1=dest,d0.l=size
	move.l	a1,a0
	moveq.l	#-1,d7			*後で開放するか(yes=-1)
@@:
	lea	buf3(a5),a3
	move.l	a0,adt_addr(a3)
	move.l	d2,adt_size(a3)
	move.l	(a5),a1			*get back orig data addr(d4=sizeは保存されている)

	move.b	(a4)+,d6
	lsl.w	#8,d6
	move.b	(a4)+,d6
	swap	d6
	move.b	(a4)+,d6
	lsl.w	#8,d6
	move.b	(a4)+,d6		*get offset
	cmpi.b	#ID_8bitPCM,adnt_regtype-work(a6)
	bcs	@f
	add.l	d6,d6		*2倍
@@:
	tst.b	adnt_regtype-work(a6)	*ID_adPCM
	bpl	@f
	add.l	d6,d6		*4倍
@@:
	move.l	adt_size(a3),d0
	cmp.l	d0,d6
	bcs	@f
	tst.l	d6
	bpl	t_offset_too_long
	add.l	d0,d6		*負値オフセットに対応
	bmi	t_offset_too_long
@@:
	tst.b	(a4)+
	beq	@f
	subq.w	#1,a4
reglist	reg	d1-d7/a0-a3/a5-a6
	movem.l	reglist,-(sp)
	move.l	adt_addr(a3),a1
	move.l	adt_size(a3),d4
	bsr	adt_process
*	tst.l	d0
*	bne	gpfa_t_error_code_exit		*d0そのものがエラーコード(これを持って帰還)
	move.l	a1,adt_addr(a3)
	move.l	d4,adt_size(a3)
	movem.l	(sp)+,reglist
@@:
	moveq.l	#0,d0
	rts
*gpfa_t_error_code_exit:
*	movem.l	(sp)+,reglist
*	bra	t_error_code_exit

bend_ope:				*線形音程変換
	* < a1.l=data address
	* < d4.l=temp size(領域のサイズではなくてデータのサイズ)
	bsr	get_offset_size
	move.l	a1,a2			*source
	bsr	get_temp_buf2		*>a1.l=destination address
	beq	t_out_of_memory
	move.l	d0,d5			*block end address
	moveq.l	#0,d6
	move.b	(a4)+,d6
	lsl.w	#8,d6
	move.b	(a4)+,d6		*src frq
	moveq.l	#0,d7
	move.b	(a4)+,d7
	lsl.w	#8,d7
	move.b	(a4)+,d7		*dst frq
	* < d4.l=pcm data size
	* < d5.l=mem.block end address
	* < d6.w=source frq
	* < d7.w=destination frq
	* < a1.l=destination pcm data address
	* < a2.l=source pcm data address
	* > d0.l=destination pcm data size
	move.l	a1,-(sp)
	lsr.l	d4
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
	moveq.l	#0,d0		*buffer
	moveq.l	#0,d1		*counter
doa_lp00_b:
	addq.l	#1,d1
	move.w	(a2)+,d2
	ext.l	d2
	add.l	d2,d0
	add.w	d7,d3
	bcc	@f
	divs	d1,d0		*(d0/d1)平均値演算
	move.w	d0,(a1)+
	swap	d0
	ext.l	d0		*Dithering
	moveq.l	#0,d1
	cmp.l	a1,d5
	bls	t_out_of_memory
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
	bls	t_out_of_memory
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
	move.l	a1,d4
	move.l	buf1_addr(a5),a1
	bsr	free_mem
	move.l	(sp)+,a1
	sub.l	a1,d4			*d4=new size
	move.l	d4,d2
	bsr	enlarge_mem		*setblock
	tst.l	d0
	bmi	t_out_of_memory
	move.l	a1,buf1_addr(a5)
	move.l	d4,buf1_size(a5)
	bra	prclp00

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

atb_step:	ds.l	1	*autobend work
atb_rvs:	ds.w	1	*autobend work
atb_rvswk:	ds.w	1	*autobend work
atb_frqsrc:	ds.l	1	*autobend work
atb_frqnow:	ds.l	1	*autobend work
atb_sgn:	ds.l	1	*autobend work

loop_set:			*ループ・オフセットアドレスの設定
	move.b	(a4)+,d1	*get omt
	move.b	(a4)+,d0	*get loop type (V3.00ではダミー)
@@:
	move.b	(a4)+,d0
	lsl.w	#8,d0
	move.b	(a4)+,d0
	swap	d0
	move.b	(a4)+,d0
	lsl.w	#8,d0
	move.b	(a4)+,d0	*get loop time
	move.l	d0,adnt_lp_time-work(a6)
	ori.b	#4,adnt_loop-work(a6)
@@:
	lsr.b	#1,d1
	bcc	get_lpedofst
	move.b	(a4)+,d0
	lsl.w	#8,d0
	move.b	(a4)+,d0
	swap	d0
	move.b	(a4)+,d0
	lsl.w	#8,d0
	move.b	(a4)+,d0	*get start offset
	cmpi.b	#ID_8bitPCM,adnt_regtype-work(a6)
	bcs	@f
	add.l	d0,d0		*2倍
@@:
	tst.b	adnt_regtype-work(a6)	*ID_adPCM
	bpl	@f
	add.l	d0,d0		*4倍
@@:
	cmp.l	d4,d0
	bcs	@f
	tst.l	d0
	bpl	t_offset_too_long
	add.l	d4,d0		*負値オフセットに対応
	bmi	t_offset_too_long
@@:
	move.l	d0,adnt_lp_start-work(a6)
	ori.b	#1,adnt_loop-work(a6)
get_lpedofst:
	lsr.b	#1,d1
	bcc	prclp00
	move.b	(a4)+,d0
	lsl.w	#8,d0
	move.b	(a4)+,d0
	swap	d0
	move.b	(a4)+,d0
	lsl.w	#8,d0
	move.b	(a4)+,d0	*get end offset
	move.l	d0,adnt_lp_end-work(a6)
	ori.b	#2,adnt_loop-work(a6)
	bra	prclp00

connect_ope:				*コネクト処理
	tst.b	(a4)
	sne	d7			*コネクトするデータを後で開放するか(-1=yes)
	beq	non_read_cnct		*ファイルネームがない場合は登録済みノートから
					*コネクトするデータは外部ファイル
	bsr	read_and_get_p16
	tst.l	d0
	beq	get_cnct_size
	rts				*case error

non_read_cnct:				*登録済みノートでコネクト
	bsr	get_p16_from_adbf
	tst.l	d0
	beq	get_cnct_size
	rts				*error case
get_cnct_size:				*コネクトして出来るデータのサイズ
	st.b	ppc_cnnct-work(a6)	*「PPC_CONNECTが実行された」マーク
	move.l	d4,d1			*orig size
	move.l	adt_size(a3),d2		*cnct note size
					*データサイズ決定処理
	tst.l	d6			*d6=offset
	bpl	@f
	neg.l	d6			*オフセットが負値ならば被コネクトデータの先頭が基準
	add.l	d6,d2
	cmp.l	d1,d2
	bhi	cns00
	move.l	d1,d2
	bra	cns00
@@:					*オフセットが正値ならば被コネクトデータの最後尾が基準
	sub.l	d6,d1
	move.l	d1,d6			*d6.l=先頭からのオフセット値
	add.l	d1,d2			*d2.l=完成データ長
cns00:
	btst.b	#0,adnt_loop-work(a6)
	bne	@f
	move.l	d6,adnt_lp_start-work(a6)	*ループオフセット
@@:
	btst.b	#1,adnt_loop-work(a6)
	bne	@f
	move.l	d2,d4
	subq.l	#2,d4				*最終PCMデータ
	move.l	d4,adnt_lp_end-work(a6)		*ループオフセット
@@:
	move.l	d2,buf2_size(a5)
	move.l	d2,d4			*完成データ長のバッファを用意する
	bsr	get_temp_buf		*d2サイズ分確保(>a1.l=data area)
	bmi	t_out_of_memory
	move.l	a1,buf2_addr(a5)

	move.l	buf1_addr(a5),a0	*orig data address
	move.l	d6,d0			*orig data size
	beq	do_cnnct
@@:					*初めorigでバッファを埋める
	move.l	(a0)+,(a1)+
	subq.l	#4,d0
	bhi	@b
do_cnnct:
	move.l	buf2_addr(a5),a1	*dest address
	add.l	d6,a1			*offset加算
	move.l	adt_addr(a3),a0		*connect data
	move.l	adt_size(a3),d2
@@:
	move.w	(a0)+,(a1)+
	subq.l	#2,d2
	bne	@b

	move.l	buf1_addr(a5),a1
	bsr	free_mem		*元のデータ領域を開放
	move.l	buf2_addr(a5),a1
	move.l	a1,buf1_addr(a5)	*新規データをテンポラリと扱う
	tst.b	d7			*開放処理が必要か
	beq	prclp00

	move.l	a1,a0
	move.l	adt_addr(a3),a1		*外部ファイル領域を開放
	bsr	free_mem
	move.l	a0,a1
	bra	prclp00

proc_end:				*(ノート登録処理を行う)
	* < a1.l=address
	* < d4.l=size
	move.l	adt_sp_buf(pc),d0
	sub.l	#(20+adpcm_tbl_size),d0
	cmp.l	d0,sp
	beq	@f
					*再帰処理帰還(CASE:NO ERROR)
	lea	(20+adpcm_tbl_size)(sp),sp
	move.l	sp,a5
	bra	t_dat_ok
@@:					*以下再帰処理完全終了した場合
	tst.b	adntcopy_mode-work(a6)
	bne	exit_smp_read		*ポインタコピーケース

	move.l	d4,d2
	tst.b	adnt_regtype-work(a6)	*登録次元で登録する
	bpl	1f			*8 or 16bitPCM
	lsr.l	#2,d2			*ADPCM SIZE
	bsr	ensure_adpcm_buf	*>a1.l=address for storing adpcm
	bne	t_out_of_memory
	move.l	a1,a0			*格納領域
	move.l	d4,d0			*16bitPCM size
	move.l	buf1_addr(a5),a1	*16bitPCM addr
	bsr	pcm_to_adpcm
	lsr.l	#2,d4
	move.l	adnt_lp_start(pc),d0
	lsr.l	#2,d0
	move.l	d0,adnt_lp_start-work(a6)
	move.l	adnt_lp_end(pc),d0
	lsr.l	#2,d0
	move.l	d0,adnt_lp_end-work(a6)
	bra	do_reg_adnt
1:
	cmpi.b	#ID_8bitPCM,adnt_regtype-work(a6)
	bne	@f
	lsr.l	#1,d2			*8bitPCM size
	bsr	ensure_adpcm_buf	*>a1.l=address for storing adpcm
	bne	t_out_of_memory
	move.l	a1,a0			*格納領域
	move.l	d4,d0			*16bitPCM size
	move.l	buf1_addr(a5),a1	*16bitPCM addr
	bsr	pcm_to_8bitpcm
	lsr.l	#1,d4
	move.l	adnt_lp_start(pc),d0
	lsr.l	#1,d0
	move.l	d0,adnt_lp_start-work(a6)
	move.l	adnt_lp_end(pc),d0
	lsr.l	#1,d0
	move.l	d0,adnt_lp_end-work(a6)
	bra	do_reg_adnt
@@:					*単純にバッファへ転送する(case:16bitPCM)
	* < d2.l=size
	bsr	ensure_adpcm_buf	*>a1.l=address for storing pcm
	bne	t_out_of_memory
	move.l	a1,a0
	move.l	d4,d0
	move.l	buf1_addr(a5),a1	*16bitPCM addr
	move.l	a1,a2
	move.l	a0,a3
	addq.l	#3,d0
	andi.w	#$fffc,d0
@@:
	move.l	(a2)+,(a3)+
	subq.l	#4,d0
	bne	@b
do_reg_adnt:
	* < a0.l=data address
	* < d4.l=true size
	* < a1.l=address to free
	bsr	free_mem		*free source area(<a1=address)
	move.l	a0,a1
exit_smp_read:
	* < a1.l=data address
	* < d4.l=data size
	bsr	get_reg_dest		*登録先の重複チェック
	bmi	grd_err
	tst.b	(a3)			*空かどうか
	beq	@f			*空は次の処理へ
	.ifdef	ZPCNV3
	st.b	OVW_flag-work(a6)
	.endif
	bsr	erase_overlaped_note	*重複ノートの削除
	tst.l	d0
	beq	@f
	rts				*case error
@@:
	move.l	adnt_regtype(pc),d0	*属性
	move.l	d0,(a3)+		*data type
	tst.b	adntcopy_mode-work(a6)
	beq	@f
	ori.w	#$01_00,-2(a3)		*ポインタコピー登録であることをマーク
@@:
	move.l	a1,(a3)+		*source
	move.l	d4,(a3)+		*size
	move.b	ppc_cnnct(pc),d3	*PPC_CONNECTが実行されたなら
	bne	@f			*ループパラメータのデフォルトは設定されているはず
	moveq.l	#0,d1
	moveq.l	#0,d2
	move.b	adnt_loop(pc),d3	*ループパラメータ設定フラグ
	bne	@f
	clr.l	(a3)+			*lpst
	clr.l	(a3)+			*lped
	move.l	#1,(a3)+		*lptm
	bra	prdmy_set
@@:
	move.l	adnt_lp_start(pc),d1
	move.l	adnt_lp_end(pc),d2
	lsr.b	#1,d3			*ループ開始オフセットの指定はあったか
	bcc	def_lpst		*デフォルト値設定
	cmp.l	d4,d1			*異常値ならばループ先頭は0
	bcs	@f
def_lpst:
	moveq.l	#0,d1
@@:
	lsr.b	#1,d3			*ループ終了オフセットの指定はあったか
	bcc	def_lped		*デフォルト値設定
	cmp.l	d4,d2			*異常値ならばループ最終は最終データのところ
	bcs	@f
def_lped:
	move.l	d4,d2
	subq.l	#1,d2			*ADPCM,8bitPCMの場合は(サイズ-1)が最終データ
	cmp.b	#ID_16bitPCM,adnt_regtype-work(a6)	*check reg type
	bne	@f
	subq.l	#1,d2			*16bitPCMの場合は(サイズ-2)が最終データ
@@:
	move.l	d1,(a3)+		*loop start offset
	move.l	d2,(a3)+		*loop end offset
	move.l	adnt_lp_time(pc),d1
	lsr.b	#1,d3			*loop回数指定はあったか
	bcs	@f
	moveq.l	#1,d1			*デフォルト値(1:1shot)
@@:
	move.l	d1,(a3)+		*loop time
prdmy_set:
	clr.l	(a3)+
	clr.l	(a3)+
	move.l	v_buffer(pc),a0
	moveq.l	#adt_name_len-1,d0
@@:
	move.b	(a0)+,(a3)+		*tone name
	dbeq	d0,@b
	move.l	a4,a0			*next address
	move.l	adt_sp_buf-work(a6),sp
	bra	t_dat_ok

get_reg_dest:				*登録先ワークアドレスを求める
	* > a3.l=登録先ワーク
	* minus:error
	* zero:ok
	* - all
reglist	reg	d0-d1
	movem.l	reglist,-(sp)
	moveq.l	#0,d0
	move.w	adnt_regnote(pc),d0	*有効範囲は既にチェック済み
	bpl	@f
	andi.w	#$7fff,d0
	move.l	adpcm_tbl2(pc),d1
	bne	1f
2:
	moveq.l	#-1,d1			*TIMBRE ERROR
	movem.l	(sp)+,reglist
	rts
@@:
	move.l	adpcm_tbl(pc),d1
	beq	2b
1:
	move.l	d1,a3
	lsl.l	#adpcm_tbl_size_,d0	*adpcm_tbl_size倍
	add.l	d0,a3			*a3=mix destination parameter pointer
	moveq.l	#0,d1			*OK
	movem.l	(sp)+,reglist
	rts

grd_err:
	tst.w	adnt_regnote-work(a6)
	bpl	t_illegal_tone_number
	bra	t_illegal_timbre_number

erase_mode:				*消去ケース
	move.w	d1,adnt_regnote-work(a6)
	bsr	get_reg_dest		* > a3.l=登録先ワーク
	bmi	grd_err
	tst.b	(a3)			*空かどうか
	beq	grd_err

erase_overlaped_note:			*重複ノートの削除
	* < a1.l=登録予定データ格納アドレス
	* < a3.l=登録先ワークアドレス
	* > d0.l=0 no error
	* > a1.l=登録予定データ格納アドレス
	tst.b	adt_attribute(a3)
	bne	exit_erovn_no_err
reglist	reg	d1-d3/a0/a2
	movem.l	reglist,-(sp)
	move.l	a1,a2
	clr.b	(a3)			*一時的に空にする
	move.l	adt_addr(a3),a1
	move.l	adt_size(a3),d1
	addq.l	#3,d1
	andi.w	#$fffc,d1
	lea	(a1,d1.l),a0		*a0.l=削除対象データの最後尾
	move.l	a0,d3			*後で使用
	move.l	adpcm_buffer_end(pc),d0
*	addq.l	#3,d0
*	andi.w	#$fffc,d0
	sub.l	a0,d0
	beq	stblk_adbf		*後ろになにもない場合
	bcs	exit_erovn
@@:
	move.l	(a0)+,(a1)+
	subq.l	#4,d0
	bne	@b
stblk_adbf:
	move.l	adpcm_buffer_size(pc),d2
	sub.l	d1,d2
	move.l	adpcm_buffer_top(pc),a1
	jsr	enlarge_mem-work(a6)
	tst.l	d0
	bmi	eon_t_out_of_memory
	move.l	a0,adpcm_buffer_top-work(a6)
	move.l	d2,adpcm_buffer_size-work(a6)
	add.l	d2,a0
	move.l	adpcm_buffer_end(pc),a1
	move.l	a0,adpcm_buffer_end-work(a6)
					*転送によって生じた矛盾を解決する
	move.w	adpcm_n_max(pc),d0	*ノート番号登録方式
	beq	erovn_tone_case
	subq.w	#1,d0			*for dbra
	move.l	adpcm_tbl(pc),a0
erovnlp0:
	tst.b	(a0)
	beq	@f
	cmp.l	adt_addr(a0),d3
	bhi	@f
	sub.l	d1,adt_addr(a0)
@@:
	lea	adpcm_tbl_size(a0),a0
	dbra	d0,erovnlp0
erovn_tone_case:			*音色番号登録方式
	move.w	adpcm_n_max2(pc),d0
	beq	1f
	subq.w	#1,d0			*for dbra
	move.l	adpcm_tbl2(pc),a0
erovnlp1:
	tst.b	(a0)
	beq	@f
	cmp.l	adt_addr(a0),d3
	bhi	@f
	sub.l	d1,adt_addr(a0)
@@:
	lea	adpcm_tbl_size(a0),a0
	dbra	d0,erovnlp1
1:
	cmp.l	a2,d3			*登録予定データアドレスに対しても演算行う
	bhi	exit_erovn
	sub.l	d1,a2
exit_erovn:
	move.l	a2,a1
	movem.l	(sp)+,reglist
exit_erovn_no_err:
	moveq.l	#0,d0
	rts
eon_t_out_of_memory:
	movem.l	(sp)+,reglist
	bra	t_out_of_memory

ensure_adpcm_buf:			*登録先バッファの確保
	* < d2=additional size
	* > a1.l=usable area address
	* > a0.l=end of usable area address
	* > d2.l=long word border length
	* > d0.l=0 no error
reglist	reg	d1/d3/a0
	movem.l	reglist,-(sp)
	move.l	adpcm_buffer_top-work(a6),d0
	bne	eab0
	move.l	#ID_ZPD,d3
	bsr	get_mem			*メモリ確保
	tst.l	d0
	bmi	@f
	move.l	a0,adpcm_buffer_top-work(a6)
	move.l	d2,adpcm_buffer_size-work(a6)
	move.l	a0,a1
	add.l	d2,a0
	move.l	a0,adpcm_buffer_end-work(a6)
	moveq.l	#0,d0
@@:
	movem.l	(sp)+,reglist
	rts
eab0:					*新たにメモリ確保
	move.l	d2,-(sp)
	move.l	d0,a1
	move.l	adpcm_buffer_end(pc),d1
	sub.l	a1,d1
	add.l	adpcm_buffer_size(pc),d2	*new size
	bcs	t_out_of_memory
	jsr	enlarge_mem-work(a6)		*メモリ確保(>a0=address)
	tst.l	d0
	bmi	exit_eab0
	cmp.l	adpcm_buffer_top-work(a6),a0
	beq	@f
	bsr	remove_adpcm_table
@@:
	move.l	a0,adpcm_buffer_top-work(a6)
	move.l	d2,adpcm_buffer_size-work(a6)
	lea	(a0,d1.l),a1
	add.l	d2,a0
	move.l	a0,adpcm_buffer_end-work(a6)
	move.l	(sp)+,d2
	addq.l	#3,d2
	andi.w	#$fffc,d2
	moveq.l	#0,d0
exit_eab0:
	movem.l	(sp)+,reglist
	rts

remove_adpcm_table:			*データの移動が発生した時の対処
	* < a0.l=new address
	* - all
reglist	reg	d1-d4/a0-a1
	movem.l	reglist,-(sp)
	move.l	adpcm_buffer_top(pc),d3
	move.l	adpcm_buffer_end(pc),d4
	sub.l	d3,a0
	move.w	adpcm_n_max(pc),d2
	subq.w	#1,d2
	bcs	@f
	move.l	adpcm_tbl(pc),a1
	bsr	do_remove_adpcm_table
@@:
	move.w	adpcm_n_max2(pc),d2
	subq.w	#1,d2
	bcs	@f
	move.l	adpcm_tbl2(pc),a1
	bsr	do_remove_adpcm_table
@@:
	movem.l	(sp)+,reglist
	rts

do_remove_adpcm_table:
dratlp:
	tst.b	(a1)
	beq	@f
	move.l	adt_addr(a1),d0
	cmp.l	d3,d0
	bcs	@f
	cmp.l	d4,d0
	bhi	@f
	add.l	a0,d0
	move.l	d0,adt_addr(a1)
@@:
	lea	adt_len(a1),a1
	dbra	d2,dratlp
	rts

get_temp_buf:				*テンポラリ領域の確保
	* < d2=size
	* > a1.l=usable area address
	* > d0.l=minus: error
	* x d0
	movem.l	d2-d3/a0,-(sp)
	move.l	#ID_TEMP,d3
	bsr	get_mem
	move.l	a0,a1
	tst.l	d0
	movem.l	(sp)+,d2-d3/a0
	rts

get_temp_buf2:				*テンポラリ領域の確保(最大)
	* > d0.l=end address of mem.block(0でエラー)
	* > a1.l=usable area address
reglist	reg	d2-d3/a0
	movem.l	reglist,-(sp)
	move.l	#-1,-(sp)
	clr.w	-(sp)
	DOS	_S_MALLOC
	addq.w	#6,sp
	andi.l	#$00ffffff,d0
	move.l	d0,d2		*save size
	move.l	d0,-(sp)
	move.l	#ID_TEMP,d3
	bsr	get_mem
	tst.l	d0
	bmi	gtb2_t_out_of_memory
	move.l	a0,a1
	move.l	(sp)+,d0	*mem. block last address
	add.l	a1,d0
	movem.l	(sp)+,reglist
	rts
gtb2_t_out_of_memory:
	movem.l	(sp)+,reglist
	moveq.l	#0,d0		*error mark
	rts

conv_to_p16:				*16ビットPCM変換
	* < d4.l=adpcm data size
	* < d7.b=ID_adPCM,ID_8bitPCM
	* < a1.l=data address
	* > eq no error
	* x d2,a0
	cmpi.b	#ID_8bitPCM,d7
	beq	1f
	move.l	a1,a0			*source
	move.l	d4,d2
	lsl.l	#2,d2			*new size
	move.l	d2,buf1_size(a5)
	bsr	get_temp_buf		*> a1.l=data area, > minus:error
	bmi	@f
	pea	(a0)
	move.l	a1,(a5)
	move.l	d4,d0			*adpcm size
	bsr	just_adpcm_to_pcm
	move.l	(sp)+,a1
	bsr	free_mem		*元のデータ領域を開放
	move.l	(a5),a1			*新規データをテンポラリと扱う
	move.l	buf1_size(a5),d4
	moveq.l	#0,d0
@@:
	rts
1:					*8bitPCM CASE
	move.l	a1,a0			*source
	move.l	d4,d2
	add.l	d2,d2			*new size
	move.l	d2,buf1_size(a5)
	bsr	get_temp_buf		*> a1.l=data area, > minus:error
	bmi	1f
	pea	(a0)
	move.l	a1,(a5)
@@:
	move.b	(a0)+,d0
	ext.w	d0
	move.w	d0,(a1)+
	subq.l	#1,d4
	bne	@b
	move.l	(sp)+,a1
	bsr	free_mem		*元のデータ領域を開放
	move.l	(a5),a1			*新規データをテンポラリと扱う
	move.l	buf1_size(a5),d4
	moveq.l	#0,d0
1:
	rts

just_adpcm_to_pcm:		*ピッチチェンジやレベルチェンジを
				*行わない単なるADPCM→PCM変換
	* < a0=adpcm data buffer
	* < a1=pcm data buffer
	* < d0.l=adpcm data size
	* - all
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
	bpl	__neg_d4
	lsr.b	#4,d1		*get 4bit data
	addq.w	#1,a0
__neg_d4:
	not.b	d4
	bsr	calc_pcm_val	*実際の計算
	move.w	d2,(a1)+	*add pcm data to buffer
	subq.l	#1,d0
	bne	__atp_lp
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
	add.b	d7,d7
	move.w	(a5,d7.w),d3	*=d
	lsr.b	d7

	moveq.l	#0,d2		*=def

	btst	#2,d1
	beq	tst_bit1
	move.w	d3,d2
tst_bit1:
	lsr.w	d3
	btst	#1,d1
	beq	tst_bit0
	add.w	d3,d2
tst_bit0:
	lsr.w	d3
	btst	#0,d1
	beq	decide_def
	add.w	d3,d2
decide_def:
	lsr.w	d3
	add.w	d3,d2

	btst	#3,d1		*minus or plus??
	beq	plus_lastval
	neg.w	d2		*case not zero
plus_lastval:
	add.w	(a3),d2		*last_val
*	bsr	chk_ovf
	move.w	d2,(a3)		*d2=pcmdata

	add.b	d1,d1
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

pcm_to_8bitpcm:
	* < a0=8bitpcm data buffer
	* < a1=pcm data buffer
	* < d0.l=pcm data size
	* - all
	movem.l	d0-d1/a0-a1,-(sp)
1:
	move.w	(a1)+,d1
	cmpi.w	#-128,d1
	bge	2f
	move.w	#-128,d1
2:
	cmpi.w	#127,d1
	ble	3f
	moveq.l	#127,d1
3:
	move.b	d1,(a0)+
	subq.l	#2,d0
	bne	1b
	movem.l	(sp)+,d0-d1/a0-a1
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
	moveq.l	#%1010_1010,d4
	lea	last_val(pc),a3
	move.w	d6,(a3)
pta_lp:
	move.w	(a1)+,d3	*d3=pcm data
	bsr	calc_adpcm_val
	ror.b	d4
	bcc	set_lower
				*case upper 4bits
	lsl.b	#4,d1
	or.b	d1,d5
	move.b	d5,(a0)+
	bra	check_cnt
set_lower:
	move.b	d1,d5
check_cnt:
	subq.l	#2,d0
	bne	pta_lp
	movem.l	(sp)+,d0-d7/a0-a6
	rts

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
	lsr.b	d1
	exg	d7,d6
	bsr	calc_pcm_val
	exg	d6,d7
	lsr.b	d1
	rts

reglist	reg	d0-d4/a0-a3
spread_adpcm_n2:			*ADPCM管理テーブル拡張(音色番号登録方式)
	* < d0.w=timbre number($8000+(0-32767))
	* - all
	movem.l	reglist,-(sp)
	lea	adpcm_n_max2(pc),a2
	lea	init_adpcm_tbl2(pc),a3
	bra	@f
spread_adpcm_n:				*ADPCM管理テーブル拡張(ノート番号登録方式)
	* < d0.w=note number(0-32767)
	* - all
	movem.l	reglist,-(sp)
	lea	adpcm_n_max(pc),a2
	lea	init_adpcm_tbl(pc),a3
@@:
	andi.l	#$7fff,d0
	lsr.w	#7,d0			*上限拡張
	addq.w	#1,d0
	lsl.w	#7,d0
	cmpi.l	#adpcm_reg_max,d0
	bls	@f
	move.l	#adpcm_reg_max,d0
@@:
	move.l	d0,d4			*new n-max
	lsl.l	#adpcm_tbl_size_,d0
	move.l	d0,d2			*require size
	moveq.l	#0,d3
	move.w	(a2),d3			*d3.w=adpcm_n_max (enlarge or get?)
	bne	enlrg_adtb
	move.l	#ID_ZPD_TBL,d3		*ID
	bsr	get_mem
	tst.l	d0
	bmi	err_exit_spadt
	move.w	d4,(a2)			*adpcm_n_max
	move.l	a0,-(a2)		*adpcm_tbl
	jsr	(a3)
	moveq.l	#0,d0			*no error
	movem.l	(sp)+,reglist
	rts
enlrg_adtb:
*	< d3.l=adpcm_n_max		*初期化時に使用(adpcm_n_max)
	move.l	-(a2),a1		*addr
	bsr	enlarge_mem
	tst.l	d0
	bmi	err_exit_spadt
	move.l	a0,(a2)+		*adpcm_tbl
	move.w	d4,(a2)			*adpcm_n_max
	sub.w	d3,d4
	lsl.l	#adpcm_tbl_size_,d3
	add.l	d3,a0
	subq.w	#1,d4			*for dbra
@@:					*新しく確保したテーブル領域について初期化を行う
	clr.l	(a0)
	lea	adpcm_tbl_size(a0),a0
	dbra	d4,@b
	moveq.l	#0,d0
	movem.l	(sp)+,reglist
	rts
err_exit_spadt:				*メモリ不足エラー
	moveq.l	#-1,d0
	movem.l	(sp)+,reglist
	rts

init_adpcm_tbl:					*ノート番号指定方式用テーブルの初期化
	* - all
	movem.l	d0/a0,-(sp)
	move.w	adpcm_n_max(pc),d0		*通常ノート番号登録形式
	beq	exit_ati
	subq.w	#1,d0				*for dbra
	move.l	adpcm_tbl(pc),a0
@@:
	clr.l	(a0)				*init attributes(type,)
	lea	adpcm_tbl_size(a0),a0		*skip size
	dbra	d0,@b
exit_ati:
	movem.l	(sp)+,d0/a0
	rts

init_adpcm_tbl2:				*音色番号指定方式用テーブルの初期化
	* - all
	movem.l	d0/a0,-(sp)
	move.w	adpcm_n_max2(pc),d0		*音程変換可能音色分
	beq	exit_ati2
	subq.w	#1,d0				*for dbra
	move.l	adpcm_tbl2(pc),a0
@@:
	clr.l	(a0)				*init attributes(type,)
	lea	adpcm_tbl_size(a0),a0		*skip size
	dbra	d0,@b
exit_ati2:
	movem.l	(sp)+,d0/a0
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

kake:			*32ビット×32ビット=32ビット
	* < d0.l X d1.l
	* > d1.l
	* X d0-d4
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

ppc_cnnct:	dc.b	0		*PPC_CONNECTが実行されたか			 !
adnt_loop:	dc.b	0		*ループ指定が有効か(d0:start,d1:end,d2:loop time)!
adntcopy_mode:	ds.b	1		*既登録ノートの複写方式(0:COPY 1:POINTER COPY)	 !
		ds.b	1		*						 !
readingdata_type:	ds.b	1	*読み込みデータタイプのデフォルトID
	.even
