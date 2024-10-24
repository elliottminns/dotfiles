{pkgs}:
pkgs.stdenv.mkDerivation {
  name = "banana-cursor-dreams";
  version = "2.2.0";
  src = builtins.fetchurl {
    url = "https://github.com/dreamsofautonomy/banana-cursor/releases/download/v2.2.0/banana-all.tar.xz";
    sha256 = "0471nrq7x5v12hyzf11qav7rldb3bnf1529vy21fkcxbf5nf5z3a";
  };

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/share/icons
    tar xvf $src -C $out/share/icons
  '';
}
