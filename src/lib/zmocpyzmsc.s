	.xdef	_zm_occupy_zmusic

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_occupy_zmusic( int mode );
*-----------------------------------------------------------------------------
_zm_occupy_zmusic:
	move.l	param1(sp),d1
	Z_MUSIC	#ZM_OCCUPY_ZMUSIC
	rts
