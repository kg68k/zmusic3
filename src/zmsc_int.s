*拍子処理を行う(保留)
*相対系でステップタイムを付けるバリエーションを設ける(保留)
*-------------------------------------------------------
*
*		割り込み処理部分ソースリスト
*
*		 Programmed by Z.Nishikawa
*
*-------------------------------------------------------
		.include	data_io.s
		.text
					*効果音エントリ
do_se_ope:				*効果音ルーチンの実質的なエントリ
@@:
	tst.l	jump_flg1-work(a6)	*ジャンプ系コマンドはルーチンを共有できない
	bne	@b
@@:
	tst.l	jump_flg2-work(a6)
	bne	@b
@@:
	tst.l	jump_flg3-work(a6)
	bne	@b
					*アゴーギク処理
agogik_base_se:	equ	(agogik_work_se-work)-(pmod_param-track_work)
	tst.b	p_pmod_sw+agogik_base_se(a6)
	beq	1f
	lea	agogik_base_se(a6),a5
	bset.b	#b_pmod_first,p_pmod_flg(a5)
	bne	pmdop_2nd_se
	move.b	#2,p_pmod_chain(a5)		*即接続(つまり同期)	3/15
*!3/15	move.b	#1,p_pmod_chain(a5)		*接続待機
*!	tst.w	p_pmod_dpt_now(a5)
*!	bne	@f
*!	addq.b	#1,p_pmod_chain(a5)		*即接続(つまり同期)
*!@@:
	moveq.l	#0,d5
	moveq.l	#0,d6
	bsr	fm_pmod
	bra	@f
pmdop_2nd_se:					*2回目以降
	bsr	pmod_ope
@@:
	bsr	do_agogik_se
1:
	move.l	play_trk_tbl_se(pc),a5
	bra	@f
m_int_lp_se:
	move.l	4(a6),a5
@@:
	moveq.l	#0,d0
	move.w	(a5)+,d0
	bmi	exit_int_se		*$ffなら未使用
mil_patch_se:
	nop				*jump系コマンド実行時にパッチ(bsr check_jump?_tr_id_se)
	move.l	a5,4(a6)
	swap	d0
	lsr.l	#16-trwk_size_,d0
	movea.l	seq_wk_tbl_se(pc),a5
	adda.l	d0,a5			*a5=trk n seq_wk_tbl
	clr.b	p_trk_seq_flg(a5)
	move.l	p_type(a5),d4		*get ch(This is the global value.)
	move.b	p_track_stat(a5),d0
	andi.b	#(.not.ID_SE),d0
	bne	m_int_lp_se		*case:-1 死んでいるならばなにもしない
	subq.b	#1,p_trkfrq_wk(a5)	*割り込み比率処理
	bcc	m_int_lp_se
	move.b	p_trkfrq(a5),p_trkfrq_wk(a5)
	move.l	p_int_play_ope(a5),a1
	jsr	(a1)
	bra	m_int_lp_se

exit_int_se:				*演奏割り込みルーチンの出口
int_dummy:
	rts

check_jump2_tr_id_se:			*[@]フェーズ2実行ルーチン
	move.l	jump_flg_ptr(pc),a1
	cmp.w	2(a1),d7		*jump_flgの示すトラックIDと今回の実行トラックが等しいか
	beq	end_jump2_mode_se	*等しいならば走査が一周したことを意味する
	rts

check_jump3_tr_id_se:			*[jump nn]フェーズ2実行ルーチン
	move.l	jump_flg_ptr(pc),a1
	cmp.w	2(a1),d7		*jump_flgの示すトラックIDと今回の実行トラックが等しいか
	beq	end_jump3_mode_se	*等しいならば走査が一周したことを意味する
	rts

int_entry_f:			*FM音源タイマ割り込みのエントリー
	* 汎用レジスタ群	d0 d1 d2 d3 d5 d6 d7
	*			a1 a2 a3(run_cmd_**以降ではグローバル)
	*			a4(MIDIデータ送信で必ず破壊される)
	* グローバルレジスタ群             d4     a0 (a3) a5 a6
	movem.l	d0-d7/a0-a6,-(sp)
	di_tmf
	ori.w	#$0700,sr
	move.w	$003c(sp),d7
	ori.w	#$2000,d7
int_entry_again:
	lea	work(pc),a6
1:
	move.b	fm_data_port,d0
	bmi	1b
	andi.w	#3,d0
	ext.w	d0
	lsl.w	#3,d0
	move.l	fmint_tbl+4(pc,d0.w),a0
	jmp	(a0)

int_entry_both:				*効果音割り込みと音楽割り込みが併発
	move.b	#$14,fm_addr_port
	move.w	fmint_tbl(pc,d0.w),d0
	and.b	timer_mask(pc),d0
	move.b	d0,$14+opmreg(a6)	*(音楽、効果音ともにOPMタイマ使用時のみに発生する)
	opmwait
	move.b	d0,fm_data_port
	opmwait
	move.w	d7,sr			*srを割り込み発生前に戻す
	bsr	inc_zmint		*音楽演奏処理へ
	move.l	sub_job_entry(pc),a0
	cmpi.l	#'独立',-4(a0)		*"独立"マークがあるとノーチェック
	beq	@f
	tst.l	sp_buf-work(a6)		*異常複数割り込み対処
	bne	exit_int_e
@@:
	jsr	(a0)			*効果音(SUB JOB)処理へ
exit_int_e:
	move.w	sr,d7
exit_int_e1:
	ori.w	#$0700,sr
exit_int_e2:
	move.b	fm_data_port,d0
	andi.w	#3,d0
	bne	int_entry_again
	movem.l	(sp)+,d0-d7/a0-a6
	ei_tmf
	rte				*割り込み処理終了

fmint_tbl:
		dc.l	0		*%00:これでエントリすることはあり得ないが、念のため
		dc.l	exit_int_e
tm_a_reset:	dc.w	%0001_1111,0	*%01:timer a
tm_a_entry:	dc.l	int_entry_fm
tm_b_reset:	dc.w	%0010_1111,0	*%10:timer b
tm_b_entry:	dc.l	int_entry_sub
tm_ab_reset:	dc.w	%0011_1111,0	*%11:both timer made overflow.
tm_ab_entry:	dc.l	int_entry_both	*midiタイマの時はint_entry_sub
sub_job_entry:	dc.l	do_se_ope

int_entry_fm:				*音楽演奏割り込みエントリ
	move.b	#$14,fm_addr_port
	move.w	fmint_tbl(pc,d0.w),d0
	and.b	timer_mask(pc),d0
	move.b	d0,$14+opmreg(a6)
	opmwait
	move.b	d0,fm_data_port
	opmwait
	move.w	d7,sr			*srを割り込み発生前に戻す
ief_patch:				*MIDIタイマ使用時にはパッチが当たる(NOP_NOP)
	bsr.w	inc_zmint
	bra	exit_int_e

int_entry_sub:				*ここは必ずOPMタイマ
	move.b	#$14,fm_addr_port
	move.w	fmint_tbl(pc,d0.w),d0
	and.b	timer_mask(pc),d0
	move.b	d0,$14+opmreg(a6)
	opmwait
	move.b	d0,fm_data_port
	opmwait

	move.l	sub_job_entry(pc),a0
	cmpi.l	#'独立',-4(a0)		*"独立"マークがあるとノーチェック
	beq	@f
	tst.l	sp_buf-work(a6)		*異常複数割り込み対処
	bne	exit_int_e2
	cmpa.l	#do_se_ope,a0		*効果音ルーチンの場合は排他処理不要
	beq	@f
	cmpa.l	#smf_entry,a0		*SMF再生ルーチンの場合は排他処理不要
	beq	@f
					*音楽演奏処理と競合してはまずいケース(ZP3 -K,ZP3 -B)
	tst.b	excint_flg-work(a6)	*排他フラグチェック
	bne	exit_int_e2		*音楽演奏処理中なのでスキップ
	jsr	(a0)			*効果音(SUB JOB)処理へ
	bra	exit_int_e2
@@:					*音楽演奏と競合しないケース
	move.w	d7,sr			*srを割り込み発生前に戻す
	jsr	(a0)			*効果音(SUB JOB)処理へ
	bra	exit_int_e1

int_entry_m:				*MIDI-TIMER割り込みエントリー
	movem.l	d0-d7/a0-a6,-(sp)
	lea	work(pc),a6
	di_tmm
	ori.w	#$0700,sr
	move.w	$003c(sp),d0
	ori.w	#$2000,d0
	st.b	excint_flg-work(a6)	*排他フラグON
	move.w	d0,sr			*SRを割り込み発生前に戻す
	bsr	inc_zmint
	ori.w	#$0700,sr		*全マスク(ZMUSICへの二重割り込み防止)
	clr.b	excint_flg-work(a6)	*排他フラグOFF
	ei_tmm
	movem.l	(sp)+,d0-d7/a0-a6
	rte				*割り込み処理終了

int_entry_e:				*プレイバック割り込みエントリ
	movem.l	d0-d7/a0-a6,-(sp)
	lea	work(pc),a6
	di_tme
	ori.w	#$0700,sr
	move.w	$003c(sp),d0
	ori.w	#$2000,d0
	st.b	excint_flg-work(a6)	*排他フラグON
	move.w	d0,sr			*SRを割り込み発生前に戻す
	bsr	inc_zmint
	ori.w	#$0700,sr		*全マスク(ZMUSICへの二重割り込み防止)
	clr.b	excint_flg-work(a6)	*排他フラグOFF
	ei_tme
	movem.l	(sp)+,d0-d7/a0-a6
	rte				*割り込み処理終了

check_nc_clock:				*(jump after n clocks)オンの時
	move.l	obtevtjtbl-work+nc_clock(a6),d0
	addq.l	#1,zmusic_int-work(a6)
	cmp.l	zmusic_int(pc),d0	*希望クロックになったか
	bne	inc_zmint_end
	move.l	obtevtjtbl-work+nc_jump(a6),a0		*希望クロックになったら
	jmp	(a0)					*飛ぶ

chfd_move	macro	exit_chfdmv	*チャンネルフェーダー移動処理
	* < a4.l=ch_fader_tbl+n
	* < a2.l=ch_nn_fdp
	* > (a2)=0ならば目的を達成している
	* X d0,d1,a1
	move.b	fd_mode(a2),d0
	cmpi.b	#CH_FADER_RESET,d0
	bne	1f
	cmpi.b	#128,fd_lvlb(a2)	*通常レベル設定はフェーダー移動モード解除を意味する
	bne	exit_chfdmv
chfd_end:				*チャンネルフェーダーテーブルから削除する
	lea	-2(a4),a1
@@:
	move.w	(a1)+,-4(a1)
	bpl	@b
	move.l	a1,a4
	tst.w	ch_fader_tbl-work(a6)
	bpl	exit_chfdmv
	andi.b	#(.not.ff_ch_fader),fader_flag-work(a6)
	bra	exit_chfdmv
1:
	move.b	fd_dest(a2),d1	*目的値
	tst.b	d0
	beq	exit_chfdmv
				*以下フェードアウト時
	add.b	d0,fd_lvlb(a2)
	cmp.b	fd_lvlb(a2),d1
	bne	exit_chfdmv	*目的に達していないなら次回も継続
	clr.l	(a2)		*fd_spd,spd2クリア(目的レベルを維持)
	endm

mstfd_move	macro	exit_mstfdmv	*マスターフェーダー移動処理
	* < a4=master_fader_tbl+n
	* < a2=mstfd_xx_spd
	* > (a2)=0ならば目的を達成している
	* X d0,d1,a1
	move.b	fd_mode(a2),d0
	cmpi.b	#MASTER_FADER_RESET,d0
	bne	1f
	cmpi.b	#128,fd_lvlb(a2)	*通常レベル設定はフェーダー移動モード解除を意味する
	bne	exit_mstfdmv
mstfd_end:				*マスターフェーダーテーブルから削除する
	lea	-2(a4),a1
@@:
	move.w	(a1)+,-4(a1)
	bpl	@b
	move.l	a1,a4
	tst.w	master_fader_tbl-work(a6)
	bpl	exit_mstfdmv
	andi.b	#(.not.ff_master_fader).and.$ff,fader_flag-work(a6)
	bra	exit_mstfdmv
1:
	move.b	fd_dest(a2),d1		*目的値
	tst.b	d0
	beq	exit_mstfdmv
					*以下フェードアウト時
	add.b	d0,fd_lvlb(a2)
	cmp.b	fd_lvlb(a2),d1
	bne	exit_mstfdmv		*目的値に達していないなら次回も継続
	clr.l	(a2)			*fd_spd,spd2クリア(目的レベルを維持)
	endm

set_fm_tune	macro
	* < d0.b=midi note number
	* < d5.w=total kf value
	* < d4.b fm ch
	* < a0.l=opmset
	* X d0-d2,d5,a1
	andi.w	#$7f,d0		*最上位ビットがたっている場合もあるからext.wでは駄目
	move.l	fm_tune_tbl-work(a6),d2
	beq	@f
	move.l	d2,a1		*周波数テーブル考慮
	move.b	(a1,d0.w),d2
	ext.w	d2
	add.w	d2,d5
@@:
	addq.w	#5,d5		*4MHz offset
	add.w	p_detune(a5),d5	*get det. param.
	move.w	d5,d2
	asr.w	#6,d5		*d5.w=d5.w/64=kc offset value
	beq	@f
	add.w	d5,d0
	andi.w	#$003f,d2	*d2=ｱﾏﾘ
@@:
	add.b	d2,d2
	add.b	d2,d2		*２つシフト

	moveq.l	#$30,d1		*key code
	or.b	d4,d1
	jsr	(a0)		*!opmset(kf)

	tst.w	d0
	bge	@f
	moveq.l	#0,d0
	bra	1f
@@:
	cmpi.w	#127,d0
	ble	1f
	moveq.l	#127,d0
1:
	subq.b	#8,d1		*$28+n
	move.b	key_code_tbl(pc,d0.w),d2
	jsr	(a0)		*!opmset(kc)
	endm

inc_zmint:
	*(jump after n clocks)イベント・ON時には(bsr.w check_nc_clock)
	*(SMF転送時には bra smf_entry)
	addq.l	#1,zmusic_int-work(a6)		*4バイトサイズ命令
inc_zmint_end:
				*アゴーギク処理
agogik_base:	equ	(agogik_work-work)-(pmod_param-track_work)
	tst.b	p_pmod_sw+agogik_base(a6)
	beq	1f
	lea	agogik_base(a6),a5
	bset.b	#b_pmod_first,p_pmod_flg(a5)
	bne	pmdop_2nd
	move.b	#2,p_pmod_chain(a5)		*即接続(つまり同期)	3/15
*!3/15	move.b	#1,p_pmod_chain(a5)		*接続待機
*!	tst.w	p_pmod_dpt_now(a5)
*!	bne	@f
*!	addq.b	#1,p_pmod_chain(a5)		*即接続(つまり同期)
*!@@:
	moveq.l	#0,d5
	moveq.l	#0,d6
	bsr	fm_pmod
	bra	@f
pmdop_2nd:					*2回目以降
	bsr	pmod_ope
@@:
	bsr	do_agogik
1:
	move.l	play_trk_tbl(pc),a5
	move.b	fader_flag(pc),d6
	beq	mil0
****************************************MASTER FADER 処理
	bpl	ch_fader		*master fader on?
	lea	mstfd_fm_spd2(pc),a3
	lea	master_fader_tbl(pc),a4
mstfdoplp:
	move.w	(a4)+,d0	*d0 must be 0,8,16,24,32,40 or -1(予めfd_wkl倍してある)
	bmi	ch_fader
	lea	(a3,d0.w),a2
	add.w	d0,d0				*d0*16倍へ
	lea	fo_ch_fm-work(a6,d0.w),a1	*こういうワークは割り込み出口で初期化する
	move.w	fd_spd(a2),d1
	add.w	d1,fd_spd2(a2)
	bcc	mstfdop_nmv
	move.l	#$22222222,d2			*第1ビットオン
	or.l	d2,(a1)+			*16個分セット
	or.l	d2,(a1)+
	or.l	d2,(a1)+
	or.l	d2,(a1)+
	mstfd_move	mstfdoplp
	bra	mstfdoplp
mstfdop_nmv:
	move.l	#$02020202,d2			*第1ビットオン
	or.l	d2,(a1)+			*16個分セット
	or.l	d2,(a1)+
	or.l	d2,(a1)+
	or.l	d2,(a1)+
	bra	mstfdoplp
****************************************CH FADER 処理
ch_fader:
	add.b	d6,d6			*ch_fader on?
	bpl	mil0
	lea	ch_fm_fdp(pc),a3
	lea	ch_fader_tbl(pc),a4
chflp:
	move.w	(a4)+,d0		*d0 must be 0～95, or -1
	bmi	mil0
	move.w	d0,d1
	lsl.w	#fd_wkl_,d0
	lea	(a3,d0.w),a2
	move.w	fd_spd(a2),d2
	add.w	d2,fd_spd2(a2)
	bcc	chfdop_nmv
	ori.b	#$41,fo_ch_fm-work(a6,d1.w)	*第6ビットON
	chfd_move	chflp
	bra	chflp
chfdop_nmv:
	ori.b	#$01,fo_ch_fm-work(a6,d1.w)	*第0ビットON
	bra	chflp

m_int_lp:
	move.l	(a6),a5
mil0:
	moveq.l	#0,d7
	move.w	(a5)+,d7
	bmi	exit_int		*$ffなら未使用
mil_patch:
	nop				*jump系コマンド実行時にパッチ(bsr check_jump?_tr_id)
	move.l	a5,(a6)
	swap	d7
	lsr.l	#16-trwk_size_,d7
	movea.l	seq_wk_tbl(pc),a5
	adda.l	d7,a5			*a5=trk n seq_wk_tbl
	clr.b	p_trk_seq_flg(a5)
	move.l	p_type(a5),d4		*get ch(This is the global value.)
					*チャンネル・マスク・チェック
	move.w	p_type(a5),d0
	beq	@f
	bmi	chk_md_chmsk
	move.w	ch_mask_ad(pc),d0	*ADPCM
	bra	chmskchk0
@@:					*FM
	move.w	ch_mask_fm(pc),d0
	bra	chmskchk0

check_jump2_tr_id:			*[@]フェーズ2実行ルーチン
	move.l	jump_flg_ptr(pc),a1
	cmp.w	2(a1),d7		*jump_flgの示すトラックIDと今回の実行トラックが等しいか
	beq	end_jump2_mode		*等しいならば走査が一周したことを意味する
	rts

check_jump3_tr_id:			*[jump nn]フェーズ2実行ルーチン
	move.l	jump_flg_ptr(pc),a1
	cmp.w	2(a1),d7		*jump_flgの示すトラックIDと今回の実行トラックが等しいか
	beq	end_jump3_mode		*等しいならば走査が一周したことを意味する
	rts

chk_md_chmsk:				*MIDI
	add.w	d0,d0
	lea	ch_mask_m0(pc),a1
	move.w	(a1,d0.w),d0
chmskchk0:
	tst.b	p_track_stat(a5)
	bne	m_int_lp		*case:$80 死んでいるならばなにもしない
					*case:1 演奏終了しているならばなにもしない
					*p_track_stat(a5)=0だけがint_play_opeへ行ける
					*同期待ち等は当然演奏処理はスキップ
					*実際の演奏処理へ
	btst.l	d4,d0
	bne	tr_mask_mode
	tst.b	p_mask_mode(a5)		*check track mask
	bne	tr_mask_mode		*masked
	subq.b	#1,p_trkfrq_wk(a5)	*割り込み比率処理
	bcc	m_int_lp
	move.b	p_trkfrq(a5),p_trkfrq_wk(a5)
	move.l	p_int_play_ope(a5),a1
	jsr	(a1)
	bra	m_int_lp

exit_int:				*演奏割り込みルーチンの出口
	move.b	fader_flag(pc),d6
	beq	exit0
	bpl	do_ch_fader
*do_master_fader:
	lea	master_fader_tbl(pc),a0
mfdo_lp:
	move.w	(a0)+,d0		*予めfd_wkl(8)倍してある
	bmi	exit0
	lsr.w	#2,d0			*d0*2倍へ
	move.w	mstfd_jmtb(pc,d0.w),d0
	jmp	mstfd_jmtb(pc,d0.w)
mstfd_jmtb:
	dc.w	mstfd_fm_do-mstfd_jmtb
	dc.w	mstfd_ad_do-mstfd_jmtb
	dc.w	mstfd_m0_do-mstfd_jmtb
	dc.w	mstfd_m1_do-mstfd_jmtb
	dc.w	mstfd_mr0_do-mstfd_jmtb
	dc.w	mstfd_mr1_do-mstfd_jmtb

mstfd_fm_do:				*FM音源
	lea	fo_ch_fm+8(pc),a1
	lea	fm_vol_tbl+8(pc),a2
	moveq.l	#8-1,d4			*ch
mf_fm_lp:
	moveq.l	#0,d0
	move.b	-(a2),d0		*get vol
	bmi	_next_mf_fm		*処理不要
	move.b	-(a1),d7		*処理フラグ
	bmi	next_mf_fm		*すでに処理済み
	move.w	d7,d6
	andi.w	#$60,d7
	beq	next_mf_fm		*フェーダー処理不要
	lea	opmset_se(pc),a4
	bsr	do_fm_volume_fdr
next_mf_fm:
	clr.b	(a1)
	dbra	d4,mf_fm_lp
	bra	mfdo_lp
_next_mf_fm:
	clr.b	-(a1)
	dbra	d4,mf_fm_lp
	bra	mfdo_lp

mstfd_ad_do:				*ADPCM音源
	lea	fo_ch_ad+16(pc),a1
	lea	ad_vol_tbl+16(pc),a2
	moveq.l	#16-1,d4		*ch
mf_ad_lp:
	moveq.l	#0,d0
	move.b	-(a2),d0		*get vol
	bmi	_next_mf_ad		*処理不要
	move.b	-(a1),d7
	bmi	next_mf_ad		*すでに処理済み
	move.w	d7,d6
	andi.w	#$60,d7
	beq	next_mf_ad		*フェーダー処理不要
	bsr	_do_ad_volume		*フェーダー処理&音量セット
next_mf_ad:
	clr.b	(a1)
	dbra	d4,mf_ad_lp
	bra	mfdo_lp
_next_mf_ad:
	clr.b	-(a1)
	dbra	d4,mf_ad_lp
	bra	mfdo_lp

mstfd_do	macro	xx,dvid
	local	mf_lp
	local	next_mf
	local	_next_mf
	move.l	#dvid*65536+16-1,d4	*ch
mf_lp:
	moveq.l	#0,d0
	move.b	-(a2),d0		*get vol
	bmi	_next_mf			*処理不要
	move.b	-(a1),d7
	bmi	next_mf			*すでに処理済み
	move.w	d7,d6
	andi.w	#$60,d7
	beq	next_mf			*フェーダー処理不要
	bsr	consider_fader_md
	move.l	d0,d1
	bsr	do_md_volume_&xx
next_mf:
	clr.b	(a1)			*clear marker
	dbra	d4,mf_lp
	bra	mfdo_lp
_next_mf:
	clr.b	-(a1)			*clear marker
	dbra	d4,mf_lp
	bra	mfdo_lp
	endm

mstfd_m0_do:				*MIDI-0
	lea	fo_ch_m0+16(pc),a1
	lea	m0_vol_tbl+16(pc),a2
	mstfd_do	m0,DEV_MIDI1

mstfd_m1_do:				*MIDI-1
	lea	fo_ch_m1+16(pc),a1
	lea	m1_vol_tbl+16(pc),a2
	mstfd_do	m1,DEV_MIDI2

mstfd_mr0_do:				*MIDI-R0
	lea	fo_ch_mr0+16(pc),a1
	lea	mr0_vol_tbl+16(pc),a2
	mstfd_do	r0,DEV_MIDI3

mstfd_mr1_do:				*MIDI-R1
	lea	fo_ch_mr1+16(pc),a1
	lea	mr1_vol_tbl+16(pc),a2
	mstfd_do	r1,DEV_MIDI4

do_ch_fader:				*チャンネルフェーダー実行
	lea	ch_fader_tbl(pc),a0
	lea	ch_fm_fdp(pc),a3
cfdo_lp:
	move.w	(a0)+,d6		*0,1,2,3...,95
	bmi	exit0
	move.w	d6,d0
	cmpi.w	#16-1,d0
	bls	case_cfdo_fm
	lea	fo_ch_fm-work(a6,d6.w),a1
	move.b	(a1),d7
	bmi	@f			*処理済み
	add.b	d7,d7			*ch fader ope?
	bpl	@f			*no need
	moveq.l	#0,d1
	move.b	fm_vol_tbl-fo_ch_fm(a1),d1	*get vol
	bmi	@f			*処理不要
	lsl.w	#fd_wkl_,d0
	mulu	fd_lvlw(a3,d0.w),d1
	lsr.l	#7,d1
	move.w	d6,d4
	andi.w	#$0f,d4			*get ch
	lsr.w	#4,d6			*/16
	add.w	d6,d6			*2
	move.w	chfd_jmtb(pc,d6.w),d6
	jsr	chfd_jmtb(pc,d6.w)
@@:
	clr.b	(a1)
	bra	cfdo_lp

chfd_jmtb:
	dc.w	0
	dc.w	do_ad_volume_-chfd_jmtb
	dc.w	do_md_volume_m0-chfd_jmtb
	dc.w	do_md_volume_m1-chfd_jmtb
	dc.w	do_md_volume_r0-chfd_jmtb
	dc.w	do_md_volume_r1-chfd_jmtb

case_cfdo_fm:				*FMの場合特別に
	lea	fo_ch_fm-work(a6,d6.w),a1
	move.b	(a1),d7
	bmi	@f			*処理済み
	add.b	d7,d7			*ch fader ope?
	bpl	@f			*no need
	moveq.l	#0,d0
	move.b	fm_vol_tbl-fo_ch_fm(a1),d0	*get vol
	bmi	@f			*処理不要
	move.w	d6,d4			*get ch
	lea	opmset_se(pc),a4
	bsr	do_fm_volume_fdr
@@:
	clr.b	(a1)
	bra	cfdo_lp

exit0:					*演奏割り込み処理の出口
	rts

tr_mask_mode:				*トラック/チャンネル・マスク時
	subq.b	#1,p_trkfrq_wk(a5)	*割り込み比率処理
	bcc	m_int_lp
	move.b	p_trkfrq(a5),p_trkfrq_wk(a5)
	lea	tmm_bak(pc),a1
	move.w	key_on_fm_patch(pc),(a1)+	*パッチ先を保存
	move.w	key_on_ad_patch(pc),(a1)+
	move.w	key_on_md_patch(pc),(a1)+
	patch_w	BRA,key_on_fm_patch,do_fmhlo
	move.w	#RTS,key_on_ad_patch-work(a6)
	patch_w	BRA,key_on_md_patch,konmdlp
	bsr	cache_flush

	move.l	p_int_play_ope(a5),a1
	jsr	(a1)

	lea	tmm_bak(pc),a1
	move.w	(a1)+,key_on_fm_patch-work(a6)
	move.w	(a1)+,key_on_ad_patch-work(a6)
	move.w	(a1)+,key_on_md_patch-work(a6)
	bsr	cache_flush
	bra	m_int_lp

tmm_bak:
	ds.l	3

consider_fader_fm_n:			*FADERを考慮したボリューム値を決める(FM)
	* < d4.w=ch			*ノイズオシレータ専用ルーチン
	* < d0.w=source vol(0-127)
	* > d0.w=true volume(127-0)
	* - all
reglist	reg	d1/d3-d4/a3-a4
	movem.l	reglist,-(sp)
	lea	fmtlcnvtbl_n(pc),a3
	bra	@f

consider_fader_fm:			*FADERを考慮したボリューム値を決める(FM)
	* < d4.w=ch
	* < d0.w=source vol(0-127)
	* > d0.w=true volume(127-0)
	* - all
reglist	reg	d1/d3-d4/a3-a4
	movem.l	reglist,-(sp)
	lea	fmtlcnvtbl(pc),a3	*!linear
@@:
	lea	fm_vol_tbl(pc),a4
	add.w	d4,a4
	move.b	d0,(a4)			*ボリュームをしまう
	move.b	fo_ch_fm-fm_vol_tbl(a4),d1
	beq	exit_csfm
	tas.b	fo_ch_fm-fm_vol_tbl(a4)
	moveq.l	#0,d3
	lsr.b	#1,d1
	bcc	@f
	lsl.w	#fd_wkl_,d4
	lea	ch_fm_fdp(pc),a4
	move.w	fd_lvlw(a4,d4.w),d4	*!linear
	add.w	d4,d4			*!linear
	mulu	(a3,d4.w),d0		*!linear
	addq.w	#7,d3
@@:
	lsr.b	#1,d1				*master fader ope
	bcc	@f
	move.w	mstfd_fm_lvlw(pc),d4	*!linear
	add.w	d4,d4			*!linear
	mulu	(a3,d4.w),d0		*!linear
	addq.w	#7,d3
@@:
	lsr.l	d3,d0
exit_csfm:
	movem.l	(sp)+,reglist
	eori.w	#$7f,d0				*127-0
	rts

fmtlcnvtbl:	*線形変化→指数変化変換テーブル
*	dc.w	$00,$0c,$18,$25,$31,$3e,$4a,$57		*BY ZEN
*	dc.w	$58,$58,$58,$59,$59,$59,$5a,$5a
*	dc.w	$5a,$5b,$5b,$5b,$5c,$5c,$5c,$5d
*	dc.w	$5d,$5d,$5e,$5e,$5e,$5f,$5f,$5f
*	dc.w	$60,$60,$60,$61,$61,$61,$62,$62
*	dc.w	$62,$63,$63,$63,$64,$64,$64,$65
*	dc.w	$65,$65,$66,$66,$66,$67,$67,$67
*	dc.w	$68,$68,$68,$69,$69,$69,$6a,$6a
*	dc.w	$6a,$6a,$6b,$6b,$6b,$6c,$6c,$6c
*	dc.w	$6d,$6d,$6d,$6e,$6e,$6e,$6f,$6f
*	dc.w	$6f,$70,$70,$70,$71,$71,$71,$72
*	dc.w	$72,$72,$73,$73,$73,$74,$74,$74
*	dc.w	$75,$75,$75,$76,$76,$76,$77,$77
*	dc.w	$77,$78,$78,$78,$79,$79,$79,$7a
*	dc.w	$7a,$7a,$7b,$7b,$7b,$7c,$7c,$7c
*	dc.w	$7d,$7d,$7d,$7e,$7e,$7e,$7f,$7f
*	dc.w	$80

        .dc.w     0, 20, 33, 41, 47, 54, 58, 63, 66, 70, 73, 76, 78, 81, 83, 84
        .dc.w    86, 87, 88, 89, 90, 91, 91, 92, 93, 94, 94, 95, 95, 96, 96, 97
        .dc.w    97, 97, 98, 98, 98, 99, 99,100,100,100,101,101,101,102,102,102
        .dc.w   103,103,103,104,104,104,105,105,105,105,106,106,106,107,107,107
        .dc.w   108,108,108,109,109,109,109,110,110,110,111,111,111,112,112,112
        .dc.w   112,113,113,113,114,114,114,115,115,115,116,116,116,116,117,117
        .dc.w   117,118,118,118,119,119,119,119,120,120,120,121,121,121,122,122
        .dc.w   122,123,123,123,123,124,124,124,125,125,125,126,126,126,127,127
        .dc.w   128

fmtlcnvtbl_n:
        .dc.w     0,  0,  1,  1,  2,  2,  2,  3,  3,  3,  3,  4,  4,  4,  4,  5
        .dc.w     5,  5,  5,  6,  6,  6,  6,  7,  7,  7,  7,  8,  8,  8,  8,  9
        .dc.w     9,  9,  9, 10, 10, 10, 11, 11, 11, 11, 12, 12, 12, 13, 13, 14
        .dc.w    14, 14, 15, 15, 16, 16, 16, 17, 17, 18, 18, 19, 19, 20, 20, 21
        .dc.w    22, 22, 23, 24, 24, 25, 26, 27, 27, 28, 29, 30, 31, 31, 32, 33
        .dc.w    34, 35, 36, 37, 38, 39, 41, 42, 43, 44, 45, 47, 48, 49, 51, 52
        .dc.w    53, 55, 56, 58, 60, 61, 63, 65, 67, 69, 71, 73, 75, 77, 79, 81
        .dc.w    83, 85, 87, 90, 92, 95, 97,100,103,106,109,112,115,119,123,127
        .dc.w   128

consider_fader_ad:			*FADERを考慮したボリューム値を決める(ADPCM)
	* < d4.w=ch
	* < d0.w=source vol(0-127)
	* > d0.w=true volume(0-127)
	* - all
reglist	reg	d1/d3-d4/a4
	movem.l	reglist,-(sp)
	lea	ad_vol_tbl(pc),a4
	add.w	d4,a4
	move.b	d0,(a4)				*ボリュームをしまう
cfa_patch:
	moveq.l	#127,d0				*非MPCM.XモードではNOP
	move.b	fo_ch_ad-ad_vol_tbl(a4),d1
	beq	exit_csad
	tas.b	fo_ch_ad-ad_vol_tbl(a4)
	moveq.l	#0,d3
	lsr.b	#1,d1
	bcc	@f
	lsl.w	#fd_wkl_,d4
	lea	ch_ad_fdp(pc),a4
	mulu	fd_lvlw(a4,d4.w),d0
	addq.w	#7,d3
@@:
	lsr.b	#1,d1				*master fader ope
	bcc	@f
	mulu	mstfd_ad_lvlw(pc),d0
	addq.w	#7,d3
@@:
	lsr.l	d3,d0
exit_csad:
	movem.l	(sp)+,reglist
	rts

consider_fader_md:			*FADERを考慮したボリューム値を決める(MIDI)
	* < d4.w=ch
	* < d0.w=source vol(0-127)
	* > d0.w=true volume(0-127)
	* - all
reglist	reg	d1/d3-d4/a4
	movem.l	reglist,-(sp)
	move.l	d4,d1
	swap	d1
@@:
	add.w	d1,d1
	move.w	cfmjtbl+2(pc,d1.w),d1
	jmp	cfmjtbl(pc,d1.w)
cfmjtbl:
	dc.w	cfm_mX-cfmjtbl
	dc.w	cfm_m0-cfmjtbl
	dc.w	cfm_m1-cfmjtbl
	dc.w	cfm_mr0-cfmjtbl
	dc.w	cfm_mr1-cfmjtbl
cfm_mX:
	move.w	current_midi_out_w(pc),d1
	bra	@b
cfm_m0:
	lea	m0_vol_tbl(pc),a4
	add.w	d4,a4
	move.b	d0,(a4)				*ボリュームをしまう
	move.b	fo_ch_m0-m0_vol_tbl(a4),d1
	beq	exit_csm0
	tas.b	fo_ch_m0-m0_vol_tbl(a4)
	moveq.l	#0,d3
	lsr.b	#1,d1
	bcc	@f
	lsl.w	#fd_wkl_,d4
	lea	ch_m0_fdp(pc),a4
	mulu	fd_lvlw(a4,d4.w),d0
	addq.w	#7,d3
@@:
	lsr.b	#1,d1				*master fader ope
	bcc	@f
	mulu	mstfd_m0_lvlw(pc),d0
	addq.w	#7,d3
@@:
	lsr.l	d3,d0
exit_csm0:
	movem.l	(sp)+,reglist
	rts

cfm_m1:
	lea	m1_vol_tbl(pc),a4
	add.w	d4,a4
	move.b	d0,(a4)				*ボリュームをしまう
	move.b	fo_ch_m1-m1_vol_tbl(a4),d1
	beq	exit_csm1
	tas.b	fo_ch_m1-m1_vol_tbl(a4)
	moveq.l	#0,d3
	lsr.b	#1,d1
	bcc	@f
	lsl.w	#fd_wkl_,d4
	lea	ch_m1_fdp(pc),a4
	mulu	fd_lvlw(a4,d4.w),d0
	addq.w	#7,d3
@@:
	lsr.b	#1,d1				*master fader ope
	bcc	@f
	mulu	mstfd_m1_lvlw(pc),d0
	addq.w	#7,d3
@@:
	lsr.l	d3,d0
exit_csm1:
	movem.l	(sp)+,reglist
	rts

cfm_mr0:
	lea	mr0_vol_tbl(pc),a4
	add.w	d4,a4
	move.b	d0,(a4)				*ボリュームをしまう
	move.b	fo_ch_mr0-mr0_vol_tbl(a4),d1
	beq	1f
	tas.b	fo_ch_mr0-mr0_vol_tbl(a4)
	moveq.l	#0,d3
	lsr.b	#1,d1
	bcc	@f
	lsl.w	#fd_wkl_,d4
	lea	ch_mr0_fdp(pc),a4
	mulu	fd_lvlw(a4,d4.w),d0
	addq.w	#7,d3
@@:
	lsr.b	#1,d1				*master fader ope
	bcc	@f
	mulu	mstfd_mr0_lvlw(pc),d0
	addq.w	#7,d3
@@:
	lsr.l	d3,d0
1:
	movem.l	(sp)+,reglist
	rts

cfm_mr1:
	lea	mr1_vol_tbl(pc),a4
	add.w	d4,a4
	move.b	d0,(a4)				*ボリュームをしまう
	move.b	fo_ch_mr1-mr1_vol_tbl(a4),d1
	beq	1f
	tas.b	fo_ch_mr1-mr1_vol_tbl(a4)
	moveq.l	#0,d3
	lsr.b	#1,d1
	bcc	@f
	lsl.w	#fd_wkl_,d4
	lea	ch_mr1_fdp(pc),a4
	mulu	fd_lvlw(a4,d4.w),d0
	addq.w	#7,d3
@@:
	lsr.b	#1,d1				*master fader ope
	bcc	@f
	mulu	mstfd_mr1_lvlw(pc),d0
	addq.w	#7,d3
@@:
	lsr.l	d3,d0
1:
	movem.l	(sp)+,reglist
	rts

port_ope	macro			*ポルタメント処理
	* X d0
	move.l	p_port_step(a5),d0
	add.l	d0,p_port_pitch(a5)
	endm

pmod_ope:				*ピッチモジュレーションパラメータ演算処理
	* X d0-d2,a1			*(含む波形接続処理)
	btst.b	#b_pmod_wvsq,p_pmod_flg(a5)	*波形進行音符毎モードか
	beq	@f
	cmpi.w	#1,(a5)
	bne	exit_pmod_ope
	btst.b	#b_pmod_wvsqrst,p_pmod_flg(a5)
	bne	@f
	movea.l	p_data_pointer(a5),a1	*compiled data address
	cmpi.b	#rest_zmd,(a1)
	beq	exit_pmod_ope		*休符では更新せず
	subq.w	#1,p_pmod_syncnt2(a5)
	bne	exit_pmod_ope
	move.w	p_pmod_syncnt(a5),p_pmod_syncnt2(a5)
@@:
	subq.w	#1,p_pmod_dly2(a5)
	bne	pm_chain?
	moveq.l	#0,d0
	move.b	p_pmod_n(a5),d0
	addq.b	#1,d0			*-1.bでエントリのケースもあり(だから.b)
	cmpi.b	#7,d0
	bhi	pm_chain?		*最後のを継続して使用
	move.b	d0,p_pmod_n(a5)
	btst.b	d0,p_pmod_omt(a5)	*省略の場合は前回のものを継続
	beq	po0
	add.w	d0,d0
	move.w	p_pmod_dpt_tbl(a5,d0.w),p_pmod_dpt_now(a5)
	move.w	p_pmod_8st_tbl(a5,d0.w),p_pmod_dly2(a5)
	move.w	p_pmod_spd_tbl(a5,d0.w),d2	*次の波形生成パラメータ
	bne	@f
	move.w	p_pmod_spd(a5),d2
@@:
	add.w	d0,d0
	move.l	p_pmod_stp_tbl(a5,d0.w),d1	*次の波形生成パラメータ
	tst.b	p_pmod_chain(a5)
	bne	check_cnct_pm
go_connect_pm:				*波形接続へ
	move.w	p_pmod_wf(a5),d0	*波形タイプ検査
	bmi	smt_pm_us
	add.w	d0,d0
	move.w	smtp(pc,d0.w),d0
	jmp	smtp(pc,d0.w)
smtp:	dc.w	smt_swp-smtp		*case0:saw
	dc.w	smt_sqp-smtp		*case1:squ
	dc.w	smt_trp-smtp		*case2:tri
	dc.w	smt_swp2-smtp		*case3:sp_saw
	dc.w	smt_pm_ns-smtp		*case4:noise
po0:
	add.w	d0,d0
	move.w	p_pmod_8st_tbl(a5,d0.w),p_pmod_dly2(a5)
	bra	fmpmod1
pm_chain?:
	move.b	p_pmod_chain(a5),d0
	beq	exit_pmod_ope		*「0:即接続」ならばディレイ処理
	bmi	fmpmod1			*「-1:波形接続処理ずみ」ならば継続
	move.l	p_pmod_step_next(a5),d1	*次の波形生成パラメータ
	move.w	p_pmod_spd_next(a5),d2
	subq.b	#1,d0			*1 or 2?
	beq	@f			*case:1
	tst.b	p_pmod_n(a5)		*case:2(=初回)
	bmi	exit_pmod_ope		*delayケース
	bra	go_connect_pm

check_cnct_pm:				*波形接続チェック
	move.l	d1,p_pmod_step_next(a5)	*次の波形生成パラメータを
	move.w	d2,p_pmod_spd_next(a5)	*セットする。
	cmpi.b	#2,p_pmod_chain(a5)	*初回ケース
	beq	go_connect_pm
@@:
	move.w	p_pmod_wf(a5),d0	*波形タイプ検査
	bmi	chk_smt_pm_us
	add.w	d0,d0
	move.w	smtp2(pc,d0.w),d0
	jmp	smtp2(pc,d0.w)
smtp2:	dc.w	chk_smt_swp-smtp2	*case0:saw
	dc.w	chk_smt_sqp-smtp2	*case1:squ
	dc.w	chk_smt_trp-smtp2	*case2:trp
	dc.w	chk_smt_swp2-smtp2	*case3:sp_saw
	dc.w	chk_smt_pm_ns-smtp2	*case4:noise

chk_smt_swp:				*ノコギリ波の接続チェック
	btst.b	#b_pmod_syncok,p_pmod_flg(a5)
	beq	pm_chain
	move.w	p_pmod_wf2(a5),d0
	subq.w	#1,d0			*case:sq
	beq	@f
	subq.w	#1,d0			*case:tri
	beq	1f
	bra	go_connect_pm		*波形接続へ
@@:					*case:sq->sw
	move.l	p_pmod_pitch(a5),d0
	eor.l	d1,d0
	bmi	go_connect_pm		*波形接続へ
	bra	pm_chain
1:					*case:tr->sw
	move.l	p_pmod_step2(a5),d0
	eor.l	d1,d0
	bpl	go_connect_pm		*波形接続へ
	bra	pm_chain

smt_swp:				*ノコギリ波の接続
	move.w	p_pmod_wf(a5),d0
	bclr.b	#b_pmod_syncok,p_pmod_flg(a5)
	clr.l	p_pmod_pitch(a5)
	move.w	d2,p_pmod_spd(a5)
	move.w	d2,p_pmod_spd2(a5)
	cmpi.b	#2,p_pmod_chain(a5)
	beq	1f
	move.l	d1,p_pmod_step2(a5)
	sne	p_pmod_chain(a5)	*振幅0ならばp_pmod_chain=0
	cmp.w	p_pmod_wf2(a5),d0
	beq	@f
	cmpi.w	#2,p_pmod_wf2(a5)
	beq	@f			*三角波も同系とみなす
	move.w	d0,p_pmod_wf2(a5)
	rts
@@:					*同波形ならば0のダブリは余計
	move.w	d0,p_pmod_wf2(a5)
	bra	fmpmod1
1:
	move.w	d0,p_pmod_wf2(a5)
	move.l	d1,p_pmod_step2(a5)
	sne	p_pmod_chain(a5)	*振幅0ならばp_pmod_chain=0
	bra	fmpmod1

chk_smt_sqp:				*矩形波の接続チェック
	btst.b	#b_pmod_syncok,p_pmod_flg(a5)
	beq	pm_chain
	move.w	p_pmod_wf2(a5),d0
	subq.w	#1,d0			*case:sq
	beq	@f
	subq.w	#1,d0			*case:tri
	beq	1f
	bra	go_connect_pm		*三角波、矩形波以外ならば波形接続へ
@@:					*case:sq->sq
	move.l	p_pmod_pitch(a5),d0
	eor.l	d1,d0			*矩形波は±が交互にならなければ見送り
	bmi	go_connect_pm		*波形接続へ
	bra	pm_chain
1:					*case:tr->sq
	move.l	p_pmod_step2(a5),d0
	eor.l	d1,d0
	bpl	go_connect_pm		*波形接続へ
	bra	pm_chain
smt_sqp:				*矩形波の接続
	move.w	p_pmod_wf(a5),p_pmod_wf2(a5)
	bclr.b	#b_pmod_syncok,p_pmod_flg(a5)
	move.l	d1,p_pmod_pitch(a5)
	move.w	d2,p_pmod_spd(a5)
	move.w	d2,p_pmod_spd2(a5)
	cmpi.b	#2,p_pmod_chain(a5)
	beq	@f
	move.l	d1,p_pmod_step2(a5)
	sne	p_pmod_chain(a5)	*振幅0ならばp_pmod_chain=0
exit_pmod_ope:
	rts
@@:					*初回時のみ特別処理
	move.l	d1,p_pmod_step2(a5)
	sne	p_pmod_chain(a5)	*振幅0ならばp_pmod_chain=0
	bra	fmpmod1

chk_smt_trp:				*三角波の接続チェック
	btst.b	#b_pmod_syncok,p_pmod_flg(a5)
	beq	pm_chain
	move.w	p_pmod_wf2(a5),d0
	subq.w	#1,d0			*case:sq
	beq	1f
	subq.w	#1,d0			*case:tr
	beq	@f
	bra	go_connect_pm		*三角波、矩形波以外ならば波形接続へ
@@:					*case:tr->tr
	move.l	p_pmod_step2(a5),d0	*get 整数部分
	eor.l	d1,d0			*方向が逆だと見送る
	bpl	go_connect_pm		*波形接続へ
	bra	pm_chain
1:					*case:sq->tr
	move.l	p_pmod_pitch(a5),d0	*get 整数部分
	eor.l	d1,d0			*方向が逆だと見送る
	bmi	go_connect_pm		*波形接続へ
	bra	pm_chain

smt_trp:				*三角波の接続
	move.w	p_pmod_wf(a5),d0
	bclr.b	#b_pmod_syncok,p_pmod_flg(a5)
	clr.l	p_pmod_pitch(a5)
	move.w	d2,p_pmod_spd(a5)
	lsr.w	d2
	move.w	d2,p_pmod_spd2(a5)
	cmpi.b	#2,p_pmod_chain(a5)
	beq	1f
	move.l	d1,p_pmod_step2(a5)
	sne	p_pmod_chain(a5)	*振幅0ならばp_pmod_chain=0
	cmp.w	p_pmod_wf2(a5),d0
	beq	@f
	tst.w	p_pmod_wf2(a5)
	beq	@f			*ノコギリ波も同系とみなす
	move.w	d0,p_pmod_wf2(a5)
	rts
@@:					*同波形ならば0のダブリは余計
	move.w	d0,p_pmod_wf2(a5)
	bra	fmpmod1
1:					*初回は特別処理
	move.w	d0,p_pmod_wf2(a5)
	move.l	d1,p_pmod_step2(a5)
	sne	p_pmod_chain(a5)	*振幅0ならばp_pmod_chain=0
	bra	fmpmod1

chk_smt_swp2:				*ノコギリ波2の接続チェック
	btst.b	#b_pmod_syncok,p_pmod_flg(a5)
	beq	pm_chain
	move.w	p_pmod_wf2(a5),d0
	subq.w	#1,d0			*case:sq
	beq	@f
	subq.w	#1,d0			*case:tri
	beq	1f
	bra	go_connect_pm		*波形接続へ
@@:					*case:sq->sw2
	move.l	p_pmod_pitch(a5),d0
	eor.l	d1,d0
	bmi	go_connect_pm		*波形接続へ
	bra	pm_chain
1:					*case:tr->sw2
	move.l	p_pmod_step2(a5),d0
	eor.l	d1,d0
	bpl	go_connect_pm		*波形接続へ
	bra	pm_chain

smt_swp2:				*ノコギリ波2の接続
	move.w	p_pmod_wf(a5),d0
	bclr.b	#b_pmod_syncok,p_pmod_flg(a5)
	clr.l	p_pmod_pitch(a5)
	move.w	d2,p_pmod_spd(a5)
	move.w	d2,p_pmod_spd2(a5)
	cmpi.b	#2,p_pmod_chain(a5)
	beq	1f
	move.l	d1,p_pmod_step2(a5)
	sne	p_pmod_chain(a5)	*振幅0ならばp_pmod_chain=0
	cmp.w	p_pmod_wf2(a5),d0
	beq	@f
	cmpi.w	#2,p_pmod_wf2(a5)
	beq	@f			*三角波も同系とみなす
	move.w	d0,p_pmod_wf2(a5)
	rts
@@:					*同波形ならば0のダブリは余計
	move.w	d0,p_pmod_wf2(a5)
	bra	fmpmod1
1:
	move.w	d0,p_pmod_wf2(a5)
	move.l	d1,p_pmod_step2(a5)
	sne	p_pmod_chain(a5)	*振幅0ならばp_pmod_chain=0
	bra	fmpmod1

chk_smt_pm_ns:
	btst.b	#b_pmod_syncok,p_pmod_flg(a5)
	beq	pm_chain
	bra	go_connect_pm		*波形接続へ
smt_pm_ns:				*ノイズの場合は即接続
	move.w	p_pmod_wf(a5),p_pmod_wf2(a5)
	bclr.b	#b_pmod_syncok,p_pmod_flg(a5)
	move.w	d2,p_pmod_spd(a5)
	lsr.w	d2
	move.w	d2,p_pmod_spd2(a5)
	move.l	d1,p_pmod_step2(a5)
	sne	p_pmod_chain(a5)	*振幅0ならばp_pmod_chain=0
	bsr	get_rand
	swap	d1
	muls.w	d1,d0
	swap	d0			*(1/65536)*2
	add.w	d0,d0			*→/32768
	move.w	d0,p_pmod_pitch(a5)
	rts

chk_smt_pm_us:
	btst.b	#b_pmod_syncok,p_pmod_flg(a5)
	beq	pm_chain
	bra	go_connect_pm		*波形接続へ
smt_pm_us:				*波形メモリの場合は即接続
	move.w	p_pmod_wf(a5),p_pmod_wf2(a5)
	bset.b	#b_pmod_syncok,p_pmod_flg(a5)
	clr.b	p_altp_flg(a5)		*反復モードスイッチオフ
	move.w	d2,p_pmod_spd(a5)
	lsr.w	d2
	move.w	d2,p_pmod_spd2(a5)
	move.l	d1,p_pmod_step2(a5)
	sne	p_pmod_chain(a5)	*振幅0ならばp_pmod_chain=0
	move.l	p_wvpm_start(a5),p_wvpm_point(a5)
	move.l	p_wvpm_lptm(a5),p_wvpm_lptm2(a5)
	bra	fmpmod1

pm_chain:				*今回は接続不能,次回へ期待
	move.b	#1,p_pmod_chain(a5)
fmpmod1:
*-------実際のモジュレーション処理-------
	move.w	p_pmod_wf2(a5),d1	*波形タイプチェック
	bmi	pmod_wvmm
	add.w	d1,d1
	move.w	fmp1(pc,d1.w),d1
	jmp	fmp1(pc,d1.w)
fmp1:	dc.w	pmod_noko-fmp1
	dc.w	pmod_kukei-fmp1
	dc.w	pmod_sankaku-fmp1
	dc.w	pmod_noko2-fmp1
	dc.w	pmod_noise-fmp1
pmod_wvmm:				*波形メモリ
	* d6 d7 a4 破壊禁止
	move.b	p_altp_flg(a5),d0
	bmi	alternative_ope
	move.l	p_wvpm_point(a5),a1
	move.w	(a1)+,d1
	ext.l	d1
pmod_wvmm_patch:			*コンパチモードではパッチ(bra store_pmod_wvmm)
	move.w	p_pmod_step2(a5),d2
	muls.w	d2,d1			*step2が振幅に相当
	asr.l	#8,d1			*/256
store_pmod_wvmm:
	reduce_range_l	d1,-32768,32767
	move.w	d1,p_pmod_pitch(a5)
	subq.w	#1,p_pmod_spd2(a5)
	bne	exit_pmus
	move.w	p_pmod_spd(a5),d1
	lsr.w	#1,d1			*d1=d1/2
	move.w	d1,p_pmod_spd2(a5)	*init speed work
	bsr	pmod_wvdpn_ope
	tst.b	d0
	bne	@f			*case:+1
	cmp.l	p_wvpm_lped(a5),a1
	bne	svwvpm
	tst.b	p_wvpm_lpmd(a5)		*-1 one shot,0 repeat,+1 alternative
	bmi	oneshot_pm
	beq	repeat_pm
alternative_pm:
	st.b	p_altp_flg(a5)
oneshot_pm:
	subq.w	#2,a1
svwvpm:
	move.l	a1,p_wvpm_point(a5)
	rts
@@:					*終了フェーズ
	cmp.l	p_wvpm_end(a5),a1
	beq	oneshot_pm		*もう終わりだ
	move.l	a1,p_wvpm_point(a5)
exit_pmus:
	rts
repeat_pm:				*先頭からのくり返しケース
	tst.l	p_wvpm_lptm2(a5)
	beq	@f
	subq.l	#1,p_wvpm_lptm2(a5)
	bne	@f
	move.b	#1,p_altp_flg(a5)
@@:
	move.l	p_wvpm_lpst(a5),p_wvpm_point(a5)
	rts
alternative_ope:
	move.l	p_wvpm_point(a5),a1
	move.w	-(a1),d1
	move.w	p_pmod_step2(a5),d2
	muls.w	d2,d1
	asr.l	#8,d1			*/256
	move.w	d1,p_pmod_pitch(a5)
	subq.w	#1,p_pmod_spd2(a5)
	bne	exit_pmus
	move.w	p_pmod_spd(a5),d1
	lsr.w	#1,d1			*d1=d1/2
	move.w	d1,p_pmod_spd2(a5)	*init speed work
	bsr	pmod_wvdpn_ope
	cmp.l	p_wvpm_lpst(a5),a1
	bne	svwvpm
	move.l	p_wvpm_lptm2(a5),d0
	beq	@f
	subq.l	#1,p_wvpm_lptm2(a5)
	bne	@f
	moveq.l	#1,d0
@@:
	move.b	d0,p_altp_flg(a5)	*d0=0ならば順方向再開,d0=1ならば最終フェーズへ
	addq.w	#2,a1
	bra	svwvpm

pmod_wvdpn_ope:				*PMOD振幅増減モード処理
	* - d0
	addq.w	#1,p_pmod_rndcnt(a5)
	move.w	p_pmod_rndcnt(a5),d1
	cmp.w	p_pmod_dpnspd(a5),d1	*指定周期になったか
	bne	exit_pmdpn
	clr.w	p_pmod_rndcnt(a5)
	move.w	p_pmod_dpnrpt(a5),d1	*無限ループ
	beq	@f
	cmp.w	p_pmod_dpntime(a5),d1
	beq	exit_pmdpn
	addq.w	#1,p_pmod_dpntime(a5)
@@:
	move.w	p_pmod_dpndpt(a5),d1
	ext.l	d1
	ext.l	d2
	bpl	pmwvdptpls
	sub.l	d1,d2			*振幅増減処理
	bmi	stnewpmstp2
	tst.l	d1
	bmi	@f
	move.l	#8000,d2
	bra	stnewpmstp2
pmwvdptpls:
	add.l	d1,d2			*振幅増減処理
	bpl	stnewpmstp2
	tst.l	d1
	bmi	@f
	move.l	#$7fff,d2
	bra	stnewpmstp2
@@:					*振幅0へ
	moveq.l	#0,d2
stnewpmstp2:
	move.w	d2,p_pmod_step2(a5)
exit_pmdpn:
	rts

pmod_noko:				*鋸歯波
	subq.w	#1,p_pmod_spd2(a5)
	beq	2f
	move.l	p_pmod_pitch(a5),d2
	bmi	@f
	add.l	p_pmod_step2(a5),d2
	bpl	1f
	tst.b	p_pmod_step2(a5)
	bmi	1f
	move.l	#$7fff_ffff,d2
	bra	1f
@@:
	add.l	p_pmod_step2(a5),d2
	bmi	1f
	tst.b	p_pmod_step2(a5)
	bpl	1f
	move.l	#$8000_0000,d2
1:
	move.l	d2,p_pmod_pitch(a5)
	bra	exit_pmnk
2:
	move.l	p_pmod_pitch(a5),d2
	neg.l	d2
	move.w	p_pmod_spd(a5),d1
	addq.w	#1,p_pmod_rndcnt(a5)
	move.w	p_pmod_rndcnt(a5),d0
	cmp.w	p_pmod_dpnspd(a5),d0	*指定周期になったか
	bne	normal_pmnk
	clr.w	p_pmod_rndcnt(a5)
	move.w	p_pmod_dpnrpt(a5),d0	*無限ループ
	beq	@f
	cmp.w	p_pmod_dpntime(a5),d0
	beq	normal_pmnk
	addq.w	#1,p_pmod_dpntime(a5)
@@:
	move.w	p_pmod_dpndpt(a5),d0
	swap	d2
	bpl	pmnk_pls
	sub.w	d0,d2
	bmi	@f
	tst.w	d0
	bmi	pmnk_zero
	move.w	#$8000,d2
@@:
	ext.l	d2
	move.l	d2,d0
	swap	d0
	move.l	d0,p_pmod_pitch(a5)
	neg.l	d2
	divu	d1,d2		*d2=range/L d2.w=step counter
	move.w	d2,d0
	clr.w	d2
	divu	d1,d2		*d2=d2/L
	swap	d0
	move.w	d2,d0
	move.l	d0,p_pmod_step2(a5)
	add.w	d1,d1
	subq.w	#1,d1			*96/09/10
	move.w	d1,p_pmod_spd2(a5)
	bra	exit_pmnk
pmnk_pls:
	add.w	d0,d2			*振幅増減処理
	bpl	@f
	tst.w	d0
	bmi	pmnk_zero
	move.w	#$7fff,d2
@@:
	ext.l	d2
	move.l	d2,d0
	swap	d0
	move.l	d0,p_pmod_pitch(a5)
	divu	d1,d2		*d2=range/L d2.w=step counter
	move.w	d2,d0
	clr.w	d2
	divu	d1,d2		*d2=d2/L
	swap	d0
	move.w	d2,d0
	addq.l	#1,d0
	neg.l	d0
	move.l	d0,p_pmod_step2(a5)
	add.w	d1,d1
	subq.w	#1,d1			*96/09/10
	move.w	d1,p_pmod_spd2(a5)
	bra	exit_pmnk
pmnk_zero:				*振幅減少でゼロになった場合
	moveq.l	#0,d2
	move.l	d2,p_pmod_step2(a5)
normal_pmnk:
	move.l	d2,p_pmod_pitch(a5)
	add.w	d1,d1
	subq.w	#1,d1			*96/09/10
	move.w	d1,p_pmod_spd2(a5)
exit_pmnk:
	tst.l	p_pmod_pitch(a5)
	bne	@f
	bset.b	#b_pmod_syncok,p_pmod_flg(a5)
	rts
@@:
	bclr.b	#b_pmod_syncok,p_pmod_flg(a5)
	rts

pmod_kukei:				*矩形波
	subq.w	#1,p_pmod_spd2(a5)
	beq	1f
	cmpi.w	#1,p_pmod_spd2(a5)
	bne	@f
	bset.b	#b_pmod_syncok,p_pmod_flg(a5)
	rts
@@:
	bclr.b	#b_pmod_syncok,p_pmod_flg(a5)
	rts
1:
	bclr.b	#b_pmod_syncok,p_pmod_flg(a5)
	move.w	p_pmod_spd(a5),p_pmod_spd2(a5)
	move.w	p_pmod_step2(a5),d2
	ext.l	d2
	bsr	pmod_wvdpn_ope		*振幅増減処理へ
	neg.l	d2
	cmpi.l	#-32768,d2
	bge	@f
	move.w	#-32768,d2
	bra	1f
@@:
	cmpi.l	#32767,d2
	ble	1f
	move.w	#32767,d2
1:
	move.w	d2,p_pmod_step2(a5)
	move.w	d2,p_pmod_pitch(a5)
	rts

pmod_sankaku:				*三角波
	move.w	p_pmod_spd(a5),d1
	move.l	p_pmod_pitch(a5),d2
	bmi	@f
	add.l	p_pmod_step2(a5),d2
	bpl	1f
	tst.b	p_pmod_step2(a5)
	bmi	1f
	move.l	#$7fff_ffff,d2
	bra	1f
@@:
	add.l	p_pmod_step2(a5),d2
	bmi	1f
	tst.b	p_pmod_step2(a5)
	bpl	1f
	move.l	#$8000_0000,d2
1:
	move.l	d2,p_pmod_pitch(a5)
	subq.w	#1,p_pmod_spd2(a5)
	bne	@f
	move.w	d1,p_pmod_spd2(a5)
	neg.l	p_pmod_step2(a5)
	bra	exit_pmtr
@@:					*中点のときが幅更新
	lsr.w	#1,d1
	cmp.w	p_pmod_spd2(a5),d1
	bne	exit_pmtr
	addq.w	#1,p_pmod_rndcnt(a5)
	move.w	p_pmod_rndcnt(a5),d0
	cmp.w	p_pmod_dpnspd(a5),d0	*指定周期になったか
	bne	exit_pmtr
	clr.w	p_pmod_rndcnt(a5)
	move.w	p_pmod_dpnrpt(a5),d0
	beq	@f			*無限ループ
	cmp.w	p_pmod_dpntime(a5),d0
	beq	exit_pmtr
	addq.w	#1,p_pmod_dpntime(a5)
@@:
	move.w	p_pmod_dpndpt(a5),d2
*	lsr.w	#1,d1			*上でやっているからREM
	ext.l	d2
	bpl	pmtr_pls
	neg.l	d2
	divu	d1,d2			*d2=range/L d2.w=step counter
	move.w	d2,d0
	clr.w	d2
	divu	d1,d2		*d2=d2/L
	swap	d0
	move.w	d2,d0
	neg.l	d0		*振幅減衰ケース
	bra	set_pmtr
pmtr_pls:
	divu	d1,d2		*d2=range/L d2.w=step counter
	move.w	d2,d0
	clr.w	d2
	divu	d1,d2		*d2=d2/L
	swap	d0
	move.w	d2,d0
	addq.l	#1,d0
set_pmtr:
	move.l	p_pmod_step2(a5),d2
	bmi	set_pmtr_sub
	add.l	d0,d2
	bpl	@f
	tst.l	d0
	bmi	pmtr_zero
	move.l	#$7fff_ffff,d2
@@:
	move.l	d2,p_pmod_step2(a5)
	bra	exit_pmtr
set_pmtr_sub:
	sub.l	d0,d2
	bmi	@f
	tst.l	d0
	bmi	pmtr_zero
	move.l	#$8000_0000,d2
@@:
	move.l	d2,p_pmod_step2(a5)
	bra	exit_pmtr
pmtr_zero:				*振幅減少でゼロになった場合
	moveq.l	#0,d2
	move.l	d2,p_pmod_step2(a5)
exit_pmtr:
	tst.l	p_pmod_pitch(a5)
	bne	@f
	bset.b	#b_pmod_syncok,p_pmod_flg(a5)
	rts
@@:
	bclr.b	#b_pmod_syncok,p_pmod_flg(a5)
	rts

pmod_noko2:				*鋸歯波2
	tst.w	p_pmod_spd2(a5)		*一度０になったらそれまで
	beq	@f
	subq.w	#1,p_pmod_spd2(a5)
	beq	@f
	move.l	p_pmod_step2(a5),d1
	add.l	d1,p_pmod_pitch(a5)
	bclr.b	#b_pmod_syncok,p_pmod_flg(a5)
	rts
@@:
	bset.b	#b_pmod_syncok,p_pmod_flg(a5)
	rts

pmod_noise:				*ノイズ
	subq.w	#1,p_pmod_spd2(a5)
	bne	@f
	bsr	get_rand
	move.w	p_pmod_step2(a5),d2
	bsr	pmod_wvdpn_ope		*振幅増減処理へ
	muls.w	d2,d0			*noise(-.5～+.5)*depth*2を求める
	swap	d0
	add.w	d0,d0
	move.w	d0,p_pmod_pitch(a5)
	move.w	p_pmod_spd(a5),d0
	lsr.w	d0
	move.w	d0,p_pmod_spd2(a5)
@@:
	cmpi.w	#1,p_pmod_spd2(a5)
	bne	@f
	bset.b	#b_pmod_syncok,p_pmod_flg(a5)
	rts
@@:
	bclr.b	#b_pmod_syncok,p_pmod_flg(a5)
	rts

arcc_ope:				*AMOD/ARCC処理
	* X d0-d3,a1
	* - a3,a4,d5
	btst.b	#b_arcc_wvsq,p_arcc_flg(a4)	*波形進行音符毎モードか
	beq	@f
	cmpi.w	#1,(a5)
	bne	exit_arcc_ope
	btst.b	#b_arcc_wvsqrst,p_arcc_flg(a4)
	bne	@f
	movea.l	p_data_pointer(a5),a1	*compiled data address
	cmpi.b	#rest_zmd,(a1)
	beq	exit_arcc_ope		*休符では更新せず
	subq.w	#1,p_arcc_syncnt2(a4)
	bne	exit_arcc_ope
	move.w	p_arcc_syncnt(a4),p_arcc_syncnt2(a4)
@@:
vseq_entry:
	subq.w	#1,p_arcc_dly2(a4)
	bne	am_chain?
	moveq.l	#0,d0
	move.b	p_arcc_n(a4),d0
	addq.b	#1,d0			*-1.bでエントリのケースもあり(だから.b)
	cmpi.b	#7,d0
	bhi	am_chain?		*最後のを継続して使用
	move.b	d0,p_arcc_n(a4)
	btst.b	d0,p_arcc_omt(a4)	*省略の場合は前回のものを継続
	beq	ao0
	move.b	p_arcc_dpt_tbl(a4,d0.w),d3	*次の波形生成パラメータ
	move.b	d3,p_arcc_dpt_now(a4)
	bmi	@f
	moveq.l	#0,d3
@@:
	lsl.w	#8,d3				*256倍する
	add.w	d0,d0
	move.w	p_arcc_8st_tbl(a4,d0.w),p_arcc_dly2(a4)
	move.w	p_arcc_stp_tbl(a4,d0.w),d1	*次の波形生成パラメータ
	move.w	p_arcc_spd_tbl(a4,d0.w),d2	*次の波形生成パラメータ
	bne	@f
	move.w	p_arcc_spd(a4),d2
@@:
	tst.b	p_arcc_chain(a4)
	bne	check_cnct_am
go_connect_am:					*波形接続へ
	move.w	p_arcc_wf(a4),d0		*波形タイプ検査
	bmi	smt_am_us
	add.w	d0,d0
	move.w	smta(pc,d0.w),d0
	jmp	smta(pc,d0.w)
smta:	dc.w	smt_swa-smta		*case0:saw
	dc.w	smt_sqa-smta		*case1:squ
	dc.w	smt_tra-smta		*case2:tri
	dc.w	smt_swa2-smta		*case3:sp_saw
	dc.w	smt_am_ns-smta		*case4:noise
ao0:
	add.w	d0,d0
	move.w	p_arcc_8st_tbl(a4,d0.w),p_arcc_dly2(a4)
	bra	fmarcc1
am_chain?:
	move.b	p_arcc_chain(a4),d0
	beq	exit_arcc_ope		*「0:即接続」ならばディレイ処理
	bmi	fmarcc1			*「-1:波形接続処理ずみ」ならば継続
	move.w	p_arcc_step_next(a4),d1	*次の波形生成パラメータ
	move.w	p_arcc_spd_next(a4),d2
	move.w	p_arcc_o_next(a4),d3
	subq.b	#1,d0			*1 or 2?
	beq	@f			*case:1
	tst.b	p_arcc_n(a4)		*case:2(=初回)
	bmi	exit_arcc_ope		*delay:ケース
	bra	go_connect_am

check_cnct_am:				*波形接続チェック
	move.w	d1,p_arcc_step_next(a4)	*次の波形生成パラメータを
	move.w	d2,p_arcc_spd_next(a4)	*セットする。
	move.w	d3,p_arcc_o_next(a4)
	cmpi.b	#2,p_arcc_chain(a4)	*初回ケース
	beq	go_connect_am
@@:
	move.w	p_arcc_wf(a4),d0
	bmi	chk_smt_am_us		*波形タイプ検査
	add.w	d0,d0
	move.w	smta2(pc,d0.w),d0
	jmp	smta2(pc,d0.w)
smta2:	dc.w	chk_smt_swa-smta2	*case0:saw
	dc.w	chk_smt_sqa-smta2	*case1:squ
	dc.w	chk_smt_tra-smta2	*case2:tri
	dc.w	chk_smt_swa2-smta2	*case3:sp_saw
	dc.w	chk_smt_am_ns-smta2	*case4:noise

chk_smt_swa:				*ノコギリ波の接続チェック
	tst.b	p_arcc_flg2(a4)		*btst.b	#b_arcc_syncok,p_arcc_flg2(a4)
	bpl	am_chain
	move.w	p_arcc_wf2(a4),d0
	subq.w	#1,d0			*case:sq
	beq	@f
	subq.w	#1,d0			*case:tr
	beq	1f
	bra	go_connect_am		*波形接続へ
@@:					*sq->sw
	move.w	p_arcc_level(a4),d0
	eor.w	d1,d0
	bpl	go_connect_am		*波形接続へ
	bra	am_chain
1:					*tr->sw
	move.w	p_arcc_step2(a4),d0
	eor.w	d1,d0
	bmi	go_connect_am		*波形接続へ
	bra	am_chain

smt_swa:				*ノコギリ波の接続
	move.w	p_arcc_wf(a4),p_arcc_wf2(a4)
	bclr.b	#b_arcc_syncok,p_arcc_flg2(a4)
	move.w	d3,p_arcc_o(a4)
	move.w	d3,p_arcc_level(a4)
	move.w	d2,p_arcc_spd(a4)
	add.w	d2,d2
	move.w	d2,p_arcc_spd2(a4)
	cmpi.b	#2,p_arcc_chain(a4)
	beq	@f
	move.w	d1,p_arcc_step2(a4)
	sne	p_arcc_chain(a4)
	rts
@@:					*初回時のみ特別処理
	move.w	d1,p_arcc_step2(a4)
	sne	p_arcc_chain(a4)
	bra	fmarcc1

chk_smt_sqa:				*矩形波の接続チェック
	tst.b	p_arcc_flg2(a4)		*btst.b	#b_arcc_syncok,p_arcc_flg2(a4)
	bpl	am_chain
	move.w	p_arcc_wf2(a4),d0
	subq.w	#1,d0			*case:sq
	beq	@f
	subq.w	#1,d0			*case:tr
	beq	1f
	bra	go_connect_am		*波形接続へ
@@:					*sq->sq
	move.w	p_arcc_level(a4),d0
	eor.w	d1,d0
	bmi	go_connect_am		*波形接続へ
	bra	am_chain
1:					*tr->sq
	move.w	p_arcc_step2(a4),d0
	eor.w	d1,d0
	bmi	go_connect_am		*波形接続へ
	bra	am_chain

smt_sqa:				*矩形波の接続
	move.w	p_arcc_wf(a4),p_arcc_wf2(a4)
	bclr.b	#b_arcc_syncok,p_arcc_flg2(a4)
	move.w	d3,p_arcc_level(a4)
	move.w	d2,p_arcc_spd(a4)
	move.w	d2,p_arcc_spd2(a4)
	cmpi.b	#2,p_arcc_chain(a4)
	beq	@f
	move.w	d1,p_arcc_step2(a4)
	sne	p_arcc_chain(a4)
	rts
@@:					*初回時のみ特別処理
	move.w	d1,p_arcc_step2(a4)
	sne	p_arcc_chain(a4)
	bra	fmarcc1

chk_smt_tra:				*三角波の接続チェック
	tst.b	p_arcc_flg2(a4)		*btst.b	#b_arcc_syncok,p_arcc_flg2(a4)
	bpl	am_chain
	move.w	p_arcc_wf2(a4),d0
	subq.w	#1,d0			*case:sq
	beq	1f
	subq.w	#1,d0			*case:sq
	beq	@f
	bra	go_connect_am
@@:					*case:tr->tr
	move.w	p_arcc_step2(a4),d0
	eor.w	d1,d0
	bmi	go_connect_am		*波形接続へ
	bra	am_chain
1:					*case:sq->tr
	move.w	p_arcc_level(a4),d0
	eor.w	d1,d0
	bpl	go_connect_am		*波形接続へ
	bra	am_chain

smt_tra:				*三角波の接続
	move.w	p_arcc_wf(a4),p_arcc_wf2(a4)
	bclr.b	#b_arcc_syncok,p_arcc_flg2(a4)
	move.w	d3,p_arcc_o(a4)
	move.w	d3,p_arcc_level(a4)
	move.w	d2,p_arcc_spd(a4)
	move.w	d2,p_arcc_spd2(a4)
	cmpi.b	#2,p_arcc_chain(a4)
	beq	@f
	move.w	d1,p_arcc_step2(a4)
	sne	p_arcc_chain(a4)
	rts
@@:					*初回時のみ特別処理
	move.w	d1,p_arcc_step2(a4)
	sne	p_arcc_chain(a4)
	bra	fmarcc1

chk_smt_swa2:				*ノコギリ波2の接続チェック
	tst.b	p_arcc_flg2(a4)		*btst.b	#b_arcc_syncok,p_arcc_flg2(a4)
	bpl	am_chain
	move.w	p_arcc_wf2(a4),d0
	subq.w	#1,d0			*case:sq
	beq	@f
	subq.w	#1,d0			*case:tr
	beq	1f
	bra	go_connect_am		*波形接続へ
@@:					*sq->sw
	move.w	p_arcc_level(a4),d0
	eor.w	d1,d0
	bpl	go_connect_am		*波形接続へ
	bra	am_chain
1:					*tr->sw
	move.w	p_arcc_step2(a4),d0
	eor.w	d1,d0
	bmi	go_connect_am		*波形接続へ
	bra	am_chain

smt_swa2:				*ノコギリ波2の接続チェック
	move.w	p_arcc_wf(a4),p_arcc_wf2(a4)
	bclr.b	#b_arcc_syncok,p_arcc_flg2(a4)
	move.w	d3,p_arcc_level(a4)
	move.w	d2,p_arcc_spd(a4)
	add.w	d2,d2
	move.w	d2,p_arcc_spd2(a4)
	cmpi.b	#2,p_arcc_chain(a4)
	beq	@f
	move.w	d1,p_arcc_step2(a4)
	sne	p_arcc_chain(a4)
	rts
@@:					*初回時のみ特別処理
	move.w	d1,p_arcc_step2(a4)
	sne	p_arcc_chain(a4)
	bra	fmarcc1

chk_smt_am_ns:
	tst.b	p_arcc_flg2(a4)		*btst.b	#b_arcc_syncok(a4),p_arcc_flg2(a4)
	bpl	am_chain
	bra	go_connect_am		*波形接続へ
smt_am_ns:
	move.w	p_arcc_wf(a4),p_arcc_wf2(a4)
	bclr.b	#b_arcc_syncok,p_arcc_flg2(a4)
	move.w	d2,p_arcc_spd(a4)
	lsr.w	d2
	move.w	d2,p_arcc_spd2(a4)
	move.w	d1,p_arcc_step2(a4)		*ノイズの場合はstep2=振幅
	sne	p_arcc_chain(a4)
	bsr	get_rand
	move.b	p_arcc_step2(a4),d1
	ext.w	d1
	bpl	@f
	neg.w	d1
@@:
	mulu	d1,d0
	swap	d0
	neg.b	d0
	move.b	d0,p_arcc_level(a4)
	rts

chk_smt_am_us:
	tst.b	p_arcc_flg2(a4)		*btst.b	#b_arcc_syncok,p_arcc_flg2(a4)
	bpl	am_chain
	bra	go_connect_am		*波形接続へ
smt_am_us:
	move.w	p_arcc_wf(a4),p_arcc_wf2(a4)
	tas.b	p_arcc_flg2(a4)		*bset.b	#b_arcc_syncok,p_arcc_flg2(a4)
	clr.b	p_alta_flg(a4)		*反復モードスイッチオフ
	move.w	d2,p_arcc_spd(a4)
	lsr.w	d2
	move.w	d2,p_arcc_spd2(a4)
	move.w	d1,p_arcc_step2(a4)
	sne	p_arcc_chain(a4)
	move.l	p_wvam_start(a4),p_wvam_point(a4)
	move.l	p_wvam_lptm(a4),p_wvam_lptm2(a4)
	bra	fmarcc1

am_chain:					*今回は接続不能,次回に期待。
	move.b	#1,p_arcc_chain(a4)
fmarcc1:
*-------実際のモジュレーション処理-------
	move.w	p_arcc_wf2(a4),d1
	bmi	arcc_wvmm
	add.w	d1,d1
	move.w	fma1(pc,d1.w),d1
	jmp	fma1(pc,d1.w)
fma1:	dc.w	arcc_noko-fma1
	dc.w	arcc_kukei-fma1
	dc.w	arcc_sankaku-fma1
	dc.w	arcc_noko2-fma1
	dc.w	arcc_noise-fma1
arcc_wvmm:				*波形メモリ
	* d6 d7 a4 破壊禁止
	move.b	p_alta_flg(a4),d0
	bmi	alternative_ope_a
	move.l	p_wvam_point(a4),a1
	move.w	(a1)+,d1
	ext.l	d1
arcc_wvmm_patch:			*コンパチモードではパッチ(bra store_arcc_wvmm)
	move.b	p_arcc_step2(a4),d2
	ext.w	d2
	muls.w	d2,d1
	asr.l	#5,d1			*/32
store_arcc_wvmm:
	reduce_range_l	d1,-128,127
	move.b	d1,p_arcc_level(a4)
	subq.w	#1,p_arcc_spd2(a4)
	bne	exit_arus
	move.w	p_arcc_spd(a4),d1
	lsr.w	#1,d1			*d1=d1/2
	move.w	d1,p_arcc_spd2(a4)	*init speed work
	bsr	arcc_wvdpn_ope
	tst.b	d0
	bne	@f			*case:+1
	cmp.l	p_wvam_lped(a4),a1
	bne	svwvam
	tst.b	p_wvam_lpmd(a4)		*-1 one shot,0 repeat,+1 alternative
	bmi	oneshot_am
	beq	repeat_am
alternative_am:
	st.b	p_alta_flg(a4)
oneshot_am:
	subq.w	#2,a1
svwvam:
	move.l	a1,p_wvam_point(a4)
	rts
@@:					*終了フェーズ
	cmp.l	p_wvam_end(a4),a1
	beq	oneshot_am		*もう終わりだ
	move.l	a1,p_wvam_point(a4)
exit_arus:
	rts
repeat_am:
	tst.l	p_wvam_lptm2(a4)
	beq	@f
	subq.l	#1,p_wvam_lptm2(a4)
	bne	@f
	move.b	#1,p_altp_flg(a4)
@@:
	move.l	p_wvam_lpst(a4),p_wvam_point(a4)
	rts
alternative_ope_a:
	move.l	p_wvam_point(a4),a1
	move.w	-(a1),d1
	move.b	p_arcc_step2(a4),d2
	ext.w	d2
	muls.w	d2,d1
	asr.l	#5,d1
	move.b	d1,p_arcc_level(a4)
	subq.w	#1,p_arcc_spd2(a4)
	bne	exit_arus
	move.w	p_arcc_spd(a4),d1
	lsr.w	#1,d1			*d1=d1/2
	move.w	d1,p_arcc_spd2(a4)	*init speed work
	bsr	arcc_wvdpn_ope
	cmp.l	p_wvam_lpst(a4),a1
	bne	svwvam
	move.l	p_wvam_lptm2(a4),d0
	beq	@f
	subq.l	#1,p_wvam_lptm2(a4)
	bne	@f
	moveq.l	#1,d0
@@:
	move.b	d0,p_alta_flg(a4)	*d0=0ならば順方向再開,d0=1ならば最終フェーズへ
	addq.w	#2,a1
	bra	svwvam

arcc_wvdpn_ope:				*ARCC振幅増減モード処理
	addq.w	#1,p_arcc_rndcnt(a4)
	move.w	p_arcc_rndcnt(a4),d1
	cmp.w	p_arcc_dpnspd(a4),d1	*指定周期になったか
	bne	exit_ardpn
	clr.w	p_arcc_rndcnt(a4)
	move.w	p_arcc_dpnrpt(a4),d0	*無限ループ
	beq	@f
	cmp.w	p_arcc_dpntime(a4),d0
	beq	exit_ardpn
	addq.w	#1,p_arcc_dpntime(a4)
@@:
	move.b	p_arcc_dpndpt(a4),d1
	ext.w	d1
	tst.w	d2
	bpl	arwvdptpls
	sub.w	d1,d2			*振幅増減処理
	bmi	stnewarstp2
	tst.w	d1
	bmi	@f
	moveq	#-128,d2
	bra	stnewarstp2
arwvdptpls:
	add.w	d1,d2			*振幅増減処理
	bpl	stnewarstp2
	tst.w	d1
	bmi	@f
	moveq.l	#127,d2
	bra	stnewarstp2
@@:					*振幅0へ
	moveq.l	#0,d2
stnewarstp2:
	move.b	d2,p_arcc_step2(a4)
exit_ardpn:
	rts

arcc_noko:				*ノコギリ波
	subq.w	#1,p_arcc_spd2(a4)
	beq	2f
	move.w	p_arcc_step2(a4),d2
	bpl	1f
	sub.w	d2,p_arcc_level(a4)
	ble	@f
	clr.w	p_arcc_level(a4)
	bra	@f
1:
	sub.w	d2,p_arcc_level(a4)
	ble	@f
	move.w	#$8000,p_arcc_level(a4)
@@:
	cmpi.w	#1,p_arcc_spd2(a4)
	bne	@f
	tas.b	p_arcc_flg2(a4)		*bset.b	#b_arcc_syncok,p_arcc_flg2(a4)
	rts
@@:
	bclr.b	#b_arcc_syncok,p_arcc_flg2(a4)
	rts
2:
	bclr.b	#b_arcc_syncok,p_arcc_flg2(a4)
	move.w	p_arcc_spd(a4),d1
	add.w	d1,d1
	move.w	d1,p_arcc_spd2(a4)
	addq.w	#1,p_arcc_rndcnt(a4)
	move.w	p_arcc_rndcnt(a4),d0
	cmp.w	p_arcc_dpnspd(a4),d0	*指定周期になったか
	bne	normal_arnk
	clr.w	p_arcc_rndcnt(a4)
	move.w	p_arcc_dpnrpt(a4),d0	*無限ループ
	beq	@f
	cmp.w	p_arcc_dpntime(a4),d0
	beq	normal_arnk
	addq.w	#1,p_arcc_dpntime(a4)
@@:
	move.b	p_arcc_dpndpt(a4),d0
	ext.w	d0
	moveq.l	#0,d2
	move.b	p_arcc_o(a4),d2
	beq	arnk_pls
	ext.w	d2
	sub.w	d0,d2
	bmi	@f
	tst.w	d0
	bmi	arnk_zero
	move.w	#-128,d2	*わざと.w
@@:
	move.w	d2,d0
	lsl.w	#8,d0
	move.w	d0,p_arcc_level(a4)
	move.w	d0,p_arcc_o(a4)
	neg.w	d2
	subq.w	#1,d1		*!
	divu	d1,d2		*d2=range/L d2.w=step counter
	move.w	d2,d0
	clr.w	d2
	divu	d1,d2		*d2=d2/L
	swap	d0
	move.w	d2,d0
	asr.l	#8,d0
	neg.w	d0
	move.w	d0,p_arcc_step2(a4)
	rts
arnk_pls:
	sub.b	p_arcc_level(a4),d2
	add.w	d0,d2			*振幅増減処理
	bpl	@f
	tst.w	d0
	bmi	arnk_zero
	moveq.l	#127,d2
@@:
	clr.w	p_arcc_level(a4)
	clr.w	p_arcc_o(a4)
	subq.w	#1,d1			*!
	divu	d1,d2		*d2=range/L d2.w=step counter
	move.w	d2,d0
	clr.w	d2
	divu	d1,d2		*d2=d2/L
	swap	d0
	move.w	d2,d0
	addq.l	#1,d0
	asr.l	#8,d0
	move.w	d0,p_arcc_step2(a4)
	rts
normal_arnk:
	move.w	p_arcc_o(a4),p_arcc_level(a4)
	rts
arnk_zero:				*振幅減少でゼロになった場合
	moveq.l	#0,d2
	move.l	d2,p_arcc_step2(a4)
	rts

arcc_kukei:				*矩形波
	subq.w	#1,p_arcc_spd2(a4)
	beq	1f
	cmpi.w	#1,p_arcc_spd2(a4)
	bne	@f
	tas.b	p_arcc_flg2(a4)		*bset.b	#b_arcc_syncok,p_arcc_flg2(a4)
	rts
@@:
	bclr.b	#b_arcc_syncok,p_arcc_flg2(a4)
	rts
1:
	bclr.b	#b_arcc_syncok,p_arcc_flg2(a4)
	move.w	p_arcc_spd(a4),p_arcc_spd2(a4)
	move.b	p_arcc_step2(a4),d2
	ext.w	d2
	neg.w	d2
	move.b	d2,p_arcc_step2(a4)
	bsr	arcc_wvdpn_ope
	tst.b	p_arcc_level(a4)
	beq	@f
	clr.w	p_arcc_level(a4)
	rts
@@:
	tst.b	d2
	bpl	1f
	add.b	d2,p_arcc_level(a4)
	ble	@f
	move.w	#$8000,p_arcc_level(a4)
@@:
	rts
1:
	add.b	d2,p_arcc_level(a4)
	ble	@f
	clr.w	p_arcc_level(a4)
@@:
	rts

arcc_sankaku:				*三角波
	move.w	p_arcc_step2(a4),d1
	bpl	@f
	sub.w	d1,p_arcc_level(a4)
	ble	1f
	clr.w	p_arcc_level(a4)
	bra	1f
@@:
	sub.w	d1,p_arcc_level(a4)
	ble	1f
	move.w	#$8000,p_arcc_level(a4)
1:
	subq.w	#1,p_arcc_spd2(a4)
	beq	1f
	cmpi.w	#1,p_arcc_spd2(a4)
	bne	@f
	tas.b	p_arcc_flg2(a4)		*bset.b	#b_arcc_syncok,p_arcc_flg2(a4)
	rts
@@:
	bclr.b	#b_arcc_syncok,p_arcc_flg2(a4)
	rts
1:
	bclr.b	#b_arcc_syncok,p_arcc_flg2(a4)
	neg.w	p_arcc_step2(a4)
	move.w	p_arcc_spd(a4),d1
	move.w	d1,p_arcc_spd2(a4)
	tst.w	p_arcc_level(a4)	*基準点の時のみ振幅更新
	bne	exit_artr2
	addq.w	#1,p_arcc_rndcnt(a4)
	move.w	p_arcc_rndcnt(a4),d0	*指定周期になったか
	cmp.w	p_arcc_dpnspd(a4),d0	*指定周期になったか
	bne	exit_artr
	clr.w	p_arcc_rndcnt(a4)
	move.w	p_arcc_dpnrpt(a4),d0	*無限ループ
	beq	@f
	cmp.w	p_arcc_dpntime(a4),d0
	beq	exit_artr
	addq.w	#1,p_arcc_dpntime(a4)
@@:
	move.b	p_arcc_dpndpt(a4),d2
	ext.w	d2
	bpl	artr_pls
	neg.w	d2
	divu	d1,d2		*d2=range/L d2.w=step counter
	move.w	d2,d0
	clr.w	d2
	divu	d1,d2		*d2=d2/L
	swap	d0
	move.w	d2,d0
	neg.l	d0
	asr.l	#8,d0
	bra	set_artr
artr_pls:
	divu	d1,d2		*d2=range/L d2.w=step counter
	move.w	d2,d0
	clr.w	d2
	divu	d1,d2		*d2=d2/L
	swap	d0
	move.w	d2,d0
	addq.l	#1,d0
	asr.l	#8,d0
set_artr:
	move.w	p_arcc_step2(a4),d2
	bmi	set_artr_sub
	add.w	d0,d2
	bpl	@f
	tst.w	d0
	bmi	artr_zero
	move.w	#$7fff,d2
@@:
	move.w	d2,p_arcc_step2(a4)
	rts
set_artr_sub:
	sub.w	d0,d2
	bmi	@f
	tst.w	d0
	bmi	artr_zero
	move.w	#$8000,d2
@@:
	move.w	d2,p_arcc_step2(a4)
	rts
artr_zero:				*振幅減少でゼロになった場合
	moveq.l	#0,d2
	move.l	d2,p_arcc_step2(a4)
exit_artr:
	rts
exit_artr2:
	move.w	p_arcc_o(a4),d2
	beq	@f
	move.w	d2,p_arcc_level(a4)
@@:
	rts

arcc_noko2:
	tst.w	p_arcc_spd2(a4)
	beq	@f
	subq.w	#1,p_arcc_spd2(a4)
	beq	@f
	move.w	p_arcc_step2(a4),d1
	sub.w	d1,p_arcc_level(a4)
	bclr.b	#b_arcc_syncok,p_arcc_flg2(a4)
	rts
@@:
	tas.b	p_arcc_flg2(a4)		*bset.b	#b_arcc_syncok,p_arcc_flg2(a4)
exit_arcc_ope:
	rts

arcc_noise:
	subq.w	#1,p_arcc_spd2(a4)
	bne	1f
	bsr	get_rand
	move.b	p_arcc_step2(a4),d2
	ext.w	d2
	bpl	@f
	neg.w	d2
@@:
	bsr	arcc_wvdpn_ope
	mulu	d2,d0
	swap	d0
	neg.b	d0
	move.b	d0,p_arcc_level(a4)
	move.w	p_arcc_spd(a4),d0
	lsr.w	d0
	move.w	d0,p_arcc_spd2(a4)
1:
	cmpi.w	#1,p_arcc_spd2(a4)
	bne	@f
	tas.b	p_arcc_flg2(a4)		*bset.b	#b_arcc_syncok,p_arcc_flg2(a4)
	rts
@@:
	bclr.b	#b_arcc_syncok,p_arcc_flg2(a4)
	rts

reduce_vol	macro	reg
	* < reg.w=-32768～+32767
	* > reg.w=0～+127
	local	rav0
	local	rav1
	tst.w	reg
	bpl	rav0
	move.w	#0,reg
	bra	rav1
rav0:
	cmpi.w	#127,reg
	ble	rav1
	move.w	#127,reg
rav1:
	endm

_case_nof_0	macro			*ノンオフモード時(FM音源,mpcmモード)
	* < a1.l=k_note
	* < d6.w=loop counter
	local	nof0_lp
	local	next_nof0
nof0_lp:
	move.l	(a1)+,d0		*note.b
	bmi	next_nof0
	cmpi.w	#MAX_GATE,d0
	beq	next_nof0
	addq.w	#1,d0			*check gate time (-1?)TIE_GATE_CODE
	beq	next_nof0
	addq.w	#1,d0			*check gate time (-2?)INF_GATE
	beq	@f			*case:len0
	subq.w	#1,-2(a1)		*dec gate
	bne	next_nof0
@@:
	ori.w	#$8080,-4(a1)		*gate 0 mark
	subq.b	#1,d3
next_nof0:
	dbra	d6,nof0_lp
	move.b	d3,p_how_many(a5)
	endm

_case_nof_fm:
	_case_nof_0
	bra	sp_cmd_ope_fm

int_play_ope_fm:			*FM
					*ゲートタイム処理
	move.b	p_how_many(a5),d3
	bmi	sp_cmd_ope_fm		*already all off
	move.w	p_voice_rsv(a5),d6	*loop counter
	lea	p_note(a5),a1
	tst.b	p_track_mode(a5)
	bmi	_case_nof_fm
	moveq.l	#8,d1			*FM reg. number
	move.l	d4,d5
	move.l	p_opmset(a5),a0		*!
dg_lp_f:
	move.l	(a1)+,d0
	bmi	_next_dgf
	cmpi.w	#MAX_GATE,d0
	beq	_next_dgf
	addq.w	#1,d0			*check gate time (-1?)TIE_GATE_CODE
	beq	_next_dgf
	addq.w	#1,d0			*check gate time (-2?)INF_GATE
	bne	@f
	ori.w	#$8080,-4(a1)		*case:len0
	bra	_next_dgf
@@:
	subq.w	#1,-2(a1)		*dec gate
	bne	_next_dgf
	ori.w	#$8080,-4(a1)		*note.b=off gate=0
	move.b	opm_kon-work(a6,d5.w),d2
	and.b	opm_nom-work(a6,d5.w),d2	*FM key off
	jsr	(a0)			*!opmset
	bset.b	#b_keyoff,p_onoff_bit(a5)	*set key off bit
	subq.b	#1,d3
_next_dgf:
	addq.b	#1,d5
	andi.b	#7,d5
	dbra	d6,dg_lp_f
	move.b	d3,p_how_many(a5)
sp_cmd_ope_fm:			*特殊コマンド処理(FMのケース)
	moveq.l	#0,d5		*d5.lw=pitch mark
				*d5.hw=level mark
				*各ルーチンはd4は壊さない(壊したら戻す)
	tst.b	p_port_flg(a5)	*ポルタメントチェック
	bne	@f
	tst.b	p_bend_sw(a5)	*オートベンドチェック
	beq	int_ope2_fm
@@:				*ディレイ値が正の場合
	tst.w	p_port_dly(a5)
	beq	do_port_fm
	subq.w	#1,p_port_dly(a5)
	bra	int_ope2_fm
do_port_fm:
	tst.w	p_port_cnt(a5)	*ポルタメント継続時間
	beq	int_ope2_fm
	port_ope		*ポルタメント/オートベンド処理
	subq.w	#1,p_port_cnt(a5)
	moveq.l	#2,d5		*mark
int_ope2_fm:				*ピッチモジュレーション処理
	tst.b	p_pmod_sw(a5)
	beq	int_ope3_fm
	bsr	pmod_ope
	ori.w	#4,d5
int_ope3_fm:			*アフタータッチシーケンス処理
	swap	d5
	tst.b	p_aftc_sw(a5)
	beq	int_ope4_fm
	subq.w	#1,p_aftc_dly2(a5)
	bne	iaf0
	moveq.l	#0,d0
	move.b	p_aftc_n(a5),d0
	addq.b	#1,d0			*-1.bでエントリのケースもあり(だから.b)
	cmpi.b	#7,d0
	bhi	iaf0
	move.b	d0,p_aftc_n(a5)
	btst.b	d0,p_aftc_omt(a5)
	beq	2f
	btst.b	d0,p_aftc_rltv(a5)
	beq	1f
	move.b	p_aftc_tbl(a5,d0.w),d1
	bpl	@f
	add.b	d1,p_aftc_level(a5)
	bpl	2f
	clr.b	p_aftc_level(a5)
	bra	2f
@@:
	add.b	d1,p_aftc_level(a5)
	bpl	2f
	move.b	#127,p_aftc_level(a5)
	bra	2f
1:
	move.b	p_aftc_tbl(a5,d0.w),p_aftc_level(a5)
2:
	add.w	d0,d0
	move.w	p_aftc_8st_tbl(a5,d0.w),p_aftc_dly2(a5)
iaf0
	move.w	#2,d5			*mark
int_ope4_fm:				*ＡＭ処理
	moveq.l	#$80,d6
	moveq.l	#arcc_max-1,d7
*	move.l	a5,a4
	lea	p_arcc_param(a5),a4
inop4fmlp:
	tst.b	p_arcc_sw(a4)
	beq	inop4fm_next
	bsr	arcc_ope
	or.b	d6,d5
inop4fm_next:
	lea	__arcc_len(a4),a4
	lsr.b	d6
	dbra	d7,inop4fmlp
*	move.l	a4,a5
int_ope5_fm:
	move.l	d5,p_lfo_param(a5)	*一時的に保存
	*↑チャンネルアサインを変更したらこのパラメータも消去する
	st.b	p_key_on(a5)
	subq.w	#1,(a5)			*dec p_step_time
	bne	@f
	movea.l	p_data_pointer(a5),a0	*compiled data address
	bsr	run_cmd_fm		*ﾁｬﾝﾈﾙｱｻｲﾝが変更されなければ次の番地へ戻ってくる
fm_return:
	move.l	a0,p_data_pointer(a5)	*次回に備える
@@:
	move.l	p_opmset(a5),a0		*!
	move.w	p_pitch_param(a5),d5
*pitch_ope_fm:				*PITCH処理
	move.w	p_voice_rsv(a5),d7	*loop counter
	move.w	_pgtjtbl_fm(pc,d5.w),d0
	jmp	_pgtjtbl_fm(pc,d0.w)
_pgtjtbl_fm:
	dc.w	level_ope_fm-_pgtjtbl_fm	*0
	dc.w	_portonlycase_fm-_pgtjtbl_fm	*2
	dc.w	_pmodonlycase_fm-_pgtjtbl_fm	*4
	dc.w	_pmodportcase_fm-_pgtjtbl_fm	*6
	dc.w	_dtnchg_case_fm-_pgtjtbl_fm	*8
	dc.w	_portonlycase_fm-_pgtjtbl_fm	*a
	dc.w	_pmodonlycase_fm-_pgtjtbl_fm	*c
	dc.w	_pmodportcase_fm-_pgtjtbl_fm	*e
_dtnchg_case_fm:
*	moveq.l	#0,d6
*	bra	@f
_portonlycase_fm:
	move.w	p_port_pitch(a5),d6
	bra	@f
_pmodonlycase_fm:
*	move.w	p_pmod_pitch(a5),d6
*	bra	@f
_pmodportcase_fm:
	move.w	p_port_pitch(a5),d6
	add.w	p_pmod_pitch(a5),d6
@@:
	lea	p_note(a5),a4
pitchfmlp:			*PITCHコントロールONLY
	move.b	(a4),d0		*get note number
	move.l	d6,d5		*set pitch param.
	set_fm_tune		*< a0.l=opmset
	addq.b	#1,d4
	andi.b	#7,d4
	addq.w	#k_note_len,a4
	dbra	d7,pitchfmlp
level_ope_fm:			*LEVEL処理
	move.w	p_level_param(a5),d5		*$0100はポリフォニックプレッシャーケース
	beq	key_on_fm
	move.w	p_ch(a5),d4
	move.w	d5,d0
	andi.w	#$000f,d0
	move.w	lvlopjt_fm(pc,d0.w),d0
	jmp	lvlopjt_fm(pc,d0.w)
lvlopjt_fm:
	dc.w	indivi_vol_fm-lvlopjt_fm	*0
	dc.w	fm_af0-lvlopjt_fm		*2
	dc.w	set_vol_fm-lvlopjt_fm		*4
	dc.w	fm_af0-lvlopjt_fm		*6

key_code_tbl:				*ＦＭ音源のキーコードのテーブル
	*	c   c#  d   d#  e   f   f#  g   g#  a   a#  b
	dc.b	$0C,$0D,$0E,$00,$01,$02,$04,$05,$06,$08,$09,$0A	*o-1(便宜上)
	dc.b	$0C,$0D,$0E,$00,$01,$02,$04,$05,$06,$08,$09,$0A	*o0
	dc.b	$0C,$0D,$0E,$10,$11,$12,$14,$15,$16,$18,$19,$1A	*o1
	dc.b	$1C,$1D,$1E,$20,$21,$22,$24,$25,$26,$28,$29,$2A	*o2
	dc.b	$2C,$2D,$2E,$30,$31,$32,$34,$35,$36,$38,$39,$3A	*o3
	dc.b	$3C,$3D,$3E,$40,$41,$42,$44,$45,$46,$48,$49,$4A	*o4
	dc.b	$4C,$4D,$4E,$50,$51,$52,$54,$55,$56,$58,$59,$5A	*o5
	dc.b	$5C,$5D,$5E,$60,$61,$62,$64,$65,$66,$68,$69,$6A	*o6
	dc.b	$6C,$6D,$6E,$70,$71,$72,$74,$75,$76,$78,$79,$7A	*o7
	dc.b	$7C,$7D,$7E,$70,$71,$72,$74,$75,$76,$78,$79,$7A	*o8
	dc.b	$7C,$7D,$7E,$70,$71,$72,$74,$75			*o9(便宜上)
	.even

set_vol_fm:				*set volume
	moveq.l	#127,d0
	sub.b	p_vol(a5),d0
	bra	@f
fm_af0:					*AFTC
	moveq.l	#127,d0
	sub.b	p_aftc_level(a5),d0
@@:					*AM処理
	* < d0.w=volume(127-0)
	neg.w	d0			*辻褄合わせ
	lea	p_arcc_param(a5),a4
	lea	ar_flg(pc),a1
	moveq.l	#0,d3			*初期値設定
	move.b	d3,(a1)+		*ar_flg=0
	move.b	cf-work(a6,d4.w),d3
	move.l	d3,d1
	andi.w	#7,d1
	move.b	fmaf0jtbl(pc,d1.w),d1
	beq	@f
	jmp	fmaf0jtbl(pc,d1.w)
fmaf0jtbl:
	dc.b	fmaf0_000-fmaf0jtbl
	dc.b	0
	dc.b	fmaf0_010-fmaf0jtbl
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	fmaf0_110-fmaf0jtbl
	dc.b	fmaf0_111-fmaf0jtbl
fmaf0_111:
	move.w	d0,(a1)+
	move.w	d0,(a1)+
	move.w	d0,(a1)+
	move.w	d0,(a1)+
	bra	@f
fmaf0_110:
	move.l	d0,(a1)+
	move.w	d0,(a1)+
	move.w	d0,(a1)+
	bra	@f
fmaf0_010:
	move.l	d0,(a1)+
	move.l	d0,(a1)+
	bra	@f
fmaf0_000:
	clr.l	(a1)+
	move.l	d0,(a1)+
@@:
	andi.w	#$f0,d5
	beq	@f
	bsr	do_calc_fm_arcc		*< d3.l=p_cf
@@:
	move.w	p_voice_rsv(a5),d7	*loop counter
	lea	ar_flg(pc),a1
	andi.w	#7,d3
	move.b	invl0jtbl-ar_flg(a1,d3.w),d3
	lea	invl0jtbl-ar_flg(a1,d3.w),a2	*jsr addr
	move.b	(a1)+,d3		*a1.l=ar_tl1
	bne	@f
	addq.w	#4,a2			*(bsr.w	set_fm_ch_ar)分スキップ
	bra	fmaflp00
@@:
	bsr	do_fm_global_arcc
fmaflp00:
	jsr	(a2)
	addq.b	#1,d4
	andi.b	#7,d4
	dbra	d7,fmaflp00
	bra	key_on_fm

indivi_vol_fm:				*音量は発音各ノートに依存する
	andi.w	#$f0,d5			*get arcc mark bit
	lea	ar_flg(pc),a1
	moveq.l	#0,d3			*初期値設定
	move.b	d3,(a1)+		*ar_flg
	move.l	d3,(a1)+		*tl1-2
	move.l	d3,(a1)+		*tl3-4
	move.b	cf-work(a6,d4.w),d3
	lea	p_arcc_param(a5),a4
	bsr	do_calc_fm_arcc
	move.w	p_voice_rsv(a5),d7	*loop counter
	lea	ar_flg(pc),a1
	andi.w	#$07,d3
	move.b	invl1jtbl-ar_flg(a1,d3.w),d3
	lea	invl1jtbl-ar_flg(a1,d3.w),a2	*jsr addr
	lea	p_note(a5),a4
	move.b	(a1)+,d3		*a1.l=ar_tl1
	bne	@f			*key_on_fm
	addq.w	#4,a2			*(bsr.w set_fm_ch_ar)の分スキップ
	bra	ivlp00
@@:
	bsr	do_fm_global_arcc
ivlp00:
	move.b	k_velo(a4),d0
	andi.w	#$7f,d0
	jsr	(a2)
	addq.w	#1,d4
	andi.w	#7,d4
	addq.w	#k_note_len,a4
	dbra	d7,ivlp00
key_on_fm:			*ノートオン処理
	tst.b	p_key_on(a5)	*第１音チェック
	bmi	exit_kon_fm
key_on_fm_patch:		*マスク時にパッチ(bra do_fmhlo)
	tas.b	p_onoff_bit(a5)	*set key on bit
	lea	p_key_on(a5),a3
fmkyonlp:
	move.l	(a3)+,d4	*このワークにどのチャンネルをキーオンすべきか書いてある
	bmi	do_fmhlo
	add.w	p_ch(a5),d4
	andi.w	#7,d4
	addq.w	#4,a3		*skip
	move.b	p_om(a5),d2
	or.b	d4,d2
	moveq.l	#8,d1
	jsr	(a0)		*!opmset
	bra	fmkyonlp
do_fmhlo:
	tst.b	p_sync(a5)	*HARD LFOシンクロか
	beq	exit_kon_fm
	moveq.l	#1,d1
	moveq.l	#2,d2		*HARD LFO RESET SEQUENCE #1
	jsr	(a0)		*!opmset
	moveq.l	#0,d2		*HARD LFO RESET SEQUENCE #2
	jmp	(a0)		*!opmset
exit_kon_fm:
exit_kon_ad:
	rts

ar_pan_:	equ	0
fmar_wk:
ar_pan:		dc.w	0			*pan			0
ar_pms:		dc.w	0			*pms			1
ar_ams:		dc.w	0			*ams			2
		dc.w	0			*			3
ar_amd:		dc.w	0			*amd			4
ar_pmd:		dc.w	0			*pmd			5
ar_lsp:		dc.w	0			*lfo spd		6
ar_nsp:		dc.w	0			*noise spd		7

		dc.b	0			*!!
ar_flg:		dc.b	0			*!!flag of ex.arcc
ar_tl1:		dc.w	0			*!!
ar_tl2:		dc.w	0			*!!
ar_tl3:		dc.w	0			*!!
ar_tl4:		dc.w	0			*!!
fmar_wk_end:

invl0jtbl:
	dc.b	invl0_000-invl0jtbl
	dc.b	0
	dc.b	invl0_010-invl0jtbl
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	invl0_110-invl0jtbl
	dc.b	invl0_111-invl0jtbl

invl0_000:
	bsr.w	set_fm_ch_ar
	moveq.l	#$60,d1
	or.b	d4,d1
	bsr	set_op1
	bsr	set_op2
	bsr	set_op3
	bra	set_op4_f

invl0_010:
	bsr.w	set_fm_ch_ar
	moveq.l	#$60,d1
	or.b	d4,d1
	bsr	set_op1
	bsr	set_op2_f
	bsr	set_op3
	bra	set_op4_f

invl0_110:
	bsr.w	set_fm_ch_ar
	moveq.l	#$60,d1
	or.b	d4,d1
	bsr	set_op1
	bsr	set_op2_f
	bsr	set_op3_f
	bra	set_op4_f

invl0_111:
	bsr.w	set_fm_ch_ar
	moveq.l	#$60,d1
	or.b	d4,d1
	bsr	set_op1_f
	bsr	set_op2_f
	bsr	set_op3_f
	bra	set_op4_f

invl1jtbl:
	dc.b	invl1_000-invl1jtbl
	dc.b	0
	dc.b	invl1_010-invl1jtbl
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	invl1_110-invl1jtbl
	dc.b	invl1_111-invl1jtbl

invl1_000:
	bsr.w	set_fm_ch_ar
	moveq.l	#$60,d1
	or.b	d4,d1
	bsr	set_op1
	bsr	set_op2
	bsr	set_op3
	bra	set_op4_v

invl1_010:
	bsr.w	set_fm_ch_ar
	moveq.l	#$60,d1
	or.b	d4,d1
	bsr	set_op1
	bsr	set_op2_v
	bsr	set_op3
	bra	set_op4_v

invl1_110:
	bsr.w	set_fm_ch_ar
	moveq.l	#$60,d1
	or.b	d4,d1
	bsr	set_op1
	bsr	set_op2_v
	bsr	set_op3_v
	bra	set_op4_v

invl1_111:
	bsr.w	set_fm_ch_ar
	moveq.l	#$60,d1
	or.b	d4,d1
	bsr	set_op1_v
	bsr	set_op2_v
	bsr	set_op3_v
	bra	set_op4_v

set_fm_ch_ar:				*FM CH ARCC
	* < d3=ar_lg
	* - d0
	* x d1,d2,d5,a4
	move.b	d3,d5			*d5=ar_flg
	beq	exit_sfca
	lsr.b	#1,d5
	bcc	@f
	move.w	ar_pan(pc),d2
	reduce_range	d2,0,127
	bsr	conv_p@p
	ror.b	#2,d2
	move.b	opmreg+AF(a6,d4.w),d1
	andi.w	#%0011_1111,d1
	or.w	d1,d2
	moveq.l	#$20,d1
	add.b	d4,d1
	jsr	(a0)			*!opmset
@@:					*PMS (3bits)
	lsr.b	#1,d5
	bcc	@f
	moveq.l	#0,d2
	move.b	opmreg+$38(a6,d4.w),d1
	move.w	ar_pms(pc),d2
	reduce_range	d2,0,7
	andi.w	#3,d1
	lsl.b	#4,d2
	or.b	d1,d2
	moveq.l	#$38,d1
	add.b	d4,d1
	jsr	(a0)			*!opmset
@@:					*AMS (2bits)
	lsr.b	#1,d5
	bcc	exit_sfca
	move.b	opmreg+$38(a6,d4.w),d1
	move.w	ar_ams(pc),d2
	reduce_range	d2,0,3
	andi.w	#$70,d1
	or.b	d1,d2
	moveq.l	#$38,d1
	add.b	d4,d1
	jmp	(a0)			*!opmset
exit_sfca:
	rts

do_calc_fm_arcc:			*複数のARCCによって算出された波形値を加算する
	* < d3.b=p_cf
	* < d5.b=arcc enable bits
	* < a4.l=p_arcc_param(a5)
	* - d0,d3
	* X d1,d2,d5,d6,d7,a1,a4
	moveq.l	#arcc_max-1,d7
	lea	ar_tl1(pc),a1
doarcclc1_lp:
	add.b	d5,d5
	bcc	next_fm_arcc
	move.b	p_arcc_level(a4),d6
	ext.w	d6
*!	bsr	debug1
	move.b	p_arcc(a4),d1
	bmi	extrn_fm_arcc		*FM ARCC(ワウワウ以外のケース)
	bne	@f
	move.b	d3,d1			*p_arcc=0のときはp_cfに従う
@@:
	andi.w	#$0f,d1
	beq	next_fm_arcc
	move.b	dcfajtbl(pc,d1.w),d1
	jmp	dcfajtbl(pc,d1.w)
dcfajtbl:
	dc.b	0			*dummy
	dc.b	dcfa0001-dcfajtbl
	dc.b	dcfa0010-dcfajtbl
	dc.b	dcfa0011-dcfajtbl
	dc.b	dcfa0100-dcfajtbl
	dc.b	dcfa0101-dcfajtbl
	dc.b	dcfa0110-dcfajtbl
	dc.b	dcfa0111-dcfajtbl
	dc.b	dcfa1000-dcfajtbl
	dc.b	dcfa1001-dcfajtbl
	dc.b	dcfa1010-dcfajtbl
	dc.b	dcfa1011-dcfajtbl
	dc.b	dcfa1100-dcfajtbl
	dc.b	dcfa1101-dcfajtbl
	dc.b	dcfa1110-dcfajtbl
	dc.b	dcfa1111-dcfajtbl
dcfa0001:
	add.w	d6,ar_tl1-ar_tl1(a1)
	bra	next_fm_arcc
dcfa0011:
	add.w	d6,ar_tl1-ar_tl1(a1)
dcfa0010:
	add.w	d6,ar_tl2-ar_tl1(a1)
	bra	next_fm_arcc
dcfa0101:
	add.w	d6,ar_tl1-ar_tl1(a1)
dcfa0100:
	add.w	d6,ar_tl3-ar_tl1(a1)
	bra	next_fm_arcc
dcfa0111:
	add.w	d6,ar_tl1-ar_tl1(a1)
dcfa0110:
	add.w	d6,ar_tl2-ar_tl1(a1)
	add.w	d6,ar_tl3-ar_tl1(a1)
	bra	next_fm_arcc
dcfa1001:
	add.w	d6,ar_tl1-ar_tl1(a1)
dcfa1000:
	add.w	d6,ar_tl4-ar_tl1(a1)
	bra	next_fm_arcc
dcfa1011:
	add.w	d6,ar_tl1-ar_tl1(a1)
dcfa1010:
	add.w	d6,ar_tl2-ar_tl1(a1)
	add.w	d6,ar_tl4-ar_tl1(a1)
	bra	next_fm_arcc
dcfa1101:
	add.w	d6,ar_tl1-ar_tl1(a1)
dcfa1100:
	add.w	d6,ar_tl3-ar_tl1(a1)
	add.w	d6,ar_tl4-ar_tl1(a1)
	bra	next_fm_arcc
dcfa1111:
	add.w	d6,ar_tl1-ar_tl1(a1)
dcfa1110:
	add.w	d6,ar_tl2-ar_tl1(a1)
	add.w	d6,ar_tl3-ar_tl1(a1)
	add.w	d6,ar_tl4-ar_tl1(a1)
next_fm_arcc:
	lea	__arcc_len(a4),a4
	dbra	d7,doarcclc1_lp
	rts

extrn_fm_arcc:				*その他のケース
	andi.w	#$7f,d1
	move.w	d1,d2
	add.w	d1,d1
	bset.b	d2,ar_flg-ar_tl1(a1)
	beq	first_efa
	bclr.b	#b_arcc_reset,p_arcc_flg(a4)	*初期化要請あったか
	beq	@f
	moveq.l	#0,d2
	move.b	p_arcc_reset(a4),d2		*あった
	bra	1f
@@:
	moveq.l	#0,d2
	move.b	p_arcc_origin(a4),d2
	btst.b	#b_arcc_phase,p_arcc_flg2(a4)
	beq	@f
	sub.w	d6,d2
	bra	1f
@@:
	add.w	d6,d2
1:
	add.w	d2,fmar_wk-ar_tl1(a1,d1.w)
	bra	next_fm_arcc
first_efa:
	bclr.b	#b_arcc_reset,p_arcc_flg(a4)	*初期化要請あったか
	beq	@f
	moveq.l	#0,d2
	move.b	p_arcc_reset(a4),d2		*あった
	bra	1f
@@:
	moveq.l	#0,d2
	move.b	p_arcc_origin(a4),d2
	btst.b	#b_arcc_phase,p_arcc_flg2(a4)
	beq	@f
	sub.w	d6,d2
	bra	1f
@@:
	add.w	d6,d2
1:
	move.w	d2,fmar_wk-ar_tl1(a1,d1.w)
	bra	next_fm_arcc

do_fm_global_arcc:			*OPM共通レジスタARCC
	* x d0,d1,d2
	* - a1
	move.b	d3,d0			*ar_flg
	beq	exit_dfga
					*noise frq
	add.b	d0,d0
	bcc	arcc_lfrq
	moveq.l	#$0f,d1
	tst.b	opmreg+$0f(a6)
	bpl	@f
	move.w	ar_nsp(pc),d2
	reduce_range	d2,0,63
	jsr	(a0)			*!opmset
	bra	arcc_lfrq
@@:
	move.w	ar_nsp(pc),d2
	reduce_range	d2,0,63
	tas.b	d2
	jsr	(a0)			*!opmset
arcc_lfrq:				*LFO frq
	add.b	d0,d0
	bcc	@f
	moveq.l	#0,d2
	move.w	ar_lsp(pc),d2
	add.w	d2,d2
	reduce_range	d2,0,255
	moveq.l	#$18,d1
	jsr	(a0)			*!opmset
@@:					*PMD
	add.b	d0,d0
	bcc	@f
	move.w	ar_pmd(pc),d2
	reduce_range	d2,0,127
	tas.b	d2
	moveq.l	#$19,d1
	jsr	(a0)			*!opmset
@@:					*AMD
	add.b	d0,d0
	bcc	@f
	move.w	ar_amd(pc),d2
	reduce_range	d2,0,127
	moveq.l	#$19,d1
	jmp	(a0)			*!opmset
@@:
exit_dfga:
	rts

set_op1:
	moveq.l	#0,d2
	move.b	ol1-work(a6,d4.w),d2	*OP1 carrier
	sub.w	(a1)+,d2
reduc_set_op:
	bmi	@f
	cmpi.w	#127,d2
	bls	1f
	moveq.l	#127,d2
1:
	jmp	(a0)				*!opmset
@@:
	moveq.l	#0,d2
	jmp	(a0)				*!opmset

set_op2:
	add.b	#16,d1
	moveq.l	#0,d2
	move.b	ol2-work(a6,d4.w),d2		*OP2 carrier
	sub.w	(a1)+,d2
	bra	reduc_set_op

set_op3:
	subq.b	#8,d1
	moveq.l	#0,d2
	move.b	ol3-work(a6,d4.w),d2		*OP3 carrier
	sub.w	(a1)+,d2
	bra	reduc_set_op

*set_op4:
*	add.b	#16,d1
*	moveq.l	#0,d2
*	move.b	ol4-work(a6,d4.w),d2		*OP4 carrier
*	sub.w	(a1),d2
*	subq.w	#6,a1				*a1.l=ar_tl1
*	bra	reduc_set_op

set_op1_f:
	move.l	d0,-(sp)
	moveq.l	#0,d2
	move.b	ol1-work(a6,d4.w),d2		*OP1 carrier
	bra	@f

set_op2_f:
	move.l	d0,-(sp)
	add.b	#16,d1
	moveq.l	#0,d2
	move.b	ol2-work(a6,d4.w),d2		*OP2 carrier
	bra	@f

set_op3_f:
	move.l	d0,-(sp)
	subq.b	#8,d1
	moveq.l	#0,d2
	move.b	ol3-work(a6,d4.w),d2		*OP3 carrier
@@:
	moveq.l	#127,d0
	add.w	(a1)+,d0
	reduce_range	d0,0,127
	bsr	consider_fader_fm
	add.w	d0,d2
	move.l	(sp)+,d0
	bra	reduc_set_op_f

set_op4_f:
	move.l	d0,-(sp)
	add.b	#16,d1
	moveq.l	#0,d2
	move.b	ol4-work(a6,d4.w),d2		*OP4 carrier
	moveq.l	#127,d0
	add.w	(a1),d0
	reduce_range	d0,0,127
	cmpi.w	#7,d4
	bne	@f
	tst.b	$0f+opmreg(a6)
	bpl	@f
	bsr	consider_fader_fm_n
	bra	1f
@@:
	bsr	consider_fader_fm
1:
	add.w	d0,d2
	subq.w	#6,a1				*a1.l=ar_tl1
	move.l	(sp)+,d0
reduc_set_op_f:
	tst.w	d2
	bmi	@f
	cmpi.w	#127,d2
	bls	1f
	moveq.l	#127,d2
1:
	jmp	(a0)				*!opmset
@@:
	moveq.l	#0,d2
	jmp	(a0)				*!opmset

set_op1_v:
	* < d0.w=0-127
	move.l	d0,-(sp)
	moveq.l	#0,d2
	move.b	ol1-work(a6,d4.w),d2		*OP1 carrier
	bra	@f

set_op2_v:
	move.l	d0,-(sp)
	add.b	#16,d1
	moveq.l	#0,d2
	move.b	ol2-work(a6,d4.w),d2		*OP2 carrier
	bra	@f

set_op3_v:
	move.l	d0,-(sp)
	subq.b	#8,d1
	moveq.l	#0,d2
	move.b	ol3-work(a6,d4.w),d2		*OP3 carrier
@@:
	add.w	(a1)+,d0
	reduce_range	d0,0,127
	bsr	consider_fader_fm
	add.w	d0,d2
	move.l	(sp)+,d0
	bra	reduc_set_op_f

set_op4_v:
	move.l	d0,-(sp)
	add.b	#16,d1
	moveq.l	#0,d2
	move.b	ol4-work(a6,d4.w),d2		*OP4 carrier
	add.w	(a1),d0
	reduce_range	d0,0,127
	cmpi.w	#7,d4
	bne	@f
	tst.b	$0f+opmreg(a6)
	bpl	@f
	bsr	consider_fader_fm_n
	bra	1f
@@:
	bsr	consider_fader_fm
1:
	add.w	d0,d2
	subq.w	#6,a1				*a1.l=ar_tl1
	move.l	(sp)+,d0
	bra	reduc_set_op_f

_case_nof_md:				*ノンオフモード時(MIDI)
	* < a1.l=p_note
	* < d3.w=loop counter
csnf_lp:
	move.l	(a1)+,d0
	bmi	end_dgm			*all end
	cmpi.w	#MAX_GATE,d0
	beq	next_csnf
	addq.w	#1,d0			*check gate (-1?)TIE_GATE_CODE
	beq	next_csnf
	addq.w	#1,d0			*check gate (-2?)INF_GATE
	beq	@f			*case len0
	subq.w	#1,-2(a1)		*dec gate
	bne	next_csnf
@@:
	move.l	d3,d0
	move.l	a1,a4
@@:
	move.l	(a4)+,-8(a4)
	dbmi	d0,@b
	subq.l	#k_note_len,a1
next_csnf:
	dbra	d3,csnf_lp
	bra	end_dgm

int_play_ope_md:			*MIDI
	move.l	p_midi_trans(a5),a0
					*ゲートタイム処理
	moveq.l	#max_note_on-1,d3
	lea	p_note(a5),a1
	tst.b	p_track_mode(a5)
	bmi	_case_nof_md
kom_lp0:
	move.b	(a1)+,d1		*note
	bmi	end_dgm
	addq.w	#1,a1
	move.w	(a1)+,d0
	cmpi.w	#MAX_GATE,d0
	beq	next_dgm
	addq.w	#1,d0			*test gate (-1?)TIE_GATE_CODE
	beq	next_dgm
	addq.w	#1,d0			*test gate (-2?)INF_GATE
	beq	@f			*case:len0
	subq.w	#1,-2(a1)		*dec gate
	bne	next_dgm
	moveq.l	#$90,d0
	add.b	d4,d0
	jsr	(a0)			*send cmd
	move.b	d1,d0
	jsr	(a0)			*note number
	bset.b	#b_keyoff,p_onoff_bit(a5)	*set key off bit
	moveq.l	#$00,d0
	jsr	(a0)			*#0
@@:	*ノートワーク整列処理
	move.l	d3,d0
	move.l	a1,a4
@@:
	move.l	(a4)+,-8(a4)
	dbmi	d0,@b
	subq.l	#k_note_len,a1
next_dgm:
	dbra	d3,kom_lp0
end_dgm:
sp_cmd_ope_md:
	moveq.l	#0,d5		*d5.lw=pitch mark
				*d5.hw=level mark
				*各ルーチンはd4は壊さない(壊したら戻す)
	tst.b	p_port_flg(a5)
	bne	@f
	tst.b	p_bend_sw(a5)
	beq	int_ope2_md
@@:
	tst.w	p_port_dly(a5)
	beq	do_port_md
	subq.w	#1,p_port_dly(a5)
	bra	int_ope2_md
do_port_md:
	tst.w	p_port_cnt(a5)		*ポルタメント継続時間
	beq	int_ope2_md
	port_ope			*ポルタメント/オートベンド処理
	subq.w	#1,p_port_cnt(a5)
	moveq.l	#2,d5			*mark
int_ope2_md:				*ピッチモジュレーション処理
	tst.b	p_pmod_sw(a5)
	beq	int_ope3_md
	tst.b	p_pmod_mode(a5)
	bmi	normal_pmod_md
					*拡張ピッチモジュレーション
	bsr	pmod_ope
	ori.w	#4,d5
	bra	int_ope3_md
normal_pmod_md:
	subq.w	#1,p_pmod_dly2(a5)
	bne	int_ope3_md
	moveq.l	#0,d2
	move.b	p_pmod_n(a5),d2
	addq.b	#1,d2			*-1.bでエントリのケースもあり(だから.b)
	cmpi.b	#7,d2
	bhi	int_ope3_md		*最後のを継続して使用
	move.b	d2,p_pmod_n(a5)
	btst.b	d2,p_pmod_omt(a5)	*省略の場合は前回のものを継続
	beq	npm0
	add.w	d2,d2
	move.w	p_pmod_8st_tbl(a5,d2.w),p_pmod_dly2(a5)	*set new delay
	move.w	p_pmod_dpt_tbl(a5,d2.w),d0	*次の振幅パラメータ
	beq	1f
	bpl	@f
	neg.w	d0
@@:					*振幅値縮小処理
	cmpi.w	#127,d0			*(振幅パラメータを尊重するため出力時に行う)
	bls	1f
	moveq.l	#127,d0
1:
	move.w	d0,p_pmod_dpt_now(a5)
	move.w	d0,p_pmod_pitch(a5)	*わざと.w
	swap	d5			*先取りswap
	ori.w	#$8000,d5		*mark
	bra	@f
npm0:
	add.w	d2,d2
	move.w	p_pmod_8st_tbl(a5,d2.w),p_pmod_dly2(a5)	*set new delay
int_ope3_md:				*アフタータッチシーケンス処理
	swap	d5
@@:
	tst.b	p_aftc_sw(a5)
	beq	int_ope4_md
	subq.w	#1,p_aftc_dly2(a5)
	bne	int_ope4_md
	moveq.l	#0,d2
	move.b	p_aftc_n(a5),d2
	addq.b	#1,d2			*-1.bでエントリのケースもあり(だから.b)
	cmpi.b	#7,d2
	bhi	int_ope4_md
	move.b	d2,p_aftc_n(a5)
	btst.b	d2,p_aftc_omt(a5)
	beq	3f
	btst.b	d2,p_aftc_rltv(a5)
	beq	1f
	move.b	p_aftc_tbl(a5,d2.w),d1
	bpl	@f
	add.b	d1,p_aftc_level(a5)
	bpl	2f
	clr.b	p_aftc_level(a5)
	bra	2f
@@:
	add.b	d1,p_aftc_level(a5)
	bpl	2f
	move.b	#127,p_aftc_level(a5)
	bra	2f
1:
	move.b	p_aftc_tbl(a5,d2.w),p_aftc_level(a5)
2:
	moveq.l	#$d0,d0			*send ch pressure
	add.b	d4,d0
	jsr	(a0)			*CH prs
	move.b	p_aftc_level(a5),d0
	jsr	(a0)			*aftc value
3:
	add.w	d2,d2
	move.w	p_aftc_8st_tbl(a5,d2.w),p_aftc_dly2(a5)
int_ope4_md:				*ＡＭ処理
	moveq.l	#$80,d6			*d6.w=level mark
	moveq.l	#arcc_max-1,d7
*	move.l	a5,a4
	lea	p_arcc_param(a5),a4
int_ope4_lp:
	tst.b	p_arcc_sw(a4)
	beq	int_ope4_next
	tst.b	p_arcc_mode(a4)
	bmi	normal_arcc_md
					*拡張ＡＲＣＣモード
	bsr	arcc_ope
	or.b	d6,d5			*mark
	bra	int_ope4_next
normal_arcc_md:
	subq.w	#1,p_arcc_dly2(a4)
	bne	int_ope4_next
	moveq.l	#0,d2
	move.b	p_arcc_n(a4),d2
	addq.b	#1,d2			*-1.bでエントリのケースもあり(だから.b)
	cmpi.b	#7,d2
	bhi	int_ope4_next		*最後のを継続して使用
	move.b	d2,p_arcc_n(a4)
	btst.b	d2,p_arcc_omt(a4)	*省略の場合は前回のものを継続
	beq	2f
	move.b	p_arcc_dpt_tbl(a4,d2.w),d3
	ext.w	d3
	bpl	1f
	neg.w	d3
	cmpi.w	#127,d3
	bls	1f
	moveq.l	#127,d3
1:
	move.b	d3,p_arcc_dpt_now(a4)
	move.b	d3,p_arcc_level(a4)	*次の振幅パラメータ
	or.b	d6,d5			*mark
2:
	add.w	d2,d2
	move.w	p_arcc_8st_tbl(a4,d2.w),p_arcc_dly2(a4)
int_ope4_next:
	lea	__arcc_len(a4),a4
	lsr.b	d6
	dbra	d7,int_ope4_lp
*	move.l	a4,a5
int_ope5_md:
	move.l	d5,p_lfo_param(a5)	*一時的に保存
	*↑チャンネルアサインを変更したらこのパラメータも消去する
	st.b	p_key_on(a5)
	subq.w	#1,(a5)			*dec p_step_time
	bne	@f
	movea.l	p_data_pointer(a5),a0	*compiled data address
	bsr	run_cmd_md		*ﾁｬﾝﾈﾙｱｻｲﾝが変更されなければ次の番地へ戻ってくる
md_return:
	move.l	a0,p_data_pointer(a5)	*次回に備える
@@:
	move.l	p_midi_trans(a5),a0
					* PANPOTの設定
	bclr.b	#pts_panpot,p_timbre_set(a5)
	beq	@f
	moveq.l	#$b0,d0
	or.b	d4,d0
	jsr	(a0)			*ctrl chg
	move.b	p_pan(a5),d1
	bpl	1f
	moveq.l	#MIDI_EXP,d0		*PAN=0のシミュレート
	jsr	(a0)
	moveq.l	#0,d0			*EXPRESSION=0にする
	jsr	(a0)
	bra	@f
1:					*通常パン
	moveq.l	#MIDI_PAN,d0
	jsr	(a0)			*pan cmd
	move.b	d1,d0
	jsr	(a0)
@@:					*音量の設定
	bclr.b	#pts_volume,p_timbre_set(a5)
	beq	@f
	* < d1.b=0-127
	* < d4.w=ch
	* X d0-d1,a4
	moveq.l	#$b0,d0
	or.b	d4,d0
	jsr	(a0)
	moveq.l	#MIDI_VOL,d0
	jsr	(a0)
	moveq.l	#0,d0
	move.b	p_vol(a5),d0
	bsr	consider_fader_md
	jsr	(a0)
@@:
	bclr.b	#pts_damper,p_timbre_set(a5)
	beq	@f
	moveq.l	#$b0,d0
	or.b	d4,d0
	jsr	(a0)
	moveq.l	#MIDI_DMP,d0
	jsr	(a0)
	move.b	p_damper(a5),d0
	jsr	(a0)
@@:
	move.l	p_lfo_param(a5),d5
	beq	key_on_md
	tst.w	d5
	beq	chg_pitch?_md
	move.l	a5,a2		*save a5 into a2
	lea	p_arcc_param(a5),a5
arcc_out_lp:
	add.b	d5,d5
	bcc	next_arcc_out
	move.b	p_arcc(a5),d1
	bmi	next_arcc_out
	tst.b	p_arcc_mode(a5)
	bpl	special_arcc
	moveq.l	#$b0,d0		*NORMAL ARCCの場合
	or.b	d4,d0
	jsr	(a0)
	move.b	d1,d0
	jsr	(a0)
	move.b	p_arcc_level(a5),d0
	bclr.b	#b_arcc_reset,p_arcc_flg(a5)	*初期化要請あったか
	beq	@f
	move.b	p_arcc_reset(a5),d0		*あった
@@:
	cmpi.b	#MIDI_VOL,d1
	bne	@f
	ext.w	d0
	bsr	consider_fader_md
@@:
	jsr	(a0)
	bra	next_arcc_out
special_arcc:					*SPECIAL ARCCの場合
	* < d1.b=arcc ctrl number
	bclr.b	#b_arcc_reset,p_arcc_flg(a5)	*初期化要請あったか
	beq	@f
	move.b	p_arcc_reset(a5),d2		*あった
	bra	1f
@@:
	move.b	p_arcc_origin(a5),d2
	btst.b	#b_arcc_phase,p_arcc_flg2(a5)
	beq	case_normiso
						*逆位相ケース
	move.b	p_arcc_level(a5),d0
*!	bsr	debug1
	bpl	@f
	sub.b	d0,d2
	bpl	1f
	moveq.l	#0,d2
	bra	1f
@@:
	sub.b	d0,d2
	bpl	1f
	moveq.l	#127,d2
	bra	1f
case_normiso:					*通常位相ケース
	move.b	p_arcc_level(a5),d0
*!	bsr	debug1
	bpl	@f
	add.b	d0,d2
	bpl	1f
	moveq.l	#0,d2
	bra	1f
@@:
	add.b	d0,d2
	bpl	1f
	moveq.l	#127,d2
1:
	cmp.b	p_arcc_last(a5),d2
	beq	next_arcc_out
	move.b	d2,p_arcc_last(a5)
	moveq.l	#$b0,d0
	or.b	d4,d0
	jsr	(a0)
	move.b	d1,d0
	jsr	(a0)
	move.b	d2,d0
	cmp.b	#MIDI_VOL,d1
	bne	@f
	ext.w	d0
	bsr	consider_fader_md
@@:
	jsr	(a0)
next_arcc_out:
	lea	__arcc_len(a5),a5
	tst.b	d5
	bne	arcc_out_lp
	move.l	a2,a5			*get back a5
					*normal pmod on ?
	add.w	d5,d5
	bcc	1f
	moveq.l	#$b0,d0
	or.b	d4,d0
	jsr	(a0)
	moveq.l	#MIDI_VIB,d0				*vibrato
	jsr	(a0)
	move.w	p_pmod_pitch(a5),d0	*!!
	beq	@f
	bset.b	#b_pmod_reset,p_md_flg(a5)		*set @m mark
	bra	mout@m
@@:
	bclr.b	#b_pmod_reset,p_md_flg(a5)		*clr @m mark
mout@m:
	jsr	(a0)
1:					*アフタータッチ(初回)の出力
	add.w	d5,d5
	bcc	chg_pitch?_md
	moveq.l	#$d0,d0
	or.b	d4,d0
	jsr	(a0)
	move.b	p_aftc_level(a5),d0
	jsr	(a0)
chg_pitch?_md:				*ピッチ系出力
	swap	d5
	move.w	pgtjtbl_md(pc,d5.w),d0
	jmp	pgtjtbl_md(pc,d0.w)
pgtjtbl_md:
	dc.w	key_on_md-pgtjtbl_md
	dc.w	portonlycase_md-pgtjtbl_md
	dc.w	pmodonlycase_md-pgtjtbl_md
	dc.w	pmodportcase_md-pgtjtbl_md
	dc.w	dtnchg_case_md-pgtjtbl_md
	dc.w	portonlycase_md-pgtjtbl_md
	dc.w	pmodonlycase_md-pgtjtbl_md
	dc.w	pmodportcase_md-pgtjtbl_md
dtnchg_case_md:
portonlycase_md:
	move.w	p_port_pitch(a5),d1
	ext.l	d1
	bra	chk_sptie
pmodonlycase_md:
pmodportcase_md:
	move.w	p_pmod_pitch(a5),d1	*FM range mode ならば振幅値変換
	ext.l	d1
	tst.b	p_pmod_mode(a5)
	bne	@f
	chg64_683_	d1		*(64range→683range)
@@:
	move.w	p_port_pitch(a5),d0
	ext.l	d0
	add.l	d0,d1
chk_sptie:
	move.w	p_special_tie(a5),d0
	ext.l	d0
	add.l	d0,d1
	move.w	p_detune(a5),d0
	ext.l	d0
	add.l	d0,d1
	add.l	#8192,d1
	bpl	@f
	moveq.l	#0,d1
	bra	1f
@@:
	cmpi.l	#16383,d1
	bls	1f
	move.w	#16383,d1
1:
	cmp.w	p_pitch_last(a5),d1
	beq	key_on_md		*前回と同じ値だった
	move.w	d1,p_pitch_last(a5)
	moveq.l	#$e0,d0			*send bend cmd
	or.b	d4,d0
	jsr	(a0)
	move.w	d1,d0
	andi.b	#127,d0
	jsr	(a0)
	bset.b	#b_bend_reset,p_md_flg(a5)		*bend set marker
	lsr.w	#7,d1
	move.b	d1,d0
	jsr	(a0)
key_on_md:			*ノートオン処理
	tst.b	p_key_on(a5)
	bmi	exit_kon_md
	lea	p_key_on(a5),a3
	tas.b	p_onoff_bit(a5)	*set key on bit
konmdlp:
	move.b	(a3)+,d2
	bmi	exit_kon_md
	move.b	(a3)+,d3	*velocity
	addq.w	#2,a3
				*音色設定
	move.b	(a3)+,d1
	bmi	@f
	move.b	d1,p_bank_msb(a5)
	moveq.l	#$b0,d0
	or.b	d4,d0
	jsr	(a0)
	moveq.l	#$00,d0		*bank MSB
	jsr	(a0)
	move.l	d1,d0
	jsr	(a0)		*BANK送信
@@:
	move.b	(a3)+,d1
	bmi	@f
	move.b	d1,p_bank_lsb(a5)
	moveq.l	#$b0,d0
	or.b	d4,d0
	jsr	(a0)
	moveq.l	#$20,d0		*bank LSB
	jsr	(a0)
	move.l	d1,d0
	jsr	(a0)		*BANK送信
@@:
	move.w	(a3)+,d1
	bmi	@f
	move.w	d1,p_pgm(a5)
	moveq.l	#$c0,d0
	or.b	d4,d0
	jsr	(a0)		*send pgm chg
	move.l	d1,d0
	jsr	(a0)
@@:
key_on_md_patch:		*マスク時にパッチ(bra konmdlp)
	moveq.l	#$90,d0		*note on cmd
	add.b	d4,d0
	jsr	(a0)

	move.b	d2,d0		*note number
	jsr	(a0)
	move.l	d3,d0		*velocity
	jsr	(a0)
	bra	konmdlp
exit_kon_md:
	rts

_case_nof_ad:
	_case_nof_0
	bra	sp_cmd_ope_ad

int_play_ope_ad:			*ADPCM
					*ゲートタイム処理
	move.b	p_how_many(a5),d3
	bmi	sp_cmd_ope_ad		*already all off
	move.w	p_voice_rsv(a5),d6	*loop counter
	lea	p_note(a5),a1
	tst.b	p_track_mode(a5)
	bmi	_case_nof_ad
	moveq.l	#0,d5
	move.b	d4,d5
dg_lp_a:
	move.l	(a1)+,d0
	bmi	_next_dga
	cmpi.w	#MAX_GATE,d0
	beq	_next_dga
	addq.w	#1,d0			*test gate (-1?)TIE_GATE_CODE
	beq	_next_dga
	addq.w	#2,d0			*test gate (-2?)INF_GATE
	bne	@f
	ori.w	#$8080,-4(a1)		*case:len0
	bra	_next_dga
@@:
	subq.w	#1,-2(a1)		*dec gate
	bne	_next_dga
	ori.w	#$8080,-4(a1)		*case:gate=0 then note.b=off,velo=off
	move.l	d5,d0
	bsr	pcm_key_off
	bset.b	#b_keyoff,p_onoff_bit(a5)	*set key off bit
	subq.b	#1,d3
_next_dga:
	addq.b	#1,d5
	andi.b	#$0f,d5
	dbra	d6,dg_lp_a
	move.b	d3,p_how_many(a5)
sp_cmd_ope_ad:			*特殊コマンド処理(MPCMのケース)
	moveq.l	#0,d5		*d5.lw=pitch mark
				*d5.hw=level mark
				*各ルーチンはd4は壊さない(壊したら戻す)
	tst.b	p_port_flg(a5)	*ポルタメントチェック
	bne	@f
	tst.b	p_bend_sw(a5)	*オートベンドチェック
	beq	int_ope2_ad
@@:
	tst.w	p_port_dly(a5)
	beq	do_port_ad
	subq.w	#1,p_port_dly(a5)
	bra	int_ope2_ad
do_port_ad:
	tst.w	p_port_cnt(a5)		*ポルタメント継続時間

beq	int_ope2_ad
	port_ope			*ポルタメント/オートベンド処理
	subq.w	#1,p_port_cnt(a5)
	moveq.l	#2,d5			*mark
int_ope2_ad:				*ピッチモジュレーション処理
	tst.b	p_pmod_sw(a5)
	beq	int_ope3_ad
	bsr	pmod_ope
	ori.w	#4,d5
int_ope3_ad:				*アフタータッチシーケンス処理
	swap	d5
	tst.b	p_aftc_sw(a5)
	beq	int_ope4_ad
	subq.w	#1,p_aftc_dly2(a5)
	bne	iaa0
	moveq.l	#0,d0
	move.b	p_aftc_n(a5),d0
	addq.b	#1,d0			*-1.bでエントリのケースもあり(だから.b)
	cmpi.b	#7,d0
	bhi	iaa0
	move.b	d0,p_aftc_n(a5)
	btst.b	d0,p_aftc_omt(a5)
	beq	2f
	btst.b	d0,p_aftc_rltv(a5)
	beq	1f
	move.b	p_aftc_tbl(a5,d0.w),d1
	bpl	@f
	add.b	d1,p_aftc_level(a5)
	bpl	2f
	clr.b	p_aftc_level(a5)
	bra	2f
@@:
	add.b	d1,p_aftc_level(a5)
	bpl	2f
	move.b	#127,p_aftc_level(a5)
	bra	2f
1:
	move.b	p_aftc_tbl(a5,d0.w),p_aftc_level(a5)
2:
	add.w	d0,d0
	move.w	p_aftc_8st_tbl(a5,d0.w),p_aftc_dly2(a5)
iaa0:
	move.w	#2,d5			*mark
int_ope4_ad:				*ＡＭ処理
	moveq.l	#$80,d6
	moveq.l	#arcc_max-1,d7
	lea	p_arcc_param(a5),a4
inop4adlp:
	tst.b	p_arcc_sw(a4)
	beq	inop4ad_next
	bsr	arcc_ope
	or.b	d6,d5
inop4ad_next:
	lea	__arcc_len(a4),a4
	lsr.b	d6
	dbra	d7,inop4adlp
int_ope5_ad:
	move.l	d5,p_lfo_param(a5)	*一時的に保存
	*↑チャンネルアサインを変更したらこのパラメータも消去する
	st.b	p_key_on(a5)
	subq.w	#1,(a5)			*dec p_step_time
	bne	@f
	movea.l	p_data_pointer(a5),a0	*compiled data address
	bsr	run_cmd_ad		*ﾁｬﾝﾈﾙｱｻｲﾝが変更されなければ次の番地へ戻ってくる
ad_return:
	move.l	a0,p_data_pointer(a5)	*次回に備える
@@:
	move.l	p_lfo_param(a5),d5
	beq	_key_on_ad
	move.l	d5,d0
	andi.w	#$000f,d0
	move.w	lvlopjt_ad(pc,d0.w),d0
	jmp	lvlopjt_ad(pc,d0.w)
lvlopjt_ad:
	dc.w	indivi_vol_ad-lvlopjt_ad	*0
	dc.w	ad_af0-lvlopjt_ad		*2
	dc.w	set_vol_ad-lvlopjt_ad		*4
	dc.w	ad_af0-lvlopjt_ad		*6
set_vol_ad:				*set volume only
	moveq.l	#0,d0
	move.b	p_vol(a5),d0
	bra	@f
ad_af0:					*AFTC
	moveq.l	#0,d0
	move.b	p_aftc_level(a5),d0
@@:
	* < d0.w=volume(0-127)
	move.l	d0,ad_ar_flg-work(a6)	*ad_ar_flg=0,ad_ar_vol=d0
	lea	p_arcc_param(a5),a4
	andi.w	#$f0,d5
	beq	@f
	bsr	do_calc_ad_arcc
@@:
	move.w	ad_ar_vol(pc),d0	*get ad_ar_vol
	bmi	@f
	cmpi.w	#127,d0
	bls	go_cfa
	moveq.l	#127,d0
	bra	go_cfa
@@:
	moveq.l	#0,d0
	bra	@f
go_cfa:
	bsr	consider_fader_ad	*フェーダー考慮
@@:
	move.l	d0,d2

	move.w	p_voice_rsv(a5),d7	*loop counter
	lea	_set_ad_ch_ar(pc),a2	*フェーダー考慮済み
	move.w	ad_ar_flg(pc),d3
	bne	@f
	lea	do_ad_volume(pc),a2	*フェーダー考慮済み
@@:					* < d2.w=volme(0-127)
	swap	d5
	tst.w	d5
	bne	proc_pitch_level_ad
@@:
	move.l	d2,d0
	jsr	(a2)
	addq.b	#1,d4
	andi.b	#$0f,d4
	dbra	d7,@b
	bra	_key_on_ad

do_calc_ad_arcc:
	* < d5.b=arcc enable bits
	* < a4.l=p_arcc_param(a5)
	* d1,d2,d3,d5,a4
	moveq.l	#arcc_max-1,d3
do_caa_lp:
	add.b	d5,d5
	bcc	next_ad_arcc
	move.b	p_arcc_level(a4),d6
	ext.w	d6
	move.b	p_arcc(a4),d1		*arccc ctrl
	andi.w	#$0f,d1			*V3.00時点でサポートしているのは7(11),10だけ
	move.b	adar_ctrltbl(pc,d1.w),d1
	jmp	adar_ctrltbl(pc,d1.w)
next_ad_arcc:
	lea	__arcc_len(a4),a4
	dbra	d3,do_caa_lp
	rts

adar_ctrltbl:
	dc.b	next_ad_arcc-adar_ctrltbl	*0
	dc.b	next_ad_arcc-adar_ctrltbl	*1
	dc.b	next_ad_arcc-adar_ctrltbl	*2
	dc.b	next_ad_arcc-adar_ctrltbl	*3
	dc.b	next_ad_arcc-adar_ctrltbl	*4
	dc.b	next_ad_arcc-adar_ctrltbl	*5
	dc.b	next_ad_arcc-adar_ctrltbl	*6
	dc.b	calc_adar_vol-adar_ctrltbl	*7 Volume
	dc.b	next_ad_arcc-adar_ctrltbl	*8
	dc.b	next_ad_arcc-adar_ctrltbl	*9
	dc.b	calc_adar_pan-adar_ctrltbl	*10 Panpot
	dc.b	calc_adar_vol-adar_ctrltbl	*11 Volume
	dc.b	next_ad_arcc-adar_ctrltbl	*12
	dc.b	next_ad_arcc-adar_ctrltbl	*13
	dc.b	next_ad_arcc-adar_ctrltbl	*14
	dc.b	next_ad_arcc-adar_ctrltbl	*15

calc_adar_vol:				*ADPCM ARCC VOLの計算
	tas.b	1+ad_ar_flg-work(a6)	*7
	add.w	d6,ad_ar_vol-work(a6)
	bra	next_ad_arcc

calc_adar_pan:				*ADPCM ARCC PANの計算
	bset.b	#2,ad_ar_flg-work(a6)	*10
	beq	first_cap
	bclr.b	#b_arcc_reset,p_arcc_flg(a4)	*初期化要請あったか
	beq	@f
	moveq.l	#0,d1
	move.b	p_arcc_reset(a4),d1		*あった
	bra	1f
@@:
	moveq.l	#0,d1
	move.b	p_arcc_origin(a4),d1
	btst.b	#b_arcc_phase,p_arcc_flg2(a4)
	beq	@f
	sub.w	d6,d1
	bra	1f
@@:
	add.w	d6,d1
1:
	add.w	d1,ad_ar_pan-work(a6)
	bra	next_ad_arcc
first_cap:
	bclr.b	#b_arcc_reset,p_arcc_flg(a4)	*初期化要請あったか
	beq	@f
	moveq.l	#0,d1
	move.b	p_arcc_reset(a4),d1		*あった
	bra	1f
@@:
	moveq.l	#0,d1
	move.b	p_arcc_origin(a4),d1
	btst.b	#b_arcc_phase,p_arcc_flg2(a4)
	beq	@f
	sub.w	d6,d1
	bra	1f
@@:
	add.w	d6,d1
1:
	move.w	d1,ad_ar_pan-work(a6)
	bra	next_ad_arcc

ad_ar:
ad_ar_flg:	ds.w	1	*0-15ビットワーク(今のところ16ビット(0-15))
ad_ar_vol:	ds.w	1	*0
ad_ar_pan:	ds.w	1	*2

set_ad_ch_ar:			*ADPCM共通ARCC
	* < d0.w=volume(0-127)
	* < d3.w=ad_ar_flg
	* < d4=ch
	* x d0
	tst.b	d3
	bpl	@f
	add.w	ad_ar_vol(pc),d0
	reduce_range	d0,0,127
@@:
	bsr	consider_fader_ad	*フェーダー考慮
_set_ad_ch_ar:				*フェーダー考慮済みエントリ
	* < d0.w=volume(0-127)
	* < d3.w=ad_ar_flg
	bsr	do_ad_volume
	* < d3.w=ad_ar_flg
	* < d4=ch
	btst.l	#10,d3
	beq	exit_saca
	move.w	ad_ar_pan(pc),d2
	reduce_range	d2,0,127
	bra	do_adpcm_pan
exit_saca:
	rts

proc_pitch_level_ad:			*PROCESSING PITCH&LEVEL
	move.w	pgtjtbl_ad(pc,d5.w),d0
	jmp	pgtjtbl_ad(pc,d0.w)
pgtjtbl_ad:
	dc.w	_key_on_ad-pgtjtbl_ad
	dc.w	portonlycase_ad-pgtjtbl_ad
	dc.w	pmodonlycase_ad-pgtjtbl_ad
	dc.w	pmodportcase_ad-pgtjtbl_ad
	dc.w	dtnchg_case_ad-pgtjtbl_ad
	dc.w	portonlycase_ad-pgtjtbl_ad
	dc.w	pmodonlycase_ad-pgtjtbl_ad
	dc.w	pmodportcase_ad-pgtjtbl_ad
dtnchg_case_ad:
*	moveq.l	#0,d5
*	bra	@f
portonlycase_ad:
	move.w	p_port_pitch(a5),d5
	bra	@f
pmodonlycase_ad:
*	move.w	p_pmod_pitch(a5),d5
*	bra	@f
pmodportcase_ad:
	move.w	p_port_pitch(a5),d5
	add.w	p_pmod_pitch(a5),d5
@@:
	* < d2.w=volume 0-127
	lea	p_note(a5),a4
@@:
	move.l	d2,d0
	jsr	(a2)
	move.b	(a4),d1			*get note
	bsr	set_ad_tune
	addq.b	#1,d4
	andi.b	#$0f,d4
	addq.w	#k_note_len,a4
	dbra	d7,@b
	bra	key_on_ad

indivi_vol_ad:				*音量は発音各ノートに依存する
	move.w	p_voice_rsv(a5),d7	*loop counter
	andi.w	#$f0,d5			*get arcc mark bit
	clr.l	ad_ar_flg-work(a6)		*ad_ar_flg=0,ad_ar_vol=0
	lea	p_arcc_param(a5),a4
	bsr	do_calc_ad_arcc
	lea	p_note(a5),a4
	lea	set_ad_ch_ar(pc),a2		*フェーダー考慮もしなければならない
	move.w	ad_ar_flg(pc),d3
	bne	@f
	lea	_do_ad_volume(pc),a2		*フェーダー考慮もしなければならない
@@:
	swap	d5
	tst.w	d5
	bne	proc_pitch_level_ad2
@@:
	move.b	k_velo(a4),d0
	andi.w	#$7f,d0
	jsr	(a2)
	addq.w	#1,d4
	andi.w	#$0f,d4
	addq.w	#k_note_len,a4
	dbra	d7,@b
_key_on_ad:				*ノートオン処理
	moveq.l	#0,d5			*PMOD/PORTパラメータニュートラル値
key_on_ad:				*PMOD/PORTパラメータを持っている場合はこちらがエントリ
key_on_ad_patch:			*マスク時にパッチ(RTS)
	tst.b	p_key_on(a5)		*第１音チェック
	bmi	exit_kon_ad
	tas.b	p_onoff_bit(a5)		*set key on bit
	lea	p_key_on(a5),a3
	move.w	p_ch(a5),a4		*わざとa4
	btst.b	#b_vtune_mode,p_md_flg(a5)
	bne	case_mpcm_k_on		*mpcm key on
koa_lp:					*TONE CASE
	moveq.l	#0,d2
	move.b	(a3)+,d2		*get note
	bmi	exit_kon_ad
	moveq.l	#0,d0
	move.b	(a3)+,d0		*get velocity
	bsr	consider_fader_ad
	move.l	d0,d1
	move.w	(a3)+,d4
	move.l	(a3)+,d0		*d0.l=bank,timbre
	lsl.l	#7,d0			*バンク考慮
	add.l	d2,d0
	cmp.w	adpcm_n_max(pc),d0	*データが存在しない
	bcc	koa_lp
	lsl.l	#adpcm_tbl_size_,d0	*adpcm_tbl_size倍
	move.l	adpcm_tbl(pc),a1
	add.l	d0,a1
	tst.b	(a1)			*check type
	beq	koa_lp			*no data
	add.w	a4,d4
	andi.w	#$0f,d4
	lsl.w	#6,d2
	add.w	d5,d2
	add.w	p_detune(a5),d2
	bsr	pcm_key_on		*<a1=data table address,d2=pitch,d1=volume,d4=ch
	bra	koa_lp

case_mpcm_k_on:				*MCPMを使用して音量可変発音
					*TIMBRE CASE
koa_lp2:
	moveq.l	#0,d2
	move.b	(a3)+,d2
	bmi	exit_kon_ad
	moveq.l	#0,d0
	move.b	(a3)+,d0		*get velocity
	bsr	consider_fader_ad
	move.l	d0,d1
	move.w	(a3)+,d4		*ch offset
	move.l	(a3)+,d0		*timbre
	cmp.w	adpcm_n_max2(pc),d0	*データが存在しない
	bcc	koa_lp2
	lsl.l	#adpcm_tbl_size_,d0	*adpcm_tbl_size倍
	move.l	adpcm_tbl2(pc),a1
	add.l	d0,a1
	tst.b	(a1)			*check type
cmko_patch:
	beq.s	koa_lp2			*非MPCMならばbpl.sになる
	add.w	a4,d4
	andi.w	#$0f,d4			*d4=ch
	lsl.w	#6,d2
	add.w	d5,d2
	add.w	p_detune(a5),d2
	bsr	pcm_key_on		*<a1=data table address,d2=pitch,d1=volume,d4=ch
	bra	koa_lp2

proc_pitch_level_ad2:			*PROCESSING PITCH&LEVEL
	move.w	pgtjtbl_ad2(pc,d5.w),d0
	jmp	pgtjtbl_ad2(pc,d0.w)
pgtjtbl_ad2:
	dc.w	_key_on_ad-pgtjtbl_ad2
	dc.w	portonlycase_ad2-pgtjtbl_ad2
	dc.w	pmodonlycase_ad2-pgtjtbl_ad2
	dc.w	pmodportcase_ad2-pgtjtbl_ad2
	dc.w	dtnchg_case_ad2-pgtjtbl_ad2
	dc.w	portonlycase_ad2-pgtjtbl_ad2
	dc.w	pmodonlycase_ad2-pgtjtbl_ad2
	dc.w	pmodportcase_ad2-pgtjtbl_ad2
dtnchg_case_ad2:
*	moveq.l	#0,d5
*	bra	@f
portonlycase_ad2:
	move.w	p_port_pitch(a5),d5
	bra	@f
pmodonlycase_ad2:
*	move.w	p_pmod_pitch(a5),d5
*	bra	@f
pmodportcase_ad2:
	move.w	p_port_pitch(a5),d5
	add.w	p_pmod_pitch(a5),d5
@@:
	move.b	k_velo(a4),d0
	andi.w	#$7f,d0
*	bmi	key_on_ad		*最初だけ効いてる
	jsr	(a2)
	move.b	(a4),d1
	bsr	set_ad_tune
	addq.w	#1,d4
	andi.w	#$0f,d4
	addq.w	#k_note_len,a4
	dbra	d7,@b
	bra	key_on_ad

chg_pitch?_ad:				*PITCH処理?
	swap	d5
	move.w	_pgtjtbl_ad(pc,d5.w),d0
	jmp	_pgtjtbl_ad(pc,d0.w)
_pgtjtbl_ad:
	dc.w	_key_on_ad-_pgtjtbl_ad
	dc.w	_portonlycase_ad-_pgtjtbl_ad
	dc.w	_pmodonlycase_ad-_pgtjtbl_ad
	dc.w	_pmodportcase_ad-_pgtjtbl_ad
	dc.w	_dtnchg_case_ad-_pgtjtbl_ad
	dc.w	_portonlycase_ad-_pgtjtbl_ad
	dc.w	_pmodonlycase_ad-_pgtjtbl_ad
	dc.w	_pmodportcase_ad-_pgtjtbl_ad
_dtnchg_case_ad:
*	moveq.l	#0,d5
*	bra	@f
_portonlycase_ad:
	move.w	p_port_pitch(a5),d5
	bra	@f
_pmodonlycase_ad:
*	move.w	p_pmod_pitch(a5),d5
*	bra	@f
_pmodportcase_ad:
	move.w	p_port_pitch(a5),d5
	add.w	p_pmod_pitch(a5),d5
@@:
	lea	p_note(a5),a4
@@:					*PITCHコントロールONLY
	move.b	(a4),d1
	bsr	set_ad_tune
	addq.b	#1,d4
	andi.b	#$0f,d4
	addq.w	#k_note_len,a4
	dbra	d7,@b
	bra	key_on_ad

run_cmd_fm:				*コマンド解釈(FM)
	lea	p_key_on(a5),a3
	clr.b	p_port_flg(a5)
next_cmd_fm:				*ジャンプする時はd0のビット8～31はall zero
	move.l	a0,p_now_pointer(a5)
	moveq.l	#0,d7
	move.b	(a0)+,d7
	bpl	case_key_fm		*音階データ
	add.b	d7,d7			*わざと.bにして最上位ビットを殺す
	add.w	d7,d7
	move.l	int_cmd_tbl_fm(pc,d7.w),a1
	jmp	(a1)

int_cmd_tbl_fm:						*コマンド群
	zmd_j_tbl	fm

run_cmd_ad:				*コマンド解釈(mpcm.X)
	lea	p_key_on(a5),a3
	clr.b	p_port_flg(a5)
next_cmd_ad:				*ジャンプする時はd0のビット8～31はall zero
	move.l	a0,p_now_pointer(a5)
	moveq.l	#0,d7
	move.b	(a0)+,d7
	bpl	case_key_ad		*音階データ
	add.b	d7,d7			*わざと.bにして最上位ビットを殺す
	add.w	d7,d7
	move.l	int_cmd_tbl_ad(pc,d7.w),a1
	jmp	(a1)

int_cmd_tbl_ad:						*コマンド群
	zmd_j_tbl	ad

run_cmd_md:				*コマンド解釈(MIDI)
	lea	p_key_on(a5),a3
	clr.b	p_port_flg(a5)
next_cmd_md:				*ジャンプする時はd0のビット8～31はall zero
	move.l	a0,p_now_pointer(a5)
	moveq.l	#0,d7
	move.b	(a0)+,d7
	bpl	case_key_md		*音階データ
	add.b	d7,d7			*わざと.bにして最上位ビットを殺す
	add.w	d7,d7
	move.l	int_cmd_tbl_md(pc,d7.w),a1
	jmp	(a1)

int_cmd_tbl_md:						*コマンド群
	zmd_j_tbl	md

dummy_instructios:
frq_chg_fm:			*FM ADPCM周波数設定
bend_range_fm:			*FM ベンドレンジ設定
tie_mode_fm:			*FM TIEモード設定
pmod_mode_fm:			*FM PMODモード設定
pcm_mode_fm:
	addq.w	#1,a0
	bra	next_cmd_fm

bend_range_ad:			*ADPCM ベンドレンジ設定
tie_mode_ad:			*ADPCM TIEモード設定
pmod_mode_ad:			*ADPCM PMODモード設定
slot_mask_ad:			*ADPCM スロットマスクの切り換え
	addq.w	#1,a0
	bra	next_cmd_ad

frq_chg_md:			*MIDI ADPCM周波数設定
slot_mask_md:			*MIDI スロットマスクの切り換え
pcm_mode_md:
voice_reserve_md:			*MIDI 発音数予約
	addq.w	#1,a0
	bra	next_cmd_md

arcc_mode_fm:			*FM ARCCモード設定
	addq.w	#2,a0
	bra	next_cmd_fm

arcc_mode_ad:			*ADPCM ARCCモード設定
	addq.w	#2,a0
	bra	next_cmd_ad

NRPN_fm:			*NRPN
	addq.w	#4,a0
	bra	next_cmd_fm

NRPN_ad:			*NRPN
	addq.w	#4,a0
	bra	next_cmd_ad

exclusive_fm:				*Exclusive
	addq.w	#1,a0			*skip maker ID
midi_transmission_fm:			*生データ送信
	moveq.l	#0,d0
	move.b	(a0)+,d0		*skip comment
	add.w	d0,a0
	move.b	(a0)+,-(sp)
	move.w	(sp)+,d0
	move.b	(a0)+,d0
	swap	d0
	move.b	(a0)+,-(sp)
	move.w	(sp)+,d0
	move.b	(a0)+,d0
	add.l	d0,a0
	bra	next_cmd_fm

exclusive_ad:				*Exclusive
	addq.w	#1,a0			*skip maker ID
midi_transmission_ad:			*生データ送信
	moveq.l	#0,d0
	move.b	(a0)+,d0		*skip comment
	add.w	d0,a0
	move.b	(a0)+,-(sp)
	move.w	(sp)+,d0
	move.b	(a0)+,d0
	swap	d0
	move.b	(a0)+,-(sp)
	move.w	(sp)+,d0
	move.b	(a0)+,d0
	add.l	d0,a0
	bra	next_cmd_ad

ID_set_fm:			*ID SET
	addq.w	#3,a0
	bra	next_cmd_fm

rltv_opm_regset_ad:		*相対OPM reg書き込み
opm_regset_ad:			*OPM reg書き込み
ID_set_ad:			*ID SET
	addq.w	#3,a0
	bra	next_cmd_ad

rltv_opm_regset_md:		*相対OPM reg書き込み
opm_regset_md:			*OPM reg書き込み
	addq.w	#3,a0
	bra	next_cmd_md

effect_ctrl_ad:			*ADPCM エフェクトコントロール
	move.b	(a0)+,d2
	bsr	skip_by_d2
	bra	next_cmd_ad

effect_ctrl_fm:			*FM エフェクトコントロール
	move.b	(a0)+,d2
	pea	next_cmd_fm(pc)

skip_by_d2:
	* < d2.b=omt.bit
sbdlp:
	lsr.b	#1,d2
	bcc	@f
	addq.w	#1,a0
@@:
	tst.b	d2
	bne	sbdlp
	rts
*------------------------------------------------------------------------------
play_end_md:
	lea	p_note(a5),a1		*完全に音が消えたかをチェック
@@:
	move.l	(a1)+,d0
	bmi	1f
	tst.w	d0
	ble	@b
quit_pled:
	addq.w	#1,(a5)
	subq.w	#1,a0			*play_endはなかったことにして演奏処理継続
	rts
1:
	bsr	do_kill_note_md
	bra	do_play_end

play_end_ad:
	move.w	p_how_many(a5),d0
	bmi	do_play_end
	lea	p_note(a5),a1		*完全に音が消えたかをチェック
1:
	move.l	(a1)+,d1		*k_noteのd7
	bmi	@f
	btst.l	#23,d1			*k_veloのd7
	bne	@f			*case:gate=0
	tst.w	d1
	bgt	quit_pled
@@:
	dbra	d0,1b
	bsr	do_kill_note_ad
	bra	do_play_end

play_end_fm:
	move.w	p_how_many(a5),d0
	bmi	do_play_end
	lea	p_note(a5),a1		*完全に音が消えたかをチェック
1:
	move.l	(a1)+,d1		*k_noteのd7
	bmi	@f
	btst.l	#23,d1			*k_veloのd7
	bne	@f			*case:gate=0
	tst.w	d1
	bgt	quit_pled
@@:
	dbra	d0,1b
	bsr	do_kill_note_fm

do_play_end:
	move.l	jump_flg3(pc),d0	*[jump]中だったか
	beq	@f
	bsr	next_jump3_mode_2	*強制的に次フェーズへ
@@:
	move.l	jump_flg2(pc),d0	*[@]中だったか
	beq	@f
	bsr	next_jump2_mode		*強制的に次フェーズへ
@@:
	btst.b	#2,p_seq_flag(a5)	*[!]中だったか
	beq	1f
	bsr	end_jump1_mode		*[!]パッチをもとに戻す
1:
	ori.b	#ID_END,p_track_stat(a5)	*end mark
	btst.b	#_ID_SE,p_track_stat(a5)
	beq	@f
	move.l	d4,d0				*効果音モードの演奏終了処理
	swap	d0
	tst.w	d0
	bne	@f
	bclr.b	d4,mask_opm_ch-work(a6)
	beq	@f				*マスクされていなかった
	bsr	restore_opm			*効果音トラック終了時の処理
	bra	exit_pled
@@:
	move.l	obtevtjtbl-work+ed_jump(a6),d1	*全トラック演奏終了ジャンプ?
	beq	@f
	tst.w	obtevtjtbl-work+lp_loop(a6)	*ループ回数指定によるジャンプ?
	beq	chk_all_end1
	bra	chk_all_end0
@@:
	tst.w	obtevtjtbl-work+lp_loop(a6)	*ループ回数指定によるジャンプ?
	beq	exit_pled
	addq.w	#1,obtevtjtbl-work+lp_work(a6)	*一応ループ回数に達したとみなす
exit_pled:
	rts

chk_all_end0:
	addq.w	#1,obtevtjtbl-work+lp_work(a6)	*一応ループ回数に達したとみなす
chk_all_end1:
	move.l	play_trk_tbl(pc),a1
	move.l	seq_wk_tbl(pc),a2
@@:
	moveq.l	#0,d0
	move.w	(a1)+,d0
	bmi	@f
	swap	d0
	lsr.l	#16-trwk_size_,d0
	tst.b	p_track_stat(a2,d0.w)		*1トラックも演奏していなかったら
	bne	@b				*all end event発生
	rts					*演奏中のトラックが1つでもある
@@:						*全トラックが演奏終了した
	clr.l	obtevtjtbl-work+ed_jump(a6)	*一回機能したら初期化
	move.l	d1,a1
	jmp	(a1)
*------------------------------------------------------------------------------
do_agogik:
	lea	tempo_value(pc),a1
	moveq.l	#0,d2
	move.w	(a1),d2
	move.w	p_pmod_pitch(a5),d0
	moveq.l	#0,d1
	ext.l	d0
	bpl	@f
	move.w	t_min(pc),d1
	add.l	d0,d2
	cmp.l	d1,d2
	bge	2f
	bra	1f
@@:
	move.w	t_max(pc),d1
	add.l	d0,d2
	cmp.l	d1,d2
	ble	2f
1:
	move.w	d1,d2
2:
	cmp.w	p_pitch_last(a5),d2
	beq	exit_agogik
	move.w	d2,p_pitch_last(a5)
agogik_calctm:				*使用タイマによってパッチが当たる
	bsr.w	do_calc_tmm		*タイマ値計算(< d2.w=tempo)
	bmi	exit_agogik		* > d1.w=timer m value
	bsr	wrt_tmp			* < d1.w=timer
exit_agogik:
	rts

do_agogik_se:
	lea	tempo_value_se(pc),a1
	moveq.l	#0,d2
	move.w	(a1),d2
	move.w	p_pmod_pitch(a5),d0
	moveq.l	#0,d1
	ext.l	d0
	bpl	@f
	move.w	t_min_se(pc),d1
	add.l	d0,d2
	cmp.l	d1,d2
	bge	2f
	bra	1f
@@:
	move.w	t_max_se(pc),d1
	add.l	d0,d2
	cmp.l	d1,d2
	ble	2f
1:
	move.w	d1,d2
2:
	cmp.w	p_pitch_last(a5),d2
	beq	exit_agogik_se
	move.w	d2,p_pitch_last(a5)
agogik_calctm_se:			*使用タイマによってパッチが当たる
	bsr.w	do_calc_tmb		*タイマ値計算(< d2.w=tempo)
	bmi	exit_agogik_se
	bsr	_wrt_tmp		*実行
exit_agogik_se:
	rts
*------------------------------------------------------------------------------
tempo_@t_ad:			*ADPCM テンポ(@T指定)
	bsr	get_tempo_@t
	bra	next_cmd_ad

tempo_@t_md:			*MIDI テンポ(@T指定)
	bsr	get_tempo_@t
	bra	next_cmd_md

tempo_@t_fm:			*FM テンポ(@T指定)
	pea	next_cmd_fm(pc)

get_tempo_@t:			*＠Ｔコマンドパラメータ取りだし
	btst.b	#_ID_SE,p_track_stat(a5)
	bne	_get_tempo_@t
	lea	timer_value(pc),a1
	move.b	(a0)+,(a1)+
	move.b	(a0)+,(a1)+
tcg0:				*タイマーモードによってパッチが当たる
	bsr.s	gyakusan_tm_m	* > d1.w=timer
wrt_tmp:			*タイマーモードによってパッチが当たる
	bsr.w	set_timer_m	* < d1.w=timer
_@t_midi_clk:			*-eスイッチがないと'rts'になる	*nmdb!!
	jmp	midi_clk

_get_tempo_@t:
	lea	timer_value_se(pc),a1
	move.b	(a0)+,(a1)+
	move.b	(a0)+,(a1)+
_tcg0:				*タイマーモードによってパッチが当たる
	bsr.s	gyakusan_tm_b	* > d1.w=timer
_wrt_tmp:			*タイマーモードによってパッチが当たる
	bra.w	set_timer_b	* < d1.w=timer

_gyakusan_tm_b:
	moveq.l	#0,d1
	move.w	mst_clk_se(pc),d1
	bra	@f
gyakusan_tm_b:
	* < a1.l=timer_value+2
	* > d0.w=tempo value
	* > d1.w=timer value
	moveq.l	#0,d1
	move.w	mst_clk(pc),d1
@@:
	move.l	#(16*4000*60000)>>8,d0
	jsr	wari-work(a6)	*d0=d0/d1
				*d0=16*4000*60000/(1024*(mst_clk/4))
	move.w	#256,d2
	move.w	-(a1),d1	*get timer
	sub.w	d1,d2
	lsl.w	#4,d2

	divu	d2,d0
	swap	d0
	tst.w	d0		*余りがあるか
	beq	@f
	add.l	#$0001_0000,d0	*余りがあるなら切り上げ
@@:
	swap	d0		*d0.w=answer
	move.w	d0,-(a1)	*set tempo
	rts

_gyakusan_tm_a:
	moveq.l	#0,d1
	move.w	mst_clk_se(pc),d1
	bra	@f
gyakusan_tm_a:
	* < a1.l=timer_value+2
	* > d0.w=tempo value
	* > d1.w=timer value
	moveq.l	#0,d1
	move.w	mst_clk(pc),d1
@@:
	move.l	#(16*4000*60000)>>8,d0
	jsr	wari-work(a6)	*d0=d0/d1
				*d0=16*4000*60000/(1024*(mst_clk/4))
	move.w	#1024,d2
	move.w	-(a1),d1	*get timer
	sub.w	d1,d2
	divu	d2,d0
	move.w	d0,-(a1)	*set tempo
	rts

_gyakusan_tm_m:
	move.w	mst_clk_se(pc),d1
	bra	@f
gyakusan_tm_m:
	* < a1.l=timer_value+2
	* > d0.w=tempo value
	* > d1.w=timer value
	move.w	mst_clk(pc),d1
@@:
	move.l	#30*1000*1000,d0
	move.w	-(a1),d2	*get timer
	mulu	d2,d1
	jsr	wari-work(a6)	*d0/d1=d0...d1
	move.w	d0,-(a1)	*set tempo
	move.l	d2,d1		*d1.w=timer
	rts

rltv_@t_md:			*FM 相対テンポ＠Ｔ
	bsr	get_rltv_@t
	bra	next_cmd_md

rltv_@t_ad:			*FM 相対テンポ＠Ｔ
	bsr	get_rltv_@t
	bra	next_cmd_ad

rltv_@t_fm:			*FM 相対テンポ＠Ｔ
	pea	next_cmd_fm(pc)

get_rltv_@t:			*相対テンポ取りだし
	btst.b	#_ID_SE,p_track_stat(a5)
	bne	_get_rltv_@t
	lea	timer_value(pc),a1
	moveq.l	#0,d1
	move.w	(a1),d1
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0
	move.w	_@t_max(pc),d2	*$3ff=tm_a, $ff=tm_b, $3fff=tm_m
	add.w	d0,d1
	bpl	@f
	tst.w	d0
	bmi	r@t_minus_case
@@:
	cmp.w	d2,d1		*上限チェック
	bls	@f
	move.w	d2,d1		*上限設定
@@:
	move.w	d1,(a1)+
	bra	tcg0

r@t_minus_case:
	moveq.l	#0,d1		*最低値設定
	bra	@b

_get_rltv_@t:			*相対テンポ取りだし(効果音実行時)
	lea	timer_value_se(pc),a1
	moveq.l	#0,d1
	move.w	(a1),d1
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0
	move.w	_@t_max_se(pc),d2	*$3ff=tm_a, $ff=tm_b, $3fff=tm_m
	add.w	d0,d1
	bpl	@f
	tst.w	d0
	bmi	_r@t_minus_case
	cmp.w	d2,d1		*上限チェック
	bls	@f
	move.w	d2,d1		*上限設定
@@:
	move.w	d1,(a1)+
	bra	_tcg0

_r@t_minus_case:
	moveq.l	#0,d1		*最低値設定
	bra	@b
*------------------------------------------------------------------------------
tempo_t_ad:				*ADPCM テンポ(Ｔ指定)
	bsr	get_tempo_t
	bra	next_cmd_ad

tempo_t_md:				*MIDI テンポ(Ｔ指定)
	bsr	get_tempo_t
	bra	next_cmd_md

tempo_t_fm:				*FM テンポ(Ｔ指定)
	pea	next_cmd_fm(pc)

get_tempo_t:				*音楽的テンポ取りだし
	btst.b	#_ID_SE,p_track_stat(a5)
	bne	_get_tempo_t
	lea	tempo_value(pc),a1
	move.b	(a0)+,d2
	lsl.w	#8,d2
	move.b	(a0)+,d2
smf_tempo:				*SMFのテンポ設定の場合ここに来る
	* < a1.l=tempo_value
	* < d2.w=tempo
	tempo_range	d2
	move.w	d2,(a1)+
go_calctm:				*タイマーモードによってパッチが当たる
	bsr.w	do_calc_tmm		*タイマ値計算(< d2.w=tempo)
	bmi	@f
	move.w	d1,(a1)			*設定
	bra	wrt_tmp			*実行
@@:
	rts

_get_tempo_t:				*音楽的テンポ取りだし(効果音実行時)
	lea	tempo_value_se(pc),a1
	move.b	(a0)+,d2
	lsl.w	#8,d2
	move.b	(a0)+,d2
	tempo_range	d2,_se
	move.w	d2,(a1)+
_go_calctm:					*タイマーモードによってパッチが当たる
	bsr.w	do_calc_tmb			*タイマ値計算(< d2.w=tempo)
	bmi	@f
	move.w	d1,(a1)				*設定
	bra	_wrt_tmp			*実行
@@:
	rts

rltv_t_ad:
	bsr	get_rltv_t
	bra	next_cmd_ad

rltv_t_md:
	bsr	get_rltv_t
	bra	next_cmd_md

rltv_t_fm:
	pea	next_cmd_fm(pc)

get_rltv_t:				*相対テンポ取りだし
	btst.b	#_ID_SE,p_track_stat(a5)
	bne	_get_rltv_t
	lea	tempo_value(pc),a1
	move.w	(a1),d2
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0
	tst.w	d0
	bpl	@f
	move.w	t_min(pc),d1		*最低値
	add.w	d0,d2
	cmp.w	d1,d2
	bcc	2f
	bra	1f
@@:
	move.w	t_max(pc),d1		*最大値
	add.w	d0,d2
	cmp.w	d1,d2
	bls	2f
1:
	move.w	d1,d2
2:
	move.w	d2,(a1)+
	bra	go_calctm

_get_rltv_t:				*相対テンポ取りだし(効果音実行時)
	lea	tempo_value_se(pc),a1
	move.w	(a1),d2
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0
	tst.w	d0
	bpl	@f
	move.w	t_min_se(pc),d2		*最低値
	add.w	d0,d2
	cmp.w	d1,d2
	bcc	2f
	bra	1f
@@:
	move.w	t_max_se(pc),d1		*最大値
	add.w	d0,d2
	cmp.w	d1,d2
	bls	2f
1:
	move.w	d1,d2
2:
	move.w	d2,(a1)+
	bra	_go_calctm
*------------------------------------------------------------------------------
set_timer_b:			*タイマーBの初期化(init_timer_bとほぼ同じ)
	* < d1.w=timer value
	move.l	d1,d2		*get timer value
	moveq.l	#$12,d1
*	move.l	p_opmset(a5),a4	*!
*	jmp	(a4)		*!opmset
	bra	opmset

set_timer_a:			*タイマーAの初期化(init_timer_aとほぼ同じ)
	* < d1.w=timer value
	move.l	d1,d2
	moveq.l	#$11,d1
*	move.l	p_opmset(a5),a4	*!
*	jsr	(a4)		*!opmset(set value L)
	bsr	opmset
	lsr.w	#2,d2
	moveq.l	#$10,d1
*	jmp	(a4)		*!opmset(set value H)
	bra	opmset

set_timer_m:			*MIDIタイマーの初期化(init_timer_mとほぼ同じ)
	* < d1.w=timer value
	ori.w	#$8000,d1
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	lea	rgr,a4
	move.b	#$8,(a4)	*rgr
	midiwait
	move.b	d1,grp4-rgr(a4)
	midiwait
	ror.w	#8,d1
	move.b	d1,grp5-rgr(a4)
	midiwait
	move.w	(sp)+,sr
	rts
*------------------------------------------------------------------------------
opm_regset_fm:
	move.l	p_opmset(a5),a4
	move.b	(a0)+,d1		*reg ID
	bmi	not_op_reg
	move.b	d1,d0
	andi.w	#$f0,d1
	lsr.b	#1,d1
	add.b	d4,d1
	andi.w	#$0f,d0
	add.w	d0,d0
	move.w	opmregope(pc,d0.w),d0
	jmp	opmregope(pc,d0.w)
opmregope:
	dc.w	regope_MUL-opmregope		*0
	dc.w	regope_DT1-opmregope		*1
	dc.w	regope_TL-opmregope		*2
	dc.w	regope_AR-opmregope		*3
	dc.w	regope_KS-opmregope		*4
	dc.w	regope_1DR-opmregope		*5
	dc.w	regope_AMS_EN-opmregope		*6
	dc.w	regope_2DR-opmregope		*7
	dc.w	regope_DT2-opmregope		*8
	dc.w	regope_RR-opmregope		*9
	dc.w	regope_1DL-opmregope		*10

regope_MUL:
	add.b	#$40,d1
	move.b	opmreg(a6,d1.w),d2
	andi.w	#$f0,d2
	or.b	(a0)+,d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm

regope_DT1:
	add.b	#$40,d1
	move.b	opmreg(a6,d1.w),d2
	andi.w	#$0f,d2
	move.b	(a0)+,d0
	lsl.b	#4,d0
	or.b	d0,d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm

regope_TL:
	add.b	#$60,d1
	move.b	(a0)+,d2
	jsr	(a4)			*opmset
	pea	next_cmd_fm(pc)
set_to_olwk:
	* < d1=$60-$7f
	* < d2=0-127
*	sub.b	#$60,d1			*$00-$1f
*	move.b	@f(pc,d1.w),d1
*	move.b	d2,ol1-work(a6,d1.w)
	rts
*@@:
*	dc.b	 0, 1, 2, 3, 4, 5, 6, 7	*$60-$67
*	dc.b	16,17,18,19,20,21,22,23
*	dc.b	 8, 9,10,11,12,13,14,15
*	dc.b	24,25,26,27,28,29,30,31

regope_AR:
	add.b	#$80,d1
	move.b	opmreg(a6,d1.w),d2
	andi.w	#$c0,d2
	or.b	(a0)+,d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm

regope_KS:
	add.b	#$80,d1
	move.b	opmreg(a6,d1.w),d2
	andi.w	#$1f,d2
	move.b	(a0)+,d0
	ror.b	#2,d0
	or.b	d0,d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm

regope_1DR:
	add.b	#$a0,d1
	move.b	opmreg(a6,d1.w),d2
	andi.w	#$c0,d2
	or.b	(a0)+,d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm

regope_AMS_EN:
	add.b	#$a0,d1
	move.b	opmreg(a6,d1.w),d2
	andi.w	#$1f,d2
	move.b	(a0)+,d0
	ror.b	#1,d0
	or.b	d0,d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm

regope_2DR:
	add.b	#$c0,d1
	move.b	opmreg(a6,d1.w),d2
	andi.w	#$c0,d2
	or.b	(a0)+,d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm

regope_DT2:
	add.b	#$c0,d1
	move.b	opmreg(a6,d1.w),d2
	andi.w	#$1f,d2
	move.b	(a0)+,d0
	ror.b	#2,d0
	or.b	d0,d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm

regope_RR:
	add.b	#$e0,d1
	move.b	opmreg(a6,d1.w),d2
	andi.w	#$f0,d2
	or.b	(a0)+,d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm

regope_1DL:
	add.b	#$e0,d1
	move.b	opmreg(a6,d1.w),d2
	andi.w	#$0f,d2
	move.b	(a0)+,d0
	lsl.b	#4,d0
	or.b	d0,d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm

not_op_reg:
	andi.w	#$7f,d1
	subq.w	#4,d1
	add.w	d1,d1
	move.w	opmregope2(pc,d1.w),d0
	jmp	opmregope2(pc,d0.w)

opmregope2:
	dc.w	regope_NFRQ-opmregope2		*4
	dc.w	regope_NE-opmregope2		*5
	dc.w	regope_LFRQ-opmregope2		*6
	dc.w	regope_PMD-opmregope2		*7
	dc.w	regope_AMD-opmregope2		*8
	dc.w	regope_WF-opmregope2		*9
	dc.w	regope_CON-opmregope2		*10
	dc.w	regope_FB-opmregope2		*11
	dc.w	regope_PAN-opmregope2		*12
	dc.w	regope_AMS-opmregope2		*13
	dc.w	regope_PMS-opmregope2		*14

regope_NFRQ:
	moveq.l	#15,d1			*noise frq
	move.b	opmreg(a6,d1.w),d2
	andi.w	#$80,d2
	or.b	(a0)+,d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm

regope_NE:
	moveq.l	#15,d1			*noise switch
	move.b	opmreg(a6,d1.w),d2
	andi.w	#$1f,d2
	move.b	(a0)+,d0
	ror.b	#1,d0
	or.b	d0,d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm

regope_LFRQ:
	moveq.l	#$18,d1			*LFRQ
	move.b	(a0)+,d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm

regope_PMD:
	moveq.l	#$19,d1			*PMD
	move.b	(a0)+,d2
	tas.b	d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm

regope_AMD:
	moveq.l	#$19,d1			*AMD
	move.b	(a0)+,d2
	andi.b	#$7f,d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm

regope_WF:
	moveq.l	#$1b,d1			*WF
	move.b	opmreg(a6,d1.w),d2
	andi.b	#$fc,d2
	move.b	(a0)+,d0
	andi.b	#3,d0
	or.b	d0,d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm

regope_CON:
	moveq.l	#$20,d1
	add.b	d4,d1
	move.b	opmreg(a6,d1.w),d2
	andi.w	#$f8,d2
	or.b	(a0)+,d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm

regope_FB:
	moveq.l	#$20,d1
	add.b	d4,d1
	move.b	opmreg(a6,d1.w),d2
	andi.w	#$c7,d2
	move.b	(a0)+,d0
	lsl.b	#3,d0
	or.b	d0,d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm

regope_PAN:
	moveq.l	#$20,d1
	add.b	d4,d1
	move.b	opmreg(a6,d1.w),d2
	andi.w	#$3f,d2
	move	(a0)+,d0
	ror.b	#2,d0
	or.b	d0,d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm

regope_AMS:
	moveq.l	#$38,d1
	add.b	d4,d1
	move.b	opmreg(a6,d1.w),d2
	andi.w	#$f0,d2
	or.b	(a0)+,d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm

regope_PMS:
	moveq.l	#$38,d1
	add.b	d4,d1
	move.b	opmreg(a6,d1.w),d2
	andi.w	#$0f,d2
	move.b	(a0)+,d0
	lsl.b	#4,d0
	or.b	d0,d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm
*-----------------------------------------------------------------------------
rltv_opm_regset_fm:
	move.l	p_opmset(a5),a4
	move.b	(a0)+,d1		*reg ID
	bmi	r_not_op_reg
	move.b	d1,d0
	andi.w	#$f0,d1
	lsr.b	#1,d1
	add.b	d4,d1
	andi.w	#$0f,d0
	add.w	d0,d0
	move.w	r_opmregope(pc,d0.w),d0
	jmp	r_opmregope(pc,d0.w)
r_opmregope:
	dc.w	r_regope_MUL-r_opmregope	*0
	dc.w	r_regope_DT1-r_opmregope	*1
	dc.w	r_regope_TL-r_opmregope		*2
	dc.w	r_regope_AR-r_opmregope		*3
	dc.w	r_regope_KS-r_opmregope		*4
	dc.w	r_regope_1DR-r_opmregope	*5
	dc.w	r_regope_AMS_EN-r_opmregope	*6
	dc.w	r_regope_2DR-r_opmregope	*7
	dc.w	r_regope_DT2-r_opmregope	*8
	dc.w	r_regope_RR-r_opmregope		*9
	dc.w	r_regope_1DL-r_opmregope	*10

r_regope_MUL:
	add.b	#$40,d1
	move.b	opmreg(a6,d1.w),d2
	move.l	d2,d3
	andi.w	#$0f,d3
	move.b	(a0)+,d0
	bmi	rrM1
	add.b	d0,d3
	cmpi.b	#15,d3
	bls	@f
	moveq.l	#15,d3
	bra	@f
rrM1:
	add.b	d0,d3
	bpl	@f
	moveq.l	#0,d3
@@:
	andi.w	#$f0,d2
	or.b	d3,d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm

r_regope_DT1:
	add.b	#$40,d1
	move.b	opmreg(a6,d1.w),d2
	move.l	d2,d3
	lsr.b	#4,d3
	andi.b	#7,d3
	move.b	(a0)+,d0
	bmi	rrD1
	add.b	d0,d3
	cmpi.b	#7,d3
	bls	@f
	moveq.l	#7,d3
	bra	@f
rrD1:
	add.b	d0,d3
	bpl	@f
	moveq.l	#0,d3
@@:
	andi.w	#$0f,d2
	lsl.b	#4,d3
	or.b	d3,d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm

r_regope_TL:
	add.b	#$60,d1
	move.b	opmreg(a6,d1.w),d2
	andi.b	#$7f,d2
	move.b	(a0)+,d0
	bmi	rrT1
	add.b	d0,d2
	cmpi.b	#127,d2
	bls	@f
	moveq.l	#127,d2
	bra	@f
rrT1:
	add.b	d0,d2
	bpl	@f
	moveq.l	#0,d2
@@:
	jsr	(a4)			*opmset
	bsr	set_to_olwk
	bra	next_cmd_fm

r_regope_AR:
	add.b	#$80,d1
	move.b	opmreg(a6,d1.w),d2
	move.l	d2,d3
	andi.w	#$1f,d3
	move.b	(a0)+,d0
	bmi	rrA1
	add.b	d0,d3
	cmpi.b	#$1f,d3
	bls	@f
	moveq.l	#$1f,d3
	bra	@f
rrA1:
	add.b	d0,d3
	bpl	@f
	moveq.l	#0,d3
@@:
	andi.w	#$c0,d2
	or.b	d3,d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm

r_regope_KS:
	add.b	#$80,d1
	move.b	opmreg(a6,d1.w),d2
	move.l	d2,d3
	rol.b	#2,d3
	andi.w	#3,d3
	move.b	(a0)+,d0
	bmi	rrK1
	add.b	d0,d3
	cmpi.b	#3,d3
	bls	@f
	moveq.l	#3,d3
	bra	@f
rrK1:
	add.b	d0,d3
	bpl	@f
	moveq.l	#0,d3
@@:
	ror.b	#2,d3
	or.b	d3,d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm

r_regope_1DR:
	add.b	#$a0,d1
	move.b	opmreg(a6,d1.w),d2
	move.l	d2,d3
	andi.w	#$1f,d3
	move.b	(a0)+,d0
	bmi	rr1DR
	add.b	d0,d3
	cmpi.b	#$1f,d3
	bls	@f
	moveq.l	#$1f,d3
	bra	@f
rr1DR:
	add.b	d0,d3
	bpl	@f
	moveq.l	#0,d3
@@:
	andi.w	#$c0,d2
	or.b	d3,d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm

r_regope_AMS_EN:
	add.b	#$a0,d1
	move.b	opmreg(a6,d1.w),d2
	move.l	d2,d3
	rol.b	#1,d3
	andi.w	#1,d3
	move.b	(a0)+,d0
	bmi	rrAE
	add.b	d0,d3
	cmpi.b	#1,d3
	bls	@f
	moveq.l	#1,d3
	bra	@f
rrAE:
	add.b	d0,d3
	bpl	@f
	moveq.l	#0,d3
@@:
	andi.w	#$1f,d2
	ror.b	#1,d3
	or.b	d3,d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm

r_regope_2DR:
	add.b	#$c0,d1
	move.b	opmreg(a6,d1.w),d2
	move.l	d2,d3
	andi.w	#$1f,d3
	move.b	(a0)+,d0
	bmi	rr2D
	add.b	d0,d3
	cmpi.b	#$1f,d3
	bls	@f
	moveq.l	#$1f,d3
	bra	@f
rr2D:
	add.b	d0,d3
	bpl	@f
	moveq.l	#0,d3
@@:
	andi.w	#$c0,d2
	or.b	d3,d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm

r_regope_DT2:
	add.b	#$c0,d1
	move.b	opmreg(a6,d1.w),d2
	move.b	d2,d3
	rol.b	#2,d3
	andi.w	#3,d2
	move.b	(a0)+,d0
	bmi	rrD2
	add.b	d0,d3
	cmpi.b	#3,d3
	bls	@f
	moveq.l	#3,d3
	bra	@f
rrD2:
	add.b	d0,d3
	bpl	@f
	moveq.l	#0,d3
@@:
	ror.b	#2,d3
	or.b	d3,d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm

r_regope_RR:
	add.b	#$e0,d1
	move.b	opmreg(a6,d1.w),d2
	move.l	d2,d3
	andi.w	#$1f,d3
	move.b	(a0)+,d0
	bmi	rrR1
	add.b	d0,d3
	cmpi.b	#$0f,d3
	bls	@f
	moveq.l	#$0f,d3
	bra	@f
rrR1:
	andi.w	#$f0,d2
	or.b	d3,d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm

r_regope_1DL:
	add.b	#$e0,d1
	move.b	opmreg(a6,d1.w),d2
	move.l	d2,d3
	lsr.b	#4,d3
	move.b	(a0)+,d0
	bmi	rr1DL
	add.b	d0,d3
	cmpi.b	#$0f,d3
	bls	@f
	moveq.l	#$0f,d3
	bra	@f
rr1DL:
	andi.w	#$0f,d2
	lsl.b	#4,d3
	or.b	d3,d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm

r_not_op_reg:
	andi.w	#$7f,d1
	subq.w	#4,d1
	add.w	d1,d1
	move.w	r_opmregope2(pc,d0.w),d0
	jmp	r_opmregope2(pc,d0.w)

r_opmregope2:
	dc.w	r_regope_NFRQ-r_opmregope2		*4
	dc.w	r_regope_NE-r_opmregope2		*5
	dc.w	r_regope_LFRQ-r_opmregope2		*6
	dc.w	r_regope_PMD-r_opmregope2		*7
	dc.w	r_regope_AMD-r_opmregope2		*8
	dc.w	r_regope_WF-r_opmregope2		*9
	dc.w	r_regope_CON-r_opmregope2		*10
	dc.w	r_regope_FB-r_opmregope2		*11
	dc.w	r_regope_PAN-r_opmregope2		*12
	dc.w	r_regope_AMS-r_opmregope2		*13
	dc.w	r_regope_PMS-r_opmregope2		*14

r_regope_NFRQ:
	moveq.l	#15,d1			*noise frq
	move.b	opmreg(a6,d1.w),d2
	move.l	d2,d3
	andi.w	#$1f,d3
	move.b	(a0)+,d0
	bmi	rrNF
	add.b	d0,d3
	cmpi.b	#$1f,d3
	bls	@f
	moveq.l	#$1f,d3
	bra	@f
rrNF:
	add.b	d0,d3
	bpl	@f
	moveq.l	#0,d3
@@:
	andi.w	#$80,d2
	or.b	d3,d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm

r_regope_NE:
	moveq.l	#15,d1			*noise switch
	move.b	opmreg(a6,d1.w),d2
	move.l	d2,d3
	andi.w	#$80,d3
	rol.b	#1,d3
	move.b	(a0)+,d0
	bmi	rrNE
	add.b	d0,d3
	cmpi.b	#1,d3
	bls	@f
	moveq.l	#1,d3
	bra	@f
rrNE:
	add.b	d0,d3
	bpl	@f
	moveq.l	#0,d3
@@:
	andi.w	#$1f,d2
	ror.b	#1,d3
	or.b	d3,d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm

r_regope_LFRQ:
	moveq.l	#$18,d1			*LFRQ
	moveq.l	#0,d2
	move.b	opmreg(a6,d1.w),d2
	move.b	(a0)+,d0
	ext.w	d0
	bmi	rrLF
	add.w	d0,d2
	cmpi.w	#255,d2
	bls	@f
	moveq.l	#255,d2
	bra	@f
rrLF:
	add.w	d0,d2
	bpl	@f
	moveq.l	#0,d2
@@:
	jsr	(a4)			*opmset
	bra	next_cmd_fm

r_regope_PMD:
	moveq.l	#$19,d1			*PMD
	move.b	opmreg(a6,d1.w),d2
	andi.w	#$7f,d2
	move.b	(a0)+,d0
	bmi	rrPMD
	add.b	d0,d2
	cmpi.b	#127,d2
	bls	@f
	moveq.l	#127,d2
	bra	@f
rrPMD:
	add.b	d0,d2
	bpl	@f
	moveq.l	#0,d2
@@:
	tas.b	d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm

r_regope_AMD:
	moveq.l	#$19,d1			*AMD
	move.b	opmreg(a6,d1.w),d2
	andi.w	#$7f,d2
	move.b	(a0)+,d0
	bmi	rrAMD
	add.b	d0,d2
	cmpi.b	#127,d2
	bls	@f
	moveq.l	#127,d2
	bra	@f
rrAMD:
	add.b	d0,d2
	bpl	@f
	moveq.l	#0,d2
@@:
	jsr	(a4)			*opmset
	bra	next_cmd_fm

r_regope_WF:
	moveq.l	#$1b,d1			*WF
	move.b	opmreg(a6,d1.w),d2
	move.l	d2,d3
	andi.w	#3,d3
	move.b	(a0)+,d0
	bmi	rrWF
	add.b	d0,d3
	cmpi.b	#3,d3
	bls	@f
	moveq.l	#3,d3
	bra	@f
rrWF:
	add.b	d0,d3
	bpl	@f
	moveq.l	#0,d3
@@:
	andi.b	#$fc,d2
	or.b	d3,d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm

r_regope_CON:
	moveq.l	#$20,d1
	add.b	d4,d1
	move.b	opmreg(a6,d1.w),d2
	move.l	d2,d3
	andi.w	#7,d3
	move.b	(a0)+,d0
	bmi	rrCON
	add.b	d0,d3
	cmpi.b	#7,d3
	bls	@f
	moveq.l	#7,d3
	bra	@f
rrCON:
	add.b	d0,d3
	bpl	@f
	moveq.l	#0,d3
@@:
	andi.w	#$f8,d2
	or.b	d3,d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm

r_regope_FB:
	moveq.l	#$20,d1
	add.b	d4,d1
	move.b	opmreg(a6,d1.w),d2
	move.l	d2,d3
	lsr.b	#3,d3
	andi.w	#7,d3
	move.b	(a0)+,d0
	bmi	rrFB
	add.b	d0,d3
	cmpi.b	#7,d3
	bls	@f
	moveq.l	#7,d3
	bra	@f
rrFB:
	add.b	d0,d3
	bpl	@f
	moveq.l	#0,d3
@@:
	andi.w	#$c7,d2
	lsl.b	#3,d3
	or.b	d3,d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm

r_regope_PAN:
	moveq.l	#$20,d1
	add.b	d4,d1
	move.b	opmreg(a6,d1.w),d2
	move.l	d2,d3
	rol.b	#2,d3
	andi.w	#3,d3
	move.b	(a0)+,d0
	bmi	rrPAN
	add.b	d0,d3
	cmpi.b	#3,d3
	bls	@f
	moveq.l	#3,d3
	bra	@f
rrPAN:
	add.b	d0,d3
	bpl	@f
	moveq.l	#0,d3
@@:
	andi.w	#$3f,d2
	ror.b	#2,d3
	or.b	d3,d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm

r_regope_AMS:
	moveq.l	#$38,d1
	add.b	d4,d1
	move.b	opmreg(a6,d1.w),d2
	move.l	d2,d3
	andi.w	#3,d3
	move.b	(a0)+,d0
	bmi	rrAMS
	add.b	d0,d3
	cmpi.b	#3,d3
	bls	@f
	moveq.l	#3,d3
	bra	@f
rrAMS:
	add.b	d0,d3
	bpl	@f
	moveq.l	#0,d3
@@:
	andi.w	#$f0,d2
	or.b	d3,d2
	jsr	(a4)		*opmset
	bra	next_cmd_fm

r_regope_PMS:
	moveq.l	#$38,d1
	add.b	d4,d1
	move.b	opmreg(a6,d1.w),d2
	move.l	d2,d3
	lsr.w	#4,d3
	andi.w	#7,d3
	move.b	(a0)+,d0
	bmi	rrPMS
	add.b	d0,d3
	cmpi.b	#7,d3
	bls	@f
	moveq.l	#7,d3
	bra	@f
rrPMS:
	add.b	d0,d3
	bpl	@f
	moveq.l	#0,d3
@@:
	andi.w	#$0f,d2
	lsl.b	#4,d3
	or.b	d3,d2
	jsr	(a4)			*opmset
	bra	next_cmd_fm
*------------------------------------------------------------------------------
reg_set_ad:				*ADPCM Ｙコマンド
	pea	next_cmd_ad(pc)
	lea	set_dtn_ad(pc),a1
	move.b	(a0)+,d1		*reg number
	move.b	(a0)+,d2		*data
	bra	@f

reg_set_fm:				*FM Ｙコマンド
	pea	next_cmd_fm(pc)
	lea	set_dtn_fm(pc),a1
	move.b	(a0)+,d1		*reg number
	move.b	(a0)+,d2		*data
@@:
	cmpi.b	#$02,d1			*emulate opmd.x y2,n
	beq	opmd_y2
	cmpi.b	#$03,d1			*emulate opmd.x y3,n
	beq	opmd_y3
	cmpi.b	#13,d1			*emulate opmd.x y13,n
	beq	opmd_y13
	cmpi.b	#14,d1			*emulate opmd.x y14,n
	beq	opmd_y14
	cmpi.b	#48,d1			*KFか
	bcs	@f
	cmpi.b	#55,d1
	bhi	@f
	addq.w	#4,sp			*peaを無効にする。(ちょっと無駄)
	andi.w	#$ff,d2
	lsr.w	#2,d2
	move.w	d2,p_detune(a5)
	jmp	(a1)
@@:
	move.l	p_opmset(a5),a4
	jsr	(a4)			*opmset
	cmpi.b	#$60,d1
	bcs	@f
	cmpi.b	#$7f,d1
	bls	set_to_olwk
@@:
	rts

opmd_y2:				*OPMD式ノートオン
	cmp.w	adpcm_n_max(pc),d2	*データが存在しない
	bcc	@f
	move.l	d2,d3
	move.w	p_frq(a5),d2		*d2.lb=p_pan(a5)  d2.hb=p_frq(a5)
	bsr	conv_p@p		*0-127→1-3
	move.w	d2,d1			*d1=frq/pan
	moveq.l	#254,d6			*ch
	move.l	d3,d2
	jmp	se_adpcm2
@@:
	rts

opmd_y3:				*OPMD式 ADPCMパンポット指定
	move.b	d2,p_pan(a5)
	bra	do_adpcm_pan

opmd_y13:				*OPMD式 ADPCM FRQ設定
	move.l	d2,d1
	move.b	d1,p_frq(a5)
	bra	do_adpcm_frq

opmd_y14:				*OPMD式 効果音モード設定
	tst.b	d2
	sne.b	se_mode-work(a6)
	rts

reg_set_md:				*MIDI Ｙコマンド
	bsr	timbre_set2		*!97/4/1
	moveq.l	#$b0,d0
	or.b	d4,d0			*ctrl chg
	jsr	(a2)
	move.b	(a0)+,d0		*reg number
	jsr	(a2)
	move.b	(a0)+,d0		*data value
	jsr	(a2)
	bra	next_cmd_md
*------------------------------------------------------------------------------
Q_gate_fm:
	move.b	(a0)+,p_Q_gate+0(a5)
	move.b	(a0)+,p_Q_gate+1(a5)
	bra	next_cmd_fm

Q_gate_ad:
	move.b	(a0)+,p_Q_gate+0(a5)
	move.b	(a0)+,p_Q_gate+1(a5)
	bra	next_cmd_ad

Q_gate_md:
	move.b	(a0)+,p_Q_gate+0(a5)
	move.b	(a0)+,p_Q_gate+1(a5)
	bra	next_cmd_md
*------------------------------------------------------------------------------
track_delay_fm			*トラックディレイ(FM)
	bsr	get_steptime
	move.w	d1,(a5)
	beq	next_cmd_fm
	rts

track_delay_md			*トラックディレイ(MIDI)
	bsr	get_steptime
	move.w	d1,(a5)
	beq	next_cmd_md
	rts

track_delay_ad			*トラックディレイ(ADPCM)
	bsr	get_steptime
	move.w	d1,(a5)
	beq	next_cmd_ad
	rts
*------------------------------------------------------------------------------
len0_note_fm:
	move.b	(a0)+,d7		*note
	bsr	do_transpose
	bsr	get_def_velo		*velocity
	clr.w	(a5)			*0 step
	lea	INF_GATE.w,a2		*∞ gate
	move.l	p_opmset(a5),a1
	bra	do_note_on_fm

len0_note_ad:
	move.b	(a0)+,d7		*note
	bsr	do_transpose
	bsr	get_def_velo		*velocity
	clr.w	(a5)			*0 step
	moveq.l	#INF_GATE,d2		*∞ gate
	bra	do_note_on_ad

len0_note_md:
	move.b	(a0)+,d7		*note
	bsr	do_transpose
	bsr	get_def_velo		*velocity
	clr.w	(a5)			*0 step
	moveq.l	#INF_GATE,d2		*∞ gate
	lea	p_note(a5),a1
	move.l	p_midi_trans(a5),a2
	moveq.l	#max_note_on-1,d5
	tst.b	p_track_mode(a5)
	bmi	do_note_on_md		*キーオフなし
@@:					*以下ステップタイム＝0のケース
	tst.b	(a1)
	bmi	do_note_on_md
	addq.w	#k_note_len,a1
	dbra	d5,@b
					*いちばん古い音を強制的にキーオフ
	moveq.l	#max_note_on-1-1,d5	*1回少なくする
	lea	p_note(a5),a1
	moveq.l	#$90,d0
	add.b	d4,d0
	jsr	(a2)			*send cmd
	move.b	(a1),d0
	jsr	(a2)			*note number
	bset.b	#b_keyoff,p_onoff_bit(a5)	*set key off bit
	moveq.l	#$00,d0
	jsr	(a2)			*#0
@@:
	move.l	k_note_len(a1),(a1)+	*詰める処理
	dbmi	d5,@b
	bra	do_note_on_md
*------------------------------------------------------------------------------
do_transpose:			*トランスポーズ
	* < d7.b=note number
	* > d7.b=calculated note number
	* x d6
	move.b	p_transpose(a5),d6
	beq	exit_dotrp
	bpl	@f
	add.b	d6,d7
	bpl	exit_dotrp
	moveq.l	#0,d7
	bra	exit_dotrp
@@:
	add.b	d6,d7
	bcc	exit_dotrp
	moveq.l	#127,d7
exit_dotrp:
	rts
*------------------------------------------------------------------------------
portament_fm:
portament2_fm:
	bsr	get_port_param
	bsr	calc_port_param
	bra	case_key_patch_fm

get_port_param:
	st.b	p_port_flg(a5)
	move.b	(a0)+,d7		*source note
	bmi	prtmntm1		*src note=0-127のときはディレイなし
	clr.w	p_port_dly(a5)		*src note=128-255のときはディレイあり
	move.b	(a0)+,d6		*dest note=128-255のときはポルタメントタイムあり
	bmi	prtmntm2		*dest note=0-127のときはポルタメントタイムなし
prtmntm0:				*ポルタメントタイム省略(ディレイも省略)
	bsr	get_st_gt_vl		*d1=step time
	move.w	d1,p_port_cnt(a5)
	rts
prtmntm1:
	move.b	(a0)+,d6		*dest note
	bpl	prtmntm3		*ポルタメントタイム無しへ(delay only)
	moveq.l	#0,d0
	move.b	(a0)+,d0		*get delay
	bpl	@f
	add.b	d0,d0			*kill 7bit
	lsl.w	#7,d0
	move.b	(a0)+,d0
@@:
	move.w	d0,p_port_dly(a5)
prtmntm2:				*portament time
	moveq.l	#0,d0
	move.b	(a0)+,d0		*get portament time
	bpl	@f
	add.b	d0,d0			*kill 7bit
	lsl.w	#7,d0
	move.b	(a0)+,d0
@@:
	move.w	d0,p_port_cnt(a5)
	bra	get_st_gt_vl		*d1.w=step time
prtmntm3:				*delay only
	moveq.l	#0,d0
	move.b	(a0)+,d0		*get delay
	bpl	@f
	add.b	d0,d0			*kill 7bit
	lsl.w	#7,d0
	move.b	(a0)+,d0
@@:
	move.w	d0,p_port_dly(a5)
	bsr	get_st_gt_vl
	sub.w	p_port_dly(a5),d1
	move.w	d1,p_port_cnt(a5)
	rts

calc_port_param:			*FM/ADPCM用パラメータ計算
	* < d7=source note
	* < d6=destination note
	andi.l	#$7f,d6			*make it 0-127
	andi.w	#$7f,d7			*make it 0-127
	move.b	d6,p_last_note(a5)	*ポルタメントの場合はデスティネーションをここへ
	moveq.l	#0,d1
	move.l	d1,p_port_pitch(a5)	*ちゃっかり初期化
	move.l	d1,p_port_step(a5)	*一応初期化
	move.w	p_port_cnt(a5),d1
	beq	1f
	sub.w	d7,d6
	bmi	@f
	asl.w	#6,d6
clprpl_fm:
	divu	d1,d6		*d6=range/L d6.w=step counter
	move.w	d6,d0
	clr.w	d6
	divu	d1,d6		*d6=d6/L
	swap	d0
	move.w	d6,d0
	addq.l	#1,d0
	move.l	d0,p_port_step(a5)
	rts
@@:
	neg.w	d6
	asl.w	#6,d6
clprmi_fm:
	divu	d1,d6		*d6=range/L d6.w=step counter
	move.w	d6,d0
	clr.w	d6
	divu	d1,d6		*d6=d6/L
	swap	d0
	move.w	d6,d0
	neg.l	d0
	move.l	d0,p_port_step(a5)
1:
	rts

calc_autoport_param	macro	xx
	* < d1.w=step
	* < d7.w=key
	* x d0,d1,d5,d6
	moveq.l	#0,d5
	move.l	d5,p_port_pitch(a5)	*ちゃっかり初期化
	move.l	d5,p_port_step(a5)	*一応初期化
	move.b	p_last_note(a5),d0
	bmi	2f
	move.b	d7,p_last_note(a5)
	move.w	p_port2_dly(a5),d5	*auto portament interval
	bpl	@f
	add.w	d5,d1
	ble	2f
	move.w	d1,p_port_dly(a5)
	move.w	d5,d1
	neg.w	d1
	bra	1f
@@:
	move.w	d5,p_port_dly(a5)
	sub.w	d5,d1
	ble	2f			*ポルタメントタイムが０になっては意味がない
1:
	move.w	p_port2_cnt(a5),d6
	beq	1f
	bpl	@f
	add.w	d6,d1
	bgt	1f
	sub.w	d6,d1
	bra	1f			*ポルタメントタイムが０になっては意味がない
@@:
	cmp.w	d1,d6
	bcc	1f
	move.l	d6,d1
1:
	move.w	d1,p_port_cnt(a5)
	move.l	d7,d6
	move.b	d0,d7
	sub.b	d0,d6
	bpl	@f
	neg.b	d6
	asl.w	#6,d6
	divu	d1,d6		*d6=range/L d6.w=step counter
	move.w	d6,d0
	clr.w	d6
	divu	d1,d6		*d6=d6/L
	swap	d0
	move.w	d6,d0
	neg.l	d0
	move.l	d0,p_port_step(a5)
	bra	case_key_patch_&xx
@@:
	asl.w	#6,d6
	divu	d1,d6		*d6=range/L d6.w=step counter
	move.w	d6,d0
	clr.w	d6
	divu	d1,d6		*d6=d6/L
	swap	d0
	move.w	d6,d0
	addq.l	#1,d0
	move.l	d0,p_port_step(a5)
	bra	case_key_patch_&xx
2:
	endm

case_key_fm:				*音符データ処理(FM)
	* < d7.b=key code
	bsr	get_st_gt_vl
	move.b	p_port2_flg(a5),p_port_flg(a5)	*ｵｰﾄﾎﾟﾙﾀﾒﾝﾄﾁｪｯｸ/ﾎﾟﾙﾀﾒﾝﾄﾌﾗｸﾞ初期化
	beq	ckf0
	calc_autoport_param	fm
ckf0:
	clr.l	p_port_pitch(a5)
	move.b	d7,p_last_note(a5)	*前回のノートを保存
case_key_patch_fm:
	bsr	do_transpose
	move.l	p_opmset(a5),a1
	move.l	d2,a2			*preserve gatetime
	lea	p_note(a5),a4
	tst.w	d2
	beq	key_off_phase_fm
	move.b	p_how_many(a5),d6
	bmi	do_note_on_fm		*現在なにも鳴っていないなら即発音
*	tst.b	p_track_mode(a5)	*!5/10
*	bmi	do_note_on_fm		*!
	move.w	p_voice_rsv(a5),d5
	tst.w	(a5)
	bne	off_tient_fm
	move.w	d4,d0
1:					*以下ステップタイム＝0のケース
	move.b	k_note(a4),d1
	bmi	@f
	cmp.b	d1,d7
	beq	same_note_fm		*同じノートナンバーを発見
	move.w	k_gate_time(a4),d2	*絶対音長0音符からのタイがあるか
	addq.w	#1,d2			*タイ指定か(=cmpi.w #TIE_GATE_CODE,k_gate_time(a4))
	bne	@f
	moveq.l	#8,d1
	move.b	opm_kon-work(a6,d0.w),d2
	and.b	opm_nom-work(a6,d0.w),d2
	jsr	(a1)				*opmset(タイの音を消す(< d1=8))
	tas.b	(a4)				*set note off mark
	bset.b	#b_keyoff,p_onoff_bit(a5)	*set key off bit
	subq.b	#1,p_how_many(a5)		*!6/17
@@:
	addq.w	#k_note_len,a4
	addq.w	#1,d0
	andi.w	#7,d0
	dbra	d5,1b
	bra	do_note_on_fm
key_off_phase_fm:			*ゲートタイム=0はノートオフ指定として処理する
	tst.b	p_track_mode(a5)
	bmi	go_cpfm
	move.w	p_voice_rsv(a5),d5
	move.w	d4,d0
kfpflp00:
	cmp.b	k_note(a4),d7
	bne	@f
	moveq.l	#8,d1
	move.b	opm_kon-work(a6,d0.w),d2
	and.b	opm_nom-work(a6,d0.w),d2
	jsr	(a1)				*opmset(タイの音を消す(< d1=8))
	tas.b	(a4)				*set note off mark
	bset.b	#b_keyoff,p_onoff_bit(a5)	*set key off bit
	subq.b	#1,p_how_many(a5)
@@:
	addq.w	#k_note_len,a4
	addq.w	#1,d0
	andi.w	#7,d0
	dbra	d5,kfpflp00
	bra	go_cpfm
off_tient_fm:					*以下ステップタイム≠0のケース
	tst.b	d6				*鳴っているのが単音(d6=0)ならば
	bne	1f				*スラーかどうかチェック
csf_lp:
	move.l	(a4)+,d0
	bmi	@f
	addq.w	#1,d0				*タイ指定か(cmpi.w #TIE_GATE_CODE,d0)
	beq	case_slur_fm			*case:slur
@@:
	dbra	d5,csf_lp
	lea	p_note(a5),a4			*破壊してしまっているから再設定
	move.w	p_voice_rsv(a5),d5
1:
	move.w	d4,d0
ktf_lp:
	move.b	k_note(a4),d1
	bmi	next_ktf
	cmp.b	d1,d7				*鳴っている音で同じノートナンバーを発見
	beq	same_note_fm
	move.w	k_gate_time(a4),d2		*絶対音長0音符からのタイがあるか
	beq	gtovwf				*ゲートタイム上書き
	addq.w	#1,d2			*タイ指定か(=cmpi.w #TIE_GATE_CODE,k_gate_time(a4))
	bne	next_ktf
	moveq.l	#8,d1
	move.b	opm_kon-work(a6,d0.w),d2
	and.b	opm_nom-work(a6,d0.w),d2
	jsr	(a1)				*opmset(タイの音を消す(< d1=8))
	tas.b	(a4)				*set note off mark
	bset.b	#b_keyoff,p_onoff_bit(a5)	*set key off bit
	subq.b	#1,p_how_many(a5)		*!96/6/17
	bra	next_ktf
gtovwf:						*c*0&e4のようなケースに対応
	move.w	a2,d2
	bmi	next_ktf
	move.w	a2,k_gate_time(a4)
next_ktf:
	addq.w	#k_note_len,a4
	addq.w	#1,d0
	andi.b	#7,d0
	dbra	d5,ktf_lp
do_note_on_fm:				*実際のノートオン処理
	move.w	p_voice_rsv(a5),d5
	move.b	p_how_many(a5),d2
	addq.b	#1,d2			*新しく発音しました
	cmp.b	d5,d2
	bls	1f
	btst.b	#b_voice_rsv,p_md_flg(a5)	*ボイスリザーブを行ったか
	bne	2f
	cmpi.w	#fm_ch_max-1,d5		*もうチャンネル一杯か
	beq	2f
	lea	p_note(a5),a4
	moveq.l	#0,d0
@@:					*DVA処理
	tst.l	(a4)+
	bmi	3f
	addq.w	#1,d0			*空いているチャンネルを割り当てる
	dbra	d5,@b
	move.w	p_voice_rsv(a5),d5	*空きなしケース
	addq.w	#1,d5
	move.w	d5,p_voice_rsv(a5)
1:
	move.b	d2,p_how_many(a5)	*新しく発音しました格納
2:
	moveq.l	#0,d0
	move.b	p_next_on(a5),d0
	cmp.b	d5,d0
	bls	@f
	moveq.l	#0,d0				*始めに戻す
@@:
	move.l	d0,d1
	addq.b	#1,d1
	move.b	d1,p_next_on(a5)	*次回の発音チャンネル
3:
	tst.b	p_track_mode(a5)		*!ダンパーなどの時は発音前にキーオフ
	bpl	@f				*!
	bset.b	#b_keyoff,p_onoff_bit(a5)	*!set key off bit
	move.l	d4,d1				*!5/10
	add.w	d0,d1				*!
	andi.w	#7,d1				*!
	move.b	opm_kon-work(a6,d1.w),d2	*!
	and.b	opm_nom-work(a6,d1.w),d2	*!
	moveq.l	#8,d1				*!
	jsr	(a1)				*!opmset(強制的にキーオフ)
@@:						*!5/10
	move.l	d0,d1
	move.l	d0,d6
	add.w	d6,d6
	add.w	d6,d6
	lea	p_note(a5,d6.w),a4
	move.b	d7,(a4)+		*note number
	move.b	d3,(a4)+		*velocity
	move.w	a2,(a4)			*gate time
	cmpi.w	#TIE_GATE,(a4)
	bne	@f
	clr.w	(a4)
@@:
	move.b	d7,(a3)+
	move.b	d3,(a3)+
	move.w	d1,(a3)+		*note on markerにオフセットをセット
	clr.l	(a3)+
	st.b	(a3)			*end code
	btst.b	#b_split_mode,p_md_flg(a5)
	beq	@f
	bsr	do_timbre_split_fm
	bra	go_cpfm
@@:
	move.l	(a6),a4
	move.w	-(a4),d0		*d0.w=現在実行中のトラックナンバー(0～)
	lea	fm_tone_set-work(a6),a4
	bset.b	d1,p_tone_set(a5)	*音色が設定されていないチャンネルに付いて設定する
	beq	2f
	add.w	d1,d4			*トラック次元では設定済み
	andi.w	#$07,d4
	move.w	d4,d1
	add.w	d1,d1
	cmp.w	(a4,d1.w),d0		*同じトラックが音色を設定しているので無視
	beq	1f
	move.w	d0,(a4,d1.w)
	move.b	d4,p_timbre_src(a5)
	move.w	p_pgm(a5),d0
	moveq.l	#0,d1
	move.b	p_bank_msb(a5),d5
	bmi	@f
	move.b	d5,d1
	andi.w	#$7f,d0			*バンクモードならばpgm=0-127
@@:
	lsl.w	#7,d1
	moveq.l	#0,d2
	move.b	p_bank_lsb(a5),d5
	bmi	@f
	move.b	d5,d2
	andi.w	#$7f,d0			*バンクモードならばpgm=0-127
@@:
	or.b	d2,d1
	lsl.w	#7,d1
	add.w	d1,d0			*バンク考慮
	bsr	fmvset
1:
	move.w	p_ch(a5),d4
	bra	go_cpfm
2:					*トラック次元で未設定
	add.w	d4,d1			*トラック次元では設定済み
	andi.w	#$07,d1
	move.w	d1,d5
	add.w	d5,d5
	move.w	d0,(a4,d5.w)
	moveq.l	#0,d5
	move.b	p_timbre_src(a5),d5
	bsr	copy_opm_timbre
go_cpfm:
	* > d1.w=step time
	* - d3.w (velocity)保存する
	* - d4.l (ch)保存する
	* X d0 d1 d2 d5 d6 / a1 a2 a4
*	tst.w	p_level_param(a5)		*AMOD/AFTC ON?
*	bne	@f				*yes(音量設定不要)
	andi.w	#$00f0,p_level_param(a5)	*!10/25
	or.w	#$0100,p_level_param(a5)	*!5/28
@@:
	tst.w	p_pitch_param(a5)		*AMOD/PORT/BEND ON?
	bne	@f				*yes(音程設定不要)
	move.w	#8,p_pitch_param(a5)
@@:
	move.w	(a5),d5			*get step & check step
	beq	next_cmd_fm
	bsr	fm_bend			*ベンドパラメータ
	bra	calc_param_fm

case_slur_fm:				*タイで単音指定のケース
	* < a4=スラーと判断されたp_noteX+4のアドレス
	* x d0,d5,a4
	move.w	(a5),d5
	tst.b	p_bend_sw(a5)
	ble	@f
	bsr	fm_bend
@@:
	bsr	tie_calc_param_fm
	move.w	d2,-(a4)		*set gate
	cmpi.w	#TIE_GATE,d2
	bne	@f
	clr.w	(a4)			*内部TIE_GATE=0(ただしまだd2.w=TIE_GATE)
@@:
	cmp.b	-(a4),d3
	beq	1f
	move.b	d3,(a4)			*ベロシティが違うなら新設定
*	tst.w	p_level_param(a5)
*	bne	1f
	andi.w	#$00f0,p_level_param(a5)	*!10/25
	or.w	#$0100,p_level_param(a5)	*!5/28
1:
	move.b	d7,-(a4)		*set note
	tst.w	p_pitch_param(a5)
	bne	@f
	move.w	#8,p_pitch_param(a5)
@@:
	rts

calc_param_fm:				*特殊コマンドのパラメータ計算
	bsr	calc_param_fm_aftc_0
	bsr	calc_param_fm_pmod_0
	bsr	calc_param_fm_arcc_0
	bra	calc_param_fm_agogik_0

same_note_fm:				*同じノートだった
	* < d0.w=ch N
	* < d1.l=8(reg)
*!!!!/97/06/09
	sub.w	d4,d0
	addq.w	#1,d0
	cmp.w	p_voice_rsv(a5),d0
	bls	@f
	moveq.l	#0,d0				*始めに戻す
@@:
	move.b	d0,p_next_on(a5)	*次回の発音チャンネル
*!!!!/97/06/09
	cmp.b	k_velo(a4),d3
	beq	1f
	move.b	d3,k_velo(a4)		*ベロシティが違うなら新設定
*	tst.w	p_level_param(a5)
*	bne	1f
	andi.w	#$00f0,p_level_param(a5)	*!10/25
	or.w	#$0100,p_level_param(a5)	*!5/28
1:
	move.w	a2,k_gate_time(a4)	*set gate time
	cmpi.w	#TIE_GATE,k_gate_time(a4)
	bne	@f
	clr.w	k_gate_time(a4)		*内部TIE_GATE
@@:
	move.w	(a5),d5
	beq	next_cmd_fm
	tst.b	p_bend_sw(a5)
	ble	@f
	bsr	fm_bend
@@:
*	bra	tie_calc_param_fm

tie_calc_param_fm:					*タイ／スラー・ケース
	* - a4
	movem.l	d2/d7/a4,-(sp)
	bsr	tie_calc_param_fm_aftc_0
	bsr	tie_calc_param_fm_pmod_0
	bsr	tie_calc_param_fm_arcc_0
	bsr	tie_calc_param_fm_agogik_0
	movem.l	(sp)+,d2/d7/a4
	rts

portament_md:				*@B0,Xケース
	bsr	get_port_param
	* < d7=source note
	* < d6=destination note
	andi.l	#$7f,d6			*make it 0-127
	andi.w	#$7f,d7			*make it 0-127
	move.b	d6,p_last_note(a5)	*ポルタメントの場合はデスティネーションをここへ
	moveq.l	#0,d1
	move.l	d1,p_port_pitch(a5)	*ちゃっかり初期化
	move.l	d1,p_port_step(a5)	*一応初期化
	move.w	p_port_cnt(a5),d1
	beq	case_key_patch_md
	sub.b	d7,d6
	bmi	@f
	swap	d6		*正のケース
	lsr.l	#16-11,d6	*diff*2048倍
	divu	#3,d6
	bvs	1f
	andi.l	#$ffff,d6
	cmpi.w	#8191,d6
	bls	clprpl_md
1:
	move.l	#8191,d6
clprpl_md:
	divu	d1,d6		*d6=range/L d6.w=step counter
	move.w	d6,d0
	clr.w	d6
	divu	d1,d6		*d6=d6/L
	swap	d0
	move.w	d6,d0
	addq.l	#1,d0
	move.l	d0,p_port_step(a5)
	bset.b	#b_bend_reset,p_md_flg(a5)		*bend set marker
	bra	case_key_patch_md
@@:				*負のケース
	neg.b	d6
	swap	d6
	lsr.l	#16-11,d6	*diff*2048倍
	divu	#3,d6
	bvs	1f
	andi.l	#$ffff,d6
	cmpi.w	#8192,d6
	bls	clprmi_md
1:
	move.l	#8192,d6
clprmi_md:
	divu	d1,d6		*d6=range/L d6.w=step counter
	move.w	d6,d0
	clr.w	d6
	divu	d1,d6		*d6=d6/L
	swap	d0
	move.w	d6,d0
	neg.l	d0
	move.l	d0,p_port_step(a5)
	bset.b	#b_bend_reset,p_md_flg(a5)		*bend set marker
	bra	case_key_patch_md

portament2_md:				*@BX,0ケース
	bsr	get_port_param
	* < d7=source note
	* < d6=destination note
	andi.l	#$7f,d6			*make it 0-127
	andi.w	#$7f,d7			*make it 0-127
	move.b	d6,p_last_note(a5)	*ポルタメントの場合はデスティネーションをここへ
	moveq.l	#0,d1
	move.l	d1,p_port_pitch(a5)	*ちゃっかり初期化
	move.l	d1,p_port_step(a5)	*一応初期化
	sub.b	d7,d6
	bmi	@f
	move.b	p_last_note(a5),d7
	swap	d6		*正のケース
	lsr.l	#16-11,d6	*diff*2048倍
	divu	#3,d6
	bvs	1f
	andi.l	#$ffff,d6
	cmpi.w	#8191,d6
	bls	clpr2pl_md
1:
	move.l	#8191,d6
clpr2pl_md:
	sub.w	d6,p_port_pitch(a5)
	move.w	p_port_cnt(a5),d1
	beq	case_key_patch_md
	divu	d1,d6		*d6=range/L d6.w=step counter
	move.w	d6,d0
	clr.w	d6
	divu	d1,d6		*d6=d6/L
	swap	d0
	move.w	d6,d0
	addq.l	#1,d0
	move.l	d0,p_port_step(a5)
	bset.b	#b_bend_reset,p_md_flg(a5)		*bend set marker
	bra	case_key_patch_md
@@:				*負のケース
	move.b	p_last_note(a5),d7
	neg.b	d6
	swap	d6
	lsr.l	#16-11,d6	*diff*2048倍
	divu	#3,d6
	bvs	1f
	andi.l	#$ffff,d6
	cmpi.w	#8192,d6
	bls	clpr2mi_md
1:
	move.l	#8192,d6
clpr2mi_md:
	move.w	d6,p_port_pitch(a5)
	move.w	p_port_cnt(a5),d1
	beq	case_key_patch_md
	divu	d1,d6		*d6=range/L d6.w=step counter
	move.w	d6,d0
	clr.w	d6
	divu	d1,d6		*d6=d6/L
	swap	d0
	move.w	d6,d0
	neg.l	d0
	move.l	d0,p_port_step(a5)
	bset.b	#b_bend_reset,p_md_flg(a5)		*bend set marker
	bra	case_key_patch_md

calc_autoport_param_md	macro
	* < d1.w=step
	* < d7.w=key
	* x d0,d1,d5,d6
	moveq.l	#0,d5
	move.l	d5,p_port_pitch(a5)	*ちゃっかり初期化
	move.l	d5,p_port_step(a5)	*一応初期化
	move.b	p_last_note(a5),d0
	bmi	exit_capm
	move.b	d7,p_last_note(a5)
	move.w	p_port2_dly(a5),d5	*auto portament interval
	move.w	d5,p_port_dly(a5)
	sub.w	d5,d1
	bls	exit_capm
	move.w	p_port2_cnt(a5),d6
	beq	1f
	bpl	@f
	add.w	d6,d1
	bgt	1f
	sub.w	d6,d1
	bra	1f
@@:
	cmp.w	d1,d6
	bcc	1f
	move.l	d6,d1
1:
	move.w	d1,p_port_cnt(a5)
	move.l	d7,d6
	move.b	d0,d7
	sub.b	d0,d6
	bpl	2f
	neg.b	d6		*負のケース
	swap	d6
	lsr.l	#16-11,d6	*diff*2048倍
	divu	#3,d6
	bvs	1f
	andi.l	#$ffff,d6
	cmpi.w	#8192,d6
	bls	clprmi_md
1:
	move.l	#8192,d6
	bra	clprmi_md
2:				*正のケース
	swap	d6
	lsr.l	#16-11,d6	*diff*2048倍
	divu	#3,d6
	bvs	1f
	andi.l	#$ffff,d6
	cmpi.w	#8191,d6
	bls	clprpl_md
1:
	move.l	#8191,d6
	bra	clprpl_md
exit_capm:
	endm

case_key_md:				*音符データ処理(MIDI)
	* < d7.b=key code
	bsr	get_st_gt_vl
	move.b	p_port2_flg(a5),p_port_flg(a5)	*ｵｰﾄﾎﾟﾙﾀﾒﾝﾄﾁｪｯｸ/ﾎﾟﾙﾀﾒﾝﾄﾌﾗｸﾞ初期化
	beq	ckm0
	calc_autoport_param_md
ckm0:
	btst.b	#b_tie_mode,p_md_flg(a5)	*!
	beq	case_key_patch_md		*!
	clr.l	p_port_pitch(a5)
	move.b	d7,p_last_note(a5)	*前回のノートを保存
case_key_patch_md:
	bsr	do_transpose
	lea	p_note(a5),a1
	move.l	p_midi_trans(a5),a2
	moveq.l	#max_note_on-1,d5
	tst.w	d2
	beq	key_off_phase_md
	tst.b	p_track_mode(a5)
	bmi	do_note_on_md		*キーオフなし
	tst.w	(a5)
	bne	off_tient_md
1:					*以下ステップタイム＝0のケース
	move.b	(a1),d1
	bmi	do_note_on_md
	cmp.b	d1,d7
	beq	same_note_md			*同じノートナンバーを発見
	move.w	k_gate_time(a1),d0		*絶対音長0音符からのタイか
	addq.w	#1,d0			*タイ指定か(=cmpi.w #TIE_GATE_CODE,k_gate_time(a1))
	bne	2f
	moveq.l	#$90,d0				*NOTE OFFへ
	add.b	d4,d0
	jsr	(a2)				*send cmd
	move.b	d1,d0
	jsr	(a2)				*note number
	bset.b	#b_keyoff,p_onoff_bit(a5)	*set key off bit
	moveq.l	#$00,d0
	jsr	(a2)				*#0
	*ノートワーク整列処理
	move.l	a1,a4
	move.l	d5,d0
@@:
	move.l	k_note_len(a4),(a4)+
	dbra	d0,@b				*!6/17
2:
	addq.w	#k_note_len,a1
	dbra	d5,1b
	bra	do_note_on_md
key_off_phase_md:			*ゲートタイム=0はノートオフ指定として処理する
	tst.b	p_track_mode(a5)
	bmi	go_cpmd
	moveq.l	#$80,d0
	add.b	d4,d0
	jsr	(a2)				*send cmd
	move.l	d7,d0
	jsr	(a2)				*note number
	bset.b	#b_keyoff,p_onoff_bit(a5)	*set key off bit
	move.l	d3,d0
	jsr	(a2)				*offベロシティ
kfpmlp00:
	move.b	(a1),d1
	bmi	go_cpmd
	cmp.b	d1,d7
	bne	1f
poly_pressure_patch2:			*ポリフォニックプレッシャー無しモードでは(bra ppp0)
	moveq.l	#$a0,d0			*polyphonic pressure
	add.b	d4,d0
	jsr	(a2)
	move.b	d1,d0
	jsr	(a2)
	moveq	#0,d0			*pp=0(reset)
	jsr	(a2)
ppp0:
	*ノートワーク整列処理
	move.l	a1,a4
	move.l	d5,d0
@@:
	move.l	k_note_len(a4),(a4)+
	dbra	d0,@b
	bra	2f
1:
	addq.w	#k_note_len,a1
2:
	dbra	d5,kfpmlp00
	bra	go_cpmd
off_tient_md:					*以下ステップタイム≠0のケース
	move.b	k_note(a1),d1
	bmi	do_note_on_md
	tst.b	k_note_len(a1)			*鳴っているのが単音4(a1)<0ならば
	bpl	@f				*スラーのケースか調べる
	btst.b	#b_tie_mode,p_md_flg(a5)	*スペシャルタイモードか
	beq	@f				*違う
	cmpi.w	#TIE_GATE_CODE,k_gate_time(a1)	*タイ指定か
	beq	case_slur_md			*スラー処理へ
ktm_lp:
	move.b	k_note(a1),d1			*鳴っている音で同じノートナンバーを発見
	bmi	do_note_on_md
@@:
	cmp.b	d1,d7
	beq	same_note_md
	move.w	k_gate_time(a1),d0		*絶対音長0音符からのタイか
	beq	gtovwm				*ゲートタイム上書き
	addq.w	#1,d0			*タイ指定か(=cmpi.w #TIE_GATE_CODE,k_gate_time(a1))
	bne	next_ktm
	moveq.l	#$90,d0				*NOTE OFFへ
	add.b	d4,d0
	jsr	(a2)				*send cmd
	move.b	d1,d0
	jsr	(a2)				*note number
	bset.b	#b_keyoff,p_onoff_bit(a5)	*set key off bit
	moveq.l	#$00,d0
	jsr	(a2)				*#0
	*ノートワーク整列処理
	move.l	a1,a4
	move.l	d5,d0
@@:
	move.l	k_note_len(a4),(a4)+
	dbra	d0,@b				*!6/17
	bra	@f
gtovwm:						*c*0&e4のようなケースに対応
	tst.w	d2
	bmi	next_ktm
	move.w	d2,k_gate_time(a1)
next_ktm:
	addq.l	#k_note_len,a1
@@:
	dbra	d5,ktm_lp
do_note_on_md:				*実際のノートオン処理
	* < a1.l=ノート情報を格納すべきアドレス
	tst.b	p_port_flg(a5)		*!3/20
	bne	@f			*!3/20
	clr.l	p_port_pitch(a5)	*!3/20
@@:
	tst.b	k_note_len*(max_note_on-1)+p_note(a5)
	bpl	force_noteon_md		*強制的にキーオンする
	move.b	d7,(a1)+		*note number
	move.b	d3,(a1)+		*velocity
	move.w	d2,(a1)			*gate time
	cmpi.w	#TIE_GATE,d2
	bne	set_ntonmk_md
	clr.w	(a1)
set_ntonmk_md:
	move.b	d7,(a3)+		*note on markerにノート番号をセット
	move.b	d3,(a3)+		*note on markerにベロシティをセット
	clr.w	(a3)+			*dummy
	moveq.l	#-1,d1
	move.b	p_timbre_set(a5),d0
	bpl	@f
	move.w	p_bank_msb(a5),d1
	swap	d1
@@:
	add.b	d0,d0			*d6 of p_timbre_set:programチェンジが行われたか(MIDI)
	bpl	@f
	move.w	p_pgm(a5),d1
@@:
	btst.b	#b_split_mode,p_md_flg(a5)
	beq	@f
	bsr	do_timbre_split_md
@@:
	move.l	d1,(a3)+
	st.b	(a3)			*end code
	andi.b	#%0011_1111,p_timbre_set(a5)	*pts_bank,pts_program=0
note_on_md:
	* > d1.w=step time
	* - d3.w (velocity)保存する
	* - d4.l (ch)保存する
	* X d0 d1 d2 d5 d6 / a1 a2 a4
	clr.w	p_special_tie(a5)
go_cpmd:
	tst.w	p_pitch_param(a5)
	bne	@f
	bclr.b	#b_bend_reset,p_md_flg(a5)
	beq	@f
	move.w	#8,p_pitch_param(a5)
@@:
	move.w	(a5),d5			*get step & check step
	beq	next_cmd_md
	bsr	midi_bend		*ベンドパラメータ
	bra	calc_param_md

case_slur_md:
	* < d4.l=type,ch
	* < d5.w=max_note_on-1
	* < a1=p_note
					*スラーのケース
	moveq.l	#0,d1
	move.b	(a1),d1			*d1.l=note
poly_pressure_patch0:			*ポリフォニックプレッシャー無しモードでは(bra csm0)
	cmp.b	k_velo(a1),d3
	beq	csm0
	moveq.l	#$a0,d0			*polyphonic pressure
	add.b	d4,d0
	jsr	(a2)
	move.b	d1,d0
	jsr	(a2)
	move.b	d3,d0			*velocity
	jsr	(a2)
csm0:
	move.b	d3,k_velo(a1)		*set velocity
	move.w	d2,k_gate_time(a1)	*set gate
	cmpi.w	#TIE_GATE,d2
	bne	@f
	clr.w	k_gate_time(a1)		*内部TIE_GATE
@@:
	sub.l	d1,d7
	moveq.l	#11,d0
	asl.l	d0,d7			*8192*diff.
	divs	#3,d7
	move.w	d7,p_special_tie(a5)
	move.w	(a5),d5			*get step
	tst.b	p_bend_sw(a5)
	ble	@f
	bsr	midi_bend
@@:
	bsr	tie_calc_param_md
	tst.w	p_pitch_param(a5)
	bne	@f
	bset.b	#b_bend_reset,p_md_flg(a5)
	move.w	#8,p_pitch_param(a5)
@@:
	rts

calc_param_md:				*特殊コマンドのパラメータ計算
	bsr	calc_param_md_aftc_0
	bsr	calc_param_md_pmod_0
	bsr	calc_param_md_arcc_0
	bra	calc_param_md_agogik_0

same_note_md:				*同じノートだった
	* < a1.l=同じノートのp_note+Xワークアドレス
poly_pressure_patch1:			*ポリフォニックプレッシャー無しモードでは(bra psp0)
	cmp.b	k_velo(a1),d3
	beq	psp0
	moveq.l	#$a0,d0			*polyphonic pressure
	add.b	d4,d0
	jsr	(a2)
	move.b	d7,d0
	jsr	(a2)
	move.b	d3,d0			*velocity
	jsr	(a2)
psp0:
	move.b	d3,k_velo(a1)		*set velocity
	move.w	d2,k_gate_time(a1)
	cmpi.w	#TIE_GATE,d2
	bne	@f
	clr.w	k_gate_time(a1)		*内部TIE_GATE
@@:
	move.w	(a5),d5			*get step
	beq	next_cmd_md
	tst.b	p_bend_sw(a5)
	ble	@f
	bsr	midi_bend
@@:
*	bra	tie_calc_param_md

tie_calc_param_md:
	bsr	tie_calc_param_md_aftc_0
	bsr	tie_calc_param_md_pmod_0
	bsr	tie_calc_param_md_arcc_0
	bra	tie_calc_param_md_agogik_0

force_noteon_md:			*強制的にキーオン
	moveq.l	#max_note_on-1-1,d5	*1回少なくする
	lea	p_note(a5),a1
	moveq.l	#$90,d0			*いちばん古い音を強制的にキーオフ
	add.b	d4,d0
	jsr	(a2)			*send cmd
	move.b	(a1),d0
	jsr	(a2)			*note number
	bset.b	#b_keyoff,p_onoff_bit(a5)	*set key off bit
	moveq.l	#$00,d0
	jsr	(a2)			*#0
@@:
	move.l	k_note_len(a1),(a1)+	*詰める処理
	dbmi	d5,@b
	move.b	d7,(a1)+		*note number
	move.b	d3,(a1)+		*velocity
	move.w	d2,(a1)			*gate time
	bpl	@f
	clr.b	(a1)
@@:
	move.l	a3,d0
	lea	p_key_on(a5),a3
	sub.l	a3,d0
	cmpi.l	#k_note_len*(max_note_on-1),d0		*次回発音ノートワークが足りてるか
	bls	set_ntonmk_md		*足りてる
	moveq.l	#(max_note_on-1)*2-1,d5
@@:					*詰める処理
	move.l	8(a3),(a3)+
	dbra	d5,@b
	bra	set_ntonmk_md

portament_ad:
portament2_ad:
	bsr	get_port_param
	bsr	calc_port_param
	bra	case_key_patch_ad

case_key_ad:				*音符データ処理(AD)
	* < d7.b=key code
	bsr	get_st_gt_vl
	move.b	p_port2_flg(a5),p_port_flg(a5)	*ｵｰﾄﾎﾟﾙﾀﾒﾝﾄﾁｪｯｸ/ﾎﾟﾙﾀﾒﾝﾄﾌﾗｸﾞ初期化
	beq	cka
	calc_autoport_param	ad
cka:
	clr.l	p_port_pitch(a5)
	move.b	d7,p_last_note(a5)	*前回のノートを保存
case_key_patch_ad:
	bsr	do_transpose
	lea	p_note(a5),a4
	tst.w	d2
	beq	key_off_phase_ad
	move.b	p_how_many(a5),d6
	bmi	do_note_on_ad		*現在なにも鳴っていないなら即発音
*	tst.b	p_track_mode(a5)	*!5/10
*	bmi	do_note_on_ad		*!5/10
	move.w	p_voice_rsv(a5),d5
	tst.w	(a5)
	bne	off_tient_ad		*和音の時なら最後の音の場合step=nz
	move.w	d4,d6
1:					*以下ステップタイム＝0のケース
	move.b	k_note(a4),d1
	bmi	@f
	cmp.b	d1,d7
	beq	same_note_ad		*同じノートナンバーを発見
	move.w	k_gate_time(a4),d0	*絶対音長0音符からのタイがあるか
	addq.w	#1,d0			*タイ指定か(=cmpi.w #TIE_GATE_CODE,k_gate_time(a4))
	bne	@f
	move.w	d6,d0
	bsr	pcm_key_off
	tas.b	(a4)				*set note off mark
	bset.b	#b_keyoff,p_onoff_bit(a5)	*set key off bit
	subq.b	#1,p_how_many(a5)		*!6/17
@@:
	addq.w	#k_note_len,a4
	addq.w	#1,d6
	andi.b	#$0f,d6
	dbra	d5,1b
	bra	do_note_on_ad
key_off_phase_ad:			*ゲートタイム=0はノートオフ指定として処理する
	tst.b	p_track_mode(a5)
	bmi	go_cpad
	move.w	p_voice_rsv(a5),d5
	move.w	d4,d6
kfpalp00:
	cmp.b	k_note(a4),d7
	bne	@f
	move.w	d6,d0
	bsr	pcm_key_off
	tas.b	(a4)			*set note off mark
	bset.b	#b_keyoff,p_onoff_bit(a5)	*set key off bit
	subq.b	#1,p_how_many(a5)
@@:
	addq.w	#k_note_len,a4
	addq.w	#1,d6
	andi.b	#$0f,d6
	dbra	d5,kfpalp00
	bra	go_cpad
off_tient_ad:				*タイの音符をすべてキーオフする
	btst.b	#b_vtune_mode,p_md_flg(a5)
	beq	1f			*vtune modeではない
	tst.b	d6			*d6=0:鳴っているのが単音
	bne	1f			*(鳴っているのが単音)スラーのケースか調べる
csa_lp:
	move.l	(a4)+,d0
	bmi	@f
	addq.w	#1,d0			*タイ指定か(cmpi.w #TIE_GATE_CODE,d0)
	beq	case_slur_ad		*case:slur
@@:
	dbra	d5,csa_lp
	lea	p_note(a5),a4		*破壊してしまっているから再設定
	move.w	p_voice_rsv(a5),d5
1:
	move.w	d4,d6
kta_lp:
	move.b	k_note(a4),d1
	bmi	next_kta
	cmp.b	d1,d7			*鳴っている音で同じノートナンバーを発見
	beq	same_note_ad
	move.w	k_gate_time(a4),d0	*絶対音長0音符からのタイがあるか
	beq	gtovwa
	addq.w	#1,d0			*タイ指定か(=cmpi.w #TIE_GATE_CODE,k_gate_time(a4))
	bne	next_kta
	move.w	d6,d0
	bsr	pcm_key_off
	tas.b	(a4)				*set note off mark
	bset.b	#b_keyoff,p_onoff_bit(a5)	*set key off bit
	subq.b	#1,p_how_many(a5)		*!6/17
	bra	next_kta
gtovwa:
	tst.w	d2
	bmi	next_kta
	move.w	d2,k_gate_time(a4)
next_kta:
	addq.w	#k_note_len,a4
	addq.w	#1,d6
	andi.b	#$0f,d6
	dbra	d5,kta_lp
do_note_on_ad:				*実際のノートオン処理
	move.w	p_voice_rsv(a5),d5
	move.b	p_how_many(a5),d1
	addq.b	#1,d1
	cmp.b	d5,d1
	bls	1f
	btst.b	#b_voice_rsv,p_md_flg(a5)
	bne	2f
	cmpi.w	#adpcm_ch_max-1,d5
	beq	2f
	lea	p_note(a5),a4
	moveq.l	#0,d0
@@:					*DVA OPERATION
	tst.l	(a4)+
	bmi	3f
	addq.w	#1,d0
	dbra	d5,@b
	move.w	p_voice_rsv(a5),d5
	addq.w	#1,d5
	move.w	d5,p_voice_rsv(a5)
1:
	move.b	d1,p_how_many(a5)
2:
	moveq.l	#0,d0
	move.b	p_next_on(a5),d0
	cmp.b	d5,d0
	bls	@f
	moveq.l	#0,d0
@@:
	move.l	d0,d6
	addq.w	#1,d6
	move.b	d6,p_next_on(a5)
3:
	move.l	d0,d6				*!save to d6
	tst.b	p_track_mode(a5)		*!ダンパーなどの時は発音前にキーオフ
	bpl	@f				*!
	bset.b	#b_keyoff,p_onoff_bit(a5)	*!set key off bit
	add.w	d4,d0				*!
	andi.w	#$0f,d0				*!
	bsr	pcm_key_off			*!
@@:						*!5/10
	move.l	d6,d1
	add.w	d6,d6
	add.w	d6,d6
	lea	p_note(a5,d6.w),a4
	move.b	d7,(a4)+		*note number
	move.b	d3,(a4)+		*velocity
	move.w	d2,(a4)			*gate time
	cmpi.w	#TIE_GATE,d2
	bne	set_ntonmk_ad
	clr.w	(a4)
set_ntonmk_ad:
	move.b	d7,(a3)+		*note number
	move.b	d3,(a3)+		*velocity
	move.w	d1,(a3)+		*note on markerにオフセットをセット
	move.l	p_bank_msb(a5),d1	*d1.l=bank.hw,timbre.lw
@@:
	btst.b	#b_split_mode,p_md_flg(a5)
	beq	@f
	bsr	do_timbre_split_ad
@@:					*d1.l=p_bank_msb.w,p_pgmをADPCM音色番号実行値に変換
	moveq.l	#0,d2
	move.w	d1,d2			*d2=pgm
	btst.b	#b_vtune_mode,p_md_flg(a5)
	beq	@f
	swap	d1
	move.w	d1,d0			*check bank_msb
	bmi	@f
	tst.b	d0			*check bank_lsb
	bmi	@f
	andi.w	#$00_7f,d2		*バンクモードの時にはpgm=0-127
	andi.w	#$00_7f,d1		*bank lsb
	andi.w	#$7f_00,d0		*bank msb
	lsr.w	#1,d0			*127倍
	or.w	d0,d1
	lsl.w	#7,d1
	add.w	d1,d2			*d2=(bank_msb*128+bank_lsb)*128+pgm
@@:
	move.l	d2,(a3)+
	st.b	(a3)			*end code
go_cpad:
	* > d1.w=step time
	* - d3.w (velocity)保存する
	* - d4.l (ch)保存する
	* X d0 d1 d2 d5 d6 / a1 a2 a4
*	tst.w	p_level_param(a5)
*	bne	@f
	andi.w	#$00f0,p_level_param(a5)	*!10/25
	or.w	#$0100,p_level_param(a5)	*!5/28
@@:
	move.w	(a5),d5			*get step & check step
	beq	next_cmd_ad
	bsr	fm_bend			*ベンドパラメータ
	bra	calc_param_ad

case_slur_ad:
	* < a4=スラーと判断されたp_noteX+4のアドレス
	* x d0,d5,a4
	move.w	(a5),d5
	tst.b	p_bend_sw(a5)
	ble	@f
	bsr	fm_bend
@@:
	bsr	tie_calc_param_ad
	move.w	d2,-(a4)		*set gate
	cmpi.w	#TIE_GATE,d2
	bne	@f
	clr.w	(a4)			*内部TIE_GATE(ただしまだd2.w=TIE_GATE)
@@:
	cmp.b	-(a4),d3
	beq	1f
	move.b	d3,(a4)			*ベロシティが違うなら新設定
*	tst.w	p_level_param(a5)
*	bne	1f
	andi.w	#$00f0,p_level_param(a5)	*!10/25
	or.w	#$0100,p_level_param(a5)	*!5/28
1:
	move.b	d7,-(a4)		*set note
	tst.w	p_pitch_param(a5)
	bne	@f
	move.w	#8,p_pitch_param(a5)
@@:
	rts

calc_param_ad:				*特殊コマンドのパラメータ計算
	bsr	calc_param_ad_aftc_0
	bsr	calc_param_ad_pmod_0
	bsr	calc_param_ad_arcc_0
	bra	calc_param_ad_agogik_0

same_note_ad:				*同じノートだった
	* < d6.w=ch N
	cmp.b	k_velo(a4),d3
	beq	1f
	move.b	d3,k_velo(a4)		*ベロシティが違うなら新設定
*	tst.w	p_level_param(a5)
*	bne	1f
	andi.w	#$00f0,p_level_param(a5)	*!10/25
	or.w	#$0100,p_level_param(a5)	*!5/28
1:
	move.w	d2,k_gate_time(a4)	*set gate time
	cmpi.w	#TIE_GATE,d2
	bne	@f
	clr.w	k_gate_time(a4)		*内部TIE_GATE
@@:
	move.w	(a5),d5			*check step
	beq	next_cmd_ad
	tst.b	p_bend_sw(a5)
	ble	@f
	bsr	fm_bend
@@:
*	bra	tie_calc_param_ad

tie_calc_param_ad:
	movem.l	d2/d7/a4,-(sp)
	bsr	tie_calc_param_ad_aftc_0
	bsr	tie_calc_param_ad_pmod_0
	bsr	tie_calc_param_ad_arcc_0
	bsr	tie_calc_param_ad_agogik_0
	movem.l	(sp)+,d2/d7/a4
	rts

*force_noteon_ad:			*強制的に次のチャンネルでキーオン
*	* < d0.b=p_next_on
*	* < d5.b=p_voice_rsv
*	* < a4.l=p_note+d0*4
*	* > d1.l=ptr
*	move.l	d0,d6			*save d0 into d6
*	move.l	d0,d1
*	addq.b	#1,d6
*	cmp.b	d5,d6
*	bls	@f
*	moveq.l	#0,d6			*始めに戻す
*	lea	p_note(a5),a4
*@@:
*	move.b	d6,p_next_on(a5)	*次回の発音チャンネル
*	bset.b	#b_keyoff,p_onoff_bit(a5)	*set key off bit
*	add.w	d4,d0
*	andi.w	#$0f,d0
*	bsr	pcm_key_off
*	move.b	d7,(a4)+		*note number
*	move.b	d3,(a4)+		*velocity
*	move.w	a2,(a4)+		*gate time
*	move.l	a3,d0
*	lea	p_key_on(a5),a3
*	sub.l	a3,d0
*	cmpi.l	#4*(16-1),d0
*	bls	set_ntonmk_ad
*	moveq.l	#(max_note_on-1)*2-1,d5
*@@:
*	move.l	8(a3),(a3)+
*	dbra	d5,@b
*	bra	set_ntonmk_ad
*-----------------------------------------------------------------------------
rest_ad:				*ADPCM/休符
	bsr	get_st_gt
rest_patch_ad:
	bsr	rest_ope
	move.l	d1,d5			*d1=d5=step
	beq	next_cmd_ad
	tst.l	d6
	bmi	tie_rest_calc_param_ad
	bsr	calc_param_ad_aftc_1
	bsr	calc_param_ad_pmod_1
	bsr	calc_param_ad_arcc_1
	bra	calc_param_ad_agogik_1

tie_rest_calc_param_ad:
	bsr	tie_calc_param_ad_aftc_1
	bsr	tie_calc_param_ad_pmod_1
	bsr	tie_calc_param_ad_arcc_1
	bra	tie_calc_param_ad_agogik_1

rest_fm:				*FM/休符
	bsr	get_st_gt
rest_patch_fm:
	bsr	rest_ope
	move.l	d1,d5			*d1=d5=step
	beq	next_cmd_fm
	tst.l	d6
	bmi	tie_rest_calc_param_fm
	bsr	calc_param_fm_aftc_1
	bsr	calc_param_fm_pmod_1
	bsr	calc_param_fm_arcc_1
	bra	calc_param_fm_agogik_1

tie_rest_calc_param_fm:
	bsr	tie_calc_param_fm_aftc_1
	bsr	tie_calc_param_fm_pmod_1
	bsr	tie_calc_param_fm_arcc_1
	bra	tie_calc_param_fm_agogik_1

rest_ope:
	moveq.l	#0,d6			*tie or not
	tst.b	p_how_many(a5)
	bmi	exit_dr			*case:all off
	move.w	p_voice_rsv(a5),d0	*loop counter
	lea	p_note+k_gate_time(a5),a1
dr_lp_f:
	move.w	(a1),d5
	cmpi.w	#MAX_GATE,d5
	beq	1f
	cmpi.w	#TIE_GATE_CODE,d5	*check gate time
	bne	@f
1:
	moveq.l	#-1,d6			*tie mark
	cmpi.w	#TIE_GATE,d2		*またさらにタイか
	beq	@f
	move.w	d2,(a1)			*set gate time
@@:
	addq.w	#k_note_len,a1
	dbra	d0,dr_lp_f
exit_dr:
	rts

rest_md:			*MIDI/休符
	bsr	timbre_set2
	bsr	get_st_gt
rest_patch_md:
	moveq.l	#0,d6			*tie or not
	moveq.l	#max_note_on-1,d0	*max note on
	lea	p_note(a5),a1
drm_lp0:
	move.l	(a1)+,d5		*note
	bmi	exit_rstmd		*exit
	cmpi.w	#MAX_GATE,d5
	beq	1f
	cmpi.w	#TIE_GATE_CODE,d5	*check gate time
	bne	@f
1:
	moveq.l	#-1,d6			*tie mark
	cmpi.w	#TIE_GATE,d2		*またさらにタイか
	beq	@f
	move.w	d2,-2(a1)		*set gate time
@@:
	dbra	d0,drm_lp0
exit_rstmd:
	move.l	d1,d5
	beq	next_cmd_md
	tst.l	d6
	bmi	tie_rest_calc_param_md
	bsr	calc_param_md_aftc_1
	bsr	calc_param_md_pmod_1
	bsr	calc_param_md_arcc_1
	bra	calc_param_md_agogik_1

tie_rest_calc_param_md:
	bsr	tie_calc_param_md_aftc_1
	bsr	tie_calc_param_md_pmod_1
	bsr	tie_calc_param_md_arcc_1
	bra	tie_calc_param_md_agogik_1
*-----------------------------------------------------------------------------
wait_md:			*ウェイト(MIDI)
	bsr	timbre_set2
	bsr	get_steptime
wait_patch_md:
	move.w	d1,(a5)
	rts

wait_fm:			*ウェイト(FM)
	bsr	get_steptime
wait_patch_fm:
	move.w	d1,(a5)
	rts

wait_ad:			*ウェイト(ADPCM)
	bsr	get_steptime
wait_patch_ad:
	move.w	d1,(a5)
	rts
*------------------------------------------------------------------------------
mx_key_md:				*MXDRV-conv用(MIDI)
	bsr	get_mxkey
	bra	case_key_patch_md

mx_key_ad:				*MXDRV-conv用(ADPCM)
	bsr	get_mxkey
	bra	case_key_patch_ad

mx_key_fm:				*MXDRV-conv用(FM)
	pea	case_key_patch_md(pc)

get_mxkey:
	move.b	(a0)+,d7		*get note number
	bsr	get_steptime
	move.w	d1,(a5)
	tst.b	d7
	bpl	@f			*note<0の場合はvelocityあり
	andi.w	#$007f,d7		*0-127
	move.w	#TIE_GATE,d2
	bra	1f
@@:
	bsr	calc_gate
1:
	move.l	a0,-(sp)
	lea	dummy_velo(pc),a0	*ダミーベロシティにポイントさせる
	bsr	get_def_velo
	move.l	(sp)+,a0
	rts
dummy_velo:	dc.b	$80
	.even

calc_gate:				*ゲートタイムの計算
	* < d1.w=step time
	* > d2.w=gate time
	* - d1
	move.w	p_Q_gate(a5),d2
	bmi	@f			*case:@Q
	mulu	d1,d2
	beq	1f
	lsr.l	#8,d2			*/256
	rts
@@:
	add.w	d1,d2
	bgt	exit_cg			*正常なケース
1:					*step-@Q<=0のケース/@Q=0のケース
	move.w	d1,d2
exit_cg:
	rts
*------------------------------------------------------------------------------
get_steptime:
	* > d1.w=steptime
	moveq.l	#0,d1
	move.b	(a0)+,d1
	bpl	@f
	add.b	d1,d1			*最上位ビット殺す
	lsl.w	#7,d1
	move.b	(a0)+,d1
@@:
	rts

get_st_gt:				*ステップ、ゲートの取りだし(休符ケース)
	* > d1=step
	* > d2=gate
	* x d0
	bsr	do_rest_vseq
	moveq.l	#0,d1
	move.b	(a0)+,d1
	bpl	@f
	add.b	d1,d1			*最上位ビット殺す
	lsl.w	#7,d1
	move.b	(a0)+,d1		*get word step
@@:
	move.w	d1,(a5)			*save p_step_time
	moveq.l	#0,d2
	move.b	(a0)+,d2
	bpl	@f			*0～127
	add.b	d2,d2			*最上位ビット殺す
	lsl.w	#7,d2
	move.b	(a0)+,d2		*get word gate
	tst.w	d2
	bne	@f
	move.w	#TIE_GATE,d2
@@:
exit_gsg:				*V2互換モードの時はパッチ(NOP)
	rts
	cmpi.w	#1,d1
	bne	@f
	move.w	#TIE_GATE,d2		*V2コンパチモードの時はstep=1は強制的にタイ
@@:
	rts

get_st_gt_vl:				*ステップ、ゲート、ベロシティの取りだし
	* > d1.l=step
	* > d2.l=gate
	* > d3.l=velocity param.(最上位bitが1の場合はデフォルト指定だった事を意味する)
	* x d0,d5
	moveq.l	#0,d1			*get step
	move.b	(a0)+,d1
	bpl	@f
	add.b	d1,d1			*最上位ビット殺す
	lsl.w	#7,d1
	move.b	(a0)+,d1		*get word step
@@:
	move.w	d1,(a5)			*save p_step_time

	moveq.l	#0,d2			*get gate
	move.b	(a0)+,d2
	bpl	@f			*0～127
	add.b	d2,d2			*最上位ビット殺す
	lsl.w	#7,d2
	move.b	(a0)+,d2		*get word gate
	tst.w	d2
	bne	@f
	move.w	#TIE_GATE,d2
@@:
get_def_velo:				*ベロシティ取りだし部
	bra.s	@f			*V2互換モードの時はパッチ(NOP)
	cmpi.w	#1,d1
	bne	@f
	move.w	#TIE_GATE,d2		*V2コンパチモードの時はstep=1は強制的にタイ
@@:
	moveq.l	#0,d5
	move.b	p_velo(a5),d5
*aftc_on?:				*アフタータッチシーケンス?
	tst.b	p_aftc_sw(a5)
	beq	vseq_on?
	tst.w	p_aftc_1st_dly(a5)	*始めにディレイがある時はdefault velocity
	bne	vseq_on?
	btst.b	#0,p_aftc_omt(a5)
	beq	vseq_on?
	tst.l	d4			*MIDIの場合はベロシティでノートオンするから
	bpl	2f			*aftertouchはaftertouchとして出力する
					*MIDIケース
	btst.b	#0,p_aftc_rltv(a5)
	beq	1f
	move.b	p_aftc_tbl(a5),d0
	bpl	@f
	add.b	d0,p_aftc_level(a5)
	bpl	vseq_on?
	clr.b	p_aftc_level(a5)
	bra	vseq_on?
@@:
	add.b	d0,p_aftc_level(a5)
	bpl	vseq_on?
	move.b	#127,p_aftc_level(a5)
	bra	vseq_on?
1:
	move.b	p_aftc_tbl(a5),p_aftc_level(a5)
	bra	vseq_on?
2:					*内蔵音源ケース
	btst.b	#0,p_aftc_rltv(a5)
	beq	@f
	moveq.l	#0,d0
	move.b	p_aftc_tbl(a5),d0
	ori.w	#$8000,d0
	swap	d0			*相対マーク
	or.l	d0,d5			*d5.hwに相対値を持っていっておく
	bra	vseq_on?
@@:
	move.b	p_aftc_tbl(a5),d5
vseq_on?:				*エンハンスド・ベロシティ・シーケンス?
	bsr	do_vseq
get_velo:
	moveq.l	#0,d3
	move.b	(a0)+,d3
	bpl	1f			*直接指定のケース
	cmpi.b	#128,d3
	beq	@f			*デフォルト選択の場合
	sub.b	#192,d3			*相対ケース
	ext.w	d3
	add.w	d5,d3
	bra	2f
@@:
	move.w	d5,d3
2:
	bset.l	#31,d3			*デフォルト選択/相対指定であるマーク
	reduce_vol	d3
1:
	tst.l	d4			*MIDI?
	bmi	2f
	tst.l	d5
	bpl	1f
	swap	d5
	tst.b	d5
	bpl	@f
	add.b	d5,d3
	bpl	1f
	clr.b	d3
	bra	1f
@@:
	add.b	d5,d3
	bpl	1f
	move.b	#127,d3			*わざと.b
1:
	move.b	d3,p_aftc_level(a5)	*便宜上セット
2:
	rts

do_rest_vseq:
	tst.b	p_vseq_param+p_arcc_sw(a5)
	beq	exit_do_vseq
	lea	p_vseq_param(a5),a4		*エンハンスド・ベロシティ・シーケンス処理
	btst.b	#b_arcc_rstsync,p_arcc_flg(a4)	*休符の時も進行?
	bne	@f
	bra	exit_do_vseq
do_vseq:
	tst.b	p_vseq_param+p_arcc_sw(a5)
	beq	exit_do_vseq
	lea	p_vseq_param(a5),a4		*エンハンスド・ベロシティ・シーケンス処理
	btst.b	#b_vseq_gvnsync,p_arcc_flg(a4)	*ベロシティが与えられている時も進行?
	bne	@f
	tst.b	(a0)				*plusなら直値指定なので無視
	bpl	exit_do_vseq
@@:
	bset.b	#b_arcc_first,p_arcc_flg(a4)
	bne	vsqop_2nd		*2回目以降の場合は別処理
					*以下、初めての場合
	move.w	p_arcc_syncnt(a4),p_arcc_syncnt2(a4)
	move.b	#2,p_arcc_chain(a4)	*即接続(つまり同期)	3/15
*!3/15	move.b	#1,p_arcc_chain(a4)	*接続待機
*!	tst.b	p_arcc_dpt_now(a4)
*!	bne	@f
*!	addq.b	#1,p_arcc_chain(a4)	*即接続(つまり同期)
*!@@:
	movem.l	d1-d2/d5,-(sp)
	moveq.l	#0,d5			*!dummy
	moveq.l	#0,d6			*!dummy
	bsr	fm_arcc
	movem.l	(sp)+,d1-d2/d5
	bra	1f
vsqop_2nd:				*2回目以降
	subq.w	#1,p_arcc_syncnt2(a4)
	bne	exit_do_vseq
	move.w	p_arcc_syncnt(a4),p_arcc_syncnt2(a4)
	tas.b	p_trk_seq_flg(a5)	*b_vseq_done
	bmi	1f			*一度やったら更新しない
	movem.l	d1-d2/a0,-(sp)
	addq.w	#1,a0			*便宜上
	bsr	vseq_entry
	movem.l	(sp)+,d1-d2/a0
1:
	move.b	p_arcc_level(a4),d0
	ext.w	d0
	move.w	#0,d5			*わざとd5.w
	move.b	p_arcc_origin(a4),d5	*SPECIAL ENHANCED VELOCITY SEQUENCEの場合
	btst.b	#b_arcc_phase,p_arcc_flg2(a4)
	beq	@f
	sub.w	d0,d5
	bra	1f
@@:
	add.w	d0,d5
1:
exit_do_vseq:
	rts

calc_param_fm_aftc_0:
calc_param_ad_aftc_0:
	tst.b	p_aftc_sw(a5)
	beq	1f
	tst.b	p_aftc_flg(a5)
	bmi	@f
	bset.b	#b_aftc_first,p_aftc_flg(a5)	*最初ならばホールドでもパラメータ計算
	beq	fm_aftc				*not first time
1:
	rts
@@:
	bset.b	#b_aftc_first,p_aftc_flg(a5)
	beq	@f
	subq.w	#1,p_aftc_syncnt2(a5)
	bne	1b
@@:
	move.w	p_aftc_syncnt(a5),p_aftc_syncnt2(a5)
	bra	fm_aftc

calc_param_fm_aftc_1:
calc_param_ad_aftc_1:
	tst.b	p_aftc_sw(a5)
	beq	1f
	btst.b	#b_aftc_rstsync,p_aftc_flg(a5)
	bne	@f
	bset.b	#b_aftc_first,p_aftc_flg(a5)	*最初ならばホールドでもパラメータ計算
	beq	fm_aftc				*not first time
1:
	rts
@@:
	bset.b	#b_aftc_first,p_aftc_flg(a5)
	beq	@f
	subq.w	#1,p_aftc_syncnt2(a5)
	bne	1b
@@:
	move.w	p_aftc_syncnt(a5),p_aftc_syncnt2(a5)
	bra	fm_aftc			*アフタータッチパラメータ

calc_param_fm_pmod_0:
calc_param_ad_pmod_0:
	tst.b	p_pmod_sw(a5)
	beq	1f
	tst.b	p_pmod_flg(a5)		*(b_pmod_sync)
	bmi	@f
	bset.b	#b_pmod_first,p_pmod_flg(a5)	*最初ならばホールドでもパラメータ計算
	beq	2f				*not first time
1:
	rts
@@:
	bset.b	#b_pmod_first,p_pmod_flg(a5)
	beq	2f
	subq.w	#1,p_pmod_syncnt2(a5)
	bne	1b
2:
	move.w	p_pmod_syncnt(a5),p_pmod_syncnt2(a5)
	move.b	#2,p_pmod_chain(a5)	*即接続(つまり同期)
	moveq.l	#4,d6
	bra	fm_pmod			*モジュレーションパラメータ

calc_param_fm_pmod_1:				*rest case
calc_param_ad_pmod_1:				*rest case
	tst.b	p_pmod_sw(a5)
	beq	1f
	btst.b	#b_pmod_rstsync,p_pmod_flg(a5)
	bne	@f
*!3/26	bset.b	#b_pmod_first,p_pmod_flg(a5)	*最初ならばホールドでもパラメータ計算
*!3/26	beq	2f				*not first time
1:
	rts
@@:
	bset.b	#b_pmod_first,p_pmod_flg(a5)
	beq	2f
	subq.w	#1,p_pmod_syncnt2(a5)
	bne	1b
2:
	move.w	p_pmod_syncnt(a5),p_pmod_syncnt2(a5)
	move.b	#2,p_pmod_chain(a5)	*即接続(つまり同期)
	moveq.l	#4,d6
	bra	fm_pmod			*モジュレーションパラメータ

calc_param_fm_arcc_0:
calc_param_ad_arcc_0:
	move.w	#$0080,d6
	moveq.l	#arcc_max-1,d7
	lea	p_arcc_param(a5),a4
@@:
	tst.b	p_arcc_sw(a4)
	beq	3f
	tst.b	p_arcc_flg(a4)			*(b_arcc_sync)
	bmi	1f
	bset.b	#b_arcc_first,p_arcc_flg(a4)	*最初ならばホールドでもパラメータ計算
	beq	2f
	lea	__arcc_len(a4),a4
	lsr.b	#1,d6
	dbra	d7,@b
	rts
1:
	bset.b	#b_arcc_first,p_arcc_flg(a4)
	beq	2f
	subq.w	#1,p_arcc_syncnt2(a4)
	bne	3f
2:
	move.w	p_arcc_syncnt(a4),p_arcc_syncnt2(a4)
	move.b	#2,p_arcc_chain(a4)		*即接続(つまり同期)
	bsr	fm_arcc
3:
	lea	__arcc_len(a4),a4
	lsr.b	#1,d6
	dbra	d7,@b
	rts

calc_param_fm_arcc_1:
calc_param_ad_arcc_1:
	move.w	#$0080,d6
	moveq.l	#arcc_max-1,d7
	lea	p_arcc_param(a5),a4
@@:
	tst.b	p_arcc_sw(a4)
	beq	3f
	btst.b	#b_arcc_rstsync,p_arcc_flg(a4)
	bne	1f
	bset.b	#b_arcc_first,p_arcc_flg(a4)	*最初ならばホールドでもパラメータ計算
	beq	2f
	lea	__arcc_len(a4),a4
	lsr.b	#1,d6
	dbra	d7,@b
	rts
1:
	bset.b	#b_arcc_first,p_arcc_flg(a4)
	beq	2f
	subq.w	#1,p_arcc_syncnt2(a4)
	bne	3f
2:
	move.w	p_arcc_syncnt(a4),p_arcc_syncnt2(a4)
	move.b	#2,p_arcc_chain(a4)		*即接続(つまり同期)
	bsr	fm_arcc
3:
	lea	__arcc_len(a4),a4
	lsr.b	#1,d6
	dbra	d7,@b
	rts

calc_param_fm_agogik_0:
calc_param_ad_agogik_0:
calc_param_md_agogik_0:
	btst.b	#b_agogik_trmk,p_agogik_flg(a5)
	beq	3f
	move.l	a5,a4
	lea.l	agogik_base(a6),a5
	btst.b	#_ID_SE,p_track_stat(a4)
	beq	@f
	lea.l	agogik_base_se(a6),a5
@@:
	tst.b	p_pmod_sw(a5)
	beq	2f
	tst.b	p_agogik_flg(a4)		*b_agogik_sync
	bmi	@f
	bset.b	#b_pmod_first,p_pmod_flg(a5)	*最初ならばホールドでもパラメータ計算
	beq	1f
	move.l	a4,a5
	rts
@@:
	bset.b	#b_pmod_first,p_pmod_flg(a5)
	beq	1f
	subq.w	#1,p_pmod_syncnt2(a5)
	bne	2f
1:
	move.w	p_pmod_syncnt(a5),p_pmod_syncnt2(a5)
	move.b	#2,p_pmod_chain(a5)		*即接続(つまり同期)
	moveq.l	#0,d6
	bsr	fm_pmod				*モジュレーションパラメータ
2:
	move.l	a4,a5
3:
	rts

calc_param_fm_agogik_1:
calc_param_ad_agogik_1:
calc_param_md_agogik_1:
	btst.b	#b_agogik_trmk,p_agogik_flg(a5)
	beq	3f
	move.l	a5,a4
	lea.l	agogik_base(a6),a5
	btst.b	#_ID_SE,p_track_stat(a4)
	beq	@f
	lea.l	agogik_base_se(a6),a5
@@:
	tst.b	p_pmod_sw(a5)
	beq	2f
	btst.b	#b_agogik_rstsync,p_agogik_flg(a4)
	bne	@f
	bset.b	#b_pmod_first,p_pmod_flg(a5)	*最初ならばホールドでもパラメータ計算
	beq	1f
	move.l	a4,a5
	rts
@@:
	bset.b	#b_pmod_first,p_pmod_flg(a5)
	beq	1f
	subq.w	#1,p_pmod_syncnt2(a5)
	bne	2f
1:
	move.w	p_pmod_syncnt(a5),p_pmod_syncnt2(a5)
	move.b	#2,p_pmod_chain(a5)		*即接続(つまり同期)
	moveq.l	#0,d6
	bsr	fm_pmod				*モジュレーションパラメータ
2:
	move.l	a4,a5
3:
	rts

tie_calc_param_fm_aftc_0:
tie_calc_param_ad_aftc_0:
	tst.b	p_aftc_sw(a5)
	beq	1f
	btst.b	#b_aftc_tiesync,p_aftc_flg(a5)	*タイ／スラー・ケースではホールドか
	bne	@f				*hold
	bset.b	#b_aftc_first,p_aftc_flg(a5)	*最初ならばホールドでもパラメータ計算
	beq	fm_aftc
1:
	rts
@@:
	bset.b	#b_aftc_first,p_aftc_flg(a5)
	beq	@f
	subq.w	#1,p_aftc_syncnt2(a5)
	bne	1b
@@:
	move.w	p_aftc_syncnt(a5),p_aftc_syncnt2(a5)
	bra	fm_aftc				*sync

tie_calc_param_fm_pmod_0:
tie_calc_param_ad_pmod_0:
	tst.b	p_pmod_sw(a5)
	beq	1f
	btst.b	#b_pmod_tiesync,p_pmod_flg(a5)	*タイ／スラー・ケースではホールドか
	bne	@f				*hold
	bset.b	#b_pmod_first,p_pmod_flg(a5)	*最初ならばホールドでもパラメータ計算
	beq	3f
1:
	rts
@@:
	bset.b	#b_pmod_first,p_pmod_flg(a5)
	beq	3f
	subq.w	#1,p_pmod_syncnt2(a5)
	bne	1b
2:
	move.w	p_pmod_syncnt(a5),p_pmod_syncnt2(a5)
	move.b	#1,p_pmod_chain(a5)		*接続待機
	tst.w	p_pmod_dpt_now(a5)
	bne	@f
	addq.b	#1,p_pmod_chain(a5)		*即接続(つまり同期)
@@:
	moveq.l	#4,d6
	bra	fm_pmod				*sync
3:
	move.w	p_pmod_syncnt(a5),p_pmod_syncnt2(a5)
	move.b	#2,p_pmod_chain(a5)		*即接続(つまり同期)
	moveq.l	#4,d6
	bra	fm_pmod				*sync

tie_calc_param_fm_aftc_1:
tie_calc_param_ad_aftc_1:
	tst.b	p_aftc_sw(a5)
	beq	2f
	btst.b	#b_aftc_rstsync,p_aftc_flg(a5)
	beq	1f
	btst.b	#b_aftc_tiesync,p_aftc_flg(a5)	*タイ／スラー・ケースではホールドか
	bne	@f				*hold
1:
	bset.b	#b_aftc_first,p_aftc_flg(a5)	*最初ならばホールドでもパラメータ計算
	beq	fm_aftc
2:
	rts
@@:
	bset.b	#b_aftc_first,p_aftc_flg(a5)
	beq	@f
	subq.w	#1,p_aftc_syncnt2(a5)
	bne	2b
@@:
	move.w	p_aftc_syncnt(a5),p_aftc_syncnt2(a5)
	bra	fm_aftc				*sync

tie_calc_param_fm_pmod_1:			*rest case
tie_calc_param_ad_pmod_1:			*rest case
	tst.b	p_pmod_sw(a5)
	beq	2f
	btst.b	#b_pmod_rstsync,p_pmod_flg(a5)
	beq	1f
*!3/26	btst.b	#b_pmod_tiesync,p_pmod_flg(a5)	*タイ／スラー・ケースではホールドか
*!3/26	bne	@f				*hold
1:
	bset.b	#b_pmod_first,p_pmod_flg(a5)	*最初ならばホールドでもパラメータ計算
	beq	4f
2:
	rts
@@:
	bset.b	#b_pmod_first,p_pmod_flg(a5)
	beq	4f
	subq.w	#1,p_pmod_syncnt2(a5)
	bne	2b
3:
	move.w	p_pmod_syncnt(a5),p_pmod_syncnt2(a5)
	move.b	#1,p_pmod_chain(a5)		*接続待機
	tst.w	p_pmod_dpt_now(a5)
	bne	@f
	addq.b	#1,p_pmod_chain(a5)		*即接続(つまり同期)
@@:
	moveq.l	#4,d6
	bra	fm_pmod				*sync
4:
	move.w	p_pmod_syncnt(a5),p_pmod_syncnt2(a5)
	move.b	#2,p_pmod_chain(a5)		*即接続(つまり同期)
	moveq.l	#4,d6
	bra	fm_pmod				*sync

tie_calc_param_fm_arcc_0:
tie_calc_param_ad_arcc_0:
	move.w	#$0080,d6
	moveq.l	#arcc_max-1,d7
	lea	p_arcc_param(a5),a4
@@:
	tst.b	p_arcc_sw(a4)
	beq	4f
	btst.b	#b_arcc_tiesync,p_arcc_flg(a4)	*タイ／スラー・ケースではホールドか
	bne	1f				*=0:hold =1:sync
	bset.b	#b_arcc_first,p_arcc_flg(a4)	*最初ならばホールドでもパラメータ計算
	beq	5f
	lea	__arcc_len(a4),a4
	lsr.b	#1,d6
	dbra	d7,@b
	rts
1:
	bset.b	#b_arcc_first,p_arcc_flg(a4)
	beq	5f
	subq.w	#1,p_arcc_syncnt2(a4)
	bne	4f
2:
	move.w	p_arcc_syncnt(a4),p_arcc_syncnt2(a4)
	move.b	#1,p_arcc_chain(a4)		*接続待機
	tst.b	p_arcc_dpt_now(a4)
	bne	3f
	addq.b	#1,p_arcc_chain(a4)		*即接続(つまり同期)
3:
	bsr	fm_arcc				*sync
4:
	lea	__arcc_len(a4),a4
	lsr.b	#1,d6
	dbra	d7,@b
	rts
5:
	move.w	p_arcc_syncnt(a4),p_arcc_syncnt2(a4)
	move.b	#2,p_arcc_chain(a4)		*即接続(つまり同期)
	bsr	fm_arcc				*sync
	lea	__arcc_len(a4),a4
	lsr.b	#1,d6
	dbra	d7,@b
	rts

tie_calc_param_fm_arcc_1:
tie_calc_param_ad_arcc_1:
	move.w	#$0080,d6
	moveq.l	#arcc_max-1,d7
	lea	p_arcc_param(a5),a4
@@:
	tst.b	p_arcc_sw(a4)
	beq	5f
	btst.b	#b_arcc_rstsync,p_arcc_flg(a4)
	beq	1f
	btst.b	#b_arcc_tiesync,p_arcc_flg(a4)	*タイ／スラー・ケースではホールドか
	bne	2f				*=0:hold =1:sync
1:
	bset.b	#b_arcc_first,p_arcc_flg(a4)	*最初ならばホールドでもパラメータ計算
	beq	6f
	lea	__arcc_len(a4),a4
	lsr.b	#1,d6
	dbra	d7,@b
	rts
2:
	bset.b	#b_arcc_first,p_arcc_flg(a4)
	beq	6f
	subq.w	#1,p_arcc_syncnt2(a4)
	bne	5f
3:
	move.w	p_arcc_syncnt(a4),p_arcc_syncnt2(a4)
	move.b	#1,p_arcc_chain(a4)		*接続待機
	tst.b	p_arcc_dpt_now(a4)
	bne	4f
	addq.b	#1,p_arcc_chain(a4)		*即接続(つまり同期)
4:
	bsr	fm_arcc				*sync
5:
	lea	__arcc_len(a4),a4
	lsr.b	#1,d6
	dbra	d7,@b
	rts
6:
	move.w	p_arcc_syncnt(a4),p_arcc_syncnt2(a4)
	move.b	#2,p_arcc_chain(a4)		*即接続(つまり同期)
	bsr	fm_arcc				*sync
	lea	__arcc_len(a4),a4
	lsr.b	#1,d6
	dbra	d7,@b
	rts


tie_calc_param_fm_agogik_0:
tie_calc_param_ad_agogik_0:
tie_calc_param_md_agogik_0:
	btst.b	#b_agogik_trmk,p_agogik_flg(a5)
	beq	4f
	move.l	a5,a4
	lea.l	agogik_base(a6),a5
	btst.b	#_ID_SE,p_track_stat(a4)
	beq	@f
	lea.l	agogik_base_se(a6),a5
@@:
	tst.b	p_pmod_sw(a5)
	beq	3f
	btst.b	#b_agogik_tiesync,p_agogik_flg(a4)	*タイ／スラー・ケースではホールドか
	bne	@f				*hold
1:
	bset.b	#b_pmod_first,p_pmod_flg(a5)	*最初ならばホールドでもパラメータ計算
	beq	5f
	move.l	a4,a5
	rts
@@:
	bset.b	#b_pmod_first,p_pmod_flg(a5)
	beq	5f
	subq.w	#1,p_pmod_syncnt2(a5)
	bne	3f
2:
	move.w	p_pmod_syncnt(a5),p_pmod_syncnt2(a5)
	move.b	#1,p_pmod_chain(a5)		*接続待機
	tst.w	p_pmod_dpt_now(a5)
	bne	@f
	addq.b	#1,p_pmod_chain(a5)		*即接続(つまり同期)
@@:
	moveq.l	#0,d6
	bsr	fm_pmod				*sync
3:
	move.l	a4,a5
4:
	rts
5:
	move.w	p_pmod_syncnt(a5),p_pmod_syncnt2(a5)
	move.b	#2,p_pmod_chain(a5)		*即接続(つまり同期)
	moveq.l	#0,d6
	bsr	fm_pmod				*sync
	move.l	a4,a5
	rts

tie_calc_param_fm_agogik_1:
tie_calc_param_ad_agogik_1:
tie_calc_param_md_agogik_1:
	btst.b	#b_agogik_trmk,p_agogik_flg(a5)
	beq	4f
	move.l	a5,a4
	lea.l	agogik_base(a6),a5
	btst.b	#_ID_SE,p_track_stat(a4)
	beq	@f
	lea.l	agogik_base_se(a6),a5
@@:
	tst.b	p_pmod_sw(a5)
	beq	3f
	btst.b	#b_agogik_rstsync,p_agogik_flg(a4)
	beq	1f
	btst.b	#b_agogik_tiesync,p_agogik_flg(a4)	*タイ／スラー・ケースではホールドか
	bne	@f				*hold
1:
	bset.b	#b_pmod_first,p_pmod_flg(a5)	*最初ならばホールドでもパラメータ計算
	beq	5f
	move.l	a4,a5
	rts
@@:
	bset.b	#b_pmod_first,p_pmod_flg(a5)
	beq	5f
	subq.w	#1,p_pmod_syncnt2(a5)
	bne	3f
2:
	move.w	p_pmod_syncnt(a5),p_pmod_syncnt2(a5)
	move.b	#1,p_pmod_chain(a5)		*接続待機
	tst.w	p_pmod_dpt_now(a5)
	bne	@f
	addq.b	#1,p_pmod_chain(a5)		*即接続(つまり同期)
@@:
	moveq.l	#0,d6
	bsr	fm_pmod				*sync
3:
	move.l	a4,a5
4:
	rts
5:
	move.w	p_pmod_syncnt(a5),p_pmod_syncnt2(a5)
	move.b	#2,p_pmod_chain(a5)		*即接続(つまり同期)
	moveq.l	#0,d6
	bsr	fm_pmod				*sync
	move.l	a4,a5
	rts

tie_calc_param_md_aftc_0:
	tst.b	p_aftc_sw(a5)
	beq	1f
	btst.b	#b_aftc_tiesync,p_aftc_flg(a5)	*タイ／スラー・ケースではホールドか
	bne	@f				*hold
	bset.b	#b_aftc_first,p_aftc_flg(a5)	*最初ならばホールドでもパラメータ計算
	beq	midi_aftc
1:
	rts
@@:
	bset.b	#b_aftc_first,p_aftc_flg(a5)
	beq	@f
	subq.w	#1,p_aftc_syncnt2(a5)
	bne	1b
@@:
	move.w	p_aftc_syncnt(a5),p_aftc_syncnt2(a5)
	bra	midi_aftc			*sync

tie_calc_param_md_aftc_1:
	tst.b	p_aftc_sw(a5)
	beq	2f
	btst.b	#b_aftc_rstsync,p_aftc_flg(a5)
	beq	1f
	btst.b	#b_aftc_tiesync,p_aftc_flg(a5)	*タイ／スラー・ケースではホールドか
	bne	@f				*hold
1:
	bset.b	#b_aftc_first,p_aftc_flg(a5)	*最初ならばホールドでもパラメータ計算
	beq	midi_aftc
2:
	rts
@@:
	bset.b	#b_aftc_first,p_aftc_flg(a5)
	beq	@f
	subq.w	#1,p_aftc_syncnt2(a5)
	bne	2b
@@:
	move.w	p_aftc_syncnt(a5),p_aftc_syncnt2(a5)
	bra	midi_aftc			*sync

tie_calc_param_md_pmod_0:
	tst.b	p_pmod_sw(a5)
	beq	1f
	btst.b	#b_pmod_tiesync,p_pmod_flg(a5)	*タイ／スラー・ケースではホールドか
	bne	@f				*hold
	bset.b	#b_pmod_first,p_pmod_flg(a5)	*最初ならばホールドでもパラメータ計算
	beq	3f
1:
	rts
@@:
	bset.b	#b_pmod_first,p_pmod_flg(a5)
	beq	3f
	subq.w	#1,p_pmod_syncnt2(a5)
	bne	1b
2:
	move.w	p_pmod_syncnt(a5),p_pmod_syncnt2(a5)
	move.b	#1,p_pmod_chain(a5)		*接続待機
	tst.w	p_pmod_dpt_now(a5)
	bne	@f
	addq.b	#1,p_pmod_chain(a5)		*即接続(つまり同期)
@@:
	moveq.l	#4,d6
	bra	midi_pmod			*sync
3:
	move.w	p_pmod_syncnt(a5),p_pmod_syncnt2(a5)
	move.b	#2,p_pmod_chain(a5)		*即接続(つまり同期)
	moveq.l	#4,d6
	bra	midi_pmod			*sync

tie_calc_param_md_pmod_1:			*rest case
	tst.b	p_pmod_sw(a5)
	beq	2f
	btst.b	#b_pmod_rstsync,p_pmod_flg(a5)
	beq	1f
*!3/26	btst.b	#b_pmod_tiesync,p_pmod_flg(a5)	*タイ／スラー・ケースではホールドか
*!3/26	bne	@f				*hold
1:
	bset.b	#b_pmod_first,p_pmod_flg(a5)	*最初ならばホールドでもパラメータ計算
	beq	4f
2:
	rts
@@:
	bset.b	#b_pmod_first,p_pmod_flg(a5)
	bne	4f
	subq.w	#1,p_pmod_syncnt2(a5)
	bne	2b
3:
	move.w	p_pmod_syncnt(a5),p_pmod_syncnt2(a5)
	move.b	#1,p_pmod_chain(a5)		*接続待機
	tst.w	p_pmod_dpt_now(a5)
	bne	@f
	addq.b	#1,p_pmod_chain(a5)		*即接続(つまり同期)
@@:
	moveq.l	#4,d6
	bra	midi_pmod			*sync
4:
	move.w	p_pmod_syncnt(a5),p_pmod_syncnt2(a5)
	move.b	#2,p_pmod_chain(a5)		*即接続(つまり同期)
	moveq.l	#4,d6
	bra	midi_pmod			*sync

tie_calc_param_md_arcc_0:
	move.w	#$0080,d6
	moveq.l	#arcc_max-1,d7
	lea	p_arcc_param(a5),a4
@@:
	tst.b	p_arcc_sw(a4)
	beq	5f
	btst.b	#b_arcc_tiesync,p_arcc_flg(a4)	*タイ／スラー・ケースではホールドか
	bne	2f				*hold
1:
	bset.b	#b_arcc_first,p_arcc_flg(a4)	*最初ならばホールドでもパラメータ計算
	beq	6f
	lea	__arcc_len(a4),a4
	lsr.b	#1,d6
	dbra	d7,@b
	rts
2:
	bset.b	#b_arcc_first,p_arcc_flg(a4)
	beq	6f
	subq.w	#1,p_arcc_syncnt2(a4)
	bne	5f
3:
	move.w	p_arcc_syncnt(a4),p_arcc_syncnt2(a4)
	move.b	#1,p_arcc_chain(a4)		*接続待機
	tst.b	p_arcc_dpt_now(a4)
	bne	4f
	addq.b	#1,p_arcc_chain(a4)		*即接続(つまり同期)
4:
	bsr	midi_arcc			*sync
5:
	lea	__arcc_len(a4),a4
	lsr.b	#1,d6
	dbra	d7,@b
	rts
6:
	move.w	p_arcc_syncnt(a4),p_arcc_syncnt2(a4)
	move.b	#2,p_arcc_chain(a4)		*即接続(つまり同期)
	bsr	midi_arcc			*sync
	lea	__arcc_len(a4),a4
	lsr.b	#1,d6
	dbra	d7,@b
	rts

tie_calc_param_md_arcc_1:
	move.w	#$0080,d6
	moveq.l	#arcc_max-1,d7
	lea	p_arcc_param(a5),a4
@@:
	tst.b	p_arcc_sw(a4)
	beq	5f
	btst.b	#b_arcc_rstsync,p_arcc_flg(a4)
	beq	1f
	btst.b	#b_arcc_tiesync,p_arcc_flg(a4)	*タイ／スラー・ケースではホールドか
	bne	2f				*hold
1:
	bset.b	#b_arcc_first,p_arcc_flg(a4)	*最初ならばホールドでもパラメータ計算
	beq	6f
	lea	__arcc_len(a4),a4
	lsr.b	#1,d6
	dbra	d7,@b
	rts
2:
	bset.b	#b_arcc_first,p_arcc_flg(a4)
	beq	6f
	subq.w	#1,p_arcc_syncnt2(a4)
	bne	5f
3:
	move.w	p_arcc_syncnt(a4),p_arcc_syncnt2(a4)
	move.b	#1,p_arcc_chain(a4)		*接続待機
	tst.b	p_arcc_dpt_now(a4)
	bne	4f
	addq.b	#1,p_arcc_chain(a4)		*即接続(つまり同期)
4:
	bsr	midi_arcc			*sync
5:
	lea	__arcc_len(a4),a4
	lsr.b	#1,d6
	dbra	d7,@b
	rts
6:
	move.w	p_arcc_syncnt(a4),p_arcc_syncnt2(a4)
	move.b	#2,p_arcc_chain(a4)		*即接続(つまり同期)
	bsr	midi_arcc			*sync
	lea	__arcc_len(a4),a4
	lsr.b	#1,d6
	dbra	d7,@b
	rts

calc_param_md_aftc_0:
	tst.b	p_aftc_sw(a5)
	beq	1f
	tst.b	p_aftc_flg(a5)
	bmi	@f
	bset.b	#b_aftc_first,p_aftc_flg(a5)
	beq	midi_aftc
1:
	rts
@@:
	bset.b	#b_aftc_first,p_aftc_flg(a5)
	beq	@f
	subq.w	#1,p_aftc_syncnt2(a5)
	bne	1b
@@:
	move.w	p_aftc_syncnt(a5),p_aftc_syncnt2(a5)
	bra	midi_aftc		*アフタータッチパラメータ

calc_param_md_aftc_1:
	tst.b	p_aftc_sw(a5)
	beq	1f
	btst.b	#b_aftc_rstsync,p_aftc_flg(a5)
	bne	@f
	bset.b	#b_aftc_first,p_aftc_flg(a5)
	beq	midi_aftc
1:
	rts
@@:
	bset.b	#b_aftc_first,p_aftc_flg(a5)
	beq	@f
	subq.w	#1,p_aftc_syncnt2(a5)
	bne	1b
@@:
	move.w	p_aftc_syncnt(a5),p_aftc_syncnt2(a5)
	bra	midi_aftc		*アフタータッチパラメータ

calc_param_md_pmod_0:
	tst.b	p_pmod_sw(a5)
	beq	1f
	tst.b	p_pmod_flg(a5)		*(b_pmod_sync)
	bmi	@f
	bset.b	#b_pmod_first,p_pmod_flg(a5)	*最初ならばホールドでもパラメータ計算
	beq	2f
1:
	rts
@@:
	bset.b	#b_pmod_first,p_pmod_flg(a5)
	beq	2f
	subq.w	#1,p_pmod_syncnt2(a5)
	bne	1b
2:
	move.w	p_pmod_syncnt(a5),p_pmod_syncnt2(a5)
	move.b	#2,p_pmod_chain(a5)		*即接続(つまり同期)
	moveq.l	#4,d6
	bra	midi_pmod			*モジュレーションパラメータ

calc_param_md_pmod_1:				*rest case
	tst.b	p_pmod_sw(a5)
	beq	1f
	btst.b	#b_pmod_rstsync,p_pmod_flg(a5)
	bne	@f
*!3/26	bset.b	#b_pmod_first,p_pmod_flg(a5)	*最初ならばホールドでもパラメータ計算
*!3/26	beq	2f
1:
	rts
@@:
	bset.b	#b_pmod_first,p_pmod_flg(a5)
	beq	2f
	subq.w	#1,p_pmod_syncnt2(a5)
	bne	1b
2:
	move.w	p_pmod_syncnt(a5),p_pmod_syncnt2(a5)
	move.b	#2,p_pmod_chain(a5)		*即接続(つまり同期)
	moveq.l	#4,d6
	bra	midi_pmod			*モジュレーションパラメータ

calc_param_md_arcc_0:
	move.w	#$0080,d6
	moveq.l	#arcc_max-1,d7
	lea	p_arcc_param(a5),a4
@@:
	tst.b	p_arcc_sw(a4)
	beq	3f
	tst.b	p_arcc_flg(a4)		*(b_arcc_sync)
	bmi	1f			*no
	bset.b	#b_arcc_first,p_arcc_flg(a4)	*最初ならばホールドでもパラメータ計算
	beq	2f
	lea	__arcc_len(a4),a4
	lsr.b	#1,d6
	dbra	d7,@b
	rts
1:
	bset.b	#b_arcc_first,p_arcc_flg(a4)
	beq	2f
	subq.w	#1,p_arcc_syncnt2(a4)
	bne	3f
2:
	move.w	p_arcc_syncnt(a4),p_arcc_syncnt2(a4)
	move.b	#2,p_arcc_chain(a4)		*即接続(つまり同期)
	bsr	midi_arcc
3:
	lea	__arcc_len(a4),a4
	lsr.b	#1,d6
	dbra	d7,@b
	rts

calc_param_md_arcc_1:
	move.w	#$0080,d6
	moveq.l	#arcc_max-1,d7
	lea	p_arcc_param(a5),a4
@@:
	tst.b	p_arcc_sw(a4)
	beq	3f
	btst.b	#b_arcc_rstsync,p_arcc_flg(a4)
	bne	1f
	bset.b	#b_arcc_first,p_arcc_flg(a4)	*最初ならばホールドでもパラメータ計算
	beq	2f
	lea	__arcc_len(a4),a4
	lsr.b	#1,d6
	dbra	d7,@b
	rts
1:
	bset.b	#b_arcc_first,p_arcc_flg(a4)
	beq	2f
	subq.w	#1,p_arcc_syncnt2(a4)
	bne	3f
2:
	move.w	p_arcc_syncnt(a4),p_arcc_syncnt2(a4)
	move.b	#2,p_arcc_chain(a4)		*即接続(つまり同期)
	bsr	midi_arcc
3:
	lea	__arcc_len(a4),a4
	lsr.b	#1,d6
	dbra	d7,@b
	rts

fm_bend:				*ベンドパラメータの計算
midi_bend:
	tst.b	p_port_flg(a5)
	bne	exit_fm_bend		*ポルタメント中はオートベンドしない
	tst.b	p_bend_sw(a5)
	beq	exit_fm_bend
	tas.b	p_bend_sw(a5)		*firstマーク
	ori.w	#2,p_pitch_param(a5)	*mark
	moveq.l	#0,d6
	move.l	d6,p_port_pitch(a5)	*ちゃっかり初期化
	move.l	d6,p_port_step(a5)	*一応初期化
	move.w	p_bend_dly(a5),d6	*ベンドディレイ値を
	bpl	@f
	move.w	d6,d1
	neg.w	d1
	add.w	d5,d6
	ble	exit_fm_bend		*delayの方が大きい場合
	move.w	d6,p_port_dly(a5)	*portament delayの所にセット
	bra	1f
@@:
	move.w	d6,p_port_dly(a5)	*portament delayの所にセット
	move.w	d5,d1			*get step
	sub.w	d6,d1			*step=step-delay->port time
	ble	exit_fm_bend		*delayの方が大きい場合
1:
	move.w	p_bend_cnt(a5),d6	*minus:tail,plus:port time
	beq	prprbd00
	bpl	@f
	add.w	d6,d1
	bgt	prprbd00		*tailの方が大きい場合は
	sub.w	d6,d1			*さっきの演算(add.w d6,d1)はなかったことにする
	bra	prprbd00
@@:
	cmp.w	d1,d6
	bcc	@f
	move.l	d6,d1
prprbd00:
	move.w	d1,p_port_cnt(a5)
	move.w	p_bend_dst(a5),d6
	sub.w	p_detune(a5),d6
	bmi	@f
	divu	d1,d6		*d6=range/L d6.w=step counter
	move.w	d6,d0
	clr.w	d6
	divu	d1,d6		*d6=d6/L
	swap	d0
	move.w	d6,d0
	addq.l	#1,d0
	move.l	d0,p_port_step(a5)
	rts
@@:
	neg.w	d6
	divu	d1,d6		*d6=range/L d6.w=step counter
	move.w	d6,d0
	clr.w	d6
	divu	d1,d6		*d6=d6/L
	swap	d0
	move.w	d6,d0
	neg.l	d0
	move.l	d0,p_port_step(a5)
exit_fm_bend:
	rts

fm_aftc:			*アフタータッチシーケンスパラメータ
	tst.b	p_aftc_sw(a5)
	beq	exit_fm_aftc	*0(off)
	bpl	@f		*1(optionl mode case)
	ori.w	#2,p_level_param(a5)	*mark(midi_aftcとはこれが有るか無いかの違いだけ)
	move.l	d5,d1
	lsr.w	#3,d1		*d1=step/8
				*ゼロになっちゃっても後でつじつまが合うから大丈夫
	move.w	d1,p_aftc_dly2(a5)
	lea	p_aftc_8st_tbl+2(a5),a1
	rept	aftc_max-1
	move.w	d1,(a1)+	*1/8ステップを８-1個分書く
	endm
	clr.b	p_aftc_n(a5)	*init pointer
	rts
@@:				*任意モードの場合
	ori.w	#2,p_level_param(a5)	*mark(midi_aftcとはこれが有るか無いかの違いだけ)
	move.w	p_aftc_1st_dly(a5),d1
	bmi	fmaftc_dly_mi
	bne	fmaftc_dly_nz
fmaftc_dly_0:			*ディレイ=0
	move.w	p_aftc_8st_tbl(a5),p_aftc_dly2(a5)	*１個目のintervalを有効とする
	clr.b	p_aftc_n(a5)	*init pointer
exit_fm_aftc:
	rts

fmaftc_dly_mi:			*ディレイ<0
	add.w	d5,d1
	ble	fmaftc_dly_0
fmaftc_dly_nz:			*ディレイ>0
	move.w	d1,p_aftc_dly2(a5)
	st.b	p_aftc_n(a5)	*init pointer
	rts

midi_aftc:			*ｱﾌﾀｰﾀｯﾁｼｰｹﾝｽﾊﾟﾗﾒｰﾀ
	tst.b	p_aftc_sw(a5)
	beq	exit_md_aftc	*0(off)
	bpl	@f		*1(optionl mode case)
	ori.w	#$4000,p_level_param(a5)	*mark(midi_aftcとはこれの違いだけ)
	move.l	d5,d1
	lsr.w	#3,d1		*d1=step/8
				*ゼロになっちゃっても後でつじつまが合うから大丈夫
	move.w	d1,p_aftc_dly2(a5)
	lea	p_aftc_8st_tbl+2(a5),a1
	rept	aftc_max-1
	move.w	d1,(a1)+	*1/8ステップを８-1個分書く
	endm
	clr.b	p_aftc_n(a5)	*init pointer
	rts
@@:				*任意モードの場合
	ori.w	#$4000,p_level_param(a5)	*mark(midi_aftcとはこれの違いだけ)
	move.w	p_aftc_1st_dly(a5),d1
	bmi	mdaftc_dly_mi
	bne	mdaftc_dly_nz
mdaftc_dly_0:			*ディレイ=0
	move.w	p_aftc_8st_tbl(a5),p_aftc_dly2(a5)	*１個目のintervalを有効とする
	clr.b	p_aftc_n(a5)	*init pointer
exit_md_aftc:
	rts

mdaftc_dly_mi:			*ディレイ<0
	add.w	d5,d1
	ble	mdaftc_dly_0
mdaftc_dly_nz:			*ディレイ>0
	move.w	d1,p_aftc_dly2(a5)
	st.b	p_aftc_n(a5)	*init pointer(-1にしておくことで一回目が-1+1=0番目のaftc値が使用される)
	rts

fm_pmod:			*ピッチモジュレーションパラメータ
	* < d6.w=marker(0,4)
	tst.b	p_pmod_sw(a5)
	beq	exit_fm_pmod
	bmi	case_18_pmod		*1/8モード
					*以下ディレイモード(&任意モード)
	or.w	d6,p_pitch_param(a5)	*mark
	moveq.l	#0,d2
	move.w	p_pmod_1st_dly(a5),d1
	bmi	fp_dly_mi			*case:delay<0
	bne	fp_dly_nz			*case:delay>0
fp_dly_0:					*case:delay=0
	move.w	p_pmod_8st_tbl(a5),p_pmod_dly2(a5)
	move.b	d2,p_pmod_n(a5)		*0
	btst.b	d2,p_pmod_omt(a5)
	beq	cont_last_pm		*先頭が省略ならば前回のを継続
	move.w	p_pmod_dpt_tbl(a5),p_pmod_dpt_now(a5)
	move.w	p_pmod_spd_tbl(a5),d1
	move.w	p_pmod_wf(a5),d2
	bmi	wv_pmod
	move.b	_fp1(pc,d2.w),d2
	jmp	_fp1(pc,d2.w)
_fp1:	dc.b	svpmsp-_fp1		*saw
	dc.b	fpkuk-_fp1		*sqa
	dc.b	svpmsp-_fp1		*tri
	dc.b	svpmsp-_fp1		*saw2
	dc.b	fpnos-_fp1		*noise
	.even

case_18_pmod:				*1/8モードのケース
	or.w	d6,p_pitch_param(a5)	*mark
	moveq.l	#0,d2
	move.b	d2,p_pmod_n(a5)		*0
	move.w	d5,d1
	lsr.w	#3,d1			*d1=step/8
	move.w	d1,p_pmod_dly2(a5)	*init interval
	lea	p_pmod_8st_tbl+2(a5),a1
	rept	modu_max-1
	move.w	d1,(a1)+
	endm
	btst.b	d2,p_pmod_omt(a5)
	beq	cont_last_pm		*先頭が省略ならば前回のを継続
	move.w	p_pmod_dpt_tbl(a5),p_pmod_dpt_now(a5)
	move.w	p_pmod_spd_tbl(a5),d1
	move.w	p_pmod_wf(a5),d2
	bmi	wv_pmod
	move.b	_fp1(pc,d2.w),d2
	jmp	_fp1(pc,d2.w)
cont_last_pm:
	st.b	p_pmod_chain(a5)
exit_fm_pmod:
	rts

svpmsp:							*swa,tri,saw2
	move.w	d1,p_pmod_spd_next(a5)			*init speed work
	move.l	p_pmod_stp_tbl(a5),p_pmod_step_next(a5)	*init step
	clr.l	p_pmod_rndcnt(a5)			*p_pmod_rndcnt=0,p_pmod_dpntime=0
	cmpi.b	#2,p_pmod_chain(a5)
	bne	@f
	clr.l	p_pmod_pitch(a5)
@@:
	rts

fpkuk:							*square
	move.w	d1,p_pmod_spd_next(a5)			*init speed work
	move.w	p_pmod_dpt_tbl(a5),d0
	move.w	d0,p_pmod_step_next(a5)			*init step
	clr.l	p_pmod_rndcnt(a5)			*p_pmod_rndcnt=0,p_pmod_dpntime=0
	cmpi.b	#2,p_pmod_chain(a5)
	bne	@f
	move.w	d0,p_pmod_pitch(a5)
@@:
	rts

fpnos:					*ノイズのケース
	clr.l	p_pmod_rndcnt(a5)	*p_pmod_rndcnt=0,p_pmod_dpntime=0
	cmpi.b	#2,p_pmod_chain(a5)
	beq	@f
					*待機ケース
	move.w	d1,p_pmod_spd_next(a5)	*init speed work
	move.w	p_pmod_dpt_tbl(a5),p_pmod_step_next(a5)	*ノイズ波形の場合、step2は振幅
	rts
@@:					*同期ケース
	move.w	p_pmod_wf(a5),p_pmod_wf2(a5)
	move.w	d1,p_pmod_spd(a5)
	lsr.w	#1,d1			*d1=d1/2
	move.w	d1,p_pmod_spd2(a5)	*init speed work
	move.w	p_pmod_dpt_tbl(a5),d1
	move.w	d1,p_pmod_step2(a5)	*ノイズ波形の場合、step2は振幅
	bsr	get_rand
	muls	d1,d0
	swap	d0
	add.w	d0,d0
	move.w	d0,p_pmod_pitch(a5)
	st.b	p_pmod_chain(a5)
	rts

wv_pmod:				*波形メモリのケース
	clr.b	p_altp_flg(a5)		*反復モードスイッチオフ
	clr.l	p_pmod_rndcnt(a5)	*p_pmod_rndcnt=0,p_pmod_dpntime=0
	cmpi.b	#2,p_pmod_chain(a5)
	beq	@f
					*待機ケース
	move.w	d1,p_pmod_spd_next(a5)
	move.w	p_pmod_dpt_tbl(a5),p_pmod_step_next(a5)	*振幅を入れておく
	rts
@@:					*同期ケース
	move.w	p_pmod_wf(a5),p_pmod_wf2(a5)
	move.w	d1,p_pmod_spd(a5)
	lsr.w	#1,d1			*d1=d1/2
	move.w	d1,p_pmod_spd2(a5)	*init speed work
	move.w	p_pmod_dpt_tbl(a5),p_pmod_step2(a5)	*振幅を入れておく
	move.l	p_wvpm_start(a5),p_wvpm_point(a5)
	move.l	p_wvpm_lptm(a5),p_wvpm_lptm2(a5)
	st.b	p_pmod_chain(a5)
	bset.b	#b_pmod_syncok,p_pmod_flg(a5)
	bra	pmod_wvmm		*p_pmod_pitchへ値を強引に設定

fp_dly_mi:				*ディレイ<0
	add.w	d5,d1
	ble	fp_dly_0
fp_dly_nz:				*ディレイ>0
	move.w	d1,p_pmod_dly2(a5)	*init delay
	st.b	p_pmod_n(a5)		*-1
	move.l	d2,p_pmod_rndcnt(a5)	*p_pmod_rndcnt=0,p_pmod_dpntime=0
	cmpi.b	#2,p_pmod_chain(a5)
	bne	@f
	move.l	d2,p_pmod_pitch(a5)	*0
	move.l	d2,p_pmod_step2(a5)	*0
@@:
	rts

midi_pmod:				*ﾋﾟｯﾁﾓｼﾞｭﾚｰｼｮﾝﾊﾟﾗﾒｰﾀ
	tst.b	p_pmod_mode(a5)
	bpl	fm_pmod			*拡張ピッチモジュレーション
	tst.b	p_pmod_sw(a5)
	beq	exit_midi_pmod
	bmi	case_18_pmod_md

	ori.w	#$8000,p_level_param(a5)	*mark
	move.w	p_pmod_1st_dly(a5),d1
	bmi	mp_dly_mi		*case:delay<0
	bne	mp_dly_nz		*case:delay>0
mp_dly_0:				*case:delay=0
	move.w	p_pmod_8st_tbl(a5),p_pmod_dly2(a5)
	clr.b	p_pmod_n(a5)
	btst.b	#0,p_pmod_omt(a5)
	beq	exit_midi_pmod
	move.w	p_pmod_dpt_tbl(a5),d1
	move.w	d1,p_pmod_dpt_now(a5)
	move.w	d1,p_pmod_pitch(a5)
exit_midi_pmod:
	rts
case_18_pmod_md:			*ディレイがゼロのケース
	ori.w	#$8000,p_level_param(a5)	*mark
	clr.b	p_pmod_n(a5)
	move.w	d5,d1
	lsr.w	#3,d1
	move.w	d1,p_pmod_dly2(a5)	*init interval
	lea	p_pmod_8st_tbl+2(a5),a1
	rept	modu_max-1
	move.w	d1,(a1)+
	endm
	btst.b	#0,p_pmod_omt(a5)
	beq	exit_midi_pmod
	move.w	p_pmod_dpt_tbl(a5),d1
	move.w	d1,p_pmod_dpt_now(a5)
	move.w	d1,p_pmod_pitch(a5)
	rts

mp_dly_mi:
	add.w	d5,d1
	ble	mp_dly_0
mp_dly_nz:
	move.w	d1,p_pmod_dly2(a5)	*init delay
	st.b	p_pmod_n(a5)
	clr.w	p_pmod_pitch(a5)
	rts

fm_arcc:				*ARCC/AMODパラメータ
	* d6 d7 a4 破壊禁止
	tst.b	p_arcc_sw(a4)
	beq	exit_fm_arcc
	bmi	case_18_arcc		*1/8モード
					*以下ディレイモード(&任意モード)
	or.w	d6,p_level_param(a5)	*mark
	moveq.l	#0,d2
	move.w	p_arcc_1st_dly(a4),d1
	bmi	fa_dly_mi				*case:delay<0
	bne	fa_dly_nz				*case:delay>0
fa_dly_0:						*case:delay=0
	move.w	p_arcc_8st_tbl(a4),p_arcc_dly2(a4)
	move.b	d2,p_arcc_n(a4)		*0
	btst.b	d2,p_arcc_omt(a4)
	beq	cont_last_am		*先頭が省略ならば前回のを継続
	move.b	p_arcc_dpt_tbl(a4),p_arcc_dpt_now(a4)
	move.w	p_arcc_spd_tbl(a4),d1
	move.w	p_arcc_wf(a4),d2
	bmi	wv_arcc
	move.b	_fa1(pc,d2.w),d2
	jmp	_fa1(pc,d2.w)
_fa1:	dc.b	fasaw-_fa1		*saw
	dc.b	fakuk-_fa1		*sqa
	dc.b	fatri-_fa1		*tri
	dc.b	fasaw-_fa1		*saw2
	dc.b	fanos-_fa1		*noise
	.even

case_18_arcc:				*1/8モードのケース
	or.w	d6,p_level_param(a5)	*mark
	moveq.l	#0,d2
	move.b	d2,p_arcc_n(a4)		*0
	move.w	d5,d1
	lsr.w	#3,d1
	move.w	d1,p_arcc_dly2(a4)	*init interval
	lea	p_arcc_8st_tbl+2(a4),a1
	rept	modu_max-1
	move.w	d1,(a1)+
	endm
	btst.b	d2,p_arcc_omt(a4)
	beq	cont_last_am		*先頭が省略ならば前回のを継続
	move.b	p_arcc_dpt_tbl(a4),p_arcc_dpt_now(a4)
	move.w	p_arcc_spd_tbl(a4),d1
	move.w	p_arcc_wf(a4),d2
	bmi	wv_arcc
	move.b	_fa1(pc,d2.w),d2
	jmp	_fa1(pc,d2.w)
cont_last_am:
	st.b	p_arcc_chain(a4)
exit_fm_arcc:
	rts

fasaw:						*ノコギリ波
fakuk:						*矩形波
fatri:						*三角波
	move.w	d1,p_arcc_spd_next(a4)		*init speed work
	move.w	p_arcc_stp_tbl(a4),p_arcc_step_next(a4)	*init step
	move.b	p_arcc_dpt_tbl(a4),d1
	bmi	@f
	moveq.l	#0,d1
@@:
	lsl.w	#8,d1
	move.w	d1,p_arcc_o_next(a4)		*ノコギリ波専用
	clr.l	p_arcc_rndcnt(a4)		*p_arcc_rndcnt=0,p_arcc,dpntime=0
	cmpi.b	#2,p_arcc_chain(a4)
	bne	@f
	move.w	d1,p_arcc_level(a4)
@@:
	rts

fanos:						*ノイズ
	clr.l	p_arcc_rndcnt(a4)		*p_arcc_rndcnt=0,p_arcc,dpntime=0
	cmpi.b	#2,p_arcc_chain(a4)
	beq	@f
						*待機ケース
	move.w	d1,p_arcc_spd_next(a4)		*init speed work
	move.b	p_arcc_dpt_tbl(a4),p_arcc_step_next(a4)
	rts
@@:						*同期ケース
	move.w	p_arcc_wf(a4),p_arcc_wf2(a4)
	move.w	d1,p_arcc_spd(a4)
	lsr.w	#1,d1
	move.w	d1,p_arcc_spd2(a4)		*init speed work
	move.b	p_arcc_dpt_tbl(a4),d1
	move.b	d1,p_arcc_step2(a4)
	bsr	get_rand
	ext.w	d1
	bpl	@f
	neg.w	d1
@@:
	mulu	d1,d0
	swap	d0
	neg.b	d0
	move.b	d0,p_arcc_level(a4)
	st.b	p_arcc_chain(a4)
	rts

wv_arcc:
	clr.b	p_alta_flg(a4)			*反復モードスイッチオフ
	clr.l	p_arcc_rndcnt(a4)		*p_arcc_rndcnt=0,p_arcc,dpntime=0
	cmpi.b	#2,p_arcc_chain(a4)
	beq	@f
						*待機ケース
	move.w	d1,p_arcc_spd_next(a4)		*init speed work
	move.b	p_arcc_dpt_tbl(a4),p_arcc_step_next(a4)	*振幅を入れておく
	rts
@@:						*同期ケース
	move.w	p_arcc_wf(a4),p_arcc_wf2(a4)
	move.w	d1,p_arcc_spd(a4)
	lsr.w	#1,d1				*d1=d1/2
	move.w	d1,p_arcc_spd2(a4)		*init speed work
	move.b	p_arcc_dpt_tbl(a4),p_arcc_step2(a4)	*振幅を入れておく
	move.l	p_wvam_start(a4),p_wvam_point(a4)
	move.l	p_wvam_lptm(a4),p_wvam_lptm2(a4)
	st.b	p_arcc_chain(a4)
	tas.b	p_arcc_flg2(a4)			*bset.b	#b_arcc_syncok,p_arcc_flg2(a4)
	bra	arcc_wvmm			*p_arcc_levelへ値を強引に設定

fa_dly_mi:					*ディレイ<0
	add.w	d5,d1
	ble	fa_dly_0
fa_dly_nz:					*ディレイ>0
	move.w	d1,p_arcc_dly2(a4)			*init delay
	st.b	p_arcc_n(a4)			*-1
	move.l	d2,p_arcc_rndcnt(a4)		*p_arcc_rndcnt=0,p_arcc_dpntime=0
	cmpi.b	#2,p_arcc_chain(a4)
	bne	@f
	move.w	d2,p_arcc_level(a4)		*0
	move.w	d2,p_arcc_step2(a4)		*0
@@:
	rts

midi_arcc:				*arccパラメータ計算
	* d6 d7 a4 破壊禁止
	tst.b	p_arcc_mode(a4)
	bpl	fm_arcc
	tst.b	p_arcc_sw(a4)
	beq	exit_midi_arcc
	bmi	case_18_arcc_md

	or.w	d6,p_level_param(a5)		*mark
	move.w	p_arcc_1st_dly(a4),d1
	bmi	ma_dly_mi			*case:delay<0
	bne	ma_dly_nz			*case:delay>0
ma_dly_0:					*case:delay=0
	move.w	p_arcc_8st_tbl(a4),p_arcc_dly2(a4)	*init delay
	clr.b	p_arcc_n(a4)
	btst.b	#0,p_arcc_omt(a4)
	beq	exit_midi_arcc
	move.b	p_arcc_dpt_tbl(a4),d1
	move.b	d1,p_arcc_dpt_now(a4)
	move.b	d1,p_arcc_level(a4)
exit_midi_arcc:
	rts
case_18_arcc_md:			*ディレイが0のケース
	or.w	d6,p_level_param(a5)		*mark
	clr.b	p_arcc_n(a4)
	move.w	d5,d1
	lsr.w	#3,d1
	move.w	d1,p_arcc_dly2(a4)	*init interval
	lea	p_arcc_8st_tbl+2(a4),a1
	rept	modu_max-1
	move.w	d1,(a1)+
	endm
	btst.b	#0,p_arcc_omt(a4)
	beq	exit_midi_arcc
	move.b	p_arcc_dpt_tbl(a4),d1
	move.b	d1,p_arcc_dpt_now(a4)
	move.b	d1,p_arcc_level(a4)
	rts

ma_dly_mi:				*delay<0
	add.w	d5,d1
	ble	ma_dly_0
ma_dly_nz:				*delay>0
	move.w	d1,p_arcc_dly2(a4)		*init delay
	st.b	p_arcc_n(a4)
	move.b	p_arcc_reset(a4),p_arcc_level(a4)
	rts

get_rand:				*乱数生成
	* > d0.w=fixed random number
	* - all
	movem.l	d1/a1-a2,-(sp)
	movem.l	mr_xp(pc),a1-a2
	move.w	(a1),d0
	move.w	(a2)+,d1

	eor.w	d1,d0
	move.w	d0,(a1)+

	cmp.l	mr_max(pc),a1
	bne	@f
	move.l	estbn(pc),a1
@@:
	cmp.l	mr_max(pc),a2
	bne	@f
	move.l	estbn(pc),a2
@@:
	movem.l	a1-a2,mr_xp-work(a6)
	movem.l	(sp)+,d1/a1-a2
	rts

mr_xp:	ds.l	2
mr_max:	ds.l	1
*------------------------------------------------------------------------------
rltv_pan_fm:				*FM パンポット相対指定
	move.b	p_pan(a5),d2
	bmi	next_cmd_fm		*PAN off時には相対指定無効
	add.b	(a0)+,d2
	bpl	_panpot_fm
	tst.b	-1(a0)
	bpl	@f
	moveq.l	#0,d2
	bra	_panpot_fm
@@:
	moveq.l	#127,d2
	bra	_panpot_fm

panpot_fm:				*FM パンポット絶対指定
	move.b	(a0)+,d2
_panpot_fm:
	move.b	d2,p_pan(a5)		*save trk wk
	bsr	conv_p@p
	ror.b	#2,d2
	move.b	opmreg+AF(a6,d4.w),d1
	andi.w	#%0011_1111,d1
	or.b	d1,d2
	moveq.l	#$20,d1
	or.b	d4,d1
	move.l	p_opmset(a5),a4
	jsr	(a4)			*opmset
	bra	next_cmd_fm

rltv_pan_md:				*MIDI パンポット相対指定
	move.b	p_pan(a5),d2
	bmi	next_cmd_md		*PAN off時には相対指定無効
	add.b	(a0)+,d2
	bpl	_panpot_md
	tst.b	-1(a0)
	bpl	@f
	moveq.l	#0,d2
	bra	_panpot_md
@@:
	moveq.l	#127,d2
	bra	_panpot_md

check_concur	macro	CTRL
	* X d1,d2,a4
	local	ckcr0
	local	ckcr1
	local	ckcr2
	lea	p_arcc_param(a5),a4
	moveq.l	#7,d1			*(level_param+1)ビットチェックポインタ
	moveq.l	#arcc_max-1,d2
ckcr0:
	cmpi.b	#CTRL,p_arcc(a4)	*ARCCがPANPOTで実行中か
	bne	ckcr2
	tst.b	p_arcc_sw(a4)		*ARCCがリセット値を持って終了しているか
	bne	ckcr1
	bclr.b	d1,p_level_param+1(a5)	*clr mark
	bclr.b	#b_arcc_reset,p_arcc_flg(a4)
	bra	ckcr2
ckcr1:
	btst.b	d1,p_level_param+1(a5)	*check mark
	bne	next_cmd_md
ckcr2:
	lea	__arcc_len(a4),a4
	subq.l	#1,d1
	dbra	d2,ckcr0
	endm

panpot_md:				*MIDI パンポット絶対指定
	move.b	(a0)+,d2
_panpot_md:
	move.b	d2,p_pan(a5)
	* ARCC-PANPOTとの競合チェック
	check_concur	MIDI_PAN
	bset.b	#pts_panpot,p_timbre_set(a5)
	bra	next_cmd_md

rltv_pan_ad:				*ADPCM パンポット相対指定
	move.b	p_pan(a5),d2
	bmi	next_cmd_ad		*PAN off時には相対指定無効
	add.b	(a0)+,d2
	bpl	_panpot_ad
	tst.b	-1(a0)
	bpl	@f
	moveq.l	#0,d2
	bra	_panpot_ad
@@:
	moveq.l	#127,d2
	bra	_panpot_md

panpot_ad:				*ADPCM パンポット絶対指定
	move.b	(a0)+,d2
_panpot_ad:
	move.b	d2,p_pan(a5)
	bsr	do_adpcm_pan
	bra	next_cmd_ad

conv_p@p:
	* < d2=pan 0-127
	* > d2=pan 0-3
	* - all
	tst.b	d2
	bmi	cpp_p0
	cmpi.b	#31,d2		*便宜上４(3)段階パンにする
	ble	cpp_p1		*０ざとble
	cmpi.b	#95,d2
	ble	cpp_p3
cpp_p2:				*わざとmove.b
	move.b	#2,d2
	rts
cpp_p0:
	move.b	#0,d2
	rts
cpp_p1:
	move.b	#1,d2
	rts
cpp_p3:
	move.b	#3,d2
	rts
*------------------------------------------------------------------------------
segno_ad:				*ADPCM [segno]
	bsr	segno_ope
	bra	next_cmd_ad

segno_md:				*MIDI [segno]
	bsr	segno_ope
	bra	next_cmd_md

segno_fm:				*FM [segno]
	pea	next_cmd_fm(pc)

segno_ope:				*[segno]処理
	move.b	(a0)+,d0		*get offset(.L)
	lsl.w	#8,d0
	move.b	(a0)+,d0
	swap	d0
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0
	tst.l	d0			*コマンド無視ケース
	beq	@f
	tas.b	(a0,d0.l)		*set segno flag
	bclr.b	#6,(a0,d0.l)		*clr d.s. done flag
@@:
	rts
*------------------------------------------------------------------------------
ds_ad:					*ADPCM [d.s.]
	bsr	ds_ope
	bra	next_cmd_ad
ds_md:					*MIDI [d.s.]
	bsr	ds_ope
	bra	next_cmd_md
ds_fm:					*FM [d.s.]
	pea	next_cmd_fm(pc)

ds_ope:					*[d.s.]処理([SEGNO]へジャンプ)
	move.b	(a0),d0			*get flag
	bpl	exit_dsop		*[segno]がなかったので無視
	add.b	d0,d0			*check d.s. done flag
	bmi	exit_dsop		*[d.s.]一度処理したことがあるので無視
	bset.b	#6,(a0)+		*set d.s. done flag
	bset.b	#1,p_seq_flag(a5)	*set p_fine_flg
	move.b	(a0)+,d1		*get offset(.L)
	lsl.w	#8,d1
	move.b	(a0)+,d1
	swap	d1
	move.b	(a0)+,d1
	lsl.w	#8,d1
	move.b	(a0)+,d1
	cmpi.b	#coda_zmd,(a0)		*直後に[CODA]があるか
	beq	case_dscoda
	cmpi.b	#repeat_end_zmd,(a0)	*直後に:|があるか
	beq	case_dsrepend
@@:
	adda.l	d1,a0
	rts

case_dsrepend:				*:|が存在する場合
	cmpi.b	#coda_zmd,5(a0)		*さらにその後ろに[CODA]があるか
	bne	@b			*ない
	pea	(a0,d1.l)
	addq.w	#5,a0
	bra	@f

case_dscoda:				*[CODA]が存在する場合
	pea	(a0,d1.l)
@@:
	addq.w	#1,a0
	bsr	coda_ope
	move.l	(sp)+,a0
	rts

exit_dsop:
	addq.w	#5,a0
	rts
*------------------------------------------------------------------------------
coda_ad:				*ADPCM [coda]
	bsr	coda_ope
	bra	next_cmd_ad
coda_md:				*MIDI [coda]
	bsr	coda_ope
	bra	next_cmd_md
coda_fm:				*FM [coda]
	bsr	coda_ope
	bra	next_cmd_fm

coda_ope:
	move.b	(a0)+,d0		*get offset(.L)
	lsl.w	#8,d0
	move.b	(a0)+,d0
	swap	d0
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0
	tas.b	(a0,d0.l)	*set coda flag
	bclr.b	#6,(a0,d0.l)	*clr tocoda done flag
	rts
*------------------------------------------------------------------------------
tocoda_ad:				*ADPCM [tocoda]
	bsr	tocoda_ope
	bra	next_cmd_ad
tocoda_md:				*MIDI [tocoda]
	bsr	tocoda_ope
	bra	next_cmd_md
tocoda_fm:				*FM [tocoda]
	pea	next_cmd_fm(pc)

tocoda_ope:				*[tocoda]処理([coda]へジャンプ)
	move.b	(a0),d0			*get flag
	bpl	@f			*[coda]がなかったので無視
	add.b	d0,d0			*check tocoda done flag
	bmi	@f			*[tocoda]一度処理したことがあるので無視
	bset.b	#6,(a0)+		*set tocoda done flag
	move.b	(a0)+,d0		*get offset(.L)
	lsl.w	#8,d0
	move.b	(a0)+,d0
	swap	d0
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0
	adda.l	d0,a0
	rts
@@:
	addq.w	#5,a0
	rts
*------------------------------------------------------------------------------
fine_fm:				*[fine]処理
	btst.b	#1,p_seq_flag(a5)	*p_fine_flag
	beq	next_cmd_fm
	bra	play_end_fm

fine_ad:				*[fine]処理
	btst.b	#1,p_seq_flag(a5)	*p_fine_flag
	beq	next_cmd_ad
	bra	play_end_ad

fine_md:				*[fine]処理
	btst.b	#1,p_seq_flag(a5)	*p_fine_flag
	beq	next_cmd_md
	bra	play_end_md
*------------------------------------------------------------------------------
seq_cmd_md:			*MIDI シーケンス特殊コマンド群([～]コマンド群処理)
	lea	next_cmd_md(pc),a4
	bra	get_seq_cmd

seq_cmd_ad:			*ADPCM シーケンス特殊コマンド群([～]コマンド群処理)
	lea	next_cmd_ad(pc),a4
	bra	get_seq_cmd

seq_cmd_fm:			*FM シーケンス特殊コマンド群([～]コマンド群処理)
	lea	next_cmd_fm(pc),a4

get_seq_cmd:			*シーケンス特殊コマンドパラメータ処理
	* > d5.l=return value
	*	=-1 to play end
	moveq.l	#0,d0
	move.b	(a0)+,d0	*seq.cmd no.
	move.b	(a0)+,d1	*n of params
	add.w	d0,d0
	move.w	seq_cmd_tbl(pc,d0.w),d0
	jmp	seq_cmd_tbl(pc,d0.w)

seq_cmd_tbl:
	dc.w	dc_ope-seq_cmd_tbl	*0
	dc.w	do_ope-seq_cmd_tbl	*1
	dc.w	jump_ope1-seq_cmd_tbl	*2
	dc.w	jump_ope2-seq_cmd_tbl	*3
	dc.w	key_ope-seq_cmd_tbl	*4
	dc.w	meter_ope-seq_cmd_tbl	*5

dc_ope:					*3 [d.c.]処理(初めに帰る)
	btst.b	#0,p_seq_flag(a5)	*p_dc_flag
	bne	exit_gsc		*一度処理済み
	cmpi.b	#coda_zmd,(a0)
	bne	@f
	addq.w	#1,a0
	bsr	coda_ope
@@:
	move.l	(a6),a1
	btst.b	#_ID_SE,p_track_stat(a5)
	beq	@f
	move.l	4(a6),a1
@@:
	move.w	-(a1),d0
	bsr	top_ptr_set		*先頭アドレスをセット
	movea.l	p_data_pointer(a5),a0
	or.b	#%11,p_seq_flag(a5)	*set p_dc_flag,p_fine_flag
exit_gsc:
	jmp	(a4)

do_ope:					*[do]処理
	move.b	#1,p_do_loop_flag(a5)
	move.l	a0,p_do_loop_ptr(a5)
	move.l	p_total(a5),p_total_olp(a5)
	tst.l	jump_flg2-work(a6)	*[@]中だったか
	bne	@f
	tst.l	jump_flg3-work(a6)	*[jump]中だったか
	bne	@f
	clr.l	p_total(a5)
@@:
	jmp	(a4)

key_ope:
	btst.b	#_ID_SE,p_track_stat(a5)
	bne	@f
	move.b	(a0)+,key+0-work(a6)
	move.b	(a0)+,key+1-work(a6)
	jmp	(a4)
@@:
	move.b	(a0)+,key_se+0-work(a6)
	move.b	(a0)+,key_se+1-work(a6)
	jmp	(a4)

meter_ope:
	btst.b	#_ID_SE,p_track_stat(a5)
	bne	@f
	move.b	(a0)+,meter+0-work(a6)
	move.b	(a0)+,meter+1-work(a6)
	jmp	(a4)
@@:
	move.b	(a0)+,meter_se+0-work(a6)
	move.b	(a0)+,meter_se+1-work(a6)
	jmp	(a4)

jump_ope1:				*次の[!]へ飛ぶ
	tst.l	jump_flg2-work(a6)	*[@]実行中は[!]は無視
	bne	exit_jo1
	tst.l	jump_flg3-work(a6)	*[jump nn]実行中は[!]は無視
	bne	exit_jo1
	bset.b	#2,p_seq_flag(a5)	*check & set [!]flag
	bne	end_jump1_mode		*[!]解除へ
	st.b	jump_flg1-work(a6)
	lea	jpop_bak(pc),a1
	move.l	case_key_patch_fm(pc),(a1)+		*パッチする前にバックアップする
	move.l	case_key_patch_ad(pc),(a1)+
	move.l	case_key_patch_md(pc),(a1)+
	move.l	rest_patch_fm(pc),(a1)+
	move.l	rest_patch_ad(pc),(a1)+
	move.l	rest_patch_md(pc),(a1)+
	move.l	wait_patch_fm(pc),(a1)+
	move.l	wait_patch_ad(pc),(a1)+
	move.l	wait_patch_md(pc),(a1)+
	patch_l	BRA,case_key_patch_fm,next_cmd_fm	*発音処理一時無効へ
	patch_l	BRA,case_key_patch_ad,next_cmd_ad
	patch_l	BRA,case_key_patch_md,next_cmd_md
	patch_l	BRA,rest_patch_fm,next_cmd_fm
	patch_l	BRA,rest_patch_ad,next_cmd_ad
	patch_l	BRA,rest_patch_md,next_cmd_md
	patch_l	BRA,wait_patch_fm,next_cmd_fm
	patch_l	BRA,wait_patch_ad,next_cmd_ad
	patch_l	BRA,wait_patch_md,next_cmd_md
	bsr	cache_flush
exit_jo1:
	jmp	(a4)

end_jump1_mode:				*[!]解除
	bclr.b	#2,p_seq_flag(a5)
	clr.l	jump_flg1-work(a6)
	lea	jpop_bak(pc),a1
	move.l	(a1)+,case_key_patch_fm-work(a6)	*バックアップからパッチデータを戻す
	move.l	(a1)+,case_key_patch_ad-work(a6)
	move.l	(a1)+,case_key_patch_md-work(a6)
	move.l	(a1)+,rest_patch_fm-work(a6)
	move.l	(a1)+,rest_patch_ad-work(a6)
	move.l	(a1)+,rest_patch_md-work(a6)
	move.l	(a1)+,wait_patch_fm-work(a6)
	move.l	(a1)+,wait_patch_ad-work(a6)
	move.l	(a1)+,wait_patch_md-work(a6)
	bsr	cache_flush
	jmp	(a4)

jump_ope2:				*次の[@]へ飛ぶ
	btst.b	#2,p_seq_flag(a5)	*[!]実行中は[@]は無視
	bne	exit_jo2
	tst.l	jump_flg3-work(a6)	*[jump nn]実行中は[@]は無視
	bne	exit_jo2
	btst.b	#_ID_SE,p_track_stat(a5)	*効果音トラックでは無効
	bne	exit_jo2
	move.l	jump_flg2(pc),d0
	bne	next_jump2_mode		*[@]解除?

	move.l	(a6),a1			*TRACK ID SET
	move.w	-(a1),d0
	bset.l	#31,d0			*最上位ビットが実行中フラグとなる
	lea.l	jump_flg2(pc),a1
	move.l	d0,(a1)
do_patch_jo3:
	* < d0.l=track id
	* < a1.l=jump_flgX
	move.l	a1,jump_flg_ptr-work(a6)	*ジャンプ基準トラックID(jump_flgX)
	lea	p_total(a5),a1
	move.l	a1,p_total_ptr-work(a6)		*ジャンプ基準トラックp_total(a5)位置

	lea	jpop2_bak(pc),a1
	move.l	case_key_patch_fm(pc),(a1)+		*パッチする前にバックアップする
	move.l	case_key_patch_ad(pc),(a1)+
	move.l	case_key_patch_md(pc),(a1)+
	move.l	rest_patch_fm(pc),(a1)+
	move.l	rest_patch_ad(pc),(a1)+
	move.l	rest_patch_md(pc),(a1)+
	move.l	wait_patch_fm(pc),(a1)+
	move.l	wait_patch_ad(pc),(a1)+
	move.l	wait_patch_md(pc),(a1)+
	patch_l	BRA,case_key_patch_fm,joX1_fm		*発音処理をフック
	patch_l	BRA,case_key_patch_ad,joX1_ad
	patch_l	BRA,case_key_patch_md,joX1_md
	patch_l	BRA,rest_patch_fm,joX1_fm
	patch_l	BRA,rest_patch_ad,joX1_ad
	patch_l	BRA,rest_patch_md,joX1_md
	patch_l	BRA,wait_patch_fm,joX1_fm
	patch_l	BRA,wait_patch_ad,joX1_ad
	patch_l	BRA,wait_patch_md,joX1_md
	bsr	cache_flush
					*処理に必要とするワークを初期化
	move.l	play_trk_tbl(pc),a1	*< d0.l=track ID
	move.l	seq_wk_tbl(pc),d2
	btst.b	#_ID_SE,p_track_stat(a5)
	beq	@f
	move.l	play_trk_tbl_se(pc),a1	*< d0.l=track ID
	move.l	seq_wk_tbl_se(pc),d2
@@:
*	moveq.l	#0,d3
1:
	moveq.l	#0,d1
	move.w	(a1)+,d1
	bmi	exit_jo2
*	cmp.w	d0,d1
*	bne	@f
*	moveq.l	#-1,d3			*ここからさきは演奏順序後ろ
*@@:
	swap	d1
	lsr.l	#16-trwk_size_,d1
	movea.l	d2,a2
	adda.l	d1,a2			*a2=trk n seq_wk_tbl
*	tst.l	d3
*	beq	@f
*	clr.l	p_total(a2)		*ワーク初期化
*	bra	1b
*@@:					*[@]が設定されたトラックよりも
	moveq.l	#0,d1			*演奏順序が前のラックの場合
	move.w	(a2),d1
	move.w	#1,(a2)
	move.l	d1,p_total(a2)
	bra	1b

exit_jo2:
	jmp	(a4)
					*第1フェーズ実行部
joX1_fm:
	moveq.l	#0,d1
	move.w	(a5),d1
	add.l	d1,p_total(a5)
	bra	next_cmd_fm

joX1_ad:
	moveq.l	#0,d1
	move.w	(a5),d1
	add.l	d1,p_total(a5)
	bra	next_cmd_ad

joX1_md:
	moveq.l	#0,d1
	move.w	(a5),d1
	add.l	d1,p_total(a5)
	bra	next_cmd_md

next_jump2_mode:				*[@]次フェーズへ
	* < d0.l=track id
	move.l	(a6),a1
	cmp.w	-(a1),d0			*same track id ?
	bne	@f
	patch_w	BSR,mil_patch,check_jump2_tr_id	*トラックIDチェックルーチンへ飛ぶようにパッチ
	btst.b	#_ID_SE,p_track_stat(a5)
	beq	jump_next_phase
	patch_w	BSR,mil_patch_se,check_jump2_tr_id_se
jump_next_phase:				*第2フェーズ
	move.l	p_total(a5),d0			*!4/11
	add.l	d0,zmusic_int-work(a6)		*!
	patch_l	BRA,case_key_patch_fm,joX2_fm	*発音処理をフック
	patch_l	BRA,case_key_patch_ad,joX2_ad
	patch_l	BRA,case_key_patch_md,joX2_md
	patch_l	BRA,rest_patch_fm,joX2_fm
	patch_l	BRA,rest_patch_ad,joX2_ad
	patch_l	BRA,rest_patch_md,joX2_md
	patch_l	BRA,wait_patch_fm,joX2_fm
	patch_l	BRA,wait_patch_ad,joX2_ad
	patch_l	BRA,wait_patch_md,joX2_md
	bra	cache_flush
@@:
	rts

joX2_fm:
	lea	next_cmd_fm(pc),a4	*帰還アドレス
do_joX2:
	moveq.l	#0,d1
	move.w	(a5),d1
	add.l	d1,p_total(a5)
	move.l	p_total_ptr(pc),a2
	move.l	(a2),d1
	cmp.l	p_total(a5),d1
	bls	@f			*おいついたら
	jmp	(a4)
@@:					*次トラックへ
	rts

joX2_ad:
	lea	next_cmd_ad(pc),a4	*帰還アドレス
	bra	do_joX2

joX2_md:
	lea	next_cmd_md(pc),a4	*帰還アドレス
	bra	do_joX2

end_jump3_mode:					*[jump nn]解除
	clr.l	jump_flg3-work(a6)
	bra	@f

end_jump2_mode:					*[@]解除
	clr.l	jump_flg2-work(a6)
@@:
	* - d7
	* p_XX(a5)は使えない
	* ^^^^^^^^^^^^^^^^^^
do_end_jumpX_mode	macro	xx
	lea	jpop2_bak(pc),a1
	move.l	(a1)+,case_key_patch_fm-work(a6)	*バックアップからパッチデータを戻す
	move.l	(a1)+,case_key_patch_ad-work(a6)
	move.l	(a1)+,case_key_patch_md-work(a6)
	move.l	(a1)+,rest_patch_fm-work(a6)
	move.l	(a1)+,rest_patch_ad-work(a6)
	move.l	(a1)+,rest_patch_md-work(a6)
	move.l	(a1)+,wait_patch_fm-work(a6)
	move.l	(a1)+,wait_patch_ad-work(a6)
	move.l	(a1)+,wait_patch_md-work(a6)
	move.w	#NOP,mil_patch&xx-work(a6)
	bsr	cache_flush
					*使用したワークの後始末
	move.l	p_total_ptr(pc),a1
	move.l	(a1),d1
	move.l	play_trk_tbl&xx(pc),a1
	move.l	seq_wk_tbl&xx(pc),d2
@@:
	moveq.l	#0,d0
	move.w	(a1)+,d0
	bmi	@f
	swap	d0
	lsr.l	#16-trwk_size_,d0
	movea.l	d2,a2
	adda.l	d0,a2			*a2=trk n seq_wk_tbl
	tst.b	p_track_stat(a2)
	bne	@b			*アクティブでないならば無視
	move.l	p_total(a2),d0
	sub.l	d1,d0			*ステップタイム演算
	addq.w	#1,d0
	move.w	d0,(a2)			*store step time
	bra	@b
@@:
	rts
	endm

	do_end_jumpX_mode

end_jump3_mode_se:				*[jump nn]解除
	clr.l	jump_flg3-work(a6)
	bra	@f

end_jump2_mode_se:				*[@]解除
	clr.l	jump_flg2-work(a6)
@@:
	* - d7
	* p_XX(a5)は使えない
	* ^^^^^^^^^^^^^^^^^^
do_end_jumpX_mode	_se
*------------------------------------------------------------------------------
jump_ope3_ad:				*ADPCM [jump nn]
	lea	next_cmd_ad(pc),a4
	bra	@f

jump_ope3_md:				*MIDI [jump nn]
	lea	next_cmd_md(pc),a4
	bra	@f

jump_ope3_fm:				*FM [jump nn]
	lea	next_cmd_fm(pc),a4
@@:					*[jump nn]処理
	btst.b	#2,p_seq_flag(a5)	*[!]実行中は[jump nn]は無視
	bne	exit_jo3
	tst.l	jump_flg2-work(a6)	*[@]実行中は[jump nn]は無視
	bne	exit_jo3
	tst.l	jump_flg3-work(a6)	*[jump nn]実行中は[jump nn]は無視
	bne	exit_jo3
	btst.b	#_ID_SE,p_track_stat(a5)	*効果音トラックでは無効
	bne	exit_jo3

	move.l	(a6),a1			*TRACK ID SET
	moveq.l	#0,d0
	move.w	-(a1),d0
	bset.l	#31,d0			*最上位ビットが実行中フラグとなる
	lea.l	jump_flg3(pc),a1
	move.l	d0,(a1)
	move.b	(a0)+,dest_measure+0-work(a6)	*目的小節番号セット
	move.b	(a0)+,dest_measure+1-work(a6)	*目的小節番号セット
	move.b	(a0)+,dest_measure+2-work(a6)	*目的小節番号セット
	move.b	(a0)+,dest_measure+3-work(a6)	*目的小節番号セット
	bra	do_patch_jo3			*以下[@]の処理と同じ
exit_jo3:
	jmp	(a4)

next_jump3_mode:			*[jump nn]次フェーズへ
	* < d0.l=track id
	move.l	(a6),a1
	cmp.w	-(a1),d0		*same track id ?
	bne	@f
	move.l	dest_measure(pc),d0
	cmp.l	p_measure(a5),d0
	bne	@f
	patch_w	BSR,mil_patch,check_jump3_tr_id	*トラックIDチェックルーチンへ飛ぶようにパッチ
	btst.b	#_ID_SE,p_track_stat(a5)
	beq	jump_next_phase
	patch_w	BSR,mil_patch_se,check_jump3_tr_id_se
	bra	jump_next_phase
@@:
	rts

next_jump3_mode_2:			*[jump nn]次フェーズへ(from 
	* < d0.l=track id
	move.l	(a6),a1
	cmp.w	-(a1),d0		*same track id ?
	bne	@f
	patch_w	BSR,mil_patch,check_jump3_tr_id	*トラックIDチェックルーチンへ飛ぶようにパッチ
	btst.b	#_ID_SE,p_track_stat(a5)
	beq	jump_next_phase
	patch_w	BSR,mil_patch_se,check_jump3_tr_id_se
	bra	jump_next_phase
@@:
	rts
*------------------------------------------------------------------------------
measure_fm:			*FM 小節線
	pea	next_cmd_fm(pc)
do_measure:
	tst.b	p_vseq_param+p_arcc_sw(a5)
	beq	1f
	lea	p_vseq_param(a5),a4		*エンハンスド・ベロシティ・シーケンス処理
	tst.b	p_arcc_flg(a4)			*b_vseq_msrsync(小節線で同期?)
	bpl	1f
	btst.b	#b_arcc_first,p_arcc_flg(a4)
	beq	@f
	subq.w	#1,p_arcc_syncnt2(a4)
	bne	1f
	bclr.b	#b_arcc_first,p_arcc_flg(a4)
@@:
	move.w	p_arcc_syncnt(a4),p_arcc_syncnt2(a4)
	clr.b	p_arcc_dpt_now(a4)
1:
	btst.b	#b_agogik_trmk,p_agogik_flg(a5)
	beq	3f
	move.l	a5,-(sp)
	move.l	a5,a4
	lea.l	agogik_base(a6),a5
	lea	do_agogik(pc),a2
	btst.b	#_ID_SE,p_track_stat(a4)
	beq	@f
	lea.l	agogik_base_se(a6),a5
	lea	do_agogik_se(pc),a2
@@:
	tst.b	p_pmod_sw(a5)
	beq	2f
	btst.b	#b_agogik_msrsync,p_agogik_flg(a4)	*小節線同期モードか
	beq	2f
	bset.b	#b_pmod_first,p_pmod_flg(a5)
	beq	@f
	subq.w	#1,p_pmod_syncnt2(a5)
	bne	2f
@@:
	move.w	p_pmod_syncnt(a5),p_pmod_syncnt2(a5)
	move.b	#2,p_pmod_chain(a5)		*即接続(つまり同期)
	moveq.l	#0,d5
	moveq.l	#0,d6
	move.l	a2,-(sp)
	bsr	fm_pmod				*モジュレーションパラメータ
	move.l	(sp)+,a2
	jsr	(a2)
2:
	move.l	(sp)+,a5
3:
	addq.l	#1,p_measure(a5)
	move.l	jump_flg3(pc),d0
	bne	next_jump3_mode			*小節スキャンジャンプ次フェーズか
	rts

measure_ad:			*ADPCM 小節線
	pea	next_cmd_ad(pc)
	bra	do_measure

measure_md:			*MIDI 小節線
	pea	next_cmd_md(pc)
	bra	do_measure
*------------------------------------------------------------------------------
loop_fm:				*FM    [LOOP]
	bset.b	#b_loop_done,p_trk_seq_flg(a5)
	bne	next_cmd_fm
	bsr	loop_ope
	beq	play_end_fm
	bra	next_cmd_fm

loop_ad:				*ADPCM [LOOP]
	bset.b	#b_loop_done,p_trk_seq_flg(a5)
	bne	next_cmd_ad
	bsr	loop_ope
	beq	play_end_ad
	bra	next_cmd_ad

loop_md:				*MIDI  [LOOP]
	bset.b	#b_loop_done,p_trk_seq_flg(a5)
	bne	next_cmd_md
	bsr	loop_ope
	beq	play_end_md
	bra	next_cmd_md

loop_ope:				*[loop]処理([do]へジャンプ)
	* eq to_play_end
	* ne loop
	move.b	p_do_loop_flag(a5),d1
	beq	exit_loop_ope		*[do]が省略の場合は演奏終了
	btst.b	#_ID_SE,p_track_stat(a5)
	bne	@f
	bsr	loop_bsr_ope
@@:
	addq.b	#1,d1		*inc loop time
	beq	@b
	move.b	d1,p_do_loop_flag(a5)
	btst.b	#2,p_seq_flag(a5)	*[!]中だったか
	bne	exit_loop_ope
	clr.b	p_seq_flag(a5)		*ワーク初期化
@@:
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0
	swap	d0
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0		*get offset
	tst.l	d0
	beq	@f
	clr.b	(a0,d0.l)		*ワーク・クリア
	bra	@b
@@:
	move.l	p_do_loop_ptr(a5),a1
	cmpi.b	#loop_zmd,(a1)		*[do]と[loop]の間に何もない場合は停止
	beq	exit_loop_ope
	btst.b	#_ID_SE,p_track_stat(a5)
	bne	@f
	tst.b	perform_flg-work(a6)
	bmi	exit_loop_ope		*FUNC $59(LOOP禁止モードケース)
@@:
	move.l	a1,a0
	moveq.l	#-1,d0
	rts
exit_loop_ope:
	moveq.l	#0,d0
	rts

loop_bsr_ope:
	move.w	obtevtjtbl-work+lp_loop(a6),d0	*1-256ならば指定あり
	beq	exit_lpo
	* < d1.b=現在までに繰り返した回数
	* X d0,d2,a1
	* - d1は破壊禁止
	cmp.b	d0,d1			*繰り返し回数チェック
	bcs	exit_lpo
	moveq.l	#0,d0
	move.l	(a6),a1
	move.w	-(a1),d0		*現在実行中のトラックナンバー(0～)
	move.l	d0,d2
	lsr.w	#3,d0			*d0=d0/8
	move.l	done_bit(pc),a1
	bset.b	d2,(a1,d0.w)
	bne	exit_lpo
	move.l	play_trk_tbl(pc),a1
	moveq.l	#0,d2
@@:					*演奏状態のトラック数のカウント
	move.w	(a1)+,d0
	bmi	lbo0
	addq.w	#1,d2
	bra	@b
lbo0:
	addq.w	#1,obtevtjtbl-work+lp_work(a6)	*今までに何トラックループしたか
	cmp.w	obtevtjtbl-work+lp_work(a6),d2
	bhi	exit_lpo
	movea.l	obtevtjtbl-work+lp_jump(a6),a1
	clr.l	obtevtjtbl-work+lp_work(a6)	*一度処理したらOFFにする(lp_work=lp_loop=0)
	jmp	(a1)
exit_lpo:
	rts
*------------------------------------------------------------------------------
*同様の処理がcalc_totalにもあり
gosub_fm:				*GOSUB
	pea	next_cmd_fm(pc)

do_gosub:
	moveq.l	#0,d0
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0		*get trk number
	move.b	(a0)+,d1
	lsl.w	#8,d1
	move.b	(a0)+,d1
	swap	d1
	move.b	(a0)+,d1
	lsl.w	#8,d1
	move.b	(a0)+,d1
	cmpi.w	#-1,d0
	bne	@f
	move.l	pattern_trk(pc),a1
	btst.b	#_ID_SE,p_track_stat(a5)
	beq	dogsb0
	move.l	pattern_trk_se(pc),a1
	bra	dogsb0
@@:
	move.l	trk_po_tbl(pc),a1
	btst.b	#_ID_SE,p_track_stat(a5)
	beq	@f
	move.l	trk_po_tbl_se(pc),a1
@@:
	lsl.l	#trk_tbl_size_,d0
	add.l	d0,a1
dogsb0:
	move.l	ti_play_data(a1),d0
	lea	ti_play_data+4(a1,d0.l),a1	*performance data top addr
	tst.l	p_return(a5)
	bne	@f
	move.l	a0,p_return(a5)
	lea	(a1,d1.l),a0
@@:
	rts

gosub_ad:				*GOSUB
	bsr	do_gosub
	bra	next_cmd_ad

gosub_md:				*GOSUB
	bsr	do_gosub
	bra	next_cmd_md

return_fm:				*return
	move.l	p_return(a5),d0
	beq	next_cmd_fm
	clr.l	p_return(a5)
	move.l	d0,a0
	bra	next_cmd_fm

return_ad:				*return
	move.l	p_return(a5),d0
	beq	next_cmd_ad
	clr.l	p_return(a5)
	move.l	d0,a0
	bra	next_cmd_ad

return_md:				*return
	move.l	p_return(a5),d0
	beq	next_cmd_md
	clr.l	p_return(a5)
	move.l	d0,a0
	bra	next_cmd_md
*------------------------------------------------------------------------------
event_fm:			*FM イベント制御
	pea	next_cmd_fm(pc)
	bra	do_event_ope

event_ad:			*ADPCM イベント制御
	pea	next_cmd_ad(pc)
	bra	do_event_ope

event_md:			*MIDI イベント制御
	pea	next_cmd_md(pc)

do_event_ope:			*イベント制御処理
	move.b	(a0)+,d1	*(ZMUSIC V3.0自身は
	lsl.w	#8,d1		*category:WORD,
	move.b	(a0)+,d1	*class:単なる文字列
	swap	d1		*のみをサポートする)
	move.b	(a0)+,d1
	lsl.w	#8,d1
	move.b	(a0)+,d1	*get offset
	tst.b	(a0)		*check category
	bne	not_just_str_word
	tst.b	1(a0)		*check class
	bne	not_just_str_word
	lea	4(a0),a1
	move.l	a1,lyric_address-work(a6)	*文字列のアドレスセット
	tst.l	d1
	beq	@f
	add.l	d1,a0				*a0=next
	subq.l	#4,d1				*属性情報の大きさを除いたものがデータ自身の長さ
	move.l	d1,lyric_size-work(a6)		*文字列のサイズセット
	rts
@@:
	moveq.l	#-1,d0
	addq.w	#4,a0		*skip属性サイズ
@@:
	addq.l	#1,d0
	tst.b	(a0)+
	bne	@b
	move.l	d0,lyric_size-work(a6)		*文字列のサイズセット
	rts
not_just_str_word:
	tst.l	d1
	beq	@f
	add.l	d1,a0
	rts
@@:
	addq.w	#4,a0		*skip属性サイズ
@@:
	tst.b	(a0)+
	bne	@b
	rts
*------------------------------------------------------------------------------
*同様の処理がcalc_totalにもあり
repeat_start_fm:		*|:n処理
	addq.w	#2,a0
	clr.b	(a0)+
	clr.b	(a0)+
	bra	next_cmd_fm

repeat_start_ad:		*|:n処理
	addq.w	#2,a0
	clr.b	(a0)+
	clr.b	(a0)+
	bra	next_cmd_ad

repeat_start_md:		*|:n処理
	addq.w	#2,a0
	clr.b	(a0)+
	clr.b	(a0)+
	bra	next_cmd_md

repeat_end_ad:			*:|処理
	bsr	do_repeat_end
	bra	next_cmd_ad

repeat_end_md:			*:|処理
	bsr	do_repeat_end
	bra	next_cmd_md

repeat_end_fm:			*:|処理
	pea	next_cmd_fm(pc)

do_repeat_end:
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0
	swap	d0
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0	*d0.l=offset value
	move.l	a0,a1
	suba.l	d0,a0		*a0.l=rept.count
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0
	move.b	(a0)+,d1
	lsl.w	#8,d1
	move.b	(a0)+,d1
	cmp.w	d1,d0		*繰り返し回数とカウンタを比較
	bne	@f		*リピート
	move.l	a1,a0		*リピートしないで次へ
	rts
@@:
	addq.w	#1,d1
	move.b	d1,-1(a0)
	ror.w	#8,d1
	move.b	d1,-2(a0)
	rts

repeat_skip_ad:			*ADPCM |n処理
	bsr	repeat_skip
	bra	next_cmd_ad

repeat_skip_md:			*MIDI |n処理
	bsr	repeat_skip
	bra	next_cmd_md

repeat_skip_fm:			*FM |n処理
	pea	next_cmd_fm(pc)

repeat_skip:			*|n処理
	move.b	(a0)+,d1
	lsl.w	#8,d1
	move.b	(a0)+,d1	*get count
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0
	swap	d0
	move.b	(a0)+,d0	*get count work offset
	lsl.w	#8,d0
	move.b	(a0)+,d0	*d0.w=offset value
	move.l	a0,a1
	suba.l	d0,a1
	move.b	(a1)+,d0
	lsl.w	#8,d0
	move.b	(a1)+,d0
	cmp.w	d0,d1		*count workと比較
	bne	@f
	addq.w	#4,a0		*skip offset
	rts			*|n以降の演奏データを実行する
@@:				*繰り返し処理から脱ける
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0
	swap	d0
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0	*d0=offset
	adda.l	d0,a0		*オフセットを足して次の|nや:|へ
	rts

repeat_skip2_ad:		*ADPCM |処理
	bsr	do_repeat_skip2
	bra	next_cmd_ad

repeat_skip2_md:		*MIDI |処理
	bsr	do_repeat_skip2
	bra	next_cmd_md

repeat_skip2_fm:		*FM |処理
	pea	next_cmd_fm(pc)

do_repeat_skip2:			*|処理(nが省略時のケース)
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0
	swap	d0
	move.b	(a0)+,d0	*get count work offset
	lsl.w	#8,d0
	move.b	(a0)+,d0	*d0.l=offset value
	move.l	a0,a1
	lea	-2(a0),a1
	suba.l	d0,a1
	move.b	(a1)+,d1	*get rept.work
	lsl.w	#8,d1
	move.b	(a1)+,d1
	move.b	(a1)+,d0
	lsl.w	#8,d0
	move.b	(a1)+,d0
	cmp.w	d0,d1		*count workとリピート回数を比較
	beq	@f
	addq.w	#4,a0		*skip offset
	rts			*|以降の演奏データを実行する
@@:				*リピート最後なので脱ける
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0
	swap	d0
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0	*d0=offset
	adda.l	d0,a0		*オフセットを足して:|へ
	rts
*------------------------------------------------------------------------------
asgn_chg_fm:			*FM チャンネル切り換え
	move.b	(a0)+,d4	*p_type
	lsl.w	#8,d4
	move.b	(a0)+,d4	*p_type
	tst.w	d4
	bmi	fm_to_midi
	bne	fm_to_adpcm
fm_to_fm:			*以下、FM音源内でのチャンネルチェンジ
	swap	d4
	move.b	(a0)+,d4
	lsl.w	#8,d4
	move.b	(a0)+,d4
	move.w	d4,p_ch(a5)
	bra	next_cmd_fm

fm_to_adpcm:
	swap	d4
	move.b	(a0)+,d4
	lsl.w	#8,d4
	move.b	(a0)+,d4
	move.l	d4,p_type(a5)
	move.l	#int_play_ope_ad,p_int_play_ope(a5)
	move.l	#ad_return,(sp)
	jsr	iw_ad0
	bra	next_cmd_ad

asch_tbl0:
	dc.w	m_out_m0-asch_tbl0
	dc.w	m_out_m1-asch_tbl0
	dc.w	m_out_r0-asch_tbl0
	dc.w	m_out_r1-asch_tbl0

fm_to_midi:
adpcm_to_midi:
	move.w	d4,d1
	ext.w	d1
	move.w	d1,p_midi_if(a5)
	add.w	d1,d1
	move.w	asch_tbl0(pc,d1.w),d1
	lea	asch_tbl0(pc,d1.w),a4
	move.l	a4,p_midi_trans(a5)
	swap	d4
	move.b	(a0)+,d4	*p_ch
	lsl.w	#8,d4
	move.b	(a0)+,d4	*p_ch
	move.l	d4,p_type(a5)
	move.l	#int_play_ope_md,p_int_play_ope(a5)
	move.w	p_detune(a5),d0
	ext.l	d0
	chg64_683	d0
	move.w	d0,p_detune(a5)
	move.w	p_bend_dst(a5),d0
	ext.l	d0
	chg64_683	d0
	move.w	d0,p_bend_dst(a5)
	move.l	#md_return,(sp)
	jsr	iw_md0
	bra	next_cmd_md

asgn_chg_md:			*MIDI チャンネル切り換え
	move.b	(a0)+,d4	*type
	lsl.w	#8,d4
	move.b	(a0)+,d4	*type
	tst.w	d4
	beq	midi_to_fm
	bpl	midi_to_adpcm
*midi_to_midi:			*以下、MIDI内でのチャンネルチェンジ
	move.w	d4,d1
	ext.w	d1
	move.w	d1,p_midi_if(a5)
	add.w	d1,d1
	move.w	asch_tbl1(pc,d1.w),d1
	lea	asch_tbl1(pc,d1.w),a4
	move.l	a4,p_midi_trans(a5)
	swap	d4
	move.b	(a0)+,d4	*ch
	lsl.w	#8,d4
	move.b	(a0)+,d4	*ch
	move.l	d4,p_type(a5)
	bra	next_cmd_md

asch_tbl1:
	dc.w	m_out_m0-asch_tbl1
	dc.w	m_out_m1-asch_tbl1
	dc.w	m_out_r0-asch_tbl1
	dc.w	m_out_r1-asch_tbl1

midi_to_fm:
	swap	d4
	move.b	(a0)+,d4	*ch
	lsl.w	#8,d4
	move.b	(a0)+,d4	*ch
	move.l	d4,p_type(a5)
	move.l	#int_play_ope_fm,p_int_play_ope(a5)
	move.l	opmset_bsr_ms-work(a6),p_opmset(a5)
	move.w	p_detune(a5),d0
	muls	#3,d0
	asr.l	#5,d0
	move.w	d0,p_detune(a5)
	move.w	p_bend_dst(a5),d0
	muls	#3,d0
	asr.l	#5,d0
	move.w	d0,p_bend_dst(a5)
	move.l	#fm_return,(sp)
	jsr	iw_fm0
	bra	next_cmd_fm

midi_to_adpcm:
	swap	d4
	move.b	(a0)+,d4
	lsl.w	#8,d4
	move.b	(a0)+,d4
	move.l	d4,p_type(a5)
	move.l	#int_play_ope_ad,p_int_play_ope(a5)
	move.w	p_detune(a5),d0
	muls	#3,d0
	asr.l	#5,d0
	move.w	d0,p_detune(a5)
	move.w	p_bend_dst(a5),d0
	muls	#3,d0
	asr.l	#5,d0
	move.w	d0,p_bend_dst(a5)
	move.l	#ad_return,(sp)
	jsr	iw_ad0
	bra	next_cmd_ad

asgn_chg_ad:			*ADPCM チャンネル切り換え
	move.b	(a0)+,d4	*type
	lsl.w	#8,d4
	move.b	(a0)+,d4	*type
	tst.w	d4
	bmi	adpcm_to_midi
	beq	adpcm_to_fm
adpcm_to_adpcm:
	swap	d4
	move.b	(a0)+,d4	*ch
	lsl.w	#8,d4
	move.b	(a0)+,d4	*ch
	move.w	d4,p_ch(a5)
	bra	next_cmd_ad

adpcm_to_fm:
	swap	d4
	move.b	(a0)+,d4
	lsl.w	#8,d4
	move.b	(a0)+,d4
	move.l	d4,p_type(a5)
	move.l	#int_play_ope_fm,p_int_play_ope(a5)
	move.l	opmset_bsr_ms-work(a6),p_opmset(a5)
	move.l	#fm_return,(sp)
	jsr	iw_fm0
	bra	next_cmd_fm
*------------------------------------------------------------------------------
ch_pressure_md:			*チャンネルプレッシャー
	move.b	(a0)+,d1
	moveq.l	#$d0,d0			*ch pressure
	add.b	d4,d0
	move.l	p_midi_trans(a5),a2
	jsr	(a2)
	move.b	d1,d0			*velocity
	jsr	(a2)
	bra	next_cmd_md

rltv_ch_pressure_md:			*相対チャンネルプレッシャー
	move.b	(a0)+,d1
	add.b	p_velo(a5),d1		*相対値を加算するが結果は1回限りの使い捨て
	bpl	@f
	tst.b	-1(a0)
	bmi	cprm_vlzr
	moveq.l	#127,d1
	bra	@f
cprm_vlzr:
	moveq.l	#0,d1
@@:
	moveq.l	#$d0,d0			*ch pressure
	add.b	d4,d0
	move.l	p_midi_trans(a5),a2
	jsr	(a2)
	move.b	d1,d0			*velocity
	jsr	(a2)
	bra	next_cmd_md
*------------------------------------------------------------------------------
polyphonic_pressure_fm:		*ポリフォニックプレッシャー
	move.w	p_voice_rsv(a5),d1	*loop counter
	lea	p_note(a5),a1
	move.b	(a0)+,d7	*get note.b
	bmi	@f		*相対指定のケース
	move.b	(a0)+,d0
	bsr	getset_vol2
*	tst.w	p_level_param(a5)
*	bne	next_cmd_fm
*	move.w	#4,p_level_param(a5)
	or.w	#$0100,p_level_param(a5)	*!5/28
	bra	next_cmd_fm
@@:
	andi.w	#$7f,d7
	move.b	(a0)+,d0
	bsr	getset_vol3
*	tst.w	p_level_param(a5)
*	bne	next_cmd_fm
*	move.w	#4,p_level_param(a5)
	or.w	#$0100,p_level_param(a5)	*!5/28
	bra	next_cmd_fm

polyphonic_pressure_ad:		*ポリフォニックプレッシャー
	move.w	p_voice_rsv(a5),d1	*loop counter
	lea	p_note(a5),a1
	move.b	(a0)+,d7	*get note.b
	bmi	@f		*相対指定のケース
	move.b	(a0)+,d0
	bsr	getset_vol2
*	tst.w	p_level_param(a5)
*	bne	next_cmd_ad
*	move.w	#4,p_level_param(a5)
	or.w	#$0100,p_level_param(a5)	*!5/28
	bra	next_cmd_ad
@@:
	andi.w	#$7f,d7
	move.b	(a0)+,d0
	bsr	getset_vol3
*	tst.w	p_level_param(a5)
*	bne	next_cmd_ad
*	move.w	#4,p_level_param(a5)
	or.w	#$0100,p_level_param(a5)	*!5/28
	bra	next_cmd_ad

getset_vol2:				*音量値をノートワークにもセット
	* < d7.b=key note number
	* < d0=volume value 0-127
	* X d0-d1/a1
gsvlp02:
	cmp.b	(a1),d7
	bne	gstv2_0
	tst.b	k_velo(a1)
	bmi	@f
	move.b	d0,k_velo(a1)
	rts
@@:
	tas.b	d0
	move.b	d0,k_velo(a1)
	rts
gstv2_0:
	addq.w	#k_note_len,a1
	dbra	d1,gsvlp02
	rts

getset_vol3:				*音量値をノートワークにもセット(相対PLUS)
	* < d7.b=key note number
	* < d0=volume value +127
	* X d0-d1/a1
gsvlp03:
	cmp.b	(a1),d7
	bne	gstv3_0
	tst.b	k_velo(a1)		*そこで打ち止め
	bmi	@f
do_gsv3:
	add.b	d0,k_velo(a1)
	bpl	exit_gsv3
	bcs	gsv_vlzr
	move.b	#127,k_velo(a1)
exit_gsv3:
	rts
gsv_vlzr:
	clr.b	k_velo(a1)
	rts
@@:
	andi.b	#$7f,k_velo(a1)
	bsr	do_gsv3
	tas.b	k_velo(a1)
	rts
gstv3_0:
	addq.w	#k_note_len,a1
	dbra	d1,gsvlp03
	rts

polyphonic_pressure_md:		*ポリフォニックプレッシャー
	moveq.l	#max_note_on-1,d2
	lea	p_note(a5),a1
	move.l	p_midi_trans(a5),a2
	move.b	(a0)+,d7	*get note.b
	bmi	ppm_rltv	*相対指定のケース
	move.b	(a0)+,d1
ppm_lp00:				*絶対指定
	move.b	(a1),d0
	bmi	1f
	cmp.b	d7,d0
	beq	@f
	addq.w	#k_note_len,a1
	dbra	d2,ppm_lp00
	bra	next_cmd_md
@@:
	move.b	d1,k_velo(a1)
1:
	moveq.l	#$a0,d0			*polyphonic pressure
	add.b	d4,d0
	jsr	(a2)
	move.b	d7,d0
	jsr	(a2)
	move.b	d1,d0			*velocity
	jsr	(a2)
	bra	next_cmd_md
ppm_rltv:				*相対指定
	andi.w	#$7f,d7
	move.b	(a0)+,d1
ppm_lp01:				*相対指定(PLUS)
	move.b	(a1),d0
	bmi	next_cmd_md
	cmp.b	d7,d0
	bne	ppm01_next
	add.b	k_velo(a1),d1
	bpl	@f
	tst.b	-1(a0)
	bmi	ppm01_vlzr
	moveq.l	#127,d1
	bra	@f
ppm01_vlzr:
	moveq.l	#0,d1
@@:
	move.b	d1,k_velo(a1)
	moveq.l	#$a0,d0			*polyphonic pressure
	add.b	d4,d0
	jsr	(a2)
	move.b	d7,d0
	jsr	(a2)
	move.b	d1,d0			*velocity
	jsr	(a2)
	bra	next_cmd_md
ppm01_next:
	addq.w	#k_note_len,a1
	dbra	d2,ppm_lp01
	bra	next_cmd_md
*------------------------------------------------------------------------------
rltv_velo_md:			*MIDI 相対ベロシティ
	move.b	p_velo16(a5),d0
	bpl	rltv_velo16
	move.b	p_velo(a5),d0
	add.b	(a0)+,d0
	bpl	st_rvm
	tst.b	-1(a0)
	bmi	@f		*case:minus value
	moveq.l	#127,d0
	bra	st_rvm
@@:
	moveq.l	#0,d0
st_rvm:
	move.b	d0,p_velo(a5)
	bra	next_cmd_md

rltv_vol2_fm:			*FM 相対ボリューム
	move.b	p_vol16(a5),d0
	bpl	rltv_vol16_fm
rltv_ch_pressure_fm:		*相対チャンネルプレッシャー
rltv_velo_fm:			*FM 相対ベロシティ
rltv_vol_fm:			*FM 相対ボリューム
	move.b	p_vol(a5),d0
	add.b	(a0)+,d0
	bpl	_volume_fm
	tst.b	-1(a0)
	bmi	@f		*case:minus value
	moveq.l	#127,d0
	bra	_volume_fm
@@:
	moveq.l	#0,d0
	bra	_volume_fm

rltv_vol16_fm:			*FM 相対ボリューム(16段階)
	add.b	(a0)+,d0
	cmpi.b	#16,d0
	bls	cnv_l127_fm
	tst.b	-1(a0)
	bmi	@f
	moveq.l	#16,d0
	bra	cnv_l127_fm
@@:
	moveq.l	#0,d0
cnv_l127_fm:
	move.b	d0,p_vol16(a5)
	ext.w	d0
	move.b	vol_tbl(pc,d0.w),d0
	bra	_volume_fm

vol_tbl:	*0 1  2  3  4  5  6   7   8   9   10  11  12  13  14  15  16
	dc.b	85,87,90,93,95,98,101,103,106,109,111,114,117,119,122,125,127
	.even

ch_pressure_fm:			*チャンネルプレッシャー
velocity_fm:			*ベロシティ設定
volume_fm:			*FM音量設定
	move.b	(a0)+,d0
	bpl	@f
	andi.w	#$7f,d0		*FM 16段階音量指定
	move.b	d0,p_vol16(a5)
	move.b	vol_tbl(pc,d0.w),d0
	bra	_volume_fm
@@:
	st.b	p_vol16(a5)
_volume_fm:
	move.b	d0,p_velo(a5)	*FMではvelo=vol
	bsr	getset_vol
*	tst.w	p_level_param(a5)
*	bne	next_cmd_fm
*	move.w	#4,p_level_param(a5)
	or.w	#$0100,p_level_param(a5)	*!5/28
	bra	next_cmd_fm

rltv_vol2_ad:			*ADPCM 相対ボリューム
	move.b	p_vol16(a5),d0
	bpl	rltv_vol16_ad
rltv_ch_pressure_ad:		*相対チャンネルプレッシャー
rltv_velo_ad:			*ADPCM 相対ベロシティ
rltv_vol_ad:			*ADPCM 相対ボリューム
	move.b	p_vol(a5),d0
	add.b	(a0)+,d0
	bpl	_volume_ad
	tst.b	-1(a0)
	bmi	@f		*case:minus value
	moveq.l	#127,d0
	bra	_volume_ad
@@:
	moveq.l	#0,d0
	bra	_volume_ad

ch_pressure_ad:			*チャンネルプレッシャー
velocity_ad:			*ADPCMベロシティ設定
volume_ad:			*ADPCM音量設定
	move.b	(a0)+,d0
	bpl	@f
	bsr	get_vol16	*ADPCM 16段階音量指定
	bra	_volume_ad
@@:
	st.b	p_vol16(a5)
_volume_ad:
	move.b	d0,p_velo(a5)	*ADPCMではvelo=vol
	bsr	getset_vol
*	tst.w	p_level_param(a5)
*	bne	next_cmd_ad
*	move.w	#4,p_level_param(a5)
	or.w	#$0100,p_level_param(a5)	*!5/28
	bra	next_cmd_ad

getset_vol:				*音量値を取り出してノートワークにもセット
	* < volume value 0-127
	* X d0-d1/a1
	move.b	d0,p_vol(a5)		*0-127
	move.w	p_voice_rsv(a5),d1	*loop counter
	lea	p_note+k_velo(a5),a1
gsvlp:
	tst.b	(a1)			*そこで打ち止め
	bmi	@f
	move.b	d0,(a1)
	addq.w	#k_note_len,a1
	dbra	d1,gsvlp
	rts
@@:
	move.b	d0,(a1)
	tas.b	(a1)
	addq.w	#k_note_len,a1
	dbra	d1,gsvlp
	rts

rltv_vol2_md:			*MIDI 相対ボリューム
	move.b	p_vol16(a5),d0
	bpl	rltv_vol16_md
rltv_vol_md:			*MIDI 相対ボリューム
	move.b	p_vol(a5),d0
	add.b	(a0)+,d0
	bpl	_volume_md
	tst.b	-1(a0)
	bmi	@f		*case:minus value
	moveq.l	#127,d0
	bra	_volume_md
@@:
	moveq.l	#0,d0
	bra	_volume_md

rltv_vol16_md:			*16段階指定
	add.b	(a0)+,d0
	cmpi.b	#16,d0
	bls	cnv_l127md
	tst.b	-1(a0)
	bmi	@f
	moveq.l	#16,d0
	bra	cnv_l127md
@@:
	moveq.l	#0,d0
cnv_l127md:
	move.b	d0,p_vol16(a5)
	ext.w	d0
	move.b	vol_tbl2(pc,d0.w),d0
	bra	_volume_md

rltv_velo16:			*16段階指定
	add.b	(a0)+,d0
	cmpi.b	#16,d0
	bls	cnvel_l127
	tst.b	-1(a0)
	bmi	@f
	moveq.l	#16,d0
	bra	cnvel_l127
@@:
	moveq.l	#0,d0
cnvel_l127
	move.b	d0,p_velo16(a5)
	ext.w	d0
	move.b	vol_tbl2(pc,d0.w),p_velo(a5)
	bra	next_cmd_md

vol_tbl2:	*	0 1  2  3  4  5  6  7  8  9 10 11 12  13  14  15  16
*	dc.b		0,7,15,23,31,39,47,55,63,71,79,87,95,103,111,119,127
	dc.b		0,8,16,24,32,40,48,56,64,72,80,88,96,104,112,120,127
	.even

rltv_vol16_ad:			*16段階指定
	add.b	(a0)+,d0
	cmpi.b	#16,d0
	bls	cnv_l127ad
	tst.b	-1(a0)
	bmi	@f
	moveq.l	#16,d0
	bra	cnv_l127ad
@@:
	moveq.l	#0,d0
cnv_l127ad:
	move.b	d0,p_vol16(a5)
	ext.w	d0
	move.b	vol_tbl2(pc,d0.w),d0
	bra	_volume_ad

velocity_md:			*MIDIベロシティ設定
	move.b	(a0)+,d0
	bpl	@f
	andi.w	#$7f,d0
	move.b	d0,p_velo16(a5)
	move.b	vol_tbl2(pc,d0.w),p_velo(a5)	*0-127
	bra	next_cmd_md
@@:
	st.b	p_velo16(a5)
	move.b	d0,p_velo(a5)	*0-127
	bra	next_cmd_md

volume16_md:			*MIDI 16段階音量指定
	pea	_volume_md(pc)

get_vol16:
	andi.w	#$7f,d0
	move.b	d0,p_vol16(a5)
	move.b	vol_tbl2(pc,d0.w),d0
	rts

volume_md:			*MIDI音量設定
	move.b	(a0)+,d0
	bmi	volume16_md
	st.b	p_vol16(a5)
_volume_md:
	move.b	d0,p_vol(a5)	*0-127
	check_concur	MIDI_VOL
	bset.b	#pts_volume,p_timbre_set(a5)	*音量設定フラグオン
	bra	next_cmd_md

do_md_volume	macro	xx
	* < d1.b=0-127
	* < d4.w=ch
	* X d0-d1,a4
	moveq.l	#$b0,d0
	or.b	d4,d0
	bsr	xx
	moveq.l	#MIDI_VOL,d0
	bsr	xx
	move.b	d1,d0
	bra	xx
	endm

do_md_volume_m0:	do_md_volume	m_out_m0
do_md_volume_m1:	do_md_volume	m_out_m1
do_md_volume_r0:	do_md_volume	m_out_r0
do_md_volume_r1:	do_md_volume	m_out_r1

do_fm_volume_fdr:			*FADER処理系の時はここへエントリ
	* < d0=127-volume
	* < d4=fm ch
	* - d0
	* X d1,d2,a4
	move.b	cf-work(a6,d4.w),d1
	swap	d1
	move.w	#$60,d1
	or.b	d4,d1

	btst.l	#0+16,d1
	beq	2f
	move.l	d0,-(sp)
	move.b	ol1-work(a6,d4.w),d2	*OP1
	bsr	consider_fader_fm
	add.b	d0,d2
	bpl	@f
	moveq.l	#127,d2
@@:
	jsr	(a4)			*opmset
	move.l	(sp)+,d0
2:
	addq.b	#8,d1
	btst.l	#2+16,d1
	beq	2f
	move.l	d0,-(sp)
	move.b	ol3-work(a6,d4.w),d2	*OP3
	bsr	consider_fader_fm
	add.b	d0,d2
	bpl	@f
	moveq.l	#127,d2
@@:
	jsr	(a4)
	move.l	(sp)+,d0
2:
	addq.b	#8,d1
	btst.l	#1+16,d1
	beq	2f
	move.l	d0,-(sp)
	move.b	ol2-work(a6,d4.w),d2	*OP2
	bsr	consider_fader_fm
	add.b	d0,d2
	bpl	@f
	moveq.l	#127,d2
@@:
	jsr	(a4)			*opmset
	move.l	(sp)+,d0
2:
	addq.b	#8,d1
	move.l	d0,-(sp)
	move.b	ol4-work(a6,d4.w),d2	*OP4
	cmpi.w	#7,d4
	bne	@f
	tst.b	$0f+opmreg(a6)
	bpl	@f
	bsr	consider_fader_fm_n
	bra	1f
@@:
	bsr	consider_fader_fm
1:
	add.b	d0,d2
	bpl	@f
	moveq.l	#127,d2
@@:
	jsr	(a4)			*opmset
	move.l	(sp)+,d0
	rts

_do_ad_volume:			*フェーダー考慮付きADPCM音量設定
	* < d0=0-127
	* < d4=ad ch(0-15)
	bsr	consider_fader_ad
do_ad_volume:			*ADPCM音量設定
	* < d0=0-127
	* < d4=ad ch(0-15)
	* X d0,d1
	move.l	d0,d1
do_ad_volume_:			*単声モード時はパッチ(rts)が当たる
	move.w	#M_SET_VOL,d0
	move.b	d4,d0
	MPCM_call
	rts
*------------------------------------------------------------------------------
do_kn_fm	macro	mode
	* < d4.l=type,ch		*mode=1:ms_key_off_fmから参照されている
	* - a4
	* x d0
reglist	reg	d1-d3/d6/a1/a4
	local	fko_lp_f,exit_kn_fm
	.if	(mode=0)
	tst.b	p_how_many(a5)
	bmi	exit_kn_fm		*already all off
	.endif
	movem.l	reglist,-(sp)
	move.w	p_voice_rsv(a5),d6	*loop counter
	lea	p_note(a5),a1
	.if	(mode=0)
	tst.b	p_track_mode(a5)
	bmi	_case_nof2_fm
	.endif
	move.w	d4,d0
	move.l	p_opmset(a5),a4
fko_lp_f:
	tas.b	(a1)				*note.b
	.if	(mode=0)
	bmi	@f
	.endif
	moveq.l	#8,d1				*FM reg. number
	move.b	opm_kon-work(a6,d0.w),d2
	and.b	opm_nom-work(a6,d0.w),d2
	jsr	(a4)				*opmset(FM key off)
	bset.b	#b_keyoff,p_onoff_bit(a5)	*set key off bit
@@:
	.if	(mode)
	move.w	sr,-(sp)
	ori.w	#$0700,sr

	move.w	#$e0,d1				*わざとmove.w
	add.b	d0,d1
	moveq.l	#$ff,d2
	moveq.l	#4-1,d3
1:
	move.b	opmreg(a6,d1.w),-(sp)
	jsr	(a4)				*1DL=RR=15
	move.b	(sp)+,opmreg(a6,d1.w)
	addq.w	#8,d1
	dbra	d3,1b

*	moveq.l	#$20,d1				*AF
*	add.b	d0,d1
*	move.b	opmreg(a6,d1.w),d2
*	move.b	d2,d3
*	andi.w	#%0011_1111,d2
*	jsr	(a4)				*PAN Off
*	move.b	d3,opmreg(a6,d1.w)
	move.w	(sp)+,sr
	.endif

	addq.w	#k_note_len,a1
	addq.w	#1,d0
	andi.w	#7,d0
	dbra	d6,fko_lp_f
	st.b	p_how_many(a5)		all key off
	movem.l	(sp)+,reglist
exit_kn_fm:
	rts

	.if	(mode=0)
_case_nof2_fm:
	* < a1.l=p_note
	* < d6.l=loop counter
@@:
	ori.l	#$8000,(a1)+
	dbra	d6,@b
	st.b	p_how_many(a5)
	movem.l	(sp)+,reglist
	rts
	.endif
	endm

do_kn_ad	macro	mode
	* < d4.l=type,ch		*mode=1:ms_key_off_adから参照されている
	* x d0
reglist	reg	d1-d2/d5-d6/a1
	local	fko_lp_a,exit_kn_ad
	.if	(mode=0)
	tst.b	p_how_many(a5)
	bmi	exit_kn_ad		*already all off
	.endif
	movem.l	reglist,-(sp)
	move.w	p_voice_rsv(a5),d6	*loop counter
	lea	p_note(a5),a1
	.if	(mode=0)
	tst.b	p_track_mode(a5)
	bmi	_case_nof2_ad
	.endif
	moveq.l	#0,d5
	move.b	d4,d5
fko_lp_a:
	tas.b	(a1)			*note.b
	.if	(mode=0)
	bmi	@f
	.endif
	move.l	d5,d0
	bsr	pcm_key_off
	bset.b	#b_keyoff,p_onoff_bit(a5)	*set key off bit
@@:
	addq.w	#k_note_len,a1
	addq.b	#1,d5
	andi.b	#$0f,d5
	dbra	d6,fko_lp_a
	st.b	p_how_many(a5)
	movem.l	(sp)+,reglist
exit_kn_ad:
	rts

	.if	(mode=0)
_case_nof2_ad:
	* < a1.l=p_note
	* < d6.l=loop counter
@@:
	ori.l	#$8000,(a1)+
	dbra	d6,@b
	st.b	p_how_many(a5)
	movem.l	(sp)+,reglist
	rts
	.endif
	.endm

do_kn_md	macro	mode
	* < d4.l=type,ch		*mode=1:ms_key_off_mdから参照されている
	* x d0,a2,a4
reglist	reg	d1-d2/d6/a1
	local	fko_lp_m
	.if	(mode=0)
	tst.b	p_track_mode(a5)
	bmi	_case_nof2_md
	.endif
	movem.l	reglist,-(sp)
	moveq.l	#max_note_on-1,d6	*max note on
	lea	p_note(a5),a1
	move.l	p_midi_trans(a5),a2
	.if	(mode)
	move.b	(a1),d1
	bpl	1f
	moveq.l	#$b0,d0
	add.b	d4,d0
	jsr	(a2)			*send cmd
	moveq.l	#$78,d0
	jsr	(a2)
	moveq.l	#$00,d0
	jsr	(a2)			*all sound off
	movem.l	(sp)+,reglist
	rts
	.endif
fko_lp_m:
	move.b	(a1),d1			*note
	bmi	@f			*exit
1:
	moveq.l	#$90,d0
	add.b	d4,d0
	jsr	(a2)			*send cmd
	move.b	d1,d0
	jsr	(a2)			*note number
	bset.b	#b_keyoff,p_onoff_bit(a5)	*set key off bit
	moveq.l	#$00,d0
	jsr	(a2)			*#0
	move.l	#-1,(a1)+
	dbra	d6,fko_lp_m
@@:
	movem.l	(sp)+,reglist
	rts

	.if	(mode=0)
_case_nof2_md:
	move.w	#-1,p_note(a5)		*すべて殺したことを記す
	rts
	.endif
	.endm

kill_note_fm:
	move.b	(a0)+,d1
	bmi	knm_m_stop_all
	beq	@f
	bsr	do_kn_fm
	cmpi.b	#2,d1
	bne	next_cmd_fm
	bra	play_end_fm
@@:
	pea	next_cmd_fm(pc)
do_kill_note_fm:
	do_kn_fm	0	*FM 強制キーオフ
do_kn_fm:
	do_kn_fm	1	*call from ms_key_off_fm

kill_note_ad:
	move.b	(a0)+,d1
	bmi	knm_m_stop_all
	beq	@f
	bsr	do_kn_ad
	cmpi.b	#2,d1
	bne	next_cmd_ad
	bra	play_end_ad
@@:
	pea	next_cmd_ad(pc)
do_kill_note_ad:
	do_kn_ad	0	*ADPCM 強制キーオフ
do_kn_ad:
	do_kn_ad	1	*call from ms_key_off_ad

kill_note_md:
	move.b	(a0)+,d1
	bmi	knm_m_stop_all
	beq	@f
	bsr	do_kn_md
	cmpi.b	#2,d1
	bne	next_cmd_md
	bra	play_end_md
@@:
	pea	next_cmd_md(pc)
do_kill_note_md:
	do_kn_md	0	*MIDI 強制キーオフ
do_kn_md:
	do_kn_md	1	*call from ms_key_off_md

knm_m_stop_all:
reglist	reg	d0/a1-a2/a5
	movem.l	reglist,-(sp)
	move.l	play_trk_tbl_se-work(a6),a1
	move.l	seq_wk_tbl_se-work(a6),a2
	btst.b	#_ID_SE,p_track_stat(a5)
	bne	1f
	move.l	play_trk_tbl-work(a6),a1
	move.l	seq_wk_tbl-work(a6),a2
1:
	moveq.l	#0,d0
	move.w	(a1)+,d0
	bmi	3f
	swap	d0
	lsr.l	#16-trwk_size_,d0
	lea	(a2,d0.l),a5
	tst.b	p_track_stat(a5)	*死んでるトラックは再演奏不可
	bmi	1b
	tst.w	p_type(a5)
	beq	@f			*FM
	bmi	2f			*MIDI
	movem.l	a1-a2,-(sp)
	bsr	do_kill_note_ad
	bsr	play_end_ad
	movem.l	(sp)+,a1-a2
	bra	1b
@@:
	movem.l	a1-a2,-(sp)
	bsr	do_kill_note_fm
	bsr	play_end_fm
	movem.l	(sp)+,a1-a2
	bra	1b
2:
	movem.l	a1-a2,-(sp)
	bsr	do_kill_note_md
	bsr	play_end_md
	movem.l	(sp)+,a1-a2
	bra	1b
3:
	movem.l	(sp)+,reglist
	rts
*------------------------------------------------------------------------------
auto_portament_ad:		*ADPCM オートポルタメント
	bsr	get_auto_portament_param
	bra	next_cmd_ad

auto_portament_md:		*MIDI オートポルタメント
	bset.b	#b_tie_mode,p_md_flg(a5)
	bsr	get_auto_portament_param
	bra	next_cmd_md

auto_portament_fm:		*FM オートポルタメント
	pea	next_cmd_fm(pc)

get_auto_portament_param:
	move.b	(a0)+,d0
	bmi	@f
	move.b	p_port2_flg(a5),d1	*get prev.sw
	move.b	d0,p_port2_flg(a5)	*set sw
	bmi	@f			*no touch case
	tst.b	d1
	bne	@f
	st.b	p_last_note(a5)		*0→1のときp_last_note初期化
@@:
	move.b	(a0)+,d1		*get omt
	beq	exit_gapp
	bpl	get_atp_tail
	move.b	(a0)+,p_port2_dly+0(a5)	*get delay
	move.b	(a0)+,p_port2_dly+1(a5)
get_atp_tail:
	add.b	d1,d1
	bpl	exit_gapp
	move.b	(a0)+,p_port2_cnt+0(a5)	*get tail
	move.b	(a0)+,p_port2_cnt+1(a5)
exit_gapp:
	rts
*------------------------------------------------------------------------------
key_transpose_fm:			*FM キートランスポーズ
	move.b	(a0)+,p_transpose(a5)
	bra	next_cmd_fm

key_transpose_ad:			*ADPCM キートランスポーズ
	move.b	(a0)+,p_transpose(a5)
	bra	next_cmd_ad

key_transpose_md:			*MIDI キートランスポーズ
	move.b	(a0)+,p_transpose(a5)
	bra	next_cmd_md
*------------------------------------------------------------------------------
voice_reserve_fm:			*FM 発音数予約
	move.b	(a0)+,p_voice_rsv+1(a5)
	bset.b	#b_voice_rsv,p_md_flg(a5)
	bra	next_cmd_fm

voice_reserve_ad:			*ADPCM 発音数予約
	move.b	(a0)+,p_voice_rsv+1(a5)
	bset.b	#b_voice_rsv,p_md_flg(a5)
	bra	next_cmd_ad
*------------------------------------------------------------------------------
rltv_@b_ad:				*ADPCM 相対ベンド
	bsr	get_@b_@k
	bsr	border_chk_@k
	bra	set_dtn_ad

rltv_@b_fm:				*FM 相対ベンド
	bsr	get_@b_@k
	pea	set_dtn_fm(pc)

border_chk_@k:
	add.w	p_detune(a5),d0
	cmp.w	#7680,d0		境界チェック
	ble	@f
	move.w	#7680,d0
	bra	st_r@k
@@:
	cmp.w	#-7680,d0
	bge	st_r@k
	move.w	#-7680,d0
st_r@k:
	move.w	d0,p_detune(a5)
	rts

rltv_@b_md:				*MIDI 相対ベンド
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0
	bsr	border_chk_@b
	bra	set_dtn_md

rltv_@k_fm:				*FM 相対ベンド
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0
	bsr	border_chk_@k
	bra	set_dtn_fm

rltv_@k_ad:				*ADPCM 相対ベンド
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0
	bsr	border_chk_@k
	bra	set_dtn_ad

rltv_@k_md:				*MIDI 相対ベンド
	bsr	get_@k_@b
	pea	set_dtn_md(pc)
border_chk_@b:
	add.w	p_detune(a5),d0
	cmp.w	#8191,d0		境界チェック
	ble	@f
	move.w	#8191,d0
	bra	st_r@b
@@:
	cmp.w	#-8192,d0
	bge	st_r@b
	move.w	#-8192,d0
st_r@b:
	move.w	d0,p_detune(a5)
	rts

detune_@b_fm:				*デチューン(@B RANGE→@K RANGE)
	bsr	get_@b_@k
	move.w	d0,p_detune(a5)		*save detune.@k
	bra	set_dtn_fm

detune_@b_ad:				*デチューン(@B RANGE→@K RANGE)
	bsr	get_@b_@k
	move.w	d0,p_detune(a5)		*save detune.@k
	bra	set_dtn_ad

detune_@b_md:				*デチューン(@B RANGE→@B RANGE)
	move.b	(a0)+,p_detune+0(a5)
	move.b	(a0)+,p_detune+1(a5)		*get fm start
set_dtn_md:
	clr.b	p_bend_sw(a5)
	clr.l	p_port_pitch(a5)		*3/28
	tst.w	p_pitch_param(a5)
	bne	next_cmd_md
	move.w	#8,p_pitch_param(a5)
	bra	next_cmd_md

detune_@k_fm:				*デチューン(@K RANGE→@K RANGE)
	move.b	(a0)+,p_detune+0(a5)
	move.b	(a0)+,p_detune+1(a5)		*get fm start
set_dtn_fm:
	clr.b	p_bend_sw(a5)
	tst.w	p_pitch_param(a5)
	bne	next_cmd_fm
	move.w	#8,p_pitch_param(a5)
	bra	next_cmd_fm

detune_@k_ad:				*デチューン(@K RANGE→@K RANGE)
	move.b	(a0)+,p_detune+0(a5)
	move.b	(a0)+,p_detune+1(a5)		*get fm start
set_dtn_ad:
	clr.b	p_bend_sw(a5)
	tst.w	p_pitch_param(a5)
	bne	next_cmd_ad
	move.w	#8,p_pitch_param(a5)
	bra	next_cmd_ad

detune_@k_md:				*デチューン(@K RANGE→@B RANGE)
	bsr	get_@k_@b
	move.w	d0,p_detune(a5)		*save detune.@k
	bra	set_dtn_md

bend_off_fm:				*オートベンドオフ(in case omt=0)
	move.b	d1,p_bend_sw(a5)
	bra	next_cmd_fm

bend_off_ad:				*オートベンドオフ(in case omt=0)
	move.b	d1,p_bend_sw(a5)
	bra	next_cmd_ad

bend_off_md:				*オートベンドオフ(in case omt=0)
	move.b	d1,p_bend_sw(a5)
	bra	next_cmd_md

bend_@b_ad:				*オートベンド(@B RANGE→@K RANGE)
	move.b	(a0)+,d1		*get omt
	beq	bend_off_ad
	bpl	@f
	bsr	get_@b_@k
	move.w	d0,p_detune(a5)		*save detune.@k
	move.b	#1,p_bend_sw(a5)	*bend switch on
@@:
	bsr	get_dst_dly_@b_@k
	bra	next_cmd_ad

get_@b_@k:
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0		*get detune.@b
	muls	#3,d0
	asr.l	#5,d0
	rts

bend_@b_fm:				*オートベンド(@B RANGE→@K RANGE)
	move.b	(a0)+,d1		*get omt
	beq	bend_off_fm
	bpl	@f
	bsr	get_@b_@k
	move.w	d0,p_detune(a5)		*save detune.@k
	move.b	#1,p_bend_sw(a5)	*bend switch on
@@:
	pea	next_cmd_fm(pc)

get_dst_dly_@b_@k:
	add.b	d1,d1			*omt check
	bpl	@f
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0		*get bend_end.@b
	muls	#3,d0
	asr.l	#5,d0
	move.w	d0,p_bend_dst(a5)	*save bend_end.@k
	move.b	#1,p_bend_sw(a5)	*bend switch on
@@:
get_delay_tail:
	add.b	d1,d1			*omt check
	bpl	get_gdd_tail
	move.b	(a0)+,p_bend_dly+0(a5)	*get dly
	move.b	(a0)+,p_bend_dly+1(a5)
get_gdd_tail:
	add.b	d1,d1			*omt check
	bpl	exit_gdd
	move.b	(a0)+,p_bend_cnt+0(a5)	*get tail
	move.b	(a0)+,p_bend_cnt+1(a5)
exit_gdd:
	rts

get_@k_@b:
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0		*get detune.@b
	ext.l	d0
	chg64_683	d0
	rts

bend_@k_md:				*オートベンド(@K RANGE→@B RANGE)
	move.b	(a0)+,d1		*get omt
	beq	bend_off_md
	bpl	@f
	bsr	get_@k_@b
	move.w	d0,p_detune(a5)		*save detune.@k
	move.b	#1,p_bend_sw(a5)	*bend switch on
@@:
	add.b	d1,d1			*omt check
	bpl	@f
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0		*get bend_end.@b
	ext.l	d0
	chg64_683	d0
	move.w	d0,p_bend_dst(a5)	*save bend_end.@k
	move.b	#1,p_bend_sw(a5)	*bend switch on
@@:
	pea	next_cmd_md(pc)
	bra	get_delay_tail

bend_@k_fm:				*オートベンド(@K RANGE→@K RANGE)
	bsr	get_no_conv
	bra	next_cmd_fm

bend_@k_ad:				*オートベンド(@K RANGE→@K RANGE)
	bsr	get_no_conv
	bra	next_cmd_ad

bend_@b_md:
	pea	next_cmd_md(pc)

get_no_conv:
	move.b	(a0)+,d1		*get omt
	beq	bend_off
	bpl	@f
	move.b	(a0)+,p_detune+0(a5)
	move.b	(a0)+,p_detune+1(a5)	*get fm start
	move.b	#1,p_bend_sw(a5)	*bend switch on
@@:
	add.b	d1,d1			*omt check
	bpl	get_delay_tail
	move.b	(a0)+,p_bend_dst+0(a5)
	move.b	(a0)+,p_bend_dst+1(a5)	*get fm end
	move.b	#1,p_bend_sw(a5)	*bend switch on
	bra	get_delay_tail
bend_off:
	move.b	d1,p_bend_sw(a5)
	rts
*------------------------------------------------------------------------------
skip_zmd_ad:				*ADPCM スキップコマンド
	pea	next_cmd_ad(pc)
	bra	@f

skip_zmd_md:				*MIDI スキップコマンド
	pea	next_cmd_md(pc)
	bra	@f

skip_zmd_fm:				*FM スキップコマンド
	pea	next_cmd_fm(pc)
@@:
	move.b	(a0)+,d1
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0
	swap	d0
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0
	tst.b	d1
	bne	@f
	adda.l	d0,a0
	rts
@@:
	move.l	d0,a0
	rts
*------------------------------------------------------------------------------
pmod_sync_fm:			*FM PMOD ホールド設定
	pea	next_cmd_fm(pc)
1:
	andi.b	#%0000_0111,p_pmod_flg(a5)	*b_pmod_sync,p_pmod_tiesync,p_pmod_rstsync
	move.b	(a0)+,d0			*b_pmod_wvsq,b_pmod_wvsqrst
	or.b	d0,p_pmod_flg(a5)
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0
	tst.w	d0
	beq	@f
	move.w	d0,p_pmod_syncnt(a5)
	move.w	d0,p_pmod_syncnt2(a5)
@@:
	rts

pmod_sync_ad:			*ADPCM PMOD ホールド設定
	pea	next_cmd_ad
	bra	1b

pmod_sync_md:			*MIDI PMOD ホールド設定
	pea	next_cmd_md
	bra	1b
*-----------------------------------------------------------------------------
arcc_sync_fm:			*FM ARCC ホールド設定
	pea	next_cmd_fm(pc)
	bra	@f

arcc_sync_ad:			*ADPCM ARCC ホールド設定
	pea	next_cmd_ad(pc)
	bra	@f

arcc_sync_md:
	pea	next_cmd_md(pc)
@@:
	bsr	get_arcc_a4
	andi.b	#%0000_0111,p_arcc_flg(a4)	*b_arcc_sync,p_arcc_tiesync,p_arcc_rstsync
	move.b	(a0)+,d0			*b_arcc_wvsq,b_arcc_wvsqrst
	or.b	d0,p_arcc_flg(a4)			*b_arcc_sync
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0
	tst.w	d0
	beq	@f
	move.w	d0,p_arcc_syncnt(a4)
	move.w	d0,p_arcc_syncnt2(a4)
@@:
	rts
*------------------------------------------------------------------------------
vseq_sync_fm:			*FM VSEQ ホールド設定
	pea	next_cmd_fm(pc)
	bra	@f

vseq_sync_ad:			*ADPCM VSEQ ホールド設定
	pea	next_cmd_ad(pc)
	bra	@f

vseq_sync_md:			*MIDI VSEQ ホールド設定
	pea	next_cmd_md(pc)
@@:
	lea	p_vseq_param(a5),a4
	andi.b	#%0001_1111,p_arcc_flg(a4)
	move.b	(a0)+,d0
	or.b	d0,p_arcc_flg(a4)
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0
	tst.w	d0
	beq	@f
	move.w	d0,p_arcc_syncnt(a4)
	move.w	d0,p_arcc_syncnt2(a4)
@@:
	rts
*------------------------------------------------------------------------------
tie_mode_md:				*MIDIのタイモードの設定
	tst.b	(a0)+
	beq	@f
	bset.b	#b_tie_mode,p_md_flg(a5)
	bra	next_cmd_md
@@:
	bclr.b	#b_tie_mode,p_md_flg(a5)
	bra	next_cmd_md
*------------------------------------------------------------------------------
pmod_sw_ad:				*ADPCM PMODスイッチ
	pea	next_cmd_ad(pc)
	bra	do_pmod_sw

pmod_sw_fm:				*FM PMODスイッチ
	pea	next_cmd_fm(pc)

do_pmod_sw:
	move.b	(a0)+,d0
	beq	dpmsw0
	cmpi.b	#previous_on,d0
	bne	@f
	tst.b	p_pmod_sw(a5)
	bne	exit_dpmsw
	move.b	p_pmod_sw2(a5),d0
	bne	@f
	moveq.l	#1,d0			*保存スイッチが0ならば1にしておく
@@:
	move.b	d0,p_pmod_sw(a5)
	bra	calc_pmod
dpmsw0:
	* < d0.b=0
	move.b	p_pmod_sw(a5),d1
	beq	exit_dpmsw
	move.b	d1,p_pmod_sw2(a5)
	move.b	d0,p_pmod_sw(a5)		*sw=0
	clr.w	p_pmod_dpt_now(a5)		*96/9/16
	bclr.b	#b_pmod_first,p_pmod_flg(a5)	*97/2/5
exit_dpmsw:
	rts

pmod_sw_md:				*MIDI PMODスイッチ
	move.b	(a0)+,d0
	beq	pmsm0
	cmpi.b	#previous_on,d0
	bne	@f
	tst.b	p_pmod_sw(a5)
	bne	next_cmd_md
	move.b	p_pmod_sw2(a5),d0
	bne	@f
	moveq.l	#1,d0			*保存スイッチが0ならば1にしておく
@@:
	move.b	d0,p_pmod_sw(a5)
*!2/5	bclr.b	#b_pmod_first,p_pmod_flg(a5)
	tst.b	p_pmod_mode(a5)
	bmi	next_cmd_md		*通常モードの場合はパラメータ計算不要*
	bsr	calc_pmod
	bra	next_cmd_md
pmsm0:
	move.b	p_pmod_sw(a5),d1
	beq	@f
	move.b	d1,p_pmod_sw2(a5)
	move.b	d0,p_pmod_sw(a5)
@@:
	bclr.b	#b_pmod_reset,p_md_flg(a5)
	beq	next_cmd_md
	move.l	p_midi_trans(a5),a2
	moveq.l	#$b0,d0
	or.b	d4,d0
	jsr	(a2)
	moveq.l	#$01,d0			*vibrato
	jsr	(a2)
	moveq.l	#$00,d0
	jsr	(a2)
	bra	next_cmd_md
*------------------------------------------------------------------------------
arcc_sw_ad:
	pea	next_cmd_ad(pc)
	bra	do_arcc_sw

arcc_sw_fm:				*FM ARCCスイッチ
	pea	next_cmd_fm(pc)
do_arcc_sw:
	bsr	get_arcc_a4
	move.b	(a0)+,d0
	beq	arsf0
	cmpi.b	#previous_on,d0
	bne	@f
	tst.b	p_arcc_sw(a4)
	bne	exit_arsf
	move.b	p_arcc_sw2(a4),d0
	bne	@f
	moveq.l	#1,d0			*保存スイッチが0ならば1にしておく
@@:
	move.b	d0,p_arcc_sw(a4)
	bra	calc_arcc
arsf0:
	move.b	p_arcc_sw(a4),d1
	beq	exit_arsf
	move.b	d1,p_arcc_sw2(a4)
	move.b	d0,p_arcc_sw(a4)
exit_arsf:
	rts

arcc_sw_md:				*FM PMODスイッチ
	bsr	get_arcc_a4
	move.b	(a0)+,d0
	beq	arsm0
	cmpi.b	#previous_on,d0
	bne	@f
	tst.b	p_arcc_sw(a4)
	bne	next_cmd_md
	move.b	p_arcc_sw2(a4),d0
	bne	@f
	moveq.l	#1,d0			*保存スイッチが0ならば1にしておく
@@:
	move.b	d0,p_arcc_sw(a4)
*!2/5	bclr.b	#b_arcc_first,p_arcc_flg(a4)
	tst.b	p_arcc_mode(a4)
	bmi	next_cmd_md		*通常モードの場合はパラメータ計算不要*
	bsr	calc_arcc
	bra	next_cmd_md
arsm0:
	move.b	p_arcc_sw(a4),d1
	beq	next_cmd_md
	move.b	d1,p_arcc_sw2(a4)
	move.b	d0,p_arcc_sw(a4)
	bra	next_cmd_md
*------------------------------------------------------------------------------
bend_sw_ad:				*ADPCM BENDスイッチ
	move.b	(a0)+,p_bend_sw(a5)
	bra	next_cmd_ad

bend_sw_fm:				*FM BENDスイッチ
	move.b	(a0)+,p_bend_sw(a5)
	bra	next_cmd_fm

bend_sw_md:				*MIDI BENDスイッチ
	move.b	(a0)+,p_bend_sw(a5)
	bra	next_cmd_md
*------------------------------------------------------------------------------
aftc_sw_ad:				*ADPCM AFTERTOUCH SEQUENCEスイッチ
	bsr	do_aftc_sw
	bra	next_cmd_ad

aftc_sw_md:				*MIDI AFTERTOUCH SEQUENCEスイッチ
	bsr	do_aftc_sw
	bra	next_cmd_md

aftc_sw_fm:				*FM AFTERTOUCH SEQUENCEスイッチ
	pea	next_cmd_fm(pc)

do_aftc_sw:
	move.b	(a0)+,d0
	beq	afsw0
	cmpi.b	#previous_on,d0
	bne	@f
	tst.b	p_aftc_sw(a5)
	bne	exit_afsw
	move.b	p_aftc_sw2(a5),d0
	bne	@f
	moveq.l	#1,d0			*保存スイッチが0ならば1にしておく
@@:
	move.b	d0,p_aftc_sw(a5)
exit_afsw:
	rts
afsw0:					*case:switch=0
	* < d0.b=0
	move.b	p_aftc_sw(a5),d1
	beq	@f
	move.b	d1,p_aftc_sw2(a5)
	move.b	d0,p_aftc_sw(a5)
	bclr.b	#b_aftc_first,p_aftc_flg(a5)	*97/2/5
@@:
	rts
*------------------------------------------------------------------------------
aftc_sync_fm:					*FM AFTERTOUCH 同期設定
	pea	next_cmd_fm(pc)
1:
	andi.b	#%0001_1111,p_aftc_flg(a5)	*b_aftc_sync,p_aftc_tiesync,p_aftc_rstsync
	move.b	(a0)+,d0			*b_aftc_wvsq,b_aftc_wvsqrst
	or.b	d0,p_aftc_flg(a5)
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0
	tst.w	d0
	beq	@f
	move.w	d0,p_aftc_syncnt(a5)
	move.w	d0,p_aftc_syncnt2(a5)
@@:
	rts

aftc_sync_ad:					*ADPCM AFTERTOUCH 同期設定
	pea	next_cmd_ad(pc)
	bra	1b

aftc_sync_md:					*MIDI AFTERTOUCH 同期設定
	pea	next_cmd_md(pc)
	bra	1b
*-----------------------------------------------------------------------------
vseq_deepen_ad:				*ADPCM VSEQ振幅増減
	lea	p_vseq_param(a5),a4
	bsr	get_arcc_deepen
	bra	next_cmd_ad

vseq_deepen_md:				*MIDI VSEQ振幅増減
	lea	p_vseq_param(a5),a4
	bsr	get_arcc_deepen
	bra	next_cmd_md

vseq_deepen_fm:				*FM VSEQ振幅増減
	lea	p_vseq_param(a5),a4
	bsr	get_arcc_deepen
	bra	next_cmd_fm
*-----------------------------------------------------------------------------
vseq_sw_fm:				*FM VSEQスイッチ
	lea	p_vseq_param(a5),a4
	bsr	do_vseq_sw
	bra	next_cmd_fm

vseq_sw_ad:				*ADPCM VSEQスイッチ
	lea	p_vseq_param(a5),a4
	bsr	do_vseq_sw
	bra	next_cmd_ad

vseq_sw_md:				*MIDI VSEQスイッチ
	lea	p_vseq_param(a5),a4
	pea	next_cmd_md(pc)
do_vseq_sw:				*VSEQ-SWの場合はここがエントリ
	move.b	(a0)+,d0
	beq	vssw0
	cmpi.b	#previous_on,d0
	bne	@f
	tst.b	p_arcc_sw(a4)
	bne	exit_vssw
	move.b	p_arcc_sw2(a4),d0
	bne	@f
	moveq.l	#1,d0			*保存スイッチが0ならば1にしておく
@@:
	move.b	d0,p_arcc_sw(a4)
	bra	calc_arcc
vssw0:					*sw=0
	* < d0.b=0
	move.b	p_arcc_sw(a4),d1
	beq	exit_vssw
	move.b	d1,p_arcc_sw2(a4)
	move.b	d0,p_arcc_sw(a4)	*0
	move.b	d0,p_arcc_dpt_now(a4)	*96/9/16
	bclr.b	#b_arcc_first,p_arcc_flg(a4)	*97/2/5
exit_vssw:
	rts
*------------------------------------------------------------------------------
aftertouch_ad:				*ADPCM アフタータッチシーケンス
	bsr	get_aftc
	bra	next_cmd_ad

aftertouch_md:				*MIDI アフタータッチシーケンス
	bsr	get_aftc
	bra	next_cmd_md

aftertouch_fm:				*FM アフタータッチシーケンス
	pea	next_cmd_fm(pc)

get_aftc:				*アフタータッチシーケンス・パラメータ取りだし
	* < d1.w=p_aftc_sw値
	move.b	(a0)+,d1		*get sw value(0,1,-1,2)
	beq	ntchaftc		*no touch when 0
	cmpi.b	#previous_on,d1
	bne	@f
	tst.b	p_aftc_sw(a5)
	bne	ntchaftc
	move.b	p_aftc_sw2(a5),d1
	bne	@f
	moveq.l	#1,d1			*保存スイッチが0ならば1にしておく
@@:
	move.b	d1,p_aftc_sw(a5)	*set sw value into sw1,2
	move.b	d1,p_aftc_sw2(a5)
ntchaftc:
	move.b	(a0)+,d0		*get omt
	move.b	d0,p_aftc_omt(a5)
	beq	aftc_sw0
	move.b	(a0)+,p_aftc_rltv(a5)	*get rltvmark
	lea	p_aftc_tbl(a5),a1
galp00:
	lsr.b	#1,d0
	bcc	@f
	move.b	(a0)+,(a1)
@@:
	addq.w	#1,a1
	tst.b	d0
	bne	galp00
	rts

aftc_sw0:					*アフタータッチシーケンス・オフ
	* < d0.b=0
	move.b	d0,p_aftc_sw(a5)
	move.b	p_vol(a5),p_aftc_level(a5)	*音量値でリセット
	bclr.b	#b_aftc_first,p_aftc_flg(a5)	*97/2/5
	rts

aftc_delay8_ad:				*ADPCMアフタータッチ・ディレイ設定(8point)
	bsr	get_afdl8
	bra	next_cmd_ad

aftc_delay8_md:				*MIDIアフタータッチ・ディレイ設定(8point)
	bsr	get_afdl8
	bra	next_cmd_md

aftc_delay8_fm:				*FMアフタータッチ・ディレイ設定(8point)
	pea	next_cmd_fm(pc)

get_afdl8:				*AFTCディレイ取りだし
	* X d0-d1/a1
	move.b	(a0)+,d0		*omt(case0:パラメータは9つある)
	lsl.w	#8,d0
	move.b	(a0)+,d0
	moveq.l	#0,d1
af8lp00:
	lsr.w	d0
	bcc	@f
	move.b	(a0)+,p_aftc_1st_dly+0(a5,d1.w)
	move.b	(a0)+,p_aftc_1st_dly+1(a5,d1.w)
@@:
	addq.w	#2,d1
	tst.w	d0
	bne	af8lp00
	rts
*------------------------------------------------------------------------------
agogik_sync_ad:			*ADPCM アゴギークホールド設定
	pea	next_cmd_ad(pc)
	bra	1f

agogik_sync_md:			*MIDI アゴーギクホールド設定
	pea	next_cmd_md(pc)
	bra	1f

agogik_sync_fm:			*FM アゴーギクホールド設定
	pea	next_cmd_fm(pc)
1:
	bset.b	#b_agogik_trmk,p_agogik_flg(a5)
	andi.b	#%0000_0011,p_agogik_flg(a5)	*b_agogik_sync,p_agogik_tiesync
						*p_agogik_rstsync,b_agogik_wvsq
						*b_agogik_wvsqrst,b_agogik_msrsync
	move.b	(a0)+,d0			*b_agogik_wvsq,b_agogik_wvsqrst
	or.b	d0,p_agogik_flg(a5)
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0
	tst.w	d0
	beq	1f
	lea.l	agogik_base(a6),a4
	btst.b	#_ID_SE,p_track_stat(a5)
	beq	@f
	lea.l	agogik_base_se(a6),a4
@@:
	move.w	d0,p_pmod_syncnt(a4)
	move.w	d0,p_pmod_syncnt2(a4)
1:
	rts
*------------------------------------------------------------------------------
agogik_delay8_md:			*アゴーギク・ディレイ・設定1/8,8point
	bsr	get_ag_dl8
	bra	next_cmd_md

agogik_delay8_ad:			*アゴーギク・ディレイ・設定1/8,8point
	bsr	get_ag_dl8
	bra	next_cmd_ad

agogik_delay8_fm:			*アゴーギク・ディレイ・設定1/8,8point
	pea	next_cmd_fm(pc)

get_ag_dl8:
	bset.b	#b_agogik_trmk,p_agogik_flg(a5)
	move.l	a5,a4
	lea.l	agogik_base(a6),a5
	btst.b	#_ID_SE,p_track_stat(a4)
	beq	@f
	lea.l	agogik_base_se(a6),a5
@@:
	bsr	get_dp8
	move.l	a4,a5
	rts
*------------------------------------------------------------------------------
agogik_wf_md:				*MIDI AGOGIK波形タイプセレクト
	bsr	get_ag_wf
	bra	next_cmd_md

agogik_wf_ad:				*ADPCM AGOGIK波形タイプセレクト
	bsr	get_ag_wf
	bra	next_cmd_ad

agogik_wf_fm:				*FM AGOGIK波形タイプセレクト
	pea	next_cmd_fm(pc)

get_ag_wf:
	bset.b	#b_agogik_trmk,p_agogik_flg(a5)
	move.l	a5,a4
	lea.l	agogik_base(a6),a5
	btst.b	#_ID_SE,p_track_stat(a4)
	beq	@f
	lea.l	agogik_base_se(a6),a5
@@:
	move.b	(a0)+,p_pmod_wf+0(a5)
	move.b	(a0)+,p_pmod_wf+1(a5)
	tst.b	p_pmod_sw(a5)
	beq	@f
	bsr	calc_pmod
@@:
	move.l	a4,a5
	rts
*------------------------------------------------------------------------------
agogik_deepen_ad:				*ADPCM AGOGIK振幅増減
	pea	next_cmd_ad(pc)
	bra	@f

agogik_deepen_md:				*MIDI AGOGIK振幅増減
	pea	next_cmd_md(pc)
	bra	@f

agogik_deepen_fm:				*FM AGOGIK振幅増減
	pea	next_cmd_fm(pc)

@@:
	bset.b	#b_agogik_trmk,p_agogik_flg(a5)
	move.l	a5,a4
	lea.l	agogik_base(a6),a5
	btst.b	#_ID_SE,p_track_stat(a4)
	beq	@f
	lea.l	agogik_base_se(a6),a5
@@:
	bsr	get_pmod_deepen
	move.l	a4,a5
	rts
*------------------------------------------------------------------------------
agogik_sw_md:				*MIDI AGOGIKスイッチ
	bsr	get_ag_sw
	bra	next_cmd_md

agogik_sw_ad:				*ADPCM AGOGIKスイッチ
	bsr	get_ag_sw
	bra	next_cmd_ad

agogik_sw_fm:				*FM AGOGIKスイッチ
	pea	next_cmd_fm(pc)

get_ag_sw:
	bset.b	#b_agogik_trmk,p_agogik_flg(a5)
	move.l	a5,a4
	lea.l	agogik_base(a6),a5
	btst.b	#_ID_SE,p_track_stat(a4)
	beq	@f
	lea.l	agogik_base_se(a6),a5
@@:
	bsr	do_pmod_sw
	move.l	a4,a5
	rts
*------------------------------------------------------------------------------
agogik_speed8_md:				*アゴーギク・スピード設定1/8,8point
	bsr	get_ag_sp8
	bra	next_cmd_md

agogik_speed8_ad:				*アゴーギク・スピード設定1/8,8point
	bsr	get_ag_sp8
	bra	next_cmd_ad

agogik_speed8_fm:				*アゴー・ギクスピード設定1/8,8point
	pea	next_cmd_fm(pc)

get_ag_sp8:
	bset.b	#b_agogik_trmk,p_agogik_flg(a5)
	move.l	a5,a4
	lea.l	agogik_base(a6),a5
	btst.b	#_ID_SE,p_track_stat(a4)
	beq	@f
	lea.l	agogik_base_se(a6),a5
@@:
	bsr	get_sp8
	tst.b	p_pmod_sw(a5)
	beq	@f
	bsr	calc_pmod
@@:
	move.l	a4,a5
	rts
*------------------------------------------------------------------------------
agogik8_md:				*8point アゴーギク
	pea	next_cmd_md(pc)
	bra	get_optag8

agogik8_ad:				*8point アゴーギク
	pea	next_cmd_ad(pc)
	bra	get_optag8

agogik8_fm:				*8point アゴーギク
	pea	next_cmd_fm(pc)

get_optag8:
	bset.b	#b_agogik_trmk,p_agogik_flg(a5)
	move.l	a5,a4
	lea.l	agogik_base(a6),a5
	btst.b	#_ID_SE,p_track_stat(a4)
	beq	@f
	lea.l	agogik_base_se(a6),a5
@@:
	move.b	(a0)+,d1		*get sw(0,1,-1)
	beq	ntchagk			*no touch when 0
	cmpi.b	#previous_on,d1
	bne	@f
	tst.b	p_pmod_sw(a5)
	bne	ntchagk
	move.b	p_pmod_sw2(a5),d1
	bne	@f
	moveq.l	#1,d1			*保存スイッチが0ならば1にしておく
@@:
	move.b	d1,p_pmod_sw(a5)
	move.b	d1,p_pmod_sw2(a5)
ntchagk:
	move.b	(a0)+,d0
	beq	agogik_sw0
	move.b	d0,p_pmod_omt(a5)
	bsr	get_pmod8
	bsr	calc_pmod
	move.l	a4,a5
	rts

agogik_sw0:
	moveq.l	#0,d0
	move.b	d0,p_pmod_sw(a5)		*OFF
	move.l	d0,p_pmod_pitch(a5)		*make it neutral
	move.w	d0,p_pmod_dpt_now(a5)		*96/9/16
	bclr.b	#b_pmod_first,p_pmod_flg(a5)	*97/2/5
	move.l	a4,a5
	rts
*------------------------------------------------------------------------------
pmod_speed8_fm:				*モジュレーションスピード設定1/8,8point
	bsr	get_sp8
	tst.b	p_pmod_sw(a5)
	beq	next_cmd_fm
	bsr	calc_pmod
	bra	next_cmd_fm

pmod_speed8_ad:				*モジュレーションスピード設定1/8,8point
	bsr	get_sp8
	tst.b	p_pmod_sw(a5)
	beq	next_cmd_ad
	bsr	calc_pmod
	bra	next_cmd_ad

pmod_speed8_md:				*モジュレーションスピード設定1/8,8point
	bsr	get_sp8
	tst.b	p_pmod_sw(a5)
	beq	next_cmd_md
*!2/5	bclr.b	#b_pmod_first,p_pmod_flg(a5)
	tst.b	p_pmod_mode(a5)		*normal mode時は不要
	bmi	next_cmd_md
	bsr	calc_pmod
	bra	next_cmd_md

get_sp8:				*PMODスピード取りだし
	* X d0-d1
	move.b	(a0)+,d0	*omt
	moveq.l	#0,d1
ps8lp00:
	lsr.b	d0
	bcc	@f
	move.b	(a0)+,p_pmod_spd_tbl+0(a5,d1.w)
	move.b	(a0)+,p_pmod_spd_tbl+1(a5,d1.w)
@@:
	addq.w	#2,d1
	tst.b	d0
	bne	ps8lp00
	rts
*------------------------------------------------------------------------------
vseq_wf_fm:				*FM VSEQ波形タイプセレクト
	pea	next_cmd_fm(pc)
	bra	@f

vseq_wf_ad:				*ADPCM VSEQ波形タイプセレクト
	pea	next_cmd_ad(pc)
	bra	@f

vseq_wf_md:				*MIDI VSEQ波形タイプセレクト
	pea	next_cmd_md(pc)
@@:
	lea	p_vseq_param(a5),a4
	move.b	(a0)+,d0
	beq	exit_vseqwf
	lsr.b	#1,d0
	bcc	@f
	move.b	(a0)+,p_arcc_wf+0(a4)
	move.b	(a0)+,p_arcc_wf+1(a4)
@@:
	lsr.b	#1,d0
	bcc	@f
	move.b	(a0)+,p_arcc_origin(a4)
@@:
	lsr.b	#1,d0
	bcc	1f
	tst.b	(a0)+
	beq	@f
	bset.b	#b_arcc_phase,p_arcc_flg2(a4)
	bra	1f
@@:
	bclr.b	#b_arcc_phase,p_arcc_flg2(a4)
1:
	tst.b	p_arcc_sw(a4)
	bne	calc_arcc
exit_vseqwf:
	rts
*------------------------------------------------------------------------------
vseq_speed8_fm:				*FM VSEQスピード設定1/8,8point
	pea	next_cmd_fm(pc)
	bra	@f

vseq_speed8_ad:				*ADPCM VSEQスピード設定1/8,8point
	pea	next_cmd_ad(pc)
	bra	@f

vseq_speed8_md:				*MIDI VSEQスピード設定1/8,8point
	pea	next_cmd_md(pc)
@@:
	lea	p_vseq_param(a5),a4
	bsr	get_sa8
	tst.b	p_arcc_sw(a4)
	bne	calc_arcc
	rts
*------------------------------------------------------------------------------
vseq_delay8_fm:				*FM VSEQディレイ設定1/8,8point
	lea	p_vseq_param(a5),a4
	bsr	get_da8
	bra	next_cmd_fm

vseq_delay8_ad:				*ADPCM VSEQディレイ設定1/8,8point
	lea	p_vseq_param(a5),a4
	bsr	get_da8
	bra	next_cmd_ad

vseq_delay8_md:				*MIDI VSEQディレイ設定1/8,8point
	lea	p_vseq_param(a5),a4
	bsr	get_da8
	bra	next_cmd_md
*------------------------------------------------------------------------------
vseq8_fm:				*FM 8point VSEQ
	pea	next_cmd_fm(pc)
	bra	@f

vseq8_ad:				*ADPCM 8point VSEQ
	pea	next_cmd_ad(pc)
	bra	@f

vseq8_md:				*MIDI 8point VSEQ
	pea	next_cmd_md(pc)
@@:
	lea	p_vseq_param(a5),a4
	move.b	(a0)+,d1		*switch value
	beq	1f			*no touch when 0
	cmpi.b	#previous_on,d1
	bne	@f
	tst.b	p_arcc_sw(a4)
	bne	1f
	move.b	p_arcc_sw2(a4),d1
	bne	@f
	moveq.l	#1,d1			*保存スイッチが0ならば1にしておく
@@:
	move.b	d1,p_arcc_sw(a4)
	move.b	d1,p_arcc_sw2(a4)
1:
	move.b	(a0)+,d0		*omt
	beq	vseqsw0
	move.b	d0,p_arcc_omt(a4)
	bsr	get_vseq8
	bra	calc_arcc

vseqsw0:
	* < d0.b=0
	move.b	d0,p_arcc_sw(a4)		*OFF
	move.b	d0,p_arcc_dpt_now(a4)		*96/9/16
	bset.b	#b_arcc_reset,p_arcc_flg(a4)
	bclr.b	#b_arcc_first,p_arcc_flg(a4)	*97/2/5
	rts
*------------------------------------------------------------------------------
arcc_speed8_fm:				*ARCCスピード設定1/8,8point
	bsr	get_arcc_a4
	bsr	get_sa8
	tst.b	p_arcc_sw(a4)
	beq	next_cmd_fm
	bsr	calc_arcc
	bra	next_cmd_fm

arcc_speed8_ad:				*ARCCスピード設定1/8,8point
	bsr	get_arcc_a4
	bsr	get_sa8
	tst.b	p_arcc_sw(a4)
	beq	next_cmd_ad
	bsr	calc_arcc
	bra	next_cmd_ad

arcc_speed8_md:				*ARCCスピード設定1/8,8point
	bsr	get_arcc_a4
	bsr	get_sa8
	tst.b	p_arcc_sw(a4)
	beq	next_cmd_md
*!2/5	bclr.b	#b_arcc_first,p_arcc_flg(a4)
	tst.b	p_arcc_mode(a4)		*normal mode時は不要
	bmi	next_cmd_md
	bsr	calc_arcc
	bra	next_cmd_md

get_sa8:				*ARCCスピード取りだし
	* X d0-d1
	move.b	(a0)+,d0		*omt
	moveq.l	#0,d1
as8lp00:
	lsr.b	d0
	bcc	@f
	move.b	(a0)+,p_arcc_spd_tbl+0(a4,d1.w)
	move.b	(a0)+,p_arcc_spd_tbl+1(a4,d1.w)
@@:
	addq.w	#2,d1
	tst.b	d0
	bne	as8lp00
	rts
*------------------------------------------------------------------------------
pmod_delay8_fm:				*モジュレーション・ディレイ・設定1/8,8point
	bsr	get_dp8
	bra	next_cmd_fm

pmod_delay8_ad:				*モジュレーション・ディレイ・設定1/8,8point
	bsr	get_dp8
	bra	next_cmd_ad

pmod_delay8_md:				*モジュレーション・ディレイ・設定1/8,8point
	bsr	get_dp8
	bra	next_cmd_md

get_dp8:				*PMODディレイ取りだし
	* X d0-d1/a1
	move.b	(a0)+,d0		*omt(case0:パラメータは9つある)
	lsl.w	#8,d0
	move.b	(a0)+,d0
	moveq.l	#0,d1
dp8lp00:
	lsr.w	d0
	bcc	@f
	move.b	(a0)+,p_pmod_1st_dly+0(a5,d1.w)
	move.b	(a0)+,p_pmod_1st_dly+1(a5,d1.w)
@@:
	addq.w	#2,d1
	tst.w	d0
	bne	dp8lp00
	rts
*------------------------------------------------------------------------------
arcc_delay8_fm:				*ARCCディレイ設定1/8,8point
	bsr	get_arcc_a4
	bsr	get_da8
	bra	next_cmd_fm

arcc_delay8_ad:				*ARCCディレイ設定1/8,8point
	bsr	get_arcc_a4
	bsr	get_da8
	bra	next_cmd_ad

arcc_delay8_md:				*ARCCディレイ設定1/8,8point
	bsr	get_arcc_a4
	pea	next_cmd_md(pc)

get_da8:				*ARCCディレイ取りだし
	* X d0-d1/a1
	move.b	(a0)+,d0		*omt(case0:パラメータは9つある)
	lsl.w	#8,d0
	move.b	(a0)+,d0
	moveq.l	#0,d1
da8lp00:
	lsr.w	d0
	bcc	@f
	move.b	(a0)+,p_arcc_1st_dly+0(a4,d1.w)
	move.b	(a0)+,p_arcc_1st_dly+1(a4,d1.w)
@@:
	addq.w	#2,d1
	tst.w	d0
	bne	da8lp00
	rts
*------------------------------------------------------------------------------
pmod_wf_fm:				*FM PMOD波形タイプセレクト
	move.b	(a0)+,p_pmod_wf+0(a5)
	move.b	(a0)+,p_pmod_wf+1(a5)
	tst.b	p_pmod_sw(a5)
	beq	next_cmd_fm
	bsr	calc_pmod
	bra	next_cmd_fm

pmod_wf_ad:				*ADPCM PMOD波形タイプセレクト
	move.b	(a0)+,p_pmod_wf+0(a5)
	move.b	(a0)+,p_pmod_wf+1(a5)
	tst.b	p_pmod_sw(a5)
	beq	next_cmd_ad
	bsr	calc_pmod
	bra	next_cmd_ad

pmod_wf_md:				*MIDI PMOD波形タイプセレクト
	move.b	(a0)+,p_pmod_wf+0(a5)
	move.b	(a0)+,p_pmod_wf+1(a5)
	tst.b	p_pmod_mode(a5)		*通常モード(minus)ならば
	bpl	@f
	move.b	#1,p_pmod_mode(a5)	*強制的に拡張PMODに設定
*!2/5	bclr.b	#b_pmod_first,p_pmod_flg(a5)
*!1/30	bra	next_cmd_md
@@:
	tst.b	p_pmod_sw(a5)
	beq	next_cmd_md
	bsr	calc_pmod
	bra	next_cmd_md
*------------------------------------------------------------------------------
arcc_wf_fm:				*FM AMOD波形タイプセレクト
	bsr	get_arcc_a4
	move.b	(a0)+,p_arcc_wf+0(a4)
	move.b	(a0)+,p_arcc_wf+1(a4)
	tst.b	p_arcc_sw(a4)
	beq	next_cmd_fm
	bsr	calc_arcc
	bra	next_cmd_fm

arcc_wf_ad:				*ADPCM AMOD波形タイプセレクト
	bsr	get_arcc_a4
	move.b	(a0)+,p_arcc_wf+0(a4)
	move.b	(a0)+,p_arcc_wf+1(a4)
	tst.b	p_arcc_sw(a4)
	beq	next_cmd_ad
	bsr	calc_arcc
	bra	next_cmd_ad

arcc_wf_md:				*MIDI AMOD波形タイプセレクト
	bsr	get_arcc_a4
	move.b	(a0)+,p_arcc_wf+0(a4)
	move.b	(a0)+,p_arcc_wf+1(a4)
	tst.b	p_arcc_mode(a4)		*通常モード(-1)ならば
	bpl	@f
	move.b	#1,p_arcc_mode(a4)	*強制的に拡張ARCCに設定
*!2/5	bclr.b	#b_arcc_first,p_arcc_flg(a4)
@@:
	tst.b	p_arcc_sw(a4)
	beq	next_cmd_md
	bsr	calc_arcc
	bra	next_cmd_md
*------------------------------------------------------------------------------
pmod_deepen_ad:					*ADPCM PMOD振幅増減
	pea	next_cmd_ad(pc)
	bra	get_pmod_deepen

pmod_deepen_md:					*MIDI PMOD振幅増減
	pea	next_cmd_md(pc)
	bra	get_pmod_deepen

pmod_deepen_fm:					*FM PMOD振幅増減
	pea	next_cmd_fm(pc)

get_pmod_deepen:
	bclr.b	#b_pmod_dpn,p_pmod_flg(a5)	*まずOFF
	move.b	(a0)+,d1			*get omt
	bpl	@f
	bset.b	#b_pmod_dpn,p_pmod_flg(a5)	*minusならばON
@@:
	add.b	d1,d1
	bpl	1f
	moveq.l	#0,d0
	move.b	(a0)+,d0			*get speed
	bpl	@f
	add.b	d0,d0
	lsl.w	#7,d0
	move.b	(a0)+,d0
@@:
	move.w	d0,p_pmod_dpnspd(a5)
1:
	add.b	d1,d1
	bpl	@f
	move.b	(a0)+,p_pmod_dpndpt+0(a5)	*get depth
	move.b	(a0)+,p_pmod_dpndpt+1(a5)
@@:
	add.b	d1,d1
	bpl	1f
	moveq.l	#0,d0
	move.b	(a0)+,d0			*get repeat time
	bpl	@f
	add.b	d0,d0
	lsl.w	#7,d0
	move.b	(a0)+,d0
@@:
	move.w	d0,p_pmod_dpnrpt(a5)
1:
	rts
*------------------------------------------------------------------------------
pmod_sw0:
	moveq.l	#0,d0
	move.b	d0,p_pmod_sw(a5)		*OFF
	move.l	d0,p_pmod_pitch(a5)		*make it neutral
	move.w	d0,p_pmod_dpt_now(a5)		*96/9/16
	bclr.b	#b_pmod_first,p_pmod_flg(a5)	*97/2/5
	rts

pmod_sw0_md:
	moveq.l	#0,d0
	move.b	d0,p_pmod_sw(a5)		*OFF
	move.l	d0,p_pmod_pitch(a5)		*make it neutral
	move.w	d0,p_pmod_dpt_now(a5)		*96/9/16
	bclr.b	#b_pmod_first,p_pmod_flg(a5)	*97/2/5
	bclr.b	#b_pmod_reset,p_md_flg(a5)
	beq	@f
	move.l	p_midi_trans(a5),a2
	moveq.l	#$b0,d0
	or.b	d4,d0
	jsr	(a2)
	moveq.l	#$01,d0			*vibrato
	jsr	(a2)
	moveq.l	#$00,d0
	jmp	(a2)
@@:
	rts

get_pmod8:				*PMODの振幅取りだし
	lea	p_pmod_dpt_tbl(a5),a1
m8flp0:
	lsr.b	#1,d0
	bcc	m8omtd
	move.b	(a0)+,(a1)+
	move.b	(a0)+,(a1)+
	tst.b	d0
	bne	m8flp0
	rts
m8omtd:
	addq.w	#2,a1
	tst.b	d0
	bne	m8flp0
	rts

pmod8_md:				*1/8 ピッチモジュレーション
	pea	next_cmd_md(pc)
	move.b	(a0)+,d1		*get sw(0,1,-1,2)
	beq	ntchp8md		*no touch when 0
	cmpi.b	#previous_on,d1
	bne	@f
	tst.b	p_pmod_sw(a5)
	bne	ntchp8md
	move.b	p_pmod_sw2(a5),d1
	bne	@f
	moveq.l	#1,d1			*保存スイッチが0ならば1にしておく
@@:
	move.b	d1,p_pmod_sw(a5)
	move.b	d1,p_pmod_sw2(a5)
ntchp8md:
	move.b	(a0)+,d0
	beq	pmod_sw0_md
	move.b	d0,p_pmod_omt(a5)
	bsr	get_pmod8
*!2/5	bclr.b	#b_pmod_first,p_pmod_flg(a5)
	tst.b	p_pmod_mode(a5)
	bpl	calc_pmod
					*	tie中に設定変更されたことも想定して
					***!2/5	念のためにパラメータを設定する
	moveq.l	#0,d0
	move.b	p_pmod_n(a5),d0
	cmpi.b	#7,d0
	bhi	2f
	btst.b	d0,p_pmod_omt(a5)	*省略の場合は前回のものを継続
	beq	2f
	add.w	d0,d0
	move.w	p_pmod_dpt_tbl(a5,d0.w),d0	*次の振幅パラメータ
	beq	1f
	bpl	@f
	neg.w	d0
@@:					*振幅値縮小処理
	cmpi.w	#127,d0			*(振幅パラメータを尊重するため出力時に行う)
	bls	1f
	moveq.l	#127,d0
1:
	move.w	d0,p_pmod_dpt_now(a5)
	move.w	d0,p_pmod_pitch(a5)	*わざと.w
	or.w	#$8000,p_level_param(a5)
2:
	rts				***!2/5

pmod8_ad:				*1/8 ピッチモジュレーション
	pea	next_cmd_ad(pc)
	move.b	(a0)+,d1		*get sw(0,1,-1,2)
	beq	ntchp8ad		*no touch when 0
	cmpi.b	#previous_on,d1
	bne	@f
	tst.b	p_pmod_sw(a5)
	bne	ntchp8ad
	move.b	p_pmod_sw2(a5),d1
	bne	@f
	moveq.l	#1,d1			*保存スイッチが0ならば1にしておく
@@:
	move.b	d1,p_pmod_sw(a5)
	move.b	d1,p_pmod_sw2(a5)
ntchp8ad:
	move.b	(a0)+,d0
	beq	pmod_sw0
	move.b	d0,p_pmod_omt(a5)
	bsr	get_pmod8
	bra	calc_pmod

pmod8_fm:				*1/8 ピッチモジュレーション
	pea	next_cmd_fm(pc)
	move.b	(a0)+,d1		*get sw(0,1,-1)
	beq	ntchp8fm		*no touch when 0
	cmpi.b	#previous_on,d1
	bne	@f
	tst.b	p_pmod_sw(a5)
	bne	ntchp8fm
	move.b	p_pmod_sw2(a5),d1
	bne	@f
	moveq.l	#1,d1			*保存スイッチが0ならば1にしておく
@@:
	move.b	d1,p_pmod_sw(a5)
	move.b	d1,p_pmod_sw2(a5)
ntchp8fm:
	move.b	(a0)+,d0
	beq	pmod_sw0
	move.b	d0,p_pmod_omt(a5)
	bsr	get_pmod8

calc_pmod:				*PMODのパラメータ計算
	move.l	d4,-(sp)
*!2/5	bclr.b	#b_pmod_first,p_pmod_flg(a5)
	move.b	p_pmod_omt(a5),d3
	moveq.l	#0,d5			*2++
	move.w	p_pmod_wf(a5),d0
	bmi	@f			*波形メモリケース
	move.b	cpmdjt(pc,d0.w),d0
	jmp	cpmdjt(pc,d0.w)
cpmdjt:
	dc.b	do_cpmd-cpmdjt		*wf0:saw
	dc.b	stp_eq_dpt-cpmdjt	*wf1:squ
	dc.b	cpmd_wf2-cpmdjt		*wf2:tri
	dc.b	do_cpmd-cpmdjt		*wf3:saw2
	dc.b	stp_eq_dpt-cpmdjt	*wf4:nos
	.even
@@:					*波形メモリケース
	andi.l	#$7fff,d0
	move.l	d0,d1
	lsl.l	#wv_tbl_size_,d0
	move.l	wave_tbl-work(a6),a1
	adda.l	d0,a1
	lea	p_wvpm_start(a5),a2
	cmp.w	wave_n_max-work(a6),d1
	bcs	@f
	bsr	set_dummy_wave		*dummy波形をセット
	bra	stp_eq_dpt
@@:
	move.l	(a1)+,d0
	move.l	d0,(a2)+		*start
	addq.w	#4,a2
*	move.l	d0,(a2)+		*point
	move.l	(a1)+,(a2)+		*end
	move.w	(a1)+,(a2)+		*loop mode
	move.l	(a1)+,(a2)+		*loop start
	move.l	(a1)+,(a2)+		*loop end
	move.l	(a1)+,d0
	move.l	d0,(a2)+		*loop time
	move.l	d0,(a2)+		*loop time2
stp_eq_dpt:				*加算ワーク=振幅値のケース(sq,noise,wvmm)
sedlp0:
	lsr.b	#1,d3
	bcc	@f
	move.w	d5,d0
	add.w	d0,d0
	move.w	p_pmod_dpt_tbl(a5,d5.w),p_pmod_stp_tbl(a5,d0.w)
@@:
	addq.w	#2,d5
	tst.b	d3
	bne	sedlp0
	bra	cpmd_00

cpmd_wf2:				*case:三角波
	moveq.l	#1,d7			*d7=シフトパラメータ (÷2)
	bra	@f
do_cpmd:				*case:ノコギリ波
	moveq.l	#0,d7			*d7=シフトパラメータ (÷1)
@@:
	moveq.l	#0,d6			*4++
cpmd_lp0:
	lsr.b	#1,d3
	bcc	next_cpmd
	move.w	p_pmod_spd_tbl(a5,d5.w),d1
	bne	@f
	move.l	d4,d1
@@:
	move.l	d1,d4
	tst.l	d7			*!nokoのときの特別演算
	bne	@f			*!
	subq.w	#1,d1			*!
@@:
	lsr.w	d7,d1
	bne	@f
	moveq.l	#1,d1
@@:
	moveq.l	#0,d2
	move.w	p_pmod_dpt_tbl(a5,d5.w),d2
	bmi	@f
	divu	d1,d2		*d2=range/L d2.w=step counter
	move.w	d2,d0
	clr.w	d2
	divu	d1,d2		*d2=d2/L
	swap	d0
	move.w	d2,d0
	addq.l	#1,d0
	move.l	d0,p_pmod_stp_tbl(a5,d6.w)
	bra	next_cpmd
@@:
	neg.w	d2
	divu	d1,d2		*d2=range/L d2.w=step counter
	move.w	d2,d0
	clr.w	d2
	divu	d1,d2		*d2=d2/L
	swap	d0
	move.w	d2,d0
	neg.l	d0
	move.l	d0,p_pmod_stp_tbl(a5,d6.w)
next_cpmd:
	addq.w	#2,d5
	addq.w	#4,d6
	tst.b	d3
	bne	cpmd_lp0
					*tie中に設定変更されたことも想定して
cpmd_00:				*念のためにパラメータを設定する
	move.b	#1,p_pmod_chain(a5)	*接続待ちへ
	moveq.l	#0,d0
	move.b	p_pmod_n(a5),d0
	cmpi.b	#7,d0
	bhi	exit_cpmd
	btst.b	d0,p_pmod_omt(a5)	*省略の場合は前回のものを継続
	beq	exit_cpmd
	add.w	d0,d0
	move.w	p_pmod_dpt_tbl(a5,d0.w),p_pmod_dpt_now(a5)
	move.w	p_pmod_spd_tbl(a5,d0.w),d1
	beq	@f
	move.w	d1,p_pmod_spd_next(a5)	*次の波形生成パラメータ
@@:
	add.w	d0,d0
	move.l	p_pmod_stp_tbl(a5,d0.w),p_pmod_step_next(a5)	*次の波形生成パラメータ
exit_cpmd:
	move.l	(sp)+,d4		*破壊したので復元
	rts
*------------------------------------------------------------------------------
asgn_arcc_fm:			*ARCC セット
	bsr	get_arcc_a4
	bsr	get_@c
	bra	next_cmd_fm

asgn_arcc_ad:			*ARCC セット
	bsr	get_arcc_a4
	bsr	get_@c
	bra	next_cmd_ad

asgn_arcc_md:			*ARCC セット
	bsr	get_arcc_a4
	pea	next_cmd_md(pc)

get_@c:
	move.b	(a0)+,d1		*get omt
	beq	exit_get_@c
	add.b	d1,d1
	bcc	@f
	move.b	(a0)+,p_arcc(a4)	*ctrl
@@:
	add.b	d1,d1
	bcc	@f
	move.b	(a0)+,p_arcc_reset(a4)	*reset value
@@:
	add.b	d1,d1
	bcc	@f
	move.b	(a0)+,p_arcc_origin(a4)	*starting point
@@:
	add.b	d1,d1
	bcc	1f
	tst.b	(a0)+
	beq	@f
	bset.b	#b_arcc_phase,p_arcc_flg2(a4)
	bra	1f
@@:
	bclr.b	#b_arcc_phase,p_arcc_flg2(a4)
1:
exit_get_@c:
	st.b	p_arcc_last(a4)		*初期化
	rts
*------------------------------------------------------------------------------
arcc_deepen_ad:					*ADPCM ARCC振幅増減
	bsr	get_arcc_a4
	pea	next_cmd_ad(pc)
	bra	get_arcc_deepen

arcc_deepen_md:					*MIDI ARCC振幅増減
	bsr	get_arcc_a4
	pea	next_cmd_md(pc)
	bra	get_arcc_deepen

arcc_deepen_fm:					*FM ARCC振幅増減
	bsr	get_arcc_a4
	pea	next_cmd_fm(pc)

get_arcc_deepen:
	bclr.b	#b_arcc_dpn,p_arcc_flg(a4)	*まずOFF
	move.b	(a0)+,d1			*get omt
	bpl	@f
	bset.b	#b_arcc_dpn,p_arcc_flg(a4)	*minusならばON
@@:
	add.b	d1,d1
	bpl	1f
	moveq.l	#0,d0
	move.b	(a0)+,d0			*get speed
	bpl	@f
	add.b	d0,d0
	lsl.w	#7,d0
	move.b	(a0)+,d0
@@:
	move.w	d0,p_arcc_dpnspd(a4)
1:
	add.b	d1,d1
	bpl	@f
	move.b	(a0)+,p_arcc_dpndpt(a4)		*get depth
@@:
	add.b	d1,d1
	bpl	1f
	moveq.l	#0,d0
	move.b	(a0)+,d0			*get repeat time
	bpl	@f
	add.b	d0,d0
	lsl.w	#7,d0
	move.b	(a0)+,d0
@@:
	move.w	d0,p_arcc_dpnrpt(a4)
1:
	rts
*------------------------------------------------------------------------------
get_arcc_a4:				*ARCCパラメータのベースアドレスを得る
	* > a4.l=ARCC parameter base address
	* > d0.w=ARCC number*2
	* x d0
	moveq.l	#0,d0
	move.b	(a0)+,d0		*ARCC number(0～3)*2
	lea	p_arcc_param(a5),a4
	add.w	saf0tbl(pc,d0.w),a4
	rts
saf0tbl:
	dc.w	__arcc_len*0
	dc.w	__arcc_len*1
	dc.w	__arcc_len*2
	dc.w	__arcc_len*3

get_arcc8:				*ARCCの振幅取りだし
get_vseq8:				*VSEQ8のエントリ
	lea	p_arcc_dpt_tbl(a4),a1
a8flp0:
	lsr.b	#1,d0
	bcc	@f
	move.b	(a0)+,(a1)
@@:
	addq.w	#1,a1
	tst.b	d0
	bne	a8flp0
	rts

arcc_sw0_md:
	* < d0.b=0
	move.b	d0,p_arcc_sw(a4)			*OFF
	move.b	d0,p_arcc_dpt_now(a4)			*96/9/16
	bset.b	#b_arcc_reset,p_arcc_flg(a4)
	bclr.b	#b_arcc_first,p_arcc_flg(a4)		*97/2/5
	or.w	d6,p_level_param(a5)			*mark
	cmpi.b	#MIDI_VOL,p_arcc(a4)			*競合チェック
	bne	@f
	bclr.b	#pts_volume,p_timbre_set(a5)
	rts
@@:
	cmpi.b	#MIDI_PAN,p_arcc(a4)			*競合チェック
	bne	@f
	bclr.b	#pts_panpot,p_timbre_set(a5)
	rts
@@:
	cmpi.b	#MIDI_DMP,p_arcc(a4)			*競合チェック
	bne	@f
	bclr.b	#pts_damper,p_timbre_set(a5)
@@:
	rts

arcc_sw0:
	* < d0.b=0
	move.b	d0,p_arcc_sw(a4)			*OFF
	move.b	d0,p_arcc_dpt_now(a4)			*96/9/16
	clr.w	p_arcc_level(a4)			*96/10/26
	bset.b	#b_arcc_reset,p_arcc_flg(a4)
	bclr.b	#b_arcc_first,p_arcc_flg(a4)		*97/2/5
	or.w	d6,p_level_param(a5)			*mark
	rts

arcc8_md:				*1/8 ARCC
	bsr	get_arcc_a4
	move.w	arcc8_marker(pc,d0.w),d6
	pea	next_cmd_md(pc)
	move.b	(a0)+,d1		*switch value
	beq	ntcha8md		*no touch when 0
	cmpi.b	#previous_on,d1
	bne	@f
	tst.b	p_arcc_sw(a4)
	bne	ntcha8md
	move.b	p_arcc_sw2(a4),d1
	bne	@f
	moveq.l	#1,d1			*保存スイッチが0ならば1にしておく
@@:
	move.b	d1,p_arcc_sw(a4)
	move.b	d1,p_arcc_sw2(a4)
ntcha8md:
	move.b	(a0)+,d0		*omt
	beq	arcc_sw0_md
	move.b	d0,p_arcc_omt(a4)
	bsr	get_arcc8
*!2/5	bclr.b	#b_arcc_first,p_arcc_flg(a4)
	tst.b	p_arcc_mode(a4)
	bpl	calc_arcc
					*	tie中に設定変更されたことも想定して
					***!2/5	念のためにパラメータを設定する
	moveq.l	#0,d0
	move.b	p_arcc_n(a4),d0
	cmpi.b	#7,d0
	bhi	2f
	btst.b	d0,p_arcc_omt(a4)	*省略の場合は前回のものを継続
	beq	2f
	move.b	p_arcc_dpt_tbl(a4,d0.w),d1
	ext.w	d1
	bpl	1f
	neg.w	d1
	cmpi.w	#127,d1
	bls	1f
	moveq.l	#127,d1
1:
	move.b	d1,p_arcc_dpt_now(a4)
	move.b	d1,p_arcc_level(a4)	*次の振幅パラメータ
	or.w	d6,p_level_param(a5)	*mark
2:					***!2/5
	rts

arcc8_marker:
	dc.w	$80,$40,$20,$10

arcc8_ad:				*1/8 ARCC
	bsr	get_arcc_a4
	move.w	arcc8_marker(pc,d0.w),d6
	pea	next_cmd_ad(pc)
	move.b	(a0)+,d1		*switch value
	beq	ntcja8ad		*no touch when 0
	cmpi.b	#previous_on,d1
	bne	@f
	tst.b	p_arcc_sw(a4)
	bne	ntcja8ad
	move.b	p_arcc_sw2(a4),d1
	bne	@f
	moveq.l	#1,d1			*保存スイッチが0ならば1にしておく
@@:
	move.b	d1,p_arcc_sw(a4)
	move.b	d1,p_arcc_sw2(a4)
ntcja8ad:
	move.b	(a0)+,d0		*omt
	beq	arcc_sw0
	move.b	d0,p_arcc_omt(a4)
	bsr	get_arcc8
	bra	calc_arcc

arcc8_fm:				*1/8 ARCC
	bsr	get_arcc_a4
	move.w	arcc8_marker(pc,d0.w),d6
	pea	next_cmd_fm(pc)
	move.b	(a0)+,d1		*switch value
	beq	ntcha8fm		*no touch when 0
	cmpi.b	#previous_on,d1
	bne	@f
	tst.b	p_arcc_sw(a4)
	bne	ntcha8fm
	move.b	p_arcc_sw2(a4),d1
	bne	@f
	moveq.l	#1,d1			*保存スイッチが0ならば1にしておく
@@:
	move.b	d1,p_arcc_sw(a4)
	move.b	d1,p_arcc_sw2(a4)
ntcha8fm:
	move.b	(a0)+,d0		*omt
	beq	arcc_sw0
	move.b	d0,p_arcc_omt(a4)
	bsr	get_arcc8

calc_arcc:				*ARCCのパラメータ計算
	* - d4
	move.l	d4,-(sp)		*tie中に設定変更されたことも想定して
*!2/5	bclr.b	#b_arcc_first,p_arcc_flg(a4)
	move.b	p_arcc_omt(a4),d3
	moveq.l	#0,d5			*2++
	move.w	p_arcc_wf(a4),d0
	bmi	@f			*波形メモリケース
	move.b	camdjt(pc,d0.w),d0
	jmp	camdjt(pc,d0.w)
camdjt:
	dc.b	camd_saw-camdjt		*wf0:saw
	dc.b	stp_eq_dpt2-camdjt	*wf1:squ
	dc.b	do_camd-camdjt		*wf2:tri
	dc.b	camd_saw-camdjt		*wf3:saw2
	dc.b	stp_eq_dpt2-camdjt	*wf4:nos
	.even
@@:					*波形メモリケース
	andi.l	#$7fff,d0
	move.l	d0,d1
	lsl.l	#wv_tbl_size_,d0
	move.l	wave_tbl-work(a6),a1
	adda.l	d0,a1
	lea	p_wvam_start(a4),a2
	cmp.w	wave_n_max-work(a6),d1
	bcs	@f
	bsr	set_dummy_wave		*dummy波形をセット
	bra	stp_eq_dpt2
@@:
	move.l	(a1)+,d0
	move.l	d0,(a2)+		*start
	addq.w	#4,a2
*	move.l	d0,(a2)+		*point
	move.l	(a1)+,(a2)+		*end
	move.w	(a1)+,(a2)+		*loop mode
	move.l	(a1)+,(a2)+		*loop start
	move.l	(a1)+,(a2)+		*loop end
	move.l	(a1)+,d0
	move.l	d0,(a2)+		*loop time
	move.l	d0,(a2)+		*loop time2
stp_eq_dpt2:				*加算ワーク=振幅値のケース(sq,noise,wvmm)
sed2lp0:
	lsr.b	#1,d3
	bcc	@f
	move.w	d5,d0
	add.w	d0,d0
	move.b	p_arcc_dpt_tbl(a4,d5.w),p_arcc_stp_tbl(a4,d0.w)
@@:
	addq.w	#1,d5
	tst.b	d3
	bne	sed2lp0
	bra	camd_00

camd_saw:				*case:ノコギリ波
	moveq.l	#1,d7			*d7=シフトパラメータ (×2)
	bra	@f
do_camd:				*case:三角波
	moveq.l	#0,d7			*d7=シフトパラメータ (×1)
@@:
	moveq.l	#0,d6			*1++
camd_lp0:
	lsr.b	#1,d3
	bcc	next_camd
	move.w	p_arcc_spd_tbl(a4,d5.w),d1
	bne	@f
	move.l	d4,d1
@@:
	move.l	d1,d4
	lsl.w	d7,d1
	tst.l	d7			*!nokoのときの特別演算
	beq	@f			*!
	subq.w	#1,d1			*!
@@:
	moveq.l	#0,d2
	move.b	p_arcc_dpt_tbl(a4,d6.w),d2
	bmi	@f
	divu	d1,d2		*d2=range/L d2.w=step counter
	move.w	d2,d0
	clr.w	d2
	divu	d1,d2		*d2=d2/L
	swap	d0
	move.w	d2,d0
	addq.l	#1,d0
	asr.l	#8,d0
	move.w	d0,p_arcc_stp_tbl(a4,d5.w)
	bra	next_camd
@@:
	neg.b	d2
	divu	d1,d2		*d2=range/L d2.w=step counter
	move.w	d2,d0
	clr.w	d2
	divu	d1,d2		*d2=d2/L
	swap	d0
	move.w	d2,d0
	neg.l	d0
	asr.l	#8,d0
	move.w	d0,p_arcc_stp_tbl(a4,d5.w)
next_camd:
	addq.w	#1,d6
	addq.w	#2,d5
	tst.b	d3
	bne	camd_lp0
camd_00:				*念のためにパラメータを設定する
	move.b	#1,p_arcc_chain(a4)	*接続待ちへ
	moveq.l	#0,d0
	move.b	p_arcc_n(a4),d0
	cmpi.b	#7,d0
	bhi	exit_camd
	btst.b	d0,p_arcc_omt(a4)	*省略の場合は前回のものを継続
	beq	exit_camd
	move.b	p_arcc_dpt_tbl(a4,d0.w),d1
	move.b	d1,p_arcc_dpt_now(a4)
	bmi	@f
	moveq.l	#0,d1
@@:
	lsl.w	#8,d1				*256倍する
	move.w	d1,p_arcc_o_next(a4)				*次の波形生成パラメータ
	add.w	d0,d0
	move.w	p_arcc_spd_tbl(a4,d0.w),d1
	beq	@f
	move.w	d1,p_arcc_spd_next(a4)	*次の波形生成パラメータ
@@:
	move.w	p_arcc_stp_tbl(a4,d0.w),p_arcc_step_next(a4)	*次の波形生成パラメータ
exit_camd:
	move.l	(sp)+,d4		*破壊したので復元
	rts

set_dummy_wave:
	* < a2.l=to be initialized
	* x a1
	lea	wv_dmy,a1
	move.l	a1,(a2)+	*start address
	move.l	a1,(a2)+	*point address
	addq.w	#2,a1
	move.l	a1,(a2)+	*end address
	subq.w	#2,a1
	move.w	#$00ff,(a2)+	*loop mode=∞
	move.l	a1,(a2)+	*loop start point
	addq.w	#2,a1
	move.l	a1,(a2)+	*loop end point
	clr.l	(a2)+		*loop time
	rts
*------------------------------------------------------------------------------
master_fader_ad:					*ADPCM フェーダー
	bsr	get_mstr_fader
	bra	next_cmd_ad

master_fader_md:					*MIDI フェーダー
	bsr	get_mstr_fader
	bset.b	#pts_volume,p_timbre_set(a5)	*音量設定フラグオン
	bra	next_cmd_md

master_fader_fm:					*FM フェーダー
	pea	next_cmd_fm(pc)

get_mstr_fader:					*マスターフェーダー設定
	move.b	(a0)+,d2
	lsl.w	#8,d2
	move.b	(a0)+,d2		*get control device ID
	cmpi.w	#-1,d2
	beq	master_fader_all

	bsr	mfd_odr_no		*> d3.w=ID
	bmi	smf_dead		*dead device case
set_mstrfdrprm:
	move.b	(a0)+,d5		*omt
	lea	mstfd_fm_spd2-work(a6),a2
	add.w	d3,a2
	lea	master_fader_tbl-work(a6),a1	*パラメータがだぶらないようにチェック
	ori.b	#ff_master_fader,fader_flag-work(a6)	*faderマーク
@@:
	move.w	(a1)+,d1
	bmi	@f
	cmp.w	d1,d3
	bne	@b
	bra	do_set_mstrfdrprm	*既存のパラメータ書き換えケース
@@:					*新規にオーダーに追加
	tst.b	d5			*omt=0ならなにもしない
	beq	exit_gmf
	st.b	(a1)
	move.w	d3,-(a1)			*IDをテーブルにセット
						*デフォルト値セット
	move.l	#fader_dflt_spd,fd_spd2(a2)	*set fd_spd2,fd_spd
	move.l	#$007f_0000,fd_lvlw(a2)		*fd_lvlw,fd_dest
do_set_mstrfdrprm:
	tst.b	d5			*omt=0ならばフェーダー解除用パラメータを設定する
	beq	off_mstfdr
	lsr.b	#1,d5			*chk omt
	bcc	@f
	moveq.l	#0,d0
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0
	move.l	d0,fd_spd2(a2)		*set fd_spd2,fd_spd
@@:
	lsr.b	#1,d5			*chk omt
	bcc	@f
	move.b	(a0)+,fd_lvlb(a2)	*set source level
@@:
	lsr.b	#1,d5			*chk omt
	bcc	@f
	move.b	(a0)+,fd_dest(a2)	*set destination level
@@:
	add.w	d3,d3				*今回の発音からフェーダー計算させるため
	lea	fo_ch_fm-work(a6,d3.w),a1
	move.l	#$2222_2222,d3
	or.l	d3,(a1)+
	or.l	d3,(a1)+
	or.l	d3,(a1)+
	or.l	d3,(a1)+

	move.b	fd_lvlb(a2),d0		*set source level
	cmp.b	fd_dest(a2),d0
	bhi	gmf00
	beq	@f
	move.b	#$01,fd_mode(a2)	*f.i. mode on
	rts
gmf00:
	st.b	fd_mode(a2)		*f.o. mode on
	rts
@@:
	tst.b	d0
	bpl	@f			*start=128,end=128ならフェーダー終了
	move.b	#MASTER_FADER_RESET,fd_mode(a2)
	rts
@@:
	clr.b	fd_mode(a2)
exit_gmf:
	rts

master_fader_all:			*dev=-1:全デバイスにフェーダーパラメータを設定
	move.l	a0,d6			*save
	moveq.l	#0,d3			*FM
	bsr	set_mstrfdrprm
	move.l	a0,-(sp)
	move.l	d6,a0
	moveq.l	#8,d3			*ADPCM
	bsr	set_mstrfdrprm
	moveq.l	#if_max-1,d2
mstfdal_lp:
	move.l	d6,a0
	bsr	get_midimfid		*>d3.w=mstr fader tbl ID
	bmi	@f
	bsr	set_mstrfdrprm
@@:
	dbra	d2,mstfdal_lp
	move.l	(sp)+,a0
	rts

off_mstfdr:				*omt=0(強制フェーダー解除)
off_chfdr:				*omt=0(強制フェーダー解除)
	move.l	#-1,fd_spd2(a2)		*set fd_spd2,fd_spd
	move.w	#128,fd_lvlw(a2)	*fd_lvlw
	rts

mfd_odr_no:
	* < d2.w=デバイスID
	* > d3.w=マスターフェーダーテーブルID
	* > minus=error
	* x d2,a4
	moveq.l	#0,d3
	tst.w	d2
	beq	exit_mfon
	bmi	@f			*plus:ADPCM | minus:MIDI
	moveq.l	#8,d3
	bra	exit_mfon
@@:
	ext.w	d2
get_midimfid:
	moveq.l	#0,d3
	lea	midi_if_tbl-work(a6),a4	*MIDI dev tbl
	move.b	(a4,d2.w),d3
	bmi	@f			*dead
	addq.w	#4,d3
	lsl.w	#2,d3			*MIDI1,2,3
exit_mfon:
	clr.l	fader_result-work(a6)
	rts
@@:
	move.l	#-1,fader_result-work(a6)	*Nフラグ立てるため
	rts
*------------------------------------------------------------------------------
ch_fader_ad:					*ADPCM フェーダー
	bsr	get_fader
	bra	next_cmd_ad

ch_fader_md:					*MIDI フェーダー
	bsr	get_fader
	bset.b	#pts_volume,p_timbre_set(a5)	*音量設定フラグオン
	bra	next_cmd_md

ch_fader_fm:					*FM フェーダー
	pea	next_cmd_fm(pc)

get_fader:					*フェーダーパラメータ取りだし
	move.b	(a0)+,d0		*type
	lsl.w	#8,d0
	move.b	(a0)+,d0
	cmpi.w	#-1,d0
	beq	chfdr_all_dev
	cmpi.w	#$7fff,d0
	beq	chfdr_track_mode1
	cmpi.w	#$7ffe,d0
	beq	chfdr_track_mode2
	cmpi.w	#$7ffd,d0
	bne	@f
	move.w	p_type(a5),d0		*このトラックのMIDI I/FのチャンネルX
	bpl	1f
	swap	d0			*カレントMIDI
	move.b	(a0)+,d0		*ch
	lsl.w	#8,d0
	move.b	(a0)+,d0
	cmpi.w	#-1,d0
	beq	chfdr_all_ch
	bsr	ch_odr_no_abs			*< d0.l=type,ch
	bpl	chkset_ch_fdr
	bra	chf_dead
1:
	addq.w	#2,a0
	bra	chf_dead
@@:
	swap	d0
	move.b	(a0)+,d0		*ch
	lsl.w	#8,d0
	move.b	(a0)+,d0
	cmpi.w	#-1,d0
	beq	chfdr_all_ch
	bsr	ch_odr_no			*< d0.l=type,ch
	bpl	chkset_ch_fdr
chf_dead:
smf_dead:				*死んでいた場合はスピードなどのパラメータを読み飛ばす
	move.b	(a0)+,d0		*get omt
	beq	exit_smf_dead
	lsr.b	#1,d0			*check omt
	bcc	@f
	addq.w	#2,a0			*speed.w
@@:
	rept	2
	lsr.b	#1,d0			*check omt
	bcc	@f
	addq.w	#1,a0
@@:
	endm
exit_smf_dead:
	rts

chfdr_all_ch:					*全チャンネルのフェーダー設定
	clr.w	d0
	bsr	ch_odr_no			* > d5.w=ch fader tbl (base) id
	bmi	chf_dead
	moveq.l	#16-1,d6
	move.l	a0,d7
@@:
	move.l	d7,a0
	bsr	chkset_ch_fdr
	addq.w	#1,d5
	dbra	d6,@b
exit_cad:
exit_cftr2:
	rts

chfdr_all_dev:					*全デバイスのチャンネルnに対してフェーダー設定
	swap	d0
	move.b	(a0)+,d0			*ch
	lsl.w	#8,d0
	move.b	(a0)+,d0
	move.l	a0,d7
	cmpi.w	#-1,d0
	beq	chfdr_all_dev_all_ch
	move.l	d0,d5				*d5.w=ch
	bsr	chkset_ch_fdr			*FM
	add.w	#16,d5
	move.l	d7,a0
	bsr	chkset_ch_fdr			*ADPCM

	lea	midi_if_tbl-work(a6),a4
	add.w	#16,d5
	move.w	d5,d6
@@:
	moveq.l	#0,d5
	move.b	(a4)+,d5		*d5=0,2,4,6
	bmi	exit_cad
	lsl.w	#3,d5			*16倍
	add.w	d6,d5
	move.l	d7,a0
	bsr	chkset_ch_fdr
	bra	@b

chfdr_all_dev_all_ch:				*全デバイス全チャンネルフェーダー
	moveq.l	#8-1,d6
	moveq.l	#0,d5
@@:						*FMのフェーダー
	move.l	d7,a0
	bsr	chkset_ch_fdr
	addq.w	#1,d5
	dbra	d6,@b

	moveq.l	#16,d5
	moveq.l	#16-1,d6
@@:						*ADPCMのフェーダー
	move.l	d7,a0
	bsr	chkset_ch_fdr
	addq.w	#1,d5
	dbra	d6,@b

	moveq.l	#if_max-1,d2
	lea	midi_if_tbl-work(a6),a4
cadac_lp:
	moveq.l	#0,d5
	move.b	(a4,d2.w),d5
	bmi	next_cadac
	addq.w	#4,d5
	lsl.w	#3,d5				*2*2^3=16倍
	moveq.l	#16-1,d6
@@:						*MIDIのフェーダー
	move.l	d7,a0
	bsr	chkset_ch_fdr
	addq.w	#1,d5
	dbra	d6,@b
next_cadac:
	dbra	d2,cadac_lp
	rts

chfdr_track_mode1:				*トラックモード1(純粋なトラック指定)
	move.l	seq_wk_tbl_se-work(a6),a1
	btst.b	#_ID_SE,p_track_stat(a5)
	bne	@f
do_chfdr_track_mode1:				*< fnc$5b
	move.l	seq_wk_tbl-work(a6),a1
@@:
	moveq.l	#0,d0
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0
	cmpi.w	#-1,d0
	beq	1f
	swap	d0
	lsr.l	#16-trwk_size_,d0
	adda.l	d0,a1
	tst.b	p_track_stat(a1)	*死んでるトラックは再演奏不可
	bmi	chf_dead
	move.l	p_type(a1),d0
	bsr	ch_odr_no_abs			*チャンネルフェーダーパラメータへ変換(>d5.w)
	bpl	chkset_ch_fdr
	bra	chf_dead

chfdr_track_mode2:				*トラックモード2
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0
	tst.w	d0
	beq	chfdr_this_track		*このトラック
	cmpi.w	#-1,d0
	bne	chf_dead			*unknown ID
1:
	move.l	play_trk_tbl_se-work(a6),a1
	move.l	seq_wk_tbl_se-work(a6),a2
	btst.b	#_ID_SE,p_track_stat(a5)
	bne	@f
do_chfdr_track_mode2:
	move.l	play_trk_tbl-work(a6),a1
	move.l	seq_wk_tbl-work(a6),a2
@@:
	move.l	a0,d7				*以下全トラック
@@:
	moveq.l	#0,d0
	move.w	(a1)+,d0
	bmi	exit_cftr2
	swap	d0
	lsr.l	#16-trwk_size_,d0
	tst.b	p_track_stat(a2,d0.l)	*死んでるトラックは再演奏不可
	bmi	@b
	move.l	p_type(a2,d0.l),d0
	bsr	ch_odr_no_abs		*チャンネルフェーダーパラメータへ変換(>d5.w)
	bmi	@b
	move.l	d7,a0
	bsr	chkset_ch_fdr
	bra	@b

chfdr_this_track:
	move.l	d4,d0
	bsr	ch_odr_no_abs			*チャンネルフェーダーパラメータへ変換(>d5.w)
	bmi	chf_dead

chkset_ch_fdr:
	* < d5.w=ch_fader tbl ID(0-95)
	* x d0,d3
reglist	reg	a1-a2
	movem.l	reglist,-(sp)
	move.b	(a0)+,d3		*omt
	move.w	d5,d0
	lsl.w	#fd_wkl_,d0
	lea	ch_fm_fdp-work(a6),a2
	adda.w	d0,a2			*ch_xx_fdp n
	lea	ch_fader_tbl-work(a6),a1
	ori.b	#ff_ch_fader,fader_flag-work(a6)	*faderマーク
@@:
	move.w	(a1)+,d0
	bmi	@f
	cmp.w	d0,d5
	bne	@b
	bra	do_set_chfdrprm		*既存のパラメータ書き換えケース
@@:					*新規にオーダー追加
	tst.b	d3
	beq	exit_gcf
	st.b	(a1)
	move.w	d5,-(a1)
						*デフォルト値セット
	move.l	#fader_dflt_spd,fd_spd2(a2)	*set fd_spd2,fd_spd
	move.l	#$007f_0000,fd_lvlw(a2)		*fd_lvlw,fd_dest
do_set_chfdrprm:
	tst.b	d3			*omt=0ならばフェーダー解除用のパラメータを設定する
	beq	off_chfdr
	lsr.b	#1,d3			*chk omt
	bcc	@f
	moveq.l	#0,d0
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0
	move.l	d0,fd_spd2(a2)		*set fd_spd2,fd_spd
@@:
	lsr.b	#1,d3			*chk omt
	bcc	@f
	move.b	(a0)+,fd_lvlb(a2)	*set source level
@@:
	lsr.b	#1,d3			*chk omt
	bcc	@f
	move.b	(a0)+,fd_dest(a2)	*set destination level
@@:
	ori.b	#$41,fo_ch_fm-work(a6,d5.w)	*今回の発音からフェーダー計算させるため
	move.b	fd_lvlb(a2),d0		*set source level
	cmp.b	fd_dest(a2),d0
	bhi	gcf00
	beq	@f
	move.b	#$01,fd_mode(a2)	*f.i. mode on
	movem.l	(sp)+,reglist
	rts
gcf00:
	st.b	fd_mode(a2)		*f.o. mode on
	movem.l	(sp)+,reglist
	rts
@@:
	tst.b	d0
	bpl	@f
	move.b	#CH_FADER_RESET,fd_mode(a2)
	movem.l	(sp)+,reglist
	rts
@@:
	clr.b	fd_mode(a2)
exit_gcf:
	movem.l	(sp)+,reglist
	rts

ch_odr_no_abs:
	* < d0.hw=type,d0.lw=ch
	* x a4
	* > d5.w=チャンネルフェーダーテーブル用オーダー値
	* > minusはエラー
	swap	d0
	tst.w	d0
	beq	con_fm
	bmi	con_midi
				*ADPCM
	moveq.l	#16,d5
	swap	d0
	add.w	d0,d5
	rts

con_fm:				*FM
	swap	d0
	move.w	d0,d5
	rts

con_midi:			*MIDI
	btst.b	d0,midi_board-work(a6)
	beq	@f		*未装着デバイス
	moveq.l	#32,d5
	lsl.w	#4,d0		*16倍
	add.w	d0,d5
	swap	d0
	add.w	d0,d5
	clr.l	fader_result-work(a6)
	rts
@@:
	move.l	#-1,fader_result-work(a6)	*Nフラグ立てるため
	rts

ch_odr_no:
	* < d0.hw=type,d0.lw=ch
	* x a4
	* > d5.w=チャンネルフェーダーテーブル用オーダー値
	* > minusはエラー
	swap	d0
	tst.w	d0
	beq	_con_fm
	bmi	_con_midi
				*ADPCM
	moveq.l	#16,d5
	swap	d0
	add.w	d0,d5
	rts

_con_fm:				*FM
	swap	d0
	move.w	d0,d5
	rts

_con_midi:			*MIDI
	moveq.l	#32,d5
	ext.w	d0		*最上位殺す
	lea	midi_if_tbl-work(a6),a4
	move.b	(a4,d0.w),d0	*既に２倍された値
	bmi	@f
	lsl.w	#4-1,d0		*16倍
	add.w	d0,d5
	swap	d0
	add.w	d0,d5
	clr.l	fader_result-work(a6)
	rts
@@:
	move.l	#-1,fader_result-work(a6)	*Nフラグ立てるため
	rts
*------------------------------------------------------------------------------
pcm_mode_ad:
	bclr.b	#b_vtune_mode,p_md_flg(a5)
	move.b	(a0)+,d0
	or.b	d0,p_md_flg(a5)
	bra	next_cmd_ad
*------------------------------------------------------------------------------
damper_md:				*MIDI ダンパーペダル
	move.b	(a0)+,d1
	move.b	d1,p_damper(a5)
	check_concur	MIDI_DMP
	bset.b	#pts_damper,p_timbre_set(a5)	*音量設定フラグオン
	bra	next_cmd_md

track_mode_fm:				*FM ノートオフなしモード
	moveq.l	#0,d1
	move.b	(a0)+,d0
	beq	@f
	moveq.l	#127,d1
@@:
*	move.b	d1,p_damper(a5)
	move.b	p_track_mode(a5),d2	*d2=previous
	andi.b	#$ff.and.(.not.ID_NO_KEYOFF),p_track_mode(a5)
	or.b	d0,p_track_mode(a5)
	bmi	next_cmd_fm
	bra	go_dokn2fm

damper_fm:				*FM ダンパーペダル
	moveq.l	#0,d0
	move.b	(a0)+,d1
	move.b	d1,p_damper(a5)
	cmpi.b	#64,d1
	bcs	@f
	moveq.l	#ID_NO_KEYOFF,d0
@@:
	move.b	p_track_mode(a5),d2	*d2=previous
	andi.b	#$ff.and.(.not.ID_NO_KEYOFF),p_track_mode(a5)
	or.b	d0,p_track_mode(a5)
	bmi	next_cmd_fm
go_dokn2fm:
	tst.b	d2			*もともとoffならなにもしない
	bpl	next_cmd_fm
	cmpi.b	#63,d1
	bhi	next_cmd_fm
	pea	next_cmd_fm(pc)

do_kn2_fm:				*ゲートタイム0のノートをキーオフ
	* < d4.l=type,ch
	* x d0-d2,d6/a1,a4
*	move.b	p_how_many(a5),d3	*!5/10
*	bmi	exit_kn2_fm		*!already all off
	move.w	p_voice_rsv(a5),d6	*loop counter
	lea	p_note(a5),a1
	moveq.l	#8,d1			*FM reg. number
	move.w	d4,d0
	move.l	p_opmset(a5),a4
fko2_lp_f:
*	tst.b	k_velo(a1)		*!k_velo=miならゲート0になったことがある
*	bpl	@f			*!
	tas.b	(a1)
*	bmi	@f			*!
	move.b	opm_kon-work(a6,d0.w),d2
	and.b	opm_nom-work(a6,d0.w),d2
	jsr	(a4)			*opmset(FM key off)
	bset.b	#b_keyoff,p_onoff_bit(a5)	*set key off bit
*	subq.b	#1,d3			*!
@@:
	addq.w	#k_note_len,a1
	addq.b	#1,d0
	andi.b	#7,d0
	dbra	d6,fko2_lp_f
*	move.b	d3,p_how_many(a5)	*!all key off
exit_kn2_fm:
	rts

track_mode_ad:				*ADPCM ノートオフなしモード
	moveq.l	#0,d1
	move.b	(a0)+,d0
	beq	@f
	moveq.l	#127,d1
@@:
*	move.b	d1,p_damper(a5)
	move.b	p_track_mode(a5),d2	*d2=previous
	andi.b	#$ff.and.(.not.ID_NO_KEYOFF),p_track_mode(a5)
	or.b	d0,p_track_mode(a5)
	bmi	next_cmd_ad
	bra	go_dokn2ad

damper_ad:				*ADPCM ダンパーペダル
	moveq.l	#0,d0
	move.b	(a0)+,d1
	move.b	d1,p_damper(a5)
	cmpi.b	#64,d1
	bcs	@f
	moveq.l	#ID_NO_KEYOFF,d0
@@:
	move.b	p_track_mode(a5),d2	*d2=previous
	andi.b	#$ff.and.(.not.ID_NO_KEYOFF),p_track_mode(a5)
	or.b	d0,p_track_mode(a5)
	bmi	next_cmd_ad
go_dokn2ad:
	tst.b	d2
	bpl	next_cmd_ad
	cmpi.b	#63,d1
	bhi	next_cmd_ad
	pea	next_cmd_ad(pc)

do_kn2_ad:				*ゲートタイム0のノートをキーオフ
*	move.b	p_how_many(a5),d3	*!5/10
*	bmi	exit_kn2_ad		*!already all off
	move.w	p_voice_rsv(a5),d6	*loop counter
	lea	p_note(a5),a1
	moveq.l	#0,d5
	move.b	d4,d5
fko2_lp_a:
*	tst.b	k_velo(a1)		*!test velocity
*	bpl	@f			*!not 0
	tas.b	(a1)			*note.b
*	bmi	@f			*!
	move.l	d5,d0
	bsr	pcm_key_off
	bset.b	#b_keyoff,p_onoff_bit(a5)	*set key off bit
*	subq.b	#1,d3
@@:
	addq.w	#k_note_len,a1
	addq.b	#1,d5
	andi.b	#$0f,d5
	dbra	d6,fko2_lp_a
*	move.b	d3,p_how_many(a5)	*!
exit_kn2_ad:
	rts

track_mode_md:
	move.b	(a0)+,d0
	andi.b	#$ff.and.(.not.ID_NO_KEYOFF),p_track_mode(a5)
	or.b	d0,p_track_mode(a5)
	bra	next_cmd_md
*------------------------------------------------------------------------------
bend_range_md:			*ベンドレンジ切り換え
	moveq.l	#$b0,d0
	add.b	d4,d0		*ctrl chg
	move.l	p_midi_trans(a5),a2
	jsr	(a2)
	moveq.l	#$64,d0
	jsr	(a2)		*RPN L
	moveq.l	#$00,d0
	jsr	(a2)
	moveq.l	#$65,d0
	jsr	(a2)		*RPN H
	moveq.l	#$00,d0
	jsr	(a2)
	moveq.l	#$06,d0
	jsr	(a2)		*data entry
	move.b	(a0)+,d0
	move.b	d0,p_@b_range(a5)
	jsr	(a2)
	bra	next_cmd_md
*------------------------------------------------------------------------------
timbre_set2:				*音色設定#2
	* > a2.l=p_midi_trans(a5)
	* X d0-d2
	move.l	p_midi_trans(a5),a2
	move.b	p_timbre_set(a5),d2
	beq	exit_tmbst2
	bpl	tmst2_prog
	move.b	p_bank_lsb(a5),d1
	bmi	@f
	moveq.l	#$b0,d0
	or.b	d4,d0
	jsr	(a2)
	moveq.l	#$20,d0		*bank LSB
	jsr	(a2)
	move.b	d1,d0
	jsr	(a2)
	move.b	p_bank_msb(a5),d1
	bmi	tmst2_prog
	bpl	ts2_0		*Running Status
@@:
	move.b	p_bank_msb(a5),d1
	bmi	tmst2_prog
	moveq.l	#$b0,d0
	or.b	d4,d0
	jsr	(a2)
ts2_0:
	moveq.l	#$00,d0		*bank MSB
	jsr	(a2)
	move.b	d1,d0
	jsr	(a2)		*BANK送信
tmst2_prog:
	add.b	d2,d2
	bpl	@f
	moveq.l	#$c0,d0
	or.b	d4,d0
	jsr	(a2)		*send pgm chg
	move.w	p_pgm(a5),d0
	jsr	(a2)
@@:
	andi.b	#%0011_1111,p_timbre_set(a5)	*pts_bank,pts_program=0
exit_tmbst2:
	rts

exclusive_md:			*ｴｸｽｸﾙｰｼﾌﾞﾃﾞｰﾀ転送
	bsr	timbre_set2
	moveq.l	#$f0,d0
	jsr	(a2)
	move.b	(a0)+,d2
	cmpi.b	#MKID_ROLAND,d2	*ﾛｰﾗﾝﾄﾞﾌｫｰﾏｯﾄ対応ｴｸｽｸﾙｰｼﾌﾞﾃﾞｰﾀ転送
	beq	1f
	cmpi.b	#MKID_YAMAHA,d2	*ﾛｰﾗﾝﾄﾞﾌｫｰﾏｯﾄ対応ｴｸｽｸﾙｰｼﾌﾞﾃﾞｰﾀ転送
	bne	@f
1:
	move.b	p_maker(a5),d0	*Maker ID
	jsr	(a2)
	move.b	p_device(a5),d0	*Device ID
	jsr	(a2)
	move.b	p_module(a5),d0	*Model ID
	jsr	(a2)
	cmpi.b	#MKID_ROLAND,d2	*ﾛｰﾗﾝﾄﾞﾌｫｰﾏｯﾄ対応ｴｸｽｸﾙｰｼﾌﾞﾃﾞｰﾀ転送
	bne	@f
	moveq.l	#$12,d0		*Command ID(ROLAND)
	jsr	(a2)
@@:
	moveq.l	#0,d0
	move.b	(a0)+,d0	*skip comment
	add.w	d0,a0
	moveq.l	#0,d3		*checksum
	move.b	(a0)+,d1
	lsl.w	#8,d1
	move.b	(a0)+,d1
	swap	d1
	move.b	(a0)+,d1
	lsl.w	#8,d1
	move.b	(a0)+,d1
	cmpi.b	#MKID_YAMAHA,d2
	bne	@f
	subq.l	#3,d1		*アドレス分のぞく
	move.w	d1,d0
	lsr.w	#7,d0
	add.b	d0,d3
	jsr	(a2)
	move.w	d1,d0
	andi.w	#$7f,d0
	add.b	d0,d3
	jsr	(a2)		*ヤマハは転送バイト数も送信
	addq.l	#3,d1		*もとにもどす
@@:
	move.b	(a0)+,d0
	add.b	d0,d3
	jsr	(a2)
	subq.l	#1,d1
	bne	@b
	cmpi.b	#MKID_ROLAND,d2	*ﾛｰﾗﾝﾄﾞﾌｫｰﾏｯﾄ対応ｴｸｽｸﾙｰｼﾌﾞﾃﾞｰﾀ転送
	beq	1f
	cmpi.b	#MKID_YAMAHA,d2	*ﾛｰﾗﾝﾄﾞﾌｫｰﾏｯﾄ対応ｴｸｽｸﾙｰｼﾌﾞﾃﾞｰﾀ転送
	bne	@f
1:
	moveq.l	#$80,d0
	andi.b	#$7f,d3
	sub.b	d3,d0		*d0=Check sum value
	andi.b	#$7f,d0
	jsr	(a2)
@@:
	moveq.l	#$f7,d0		*end of exclusive
	jsr	(a2)
	bra	next_cmd_md
*------------------------------------------------------------------------------
ID_set_md:				*ID SET
	move.b	(a0)+,d0
	bmi	@f
	move.b	d0,p_maker(a5)
@@:
	move.b	(a0)+,d0
	bmi	@f
	move.b	d0,p_device(a5)
@@:
	move.b	(a0)+,d0
	bmi	next_cmd_md
	move.b	d0,p_module(a5)
	bra	next_cmd_md
*------------------------------------------------------------------------------
midi_transmission_md:			*生MIDIデータ転送
	bsr	timbre_set2
	moveq.l	#0,d0
	move.b	(a0)+,d0	*skip comment
	add.w	d0,a0
	move.b	(a0)+,d1
	lsl.w	#8,d1
	move.b	(a0)+,d1	*d1=number of data
	swap	d1
	move.b	(a0)+,d1
	lsl.w	#8,d1
	move.b	(a0)+,d1	*d1=number of data
@@:
	move.b	(a0)+,d0
	jsr	(a2)		*send first data
	subq.l	#1,d1
	bne	@b
	bra	next_cmd_md
*------------------------------------------------------------------------------
frq_chg_ad:			*@F 周波数切り換え
	move.b	(a0)+,d1
	move.b	d1,p_frq(a5)
	bsr	do_adpcm_frq
	bra	next_cmd_ad
*------------------------------------------------------------------------------
NRPN_md:			*@Yコマンド(SET DATA TO NRPN)
	moveq.l	#$b0,d0		*ｺﾝﾄﾛｰﾙﾁｪﾝｼﾞ
	or.b	d4,d0
	move.l	p_midi_trans(a5),a2
	jsr	(a2)
	moveq.l	#$63,d0		*NRPN H
	jsr	(a2)
	move.b	(a0)+,d0
	jsr	(a2)

	moveq.l	#$62,d0		*NRPN L
	jsr	(a2)
	move.b	(a0)+,d0
	jsr	(a2)

	moveq.l	#$06,d0
	jsr	(a2)
	move.b	(a0)+,d0
	bmi	@f
	jsr	(a2)		*H
@@:
	move.b	(a0)+,d1
	bmi	next_cmd_md	*L省略時
	moveq.l	#$26,d0
	jsr	(a2)
	move.b	d1,d0
	jsr	(a2)		*L
	bra	next_cmd_md
*------------------------------------------------------------------------------
effect_ctrl_md:			*@E effect control
	move.b	(a0)+,d2	*get omt.
	beq	next_cmd_md
	move.l	p_midi_trans(a5),a2
	move.l	p_maker(a5),d0
	andi.l	#$ff00_ff00,d0
	cmpi.l	#$4100_1600,d0
	beq	e_mt32		*MT32
				*コントロールチェンジでコントロールする場合
	moveq.l	#$b0,d0		*d1=ctrl chg message
	or.b	d4,d0
	jsr	(a2)
	lea	p_effect1(a5),a1
	move.l	#$000f_cedb,d3	*$5b,$5d,$5e,$5c,$5fの順番でctrl番号を生成
ecmlp00:
	lsr.b	#1,d2
	bcc	@f
	move.b	d3,d0		*ctrl no.
	andi.b	#$0f,d0
	ori.b	#$50,d0
	jsr	(a2)
	move.b	(a0)+,d0
	move.b	d0,(a1)+	*value
	jsr	(a2)
	lsr.l	#4,d3
	tst.b	d2
	bne	ecmlp00
	bra	next_cmd_md
@@:
	addq.w	#1,a1
	lsr.l	#4,d3
	tst.b	d2
	bne	ecmlp00
	bra	next_cmd_md

e_mt32:
	move.l	#$0003_00_00,d1
	lsr.b	#1,d2		*dummy shift(必ず一個はパラメータがあるはずなので無条件シフト)
	move.b	(a0)+,d1	*get part number
	cmpi.b	#7,d1
	bls	@f
	move.b	#$10,d1		*8以上はrythm partとみなす
@@:
	lsl.w	#4,d1		*16倍
	addq.b	#6,d1		*reverb switch offset

	moveq.l	#$f0,d0		*exc
	jsr	(a2)
	moveq.l	#$41,d0		*maker
	jsr	(a2)
	move.b	p_device(a5),d0	*device
	jsr	(a2)
	moveq.l	#$16,d0		*module
	jsr	(a2)
	moveq.l	#$12,d0		*command
	jsr	(a2)
	moveq.l	#0,d3		*clr chk_sum
	swap	d1
	move.b	d1,d0
	add.b	d0,d3
	jsr	(a2)
	rept	2
	rol.l	#8,d1
	move.b	d1,d0
	add.b	d0,d3
	jsr	(a2)
	endm
	moveq.l	#0,d0		*default=0(OFF)
	lsr.b	#1,d2		*スイッチの値省略
	bcc	@f
	move.b	(a0)+,d0
	beq	@f
	moveq.l	#1,d0		*それ以外は1(ON)とする
	add.b	d0,d3
@@:
	jsr	(a2)
	andi.b	#$7f,d3
	moveq.l	#$80,d0
	sub.b	d3,d0
	andi.b	#$7f,d0
	jsr	(a2)		*check sum
	moveq.l	#$f7,d0		*end of EXC
	jsr	(a2)
	bsr	skip_by_d2	*残ったomt.bitを参照しa0を更新
	bra	next_cmd_md
*------------------------------------------------------------------------------
poke_md:				*ワーク直接書き換え直接
	bsr	do_poke
	bra	next_cmd_md

poke_ad:				*ワーク直接書き換え直接
	bsr	do_poke
	bra	next_cmd_ad

poke_fm:				*ワーク直接書き換え直接
	pea	next_cmd_fm(pc)

do_poke:
	moveq.l	#0,d0
	move.b	(a0)+,d0		*get mode
	move.l	d0,d1
	lsr.b	#4,d0
	moveq.l	#0,d2
@@:
	lsl.l	#8,d2
	move.b	(a0)+,d2		*get offset
	dbra	d0,@b
	andi.w	#$0f,d1
	move.l	d1,d0
	moveq.l	#0,d3
@@:
	lsl.l	#8,d3
	move.b	(a0)+,d3		*get data
	dbra	d0,@b
	move.b	dpjtbl(pc,d1.w),d1
	jmp	dpjtbl(pc,d1.w)
dpjtbl:
	dc.b	dpj_byte-dpjtbl		*0
	dc.b	dpj_word-dpjtbl		*1
	dc.b	@f-dpjtbl		*2
	dc.b	dpj_long-dpjtbl		*3
dpj_byte:
	move.b	d3,(a5,d2.l)
@@:
	rts
dpj_word:
	move.w	d3,(a5,d2.l)
	rts
dpj_long:
	move.l	d3,(a5,d2.l)
	rts
*------------------------------------------------------------------------------
rltv_poke_ad:				*ワーク直接書き換え相対
	bsr	do_rltv_poke
	bra	next_cmd_ad

rltv_poke_md:				*ワーク直接書き換え相対
	bsr	do_rltv_poke
	bra	next_cmd_md

rltv_poke_fm:				*ワーク直接書き換え相対
	pea	next_cmd_fm(pc)

do_rltv_poke:
	moveq.l	#0,d0
	move.b	(a0)+,d0		*get mode
	move.l	d0,d1
	lsr.b	#4,d0
	moveq.l	#0,d2
@@:
	move.b	(a0)+,d2		*get offset
	lsl.w	#8,d2
	dbra	d0,@b
	andi.w	#$0f,d1
	move.l	d1,d0
	moveq.l	#0,d3
@@:
	move.b	(a0)+,d3		*get data
	lsl.w	#8,d3
	dbra	d0,@b
	move.b	dprjtbl(pc,d1.w),d1
	jmp	dprjtbl(pc,d1.w)
dprjtbl:
	dc.b	dprj_byte-dprjtbl
	dc.b	dprj_word-dprjtbl
dprj_byte:
	tst.b	d2
	bmi	dprj_byte_minus
	add.b	d2,(a5,d3.w)
	bcs	@f
	rts
@@:
	st.b	(a5,d3.w)		*set max vlaue
	rts
dprj_byte_minus:
	add.b	d2,(a5,d3.w)
	bmi	@f
	rts
@@:
	clr.b	(a5,d3.w)
	rts

dprj_word:
	tst.w	d2
	bmi	dprj_word_minus
	add.w	d2,(a5,d3.w)
	bcs	@f
	rts
@@:
	move.w	#-1,(a5,d3.w)
	rts
dprj_word_minus:
	add.w	d2,(a5,d3.w)
	bmi	@f
	rts
@@:
	clr.w	(a5,d3.w)
	rts
*------------------------------------------------------------------------------
pmod_mode_md:			*MIDI PMODモード設定
	move.b	(a0)+,d0
	cmp.b	p_pmod_mode(a5),d0
	beq	next_cmd_md	*設定内容が同じならなにもしない
*!2/5	bclr.b	#b_pmod_first,p_pmod_flg(a5)
	move.b	d0,p_pmod_mode(a5)
	bmi	next_cmd_md
	tst.b	p_pmod_sw(a5)
	beq	next_cmd_md
	bsr	calc_pmod
	bra	next_cmd_md
*------------------------------------------------------------------------------
arcc_mode_md:			*MIDI ARCCモード設定
	bsr	get_arcc_a4
	move.b	(a0)+,d0
	cmp.b	p_arcc_mode(a4),d0
	beq	next_cmd_md
*!2/5	bclr.b	#b_arcc_first,p_arcc_flg(a4)
	move.b	d0,p_arcc_mode(a4)
	bmi	next_cmd_md
	tst.b	p_arcc_sw(a4)
	beq	next_cmd_md
	bsr	calc_arcc
	bra	next_cmd_md
*------------------------------------------------------------------------------
waiting_fm:				*Wコマンド(同期待ち)
	moveq.l	#1,d0
	tst.b	p_sync_wk(a5)		*同期待ちにするかどうかの決断
	bne	@f
	move.b	d0,p_sync_wk(a5)	*同期待ちにせず初期状態に戻してリターン
	bra	next_cmd_fm
@@:
	ori.b	#ID_SYNC,p_track_stat(a5)
	move.w	d0,(a5)			*step time=1
	st.b	p_sync_wk(a5)		*waiting
	rts

waiting_ad:				*Wコマンド(同期待ち)
	moveq.l	#1,d0
	tst.b	p_sync_wk(a5)		*同期待ちにするかどうかの決断
	bne	@f
	move.b	d0,p_sync_wk(a5)	*同期待ちにせず初期状態に戻してリターン
	bra	next_cmd_ad
@@:
	ori.b	#ID_SYNC,p_track_stat(a5)
	move.w	d0,(a5)			*step time=1
	st.b	p_sync_wk(a5)		*waiting
	rts

waiting_md:				*Wコマンド(同期待ち)
	moveq.l	#1,d0
	tst.b	p_sync_wk(a5)		*同期待ちにするかどうかの決断
	bne	@f
	move.b	d0,p_sync_wk(a5)	*同期待ちにせず初期状態に戻してリターン
	bra	next_cmd_md
@@:
	ori.b	#ID_SYNC,p_track_stat(a5)
	move.w	d0,(a5)			*step time=1
	st.b	p_sync_wk(a5)		*waiting
	rts
*------------------------------------------------------------------------------
send_sync_md:			*MIDI 同期送信
	bsr	do_send_sync
	bra	next_cmd_md

send_sync_ad:			*ADPCM 同期送信
	bsr	do_send_sync
	bra	next_cmd_ad

send_sync_fm:			*FM 同期送信
	pea	next_cmd_fm(pc)

do_send_sync:			*同期送信コマンドパラメータ取りだし
	moveq.l	#0,d0
	move.b	(a0)+,d0	*get tr number
	lsl.w	#8,d0
	move.b	(a0)+,d0
	cmp.w	trk_n_max-work(a6),d0
	bhi	exit_dss
	swap	d0
	lsr.l	#16-trwk_size_,d0
	move.l	seq_wk_tbl-work(a6),a1
	btst.b	#_ID_SE,p_track_stat(a5)
	beq	@f
	move.l	seq_wk_tbl_se-work(a6),a1
@@:
	adda.l	d0,a1
	bclr.b	#_ID_SYNC,p_track_stat(a1)
	bne	@f
	clr.b	p_sync_wk(a1)
	rts
@@:					*同期信号によって再演奏開始した場合
	move.l	p_total(a5),p_total(a1)	*jumpコマンドに対応するため
exit_dss:
	rts
*------------------------------------------------------------------------------
forceplay_ad:			*ADPCM 強制再演奏
	bsr	do_forceplay
	bra	next_cmd_ad

forceplay_md:			*MIDI 強制再演奏
	bsr	do_forceplay
	bra	next_cmd_md

forceplay_fm:			*FM 強制再演奏
	pea	next_cmd_fm(pc)

do_forceplay:				*強制再演奏
	* d0,d1,a2,a4
	moveq.l	#0,d0
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0
	move.l	d0,d1
	move.l	seq_wk_tbl-work(a6),a1
	movea.l	trk_po_tbl-work(a6),a2
	btst.b	#_ID_SE,p_track_stat(a5)
	beq	@f
	move.l	seq_wk_tbl_se-work(a6),a1
	movea.l	trk_po_tbl_se-work(a6),a2
@@:
	swap	d0
	lsr.l	#16-trwk_size_,d0
	adda.l	d0,a1
	tst.b	p_track_stat(a1)	*死んでるトラックは再演奏不可
	bmi	@f
	movem.l	d4/a5,-(sp)
	move.l	a1,a5
	move.w	#$0001,(a1)+		*dummy step time
	lsl.l	#trk_tbl_size_,d1
	add.l	d1,a2
	move.l	(a2)+,(a1)+		*p_track_stat,p_track_mode,p_trkfrq,p_trkfrq_wk
	move.l	(a2)+,d4
	move.l	d4,(a1)+		*p_type,p_ch
	jsr	_ms_key_off
	add.l	(a2)+,a4
	move.l	a4,(a1)+		*p_data_pointer
	jsr	init_wks2
	movem.l	(sp)+,d4/a5
@@:
	rts
*------------------------------------------------------------------------------
timbre_split_fm:		*FM 音色スプリット
	pea	next_cmd_fm(pc)
	bra	get_timbre_split_param

timbre_split_md:		*MIDI 音色スプリット
	pea	next_cmd_md(pc)
	bra	get_timbre_split_param

timbre_split_ad:		*ADPCM 音色スプリット
	pea	next_cmd_ad(pc)

get_timbre_split_param:
	bclr.b	#b_split_mode,p_md_flg(a5)
	move.b	(a0)+,d0	*get num of param(0-8)
	bpl	@f		*最上位ビットはSPLITスイッチ
	tas.b	p_md_flg(a5)	*bset.b	#b_split_mode,p_md_flg(a5)
@@:
	add.b	d0,d0		*最上位ビット殺す
	beq	exit_gtsp
	lea	p_split_tbl(a5),a1
@@:
	move.b	(a0)+,(a1)+	*start note
	move.b	(a0)+,(a1)+	*end note
	move.b	(a0)+,(a1)+	*bank.w
	move.b	(a0)+,(a1)+
	move.b	(a0)+,(a1)+	*timbre.w
	move.b	(a0)+,(a1)+
	subq.b	#2,d0
	bne	@b
exit_gtsp:
	rts
*------------------------------------------------------------------------------
slot_mask_fm:			*FM スロットマスクの切り換え
	move.b	(a0)+,d0
	beq	@f
				*mode start
	bset.b	#b_slot_mask,p_md_flg(a5)
	move.b	p_om(a5),p_om_bak(a5)
	move.b	d0,p_om(a5)
	not.b	d0
	move.b	d0,opm_nom-work(a6,d4.w)
	bra	next_cmd_fm
@@:				*mode off
	bclr.b	#b_slot_mask,p_md_flg(a5)
	move.b	p_om_bak(a5),d0
	move.b	d0,p_om(a5)
	not.b	d0
	move.b	d0,opm_nom-work(a6,d4.w)
	bra	next_cmd_fm

timbre_fm:			*FM 音色切り換え
	moveq.l	#0,d0
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0
	move.w	d0,p_pgm(a5)
	move.b	p_bank_msb(a5),d1
	ext.w	d1
	bmi	@f
	lsl.w	#7,d1
	move.b	p_bank_lsb(a5),d2
	bmi	@f
	or.b	d2,d1
	lsl.w	#7,d1
	add.w	d1,d0		*バンク考慮
@@:
	moveq.l	#0,d1
	move.b	p_next_on(a5),d1
	cmp.w	p_voice_rsv(a5),d1
	bls	@f
	moveq.l	#0,d1
@@:
	clr.b	p_tone_set(a5)
	bset.b	d1,p_tone_set(a5)
	add.w	d1,d4
	andi.w	#$07,d4
	move.w	d4,d1
	add.w	d1,d1
	move.l	(a6),a1
	lea	fm_tone_set-work(a6),a4
	move.w	-(a1),(a4,d1.w)
	move.b	d4,p_timbre_src(a5)
	bsr	fmvset
	move.w	p_ch(a5),d4
	bra	next_cmd_fm

init_rr:
	moveq.l	#$e0,d1
	add.b	d4,d1
	moveq.l	#$ff,d2
	moveq.l	#4-1,d0
@@:
	jsr	(a4)
	addq.b	#8,d1
	dbra	d0,@b

	moveq.l	#$60,d1
	add.b	d4,d1
	moveq.l	#4-1,d0
@@:
	jsr	(a4)
	addq.b	#8,d1
	dbra	d0,@b
	rts

fmvset:				*ＦＭ音色のセット
	* < d0.l=sound number(0～32767)
	* < d4.w=ch
	* < a5=seq_wk_tbl n
	* - all
	* x a4
reglist	reg	d0-d3/a1/a4
	cmp.w	fmsnd_n_max-work(a6),d0
	bcc	_exit_fmvset
	movem.l	reglist,-(sp)
	lsl.l	#4,d0
	move.l	d0,d1
	add.l	d0,d0
	add.l	d1,d0		*fmsnd_size倍
	movea.l	fmsnd_buffer-work(a6),a1
	adda.l	d0,a1
	tst.w	(a1)+
	beq	exit_fmvset
	move.l	p_opmset(a5),a4
	bsr	init_rr
	bsr	swk_copy	*アウトプットレベル等のワークへのコピー

	moveq.l	#$18,d1
	move.b	(a1)+,d2	*0)LFRQ
	jsr	(a4)		*opmset

	moveq.l	#$19,d1
	move.b	(a1)+,d2	*1)PMD/F=1
	jsr	(a4)		*opmset
	move.b	(a1)+,d2	*2)AMD/F=0
	jsr	(a4)		*opmset

	move.b	(a1)+,d2	*3)SYNC/OM/WF
	smi.b	p_sync(a5)
	andi.b	#$03,d2		*get only WF
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	move.b	OPMCTRL.w,d1
	andi.b	#$fc,d1
	or.b	d1,d2
	moveq.l	#$1b,d1
	jsr	(a4)		*opmset
	move.w	(sp)+,sr

	moveq.l	#$20,d1
	or.b	d4,d1		*$20+n
	move.b	(a1)+,d2	*4)PAN/AF
	jsr	(a4)		*opmset
	rol.b	#2,d2
	andi.w	#3,d2
	move.b	_pan_tbl_(pc,d2.w),p_pan(a5)
	bra	@f
_pan_tbl_:	dc.b	-1,0,127,64
@@:
	add.b	#$18,d1		*$38+n
	move.b	(a1)+,d2	*5)PMS/AMS
	jsr	(a4)		*opmset

OP_parameters:
*-----------------------------------
	moveq.l	#4-1,d0
@@:
	addq.b	#8,d1
	move.b	(a1)+,d2	*6)～9)DT1/MUL
	jsr	(a4)		*opmset
	dbra	d0,@b
*-----------------------------------
*	tst.w	p_level_param(a5)		*!
*	bne	@f			*!
*	move.w	#4,p_level_param(a5)	*!
	or.w	#4,p_level_param(a5)	*!
*@@:					*!
	addq.w	#4,a1
	add.w	#32,d1
*-----------------------------------
	moveq.l	#16-1,d0
@@:
	addq.b	#8,d1		*14)KS/AR～29)1DL/RR
	move.b	(a1)+,d2
	jsr	(a4)		*opmset
	dbra	d0,@b
*-----------------------------------
exit_fmvset:
	movem.l	(sp)+,reglist
_exit_fmvset:
	rts

timbre2_fm:			*FM H-LFOノンタッチ・音色切り換え(MXDRV.Xコンパチ)
	moveq.l	#0,d0
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0
	move.w	d0,p_pgm(a5)
	move.b	p_bank_msb(a5),d1
	ext.w	d1
	bmi	@f
	lsl.w	#7,d1
	move.b	p_bank_lsb(a5),d2
	bmi	@f
	or.b	d2,d1
	lsl.w	#7,d1
	add.w	d1,d0		*バンク考慮
@@:
	moveq.l	#0,d1
	move.b	p_next_on(a5),d1
	cmp.w	p_voice_rsv(a5),d1
	bls	@f
	moveq.l	#0,d1
@@:
	clr.b	p_tone_set(a5)
	bset.b	d1,p_tone_set(a5)
	add.w	d1,d4
	andi.w	#$07,d4
	move.w	d4,d1
	add.w	d1,d1
	move.l	(a6),a1
	lea	fm_tone_set-work(a6),a4
	move.w	-(a1),(a4,d1.w)
	move.b	d4,p_timbre_src(a5)
	bsr	mx_fmvset
	move.w	p_ch(a5),d4
	bra	next_cmd_fm

mx_fmvset:			*ＦＭ音色のセット
	* < d0.l=sound number(0～32767)
	* < d4.w=ch
	* < a5=seq_wk_tbl n
	* - all
	cmp.w	fmsnd_n_max-work(a6),d0
	bcc	_exit_fmvset
	movem.l	reglist,-(sp)
	lsl.l	#4,d0
	move.l	d0,d1
	add.l	d0,d0
	add.l	d1,d0		*fmsnd_size倍
	movea.l	fmsnd_buffer-work(a6),a1
	adda.l	d0,a1
	tst.w	(a1)+
	beq	exit_fmvset
	move.l	p_opmset(a5),a4
	bsr	init_rr
	bsr	swk_copy	*アウトプットレベル等のワークへのコピー(PAN保存)

	addq.w	#4,a1

	moveq.l	#$20,d1		*LR/AF
	or.b	d4,d1
	move.b	(a1)+,d0	*4)PAN/AF
	andi.b	#$3f,d0		*mask pan
	move.b	p_pan(a5),d2	*get default pan
	bsr	conv_p@p
	ror.b	#2,d2
	or.b	d0,d2
	jsr	(a4)		*opmset
	addq.w	#1,a1
	add.b	#$18,d1		*$38+n
	bra	OP_parameters

swk_copy:			*あとでボリューム変更等で使うので音色数列のなかから
	* < d4.w=ch
	* X d0			*必要なパラメータをワークへ待避する
	* - a4
	move.b	10(a1),ol1-work(a6,d4.w)
	move.b	12(a1),ol2-work(a6,d4.w)
	move.b	11(a1),ol3-work(a6,d4.w)
	move.b	13(a1),ol4-work(a6,d4.w)
	move.b	4(a1),d0
	andi.w	#7,d0					*get algorithm
	move.b	carrier_tbl(pc,d0.w),cf-work(a6,d4.w)	*CF
	move.b	3(a1),d0				*3)SYNC/OM/WF
	btst.b	#b_slot_mask,p_md_flg(a5)
	bne	@f
	and.b	#%0111_1000,d0				*get OM
	move.b	d0,p_om(a5)
	not.b	d0
	move.b	d0,opm_nom-work(a6,d4.w)
@@:
	rts

carrier_tbl:			*アルゴリズムに対応するキャリアの位置
	dc.b	%1000		*AL0
	dc.b	%1000		*AL1
	dc.b	%1000		*AL2
	dc.b	%1000		*AL3
	dc.b	%1010		*AL4
	dc.b	%1110		*AL5
	dc.b	%1110		*AL6
	dc.b	%1111		*AL7

timbre2_ad:			*ADPCM 音色切り換え
timbre_ad:			*ADPCM 音色切り換え
	move.b	(a0)+,p_pgm+0(a5)
	move.b	(a0)+,p_pgm+1(a5)
	bra	next_cmd_ad

do_timbre_split_ad:		*ADPCM音色スプリット
do_timbre_split_md:		*MIDI 音色スプリット
	* < d7.b=note
	* < d1.hw=bank
	* < d1.lw=timbre
	* > d1.hw=bank
	* > d1.lw=timbre
	* x d0-d2/a2
	lea	p_split_tbl(a5),a2
	moveq.l	#n_of_split-1,d2
@@:
	move.b	pst_split_st(a2),d0	*range start param
	bmi	do_split_md
	cmp.b	d0,d7
	bcs	next_dtsm
	move.b	pst_split_ed(a2),d0	*range end param
	bmi	do_split_md
	cmp.b	d0,d7
	bls	do_split_md
next_dtsm:
	addq.w	#pst_split_len,a2
	dbra	d2,@b
	rts			*splitなし

do_split_md:
	move.w	pst_split_bank(a2),d0	*get bank number
	cmp.w	p_bank_msb(a5),d0	*バンクの比較もする
	beq	@f
	move.w	d0,p_bank_msb(a5)
	swap	d1
	move.w	d0,d1
	swap	d1
	move.w	pst_split_pgm(a2),d0
	move.w	d0,p_pgm(a5)
	move.w	d0,d1
	rts
@@:					*音色番号の比較
	move.w	pst_split_pgm(a2),d0
	cmp.w	p_pgm(a5),d0		*すでに同じ音色が設定されているならばスキップ
	beq	@f
	move.w	d0,p_pgm(a5)
	move.w	d0,d1
@@:
	rts

timbre2_md:			*MIDI 音色切り換え
timbre_md:			*MIDI 音色切り換え
	move.b	(a0)+,d1	*get sound number H
	lsl.w	#8,d1
	move.b	(a0)+,d1	*get sound number L
	move.l	p_midi_trans(a5),a2
	cmpi.w	#127,d1
	bhi	@f
	move.w	d1,p_pgm(a5)
	bset.b	#pts_program,p_timbre_set(a5)
	bra	next_cmd_md
@@:
	move.l	d1,d3
	lsr.w	#7,d3
	andi.w	#127,d3		*bank msb
	cmp.b	p_bank_msb(a5),d3
	beq	@f
	move.b	d3,p_bank_msb(a5)
	tas.b	p_timbre_set(a5)
@@:
	andi.w	#127,d1		*pgm number
	move.w	d1,p_pgm(a5)
	bset.b	#pts_program,p_timbre_set(a5)
	bra	next_cmd_md
*------------------------------------------------------------------------------
bank_select_ad:			*Iコマンド(bank select)
	move.b	(a0)+,d0
	bmi	@f
	move.b	d0,p_bank_msb(a5)
@@:
	move.b	(a0)+,d0
	bmi	@f
	move.b	d0,p_bank_lsb(a5)
@@:
	btst.b	#b_vtune_mode,p_md_flg(a5)
	bne	next_cmd_ad
	move.w	p_bank_msb(a5),p_pgm(a5)	*TONE MODE時
	bra	next_cmd_ad

bank_select_fm:			*Iコマンド(bank select)
	move.b	(a0)+,d0
	bmi	@f
	move.b	d0,p_bank_msb(a5)
@@:
	move.b	(a0)+,d0
	bmi	next_cmd_fm
	move.b	d0,p_bank_lsb(a5)
	bra	next_cmd_fm

bank_select_md:			*Iコマンド(bank select) ctrl chg 0,32
*!97/2/6	tas.b	p_timbre_set(a5)
	move.l	p_midi_trans(a5),a2
	move.b	(a0)+,d1
	bmi	@f
	move.b	d1,p_bank_msb(a5)
	moveq.l	#$b0,d0
	or.b	d4,d0
	jsr	(a2)
	moveq.l	#$00,d0		*bank MSB
	jsr	(a2)
	move.b	d1,d0
	jsr	(a2)
@@:
	move.b	(a0)+,d1
	bmi	next_cmd_md
	move.b	d1,p_bank_lsb(a5)
	moveq.l	#$b0,d0
	or.b	d4,d0
	jsr	(a2)
	moveq.l	#$20,d0		*bank LSB
	jsr	(a2)
	move.b	d1,d0
	jsr	(a2)		*BANK送信
	bra	next_cmd_md

do_timbre_split_fm:		*FM 音色スプリット
	* < d1.w=offset
	* < d7.b=note
reglist	reg	d0-d2/d4-d5/a2
	movem.l	reglist,-(sp)
	lea	p_split_tbl(a5),a2
	moveq.l	#n_of_split-1,d2
@@:
	move.b	pst_split_st(a2),d0	*range start param
	bmi	do_split_fm
	cmp.b	d0,d7
	bcs	next_dtsf
	move.b	pst_split_ed(a2),d0	*range end param
	bmi	do_split_fm
	cmp.b	d0,d7
	bls	do_split_fm
next_dtsf:
	addq.w	#pst_split_len,a2
	dbra	d2,@b
	movem.l	(sp)+,reglist
	rts				*splitなし

do_split_fm:
	move.w	pst_split_bank(a2),d0	*get bank number
	cmp.w	p_bank_msb(a5),d0	*バンクの比較もする
	beq	@f
	move.w	d0,p_bank_msb(a5)
	clr.b	p_tone_set(a5)
@@:					*音色番号の比較
	move.w	pst_split_pgm(a2),d0
	cmp.w	p_pgm(a5),d0		*すでに同じ音色が設定されているならばスキップ
	beq	@f
	move.w	d0,p_pgm(a5)
	clr.b	p_tone_set(a5)
@@:
	bset.b	d1,p_tone_set(a5)	*音色設定済みマークON
	bne	1f			*すでにマーク済み(音色設定済み)ならばEXIT
	add.b	d1,d4
	andi.w	#$07,d4
	move.b	d4,p_timbre_src(a5)
	move.w	p_pgm(a5),d0
	moveq.l	#0,d1
	move.b	p_bank_msb(a5),d5
	bmi	@f
	move.b	d5,d1
	andi.w	#$7f,d0			*バンクモードならばpgm=0-127
@@:
	lsl.w	#7,d1
	moveq.l	#0,d2
	move.b	p_bank_lsb(a5),d5
	bmi	@f
	move.b	d5,d2
	andi.w	#$7f,d0			*バンクモードならばpgm=0-127
@@:
	or.b	d2,d1
	lsl.w	#7,d1
	add.w	d1,d0			*バンク考慮
	bsr	fmvset
1:
	movem.l	(sp)+,reglist
	rts
*------------------------------------------------------------------------------
do_adpcm_frq:
	* < d1.b=frq
	* < d4.b=ch
adpcm_frq_patch0:		*パッチが当たる(bra frq_mpcm)
	move.l	d1,d0
	move.b	d0,adpcm_frq-work(a6)
	tst.b	se_mode-work(a6)
	bne	exit_fa		*se modeで演奏中ならexit
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	move.b	OPMCTRL.w,d2	*音声合成クロック読みだし
	tas.b	d2		*最上位ビット=1だと4MHz,0だと8MHz
	cmpi.b	#$05,d0
	bhi	1f		*31.2kHz
	beq	2f		*20.8kHz
	cmpi.b	#$02,d0
	bcs	@f		*5.2kHzならばクロック4MHz
	subq.b	#$02,d0
	andi.b	#$7f,d2		*7.8kHzならばクロック8MHz
	bra	@f
1:
	moveq.l	#3,d0
	andi.b	#$7f,d2
	bra	@f
2:
	moveq.l	#3,d0
@@:
	moveq.l	#$1b,d1
	jsr	opmset-work(a6)	*クロックを書き込む
	lsl.b	#2,d0
	andi.b	#%0000_1100,d0
	move.b	$e9a005,d1	*周波数やパンをゲット
	andi.b	#%1111_0011,d1
	or.b	d0,d1		*設定値を作成
	move.b	d1,$e9a005	*コントロールデータ送信
	move.w	(sp)+,sr
exit_fa:
	rts

frq_mpcm:			*mpcmモード時のfrqチェンジ
	* < d1.b=frq(0-4,5,6)
	* x d0,d1
frq_mpcm_patch:			*V2互換モードではパッチ(NOP)
	bra.s	1f
	cmpi.b	#5,d1		*16bitPCM
	beq	@f
	cmpi.b	#6,d1		*8bitPCM
	bne	1f
@@:
	moveq.l	#4,d1		*15.6kHz
1:
	move.w	#M_SET_FRQ,d0
	move.b	d4,d0
	MPCM_call
	rts
*------------------------------------------------------------------------------
do_adpcm_pan:
	* < d2.b=panpot(0-127)
	* < d4.b=ch
	* - d3
adpcm_pan_patch0:			*パッチが当たる(bra pan_mpcm)
	bsr	conv_p@p
	move.b	d2,adpcm_pan-work(a6)	*グローバルパラメータ
	tst.b	se_mode-work(a6)
	bne	exit_pa			*se modeで演奏中ならexit
	lea	$e9a005,a1
	move.b	(a1),d0
	and.b	#%1111_1100,d0
	tst.b	d2
	beq	@f
	cmpi.b	#3,d2		*出力チェック
	bne	pa1
@@:
	eori.b	#%0000_0011,d2	*ビット反転
pa1:
	or.b	d2,d0
	move.b	d0,(a1)
exit_pa:
	rts

pan_mpcm:				*mpcmモード時のパン
	* < d2.b=0-127,128
	* < d4.b=ch
	* x d0,d1
	move.b	d2,d1
	bsr	conv_p@p
	move.b	d2,adpcm_pan-work(a6)	*グローバルパラメータ
	tas.b	d1
	bpl	@f
	moveq.l	#0,d1
@@:
	move.w	#M_SET_PAN,d0
	move.b	d4,d0
	MPCM_call
	rts

single_pkon:				*単音発音
	cmpi.b	#91,d1
	bcs	@f			*音量が小さいとみなす
	tst.b	se_mode-work(a6)
	bne	@f			*se modeで演奏中ならexit
	move.w	p_frq(a5),d2		*d2.lb=p_pan(a5)  d2.hb=p_frq(a5)
	bsr	conv_p@p		*0-127→1-3
	move.w	d2,d1			*d1=frq/pan
	move.l	adt_size(a1),d2
	move.l	adt_addr(a1),a1
	bra	adpcmout

pcm_key_off:
	* < d0.w=ch
pkof_patch0:				*パッチがあたる(bra single_pkof)
	or.w	#M_KEY_OFF,d0
	MPCM_call
@@:
	rts

single_pkof:
	tst.b	se_mode-work(a6)
	bne	@b
	bra	adpcm_end

pcm_key_on:
	* < d4.w=ch
	* < d1.b=vol
	* < d2.l=pitch
	* < a1.l=data table address
	* X d0,d1
pkon_patch0:			*パッチがあたる(bra single_pkon)
*	move.w	#M_SET_VOL,d0
*	move.b	d4,d0
*	bsr	debug1
*	MPCM_call		*音量設定

	moveq.l	#0,d1
	move.b	p_frq(a5),d1
	bsr	frq_mpcm

	move.b	p_pan(a5),d1
	tas.b	d1
	bpl	@f
	moveq.l	#0,d1
@@:
	move.w	#M_SET_PAN,d0
	move.b	d4,d0
	MPCM_call

	moveq.l	#0,d1		*table type
	move.w	#M_SET_PCM,d0
	move.b	d4,d0
	MPCM_call		*データ登録

	move.l	d2,d1
	move.w	#M_SET_PITCH,d0
	move.b	d4,d0
	MPCM_call
datatype_mpcm_patch:		*V2互換モードではパッチ(NOP)
	bra.s	2f
	move.b	p_frq(a5),d0	*8bitPCMや16bitPCMにデータタイプを変更する
	cmpi.b	#5,d0		*16bitPCM
	bne	@f
	moveq.l	#1,d1
	bra	1f
@@:
	cmpi.b	#6,d0		*8bitPCM
	bne	2f
	moveq.l	#2,d1
1:
	move.w	#M_CHG_PCMKIND,d0
	move.b	d4,d0
	MPCM_call
2:
	move.l	d4,d0
	MPCM_call		*発音
	rts

set_ad_tune:			*音程設定 (パッチが当たる(RTS))
	* < d1.b=midi note number
	* < d4.w=ch
	* < d5.w=tune
	andi.w	#$7f,d1		*最上位ビットを殺す
	move.l	pcm_tune_tbl-work(a6),d0
	beq	@f
	move.l	d0,a1
	move.b	(a1,d1.w),d0
	ext.w	d0
@@:
	lsl.w	#6,d1		*64倍
	add.w	d0,d1
	add.w	p_detune(a5),d1
	add.w	d5,d1		*d1.w=pitch
	move.w	#M_SET_PITCH,d0
	move.b	d4,d0
	MPCM_call
	rts
*----------------------------------------
*    X68k ADPCM PUTI NOISE ELIMINATOR
*
*		ＸＡＰＮＥＬ
*
*	 Programmed by Z.Nishikawa
*----------------------------------------
DMADSTAT:	equ	$c32
OPMCTRL:	equ	$9da
*	以下'XAPNEL.X'のルーチンの流用です

adpcmout:			*IOCS	$60
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	movem.l	d1-d2/a0-a2,-(sp)
	bsr	adpcm_end
	lea	OCR3,a0
	lea	last_param(pc),a2
	move.w	d1,(a2)+
	move.l	a1,(a2)+
	move.l	d2,(a2)+
	clr.w	(a2)

	moveq.l	#0,d0

	cmpi.l	#$feff,d2
	bls	adpcm_sgl	*$feff以下なら単回処理(<d0.l=0)

	move.l	d2,d0
	move.l	#$feff,d2
	divu	d2,d0
	swap	d0
	tst.w	d0
	beq	@f
	swap	d0
	bra	store_lpc
@@:
	swap	d0
	subq.w	#1,d0
store_lpc:
	move.w	d0,(a2)		*d0回数
	sub.l	d2,-4(a2)	*size補正
	moveq.l	#$80,d0		*ループ指定
adpcm_sgl:
	* a0=OCR3,a2=last_feff

	addq.b	#%0000_0010,d0	*play指定
	move.b	d0,DMADSTAT.w
	move.b	#%0111_1010,(a0)	*aray mode
	st	CSR3-OCR3(a0)		*status set
	move.w	#2,BTC3-OCR3(a0)	*アレイテーブルの個数
	lea	aray_tbl(pc),a2
	move.l	a2,BAR3-OCR3(a0)	*アレイテーブルのアドレス
	move.l	a1,next_at-aray_tbl(a2)
	move.w	d2,next_at+4-aray_tbl(a2)
	bsr	adpcm_dtst
	move.b	#$02,$e92001
	moveq.l	#0,d0
	movem.l	(sp)+,d1-d2/a0-a2
	move.w	(sp)+,sr
	rts

adpcm_dtst:
	* X d0,d1,a1
	move.w	d1,d0
	andi.w	#$8080,d0
	bne	2f		*両方省略
	bmi	skip_frq_ope
	move.b	OPMCTRL.w,d0	*音声合成クロック読みだし
	tas.b	d0
	cmpi.w	#$06_00,d1	*31.2kHz?
	bcc	1f
	cmpi.w	#$05_00,d1	*20.8kHz?
	bcc	2f
	cmpi.w	#$02_00,d1
	bcs	@f		*5.2kHzならばクロック4MHz
	sub.w	#$02_00,d1
	andi.b	#$7f,d0		*7.8kHzならばクロック8MHz
	bra	@f
1:
	move.w	#$03_00,d1
	andi.b	#$7f,d0
	bra	@f
2:
	move.w	#$03_00,d1
@@:
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	move.b	d0,OPMCTRL.w
	opmset	#$1b,d0		*クロックを書き込む
	lea	work,a1
	move.b	d0,$1b+opmreg(a1)
	move.w	(sp)+,sr
	move.w	d1,d0
	andi.b	#%1000_0011,d0
	bmi	skip_pan_ope	*パン省略
	beq	@f

	cmpi.b	#3,d0		*出力チェック
	bne	1f
@@:
	eori.b	#%0000_0011,d0	*ビット反転
1:
	lsr.w	#6,d1		*サンプリング周波数を下位バイトへ
	andi.b	#%0000_1100,d1
	or.b	d0,d1		*出力モードを重ね合わせる
	move.b	$e9a005,d0	*周波数やパンをゲット
	andi.b	#%1111_0000,d0
	or.b	d1,d0		*設定値を作成
	move.b	d0,$e9a005	*コントロールデータ送信
2:
	move.b	#$88,CCR3-OCR3(a0)	*dma start
	rts

skip_frq_ope:			*周波数設定省略ケース
	move.w	d1,d0
	andi.b	#%0000_0011,d0
	beq	@f

	cmpi.b	#3,d0		*出力チェック
	bne	1f
@@:
	eori.b	#%0000_0011,d0	*ビット反転
1:				* < d0.b=pan
	move.b	$e9a005,d1	*周波数やパンをゲット
	andi.b	#%1111_1100,d1	*パンポット以外を保存
	or.b	d1,d0		*パンポット値を重ねる
	move.b	d0,$e9a005	*コントロールデータ送信
	move.b	#$88,CCR3-OCR3(a0)	*dma start
	rts

skip_pan_ope:			*パンポット省略ケース
	lsr.w	#6,d1		*サンプリング周波数を下位バイトへ
	andi.b	#%0000_1100,d1
	move.b	$e9a005,d0	*周波数やパンをゲット
	andi.b	#%1111_0011,d0
	or.b	d1,d0		*周波数値を重ねる
	move.b	d0,$e9a005	*コントロールデータ送信
	move.b	#$88,CCR3-OCR3(a0)	*dma start
	rts

adpcmmod:			*IOCS	$67
	tst.b	d1
	beq	adpcm_end
	cmpi.b	#1,d1
	beq	adpcm_stop
	cmpi.b	#2,d1
	beq	adpcm_cnt
	moveq.l	#-1,d0	*エラーコード
	rts
adpcm_end:
	tst.b	se_mode
	bne	@f
	moveq.l	#0,d0		*終了コード
	move.w	sr,-(sp)
	ori.w	#$0700,sr	*最上位割り込みマスク
	move.b	#$10,CCR3
	move.b	#$88,$e92003
	move.w	d0,DMADSTAT.w
	move.w	(sp)+,sr
@@:
	rts
adpcm_stop:
	moveq.l	#0,d0
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	move.b	d0,se_mode
	move.b	#$20,CCR3	*動作中断
				*move.b	#$88,$e92003をしないのは再開した時に音が変に鳴るから
	move.w	(sp)+,sr
	rts
adpcm_cnt:
	move.b	#$08,CCR3	*動作継続
	moveq.l	#0,d0
	rts

int_adpcm_stop:			*ＡＤＰＣＭデータの再生が終了するとここへくる
	ori.w	#$0700,sr
	movem.l	d0-d2/a0-a1,-(sp)
	lea	last_feff(pc),a0
	tst.w	(a0)
	beq	stop_quit
	subq.w	#1,(a0)
	move.l	#$feff,d1
	move.l	-(a0),d0	*get size
	move.l	d0,d2
	sub.l	d1,d0
	bcs	@f
	sub.l	d1,(a0)		*size=size-$feff
	move.l	d1,d2
@@:
	add.l	d1,-(a0)
	move.l	(a0),a1		*get address
	move.w	-(a0),d1	*get param

	lea	OCR3,a0
	move.b	#%0000_0010,DMADSTAT.w
	move.b	#%0111_0010,(a0)	*no aray
	st	CSR3-OCR3(a0)		*status set
	move.l	a1,MAR3-OCR3(a0)
	move.w	d2,MTC3-OCR3(a0)
	bsr	adpcm_dtst
	move.b	#$02,$e92001

	movem.l	(sp)+,d0-d2/a0-a1
	rte

stop_quit:
	move.b	#$10,CCR3	*dma stop
	st	CSR3		*status clear
	move.b	#$88,$e92003
	moveq.l	#0,d0
	move.b	d0,DMADSTAT.w
	move.b	d0,se_mode
	movem.l	(sp)+,d0-d2/a0-a1
	rte

aray_tbl:
	dc.l	dummy_data
	dc.w	num_of_80
next_at:
	dc.l	0
	dc.w	0
dummy_data:	dcb.b	num_of_80,$80
	.even
last_param:	ds.w	1
last_address:	ds.l	1
last_size:	ds.l	1
last_feff:	dc.w	0
	.even

	if	(debug.and.1)
debug2:				*デバグ用ルーチン(レジスタ値を表示／割り込み対応)
	move.w	sr,db_work2	*save sr
	ori.w	#$700,sr	*mask int
	movem.l	d0-d7/a0-a7,db_work

	moveq.l	#%0011,d1
	IOCS	_B_COLOR

	lea	str__(pc),a1

	move.w	#$0d0a,(a1)+

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

	moveq.l	#0,d0
	move.w	db_work2(pc),d0		*SR
	bsr	_get_hex32
	addq.w	#8,a1
	move.b	#' ',(a1)+
	move.l	(a7),d0			*PC
	bsr	_get_hex32
	addq.w	#8,a1
	clr.b	(a1)+
	lea	str__(pc),a1
	IOCS	_B_PRINT
*@@:
*	btst.b	#5,$806.w
*	bne	@b

	movem.l	db_work(pc),d0-d7/a0-a7
	move.w	db_work2(pc),sr	*get back sr
	rts

debug1:
	move.w	sr,-(sp)
	move.l	a6,-(sp)
	move.l	tad(pc),a6
	move.b	d1,(a6)+
	move.l	a6,tad
	move.l	(sp)+,a6
	move.w	(sp)+,sr
@@:
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
	bls	@f
	addq.b	#7,d1
@@:
	move.b	d1,-(a1)
	lsr.l	#4,d0
	dbra	d4,_gh_lp32
	movem.l	(sp)+,d0-d1/d4/a1
	rts

		*デバッグ用ワーク
	.even
str__:		ds.b	96*2
		dc.b	'REGI'
db_work:	dcb.l	16,0		*for debug
db_work2:	dc.l	0
tad:		dc.l	$e40000

	endif
