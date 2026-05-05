{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "soci-snapshotter";
  version = "0.13.0";

  src = fetchFromGitHub {
    owner = "awslabs";
    repo = "soci-snapshotter";
    rev = "v${version}";
    hash = lib.fakeHash;
  };

  modRoot = "cmd";

  vendorHash = lib.fakeHash;

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
