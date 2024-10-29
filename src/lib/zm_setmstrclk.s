	.xdef	_zm_set_master_clock

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	MSTRCLK	*zm_set_master_clock( int side,MSTRCLK *mstrclk );
*-----------------------------------------------------------------------------

_zm_set_master_clock:
	movem.l	param1(sp),d1/a1
	Z_MUSIC	#ZM_SET_MASTER_CLOCK
	move.l	a0,d0
	rts
