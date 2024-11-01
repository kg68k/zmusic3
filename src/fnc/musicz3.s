*		ZMUSIC.X Version 3.0用 外部関数
*
*		MUSICZ.FNC Version 3.00
*
*	参考文献	MUSIC.FNC	SHARP
*			MUSIC2.FNC	SAN M.S.

	.include	doscall.mac
	.include	iocscall.mac
	.include	zmcall.mac
	.include	z_global.mac
	.include	zmid.mac
	.include	fdef.mac

	*ZM302_L.LZHに入っているMUZUCZ3.FNCはversion 3.02だが
	*ソースコードをアセンブルすると3.02Cになってしまうのでごまかす
	NO_VERSION_SUFFIX: .equ 1
	.include	version.mac

	.cpu	68000

val:		equ	6
dim1:		equ	8
dim2:		equ	10
dim1_data:	equ	10
dim2_data:	equ	16
next_par:	equ	10
no_english:	equ	-1	*英語のメッセージはいらない
ary1_ic:	equ	ary1_i.or.ary1_c

zms_buffer_default_size:	equ	65536
fn_size:	equ	92	*１ファイルネームバッファの大きさ

Z_MUSIC	macro	func		*ドライバへのファンクションコール
	move.l	func,d0
	trap	#3
	endm

information_table:
	dc.l	init
	dc.l	run
	dc.l	end
	dc.l	system
	dc.l	break
	dc.l	ctrl_d
	dc.l	yobi
	dc.l	yobi
	dc.l	token_table
	dc.l	parameter
	dc.l	exec_address
	dcb.b	20,0

token_table:
	dc.b	'm_alloc',0
	dc.b	'm_assign',0
	dc.b	'm_assign2',0
	dc.b	'm_vget',0
	dc.b	'm_vset',0
	dc.b	'm_fmvset',0
	dc.b	'm_tempo',0
	dc.b	'm_trk',0
	dc.b	'm_trk2',0
	dc.b	'm_play',0
	dc.b	'm_stop',0
	dc.b	'm_cont',0
	dc.b	'm_stat',0
	dc.b	'm_init',0
	dc.b	'm_atoi',0
	dc.b	'm_ch',0
	dc.b	'm_pcmset',0
	dc.b	'm_pcmplay',0
	dc.b	'm_rec',0
	dc.b	'm_rstop',0
	dc.b	'm_save',0
	dc.b	'm_trans',0
	dc.b	'm_inp',0
	dc.b	'm_out',0
	dc.b	'm_dirout',0
	dc.b	'm_exc',0
	dc.b	'm_roland',0
	dc.b	'm_total',0
	dc.b	'm_fadeout',0
	dc.b	'm_pcmcnf',0
	dc.b	'm_adpcm_block',0
	dc.b	'm_switch',0
	dc.b	'm_print',0
	dc.b	'm_detect',0
	dc.b	'sc55_init',0
	dc.b	'sc55_v_reserve',0
	dc.b	'sc55_reverb',0
	dc.b	'sc55_chorus',0
	dc.b	'sc55_part_setup',0
	dc.b	'sc55_part_parameter',0
	dc.b	'sc55_drum_setup',0
	dc.b	'sc55_drum_parameter',0
	dc.b	'sc55_print',0
	dc.b	'sc55_display',0
	dc.b	'mt32_init',0
	dc.b	'mt32_p_reserve',0
	dc.b	'mt32_reverb',0
	dc.b	'mt32_part_setup',0
	dc.b	'mt32_drum_setup',0
	dc.b	'mt32_common',0
	dc.b	'mt32_patch',0
	dc.b	'mt32_partial',0
	dc.b	'mt32_print',0
	dc.b	'u220_setup',0
	dc.b	'u220_part_setup',0
	dc.b	'u220_common',0
	dc.b	'u220_timbre',0
	dc.b	'u220_drum_setup',0
	dc.b	'u220_drum_inst',0
	dc.b	'u220_print',0
	dc.b	'm1_midi_ch',0
	dc.b	'm1_part_setup',0
	dc.b	'm1_effect_setup',0
	dc.b	'm1_print',0
	dc.b	'send_to_m1',0
	dc.b	'zmd_play',0
	dc.b	'm_debug',0
	dc.b	'm_count',0
	dc.b	'fm_master',0
	dc.b	'm_mute',0
	dc.b	'm_solo',0
	dc.b	'm_wave_form',0
	dc.b	'adpcm_to_pcm',0
	dc.b	'pcm_to_adpcm',0
	dc.b	'exec_zms',0
	dc.b	'zm_ver',0
*V3系
	dc.b	'zm_detect',0
	dc.b	'zm_switch',0
	dc.b	'zm_work',0
	dc.b	'zm_assign',0
	dc.b	'zm_vget',0
	dc.b	'zm_vset',0
	dc.b	'zm_tempo',0
	dc.b	'zm_play',0
	dc.b	'zm_play_again',0
	dc.b	'zm_play_all',0
	dc.b	'zm_play2',0
	dc.b	'zm_stop',0
	dc.b	'zm_stop_all',0
	dc.b	'zm_cont',0
	dc.b	'zm_cont_all',0
	dc.b	'zm_play_status_all_ch',0
	dc.b	'zm_play_status_all_tr',0
	dc.b	'zm_play_status_ch',0
	dc.b	'zm_play_status_tr',0
	dc.b	'zm_init',0
	dc.b	'zm_atoi',0
	dc.b	'zm_check_zmsc',0
	dc.b	'zm_set_timer_value',0
	dc.b	'zm_set_master_clock',0
	dc.b	'zm_play_zmd',0
	dc.b	'zm_play_zmd_se',0
	dc.b	'zm_se_play',0
	dc.b	'zm_se_adpcm1',0
	dc.b	'zm_se_adpcm2',0
	dc.b	'zm_intercept_play',0
	dc.b	'zm_current_midi_in',0
	dc.b	'zm_current_midi_out',0
	dc.b	'zm_midi_transmission',0
	dc.b	'zm_exclusive',0
	dc.b	'zm_set_eox_wait',0
	dc.b	'zm_midi_inp1',0
	dc.b	'zm_midi_out1',0
	dc.b	'zm_midi_rec',0
	dc.b	'zm_midi_rec_end',0
	dc.b	'zm_gs_reset',0
	dc.b	'zm_gs_partial_reserve',0
	dc.b	'zm_gs_reverb',0
	dc.b	'zm_gs_chorus',0
	dc.b	'zm_gs_part_setup',0
	dc.b	'zm_gs_part_parameter',0
	dc.b	'zm_gs_drum_setup',0
	dc.b	'zm_gs_drum_parameter',0
	dc.b	'zm_gs_drum_name',0
	dc.b	'zm_gs_print',0
	dc.b	'zm_gs_display',0
	dc.b	'zm_gm_system_on',0
	dc.b	'zm_sc88_mode_set',0
	dc.b	'zm_sc88_reverb',0
	dc.b	'zm_sc88_chorus',0
	dc.b	'zm_sc88_delay',0
	dc.b	'zm_sc88_equalizer',0
	dc.b	'zm_sc88_part_setup',0
	dc.b	'zm_sc88_part_parameter',0
	dc.b	'zm_sc88_drum_setup',0
	dc.b	'zm_sc88_drum_parameter',0
	dc.b	'zm_sc88_drum_name',0
	dc.b	'zm_sc88_user_inst',0
	dc.b	'zm_sc88_user_drum',0
	dc.b	'zm_mt32_reset',0
	dc.b	'zm_mt32_partial_reserve',0
	dc.b	'zm_mt32_reverb',0
	dc.b	'zm_mt32_part_setup',0
	dc.b	'zm_mt32_drum',0
	dc.b	'zm_mt32_common',0
	dc.b	'zm_mt32_partial',0
	dc.b	'zm_mt32_patch',0
	dc.b	'zm_mt32_print',0
	dc.b	'zm_u220_setup',0
	dc.b	'zm_u220_part_setup',0
	dc.b	'zm_u220_common',0
	dc.b	'zm_u220_timbre',0
	dc.b	'zm_u220_drums_setup',0
	dc.b	'zm_u220_drums_inst',0
	dc.b	'zm_u220_print',0
	dc.b	'zm_m1_setup',0
	dc.b	'zm_m1_part_setup',0
	dc.b	'zm_m1_effect_setup',0
	dc.b	'zm_m1_print',0
	dc.b	'zm_send_to_m1',0
	dc.b	'zm_pcm_read',0
	dc.b	'zm_pcm_erase',0
	dc.b	'zm_register_zpd',0
	dc.b	'zm_set_zpd_table',0
	dc.b	'zm_exec_subfile',0
	dc.b	'zm_transmit_midi_dump',0
	dc.b	'zm_set_wave_form1',0
	dc.b	'zm_set_wave_form2',0
	dc.b	'zm_obtain_events',0
	dc.b	'zm_loop_control',0
	dc.b	'zm_mask_tracks',0
	dc.b	'zm_mask_all_tracks',0
	dc.b	'zm_solo_track',0
	dc.b	'zm_mask_channels',0
	dc.b	'zm_mask_all_channels',0
	dc.b	'zm_solo_channel',0
	dc.b	'zm_set_ch_output_level',0
	dc.b	'zm_set_tr_output_level',0
	dc.b	'zm_master_fader',0
	dc.b	'zm_get_fader_status',0
	dc.b	'zm_get_play_time',0
	dc.b	'zm_get_1st_comment',0
	dc.b	'zm_get_timer_mode',0
	dc.b	'zm_get_track_table',0
	dc.b	'zm_get_track_table_se',0
	dc.b	'zm_get_play_work',0
	dc.b	'zm_get_play_work_se',0
	dc.b	'zm_get_buffer_information',0
	dc.b	'zm_zmsc_status',0
	dc.b	'zm_calc_total',0
	dc.b	'zm_occupy_zmusic',0
	dc.b	'zm_occupy_compiler',0
	dc.b	'zm_store_error',0
	dc.b	'zm_print_error',0
	dc.b	'zm_get_mem',0
	dc.b	'zm_enlarge_mem',0
	dc.b	'zm_free_mem',0
	dc.b	'zm_free_mem2',0
	dc.b	'zm_exchange_memid',0
	dc.b	'zm_init_all',0
	dc.b	'zm_int_start',0
	dc.b	'zm_int_stop',0
	dc.b	'zm_control_tempo',0
	dc.b	'zm_convert_pcm',0
	dc.b	'zm_exec_zmd',0
	dc.b	0			*end code
	.even

parameter:
	dc.l	m_alloc_p
	dc.l	m_assign_p
	dc.l	m_assign2_p
	dc.l	m_vget_p
	dc.l	m_vset_p
	dc.l	m_fmvset_p
	dc.l	m_tempo_p
	dc.l	m_trk_p
	dc.l	m_trk2_p
	dc.l	m_play_p
	dc.l	m_stop_p
	dc.l	m_cont_p
	dc.l	m_stat_p
	dc.l	m_init_p
	dc.l	m_atoi_p
	dc.l	m_ch_p
	dc.l	m_pcmset_p
	dc.l	m_pcmplay_p
	dc.l	m_rec_p
	dc.l	m_rstop_p
	dc.l	m_save_p
	dc.l	m_trans_p
	dc.l	m_inp_p
	dc.l	m_out_p
	dc.l	m_dirout_p
	dc.l	m_exc_p
	dc.l	m_roland_p
	dc.l	m_total_p
	dc.l	m_fadeout_p
	dc.l	m_pcmcnf_p
	dc.l	m_adpcm_block_p
	dc.l	m_switch_p
	dc.l	m_print_p
	dc.l	m_detect_p
	dc.l	sc55_init_p
	dc.l	sc55_vr_p
	dc.l	sc55_rvb_p
	dc.l	sc55_cho_p
	dc.l	sc55_pst_p
	dc.l	sc55_pst_p
	dc.l	sc55_dpr_p
	dc.l	sc55_dpr_p
	dc.l	sc55_prt_p
	dc.l	sc55_dsp_p
	dc.l	mt32_init_p
	dc.l	mt32_pr_p
	dc.l	mt32_rvb_p
	dc.l	mt32_pst_p
	dc.l	mt32_dst_p
	dc.l	mt32_cmn_p
	dc.l	mt32_ptch_p
	dc.l	mt32_prtl_p
	dc.l	mt32_prt_p
	dc.l	u220_setup_p
	dc.l	u220_pst_p
	dc.l	u220_cmn_p
	dc.l	u220_tmb_p
	dc.l	u220_dst_p
	dc.l	u220_dis_p
	dc.l	u220_prt_p
	dc.l	m1_mdch_p
	dc.l	m1_ptst_p
	dc.l	m1_efct_p
	dc.l	m1_prt_p
	dc.l	send_to_m1_p
	dc.l	zmd_play_p
	dc.l	m_debug_p
	dc.l	m_count_p
	dc.l	fm_master_p
	dc.l	m_mute_p
	dc.l	m_solo_p
	dc.l	m_wave_form_p
	dc.l	adpcm_to_pcm_p
	dc.l	pcm_to_adpcm_p
	dc.l	exec_zms_p
	dc.l	zm_ver_p
*V3系
	dc.l	m_detect_p
	dc.l	m_switch_p
	dc.l	zm_work_p
	dc.l	zm_assign_p
	dc.l	zm_vget_p
	dc.l	zm_vset_p
	dc.l	zm_tempo_p
	dc.l	zm_play_p
	dc.l	zm_play_again_p
	dc.l	zm_play_all_p
	dc.l	zm_play2_p
	dc.l	zm_stop_p
	dc.l	zm_stop_all_p
	dc.l	zm_cont_p
	dc.l	zm_cont_all_p
	dc.l	zm_play_status_all_ch_p
	dc.l	zm_play_status_all_tr_p
	dc.l	zm_play_status_ch_p
	dc.l	zm_play_status_tr_p
	dc.l	zm_init_p
	dc.l	zm_atoi_p
	dc.l	zm_check_zmsc_p
	dc.l	zm_set_timer_value_p
	dc.l	zm_set_master_clock_p
	dc.l	zm_play_zmd_p
	dc.l	zm_play_zmd_se_p
	dc.l	zm_se_play_p
	dc.l	zm_se_adpcm1_p
	dc.l	zm_se_adpcm2_p
	dc.l	zm_intercept_play_p
	dc.l	zm_current_midi_in_p
	dc.l	zm_current_midi_out_p
	dc.l	zm_midi_transmission_p
	dc.l	zm_exclusive_p
	dc.l	zm_set_eox_wait_p
	dc.l	zm_midi_inp1_p
	dc.l	zm_midi_out1_p
	dc.l	zm_midi_rec_p
	dc.l	zm_midi_rec_end_p
	dc.l	zm_gs_reset_p
	dc.l	zm_gs_partial_reserve_p
	dc.l	zm_gs_reverb_p
	dc.l	zm_gs_chorus_p
	dc.l	zm_gs_part_parameter_p
	dc.l	zm_gs_part_parameter_p
	dc.l	zm_gs_drum_setup_p
	dc.l	zm_gs_drum_setup_p
	dc.l	zm_gs_drum_name_p
	dc.l	zm_gs_print_p
	dc.l	zm_gs_display_p
	dc.l	zm_gm_system_on_p
	dc.l	zm_sc88_mode_set_p
	dc.l	zm_sc88_reverb_p
	dc.l	zm_sc88_chorus_p
	dc.l	zm_sc88_delay_p
	dc.l	zm_sc88_equalizer_p
	dc.l	zm_sc88_part_parameter_p
	dc.l	zm_sc88_part_parameter_p
	dc.l	zm_sc88_drum_setup_p
	dc.l	zm_sc88_drum_setup_p
	dc.l	zm_sc88_drum_name_p
	dc.l	zm_sc88_user_inst_p
	dc.l	zm_sc88_user_drum_p
	dc.l	zm_mt32_reset_p
	dc.l	zm_mt32_partial_reserve_p
	dc.l	zm_mt32_reverb_p
	dc.l	zm_mt32_part_setup_p
	dc.l	zm_mt32_drum_p
	dc.l	zm_mt32_common_p
	dc.l	zm_mt32_partial_p
	dc.l	zm_mt32_patch_p
	dc.l	zm_mt32_print_p
	dc.l	zm_u220_setup_p
	dc.l	zm_u220_part_setup_p
	dc.l	zm_u220_common_p
	dc.l	zm_u220_timbre_p
	dc.l	zm_u220_drums_setup_p
	dc.l	zm_u220_drums_inst_p
	dc.l	zm_u220_print_p
	dc.l	zm_m1_setup_p
	dc.l	zm_m1_part_setup_p
	dc.l	zm_m1_effect_setup_p
	dc.l	zm_m1_print_p
	dc.l	zm_send_to_m1_p
	dc.l	zm_pcm_read_p
	dc.l	zm_pcm_erase_p
	dc.l	zm_register_zpd_p
	dc.l	zm_set_zpd_table_p
	dc.l	zm_exec_subfile_p
	dc.l	zm_transmit_midi_dump_p
	dc.l	zm_set_wave_form1_p
	dc.l	zm_set_wave_form2_p
	dc.l	zm_obtain_events_p
	dc.l	zm_loop_control_p
	dc.l	zm_mask_tracks_p
	dc.l	zm_mask_all_tracks_p
	dc.l	zm_solo_track_p
	dc.l	zm_mask_channels_p
	dc.l	zm_mask_all_channels_p
	dc.l	zm_solo_channel_p
	dc.l	zm_set_ch_output_level_p
	dc.l	zm_set_tr_output_level_p
	dc.l	zm_master_fader_p
	dc.l	zm_get_fader_status_p
	dc.l	zm_get_play_time_p
	dc.l	zm_get_1st_comment_p
	dc.l	zm_get_timer_mode_p
	dc.l	zm_get_track_table_p
	dc.l	zm_get_track_table_se_p
	dc.l	zm_get_play_work_p
	dc.l	zm_get_play_work_se_p
	dc.l	zm_get_buffer_information_p
	dc.l	zm_zmsc_status_p
	dc.l	zm_calc_total_p
	dc.l	zm_occupy_zmusic_p
	dc.l	zm_occupy_compiler_p
	dc.l	zm_store_error_p
	dc.l	zm_print_error_p
	dc.l	zm_get_mem_p
	dc.l	zm_enlarge_mem_p
	dc.l	zm_free_mem_p
	dc.l	zm_free_mem2_p
	dc.l	zm_exchange_memid_p
	dc.l	zm_init_all_p
	dc.l	zm_int_start_p
	dc.l	zm_int_stop_p
	dc.l	zm_control_tempo_p
	dc.l	zm_convert_pcm_p
	dc.l	zm_exec_zmd_p

m_alloc_p:	dc.w	int_val,int_val,int_ret
m_assign_p:	dc.w	int_val,int_val,int_ret
m_assign2_p:	dc.w	str_val,int_val,int_ret
m_vget_p:	dc.w	int_val,ary2_c,int_ret
m_vset_p:	dc.w	int_val,ary2_c,int_ret
m_fmvset_p:	dc.w	int_val,ary2_c,int_ret
m_tempo_p:	dc.w	int_omt,int_ret
m_trk_p:	dc.w	int_val,str_val,int_ret
m_trk2_p:	dc.w	str_val,int_val
		dcb.w	7,int_omt
		dc.w	int_ret
m_play_p:	dcb.w	10,int_omt
		dc.w	int_ret
m_stop_p:	dcb.w	10,int_omt
		dc.w	int_ret
m_cont_p:	dcb.w	10,int_omt
		dc.w	int_ret
m_stat_p:	dc.w	int_val,int_ret
m_init_p:	dc.w	int_omt,int_ret
m_atoi_p:	dc.w	int_val,int_ret
m_ch_p:		dc.w	str_val,int_ret
		*	note	filename pitch
m_pcmset_p:	dc.w	int_val,str_val,int_omt
		*	volume	mix     delay
		dc.w	int_omt,int_omt,int_omt
		*	cut offset,size
		dc.w	int_omt
		*	reverse
		dc.w	int_omt
		*	fade point,level
		dc.w	int_omt,int_ret
m_pcmplay_p:	dc.w	int_val,int_val,int_val,int_ret
m_rec_p:	dc.w	int_omt,int_ret
m_rstop_p:	dc.w	int_omt,int_ret
m_save_p:	dc.w	str_val,int_ret
m_trans_p:	dc.w	str_val,int_ret
m_inp_p:	dc.w	char_omt,int_ret
m_out_p:	dc.w	char_val
		dcb.w	9,char_omt
		dc.w	int_ret
m_dirout_p:	dc.w	ary1_c,int_omt,int_ret
m_exc_p:	dc.w	ary1_c,int_omt,int_ret
m_roland_p:	dc.w	char_val,char_val
		dc.w	ary1_c,int_omt,int_ret
