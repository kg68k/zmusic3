	.xdef	_zm_mt32_partial

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_mt32_partial( int port,int size,int pl_id,char *partial );
*-----------------------------------------------------------------------------
_zm_mt32_partial:
	move.l	d3,a2
	movem.l	param1(sp),d1-d3/a1
	Z_MUSIC	#ZM_MT32_PARTIAL
	move.l	a2,d3
	rts
