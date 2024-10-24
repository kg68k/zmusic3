	.xdef	_zm_calc_total

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_calc_total( char *zmd,char **errtbl);
*-----------------------------------------------------------------------------
_zm_calc_total:
	movem.l	param1(sp),a1-a2	*a1=zmd addr,a2=result
	Z_MUSIC	#ZM_CALC_TOTAL
	move.l	a0,(a2)		*エラーリストのアドレスを格納してやる
	rts
