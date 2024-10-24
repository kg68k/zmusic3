	.xdef	_zm_mt32_drum

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_mt32_drum( int port,int size,int dr_id,char *drum );
*-----------------------------------------------------------------------------
_zm_mt32_drum:
	move.l	d3,a2
	movem.l	param1(sp),d1-d3/a1
	Z_MUSIC	#ZM_MT32_DRUM
	move.l	a2,d3
	rts
