{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (config.lib.file) mkOutOfStoreSymlink;
  tmux = let
    base = import ../home/tmux.nix {inherit pkgs;};
  in
    base
    // {
      plugins = with pkgs.tmuxPlugins; [
        yank
        sensible
        vim-tmux-navigator
      ];
      extraConfig =
        builtins.replaceStrings
        ["run-shell " "tokyo-night/tokyo-night.tmux"]
        ["run-shell \"${pkgs.bash}/bin/bash " "tokyo-night/tokyo-night.tmux\""]
        base.extraConfig;
    };
  zsh = let
    base = import ../home/zsh.nix {inherit config pkgs lib;};
  in
    base
    // {
      plugins = map (plugin:
        if plugin.name == "powerlevel10k-config"
        then
          plugin
          // {
            # Home Manager expects plugin sources to be directories.
            src = pkgs.writeTextDir "p10k.zsh" (builtins.readFile ../home/p10k.zsh);
          }
        else plugin)
      base.plugins;
      shellAliases =
        base.shellAliases
        // {
          codex = "GITHUB_PAT_TOKEN=$(gh auth token) command codex";
        };
    };
in {
  imports = [
    ./firefox
    ../home/fastfetch.nix
    ../home/ghostty.nix
    ../home/zellij.nix
  ];

  programs.home-manager.enable = true;

  home.username = "elliott";
  home.homeDirectory = "/Users/elliott";
  home.packages = [
    pkgs.alacritty
    (import ./zen-yt {inherit pkgs;})
    (pkgs.writeScriptBin "reject-screencast" (builtins.readFile ./scripts/reject-screencast))
  ];

  programs.ghostty.settings.font-family = lib.mkForce "JetBrainsMono NFM";
  # Ghostty's multiline prompt rewriting corrupts Powerlevel10k at startup.
  programs.ghostty.enableZshIntegration = false;
  programs.ghostty.settings.shell-integration = "none";

  xdg.enable = true;
  xdg.configFile.nvim.source = mkOutOfStoreSymlink "/Users/elliott/.dotfiles/.config/nvim";

  home.stateVersion = "23.11";
  home.enableNixpkgsReleaseCheck = false;

  programs = {
    git = import ../home/git.nix {inherit config pkgs lib;};
    inherit tmux;
    inherit zsh;
    zoxide = import ../home/zoxide.nix {inherit config pkgs;};
    fzf = import ../home/fzf.nix {inherit pkgs;};
    oh-my-posh =
      (import ../home/oh-my-posh.nix {inherit pkgs;})
      // {
        enableZshIntegration = false;
      };
  };
}
