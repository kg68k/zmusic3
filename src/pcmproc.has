erase:					*.ERASE
	moveq.l	#0,d3
	bsr	skip_eq
	cmpi.b	#'{',(a4)
	bne	@f
	addq.w	#1,a4
	moveq.l	#-1,d3
@@:
	bsr	chk_num
	bmi	get_ers_nt
	bsr	get_num
	move.l	d1,d2
	cmp.l	#adpcm_reg_max,d2
	bcc	m_illegal_tone_number
	bra	do_wrt_ers
get_ers_nt:				*ノート番号指定
	moveq.l	#0,d2
	move.w	adpcm_bank-work(a6),d2	*d2=adpcm_bank*128
	bsr	get_note_2way		*>d2.l=orig key
do_wrt_ers:
	moveq.l	#CMN_ERASE_PCM,d0
	bsr	do_wrt_cmn_b
	move.l	d2,d0
	bsr	do_wrt_cmn_w		*note num
	tst.b	d3
	bne	find_end
	bra	cmpl_lp

erase_tone:				*.ERASE_TONE
	moveq.l	#0,d3
	bsr	skip_eq
	cmpi.b	#'{',(a4)
	bne	@f
	addq.w	#1,a4
	moveq.l	#-1,d3
@@:
	move.b	d3,-(sp)
	moveq.l	#1,d3			*tone mode
	bsr	get_bank_tone_timbre	*>d2.l=note num
	move.b	(sp)+,d3
	bra	do_wrt_ers

erase_timbre:				*.ERASE_TIMBRE
	moveq.l	#0,d3
	bsr	skip_eq
	cmpi.b	#'{',(a4)
	bne	@f
	addq.w	#1,a4
	moveq.l	#-1,d3			*timbre mode
@@:
	bsr	get_bank_timbre
	bra	do_wrt_ers

set_adpcm_bank:
*	bsr	check_relation_cmn	*コマンド関係チェック
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
	moveq.l	#0,d3
	bsr	skip_eq
	cmpi.b	#'{',(a4)
	bne	@f
	addq.w	#1,a4
	moveq.l	#-1,d3
@@:
	bsr	get_num
	subq.l	#1,d1
	cmp.l	#adpcm_bank_max,d1
	bhi	m_illegal_bank_number
	lsl.w	#7,d1			*128
	move.w	d1,adpcm_bank-work(a6)
	tst.b	d3
	bne	find_end
	bra	cmpl_lp

reg_16bitpcm_timbre:		*16bitPCMファイルを読み込む(音色として登録)(V3方式)
	move.l	#$01_00_0000,csa_regtype-work(a6)	*16bitPCMとして登録
	bra	@f
reg_8bitpcm_timbre:		*8bitPCMファイルを読み込む(音色として登録)(V3方式)
	move.l	#$02_00_0000,csa_regtype-work(a6)	*16bitPCMとして登録
	bra	@f
reg_adpcm_timbre:		*ADPCMファイルを読み込む(音色として登録)(V3方式)
	move.l	#$ff_00_0000,csa_regtype-work(a6)	*ADPCMとして登録
@@:
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_REGISTER_PCM,d0
	bsr	do_wrt_cmn_b
	lea	256(a0),a0			*256:適当
	bsr	chk_membdr_cmn			*一応、最低必要分メモリは確保
	lea	-256(a0),a0
	moveq.l	#0,d7			*深さ初期化(再帰処理時に使用)
	bsr	get_bank_timbre
	move.l	a0,a2
	sub.l	zmd_addr-work(a6),a2	*a2=加工パラメータ有り/なしフラグのオフセットアドレス
	move.l	d2,d0
	bsr	do_wrt_cmn_l		*flag(.w)/登録ノート(.w)

	bsr	skip_sep
	moveq.l	#0,d2
	bsr	get_note_2way		*>d2.l=orig key
	bra	set_orig_key

reg_16bitpcm_tone:		*16bitPCMファイルを読み込む(トーンとして登録)(V3方式)
	move.l	#$01_00_0000,csa_regtype-work(a6)	*16bitPCMとして登録
	bra	@f
reg_8bitpcm_tone:		*8bitPCMファイルを読み込む(トーンとして登録)(V3方式)
	move.l	#$02_00_0000,csa_regtype-work(a6)	*16bitPCMとして登録
	bra	@f
reg_adpcm_tone:			*ADPCMファイルを読み込む(トーンとして登録)(V3方式)
	move.l	#$ff_00_0000,csa_regtype-work(a6)	*ADPCMとして登録
@@:
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_REGISTER_PCM,d0
	bsr	do_wrt_cmn_b
	lea	256(a0),a0			*256:適当
	bsr	chk_membdr_cmn			*一応、最低必要分メモリは確保
	lea	-256(a0),a0
	moveq.l	#0,d7			*深さ初期化(再帰処理時に使用)
	moveq.l	#1,d3			*tone mode
	bsr	get_bank_tone_timbre	*>d2.l=note num
	move.l	a0,a2
	sub.l	zmd_addr-work(a6),a2	*a2=加工パラメータ有り/なしフラグのオフセットアドレス
	move.w	d2,reg_n-work(a6)
	move.l	d2,d0
	bsr	do_wrt_cmn_l		*flag(.w)/登録ノート(.w)
set_orig_key:
	move.l	csa_regtype-work(a6),d0
	andi.l	#$7f,d2			*d1=オリジナルキーコード
	swap	d2
	or.l	d2,d0
	bsr	do_wrt_cmn_l		*reg type(.b)/original key(.b)/reserve(.w)
	bsr	skip_sep
	moveq.l	#adt_name_len-1,d1
	bsr	get_string		*文字列
	cmpi.l	#adt_name_len,d3
	beq	@f
	moveq.l	#0,d0
	bsr	do_wrt_cmn_b
@@:
	bsr	skip_sep
	cmp.l	a4,d4
	bls	m_parameter_shortage
	cmpi.b	#'.',(a4)
	bne	getset_ppcfnstr
					*.TIMBRE .TONEとかの場合
	addq.w	#1,a4			*skip .
	cmp.l	a4,d4
	bls	m_parameter_shortage
	lea	timbre_tone(pc),a1
	bsr	get_com_no
	bmi	m_illegal_operand	*timbreでもtoneない場合
	move.l	d0,d3
	bsr	get_bank_tone_timbre	*> d2.l=tone number
	cmp.w	reg_n-work(a6),d2
	beq	m_illegal_parameters_combination
	move.l	d2,d0
	btst.l	#1,d3			*ポインタタイプか
	beq	@f
	bset.l	#24,d0
@@:
	bsr	do_wrt_cmn_l		*copy source
	btst.l	#1,d3
	beq	1f
	move.l	zmd_addr-work(a6),a1	*なにかしらのPPCがあるので
	tas.b	(a2,a1.l)		*マーク
	bsr	skip_sep
	bsr	ppc_alteration
1:
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_illegal_command_line
	move.b	(a4),d0
	cmpi.b	#' ',d0
	bls	_get_ppc
	cmpi.b	#',',d0
	beq	_get_ppc		*その他のパラメータがありそう
	cmpi.b	#'.',d0
	beq	_get_ppc		*その他のパラメータがありそう
	cmpi.b	#'}',d0
	beq	end_rad			*ファイルネームのみ
	bra	m_illegal_operand
