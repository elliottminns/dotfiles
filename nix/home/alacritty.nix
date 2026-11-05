{
  pkgs,
  meta ? {},
  ...
}: {
  enable = true;
  package = pkgs.unstable.alacritty or pkgs.alacritty;

  settings = {
    window = {
      padding = {
        x = 4;
        y = 8;
      };
      decorations = "Full";
      opacity = 1;
      startup_mode = "Windowed";
      title = "Alacritty";
      dynamic_title = true;
      decorations_theme_variant = "None";
    };

    general.live_config_reload = true;

    # Tokyo Night, matching the shared terminal theme.
    colors = {
      primary = {
        background = "#1a1b26";
        foreground = "#c0caf5";
      };
      cursor = {
        cursor = "#c0caf5";
        text = "#15161e";
      };
      selection = {
        background = "#33467c";
        text = "#c0caf5";
      };
      normal = {
        black = "#15161e";
        red = "#f7768e";
        green = "#9ece6a";
        yellow = "#e0af68";
        blue = "#7aa2f7";
        magenta = "#bb9af7";
        cyan = "#7dcfff";
        white = "#a9b1d6";
      };
      bright = {
        black = "#414868";
        red = "#f7768e";
        green = "#9ece6a";
        yellow = "#e0af68";
        blue = "#7aa2f7";
        magenta = "#bb9af7";
        cyan = "#7dcfff";
        white = "#c0caf5";
      };
    };

    font = let
      jetbrainsMono = style: {
        family = "JetBrainsMono Nerd Font Mono";
        inherit style;
      };
    in {
      size =
        if (meta.name or "") == "karasu"
        then 12
        else 16;
      normal = jetbrainsMono "Regular";
      bold = jetbrainsMono "Bold";
      italic = jetbrainsMono "Italic";
      bold_italic = jetbrainsMono "Bold Italic";
    };

    mouse.hide_when_typing = true;

    cursor = {
      style = "Block";
    };

    env = {
      TERM = "xterm-256color";
    };

    terminal.shell.program = "${pkgs.zsh}/bin/zsh";
  };
}
