	.xdef	_zm_set_wave_form2

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_set_wave_form2( int wave,char *data );
*-----------------------------------------------------------------------------
_zm_set_wave_form2:
	movem.l	param1(sp),d1/a1
	Z_MUSIC	#ZM_SET_WAVE_FORM2
	rts
