{pkgs, ...}: {
  enable = true;
  enableZshIntegration = false;
  enableFishIntegration = true;
  settings = {
    format = ''
      $directory
      $character
    '';
    add_newline = true;
    package = {
      disabled = true;
    };
  };
}
