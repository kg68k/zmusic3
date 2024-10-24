	.xdef	_zm_print_error

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_print_error( int mode,int lang,int noferr,
*				char *ZMD,char *srcaddr,char *srcname,
*				char *errtbl
*				char **buff);
*-----------------------------------------------------------------------------
_zm_print_error:
	move.l	sp,a0
	movem.l	a3-a5,-(sp)
	move.w	param1+2(a0),d1
	swap	d1
	move.w	param2+2(a0),d1
	move.l	param3(a0),d2
	move.l	param4(a0),a1		**ZMD
	tst.b	(a1)
	bne	@f
	suba.l	a1,a1			*no ZMD name
@@:
	move.l	param5(a0),a2		*srcaddr
	tst.l	(a2)
	bne	@f
	suba.l	a2,a2
@@:
	move.l	param6(a0),a3		*srcname
	tst.b	(a3)
	bne	@f
	suba.l	a3,a3			*no srcname
@@:
	move.l	param7(a0),a5		*err tbl addr
	move.l	param8(a0),a4
	Z_MUSIC	#ZM_PRINT_ERROR		*a4=**buff
	move.l	a0,(a4)
	movem.l	(sp)+,a3-a5
	rts
