	.xdef	_zm_store_error

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_store_error( int err,int noferr,char **addr );
*-----------------------------------------------------------------------------
_zm_store_error:
	movem.l	param1(sp),d1-d2/a1
	Z_MUSIC	#ZM_STORE_ERROR
	move.l	a0,(a1)
	rts
