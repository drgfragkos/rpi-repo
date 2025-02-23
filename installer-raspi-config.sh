#!/bin/sh

# Function to display help message
show_help() {
    echo "Usage: sudo ./installer-raspi-config.sh [options]"
    echo
    echo "This script installs or updates raspi-config on Raspberry Pi running Linux distributions like Kali Linux."
    echo
    echo "Options:"
    echo "  -h, --help    Display this help message and exit"
    echo
    echo "Purpose:"
    echo "  raspi-config is a configuration tool specifically designed for Raspberry Pi. It allows users to easily configure various system settings such as memory split, overclocking, and enabling or disabling interfaces like SPI, I2C, and others."
    echo 
    echo "Author:"
    echo "  (c) @drgfragkos 2025"
    echo
}

# Parse command line arguments
while [ "$1" != "" ]; do
    case $1 in
        -h | --help )
            show_help
            exit 0
            ;;
        * )
            echo "Invalid option: $1"
            show_help
            exit 1
    esac
    shift
done

# Check if running as root
if [ "$(whoami)" != "root" ]; then
  echo "Sorry, you are not root. You must type: sudo ./installer-raspi-config.sh"
  exit 1
fi

# Check for required commands
for cmd in apt-get wget dpkg sort grep sed; do
    if ! command -v $cmd >/dev/null 2>&1; then
        echo "Error: Required command '$cmd' is not installed. Please install it first."
        exit 1
    fi
done

# Check if running on Raspberry Pi by examining /proc/cpuinfo for 'Raspberry'
if ! grep -qi raspberry /proc/cpuinfo; then
    echo "Warning: This script is intended for Raspberry Pi devices. Proceeding anyway..."
fi

# Check if raspi-config is installed
if command -v raspi-config >/dev/null 2>&1; then
  echo "raspi-config is already installed, updating to the latest version..."
else
  echo "raspi-config is not installed, installing the latest version..."
fi

# Update package lists
apt-get update || { echo "Failed to update package lists."; exit 1; }

# Install dependencies
apt-get install -y libnewt0.52 whiptail parted triggerhappy lua5.1 alsa-utils || { echo "Failed to install dependencies."; exit 1; }

# Auto install any missing dependencies
apt-get install -fy || { echo "Failed to auto-install missing dependencies."; exit 1; }

# Retrieve latest package file from the directory listing
POOL_URL="https://archive.raspberrypi.org/debian/pool/main/r/raspi-config/"
LATEST_DEB=$(wget -q -O - "$POOL_URL" | grep -o 'raspi-config_[0-9]\+_all.deb' | sort -V | tail -n 1)

if [ -z "$LATEST_DEB" ]; then
    echo "Failed to determine the latest raspi-config package."
    exit 1
fi

# Extract timestamp (publication date) from filename
TIMESTAMP=$(echo "$LATEST_DEB" | sed -E 's/raspi-config_([0-9]+)_all.deb/\1/')

echo "Latest package determined: $LATEST_DEB"
echo "Publication date (timestamp in filename): $TIMESTAMP"

# Download the latest raspi-config package
TEMP_DEB="/tmp/$LATEST_DEB"
wget -O "$TEMP_DEB" "${POOL_URL}${LATEST_DEB}" || { echo "Failed to download raspi-config package."; exit 1; }

# Install the downloaded package
dpkg -i "$TEMP_DEB" || { echo "Installation of raspi-config failed."; exit 1; }

# Cleanup
rm -f "$TEMP_DEB" || echo "Warning: Failed to remove temporary file $TEMP_DEB"

echo "raspi-config is now installed or updated to the latest version."
echo "Run it by typing: sudo raspi-config"

exit 0