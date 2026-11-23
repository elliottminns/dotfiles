pkgs: rec {
  gptscript = pkgs.callPackage ./gptscript {};
  banana-cursor-dreams = pkgs.callPackage ./banana-cursor-dreams {};
  blackmagic-desktop-video-vendor = let
    # Newer patchelf versions produce overlapping LOAD segments in the helper.
    patchelf = pkgs.stdenv.mkDerivation {
      pname = "patchelf-desktopvideo";
      version = "0.15.2";
      src = pkgs.fetchurl {
        url = "https://github.com/NixOS/patchelf/releases/download/0.15.2/patchelf-0.15.2.tar.bz2";
        hash = "sha256-F3RfVkFZyOIo/EEtplogSLhGxLa0Igt3y/IkFuAvLXw=";
      };
      enableParallelBuilding = true;
    };
  in
    pkgs.blackmagic-desktop-video.overrideAttrs (oldAttrs: {
      preFixup =
        (oldAttrs.preFixup or "")
        + ''
          export PATH=${pkgs.lib.getBin patchelf}/bin:$PATH
        '';
      postInstall =
        (oldAttrs.postInstall or "")
        + ''
        '';

      postFixup =
        (oldAttrs.postFixup or "")
        + ''
          patchelf --set-rpath '$ORIGIN/blackmagic/DesktopVideo' $out/lib/libDeckLinkAPI.so
          patchelf --set-rpath '$ORIGIN/blackmagic/DesktopVideo' $out/lib/libDeckLinkPreviewAPI.so
        '';
    });
  blackmagic-desktop-video-gui = pkgs.callPackage ./blackmagic-desktop-video-gui {
    inherit blackmagic-desktop-video-vendor;
  };
  avc12-4k-capture = pkgs.callPackage ./avmvc12 {};
  wl-screenrec = pkgs.callPackage ./wl-screenrec {};
  soci-snapshotter = pkgs.callPackage ./soci-snapshotter {};
  # opencode is now provided via flake input (see overlays/default.nix)
  # example = pkgs.callPackage ./example { };
}
