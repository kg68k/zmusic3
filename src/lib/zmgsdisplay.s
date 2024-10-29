	.xdef	_zm_gs_display
	.xdef	_zm_sc55_display

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_gs_display( int port,int id,short *pattern );
*-----------------------------------------------------------------------------

_zm_gs_display:
_zm_sc55_display:
	move.l	d3,a2
	movem.l	param1(sp),d1/d3/a1
	Z_MUSIC	#ZM_GS_DISPLAY
	move.l	a2,d3
	rts
