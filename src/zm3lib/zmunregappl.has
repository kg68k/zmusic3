	.xdef	_zm_unregister_application

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_unregister_application( int result);
*-----------------------------------------------------------------------------
_zm_unregister_application:
	move.l	param1(sp),d1
	suba.l	a1,a1
	Z_MUSIC	#ZM_APPLICATION_RELEASER
	move.l	a0,d0
	rts
