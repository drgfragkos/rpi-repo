#!/bin/bash
#
# -------------------------------------------------------------------------
# reset-xfce.sh
#
# This script completely removes the XFCE4 desktop environment, LightDM,
# and the X server from Kali Linux, then reinstalls them from scratch.
#
# INSTRUCTIONS:
# 1. Switch to a TTY (text console) before running this script:
#    - Press Ctrl + Alt + F3 (or Ctrl + Alt + F1/F2... depending on setup).
#    - Log in with your username and password.
#
# 2. Make the script executable:
#    chmod +x reset-xfce.sh
#
# 3. Run the script as root:
#    sudo ./reset-xfce.sh
#
# HOW IT WORKS:
# - The script stops the graphical environment (XFCE4 + X server).
# - Asks you to confirm each step (uninstall, cleanup, reinstall, etc.).
# - Tracks progress in a file named 'xfce_reset.track' in the current directory.
#   If something interrupts the process, rerun the script and it will resume
#   from the last completed step.
# - If all steps are successful, it removes 'xfce_reset.track' to allow a clean
#   start if the script is run again.
#
# Author: 
#   (c) @drgfragkos 2025 
#
# -------------------------------------------------------------------------

#######################################
# Global Variables
#######################################
TRACK_FILE="xfce_reset.track"   # File to store the last completed step
CURRENT_STEP=0                  # Holds the current step number

#######################################
# confirm: Ask user for y/n confirmation
# Usage:   confirm "Your question?" && <action if yes>
#######################################
confirm() {
    local prompt="$1"
    while true; do
        read -rp "$prompt (y/n): " choice
        case "$choice" in
            [Yy]* ) return 0 ;;  # User chose yes
            [Nn]* ) return 1 ;;  # User chose no
            * ) echo "Please answer y or n." ;;
        esac
    done
}

#######################################
# load_progress: Load last completed step from TRACK_FILE (if exists)
#######################################
load_progress() {
    if [[ -f "$TRACK_FILE" ]]; then
        # shellcheck source=/dev/null
        source "$TRACK_FILE"
        # Ensure CURRENT_STEP is a valid number
        if [[ ! "$CURRENT_STEP" =~ ^[0-9]+$ ]]; then
            echo "Warning: TRACK_FILE is corrupted or invalid. Resetting progress."
            CURRENT_STEP=0
        else
            echo "Resuming from step #$CURRENT_STEP..."
        fi
    fi
}

#######################################
# save_progress: Save current step to TRACK_FILE
#######################################
save_progress() {
    echo "CURRENT_STEP=$CURRENT_STEP" > "$TRACK_FILE"
}

#######################################
# complete_step: Mark a step as completed and save progress
#######################################
complete_step() {
    ((CURRENT_STEP++))
    save_progress
}

#######################################
# MAIN LOGIC
#######################################

# 0. Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "Please run this script as root (use sudo)."
    exit 1
fi

echo "=================================================="
echo "🚀 XFCE4 Reset & Reinstall Script for Kali Linux 🚀"
echo "=================================================="
echo "This script will:"
echo "  - Kill the current X session (XFCE4)."
echo "  - Completely remove XFCE4, LightDM, Xorg."
echo "  - Clean up leftover files."
echo "  - Reinstall everything from scratch."
echo "A .track file will keep track of each step."
echo "If all steps finish successfully, the .track file"
echo "will be removed. Otherwise, you can rerun the script"
echo "to resume from the last completed step."
echo "--------------------------------------------------"
echo ""

# Load the last completed step (if any)
load_progress

# STEP 1: Kill XFCE4/X server if needed
if [[ $CURRENT_STEP -lt 1 ]]; then
    echo "Step 1: Kill all XFCE4/X processes."
    if confirm "Do you want to kill the current X session now?"; then
        # Attempt to kill known processes
        echo "Killing XFCE processes..."
        pkill xfce4-session
        pkill xfwm4
        pkill xfdesktop
        pkill Xorg
        # Alternatively, you could use: systemctl isolate multi-user.target
        echo "✅ XFCE4/X processes should now be terminated."
    else
        echo "Skipping kill step. (If XFCE is still running, removal can fail.)"
    fi
    complete_step
