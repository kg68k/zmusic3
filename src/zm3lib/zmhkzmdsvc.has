	.xdef	_zm_hook_zmd_service

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	char	*zm_hook_zmd_service( int zmd,char *job );
*-----------------------------------------------------------------------------
_zm_hook_zmd_service:
	movem.l	param1(sp),d1/a1
	Z_MUSIC	#ZM_HOOK_ZMD_SERVICE
	tst.l	d0
	beq	@f
	moveq.l	#-1,d0
	rts
@@:
	move.l	a0,d0
	rts
