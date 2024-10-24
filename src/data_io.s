*-----------------------------------------------------------------------------
*	ZMUSIC V3
*	DATA I/O部ソース
*-----------------------------------------------------------------------------
	.align	4
*test:					*ここを非コメント化すると負荷に応じで画面フラッシュ
m_out_entry:				*MIDI送信割り込み(CZ6BM1-0)
	ori.w	#$0700,sr
	movem.l	d0/a0-a1,-(sp)
	lea	rgr,a0
	move.b	#%0100_0000,icr-rgr(a0)	*割り込みクリア
	midiwait
	move.l	m_buffer_0(pc),a1
	move.w	m_buffer_ip(a1),d0
	move.b	#$05,(a0)
	midiwait
@@:
	move.b	m_buffer(a1,d0.w),grp6-rgr(a0)
	midiwait
	addq.w	#1,d0
	andi.w	#mbufsz-1,d0
	subq.w	#1,m_len(a1)
	beq	@f			*全部送信終了
	btst.b	#6,grp4-rgr(a0)
	bne	@b			*まだ書き込める
	move.w	d0,m_buffer_ip(a1)
	ifdef test
	move.w	#%00000_00000_11111_0,$e82200	*!!!
	endif
	movem.l	(sp)+,d0/a0-a1
	rte
@@:					*割り込みひとまず終了
	clr.b	(a0)
	midiwait
	lea	r06_0(pc),a1
	andi.b	#%1011_1111,(a1)
	move.b	(a1),grp6-rgr(a0)
	midiwait
	ifdef test
	clr.w	$e82200				*!!!
	endif
	movem.l	(sp)+,d0/a0-a1
	rte

m_out_entry2:				*MIDI送信割り込み(CZ6BM1-1)
	ori.w	#$0700,sr
	movem.l	d0/a0-a1,-(sp)
	lea	rgr+$10,a0
	move.b	#%0100_0000,icr-rgr(a0)	*割り込みクリア
	midiwait
	move.l	m_buffer_1(pc),a1
	move.w	m_buffer_ip(a1),d0
	move.b	#$05,(a0)
	midiwait
@@:
	move.b	m_buffer(a1,d0.w),grp6-rgr(a0)
	midiwait
	addq.w	#1,d0
	andi.w	#mbufsz-1,d0
	subq.w	#1,m_len(a1)
	beq	@f			*全部送信終了
	btst.b	#6,grp4-rgr(a0)
	bne	@b			*まだ書き込める
	move.w	d0,m_buffer_ip(a1)
	ifdef test
	move.w	#%00000_11111_00000_0,$e82200	*!!!
	endif
	movem.l	(sp)+,d0/a0-a1
	rte
@@:					*割り込みひとまず終了
	clr.b	(a0)
	midiwait
	lea	r06_1(pc),a1
	andi.b	#%1011_1111,(a1)
	move.b	(a1),grp6-rgr(a0)
	midiwait
	ifdef test
	clr.w	$e82200				*!!!
	endif
	movem.l	(sp)+,d0/a0-a1
	rte

m_out_entry_r:				*RS-MIDI送信割り込み
	ori.w	#$0700,sr
	movem.l	d0/a0-a1,-(sp)
	lea	scc_a,a0
	move.l	m_buffer_r(pc),a1
	tst.w	m_len(a1)
	beq	@f
	ifdef test
	move.w	#%11111_00000_00000_0,$e82200	*!!!
	endif
	move.w	m_buffer_ip(a1),d0
	move.b	m_buffer(a1,d0.w),2(a0)
	addq.w	#1,d0
	andi.w	#mbufsz-1,d0
	move.w	d0,m_buffer_ip(a1)
	subq.w	#1,m_len(a1)
	bne	exit_moer		*全部送信終了
@@:
	ifdef test
	clr.w	$e82200			*!!!
	endif
	tst.b	(a0)			*!!!Dummy
	move.b	#$28,(a0)		*割り込みクリア
exit_moer:
	move.b	#$38,(a0)		*割り込みクリア
	movem.l	(sp)+,d0/a0-a1
	rte

_m_out_m0:				*CZ6BM1-0
	jmp	@f.l
@@:
	cmpi.b	#$f7,d0
	bne	m_out_m0
	clr.b	stat0-work(a6)		*clear status byte
	move.w	sr,-(sp)
	andi.w	#$f8ff,sr		*all int. enable
