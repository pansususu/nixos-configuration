{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    silentSDDM.url = "github:uiriansan/SilentSDDM";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, spicetify-nix, silentSDDM, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";

      # Auto-discover hosts: every directory inside ./hosts becomes a
      # `nixosConfigurations.<name>`. To add a device, drop a new directory
      # (with a default.nix + hardware-configuration.nix) inside ./hosts.
      hostDirs = builtins.attrNames (builtins.readDir ./hosts);
      hosts = builtins.filter (name: builtins.pathExists (./hosts + "/${name}/default.nix")) hostDirs;

      mkHost = hostname: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs self; hostname = hostname; };
        modules = [
          ./hosts/${hostname}
          spicetify-nix.nixosModules.spicetify
          silentSDDM.nixosModules.default
          home-manager.nixosModules.home-manager
        ];
      };
    in
    {
      nixosConfigurations = builtins.listToAttrs (
        map (hostname: { name = hostname; value = mkHost hostname; }) hosts
      );
    };
}
