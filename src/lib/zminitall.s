	.xdef	_zm_init_all

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_init_all( void );
*-----------------------------------------------------------------------------
_zm_init_all:
	Z_MUSIC	#ZM_INIT_ALL
	rts
