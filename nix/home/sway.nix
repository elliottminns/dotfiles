{
  config,
  pkgs,
  ...
}: {
  enable = false;
  config = {
    modifier = "Mod4";
    terminal = "alacritty";
    startup = [
      # Launch Firefox on start
      {command = "firefox";}
    ];
    output = {
      "*" = {
        bg = "$HOME/.dotfiles/wallpapers/abstract.png";
      };
    };
  };
}
