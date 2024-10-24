	.xdef	_zm_release_driver

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_release_driver( char **zmsc );
*-----------------------------------------------------------------------------
_zm_release_driver:
	move.l	param1(sp),a1
	Z_MUSIC	#ZM_RELEASE_DRIVER
	move.l	a0,(a1)
	rts
