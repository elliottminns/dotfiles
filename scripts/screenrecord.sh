#!/usr/bin/env bash
LOCKDIR=$HOME/.local/share/screenrecord
LOCKFILE=$HOME/.local/share/screenrecord/record.lock
PROCESS_LOCKFILE=$HOME/.local/share/screenrecord/process.lock
DIR=$HOME/Videos/Screencast
RAWDIR=$HOME/Videos/Screencast/raw

mkdir -p $LOCKDIR/log
mkdir -p $RAWDIR

if test -f "$LOCKFILE"; then
  kill -SIGINT $(head -n 1 $LOCKFILE)
  sleep 1
  FILENAME=$(head -n 2 $LOCKFILE | tail -n 1)
  rm $LOCKFILE
  touch $PROCESS_LOCKFILE

  rm $PROCESS_LOCKFILE
  echo "Killed screenrecord"

  numbers=$(ls "$DIR" | grep -Eo '^[0-9]{3}-' | grep -Eo '[0-9]{3}' | sort -n)
  # Get the highest number
  last_number=$(echo "$numbers" | tail -n 1)
  # Calculate the next number
  next_number=$(printf "%03d" $((10#$last_number + 1)))

  # If no numbers are found, start from 001
  if [[ -z "$last_number" ]]; then
    next_number="000"
  else
    # Calculate the next number
    next_number=$(printf "%03d" $((10#$last_number + 1)))
  fi

  name=$(zenity --entry --entry-text "$next_number-" --text "Please enter a file name")

  # Set the file name
  if [ $? -eq 0 ]; then
    mv $FILENAME $DIR/$name.mp4
  fi
else
  DATE=$(date "+%FT%H-%M-%S")
  FILENAME="$DIR/$DATE.mp4"
  wl-screenrec --filename $FILENAME 2>&1 &
  #$HOME/.nix-profile/bin/ffmpeg -framerate 60 -f avfoundation -capture_cursor 0 -i "1:none" -vf "format=uyvy422,eq=gamma=1.05" -video_size 3840x2160 -c:v libx264 -crf 0 -preset ultrafast $FILENAME >> $LOCKDIR/log/$DATE 2>&1 &
  #ffmpeg -framerate 60 -f avfoundation -capture_cursor 0 -i "1:none" $FILENAME >> $LOCKDIR/log/$DATE 2>&1 &
  PID=$!

  echo $PID > $LOCKFILE
  echo $FILENAME >> $LOCKFILE

  echo "Running screenrecord"
fi
