	.xdef	_zm_int_start

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	void	zm_int_start( int tmtype );
*-----------------------------------------------------------------------------
_zm_int_start:
	move.l	param1(sp),d1
	Z_MUSIC	#ZM_INT_START
	rts
