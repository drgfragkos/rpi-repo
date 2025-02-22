#!/bin/bash
# Kali Linux Comprehensive Update Script
#
# This script performs the following actions in order:
# 1. Updates the package list.
# 2. Upgrades all installed packages.
# 3. Performs a distribution upgrade, handling dependency changes.
# 4. Removes unnecessary packages.
# 5. Cleans up obsolete package files.
# 6. Clears the package cache.
# 7. Reconfigures any partially installed packages.
# 8. Fixes any broken dependencies.
#
# Run this script as a user with sudo privileges:
#   sudo ./update_kali.sh

sudo apt update && sudo apt upgrade -y && sudo apt dist-upgrade -y && sudo apt autoremove -y && sudo apt autoclean -y && sudo apt clean && sudo dpkg --configure -a && sudo apt install -f

# (c) @drgfragkos 2020