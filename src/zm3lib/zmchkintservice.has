	.xdef	_zm_check_int_service

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	char	*zm_check_int_service( void );
*-----------------------------------------------------------------------------
_zm_check_int_service:
	moveq.l	#-1,d1
	suba.l	a1,a1
	Z_MUSIC	#ZM_SET_INT_SERVICE
	move.l	a0,d0
	rts
