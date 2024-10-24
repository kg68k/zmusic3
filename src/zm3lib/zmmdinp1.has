	.xdef	_zm_midi_inp1

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_midi_inp1( int port,int mode );
*-----------------------------------------------------------------------------

_zm_midi_inp1:
	movem.l	param1(sp),d1-d2
	Z_MUSIC	#ZM_MIDI_INP1
	rts
