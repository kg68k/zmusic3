	.xdef	_zm_sc88_delay

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_sc88_delay( int port,int size,int id,char *dly );
*-----------------------------------------------------------------------------

_zm_sc88_delay:
	move.l	d3,a2
	movem.l	param1(sp),d1-d3/a1
	Z_MUSIC	#ZM_SC88_DELAY
	move.l	a2,d3
	rts
