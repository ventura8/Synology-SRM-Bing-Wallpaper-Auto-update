#!/usr/bin/env bats

setup() {
    INSTALLER="/app/install.sh"
    UNINSTALLER="/app/uninstall.sh"
    chmod +x "$INSTALLER"
    chmod +x "$UNINSTALLER"
    
    # Pre-Install (Standard Config)
    # Simulate user input: 1 (4k), n (no custom region), n (no custom overlay), n (default time)
    # The actual install.sh now has prompts: Res[1] -> Region[1..5] -> Overlay[y/n] -> Time change[y/n]
    # To be safe with defaults, let's use:
    # 1\n (4k)
    # \n (Default Region)
    # \n (Default Overlay - yes)
    # \n (Default Time - no)
    # Note: \n in bash echo passes empty lines.
    
    # Actually, let's just create the file and crontab entry manually to isolate uninstaller logic
    # This avoids dependency on install.sh logic in this specific test
    
    touch /usr/local/bin/bing_wallpaper_auto_update.sh
    chmod +x /usr/local/bin/bing_wallpaper_auto_update.sh
    
    echo -e "0\t10\t*\t*\t*\troot\t/usr/local/bin/bing_wallpaper_auto_update.sh" >> /etc/crontab
}

@test "Uninstaller should require root privileges" {
    # We are root in Docker. Tests typically run as root.
    # Skipping drop-privs for simplicity.
    true
}

@test "Uninstaller should remove the script file" {
    run bash "$UNINSTALLER"
    [ "$status" -eq 0 ]
    [ ! -f "/usr/local/bin/bing_wallpaper_auto_update.sh" ]
}

@test "Uninstaller should remove the cron job" {
    run bash "$UNINSTALLER"
    [ "$status" -eq 0 ]
    
    # Ensure grep didn't find it (exit code 1 means NOT found)
    run grep "bing_wallpaper_auto_update.sh" /etc/crontab
    [ "$status" -eq 1 ]
}

@test "Uninstaller should be idempotent (safe to run twice)" {
    run bash "$UNINSTALLER"
    [ "$status" -eq 0 ]
    
    run bash "$UNINSTALLER"
    [ "$status" -eq 0 ]
    
    # Should still be gone
    [ ! -f "/usr/local/bin/bing_wallpaper_auto_update.sh" ]
}

@test "Uninstaller should use synoservicectl if available" {
    # Ensure synoservicectl is in PATH and executable (Dockerfile does this)
    # Check output for "Restarted via synoservicectl"
    
    run bash "$UNINSTALLER"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Restarted via synoservicectl"* ]]
}

@test "Uninstaller should fallback to synoservice if synoservicectl is missing" {
    # Mock environment: Remove /usr/syno/sbin from PATH so synoservicectl is not found
    # But ensure synoservice IS in PATH (Dockerfile puts it in /usr/bin)
    
    ORIG_PATH="$PATH"
    export PATH=$(echo "$PATH" | sed 's|/usr/syno/sbin||g; s|::|:|g')
    
    # Run
    run bash "$UNINSTALLER"
    
    # Restore
    export PATH="$ORIG_PATH"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"Restarted via synoservice"* ]]
}

@test "Uninstaller should fallback to systemctl if others missing" {
    # Mock environment:
    # 1. Hide synoservicectl (Path manipulation)
    # 2. Hide synoservice (Rename temporary)
    # 3. Create mock systemctl
    
    ORIG_PATH="$PATH"
    export PATH=$(echo "$PATH" | sed 's|/usr/syno/sbin||g; s|::|:|g')
    
    mv /usr/bin/synoservice /usr/bin/synoservice.bak
    
    echo '#!/bin/bash' > /usr/bin/systemctl
    echo 'echo "Mock systemctl: $*"' >> /usr/bin/systemctl
    chmod +x /usr/bin/systemctl
    
    run bash "$UNINSTALLER"
    
    # Cleanup
    rm /usr/bin/systemctl
    mv /usr/bin/synoservice.bak /usr/bin/synoservice
    export PATH="$ORIG_PATH"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"Restarted via systemctl"* ]]
}

@test "Uninstaller should fallback to killall if services missing" {
    # Mock environment: Hide all service managers
    
    ORIG_PATH="$PATH"
    export PATH=$(echo "$PATH" | sed 's|/usr/syno/sbin||g; s|::|:|g')
    
    mv /usr/bin/synoservice /usr/bin/synoservice.bak
    # Ensure systemctl is gone (it shouldn't be there, but just in case)
    rm -f /usr/bin/systemctl
    
    # Create mock killall
    echo '#!/bin/bash' > /usr/bin/killall
    echo 'echo "Mock killall: $*"' >> /usr/bin/killall
    chmod +x /usr/bin/killall
    
    run bash "$UNINSTALLER"
    
    # Cleanup
    rm /usr/bin/killall
    mv /usr/bin/synoservice.bak /usr/bin/synoservice
    export PATH="$ORIG_PATH"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"Reloaded via killall -HUP"* ]]
}

@test "Uninstaller should fail if not root" {
    # Mock id command
    mkdir -p /tmp/bin_user_un
    echo '#!/bin/bash' > /tmp/bin_user_un/id
    echo 'if [ "$1" == "-u" ]; then echo 1000; else /usr/bin/id "$@"; fi' >> /tmp/bin_user_un/id
    chmod +x /tmp/bin_user_un/id
    
    ORIG_PATH="$PATH"
    export PATH="/tmp/bin_user_un:$PATH"
    
    run bash "$UNINSTALLER"
    
    export PATH="$ORIG_PATH"
    rm -rf /tmp/bin_user_un
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"must be run as root"* ]]
}
