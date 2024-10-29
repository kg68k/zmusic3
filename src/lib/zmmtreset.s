	.xdef	_zm_mt32_reset

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_mt32_reset( int port,int id );
*-----------------------------------------------------------------------------
_zm_mt32_reset:
	move.l	d3,a2
	movem.l	param1(sp),d1/d3
	Z_MUSIC	#ZM_MT32_RESET
	move.l	a2,d3
	rts
