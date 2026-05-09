{
  lib,
  pkgs,
  meta,
  ...
}: let
  isZenbox = meta.hostname == "zenbox";
in {
  config = lib.mkIf isZenbox {
    services.k3s = {
      enable = true;
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
      k3s
      cifs-utils
      nfs-utils
    ];
  };
}
