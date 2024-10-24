{...}: let
  startRecordScript =
    pkgs.writeShellScript "exit.sh"
    ''
      if zenity --question --text="Do you wish to exit?"; then
        hyprctl dispatch exit
      fi
    '';
in {
}