m_total_p:	dc.w	int_ret
m_fadeout_p:	dc.w	int_omt,int_ret
m_pcmcnf_p:	dc.w	str_val,int_ret
m_adpcm_block_p:	dc.w	str_val,int_ret
m_switch_p:	dc.w	char_omt,str_omt,int_ret
m_print_p:	dc.w	str_val,int_ret
m_detect_p:	dc.w	char_omt,int_ret
sc55_init_p	dc.w	char_omt,int_ret
sc55_vr_p:	dc.w	ary1_c,char_omt,int_ret
sc55_rvb_p:	dc.w	ary1_c,char_omt,int_ret
sc55_cho_p:	dc.w	ary1_c,char_omt,int_ret
sc55_pst_p:	dc.w	char_val,ary1_c,char_omt,int_ret
sc55_dpr_p:	dc.w	char_val,char_val,ary1_c,char_omt,int_ret
sc55_prt_p:	dc.w	str_val,char_omt,int_ret
sc55_dsp_p:	dc.w	ary1_i,char_omt,int_ret
mt32_init_p	dc.w	char_omt,int_ret
mt32_pr_p:	dc.w	ary1_c,char_omt,int_ret
mt32_rvb_p:	dc.w	ary1_c,char_omt,int_ret
mt32_pst_p:	dc.w	ary1_c,char_omt,int_ret
mt32_dst_p:	dc.w	char_val,ary1_c,char_omt
		dc.w	int_ret
mt32_cmn_p:	dc.w	char_val,str_val,ary1_c
		dc.w	char_omt,int_ret
mt32_ptch_p:	dc.w	char_val,ary1_c,char_omt
		dc.w	int_ret
mt32_prtl_p:	dc.w	char_val,char_val,ary1_c
		dc.w	char_omt,int_ret
mt32_prt_p:	dc.w	str_val,char_omt,int_ret
u220_setup_p:	dc.w	ary1_c,char_omt,int_ret
u220_pst_p:	dc.w	char_val,ary1_c,char_omt
		dc.w	int_ret
u220_cmn_p:	dc.w	ary1_c,char_omt,int_ret
u220_tmb_p:	dc.w	char_val,str_val,ary1_c
		dc.w	char_omt,int_ret
u220_dst_p:	dc.w	ary1_c,char_omt,int_ret
u220_dis_p:	dc.w	char_val,ary1_c
		dc.w	char_omt,int_ret
u220_prt_p:	dc.w	str_val,char_omt,int_ret
m1_mdch_p:	dc.w	ary1_c,int_ret
m1_ptst_p:	dc.w	ary1_c,int_ret
m1_efct_p:	dc.w	ary1_c,int_ret
m1_prt_p:	dc.w	str_val,int_ret
send_to_m1_p:	dc.w	char_omt,int_ret
zmd_play_p:	dc.w	str_val,int_ret
m_debug_p:	dc.w	char_val,int_ret
m_count_p:	dc.w	int_val,int_ret
fm_master_p	dc.w	char_val,int_ret
m_mute_p:	dcb.w	10,int_omt
		dc.w	int_ret
m_solo_p:	dcb.w	10,int_omt
		dc.w	int_ret
m_wave_form_p:	dc.w	int_val,int_val,int_omt
		dc.w	ary1_i,int_ret
adpcm_to_pcm_p:	dc.w	ary1_c,int_omt,ary1_i,int_ret
pcm_to_adpcm_p:	dc.w	ary1_i,int_omt,ary1_c,int_ret
exec_zms_p:	dc.w	str_val,int_ret
zm_ver_p:	dc.w	char_omt,int_ret

zm_work_p:	dc.w	char_val,int_val,int_ret
zm_assign_p:	dc.w	int_val,int_val,int_ret
zm_vget_p:	dc.w	int_val,int_val,ary2_c,int_ret
zm_vset_p:	dc.w	int_val,int_val,ary2_c,int_ret
zm_tempo_p:	dc.w	int_val,int_val,int_ret
zm_play_p:	dc.w	ary1_ic,int_ret
zm_play_again_p:	dc.w	int_ret
zm_play_all_p:	dc.w	int_ret
zm_play2_p:	dc.w	int_omt,int_ret
zm_stop_p:	dc.w	ary1_ic,int_ret
zm_stop_all_p:	dc.w	int_ret
zm_cont_p:	dc.w	ary1_ic,int_ret
zm_cont_all_p:	dc.w	int_ret
zm_play_status_all_ch_p:	dc.w	ary1_ic,int_ret
zm_play_status_all_tr_p:	dc.w	ary1_ic,int_ret
zm_play_status_ch_p:		dc.w	int_val,int_ret
zm_play_status_tr_p:		dc.w	int_val,int_ret
zm_init_p:	dc.w	int_val,int_ret
zm_atoi_p:	dc.w	int_val,int_ret
zm_check_zmsc_p:	dc.w	int_omt,int_ret
zm_set_timer_value_p:	dc.w	int_val,int_val,int_ret
zm_set_master_clock_p:	dc.w	int_val,ary1_ic,int_ret
zm_play_zmd_p:		dc.w	int_val,ary1_ic,int_ret
zm_play_zmd_se_p:	dc.w	ary1_ic,int_ret
zm_se_play_p:		dc.w	ary1_ic,int_ret
zm_se_adpcm1_p:		dc.w	char_val,char_val,char_val,char_val
			dc.w	int_val,int_val,int_val,ary1_ic,int_ret
zm_se_adpcm2_p:		dc.w	char_val,char_val,char_val,char_val
			dc.w	int_val,int_val,int_val,int_ret
zm_intercept_play_p:	dc.w	int_val,int_ret
zm_current_midi_in_p:	dc.w	int_val,int_ret
zm_current_midi_out_p:	dc.w	int_val,int_ret
zm_midi_transmission_p:	dc.w	int_val,int_val,ary1_ic,int_ret
zm_exclusive_p:		dc.w	int_val,int_val,int_val,ary1_ic,int_ret
zm_set_eox_wait_p:	dc.w	int_val,int_val,int_ret
zm_midi_inp1_p:	dc.w	int_val,int_val,int_ret
zm_midi_out1_p:	dc.w	int_val,char_val,int_ret
zm_midi_rec_p:	dc.w	int_val,int_ret
zm_midi_rec_end_p:	dc.w	int_val,int_ret
zm_gs_reset_p:	dc.w	int_val,int_val,int_ret
zm_gs_partial_reserve_p:	dc.w	int_val,int_val,ary1_ic,int_ret
zm_gs_reverb_p:	dc.w	int_val,int_val,int_val,ary1_ic,int_ret
zm_gs_chorus_p:	dc.w	int_val,int_val,int_val,ary1_ic,int_ret
zm_gs_part_parameter_p:	dc.w	int_val,int_val,int_val,ary1_ic,int_ret
zm_gs_drum_setup_p:	dc.w	int_val,int_val,int_val,ary1_ic,int_ret
zm_gs_drum_name_p:	dc.w	int_val,int_val,int_val,str_val,int_ret
zm_gs_print_p:		dc.w	int_val,int_val,int_val,str_val,int_ret
zm_gs_display_p:	dc.w	int_val,int_val,ary1_ic,int_ret
zm_gm_system_on_p:	dc.w	int_val,int_ret
zm_sc88_mode_set_p:	dc.w	int_val,int_val,int_ret
zm_sc88_reverb_p:	dc.w	int_val,int_val,int_val,ary1_ic,int_ret
zm_sc88_chorus_p:	dc.w	int_val,int_val,int_val,ary1_ic,int_ret
zm_sc88_delay_p:	dc.w	int_val,int_val,int_val,ary1_ic,int_ret
zm_sc88_equalizer_p:	dc.w	int_val,int_val,int_val,ary1_ic,int_ret
zm_sc88_part_parameter_p:	dc.w	int_val,int_val,int_val,ary1_ic,int_ret
zm_sc88_drum_setup_p:	dc.w	int_val,int_val,int_val,ary1_ic,int_ret
zm_sc88_drum_name_p:	dc.w	int_val,int_val,int_val,str_val,int_ret
zm_sc88_user_inst_p:	dc.w	int_val,int_val,int_val,ary1_ic,int_ret
zm_sc88_user_drum_p:	dc.w	int_val,int_val,int_val,ary1_ic,int_ret
zm_mt32_reset_p:	dc.w	int_val,int_val,int_ret
zm_mt32_partial_reserve_p:	dc.w	int_val,int_val,ary1_ic,int_ret
zm_mt32_reverb_p:	dc.w	int_val,int_val,int_val,ary1_ic,int_ret
zm_mt32_part_setup_p:	dc.w	int_val,int_val,int_val,ary1_ic,int_ret
zm_mt32_drum_p:		dc.w	int_val,int_val,int_val,ary1_ic,int_ret
zm_mt32_common_p:	dc.w	int_val,int_val,int_val,ary1_ic,int_ret
zm_mt32_partial_p:	dc.w	int_val,int_val,int_val,ary1_ic,int_ret
zm_mt32_patch_p:	dc.w	int_val,int_val,int_val,ary1_ic,int_ret
zm_mt32_print_p:	dc.w	int_val,int_val,int_val,str_val,int_ret
zm_u220_setup_p:	dc.w	int_val,int_val,ary1_ic,int_ret
zm_u220_part_setup_p:	dc.w	int_val,int_val,ary1_ic,int_ret
zm_u220_common_p:	dc.w	int_val,int_val,ary1_ic,int_ret
zm_u220_timbre_p:	dc.w	int_val,int_val,ary1_ic,int_ret
zm_u220_drums_setup_p:	dc.w	int_val,int_val,ary1_ic,int_ret
zm_u220_drums_inst_p:	dc.w	int_val,int_val,ary1_ic,int_ret
zm_u220_print_p:	dc.w	int_val,int_val,int_val,str_val,int_ret
zm_m1_setup_p:	dc.w	ary1_ic,int_ret
zm_m1_part_setup_p:	dc.w	ary1_ic,int_ret
zm_m1_effect_setup_p:	dc.w	ary1_ic,int_ret
zm_m1_print_p:	dc.w	int_val,str_val,int_ret
zm_send_to_m1_p:	dc.w	int_val,int_val,int_ret
zm_pcm_read_p:	dc.w	int_val,int_val,int_val,int_val,ary1_ic,int_ret
zm_pcm_erase_p:	dc.w	int_val,int_ret
zm_register_zpd_p:	dc.w	str_val,int_ret
zm_set_zpd_table_p:	dc.w	int_val,ary1_ic,int_ret
zm_exec_subfile_p:	dc.w	str_val,int_ret
zm_transmit_midi_dump_p:	dc.w	int_val,str_val,int_ret
zm_set_wave_form1_p:	dc.w	int_val,ary1_ic,int_ret
zm_set_wave_form2_p:	dc.w	int_val,ary1_ic,int_ret
zm_obtain_events_p:	dc.w	int_val,ary1_ic,int_ret
zm_loop_control_p:	dc.w	int_val,int_ret
zm_mask_tracks_p:	dc.w	ary1_ic,int_ret
zm_mask_all_tracks_p:	dc.w	int_val,int_ret
zm_solo_track_p:	dc.w	int_val,int_ret
zm_mask_channels_p:	dc.w	ary1_ic,int_ret
zm_mask_all_channels_p:	dc.w	int_val,int_ret
zm_solo_channel_p:	dc.w	int_val,int_ret
zm_set_ch_output_level_p:	dc.w	ary1_ic,int_ret
zm_set_tr_output_level_p:	dc.w	ary1_ic,int_ret
zm_master_fader_p:	dc.w	ary1_ic,int_ret
zm_get_fader_status_p:	dc.w	int_ret
zm_get_play_time_p:	dc.w	int_ret
zm_get_1st_comment_p:	dc.w	int_ret
zm_get_timer_mode_p:	dc.w	int_ret
zm_get_track_table_p:	dc.w	int_ret
zm_get_track_table_se_p:	dc.w	int_ret
zm_get_play_work_p:	dc.w	int_val,int_ret
zm_get_play_work_se_p:	dc.w	int_val,int_ret
zm_get_buffer_information_p:	dc.w	int_ret
zm_zmsc_status_p:	dc.w	int_ret
zm_calc_total_p:	dc.w	ary1_c,int_vp,int_ret
zm_occupy_zmusic_p:	dc.w	int_val,int_ret
zm_occupy_compiler_p:	dc.w	int_val,int_ret
zm_store_error_p:	dc.w	int_val,int_val,int_vp,int_ret
zm_print_error_p:	dc.w	int_val,int_val,int_val,str_val
			dc.w	ary1_ic,str_val,int_val,int_vp,int_ret
zm_get_mem_p:	dc.w	int_val,int_val,int_ret
zm_enlarge_mem_p:	dc.w	int_val,int_val,int_ret
zm_free_mem_p:	dc.w	int_val,int_ret
zm_free_mem2_p:	dc.w	int_val,int_ret
zm_exchange_memid_p:	dc.w	int_val,int_val,int_val,int_val,int_ret
zm_init_all_p:	dc.w	int_ret
zm_int_start_p:	dc.w	int_val,int_ret
zm_int_stop_p:	dc.w	int_val,int_ret
zm_control_tempo_p:	dc.w	int_val,int_ret
zm_convert_pcm_p:	dc.w	int_val,int_val,ary1_ic,ary1_ic,int_ret
zm_exec_zmd_p:	dc.w	int_val,int_val,ary1_c,int_ret

exec_address:
	dc.l	m_alloc
	dc.l	m_assign
	dc.l	m_assign2
	dc.l	m_vget
	dc.l	m_vset
	dc.l	m_fmvset
	dc.l	m_tempo
	dc.l	m_trk
	dc.l	m_trk2
	dc.l	m_play
	dc.l	m_stop
	dc.l	m_cont
	dc.l	m_stat
	dc.l	m_init
	dc.l	m_atoi
	dc.l	m_ch
	dc.l	m_pcmset
	dc.l	m_pcmplay
	dc.l	m_rec
	dc.l	m_rstop
	dc.l	m_save
	dc.l	m_trans
	dc.l	m_inp
	dc.l	m_out
	dc.l	m_dirout
	dc.l	m_exc
	dc.l	m_roland
	dc.l	m_total
	dc.l	m_fadeout
	dc.l	m_pcmcnf
	dc.l	m_adpcm_block
	dc.l	m_switch
	dc.l	m_print
	dc.l	m_detect
	dc.l	sc55_init
	dc.l	sc55_vr
	dc.l	sc55_rvb
	dc.l	sc55_cho
	dc.l	sc55_pst
	dc.l	sc55_pst
	dc.l	sc55_dst
	dc.l	sc55_dst
	dc.l	sc55_prt
	dc.l	sc55_dsp
	dc.l	mt32_init
	dc.l	mt32_pr
	dc.l	mt32_rvb
	dc.l	mt32_pst
	dc.l	mt32_dst
	dc.l	mt32_cmn
	dc.l	mt32_ptch
	dc.l	mt32_prtl
	dc.l	mt32_prt
	dc.l	u220_setup
	dc.l	u220_pst
	dc.l	u220_cmn
	dc.l	u220_tmb
	dc.l	u220_dst
	dc.l	u220_dis
	dc.l	u220_prt
	dc.l	m1_mdch
	dc.l	m1_ptst
	dc.l	m1_effect
	dc.l	m1_prt
	dc.l	send_m1
	dc.l	zmd_play
	dc.l	m_debug
	dc.l	m_count
	dc.l	fm_master
	dc.l	m_mute
	dc.l	m_solo
	dc.l	m_wave_form
	dc.l	adpcm_to_pcm
	dc.l	pcm_to_adpcm
	dc.l	exec_zms
	dc.l	zm_ver
*V3系
	dc.l	m_detect
	dc.l	m_switch
	dc.l	zm_work
	dc.l	zm_assign
	dc.l	zm_vget
	dc.l	zm_vset
	dc.l	zm_tempo
	dc.l	zm_play
	dc.l	zm_play_again
	dc.l	zm_play_all
	dc.l	zm_play2
	dc.l	zm_stop
	dc.l	zm_stop_all
	dc.l	zm_cont
	dc.l	zm_cont_all
	dc.l	zm_play_status_all_ch
	dc.l	zm_play_status_all_tr
	dc.l	zm_play_status_ch
	dc.l	zm_play_status_tr
	dc.l	zm_init
	dc.l	zm_atoi
	dc.l	zm_check_zmsc
	dc.l	zm_set_timer_value
	dc.l	zm_set_master_clock
	dc.l	zm_play_zmd
	dc.l	zm_play_zmd_se
	dc.l	zm_se_play
	dc.l	zm_se_adpcm1
	dc.l	zm_se_adpcm2
	dc.l	zm_intercept_play
	dc.l	zm_current_midi_in
	dc.l	zm_current_midi_out
	dc.l	zm_midi_transmission
	dc.l	zm_exclusive
	dc.l	zm_set_eox_wait
	dc.l	zm_midi_inp1
	dc.l	zm_midi_out1
	dc.l	zm_midi_rec
	dc.l	zm_midi_rec_end
	dc.l	zm_gs_reset
	dc.l	zm_gs_partial_reserve
	dc.l	zm_gs_reverb
	dc.l	zm_gs_chorus
	dc.l	zm_gs_part_parameter
	dc.l	zm_gs_part_parameter
	dc.l	zm_gs_drum_setup
	dc.l	zm_gs_drum_setup
	dc.l	zm_gs_drum_name
	dc.l	zm_gs_print
	dc.l	zm_gs_display
	dc.l	zm_gm_system_on
	dc.l	zm_sc88_mode_set
	dc.l	zm_sc88_reverb
	dc.l	zm_sc88_chorus
	dc.l	zm_sc88_delay
	dc.l	zm_sc88_equalizer
	dc.l	zm_sc88_part_parameter
	dc.l	zm_sc88_part_parameter
	dc.l	zm_sc88_drum_setup
	dc.l	zm_sc88_drum_setup
	dc.l	zm_sc88_drum_name
	dc.l	zm_sc88_user_inst
	dc.l	zm_sc88_user_drum
	dc.l	zm_mt32_reset
	dc.l	zm_mt32_partial_reserve
	dc.l	zm_mt32_reverb
	dc.l	zm_mt32_part_setup
	dc.l	zm_mt32_drum
	dc.l	zm_mt32_common
	dc.l	zm_mt32_partial
	dc.l	zm_mt32_patch
	dc.l	zm_mt32_print
	dc.l	zm_u220_setup
	dc.l	zm_u220_part_setup
	dc.l	zm_u220_common
	dc.l	zm_u220_timbre
	dc.l	zm_u220_drums_setup
	dc.l	zm_u220_drums_inst
	dc.l	zm_u220_print
	dc.l	zm_m1_setup
	dc.l	zm_m1_part_setup
	dc.l	zm_m1_effect_setup
	dc.l	zm_m1_print
	dc.l	zm_send_to_m1
	dc.l	zm_pcm_read
	dc.l	zm_pcm_erase
	dc.l	zm_register_zpd
	dc.l	zm_set_zpd_table
	dc.l	zm_exec_subfile
	dc.l	zm_transmit_midi_dump
	dc.l	zm_set_wave_form1
	dc.l	zm_set_wave_form2
	dc.l	zm_obtain_events
	dc.l	zm_loop_control
	dc.l	zm_mask_tracks
	dc.l	zm_mask_all_tracks
	dc.l	zm_solo_track
	dc.l	zm_mask_channels
	dc.l	zm_mask_all_channels
	dc.l	zm_solo_channel
	dc.l	zm_set_ch_output_level
	dc.l	zm_set_tr_output_level
	dc.l	zm_master_fader
	dc.l	zm_get_fader_status
	dc.l	zm_get_play_time
	dc.l	zm_get_1st_comment
	dc.l	zm_get_timer_mode
	dc.l	zm_get_track_table
	dc.l	zm_get_track_table_se
	dc.l	zm_get_play_work
	dc.l	zm_get_play_work_se
	dc.l	zm_get_buffer_information
	dc.l	zm_zmsc_status
	dc.l	zm_calc_total
	dc.l	zm_occupy_zmusic
	dc.l	zm_occupy_compiler
	dc.l	zm_store_error
	dc.l	zm_print_error
	dc.l	zm_get_mem
	dc.l	zm_enlarge_mem
	dc.l	zm_free_mem
	dc.l	zm_free_mem2
	dc.l	zm_exchange_memid
	dc.l	zm_init_all
	dc.l	zm_int_start
	dc.l	zm_int_stop
	dc.l	zm_control_tempo
	dc.l	zm_convert_pcm
	dc.l	zm_exec_zmd

init:
reglist	reg	d0-d1/a0/a6
	movem.l	reglist,-(sp)
	lea	work(pc),a6
	clr.b	out_flg-work(a6)	*ファイル書き出しスイッチクリア

	bsr	chk_drv			*ドライバ常駐チェック
	bpl	@f
	clr.b	zm3_flg-work(a6)	*未登録
	movem.l	(sp)+,reglist
	rts
@@:
	st.b	zm3_flg-work(a6)	*登録
	bsr	run
	movem.l	(sp)+,reglist
	rts

