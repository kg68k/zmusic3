	.xdef	_zm_gm_system_on

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_gm_system_on( int port );
*-----------------------------------------------------------------------------
_zm_gm_system_on:
	move.l	param1(sp),d1
	Z_MUSIC	#ZM_GM_SYSTEM_ON
	rts
