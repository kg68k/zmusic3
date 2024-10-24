	.nlist
	.include	version.mac

Z_MUSIC	macro	number
	moveq.l	number,d0
	trap	#3
	endm

m_err	macro	ec
	move.l	#$8000_0000+ZM_COMPILER*65536+ec,d0
	bra	m_error_code_exit
	endm

m_warn	macro	wn
	movem.l	d0-d7/a0-a5,-(sp)
	move.l	#$8000_0000+ZM_COMPILER*65536+wn,d0
	bra	m_warn_code_exit
	endm

patch_w	macro	cmd,src,dest
	.iff	(debug.and.2)
	move.w	#cmd+((dest-src-2).and.$ff),src-work(a6)
	.else
	lea	dest-src-2(pc,d0.w),a0
	dc.b	0,0	*for test
	.endif
	endm

patch_w2	macro	cmd,src,dest
	.iff	(debug.and.2)
	move.w	#cmd+((dest-src-2).and.$ff),src
	.else
	lea	dest-src-2(pc,d0.w),a0
	dc.b	0,0	*for test
	.endif
	endm
