#!/usr/bin/env bash
#
# -----------------------------------------------------------------------------
#  Name:         timezone_ntp_setup.sh
#  Description:  A script to assist users in setting the correct time zone
#                and enabling NTP services on Kali/Debian-based systems
#                (including Raspberry Pi). It supports both interactive mode
#                and automated mode via CLI flags.
#
#  Features:
#    1. Interactive:
#       - Confirm or update the time zone
#       - Choose an NTP solution to install/enable (A/B/C), or q to quit
#       - Optional reboot
#    2. Automated (non-interactive) via flags:
#       - -tz <valid_timezone>  : Automatically sets the given timezone
#       - -ntp <A|B|C>          : Automatically installs/enables the chosen NTP
#       - Both flags can be used together for a fully automated run
#
#  Usage:
#    1) Interactive:
#       sudo ./timezone_ntp_setup.sh
#    2) Automated with flags:
#       sudo ./timezone_ntp_setup.sh -tz "Asia/Dubai" -ntp C
#
#  Examples:
#       ./timezone_ntp_setup.sh
#       bash timezone_ntp_setup.sh
#       sudo ./timezone_ntp_setup.sh -tz "America/New_York"
#       sudo ./timezone_ntp_setup.sh -ntp A
#       sudo ./timezone_ntp_setup.sh -tz "Asia/Dubai" -ntp C
#
#  Author:
#       (c) 2025 @drgfragkos
#
# -----------------------------------------------------------------------------

# Exit on error
set -e

################################################################################
#  GLOBALS
################################################################################

# Flags for automated mode
AUTO_TIMEZONE=""
AUTO_NTP_CHOICE=""

# Will set to 1 if any operation suggests a reboot is recommended
RESTART_RECOMMENDED=0

################################################################################
#  FUNCTIONS
################################################################################

usage() {
  cat <<EOF
Usage: sudo $0 [OPTIONS]

Options:
  -tz <timezone>      Set the system timezone automatically (e.g. "Asia/Dubai")
  -ntp <A|B|C>        Install and enable the specified NTP solution:
                       A = systemd-timesyncd (recommended)
                       B = classic ntp
                       C = chrony
  -h, --help          Show this help message and exit

Examples:
  Interactive:
    sudo $0
  Automated:
    sudo $0 -tz "America/New_York" -ntp A
EOF
}

# --------------------------------------------------------------------
# Check if we are root
# --------------------------------------------------------------------
check_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "ERROR: This script must be run as root."
    echo "Please re-run with 'sudo' or switch to the root user."
    exit 1
  fi
}

# --------------------------------------------------------------------
# Parse command line arguments
# --------------------------------------------------------------------
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -tz)
        shift
        if [[ -z "$1" ]]; then
          echo "ERROR: Missing argument for -tz."
          exit 1
        fi
        AUTO_TIMEZONE="$1"
        shift
        ;;
      -ntp)
        shift
        if [[ -z "$1" ]]; then
          echo "ERROR: Missing argument for -ntp."
          exit 1
        fi
        AUTO_NTP_CHOICE="$1"
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "ERROR: Unrecognized option: $1"
        usage
        exit 1
        ;;
    esac
  done
}

# --------------------------------------------------------------------
# Validate that a timezone is recognized by timedatectl
# Returns 0 if valid, 1 if invalid
# --------------------------------------------------------------------
is_valid_timezone() {
  local tz="$1"
  timedatectl list-timezones | grep -qx "$tz"
}

# --------------------------------------------------------------------
# Update GNOME Time and Date settings for timezone (if available)
# --------------------------------------------------------------------
update_clock_settings_timezone() {
  if command -v gsettings >/dev/null 2>&1; then
    echo "Updating clock settings timezone to: $1"
    gsettings set org.gnome.desktop.datetime timezone "$1" 2>/dev/null || true
  fi
}

