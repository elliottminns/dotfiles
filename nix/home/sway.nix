{
  config,
  pkgs,
  ...
}: {
  enable = false;
  config = rec {
    modifier = "Mod4";
    terminal = "alacritty";
    startup = [
      # Launch Firefox on start
      {command = "firefox";}
    ];
  };
}
