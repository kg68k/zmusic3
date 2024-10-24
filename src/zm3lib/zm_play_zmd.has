	.xdef	_zm_play_zmd

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_play_zmd( int size,char *zmd);
*-----------------------------------------------------------------------------

_zm_play_zmd:
	movem.l	param1(sp),d2/a1
	cmp.l	#ZmuSiC0,(a1)
	bne	@f
	addq.w	#8,a1
@@:
	Z_MUSIC	#ZM_PLAY_ZMD
	rts
