{pkgs, ...}: {
  imports = [../../modules/workstation-base.nix ./secrets.nix ./rgb.nix];

  services.fwupd.enable = true;
  services.displayManager.gdm.enable = true;
  security.rtkit.enable = true;

  # Enforce the configured credentials on activation, including account unlock.
  users.mutableUsers = false;
  users.users.elliott.extraGroups = ["networkmanager"];
  programs.gnupg.agent.pinentryPackage = pkgs.pinentry-gnome3;
  environment.systemPackages = [pkgs.usbutils];

  system.stateVersion = "26.05";
}
