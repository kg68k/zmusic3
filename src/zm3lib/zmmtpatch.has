	.xdef	_zm_mt32_patch

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_mt32_patch( int port,int size,int pt_id,char *patch );
*-----------------------------------------------------------------------------
_zm_mt32_patch:
	move.l	d3,a2
	movem.l	param1(sp),d1-d3/a1
	Z_MUSIC	#ZM_MT32_PATCH
	move.l	a2,d3
	rts
