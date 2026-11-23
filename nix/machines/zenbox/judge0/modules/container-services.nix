# Package-backed services in declarative NixOS (systemd-nspawn) containers.
{ config, lib, pkgs, ... }:
let
  inherit (lib) mkOption mkEnableOption types mkIf mapAttrs mapAttrsToList;
  cfg = config.services.vps;
  apps = lib.filterAttrs (_: app: app.enable) cfg.apps;
  packageApps = lib.filterAttrs (_: app: app.image == null) apps;
  imageApps = lib.filterAttrs (_: app: app.image != null) apps;
  imageNetworks = lib.unique (mapAttrsToList networkName imageApps);
  packageNetworks = lib.filterAttrs (name: _: !(builtins.elem name imageNetworks)) networks;
  # Stable allocation independent of attribute ordering; collisions fail evaluation.
  number = text: modulus: offset:
    offset + lib.mod (lib.foldl' (n: c: n * 16 + (lib.strings.charToInt c - (if builtins.match "[0-9]" c != null then 48 else 87))) 0
      (lib.stringToCharacters (builtins.substring 0 6 (builtins.hashString "sha256" text)))) modulus;
  networkName = name: app: if app.network == null then "private-${name}" else "shared-${app.network}";
  names = lib.unique (mapAttrsToList networkName apps);
  networks = lib.genAttrs names (name: {
    id = number name 250 1;
    bridge = "vs${builtins.substring 0 10 (builtins.hashString "sha256" name)}";
  });
  net = name: app: networks.${networkName name app};
  address = name: app: "10.231.${toString (net name app).id}.${toString app.addressId}";
  target = name: app: "http://${address name app}:${toString app.port}";
  unit = name: if apps.${name}.image == null then "container@vs-${name}.service" else "docker-vs-${name}.service";
  unique = xs: builtins.length xs == builtins.length (lib.unique xs);
  internalApps = lib.filterAttrs (_: app: app.internal.enable) apps;
  externalApps = lib.filterAttrs (_: app: app.external.enable) apps;
  bridgePairs = lib.concatMap (a: map (b: { from = a.bridge; to = b.bridge; })
    (lib.filter (b: a.bridge != b.bridge) (lib.attrValues networks))) (lib.attrValues networks);
  resourceOptions = {
    memoryMax = mkOption { type = types.nullOr types.str; default = null; description = "Container-wide systemd MemoryMax, e.g. 512M."; };
    cpuQuota = mkOption { type = types.nullOr types.str; default = null; description = "Container-wide CPUQuota; 100% is one CPU."; };
    tasksMax = mkOption { type = types.nullOr types.ints.positive; default = null; };
  };
