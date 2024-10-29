	.xdef	_zm_convert_pcm

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	void	zm_convert_pcm( int mode, int size, char *source, char *destination );
*-----------------------------------------------------------------------------

_zm_convert_pcm:
	movem.l	param1(sp),d1-d2/a1-a2
	Z_MUSIC	#ZM_CONVERT_PCM
	rts
