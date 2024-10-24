	.xdef	_zm_set_zpd_table

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_set_zpd_table( int ver,char *zpd );
*-----------------------------------------------------------------------------
_zm_set_zpd_table:
	movem.l	param1(sp),d1/a1
	Z_MUSIC	#ZM_SET_ZPD_TABLE
	rts