getset_ppcfnstr:			*filename転送
	move.b	(a4),d0
	bsr	chk_kanji		*漢字かどうかチェック
	bmi	@f
	cmpi.b	#' ',d0
	bls	get_ppc
	cmpi.b	#',',d0
	beq	get_ppc			*その他のパラメータがありそう
	cmpi.b	#'}',d0
	beq	adntfn_only		*ファイルネームのみ
	bsr	do_wrt_cmn_b
	addq.w	#1,a4
	cmp.l	a4,d4
	bhi	getset_ppcfnstr
	bra	adntfn_only
@@:					*漢字のケース
	bsr	do_wrt_cmn_b
	addq.w	#1,a4
	cmp.l	a4,d4
	bls	m_string_break_off
	move.b	(a4)+,d0
	bsr	do_wrt_cmn_b
	cmp.l	a4,d4
	bhi	getset_ppcfnstr
adntfn_only:
	moveq.l	#0,d0
	bsr	do_wrt_cmn_b	*filename endcode
end_rad:			*登録コマンド終了
	tst.l	d7
	bne	m_illegal_nesting_error
	move.l	zmd_addr-work(a6),d0
	move.b	(a2,d0.l),d1	*加工処理が有ったなら加工処理終わりコードセット
	bpl	@f
	moveq.l	#0,d0
	bsr	do_wrt_cmn_b	*ppc endcode
@@:
	move.l	zmd_addr-work(a6),a1	*わざともう一度取り出す
	move.l	a0,d0
	sub.l	a1,d0		*d0.l=次のZMDを格納するオフセットアドレス
	subq.w	#2,d0		*a2.l+2からのオフセットだから
	sub.l	a2,d0		*d0.l=flag.wのd0-d14に入れるべき値
	cmpi.l	#32767,d0
	bls	@f
	moveq.l	#0,d0		*特殊ケース
@@:
	ror.w	#8,d0
	or.b	d1,d0
	move.b	d0,(a2,a1.l)
	ror.w	#8,d0
	move.b	d0,1(a2,a1.l)
	ifndef	sv
	move.l	zmd_addr-work(a6),a1
	move.l	z_cmn_flag(a1),d0
	bset.l	#CMN_REGISTER_PCM/4,d0
	move.l	d0,z_cmn_flag(a1)
	endif
	bra	find_end

get_ppc:			*PPCコマンド解釈コンパイル
	moveq.l	#0,d0
	bsr	do_wrt_cmn_b	*filename endcode
_get_ppc:
ppc_lp:
	bsr	skip_sep	*skip	','
@@:
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_illegal_command_line
	move.b	(a4),d0
	cmpi.b	#'.',d0
	bne	@f
	addq.w	#1,a4
	bra	@b
@@:
	cmpi.b	#'/',d0		*コメント行スキップ
	bne	@f
	addq.w	#1,a4		*skip '/'
	bsr	do_skip_comment
	bra	ppc_lp
@@:
	cmpi.b	#'(',d0
	beq	bracket_ppc
	cmpi.b	#')',d0
	bne	@f
	addq.w	#1,a4
	subq.l	#1,d7		*深さマーク
	bcs	m_illegal_command_line
	moveq.l	#0,d0		*MIX/CONNECT end mark
	bsr	do_wrt_cmn_b
	bra	ppc_lp
@@:
	cmpi.b	#'}',d0		*終了
	beq	end_rad

	lea	PPC_tbl(pc),a1
	bsr	get_com_no	*PPC認識
	bmi	m_undefined_ppc
	add.w	d0,d0
	add.w	d0,d0		*4倍
	move.w	2+PPCjtbl(pc,d0.w),d0
	move.l	zmd_addr-work(a6),a1	*なにかしらのPPCがあるので
	tas.b	(a2,a1.l)		*マーク
	jmp	PPCjtbl(pc,d0.w)

bracket_ppc:			*'('で始まっている場合
	addq.w	#1,a4		*skip '('
	bsr	skip_sep
	cmp.l	a4,d4
	bls	m_illegal_command_line
@@:
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_illegal_command_line
	move.b	(a4),d0
	cmpi.b	#'.',d0
	bne	@f
	addq.w	#1,a4
	bra	@b
@@:
	lea	PPC_tbl(pc),a1
	bsr	get_com_no	*PPC認識
	bmi	m_undefined_ppc
	add.w	d0,d0
	add.w	d0,d0
	move.l	PPCjtbl(pc,d0.w),d0
*!	bmi	m_illegal_command_line
	bpl	m_illegal_command_line
	addq.l	#1,d7		*深さマーク
	bcs	m_illegal_command_line
	move.l	zmd_addr-work(a6),a1	*なにかしらのPPCがあるので
	tas.b	(a2,a1.l)		*マーク
	jmp	PPCjtbl(pc,d0.w)

PPCjtbl:
	dc.w	0,ppc_bend-PPCjtbl	*bend
	dc.w	-1,ppc_connect-PPCjtbl	*connect(括弧がつく可能性有りのコマンド)
	dc.w	0,ppc_fade-PPCjtbl	*fade
	dc.w	0,ppc_loop-PPCjtbl	*loop
	dc.w	-1,ppc_mix-PPCjtbl	*mix(括弧がつく可能性有りのコマンド)
	dc.w	0,ppc_portament-PPCjtbl	*portament
	dc.w	0,ppc_pitch-PPCjtbl	*pitch
	dc.w	0,ppc_reverse-PPCjtbl	*reverse
	dc.w	0,ppc_truncate-PPCjtbl	*truncate
	dc.w	0,ppc_tune-PPCjtbl	*tune
	dc.w	0,ppc_volume-PPCjtbl	*volume
	dc.w	0,ppc_delete-PPCjtbl	*delete
	dc.w	0,ppc_dist-PPCjtbl	*distortion
	dc.w	0,ppc_smooth-PPCjtbl	*smooth
*	dc.w	0,ppc_execute-PPCjtbl	*execute

	dc.w	0,ppc_bend-PPCjtbl	*b
	dc.w	-1,ppc_connect-PPCjtbl	*n(括弧がつく可能性有りのコマンド)
	dc.w	0,ppc_fade-PPCjtbl	*f
	dc.w	0,ppc_loop-PPCjtbl	*l
	dc.w	-1,ppc_mix-PPCjtbl	*m(括弧がつく可能性有りのコマンド)
	dc.w	0,ppc_portament-PPCjtbl	*g
	dc.w	0,ppc_pitch-PPCjtbl	*p 
	dc.w	0,ppc_reverse-PPCjtbl	*r
	dc.w	0,ppc_truncate-PPCjtbl	*c
	dc.w	0,ppc_tune-PPCjtbl	*t
	dc.w	0,ppc_volume-PPCjtbl	*v
	dc.w	0,ppc_delete-PPCjtbl	*d

PPC_tbl:	*PCM data PROCESSING COMMAND
	dc.b	'BEND',0
	dc.b	'CONNECT',0
	dc.b	'FADE',0
	dc.b	'LOOP',0
	dc.b	'MIX',0
	dc.b	'PORTAMENT',0
	dc.b	'PITCH',0
	dc.b	'REVERSE',0
	dc.b	'TRUNCATE',0
	dc.b	'TUNE',0
	dc.b	'VOLUME',0
	dc.b	'DELETE',0
	dc.b	'DISTORTION',0
	dc.b	'SMOOTH',0
