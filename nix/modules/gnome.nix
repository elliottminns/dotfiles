{pkgs, ...}: {
  services.accounts-daemon.enable = true;
  services.gnome.gnome-online-accounts.enable = true;

  environment.systemPackages = with pkgs; [
    networkmanager-openvpn
    gnome-shell-extensions
    gnomeExtensions.tiling-assistant
    gnomeExtensions.window-calls
  ];
}
