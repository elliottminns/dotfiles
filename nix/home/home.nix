{
  config,
  pkgs,
  meta,
  lib,
  ...
}: let
  inherit (config.lib.file) mkOutOfStoreSymlink;
in {
  imports = [
    ./ags/default.nix
  ];

  programs.home-manager.enable = true;

  home.username = "elliott";
  home.homeDirectory = "/home/elliott";
  home.pointerCursor = {
    x11.enable = true;
    gtk.enable = true;
    package = pkgs.bibata-cursors;
    size = meta.cursor;
    name = "Bibata-Modern-Classic";
  };

  xdg.enable = true;

  xdg.configFile.emacs.source = mkOutOfStoreSymlink "/home/elliott/.dotfiles/emacs";
  home.file.".emacs.d/early-init.el".source = mkOutOfStoreSymlink "/home/elliott/.dotfiles/emacs/early-init.el";
  home.file.".emacs.d/init.el".source = mkOutOfStoreSymlink "/home/elliott/.dotfiles/emacs/init.el";
  home.file.".emacs.d/init.org".source = mkOutOfStoreSymlink "/home/elliott/.dotfiles/emacs/init.org";
  xdg.configFile.nvim.source = mkOutOfStoreSymlink "/home/elliott/.dotfiles/.config/nvim";
  xdg.dataFile.password-store.source = mkOutOfStoreSymlink "/home/elliott/.password-store";

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
      xdg-desktop-portal-hyprland
    ];
    config = {
      common.default = ["gtk"];
      gnome = {
        default = ["gnome" "gtk"];
        "org.freedesktop.portal.FileChooser" = ["gnome"];
      };
      hyprland = {
        default = ["hyprland" "gtk"];
        "org.freedesktop.impl.portal.FileChooser" = ["gtk"];
      };
    };
  };

  dconf = {
    enable = true;
    settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
  };

  home.stateVersion = "23.11";

  home.sessionVariables.EDITOR = "nvim";

  home.packages = with pkgs; [
    bacon
    telegram-desktop
    opencode
    neovim
  ];

  home.shellAliases = {
    vi = "nvim";
    vim = "nvim";
  };

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
    git = import ./git.nix {inherit config pkgs;};
    alacritty = import ./alacritty.nix {inherit config pkgs meta;};
    gpg = import ./gpg.nix {inherit config pkgs;};
    zoxide = import ./zoxide.nix {inherit config pkgs;};
    firefox = import ./firefox.nix {inherit pkgs;};
    password-store = import ./pass.nix {inherit pkgs;};
    fzf = import ./fzf.nix {inherit pkgs;};
  };

  services = {
    hyprpaper = {
      enable = true;
      settings = {
        preload = [
          "$HOME/.dotfiles/wallpapers/purple-bokah.jpg"
          "$HOME/.dotfiles/wallpapers/abstract.png"
        ];

        wallpaper = map (monitor: "${monitor.name},$HOME/.dotfiles/wallpapers/abstract.png") meta.monitors;
      };
    };
  };

  gtk = {
    enable = true;
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  wayland.windowManager = {
    hyprland = import ./hyprland.nix {inherit pkgs meta config;};
  };
}
