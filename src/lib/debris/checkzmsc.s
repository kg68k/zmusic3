	.include	zm3lib.mac
	.include	iocscall.mac

_check_zmsc::
	suba.l	a1,a1
	IOCS	_B_SUPER	*go into supervisor mode
	move.l	d0,-(sp)
	movea.l	$8c.w,a1
	subq.l	#8,a1
	moveq.l	#-1,d1
	cmpi.l	#'ZmuS',(a1)+	*version ID
	bne	@f
	cmpi.w	#'iC',(a1)+
	bne	@f
	moveq.l	#0,d1
	move.w	(a1)+,d1
@@:
	move.l	(sp)+,a1
	IOCS	_B_SUPER	*back to user mode
	move.l	d1,d0
	rts