run:
reglist	reg	d0-d1/a0-a1/a6
	movem.l	reglist,-(sp)
	lea	work(pc),a6

	clr.l	n_of_err-work(a6)	*コンパイル時に発生したエラーの数の初期化
	clr.l	zmd_addr-work(a6)	*初期化
					*ZMSバッファ確保
	move.l	zms_buffer_addr(pc),d0
	beq	@f
	clr.l	zms_buffer_addr-work(a6)
	move.l	d0,-(sp)
	DOS	_MFREE			*昔のバッファを解放
	addq.w	#4,sp
@@:
	move.l	#zms_buffer_default_size,-(sp)
	DOS	_MALLOC
	addq.w	#4,sp
	tst.l	d0			*確保失敗
	bmi	@f
	move.l	d0,zms_buffer_addr-work(a6)
	move.l	#zms_buffer_default_size,zms_buffer_size-work(a6)
	clr.l	zms_buffer_ptr-work(a6)
@@:
	clr.b	compiler_flg-work(a6)
	tst.b	zm3_flg-work(a6)
	beq	@f
	suba.l	a1,a1			*演奏停止
	Z_MUSIC	#ZM_STOP
	moveq.l	#ZM_COMPILER,d1
	lea	-1.w,a1			*detect mode
	Z_MUSIC	#ZM_HOOK_FNC_SERVICE
	move.l	a0,d0
	sne	compiler_flg-work(a6)
@@:
	movem.l	(sp)+,reglist
	rts

chk_drv:			*デバイス名のcheck
	* > eq=no error
	* > mi=error
	clr.l	-(sp)
	DOS	_SUPER
	addq.w	#4,sp
	move.l	d0,-(sp)

	moveq.l	#-1,d1
	move.l	$8c.w,a0
	subq.w	#8,a0
	cmpi.l	#'ZmuS',(a0)+
	bne	@f
	cmpi.w	#'iC',(a0)+
	bne	@f
	move.w	(a0),zm_ver_buf
	cmpi.b	#$30,(a0)
	bcs	@f		*version error
	moveq.l	#0,d1
@@:
	DOS	_SUPER		*見付けた
	addq.w	#4,sp
	move.l	d1,d0
	rts

ctrl_d:
reglist	reg	d0/a0-a1
	movem.l	reglist,-(sp)
	move.b	zm3_flg(pc),d0	*d0=dummy
	beq	@f
	suba.l	a1,a1
	Z_MUSIC	#ZM_STOP
@@:
	movem.l	(sp)+,reglist
end:
break:
system:
yobi:
	rts

m_alloc:			*V2 トラックバッファの確保(dummy)
	bra	ok_0

m_assign:			*V2 チャンネルアサイン
	bsr	check_zm3
	move.w	#'(a',d0
	bsr	do_wrt_zms_w
	move.l	par1+val(sp),d0	*ch
	bsr	wrt_num
	moveq	#',',d0
	bsr	do_wrt_zms_b
	move.l	par2+val(sp),d0	*tr
	bsr	wrt_num
	moveq	#')',d0
	bsr	do_wrt_zms_b
	bsr	compile_zms
	bra	ok_0

m_assign2:			*V2 文字列チャンネルアサイン
	bsr	check_zm3
	move.w	#'(a',d0
	bsr	do_wrt_zms_w
	move.l	par1+val(sp),a0
	bsr	wrt_str
	moveq	#',',d0
	bsr	do_wrt_zms_b
	move.l	par2+val(sp),d0
	bsr	wrt_num
	moveq	#')',d0
	bsr	do_wrt_zms_b
	bsr	compile_zms
	bra	ok_0

m_vget:				*V2 音色取りだし
	bsr	check_zm3
	move.l	par1+val(sp),d1	*sound number
	movea.l	par2+val(sp),a1	*配列
	cmpi.w	#4,dim1(a1)
	bne	mz_illegal_arry	*配列の次元が違う
	cmpi.w	#10,dim2(a1)
	bne	mz_illegal_arry	*配列の次元が違う
	lea	dim2_data(a1),a1
	moveq.l	#0,d2		*normal
	Z_MUSIC	#ZM_VGET
	tst.l	d0
	bne	error
	bra	ok_0

m_vset:				*V2 FM音源音色登録
	bsr	check_zm3
	move.w	#'(v',d0
	bsr	do_wrt_zms_w
	move.l	par1+val(sp),d0
	bsr	wrt_num
	move.l	#',0'*65536+$0d0a,d0
	bsr	do_wrt_zms_l
	move.l	par2+val(sp),a1
	cmpi.w	#4,dim1(a1)
	bne	mz_illegal_arry	*配列の次元が違う
	cmpi.w	#10,dim2(a1)
	bne	mz_illegal_arry	*配列の次元が違う
	lea	dim2_data(a1),a1
	lea	rem1(pc),a0
	bsr	wrt_str
	moveq.l	#4,d1
mvslp00:
	cmpi.b	#3,d1
	bne	non_rem2
	lea	rem2(pc),a0
	bsr	wrt_str
non_rem2:
	moveq	#9,d0
	bsr	do_wrt_zms_b
	moveq.l	#11-1,d2
mvslp01:
	moveq.l	#0,d0
	move.b	(a1)+,d0
	bsr	wrt_num2
	moveq	#',',d0
	bsr	do_wrt_zms_b
	dbra	d2,mvslp01
	tst.w	d1
	bne	@f
	move.l	#') '*65536+$0d0a,d0	*ライトの場合は')'
	bsr	do_wrt_zms_l
	bra	1f
@@:
	move.w	#$0d0a,d0
	bsr	do_wrt_zms_w
1:
	dbra	d1,mvslp00
	bsr	compile_zms
	bra	ok_0

m_fmvset:			*V2 ＦＭ音源音色登録その2
	bsr	check_zm3
	lea	rem2(pc),a0
	moveq	#9,d0
	bsr	do_wrt_zms_b
	lea	fmvset(pc),a0	*cmd header
	bsr	wrt_str
	move.l	par1+val(sp),d0
	bsr	wrt_num		*tone number
	moveq	#'{',d0
	bsr	do_wrt_zms_b
	move.l	par2+val(sp),a1
	cmpi.w	#4,dim1(a1)
	bne	mz_illegal_arry
	cmpi.w	#10,dim2(a1)
	bne	mz_illegal_arry
	lea	dim2_data(a1),a1
	moveq.l	#4,d1
fmvslp00:
	tst.b	d1
	bne	non_rem3
	lea	rem3(pc),a0
	bsr	wrt_str
non_rem3:
	cmpi.b	#4,d1
	beq	only1tab
	moveq	#9,d0
	bsr	do_wrt_zms_b
only1tab:
	moveq	#9,d0
	bsr	do_wrt_zms_b
_11dt:
	moveq.l	#11-1,d2
fmvslp01:
	moveq.l	#0,d0
	move.b	(a1)+,d0
	bsr	wrt_num2
	moveq	#',',d0
	bsr	do_wrt_zms_b
	dbra	d2,fmvslp01
	tst.w	d1
	bne	@f
	move.l	#') '*65536+$0d0a,d0	*ライトの場合は')'
	bsr	do_wrt_zms_l
	bra	1f
@@:
	move.w	#$0d0a,d0
	bsr	do_wrt_zms_w
1:
	dbra	d1,fmvslp00
	bsr	compile_zms
	bra	ok_0

m_tempo:			*V2 テンポ
	bsr	check_zm3
	tst.w	par1(sp)
	bmi	@f		*ask mode
	move.w	#'(o',d0
	bsr	do_wrt_zms_w
	move.l	par1+val(sp),d0	*tempo value
	bsr	wrt_num
	moveq	#')',d0
	bsr	do_wrt_zms_b
	bsr	compile_zms
	bra	ok_0
@@:				*ask mode
	moveq.l	#-1,d1
	Z_MUSIC	#ZM_TEMPO
	bra	ok_ret		*戻り値有りのケース

m_trk:				*V2トラック書き込み
	bsr	check_zm3
	move.w	#'(t',d0
	bsr	do_wrt_zms_w
	move.l	par1+val(sp),d0	*trk num
	bsr	wrt_num
	moveq	#')',d0
	bsr	do_wrt_zms_b
	move.l	par2+val(sp),a0	*mml str addres
	bsr	wrt_str
	bsr	compile_zms
	bra	ok_0

m_trk2:				*V2 トラック書き込み #2
	bsr	check_zm3
	move.w	#'(t',d0
	bsr	do_wrt_zms_w
	lea.l	par2(sp),a3
	moveq.l	#8-1,d3
mt2_lp:
	tst.w	(a3)		*省略チェック
	bmi	end_mt2l
	addq.w	#val,a3
	cmpi.b	#8-1,d3
	beq	@f
	moveq	#',',d0		*','はラストはいらない
@@:
	bsr	do_wrt_zms_b
	move.l	(a3)+,d0
	bsr	wrt_num
	dbra	d3,mt2_lp
end_mt2l:
	moveq	#')',d0
	bsr	do_wrt_zms_b
	move.l	par1+val(sp),a0	*mml str addres
	bsr	wrt_str
	bsr	compile_zms
	bra	ok_0

m_play:				*V2 演奏開始
	bsr	check_zm3
	move.w	#'(p',d0
	bsr	do_wrt_zms_w
	move.l	sp,a0
	bsr	wrt_trks	*トラック番号を書く
	moveq.l	#')',d0
	bsr	do_wrt_zms_b
	bsr	compile_zms
	bsr	go_play		*実際に演奏開始
	bne	error
	bra	ok_0

m_stop:				*V2 演奏停止
	bsr	check_zm3
	lea	par1(sp),a0
	bsr	get_trk_seq
	Z_MUSIC	#ZM_STOP
	tst.l	d0
	bne	error
	bra	ok_0

m_cont:				*V2 演奏再開
	bsr	check_zm3
	lea	par1(sp),a0
	bsr	get_trk_seq
	Z_MUSIC	#ZM_CONT
	tst.l	d0
	bne	error
	bra	ok_0

get_trk_seq:			*トラック番号パラメータ作成
	* < a0.l=par1(sp)
	* > a1.l=track numbers{tr.w,tr.w,...-1(.w)}
reglist	reg	d0-d1/d5/a0
	movem.l	reglist,-(sp)
	moveq.l	#10-1,d5	*basicのパラメータマックスが10個のため
	lea	trk_cmd(pc),a1
bps_lp:
	tst.w	(a0)		*省略?
	bmi	@f
	move.l	val(a0),d0	*get trk number
	subq.l	#1,d0
	cmpi.l	#tr_max-1,d0
	bhi	@f
	move.w	d0,(a1)+
@@:
	add.w	#next_par,a0		*次へ
	dbra	d5,bps_lp
	move.w	#-1,(a1)+	*endcode
	lea	trk_cmd(pc),a1	*戻り値
	movem.l	(sp)+,reglist
	rts

m_stat:				*V2 演奏状態検査
	bsr	check_zm3
	move.l	par1+val(sp),d2
	subq.b	#1,d2		*track number
	moveq.l	#3,d1		*track check mode
	Z_MUSIC	#ZM_PLAY_STATUS
	bra	ok_ret

m_init:				*V2 初期化
	bsr	check_zm3	*ドライバがアクティブかどうかチェック
	move.w	#'(i',d0
	bsr	do_wrt_zms_w
	tst.w	par1(sp)
	bmi	@f
	move.l	par1+val(sp),d0
	bsr	wrt_num
@@:
	moveq.l	#')',d0
	bsr	do_wrt_zms_b
	bsr	compile_zms
	bra	ok_0

m_atoi:					*V2トラックアドレス取得
	bsr	check_zm3
	move.l	par1+val(sp),d1		*track number
	Z_MUSIC	#ZM_ATOI
	move.l	a0,d0
	beq	error
	bra	ok_ret

m_ch:				*V2 ベースチャンネル切り換え
	bsr	check_zm3
	move.w	#'(b',d0
	bsr	do_wrt_zms_w
	move.l	par1+val(sp),a0
	moveq.l	#0,d1
	move.b	(a0)+,d0
	bsr	mk_capital
	cmpi.b	#'M',d0
	bne	@f
	addq.b	#1,d1		*midiならd1=1
@@:
	move.l	d1,d0		*fmならd1=0
	bsr	wrt_num
	moveq	#')',d0
	bsr	do_wrt_zms_b
	bsr	compile_zms
	bra	ok_0

m_pcmset:			*V2 ADPCMデータリード
	bsr	check_zm3
	move.l	par1+val(sp),d0	*set note number
	bsr	wrt_num
	moveq	#'=',d0
	bsr	do_wrt_zms_b
	move.l	par2+val(sp),a0
	bsr	wrt_str		*write filename
	tst.w	par3(sp)
	bmi	@f
	move.w	#',p',d0	*pitch
	bsr	do_wrt_zms_w
	move.l	par3+val(sp),d0
	bsr	wrt_num
@@:
	tst.w	par4(sp)
	bmi	@f
	move.w	#',v',d0	*vol
	bsr	do_wrt_zms_w
	move.l	par4+val(sp),d0
	bsr	wrt_num
@@:
	tst.w	par7(sp)
	bmi	@f
	move.w	#',c',d0	*cut header
	bsr	do_wrt_zms_w
	move.l	par7+val(sp),d0
	move.l	d0,d1
	clr.w	d0
	swap	d0
	bsr	wrt_num		*write offset
	moveq	#',',d0
	bsr	do_wrt_zms_b
	move.w	d1,d0
	bsr	wrt_num		*write cut size
@@:
	tst.w	par8(sp)
	bmi	@f
	move.l	par8+val(sp),d0
	beq	@f
	move.w	#',r',d0	*reverse
	bsr	do_wrt_zms_w
@@:
	tst.w	par9(sp)
	bmi	@f
	move.w	#',f',d0	*fade in/out header
	bsr	do_wrt_zms_w
	move.l	par9+val(sp),d0
	move.l	d0,d1
	clr.w	d0
	swap	d0
	tst.w	d1		*check mode
	bpl	wrt_fp
	moveq	#'-',d0		*case:fade in
	bsr	do_wrt_zms_b
wrt_fp:
	bsr	wrt_num		*fade point
	moveq	#',',d0
	bsr	do_wrt_zms_b
	moveq.l	#0,d0
	move.b	d1,d0
	bsr	wrt_num		*fade level
@@:
	tst.w	par5(sp)
	bmi	@f
	move.w	#',m',d0	*mix header
	bsr	do_wrt_zms_w
	move.l	par5+val(sp),d0
	bsr	wrt_num
	tst.w	par6(sp)
	bmi	@f
	move.w	#',d',d0	*delay header
	bsr	do_wrt_zms_w
	move.l	par6+val(sp),d0
	bsr	wrt_num
	bsr	compile_zms
	bra	ok_0

m_pcmplay:				*V2 adpcm dataの演奏
	bsr	check_zm3
	move.l	par1+val(sp),d2		*get note
	move.l	par2+val(sp),d0		*get pan
	move.l	#$ff40_0000,d1		*-1:ADPCM,64:vol
	move.w	par3+val+2(sp),d1	*get frq
	lsl.w	#8,d0
	or.w	d0,d1
	move.l	#$e0,d4			*0:優先度,$e0:空きチャンネルスキャン
	Z_MUSIC	#ZM_SE_ADPCM2
	bra	ok_0

m_rec:				*V2 MIDIデータ録音
	bsr	check_zm3
	moveq	#-1,d1
	tst.w	par1(sp)
	bmi	@f
	move.l	par1+val(sp),d1
@@:
	Z_MUSIC	#ZM_MIDI_REC
	tst.l	d0
	bne	error
	bra	ok_0

m_rstop:			*V2 MIDIデータ録音停止
	bsr	check_zm3
	moveq.l	#-1,d1
	tst.w	par1(sp)
	bmi	@f
	move.l	par1+val(sp),d1
@@:
	Z_MUSIC	#ZM_MIDI_REC_END
	tst.l	d0
	bne	error
	bra	ok_0

m_save:				*V2 MIDIデータセーブ(Dummy)
	bra	ok_0

m_trans:			*V2 MIDIデータファイルの送信
	bsr	check_zm3
	lea	midi_dump(pc),a0	*command name
	bsr	wrt_str
	move.l	par1+val(sp),a0		*filename
	bsr	wrt_str
	bsr	compile_zms
	bra	ok_0

m_inp:				*ＭＩＤＩデータ入力
	bsr	check_zm3
	moveq.l	#0,d2
	tst.w	par1(sp)		*省略?
	bmi	@f
	move.l	par1+val(sp),d2
@@:
	Z_MUSIC	#ZM_MIDI_INP1
	bra	ok_ret

m_out:				*V2 MIDIデータ出力
	bsr	check_zm3
	lea	midi_data(pc),a0
	bsr	wrt_str
	lea	par1(sp),a0
	moveq.l	#10-1,d1
_moutlp:
	tst.w	(a0)		*省略?
	bmi	@f
	move.l	val(a0),d0
	bsr	wrt_num3	*16進数書き込み
	moveq	#',',d0
	bsr	do_wrt_zms_b
@@:
	lea	next_par(a0),a0
	dbra	d1,_moutlp
	moveq.l	#'}',d0
	bsr	do_wrt_zms_b
	bsr	compile_zms
	bra	ok_0

m_dirout:			*V2 MIDIデータ送信
	bsr	check_zm3
	movea.l	par1+val(sp),a1	*配列
	moveq.l	#0,d2
	move.w	dim1(a1),d2	*添字取りだし
	addq.l	#1,d2		*サイズに直す
	lea	dim1_data(a1),a1
	tst.w	par2(sp)
	bmi	@f
	move.l	par2+val(sp),d1		*get size
	beq	mz_illegal_parameter
	cmp.l	d2,d1
	bhi	mz_illegal_parameter	*サイズが添え字より大きい!?
	move.l	d1,d2
@@:
	lea	midi_data(pc),a0
kyoutsu:
	bsr	wrt_str
	moveq	#9,d0
	bsr	do_wrt_zms_b
kyoutsu2:
	moveq.l	#0,d1		*一行のデータ数カウンタ
mdirlp00:
	moveq.l	#0,d0
	move.b	(a1)+,d0
	bsr	wrt_num3	*hex
	addq.b	#1,d1
	cmpi.b	#16,d1		*16データごと改行
	bne	1f
	moveq.l	#0,d1
	move.l	#$0d0a0909,d0
	bsr	do_wrt_zms_l
	bra	@f
1:				*,で区切る
	cmp.l	#1,d2		*最後?
	beq	2f
	moveq	#',',d0
	bsr	do_wrt_zms_b
	bra	@f
2:				*ラスト
	moveq	#'}',d0
	bsr	do_wrt_zms_b
@@:
	subq.l	#1,d2
	bne	mdirlp00
	bsr	compile_zms
	bra	ok_0

m_exc:				*V2 エクスクルーシブ転送
	bsr	check_zm3
	movea.l	par1+val(sp),a1	*配列
	moveq.l	#0,d2
	move.w	8(a1),d2	*d2=添え字の大きさ
	addq.l	#1,d2		*サイズに直す
	lea	10(a1),a1
	tst.w	par2(sp)
	bmi	@f			*省略のケース
	move.l	par2+val(sp),d1		*get size
	beq	mz_illegal_parameter
	cmp.l	d2,d1
	bhi	mz_illegal_parameter	*サイズが添え字より大きい!?
	move.l	d1,d2
@@:
	lea	exclusive(pc),a0
	bra	kyoutsu		*後はdiroutと共通

m_roland:			*V2 ROLANDエクスクルーシブ転送
	bsr	check_zm3
	move.l	par1+val(sp),d3	*dev id
	lsl.w	#8,d3
	move.l	par2+val(sp),d1	*model id
	move.b	d1,d3
	movea.l	par3+val(sp),a1	*配列
	moveq.l	#0,d2
	move.w	dim1(a1),d2	*d2=添え字の大きさ
	addq.l	#1,d2		*サイズに直す
	lea	dim1_data(a1),a1	*a1=data address
	tst.w	par4(sp)
	bmi	@f		*省略のケース
	move.l	par4+val(sp),d1	*get size
	beq	mz_illegal_parameter	*illegal parameter
	cmp.l	d2,d1
	bhi	mz_illegal_parameter	*サイズが添え字より大きい!?
	move.l	d1,d2
@@:
	lea	roland(pc),a0
	bsr	wrt_str
	moveq.l	#0,d0
	ror.w	#8,d3
	move.b	d3,d0
	bsr	wrt_num3	*dev
	moveq	#',',d0
	bsr	do_wrt_zms_b
	lsr.w	#8,d3
	move.b	d3,d0
	bsr	wrt_num3	*model
	move.l	#' {'*65536+$0d0a,d0
	bsr	do_wrt_zms_l
	move.w	#$0909,d0
	bsr	do_wrt_zms_w
	bra	kyoutsu2	*後はdiroutと共通

m_total:			*V2 ステップタイムのトータル値表示(Dummy)
	bra	ok_0

