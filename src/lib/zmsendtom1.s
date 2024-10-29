	.xdef	_zm_send_to_m1

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_send_to_m1( int port,int id );
*-----------------------------------------------------------------------------
_zm_send_to_m1:
	move.l	d3,a2
	movem.l	param1(sp),d1/d3
	Z_MUSIC	#ZM_SEND_TO_M1
	move.l	a2,d3
	rts
