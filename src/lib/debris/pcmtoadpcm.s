	.include	zm3lib.mac

_pcm_to_adpcm::
	movea.l	param1(sp),a1
	move.l	param2(sp),d2
	movea.l	param3(sp),a2
	moveq	#1,d1
	Z_MUSIC	#ZM_CONVERT_PCM
	rts
