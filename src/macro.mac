	.nlist
	.include	version.mac

Z_MUSIC	macro	number
	moveq.l	number,d0
	trap	#3
	endm

MPCM_call	macro	number
*local	mmmm
*	cmpi.b	#$0f,d0
*	bls	mmmm
*	cmpi.b	#-1,d0
*	beq	mmmm
*	jsr	debug2
*mmmm:
	trap	#1
	endm

bitsns	macro	n		*IOCS	_BITSNSと同等に機能する
	move.b	$800+n.w,d0
	endm

opmwait	macro
	jbsr	opmwait
	endm

midiwait	macro			*24MHzに改造したXVIへ対応/X68030へ対応させる時
	jbsr	midiwait
	endm


opmset	macro	reg,data	*ＦＭ音源のレジスタ書き込み
	opmwait
	move.b	reg,fm_addr_port
	opmwait
	move.b	data,fm_data_port
	endm

opmset0	macro	reg,data	*ＦＭ音源のレジスタ書き込み
	opmwait
	move.b	reg,fm_addr_port
	opmwait
	clr.b	fm_data_port
	endm

calc_wk	macro	reg
	swap	reg
	lsr.l	#16-trwk_size_,reg
	movea.l	seq_wk_tbl-work(a6),a5
	adda.l	reg,a5		*a5=trk n seq_wk_tbl
	endm

err	macro	ern	*,beep
*	.if	(beep=1)
*	bsr	play_beep
*	.endif
	move.l	fnc_no(pc),d0	*わざと.l
	move.w	#ern,d0
	bra	t_error_code_exit
	endm

tempo_range	macro	tempo,type
	local	t1
	local	t2
	cmp.w	t_min&type-work(a6),tempo
	bcc	t1
	move.w	t_min&type-work(a6),tempo
	bra	t2
t1:
	cmp.w	t_max&type-work(a6),tempo
	bls	t2
	move.w	t_max&type-work(a6),tempo
t2:
	endm

init_pmod_wk	macro	dstnc,dreg,areg
	*一度に複数を初期化(p_pmod_dpndpt,p_pmod_dpt_tbl)
	move.l	dreg,p_pmod_dpndpt+dstnc(areg)

	*一度に複数を初期化(p_pmod_dpnspd,p_pmod_spd_tbl)
	move.l	#mod_dflt,p_pmod_dpnspd+dstnc(areg)
	move.l	dreg,p_pmod_spd_tbl+02+dstnc(areg)	*!
	move.l	dreg,p_pmod_spd_tbl+06+dstnc(areg)	*!
	move.l	dreg,p_pmod_spd_tbl+10+dstnc(areg)	*!
	move.l	dreg,p_pmod_spd_tbl+14+dstnc(areg)	*!p_pmod_dpt_now.w=0

	*一度に複数を初期化(p_pmod_wf,p_pmod_1st_dly)
	move.l	#$0002_0000,p_pmod_wf+dstnc(areg)
	move.l	dreg,p_pmod_8st_tbl+00+dstnc(areg)	*!
	move.l	dreg,p_pmod_8st_tbl+04+dstnc(areg)	*!
	move.l	dreg,p_pmod_8st_tbl+08+dstnc(areg)	*!
	move.l	dreg,p_pmod_8st_tbl+12+dstnc(areg)	*!

	*一度に複数を初期化(p_pmod_sw,p_pmod_sw2,p_pmod_chain,p_pmod_flg)
	move.l	#$00_00_02_80,p_pmod_sw+dstnc(areg)

	*一度に複数を初期化(p_pmod_mode,p_pmod_omt,p_pitch_last)
	move.l	#$ff_01_ffff,p_pmod_mode+dstnc(areg)

	move.l	dreg,p_pmod_pitch+dstnc(areg)

	*一度に複数を初期化(p_pmod_wf2,p_pmod_dpnrpt)
	move.l	#$0002_0000,p_pmod_wf2+dstnc(areg)

	*一度に複数を初期化(p_pmod_syncnt,p_pmod_syncnt2)
	move.l	#$0001_0001,p_pmod_syncnt+dstnc(areg)
	endm

