	.xdef	_zm_exec_subfile

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_exec_subfile( char *filename );
*-----------------------------------------------------------------------------
_zm_exec_subfile:
	move.l	param1(sp),a1
	Z_MUSIC	#ZM_EXEC_SUBFILE
	rts
