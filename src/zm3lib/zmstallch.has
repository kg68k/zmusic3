	.xdef	_zm_play_status_all_ch

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	void	zm_play_status_all_ch( int *);
*-----------------------------------------------------------------------------

_zm_play_status_all_ch:
	moveq.l	#0,d1
	move.l	param1(sp),a1
	Z_MUSIC	#ZM_PLAY_STATUS
	rts
