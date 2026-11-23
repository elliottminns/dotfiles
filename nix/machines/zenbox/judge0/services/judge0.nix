{config, lib, pkgs, ...}: let
  cfg = config.services.judge0;
  secretsFile = cfg.secretsFile;
  names = ["judge0-workers"] ++ lib.optional cfg.api.enable "judge0-server" ++ lib.optionals cfg.localStorage ["judge0-db" "judge0-redis"];
  appNames = { judge0-workers = "j0-worker"; judge0-server = "j0-api"; judge0-db = "j0-db"; judge0-redis = "j0-redis"; };
  runtimeName = name: "vs-${appNames.${name}}";
  database = {
    POSTGRES_HOST = cfg.databaseHost;
    POSTGRES_PORT = "5432";
    POSTGRES_DB = "judge0";
    POSTGRES_USER = "judge0";
    REDIS_HOST = cfg.redisHost;
    REDIS_PORT = "6379";
  };
  limits = {
    CPU_TIME_LIMIT = "5";
    CPU_EXTRA_TIME = "1";
    WALL_TIME_LIMIT = "15";
    MEMORY_LIMIT = "256000";
    STACK_LIMIT = "128000";
    MAX_PROCESSES_AND_OR_THREADS = "60";
    MAX_FILE_SIZE = "65536";
    MAX_MAX_FILE_SIZE = "131072";
    NUMBER_OF_RUNS = "1";
  };
  common = {
    log-driver = "json-file";
    extraOptions = ["--log-opt=max-size=10m" "--log-opt=max-file=3"];
  };
  application = common // {
    image = "dreamsofcode/judge0:1.0.1";
    environmentFiles = [config.sops.templates.judge0-database.path];
    extraOptions = common.extraOptions ++ ["--privileged" "--cgroupns=private"];
  };
