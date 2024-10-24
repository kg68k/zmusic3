	.xdef	_zm_play_status_tr

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_play_status_tr( int );
*-----------------------------------------------------------------------------

_zm_play_status_tr:
	moveq.l	#3,d1
	move.l	param1(sp),d2
	Z_MUSIC	#ZM_PLAY_STATUS
	rts
