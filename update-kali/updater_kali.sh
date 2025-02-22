#!/bin/bash
# filepath: /Users/cybernode/Downloads/updater_kali.sh
#
# Kali Linux Comprehensive Update Script – Enhanced Version
#
# This script performs the following actions:
# 1. Updates and upgrades packages.
# 2. Performs a distribution upgrade.
# 3. Removes unnecessary packages.
# 4. Cleans obsolete packages.
# 5. Clears the package cache.
# 6. Reconfigures partially installed packages.
# 7. Fixes broken dependencies.
#
# Enhancements:
# - Each step is tracked in a dynamic .tracker file (named after the script) so that it resumes after a reboot.
# - Each step prompts for a confirmation: proceed, skip, or reboot. (The last step offers only proceed or reboot.)
# - The script accepts the -yall option to run all steps automatically and installs an @reboot crontab entry.
# - After all steps finish, the tracker and the crontab auto‑run entry are removed.
#
# Usage:
#   sudo ./updater_kali.sh [-yall]
#
# Author:
#   (c) 2025 @drgfragkos
#

# Determine the directory where the script resides and its basename
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_PATH="$(realpath "$0")"
SCRIPT_BASENAME="$(basename "$0")"

# Tracker file is named based on the script name so it remains unique irrespective of renaming.
TRACKER_FILE="${SCRIPT_DIR}/.${SCRIPT_BASENAME}.tracker"

# Define steps
STEPS=(
  "sudo apt update && sudo apt upgrade -y"
  "sudo apt dist-upgrade -y"
  "sudo apt autoremove -y"
  "sudo apt autoclean -y"
  "sudo apt clean"
  "sudo dpkg --configure -a"
  "sudo apt install -f"
)
DESCRIPTIONS=(
  "Update package lists & upgrade packages"
  "Distribution upgrade"
  "Autoremove unnecessary packages"
  "Autoclean obsolete packages"
  "Clear package cache"
  "Reconfigure partially installed packages"
  "Fix broken dependencies"
)
TOTAL_STEPS=${#STEPS[@]}

# Process parameters
AUTO_MODE=0
if [[ "$1" == "-yall" ]]; then
    AUTO_MODE=1
fi

# Function to add an @reboot entry to the user's crontab (only when in AUTO_MODE)
add_reboot_cron() {
    # Check if the entry already exists 
    crontab -l 2>/dev/null | grep -q "$SCRIPT_PATH -yall" && return
    # Append our @reboot entry to the crontab
    (crontab -l 2>/dev/null; echo "@reboot sleep 10 && $SCRIPT_PATH -yall") | crontab -
}

# Function to remove our @reboot entry from the user's crontab
remove_reboot_cron() {
    local temp_cron
    temp_cron=$(crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH -yall")
    echo "$temp_cron" | crontab -
}

# In AUTO_MODE, ensure the script runs automatically after reboot
if [[ $AUTO_MODE -eq 1 ]]; then
    add_reboot_cron
fi

# Determine current step from tracker file
current_step=0
if [[ -f "$TRACKER_FILE" ]]; then
    current_step=$(cat "$TRACKER_FILE")
fi
# If tracker value is greater than or equal to TOTAL_STEPS, restart from the beginning.
if [[ $current_step -ge $TOTAL_STEPS ]]; then
    current_step=0
fi

# Function to prompt the user and return the choice.
prompt_choice() {
    local prompt_text="$1"
    local valid=0
    local choice
    while [[ $valid -eq 0 ]]; do
        read -rp "$prompt_text " choice
        case "$choice" in
            [Pp]*)
                echo "proceed"
                valid=1
                ;;
            [Ss]*)
                echo "skip"
                valid=1
                ;;
            [Rr]*)
                echo "reboot"
                valid=1
                ;;
            *)
                echo "Invalid input. Please enter (P)roceed, (S)kip, or (R)eboot."
                ;;
        esac
    done
}

# Iterate over steps starting at current_step
i=$current_step
while [ $i -lt $TOTAL_STEPS ]; do
    step_desc="${DESCRIPTIONS[$i]}"
    step_cmd="${STEPS[$i]}"
    echo "=============================="
    echo "Step $(($i+1)) of $TOTAL_STEPS: $step_desc"
    echo "Command: $step_cmd"
    echo "=============================="

    if [[ $AUTO_MODE -eq 0 ]]; then
        if [[ $i -eq $(($TOTAL_STEPS - 1)) ]]; then
            # For the last step allow only proceed or reboot.
            read -rp "Do you want to (P)roceed or (R)eboot? " choice
            case "$choice" in
                [Rr]*)
                    echo "Rebooting now. Resume this script after login."
                    echo $i > "$TRACKER_FILE"
                    exit 0
                    ;;
                *)
                    echo "Proceeding with step."
                    ;;
            esac
        else
            user_choice=$(prompt_choice "Choose: (P)roceed, (S)kip, or (R)eboot?")
            if [[ "$user_choice" == "reboot" ]]; then
                echo "Rebooting now. Resume this script after login."
                echo $i > "$TRACKER_FILE"
                exit 0
            elif [[ "$user_choice" == "skip" ]]; then
                echo "Skipping step $(($i+1))..."
                i=$((i+1))
                echo $i > "$TRACKER_FILE"
                continue
            fi
        fi
    else
        echo "AUTO_MODE: proceeding with step."
    fi

    # Execute the command
    echo "Executing: $step_cmd"
    eval "$step_cmd"
    if [[ $? -ne 0 ]]; then
        echo "Command failed at step $(($i+1)). Exiting. You can re-run the script to try again from this step."
        exit 1
    fi

    # Update tracker file with next step
    i=$((i+1))
    echo $i > "$TRACKER_FILE"

    if [[ $AUTO_MODE -eq 0 ]]; then
        if [[ $i -lt $TOTAL_STEPS ]]; then
            read -rp "Step complete. (C)ontinue, (S)kip next step, or (R)eboot? " ans
            case "$ans" in
                [Rr]*)
                    echo "Rebooting now. Resume with step $(($i))."
                    exit 0
                    ;;
                [Ss]*)
                    echo "Skipping step $(($i+1))."
                    i=$((i+1))
                    echo $i > "$TRACKER_FILE"
                    ;;
                *)
                    echo "Continuing..."
                    ;;
            esac
        else
            # Last step
            read -rp "Final step complete. (R)eboot to finish the process: " ans_final
            if [[ "$ans_final" =~ ^[Rr] ]]; then
                echo "Rebooting now."
                rm -f "$TRACKER_FILE"
                remove_reboot_cron
                exit 0
            fi
        fi
    fi
done

# All steps finished
echo "All steps completed successfully."
rm -f "$TRACKER_FILE"
remove_reboot_cron
exit 0