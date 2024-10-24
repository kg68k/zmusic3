do_prt_err_mes:
	* < d1.hw=output mode(0:screen,1:buffer)	(Be used in ZMSC0)
	* < d1.lw=language mode(0:English,1:Japanese)
	* < d2.l=num. of err/warn
	* < a0.l=error table addr.
	* < a1.l=ZMD filename(ない場合は0)
	* < a2.l=source address(ない場合は0)
	* < a3.l=source filename(ない場合は0)
	* < (a5.l=画面リダイレクトバッファ(FNC $6F))
	* < (d7.l=文字ポインタ(FNC $6F))
	* > a0.l=出力バッファ(if d1.l==1)	(Be used in ZMSC0)
	* - all
reglist	reg	d0-d7/a0-a5
	movem.l	reglist,-(sp)
	lea	err_mes_tbl_e(pc),a4	*English version
	tst.b	d1
	beq	@f
	lea	err_mes_tbl_j(pc),a4	*Japanese version
@@:
	move.l	a1,d6			*後で使う
errocc_lp:
	move.l	a3,src_name-work(a6)	*主ソースファイル名
	moveq.l	#0,d0			*dummy line number
	move.l	(a0)+,d1		*err number
	move.l	a0,d3
	move.l	(a0)+,d0
	or.l	(a0)+,d0
	or.l	(a0)+,d0
	beq	case_no_lner		*付加エラー情報なし
	move.l	d3,a0

	move.l	(a0)+,d0		*zms file name
	beq	@f
	move.l	d0,src_name-work(a6)		*サブソースファイル名
@@:
	cmpi.w	#UNDEFINED_ZMD_CODE,d1
	beq	dpem_clcttl_case
	cmpi.w	#FILE_NOT_FOUND,d1
	beq	dpem_read_err
	cmpi.w	#ILLEGAL_FILE_SIZE,d1
	beq	dpem_read_err
	cmpi.w	#READ_ERROR,d1
	beq	dpem_read_err

	move.l	(a0)+,d3	*line number
	move.l	(a0)+,d5	*line locate
	move.l	d3,d0
	bsr	num_to_str	* < d0.l=line number

	tst.l	src_name-work(a6)		*ない場合はスキップ
	beq	@f
	move.l	src_name-work(a6),-(sp)
	PRINT			*filename表示
	addq.w	#4,sp

	lea	suji-1(pc),a1
	bsr	prta1_		*tab & line number

	move.w	#9,-(sp)	*tab
	PUTCHAR
	addq.w	#2,sp
@@:
	move.l	d1,d0
	andi.l	#$ffff,d0
	bsr	num_to_str

	lea	Error(pc),a1
	cmpi.w	#SURPLUS_IN_DIVISION,d1
	bcs	@f
	lea	Warning(pc),a1
@@:
	bsr	prta1_

	lea	suji(pc),a1
	bsr	prta1_		*err number

	lea	colontab(pc),a1	*':',13,10,0
	bsr	prta1_

	add.w	d1,d1
	move.w	(a4,d1.w),d0
	lea	(a4,d0.w),a1
	bsr	prta1_		*エラーメッセージ表示

	lea	CRLF(pc),a1
	bsr	prta1_

	move.l	a2,-(sp)
	move.l	src_name-work(a6),d0
	beq	gnd00		*サブソースでない
	cmp.l	d0,a3
	beq	gnd00		*サブソースでない
	move.l	d0,a2
@@:
	tst.b	(a2)+		*ファイル名スキップ
	bne	@b
	move.l	a2,d0
	addq.l	#1,d0
	bclr.l	#0,d0
	move.l	d0,a2
	add.l	(a2)+,a2
gnd00:
	move.l	a2,d0		*ない場合はスキップ
	beq	go_next_dpem
	tst.l	d3
	beq	go_next_dpem
	bsr	scan_line_number
go_next_dpem:
	move.l	(sp)+,a2
	bra	next_dpem
case_no_lner:			*行情報なしエラー
	tst.l	d6
	beq	@f
	pea	(a1)
	PRINT			*filename
	addq.w	#4,sp

	move.w	#9,-(sp)	*tab
	PUTCHAR
	addq.w	#2,sp
@@:
	move.l	d1,d0
	andi.l	#$ffff,d0
	bsr	num_to_str

	lea	Error(pc),a1
	cmpi.w	#SURPLUS_IN_DIVISION,d1
	bcs	@f
	lea	Warning(pc),a1
@@:
	bsr	prta1_

	lea	suji(pc),a1	*err number
	bsr	prta1_

	lea	colontab(pc),a1	*':',13,10,0
	bsr	prta1_

	add.w	d1,d1
	move.w	(a4,d1.w),d0
	lea	(a4,d0.w),a1
	bsr	prta1_		*エラーメッセージ表示

	lea	CRLF(pc),a1
	bsr	prta1_
next_dpem:
	subq.l	#1,d2
	bne	errocc_lp
	movem.l	(sp)+,reglist
	rts

