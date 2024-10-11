{ config, pkgs, lib, ... }:

let
  unstable = import
    (builtins.fetchTarball "https://github.com/nixos/nixpkgs/tarball/nixos-unstable")
    { config = config.nixpkgs.config; };
in
{
  imports = [
    ./hardware-configuration.nix
    # Import Home Manager as a NixOS module
    (import (builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-23.05.tar.gz") + "/nixos")
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Bootloader configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking configuration
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 ];  # Open ports for SSH and web
    allowedUDPPorts = [ 53 123 ];     # DNS and NTP
  };
  networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];

  # Localization settings
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  # X server and desktop environment
  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];
    displayManager.gdm = {
      enable = true;
      wayland = true;  # Explicitly enable Wayland
    };
    desktopManager.gnome.enable = true;
  };

  # Printing services
  services.printing.enable = false;

  # Audio configuration with Pipewire
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse = {
      enable = true;
      support32Bit = true;
    };
  };
  security.rtkit.enable = true;

  # User configuration
  users.users.debug = {
    isNormalUser = true;
    description = "Alan Hamlyn";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    # Home directory is set by default to /home/debug
  };

  # Nix settings
  nix.settings.cores = 4;

  # System packages
  environment.systemPackages = with pkgs; [
    firefox
    libreoffice
    gnome.gnome-terminal
    gparted
    audacity
    vlc
    remmina
    gnome.gnome-disk-utility
    evince
    git
    brave
    discord
    google-chrome
    steam
    steam-run
    vscode
    obsidian
    chromium
    zoom-us
    thunderbird
    signal-desktop
    protonmail-bridge
    vim
    appimage-run             # AppImage support
    unstable.code-cursor     # Unstable package
    bottom                   # System resource monitoring
    qdirstat                 # Disk usage analyzer
    jetbrains.datagrip       # JetBrains DataGrip
    onlyoffice-bin_latest    # OnlyOffice
  ];

  # GNOME extensions
  environment.gnomeExtensions = with pkgs.gnomeExtensions; [
    dash-to-dock
    gnome-shell-pomodoro
    gnome-shell-system-monitor
  ];

  # Virtualization
  virtualisation = {
    docker.enable = true;
    virtualbox.host.enable = true;  # Only enable the host component
    # Removed virtualbox.guest.enable to prevent conflicts
  };

  # NVIDIA configuration
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement = {
      enable = true;
      preferredMode = "maximum_performance";
    };
  };
  hardware.opengl = {
    driSupport32Bit = true;
    extraPackages = with pkgs.pkgsi686Linux; [ libGL vulkan-loader ];
  };

  # Additional services
  services = {
    flatpak.enable = true;
    mongodb.enable = true;
    journald = {
      storage = "volatile";
      extraConfig = ''
        SystemMaxUse=200M
        RuntimeMaxUse=100M
        MaxFileSec=1day
      '';
    };
  };

  # Kernel parameters and sysctl settings
  boot = {
    kernelParams = [ "quiet" ];
    kernel = {
      zswap = {
        enable = true;
        compressor = "lz4";
        maxPoolPercent = 20;
      };
      sysctl = {
        "vm.swappiness" = 10;
        "kernel.perf_event_paranoid" = 2;
      };
    };
  };

  # File system configuration
  fileSystems = {
    "/tmp" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "size=4G" "mode=1777" ];
    };
    "/" = {
      device = "/dev/disk/by-uuid/edd63e45-be15-42f1-b2b1-026d039720de";
      fsType = "ext4";
      options = [ "noatime" "nodiratime" ];
      autoTrimInterval = "weekly";  # Use autoTrimInterval instead of discard
    };
  };

  # Power management
  powerManagement.cpuFreqGovernor = "performance";

  # System state version
  system.stateVersion = "24.05";  # Set to the latest stable version

  # Home Manager configuration for user 'debug'
  home-manager.users.debug = { pkgs, ... }: {
    # SSH configuration
    programs.ssh = {
      enable = true;
      startAgent = true;
      config = {
        host."github.com" = {
          IdentityFile = "~/.ssh/github_ed25519";
        };
      };
    };

    # Create Applications directory in home
    home.file."Applications" = {
      isDirectory = true;
      mode = "0755";
    };

    # Additional Home Manager configurations can be added here
  };
}
