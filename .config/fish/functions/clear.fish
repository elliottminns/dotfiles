function clear
  printf '\e[H\e[2J'
  commandline -f repaint
end
