pkgs: {
  gptscript = pkgs.callPackage ./gptscript {};
  banana-cursor-dreams = pkgs.callPackage ./banana-cursor-dreams {};
  avc12-4k-capture = pkgs.callPackage ./avmvc12 {};
  wl-screenrec = pkgs.callPackage ./wl-screenrec {};
  opencode = pkgs.callPackage ./opencode {};
  # example = pkgs.callPackage ./example { };
}
