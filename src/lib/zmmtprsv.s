	.xdef	_zm_mt32_partial_reserve

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_mt32_partial_reserve( int port,int id,char *rsv );
*-----------------------------------------------------------------------------
_zm_mt32_partial_reserve:
	move.l	d3,a2
	movem.l	param1(sp),d1/d3/a1
	Z_MUSIC	#ZM_MT32_PARTIAL_RESERVE
	move.l	a2,d3
	rts
