<#
.SYNOPSIS
Bulk Recovery Email Updater for Google Workspace using GAM.
.VERSION
1.0.0 (March 2026)
.AUTHOR
Created by Kjell @ beIT (https://be-it.no)
Professional IT support and automation solutions.
.LINK
https://github.com/kjellvez/gamrec-update

.INSTRUCTIONS
1. Edit the "CONFIGURATION" block below with your domain and GAM path.
2. Ensure $DryRun is set to $true for your first run.
3. Run the script. It will generate an 'all_users.csv' and two log files in your working directory.
4. Review the logs. Once you are happy with the simulated results, change $DryRun to $false and run it again to apply the actual changes.
#>

# ======================================================================
# ⚙️ CONFIGURATION - EDIT THESE SETTINGS BEFORE RUNNING
# ======================================================================

$DryRun  = $true                  # Change to $false ONLY when ready to apply changes!
$Domain  = "@yourdomain.com"      # Your primary Workspace domain (e.g., "@company.com")
$GamPath = "C:\GAM7\gam.exe"       # The full path to your gam.exe installation
$WorkDir = "C:\GAMWork"  # Folder where logs and the CSV will be saved

# ======================================================================
# 🚀 SCRIPT LOGIC STARTS HERE (No need to edit below this line)
# ======================================================================

if (!(Test-Path -Path $WorkDir)) { New-Item -ItemType Directory -Path $WorkDir | Out-Null }

$csvFile    = "$WorkDir\all_users.csv"
$successLog = "$WorkDir\SetRecoveryEmail_Success.log"
$issueLog   = "$WorkDir\SetRecoveryEmail_Issues.log"
$timestamp  = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$runType    = if ($DryRun) { "DRY RUN" } else { "LIVE UPDATE" }

Add-Content -Path $successLog -Value "--- $runType starting $timestamp ---"
Add-Content -Path $issueLog -Value "--- $runType starting $timestamp ---"

Write-Host "1. Downloading user data in CSV format from Google Workspace..." -ForegroundColor Cyan
cmd.exe /c "$GamPath print users fields recoveryemail,emails > $csvFile"

Write-Host "2. Processing users and applying logic ($runType)..." -ForegroundColor Cyan

$users = Import-Csv -Path $csvFile

foreach ($row in $users) {
    $primary = $row.primaryEmail
    $recovery = $row.recoveryEmail

    # Skip if user already has a recovery email or row is invalid
    if (-not [string]::IsNullOrWhiteSpace($recovery) -or [string]::IsNullOrWhiteSpace($primary)) { continue }

    $external = $null

    # Search all dynamically generated GAM columns for secondary emails
    foreach ($property in $row.PSObject.Properties) {
        if ($property.Name -like "emails.*.address") {
            $val = $property.Value
            if (-not [string]::IsNullOrWhiteSpace($val) -and $val -ne $primary -and $val -notlike "*$Domain") {
                $external = $val
                break
            }
        }
    }

    if ($external) {
        if ($DryRun) {
            Write-Host "-> [DRY RUN - WOULD UPDATE] $primary -> $external" -ForegroundColor Green
            Add-Content -Path $successLog -Value "[DRY RUN - WOULD UPDATE] $primary -> $external"
        } else {
            Write-Host "-> [UPDATING] $primary -> $external" -ForegroundColor Green
            $output = & $GamPath update user $primary recoveryemail $external 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Add-Content -Path $successLog -Value "[SUCCESS] $primary -> $external"
            } else {
                Write-Host "-> ERROR updating $primary" -ForegroundColor Red
                Add-Content -Path $issueLog -Value "[FAILED UPDATE] $primary -> Tried setting $external. Error: $output"
            }
        }
    } else {
        Write-Host "-> [MISSING DATA] $primary" -ForegroundColor Yellow
        Add-Content -Path $issueLog -Value "[MISSING DATA] $primary -> No recovery email or external email found."
    }
}

Write-Host "----------------------------------------------------------------"
Write-Host "Run complete! ($runType)"
Write-Host "Check logs in $WorkDir"
