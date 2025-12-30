#!/usr/bin/env bats

setup() {
    INSTALLER="/app/install.sh"
    chmod +x "$INSTALLER"

    # Use local path to avoid download failure in tests (simulating Repo checkout)
    export LOCAL_INSTALL_PATH="/app/bing_wallpaper_auto_update.sh"
    
    # Clean state
    rm -f /usr/local/bin/bing_wallpaper_auto_update.sh
    > /etc/crontab
    
    # Mock systemctl (not present in container by default) or rely on Dockerfile mock
    
    # --- Wallpaper Script Mocks (needed for auto-apply) ---
    mkdir -p /tmp/bin
    ECHO_JSON='{"images":[{"startdate":"20251230","fullstartdate":"202512300000","enddate":"20251231","url":"/th?id=OHR.WhooperSwans_EN-US1234.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.WhooperSwans_EN-US1234","copyright":"Whooper swans, Kotoku Pond, Japan (© Martin Bailey/Shutterstock)","copyrightlink":"https://www.bing.com/search?q=Whooper+Swans","title":"Whooper swans, Kotoku Pond, Japan","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20251230_WhooperSwans%22&FORM=HPQUIZ","wp":true,"hsh":"1234567890abcdef","drk":1,"top":1,"bot":1,"hs":[]}]}'
    echo "$ECHO_JSON" > /tmp/mock_response.json

    cat <<EOT | tr -d '\r' > /tmp/bin/wget
#!/bin/bash
if [[ "\$@" == *"HPImageArchive.aspx"* ]]; then
    cat /tmp/mock_response.json
    exit 0
fi
if [[ "\$@" == *"bing_wallpaper_auto_update.sh"* ]]; then
    # Mock script download
    echo "#!/bin/sh" > /tmp/mock_script.sh
    echo "echo 'Mock Script'" >> /tmp/mock_script.sh
    chmod +x /tmp/mock_script.sh
    OUTPUT=""
    while [[ "\$#" -gt 0 ]]; do
        case "\$1" in
            -O|-qO) OUTPUT="\$2"; shift ;;
        esac
        shift
    done
    if [ -n "\$OUTPUT" ] && [ "\$OUTPUT" != "-" ]; then
        cp /tmp/mock_script.sh "\$OUTPUT"
    fi
    exit 0
fi
if [[ "\$@" == *".jpg"* ]]; then
    echo "mock_binary_data" > /tmp/mock_image.jpg
    OUTPUT=""
    while [[ "\$#" -gt 0 ]]; do
        case "\$1" in
            -O|-qO) OUTPUT="\$2"; shift ;;
        esac
        shift
    done
    if [ -n "\$OUTPUT" ] && [ "\$OUTPUT" != "-" ]; then
        cp /tmp/mock_image.jpg "\$OUTPUT"
    elif [ "\$OUTPUT" == "-" ]; then
        cat /tmp/mock_image.jpg
    fi
    exit 0
fi
exit 0
EOT
    chmod +x /tmp/bin/wget
    export PATH="/tmp/bin:$PATH"

    # Mock synoinfo.conf and login background for the wallpaper script
    mkdir -p /etc /usr/syno/etc
    echo 'login_background_customize="no"' > /etc/synoinfo.conf
    # Mock systemctl (not present in container by default) or rely on Dockerfile mock
    

}

teardown() {
    rm -f /usr/local/bin/bing_wallpaper_auto_update.sh
    # Remove mocks
    # rm -f /usr/syno/sbin/synoservicectl  <-- Destructive to global state!
    # rm -f /usr/bin/synoservice           <-- Destructive!
    
    # Restore PATH
    export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
}

# ... (omitted)

@test "Installer should configure custom Region and Overlay (PTY Interactive)" {
    # ...
    
    # Add extra newlines to ensure read loops terminate if they expect more input
    INPUTS=$(printf "1\n5\nja-JP\nn\nn\n\n\n")
    
    # ...
}

