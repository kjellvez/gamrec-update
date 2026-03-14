# GAM Bulk Recovery Email Updater

A lightweight, high-speed tool for Google Workspace administrators to automatically populate missing user recovery emails. 

This script pulls all users via [GAM](https://github.com/GAM-team/GAM), checks if they are missing a recovery email, and securely updates their profile using any external secondary email already attached to their account (e.g., a personal alias labeled "home" or "work").

By processing the user data locally (using PowerShell on Windows or an embedded Python script on Linux), this tool can evaluate thousands of users minimizing Google Workspace API call.  It will do an API call if a user is updated, using a PATCH request.

## ⚙️ Prerequisites
1. **GAM 7+ Installed and Authenticated:** You must have GAM installed and authorized with Domain-Wide Delegation in your Google Workspace environment. 
   * [GAM Installation Instructions](https://github.com/GAM-team/GAM/wiki/How-to-Install-GAM7)
2. **Google Admin Privileges:** The account running GAM must have permissions to update user security settings.

## 🚀 How to Use (Linux / Debian / Proxmox)
1. Download `gam_set_recovery_email.sh` to your machine.
2. Open the script in a text editor (like `nano`) and update the **CONFIGURATION** block at the top with your specific domain and paths.
3. Make the script executable:
   ```bash
   chmod +x gam_set_recovery_email.sh
   ```
4. Run the script:
   ```bash
   ./gam_set_recovery_email.sh
   ```

## 🚀 How to Use (Windows 11)
1. Download `GAM_SetRecoveryEmail.ps1`.
2. Right-click the script and select **Edit** to update the **CONFIGURATION** block with your domain and GAM installation path.
3. Right-click the file and select **Run with PowerShell**. 
*(Note: If Windows blocks the script, open PowerShell as Admin and run `Set-ExecutionPolicy RemoteSigned`, then try again).*

## 🛡️ Built-In Safety: Dry Run Mode
By default, both scripts are configured with `DryRun = true` (or `DRY_RUN=true`). 
When you run the script for the first time, it will **NOT** make any changes to Google Workspace. Instead, it will generate simulated log files so you can verify exactly which accounts *would* be updated.

Once you have reviewed the `SetRecoveryEmail_Success.log` and are ready to apply the changes, simply change the `DryRun` variable to `false` inside the script and run it again.