@@:
	btst.b	#6,r06_0(pc)		*割り込みモードか
	bne	@b			*yes
	ori.w	#$0700,sr
	lea	rgr,a4
	move.b	#5,(a4)
	midiwait
@@:
	btst.b	#6,grp4-rgr(a4)
	beq	@b
	move.b	d0,grp6-rgr(a4)
	midiwait
	move.w	(sp)+,sr
					*EOX後のウェイト
	move.w	d2,-(sp)
	move.w	eox_w+0(pc),d2
	subq.w	#1,d2
@@:
	bsr	v_wait
	dbra	d2,@b
	move.w	(sp)+,d2
	rts

_m_out_m1:				*CZ6BM1-1
	jmp	@f.l
@@:
	cmpi.b	#$f7,d0
	bne	m_out_m1
	clr.b	stat1-work(a6)		*clear status byte
	move.w	sr,-(sp)
	andi.w	#$f8ff,sr		*all int. enable
@@:
	btst.b	#6,r06_1(pc)		*割り込みモードか
	bne	@b			*yes
	ori.w	#$0700,sr
	lea	rgr+$10,a4
	move.b	#5,(a4)
	midiwait
@@:
	btst.b	#6,grp4-rgr(a4)
	beq	@b
	move.b	d0,grp6-rgr(a4)
	midiwait
	move.w	(sp)+,sr
					*EOX後のウェイト
	move.w	d2,-(sp)
	move.w	eox_w+2(pc),d2
	subq.w	#1,d2
@@:
	bsr	v_wait
	dbra	d2,@b
	move.w	(sp)+,d2
	rts

_m_out_r0:				*RS232C 0
	jmp	@f.l
@@:
	cmpi.b	#$f7,d0
	bne	m_out_r0
	clr.b	statr0-work(a6)		*clear status byte
	move.l	m_buffer_r(pc),a4
	move.w	sr,-(sp)
	andi.w	#$f8ff,sr		*all int. enable
@@:
	tst.w	m_len(a4)		*割り込みモードか
	bne	@b			*yes
	ori.w	#$0700,sr
	lea	scc_a,a4
	tst.b	(a4)			*!!!Dummy
@@:
	btst.b	#2,(a4)
	beq	@b
*	move.w	(sp)+,sr		*03/10
	move.b	d0,2(a4)
					*EOX後のウェイト
	move.w	d2,-(sp)
	move.w	eox_w+4(pc),d2
	subq.w	#1,d2
@@:
	bsr	v_wait
	dbra	d2,@b
	move.w	(sp)+,d2
	move.w	(sp)+,sr		*03/20
	rts

_m_out_r1:				*RS232C
	jmp	@f.l
@@:
	cmpi.b	#$f7,d0
	bne	m_out_r1
	clr.b	statr1-work(a6)		*clear status byte
	move.l	m_buffer_r(pc),a4
	move.w	sr,-(sp)
	andi.w	#$f8ff,sr		*all int. enable
@@:
	tst.w	m_len(a4)		*割り込みモードか
	bne	@b			*yes
	ori.w	#$0700,sr
	lea	scc_a,a4
	tst.b	(a4)			*!!!Dummy
@@:
	btst.b	#2,(a4)
	beq	@b
*	move.w	(sp)+,sr		*03/10
	move.b	d0,2(a4)
					*EOX後のウェイト
	move.w	d2,-(sp)
	move.w	eox_w+6(pc),d2
	subq.w	#1,d2
@@:
	bsr	v_wait
	dbra	d2,@b
	move.w	(sp)+,d2
	move.w	(sp)+,sr		*03/20
	rts

_m_out:					*nmdb!(RTS)
	bra.w	_m_out_m0		*eox_wが0ならぱ(bra.w m_out_xx)

m_out_m0:				*CZ6BM1-0 MIDI送信
	* < d0.b=data
	* X a4
	jmp	m_out_m0_patch.l	*MIDI出力ルーチンのパッチ時に使われる
m_out_m0_patch:
	tst.b	d0			*ARS
	bpl	exit_ars0_
	cmpi.b	#$f8,d0
	bcc	exit_ars0_
	cmpi.b	#$f0,d0
	bcs	@f
	clr.b	stat0-work(a6)		*clear status byte
	bra	exit_ars0_
@@:
	cmp.b	stat0(pc),d0		*オートマチックランニングステータス機能(ARS)
	beq	2f
	move.b	d0,stat0-work(a6)	*save status byte
