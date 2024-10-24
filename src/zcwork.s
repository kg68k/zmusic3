work:
*word
sp_buf:		ds.l	1	*コンパイル時のスタック保存ワーク
_sp_buf:	ds.l	1	*起動時のスタック保存ワーク
ssp:		ds.l	1	*スーパバイザスタック保存
dev_end_adr:	ds.l	1	*本プログラムの最終アドレス格納
zmc_work:	ds.l	1	*ZMCワークアドレス
a0work:		dc.l	0	*汎用
a1work:		dc.l	0	*汎用
a2work:		dc.l	0	*汎用
open_fn:	dc.l	0	*実際にオープンするファイル名の格納アドレス
fopen_name:	ds.l	1	*fopenで取り扱った最後のファイルネーム
filename:	dc.l	0	*読み込もうとするファイル名
nul_address:	dc.l	0	*NULLの存在するアドレス
zmd_top:	ds.l	1	*ZMDの存在するアドレス(use in calc_total)
sr_filename:	dc.l	0	*ソースファイルネーム
sv_filename:	dc.l	0	*書き出しファイルネーム
num_of_err:	dc.l	0	*エラーの数
date_buf:	ds.l	1	*書き出しファイルの日付
n_of_err:	ds.l	1	*発生したエラーの数[0]
n_of_warn:	ds.l	1	*発生したウォーニングの数[0]
err_stock_addr:	ds.l	1	*エラーを溜めておくところ
err_stock_size:	ds.l	1	*
err_stock_now:	ds.l	1	*
erfn_addr:	ds.l	1	*エラーが発生したソースのファイル名の格納領域
erfn_size:	ds.l	1
erfn_now:	ds.l	1
*erfn_recent0:	ds.l	1
*erfn_recent1:	ds.l	1
clc_mst_clk:	ds.w	1	*calc_total用マスタークロック
clc_tempo:	ds.w	1	*calc_total用テンポ
clc_play_time:	ds.l	1	*calc_total用演奏時間計算ワーク
_clc_play_time:	ds.l	1	*calc_total用演奏時間計算ワーク(作業用)
clc_trk_base:	ds.l	1	*calc_total用ワーク
clc_ptn_trk:	ds.l	1	*calc_total用ワーク
clc_otlp_step:	ds.l	1	*calc_total用ワーク
clc_ttl_steptime:	ds.l	1	*calc_total用ワーク
clc_ttl_checksum:	ds.l	1	*calc_total用ワーク
tempo_map_addr:	ds.l	1	*calc_total用テンポマップワークアドレス
tempo_map_size:	ds.l	1	*calc_total用テンポマップワークサイズ
compile_option:	ds.l	1	*コンパイラファンクションパラメータ保存
zms_addr:	ds.l	1	*ZMS格納アドレス
zmd_addr:	ds.l	1	*ZMD格納アドレス
zmd_size:	ds.l	1	*ZMD格納バッファサイズ
zmd_end:	ds.l	1	*ZMD格納バッファ最終アドレス
zmd_now:	ds.l	1	*ZMD格納バッファポインタ
ctrl_addr:	ds.l	1	*CTRL-ZMD格納アドレス
ctrl_size:	ds.l	1	*CTRL-ZMD格納バッファサイズ
ctrl_end:	ds.l	1	*CTRL-ZMD格納バッファ最終アドレス
ctrl_now:	ds.l	1	*CTRL-ZMD格納バッファポインタ
ptn_addr:	ds.l	1	*パターントラック管理テーブルアドレス
ptn_size:	ds.l	1	*パターントラック管理テーブルサイズ
ptn_now:	ds.l	1	*パターントラック管理テーブルポインタ
macro_addr:	ds.l	1	*マクロワークアドレス
macro_size:	ds.l	1	*マクロワークサイズ
macro_now:	ds.l	1	*マクロワークポインタ
chgsrc_addr:	ds.l	1	*変換後のソースアドレス
chgsrc_size:	ds.l	1	*変換後のソースサイズ
trkn_addr:	ds.l	1	*トラック番号再割り振り用ワークアドレス
trkn_size:	ds.l	1	*トラック番号再割り振り用ワークサイズ
trkn_end:	ds.l	1	*トラック番号再割り振り用ワーク最終アドレス
trkn_now:	ds.l	1	*トラック番号再割り振り用ワークポインタ
pmr_addr:	ds.l	1	*マクロ変換結果情報ワークアドレス
pmr_size:	ds.l	1
pmr_now:	ds.l	1
pmr_ofs:	ds.l	1	*マクロ名と一致した時のテキストポインタ
pmr_ptr0:	ds.l	1	*マクロ名と一致した時のテキストポインタ
pmr_ptr1:	ds.l	1	*マクロ名と一致した時のテキストポインタ
pmr_cr:		ds.l	1	*マクロによってずれた改行数
pmr_rvs_start:	ds.l	1
line_ptr:	ds.l	1	*ソース行番号[0]
line_number:	ds.l	1	*ソース行番号[0]
line_locate:	ds.l	1	*ソース行位置[0]
line_backup:	ds.l	4	*ソース行情報バックアップ
trk_inf_tbl:	ds.l	1	*トラック情報テーブルの一時格納ワーク(new_gtr:参照)
tit_size:	ds.l	1
tit_now:	ds.l	1
ti_link_offset:	ds.l	1	*トラック情報テーブルのリンク形成ワーク[0]
t_trk_no:	ds.l	1	*複数同時書き込み(t)用トラック番号バッファ
compile_phase:	dc.b	0	*コンパイラが今どのフェーズを処理しているか([0],1)	 !!!
compile_status:	dc.b	0	*コンパイル結果に関するレポート(d7:W使用,d6:ｼﾞｬﾝﾌﾟ系使用)!!!
n_of_track:	dc.w	0	*演奏に使用するトラック数[0]				 !!!
trk_ptr_tbl:	ds.l	1	*トラックバッファ管理テーブル
trk_n_max:	ds.w	1	*管理出来るトラック最大数[16]
current_trk_ptr:	ds.l	1
csa_regnote:	ds.l	1	*ADPCM登録コマンドワーク
csa_regtype:	ds.l	1	*ADPCM登録コマンドワーク
mix_note:	ds.l	1	*ADPCM登録コマンドワーク
mix_delay:	ds.l	1	*ADPCM登録コマンドワーク
pitch_p:	ds.l	1	*ADPCM登録コマンドワーク
vol_p:		ds.l	1	*ADPCM登録コマンドワーク
fade_p:		ds.l	1	*ADPCM登録コマンドワーク
fade_delay:	ds.l	1	*ADPCM登録コマンドワーク
fade_size:	ds.l	1	*ADPCM登録コマンドワーク
cut_offset:	ds.l	1	*ADPCM登録コマンドワーク
cut_size:	ds.l	1	*ADPCM登録コマンドワーク
now_cmd:	ds.b	1	*0:()系 $80:.系か 2:MML系か 1:行単位コンパイル [0]
ptn_cmd:	ds.b	1	*patternトラック定義コマンド実行中か[0]=no
adpcm_bank:	ds.w	1	*ADPCMバンク番号[0]
zms_file_id:	ds.l	1	*ソースファイルネームID([0],1,2,...)
include_depth:	ds.l	1	*インクルードの深さ
step_input:	dc.b	0	*ステップ入力ツールモードか[0]:no,[$ff]:yes	!!!
assign_done:	ds.b	1	*assignが行われたかどうか			!!!
jump_cmd_ctrl:	dc.b	1	*jumpコマンド系の生成制御 [1]=ENABLE		!!!
velo_vol_ctrl:	dc.b	0	*_~を相対ベロシティとするか[0]=no,nz=yes	!!!
dev_mdl_ID:	ds.b	2*if_max	*devIDとmdlIDの保存ワーク
n_of_ptn:	ds.l	1	*定義されたパターンの個数
temp_buffer:	ds.l	1	*一時的な作業エリア
arry_stock:	ds.l	1	*パラメータ数値の一時的保存バッファ
*tpt_backup:	ds.l	1	*tpt_ワークのバックアップ(連符処理2パス用)
step_buf:	ds.l	1	*ステップタイムワーク(最上位バイトはフラグ)
gate_buf:	ds.l	1	*ゲートタイムワーク(最上位バイトはフラグ)
auto_comment:	dc.b	0	*自動コメント生成モード[1]:on		!
seq_cmd:	dc.b	0	*[]系コマンドか[0]:no			!
gate_range:	dc.b	0	*Qコマンドの最大値[8]			!
gate_shift:	dc.b	0	*Qコマンドの最大値=2^n[3]		!
rel_cmplr_mark:	ds.l	1	*コンパイラ解放ルーチンのマーク(application_releaserで使用)
src_address:	ds.l	1	*ソースアドレス
src_size:	ds.l	1	*ソースサイズ
rcgz_addr:	ds.l	1	*calc_totalに置いて現在処理しているtrack先頭address
assign_bracket:			*			#
port_bracket:	ds.b	1	*ポルタメントMMLの括弧	#
port_zmd:	ds.b	1	*ポルタメントのZMD	#
clc_trkfrq:	ds.w	1	*calc_total内で使用するtrkfrqコピー
asgn_trk_s:	ds.l	1	*.assignワーク
asgn_trk_e:	ds.l	1	*.assignワーク
asgn_ch_s:	ds.l	1	*.assignワーク
asgn_ch_e:	ds.l	1	*.assignワーク
err_cache:	ds.b	16	*エラー情報のキャッシュ
a4_preserve:	ds.l	1	*マクロ処理内でのa4レジスタ保存領域
mcrnm_hash_tbl:	ds.l	1	*マクロネームハッシュテーブル
reg_n:		ds.w	1
list_mode:	dc.b	0	*.list,.nlist処理ワーク[0]:normal		!
fxgt_mode:	dc.b	0	*fixed gatetime mode [0]:fxgt>step 1:fxgt<step	!
v2_compatch:	dc.b	0	*V2コンパチコンパイルか(0:no 1:yes)		!
		dc.b	0	*						!