*	dc.b	'EXECUTE',0

	dc.b	'B',0
	dc.b	'N',0
	dc.b	'F',0
	dc.b	'L',0
	dc.b	'M',0
	dc.b	'G',0
	dc.b	'P',0
	dc.b	'R',0
	dc.b	'C',0
	dc.b	'T',0
	dc.b	'V',0
	dc.b	'D',0
	dc.b	-1
	.even

ppc_pitch:			*ピッチ変換
	bsr	chk_num
	bmi	case_ppcptch_kc
	bsr	get_num
*	tst.l	d1
*	beq	m_illegal_pitch_value
	cmpi.l	#-144,d1
	blt	m_illegal_pitch_value
	cmpi.l	#144,d1
	bgt	m_illegal_pitch_value
	bsr	get_frq_rng
	move.l	d1,d3
	bra	get_ppcptch_ofsz
case_ppcptch_kc:		*音階指定ケース
	moveq.l	#0,d2
	bsr	get_note_2way	*> d2=src kc
	move.l	d2,d3
	bsr	skip_sep
	moveq.l	#0,d2
	bsr	get_note_2way	*> d2=dest kc
	sub.l	d3,d2
	beq	m_illegal_parameters_combination
	move.l	d2,d1
	bsr	get_frq_rng
	move.l	d1,d3
get_ppcptch_ofsz:
	moveq.l	#0,d2
	bsr	skip_sep
	bsr	chk_num
	bmi	@f
	bsr	get_num		*get offset
	move.l	d1,d2
@@:
	moveq.l	#0,d1
	bsr	skip_sep
	bsr	chk_num
	bmi	do_wrt_cmn_pitch
	bsr	get_num		*get size
do_wrt_cmn_pitch:
	moveq.l	#PPC_PITCH,d0
	bsr	do_wrt_cmn_b
	move.l	d2,d0		*offset
	bsr	do_wrt_cmn_l
	move.l	d1,d0		*size
	bsr	do_wrt_cmn_l
	move.l	d3,d0		*src/dest frq
	bsr	do_wrt_cmn_l
	bra	ppc_lp

ppc_tune:			*周波数微調整
	bsr	chk_num
	bmi	m_missing_operand
	bsr	get_num		*get src frq
	tst.l	d1
	beq	m_illegal_frequency_value
	cmpi.l	#65535,d1
	bhi	m_illegal_frequency_value
	move.l	d1,d3
	swap	d3
	bsr	skip_sep
	bsr	chk_num
	bmi	m_missing_operand
	bsr	get_num		*get dest frq
	tst.l	d1
	beq	m_illegal_frequency_value
	cmpi.l	#65535,d1
	bhi	m_illegal_frequency_value
	move.w	d1,d3

	moveq.l	#0,d2
	bsr	skip_sep
	bsr	chk_num
	bmi	@f
	bsr	get_num		*get offset
	move.l	d1,d2
@@:
	moveq.l	#0,d1
	bsr	skip_sep
	bsr	chk_num
	bmi	do_wrt_cmn_pitch
	bsr	get_num		*get size
	bra	do_wrt_cmn_pitch

ppc_dist:			*ディストーション
	bsr	chk_num
	bmi	m_missing_operand
	bsr	get_num		*get mul vol
	cmpi.l	#adpcm_vol_max,d1
	bhi	m_illegal_volume_value
	move.l	d1,d3

	swap	d3
	bsr	skip_sep
	bsr	chk_num
	bmi	m_missing_operand
	bsr	get_num		*get cutoff level
	cmpi.l	#32767,d1
	bhi	m_cut_off_level_too_big
	move.w	d1,d3

	moveq.l	#0,d2
	bsr	skip_sep
	bsr	chk_num
	bmi	@f
	bsr	get_num		*get offset
	move.l	d1,d2
@@:
	moveq.l	#0,d1
	bsr	skip_sep
	bsr	chk_num
	bmi	@f
	bsr	get_num		*get size
@@:
	moveq.l	#PPC_DISTORTION,d0
	bsr	do_wrt_cmn_b
	move.l	d2,d0		*offset
	bsr	do_wrt_cmn_l
	move.l	d1,d0		*size
*	or.l	d2,d1
*	beq	m_illegal_parameters_combination
	bsr	do_wrt_cmn_l
	move.l	d3,d0		*mul,cutoff level
	bsr	do_wrt_cmn_l
	bra	ppc_lp

ppc_volume:			*音量変換
	bsr	chk_num
	bmi	m_missing_operand
	bsr	get_num
*	tst.l	d1
*	beq	m_illegal_volume_value
	cmpi.l	#adpcm_vol_max,d1
	bhi	m_illegal_volume_value
	move.l	d1,d3

	moveq.l	#0,d2
	bsr	skip_sep
	bsr	chk_num
	bmi	@f
	bsr	get_num		*get offset
	move.l	d1,d2
@@:
	moveq.l	#0,d1
	bsr	skip_sep
	bsr	chk_num
	bmi	@f
	bsr	get_num		*get size
@@:
	moveq.l	#PPC_VOLUME,d0
	bsr	do_wrt_cmn_b
	move.l	d2,d0		*offset
	bsr	do_wrt_cmn_l
	move.l	d1,d0		*size
*	or.l	d2,d1
*	beq	m_illegal_parameters_combination
	bsr	do_wrt_cmn_l
	move.l	d3,d0		*volume
	bsr	do_wrt_cmn_w
	bra	ppc_lp

ppc_smooth:			*スムージング
	bsr	chk_num
	bmi	m_missing_operand
	bsr	get_num
	subq.l	#1,d1
	cmpi.l	#65535,d1
	bhi	m_illegal_repeat_time
	move.l	d1,d3

	moveq.l	#0,d2
	bsr	skip_sep
	bsr	chk_num
	bmi	@f
	bsr	get_num		*get offset
	move.l	d1,d2
@@:
	moveq.l	#0,d1
	bsr	skip_sep
	bsr	chk_num
	bmi	@f
	bsr	get_num		*get size
@@:
	moveq.l	#PPC_SMOOTH,d0
	bsr	do_wrt_cmn_b
	move.l	d2,d0		*offset
	bsr	do_wrt_cmn_l
	move.l	d1,d0		*size
*	or.l	d2,d1
*	beq	m_illegal_parameters_combination
	bsr	do_wrt_cmn_l
	move.l	d3,d0		*repeat time
	bsr	do_wrt_cmn_w
	bra	ppc_lp

*ppc_execute:				*外部コマンド実行
*	moveq.l	#PPC_EXECUTE,d0
*	bsr	do_wrt_cmn_b
*	bsr	skip_spc2
*	move.l	a0,d3			*チェックで使用
*exefnstr_lp:				*filename,option転送
*	move.b	(a4),d0
*	bsr	chk_kanji		*漢字かどうかチェック
*	bmi	@f
*	cmpi.b	#$0d,d0
*	beq	set_exfnedcd
*	cmpi.b	#$0a,d0
*	beq	set_exfnedcd
*	bsr	do_wrt_cmn_b
*	addq.w	#1,a4
*	cmp.l	a4,d4
*	bhi	exefnstr_lp
*	bra	m_illegal_command_line
*@@:					*漢字ケース
*	bsr	do_wrt_cmn_b
*	addq.w	#1,a4
*	cmp.l	a4,d4
*	bls	m_string_break_off
*	move.b	(a4)+,d0
*	bsr	do_wrt_cmn_b
*	cmp.l	a4,d4
*	bhi	exefnstr_lp
*	bra	m_illegal_command_line
*set_exfnedcd:
*	cmp.l	d3,a0
*	beq	m_illegal_command_line
*	moveq.l	#0,d0
*	bsr	do_wrt_cmn_b		*filename endcode
*	bra	ppc_lp

