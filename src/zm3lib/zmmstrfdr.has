	.xdef	_zm_master_fader

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_master_fader( char *fdr );
*-----------------------------------------------------------------------------
_zm_master_fader:
	move.l	param1(sp),a1
	Z_MUSIC	#ZM_MASTER_FADER
	rts
