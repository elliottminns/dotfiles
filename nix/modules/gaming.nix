{
  lib,
  meta,
  pkgs,
  ...
}: {
  environment.systemPackages =
    (with pkgs; [
      mangohud
      protonup-ng
    ])
    ++ lib.optionals (meta.hasGaming or true) (with pkgs; [
      lutris
    ]);
}
