{
  lib,
  buildGoModule,
  fetchFromGitHub,
  zlib,
}:
buildGoModule rec {
  pname = "soci-snapshotter";
  version = "0.13.0";

  src = fetchFromGitHub {
    owner = "awslabs";
    repo = "soci-snapshotter";
    rev = "v${version}";
    hash = "sha256-aLjZ6ItMuQY+NVmEv1uIT5ixGp9PlUFygTvj9lL7KS0=";
  };

  modRoot = "cmd";

  vendorHash = "sha256-wPQNp0UV03BWeU0ozZ8fEJeCWShKNMziO9PrK5AYZP0=";

  buildInputs = [zlib];

  # Patch CGO directives before buildGoModule generates its vendor tree.
  # Upstream hard-codes a relative path to its bundled static zlib.
  postPatch = ''
    substituteInPlace ztoc/compression/gzip_zinfo.go \
      --replace-fail '-L''${SRCDIR}/../out -l:libz.a' '-lz'
  '';

  subPackages = ["soci"];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/awslabs/soci-snapshotter/version.Version=v${version}"
  ];

  meta = with lib; {
    description = "AWS SOCI Snapshotter CLI for creating seekable OCI indexes";
    homepage = "https://github.com/awslabs/soci-snapshotter";
    license = licenses.asl20;
    platforms = platforms.linux;
  };
}