in {
  options.services.judge0 = {
    api.enable = lib.mkOption { type = lib.types.bool; default = true; };
    localStorage = lib.mkOption { type = lib.types.bool; default = true; };
    databaseHost = lib.mkOption { type = lib.types.str; default = "db"; };
    redisHost = lib.mkOption { type = lib.types.str; default = "redis"; };
    storagePorts = lib.mkOption { type = lib.types.bool; default = false; };
    storageVolumePrefix = lib.mkOption { type = lib.types.str; default = "judge0"; };
    primaryWorkerHost = lib.mkOption { type = lib.types.nullOr lib.types.str; default = null; };
  };
  options.services.judge0.secretsFile = lib.mkOption {
    type = lib.types.path;
    default = ../secrets/judge0.yaml;
    description = "SOPS-encrypted Judge0 credentials for this host.";
  };
  options.services.judge0.enable = lib.mkEnableOption "the Judge0 container stack" // {
    default = builtins.pathExists secretsFile;
  };

  config = lib.mkMerge [
    {
      virtualisation.vmVariant.services.judge0.enable = lib.mkForce false;
    }
    (lib.mkIf cfg.enable {
      sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
      sops.gnupg.sshKeyPaths = [];
      sops.secrets = {
        judge0-db-password = { sopsFile = secretsFile; key = "postgres_password"; };
        judge0-auth-token = { sopsFile = secretsFile; key = "authn_token"; };
        judge0-authz-token = { sopsFile = secretsFile; key = "authz_token"; };
      };
      # Docker env-files use literal, unquoted values. Use single-line secrets.
      sops.templates = {
        judge0-database = {
          mode = "0400";
          content = "POSTGRES_PASSWORD=${config.sops.placeholder.judge0-db-password}\nREDIS_PASSWORD=${config.sops.placeholder.judge0-db-password}\n";
          restartUnits = map (name: "docker-${runtimeName name}.service") names;
        };
        judge0-auth = {
          mode = "0400";
          content = ''
            AUTHN_TOKEN=${config.sops.placeholder.judge0-auth-token}
            AUTHZ_TOKEN=${config.sops.placeholder.judge0-authz-token}
          '';
          restartUnits = lib.optional cfg.api.enable "docker-vs-j0-api.service";
        };
      };

      virtualisation.docker.enable = true;
      services.vps.apps = lib.mapAttrs' (name: container: lib.nameValuePair appNames.${name} {
        enable = true;
        image = container.image;
        network = "judge0";
        port = if name == "judge0-db" then 5432 else if name == "judge0-redis" then 6379 else 2358;
        environmentVariables = container.environment or {};
        secretFile = config.sops.templates.judge0-database.path;
        oci = (builtins.removeAttrs container ["image" "environment" "environmentFiles" "dependsOn"]) // {
          dependsOn = map runtimeName (container.dependsOn or []);
          environmentFiles = lib.optional (name == "judge0-server") config.sops.templates.judge0-auth.path;
        };
      }) ({
          judge0-workers = application // {
            dependsOn = lib.optional cfg.api.enable "judge0-server" ++ lib.optionals cfg.localStorage ["judge0-db" "judge0-redis"];
            extraOptions = application.extraOptions ++ ["--hostname=judge0-worker-${config.networking.hostName}"];
            volumes = ["${./judge0-worker-priority.rb}:/api/config/initializers/judge0_worker_priority.rb:ro"];
            cmd = ["./scripts/workers"];
            environment = database // limits // { COUNT = "2"; INTERVAL = "0.1"; } // lib.optionalAttrs (cfg.primaryWorkerHost != null) { JUDGE0_PRIMARY_WORKER_HOST = cfg.primaryWorkerHost; };
          };
        } // lib.optionalAttrs cfg.localStorage {
          judge0-db = common // {
            image = "postgres:15-alpine";
            environment = { POSTGRES_DB = "judge0"; POSTGRES_USER = "judge0"; };
            environmentFiles = [config.sops.templates.judge0-database.path];
            volumes = ["${cfg.storageVolumePrefix}_postgres_data:/var/lib/postgresql/data"];
            ports = lib.optionals cfg.storagePorts ["127.0.0.1:5432:5432"];
            extraOptions = common.extraOptions ++ ["--network-alias=db"];
          };
          judge0-redis = common // {
            image = "redis:7-alpine";
            environmentFiles = [config.sops.templates.judge0-database.path];
            entrypoint = "/bin/sh";
            cmd = ["-c" ''exec redis-server --appendonly yes --requirepass "$REDIS_PASSWORD"''];
            ports = lib.optionals cfg.storagePorts ["127.0.0.1:6379:6379"];
            volumes = ["${cfg.storageVolumePrefix}_redis_data:/data"];
            extraOptions = common.extraOptions ++ ["--network-alias=redis"];
          };
        } // lib.optionalAttrs cfg.api.enable {
          judge0-server = application // {
            dependsOn = lib.optionals cfg.localStorage ["judge0-db" "judge0-redis"];
            ports = ["127.0.0.1:2358:2358"];

            environment = database // limits // {
              ENABLE_WAIT_RESULT = "true";
              ENABLE_COMPILER_OPTIONS = "true";
              ALLOWED_LANGUAGES_FOR_COMPILE_OPTIONS = "all";
              ENABLE_COMMAND_LINE_ARGUMENTS = "true";
              ENABLE_SUBMISSION_DELETE = "false";
              ENABLE_BATCHED_SUBMISSIONS = "true";
              MAX_QUEUE_SIZE = "100";
              AUTHN_HEADER = "X-Auth-Token";
              AUTHZ_HEADER = "X-Auth-User";
              ENABLE_PER_PROCESS_AND_THREAD_TIME_LIMIT = "false";
              ENABLE_PER_PROCESS_AND_THREAD_MEMORY_LIMIT = "false";
              MAINTENANCE_MODE = "false";
              ENABLE_CALLBACKS = "true";
              CALLBACKS_MAX_TRIES = "3";
              CALLBACKS_TIMEOUT = "5";
            };
          };
        });

      systemd.services = lib.genAttrs (map (name: "docker-${runtimeName name}") names) (_: {
        after = ["sops-install-secrets.service"];
      }) // lib.genAttrs (["docker-vs-j0-worker"] ++ lib.optional cfg.api.enable "docker-vs-j0-api") (_: {
        after = ["sops-install-secrets.service"];
        preStart = lib.mkIf cfg.localStorage (lib.mkBefore ''
          ready=false
          for attempt in $(seq 1 60); do
            if ${pkgs.docker}/bin/docker exec vs-j0-db pg_isready -U judge0 -d judge0 >/dev/null 2>&1 && \
               ${pkgs.docker}/bin/docker exec vs-j0-redis sh -c 'REDISCLI_AUTH="$REDIS_PASSWORD" redis-cli ping' | ${pkgs.gnugrep}/bin/grep -qx PONG; then
              ready=true
              break
            fi
            sleep 2
          done
          if [ "$ready" != true ]; then
            echo "Judge0 database or Redis did not become ready" >&2
            exit 1
          fi
        '');
      });
    })
  ];
}