clc_phase:	ds.b	1		*calc_totalの処理PHASE([0]:tempo map作成,1:各種計算)@
dlp_clc_flg:	ds.b	1		*do-loopがあったか無かったか([0]:なかった,1:あった) @


*const
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

real_ch_tbl:	*V2互換のため
	dc.l	$0000_0000,$0000_0001,$0000_0002,$0000_0003	*FM
	dc.l	$0000_0004,$0000_0005,$0000_0006,$0000_0007
	dc.l	$0001_0000					*ADPCM1
	dc.l	$8000_0000,$8000_0001,$8000_0002,$8000_0003	*MIDI
	dc.l	$8000_0004,$8000_0005,$8000_0006,$8000_0007
	dc.l	$8000_0008,$8000_0009,$8000_000a,$8000_000b
	dc.l	$8000_000c,$8000_000d,$8000_000e,$8000_000f
	dc.l	$0001_0001,$0001_0002,$0001_0003		*ADPCM2-8
	dc.l	$0001_0004,$0001_0005,$0001_0006,$0001_0007
v2_ch_tbl:	*V2互換のため
	dc.l	$0000_0000,$0000_0001,$0000_0002,$0000_0003	*FM
	dc.l	$0000_0004,$0000_0005,$0000_0006,$0000_0007
	dc.l	$0001_0000					*ADPCM1
	dc.l	$8000_0000,$8000_0001,$8000_0002,$8000_0003	*MIDI
	dc.l	$8000_0004,$8000_0005,$8000_0006,$8000_0007
	dc.l	$8000_0008,$8000_0009,$8000_000a,$8000_000b
	dc.l	$8000_000c,$8000_000d,$8000_000e,$8000_000f
	dc.l	$0001_0001,$0001_0002,$0001_0003		*ADPCM2-8
	dc.l	$0001_0004,$0001_0005,$0001_0006,$0001_0007

*byte
zmusic_stat:	ds.b	1		*ZMUSICは常駐しているか
		ds.b	1
