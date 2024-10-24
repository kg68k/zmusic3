	.xdef	_zm_mt32_reverb

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_mt32_reverb( int port,int size,int id,char *rvb );
*-----------------------------------------------------------------------------
_zm_mt32_reverb:
	move.l	d3,a2
	movem.l	param1(sp),d1-d3/a1
	Z_MUSIC	#ZM_MT32_REVERB
	move.l	a2,d3
	rts
