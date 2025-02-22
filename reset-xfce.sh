#!/bin/bash
#
# -------------------------------------------------------------------------
# reset-xfce.sh
#
# A robust script to remove and reinstall the entire XFCE desktop environment,
# LightDM, and Xorg on Kali Linux. It ensures you are in a text-only mode by
# isolating the system to multi-user.target (non-graphical) and stops any
# services that might restart the GUI automatically.
#
# The script tracks progress in 'xfce_reset.track' so if you reboot or exit
# the script halfway, it can continue from where it left off.
#
# USAGE:
#  1) Switch to a TTY (e.g., Ctrl+Alt+F3), log in.
#  2) Make this script executable:
#       chmod +x reset-xfce.sh
#  3) Run as root:
#       sudo ./reset-xfce.sh
#
# Keep an eye on the console prompts. You can skip any step, but that might
# cause an incomplete reinstall of XFCE4.
#
# Author: 
#   (c) @drgfragkos 2025 
#
# -------------------------------------------------------------------------

#######################################
# CONFIG
#######################################
TRACK_FILE="xfce_reset.track"   # Progress file
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
            [Yy]* ) return 0 ;;   # User chose yes
            [Nn]* ) return 1 ;;   # User chose no
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
        # Ensure CURRENT_STEP is numeric
        if [[ ! "$CURRENT_STEP" =~ ^[0-9]+$ ]]; then
            echo "Warning: $TRACK_FILE is invalid. Resetting progress to 0."
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
# complete_step: Mark a step as completed, save progress
#######################################
complete_step() {
    ((CURRENT_STEP++))
    save_progress
}

#######################################
# MAIN
#######################################

# 0. Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "Please run this script as root (use: sudo ./reset-xfce.sh)."
    exit 1
fi

echo "=================================================="
echo "🚀  XFCE4 Reset & Reinstall Script for Kali Linux 🚀"
echo "=================================================="
echo "This script will:"
echo "  - Isolate the system to multi-user mode (no GUI)."
echo "  - Completely remove XFCE4, LightDM, Xorg packages."
echo "  - Clean up leftover configs."
echo "  - Reinstall XFCE4, LightDM, and Xorg from scratch."
echo "  - (Optionally) configure LightDM to allow root login."
echo "  - Keep track of progress in '$TRACK_FILE'."
echo "If you reboot or exit midway, rerun the script to resume."
echo "--------------------------------------------------"
echo ""

# Load progress from the track file
load_progress

# STEP 1: Isolate multi-user.target (kill GUI entirely)
if [[ $CURRENT_STEP -lt 1 ]]; then
    echo "STEP 1: Move to multi-user.target (non-graphical mode)."
    if confirm "Switch to multi-user.target now? This will kill the GUI (XFCE4/X)."; then
        systemctl isolate multi-user.target
        echo "✅ System is now in multi-user mode. You should be in a TTY (text console)."
    else
        echo "⚠️  Skipping isolation. (The GUI may respawn if not fully stopped.)"
    fi
    complete_step
fi

# STEP 2: Stop & disable LightDM
if [[ $CURRENT_STEP -lt 2 ]]; then
    echo "STEP 2: Stop and disable LightDM service."
    if confirm "Stop and disable LightDM now?"; then
        systemctl stop lightdm 2>/dev/null
        systemctl disable lightdm 2>/dev/null
        echo "✅ LightDM stopped and disabled."
    else
        echo "⚠️  Skipping LightDM stop/disable."
    fi
    complete_step
fi

# STEP 3: Remove XFCE4, LightDM, Xorg
if [[ $CURRENT_STEP -lt 3 ]]; then
    echo "STEP 3: Completely remove XFCE4, LightDM, Xorg."
    if confirm "Purge XFCE4, LightDM, and Xorg packages?"; then
        apt purge --autoremove -y \
            kali-desktop-xfce \
            xfce4 \
            xfce4-* \
            lightdm \
            lightdm-* \
            xserver-xorg \
            xserver-xorg-* \
            x11-common
        echo "✅ XFCE4, LightDM, Xorg removed."
    else
        echo "⚠️  Skipping purge step."
    fi
    complete_step
fi

