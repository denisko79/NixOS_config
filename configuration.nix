# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix
  ];

  system.stateVersion = "25.11";

  # File Systems с добавленными субволами (@nix, @log, @cache)
  # Замени /dev/disk/by-uuid/ на реальные UUID из blkid
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/твой-uuid";
    fsType = "btrfs";
    options = [ "subvol=@" "compress=zstd" "noatime" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/твой-uuid";
    fsType = "btrfs";
    options = [ "subvol=@home" "compress=zstd" "noatime" ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/твой-uuid";
    fsType = "btrfs";
    options = [ "subvol=@nix" "compress=zstd" "noatime" ];
  };

  fileSystems."/var/log" = {
    device = "/dev/disk/by-uuid/твой-uuid";
    fsType = "btrfs";
    options = [ "subvol=@log" "compress=zstd" "noatime" ];
  };

  fileSystems."/var/cache" = {
    device = "/dev/disk/by-uuid/твой-uuid";
    fsType = "btrfs";
    options = [ "subvol=@cache" "compress=zstd" "noatime" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/твой-uuid";
    fsType = "vfat";
  };

  # Btrfs autoScrub
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" "/home" "/nix" "/var/log" "/var/cache" ];
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

  # ZRAM (подняли до 75%)
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 75;
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

  # OpenSSH сервер - МИНИМАЛЬНАЯ конфигурация (не трогаем)
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

  # User Configuration - МЕНЯЕМ BASH НА ZSH
  users.users.denis = {
    isNormalUser = true;
    description = "Main User";
    extraGroups = [ 
      "wheel" 
      "networkmanager" 
      "audio" 
      "video" 
      "storage"
      "input"  # Добавили для input устройств (если нужно)
    ];
    # Пароль нужно будет установить через 'passwd'
    hashedPassword = null;
    
    # ЗДЕСЬ МЕНЯЕМ SHELL НА ZSH
    shell = pkgs.zsh;
    createHome = true;
    home = "/home/denis";
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

  # Zsh с Oh-My-Zsh
  programs.zsh = {
    enable = true;
    
    # Автодополнение
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    
    # Oh-My-Zsh
    ohMyZsh = {
      enable = true;
      plugins = [ 
        "git" 
        "sudo" 
        "systemd" 
        "docker" 
        "podman"
        "history"
        "colored-man-pages"
        "command-not-found"
      ];
      theme = "robbyrussell";  # Можно изменить на другой
      # Другие популярные темы: "agnoster", "bureau", "avit"
    };
  };

  # Shell aliases для zsh (можно оставить те же)
  environment.shellAliases = {
    cat = "bat";  # Заменяем cat на bat для подсветки
    ls = "ls --color=auto";  # Цвета в ls
    ll = "ls -la";
    la = "ls -A";
    l = "ls -CF";
    grep = "grep --color=auto";
    egrep = "egrep --color=auto";
    fgrep = "fgrep --color=auto";
  };

  # Podman (контейнеризация, альтернатива Docker)
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;  # Для совместимости с docker командами (podman -> docker alias)
    defaultNetwork.settings.dns_enabled = true;  # DNS в контейнерах
    autoPrune = {
      enable = true;  # Авто-очистка неиспользуемых образов/контейнеров
      dates = "weekly";
    };
  };

  # Fonts (шрифты для терминала/консоли/приложений)
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liberation_ttf
    font-awesome

    # Nerd Fonts — для тем типа Agnoster
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.hack
    powerline-fonts  # Для powerline тем
  ];

  # Подсветка синтаксиса и полезные утилиты
  programs.bat.enable = true;  # bat - cat с подсветкой синтаксиса
  environment.variables = {
    BAT_THEME = "Dracula";  # Тема для bat (можно изменить)
  };

  # System Packages - УБИРАЕМ POWERLEVEL10K
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
    
    # ZSH и Oh-My-Zsh
    zsh
    oh-my-zsh
    
    # Дополнительные плагины для zsh
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
    
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

    # Подсветка и шрифты
    bat  # Для подсветки синтаксиса в терминале
    ripgrep  # rg - быстрый grep с подсветкой

    # Podman-related
    podman-compose  # Для compose-файлов (если нужно)
    dive  # Анализатор образов контейнеров
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
  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [ "https://cache.nixos.org/" "https://nix-community.cachix.org" ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  # Авто-очистка Nix
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # Логи journald
  services.journald.extraConfig = "SystemMaxUse=300M";
}
