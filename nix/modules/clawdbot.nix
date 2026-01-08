# Clawdbot dependencies module
# Only applied to hosts with hasClawdUser = true
{ config, pkgs, lib, meta, ... }:

lib.mkIf (meta.hasClawdUser or false) {
  # System packages for Clawdbot
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

  # Clawdbot systemd service
  systemd.services.clawdbot = {
    description = "Clawdbot Gateway";
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
      User = "clawd";
      Group = "users";
      WorkingDirectory = "/home/clawd/clawdbot";
      ExecStart = "${pkgs.nodejs_22}/bin/node dist/index.js gateway-daemon --port 18789";
      Restart = "always";
      RestartSec = 5;
      
      # Security hardening
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      ReadWritePaths = [ 
        "/home/clawd/.clawdbot" 
        "/home/clawd/clawd"
        "/tmp"
      ];
    };
    
    # Enable after Clawdbot is installed
    enable = false;
  };

  # Firewall rules for Clawdbot
  networking.firewall = {
    allowedTCPPorts = [ 18789 18790 18793 ];
  };

  # BTRFS snapshots for clawd home (if using BTRFS)
  services.btrbk.instances."clawd-home" = {
    onCalendar = "daily";
    settings = {
      snapshot_preserve_min = "1d";
      snapshot_preserve = "7d 4w";
      volume."/home/clawd" = {
        snapshot_dir = "/home/clawd/.snapshots";
        subvolume."." = {};
      };
    };
  };
}
