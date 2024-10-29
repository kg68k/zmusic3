	.xdef	_zm_cont

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	short	*zm_cont( short * );
*-----------------------------------------------------------------------------

_zm_cont:
	move.l	param1(sp),a1
	Z_MUSIC	#ZM_STOP
	move.l	a0,d0
	rts