# --------------------------------------------------------------------
# Update GNOME Time and Date settings to use automatic NTP sync (if available)
# --------------------------------------------------------------------
update_clock_settings_ntp() {
  if command -v gsettings >/dev/null 2>&1; then
    echo "Updating clock settings: enabling automatic time synchronization"
    gsettings set org.gnome.desktop.datetime automatic-clock-synchronization true 2>/dev/null || true
  fi
}

# --------------------------------------------------------------------
# Set system timezone
# --------------------------------------------------------------------
set_timezone() {
  local tz="$1"
  echo "Setting system timezone to: $tz"
  timedatectl set-timezone "$tz"
  update_clock_settings_timezone "$tz"  # Ensure GUI reflects the new timezone
  echo "New system time: $(date)"
}

# --------------------------------------------------------------------
# Install and enable systemd-timesyncd
# --------------------------------------------------------------------
install_timesyncd() {
  echo "Installing and enabling systemd-timesyncd..."
  apt-get update
  apt-get install -y systemd
  systemctl enable systemd-timesyncd
  systemctl start systemd-timesyncd
  # Update system settings to reflect NTP is enabled
  timedatectl set-ntp true
  update_clock_settings_ntp
  echo "systemd-timesyncd is now enabled."
  echo
}

# --------------------------------------------------------------------
# Install and enable classic ntp
# --------------------------------------------------------------------
install_ntp() {
  echo "Installing and enabling classic ntp..."
  apt-get update
  apt-get install -y ntp
  systemctl enable ntp
  systemctl start ntp
  # Although classic ntp runs as a separate service, update clock settings for consistency
  timedatectl set-ntp true
  update_clock_settings_ntp
  echo "ntp service is now enabled."
  echo
}

# --------------------------------------------------------------------
# Install and enable chrony
# --------------------------------------------------------------------
install_chrony() {
  echo "Installing and enabling chrony..."
  apt-get update
  apt-get install -y chrony
  systemctl enable chrony
  systemctl start chrony
  # Update clock settings to reflect automatic NTP sync
  timedatectl set-ntp true
  update_clock_settings_ntp
  echo "chrony is now enabled."
  echo
}

# --------------------------------------------------------------------
# Offer interactive NTP choice (A/B/C/q)
# --------------------------------------------------------------------
interactive_ntp() {
  read -rp "Would you like to install and enable NTP for automatic time sync? (y/n): " install_ntp_flag
  if [[ "${install_ntp_flag,,}" == "y" || "${install_ntp_flag,,}" == "yes" ]]; then
    echo
    echo "Which NTP solution would you like to use?"
    echo
    echo "  A) systemd-timesyncd (Recommended for simplicity)"
    echo "       - Pros: Built-in, simple to set up, minimal configuration needed."
    echo "       - Cons: Fewer advanced configuration options."
    echo
    echo "  B) Classic NTP"
    echo "       - Pros: Mature, highly configurable."
    echo "       - Cons: Heavier than some alternatives, older approach."
    echo
    echo "  C) Chrony"
    echo "       - Pros: Robust, lightweight, and flexible. Handles network changes well."
    echo "       - Cons: Might require additional configuration for advanced use-cases."
    echo
    echo "  q) Quit (no changes to NTP)"
    echo

    read -rp "Enter your choice (A/B/C/q): " ntp_choice
    echo

    # If user chooses to quit
    if [[ "${ntp_choice,,}" == "q" ]]; then
      echo "Quitting NTP setup. No NTP changes applied."
      return
    fi

    # Turn off any existing time-sync to avoid conflict
    timedatectl set-ntp off || true

    case "${ntp_choice^^}" in
      A)
        install_timesyncd
        ;;
      B)
        install_ntp
        ;;
      C)
        install_chrony
        ;;
      *)
        echo "ERROR: Invalid choice. No action taken."
        exit 1
        ;;
    esac
  else
    echo "Skipping NTP installation. You can install it later if needed."
    echo
  fi
}

