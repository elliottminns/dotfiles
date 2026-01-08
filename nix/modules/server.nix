# Server-specific configuration module
# Used for headless machines like zenbox
{ config, pkgs, lib, meta, ... }:

lib.mkIf (meta.server or false) {
  # Disable desktop services
  services.xserver.enable = lib.mkForce false;
  services.xserver.displayManager.gdm.enable = lib.mkForce false;
  services.xserver.desktopManager.gnome.enable = lib.mkForce false;
  programs.hyprland.enable = lib.mkForce false;
  programs.sway.enable = lib.mkForce false;
  services.kanata.enable = lib.mkForce false;
  
  # Server-specific packages
  environment.systemPackages = with pkgs; [
    # Core tools
    vim
    htop
    tmux
    git
    curl
    wget
    jq
    ripgrep
    fd
    tree
    
    # Node.js for Clawdbot
    nodejs_22
    nodePackages.pnpm
    
    # Media processing
    ffmpeg
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
  ];

  # Clawdbot systemd service
  systemd.services.clawdbot = {
    description = "Clawdbot Gateway";
    after = [ "network-online.target" "tailscaled.service" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "simple";
      User = "elliott";
      Group = "users";
      WorkingDirectory = "/home/elliott/clawdbot";
      ExecStart = "${pkgs.nodejs_22}/bin/node dist/index.js gateway-daemon --port 18789";
      Restart = "always";
      RestartSec = 5;
    };
    
    # Don't start until Clawdbot is installed
    enable = false;
  };

  # Server firewall
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
    allowedTCPPorts = [ 22 18789 18790 18793 ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };

  # BTRFS snapshots for home
  services.btrbk = {
    instances."home" = {
      onCalendar = "daily";
      settings = {
        snapshot_preserve_min = "1d";
        snapshot_preserve = "7d 4w 3m";
        volume."/home" = {
          snapshot_dir = "/home/.snapshots";
          subvolume."." = {};
        };
      };
    };
  };
}
