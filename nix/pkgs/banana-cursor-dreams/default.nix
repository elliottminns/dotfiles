{pkgs}:
pkgs.stdenv.mkDerivation {
  name = "banana-cursor-dreams";
  version = "2.1.0";
  src = builtins.fetchurl {
    url = "https://github.com/dreamsofautonomy/banana-cursor/releases/download/v2.1.0/banana-all.tar.xz";
    sha256 = "1jyskd1qxa1zzr7bl6hgrxpja0ri7pw0baqdg24mrbw1x8ly7n6i";
  };

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/share/icons
    tar xvf $src -C $out/share/icons
  '';
}
