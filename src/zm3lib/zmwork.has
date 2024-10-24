
	.xdef	_zm_work

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	_zm_work( int track,int offset );
*-----------------------------------------------------------------------------

_zm_work:
	movem.l	param1(sp),d1-d2	*d1=トラック番号,d2=ワークオフセット
	Z_MUSIC	#ZM_GET_PLAY_WORK	*a0=trk n seq_wk_tbl
	moveq.l	#0,d0
	move.b	(a0,d2.l),d0
	rts
