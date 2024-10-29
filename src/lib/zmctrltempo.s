	.xdef	_zm_control_tempo

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_control_tempo( int mode );
*-----------------------------------------------------------------------------
_zm_control_tempo:
	move.l	param1(sp),d1
	Z_MUSIC	#ZM_CONTROL_TEMPO
	rts
