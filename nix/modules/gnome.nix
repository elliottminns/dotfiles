{pkgs, ...}: {
  services.accounts-daemon.enable = true;
  services.gnome.gnome-online-accounts.enable = true;

  environment.systemPackages = with pkgs; [
    gnome.networkmanager-openvpn
    gnome.gnome-shell-extensions
    gnomeExtensions.tiling-assistant
    gnomeExtensions.window-calls
  ];
}
