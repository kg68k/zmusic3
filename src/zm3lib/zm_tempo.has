	.xdef	_zm_tempo

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	_zm_tempo( int,int );
*-----------------------------------------------------------------------------

_zm_tempo:
	movem.l	param1(sp),d1-d2		*d1=tempo,d2=mode
	andi.l	#$ffff,d1
	swap	d2
	clr.w	d2
	or.l	d2,d1
	Z_MUSIC	#ZM_TEMPO
	rts
