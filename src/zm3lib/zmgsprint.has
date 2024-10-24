	.xdef	_zm_gs_print
	.xdef	_zm_sc55_print

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_gs_print( int port,int size,int id,char *mes );
*-----------------------------------------------------------------------------

_zm_gs_print:
_zm_sc55_print:
	move.l	d3,a2
	movem.l	param1(sp),d1-d3/a1
	Z_MUSIC	#ZM_GS_PRINT
	move.l	a2,d3
	rts
