# Reset Kali Linux Raspberry Pi Password Script

This is a Bash script that helps you reset (blank) one or more user passwords on the Kali Linux root partition on an SD card. It is especially useful when you want to remove passwords from your Kali Linux installation before deploying the SD card into a Raspberry Pi. The tool is also intended to make it extremly straighforward when the user has forgotten the Raspberry Pi Kali Linux password and wants to save time to get back in. It should work for all Linux OS installed on a removable drive, but for now this was tested for Kali Linux OS on a Raspberry Pi. 

The Bash script is written in a way to run on both macOS and Linux, but due to the fact macOS can be highly unreliable writting on ext4, it is highly recommended to use a Linux VM instead, so the tool can run seamesly without any issues.

## Features

- **Cross-Platform Support:**  
  - On **macOS**, the script uses `fuse-ext2` (with optional macFUSE) to mount ext partitions.
  - On **Linux**, native ext filesystem support is assumed.
  
- **Flexible Partition Input:**  
  The script accepts either a full device path (e.g. `/dev/sdb2`) or a device identifier (e.g. `sdb2`) and builds the correct device name.

- **Backup/Restore Functionality:**  
  - Optionally backs up the `/etc/shadow` file before making changes.
  - If a backup is detected, you can choose to restore it instead of blanking user passwords.

- **User Account Selection:**  
  Lists all accounts found in the target `/etc/shadow` file and allows you to choose which user(s) should have their passwords blanked. (For example, you may want to specifically blank out the default `kali` account.)

- **Automatic Cleanup:**  
  After making changes, the script unmounts the partition and checks whether the device is still mounted, displaying a final list of connected drives. This helps ensure that you can safely remove the SD card.

## Prerequisites

### For macOS
- **fuse-ext2:**  
  Install via Homebrew:  
  ```bash
  brew install --HEAD fuse-ext2
  ```
- **macFUSE:**  
  For better compatibility, install macFUSE via Homebrew Cask:  
  ```bash
  brew install --cask macfuse
  ```

> **Note:** Even with these tools, writing to ext4 partitions (especially with journaling enabled) can be unreliable. The script recommends using a Linux system (or virtual machine) if you require stable write support.

### For Linux (e.g., Kali Linux)
- Native ext filesystem support is assumed.
- The script relies on standard utilities such as `fdisk` and `mount`.
- The drive listing command defaults to `sudo fdisk -l` if needed.

## Usage

1. **Make the Script Executable:**

   ```bash
   chmod +x reset-kali-RaspPi-pwd++.sh
   ```

2. **Run the Script with `sudo`:**

   ```bash
   sudo ./reset-kali-RaspPi-pwd++.sh
   ```

3. **Follow the Prompts:**

   - The script will list connected drives and prompt you to enter the identifier for the **Kali Linux root partition** (NOT the boot partition). For example, on Linux you can enter `sdb2` or `/dev/sdb2`, depending on your preference.
   - It will then mount the selected partition.
   - Next, the script will check for an existing backup of the `/etc/shadow` file:
     - If one exists, you can choose to restore the backup rather than blanking the passwords.
     - If no backup is found, you will be offered the option to create one.
   - After that, it lists all accounts from the `/etc/shadow` file and prompts you to select the account whose password you wish to blank. If the account already has a blank password, the script will inform you accordingly.
   - You can continue blanking additional accounts or finish the process.

4. **Cleanup:**

   - Once password resetting is complete, the script automatically unmounts the partition.
   - It then checks whether the device is still mounted and lists the connected drives for your final verification.
   - This ensures that the SD card (or external drive) can be safely removed and used on your Raspberry Pi.

## Script Structure

- **Header and Requirements:**  
  The header explains the purpose of the script, supported platforms, and the prerequisites.

- **Functions:**
  - `check_ext_write_support`: Checks whether the OS supports writing to ext partitions and verifies required utilities.
  - `cleanup`: Unmounts the partition, removes the temporary mount point, and lists connected drives to confirm that the device is unmounted.

- **User Prompts:**  
  The script guides you through selecting the partition, deciding on backup/restore, and choosing which user account(s) should have their passwords blanked.

- **Password Reset Logic:**  
  Uses `sed` to remove the password field in the `/etc/shadow` file for the specified accounts.

## Author

(c) @drgfragkos 2020

---

