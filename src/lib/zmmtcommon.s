	.xdef	_zm_mt32_common

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_mt32_common( int port,int size,int cm_id,char *common );
*-----------------------------------------------------------------------------
_zm_mt32_common:
	move.l	d3,a2
	movem.l	param1(sp),d1-d3/a1
	Z_MUSIC	#ZM_MT32_COMMON
	move.l	a2,d3
	rts
