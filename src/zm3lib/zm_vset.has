	.xdef	_zm_vset

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	_zm_vset( int,int,char*);
*-----------------------------------------------------------------------------

_zm_vset:
	movem.l	param1(sp),d1-d2/a1	*d1=timbre,d2=mode,a1=timbre number
	Z_MUSIC	#ZM_VSET
	rts
