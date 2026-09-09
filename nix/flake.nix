{
  description = "Top level NixOS Flake";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:NixOs/nixos-hardware/master";

    # Unstable Packages
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Disko
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # Home Manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Alacritty theme
    alacritty-theme.url = "github:alexghr/alacritty-theme.nix";
    alacritty-theme.inputs.nixpkgs.follows = "nixpkgs";

    # Templ
    templ.url = "github:a-h/templ";
    templ.inputs.nixpkgs.follows = "nixpkgs";

    # Ags
    ags.url = "github:Aylur/ags";
    ags.inputs.nixpkgs.follows = "nixpkgs";

    # Matugen
    matugen.url = "github:InioX/matugen?ref=v2.2.0";
    matugen.inputs.nixpkgs.follows = "nixpkgs";

    # NixVim
    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";

    # Zen browser
    zen-browser.url = "github:0xc000022070/zen-browser-flake";

    # Opencode
    opencode.url = "github:anomalyco/opencode/v1.1.53";

    # Kiru
    kiru-agent.url = "git+ssh://git@github.com/kiruhq/kiru";
    kiru.url = "github:kiruhq/kiru-nix";
  };

  outputs = {
    self,
    nixpkgs,
    disko,
    home-manager,
    alacritty-theme,
    templ,
    nixpkgs-unstable,
    nixos-hardware,
    ags,
    kiru-agent,
    kiru,
    ...
  } @ inputs: let
    inherit (self) outputs;

    systems = [
      "aarch64-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];

    hosts = [
      {
        name = "itachi";
        hardware = null;
        gaps = false;
        monitors = [
          {
            name = "eDP-1";
            dimensions = "preferred";
            position = "0x0";
            scale = 1.6;
            internal = true;
            framerate = 60;
            transform = 0;
          }
        ];
        cursor = 64;
      }
      {
        name = "karasu";
        hardware = nixos-hardware.nixosModules.framework-13-7040-amd;
        gaps = false;
        monitors = [
          {
            name = "eDP-1";
            dimensions = "preferred";
            position = "0x0";
            scale = 1.6;
            internal = true;
            framerate = 144;
            transform = 0;
          }
        ];
        cursor = 64;
      }
      {
        name = "zen13";
        hardware = nixos-hardware.nixosModules.framework-13-7040-amd;
        gaps = false;
        monitors = [
          {
            name = "eDP-1";
            dimensions = "preferred";
            position = "1920x0";
            scale = 1.6;
            internal = true;
            framerate = 144;
            transform = 0;
          }
          {
            name = "desc:BNQ BenQ RD320UA 49R01325019";
            dimensions = "3840x2160";
            position = "0x0";
            scale = 2.0;
            framerate = 60;
            transform = 0;
          }
        ];
        cursor = 24;
      }

      {
        name = "chidori";
        gaps = false;
        hardware = null;
        monitors = [
          {
            name = "eDP-2";
            width = "2560";
            height = "1600";
            dimensions = "2560x1600";
            position = "1920x0";
            scale = 1.6;
            framerate = 60;
            internal = true;
            transform = 0;
          }
          {
            name = "desc:BNQ BenQ RD320UA 49R01325019";
            dimensions = "3840x2160";
            position = "0x0";
            scale = 2.0;
            framerate = 60;
            transform = 0;
          }
        ];
        cursor = 64;
      }
      {
        name = "amaterasu";
        gaps = true;
        hardware = null;
        monitors = [
          {
            name = "desc:IDI Elgato Prom. 0x01348D27";
            dimensions = "1024x600";
            position = "-1024x0";
            scale = 1;
            framerate = 60;
            transform = 0;
          }
          {
            name = "desc:BNQ BenQ RD320UA 49R01325019";
            dimensions = "preferred";
            position = "0x0";
            scale = 2;
            framerate = 60;
            transform = 0;
          }
          {
            name = "desc:Invalid Vendor Codename - RTK J584T05 0x20231127";
            dimensions = "3840x2160";
            position = "auto-right";
            scale = 2;
            framerate = 60;
            transform = 0;
          }
        ];
        cursor = 64;
      }
      {
        name = "zenbox";
        # Framework Desktop
        hardware = nixos-hardware.nixosModules.framework-desktop-amd-ai-max-300-series;
        gaps = false;
        hasGaming = false;
        monitors = [
          {
            name = "HDMI-A-1"; # Adjust based on actual display
            dimensions = "preferred";
            position = "0x0";
            scale = 1;
            framerate = 60;
            transform = 0;
          }
        ];
        cursor = 32;
      }
    ];

    forAllSystems = fn:
      nixpkgs.lib.genAttrs systems (system:
        fn {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        });
  in {
    overlays = import ./overlays {inherit inputs;};

    formatter = forAllSystems ({pkgs}: pkgs.alejandra);

    packages = forAllSystems ({pkgs}: import ./pkgs pkgs);

    nixosConfigurations = builtins.listToAttrs (
      map (host: {
        name = host.name;
        value = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs outputs;
            meta =
              host
              // {
                hostname = host.name;
              };
          };
          modules =
            [
              # Modules
              disko.nixosModules.disko
              # System Specific
              ./machines/${host.name}/hardware-configuration.nix
              ./machines/${host.name}/disko-config.nix
              # General
              ./configuration.nix
              # Home Manager
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.elliott = import ./home/home.nix;
                home-manager.extraSpecialArgs = {
                  inherit inputs;
                  meta = host;
                };
              }
            ]
            ++ (
              if host.hardware != null
              then [host.hardware]
              else []
            );
        };
      })
      hosts
    );
  };
}
