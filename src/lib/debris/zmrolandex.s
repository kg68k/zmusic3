	.include	zm3lib.mac

_zm_roland_exclusive::
	move.l	d3,a2
	movem.l	param1(sp),d1-d3/a1
	Z_MUSIC	#ZM_EXCLUSIVE
	move.l	a2,d3
	rts
