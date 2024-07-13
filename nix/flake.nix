{
  description = "Top level NixOS Flake";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

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
  };

  outputs = { self, nixpkgs, disko, home-manager, alacritty-theme, templ, nixpkgs-unstable, ags, ... }@inputs: let
    inherit (self) outputs;

    systems = [
      "x86_64-linux"
    ];

    hosts = [
      "itachi"
      "karasu"
      "chidori"
    ];

    pkgs = import nixpkgs {
      system = "x86_64-linux";
      config = {
        allowUnfree = true;
        permittedInsecurePackages = [
          "electron-25.9.0"
        ];
      };
    };

    forAllSystems = nixpkgs.lib.genAttrs systems;
  in  {

    overlays.additions = final: _prev: import ./pkgs final.pkgs;

    overlays.unstable = final: prev: {
      unstable = import nixpkgs-unstable {
        system = prev.system;
        config.allowUnfree = prev.config.allowUnfree;
      };
    };

    nixpkgs.overlays = [
      self.overlays.unstable
      alacritty-theme.overlays.default
      templ.overlays.default
    ];

    packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});

    nixosConfigurations = builtins.listToAttrs (map (name: {
      name = name;
      value = nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs outputs;
        meta = { hostname = name; };
      };
      system = "x86_64-linux";
      modules = [
        # Modules
        disko.nixosModules.disko
      	# System Specific
      	./machines/${name}/hardware-configuration.nix
        ./machines/${name}/disko-config.nix
        # General
        ./configuration.nix
        # Home Manager
        ({ config, pkgs, ...}: {
          nixpkgs.overlays = [
            self.overlays.unstable
            self.overlays.additions
            alacritty-theme.overlays.default
            inputs.templ.overlays.default
          ];
        })
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.elliott = import ./home/home.nix;
          home-manager.extraSpecialArgs = { inherit inputs; };
        }
      ];
    };
    }) hosts);
  };
}
