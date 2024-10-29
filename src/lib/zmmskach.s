	.xdef	_zm_mask_all_channels

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_mask_all_channels( int mode );
*-----------------------------------------------------------------------------
_zm_mask_all_channels:
	move.l	param1(sp),d1
	suba.l	a1,a1
	Z_MUSIC	#ZM_MASK_CHANNELS
	rts
