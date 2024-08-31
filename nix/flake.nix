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
  };

  outputs = { self, nixpkgs, disko, home-manager, alacritty-theme, templ, nixpkgs-unstable, ags, ... }@inputs: let
    inherit (self) outputs;

    systems = [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];

    hosts = [
      "itachi"
      "karasu"
      "chidori"
    ];

    forAllSystems = nixpkgs.lib.genAttrs systems;
  in  {
    overlays = import ./overlays {inherit inputs;};

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
