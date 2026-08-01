{ config, lib, self, ... }:

{ 
  xdg.configFile."rofi/config.rasi".source = config.lib.file.mkOutOfStoreSymlink "${self}/home/sabrina/modules/programs/rofi/config.rasi";
}
