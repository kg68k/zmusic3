	.xdef	_zm_sc88_drum_name

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_sc88_drum_name( int port,int size,int mp_id,char *mes );
*-----------------------------------------------------------------------------
_zm_sc88_drum_name:
	move.l	d3,a2
	movem.l	param1(sp),d1-d3/a1
	Z_MUSIC	#ZM_SC88_DRUM_NAME
	move.l	a2,d3
	rts
