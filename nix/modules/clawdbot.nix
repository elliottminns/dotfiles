# Zenbot dependencies module
# Only applied to hosts with hasClawdUser = true
{ config, pkgs, lib, meta, ... }:

lib.mkIf (meta.hasClawdUser or false) {
  # System packages for Zenbot
  environment.systemPackages = with pkgs; [
    # Node.js runtime
    nodejs_22
    nodePackages.pnpm

    # Native module build deps
    python3
    gcc
    gnumake
    pkg-config

    # Sharp image processing deps
    vips

    # Browser automation (Playwright)
    chromium
    google-chrome  # Fallback for browser tool

    # Media processing
    ffmpeg

    # Utilities
    jq
    curl
    wget
    git
  ];

  # Zenbot systemd service
  systemd.services.zenbot = {
    description = "Zenbot Gateway";
    after = [ "network-online.target" "tailscaled.service" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      NODE_ENV = "production";
      # Playwright browser path
      PLAYWRIGHT_BROWSERS_PATH = "${pkgs.chromium}/bin";
    };

    serviceConfig = {
      Type = "simple";
      User = "zenbot";
      Group = "users";
      WorkingDirectory = "/home/zenbot/zenbot";
      ExecStart = "${pkgs.nodejs_22}/bin/node dist/index.js gateway-daemon --port 18789";
      Restart = "always";
      RestartSec = 5;

      # Security hardening
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      ReadWritePaths = [
        "/home/zenbot/.zenbot"
        "/home/zenbot/workspace"
        "/tmp"
      ];
    };

    # Enable after Zenbot is installed
    enable = false;
  };

  # Firewall rules for Zenbot
  networking.firewall = {
    allowedTCPPorts = [ 18789 18790 18793 ];
  };

  # BTRFS snapshots for /home
  services.btrbk.instances."home" = {
    onCalendar = "hourly";
    settings = {
      snapshot_preserve_min = "2h";
      snapshot_preserve = "24h 7d 4w";  # 24 hourly, 7 daily, 4 weekly
      volume."/home" = {
        snapshot_dir = "/home/.snapshots";
        subvolume."." = {};
      };
    };
  };

  # Create snapshot directory
  systemd.tmpfiles.rules = [
    "d /home/.snapshots 0755 root root -"
  ];

  # Add btrbk tools
  environment.systemPackages = with pkgs; [
    btrbk
    btrfs-progs
    compsize
  ];
}