exit_ars0_:
	move.l	m_buffer_0(pc),a4
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	btst.b	#6,r06_0(pc)		*割り込みモードか
	bne	set_mb			*yes
	*ダイレクト
	move.b	#$05,rgr
	midiwait
	btst.b	#6,grp4
	beq	@f			*ハード・バッファフル
	move.b	d0,grp6
	midiwait
	move.w	(sp)+,sr
2:
	rts
@@:					*割り込み送信準備
	move.w	d1,-(sp)
	move.w	m_buffer_sp(a4),d1
	move.w	d1,m_buffer_ip(a4)
	move.w	#1,m_len(a4)
	move.b	d0,m_buffer(a4,d1.w)
	addq.w	#1,d1
	andi.w	#mbufsz-1,d1
	move.w	d1,m_buffer_sp(a4)
	lea	r06_0(pc),a4
	ori.b	#%0100_0000,(a4)
	clr.b	rgr
	midiwait
	move.b	(a4),grp6
	midiwait
	move.w	(sp)+,d1
	move.w	(sp)+,sr
	rts
set_mb:					*ソフトバッファへの書き込み
	cmp.w	#mbufsz,m_len(a4)	*ソフト・バッファ・フルかどうか
	bne	@f
	andi.w	#$f8ff,sr		*all int. enable
smlp0:
	cmp.w	#mbufsz,m_len(a4)	*ソフト・バッファ・フルかどうか
	beq	smlp0
	ori.w	#$0700,sr
@@:
	move.w	d1,-(sp)
	move.w	m_buffer_sp(a4),d1
	move.b	d0,m_buffer(a4,d1.w)
	addq.w	#1,d1
	andi.w	#mbufsz-1,d1
	move.w	d1,m_buffer_sp(a4)
	addq.w	#1,m_len(a4)
	move.w	(sp)+,d1
	move.w	(sp)+,sr
	rts

m_out_m1:				*CZ6BM1-1 MIDI送信
	* < d0.b=data
	* X a4
	jmp	m_out_m1_patch.l	*MIDI出力ルーチンのパッチ時に使われる
m_out_m1_patch:
	tst.b	d0			*ARS
	bpl	exit_ars1_
	cmpi.b	#$f8,d0
	bcc	exit_ars1_
	cmpi.b	#$f0,d0
	bcs	@f
	clr.b	stat1-work(a6)		*clear status byte
	bra	exit_ars1_
@@:
	cmp.b	stat1(pc),d0		*オートマチックランニングステータス機能(ARS)
	beq	2f
	move.b	d0,stat1-work(a6)	*save status byte
exit_ars1_:
	move.l	m_buffer_1(pc),a4
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	btst.b	#6,r06_1(pc)		*割り込みモードか
	bne	set_mb			*yes
	*ダイレクト
	move.b	#$05,rgr+$10
	midiwait
	btst.b	#6,grp4+$10
	beq	@f			*ハード・バッファフル
	move.b	d0,grp6+$10
	midiwait
	move.w	(sp)+,sr
2:
	rts
@@:					*割り込み送信準備
	move.w	d1,-(sp)
	move.w	m_buffer_sp(a4),d1
	move.w	d1,m_buffer_ip(a4)
	move.w	#1,m_len(a4)
	move.b	d0,m_buffer(a4,d1.w)
	addq.w	#1,d1
	andi.w	#mbufsz-1,d1
	move.w	d1,m_buffer_sp(a4)
	lea	r06_1(pc),a4
	ori.b	#%0100_0000,(a4)
	clr.b	rgr+$10
	midiwait
	move.b	(a4),grp6+$10
	midiwait
	move.w	(sp)+,d1
	move.w	(sp)+,sr
	rts

m_out_r0:				*RS-MIDI送信 0
	* < d0.b=data
	jmp	@f.l				*MIDI出力ルーチンのパッチ時に使われる
@@:
	tst.b	current_rs232c_part-work(a6)	*0?
	beq	@f
	swap	d0
	move.w	#$f5,d0
	bsr	@f
	move.w	#$01,d0
	bsr	@f
	swap	d0
	clr.b	current_rs232c_part-work(a6)
