{ config, pkgs, ... }:

{
  networking.hostName = "finix";
  networking.networkmanager.enable = true;

  services.openssh.enable = true;
}
