# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix
  ];

  system.stateVersion = "25.11";

  # File Systems
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/d95e1f66-17ed-4ef6-a138-d231db7f9e94";
    fsType = "btrfs";
    options = [ "subvol=@" "compress=zstd" "noatime" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/d95e1f66-17ed-4ef6-a138-d231db7f9e94";
    fsType = "btrfs";
    options = [ "subvol=@home" "compress=zstd" "noatime" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/3FF6-D880";
    fsType = "vfat";
  };

  # Boot
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 10;
      editor = false;
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
  };

  boot.kernelParams = [ "quiet" "splash" ];
  boot.supportedFilesystems = [ "btrfs" ];

  # ZRAM
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # Networking
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    
    # Firewall configuration
    firewall = {
      enable = true;
      # Разрешаем SSH
      allowedTCPPorts = [ 22 ];
      allowedUDPPorts = [ ];
    };
  };

  # OpenSSH сервер - МИНИМАЛЬНАЯ конфигурация
  services.openssh = {
    enable = true;
    
    # Минимальные настройки для работы
    settings = {
      # Аутентификация
      PasswordAuthentication = true;
      PubkeyAuthentication = true;
      
      # Безопасность
      PermitRootLogin = "no";
      PermitEmptyPasswords = false;
      
      # Базовые настройки
      X11Forwarding = true;
      PrintMotd = true;
    };
  };

  # MOTD (Message of the Day)
  environment.etc."motd".text = ''
    Welcome to ${config.networking.hostName}!
    NixOS ${config.system.nixos.release}
  '';

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
      };
    };
  };

  # Audio - PipeWire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Localization
  time.timeZone = "Europe/Moscow";
  i18n.defaultLocale = "en_US.UTF-8";
  
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # User Configuration
  users.users.user = {
    isNormalUser = true;
    description = "Main User";
    extraGroups = [ 
      "wheel" 
      "networkmanager" 
      "audio" 
      "video" 
      "storage"
    ];
    # Пароль нужно будет установить через 'passwd'
    hashedPassword = null;
    
    shell = pkgs.bash;
    createHome = true;
    home = "/home/user";
  };

  # Sudo Configuration
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };

  # Programs - SSH агент включается здесь
  programs.ssh = {
    startAgent = true;
    agentTimeout = "30m";
    extraConfig = ''
      # Дополнительные настройки SSH клиента
    '';
  };

  # System Packages
  environment.systemPackages = with pkgs; [
    # Основные утилиты
    vim
    wget
    curl
    git
    htop
    btop
    nano
    networkmanagerapplet
    bluez
    bluez-tools
    btrfs-progs
    mc
    fastfetch
    
    # SSH
    openssh
    
    # Сетевые утилиты
    nmap
    netcat-openbsd
    
    # Дополнительные инструменты для Git
    git-crypt    # для шифрования секретов в репозитории
    gh           # GitHub CLI
    lazygit      # TUI интерфейс для Git

    # Системные утилиты
    usbutils
    pciutils
  ];
  
  # Дополнительные сервисы
  services = {
    dbus.enable = true;
    blueman.enable = true;
    udisks2.enable = true;
  };
  
  # Включение firmware
  hardware.enableRedistributableFirmware = true;

  # Nix settings
  nix.settings.auto-optimise-store = true;
}
