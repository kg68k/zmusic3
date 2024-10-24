echo off
echo ZMSC3.X 生成バッチ
zmsc3 -r > nul
has /w zmsc0.has -ozmsc3.o /s debug=0%1 /s mpu=0%2 > er
hlk zmsc3 >> er
