	.xdef	_zm_u220_common

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_u220_common( int port,int cm_id,char *common );
*-----------------------------------------------------------------------------
_zm_u220_common:
	move.l	d3,a2
	movem.l	param1(sp),d1/d3/a1
	Z_MUSIC	#ZM_U220_COMMON
	move.l	a2,d3
	rts
