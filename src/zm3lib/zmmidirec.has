	.xdef	_zm_midi_rec

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_midi_rec( int port );
*-----------------------------------------------------------------------------

_zm_midi_rec:
	move.l	param1(sp),d1
	Z_MUSIC	#ZM_MIDI_REC
	rts
