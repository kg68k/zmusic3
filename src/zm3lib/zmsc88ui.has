	.xdef	_zm_sc88_user_inst

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_sc88_user_inst( int port,int size,int ui_id,char *param );
*-----------------------------------------------------------------------------

_zm_sc88_user_inst:
	move.l	d3,a2
	movem.l	param1(sp),d1-d3/a1
	Z_MUSIC	#ZM_SC88_USER_INST
	move.l	a2,d3
	rts