m_fadeout:			*フェードアウト
	bsr	check_zm3
	tst.w	par1(sp)		*省略?
	bpl	@f
	move.w	#$00_80,d2		*end=$00,start=$80
	moveq.l	#fader_dflt_spd,d1	*deafult speed
	bra	1f
@@:
	move.l	par1+val(sp),d1
	move.w	#$00_80,d2		*end=$00,start=$80
	tst.l	d1
	bne	@f
	move.w	#$80_80,d2
	bra	1f
@@:
	bpl	@f
	neg.l	d1
	move.w	#$80_00,d2		*end=$80,start=$00
@@:
	cmpi.l	#255,d1			*check speed
	bhi	mz_illegal_fader_speed
1:
	lea	fdr_cmd(pc),a1		*param. tbl
	move.l	a1,a0
	move.w	#-1,(a0)+		*all
	move.b	#%0000_0111,(a0)+
	move.b	d1,(a0)+
	clr.b	(a0)+
	move.b	d2,(a0)+		*start level
	rol.w	#8,d2			*end level
	move.b	d2,(a0)+
	Z_MUSIC	#ZM_MASTER_FADER
	tst.l	d0
	bne	error
	bra	ok_0

m_pcmcnf:			*V2 ADPCMコンフィギュレーションファイルセット
	bsr	check_zm3
	lea	adpcm_list(pc),a0
	bsr	wrt_str
	move.l	par1+val(sp),a0
	tst.b	(a0)
	beq	mz_nul_string_error
	bsr	wrt_str
	bsr	compile_zms
	bra	ok_0

m_adpcm_block:			*V2 ブロックデータの読み込み
	bsr	check_zm3
	lea	adpcm_block_(pc),a0
	bsr	wrt_str
	move.l	par1+val(sp),a0
	tst.b	(a0)
	beq	mz_nul_string_error
	bsr	wrt_str
	bsr	compile_zms
	bra	ok_0

m_detect:			*V2 コンパイルモード
	bsr	check_zm3
	clr.b	detect_mode
	tst.w	par1(sp)
	bmi	ok_0
	tst.l	par1+val(sp)
	sne	detect_mode
	bra	ok_0

m_switch:			*V2 ファイル書き出しモード
	bsr	check_zm3
	tst.w	par1(sp)	*省略時
	bmi	@f
	move.l	par1+val(sp),d0
	sne	out_flg-work(a6)	*ファイル出力フラグ
@@:
	tst.w	par2(sp)
	bmi	1f		*ファイルネーム省略時はデフォルトを生成
	move.l	par2+val(sp),a0
	bra	@f
1:
	lea	dflt_fn(pc),a0
@@:
	lea	gene_fn(pc),a1
	moveq.l	#0,d1
gfnlp:
	move.b	(a0)+,d0
	cmpi.b	#'.',d0
	bne	@f
	st	d1
@@:
	move.b	d0,(a1)+
	cmpi.b	#' ',d0
	bhi	gfnlp		*終了
	subq.w	#1,a1
	tst.b	d1
	bne	ok_0
	move.b	#'.',(a1)+	*拡張子をセット
	move.b	#'Z',(a1)+
	move.b	#'M',(a1)+
	move.b	#'S',(a1)+
	clr.b	(a1)
	bra	ok_0

m_print:			*文字列を表示する
	bsr	check_zm3
	lea	m_prt_(pc),a0
	bsr	wrt_str
	move.w	#' "',d0
	bsr	do_wrt_zms_w
	move.l	par1+val(sp),a0
	tst.b	(a0)
	beq	mz_nul_string_error	*length=0は駄目
	bsr	wrt_str
	moveq	#'"',d0
	bsr	do_wrt_zms_b
	bsr	compile_zms
	bra	ok_0

sc55_init:			*V2 SC55初期化
	bsr	check_zm3
	moveq.l	#-1,d3
	tst.w	par1(sp)
	bmi	@f
	move.l	par1+val(sp),d3	*get dev id
@@:
	lea	sc55_init_(pc),a0
	bsr	wrt_str
	tst.l	d3
	bmi	@f
	moveq	#' ',d0
	bsr	do_wrt_zms_b
	move.l	d3,d0
	bsr	wrt_num3	*dev id
@@:
	bsr	compile_zms
	bra	ok_0

sc55_vr:			*V2 sc55 voice resereve
	bsr	check_zm3
	movea.l	par1+val(sp),a1
	cmpi.w	#16-1,dim1(a1)
	bne	mz_illegal_arry		*配列のサイズが違う
	lea	dim1_data(a1),a1	*a1=data pointer
	moveq.l	#-1,d3
	tst.w	par2(sp)
	bmi	@f
	move.l	par2+val(sp),d3	*get dev id
@@:
	lea	sc55_vr_(pc),a0
	bsr	wrt_str
	move.l	d3,d0
	bmi	@f
	bsr	wrt_num3	*dev id
@@:
	move.w	#' {',d0
	bsr	do_wrt_zms_w
	moveq.l	#16-1,d1
@@:
	moveq.l	#0,d0
	move.b	(a1)+,d0
	bsr	wrt_num
	tst.w	d1
	bne	1f
	moveq.l	#'}',d0
	bsr	do_wrt_zms_b
	bra	2f
1:				*,で区切る
	moveq	#',',d0
	bsr	do_wrt_zms_b
2:
	dbra	d1,@b
	bsr	compile_zms
	bra	ok_0

sc55_rvb:			*V2 sc55 reverb parameter
	bsr	check_zm3
	movea.l	par1+val(sp),a1
	cmpi.w	#7-1,dim1(a1)
	bhi	mz_illegal_arry		*配列のサイズが違う
	move.w	dim1(a1),d1		*d2=添え字の大きさ(=dbra counter)
	lea	dim1_data(a1),a1	*a1=data pointer
	moveq.l	#-1,d3
	tst.w	par2(sp)
	bmi	@f
	move.l	par2+val(sp),d3	*get dev id
@@:
	lea	sc55_rvb_(pc),a0
	bsr	wrt_str
	move.l	d3,d0
	bmi	@f
	bsr	wrt_num3	*dev id
@@:
	move.w	#' {',d0
	bsr	do_wrt_zms_w
@@:
	moveq.l	#0,d0
	move.b	(a1)+,d0
	bsr	wrt_num
	tst.w	d1
	bne	1f
	moveq.l	#'}',d0
	bsr	do_wrt_zms_b
	bra	2f
1:				*,で区切る
	moveq	#',',d0
	bsr	do_wrt_zms_b
2:
	dbra	d1,@b
	bsr	compile_zms
	bra	ok_0

sc55_cho:			*V2 sc55 chorus parameter
	bsr	check_zm3
	movea.l	par1+val(sp),a1
	cmpi.w	#8-1,dim1(a1)
	bhi	mz_illegal_arry		*配列のサイズが違う
	move.w	dim1(a1),d1		*d2=添え字の大きさ(=dbra counter)
	lea	dim1_data(a1),a1	*a1=data pointer
	moveq.l	#-1,d3
	tst.w	par2(sp)
	bmi	@f
	move.l	par2+val(sp),d3		*get dev id
@@:
	lea	sc55_cho_(pc),a0
	bsr	wrt_str
	move.l	d3,d0
	bmi	@f
	bsr	wrt_num3	*dev id
@@:
	move.w	#' {',d0
	bsr	do_wrt_zms_w
@@:
	moveq.l	#0,d0
	move.b	(a1)+,d0
	bsr	wrt_num
	tst.w	d1
	bne	1f
	moveq.l	#'}',d0
	bsr	do_wrt_zms_b
	bra	2f
1:				*,で区切る
	moveq	#',',d0
	bsr	do_wrt_zms_b
2:
	dbra	d1,@b
	bsr	compile_zms
	bra	ok_0

sc55_pst:			*V2 sc55 part parameter
	bsr	check_zm3
	move.l	par1+val(sp),d1		*get part number
	cmpi.l	#16,d1
	bhi	mz_illegal_parameter	*16以上はエラー
	movea.l	par2+val(sp),a1
	cmpi.w	#119-1,dim1(a1)
	bhi	mz_illegal_arry		*配列のサイズが違う
	move.w	dim1(a1),d2		*d2=添え字の大きさ(=dbra counter)
	lea	dim1_data(a1),a1	*a1=data pointer
	moveq.l	#-1,d3
	tst.w	par3(sp)
	bmi	@f
	move.l	par3+val(sp),d3	*get dev id
@@:
	lea	sc55_pst_(pc),a0
	bsr	wrt_str
	move.l	d1,d0
	bsr	wrt_num3	*part number
	tst.l	d3
	bmi	@f
	moveq	#',',d0
	bsr	do_wrt_zms_b
	move.l	d3,d0
	bsr	wrt_num3	*dev id
@@:
	move.w	#' {',d0
	bsr	do_wrt_zms_w
@@:
	moveq.l	#0,d0
	move.b	(a1)+,d0
	bsr	wrt_num
	tst.w	d2
	bne	1f
	moveq.l	#'}',d0
	bsr	do_wrt_zms_b
	bra	2f
1:				*,で区切る
	moveq	#',',d0
	bsr	do_wrt_zms_b
2:
	dbra	d2,@b
	bsr	compile_zms
	bra	ok_0

sc55_dst:			*sc55 drum parameter
	bsr	check_zm3
	move.l	par1+val(sp),d0		*get map number
	cmpi.l	#1,d0
	bhi	mz_illegal_parameter	*1以上はエラー
	move.l	par2+val(sp),d1		*get key code
	cmpi.l	#127,d1
	bhi	mz_illegal_parameter
	movea.l	par3+val(sp),a1
	cmpi.w	#8-1,dim1(a1)
	bhi	mz_illegal_arry		*配列のサイズが違う
	move.w	dim1(a1),d2		*d2=添え字の大きさ(=dbra counter)
	lea	dim1_data(a1),a1	*a1=data pointer
	moveq.l	#-1,d3
	tst.w	par4(sp)
	bmi	@f
	move.l	par4+val(sp),d3		*get dev id
@@:
	lea	sc55_dst_(pc),a0
	bsr	wrt_str
	bsr	wrt_num3	*map number
	moveq	#',',d0
	bsr	do_wrt_zms_b
	move.l	d1,d0
	bsr	wrt_num3	*key number
	move.l	d3,d0
	bmi	@f
	moveq	#',',d0
	bsr	do_wrt_zms_b
	bsr	wrt_num3	*dev id
@@:
	move.w	#' {',d0
	bsr	do_wrt_zms_w
@@:
	moveq.l	#0,d0
	move.b	(a1)+,d0
	bsr	wrt_num
	tst.w	d2
	bne	1f
	moveq.l	#'}',d0
	bsr	do_wrt_zms_b
	bra	2f
1:				*,で区切る
	moveq	#',',d0
	bsr	do_wrt_zms_b
2:
	dbra	d2,@b
	bsr	compile_zms
	bra	ok_0

sc55_prt:			*SC55に文字列を表示する
	bsr	check_zm3
	lea	sc55_prt_(pc),a0
	bsr	wrt_str
	tst.w	par2(sp)		*dev id省略?
	bmi	@f
	move.l	par2+val(sp),d0
	bsr	wrt_num3		*dev id
@@:
	move.w	#' "',d0
	bsr	do_wrt_zms_w
	move.l	par1+val(sp),a0
	tst.b	(a0)
	beq	mz_nul_string_error		*length=0は駄目
	bsr	wrt_str
	moveq	#'"',d0
	bsr	do_wrt_zms_b
	bsr	compile_zms
	bra	ok_0

sc55_dsp:			*SC55のレベル・ディスプレイに表示する
	bsr	check_zm3
	movea.l	par1+val(sp),a1
	cmpi.w	#16-1,dim1(a1)
	bne	mz_illegal_arry		*配列のサイズが違う
	lea	dim1_data(a1),a1	*a1=data pointer
	moveq.l	#-1,d3
	tst.w	par2(sp)
	bmi	@f
	move.l	par2+val(sp),d3	*get dev id
@@:
	lea	sc55_dsp_(pc),a0
	bsr	wrt_str
	move.l	d3,d0
	bmi	@f
	bsr	wrt_num3	*dev id
@@:
	move.w	#' {',d0
	bsr	do_wrt_zms_w
	moveq.l	#16-1,d2	*for dbra
sc55dsplp:
	moveq.l	#0,d0
	move.l	(a1)+,d0
	bsr	wrt_num
	tst.w	d2
	bne	1f
	moveq.l	#'}',d0
	bsr	do_wrt_zms_b
	bra	@f
1:
	cmpi.w	#8,d2		*8個ずつまとめる
	bne	2f
	move.l	#$0d0a0909,d0
	bsr	do_wrt_zms_l
	bra	@f
2:
	moveq	#',',d0
	bsr	do_wrt_zms_b
@@:
	dbra	d2,sc55dsplp
	bsr	compile_zms
	bra	ok_0

mt32_init:			*V2 MT32初期化
	bsr	check_zm3
	moveq.l	#-1,d3
	tst.w	par1(sp)
	bmi	@f
	move.l	par1+val(sp),d3	*get dev id
@@:
	lea	mt32_init_(pc),a0
	bsr	wrt_str
	tst.l	d3
	bmi	@f
	moveq	#' ',d0
	bsr	do_wrt_zms_b
	move.l	d3,d0
	bsr	wrt_num3	*dev id
@@:
	bsr	compile_zms
	bra	ok_0

mt32_pr:			*V2 mt32パーシャルリザーブ
	bsr	check_zm3
	movea.l	par1+val(sp),a1
	cmpi.w	#9-1,dim1(a1)
	bne	mz_illegal_arry		*配列のサイズが違う
	lea	dim1_data(a1),a1	*a1=data pointer
	moveq.l	#-1,d3
	tst.w	par2(sp)
	bmi	@f
	move.l	par2+val(sp),d3	*get dev id
@@:
	lea	mt32_pr_(pc),a0
	bsr	wrt_str
	move.l	d3,d0
	bmi	@f
	bsr	wrt_num3	*dev id
@@:
	move.w	#' {',d0
	bsr	do_wrt_zms_w
	moveq.l	#9-1,d1
@@:
	moveq.l	#0,d0
	move.b	(a1)+,d0
	bsr	wrt_num
	tst.w	d1
	bne	1f
	moveq	#'}',d0
	bsr	do_wrt_zms_b
	bra	2f
1:
	moveq	#',',d0
	bsr	do_wrt_zms_b
2:
	dbra	d1,@b
	bsr	compile_zms
	bra	ok_0

mt32_rvb:			*V2 mt32リバーブ・パラメータ設定
	bsr	check_zm3
	movea.l	par1+val(sp),a1
	move.w	dim1(a1),d1	*添え字
	cmpi.w	#3-1,d1
	bhi	mz_illegal_arry		*配列のサイズが違う
	lea	dim1_data(a1),a1	*a1=data pointer
	moveq.l	#-1,d3
	tst.w	par2(sp)
	bmi	@f
	move.l	par2+val(sp),d3	*get dev id
@@:
	lea	mt32_rvb_(pc),a0
	bsr	wrt_str
	move.l	d3,d0
	bmi	@f
	bsr	wrt_num3	*dev id
@@:
	move.w	#' {',d0
	bsr	do_wrt_zms_w
@@:
	moveq.l	#0,d0
	move.b	(a1)+,d0
	bsr	wrt_num
	tst.w	d1
	bne	1f
	moveq	#'}',d0
	bsr	do_wrt_zms_b
	bra	2f
1:
	moveq	#',',d0
	bsr	do_wrt_zms_b
2:
	dbra	d1,@b
	bsr	compile_zms
	bra	ok_0

mt32_pst:			*V2 MT32パートＭＩＤＩチャンネル設定
	bsr	check_zm3
	movea.l	par1+val(sp),a1
	move.w	dim1(a1),d1
	cmpi.w	#9-1,d1
	bhi	mz_illegal_arry		*配列のサイズが違う
	lea	dim1_data(a1),a1	*a1=data pointer
	moveq.l	#-1,d3
	tst.w	par2(sp)
	bmi	@f
	move.l	par2+val(sp),d3	*get dev id
@@:
	lea	mt32_pst_(pc),a0
	bsr	wrt_str
	move.l	d3,d0
	bmi	@f
	bsr	wrt_num3	*dev id
@@:
	move.w	#' {',d0
	bsr	do_wrt_zms_w
@@:
	moveq.l	#0,d0
	move.b	(a1)+,d0
	bsr	wrt_num
	tst.w	d1
	bne	1f
	moveq	#'}',d0
	bsr	do_wrt_zms_b
	bra	2f
1:
	moveq	#',',d0
	bsr	do_wrt_zms_b
2:
	dbra	d1,@b
	bsr	compile_zms
	bra	ok_0

mt32_dst:			*V2 mt32ドラムセットアップ設定
	bsr	check_zm3
	move.l	par1+val(sp),d1	*note number
	movea.l	par2+val(sp),a1
	move.w	dim1(a1),d2		*添え字
	cmpi.w	#4-1,d2
	bhi	mz_illegal_arry		*配列のサイズが違う
	lea	dim1_data(a1),a1	*a1=data pointer
	moveq.l	#-1,d3
	tst.w	par3(sp)
	bmi	@f
	move.l	par3+val(sp),d3	*get dev id
@@:
	lea	mt32_dst_(pc),a0
	bsr	wrt_str
	move.l	d1,d0
	bsr	wrt_num		*note num
	tst.l	d3
	bmi	@f
	moveq	#',',d0
	bsr	do_wrt_zms_b
	move.l	d3,d0
	bsr	wrt_num3	*dev id
@@:
	move.w	#' {',d0
	bsr	do_wrt_zms_w
@@:
	moveq.l	#0,d0
	move.b	(a1)+,d0
	bsr	wrt_num
	tst.w	d2
	bne	1f
	moveq	#'}',d0
	bsr	do_wrt_zms_b
	bra	2f
1:
	moveq	#',',d0
	bsr	do_wrt_zms_b
2:
	dbra	d2,@b
	bsr	compile_zms
	bra	ok_0

mt32_cmn:			*V2 MT32音色コモンパラメータ設定
	bsr	check_zm3
	move.l	par1+val(sp),d1		*timbre number
	movea.l	par2+val(sp),a3		*name address
	tst.b	(a3)
	beq	mz_nul_string_error
	movea.l	par3+val(sp),a1
	move.w	dim1(a1),d2	*添え字
	cmpi.w	#4-1,d2
	bhi	mz_illegal_arry		*配列のサイズが違う
	lea	dim1_data(a1),a1	*a1=data pointer
	moveq.l	#-1,d3
	tst.w	par4(sp)
	bmi	@f
	move.l	par4+val(sp),d3	*get dev id
@@:
	lea	mt32_cmn_(pc),a0
	bsr	wrt_str
	move.l	d1,d0
	bsr	wrt_num		*timbre num
	tst.l	d3
	bmi	@f
	moveq	#',',d0
	bsr	do_wrt_zms_b
	move.l	d3,d0
	bsr	wrt_num3	*dev id
@@:
	move.l	#' { "',d0
	bsr	do_wrt_zms_l
@@:
	move.l	a3,a0
	bsr	wrt_str
	move.w	#'",',d0
	bsr	do_wrt_zms_w
@@:
	moveq.l	#0,d0
	move.b	(a1)+,d0
	bsr	wrt_num
	tst.w	d2
	bne	1f
	moveq	#'}',d0
	bsr	do_wrt_zms_b
	bra	2f
1:
	moveq	#',',d0
	bsr	do_wrt_zms_b
2:
	dbra	d2,@b
	bsr	compile_zms
	bra	ok_0

mt32_ptch:			*V2 mt32パッチパラメータ設定
	bsr	check_zm3
	move.l	par1+val(sp),d1	*patch number
	movea.l	par2+val(sp),a1
	move.w	dim1(a1),d2	*添え字
	cmpi.w	#7-1,d2
	bhi	mz_illegal_arry		*配列のサイズが違う
	lea	dim1(a1),a1	*a1=data pointer
	moveq.l	#-1,d3
	tst.w	par3(sp)
	bmi	@f
	move.l	par3+val(sp),d3	*get dev id
@@:
	lea	mt32_ptch_(pc),a0
	bsr	wrt_str
	move.l	d1,d0
	bsr	wrt_num		*patch num
	tst.l	d3
	bmi	@f
	moveq	#',',d0
	bsr	do_wrt_zms_b
	move.l	d3,d0
	bsr	wrt_num3	*dev id
@@:
	move.w	#' {',d0
	bsr	do_wrt_zms_w
@@:
	moveq.l	#0,d0
	move.b	(a1)+,d0
	bsr	wrt_num
	tst.w	d2
	bne	1f
	moveq	#'}',d0
	bsr	do_wrt_zms_b
	bra	2f
1:
	moveq	#',',d0
	bsr	do_wrt_zms_b
2:
	dbra	d2,@b
	bsr	compile_zms
	bra	ok_0

