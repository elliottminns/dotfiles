{
  description = "Top level NixOS Flake";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    #nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

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

    # Templ
    templ.url = "github:a-h/templ";

    # Ags
    ags.url = "github:Aylur/ags";

    # Matugen
    matugen.url = "github:InioX/matugen?ref=v2.2.0";

    # NixVim
    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";

    # Zen browser
    zen-browser.url = "github:MarceColl/zen-browser-flake";
  };

  outputs = {
    self,
    nixpkgs,
    disko,
    home-manager,
    alacritty-theme,
    templ,
    nixpkgs-unstable,
    ags,
    ...
  } @ inputs: let
    inherit (self) outputs;

    systems = [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];

    hosts = [
      {name = "itachi";}
      {
        name = "karasu";
        monitors = [
          {
            internal = true;
            name = "eDP-1";
            width = "2256";
            height = "1504";
            scale = 1.566667;
            framerate = 144;
          }
        ];
        cursor = 64;
      }
      {
        name = "chidori";
        monitors = [
          {
            name = "eDP-2";
            width = "2560";
            height = "1600";
            scale = 1.6;
            internal = true;
          }
        ];
        curor = 64;
      }
      {
        name = "amaterasu";
        monitors = map (
          name: {
            name = name;
            width = "3840";
            height = "2160";
            scale = 2;
            framerate = 60;
          }
        ) ["DP-3"];
        cursor = 64;
      }
    ];

    forAllSystems = fn: nixpkgs.lib.genAttrs systems (system: fn {pkgs = import nixpkgs {inherit system;};});
  in {
    overlays = import ./overlays {inherit inputs;};

    formatter = forAllSystems ({pkgs}: pkgs.alejandra);

    packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});

    nixosConfigurations = builtins.listToAttrs (map (host: {
        name = host.name;
        value = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs outputs;
            meta = {
              hostname = host.name;
            };
          };
          system = "x86_64-linux";
          modules = [
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
          ];
        };
      })
      hosts);
  };
}
