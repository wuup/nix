# Welcome to my NixOS config

{ config, pkgs, ... }:

let
  userConfig = {
    name = "debug";
    homeDir = "/home/debug";
    description = "Debug user";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      wget
      appimage-run
      signal-desktop
      gh
      nix
      discord
      slack
      steam
      brave
      zoom-us
      ulauncher
      obs-studio
      vlc
      neofetch
      audacity
      obsidian
      teamspeak_client
      libreoffice
    ];
  };
in

{
  # Introducing the computer to its hardware.
  imports = [ ./hardware-configuration.nix ];

  # Setting up GRUB for OS selection at boot.
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
    useOSProber = true;
  };

  # Network setup with a name and NetworkManager for easy internet access.
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
  };

  # Locale and time zone to keep your computer in the loop.
  time.timeZone = "America/New_York";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
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
  };

  # Desktop and login manager setup for a nice GUI.
  services.xserver = {
    enable = true;
    layout = "us";
    xkbVariant = "";
    displayManager.lightdm.enable = true;
    desktopManager.pantheon.enable = true;
  };

  # Configuring system services like printing and sound.
  services = {
    printing.enable = true;
    pipewire = {
      enable = true;
      alsa = { enable = true; support32Bit = true; };
      pulse.enable = true;
    };
  };

  # Sound system with Pipewire and real-time audio privileges.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;

  # User account setup.
  users.users.${userConfig.name} = {
    isNormalUser = true;
    home = userConfig.homeDir;
    createHome = true;
    description = userConfig.description;
    extraGroups = userConfig.extraGroups;
    packages = userConfig.packages;
  };

  # Allowing 'unfree' packages and defining system-wide essentials.
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    vim,
    ripgrep,
    fd,
    wget,
    appimage-run,
    git,
    mongodb,
    htop,
    python3,
    python311Packages.pip,
  ];

  # Systemd setup for services and tasks.
  systemd = {
    tmpfiles.rules = [ "d /home/debug/Applications 0755 debug users - -" ];
    services.cursorAppImage = {
      description = "Sets up Cursor AppImage for 'debug'.";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.wget pkgs.coreutils ];
      script = ''
        mkdir -p /home/debug/Applications
        ${pkgs.wget}/bin/wget -O /home/debug/Applications/cursor-0.28.1-x86_64.AppImage https://download.cursor.sh/linux/appImage/x64
        chmod +x /home/debug/Applications/cursor-0.28.1-x86_64.AppImage
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "debug";
      };
    };
  };

  # AppImage support setup.
  boot.binfmt.registrations.appimage = {
    wrapInterpreterInShell = false;
    interpreter = "${pkgs.appimage-run}/bin/appimage-run";
    recognitionType = "magic";
    offset = 0;
    mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff'';
    magicOrExtension = ''\x7fELF....AI\x02'';
  };

  # System version for upgrades and troubleshooting.
  system.stateVersion = "23.11";
}
