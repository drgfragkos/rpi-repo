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
# After the XFCE reinstall steps (1–9), the script has additional steps
# (10–17) to troubleshoot login-loop issues (e.g., .Xauthority fixes,
# resetting home directory permissions, checking logs, optionally creating
# a new user, etc.). These steps will run after reboot if you re-run the script.
#
# The script tracks progress in 'xfce_reset.track' so if you reboot or exit
# the script halfway, it can continue from where it left off.
#
# USAGE:
#   1) Switch to a TTY (e.g., Ctrl+Alt+F3), log in.
#   2) Make this script executable:
#        chmod +x reset-xfce.sh
#   3) Run as root:
#        sudo ./reset-xfce.sh
#
# Keep an eye on the console prompts. You can skip any step, but that might
# cause an incomplete reinstall or partial troubleshooting.
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
TARGET_USER=""                  # Username to fix (for login loop steps)

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
# save_progress: Save current step and other vars to TRACK_FILE
#######################################
save_progress() {
    {
      echo "CURRENT_STEP=$CURRENT_STEP"
      echo "TARGET_USER=$TARGET_USER"
    } > "$TRACK_FILE"
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
echo ""
echo "After step 9, it includes post-reboot steps to fix common"
echo "login loop issues if needed (steps 10–17)."
echo "--------------------------------------------------"
echo ""

# Load progress from the track file
load_progress

###############################################################################
#                             PHASE 1: XFCE RESET                             #
###############################################################################
# Steps 1 through 9 handle removing and reinstalling XFCE, LightDM, and Xorg.

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
    if confirm "Purge XFCE4, LightDM, Xorg, and any other DMs (GDM3, SDDM, etc.)?"; then
        apt purge --autoremove -y \
            kali-desktop-xfce \
            xfce4 \
            xfce4-* \
            lightdm \
            lightdm-* \
            gdm3 \
            sddm \
            xserver-xorg \
            xserver-xorg-* \
            x11-common
        echo "✅ XFCE4, LightDM, Xorg, and other DMs removed."
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
        LIGHTDM_CONF="/etc/lightdm/lightdm.conf"
        if [[ -f "$LIGHTDM_CONF" ]]; then
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
        echo "All Phase-1 steps (XFCE reset) completed!"
        echo "Rebooting in 5 seconds..."
        sleep 5
        reboot
        exit 0
    else
        echo "Skipping reboot. You can reboot manually."
        complete_step
    fi
fi

###############################################################################
#                          PHASE 2: LOGIN LOOP FIXES                          #
###############################################################################
# Steps 10 onwards help fix common login loop issues (post-reboot).

# STEP 10: Ask for username to fix
if [[ $CURRENT_STEP -lt 10 ]]; then
    echo "STEP 10: Identify the username experiencing the login loop."
    if confirm "Do you want to proceed with login loop fixes?"; then
        while [[ -z "$TARGET_USER" ]]; do
            read -rp "Enter the username to fix (or 'root' if that's the case): " user_input
            if id "$user_input" &>/dev/null; then
                TARGET_USER="$user_input"
            else
                echo "User '$user_input' does not exist. Please try again."
            fi
        done
        echo "Target username set to: $TARGET_USER"
        save_progress
    else
        echo "Skipping login loop fixes."
    fi
    complete_step
fi

# Reload updated variables from track file in case user input was saved
source "$TRACK_FILE"

# STEP 11: Check disk space
if [[ $CURRENT_STEP -lt 11 ]]; then
    echo "STEP 11: Check disk space usage."
    if confirm "Do you want to check your disk space usage now?"; then
        df -h
        echo "If any partition is at 100%, free space before continuing!"
    else
        echo "Skipping disk space check."
    fi
    complete_step
fi

# STEP 12: Fix ~/.Xauthority
if [[ $CURRENT_STEP -lt 12 ]]; then
    echo "STEP 12: Fix ownership/permissions of ~/.Xauthority."
    if confirm "Fix ~/.Xauthority for user '$TARGET_USER'?"; then
        if [[ -f "/home/$TARGET_USER/.Xauthority" ]]; then
            chown "$TARGET_USER:$TARGET_USER" "/home/$TARGET_USER/.Xauthority" || true
            chmod 600 "/home/$TARGET_USER/.Xauthority" || true
            echo "✅ Fixed ~/.Xauthority ownership and permissions."
        else
            echo "⚠️  /home/$TARGET_USER/.Xauthority not found."
        fi
    else
        echo "Skipping .Xauthority fix."
    fi
    complete_step
fi

# STEP 13: Reset user home directory permissions
if [[ $CURRENT_STEP -lt 13 ]]; then
    echo "STEP 13: Reset user home directory permissions."
    if confirm "Reset /home/$TARGET_USER to 755 and correct ownership?"; then
        chown -R "$TARGET_USER:$TARGET_USER" "/home/$TARGET_USER"
        chmod -R 755 "/home/$TARGET_USER"
        echo "✅ Reset permissions for /home/$TARGET_USER."
    else
        echo "Skipping home directory permission reset."
    fi
    complete_step
fi

# STEP 14: Check Xorg errors
if [[ $CURRENT_STEP -lt 14 ]]; then
    echo "STEP 14: Check for Xorg errors in system logs."
    if confirm "Show Xorg-related logs?"; then
        echo "===== journalctl -xe | grep -i xorg ====="
        journalctl -xe | grep -i xorg || echo "No Xorg errors found in journal."
        echo "========================================="
        if [[ -f "/home/$TARGET_USER/.xsession-errors" ]]; then
            echo "===== /home/$TARGET_USER/.xsession-errors ====="
            cat "/home/$TARGET_USER/.xsession-errors"
            echo "==============================================="
        else
            echo "No ~/.xsession-errors file found for $TARGET_USER."
        fi
    else
        echo "Skipping Xorg error checks."
    fi
    complete_step
fi

# STEP 15: Check Display Manager Logs
if [[ $CURRENT_STEP -lt 15 ]]; then
    echo "STEP 15: Check Display Manager logs."
    if confirm "Show logs for LightDM, GDM, or SDDM?"; then
        echo "===== Checking LightDM logs ====="
        journalctl -xe | grep -i lightdm || echo "No LightDM logs found."
        echo "===== Checking GDM logs ====="
        journalctl -xe | grep -i gdm || echo "No GDM logs found."
        echo "===== Checking SDDM logs ====="
        journalctl -xe | grep -i sddm || echo "No SDDM logs found."
    else
        echo "Skipping display manager log checks."
    fi
    complete_step
fi

# STEP 16: (Optional) Reinstall Display Manager
if [[ $CURRENT_STEP -lt 16 ]]; then
    echo "STEP 16: (Optional) Reinstall/verify Display Manager."
    echo "Current DM is LightDM (likely), but you can install others."
    if confirm "Would you like to reinstall or switch display manager?"; then
        echo "Pick a display manager to install/reinstall:"
        echo "1) gdm3 (GNOME)"
        echo "2) lightdm (LightDM)"
        echo "3) sddm (KDE Plasma)"
        echo "4) Skip"
        read -rp "Enter choice [1-4]: " dm_choice
        case "$dm_choice" in
            1)
                echo "Reinstalling gdm3..."
                apt update && apt install --reinstall -y gdm3
                dpkg-reconfigure gdm3
                ;;
            2)
                echo "Reinstalling lightdm..."
                apt update && apt install --reinstall -y lightdm
                dpkg-reconfigure lightdm
                ;;
            3)
                echo "Reinstalling sddm..."
                apt update && apt install --reinstall -y sddm
                dpkg-reconfigure sddm
                ;;
            4)
                echo "Skipping display manager reinstall."
                ;;
            *)
                echo "Invalid choice. Skipping DM reinstall."
                ;;
        esac
    else
        echo "Skipping display manager reinstall."
    fi
    complete_step