mt32_prtl:			*V2 mt32音色パーシャルパラメータ設定
	bsr	check_zm3
	move.l	par1+val(sp),d0	*timbre number
	move.l	par2+val(sp),d1	*name address
	movea.l	par3+val(sp),a1
	move.w	dim1(a1),d2		*添え字
	cmpi.w	#58-1,d2
	bhi	mz_illegal_arry		*配列のサイズが違う
	lea	dim1(a1),a1		*a1=data pointer
	moveq.l	#-1,d3
	tst.w	par4(sp)
	bmi	@f
	move.l	par4+val(sp),d3	*get dev id
@@:
	lea	mt32_prtl_(pc),a0
	bsr	wrt_str
	bsr	wrt_num		*timbre number
	moveq	#',',d0
	bsr	do_wrt_zms_b
	move.l	d1,d0
	bsr	wrt_num		*partial number
	tst.l	d3
	bmi	@f
	moveq	#',',d0
	bsr	do_wrt_zms_b
	move.l	d3,d0
	bsr	wrt_num3	*dev id
@@:
	move.l	#' {'*65536+$0d0a,d0
	bsr	do_wrt_zms_l
	lea	rem4(pc),a0
	bsr	wrt_str
	moveq	#9,d0		*tab
	bsr	do_wrt_zms_b
	moveq.l	#0,d1
prtllp:
	moveq.l	#0,d0
	move.b	(a1)+,d0
	bsr	wrt_num2
	addq.b	#1,d1

	cmpi.b	#8,d1
	bne	@f
	lea	rem5(pc),a0
	bsr	wrt_str
	moveq	#9,d0		*tab
	bsr	do_wrt_zms_b
	bra	1f
@@:
	cmpi.b	#$14,d1
	bne	@f
	lea	rem6(pc),a0
	bsr	wrt_str
	moveq	#9,d0		*tab
	bsr	do_wrt_zms_b
	bra	1f
@@:
	cmpi.b	#$17,d1
	bne	@f
	lea	rem7(pc),a0
	bsr	wrt_str
	moveq	#9,d0		*tab
	bsr	do_wrt_zms_b
	bra	1f
@@:
	cmpi.b	#$1C,d1
	bne	@f
	lea	rem8(pc),a0
	bsr	wrt_str
	moveq	#9,d0		*tab
	bsr	do_wrt_zms_b
	bra	1f
@@:
	cmpi.b	#$29,d1
	bne	@f
	lea	rem9(pc),a0
	bsr	wrt_str
	moveq	#9,d0		*tab
	bsr	do_wrt_zms_b
	bra	1f
@@:
	cmpi.b	#$2f,d1
	bne	@f
	lea	rem10(pc),a0
	bsr	wrt_str
	moveq	#9,d0		*tab
	bsr	do_wrt_zms_b
	bra	1f
@@:
	tst.w	d2
	bne	@f
	moveq.l	#',',d0
	bsr	do_wrt_zms_b
	bra	1f
@@:
	moveq.l	#'}',d0		*最後
	bsr	do_wrt_zms_b
1:
	dbra	d2,prtllp
	bsr	compile_zms
	bra	ok_0

mt32_prt:			*V2 MT32に文字列を表示する
	bsr	check_zm3
	lea	mt32_prt_(pc),a0
	bsr	wrt_str
	tst.w	par2(sp)		*dev id省略?
	bmi	@f
	move.l	par2+val(sp),d0
	bsr	wrt_num3		*dev id
@@:
	move.w	#' "',d0
	bsr	do_wrt_zms_w
	move.l	par1+val(sp),a0
	tst.b	(a0)
	beq	mz_nul_string_error	*length=0は駄目
	bsr	wrt_str
	moveq	#'"',d0
	bsr	do_wrt_zms_b
	bsr	compile_zms
	bra	ok_0

u220_setup:			*V2 u220セットアップパラメータの設定
	bsr	check_zm3
	movea.l	par1+val(sp),a1
	cmpi.w	#7-1,dim1(a1)
	bne	mz_illegal_arry		*配列のサイズが違う
	lea	dim1_data(a1),a1	*a1=data pointer
	moveq.l	#-1,d3
	tst.w	par2(sp)
	bmi	@f
	move.l	par2+val(sp),d3		*get dev id
@@:
	lea	u220_setup_(pc),a0
	bsr	wrt_str
	move.l	d3,d0
	bmi	@f
	bsr	wrt_num3		*dev id
@@:
	move.w	#' {',d0
	bsr	do_wrt_zms_w
	moveq.l	#7-1,d1
@@:
	moveq.l	#0,d0
	move.b	(a1)+,d0
	bsr	wrt_num
	tst.w	d1
	beq	1f
	moveq	#',',d0
	bsr	do_wrt_zms_b
	bra	2f
1:
	moveq.l	#'}',d0
	bsr	do_wrt_zms_b
2:
	dbra	d1,@b
	bsr	compile_zms
	bra	ok_0

u220_pst:			*V2 u220テンポラリパート・セットアップパラメータ設定
	bsr	check_zm3
	move.l	par1+val(sp),d1	*part number
	movea.l	par2+val(sp),a1
	move.w	dim1(a1),d2		*添え字
	cmpi.w	#13-1,d2
	bne	mz_illegal_arry		*配列のサイズが違う
	lea	dim1_data(a1),a1	*a1=data pointer
	moveq.l	#-1,d3
	tst.w	par3(sp)
	bmi	@f
	move.l	par3+val(sp),d3	*get dev id
@@:
	lea	u220_pst_(pc),a0
	bsr	wrt_str
	move.l	d1,d0
	bsr	wrt_num		*patch num
	tst.l	d3
	bmi	@f
	moveq	#',',d0
	bsr	do_wrt_zms_b
	move.l	d3,d0
	bsr	wrt_num3	*dev id
@@:
	move.w	#' {',d0
	bsr	do_wrt_zms_w
@@:
	moveq.l	#0,d0
	move.b	(a1)+,d0
	bsr	wrt_num
	tst.w	d2
	beq	1f
	moveq	#',',d0
	bsr	do_wrt_zms_b
	bra	2f
1:
	moveq	#'}',d0
	bsr	do_wrt_zms_b
2:
	dbra	d2,@b
	bsr	compile_zms
	bra	ok_0

u220_cmn:			*V2 u220テンポラリパッチ・コモンパラメータの設定
	bsr	check_zm3
	movea.l	par1+val(sp),a1
	cmpi.w	#18-1,dim1(a1)
	bne	mz_illegal_arry		*配列のサイズが違う
	lea	dim1_data(a1),a1	*a1=data pointer
	moveq.l	#-1,d3
	tst.w	par2(sp)
	bmi	@f
	move.l	par2+val(sp),d3		*get dev id
@@:
	lea	u220_cmn_(pc),a0
	bsr	wrt_str
	move.l	d3,d0
	bmi	@f
	bsr	wrt_num3		*dev id
@@:
	move.w	#' {',d0
	bsr	do_wrt_zms_w
	moveq.l	#18-1,d1
@@:
	moveq.l	#0,d0
	move.b	(a1)+,d0
	bsr	wrt_num
	tst.w	d1
	beq	1f
	move.b	#',',d0
	bsr	do_wrt_zms_b
	bra	2f
1:
	moveq	#'}',d0
	bsr	do_wrt_zms_b
2:
	dbra	d1,@b
	bsr	compile_zms
	bra	ok_0

u220_tmb:			*V2 U220音色パラメータ設定
	bsr	check_zm3
	move.l	par1+val(sp),d1		*timbre number
	movea.l	par2+val(sp),a3		*name address
	tst.b	(a3)
	beq	mz_nul_string_error
	movea.l	par3+val(sp),a1
	move.w	dim1(a1),d2		*添え字
	cmpi.w	#26-1,d2
	bne	mz_illegal_arry		*配列のサイズが違う
	lea	dim1_data(a1),a1	*a1=data pointer
	moveq.l	#-1,d3
	tst.w	par4(sp)
	bmi	@f
	move.l	par4+val(sp),d3		*get dev id
@@:
	lea	u220_tmb_(pc),a0
	bsr	wrt_str
	move.l	d1,d0
	bsr	wrt_num			*timbre num
	tst.l	d3
	bmi	@f
	moveq	#',',d0
	bsr	do_wrt_zms_b
	move.l	d3,d0
	bsr	wrt_num3	*dev id
@@:
	move.w	#' {',d0
	bsr	do_wrt_zms_w
	move.l	a3,a0
	bsr	wrt_str
	move.w	#$0d0a,d0
	bsr	do_wrt_zms_w
	lea	rem11(pc),a0
	bsr	wrt_str
	moveq	#9,d0
	bsr	do_wrt_zms_b
	moveq.l	#0,d1
tmblp:
	moveq.l	#0,d0
	move.b	(a1)+,d0
	bsr	wrt_num2
	addq.b	#1,d1
	cmpi.b	#9,d1
	bne	@f
	lea	rem12(pc),a0
	bsr	wrt_str
	moveq	#9,d0
	bsr	do_wrt_zms_b
	bra	2f
@@:
	cmpi.b	#18,d1
	bne	@f
	lea	rem13(pc),a0
	bsr	wrt_str
	moveq	#9,d0
	bsr	do_wrt_zms_b
	bra	2f
@@:
	tst.w	d2
	beq	1f
	moveq	#',',d0
	bsr	do_wrt_zms_b
	bra	2f
1:
	moveq	#'}',d0
	bsr	do_wrt_zms_b
2:
	dbra	d2,tmblp
	bsr	compile_zms
	bra	ok_0

u220_dst:			*V2 u220テンポラリ・ドラム・セットアップパラメータの設定
	bsr	check_zm3
	movea.l	par1+val(sp),a1
	cmpi.w	#7-1,dim1(a1)
	bne	mz_illegal_arry		*配列のサイズが違う
	lea	dim1_data(a1),a1	*a1=data pointer
	moveq.l	#-1,d3
	tst.w	par2(sp)
	bmi	@f
	move.l	par2+val(sp),d3		*get dev id
@@:
	lea	u220_dst_(pc),a0
	bsr	wrt_str
	move.l	d3,d0
	bmi	@f
	bsr	wrt_num3		*dev id
@@:
	move.w	#' {',d0
	bsr	do_wrt_zms_w
	moveq.l	#7-1,d1
@@:
	moveq.l	#0,d0
	move.b	(a1)+,d0
	bsr	wrt_num
	tst.w	d1
	beq	1f
	moveq.l	#',',d0
	bsr	do_wrt_zms_b
	bra	2f
1:
	moveq	#'}',d0
	bsr	do_wrt_zms_b
2:
	dbra	d1,@b
	bsr	compile_zms
	bra	ok_0

u220_dis:			*V2 u220ドラムインストパラメータ設定
	bsr	check_zm3
	move.l	par1+val(sp),d1	*note number
	movea.l	par2+val(sp),a1
	move.w	dim1(a1),d2		*添え字
	cmpi.w	#20-1,d2
	bhi	mz_illegal_arry		*配列のサイズが違う
	lea	dim1_data(a1),a1	*a1=data pointer
	moveq.l	#-1,d3
	tst.w	par3(sp)
	bmi	@f
	move.l	par3+val(sp),d3		*get dev id
@@:
	lea	u220_dis_(pc),a0
	bsr	wrt_str
	move.l	d1,d0
	bsr	wrt_num		*note num
	tst.l	d3
	bmi	@f
	moveq.l	#',',d0
	bsr	do_wrt_zms_b
	move.l	d3,d0
	bsr	wrt_num3	*dev id
@@:
	move.w	#' {',d0
	bsr	do_wrt_zms_w
@@:
	moveq.l	#0,d0
	move.b	(a1)+,d0
	bsr	wrt_num
	tst.w	d2
	beq	1f
	moveq	#',',d0
	bsr	do_wrt_zms_b
	bra	2f
1:
	moveq	#'}',d0
	bsr	do_wrt_zms_b
2:
	dbra	d2,@b
	bsr	compile_zms
	bra	ok_0

u220_prt:			*V2 U220に文字列を表示する
	bsr	check_zm3
	lea	u220_prt_(pc),a0
	bsr	wrt_str
	tst.w	par2(sp)		*dev id省略?
	bmi	@f
	move.l	par2+val(sp),d0
	bsr	wrt_num3		*dev id
@@:
	move.w	#' "',d0
	bsr	do_wrt_zms_w
	move.l	par1+val(sp),a0
	tst.b	(a0)
	beq	mz_nul_string_error	*length=0は駄目
	bsr	wrt_str
	moveq	#'"',d0
	bsr	do_wrt_zms_b
	bsr	compile_zms
	bra	ok_0

m1_mdch:			*V2 M1 SONG0のＭＩＤＩチャンネル設定
	bsr	check_zm3
	movea.l	par1+val(sp),a1
	cmpi.w	#8-1,dim1(a1)
	bne	mz_illegal_arry		*配列のサイズが違う
	lea	dim1_data(a1),a1	*a1=data pointer
	lea	m1_mdch_(pc),a0
	bsr	wrt_str
	moveq.l	#8-1,d1
@@:
	moveq.l	#0,d0
	move.b	(a1)+,d0
	bsr	wrt_num
	tst.w	d1
	beq	1f
	moveq	#',',d0
	bsr	do_wrt_zms_b
	bra	2f
1:
	moveq	#'}',d0
	bsr	do_wrt_zms_b
2:
	dbra	d1,@b
	bsr	compile_zms
	bra	ok_0

m1_ptst:			*V2 M1 SONG0のパートパラメータ設定
	bsr	check_zm3
	movea.l	par1+val(sp),a1
	cmpi.w	#40-1,dim1(a1)
	bne	mz_illegal_arry		*配列のサイズが違う
	lea	dim1_data(a1),a1	*a1=data pointer
	lea	rem14(pc),a0
	bsr	wrt_str
	move.w	#'1'*256+9,d0
	bsr	do_wrt_zms_w
	moveq	#9,d0
	bsr	do_wrt_zms_b
	lea	rem15(pc),a0
	bsr	wrt_str
	lea	m1_ptst_(pc),a0
	bsr	wrt_str
	moveq.l	#40-1,d1
	moveq.l	#2,d2
	moveq.l	#6,d3
m1ptst_lp:
	moveq.l	#0,d0
	move.b	(a1)+,d0
	bsr	wrt_num2
	tst.w	d1
	bne	@f
	moveq.l	#'}',d0
	bsr	do_wrt_zms_b
	bra	1f
@@:
	subq.b	#1,d3
	bne	@f
	moveq.l	#5,d3
	move.w	#$0d0a,d0
	bsr	do_wrt_zms_w
	lea	rem14(pc),a0
	bsr	wrt_str
	move.l	d2,d0
	bsr	wrt_num
	addq.b	#1,d2
	move.w	#$0909,d0
	bsr	do_wrt_zms_w
	lea	rem15(pc),a0
	bsr	wrt_str
	move.w	#$0909,d0
	bsr	do_wrt_zms_w
	bra	1f
@@:
	moveq.l	#',',d0
	bsr	do_wrt_zms_b
1:
	dbra	d1,m1ptst_lp
	bsr	compile_zms
	bra	ok_0

m1_effect:			*V2 M1 SONG0のエフェクトパラメータ設定
	bsr	check_zm3
	movea.l	par1+val(sp),a1
	cmpi.w	#25-1,dim1(a1)
	bne	mz_illegal_arry		*配列のサイズが違う
	lea	dim1_data(a1),a1	*a1=data pointer
	lea	m1_efct_(pc),a0
	bsr	wrt_str
	moveq.l	#25-1,d1
@@:
	moveq.l	#0,d0
	move.b	(a1)+,d0
	bsr	wrt_num
	tst.w	d1
	beq	1f
	moveq	#',',d0
	bsr	do_wrt_zms_b
	bra	2f
1:
	moveq	#'}',d0
	bsr	do_wrt_zms_b
2:
	dbra	d1,@b
	bsr	compile_zms
	bra	ok_0

m1_prt:				*V2 M1 SONG0のソングネーム設定
	bsr	check_zm3
	lea	m1_prt_(pc),a0
	bsr	wrt_str
	move.l	par1+val(sp),a0
	tst.b	(a0)
	beq	mz_nul_string_error	*length=0は駄目
	bsr	wrt_str
	moveq	#'"',d0
	bsr	do_wrt_zms_b
	bsr	compile_zms
	bra	ok_0

send_m1:			*V2 M1へ送信
	bsr	check_zm3
	moveq.l	#-1,d3
	tst.w	par1(sp)
	bmi	@f
	move.l	par1+val(sp),d3	*get dev id
@@:
	lea	send_m1_(pc),a0
	bsr	wrt_str
	tst.l	d3
	bmi	@f
	moveq	#' ',d0
	bsr	do_wrt_zms_b
	move.l	d3,d0
	bsr	wrt_num3	*dev id
@@:
	bsr	compile_zms
	bra	ok_0

zmd_play:			*V2 ブロックデータの読み込み
	bsr	check_zm3
	lea	filename(pc),a2
	move.l	par1+val(sp),a1	*a1=file name
	clr.b	d1
zmdplp01:				*ファイルネームのゲット
	move.b	(a1)+,d0
	cmpi.b	#'.',d0
	bne	@f
	st.b	d1		*MARK
@@:
	cmpi.b	#' ',d0
	bls	@f
	move.b	d0,(a2)+
	bra	zmdplp01
@@:
	tst.b	d1
	bne	@f
	move.b	#'.',(a2)+	*拡張子をセット
	move.b	#'Z',(a2)+
	move.b	#'M',(a2)+
	move.b	#'D',(a2)+
@@:
	clr.b	(a2)			*end code
	lea	filename(pc),a2
	bsr	fopen			*< a2=filename
	tst.l	d5
	bmi	mz_file_open_error	*read error
	bsr	read			*return=a5:address,d3:size
	bsr	self_output
	bra	ok_0

	.include	../fopen.s

m_debug:			*V2 [!]コマンドの有効/無効化
	bsr	check_zm3
	move.w	#'(d',d0
	bsr	do_wrt_zms_w
	move.l	par1+val(sp),d0
	bsr	wrt_num
	moveq	#')',d0
	bsr	do_wrt_zms_b
	bsr	compile_zms
	bra	ok_0

m_count:			*V2 全音符の絶対音長の設定
	bsr	check_zm3
	move.w	#'(z',d0
	bsr	do_wrt_zms_w
	move.l	par1+val(sp),d0
	bsr	wrt_num
	moveq	#')',d0
	bsr	do_wrt_zms_b
	bsr	compile_zms
	bra	ok_0

fm_master:			*V2 FM音源の出力バランス設定
	bsr	check_zm3
	lea	fm_mstr_(pc),a0
	bsr	wrt_str
	move.l	par1+val(sp),d0
	bsr	wrt_num
	bsr	compile_zms
	bra	ok_0

m_mute:				*V2 任意トラックのマスク
	bsr	check_zm3
	lea	par1(sp),a3
	tst.w	(a3)		*全省略ならば初期化
	bmi	reset_mask
	moveq.l	#-1,d3
	bsr	get_mask_trk
	Z_MUSIC	#ZM_MASK_TRACKS
	tst.l	d0
	bne	error
	bra	ok_0

m_solo:				*V2 任意トラックのマスク解除
	bsr	check_zm3
	lea	par1(sp),a3
	tst.w	(a3)		*全省略ならば初期化
	bmi	reset_mask
	moveq.l	#0,d3
	bsr	get_mask_trk
	Z_MUSIC	#ZM_MASK_TRACKS
	tst.l	d0
	bne	error
	bra	ok_0

reset_mask:
	moveq.l	#0,d1
	move.l	d1,a1
	Z_MUSIC	#ZM_MASK_TRACKS
	tst.l	d0
	bne	error
	bra	ok_0

get_mask_trk:			*トラック番号を取得してテーブルへ
	* < a3.l=par1(sp)
	* < d3.w=mode
	* > a1.l=trk_cmd
	* - all
reglist	reg	d1-d2/a0
	movem.l	reglist,-(sp)
	lea	trk_cmd(pc),a0
	move.l	a0,a1
	moveq.l	#0,d2
gmt_lp:
	tst.w	(a3)
	bmi	@f		*no more value
	move.l	val(a3),d1
	subq.l	#1,d1
	cmpi.l	#tr_max-1,d1
	bhi	mz_illegal_track_number
	move.w	d1,(a0)+	*track
	move.w	d3,(a0)+	*mode
	addq.w	#1,d2
	cmpi.w	#128,d2
	bhi	mz_too_many_tracks
	add.w	#next_par,a3		*次へ
	bra	gmt_lp
@@:
	move.w	#-1,(a0)+	*endcode
	movem.l	(sp)+,reglist
	rts

m_wave_form:			*V2 波形メモリセット
	bsr	check_zm3
	lea	wvfm_(pc),a0
	bsr	wrt_str
	move.l	par1+val(sp),d0	*波形番号
	bsr	wrt_num
	moveq	#',',d0
	bsr	do_wrt_zms_b
	move.l	par2+val(sp),d0	*ループタイプ
	bsr	wrt_num
	moveq.l	#0,d0
	tst.w	par3(sp)
	bmi	@f
	moveq	#',',d0
	bsr	do_wrt_zms_b
	move.l	par3+val(sp),d0	*ループポイント