@test "Installer should handle invalid interactive inputs (PTY Interactive)" {
    # ...
    
    # Add extra newlines
    INPUTS=$(printf "9\n1\n9\n1\nx\nn\n\n\n")
    
    run run_with_pty "$INPUTS" "bash $INSTALLER"
    # ...
}

@test "Installer should require root privileges" {
    # Mock id command to return non-root
    mkdir -p /tmp/bin_user
    echo '#!/bin/bash' > /tmp/bin_user/id
    echo 'if [ "$1" == "-u" ]; then echo 1000; else /usr/bin/id "$@"; fi' >> /tmp/bin_user/id
    chmod +x /tmp/bin_user/id
    
    export PATH="/tmp/bin_user:$PATH"
    
    run bash "$INSTALLER"
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"must be run as root"* ]]
}

# ... (omitted tests) ...
@test "Installer should fallback service restart (synoservice)" {
    # Mock synoservice
    echo 'echo "Mock synoservice: $*"' > /usr/bin/synoservice
    chmod +x /usr/bin/synoservice
    
    # Rename synoservicectl to trigger fallback
    mv /usr/syno/sbin/synoservicectl /usr/syno/sbin/synoservicectl.bak
    
    run bash -c "yes \"\" | bash $INSTALLER"
    
    mv /usr/syno/sbin/synoservicectl.bak /usr/syno/sbin/synoservicectl
    # rm /usr/bin/synoservice  <-- Destructive to global state, needed by next test
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"Restarted via synoservice"* ]]
}

@test "Installer should fallback service restart (systemctl)" {
    # Rename upper priority services to force fallback
    mv /usr/syno/sbin/synoservicectl /usr/syno/sbin/synoservicectl.bak
    mv /usr/bin/synoservice /usr/bin/synoservice.bak
    
    # Mock systemctl via PATH
    mkdir -p /tmp/bin_systemd
    echo '#!/bin/bash' > /tmp/bin_systemd/systemctl
    echo 'echo "Mock systemctl: $*"' >> /tmp/bin_systemd/systemctl
    chmod +x /tmp/bin_systemd/systemctl
    
    ORIG_PATH="$PATH"
    export PATH="/tmp/bin_systemd:$PATH"
    
    run bash -c "yes \"\" | bash $INSTALLER"
    
    export PATH="$ORIG_PATH"
    rm -rf /tmp/bin_systemd
    
    mv /usr/bin/synoservice.bak /usr/bin/synoservice
    mv /usr/syno/sbin/synoservicectl.bak /usr/syno/sbin/synoservicectl
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"Restarted via systemctl"* ]]
}

@test "Installer should fallback service restart (killall)" {
    mv /usr/syno/sbin/synoservicectl /usr/syno/sbin/synoservicectl.bak
    mv /usr/bin/synoservice /usr/bin/synoservice.bak
    # Mock systemctl MISSING (by PATH priority or just ensuring default PATH doesn't have it, or mocking missing)
    # The container likely doesn't have systemctl.
    
    # Mock killall via PATH
    mkdir -p /tmp/bin_killall
    echo '#!/bin/bash' > /tmp/bin_killall/killall
    echo 'echo "Reloaded via killall -HUP"' >> /tmp/bin_killall/killall
    chmod +x /tmp/bin_killall/killall
    
    ORIG_PATH="$PATH"
    export PATH="/tmp/bin_killall:$PATH"
    
    run bash -c "yes \"\" | bash $INSTALLER"
    
    export PATH="$ORIG_PATH"
    rm -rf /tmp/bin_killall
    
    mv /usr/bin/synoservice.bak /usr/bin/synoservice
    mv /usr/syno/sbin/synoservicectl.bak /usr/syno/sbin/synoservicectl
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"Reloaded via killall -HUP"* ]]
}

