	.xdef	_zm_play_status_ch

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_play_status_ch( int );
*-----------------------------------------------------------------------------

_zm_play_status_ch:
	moveq.l	#2,d1
	move.l	param1(sp),d2
	Z_MUSIC	#ZM_PLAY_STATUS
	rts
