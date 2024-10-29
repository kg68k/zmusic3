	.xdef	_zm_m1_print

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_m1_print( int size,char *mes );
*-----------------------------------------------------------------------------
_zm_m1_print:
	movem.l	param1(sp),d2/a1
	Z_MUSIC	#ZM_M1_PRINT
	rts
