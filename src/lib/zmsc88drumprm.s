	.xdef	_zm_sc88_drum_setup
	.xdef	_zm_sc88_drum_parameter

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_sc88_drum_setup( int port,int size,int dr_id,char *param );
*-----------------------------------------------------------------------------

_zm_sc88_drum_setup:
_zm_sc88_drum_parameter:
	move.l	d3,a2
	movem.l	param1(sp),d1-d3/a1
	Z_MUSIC	#ZM_SC88_DRUM_SETUP
	move.l	a2,d3
	rts