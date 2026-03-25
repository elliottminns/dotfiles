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

  outputs = inputs @ {
    self,
    nix-darwin,
    nixpkgs,
    home-manager,
    ...
  }: let
    # Username
    username = "elliott";
    configuration = {pkgs, ...}: let
      gsed = pkgs.writeShellScriptBin "gsed" ''
        exec ${pkgs.gnused}/bin/sed "$@"
      '';
    in {
      disabledModules = ["services/karabiner-elements"];
      imports = [
        ./modules/services/karabiner-elements.nix
        ./extra/services/kanata.nix
      ];

      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages = [
        pkgs.neovim
        pkgs.alejandra
        pkgs.awscli2
        pkgs.bat
        pkgs.betterdisplay
        pkgs.bun
        pkgs.cargo-bundle
        pkgs.cargo-leptos
        pkgs.claude-code-bin
        pkgs.dioxus-cli
        pkgs.doppler
        pkgs.ffmpeg
        pkgs.git
        pkgs.gh
        pkgs.ghostty-bin
        pkgs.cairo
        pkgs.gdk-pixbuf
        pkgs.glib
        pkgs.go
        pkgs.gnupg
        pkgs.gnused
        gsed
        pkgs.gst_all_1.gstreamer
        pkgs.gst_all_1.gst-plugins-bad
        pkgs.gst_all_1.gst-plugins-base
        pkgs.gst_all_1.gst-plugins-good
        pkgs.harfbuzz
        pkgs.gtk3
        pkgs.just
        pkgs.macdylibbundler
        pkgs.mediainfo
        pkgs.opentofu
        pkgs.openssl
        pkgs.postgresql
        pkgs.python3Packages.mlx-lm
        pkgs.ollama
        pkgs.exiftool
        pkgs.pango
        pkgs.pass
        pkgs.pkg-config
        pkgs.pwgen
        pkgs.protonmail-bridge
        pkgs.ripgrep
        pkgs.rust-analyzer
        pkgs.rustup
        pkgs.slack
        pkgs.tailwindcss
        pkgs.tmux
        pkgs.trunk
        pkgs.uv
        pkgs.wasm-pack
        pkgs.zellij
        pkgs.zoxide
        inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];

      services.kanata.enable = true;
      services.kanata.package = pkgs.kanata;
      services.kanata.keyboards.internal = {
        extraDefCfg = ''
          process-unmapped-keys yes
        '';
        config = ''
          (defsrc
            f1   f2   f3   f4   f5   f6   f7   f8   f9   f10   f11   f12
            caps a s d f j k l ;
          )

          (defvar
            tap-time 150
            hold-time 200
          )

          (defalias
            escctrl (tap-hold 100 100 esc lctl)
            a (tap-hold $tap-time $hold-time a lmet)
            s (tap-hold $tap-time $hold-time s lalt)
            d (tap-hold $tap-time $hold-time d lsft)
            f (tap-hold $tap-time $hold-time f lctl)
            j (tap-hold $tap-time $hold-time j rctl)
            k (tap-hold $tap-time $hold-time k rsft)
            l (tap-hold $tap-time $hold-time l ralt)
            ; (tap-hold $tap-time $hold-time ; rmet)
          )

          (deflayer base
            brdn  brup  _    _    _    _   prev  pp  next  mute  vold  volu
            @escctrl @a @s @d @f @j @k @l @;
          )

          (deflayer fn
            f1   f2   f3   f4   f5   f6   f7   f8   f9   f10   f11   f12
            @escctrl _ _ _ _ _ _ _ _
          )
        '';
      };

      services.openssh.enable = true;

      networking.hostName = "amaterasu";
      networking.localHostName = "amaterasu";
      networking.computerName = "amaterasu";

      # User directory
      users.users.elliott = {
        name = username;
        home = "/Users/elliott";
        shell = pkgs.zsh;
      };

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";
      nixpkgs.config.allowUnfreePredicate = pkg:
        builtins.elem (pkgs.lib.getName pkg) [
          "betterdisplay"
          "claude-code-bin"
          "slack"
        ];
      homebrew = {
        enable = true;
        onActivation = {
          autoUpdate = false;
          upgrade = false;
          cleanup = "uninstall";
        };
        brews = [];
        casks = [
          "adobe-creative-cloud"
          "aldente"
          "discord"
          "docker-desktop"
          "elgato-camera-hub"
          "font-inter"
          "google-drive"
          "istat-menus"
          "obs"
          "logi-options+"
          "elgato-stream-deck"
          "notion"
          "sizeup"
          "vlc"
          "figma"
          "google-chrome"
        ];
        masApps = {
          Xcode = 497799835;
        };
      };

      # Create /etc/zshrc and make zsh available as the managed login shell.
      programs.zsh.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;
      system.primaryUser = username;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in {
    formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.alejandra;

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
