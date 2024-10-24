	.nlist
*
* fdef.h X68k XC Compiler v2.00 Copyright 1990 SHARP/Hudson
*
* Ｘ－ＢＡＳＩＣ 拡張 ＦＮＣ 引数定義マクロ
*
*	引数コード	dc.w	????
*
float_val	equ	$0001		float型の値
int_val		equ	$0002		  int型の値
char_val	equ	$0004		 char型の値
str_val		equ	$0008		  str型の値
*
float_omt	equ	$0081		省略可能なfloat型の値
int_omt		equ	$0082		省略可能な  int型の値
char_omt	equ	$0084		省略可能な char型の値
str_omt		equ	$0088		省略可能な  str型の値
*
float_vp	equ	$0011		float型の変数の値のポインタ
int_vp		equ	$0012		  int型の変数の値のポインタ
char_vp		equ	$0014		 char型の変数の値のポインタ
str_vp		equ	$0018		  str型の変数の値のポインタ
*
ary1		equ	$003f		１次元配列（全ての型）
ary1_i		equ	$0032		１次元配列（int型）
ary1_fic	equ	$0037		１次元配列（float,int,char型）
ary1_c		equ	$0034		１次元配列（char型）
ary2_c		equ	$0054		２次元配列（char型）
*
float_ret	equ	$8000		返り値はfloat型
int_ret		equ	$8001		返り値はint型
str_ret		equ	$8003		返り値はstr型
void_ret	equ	$ffff		返り値はなし
*
*	引数オフセット	sp+????
*
par1		equ	6		第１引数ＦＡＣ
par2		equ	16		第２引数ＦＡＣ
par3		equ	26		第３引数ＦＡＣ
par4		equ	36		第４引数ＦＡＣ
par5		equ	46		第５引数ＦＡＣ
par6		equ	56		第６引数ＦＡＣ
par7		equ	66		第７引数ＦＡＣ
par8		equ	76		第８引数ＦＡＣ
par9		equ	86		第９引数ＦＡＣ
*
	.list
