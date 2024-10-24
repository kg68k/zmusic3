fopen:					*ファイルのオープン(環境変数参照モード)
	* < a2=file name
	* > d5=file handle (error:d5<0)
	* - all 
reglist	reg	d0-d1/a0-a2
	movem.l	reglist,-(sp)
	move.l	a2,fopen_name-work(a6)
	moveq.l	#0,d0
	move.l	d0,getname+10-work(a6)	*go_fopenにエントリが1回目であることをマーク
fopnlp00:
	move.b	(a2)+,d1
	beq	fopn0
	cmpi.b	#'\',d1			*init.
	bne	@f
	moveq.l	#0,d0
	bra	fopnlp00
@@:
	cmpi.b	#'/',d1			*init.
	bne	@f
	moveq.l	#0,d0
	bra	fopnlp00
@@:
	cmp.b	#'.',d1
	bne	fopnlp00
	move.l	a2,d0			*拡張子があるならばその位置をメモ
	bra	fopnlp00
fopn0:					*拡張子転送
	lea	getname+6-work(a6),a1
	tst.l	d0			*拡張子無しケース
	beq	no_ext_fopn
	move.b	#'_',(a1)+		*zmusic_
	move.l	d0,a0
@@:
	move.b	(a0)+,d0		*拡張子をzmusic_XXXのXXXの部分に設定
	beq	@f
	bsr	mk_capital
	move.b	d0,(a1)+
	bra	@b
@@:
	clr.b	(a1)+			*end code
	movem.l	(sp)+,reglist
	bsr	go_fopen
	tst.l	d5
	bmi	@f
	rts
no_ext_fopn:
	movem.l	(sp)+,reglist
@@:
	clr.w	getname+6-work(a6)
	st.b	getname+13-work(a6)	*go_fopenにエントリが2回目であることをマーク

reglist	reg	d0-d2/a0-a3
	movem.l	reglist,-(sp)
	bra	@f

go_fopen:
	* < a2=file name
	* > d5=file handle (error:d5<0)
	* - all 
	movem.l	reglist,-(sp)

	bsr	check_drvchg
	bmi	@f
	clr.w	-(sp)
	pea     (a2)
	DOS	_OPEN
	addq.w	#6,sp
	move.l	d0,d5		*d5.w=file handle
	bpl	get_file_info	*no problem
@@:
	movea.l	a2,a0		*a0=file name only(non pathed)

	pea	getname(pc)
	bsr	search_env
	addq.w	#4,sp
	tst.l	d0
	beq	exit_fopen
	move.l	d0,a1
fo0:
	moveq.l	#0,d1
	move.l	open_fn(pc),a2
fopen_lp01:
	tst.l	d1
	bne	cont_standard_dir
	move.b	(a1)+,d0
	cmpi.b	#'/',d0
	beq	standard_dir
	cmpi.b	#'-',d0
	beq	standard_dir
	subq.w	#1,a1
	moveq.l	#0,d1
fopen_lp02:
	move.b	(a1)+,d0
	beq	do_fopen
	cmpi.b	#';',d0
	beq	do_fopen
	move.b	d0,(a2)+
	bra	fopen_lp02
cont_standard_dir:
	move.l	d1,a1
	bra	subptlp
standard_dir:
	tst.b	getname+13-work(a6)
	beq	@f
	move.b	(a1)+,getname+6-work(a6)	*go_fopen1回目
	bra	1f
@@:
	move.b	(a1)+,getname+10-work(a6)	*go_fopen2回目
1:
	pea	getname-work(a6)
	bsr	search_env
	addq.w	#4,sp
	tst.l	d0
	beq	exit_fopen
	move.l	d0,a3
	move.l	a1,d1
subptlp:
	move.b	(a1)+,d0
	beq	@f
	cmpi.b	#';',d0
	beq	@f
	move.b	d0,(a2)+
	bra	subptlp
@@:
	moveq.l	#'\',d0		*余計な'\'記号の削除
subptlp0:
	cmp.b	-1(a2),d0
	bne	subpt0
	move.b	-2(a2),d2
	bsr	chk_knj
	bmi	subpt0
	subq.w	#1,a2
	bra	subptlp0
subpt0:
@@:
	cmp.b	(a3),d0
	bne	@f
	addq.w	#1,a3
	bra	@b
@@:
	move.b	d0,(a2)+
@@:
	move.b	(a3)+,d0
	beq	@f
	cmpi.b	#';',d0
	beq	do_fopen
	move.b	d0,(a2)+	*DIR名の転送
	bra	@b
@@:
	moveq.l	#0,d1
do_fopen:
	pea	(a0)
	moveq.l	#'\',d0		*余計な'\'記号の削除
