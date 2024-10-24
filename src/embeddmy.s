embed_with_dummy:				*対応している外部参照を探しだし
	* < zpd_scan(=0:scan,=$ff:no scan)	*そのファイル名を取り出す
	* < mdd_scan(=0:scan,=$ff:no scan)	取りだしの成功した外部参照はダミーで埋める
	* < a5.l=zmd address
reglist	reg	d0-d2/a2-a3/a5
	movem.l	reglist,-(sp)
	move.l	z_comn_offset(a5),d0
	lea	z_comn_offset+4(a5,d0.l),a5
	lea	zpd_scan(pc),a3
	move.w	(a3),d2
pcd_lp01:
	cmp.w	(a3),d2				*エントリ時とマークが違うということは
	bne	exit_ccd			*何等かのファイル名取得したということ
	moveq.l	#0,d0
	move.b	(a5)+,d0
	bmi	exit_ccd			*共通コマンドエンド
	move.l	cmncmdjtbl(pc,d0.w),d0
	beq	unid_error			*未定義のZMDを含んでいる
	bpl	@f
	sub.l	d0,a5
	bra	pcd_lp01
@@:
	jsr	cmncmdjtbl(pc,d0.l)
	bra	pcd_lp01
exit_ccd:
	movem.l	(sp)+,reglist
	rts

cmncmdjtbl:
	dc.l	-1				*initialize
	dc.l	juke_error-cmncmdjtbl		*read & exec. cnf file
	dc.l	0				*tempo
	dc.l	0				*全音符カウンタ/拍子セット
	dc.l	0
	dc.l	0
	dc.l	-49				*ボイスセット
	dc.l	cmn_wave_form-cmncmdjtbl	*wave form setting
	dc.l	juke_error-cmncmdjtbl		*adpcm data cnf
	dc.l	-2				*erase adpcm
	dc.l	cmn_block_adpcm-cmncmdjtbl	*read a block data
	dc.l	-1				*current midi in
	dc.l	-1				*current midi out
	dc.l	cmn_midi_trans-cmncmdjtbl	*MIDI生データ転送
	dc.l	cmn_midi_dump-cmncmdjtbl	*trans midi data dump
	dc.l	0				*
	dc.l	cmn_comment-cmncmdjtbl		*comment
	dc.l	cmn_print-cmncmdjtbl		*print message
	dc.l	cmn_dummy-cmncmdjtbl		*dummy code
cmncmdjtbl_end:
n4_of_cmn_cmd:	equ	cmncmdjtbl_end-cmncmdjtbl

cmn_dummy:				*なにもしないZMD
	rts

cmn_midi_trans:			*MIDIデータ転送
	addq.w	#1,a5		*MIDI I/F(0-2/-1:current)
	moveq.l	#0,d0
	move.b	(a5)+,d0	*str length(0-255)
	add.w	d0,a5		*skip comment str
	bsr	get_cm_l	*d0.l=n of data
	add.l	d0,a5
	rts

cmn_wave_form:			*波形メモリセット
	addq.w	#2,a5		*wave no
	bsr	get_cm_l	*d0.l=data size
	add.w	#17,a5
	moveq.l	#0,d1
	move.b	(a5)+,d1	*string len
	add.w	d1,a5
	move.l	a5,d1
	addq.l	#1,d1
	bclr.l	#0,d1		*even
	add.l	d0,d1
	move.l	d1,a5
	rts

cmn_block_adpcm:
	move.b	(a5),d1		*zpd id
	cmpi.b	#$20,d1
	bcs	cba_nofn	*$20未満はアドレス指定
	tas.b	(a3)		*zpd_scan marked
	bne	srch_fn_end
trans_cmn_fn:
	moveq.l	#CMN_DUMMY,d1
	move.b	d1,-1(a5)	*CMN_BLOCK_PCMを消す
	lea	filename(pc),a2
@@:
	move.b	(a5),d0
	move.b	d1,(a5)+	*dummyで埋める
	move.b	d0,(a2)+
	bne	@b
	rts
cba_nofn:			*<d1.l=zpd id
	addq.w	#5,a5		*skip id.b,offset.l
	rts

cmn_midi_dump:				*バイナリMIDIデータ転送
	move.b	(a5)+,d0
	ext.w	d0
	ext.l	d0
	move.l	d0,2(a3)		*set I/F number to mdd_dest_if
	tst.b	(a5)
	bne	@f
	add.w	#9,a5		*skip 0.b,offset.l,size.l
	rts
@@:
	tas.b	1(a3)		*mdd_scan marked
	beq	trans_cmn_fn

cmn_print:			*print
cmn_comment:			*コメント行
srch_fn_end:			*ファイル名の場合
	tst.b	(a5)+
	bne	srch_fn_end	*ファイルネームのエンドを捜して
	rts			*ループに戻る

get_cm_w:
	move.b	(a5)+,d0
	lsl.w	#8,d0
	move.b	(a5)+,d0
	rts

get_cm_l:
	move.b	(a5)+,d0
	lsl.w	#8,d0
	move.b	(a5)+,d0
	swap	d0
	move.b	(a5)+,d0
	lsl.w	#8,d0
	move.b	(a5)+,d0
	rts
