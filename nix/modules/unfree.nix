{
  pkgs,
  lib,
  meta,
  ...
}: {
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) (
      map lib.getName [
        pkgs.discord
        pkgs.unstable.keymapp
        pkgs.signal-desktop
        pkgs.steam
        pkgs.steam-run
        pkgs.steam-original
        pkgs.obsidian
        pkgs.slack
        pkgs.displaylink
        pkgs.davinci-resolve-studio
        pkgs.davinci-resolve
      ]
    );

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs;
    [
      discord
      unstable.keymapp
      obsidian
      signal-desktop
      slack
    ]
    ++ (
      if meta.hostname == "amaterasu"
      then [unstable.davinci-resolve-studio]
      else []
    );
}
