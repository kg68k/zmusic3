	.xdef	_zm_free_mem2

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_free_mem2( int emply );
*-----------------------------------------------------------------------------
_zm_free_mem2:
	move.l	d3,a2
	move.l	param1(sp),d3
	Z_MUSIC	#ZM_FREE_MEM2
	move.l	a2,d3
	rts