@@:
m_out_r0_patch:
	tst.b	d0			*ARS
	bpl	exit_arsr0_
	cmpi.b	#$f8,d0
	bcc	exit_arsr0_
	cmpi.b	#$f0,d0
	bcs	@f
	clr.b	statr0-work(a6)		*clear status byte
	bra	exit_arsr0_
@@:
	cmp.b	statr0(pc),d0		*オートマチックランニングステータス機能(ARS)
	beq	2f
	move.b	d0,statr0-work(a6)	*save status byte
exit_arsr0_:
	move.l	m_buffer_r(pc),a4
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	*ダイレクト
	tst.w	m_len(a4)
	bne	set_mb			*ソフトバッファへ
	tst.b	scc_a			*!!!Dummy
	btst.b	#2,scc_a
	beq	set_mb			*ソフトバッファへ
	move.w	(sp)+,sr
	move.b	d0,scc_a+2		*出力
2:
	rts

m_out_r1:				*RS-MIDI送信 1
	* < d0.b=data
	jmp	@f.l				*MIDI出力ルーチンのパッチ時に使われる
@@:
	tst.b	current_rs232c_part-work(a6)	*-1?
	bmi	@f
	swap	d0
	move.w	#$f5,d0
	bsr	@f
	move.w	#$02,d0
	bsr	@f
	swap	d0
	st.b	current_rs232c_part-work(a6)
@@:
m_out_r1_patch:
	tst.b	d0			*ARS
	bpl	exit_arsr1_
	cmpi.b	#$f8,d0
	bcc	exit_arsr1_
	cmpi.b	#$f0,d0
	bcs	@f
	clr.b	statr1-work(a6)		*clear status byte
	bra	exit_arsr1_
@@:
	cmp.b	statr1(pc),d0		*オートマチックランニングステータス機能(ARS)
	beq	2f
	move.b	d0,statr1-work(a6)	*save status byte
exit_arsr1_:
	move.l	m_buffer_r(pc),a4
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	*ダイレクト
	tst.w	m_len(a4)
	bne	set_mb			*ソフトバッファへ
	tst.b	scc_a			*!!!Dummy
	btst.b	#2,scc_a
	beq	set_mb			*ソフトバッファへ
	move.w	(sp)+,sr
	move.b	d0,scc_a+2		*出力
2:
	rts
					*チャンネルワークおよびARSを使用しないならば
					*各MIDI転送ルーチンの先頭のbsr midi_map_?を
					*殺す
midi_map	macro	xx,mmX_adr
	* < d0.b=data
	* > minus:no send
	movem.l	d0-d1,-(sp)
	move.b	d0,d1
	bpl	data_byte_&xx
	cmpi.b	#$f8,d0			*system realtime message
	bcc	exit_mm&xx
	cmpi.b	#$f0,d0			*system common & EXC (ステータスクリア)
	bcc	stcl_mm&xx
	cmp.b	stat&xx(pc),d0		*オートマチックランニングステータス機能(ARS)
	beq	no_send&xx
	move.b	d0,stat&xx-work(a6)	*save status byte
	move.b	#2,order&xx-work(a6)	*data byte counter初期化
exit_mm&xx:
	moveq.l	#0,d0
	movem.l	(sp)+,d0-d1
	rts

send_mm&xx:				*必ず送信
	moveq.l	#0,d0
	movem.l	(sp)+,d0-d1
	rts

stcl_mm&xx:				*status clear case and send.(いかなる時も送信)
	clr.b	stat&xx-work(a6)
	movem.l	(sp)+,d0-d1
	rts

no_send&xx:				*送信処理省略
	moveq.l	#-1,d0
	movem.l	(sp)+,d0-d1
	rts

*case_ch_mask_midi&xx:			*MIDIのチャンネルマスク実行時
*	move.b	stat&xx(pc),d0
*	andi.b	#$0f,d0
*	move.w	mask_midi_ch&xx(pc),d1
*	btst.l	d0,d1
*	beq	send_mm&xx
*	moveq.l	#-1,d0			*送信処理省略
*	movem.l	(sp)+,d0-d1
*	rts

data_byte_&xx:
	*以下はチャンネルワークモード
	move.b	stat&xx(pc),d1
	beq	send_mm&xx
					*ctrl change
	cmpi.b	#$af,d1
	bls	exit_mm&xx		*素通り(note on/off, polyphonic pressure)
	cmpi.b	#$bf,d1
	bhi	_cf_&xx
	subq.b	#1,order&xx-work(a6)	*何番目のデータか
	bne	@f
	andi.w	#$0f,d1
	add.w	d1,d1
	move.w	chwkvn_&xx(pc,d1.w),a4
	adda.l	mmX_adr(pc),a4
	move.b	#2,order&xx-work(a6)	*データ順列パラメータ初期化
	move.w	ctrl_n&xx(pc),d1		*ctrl number
	move.b	d0,__b0(a4,d1.w)
	bra	exit_mm&xx
