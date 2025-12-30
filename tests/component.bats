#!/usr/bin/env bats

setup() {
    INSTALLER="/app/install.sh"
    chmod +x "$INSTALLER"
    
    # Use local path to avoid download
    export LOCAL_INSTALL_PATH="/app/bing_wallpaper_auto_update.sh"
    
    # Clean state
    rm -f /usr/local/bin/bing_wallpaper_auto_update.sh
    > /etc/crontab
    
    # Mock wallpaper script execution during install (auto-apply)
    # We don't want it to actually run heavy logic, just exist
    # But install.sh COPIES the source file.
    # We let it copy the real file, but we mock the dependencies (wget) so it doesn't hang.
    
    # Mock wget to handle Bing API and Image download
    mkdir -p /tmp/bin
    cat << 'EOF' > /tmp/bin/wget
#!/bin/bash
if [[ "$@" == *"HPImageArchive.aspx"* ]]; then
    # Return valid JSON for Bing API
    echo '{"images":[{"startdate":"20230101","urlbase":"/th?id=OHR.TestImage","copyright":"Test Copyright (c) Provider"}]}'
elif [[ "$@" == *".jpg" ]]; then
    # Create dummy image
    touch /tmp/mock_image.jpg
    echo "mock_binary_data" > /tmp/mock_image.jpg
    # If output is directed to stdout (captured by variable), cat it?
    # No, script uses -O "$TMP_FILE".
    # We need to handle -O argument.
    
    # Simple argument parsing to find -O or -qO
    OUTPUT_FILE=""
    while [[ $# -gt 0 ]]; do
        case $1 in
            -O) OUTPUT_FILE="$2"; shift ;;
            -O*) OUTPUT_FILE="${1#-O}" ;;
            -qO) OUTPUT_FILE="$2"; shift ;;
            -qO*) OUTPUT_FILE="${1#-qO}" ;;
        esac
        shift
    done
    
    if [ -n "$OUTPUT_FILE" ] && [ "$OUTPUT_FILE" != "-" ]; then
        echo "mock_binary_data" > "$OUTPUT_FILE"
    else
        echo "mock_binary_data"
    fi
else
    # Default success
    exit 0
fi
EOF
    chmod +x /tmp/bin/wget
    export PATH="/tmp/bin:$PATH"
}

teardown() {
    rm -rf /tmp/bin
}

@test "Component: Config Injection (Resolution: 1080p, Region: ja-JP)" {
    # Run installer non-interactively (Inputs pre-set via env vars)
    run env BING_RESOLUTION="1080p" \
            BING_MARKET="ja-JP" \
            BURN_TEXT_OVERLAY="false" \
            NON_INTERACTIVE="true" \
            bash "$INSTALLER"
            
    [ "$status" -eq 0 ] || { echo "Install Failed: $output"; false; }
    
    TARGET="/usr/local/bin/bing_wallpaper_auto_update.sh"
    
    # Verify Injection
    grep 'BING_RESOLUTION="1080p"' "$TARGET"
    grep 'BING_MARKET="ja-JP"' "$TARGET"
    grep 'BURN_TEXT_OVERLAY=false' "$TARGET"
}

@test "Component: Idempotency (Repeat Install)" {
    export NON_INTERACTIVE="true"
    
    # First Run (Default 4k)
    run env BING_RESOLUTION="4k" NON_INTERACTIVE="true" bash "$INSTALLER"
    [ "$status" -eq 0 ]
    
    # Verify single cron entry
    COUNT=$(grep -c "$TARGET" /etc/crontab || true)
    
    # Second Run (Change Config)
    run env BING_RESOLUTION="1080p" NON_INTERACTIVE="true" bash "$INSTALLER"
    [ "$status" -eq 0 ]
    
    # Verify ONLY one entry remains (sed delete worked)
    FINAL_COUNT=$(grep -c "bing_wallpaper_auto_update.sh" /etc/crontab)
    [ "$FINAL_COUNT" -eq 1 ]
    
    # Verify config updated
    run grep 'BING_RESOLUTION="1080p"' "/usr/local/bin/bing_wallpaper_auto_update.sh"
    [ "$status" -eq 0 ]
}

@test "Component: Service Manager Priority (Mock synoservicectl)" {
    # Ensure synoservicectl exists (Dockerfile mock)
    [ -x "/usr/syno/sbin/synoservicectl" ]
    
    run env NON_INTERACTIVE="true" bash "$INSTALLER"
    [ "$status" -eq 0 ]
    
    [[ "$output" == *"Restarted via synoservicectl"* ]]
}
