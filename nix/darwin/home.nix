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
in {
  imports = [
    ../home/fastfetch.nix
    ../home/ghostty.nix
    ../home/zellij.nix
  ];

  programs.home-manager.enable = true;

  home.username = "elliott";
  home.homeDirectory = "/Users/elliott";
  home.packages = [
    pkgs.alacritty
  ];

  programs.ghostty.settings.font-family = lib.mkForce "JetBrainsMono NFM";

  xdg.enable = true;
  xdg.configFile.emacs.source = mkOutOfStoreSymlink "/Users/elliott/.dotfiles/emacs";
  home.file.".emacs.d/early-init.el".source = mkOutOfStoreSymlink "/Users/elliott/.dotfiles/emacs/early-init.el";
  home.file.".emacs.d/init.el".source = mkOutOfStoreSymlink "/Users/elliott/.dotfiles/emacs/init.el";
  home.file.".emacs.d/init.org".source = mkOutOfStoreSymlink "/Users/elliott/.dotfiles/emacs/init.org";
  xdg.configFile.nvim.source = mkOutOfStoreSymlink "/Users/elliott/.dotfiles/.config/nvim";

  home.stateVersion = "23.11";
  home.enableNixpkgsReleaseCheck = false;

  programs = {
    emacs = {
      enable = true;
      package = pkgs.emacs;
      extraPackages = epkgs:
        with epkgs; [
          catppuccin-theme
          cape
          consult
          corfu
          corfu-terminal
          cargo
          eldoc-box
          evil
          evil-args
          evil-collection
          evil-commentary
          evil-org
          evil-surround
          general
          highlight-numbers
          marginalia
          orderless
          rainbow-delimiters
          rust-mode
          toml-mode
          (treesit-grammars.with-grammars (grammars:
            with grammars; [
              tree-sitter-rust
              tree-sitter-toml
            ]))
          undo-tree
          vertico
          which-key
        ];
    };
    git = import ../home/git.nix {inherit config pkgs lib;};
    inherit tmux;
    zsh = import ../home/zsh.nix {inherit config pkgs lib;};
    zoxide = import ../home/zoxide.nix {inherit config pkgs;};
    fzf = import ../home/fzf.nix {inherit pkgs;};
    oh-my-posh = import ../home/oh-my-posh.nix {inherit pkgs;};
  };
}
