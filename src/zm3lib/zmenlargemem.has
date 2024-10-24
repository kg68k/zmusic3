	.xdef	_zm_enlarge_mem

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	char	*zm_enlarge_mem( int size,char *addr );
*-----------------------------------------------------------------------------
_zm_enlarge_mem:
	movem.l	param1(sp),d2/a1
	Z_MUSIC	#ZM_ENLARGE_MEM
	move.l	a0,d0
	rts
