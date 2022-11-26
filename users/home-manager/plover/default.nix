# It's a user that often dwells in the terminal. Mostly used in servers.
{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    wireshark-cli
    bind.dnsutils
    nettools
    bat
    fd
    jq
  ];

  profiles = {
    dev = {
      enable = true;
      shell.enable = true;
    };

    editors.neovim.enable = true;
  };

  systemd.user.sessionVariables = {
    MANPAGER = "nvim +Man!";
    EDITOR = "nvim";
  };

  home.stateVersion = "22.11";
}
