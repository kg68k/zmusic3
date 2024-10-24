size_of_isi:	equ	7*4+56		*付加情報のサイズ
include_file:				*.INCLUDE(インクルード)
*	bsr	check_relation_cmn	*コマンド関係チェック
	bsr	skip_eq
	cmp.l	a4,d4
	bls	m_missing_filename	*ファイルネームがありません
	cmpi.b	#'{',(a4)		*'{'で始まっているかどうか
	seq	d2
	bne	@f
	addq.w	#1,a4
@@:
	moveq.l	#0,d1			*len
	moveq.l	#0,d3			*拡張子マーク
	move.l	temp_buffer-work(a6),a2
infnlp:					*ファイルネームの取得
	cmp.l	a4,d4
	bls	exit_gtiffn
	cmpi.b	#' ',(a4)
	bls	exit_gtiffn
	move.b	(a4)+,d0
	bsr	chk_kanji
	bpl	@f
	move.b	d0,(a2)+
	cmp.l	a4,d4
	bls	m_kanji_break_off
	move.b	(a4)+,(a2)+
	addq.l	#2,d1
	bra	infnlp
@@:
	cmpi.b	#'.',d0
	bne	@f
	move.l	a2,d3
@@:
	move.b	d0,(a2)+
	addq.l	#1,d1
	bra	infnlp
exit_gtiffn:
	cmpi.b	#'.',-1(a2)
	beq	@f			*最後の文字が'.'
	tst.l	d3
	bne	2f
	bra	1f
@@:
	subq.w	#1,a2
1:
	move.b	#'.',(a2)+
	move.b	#'Z',(a2)+
	move.b	#'M',(a2)+
	move.b	#'C',(a2)+
2:
	tst.b	d2			*'{'で始まっている場合は最後の文字が
	beq	@f			*'}'である必要がある
	cmpi.b	#'}',-(a2)
	bne	m_illegal_command_line
	subq.l	#1,d1			*文字長が0ではだめ
	ble	m_missing_filename
@@:
	clr.b	(a2)+			*end code
	addq.l	#1,d1
					*>d1.l=filename length
	add.l	#size_of_isi,d1		*付加情報分のサイズも加算して今回のワーク占有量を算出
	move.l	erfn_addr-work(a6),a1
	move.l	erfn_now-work(a6),d2
	add.l	d1,d2
	cmp.l	erfn_size-work(a6),d2
	bcs	cpy_fn_to_erfn
					*ファイルネームバッファ拡張
	move.l	a0,-(sp)
	jsr	enlarge_mem-work(a6)
	tst.l	d0
	bmi	m_out_of_memory
	move.l	d2,erfn_size-work(a6)
	move.l	a0,erfn_addr-work(a6)
	move.l	a0,a1
	move.l	(sp)+,a0
cpy_fn_to_erfn:					*読み込みファイルネームを関連ワークへ保存
	add.l	erfn_now-work(a6),a1
	move.l	temp_buffer-work(a6),a2
	addq.l	#1,zms_file_id-work(a6)
	bcs	m_too_many_include_files
*	move.l	a1,erfn_recent0-work(a6)	*現在コンパイル中のファイル名
@@:						*ファイルネームをファイルネームバッファへ退避
	move.b	(a2)+,(a1)+
	bne	@b
	move.l	a1,d0
	addq.l	#1,d0
	bclr.l	#0,d0			*.even
	move.l	d0,a1
*	sub.l	erfn_addr-work(a6),d0	*いちおうセット
*	move.l	d0,erfn_now-work(a6)
	moveq.l	#size_of_isi/4-1,d0
@@:
	clr.l	(a1)+			*初期化
	dbra	d0,@b
	lea	-size_of_isi(a1),a1	*戻す

	move.l	temp_buffer-work(a6),a2
	jsr	fopen-work(a6)		*>d5.l=file handle
	tst.l	d5
	bmi	m_file_not_found

	jsr	get_fsize-work(a6)	*>d3.l=file size

	move.l	d3,d2
	move.l	#ID_TEMP,d3
	movem.l	d2/a0,-(sp)			*push true size,fn buffer
	jsr	get_mem-work(a6)
	tst.l	d0
	bmi	m_out_of_memory
