	.xdef	_zm_midi_transmission

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_midi_transmission( int port,int size,char *midi );
*-----------------------------------------------------------------------------

_zm_midi_transmission:
	movem.l	param1(sp),d1-d2/a1
	Z_MUSIC	#ZM_MIDI_TRANSMISSION
	rts