init_arcc_wk	macro	arcc_dflt,arcc_sync
	*一度に複数を初期化(p_arcc_wf,p_arcc_dpndpt,p_arcc_dpt_tbl)
	move.l	#$0002_00_00,p_arcc_wf(a4)

	*一度に複数を初期化(p_arcc_dpnspd,p_arcc_spd_tbl)
	move.l	#mod_dflt,p_arcc_dpnspd(a4)
	move.l	d0,p_arcc_spd_tbl+02(a4)	*!
	move.l	d0,p_arcc_spd_tbl+06(a4)	*!
	move.l	d0,p_arcc_spd_tbl+10(a4)	*!
	move.l	d0,p_arcc_spd_tbl+14(a4)	*!p_arcc_dpt_now.b=0,p_arcc_flg2.b=0

	*一度に複数を初期化(p_arcc_mode,p_arcc_omt,p_arcc_1st_dly)
	move.l	#$ff_01_0000,p_arcc_mode(a4)
	move.l	d0,p_arcc_8st_tbl+00(a4)	*!
	move.l	d0,p_arcc_8st_tbl+04(a4)	*!
	move.l	d0,p_arcc_8st_tbl+08(a4)	*!
	move.l	d0,p_arcc_8st_tbl+12(a4)	*!

	*一度に複数を初期化(p_arcc_sw,p_arcc_sw2,p_arcc_chain,p_arcc_flg)
	move.l	#$00_00_02_00+arcc_sync,p_arcc_sw(a4)

	*一度に複数を初期化(p_arcc_last,p_arcc_reset,p_arcc_origin,p_arcc)
	move.l	#$ff_7f_7f00+arcc_dflt,p_arcc_last(a4)

	*一度に複数を初期化(p_arcc_wf2,p_arcc_dpnrpt)
	move.l	#$0002_0000,p_arcc_wf2(a4)

	*一度に複数を初期化(p_arcc_syncnt,p_arcc_syncnt2)
	move.l	#$0001_0001,p_arcc_syncnt(a4)
	endm

patch	macro	sor,des,para
	.if	(para=0)
	dc.l	sor-work
	dc.w	des-sor-2,para
	.else
	dc.l	sor-work
	dc.w	0,para
	.endif
	endm

patch_l	macro	cmd,src,dest
	.iff	(debug.and.2)
	move.l	#cmd*65536+((dest-src-2).and.$ffff),src-work(a6)
	.else
	dc.w	0
	lea	dest-src-2(pc),a0
	dc.w	0
	.endif
	endm

patch_l2	macro	cmd,src,dest
	.iff	(debug.and.2)
	move.l	#cmd*65536+((dest-src-2).and.$ffff),src
	.else
	dc.w	0
	lea	dest-src-2(pc),a0
	dc.w	0
	.endif
	endm

patch_w	macro	cmd,src,dest
	.iff	(debug.and.2)
	move.w	#cmd+((dest-src-2).and.$ff),src-work(a6)
	.else
	lea	dest-src-2(pc,d0.w),a0
	dc.b	0,0	*for test
	.endif
	endm

patch_w2	macro	cmd,src,dest
	.iff	(debug.and.2)
	move.w	#cmd+((dest-src-2).and.$ff),src
	.else
	lea	dest-src-2(pc,d0.w),a0
	dc.b	0,0	*for test
	.endif
	endm

patch_x	macro	src,dest
*	fail	(((dest-work).slt.-32768).or.((dest-work).sgt.32767))
	.iff	(debug.and.2)
	move.l	#$4eae*65536+((dest-work).and.$ffff),src-work(a6)
	.else
	dc.w	0
	lea	dest-work(pc),a0
	dc.w	0
	.endif
	endm

patch_x2	macro	src,dest
*	fail	(((dest-work).slt.-32768).or.((dest-work).sgt.32767))
	.iff	(debug.and.2)
	move.l	#$4eae*65536+((dest-work).and.$ffff),src
	.else
	dc.w	0
	lea	dest-work(pc),a0
	dc.w	0
	.endif
	endm

