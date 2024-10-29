	.xdef	_zm_se_play

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_se_play( char *zmd );
*-----------------------------------------------------------------------------

_zm_se_play:
	move.l	param1(sp),a1
	Z_MUSIC	#ZM_SE_PLAY
	rts
