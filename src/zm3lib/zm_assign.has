
	.xdef	_zm_assign

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	_zm_assign( int,int );
*-----------------------------------------------------------------------------

_zm_assign:
	move.l	param1(sp),d1		*チャンネル
	move.l	param2(sp),d2		*トラック番号
	Z_MUSIC	#ZM_ASSIGN
	rts
