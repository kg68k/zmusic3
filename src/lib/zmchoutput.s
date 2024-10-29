	.xdef	_zm_set_ch_output_level

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_set_ch_output_level( char *out );
*-----------------------------------------------------------------------------
_zm_set_ch_output_level:
	move.l	param1(sp),a1
	Z_MUSIC	#ZM_SET_CH_OUTPUT_LEVEL
	rts
