	.xdef	_zm_m1_part_setup

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_m1_part_setup( char *ptstup );
*-----------------------------------------------------------------------------
_zm_m1_part_setup:
	move.l	param1(sp),a1
	Z_MUSIC	#ZM_M1_PART_SETUP
	rts
