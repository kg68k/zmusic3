	.xdef	_zm_solo_track

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_solo_track( int track );
*-----------------------------------------------------------------------------
_zm_solo_track:
	move.l	param1(sp),d1
	lea	1.w,a1
	Z_MUSIC	#ZM_MASK_TRACKS
	rts
