{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
  networking.nameservers = [ "1.1.1.1" "1.0.0.1" ]; 
  
  time.timeZone = "America/New_York";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.ntp.enable = true;

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  services.printing.enable = false;

  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.debug = {
    isNormalUser = true;
    description = "Alan Hamlyn";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  programs.firefox.enable = true;
  nixpkgs.config.allowUnfree = true;

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
    mongodb-compass
    teamspeak_client
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
  ];

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia.modesetting.enable = true;
  hardware.nvidia.powerManagement.enable = true;
  hardware.opengl.driSupport32Bit = true;
  hardware.opengl.extraPackages = with pkgs.pkgsi686Linux; [ libGL vulkan-loader ];

  services.flatpak.enable = true;
  virtualisation.virtualbox.host.enable = true;
  services.mongodb.enable = true;

  boot.kernelParams = [ "zswap.enabled=1" "zswap.compressor=lz4" "zswap.max_pool_percent=20" "kernel.perf_event_paranoid=2" "quiet" ];

  fileSystems."/tmp" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "size=4G" "mode=1777" ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/edd63e45-be15-42f1-b2b1-026d039720de";
    fsType = "ext4";
    options = [ "noatime" "discard" ];
  };

  powerManagement.cpuFreqGovernor = "schedutil";

  services.journald.extraConfig = ''
    SystemMaxUse=200M
    RuntimeMaxUse=100M
    MaxFileSec=1day
  '';

  nix.settings.cores = 0;

  boot.kernel.sysctl = {
    "vm.swappiness" = 20;
  };

  system.stateVersion = "24.05";
}
