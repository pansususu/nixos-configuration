{ config, pkgs, inputs, self, lib, ... }:

{
  home.username = "sabrina";
  home.homeDirectory = "/home/sabrina";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  imports =
    let
      moduleFiles = builtins.filter (n: builtins.match ".*\.nix" n != null)
        (builtins.attrNames (builtins.readDir ./modules));
      programDirs = builtins.filter
        (n: builtins.pathExists ./modules/programs/${n}/default.nix)
        (builtins.attrNames (builtins.readDir ./modules/programs));
    in
      (map (n: ./modules/${n}) moduleFiles)
      ++ (map (n: ./modules/programs/${n}/default.nix) programDirs);

  home.packages = with pkgs; [
    vivaldi
    alacritty
    obsidian
    vscode
    discord
    qbittorrent
    prismlauncher
    nautilus
    micro
    opencode
    fastfetch
    btop
    playerctl
    brightnessctl
    pavucontrol
    virt-manager
    nwg-look
    xwayland-satellite
    python3
    python3Packages.tkinter
    bazaar
    cowsay
    papirus-icon-theme
    oreo-cursors-plus
    vinegar
    rojo
    luau-lsp
    android-studio
    android-tools
    onlyoffice-desktopeditors
    lshw
    fuse
    appimage-run
    ydotool
    obs-studio
    kdePackages.kamoso
    satty
  ];

  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name = "oreo_spark_blue_cursors";
      package = pkgs.oreo-cursors-plus;
    };
    font = {
      name = "CaskaydiaCove Nerd Font";
      size = 10;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  programs.bash = {
    enable = true;
    bashrcExtra = ''
      . /etc/bashrc
      unset __HM_SESS_VARS_SOURCED
      export YDOTOOL_SOCKET=/run/ydotoold/socket
    '';
    shellAliases = {
      cdnix      = "cd /home/sabrina/nixos";
      ednix      = "sudo nano /home/sabrina/nixos/flake.nix";
      edhost     = "sudo nano /home/sabrina/nixos/hosts/finix/default.nix";
      edhome     = "sudo nano /home/sabrina/nixos/home/sabrina/default.nix";
      edniri     = "nano /home/sabrina/nixos/config/niri/config.kdl";
      nixrebuild = "sudo git -C /home/sabrina/nixos add . && sudo git -C /home/sabrina/nixos commit -m 'auto: update config' && sudo nixos-rebuild switch --flake /home/sabrina/nixos#finix";
      nixgen     = "nixos-rebuild list-generations";
      nixclean   = "sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations +5 && sudo nix-store --gc && nixrebuild";
      clean      = "clear";
    };
  };

  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "sudo" "web-search" "colorize" ];
    };
    initContent = ''
      autoload -Uz vcs_info
      precmd() { vcs_info }
      zstyle ':vcs_info:git:*' check-for-changes true
      zstyle ':vcs_info:git:*' formats ' %F{86}[%F{81}%b%F{86}]%f'
      zstyle ':vcs_info:git:*' actionformats ' %F{86}[%F{208}%b|%a%F{86}]%f'
      PROMPT='%F{81}%n%F{117}@%F{86}%m%F{81}:%F{117}%~%F{86}''${vcs_info_msg_0_}%F{81}%(#.#.❯)%f '
      unset __HM_SESS_VARS_SOURCED
      export YDOTOOL_SOCKET=/run/ydotoold/socket
    '';
    shellAliases = {
      cdnix      = "cd /home/sabrina/nixos";
      ednix      = "sudo nano -l /home/sabrina/nixos/flake.nix";
      edhost     = "sudo nano -l /home/sabrina/nixos/hosts/finix/default.nix";
      edhome     = "sudo nano -l /home/sabrina/nixos/home/sabrina/default.nix";
      edniri     = "nano -l /home/sabrina/nixos/config/niri/config.kdl";
      nixrebuild = "sudo git -C /home/sabrina/nixos add . && sudo git -C /home/sabrina/nixos commit -m 'auto: update config' && sudo nixos-rebuild switch --flake /home/sabrina/nixos#finix";
      nixgen     = "nixos-rebuild list-generations";
      nixclean   = "sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations +5 && sudo nix-store --gc && nixrebuild";
      clean      = "clear";
    };
  };

  home.sessionVariables = {
    XCURSOR_SIZE = "32";
    XCURSOR_THEME = "oreo_spark_blue_cursors";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    BROWSER = "vivaldi";
    ANDROID_EMULATOR_USE_SYSTEM_VULKAN = "1";
    PYTHONPATH = "${pkgs.python3Packages.tkinter}/${pkgs.python3.sitePackages}";
    YDOTOOL_SOCKET = "/run/ydotoold/socket";
  };

  xdg.mime.enable = true;

  xresources.properties = {
    "Xcursor.theme" = "oreo_spark_blue_cursors";
    "Xcursor.size" = 32;
  };
}
