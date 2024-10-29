	.xdef	_zm_u220_part_setup

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_u220_part_setup( int port,int pt_id,char *setup );
*-----------------------------------------------------------------------------
_zm_u220_part_setup:
	move.l	d3,a2
	movem.l	param1(sp),d1/d3/a1
	Z_MUSIC	#ZM_U220_PART_SETUP
	move.l	a2,d3
	rts