errmes_lang:	dc.b	0		*0:English 1:Japanese
max_err_num:	ds.b	1		*エラーがこの値を超えるとコンパイル中止
v_buffer:	ds.b	55		*音色パラメータバッファ
rv_p:		ds.b	1		*ADPCM登録コマンドワーク
nt_buf:		ds.b	1		*ノート番号退避
vl_buf:		ds.b	1		*ベロシティワーク
oct_wk:		ds.b	1		*オクターブワーク
wave_param_flg:	ds.b	1		*波形メモリ登録コマンドのパラメータ省略フラグ
exclusive_flg:	ds.b	1		*Exclusive MIDIコマンドか0:no
zmc_call:	dc.b	0		*ZMC.Xの最新利用ファンクション番号
adpcm_default_ch:	ds.b	1	*V2式ADPCMチャンネルアサイン対応ワーク
disp_mode:	dc.b	1		*表示 0:no [1]:yes
compile_type:	dc.b	0		*[0]:filename mode -1:addr. compile 1:addr. calc
get_src_fn:	dc.b	0		*ファイル名を取り込んだかどうか [0]:not yes/1:done
link_switch:	dc.b	0		*-Lオプション
warn_flg:	dc.b	0		*Warningフラグ[0]:on
v2_mode:	dc.b	0		*起動時に'-2'が指定されたか([0]:no,$ff:yes)

*const data
*			 AF  OM  WF  SY  SP PMD AMD PMS AMS PAN DMY
std_55:		dc.b	 63, 15,  3,  1,255,127,127,  7,  3,  3,  0
alfb_55:	rept	4
*			 AR  DR  SR  RR  SL  OL  KS  ML DT1 DT2 AME
		dc.b	 31, 31, 31, 15, 15,127,  3, 15,  7,  3,  1
		endm 
*			 CON FBL OM PAN WF SYC SPD PMD AMD PMS AMS
		dc.b	   7,  7,15,  3, 3,  1,255,127,127,  7,  3
*strings data
CRLF:		dc.b	13,10,0		*!
ZMD:		dc.b	'ZMD',0
ZMS:		dc.b	'ZMS',0
ZPD:		dc.b	'ZPD',0
		dc.b	09		*tab(ERROR CODE表示時に使用)	!!!順番と位置を
suji:		dcb.b	11,0		*数値表示用			!!!変えては駄目
suji2:		dcb.b	15,0		*数値表示用(桁揃え)
*abslen:		dc.b	'*'		*絶対音長指定記号
track_stat_cmdln:	dc.b	'PLAY',0,'RECORD',0,-1
track_mode_cmdln:	dc.b	'NORMAL',0,'RHYTHM',0,-1
rhythm_timbre_tone:	dc.b	'RHYTHM',0		*!
			dc.b	'TIMBRE',0,'TONE',0,-1		*!
NUL:		dc.b	'NUL     '
kaijo:		dc.b	'Z-MUSIC COMPILER has been released from the system.',13,10,0
kaijo_j:	dc.b	'Z-MUSICコンパイラを常駐解除しました',13,10,0
kaijo_er:	dc.b	'Z-MUSIC COMPILER is unable to release.',13,10,0
kaijo_er_j:	dc.b	'Z-MUSICコンパイラは解除出来ません',13,10,0
MJMN_tbl:	dc.b	'MAJOR',0,'MINOR',0,-1
KEY_tbl:	dc.b	'CMAJOR',0
		dc.b	'GMAJOR',0
		dc.b	'DMAJOR',0
		dc.b	'AMAJOR',0
		dc.b	'EMAJOR',0
		dc.b	'BMAJOR',0
		dc.b	'F+MAJOR',0
		dc.b	'F#MAJOR',0
		dc.b	'C+MAJOR',0
		dc.b	'C#MAJOR',0

		dc.b	'CMAJOR',0
		dc.b	'FMAJOR',0
		dc.b	'B-MAJOR',0
		dc.b	'BBMAJOR',0
		dc.b	'E-MAJOR',0
		dc.b	'EBMAJOR',0
		dc.b	'A-MAJOR',0
		dc.b	'ABMAJOR',0
		dc.b	'D-MAJOR',0
		dc.b	'DBMAJOR',0
		dc.b	'G-MAJOR',0
		dc.b	'GBMAJOR',0
		dc.b	'C-MAJOR',0
		dc.b	'CBMAJOR',0

		dc.b	'AMINOR',0
		dc.b	'EMINOR',0
		dc.b	'BMINOR',0
		dc.b	'F+MINOR',0
		dc.b	'F#MINOR',0
		dc.b	'C+MINOR',0
		dc.b	'C#MINOR',0
		dc.b	'G+MINOR',0
		dc.b	'G#MINOR',0
		dc.b	'D+MINOR',0
		dc.b	'D#MINOR',0
		dc.b	'A+MINOR',0
		dc.b	'A#MINOR',0

		dc.b	'AMINOR',0
		dc.b	'DMINOR',0
		dc.b	'GMINOR',0
		dc.b	'CMINOR',0
		dc.b	'FMINOR',0
		dc.b	'B-MINOR',0
		dc.b	'BBMINOR',0
		dc.b	'E-MINOR',0
		dc.b	'EBMINOR',0
		dc.b	'A-MINOR',0
		dc.b	'ABMINOR',0
		dc.b	-1
mstrfadr_dev:
	dc.b	'ALL',0			*0
	dc.b	'FM',0			*1
	dc.b	'ADPCM',0		*2
	dc.b	'MIDI1',0		*3
	dc.b	'MIDI2',0		*4
	dc.b	'MIDI3',0		*5
	dc.b	-1

mmlstop_mode:
trkfadr_dev:
msktrk_dev:
	dc.b	'ALL',0			*0
	dc.b	-1

chfdr_dev:
	dc.b	'ALL',0			*0
	dc.b	'FM-ALL',0		*1
	dc.b	'ADPCM-ALL',0		*2
	dc.b	'MIDI1-ALL',0		*3
	dc.b	'MIDI2-ALL',0		*4
	dc.b	'MIDI3-ALL',0		*5
	dc.b	-1

msktrk_mode:
	dc.b	'OFF',0
	dc.b	'ON',0
	dc.b	'REVERSE',0
	dc.b	-1

vib_mode:				*[VIBRAO.MODE]パラメータ
	dc.b	'NORMAL',0
	dc.b	'FM',0
	dc.b	'MIDI',0
	dc.b	-1

krmp_strv:				*[KEY_REMAP]
noise_strv:				*[NOISE]
sltmsk_strv:				*[SLOT_SEPARATION]
echo_strv:				*[ECHO]
	dc.b	'OFF',0
	dc.b	-1

