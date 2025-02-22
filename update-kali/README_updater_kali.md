# updater_kali.sh

**Kali Linux Comprehensive Update Script – Enhanced Version**

This script automates the process of updating and maintaining your Kali Linux system in pristine condition. It performs a series of system update tasks, each tracked individually, allowing you to resume after a reboot.

## Features

- **Sequential Steps:**  
  The script is divided into multiple steps:
  1. Update package lists & upgrade packages.
  2. Perform a distribution upgrade.
  3. Remove unnecessary packages.
  4. Clean obsolete packages.
  5. Clear package cache.
  6. Reconfigure partially installed packages.
  7. Fix broken dependencies.

- **Step Tracking:**  
  Each step is recorded in a dynamic `.tracker` file (named based on the script’s filename) so that the script resumes from the correct step after a reboot.

- **User Prompts:**  
  Before executing each step, you are prompted to:
  - **Proceed:** Execute the current step.
  - **Skip:** Skip the current step.
  - **Reboot:** Reboot the system and resume the script upon login.  
  *For the final step, only proceed or reboot options are available.*

- **Automatic Mode (-yall):**  
  When run with the `-yall` option, the script:
  - Automatically executes all steps without prompting for confirmation.
  - Installs an `@reboot` crontab entry so that the script resumes automatically after a reboot (from either GUI or TTY).
  - Removes the tracker and the crontab entry after successful completion.

- **Dynamic Adaptability:**  
  The script checks its own name and current directory at runtime, ensuring that the tracker file and cron job are always correctly configured—even if the file is renamed or moved.

## Usage

Run the script with root privileges. You can run it with or without the auto-confirmation flag.

- **Interactive Mode:**

  ```bash
  sudo ./updater_kali.sh
  ```

- **Automatic Mode:**

  ```bash
  sudo ./updater_kali.sh -yall
  ```

## How It Works

1. **Initialization:**  
   The script determines its own location and filename to create a unique tracker file.
   
2. **Step Execution:**  
   - Reads the current step from the tracker file (if available) or starts from the beginning.
   - Executes each defined update command sequentially.
   - Prompts for user input (unless in auto mode).
   - Updates the tracker file after completing each step.

3. **Reboot Handling:**  
   - If the user chooses to reboot, the script stores the current step and exits.
   - On login, if in auto mode (or rerun interactively), the script resumes from the stored step.

4. **Cleanup:**  
   Upon successful completion of all steps, the tracker file and any automated crontab entries are removed.

## License

(c) 2025 @drgfragkos

## Disclaimer

This script modifies system files and performs system updates. Please review the script and ensure you have proper backups before running it.
