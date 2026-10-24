{
  config,
  pkgs,
  meta,
  lib,
  ...
}: {
  imports = [
    ./common.nix
    ./ags/default.nix
  ];

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

  home.stateVersion = "23.11";

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

  wayland.windowManager = {
    hyprland = import ./hyprland.nix {inherit pkgs meta config;};
  };
}
