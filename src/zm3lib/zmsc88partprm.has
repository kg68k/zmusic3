	.xdef	_zm_sc88_part_parameter
	.xdef	_zm_sc88_part_setup

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_sc88_part_parameter( int port,int size,int pt_id,char *param );
*-----------------------------------------------------------------------------

_zm_sc88_part_parameter:
_zm_sc88_part_setup:
	movem.l	param1(sp),d1-d3/a1
	Z_MUSIC	#ZM_SC88_PART_PARAMETER
	rts
