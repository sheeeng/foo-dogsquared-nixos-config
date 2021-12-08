# The module for anything dev-related.
# If you want to see editor-specific modules, see `modules/editors.nix`.
{ config, options, lib, pkgs, ... }:

let cfg = config.modules.dev;
in {
  options.modules.dev = {
    enable = lib.mkEnableOption
      "Configures my barebones requirement for a development environment.";
    shell.enable =
      lib.mkEnableOption "Installs of the shell utilities I rely on.";
    virtualization.enable = lib.mkEnableOption
      "Configures my virtualization-related stuff for my development. (I sometimes have to use these.)";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    ({
      # I want to include documentations for my own sanity, OK?
      documentation = {
        enable = true;
        dev.enable = true;
        nixos.enable = true;
        man.generateCaches = true;
      };

      # Configure all of the development-related configuration in the system.

      # Install Git, our favorite version control system.
      # In this case, we want ALL OF THE EXTENSIONS!
      programs.git = {
        enable = true;
        lfs.enable = true;
        package = pkgs.gitFull;
      };

      programs.gnupg = { agent.enable = true; };

      # Convenience!
      environment.localBinInPath = true;

      # This is set as our system packages for the sake of convenience.
      services.lorri.enable = true;
      environment.systemPackages = with pkgs; [
        cachix # Compile no more by using someone's binary cache!
        curl # Our favorite network client.
        cmake # The poster boy for the hated build system.
        direnv # The power of local development environment.
        gcc # The usual toolchain.
        gnumake # Make your life easier with GNU Make.
        moreutils # Less is more but more utilities, the merrier.

        # I SAID ALL OF THE GIT EXTENSIONS!
        git-crypt
      ];
    })

    (lib.mkIf cfg.shell.enable {
      environment.systemPackages = with pkgs; [
        alacritty # The terminal emu that can run fast.
        lazygit # Git interface for the lazy.
        fd # Oh nice, a more reliable `find`.
        ripgrep # On nice, a more reliable `grep`.
        exa # Oh nice, a shinier `ls`.
        bat # dog > bat > cat
        fzf # A fuzzy finder that enables fuzzy finding not furry finding, a common misconception.
        gopass # An improved version of the password manager for hipsters.
        zoxide # Gain teleportation abilities!
      ];
    })

    # !!! Please add your user to the "libvirtd" group.
    (lib.mkIf cfg.virtualization.enable {
      # Enable podman just as my main container runtime or something.
      virtualisation.podman = {
        enable = true;
        dockerCompat = true;
      };

      # Enable libvirt for muh qemu.
      virtualisation.libvirtd = {
        enable = true;
        qemu.ovmf.enable = true;
      };
    })
  ]);
}
