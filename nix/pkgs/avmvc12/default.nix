{
  pkgs,
  stdenv,
  lib,
  fetchFromGitHub,
  nukeReferences,
}:
stdenv.mkDerivation rec {
  pname = "avmvc12-${version}-${pkgs.linuxPackages_latest.kernel.version}";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "GloriousEggroll";
    repo = "AVMATRIX-VC12-4K-CAPTURE";
    rev = "main";
    hash = "sha256-poAjXYQoMF9k0NyrHqdinOm2xjhEcyV0xdFP83z24cg=";
  };

  sourceRoot = "source/src";

  hardeningDisable = ["pic"];

  nativeBuildInputs = [nukeReferences] ++ [pkgs.linuxPackages_latest.kernel.moduleBuildDependencies];

  makeFlags = [
    "KERNELRELEASE=${pkgs.linuxPackages_latest.kernel.modDirVersion}"
    "KERNELDIR=${pkgs.linuxPackages_latest.kernel.dev}/lib/modules/${pkgs.linuxPackages_latest.kernel.modDirVersion}/build"
    "INSTALL_MOD_PATH=$(out)"
  ];

  installPhase = ''
    mkdir -p $out/lib/modules/${pkgs.linuxPackages_latest.kernel.modDirVersion}/drivers/misc
    for x in $(find . -name '*.ko'); do
      nuke-refs $x
      cp $x $out/lib/modules/${pkgs.linuxPackages_latest.kernel.modDirVersion}/drivers/misc/
    done
  '';

  meta = with lib; {
    description = "Kernel module for AVMATRIX VC12-4K PCIe video capture card with small modifications by GloriousEggroll (Thomas Crider).";
    homepage = "https://www.avmatrix.com/products/vc12-4k-4k-hdmi-pcie-capture-card/";
    license = licenses.gpl2;

    platforms = platforms.linux;
  };
}
