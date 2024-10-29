	.xdef	_zm_exclusive

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	void	zm_exclusive( int port,int size,int id,char *midi );
*-----------------------------------------------------------------------------

_zm_exclusive:
	move.l	d3,a2
	movem.l	param1(sp),d1-d3/a1
	Z_MUSIC	#ZM_EXCLUSIVE
	move.l	a2,d3
	rts