@@:
	bsr	wrt_num		*write loop point
	move.l	par4+val(sp),a1
	addq.w	#dim1,a1
	move.w	(a1)+,d2	*添え字をゲット
	addq.w	#1,d2		*データカウントにする
	move.w	#' {',d0
	bsr	do_wrt_zms_w
	moveq.l	#0,d1
wvf_lp01:
	move.l	(a1)+,d0
	bsr	wrt_num
	subq.w	#1,d2
	beq	mwf_owari
	addq.w	#1,d1
	cmp.l	#16,d1		*16個おきに改行
	bcs	@f
	moveq.l	#0,d1
	move.l	#$0d0a_0909,d0
	bsr	do_wrt_zms_l
	bra	wvf_lp01
@@:
	moveq	#',',d0
	bsr	do_wrt_zms_b
	bra	wvf_lp01
mwf_owari:
	moveq	#'}',d0
	bsr	do_wrt_zms_b
	bsr	compile_zms
	bra	ok_0

adpcm_to_pcm:				*V2 ADPCM→PCM変換
	bsr	check_zm3
	movea.l	par1+val(sp),a1		*配列
	moveq.l	#0,d0
	move.w	dim1(a1),d0
	addq.l	#1,d0			*size
	lea	dim1_data(a1),a1
	tst.w	par2(sp)
	bmi	@f			*省略のケース
	move.l	par2+val(sp),d1		*get size
	beq	mz_illegal_parameter
	cmp.l	d0,d1
	bhi	mz_illegal_parameter	*サイズが添え字より大きい!?
	move.l	d1,d2			*d2=変換元のサイズ
@@:
	movea.l	par3+val(sp),a2		*配列
	moveq.l	#0,d1
	move.w	dim1(a2),d1
	addq.l	#1,d1			*size
	lea	dim1_data(a2),a2
	move.l	d2,d0
	lsl.l	#1,d0
	cmp.l	d0,d1
	bcs	mz_buffer_too_small
	moveq.l	#0,d1			*ADPCM->PCM
	Z_MUSIC	#ZM_CONVERT_PCM
	bra	ok_0

pcm_to_adpcm:				*V2 PCM→ADPCM変換
	bsr	check_zm3
	movea.l	par1+val(sp),a1		*配列
	moveq.l	#0,d0
	move.w	dim1(a1),d0
	addq.l	#1,d0			*size
	lea	dim1_data(a1),a1
	tst.w	par2(sp)
	bmi	@f			*省略のケース
	move.l	par2+val(sp),d1		*get size
	beq	mz_illegal_parameter
	cmp.l	d0,d1
	bhi	mz_illegal_parameter	*サイズが添え字より大きい!?
	move.l	d1,d2			*d2=変換元のサイズ
@@:
	movea.l	par3+val(sp),a2		*配列
	moveq.l	#0,d1
	move.w	dim1(a2),d1
	addq.l	#1,d1			*size
	lea	dim1_data(a2),a2
	move.l	d2,d0
	lsr.l	#1,d0
	cmp.l	d0,d1
	bcs	mz_buffer_too_small
	moveq.l	#1,d1			*PCM->ADPCM
	Z_MUSIC	#ZM_CONVERT_PCM
	bra	ok_0

exec_zms:				*V2 ZMSコマンド実行
	bsr	check_zm3
	move.l	par1+val(sp),a0	*そのまま書き出す
	bsr	wrt_str
	bsr	compile_zms
	bra	ok_0

zm_ver:					*V2 ZMUSICバージョン取得
zm_check_zmsc:				*V3 ZMUSICのバージョン取得
	bsr	check_zm3
	moveq.l	#0,d0
	move.w	zm_ver_buf(pc),d0	*d0.w=version ID
	bra	ok_ret

zm_work:			*V3 演奏トラックワーク内容取得
	bsr	check_zm3
	move.l	par1+val(sp),d1		*トラック番号(0-65534)
	Z_MUSIC	#ZM_GET_PLAY_WORK	*a0=trk n seq_wk_tbl
	move.l	par2+val(sp),d2		*オフセット(0-65535)
	moveq.l	#0,d0
	move.b	(a0,d2.l),d0		*d0.b=Work value
	bra	ok_ret

zm_exec_zmd:			*V3 ZMD列の実行
	bsr	check_zm3
	move.l	par1+val(sp),d1	*track number
	move.l	par2+val(sp),d2	*size
	movea.l	par3+val(sp),a1	*zmd
	Z_MUSIC	#ZM_EXEC_ZMD
	bra	ok_ret

zm_assign:			*V3 チャンネルアサイン
	bsr	check_zm3
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d2
	Z_MUSIC	#ZM_ASSIGN
	tst.l	d0
	bne	error
	bra	ok_0

zm_vget:			*V3 音色取りだし
	bsr	check_zm3
	move.l	par1+val(sp),d1	*sound number
	move.l	par2+val(sp),d2	*mode
	movea.l	par3+val(sp),a1	*配列
	cmpi.w	#4,dim1(a1)
	bne	mz_illegal_arry	*配列の次元が違う
	cmpi.w	#10,dim2(a1)
	bne	mz_illegal_arry	*配列の次元が違う
	lea	dim2_data(a1),a1
	Z_MUSIC	#ZM_VGET
	tst.l	d0
	bne	error
	bra	ok_0

zm_vset:			*V3 音色登録
	bsr	check_zm3
	move.l	par1+val(sp),d1	*sound number
	move.l	par2+val(sp),d2	*配列
	movea.l	par3+val(sp),a1	*配列
	cmpi.w	#4,dim1(a1)
	bne	mz_illegal_arry	*配列の次元が違う
	cmpi.w	#10,dim2(a1)
	bne	mz_illegal_arry
	lea	dim2_data(a1),a1
	Z_MUSIC	#ZM_VSET
	tst.l	d0
	bne	error
	bra	ok_0

zm_tempo			*V3 テンポ
	bsr	check_zm3
	move.l	par1+val(sp),d1	*tempo value
	move.l	par2+val(sp),d2	*tempo mode
	andi.l	#$ffff,d1
	swap	d2
	clr.w	d2
	or.l	d2,d1
	Z_MUSIC	#ZM_TEMPO
	bra	ok_ret			*d0.l=設定前のテンポとタイマ値

zm_play:				*V3 演奏開始
	bsr	check_zm3
	move.l	par1+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_PLAY
	bra	ok_0

zm_play_again:				*V3 再演奏
	Z_MUSIC	#ZM_PLAY_AGAIN
	bra	ok_0

zm_play_all:				*V3 全演奏開始
	bsr	check_zm3
	suba.l	a1,a1
	Z_MUSIC	#ZM_PLAY
	bra	ok_0

zm_play2:				*V3 再演奏
	Z_MUSIC	#ZM_PLAY2
	bra	ok_0

zm_stop:				*V3 演奏停止
	bsr	check_zm3
	move.l	par1+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_STOP
	bra	ok_0

zm_stop_all:				*V3 全演奏停止
	bsr	check_zm3
	suba.l	a1,a1
	Z_MUSIC	#ZM_STOP
	bra	ok_0

zm_cont:				*V3 演奏再開
	bsr	check_zm3
	move.l	par1+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_CONT
	bra	ok_0

zm_cont_all:				*V3 全演奏再開
	bsr	check_zm3
	suba.l	a1,a1
	Z_MUSIC	#ZM_CONT
	bra	ok_0

zm_play_status_all_ch:			*V3 全チャンネル演奏状態検査
	bsr	check_zm3
	moveq.l	#0,d1
	move.l	par1+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_PLAY_STATUS
	bra	ok_0

zm_play_status_ch:			*V3 チャンネル演奏状態検査
	bsr	check_zm3
	moveq.l	#2,d1
	move.l	par1+val(sp),d2
	Z_MUSIC	#ZM_PLAY_STATUS	*>d0.l=status
	bra	ok_ret

zm_play_status_all_tr:			*V3 全トラック演奏状態検査
	bsr	check_zm3
	moveq.l	#1,d1
	move.l	par1+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_PLAY_STATUS
	bra	ok_0

zm_play_status_tr:			*V3 トラック演奏状態検査
	bsr	check_zm3
	moveq.l	#3,d1
	move.l	par1+val(sp),d2
	Z_MUSIC	#ZM_PLAY_STATUS	*>d0.l=status
	bra	ok_ret

zm_init:				*V3 初期化
	bsr	check_zm3		*ドライバがアクティブかどうかチェック
	move.l	par1+val(sp),d1
	Z_MUSIC	#ZM_INIT		*>d0.l=Z-MUSICのバージョンID
	bra	ok_ret

zm_atoi:				*V3トラックアドレス取得
	bsr	check_zm3
	move.l	par1+val(sp),d1		*track number
	Z_MUSIC	#ZM_ATOI		*>a0.l=指定演奏トラックの先頭アドレス
	move.l	a0,d0
	beq	error
	bra	ok_ret

zm_set_timer_value:			*V3 タイマ値設定
	bsr	check_zm3
	move.l	par1+val(sp),d1		*d1=timer
	move.l	par2+val(sp),d2		*d2=mode
	andi.l	#$ffff,d1
	swap	d2
	clr.w	d2
	or.l	d2,d1
	Z_MUSIC	#ZM_SET_TIMER_VALUE	*>d0.l=設定前のテンポとタイマ値
	bra	ok_ret

zm_set_master_clock:			*V3 拍子、メトロノーム速度調号、全音符絶対音長の設定
	move.l	par1+val(sp),d1		*d1.l=0が音楽,1が効果音
	move.l	par2+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_SET_MASTER_CLOCK
	bra	ok_0

zm_play_zmd:				*V3 ZMDの演奏
	move.l	par1+val(sp),d2
	move.l	par2+val(sp),a1
	lea	dim1_data(a1),a1
	cmp.l	#ZmuSiC0,(a1)
	bne	@f
	addq.w	#8,a1
@@:
	Z_MUSIC	#ZM_PLAY_ZMD
	tst.l	d0
	bne	error
	bra	ok_0

zm_play_zmd_se:				*V3 ZMDの効果音演奏
	move.l	par1+val(sp),a1
	lea	dim1_data(a1),a1
	cmp.l	#ZmuSiC0,(a1)
	bne	@f
	addq.w	#8,a1
@@:
	Z_MUSIC	#ZM_PLAY_ZMD
	tst.l	d0
	bne	error
	bra	ok_0

zm_se_play:				*V3 ZMD効果音の演奏
	move.l	par1+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_SE_PLAY
	tst.l	d0
	bne	error
	bra	ok_0

zm_se_adpcm1:				*V3 ADPCM効果音再生1
	move.l	par1+val(sp),d1
	lsl.w	#8,d1
	move.b	par2+val+3(sp),d1
	swap	d1
	move.l	par3+val(sp),d0
	lsl.w	#8,d0
	move.b	par4+val+3(sp),d0
	move.w	d0,d1			*d1=type,vol,frq,pan
	move.l	par5+val(sp),d2		*d2=size
	move.w	par6+val(sp),d4
	swap	d4
	move.w	par7+val+2(sp),d4	*d4=priority_ch
	move.l	par8+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_SE_ADPCM1
	tst.l	d0
	bne	error
	bra	ok_0

zm_se_adpcm2:				*V3 ADPCM効果音再生2
	move.l	par1+val(sp),d1
	lsl.w	#8,d1
	move.b	par2+val+3(sp),d1
	swap	d1
	move.l	par3+val(sp),d0
	lsl.w	#8,d0
	move.b	par4+val+3(sp),d0
	move.w	d0,d1			*d1=type,vol,frq,pan
	move.l	par5+val(sp),d2		*d2=size
	move.w	par6+val(sp),d4
	swap	d4
	move.w	par7+val+2(sp),d4	*d4=priority_ch
	Z_MUSIC	#ZM_SE_ADPCM2
	tst.l	d0
	bne	error
	bra	ok_0

zm_intercept_play:			*V3 演奏開始制御の遮断制御
	move.l	par1+val(sp),d1
	Z_MUSIC	#ZM_INTERCEPT_PLAY
	bra	ok_0

zm_current_midi_in:			*V3 カレントMIDI-IN端子の設定
	move.l	par1+val(sp),d1
	Z_MUSIC	#ZM_CURRENT_MIDI_IN
	bra	ok_ret			*>d0.l=以前のカレントMIDI-OUTのポート番号(0-2)

zm_current_midi_out:			*V3 カレントMIDI-OUT端子の設定
	move.l	par1+val(sp),d1
	Z_MUSIC	#ZM_CURRENT_MIDI_OUT
	bra	ok_ret			*>d0.l=以前のカレントMIDI-INのポート番号(0-2)

zm_midi_transmission:			*V3 MIDIデータメッセージの送信
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d2
	move.l	par3+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_MIDI_TRANSMISSION
	bra	ok_ret			*>d0.l=送信データの8ビット加算合計値

zm_exclusive:				*V3 エクスクルーシブメッセージの送信
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d2
	move.l	par3+val(sp),d3
	move.l	par3+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_EXCLUSIVE
	bra	ok_0

zm_set_eox_wait:			*V3 EOX送信後のウェイトを設定する
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d2
	Z_MUSIC	#ZM_SET_EOX_WAIT
	bra	ok_ret			*>d0.l=それまでのウェイト値

zm_midi_inp1:				*V3 MIDIデータの1バイト入力
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d2
	Z_MUSIC	#ZM_MIDI_INP1
	bra	ok_ret			*>d0.l=data

zm_midi_out1:				*V3 MIDIデータの1バイト出力
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d2
	Z_MUSIC	#ZM_MIDI_OUT1
	tst.l	d0
	bne	error
	bra	ok_0

zm_midi_rec:				*V3 MIDIデータのレコーディング開始
	move.l	par1+val(sp),d1
	Z_MUSIC	#ZM_MIDI_REC
	tst.l	d0
	bne	error
	bra	ok_0

zm_midi_rec_end:			*V3 MIDIデータのレコーディング終了
	move.l	par1+val(sp),d1
	Z_MUSIC	#ZM_MIDI_REC_END
	tst.l	d0
	bne	error
	bra	ok_0

zm_gs_reset:				*V3 GS音源の初期化
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d3
	Z_MUSIC	#ZM_GS_RESET
	tst.l	d0
	bne	error
	bra	ok_0

zm_gs_partial_reserve:			*V3 GS音源のパーシャルリザーブ
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d3
	move.l	par3+val(sp),a1
	cmpi.w	#16-1,dim1(a1)
	bne	mz_illegal_arry		*配列のサイズが違う
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_GS_PARTIAL_RESERVE
	tst.l	d0
	bne	error
	bra	ok_0

zm_gs_reverb:				*V3 GS音源のリバーブ・パラメータの設定
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d2
	move.l	par3+val(sp),d3
	move.l	par4+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_GS_REVERB
	tst.l	d0
	bne	error
	bra	ok_0

zm_gs_chorus:				*V3 GS音源のコーラス・パラメータの設定
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d2
	move.l	par3+val(sp),d3
	move.l	par4+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_GS_CHORUS
	tst.l	d0
	bne	error
	bra	ok_0

zm_gs_part_parameter:			*V3 GS音源のパート・パラメータの設定
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d2
	move.l	par3+val(sp),d3
	move.l	par4+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_GS_PART_PARAMETER
	tst.l	d0
	bne	error
	bra	ok_0

zm_gs_drum_setup:			*V3 GS音源のドラム・セットアップ設定
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d2
	move.l	par3+val(sp),d3
	move.l	par4+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_GS_DRUM_SETUP
	tst.l	d0
	bne	error
	bra	ok_0

zm_gs_drum_name:			*V3 GS音源のドラム・セット名設定
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d2
	move.l	par3+val(sp),d3
	move.l	par4+val(sp),a1		*a1.l=文字列ポインタ
	Z_MUSIC	#ZM_GS_DRUM_NAME
	tst.l	d0
	bne	error
	bra	ok_0

zm_gs_print:				*V3 GS音源の画面へのメッセージ出力
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d2
	move.l	par3+val(sp),d3
	move.l	par4+val(sp),a1		*a1.l=文字列ポインタ
	Z_MUSIC	#ZM_GS_PRINT
	tst.l	d0
	bne	error
	bra	ok_0

zm_gs_display:				*V3 GS音源の画面へのドットパターン出力
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d2
	move.l	par3+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_GS_DISPLAY
	tst.l	d0
	bne	error
	bra	ok_0

zm_gm_system_on:			*V3 GM音源のリセット
	move.l	par1+val(sp),d1
	Z_MUSIC	#ZM_GM_SYSTEM_ON
	tst.l	d0
	bne	error
	bra	ok_0

zm_sc88_mode_set:			*V3 SC88モード設定
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d3
	Z_MUSIC	#ZM_SC88_MODE_SET
	tst.l	d0
	bne	error
	bra	ok_0

zm_sc88_reverb:				*V3 SC88のリバーブ・パラメータの設定
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d2
	move.l	par3+val(sp),d3
	move.l	par4+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_SC88_REVERB
	tst.l	d0
	bne	error
	bra	ok_0

zm_sc88_chorus:				*V3 SC88のコーラス・パラメータの設定
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d2
	move.l	par3+val(sp),d3
	move.l	par4+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_SC88_CHORUS
	tst.l	d0
	bne	error
	bra	ok_0

zm_sc88_delay:				*V3 SC88のディレイ・パラメータの設定
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d2
	move.l	par3+val(sp),d3
	move.l	par4+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_SC88_DELAY
	tst.l	d0
	bne	error
	bra	ok_0

zm_sc88_equalizer:			*V3 SC88のイコライザ・パラメータの設定
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d2
	move.l	par3+val(sp),d3
	move.l	par4+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_SC88_EQUALIZER
	tst.l	d0
	bne	error
	bra	ok_0

zm_sc88_part_parameter:			*V3 SC88のパート・パラメータの設定
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d2
	move.l	par3+val(sp),d3
	move.l	par4+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_SC88_PART_PARAMETER
	tst.l	d0
	bne	error
	bra	ok_0

zm_sc88_drum_setup:			*V3 SC88のドラム・セットアップ設定
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d2
	move.l	par3+val(sp),d3
	move.l	par4+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_SC88_DRUM_SETUP
	tst.l	d0
	bne	error
	bra	ok_0

zm_sc88_drum_name:			*V3 SC88のドラム・セット名設定
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d2
	move.l	par3+val(sp),d3
	move.l	par4+val(sp),a1		*a1.l=文字列ポインタ
	Z_MUSIC	#ZM_SC88_DRUM_NAME
	tst.l	d0
	bne	error
	bra	ok_0

zm_sc88_user_inst:			*V3 SC88のユーザー音色の設定
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d2
	move.l	par3+val(sp),d3
	move.l	par4+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_SC88_USER_INST
	tst.l	d0
	bne	error
	bra	ok_0

zm_sc88_user_drum:			*V3 SC88のユーザードラムセットの設定
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d2
	move.l	par3+val(sp),d3
	move.l	par4+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_SC88_USER_DRUM
	tst.l	d0
	bne	error
	bra	ok_0

zm_mt32_reset:				*V3 MT32の初期化
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d3
	Z_MUSIC	#ZM_MT32_RESET
	tst.l	d0
	bne	error
	bra	ok_0

zm_mt32_partial_reserve:		*V3 MT32のパーシャルリザーブ
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d3
	move.l	par3+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_MT32_PARTIAL_RESERVE
	tst.l	d0
	bne	error
	bra	ok_0

zm_mt32_reverb:				*V3 MT32のリバーブパラメータの設定
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d2
	move.l	par3+val(sp),d3
	move.l	par4+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_MT32_REVERB
	tst.l	d0
	bne	error
	bra	ok_0

zm_mt32_part_setup:			*V3 MT32のパート・パラメータの設定
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d2
	move.l	par3+val(sp),d3
	move.l	par4+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_MT32_PART_SETUP
	tst.l	d0
	bne	error
	bra	ok_0

zm_mt32_drum:				*V3 MT32のドラム・セットアップ設定
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d2
	move.l	par3+val(sp),d3
	move.l	par4+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_MT32_DRUM
	tst.l	d0
	bne	error
	bra	ok_0

zm_mt32_common:				*V3 MT32のコモン・パラメータの設定
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d2
	move.l	par3+val(sp),d3
	move.l	par4+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_MT32_COMMON
	tst.l	d0
	bne	error
	bra	ok_0

zm_mt32_partial:			*V3 MT32のパーシャル・パラメータ設定
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d2
	move.l	par3+val(sp),d3
	move.l	par4+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_MT32_PARTIAL
	tst.l	d0
	bne	error
	bra	ok_0

zm_mt32_patch:				*V3 MT32のパッチ・パラメータ設定
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d2
	move.l	par3+val(sp),d3
	move.l	par4+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_MT32_PATCH
	tst.l	d0
	bne	error
	bra	ok_0

