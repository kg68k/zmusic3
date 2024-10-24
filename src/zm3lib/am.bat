echo off
echo ZMUSIC Ver.3.0用 X-BASIC外部関数 生成バッチ
del musicz3.fnc > nul
has /w4 musicz /sdebug=0%1 > er
hlk musicz -o MUSICZ3.FNC >> er
copy musicz3.fnc \basic2 > nul
copy zmsc3lib.def \bc > nul
