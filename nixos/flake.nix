{
  description = "NixOS configuration";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
  inputs.nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

  inputs.agenix.url = "github:ryantm/agenix";
  inputs.agenix.inputs.nixpkgs.follows = "nixpkgs";

  inputs.rust-overlay = {
    url = "github:oxalica/rust-overlay";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  inputs.home-manager.url = "github:nix-community/home-manager/release-24.11";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nur.url = "github:nix-community/NUR";

  inputs.nix-index-database.url = "github:Mic92/nix-index-database";
  inputs.nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

  inputs.disko.url = "github:nix-community/disko";
  inputs.disko.inputs.nixpkgs.follows = "nixpkgs";

  inputs.arion.url = "github:hercules-ci/arion";
  inputs.arion.inputs.nixpkgs.follows = "nixpkgs";

  outputs = inputs:
    with inputs; let
      system = "x86_64-linux";
      globals = builtins.fromJSON (builtins.readFile "${self}/globals.json");

      config = {
        allowUnfree = true;
        permittedInsecurePackages = [
          # FIXME:: add any insecure packages you absolutely need here
        ];
      };

      overlays = [
        nur.overlays.default
        (_final: prev: {
          # this allows us to reference pkgs.unstable
          unstable = import nixpkgs-unstable {
            inherit (prev) system;
            inherit config;
          };
        })
        (import rust-overlay)
      ];

      nixpkgsWithOverlays = with inputs; rec {
        inherit overlays config;
      };

      pkgs = nixpkgsWithOverlays;
      lib = pkgs.lib;

      configurationDefaults = args: {
        nixpkgs = nixpkgsWithOverlays;
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "hm-backup";
        home-manager.extraSpecialArgs = args;
      };

      argDefaults = {
        inherit
          globals
          inputs
          self
          nix-index-database
          ;
        channels = {
          inherit nixpkgs nixpkgs-unstable;
        };
      };

      mkNixosConfiguration = {
        hostname,
        username,
        args ? {},
        modules,
      }: let
        specialArgs = argDefaults // {inherit hostname username;} // args;
      in
        nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules =
            [
              (configurationDefaults specialArgs)
              home-manager.nixosModules.home-manager
              arion.nixosModules.arion
            ]
            ++ modules;
        };
    in {
      nixosConfigurations.nixos = mkNixosConfiguration {
        # FIXME: replace with your server's hostname
        hostname = "bobs-server";
        username = "ironmagma";
        args = {
          nixPkgs = import nixpkgs {inherit system overlays;};
        };
        modules = [
          agenix.nixosModules.age
          ./hetzner.nix
          ./linux.nix
        ];
      };
    };
}
