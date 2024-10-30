{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    mangohud
    #retroarchFull
    protonup
    lutris
  ];
}
