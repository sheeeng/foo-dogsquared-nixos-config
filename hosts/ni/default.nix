{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    inputs.guix-overlay.nixosModules.guix-binary

    (lib.mapHomeManagerUser "foo-dogsquared" {
      extraGroups = [ "wheel" "audio" "docker" "podman" "networkmanager" ];
      hashedPassword =
        "$6$.cMYto0K0CHbpIMT$dRqyKs4q1ppzmTpdzy5FWP/V832a6X..FwM8CJ30ivK0nfLjQ7DubctxOZbeOtygfjcUd1PZ0nQoQpOg/WMvg.";
      isNormalUser = true;
      createHome = true;
      home = "/home/foo-dogsquared";
    })
  ];

  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
    "riscv64-linux"
  ];

  boot.initrd.supportedFilesystems = [ "btrfs" ];
  boot.supportedFilesystems = [ "btrfs" ];

  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [
      "/mnt/archives"
    ];
  };

  # My custom configuration with my custom modules starts here.
  profiles = {
    i18n.enable = true;
    archiving.enable = true;
    system = {
      enable = true;
      audio.enable = true;
      fonts.enable = true;
      hardware.enable = true;
      cleanup.enable = true;
      autoUpgrade.enable = true;
    };
    dev = {
      enable = true;
      shell.enable = true;
      virtualization.enable = true;
      neovim.enable = true;
    };
  };

  tasks = {
    multimedia-archive.enable = true;
    backup-archive.enable = true;
  };
  themes.themes.a-happy-gnome.enable = true;

  environment.systemPackages = with pkgs; [
    # This is installed just to get Geiser to properly work.
    guile_3_0
  ];

  # Enable Guix service.
  services.guix-binary.enable = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Set your time zone.
  time.timeZone = "Asia/Manila";

  # Doxxing myself.
  location = {
    latitude = 15.0;
    longitude = 121.0;
  };

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp1s0.useDHCP = true;
  networking.interfaces.wlp2s0.useDHCP = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;

  services.auto-cpufreq.enable = true;
  services.thermald.enable = true;
  services.avahi.enable = true;

  # The usual doas config.
  security.doas = {
    enable = true;
    extraRules = [{
      groups = [ "wheel" ];
      persist = true;
    }];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}

