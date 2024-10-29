	.xdef	_zm_int_stop

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	void	zm_int_stop( int tmtype );
*-----------------------------------------------------------------------------
_zm_int_stop:
	move.l	param1(sp),d1
	Z_MUSIC	#ZM_INT_STOP
	rts
