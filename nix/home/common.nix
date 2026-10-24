{
  config,
  pkgs,
  meta,
  lib,
  ...
}: let
  inherit (config.lib.file) mkOutOfStoreSymlink;
in {
  imports = [./gnome.nix ./ghostty.nix ./ghcr.nix ./zellij.nix];

  programs.home-manager.enable = true;

  home.username = "elliott";

  home.homeDirectory = "/home/elliott";

  home.pointerCursor = {
    enable = true;
    x11.enable = true;
    gtk.enable = true;
    package = pkgs.bibata-cursors;
    size = meta.cursor;
    name = "Bibata-Modern-Classic";
  };

  xdg.enable = true;

  home.sessionVariables.EDITOR = "nvim";

  home.shellAliases = {
    vi = "nvim";
    vim = "nvim";
  };

  gtk = {
    enable = true;
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  programs.git = import ./git.nix {inherit config pkgs;};

  programs.fzf = import ./fzf.nix {inherit pkgs;};

  programs.zoxide = import ./zoxide.nix {inherit config pkgs;};

  xdg.configFile.emacs.source = mkOutOfStoreSymlink "/home/elliott/.dotfiles/emacs";
  home.file.".emacs.d/early-init.el".source = mkOutOfStoreSymlink "/home/elliott/.dotfiles/emacs/early-init.el";
  home.file.".emacs.d/init.el".source = mkOutOfStoreSymlink "/home/elliott/.dotfiles/emacs/init.el";
  home.file.".emacs.d/init.org".source = mkOutOfStoreSymlink "/home/elliott/.dotfiles/emacs/init.org";
  xdg.configFile.nvim.source = mkOutOfStoreSymlink "/home/elliott/.dotfiles/.config/nvim";
  xdg.dataFile.password-store.source = mkOutOfStoreSymlink "/home/elliott/.password-store";

  home.packages = with pkgs; [
    bacon
    docker-credential-helpers
    telegram-desktop
    opencode
    neovim
  ];

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
    tmux = import ./tmux.nix {inherit pkgs;};
    zsh = import ./zsh.nix {inherit config pkgs lib;};
    starship = import ./starship.nix {inherit config pkgs lib;};
    fish = import ./fish.nix {inherit pkgs;};
    alacritty = import ./alacritty.nix {inherit config pkgs meta;};
    gpg = import ./gpg.nix {inherit config pkgs;};
    firefox = import ./firefox.nix {inherit pkgs;};
    password-store = import ./pass.nix {inherit config;};
  };
}
