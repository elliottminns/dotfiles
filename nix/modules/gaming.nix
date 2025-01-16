{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    mangohud
    protonup
    lutris
  ];
}
