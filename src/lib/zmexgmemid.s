	.xdef	_zm_exchange_memid

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_exchange_memid( int mode,int s_emply,int d_emply,char *addr );
*-----------------------------------------------------------------------------
_zm_exchange_memid:
	move.l	d3,a2
	movem.l	param1(sp),d1-d3/a1
	Z_MUSIC	#ZM_EXCHANGE_MEMID
	move.l	a2,d3
	rts
