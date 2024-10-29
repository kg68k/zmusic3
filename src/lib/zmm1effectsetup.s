	.xdef	_zm_m1_effect_setup

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_m1_effect_setup( char *effect );
*-----------------------------------------------------------------------------
_zm_m1_effect_setup:
	move.l	param1(sp),a1
	Z_MUSIC	#ZM_M1_EFFECT_SETUP
	rts
