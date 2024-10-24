	.xdef	_zm_current_midi_out

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_current_midi_out( int port );
*-----------------------------------------------------------------------------

_zm_current_midi_out:
	move.l	param1(sp),d1
	Z_MUSIC	#ZM_CURRENT_MIDI_OUT
	rts
