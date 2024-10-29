#!/bin/sh
eval $(xdotool getactivewindow getwindowgeometry --shell)
xpos=$(( $((3840 - WIDTH)) / 2))
ypos=$(( $((2160 - (HEIGHT + 72))) / 2))
xdotool getactivewindow windowmove $xpos $ypos
