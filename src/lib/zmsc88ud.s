	.xdef	_zm_sc88_user_drum

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_sc88_user_drum( int port,int size,int ud_id,char *param );
*-----------------------------------------------------------------------------

_zm_sc88_user_drum:
	move.l	d3,a2
	movem.l	param1(sp),d1-d3/a1
	Z_MUSIC	#ZM_SC88_USER_DRUM
	move.l	a2,d3
	rts
