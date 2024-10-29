
	.xdef	_zm_get_zmlibver

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	_zm_get_zmlibver( void );
*-----------------------------------------------------------------------------

_zm_get_zmlibver:
	move.l	#libver,d0
	rts
