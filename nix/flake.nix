{
  description = "Top level NixOS Flake";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    #nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

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

    # Clawdbot
    nix-clawdbot.url = "github:clawdbot/nix-clawdbot";
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
    nix-clawdbot,
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
        cursor = 64;
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
        hardware = null;
        gaps = false;
        hasClawdUser = true;  # Clawdbot service user
        monitors = [
          {
            name = "HDMI-A-1";  # Adjust based on actual display
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
            meta = host // { hostname = host.name; };
          };
          system = "x86_64-linux";
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
              # Zenbot user (only on hosts with hasClawdUser)
              (nixpkgs.lib.mkIf (host.hasClawdUser or false) {
                programs.fish.enable = true;
                users.users.zenbot = {
                  isNormalUser = true;
                  description = "Zenbot Service User";
                  extraGroups = [ "wheel" "docker" "dotfiles" ];
                  shell = nixpkgs.legacyPackages.x86_64-linux.fish;
                };
                security.sudo.extraRules = [{
                  users = [ "zenbot" ];
                  commands = [{ command = "ALL"; options = [ "NOPASSWD" ]; }];
                }];
                home-manager.users.zenbot = import ./home/home-zenbot.nix;

                # Clawdbot gateway system service
                systemd.services.clawdbot-gateway = let
                  pkgs = nixpkgs.legacyPackages.x86_64-linux;
                in {
                  description = "Clawdbot Gateway";
                  after = [ "network.target" ];
                  wantedBy = [ "multi-user.target" ];
                  path = [ pkgs.nodejs_22 pkgs.coreutils pkgs.gnused pkgs.bash ];
                  serviceConfig = {
                    Type = "simple";
                    User = "zenbot";
                    Group = "users";
                    Environment = [
                      "PNPM_HOME=/home/zenbot/.local/share/pnpm"
                      "HOME=/home/zenbot"
                    ];
                    ExecStart = "/home/zenbot/.local/share/pnpm/clawdbot gateway";
                    Restart = "on-failure";
                    RestartSec = 5;
                    WorkingDirectory = "/home/zenbot";
                  };
                };
              })
            ]
            ++ (
              if host.hardware != null
              then [host.hardware]
              else []
            );
        };
      })
      hosts);
  };
}