# STEP 4: Clean leftover config
if [[ $CURRENT_STEP -lt 4 ]]; then
    echo "STEP 4: Clean up leftover config files."
    if confirm "Remove leftover XFCE/LightDM config (in /etc, /usr, and ~)?"; then
        rm -rf ~/.config/xfce4 ~/.cache/xfce4 ~/.local/share/xfce4
        rm -rf /etc/xdg/xfce4 /usr/share/xfce4 /var/lib/lightdm
        echo "✅ Configuration files removed."
    else
        echo "⚠️  Skipping config cleanup."
    fi
    complete_step
fi

# STEP 5: Update package lists
if [[ $CURRENT_STEP -lt 5 ]]; then
    echo "STEP 5: Update package lists (apt update)."
    if confirm "Run apt update now?"; then
        apt update
        echo "✅ Package lists updated."
    else
        echo "⚠️  Skipping apt update."
    fi
    complete_step
fi

# STEP 6: Reinstall XFCE4, LightDM, Xorg
if [[ $CURRENT_STEP -lt 6 ]]; then
    echo "STEP 6: Reinstall XFCE4, LightDM, and Xorg."
    if confirm "Install kali-desktop-xfce, xorg, x11-xserver-utils, lightdm?"; then
        apt install -y kali-desktop-xfce xorg x11-xserver-utils lightdm
        echo "✅ XFCE4, LightDM, and Xorg reinstalled."
    else
        echo "⚠️  Skipping XFCE4 reinstall."
    fi
    complete_step
fi

# STEP 7: Configure LightDM as default DM
if [[ $CURRENT_STEP -lt 7 ]]; then
    echo "STEP 7: Configure LightDM as default display manager."
    if confirm "Run dpkg-reconfigure lightdm?"; then
        dpkg-reconfigure lightdm
        echo "✅ LightDM reconfigured."
    else
        echo "⚠️  Skipping lightdm reconfiguration."
    fi
    complete_step
fi

# STEP 8: Optional - Configure LightDM for root login
if [[ $CURRENT_STEP -lt 8 ]]; then
    echo "STEP 8: (Optional) Allow or verify root login in LightDM."
    echo "By default, Kali may block root logins via LightDM. If you plan"
    echo "to log in with a regular user, you can skip this step."
    if confirm "Do you want to configure LightDM to allow root GUI login?"; then
        # Simple approach: Adjust LightDM config
        # This section might differ across versions. Example:
        LIGHTDM_CONF="/etc/lightdm/lightdm.conf"
        if [[ -f "$LIGHTDM_CONF" ]]; then
            # We’ll try to set root login options. This can vary by distro.
            # We enable manual login and hide user list.
            sed -i 's/^#*\s*greeter-show-manual-login=.*/greeter-show-manual-login=true/' "$LIGHTDM_CONF"
            sed -i 's/^#*\s*greeter-hide-users=.*/greeter-hide-users=false/' "$LIGHTDM_CONF"
            sed -i 's/^#*\s*allow-guest=.*/allow-guest=false/' "$LIGHTDM_CONF"
            echo "✅ LightDM config updated to allow manual logins."
            echo "If you still cannot log in as root, edit /etc/pam.d/lightdm"
            echo "to comment out lines blocking root. But do so at your own risk."
        else
            echo "⚠️  $LIGHTDM_CONF not found. You may need to manually configure it."
        fi
    else
        echo "Skipping root login configuration."
    fi
    complete_step
fi

# STEP 9: Reboot
if [[ $CURRENT_STEP -lt 9 ]]; then
    echo "STEP 9: Reboot the system (recommended)."
    if confirm "Reboot now to apply all changes?"; then
        complete_step
        echo "All steps completed successfully!"
        # Remove track file to allow a fresh run next time
        rm -f "$TRACK_FILE"
        echo "Rebooting in 5 seconds..."
        sleep 5
        reboot
        exit 0
    else
        echo "Skipping reboot. Please reboot manually to finalize changes."
        complete_step
    fi
fi

# If we've reached here without reboot, check if all steps are done
if [[ $CURRENT_STEP -ge 9 ]]; then
    echo "All steps completed successfully (no reboot chosen)."
    rm -f "$TRACK_FILE"
fi

echo "✅ Script completed. A reboot is highly recommended."
exit 0
