{
  lib,
  pkgs,
  meta,
  ...
}: let
  isZenbox = meta.hostname == "zenbox";
  k3s_1_30_1 = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "k3s";
    version = "1.30.1+k3s1";

    src = pkgs.fetchurl {
      url = "https://github.com/k3s-io/k3s/releases/download/v1.30.1%2Bk3s1/k3s";
      hash = "sha256-OaUFf7Sb9XakXDLvPvY7/0SCUtTSXGxBuNzF5I4ni/U=";
    };

    nativeBuildInputs = [pkgs.makeWrapper];

    runtimeDeps = with pkgs; [
      kmod
      socat
      iptables
      nftables
      iproute2
      ipset
      bridge-utils
      ethtool
      util-linuxMinimal
      conntrack-tools
      runc
      bash
      shadow
    ];

    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      install -Dm755 $src $out/bin/k3s
      wrapProgram $out/bin/k3s \
        --prefix PATH : ${lib.makeBinPath runtimeDeps} \
        --prefix PATH : "$out/bin"
      ln -s k3s $out/bin/kubectl
      ln -s k3s $out/bin/crictl
      ln -s k3s $out/bin/ctr

      runHook postInstall
    '';

    meta =
      pkgs.k3s.meta
      // {
        sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      };
  };
in {
  config = lib.mkIf isZenbox {
    services.k3s = {
      enable = true;
      package = k3s_1_30_1;
      role = "agent";
      serverAddr = "https://homelab-0:6443";
      tokenFile = "/etc/rancher/k3s/cluster-token";
      extraFlags = [
        "--node-label workload=kiru-cicd"
        "--node-label kiru.run/workload=cicd"
        "--node-taint kiru.run/workload=cicd:NoSchedule"
      ];
    };

    services.openiscsi = {
      enable = true;
      name = "iqn.2016-04.com.open-iscsi:${meta.hostname}";
    };

    environment.systemPackages = with pkgs; [
      k3s_1_30_1
      cifs-utils
      nfs-utils
    ];
  };
}
