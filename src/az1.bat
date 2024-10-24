echo off
echo ZMC.X 生成バッチ
zmc -r > nul
has /w zmsc1.has -ozmc.o /s debug=0%1 > er1
hlk zmc >> er1
