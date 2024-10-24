	.xdef	_zm_midi_rec_end

	.include	zmid.mac
	.include	zm3lib.mac
	.include	doscall.mac
	.include	iocscall.mac
*-----------------------------------------------------------------------------
*	int	zm_midi_rec_end( int port );
*-----------------------------------------------------------------------------

_zm_midi_rec_end:
	move.l	param1(sp),d1
	Z_MUSIC	#ZM_MIDI_REC_END
	rts
