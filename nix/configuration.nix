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
    ./modules/gnome.nix
    ./modules/gaming.nix
    ./modules/messaging.nix
    ./modules/yubikey-gpg.nix
    ./modules/unfree.nix
    ./modules/video.nix
  ];

  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings.warn-dirty = false;
  };

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.unstable
      outputs.overlays.modifications
      inputs.templ.overlays.default
      inputs.alacritty-theme.overlays.default

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
  services.systembus-notify.enable = true;

  # Use the latest linux kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # List packages installed in system profile. To search, run:
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = meta.hostname; # Hostname is defined by the flake.

  # Pick only one of the below networking options.
  #networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
    #   useXkbConfig = true; # use xkb.options in tty.
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    openmoji-color
  ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.elliott = {
    isNormalUser = true;
    extraGroups = [
      "wheel" # Enable ‘sudo’ for the user.
      "docker"
      "input"
      "uinput"
    ];
    shell = pkgs.zsh;
    packages = with pkgs; [
      tree
    ];
    hashedPassword = "$6$026yeBrVd8/z.7CJ$e9Fl5oMabKXM6fRC0V7kG/LCZnCyunekKLY4T3Vi/zQXV7PpOcTchDpxr0opnI3zA4.2V9yyu51h1tF.4UoHT1";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDNFZUZg93LySz/1Qdg7WBEBdpnSMjJyJmFwnPikmTHJ/MQWC0Bf5kVyfkLxaU3paeRQnoI4RcG9k8DJGy8hnUdxe2Eg5fWtW0+cJ0zm791WisCTb8bCmTBO9053U59qOA7WTrJAVcTylBsBa7R3CGs6FYlMsu8CXvUWrp4XQ2k83DQlzpgr5r9BNIsfbfswXMSm91i/bRSuxSXu2QpV/9C4wHBUYAGz+hTFw8LJgt/lH6ute2w1ed93/vG4CNI9gv1obecc8rrVGvjZk1Q6sPr8PamBxc7Y4HEYWKPtJPq54UK+b2duUuL2tDYVQmJIvto6how+EZ/oAPxMRK5qHJOn2AJ/z0rcPO6FqyggtKeZATOgFCYSNLLrEwiYvppVNiM/hjFRqpk+BZ+gWE1X+D3xXIDUG1jchMCUQ/2q62CSp/VU/z39IGBxa9eN/k6WsmdlKgeCcx2BtoFKMd0LQqfndduYPcnvn2EzJwLrF0p7LQGIO74jkAQ451IeSoDOvlCe9Y9LAjwH1DG4ve7XwuqpKdJ2LcHirLHxQIONdc906U70TVuQzGOJed5huhKBkbGzDi08VsF8zCO9pMHSJ2ioBWVyNSRUf9wVKtPtUFhmgCHT/l0+xdrCeE8m7sT0Zb8qNjdMDylXQhaPm30f/ievIBe5+81w0Kyoj4kFSzr3Q== cardno:11_070_772"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  hardware.keyboard.qmk.enable = true;

  # $ nix search wget
  environment.systemPackages = with pkgs; [
    act
    alejandra
    argocd
    awscli
    #banana-cursor
    banana-cursor-dreams
    bubblewrap
    #calibre
    chromium
    clickgen
    distrobox
    dotool
    doppler
    emacs
    eza
    firefox
    fzf
    git
    glib
    go-migrate
    goimports-reviser
    golines
    gptscript
    grim # screenshot functionality
    gtk3
    k6
    hyprpaper
    hyprpicker
    unstable.ghostty
    inputs.zen-browser.packages."${system}".default
    imagemagick
    jq
    kanata
    keylight-controller-mschneider82
    kubectl
    kubectx
    kustomize
    lua-language-server
    mako # notification system developed by swaywm maintainer
    mullvad-vpn
    mm-common
    my-helmfile
    my-kubernetes-helm
    neovim
    nil
    nwg-look
    (wrapOBS {
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs
        obs-backgroundremoval
        obs-pipewire-audio-capture
        obs-gstreamer
        obs-vaapi
      ];
    })
    oh-my-posh
    openssl
    pika-backup
    python3
    pkg-config
    pop-gtk-theme
    postgresql
    protonvpn-cli
    protonvpn-gui
    qemu
    qmk
    rclone
    ripgrep
    sassc
    slurp
    spotify
    sqlc
    streamcontroller
    unstable.stripe-cli
    stow
    stylua
    templ
    tmux
    transmission_4-gtk
    typescript-language-server
    unzip
    wvkbd
    showmethekey
    wshowkeys
    wl-screenrec
    wl-clipboard
    wofi
    vlc
    zenity
    zellij
    zip
    avahi
    nssmdns
    railway
  ];

  # Virtualisation
  virtualisation.docker.enable = true;
  virtualisation.libvirtd.enable = true;
  virtualisation.podman = {
    enable = true;
  };

  programs.virt-manager.enable = true;

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
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # enable sway window manager
  programs.sway = {
    enable = false;
    wrapperFeatures.gtk = true;
  };

  security.polkit.enable = true;

  programs.hyprland.enable = true;

  programs.zsh.enable = true;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

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
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = lib.mkForce [
      pkgs.xdg-desktop-portal-gtk # For both
      pkgs.xdg-desktop-portal-hyprland # For Hyprland
      pkgs.xdg-desktop-portal-gnome # For GNOME
    ];
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
           a (multi f24 (tap-hold $tap-time $hold-time a lmet))
           s (multi f24 (tap-hold $tap-time $hold-time s lalt))
           d (multi f24 (tap-hold $tap-time $hold-time d lsft))
           f (multi f24 (tap-hold $tap-time $hold-time f lctl))
           j (multi f24 (tap-hold $tap-time $hold-time j rctl))
           k (multi f24 (tap-hold $tap-time $hold-time k rsft))
           l (multi f24 (tap-hold $tap-time $hold-time l ralt))
           ; (multi f24 (tap-hold $tap-time $hold-time ; rmet))
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
