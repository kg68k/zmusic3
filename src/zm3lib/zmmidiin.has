	.xdef	_zm_current_midi_in

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_current_midi_in( int port );
*-----------------------------------------------------------------------------

_zm_current_midi_in:
	move.l	param1(sp),d1
	Z_MUSIC	#ZM_CURRENT_MIDI_IN
	rts
