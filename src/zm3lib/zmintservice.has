	.xdef	_zm_set_int_service

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_set_int_service( int clock,int tempo,char *entry );
*-----------------------------------------------------------------------------
_zm_set_int_service:
	movem.l	param1(sp),d1-d2/a1
	swap	d1
	move.w	d2,d1
	Z_MUSIC	#ZM_SET_INT_SERVICE
	rts