@test "Installer should copy script to /usr/local/bin" {
    # Mock root (id returns 0) - Standard in container
    export BING_RESOLUTION="4k"
    export BING_MARKET="en-WW"
    export BURN_TEXT_OVERLAY="true"
    
    # Non-interactive env var logic is handled separately
    # But if we want to run non-interactive, just set env vars and piping yes is enough?
    # Actually, install.sh checks [ -z "$NON_INTERACTIVE" ] for prompts.
    # If we pipe, [ -t 0 ] is false. So prompts skipped.
    
    run bash -c "yes \"\" | bash $INSTALLER"
    
    [ "$status" -eq 0 ]
    [ -x "/usr/local/bin/bing_wallpaper_auto_update.sh" ]
    [[ "$output" == *"Applying wallpaper now..."* ]]
    [[ "$output" == *"Done."* ]]
}

@test "Installer should add cron job" {
    export BING_RESOLUTION="4k"
    # Use yes to skip time prompt
    run bash -c "yes \"\" | bash $INSTALLER"
    [ "$status" -eq 0 ]
    
    # install.sh uses tabs. We use grep -E with [[:space:]]+ to match tabs or spaces
    grep -E "$INSTALL_PATH" /etc/crontab
    grep -E "0[[:space:]]+10" /etc/crontab
}

@test "Installer should respect CRON_HOUR/MIN env vars" {
    export CRON_HOUR=8
    export CRON_MIN=30
    
    export BING_RESOLUTION="4k"
    
    run bash -c "yes \"\" | bash $INSTALLER"
    [ "$status" -eq 0 ]
    
    grep -E "30[[:space:]]+8" /etc/crontab
}

@test "Installer should use Default Config (4k) in non-interactive mode" {
    # Without TTY, script defaults to 4k. We verify this default behavior.
    bash "$INSTALLER"
    
    # Non-interactive mode (default when piping yes without PTY)
    # This covers the ELSE branch of interactivity checks
    
    unset BING_RESOLUTION
    
    run bash -c "yes \"\" | bash $INSTALLER"
    
    [ "$status" -eq 0 ]
    
    TARGET="/usr/local/bin/bing_wallpaper_auto_update.sh"
    # Defaults
    grep 'BING_RESOLUTION="4k"' "$TARGET"
    grep 'BING_MARKET="en-WW"' "$TARGET"
    grep 'BURN_TEXT_OVERLAY=true' "$TARGET"
}

@test "Installer should configure custom Region and Overlay (Forced Interactive)" {
    # Interactive mode via pipe + FORCE_INTERACTIVE
    # Force defaults for resolution (1 = 4k), but change region -> 5 -> ja-JP
    # Overlay -> n (disable)
    # Time -> n (keep default)
    
    export FORCE_INTERACTIVE=1
    export LOCAL_INSTALL_PATH="/app/bing_wallpaper_auto_update.sh"
    
    # Inputs:
    # 1. Resolution: 1 (Default 4k)
    # 2. Region: 5 (Other)
    # 3. Region Code: ja-JP
    # 4. Overlay: n
    # 5. Time: n
    # 6. Extra newlines to ensure read loops terminate
    
    INPUTS=$(printf "1\n5\nja-JP\nn\nn\n\n\n")
    
    run bash -c "printf \"$INPUTS\" | bash $INSTALLER"
    
    [ "$status" -eq 0 ]
    
    TARGET="/usr/local/bin/bing_wallpaper_auto_update.sh"
    grep 'BING_RESOLUTION="4k"' "$TARGET"
    grep 'BING_MARKET="ja-JP"' "$TARGET"
    grep 'BURN_TEXT_OVERLAY=false' "$TARGET"
}

