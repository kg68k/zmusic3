*-------------------------------------------------------
*
*	       A ♪SOUND mind in a SOUND body
*
*	      　ＺＭＵＳＩＣ．Ｘ Version 3.0
*
*		 Programmed by Z.Nishikawa
*
*-------------------------------------------------------
	.cpu		68000
	.nlist
	.include	doscall.mac
	.include	iocscall.mac
	.include	dma.mac
	.include	z_global.mac
	.include	table.mac
	.include	label.mac
	.include	macro.mac
	.include	error.mac
	.include	zmd.mac
	.include	zmid.mac
	.include	zmcall.mac
	.include	mpcmcall.mac
	.list
	.text
	.lall

begin_of_prog:
device_driver0:
	dc.l	dev_header1
	dc.w	$8020			*char,ioctrl不可,raw
	dc.l	strategy_entry0
	dc.l	interrupt_entry0
dev_name0:
	dc.b	'ZMS     '
pack_ptr0:
	dc.l	0
func_tbl0:
	dc.l	dev_init-func_tbl0	*0  初期化
	dc.l	not_com-func_tbl0	*1  エラー
	dc.l	not_com-func_tbl0	*2  無効
	dc.l	not_com-func_tbl0	*3  (ioctrlによる入力)
	dc.l	not_com-func_tbl0	*4  (入力)
	dc.l	ok_com-func_tbl0	*5  １バイト先読み入力
	dc.l	ok_com-func_tbl0	*6  入力ステータスチェック
	dc.l	ok_com-func_tbl0	*7  入力バッファクリア
	dc.l	dev_out-func_tbl0	*8  出力(verify off)
	dc.l	dev_out-func_tbl0	*9  出力(verify on)
	dc.l	ok_com-func_tbl0	*10 出力ステータスチェック
	dc.l	ok_com-func_tbl0	*11 無効
	dc.l	not_com-func_tbl0	*12 ioctrlによる出力

interrupt_entry0:
	movem.l	d0/a4-a5,-(sp)
	movea.l	pack_ptr0(pc),a5
	moveq.l	#0,d0			*d0.l=com code
	move.b	2(a5),d0
	add.w	d0,d0
	add.w	d0,d0
	move.l	func_tbl0(pc,d0.w),d0
	jsr	func_tbl0(pc,d0.l)	*jump tableで参照したところへ…
	move.b	d0,3(a5)		*終了ステータスをセット
	lsr.w	#8,d0
	move.b	d0,4(a5)
	movem.l	(sp)+,d0/a4-a5
	rts

dev_header1:
	dc.l	dev_header2
	dc.w	$c020			*char,ioctrl可,raw
	dc.l	strategy_entry1
	dc.l	interrupt_entry1
dev_name1:
	dc.b	'PCM     '
pack_ptr1:
	dc.l	0
func_tbl1:
	dc.w	ok_com-func_tbl1	*0  初期化
	dc.w	not_com-func_tbl1	*1  エラー
	dc.w	not_com-func_tbl1	*2  無効
	dc.w	ioctrl_inp1-func_tbl1	*3  (ioctrlによる入力)
	dc.w	pcmdev_inp1-func_tbl1	*4  (入力)
	dc.w	ok_com-func_tbl1	*5  １バイト先読み入力
	dc.w	ok_com-func_tbl1	*6  入力ステータスチェック
	dc.w	ok_com-func_tbl1	*7  入力バッファクリア
	dc.w	pcmdev_out1-func_tbl1	*8  出力(verify off)
	dc.w	pcmdev_out1-func_tbl1	*9  出力(verify on)
	dc.w	ok_com-func_tbl1	*10 出力ステータスチェック
	dc.w	ok_com-func_tbl1	*11 無効
	dc.w	ioctrl_out1-func_tbl1	*12 ioctrlによる出力

interrupt_entry1:
	movem.l	d0/a4-a5,-(sp)
	movea.l	pack_ptr1(pc),a5
	moveq.l	#0,d0			*d0.l=com code
	move.b	2(a5),d0
	add.w	d0,d0
	move.w	func_tbl1(pc,d0.w),d0
	jsr	func_tbl1(pc,d0.w)	*jump tableで参照したところへ…
	move.b	d0,3(a5)		*終了ステータスをセット
	lsr.w	#8,d0
	move.b	d0,4(a5)
	movem.l	(sp)+,d0/a4-a5
	rts

dev_header2:
	dc.l	-1
	dc.w	$8020
	dc.l	strategy_entry2
	dc.l	interrupt_entry2
dev_name2:
	dc.b	'MIDI    '
pack_ptr2:
	dc.l	0
func_tbl2:
	dc.w	ok_com-func_tbl2	*0  初期化
	dc.w	not_com-func_tbl2	*1  エラー
	dc.w	not_com-func_tbl2	*2  無効
	dc.w	not_com-func_tbl2	*3  ioctrlによる入力
	dc.w	not_com-func_tbl2	*4　入力
	dc.w	not_com-func_tbl2	*5  1バイト先読み入力
	dc.w	ok_com-func_tbl2	*6  入力ステータスチェック
	dc.w	ok_com-func_tbl2	*7  入力バッファクリア
	dc.w	dev_out_midi-func_tbl2	*8  出力(verify off)
	dc.w	dev_out_midi-func_tbl2	*9  出力(verify on)
	dc.w	ok_com-func_tbl2	*10 出力ステータスチェック
	dc.w	ok_com-func_tbl2	*11 無効
	dc.w	not_com-func_tbl2	*12 ioctrlによる出力

interrupt_entry2:			*MIDI生データ通信処理
	movem.l	d0/a4-a5,-(sp)
	movea.l	pack_ptr2(pc),a5
	moveq.l	#0,d0			*d0.l=com code
	move.b	2(a5),d0
	add.w	d0,d0
	move.w	func_tbl2(pc,d0.w),d0
	jsr	func_tbl2(pc,d0.w)	*jump tableで参照したところへ…
	move.b	d0,3(a5)		*終了ステータスをセット
	lsr.w	#8,d0
	move.b	d0,4(a5)
	movem.l	(sp)+,d0/a4-a5
	rts

strategy_entry0:
	move.l	a5,pack_ptr0
	rts
strategy_entry1:
	move.l	a5,pack_ptr1
	rts
strategy_entry2:
	move.l	a5,pack_ptr2
	rts

not_com:
	move.w	#$5003,d0	*無視/中止,無効
	rts
ok_com:
	clr.w	d0		*no error
	rts
*------------------------------------------------------------------------------
*			演奏データ出力
*------------------------------------------------------------------------------
reg_zm_dev	reg	d1-d7/a0-a6
dev_out:
	* グローバルレジスタ d4		a4 a6
	movem.l	reg_zm_dev,-(sp)
	lea	work,a6
	movea.l	14(a5),a4	*get buff. add.
	move.l	18(a5),d4	*n bytes
	beq	dev_out_end	*case:data length is 0
	move.l	d4,-(sp)
	pea	(a4)
	DOS	_SETBLOCK
	addq.w	#8,sp
dev_out_chk:				*-Sでのエントリ
	move.l	#dev_out_end,fnc_quit_addr-work(a6)	*エラー発生の対処時に
	move.l	sp,sp_buf-work(a6)			*使用するパラメータを設定
	move.w	#$7fff,fnc_no-work(a6)			*
	cmpi.b	#$1a,(a4)		*ヘッダチェック
	bls	exec_cmp		*コンパイルデータの実行
	cmpi.l	#SMFHED,(a4)
	beq	go_trans_smf

	jsr	stop_timer-work(a6)
	jsr	all_key_off-work(a6)
	move.l	#ID_ZMD,d3
	jsr	free_mem2-work(a6)	*ZMDメモリブロックの解放
	move.l	#0,d1			*errmax=0,no header,no err list
	move.l	compiler_j(pc),d0
	beq	nocompiler		*compilerはリンクされていないのでコンパイル不可能→終了
	move.l	d0,a0
	move.l	a4,a1			*source addr.
	move.l	d4,d2			*source size
	moveq.l	#1,d1			*no header,no err list,errmax=1
	cmpi.b	#2,zmsc_mode-work(a6)
	bne	@f
	ori.w	#ZMC_V2,d1
@@:
	movem.l	d1-d7/a1-a6,-(sp)
	jsr	(a0)			*compilerへ処理を移す
	movem.l	(sp)+,d1-d7/a1-a6	*d0.l=0:no error, a0.l=OBJ pointer
	tst.l	d0			*d0.l=n of errors
	bne	dev_out_end_err		*a0.l=0 エラーが発生している
	move.l	a0,d0
	beq	dev_out_end_err
	move.l	a0,-(sp)
	moveq.l	#0,d2			*dummy size
	lea	8(a0),a1
	bsr	_play_zmd
	move.l	(sp)+,a1
	move.l	calc_total_j(pc),a0
	movem.l	d1-d7/a1-a6,-(sp)
	jsr	(a0)			*トータルステップなどの計算(x:a6)
	movem.l	(sp)+,d1-d7/a1-a6
	move.l	a0,a1			*>a0.l=エラーテーブル/結果テーブルの解放
	jsr	free_mem		*エラーテーブル/結果テーブルの解放
dev_out_end:				* < 通常終了
	moveq.l	#0,d0
	move.l	d0,sp_buf-work(a6)
	movem.l	(sp)+,reg_zm_dev
	rts

dev_out_error:			*なんらかのエラー
	* < d0.l=error code
	jsr	set_err_code-work(a6)
	moveq.l	#0,d0
	bsr	set_err_code		*set error code(dummy)
	bsr	set_err_code		*set error code(dummy)
	bsr	set_err_code		*set error code(dummy)
	addq.l	#1,n_of_err-work(a6)
dev_out_end_err:
	jsr	play_beep-work(a6)
	bra	dev_out_end

exec_cmp:				*コンパイルデータの実行(ここを変えたらexec_comn_cmdもかえる)
	cmpi.l	#ZmuSiC0,(a4)		*$10,'Zmu'
	bne	zmadpcm??
	cmpi.l	#ZmuSiC1+v_code,4(a4)	*'Sic',version(.b)
	bne	match_err

	jsr	stop_timer-work(a6)
	jsr	all_key_off-work(a6)
	move.l	#ID_ZMD,d3
	jsr	free_mem2-work(a6)	*ZMDメモリブロックの解放

	st.b	play_bak_flg-work(a6)
	lea	8(a4),a1		*address(header分足す)
	subq.l	#8,d4			*headerの長さ分まとめて差し引く
	ble	dev_out_end		*minus or zero
	move.l	d4,d2			*size
	bsr	_play_zmd
	bra	dev_out_end

zmadpcm??:				*ZPDのケースか(V2)
	cmpi.l	#ZPDV2_0,(a4)		*$10,'ZmA'
	bne	zmadpcm3??
	cmpi.l	#ZPDV2_1,4(a4)		*'dpCm'
	bne	match_err

	move.l	#ID_ZPD,d3
	jsr	free_mem2-work(a6)	*古いのを解放

	addq.w	#8,a4			*skip header
	subq.l	#8,d4			*headerの長さ分まとめて差し引く
	ble	dev_out_end		*minus or zero
	move.l	d4,d2			*size
	move.l	#ID_ZPD,d3		*employment
	jsr	get_mem-work(a6)	*メモリ確保(>a0.l=address,>d2.l=modified size)
	tst.l	d0
	bmi	outmem_err
	move.l	a0,a2
@@:					*バッファへ転送
	move.l	(a4)+,(a0)+
	subq.l	#4,d2
	bne	@b
	clr.b	zpd_last_fn+30-work(a6)	*ファイルネームキャッシュ無効化
	bsr	set_adpcm_tbl_v2	*ブロックデータのインフォメーションをワークにセット
	bra	dev_out_end

zmadpcm3??:				*ZPDのケースか(V3)
	cmpi.l	#ZPDV3_0,(a4)		*$1a,'Zma'
	bne	match_err
	cmpi.l	#ZPDV3_1,4(a4)		*'DPcM'
	bne	match_err

	move.l	#ID_ZPD,d3
	jsr	free_mem2-work(a6)	*古いのを解放

	addq.w	#8,a4			*skip header
	subq.l	#8,d4			*headerの長さ分まとめて差し引く
	ble	dev_out_end		*minus or zero
	move.l	d4,d2			*size
	move.l	#ID_ZPD,d3		*employment
	jsr	get_mem-work(a6)	*メモリ確保(>a0.l=address,>d2.l=modified size)
	tst.l	d0
	bmi	outmem_err
	move.l	a0,a2
@@:					*バッファへ転送
	move.l	(a4)+,(a0)+
	subq.l	#4,d2
	bne	@b
	clr.b	zpd_last_fn+30-work(a6)	*ファイルネームキャッシュ無効化
	bsr	set_adpcm_tbl_v3	*ブロックデータのインフォメーションをワークにセット
	bra	dev_out_end

go_trans_smf:
*	clr.b	mbd_last_fn-work(a6)	*ファイルネームキャッシュ無効化
	move.l	a4,a1
	move.l	d4,d2
	moveq.l	#-1,d1			*current MIDI I/F
	bsr	midi_transmission
	bra	dev_out_end

outmem_err:
	move.l	#ZM_GET_MEM*65536+OUT_OF_MEMORY,d0	*エラーを出したファンクション番号を持って帰る
	bra	dev_out_error

match_err:			*ヘッダの不一致
	move.l	#$7fff*65536+UNIDENTIFIED_FILE,d0
	bra	dev_out_error

nocompiler:
	move.l	#$7fff*65536+COMPILER_NOT_AVAILABLE,d0
	bra	dev_out_error

pcmdev_inp1:				*PCMDRV.SYS処理
	movem.l	d1-d2/a1,-(sp)
	moveq.l	#$61,d0
	bra	@f
pcmdev_out1:
	movem.l	d1-d2/a1,-(sp)
	moveq.l	#0,d1
	IOCS	_ADPCMMOD
	moveq.l	#$60,d0
@@:
	move.l	$12(a5),d2		*length
	move.l	$0e(a5),a1		*address
	move.w	frqpan(pc),d1		*frq/pan
	trap	#$0f
	movem.l	(sp)+,d1-d2/a1
	bra	ok_com

ioctrl_inp1:
	IOCS	_ADPCMSNS
	movea.l	$0e(a5),a4
	move.b	d0,(a4)
	bra	ok_com

ioctrl_out1:
	movea.l	$0e(a5),a4
	move.b	(a4)+,d0
	lsl.w	#8,d0
	move.b	(a4)+,d0
	move.w	d0,frqpan
	bra	ok_com

frqpan:	.dc.w	$0403

reg_midi_out:	reg	d1-d2/a1/a5-a6
dev_out_midi:				*MIDI生データの出力
nmdb0:					*nmdb!!
	tst.l	18(a5)			*check size
	beq	ok_com
	movem.l	reg_midi_out,-(sp)	*ここを変えたら-sの処理も変える
	lea	work,a6
	move.l	#1f,fnc_quit_addr-work(a6)	*エラー発生の対処時に
	move.l	sp,sp_buf-work(a6)		*使用するパラメータを設定
	move.w	#$7fff,fnc_no-work(a6)		*
	move.l	14(a5),a1		*addr
	move.l	18(a5),d2		*size
	move.l	d2,-(sp)
	pea	(a1)
	DOS	_SETBLOCK
	addq.w	#8,sp
*	clr.b	mbd_last_fn-work(a6)	*ファイルネームキャッシュ無効化
	cmpi.w	#$0d0a,(a1)
	bne	@f
	cmpi.b	#$1a,-1(a1,d2.l)	*終端記号チェック
	bne	1f
	moveq.l	#0,d2			*ascii case
@@:
	moveq.l	#-1,d1			*current MIDI I/F
	bsr	midi_transmission
exit_dev_out_midi:
	clr.l	sp_buf-work(a6)
	movem.l	(sp)+,reg_midi_out
	bra	ok_com
1:					*エラーケース
	move.l	#$7fff*65536+UNIDENTIFIED_FILE,d0
	jsr	set_err_code-work(a6)
	moveq.l	#0,d0
	bsr	set_err_code		*set error code(dummy)
	bsr	set_err_code		*set error code(dummy)
	bsr	set_err_code		*set error code(dummy)
	addq.l	#1,n_of_err-work(a6)
	jsr	play_beep-work(a6)
	bra	exit_dev_out_midi

com_max:	equ	(m_job_tbl_end-m_job_tbl)/4-1	*MAXコマンドナンバー
version_id:
		dc.b	'ZmuSiC'	*ID
ver_num:	dc.b	v_code		*ZMUSIC VERSION NUMBER
		dc.b	v_code_+ver_type

Z_MUSIC_t3:	* trap #3でここに飛んでくる
	* < d0.w=command number
	* > d0,a0 (この仕様は変更出来ない)
	* - d1-d7,a1-a6
reglist	reg	d1-d7/a1-a6
	movem.l	reglist,-(sp)
	lea	work,a6
	move.w	d0,fnc_no-work(a6)	*エラー発生時に使用
	add.w	d0,d0
	add.w	d0,d0
	move.l	m_job_tbl(pc,d0.w),d0
	beq	err_exit_Z_MUSIC_t3
	move.l	d0,a0
	move.w	$0034(a7),d0
	ori.w	#$2000,d0
	move.w	d0,sr_type-work(a6)			*SRを割り込み発生前に戻す時に使用
	move.l	#exit_Z_MUSIC_t3,fnc_quit_addr-work(a6)	*エラー発生の対処時に
	move.l	sp,sp_buf-work(a6)			*使用するパラメータを設定
	jsr	(a0)
exit_Z_MUSIC_t3:
	ori.w	#$0700,sr
	clr.l	sp_buf	*わざと'-work(a6)'をつけない(先のjsr (a0)でa6破壊の場合があるため)
	movem.l	(sp)+,reglist
	rte
err_exit_Z_MUSIC_t3:
	move.l	d0,a0			*a0=0
	moveq.l	#-1,d0
	bra	exit_Z_MUSIC_t3

m_job_tbl:
		dc.l	m_init				*$00
		dc.l	m_assign			*$01
compiler_j:	dc.l	0				*$02
		dc.l	m_vget				*$03
		dc.l	m_vset				*$04
		dc.l	0				*$05
		dc.l	m_tempo				*$06
		dc.l	set_timer_value			*$07
		dc.l	m_play				*$08
		dc.l	m_play2				*$09
		dc.l	m_play_again			*$0a
		dc.l	m_play_status			*$0b
		dc.l	m_stop				*$0c
		dc.l	m_cont				*$0d
		dc.l	m_atoi				*$0e
		dc.l	set_master_clock		*$0f
		dc.l	play_zmd			*$10
		dc.l	play_zmd_se			*$11
		dc.l	se_play				*$12
		dc.l	se_adpcm1			*$13
		dc.l	se_adpcm2			*$14
		dc.l	intercept_play			*$15
		dc.l	current_midi_in			*$16
		dc.l	current_midi_out		*$17
		dc.l	midi_transmission		*$18
		dc.l	exclusive			*$19
		dc.l	0				*$1a
		dc.l	set_eox_wait			*$1b
		dc.l	midi_inp1			*$1c
		dc.l	midi_out1			*$1d
		dc.l	midi_rec			*$1e
		dc.l	midi_rec_end			*$1f
		dc.l	gs_reset			*$20
		dc.l	gs_partial_reserve		*$21
		dc.l	gs_reverb			*$22
		dc.l	gs_chorus			*$23
		dc.l	gs_part_setup			*$24
		dc.l	gs_drum_setup			*$25
		dc.l	gs_drum_name			*$26
		dc.l	gs_print			*$27
		dc.l	gs_display			*$28
		dc.l	gm_system_on			*$29
		dc.l	0				*$2a
		dc.l	0				*$2b
		dc.l	0				*$2c
		dc.l	0				*$2d
		dc.l	0				*$2e
		dc.l	0				*$2f
		dc.l	mt32_reset			*$30
		dc.l	mt32_partial_reserve		*$31
		dc.l	mt32_reverb			*$32
		dc.l	mt32_part_setup			*$33
		dc.l	mt32_drum_setup			*$34
		dc.l	mt32_common			*$35
		dc.l	mt32_partial			*$36
		dc.l	mt32_patch			*$37
		dc.l	mt32_print			*$38
		dc.l	u220_setup			*$39
		dc.l	u220_part_setup			*$3a
		dc.l	u220_common			*$3b
		dc.l	u220_timbre			*$3c
		dc.l	u220_drum_setup			*$3d
		dc.l	u220_drum_inst			*$3e
		dc.l	u220_print			*$3f
		dc.l	m1_setup			*$40
		dc.l	m1_part_setup			*$41
		dc.l	m1_effect_setup			*$42
		dc.l	m1_print			*$43
		dc.l	send_to_m1			*$44
		dc.l	0				*$45
		dc.l	sc88_mode_set			*$46
		dc.l	sc88_reverb			*$47
		dc.l	sc88_chorus			*$48
		dc.l	sc88_delay			*$49
		dc.l	sc88_equalizer			*$4a
		dc.l	sc88_part_setup			*$4b
		dc.l	sc88_drum_setup			*$4c
		dc.l	sc88_drum_name			*$4d
		dc.l	sc88_user_inst			*$4e
		dc.l	sc88_user_drum			*$4f
		dc.l	pcm_read			*$50
		dc.l	register_zpd			*$51
		dc.l	set_zpd_table			*$52
		dc.l	convert_pcm			*$53
		dc.l	exec_subfile			*$54
		dc.l	transmit_midi_dump		*$55
		dc.l	set_wave_form1			*$56
		dc.l	set_wave_form2			*$57
		dc.l	obtain_events			*$58
		dc.l	loop_control			*$59
		dc.l	mask_tracks			*$5a
		dc.l	mask_channels			*$5b
		dc.l	set_ch_output_level		*$5c
		dc.l	set_tr_output_level		*$5d
		dc.l	master_fader			*$5e
		dc.l	get_fader_status		*$5f
		dc.l	get_play_time			*$60
		dc.l	get_1st_comment			*$61
		dc.l	get_timer_mode			*$62
		dc.l	get_track_table			*$63
		dc.l	get_play_work			*$64
		dc.l	get_buffer_information		*$65
		dc.l	get_zmsc_status			*$66
calc_total_j:	dc.l	0				*$67	calc_total
		dc.l	application_releaser		*$68
		dc.l	release_driver			*$69
		dc.l	occupy_zmusic			*$6a
		dc.l	hook_fnc_service		*$6b
		dc.l	hook_zmd_service		*$6c
		dc.l	0				*$6d	occupy_compiler
		dc.l	store_error			*$6e
		dc.l	print_error			*$6f
		dc.l	get_mem				*$70
		dc.l	enlarge_mem			*$71
		dc.l	free_mem			*$72
		dc.l	free_mem2			*$73
		dc.l	exchange_memid			*$74
		dc.l	0				*$75
		dc.l	0				*$76
		dc.l	0				*$77
		dc.l	init_all			*$78
		dc.l	int_start			*$79
		dc.l	int_stop			*$7a
		dc.l	set_int_service			*$7b
		dc.l	control_tempo			*$7c
		dc.l	0				*$7d
		dc.l	zmusic_mode			*$7e
		dc.l	exec_zmd			*$7f
m_job_tbl_end:

init_cmn_wks	macro					*PLAY等用
	* x d0.l
	moveq.l	#0,d0
	move.l	d0,stat0-work(a6)
	move.l	d0,statr0-work(a6)
	move.l	d0,jump_flg1-work(a6)		*init jump flg1
	move.l	d0,jump_flg2-work(a6)		*init jump flg2
	move.l	d0,jump_flg3-work(a6)		*init jump flg3
	move.l	#$0403_ffff,adpcm_frq-work(a6)	*adpcm_frq,adpcm_pan,adpb_clr,wvmm_clr
	move.b	d0,zpd_last_fn+30-work(a6)	*ファイルネームキャッシュ無効化
	endm

m_init:							*イニシャライズ
	*   cmd=$00
	* < d1.l=0通常初期化,2:Ver.2.0モードへ,3:Ver.3.0モードへ
	* > d0.l=Version ID
	move.w	sr,-(sp)				*念のため
	ori.w	#$700,sr
	move.b	d1,-(sp)
	bsr	m_stop_all				*演奏中ならまずそれを停止
	jsr	all_key_off-work(a6)			*全消音
	move.l	play_trk_tbl-work(a6),a1		*どのtrackがどのchannelへ
	move.w	#-1,(a1)				*ｱｻｲﾝされているかを初期化
	bsr	init_mask_fader_work
	jsr	init_play_wk-work(a6)			*演奏ワークの初期化
	init_cmn_wks					*共通ワーク初期化
	bsr	init_opmwk				*FM音源のチャンネルワークの初期化
	bsr	init_midiwk				*MIDIのチャンネルワークの初期化
mpcm_patch0:
	move.w	#M_INIT,d0				*MPCM初期化
	MPCM_call
_mpcm_patch0:
	move.l	#ID_ERROR,d3				*エラーストック・クリア
	jsr	free_mem2-work(a6)
	moveq.l	#0,d0
	move.w	ver_num(pc),d0
	move.b	(sp)+,d1
	cmpi.b	#2,d1
	beq	@f
	cmpi.b	#3,d1
	bne	1f
@@:
	jsr	zmusic_mode-work(a6)
1:
	move.w	(sp)+,sr
	rts

init_mask_fader_work:					*マスク／フェーダー関連ワークの初期化
	* x d0,d1,a4
	move.l	mask_preserve-work(a6),d0		*d0=0 or $00ff0000($ff on p_mask_mode)
	bne	@f
	move.l	d0,ch_mask_fm-work(a6)			*6つのデバイスワークをまとめて初期化
	move.l	d0,ch_mask_m0-work(a6)
	move.l	d0,ch_mask_mr0-work(a6)
@@:
*	andi.b	#(.not.ff_ch_fader),fader_flag-work(a6)	*ch_fader 終了
	clr.b	fader_flag-work(a6)			*ch_fader & master_fader終了
	st.b	ch_fader_tbl-work(a6)			*ch_fader
	st.b	master_fader_tbl-work(a6)		*master_fader
	lea	fm_vol_tbl-work(a6),a4			*まとめてfm_vol_tbl～mr1_vol_tbl
	moveq.l	#-1,d0					*までを初期化する(フェーダー系ワーク)
	moveq.l	#(if_max+2)*16/4-1,d1			*+2はFMとADPCMのチャンネル分
@@:
	move.l	d0,(a4)+
	dbra	d1,@b
	rts

m_assign:			*チャンネルアサイン
	*   cmd=$01
	* < d1.l=ch_number
	* < 	  .hw=type	(0,1,$8000,$8001,$8002,-1:current)
	* < 	  .lw=ch	(0-15)
	* < d2.l=trk_number(0-65534)
	* > error code
	move.l	d1,d0
	swap	d0
	tst.w	d0		*d0.w=type
	bmi	mas_midi
	bne	mas_adpcm
	cmpi.w	#7,d1		*FMチャンネルの最大値をチェック
	bls	mas_trchk
	bra	t_illegal_channel
mas_midi:			*MIDIチャンネルの最大値をチェック
	cmpi.w	#-1,d0
	bne	@f
	swap	d1			*カレント使用ケース
	move.w	current_midi_out_w-work(a6),d1
	lsr.w	#1,d1
	ori.w	#$8000,d1
	swap	d1
@@:
	cmpi.w	#$0f,d1
	bls	mas_trchk
	bra	t_illegal_channel
mas_adpcm:			*ADPCMチャンネルの最大値をチェック
	cmpi.w	#adpcm_ch_max-1,d1
	bhi	t_illegal_channel
mas_trchk:
	cmpi.w	#tr_max-1,d2
	bhi	t_illegal_track_number
	calc_wk	d2
	move.l	d1,p_type(a5)
				*play_trk_tblへトラック登録
	* < d2=trk number
	* - all
	move.l	play_trk_tbl-work(a6),a1
	moveq.l	#pl_max-1,d1
@@:
	move.w	(a1)+,d0
	cmpi.w	#-1,d0
	beq	@f		*トラック番号をセット
	cmp.w	d2,d0		*既に同じ物がアサイン済か
	beq	t_dat_ok
	dbra	d1,@b
@@:
	move.w	#-1,(a1)
	move.w	d2,-(a1)
	t_dat_ok

*compiler:				*COMPILE
	*   cmd=$02
	* < d1.l=mode
	*	d0-d6:検出するエラーの最大/0:∞,1-127
	*	d15:エラーテーブルリストを作成して出力するか(0:no,1:yes)
	* < d2.l=size
	* < a1.l=source address	(a1=d2=0でコンパイラ解除)
	*-------
	* > d0.l=num. of error
	* > a0.l=error table (if required/to be free)
	*	(error code.w,error line.l)
	*-------
	* > d0.l=0:no error
	* > a0.l=object address
	*   0(a0)～15(a0)=ZMD standard header(if required)
	*   8(a0)～ZMD
	*   (ウォーニングがあればZMDデータの後ろにくっついている)
	*------- release compiler case
	* > d0.l=0:no error/nz error

m_vget:				*ボイスゲット
	*   cmd=$03
	* < d1.l=timbre number(0-32767)
	* < d2.l=mode(0:normal,1:AL/FB)
	* < a1.l=destination data address(80bytes)
	cmpi.l	#fmsnd_reg_max-1,d1
	bhi	t_illegal_timbre_number
	cmp.w	fmsnd_n_max-work(a6),d1
	bcc	t_illegal_timbre_number

	lsl.l	#4,d1
	move.l	d1,d0
	add.l	d1,d1
	add.l	d0,d1		*48倍
	movea.l	fmsnd_buffer-work(a6),a2
	adda.l	d1,a2
	tst.w	(a2)+
	beq	t_no_timbre_parameters
	tst.l	d2
	bne	m_vget2

	move.b	(a2)+,$04(a1)	*0)LFRQ

	move.b	(a2)+,d0
	and.b	#$7f,d0
	move.b	d0,$05(a1)	*1)PMD

	move.b	(a2)+,d0
	andi.b	#127,d0
	move.b	d0,$06(a1)	*2)AMD
				*3)SYNC/OM/WF
	move.b	(a2)+,d0
	bpl	@f
	move.b	#1,$03(a1)	*SYNC=1
	bra	gtv_wf
@@:
	clr.b	$03(a1)		*SYNC=0
gtv_wf:
	move.b	d0,d1
	andi.b	#3,d1
	move.b	d1,$02(a1)	*WF
	andi.b	#%0111_1000,d0
	lsr.b	#3,d0
	move.b	d0,$01(a1)	*OM

	move.b	(a2)+,d0	*4)
	move.b	d0,d1
	rol.b	#2,d1
	andi.b	#3,d1
	move.b	d1,$09(a1)	*PAN
	andi.b	#%0011_1111,d0
	move.b	d0,(a1)		*AF

	move.b	(a2)+,d0	*5)
	move.b	d0,d1
	lsr.b	#4,d1
	andi.b	#7,d1
	move.b	d1,$07(a1)	*PMS
	andi.b	#3,d0
	move.b	d0,$08(a1)	*AMS
************************************************
op_param_gv:
	move.b	(a2)+,d0	*6)OP1:DT1/MUL
	move.b	d0,d1
	lsr.b	#4,d1
	andi.b	#7,d1
	move.b	d1,$13(a1)	*DT1
	andi.b	#15,d0
	move.b	d0,$12(a1)	*MUL

	move.b	(a2)+,d0	*7)OP3:DT1/MUL
	move.b	d0,d1
	lsr.b	#4,d1
	andi.b	#7,d1
	move.b	d1,$29(a1)	*DT1
	andi.b	#15,d0
	move.b	d0,$28(a1)	*MUL

	move.b	(a2)+,d0	*8)OP2:DT1/MUL
	move.b	d0,d1
	lsr.b	#4,d1
	andi.b	#7,d1
	move.b	d1,$1e(a1)	*DT1
	andi.b	#15,d0
	move.b	d0,$1d(a1)	*MUL

	move.b	(a2)+,d0	*9)OP4:DT1/MUL
	move.b	d0,d1
	lsr.b	#4,d1
	andi.b	#7,d1
	move.b	d1,$34(a1)	*DT1
	andi.b	#15,d0
	move.b	d0,$33(a1)	*MUL
************************************************
	move.b	(a2)+,$10(a1)	*10)OP1:TL
	move.b	(a2)+,$26(a1)	*11)OP3:TL
	move.b	(a2)+,$1b(a1)	*12)OP2:TL
	move.b	(a2)+,$31(a1)	*13)OP4:TL

	move.b	(a2)+,d0	*14)OP1:KS/AR
	move.b	d0,d1
	andi.b	#31,d1
	move.b	d1,$0b(a1)	*AR
	rol.b	#2,d0
	andi.b	#3,d0
	move.b	d0,$11(a1)	*KS

	move.b	(a2)+,d0	*15)OP3:KS/AR
	move.b	d0,d1
	andi.b	#31,d1
	move.b	d1,$21(a1)	*AR
	rol.b	#2,d0
	andi.b	#3,d0
	move.b	d0,$27(a1)	*KS

	move.b	(a2)+,d0	*16)OP2:KS/AR
	move.b	d0,d1
	andi.b	#31,d1
	move.b	d1,$16(a1)	*AR
	rol.b	#2,d0
	andi.b	#3,d0
	move.b	d0,$1c(a1)	*KS

	move.b	(a2)+,d0	*17)OP4:KS/AR
	move.b	d0,d1
	andi.b	#31,d1
	move.b	d1,$2c(a1)	*AR
	rol.b	#2,d0
	andi.b	#3,d0
	move.b	d0,$32(a1)	*KS
************************************************
	move.b	(a2)+,d0	*18)OP1:AME/1DR
	move.b	d0,d1
	andi.b	#31,d1
	move.b	d1,$0c(a1)	*1DR
	rol.b	#1,d0
	andi.b	#1,d0
	move.b	d0,$15(a1)	*AME

	move.b	(a2)+,d0	*19)OP3:AME/1DR
	move.b	d0,d1
	andi.b	#31,d1
	move.b	d1,$22(a1)	*1DR
	rol.b	#1,d0
	andi.b	#1,d0
	move.b	d0,$2b(a1)	*AME

	move.b	(a2)+,d0	*20)OP2:AME/1DR
	move.b	d0,d1
	andi.b	#31,d1
	move.b	d1,$17(a1)	*1DR
	rol.b	#1,d0
	andi.b	#1,d0
	move.b	d0,$20(a1)	*AME

	move.b	(a2)+,d0	*21)OP4:AME/1DR
	move.b	d0,d1
	andi.b	#31,d1
	move.b	d1,$2d(a1)	*1DR
	rol.b	#1,d0
	andi.b	#1,d0
	move.b	d0,$36(a1)	*AME
************************************************
	move.b	(a2)+,d0	*22)OP1:DT2/2DR
	move.b	d0,d1
	andi.b	#31,d1
	move.b	d1,$0d(a1)	*2DR
	rol.b	#2,d0
	andi.b	#3,d0
	move.b	d0,$14(a1)	*DT2

	move.b	(a2)+,d0	*23)OP3:DT2/2DR
	move.b	d0,d1
	andi.b	#31,d1
	move.b	d1,$23(a1)	*2DR
	rol.b	#2,d0
	andi.b	#3,d0
	move.b	d0,$2a(a1)	*DT2

	move.b	(a2)+,d0	*24)OP2:DT2/2DR
	move.b	d0,d1
	andi.b	#31,d1
	move.b	d1,$18(a1)	*2DR
	rol.b	#2,d0
	andi.b	#3,d0
	move.b	d0,$1f(a1)	*DT2

	move.b	(a2)+,d0	*25)OP4:DT2/2DR
	move.b	d0,d1
	andi.b	#31,d1
	move.b	d1,$2e(a1)	*2DR
	rol.b	#2,d0
	andi.b	#3,d0
	move.b	d0,$35(a1)	*DT2
************************************************
	move.b	(a2)+,d0	*26)OP1:D1L/RR
	move.b	d0,d1
	andi.b	#15,d1
	move.b	d1,$0e(a1)	*RR
	lsr.b	#4,d0
	move.b	d0,$0f(a1)	*D1L

	move.b	(a2)+,d0	*27)OP3:D1L/RR
	move.b	d0,d1
	andi.b	#15,d1
	move.b	d1,$24(a1)	*RR
	lsr.b	#4,d0
	move.b	d0,$25(a1)	*D1L

	move.b	(a2)+,d0	*28)OP2:D1L/RR
	move.b	d0,d1
	andi.b	#15,d1
	move.b	d1,$19(a1)	*RR
	lsr.b	#4,d0
	move.b	d0,$1a(a1)	*D1L

	move.b	(a2)+,d0	*29)OP4:D1L/RR
	move.b	d0,d1
	andi.b	#15,d1
	move.b	d1,$2f(a1)	*RR
	lsr.b	#4,d0
	move.b	d0,$30(a1)	*D1L
************************************************
	lea	55(a1),a1
	moveq.l	#fmsndname_len-1,d0	*音色名の最大長
@@:				*音色名転送
	move.b	(a2)+,(a1)+
	dbeq	d0,@b
	t_dat_ok

m_vget2:				*AL/FB分離方式
	* < d1.l=offset
	* < a2.l=fmsnd_buffer
	move.l	a1,a0			*保存
	move.l	a2,a3			*use later
	addq.w	#6,a2			*op_paramを収納
	lea	-11(a1),a1		*-11はつじつま合わせ
	bsr	op_param_gv

	move.b	(a3)+,50(a0)		*0)LFRQ

	move.b	(a3)+,d0
	andi.b	#127,d0
	move.b	d0,51(a0)		*1)PMD

	move.b	(a3)+,d0
	andi.b	#127,d0
	move.b	d0,52(a0)		*2)AMD
					*3)SYNC/OM/WF
	move.b	(a3)+,d0
	bpl	@f
	move.b	#1,49(a0)		*SYNC=1
	bra	gtv2_wf
@@:
	clr.b	49(a0)			*SYNC=0
gtv2_wf:
	move.b	d0,d1
	andi.b	#3,d1
	move.b	d1,48(a0)		*WF
	andi.b	#%0111_1000,d0
	lsr.b	#3,d0
	move.b	d0,46(a0)		*OM

	move.b	(a3)+,d0		*4)PAN/AF
	move.b	d0,d1
	rol.b	#2,d1
	andi.b	#3,d1
	move.b	d1,47(a0)		*PAN

	move.b	d0,d1
	lsr.b	#3,d1
	andi.b	#7,d1
	move.b	d1,45(a0)		*FB

	andi.b	#7,d0
	move.b	d0,44(a0)		*AL

	move.b	(a3)+,d0		*5)
	move.b	d0,d1
	lsr.b	#4,d1
	andi.b	#7,d1
	move.b	d1,53(a0)		*PMS
	andi.b	#3,d0
	move.b	d0,54(a0)		*AMS
	t_dat_ok

m_vset:				*ボイスセット
	*   cmd=$04
	* < d1.l=timbre number(0-32767)
	* < d2.l=mode(0:normal,1:AL/FB,-1:ZMD形式)
	* < a1.l=parameters' data address
	cmpi.l	#fmsnd_reg_max-1,d1
	bhi	t_illegal_timbre_number
	cmp.w	fmsnd_n_max-work(a6),d1
	bcs	@f
	bsr	spread_fmsnd_n
	bmi	t_out_of_memory
@@:
	lsl.l	#4,d1
	move.l	d1,d0
	add.l	d1,d1
	add.l	d0,d1		*48倍
	movea.l	fmsnd_buffer-work(a6),a2
	adda.l	d1,a2
	move.w	#fmsnd_exists,(a2)+	*existance mark

	tst.l	d2
	bmi	m_vset_zmd		*ZMD形式へ
	bne	m_vset2			*AL/FB分離方式へ

	move.b	$04(a1),(a2)+	*0)LFRQ

	move.b	$05(a1),d0	*1)PMD
	tas.b	d0
	move.b	d0,(a2)+

	move.b	$06(a1),d0	*2)AMD
	andi.b	#127,d0
	move.b	d0,(a2)+
				*3)SYNC/OM/WF
	move.b	$01(a1),d0	*OM
	andi.b	#$0f,d0
	lsl.b	#3,d0
	tst.b	$03(a1)		*SYNC
	beq	@f
	tas.b	d0
@@:
	move.b	$02(a1),d1	*WF
	andi.b	#3,d1
	or.b	d1,d0
	move.b	d0,(a2)+

	move.b	$09(a1),d0	*PAN
	andi.b	#3,d0
	ror.b	#2,d0
	move.b	(a1),d1
	andi.b	#%0011_1111,d1
	or.b	d1,d0		*AF
	move.b	d0,(a2)+	*4)PAN/AF

	move.b	$07(a1),d0	*PMS
	andi.b	#7,d0
	lsl.b	#4,d0
	move.b	$08(a1),d1	*AMS
	andi.b	#3,d1
	or.b	d1,d0
	move.b	d0,(a2)+	*5)
************************************************
op_param:
	move.b	$13(a1),d0	*DT1
	andi.b	#7,d0
	lsl.b	#4,d0
	move.b	$12(a1),d1	*MUL
	andi.b	#15,d1
	or.b	d1,d0
	move.b	d0,(a2)+	*6)OP1:DT1/MUL

	move.b	$29(a1),d0	*DT1
	andi.b	#7,d0
	lsl.b	#4,d0
	move.b	$28(a1),d1	*MUL
	andi.b	#15,d1
	or.b	d1,d0
	move.b	d0,(a2)+	*7)OP3:DT1/MUL

	move.b	$1e(a1),d0	*DT1
	andi.b	#7,d0
	lsl.b	#4,d0
	move.b	$1d(a1),d1	*MUL
	andi.b	#15,d1
	or.b	d1,d0
	move.b	d0,(a2)+	*8)OP2:DT1/MUL

	move.b	$34(a1),d0	*DT1
	andi.b	#7,d0
	lsl.b	#4,d0
	move.b	$33(a1),d1	*MUL
	andi.b	#15,d1
	or.b	d1,d0
	move.b	d0,(a2)+	*9)OP4:DT1/MUL
************************************************
	move.b	$10(a1),d0
	andi.b	#127,d0
	move.b	d0,(a2)+	*10)OP1:TL
	move.b	$26(a1),d0
	andi.b	#127,d0
	move.b	d0,(a2)+	*11)OP3:TL
	move.b	$1b(a1),d0
	andi.b	#127,d0
	move.b	d0,(a2)+	*12)OP2:TL
	move.b	$31(a1),d0
	andi.b	#127,d0
	move.b	d0,(a2)+	*13)OP4:TL

	move.b	$11(a1),d0	*KS
	andi.b	#3,d0
	ror.b	#2,d0
	move.b	$0b(a1),d1	*AR
	andi.b	#31,d1
	or.b	d1,d0
	move.b	d0,(a2)+	*14)OP1:KS/AR

	move.b	$27(a1),d0	*KS
	andi.b	#3,d0
	ror.b	#2,d0
	move.b	$21(a1),d1	*AR
	andi.b	#31,d1
	or.b	d1,d0
	move.b	d0,(a2)+	*15)OP3:KS/AR

	move.b	$1c(a1),d0	*KS
	andi.b	#3,d0
	ror.b	#2,d0
	move.b	$16(a1),d1	*AR
	andi.b	#31,d1
	or.b	d1,d0
	move.b	d0,(a2)+	*16)OP2:KS/AR

	move.b	$32(a1),d0	*KS
	andi.b	#3,d0
	ror.b	#2,d0
	move.b	$2c(a1),d1	*AR
	andi.b	#31,d1
	or.b	d1,d0
	move.b	d0,(a2)+	*17)OP4:KS/AR
************************************************
	move.b	$15(a1),d0	*AME
	andi.b	#1,d0
	ror.b	#1,d0
	move.b	$0c(a1),d1	*1DR
	andi.b	#31,d1
	or.b	d1,d0
	move.b	d0,(a2)+	*18)OP1:AME/1DR

	move.b	$2b(a1),d0	*AME
	andi.b	#1,d0
	ror.b	#1,d0
	move.b	$22(a1),d1	*1DR
	andi.b	#31,d1
	or.b	d1,d0
	move.b	d0,(a2)+	*19)OP3:AME/1DR

	move.b	$20(a1),d0	*AME
	andi.b	#1,d0
	ror.b	#1,d0
	move.b	$17(a1),d1	*1DR
	andi.b	#31,d1
	or.b	d1,d0
	move.b	d0,(a2)+	*20)OP2:AME/1DR

	move.b	$36(a1),d0	*AME
	andi.b	#1,d0
	ror.b	#1,d0
	move.b	$2d(a1),d1	*1DR
	andi.b	#31,d1
	or.b	d1,d0
	move.b	d0,(a2)+	*21)OP4:AME/1DR
************************************************
	move.b	$14(a1),d0	*DT2
	andi.b	#3,d0
	ror.b	#2,d0
	move.b	$0d(a1),d1	*2DR
	andi.b	#31,d1
	or.b	d1,d0
	move.b	d0,(a2)+	*22)OP1:DT2/2DR

	move.b	$2a(a1),d0	*DT2
	andi.b	#3,d0
	ror.b	#2,d0
	move.b	$23(a1),d1	*2DR
	andi.b	#31,d1
	or.b	d1,d0
	move.b	d0,(a2)+	*23)OP3:DT2/2DR

	move.b	$1f(a1),d0	*DT2
	andi.b	#3,d0
	ror.b	#2,d0
	move.b	$18(a1),d1	*2DR
	andi.b	#31,d1
	or.b	d1,d0
	move.b	d0,(a2)+	*24)OP2:DT2/2DR

	move.b	$35(a1),d0	*DT2
	andi.b	#3,d0
	ror.b	#2,d0
	move.b	$2e(a1),d1	*2DR
	andi.b	#31,d1
	or.b	d1,d0
	move.b	d0,(a2)+	*25)OP4:DT2/2DR
************************************************
	move.b	$0f(a1),d0	*1DL
	andi.b	#15,d0
	lsl.b	#4,d0
	move.b	$0e(a1),d1	*RR
	andi.b	#15,d1
	or.b	d1,d0
	move.b	d0,(a2)+	*26)OP1:D1L/RR

	move.b	$25(a1),d0	*1DL
	andi.b	#15,d0
	lsl.b	#4,d0
	move.b	$24(a1),d1	*RR
	andi.b	#15,d1
	or.b	d1,d0
	move.b	d0,(a2)+	*27)OP3:D1L/RR

	move.b	$1a(a1),d0	*1DL
	andi.b	#15,d0
	lsl.b	#4,d0
	move.b	$19(a1),d1	*RR
	andi.b	#15,d1
	or.b	d1,d0
	move.b	d0,(a2)+	*28)OP2:D1L/RR

	move.b	$30(a1),d0	*1DL
	andi.b	#15,d0
	lsl.b	#4,d0
	move.b	$2f(a1),d1	*RR
	andi.b	#15,d1
	or.b	d1,d0
	move.b	d0,(a2)+	*29)OP4:D1L/RR
************************************************
	lea	55(a1),a1
	moveq.l	#fmsndname_len-1,d0	*音色名の最大長
@@:				*音色名転送
	move.b	(a1)+,(a2)+
	dbeq	d0,@b
	t_dat_ok

m_vset_zmd:				*ZMD形式
	moveq.l	#fmsnd_size-2-1,d0
@@:
	move.b	(a1)+,(a2)+
	dbra	d0,@b
	t_dat_ok

m_vset2:				*AL/FB分離方式
	* < d1.l=offset
	* < a2.l=fmsnd_buffer
	move.l	a1,a0			*保存
	move.l	a2,a3			*use later
	addq.w	#6,a2			*op_paramを収納
	lea	-11(a1),a1		*-11はつじつま合わせ
	bsr	op_param

	move.b	50(a0),(a3)+		*0)LFRQ

	move.b	51(a0),d0		*1)PMD
	tas.b	d0
	move.b	d0,(a3)+

	move.b	52(a0),d0		*2)AMD
	andi.b	#127,d0
	move.b	d0,(a3)+
					*3)SYNC/OM/WF
	move.b	46(a0),d0		*OM
	andi.b	#$0f,d0
	lsl.b	#3,d0
	tst.b	49(a0)			*SYNC
	beq	@f
	tas.b	d0
@@:
	move.b	48(a0),d1		*WF
	andi.b	#3,d1
	or.b	d1,d0
	move.b	d0,(a3)+

	move.b	47(a0),d0		*PAN
	andi.b	#3,d0
	ror.b	#2,d0
	move.b	45(a0),d1		*FB
	andi.b	#7,d1
	lsl.b	#3,d1
	or.b	d1,d0
	move.b	44(a0),d1		*AL
	andi.b	#7,d1
	or.b	d1,d0
	move.b	d0,(a3)+		*4)PAN/AF

	move.b	53(a0),d0		*PMS
	andi.b	#7,d0
	lsl.b	#4,d0
	move.b	54(a0),d1		*AMS
	andi.b	#3,d1
	or.b	d1,d0
	move.b	d0,(a3)+		*5)
	t_dat_ok

spread_fmsnd_n:				*波形メモリ管理テーブル
reglist	reg	d0-d4/a0-a1
	* < d1.w=0-65534
	* - all
	movem.l	reglist,-(sp)
	andi.l	#$ffff,d1
	addq.l	#8,d1			*上限を増やす
	cmpi.l	#fmsnd_reg_max,d1
	bls	@f
	move.l	#fmsnd_reg_max,d1
@@:
	move.l	d1,d4			*new n-max
	lsl.w	#4,d1
	move.l	d1,d2
	add.w	d1,d1
	add.w	d1,d2			*fmsnd_size倍
	move.l	fmsnd_buffer-work(a6),d0	*enlarge or get?
	bne	enlrg_fmtb
	move.l	#ID_FMSND,d3		*ID
	jbsr	get_mem
	tst.l	d0
	bmi	err_exit_spfmt
	move.l	a0,fmsnd_buffer-work(a6)
	move.w	d4,fmsnd_n_max-work(a6)
	jsr	fmsnd_init-work(a6)
	moveq.l	#0,d0			*no error
	movem.l	(sp)+,reglist
	rts
enlrg_fmtb:
	moveq.l	#0,d3
	move.w	fmsnd_n_max-work(a6),d3
	move.l	d0,a1			*addr
	jbsr	enlarge_mem
	tst.l	d0
	bmi	err_exit_spfmt
	move.l	a0,fmsnd_buffer-work(a6)
	move.w	d4,fmsnd_n_max-work(a6)
	sub.w	d3,d4
	lsl.w	#4,d3
	move.w	d3,d1
	add.w	d1,d1
	add.w	d1,d3			*fmsnd_size倍
	add.w	d3,a0
	subq.w	#1,d4			*for dbra
@@:
	clr.w	(a0)
	lea	fmsnd_size(a0),a0
	dbra	d4,@b
	moveq.l	#0,d0
	movem.l	(sp)+,reglist
	rts
err_exit_spfmt:				*メモリ不足エラー
	moveq.l	#-1,d0
	movem.l	(sp)+,reglist
	rts

m_tempo:			*テンポセット	!v3
	*   cmd=$06
	* < d1.lw=tempo value(Timer A:77～32767,Timer B:20～5000,YM3802:1～32767
	*		      -1:で現在のテンポ取得)
	* < d1.hw=設定モード(-1:でZMUSICのワークに反映しない,0:反映する)
	* > d0.hw=timer value
	* > d0.lw=tempo value
	ori.w	#$0700,sr
	move.l	tempo_value-work(a6),d7
	cmpi.w	#-1,d1
	bne	@f
	move.l	d7,d0		*取得のみ
	swap	d0
	rts
@@:
	move.l	d1,d6
	tempo_range	d6
	move.w	d6,tempo_value-work(a6)
	jsr	calc_timer-work(a6)
	jsr	_init_timer-work(a6)
	bsr	midi_clk		*01/01/20
	tst.l	d6
	bpl	@f
	move.l	d7,tempo_value-work(a6)	*反映しないモードならば以前の値に戻す
@@:
	move.l	d7,d0
	swap	d0
	rts			*!01/01/20

m_tempo_patch:			*nmdb!!(MIDI I/Fが無い時rts)
				*タイミングクロック自動送出設定
midi_clk:			*タイミングクロック値セット
	* - d0,d6,d7,a0,a1
	* x d1,d2
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	movem.l	d0/a0,-(sp)

	move.w	tempo_value-work(a6),d2	*テンポからタイマ値を計算

	move.l	#30*1000*1000,d0	*１分=60*1000000μｓ
	moveq.l	#96,d1
	mulu	d2,d1
	bsr	wari			*d0/d1=d0...d1
	move.l	d0,d1
	cmpi.l	#$3fff,d1
	bhi	@f
	andi.w	#$3fff,d1
	bra	1f
@@:
	move.w	#$3fff,d1
1:
	lea	rgr,a0
	move.b	#8,(a0)
				midiwait
	ori.w	#$8000,d1
	move.w	d1,d2
	move.b	d1,grp6-rgr(a0)
				midiwait
	ror.w	#8,d1
	move.b	d1,grp7-rgr(a0)
				midiwait
midi_clk2:			*nmdb2!!
	add.w	#$10,a0		*２枚目のCZ6BM1用
	move.b	#8,(a0)
				midiwait
	move.b	d2,grp6-rgr(a0)
				midiwait
	ror.w	#8,d2
	move.b	d2,grp7-rgr(a0)
				midiwait
midi_clk2_e:
	movem.l	(sp)+,d0/a0
	move.w	(sp)+,sr
	rts

set_timer_value:		*タイマーの値を設定する
	*   cmd=$07
	* < d1.lw=timer value(Timer A:0～1023,Timer B:0～255,YM3802:0～8191)
	*		      -1:で現在のタイマ値取得)
	* < d1.hw=設定モード(-1:でZMUSICのワークに反映しない,0:反映する)
	* > d0.hw=tempo value
	* > d0.lw=timer value
	ori.w	#$0700,sr
	lea	tempo_value-work(a6),a1
	move.l	(a1)+,d7
	cmpi.w	#-1,d1		*取得
	beq	@f
	move.l	d1,d6
	move.w	d1,-2(a1)
set_timer_value_patch:		*使用タイマーによって変わる
	jsr	gyakusan_tm_m-work(a6)	*< a1.l=timer_value+2 >a1.l=tempo_value 
	jsr	_init_timer-work(a6)
	bsr	midi_clk		*01/01/20
	tst.l	d6		*反映しないモードならば以前の値に戻す
	bpl	@f
	move.l	d7,(a1)
@@:
	move.l	d7,d0
	rts

m_play:				*演奏開始	!v3
	*    cmd=$08
	* < a1.l=track numbers{tr.w,tr.w,...-1(.w)}
	*	=0 to play all(戻り値無し)
	* > (a0)	設定できなかったトラック番号の並びが返る
	*		-1=end code
	* > a1.l=next addr
	move.l	m_play_result-work(a6),a0
	move.w	#-1,(a0)
	move.l	a1,d0
	seq	play_bak_flg-work(a6)	*全トラック演奏か否か
	beq	m_play_all
m_play_again_entry:
	ori.w	#$700,sr
	move.l	a1,a2
	move.l	play_bak-work(a6),a3
@@:
	move.w	(a2)+,d0
	move.w	d0,(a3)+
	cmpi.w	#-1,d0
	bne	@b
	move.w	#-1,(a3)
m_play_lp:
	move.w	(a1)+,d1
	cmpi.w	#-1,d1
	beq	mpa_end			*routine exit
	move.l	play_trk_tbl-work(a6),a3
@@:
	moveq.l	#0,d0
	move.w	(a3)+,d0
	cmpi.w	#-1,d0
	beq	m_play_err
	cmp.w	d0,d1
	bne	@b
	jsr	top_ptr_set-work(a6)		*>a5=seq_wk_tbl n
	bra	m_play_lp
m_play_err:
	move.w	d1,(a0)+
	move.w	#-1,(a0)
	bra	m_play_lp

m_play_all:			*演奏可能なチャンネルを全部演奏
	jsr	stop_timer-work(a6)
	bsr	all_key_off2	*all key off

	move.l	play_trk_tbl-work(a6),a3
mpa_lp:
	moveq.l	#0,d0
	move.w	(a3)+,d0	*0-127
	cmpi.w	#-1,d0
	beq	mpa_end
	jsr	top_ptr_set-work(a6)	*>a5=seq_wk_tbl n
	bra	mpa_lp
mpa_end:
	move.l	m_play_result-work(a6),a0	*戻り値
m_play00:					*FUNC INTERCEPT_PLAY で書き変わる
	bset.b	#pf_PLAY,perform_flg-work(a6)
	move.l	obtevtjtbl-work+mp_jump(a6),d0
	beq	@f
	move.l	d0,a4
	jsr	(a4)
@@:
	ori.w	#$0700,sr
	clr.l	zmusic_int-work(a6)
	jsr	init_timer-work(a6)
	bsr	get_present_time		*> d1.l=00HHMMSS
	move.l	d1,play_start_time-work(a6)
	move.l	#-1,play_stop_time-work(a6)
	move.l	#-1,play_cont_time-work(a6)
m_play_patch:				*nmdb!!(patched to be RTS)
	clr.b	start_wait_flg-work(a6)	*$FA待ち(外部シーケンサホストモードの時意味をなす)
	bsr	midi_clk
	lea	rgr+6,a4		*=grp4
	move.b	#1,-6(a4)
					midiwait
mpp_fa0:				*外部シーケンサがホストの時はbra _mpp_fa0
	move.b	#%1111_1010,2(a4)	*midi start!($fa)
					midiwait
_mpp_fa0:
	move.b	f8_start-work(a6),(a4)	*trans $f8 start
					midiwait
_mpp:					*nmdb2!!(patched to be RTS)
	add.w	#$10,a4			*２枚目のCZ6BM1用
	move.b	#1,-6(a4)
					midiwait
mpp_fa1:				*外部シーケンサがホストの時はbra _mpp_fa1
	move.b	#%1111_1010,2(a4)	*midi start!($fa)
					midiwait
_mpp_fa1:
	move.b	f8_start-work(a6),(a4)	*trans $f8 start
					midiwait
	rts

m_play_again:				*前回のm_play()をもう一度やる	!v3
	*   cmd=$0a
	move.l	m_play_result-work(a6),a0
	tst.b	play_bak_flg-work(a6)
	bne	m_play_all		*全トラック演奏のケース
	move.l	play_bak-work(a6),a1
	bra	m_play_again_entry	*指定トラック演奏のケース

do_init_wks	macro	param		*デバイスの種類に依存しない初期化群
	*アフタータッチ関係
	move.l	#$00_00_80_ff,p_aftc_omt(a5)	*p_aftc_omt,p_aftc_rltv,p_aftc_flg,p_aftc_level
	move.l	d0,p_aftc_sw(a5)		*p_aftc_sw,p_aftc_sw2,p_aftc_1st_dly
	move.l	#$0001_0001,p_aftc_syncnt(a5)	*p_aftc_syncnt,p_aftc_syncnt2

	*ＰＭＯＤ関係
	init_pmod_wk	0,d0,a5

	*ＡＲＣＣ関係
	lea	p_arcc_param(a5),a4
	moveq.l	#arcc_max-1,d1
@@:
	init_arcc_wk	param,$80
	add.w	#__arcc_len,a4
	dbra	d1,@b

	*ベロシティ・シーケンス関係
	lea	p_vseq_param(a5),a4
	init_arcc_wk	0,0

	*ベンド関係
	move.l	d0,p_detune(a5)		*p_detune,p_special_tie
	move.l	d0,p_port_dly(a5)	*p_port_dly,p_port_tail
	move.l	d0,p_bend_dly(a5)	*p_bend_dly,p_bend_tail
	move.l	d0,p_port2_dly(a5)	*p_port2_dly,p_port_tail
	move.l	d0,p_port_pitch(a5)
	move.l	d0,p_port_flg(a5)	*p_port_flg,p_port2_flg,p_bend_sw,p_agogik_flg
	move.w	d0,p_bend_dst(a5)

	lea	p_measure(a5),a4	*一般ワーク関係
	move.l	d0,(a4)+		*p_measure
	move.l	d0,(a4)+		*p_voice_rsv,p_next_on,p_tone_set
	move.l	d0,(a4)+		*p_return
	move.l	mask_preserve-work(a6),d0	*マスクを保存?
	and.l	d0,(a4)+		*p_transpose,p_mask_mode,p_damper,p_seq_flag
	move.l	#$ffff_0000,(a4)+	*p_bank_msb,p_bank_lsb,p_pgm
	move.l	#$01_0c_ff_ff,(a4)+	*p_sync_wk,p_@b_range,p_vol16,p_velo16
	move.l	#$0000_ffff,(a4)+	*p_do_loop_flag,p_md_flg,p_how_many,p_last_note
	move.l	#$41_10_42_ff,(a4)+	*p_maker,p_device,p_module,p_effect1
	move.l	#$ffffffff,(a4)+	*p_effect3,p_effect4,p_effect2,p_effect5

	endm

init_wks:				*ここではレジスタを壊してはいけない(except d0,d1)
	* < d4.l=p_type,ch
	* X d0,d1,a4
	* - d4
	move.w	#$0001,(a5)			*p_step_time
init_wks2:
	tst.l	d4
	bmi	init_wks_md
	btst.l	#16,d4
	beq	init_wks_fm

init_wks_ad:				*ADPCM
	* < d4.l=p_type,ch
	* X d0,d1,a4
	* - d4
	moveq.l	#0,d0
	do_init_wks	7		*volume
	move.l	#$40_40_04_40,p_vol(a5)	*一度に複数を初期化(p_vol,p_velo,p_frq,p_pan)
	lea	ad_vol_tbl-work(a6),a4
	move.b	#$40,(a4,d4.w)
iw_ad0:
	lea	p_note(a5),a4
	move.l	#$ffff_0010,d0
@@:
	move.l	d0,(a4)+
	dbra	d0,@b
	rts

init_wks_fm:				*FM
	* < d4.l=p_type,ch
	* X d0,d1,a4
	* - d4
	moveq.l	#0,d0
	do_init_wks	0
	move.l	#$6a_6a_04_40,p_vol(a5)	*一度に複数を初期化(p_vol,p_velo,p_frq,p_pan)
	lea	fm_vol_tbl-work(a6),a4
	move.b	#$6a,(a4,d4.w)
iw_fm0:
	lea	p_note(a5),a4
	move.l	#$ffff_0010-1,d0
@@:
	move.l	d0,(a4)+
	dbra	d0,@b
	lea	fm_tone_set-work(a6),a4
	move.w	d4,d1
	add.w	d1,d1
	move.w	d0,(a4,d1.w)		*-1
	rts

init_wks_md:				*MIDI
	* < d4.l=p_type,ch
	* X d0,d1,a4
	* - d4
	moveq.l	#0,d0
	do_init_wks	11		*expression
	move.l	#$40_7f_04_40,p_vol(a5)	*一度に複数を初期化(p_vol,p_velo,p_frq,p_pan)
	move.l	d4,d0
	swap	d0
	lsl.w	#4,d0			*16倍
	lea	m0_vol_tbl-work(a6),a4
	add.w	d0,a4
	move.b	#$40,(a4,d4.w)
iw_md0:
	lea	p_note(a5),a4
	move.l	#$ffff_0010,d0
@@:
	move.l	d0,(a4)+
	dbra	d0,@b
	rts

m_play_status:				*演奏状態の検査
	*   cmd=$0b
	* < d1.l=0:check all ch mode
	* < a1.l=result status table address
	*        (a1.l=0とすると戻り値はテーブルで返らずにd0.lに返る)
	* > (a1)={active_device.l,active_device.l,...,-1.l }
	* > d0.l=(a1.l=0のときのみ。0:演奏終了,1:演奏中)
	*
	* < d1.l=1:check all track mode
	* < a1.l=result status table address
	*        (a1.l=0とすると戻り値はテーブルで返らずにd0.lに返る)
	* > (a1)={active_track.w,active_track.w,...,-1.w}
	* > d0.l=(a1.l=0のときのみ。0:演奏終了,1:演奏中)
	*
	* < d1.l=2:channel checking mode
	* < d2.hw=p_type($0000:FM,$0001:ADPCM,$8000～$8002:MIDI1～3)
	* < d2.lw=p_ch(0-15)
	* > d0.b=0 non active
	*	 ne    active
	*
	* < d1.l=3:track checking mode
	* < d2.l=track number(0-65534)
	* > d0.b=0 non active
	*	 ne    active
	add.w	d1,d1
	move.w	@f(pc,d1.w),d1
	jmp	@f(pc,d1.w)
@@:
	dc.w	m_stat_all_ch-@b
	dc.w	m_stat_all_tr-@b
	dc.w	m_stat_ch-@b
	dc.w	m_stat_tr-@b

m_stat_ch:				*チャンネルの検査
	move.l	play_trk_tbl-work(a6),a0
@@:
	moveq.l	#0,d0
	move.w	(a0)+,d0
	cmpi.w	#-1,d0
	beq	@f
	calc_wk	d0
	cmp.l	p_type(a5),d2		*検査チャンネルか
	bne	@b
	tst.b	p_track_stat(a5)	*チャンネルが生きているか
	bne	@b			*1つでも生きていたら生きていたことになる
	moveq.l	#-1,d0			*active
	rts
@@:
	moveq.l	#0,d0			*dead
	rts

m_stat_tr:				*トラックの検査
	move.l	play_trk_tbl-work(a6),a0
@@:
	moveq.l	#0,d0
	move.w	(a0)+,d0
	cmpi.w	#-1,d0
	beq	@f
	cmp.w	d0,d2			*検査トラックか
	bne	@b
	calc_wk	d0
	tst.b	p_track_stat(a5)	*チャンネルが生きているか
	bne	@f
	moveq.l	#-1,d0			*active
	rts
@@:
	moveq.l	#0,d0			*dead
	rts

m_stat_all_ch:				*全チャンネルの検査
	move.l	a1,d0
	beq	m_stat_all
	move.l	#-1,(a1)
	move.l	a1,a2
	move.l	play_trk_tbl-work(a6),a0
mstlp:
	moveq.l	#0,d0
	move.w	(a0)+,d0
	cmpi.w	#-1,d0
	beq	mst_exit
	calc_wk	d0
	tst.b	p_track_stat(a5)
	bne	mstlp
	move.l	p_type(a5),d0
	move.l	d0,(a2)+		*sentinel
	move.l	#-1,(a2)
	move.l	a1,a3
@@:
	cmp.l	(a3)+,d0
	bne	@b
	cmpa.l	a3,a2
	beq	mstlp
	move.l	#-1,-(a2)	*kill sentinel
	bra	mstlp
mst_exit:
	rts

m_stat_all_tr:				*全トラックの検査
	move.l	a1,d0
	beq	m_stat_all
	move.w	#-1,(a1)
	move.l	a1,a2
	move.l	play_trk_tbl-work(a6),a0
@@:
	moveq.l	#0,d0
	move.w	(a0)+,d0
	cmpi.w	#-1,d0
	beq	@f
	move.l	d0,d1
	calc_wk	d1
	tst.b	p_track_stat(a5)
	bne	@b
	move.w	d0,(a2)+
	move.w	#-1,(a2)
	bra	@b
@@:
	rts

m_stat_all:
	move.l	play_trk_tbl-work(a6),a0
@@:
	moveq.l	#0,d0
	move.w	(a0)+,d0
	cmpi.w	#-1,d0
	beq	@f
	move.l	d0,d1
	calc_wk	d1
	tst.b	p_track_stat(a5)
	bne	@b
	moveq.l	#-1,d0		*演奏中
	rts
@@:
	moveq.l	#0,d0		*演奏終了
	rts

m_stop:				*演奏停止
	*   cmd=$0c
	* < a1.l=track numbers{tr.w,tr.w,...-1(.w)}
	* <     =0 to stop all
	* > (a0)	設定できなかったトラック番号の並び
	*		-1=end code
	* > a1.l=next addr
	move.l	m_stop_result-work(a6),a0
	move.w	#-1,(a0)
	move.l	a1,d0
	beq	m_stop_all
m_stop_lp:
	move.w	(a1)+,d1
	cmpi.w	#-1,d1
	beq	msa_end				*routine exit
	move.l	play_trk_tbl-work(a6),a3
@@:
	moveq.l	#0,d0
	move.w	(a3)+,d0
	cmpi.w	#-1,d0
	beq	m_stop_err
	cmp.w	d0,d1
	bne	@b
	calc_wk	d0
	bset.b	#_ID_PLAY_STOP,p_track_stat(a5)	*演奏状態から停止状態へ
	bne	m_stop_lp			*もともと演奏停止してた
	move.l	p_type(a5),d4
	bsr	_ms_key_off
	bra	m_stop_lp
m_stop_err:
	move.w	d1,(a0)+
	move.w	#-1,(a0)
	bra	m_stop_lp

m_stop_all:			*演奏中の全トラックを停止
	jbsr	stop_smf	*SMFが送信中ならそれを停止
	jsr	stop_timer-work(a6)
*	bsr	all_key_off	*all key off

	move.l	play_trk_tbl-work(a6),a3
msa_lp:
	moveq.l	#0,d0
	move.w	(a3)+,d0
	cmpi.w	#-1,d0
	beq	msa_end
	calc_wk	d0
	bset.b	#_ID_PLAY_STOP,p_track_stat(a5)	*演奏状態から停止状態へ
	bne	msa_lp				*元もと演奏は停止していた
	move.l	p_type(a5),d4
	bsr	_ms_key_off
	bra	msa_lp
msa_end:
	bset.b	#pf_STOP,perform_flg-work(a6)
	move.l	obtevtjtbl-work+ms_jump(a6),d0
	beq	@f
	move.l	d0,a0
	jsr	(a0)
@@:
	move.l	m_stop_result-work(a6),a0	*戻り値
	bsr	get_present_time		*> d1.l=00HHMMSS
	move.l	d1,play_stop_time-work(a6)
	move.l	#-1,play_cont_time-work(a6)
m_stop_patch:				*nmdb!!(patched to be RTS)
	lea	rgr+6,a4		*=grp4
	ori.w	#$0700,sr
	move.b	#1,-6(a4)
					midiwait
	move.b	#%1111_1100,2(a4)	*midi stop($fc)
					midiwait
	move.b	f8_stop-work(a6),(a4)	*trans $f8 stop
					midiwait
_msp:					*nmdb2!!(patched to be RTS)
	add.w	#$10,a4			*２枚目のCZ6BM1用
	move.b	#1,-6(a4)
					midiwait
	move.b	#%1111_1100,2(a4)	*midi stop($fc)
					midiwait
	move.b	f8_stop-work(a6),(a4)	*trans $f8 stop
					midiwait
	rts

ms_key_off:				*キーオフする
	tst.l	d4
_ms_key_off:
	bmi	ms_key_off_md
	btst.l	#16,d4
	bne	ms_key_off_ad

ms_key_off_fm:				*強制的にFMをキーオフする
	* - a4(一部のルーチンでは保存される必要があるため)
	jmp	do_kn_fm-work(a6)

ms_key_off_ad:				*強制的にADPCMをキーオフする
	jmp	do_kn_ad-work(a6)

ms_key_off_md:				*強制的にMIDIをキーオフする
reglist	reg	a2/a4
	movem.l	reglist,-(sp)
	tst.b	p_damper(a5)
	beq	@f
	move.l	p_midi_trans(a5),a2
	moveq.l	#$b0,d0
	or.b	d4,d0		*ダンパーを一時的にオフする動作
	jsr	(a2)
	moveq.l	#64,d0
	jsr	(a2)
	moveq.l	#0,d0
	jsr	(a2)
	jsr	do_kn_md-work(a6)
	moveq.l	#$b0,d0
	or.b	d4,d0		*ダンパーをもとに戻す動作
	jsr	(a2)
	moveq.l	#64,d0
	jsr	(a2)
	moveq.l	#127,d0
	jsr	(a2)
	movem.l	(sp)+,reglist
	rts
@@:
	jsr	do_kn_md-work(a6)
	movem.l	(sp)+,reglist
	rts

m_cont:				*演奏再開
	*   cmd=$0d
	* < a1.l=track numbers{tr.w,tr.w,...-1(.w)}
	*	=0 to continue all
	* > (a0)	設定できなかったトラック番号の並び
	*		-1=end code
	* > a1.l=next addr
	move.l	m_cont_result-work(a6),a0
	move.w	#-1,(a0)
	move.l	a1,d0
	beq	m_cont_all
	ori.w	#$700,sr
m_cont_lp:
	move.w	(a1)+,d1
	cmpi.w	#-1,d1
	beq	mca_end		*routine exit
	move.l	play_trk_tbl-work(a6),a3
@@:
	moveq.l	#0,d0
	move.w	(a3)+,d0		*active ?
	cmpi.w	#-1,d0
	beq	m_cont_err
	cmp.w	d0,d1
	bne	@b
	calc_wk	d0
	bclr.b	#_ID_PLAY_STOP,p_track_stat(a5)		*on
	beq	m_cont_lp		*もともと再生中
	move.w	p_type(a5),d0
	bne	m_cont_lp
	move.w	p_ch(a5),d4		*FMの時は音色復元処理が必要
	jsr	restore_opm-work(a6)
	bra	m_cont_lp
m_cont_err:
	move.w	d1,(a0)+
	move.w	#-1,(a0)
	bra	m_cont_lp

m_cont_all:				*全チャンネル再開
	ori.w	#$0700,sr
	move.l	play_trk_tbl-work(a6),a3
mca_lp:
	moveq.l	#0,d0
	move.w	(a3)+,d0
	cmpi.w	#-1,d0
	beq	mca_end
	calc_wk	d0
	bclr.b	#_ID_PLAY_STOP,p_track_stat(a5)
	beq	mca_lp
	move.w	p_type(a5),d0
	bne	mca_lp
	move.w	p_ch(a5),d4		*FMの時は音色復元処理が必要
	jsr	restore_opm-work(a6)
	bra	mca_lp
mca_end:
	bset.b	#pf_CONT,perform_flg-work(a6)
	move.l	obtevtjtbl-work+mc_jump(a6),d0
	beq	@f
	move.l	d0,a0
	jsr	(a0)
@@:
	move.l	m_cont_result-work(a6),a0	*戻り値
*	ori.w	#$0700,sr
	jsr	init_timer-work(a6)
	bsr	get_present_time	*> d1.l=00HHMMSS
	move.l	d1,play_cont_time-work(a6)
m_cont_patch:				*nmdb!!(patched to be RTS)
	bsr	midi_clk
	lea	rgr+6,a4		*=grp4
	move.b	#1,-6(a4)
					midiwait
	move.b	#%1111_1011,2(a4)	*midi continue($fb)
					midiwait
	move.b	f8_start-work(a6),(a4)	*trans $f8 start
					midiwait
_mcp:					*nmdb2!!(patched to be RTS)
	add.w	#$10,a4			*２枚目のCZ6BM1用
	move.b	#1,-6(a4)
					midiwait
	move.b	#%1111_1011,2(a4)	*midi continue($fb)
					midiwait
	move.b	f8_start-work(a6),(a4)	*trans $f8 start
					midiwait
	rts

m_atoi:				*トラックデータアドレスを返す
	*   cmd=$0e
	* < d1.l=track number(0-65534)
	* > a0.l=track address(0:track doesn't exist)
	cmpi.l	#tr_max-1,d1
	bhi	t_illegal_track_number	*illegal trk number
	cmp.w	trk_n_max-work(a6),d1
	bcc	t_illegal_track_number		*illegal trk number
	move.l	trk_po_tbl-work(a6),d0
	beq	t_no_performance_data	*演奏データがない
	move.l	d0,a0
	lsl.l	#trk_tbl_size_,d1
	lea	ti_play_data(a0,d1.l),a0
	add.l	(a0)+,a0
	rts

wave_tbl_init:			*wave_tblの初期化
	* - all
	movem.l	d0-d1/a0-a1,-(sp)
	move.w	wave_n_max-work(a6),d0
	beq	exit_wti
	subq.w	#1,d0		*for dbra
	movea.l	wave_tbl-work(a6),a0
@@:
	bsr	do_init_wvtbl
	dbra	d0,@b
exit_wti:
	movem.l	(sp)+,d0-d1/a0-a1
	rts

do_init_wvtbl:
	* < a0.l=to be initialized
	* > a0.l=next
	* x a1
	lea	wv_dmy(pc),a1
	move.l	a1,(a0)+	*start address
	addq.w	#2,a1
	move.l	a1,(a0)+	*end address
	subq.w	#2,a1
	move.w	#$00ff,(a0)+	*loop mode
	move.l	a1,(a0)+	*loop start point
	addq.w	#4,a1
	move.l	a1,(a0)+	*loop end point
	clr.l	(a0)+		*loop time
	clr.l	(a0)+		*dummy
	clr.w	(a0)+		*name len
	clr.l	(a0)+		*name addr
	rts

wv_dmy:	dc.l	0

adpcm_tbl_init:					*adpcm_tblの初期化
	* - all
	bsr	init_adpcm_tbl
	bra	init_adpcm_tbl2

init_midibd:				*MIDIボードのイニシャライズ
					*nmdb!!
	move.w	sr,-(sp)
	ori.w	#$700,sr
	movem.l	d0-d2/a0-a1,-(sp)
	moveq.l	#0,d0			*レジスタ・ワークの初期化
	lea	r06_0-work(a6),a0
	move.l	d0,(a0)+		*r06_0,r06_1,wr1,dummy
	move.b	midi_board-work(a6),d2
	beq	exit_i_mdbd_
	btst.l	#if_m0,d2
	beq	@f
	lea	rgr,a0
	moveq.l	#$80,d1
	bsr	init_cz6bm1
@@:
	btst.l	#if_m1,d2
	beq	@f
	lea	rgr+$10,a0
	moveq.l	#$a0,d1
	bsr	init_cz6bm1
@@:
	btst.l	#if_mr0,d2
	beq	exit_i_mdbd_
	lea	rs_data(pc),a0
	moveq.l	#(rs_data_e-rs_data)-1,d0
	lea	scc_a,a1
	tst.b	(a1)			*dummy read
@@:
	move.b	(a0)+,(a1)
	dbra	d0,@b
	move.b	#1,(a1)
	moveq.l	#%0000_0010,d0
	move.b	d0,wr1-work(a6)
	move.b	d0,(a1)
exit_i_mdbd_:
	movem.l	(sp)+,d0-d2/a0-a1
	move.w	(sp)+,sr
exit_i_mdbd:
	rts

init_cz6bm1:
	* < d1=vector offset
	* < a0=rgr
	* X d0-d1/a0-a1
	move.b	#$80,(a0)	*initial reset
	moveq.l	#0,d0		*1/60/512=0.000032secのウエイト
	jsr	h_wait-work(a6)
	clr.b	(a0)		*initial reset end
	midiwait
	move.b	d1,grp4-rgr(a0)	*write vector offset
	midiwait
	lea	md_init_tbl_i(pc),a1
	cmpi.b	#1,timer_mode-work(a6)
	beq	@f
	lea	md_init_tbl_e(pc),a1
@@:
	move.b	(a1)+,d0
	beq	@f
	move.b	d0,d1
	lsr.b	#4,d0
	move.b	d0,(a0)
	midiwait
	andi.w	#$0f,d1
	add.w	d1,d1
	move.b	(a1)+,ivr-rgr(a0,d1.w)
	midiwait
	bra	@b
@@:
	rts

md_init_tbl_i:			*X680x0がホストケース
	dc.b	$06,%00000000
	dc.b	$66,%00000010
	dc.b	$67,%00011000
	dc.b	$65,%10010100
	dc.b	$55,%10000101
	dc.b	$44,%00001000
	dc.b	$35,%10010000
	dc.b	$24,%00001000
	dc.b	$25,%00000000
	dc.b	$05,%00000010
	dc.b	$03,%11111111
	dc.b	$14,%00101011
	dc.b	$94,%00000000
	dc.b	$35,%11010001
	dc.b	$55,%10000001
	dc.b	0

md_init_tbl_e:			*外部シーケンサがホストケース
	dc.b	$06,%00000000
	dc.b	$66,%00000010
	dc.b	$67,%00011000
	dc.b	$65,%10010100
	dc.b	$55,%10000101
	dc.b	$44,%00001000
	dc.b	$35,%10010000
	dc.b	$24,%00001000
	dc.b	$25,%00000000
	dc.b	$05,%00000010
	dc.b	$03,%11111111
	dc.b	$14,%00111001
	dc.b	$94,%00000000
	dc.b	$35,%11010001
	dc.b	$55,%10000001
	dc.b	$75,%00110001
	dc.b	0

*	.dc.b	$09,$80,$04,$44,$01,$00,$03,$c0		*Ussy's Library
*	.dc.b	$05,$e2,$09,$01,$0b,$50,$0e,$02
*	.dc.b	$0c,$03,$0d,$00,$03,$c1,$05,$ea
*	.dc.b	$0e,$03,$10,$10,$01,$12,$09,$09
rs_data:
	dc.b	$09,$80,$04,$44,$01,$00,$03,$c0		*Z's(5MHz)
	dc.b	$05,$e2,$09,$01,$0b,$50,$0e,$02
	dc.b	$0c
bps_v:	dc.b	$03					*3:31250,2:39062
	dc.b		$0d,$00,$03,$c1,$05,$ea
	dc.b	$0e,$03,$10,$10,$01,$12,$0f,$00
	dc.b	$c0,$10,$30,$38,$02,$50,$09,$09
rs_data_e:
	.even

init_opmwk:			*FM音源チャンネルワークの初期化
	* X d0,a1		*-Vスイッチによりパッチが当たる(bra exit_ifmwk)
	lea	_opm-work(a6),a1
	moveq.l	#256/4-1,d0
@@:
	clr.l	(a1)+
	dbra	d0,@b
	move.l	#$00010203,opm_kon+0-work(a6)
	move.l	#$04050607,opm_kon+4-work(a6)
	lea	cf-work(a6),a1
	moveq.l	#10-1,d0
@@:
	clr.l	(a1)+
	dbra	d0,@b
exit_ifmwk:
	rts

init_midiwk:			*MIDIのチャンネルワークの初期化
	* X d0,a0,a1,a2		*-Vスイッチによりパッチが当たる(bra exit_mdwk)
	lea	mm0_adr-work(a6),a0
	lea	midi_if_tbl-work(a6),a1
imdwklp0:
	moveq.l	#0,d0
	move.b	(a1)+,d0
	bmi	exit_mdwk
	add.w	d0,d0
	move.l	(a0,d0.w),a2
	moveq.l	#chwklen/4-1,d0
@@:
	move.l	#-1,(a2)+
	dbra	d0,@b
	bra	imdwklp0
exit_mdwk:
	rts

set_master_clock:			*全音符の絶対音長設定
	*   cmd=$0f
	* < a1.l=0の時は値の問い合わせのみ
	* < d1.l=0:通常音楽演奏用の設定,1:効果音演奏用の設定
	* < $00(a1).w=拍子(上位バイト:分子/下位バイト:分母)
	* < $02(a1).b=メトロノーム速度(音楽的音長)
	* < $03(a1).b=reserve
	* < $04(a1).w=調号(SMFの調号フォーマットに準拠)
	* < $06(a1).w=全音符の絶対音長
	* > a0.l=現在の設定値の格納アドレス
	*	 パラメータの格納状況は上記に準ずる。
	ori.w	#$0700,sr
	lea	meter-work(a6),a0	*問い合わせ時にはこれがそのまま戻り値
	lea	set_new_t_max_min(pc),a2
	tst.l	d1
	beq	@f
	lea	meter_se-work(a6),a0	*問い合わせ時にはこれがそのまま戻り値
	lea	set_new_t_max_min_se(pc),a2
@@:
	move.l	a0,a3
	move.l	a1,d0
	beq	t_dat_ok
	cmpi.w	#max_note_len,6(a1)	*mst_clk max check
	bhi	t_illegal_note_length
	move.l	(a1)+,(a3)+		*meter(.w),metronome(.b),dummy(.b)同時格納
	move.l	(a1)+,(a3)+		*key(.w),mst_clk(.w)同時格納
	jsr	(a2)
	bra	t_dat_ok

reglist	reg	d0/a1-a2/a4
set_new_t_max_min_se:
	* (smc_work+4).w=_@t_max_se
	* a2.l=t_min_se
	* a4.l=_gyakusan_tm_X
	movem.l	reglist,-(sp)
	move.w	_@t_max_se-work(a6),smc_work+2-work(a6)
	lea	t_min_se-work(a6),a2
	move.l	gyakusan_table+4-work(a6),a4	*_gyakusan_tm_X
	bra	@f

set_new_t_max_min:
	* (smc_work+2).w=_@t_max
	* a2.l=t_min
	* a4.l=gyakusan_tm_X
	movem.l	reglist,-(sp)
	move.w	_@t_max-work(a6),smc_work+2-work(a6)
	lea	t_min-work(a6),a2
	move.l	gyakusan_table-work(a6),a4	*gyakusan_tm_X
@@:
	lea	smc_work+4-work(a6),a1
	jsr	(a4)			*> d0.w=tempo value d1.w=timer value
	cmpi.w	#100,d0			*適当なテンポ
	bls	@f			*この値より小さければ最低テンポ値とみなす
	move.w	d0,2(a2)		*t_max
	bra	1f
@@:
	move.w	d0,(a2)+		*t_min
1:
	lea	smc_work+2-work(a6),a1
	move.w	#1,(a1)+		*min timer value
	jsr	(a4)			*> d0.w=tempo value d1.w=timer value
	move.w	d0,(a2)			*t_max
	movem.l	(sp)+,reglist
	rts

m_play2:				*もう一度共通コマンドから再演奏
	*   cmd=$09
	move.l	trk_buffer_top-work(a6),d0
	beq	t_no_zmd_err		*ZMDがない
	moveq.l	#0,d2
	move.l	d0,a1
	move.l	#$00ff0000,mask_preserve-work(a6)	*マスクを保存して演奏するマーク
	bra	@f

play_zmd:					*コンパイルデータの演奏
	*   cmd=$10
	* < d2.l=total data size d2がゼロならバッファへは転送せず即演奏
	*	 サイズはヘッダ8バイト分は含んでも含まなくてもいい
	* < a1=play data address
	*  (a1)=data...(header8バイトの次から)
	* > d0.l=error code
	clr.l	mask_preserve-work(a6)		*マスクを初期化して演奏するマーク
@@:
	jbsr	stop_timer
	bsr	all_key_off2
_play_zmd:
	move.l	d2,d6				*サイズ保存
	tst.l	z_trk_offset-8(a1)		*演奏データなし
	beq	direct_play
	lea	meter-work(a6),a2
	lea	z_meter-8(a1),a0
	move.l	(a0)+,(a2)+			*meter(.w),metronome(.b),dummy(.b)
	move.l	(a0)+,d0			*key(.w),mst_clk(.w)
	move.l	(a2),d1
	move.l	d0,(a2)+
	move.w	(a0)+,(a2)+			*tempo_value(.w)
	cmp.w	d0,d1
	beq	@f
	bsr	set_new_t_max_min
@@:
	moveq.l	#0,d2
	move.l	d2,fm_tune_tbl-work(a6)
	move.l	d2,pcm_tune_tbl-work(a6)
	init_pmod_wk	agogik_base,d2,a6
	bsr	calc_timer

	move.l	d6,d2				*d2=size
	beq	direct_play
	move.l	#ID_ZMD,d3			*employment
	bsr	get_mem				*>a0.l=address,d0.l=error code
	tst.l	d0
	bmi	t_out_of_memory
	move.l	a0,trk_buffer_top-work(a6)
	move.l	d2,trk_buffer_size-work(a6)	*d2=long word border size
	lea	(a0,d2.l),a2
	move.l	a2,trk_buffer_end-work(a6)
	move.l	a0,a2				*a0=a2=destination
@@:						*ZMDを用意したバッファへ転送
	move.l	(a1)+,(a0)+
	subq.l	#4,d2
	bne	@b
	bra	do_comn_cmd
direct_play:
	move.l	a1,a2
	move.l	a1,trk_buffer_top-work(a6)
	move.l	d2,trk_buffer_size-work(a6)	*d2=long word border size
	add.l	d2,a1
	move.l	a1,trk_buffer_end-work(a6)
do_comn_cmd:
	st.b	play_bak_flg-work(a6)	*m_play2パラメータ初期化
	move.l	(a2)+,d0		*共通コマンドの有無チェック(有ればその値がオフセット)
	beq	@f
	move.l	a2,-(sp)
	add.l	d0,a2
	bsr	exec_comn_cmd		*共通コマンド実行
					*set information block & play
	move.l	(sp)+,a2
@@:
	move.l	(a2)+,d0
	pea.l	(a2)			*後で使用
	beq	exec_ctrl_cmd		*演奏データ無し
	add.l	d0,a2
	move.w	(a2)+,d5		*num of trks(0-65534)
	cmp.w	trk_n_max-work(a6),d5
	bcs	@f
	bsr	spread_trk_n			*トラック数限界値拡張処理へ
	bmi	t_out_of_memory
@@:
	move.l	a2,trk_po_tbl-work(a6)
						*各トラックの先頭アドレスをワークへセット
	move.l	play_trk_tbl-work(a6),a3
	movea.l	seq_wk_tbl-work(a6),a5
	moveq.l	#0,d3
	lea	ii_bit_work-work(a6),a4
	move.l	d3,(a4)+		*ii_fm_bitからii_mr1_bitまでを初期化
	move.l	d3,(a4)+
	move.l	d3,(a4)+
set_i_lp01:
do_top_ptr_set	macro	para
	local	pcd_md,pcd_ad,pcd_fm,pcd_dvset,exit_pcd
	move.l	(a2)+,d4
	bpl	@f			*演奏トラックではない場合(rec or pattern)
	subq.w	#4,a2
	move.l	a2,pattern_trk-work(a6)
	.if	(para=1)
	lea	ti_size(a2),a2		*次のトラック追加情報までのオフセットスキップ
	.endif
	bra	exit_pcd
@@:
	.if	(para=1)
	move.w	d3,(a3)+
	.endif
	move.l	a5,a1
	move.w	#$0001,(a1)+		*dummy step time
	move.l	d4,(a1)+		*p_track_stat,p_track_mode,p_trkfrq,p_trkfrq_wk
	move.w	(a2)+,d4		*p_type
	beq	pcd_fm			*FMの場合
	bpl	pcd_ad			*ADPCMの場合
pcd_md:					*MIDIの場合
	move.l	#int_play_ope_md,p_int_play_ope(a5)
	cmpi.w	#$ffff,d4		*current midi ?
	bne	@f
	move.w	current_midi_out_w-work(a6),d4
	move.w	current_midi_out_r-work(a6),p_midi_if(a5)
	bra	1f
@@:
	ext.w	d4
	move.w	d4,p_midi_if(a5)
	lea	midi_if_tbl-work(a6),a4
	move.b	(a4,d4.w),d4		*0,2,4
	andi.w	#$7f,d4
1:
	move.w	d4,d1
	lsr.b	#1,d4			*0,1,2
	ori.w	#$8000,d4
	moveq.l	#0,d0
	move.w	@f(pc,d1.w),d0
	lea	@f(pc,d0.l),a4
	move.l	a4,p_midi_trans(a5)
	lsl.w	#3,d1			*これで16倍
	lea	fo_ch_m0-work(a6,d1.w),a4
	swap	d4
	move.w	(a2)+,d4		*p_ch
	move.l	d4,(a1)+		*p_type(a5)
	clr.b	(a4,d4.w)		*init fader flag work
	jbsr	init_wks_md
	jsr	init_inst_md-work(a6)
	bra	pcd_dvset
@@:
	dc.w	m_out_m0-@b
	dc.w	m_out_m1-@b
	dc.w	m_out_r0-@b
	dc.w	m_out_r1-@b
pcd_ad:
	move.l	#int_play_ope_ad,p_int_play_ope(a5)
	swap	d4
	move.w	(a2)+,d4		*p_ch
	move.l	d4,(a1)+		*p_type(a5)
	clr.b	fo_ch_ad-work(a6,d4.w)	*init fader flag work
	move.l	opmset_bsr_ms-work(a6),a4	*!97/10/10
	move.l	a4,p_opmset(a5)			*!97/10/10
	jbsr	init_wks_ad
	jsr	init_inst_ad-work(a6)
	bra	pcd_dvset
pcd_fm:
	move.l	#int_play_ope_fm,p_int_play_ope(a5)
	swap	d4
	move.w	(a2)+,d4		*p_ch
	move.l	d4,(a1)+		*p_type(a5)
	clr.b	fo_ch_fm-work(a6,d4.w)	*init fader flag work
	move.l	opmset_bsr_ms-work(a6),a4
	move.l	a4,p_opmset(a5)
	jsr	init_inst_fm-work(a6)	* < a4.l=opmset
	jbsr	init_wks_fm
pcd_dvset:
	move.l	(a2)+,a4		*演奏データまでのoffset
	add.l	a2,a4
	move.l	a4,(a1)+		*p_data_pointer
	move.l	a4,(a1)+		*p_now_pointer
	.if	(para=1)
	addq.w	#4,a2			*次のトラック追加情報までのオフセットスキップ
	addq.w	#1,d3			*トラック番号増加
	lea	trwk_size(a5),a5
	.endif
exit_pcd:
	endm
	do_top_ptr_set	1
	dbra	d5,set_i_lp01

	move.w	d5,(a3)			*set end code/write 255
exec_ctrl_cmd:
	move.l	(sp)+,a2		*演奏制御コマンドがあるか
	move.l	(a2)+,d0
	beq	m_play00
	add.l	d0,a2
	clr.b	ctrl_play_work-work(a6)	*ワーク初期化
ctrl_cmd_lp:
	moveq.l	#0,d1
	move.w	(a2)+,d1
	bmi	t_dat_ok		*end
	move.l	ctrl_cmd_tbl(pc,d1.w),a1
	jmp	(a1)

ctrl_cmd_tbl:
	dc.l	ctrl_play		*0
	dc.l	ctrl_stop		*2
	dc.l	ctrl_cont		*4
	dc.l	ctrl_mfader		*6
	dc.l	ctrl_tfader		*8
	dc.l	ctrl_tmask		*10
ctrl_cmd_tbl_end:
n4_of_ctrl_cmd:	equ	ctrl_cmd_tbl_end-ctrl_cmd_tbl

get_present_time:			*演奏開始時間記録
reglist	reg	d0/d2-d3/a2
	* > d1.l=現在時間(00HHMMSS)
	movem.l	reglist,-(sp)
@@:
	lea	$e8a00c,a2		*演奏開始時間を記録しておく
	bclr.b	#0,$e8a01b-$e8a00c(a2)	*bank 0
	move.w	-(a2),d2		*hour
	andi.w	#$0f,d2
	lsl.w	#4,d2
	move.w	-(a2),d0
	andi.w	#$0f,d0
	or.w	d0,d2
	swap	d2
	move.w	-(a2),d2		*minute
	andi.w	#$0f,d2
	lsl.w	#4,d2
	move.w	-(a2),d0
	andi.w	#$0f,d0
	or.w	d0,d2
	lsl.w	#8,d2
	move.w	-(a2),d3		*second
	andi.w	#$0f,d3
	lsl.w	#4,d3
	move.w	-(a2),d0
	andi.w	#$0f,d0
	or.w	d0,d2
	or.w	d3,d2

	lea	$e8a00c,a2		*演奏開始時間を記録しておく
	move.w	-(a2),d1		*hour
	andi.w	#$0f,d1
	lsl.w	#4,d1
	move.w	-(a2),d0
	andi.w	#$0f,d0
	or.w	d0,d1
	swap	d1
	move.w	-(a2),d1		*minute
	andi.w	#$0f,d1
	lsl.w	#4,d1
	move.w	-(a2),d0
	andi.w	#$0f,d0
	or.w	d0,d1
	lsl.w	#8,d1
	move.w	-(a2),d3		*second
	andi.w	#$0f,d3
	lsl.w	#4,d3
	move.w	-(a2),d0
	andi.w	#$0f,d0
	or.w	d0,d1
	or.w	d3,d1

	cmp.l	d1,d2			*時間読み込みエラー防止のため
	bne	@b
	movem.l	(sp)+,reglist
	rts

ctrl_play:			*play(演奏開始)
	move.w	#ZM_PLAY,fnc_no-work(a6)
	cmpi.w	#-1,(a2)
	bne	@f
	pea	2(a2)		*skip -1 mark
	suba.l	a1,a1		*a1=0
	bsr	m_play
	move.l	(sp)+,a2
	bra	ctrl_cmd_lp
@@:
	tas.b	ctrl_play_work-work(a6)
	bmi	1f
	move.l	play_trk_tbl-work(a6),a1
@@:
	moveq.l	#0,d0
	move.w	(a1)+,d0
	cmpi.w	#-1,d0
	beq	1f
	calc_wk	d0
	tas.b	p_track_stat(a5)	*make Dead
	bra	@b
1:
	move.l	a2,a1
	bsr	m_play
	move.l	a1,a2
	bra	ctrl_cmd_lp

ctrl_stop:			*stop(演奏停止)
	move.w	#ZM_STOP,fnc_no-work(a6)
	cmpi.w	#-1,(a2)
	bne	@f
	addq.w	#2,a2		*skip -1 mark
	suba.l	a1,a1		*a1=0
	bsr	m_stop
	bra	ctrl_cmd_lp
@@:
	move.l	a2,a1
	bsr	m_stop
	move.l	a1,a2
	bra	ctrl_cmd_lp

ctrl_cont:			*continue(演奏再開)
	move.w	#ZM_CONT,fnc_no-work(a6)
	cmpi.w	#-1,(a2)
	bne	@f
	addq.w	#2,a2		*skip -1 mark
	suba.l	a1,a1		*a1=0
	bsr	m_cont
	bra	ctrl_cmd_lp
@@:
	move.l	a2,a1
	bsr	m_cont
	move.l	a1,a2
	bra	ctrl_cmd_lp

ctrl_mfader:			*master_fader(マスターフェーダー)
	move.w	#ZM_MASTER_FADER,fnc_no-work(a6)
	move.l	a2,a1
	bsr	master_fader
	move.l	a1,a2
	bra	ctrl_cmd_lp

ctrl_tfader:			*track_fader(トラックフェーダー)
	move.w	#ZM_SET_TR_OUTPUT_LEVEL,fnc_no-work(a6)
	move.l	a2,a1
	bsr	set_tr_output_level
	move.l	a1,a2
	bra	ctrl_cmd_lp

ctrl_tmask:			*track_mask(トラックマスク)
	move.w	#ZM_MASK_TRACKS,fnc_no-work(a6)
	move.l	#$00ff0000,mask_preserve-work(a6)	*マスクを保存して演奏するマーク 97/4/8
	cmpi.w	#-1,(a2)
	bne	@f
	addq.w	#2,a2		*skip -1 mark
	suba.l	a1,a1		*a1=0
	moveq.l	#0,d1		*0:enable
	move.w	(a2)+,d1	*mode(-1,0,+1)
	bsr	mask_tracks
	bra	ctrl_cmd_lp
@@:
	move.l	a2,a1
	bsr	mask_tracks
	move.l	a1,a2
	bra	ctrl_cmd_lp

all_key_off2:			*演奏中の全チャンネルをノートオフする
reglist	reg	d0-d5/a2-a5
	movem.l	reglist,-(sp)
	move.l	play_trk_tbl-work(a6),a2
ako2_lp:
	moveq.l	#0,d0
	move.w	(a2)+,d0
	cmpi.w	#-1,d0
	beq	ako2_exit
	calc_wk	d0
	tst.b	p_track_stat(a5)		*play_end,dead?
	bne	ako2_next			*既に停止中
	move.l	p_type(a5),d4
	bsr	_ms_key_off
ako2_next:
	ori.b	#ID_PLAY_STOP,p_track_stat(a5)	*st.b	p_track_stat(a5)
	bra	ako2_lp
ako2_exit:
	movem.l	(sp)+,reglist
	rts

spread_trk_n:				*トラック関連のワーク確保
	* < d5.l=new track max(0/1-65535)
	* - all
reglist	reg	d0/d2-d3/d5/a0-a1
	andi.l	#$ffff,d5
	beq	exit_sptrk		*0ならば処理無し
	movem.l	reglist,-(sp)
	addq.l	#8,d5			*上限を増やす
	cmpi.l	#tr_max,d5
	bls	@f
	move.l	#tr_max,d5
@@:
	move.l	d5,d2			*seq_wk_tblのサイズ
	swap	d2
	lsr.l	#16-trwk_size_,d2

	move.l	d5,d0
	addq.l	#1,d0			*+1
	add.l	d0,d0			*x2
	move.l	d0,-(sp)
	add.l	d0,d2			*play_trk_tblのサイズ
	add.l	d0,d2			*play_bakのサイズ

	move.l	d5,d0
	lsr.l	#3,d0			*/8
	addq.l	#2,d0			*最低でも2バイトにしたいから
	bclr.l	#0,d0			*.even
	move.l	d0,-(sp)
	add.l	d0,d2			*done_bitのサイズ

	move.l	d5,d0
	addq.l	#1,d0			*+1
	lsl.l	#2,d0			*×4
	move.l	d0,-(sp)
	lsl.l	#3,d0
	add.l	d0,d2			*result系のサイズ×nof_result(8)

	move.l	_result_start-work(a6),d0	*enlarge or get?
	bne	enlrg_sqtb
	move.l	#ID_SYSTEM,d3		*ID
	bsr	get_mem
	tst.l	d0
	bpl	@f
	bra	err_exit_sptrk
enlrg_sqtb:
	move.l	d0,a1			*addr
	bsr	enlarge_mem
	tst.l	d0
	bmi	err_exit_sptrk
@@:
	lea	_result_start-work(a6),a1
	moveq.l	#nof_result-1,d0
	move.l	(sp)+,d2		*get back result系size
@@:
	move.l	a0,(a1)+
	add.l	d2,a0
	dbra	d0,@b

	move.l	a0,done_bit-work(a6)
	add.l	(sp)+,a0		*get back don_bit size

	move.l	(sp)+,d2		*get back play_trk_tbl(&play_bak) size
	move.l	a0,play_trk_tbl-work(a6)
	move.w	#-1,(a0)			*初期化
	add.l	d2,a0

	move.l	a0,play_bak-work(a6)
	move.w	#-1,(a0)			*初期化
	add.l	d2,a0

	lea	128(a0),a0		*seq_wk_tbl系ワークはベースアドレスよりも
	move.l	a0,seq_wk_tbl-work(a6)	*128バイト手前をアクセスすることがあるから
	move.w	d5,trk_n_max-work(a6)
exit_sptrk:
	moveq.l	#0,d0			*no error mark
	movem.l	(sp)+,reglist
	rts
err_exit_sptrk:				*メモリ不足エラー
	lea	4*3(sp),sp
	moveq.l	#-1,d0			*error mark
	movem.l	(sp)+,reglist
	rts

play_zmd_se:			*コンパイルデータの効果音サイド演奏
	*   cmd=$11
	* < a1=play data address
	*  (a1)=data...(header8バイトの次から)
	clr.l	mask_preserve-work(a6)		*マスクを初期化して演奏するマーク
	bsr	stop_timer_se
	lea	meter_se-work(a6),a2
	lea	z_meter-8(a1),a0
	move.l	(a0)+,(a2)+			*meter(.w),metronome(.b),dummy(.b)
	move.l	(a0)+,d0			*key(.w),mst_clk(.w)
	move.l	(a2),d1
	move.l	d0,(a2)+
	move.w	(a0)+,(a2)+			*tempo_value(.w)
	cmp.w	d0,d1
	beq	@f
	bsr	set_new_t_max_min_se
@@:
	moveq.l	#0,d2
	move.l	d2,fm_tune_tbl-work(a6)
	move.l	d2,pcm_tune_tbl-work(a6)
	init_pmod_wk	agogik_base_se,d2,a6		*< d2=0
	bsr	calc_timer_se

	move.l	a1,a2
	move.l	(a2)+,d0	*共通コマンドの有無チェック
	beq	@f
	move.l	a2,-(sp)
	add.l	d0,a2
	bsr	exec_comn_cmd_se	*共通コマンド実行
				*set information block & play
	move.l	(sp)+,a2
	move.l	(a2)+,d0	*演奏データまでのオフセット
	beq	t_dat_ok
	add.l	d0,a2
	move.w	(a2)+,d5	*num of trks
	cmp.w	se_tr_max-work(a6),d5
	bls	@f
	move.w	se_tr_max-work(a6),d5
@@:				*各トラックの先頭アドレスをワークへセット
	move.l	a2,trk_po_tbl_se-work(a6)
	move.l	play_trk_tbl_se-work(a6),a3
	movea.l	seq_wk_tbl_se-work(a6),a5
	moveq.l	#0,d3
set_i_lp01_se:
	move.l	(a2)+,d4
	bpl	@f
	subq.w	#4,a2
	move.l	a2,pattern_trk_se-work(a6)
	lea	ti_size(a2),a2
	bra	exit_pcd_se
@@:
	move.w	d3,(a3)+
	move.l	a5,a1
	move.w	#$0001,(a1)+		*dummy step time
	bset.l	#24+_ID_SE,d4
	move.l	d4,(a1)+		*p_track_stat,p_track_mode,p_trkfrq,p_trkfrq_wk
	move.w	(a2)+,d4		*get p_type
	beq	pcd_fm_se
	bpl	pcd_ad_se
	move.l	#int_play_ope_md,p_int_play_ope(a5)
	cmpi.w	#$ffff,d4
	bne	@f
	move.w	current_midi_out_w(pc),d4
	move.w	current_midi_out_r(pc),p_midi_if(a5)
	bra	1f
@@:
	ext.w	d4
	move.w	d4,p_midi_if(a5)
	lea	midi_if_tbl(pc),a4
	move.b	(a4,d4.w),d4		*0,2,4
	andi.w	#$7f,d4
1:
	move.w	d4,d1
	lsr.b	#1,d4			*0,1,2
	ori.w	#$8000,d4
	moveq.l	#0,d0
	move.w	@f(pc,d1.w),d0
	lea	@f(pc,d0.l),a4
	move.l	a4,p_midi_trans(a5)
	swap	d4
	move.w	(a2)+,d4		*get p_ch
	move.l	d4,(a1)+		*p_type,p_ch
	bsr	ms_key_off_md
	bsr	init_wks_md
	bra	pcd_dvset_se
@@:
	dc.w	m_out_m0-@b
	dc.w	m_out_m1-@b
	dc.w	m_out_r0-@b
	dc.w	m_out_r1-@b
pcd_ad_se:
	move.l	#int_play_ope_ad,p_int_play_ope(a5)
	swap	d4
	move.w	(a2)+,d4		*get p_ch
	move.l	d4,(a1)+		*p_type,p_ch
	lea	opmset-work(a6),a4	*!97/10/10
	move.l	a4,p_opmset(a5)		*!97/10/10
	bsr	ms_key_off_ad
	bsr	init_wks_ad
	bra	pcd_dvset_se
pcd_fm_se:
	move.l	#int_play_ope_fm,p_int_play_ope(a5)
	swap	d4
	move.w	(a2)+,d4		*get p_ch
	move.l	d4,(a1)+		*p_type,p_ch
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	bset.b	d4,mask_opm_ch-work(a6)	*効果音モードFMレジスタマスク
	lea	opmset-work(a6),a4
	move.l	a4,p_opmset(a5)
	bsr	ms_key_off_fm
	bsr	init_inst_fm		*< a4.l=opmset
	move.w	(sp)+,sr
	bsr	init_wks_fm
pcd_dvset_se:
	move.l	(a2)+,a4		*演奏データまでのoffset
	add.l	a2,a4
	move.l	a4,(a1)+		*p_data_pointer
	move.l	a4,(a1)+		*p_now_pointer
	addq.w	#4,a2			*トラック追加情報までのオフセットスキップ
	addq.w	#1,d3
	lea	trwk_size(a5),a5
exit_pcd_se:
	dbra	d5,set_i_lp01_se

	move.b	d5,(a3)			*set end code/write 255
	ori.w	#$0700,sr
	bra	init_timer_se

se_play:			*効果音モードプレイ
	*   cmd=$12		高速処理が要求されるのでﾊﾟﾗﾒｰﾀﾁｪｯｸは無し
	* < a1.l=compiled data address
	* (a1).w=total of play trks...(トラック・チャンネル情報テーブルから)
	* PMD,AMDは初期化されない
se_play_patch:					*この部分は始めの一回しか実行されない
	move.l	#$00c0_0078,mst_clk_se-work(a6)	*master_clock(.w),tempo_value(.w)
	bsr	set_new_t_max_min_se
	moveq.l	#0,d2
	move.l	d2,fm_tune_tbl-work(a6)
	move.l	d2,pcm_tune_tbl-work(a6)
	init_pmod_wk	agogik_base_se,d2,a6	*< d2=0
	bsr	calc_timer_se
	patch_w2	BRA,se_play_patch,go_se_play
	bsr	cache_flush
go_se_play:
*	clr.l	mask_preserve-work(a6)		*マスクを初期化して演奏するマーク
	move.w	(a1)+,d5			*num of trks
*	ori.w	#$700,sr
	bsr	stop_timer_se
sepl_lp01:
	move.l	(a1),d2
	bpl	@f
	move.l	a1,pattern_trk_se-work(a6)
@@:
	bset.l	#24+_ID_SE,d2		*p_track_stat,p_track_mode,p_trkfrq,p_trkfrq_wk
	addq.w	#4,a1
	move.w	(a1)+,d4		*get p_type
	beq	_pcd_fm_se
	bpl	_pcd_ad_se
	move.l	#int_play_ope_md,d1
	cmpi.w	#$ffff,d4
	bne	@f
	move.w	current_midi_out_w(pc),d4
	move.w	current_midi_out_r(pc),d6
	bra	1f
@@:
	ext.w	d4
	move.w	d4,d6
	lea	midi_if_tbl(pc),a4
	move.b	(a4,d4.w),d4		*0,2,4
	andi.w	#$7f,d4
1:
	move.w	d4,d3
	lsr.b	#1,d4			*0,1,2
	ori.w	#$8000,d4
	moveq.l	#0,d0
	move.w	@f(pc,d3.w),d0
	lea	@f(pc,d0.l),a4
	swap	d4
	move.w	(a1)+,d4		*get p_ch
	lea	init_wks_md(pc),a2
	lea	ms_key_off_md(pc),a0
	bra	_pcd_dvset_se
@@:
	dc.w	m_out_m0-@b
	dc.w	m_out_m1-@b
	dc.w	m_out_r0-@b
	dc.w	m_out_r1-@b
_pcd_ad_se:
	move.l	#int_play_ope_ad,d1
	swap	d4
	move.w	(a1)+,d4		*get p_ch
	lea	init_wks_ad(pc),a2
	lea	ms_key_off_ad(pc),a0
	bra	_pcd_dvset_se
_pcd_fm_se:
	move.l	#int_play_ope_fm,d1
	swap	d4
	move.w	(a1)+,d4		*get p_ch
	bset.b	d4,mask_opm_ch-work(a6)	*効果音モードFMレジスタマスク
	lea	opmset-work(a6),a4
	lea	init_wks_fm(pc),a2
	bsr	init_inst_fm		*< a4.l=opmset
	lea	ms_key_off_fm(pc),a0
_pcd_dvset_se:
	move.l	(a1)+,d7		*d7.l=演奏データまでのoffset
	add.l	a1,d7
	addq.l	#4,a1			*トラック追加情報までのオフセットスキップ

	move.l	play_trk_tbl_se-work(a6),a3
	moveq.l	#0,d3
@@:
	moveq.l	#0,d0
	move.w	(a3)+,d0
	cmpi.w	#-1,d0
	beq	set_new_sepl			*新規登録
	swap	d0
	lsr.l	#16-trwk_size_,d0
	movea.l	seq_wk_tbl_se-work(a6),a5
	adda.l	d0,a5				*a5=trk n seq_wk_tbl_se
	addq.w	#1,d3
	cmp.l	p_type(a5),d4			*同じデバイスがあるか
	bne	@b
sttrkprm:
	move.w	#$0001,(a5)		*p_step_time
	move.l	d2,p_track_stat(a5)	*p_track_stat,p_track_mode,p_trkfrq,p_trkfrq_wk
	move.l	d7,p_data_pointer(a5)	*set address
	move.l	d7,p_now_pointer(a5)	*set address
	move.l	d1,p_int_play_ope(a5)
	move.l	a4,p_midi_trans(a5)	*p_opmset(a5)
	move.w	d6,p_midi_if(a5)	*内蔵音源に取ってはダミー
	jsr	(a0)			*ms_key_off_xx
	jsr	(a2)			*init_wks_xx(効果音モード用演奏ワーク初期化(x a4))
	dbra	d5,sepl_lp01
	bra	init_timer_se

set_new_sepl:				*新規登録
	move.w	d3,-2(a3)		*set play trk tbl
	move.w	#-1,(a3)		*end mark
	move.l	d3,d0
	swap	d0
	lsr.l	#16-trwk_size_,d0
	movea.l	seq_wk_tbl_se-work(a6),a5
	adda.l	d0,a5			*a5=trk n seq_wk_tbl_se
	move.l	d4,p_type(a5)
	addq.w	#1,d3
	bra	sttrkprm

exec_comn_cmd:			*共通コマンド群の処理
	* < a2=comn data addr
	* X d0-d2,a0-a2/a5
pcd_lp01:
	moveq.l	#0,d0
	move.b	(a2)+,d0
	bmi	exit_ccd	*共通コマンドエンド
	move.l	cmncmdjtbl(pc,d0.w),a0
	jsr	(a0)
	bra	pcd_lp01
exit_ccd:
exit_ccd_se:
	rts
cmncmdjtbl:
	dc.l	cmn_init		*($00)initialize
	dc.l	cmn_read_sub		*($04)read & exec. cnf file
	dc.l	0			*($08)tempo
	dc.l	0			*($0c)全音符カウンタ/拍子セット
	dc.l	cmn_fm_tune_set		*($10)FM音源周波数テーブル
	dc.l	cmn_pcm_tune_set	*($14)PCM音源周波数テーブル
	dc.l	cmn_vset		*($18)ボイスセット
	dc.l	cmn_wave_form		*($1c)wave form setting
	dc.l	cmn_register_pcm	*($20)adpcm data cnf
	dc.l	cmn_erase_pcm		*($24)erase adpcm
	dc.l	cmn_block_adpcm		*($28)read a block data
	dc.l	cmn_crnt_midi_in	*($2c)current midi in
	dc.l	cmn_crnt_midi_out	*($30)current midi out
	dc.l	cmn_midi_trans		*($34)MIDI生データ転送
	dc.l	cmn_midi_dump		*($38)trans midi data dump
	dc.l	0			*($3c)
	dc.l	cmn_comment		*($40)comment
	dc.l	cmn_print		*($44)print message
	dc.l	cmn_dummy		*($48)dummy code
	dc.l	cmn_halt		*($4c)halt
cmncmdjtbl_end:
n4_of_cmn_cmd:	equ	cmncmdjtbl_end-cmncmdjtbl

exec_comn_cmd_se:				*共通コマンド群の処理(効果音サイド)
	* < a2=comn data addr
	* X d0-d2,a0-a2
pcd_lp01_se:
	moveq.l	#0,d0
	move.b	(a2)+,d0
	bmi	exit_ccd_se	*共通コマンドエンド
	move.l	cmncmdjtbl_se(pc,d0.w),a0
	jsr	(a0)
	bra	pcd_lp01_se
cmncmdjtbl_se:
	dc.l	cmn_init_se		*($00)初期化
	dc.l	cmn_read_sub_se		*($04)read & exec. cnf file
	dc.l	0			*($08)テンポ
	dc.l	0			*($0c)全音符カウンタ/拍子セット
	dc.l	cmn_fm_tune_set		*($10)FM音源周波数テーブル
	dc.l	cmn_pcm_tune_set	*($14)PCM音源周波数テーブル
	dc.l	cmn_vset		*($18)ボイスセット
	dc.l	cmn_wave_form		*($1c)wave form setting
	dc.l	cmn_register_pcm	*($20)adpcm data cnf
	dc.l	cmn_erase_pcm		*($24)erase adpcm
	dc.l	cmn_block_adpcm		*($28)read a block data
	dc.l	cmn_crnt_midi_in	*($2c)current midi in
	dc.l	cmn_crnt_midi_out	*($30)current midi out
	dc.l	cmn_midi_trans		*($34)MIDI生データ転送
	dc.l	cmn_midi_dump		*($38)trans midi data dump
	dc.l	0			*($3c)
	dc.l	cmn_comment		*($40)comment
	dc.l	cmn_print		*($44)print message
	dc.l	cmn_dummy		*($48)dummy code
	dc.l	cmn_halt_se		*($4c)halt

	*コンパイルデータの実行部

cmn_init:				*初期化(m_init相当)
	move.w	#ZM_INIT,fnc_no-work(a6)
	move.l	play_trk_tbl-work(a6),a1		*どのtrackがどのchannelへ
	move.w	#-1,(a1)				*ｱｻｲﾝされているかを初期化
	bsr	init_mask_fader_work
	init_cmn_wks					*共通ワーク初期化
	move.b	(a2)+,d1
	cmpi.b	#3,d1
	beq	@f
	cmpi.b	#2,d1
	bne	1f
@@:
	move.l	a2,-(sp)
	bsr	zmusic_mode		*モード変更
	move.l	(sp)+,a2
1:
	rts

cmn_init_se:				*初期化(m_init相当)
	addq.w	#1,a2
cmn_dummy:				*なにもしないZMD
	rts

cmn_vset:				*FM音色設定
	move.w	#ZM_VSET,fnc_no-work(a6)
	moveq.l	#0,d1
	move.b	(a2)+,d1		*tone number(H)
	lsl.w	#8,d1
	move.b	(a2)+,d1		*tone number(L)
	moveq.l	#-1,d2
	lea	1(a2),a1		*skip dummy
	bsr	m_vset
	move.l	a1,a2
	rts

cmn_pcm_tune_set:			*PCM音源周波数テーブル
	move.l	a2,pcm_tune_tbl-work(a6)
	lea	128(a2),a2
	rts

cmn_fm_tune_set:			*FM音源周波数テーブル
	move.l	a2,fm_tune_tbl-work(a6)
	lea	128(a2),a2
	rts

cmn_crnt_midi_out:			*カレントＭＩＤＩ－ＯＵＴ
	move.w	#ZM_CURRENT_MIDI_OUT,fnc_no-work(a6)
	moveq.l	#0,d1
	move.b	(a2)+,d1
	bra	current_midi_out

cmn_crnt_midi_in:			*カレントＭＩＤＩ－ＩＮ
	move.w	#ZM_CURRENT_MIDI_IN,fnc_no-work(a6)
	moveq.l	#0,d1
	move.b	(a2)+,d1
	bra	current_midi_in

cmn_midi_trans:			*MIDIデータ転送
	move.w	#ZM_MIDI_TRANSMISSION,fnc_no-work(a6)
	move.b	(a2)+,d1	*MIDI I/F(0-2/-1:current)
	ext.w	d1
	bsr	get_m_out_addr
	moveq.l	#0,d1
	move.b	(a2)+,d1	*str length(0-255)
	add.w	d1,a2		*skip comment str
	bsr	get_cm_l
	move.l	d0,d2		*n bytes
	movea.l	a2,a1
	add.l	d2,a2
	jmp	trans_midi_dat

cmn_halt:			*一時停止
	bsr	get_cm_l
	move.l	d0,d1
@@:
	bitsns	$0		*ESCを押せば終了
	btst.l	#1,d0
	bne	@f
	jsr	v_wait-work(a6)
	subq.l	#1,d1
	bne	@b
@@:
	rts

cmn_halt_se:			*一時停止(SEサイドでは無視)
	addq.w	#4,a2
	rts

cmn_register_pcm:
	move.w	#ZM_PCM_READ,fnc_no-work(a6)
	bsr	get_cm_l
	move.l	d0,d1		*flag of option existance/reg note number
	bsr	get_cm_l
	move.l	d0,d2		*d2.l=data type.b/original key code
	movea.l	a2,a1
	bsr	pcm_read
	move.l	a0,a2		*a2=更新された
	rts

cmn_erase_pcm:
	move.w	#ZM_PCM_READ,fnc_no-work(a6)
	bsr	get_cm_w
	move.l	d0,d1		*d1.w=note number to erase
	suba.l	a1,a1		*a1.l=0:erase_mode
	bra	pcm_read

cmn_comment:			*コメント行
srch_fn_end:			*ファイル名の場合
	tst.b	(a2)+
	bne	srch_fn_end	*ファイルネームのエンドを捜して
	rts			*ループに戻る

cmn_wave_form:			*波形メモリセット
	move.w	#ZM_SET_WAVE_FORM2,fnc_no-work(a6)
	bsr	get_cm_w
	move.w	d0,d1		*get wave no
	move.l	a2,a1		*wave data addr.
	bsr	set_wave_form2
	move.l	a0,a2
	rts

cmn_print:			*print
	* < a2.l=pointer
	pea	(a2)
	DOS	_PRINT
	addq.w	#4,sp
	bra	srch_fn_end

cmn_block_adpcm:
	move.w	#ZM_REGISTER_ZPD,fnc_no-work(a6)
	movea.l	a2,a1					*ファイルネームポインタを渡してコール
	movem.l	d0-d7/a0-a5,-(sp)
	move.b	(a2),d1
	cmpi.b	#$20,d1
	bcs	cba_nofn				*$20未満はアドレス指定
	move.w	#ZM_REGISTER_ZPD,fnc_no-work(a6)
	move.l	sp,sp_buf-work(a6)			*使用するパラメータを設定
	move.l	#@f,fnc_quit_addr-work(a6)
	bsr	register_zpd
@@:
	movem.l	(sp)+,d0-d7/a0-a5
	bra	srch_fn_end
cba_nofn:			*<d1.l=zpd id
	addq.w	#1,a2		*skip 0
	bsr	get_cm_l	*get offset
	add.l	d0,a2
	move.w	#ZM_SET_ZPD_TABLE,fnc_no-work(a6)
	bsr	set_zpd_tbl_
	movem.l	(sp)+,d0-d7/a0-a5
	rts

cmn_read_sub_se:		*コンフィギュレーション読み込み(ZPD,CNF,MDD,MID,ZMSいずれも可)
	lea	exec_comn_cmd_se(pc),a5
	bra	@f
cmn_read_sub:			*コンフィギュレーション読み込み(ZPD,CNF,MDD,MID,ZMSいずれも可)
	lea	exec_comn_cmd(pc),a5
@@:
	move.w	#ZM_EXEC_SUBFILE,fnc_no-work(a6)
	tst.b	(a2)
	beq	@f
	lea	CNF-work(a6),a1	*拡張子
*	lea	cnf_last_fn(pc),a3
	bra	exec_subfile0
@@:
	addq.w	#1,a2		*skip 0
	bsr	get_cm_l	*get offset
	lea	(a2,d0.l),a1
	bsr	get_cm_l	*get size
	move.l	d0,d3
	bra	do_exec_subfile

cmn_midi_dump:				*バイナリMIDIデータ転送
	move.w	#ZM_TRANSMIT_MIDI_DUMP,fnc_no-work(a6)
	move.b	(a2)+,d1		*get I/F number
	ext.w	d1
	ext.l	d1
	tst.b	(a2)			*ファイルネームがあるか
	bne	transmit_midi_dump0	*ファイルを読み込んで転送
	addq.w	#1,a2		*skip 0
	bsr	get_cm_l	*get offset
	lea	(a2,d0.l),a1
	moveq.l	#0,d2
	bra	midi_transmission

get_cm_w:
	move.b	(a2)+,d0
	lsl.w	#8,d0
	move.b	(a2)+,d0
	rts

get_cm_l:
	move.b	(a2)+,d0
	lsl.w	#8,d0
	move.b	(a2)+,d0
	swap	d0
	move.b	(a2)+,d0
	lsl.w	#8,d0
	move.b	(a2)+,d0
	rts

se_adpcm1:			*ADPCMをSEモードで鳴らす	!v3
	*   cmd=$13
	* < a1.l=data address
	* < d1.hwhb=data type(-1:ADPCM,1:16bitPCM,2:8bitPCM)
	* < d1.hwlb=volume(0-127,64が標準)
	* < d1.lwhb=frq(0:3.9kHz 1:5.2kHz 2:7.8kHz 3:10.4kHz 4:15.6kHz)
	* < d1.lwlb=pan(0-3 / $80+0-127)
	* < d2.l=data size
	* < d4.lw=ch(0-15)
	* < d4.hw=se priority(0-255)
	ori.w	#$700,sr
sea1_patch:			*MPCM case(bra sea1_)
	swap	d4
	tst.b	se_mode-work(a6)
	beq	@f
	cmp.b	se_level(pc),d4
	bcc	@f
	rts
@@:
	move.b	d4,se_level-work(a6)
	st.b	se_mode-work(a6)
	jmp	adpcmout
sea1_:				*mpcmを用いて発音するケース
	move.w	#M_EFCT_OUT,d0
	move.b	d4,d0		*ch
	MPCM_call		*キーオン
	rts

se_adpcm2:			*ドライバー内のADPCM DATAをSEモードで鳴らす	!v3
	*   cmd=$14		*(エラーチェックはなし)
	* < d1.hwhb=data type(-1:ADPCM,1:16bitPCM,2:8bitPCM)
	* < d1.hwlb=volume(0-127,64が標準)
	* < d1.lwhb=frq(0:3.9kHz 1:5.2kHz 2:7.8kHz 3:10.4kHz 4:15.6kHz)
	* < d1.lwlb=pan(0-3 / $80+0-127)
	* < d2.l=PCM data number(d15が1ならば音色番号($8000+0-32767),
	*			      0ならばノート番号(0-32767)指定)
	* < d4.lw=ch(0-15)
	* < d4.hw=se priority(0-255)
	ori.w	#$700,sr
	bclr.l	#15,d2
	beq	@f
	tst.w	adpcm_n_max2-work(a6)
	beq	t_empty_timbre_number
	move.l	adpcm_tbl2-work(a6),a1
	bra	sea2_00
@@:
	tst.w	adpcm_n_max-work(a6)
	beq	t_empty_note_number
	move.l	adpcm_tbl-work(a6),a1
sea2_00:
	lsl.l	#adpcm_tbl_size_,d2	*adpcm_tbl_size倍
	lea	adt_size(a1,d2.l),a1	*skip attribute
	move.l	(a1),d2			*adt_size
	move.l	-(a1),a1		*adt_address
sea2_patch:				*MPCM case(bra sea2_)
	swap	d4
	tst.b	se_mode-work(a6)
	beq	@f
	cmp.b	se_level(pc),d4
	bcc	@f
	rts
@@:
	move.b	d4,se_level-work(a6)
	st.b	se_mode-work(a6)
	jmp	adpcmout
sea2_:
	move.w	#M_EFCT_OUT,d0
	move.b	d4,d0		*ch
	MPCM_call		*キーオン
	rts

intercept_play:
	*   cmd=$15
	* < d1.l＝-1 interception mode
	* < d1.l＝0  release interception & play
	* < d1.l＝1  release interception
	* > none
	tst.l	d1
	bpl	@f
	patch_l2	BRA,m_play00,tmf_1
	bra	cache_flush
@@:
	move.l	m_play00_bak-work(a6),m_play00
	bsr	cache_flush
	tst.l	d1
	beq	m_play00
	rts
tmf_1:
	tas.b	timer_flg-work(a6)		*M_PLAYが実行されたマーク
	rts

current_midi_in:				*MIDIのカレント入力先
	*   cmd=$16
	* < d1.w=midi-in port number(0～3,-1:ask)
	* > d0.l=前回の設定(0-3,-1:err)
	* - a2保存
	* MIDI I/Fが無い時にはこのルーチンは無効となる
	ori.w	#$0700,sr
	moveq.l	#0,d0
	lea	current_midi_in_r+1(pc),a0
	move.b	(a0),d0				*戻り値(相対指定値)
	tst.w	d1				*問い合わせのみ
	bmi	@f
	cmp.w	d0,d1				*値が同じなら設定しない
	beq	@f
	move.b	d1,(a0)+			*絶対値書き込み
	moveq.l	#0,d2
	move.b	midi_if_tbl-current_midi_in_w(a0,d1.w),d2
	bmi	t_device_offline
	move.w	d2,(a0)				*current_midi_in_w
	bra	cache_flush
@@:
	rts

dummy_mdifret:					*MIDI I/Fが一枚もない時の戻り値
	moveq.l	#-1,d0
	rts

current_midi_out:				*MIDIのカレント出力先
	*   cmd=$17
	* < d1.w=midi-out port number(0～3,-1:ask)
	* > d0.l=前回の設定(0-3,-1:ERR)
	* - a2.l保存
	* x a0
	* MIDI I/Fが無い時にはこのルーチンは無効となる
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	moveq.l	#0,d0
	lea	current_midi_out_r+1(pc),a0
	move.b	(a0),d0				*戻り値(相対指定値)
	tst.w	d1				*問い合わせのみ
	bmi	@f
	cmp.w	#if_max-1,d1
	bhi	t_illegal_interface_number
	cmp.w	d0,d1				*値が同じなら設定しない
	beq	@f
	move.b	d1,(a0)+			*絶対値書き込み
	moveq.l	#0,d2
	move.b	midi_if_tbl-current_midi_out_w(a0,d1.w),d2
	bmi	t_device_offline
	move.w	d2,(a0)				*current_midi_out_w
	lea	eox_w-work(a6),a1
	tst.w	(a1,d2.w)			*ウェイトの有り無しチェック
	beq	1f
	move.w	_m_out1_j_tbl(pc,d2.w),_m_out+2-work(a6)
	bsr	cache_flush
@@:
	move.w	(sp)+,sr
	rts
1:
	move.w	m_out1_j_tbl(pc,d2.w),_m_out+2-work(a6)
	bsr	cache_flush
	move.w	(sp)+,sr
	rts

_m_out1_j_tbl:
	dc.w	_m_out_m0-_m_out-2
	dc.w	_m_out_m1-_m_out-2
	dc.w	_m_out_r0-_m_out-2
	dc.w	_m_out_r1-_m_out-2

m_out1_j_tbl:
	dc.w	m_out_m0-_m_out-2
	dc.w	m_out_m1-_m_out-2
	dc.w	m_out_r0-_m_out-2
	dc.w	m_out_r1-_m_out-2

get_m_out_addr:		*インターフェース番号に対応した転送サブルーチンアドレスをかえす
			*nmdb!!(bra dummy_trans)
	* < d1.w=interface number(0-3,-1)
	* > a5.l=midi trans addr
	* x d0
	* - d1
	tst.w	d1
	bpl	@f
	lea	_m_out-work(a6),a5
	rts
@@:
	cmpi.w	#if_max-1,d1
	bhi	t_illegal_interface_number
	lea	midi_if_tbl(pc),a0
	moveq.l	#0,d0
	move.b	(a0,d1.w),d0
	bmi	dummy_trans
	lea	eox_w-work(a6),a5
	tst.w	(a5,d0.w)			*ウェイトの有無で割り込み送信か否かを判断
	beq	@f
	move.w	_gmoa_j_tbl(pc,d0.w),d0
	lea	gmoa_j_tbl(pc,d0.l),a5
	rts
@@:
	move.w	gmoa_j_tbl(pc,d0.w),d0
	lea	gmoa_j_tbl(pc,d0.l),a5
	rts
dummy_trans:
	lea	@f(pc),a5
@@:
	rts

gmoa_j_tbl:
	dc.w	m_out_m0-gmoa_j_tbl
	dc.w	m_out_m1-gmoa_j_tbl
	dc.w	m_out_r0-gmoa_j_tbl
	dc.w	m_out_r1-gmoa_j_tbl

_gmoa_j_tbl:
	dc.w	_m_out_m0-gmoa_j_tbl
	dc.w	_m_out_m1-gmoa_j_tbl
	dc.w	_m_out_r0-gmoa_j_tbl
	dc.w	_m_out_r1-gmoa_j_tbl

midi_transmission:			*MIDI生データの転送
	*   cmd=$18
	* < d1.l:midi-out port number(0-3,-1:current)
	* < d2.l:mode (size)
	*	＝0 ASCII mode (end code:$1a)
	*	≠0 BIN mode (data size)
	* < a1.l=data address
	* > d0.l=sum
	* - all
nmdb7:				*nmdb!!(patched to be RTS)
reglist	reg	d1-d5/d7/a1-a2/a4-a5
	movem.l	reglist,-(sp)
	bsr	get_m_out_addr
	tst.l	d2		*check size
	bne	bin_trns_md
	moveq.l	#0,d3		*init sum
mtrs_lp01:
	move.b	(a1)+,d0
	cmpi.b	#$1a,d0
	beq	exit_mdtr
	cmpi.b	#'.',d0
	bls	mtrs_lp01	*セパレータスキップ
	cmpi.b	#'/',d0
	beq	skip_cmnt
	cmpi.b	#'*',d0
	beq	skip_cmnt
	bsr	mk_capital
	move.b	d0,d1
	sub.b	#'0',d1
	cmpi.b	#9,d1
	bls	@f
	subq.b	#7,d1
@@:
	move.b	(a1)+,d0
	bsr	mk_capital
	sub.b	#'0',d0
	cmpi.b	#9,d0
	bls	@f
	subq.b	#7,d0
@@:
	lsl.b	#4,d1
	or.b	d1,d0
	add.b	d0,d3
	jsr	(a5)		*do trans
	bra	mtrs_lp01
skip_cmnt:			*改行までスキップ
	move.b	(a1)+,d0
	cmpi.b	#" ",d0
	bcc	skip_cmnt
	cmpi.b	#09,d0
	beq	skip_cmnt	*skip tab
	bra	mtrs_lp01

bin_trns_md:			*BINARY DATAの送信
	* < d2.l=size
	* < a1.l=data address
	* < a5.l=midi trans addr
	cmpi.l	#SMFHED,(a1)		*'MThd'
	beq	trans_smf_dat
	bsr	trans_midi_dat
exit_mdtr:
	move.l	d3,d0
	movem.l	(sp)+,reglist
	rts

trans_midi_dat:			*BINARY DATAの送信
	* < d2.l=size
	* < a1.l=data address
	* < a5.l=midi trans addr
	* > d3.b=sum
	* > d2.l=0,a1=next
	* d0,d2,d3
	moveq.l	#0,d3
@@:
	move.b	(a1)+,d0
	add.b	d0,d3
	jsr	(a5)		*do trans
	subq.l	#1,d2
	bne	@b
	rts

stop_smf:
	tst.b	smf_end_flag-work(a6)
	ble	@f
	bsr	release_int_mode
@@:
	rts

trans_smf_dat:				*SMF転送
	cmpi.l	#$0000_0001,8(a1)		*フォーマット1か
	bne	t_unmanageable_data_sequence	*未対応
	move.w	sr,d7
	ori.w	#$0700,sr
	cmp.l	#int_dummy,sub_job_entry-work(a6)
	beq	use_int_mode0			*割り込みモードが使える
	tst.b	smf_end_flag-work(a6)
	bgt	use_int_mode1			*割り込みモードを使う
	bmi	t_device_already_occupied	*すでにデバイスは占有されています

	move.w	mst_clk(pc),-(sp)
	move.w	$0c(a1),d0
	bmi	t_unmanageable_data_sequence	*未対応
	lsl.w	#2,d0
	move.w	d0,mst_clk-work(a6)
	lea	22(a1),a2
	move.l	tempo_value(pc),-(sp)		*tempo_value,timer_value	*01/01/20
	move.w	#120,tempo_value-work(a6)	*テンポ=120
	move.l	inc_zmint-work(a6),-(sp)
	patch_l	BSR,inc_zmint,smf_entry
	bsr	cache_flush
	st.b	smf_end_flag-work(a6)
	jsr	getval-work(a6)
	move.l	d0,smf_delta-work(a6)
	move.l	a2,smf_pointer-work(a6)
	move.l	#1,smf_running-work(a6)		*running count host
	move.l	a5,smf_transfer-work(a6)	*MIDI transfer
	bsr	calc_timer
	bsr	init_timer
	bsr	midi_clk		*01/01/20
	move.w	d7,sr
smfcheck_lp:
	bitsns	$0				*ESCを押せば終了
	btst.l	#1,d0
	bne	1f
@@:
	tst.b	smf_end_flag-work(a6)
	bne	smfcheck_lp
1:
	bsr	init_kbuf
	ori.w	#$0700,sr
	move.l	(sp)+,inc_zmint-work(a6)
	move.l	(sp)+,tempo_value-work(a6)
	move.w	(sp)+,mst_clk-work(a6)
	clr.b	smf_end_flag-work(a6)
	bsr	cache_flush
	bsr	init_timer
	bsr	midi_clk		*01/01/20
	move.w	d7,sr
	movem.l	(sp)+,reglist
	t_dat_ok

init_kbuf:			*キーバッファクリア
	move.l	d0,-(sp)
	clr.w	-(sp)
	DOS	_KFLUSH
	addq.w	#2,sp
	move.l	(sp)+,d0
	rts

use_int_mode1:					*割り込みモード
	bsr	release_int_mode
use_int_mode0:
	* < d2=data size
	move.l	#ID_SMF,d3
	bsr	get_mem
	tst.l	d0
	bmi	t_out_of_memory
	move.l	a0,smf_addr-work(a6)
@@:						*コピー
	move.l	(a1)+,(a0)+
	subq.l	#4,d2
	bne	@b
	move.l	smf_addr-work(a6),a2
	move.w	$0c(a2),d1
	bmi	t_unmanageable_data_sequence	*未対応
	lsl.w	#2,d1				*全音符長に変換
	swap	d1
	move.l	d1,smf_mst_clk-work(a6)
	lea	22(a2),a2
	move.w	#120,d1				*defaultテンポ=120
	move.b	#1,smf_end_flag-work(a6)	*割り込みモードマーク
	jsr	getval-work(a6)			*初期デルタタイム
	move.l	d0,smf_delta-work(a6)
	move.l	a2,smf_pointer-work(a6)
	move.l	#1,smf_running-work(a6)		*running count host
	move.l	a5,smf_transfer-work(a6)	*MIDI transfer
	lea	smf_entry-work(a6),a1
	bsr	set_int_service
	move.w	d7,sr
	movem.l	(sp)+,reglist
	t_dat_ok

release_int_mode:				*割り込みモード中止/解除
reglist	reg	d0-d2/a0-a1
	movem.l	reglist,-(sp)
	moveq.l	#0,d1
	move.b	d1,smf_end_flag-work(a6)	*割り込みモードクリア
	lea	smf_entry-work(a6),a1
	bsr	set_int_service			*解除
	move.l	smf_addr(pc),a1
	bsr	free_mem
	movem.l	(sp)+,reglist
	rts

exclusive:
	*   cmd=$19
	* < a1.l=data address
	* < d1.l=midi-out port number(0-3,-1:current)
	* < d2.l=size
	* < d3.hw=MAKER ID
	* < d3.lw=id,model
	* > none
	bsr	get_m_out_addr
	lea	header(pc),a2
	move.l	d3,d5
	swap	d5		*d5.w=maker ID
	tst.l	d3		*メーカー指定なしのケース
	bmi	1f
	tst.b	d3
	bmi	@f
	move.b	d3,3(a2)	*set mdl
@@:
	lsr.w	#8,d3
	tst.b	d3
	bmi	@f
	move.b	d3,2(a2)	*set dev
@@:
	cmpi.b	#MKID_ROLAND,d5
	bne	1f
	moveq.l	#5-1,d1
@@:				*header転送
	move.b	(a2)+,d0
	jsr	(a5)
	dbra	d1,@b
	moveq.l	#0,d3		*checksum=0
	bra	2f
1:
	moveq.l	#0,d3		*checksum=0
	moveq.l	#$f0,d0
	jsr	(a5)
	cmpi.b	#MKID_YAMAHA,d5
	bne	2f
	moveq.l	#MKID_YAMAHA,d0
	jsr	(a5)
	move.b	2(a2),d0	*mdl
	jsr	(a5)
	move.b	3(a2),d0	*dev
	jsr	(a5)
	move.l	d2,d1
	subq.l	#3,d1		*アドレス分引く
	move.w	d1,d0
	lsr.w	#7,d0
	andi.w	#$7f,d0
	add.b	d0,d3
	jsr	(a5)		*length MSB
	move.w	d1,d0
	andi.w	#$7f,d0
	add.b	d0,d3
	jsr	(a5)		*length LSB
2:
	move.b	(a1)+,d0
	add.b	d0,d3
	jsr	(a5)
	subq.l	#1,d2
	bne	2b
	cmpi.b	#MKID_ROLAND,d5
	beq	@f
	cmpi.b	#MKID_YAMAHA,d5
	bne	1f
@@:
	andi.b	#$7f,d3
	moveq.l	#$80,d0
	sub.b	d3,d0
	andi.b	#$7f,d0
	jsr	(a5)
1:
	moveq.l	#$f7,d0		*EOX
	jmp	(a5)

set_eox_wait:				*wait
	*   cmd=$1b
	* < d1.l=midi-out port number(0-3,-1:current)
	* < d2.w=wait parameter(0-65535)
	* > d0.w=last parameter(0-65535)
	* MIDI I/Fが無い時にはこのルーチンは無効となる
	ori.w	#$0700,sr
	lea	eox_w-work(a6),a2
	tst.w	d2
	bne	case_ew
					*eox_wait無しの場合
	tst.w	d1
	bpl	1f
					*カレントの場合
	move.w	current_midi_out_w(pc),d1	*d1.w=0,2,4,6
	move.w	@f(pc,d1.w),_m_out+2-work(a6)
	moveq.l	#0,d0
	move.w	(a2,d1.w),d0		*d0.w=previous
	move.w	d2,(a2,d1.w)
	bra	cache_flush
1:					*明示指定の場合
	cmpi.w	#if_max-1,d1
	bhi	t_illegal_interface_number
	lea	midi_if_tbl(pc),a1
	moveq.l	#0,d0
	move.b	(a1,d1.w),d0
	bmi	t_device_offline
	cmp.w	current_midi_out_w(pc),d0
	bne	1f
	move.w	@f(pc,d0.w),_m_out+2-work(a6)
1:
	move.w	(a2,d0.w),d1
	move.w	d2,(a2,d0.w)
	move.w	d1,d0
	bra	cache_flush
@@:
	dc.w	m_out_m0-_m_out-2
	dc.w	m_out_m1-_m_out-2
	dc.w	m_out_r0-_m_out-2
	dc.w	m_out_r1-_m_out-2
case_ew:				*eox_wait有りの場合
	tst.w	d1
	bpl	1f
					*カレントの場合
	move.w	current_midi_out_w(pc),d1	*d1.w=0,2,4,6
	move.w	@f(pc,d1.w),_m_out+2-work(a6)
	moveq.l	#0,d0
	move.w	(a2,d1.w),d0		*d0.w=previous
	move.w	d2,(a2,d1.w)
	bra	cache_flush
1:
	cmpi.w	#if_max-1,d1
	bhi	t_illegal_interface_number
	lea	midi_if_tbl(pc),a1
	moveq.l	#0,d0
	move.b	(a1,d1.w),d0
	bmi	t_device_offline
	cmp.w	current_midi_out_w(pc),d0
	bne	1f
	move.w	@f(pc,d0.w),_m_out+2-work(a6)
1:
	move.w	(a2,d0.w),d1		*d0.w=previous
	move.w	d2,(a2,d0.w)
	move.w	d1,d0
	bra	cache_flush
@@:
	dc.w	_m_out_m0-_m_out-2
	dc.w	_m_out_m1-_m_out-2
	dc.w	_m_out_r0-_m_out-2
	dc.w	_m_out_r1-_m_out-2

midi_inp1:				*nmdb!!(patched to be RTS)
	*   cmd=$1c
	* < d1.w=midi-out port number(0-3,-1:current)
	* < d2.l=0 single mode
	* < d2.l<>0 loop mode		*読み出せるまで待ちつづける
	* > d0.b=recieved data
	* > d0.w=minus:dataなし
	* > d0.l=minus:読みこぼしあり
	* > a0.l=前回の読みだしからの経過クロック数
	* - d1
	tst.w	d1			*minusならcurrent使用
	bpl	@f
	move.w	current_midi_in_w(pc),d0
	move.w	mi1_j_tbl(pc,d0.w),d0
	jmp	mi1_j_tbl(pc,d0.w)
@@:
	cmpi.w	#if_max-1,d1
	bhi	t_illegal_interface_number
	lea	midi_if_tbl(pc),a1
	moveq.l	#0,d0
	move.b	(a1,d1.w),d0
	bmi	t_device_offline
	move.w	mi1_j_tbl(pc,d0.w),d0
	jmp	mi1_j_tbl(pc,d0.w)
mi1_j_tbl:
	dc.w	mi1_m0-mi1_j_tbl
	dc.w	mi1_m1-mi1_j_tbl
	dc.w	mi1_r-mi1_j_tbl
	dc.w	mi1_r-mi1_j_tbl

mi1_m0:				*CZ6BM1 #1
	move.l	rec_buffer_0-work(a6),a1
mi10:
	moveq.l	#0,d0
	move.w	rec_buf_err(a1),d0	*最上位にバッファ溢れフラグを持ってくる
	swap	d0
	tst.l	d2
	bne	loop_inp_m0		*ループモードへ
	tst.b	rec_buf_stat(a1)	*データあるか
	beq	exit_mi1
get_data_mi:
	move.l	last_zmusic_int(pc),d1
	move.l	zmusic_int(pc),a0
	move.l	a0,last_zmusic_int-work(a6)
	sub.l	d1,a0			*a0.l=前回からの経過クロック
	move.w	rec_read_ptr(a1),d1
	move.b	rec_buffer(a1,d1.w),d0
	addq.w	#1,d1
	andi.w	#recbufsize-1,d1
	move.w	d1,rec_read_ptr(a1)
	cmp.w	rec_write_ptr(a1),d1
	sne.b	rec_buf_stat(a1)
	rts
exit_mi1:				*データなし
	move.w	#-1,d0
	rts

loop_inp_m0:
	tst.b	rec_buf_stat(a1)	*データあるか
	bne	get_data_mi
	jsr	h_wait-work(a6)
	subq.l	#1,d2
	bne	loop_inp_m0
	move.w	#-1,d0
	rts

mi1_m1:				*CZ6BM1 #2
	move.l	rec_buffer_1-work(a6),a1
	bra	mi10

mi1_r:				*RS232C
	move.l	rec_buffer_r-work(a6),a1
	bra	mi10

midi_out1:			*nmdb!!(patched to be RTS)
	*   cmd=$1d
	* < d1.w=midi-out port number(0-3,-1:current)
	* < d2.b=midi data
	* > d0.l=error code
	move.b	d2,d0
	moveq.l	#0,d2
	tst.w	d1			*minusならcurrent使用
	bpl	@f
	move.w	current_midi_in_w(pc),d2
	move.w	mo1_j_tbl(pc,d2.w),d2
	jmp	mo1_j_tbl(pc,d2.l)
@@:
	cmpi.w	#if_max-1,d1
	bhi	t_illegal_interface_number
	lea	midi_if_tbl(pc),a0
	move.b	(a0,d1.w),d2
	bmi	t_device_offline
	move.w	mo1_j_tbl(pc,d2.w),d2
	jmp	mo1_j_tbl(pc,d2.l)
mo1_j_tbl:
	dc.w	m_out_m0-mo1_j_tbl
	dc.w	m_out_m1-mo1_j_tbl
	dc.w	m_out_r0-mo1_j_tbl
	dc.w	m_out_r1-mo1_j_tbl

midi_rec:			*MIDI生データの受信開始
	*   cmd=$1e
	* < d1.w=I/F number(0-3,-1:current)
nmdb5:				*nmdb!!
	ori.w	#$0700,sr
	tst.w	d1			*minusならcurrent使用
	bpl	@f
	move.w	current_midi_in_w(pc),d0
	move.w	m_in_s_tbl(pc,d0.w),d0
	jmp	m_in_s_tbl(pc,d0.w)
@@:
	cmpi.w	#if_max-1,d1
	bhi	t_illegal_interface_number
	moveq.l	#0,d0
	lea	midi_if_tbl(pc),a0
	move.b	(a0,d1.w),d0
	bmi	t_device_offline
	move.w	m_in_s_tbl(pc,d0.w),d0
	jmp	m_in_s_tbl(pc,d0.w)
m_in_s_tbl:
	dc.w	m_in_s_m0-m_in_s_tbl
	dc.w	m_in_s_m1-m_in_s_tbl
	dc.w	m_in_s_r-m_in_s_tbl
	dc.w	m_in_s_r-m_in_s_tbl

m_in_s_m0:
	move.l	rec_buffer_0(pc),a1
	clr.l	rec_write_ptr(a1)	*rec_write_ptr,rec_read_ptr
	clr.w	rec_buf_err(a1)		*rec_buf_err,rec_buf_stat
	lea	rgr,a0
	lea	r06_0(pc),a1
mis0:
	move.b	#3,(a0)
					midiwait
	move.b	#%1001_0001,grp5-rgr(a0)	*buffer clear,MCF on,RecEn
					midiwait
	clr.b	(a0)
					midiwait
	ori.b	#$20,(a1)		*割り込みオン
	move.b	(a1),grp6-rgr(a0)
					midiwait
	t_dat_ok

m_in_s_m1:
	move.l	rec_buffer_1(pc),a1
	clr.l	rec_write_ptr(a1)	*rec_write_ptr,rec_read_ptr
	clr.w	rec_buf_err(a1)		*rec_buf_err,rec_buf_stat
	lea	rgr+$10,a0
	lea	r06_1(pc),a1
	bra	mis0

m_in_s_r:
	move.l	rec_buffer_r(pc),a1
	clr.l	rec_write_ptr(a1)	*rec_write_ptr,rec_read_ptr
	clr.w	rec_buf_err(a1)		*rec_buf_err,rec_buf_stat
	lea	scc_a,a0
	tst.b	(a0)
	move.b	#$01,(a0)
	move.b	wr1(pc),d0
	andi.b	#%1110_0111,d0
	ori.b	#%0001_0000,d0
	move.b	d0,wr1-work(a6)
	move.b	d0,(a0)
	t_dat_ok
m_in_s_no:				*MIDIインターフェースなし
m_in_e_no:				*MIDIインターフェースなし
	moveq.l	#-1,d0
	rts

midi_rec_end:				*MIDI生データ受信終了
	*   cmd=$1f
	* < d1.w＝I/F number (0-3,-1:current)
	* > d0.l=error code
	ori.w	#$0700,sr
	tst.w	d1
	bpl	@f
	move.w	current_midi_in_w(pc),d0
	move.w	m_in_e_tbl(pc,d0.w),d0
	jmp	m_in_e_tbl(pc,d0.w)
@@:
	cmpi.w	#if_max-1,d1
	bhi	t_illegal_interface_number
	moveq.l	#0,d0
	lea	midi_if_tbl(pc),a0
	move.b	(a0,d1.w),d0
	bmi	t_device_offline
	move.w	m_in_e_tbl(pc,d0.w),d0
	jmp	m_in_e_tbl(pc,d0.w)
m_in_e_tbl:
	dc.w	m_in_e_m0-m_in_e_tbl
	dc.w	m_in_e_m1-m_in_e_tbl
	dc.w	m_in_e_r-m_in_e_tbl
	dc.w	m_in_e_r-m_in_e_tbl

m_in_e_m0:
	lea	rgr,a0
	lea	r06_0(pc),a1
mie0:
	clr.b	(a0)
					midiwait
	andi.b	#%1101_1111,(a1)
	move.b	(a1),grp6-rgr(a0)	*int end
					midiwait
	t_dat_ok

m_in_e_m1:
	lea	rgr+$10,a1
	lea	r06_1(pc),a1
	bra	mie0

m_in_e_r:
	lea	scc_a,a0		*int end (記録強制終了)
	tst.b	(a0)
	move.b	#$01,(a0)
	andi.b	#%1110_0111,wr1-work(a6)
	move.b	wr1(pc),(a0)
	t_dat_ok

send_header:
	* - all
	movem.l	d2/a1,-(sp)
	lea	header(pc),a1
	moveq.l	#8-1,d2
@@:
	move.b	(a1)+,d0
	jsr	(a5)
	dbra	d2,@b
	movem.l	(sp)+,d2/a1
	rts

gs_reset:				*GSの初期化!v3
	*   cmd=$20
	* < d1.w=midi-out port number(0-3,-1:current)
	* < d3.b=gs id number(0-127,-1:current)
	* > d0.l=error code
	bsr	get_m_out_addr
	bsr	getset_gs_id			*ID保存／取得
	lea	header(pc),a1
	moveq.l	#11,d2
	move.b	d3,2(a1)
	move.b	#$42,3(a1)
	move.b	#$40,5(a1)
	move.l	#$007f0041,6(a1)
	bsr	trans_midi_dat
	t_dat_ok

getset_m1_id:
	lea	m1_id(pc),a4
	bra	@f

getset_mt32_id:
	lea	mt32_id(pc),a4
	bra	@f

getset_u220_id:
	lea	u220_id(pc),a4
	bra	@f

getset_sc88_id:
	lea	sc88_id(pc),a4
	bra	@f

getset_gs_id:
	* < d1.w=midi-out port number(0-3,-1:current)
	* < d3.b=ID
	* x d0,a4
	lea	gs_id(pc),a4
@@:
	tst.w	d1
	bpl	@f
	move.w	current_midi_out_w(pc),d0
	bra	1f
@@:
	move.l	a0,-(sp)
	lea	midi_if_tbl(pc),a0
	moveq.l	#0,d0
	move.b	(a0,d1.w),d0
	move.l	(sp)+,a0
1:
	lsr.w	#1,d0			*/2
	tst.b	d3
	bpl	@f
	move.b	(a4,d0.w),d3		*DEFAULTを使う
	rts
@@:
	move.b	d3,(a4,d0.w)
	rts

gs_partial_reserve:				*GSのパーシャルリザーブを設定!v3
	*   cmd=$21
	* < d1.w=midi-out port number(0-3,-1:current)
	* < a1.l=data address
	* < d3.b=gs id number(0-127,-1:current)
	* > d0.l=error code
	bsr	get_m_out_addr
	bsr	getset_gs_id			*ID保存／取得
	lea	header+2(pc),a2
	move.b	d3,(a2)+		*set dev ID
	move.b	#$42,(a2)+		*set model id
	addq.w	#1,a2
	move.b	#$40,(a2)+		*set addr H
	move.w	#$0110,(a2)+		*set addr L
	bsr	send_header
	move.l	v_buffer(pc),a0
	move.b	9(a1),(a0)+	*copy part 10
	moveq.l	#9-1,d0
@@:
	move.b	(a1)+,(a0)+	*copy part 1 to 9
	dbra	d0,@b
	addq.w	#1,a1		*skip part 10
	moveq.l	#6-1,d0
@@:
	move.b	(a1)+,(a0)+	*copy part 11 to 16
	dbra	d0,@b
	moveq.l	#16,d2
	move.l	v_buffer(pc),a1
	bsr	trans_midi_dat	*data 本体を転送(> d3.b=sum)
	add.b	$40+$01+$10,d3
	moveq.l	#$80,d0
	andi.b	#$7f,d3
	sub.b	d3,d0
	andi.b	#$7f,d0
	jsr	(a5)
	moveq.l	#$f7,d0
	jsr	(a5)
	t_dat_ok

gs_reverb:				*GSのリバーブパラメータ設定
	*   cmd=$22
	* < d1.w=midi-out port number(0-3,-1:current)
	* < a1.l=data address
	* < d2.l=size
	* < d3.b=gs id number(0-127,-1:current)
	* > d0.l=error code
	bsr	get_m_out_addr
	tst.l	d2
	beq	t_illegal_data_size
	cmpi.l	#7,d2
	bhi	t_illegal_data_size
	bsr	getset_gs_id			*ID保存／取得
	lea	header+2(pc),a2
	move.b	d3,(a2)+		*set dev ID
	move.b	#$42,(a2)+		*set model id
	addq.w	#1,a2
	move.b	#$40,(a2)+
	move.w	#$0130,(a2)+
	bsr	send_header
	bsr	trans_midi_dat		*> d3.b=sum
	add.b	#$40+$01+$30,d3
	andi.b	#$7f,d3
	moveq.l	#$80,d0
	sub.b	d3,d0
	andi.b	#$7f,d0
	jsr	(a5)
	moveq.l	#$f7,d0
	jsr	(a5)
	t_dat_ok

gs_chorus:			*gsのコーラスパラメータ設定
	*   cmd=$23
	* < d1.w=midi-out port number(0-3,-1:current)
	* < a1.l=data address
	* < d2.l=size
	* < d3.b=gs id number(0-127,-1:current)
	* > d0.l=error code
	bsr	get_m_out_addr
	tst.l	d2
	beq	t_illegal_data_size
	cmpi.l	#8,d2
	bhi	t_illegal_data_size
	bsr	getset_gs_id			*ID保存／取得
	lea	header+2(pc),a2
	move.b	d3,(a2)+			*set dev ID
	move.b	#$42,(a2)+			*set model id
	addq.w	#1,a2
	move.b	#$40,(a2)+
	move.w	#$0138,(a2)+
	bsr	send_header
	bsr	trans_midi_dat			*> d3.b=sum
	add.b	#$40+$01+$38,d3
	andi.b	#$7f,d3
	moveq.l	#$80,d0
	sub.b	d3,d0
	andi.b	#$7f,d0
	jsr	(a5)
	moveq.l	#$f7,d0
	jsr	(a5)
	t_dat_ok

gs_part_setup:				*gsのパートパラメータ設定
	*   cmd=$24
	* < a1.l=data address
	* < d1.w=midi-out port number(0-3,-1:current)
	* < d2.l=size(1～119)
	* < d3.hw=gs part number
	* < d3.lw=gs id number(0-127,-1:current)
	* > d0.l=error code
	bsr	get_m_out_addr
	subq.w	#1,d2			*for dbra
	bmi	t_illegal_data_size
	cmp.l	#119-1,d2
	bhi	t_illegal_data_size
	bsr	getset_gs_id		*ID保存／取得
	lea	header+2(pc),a2
	move.b	d3,(a2)+		*set dev ID
	move.b	#$42,(a2)+		*set model id
	move.l	#$401002,d4		*inst address
	swap	d3
	cmpi.w	#16,d3
	bhi	t_illegal_part_number
	cmpi.b	#10,d3
	bcs	@f			*9以下はそのまま
	bhi	dec_ptn
	moveq.l	#0,d3			*10はd3=0
	bra	@f
dec_ptn:
	subq.b	#1,d3			*10以上はd3=d3-1
@@:
	lsl.w	#8,d3
	or.w	d3,d4			*d4.l=partナンバーに対応したアドレス値
	move.b	(a1),d0			*保存
	movem.l	d0/a1,-(sp)		*先頭データ保存
	subq.b	#1,d0			*MIDI CH(1～16)->内部コード($00～$0f)
	cmpi.b	#$0f,d0
	bls	@f
	moveq.l	#$10,d0			*範囲外はOFFとみなす
@@:
	move.b	d0,(a1)

	move.l	d4,d5
	move.l	a1,a3
	moveq.l	#0,d1
	moveq.l	#0,d3
	lea	gsptofs(pc),a2
gsptlp:
	add.b	(a1)+,d1
	addq.l	#1,d3
	addq.b	#1,d4		*どうせ上位は変化しないから
	move.w	d4,d0
	andi.w	#$f0ff,d0
	cmp.w	(a2),d0
	bne	@f
	bsr	send_gsptdt
	move.l	(a2)+,d0
	add.w	d0,d4
	move.l	d4,d5
	move.l	a1,a3
	moveq.l	#0,d1
	moveq.l	#0,d3
@@:
	dbra	d2,gsptlp
	tst.l	d3
	beq	@f
	bsr	send_gsptdt
@@:
	movem.l	(sp)+,d0/a1
	move.b	d0,(a1)		*書き換えた値をもとに戻す
	t_dat_ok

send_gsptdt:
	* < a3.l=data address
	* < d1.b=sum
	* < d5.l=address
	* < d3.l=count
	movem.l	d2/d4/a1-a2,-(sp)
	lea	exc_addr(pc),a1
	swap	d5
	move.b	d5,(a1)+
	swap	d5
	move.w	d5,(a1)+
	add.b	-(a1),d1
	add.b	-(a1),d1
	add.b	-(a1),d1
	move.w	d1,-(sp)
	move.l	d3,-(sp)
	bsr	send_header
	move.l	a3,a1
	move.l	(sp)+,d2
	bsr	trans_midi_dat	* > d3=sum
	moveq.l	#$80,d0
	move.w	(sp)+,d2
	andi.b	#$7f,d2
	sub.b	d2,d0
	andi.b	#$7f,d0
	jsr	(a5)
	moveq.l	#$f7,d0
	jsr	(a5)
	movem.l	(sp)+,d2/d4/a1-a2
	rts

gsptofs:
*	dc.w	$1017,$0000
	dc.w	$1019,$0000
	dc.w	$1023,$000d
	dc.w	$1038,$0008
	dc.w	$104c,$0fb4
	dc.w	$200b,$0005
	dc.w	$201b,$0005
	dc.w	$202b,$0005
	dc.w	$203b,$0005
	dc.w	$204b,$0005
	dc.w	-1

gs_drum_setup:				*SC55のドラムパラメータ設定	!v3
	*   cmd=$25
	* < a1.l=data address
	* < d1.w=midi-out port number(0-3,-1:current)
	* < d2.l=size
	* < d3.hw=gs map number*256+note number
	* < d3.lw=gs id number(0-127,-1:current)
	* > d0.l=error code
	bsr	get_m_out_addr
	subq.w	#1,d2			*for dbra
	bmi	t_illegal_data_size
	cmpi.l	#8-1,d2
	bhi	t_illegal_data_size
	bsr	getset_gs_id		*ID保存／取得
	lea	header+2(pc),a2
	move.b	d3,(a2)+		*set dev ID
	move.b	#$42,(a2)+		*set model id
	move.l	#$410100,d4		*inst address
	swap	d3
	cmpi.b	#127,d3
	bhi	t_illegal_note_number
	move.b	d3,d4			*note set
	lsl.w	#4,d3
	andi.w	#$f000,d3
	or.w	d3,d4			*make address
gsdrm_set_lp:
	bsr	sc_p_set
	add.w	#$0100,d4
	addq.w	#1,a1
	dbra	d2,gsdrm_set_lp
	t_dat_ok

sc_p_set:				*gsフォーマット:1パラメータ書き込み
	* < d4=instrument address	*(dev ID,model IDは先に
	* < a1.l=data address		*header+2,+3へ設定しておくこと)
	* < d2.l=data size
	* - all
	movem.l	d0-d2/d4/a0-a2,-(sp)
	lea	exc_addr(pc),a0
	move.b	(a1),sc_p_data-exc_addr(a0)	*1バイトデータセット

	swap	d4
	move.b	d4,(a0)+		*set addr H
	swap	d4
	move.w	d4,(a0)+		*set addr L

	move.b	-(a0),d1		*アドレス加算(for make check sum)
	add.b	-(a0),d1
	add.b	-(a0),d1
	add.b	(a1),d1			*data加算
	moveq.l	#$80,d0
	andi.b	#$7f,d1
	sub.b	d1,d0
	lea	header(pc),a1
	move.b	d0,tail-header(a1)	*save ROLAND check sum
	moveq.l	#11,d2
	bsr	trans_midi_dat		*尻尾を転送
	movem.l	(sp)+,d0-d2/d4/a0-a2
	rts

gs_drum_name:
	*   cmd=$26
	* < a1.l=data address
	* < d1.w=midi-out port number(0-2,-1:current)
	* < d2.l=size
	* < d3.hw=gs drum map number(0,1:PRESET)
	* < d3.lw=gs id number(0-127,-1:current)
	* > d0.l=error code
	bsr	get_m_out_addr
	tst.l	d2
	beq	t_illegal_string_length
	cmpi.l	#12,d2
	bhi	t_illegal_string_length
	bsr	getset_gs_id		*ID保存／取得

	lea	header+2(pc),a2
	move.b	d3,(a2)+		*set dev ID
	move.b	#$42,(a2)+		*set model id
	addq.w	#1,a2
	move.b	#$41,(a2)+
	clr.w	(a2)+
	move.l	d3,d0
	swap	d0
	tst.b	d0
	beq	1f
	move.w	#$1000,-2(a2)
1:
	bsr	send_header
	bsr	trans_midi_dat		* > d3=sum
	add.b	#$10,d3			*$10=addr sum
	andi.b	#$7f,d3
	moveq.l	#$80,d0
	sub.b	d3,d0
	andi.b	#$7f,d0
	jsr	(a5)
	moveq.l	#$f7,d0
	jsr	(a5)
	t_dat_ok

gs_print:
	*   cmd=$27
	* < a1.l=data address
	* < d1.w=midi-out port number(0-3,-1:current)
	* < d2.l=size
	* < d3.b=gs id number(0-127,-1:current)
	* > d0.l=error code
	bsr	get_m_out_addr
	tst.l	d2
	beq	t_illegal_string_length
	cmpi.l	#32,d2
	bhi	t_illegal_string_length
	bsr	getset_gs_id			*ID保存／取得

	lea	header+2(pc),a2
	move.b	d3,(a2)+		*set dev ID
	move.b	#$45,(a2)+		*set model id
	addq.w	#1,a2
	move.b	#$10,(a2)+
	clr.w	(a2)+
	bsr	send_header
	bsr	trans_midi_dat		* > d3=sum
	add.b	#$10,d3			*$10=addr sum
	andi.b	#$7f,d3
	moveq.l	#$80,d0
	sub.b	d3,d0
	andi.b	#$7f,d0
	jsr	(a5)
	moveq.l	#$f7,d0
	jsr	(a5)
	t_dat_ok

gs_display:			*SC55の画面にドットパターンを表示する
	*   cmd=$28
	* < a1.l=data address
	* < d1.w=midi-out port number(0-3,-1:current)
	* < d3.b=gs id number(0-127,-1:current)
	* > d0.l=error code
	bsr	get_m_out_addr
	bsr	getset_gs_id			*ID保存／取得
	move.l	v_buffer(pc),a2

	moveq.l	#16-1,d4
mk_ddlp:
	move.w	(a1)+,d1
	move.b	d1,d0
	lsl.b	#4,d0
	andi.b	#$10,d0
	move.b	d0,48(a2)
	move.w	d1,d0
	lsr.w	#1,d0
	andi.b	#$1f,d0
	move.b	d0,32(a2)
	move.w	d1,d0
	lsr.w	#6,d0
	andi.b	#$1f,d0
	move.b	d0,16(a2)
	rol.w	#5,d1			*same as lsr.w	#11,d1
	andi.b	#$1f,d1
	move.b	d1,(a2)+
	dbra	d4,mk_ddlp

	lea	header+2(pc),a2
	move.b	d3,(a2)+		*set dev id
	move.b	#$45,(a2)+		*set model id
	addq.w	#1,a2
	move.b	#$10,(a2)+		*address H
	move.w	#$0100,(a2)+		*address L
	bsr	send_header
	moveq.l	#64,d2			*data length
	move.l	v_buffer(pc),a1
	bsr	trans_midi_dat		*データ本体を転送(> d3=sum)
	add.b	#$11,d3			*$11=addr sum
	andi.b	#$7f,d3
	moveq.l	#$80,d0
	sub.b	d3,d0
	andi.b	#$7f,d0
	jsr	(a5)
	moveq.l	#$f7,d0
	jsr	(a5)
	t_dat_ok

gm_system_on:				*GMシステム・オン
	*   cmd=$29
	* < d1.w=midi-out port number(0-3,-1:current)
	* > d0.l=error code
	bsr	get_m_out_addr
	lea	gmon_dat(pc),a1
@@:
	move.b	(a1)+,d0
	beq	t_dat_ok
	jsr	(a5)
	bra	@b

gmon_dat:
	dc.b	$f0,$7e,$7f,$09,$01,$f7
	dc.b	0
	.even

mt32_reset:			*MT32の初期化
	*   cmd=$30
	* < d1.w=midi-out port number(0-3,-1:current)
	* < d3.b=mt32 id number(0-127,-1:current)
	* > d0.l=error code
	bsr	get_m_out_addr
	bsr	getset_mt32_id			*ID保存／取得
	lea	header(pc),a1
	moveq.l	#11,d2
	move.b	d3,2(a1)
	move.b	#$16,3(a1)
	move.b	#$7f,5(a1)
	move.l	#$00000001,6(a1)
	bsr	trans_midi_dat
	t_dat_ok

mt32_partial_reserve:				*MT32のパーシャルリザーブを設定
	*   cmd=$31
	* < a1.l=data address
	* < d1.w=midi-out port number(0-3,-1:current)
	* < d3.b=mt32 id number(0-127,-1:current)
	* > d0.l=error code
	bsr	get_m_out_addr
	bsr	getset_mt32_id			*ID保存／取得
	lea	header+2(pc),a2
	move.b	d3,(a2)+		*set dev ID
	move.b	#$16,(a2)+		*set model id
	addq.w	#1,a2
	move.b	#$10,(a2)+		*set addr H
	move.w	#$0004,(a2)+		*set addr L
	bsr	send_header
	moveq.l	#9,d2
	bsr	trans_midi_dat		*data 本体を転送(> d3=sum)
	add.b	#$14,d3			*$14=addr sum
	andi.b	#$7f,d3
	moveq.l	#$80,d0
	sub.b	d3,d0
	andi.b	#$7f,d0
	jsr	(a5)
	moveq.l	#$f7,d0
	jsr	(a5)
	t_dat_ok

mt32_reverb:				*MT32のリバーブパラメータ設定
	*   cmd=$32
	* < a1.l=data address
	* < d1.w=midi-out port number(0-3,-1:current)
	* < d2.l=size
	* < d3.b=mt32 id number(0-127,-1:current)
	* > d0.l=error code
	bsr	get_m_out_addr
	tst.l	d2
	beq	t_illegal_data_size
	cmpi.l	#3,d2
	bhi	t_illegal_data_size
	bsr	getset_mt32_id			*ID保存／取得
	lea	header+2(pc),a2
	move.b	d3,(a2)+		*set dev ID
	move.b	#$16,(a2)+		*set model id
	addq.w	#1,a2
	move.b	#$10,(a2)+		*set addr H
	move.w	#$0001,(a2)+		*set addr L
	bsr	send_header
	bsr	trans_midi_dat		*data 本体を転送(> d3=sum)
	add.b	#$11,d3			*$11=addr sum
	andi.b	#$7f,d3
	moveq.l	#$80,d0
	sub.b	d3,d0
	andi.b	#$7f,d0
	jsr	(a5)
	moveq.l	#$f7,d0
	jsr	(a5)
	t_dat_ok

mt32_part_setup:			*MT32のパートパラメータ設定
	*   cmd=$33
	* < a1.l=data address
	* < d1.w=midi-out port number(0-3,-1:current)
	* < d2.l=size
	* < d3.b=mt32 id number(0-127,-1:current)
	* > d0.l=error code
	bsr	get_m_out_addr
	tst.l	d2
	beq	t_illegal_data_size
	cmpi.l	#9,d2
	bhi	t_illegal_data_size
	bsr	getset_mt32_id		*ID保存／取得
	lea	header+2(pc),a2
	move.b	d3,(a2)+		*set dev ID
	move.b	#$16,(a2)+		*set model id
	addq.w	#1,a2
	move.b	#$10,(a2)+		*set addr H
	move.w	#$000d,(a2)+		*set addr L
	bsr	send_header

	move.l	v_buffer(pc),a2
	move.l	d2,d1
	subq.w	#1,d1			*for dbra
mk_mdch_lp:				*1～16->$00～$0f
	move.b	(a1)+,d0
	subq.b	#1,d0
	cmpi.b	#$0f,d0
	bls	@f
	moveq.l	#$10,d0			*規定外はOFFとみなす
@@:
	move.b	d0,(a2)+
	dbra	d1,mk_mdch_lp
	move.l	v_buffer(pc),a1
	bsr	trans_midi_dat		*data 本体を転送(> d3=sum)
	add.b	#$1d,d3			*$1d=addr sum
	andi.b	#$7f,d3
	moveq.l	#$80,d0
	sub.b	d3,d0
	andi.b	#$7f,d0
	jsr	(a5)
	moveq.l	#$f7,d0
	jsr	(a5)
	t_dat_ok

mt32_drum_setup:			*MT32のドラムパラメータ設定
	*   cmd=$34
	* < a1.l=data address
	* < d1.w=midi-out port number(0-3,-1:current)
	* < d2.l=size
	* < d3.hw=tone no
	* < d3.lw=mt32 id number(0-127,-1:current)
	* > d0.l=error code
	bsr	get_m_out_addr
	tst.l	d2
	beq	t_illegal_data_size
	cmpi.l	#4,d2
	bhi	t_illegal_data_size
	bsr	getset_mt32_id			*ID保存／取得
	lea	header+2(pc),a2
	move.b	d3,(a2)+		*set dev ID
	move.b	#$16,(a2)+		*set model id
	addq.w	#1,a2
	move.l	#$030110,d4		*parameter base address
	swap	d3
	cmpi.w	#87,d3
	bhi	t_illegal_note_number	*MTでは受信不可
	sub.w	#24,d3
	bmi	t_illegal_note_number
	add.w	d3,d3
	add.w	d3,d3
	add.w	d3,d4			*exact address
	bclr.l	#7,d4
	beq	@f
	add.w	#$0100,d4
@@:
	swap	d4
	move.b	d4,(a2)+		*set addr H
	move.b	d4,d1			*sum
	swap	d4
	move.w	d4,(a2)+		*set addr L
	add.b	d4,d1
	lsr.w	#8,d4
	add.b	d4,d1			*sum
	move.b	d1,-(sp)
	bsr	send_header
	bsr	trans_midi_dat		*data 本体を転送(> d3=sum)
	add.b	(sp)+,d3		*addr sum
	andi.b	#$7f,d3
	moveq.l	#$80,d0
	sub.b	d3,d0
	andi.b	#$7f,d0
	jsr	(a5)
	moveq.l	#$f7,d0
	jsr	(a5)
	t_dat_ok

mt32_common:			*MT32の音色コモンパラメータ設定
	*   cmd=$35
	* < a1.l=data address
	* < d1.w=midi-out port number(0-3,-1:current)
	* < d2.l=size
	* < d3.hw=program number(1-64)
	* < d3.lw=mt32 id number(0-127,-1:current)
	* > d0.l=error code
	bsr	get_m_out_addr
	tst.l	d2
	beq	t_illegal_data_size
	cmpi.l	#15,d2
	bhi	t_illegal_data_size
	bsr	getset_mt32_id			*ID保存／取得
	lea	header+2(pc),a2
	move.b	d3,(a2)+		*set dev ID
	move.b	#$16,(a2)+		*set model id
	addq.w	#1,a2
	move.l	#$080000,d4		*base address
	swap	d3
	subq.w	#1,d3			*make prog number 0-63
	bmi	t_illegal_tone_number
	cmpi.w	#63,d3
	bhi	t_illegal_tone_number
	ror.w	#7,d3			*d3=d3*512
	move.w	d3,d4			*exact address
	swap	d4
	move.b	d4,(a2)+		*set addr H
	move.b	d4,d1			*sum
	swap	d4
	move.w	d4,(a2)+		*set addr L
	add.b	d4,d1
	lsr.w	#8,d4
	add.b	d4,d1			*address sum
	move.b	d1,-(sp)		*sum保存
	bsr	send_header		*send header
	move.l	v_buffer(pc),a2
	moveq.l	#0,d0
@@:
	addq.l	#1,d0		*文字数カウント
	move.b	(a1)+,(a2)+
	bne	@b
	subq.w	#1,a2
	moveq.l	#10+1,d1
	sub.l	d0,d1
	beq	trns_cmp		*10文字丁度:他のパラメータの処理に
	bmi	t_illegal_string_length	*10文字以上:エラー
	subq.b	#1,d1			*for dbra
@@:
	move.b	#" ",(a2)+		*足りない分をスペースで埋める
	dbra	d1,@b
trns_cmp:
	sub.l	d0,d2
	bmi	t_illegal_parameter_format	*異常事態発生
	beq	send_cmdt
	move.l	d2,d0
	subq.l	#1,d0			*for dbra
@@:
	move.b	(a1)+,(a2)+		*数値パラメータをワークへ
	dbra	d0,@b
send_cmdt:
	add.w	#10,d2			*データ総バイト数
	move.l	v_buffer(pc),a1
	bsr	trans_midi_dat		*data 本体を転送(> d3=sum)
	add.b	(sp)+,d3		*addr sum
	andi.b	#$7f,d3
	moveq.l	#$80,d0
	sub.b	d3,d0
	andi.b	#$7f,d0
	jsr	(a5)
	moveq.l	#$f7,d0
	jsr	(a5)
	t_dat_ok

mt32_partial:			*MT32の音色パーシャルパラメータ設定
	*   cmd=$36
	* < a1.l=data address
	* < d1.w=midi-out port number(0-3,-1:current)
	* < d2.l=size
	* < d3.hw=program number(1-64)*256+partial number(1-4)
	* < d3.lw=mt32 id number(0-127,-1:current)
	* > d0.l=error code
	bsr	get_m_out_addr
	tst.l	d2
	beq	t_illegal_data_size
	cmpi.l	#58,d2
	bhi	t_illegal_data_size
	bsr	getset_mt32_id		*ID保存／取得

	lea	header+2(pc),a2
	move.b	d3,(a2)+		*set dev ID
	move.b	#$16,(a2)+		*set model id
	addq.w	#1,a2
	move.l	#$080000,d4		*base address
	swap	d3
	move.w	d3,d5			*後でﾊﾟｰｼｬﾙﾅﾝﾊﾞｰとして使う
	lsr.w	#8,d3
	subq.w	#1,d3			*make prog number 0-63
	bmi	t_illegal_tone_number
	cmpi.w	#64-1,d3
	bhi	t_illegal_tone_number
	ror.w	#7,d3			*d3=d3*512
	move.w	d3,d4
	subq.b	#1,d5			*1-4 -> 0-3
	bmi	t_illegal_parameter_value
	cmpi.b	#4-1,d5
	bhi	t_illegal_parameter_value
	ext.w	d5
	mulu	#58,d5			*1パーシャルのパラメータ数
	add.w	#$0e,d5			*partial offset
	move.b	d5,d4
	andi.b	#$7f,d4
	add.w	d5,d5			*lsl.w	#1,d5
	andi.w	#$7f00,d5
	add.w	d5,d4			*exact address
	swap	d4
	move.b	d4,(a2)+		*set addr H
	move.b	d4,d1			*sum
	swap	d4
	move.w	d4,(a2)+		*set addr L
	add.b	d4,d1
	lsr.w	#8,d4
	add.b	d4,d1			*address sum
	move.b	d1,-(sp)
	bsr	send_header		*send header
	bsr	trans_midi_dat		*data 本体を転送(> d3=sum)
	add.b	(sp)+,d3		*addr sum
	andi.b	#$7f,d3
	moveq.l	#$80,d0
	sub.b	d3,d0
	andi.b	#$7f,d0
	jsr	(a5)
	moveq.l	#$f7,d0
	jsr	(a5)
	t_dat_ok

mt32_patch:				*MT32の音色パッチパラメータ設定
	*   cmd=$37
	* < a1.l=data address
	* < d1.w=midi-out port number(0-3,-1:current)
	* < d2.l=size
	* < d3.hw=patch number(1-128)
	* < d3.lw=mt32 id number(0-127,-1:current)
	* > d0.l=error code
	bsr	get_m_out_addr		*>a5=m_out_xx addr
	tst.l	d2
	beq	t_illegal_data_size
	cmpi.l	#7,d2
	bhi	t_illegal_data_size
	bsr	getset_mt32_id		*ID保存／取得

	lea	header+2(pc),a2
	move.b	d3,(a2)+		*set dev ID
	move.b	#$16,(a2)+		*set model id
	addq.w	#1,a2
	move.l	#$050000,d4		*base address
	swap	d3
	subq.w	#1,d3		*make patch number 0-127
	bmi	t_illegal_tone_number
	cmpi.w	#127,d3
	bhi	t_illegal_tone_number
	lsl.w	#3,d3		*d3=d3*8
	move.b	d3,d4
	andi.b	#$7f,d4
	add.w	d3,d3		*lsl.w	#1,d3
	andi.w	#$7f00,d3
	add.w	d3,d4			*exact address
	swap	d4
	move.b	d4,(a2)+		*set addr H
	move.b	d4,d1			*sum
	swap	d4
	move.w	d4,(a2)+		*set addr L
	add.b	d4,d1
	lsr.w	#8,d4
	add.b	d4,d1			*address sum
	move.b	d1,-(sp)
	bsr	send_header		*send header
	bsr	trans_midi_dat		*data 本体を転送(> d3=sum)
	add.b	(sp)+,d3		*addr sum
	andi.b	#$7f,d3
	moveq.l	#$80,d0
	sub.b	d3,d0
	andi.b	#$7f,d0
	jsr	(a5)
	moveq.l	#$f7,d0
	jsr	(a5)
	t_dat_ok

mt32_print:
	*   cmd=$38
	* < a1.l=data address
	* < d1.w=midi-out port number(0-3,-1:current)
	* < d2.l=size
	* < d3.b=mt32 id number(0-127,-1:current)
	* > d0.l=error code
	bsr	get_m_out_addr		*>a5=m_out_xx addr
	tst.l	d2
	beq	t_illegal_string_length
	cmpi.l	#20,d2
	bhi	t_illegal_string_length
	bsr	getset_mt32_id		*ID保存／取得

	lea	header+2(pc),a2
	move.b	d3,(a2)+		*set dev ID
	move.b	#$16,(a2)+		*set model id
	addq.w	#1,a2
	move.b	#$20,(a2)+
	clr.w	(a2)+
	bsr	send_header
	bsr	trans_midi_dat		*(> d3=sum)
	add.b	#$20,d3			*addr sum
	andi.b	#$7f,d3
	moveq.l	#$80,d0
	sub.b	d3,d0
	andi.b	#$7f,d0
	jsr	(a5)
	moveq.l	#$f7,d0
	jsr	(a5)
	t_dat_ok

u220_setup:				*U220のセットアップパラメータ設定
	*   cmd=$39
	* < a1.l=data address
	* < d1.w=midi-out port number(0-3,-1:current)
	* < d3.b=u220 id number(0-127,-1:current)
	* > d0.l=error code
	bsr	get_m_out_addr		*>a5=m_out_xx addr
	bsr	getset_u220_id		*ID保存／取得

	lea	header+2(pc),a2
	move.b	d3,(a2)+		*set dev ID
	move.b	#$2b,(a2)+		*set model id
	addq.w	#1,a2
	clr.b	(a2)+			*set addr H
	clr.w	(a2)+			*set addr L
	bsr	send_header
	move.l	v_buffer(pc),a2
	move.l	#$0e07_0a00,(a2)+	*440.0Hz,LCD=10
	move.b	(a1)+,d0		*chorus sw
	add.b	d0,d0			*lsl.b	#1,d0
	or.b	(a1)+,d0		*reverb sw
	move.b	d0,-1(a2)
	clr.l	(a2)+			*dummy data
	move.b	(a1)+,d0		*Rx_ctrl channel
	subq.b	#1,d0
	cmpi.b	#$0f,d0
	bls	@f
	moveq.l	#$10,d0		*規定外はOFFとみなす
@@:
	bsr	stu2_dt
	clr.b	(a2)+		*dummy data
	clr.b	(a2)+
	moveq.l	#4-1,d2
@@:
	move.b	(a1)+,(a2)+	*patch change,timbre change,rythm change,Rx.R.inst Assign
	dbra	d2,@b

	moveq.l	#16,d2		*d2=size
	move.l	v_buffer(pc),a1
	bsr	trans_midi_dat	*(> d3=sum)
	andi.b	#$7f,d3
	moveq.l	#$80,d0
	sub.b	d3,d0
	andi.b	#$7f,d0
	jsr	(a5)
	moveq.l	#$f7,d0
	jsr	(a5)
	t_dat_ok

stu2_dtw:			*set data その２
	* < a2.l=buffer address
	* < d0.w=data
	bsr	stu2_dt
	lsr.w	#8,d0
stu2_dt:			*set data
	* < a2.l=buffer address
	* < d0.b=data
	move.b	d0,-(sp)
	andi.b	#$0f,d0
	move.b	d0,(a2)+
	move.b	(sp)+,d0
	lsr.b	#4,d0
	move.b	d0,(a2)+
	rts

u220_part_setup:			*U220のﾃﾝﾎﾟﾗﾘｰﾊﾟｯﾁの(PART)ﾊﾟﾗﾒｰﾀ設定
	*   cmd=$3a
	* < a1.l=data address
	* < d1.w=midi-out port number(0-3,-1:current)
	* < d3.hw=part number(1～6)
	* < d3.lw=u220 id number(0-127,-1:current)
	* > d0.l=error code
	bsr	get_m_out_addr		*>a5=m_out_xx addr
	bsr	getset_u220_id		*ID保存／取得

	lea	header+2(pc),a2
	move.b	d3,(a2)+	*set dev ID
	move.b	#$2b,(a2)+	*set model id
	addq.w	#1,a2
	moveq.l	#$3c,d4		*base address
	swap	d3
	subq.w	#1,d3		*make 1-6 -> 0-5
	bmi	t_illegal_part_number
	cmpi.w	#5,d3
	bhi	t_illegal_part_number
	lsl.w	#4,d3		*d3=d3*16
	add.w	d3,d4
	move.l	d4,d3
	andi.b	#$7f,d3
	add.w	d4,d4		*lsl.w	#1,d4
	andi.w	#$7f00,d4
	move.b	d3,d4
	ori.w	#$0600,d4	*d4=exact address
	swap	d4
	move.b	d4,(a2)+	*set addr H
	move.b	d4,d1		*sum
	swap	d4
	move.w	d4,(a2)+	*set addr L
	add.b	d4,d1
	lsr.w	#8,d4
	add.b	d4,d1		*address sum
	move.b	d1,-(sp)
	bsr	send_header
	move.l	v_buffer(pc),a2
	move.b	(a1),d0		*timbre number
	subq.b	#1,d0		*1～128→0～127
	bmi	t_illegal_tone_number
	move.b	10(a1),d1	*Rx.volume
	lsl.b	#7,d1
	or.b	d1,d0
	bsr	stu2_dt

	move.b	1(a1),d0	*v reserve
	move.b	7(a1),d1	*out assign
	lsl.b	#5,d1
	or.b	d1,d0
	bsr	stu2_dt

	moveq.l	#0,d0
	move.b	2(a1),d0	*midi ch
	subq.b	#1,d0
	cmpi.b	#$0f,d0
	bls	@f
	moveq.l	#$10,d0		*規定外OFFとみなす
@@:
	moveq.l	#0,d1
	move.b	8(a1),d1	*part level
	lsl.w	#5,d1
	or.w	d1,d0
	move.b	9(a1),d1	*part pan
	swap	d1
	lsr.l	#4,d1
	or.w	d1,d0
	bsr	stu2_dtw	*2bytes書き込み

	move.b	3(a1),d0	*k.range low
	move.b	12(a1),d1	*Rx.HOLD
	lsl.b	#7,d1
	or.b	d1,d0
	bsr	stu2_dt

	move.b	4(a1),d0	*k.range hi
	move.b	11(a1),d1	*Rx.PAN
	lsl.b	#7,d1
	or.b	d1,d0
	bsr	stu2_dt

	move.b	5(a1),d0	*velo level
	bsr	stu2_dt
	move.b	6(a1),d0	*velo threshold
	bsr	stu2_dt

	moveq.l	#16,d2
	move.l	v_buffer(pc),a1
	bsr	trans_midi_dat	*(>d3=sum)
	add.b	(sp)+,d3
	andi.b	#$7f,d3
	moveq.l	#$80,d0
	sub.b	d3,d0
	andi.b	#$7f,d0
	jsr	(a5)
	moveq.l	#$f7,d0
	jsr	(a5)
	t_dat_ok

u220_common:				*U220のﾃﾝﾎﾟﾗﾘｰﾊﾟｯﾁのｺﾓﾝﾊﾟﾗﾒｰﾀ設定
	*   cmd=$3b
	* < a1.l=data address
	* < d1.w=midi-out port number(0-3,-1:current)
	* < d3.b=u220 id number(0-127,-1:current)
	* > d0.l=error code
	bsr	get_m_out_addr		*>a5=m_out_xx addr
	bsr	getset_u220_id		*ID保存／取得

	lea	header+2(pc),a2
	move.b	d3,(a2)+		*set dev ID
	move.b	#$2b,(a2)+		*set model id
	addq.w	#1,a2
	clr.b	(a2)+			*set addr H
	move.w	#$0618,(a2)+		*set addr L
	bsr	send_header
	move.l	v_buffer(pc),a2
	moveq.l	#0,d0
	move.b	4(a1),d0	*cho rate
	moveq.l	#0,d1
	move.b	2(a1),d1	*cho level
	lsl.w	#6,d1
	or.w	d1,d0
	move.b	5(a1),d1	*cho depth
	swap	d1		*lsl.l	#16,d1
	lsr.l	#5,d1
	or.w	d1,d0
	bsr	stu2_dtw

	moveq.l	#0,d0
	move.b	8(a1),d0	*rev time
	moveq.l	#0,d1
	move.b	6(a1),d1	*cho FB
	lsl.w	#7,d1
	or.w	d1,d0
	move.b	(a1),d1		*cho type
	swap	d1
	lsr.l	#3,d1
	or.w	d1,d0
	bsr	stu2_dtw

	moveq.l	#0,d0
	move.b	3(a1),d0	*cho delay time
	moveq.l	#0,d1
	move.b	10(a1),d1	*rev FB
	swap	d1
	lsr.l	#5,d1
	or.w	d1,d0
	bsr	stu2_dtw

	moveq.l	#0,d0
	move.b	9(a1),d0	*rev level
	moveq.l	#0,d1
	move.b	11(a1),d1	*pre rev dly time
	lsl.w	#6,d1
	or.w	d1,d0
	move.b	7(a1),d1	*rev type
	swap	d1
	lsr.l	#4,d1
	or.w	d1,d0
	add.w	d0,d0		*lsl.w	#1,d0
	move.b	1(a1),d1	*out mode
	lsr.b	#1,d1
	roxr.w	#1,d0
	bsr	stu2_dtw

	lea	12(a1),a1
	moveq.l	#3-1,d3
@@:
	move.b	(a1)+,d0	*ctrl #1-3
	ror.w	#8,d0
	move.b	(a1)+,d0	*parameter #1-3
	ror.w	#8,d0
	bsr	stu2_dtw
	dbra	d3,@b

	moveq.l	#28,d2
	move.l	v_buffer(pc),a1
	bsr	trans_midi_dat	*>d3=sum
	add.b	#$1e,d3		*address sum
	andi.b	#$7f,d3
	moveq.l	#$80,d0
	sub.b	d3,d0
	andi.b	#$7f,d0
	jsr	(a5)
	moveq.l	#$f7,d0
	jsr	(a5)
	t_dat_ok

u220_timbre:			*U220の音色パラメータ設定
	*   cmd=$3c
	* < a1.l=data address
	* < d1.w=midi-out port number(0-3,-1:current)
	* < d3.hw=program number(1-128)
	* < d3.lw=u220 id number(0-127,-1:current)
	* > d0.l=error code
	bsr	get_m_out_addr		*>a5=m_out_xx addr
	bsr	getset_u220_id		*ID保存／取得

	lea	header+2(pc),a2
	move.b	d3,(a2)+		*set dev ID
	move.b	#$2b,(a2)+		*set model id
	addq.w	#1,a2
	swap	d3
	subq.w	#1,d3		*make prog number 0-127
	bmi	t_illegal_tone_number
	cmpi.w	#127,d3
	bhi	t_illegal_tone_number
	moveq.l	#0,d4
	lsl.w	#6,d3
	move.w	d3,d4
	andi.b	#$7f,d3
	add.l	d4,d4		*lsl.l	#1,d4
	move.b	d3,d4
	add.l	#$020000,d4	*d4=exact address
	swap	d4
	move.b	d4,(a2)+		*set addr H
	move.b	d4,d1			*sum
	swap	d4
	move.w	d4,(a2)+		*set addr L
	add.b	d4,d1
	lsr.w	#8,d4
	add.b	d4,d1			*address sum
	move.b	d1,-(sp)
	bsr	send_header		*send header
	move.l	v_buffer(pc),a2
	moveq.l	#0,d3
@@:
	addq.l	#1,d3		*文字数カウント
	move.b	(a1)+,d0
	beq	@f
	bsr	stu2_dt
	bra	@b
@@:
	moveq.l	#12+1,d1
	sub.l	d3,d1
	beq	trns_cmp_u	*12文字丁度:他のパラメータの処理に
	bmi	t_illegal_string_length
	subq.b	#1,d1		*for dbra
@@:
	moveq.l	#$20,d0
	bsr	stu2_dt		*足りない分をスペースで埋める
	dbra	d1,@b
trns_cmp_u:
	moveq.l	#0,d0
	move.b	1(a1),d0		*tone #
	subq.b	#1,d0
	bmi	t_illegal_note_number	*トーンナンバー異常
	moveq.l	#0,d1
	move.b	(a1),d1			*tone Meida
	lsl.w	#7,d1
	or.w	d1,d0
	move.b	17(a1),d1		*detune depth
	swap	d1
	lsr.l	#4,d1
	or.w	d1,d0
	bsr	stu2_dtw

	move.b	3(a1),d0		*level velo sens
	move.b	4(a1),d1		*level ch aft
	lsl.b	#4,d1
	or.b	d1,d0
	bsr	stu2_dt
	move.b	2(a1),d0		*timbre level
	bsr	stu2_dt

	move.b	5(a1),d0		*Env A
	move.b	6(a1),d1		*Env D
	lsl.b	#4,d1
	or.b	d1,d0
	bsr	stu2_dt
	move.b	7(a1),d0		*Env S
	move.b	8(a1),d1		*Env R
	lsl.b	#4,d1
	or.b	d1,d0
	bsr	stu2_dt

	move.b	10(a1),d0		*Pitch fine
	bsr	stu2_dt
	move.b	09(a1),d0		*Pitch coarse
	bsr	stu2_dt

	moveq.l	#0,d0
	move.b	11(a1),d0		*Bend lower
	moveq.l	#0,d1
	move.b	12(a1),d1		*Bend upper
	lsl.w	#5,d1
	or.w	d1,d0
	move.b	15(a1),d1		*Auto Bend depth
	swap	d1
	lsr.l	#7,d1
	or.w	d1,d0
	bsr	stu2_dtw

	moveq.l	#0,d0
	move.b	14(a1),d0		*Pitch poly aft
	moveq.l	#0,d1
	move.b	13(a1),d1		*Pitch ch aft
	lsl.w	#5,d1
	or.w	d1,d0
	move.b	16(a1),d1		*Auto Bend rate
	swap	d1
	lsr.l	#6,d1
	or.w	d1,d0
	bsr	stu2_dtw

	move.b	23(a1),d0		*Mod depth
	lsl.b	#4,d0
	bsr	stu2_dt
	move.b	21(a1),d0		*Vib delay
	move.b	20(a1),d1		*Vib depth
	lsl.b	#4,d1
	or.b	d1,d0
	bsr	stu2_dt

	move.b	18(a1),d0		*Vib rate
	bsr	stu2_dt
	move.b	19(a1),d0		*Vib WF
	bsr	stu2_dt

	move.b	22(a1),d0		*Vib rise
	bsr	stu2_dt
	move.b	24(a1),d0		*Vib ch aft
	move.b	25(a1),d1		*Vib poly aft
	lsl.b	#4,d1
	or.b	d1,d0
	bsr	stu2_dt
	moveq.l	#0,d0			*Dummy
	bsr	stu2_dtw
send_cmdt_u:
	moveq.l	#$40,d2			*データ総バイト数
	move.l	v_buffer(pc),a1
	bsr	trans_midi_dat		*data 本体を転送(>d3=sum)
	add.b	(sp)+,d3		*address sum
	andi.b	#$7f,d3
	moveq.l	#$80,d0
	sub.b	d3,d0
	andi.b	#$7f,d0
	jsr	(a5)
	moveq.l	#$f7,d0
	jsr	(a5)
	t_dat_ok

u220_drum_setup:				*U220のﾃﾝﾎﾟﾗﾘｰﾊﾟｯﾁの(DRUM)ﾊﾟﾗﾒｰﾀ設定
	*   cmd=$3d
	* < a1.l=data address
	* < d1.w=midi-out port number(0-3,-1:current)
	* < d3.b=u220 id number(0-127,-1:current)
	* > d0.l=error code
	bsr	get_m_out_addr		*>a5=m_out_xx addr
	bsr	getset_u220_id		*ID保存／取得

	lea	header+2(pc),a2
	move.b	d3,(a2)+		*set dev ID
	move.b	#$2b,(a2)+		*set model id
	addq.w	#1,a2
	clr.b	(a2)+			*set addr H
	move.w	#$0634,(a2)+		*set addr L
	bsr	send_header
	move.l	v_buffer(pc),a2
	move.b	1(a1),d0		*rythm v rsv
	move.b	(a1),d1			*rythm set number
	lsl.b	#5,d1
	or.b	d1,d0
	bsr	stu2_dt

	move.b	2(a1),d0		*rythm part ch
	subq.b	#1,d0
	cmpi.b	#$0f,d0
	bls	@f
	moveq.l	#$10,d0			*規定外の時はOFFとみなす
@@:
	move.b	6(a1),d1		*rythm part Rx.HOLD
	lsl.b	#5,d1
	or.b	d1,d0
	move.b	5(a1),d1		*rythm part Rx.VOLUME
	lsl.b	#6,d1
	or.b	d1,d0
	bsr	stu2_dt

	move.b	3(a1),d0		*rythm part level
	move.b	4(a1),d1		*rythm part boost sw
	lsl.b	#7,d1
	or.b	d1,d0
	bsr	stu2_dt
	clr.w	(a2)			*dummy

	moveq.l	#8,d2
	move.l	v_buffer(pc),a1
	bsr	trans_midi_dat		*>d3=sum
	add.b	#$3a,d3			*address sum
	andi.b	#$7f,d3
	moveq.l	#$80,d0
	sub.b	d3,d0
	andi.b	#$7f,d0
	jsr	(a5)
	moveq.l	#$f7,d0
	jsr	(a5)
	t_dat_ok

u220_drum_inst:				*U220のﾃﾝﾎﾟﾗﾘｴﾘｱのﾄﾞﾗﾑの音色を変更する
	*   cmd=$3e
	* < a1.l=data address
	* < d1.w=midi-out port number(0-3,-1:current)
	* < d3.hw=patch number(35～99)
	* < d3.lw=u220 id number(0-127,-1:current)
	* > d0.l=error code
	bsr	get_m_out_addr		*>a5=m_out_xx addr
	bsr	getset_u220_id		*ID保存／取得

	lea	header+2(pc),a2
	move.b	d3,(a2)+		*set dev ID
	move.b	#$2b,(a2)+		*set model id
	addq.w	#1,a2
	move.l	#$110000,d4		*base address
	swap	d3
	cmpi.w	#35,d3
	bcs	t_illegal_note_number
	cmpi.w	#99,d3
	bhi	t_illegal_note_number
	lsl.w	#8,d3			*d3=d3*256
	add.w	d3,d4			*exact address
	swap	d4
	move.b	d4,(a2)+		*set addr H
	move.b	d4,d1			*sum
	swap	d4
	move.w	d4,(a2)+		*set addr L
	add.b	d4,d1
	lsr.w	#8,d4
	add.b	d4,d1			*address sum
	move.b	d1,-(sp)
	bsr	send_header		*send header
	move.b	1(a1),d0
	subq.b	#1,d0
	bmi	t_illegal_tone_number
	move.b	1(a1),-(sp)		*save parameter
	move.b	d0,1(a1)
	moveq.l	#20-1,d2
	bsr	trans_midi_dat		*data 本体を転送(>d3=sum)
	move.b	(sp)+,1(a1)		*back parameter
	add.b	(sp)+,d3		*address sum
	andi.b	#$7f,d3
	moveq.l	#$80,d0
	sub.b	d3,d0
	andi.b	#$7f,d0
	jsr	(a5)
	moveq.l	#$f7,d0
	jsr	(a5)
	t_dat_ok

u220_print:
	*   cmd=$3f
	* < a1.l=data address
	* < d1.w=midi-out port number(0-3,-1:current)
	* < d2.l=size
	* < d3.b=u220 id number(0-127,-1:current)
	* > d0.l=error code
	bsr	get_m_out_addr		*>a5=m_out_xx addr
	tst.l	d2
	beq	t_illegal_string_length
	cmpi.l	#12,d2
	bhi	t_illegal_string_length
	bsr	getset_u220_id		*ID保存／取得

	lea	header+2(pc),a2
	move.b	d3,(a2)+		*set dev ID
	move.b	#$2b,(a2)+		*set model id
	addq.w	#1,a2
	clr.b	(a2)+			*address H
	move.w	#$0600,(a2)+		*address L
	bsr	send_header
	move.l	v_buffer(pc),a2
	move.l	d2,d3
	subq.l	#1,d3		*for dbra
@@:
	move.b	(a1)+,d0
	bsr	stu2_dt
	dbra	d3,@b
	moveq.l	#12-1,d1
	sub.w	d2,d1
	bmi	send_u2pr
@@:
	moveq.l	#$20,d0		*SPC
	bsr	stu2_dt
	dbra	d1,@b
send_u2pr:
	moveq.l	#24,d2
	move.l	v_buffer(pc),a1
	bsr	trans_midi_dat	*>d3=sum
	addq.b	#$06,d3		*address sum
	andi.b	#$7f,d3
	moveq.l	#$80,d0
	sub.b	d3,d0
	andi.b	#$7f,d0
	jsr	(a5)
	moveq.l	#$f7,d0
	jsr	(a5)
	t_dat_ok

m1_setup:			*M1の受信MIDI CHの設定
	*   cmd=$40
	* < a1.l=data address
	* > d0.l=error code
	move.l	v_buffer(pc),a2
	addq.w	#8,a2
	lea	8(a2),a3
	moveq.l	#8-1,d2		*dbra count
m1_md_lp:
	moveq.l	#03,d1		*ON
	move.b	(a1)+,d0
	subq.b	#1,d0
	cmpi.b	#$0f,d0
	bls	@f
	moveq.l	#0,d0		*一応チャンネル１にする
	moveq.l	#0,d1		*OFF
@@:
	move.b	d0,(a2)+
	move.b	d1,(a3)+
	dbra	d2,m1_md_lp
	t_dat_ok

m1_part_setup:			*M1のSEQ SONG0の設定
	*   cmd=$41
	* < a1.l=data address
	* > d0.l=error code
	move.l	v_buffer(pc),a2
	lea	56(a2),a2
	moveq.l	#40-1,d2
@@:
	move.b	(a1)+,(a2)+
	dbra	d2,@b
	t_dat_ok

m1_effect_setup:		*M1のSEQ SONG0のEFFECTの設定
	*   cmd=$42
	* < a1.l=data address
	* > d0.l=error code
	lea	m1_ef_dflt(pc),a2
	moveq.l	#25-1,d2	*=dbra counter
@@:
	move.b	(a1)+,(a2)+
	dbra	d2,@b
	t_dat_ok

m1_print:			*M1のSEQ SONG0のNAME設定
	*   cmd=$43
	* < a1.l=data address
	* < d2.l=size
	* > d0.l=error code
	cmpi.l	#10,d2
	bhi	t_illegal_string_length
	move.l	v_buffer(pc),a2
	lea	20(a2),a2
	move.l	d2,d3
	subq.l	#1,d3		*for dbra
	bmi	t_illegal_string_length
@@:
	move.b	(a1)+,(a2)+
	dbra	d3,@b
	moveq.l	#10-1,d3
	sub.w	d2,d3
	bmi	t_dat_ok	*10文字丁度
@@:
	move.b	#$20,(a2)+	*SPC
	dbra	d3,@b
	t_dat_ok

send_to_m1:			*M1へパラメータを書き込む
	*   cmd=$44
	* < d1.w=midi-out port number(0-3,-1:current)
	* < d3.b=m1 id number(0-127,-1:current)
	* > d0.l=error code
	bsr	get_m_out_addr		*>a5=m_out_xx addr
	bsr	getset_m1_id		*ID保存／取得

	move.l	v_buffer(pc),a1
	move.l	#$f0420019,(a1)+	*header&maker ID,dummy,M1
	move.b	d3,-2(a1)		*ID
	move.l	#$48_00_0000,(a1)+	*cmd,bank,seq data size
	move.b	#$04,16(a1)		*beat
	move.b	#$78,17(a1)		*tempo/protect
	move.b	#$14,19(a1)		*next song
	clr.b	30(a1)			*nul
	lea	m1_ef_dflt+25(pc),a2
	moveq.l	#25-1,d0
@@:
	move.b	-(a2),31(a1,d0.w)	*エフェクトデータのセット
	dbra	d0,@b

	moveq.l	#96-1,d0			*データ列のならび変え
@@:
	move.l	d0,d1
	divu.w	#7,d1
	add.w	d0,d1
	move.b	(a1,d0.w),1(a1,d1.w)
	dbra	d0,@b

	moveq.l	#0,d2			*MIDIデータへの変換
stmlp:
	moveq.l	#7-1,d1
	moveq.l	#0,d3
@@:
	move.b	1(a1,d1.w),d0
	andi.b	#$7f,1(a1,d1.w)
	lsl.b	#1,d0
	roxl.b	#1,d3
	dbra	d1,@b
	move.b	d3,(a1)
	addq.w	#8,a1
	addq.w	#7,d2
	cmpi.w	#96,d2
	bls	stmlp
@@:
	move.l	v_buffer(pc),a1
	move.b	#$f7,$76(a1)		*EOX
	moveq.l	#$77,d2
	bsr	trans_midi_dat		*>d3=sum

	move.l	v_buffer(pc),a1		*SEQ0にする
	move.l	#$4e0600f7,4(a1)	*cmd,mode,bank,EOX
	moveq.l	#$8,d2
	bsr	trans_midi_dat		*>d3=sum
	t_dat_ok

sc88_mode_set:					*SC88のモードセット
	*   cmd=$46
	* < d1.w=midi-out port number(0-3,-1:current)
	* < d3.hw=sc88 mode (0:single or 1:double)
	* < d3.lw=sc88 id number(0-127,-1:current)
	* > d0.l=error code
	bsr	get_m_out_addr
	bsr	getset_gs_id			*ID保存／取得
	lea	header(pc),a1
	moveq.l	#11,d2
	move.b	d3,2(a1)
	move.b	#$42,3(a1)
	clr.b	5(a1)		*00
	move.w	#$007f,6(a1)	*addr=00007f
	swap	d3
	move.b	d3,8(a1)
	bne	@f
	move.b	#$01,9(a1)	*case:mode=$00
	bsr	trans_midi_dat
	t_dat_ok
@@:				*case:mode=$01
	clr.b	9(a1)
	bsr	trans_midi_dat
	t_dat_ok

sc88_reverb:				*SC88のリバーブパラメータ設定
	*   cmd=$47
	* < d1.w=midi-out port number(0-3,-1:current)
	* < a1.l=data address
	* < d2.l=size
	* < d3.b=sc88 id number(0-127,-1:current)
	* > d0.l=error code
	bsr	get_m_out_addr
	tst.l	d2
	beq	t_illegal_data_size
	cmpi.l	#8,d2
	bhi	t_illegal_data_size
	bsr	getset_sc88_id		*ID保存／取得
	lea	header+2(pc),a2
	move.b	d3,(a2)+		*set dev ID
	move.b	#$42,(a2)+		*set model id
	addq.w	#1,a2
	move.b	#$40,(a2)+
	move.w	#$0130,(a2)+
	bsr	send_header
	bsr	trans_midi_dat		*> d3.b=sum
	add.b	#$40+$01+$30,d3
	andi.b	#$7f,d3
	moveq.l	#$80,d0
	sub.b	d3,d0
	andi.b	#$7f,d0
	jsr	(a5)
	moveq.l	#$f7,d0
	jsr	(a5)
	t_dat_ok

sc88_chorus:			*SC88のコーラスパラメータ設定
	*   cmd=$48
	* < d1.w=midi-out port number(0-3,-1:current)
	* < a1.l=data address
	* < d2.l=size
	* < d3.b=SC88 id number(0-127,-1:current)
	* > d0.l=error code
	bsr	get_m_out_addr
	tst.l	d2
	beq	t_illegal_data_size
	cmpi.l	#9,d2
	bhi	t_illegal_data_size
	bsr	getset_sc88_id			*ID保存／取得
	lea	header+2(pc),a2
	move.b	d3,(a2)+			*set dev ID
	move.b	#$42,(a2)+			*set model id
	addq.w	#1,a2
	move.b	#$40,(a2)+
	move.w	#$0138,(a2)+
	bsr	send_header
	bsr	trans_midi_dat			*> d3.b=sum
	add.b	#$40+$01+$38,d3
	andi.b	#$7f,d3
	moveq.l	#$80,d0
	sub.b	d3,d0
	andi.b	#$7f,d0
	jsr	(a5)
	moveq.l	#$f7,d0
	jsr	(a5)
	t_dat_ok

sc88_delay:			*SC88のディレイパラメータ設定
	*   cmd=$49
	* < d1.w=midi-out port number(0-3,-1:current)
	* < a1.l=data address
	* < d2.l=size
	* < d3.b=SC88 id number(0-127,-1:current)
	* > d0.l=error code
	bsr	get_m_out_addr
	tst.l	d2
	beq	t_illegal_data_size
	cmpi.l	#11,d2
	bhi	t_illegal_data_size
	bsr	getset_sc88_id			*ID保存／取得
	lea	header+2(pc),a2
	move.b	d3,(a2)+			*set dev ID
	move.b	#$42,(a2)+			*set model id
	addq.w	#1,a2
	move.b	#$40,(a2)+
	move.w	#$0150,(a2)+
	bsr	send_header
	bsr	trans_midi_dat			*> d3.b=sum
	add.b	#$40+$01+$50,d3
	andi.b	#$7f,d3
	moveq.l	#$80,d0
	sub.b	d3,d0
	andi.b	#$7f,d0
	jsr	(a5)
	moveq.l	#$f7,d0
	jsr	(a5)
	t_dat_ok

sc88_equalizer:			*SC88のイコライザ・パラメータ設定
	*   cmd=$4a
	* < d1.w=midi-out port number(0-3,-1:current)
	* < a1.l=data address
	* < d2.l=size
	* < d3.b=SC88 id number(0-127,-1:current)
	* > d0.l=error code
	bsr	get_m_out_addr
	tst.l	d2
	beq	t_illegal_data_size
	cmpi.l	#4,d2
	bhi	t_illegal_data_size
	bsr	getset_sc88_id			*ID保存／取得
	lea	header+2(pc),a2
	move.b	d3,(a2)+			*set dev ID
	move.b	#$42,(a2)+			*set model id
	addq.w	#1,a2
	move.b	#$40,(a2)+
	move.w	#$0200,(a2)+
	bsr	send_header
	bsr	trans_midi_dat			*> d3.b=sum
	add.b	#$40+$02+$00,d3
	andi.b	#$7f,d3
	moveq.l	#$80,d0
	sub.b	d3,d0
	andi.b	#$7f,d0
	jsr	(a5)
	moveq.l	#$f7,d0
	jsr	(a5)
	t_dat_ok

sc88_part_setup:				*SC88のパートパラメータ設定
	*   cmd=$4b
	* < a1.l=data address
	* < d1.w=midi-out port number(0-3,-1:current)
	* < d2.l=size(1～119)
	* < d3.hw=sc88 part number(1-16)
	* < d3.lw=sc88 id number(0-127,-1:current)
	* > d0.l=error code
	bsr	get_m_out_addr
	subq.w	#1,d2			*for dbra
	cmp.l	#127-1,d2
	bhi	t_illegal_data_size
	bsr	getset_sc88_id		*ID保存／取得
	lea	header+2(pc),a2
	move.b	d3,(a2)+		*set dev ID
	move.b	#$42,(a2)+		*set model id
	move.l	#$401002,d4		*inst address
	swap	d3
	cmpi.w	#16,d3
	bhi	t_illegal_part_number
	cmpi.b	#10,d3
	bcs	@f			*9以下はそのまま
	bhi	1f
	moveq.l	#0,d3			*10はd3=0
	bra	@f
1:
	subq.b	#1,d3			*10以上はd3=d3-1
@@:
	lsl.w	#8,d3
	or.w	d3,d4			*d4.l=partナンバーに対応したアドレス値
	move.b	(a1),d0			*保存
	movem.l	d0/a1,-(sp)		*先頭データ保存
	subq.b	#1,d0			*MIDI CH(1～16)->内部コード($00～$0f)
	cmpi.b	#$0f,d0
	bls	@f
	moveq.l	#$10,d0			*範囲外はOFFとみなす
@@:
	move.b	d0,(a1)

	move.l	d4,d5
	move.l	a1,a3
	moveq.l	#0,d1
	moveq.l	#0,d3
	lea	sc88ptofs(pc),a2
ssptlp:
	add.b	(a1)+,d1
	addq.l	#1,d3
	addq.b	#1,d4		*どうせ上位は変化しないから
	move.w	d4,d0
	andi.w	#$f0ff,d0
	cmp.w	(a2),d0
	bne	@f
	bsr	send_gsptdt
	move.l	(a2)+,d0
	add.w	d0,d4
	move.l	d4,d5
	move.l	a1,a3
	moveq.l	#0,d1
	moveq.l	#0,d3
@@:
	dbra	d2,ssptlp
	tst.l	d3
	beq	@f
	bsr	send_gsptdt
@@:
	movem.l	(sp)+,d0/a1
	move.b	d0,(a1)		*書き換えた値をもとに戻す
	t_dat_ok

sc88ptofs:
*	dc.w	$1017,$0000
	dc.w	$1019,$0000
	dc.w	$1024,$0006
	dc.w	$102d,$0003
	dc.w	$1038,$0008
	dc.w	$104c,$0fb4
	dc.w	$200b,$0005
	dc.w	$201b,$0005
	dc.w	$202b,$0005
	dc.w	$203b,$0005
	dc.w	$204b,$0005
	dc.w	$205b,$1FA5
	dc.w	$4002,$001e
	dc.w	-1

sc88_drum_setup:			*SC88のドラムパラメータ設定	!v3
	*   cmd=$4c
	* < a1.l=data address
	* < d1.w=midi-out port number(0-3,-1:current)
	* < d2.l=size
	* < d3.hw=sc88 map number*256+note number
	* < d3.lw=sc88 id number(0-127,-1:current)
	* > d0.l=error code
	bsr	get_m_out_addr
	subq.w	#1,d2			*for dbra
	cmpi.l	#9-1,d2
	bhi	t_illegal_data_size
	bsr	getset_sc88_id		*ID保存／取得
	lea	header+2(pc),a2
	move.b	d3,(a2)+		*set dev ID
	move.b	#$42,(a2)+		*set model id
	move.l	#$410100,d4		*inst address
	swap	d3
	cmpi.b	#127,d3
	bhi	t_illegal_note_number
	move.b	d3,d4			*note set
	lsl.w	#4,d3
	andi.w	#$f000,d3
	or.w	d3,d4			*make address
@@:
	bsr	sc_p_set
	add.w	#$0100,d4
	addq.w	#1,a1
	dbra	d2,@b
	t_dat_ok

sc88_drum_name:
	*   cmd=$4d
	* < a1.l=data address
	* < d1.w=midi-out port number(0-2,-1:current)
	* < d2.l=size
	* < d3.hw=sc88 drum map number(0,1:PRESET/$80+0,1:USER)
	* < d3.lw=sc88 id number(0-127,-1:current)
	* > d0.l=error code
	bsr	get_m_out_addr
	tst.l	d2
	beq	t_illegal_string_length
	cmpi.l	#12,d2
	bhi	t_illegal_string_length
	bsr	getset_sc88_id		*ID保存／取得

	lea	header+2(pc),a2
	move.b	d3,(a2)+		*set dev ID
	move.b	#$42,(a2)+		*set model id
	addq.w	#1,a2
	move.b	#$41,(a2)+
	clr.w	(a2)+
	move.l	d3,d0
	swap	d0
	bclr.l	#7,d0
	bne	2f
	tst.b	d0
	beq	1f
	move.w	#$1000,-2(a2)
1:
	bsr	send_header
	bsr	trans_midi_dat		* > d3=sum
	add.b	#$10,d3			*$10=addr sum
	andi.b	#$7f,d3
	moveq.l	#$80,d0
	sub.b	d3,d0
	andi.b	#$7f,d0
	jsr	(a5)
	moveq.l	#$f7,d0
	jsr	(a5)
	t_dat_ok
2:
	move.b	#$21,-3(a2)
	tst.b	d0
	beq	1b
	move.w	#$1000,-2(a2)
	bra	1b

sc88_user_inst:				*SC88のユーザー音色パラメータ設定
	*   cmd=$4e
	* < a1.l=data address
	* < d1.w=midi-out port number(0-3,-1:current)
	* < d2.l=size
	* < d3.hw=sc88 bank number*256+program number
	* < d3.lw=sc88 id number(0-127,-1:current)
	* > d0.l=error code
	bsr	get_m_out_addr
	subq.w	#1,d2			*for dbra
	cmpi.l	#11-1,d2
	bhi	t_illegal_data_size
	bsr	getset_sc88_id		*ID保存／取得
	lea	header+2(pc),a2
	move.b	d3,(a2)+		*set dev ID
	move.b	#$42,(a2)+		*set model id
	move.l	#$200000,d4		*inst address
	swap	d3
	cmpi.b	#127,d3
	bhi	t_illegal_note_number
	move.b	d3,d4			*note set
	lsl.w	#4,d3
	andi.w	#$f000,d3
	or.w	d3,d4			*make address
@@:
	bsr	sc_p_set
	add.w	#$0100,d4
	addq.w	#1,a1
	dbra	d2,@b
	t_dat_ok

sc88_user_drum:				*SC88のユーザードラムセット・パラメータ設定
	*   cmd=$4f
	* < a1.l=data address
	* < d1.w=midi-out port number(0-3,-1:current)
	* < d2.l=size
	* < d3.hw=sc88 set number*256+note number
	* < d3.lw=sc88 id number(0-127,-1:current)
	* > d0.l=error code
	bsr	get_m_out_addr
	subq.w	#1,d2			*for dbra
	cmpi.l	#12-1,d2
	bhi	t_illegal_data_size
	bsr	getset_sc88_id		*ID保存／取得
	lea	header+2(pc),a2
	move.b	d3,(a2)+		*set dev ID
	move.b	#$42,(a2)+		*set model id
	move.l	#$210100,d4		*inst address
	swap	d3
	cmpi.b	#127,d3
	bhi	t_illegal_note_number
	move.b	d3,d4			*note set
	lsl.w	#4,d3
	andi.w	#$f000,d3
	or.w	d3,d4			*make address
@@:
	bsr	sc_p_set
	add.w	#$0100,d4
	addq.w	#1,a1
	dbra	d2,@b
	t_dat_ok

skip_peri:
	* < a0.l=filename addr
@@:
	cmpi.b	#'.',(a0)
	bne	@f
	addq.w	#1,a0
	bra	@b
@@:
	rts

clr_adpb?:
	* - all
	tst.b	adpb_clr-work(a6)
	beq	@f
	movem.l	d0/d3,-(sp)
	move.l	#ID_ZPD,d3
	jsr	free_mem2-work(a6)
	clr.b	adpb_clr-work(a6)
	movem.l	(sp)+,d0/d3
@@:
	rts

	.include	pcm_read.s

register_zpd:				*ADPCMブロックデータの取り込み
	*   cmd=$51
	* < a1.l=filename address
	* > d0.l=error code
	* > work:header_bufferにファイルのヘッダ情報が格納されている
					*拡張子が無い時は'ZPD'を自動的に付ける
	move.l	filename(pc),a2
	moveq.l	#0,d0
rgzdlp00:
	move.b	(a1)+,d1
	move.b	d1,(a2)+
	beq	rgzd0
	cmpi.b	#'\',d1			*init.
	bne	@f
	moveq.l	#0,d0
	bra	rgzdlp00
@@:
	cmpi.b	#'/',d1			*init.
	bne	@f
	moveq.l	#0,d0
	bra	rgzdlp00
@@:
	cmp.b	#'.',d1
	bne	rgzdlp00
	move.l	a1,d0			*拡張子があるならばその位置をメモ
	bra	rgzdlp00
rgzd0:					*ＰＤＸかどうか
	tst.l	d0
	beq	@f
	move.l	d0,a0
	move.b	(a0)+,d0		*拡張子が'PDX'かどうかをチェック
	bsr	mk_capital
	cmpi.b	#'P',d0
	bne	@f
	move.b	(a0)+,d0
	bsr	mk_capital
	cmpi.b	#'D',d0
	bne	@f
	move.b	(a0)+,d0
	bsr	mk_capital
	cmpi.b	#'X',d0
	beq	register_pdx
@@:
	move.l	filename(pc),a0
	lea	ZPD(pc),a1
	bsr	kakuchoshi

	bsr	read_abd		*>a2.l=read data addr.,> a3.l=last_fn
	tst.l	d0
	beq	@f
	rts				*case:error
@@:
	tst.l	d1
	beq	t_dat_ok2		*no read(case:d0=0)
	cmpi.w	#2,d1			*v2のZPDかどうか
	bhi	register_v3_zpd
	bsr	fn_to_lastfn		*ファイルネーム保存 * < a3.l=last_fn
	bra	set_adpcm_tbl_v2_
set_adpcm_tbl_v2:
	bsr	adpcm_tbl_init	*adpcm_tblの初期化
set_adpcm_tbl_v2_:
	* < a2.l=ZPD head addr.
	* x d0,d1,a2,a3,a4
abd_lp00:
	moveq.l	#0,d0
	move.w	(a2)+,d0
	move.w	d0,d3
	bpl	abd_note_case
	cmpi.w	#-1,d0
	beq	t_dat_ok	*all end
	andi.w	#$7fff,d0
	cmpi.w	#adpcm_reg_max-1,d0
	bhi	t_illegal_timbre_number
	cmp.w	adpcm_n_max2(pc),d0
	bcs	@f
	bsr	spread_adpcm_n2
	bmi	t_out_of_memory
@@:
	move.l	adpcm_tbl2(pc),a3
	bra	abd00
abd_note_case:
	cmpi.w	#adpcm_reg_max-1,d0
	bhi	t_illegal_tone_number
	cmp.w	adpcm_n_max(pc),d0
	bcs	@f
	bsr	spread_adpcm_n
	bmi	t_out_of_memory
@@:
	move.l	adpcm_tbl(pc),a3
abd00:
	lsl.l	#adpcm_tbl_size_,d0		*adpcm_tbl_size倍
	add.l	d0,a3		*ワークアドレス
	andi.w	#$7f,d3
	swap	d3
	clr.w	d3		*$00_nn_0000
	move.l	d3,(a3)+	*dummy attributes(初めは先頭を00にしておく)
	move.l	(a2)+,d1	*data address offset
	lea	(a2,d1.l),a4
	move.l	a4,(a3)+	*address
	move.l	(a2)+,d3
	move.l	d3,(a3)+	*size
	clr.l	(a3)+		*loop start
	subq.l	#1,d3		*point last data addr.
	move.l	d3,(a3)+	*loop end
	move.l	#1,(a3)+	*ループ１回
	clr.l	(a3)+		*reserved
	clr.l	(a3)+		*reserved
	clr.b	(a3)		*名前無し
	st.b	-32(a3)		*先頭バイトも$ffにしてデータを有効状態にする
	bra	abd_lp00

read_abd:
	* > d1.l=file type(0:no read, 2:v2.zpd, 3:v3.zpd)
	* > d4.l=true data size
	* > d6.l=date 
	* > a2.l=data addr.(=a0.l)
	* > a3.l=zpd_last_fn
	* > d0.l=0 no error
	* x d0,d1,d2,d3,d5,a0,a1,a3
	move.l	filename(pc),a2
	bsr	fopen		*(ret:d5=file handle)
	tst.l	d5		*d5=file_handle
	bmi	t_file_not_found	*read error

	lea	zpd_last_fn(pc),a3
	bsr	fname_chk
	bne	@f
	bsr	do_fclose
	clr.b	adpb_clr-work(a6)
	moveq.l	#0,d1
	moveq.l	#0,d0		*no error
	rts			*同じものは読まない
@@:
 	bsr	get_fsize	*>d3.l=file size
	bmi	t_illegal_file_size
	subq.l	#8,d3		*header分減じる
	move.l	d3,d2		*d2=total data size(get mem時に使用)
	move.l	d2,d4		*データ読み込み時に使用

	lea	header_buffer(pc),a0
	move.w	sr,-(sp)
	andi.w	#$f8ff,sr
	move.l	#8,-(sp)	*push size(header size)
	move.l	a0,-(sp)	*push addr
	move.w	d5,-(sp)	*file handle
	DOS	_READ		*サンプリングデータの読み込み
	lea	10(sp),sp
	move.w	(sp)+,sr
	cmp.l	#8,d0
	bne	t_read_error

	cmpi.l	#ZPDV2_0,(a0)		*HEADER check(v2 zpd) $10,'ZmA'
	beq	@f			*zmusicには無縁のデータです
	cmpi.l	#ZPDV3_0,(a0)		*HEADER check(v3 zpd)
	bne	t_unidentified_file	*ID error
	cmpi.l	#ZPDV3_1,4(a0)		*ZmaDPcM
	bne	t_unidentified_file	*ID error
	moveq.l	#3,d1			*v3
	bra	ra_00
@@:
	cmpi.l	#ZPDV2_1,4(a0)	*$10,'ZmAdpCm' CASE
	bne	t_unidentified_file	*ID error
	moveq.l	#2,d1			*v2
ra_00:
	bsr	clr_adpb?
	move.l	#ID_ZPD,d3
	bsr	get_mem		*>a0.l=address,d2.l=lw border length
	tst.l	d0
	bmi	t_out_of_memory
	move.l	a0,a2
	clr.b	zpd_last_fn+30-work(a6)	*ファイル名バッファ除去
*	tst.b	adpb_clr-work(a6)
*	bne	@f
*	bsr	adpcm_tbl_init		*adpcm_tblの初期化
*@@:
	move.w	sr,-(sp)
	andi.w	#$f8ff,sr
	move.l	d4,-(sp)	*push size
	move.l	a2,-(sp)	*push addr
	move.w	d5,-(sp)	*file handle
	DOS	_READ		*サンプリングデータの読み込み
	lea	10(sp),sp
	move.w	(sp)+,sr
	cmp.l	d0,d4
	bne	t_read_error

	bsr	do_fclose
	move.l	a2,a0		*return value
	moveq.l	#0,d0		*no error
	rts

register_v3_zpd:			*ADPCMブロックデータの取り込み	*v3専用
	bsr	fn_to_lastfn		*ファイルネーム保存 * < a3.l=last_fn
	bra	set_adpcm_tbl_v3_
set_adpcm_tbl_v3:
	bsr	adpcm_tbl_init	*adpcm_tblの初期化
set_adpcm_tbl_v3_:
	* < a2.l=ZPD head addr.
	* d0,d1,a2,a3,a4
	addq.w	#4,a2		*skip dummy
	move.l	(a2)+,d2
	beq	t_dat_ok	*all end
abd_lp00_2:
	moveq.l	#0,d0
	move.w	(a2)+,d0
	bpl	abd_note_case_2
	andi.w	#$7fff,d0
	cmpi.w	#adpcm_reg_max-1,d0
	bhi	t_illegal_timbre_number
	cmp.w	adpcm_n_max2(pc),d0
	bcs	@f
	bsr	spread_adpcm_n2
	bmi	t_out_of_memory
@@:
	move.l	adpcm_tbl2(pc),a3
	bra	abd00_2
abd_note_case_2:
	cmpi.w	#adpcm_reg_max-1,d0
	bhi	t_illegal_tone_number
	cmp.w	adpcm_n_max(pc),d0
	bcs	@f
	bsr	spread_adpcm_n
	bmi	t_out_of_memory
@@:
	move.l	adpcm_tbl(pc),a3
abd00_2:
	lsl.l	#adpcm_tbl_size_,d0		*adpcm_tbl_size倍
	add.l	d0,a3		*ワークアドレス
	move.l	(a2)+,d0	*get attributes
	pea	(a3)
	clr.l	(a3)+		*とりあえずエリア無効にしておく
	move.l	(a2)+,d1
	lea	(a2,d1.l),a4
	move.l	a4,(a3)+	*address
	move.l	(a2)+,(a3)+	*size
	move.l	(a2)+,(a3)+	*loop start
	move.l	(a2)+,(a3)+	*loop end
	move.l	(a2)+,(a3)+	*loop time
	move.l	(a2)+,(a3)+	*reserved
	move.l	(a2)+,(a3)+	*reserved
	moveq.l	#adt_name_len-1,d1
@@:
	move.b	(a2)+,(a3)+	*tone name
	dbeq	d1,@b

	move.l	a2,d1		*even a2
	addq.l	#1,d1
	bclr.l	#0,d1
	move.l	d1,a2

	move.l	(sp)+,a3
	move.l	d0,(a3)		*アトリビュート設定

	subq.l	#1,d2
	bne	abd_lp00_2
	t_dat_ok

register_pdx:				*PDXの取り込み
	bsr	read_abd		*>a2.l=read data addr.,> a3.l=last_fn
	tst.l	d0
	beq	@f
	rts				*case:error
@@:
	tst.l	d1
	beq	t_dat_ok2		*no read(case:d0=0)
	cmpi.w	#2,d1			*v2のZPDかどうか
	bhi	register_v3_zpd
	bsr	fn_to_lastfn		*ファイルネーム保存 * < a3.l=last_fn
	bra	set_adpcm_tbl_pdx_
set_adpcm_tbl_pdx:
	bsr	adpcm_tbl_init		*adpcm_tblの初期化
set_adpcm_tbl_pdx_:
	* < a2.l=PDX head addr.
	move.w	adpcm_n_max(pc),d0	*96+16=112
	cmpi.w	#112,d0
	bcc	@f
	bsr	spread_adpcm_n
	bmi	t_out_of_memory
@@:
	move.l	a2,a1
	move.l	#15*adpcm_tbl_size,d0	*pdxはo0d+からだから15はそのオフセット
	moveq.l	#96-1,d2
	move.l	#15*65536,d5		*$00_nn_0000
pdx_lp00:
	move.l	(a1)+,d1	*offset for data
	beq	next_pdx
	move.l	adpcm_tbl(pc),a3
	add.l	d0,a3		*ワークアドレス
	move.l	d5,(a3)+	*dummy attributes(初めは先頭を00にしておく)
	lea	(a2,d1.l),a4
	move.l	a4,(a3)+	*address
	move.l	(a1)+,d3
	move.l	d3,(a3)+	*size
	clr.l	(a3)+		*loop start
	subq.l	#1,d3		*point last data addr.
	move.l	d3,(a3)+	*loop end
	move.l	#1,(a3)+	*ループ１回
	clr.l	(a3)+
	clr.l	(a3)+
	clr.b	(a3)		*名前無し
	st.b	-32(a3)		*先頭バイトも$ffにしてデータを有効状態にする
next_pdx:
	add.l	#$0001_0000,d5
	add.l	#adpcm_tbl_size,d0
	dbra	d2,pdx_lp00
	t_dat_ok

set_zpd_table:			*ＺＰＤデータのテーブルセット	!v3
	*   cmd=$52
	* < d1.l=version type(0:V1～2,1:V3,2:PDX)
	* < a1.l=data address (ヘッダの次から)
	* > d0.l=error code
	movea.l	a1,a2
set_zpd_tbl_:
	clr.b	zpd_last_fn+30-work(a6)
	subq.w	#1,d1
	bmi	set_adpcm_tbl_v2_	*v2 case
	beq	set_adpcm_tbl_v3_	*v3 case
	subq.w	#1,d1
	beq	set_adpcm_tbl_pdx_
	bra	t_unidentified_file

clr_wvmm?:			*波形メモリバッファの管理
	* - all
	tst.b	wvmm_clr-work(a6)
	beq	@f
	movem.l	d0/d3,-(sp)
	move.l	#ID_WAVE,d3
	jsr	free_mem2-work(a6)
*	bsr	wave_tbl_init
	clr.b	wvmm_clr-work(a6)
	movem.l	(sp)+,d0/d3
@@:
	rts

spread_wave_n:				*波形メモリ管理テーブル
reglist	reg	d0-d4/a0-a1
	* < d1.w=0～32767-8
	* - all
	movem.l	reglist,-(sp)
	ext.l	d1
	addq.l	#8,d1			*上限拡張
	cmpi.l	#wv_reg_max,d1
	bls	@f
	move.l	#wv_reg_max,d1
@@:
	move.l	d1,d4			*new n-max
	lsl.l	#wv_tbl_size_,d1
	move.l	d1,d2			*require size
	moveq.l	#0,d3
	move.w	wave_n_max(pc),d3
	bne	enlrg_wvtb
	move.l	#ID_WAVE_TBL,d3		*ID
	bsr	get_mem
	tst.l	d0
	bmi	err_exit_spadt
	move.l	a0,wave_tbl-work(a6)
	move.w	d4,wave_n_max-work(a6)
	bsr	wave_tbl_init
	moveq.l	#0,d0			*no error
	movem.l	(sp)+,reglist
	rts
enlrg_wvtb:
	move.l	wave_tbl(pc),a1		*enlarge or get?(adpcm_tbl)
	bsr	enlarge_mem
	tst.l	d0
	bmi	err_exit_spwvt
	move.l	a0,wave_tbl-work(a6)
	move.w	d4,wave_n_max-work(a6)
	sub.w	d3,d4
	lsl.l	#wv_tbl_size_,d3
	add.l	d3,a0
	subq.w	#1,d4			*for dbra
@@:
	bsr	do_init_wvtbl
	dbra	d4,@b
	moveq.l	#0,d0
	movem.l	(sp)+,reglist
	rts
err_exit_spwvt:				*メモリ不足エラー
	moveq.l	#-1,d0
	movem.l	(sp)+,reglist
	rts

convert_pcm:			*PCMデータの変換
	*   cmd=$53
	* < d1.l=mode(0:adpcm to pcm,1:pcm to adpcm)
	* < d2.l=size(変換元のデータサイズ)
	* < a1.l=src data address
	* < a2.l=dest data address
	* > none
	move.l	d2,d0			*size
	tst.l	d1			*check mode
	beq	@f
	move.l	a2,a0			*a0=dest:adpcm buffer
	bra	pcm_to_adpcm		*a1=src:pcm buffer
@@:
	move.l	a1,a0			*a0=src:adpcm buffer
	move.l	a2,a1			*a1=dest:pcm buffer
	bra	just_adpcm_to_pcm

exec_subfile:			*サブファイルの読み込みと実行
	*   cmd=$54
	* < a1=filename文字列(endcode=0)
	* > d0.l=error code
	move.l	a1,a2		*a2=filename文字列
	lea	CNF(pc),a1	*拡張子
*	lea	cnf_last_fn(pc),a3
*	clr.b	(a3)		*ファンクションで呼ばれた場合はキャッシュ処理なし
	lea	exec_comn_cmd(pc),a5
exec_subfile0:
	bsr	read_subfile	*>a1 address, d3 size
	tst.l	d0
	beq	do_exec_subfile
	rts			*読み込み失敗
do_exec_subfile:
	* < a1.l=address
	* < d3.l=size
	* - a1-a2
reglist	reg	a1-a2
	movem.l	reglist,-(sp)
					*コンパイルデータの実行(ここを変えたらexec_cmpも変える)
	cmpi.l	#ZmuSiC0,(a1)		*$10,'Zmu'
	bne	isitzpd?
	cmpi.l	#ZmuSiC1+v_code,4(a1)	*'Sic',version(.b)
	bne	go_subcnv
	lea	8(a1),a2		*address(header分足す)
	jsr	(a5)
exit_cmnrdcnf:				*メモリを解放して終了
	movem.l	(sp)+,reglist
	bra	free_mem

isitzpd?:				*ZPDのケースか(V2)
	cmpi.l	#ZPDV2_0,(a1)		*$10,'ZmA'
	bne	isitv3zpd?
	cmpi.l	#ZPDV2_1,4(a1)	*'dpCm'
	bne	go_subcnv

	lea	8(a1),a2		*addr
	move.l	d3,d2			*size
	subq.l	#8,d2			*headerの長さ分差し引く
	ble	exit_cmnrdcnf		*minus or zero
	clr.b	zpd_last_fn+30-work(a6)	*ファイルネームキャッシュ無効化
	clr.b	adpb_clr-work(a6)	*初期化不要
	bsr	set_adpcm_tbl_v2	*ブロックデータのインフォメーションをワークにセット
exit_isitzpd:
	movem.l	(sp)+,reglist
	move.l	#0,d1			*no check
	move.l	#ID_ZPD,d3
	bra	exchange_memid

isitv3zpd?:				*ZPDのケースか(V3)
	cmpi.l	#ZPDV3_0,(a1)		*$10,'Zma'
	bne	isitsmf?
	cmpi.l	#ZPDV3_1,4(a1)		*'DPcM'
	bne	match_err

	lea	8(a1),a2		*addr
	move.l	d3,d2			*size
	subq.l	#8,d2			*headerの長さ分差し引く
	ble	exit_cmnrdcnf		*minus or zero
	clr.b	zpd_last_fn+30-work(a6)	*ファイルネームキャッシュ無効化
	clr.b	adpb_clr-work(a6)	*初期化不要
	bsr	set_adpcm_tbl_v3	*ブロックデータのインフォメーションをワークにセット
	bra	exit_isitzpd

isitsmf?:				*バイナリMIDIダンプデータ(MID)送信
	cmpi.l	#SMFHED,(a1)		*'MThd'
	bne	go_subcnv
*	clr.b	mbd_last_fn-work(a6)	*ファイルネームキャッシュ無効化
	move.l	d3,d2
	bsr	midi_transmission
	bra	exit_cmnrdcnf

go_subcnv:
	* < a1.l=address
	* < d3.l=size
	move.l	compiler_j(pc),a0		*compilerファンクションが有効か(d0=fnc addr)
	move.l	a0,d0
	beq	gs_t_cannot_compile
	move.l	#1,d1			*no header,no err list,errmax=1
	move.l	d3,d2			*size
					*< a1=addr,d2=size
	movem.l	d1-d7/a1-a6,-(sp)
	jsr	(a0)			*go compiler fnc
	movem.l	(sp)+,d1-d7/a1-a6
	tst.l	d0			*> d0=error, a0=error tbl addr(if required)
	bne	gs_t_compile_error	*コンパイル失敗
	move.l	a0,-(sp)
	move.l	a0,a2			*a0=OBJ addr(case:no error)
	lea	z_comn_offset(a2),a2
	move.l	(a2)+,d0
	beq	@f
	add.l	d0,a2
	jsr	(a5)			*共通コマンド実行 < a2.l=zmd addr.
@@:
	move.l	(sp)+,a1
	bsr	free_mem		*オブジェクト領域を解放
	movem.l	(sp)+,reglist
	bra	free_mem		*読み込んだｿｰｽを破棄して終了
gs_t_cannot_compile:
	movem.l	(sp)+,reglist
	bra	t_compiler_not_available
gs_t_compile_error:
	movem.l	(sp)+,reglist
	bra	t_compile_error

read_subfile:			*サブファイル読み込み
	* < a1.l=拡張子
	* < a2.l=filename
	* < a3.l=last fn buffer
	* > d0.l=0 no error
	* > a1.l=data address
	* > d3.l=size
	* > a2=next
	move.l	filename(pc),a0
@@:
	move.b	(a2)+,(a0)+
	bne	@b
	move.l	a2,-(sp)
	move.l	filename(pc),a0
	bsr	kakuchoshi

	move.l	filename(pc),a2
	bsr	fopen		*環境変数対応
	tst.l	d5		*d5=file_handle
	bmi	rs_t_file_not_found

*	bsr	fname_chk	* < a3.l=last_fn
*	bne	@f
*	bsr	do_fclose
*	bra	exit_rdsb
*@@:
	bsr	get_fsize	*>d3.l=file size
	bmi	rs_t_illegal_file_size

	move.l	d3,d2
	bsr	get_temp_buf	*>a1.l=data address(d2サイズ分使い捨てバッファを確保)
	bmi	rs_t_out_of_memory
	bsr	so_read
*	bsr	fn_to_lastfn	* < a3.l=last_fn
exit_rdsb:
	move.l	(sp)+,a2
	moveq.l	#0,d0		*ok
	rts

rs_t_file_not_found:
	move.l	(sp)+,a2
	bra	t_file_not_found

rs_t_illegal_file_size:
	move.l	(sp)+,a2
	bra	t_illegal_file_size

rs_t_out_of_memory:
	move.l	(sp)+,a2
	bra	t_out_of_memory

fn_to_lastfn:			*読み込んだファイルの情報保存
	* < a3.l=last fn addr
	* - all
	movem.l	d0/a1/a3,-(sp)
	lea.l	file_info_buf(pc),a1
	moveq.l	#53-1,d0
@@:
	move.b	(a1)+,(a3)+
	dbra	d0,@b
	movem.l	(sp)+,d0/a1/a3
	rts

so_read:
	* < d3.l=size
	* < a1.l=address
	* < d5.l=file handle
	* - all except d0
	move.w	sr,-(sp)
	andi.w	#$f8ff,sr
	move.l	d3,-(sp)	*push size
	move.l	a1,-(sp)	*push addr
	move.w	d5,-(sp)	*file handle
	DOS	_READ		*サンプリングデータの読み込み
	lea	10(sp),sp
	move.w	(sp)+,sr
	bra	do_fclose

transmit_midi_dump:			*MIDIダンプファイルの転送
	*   cmd=$55
	* < d1.w=midi port number(0～2),-1はカレント
	* < a1.l=filename文字列(endcode=0)
	* > d0.l=error code
	move.l	a1,a2
transmit_midi_dump0:			*< a2.l=filename
	bsr	current_midi_out	*一時的に設定する
	move.w	d0,-(sp)
	lea	MDD(pc),a1		*拡張子
*	lea	mbd_last_fn(pc),a3
	bsr	read_subfile		*>a1 address, d3 size*
	tst.l	d0
	bne	t_read_error
	move.l	d3,d2
	cmpi.l	#SMFHED,(a1)
	beq	@f
	cmpi.b	#$1a,-1(a1,d3.l)
	bne	t_unidentified_file	*endcodeがない
	moveq.l	#0,d2			*dummy size
@@:
	bsr	midi_transmission
	move.w	(sp)+,d1		*元に戻す
	bsr	current_midi_out
	bra	free_mem		*使い捨て領域解放&帰還

set_wave_form1:					*波形データ登録(データ転送有り)
	*   cmd=$56				*v3済み
	* < a1.l=data address
	* < d1.w=wave number
	* < 0(a1).l=data size
	* < 4(a1).b=loop type
	* < 5(a1).l=loop start offset
	* < 9(a1).l=loop end offset
	* < 13(a1).l=loop time(0=∞)
	* < 17(a1).l reserved area
	* < 21(a1).b name len 
	* < 22(a1)～ name
	* < 22+name len(a1)～ data(ただし偶数アドレスから始まっている)
	* > d0.l=0 no error
	bsr	clr_wvmm?			*波形メモリバッファの管理
	ext.l	d1
	subq.w	#wv_def_max,d1
	cmpi.l	#wv_reg_max-1,d1
	bhi	t_illegal_wave_number
	cmp.w	wave_n_max(pc),d1
	bcs	@f
	bsr	spread_wave_n
	bmi	t_out_of_memory
@@:
	lsl.l	#wv_tbl_size_,d1
	move.l	wave_tbl(pc),a4
	adda.w	d1,a4				*管理テーブルのアドレス

	move.l	a1,a5
	move.l	(a1),d2				*size
	moveq.l	#0,d4
	move.b	21(a1),d4			*str len
	add.l	d4,d2				*文字列サイズ
	move.l	wave_memory_top(pc),d0
	bne	enlarge_wvmm
	move.l	#ID_WAVE,d3
	bsr	get_mem				*a0.l=address,d2.l=long word border size
	tst.l	d0
	bmi	t_out_of_memory
	move.l	a0,wave_memory_top-work(a6)
	move.l	d2,wave_memory_size-work(a6)
	lea	(a0,d2.l),a1
	move.l	a1,wave_memory_end-work(a6)
	bra	swf1_00
enlarge_wvmm:
	move.l	d0,a1
	add.l	wave_memory_size(pc),d2
	bsr	enlarge_mem
	tst.l	d0
	bmi	t_out_of_memory
	movem.l	d0-d3/a1,-(sp)			*テーブルの辻褄会わせ
	move.w	wave_n_max(pc),d0
	subq.w	#1,d0				*for dbra
	bcs	exit_enlgwvm
	move.l	wave_tbl(pc),a1
	move.l	a0,d2
	move.l	wave_memory_top(pc),d1
	move.l	d1,d3
	sub.l	d1,d2				*新領域までのオフセット
	add.l	wave_memory_size(pc),d1		*旧領域の最終アドレス
enlgwvmlp00:
	cmp.l	wave_start_addr(a1),d3
	bhi	@f
	cmp.l	wave_start_addr(a1),d1
	bcs	@f
	add.l	d2,wave_start_addr(a1)
	add.l	d2,wave_end_addr(a1)
	add.l	d2,wave_loop_start(a1)
	add.l	d2,wave_loop_end(a1)
	add.l	d2,wave_name_addr(a1)
@@:
	lea	wv_tbl_size(a1),a1
	dbra	d0,enlgwvmlp00
exit_enlgwvm:
	movem.l	(sp)+,d0-d3/a1
	move.l	a0,wave_memory_top-work(a6)
	move.l	d2,wave_memory_size-work(a6)
	lea	(a0,d2.l),a1
	move.l	wave_memory_end(pc),a0
	move.l	a1,wave_memory_end-work(a6)
swf1_00:
	move.l	d4,d0			*< d4.l=文字長
	move.l	a0,a1			*a1=もらった領域の先頭アドレス(文字列が格納される)
	add.l	a0,d0
	addq.l	#1,d0
	bclr.l	#0,d0			*.even
	move.l	d0,a0			*a0=波形が格納されるアドレス
	move.l	a0,(a4)+		*data address	p_wvXm_point
	move.b	(a5)+,d0		*get size H
	lsl.w	#8,d0
	move.b	(a5)+,d0
	swap	d0
	move.b	(a5)+,d0		*get size L
	lsl.w	#8,d0
	move.b	(a5)+,d0
	add.l	a0,d0
	move.l	d0,(a4)+		*end address+2	p_wvXm_end
	addq.w	#1,a4			*reserved
	move.b	(a5)+,d0
	subq.b	#1,d0			*0-2→-1,0,+1
	move.b	d0,(a4)+		*loop type	p_wvXm_lpmd
	move.b	(a5)+,d0		*get loop start H
	lsl.w	#8,d0
	move.b	(a5)+,d0
	swap	d0
	move.b	(a5)+,d0		*get loop start L
	lsl.w	#8,d0
	move.b	(a5)+,d0
	add.l	a0,d0
	move.l	d0,(a4)+		*set loop start address	p_wvXm_lpst
	move.b	(a5)+,d0		*get loop end H
	lsl.w	#8,d0
	move.b	(a5)+,d0
	swap	d0
	move.b	(a5)+,d0		*get loop end L
	lsl.w	#8,d0
	move.b	(a5)+,d0
	add.l	a0,d0
	move.l	d0,(a4)+		*loop end address	p_wvXm_lped
	rept	4
	move.b	(a5)+,(a4)+		*loop time		p_wvXm_lptm
	endm
	addq.w	#4,a5			*reserved area
	add.w	#5,a4			*reserved area
	move.b	(a5)+,(a4)+		*str len
	move.l	a1,(a4)+		*str addr
	subq.w	#1,d2
	bcs	cp_data_wvst		*文字なしの場合はスキップ
@@:					*文字列コピー
	move.b	(a5)+,(a1)+
	dbra	d2,@b
cp_data_wvst:
	move.l	d5,d0
	addq.l	#1,d0
	bclr.l	#0,d0			*.even
	move.l	d0,a5
@@:
	move.w	(a5)+,(a0)+			*データ部転送
	subq.w	#2,d2
	bne	@b
	move.l	a5,a0				*next addr(return value)
	t_dat_ok

set_wave_form2:					*波形データ登録(データ転送なし)
	*   cmd=$57				*v3済み
	* < a1.l=data address
	* < d1.w=wave number
	* < 0(a1).l=data size
	* < 4(a1).b=loop type
	* < 5(a1).l=loop start offset
	* < 9(a1).l=loop end offset
	* < 13(a1).l=loop time(0=∞)
	* < 17(a1).l reserved area
	* < 21(a1).b name len 
	* < 22(a1)～ name
	* < 22+name len(a1)～ data(ただし偶数アドレスから始まっている)
	* > d0.l=0 no error
	* > a0.l next addr
	bsr	clr_wvmm?		*波形メモリバッファの管理
	ext.l	d1
	subq.w	#wv_def_max,d1
	cmpi.l	#wv_reg_max-1,d1
	bhi	t_illegal_wave_number
	cmp.w	wave_n_max(pc),d1
	bcs	@f
	bsr	spread_wave_n
	bmi	t_out_of_memory
@@:
	lsl.l	#wv_tbl_size_,d1
	move.l	wave_tbl(pc),a4
	add.l	d1,a4
	lea	22(a1),a0		*a0=文字列格納アドレス
	moveq.l	#0,d0
	move.b	21(a1),d0		*d0.l=string len
	lea	22(a1,d0.w),a2
	move.l	a2,d0
	addq.l	#1,d0
	bclr.l	#0,d0			*.even
	move.l	d0,a2			*a2=波形データ格納アドレス

	move.l	a2,(a4)+		*data addr	p_wvXm_point
	move.b	(a1)+,d0		*get size H
	lsl.w	#8,d0
	move.b	(a1)+,d0
	swap	d0
	move.b	(a1)+,d0		*get size L
	lsl.w	#8,d0
	move.b	(a1)+,d0
	add.l	a2,d0
	move.l	d0,-(sp)
	move.l	d0,(a4)+		*end addr	p_wvXm_end
	addq.w	#1,a4			*reserved
	move.b	(a1)+,d0
	subq.b	#1,d0			*0-2→-1,0,+1
	move.b	d0,(a4)+		*type		p_wvXm_lpmd
	move.b	(a1)+,d0		*get loop start H
	lsl.w	#8,d0
	move.b	(a1)+,d0
	swap	d0
	move.b	(a1)+,d0		*get loop start L
	lsl.w	#8,d0
	move.b	(a1)+,d0
	add.l	a2,d0
	move.l	d0,(a4)+		*loop start offset	p_wvXm_lpst
	move.b	(a1)+,d0		*get loop end H
	lsl.w	#8,d0
	move.b	(a1)+,d0
	swap	d0
	move.b	(a1)+,d0		*get loop end L
	lsl.w	#8,d0
	move.b	(a1)+,d0
	add.l	a2,d0
	move.l	d0,(a4)+		*loop end offset	p_wvXm_lped
	rept	4
	move.b	(a1)+,(a4)+		*loop time		p_wvXm_lptm
	endm
	addq.w	#4,a1			*reserved area
	add.w	#5,a4			*reserved area
	move.b	(a1)+,(a4)+		*str len
	move.l	a0,(a4)+		*str addr
	move.l	(sp)+,a0		*next addr (return value)
	t_dat_ok

obtain_events:			*各種イベントの取得
	*   cmd=$58
	* < a1.l=destination address table
	* < d1.w=omit flag (d0:m_play,d1:m_stop,d2:m_cont...
	*			bit:1=do parameter set	bit:0=omit parameter setting)
	*   00(a1).l	0:m_play(0:off)
	*   04(a1).l	1:m_stop(0:off)
	*   08(a1).l	2:m_cont(0:off)
	*   0c(a1).l	3:Jump after if performance comes to an end.(0:off)
	*   10(a1).l	4:Loop time value(0:off/1-256)上位16ビットは0に初期化しておくこと
	*   14(a1).l	5:Jump after n times loop
	*   18(a1).l	6:Clock value(0:off)
	*   1c(a1).l	7:Jump after n clocks
	* > a0.l=イベントテーブルアドレス
	*
	* < a1.l=-1 ask mode
	* > a0.l=イベントテーブルアドレス
	ori.w	#$700,sr
	cmp.l	#-1,a1
	beq	obtevt_ask
	lea	obtevtjtbl(pc),a2
	moveq.l	#obtevtjtblsize/4-1,d0
obtevtlp:					*パラメータ転送
	lsr.w	#1,d1
	bcc	@f
	move.l	(a1)+,(a2)
@@:
	addq.w	#4,a2
	tst.w	d1
	beq	@f				*まだ設定するモノがあるか
	dbra	d0,obtevtlp
@@:
	move.w	trk_n_max(pc),d0
	beq	skip_clr_dnbt
	lsr.w	#5,d0				*/32
	move.l	done_bit(pc),a0
@@:
	clr.l	(a0)+
	dbra	d0,@b
skip_clr_dnbt:
	tst.l	obtevtjtbl-work+nc_clock(a6)
	beq	@f
	clr.l	zmusic_int-work(a6)		*ｸﾛｯｸｼﾞｬﾝﾌﾟ指定なので関連ワーク初期化
	patch_l	BSR,inc_zmint,check_nc_clock
	bra	1f
@@:
	move.l	zi_inst(pc),inc_zmint-work(a6)
1:
	bsr	cache_flush
obtevt_ask:
	lea	obtevtjtbl(pc),a0
	rts

mp_jump:	equ	0	*.l
ms_jump:	equ	4	*.l
mc_jump:	equ	8	*.l
ed_jump:	equ	12	*.l
lp_work:	equ	16	*規定回数ループしたトラックの数(.w)
lp_loop:	equ	18	*指定ループ回数(.w)チェックには下位バイトのみ使用する
lp_jump:	equ	20	*.l
nc_clock:	equ	24	*.l
nc_jump:	equ	28	*.l
obtevtjtblsize:	equ	32
obtevtjtbl:	ds.b	obtevtjtblsize
zi_inst:	ds.l	1

loop_control:			*演奏トラック全体のループ回数を得る
	*   cmd=$59
	* < d1.l=control mode(-1:ask loop time,0:normal loop mode,1:ignore loop)
	* > d0.l=loop time(-1:error)
	tst.l	d1
	beq	lpctrl00
	bpl	lpctrl01
get_lptm:
	move.l	play_trk_tbl(pc),a0
	moveq.l	#-1,d0
	moveq.l	#0,d1
glt_lp:
	moveq.l	#0,d3
	move.w	(a0)+,d3
	cmpi.w	#-1,d3
	beq	exit_glt
	calc_wk	d3
*	tst.b	p_track_stat(a5)
*	bne	glt_lp
	moveq.l	#0,d3
	move.b	p_do_loop_flag(a5),d3
	tst.b	d1
	beq	@f
	cmp.b	d0,d3
	bcc	glt_lp
@@:
	move.l	d3,d0
	st.b	d1
	bra	glt_lp
exit_glt:
	tst.l	d0
	bne	@f
	moveq.l	#1,d0
@@:
	rts

lpctrl00:		*ループモードを通常へ
	bclr.b	#7,perform_flg-work(a6)
	bra	get_lptm

lpctrl01:		*ループモードを｢ループ禁止｣モードへ
	tas.b	perform_flg-work(a6)
	bra	get_lptm

mask_tracks:				*v3
	*   cmd=$5a
	* < a1.l=parameter table
	* < 	 param. sequence
	*		{track number(.w),mask mode(.w),...,-1.w}
	*		track number:(0-65534)(.w)
	*		mask mode 0.w:enable
	*			  1.w:reverse
	*			 -1.w:disable
	*		end code:-1.w
	* < a1.l=0		all tracks
	* < d1.w=0		enable
	* < d1.w=+1		reverse
	* < d1.w=-1		mask
	*
	* < a1.l=1		SOLO mode
	* < d1.w=0-65534	track numbers
	*
	* > (a0)		設定できなかったトラック番号の並び
	*			-1=end code
	* > next addr(case:< a1.l<>0)
	move.l	mask_track_result(pc),a0
	move.w	#-1,(a0)
	ori.w	#$700,sr		*割り込み禁止
	move.l	a1,d0
	beq	msktr_all_tr		*全トラックへの操作
	subq.l	#1,d0
	beq	solo_tr			*ソロ
trmsklp00:
	move.w	(a1)+,d0		*tr=0-65534
	cmpi.w	#-1,d0
	beq	t_dat_ok
	* < d0=track number(0-65534)
	* eq:no error
	* mi:error	-2(a1) will be updated.
	* x d1,a2
	move.l	play_trk_tbl(pc),a2
@@:
	moveq.l	#0,d1
	move.w	(a2)+,d1
	cmpi.w	#-1,d1
	beq	err_msktr
	cmp.w	d1,d0
	bne	@b
	calc_wk	d1
	move.w	(a1)+,d2
	beq	msktr_enable		*マスク解除
	bmi	msktr_mask		*マスク設定
					*マスク反転のケース
	not.b	p_mask_mode(a5)
	beq	1f
	bra	@f
msktr_mask:				*マスク設定
	st.b	p_mask_mode(a5)
@@:
	move.l	p_type(a5),d4
	bsr	_ms_key_off
	bra	trmsklp00
msktr_enable:				*マスク解除
	clr.b	p_mask_mode(a5)
1:
	tst.w	p_type(a5)
	bne	trmsklp00
	move.w	p_ch(a5),d4		*FMのみ音色再設定処理
	bsr	restore_af
	bra	trmsklp00
err_msktr:				*エラー
	move.w	d0,(a0)+
	move.w	#-1,(a0)
	addq.w	#2,a1			*skip mode
	bra	trmsklp00

msktr_all_tr:				*全トラック操作
	move.l	play_trk_tbl(pc),a1
	tst.w	d1
	beq	msktr_all_enable
	bmi	msktr_all_mask
*msktr_all_reverse:			*全トラックマスク反転
@@:
	moveq.l	#0,d0
	move.w	(a1)+,d0
	cmpi.w	#-1,d0
	beq	t_dat_ok
	calc_wk	d0
	not.b	p_mask_mode(a5)
	beq	1f
	move.l	p_type(a5),d4
	bsr	_ms_key_off
	bra	@b
1:
	tst.w	p_type(a5)
	bne	@b
	move.w	p_ch(a5),d4		*FMのみ音色再設定処理
	bsr	restore_af
	bra	@b

msktr_all_enable:			*全トラックマスク解除
@@:
	moveq.l	#0,d0
	move.w	(a1)+,d0
	cmpi.w	#-1,d0
	beq	t_dat_ok
	calc_wk	d0
	clr.b	p_mask_mode(a5)
	tst.w	p_type(a5)
	bne	@b
	move.w	p_ch(a5),d4		*FMのみ音色再設定処理
	bsr	restore_af
	bra	@b

msktr_all_mask:				*全トラックマスク設定
@@:
	moveq.l	#0,d0
	move.w	(a1)+,d0
	cmpi.w	#-1,d0
	beq	t_dat_ok
	calc_wk	d0
	st.b	p_mask_mode(a5)
	move.l	p_type(a5),d4
	bsr	_ms_key_off
	bra	@b

solo_tr:				*全トラック操作
	move.l	play_trk_tbl(pc),a1
@@:
	moveq.l	#0,d0
	move.w	(a1)+,d0
	cmpi.w	#-1,d0
	beq	t_dat_ok
	cmp.w	d0,d1
	beq	solo_en_tr
	calc_wk	d0
	st.b	p_mask_mode(a5)
	move.l	p_type(a5),d4
	bsr	_ms_key_off
	bra	@b
solo_en_tr:				*全トラックマスク解除
	clr.b	p_mask_mode(a5)
	tst.w	p_type(a5)
	bne	@b
	move.w	p_ch(a5),d4		*FMのみ音色再設定処理
	bsr	restore_af
	bra	@b

mask_channels:				*v3
	*   cmd=$5b
	* < a1.l=parameter table
	* < 	param. sequence
	*		{device type(.w),ch number(.w),mask mode(.w)...,-1(.l)}
	*		device type:0,1,$8000-$8002
	*		ch number  :0-15
	*		mask mode	 0.w:enable
	*				-1.w:disable
	*		endcode=-1.l
	* < a1.l=0	all ch
	* < d1.w=0	enable
	* < d1.w=+1	reverse
	* < d1.w=-1	mask
	*
	* < a1.l=1	SOLO mode
	* < d1.l	type,ch
	*
	* > (a0)	設定できなかったチャンネル番号の並び
	*		-1.l=end code
	move.l	mask_channel_result(pc),a0
	move.w	#-1,(a0)
	ori.w	#$700,sr		*割り込み禁止
	move.l	a1,d0
	beq	chmsk_all_ch		*全チャンネルへの操作
	subq.l	#1,d0
	beq	solo_ch
chmsklp00:
	moveq.l	#0,d0
	move.l	(a1)+,d4		*check p_type
	cmpi.l	#-1,d4
	beq	t_dat_ok		*all end
	move.l	d4,d0
	swap	d0
	tst.w	d0
	bmi	_mskch_md
	beq	_mskch_fm
	lea	ch_mask_ad(pc),a2	*ADPCM
	cmpi.w	#-1,d4			*-1:全チャンネル
	bne	@f			*1チャンネルのケース
_msk_allch:
	move.w	#16-1,d4
_mskallch_lp:
	pea	(a1)			*複数チャンネルのケース
	move.w	(a2),d3			*ADPCM
	bsr	get_smkch_mode
	move.l	a1,d1
	move.l	(sp)+,a1
	dbra	d4,_mskallch_lp
	move.l	d1,a1
	bra	chmsklp00
@@:
	move.w	(a2),d3			*ADPCM
	bsr	get_smkch_mode
	bra	chmsklp00

_mskch_fm:				*FM
	lea	ch_mask_fm(pc),a2
	cmpi.w	#-1,d4
	bne	@b			*1チャンネルのケース
	moveq.l	#7,d4
	bra	_mskallch_lp

_mskch_md:				*MIDI
	lea	midi_if_tbl(pc),a2
	ext.w	d0
	move.b	(a2,d0.w),d0		*> d0はもともと2倍してある
	bmi	@f			*エラーケースは自動的に後半ルーチンで処理される
	lea	ch_mask_m0(pc),a2
	add.w	d0,a2
	cmpi.w	#-1,d4
	bne	@b
	bra	_msk_allch

@@:
	addq.w	#2,a1			*skip mode(get modeに相当)
	move.l	d4,(a0)+		*error(enableにしても影響の有るトラックは無し)
	move.l	#-1,(a0)			*set endcode
	rts

get_smkch_mode:
	move.w	(a1)+,d0		*get mode
	beq	chmsk_enable
	bmi	chmsk_mask
					*マスク反転のケース
	bchg.l	d4,d3
	bne	_chmsk_enable
	bra	_chmsk_mask

chmsk_enable:
	bclr.l	d4,d3			*enable
_chmsk_enable:
	move.w	d3,(a2)
	moveq.l	#0,d3
	move.l	play_trk_tbl(pc),a3
chmsk_en_lp0:				*イネーブル
	moveq.l	#0,d0
	move.w	(a3)+,d0
	cmpi.w	#-1,d0
	beq	@f			*指定チャンネルは演奏トラックとして存在していない
	calc_wk	d0
	cmp.l	p_type(a5),d4		*希望チャンネルか
	bne	chmsk_en_lp0
	moveq.l	#-1,d3
	tst.w	p_type(a5)
	bne	chmsk_en_lp0
	bsr	restore_af		*FMの時だけ音色
	bra	chmsk_en_lp0
@@:
	tst.l	d3
	bne	@f
	move.l	d4,(a0)+		*error:(disableにしても影響の有るトラックは無し)
	move.l	#-1,(a0)
@@:
	rts

chmsk_mask:				*マスク
	bset.l	d4,d3			*mask
_chmsk_mask:
	move.w	d3,(a2)
	moveq.l	#0,d3			*flag
	move.l	play_trk_tbl(pc),a3
chmsk_msk_lp0:
	moveq.l	#0,d0
	move.w	(a3)+,d0
	cmpi.w	#-1,d0
	beq	@f
	calc_wk	d0
	cmp.l	p_type(a5),d4		*希望チャンネルか
	bne	chmsk_msk_lp0
	bsr	ms_key_off
	moveq.l	#-1,d3			*１個でも正常に設定したmark on
	bra	chmsk_msk_lp0		*他のトラックにも同チャンネルがある可能性があるので更にループ
@@:
	tst.l	d3
	bne	@f
	move.l	d4,(a0)+		*error:(disableにしても影響の有るトラックは無し)
	move.l	#-1,(a0)
@@:
	rts

chmsk_all_ch:
	tst.w	d1
	bmi	all_ch_mask
	bne	all_ch_reverse
	moveq.l	#0,d0			*6つのデバイスワークをまとめて初期化
	move.l	d0,ch_mask_fm-work(a6)
	move.l	d0,ch_mask_m0-work(a6)
	move.l	d0,ch_mask_mr0-work(a6)
	rts				*as same as t_dat_ok

all_ch_mask:
	moveq.l	#-1,d0			*5つのデバイスワークをまとめてマスク
	move.l	d0,ch_mask_fm-work(a6)
	move.l	d0,ch_mask_m0-work(a6)
	move.l	d0,ch_mask_mr0-work(a6)
	move.l	play_trk_tbl(pc),a1
@@:					*演奏中のトラックすべてキーオフ
	moveq.l	#0,d0
	move.w	(a1)+,d0
	cmpi.w	#-1,d0
	beq	t_dat_ok
	calc_wk	d0
	move.l	p_type(a5),d4
	bsr	_ms_key_off
	bra	@b

solo_ch:
	move.l	d1,d0
	jsr	ch_odr_no		*>d5.l=chオーダー値
	bmi	t_device_offline
	moveq.l	#-1,d0
	lea	ch_mask_mr1-work(a6),a1	*6つのデバイスワークをまとめてマスク
	move.l	d0,-(a1)		*ch_mask_mr0-work(a6)
	move.l	d0,-(a1)		*ch_mask_m0-work(a6)
	move.l	d0,-(a1)		*ch_mask_fm-work(a6)
	move.l	d5,d0
	lsr.l	#3,d5
	bclr.b	d0,(a1,d5.l)		*指定チャンネルのみマスクオフ
	bra	@f

all_ch_reverse:
	not.l	ch_mask_fm-work(a6)	*6つのデバイスワークをまとめてリバース・マスク
	not.l	ch_mask_m0-work(a6)
	not.l	ch_mask_mr0-work(a6)
@@:
	move.l	play_trk_tbl(pc),a1
altmsk_lp:				*演奏中のトラックすべてキーオフ
	moveq.l	#0,d0
	move.w	(a1)+,d0
	cmpi.w	#-1,d0
	beq	t_dat_ok
	calc_wk	d0
	move.l	p_type(a5),d4
	bmi	altmsk_md
	btst.l	#16,d4
	beq	@f
	move.w	ch_mask_ad(pc),d0	*ADPCM
	btst.l	d4,d0
	beq	altmsk_lp
	bsr	ms_key_off_ad
	bra	altmsk_lp
@@:					*FM
	btst.b	d4,ch_mask_fm+1-work(a6)
	beq	@f
	bsr	ms_key_off_fm
	bra	altmsk_lp
@@:
	bsr	restore_af
	bra	altmsk_lp
altmsk_md:				*MIDI
	move.l	d4,d0
	swap	d0			*d0=p_type
	add.w	d0,d0			*kill 16th bit & x2
	lea	ch_mask_m0(pc),a2
	move.w	(a2,d0.w),d0
	btst.l	d4,d0
	beq	altmsk_lp
	bsr	ms_key_off_md
	bra	altmsk_lp

set_ch_output_level:			*各チャンネルの出力レベルの設定
	*   cmd=$5c
	* < a1.l=parameter table
	* < 	param. sequence
	*		{device type(.w),ch number(.w),omt(b),speed(.w),start(.b),end(.b)}
	*		device type:0,1,$8000～$8002,-1:all
	*		ch number:0-15
	*		omt:d0=speed,d1=start,d2=end
	*		fader speed:0-65535
	*		start level:0-128
	*		end level:0-128
	* > d0		 0:ok
	*		-1:error
	ori.w	#$700,sr	*割り込み禁止
	bsr	stop_tm_int_ms
	move.w	sr_type(pc),sr	*INT enable
	move.l	a1,a0
	jbsr	get_fader
	move.l	a0,a1
	move.l	fader_result(pc),d0
	bra	start_tm_int_ms

set_tr_output_level:			*各トラックの出力レベルの設定
	*   cmd=$5d
	* < a1.l=parameter table
	* < 	sequence of {tr number(.w),omt(b),speed(.w),start(.b),end(.b)}
	*		tr number.w:0-65534,65535:all
	*		omt:d0=speed,d1=start,d2=end
	*		fader speed:0-65535
	*		start level:0-128
	*		end level:0-128
	* > d0		 0:ok
	*		-1:error
	ori.w	#$700,sr		*割り込み禁止
	bsr	stop_tm_int_ms
	move.w	sr_type(pc),sr		*INT enable
	move.l	a1,a0
	cmpi.w	#-1,(a0)		*check mode at first
	beq	all_stol
					*トラックフェーダー
	jbsr	do_chfdr_track_mode1
	move.l	a0,a1
	move.l	fader_result(pc),d0
	bra	start_tm_int_ms
all_stol:				*全トラックフェーダー
	addq.w	#2,a0
	jbsr	do_chfdr_track_mode2
	move.l	a0,a1
	move.l	fader_result(pc),d0
	bra	start_tm_int_ms

master_fader:			*ﾌｪｰﾄﾞｱｳﾄ/ｲﾝ処理
	*   cmd=$5e
	* < a1.l=parameter list address
	*	{ device-code.w:0/1/$8000～$8002/-1,
	*	  omt.b:%000～%111
	*	  speed.w:0-65535
	*	  start-level.b:0-128, end-level.b:0-128}
	* > d0	=0:ok
	*	-1:error
	ori.w	#$700,sr
	bsr	stop_tm_int_ms
	move.w	sr_type(pc),sr	*INT enable
	move.l	a1,a0
	jbsr	get_mstr_fader
	move.l	a0,a1
	move.l	fader_result(pc),d0
	bra	start_tm_int_ms

get_fader_status:		*フェーダーの状態を得る
	*   cmd=$5f
	* > d0.l d0:実行中のチャンネルフェーダーすべてが目的に達している(1:達成した 0:達成していない)
	*	 d1:実行中のマスターフェーダーすべてが目的に達している(1:達成した 0:達成していない)
	*	 d6:チャンネルフェーダーの状態(1:実行中 0:実行されていない)
	*	 d7:マスターフェーダーの状態(1:実行中 0:実行されていない)
	moveq.l	#0,d0
	move.b	fader_flag(pc),d6
	move.b	d6,d0
	beq	3f		*フェーダー類はなにも実行されておらず
	bpl	2f		*マスターフェーダーの調査
	lea	mstfd_fm_spd2(pc),a3
	lea	master_fader_tbl(pc),a4
	moveq.l	#0,d2		*実行中のフェーダー数
	moveq.l	#0,d3		*目的を達成したフェーダー数
@@:
	move.w	(a4)+,d1	*d1 must be 0,8,16,24,32,40 or -1(予めfd_wkl倍してある)
	bmi	1f
	lea	(a3,d1.w),a2
	addq.w	#1,d2
	tst.l	(a2)		*fd_spd=spd2=0は目的達成を表す
	bne	@b
	addq.w	#1,d3
	bra	@b
1:
	cmp.w	d2,d3
	bne	2f
	bset.l	#1,d0		*すべて達成
2:
	add.b	d6,d6			*ch_fader on?
	bpl	3f
	lea	ch_fm_fdp(pc),a3
	lea	ch_fader_tbl(pc),a4
	moveq.l	#0,d2			*実行中のフェーダー数
	moveq.l	#0,d3			*目的を達成したフェーダー数
@@:
	move.w	(a4)+,d1		*d1 must be 0～95, or -1
	bmi	1f
	lsl.w	#fd_wkl_,d1
	lea	(a3,d1.w),a2
	addq.w	#1,d2
	tst.l	(a2)			*fd_spd=spd2=0は目的達成を表す
	bne	@b
	addq.w	#1,d3
	bra	@b
1:
	cmp.w	d2,d3
	bne	3f
	bset.l	#0,d0		*すべて達成
3:
	rts

get_play_time:			*演奏時間の取得
	*   cmd=$60
	* > d0.l=00HH:MM:LL
	*HH:0-99 MM:0-59 SS:0-59
	cmp.l	#-1,play_start_time-work(a6)
	beq	t_dat_ok		*測定不可能
@@:
	bsr	get_sec_present_time	*> d1.l=time
	move.l	d1,d2
	bsr	get_sec_present_time	*> d1.l=time
	cmp.l	d1,d2			*時間読み込みエラー防止のため
	bne	@b

	lea	play_start_time-work(a6),a0
	bsr	cnv_time_to_sec		*>d0.l=sec次元値
	lea	play_stop_time-work(a6),a0
	tst.l	(a0)
	bmi	1f			*停止していない
	move.l	d0,d3			*d3.l=play start time
	bsr	cnv_time_to_sec		*>d0.l=sec次元値
	lea	play_cont_time-work(a6),a0
	tst.l	(a0)
	bpl	@f
	move.l	d0,d2
	move.l	d3,d0
	bra	1f			*停止中ならば演奏経過時間も停止してやる
@@:
	move.l	d0,d1			*d1.l=play stop time
	bsr	cnv_time_to_sec		*>d0.l=sec次元値
	move.l	#-1,(a0)		*play_cont_time=-1
	move.l	#-1,-(a0)		*play_stop_time=-1
	cmp.l	d1,d3
	bls	@f
	add.l	#60*60*24,d1
@@:
	sub.l	d3,d1
	add.l	d1,d2
	move.l	d0,d3
	cmp.l	d3,d1
	bls	@f
	add.l	#60*60*24,d3
@@:
	sub.l	d1,d3
	movem.l	d0/d2,-(sp)
	move.l	d3,d2			*00HHMMSSでplay_start_timeに格納する
	bsr	cnv_sec_to_time
	moveq.l	#0,d1
	move.b	d0,d1
	divu	#10,d1
	lsl.b	#4,d1
	move.b	d1,-(a0)
	swap	d1
	or.b	d1,(a0)			*SS
	lsr.l	#8,d0
	moveq.l	#0,d1
	move.b	d0,d1
	divu	#10,d1
	lsl.b	#4,d1
	move.b	d1,-(a0)
	swap	d1
	or.b	d1,(a0)			*MM
	lsr.l	#8,d0
	moveq.l	#0,d1
	move.b	d0,d1
	divu	#10,d1
	lsl.b	#4,d1
	move.b	d1,-(a0)
	swap	d1
	or.b	d1,(a0)			*HH
	clr.b	-(a0)			*dummy
	movem.l	(sp)+,d0/d2
1:
	cmp.l	d2,d0
	bls	@f
	add.l	#60*60*24,d2
@@:
	sub.l	d0,d2
cnv_sec_to_time:
	* < d2.l=sec
	* > d0.l=time
	divu	#60*60,d2
	move.w	d2,d0		*HH
	swap	d0
	clr.w	d2
	swap	d2
	divu	#60,d2
	move.b	d2,d0		*MM
	lsl.w	#8,d0
	swap	d2
	move.b	d2,d0		*SS
	rts

cnv_time_to_sec:
	* < (a0).l=00HHMMSS
	move.l	d1,-(sp)
	moveq.l	#0,d0
	move.b	1(a0),d0	*get HH
	lsr.b	#4,d0
	mulu	#60*60*10,d0
	move.b	1(a0),d1	*get HH
	andi.w	#$0f,d1
	mulu	#60*60,d1
	add.l	d1,d0
	moveq.l	#0,d1
	move.b	2(a0),d1	*get MM
	lsr.b	#4,d1
	mulu	#60*10,d1
	add.l	d1,d0
	move.b	2(a0),d1	*get MM
	andi.w	#$0f,d1
	mulu	#60,d1
	add.l	d1,d0
	moveq.l	#0,d1
	move.b	3(a0),d1	*get SS
	lsr.b	#4,d1
	mulu	#10,d1
	add.l	d1,d0
	move.b	3(a0),d1	*get SS
	andi.l	#$0f,d1
	add.l	d1,d0
	move.l	(sp)+,d1
	rts

get_sec_present_time:			*現在の時刻を秒次元に変換して取得する
	* > d1.l=time
	movem.l	d0/d3/a2,-(sp)
	lea	$e8a00c,a2		*演奏開始時間を記録しておく
	bclr.b	#0,$e8a01b-$e8a00c(a2)	*bank 0
	move.w	-(a2),d1		*hour
	andi.w	#$0f,d1
	mulu	#10*60*60,d1
	move.w	-(a2),d0
	andi.w	#$0f,d0
	mulu	#60*60,d0
	add.l	d0,d1
	move.w	-(a2),d0		*minute
	andi.w	#$0f,d0
	mulu	#10*60,d0
	add.l	d0,d1
	move.w	-(a2),d0
	andi.w	#$0f,d0
	mulu	#60,d0
	add.l	d0,d1
	move.w	-(a2),d0		*second
	andi.w	#$0f,d0
	mulu	#10,d0
	add.l	d0,d1
	move.w	-(a2),d0
	andi.l	#$0f,d0
	add.l	d0,d1
	movem.l	(sp)+,d0/d3/a2
	rts

get_1st_comment:		*最初のコメントを取り出す
	*   cmd=$61
	* > a0.l=comment_address
	move.l	trk_buffer_top(pc),d0	*IDなしのアドレスだからz_系オフセットは-8して使用
	beq	t_dat_ok2
	move.l	d0,a0
	add.l	#z_title_offset-8,a0
	move.l	(a0)+,d0
	beq	t_dat_ok2
	add.l	d0,a0
	t_dat_ok

get_timer_mode:			*どのタイマーを使用しているか
	*   cmd=$62
	* > d0.l=timer type(0:Timer A  1:Timer B  2:YM3802 timer)
	tst.b	timer_mode-work(a6)
	bmi	t_dat_ok	*timer_a->d0.l=0
	bne	@f
	moveq.l	#1,d0		*timer_b->d0.l=1
	rts
@@:
	moveq.l	#2,d0		*timer_m->d0.l=2
	rts

get_track_table:		*トラックテーブルのアドレスを得る
	*   cmd=$63
	* > a0.l=play_trk_tbl
	* > d0.l=play_trk_tbl_se
	move.l	play_trk_tbl(pc),a0
	move.l	play_trk_tbl_se(pc),d0
	rts

get_play_work:			*演奏ワークアドレスを返す	!v3
	*   cmd=$64
	* < d1.l=trk number(0-65534)
	* > a0=trk n seq_wk_tbl
	* > d0=trk n seq_wk_tbl_se
	calc_wk	d1
	movea.l	a5,a0
	movea.l	seq_wk_tbl_se(pc),a5
	adda.l	d1,a5
	move.l	a5,d0
	rts

get_buffer_information:			*各バッファのインフォメーション
	*   cmd=$65
	* > a0.l=buffer head address
	lea	trk_buffer_top(pc),a0
	rts

get_zmsc_status:			*ZMUSICのワーク状況	!v3
	*   cmd=$66
	* > a0.l=status work address
	lea	zmusic_stat(pc),a0
	rts
*-----------------------------------------------------------------------------
application_releaser:		*サポートプログラムの解除ルーチンの登録
	*   cmd=$68
	* < a1.l=release routine address(0:cancel)
	* < d1.l=result code(キャンセル時に使用)
	* > d0.l=result code
	* > a0.l=0:error/nz:no error
	* 1)	a1.lから始まる各解放ルーチンは必要処理を実行後、最後に
	*	ZMUSIC側で解放してほしいメモリブロックがあるならば
	*	そのアドレスをa0.lにかえすようにすること。
	*	なければa0.l=0を返すこと
	* 2)	a1.lからの各解放ルーチンでなにか表示したいメッセージが
	*	有る場合はその文字列のアドレスをa1.lに返すようにすること。
	*	なければa1.l=0を返すこと
	* 3)	解放ルーチンでエラーが発生した場合は戻り値として
	*	d0.l(0:no error,1:occupied,-1:error)を返すことが出来る。
	*	エラーが発声した場合もその旨を告げるメッセージ文字列をa1.lに
	*	与えることが出来る。
	move.l	a1,d0				*d0に意味無し
	bne	spt_set_mode
						*キャンセル
	move.l	nof_ex_appli(pc),d0
	beq	t_no_application_registered	*1個も登録されていない
	move.l	ex_appli_addr(pc),a0
@@:
	cmp.l	4(a0),d1
	beq	@f
	addq.w	#8,a0
	subq.l	#1,d0
	bne	@b
	bra	t_illegal_result_code
@@:
	move.l	8(a0),(a0)+
	move.l	8(a0),(a0)+
	subq.l	#1,d0
	bne	@b
	subq.l	#1,nof_ex_appli-work(a6)
	t_dat_ok
spt_set_mode:
	move.l	nof_ex_appli(pc),d1
	bne	1f				*既にある
	move.l	ex_appli_addr(pc),d0
	move.l	d0,a0
	bne	@f				*既にある
	move.l	#ID_APPLI,d3
	move.l	#1024,d2
	move.l	d2,ex_appli_size-work(a6)	*バッファ新設
	bsr	get_mem
	tst.l	d0
	bmi	t_out_of_memory
	move.l	a0,ex_appli_addr-work(a6)
@@:
	move.l	a1,(a0)+			*アドレス登録
	move.l	ex_appli_id(pc),d0
	move.l	d0,(a0)+
	addq.l	#1,nof_ex_appli-work(a6)
	addq.l	#1,ex_appli_id-work(a6)
	rts
1:						*1こ以上の場合
	lsl.l	#3,d1
	move.l	ex_appli_size(pc),d2
	move.l	ex_appli_addr(pc),a0
	move.l	a1,d3
	cmp.l	d2,d1				*既に確保したバッファ領域内
	bcs	@f
	move.l	a0,a1
	add.l	#128,d2
	jsr	enlarge_mem-work(a6)
	tst.l	d0
	bmi	t_out_of_memory
	move.l	d2,ex_appli_size-work(a6)
	move.l	a0,ex_appli_addr-work(a6)
@@:
	move.l	d3,0(a0,d1.l)			*アドレス登録
	move.l	ex_appli_id(pc),d0
	move.l	d0,4(a0,d1.l)			*ID登録
	addq.l	#1,nof_ex_appli-work(a6)
	addq.l	#1,ex_appli_id-work(a6)
	rts

ex_appli_id:	dc.l	0
nof_ex_appli:	dc.l	0
ex_appli_addr:	dc.l	0
ex_appli_size:	dc.l	0

release_driver:				*ZMUSICの解除
	*   cmd=$69
	* > d0.l=error code(0:release completed)
	* > a0.l=driver address(to be free)
*	tst.b	cmd_or_dev-work(a6)
*	beq	rv_cannot_release	*device=で登録したものは解除出来ない
	bsr	m_init
	bsr	wait_trns		*m_init()で送信されたMIDIデータの送信終了まで待つ
	tst.b	smf_end_flag-work(a6)	*smf_end_flag=-1の場合はエラー
	ble	@f
	bsr	release_int_mode	*SMFの割り込みモード解除
@@:					*サポートプログラムの解除
	move.l	nof_ex_appli(pc),d2
	beq	delete_dvnm		*解除するもの無し
	move.l	ex_appli_addr(pc),a2
rlsdrvlp00:
	move.l	(a2),a0			*あえて(a2)+としない(コールしたあとで前につまるから)
	movem.l	d1-d7/a2-a6,-(sp)
	jsr	(a0)			*a0.l=release addr.,a1.l=release message
	movem.l	(sp)+,d1-d7/a2-a6
	move.l	d0,d1			*戻り値保存
	move.l	a1,d0
	beq	@f
	jsr	prta1
@@:
	tst.l	d1
	bne	next_rlsdrv		*error/occupied
	move.l	a0,d0
	beq	next_rlsdrv		*解除するメモリはない
	pea	$10(a0)
	DOS	_MFREE
	addq.w	#4,sp
next_rlsdrv:
	subq.l	#1,d2
	bne	rlsdrvlp00
delete_dvnm:
	bsr	wait_trns	*解放時にZMUSICのファンクションを使用するかも知れないから
	moveq.l	#ID_ALL,d3
	bsr	free_mem2	*その他のバッファも解放

	bsr	kill_OPM	*デバイス名をシステムワークより除去
	bmi	rv_cannot_release

	bsr	back_copy_key

	bsr	release_vectors

	move.l	a0work(pc),a0	*ドライバ解除アドレス
	t_dat_ok

rv_cannot_release:
	moveq.l	#-1,d0
	rts

release_vectors:
	* - all
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	movem.l	d0-d2/a1-a2,-(sp)
	move.b	midi_board(pc),d2
	beq	relvec0
	lea	rgr,a1
	btst.l	#if_m0,d2
	beq	@f
	move.b	#$80,(a1)	*initial reset
	moveq.l	#0,d0		*1/60/512=0.000032secのウエイト
	bsr	h_wait
	clr.b	(a1)		*initial reset end
	midiwait
	clr.b	grp6-rgr(a1)	*disable all int.
	midiwait
@@:
	btst.l	#if_m1,d2
	beq	@f
	lea	$10(a1),a1
	move.b	#$80,(a1)	*initial reset
	moveq.l	#0,d0		*1/60/512=0.000032secのウエイト
	bsr	h_wait
	clr.b	(a1)		*intial reset end
	midiwait
	clr.b	grp6-rgr(a1)	*disable all int.
	midiwait
@@:
	btst.l	#if_mr0,d2
	beq	relvec0
	lea	scc_a,a1
	tst.b	(a1)
	moveq.l	#(scca_init_e-scca_init)-1,d0
	lea	scca_init(pc),a2
@@:
	move.b	(a2)+,(a1)
	dbra	d0,@b
	moveq.l	#-1,d1			*RS232Cのパラメータ復元
	IOCS	_SET232C
	move.l	d0,d1
	IOCS	_SET232C
					*念のためにマウスの初期化も行う
	moveq.l	#(sccb_init_e-sccb_init)-1,d0
	subq.w	#4,a1
	lea	sccb_init(pc),a2
@@:
	move.b	(a2)+,(a1)
	dbra	d0,@b
	IOCS	_MS_INIT
relvec0:			*MPCMの占有解除
	tst.b	ext_pcmdrv-work(a6)
	beq	@f
	lea	ZMSC3_X-work(a6),a1
	move.w	#M_FREE,d0
	MPCM_call
	bra	gb_intvcs
@@:					*ZMUSIC同梱の標準ADPCMドライバの解除
	move.l	adpcm_stop_v-work(a6),d0
	beq	@f
	move.l	d0,$1a8.w		*get back int adpcm stop vector
@@:
	move.l	adpcmout_v-work(a6),d0
	beq	@f
	move.w	#$160,d1
	movea.l	d0,a1
	IOCS	_B_INTVCS	*get back int adpcmout vector
@@:
	move.l	adpcmmod_v-work(a6),d0
	beq	@f
	move.w	#$167,d1
	movea.l	d0,a1
	IOCS	_B_INTVCS	*get back int adpcmmod vector
@@:				*MPCM組み込み拒否マークの削除
	move.l	dummy_vect(pc),d0
	beq	@f
	move.l	d0,$84.w
@@:
gb_intvcs:
	move.l	sv_trap3(pc),d0
	beq	@f
	move.l	d0,$8c.w	*get back trap #3 vector
@@:
	move.l	abortjob_org(pc),d0
	beq	@f
	move.w	#$01_00+_ABORTJOB,d1
	move.l	d0,a1
	IOCS	_B_INTVCS	*ABORT処理のフックをもとに戻す
@@:				*midi in 1
	move.l	rec_vect(pc),d0
	beq	@f
	move.l	d0,$228.w	*get back $8a vector
@@:				*midi out 1
	move.l	mot_vect(pc),d0
	beq	@f
	move.l	d0,$230.w	*get back $8c vector
@@:				*midi in 2
	move.l	rec_vect2(pc),d0
	beq	@f
	move.l	d0,$2a8.w	*get back $aa vector
@@:				*midi out 2
	move.l	mot_vect2(pc),d0
	beq	@f
	move.l	d0,$2b0.w	*get back $ac vector
@@:				*rs-midi
	lea	rs_vect-work(a6),a1
	move.l	(a1),d0
	beq	rls000
	lea	$160.w,a0
	moveq.l	#8-1,d0
@@:
	move.l	(a1)+,(a0)+
	dbra	d0,@b
rls000:				*midi timer
	move.l	mint_vect(pc),d0
	beq	@f
	move.l	d0,$238.w	*get back $8e vector
@@:				*opm timer
	move.l	eint_vect(pc),d0
	beq	@f
	move.l	d0,$210.w	*get back $84 vector
@@:				*opm timer
	move.l	rmint_vect(pc),d0
	beq	@f
	move.l	d0,$200.w	*get back $80 vector
@@:				*opm timer
	tst.b	opm_vect-work(a6)
	beq	exit_relvc
	suba.l	a1,a1
	IOCS	_OPMINTST
exit_relvc:
	movem.l	(sp)+,d0-d2/a1-a2
	move.w	(sp)+,sr
	rts

scca_init:
	dc.b	$09,$c0,$09,$80,$04,$45,$01,$00
	dc.b	$02,$50,$03,$c0,$05,$e2,$09,$01
	dc.b	$0b,$56,$0c,$0e,$0d,$00,$0e,$02
	dc.b	$03,$c1,$05,$ea,$00,$80,$0e,$03
	dc.b	$0f,$00,$00,$10,$00,$10,$01,$10
scca_init_e:
sccb_init:
	dc.b	$09,$40,$04,$4c,$01,$00,$03,$c0
	dc.b	$05,$e0,$0b,$56,$0c,$1f,$0d,$00
	dc.b	$0e,$02,$03,$c1,$05,$e8,$00,$80
	dc.b	$0e,$03,$0f,$00,$00,$10,$00,$10
	dc.b	$01,$10,$09,$09
sccb_init_e:
	.even

wait_trns:			*MIDIデータの送信終わり待ち
	move.w	sr,-(sp)
	andi.w	#$f8ff,sr
	movem.l	d0-d1/a0-a1,-(sp)
	moveq.l	#if_max-1,d1
	lea	m_buffer_0(pc),a0
wtrlp:
	move.l	(a0)+,d0
	beq	wtr1
	move.l	d0,a1
@@:				*送信終了まで待つ
	tst.w	m_len(a1)
	bne	@b
wtr1:
	dbra	d1,wtrlp
	movem.l	(sp)+,d0-d1/a0-a1
	move.w	(sp)+,sr
	rts

back_copy_key:			*COPY KEY VECTOR復元
	movem.l	d0-d1/a0-a3,-(sp)
	move.l	a0work-work(a6),a0
@@:
	move.l	(a0),d0
	beq	@f
	move.l	d0,a0
	bra	@b
@@:
	move.l	copy_org(pc),d1		*元の処理ルーチンアドレス(これで書き戻す)
	lea	copy_key(pc),a2
bcklp:
	cmp.l	$54(a0),a2		*$54=copy key vector,(trap #12)
	bne	@f
	move.l	d1,$54(a0)
@@:
	move.l	12(a0),d0
	beq	exit_bck
	move.l	d0,a0
	bra	bcklp
exit_bck:
	movem.l	(sp)+,d0-d1/a0-a3
	rts

kill_OPM:			*デバイス名の除去
	* > eq=no error
	* > mi=error
	lea	$6800,a0		*デバイス名”ＯＰＭ”を強制的に削除する
KO_lp01:
	lea	NUL(pc),a2
	bsr	do_find
	cmpa.l	a2,a0
	bcc	KO_err
	cmpi.w	#$8024,-18(a0)	*本当にNULか
	bne	KO_lp01

	lea	-22(a0),a1
	move.l	a1,nul_address-work(a6)

	lea	dev_name0,a2
	bsr	rmk_heap			*ヒープ調査(return:a1,a0)
	bmi	KO_err
	move.l	dev_header2,(a0)	*ヒープを再構成して自分は抜ける

	moveq.l	#0,d0
	rts
KO_err:
	moveq.l	#-1,d0
	rts

rmk_heap:
	* < a1.l=NUL
	* < a2.l=抜けたいデバイス名
	* > a0.l=探し出したデバイス名のアドレスの1つ前のデバイスのアドレス
	* d0,a0,a1,a2
	lea	-14(a2),a3
KO_lp02:
	bsr	same_dev?
	bne	@f
	cmp.l	a1,a3
	bne	@f
	moveq.l	#0,d0		*Hit!
	rts
@@:
	cmpi.l	#-1,(a1)	*最後尾に来てしまったか
	beq	err_KO
	movea.l	a1,a0		*一つ前のをキープ(戻り値になる)
	move.l	(a1),a1		*次へ
	bra	KO_lp02
err_KO:
	moveq.l	#-1,d0
	rts

same_dev?:			*同じ名前かどうか
	* < a2.l=source name
	* > mi=not same
	* > eq=same
	movem.l	a1-a2,-(sp)
	lea	14(a1),a1
	moveq.l	#8-1,d1
@@:
	cmpm.b	(a1)+,(a2)+
	bne	@f
	dbra	d1,@b
	moveq.l	#0,d0
	movem.l	(sp)+,a1-a2
	rts
@@:
	moveq.l	#-1,d0
	movem.l	(sp)+,a1-a2
	rts

do_find:			*特定のデバイス名を探し出す
	move.b	(a2),d0
dfn_lp01:			*一文字目が見付かるまでループ
	cmp.b	(a0)+,d0
	bne	dfn_lp01

	move.l	a0,d0		*save a0 to d0
	lea	1(a2),a1
	moveq.l	#7-1,d1
dfn_lp02:
	cmpm.b	(a0)+,(a1)+
	bne	next_dfn
	dbra	d1,dfn_lp02
	rts
next_dfn:
	movea.l	d0,a0		*get back a0
	bra	do_find

occupy_zmusic:			*ZMUSICドライバの占有
	*   cmd=$6a
	* < d1.l=1	lock ZMUSIC
	* < d1.l=0	unlock ZMUSIC
	* < d1.l=-1	ask status
	* > d0.l	case:d1.l=1,0	d0:以前の占有状態(d1.l=-1のケース参照)
	* > d0.l	case:d1.l=-1	d0=0:free,	d0.l=1:occupied
	tst.l	d1
	bmi	1f
	beq	@f
						*Lock
	addq.b	#1,occupy_flag-work(a6)
	bra	1f
@@:						*Unlock
	tst.b	occupy_flag-work(a6)
	beq	1f
	subq.b	#1,occupy_flag-work(a6)
1:
	moveq.l	#0,d0
	move.b	occupy_flag(pc),d0
	rts

hook_fnc_service:		*ファンクションコールのフック
	*   cmd=$6b
	* < d1.l=function number
	* < a1.l=new user's job address(-1:ask mode)
	* > a0.l=original job address
	move.l	d1,d0
	swap	d0
	cmpi.w	#1,d0		*上位2バイトチェック
	beq	domdoutpatch	*MIDI出力ルーチンへのパッチ
	cmpi.l	#127,d1
	bhi	t_illegal_function_number
	lea	m_job_tbl(pc),a2
	add.w	d1,d1
	add.w	d1,d1
	move.l	(a2,d1.w),a0	*a0.l=original address
	cmp.l	#-1,a1
	beq	t_dat_ok	*case:ask mode
	move.l	a1,(a2,d1.w)
	t_dat_ok
domdoutpatch:			*MIDI出力ルーチン書き換えケース
	add.w	d1,d1
	move.w	@f(pc,d1.w),d1
	jmp	@f(pc,d1.w)
@@:
	dc.w	hfsm0-@b
	dc.w	hfsm1-@b
	dc.w	hfsr0-@b
	dc.w	hfsr1-@b
hfsm0:				*CZ6BM1 #1
	move.l	a1,d0
	beq	1f
	addq.l	#1,d0		*d0=-1?
	beq	@f
	move.l	a1,m_out_m0+2-work(a6)
	move.l	a2,_m_out_m0+2-work(a6)
	bsr	cache_flush
@@:
	lea	m_out_m0+6-work(a6),a0
	move.l	#_m_out_m0+6,d0
	rts
1:
	move.l	#m_out_m0+6,m_out_m0+2-work(a6)
	move.l	#_m_out_m0+6,_m_out_m0+2-work(a6)
	bsr	cache_flush
	t_dat_ok
hfsm1:				*CZ6BM1 #2
	move.l	a1,d0
	beq	1f
	addq.l	#1,d0		*d0=-1?
	beq	@f
	move.l	a1,m_out_m1+2-work(a6)
	move.l	a2,_m_out_m1+2-work(a6)
	bsr	cache_flush
@@:
	lea	m_out_m1+6-work(a6),a0
	move.l	#_m_out_m1+6,d0
	rts
1:
	move.l	#m_out_m1+6,m_out_m1+2-work(a6)
	move.l	#_m_out_m1+6,_m_out_m1+2-work(a6)
	bsr	cache_flush
	t_dat_ok
hfsr0:				*RS232C-MIDI1
	move.l	a1,d0
	beq	1f
	addq.l	#1,d0		*d0=-1?
	beq	@f
	move.l	a1,m_out_r0+2-work(a6)
	move.l	a2,_m_out_r0+2-work(a6)
	bsr	cache_flush
@@:
	lea	m_out_r0+6-work(a6),a0
	move.l	#_m_out_r0+6,d0
	rts
1:
	move.l	#m_out_r0+6,m_out_r0+2-work(a6)
	move.l	#_m_out_r0+6,_m_out_r0+2-work(a6)
	bsr	cache_flush
	t_dat_ok
hfsr1:				*RS232C-MIDI2
	move.l	a1,d0
	beq	1f
	addq.l	#1,d0		*d0=-1?
	beq	@f
	move.l	a1,m_out_r1+2-work(a6)
	move.l	a2,_m_out_r1+2-work(a6)
	bsr	cache_flush
@@:
	lea	m_out_r1+6-work(a6),a0
	move.l	#_m_out_r1+6,d0
	rts
1:
	move.l	#m_out_r1+6,m_out_r1+2-work(a6)
	move.l	#_m_out_r1+6,_m_out_r1+2-work(a6)
	bsr	cache_flush
	t_dat_ok

hook_zmd_service:		*ＺＭＤ(演奏データ／共通コマンド／制御コマンド)処理のフック
	*   cmd=$6c
	* < d1.lw=ZMD code
	* < d1.hw=device(0:FM,1:ADPCM,2:MIDI,
	*		-1:COMMON ZMD,-2:COMMON ZMD of SE side,
	*		-3:CONTROL ZMD)
	* < a1.l=new user's job address(-1:ask mode)
	* > d0.l=0:no error
	* > a0.l=original job address
	move.l	d1,d0
	bmi	case_hk_cmn		*case common cmd
	swap	d0
	add.w	d0,d0			*2倍
	add.w	d0,d0			*4倍
	move.l	hzstbl0(pc,d0.w),d0
	lea	(a6,d0.l),a2
	cmpi.w	#255,d1
	bhi	t_illegal_zmd_code	*未定義のZMDの処理内容を書き換えようとしました
	add.w	d1,d1
	add.w	d1,d1
	move.l	(a2,d1.w),a0		*a0.l=original address
	cmp.l	#-1,a1
	beq	t_dat_ok		*case:ask mode
	move.l	a1,(a2,d1.w)
	t_dat_ok
hzstbl0:
	dc.l	int_cmd_tbl_fm-work
	dc.l	int_cmd_tbl_ad-work
	dc.l	int_cmd_tbl_md-work
case_hk_cmn:				*共通コマンドの機能書き換え
	swap	d0			*-1～-3
	neg.w	d0			*1～3
	subq.w	#1,d0			*0-2
	lsl.w	#3,d0			*8倍
	cmp.w	hzstbl1+6(pc,d0.w),d1
	bcc	t_illegal_zmd_code	*未定義のZMDの処理内容を書き換えようとしました
	move.l	hzstbl1(pc,d0.w),d0
	lea	(a6,d0.l),a2
	add.w	d1,d1
	add.w	d1,d1
	move.l	(a2,d1.w),a0		*a0.l=original address
	cmp.l	#-1,a1
	beq	t_dat_ok		*case:ask mode
	move.l	a1,(a2,d1.w)
	t_dat_ok
hzstbl1:
	dc.l	cmncmdjtbl-work,n4_of_cmn_cmd
	dc.l	cmncmdjtbl_se-work,n4_of_cmn_cmd
	dc.l	ctrl_cmd_tbl-work,n4_of_ctrl_cmd

store_error:					*エラー情報の蓄積格納
	*   cmd=$6e
	* < d1.l=error code(-1のときは問い合わせのみ)
	*	(エラーの発生したファンクション番号(0-32767)*65536+エラーの種類(0-65535))
	* < d2.l=n_of_errに幾つ加算するか
	* > a0.l=エラーストックバッファのアドレス
	* > d0.l=現在ストックしているエラー情報の個数
	cmpi.l	#-1,d1				*問い合わせのみの場合
	beq	@f
	move.l	d1,d0
	bsr	set_err_code
	add.l	d2,n_of_err-work(a6)
@@:
	move.l	n_of_err-work(a6),d0		*戻り値
	move.l	err_stock_addr-work(a6),a0
	rts

print_error:					*エラーの表示／出力
	*   cmd=$6f
	* < d1.hw=output mode(0:screen,1:buffer)	(Be used in ZMSC0)
	* < d1.lw=language mode(0:English,1:Japanese)
	* < d2.l=num. of err/warn
	* < a1.l=ZMD filename(ない場合は0)
	* < a2.l=source address(ない場合は0)
	* < a3.l=source filename(ない場合は0)
	* < a5.l=error table addr.
	* > a0.l=出力バッファ(endcod=0)(if d1.l==1)	(Be used in ZMSC0)
	* > d0.l=出力バッファサイズ(endcode含まず)
	* - all
	movem.l	d2/a5,-(sp)
	suba.l	a5,a5			*default
	moveq.l	#0,d7			*文字バッファ使用サイズ=0
	btst.l	#16,d1			*d1.hwチェック(0:画面出力か、1:バッファ出力か)
	beq	@f
	move.l	#1024,d2
	move.l	#ID_TEMP,d3
	bsr	get_mem
	tst.l	d0
	bmi	t_out_of_memory
	move.l	a0,a5
	move.l	d2,prterr_size-work(a6)
@@:
	movem.l	(sp)+,d2/a0
	bsr	do_prt_err_mes
	move.l	d7,d0
	move.l	a5,a0
	rts

PUTCHAR	macro
	local	ptch0
	local	ptch1
	move.l	a5,d0
	beq	ptch0
	bsr	putchar_
	bra	ptch1
ptch0:
	DOS	_PUTCHAR
ptch1:
	endm

PRINT	macro
	local	prt0
	local	prt1
	move.l	a5,d0
	beq	prt0
	bsr	print_
	bra	prt1
prt0:
	DOS	_PRINT
prt1:
	endm

reglist	reg	d2/a0-a1

putchar_:
	movem.l	reglist,-(sp)
	lea	zero(pc),a1		*endcodeにポイント
	move.b	5+12(sp),(a5,d7.l)
	bra	prta1_00

print_:
	movem.l	reglist,-(sp)
	move.l	4+12(sp),a1
	bra	prta1_lp

prta1_:					*出力
	move.l	a5,d0
	bne	@f
	pea	(a1)
	DOS	_PRINT
	addq.w	#4,sp
	rts
@@:
	movem.l	reglist,-(sp)
prta1_lp:
	move.b	(a1)+,(a5,d7.l)
prta1_00:
	beq	@f
	addq.l	#1,d7
	cmp.l	prterr_size(pc),d7
	bcs	prta1_lp
	move.l	#1024,d2
	add.l	prterr_size(pc),d2
	move.l	a5,a1
	bsr	enlarge_mem
	tst.l	d0
	bmi	t_out_of_memory
	move.l	a0,a5
	move.l	d2,prterr_size-work(a6)
	bra	prta1_lp
@@:
	movem.l	(sp)+,reglist
	rts

*----------------------------------------
	*t_系のコマンドのエラーは
	*d0.hb=エラー発生ファンクション番号(-1はDEV_OUT時に発生)
	*d0.lb=エラーコード
	*a0.l=0
	*で表現される
	*スタックの調整はこちらで行う
*----------------------------------------
t_dat_ok:	moveq.l	#0,d0		*正常終了
		rts
t_dat_ok2:	moveq.l	#0,d0		*正常終了 #2
		move.l	d0,a0
		rts

t_illegal_channel:		err	ILLEGAL_CHANNEL
t_illegal_track_number:		err	ILLEGAL_TRACK_NUMBER
t_illegal_tone_number:		err	ILLEGAL_TONE_NUMBER
t_illegal_note_length:		err	ILLEGAL_NOTE_LENGTH
t_device_offline:		err	DEVICE_OFFLINE
t_illegal_data_size:		err	ILLEGAL_DATA_SIZE
t_illegal_part_number:		err	ILLEGAL_PART_NUMBER
t_illegal_note_number:		err	ILLEGAL_NOTE_NUMBER
t_illegal_timbre_number:	err	ILLEGAL_TIMBRE_NUMBER
t_illegal_string_length:	err	ILLEGAL_STRING_LENGTH
t_illegal_parameter_format:	err	ILLEGAL_PARAMETER_FORMAT
t_illegal_parameters_combination:	err	ILLEGAL_PARAMETERS_COMBINATION
t_illegal_parameter_value:	err	ILLEGAL_PARAMETER_VALUE
t_empty_timbre_number:		err	EMPTY_TIMBRE_NUMBER
t_empty_note_number:		err	EMPTY_NOTE_NUMBER
t_offset_too_long:		err	OFFSET_TOO_LONG
t_processing_size_too_large:	err	PROCESSING_SIZE_TOO_LARGE
t_unidentified_file:		err	UNIDENTIFIED_FILE
t_unmanageable_data_sequence:	err	UNMANAGEABLE_DATA_SEQUENCE
t_illegal_wave_number:		err	ILLEGAL_WAVE_NUMBER
t_no_application_registered	err	NO_APPLICATION_REGISTERED
t_illegal_result_code		err	ILLEGAL_RESULT_CODE
t_no_zmd_err:			err	NO_ZMD_ERROR
t_unidentified_memory:		err	UNIDENTIFIED_MEMORY
t_compiler_not_available:	err	COMPILER_NOT_AVAILABLE
t_compile_error:		err	COMPILE_ERROR
t_illegal_zmd_code:		err	ILLEGAL_ZMD_CODE
t_illegal_function_number:	err	ILLEGAL_FUNCTION_NUMBER
t_no_performance_data:		err	NO_PERFORMANCE_DATA
t_no_timbre_parameters		err	NO_TIMBRE_PARAMETERS
t_illegal_interface_number	err	ILLEGAL_INTERFACE_NUMBER
t_device_already_occupied:	err	THE_DEVICE_ALREADY_OCCUPIED
t_illegal_memory_block_size:	err	ILLEGAL_MEMORY_BLOCK_SIZE
t_out_of_memory:
	move.l	#ID_TEMP,d3
	bsr	free_mem2
	err	OUT_OF_MEMORY

t_file_not_found:			*ファイルネームをサブ情報としてもつ
	move.l	fnc_no(pc),d0
	move.w	#FILE_NOT_FOUND,d0
	bra	@f

t_illegal_file_size:			*ファイルネームをサブ情報としてもつ
	move.l	fnc_no(pc),d0
	move.w	#ILLEGAL_FILE_SIZE,d0
	bra	@f

t_read_error:				*ファイルネームをサブ情報としてもつ
	move.l	fnc_no(pc),d0
	move.w	#READ_ERROR,d0
@@:
	move.l	d0,-(sp)
	bsr	set_err_code
	move.l	fopen_name(pc),d0
	bsr	set_err_code		*set error code(fopenで最後に取り扱ったfilename)
	moveq.l	#0,d0
	bsr	set_err_code		*set error code(dummy)
	bsr	set_err_code		*set error code(dummy)
	bra	inc_n_of_err

t_error_code_exit:			*d0.lがそのままエラーコード
	* < d0.l=error code
	move.l	d0,-(sp)
	bsr	set_err_code		*set error code
	moveq.l	#0,d0
	bsr	set_err_code		*set error code(dummy)
	bsr	set_err_code		*set error code(dummy)
	bsr	set_err_code		*set error code(dummy)
inc_n_of_err:
	addq.l	#1,n_of_err-work(a6)
	bsr	do_fclose		*openしているファイルがあればそれを閉じる
*	bsr	play_beep
	suba.l	a0,a0			*error mark
	move.l	(sp)+,d0
	bset.l	#31,d0			*error mark
	move.l	sp_buf-work(a6),sp
	move.l	fnc_quit_addr-work(a6),-(sp)
	rts

set_err_code:				*エラーコードのストック
reglist	reg	d0-d4/a0-a1
	movem.l	reglist,-(sp)
	move.l	d0,d4			*main info
	tst.l	n_of_err-work(a6)
	bne	case_erstk_enlg
	tst.l	err_stock_addr-work(a6)
	bne	store_ercd
	move.l	#ID_ERROR,d3
	move.l	#256,d2			*初期値は256バイト
	bsr	get_mem
	tst.l	d0
	bmi	exit_sec
	move.l	d2,err_stock_size-work(a6)
	move.l	a0,err_stock_addr-work(a6)
	bra	store_ercd_
store_ercd:
	move.l	err_stock_next(pc),a0
store_ercd_:
	move.l	d4,(a0)+		*エラー情報格納
	move.l	a0,err_stock_next-work(a6)
exit_sec:
	movem.l	(sp)+,reglist
	rts
case_erstk_enlg:			*メモリ領域拡大の場合
	move.l	err_stock_next(pc),a0
	move.l	err_stock_addr(pc),a1
	add.l	err_stock_size(pc),a1
	cmp.l	a1,a0
	bcs	store_ercd_
	sub.l	err_stock_addr(pc),a0
	move.l	a0,d1			*d1.l=現在の書き込み目的オフセット
	move.l	err_stock_addr(pc),a1
	move.l	err_stock_size(pc),d2
	add.l	#256,d2			*もう256バイト確保
	move.l	d2,err_stock_size-work(a6)
	jsr	enlarge_mem-work(a6)
	tst.l	d0
	bmi	exit_sec
	move.l	a0,err_stock_addr-work(a6)
	add.l	d1,a0
	bra	store_ercd_

	.include	prterrms.s
	.include	zmerrmes.s	*エラーメッセージ
	.even

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

get_mem:			*メモリの確保
	*   cmd=$70
	* < d2.l=memory size
	* < d3.l=employment
	* > d0.l=memory block address (or error code/ depends on _S_MALLOC)
	* > d2.l=long word border size
	* > a0.l=data address
	* - all
reglist	reg	d1
	move.l	reglist,-(sp)
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	addq.l	#3,d2
	andi.w	#$fffc,d2	*make it long word border
	move.l	d2,d1
	beq	1f
	addq.l	#8,d1		*add header size
	move.l	d1,-(sp)
	clr.w	-(sp)
	DOS	_S_MALLOC
	addq.w	#6,sp
	tst.l	d0
	bmi	@f
	move.l	d0,a0
	move.l	a0work-work(a6),-12(a0)	*親書き換え(強引)
	move.l	#ID_ZMSC,(a0)+	*IDをセット
	move.l	d3,(a0)+	*使用目的をセット
	move.w	(sp)+,sr
	move.l	(sp)+,reglist
	rts
@@:
	move.w	(sp)+,sr
	move.l	(sp)+,reglist
	bra	t_out_of_memory
1:
	move.w	(sp)+,sr
	move.l	(sp)+,reglist
	bra	t_illegal_memory_block_size

enlarge_mem:			*メモリブロックの拡大縮小
	*   cmd=$71
	* < d2.l=new memory size
	* < a1.l=now address
	* > d0.l=address (0:done it, error/ depends on _S_MALLOC)
	* > d2.l=long word border size
	* > a0.l=address
	* - all
reglist	reg	d1/a1-a2
	movem.l	reglist,-(sp)
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	addq.l	#3,d2
	andi.w	#$fffc,d2	*Make it long word border
	move.l	d2,d1
	beq	err_exit_enlmm1
	addq.l	#8,d1
	move.l	a1,a0
	move.l	d1,-(sp)
	pea	-8(a1)
	DOS	_SETBLOCK
	addq.w	#8,sp
	tst.l	d0
	beq	exit_enlmm	*no error
	move.l	d1,-(sp)	*SETBLOCK出来ない時は新たにメモリ確保
	clr.w	-(sp)
	DOS	_S_MALLOC
	addq.w	#6,sp
	tst.l	d0
	bmi	err_exit_enlmm2	*error
	move.l	d0,a0
	move.l	a0work-work(a6),-12(a0)	*親書き換え(強引)
	move.l	-8(a1),(a0)+	*IDをセット
	move.l	-4(a1),(a0)+	*使用目的をセット
	move.l	a0,a2
	pea	-8(a1)
	move.l	d2,d0
*	addq.l	#3,d0
*	andi.w	#$fffc,d0
@@:				*旧メモリ内容を新メモリエリアへ複写
	move.l	(a1)+,(a2)+
	subq.l	#4,d0
	bne	@b
	DOS	_S_MFREE	*メモリ開放
	addq.w	#4,sp
exit_enlmm:
	move.w	(sp)+,sr
	movem.l	(sp)+,reglist
	rts
err_exit_enlmm1:
	move.w	(sp)+,sr
	movem.l	(sp)+,reglist
	bra	t_illegal_memory_block_size
err_exit_enlmm2:
	move.w	(sp)+,sr
	movem.l	(sp)+,reglist
	bra	t_out_of_memory

free_mem:			*メモリブロックの解放
	*   cmd=$72
	* < a1.l=data address
	* > d0.l=0 no error
	* - a1
	move.l	a1,-(sp)
	cmpi.l	#ID_ZMSC,-8(a1)
	bne	err_frmm
	pea	-8(a1)
	DOS	_S_MFREE
	addq.w	#4,sp
	tst.l	d0
	bne	_err_frmm		*case error
	move.l	-4(a1),d0
	cmp.l	#ID_ZMD,d0
	bne	@f
	bsr	free_ZMD_mem
	bra	exit_frmm
@@:
	cmp.l	#ID_ERROR,d0
	bne	@f
	bsr	free_ERROR_mem
	bra	exit_frmm
@@:
	cmp.l	#ID_ZPD,d0
	bne	@f
	bsr	free_ZPD_mem
	bsr	adpcm_tbl_init
	bra	exit_frmm
@@:
	cmp.l	#ID_ZPD_TBL,d0
	bne	@f
	bsr	free_ZPD_TBL_mem
	bra	exit_frmm
@@:
	cmp.l	#ID_WAVE,d0
	bne	@f
	bsr	free_WAVE_mem
	bra	exit_frmm
@@:
	cmp.l	#ID_WAVE_TBL,d0
	bne	@f
	bsr	free_WAVE_TBL_mem
	bra	exit_frmm
@@:
	cmp.l	#ID_FMSND,d0
	bne	@f
	bsr	free_FMSND_mem
*	bra	exit_frmm
@@:
exit_frmm:
	moveq.l	#0,d0
	move.l	(sp)+,a1
	rts
err_frmm:
	moveq.l	#-1,d0
_err_frmm:
	move.l	(sp)+,a1
	rts

free_ZMD_mem:
	moveq.l	#0,d0
	move.l	d0,trk_buffer_top-work(a6)
	move.l	d0,trk_po_tbl-work(a6)
	move.l	d0,pattern_trk-work(a6)
	move.l	a1,-(sp)
	move.l	play_trk_tbl(pc),a1
	move.w	#-1,(a1)			*初期化
	move.l	play_bak(pc),a1
	move.w	#-1,(a1)			*初期化
	move.l	(sp)+,a1
	rts

free_ERROR_mem:
	moveq.l	#0,d0
	move.l	d0,n_of_err-work(a6)
	move.l	d0,err_stock_addr-work(a6)
	rts

free_ZPD_mem:
	moveq.l	#0,d0
	move.b	d0,zpd_last_fn+30-work(a6)
	cmp.l	adpcm_buffer_top-work(a6),a1
	bne	@f
	move.l	d0,adpcm_buffer_top-work(a6)
@@:
	rts

free_ZPD_TBL_mem:
	moveq.l	#0,d0
	cmp.l	adpcm_tbl-work(a6),a1
	bne	@f
	move.l	d0,adpcm_tbl-work(a6)
	move.l	d0,adpcm_n_max-work(a6)
	rts
@@:
	cmp.l	adpcm_tbl2-work(a6),a1
	beq	@f
	move.l	d0,adpcm_tbl2-work(a6)
	move.l	d0,adpcm_n_max2-work(a6)
@@:
	rts

free_WAVE_mem:
	moveq.l	#0,d0
	cmp.l	wave_memory_top-work(a6),a1
	bne	@f
	move.l	d0,wave_memory_top-work(a6)
@@:
	rts

free_ZPD_mem2:
	moveq.l	#0,d0
	move.b	d0,adpb_clr-work(a6)
	move.l	d0,adpcm_buffer_top-work(a6)
	move.b	d0,zpd_last_fn+30-work(a6)
	rts

free_ZPD_TBL_mem2:
	moveq.l	#0,d0
	move.l	d0,adpcm_tbl-work(a6)
	move.l	d0,adpcm_n_max-work(a6)
	move.l	d0,adpcm_tbl2-work(a6)
	move.l	d0,adpcm_n_max2-work(a6)
	rts

free_WAVE_mem2:
	moveq.l	#0,d0
	move.b	d0,wvmm_clr-work(a6)
	move.l	d0,wave_memory_top-work(a6)
	rts

free_WAVE_TBL_mem:
	cmp.l	wave_tbl-work(a6),a1
	bne	@f
free_WAVE_TBL_mem2:
	moveq.l	#0,d0
	move.l	d0,wave_tbl-work(a6)
	move.l	d0,wave_n_max-work(a6)
@@:
	rts

free_FMSND_mem:
	moveq.l	#0,d0
	move.l	d0,fmsnd_buffer-work(a6)
	move.w	d0,fmsnd_n_max-work(a6)
	rts

free_mem2:			*メモリブロックの解放　その2(使用用途識別開放)
	*   cmd=$73
	* < d3.l=employment ID(0:ALL)
	* > d0.l:0 no error, ne:error
	* - all
	movem.l	d1/a1,-(sp)
	moveq.l	#-1,d1
	move.l	fstmem(pc),a1
	move.l	a1,d0
	bne	@f
	bsr	get_fstmem		*メモリブロックの最初を求める
@@:
frmm2lp:
	move.l	12(a1),d0
	beq	all_end_frmm2	*all end
	move.l	d0,a1
	cmpi.l	#ID_ZMSC,16(a1)
	bne	frmm2lp
	tst.l	d3		*all ZmSc
	beq	@f
	cmp.l	20(a1),d3	*ID CHECK
	bne	frmm2lp
@@:
	pea	16(a1)
	DOS	_S_MFREE
	addq.w	#4,sp
	moveq.l	#0,d1
	bra	frmm2lp
all_end_frmm2:
	tst.l	d1
	bne	exit_frmm2		*err case
	tst.l	d3
	bne	@f			*All freeだったか
	bsr	free_ZMD_mem
	bsr	free_ERROR_mem
	bsr	free_ZPD_mem2
	bsr	free_ZPD_TBL_mem2
	bsr	free_WAVE_mem2
	bsr	free_WAVE_TBL_mem2
	bsr	free_FMSND_mem
	bra	exit_frmm2
@@:
	cmp.l	#ID_ZMD,d3
	bne	@f
	bsr	free_ZMD_mem
	bra	exit_frmm2
@@:
	cmp.l	#ID_ERROR,d3
	bne	@f
	bsr	free_ERROR_mem
	bra	exit_frmm2
@@:
	cmp.l	#ID_ZPD,d3
	bne	@f
	bsr	free_ZPD_mem2
	bsr	adpcm_tbl_init
	bra	exit_frmm2
@@:
	cmp.l	#ID_ZPD_TBL,d3
	bne	@f
	bsr	free_ZPD_TBL_mem2
	bra	exit_frmm2
@@:
	cmp.l	#ID_WAVE,d3
	bne	@f
	bsr	free_WAVE_mem2
	bra	exit_frmm2
@@:
	cmp.l	#ID_WAVE_TBL,d3
	bne	@f
	bsr	free_WAVE_TBL_mem2
	bra	exit_frmm2
@@:
	cmp.l	#ID_FMSND,d3
	bne	@f
	bsr	free_FMSND_mem
*	bra	exit_frmm2
@@:
exit_frmm2:
	move.l	d1,d0			*error code
	movem.l	(sp)+,d1/a1
	rts

get_fstmem:
	move.l	a0work(pc),a1
@@:				*メモリブロックの先頭アドレスを求める
	move.l	(a1),d0
	beq	@f
	move.l	d0,a1
	bra	@b
@@:
	move.l	a1,fstmem-work(a6)
	rts

exchange_memid:			*メモリブロックのIDの変更
	*   cmd=$74
	* < a1.l=mem.block address
	* < d1.l=mode	(0:no check) (1:check mode) (-1:exchange all who got d2 id.) 
	* < d2.l=old ID (Can be omitted in 'no check' case.)
	* < d3.l=New ID ($8000_0000 means lock mem.)($0000_0000 means unlock mem.)
	* > d0.l=return (0:no error, ne:error)
	* - all except d0,a0
reglist	reg	d1/a1
	movem.l	reglist,-(sp)
	tst.l	d1
	beq	@f
	bmi	exgmmid_repeat_mode
	cmp.l	#ID_ZMSC,-8(a1)
	bne	exit_em_err
	move.l	-4(a1),d0
	bclr.l	#31,d0
	cmp.l	d0,d2
	bne	exit_em_err
@@:
	tst.l	d3
	beq	unlock0
	cmpi.l	#ID_LOCK,d3
	bne	@f
	or.l	d3,-(a1)		*lock case
	movem.l	(sp)+,reglist
	t_dat_ok
@@:
	move.l	d3,-(a1)		*exchange case
	movem.l	(sp)+,reglist
	t_dat_ok
unlock0:
	andi.l	#$7fff_ffff,-(a1)	*unlock case
	movem.l	(sp)+,reglist
	t_dat_ok
exit_em_err
	movem.l	(sp)+,reglist
	bra	t_unidentified_memory

exgmmid_repeat_mode:		*d2.lで示されるIDを持つメモリブロックのIDを全てd3へ置き換える
	moveq.l	#-1,d1
	move.l	fstmem(pc),a1
	move.l	a1,d0
	bne	@f
	bsr	get_fstmem		*メモリブロックの最初を求める
@@:
exmmlp:
	move.l	12(a1),d0
	beq	exit_exmmid
	move.l	d0,a1
	cmpi.l	#ID_ZMSC,16(a1)
	bne	exmmlp
	move.l	20(a1),d0
	bclr.l	#31,d0
	cmp.l	d0,d2		*ID CHECK
	bne	exmmlp
	tst.l	d3
	beq	unlock1
	cmpi.l	#ID_LOCK,d3
	bne	@f
	or.l	d3,20(a1)	*lock case
	moveq.l	#0,d1
	bra	exmmlp
@@:
	move.l	d3,20(a1)	*exchange case
	moveq.l	#0,d1
	bra	exmmlp
unlock1:
	andi.l	#$7fff_ffff,20(a1)	*unlock case
	moveq.l	#0,d1
	bra	exmmlp
exit_exmmid:
	move.l	d1,d0		*error code
	movem.l	(sp)+,d1/a1
	rts

init_all:			*ドライバの初期化
	*   cmd=$78
	* > d0.l=Version ID
	tst.b	no_init_mode-work(a6)
	beq	@f
	move.w	#RTS,d0
	move.w	d0,init_inst_fm-work(a6)
	move.w	d0,init_inst_ad-work(a6)
	move.w	d0,init_inst_md-work(a6)
@@:
	moveq.l	#0,d1
	bsr	current_midi_in
	moveq.l	#0,d1
	bsr	current_midi_out
	bsr	init_midibd
	moveq.l	#$fe,d0			*dummy
	jsr	m_out_r0-work(a6)
	clr.b	zpd_last_fn+30-work(a6)
*	clr.b	cnf_last_fn+30-work(a6)
*	clr.b	mbd_last_fn+30-work(a6)
	move.l	m_play00,m_play00_bak-work(a6)
	bsr	wave_tbl_init
	bsr	adpcm_tbl_init
	bsr	fmsnd_init
	jsr	mr_init-work(a6)	*乱数初期化
	jbsr	m_init
	bsr	init_se_wk
	bsr	set_new_t_max_min
	bsr	set_new_t_max_min_se
	move.b	zmsc_mode-work(a6),d1
	bsr	zmusic_mode
	bsr	init_global_fmopmprms	*FM音源グローバルパラメータ初期化
	move.w	#$0403,d1		*frq/pan
	moveq.l	#num_of_80,d2		*length
	lea	dummy_data,a1
	IOCS	_ADPCMOUT		*ダミー再生
	moveq.l	#0,d0
	move.w	ver_num,d0
	rts

init_global_fmopmprms:
	lea	opmset-work(a6),a4
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	move.b	OPMCTRL.w,d1
	andi.b	#$fc,d1
	move.b	d1,d2
	moveq.l	#$1b,d1				*WF=0
	jsr	(a4)
	move.w	(sp)+,sr
	moveq.l	#1,d1
	moveq.l	#2,d2				*HARD LFO RESET
	jsr	(a4)
	moveq.l	#0,d2				*HARD LFO START
	jsr	(a4)
	moveq.l	#$19,d1
	moveq.l	#$80,d2				*PMD=0
	jsr	(a4)
	moveq.l	#0,d2				*AMD=0
	jsr	(a4)
	moveq.l	#$18,d1				*LFRQ=0
	jsr	(a4)
	moveq.l	#15,d1				*NE=0,NFRQ=0
	jmp	(a4)

mr_p:	equ	89		*乱数用シード
mr_q:	equ	38		*乱数用シード
mr_init:			*乱数発生初期化ルーチン
	movem.l	d0-d3/a0-a2,-(sp)
	lea.l	exec,a0
	lea.l	$1_0000,a1
	move.l	estbn(pc),a2
	moveq.l	#20-1,d3
@@:				*乱数シード作成(適当)
	move.l	(a0)+,d0
	move.l	(a1)+,d2
	rol.l	#8,d0
	eor.l	d2,d0
	move.l	d0,(a2)+
	dbra	d3,@b
				*乱数生成テーブル作成
	move.l	#(mr_p/16)+1,d1
	moveq	#((mr_p/16)+1)*16-mr_p,d2	*shift counter
	move.l	estbn(pc),a1
	lea	(mr_p/16)*2(a1),a0
	move.w	(a0)+,d1
	move.w	-4(a0),d0
	lsl.w	d2,d1
	move.w	(a1),d3
	lsr.w	d2,d3
	eor.w	d0,d3
	or.w	d3,d1
	move.w	d1,-2(a0)

	moveq.l	#(mr_p-((mr_p/16)+1))-1,d3
@@:
	move.w	(a1)+,d0
	lsl.w	d2,d0
	move.w	(a1),d1
	lsr.w	d2,d1
	or.w	d1,d0
	move.w	-2(a0),d1
	eor.w	d1,d0
	move.w	d0,(a0)+
	dbra	d3,@b

	move.l	estbn(pc),a0
	lea	(mr_p-mr_q)*2(a0),a1
	movem.l	a0-a1,mr_xp-work(a6)
	movem.l	(sp)+,d0-d3/a0-a2
	rts

fmsnd_init:				*音色バッファの初期化
	movem.l	d1-d2/a1-a2,-(sp)
	move.w	fmsnd_n_max(pc),d1
	beq	exit_fmsnd_init
	lea	preset_fmsnd(pc),a1	*src
	movea.l	fmsnd_buffer(pc),a2	*dest
	moveq.l	#fmsnd_size/4-1,d2
@@:
	move.l	(a1)+,(a2)+
	dbra	d2,@b

	movea.l	fmsnd_buffer(pc),a1	*src
	lea	fmsnd_size(a1),a2	*dest
	subq.w	#1,d1
	mulu	#fmsnd_size/4,d1
	subq.w	#1,d1			*for dbra
	bcs	exit_fmsnd_init
@@:
	move.l	(a1)+,(a2)+
	dbra	d1,@b
exit_fmsnd_init:
	movem.l	(sp)+,d1-d2/a1-a2
	rts

preset_fmsnd:			*音色バッファの初期データ
	dc.b	0,0
	ds.b	30
	ds.b	16
preset_fmsnd_end_:
	.even

init_se_wk:
	movem.l	d0-d2/d4/a5,-(sp)
	clr.l	mask_preserve-work(a6)		*マスクを初期化して演奏するマーク
	movea.l	seq_wk_tbl_se(pc),a5
	move.w	se_tr_max(pc),d2
	subq.w	#1,d2
	bcs	exit_isw
	moveq.l	#0,d4		*p_type,p_ch=0
@@:
	jbsr	init_wks
	move.b	#ID_DEAD,p_track_stat(a5)
	lea	trwk_size(a5),a5
	dbra	d2,@b
exit_isw:
	movem.l	(sp)+,d0-d2/d4/a5
	rts

int_start:			*割り込みの開始制御
	*   cmd=$79
	* < d1.w=-1	音楽タイマ 
	* < d1.w=0	音楽／効果音タイマ 
	* < d1.w=1	効果音タイマ 
	ori.w	#$0700,sr
	tst.w	d1
	bmi	_init_timer
	bne	init_timer_se
	bsr	_init_timer
	bra	init_timer_se

int_stop:			*割り込みの停止制御
	*   cmd=$7a
	* < d1.w=-1	音楽タイマ 
	* < d1.w=0	音楽／効果音タイマ 
	* < d1.w=1	効果音タイマ 
	tst.w	d1
	bmi	stop_timer
	bne	stop_timer_se
	bsr	stop_timer
	bra	stop_timer_se

set_int_service:		*ユーザ割り込みサービスの設定
	*   cmd=$7b
	*設定時
	* 	< d1.hw=全音符のクロック数
	* 	< d1.lw=音楽テンポ
	* 	< a1.l=ユーザー割り込みエントリ
	*	> d0.l=0:done	d0.l=-1:先約有り,a0.l=ルーチンエントリアドレス
	*テンポの変更
	* 	< d1.hw=全音符のクロック数
	* 	< d1.lw=音楽テンポ
	*	< a1.l=-1
	*	> d0.l=0:正常終了	d0.l=-1:失敗
	*検査時
	* 	< d1.l=-1
	*	< a1.l=0
	*	> d0.l=0:空き,a0.l=0	d0.l=-1:先約有り,a0.l=ルーチンエントリアドレス
	*解除時
	* 	< d1.l=0
	* 	< a1.l=ユーザー割り込みエントリ
	* 	> d0.l=0:done	d0.l=-1:解除不可能
	* x d0-d2/a0-a1
	ori.w	#$0700,sr
	move.l	a1,d0
	beq	sis_detect	*検査
	cmpa.l	#-1,a1
	beq	sis_tempo	*テンポ変更
	cmpi.l	#-1,d1
	beq	sis_detect	*検査
	tst.l	d1
	beq	sis_release	*解除

	cmp.l	#int_dummy,sub_job_entry-work(a6)
	bne	error_sis		*先約有り
	tst.b	timer_mode-work(a6)	*(A:-1/B:0/M:1)
	beq	can_use_tm_a
	bpl	can_use_tm_b2
can_use_tm_b:						*タイマAをシステムが使っている
							*タイマBをユーザー割り込みに当てる
	move.w	#%0001_1111,tm_a_reset-work(a6)
	move.w	#%0010_1111,tm_b_reset-work(a6)
	move.w	#%0011_1111,tm_ab_reset-work(a6)
	move.l	a1,sub_job_entry-work(a6)
tm_b_chng:					*テンポだけ変更する場合のエントリ
	move.l	d1,d2
	tempo_range	d2,_se
	move.w	mst_clk(pc),-(sp)		*便宜上
	swap	d1
	move.w	d1,mst_clk-work(a6)
	move.w	d2,tempo_value_se-work(a6)
	bsr	calc_timer_se			*>d1.l=timer value
	bmi	@f
	bsr	init_timer_se
@@:
	move.w	(sp)+,mst_clk-work(a6)
	t_dat_ok
can_use_tm_b2:					*MIDIタイマをシステムが使っている
						*タイマBをユーザー割り込みに当てる
	cmp.l	#$fe0000,$10c.w
	bcs	error_sis			*先約有り
	st.b	opm_vect-work(a6)
	move.l	a1,sub_job_entry-work(a6)
	move.w	#%0000_1010,tm_a_reset-work(a6)
	move.w	#%0010_1010,tm_b_reset-work(a6)
	move.w	#%0010_1010,tm_ab_reset-work(a6)
	lea	int_entry_f-work(a6),a1
	IOCS	_OPMINTST
tm_b2_chng:					*テンポだけ変更する場合のエントリ
	move.l	d1,d2
	tempo_range	d2,_se
	move.w	mst_clk(pc),-(sp)		*便宜上
	swap	d1
	move.w	d1,mst_clk-work(a6)
	move.w	d2,tempo_value_se-work(a6)
	bsr	calc_timer_se			*>d1.l=timer value
	bmi	@f
	bsr	init_timer_se
@@:
	move.w	(sp)+,mst_clk-work(a6)
	t_dat_ok
can_use_tm_a:						*タイマBをシステムが使っている
							*タイマAをユーザー割り込みに当てる
	move.w	#%0001_1111,tm_a_reset-work(a6)
	move.w	#%0010_1111,tm_b_reset-work(a6)
	move.w	#%0011_1111,tm_ab_reset-work(a6)
	move.l	a1,sub_job_entry-work(a6)
tm_a_chng:					*テンポだけ変更する場合のエントリ
	move.l	d1,d2
	tempo_range	d2,_se
	move.w	mst_clk(pc),-(sp)		*便宜上
	swap	d1
	move.w	d1,mst_clk-work(a6)
	move.w	d2,tempo_value_se-work(a6)
	bsr	calc_timer_se			*>d1.l=timer value
	bmi	@f
	bsr	init_timer_se
@@:
	move.w	(sp)+,mst_clk-work(a6)
	t_dat_ok

sis_release					*解除
	cmp.l	sub_job_entry-work(a6),a1
	bne	error_sis			*エントリが違うので解除は出来ない
	tst.b	timer_mode-work(a6)		*(A:-1/B:0/M:1)
	beq	release_tm_a
	bpl	release_tm_b2
release_tm_b:					*タイマAをシステムが使っている
	bsr	stop_timer_b			*タイマBのユーザー割り込みを解除
	move.w	#%0001_0101,tm_a_reset-work(a6)	*タイマAのみが有効になるような設定に戻す
	move.w	#%0000_0101,tm_b_reset-work(a6)
	move.w	#%0001_0101,tm_ab_reset-work(a6)
	lea	int_dummy(pc),a1
	move.l	a1,sub_job_entry-work(a6)
	t_dat_ok
release_tm_b2:					*MIDIタイマをシステムが使っている
	bsr	stop_timer_b
	clr.w	tm_a_reset-work(a6)		*FM音源タイマが死ぬような設定にする
	clr.w	tm_b_reset-work(a6)
	clr.w	tm_ab_reset-work(a6)
	lea	int_dummy(pc),a1
	move.l	a1,sub_job_entry-work(a6)
	clr.b	opm_vect-work(a6)
	suba.l	a1,a1
	IOCS	_OPMINTST
	t_dat_ok
release_tm_a:					*タイマBをシステムが使っている
	bsr	stop_timer_a			*タイマAのユーザー割り込みを解除
	move.w	#%0000_1010,tm_a_reset-work(a6)	*タイマBのみが有効になるような設定に戻す
	move.w	#%0010_1010,tm_b_reset-work(a6)
	move.w	#%0010_1010,tm_ab_reset-work(a6)
	lea	int_dummy(pc),a1
	move.l	a1,sub_job_entry-work(a6)
	t_dat_ok

sis_detect				*検査
	suba.l	a0,a0
	cmp.l	#int_dummy,sub_job_entry-work(a6)
	beq	t_dat_ok		*あき
error_sis:
	move.l	sub_job_entry(pc),a0
	moveq.l	#-1,d0
	rts

sis_tempo:				*テンポ変更
	cmp.l	#int_dummy,sub_job_entry-work(a6)
	beq	error_sis			*ルーチンなにもない
	tst.b	timer_mode-work(a6)		*(A:-1/B:0/M:1)
	beq	tm_a_chng
	bmi	tm_b_chng
						*MIDIタイマをシステムが使っている
	cmp.l	#$fe0000,$10c.w			*タイマBをユーザー割り込みに当てる
	bcc	error_sis			*ルーチンなにもない
	bra	tm_b2_chng

control_tempo:		*テンポ設定の主導権設定
	*   cmd=$7c
	* < d1.l=-1	テンポ設定の主導権を外部アプリケーションに委託
	* < d1.l=0	テンポ設定主導権を奪還(内部パラメタでテンポ初期化も行う)
	ori.w	#$0700,sr
	tst.l	d1
	beq	ctrl_tempo_off
			*テンポ設定の主導権を外部アプリケーションに委託
	tas.b	tempo_mode-work(a6)
	bne	t_dat_ok
	lea	ctrl_tempo_bak(pc),a1
	move.l	wrt_tmp(pc),(a1)+
	move.w	#RTS,init_timer-work(a6)
	move.l	#NOP_NOP,wrt_tmp-work(a6)
	bsr	cache_flush
	t_dat_ok

ctrl_tempo_off:		*テンポ設定主導権を奪還(内部パラメタでテンポ初期化も行う)
	bclr.b	#7,tempo_mode-work(a6)
	beq	t_dat_ok
	lea	ctrl_tempo_bak(pc),a1
	move.w	#NOP,init_timer-work(a6)
	move.l	(a1)+,wrt_tmp-work(a6)
	bsr	cache_flush
	bsr	init_timer
	jsr	midi_clk		*01/01/20
	t_dat_ok

zmusic_mode:		*ZMUSICモード切り換え
	*   cmd=$7e
	* < d1.l=mode(2:Ver.2.0 mode,3:Ver.3.0 mode,-1:ask)
	* > d0.l=0:DONE -1:SAME
	* > d0.l=last mode(< d1.l=-1のときのみ)
	* x d1,a0,a1,a2
	tst.b	d1
	bmi	ask_zmsc3_mode
	cmpi.b	#3,d1
	bcs	zmusic_mode_v2
	bne	zmsc3_mode_notouch
							*Version 3.0xモード
	move.b	d1,zmsc_mode-work(a6)
	lea	mode_patch_bkup-work(a6),a0
	move.w	(a0)+,pmod_wvmm_patch-work(a6)
	move.w	(a0)+,arcc_wvmm_patch-work(a6)
	move.w	(a0)+,frq_mpcm_patch
	move.w	(a0)+,datatype_mpcm_patch
	move.w	(a0)+,exit_gsg-work(a6)
	move.w	(a0)+,get_def_velo-work(a6)
	lea	v3_volume_tbl(pc),a1
	lea	vol_tbl2-work(a6),a2
	moveq.l	#17-1,d0
@@:
	move.b	(a1)+,(a2)+
	dbra	d0,@b
mpcm_patch1:
	lea	mpcm_vol_tbl-work(a6),a1
	moveq.l	#-1,d1
	move.w	#M_SET_VOLTBL,d0
	MPCM_call
_mpcm_patch1:
	jsr	cache_flush-work(a6)
	t_dat_ok
zmsc3_mode_notouch:
	moveq.l	#-1,d0
	rts

zmusic_mode_v2						*Version 2.0xモード
	move.b	d1,zmsc_mode-work(a6)
	patch_w	BRA,pmod_wvmm_patch,store_pmod_wvmm	*波形メモリ振幅考慮無し
	patch_w	BRA,arcc_wvmm_patch,store_arcc_wvmm
	move.w	#NOP,frq_mpcm_patch
	move.w	#NOP,datatype_mpcm_patch
	move.w	#NOP,exit_gsg-work(a6)
	move.w	#NOP,get_def_velo-work(a6)
	lea	v2_volume_tbl(pc),a1
	lea	vol_tbl2-work(a6),a2
	moveq.l	#17-1,d0
@@:
	move.b	(a1)+,(a2)+
	dbra	d0,@b
mpcm_patch2:
	moveq.l	#1,d1
	move.w	#M_SET_VOLTBL,d0
	MPCM_call
_mpcm_patch2:
	jsr	cache_flush-work(a6)
	t_dat_ok

v2_volume_tbl:
	dc.b		0,7,15,23,31,39,47,55,63,71,79,87,95,103,111,119,127
v3_volume_tbl:
	dc.b		0,8,16,24,32,40,48,56,64,72,80,88,96,104,112,120,127
	.even

ask_zmsc3_mode:
	moveq.l	#0,d0
	move.b	zmsc_mode-work(a6),d0
	rts

exec_zmd:		*ZMD列の実行
	*   cmd=$7f
	* < d1.l=トラック番号(0-65534,65535:特に指定しない場合)
	* < d2.l=ZMD列の長さ(1～)
	* < a1.l=ZMD列格納アドレス(バッファ自体はd2.l+8の大きさを必要とする)
	ori.w	#$700,sr
	move.l	play_trk_tbl-work(a6),a3
@@:
	moveq.l	#0,d0
	move.w	(a3)+,d0
	cmpi.w	#-1,d0
	beq	t_illegal_track_number
	cmpi.w	#-1,d1			*特に指定しない場合
	beq	@f
	cmp.w	d0,d1
	bne	@b
@@:
	calc_wk	d0			*>a5=seq_wk_tbl n
	move.l	p_data_pointer(a5),d0
	lea	(a1,d2.l),a3
	move.b	#skip_zmd,(a3)+		*zmd
	move.b	#1,(a3)+		*mode
	rept	4
	rol.l	#8,d0
	move.b	d0,(a3)+
	endm
	move.l	a1,p_data_pointer(a5)	*ジャンプ先登録
	rts
*-----------------------------------------------------------------------------
func_end:

init_play_wk:			*演奏ワークの初期化
	movem.l	d0-d2/d4/a5,-(sp)
	move.w	trk_n_max(pc),d2
	beq	exit_ipw
	movea.l	seq_wk_tbl(pc),a5
	subq.w	#1,d2		*for dbra
	moveq.l	#0,d4		*p_type,p_ch=0
@@:
	jsr	init_wks
	move.b	#ID_DEAD,p_track_stat(a5)	*off
	clr.l	p_now_pointer(a5)
	lea	trwk_size(a5),a5
	dbra	d2,@b
exit_ipw:
	movem.l	(sp)+,d0-d2/d4/a5
	rts

init_inst_fm:				*case:FM
	* < d4.l=type,ch
	* < a4.l=opmset
	* - all
reglist	reg	d1-d2
	bset.b	d4,ii_fm_bit-work(a6)
	bne	1f
	movem.l	reglist,-(sp)
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	moveq.l	#$38,d1			*PMS/AMS
	add.b	d4,d1
	moveq.l	#0,d2
	jsr	(a4)
	cmpi.w	#7,d4			*FM8チャンネル目
	bne	@f
	moveq.l	#15,d1			*fm ch=8ならnoiseパラメータも設定
	jsr	(a4)
@@:
	move.w	(sp)+,sr
	movem.l	(sp)+,reglist
1:
	rts

init_inst_ad:				*ADPCM初期化
	* < d4.l=type,ch
	* < a5.l=seq wk n
	* - all
reglist		reg	d0-d4/a1
	movem.l	reglist,-(sp)
	move.w	ii_ad_bit(pc),d3
	bset.l	d4,d3
	bne	exit_adii
	move.w	d3,ii_ad_bit-work(a6)
	move.b	p_frq(a5),d1
	jsr	do_adpcm_frq		*周波数
	move.b	p_pan(a5),d2
	jsr	do_adpcm_pan
adii_patch:				*no mpcm でパッチ(bra exit_adii)
	move.b	p_vol(a5),d0
	andi.w	#$7f,d0
	bsr	consider_fader_ad
	jsr	do_ad_volume-work(a6)		*音量
	move.w	p_detune(a5),d1
	jsr	set_ad_tune
	lea	zero(pc),a1		*dummy((a1).b=0)
	moveq.l	#0,d1			*table type
	move.w	#M_SET_PCM,d0
	move.b	d4,d0
	MPCM_call
exit_adii:
	movem.l	(sp)+,reglist
	rts

ii_bit_work:
ii_fm_bit:	dc.w	0
ii_ad_bit:	dc.w	0
ii_m0_bit:	dc.w	0
ii_m1_bit:	dc.w	0
ii_mr0_bit:	dc.w	0
ii_mr1_bit:	dc.w	0

init_inst_md:				*MIDIのケース
	* < d4.l=type,ch
	* < a5.l=seq wk n
	* - all
reglist		reg	d0-d4/a1-a2/a4
	movem.l	reglist,-(sp)
	move.l	d4,d0
	swap	d0
	add.w	d0,d0
	move.l	p_midi_trans(a5),a2
	lea	ii_m0_bit(pc,d0.w),a4
	move.w	(a4),d3
	bset.l	d4,d3
	bne	exit_ii
	move.w	d3,(a4)
	moveq.l	#$b0,d2
	or.b	d4,d2		*program change($cn)
	move.b	d2,d0
	jsr	(a2)

	lea	initmidiouttbl(pc),a1
@@:
	move.b	(a1)+,d0
	bmi	@f
	jsr	(a2)
	bra	@b
@@:
	moveq.l	#$65,d0
	jsr	(a2)		*RPN H
	moveq.l	#$00,d0
	jsr	(a2)

	moveq.l	#$64,d0
	jsr	(a2)		*RPN L
	moveq.l	#$00,d0
	jsr	(a2)

	moveq.l	#$06,d0		*PITCH BEND RANGEを設定する
	jsr	(a2)
	move.b	p_@b_range(a5),d0
	jsr	(a2)

	moveq.l	#$07,d0
	jsr	(a2)
	move.b	p_vol(a5),d0
	jsr	(a2)		*volume set

	moveq.l	#10,d0
	jsr	(a2)
	move.b	p_pan(a5),d0
	jsr	(a2)		*panpot set

	moveq.l	#64,d0
	jsr	(a2)
	move.b	p_damper(a5),d0
	jsr	(a2)		*damper

	add.b	#$30,d2		*bender($en)
	move.b	d2,d0
	jsr	(a2)
	move.w	p_detune(a5),d0
	add.w	#8192,d0
	move.w	d0,d1
	andi.b	#127,d0		*lower.b
	lsr.w	#7,d1		*higher.b
	jsr	(a2)		*lower @b
	move.b	d1,d0
	jsr	(a2)		*higher @b
exit_ii:
	movem.l	(sp)+,reglist
	rts

initmidiouttbl:
	dc.b	$79,$00		*reset all controllers
	dc.b	$7c,0		*omni mode off
	dc.b	$7f,0		*poly mode on
	dc.b	$7a,$7f		*local on
	dc.b	$65,0		*RPN H
	dc.b	$64,1		*RPN L
	dc.b	$06,$40		*FINE TUNINGをニュートラルへ(H)
	dc.b	$26,0		*FINE TUNINGをニュートラルへ(L)
	dc.b	$65,0		*RPN H
	dc.b	$64,2		*RPN L
	dc.b	$06,$40		*COURSE TUNINGをニュートラルへ
	dc.b	$01,$00		*modulation off
	dc.w	-1

all_key_off:				*全チャンネルをノートオフする
	* - all
reglist	reg	d0-d2/d4/a0/a2-a4
	movem.l	reglist,-(sp)
					*FM
	moveq.l	#8-1,d4
@@:
	bsr	ako_fm
	dbra	d4,@b
	moveq.l	#15,d1
	moveq.l	#0,d2
	bsr	opmset			*NOISE OFF
					*ADPCM
	moveq.l	#16-1,d4
@@:
	bsr	ako_adpcm
	dbra	d4,@b
nmdb9:					*nmdb!!(patched to be bra exit_ako0)
					*拡張ＭＩＤＩ部処理
	lea	midi_if_tbl(pc),a0
ako_lp01:
	moveq.l	#0,d0
	move.b	(a0)+,d0
	bmi	exit_ako0
	move.w	ako_j_tbl(pc,d0.w),d0
	lea	ako_j_tbl(pc,d0.l),a2
	moveq.l	#16-1,d4
@@:
	bsr	ako_midi
	dbra	d4,@b
	bra	ako_lp01
exit_ako0:
	movem.l	(sp)+,reglist
	rts
ako_j_tbl:
	dc.w	m_out_m0-ako_j_tbl
	dc.w	m_out_m1-ako_j_tbl
	dc.w	m_out_r0-ako_j_tbl
	dc.w	m_out_r1-ako_j_tbl

nmdb4:					*nmdb!!(patched to be RTS)
ako_midi:
	moveq.l	#$b0,d0
	or.w	d4,d0
	jsr	(a2)
	moveq.l	#$78,d0
	jsr	(a2)
	moveq.l	#$00,d0
	jmp	(a2)				*all sound off

ako_fm:
	moveq.l	#8,d1
	move.l	d4,d2
	bsr	opmset			*fm key off

*	moveq.l	#$60,d1			*TL
*	add.w	d2,d1
*	moveq.l	#127,d2			*v=0
*	moveq.l	#4-1,d0
*@@:
*	bsr	opmset
*	addq.w	#8,d1
*	dbra	d0,@b

	moveq.l	#$e0,d1			*RR
	add.w	d2,d1
	moveq.l	#$ff,d2
	moveq.l	#4-1,d0
@@:
	bsr	opmset
	addq.w	#8,d1
	dbra	d0,@b
	rts

ako_adpcm:
	tst.b	se_mode-work(a6)
	bmi	@f
ako_ad_patch:				*STD PCMDRVの場合はパッチが当たる(bra adpcm_end)
	move.w	#M_KEY_OFF,d0
	move.b	d4,d0
	MPCM_call
@@:
	rts

top_ptr_set:			*データ領域の先頭アドレスをワークへセットする
	* < d0.l=trk_number
	* > a5.l=seq_wk_tbl n
	* x a4
reglist	reg	d0-d1/d4/a1-a2
	movem.l	reglist,-(sp)
	move.l	d0,d1
	calc_wk	d0
	movea.l	trk_po_tbl(pc),a2
	lsl.l	#trk_tbl_size_,d1
	add.l	d1,a2
	do_top_ptr_set	0
	movem.l	(sp)+,reglist
	rts

do_calc_tmm:
	* < d2.w=tempo_value.w=tempo
	* > d1.w=timer m value
	* d0,a1,a6破壊禁止
	move.l	d0,-(sp)
	move.l	#30*1000*1000,d0	*１分=60*1000000μｓ
	move.w	mst_clk(pc),d1
	mulu	d2,d1
	bsr	wari			*d0/d1=d0...d1
	move.l	d0,d1
	move.l	(sp)+,d0
	cmpi.l	#$3fff,d1
	bhi	@f
	andi.w	#$3fff,d1
	rts
@@:
	move.w	#$3fff,d1
	rts

do_calc_tmb:
	* < d2.w=tempo_value.w=tempo
	* > d1.w=timer a value
	* a1,a6破壊禁止
	move.l	d0,-(sp)
	lsl.w	#4,d2

	moveq.l	#0,d1
	move.w	mst_clk(pc),d1
	move.l	#(16*4000*60000)>>8,d0
	bsr	wari		*d0=d0/d1
				*d0=16*4000*60000/(1024*(mst_clk/4))
	divu	d2,d0
	bvs	tmp_err
	swap	d0
	tst.w	d0		*余りがあるか
	beq	@f
	add.l	#$0001_0000,d0	*余りがあるなら切り上げ
@@:
	swap	d0		*d0.w=answer
	move.w	#256,d1
	sub.w	d0,d1
	bcc	@f
	moveq.l	#0,d1
@@:
	movem.l	(sp)+,d0	*わざとmovem
	rts

tmp_err:
	move.l	(sp)+,d0
	moveq.l	#-1,d1
	rts

calc_timer:			*テンポ値をタイマーの設定値へ変換しワークへセット
	movem.l	d0-d2,-(sp)
	move.w	tempo_value(pc),d2
calc_timer_patch:		*ここはタイマーモードによって書き変わる
	bsr.w	do_calc_tmm
	bmi	@f
	move.w	d1,timer_value-work(a6)
@@:
	movem.l	(sp)+,d0-d2
	rts

calc_timer_se:			*テンポ値をタイマーBの設定値へ変換しワークへセット
	movem.l	d0-d2,-(sp)
	move.w	tempo_value_se(pc),d2
calc_timer_se_patch:		*ここはタイマーモードによって書き変わる
	bsr.w	do_calc_tmb
	bmi	@f
	move.w	d1,timer_value_se-work(a6)
@@:
	movem.l	(sp)+,d0-d2
	rts

do_calc_tma:			*テンポ値(77～300)をタイマーAの設定値へ変換する
	* < d2.w=tempo_value.w=tempo
	* > d1.w=timer a value
	* a1,a6使用禁止
	move.l	d0,-(sp)
	moveq.l	#0,d1
	move.w	mst_clk(pc),d1
	move.l	#(16*4000*60000)>>8,d0
	bsr	wari		*d0=d0/d1
				*d0=16*4000*60000/(1024*(mst_clk/4))
	divu	d2,d0
	bvs	tmp_err
	move.w	#1024,d1
	sub.w	d0,d1
	bcc	@f
	moveq.l	#0,d1
@@:
	movem.l	(sp)+,d0	*わざとmovem
	rts

init_timer_a_se:			*タイマーAの初期化
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	move.w	timer_value_se(pc),d2	*timer A value
	moveq.l	#$11,d1
	bsr	opmset
	bra	ita00

init_timer_a:			*タイマーAの初期化
	move.w	timer_value(pc),d2	*timer A value
_init_timer_a:			*タイマーAの初期化
	* < d2.w=timer value
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	moveq.l	#$11,d1
	bsr	opmset
ita00:
	moveq.l	#$10,d1
	lsr.w	#2,d2
	bsr	opmset
	move.w	tm_ab_reset(pc),d2
	ori.b	#%0011_0000,d2
	ori.b	#%0001_0101,timer_mask-work(a6)
	moveq.l	#$14,d1
	bsr	opmset
	bset.b	#b_tma_flg,timer_flg-work(a6)
	move.w	(sp)+,sr
	rts

init_timer:
	nop			*FNC control_tempoでパッチ(RTS)が当たる
_init_timer:			*使用タイマによってパッチが当たる
init_timer_m:			*MIDIタイマーの初期化
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	pea	(a0)
	lea	rgr,a0
	move.w	timer_value(pc),d1
	ori.w	#$8000,d1
	move.b	#$8,(a0)
	midiwait
	move.b	d1,grp4-rgr(a0)
	midiwait
	ror.w	#8,d1
	move.b	d1,grp5-rgr(a0)
	midiwait
	clr.b	(a0)
	midiwait
	tas.b	r06_0-work(a6)	*int on
	move.b	r06_0(pc),grp6-rgr(a0)
	midiwait
	move.l	(sp)+,a0
	bset.b	#b_tmm_flg,timer_flg-work(a6)
	move.w	(sp)+,sr
	rts

init_timer_e:			*外部シーケンサがホスト
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	pea	(a0)
	lea	rgr,a0

	move.b	#$07,(a0)
	midiwait
	move.b	itpl_rate-work(a6),grp5-rgr(a0)
	midiwait

	clr.b	(a0)
	midiwait
	ori.b	#%0000_0101,r06_0-work(a6)	*int on
	move.b	r06_0(pc),grp6-rgr(a0)
	midiwait

	move.l	(sp)+,a0
	bset.b	#b_tmm_flg,timer_flg-work(a6)
	move.w	(sp)+,sr
	rts

init_timer_se:				*使用タイマによってパッチが当たる
init_timer_b_se:			*タイマーBの初期化
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	move.w	timer_value_se(pc),d2	*timer B value
	bra	itb00

init_timer_b:			*タイマーBの初期化
	move.w	timer_value(pc),d2	*timer B value
_init_timer_b:			*タイマーBの初期化
	* < d2.w=timer value
	move.w	sr,-(sp)
	ori.w	#$0700,sr
itb00:
	moveq.l	#$12,d1
	bsr	opmset
	move.w	tm_ab_reset(pc),d2
	ori.b	#%0011_0000,d2
	ori.b	#%0010_1010,timer_mask-work(a6)
	moveq.l	#$14,d1
	bsr	opmset
	bset.b	#b_tmb_flg,timer_flg-work(a6)
	move.w	(sp)+,sr
	rts

stop_timer_a:
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	movem.l	d1-d2,-(sp)
	moveq.l	#$14,d1
	move.w	tm_ab_reset-work(a6),d2
	andi.b	#%0001_1010,d2
	andi.b	#%0011_1010,timer_mask-work(a6)
	bsr	opmset			*int mask
	bclr.b	#b_tma_flg,timer_flg-work(a6)
	movem.l	(sp)+,d1-d2
	move.w	(sp)+,sr
	rts

stop_timer_b:
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	movem.l	d1-d2,-(sp)
	moveq.l	#$14,d1
	move.w	tm_ab_reset-work(a6),d2
	andi.b	#%0010_0101,d2
	andi.b	#%0011_0101,timer_mask-work(a6)
	bsr	opmset			*int mask
	bclr.b	#b_tmb_flg,timer_flg-work(a6)
	movem.l	(sp)+,d1-d2
	move.w	(sp)+,sr
	rts

stop_timer:				*使用タイマによってパッチが当たる
	* - all
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	clr.b	rgr
	midiwait
	andi.b	#$7f,r06_0-work(a6)	*int stop
	move.b	r06_0(pc),grp6
	midiwait
	bclr.b	#b_tmm_flg,timer_flg-work(a6)
	move.w	(sp)+,sr
	rts

stop_timer_se:				*使用タイマによってパッチ(bra stop_timer_a)が当たる
	bra.w	stop_timer_b

play_beep:				*BEEP音を鳴らす
	move.w	sr,-(sp)
	ori.w	#$700,sr
	move.l	d0,-(sp)
	move.w	#$07,-(sp)
	clr.w	-(sp)
	DOS	_CONCTRL
	addq.w	#4,sp
	move.l	(sp)+,d0
	move.w	(sp)+,sr
	rts

copy_key:			*COPY key operation
	move.l	d0,-(sp)
	move.w	sr,d0
	andi.w	#$700,d0
	movem.l	(sp)+,d0	*わざとmovem
	bne	@f
	move.l	copy_org(pc),-(sp)
	rts
@@:
	rte

abortjob:
	move.w	sr,-(sp)
	ori.w	#$700,sr
	movem.l	d0/d3/a0,-(sp)
	move.l	#ID_TEMP,d3
	Z_MUSIC	#ZM_FREE_MEM2	*TEMPメモリブロック削除
	movem.l	(sp)+,d0/d3/a0
	move.w	(sp)+,sr
	move.l	abortjob_org(pc),-(sp)
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

kakuchoshi:			*拡張子がなければ設定
	* < a0=filename address
	* < a1=拡張子アドレス
	* X a0
	bsr	skip_peri
	moveq.l	#91-1,d0
kkchs_lp:
	move.b	(a0)+,d0
	beq	do_kkchs
	cmpi.b	#'.',d0
	beq	find_period
	dbra	d0,kkchs_lp
do_kkchs:
	subq.l	#1,a0
	move.b	#'.',(a0)+
	move.b	(a1)+,(a0)+
	move.b	(a1)+,(a0)+
	move.b	(a1)+,(a0)+
	clr.b	(a0)
	rts
find_period:
	cmpi.b	#' ',(a0)
	bls	do_kkchs	*'.'はあっても拡張子がないケース
	rts

	.include	fopen.s

get_fsize2:			*ファイルサイズの偶数調整をする
	* < d5.w=file handle
	* > d3.l=data size
	* > mi=err
	* X d0
	* - d5
	move.w	#2,-(sp)	*ファィルの長さを調べる
	clr.l	-(sp)
	move.w	d5,-(sp)
	DOS	_SEEK
 	addq.w	#8,sp		*d0.l=file length
	addq.l	#1,d0
	bclr.l	#0,d0		*.even
	bra	gf0

fname_chk:
	* < a3.l=last_fn addr
	* > eq=same
	* > mi=not same
	movem.l	d0/a0/a3,-(sp)
	lea.l	file_info_buf(pc),a0
	moveq.l	#53-1,d0
@@:
	cmpm.b	(a0)+,(a3)+
	bne	@f
	dbra	d0,@b
	moveq.l	#0,d0
@@:
	movem.l	(sp)+,d0/a0/a3
	rts

cache_flush:				*キャッシュのフラッシュ
	movem.l	d0-d1,-(sp)
	moveq.l	#3,d1
	IOCS	_SYS_STAT
	movem.l	(sp)+,d0-d1
	rts

	.include	work.s
	.include	zmsc_int.s

bil_prta1:				*日本語対応
	tst.b	errmes_lang-work(a6)	*0:英語か 1:日本語か
	beq	prta1
@@:					*次のメッセージをゲット
	tst.b	(a1)+
	bne	@b
prta1:
	move.w	#2,-(sp)
	pea	(a1)
	DOS	_FPUTS
	addq.w	#6,sp
	rts

dev_init:				*デバイスドライバとしての初期化
	movem.l	d1/a1/a6,-(sp)
	lea	work,a6
	lea	cannot_reg(pc),a1
	bsr	bil_prta1
	movem.l	(sp)+,d1/a1/a6
	jmp	not_com

exec:				*コマンドラインから実行した時
	lea	work,a6
	clr.l	-(sp)
	DOS	_SUPER			*スーパーバイザーへ
	addq.w	#4,sp
	move.l	d0,ssp-work(a6)
	move.l	sp,_sp_buf-work(a6)

	move.l	a0,a0work-work(a6)
	move.l	a1,a1work-work(a6)

	tst.b	$0cbc.w			*MPUが68000ならキャッシュフラッシュ必要無し
	bne	@f
	move.w	#RTS,cache_flush-work(a6)
@@:
	movea.l	a2,a4
	addq.w	#1,a4

	DOS	_VERNUM
	cmpi.w	#$0300,d0
	bcs	Human_ver_err

	bsr	chk_board		*CHECK MIDI BOARD

	bsr	get_work_area0		*> a1.l=last address of this prog.
	bne	resigned
*	lea	$10(a0),a0		*メモリブロックの変更
*	suba.l	a0,a1
*	pea	(a1)
*	pea	(a0)
*	DOS	_SETBLOCK
*	addq.w	#8,sp
*	tst.l	d0
*	bmi	resigned		*out of memory

*!	tst.b	-1(a4)			*スイッチ処理
*!	bne	@f
	pea	zmsc3_opt(pc)
	jsr	search_env-work(a6)
	addq.w	#4,sp
	tst.l	d0
	beq	@f
	move.l	a4,-(sp)
	move.l	d0,a4
	bsr	chk_optsw
	move.l	(sp)+,a4
@@:
	bsr	chk_optsw

	bsr	chk_drv
	beq	exit_ooZ		*すでに常駐している

	bsr	get_work_area1		*> a1.l=last address of this prog.
	move.l	a0work-work(a6),a0
	lea	$10(a0),a0		*メモリブロックの変更
	suba.l	a0,a1
	pea	(a1)
	pea	(a0)
	DOS	_SETBLOCK
	addq.w	#8,sp
	tst.l	d0
	bmi	resigned		*out of memory

	bsr	set_patch

	moveq.l	#trk_n_max_default,d5
	move.w	d5,trk_n_max-work(a6)
	jbsr	spread_trk_n
	bmi	resigned		*out of memory

	bsr	set_vect
	bne	exit_oo			*(既に登録住み)
	bsr	prt_keep_info
	bsr	set_dev_name
	bmi	unknown_err
	jsr	init_all-work(a6)

	tst.b	pcm_read_flg-work(a6)
	beq	@f
	bsr	do_block_read
@@:
	tst.b	stup_read_flg-work(a6)		*スタートアップファイルの読み込み
	beq	@f
	bsr	read_start_up
@@:
	move.l	ssp-work(a6),a1
	IOCS	_B_SUPER

	move.l	dev_end_adr-work(a6),d0
	lea	begin_of_prog,a0
	sub.l	a0,d0			*常駐サイズ

	clr.w	-(sp)
	move.l	d0,-(sp)		*for KEEPPR
	DOS	_KEEPPR			*常駐終了

unknown_err:
	lea	unknown_mes(pc),a1
err_exit:
	bsr	prt_title
	bsr	bil_prta1
	move.l	ssp-work(a6),a1
	IOCS	_B_SUPER	*ユーザーモードへ戻る

	move.w	#1,-(sp)
	DOS	_EXIT2

do_block_read:			*立ち上げ時にデータをリード
	lea	stup_zpdfn-work(a6),a1
	jsr	register_zpd-work(a6)
	tst.l	d0
	bne	exit_bdr
dbrp:
	bsr	mes_head
	lea	default_adp-work(a6),a1	*読み込み正常完了
	bra	bil_prta1
exit_bdr:
	bsr	mes_head
	lea	cannot_read-work(a6),a1
	bra	bil_prta1

mes_head:
	move.l	a1,-(sp)
	lea	read_mes1-work(a6),a1
	bsr	prta1
	lea	stup_zpdfn-work(a6),a1
	bsr	prta1
	move.l	(sp)+,a1
	rts

mes_head2:
	move.l	a1,-(sp)
	lea	read_mes2-work(a6),a1
	bsr	prta1
	lea	stup_fnsv-work(a6),a1
	bsr	prta1
	move.l	(sp)+,a1
	rts

read_start_up:				*立ち上げ時にデータをリード(その２)
	lea.l	stup_fnsv-work(a6),a2
	jsr	fopen-work(a6)		*(ret:d5=file handle)
	jsr	get_fsize-work(a6)	*>d3.l=size
	move.l	d3,d2
	move.l	d3,d4			*size(自己出力時に使用)
	move.l	#ID_STARTUP,d3
	jsr	get_mem-work(a6)	*>a0.l=address,d2.l=lw border length
	tst.l	d0
	bmi	su_not_ok
	move.l	a0,a4			*addr(自己出力時に使用)

	move.w	sr,-(sp)
	andi.w	#$f8ff,sr
	move.l	d4,-(sp)	*push size
	move.l	a4,-(sp)	*push addr
	move.w	d5,-(sp)	*file handle
	DOS	_READ		*サンプリングデータの読み込み
	lea	10(sp),sp
	move.w	(sp)+,sr

	move.w	d5,-(sp)	*close
	DOS	_CLOSE
	addq.w	#2,sp

	*.mddかどうかチェックする
@@:
	move.b	(a2)+,d0
	beq	not_mdd
	cmpi.b	#'.',d0
	bne	@b
	move.b	(a2)+,d0
	andi.b	#$df,d0
	cmpi.b	#'M',d0
	bne	not_mdd
	move.b	(a2)+,d0
	andi.b	#$df,d0
	cmpi.b	#'D',d0
	bne	not_mdd
	move.b	(a2)+,d0
	andi.b	#$df,d0
	cmpi.b	#'D',d0
	beq	nmdb10
not_mdd:
	pea	su_ok(pc)		*戻り番地
	movem.l	reg_zm_dev,-(sp)
	jmp	dev_out_chk
nmdb10:					*nmdb!!
	cmpi.w	#$0d0a,(a4)		*header check
	bne	su_not_ok
	cmpi.b	#$1a,-1(a4,d4.l)	*endcode check
	bne	su_not_ok
	move.l	a4,a1
	moveq.l	#0,d2
	moveq.l	#-1,d1			*current MIDI I/F
	jbsr	midi_transmission
su_ok:					*スタートアップ組み込み成功
	move.l	a4,a1
	jsr	free_mem-work(a6)
surp:					*-GでRTSに
	bsr	mes_head2
	lea	default_adp-work(a6),a1	*読み込み正常完了
	bra	bil_prta1

su_not_ok:				*スタートアップ組み込み失敗
	bsr	mes_head2
	lea	cannot_read-work(a6),a1
	bra	bil_prta1

title_mes:			*使い捨てのワーク群(後にグローバルワークとして使用される)
	dc.b	'Z-MUSIC PERFORMANCE MANAGER '
	dc.b	$F3,'I',$F3,'N',$F3,'T',$F3,'E',$F3,'G',$F3,'R',$F3,'A',$F3,'L '
	dc.b	$F3,'V',$F3,'E',$F3,'R',$F3,'S',$F3,'I',$F3,'O',$F3,'N'
	version
	TEST
	dc.b	' (C) 1991,98 '
	dc.b	'ZENJI SOFT',13,10,0
yes_midi:	dc.b	"MIDI/",0
no_midi:	dc.b	"FM･OPM/ADPCM are under the control of Z-MUSIC.",13,10,0
		dc.b	"FM･OPM/ADPCMがZ-MUSICの管理下に入りました.",13,10,0
no_midi_:	dc.b	"FM･OPM/ADPCM/MPCM.X are under the control of Z-MUSIC.",13,10,0
		dc.b	"FM･OPM/ADPCM/MPCM.XがZ-MUSICの管理下に入りました.",13,10,0
already_mes:	dc.b	'An application which cannot cooperate with Z-MUSIC has been included.',13,10,0
		dc.b	'協調不可能のアプリケーションが常駐しています.',13,10,0
already_mesZ:	dc.b	'Z-MUSIC PERFORMANCE MANAGER was already included.',13,10,0
		dc.b	'Z-MUSIC演奏マネージャはすでに常駐しています.',13,10,0
already_mes2:	dc.b	"An unidentified ADPCM driver has been included.",13,10,0
		dc.b	'認識不可能のADPCMドライバが常駐しています.',13,10,0
already_mes_mp:	dc.b	'MPCM denies Z-MUSIC occupation.',13,10,0
		dc.b	'MPCMがZMUSICによる占有を拒否しました.',13,10,0
out_mem_mes:	dc.b	'Out of memory error.',13,10,0
		dc.b	'メモリが不足しています.',13,10,0
devoffline_mes:	dc.b	'Interface Device is not ready.',13,10,0
		dc.b	'未接続のインターフェースを指定しました.',13,10,0
redefinit_mes:	dc.b	'Interface Device sequence error.',13,10,0
		dc.b	'同一インターフェースを複数回指定しました.',13,10,0
os_too_old_mes:	dc.b	"Z-MUSIC SYSTEM ver.3.0 runs on Human68k ver.3.00 and over.",13,10,0
		dc.b	'Z-MUSICシステム ver.3.0はHuman68k ver.3.00以上で動作します.',13,10,0
cannot_reg:	dc.b	13,10,'ZMSC3.X cannot be registered from CONFIG.SYS.',13,10,0
cannot_reg_j:	dc.b	13,10,'ZMSC3.XはCONFIG.SYSから登録することは出来ません.',13,10,0
kakuho_mes:	dc.b	'kByte(s)',$1b,'[m ',0
*atrb_0010:	dc.b	$1b,'[32m',0
tm___mes:	dc.b	'TEMPO SOURCE:',0
tm_a_mes:	dc.b	'YM2151 TIMER A',13,10,0
tm_b_mes:	dc.b	'YM2151 TIMER B',13,10,0
tm_m_mes:	dc.b	'YM3802 TIMER',13,10,0
*atrb_rev:	dc.b	$1b,'[m',13,10,0
mif_bar:	dc.b	'MIDI INTERFACE ',0
mif_tbl:	dc.b	'YM3802-1',13,10,0
		dc.b	'YM3802-2',13,10,0
		dc.b	'RS-MIDI1',13,10,0
		dc.b	'RS-MIDI2',13,10,0
sq_m_mes0:	dc.b	'External MIDI devices will be synchronized with Z-MUSIC.',13,10,0
		dc.b	'外部MIDI機器がZ-MUSICと同期します.',13,10,0
sq_m_mes1:	dc.b	'Z-MUSIC will be synchronized with External MIDI devices.',13,10,0
		dc.b	'Z-MUSICが外部MIDI機器と同期します.',13,10,0
kaijo:		dc.b	'Z-MUSIC PERFORMANCE MANAGER has been released from the system.',13,10,0
		dc.b	'Z-MUSIC演奏マネージャは常駐解除されました.',13,10,0
not_kep_mes:	dc.b	'Z-MUSIC PERFORMANCE MANAGER is not kept in the system.',13,10,0
		dc.b	'Z-MUSIC演奏マネージャは常駐していません.',13,10,0
rls_er_mes:	dc.b	'Z-MUSIC PERFORMANCE MANAGER is unable to release.',13,10,0
		dc.b	'Z-MUSIC演奏マネージャは常駐解除できません.',13,10,0
ocp_zc_er_mes:	dc.b	'Z-MUSIC COMPILER is occupied by some other application.',13,10,0
		dc.b	'Z-MUSICコンパイラが他のアプリケーションに占有されています.',13,10,0
ocp_zm_er_mes:	dc.b	'Z-MUSIC PERFORMANCE MANAGER is occupied by some other application.',13,10,0
		dc.b	'Z-MUSIC演奏マネージャが他のアプリケーションに占有されています.',13,10,0
ver_er_mes:	dc.b	'Illegal version number. Unable to release.',13,10,0
		dc.b	'バージョンが異なるため常駐解除はできません.',13,10,0
unknown_mes:	dc.b	'Unknown error.',13,10,0
		dc.b	'正体不明のエラーです.',13,10,0
help_mes:
	dc.b	'< USAGE >'
	dc.b	' ZMSC.X [Optional Switches]',13,10
	dc.b	'< OPTIONAL SWITCHES >',13,10
	dc.b	'-? or H      Display the list of optional switches.',13,10
	dc.b	'-2           Ver.2.0 compatible mode.',13,10
	dc.b	'-A           Make Z-MUSIC work under OPM･TIMER-A.',13,10
	dc.b	'-B           Make Z-MUSIC work under OPM･TIMER-B.',13,10
	dc.b	'-C           Single RS232C-MIDI mode.',13,10
	dc.b	'-E           Synchronize an external MIDI sequencer.',13,10
	dc.b	'-F<n>        Prepare n tracks for sound effect mode.(default=0)',13,10
	dc.b	'-G           No message will be displayed.',13,10
	dc.b	'-I<n>        Establish the sequence of MIDI I/F.(default=1234)',13,10
	dc.b	'-J           Messages will be displayed in Japanese.',13,10
	dc.b	'-N           No initializing mode.',13,10
	dc.b	'-P           Disable to send polyphonic pressure message.',13,10
	dc.b	'-R           Release Z-MUSIC from the system.',13,10
	dc.b	'-S<filename> Include start-up file.',13,10
	dc.b	'-W           Dual RS232C-MIDI mode.',13,10
	dc.b	'-X<n>        Wait n/60[sec.] after sending EOX.(default=3)',13,10
	dc.b	'-Y<n>        Set Time Valiable of SCC(RS-MIDI).(default=3)',13,10
	dc.b	'-Z<filename> Include ZPD(ADPCM block data).',13,10
	dc.b	0
	dc.b	'< 使用方法 >'
	dc.b	' ZMSC.X [Optional Switches]',13,10
	dc.b	'< オプションスイッチ >',13,10
	dc.b	'-? or H      ヘルプ表示.',13,10
	dc.b	'-2           Ver.2.0コンパチモード',13,10
	dc.b	'-A           演奏制御割り込みにOPM･TIMER-Aを使用します.',13,10
	dc.b	'-B           演奏制御割り込みにOPM･TIMER-Bを使用します.',13,10
	dc.b	'-C           シングルRS232C-MIDIモード',13,10
	dc.b	'-E           外部MIDI機器をZ-MUSICと同期させます.',13,10
	dc.b	'-F<n>        効果音トラックとしてnトラック確保します.(default=0).',13,10
	dc.b	'-G           メッセージを表示しません',13,10
	dc.b	'-I<n>        使用するMIDI I/Fの順序を定義します.(deault=1234)',13,10
	dc.b	'-J           日本語メッセージモード.',13,10
	dc.b	'-N           初期化なしモード.',13,10
	dc.b	'-P           ポリフォニックプレッシャーを送信しません.',13,10
	dc.b	'-R           Z-MUSICの常駐を解除します.',13,10
	dc.b	'-S<filename> スタートアップファイルを組み込みます.',13,10
	dc.b	'-W           デュアルRS232C-MIDIモード.',13,10
	dc.b	'-X<n>        EOX送信後n/60[sec.]待ちます.(default=3)',13,10
	dc.b	'-Y<n>        SCC(RS-MIDI)の時定数を設定します.(default=3)',13,10
	dc.b	'-Z<filename> ZPD(ADPCM block data)を組み込みます.',13,10
	dc.b	0
zmsc3_opt:	dc.b	'zmsc3_opt',0
	.even

exit_ooZ:
	lea	already_mesZ(pc),a1
	bra	err_exit
exit_oo:			*すでに常駐または常駐不可
	tst.l	d0
	bpl	@f
	lea	already_mes(pc),a1
	bra	err_exit
@@:
	lea	already_mes2(pc),a1	*COULDN'T SET INT ADPCM VECT
	subq.w	#1,d0
	beq	err_exit
	lea	already_mes_mp(pc),a1	*COULDN'T OCCUPY MPCM
	bra	err_exit

already_keptZ:
	lea	already_mesZ(pc),a1	*ZMUSIC already included
	bra	ak_prt
already_kept:
	tst.l	d0
	bpl	@f
	lea	already_mes(pc),a1	*COULDN'T SET ZMUSIC VECT
	bra	ak_prt
@@:
	lea	already_mes2(pc),a1	*COULDN'T SET INT ADPCM VECT
	subq.w	#1,d0
	beq	ak_prt
	lea	already_mes_mp(pc),a1	*COULDN'T OCCUPY MPCM
ak_prt:
	bsr	bil_prta1
	movem.l	(sp)+,d1-d7/a0-a6
	jmp	not_com

chk_optsw:				*スイッチ処理
	* < cmd_or_dev  0:device / $ff:command
chk_optsw_lp:
	move.b	(a4)+,d0
	beq	no_more?
	cmpi.b	#' ',d0
	beq	chk_optsw_lp
	cmpi.b	#'-',d0		*その他スイッチ処理へ
	beq	other_sw
	cmpi.b	#'/',d0
	beq	other_sw
	bra	chk_optsw_lp

no_more?:			*もうこれ以上スイッチは無しか
	rts

other_sw:			*その他のスイッチ
	move.b	(a4)+,d0
	beq	no_more?
	cmpi.b	#'?',d0		*diplay help message
	beq	prt_help
	cmpi.b	#'2',d0		*V2コンパチモードの設定
	beq	v2_compatible_mode
	jsr	mk_capital-work(a6)
	cmpi.b	#'A',d0		*timer a mode
	beq	set_timer_a_mode
	cmpi.b	#'B',d0		*timer_b mode
	beq	set_timer_b_mode
	cmpi.b	#'C',d0		*シングルRS232C-MIDI MODE
	beq	set_single_rs232c_mode
	cmpi.b	#'E',d0		*外部同期モード
	beq	synchro_on
	cmpi.b	#'F',d0		*効果音モードの設定
	beq	se_mode_cnf
	cmpi.b	#'G',d0		*タイトル表示なしモード
	beq	non_title
	cmpi.b	#'H',d0		*diplay help message
	beq	prt_help
	cmpi.b	#'I',d0		*MIDIインターフェースの設定
	beq	midi_assign
	cmpi.b	#'J',d0		*エラーメッセージの言語
	beq	set_err_lang
	cmpi.b	#'N',d0		*初期化無しモード
	beq	no_init
	cmpi.b	#'P',d0		*ポリフォニックプレッシャー無し
	beq	kill_poly_pres
	cmpi.b	#'R',d0		*解除
	beq	release
	cmpi.b	#'S',d0		*start up
	beq	start_up
	cmpi.b	#'V',d0		*チャンネルワークなしにする
	beq	kill_ch_wk
	cmpi.b	#'W',d0		*RS232C mode
	beq	set_dual_rs232c_mode
	cmpi.b	#'X',d0		*EOX wait
	beq	get_eoxw
	cmpi.b	#'Y',d0		*RS232C SCC 時定数設定
	beq	set_rs232c_bpsv
	cmpi.b	#'Z',d0		*ADPCM DATA READ
	beq	block_read
	bra	prt_help

kill_ch_wk:	*'-V'	(チャンネルワークを無効にする)
		*	(-1=all(default),0=kill fm(通常禁止),
		*	  1=kill midi,2=kill all(通常禁止))
	clr.b	ch_wk_mode-work(a6)
	bsr	chk_num
	bmi	chk_optsw_lp
	bsr	asc_to_n
	move.b	d1,ch_wk_mode-work(a6)
	bra	chk_optsw_lp

se_mode_cnf:		*'-F'	(効果音トラックに何トラック使うか)
	move.w	#4,se_tr_max-work(a6)	*デフォルト=4
	bsr	chk_num
	bmi	chk_optsw_lp
	bsr	asc_to_n
	cmpi.l	#tr_max,d1
	bhi	chk_optsw_lp
	move.w	d1,se_tr_max-work(a6)
	bra	chk_optsw_lp

no_init:			*'-N'
	st.b	no_init_mode-work(a6)
	bra	chk_optsw_lp

kill_poly_pres:			*'-P'
	clr.b	polypress_mode-work(a6)
	bra	chk_optsw_lp

v2_compatible_mode:
	move.b	#2,zmsc_mode-work(a6)
	bra	chk_optsw_lp

set_dual_rs232c_mode:
	bset.b	#if_mr0,midi_board-work(a6)
	bset.b	#if_mr1,midi_board-work(a6)
	lea	midi_if_tbl-work(a6),a0
1:						*インターフェーステーブルにも登録
	move.b	(a0)+,d0
	bpl	1b
	cmpi.b	#-1,d0
	beq	1f
	cmpi.b	#$80+if_mr0*2,d0
	bne	@f
	move.b	#if_mr0*2,-1(a0)
	bra	1b
@@:
	cmpi.b	#$80+if_mr1*2,d0
	bne	1b
	move.b	#if_mr1*2,-1(a0)
	bra	1b
1:
	tas.b	rs232c_mode-work(a6)		*dual
	move.l	#NOP_NOP,rs_check_patch
	jsr	cache_flush-work(a6)
	bra	chk_optsw_lp

set_single_rs232c_mode:
	bset.b	#if_mr0,midi_board-work(a6)
	lea	midi_if_tbl-work(a6),a0
1:						*インターフェーステーブルにも登録
	move.b	(a0)+,d0
	bpl	1b
	cmpi.b	#-1,d0
	beq	1f
	cmpi.b	#$80+if_mr0*2,d0
	bne	1b
	move.b	#if_mr0*2,-1(a0)
	bra	1b
1:
	bclr.b	#7,rs232c_mode-work(a6)		*single
	bne	prt_help			*すでに-Wを指定しているのにおかしい
	move.l	#NOP_NOP,rs_check_patch
	jsr	cache_flush-work(a6)
	bra	chk_optsw_lp

set_rs232c_bpsv:
	bsr	chk_num
	bmi	prt_help
	cmpi.b	#'-',(a4)
	beq	prt_help
	bsr	asc_to_n
	andi.b	#$0f,d1
	move.b	d1,bps_v
	or.b	d1,rs232c_mode-work(a6)		*一応格納
	bra	chk_optsw_lp

non_title:
	move.l	#$7000_4e75,d0			*moveq.l #0,d0
						*rts
	move.l	d0,prt_title			*タイトル
	move.w	d0,prt_keep_info		*常駐ステータス
	move.w	d0,dbrp				*ADPCMデータ読み込みメッセージ
	move.w	d0,surp				*スタートアップファイル
	move.w	d0,release_mes			*解除
	jsr	cache_flush-work(a6)
	bra	chk_optsw_lp

set_timer_a_mode:	*'A'
	st.b	timer_mode-work(a6)
	bra	chk_optsw_lp

set_timer_b_mode:	*'B'(MIDIボード装着時にもFM-TIMERを設定したい場合)
	clr.b	timer_mode-work(a6)
	bra	chk_optsw_lp

midi_assign:
	lea	midi_if_tbl-work(a6),a0
	moveq.l	#0,d1
	moveq.l	#if_max-1,d2
mdaslp:
	bsr	chk_num
	bmi	1f
	move.b	(a4),d0
	sub.b	#'1',d0
	bmi	1f		*MIDIインターフェースは使用しない
	cmpi.b	#if_max-1,d0
	bhi	prt_help	*異常なインターフェース番号を指定している
	cmpi.b	#if_mr0,d0
	bcs	@f
	cmpi.b	#if_mr1,d0
	bhi	@f
	bset.b	d0,midi_board-work(a6)
	move.l	#NOP_NOP,rs_check_patch
	jsr	cache_flush-work(a6)
@@:
	addq.w	#1,a4
	bset.l	d0,d1
	bne	3f		*同じインターフェース番号を指定している
	btst.b	d0,midi_board-work(a6)
	beq	4f		*異常なインターフェース番号を指定している
	add.b	d0,d0
	move.b	d0,(a0)+
	dbra	d2,mdaslp
1:
	move.b	d1,available_device-work(a6)
*	move.b	d1,midi_board-work(a6)
	st.b	(a0)
	moveq.l	#0,d0
2:
	lea	midi_if_tbl-work(a6),a0
@@:
	move.b	(a0)+,d1
	cmpi.b	#-1,d1
	beq	@f
	cmp.b	d1,d0
	bne	@b
	bra	1f
@@:
	move.b	d0,d2
	tas.b	d2
	st.b	(a0)
	move.b	d2,-(a0)
1:
	addq.w	#2,d0
	cmpi.w	#if_max*2,d0
	bcs	2b
	bra	chk_optsw_lp
3:
	lea	redefinit_mes(pc),a1
	bra	err_exit
4:
	lea	devoffline_mes(pc),a1
	bra	err_exit

set_err_lang:				*エラーメッセージの言語選択
	move.b	#1,errmes_lang-work(a6)	*1:Japanese
	bra	chk_optsw_lp

synchro_on:				*nmdb!!
	bsr	chk_num
	bmi	@f
	bsr	asc_to_n		*外部シーケンサがホスト
	andi.b	#$0f,d1
	beq	@f
	ori.b	#%0011_0000,d1		*R75への書きだしデータとして形成
	move.b	d1,itpl_rate-work(a6)
	move.b	#2,timer_mode-work(a6)
@@:					*X680x0がホストモード
	st.b	synchro_mode-work(a6)
	bra	chk_optsw_lp

block_read:
brlp00:
	move.b	(a4)+,d0	*SPCをスキップ
	beq	no_more?
	cmpi.b	#' ',d0
	bls	brlp00
	subq.w	#1,a4
	lea	stup_zpdfn-work(a6),a0
	bsr	copy_fn
	lea	stup_zpdfn-work(a6),a0
	lea	ZPD-work(a6),a1
	jsr	kakuchoshi-work(a6)

	lea	stup_zpdfn-work(a6),a2
	bsr	open_and_size
	bmi	non_jochu
	st.b	pcm_read_flg-work(a6)	*flag set
	bra	chk_optsw_lp

copy_fn:			*ファイルネームをバッファへ転送
	* < a0.l=destination address
	* < a4=address
	* > d1.b=minus 拡張子がある
	* > d1.b=plus 拡張子はなかった
	* - all except d1,a4
	movem.l	d0/d2/a0,-(sp)
	moveq.l	#0,d1
	moveq.l	#0,d2
copy_fnlp01:
	move.b	(a4)+,d0
	cmpi.b	#'.',d0
	bne	@f
	cmpi.b	#' ',(a4)
	bls	@f
	st.b	d1
@@:
	cmpi.b	#',',d0		*separater
	beq	exit_copyfn
	cmpi.b	#' ',d0		*ctrl code
	bls	exit_copyfn
	tst.b	d2
	beq	@f
	tst.b	-1(a0)
	bmi	cfst_lt
@@:
	jsr	mk_capital-work(a6)
cfst_lt:
	move.b	d0,(a0)+
	st.b	d2
	bra	copy_fnlp01
exit_copyfn:
	subq.w	#1,a4
exit_cfn:
	cmpi.b	#'.',-1(a0)
	bne	@f
	subq.w	#1,a0		*最後の'.'を潰す
@@:
	clr.b	(a0)
	movem.l	(sp)+,d0/d2/a0
	rts

non_jochu:
	jsr	play_beep-work(a6)
	bsr	mes_head
	lea	cannot_read-work(a6),a1	*エラーメッセージを表示して終了
	bra	err_exit

Human_ver_err:
	jsr	play_beep-work(a6)
	lea	os_too_old_mes(pc),a1
	bra	err_exit

resigned:
	jsr	play_beep-work(a6)
	lea	out_mem_mes(pc),a1
	bra	err_exit

open_and_size:
	* < a2.l=file name pointer
	* X d0,d3,d5
	jsr	fopen-work(a6)	*<a2.l=file name,(ret:d5=file handle)
	tst.l	d5		*d5=file_handle
	bmi	oas_err
	jsr	do_fclose-work(a6)
	moveq.l	#0,d0
	rts
oas_err:
	moveq.l	#-1,d0
	rts

start_up:
sulp00:
	move.b	(a4)+,d0	*SPCをスキップ
	beq	no_more?	*手抜き(case:command)
	cmpi.b	#' ',d0
	bls	sulp00
	subq.w	#1,a4
	lea.l	stup_fnsv-work(a6),a0
	moveq.l	#96-1,d1
sulp01:				*ファイルネームのゲット
	move.b	(a4)+,d0
	cmpi.b	#' ',d0
	bls	@f
	move.b	d0,(a0)+
	dbra	d1,sulp01
@@:
	subq.w	#1,a4
	clr.b	(a0)		*end code

	lea.l	stup_fnsv-work(a6),a2
	bsr	open_and_size
	bmi	_non_jochu
	st.b	stup_read_flg-work(a6)		*flag set
	bra	chk_optsw_lp

_non_jochu:
	bsr	prt_title
	jsr	play_beep-work(a6)
	bsr	mes_head2
	lea	cannot_read-work(a6),a1		*エラーメッセージを表示して終了
	bra	err_exit

get_eoxw:
	bsr	asc_to_n
	lea	eox_w-work(a6),a1
	rept	if_max
	move.w	d1,(a1)+
	endm
	bra	chk_optsw_lp

chk_num:			*数字かどうかチェック
	* > eq=number
	* > mi=not num
	move.l	d0,-(sp)
	bsr	skip_spc
	move.b	(a4),d0
	cmpi.b	#'%',d0
	beq	yes_num
	cmpi.b	#'$',d0
	beq	yes_num
	cmpi.b	#'-',d0
	beq	yes_num
	cmpi.b	#'+',d0
	beq	yes_num
	cmpi.b	#'0',d0
	bcs	not_num
	cmpi.b	#'9',d0
	bhi	not_num
yes_num:
	move.l	(sp)+,d0
	move.w	#CCR_ZERO,ccr
	rts
not_num:
	move.l	(sp)+,d0
	move.w	#CCR_NEGA,ccr
	rts

skip_spc:			*スペース/タブをスキップする
	cmpi.b	#' ',(a4)+
	beq	skip_spc
	cmpi.b	#09,-1(a4)	*skip tab
	beq	skip_spc
	subq.w	#1,a4
@@:
	rts

skip_plus:			*PLUSをスキップする
	cmpi.b	#'+',(a4)+
	beq	skip_plus
	subq.w	#1,a4
@@:
	rts

skip_sep:			*セパレータをスキップする(スペースやタブも)
	move.w	d0,-(sp)
skip_sep_lp:
	move.b	(a4)+,d0
	cmpi.b	#' ',d0
	beq	skip_sep_lp
	cmpi.b	#09,d0
	beq	skip_sep_lp
	cmpi.b	#',',d0
	beq	skip_sep_lp
	cmpi.b	#':',d0
	beq	skip_sep_lp
	cmpi.b	#'=',d0		*OPMD CNF FILEのケース
	beq	skip_sep_lp
	subq.w	#1,a4
@@:
	move.w	(sp)+,d0
	rts

asc_to_n:			*数字文字列を数値へ
	* < (a4)=number strings
	* > d1.l=value
	* > a4=next
	* x none
	bsr	skip_sep	*','などをskip
	movem.l	d2-d3,-(sp)
	cmpi.b	#'-',(a4)
	seq	d2   		*'-'ならマーク
	bne	get_num0
	addq.w	#1,a4
get_num0:
	bsr	skip_plus
	bsr	skip_spc

	cmpi.b	#'$',(a4)
	beq	get_hexnum_
	cmpi.b	#'%',(a4)
	beq	get_binnum_

	moveq.l	#0,d1
	moveq.l	#0,d0
num_lp01:
	move.b	(a4)+,d0
	cmpi.b	#'_',d0
	beq	num_lp01
	sub.b	#$30,d0
	bmi	num_exit
	cmp.b	#9,d0
	bhi	num_exit

	add.l	d1,d1
	move.l	d1,d3
	lsl.l	#2,d1
	add.l	d3,d1		*d1=d1*10
	add.l	d0,d1		*d1=d1+d0
	bra	num_lp01
num_exit:
	subq.w	#1,a4
	tst.b	d2
	beq	@f
	neg.l	d1
@@:
	bsr	skip_sep
	movem.l	(sp)+,d2-d3
num_ret:
	rts
get_hexnum_:			*16進数
	moveq.l	#0,d0
	moveq.l	#0,d1
	addq.w	#1,a4
	bsr	skip_spc
__num_lp01_:
	move.b	(a4)+,d0
	cmpi.b	#'_',d0
	beq	__num_lp01_
	jsr	mk_capital-work(a6)
	sub.b	#$30,d0
	bmi	num_exit
	cmp.b	#9,d0
	bls	calc_hex_
	cmpi.b	#17,d0
	bcs	num_exit
	cmpi.b	#22,d0
	bhi	num_exit
	subq.b	#7,d0
calc_hex_:
	lsl.l	#4,d1
	or.b	d0,d1
	bra	__num_lp01_
get_binnum_:			*2進数
	moveq.l	#0,d0
	moveq.l	#0,d1
	addq.w	#1,a4
	bsr	skip_spc
b__num_lp01_:
	move.b	(a4)+,d0
	cmpi.b	#'_',d0
	beq	b__num_lp01_
	cmpi.b	#'0',d0
	beq	calc_b_num__
	cmpi.b	#'1',d0
	bne	num_exit
calc_b_num__:
	sub.b	#$30,d0
	add.l	d1,d1
	or.b	d0,d1
	bra	b__num_lp01_

set_vect:				*本デバイスドライバを拡張IOCSとして登録
	* > d0.l≠0ならエラー
	lea	$fe0000,a2
					*MIDIタイマ使用か
	move.b	timer_mode-work(a6),d0	*1:MIDIタイマ
	ble	2f
	subq.b	#1,d0
	bne	extmmd			*2:
	move.l	$238.w,d0
	cmp.l	a2,d0
	bcs	3f			*すでに何かが占有中
	lea	int_entry_m-work(a6),a1
	move.l	a1,$238.w
	move.l	d0,mint_vect-work(a6)
	bra	1f
extmmd:					*MIDIクロックモード
	move.l	$210.w,d0		*PlayBackCounter int
	cmp.l	a2,d0
	bcs	3f			*すでに何かが占有中
	move.l	$200.w,d1		*RealtimeMessageRecv int
	cmp.l	a2,d1
	bcs	3f
	lea	int_entry_e-work(a6),a1
	move.l	a1,$210.w
	move.l	d0,eint_vect-work(a6)
	lea	int_rm_ope-work(a6),a1
	move.l	a1,$200.w
	move.l	d1,rmint_vect-work(a6)
1:
	tst.w	se_tr_max-work(a6)
	beq	_sv0
	bra	set_opmv
2:
	cmp.l	$10c.w,a2
	bcs	set_opmv
3:					*すでに何かが占有中
	moveq.l	#-1,d0
	rts

set_opmv:
	st.b	opm_vect-work(a6)
	lea	int_entry_f-work(a6),a1
	IOCS	_OPMINTST
_sv0:
	move.l	$228.w,d0		*MIDI受信割り込みベクタ設定 #1
	cmp.l	a2,d0
	bcs	already_bye		*すでに何かが占有中
	lea	rec_int-work(a6),a1
	move.l	a1,$228.w
	move.l	d0,rec_vect-work(a6)

	move.l	$230.w,d0		*MIDI送信割り込みベクタ設定 #1
	cmp.l	a2,d0
	bcs	already_bye		*すでに何かが占有中
	lea	m_out_entry-work(a6),a1
	move.l	a1,$230.w
	move.l	d0,mot_vect-work(a6)

	move.l	$2a8.w,d0		*MIDI受信割り込みベクタ設定 #2
	cmp.l	a2,d0
	bcs	already_bye		*すでに何かが占有中
	lea	rec_int2-work(a6),a1
	move.l	a1,$2a8.w
	move.l	d0,rec_vect2-work(a6)

	move.l	$2b0.w,d0		*MIDI送信割り込みベクタ設定 #2
	cmp.l	a2,d0
	bcs	already_bye		*すでに何かが占有中
	lea	m_out_entry2-work(a6),a1
	move.l	a1,$2b0.w
	move.l	d0,mot_vect2-work(a6)

	btst.b	#if_mr0,midi_board-work(a6)
	beq	set_advct
					*RS-MIDIベクタの設定
	lea	$160.w,a0
	cmp.l	(a0),a2
rs_check_patch:				*スイッチ-i3などでパッチが当たる(NOP*2)
	bhi	already_bye		*すでに何かが占有中
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	lea	rs_vect-work(a6),a1
	moveq.l	#8-1,d0
@@:
	move.l	(a0)+,(a1)+
	dbra	d0,@b

	lea	$160.w,a1
	lea	m_out_entry_r-work(a6),a0
	move.l	a0,(a1)+
	move.l	a0,(a1)+
	lea	es_int-work(a6),a0
	move.l	a0,(a1)+
	move.l	a0,(a1)+
	lea	rec_int_r-work(a6),a0
	move.l	a0,(a1)+
	move.l	a0,(a1)+
	lea	sp_int-work(a6),a0
	move.l	a0,(a1)+
	move.l	a0,(a1)+
	move.w	(sp)+,sr
set_advct:				*ADPCMの停止処理の書き換え
	tst.b	ext_pcmdrv-work(a6)
	bne	@f
	lea	int_adpcm_stop,a1
	moveq.l	#$6a,d1
	IOCS	_B_INTVCS
	move.l	d0,adpcm_stop_v-work(a6)
	cmp.l	a2,d0
	bcs	already_bye_

	move.l	$84.w,d0
	cmp.l	a2,d0
	bcs	already_bye_
	move.l	d0,dummy_vect-work(a6)
	clr.l	$84.w

	lea	adpcmout,a1
	move.w	#$160,d1		*IOCS	_ADPCMOUTを乗っ取る
	IOCS	_B_INTVCS
	move.l	d0,adpcmout_v-work(a6)

	lea	adpcmmod-adpcmout(a1),a1
	move.w	#$167,d1		*IOCS	_ADPCMMODを乗っ取る
	IOCS	_B_INTVCS
	move.l	d0,adpcmmod_v-work(a6)
	bra	ocpy_trp3
@@:
	lea	ZMSC3_X-work(a6),a1
	move.w	#M_LOCK,d0
	MPCM_call
	tst.l	d0
	bne	already_bye_mpcm
	move.w	#M_INIT,d0
	MPCM_call
	lea	mpcm_vol_tbl-work(a6),a1
	moveq.l	#-1,d1
	move.w	#M_SET_VOLTBL,d0
	MPCM_call
ocpy_trp3:
	moveq.l	#35,d1		*trap #3を乗っ取る
	lea	Z_MUSIC_t3,a1
	IOCS	_B_INTVCS
	move.l	d0,sv_trap3-work(a6)
prt_title:				*タイトル表示(-GでRTSに)
	move.l	a1,-(sp)
	tst.b	title_mes
	beq	1f
	lea.l	title_mes(pc),a1		*常駐タイトル
	bsr	prta1
	clr.b	(a1)
1:
	move.l	(sp)+,a1
	moveq.l	#0,d0			*no problem
	rts

already_bye_:			*ADPCM関連のベクタが占有されている
	moveq.l	#1,d0
	jmp	release_vectors-work(a6)
already_bye_mpcm:		*MPCM関連が占有されている
	clr.b	ext_pcmdrv-work(a6)
	moveq.l	#2,d0
	jmp	release_vectors-work(a6)
already_bye:			*ZMUSICで使用するベクタが占有されている
	moveq.l	#-1,d0
	jmp	release_vectors-work(a6)

chk_board:			*MIDIボードのチェック
	* - all
reglist	reg	d0/a0
	movem.l	reglist,-(sp)
	lea	midi_if_tbl-work(a6),a0
				*MIDI I/F 0のチェック
	move.w	#1,-(sp)
	pea	icr
	pea	isr
	DOS	_BUS_ERR
	lea	10(sp),sp
	move.b	#$80+if_m0*2,(a0)+
	tst.l	d0
	bne	@f
	bset.b	#if_m0,midi_board-work(a6)
	move.b	#if_m0*2,-1(a0)
	move.b	#1,timer_mode-work(a6)	*MIDI TIMER(default)
@@:
				*MIDI I/F 1のチェック
	move.w	#1,-(sp)
	pea	icr+$10
	pea	isr+$10
	DOS	_BUS_ERR
	lea	10(sp),sp
	move.b	#$80+if_m1*2,(a0)+
	tst.l	d0
	bne	@f
	bset.b	#if_m1,midi_board-work(a6)
	move.b	#if_m1*2,-1(a0)
@@:				*RS232C MIDI(標準装備)
	move.b	#$80+if_mr0*2,(a0)+
	cmp.l	#$fe0000,$160.w
	bcs	@f			*すでに何かが占有中
	bset.b	#if_mr0,midi_board-work(a6)
	move.b	#if_mr0*2,-1(a0)
@@:
	move.b	#$80+if_mr1*2,(a0)+
	st.b	(a0)
	move.b	midi_board-work(a6),available_device-work(a6)
	movem.l	(sp)+,reglist
	rts

set_dev_name:				*コマンドからドライバが実行された場合に
	lea	$6800,a0		*デバイス名 "ＯＰＭ" を強制的に登録する
fdn_lp01:
	lea	NUL-work(a6),a2
	jsr	do_find-work(a6)
	cmpa.l	#NUL,a0
	bcc	err_fdn
	cmpi.w	#$8024,-18(a0)	*本当にNULか
	bne	fdn_lp01
	lea	-22(a0),a0
fdn_lp02:
	movea.l	a0,a1
	movea.l	(a1),a0		*最後尾を見付ける
	cmpa.l	#-1,a0
	bne	fdn_lp02
	lea	device_driver0,a0
	move.l	a0,(a1)
	moveq.l	#0,d0
	rts
err_fdn:
	moveq.l	#-1,d0
	rts

set_patch:					*-a,-e,-i,-m スイッチ処理
reglist	reg	d0-d1/a0-a2
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	movem.l	reglist,-(sp)

	lea	mode_patch_bkup-work(a6),a0
	move.w	pmod_wvmm_patch,(a0)+
	move.w	arcc_wvmm_patch,(a0)+
	move.w	frq_mpcm_patch,(a0)+
	move.w	datatype_mpcm_patch,(a0)+
	move.w	exit_gsg,(a0)+
	move.w	get_def_velo,(a0)+

	tst.b	rs232c_mode-work(a6)		*RS232C MIDIのパッチ
	bmi	@f				*-1,1の場合はデュアル
	patch_w	BRA,m_out_r0,m_out_r0_patch	*SINGLEの場合は$f5の送出禁止
	patch_w	BRA,m_out_r1,m_out_r1_patch
@@:
	move.l	$84.w,a0
	cmp.l	#'MPCM',-8(a0)
	seq	ext_pcmdrv-work(a6)
	bne	std_pcmdrv
						*MPCM case
	patch_l2	BRA,adpcm_frq_patch0,frq_mpcm
	patch_l2	BRA,adpcm_pan_patch0,pan_mpcm
	patch_w2	BRA,sea1_patch,sea1_
	patch_w2	BRA,sea2_patch,sea2_
	move.w	#NOP,cfa_patch-work(a6)
	bra	@f
std_pcmdrv:					*standard pcmdrv case
	patch_l2	BRA,pkon_patch0,single_pkon
	patch_l2	BRA,pkof_patch0,single_pkof
	patch_w		BRA,adii_patch,exit_adii
	patch_w		BPL,cmko_patch,koa_lp2
	patch_w2	BRA,mpcm_patch0,_mpcm_patch0
	patch_w		BRA,mpcm_patch1,_mpcm_patch1
	patch_w		BRA,mpcm_patch2,_mpcm_patch2
	move.w	#JMP,ako_ad_patch-work(a6)
	move.l	#adpcm_end,ako_ad_patch+2-work(a6)
	move.w	#RTS,do_ad_volume_-work(a6)
	move.w	#RTS,set_ad_tune
@@:
	move.l	#opmset,opmset_bsr_ms-work(a6)
	tst.w	se_tr_max-work(a6)
	beq	@f
	move.l	#opmset_se,opmset_bsr_ms-work(a6)
	bra	1f
@@:
	move.w	#RTS,play_zmd_se
	move.w	#RTS,se_play
1:
	move.b	timer_mode-work(a6),d0		*タイマモードチェック
	bgt	tm_md_mode
	bmi	tm_a_mode
tm_b_mode:					*タイマBモード
	patch_l	BRA,_init_timer,init_timer_b
	patch_l	BRA,stop_timer,stop_timer_b
	patch_l	BRA,init_timer_se,init_timer_a_se
	patch_l	BRA,stop_timer_se,stop_timer_a
	patch_l	BSR,calc_timer_patch,do_calc_tmb
	patch_l	BSR,calc_timer_se_patch,do_calc_tma
	patch_l	BSR,agogik_calctm,do_calc_tmb
	patch_l	BSR,agogik_calctm_se,do_calc_tma
	patch_l	BSR,go_calctm,do_calc_tmb
	patch_l	BSR,_go_calctm,do_calc_tma
	patch_w	BSR,tcg0,gyakusan_tm_b
	patch_w	BSR,_tcg0,gyakusan_tm_a
	patch_l	BSR,wrt_tmp,set_timer_b
	patch_l	BRA,_wrt_tmp,set_timer_a
	patch_x2	set_timer_value_patch,gyakusan_tm_b
	move.l	#gyakusan_tm_b,gyakusan_table+0-work(a6)
	move.l	#gyakusan_tm_a,gyakusan_table+4-work(a6)
	move.l	#int_entry_sub,tm_a_entry-work(a6)
	move.l	#int_entry_fm,tm_b_entry-work(a6)
	tst.w	se_tr_max-work(a6)
	bne	@f
							*効果音演奏無し
	move.w	#%0000_1010,tm_a_reset-work(a6)
	move.w	#%0010_1010,tm_b_reset-work(a6)
	move.w	#%0010_1010,tm_ab_reset-work(a6)
	move.l	#int_dummy,sub_job_entry-work(a6)
@@:
*	move.l	#20*65536+5000,t_min-work(a6)		*t_min,t_max
*	move.l	#77*65536+32767,t_min_se-work(a6)	*t_min_se,t_max_se
	move.l	#$ff*65536+$3ff,_@t_max-work(a6)	*_@t_max,_@t_max_se
	patch_w	BRA,start_tm_int_ms,ei_tmf
	patch_w	BRA,stop_tm_int_ms,di_tmf
	bra	cpk_ope_patch
tm_a_mode:					*タイマAモード
	patch_l	BRA,_init_timer,init_timer_a
	patch_l	BRA,stop_timer,stop_timer_a
*	patch_l	BRA,init_timer_se,init_timer_b_se
*	patch_l	BRA,stop_timer_se,stop_timer_b
	patch_l	BSR,calc_timer_patch,do_calc_tma
	patch_l	BSR,calc_timer_se_patch,do_calc_tmb
	patch_l	BSR,agogik_calctm,do_calc_tma
*	patch_l	BSR,agogik_calctm_se,do_calc_tmb
	patch_l	BSR,go_calctm,do_calc_tma
*	patch_l	BSR,_go_calctm,do_calc_tmb
	patch_w	BSR,tcg0,gyakusan_tm_a
*	patch_w	BSR,_tcg0,gyakusan_tm_b
	patch_l	BSR,wrt_tmp,set_timer_a
*	patch_l	BRA,_wrt_tmp,set_timer_b
	move.l	#gyakusan_tm_a,gyakusan_table+0-work(a6)
*	move.l	#gyakusan_tm_b,gyakusan_table+4-work(a6)
	patch_x2	set_timer_value_patch,gyakusan_tm_a
	tst.w	se_tr_max-work(a6)
	bne	@f
							*効果音演奏無し
	move.w	#%0001_0101,tm_a_reset-work(a6)
	move.w	#%0000_0101,tm_b_reset-work(a6)
	move.w	#%0001_0101,tm_ab_reset-work(a6)
	move.l	#int_dummy,sub_job_entry-work(a6)
@@:
*	move.l	#77*65536+32767,t_min-work(a6)		*t_min,t_max
*	move.l	#20*65536+5000,t_min_se-work(a6)	*t_min_se,t_max_se
	move.l	#$3ff*65536+$ff,_@t_max-work(a6)	*_@t_max,_@t_max_se
	patch_w	BRA,start_tm_int_ms,ei_tmf
	patch_w	BRA,stop_tm_int_ms,di_tmf
	bra	cpk_ope_patch
tm_md_mode:						*MIDIタイマーモード
	move.w	#%0000_1010,tm_a_reset-work(a6)		*OPMタイマは使うとしてもタイマBの方だけ
	move.w	#%0010_1010,tm_b_reset-work(a6)
	move.w	#%0010_1010,tm_ab_reset-work(a6)
*	move.l	#int_entry_sub,tm_b_entry-work(a6)
	move.l	#int_entry_sub,tm_ab_entry-work(a6)
	move.l	#NOP_NOP,ief_patch-work(a6)		*FM音源割り込み処理を無効化
	tst.w	se_tr_max-work(a6)
	bne	@f
	move.l	#int_dummy,sub_job_entry-work(a6)
@@:
	cmpi.b	#2,d0					*< d0.b=timer_mode
	bne	cpk_ope_patch
							*外部シーケンサホストケース
	patch_l	BRA,_init_timer,init_timer_e

	move.b	#%0011_1001,f8_start-work(a6)
	move.b	#%0010_1001,f8_stop-work(a6)

	patch_w2	BRA,mpp_fa0,_mpp_fa0
	patch_w2	BRA,mpp_fa1,_mpp_fa1

	patch_w	BRA,start_tm_int_ms,ei_tme
	patch_w	BRA,stop_tm_int_ms,di_tme
cpk_ope_patch:
	lea	copy_key-work(a6),a0
	move.l	$b0.w,copy_org-work(a6)
	move.l	a0,$b0.w			*copy key vect kill

	move.w	#$01_00+_ABORTJOB,d1
	lea	abortjob-work(a6),a1
	IOCS	_B_INTVCS
	move.l	d0,abortjob_org-work(a6)
ex_sync?:
	tst.b	synchro_mode-work(a6)		*外部シーケンサ同期モードか
	bne	@f				*非同期モード
	move.w	#RTS,m_tempo_patch
	move.w	#RTS,m_play_patch
	move.w	#RTS,m_stop_patch
	move.w	#RTS,m_cont_patch
	move.w	#RTS,_@t_midi_clk
@@:
	bsr	mdbd_patch
						*チャンネルワークに関するパッチ
	move.b	ch_wk_mode-work(a6),d0
	beq	kill_fm_map			*ARS機能のみ機能させる(FM音源マップ処理は省略)
	bpl	@f
						*全ての特殊処理を行う
	patch_l	BSR,m_out_m0_patch,midi_map_0
	patch_l	BSR,m_out_m1_patch,midi_map_1
	patch_l	BSR,m_out_r0_patch,midi_map_r0
	patch_l	BSR,m_out_r1_patch,midi_map_r1

	patch_w	BPL,(m_out_m0_patch+4),exit_ars0_
	patch_w	BPL,(m_out_m1_patch+4),exit_ars1_
	patch_w	BPL,(m_out_r0_patch+4),exit_arsr0_
	patch_w	BPL,(m_out_r1_patch+4),exit_arsr1_

	move.w	#RTS,m_out_m0_patch+6-work(a6)
	move.w	#RTS,m_out_m1_patch+6-work(a6)
	move.w	#RTS,m_out_r0_patch+6-work(a6)
	move.w	#RTS,m_out_r1_patch+6-work(a6)
	bra	reorder_mdif
@@:						*ＭＩＤＩチャンネルワーク/ARS両方の処理を省略
	patch_w	BRA,m_out_m0_patch,exit_ars0_
	patch_w	BRA,m_out_m1_patch,exit_ars1_
	patch_w	BRA,m_out_r0_patch,exit_arsr0_
	patch_w	BRA,m_out_r1_patch,exit_arsr1_

	patch_w2	BRA,init_midiwk,exit_mdwk	*init. ch wk

	subq.b	#1,d0			*case:d0=1 kill midi map only
	beq	reorder_mdif		*case:d0=2 kill all map
kill_fm_map:				*ＦＭ音源レジスタマップ処理の省略
	tst.w	se_tr_max-work(a6)	*(効果音モードが有効ならば無視)
	bne	@f
	move.l	exit_opmset-work(a6),opmset_patch1-work(a6)
	patch_w2	BRA,init_opmwk,exit_ifmwk	*init. ch wk
@@:
	tst.b	polypress_mode-work(a6)	*ポリフォニックプレッシャーを使用するか否か
	bne	reorder_mdif
	patch_w	BRA,poly_pressure_patch0,csm0
	patch_w	BRA,poly_pressure_patch1,psp0
	patch_w	BRA,poly_pressure_patch2,ppp0
reorder_mdif:
	lea	midi_if_tbl-work(a6),a1
	move.l	v_buffer-work(a6),a2
	moveq.l	#0,d0
rodrmdiflp:				*未接続I/F無効化
	move.b	(a1)+,d0
	bpl	@f
	cmpi.b	#-1,d0
	beq	1f
	add.b	d0,d0
	move.l	md_patch_tbl0(pc,d0.w),d1
	lea	md_patch_tbl0(pc,d1.l),a0
	move.w	#RTS,(a0)
	move.l	md_patch_tbl1(pc,d0.w),d1
	lea	md_patch_tbl1(pc,d1.l),a0
	move.w	#RTS,(a0)
	bra	rodrmdiflp
@@:
	move.b	d0,(a2)+
	bra	rodrmdiflp
1:					*並べ換え
	lea	midi_if_tbl-work(a6),a1
@@:
	move.b	(a1)+,d0
	bpl	@b
	move.b	d0,(a2)+
	cmpi.b	#-1,d0
	bne	@b

	move.l	v_buffer-work(a6),a1
	move.l	(a1)+,midi_if_tbl+0-work(a6)
	move.l	(a1)+,midi_if_tbl+4-work(a6)

	move.l	inc_zmint-work(a6),zi_inst-work(a6)	*obtain_events用
	jsr	cache_flush-work(a6)
	movem.l	(sp)+,reglist
	move.w	(sp)+,sr
	rts

md_patch_tbl0:
	dc.l	m_out_m0-md_patch_tbl0
	dc.l	m_out_m1-md_patch_tbl0
	dc.l	m_out_r0-md_patch_tbl0
	dc.l	m_out_r1-md_patch_tbl0

md_patch_tbl1:
	dc.l	_m_out_m0-md_patch_tbl1
	dc.l	_m_out_m1-md_patch_tbl1
	dc.l	_m_out_r0-md_patch_tbl1
	dc.l	_m_out_r1-md_patch_tbl1

reglist	reg	d0-d2/a0
mdbd_patch:				*MIDIインターフェースの有無の考慮
	movem.l	reglist,-(sp)
	tst.b	available_device-work(a6)
	bne	@f
	clr.l	current_midi_in_r-work(a6)	*MIDI出力を行わない時のみ初期化
	clr.l	current_midi_out_r-work(a6)	*MIDI出力を行わない時のみ初期化
	lea	nmdout_tbl(pc),a0	*MIDI出力を行わない
	bsr	do_ncp
@@:
	move.b	midi_board-work(a6),d0
	bne	mdbd2_patch
	lea	nmdb_tbl(pc),a0		*MIDIボード無しのケース
	bsr	do_ncp
mdbd2_patch:				*CZ6BM1 #2の有無の考慮
	btst.l	#if_m1,d0
	bne	exit_ncp
	lea	nmdb2_tbl(pc),a0	*MIDIボードは1枚のみ
	bsr	do_ncp
exit_ncp:
	movem.l	(sp)+,reglist
	rts

do_ncp:
	move.l	#BRA*65536,d1
dnlp00:
	move.l	(a0)+,d0
	beq	1f
	move.w	(a0)+,d1
	move.w	(a0)+,d2
	bne	@f
	move.l	d1,(a6,d0.l)
	bra	dnlp00
@@:					*特殊ケース(RTSを埋めこむ場合など)
	move.w	d2,(a6,d0.l)
	bra	dnlp00
1:
	rts

*	dc.w	書き換えアドレス先アドレス,ジャンプ先アドレス,0
*または
*	dc.w	書き換えアドレス先アドレス,0,パッチ命令

nmdout_tbl:			*MIDI出力を行わない場合のパッチ(MIDIボードはあるかも)
	patch	nmdb0,ok_com,0
	patch	ms_key_off_md,0,RTS
	patch	nmdb4,0,RTS
	patch	nmdb7,0,RTS
	patch	nmdb9,exit_ako0,0
	patch	nmdb10,su_not_ok,0
	patch	nmdb11,exit_pbm,0
	patch	midi_inp1,0,RTS
	patch	midi_out1,0,RTS
	patch	_m_out,0,RTS
	patch	get_m_out_addr,dummy_trans,0
	patch	current_midi_in,dummy_mdifret,0
	patch	current_midi_out,dummy_mdifret,0
	patch	set_eox_wait,0,RTS
	dc.l	0

nmdb_tbl:			*MIDIボードが１枚もない場合のパッチ
	patch	m_tempo_patch,0,RTS
	patch	m_play_patch,0,RTS
	patch	m_stop_patch,0,RTS
	patch	m_cont_patch,0,RTS
	patch	init_midibd,exit_i_mdbd,0
	patch	_@t_midi_clk,0,RTS
	dc.l	0

nmdb2_tbl:			*MIDIボードが２枚ない場合のパッチ
	patch	midi_clk2,midi_clk2_e,0
	patch	_mpp,t_dat_ok,0
	patch	_msp,t_dat_ok,0
	patch	_mcp,t_dat_ok,0
	dc.l	0

prt_help:			*簡易ヘルプの表示
	bsr	prt_title
	lea	help_mes(pc),a1
	bra	err_exit

*forbid_rs:			*RS232Cの使用禁止
*	movem.l	d0/d2/a0,-(sp)
*	andi.b	#%1111_0011,midi_board-work(a6)		*if_mr0,if_mr1
*	andi.b	#%1111_0011,available_device-work(a6)	*if_mr0,if_mr1
*1:
*	lea	midi_if_tbl-work(a6),a0
*	moveq.l	#if_max-1,d2
*@@:
*	move.b	(a0)+,d0
*	cmp.b	#if_mr0*2,d0
*	beq	@f
*	cmp.b	#if_mr1*2,d0
*	beq	@f
*	dbra	d2,@b
*	movem.l	(sp)+,d0/d2/a0
*	rts
*@@:
*	tas.b	-(a0)
*	bra	1b

get_work_area0:				*ワークエリアの確保
	* > a1.l=このプログラムの最終アドレス
	* > nz=out of memory
	* - all
v_b_len:	equ	1024
open_fn__:	equ	92
	lea.l	work_start0(pc),a1
	move.l	a1,v_buffer-work(a6)
	lea	v_b_len(a1),a1

	move.l	a1,filename-work(a6)
	lea	open_fn__(a1),a1

	move.l	a1,open_fn-work(a6)
	lea	open_fn__(a1),a1

	move.l	a1,dev_end_adr-work(a6)	*このプログラムの最終アドレス
	move.w	#1,-(sp)
	pea	(a1)
	pea	(a1)
	DOS	_BUS_ERR		*メモリを過剰使用していないか
	lea	10(sp),sp
	tst.l	d0
	rts

get_work_area1:				*ワークエリアの確保
	* > a1.l=このプログラムの最終アドレス
	* > nz=out of memory
	* - all
reglist	reg	d0-d1/a0
rand_frq:	equ	89*2
	movem.l	reglist,-(sp)
	move.l	dev_end_adr-work(a6),a1
	add.w	#128,a1			*seq_wk_tbl系ワークはベースアドレスよりも
	move.l	a1,dmy_seq_wk-work(a6)	*128バイト手前をアクセスすることがあるから
	lea	trwk_size(a1),a1

	move.l	a1,seq_wk_tbl_se-work(a6)
	move.w	se_tr_max-work(a6),d0
	mulu	#trwk_size,d0
	lea	-128(a1,d0.l),a1	*-128は上で足している分をもとに戻すことを意味する

	move.l	a1,play_trk_tbl_se-work(a6)
	move.w	#-1,(a1)
	move.w	se_tr_max-work(a6),d0
	beq	@f
	add.w	d0,d0				*×2バイト
	lea	(a1,d0.w),a1
	move.w	#-1,(a1)+			*end code
@@:
	move.l	a1,estbn-work(a6)
	lea	rand_frq(a1),a1
	move.l	a1,mr_max-work(a6)

	move.b	midi_board-work(a6),d0
	beq	1f
	lea	m_buffer_0-work(a6),a0	*MIDI送信バッファ等の確保
	moveq.l	#if_max-1,d1
gwlp0:
	lsr.w	#1,d0
	bcc	@f
	move.l	a1,(a0)
	clr.l	m_buffer_sp(a1)		*m_buffer_sp,m_buffer_ip
	clr.w	m_len(a1)		*m_len
	lea	m_buffer_end-m_buffer_start(a1),a1
	move.l	a1,rec_buffer_0-m_buffer_0(a0)
	clr.l	rec_write_ptr(a1)	*rec_write_ptr,rec_read_ptr
	clr.w	rec_buf_err(a1)		*rec_buf_err,rec_buf_stat
	lea	rec_buffer_end-rec_buffer_start(a1),a1
	tst.b	ch_wk_mode-work(a6)
	bgt	@f
	move.l	a1,mm0_adr-m_buffer_0(a0)
	lea	chwklen*16(a1),a1
@@:
	addq.w	#4,a0
	dbra	d1,gwlp0
1:
	move.l	a1,dev_end_adr-work(a6)	*このプログラムの最終アドレス
	move.w	#1,-(sp)
	pea	(a1)
	pea	(a1)
	DOS	_BUS_ERR		*メモリを過剰使用していないか
	lea	10(sp),sp
	tst.l	d0
	movem.l	(sp)+,reglist
	rts

prt_keep_info:				*常駐インフォーメーション(-GでRTSに)
	lea	midi_if_tbl-work(a6),a0
	moveq.l	#0,d1
	moveq.l	#0,d2
@@:
	move.b	(a0)+,d1
	bmi	@f
	lea	mif_bar(pc),a1
	bsr	prta1
	move.l	d2,d0
	add.b	#'1',d0
	lea	suji-work(a6),a1
	move.b	d0,(a1)
	move.b	#':',1(a1)
	clr.b	2(a1)
	bsr	prta1			*BAR
	lsr.b	#1,d1			*1/2倍して(0-3)
	mulu	#11,d1
	lea	mif_tbl(pc),a1
	add.w	d1,a1
	jsr	prta1			*I/F TYPE
	addq.w	#1,d2
	bra	@b
@@:					*タイマータイプ
	lea	tm___mes(pc),a1
	jsr	prta1-tm___mes(a1)
	lea	tm_b_mes(pc),a1
	tst.b	timer_mode-work(a6)
	beq	@f
	bmi	tma_
	lea	tm_m_mes(pc),a1
	bra	@f
tma_:
	lea	tm_a_mes(pc),a1
@@:
	jsr	prta1
	tst.b	synchro_mode-work(a6)
	beq	1f
	lea	sq_m_mes0(pc),a1
	cmpi.b	#2,timer_mode-work(a6)
	bne	@f
	lea	sq_m_mes1(pc),a1
@@:
	jbsr	bil_prta1
1:
nmdb11:					*nmdb!!(bra exit_pbm)
	lea	yes_midi(pc),a1		*"MIDI/"
	bsr	prta1
exit_pbm:
	lea	no_midi(pc),a1
	tst.b	ext_pcmdrv-work(a6)
	beq	bil_prta1
	lea	no_midi_(pc),a1		*MPCM case
	bra	bil_prta1

release:				*解除処理
	bsr	kep_chk			*常駐check
	bmi	not_kep			*常駐していない
	bne	illegal_ver		*バージョンが違う

	moveq.l	#ZM_OCCUPY_COMPILER,d1	*コンパイラがいるかどうかチェック
	lea	-1.w,a1
	Z_MUSIC	#ZM_HOOK_FNC_SERVICE
	move.l	a0,d0
	beq	@f
	moveq.l	#-1,d1			*ask
	Z_MUSIC	#ZM_OCCUPY_COMPILER
	tst.l	d0
	bne	case_compiler_occupied
@@:
	moveq.l	#-1,d1			*ask
	Z_MUSIC	#ZM_OCCUPY_ZMUSIC
	tst.l	d0
	bne	case_zmusic_occupied

	Z_MUSIC	#ZM_RELEASE_DRIVER		*> a0.l=free address
	tst.l	d0
	bne	release_err

	pea	$10(a0)
	DOS	_MFREE
	addq.w	#4,sp

	bsr	prt_title
	bsr	release_mes

	move.l	ssp-work(a6),a1
	IOCS	_B_SUPER	*ユーザーモードへ戻る

	DOS	_EXIT

release_mes:
	lea	kaijo(pc),a1
	jmp	bil_prta1-kaijo(a1)

case_compiler_occupied:			*ZMUSIC-COMPILERは占有されているので解除不可能
	lea	ocp_zc_er_mes(pc),a1
	bra	err_exit

case_zmusic_occupied:			*ZMUSIC-DRIVERは占有されているので解除不可能
	lea	ocp_zm_er_mes(pc),a1
	bra	err_exit

illegal_ver:				*VERSIONが違う
	lea	ver_er_mes(pc),a1
	bra	err_exit

release_err:				*解除不能の状態
	lea	rls_er_mes(pc),a1
	bra	err_exit

not_kep:				*常駐していないのか
	bsr	chk_drv
	beq	release_err		*device=で登録されたため解除不能
	lea	not_kep_mes(pc),a1	*常駐していない
	bra	err_exit

chk_drv:			*デバイス名のcheck
	* > eq=exist
	* > mi=not exist
	* x a1
	move.l	$8c.w,a1
	subq.w	#8,a1
	cmpi.l	#'ZmuS',(a1)+
	bne	@f
	cmpi.w	#'iC',(a1)+
	bne	@f
	rts
@@:
	moveq.l	#-1,d0
	rts

kep_chk:			*分身が常駐しているか
	* > eq=exists
	* > ne=none
	* > a2work分身のアドレス
	move.l	a0work-work(a6),a0
@@:				*メモリポインタの先頭を求める
	move.l	(a0),d0
	beq	klop1
	move.l	d0,a0
	bra	@b
klop1:
	move.l	12(a0),d0	*次のメモリ管理ポインタ
	beq	err_chk
	movea.l	d0,a2
	cmpi.b	#$ff,4(a2)	*!Thanks to E.Tachibana
	bne	klop_nxt	*常駐プロセスでない
	lea	version_id+8-begin_of_prog+$100(a2),a1
	cmpa.l	8(a2),a1
	bhi	klop_nxt	*比較対象のメモリブロックが小さすぎるので対象外
	subq.w	#8,a1		*!Thanks to E.Tachibana
	lea	version_id,a0
	cmpm.l	(a1)+,(a0)+
	bne	klop_nxt
	cmpm.w	(a1)+,(a0)+
	bne	klop_nxt
	cmpm.w	(a1)+,(a0)+
	bne	wrong_ver
	move.l	a2,a2work-work(a6)
	moveq.l	#0,d0		*分身の存在を確認
	rts
klop_nxt:
	move.l	a2,a0
	bra	klop1		*どんどんさかのぼる
err_chk:			*分身は無かった
	moveq.l	#-1,d0
	rts
wrong_ver:			*バージョンが違う
	moveq.l	#1,d0
	rts

*end_of_prog:
work_start0:
	nop			*ZM302C_X.LZHのZMSC3.Xと同一にするための細工

	end	exec
