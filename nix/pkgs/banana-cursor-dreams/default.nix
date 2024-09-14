{pkgs}:
pkgs.stdenv.mkDerivation {
  name = "banana-cursor-dreams";
  version = "2.1.0";
  src = builtins.fetchurl {
    url = "https://github.com/elliottminns/banana-cursor/releases/download/v2.1.0/Banana-Catppuccin-Mocha.tar.xz";
    sha256 = "1fimqhw8pxs96wmllmjvf030nnml120gr1xm6pkiajzwd73x17yk";
  };

  unpack = false;

  installPhase = ''
    mkdir -p $out/share/icons
    tar xvf $src -C $out/share/icons
  '';
}
