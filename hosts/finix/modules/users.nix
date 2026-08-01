{ config, pkgs, ... }:

{
  programs.zsh.enable = true;

  users.users.sabrina = {
    isNormalUser = true;
    extraGroups = [ "wheel" "audio" "video" "render" "input" "ydotool" "fuse" "libvirtd" "seat" ];
    shell = pkgs.zsh;
    packages = with pkgs; [ tree ];
  };
}