fi

# STEP 17: (Optional) Create a new user as a last solution
if [[ $CURRENT_STEP -lt 17 ]]; then
    echo "STEP 17: (Optional) Create a new user if all else fails."
    echo "If the login loop persists, you can test with a fresh user."
    if confirm "Do you want to create a new user now? (last resort)"; then
        while true; do
            read -rp "Enter the new username (or leave empty to skip): " NEW_USER
            if [[ -z "$NEW_USER" ]]; then
                echo "Skipping new user creation."
                break
            fi
            if id "$NEW_USER" &>/dev/null; then
                echo "User '$NEW_USER' already exists. Try another username or press Enter to skip."
            else
                echo "Creating new user: $NEW_USER"
                adduser "$NEW_USER"
                usermod -aG sudo "$NEW_USER"
                echo "✅ User '$NEW_USER' created and added to sudo group."
                echo "You can now try logging in as '$NEW_USER'."
                break
            fi
        done
    else
        echo "Skipping new user creation."
    fi
    complete_step
fi

# After step 17, we've completed all post-reboot login loop checks.

echo "=================================================="
echo "✅ All available steps have been completed or skipped."
echo "If you'd like to repeat any step, remove or edit $TRACK_FILE."
echo ""
echo "A final reboot is often helpful. You can do it now or later."
echo "=================================================="

exit 0