zm_mt32_print:				*V3 MT32の画面へのメッセージ出力
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d2
	move.l	par3+val(sp),d3
	move.l	par4+val(sp),a1
	Z_MUSIC	#ZM_MT32_PRINT
	tst.l	d0
	bne	error
	bra	ok_0

zm_u220_setup:				*V3 U220のセットアップ・パラメータの設定
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d3
	move.l	par3+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_U220_SETUP
	tst.l	d0
	bne	error
	bra	ok_0

zm_u220_part_setup:			*V3 U220の(テンポラリパッチ)パートセットアップ・パラメータの設定
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d3
	move.l	par3+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_U220_PART_SETUP
	tst.l	d0
	bne	error
	bra	ok_0

zm_u220_common:				*V3 U220の(テンポラリパッチ)コモン・パラメータの設定
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d3
	move.l	par3+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_U220_COMMON
	tst.l	d0
	bne	error
	bra	ok_0

zm_u220_timbre:				*V3 U220のティンバー・パラメータの設定
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d3
	move.l	par3+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_U220_TIMBRE
	tst.l	d0
	bne	error
	bra	ok_0

zm_u220_drums_setup:			*V3 U220の(テンポラリパッチ)パッチ・ドラム・セットアップ設定
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d3
	move.l	par3+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_U220_DRUM_SETUP
	tst.l	d0
	bne	error
	bra	ok_0

zm_u220_drums_inst:			*V3 U220の(テンポラリパッチ)ドラム音色設定
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d3
	move.l	par3+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_U220_DRUM_INST
	tst.l	d0
	bne	error
	bra	ok_0

zm_u220_print:				*V3 U220の画面へのメッセージ出力
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d2
	move.l	par3+val(sp),d3
	move.l	par4+val(sp),a1
	Z_MUSIC	#ZM_U220_PRINT
	tst.l	d0
	bne	error
	bra	ok_0

zm_m1_setup:				*V3 M1のSEQ-SONG0のMIDIチャンネルの設定
	move.l	par1+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_M1_SETUP
	tst.l	d0
	bne	error
	bra	ok_0

zm_m1_part_setup:			*V3 M1のSEQ-SONG0のトラックパラメータの設定
	move.l	par1+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_M1_PART_SETUP
	tst.l	d0
	bne	error
	bra	ok_0

zm_m1_effect_setup:			*V3 M1のSEQ-SONG0のエフェクトパラメータの設定
	move.l	par1+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_M1_EFFECT_SETUP
	tst.l	d0
	bne	error
	bra	ok_0

zm_m1_print:				*V3 M1のSEQ-SONG0のタイトル設定
	move.l	par1+val(sp),d2
	move.l	par2+val(sp),a1
	Z_MUSIC	#ZM_M1_PRINT
	tst.l	d0
	bne	error
	bra	ok_0

zm_send_to_m1:				*V3 M1へパラメータを送信する
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d3
	Z_MUSIC	#ZM_SEND_TO_M1
	tst.l	d0
	bne	error
	bra	ok_0

zm_pcm_read:				*V3 PCMファイルの登録
	moveq.l	#0,d1
	move.w	par1+val+2(sp),d1
	tst.b	par2+val+3(sp)
	bpl	@f
	bset.l	#31,d1		*加工有りマーク
@@:
	moveq.l	#0,d2
	move.b	par3+val+3(sp),d2	*登録タイプ
	lsl.w	#8,d2
	move.b	par4+val+3(sp),d2	オリジナルキー
	swap	d2
	Z_MUSIC	#ZM_PCM_READ
	move.l	a0,d0
	bne	ok_ret
	bra	error		*a0.l=0はエラー

zm_pcm_erase:				*V3 PCMファイルの登録取消
	move.l	par1+val(sp),d1
	suba.l	a1,a1			*erase mode
	Z_MUSIC	#ZM_PCM_READ
	tst.l	d0
	bne	error
	bra	ok_0

zm_register_zpd:			*V3 ZPDの登録
	move.l	par1+val(sp),a1		*filename
	Z_MUSIC	#ZM_REGISTER_ZPD
	tst.l	d0
	bne	error
	bra	ok_0

zm_set_zpd_table:			*V3 ZPDテーブルの登録
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_SET_ZPD_TABLE
	tst.l	d0
	bne	error
	bra	ok_0

zm_exec_subfile:			*V3 サブファイルの読み込みと実行
	move.l	par1+val(sp),a1		*filename
	Z_MUSIC	#ZM_EXEC_SUBFILE
	tst.l	d0
	bne	error
	bra	ok_0

zm_transmit_midi_dump:			*V3 MIDIデータファイルの転送
	move.l	par1+val(sp),d1		*port number
	move.l	par2+val(sp),a1		*filename
	Z_MUSIC	#ZM_TRANSMIT_MIDI_DUMP
	tst.l	d0
	bne	error
	bra	ok_0

zm_set_wave_form1:			*V3 波形メモリの登録1
	move.l	par1+val(sp),d1		*wave number
	move.l	par2+val(sp),a1		*data buffer
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_SET_WAVE_FORM1
	tst.l	d0
	bne	error
	bra	ok_0

zm_set_wave_form2:			*V3 波形メモリの登録2
	move.l	par1+val(sp),d1		*wave number
	move.l	par2+val(sp),a1		*data buffer
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_SET_WAVE_FORM2
	tst.l	d0
	bne	error
	bra	ok_0

zm_obtain_events:			*V3 各種イベントの取得
	move.l	par1+val(sp),d1		*omt
	move.l	par2+val(sp),a1		*data buffer
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_OBTAIN_EVENTS
	move.l	a0,d0
	beq	error
	bra	ok_ret

zm_loop_control:			*V3 現在の演奏のループ回数を取得する
	move.l	par1+val(sp),d1
	Z_MUSIC	#ZM_LOOP_CONTROL
	cmpi.l	#-1,d0
	beq	error			*-1はエラー
	bra	ok_ret

zm_mask_tracks:				*V3 トラックマスク
	move.l	par1+val(sp),a1		*buffer
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_MASK_TRACKS
	move.l	a0,d0
	beq	error
	bra	ok_ret

zm_mask_all_tracks:			*V3 全トラックマスク
	move.l	par1+val(sp),d1
	suba.l	a1,a1
	Z_MUSIC	#ZM_MASK_TRACKS
	tst.l	d0
	bne	error
	bra	ok_0

zm_solo_track:				*V3 ソロトラック演奏
	move.l	par1+val(sp),d1
	lea	1.w,a1
	Z_MUSIC	#ZM_MASK_TRACKS
	tst.l	d0
	bne	error
	bra	ok_0

zm_mask_channels:			*V3 チャンネルマスク
	move.l	par1+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_MASK_CHANNELS
	tst.l	d0
	bne	error
	bra	ok_0

zm_mask_all_channels:			*V3 全チャンネルマスク
	move.l	par1+val(sp),d1
	suba.l	a1,a1
	Z_MUSIC	#ZM_MASK_CHANNELS
	tst.l	d0
	bne	error
	bra	ok_0

zm_solo_channel:			*V3 ソロチャンネル演奏
	move.l	par1+val(sp),d1
	lea	1.w,a1
	Z_MUSIC	#ZM_MASK_CHANNELS
	tst.l	d0
	bne	error
	bra	ok_0

zm_set_ch_output_level:			*V3 各チャンネルの出力レベルの設定
	move.l	par1+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_SET_CH_OUTPUT_LEVEL
	tst.l	d0
	bne	error
	bra	ok_0

zm_set_tr_output_level:			*V3 各トラックの出力レベルの設定
	move.l	par1+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_SET_TR_OUTPUT_LEVEL
	tst.l	d0
	bne	error
	bra	ok_0

zm_master_fader:			*V3 マスターフェーダーの設定
	move.l	par1+val(sp),a1
	lea	dim1_data(a1),a1
	Z_MUSIC	#ZM_MASTER_FADER
	tst.l	d0
	bne	error
	bra	ok_0

zm_get_fader_status:			*V3 フェーダーの状態取得
	Z_MUSIC	#ZM_GET_FADER_STATUS
	bra	ok_ret

zm_get_play_time:			*V3 演奏時間の取得
	Z_MUSIC	#ZM_GET_PLAY_TIME
	bra	ok_ret

zm_get_1st_comment:			*V3 演奏中の曲のコメントを取り出す
	Z_MUSIC	#ZM_GET_1ST_COMMENT
	move.l	a0,d0
	bra	ok_ret

zm_get_timer_mode:			*V3 現在のテンポソースとなっているタイマの種類を返す
	Z_MUSIC	#ZM_GET_TIMER_MODE
	bra	ok_ret

zm_get_track_table:			*V3 演奏トラックテーブルのアドレスを得る
	Z_MUSIC	#ZM_GET_TRACK_TABLE
	move.l	a0,d0
	bra	ok_ret

zm_get_track_table_se:			*V3 効果音演奏トラックテーブルのアドレスを得る
	Z_MUSIC	#ZM_GET_TRACK_TABLE
	move.l	a0,d0
	bra	ok_ret

zm_get_play_work:			*V3 演奏トラックワークのアドレスを得る
	move.l	par1+val(sp),d1
	Z_MUSIC	#ZM_GET_PLAY_WORK
	move.l	a0,d0
	bra	ok_ret

zm_get_play_work_se:			*V3 効果音演奏トラックワークのアドレスを得る
	move.l	par1+val(sp),d1
	Z_MUSIC	#ZM_GET_PLAY_WORK
	bra	ok_ret

zm_get_buffer_information:		*V3 バッファ・アドレステーブルのアドレス
	Z_MUSIC	#ZM_GET_BUFFER_INFORMATION
	move.l	a0,d0
	bra	ok_ret

zm_zmsc_status:				*V3 ZMUSICの状態ワークのアドレス
	Z_MUSIC	#ZM_GET_ZMSC_STATUS
	move.l	a0,d0
	bra	ok_ret

zm_calc_total:				*V3 ZMDの演奏時間やトータルステップタイムなどの計算
	move.l	par1+val(sp),a1		*a1=zmd addr
	lea	dim1_data(a1),a1
	move.l	par2+val(sp),a2		*a2=result ptr
	Z_MUSIC	#ZM_CALC_TOTAL
	move.l	a0,(a2)			*エラーリストのアドレスを格納してやる
	bra	ok_ret

zm_occupy_zmusic:			*V3 ZMUSICの占有
	move.l	par1+val(sp),d1
	Z_MUSIC	#ZM_OCCUPY_ZMUSIC
	bra	ok_ret

zm_occupy_compiler:			*V3 コンパイラの占有
	move.l	par1+val(sp),d1
	Z_MUSIC	#ZM_OCCUPY_COMPILER
	bra	ok_ret

zm_store_error:				*V3 エラーコードのストア
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d2
	move.l	par3+val(sp),a1		*pointer
	Z_MUSIC	#ZM_STORE_ERROR
	move.l	a0,(a1)
	bra	ok_ret

zm_print_error:				*V3 エラーメッセージの表示
	move.w	par1+val+2(sp),d1
	swap	d1
	move.w	par2+val+2(sp),d1
	move.l	par3+val(sp),d2
	move.l	par4+val(sp),a1		*STR-ZMD
	tst.b	(a1)
	bne	@f
	suba.l	a1,a1			*no ZMD name
@@:
	move.l	par5+val(sp),a2		*srcaddr
	lea	dim1_data(a2),a2
	tst.b	(a2)
	bne	@f
	suba.l	a2,a2
@@:
	move.l	par6+val(sp),a3		*STR-srcname
	tst.b	(a3)
	bne	@f
	suba.l	a3,a3			*no srcname
@@:
	move.l	par7+val(sp),a5		*err tbl addr
	move.l	par8+val(sp),a4		*出力バッファアドレス格納配列
	Z_MUSIC	#ZM_PRINT_ERROR		*a4=**buff
	move.l	a0,(a4)
	bra	ok_ret

zm_get_mem:				*V3 メモリの確保
	move.l	par1+val(sp),d2
	move.l	par2+val(sp),d3
	Z_MUSIC	#ZM_GET_MEM
	move.l	a0,d0
	bra	ok_ret

zm_enlarge_mem:				*V3 メモリブロックのサイズの変更
	move.l	par1+val(sp),d2
	move.l	par2+val(sp),a1
	Z_MUSIC	#ZM_ENLARGE_MEM
	move.l	a0,d0
	bra	ok_ret

zm_free_mem:				*V3 メモリブロックの解放
	move.l	par1+val(sp),a1
	Z_MUSIC	#ZM_FREE_MEM
	bra	ok_ret

zm_free_mem2:				*V3 特定の用途IDを持ったメモリブロックの解放
	move.l	par1+val(sp),d3
	Z_MUSIC	#ZM_FREE_MEM2
	bra	ok_ret

zm_exchange_memid:			*V3 メモリブロックの用途IDの変更
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d2
	move.l	par3+val(sp),d3
	move.l	par4+val(sp),a1
	Z_MUSIC	#ZM_EXCHANGE_MEMID
	bra	ok_ret

zm_init_all:				*V3 ZMUSICの全初期化を行う
	Z_MUSIC	#ZM_INIT_ALL
	bra	ok_ret

zm_int_start:				*V3 割り込み開始制御
	move.l	par1+val(sp),d1
	Z_MUSIC	#ZM_INT_START
	bra	ok_0

zm_int_stop:				*V3 割り込み停止制御
	move.l	par1+val(sp),d1
	Z_MUSIC	#ZM_INT_STOP
	bra	ok_0

zm_control_tempo:			*V3 テンポ設定の主導権設定
	move.l	par1+val(sp),d1
	Z_MUSIC	#ZM_CONTROL_TEMPO
	tst.l	d0
	bne	error
	bra	ok_0

zm_convert_pcm:				*V3 PCMデータの変換を行う
	move.l	par1+val(sp),d1
	move.l	par2+val(sp),d2
	move.l	par3+val(sp),a1
	lea	dim1_data(a1),a1
	move.l	par4+val(sp),a2
	lea	dim1_data(a2),a2
	Z_MUSIC	#ZM_CONVERT_PCM
	bra	ok_ret

fnc_end:

wrt_str:				*文字データのバッファへの書き込み
	* < a0=source str pointer
	* - all
	movem.l	d0/a0,-(sp)
@@:
	move.b	(a0)+,d0
	beq	@f
	bsr	do_wrt_zms_b
	bra	@b
@@:
	movem.l	(sp)+,d0/a0
	rts

wrt_trks:			*チャンネル番号を書く
	* < a0.l=sp
reglist	reg	d0-d4/a0
	movem.l	reglist,-(sp)
	moveq.l	#0,d1
	moveq.l	#0,d2
	moveq.l	#10-1,d3	*basicのパラメータマックスが１０個のため
	moveq.l	#0,d4		*reset marker
	bra	@f
chs_lp:
	moveq	#',',d0
	bsr	do_wrt_zms_b
@@:
	tst.w	par1(a0,d1.w)	*省略?
	bmi	next_chs
	move.l	par1+val(a0,d1.w),d0	*get trk number
	st.b	d4		*mark
	bsr	wrt_num
	add.w	#next_par,d1		*次へ
	dbra	d3,chs_lp
	movem.l	(sp)+,reglist
	rts
next_chs:
	add.w	#next_par,d1		*次へ
	dbra	d3,@b
	movem.l	(sp)+,reglist
	rts

self_output:				*ZMSへ出力
	* < d3=size
	* < a5=data address
	move.w	#%0_000_01,-(sp)
	pea	ZMS(pc)
	DOS	_OPEN
	addq.w	#6,sp
	move.l	d0,d5		*d5.w=file handle

	move.l	d3,-(sp)	*size
	pea	(a5)		*data address
	move.w	d5,-(sp)
	DOS	_WRITE
	lea	10(sp),sp

	move.w	d5,-(sp)
	DOS	_CLOSE
	addq.w	#2,sp
	rts

read:
	* < d5.l=file handle
	* > a5=data address
	* > d3.l=size
	* X d0
	move.w	#2,-(sp)		*ファィルの長さを調べる
	clr.l	-(sp)
	move.w	d5,-(sp)
	DOS	_SEEK
 	addq.w	#8,sp			*d0.l=file length
	move.l	d0,d3			*d3=length
	bne	@f
	addq.w	#4,sp
	bra	mz_illegal_filesize	*file size=0
@@:
	move.l	d0,-(sp)
	move.w	#2,-(sp)
	DOS	_MALLOC2
	addq.w	#6,sp
	tst.l	d0
	bpl	@f
	addq.w	#4,sp
	bra	mz_out_of_memory	*OUT OF MEMORY
@@:
	move.l	d0,a5

	clr.w	-(sp)		*ファイルポインタを元に戻す
	clr.l	-(sp)
	move.w	d5,-(sp)
	DOS	_SEEK
	addq.w	#8,sp

	move.l	d3,-(sp)	*push size
	pea	(a5)		*push addr
	move.w	d5,-(sp)	*file handle
	DOS	_READ
	lea	10(sp),sp
	cmp.l	d0,d3
	bne	@f
	addq.w	#4,sp
	bra	mz_read_error		*読み込み失敗
@@:
	move.w	d5,-(sp)	*close
	DOS	_CLOSE
	addq.l	#2,sp
	rts

do_wrt_zms_l:
	rol.l	#8,d0
	bsr	do_wrt_zms_b
	rol.l	#8,d0
	bsr	do_wrt_zms_b
	rol.l	#8,d0
	bsr	do_wrt_zms_b
	rol.l	#8,d0
	bra	do_wrt_zms_b

do_wrt_zms_w:
	rol.w	#8,d0
	bsr	do_wrt_zms_b
	rol.w	#8,d0

do_wrt_zms_b:
reglist	reg	d0-d3/a0-a2
	tst.l	zms_buffer_addr-work(a6)
	beq	error_dwzb
	movem.l	reglist,-(sp)
	move.l	zms_buffer_addr(pc),a1
	move.l	zms_buffer_ptr(pc),d1
	move.b	d0,(a1,d1.l)
	addq.l	#1,d1
	move.l	d1,zms_buffer_ptr-work(a6)
	move.l	zms_buffer_size(pc),d2
	cmp.l	d2,d1				*バッファのサイズチェック
	bne	1f				*まだ不足していない
	addq.l	#3,d2
	andi.w	#$fffc,d2			*Make it long word border
	move.l	d2,d3				*後で使う
	add.l	#zms_buffer_default_size,d2	*大きく取り直す
	move.l	d2,zms_buffer_size-work(a6)	*new size
	move.l	d2,-(sp)
	pea	(a1)
	DOS	_SETBLOCK
	addq.w	#8,sp
	tst.l	d0
	beq	1f		*no error
	move.l	d2,-(sp)	*SETBLOCK出来ない時は新たにメモリ確保
	DOS	_MALLOC
	addq.w	#4,sp
	tst.l	d0
	bmi	err_exit_enlmm	*error
	move.l	d0,a0
	move.l	d0,a2
	pea	(a1)
@@:				*旧メモリ内容を新メモリエリアへ複写
	move.l	(a1)+,(a2)+
	subq.l	#4,d3
	bne	@b
	DOS	_MFREE		*元のメモリ開放
	addq.w	#4,sp
	move.l	a0,zms_buffer_addr-work(a6)	*new addr
1:
	movem.l	(sp)+,reglist
	rts
err_exit_enlmm:			*error
	movem.l	(sp)+,reglist
	addq.w	#4,sp		*=rts
	bra	mz_out_of_memory
error_dwzb:
	addq.w	#4,sp
	bra	mz_v2_command_error

chk_kanji:
	tst.b	d0
	bpl	@f		*normal characters
	cmpi.b	#$a0,d0		*漢字か
	bcs	cknj_yes
	cmpi.b	#$df,d0
	bls	@f
cknj_yes:
	move.w	#CCR_NEGA,ccr	*yes
	rts
@@:
	move.w	#CCR_ZERO,ccr	*no
	rts

wrt_num:			*d0の値を文字数列に変換しバッファへ書き込む
	* < d0.l=value
	* - all
reglist	reg	d1-d5/a1
	movem.l	reglist,-(sp)
	moveq.l	#0,d4
	move.l	d0,d5
	lea	exp_tbl(pc),a1
	moveq.l	#10-1,d1
ex_loop0:
	moveq.l	#0,d2
	move.l	(a1)+,d3
ex_loop1:
	or	d3,d3		*clr carry
	sub.l	d3,d5
	bcs	xbcd_str
	addq.b	#1,d2
	bra	ex_loop1
xbcd_str:
	add.l	d3,d5
	tst.b	d2
	bne	nml_ktset
	tst.b	d4
	beq	nml_lp_ope
nml_ktset:
	st	d4
	add.b	#'0',d2
	move.l	d2,d0
	bsr	do_wrt_zms_b
nml_lp_ope:
	dbra	d1,ex_loop0
	tst.l	d4
	bne	set_suji_end
	moveq	#'0',d0
	bsr	do_wrt_zms_b
