	.xdef	_zm_atoi

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	char	*zm_atoi( int track );
*-----------------------------------------------------------------------------

_zm_atoi:
	move.l	param1(sp),d1
	Z_MUSIC	#ZM_STOP
	move.l	a0,d0
	rts
