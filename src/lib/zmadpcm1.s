	.xdef	_zm_se_adpcm1

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_se_adpcm1(char data_type,char volume,char pan,char frq,
*			int size,short priority,short ch,char *adpcm);
*-----------------------------------------------------------------------------

_zm_se_adpcm1:
	move.l	d4,a2			*save d4
	move.l	param1(sp),d1
	lsl.w	#8,d1
	move.b	param2(sp),d1
	swap	d1
	move.l	param3(sp),d0
	lsl.w	#8,d0
	move.b	param4(sp),d0
	move.w	d0,d1			*d1=type,vol,pan,frq
	move.l	param5(sp),d2		*d2=size
	move.w	param6(sp),d4
	swap	d4
	move.w	param7(sp),d4		*d4=priority_ch
	move.l	param8(sp),a1
	Z_MUSIC	#ZM_SE_ADPCM1
	move.l	a2,d4
	rts