set_suji_end:
	movem.l	(sp)+,reglist
	rts

wrt_num2:			*d0の値を文字数列に変換しバッファへ書き込む
	* < d0.l=value		*3桁固定
	* - all
reglist	reg	d1-d5/a1
	movem.l	reglist,-(sp)
	moveq	#0,d4
	move.l	d0,d5
	lea	exp_tbl+28(pc),a1
	moveq.l	#3-1,d1
_ex_loop0:
	moveq.l	#0,d2
	move.l	(a1)+,d3
_ex_loop1:
	or	d3,d3		*clr carry
	sub.l	d3,d5
	bcs	_xbcd_str
	addq.b	#1,d2
	bra	_ex_loop1
_xbcd_str:
	add.l	d3,d5
	tst.b	d2
	bne	_nml_ktset
	tst.b	d4
	bne	_nml_ktset
	moveq	#' ',d0
	bsr	do_wrt_zms_b
	bra	_nml_lp_ope
_nml_ktset:
	st	d4
	add.b	#'0',d2
	move.l	d2,d0
	bsr	do_wrt_zms_b
_nml_lp_ope:
	dbra	d1,_ex_loop0
	tst.b	d4
	bne	_set_suji_end
	moveq	#'0',d0
	bsr	do_wrt_zms_b
_set_suji_end:
	movem.l	(sp)+,reglist
	rts

wrt_num3:			*16進数文字列(2bytes)で書き込み
	* < d0=data value
	* - all
	movem.l	d0-d2,-(sp)
	move.l	d0,d2
	moveq	#'$',d0
	bsr	do_wrt_zms_b
	move.b	d2,d1
	lsr.b	#4,d1
	add.b	#$30,d1
	cmpi.b	#'9',d1
	bls	its_hex8
	addq.b	#7,d1
its_hex8:
	move.b	d1,d0
	bsr	do_wrt_zms_b

	andi.b	#$0f,d2
	add.b	#$30,d2
	cmpi.b	#'9',d2
	bls	its_hex8_
	addq.b	#7,d2
its_hex8_:
	move.l	d2,d0
	bsr	do_wrt_zms_b
	movem.l	(sp)+,d0-d2
	rts

mk_capital:			*小文字→大文字(英字以外の場合はそのままthrough out)
	* < d0.b=letter chr
	cmpi.b	#'a',d0
	bcs	exit_mkcptl
	cmpi.b	#'z',d0
	bhi	exit_mkcptl
	andi.w	#$df,d0		*わざと.w
exit_mkcptl:
	rts

check_zm3:			*ZMUSIC/MUSICZ.FNC状態チェック
	lea	work(pc),a6
	tst.b	zm3_flg-work(a6)
	beq	1f
	rts
1:
	addq.w	#4,sp
	bra	mz_no_zmusic_error

compile_zms:				*コンパイル
reglist	reg	d1-d3/a0-a1
	tst.b	compiler_flg-work(a6)
	bne	@f
	addq.w	#4,sp
	bra	mz_no_compiler_error	*コンパイラが常駐していない
@@:
	movem.l	reglist,-(sp)
	move.w	#$0d0a,d0
	bsr	do_wrt_zms_w
	moveq.l	#0,d3
	tst.b	detect_mode
	beq	1f
	move.l	#ID_ZMD,d3		*全ZMDを解放
	Z_MUSIC	#ZM_FREE_MEM2
	move.l	zms_buffer_addr(pc),a1
	move.l	zms_buffer_ptr(pc),d2
	move.l	#ZMC_ERL+1,d1
	Z_MUSIC	#ZM_COMPILER
	move.l	d0,d3			*n of err
	move.l	(a0),d2
	move.l	a0,a1			*>a0.l=エラーテーブル/結果テーブルの解放
	Z_MUSIC	#ZM_FREE_MEM		*エラーテーブル/結果テーブルの解放
	move.l	d2,d0			*d0.l=error
	andi.l	#$ffff,d0
1:
	tst.l	d3			*check n of err
	movem.l	(sp)+,reglist
	bne	get_ermstj
	rts

go_play:					*演奏またはZMSファイル出力
reglist	reg	d0-d3/d5/a0-a1
	movem.l	reglist,-(sp)
	move.l	#ID_ZMD,d3		*全ZMDを解放
	Z_MUSIC	#ZM_FREE_MEM2
	move.l	zms_buffer_addr(pc),a1
	move.l	zms_buffer_ptr(pc),d2
	move.l	#ZMC_ERL+1,d1
	Z_MUSIC	#ZM_COMPILER
	move.l	a0,zmd_addr-work(a6)
	beq	error_go_play		*エラーが発生している
	move.l	d0,n_of_err-work(a6)	*n of err
	bne	error_go_play		*エラーが発生している

	tst.b	out_flg-work(a6)		*ファイル出力か演奏か
	beq	@f

	move.l	zmd_addr(pc),a1
	Z_MUSIC	#ZM_CALC_TOTAL
	move.l	a0,a1			*>a0.l=エラーテーブル/結果テーブルの解放
	Z_MUSIC	#ZM_FREE_MEM		*エラーテーブル/結果テーブルの解放

	move.w	#32,-(sp)
	pea	gene_fn(pc)
	DOS	_CREATE
	addq.w	#6,sp
	move.l	d0,d5				*d5.w=file handle
	bmi	error_go_play

	move.l	zms_buffer_ptr(pc),d2
	move.l	d2,-(sp)			*data size
	move.l	zms_buffer_addr(pc),-(sp)	*data addr
	move.w	d5,-(sp)
	DOS	_WRITE
	lea	10(sp),sp
	cmp.l	d2,d0
	bne	error_go_play

	move.w	d5,-(sp)
	DOS	_CLOSE
	addq.w	#2,sp
	bra	1f
@@:
	moveq.l	#0,d2			*dummy size
	move.l	zmd_addr(pc),a1
	addq.w	#8,a1			*skip header
	Z_MUSIC	#ZM_PLAY_ZMD
	tst.l	d0
	bne	error_go_play

	move.l	zmd_addr(pc),a1
	Z_MUSIC	#ZM_CALC_TOTAL
	move.l	a0,a1			*>a0.l=エラーテーブル/結果テーブルの解放
	Z_MUSIC	#ZM_FREE_MEM		*エラーテーブル/結果テーブルの解放
1:
	moveq.l	#0,d0			*no error mark
	movem.l	(sp)+,reglist
	rts

error_go_play:
	moveq.l	#-1,d0
	movem.l	(sp)+,reglist
	rts

ok_0:					*戻り値無しでリータン
	moveq.l	#0,d0
	lea	ret_buf(pc),a0
	move.l	d0,6(a0)		*戻り値書き込み(low long word)
	rts

ok_ret:					*戻り値有りでリータン
	lea	ret_buf(pc),a0
	move.l	d0,6(a0)		*戻り値書き込み(low long word)
	moveq.l	#0,d0
	rts

error:					*エラー発生時の処理
	tst.b	zm3_flg-work(a6)
	beq	mz_no_zmusic_error	*ZMUSICがない
	move.l	zmd_addr(pc),a0		*コンパイル時に発生したエラーのテーブル
	lea	mz_compile_error_mes(pc),a1
	tst.l	n_of_err-work(a6)
	bne	@f
	moveq.l	#-1,d1
	Z_MUSIC	#ZM_STORE_ERROR		*> d0.l=n of err,a0.l=error tbl
	lea	mz_unknown_error_mes(pc),a1
	tst.l	d0			*n of err
	beq	@f			*エラーなし
	move.l	(a0),d1
	move.l	a0,a1
	Z_MUSIC	#ZM_FREE_MEM
	andi.l	#$ffff,d1		*エラー番号だけほしい
	add.w	d1,d1
	move.w	err_mes_tbl_j(pc,d1.w),d0
	lea	err_mes_tbl_j(pc,d0.w),a1	*a1.l=エラーメッセージ
@@:
	moveq.l	#1,d0			*error mark
	rts

get_ermstj:					*compile_error
	addq.w	#4,sp
	tst.b	zm3_flg-work(a6)
	beq	mz_no_zmusic_error	*ZMUSICがない
	add.w	d0,d0
	move.w	err_mes_tbl_j(pc,d0.w),d0
	lea	err_mes_tbl_j(pc,d0.w),a1	*a1.l=エラーメッセージ
	moveq.l	#1,d0			*error mark
	rts

	.include	../zmerrmes.s

mz_v2_command_error:
	lea	mz_v2_command_error_mes(pc),a1
	bra	@f
mz_illegal_arry:
	lea	mz_illegal_arry_mes(pc),a1
	bra	@f
mz_no_zmusic_error:
	lea	mz_no_zmusic_error_mes(pc),a1
	bra	@f
mz_no_compiler_error:
	lea	mz_no_compiler_error_mes(pc),a1
	bra	@f
mz_illegal_parameter:
	lea	mz_illegal_parameter_mes(pc),a1
	bra	@f
mz_illegal_fader_speed:
	lea	mz_illegal_fader_speed_mes(pc),a1
	bra	@f
mz_nul_string_error:
	lea	mz_nul_string_error_mes(pc),a1
	bra	@f
mz_file_open_error:
	lea	mz_file_open_error_mes(pc),a1
	bra	@f
mz_illegal_track_number:
	lea	mz_illegal_track_number_mes(pc),a1
	bra	@f
mz_too_many_tracks:
	lea	mz_too_many_tracks_mes(pc),a1
	bra	@f
mz_buffer_too_small:
	lea	mz_buffer_too_small_mes(pc),a1
	bra	@f
mz_illegal_filesize:
	lea	mz_illegal_filesize_mes(pc),a1
	bra	@f
mz_out_of_memory:
	lea	mz_out_of_memory_mes(pc),a1
	bra	@f
mz_read_error:
	lea	mz_read_error_mes(pc),a1
@@:
	moveq.l	#1,d0			*error mark
	rts

	if	(debug.and.1)
debug2:					*デバグ用ルーチン(レジスタ値を表示／割り込み対応)
	movem.l	d0-d7/a0-a7,db_work
	clr.l	-(sp)
	DOS	_SUPER
	addq.w	#4,sp
	move.l	d0,-(sp)

	move.w	sr,db_work2		*save sr	(サブルーチン_get_hex32が必要)
	ori.w	#$700,sr		*mask int

	moveq.l	#%0011,d1
	IOCS	_B_COLOR

	lea	str__(pc),a1

	move.w	#$0d0a,(a1)+
	move.w	#$0d0a,(a1)+	*!
	move.w	#$0d0a,(a1)+	*!

	moveq.l	#8-1,d7
	lea	db_work(pc),a6
dbg2_lp01:
	move.l	(a6)+,d0
	bsr	_get_hex32
	addq.w	#8,a1
	cmpi.b	#4,d7
	bne	@f
	move.b	#' ',(a1)+
@@:
	move.b	#' ',(a1)+
	dbra	d7,dbg2_lp01

	move.b	#$0d,(a1)+
	move.b	#$0a,(a1)+

	moveq.l	#8-1,d7
dbg2_lp02:
	move.l	(a6)+,d0
	bsr	_get_hex32
	addq.w	#8,a1
	cmpi.b	#4,d7
	bne	@f
	move.b	#' ',(a1)+
@@:
	move.b	#' ',(a1)+
	dbra	d7,dbg2_lp02

	move.l	(a7),d0
	bsr	_get_hex32
	addq.w	#8,a1
*	move.b	#$0d,(a1)+
*	move.b	#$0a,(a1)+
	clr.b	(a1)+
	lea	str__(pc),a1
	IOCS	_B_PRINT
*@@:
*	btst.b	#5,$806.w
*	bne	@b

	move.w	db_work2(pc),sr	*get back sr
	DOS	_SUPER
	addq.w	#4,sp
	movem.l	db_work(pc),d0-d7/a0-a7
	rts

_get_hex32:			*値→16進数文字列(4bytes)
	* < d0=data value
	* < a1=格納したいアドレス
	* > (a1)=ascii numbers
	* - all
	movem.l	d0-d1/d4/a1,-(sp)
	addq.w	#8,a1
	clr.b	(a1)
	moveq.l	#8-1,d4
_gh_lp32:
	move.b	d0,d1
	andi.b	#$0f,d1
	add.b	#$30,d1
	cmpi.b	#'9',d1
	bls	_its_hex32
	addq.b	#7,d1
_its_hex32:
	move.b	d1,-(a1)
	lsr.l	#4,d0
	dbra	d4,_gh_lp32
	movem.l	(sp)+,d0-d1/d4/a1
	rts
		*デバッグ用ワーク
	.even
str__:		ds.b	96*2
db_work:	dcb.l	16,0		*for debug
db_work2:	dc.l	0
		dc.b	'REGI'
	endif

	.data
work:
ZMS:		.dc.b	'ZMS',0
CRLF:		.dc.b	13,10,0
dflt_fn:	.dc.b	'ZMUSIC.ZMS',0
rem1:	dc.b	"/",9," AF  OM  WF  SY  SP PMD AMD PMS AMS PAN",13,10,0
rem2:	dc.b	"/",9," AR  DR  SR  RR  SL  OL  KS  ML DT1 DT2 AME",13,10,0
rem3:	dc.b	9,"/",9," AL  FB  OM PAN  WF  SY  SP PMD AMD PMS AMS",13,10,0
rem4:	dc.b	"/  WG ",9," PC  PF PKF PBS WFM PCM PLW PWVS",13,10,0
rem5:	dc.b	13,10,"/ P-ENV",9,"DPT VLS TMK TM1 TM2 TM3 TM4 LV0 LV1 LV2 STL EDL",13,10,0 
rem6:	dc.b	13,10,"/ P-LFO",9," RT DPT MDS",13,10,0
rem7:	dc.b	13,10,"/  TVF ",9,"CUT RES KYF BSP BSL",13,10,0
rem8:	dc.b	13,10,"/TVFENV",9,"DPT VLS DPT TMK TM1 TM2 TM3 TM4 TM5 LV1 LV2 LV3 STL",13,10,0
rem9:	dc.b	13,10,"/  TVA ",9,"LVL VLS BP1 BL1 BP2 BL2",13,10,0
rem10:	dc.b	13,10,"/TVAENV",9,"TMK TMV TM1 TM2 TM3 TM4 TM5 LV1 LV2 LV3 STL",13,10,0
rem11:	dc.b	"/",9,"TMD TMN TML VLS CHP EAR EDR ESL ERR",13,10,0
rem12:	dc.b	13,10,"/",9,"PSC PSF BRL BRU CHA PAS ABD ABR DTD",13,10,0
rem13:	dc.b	13,10,"/",9,"VRT WFM DPT DLY RST MDP CHA PAS",13,10,0
rem14:	dc.b	"/  Tr",0
rem15:	dc.b	"PRG VOL KTR DTN PAN",13,10,0
i_data:	dc.b	$1a
fmvset:		dc.b	'.FM_VSET ',0
midi_dump:	dc.b	'.MIDI_DUMP ',0
midi_data:	dc.b	'.MIDI_DATA {',0
exclusive:	dc.b	'.EXCLUSIVE {',0
roland:		dc.b	'.ROLAND_EXCLUSIVE ',0
adpcm_list:	dc.b	'.ADPCM_LIST ',0
sc55_vr_:	dc.b	'.SC55_V_RESERVE ',0
sc55_rvb_:	dc.b	'.SC55_REVERB ',0
sc55_cho_:	dc.b	'.SC55_CHORUS ',0
sc55_pst_:	dc.b	'.SC55_PART_SETUP ',0
sc55_dst_:	dc.b	'.SC55_DRUM_SETUP ',0
sc55_prt_:	dc.b	'.SC55_PRINT ',0
sc55_dsp_:	dc.b	'.SC55_DISPLAY ',0
adpcm_block_:	dc.b	'.ADPCM_BLOCK_DATA ',0
mt32_pr_:	dc.b	'.MT32_P_RESERVE ',0
mt32_rvb_:	dc.b	'.MT32_REVERB ',0
mt32_pst_:	dc.b	'.MT32_PART_SETUP ',0
mt32_dst_:	dc.b	'.MT32_DRUM_SETUP ',0
mt32_cmn_:	dc.b	'.MT32_COMMON ',0
mt32_ptch_:	dc.b	'.MT32_PATCH ',0
mt32_prtl_:	dc.b	'.MT32_PARTIAL ',0
mt32_prt_:	dc.b	'.MT32_PRINT ',0
u220_prt_:	dc.b	'.U220_PRINT ',0
m_prt_:		dc.b	'.PRINT ',0
u220_setup_:	dc.b	'.U220_SETUP ',0
u220_cmn_:	dc.b	'.U220_COMMON ',0
u220_dst_:	dc.b	'.U220_DRUM_SETUP ',0
u220_pst_:	dc.b	'.U220_PART_SETUP ',0
u220_tmb_:	dc.b	'.U220_TIMBRE ',0
u220_dis_:	dc.b	'.U220_DRUM_INST ',0
m1_mdch_:	dc.b	'.M1_MIDI_CH {',0
m1_ptst_:	dc.b	'.M1_PART_SETUP {',0
m1_efct_:	dc.b	'.M1_EFFECT_SETUP {',0
m1_prt_:	dc.b	'.M1_PRINT "',0
send_m1_:	dc.b	'.SEND_TO_M1 ',0
fm_mstr_:	dc.b	'.FM_MASTER_VOLUME ',0
wvfm_:		dc.b	'.WAVE_FORM ',0
sc55_init_:	dc.b	'.SC55_INIT ',0
mt32_init_:	dc.b	'.MT32_INIT ',0
	.even
ret_buf:	dc.w	0	*+0
ret_buf_h:	dc.l	0	*+2 hi
ret_buf_l:	dc.l	0	*+6 low
zmd_play_wk:	dc.l	0
zm_ver_buf:	dc.w	0	*ZMUSICバージョンバッファ
open_fn:	dc.l	open_fn_

exp_tbl:
	dc.l	1000000000	*0
	dc.l	100000000	*4
	dc.l	10000000	*8
	dc.l	1000000		*12
	dc.l	100000		*16
	dc.l	10000		*20
	dc.l	1000		*24
	dc.l	100		*28
	dc.l	10		*32
	dc.l	1		*36

mz_unknown_error_mes:		dc.b	'正体不明のエラーが発生しました',0
mz_compile_error_mes:		dc.b	'ZMUSICコンパイラでエラーが発生しました',0
mz_no_zmusic_error_mes:		dc.b	'ZMUSICバージョン3.0以上が常駐していません',0
mz_no_compiler_error_mes:	dc.b	'ZMUSICコンパイラが常駐していません',0
mz_illegal_arry_mes:		dc.b	'配列の型が規定外です',0
mz_illegal_parameter_mes:	dc.b	'パラメータの値が規定外です',0
mz_illegal_fader_speed_mes:	dc.b	'フェーダー移動速度が規定外です',0
mz_nul_string_error_mes:	dc.b	'文字列が異常です',0
mz_file_open_error_mes:		dc.b	'ファイルのオープンに失敗しました',0
mz_illegal_track_number_mes:	dc.b	'トラック番号が規定外です',0
mz_too_many_tracks_mes:		dc.b	'トラック番号が多すぎます',0
mz_buffer_too_small_mes:	dc.b	'バッファサイズが小さすぎます',0
mz_illegal_filesize_mes:	dc.b	'ファイルサイズが異常です',0
mz_out_of_memory_mes:		dc.b	'メモリが不足しています',0
mz_read_error_mes:		dc.b	'ファイルの読み込みに失敗しました',0
mz_v2_command_error_mes:	dc.b	'MUSICZ.FNC V1.00～2.00のコマンドの使い方が不正です',0

detect_mode:	dc.b	0	*compile mode

title:
	dc.b	'MUSICZ.FNC '
	dc.b	$F3,'V',$F3,'E',$F3,'R',$F3,'S',$F3,'I',$F3,'O',$F3,'N'
	version
	test
	dc.b	' (C) 1991,96 '
	dc.b	'ZENJI SOFT',13,10,0
	.even
zm3_flg:		ds.b	1	*0:ZMUSICが常駐していない,1:常駐している
compiler_flg:		ds.b	1	*0:コンパイラが常駐していない,1:常駐している
out_flg:		ds.b	1	*0:generate mode off,1:on
	.even
zms_buffer_addr:	ds.l	1
zms_buffer_ptr:		ds.l	1
zms_buffer_size:	ds.l	1
n_of_err:		ds.l	1	*コンパイル時に発生したエラーの数
zmd_addr:		ds.l	1	*ZMDのアドレス/コンパイル時に発生したエラーのテーブル
fopen_name:		ds.l	1
	.bss
suji:			ds.b	20
filename:		ds.b	fn_size
gene_fn:		ds.b	fn_size
open_fn_:				*fopenワーク
fdr_cmd:				*m_fadeoutワーク
trk_cmd:				*m_stop,m_contワーク
pcm_cmd:		ds.b	1024	*m_pcmsetワーク
