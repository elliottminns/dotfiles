{pkgs, ...}: {
  programs.ghostty = {
    enable = true;
    # Ghostty's multiline prompt rewriting corrupts Powerlevel10k at startup.
    enableZshIntegration = false;
    package =
      if pkgs.stdenv.hostPlatform.isDarwin
      then pkgs.ghostty-bin
      else pkgs.ghostty;
    settings = {
      font-family = "JetBrainsMono Nerd Font Mono";
      font-size = 20;
      font-feature = "-calt, -liga, -dlig";
      theme = "TokyoNight";
      mouse-hide-while-typing = true;
      cursor-style = "block";
      cursor-style-blink = false;
      shell-integration-features = "no-cursor";
      shell-integration = "none";
      window-decoration = "none";
    };
  };
}