vibdpn_strv:				*[VIBRATO.DEEPEN]
agogik_sync:				*[AGOGIK.SYNC]パラメータ
arcc_sync:				*[ARCCn.SYNC]パラメータ
vib_sync:				*[VIBRAO.SYNC]パラメータ
vseq_sync:				*[VELOCITY.SYNC]パラメータ
switch_strv:				*[***.SWITCH]パラメータ
	dc.b	'OFF',0
	dc.b	'ON',0
	dc.b	-1

switch_strv2:				*[***.LEVEL/DEPTH]パラメータ
	dc.b	'1/8',0			*-1
	dc.b	'OFF',0			*0
	dc.b	'OPTIONAL',0		*1
	dc.b	'ON',0			*2
	dc.b	-1

switch_strv3:				*[***.SWITCH]パラメータ
	dc.b	'1/8',0			*-1
	dc.b	'STOP',0		*0
	dc.b	'OPTIONAL',0		*1
	dc.b	'ON',0			*2
	dc.b	'OFF',0			*3
	dc.b	-1

wvfm_tbl:				*波形テーブル
	dc.b	'SAW',0			*0
	dc.b	'SQUARE',0		*1
	dc.b	'TRIANGLE',0		*2
	dc.b	'S.SAW',0		*3
	dc.b	'RANDOM',0		*4
	dc.b	-1

iptmd_tbl:
	dc.b	'MML',0
	dc.b	'STEP',0
	dc.b	-1

arccmd_tbl:				*[ARCCn.MODE]パラメータ
tiemd_tbl:				*[TIE_MODE]パラメータ
	dc.b	'NORMAL',0
	dc.b	'SPECIAL',0
	dc.b	'ENHANCED',0		*SPECIALとENHANCEDは同義
	dc.b	-1

phase_tbl:
	dc.b	'NORMAL',0
	dc.b	'INVERSE',0
	dc.b	'REVERSE',0
	dc.b	-1

en_ds_tbl:
	dc.b	'DISABLE',0
	dc.b	'ENABLE',0
	dc.b	-1

rltvvlcty_tbl:
	dc.b	'~_',0
	dc.b	'_~',0
	dc.b	'@U',0
	dc.b	'U',0
	dc.b	-1

vibdpnlp_strv:
mechlp_strv:
	dc.b	'LOOP',0
	dc.b	-1

category_strv:
	dc.b	'WORD',0
	dc.b	'PICTURE',0
	dc.b	'SOUND',0
	dc.b	-1

class0_strv:
	dc.b	'STRING',0
	dc.b	-1

class1_strv:
	dc.b	'PIC',0
	dc.b	-1

class2_strv:
	dc.b	'ADPCM',0
	dc.b	-1

opm_wf_name:				*波形テーブル
	dc.b	'SAW',0			*0
	dc.b	'SQUARE',0		*1
	dc.b	'TRIANGLE',0		*2
	dc.b	'RANDOM',0		*3
	dc.b	-1

wvfm_name:
	dc.b	'1SHOT',0		*0
	dc.b	'REPEAT',0		*1
	dc.b	'ALTERNATE',0		*2

sc88_drmmap_strv:
	dc.b	'USER65',0
	dc.b	'USER66',0
	dc.b	-1

list_str:
	dc.b	'.LIST',0
	dc.b	-1

fxgt_str:
	dc.b	'STEPTIME',0
	dc.b	-1

control_name:		dc.b	'BANK_MSB',0			*0
			dc.b	'VIBRATO',0			*1
			dc.b	'CTRL2',0			*2
			dc.b	'CTRL3',0			*3
			dc.b	'CTRL4',0			*4
			dc.b	'PORTAMENT_TIME',0		*5
			dc.b	'DATA_ENTRY_MSB',0		*6
			dc.b	'VOLUME',0			*7
			dc.b	'CTRL8',0			*8
			dc.b	'CTRL9',0			*9
			dc.b	'PANPOT',0			*10
			dc.b	'EXPRESSION',0			*11
			dc.b	'CTRL12',0			*12
			dc.b	'CTRL13',0			*13
			dc.b	'CTRL14',0			*14
			dc.b	'CTRL15',0			*15
			dc.b	'CTRL16',0			*16
			dc.b	'CTRL17',0			*17
			dc.b	'CTRL18',0			*18
			dc.b	'CTRL19',0			*19
			dc.b	'CTRL20',0			*20
			dc.b	'CTRL21',0			*21
			dc.b	'CTRL22',0			*22
			dc.b	'CTRL23',0			*23
			dc.b	'CTRL24',0			*24
			dc.b	'CTRL25',0			*25
			dc.b	'CTRL26',0			*26
			dc.b	'CTRL27',0			*27
			dc.b	'CTRL28',0			*28
			dc.b	'CTRL29',0			*29
			dc.b	'CTRL30',0			*30
			dc.b	'CTRL31',0			*31
			dc.b	'BANK_LSB',0			*32
			dc.b	'CTRL33',0			*33
			dc.b	'CTRL34',0			*34
			dc.b	'CTRL35',0			*35
			dc.b	'CTRL36',0			*36
			dc.b	'DATA_ENTRY_LSB',0		*37
			dc.b	'CTRL31',0			*38
			dc.b	'CTRL39',0			*39
			dc.b	'CTRL40',0			*40
			dc.b	'CTRL41',0			*41
			dc.b	'CTRL42',0			*42
			dc.b	'CTRL43',0			*43
			dc.b	'CTRL44',0			*44
			dc.b	'CTRL45',0			*45
			dc.b	'CTRL46',0			*46
			dc.b	'CTRL47',0			*47
			dc.b	'CTRL48',0			*48
			dc.b	'CTRL49',0			*49
			dc.b	'CTRL50',0			*50
			dc.b	'CTRL51',0			*51
			dc.b	'CTRL52',0			*52
			dc.b	'CTRL53',0			*53
			dc.b	'CTRL54',0			*54
			dc.b	'CTRL55',0			*55
			dc.b	'CTRL56',0			*56
			dc.b	'CTRL57',0			*57
			dc.b	'CTRL58',0			*58
			dc.b	'CTRL59',0			*59
			dc.b	'CTRL60',0			*60
			dc.b	'CTRL61',0			*61
			dc.b	'CTRL62',0			*62
			dc.b	'CTRL63',0			*63
			dc.b	'DAMPER',0			*64
			dc.b	'PORTAMENT',0			*65
			dc.b	'SOSTENUTO',0			*66
			dc.b	'SOFT',0			*67
			dc.b	'CTRL68',0			*68
			dc.b	'FREEZE',0			*69
			dc.b	'CTRL70',0			*70
			dc.b	'CTRL71',0			*71
			dc.b	'CTRL72',0			*72
			dc.b	'CTRL73',0			*73
			dc.b	'CTRL74',0			*74
			dc.b	'CTRL75',0			*75
			dc.b	'CTRL76',0			*76
			dc.b	'CTRL77',0			*77
			dc.b	'CTRL78',0			*78
			dc.b	'CTRL79',0			*79
			dc.b	'CTRL80',0			*80
			dc.b	'CTRL81',0			*81
			dc.b	'CTRL82',0			*82
			dc.b	'CTRL83',0			*83
			dc.b	'PORTAMENT_CONTROL',0		*84
			dc.b	'CTRL85',0			*85
			dc.b	'CTRL86',0			*86
			dc.b	'CTRL87',0			*87
			dc.b	'CTRL88',0			*88
			dc.b	'CTRL89',0			*89
			dc.b	'CTRL90',0			*90
			dc.b	'REVERB',0			*91
			dc.b	'TREMOLO',0			*92
			dc.b	'CHORUS',0			*93
			dc.b	'DELAY',0			*94
			dc.b	'PHASER',0			*95
			dc.b	'DATA_INCREMENT',0		*96
			dc.b	'DATA_DECREMENT',0		*97
			dc.b	'NRPN_LSB',0			*98
			dc.b	'NRPN_MSB',0			*99
			dc.b	'RPN_LSB',0			*100
			dc.b	'RPN_MSB',0			*101
			dc.b	'CTRL102',0			*102
			dc.b	'CTRL103',0			*103
			dc.b	'CTRL104',0			*104
			dc.b	'CTRL105',0			*105
			dc.b	'CTRL106',0			*106
			dc.b	'CTRL107',0			*107
			dc.b	'CTRL108',0			*108
			dc.b	'CTRL109',0			*109
			dc.b	'CTRL110',0			*110
			dc.b	'CTRL111',0			*111
			dc.b	'CTRL112',0			*112
			dc.b	'CTRL113',0			*113
			dc.b	'CTRL114',0			*114
			dc.b	'CTRL115',0			*115
			dc.b	'CTRL116',0			*116
			dc.b	'CTRL117',0			*117
			dc.b	'CTRL118',0			*118
			dc.b	'CTRL119',0			*119
			dc.b	'ALL_SOUND_OFF',0		*120
			dc.b	'RESET_ALL_CONTROLLERS',0	*121
			dc.b	'LOCAL',0			*122
			dc.b	'ALL_NOTES_OFF',0		*123
			dc.b	'OMNI_OFF',0			*124
			dc.b	'OMNI_ON',0			*125
			dc.b	'MONO',0			*126
			dc.b	'POLY',0			*127
			dc.b	-1
