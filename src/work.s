***************** ワークエリア *****************
		.even
play_bak_flg:	dc.b	0		*全トラック演奏か否か
OPM:		dc.b	'OPM',0		*自己出力用ファイルネーム
MIDI:		dc.b	'MIDI',0	*自己出力用ファイルネーム
NUL:		dc.b	'NUL     '
ZMSC3_X:	dc.b	'ZMSC3.X',0
pcm_read_flg:	dc.b	0		*ADPCMデータを読んだか(常駐時に必要)
stup_read_flg:	dc.b	0		*START UP FILEを読むかどうか(常駐時に必要)
se_level:	dc.b	0		*ADPCM効果音の優先レベル(default=0)
		.even
r06_0:		dc.b	0		*YM3802 R06(init_midibd時には初期化する)	!!!
r06_1:		dc.b	0		*YM3802 R06(init_midibd時には初期化する)	!!!
wr1:		dc.b	0		*SCC CHA WR1(init_midibd時には初期化する)	!!!
		dc.b	0		*						!!!
stat0:		dc.b	0		*ARS関係のparameter 0	!!(必ず偶数アドレスから)
order0:		dc.b	0		*			!!
stat1:		dc.b	0		*ARS関係のparameter 0	!!
order1:		dc.b	0		*			!!
statr0:		dc.b	0		*ARS関係のparameter 0	!!
orderr0:	dc.b	0		*			!!
statr1:		dc.b	0		*ARS関係のparameter 0	!!
orderr1:	dc.b	0		*			!!

opm_vect:	dc.b	0		*OPMベクタを占有したか
*			        dev mdl
header:		dc.b	$f0,$41,$00,$00,$12	*ROLAND EXCLUSIVE HEADER
exc_addr:	dc.b	0,0,0		*ROLAND EXCLUSIVE ADDRESS
sc_p_data:	dc.b	0		*1 byte転送時に使用
tail:		dc.b	0,$f7		*ROLAND EXCLUSIVE TAIL
tempo_mode:	dc.b	0		*FNC control_tempoのフラグワーク
ctrl_play_work	dc.b	0		*ctrl_playワーク
timer_mask:	dc.b	%0011_1111
excint_flg:	dc.b	0		*割り込み排他フラグ[0]
start_wait_flg:	dc.b	0		*演奏開始($FA)待ちかどうか($00:Waiting,$80:Not Waiting)
f8_start:	dc.b	%0011_1011	*外部シーケンサがホストのときは %0011_1001 になる
f8_stop:	dc.b	%0010_1011	*外部シーケンサがホストのときは %0010_1001 になる


		.even
	.include	zm_stat.mac
	.align	4
	.include	common.mac

