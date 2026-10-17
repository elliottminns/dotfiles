{config, lib, pkgs, ...}: {
  config = lib.mkIf (config.services.judge0.enable && config.services.judge0.api.enable) {
    # Keep Docker bound to loopback. Only Tailscale exposes the API remotely.
    systemd.services.judge0-storage-tailnet = lib.mkIf config.services.judge0.storagePorts {
      description = "Expose shared Judge0 storage over Tailscale";
      wants = ["tailscaled.service" "docker-judge0-db.service" "docker-judge0-redis.service"];
      after = ["tailscaled.service" "docker-judge0-db.service" "docker-judge0-redis.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = { Type = "oneshot"; RemainAfterExit = true; Restart = "on-failure"; RestartSec = "5s"; };
      script = ''
        ${pkgs.tailscale}/bin/tailscale serve --bg --yes --tcp=5432 tcp://127.0.0.1:5432
        ${pkgs.tailscale}/bin/tailscale serve --bg --yes --tcp=6379 tcp://127.0.0.1:6379
      '';
      preStop = ''
        ${pkgs.tailscale}/bin/tailscale serve --tcp=5432 off
        ${pkgs.tailscale}/bin/tailscale serve --tcp=6379 off
      '';
    };
    systemd.services.judge0-tailnet = {
      description = "Expose Judge0 to the VPS over Tailscale";
      wants = ["tailscaled.service" "docker-judge0-server.service"];
      after = ["tailscaled.service" "docker-judge0-server.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.tailscale}/bin/tailscale serve --bg --yes --tcp=2358 tcp://127.0.0.1:2358";
        ExecStop = "${pkgs.tailscale}/bin/tailscale serve --tcp=2358 off";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}
