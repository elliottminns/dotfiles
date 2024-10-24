{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod"];
  boot.initrd.kernelModules = ["dm-snapshot" "amdgpu"];
  boot.kernelModules = ["kvm-amd"];
  boot.extraModulePackages = [pkgs.avc12-4k-capture];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp67s0f0.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp67s0f1.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp70s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      amdvlk
      rocmPackages.clr.icd
      libva
      libvdpau-va-gl
    ];
  };

  services.xserver.videoDrivers = [
    "amdgpu"
    "displaylink"
    "modesetting"
  ];

  fileSystems."/mnt/video-assets" = {
    device = "truenas:/mnt/main/enc/video-assets";
    fsType = "nfs";
    options = ["x-systemd.automount" "noauto"];
  };

  environment.systemPackages = [
    pkgs.clinfo
    pkgs.displaylink
    pkgs.rocmPackages.rocminfo
  ];
}
