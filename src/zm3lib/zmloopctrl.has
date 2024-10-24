	.xdef	_zm_loop_control

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_loop_control( int );
*-----------------------------------------------------------------------------
_zm_loop_control:
	move.l	param1(sp),d1
	Z_MUSIC	#ZM_LOOP_CONTROL
	rts