@@:
	move.b	d0,ctrl_n&xx+1-work(a6)
	bra	exit_mm&xx
_cf_&xx:					*program change
	cmpi.b	#$cf,d1
	bhi	_df_&xx
	andi.w	#$0f,d1
	add.w	d1,d1
	move.w	chwkvn_&xx(pc,d1.w),a4
	adda.l	mmX_adr(pc),a4
	move.b	d0,__c0(a4)
	bra	exit_mm&xx
chwkvn_&xx:
	dc.w	chwklen*0,chwklen*1,chwklen*2,chwklen*3
	dc.w	chwklen*4,chwklen*5,chwklen*6,chwklen*7
	dc.w	chwklen*8,chwklen*9,chwklen*10,chwklen*11
	dc.w	chwklen*12,chwklen*13,chwklen*14,chwklen*15
_df_&xx:					*channel pressure
	cmpi.b	#$df,d1
	bhi	_ef_&xx
	andi.w	#$0f,d1
	add.w	d1,d1
	move.w	chwkvn_&xx(pc,d1.w),a4
	adda.l	mmX_adr(pc),a4
	move.b	d0,__d0(a4)
	bra	exit_mm&xx
_ef_&xx:					*pitch bender
	*status xが$ef以上になることはない
	andi.w	#$0f,d1
	add.w	d1,d1
	move.w	chwkvn_&xx(pc,d1.w),a4
	adda.l	mmX_adr(pc),a4
	subq.b	#1,order&xx-work(a6)	*何番目のデータか
	bne	@f
	subq.w	#1,a4
	move.b	#2,order&xx-work(a6)	*データ順列パラメータ初期化
@@:
	move.b	d0,__e0+1(a4)		*わざと+1
	bra	exit_mm&xx
	endm

midi_map_0:	midi_map	0,mm0_adr
midi_map_1:	midi_map	1,mm1_adr
midi_map_r0:	midi_map	r0,mmr0_adr
midi_map_r1:	midi_map	r1,mmr1_adr

opmset:
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	opmset	d1,d2
	bsr	case_special_opmset
opmset_patch1:				*FMマップ省略時bra exit_opmset
	andi.w	#$ff,d1
	move.b	d2,opmreg(a6,d1.w)
exit_opmset:
	move.w	(sp)+,sr
	rts

opmset_se:				*効果音モード時のOPM書き込み
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	cmpi.b	#$20,d1			*グローバルレジスタ系は書き込む
	bcs	@f
	btst.b	d1,mask_opm_ch-work(a6)	*効果音で使用しているチャンネルか
	beq	_os0
	bra	wkst_os			*効果音で使用中のチャンネルの場合
@@:
	cmpi.b	#$08,d1			*キーオン、オフ関係か
	bne	@f
	btst.b	d2,mask_opm_ch-work(a6)	*効果音で使用しているチャンネルか(わざとd2)
	beq	_os0
	bra	wkst_os
@@:
	cmpi.b	#$0f,d1			*noise set
	beq	wkst_os
_os0:
	opmset	d1,d2
	bsr	case_special_opmset
wkst_os:
	andi.w	#$ff,d1
	move.b	d2,opmreg(a6,d1.w)
	move.w	(sp)+,sr
	rts

case_special_opmset:			*特殊処理レジスタ群
	cmpi.b	#$1b,d1			*$1cより上は対象外
	bhi	exit_cso
	bne	@f
	move.b	d2,OPMCTRL.w		*ＯＳのワークへもセットする
exit_cso:
	rts
@@:
	cmpi.b	#$08,d1			*KEY ON/OFF
	bne	@f
	move.w	d0,-(sp)
	move.l	d2,d0
	andi.w	#7,d0
	move.b	d2,opm_kon-work(a6,d0.w)
	move.w	(sp)+,d0
	rts
@@:					*PMD
	cmpi.b	#$19,d1
	bne	@f
	tst.b	d2
	bpl	@f
	move.b	d2,opm_pmd-work(a6)