ppc_mix:				*MIX
	moveq.l	#PPC_MIX,d0
	bsr	do_wrt_cmn_b
ppc_mix0:				*connect entry
	bsr	skip_sep
	cmp.l	a4,d4
	bls	m_parameter_shortage
	cmpi.b	#'.',(a4)
	bne	pmxfnstr
					*.TIMBRE .TONEとかの場合
	addq.w	#1,a4			*skip .
	cmp.l	a4,d4
	bls	m_parameter_shortage
	lea	timbre_tone(pc),a1
	bsr	get_com_no
	bmi	m_illegal_operand	*timbreでもtoneない場合
	cmpi.l	#1,d0
	bhi	m_illegal_parameter_format	*ポインタ系などは使えない
	move.l	d0,d3
	bsr	get_bank_tone_timbre	*> d2.l=tone number
	move.l	d2,d0
	bsr	do_wrt_cmn_l		*copy source
	bsr	skip_sep
	cmp.l	a4,d4
	bhi	get_mix_offset
	bra	m_illegal_command_line
pmxfnstr:
	bsr	skip_spc2
pmxfnstr_lp:				*filename転送
	move.b	(a4),d0
	bsr	chk_kanji		*漢字かどうかチェック
	bmi	@f
	cmpi.b	#' ',d0
	bls	set_mxfnedcd
	cmpi.b	#',',d0
	beq	set_mxfnedcd		*その他のパラメータがありそう
	cmpi.b	#'}',d0
	beq	set_mxfn_only
	cmpi.b	#')',d0
	beq	set_mxfn_only2
	bsr	do_wrt_cmn_b
	addq.w	#1,a4
	cmp.l	a4,d4
	bhi	pmxfnstr_lp
	bra	m_illegal_command_line
@@:					*漢字ケース
	bsr	do_wrt_cmn_b
	addq.w	#1,a4
	cmp.l	a4,d4
	bls	m_string_break_off
	move.b	(a4)+,d0
	bsr	do_wrt_cmn_b
	cmp.l	a4,d4
	bhi	pmxfnstr_lp
	bra	m_illegal_command_line
set_mxfn_only2:				*')'にて終了したケース(オフセット，サイズなし)
	moveq.l	#0,d0
	bsr	do_wrt_cmn_b		*filename endcode
	moveq.l	#0,d0
	bsr	do_wrt_cmn_l		*mix delay=0
	moveq.l	#0,d0
	bsr	do_wrt_cmn_b		*mix ppc endcode
	subq.l	#1,d7
	bcs	m_illegal_command_line
	moveq.l	#0,d0
	bsr	do_wrt_cmn_b		*mix ppc endcode
	bra	ppc_lp
set_mxfn_only:				*'}'で終了したケース(オフセット，サイズなし)
	moveq.l	#0,d0
	bsr	do_wrt_cmn_b		*filename endcode
	moveq.l	#0,d0
	bsr	do_wrt_cmn_l		*mix delay=0
	moveq.l	#0,d0
	bsr	do_wrt_cmn_b		*mix ppc endcode
	bra	ppc_lp
set_mxfnedcd:				*set filename endcode
	moveq.l	#0,d0
	bsr	do_wrt_cmn_b		*filename endcode
get_mix_offset:				*オフセット，サイズ取りだし
	bsr	skip_sep
	moveq.l	#0,d1
	bsr	chk_num
	bmi	@f
	bsr	get_num		*get mix offset
@@:
	move.l	d1,d0			*mix offset
	bsr	do_wrt_cmn_l
	tst.l	d7
	bne	ppc_lp
	moveq.l	#0,d0
	bsr	do_wrt_cmn_b		*mix ppc endcode
	bra	ppc_lp

ppc_truncate:			*きりだし
	moveq.l	#0,d2
	bsr	chk_num
	bmi	@f
	bsr	get_num	*get offset
	move.l	d1,d2
@@:
	moveq.l	#0,d1
	bsr	skip_sep
	bsr	chk_num
	bmi	@f
	bsr	get_num	*get size
@@:
	move.l	d1,d0		*size
	or.l	d2,d0
	beq	m_illegal_parameters_combination	*両方ゼロでは意味なし
	moveq.l	#PPC_TRUNCATE,d0
	bsr	do_wrt_cmn_b
	move.l	d2,d0		*offset
	bsr	do_wrt_cmn_l
	move.l	d1,d0		*size
	bsr	do_wrt_cmn_l
	bra	ppc_lp

ppc_alteration:			*ポインタコピー(ルーチンの終端がbra ppc_lpでない点に注意)
	moveq.l	#0,d2
	bsr	chk_num
	bmi	@f
	bsr	get_num		*get offset
	move.l	d1,d2
@@:
	moveq.l	#0,d1
	bsr	skip_sep
	bsr	chk_num
	bmi	@f
	bsr	get_num		*get size
@@:
	moveq.l	#PPC_ALTERATION,d0
	bsr	do_wrt_cmn_b
	move.l	d2,d0		*offset
	bsr	do_wrt_cmn_l
	move.l	d1,d0		*size
	bra	do_wrt_cmn_l

ppc_delete:			*領域削除
	moveq.l	#0,d2
	bsr	chk_num
	bmi	@f
	bsr	get_num		*get offset
	move.l	d1,d2
@@:
	moveq.l	#0,d1
	bsr	skip_sep
	bsr	chk_num
	bmi	@f
	bsr	get_num		*get size
@@:
	moveq.l	#PPC_DELETE,d0
	bsr	do_wrt_cmn_b
	move.l	d2,d0		*offset
	bsr	do_wrt_cmn_l
	move.l	d1,d0		*size
	or.l	d2,d1
	beq	m_illegal_parameters_combination	*両方ゼロでは意味なし
	bsr	do_wrt_cmn_l
	bra	ppc_lp

ppc_reverse:
	moveq.l	#0,d2
	bsr	chk_num
	bmi	@f
	bsr	get_num	*get offset
	move.l	d1,d2
@@:
	moveq.l	#0,d1
	bsr	skip_sep
	bsr	chk_num
	bmi	@f
	bsr	get_num	*get size
@@:
	moveq.l	#PPC_REVERSE,d0
	bsr	do_wrt_cmn_b
	move.l	d2,d0		*offset
	bsr	do_wrt_cmn_l
	move.l	d1,d0		*size
	or.l	d2,d1
	beq	m_illegal_parameters_combination	*両方ゼロでは意味なし
	bsr	do_wrt_cmn_l
	bra	ppc_lp

