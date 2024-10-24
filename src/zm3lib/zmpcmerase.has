	.xdef	_zm_pcm_erase

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_pcm_erase( int num );
*-----------------------------------------------------------------------------
_zm_pcm_erase:
	move.l	param1(sp),d1
	suba.l	a1,a1			*erase mode
	Z_MUSIC	#ZM_PCM_READ
	rts