control_name2:
			dc.b	'FM.PANPOT',0			*$80
			dc.b	'FM.PMS',0			*$81
			dc.b	'FM.AMS',0			*$82
			dc.b	'*',0				*$83
			dc.b	'FM.AMD',0			*$84
			dc.b	'FM.PMD',0			*$85
			dc.b	'FM.LFO',0			*$86
			dc.b	'FM.NOISE',0			*$87
			dc.b	-1

opm_op_name:
	dc.b	'OP1.',0	*0
	dc.b	'OP3.',0	*1
	dc.b	'OP2.',0	*2
	dc.b	'OP4.',0	*3
	dc.b	'NFRQ',0	*4
	dc.b	'NE',0		*5
	dc.b	'LFRQ',0	*6
	dc.b	'PMD',0		*7
	dc.b	'AMD',0		*8
	dc.b	'WF',0		*9
	dc.b	'CON',0		*10
	dc.b	'FB',0		*11
	dc.b	'PAN',0		*12
	dc.b	'AMS',0		*13
	dc.b	'PMS',0		*14
	dc.b	-1

opm_op_name2:
	dc.b	'1.',0		*0
	dc.b	'3.',0		*1
	dc.b	'2.',0		*2
	dc.b	'4.',0		*3
	dc.b	'NFRQ',0	*4
	dc.b	'NE',0		*5
	dc.b	'LFRQ',0	*6
	dc.b	'PMD',0		*7
	dc.b	'AMD',0		*8
	dc.b	'WF',0		*9
	dc.b	'AL',0		*10
	dc.b	'FB',0		*11
	dc.b	'PAN',0		*12
	dc.b	'AMS',0		*13
	dc.b	'PMS',0		*14
	dc.b	-1

opm_reg_name:
	dc.b	'MUL',0		*0
	dc.b	'DT1',0		*1
	dc.b	'TL',0		*2
	dc.b	'AR',0		*3
	dc.b	'KS',0		*4
	dc.b	'1DR',0		*5
	dc.b	'AMS-EN',0	*6
	dc.b	'2DR',0		*7
	dc.b	'DT2',0		*8
	dc.b	'RR',0		*9
	dc.b	'1DL',0		*10
	dc.b	-1

opm_reg_name2:
	dc.b	'MLT',0		*0
	dc.b	'DT',0		*1
	dc.b	'TL',0		*2
	dc.b	'AR',0		*3
	dc.b	'KS',0		*4
	dc.b	'D1R',0		*5
	dc.b	'AM-E',0	*6
	dc.b	'D2R',0		*7
	dc.b	'DT2',0		*8
	dc.b	'RR',0		*9
	dc.b	'D1L',0		*10
	dc.b	-1

opm_reg_name3:
	dc.b	'ML',0		*0
	dc.b	'D1',0		*1
	dc.b	'OL',0		*2
	dc.b	'AR',0		*3
	dc.b	'RS',0		*4
	dc.b	'DR',0		*5
	dc.b	'AME',0		*6
	dc.b	'SR',0		*7
	dc.b	'D2',0		*8
	dc.b	'RR',0		*9
	dc.b	'SL',0		*10
	dc.b	-1