@@:
	rts

restore_af:
restore_opm:				*効果音トラック終了時の処理
	* < d4.w=opm ch(0-7)
	* - all
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	movem.l	d0-d1,-(sp)
	moveq.l	#$20,d0
	add.b	d4,d0
	moveq.l	#28-1,d1
@@:
	opmset	d0,<opmreg(a6,d0.w)>
	addq.b	#8,d0
	dbra	d1,@b
	opmset	#$0f,<opmreg+$0f(a6)>	*noise
	movem.l	(sp)+,d0-d1
	move.w	(sp)+,sr
	rts

*restore_af:				*マスクトラックの復元
*	* < d4.w=opm ch(0-7)
*	* x d0
*	move.w	sr,-(sp)
*	ori.w	#$0700,sr
*	moveq.l	#$20,d0
*	add.b	d4,d0
*	opmset	d0,<opmreg(a6,d0.w)>
*	move.w	(sp)+,sr
*	rts

copy_opm_timbre:			*他チャンネルの音色をコピーする
	* < d1.b=実行ch
	* < d5.b=copy元ch
	* x d0-d2,a2
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	move.b	ol1-work(a6,d5.w),ol1-work(a6,d1.w)
	move.b	ol2-work(a6,d5.w),ol2-work(a6,d1.w)
	move.b	ol3-work(a6,d5.w),ol3-work(a6,d1.w)
	move.b	ol4-work(a6,d5.w),ol4-work(a6,d1.w)
	move.b	opm_nom-work(a6,d5.w),opm_nom-work(a6,d1.w)
	move.b	cf-work(a6,d5.w),cf-work(a6,d1.w)

	move.l	d1,d0
*init_rr:			*音色切り換え時にプチといわせない処理
	moveq.l	#$e0,d1
	add.b	d0,d1
	moveq.l	#$ff,d2
	opmset	d1,d2
	addq.b	#8,d1
	opmset	d1,d2
	addq.b	#8,d1
	opmset	d1,d2
	addq.b	#8,d1
	opmset	d1,d2

	lea	opmreg+$20(a6,d5.w),a2	*source addr.
	moveq.l	#$20,d1
	add.b	d0,d1
	move.b	(a2),d2
	bsr	opmset

	add.b	#$18,d1
	lea	$18(a2),a2
	moveq.l	#25-1,d0
@@:
	move.b	(a2),d2
	bsr	opmset
	addq.w	#8,d1
	addq.w	#8,a2
	dbra	d0,@b
	move.w	(sp)+,sr
	rts

di_tmf	macro
	andi.b	#$f7,$00e88015	*MFP FM_int off
	endm

ei_tmf	macro
	ori.b	#$08,$00e88015	*MFP FM_int ON
	endm

stop_tm_int_se:
di_tmf:
	di_tmf
	rts

start_tm_int_se:
ei_tmf:
	ei_tmf
	rts

di_tmm	macro
	move.b	#$80,icr
	midiwait
	clr.b	rgr
	midiwait
	andi.b	#$7f,r06_0-work(a6)
	move.b	r06_0(pc),grp6
	midiwait
	endm

ei_tmm	macro
	clr.b	rgr
	midiwait
	tas.b	r06_0-work(a6)
	move.b	r06_0(pc),grp6
	midiwait
	endm

stop_tm_int_ms:			*タイマによってパッチが当たる
	di_tmm
	rts

start_tm_int_ms:		*タイマによってパッチが当たる
	ei_tmm
	rts

di_tme	macro
	move.b	#$04,icr
	midiwait
	clr.b	rgr
	midiwait
	bclr.b	#2,r06_0-work(a6)
	move.b	r06_0(pc),grp6
	midiwait
	endm

ei_tme	macro
	move.b	#$07,rgr
	midiwait

	move.b	itpl_rate-work(a6),grp5
	midiwait
	clr.b	rgr
	midiwait
	bset.b	#2,r06_0-work(a6)
	move.b	r06_0(pc),grp6
	midiwait
	endm

di_tme:
	di_tme
	rts

ei_tme:
	ei_tme
	rts

int_rm_ope:			*リアルタイムメッセージ受信処理
reglist	reg	d0-d7/a0-a6
	movem.l	reglist,-(sp)
	lea	work(pc),a6
	move.b	#$01,icr		*int clr
	midiwait
