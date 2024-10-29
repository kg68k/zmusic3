	.xdef	_zm_get_fader_status

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_get_fader_status( void );
*-----------------------------------------------------------------------------
_zm_get_fader_status:
	Z_MUSIC	#ZM_GET_FADER_STATUS
	rts