shp_com_tbl:	*共通コマンド
	dc.b	'16BITPCM_TIMBRE',0
	dc.b	'16BITPCM_TONE',0
	dc.b	'8BITPCM_TIMBRE',0
	dc.b	'8BITPCM_TONE',0
	dc.b	'ADPCM_BANK',0
	dc.b	'ADPCM_BLOCK_DATA',0
	dc.b	'ADPCM_LIST',0
	dc.b	'ADPCM_TIMBRE',0
	dc.b	'ADPCM_TONE',0
	dc.b	'ADPCM_TUNE_SETUP',0
	dc.b	'ASSIGN',0
	dc.b	'CNF',0
	dc.b	'CALL',0
	dc.b	'COMMENT',0
	dc.b	'CONTINUE',0
	dc.b	'CURRENT_MIDI_IN',0
	dc.b	'CURRENT_MIDI_OUT',0
	dc.b	'DEFINE',0
	dc.b	'DUMMY',0
	dc.b	'ERASE_TONE',0
	dc.b	'ERASE_TIMBRE',0
	dc.b	'ERASE',0
	dc.b	'EXCLUSIVE',0
	dc.b	'FIXED_GATETIME',0
	dc.b	'FM_MASTER_VOLUME',0
	dc.b	'FM_TIMBRE',0
	dc.b	'FM_TUNE_SETUP',0
	dc.b	'FM_VSET',0
	dc.b	'GATETIME_RESOLUTION',0
	dc.b	'GM_SYSTEM_ON',0
	dc.b	'GS_CHORUS',0
	dc.b	'GS_DISPLAY',0
	dc.b	'GS_DRUM_SETUP',0
	dc.b	'GS_DRUM_PARAMETER',0
	dc.b	'GS_DRUM_NAME',0
	dc.b	'GS_INIT',0
	dc.b	'GS_PARTIAL_RESERVE',0
	dc.b	'GS_PART_SETUP',0
	dc.b	'GS_PART_PARAMETER',0
	dc.b	'GS_PRINT',0
	dc.b	'GS_RESET',0
	dc.b	'GS_REVERB',0
	dc.b	'GS_V_RESERVE',0
	dc.b	'HALT',0
	dc.b	'INCLUDE',0
	dc.b	'INITIALIZE',0
	dc.b	'JUMP',0
	dc.b	'KEY',0
	dc.b	'LENGTH_MODE',0
	dc.b	'LIST',0
	dc.b	'M1_EFFECT_SETUP',0
	dc.b	'M1_MIDI_CH',0
	dc.b	'M1_PART_SETUP',0
	dc.b	'M1_PRINT',0
	dc.b	'M1_SETUP',0
	dc.b	'MASTER_CLOCK',0
	dc.b	'MASTER_FADER',0
	dc.b	'METER',0
	dc.b	'MIDI_DATA',0
	dc.b	'MIDI_DUMP',0
	dc.b	'MT32_COMMON',0
	dc.b	'MT32_DRUM_SETUP',0
	dc.b	'MT32_INIT',0
	dc.b	'MT32_PARTIAL_RESERVE',0
	dc.b	'MT32_PARTIAL',0
	dc.b	'MT32_PART_SETUP',0
	dc.b	'MT32_PATCH',0
	dc.b	'MT32_P_RESERVE',0
	dc.b	'MT32_PRINT',0
	dc.b	'MT32_RESET',0
	dc.b	'MT32_REVERB',0
	dc.b	'MT32_RHYTHM_SETUP',0
	dc.b	'NLIST',0
	dc.b	'O',0
	dc.b	'PATTERN',0
	dc.b	'PCM_TUNE_SETUP',0
	dc.b	'PERFORMANCE_TIME',0
	dc.b	'PLAY',0
	dc.b	'PRINT',0
	dc.b	'RELATIVE_VELOCITY',0
	dc.b	'ROLAND_EXCLUSIVE',0
	dc.b	'SC55_CHORUS',0
	dc.b	'SC55_DISPLAY',0
	dc.b	'SC55_DRUM_SETUP',0
	dc.b	'SC55_DRUM_PARAMETER',0
	dc.b	'SC55_DRUM_NAME',0
	dc.b	'SC55_INIT',0
	dc.b	'SC55_PARTIAL_RESERVE',0
	dc.b	'SC55_PART_SETUP',0
	dc.b	'SC55_PART_PARAMETER',0
	dc.b	'SC55_PRINT',0
	dc.b	'SC55_REVERB',0
	dc.b	'SC55_RESET',0
	dc.b	'SC55_V_RESERVE',0
	dc.b	'SC88_MODE_SET',0
	dc.b	'SC88_MODE',0
	dc.b	'SC88_REVERB',0
	dc.b	'SC88_CHORUS',0
	dc.b	'SC88_DELAY',0
	dc.b	'SC88_EQUALIZER',0
	dc.b	'SC88_PART_SETUP',0
	dc.b	'SC88_PART_PARAMETER',0
	dc.b	'SC88_DRUM_SETUP',0
	dc.b	'SC88_DRUM_PARAMETER',0
	dc.b	'SC88_DRUM_NAME',0
	dc.b	'SC88_USER_INST',0
	dc.b	'SC88_USER_DRUM',0
	dc.b	'SEND_TO_M1',0
	dc.b	'SMF',0
	dc.b	'STOP',0
	dc.b	'TEMPO',0
	dc.b	'TRACK_FADER',0
	dc.b	'TRACK_MASK',0
	dc.b	'TRACK',0
	dc.b	'U220_COMMON',0
	dc.b	'U220_DRUM_INST',0
	dc.b	'U220_DRUM_SETUP',0
	dc.b	'U220_PART_SETUP',0
	dc.b	'U220_PRINT',0
	dc.b	'U220_SETUP',0
	dc.b	'U220_TIMBRE',0
	dc.b	'WAVE_FORM',0
	dc.b	'WAVEFORM',0
	dc.b	'YAMAHA_BULKDUMP',0
	dc.b	'YAMAHA_EXCLUSIVE',0
	dc.b	'ZPD',0
	dc.b	-1

