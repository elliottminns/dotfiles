#!/bin/zsh

for i in *.mov ; do
  # Do this: ffmpeg -i output.mkv -c:v libx264rgb -crf 0 -preset veryslow output-smaller.mkv
  ffmpeg -i "$i" -c:v libx264rgb -crf 0 -preset veryslow "${i%.*}.smaller.mov"
  mv "${i%.*}.smaller.mov" "$i"
done
