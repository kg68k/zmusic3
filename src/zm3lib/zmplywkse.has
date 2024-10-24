	.xdef	_zm_get_play_work_se

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	char	*zm_get_play_work_se( int track );
*-----------------------------------------------------------------------------
_zm_get_play_work_se:
	move.l	param1(sp),d1
	Z_MUSIC	#ZM_GET_PLAY_WORK
	rts
