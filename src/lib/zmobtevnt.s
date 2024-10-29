	.xdef	_zm_obtain_events

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	*zm_obtain_events( int omt,int *event );
*-----------------------------------------------------------------------------
_zm_obtain_events:
	movem.l	param1(sp),d1/a1
	Z_MUSIC	#ZM_OBTAIN_EVENTS
	move.l	a0,d0
	rts
