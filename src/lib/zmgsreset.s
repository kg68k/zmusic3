	.xdef	_zm_gs_reset
	.xdef	_zm_sc55_reset

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_gs_reset( int port,int id );
*-----------------------------------------------------------------------------
_zm_sc55_reset:
_zm_gs_reset:
	move.l	d3,a2		*保存
	movem.l	param1(sp),d1/d3
	Z_MUSIC	#ZM_GS_RESET
	move.l	a2,d3
	rts