prsv_isi:					*isi(information of sub include file)保存
*	move.l	a1,erfn_recent1-work(a6)	*最新isi付加情報アドレス
	move.l	a0,(a1)+			*読み込んだファイルのアドレス
	move.l	d2,(a1)+			*読み込んだファイルの長さ(d2:LW BORDER SIZE)
	move.l	d4,(a1)+			*親ソースの最終アドレス保存
	move.l	a4,(a1)+			*親ソースのコンパイルアドレス保存
	move.l	line_number-work(a6),(a1)+
	move.l	line_ptr-work(a6),(a1)+
	move.l	line_locate-work(a6),(a1)+
	lea	file_info_buf-work(a6),a2
	moveq.l	#56/4-1,d0
@@:
	move.l	(a2)+,(a1)+
	dbra	d0,@b
	bsr	check_include_error
	sub.l	erfn_addr-work(a6),a1
	move.l	erfn_now-work(a6),d3		*backup
	move.l	a1,erfn_now-work(a6)
	tst.l	d0
	bpl	@f
	subq.l	#1,zms_file_id-work(a6)
	move.l	d3,erfn_now-work(a6)
	movem.l	(sp)+,d3/a0
	bra	m_recusive_include_error
@@:
	move.l	(sp)+,d3		*get true size
	ifndef	sv
	move.w	sr,-(sp)
	andi.w	#$f8ff,sr
	endif
	move.l	d3,-(sp)		*push size
	move.l	a0,-(sp)		*push addr
	move.w	d5,-(sp)		*file handle
	DOS	_READ			*ソース読み込み
	lea	10(sp),sp
	ifndef	sv
	move.w	(sp)+,sr
	endif

	jsr	do_fclose-work(a6)

	move.l	a0,a4
	add.l	d3,a0
	move.l	a0,d4
	move.l	#1,line_number-work(a6)
	move.l	a4,line_ptr-work(a6)
	move.l	a4,line_locate-work(a6)

	move.l	(sp)+,a0
	addq.l	#1,include_depth-work(a6)
	bra	cmpl_lp

check_include_error:			*重複インクルードチェック
	* > d0.l=minus:error
reglist	reg	a1-a4
	movem.l	reglist,-(sp)
	move.l	erfn_addr-work(a6),a1	*check 無限再帰
	move.l	erfn_now-work(a6),d0
	lea	(a1,d0.l),a3		*end addr
cielp00:
	cmp.l	a3,a1
	bcc	cie_normal
@@:
	tst.b	(a1)+			*filename skip
	bne	@b
	move.l	a1,d0
	addq.l	#1,d0
	bclr.l	#0,d0			*.even
	move.l	d0,a1
	lea	7*4(a1),a1		*情報部分をポイント
	lea	56(a1),a4		*次のisi->a4.l
	lea	file_info_buf-work(a6),a2
	moveq.l	#54/2-1,d0
@@:
	cmpm.w	(a2)+,(a1)+
	bne	@f
	dbra	d0,@b
	moveq.l	#-1,d0			*error case
	movem.l	(sp)+,reglist
	rts
@@:
	move.l	a4,a1
	bra	cielp00
cie_normal:
	moveq.l	#0,d0			*normal case
	movem.l	(sp)+,reglist
	rts

pop_include_ope:				*インクルードしたファイルが
reglist	reg	d0-d1/a2
	movem.l	reglist,-(sp)
*	move.l	erfn_recent1-work(a6),d0	*コンパイル終了するとここへくる
*	beq	cmpl_lp
*	clr.l	erfn_recent0-work(a6)	*初期化
*	clr.l	erfn_recent1-work(a6)	*初期化
	move.l	erfn_addr-work(a6),a2
*	add.l	erfn_now-work(a6),a2
*!	move.l	include_depth-work(a6),d1
	move.l	zms_file_id-work(a6),d1
@@:
	tst.b	(a2)+
	bne	@b
	move.l	a2,d0
	addq.l	#1,d0
	bclr.l	#0,d0			*.even
	move.l	d0,a2
	subq.l	#1,d1
	beq	@f
	lea	size_of_isi(a2),a2
	bra	@b
@@:
	addq.l	#8,a2			*アドレス,サイズスキップ
	move.l	(a2)+,d4		*親ソースの終了アドレス
	move.l	(a2)+,a4		*親ソースのコンパイルアドレス
	move.l	(a2)+,line_number-work(a6)
	move.l	(a2)+,line_ptr-work(a6)
	move.l	(a2)+,line_locate-work(a6)
	subq.l	#1,include_depth-work(a6)
	movem.l	(sp)+,reglist
	bra	cmpl_lp

