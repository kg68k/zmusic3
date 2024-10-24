disprslt:				*calc_totalの結果表示
	* < d2.l=zmd size
reglist	reg	d0-d6/a0-a3
	movem.l	reglist,-(sp)
	move.l	d2,d6			*d6=size
	move.l	a0,a3			*メモリ解放時に使用

	moveq.l	#1,d5			*TRACK NUMBER
	lea	4*8(a0),a0		*スキップRESERVEDエリア
rsltclcttl_lp:
	move.l	(a0)+,d0		*get offset
	bmi	exit_rsltclcttl_lp
	lea	(a0,d0.l),a2

	lea	track_no+6(pc),a1	*'-TRACK'
	moveq.l	#10,d0
@@:
	move.b	#'-',(a1)+		*'-'で埋める
	dbra	d0,@b
	move.l	d5,d0
	bsr	num_to_str		*数値→文字列変換
	lea	track_no+6(pc),a1
@@:
	move.b	suji-(track_no+6)(a1),d0
	beq	@f
	move.b	d0,(a1)+
	bra	@b
@@:
	move.l	a2,a1
	move.l	(a1)+,d0
	or.l	(a1)+,d0
	or.l	(a1)+,d0
	or.l	(a1)+,d0
	bne	@f
	move.l	a1,a2			*全情報が0はそれはパターントラック
	bra	rsltclcttl_lp
@@:
	lea	track_no(pc),a1		*'-TRACKxxx-------------------------------------'
	bsr	prta1_

	lea	ttl_stp(pc),a1		*'TOTAL STEPTIME:'
	bsr	clc_mes_prt2
	lea	ttl_chksm(pc),a1	*'TOTAL CHECKSUM:'
	bsr	clc_mes_prt
	lea	ttl_msr(pc),a1		*'TOTAL MEASURE :'
	bsr	clc_mes_prt		*> d1.l=number of measure
	move.l	#1,d3
	move.l	d1,d4
	bne	@f
	addq.l	#1,d5			*inc trk num
	bra	rsltclcttl_lp
@@:
	lea	measure_no(pc),a1	*'-MEASURE'
	bsr	prta1_
	move.l	d3,d0
	bsr	num_to_str
	lea	suji(pc),a1
	bsr	prta1_			*measure number
	lea	dashcrlf(pc),a1
	bsr	prta1_			*'-',CR,LF
	lea	msr_stp(pc),a1		*TAB,'STEPTIME:'
	bsr	clc_mes_prt
	lea	msr_chksm(pc),a1	*TAB,'CHECKSUM:'
	bsr	clc_mes_prt
	addq.l	#1,d3			*inc msr num
	subq.l	#1,d4			*dec rept ctr
	bne	@b
	addq.l	#1,d5			*inc trk num
	bra	rsltclcttl_lp
exit_rsltclcttl_lp:
	lea	clc_ttl_header(pc),a1	*ステップタイム計算
	bsr	prta1_

	move.l	d6,d0
	bsr	num_to_str
	move.l	a3,a2			*計算結果表示
	lea	ttl_siz(pc),a1		*'TOTAL ZMD SIZE:'
	bsr	prta1_
	lea	suji2(pc),a1
	bsr	prta1_
	lea	BYTES(pc),a1
	bsr	prta1_
	lea	ttl_stp(pc),a1		*'TOTAL STEPTIME:'
	bsr	clc_mes_prt
	lea	ttl_chksm(pc),a1	*'TOTAL CEHCKSUM:'
	bsr	clc_mes_prt
	lea	ttl_plt+15(pc),a1	*時間文字列作成
	lea	1(a2),a0
	moveq.l	#3-1,d2
dsp_pltmlp:
	moveq.l	#0,d0
	move.b	(a0)+,d0
	bsr	num_to_str
	move.b	suji+0(pc),d0
	move.b	suji+1(pc),d1
	bne	@f
	move.b	#'0',(a1)+
	move.b	d0,(a1)+
	bra	next_dspplt
@@:
	move.b	d0,(a1)+
	move.b	d1,(a1)+
next_dspplt:
	addq.w	#1,a1
	dbra	d2,dsp_pltmlp
	lea	ttl_plt(pc),a1		*'TOTAL PLAYTIME:'
	bsr	prta1_
	move.l	a3,a1			*get back addr.
	bsr	free_mem		*<a1.l=mem. block addr.CALC_TOTAL結果バッファ解放
	movem.l	(sp)+,reglist
	rts

clc_mes_prt:
	* < a1.l=message addr.
	* < a2.l=value stored buffer
	* > d1.l=取り出した値
	* x d0-d1/a1 
	bsr	prta1_
	move.l	(a2)+,d1
	move.l	d1,d0
	bsr	num_to_str
	lea	suji(pc),a1
	bsr	prta1_			*print value in DEC
	move.w	#'(',-(sp)		*'('
	DOS	_PUTCHAR
	addq.w	#2,sp
	move.l	d1,d0
	bsr	get_hex32
	lea	suji(pc),a1
	bsr	prta1_			*print value in HEX
	lea	brktedcrlf(pc),a1	*')',CR,LF
	bra	prta1_

clc_mes_prt2:
	* < a1.l=message addr.
	* < a2.l=value stored buffer
	* > d1.l=取り出した値
	* x d0-d1/a1 
	bsr	prta1_			*タイトルメッセージ表示

	pea	(a2)
	move.l	(a2)+,d0		*ループ外
*	beq	@f
	bsr	num_to_str
	lea	suji(pc),a1
	bsr	prta1_			*print value in DEC
	move.w	#';',-(sp)		*';'
	DOS	_PUTCHAR
	addq.w	#2,sp
@@:
	move.l	(a2)+,d0		*ループ内
	bsr	num_to_str
	lea	suji(pc),a1
	bsr	prta1_			*print value in DEC

	move.l	(sp)+,a2

	move.w	#'(',-(sp)		*'('
	DOS	_PUTCHAR
	addq.w	#2,sp
	move.l	(a2)+,d0		*ループ外
*	beq	@f
	bsr	get_hex32
	lea	suji(pc),a1
	bsr	prta1_			*print value in HEX
	move.w	#';',-(sp)		*';'
	DOS	_PUTCHAR
	addq.w	#2,sp
@@:
	move.l	(a2)+,d0		*ループ内
	bsr	get_hex32
	lea	suji(pc),a1
	bsr	prta1_			*print value in HEX
	lea	brktedcrlf(pc),a1	*')',CR,LF
	bra	prta1_

track_no:	dc.b	'-TRACK----------------------------------------------------',13,10,0
dashcrlf:	dc.b	'-',13,10,0
ttl_siz:	dc.b	'TOTAL ZMD SIZE:',0
ttl_stp:	dc.b	'TOTAL STEPTIME:',0
ttl_chksm:	dc.b	'TOTAL CHECKSUM:',0
ttl_msr:	dc.b	'TOTAL MEASURE :',0
measure_no:	dc.b	'-MEASURE',0
msr_stp:	dc.b	9,'STEPTIME:',0
msr_chksm:	dc.b	9,'CHECKSUM:',0
clc_ttl_header:	dc.b	'----------------------------------------------------------',13,10,0
ttl_plt:	dc.b	'TOTAL PLAYTIME:00:00:00',13,10,0
BYTES:		dc.b	' bytes',13,10,0
brktedcrlf:	dc.b	')',13,10,0
	.even
