# AGENTS.md - Nix Dotfiles

This directory contains Nix flake-based system + Home Manager configuration.

## Style
- Prefer `alejandra` formatting for Nix.
- Keep changes small and host-scoped when possible.
- Avoid refactors that churn lockfiles unless necessary.
- Prefer `nixpkgs` packages over Homebrew when they are available and confirmed to work on the target host; verify host support before switching, and use Homebrew for software that is unavailable or unsuitable in `nixpkgs`.

## Safety
- Do not add or commit secrets.
- When editing host configs, confirm the target host (`machines/<host>/`).

## Useful commands
- Format Nix: `nix fmt`
- Check flake: `nix flake check`
- Build a host: `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`
- Switch (NixOS): `sudo nixos-rebuild switch --flake .#<host>`

## Repo conventions
- Hosts live in `machines/<host>/`.
- Shared modules live in `modules/`.
- Home Manager profiles live in `home/`.
