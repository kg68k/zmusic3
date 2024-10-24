	.xdef	_zm_gs_chorus
	.xdef	_zm_sc55_chorus

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_gs_chorus( int port,int size,int id,char *cho );
*-----------------------------------------------------------------------------

_zm_gs_chorus:
_zm_sc55_chorus:
	move.l	d3,a2
	movem.l	param1(sp),d1-d3/a1
	Z_MUSIC	#ZM_GS_CHORUS
	move.l	a2,d3
	rts
