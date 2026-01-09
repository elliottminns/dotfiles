{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    mangohud
    protonup-ng
    lutris
  ];
}
