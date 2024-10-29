#!/bin/zsh

mkdir -p ../../b-roll

for i in *.mov ; do
  ffmpeg -i $i -c:v h264_videotoolbox -crf 18 -vf format=yuv420p -c:a copy "./${i%.*}-proxy.mov"
  #ffmpeg -i "$i" -c:v prores_videotoolbox -filter:v fps=60 -profile:v 3 -vendor apl0 -bits_per_mb 8000 -pix_fmt uyvy422 "${i%.*}.mov"
  #ffmpeg -i $i -c:v h264_videotoolbox -crf 0 -preset veryslow ./raw/${i%.*}.mkv
  retval=$?
done
