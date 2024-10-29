	.xdef	_zm_pcm_read

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	char	*zm_pcm_read( int num,int flag,int type,int orig,char *param);
*-----------------------------------------------------------------------------
_zm_pcm_read:
	moveq.l	#0,d1
	move.w	param1+2(sp),d1
	tst.b	param2+3(sp)
	bpl	@f
	bset.l	#31,d1		*加工有りマーク
@@:
	moveq.l	#0,d2
	move.b	param3+3(sp),d2	*登録タイプ
	lsl.w	#8,d2
	move.b	param4+3(sp),d2	*オリジナルキー
	swap	d2
	Z_MUSIC	#ZM_PCM_READ
	move.l	a0,d0
	rts
