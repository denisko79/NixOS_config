# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, ... }:

let
  unstable = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz") {};
in {

  imports = [ 
    ./hardware-configuration.nix
  ];

  system.stateVersion = "25.11";

  # File Systems с добавленными субволами (@nix, @log, @cache)
  # Замени /dev/disk/by-uuid/ на реальные UUID из blkid
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/0eb7311e-c27f-4231-adce-88edac061a3e";
    fsType = "btrfs";
    options = [ "subvol=@" "compress=zstd" "noatime" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/0eb7311e-c27f-4231-adce-88edac061a3e";
    fsType = "btrfs";
    options = [ "subvol=@home" "compress=zstd" "noatime" ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/0eb7311e-c27f-4231-adce-88edac061a3e";
    fsType = "btrfs";
    options = [ "subvol=@nix" "compress=zstd" "noatime" ];
  };

  fileSystems."/var/log" = {
    device = "/dev/disk/by-uuid/0eb7311e-c27f-4231-adce-88edac061a3e";
    fsType = "btrfs";
    options = [ "subvol=@log" "compress=zstd" "noatime" ];
  };

  fileSystems."/var/cache" = {
    device = "/dev/disk/by-uuid/0eb7311e-c27f-4231-adce-88edac061a3e";
    fsType = "btrfs";
    options = [ "subvol=@cache" "compress=zstd" "noatime" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/11E5-97FD";
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
      allowedTCPPorts = [ 22 ];
      allowedUDPPorts = [ ];
    };
  };

  # OpenSSH сервер
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PubkeyAuthentication = true;
      PermitRootLogin = "no";
      PermitEmptyPasswords = false;
      X11Forwarding = true;
      PrintMotd = true;
    };
  };

  # MOTD
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
  users.users.denis = {
    isNormalUser = true;
    description = "Main User";
    extraGroups = [ 
      "wheel" 
      "networkmanager" 
      "audio" 
      "video" 
      "storage"
      "input"
    ];
    hashedPassword = null;
    shell = pkgs.zsh;
    createHome = true;
    home = "/home/denis";
  };

  # Sudo Configuration
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };

  # Programs - SSH агент
  programs.ssh = {
    startAgent = true;
    agentTimeout = "30m";
  };

  # Zsh с Oh-My-Zsh и Powerlevel10k
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    
    ohMyZsh = {
      enable = true;
      theme = "powerlevel10k/powerlevel10k";
      plugins = [ 
        "git" 
        "sudo" 
        "systemd" 
        "docker" 
        "podman"
        "history"
        "colored-man-pages"
        "command-not-found"
        "z"
      ];
    };
    
    shellInit = ''
      if [[ ! -f ~/.p10k.zsh ]]; then
        echo "Powerlevel10k config not found. Run 'p10k configure' after first login."
      fi
    '';
  };

  # Shell aliases
  environment.shellAliases = {
    cat = "bat";
    ls = "ls --color=auto";
    ll = "ls -la";
    la = "ls -A";
    l = "ls -CF";
    grep = "grep --color=auto";
    egrep = "egrep --color=auto";
    fgrep = "fgrep --color=auto";
    
    # Алиасы для eza
    lx = "eza --long --header --group --git --icons";
    lt = "eza --tree --level=2 --icons";
    lla = "eza --long --all --header --group --git --icons";
    
    # Полезные алиасы
    nrs = "sudo nixos-rebuild switch";
    nrb = "sudo nixos-rebuild boot";
    ncg = "sudo nix-collect-garbage -d";
    update = "sudo nix-channel --update && sudo nixos-rebuild switch --upgrade";
  };

  # Podman
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # Fonts — исправленный и оптимизированный блок
  fonts = {
    packages = with pkgs; [
      # Базовые + эмодзи + CJK
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji

      liberation_ttf
      font-awesome_6

      # Nerd Fonts — только нужные для Powerlevel10k / терминалов / иконок
      nerd-fonts.jetbrains-mono     # основной выбор для кода и терминала
      nerd-fonts.fira-code          # лигатуры
      nerd-fonts.hack               # очень читаемый
      nerd-fonts.symbols-only       # обязательно для иконок (p10k, eza, waybar и т.д.)
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [ "Noto Serif" "Noto Color Emoji" ];
        sansSerif = [ "Noto Sans" "Noto Color Emoji" ];
        monospace = [ "JetBrainsMono Nerd Font" "FiraCode Nerd Font" "Hack Nerd Font" "Noto Color Emoji" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  # Настройки переменных окружения
  environment.variables = {
    BAT_THEME = "Dracula";
    EXA_COLORS = "uu=38;5;249:gu=38;5;245:sn=38;5;7:sb=38;5;7:da=38;5;245";
  };

  # Подсветка синтаксиса
  programs.bat.enable = true;
  
  # Дополнительные настройки
  programs.command-not-found.enable = true;

  # System Packages
  environment.systemPackages = with pkgs; [
    # Основные утилиты
    vim
    nodejs_24
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
    
    # ZSH окружение
    zsh
    oh-my-zsh
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
    zsh-history-substring-search
    
    # Powerlevel10k из unstable
    unstable.zsh-powerlevel10k
    
    # SSH и сеть
    openssh
    nmap
    netcat-openbsd
    
    # Git инструменты
    git-crypt
    gh
    lazygit
    
    # Системные утилиты
    usbutils
    pciutils
    lsof
    psmisc
    
    # Терминальные инструменты
    bat
    ripgrep
    fd
    fzf
    eza
    
    # Podman
    podman-compose
    dive
    
    # Другие полезные пакеты
    duf
    bottom
    tealdeer
    jq
    yq
    zoxide
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
    substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
    ];
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
