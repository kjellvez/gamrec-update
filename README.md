# GAM Bulk Recovery Email Updater

A lightweight, high-speed tool for Google Workspace administrators to automatically populate missing user recovery emails. 

This script pulls all users via [GAM](https://github.com/GAM-team/GAM), checks if they are missing a recovery email, and securely updates their profile using any external secondary email already attached to their account (e.g., a personal alias labeled "home" or "work").

By processing the user data locally (using PowerShell on Windows or an embedded Python script on Linux), this tool can evaluate thousands of users while minimizing Google Workspace API call.  It will do an API call if a user is updated, using a PATCH request.

## ⚙️ Prerequisites
1. **GAM 7+ Installed and Authenticated:** You must have GAM installed and authorized with Domain-Wide Delegation in your Google Workspace environment. 
   * [GAM Installation Instructions](https://github.com/GAM-team/GAM/wiki/How-to-Install-GAM7)
2. **Google Admin Privileges:** The account running GAM must have permissions to update user security settings.

## 🚀 How to Use (Linux)
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

## 🚀 How to Use (Windows)
1. Download `GAM_SetRecoveryEmail.ps1`.
2. Right-click the script and select **Edit** to update the **CONFIGURATION** block with your domain and GAM installation path.
3. Right-click the file and select **Run with PowerShell**. 
*(Note: If Windows blocks the script, open PowerShell as Admin and run `Set-ExecutionPolicy RemoteSigned`, then try again).*

## 🛡️ Built-In Safety: Dry Run Mode
By default, both scripts are configured with `DryRun = true` (or `DRY_RUN=true`). 
When you run the script for the first time, it will **NOT** make any changes to Google Workspace. Instead, it will generate simulated log files so you can verify exactly which accounts *would* be updated.

Once you have reviewed the `SetRecoveryEmail_Success.log` and are ready to apply the changes, simply change the `DryRun` variable to `false` inside the script and run it again.

## 📁 Output Files & Logging
When the script runs, it will automatically create a working directory (default: `C:\GAMWork` on Windows or `/root/GAMWork` on Linux) and generate three files:

* `all_users.csv`: A local export of your Workspace directory's current email data. This file remains in the folder and is **overwritten** with fresh data each time you run the script.
* `SetRecoveryEmail_Success.log`: A continuous, running log of every user account that was successfully updated (or *would* be updated in Dry Run mode). New runs are **appended** to the bottom of this file with a timestamped header.
* `SetRecoveryEmail_Issues.log`: A continuous, running log of users who were skipped because they lacked both recovery and valid external email, or accounts that threw an API error. New runs are **appended** to the bottom of this file with a timestamped header.

### How to View the Logs
**On Linux:**
You can quickly read the logs right in your terminal:
* View all successes: `cat /root/GAMWork/SetRecoveryEmail_Success.log`
* Scroll through issues: `less /root/GAMWork/SetRecoveryEmail_Issues.log` (press `q` to quit)
* Search for a specific user: `grep "username" /root/GAMWork/SetRecoveryEmail_Success.log`

**On Windows:**
You can navigate to `C:\GAMWork` in File Explorer and open the `.log` files directly in **Notepad**, or import the `all_users.csv` into **Excel** for easier filtering. Alternatively, view them in PowerShell:
* `Get-Content C:\GAMWork\SetRecoveryEmail_Success.log`

## 🐛 Support & Feedback
If you run into any issues please open an issue on the [GitHub Repository](https://github.com/kjellvez/gamrec-update/issues). 

*Created with ❤️ by [beIT](https://be-it.no).*
