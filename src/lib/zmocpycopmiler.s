	.xdef	_zm_occupy_compiler

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_occupy_compiler( int mode );
*-----------------------------------------------------------------------------
_zm_occupy_compiler:
	move.l	param1(sp),d1
	Z_MUSIC	#ZM_OCCUPY_COMPILER
	rts
