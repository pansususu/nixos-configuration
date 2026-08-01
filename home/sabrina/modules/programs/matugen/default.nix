{ config, pkgs, lib, self, ... }:

{ 
  xdg.configFile."matugen".source = config.lib.file.mkOutOfStoreSymlink "${self}/home/sabrina/modules/programs/matugen";
}