ppc_fade:			*フェーダー
	bsr	chk_num
	bmi	m_missing_operand
	bsr	get_num		*get src level
	cmpi.l	#65535,d1
	bhi	m_illegal_volume_value
	move.l	d1,d3
	swap	d3
	bsr	skip_sep
	bsr	chk_num
	bmi	m_missing_operand
	bsr	get_num		*get dest level
	cmpi.l	#65535,d1
	bhi	m_illegal_volume_value
	move.w	d1,d3

	moveq.l	#0,d2
	bsr	skip_sep
	bsr	chk_num
	bmi	@f
	bsr	get_num	*get offset
	move.l	d1,d2
@@:
	moveq.l	#0,d1
	bsr	skip_sep
	bsr	chk_num
	bmi	@f
	bsr	get_num	*get size
@@:
	moveq.l	#PPC_FADE,d0
	bsr	do_wrt_cmn_b
	move.l	d2,d0		*offset
	bsr	do_wrt_cmn_l
	move.l	d1,d0		*size
	or.l	d2,d1
	beq	m_illegal_parameters_combination
	bsr	do_wrt_cmn_l
	move.l	d3,d0		*src/dest level
	bsr	do_wrt_cmn_l
	bra	ppc_lp

ppc_portament:			*ポルタメント変換
	bsr	chk_num
	bmi	case_ppcport_kc
	bsr	get_num
*	tst.l	d1
*	beq	m_illegal_pitch_value
	cmpi.l	#-144,d1
	blt	m_illegal_pitch_value
	cmpi.l	#144,d1
	bgt	m_illegal_pitch_value
	bsr	get_frq_rng
	move.l	d1,d3
	bra	get_ppcport_ofsz
case_ppcport_kc:		*音階指定ケース
	moveq.l	#0,d2
	bsr	get_note_2way	*> d2=src kc
	move.l	d2,d3
	bsr	skip_sep
	moveq.l	#0,d2
	bsr	get_note_2way	*> d2=dest kc
	sub.l	d3,d2
	beq	m_illegal_parameters_combination
	move.l	d2,d1
	bsr	get_frq_rng
	move.l	d1,d3
get_ppcport_ofsz:
	moveq.l	#0,d2
	bsr	skip_sep
	bsr	chk_num
	bmi	@f
	bsr	get_num	*get offset
	move.l	d1,d2
@@:
	moveq.l	#0,d1
	bsr	skip_sep
	bsr	chk_num
	bmi	do_wrt_cmn_bend
	bsr	get_num	*get size
do_wrt_cmn_bend:
	moveq.l	#PPC_BEND,d0
	bsr	do_wrt_cmn_b
	move.l	d2,d0		*offset
	bsr	do_wrt_cmn_l
	move.l	d1,d0		*size
	or.l	d2,d1
	beq	m_illegal_parameters_combination
	bsr	do_wrt_cmn_l
	move.l	d3,d0		*src/dest frq
	bsr	do_wrt_cmn_l
	bra	ppc_lp

ppc_bend:			*周波数微調整
	bsr	chk_num
	bmi	m_missing_operand
	bsr	get_num	*get src frq
	tst.l	d1
	beq	m_illegal_frequency_value
	cmpi.l	#65535,d1
	bhi	m_illegal_frequency_value
	move.l	d1,d3
	swap	d3
	bsr	skip_sep
	bsr	chk_num
	bmi	m_missing_operand
	bsr	get_num	*get dest frq
	tst.l	d1
	beq	m_illegal_frequency_value
	cmpi.l	#65535,d1
	bhi	m_illegal_frequency_value
	move.w	d1,d3

	moveq.l	#0,d2
	bsr	skip_sep
	bsr	chk_num
	bmi	@f
	bsr	get_num	*get offset
	move.l	d1,d2
@@:
	moveq.l	#0,d1
	bsr	skip_sep
	bsr	chk_num
	bmi	do_wrt_cmn_bend
	bsr	get_num	*get size
	bra	do_wrt_cmn_bend

ppc_loop:					*ループパラメータ設定
	lea	256(a0),a0			*256:適当
	bsr	chk_membdr_cmn			*一応、最低必要分メモリは確保
	lea	-256(a0),a0
	moveq.l	#PPC_LOOP,d0
	bsr	do_wrt_cmn_b
	move.l	a0,a1
	moveq.l	#0,d0
	bsr	do_wrt_cmn_b			*omt
	bsr	chk_num
	bmi	m_missing_operand
	bsr	get_num				*get loop type
	move.l	d1,d0
	bne	m_undefined_loop_type
	bsr	do_wrt_cmn_b			*loop type

	bsr	skip_sep
	bsr	chk_num
	bmi	m_missing_operand
	bsr	get_num
	move.l	d1,d0
	bsr	do_wrt_cmn_l			*loop time

	bsr	skip_sep
	bsr	chk_num
	bmi	@f
	bsr	get_num
	move.l	d1,d0
	bsr	do_wrt_cmn_l			*start point
	bset.b	#0,(a1)
@@:
	bsr	skip_sep
	bsr	chk_num
	bmi	ppc_lp
	bsr	get_num
	move.l	d1,d0
	bsr	do_wrt_cmn_l			*end point
	bset.b	#1,(a1)
	bra	ppc_lp

ppc_connect:			*connect
	moveq.l	#PPC_CONNECT,d0
	bsr	do_wrt_cmn_b
	bra	ppc_mix0

get_bank_timbre:
	move.l	d3,-(sp)
	moveq.l	#0,d3
	bsr	get_bank_tone_timbre
	move.l	(sp)+,d3
	rts

get_bank_tone_timbre:			*バンク番号とトーン番号/音色番号の取りだし
	* < d3.lの第0ビット	0:timbre/1:tone
	* > d2.l=0-32767
	* - d3.l
	bsr	chk_num
	bmi	m_illegal_operand
	bsr	get_num			*d1=bank no.
	cmp.l	a4,d4
	bls	m_parameter_shortage
	btst.l	#0,d3
	beq	@f
	subq.l	#1,d1			*toneモードの時のバンクは1-256
@@:
	move.l	d1,d2			*d2=bank no.
	cmp.l	#adpcm_bank_max,d2
	bhi	m_illegal_bank_number
	lsl.w	#7,d2			*128倍
	bsr	skip_spc
	cmp.l	a4,d4
	bls	m_parameter_shortage
	btst.l	#0,d3
	bne	1f
	cmpi.b	#':',(a4)
	bne	1f
					*バンクを7bit:7bit的に表記する場合
	addq.w	#1,a4
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted
	bsr	get_num
	cmpi.l	#127,d1
	bhi	m_illegal_bank_number
	add.l	d1,d2
	cmpi.l	#adpcm_bank_max,d2
	bhi	m_illegal_bank_number
	lsl.l	#7,d2			*128倍
1:
	bsr	skip_sep
	btst.l	#0,d3
	bne	@f
	bsr	chk_num
	bmi	m_parameter_cannot_be_omitted	*音色番号指定モードで文字列指定はおかしい
	bra	1f
@@:
	bsr	chk_num
	bmi	get_note_2way	*文字列指定ケース
1:
	bsr	get_num		*d1=note number/timbre number
	cmp.l	a4,d4
	bls	m_parameter_shortage
	btst.l	#0,d3
	bne	1f
	subq.l	#1,d1		*音色番号指定では1-128指定だから
	cmpi.l	#127,d1
	bhi	m_illegal_timbre_number
	add.w	d1,d2
	ori.l	#$8000,d2		*timbreなら最上位ビットオン
	rts
