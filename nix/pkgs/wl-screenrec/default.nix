{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  libdrm,
  ffmpeg,
  wayland,
}:
rustPlatform.buildRustPackage rec {
  pname = "wl-screenrec";
  version = "0.1.5-unstable-2024-11-05";

  src = fetchFromGitHub {
    owner = "russelltg";
    repo = pname;
    rev = "708ec89a0b564751fe089892b10fbe55726123cf";
    hash = "sha256-KKZj7I+7ipTR+A0Hs81MeShK4KLTTtf9JwChe0pEni8=";
  };

  cargoHash = "sha256-NA/xvgm8/ShpFXqbUp3OHZo3R3LG81ZtTR7FdnwZJ8M=";

  nativeBuildInputs = [
    pkg-config
    rustPlatform.bindgenHook
  ];

  buildInputs = [
    wayland
    libdrm
    ffmpeg
  ];

  doCheck = false; # tests use host compositor, etc

  meta = with lib; {
    description = "High performance wlroots screen recording, featuring hardware encoding";
    homepage = "https://github.com/russelltg/wl-screenrec";
    license = licenses.asl20;
    platforms = platforms.linux;
    mainProgram = "wl-screenrec";
    maintainers = with maintainers; [colemickens];
  };
}
