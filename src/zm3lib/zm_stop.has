	.xdef	_zm_stop

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	short	*zm_stop( short * );
*-----------------------------------------------------------------------------

_zm_stop:
	move.l	param1(sp),a1
	Z_MUSIC	#ZM_STOP
	move.l	a0,d0
	rts
