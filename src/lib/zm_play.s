	.xdef	_zm_play

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	short	*zm_play( short * );
*-----------------------------------------------------------------------------

_zm_play:
	move.l	param1(sp),a1
	Z_MUSIC	#ZM_PLAY
	move.l	a0,d0
	rts
