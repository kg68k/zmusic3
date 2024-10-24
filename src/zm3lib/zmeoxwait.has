	.xdef	_zm_set_eox_wait

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_set_eox_wait( int port,int wait );
*-----------------------------------------------------------------------------

_zm_set_eox_wait:
	movem.l	param1(sp),d1-d2
	Z_MUSIC	#ZM_SET_EOX_WAIT
	rts
