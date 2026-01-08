# Hardware configuration for zenbox (Framework Desktop)
# This is a placeholder - regenerate with nixos-generate-config on actual hardware
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Framework Desktop - adjust based on actual hardware
  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];  # or kvm-intel
  boot.extraModulePackages = [ ];

  # LUKS
  boot.initrd.luks.devices."crypted".device = "/dev/disk/by-partlabel/luks";

  # Firmware updates
  services.fwupd.enable = true;
  hardware.enableRedistributableFirmware = true;

  # CPU
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  # hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
