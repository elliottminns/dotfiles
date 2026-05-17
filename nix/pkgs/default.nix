pkgs: rec {
  gptscript = pkgs.callPackage ./gptscript {};
  banana-cursor-dreams = pkgs.callPackage ./banana-cursor-dreams {};
  blackmagic-desktop-video-vendor = pkgs.blackmagic-desktop-video.overrideAttrs (oldAttrs: {
    postInstall =
      (oldAttrs.postInstall or "")
      + ''
        mkdir -p $out/lib/blackmagic/DesktopVideo
        cp $unpacked/usr/lib/blackmagic/DesktopVideo/libc++.so.1 $out/lib/blackmagic/DesktopVideo/
        cp $unpacked/usr/lib/blackmagic/DesktopVideo/libc++abi.so.1 $out/lib/blackmagic/DesktopVideo/
        cp $unpacked/usr/lib/blackmagic/DesktopVideo/libgcc_s.so.1 $out/lib/blackmagic/DesktopVideo/
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
