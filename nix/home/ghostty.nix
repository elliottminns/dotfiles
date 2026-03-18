{pkgs, ...}: {
  programs.ghostty = {
    enable = true;
    package = pkgs.ghostty-bin;
    settings = {
      font-family = "JetBrains Mono";
      font-size = 20;
      font-feature = "-calt, -liga, -dlig";
      theme = "TokyoNight";
      mouse-hide-while-typing = true;
      cursor-style = "block";
      cursor-style-blink = false;
      shell-integration-features = "no-cursor";
    };
  };
}
