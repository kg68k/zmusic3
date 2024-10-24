	.xdef	_zm_gs_part_parameter
	.xdef	_zm_gs_part_setup
	.xdef	_zm_sc55_part_parameter
	.xdef	_zm_sc55_part_setup

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_gs_part_parameter( int port,int size,int pt_id,char *param );
*-----------------------------------------------------------------------------

_zm_gs_part_parameter:
_zm_gs_part_setup:
_zm_sc55_part_parameter:
_zm_sc55_part_setup:
	move.l	d3,a2
	movem.l	param1(sp),d1-d3/a1
	Z_MUSIC	#ZM_GS_PART_PARAMETER
	move.l	a2,d3
	rts
