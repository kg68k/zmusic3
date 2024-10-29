	.include	zm3lib.mac

_zm_play_zmd::
	movem.l	param1(sp),d2/a1
	Z_MUSIC	#ZM_PLAY_ZMD
	rts
