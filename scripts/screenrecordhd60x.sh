#!/bin/bash
LOCKDIR=/Users/elliott/.local/share/screenrecord
LOCKFILE=/Users/elliott/.local/share/screenrecord/record.lock
PROCESS_LOCKFILE=/Users/elliott/.local/share/screenrecord/process.lock
DIR=/Users/elliott/Movies/Screencast
RAWDIR=/Users/elliott/Movies/Screencast/raw

mkdir -p $LOCKDIR/log
mkdir -p $RAWDIR

if test -f "$LOCKFILE"; then
  kill -SIGINT $(head -n 1 $LOCKFILE)
  sleep 1
  rm $LOCKFILE
  touch $PROCESS_LOCKFILE
  #DATE=$(head -n 2 $LOCKFILE | tail -n 1)
  FILENAME="$DIR/$DATE.mkv"
  OUTPUT="$DIR/$DATE.mov"
  RAWFILENAME="$RAWDIR/$DATE.mkv"
  rm $PROCESS_LOCKFILE
  echo "Killed screenrecord"
else
  DATE=$(date "+%FT%H-%M-%S")
  $HOME/.nix-profile/bin/ffmpeg -framerate 60 -f avfoundation -capture_cursor 0 -i "0:none" -vf "format=uyvy422,eq=gamma=1.05" -video_size 3840x2160 -c:v h264_videotoolbox -crf 0 -preset ultrafast "$HOME/Movies/Screencast/$DATE.mkv" >> $LOCKDIR/log/$DATE 3>&1 &
  PID=$!

  echo $PID > $LOCKFILE
  echo $DATE >> $LOCKFILE

  echo "Running screenrecord"
fi
