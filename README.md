```bash
# Форматирование разделов
mkfs.vfat -F 32 -n BOOT /dev/sda1
mkfs.btrfs -L NIXROOT /dev/sda2

# Монтирование корневого раздела для создания подтомов
mount /dev/sda2 /mnt

# Создание Btrfs-подтомов
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@cache

# Отмонтирование перед повторным монтированием по подтомам
umount /mnt

# Монтирование подтомов в нужные точки
mount -o subvol=@,compress=zstd,noatime /dev/sda2 /mnt

mkdir -p /mnt/{home,nix,log,cache}
mount -o subvol=@home,compress=zstd,noatime /dev/sda2 /mnt/home
mount -o subvol=@nix,compress=zstd,noatime /dev/sda2 /mnt/nix   
mount -o subvol=@log,compress=zstd,noatime /dev/sda2 /mnt/log
mount -o subvol=@cache,compress=zstd,noatime /dev/sda2 /mnt/cache

# Монтирование загрузочного раздела
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot

# Генерация конфигурации оборудования
nixos-generate-config --root /mnt

# Установка
nixos-install

# Получение UUID разделов (для ручной настройки configuration.nix при необходимости)
blkid /dev/sda1
blkid /dev/sda2
```

### Замечания:
- Добавлены рекомендуемые опции монтирования Btrfs: `compress=zstd,noatime` — повышают производительность и эффективность использования диска.
- Использован `mkdir -p` для надёжности (не вызовет ошибку, если каталог уже существует).
- После генерации `hardware-configuration.nix` убедитесь, что в нём правильно указаны `fileSystem` с нужными `subvol` и `options`.

Если вы используете UEFI, убедитесь, что `/boot` — это FAT32-раздел (`/dev/sda1`), как и задумано.
