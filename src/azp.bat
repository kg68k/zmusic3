echo off
echo ZP3.R 生成バッチ
zp3 -r > nul
has /w  zp.has -ozp3.o /s debug=0%1 > er
hlk zp3
cv zp3
