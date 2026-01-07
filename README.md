### 🔧 Шаги по установке

1. **Загрузитесь с установочного образа NixOS** (graphical или minimal).
2. **Отформатируйте диск** (пример для UEFI):

   ```bash
   mkfs.vfat -F 32 -n BOOT /dev/sda1
   mkfs.btrfs -L NIXROOT /dev/sda2
   mount /dev/sda2 /mnt
   btrfs subvolume create /mnt/@
   btrfs subvolume create /mnt/@home
   umount /mnt
   mount -o subvol=@ /dev/sda2 /mnt
   mkdir /mnt/home
   mount -o subvol=@home /dev/sda2 /mnt/home
   mkdir /mnt/boot
   mount /dev/sda1 /mnt/boot
   ```

3. **Сгенерируйте `hardware-configuration.nix`**:

   ```bash
   nixos-generate-config --root /mnt
   ```