fi

# STEP 2: Stop and disable LightDM
if [[ $CURRENT_STEP -lt 2 ]]; then
    echo "Step 2: Stop and disable LightDM."
    if confirm "Stop and disable LightDM display manager?"; then
        systemctl stop lightdm
        systemctl disable lightdm
        echo "✅ LightDM stopped and disabled."
    else
        echo "Skipping LightDM stop/disable."
    fi
    complete_step
fi

# STEP 3: Remove XFCE4, LightDM, Xorg
if [[ $CURRENT_STEP -lt 3 ]]; then
    echo "Step 3: Purge XFCE4, LightDM, and Xorg."
    if confirm "Remove XFCE4, LightDM, and Xorg completely?"; then
        apt purge --autoremove -y kali-desktop-xfce xfce4 xfce4-* lightdm lightdm-* xserver-xorg xserver-xorg-* x11-common
        echo "✅ XFCE4, LightDM, and Xorg removed."
    else
        echo "Skipping purge step."
        echo "Note: If you skip this, a clean reinstall may not happen."
    fi
    complete_step
fi

# STEP 4: Remove leftover config files
if [[ $CURRENT_STEP -lt 4 ]]; then
    echo "Step 4: Clean up leftover configuration files."
    if confirm "Remove leftover XFCE and LightDM config files?"; then
        rm -rf ~/.config/xfce4 ~/.cache/xfce4 ~/.local/share/xfce4
        rm -rf /etc/xdg/xfce4 /usr/share/xfce4 /var/lib/lightdm
        echo "✅ Configuration files removed."
    else
        echo "Skipping config cleanup."
    fi
    complete_step
fi

# STEP 5: Update APT package lists
if [[ $CURRENT_STEP -lt 5 ]]; then
    echo "Step 5: Update package lists (apt update)."
    if confirm "Proceed with apt update?"; then
        apt update
        echo "✅ Package lists updated."
    else
        echo "Skipping apt update."
    fi
    complete_step
fi

# STEP 6: Reinstall XFCE4 and Xorg
if [[ $CURRENT_STEP -lt 6 ]]; then
    echo "Step 6: Reinstall XFCE4, Xorg, LightDM."
    if confirm "Install kali-desktop-xfce, xorg, x11-xserver-utils, lightdm?"; then
        apt install -y kali-desktop-xfce xorg x11-xserver-utils lightdm
        echo "✅ XFCE4, Xorg, and LightDM installed."
    else
        echo "Skipping XFCE4 reinstallation."
    fi
    complete_step
fi

# STEP 7: Reconfigure LightDM
if [[ $CURRENT_STEP -lt 7 ]]; then
    echo "Step 7: Set LightDM as default display manager."
    if confirm "Run dpkg-reconfigure lightdm?"; then
        dpkg-reconfigure lightdm
        echo "✅ LightDM reconfigured."
    else
        echo "Skipping LightDM reconfiguration."
    fi
    complete_step
fi

# STEP 8: Offer Reboot
if [[ $CURRENT_STEP -lt 8 ]]; then
    echo "Step 8: Reboot the system (recommended)."
    if confirm "Reboot now to apply all changes?"; then
        complete_step
        echo "All steps completed successfully!"
        # Remove the tracking file (clean slate)
        rm -f "$TRACK_FILE"
        echo "Rebooting in 5 seconds..."
        sleep 5
        reboot
        exit 0
    else
        echo "Skipping reboot. You should reboot manually."
        complete_step
    fi
fi

# If we've reached here without reboot, check if all steps are done
if [[ $CURRENT_STEP -ge 8 ]]; then
    echo "All steps completed successfully (no reboot chosen)."
    # Remove the tracking file (clean slate)
    rm -f "$TRACK_FILE"
fi

echo "✅ Script completed. You may need to reboot to finalize changes."
exit 0
