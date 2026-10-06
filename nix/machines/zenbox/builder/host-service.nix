{
  pkgs,
  vm,
}:
pkgs.writeText "zenbox-builder.service" ''
  [Unit]
  Description=Isolated Nix builder VM
  Wants=network-online.target
  After=network-online.target

  [Service]
  Type=simple
  ExecStart=${pkgs.lib.getExe vm}
  DynamicUser=yes
  User=zenbox-builder
  SupplementaryGroups=kvm
  StateDirectory=zenbox-builder
  StateDirectoryMode=0700
  RuntimeDirectory=zenbox-builder
  RuntimeDirectoryMode=0700
  WorkingDirectory=/var/lib/zenbox-builder
  Restart=on-failure
  RestartSec=10
  TimeoutStopSec=120
  UMask=0077
  PrivateTmp=yes
  ProtectSystem=strict
  ProtectHome=yes
  NoNewPrivileges=yes
  ProtectKernelTunables=yes
  ProtectKernelModules=yes
  ProtectControlGroups=yes
  RestrictSUIDSGID=yes
  RestrictRealtime=yes
  LockPersonality=yes
  CapabilityBoundingSet=
  DevicePolicy=closed
  DeviceAllow=/dev/kvm rw
  RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6 AF_NETLINK
  MemoryMax=20G
  TasksMax=512
  CPUQuota=800%
  Nice=10
  # QEMU's user networking runs in this cgroup. Block host loopback, LAN,
  # link-local and all direct tailnet access through the host.
  # Tailnet ACLs MUST also restrict the guest's own Tailscale identity:
  # these host rules cannot inspect traffic inside its encrypted tunnel.
  IPAddressDeny=127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 169.254.0.0/16 100.64.0.0/10 ::1/128 fc00::/7 fe80::/10

  [Install]
  WantedBy=multi-user.target
''
