   10 dim int ds1(50000)
   20 dim char sr1(50000),ds2(50000)
   30 int i,f,fsize,ad_size
   40 f=fopen("g:g.pcm","r")
   50 get_size():ad_size=fsize
   60 fread(sr1,ad_size,f)
   70 fclose(f)
   80 zm_convert_pcm(0,ad_size,sr1,ds1)
  120 zm_convert_pcm(1,ad_size*4,ds1,ds2)
  130 f=fopen("gg.PCM","c")
  140 fwrite(ds2,ad_size,f)
  150 fclose(f)
  160 end
  170 func get_size()
  180 fsize=fseek(f,0,2)
  190 fseek(f,0,0)
  200 endfunc