subptlp1:
	cmp.b	-1(a2),d0
	bne	subpt1
	move.b	-2(a2),d2
	bsr	chk_knj
	bmi	subpt1
	subq.w	#1,a2
	bra	subptlp1
subpt1:
@@:
	cmp.b	(a0),d0
	bne	@f
	addq.w	#1,a0
	bra	@b
@@:
	move.b	d0,(a2)+
do_fopenlp:
	move.b	(a0)+,(a2)+
	bne	do_fopenlp
	clr.b	(a2)
	move.l	(sp)+,a0

	move.l	open_fn(pc),a2
	bsr	check_drvchg
	bmi	@f

	clr.w	-(sp)
	pea	(a2)
	DOS	_OPEN
	addq.w	#6,sp
	move.l	d0,d5		*d5.w=file handle
	bpl	get_file_info	*no problem
@@:
	tst.l	d1
	bne	fopen_lp01
	tst.b	-1(a1)		*まだ環境変数が残ってるか
	bne	fopen_lp01
exit_fopen:
	moveq.l	#-1,d5
	movem.l	(sp)+,reglist
	rts

chk_knj:
	tst.b	d2
	bpl	@f		*normal characters
	cmpi.b	#$a0,d2		*漢字か
	bcs	ckanji_yes
	cmpi.b	#$df,d2
	bls	@f
ckanji_yes:
	move.w	#CCR_NEGA,ccr	*yes
	rts
@@:
	move.w	#CCR_ZERO,ccr	*no
	rts

get_file_info:
	* < a2.l=オープン成功したファイル名文字列
	move.w	#32,-(sp)
	pea	(a2)
	pea.l	file_info_buf(pc)
	DOS	_FILES
	lea	10(sp),sp
	movem.l	(sp)+,reglist
	rts

search_env:
	movem.l	a0-a1,-(sp)
	DOS	_GETPDB
	move.l	d0,a1		*環境変数文字列群
	move.l	(a1),a1
	addq.w	#4,a1
	tst.b	(a1)
	beq	err_exit_sen	*環境変数なし
sen_lp00:
	move.l	2*4+4(sp),a0	*サーチ環境変数名
sen_lp01:
	move.b	(a1)+,d0
	cmpi.b	#'=',d0
	bne	@f
	moveq.l	#0,d0
@@:
	cmp.b	(a0)+,d0
	bne	skip_next_en
	tst.b	d0
	bne	sen_lp01
	move.l	a1,d0
	bra	exit_sen
skip_next_en:
	tst.b	(a1)+
	bne	skip_next_en
	tst.b	(a1)
	bne	sen_lp00
err_exit_sen:
	moveq.l	#0,d0		*error
exit_sen:
	movem.l	(sp)+,a0-a1
	rts

get_fsize:			*ファイルサイズの偶数調整なし
	* < d5.w=file handle
	* > d3.l=data size
	* > mi=err
	* X d0
	* - d5
	move.w	#2,-(sp)	*ファィルの長さを調べる
	clr.l	-(sp)
	move.w	d5,-(sp)
	DOS	_SEEK
 	addq.w	#8,sp		*d0.l=file length
gf0:
	move.l	d0,d3		*d3=length
	ble	@f

	clr.w	-(sp)		*ファイルポインタを元に戻す
	clr.l	-(sp)
	move.w	d5,-(sp)
	DOS	_SEEK
	addq.w	#8,sp
	moveq.l	#0,d0
	rts
@@:
	bsr	do_fclose
	moveq.l	#-1,d0
	rts

do_fclose:
	move.w	d5,-(sp)	*close
	DOS	_CLOSE
	addq.w	#2,sp
	rts

check_drvchg:
	* < a2.l=path
	* > zero:no problem
	* > minus:error
	* x d0
	move.b	(a2),d0
	bsr	chk_kanji
	bmi	check_current
	cmpi.b	#':',1(a2)
	bne	check_current
	bsr	mk_capital
	cmpi.b	#'A',d0
	bcs	check_current
	cmpi.b	#'Z',d0
	bhi	check_current
	sub.b	#$40,d0
	bra	@f
check_current:
	moveq.l	#0,d0
@@:
	move.w	d0,-(sp)
	DOS	_DRVCTRL
	addq.w	#2,sp
	btst.l	#1,d0
	beq	not_ready_chkdrv
	moveq.l	#0,d0		*no error mark
	rts

not_ready_chkdrv:
	moveq.l	#-1,d0		*error mark
	rts
	*		 0123456789
getname:	dc.b	'zmusic_???'
		dc.l	0	*最下位バイトはフラグにもなっている
file_info_buf:	ds.b	54		*ファイル情報一時格納バッファ
	.even
