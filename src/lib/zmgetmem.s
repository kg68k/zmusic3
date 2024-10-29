	.xdef	_zm_get_mem

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	char	*zm_get_mem( int size,int emply );
*-----------------------------------------------------------------------------
_zm_get_mem:
	move.l	d3,a2
	movem.l	param1(sp),d2-d3
	Z_MUSIC	#ZM_GET_MEM
	move.l	a2,d3
	move.l	a0,d0
	rts
