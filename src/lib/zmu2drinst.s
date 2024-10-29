	.xdef	_zm_u220_drum_inst

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_u220_drum_inst( int port,int dr_id,char *inst );
*-----------------------------------------------------------------------------
_zm_u220_drum_inst:
	move.l	d3,a2
	movem.l	param1(sp),d1/d3/a1
	Z_MUSIC	#ZM_U220_DRUM_INST
	move.l	a2,d3
	rts
