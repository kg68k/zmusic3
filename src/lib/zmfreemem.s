	.xdef	_zm_free_mem

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_free_mem( char *addr );
*-----------------------------------------------------------------------------
_zm_free_mem:
	move.l	param1(sp),a1
	Z_MUSIC	#ZM_FREE_MEM
	rts