1:					*tone
	cmpi.l	#127,d1
	bhi	m_illegal_note_number
	add.w	d1,d2
	rts

get_note_2way:			*音階指定
	* < d2.l=bank number
	* > d2.l=note number
	* x d0
reglist	reg	d1/d3/d5
	movem.l	reglist,-(sp)
@@:
	cmp.l	a4,d4
	bls	m_parameter_shortage
	move.b	(a4),d0
	jsr	mk_capital-work(a6)
	cmpi.b	#'.',d0
	bne	@f
	addq.w	#1,a4		*skip '.'
	bra	@b
@@:
	cmpi.b	#'O',d0		*音階、オクターブの順の指定か
	bne	@f
	addq.w	#1,a4		*skip 'o'
	bsr	chk_num
	bmi	m_illegal_octave
	bsr	get_num		*d1=octave num
	cmp.l	a4,d4
	bls	m_parameter_shortage
	bsr	get_note_num	*< d1=oct,d2=bank*128
	bmi	m_illegal_tone_number
	cmp.l	#adpcm_reg_max,d2
	bcc	m_illegal_tone_number
	movem.l	(sp)+,reglist
	rts
@@:				*ステップエディタ系の音階指定(ex.C#4)
	cmpi.b	#'A',d0
	bcs	m_unexpected_operand
	cmpi.b	#'G',d0
	bhi	m_unexpected_operand
	moveq.l	#-1,d1		*dummy octave=-1
	bsr	get_note_num2	*< d1.l=dummy,d2=bank*128
	bmi	m_illegal_tone_number
	bsr	chk_num
	bmi	m_illegal_tone_number
	bsr	get_num		*get octave
	cmp.l	a4,d4
	bls	m_parameter_shortage
	addq.w	#1,d1		*-1～9→0-10
	mulu	#12,d1
	add.w	d1,d2
	cmpi.l	#adpcm_reg_max,d2
	bcc	m_illegal_tone_number
	moveq.l	#0,d3
	moveq.l	#-1,d5
	bsr	chk_chogo2
	add.b	d3,d2
	movem.l	(sp)+,reglist
	rts

reg_adpcm_data_by_kc:		*ADPCMファイルを読み込む(音階指定)(V2互換)
	bset.b	#0,now_cmd-work(a6)		*パラメタを複数行に渡って書けないMARK
	bsr	get_num		*d1=octave num
	cmp.l	a4,d4
	bls	m_parameter_shortage
	moveq.l	#0,d2
	move.w	adpcm_bank-work(a6),d2	*d2=adpcm_bank*128
	bsr	get_note_num		*< d1=oct,d2=bank*128
	bmi	m_illegal_tone_number
	cmp.l	#adpcm_reg_max,d2
	bcc	m_illegal_tone_number
	bra	@f

reg_adpcm_data_by_no:		*ADPCMファイルを読み込む(ノートナンバー指定)(V2互換)
	bset.b	#0,now_cmd-work(a6)		*パラメタを複数行に渡って書けないMARK
	bsr	get_num		*d1=note num
	cmp.l	a4,d4
	bls	m_parameter_shortage
	move.l	d1,d2		*d2=note number
	cmp.l	#adpcm_reg_max,d2
	bcc	m_illegal_tone_number
@@:
	move.l	d2,csa_regnote-work(a6)
	move.l	d2,d0
	swap	d0
	or.l	#$ff00_0000,d0
	move.l	d0,csa_regtype-work(a6)
get_reg_data:				*登録データの取りだし(V2互換用)
	* < d2.l=登録先番号
	bsr	skip_eq
	bsr	chk_num
	bmi	do_copy_fnm
	cmp.l	a4,d4
	bls	m_parameter_shortage
	bsr	get_num			*ファイルネームではなくて数値のケース
	cmpi.l	#adpcm_reg_max,d1
	bcc	m_illegal_tone_number
	move.l	filename-work(a6),a1
	move.l	d1,(a1)			*転送もとの数値をファイルネームワークへセーブ
	bra	get_param
do_copy_fnm:
	cmp.l	a4,d4
	bls	m_parameter_shortage
	move.b	(a4),d0
	cmpi.b	#'.',d0
	beq	bykc			*キーコードによりコピー元指定
	cmpi.b	#'#',d0
	beq	bykc			*キーコードによりコピー元指定
	cmpi.b	#' ',d0
	bls	m_illegal_filename
	move.l	a0,d0			*save
	move.l	filename-work(a6),a0	*destination
	bsr	copy_fn			*copy filename to work
	move.l	d0,a0
get_param:
	moveq.l	#0,d0
	move.l	d0,mix_note-work(a6)
	move.l	d0,mix_delay-work(a6)
	move.l	d0,pitch_p-work(a6)
	move.l	d0,vol_p-work(a6)
	move.l	d0,fade_p-work(a6)
	move.l	d0,fade_delay-work(a6)
	move.l	d0,fade_size-work(a6)
	move.l	d0,cut_offset-work(a6)
	move.l	d0,cut_size-work(a6)
	move.b	d0,rv_p-work(a6)
	cmp.l	a4,d4
	bls	do_read_ocr
ocr_lp:
	bsr	skip_sep2
	bsr	skip_spc2
	cmpi.b	#'/',(a4)
	beq	do_read_ocr
	cmp.l	a4,d4
	bls	do_read_ocr
	cmpi.b	#' ',(a4)
	bcs	do_read_ocr
	move.b	(a4)+,d0
	jsr	mk_capital-work(a6)
	cmpi.b	#'C',d0
	beq	get_cp
	cmpi.b	#'F',d0
	beq	get_fp
	cmpi.b	#'R',d0
	beq	get_rv
	cmpi.b	#'D',d0
	beq	get_dp
	cmpi.b	#'M',d0
	beq	get_mp		*get mix p
	cmpi.b	#'V',d0
	beq	get_vp		*get vol_p
	cmpi.b	#'P',d0
	bne	m_undefined_ppc

*get_pp:			*pitch change parameter
	bsr	chk_num
	bmi	m_missing_operand
	bsr	get_num
*	tst.l	d1
*	beq	m_illegal_pitch_value
	cmpi.l	#-144,d1
	blt	m_illegal_pitch_value
	cmpi.l	#144,d1
	bgt	m_illegal_pitch_value
	bsr	get_frq_rng
	move.l	d1,pitch_p-work(a6)
	bra	ocr_lp

get_vp:			*volume parameter
	bsr	chk_num
	bmi	m_missing_operand
	bsr	get_num
	cmp.l	#adpcm_vol_max,d1
	bhi	m_illegal_volume_value
	bset.l	#31,d1		*ON!
	move.l	d1,vol_p-work(a6)
	bra	ocr_lp

get_dp:			*mix delay parameter
	bsr	chk_num
	bmi	m_missing_operand
	bsr	get_num
	move.l	d1,mix_delay-work(a6)
	bra	ocr_lp

get_mp:
	bsr	chk_num
	bpl	@f		*note number指定の場合
	cmp.l	a4,d4
	bls	m_missing_operand
	move.b	(a4)+,d0
	andi.w	#$df,d0
	cmpi.b	#'O',d0
	bne	m_unexpected_operand		*変な文字?
	bsr	chk_num
	bmi	m_missing_operand
	bsr	get_num				*get dest. oct
	cmp.l	a4,d4
	bls	m_parameter_shortage
	moveq.l	#0,d2
	move.w	adpcm_bank-work(a6),d2		*d2=adpcm_bank*128
	bsr	get_note_num			*< d1=oct,d2=bank*128
	bmi	m_illegal_tone_number
	move.l	d2,d1
	bra	chk_mnote
@@:
	bsr	get_num		*get note number
chk_mnote:
	cmp.l	#adpcm_reg_max,d1
	bcc	m_illegal_tone_number
	bset.l	#31,d1		*ON!
	move.l	d1,mix_note-work(a6)
	bsr	skip_sep
	bsr	chk_num		*offsetあるか
	bmi	ocr_lp
	bsr	get_num		*get delay
	move.l	d1,mix_delay-work(a6)
	bra	ocr_lp

get_rv:				*逆転
	st.b	rv_p-work(a6)
	bra	ocr_lp

get_cp:				*truncate parameter
	moveq.l	#0,d1
	bsr	chk_num
	bmi	@f
	bsr	get_num		*get cut offset
@@:
	bsr	skip_sep
	move.l	d1,cut_offset-work(a6)
	moveq.l	#0,d1
	bsr	chk_num
	bmi	@f
	bsr	get_num		*get cut size
@@:
	move.l	d1,cut_size-work(a6)
	bne	ocr_lp
	tst.l	cut_offset-work(a6)	*delayもsizeも0ではエラー
	beq	m_illegal_parameters_combination
	bra	ocr_lp

get_fp:				*fade in/out parameter
	bsr	chk_num
	bmi	ocr_fo_mode
	bsr	get_num
	tst.l	d1
	bpl	ocr_fo_mode
*ocr_fi_mode:
	neg.l	d1		*d1=delay
	move.l	#$0000_0080,fade_p-work(a6)
	clr.l	fade_delay-work(a6)
	move.l	d1,fade_size-work(a6)
	bsr	skip_sep
	bsr	chk_num
	bmi	ocr_lp			*default=0
	bsr	get_num			*get end level
	cmpi.l	#65535,d1
	bhi	m_illegal_volume_value
	move.w	d1,fade_p+0-work(a6)	*in level
	bra	ocr_lp
ocr_fo_mode:
	move.l	#$0080_0000,fade_p-work(a6)
	move.l	d1,fade_delay-work(a6)
	clr.l	fade_size-work(a6)
	bsr	skip_sep
	bsr	chk_num
	bmi	ocr_lp			*default=0
	bsr	get_num			*get end level
	cmpi.l	#65535,d1
	bhi	m_illegal_volume_value
	move.w	d1,fade_p+2-work(a6)	*out level
	bra	ocr_lp

bykc:				*note number/timbre numberによるコピーノート指定
	addq.w	#1,a4		*skip header '.'
	cmp.l	a4,d4
	bls	m_parameter_shortage
	move.b	(a4)+,d0
	andi.w	#$df,d0
	cmpi.b	#'O',d0
	bne	m_unexpected_operand		*変な文字?
	bsr	chk_num
	bmi	m_missing_operand
	bsr	get_num				*d1=octave
	cmp.l	a4,d4
	bls	m_parameter_shortage
	moveq.l	#0,d2
	move.w	adpcm_bank-work(a6),d2		*d2=adpcm_bank*128
	bsr	get_note_num			*< d1=oct,d2=bank*128
	bmi	m_illegal_tone_number
	cmp.l	#adpcm_reg_max,d2
	bcc	m_illegal_tone_number
	move.l	filename-work(a6),a1
	move.l	d2,(a1)
	bra	get_param

do_read_ocr:				*pitch/vol,cut,rev,fade,mix
*	bsr	check_relation_cmn	*コマンド関係チェック
	moveq.l	#CMN_REGISTER_PCM,d0
	bsr	do_wrt_cmn_b
	lea	256(a0),a0			*256:適当
	bsr	chk_membdr_cmn			*一応、最低必要分メモリは確保
	lea	-256(a0),a0
	move.l	a0,a2
	sub.l	zmd_addr-work(a6),a2	*a2=加工パラメータ有り/なしフラグのオフセットアドレス
	move.l	csa_regnote-work(a6),d0	*flag(.w)/登録ノート(.w)
	bsr	do_wrt_cmn_l
	move.l	csa_regtype-work(a6),d0	*reg type(.b)/original key(.b)/reserve(.w)
	bsr	do_wrt_cmn_l
	moveq.l	#0,d0
	bsr	do_wrt_cmn_b		*DUMMY TONE NAME
	move.l	filename-work(a6),a1
	tst.b	(a1)
	bne	fncpy_dro
	move.l	(a1),d0			*copy note number
	bsr	do_wrt_cmn_l
	bra	@f
fncpy_dro:				*filenameケース
	move.b	(a1)+,d0
	beq	exit_fncpy_dro
	bsr	do_wrt_cmn_b		*ファイルネーム転送
	bra	fncpy_dro
exit_fncpy_dro:
	bsr	do_wrt_cmn_b		*end code
@@:					*pitch shift
	move.l	pitch_p-work(a6),d1
	beq	@f
	move.l	zmd_addr-work(a6),d0
	tas.b	(a2,d0.l)		*flag on
	moveq.l	#PPC_PITCH,d0
	bsr	do_wrt_cmn_b
	moveq.l	#0,d0			*offset
	bsr	do_wrt_cmn_l
	moveq.l	#0,d0			*size
	bsr	do_wrt_cmn_l
	move.l	d1,d0			*pitch src dest
	bsr	do_wrt_cmn_l
@@:					*volume
	move.l	vol_p-work(a6),d1
	beq	@f
	move.l	zmd_addr-work(a6),d0
	tas.b	(a2,d0.l)		*flag on
	moveq.l	#PPC_VOLUME,d0
	bsr	do_wrt_cmn_b
	moveq.l	#0,d0			*offset
	bsr	do_wrt_cmn_l
	moveq.l	#0,d0			*size
	bsr	do_wrt_cmn_l
	move.l	d1,d0			*volume
	bsr	do_wrt_cmn_w
@@:					*truncate
	move.l	cut_offset-work(a6),d1
	move.l	cut_size-work(a6),d2
	move.l	d1,d0
	or.l	d2,d0			*両方ゼロ
	beq	@f
dov2trct:
	move.l	zmd_addr-work(a6),d0
	tas.b	(a2,d0.l)		*flag on
	moveq.l	#PPC_TRUNCATE,d0
	bsr	do_wrt_cmn_b
	move.l	d1,d0			*offset
	bsr	do_wrt_cmn_l
	move.l	d2,d0			*size
	bsr	do_wrt_cmn_l
@@:					*reverse
	tst.b	rv_p-work(a6)
	beq	@f
	move.l	zmd_addr-work(a6),d0
	tas.b	(a2,d0.l)		*flag on
	moveq.l	#PPC_REVERSE,d0
	bsr	do_wrt_cmn_b
	move.l	#0,d0			*offset
	bsr	do_wrt_cmn_l
	move.l	#0,d0			*size
	bsr	do_wrt_cmn_l
@@:					*fade
	move.l	fade_p-work(a6),d1
	beq	@f
	move.l	zmd_addr-work(a6),d0
	tas.b	(a2,d0.l)		*flag on
	moveq.l	#PPC_FADE,d0
	bsr	do_wrt_cmn_b
	move.l	fade_delay-work(a6),d0	*offset
	bsr	do_wrt_cmn_l
	move.l	fade_size-work(a6),d0	*size
	bsr	do_wrt_cmn_l
	move.l	d1,d0			*start level,end level
	bsr	do_wrt_cmn_l
@@:					*mix
	move.l	mix_note-work(a6),d1
	beq	@f
	move.l	mix_delay-work(a6),d2
	move.l	zmd_addr-work(a6),d0
	tas.b	(a2,d0.l)		*flag on
	moveq.l	#PPC_MIX,d0
	bsr	do_wrt_cmn_b
	move.w	d1,d0
	andi.l	#$ffff,d0		*mix note
	bsr	do_wrt_cmn_l
	move.l	d2,d0			*mix delay
	bsr	do_wrt_cmn_l
	moveq.l	#0,d0			*end code
	bsr	do_wrt_cmn_b
@@:
	move.l	zmd_addr-work(a6),d0
	move.b	(a2,d0.l),d1
	beq	@f
	moveq.l	#0,d0			*end code
	bsr	do_wrt_cmn_b
@@:
	move.l	zmd_addr-work(a6),a1	*わざともう一度取り出す
	move.l	a0,d0
	sub.l	a1,d0		*d0.l=次のZMDを格納するオフセットアドレス
	subq.w	#2,d0		*a2.l+2からのオフセットだから
	sub.l	a2,d0		*d0.l=flag.wのd0-d14に入れるべき値
	cmpi.l	#32767,d0
	bls	@f
	moveq.l	#0,d0		*特殊ケース
@@:
	ror.w	#8,d0
	or.b	d1,d0
	move.b	d0,(a2,a1.l)
	ror.w	#8,d0
	move.b	d0,1(a2,a1.l)
	ifndef	sv
	move.l	zmd_addr-work(a6),a1
	move.l	z_cmn_flag(a1),d0
	bset.l	#CMN_REGISTER_PCM/4,d0
	move.l	d0,z_cmn_flag(a1)
	endif
	bra	cmpl_lp

get_frq_rng:
	* < d1.l=-144～+144/0はなし
	* > d1.l=src,dest
	* x d0
	moveq.l	#0,d0
	tst.l	d1
	beq	1f
	bpl	@f
	moveq.l	#-1,d0
	neg.l	d1		*負値は絶対値に
@@:
	subq.l	#1,d1
	cmpi.l	#143,d1
	bhi	m_illegal_pitch_value
	add.l	d1,d1
	move.w	frq_tbl(pc,d1.l),d1
	swap	d1
	move.w	#65280,d1
	tst.l	d0
	bpl	@f
	swap	d1
@@:
	rts
1:
	move.l	#$ff00_ff00,d1
	rts

frq_tbl:
	* for i=1 to 144
	*  frq_tbl=(2^-(i/12))*65280
	* next
	dc.w	61616,58158,54894,51813,48905,46160,43569,41124,38816,36637,34581,32640
	dc.w	30808,29079,27447,25906,24452,23080,21785,20562,19408,18319,17290,16320
	dc.w	15404,14539,13723,12953,12226,11540,10892,10281,9704,9159,8645,8160
	dc.w	7702,7270,6862,6477,6113,5770,5446,5140,4852,4580,4323,4080
	dc.w	3851,3635,3431,3238,3057,2885,2723,2570,2426,2290,2161,2040
	dc.w	1926,1817,1715,1619,1528,1442,1362,1285,1213,1145,1081,1020
	dc.w	963,909,858,810,764,721,681,643,606,572,540,510
	dc.w	481,454,429,405,382,361,340,321,303,286,270,255
	dc.w	241,227,214,202,191,180,170,161,152,143,135,128
	dc.w	120,114,107,101,96,90,85,80,76,72,68,64
	dc.w	60,57,54,51,48,45,43,40,38,36,34,32
	dc.w	30,28,27,25,24,23,21,20,19,18,17,16

get_note_num2:			*ノートナンバーで指定してきたケースの対処
reglist	reg	d0/d3/d5/a2	*ステップ入力タイプ
	movem.l	reglist,-(sp)
	moveq.l	#-1,d5
	bra	@f
get_note_num:			*ノートナンバーで指定してきたケースの対処
	* < d1.l=octave
	* < d2.l=bank number
	* > d2.l=note number
	movem.l	reglist,-(sp)
	moveq.l	#0,d5
@@:
	addq.l	#1,d1
	move.l	d1,d0
	moveq.l	#0,d1
	cmp.l	a4,d4
	bls	err_gnn
	move.b	(a4)+,d1	*A-G
	andi.w	#$df,d1
	subi.w	#'A',d1
	lea	kc_value(pc),a2
	move.b	(a2,d1.w),d1	*d1=0～11(kc)
	mulu	#12,d0		*d0=d0*12
	add.w	d0,d1		*d0=オクターブを考慮したキー値(0～127)
	moveq.l	#0,d3
	bsr	chk_chogo2
	add.w	d3,d2		*d1=real key code
	add.w	d1,d2
	moveq.l	#0,d0
	movem.l	(sp)+,reglist
	rts

err_gnn:
	moveq.l	#-1,d0
	movem.l	(sp)+,reglist
	rts

chk_chogo2:
	* < d3=previous chogo
	* > d3=now chogo
	* x d0
chk_chogo_lp2:			*調号処理
	bsr	skip_spc
	cmp.l	a4,d4
	bls	exit_chogo2
	move.b	(a4),d0
	cmpi.b	#'#',d0
	beq	case_sharp2
	cmpi.b	#'+',d0
	beq	case_sharp2
	cmpi.b	#'-',d0
	bne	exit_chogo2
	tst.l	d5
	beq	case_flat2
	addq.w	#1,a4		*ステップ入力モードにおいて「--1」などのケースに対応
	cmp.l	a4,d4
	bls	@f
	move.b	(a4),d0
	cmpi.b	#'0',d0
	bcs	@f
	cmpi.b	#'9',d0
	bhi	@f
	subq.w	#1,a4
exit_chogo2:
	rts

case_flat2:
	addq.w	#1,a4
@@:
	subq.w	#1,d3		*-1
	bra	chk_chogo_lp2

case_sharp2:
	addq.w	#1,a4
	addq.w	#1,d3		*+1
	bra	chk_chogo_lp2

copy_fn:			*ファイルネームをバッファへ転送
	* < a0.l=destination address
	* < a4=str address
	* < d4=border addr.
	* > minus 拡張子がある
	* > zero  拡張子はなかった
	* - all except d1,d4,a4
	movem.l	d0-d2/a0,-(sp)
	moveq.l	#0,d1
	moveq.l	#0,d2
copy_fnlp01:
	cmp.l	a4,d4
	bls	exit_cfn
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
*cf_patch:			*-C時にパッチが当たる
*	bsr.s	mk_capital
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
	tst.b	d1
	movem.l	(sp)+,d0-d2/a0
	rts

timbre_tone:					*!
timbre_mes:	dc.b	'TIMBRE',0		*!
tone_mes:	dc.b	'TONE',0		*!
		dc.b	'*TIMBRE',0		*!
		dc.b	'*TONE',0		*!
		dc.b	-1
	.even
