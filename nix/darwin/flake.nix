{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    codex-cli-nix.url = "github:sadjow/codex-cli-nix";

    # Home Manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, ... }:
  let
    # Username
    username = "elliott";
    configuration = { pkgs, ... }: {
      disabledModules = [ "services/karabiner-elements" ];
      imports = [ ./modules/services/karabiner-elements.nix ];

      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [
	  pkgs.neovim
          pkgs.git
          pkgs.gh
          pkgs.ghostty-bin
          pkgs.gnupg
          pkgs.pass
          pkgs.rustup
          pkgs.tmux
          pkgs.zoxide
          inputs.codex-cli-nix.packages.${pkgs.system}.default
        ];

      services.karabiner-elements.enable = true;

      # User directory
      users.users.elliott = {
        name = username;
        home = "/Users/elliott";
      };

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;
      system.primaryUser = username;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#amaterasu
    darwinConfigurations."amaterasu" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
	home-manager.darwinModules.home-manager
        {
          # `home-manager` config
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.elliott = import ./home.nix;
        }
      ];
    };
  };
}
