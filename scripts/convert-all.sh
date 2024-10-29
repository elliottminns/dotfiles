#!/usr/bin/env zsh

mkdir -p ./raw

# Convert to editable footage
for i in *(.mkv|.avi) ; do
  ffmpeg -vaapi_device /dev/dri/renderD128 -i "$i" -vf 'format=nv12,hwupload' -c:v h264_vaapi -qp 18 -an "${i%.*}.mov"
done

# Convert to lossless
for i in *(.mkv|.avi) ; do
  ffmpeg -i $i -c:v libx264 -crf 0 -preset veryslow -an ./raw/${i%.*}.mkv
  retval=$?
done