ksign__:	equ	14
seq_com_tbl:				*［］コマンド系
			dc.b	'!',0
			dc.b	'$',0
			dc.b	'*',0
			dc.b	'/',0
			dc.b	'@DETUNE',0
			dc.b	'@PANPOT',0
			dc.b	'@PITCH',0
			dc.b	'@TEMPO',0
			dc.b	'@VELOCITY',0
			dc.b	'@VOLUME',0
			dc.b	'@',0
			dc.b	'AFTERTOUCH.DELAY',0
			dc.b	'AFTERTOUCH.LEVEL',0
			dc.b	'AFTERTOUCH.SWITCH',0
			dc.b	'AFTERTOUCH.SYNC',0
			dc.b	'AGOGIK.DEEPEN',0
			dc.b	'AGOGIK.DELAY',0
			dc.b	'AGOGIK.DEPTH',0
			dc.b	'AGOGIK.LEVEL',0
			dc.b	'AGOGIK.SPEED',0
			dc.b	'AGOGIK.SWITCH',0
			dc.b	'AGOGIK.SYNC',0
			dc.b	'AGOGIK.WAVEFORM',0
			dc.b	'ALL_SOUND_OFF',0
			dc.b	'ARCC1.CONTROL',0
			dc.b	'ARCC2.CONTROL',0
			dc.b	'ARCC3.CONTROL',0
			dc.b	'ARCC4.CONTROL',0
			dc.b	'ARCC1.DEEPEN',0
			dc.b	'ARCC2.DEEPEN',0
			dc.b	'ARCC3.DEEPEN',0
			dc.b	'ARCC4.DEEPEN',0
			dc.b	'ARCC1.DELAY',0
			dc.b	'ARCC2.DELAY',0
			dc.b	'ARCC3.DELAY',0
			dc.b	'ARCC4.DELAY',0
			dc.b	'ARCC1.DEPTH',0
			dc.b	'ARCC2.DEPTH',0
			dc.b	'ARCC3.DEPTH',0
			dc.b	'ARCC4.DEPTH',0
			dc.b	'ARCC1.LEVEL',0
			dc.b	'ARCC2.LEVEL',0
			dc.b	'ARCC3.LEVEL',0
			dc.b	'ARCC4.LEVEL',0
			dc.b	'ARCC1.MODE',0
			dc.b	'ARCC2.MODE',0
			dc.b	'ARCC3.MODE',0
			dc.b	'ARCC4.MODE',0
			dc.b	'ARCC1.ORIGIN',0
			dc.b	'ARCC2.ORIGIN',0
			dc.b	'ARCC3.ORIGIN',0
			dc.b	'ARCC4.ORIGIN',0
			dc.b	'ARCC1.PHASE',0
			dc.b	'ARCC2.PHASE',0
			dc.b	'ARCC3.PHASE',0
			dc.b	'ARCC4.PHASE',0
			dc.b	'ARCC1.RESET',0
			dc.b	'ARCC2.RESET',0
			dc.b	'ARCC3.RESET',0
			dc.b	'ARCC4.RESET',0
			dc.b	'ARCC1.SPEED',0
			dc.b	'ARCC2.SPEED',0
			dc.b	'ARCC3.SPEED',0
			dc.b	'ARCC4.SPEED',0
			dc.b	'ARCC1.SWITCH',0
			dc.b	'ARCC2.SWITCH',0
			dc.b	'ARCC3.SWITCH',0
			dc.b	'ARCC4.SWITCH',0
			dc.b	'ARCC1.SYNC',0
			dc.b	'ARCC2.SYNC',0
			dc.b	'ARCC3.SYNC',0
			dc.b	'ARCC4.SYNC',0
			dc.b	'ARCC1.WAVEFORM',0
			dc.b	'ARCC2.WAVEFORM',0
			dc.b	'ARCC3.WAVEFORM',0
			dc.b	'ARCC4.WAVEFORM',0
			dc.b	'ASSIGN',0
			dc.b	'AUTO_PORTAMENT.SWITCH',0
			dc.b	'AUTO_PORTAMENT',0
			dc.b	'BAR',0
			dc.b	'BEND.RANGE',0
			dc.b	'BEND.SWITCH',0
			dc.b	'BEND',0
			dc.b	'CH_ASSIGN',0
			dc.b	'CH_FADER',0
			dc.b	'CH_PRESSURE',0
			dc.b	'CODA',0
			dc.b	'COMMENT',0
			dc.b	'CONTROL',0
			dc.b	'DAMPER',0
			dc.b	'DETUNE',0
			dc.b	'D.C.',0
		  	dc.b	'D.S.',0
			dc.b	'DO',0
			dc.b	'DUMMY',0
			dc.b	'ECHO',0
			dc.b	'EFFECT.CHORUS',0
			dc.b	'EFFECT.DELAY',0
			dc.b	'EFFECT.REVERB',0
			dc.b	'EFFECT',0
			dc.b	'EMBED',0
			dc.b	'END',0
			dc.b	'EVENT',0
			dc.b	'EXCLUSIVE',0
			dc.b	'FINE',0
			dc.b	'FREQUENCY',0
sct_gm_syson:		dc.b	'GM_SYSTEM_ON',0
sct_gs_chorus:		dc.b	'GS_CHORUS',0
sct_gs_dsply:		dc.b	'GS_DISPLAY',0
sct_gs_drmstup:		dc.b	'GS_DRUM_SETUP',0
			dc.b	'GS_DRUM_PARAMETER',0
sct_gs_drmname:		dc.b	'GS_DRUM_NAME',0
			dc.b	'GS_INIT',0
sct_gs_v_rsv:		dc.b	'GS_PARTIAL_RESERVE',0
sct_gs_ptstup:		dc.b	'GS_PART_SETUP',0
			dc.b	'GS_PART_PARAMETER',0
sct_gs_print:		dc.b	'GS_PRINT',0
sct_gs_reset:		dc.b	'GS_RESET',0
sct_gs_reverb:		dc.b	'GS_REVERB',0
			dc.b	'GS_V_RESERVE',0
			dc.b	'INSTRUMENT_ID',0
			dc.b	'JUMP',0
			dc.b	'K.SIGN',0
			dc.b	'KEY_REMAP',0
			dc.b	'KEY_SIGNATURE',0
			dc.b	'KEY',0
			dc.b	'LOOP',0
			dc.b	'M1_EFFECT_SETUP',0
			dc.b	'M1_MIDI_CH',0
			dc.b	'M1_PART_SETUP',0
			dc.b	'M1_PRINT',0
			dc.b	'M1_SETUP',0
			dc.b	'MASTER_FADER',0
			dc.b	'MEASURE',0
			dc.b	'METER',0
			dc.b	'MIDI_DATA',0
sct_mt32cmn:		dc.b	'MT32_COMMON',0
sct_mt32drmstup:	dc.b	'MT32_DRUM_SETUP',0
			dc.b	'MT32_INIT',0
