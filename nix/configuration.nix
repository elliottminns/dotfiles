# Edit this configuration file to define what should be installed onconfig
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  inputs,
  outputs,
  pkgs,
  meta,
  lib,
  ...
}: let
  my-kubernetes-helm = with pkgs;
    wrapHelm kubernetes-helm {
      plugins = with pkgs.kubernetes-helmPlugins; [
        helm-secrets
        helm-diff
        helm-s3
        helm-git
      ];
    };

  my-helmfile = pkgs.helmfile-wrapped.override {
    inherit (my-kubernetes-helm) pluginsDir;
  };
in {
  imports = [
    ./modules/languages.nix
    ./modules/workstation-base.nix
    ./modules/gaming.nix
    ./modules/messaging.nix
    ./modules/unfree.nix
    ./modules/video.nix
    ./modules/k3s-worker.nix
  ];

  # Allows uv-managed Python downloads and other generic Linux binaries to run.
  programs.nix-ld.enable = true;

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.kiru
      outputs.overlays.modifications
      inputs.claude-code.overlays.default
      inputs.templ.overlays.default

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      permittedInsecurePackages = [
        "electron-25.9.0"
      ];
    };
  };

  services.mullvad-vpn.enable = true;
  services.ollama = {
    enable = true;
    host = "0.0.0.0";
    package = pkgs.ollama-rocm;
    loadModels = [
      "glm-4.7-flash"
      "gemma3:27b"
      "llama4:16x17b"
    ];
  };
  services.systembus-notify.enable = true;
  services.hardware.bolt.enable = true; # Thunderbolt device management (boltctl)

  # Blackmagic Desktop Video is sensitive to bleeding-edge kernels; keep zenbox
  # off linuxPackages_latest so DeckLink API enumeration works reliably.
  boot.kernelPackages =
    if meta.hostname == "zenbox"
    then pkgs.linuxPackages
    else pkgs.linuxPackages_latest;

  # Helps recover from transient GPU/display glitches (e.g. hotplug/input-switch).
  boot.kernelParams = [
    "amdgpu.gpu_recovery=1"
  ];

  networking.extraHosts = "";

  networking.networkmanager.insertNameservers = [
    "192.168.0.1"
  ];
  networking.nameservers = [
    "192.168.0.1"
  ];

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  console = {
    font = "Lat2-Terminus16";
    #   useXkbConfig = true; # use xkb.options in tty.
  };

  fonts.packages = with pkgs; [
    openmoji-color
  ];

  # Define groups
  users.groups.dotfiles = {};

  systemd.tmpfiles.rules = [
    "d /var/lib/soci-snapshotter-grpc 0755 root root -"
  ];

  environment.sessionVariables = lib.mkIf (meta.hostname == "zenbox") {
    PKG_CONFIG_PATH = lib.makeSearchPath "lib/pkgconfig" [
      pkgs.glib.dev
      pkgs.gtk3.dev
    ];
  };

  # Additional groups and packages for development workstations.
  users.users.elliott = {
    extraGroups = [
      "docker"
      "containerd"
      "input"
      "uinput"
      "dotfiles"
    ];
    packages = with pkgs; [
      tree
    ];
  };

  hardware.keyboard.qmk.enable = true;

  # $ nix search wget
  environment.systemPackages = with pkgs; [
    act
    bat
    alejandra
    argocd
    awscli2
    banana-cursor-dreams
    bubblewrap
    chromium
    clickgen
    cloud-utils
    cmake
    distrobox
    dotool
    doppler
    emacs
    eza
    fzf
    glib
    gh
    go-migrate
    goimports-reviser
    golines
    gptscript
    grim # screenshot functionality
    gtk3
    k6
    fastfetch
    hyprpaper
    hyprpicker
    inputs.zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".default
    imagemagick
    just
    jq
    kanata
    keylight-controller-mschneider82
    kubectl
    kubectx
    kustomize
    lua-language-server
    mako # notification system developed by swaywm maintainer
    htop
    nvtopPackages.full
    mullvad-vpn
    mm-common
    my-helmfile
    my-kubernetes-helm
    nil
    nwg-look
    ((wrapOBS.override (lib.optionalAttrs (meta.hostname == "zenbox") {
        obs-studio = pkgs.obs-studio.override {
          decklinkSupport = true;
        };
      })) {
        plugins = with pkgs.obs-studio-plugins; [
          wlrobs
          obs-backgroundremoval
          obs-pipewire-audio-capture
          obs-gstreamer
          obs-vaapi
        ];
      })
    openssl
    pika-backup
    python3
    pkg-config
    postgresql
    proton-vpn-cli
    proton-vpn
    qemu
    qmk
    rclone
    slurp
    spotify
    sqlc
    streamcontroller
    unstable.stripe-cli
    stow
    stylua
    templ
    opentofu
    tmux
    transmission_4-gtk
    typescript-language-server
    wvkbd
    showmethekey
    wshowkeys
    unstable.wl-screenrec
    wf-recorder
    gpu-screen-recorder
    libva-utils
    wofi
    vlc
    mpv

    ffmpeg
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
    rustup
    kiru.kiru
    cargo-watch
    cargo-edit
    pkgsCross.mingwW64.stdenv.cc

    zenity
    zellij
    zip
    avahi
    nssmdns
    asciinema
    jrnl
    claude-code
    inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
    cosmic-ext-tweaks
    soci-snapshotter
  ];

  # Virtualisation
  virtualisation.containerd.enable = true;
  users.groups.containerd.gid = 994;
  virtualisation.containerd.settings.grpc.gid = 994;
  virtualisation.docker.enable = true;
  virtualisation.libvirtd.enable = true;
  virtualisation.podman = {
    enable = true;
  };

  programs.virt-manager.enable = true;

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # Steam
  programs.steam = {
    enable = true;
    extraCompatPackages = [
      pkgs.proton-ge-bin
    ];
    gamescopeSession = {
      enable = true;
    };
  };

  programs.gamemode.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;

  # enable sway window manager
  programs.sway = {
    enable = false;
    wrapperFeatures.gtk = true;
  };

  security.polkit.enable = true;

  programs.hyprland.enable = true;

  # Enable Bonjour
  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;

  services.postgresql = {
    enable = true;
    authentication = pkgs.lib.mkOverride 10 ''
      #type database  DBuser  auth-method
      local all       all     trust
      host  all       all     127.0.0.1/32 trust
    '';
  };

  # gnome
  services.displayManager.gdm.enable = false;

  # COSMIC
  # Enable the COSMIC login manager
  services.displayManager.cosmic-greeter.enable = true;
  # Enable the COSMIC desktop environment
  services.desktopManager.cosmic.enable = true;

  # Audio (PipeWire) — explicit config ensures ALSA plugin paths stay consistent
  services.pipewire.alsa.support32Bit = true;

  xdg.portal = {
    enable = true;
    extraPortals = lib.mkForce [
      pkgs.xdg-desktop-portal-gtk # For both
      pkgs.xdg-desktop-portal-hyprland # For Hyprland
      pkgs.xdg-desktop-portal-gnome # For GNOME
    ];
    config = {
      gnome = {
        default = [
          "gnome"
          "gtk"
        ];
        "org.freedesktop.portal.FileChooser" = ["gnome"];
      };
      hyprland = {
        default = [
          "hyprland"
          "gtk"
        ];
        "org.freedesktop.impl.portal.FileChooser" = ["gtk"];
      };
      common = {
        default = ["gtk"];
      };
    };
  };

  services.kanata = {
    enable = true;
    keyboards = {
      internalKeyboard = {
        devices = [
          "/dev/input/by-path/platform-i8042-serio-0-event-kbd"
          "/dev/input/by-id/usb-Framework_Laptop_16_Keyboard_Module_-_ANSI_FRAKDKEN0100000000-event-kbd"
          "/dev/input/by-id/usb-Framework_Laptop_16_Keyboard_Module_-_ANSI_FRAKDKEN0100000000-if02-event-kbd"
        ];
        extraDefCfg = "process-unmapped-keys yes";
        config = ''
          (defsrc
           caps a s d f j k l ;
          )
          (defvar
           tap-time 150
           hold-time 200
          )
          (defalias
           caps (tap-hold 100 100 esc lctl)
           a (tap-hold $tap-time $hold-time a lmet)
           s (tap-hold $tap-time $hold-time s lalt)
           d (tap-hold $tap-time $hold-time d lsft)
           f (tap-hold $tap-time $hold-time f lctl)
           j (tap-hold $tap-time $hold-time j rctl)
           k (tap-hold $tap-time $hold-time k rsft)
           l (tap-hold $tap-time $hold-time l ralt)
           ; (tap-hold $tap-time $hold-time ; rmet)
          )


          (deflayer base
           @caps @a  @s  @d  @f  @j  @k  @l  @;
          )
        '';
      };
    };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "23.11"; # Did you read the comment?
}
