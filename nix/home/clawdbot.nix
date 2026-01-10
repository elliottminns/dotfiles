# Clawdbot manual setup (nix-clawdbot module has NixOS compatibility issues)
{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    nodejs_22
    nodePackages.pnpm
  ];

  # Fish shell configuration
  programs.fish = {
    enable = true;
    shellAliases = {
      cb = "clawdbot";
    };
    interactiveShellInit = ''
      # Clawdbot environment
      set -gx CLAWDBOT_CONFIG_DIR "$HOME/.config/clawdbot"
      fish_add_path "$HOME/.npm-global/bin"

      # pnpm setup
      set -gx PNPM_HOME "$HOME/.local/share/pnpm"
      fish_add_path "$PNPM_HOME"
    '';
  };

  # npm global config to install clawdbot without sudo
  home.file.".npmrc".text = ''
    prefix=''${HOME}/.npm-global
  '';

  # Create directories
  home.file.".config/clawdbot/.keep".text = "";
  home.file.".npm-global/.keep".text = "";
  home.file.".local/share/pnpm/.keep".text = "";

  # Activation script to install clawdbot if not present
  home.activation.installClawdbot = lib.hm.dag.entryAfter ["writeBoundary"] ''
    export PATH="${pkgs.nodejs_22}/bin:${pkgs.nodePackages.pnpm}/bin:$PATH"
    export PNPM_HOME="$HOME/.local/share/pnpm"
    if [ ! -x "$PNPM_HOME/clawdbot" ]; then
      ${pkgs.nodePackages.pnpm}/bin/pnpm install -g clawdbot@latest || true
    fi
  '';

}
