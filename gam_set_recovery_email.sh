#!/bin/bash

# ======================================================================
# INSTRUCTIONS
# 1. Edit the "CONFIGURATION" block below with your domain and GAM path.
# 2. Ensure DRY_RUN is set to true for your first run.
# 3. Run the script. It will generate an 'all_users.csv' and two logs.
# 4. Review the logs. Once happy with the simulated results, change 
#    DRY_RUN to false and run it again to apply the actual changes.
# ======================================================================

# ======================================================================
# ⚙️ CONFIGURATION - EDIT THESE SETTINGS BEFORE RUNNING
# ======================================================================

DRY_RUN=true                     # Set to false ONLY when ready to apply changes!
DOMAIN="@yourdomain.com"         # Your primary Workspace domain (e.g., "@company.com")
GAM_CMD="/root/bin/gam7/gam"     # The full path to your gam executable
WORK_DIR="/root/GAMWork"         # Folder where logs and the CSV will be saved

# ======================================================================
# 🚀 SCRIPT LOGIC STARTS HERE (No need to edit below this line)
# ======================================================================

mkdir -p "$WORK_DIR"

CSV_FILE="$WORK_DIR/all_users.csv"
SUCCESS_LOG="$WORK_DIR/SetRecoveryEmail_Success.log"
ISSUE_LOG="$WORK_DIR/SetRecoveryEmail_Issues.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

if [ "$DRY_RUN" = true ]; then RUN_TYPE="DRY RUN"; else RUN_TYPE="LIVE UPDATE"; fi

echo "--- $RUN_TYPE starting $TIMESTAMP ---" >> "$SUCCESS_LOG"
echo "--- $RUN_TYPE starting $TIMESTAMP ---" >> "$ISSUE_LOG"

echo "1. Downloading user data in CSV format from Google Workspace..."
$GAM_CMD print users fields recoveryemail,emails > "$CSV_FILE"

echo "2. Processing users and applying logic ($RUN_TYPE)..."

# Embedded Python script to safely parse the shifting CSV columns
python3 -c '
import csv, sys
domain = sys.argv[1]
with open(sys.argv[2], mode="r", encoding="utf-8-sig") as f:
    reader = csv.DictReader(f)
    for row in reader:
        primary = row.get("primaryEmail", "")
        recovery = row.get("recoveryEmail", "")
        
        if recovery or not primary:
            continue
            
        external = ""
        for key, val in row.items():
            if key and "emails." in key and "address" in key:
                if val and not val.endswith(domain) and val != primary:
                    external = val
                    break
        
        if external:
            print(f"UPDATE|{primary}|{external}")
        else:
            print(f"MISSING|{primary}")
' "$DOMAIN" "$CSV_FILE" | while IFS='|' read -r action primary external; do

    if [ "$action" = "UPDATE" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "-> [DRY RUN - WOULD UPDATE] $primary -> $external"
            echo "[DRY RUN - WOULD UPDATE] $primary -> $external" >> "$SUCCESS_LOG"
        else
            echo "-> [UPDATING] $primary -> $external"
            UPDATE_OUTPUT=$($GAM_CMD update user "$primary" recoveryemail "$external" 2>&1)
            
            if [ $? -eq 0 ]; then
                echo "[SUCCESS] $primary -> $external" >> "$SUCCESS_LOG"
            else
                echo "-> ERROR updating $primary"
                echo "[FAILED UPDATE] $primary -> Tried setting $external. Error: $UPDATE_OUTPUT" >> "$ISSUE_LOG"
            fi
        fi
        
    elif [ "$action" = "MISSING" ]; then
        echo "-> [MISSING DATA] $primary"
        echo "[MISSING DATA] $primary -> No recovery email or external email found." >> "$ISSUE_LOG"
    fi
done

echo "----------------------------------------------------------------"
echo "Run complete! ($RUN_TYPE)"
echo "Check logs in $WORK_DIR"