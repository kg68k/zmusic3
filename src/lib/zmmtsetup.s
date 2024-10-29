	.xdef	_zm_mt32_part_setup

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_mt32_part_setup( int port,int size,int id,char *param );
*-----------------------------------------------------------------------------
_zm_mt32_part_setup:
	move.l	d3,a2
	movem.l	param1(sp),d1-d3/a1
	Z_MUSIC	#ZM_MT32_PART_SETUP
	move.l	a2,d3
	rts
