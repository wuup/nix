# Welcome to my personal NixOS configuration file! This is like the blueprint for my computer, telling it how to set itself up. If you're new to Nix or just curious, I've added comments to make it easier to understand. Let's dive in!

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
      # Add "just for me" packages here
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
      # Any other personal packages
    ];
  };
in

{
  # First things first, we're telling our system about the hardware it's running on. Think of it as introducing your computer to its own body.
  imports = [ ./hardware-configuration.nix ];

  # Now, let's talk about starting up. We use GRUB, a program that lets us choose which operating system to boot into.
  boot.loader.grub = {
    enable = true; # Yes, we want GRUB.
    device = "/dev/sda"; # This is where GRUB lives, on the first hard drive.
    useOSProber = true; # This helps GRUB find other operating systems you might have.
  };

  # Networking setup. Here we give our computer a name and tell it to manage its network connections with NetworkManager.
  networking = {
    hostName = "nixos"; # Like naming a pet, but for your computer.
    networkmanager.enable = true; # This makes connecting to the internet a breeze.
    # If you're behind a proxy, you'd configure it here. Just remove the # to make it active.
    # proxy.default = "http://user:password@proxy:port/";
    # proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  };

  # Setting up the locale and time zone ensures your computer knows where it is and speaks your language.
  time.timeZone = "America/New_York"; # Tell your computer what time it is.
  i18n = {
    defaultLocale = "en_US.UTF-8"; # And that we're using English in the US.
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

  # For the graphical interface, we're setting up a desktop environment and a login manager.
  services.xserver = {
    enable = true; # Yes, we want a graphical interface.
    layout = "us"; # Keyboard layout is set to US.
    xkbVariant = ""; # Default variant.
    displayManager.lightdm.enable = true; # LightDM is our login manager.
    desktopManager.pantheon.enable = true; # And we're using the Pantheon desktop environment.
  };

  # System services like printing and sound are configured here.
  services = {
    printing.enable = true; # Enable printing.
    pipewire = {
      enable = true; # Pipewire for handling multimedia.
      alsa = { enable = true; support32Bit = true; }; # Compatibility settings for sound.
      pulse.enable = true; # Enable PulseAudio support through Pipewire.
      # JACK support is commented out by default. Remove the # if you need it.
      # jack.enable = true;
    };
  };

  # Sound system setup. We're using Pipewire, so PulseAudio is turned off.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true; # Real-time privileges for audio applications.

  # User setup. Here's where I define my user account on this computer.
  users.users.${userConfig.name} = {
    isNormalUser = true; # Yes, it's a regular user account.
    home = userConfig.homeDir; # Home directory.
    createHome = true; # Automatically create the home directory.
    description = userConfig.description; # A simple description.
    extraGroups = userConfig.extraGroups; # Adding to useful groups.
    packages = userConfig.packages; # Some packages I want available to this user.
  };

  # Package management. Here we're allowing 'unfree' packages, which are not open source.
  nixpkgs.config.allowUnfree = true;
  # Defining a list of system-wide packages for easier management and expansion.
  environment.systemPackages = with pkgs; [
    # essential packages for my own personal operating system
    # base useful packages in all environments
    vim, # A highly configurable text editor built to enable efficient text editing
    ripgrep, # A line-oriented search tool that recursively searches your current directory for a regex pattern
    fd, # A simple, fast and user-friendly alternative to 'find'
    wget, # A free utility for non-interactive download of files from the Web
    appimage-run, # Tool to run AppImage files
    git, # A free and open source distributed version control system
    mongodb, # A general purpose, document-based, distributed database built for modern application developers and for the cloud era
    htop, # An interactive process viewer for Unix systems

    # python
    python3, # A programming language that lets you work quickly and integrate systems more effectively

  ];
  # The systemd configuration section is dedicated to setting up system services and tasks automatically.
  systemd = {
    # This rule ensures the creation of a directory specifically for storing applications. It sets the directory permissions to 0755, making it readable and executable by everyone but writable only by the user 'debug'. The directory is owned by 'debug' and belongs to the 'users' group.
    tmpfiles.rules = [ "d /home/debug/Applications 0755 debug users - -" ]; 

    # Defines a systemd service named 'cursorAppImage'. This service is responsible for downloading a specific version of the Cursor AppImage and making it executable. It's designed to run after the network is available and to be available for all users in a multi-user environment.
    services.cursorAppImage = {
      description = "Automatically downloads and sets up the Cursor AppImage for the user 'debug'.";
      after = [ "network.target" ]; # Ensures the service runs after the network is online.
      wantedBy = [ "multi-user.target" ]; # Indicates the service should be available in a multi-user setup.
      path = [ pkgs.wget pkgs.coreutils ]; # Specifies the tools (wget for downloading, coreutils for file operations) required for the script to execute.

      # The script that runs as part of the service. It creates the Applications directory if it doesn't exist, downloads the Cursor AppImage to this directory, and then makes the AppImage executable.
      script = ''
        mkdir -p /home/debug/Applications
        ${pkgs.wget}/bin/wget -O /home/debug/Applications/cursor-0.28.1-x86_64.AppImage https://download.cursor.sh/linux/appImage/x64
        chmod +x /home/debug/Applications/cursor-0.28.1-x86_64.AppImage
      ''; 

      # Configuration for how the service behaves. 'Type=oneshot' means the service will run its task once and then stop. 'RemainAfterExit=true' keeps the service's status as active after completion, useful for tasks that don't need to run continuously. The service runs as the 'debug' user.
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "debug";
      };
    };
  };

  # Support for running AppImages, a type of portable software.
  boot.binfmt.registrations.appimage = {
    wrapInterpreterInShell = false; # Direct execution.
    interpreter = "${pkgs.appimage-run}/bin/appimage-run"; # The program that runs AppImages.
    recognitionType = "magic"; # How we recognize AppImages.
    offset = 0; # No offset needed.
    mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff''; # The magic bytes to look for.
    magicOrExtension = ''\x7fELF....AI\x02''; # More magic bytes that signify an AppImage.
  };

  # Finally, we're setting the version of the system state. This helps with upgrades and troubleshooting.
  system.stateVersion = "23.11"; # The version of NixOS this configuration is designed for.
}

