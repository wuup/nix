{ config, pkgs, lib, ... }:
let
  unstable = import
    (builtins.fetchTarball https://github.com/nixos/nixpkgs/tarball/nixos-unstable)
    { config = config.nixpkgs.config; };
in
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

  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

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

    # Unstable packages
    unstable.code-cursor

    # Bottom (btm) for system resource monitoring
    bottom

    # Disk Usage Analyzer
    qdirstat

    # JetBrains DataGrip for database management
    jetbrains.datagrip

    # OnlyOffice for office productivity
    onlyoffice-bin_latest
  ];

  # Docker and VirtualBox Virtualization
  virtualisation.docker.enable = true;
  virtualisation.virtualbox.host.enable = true;

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia.modesetting.enable = true;
  hardware.nvidia.powerManagement = {
    enable = true;
    preferredMode = "maximum_performance";
  };

  hardware.opengl.driSupport32Bit = true;
  hardware.opengl.extraPackages = with pkgs.pkgsi686Linux; [ libGL vulkan-loader ];

  services.flatpak.enable = true;
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
    options = [ "noatime" "nodiratime" "discard" ];
  };

  powerManagement.cpuFreqGovernor = "performance";

  services.journald.extraConfig = ''
    SystemMaxUse=200M
    RuntimeMaxUse=100M
    MaxFileSec=1day
  '';

  services.journald.storage = "volatile";

  nix.settings.cores = 0;

  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
  };

  # AppImage support
  boot.binfmt.registrations.appimage = {
    wrapInterpreterInShell = false;
    interpreter = "${pkgs.appimage-run}/bin/appimage-run";
    recognitionType = "magic";
    offset = 0;
    mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff'';
    magicOrExtension = ''\x7fELF....AI\x02'';
  };

  # Create Applications directory for users
  systemd.tmpfiles.rules = [
    "d /home/debug/Applications 0755 debug users - -"
  ];

  # SSH Key Generation Service
  systemd.services.generateSSHKey = {
    description = "Generate SSH Key for GitHub";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.openssh pkgs.coreutils pkgs.su ];
    script = ''
      for USER in debug; do
        ${pkgs.su}/bin/su - $USER -c '
          SSH_DIR="/home/$USER/.ssh"
          mkdir -p $SSH_DIR
          chmod 700 $SSH_DIR

          SSH_KEY_PATH="$SSH_DIR/github_ed25519"

          if [ ! -f $SSH_KEY_PATH ]; then
            ssh-keygen -t ed25519 -C "$USER@github" -f $SSH_KEY_PATH -N ""
            chmod 600 $SSH_KEY_PATH
            chmod 644 $SSH_KEY_PATH.pub
            eval "$(ssh-agent -s)"
            ssh-add $SSH_KEY_PATH
            echo "SSH key generated successfully for $USER."
          else
            echo "SSH key already exists for $USER. Skipping generation."
          fi
        '
      done
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  system.stateVersion = "24.05";
}
