{ config, pkgs, ... }:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
in
{
  programs.home-manager.enable = true;

  home.username = "elliott";
  home.homeDirectory = "/Users/elliott";
  xdg.enable = true;

  xdg.configFile.nvim.source = mkOutOfStoreSymlink "/Users/elliott/.dotfiles/.config/nvim";

  home.stateVersion = "23.11";

  programs = {
    alacritty = (import ../home/alacritty.nix  { inherit pkgs; });
    tmux = (import ../home/tmux.nix { inherit pkgs; });
    zsh = (import ../home/zsh.nix { inherit config pkgs; });
    zoxide = (import ../home/zoxide.nix { inherit config pkgs; });
    fzf = (import ../home/fzf.nix { inherit pkgs; });
    oh-my-posh = (import ../home/oh-my-posh.nix { inherit pkgs; });
  };
}
