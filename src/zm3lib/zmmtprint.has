	.xdef	_zm_mt32_print

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_mt32_print( int port,int size,int id,char *mes );
*-----------------------------------------------------------------------------
_zm_mt32_print:
	move.l	d3,a2
	movem.l	param1(sp),d1-d3/a1
	Z_MUSIC	#ZM_MT32_PRINT
	move.l	a2,d3
	rts
