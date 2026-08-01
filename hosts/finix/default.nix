# finix — NixOS host configuration.
# Target machine: user sabrina, hostname finix, niri + quickshell shell.
{ config, pkgs, lib, inputs, self, hostname, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/boot.nix
    ./modules/hardware.nix
    ./modules/networking.nix
    ./modules/system.nix
    ./modules/users.nix
    ./modules/sddm.nix
  ];

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "26.11";

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";
    extraSpecialArgs = { inherit inputs self; };
    users.sabrina = import ../../home/sabrina;
  };
}
