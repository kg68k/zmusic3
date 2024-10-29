	.xdef	_zm_solo_channels

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_solo_channels( int channels );
*-----------------------------------------------------------------------------
_zm_solo_channels:
	move.l	param1(sp),d1
	lea	1.w,a1
	Z_MUSIC	#ZM_MASK_CHANNELS
	rts
