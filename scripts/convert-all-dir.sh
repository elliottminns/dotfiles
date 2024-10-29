#!/bin/zsh

FILEDIR=/Users/elliott/Movies/Screencast

pushd $FILEDIR

mkdir -p raw

FILES="./*.mkv"
for i in $FILES
do
  $HOME/.nix-profile/bin/ffmpeg -i $i -c:v h264_videotoolbox -crf 0 -preset veryslow raw/$i
  $HOME/.nix-profile/bin/ffmpeg -i "$i" -c:v prores_videotoolbox -filter:v fps=60 -profile:v 3 -vendor apl0 -bits_per_mb 8000 -pix_fmt yuv422p10le "${i%.*}.mov"
done

popd
