	.xdef	_zm_u220_timbre

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_u220_timbre( int port,int tm_id,char *timbre );
*-----------------------------------------------------------------------------
_zm_u220_timbre:
	move.l	d3,a2
	movem.l	param1(sp),d1/d3/a1
	Z_MUSIC	#ZM_U220_TIMBRE
	move.l	a2,d3
	rts
