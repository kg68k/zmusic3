	.xdef	_zm_midi_out1

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_midi_out1( int port,char data );
*-----------------------------------------------------------------------------

_zm_midi_out1:
	movem.l	param1(sp),d1-d2
	Z_MUSIC	#ZM_MIDI_OUT1
	rts
