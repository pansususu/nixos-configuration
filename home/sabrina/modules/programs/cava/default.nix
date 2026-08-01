{ config, pkgs, lib, self, ... }:

let
  cava-dynamic = pkgs.writeShellScriptBin "cava" ''
    # Ensure the cava config directory exists
    mkdir -p ~/.config/cava
    
    # Combine the static Nix config and the dynamic Matugen colors
    cat ~/.config/cava/config_base ~/.config/cava/colors > ~/.config/cava/config 2>/dev/null
    
    # Launch the actual CAVA binary
    exec ${pkgs.cava}/bin/cava "$@"
  '';
in
{
  home.packages = [
    (lib.hiPrio cava-dynamic)
  ];

  # Symlink the base config.
  xdg.configFile."cava/config_base".source = config.lib.file.mkOutOfStoreSymlink "${self}/home/sabrina/modules/programs/cava/config";
}
