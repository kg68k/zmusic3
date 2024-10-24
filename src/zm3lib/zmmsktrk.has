	.xdef	_zm_mask_tracks

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	short	*zm_mask_tracks( short *track );
*-----------------------------------------------------------------------------
_zm_mask_tracks:
	move.l	param1(sp),a1
	Z_MUSIC	#ZM_MASK_TRACKS
	rts