t_dat_ok	macro
	moveq.l	#0,d0
	rts
	endm

reduce_range	macro	reg,min,max
	* < reg.w=-32768～+32767
	* > reg.w=-128～+127
	local	rav0
	local	rav1
	cmpi.w	#min,reg
	bge	rav0
	move.w	#min,reg
	bra	rav1
rav0:
	cmpi.w	#max,reg
	ble	rav1
	move.w	#max,reg
rav1:
	endm

reduce_range_l	macro	reg,min,max
	* < reg.l=-32768～+32767
	* > reg.w=-128～+127
	local	rav0
	local	rav1
	cmpi.l	#min,reg
	bge	rav0
	move.w	#min,reg
	bra	rav1
rav0:
	cmpi.l	#max,reg
	ble	rav1
	move.w	#max,reg
rav1:
	endm

chg64_683	macro	reg	*64range -> 683 range
	local	c66_0,c66_1,c66_2
	cmpi.l	#3000,reg
	bgt	c66_0
	cmpi.l	#-3000,reg
	bge	c66_1
c66_0:
	divs	#3,reg
	ext.l	reg
	asl.l	#5,reg
	bra	c66_2
c66_1:
	asl.l	#5,reg
	divs	#3,reg
c66_2:
	endm

chg64_683_	macro	reg	*64range -> 683 range
	local	c66_0,c66_1,c66_2
	cmpi.l	#3000,reg
	bgt	c66_0
	cmpi.l	#-3000,reg
	bge	c66_1
c66_0:
	divs	#3,reg
	ext.l	reg
	asl.l	#5,reg
	bra	c66_2
c66_1:
	asl.l	#5,reg
	divs	#3,reg
	ext.l	reg		*ここが上と違う
c66_2:
	endm

	*MIDI ボードのアドレス
ivr:	equ	$eafa01
rgr: 	equ	$eafa03
isr: 	equ	$eafa05
icr:	equ	$eafa07
grp4: 	equ	icr+2
grp5:	equ	grp4+2
grp6: 	equ	grp5+2
grp7:	equ	grp6+2

scc_a:	equ	$e98005

