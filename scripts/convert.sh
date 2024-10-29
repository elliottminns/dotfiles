#!/bin/zsh

ffmpeg -i $1 -c:v libx264 -crf 0 -preset veryslow ./raw/$1
#ffmpeg -i $1 -c:v prores_ks -profile:v 3 -vendor apl0 -bits_per_mb 8000 -pix_fmt yuv444p10le "${1%.*}.mov"
ffmpeg -i $1 -c:v prores_ks -profile:v 3 -vendor apl0 -bits_per_mb 8000 "${1%.*}.mov"

#for i in *.mkv ; do
 # ffmpeg -i "$i" -c:v prores_ks -profile:v 3 -vendor apl0 -bits_per_mb 8000 -pix_fmt yuv422p10le "${i%.*}.mov"
  #ffmpeg -i "$i" -c:v libx265 -x265-params profile=main10:pix_fmt=yuv422p10le -b:v 8000k "${i%.*}.mov"
#done
