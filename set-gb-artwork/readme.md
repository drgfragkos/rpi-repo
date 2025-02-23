# set-bg-artwork.sh

# set-bg-artwork.sh

A Bash script that copies custom background images into Kali Linux's designated background directories and updates symbolic links accordingly. Optionally, the script can prompt to reboot the system so that changes take effect.

## Features

- **Copy Images:** Moves custom `default.jpg` and `background.jpg` from the `bg-artwork/` folder to `/usr/share/backgrounds/kali/`.
- **Update Symbolic Links:**
  - Links `/usr/share/backgrounds/kali-16x9/default` to the new `default.jpg`.
  - Links `/usr/share/desktop-base/active-theme/login/background` to the new `background.jpg`.
- **Interactive and Non-interactive Mode:** 
  - Run interactively to confirm each step.
  - Use the `-y` or `--yes` flag to skip confirmations (except for the final reboot prompt).
- **Root Privileges Required:** Must be run as root.

## Requirements

- **Kali Linux:** Must have the background directories:
  - `/usr/share/backgrounds/kali/`
  - `/usr/share/backgrounds/kali-16x9/` (for 16:9 images)
  - `/usr/share/desktop-base/active-theme/login`
- **Custom Images:**
  - Place your `default.jpg` and `background.jpg` files inside a folder called `bg-artwork` located in the same directory as the script.
- **Root Access:** The script must be executed with root privileges (e.g., using `sudo`).

## Setup

1. **Create the `bg-artwork` Folder:**

   Ensure a folder named `bg-artwork/` exists in the same directory as `set-bg-artwork.sh`.

2. **Add Custom Images:**

   Place your `default.jpg` and `background.jpg` files into the `bg-artwork/` folder.

## Usage

### Interactive Mode

Run the script without additional flags to use the interactive prompts:

```bash
sudo ./set-bg-artwork.sh
```

### Non-Interactive Mode

To skip the confirmation prompts (except for the reboot):

```bash
sudo ./set-bg-artwork.sh -y
```

### Help Option

For a quick usage reminder:

```bash
sudo ./set-bg-artwork.sh -h
```

## How It Works

1. **Argument Parsing:**
   - Supports `-y`/`--yes` to skip confirmation prompts.
   - Supports `-h`/`--help` to display usage instructions.

2. **Root Privilege Check:**
   - Verifies that the script is run as root.

3. **Image Verification:**
   - Checks for the existence of `bg-artwork/` folder and the required images.

4. **Image Copy:**
   - Copies `default.jpg` and `background.jpg` from `bg-artwork/` to `/usr/share/backgrounds/kali/`.

5. **Update Symbolic Links:**
   - Updates the link in `/usr/share/backgrounds/kali-16x9/` for `default.jpg`.
   - Updates the link in `/usr/share/desktop-base/active-theme/login` for `background.jpg`.

6. **Optional Reboot:**
   - Offers to reboot the system so that changes take effect.

## Notes

- **Image Recommendations:** It is recommended to use 16:9 images at resolutions like 3840x2160 or 1920x1080/1200.
- **Backup:** Ensure you have backups or a recovery plan before executing system-wide changes.
- **Customization:** Modify paths and filenames as needed based on your system configuration.

## License

[Your License Information Here]

## Author

(c) 2024 @drgfragkos

```