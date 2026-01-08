# Home Manager configuration for clawd user (Clawdbot service)
{ config, pkgs, lib, ... }:

{
  programs.home-manager.enable = true;

  home.username = "clawd";
  home.homeDirectory = "/home/clawd";
  home.stateVersion = "23.11";

  xdg.enable = true;

  programs = {
    bash = {
      enable = true;
      shellAliases = {
        ll = "ls -la";
        ".." = "cd ..";
        gs = "git status";
        gp = "git push";
        gl = "git pull";
        
        # Clawdbot shortcuts
        cb = "cd ~/clawdbot";
        cw = "cd ~/clawd";
        cbs = "systemctl --user status clawdbot";
        cbl = "journalctl --user -u clawdbot -f";
        cbr = "systemctl --user restart clawdbot";
      };
      initExtra = ''
        export PATH="$HOME/.local/bin:$HOME/clawdbot/node_modules/.bin:$PATH"
        export CLAWDBOT_WORKSPACE="$HOME/clawd"
      '';
    };

    git = {
      enable = true;
      userName = "Dreamfox";
      userEmail = "dreamfox@clawd.bot";
      extraConfig = {
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
  home.file.".clawdbot/.keep".text = "";
  home.file."clawd/.keep".text = "";
}
