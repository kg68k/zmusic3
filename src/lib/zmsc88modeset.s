	.xdef	_zm_sc88_mode_set

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_sc88_mode_set( int port,int md_id);
*-----------------------------------------------------------------------------

_zm_sc88_mode_set:
	move.l	d3,a2
	movem.l	param1(sp),d1/d3
	Z_MUSIC	#ZM_SC88_MODE_SET
	move.l	a2,d3
	rts
