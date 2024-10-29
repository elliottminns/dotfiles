#!/bin/zsh

for i in *(.mkv|.mp4|.mov) ; do
  ffmpeg -i $i -c:v h264_videotoolbox -crf 0 -preset veryslow ./raw/${i%.*}.mkv
done
