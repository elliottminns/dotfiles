#!/bin/zsh

ffmpeg -i "$1" -c:v prores_videotoolbox -profile:v 3 -vendor apl0 -bits_per_mb 8000 -pix_fmt uyvy422 "${1%.*}.mov"
