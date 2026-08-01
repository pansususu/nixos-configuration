{ config, pkgs, inputs, ... }:

{
  time.timeZone = "America/Asuncion";

  i18n.defaultLocale = "es_PY.UTF-8";

  console.keyMap = "la-latin1";

  boot.kernelParams = [ "apparmor=0" ];
  programs.fuse.enable = true;

  programs.ydotool.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      libpng
      libxkbfile
      stdenv.cc.cc
      zlib
      zstd
      openssl
      curl
      expat
      libGL
      libGLU
      libxkbcommon
      libX11
      libXcomposite
      libXcursor
      libXdamage
      libXext
      libXfixes
      libXi
      libXrandr
      libXrender
      libXScrnSaver
      libXtst
      libpulseaudio
      libvorbis
      alsa-lib
      dbus
      dbus-glib
      fontconfig
      freetype
      gtk3
      pango
      cairo
      glib
      systemd
      wayland
      libdrm
      mesa
      vulkan-loader
      vulkan-tools
      pipewire
      ncurses5
      ncurses
      libxshmfence
      libxcb
      xcbutilimage
      xcbutilkeysyms
      xcbutilwm
      pixman
      libepoxy
      libedit
      libgcc
      libselinux
      libsepol
      pcre
      pcre2
      util-linux
      lz4
      bzip2
      libxml2
      libxslt
      agg
      at-spi2-atk
      at-spi2-core
      atk
      boost
      icu
      lcms2
      nspr
      nss
      re2
      snappy
      double-conversion
      libthai
      libdatrie
      minizip
      speechd
      xorg.libXxf86vm
      xorg.xkeyboardconfig
      libSM
      libICE
      libxcb
    ];
  };

  programs.niri.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
    ];
  };

  services.flatpak.enable = true;

  security.polkit.enable = true;

  services.asusd.enable = true;

  virtualisation.libvirtd.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Spicetify
  programs.spicetify = let
    spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  in {
    enable = true;
    spotifyPackage = pkgs.spotify;
    theme = spicePkgs.themes.comfy;
    colorScheme = "Sakura";
    enabledExtensions = with spicePkgs.extensions; [
      adblock
      hidePodcasts
      shuffle
    ];
  };

  # Paquetes de sistema
  environment.pathsToLink = [ "/share/applications" ];

  environment.systemPackages = with pkgs; [
    seatd
    pipewire
    wireplumber
    nano
    pkgs.dnsutils
    fortune
    wget
    git
    nixos-rebuild-ng
    iproute2
    iputils
    killall
    wev
    asusctl
    steam
    steam-run
    distrobox
  ];

  # Fonts
  xdg.icons.enable = true;

  fonts.fontconfig.enable = true;

  fonts.packages = with pkgs; [
    nerd-fonts.caskaydia-cove
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.iosevka
    noto-fonts
    noto-fonts-color-emoji
    noto-fonts-cjk-sans
  ];

  fonts.fontconfig.defaultFonts = {
    emoji = [ "Noto Color Emoji" ];
  };

  # Browser MIME associations
  xdg.mime.defaultApplications = {
    "x-scheme-handler/http" = "vivaldi.desktop";
    "x-scheme-handler/https" = "vivaldi.desktop";
    "text/html" = "vivaldi.desktop";
  };
}
