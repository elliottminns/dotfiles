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

  vendorHash = "sha256-yacNFTSy2vzVH/uakN9zoxgbvAD4oAYQvuETHXXwurg=";

  buildInputs = [zlib];

  # Patch CGO directives to use Nix zlib instead of hardcoded relative path.
  # The vendored Go source has: #cgo LDFLAGS: -L${SRCDIR}/../out -l:libz.a
  # Must use preBuild because buildGoModule recreates vendor/ after patchPhase.
  preBuild = ''
    substituteInPlace vendor/github.com/awslabs/soci-snapshotter/ztoc/compression/gzip_zinfo.go \
      --replace-fail '-L''${SRCDIR}/../out -l:libz.a' '-L${zlib.static}/lib -lz'
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
