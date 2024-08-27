{
  description = "Example Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.05-darwin";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    templ.url = "github:a-h/templ";
    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  outputs = { self, nix-darwin, nixpkgs, nixpkgs-unstable, templ, home-manager, ... }@inputs:
  let
    add-unstable-packages = final: _prev: {
      unstable = import inputs.nixpkgs-unstable {
        system = "aarch64-darwin";
      };
    };
    configuration = { pkgs, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      nixpkgs.config.allowUnfree = true;
      nixpkgs.overlays = [
        inputs.templ.overlays.default
        add-unstable-packages
      ];
      environment.systemPackages =
        [
          pkgs.awscli
          pkgs.neovim
          pkgs.ffmpeg
          pkgs.ripgrep
          pkgs.rclone
          pkgs.unstable.amber-lang
          pkgs.rustup
          pkgs.obsidian
          pkgs.tailwindcss
          pkgs.tailwindcss-language-server
          pkgs.pass
          pkgs.lua-language-server
          pkgs.stylua
          pkgs.zoxide
          pkgs.iperf
          pkgs.air
          pkgs.templ
          pkgs.bun
          pkgs.opentofu
          pkgs.gh
          pkgs.nil
        ];

      users.users.elliott = {
        name = "elliott";
        home = "/Users/elliott";
      };

      homebrew = {
        enable = true;
        brews = [
          "stripe"
        ];
        casks = [
          "alacritty"
          "hammerspoon"
          "amethyst"
          "alfred"
          "logseq"
          "notion"
          "discord"
          "iina"
        ];
        taps = [
          "stripe/stripe-cli"
        ];
      };


      # Auto upgrade nix package and the daemon service.
      services.nix-daemon.enable = true;
      # nix.package = pkgs.nix;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Create /etc/zshrc that loads the nix-darwin environment.
      programs.zsh.enable = true;  # default shell on catalina

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 4;

      system.defaults = {
        NSGlobalDomain.AppleICUForce24HourTime = true;
        NSGlobalDomain.AppleShowAllExtensions = true;
        loginwindow.GuestEnabled = false;
      };

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."tsukuyomi" = nix-darwin.lib.darwinSystem {
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

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."tsukuyomi".pkgs;
  };
}
