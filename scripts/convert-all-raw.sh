#!/bin/zsh

for i in *(.mkv|.mp4|.mov) ; do
  ffmpeg -i "$i" -c:v prores_videotoolbox -profile:v 3 -vendor apl0 -bits_per_mb 8000 -pix_fmt yuv422p10le "${i%.*}.mov"
done
