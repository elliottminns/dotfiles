{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (config.lib.file) mkOutOfStoreSymlink;
in {
  imports = [
    ../home/fastfetch.nix
    ../home/ghostty.nix
  ];

  programs.home-manager.enable = true;

  home.username = "elliott";
  home.homeDirectory = "/Users/elliott";
  xdg.enable = true;
  xdg.configFile.nvim.source = mkOutOfStoreSymlink "/Users/elliott/.dotfiles/.config/nvim";

  home.stateVersion = "23.11";

  programs = {
    git = import ../home/git.nix { inherit config pkgs lib;};
    tmux = import ../home/tmux.nix {inherit pkgs;};
    zsh = import ../home/zsh.nix {inherit config pkgs lib; };
    zoxide = (import ../home/zoxide.nix { inherit config pkgs; });
    fzf = import ../home/fzf.nix {inherit pkgs;};
    oh-my-posh = import ../home/oh-my-posh.nix {inherit pkgs;};
  };
}
