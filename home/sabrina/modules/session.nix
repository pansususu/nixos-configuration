{ config, pkgs, lib, self, ... }:

{
  xdg.configFile."niri/config.kdl".source = "${self}/config/niri/config.kdl";

  # ---------------------------------------------------------------------------
  # Quickshell ilyamiro shell.
  # The QML tree and its helper scripts are deployed under ~/.config/hypr/...
  # (same layout as upstream) so the ~50 hardcoded paths inside the QML files
  # keep resolving without any QML edits. All hyprctl calls go through the
  # shim on PATH, which translates them to `niri msg`.
  # ---------------------------------------------------------------------------

  home.file.".config/hypr/scripts/quickshell" = {
    source = "${self}/home/sabrina/shell/qml";
    recursive = true;
  };

  home.file.".config/hypr/scripts/caching.sh" = {
    source = "${self}/home/sabrina/shell/scripts/caching.sh";
    executable = true;
  };
  home.file.".config/hypr/scripts/exit.sh" = {
    source = "${self}/home/sabrina/shell/scripts/exit.sh";
    executable = true;
  };
  home.file.".config/hypr/scripts/lock.sh" = {
    source = "${self}/home/sabrina/shell/scripts/lock.sh";
    executable = true;
  };
  home.file.".config/hypr/scripts/qs_manager.sh" = {
    source = "${self}/home/sabrina/shell/scripts/qs_manager.sh";
    executable = true;
  };
  home.file.".config/hypr/scripts/reload.sh" = {
    source = "${self}/home/sabrina/shell/scripts/reload.sh";
    executable = true;
  };
  home.file.".config/hypr/scripts/screenshot.sh" = {
    source = "${self}/home/sabrina/shell/scripts/screenshot.sh";
    executable = true;
  };
  home.file.".config/hypr/scripts/volume_listener.sh" = {
    source = "${self}/home/sabrina/shell/scripts/volume_listener.sh";
    executable = true;
  };
  home.file.".config/hypr/scripts/workspaces.sh" = {
    source = "${self}/home/sabrina/shell/scripts/workspaces.sh";
    executable = true;
  };

  # ---------------------------------------------------------------------------
  # hyprctl -> niri shim (installed under multiple names).
  # ---------------------------------------------------------------------------
  home.packages = let
    shim = pkgs.writeScriptBin "hyprctl" (builtins.readFile "${self}/home/sabrina/shell/shims/hyprctl.py");
    shimAs = name: pkgs.writeScriptBin name (builtins.readFile "${self}/home/sabrina/shell/shims/hyprctl.py");
  in [
    shim
    (shimAs "n")
    (shimAs "swww")
    (shimAs "swww-daemon")

    pkgs.quickshell
    pkgs.swaybg
    pkgs.matugen

    # Shell dependencies (from the upstream hyprland session)
    pkgs.rofi
    pkgs.pavucontrol
    pkgs.fortune
    pkgs.wl-screenrec
    pkgs.alsa-utils
    pkgs.networkmanager_dmenu
    pkgs.wl-clipboard
    pkgs.fd
    pkgs.qt6.qtmultimedia
    pkgs.qt6.qt5compat
    pkgs.qt6.qtwebsockets
    pkgs.qt6.qtwebengine
    pkgs.ripgrep
    pkgs.gtk3
    pkgs.cava
    pkgs.cliphist
    pkgs.tree
    pkgs.jq
    pkgs.socat
    pkgs.pamixer
    pkgs.brightnessctl
    pkgs.acpi
    pkgs.iw
    pkgs.bluez
    pkgs.libnotify
    pkgs.networkmanager
    pkgs.lm_sensors
    pkgs.bc
    pkgs.pulseaudio
    pkgs.ladspaPlugins
    pkgs.ladspa-sdk
    pkgs.imagemagick

    # niri-specific additions
    pkgs.inotify-tools
    pkgs.grim
    pkgs.slurp
    pkgs.satty
    pkgs.gpu-screen-recorder
    pkgs.ffmpeg
    pkgs.mpvpaper
    pkgs.playerctl
    pkgs.swayosd
  ];

  home.sessionVariables.NIXOS_OZONE_WL = "1";
}
