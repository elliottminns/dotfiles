{
  inputs,
  outputs,
  pkgs,
  meta,
  lib,
  ...
}: {
  imports = [./gnome.nix ./yubikey-gpg.nix];

  nix.package = pkgs.nixVersions.stable;
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    warn-dirty = false;
  };
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    outputs.overlays.unstable
    inputs.alacritty-theme.overlays.default
  ];

  networking.hostName = meta.hostname;
  networking.networkmanager.enable = true;
  services.tailscale.enable = true;
  services.openssh.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;
  hardware.enableRedistributableFirmware = true;

  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  services.xserver.enable = true;
  services.desktopManager.gnome.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  users.users.elliott = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    shell = pkgs.zsh;
    hashedPassword = "$6$026yeBrVd8/z.7CJ$e9Fl5oMabKXM6fRC0V7kG/LCZnCyunekKLY4T3Vi/zQXV7PpOcTchDpxr0opnI3zA4.2V9yyu51h1tF.4UoHT1";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDNFZUZg93LySz/1Qdg7WBEBdpnSMjJyJmFwnPikmTHJ/MQWC0Bf5kVyfkLxaU3paeRQnoI4RcG9k8DJGy8hnUdxe2Eg5fWtW0+cJ0zm791WisCTb8bCmTBO9053U59qOA7WTrJAVcTylBsBa7R3CGs6FYlMsu8CXvUWrp4XQ2k83DQlzpgr5r9BNIsfbfswXMSm91i/bRSuxSXu2QpV/9C4wHBUYAGz+hTFw8LJgt/lH6ute2w1ed93/vG4CNI9gv1obecc8rrVGvjZk1Q6sPr8PamBxc7Y4HEYWKPtJPq54UK+b2duUuL2tDYVQmJIvto6how+EZ/oAPxMRK5qHJOn2AJ/z0rcPO6FqyggtKeZATOgFCYSNLLrEwiYvppVNiM/hjFRqpk+BZ+gWE1X+D3xXIDUG1jchMCUQ/2q62CSp/VU/z39IGBxa9eN/k6WsmdlKgeCcx2BtoFKMd0LQqfndduYPcnvn2EzJwLrF0p7LQGIO74jkAQ451IeSoDOvlCe9Y9LAjwH1DG4ve7XwuqpKdJ2LcHirLHxQIONdc906U70TVuQzGOJed5huhKBkbGzDi08VsF8zCO9pMHSJ2ioBWVyNSRUf9wVKtPtUFhmgCHT/l0+xdrCeE8m7sT0Zb8qNjdMDylXQhaPm30f/ievIBe5+81w0Kyoj4kFSzr3Q== cardno:11_070_772"
    ];
  };
  security.sudo.wheelNeedsPassword = false;
  programs.zsh.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = lib.mkDefault pkgs.pinentry-tty;
  };

  fonts.packages = [pkgs.nerd-fonts.jetbrains-mono];
  environment.systemPackages = with pkgs; [
    firefox
    git
    neovim
    ripgrep
    unzip
    pciutils
    wl-clipboard
  ];
}
