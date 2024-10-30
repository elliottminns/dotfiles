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
    package = pkgs.banana-cursor-dreams;
    size = meta.cursor;
    name = "Banana-Catppuccin-Mocha";
  };

  xdg.enable = true;

  xdg.configFile.nvim.source = mkOutOfStoreSymlink "/home/elliott/.dotfiles/.config/nvim";
  xdg.dataFile.password-store.source = mkOutOfStoreSymlink "/home/elliott/.password-store";

  dconf = {
    enable = true;
    settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
  };

  home.stateVersion = "23.11";

  programs = {
    tmux = import ./tmux.nix {inherit pkgs;};
    zsh = import ./zsh.nix {inherit config pkgs lib;};
    neovim = import ./neovim.nix {inherit config pkgs;};
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
