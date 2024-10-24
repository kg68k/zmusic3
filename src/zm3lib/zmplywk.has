	.xdef	_zm_get_play_work

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	char	*zm_get_play_work( int track );
*-----------------------------------------------------------------------------
_zm_get_play_work:
	move.l	param1(sp),d1
	Z_MUSIC	#ZM_GET_PLAY_WORK
	move.l	a0,d0
	rts
