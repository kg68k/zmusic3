	.xdef	_zm_register_application

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_register_application( char *addr,int *result);
*-----------------------------------------------------------------------------
_zm_register_application:
	movem.l	param1(sp),a1-a2
	Z_MUSIC	#ZM_APPLICATION_RELEASER
	move.l	d0,(a2)
	move.l	a0,d0
	rts
