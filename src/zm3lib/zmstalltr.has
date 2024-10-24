	.xdef	_zm_play_status_all_tr

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	void	zm_play_status_all_tr( short *);
*-----------------------------------------------------------------------------

_zm_play_status_all_tr:
	moveq.l	#1,d1
	move.l	param1(sp),a1
	Z_MUSIC	#ZM_PLAY_STATUS
	rts