dpem_clcttl_case:		*UNDEFINED_ZMD_CODE(CALC_TOTAL専用)
	move.l	(a0)+,d0	*offset
	bsr	get_hex32

	tst.l	src_name-work(a6)
	beq	@f		*ない場合はスキップ
	move.l	src_name-work(a6),-(sp)
	PRINT			*filename
	addq.w	#4,sp

	move.w	#9,-(sp)	*tab
	PUTCHAR
	addq.w	#2,sp
@@:
	lea	suji(pc),a1
	bsr	prta1_		*offset

	move.w	#32,-(sp)
	PUTCHAR			*spc
	addq.w	#2,sp

	move.l	(a0)+,d0	*zmd
	bsr	get_hex32
	lea	suji+6(pc),a1
	bsr	prta1_		*zmd

	move.w	#9,-(sp)	*tab
	PUTCHAR
	addq.w	#2,sp

	move.l	d1,d0
	andi.l	#$ffff,d0
	bsr	num_to_str

	lea	Error(pc),a1
	cmpi.w	#SURPLUS_IN_DIVISION,d1
	bcs	@f
	lea	Warning(pc),a1
@@:
	bsr	prta1_

	lea	suji(pc),a1
	bsr	prta1_		*err number

	lea	colontab(pc),a1	*':',13,10,0
	bsr	prta1_

	add.w	d1,d1
	move.w	(a4,d1.w),d0
	lea	(a4,d0.w),a1
	bsr	prta1_		*エラーメッセージ表示

	lea	CRLF(pc),a1
	bsr	prta1_

	bra	next_dpem

dpem_read_err:				*READ ERROR
	tst.l	src_name-work(a6)	*ない場合はスキップ
	beq	@f
	move.l	src_name-work(a6),-(sp)
	PRINT				*filename表示
	addq.w	#4,sp

	move.w	#9,-(sp)		*tab
	PUTCHAR
	addq.w	#2,sp
@@:
	move.l	d1,d0
	andi.l	#$ffff,d0
	bsr	num_to_str

	lea	Error(pc),a1
	cmpi.w	#SURPLUS_IN_DIVISION,d1
	bcs	@f
	lea	Warning(pc),a1
@@:
	bsr	prta1_

	lea	suji(pc),a1
	bsr	prta1_			*err number

	lea	colontab(pc),a1	*':',13,10,0
	bsr	prta1_

	add.w	d1,d1
	move.w	(a4,d1.w),d0
	lea	(a4,d0.w),a1
	bsr	prta1_			*エラーメッセージ表示

	lea	CRLF(pc),a1
	bsr	prta1_

	addq.w	#8,a0
	bra	next_dpem

Warning:	dc.b	'WARNING ',0
Error:		dc.b	'ERROR   ',0
colontab:	dc.b	':',9,0
	.even
src_name:	ds.l	1

scan_line_number:		*エラー箇所の表示
	* < d3.l=探したい行番号
	moveq.l	#1,d4
linehedlp00:			*行の頭だし
	cmp.l	d3,d4
	beq	sln_findend
linehedlp01:
	move.b	(a2)+,d0
	jsr	chk_kanji-work(a6)
	bpl	@f
	addq.w	#1,a2
	bra	linehedlp01
@@:
	cmpi.b	#$0a,d0
	bne	linehedlp01
	addq.l	#1,d4
	bra	linehedlp00
sln_findend:
	move.l	a2,a1
	move.l	a1,-(sp)
slnfe_lp:
	move.b	(a2)+,d0
	jsr	chk_kanji-work(a6)
	bpl	@f
	addq.w	#1,a2
	bra	slnfe_lp
@@:
	tst.b	d0
	beq	@f
	cmpi.b	#$0d,d0
	beq	@f
	cmpi.b	#$0a,d0
	beq	@f
	cmpi.b	#$1a,d0
	bne	slnfe_lp
@@:
	clr.b	-(a2)		*終端コード設定
	bsr	prta1_
	move.b	d0,(a2)		*復元

	lea	CRLF(pc),a1	*13,10,0
	bsr	prta1_
	move.l	(sp)+,a1
	tst.l	d5
	beq	prt_arrow
perlctlp:			*エラー箇所の明示
	moveq.l	#9,d0		*tab
	cmp.b	(a1)+,d0
	beq	@f
	moveq.l	#' ',d0
@@:
	move.w	d0,-(sp)
	PUTCHAR
	addq.w	#2,sp
	subq.l	#1,d5
	bne	perlctlp
prt_arrow:
	move.w	#'^',-(sp)
	PUTCHAR
	addq.w	#2,sp

	lea	CRLF(pc),a1	*13,10,0
	bra	prta1_

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
	swap	d0
	tst.w	d0
	beq	soroelp
	move.b	#',',(a0)+
	bra	soroelp
soroe01:
	swap	d0
soroelp:
	move.b	(a1)+,(a0)+
	move.b	(a1)+,(a0)+
	move.b	(a1)+,(a0)+
	subq.w	#1,d0
	ble	exit_soroe
	move.b	#',',(a0)+
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