zmd_j_tbl	macro	xx
n	set	play_end_&xx
	dc.l	rest_&xx			*$80 休符 R
	dc.l	wait_&xx			*$81 ウェイト @W
	dc.l	track_delay_&xx			*$82 トラックディレイ
	dc.l	mx_key_&xx			*$83 MXDRVコンバート用KEY ON
	dc.l	portament_&xx			*$84 ポルタメント ()
	dc.l	portament2_&xx			*$85 ポルタメント2 []
	dc.l	n,n
	dc.l	n,n,n,n,n,n,n,n
	dc.l	volume_&xx			*$90 VOLUME V/@V(127段階)
	dc.l	rltv_vol_&xx			*$91 相対ボリューム @V
	dc.l	rltv_vol2_&xx			*$92 相対ボリューム @V
	dc.l	velocity_&xx			*$93 ベロシティ @U
	dc.l	rltv_velo_&xx			*$94 相対ベロシティ・アップ／ダウン
	dc.l	pmod_mode_&xx			*$95 PMODモード選択 M
	dc.l	pmod_sw_&xx			*$96 PMODスイッチ @M
	dc.l	pmod_sync_&xx			*$97 モジュレーションホールド H
	dc.l	bend_sw_&xx			*$98 ピッチベンド・スイッチ @B
	dc.l	aftc_sw_&xx			*$99 アフタータッチ・シーケンススイッチ @Z
	dc.l	aftc_sync_&xx			*$9a アフタータッチ・シーケンススイッチ @Z
	dc.l	vseq_sw_&xx			*$9b ベロシティ・シーケンス・スイッチ
	dc.l	agogik_sw_&xx			*$9c アゴーギク・スイッチ
	dc.l	agogik_sync_&xx			*$9d アゴーギク・ホールド
	dc.l	tie_mode_&xx			*$9e タイモード指定(MIDI専用) "
	dc.l	pcm_mode_&xx			*$9f PCM MODE
	dc.l	panpot_&xx			*$a0 パンポット絶対指定 P/@P
	dc.l	rltv_pan_&xx			*$a1 パンポット相対指定 P/@P
	dc.l	slot_mask_&xx			*$a2 OPMマスク切り換え
	dc.l	damper_&xx			*$a3 DUMPER @D
	dc.l	track_mode_&xx			*$a4 non key off mode @R
	dc.l	bend_range_&xx			*$a5 BEND RANGE CHANGE @G
	dc.l	frq_chg_&xx			*$a6 ADPCM FRQ CHANGE @F
	dc.l	n				*$a7
	dc.l	ch_pressure_&xx			*$a8 チャンネル・プレッシャー
	dc.l	rltv_ch_pressure_&xx		*$a9 チャンネル・プレッシャー相対
	dc.l	kill_note_&xx			*$aa 強制キーオフ `
	dc.l	key_transpose_&xx		*$ab キートランスポーズ K
	dc.l	voice_reserve_&xx		*$ac 発音数予約 [VOICE_RESERVE]
	dc.l	vseq_sync_&xx			*$ad ベロシティ・シーケンス同期
	dc.l	n,n				*$ae～$af
	dc.l	pmod_wf_&xx			*$b0 PMOD波形タイプセレクト S
	dc.l	agogik_wf_&xx			*$b1 アゴーギク波形タイプセレクト
	dc.l	len0_note_&xx			*$b2 V2音長0ノート発音
	dc.l	arcc_sw_&xx			*$b3 ARCCスイッチ @A
	dc.l	arcc_mode_&xx			*$b4 ARCCモード選択 M
	dc.l	arcc_sync_&xx			*$b5 モジュレーション・ホールド H
	dc.l	opm_regset_&xx			*$b6 OPMレジスタ書き込み
	dc.l	rltv_opm_regset_&xx		*$b7 相対OPMレジスタ書き込み
	dc.l	detune_@b_&xx			*$b8 デチューン @B
	dc.l	detune_@k_&xx			*$b9 デチューン @K
	dc.l	rltv_@b_&xx			*$ba 相対ディチューン @B
	dc.l	rltv_@k_&xx			*$bb 相対ディチューン @K
	dc.l	reg_set_&xx			*$bc レジスタ書き込み Y
	dc.l	forceplay_&xx			*$bd 強制再演奏 Jn
	dc.l	send_sync_&xx			*$be シンクロ信号送信 Wn
	dc.l	Q_gate_&xx			*$bf Q/@Qコマンド(CONVERTER専用)
	dc.l	polyphonic_pressure_&xx		*$c0 ﾎﾟﾘﾌｫﾆｯｸﾌﾟﾚｯｼｬｰ 絶対&相対
	dc.l	tempo_@t_&xx			*$c1 テンポ @T
	dc.l	rltv_@t_&xx			*$c2 相対テンポ @T±n
	dc.l	tempo_t_&xx			*$c3 テンポ T
	dc.l	rltv_t_&xx			*$c4 相対テンポ T±n
	dc.l	seq_cmd_&xx			*$c5 SEQUENCE CMD []
	dc.l	bank_select_&xx			*$c6 bank select I
	dc.l	timbre_&xx			*$c7 音色切り換え @
	dc.l	timbre2_&xx			*$c8 音色切り換え2 [TIMBRE]
	dc.l	arcc_wf_&xx			*$c9 ARCC波形タイプセレクト S
	dc.l	ID_set_&xx			*$ca ID SET @I
	dc.l	jump_ope3_&xx			*$cb [jump nn]
	dc.l	asgn_chg_&xx			*$cc アサイン変更 @N
	dc.l	repeat_start_&xx		*$cd |:
	dc.l	repeat_end_&xx			*$ce :|
	dc.l	NRPN_&xx			*$cf NRPN set @Y
	dc.l	segno_&xx			*$d0 [segno]
	dc.l	coda_&xx			*$d1 [coda]
	dc.l	skip_zmd_&xx			*$d2 ダミー
	dc.l	ds_&xx				*$d3 [d.s.]
	dc.l	tocoda_&xx			*$d4 [tocoda]
	dc.l	gosub_&xx			*$d5 GOSUB
	dc.l	ch_fader_&xx			*$d6 チャンネル・フェーダー \n
	dc.l	master_fader_&xx		*$d7 マスター・フェーダー
	dc.l	repeat_skip_&xx			*$d8 |n
	dc.l	repeat_skip2_&xx		*$d9 |only
	dc.l	pmod_deepen_&xx			*$da PMOD振幅増減
	dc.l	arcc_deepen_&xx			*$db ARCC振幅増減
	dc.l	vseq_deepen_&xx			*$dc VSEQ振幅増減
	dc.l	agogik_deepen_&xx		*$dd アゴーギク振幅増減
	dc.l	timbre_split_&xx		*$de 音色スプリット
	dc.l	vseq_wf_&xx			*$df EXベロシティ波形タイプセレクト
	dc.l	bend_@b_&xx			*$e0 オートベンド @B
	dc.l	bend_@k_&xx			*$e1 オートベンド @K
	dc.l	pmod8_&xx			*$e2 PMOD振幅 @M (1/8)
	dc.l	pmod_speed8_&xx			*$e3 PMODスピード @S (8point)
	dc.l	pmod_delay8_&xx			*$e4 PMODディレイ @H (8point)
	dc.l	arcc8_&xx			*$e5 ARCC振幅 @A (1/8)
	dc.l	arcc_speed8_&xx			*$e6 ARCCスピード @S (8point)
	dc.l	arcc_delay8_&xx			*$e7 ARCCディレイ @H (8point)
	dc.l	aftertouch_&xx			*$e8 ｱﾌﾀｰﾀｯﾁ･ｼｰｹﾝｽ(1/8) @Z
	dc.l	aftc_delay8_&xx			*$e9 ｱﾌﾀｰﾀｯﾁ･ｼｰｹﾝｽ･ﾃﾞｨﾚｲ(optional 8point)
	dc.l	vseq8_&xx			*$ea ベロシティ・シーケンス振幅 (8point)
	dc.l	vseq_speed8_&xx			*$eb ベロシティ・シーケンス・スピード (8point)
	dc.l	vseq_delay8_&xx			*$ec ベロシティ・シーケンス・ディレイ (8point)
	dc.l	agogik8_&xx			*$ed アゴーギク振幅(1/8)
	dc.l	agogik_speed8_&xx		*$ee アゴーギク・スピード(8point)
	dc.l	agogik_delay8_&xx		*$ef アゴーギク・ディレイ(8point)
	dc.l	effect_ctrl_&xx			*$f0 ｴﾌｪｸﾄｺﾝﾄﾛｰﾙ @E
	dc.l	poke_&xx			*$f1 ワーク直接書き換え直接 ?
	dc.l	rltv_poke_&xx			*$f2 ワーク直接書き換え相対 ?
	dc.l	exclusive_&xx			*$f3 Exclusive Send X
	dc.l	midi_transmission_&xx		*$f4 MIDI生データ転送 @X
	dc.l	loop_&xx			*$f5 LOOP終端
	dc.l	auto_portament_&xx		*$f6 オートポルタメント
	dc.l	asgn_arcc_&xx			*$f7 ARCCコントロール定義 @C
	dc.l	event_&xx			*$f8 イベント制御
	dc.l	return_&xx			*$f9 RETURN
	dc.l	next_cmd_&xx			*$fa ダミー
	dc.l	waiting_&xx			*$fb 同期待ち W
	dc.l	fine_&xx			*$fc [fine]
	dc.l	n				*$fd
	dc.l	measure_&xx			*$fe 小節線
	dc.l	play_end_&xx			*$ff 演奏終了
	endm

	.list