iro_lp:
	move.b	#$01,rgr
	midiwait
	move.b	grp6,d0			*read R16($F8～$FF)
	beq	exit_iro		*d0=0のときはバッファ空
	cmpi.b	#$fa,d0
	beq	iro_start
	move.b	d0,grp5			*R15へ出力
	midiwait
	move.b	#$01,grp7		*FIFO-IRx更新(R17)
	midiwait
	cmpi.b	#$fb,d0
	beq	iro_cont
	cmpi.b	#$fc,d0
	bne	iro_lp
iro_stop:
	jbsr	m_stop_all
	bra	iro_lp

iro_start:
	tas	start_wait_flg-work(a6)
	bpl	@f
	jbsr	m_play_all
	move.b	#$01,rgr
	midiwait
@@:
	move.b	#$FA,grp5		*R15へ出力
	midiwait
	move.b	#$01,grp7		*FIFO-IRx更新(R17)
	midiwait
	bra	iro_lp

iro_cont:
	jbsr	m_cont_all
	bra	iro_lp
exit_iro:
	movem.l	(sp)+,reglist
	rte			*割り込み処理終了

opmwait:
@@:
	tst.b	fm_data_port	*busy check
	nop
	bmi	@b
midiwait:
	tst.b	$e9a001	*ダミー
	nop		*040への対応の意味を含めて(アドバイスありがとう)
	rts		*NOPはパイプラインを崩して本当にウェイトを与える目的で行っている

v_wait:
@@:
	btst.b	#4,$e88001
	beq	@b
@@:
	btst.b	#4,$e88001
	bne	@b
	rts

h_wait:				*単なるウェイト
	* < d0.w=loop counter	*d0*(1/60/512)秒のウェイト
hsy_lp01:
	tst.b	$e88001
	bpl	hsy_lp01
hsy_lp02:
	tst.b	$e88001
	bmi	hsy_lp02
	dbra	d0,hsy_lp01
	rts