@test "Installer should handle invalid interactive inputs (Forced Interactive)" {
    # Interactive mode via pipe + FORCE_INTERACTIVE
    # Test invalid inputs triggering fallback defaults
    
    export FORCE_INTERACTIVE=1
    export LOCAL_INSTALL_PATH="/app/bing_wallpaper_auto_update.sh"
    
    # Inputs:
    # 1. Resolution: 9 (Invalid) -> 1 (Valid 4k)
    # 2. Region: 9 (Invalid) -> 1 (Valid en-WW)
    # 3. Overlay: x (Invalid/Accepted as Default)
    # 4. Time: n (No change)
    # 5. Extra newlines
    
    INPUTS=$(printf "9\n1\n9\n1\nx\nn\n\n\n")
    
    run bash -c "printf \"$INPUTS\" | bash $INSTALLER"
    
    [ "$status" -eq 0 ]
    
    TARGET="/usr/local/bin/bing_wallpaper_auto_update.sh"
    grep 'BING_RESOLUTION="4k"' "$TARGET"
    grep 'BING_MARKET="en-WW"' "$TARGET"
    grep 'BURN_TEXT_OVERLAY=true' "$TARGET"
}

@test "Installer should handle comprehensive interactive choices (Resolution, Region, Time Validation)" {
    export FORCE_INTERACTIVE=1
    export LOCAL_INSTALL_PATH="/app/bing_wallpaper_auto_update.sh"
    
    # Inputs:
    # 1. Resolution: 2 (1080p)
    # 2. Region: 2 (en-US)
    # 3. Overlay: y (Enable)
    # 4. Change Time? y
    # 5. Enter Hour: 99 (Invalid) -> 12 (Valid)
    # 6. Enter Minute: 99 (Invalid) -> 30 (Valid)
    # 7. Extra newlines
    
    INPUTS=$(printf "2\n2\ny\ny\n99\n12\n99\n30\n\n\n")
    
    run bash -c "printf \"$INPUTS\" | bash $INSTALLER"
    
    [ "$status" -eq 0 ]
    
    TARGET="/usr/local/bin/bing_wallpaper_auto_update.sh"
    grep 'BING_RESOLUTION="1080p"' "$TARGET"
    grep 'BING_MARKET="en-US"' "$TARGET"
    # Verify cron schedule
    grep -E "30[[:space:]]+12" /etc/crontab
}

@test "Installer should download script if local source missing" {
    unset LOCAL_INSTALL_PATH
    
    # Provide inputs (Yes to time change? No, stick to defaults)
    # The installer will try to download. Our mock wget should handle it.
    
    run bash -c "yes \"\" | bash $INSTALLER"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"Downloading SRM Wallpaper Script..."* ]]
    [ -f "/usr/local/bin/bing_wallpaper_auto_update.sh" ]
}

@test "Installer should fail if download fails" {
    unset LOCAL_INSTALL_PATH
    
    # Mock wget to fail
    mkdir -p /tmp/bin_fail
    echo '#!/bin/bash' > /tmp/bin_fail/wget
    echo 'exit 1' >> /tmp/bin_fail/wget
    chmod +x /tmp/bin_fail/wget
    
    # Prepend to PATH
    ORIG_PATH="$PATH"
    export PATH="/tmp/bin_fail:$PATH"
    
    # Use yes to skip prompts (though download happens before prompts)
    run bash -c "yes \"\" | bash $INSTALLER"
    
    export PATH="$ORIG_PATH"
    rm -rf /tmp/bin_fail
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"Download failed"* ]]
}

@test "Installer should fail if not root (Non-Root User)" {
    # Mock id command
    mkdir -p /tmp/bin_user_nr
    echo '#!/bin/bash' > /tmp/bin_user_nr/id
    echo 'if [ "$1" == "-u" ]; then echo 1000; else /usr/bin/id "$@"; fi' >> /tmp/bin_user_nr/id
    chmod +x /tmp/bin_user_nr/id
    
    ORIG_PATH="$PATH"
    export PATH="/tmp/bin_user_nr:$PATH"
    
    run bash "$INSTALLER"
    
    export PATH="$ORIG_PATH"
    rm -rf /tmp/bin_user_nr
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"must be run as root"* ]]
}
