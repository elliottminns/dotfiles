#!/usr/bin/env bash
LOCKDIR=$HOME/.local/share/screenrecord
LOCKFILE=$HOME/.local/share/screenrecord/record.lock
PROCESS_LOCKFILE=$HOME/.local/share/screenrecord/process.lock
DIR=$HOME/Videos/Screencast
RAWDIR=$HOME/Videos/Screencast/raw

mkdir -p $LOCKDIR/log
mkdir -p $RAWDIR

if test -f "$LOCKFILE"; then
  echo "Running screenrecord"
else
  DATE=$(date "+%FT%H-%M-%S")
  FILENAME="$DIR/$DATE.mp4"
  OUTPUT=$(hyprctl monitors | grep "model: BenQ" -B 4 | grep "Monitor" | awk '{print $2}')
  echo $OUTPUT
  wl-screenrec --output $OUTPUT --filename $FILENAME 2>&1 &
  #$HOME/.nix-profile/bin/ffmpeg -framerate 60 -f avfoundation -capture_cursor 0 -i "1:none" -vf "format=uyvy422,eq=gamma=1.05" -video_size 3840x2160 -c:v libx264 -crf 0 -preset ultrafast $FILENAME >> $LOCKDIR/log/$DATE 2>&1 &
  #ffmpeg -framerate 60 -f avfoundation -capture_cursor 0 -i "1:none" $FILENAME >> $LOCKDIR/log/$DATE 2>&1 &
  PID=$!

  echo $PID > $LOCKFILE
  echo $FILENAME >> $LOCKFILE

  echo "Running screenrecord"
fi
