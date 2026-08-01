{ config, self, ... }:

{
  xdg.configFile."kitty".source = config.lib.file.mkOutOfStoreSymlink "${self}/home/sabrina/modules/programs/kitty";
}
