# Home Manager configuration for server hosts (like zenbox)
{ config, pkgs, meta, lib, ... }:

{
  programs.home-manager.enable = true;

  home.username = "elliott";
  home.homeDirectory = "/home/elliott";
  home.stateVersion = "23.11";

  xdg.enable = true;

  programs = {
    tmux = import ./tmux.nix { inherit pkgs; };
    zsh = import ./zsh.nix { inherit config pkgs lib; };
    git = import ./git.nix { inherit config pkgs; };
    gpg = import ./gpg.nix { inherit config pkgs; };
    zoxide = import ./zoxide.nix { inherit config pkgs; };
    fzf = import ./fzf.nix { inherit pkgs; };
  };

  # Server-specific shell aliases
  programs.zsh.shellAliases = {
    # Clawdbot shortcuts
    cb = "cd ~/clawdbot";
    cbs = "sudo systemctl status clawdbot";
    cbl = "sudo journalctl -u clawdbot -f";
    cbr = "sudo systemctl restart clawdbot";
  };

  home.packages = with pkgs; [
    nodejs_22
    nodePackages.pnpm
    btrbk
    btrfs-progs
  ];
}
