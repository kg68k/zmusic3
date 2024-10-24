	.xdef	_zm_release_int_service

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_release_int_service( char *entry );
*-----------------------------------------------------------------------------
_zm_release_int_service:
	move.l	param1(sp),a1
	moveq.l	#0,d1
	Z_MUSIC	#ZM_SET_INT_SERVICE
	rts
