#!/bin/bash
#
# sudo ./reset-kali-RaspPi-password++.sh
#
# This script lists disks, lets you pick the Kali Linux root partition (NOT the boot partition),
# mounts it, optionally backs up /etc/shadow, and resets one or more user passwords to blank 
# (or restores a previously backed-up shadow file).
#
# It first checks if the OS has the capability to write to ext filesystems.
#
# Requirements:
# - On macOS:
#   - fuse-ext2 (or an alternative) must be installed and configured.
#     For example, install via Homebrew:
#         brew install --HEAD fuse-ext2
#   - Additionally, macFUSE should be installed for better compatibility:
#         brew install --cask macfuse
#   - Note: Even with these tools, writing to ext4 (especially with journaling enabled)
#     on macOS can be highly unreliable, affecting the target filesystem on the external drive.
#
# - On Linux: native ext filesystem support is typical.
#
# Run the script with sudo if required: sudo ./reset-kali-RaspPi-password++.sh
#
# Author: (c) @drgfragkos 2020

check_ext_write_support() {
    os_type=$(uname)
    if [ "$os_type" = "Darwin" ]; then
        echo ""
        echo "Detected macOS."
        if ! command -v fuse-ext2 &>/dev/null; then
            echo "ERROR: 'fuse-ext2' is not installed."
            echo "To enable write support for ext2/3/4 filesystems on macOS, you'll need both macFUSE and fuse‑ext2."
            echo "You can install macFUSE by running:"
            echo "  brew install --cask macfuse"
            echo "Then, install fuse-ext2 via:"
            echo "  brew install --HEAD fuse-ext2"
            echo ""
            echo "[!] You cannot use macOS to write to ext4 partitions reliably, especially with journaling enabled."
            echo "[!] Your best option is to use a Linux system (or virtual machine) to perform this action."
            exit 1
        else
            echo "fuse-ext2 is available."
        fi

        # Check for macFUSE kernel extension
        if ! kextstat | grep -i fuse >/dev/null; then
            echo "WARNING: macFUSE kernel extension is not loaded."
            echo "For better support with ext4 partitions (especially with journaling), install and load macFUSE:"
            echo "  brew install --cask macfuse"
            echo "Then, follow the on-screen instructions to allow system extension loading."
        else
            echo "macFUSE kernel extension appears to be loaded."
        fi

        echo ""
        echo "[!] Writing to ext4 partitions on macOS is unreliable, especially if journaling is enabled."
        echo "[!] Your best option is to use a Linux system to write to ext4 partitions."
    elif [ "$os_type" = "Linux" ]; then
        echo ""
        echo "Detected Linux."
        echo "Native ext filesystem write support is assumed."
        echo "Use the command:"
        echo "  brew list | grep ext"
        echo "If you see ext4fuse or fuse-ext2, you may already have a solution for writing to ext4 partitions."
    else
        echo "Unsupported OS: $os_type"
        exit 1
    fi
}

cleanup() {
    echo "Performing cleanup..."
    sudo umount "$mount_point" 2>/dev/null
    sudo rmdir "$mount_point" 2>/dev/null
    sleep 1

    # Check if the device is still mounted.
    if mount | grep -q "$full_device"; then
        echo "WARNING: The device $full_device is still mounted!"
        echo "Please run: sudo umount $full_device"
    else
        echo "The device $full_device appears to be unmounted."
    fi

    echo "Listing connected drives for final confirmation:"
    diskutil list 2>/dev/null || sudo fdisk -l
}

# Check ext filesystem write support before proceeding.
check_ext_write_support

echo "Listing connected drives:"
diskutil list 2>/dev/null || sudo fdisk -l

# Prompt clearly for the root partition (NOT the boot partition).
read -p "Enter the identifier for the Kali Linux ROOT partition (NOT the boot partition) (e.g. sdb2 on Linux or disk2s2 on macOS): " drive_id

# Build full device name (if drive_id does not already begin with '/dev/')
if [[ "$drive_id" =~ ^/dev/ ]]; then
    full_device="$drive_id"
else
    full_device="/dev/$drive_id"
fi

# Create a temporary mount point.
mount_point="/tmp/kali_root"
if [ ! -d "$mount_point" ]; then
    sudo mkdir "$mount_point"
fi

os_type=$(uname)
if [ "$os_type" = "Darwin" ]; then
    echo "Mounting the partition using fuse-ext2..."
    sudo fuse-ext2 -o rw,force "$full_device" "$mount_point"
elif [ "$os_type" = "Linux" ]; then
    echo "Mounting the partition using the native mount command..."
    sudo mount "$full_device" "$mount_point"
fi

if [ $? -ne 0 ]; then
    echo "Error mounting partition. Please ensure the drive identifier is correct and you have write permissions."
    exit 1
fi

shadow_file="$mount_point/etc/shadow"
if [ ! -f "$shadow_file" ]; then
    echo "Error: /etc/shadow not found on the mounted partition."
    sudo umount "$mount_point"
    exit 1
fi

# Backup or restore decision.
if [ -f "${shadow_file}.bak" ]; then
    echo "A backup of the shadow file already exists at ${shadow_file}.bak"
    read -p "Do you want to (B) Blank the password (reset) or (R) Restore the backup? [B/R]: " user_choice
    if [[ "$user_choice" =~ ^[Rr]$ ]]; then
        sudo cp "${shadow_file}.bak" "$shadow_file"
        echo "Backup restored. Exiting."
        cleanup
        exit 0
    fi
else
    read -p "Do you want to create a backup of the /etc/shadow file? [Y/n]: " backup_choice
    if [[ "$backup_choice" =~ ^[Yy]*$ ]]; then
        echo "Backing up the shadow file..."
        sudo cp "$shadow_file" "${shadow_file}.bak"
    else
        echo "Proceeding without backup."
    fi
fi

# Loop to blank one or more user passwords.
echo "The following accounts exist in the target shadow file:"
cut -d: -f1 "$shadow_file"
while true; do
    read -p "Enter the account whose password you wish to blank: " target_user
    if grep -q "^$target_user:" "$shadow_file"; then
        current_entry=$(grep "^$target_user:" "$shadow_file")
        # Check if the password field is already blank.
        if [[ "$current_entry" =~ ^$target_user:: ]]; then
            echo "Account '$target_user' already has an empty password."
        else
            echo "Blanking password for account '$target_user'..."
            if [ "$os_type" = "Darwin" ]; then
                sudo sed -i '' "s/^$target_user:[^:]*:/${target_user}::/" "$shadow_file"
            elif [ "$os_type" = "Linux" ]; then
                sudo sed -i "s/^$target_user:[^:]*:/${target_user}::/" "$shadow_file"
            fi
            echo "Password for '$target_user' has been set to blank."
        fi
    else
        echo "Account '$target_user' not found in the shadow file."
    fi
    read -p "Do you want to blank another user's password? [y/N]: " another
    if [[ ! "$another" =~ ^[Yy]$ ]]; then
        break
    fi
done

echo "Password reset complete for selected accounts."
echo "Unmounting partition..."
cleanup

echo "[x] Done!"
echo "[x] You can now safely remove your drive."
echo ""
echo "[i] Thank you for using ./reset-kali-RaspPi-password++.sh | Follow @drgfragkos on Twitter."
