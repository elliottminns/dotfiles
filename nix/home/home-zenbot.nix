# Home Manager configuration for zenbot user (Zenbot service)
{ config, pkgs, lib, ... }:

{
  imports = [
    ./clawdbot.nix
  ];
  programs.home-manager.enable = true;

  home.username = "zenbot";
  home.homeDirectory = "/home/zenbot";
  home.stateVersion = "23.11";

  xdg.enable = true;

  programs = {
    fish = import ./fish.nix {};
    starship = import ./starship.nix {inherit pkgs;};

    bash = {
      enable = true;
      shellAliases = {
        ll = "ls -la";
        ".." = "cd ..";
        gs = "git status";
        gp = "git push";
        gl = "git pull";

        # Zenbot shortcuts
        zb = "cd ~/zenbot";
        zw = "cd ~/workspace";
        zbs = "systemctl --user status zenbot";
        zbl = "journalctl --user -u zenbot -f";
        zbr = "systemctl --user restart zenbot";
      };
      initExtra = ''
        export PATH="$HOME/.local/bin:$HOME/zenbot/node_modules/.bin:$PATH"
        export ZENBOT_WORKSPACE="$HOME/workspace"
      '';
    };

    git = {
      enable = true;
      settings = {
        user.name = "Zenbot";
        user.email = "zenbot@zenbot.dev";
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
      };
    };

    tmux = {
      enable = true;
      terminal = "screen-256color";
      historyLimit = 10000;
      extraConfig = ''
        set -g mouse on
        set -g base-index 1
      '';
    };

    vim = {
      enable = true;
      defaultEditor = true;
      settings = {
        number = true;
        expandtab = true;
        tabstop = 2;
        shiftwidth = 2;
      };
    };
  };

  home.packages = with pkgs; [
    nodejs_22
    nodePackages.pnpm
    htop
    ripgrep
    fd
    jq
    tree
  ];

  # Create workspace directories
  home.file.".zenbot/.keep".text = "";
  home.file."workspace/.keep".text = "";
}
