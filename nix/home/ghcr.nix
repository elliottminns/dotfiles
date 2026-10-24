{config, lib, pkgs, ...}: let
  ghcrCredentialHelper = pkgs.writeScriptBin "docker-credential-sops-ghcr" ''
    #!${pkgs.python3}/bin/python3
    import json
    import subprocess
    import sys

    if len(sys.argv) == 2 and sys.argv[1] == "get":
        registry = sys.stdin.read().strip().rstrip("/")
        if registry not in ("ghcr.io", "https://ghcr.io"):
            sys.exit("credential not found in native keychain")
        try:
            decrypted = subprocess.run(
                ["${pkgs.sops}/bin/sops", "--decrypt", "--output-type", "json", "${config.home.homeDirectory}/.dotfiles/nix/secrets/ghcr.yaml"],
                check=True, stdout=subprocess.PIPE, text=True,
            )
            secret = json.loads(decrypted.stdout)
            print(json.dumps({"Username": secret["ghcr_username"], "Secret": secret["ghcr_token"]}))
        except (OSError, subprocess.CalledProcessError, ValueError, KeyError):
            sys.exit("Unable to decrypt the GHCR SOPS secret")
    elif len(sys.argv) == 2 and sys.argv[1] == "list":
        print("{}")
    else:
        sys.exit("GHCR credentials are managed by SOPS; edit secrets/ghcr.yaml instead")
  '';
in {
  home.packages = [ghcrCredentialHelper];
  home.file.".docker/config.json".text = builtins.toJSON {
    credsStore = if pkgs.stdenv.isDarwin then "desktop" else "secretservice";
    credHelpers."ghcr.io" = "sops-ghcr";
  };
}