sv_trap3:	dc.l	0		*trap #3
copy_org:	dc.l	0		*コピーキー処理ルーチンのオリジナルアドレス
abortjob_org:	dc.l	0		*ABORT処理ルーチンのオリジナルアドレス
mint_vect:	dc.l	0		*MIDI TIMER int vect
eint_vect:	dc.l	0		*PlayBackCounter int vect
rmint_vect:	dc.l	0		*RealtimeMessageRecv int vect
rec_vect:	dc.l	0		*default=0(vector $8a)
rec_vect2:	dc.l	0		*default=0(vector $8a)
mot_vect:	dc.l	0		*m_out int vect
mot_vect2:	dc.l	0		*m_out int vect 2
rs_vect:	dcb.l	8,0		*RS232Cベクタ
out_name:	dc.l	0		*OPM/MIDIどちらへ出力するか
fh_su:		dc.l	0		*ファイルハンドル(START UP FILE組み込み専用)
m_play00_bak:	ds.l	1		*パッチバッファ
dummy_vect:	dc.l	0		*default=0(MPCM組み込み拒否)
adnt_regtype:	dc.l	0		*登録タイプ(下3バイト未使用)
adnt_work:	dc.w	0		*変換処理ありかなしか	!!!ファンクション$10用ワーク
adnt_regnote:	dc.w	0		*登録先ノート番号	!!!
adnt_lp_start:	dc.l	0		*loop start offset	!!!
adnt_lp_end:	dc.l	0		*loop end offset	!!!
adnt_lp_time:	dc.l	0		*loop time		!!!
last_val:	dc.w	0		*0	ADPCM加工処理関係のWORK
_sp_buf:	ds.l	1		*MMLコンパイル/ZMUSIC起動時のスタック保存ワーク
ssp:		dc.l	0		*スーパーバイザスタックの一時退避ワーク
a0work:		dc.l	0		*default=0(汎用ワーク)
a1work:		dc.l	0		*default=0(汎用ワーク)
a2work:		dc.l	0		*default=0(汎用ワーク)
nul_address:	dc.l	0		*NULの存在したアドレス
*timer_i_v:	dc.l	$78_0516	*テンポ＆タイマー初期値
*timer_i_v_se:	dc.l	$78_00d7	*テンポ＆タイマー初期値
v_buffer:	dc.l	0		*汎用バッファアドレス
open_fn:	dc.l	0		*実際にオープンするファイル名の格納アドレス
filename:	dc.l	0		*読み込もうとするファイル名
ctrl_n0:	dc.w	0		*ARSのパラメータ
ctrl_n1:	dc.w	0		*ARSのパラメータ
ctrl_nr0:	dc.w	0		*ARSのパラメータ
ctrl_nr1:	dc.w	0		*ARSのパラメータ
fstmem:		dc.l	0		*メモリ管理ポインタの先頭
jpop_bak:
jpop2_bak:
jpop3_bak:	ds.l	3+3+3		*ジャンプ関連ワーク
jump_flg_ptr:	ds.l	1		*ジャンプ関連ワーク
p_total_ptr:	ds.l	1		*ジャンプ関連ワーク
*mpcm_work:	dc.l	0		*mpcmワークアドレス
estbn:		ds.l	1		*乱数生成用ワークエリア・アドレス
dmy_seq_wk:	ds.l	1		*ダミーシーケンスワークアドレス
done_bit:	ds.l	1		*loop_bsr_opeのワーク
play_bak:	ds.l	1		*m_play()等のパラメータバックアップ
prterr_size:	ds.l	1		*FNC print_error用ワーク
fader_result:	ds.l	1		*fnc$5bワーク0 or -1
jump_flg1:	dc.l	0		*[!] flag	!!
jump_flg2:	dc.l	0		*[@] flag	!!
jump_flg3:	dc.l	0		*[JUMP] flag	!!
dest_measure:	dc.w	0		*destination measure
fopen_name:	ds.l	1		*fopenで取り扱った最後のファイルネーム
ctrl_tempo_bak:	ds.b	8		*FNC control_tempoのパッチバッファ
mask_preserve:	dc.l	0		*MASK初期化Flag([0]:初期化する,$00ff0000:初期化しない($ff on p_mask_mode)
smc_work:	dc.l	0
gyakusan_table:	dc.l	gyakusan_tm_m	*0(NORMAL)	(使用タイマによって書き変わる)
		dc.l	gyakusan_tm_b	*4(SE)		(使用タイマによって書き変わる)
fm_tone_set:	dcb.w	8,-1		*FM音源音色設定ワーク[-1](内容はトラック番号)
mode_patch_bkup:	ds.w	6

adpcm_stop_v:	ds.l	1
adpcmout_v:	ds.l	1
adpcmmod_v:	ds.l	1

exp_tbl:
	dc.l	1000000000
	dc.l	100000000
	dc.l	10000000
	dc.l	1000000
	dc.l	100000
	dc.l	10000
	dc.l	1000
	dc.l	100
	dc.l	10
	dc.l	1

scaleval:
	dc.w	 16,17,19,21,23,25,28
	dc.w	 31,34,37,41,45,50,55
	dc.w	 60,66,73,80,88,97,107
	dc.w	 118,130,143,157,173,190,209
	dc.w	 230,253,279,307,337,371,408
	dc.w	 449,494,544,598,658,724,796
	dc.w	 876,963,1060,1166,1282,1411,1552
levelchg:
	dc.w	-1,-1,-1,-1,2,4,6,8
	dc.w	-1,-1,-1,-1,2,4,6,8

m1_ef_dflt:			*M1デフォルトエフェクトデータ
	dc.b	$0B,$00,$1E,$1E,$00,$19,$19,$00,$00,$1F
	dc.b	$3C,$09,$00,$03,$00,$0A,$00,$00,$00
	dc.b	$1A,$00,$00,$28,$32,$1C,$00,$00,$00

	.even
ZMD:		dc.b	'ZMD',0
ZMS:		dc.b	'ZMS',0
ZPD:		dc.b	'ZPD',0
CNF:		dc.b	'CNF',0
MDD:		dc.b	'MDD',0
PDX:		dc.b	'PDX',0

SPC2:		dc.b	'  ',0
brktedcrlf:	dc.b	')'						*!!!
CRLF:		dc.b	13,10						*!!!
zero:		dc.b	0						*!!!
		dc.b	09		*tab(ERROR CODE表示時に使用)	*!!!順番と位置を
suji:		dcb.b	11,0		*数値表示用			*!!!変えては駄目
suji2:		dcb.b	15,0		*数値表示用2

read_mes1:	dc.b	"Packed ADPCM data '",0
read_mes2:	dc.b	"Start up file '",0
cannot_read:	dc.b	"' couldn't be included.",13,10,0
		dc.b	"'を組み込むことはできませんでした",13,10,0
default_adp:	dc.b	"' has been included.",13,10,0
		dc.b	"'を組み込みました",13,10,0
	.even
stup_zpdfn:	ds.b	96		*スタートアップＺＰＤファイルのファイル名バッファ
stup_fnsv:	ds.b	96		*スタートアップファイルのファイル名バッファ
prsv_work:	ds.b	64		*スタック保存用

*開発に使用した主なツール
*	SUPERED  v1.18		(C)T.Nishikawa
*	HAS v3.09		(C)Y.NAKAMURA
*	HLK v3.01		(C)SALT
*	DB  v3.00		(C)SHARP/Hudson
*	DI  v0.51+13		(C)S.OHYAMA/GORRY,CAT-K