sct_mt32prsv:		dc.b	'MT32_PARTIAL_RESERVE',0
sct_mt32ptl:		dc.b	'MT32_PARTIAL',0
sct_mt32ptstup:		dc.b	'MT32_PART_SETUP',0
sct_mt32ptch:		dc.b	'MT32_PATCH',0
			dc.b	'MT32_P_RESERVE',0
sct_mt32prt:		dc.b	'MT32_PRINT',0
sct_mt32reset:		dc.b	'MT32_RESET',0
sct_mt32rvb:		dc.b	'MT32_REVERB',0
			dc.b	'MT32_RHYTHM_SETUP',0
			dc.b	'MUTE',0
			dc.b	'NOISE',0
			dc.b	'NRPN',0
			dc.b	'OPM.LFO',0
			dc.b	'OPM',0
			dc.b	'PANPOT',0
			dc.b	'PATTERN',0
			dc.b	'PCM_MODE',0
			dc.b	'PITCH',0
			dc.b	'POKE',0
			dc.b	'POLYPHONIC_PRESSURE',0
			dc.b	'PUSH_PORTAMENT',0
			dc.b	'PULL_PORTAMENT',0
			dc.b	'PORTAMENT',0
			dc.b	'PROGRAM_BANK',0
			dc.b	'PROGRAM_SPLIT.SWITCH',0
			dc.b	'PROGRAM_SPLIT',0
			dc.b	'PROGRAM',0
			dc.b	'REPLAY',0
			dc.b	'ROLAND_EXCLUSIVE',0
			dc.b	'SC55_CHORUS',0
			dc.b	'SC55_DISPLAY',0
			dc.b	'SC55_DRUM_SETUP',0
			dc.b	'SC55_DRUM_PARAMETER',0
			dc.b	'SC55_DRUM_NAME',0
			dc.b	'SC55_INIT',0
			dc.b	'SC55_PARTIAL_RESERVE',0
			dc.b	'SC55_PART_SETUP',0
			dc.b	'SC55_PART_PARAMETER',0
			dc.b	'SC55_PRINT',0
			dc.b	'SC55_REVERB',0
			dc.b	'SC55_RESET',0
			dc.b	'SC55_V_RESERVE',0
			dc.b	'SC88_MODE_SET',0
sct_sc88_mode:		dc.b	'SC88_MODE',0
sct_sc88_reverb:	dc.b	'SC88_REVERB',0
sct_sc88_chorus:	dc.b	'SC88_CHORUS',0
sct_sc88_delay:		dc.b	'SC88_DELAY',0
sct_sc88_equalizer:	dc.b	'SC88_EQUALIZER',0
sct_sc88_ptstup:	dc.b	'SC88_PART_SETUP',0
			dc.b	'SC88_PART_PARAMETER',0
sct_sc88_drmstup:	dc.b	'SC88_DRUM_SETUP',0
			dc.b	'SC88_DRUM_PARAMETER',0
sct_sc88_drmname:	dc.b	'SC88_DRUM_NAME',0
sct_sc88_usrinst:	dc.b	'SC88_USER_INST',0
sct_sc88_usrdrum:	dc.b	'SC88_USER_DRUM',0
			dc.b	'SEGNO',0
			dc.b	'SEND_TO_M1',0
			dc.b	'SLOT_SEPARATION',0
			dc.b	'STOP',0
			dc.b	'SYNCHRONIZE',0
			dc.b	'TEMPO',0
			dc.b	'TIE_MODE',0
			dc.b	'TIMER',0
			dc.b	'TIMBRE_BANK',0
			dc.b	'TIMBRE_SPLIT.SWITCH',0
			dc.b	'TIMBRE_SPLIT',0
			dc.b	'TIMBRE',0
			dc.b	'TOCODA',0
			dc.b	'TRACK_DELAY',0
			dc.b	'TRACK_FADER',0
			dc.b	'TRACK_MODE',0
sct_u220cmn:		dc.b	'U220_COMMON',0
sct_u220drminst:	dc.b	'U220_DRUM_INST',0
sct_u220drmstup:	dc.b	'U220_DRUM_SETUP',0
sct_u220ptstup:		dc.b	'U220_PART_SETUP',0
sct_u220prt:		dc.b	'U220_PRINT',0
sct_u220stup:		dc.b	'U220_SETUP',0
sct_u220tmb:		dc.b	'U220_TIMBRE',0
			dc.b	'VELOCITY.DEEPEN',0
			dc.b	'VELOCITY.DELAY',0
			dc.b	'VELOCITY.DEPTH',0
			dc.b	'VELOCITY.LEVEL',0
			dc.b	'VELOCITY.ORIGIN',0
			dc.b	'VELOCITY.PHASE',0
			dc.b	'VELOCITY.SPEED',0
			dc.b	'VELOCITY.SWITCH',0
			dc.b	'VELOCITY.SYNC',0
			dc.b	'VELOCITY.WAVEFORM',0
			dc.b	'VELOCITY',0
			dc.b	'VIBRATO.DEEPEN',0
			dc.b	'VIBRATO.DELAY',0
			dc.b	'VIBRATO.DEPTH',0
			dc.b	'VIBRATO.MODE',0
			dc.b	'VIBRATO.SPEED',0
			dc.b	'VIBRATO.SWITCH',0
			dc.b	'VIBRATO.SYNC',0
			dc.b	'VIBRATO.WAVEFORM',0
			dc.b	'VOICE_RESERVE',0
			dc.b	'VOLUME',0
			dc.b	'YAMAHA_BULKDUMP',0
			dc.b	'YAMAHA_EXCLUSIVE',0
			dc.b	'^',0
			dc.b	-1
		.even
header:		dc.b	$f0,$41,$00,$00,$12	*ROLAND EXCLUSIVE HEADER
exc_addr:	dc.b	0,0,0			*ROLAND EXCLUSIVE ADDRESS
sc_p_data:	dc.b	0			*1 byte転送時に使用
tail:		dc.b	0,$f7			*ROLAND EXCLUSIVE TAIL
m1_ef_dflt:			*M1デフォルトエフェクトデータ
	dc.b	$0B,$00,$1E,$1E,$00,$19,$19,$00,$00,$1F
	dc.b	$3C,$09,$00,$03,$00,$0A,$00,$00,$00
	dc.b	$1A,$00,$00,$28,$32,$1C,$00,$00,$00
crld_ctr:	dc.b	$1b,'[0K',0
