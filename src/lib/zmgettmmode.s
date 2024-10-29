	.xdef	_zm_get_timer_mode

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_get_timer_mode( void );
*-----------------------------------------------------------------------------
_zm_get_timer_mode:
	Z_MUSIC	#ZM_GET_TIMER_MODE
	rts
