{
  stdenv,
  fetchurl,
}:
stdenv.mkDerivation rec {
  name = "gptscript";
  version = "0.8.2";
  src = fetchurl {
    url = "https://github.com/gptscript-ai/gptscript/releases/download/v0.8.2/gptscript-v0.8.2-linux-amd64.tar.gz";
    sha256 = "sha256-rz1SagY7lTVpbdK/iIFxI2OhMyQNFTxJGPy3itXy4ek=";
  };

  sourceRoot = ".";
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin
    cp -r gptscript  $out/bin/gptscript
    chmod +x $out/bin/gptscript
  '';
}
