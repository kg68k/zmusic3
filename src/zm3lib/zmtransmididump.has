	.xdef	_zm_transmit_midi_dump

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_transmit_midi_dump( int port,char *filename );
*-----------------------------------------------------------------------------
_zm_transmit_midi_dump
	movem.l	param1(sp),d1/a1
	Z_MUSIC	#ZM_TRANSMIT_MIDI_DUMP
	rts
