{ config, pkgs, self, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history.size = 10000;
    history.path = "$HOME/.zsh_history";
    history.ignoreAllDups = true;

    initContent = builtins.readFile ./zsh-init.sh;

    shellAliases = {
      edit = "sudo -E nvim -n";
      gitavail = "ssh-add $HOME/Documents/Важное/recovery_keys/GitHub/github_remote_keys/key";
      update = "sudo nixos-rebuild switch";
      stop = "shutdown now";
      edconf = "sudo -E nvim /home/sabrina/nixos/flake.nix";
    };

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
      ];
      theme = "robbyrussell";
    };
  };

  home.sessionVariables = {
    programs = "${self}/home/sabrina/modules/programs";
  };
}
