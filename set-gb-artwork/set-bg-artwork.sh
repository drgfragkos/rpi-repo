#!/bin/bash
#
# ----------------------------------------------------------------------------
# Script Name : set-bg-artwork.sh
# Description : Copies custom background images to Kali’s background directories
#               and updates symbolic links to use those images.
# Usage       : sudo ./set-bg-artwork.sh [options]
#               Options:
#                 -y, --yes    Skip all confirmation prompts (except the reboot).
# Requirements: Must be run as root (sudo or su).
# Author      : (c) @drgfragkos 2024
# ----------------------------------------------------------------------------
# Examples:
#   1) Place your custom images named 'default.jpg' and 'background.jpg' in the
#      'bg-artwork/' folder (same directory as this script).
#   2) Run the script with interactive prompts:
#        sudo ./set-bg-artwork.sh
#   3) Run the script without intermediate confirmations (except reboot):
#        sudo ./set-bg-artwork.sh -y
# ----------------------------------------------------------------------------
#
# Notes:
#   - The script checks if at least 'default.jpg' and 'background.jpg' exist in
#     the local folder 'bg-artwork/'. If not present, it will instruct you to
#     place them there and exit.
#   - We recommend 16:9 images at resolutions like 3840x2160 or 1920x1080/1200.
#   - The script will optionally reboot the system at the end so that changes
#     take effect.
#
# ----------------------------------------------------------------------------


### 1) Parse arguments
skip_confirm="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -y|--yes)
      skip_confirm="true"
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [-y|--yes]"
      echo "       -y, --yes    Skip all confirmation prompts except reboot."
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [-y|--yes]"
      exit 1
      ;;
  esac
done


### 2) Check if running as root
if [[ $EUID -ne 0 ]]; then
  echo "This script requires root privileges."
  echo "Please run it with sudo or switch to root (su)."
  exit 1
fi


### 3) Verify required images in bg-artwork/
BG_ARTWORK_DIR="./bg-artwork"
REQUIRED_FILES=("default.jpg" "background.jpg")

# Make sure the 'bg-artwork' folder exists
if [[ ! -d "$BG_ARTWORK_DIR" ]]; then
  echo "Folder '$BG_ARTWORK_DIR' does not exist."
  echo "Please create it, place default.jpg and background.jpg in it, then re-run."
  exit 1
fi

# Check for required images
for file in "${REQUIRED_FILES[@]}"; do
  if [[ ! -f "$BG_ARTWORK_DIR/$file" ]]; then
    echo "Could not find '$file' in '$BG_ARTWORK_DIR/'."
    echo "Please ensure both 'default.jpg' and 'background.jpg' are in '$BG_ARTWORK_DIR/'."
    exit 1
  fi
done


### 4) Explain the plan (only if not skipping confirmation)
if [[ "$skip_confirm" == "false" ]]; then
  echo "-----------------------------------------------------------------"
  echo "This script will:"
  echo "  1) Copy 'default.jpg' and 'background.jpg' from '$BG_ARTWORK_DIR/'"
  echo "     to '/usr/share/backgrounds/kali/'."
  echo "  2) Update the symbolic link in '/usr/share/backgrounds/kali-16x9/'"
  echo "     to point to the new 'default.jpg'."
  echo "  3) Update the symbolic link in '/usr/share/desktop-base/active-theme/login/'"
  echo "     to point to the new 'background.jpg'."
  echo "  4) Optionally reboot the system for changes to take effect."
  echo "-----------------------------------------------------------------"
  read -rp "Do you want to proceed with these actions? [y/N]: " proceed
  if [[ ! "$proceed" =~ ^[Yy]$ ]]; then
    echo "Aborting script."
    exit 0
  fi
else
  echo "Skipping confirmations. Proceeding with file copying and link updates..."
fi


### 5) Copy images to /usr/share/backgrounds/kali/
TARGET_DIR="/usr/share/backgrounds/kali"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "Directory '$TARGET_DIR' does not exist. Cannot proceed."
  exit 1
fi

echo "Step 1/3: Copying images to '$TARGET_DIR'..."
cp -v "$BG_ARTWORK_DIR/default.jpg" "$TARGET_DIR/" || exit 1
cp -v "$BG_ARTWORK_DIR/background.jpg" "$TARGET_DIR/" || exit 1
echo "Images copied successfully."
echo "-----------------------------------------------------------------"


### 6) Update symbolic link in /usr/share/backgrounds/kali-16x9/
LINK_DIR_16x9="/usr/share/backgrounds/kali-16x9"
if [[ ! -d "$LINK_DIR_16x9" ]]; then
  echo "Directory '$LINK_DIR_16x9' does not exist. Skipping symlink creation."
else
  echo "Step 2/3: Updating symbolic link in '$LINK_DIR_16x9'..."
  ln -sf "$TARGET_DIR/default.jpg" "$LINK_DIR_16x9/default"
  echo "Symbolic link to 'default.jpg' updated in '$LINK_DIR_16x9'."
fi
echo "-----------------------------------------------------------------"


### 7) Update symbolic link for the login background
LOGIN_THEME_DIR="/usr/share/desktop-base/active-theme/login"
if [[ ! -d "$LOGIN_THEME_DIR" ]]; then
  echo "Directory '$LOGIN_THEME_DIR' does not exist. Skipping symlink creation."
else
  echo "Step 3/3: Updating symbolic link in '$LOGIN_THEME_DIR'..."
  ln -sf "$TARGET_DIR/background.jpg" "$LOGIN_THEME_DIR/background"
  echo "Symbolic link to 'background.jpg' updated in '$LOGIN_THEME_DIR'."
fi
echo "-----------------------------------------------------------------"


### 8) Optional reboot prompt (always shown)
echo "All steps completed."
read -rp "Would you like to reboot now so changes take effect? [y/N]: " reboot_ans
if [[ "$reboot_ans" =~ ^[Yy]$ ]]; then
  echo "Rebooting system..."
  reboot
else
  echo "Script finished. Reboot was not initiated."
fi