# --------------------------------------------------------------------
# Automated NTP setup
# --------------------------------------------------------------------
automated_ntp() {
  local choice="$1"

  echo "Automated NTP setup: choice = $choice"
  echo

  # Turn off any existing time-sync to avoid conflict
  timedatectl set-ntp off || true

  case "${choice^^}" in
    A)
      install_timesyncd
      ;;
    B)
      install_ntp
      ;;
    C)
      install_chrony
      ;;
    *)
      echo "ERROR: Invalid -ntp value: $choice"
      echo "Accepted values are A, B, or C."
      RESTART_RECOMMENDED=1
      return 1
      ;;
  esac

  return 0
}

################################################################################
#  MAIN SCRIPT
################################################################################

check_root
parse_args "$@"
clear

echo "========================================"
echo " Timezone and NTP Setup Script"
echo "========================================"
echo

# 1) TIMEZONE SETUP
if [[ -n "$AUTO_TIMEZONE" ]]; then
  echo "Automated mode: Setting timezone to '$AUTO_TIMEZONE'"
  if is_valid_timezone "$AUTO_TIMEZONE"; then
    set_timezone "$AUTO_TIMEZONE"
  else
    echo "ERROR: '$AUTO_TIMEZONE' is not a valid timezone."
    echo "Skipping timezone update. You may set it manually."
    RESTART_RECOMMENDED=1
  fi
  echo
else
  # Interactive timezone
  interactive_timezone() {
    local current_tz
    current_tz=$(timedatectl show --property=Timezone --value)
    echo "Current system timezone is: $current_tz"
    echo
    read -rp "Is this timezone correct? (y/n): " tz_correct

    if [[ "${tz_correct,,}" == "n" || "${tz_correct,,}" == "no" ]]; then
      echo
      echo "Available timezones:"
      echo "--------------------"
      mapfile -t TIMEZONES < <(timedatectl list-timezones)
      i=1
      for ZONE in "${TIMEZONES[@]}"; do
        echo "$i) $ZONE"
        ((i++))
      done
      echo
      read -rp "Enter the number corresponding to your desired timezone: " zone_choice
      if ! [[ "$zone_choice" =~ ^[0-9]+$ ]] || (( zone_choice < 1 || zone_choice > ${#TIMEZONES[@]} )); then
        echo "ERROR: Invalid choice. Exiting..."
        exit 1
      fi
      local new_tz="${TIMEZONES[$((zone_choice-1))]}"
      set_timezone "$new_tz"
      echo
    else
      echo "Keeping existing timezone: $current_tz"
      echo
    fi
  }
  interactive_timezone
fi

# 2) NTP SETUP
if [[ -n "$AUTO_NTP_CHOICE" ]]; then
  echo "Automated mode: Installing/Enabling NTP choice '$AUTO_NTP_CHOICE'"
  if ! automated_ntp "$AUTO_NTP_CHOICE"; then
    echo "There was an error installing/enabling NTP with option '$AUTO_NTP_CHOICE'."
    echo "You may need to fix this manually or choose a different NTP solution."
  fi
else
  interactive_ntp
fi

# 3) (Optional) Reboot
if [[ -z "$AUTO_TIMEZONE" || -z "$AUTO_NTP_CHOICE" ]]; then
  echo
  read -rp "Would you like to reboot the system now? (y/n): " reboot_now
  if [[ "${reboot_now,,}" == "y" || "${reboot_now,,}" == "yes" ]]; then
    echo "Rebooting now..."
    reboot
  else
    echo "Reboot skipped. Please reboot manually if necessary."
    echo "Script completed."
  fi
else
  echo
  if [[ "$RESTART_RECOMMENDED" -eq 1 ]]; then
    echo "WARNING: Issues were detected. A reboot is recommended."
  else
    echo "Automated script completed. No reboot necessary."
  fi
fi