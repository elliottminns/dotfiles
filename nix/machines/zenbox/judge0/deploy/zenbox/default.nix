# Copy deploy/zenbox, services/judge0*.nix, services/judge0-worker-priority.rb,
# and secrets/judge0.yaml together.
{lib, ...}: let
  sopsSource = builtins.fetchTree {
    type = "github";
    owner = "Mic92";
    repo = "sops-nix";
    rev = "ee48786c6f9160d2c1a084aac841f68195b8420c";
    narHash = "sha256-mVD4XIc5JkqMW2K04IkFUzHgHmyJZlzw5ktfgMDCbKU=";
  };
in {
  imports = [
    (sopsSource + "/modules/sops")
    ../../modules/container-services.nix
    ../../services/judge0.nix
    ../../services/judge0-tailnet.nix
  ];
  # Override the shared workstation configuration so container isolation is active.
  networking.firewall.enable = lib.mkForce true;

  services.judge0 = {
    enable = true;
    api.enable = false;
    localStorage = false;
    databaseHost = "100.101.64.60";
    redisHost = "100.101.64.60";
    secretsFile = ../../secrets/judge0.yaml;
  };
}
