	.xdef	_zm_compiler

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	_zm_compiler( int mode,int size,cahr *zms,char **result);
*-----------------------------------------------------------------------------

_zm_compiler:
	movem.l	param1(sp),d1-d2/a1-a2	*d1=mode,d2=size,a1=zms addr,a2=result
	Z_MUSIC	#ZM_COMPILER
	move.l	a0,(a2)		*ZMD/エラーリストのアドレスを格納してやる
	rts