rec_int:			*データを受信するとここへ来る (CZ6BM1 #0)
reglist	reg	d0-d2/a0/a2
	ori.w	#$0700,sr
	movem.l	reglist,-(sp)
	lea	rgr,a2
	move.l	rec_buffer_0(pc),a0
ri0:
	move.w	rec_read_ptr(a0),d1
	move.w	rec_write_ptr(a0),d2
	move.b	#$03,(a2)
					midiwait
@@:
	tst.b	grp4-rgr(a2)
	bpl	@f
	move.b	grp6-rgr(a2),d0
					*midiwait
	cmpi.b	#$fe,d0
	beq	@b
*	cmpi.b	#$f8,d0			*MIDIクロックフィルタを有効にすれば必要無し
*	beq	@b
	move.b	d0,rec_buffer(a0,d2.w)
	st.b	rec_buf_stat(a0)	*有効データありフラグON
	addq.w	#1,d2
	andi.w	#recbufsize-1,d2
	cmp.w	d1,d2
	bne	@b
	st.b	rec_buf_err(a0)		*書き込みポインタが1周してしまった
*	bsr	play_beep		*バッファ溢れを起こしたら警告音を鳴らす(DEBUG)
	bra	@b
@@:
	move.w	d2,rec_write_ptr(a0)
	move.b	#$20,icr-rgr(a2)	*int clr
					midiwait
	movem.l	(sp)+,reglist
	rte

rec_int2:			*データを受信するとここへ来る (CZ6BM1 #1)
	ori.w	#$0700,sr
	movem.l	reglist,-(sp)
	lea	rgr+$10,a2
	move.l	rec_buffer_1(pc),a0
	bra	ri0

es_int:
	ori.w	#$0700,sr
	tst.b	scc_a		*!!!Dummy
	move.b	#$38,scc_a
	rte

sp_int:
	ori.w	#$0700,sr
	tst.b	scc_a
	move.b	#$30,scc_a
	move.b	#$38,scc_a
	rte

rec_int_r:			*データを受信するとここへ来る
	ori.w	#$0700,sr
	movem.l	reglist,-(sp)
	lea	scc_a,a2
	tst.b	(a2)		*!!!Dummy
	move.l	rec_buffer_r(pc),a0
	move.w	rec_read_ptr(a0),d1
	move.w	rec_write_ptr(a0),d2
@@:
	btst.b	#0,(a2)
	beq	@f
	move.b	2(a2),d0
	cmpi.b	#$fe,d0
	beq	@b
	cmpi.b	#$f8,d0
	beq	@b
	move.b	d0,rec_buffer(a0,d2.w)
	st.b	rec_buf_stat(a0)	*有効データありフラグON
	addq.w	#1,d2
	andi.w	#recbufsize-1,d2
	cmp.w	d1,d2
	bne	@b
	st.b	rec_buf_err(a0)		*書き込みポインタが1周してしまった
*	bsr	play_beep		*バッファ溢れを起こしたら警告音を鳴らす
	bra	@b
@@:
	move.w	d2,rec_write_ptr(a0)
	move.b	#$38,(a2)	*割り込みリセット
	movem.l	(sp)+,reglist
	rte

smf_entry:
	tst.b	smf_end_flag-work(a6)
	beq	exit_smf_entry
	tst.l	smf_delta-work(a6)
	beq	tsd_lp00
	subq.l	#1,smf_delta-work(a6)
	bne	exit_smf_entry
tsd_lp00:
	move.l	smf_running(pc),d2	*running count host
	move.l	smf_pointer(pc),a2
	move.l	smf_transfer(pc),a5
tsd_lp01:
	moveq.l	#0,d0
	move.b	(a2)+,d0		*get event
	bmi	event_head
	jsr	(a5)
	subq.l	#1,d2
	bne	tsd_lp01
get_dlt:
	bsr	getval			*delta time
	move.l	a2,smf_pointer-work(a6)
	move.l	d0,smf_delta-work(a6)
	beq	tsd_lp00
exit_smf_entry:
	rts

event_head:
	cmpi.b	#$f7,d0
	beq	smf_sysex
	cmpi.b	#$ff,d0
	beq	meta_events
	jsr	(a5)
	cmpi.b	#$f0,d0
	beq	smf_sysex
	lsr.b	#4,d0
	subq.b	#8,d0
	moveq.l	#0,d2
	move.b	minpjtbl(pc,d0.w),d2
	move.l	d2,smf_running-work(a6)
	bra	tsd_lp01
minpjtbl:			*$80,$90,$a0,$b0,$c0,$d0,$e0,$f0が
	dc.b	2,2,2,2,1,1,2,0	*それぞれ何バイトのデータバイトを取るか

smf_sysex:			*SYSEX
	bsr	getval		*get data count
	move.l	d0,d2
	beq	get_dlt
@@:
	move.b	(a2)+,d0		*get event
	jsr	(a5)
	subq.l	#1,d2
	bne	@b
	bra	get_dlt

meta_events:
	move.b	(a2)+,d0	*event type
	cmpi.b	#$2f,d0		*track end
	beq	@f
	cmpi.b	#$51,d0		*tempo
	beq	set_smf_tempo
	bsr	getval		*data length
	add.l	d0,a2
	bra	get_dlt
@@:					*終了処理
	tst.b	smf_end_flag-work(a6)
	bmi	@f
	jbsr	release_int_mode	*割り込みモードなら解除
@@:
	clr.b	smf_end_flag-work(a6)
	bra	exit_smf_entry

set_smf_tempo:
	addq.w	#1,a2		*skip 03
	moveq.l	#0,d1
	move.b	(a2)+,d1
	swap	d1
	move.b	(a2)+,d1
	lsl.w	#8,d1
	move.b	(a2)+,d1
	move.l	#60*1000*1000,d0
	bsr	wari		*1000,000/smf_tempo	(d0/d1)
	tst.b	smf_end_flag-work(a6)
	bpl	@f
	move.w	d0,d2
	lea	tempo_value(pc),a1
	jsr	smf_tempo-work(a6)
	bra	get_dlt
@@:				*割り込みモード時
	move.l	smf_mst_clk(pc),d1
	move.w	d0,d1		*d1.hw=マスタークロック/d1.lw=テンポ
	lea	-1.w,a1		*a1.l=-1:テンポ変更モード
	bsr	set_int_service
	bra	get_dlt

getval:
	* > d0.l=data
	* - all
	move.l	d1,-(sp)
	moveq.l	#0,d0
	moveq.l	#0,d1
	move.b	(a2)+,d1
	bpl	1f
@@:
	andi.b	#$7f,d1
	or.b	d1,d0
	lsl.l	#7,d0
	move.b	(a2)+,d1
	bmi	@b
1:
	or.b	d1,d0
	move.l	(sp)+,d1
	rts
