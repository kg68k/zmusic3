	.xdef	_zm_register_zpd

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_register_zpd( char *zpd );
*-----------------------------------------------------------------------------
_zm_register_zpd:
	move.l	param1(sp),a1
	Z_MUSIC	#ZM_REGISTER_ZPD
	rts
