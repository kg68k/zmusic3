	.xdef	_zm_mask_channels

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	*zm_mask_channels( short *channel );
*-----------------------------------------------------------------------------
_zm_mask_channels:
	move.l	param1(sp),a1
	Z_MUSIC	#ZM_MASK_CHANNELS
	rts
