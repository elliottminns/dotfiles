pkgs: {
  gptscript = pkgs.callPackage ./gptscript {};
  banana-cursor-dreams = pkgs.callPackage ./banana-cursor-dreams {};
  avc12-4k-capture = pkgs.callPackage ./avmvc12 {};
  wl-screenrec = pkgs.callPackage ./wl-screenrec {};
  # opencode is now provided via flake input (see overlays/default.nix)
  # example = pkgs.callPackage ./example { };
}
