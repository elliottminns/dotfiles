{
  pkgs,
  meta,
  ...
}: let
  monitorLine = monitor:
    builtins.concatStringsSep "," [
      monitor.name
      "${
        if monitor ? dimensions
        then monitor.dimensions
        else "${monitor.width}x${monitor.height}"
      }${
        if monitor.dimensions == "preferred"
        then ""
        else "@${builtins.toString monitor.framerate}"
      }"
      monitor.position
      (builtins.toString monitor.scale)
      "transform"
      (builtins.toString monitor.transform)
    ];

  lidScript = let
    monitor = builtins.elemAt meta.monitors 0;
  in
    pkgs.writeShellScript "lidswitch.sh"
    ''
      if grep open /proc/acpi/button/lid/LID0/state; then
          hyprctl keyword monitor "${monitorLine monitor}"
      else
          if [[ `hyprctl monitors | grep "Monitor" | wc -l` != 1 ]]; then
              hyprctl keyword monitor "${monitor.name}, disable"
          else
            systemctl suspend
          fi
      fi
    '';

  exitScript =
    pkgs.writeShellScript "exit.sh"
    ''
      if zenity --question --text="Do you wish to exit?"; then
        hyprctl dispatch exit
      fi
    '';

  gapsScript =
    pkgs.writeShellScript "gaps.sh"
    ''
      # Get current gaps values
      CURRENT_GAPS_IN=$(hyprctl getoption general:gaps_in -j | jq '.custom')
      CURRENT_GAPS_OUT=$(hyprctl getoption general:gaps_out -j | jq '.custom')

      if [ "$CURRENT_GAPS_OUT" -eq "0 0 0 0" ]; then
      # If gaps are 0, set them back to default values
      hyprctl keyword general:gaps_out "27,27,27,27"
      hyprctl keyword general:border_size "2"
      hyprctl keyword decoration:rounding "16"
      else
      # If gaps exist, set them to 0
      hyprctl keyword general:gaps_out 0
      hyprctl keyword general:border_size "0"
      hyprctl keyword decoration:rounding "0"
      fi
    '';

  leftGaps =
    pkgs.writeShellScript "leftgaps.sh"
    ''
      hyprctl keyword general:gaps_out "0,500,0,0"
      hyprctl keyword general:border_size "0"
      hyprctl keyword decoration:rounding "0"
    '';
in {
  enable = true;
  settings = {
    "$mod" = "SUPER";
    exec-once = ["ags"];
    exec = [
      ''gsettings set org.gnome.desktop.interface gtk-theme "Adwaita"   # for GTK3 apps''
      ''gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"   # for GTK4 apps''
      ''gsettings set org.gnome.desktop.interface cursor-theme "Banana-Catppuccin-Mocha"''
      ''gsettings set org.gnome.desktop.interface cursor-size 64''
    ];
    xwayland = {
      force_zero_scaling = true;
    };
    general = {
      gaps_out =
        if meta.gaps
        then "27,27,27,27"
        else 0;
      border_size =
        if meta.gaps
        then 2
        else 0;
      "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
      "col.inactive_border" = "rgba(595959aa)";
      # Set to true enable resizing windows by clicking and dragging on borders and gaps
      resize_on_border = false;
      # Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
      allow_tearing = false;
      layout = "dwindle";
    };
    input = {
      follow_mouse = 1;
      touchpad = {
        natural_scroll = true;
        disable_while_typing = true;
        tap-to-click = false;
        middle_button_emulation = false;
      };
      sensitivity = 0;
    };
    "misc:middle_click_paste" = false;
    env = [
      "QT_QPA_PLATFORMTHEME,qt6ct"
      "HYPRCURSOR_SIZE,${builtins.toString meta.cursor}"
      "XCURSOR_SIZE,${builtins.toString meta.cursor}"
      "QT_QPA_PLATFORM,wayland"
      "MOZ_ENABLE_WAYLAND,1"
    ];
    monitor = map monitorLine meta.monitors;
    bezier = [
      "easeOutBack,0.34,1.56,0.64,1"
      "easeInBack,0.36,0,0.66,-0.56"
      "easeInCubic,0.32,0,0.67,0"
      "easeInOutCubic,0.65,0,0.35,1"
    ];
    decoration = {
      rounding =
        if meta.gaps
        then 16
        else 0;

      # Change transparency of focused and unfocused windows
      active_opacity = 1.0;
      inactive_opacity = 1.0;

      #drop_shadow = true;
      #shadow_range = 4;
      #shadow_render_power = 3;
      #"col.shadow" = "rgba(1a1a1aee)";

      blur = {
        enabled = true;
        size = 3;
        passes = 1;
        vibrancy = 0.1696;
      };
    };
    animation = [
      "windowsIn,1,5,easeOutBack,popin"
      "windowsOut,1,5,easeInBack,popin"
      "fadeIn,0"
      "fadeOut,1,10,easeInCubic"
      "workspaces,1,4,easeInOutCubic,slide"
    ];
    bind =
      [
        "$mod, Return, exec, alacritty"
        "$mod, Q, killactive"
        "$mod, M, exec, ${exitScript}"
        "$mod, S, exec, grim"
        "$mod, F, exec, zen"
        "$mod, E, exec, nautilus"
        "$mod, V, togglefloating"
        "$mod+SHIFT, F, fullscreen, 0"
        "$mod+SHIFT, G, exec, ${gapsScript}"
        "$mod+SHIFT, L, exec, ${leftGaps}"
        "$mod, R, exec, wofi --show drun"
        "$mod, S, exec, grim"
        "$mod, P, pin"
        "$mod, J, togglesplit"
        "$mod, T, togglegroup"
        "$mod+ALT, R, resizeactive,"
        "$mod+ALT, J, changegroupactive, f"
        "$mod+ALT, K, changegroupactive, f"
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
        "$mod, h, movefocus, l"
        "$mod, l, movefocus, r"
        "$mod, k, movefocus, u"
        "$mod, j, movefocus, d"
        "CTRL, left, workspace, -1"
        "CTRL, right, workspace, +1"
      ]
      ++ (
        builtins.concatLists (builtins.genList (
            x: let
              ws = let
                c = (x + 1) / 10;
              in
                builtins.toString (x + 1 - (c * 10));
            in [
              "$mod, ${ws}, workspace, ${toString (x + 1)}"
              "$mod SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
            ]
          )
          10)
      );
    bindl = [
      '', switch:Lid Switch, exec, ${lidScript}''
    ];
    bindm = [
      "$mod CTRL, mouse:272, resizewindow"
      "$mod ALT, mouse:272, movewindow"
    ];
  };
  extraConfig = ''
  '';
}
