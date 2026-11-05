{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (config.lib.file) mkOutOfStoreSymlink;
  whisperModel = pkgs.fetchurl {
    name = "ggml-large-v3-turbo.bin";
    url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/5359861c739e955e79d9a303bcbc70fb988958b1/ggml-large-v3-turbo.bin";
    hash = "sha256-H8cPd0046xaZk6w5Huo1fvR8iHV+9y7llDh5t+jivGk=";
  };
  whisperBaseEnModel = pkgs.fetchurl {
    name = "ggml-base.en.bin";
    url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/5359861c739e955e79d9a303bcbc70fb988958b1/ggml-base.en.bin";
    hash = "sha256-oDd5yG3zMjB19eeWyyzlAp8A7Ihp7uP9+4l6/jbG0AI=";
  };
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
    ../home/ghcr.nix
    ./firefox
    ../home/fastfetch.nix
    ../home/ghostty.nix
    ../home/zellij.nix
  ];

  programs.home-manager.enable = true;

  home.username = "elliott";
  home.homeDirectory = "/Users/elliott";
  home.packages = [
    (import ./zen-yt {inherit pkgs;})
    (pkgs.writeScriptBin "reject-screencast" (builtins.readFile ./scripts/reject-screencast))
  ];

  programs.ghostty.settings = {
    font-family = lib.mkForce "JetBrainsMono NFM";
    window-decoration = lib.mkForce "auto";
  };
  xdg.enable = true;
  xdg.configFile.nvim.source = mkOutOfStoreSymlink "/Users/elliott/.dotfiles/.config/nvim";

  home.stateVersion = "23.11";
  home.enableNixpkgsReleaseCheck = false;
  home.file.".local/share/whisper/ggml-large-v3-turbo.bin".source = whisperModel;
  home.file.".local/share/whisper/ggml-base.en.bin".source = whisperBaseEnModel;

  programs = {
    alacritty =
      lib.recursiveUpdate
      (import ../home/alacritty.nix {inherit pkgs;})
      {
        settings.font = {
          normal.family = "JetBrainsMono NFM";
          bold.family = "JetBrainsMono NFM";
          italic.family = "JetBrainsMono NFM";
          bold_italic.family = "JetBrainsMono NFM";
        };
      };
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
