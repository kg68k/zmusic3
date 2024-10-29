	.include	zm3lib.mac

_zm_se_play::
	move.l	param1(sp),a1
	Z_MUSIC	#ZM_SE_PLAY
	rts
