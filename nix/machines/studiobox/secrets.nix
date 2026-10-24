{config, ...}: let
  # Match the existing zenbox deployment pin without updating unrelated inputs.
  sopsSource = builtins.fetchTree {
    type = "github";
    owner = "Mic92";
    repo = "sops-nix";
    rev = "ee48786c6f9160d2c1a084aac841f68195b8420c";
    narHash = "sha256-mVD4XIc5JkqMW2K04IkFUzHgHmyJZlzw5ktfgMDCbKU=";
  };
in {
  imports = [(sopsSource + "/modules/sops")];

  sops = {
    # Provision this encrypted file during installation (see README.md).
    # A runtime path lets the repo copy use only Elliott's YubiKey recipient;
    # the deployed copy is additionally encrypted to the machine's host key.
    defaultSopsFile = "/var/lib/sops/shared.yaml";
    validateSopsFiles = false;
    useSystemdActivation = true;
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    gnupg.sshKeyPaths = [];
    secrets.tailscale-auth-key = {
      key = "tailscale_auth_key";
      mode = "0400";
    };
  };

  services.tailscale.authKeyFile = config.sops.secrets.tailscale-auth-key.path;
  systemd.services.sops-install-secrets.unitConfig.RequiresMountsFor = ["/var/lib/sops"];
  systemd.services.tailscaled-autoconnect = {
    requires = ["sops-install-secrets.service"];
    after = ["sops-install-secrets.service"];
  };
}
