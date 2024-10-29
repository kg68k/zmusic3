	.xdef	_zm_get_zmsc_status

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	char	*zm_get_zmsc_status( void );
*-----------------------------------------------------------------------------
_zm_get_zmsc_status:
	Z_MUSIC	#ZM_GET_ZMSC_STATUS
	move.l	a0,d0
	rts