in {
  options.services.vps.apps = mkOption {
    default = {};
    description = "Package-backed services; each enabled entry creates a NixOS container.";
    type = types.attrsOf (types.submodule ({ name, ... }: {
      options = {
        enable = mkEnableOption "the ${name} container service";
        package = mkOption { type = types.nullOr types.package; default = null; description = "Package from nixpkgs or a flake input; choose exactly one of package or image."; };
        image = mkOption { type = types.nullOr types.str; default = null; description = "OCI image run by Docker; choose exactly one of package or image."; };
        oci = mkOption { type = types.attrsOf types.anything; default = {}; description = "Additional NixOS OCI container options, e.g. volumes, login, cmd and dependsOn. Networking and environment are managed by this module."; };
        executable = mkOption { type = types.str; default = if config.services.vps.apps.${name}.package == null then "" else lib.getExe config.services.vps.apps.${name}.package; description = "Absolute executable path (defaults to lib.getExe package)."; };
        arguments = mkOption { type = types.listOf types.str; default = []; };
        environmentVariables = mkOption { type = types.attrsOf types.str; default = {}; };
        secretFile = mkOption { type = types.nullOr types.str; default = null; description = "Runtime sops secret/template path containing systemd EnvironmentFile entries. Never use a Nix path literal for plaintext."; };
        port = mkOption { type = types.port; default = 3000; description = "Application port; bind the application to 0.0.0.0."; };
        network = mkOption { type = types.nullOr types.str; default = null; description = "Same non-null name shares an L2 bridge; null gives this app its own bridge."; };
        addressId = mkOption { type = types.ints.between 2 254; default = number name 253 2; description = "Stable host octet; override if a shared network reports a collision."; };
        address = mkOption { type = types.str; readOnly = true; default = address name config.services.vps.apps.${name}; };
        allowedTCPPorts = mkOption { type = types.listOf types.port; default = []; description = "Additional ports reachable by host and network peers."; };
        allowedUDPPorts = mkOption { type = types.listOf types.port; default = []; };
        resources = resourceOptions;
        internal = {
          enable = mkEnableOption "tailnet HTTPS exposure via Tailscale Services";
          domain = mkOption { type = types.str; default = ""; description = "Service FQDN, e.g. api.example-tailnet.ts.net; first label is the Tailscale Service name."; };
          proxyPort = mkOption { type = types.port; default = number name 40000 20000; description = "Host loopback port for Tailscale Serve's local backend."; };
        };
        external = {
          enable = mkEnableOption "public HTTP exposure via Cloudflare Tunnel";
          domain = mkOption { type = types.str; default = ""; };
          tunnel = mkOption { type = types.str; default = "790bd581-6375-4422-bbd6-b7f64bbde3dc"; description = "Existing services.cloudflared.tunnels key."; };
        };
        extraConfig = mkOption { type = types.deferredModule; default = {}; description = "Additional NixOS module inside the container."; };
      };
    }));
  };

  config = mkIf (apps != {}) (lib.mkMerge [
    {
      assertions = [
        { assertion = config.networking.firewall.enable; message = "VPS container services require the host firewall for network isolation."; }
        { assertion = unique (map (n: n.id) (lib.attrValues networks)); message = "VPS network subnet collision: rename one network/service."; }
        { assertion = unique (mapAttrsToList address apps); message = "VPS container IP collision: set a distinct addressId within the shared network."; }
        { assertion = unique (mapAttrsToList (_: a: a.internal.proxyPort) internalApps); message = "VPS internal proxy port collision: set internal.proxyPort."; }
        { assertion = unique (mapAttrsToList (_: a: a.internal.domain) internalApps); message = "VPS internal domains must be unique."; }
        { assertion = unique (mapAttrsToList (_: a: a.external.domain) externalApps); message = "VPS external domains must be unique."; }
        { assertion = lib.all (name: !(builtins.elem name imageNetworks)) (lib.unique (mapAttrsToList networkName packageApps)); message = "VPS shared networks cannot mix package and OCI apps."; }
      ] ++ lib.flatten (mapAttrsToList (name: app: [
        { assertion = (app.package != null) != (app.image != null); message = "VPS ${name}: choose exactly one of package or image."; }
        { assertion = app.image == null || lib.all (key: !(builtins.hasAttr key app.oci)) ["image" "environment"]; message = "VPS ${name}: configure image, environmentVariables, secretFile through the app interface."; }
        { assertion = builtins.match "[a-z][a-z0-9-]{0,8}" name != null; message = "VPS service names must start with a letter and contain at most 9 lowercase letters, digits or hyphens (container interface limit)."; }
        { assertion = !app.internal.enable || (config.services.tailscale.enable && builtins.match "[a-z0-9-]+\\.[a-z0-9.-]+\\.ts\\.net" app.internal.domain != null); message = "VPS ${name}: internal.domain must be a Tailscale Service FQDN and Tailscale must be enabled."; }
        { assertion = !app.external.enable || (app.external.domain != "" && config.services.cloudflared.enable && builtins.hasAttr app.external.tunnel config.services.cloudflared.tunnels); message = "VPS ${name}: external exposure needs a domain and an enabled, configured Cloudflare tunnel."; }
        { assertion = app.secretFile == null || lib.hasPrefix "/run/" app.secretFile; message = "VPS ${name}: secretFile must be a runtime /run path from sops."; }
      ]) apps);
      networking.bridges = lib.listToAttrs (map (n: lib.nameValuePair n.bridge { interfaces = []; }) (lib.attrValues packageNetworks));
      networking.interfaces = lib.listToAttrs (map (n: lib.nameValuePair n.bridge {
        ipv4.addresses = [{ address = "10.231.${toString n.id}.1"; prefixLength = 24; }];
      }) (lib.attrValues packageNetworks));
      networking.firewall = if config.networking.nftables.enable then {
        filterForward = true;
        extraForwardRules = lib.mkBefore (lib.concatMapStringsSep "\n" (p:
          ''iifname "${p.from}" oifname "${p.to}" drop'') bridgePairs);
      } else {
        extraCommands = lib.concatMapStringsSep "\n" (p:
          "iptables -w -I FORWARD 1 -i ${p.from} -o ${p.to} -j DROP") bridgePairs;
        extraStopCommands = lib.concatMapStringsSep "\n" (p:
          "iptables -w -D FORWARD -i ${p.from} -o ${p.to} -j DROP 2>/dev/null || true") bridgePairs;
      };
      networking.nat = {
        enable = true;
        internalInterfaces = map (n: n.bridge) (lib.attrValues networks);
      };
      containers = lib.mapAttrs' (name: app: lib.nameValuePair "vs-${name}" {
        autoStart = true;
        privateNetwork = true;
        hostBridge = (net name app).bridge;
        localAddress = "${address name app}/24";
        bindMounts = lib.optionalAttrs (app.secretFile != null) {
          "/run/vps-environment" = { hostPath = app.secretFile; isReadOnly = true; };
        };
        config = { utils, ... }: {
          imports = [app.extraConfig];
          system.stateVersion = config.system.stateVersion;
          networking = {
            useDHCP = false;
            defaultGateway = "10.231.${toString (net name app).id}.1";
            nameservers = ["1.1.1.1" "9.9.9.9"];
            firewall.allowedTCPPorts = [app.port] ++ app.allowedTCPPorts;
            firewall.allowedUDPPorts = app.allowedUDPPorts;
            hosts = lib.mapAttrs' (peer: other: lib.nameValuePair (address peer other) [peer])
              (lib.filterAttrs (peer: other: networkName peer other == networkName name app) apps);
          };
          users.groups.app = {};
          users.users.app = { isSystemUser = true; group = "app"; };
          systemd.services.app = {
            wantedBy = ["multi-user.target"];
            after = ["network-online.target"];
            wants = ["network-online.target"];
            environment = app.environmentVariables;
            serviceConfig = {
              ExecStart = utils.escapeSystemdExecArgs ([app.executable] ++ app.arguments);
              User = "app";
              Group = "app";
              StateDirectory = "app";
              WorkingDirectory = "/var/lib/app";
              Restart = "on-failure";
              RestartSec = "5s";
              NoNewPrivileges = true;
              PrivateTmp = true;
              ProtectSystem = "strict";
              ProtectHome = true;
              CapabilityBoundingSet = "";
              RestrictSUIDSGID = true;
              UMask = "0077";
            } // lib.optionalAttrs (app.secretFile != null) { EnvironmentFile = "/run/vps-environment"; };
          };
        };
      }) packageApps;
      systemd.services = lib.mapAttrs' (name: app: lib.nameValuePair "container@vs-${name}" {
        wants = ["network-online.target"];
        requires = lib.optional (app.secretFile != null) "sops-install-secrets.service";
        after = ["network-online.target"] ++ lib.optional (app.secretFile != null) "sops-install-secrets.service";
        serviceConfig = lib.filterAttrs (_: v: v != null) {
          MemoryMax = app.resources.memoryMax;
          CPUQuota = app.resources.cpuQuota;
          TasksMax = app.resources.tasksMax;
        };
      }) packageApps;
    }
    # OCI apps retain their image and persistent Docker volumes.
    (lib.mkIf (imageApps != {}) {
      virtualisation.docker.enable = true;
      virtualisation.oci-containers = {
        backend = "docker";
        containers = lib.mapAttrs' (name: app: lib.nameValuePair "vs-${name}" (app.oci // {
          image = app.image;
          cmd = app.oci.cmd or app.arguments;
          environment = app.environmentVariables;
          environmentFiles = lib.optional (app.secretFile != null) app.secretFile ++ (app.oci.environmentFiles or []);
          extraOptions = ["--network=vs-${networkName name app}" "--ip=${app.address}"]
            ++ (app.oci.extraOptions or [])
            ++ lib.optional (app.resources.memoryMax != null) "--memory=${app.resources.memoryMax}"
            ++ lib.optional (app.resources.cpuQuota != null) "--cpus=${toString ((builtins.fromJSON (lib.removeSuffix "%" app.resources.cpuQuota)) / 100.0)}"
            ++ lib.optional (app.resources.tasksMax != null) "--pids-limit=${toString app.resources.tasksMax}";
        })) imageApps;
      };
      systemd.services = lib.mkMerge [
        (lib.genAttrs (map (name: "vps-network-${name}") imageNetworks) (unitName: let
          name = lib.removePrefix "vps-network-" unitName;
          n = networks.${name};
        in {
          requires = ["docker.service"];
          after = ["docker.service"];
          serviceConfig = { Type = "oneshot"; RemainAfterExit = true; };
          script = ''
            ${pkgs.docker}/bin/docker network inspect vs-${name} >/dev/null 2>&1 || \
              ${pkgs.docker}/bin/docker network create --subnet 10.231.${toString n.id}.0/24 \
                --gateway 10.231.${toString n.id}.1 --opt com.docker.network.bridge.name=${n.bridge} vs-${name}
          '';
        }))
        (lib.mapAttrs' (name: app: lib.nameValuePair "docker-vs-${name}" {
          requires = ["vps-network-${networkName name app}.service"] ++ lib.optional (app.secretFile != null) "sops-install-secrets.service";
          after = ["vps-network-${networkName name app}.service"] ++ lib.optional (app.secretFile != null) "sops-install-secrets.service";
        }) imageApps)
      ];
    })
    # Isolated bridges are not trusted host interfaces: peers reach only explicitly
    # opened container ports. No inbound host port or public firewall rule is added.
    {
      systemd.sockets = lib.mapAttrs' (name: app: lib.nameValuePair "vps-proxy-${name}" {
        wantedBy = ["sockets.target"];
        listenStreams = ["127.0.0.1:${toString app.internal.proxyPort}"];
      }) internalApps;
      systemd.services = lib.mkMerge (mapAttrsToList (name: app: {
        "vps-proxy-${name}" = {
          requires = [(unit name)];
          after = [(unit name)];
          serviceConfig = {
            ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd ${address name app}:${toString app.port}";
            DynamicUser = true;
            PrivateTmp = true;
            NoNewPrivileges = true;
          };
        };
        "vps-serve-${name}" = let
          serviceName = builtins.head (lib.splitString "." app.internal.domain);
          serve = "${pkgs.tailscale}/bin/tailscale serve --service=svc:${serviceName} --https=443";
        in {
          wantedBy = ["multi-user.target"];
          wants = ["tailscaled.service" "vps-proxy-${name}.socket"];
          after = ["tailscaled.service" "vps-proxy-${name}.socket"];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${serve} --bg --yes http://127.0.0.1:${toString app.internal.proxyPort}";
            ExecStop = "${serve} off";
            Restart = "on-failure";
            RestartSec = "5s";
          };
        };
      }) internalApps);
    }
    { services.cloudflared.tunnels = lib.mkMerge (mapAttrsToList (name: app: {
      ${app.external.tunnel}.ingress.${app.external.domain} = target name app;
    }) externalApps); }
  ]);
}
