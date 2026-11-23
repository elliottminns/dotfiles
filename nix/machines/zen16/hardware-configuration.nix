{
  config,
  lib,
  modulesPath,
  ...
}: {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "thunderbolt" "usbhid" "usb_storage" "sd_mod"];
  boot.initrd.kernelModules = ["amdgpu"];
  boot.kernelModules = ["kvm-amd"];
  boot.extraModulePackages = [];

  # The package copies the .ko directly, bypassing nixpkgs' module signing.
  # Generate the certificate required when assembling the kernel module closure.
  nixpkgs.overlays = [
    (final: prev: {
      linuxPackages_latest = prev.linuxPackages_latest.extend (_kernelFinal: kernelPrev: {
        framework-laptop-kmod = kernelPrev.framework-laptop-kmod.overrideAttrs (old: {
          postInstall =
            (old.postInstall or "")
            + ''
              ${final.kmodigest}/bin/kmodigest "$out/lib/modules/${kernelPrev.kernel.modDirVersion}/extra/framework_laptop.ko"
            '';
        });
      });
    })
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
