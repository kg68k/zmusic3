	.xdef	_zm_init

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	_zm_init( int );
*-----------------------------------------------------------------------------

_zm_init:
	move.l	param1(sp),d1
	Z_MUSIC	#ZM_INIT
	rts
