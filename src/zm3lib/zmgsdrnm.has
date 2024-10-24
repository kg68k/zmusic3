	.xdef	_zm_gs_drum_name
	.xdef	_zm_sc55_drum_name

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_gs_drum_name( int port,int size,int mp_id,char *name );
*	int	zm_sc55_drum_name( int port,int size,int mp_id,char *name );
*-----------------------------------------------------------------------------
_zm_gs_drum_name:
_zm_sc55_drum_name:
	move.l	d3,a2
	movem.l	param1(sp),d1-d3/a1
	Z_MUSIC	#ZM_GS_DRUM_NAME
	move.l	a2,d3
	rts
