
	.xdef	_zm_check_zmsc
	.xdef	_zm_ver

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	_zm_check_zmsc( void );
*	int	_zm_ver( void );
*-----------------------------------------------------------------------------

_zm_check_zmsc:
_zm_ver:
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
