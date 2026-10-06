# Standalone host integration: copy this directory into Zenbox's NixOS repo
# and import this file only for Zenbox. No production VPS input is needed.
{...}: let
  source = builtins.fetchTree {
    type = "github";
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "7fc6f2c20af09cdcaf48b92ec3121860139ec668";
    narHash = "sha256-bNyvoIyOCu7lzoCpWKWGIsHpTtERUWzqYWFPlN++WTw=";
  };
  system = "x86_64-linux";
  pkgs = import source {inherit system;};
  guest = import (source + "/nixos/lib/eval-config.nix") {
    inherit system;
    modules = [./vm.nix];
  };
  unit = import ./host-service.nix {
    inherit pkgs;
    vm = guest.config.system.build.vm;
  };
in {
  systemd.units."zenbox-builder.service" = {
    text = builtins.readFile unit;
    wantedBy = ["multi-user.target"];
  };
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "zenbox-builder-exec" ''
      exec ${pkgs.python3}/bin/python3 ${./guest-exec.py} "$@"
    '')
  ];
}
