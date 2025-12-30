#!/bin/sh
# Installer for Synology SRM 1.3 Bing Wallpaper Script


main() {
    USER_ID=$(id -u)
    if [ "$USER_ID" -ne 0 ]; then
        echo "Error: This script must be run as root. Try 'sudo -i' first."
        exit 1
    fi

    REPO_URL="https://raw.githubusercontent.com/ventura8/Synology-SRM-Bing-Wallpaper-Auto-update/main"
    SCRIPT_NAME="bing_wallpaper_auto_update.sh"
    INSTALL_DIR="/usr/local/bin"
    INSTALL_PATH="$INSTALL_DIR/$SCRIPT_NAME"

    read_input() {
        if [ -t 0 ] || [ -n "$FORCE_STDIN" ] || [ -n "$FORCE_INTERACTIVE" ]; then
            read -r "$@"
        else
            # Try to read from /dev/tty. If it fails (e.g. no device in container), fallback to stdin.
            if ! { read -r "$@" < /dev/tty; } 2>/dev/null; then
                read -r "$@"
            fi
        fi
    }

    if [ -n "$LOCAL_INSTALL_PATH" ]; then
        echo "Installing from local source: $LOCAL_INSTALL_PATH"
        cp "$LOCAL_INSTALL_PATH" "$INSTALL_PATH"
    else
        echo "Downloading SRM Wallpaper Script..."
        wget -t 5 --no-cache --no-check-certificate "$REPO_URL/$SCRIPT_NAME" -qO "$INSTALL_PATH"
    fi

    if [ ! -s "$INSTALL_PATH" ]; then
        echo "Error: Download failed, file missing, or empty."
        exit 1
    fi

    # --- Interactive Resolution Selection ---
    # Allow pre-setting via env var for automation
    if [ -n "$BING_RESOLUTION" ]; then
        RESOLUTION="$BING_RESOLUTION"
        echo "Using pre-set resolution: $RESOLUTION"
    else
        RESOLUTION="4k"  # Default
        if { [ -t 0 ] || [ -c /dev/tty ] || [ -n "$FORCE_INTERACTIVE" ]; } && [ -z "$NON_INTERACTIVE" ]; then
            echo ""
            echo "Choose image resolution:"
            echo "  [1] 4K (UHD) - Default"
            echo "  [2] 1080p (FHD)"
            printf "Enter choice [1]: "
            read_input RES_CHOICE
            
            case "$RES_CHOICE" in
                2)
                    RESOLUTION="1080p"
                    echo "Selected: 1080p"
                    ;;
                1|"")
                    RESOLUTION="4k"
                    echo "Selected: 4K"
                    ;;
                *)
                    echo "Invalid choice. Using default: 4K"
                    RESOLUTION="4k"
                    ;;
            esac
        fi
    fi

    # Apply resolution to downloaded script
    sed -i "s/BING_RESOLUTION=\".*\"/BING_RESOLUTION=\"$RESOLUTION\"/" "$INSTALL_PATH"


    # --- Interactive Region Selection ---
    if [ -n "$BING_MARKET" ]; then
        REGION="$BING_MARKET"
        echo "Using pre-set region: $REGION"
    else
        REGION="en-WW" # Default
        if { [ -t 0 ] || [ -c /dev/tty ] || [ -n "$FORCE_INTERACTIVE" ]; } && [ -z "$NON_INTERACTIVE" ]; then
            echo ""
            echo "Choose Bing Region:"
            echo "  [1] en-WW (Worldwide) - Default"
            echo "  [2] en-US (USA)"
            echo "  [3] en-GB (UK)"
            echo "  [4] de-DE (Germany)"
            echo "  [5] Other (Type manual code e.g. ja-JP)"
            printf "Enter choice [1]: "
            read_input REGION_CHOICE

            case "$REGION_CHOICE" in
                2) REGION="en-US" ;;
                3) REGION="en-GB" ;;
                4) REGION="de-DE" ;;
                5)
                    printf "Enter region code: "
                    read_input MAN_REGION
                    if [ -n "$MAN_REGION" ]; then
                        REGION="$MAN_REGION"
                    fi
                    ;;
                *) REGION="en-WW" ;;
            esac
            echo "Selected Region: $REGION"
        fi
    fi
    sed -i "s/BING_MARKET=\".*\"/BING_MARKET=\"$REGION\"/" "$INSTALL_PATH"


    # --- Interactive Text Overlay Selection ---
    if [ -n "$BURN_TEXT_OVERLAY" ]; then
        OVERLAY="$BURN_TEXT_OVERLAY"
        echo "Using pre-set text overlay setting: $OVERLAY"
    else
        OVERLAY="true" # Default
        if { [ -t 0 ] || [ -c /dev/tty ] || [ -n "$FORCE_INTERACTIVE" ]; } && [ -z "$NON_INTERACTIVE" ]; then
            echo ""
            printf "Enable Text Overlay (Title & Copyright)? [Y/n]: "
            read_input OVERLAY_CHOICE
            case "$OVERLAY_CHOICE" in
                [nN][oO]|[nN])
                    OVERLAY="false"
                    echo "Selected Overlay: Disabled"
                    ;;
                *)
                    OVERLAY="true"
                    echo "Selected Overlay: Enabled"
                    ;;
            esac
        fi
    fi
    sed -i "s/BURN_TEXT_OVERLAY=.*/BURN_TEXT_OVERLAY=$OVERLAY/" "$INSTALL_PATH"


    chmod +x "$INSTALL_PATH"
    echo "Installed to: $INSTALL_PATH"

    # --- Cron Automation ---
    CRON_FILE="/etc/crontab"

    # Defaults
    DEF_HOUR=${CRON_HOUR:-10}
    DEF_MIN=${CRON_MIN:-0}
    NEW_HOUR="$DEF_HOUR"
    NEW_MIN="$DEF_MIN"

    # Interactive Prompt for Time
    # We use /dev/tty because the script is often piped via wget
    if { [ -t 0 ] || [ -c /dev/tty ] || [ -n "$FORCE_INTERACTIVE" ]; } && [ -z "$NON_INTERACTIVE" ]; then
        echo "-------------------------------------------------------"
        printf "Default schedule is set to %02d:%02d daily.\n" "$DEF_HOUR" "$DEF_MIN"
        printf "Do you want to change the time? [y/N] "
        read_input RESPONSE
        case "$RESPONSE" in
            [yY][eE][sS]|[yY])
                while true; do
                    printf "Enter Hour (0-23): "
                    read_input NEW_HOUR
                    # Validate integer 0-23
                    if [ "$NEW_HOUR" -ge 0 ] && [ "$NEW_HOUR" -le 23 ] 2>/dev/null; then
                        DEF_HOUR=$NEW_HOUR
                        break
                    else
                        echo "Invalid hour. Please enter a number between 0 and 23."
                    fi
                done

                while true; do
                    printf "Enter Minute (0-59): "
                    read_input NEW_MIN
                    # Validate integer 0-59
                    if [ "$NEW_MIN" -ge 0 ] && [ "$NEW_MIN" -le 59 ] 2>/dev/null; then
                        DEF_MIN=$NEW_MIN
                        break
                    else
                        echo "Invalid minute. Please enter a number between 0 and 59."
                    fi
                done
                ;;
            *)
                echo "Keeping default time."
                ;;
        esac
    fi

    HOUR=$DEF_HOUR
    MIN=$DEF_MIN
    CRON_JOB="$MIN\t$HOUR\t*\t*\t*\troot\t$INSTALL_PATH"

    echo "Configuring automatic execution..."

    # Backup crontab just in case
    cp "$CRON_FILE" "${CRON_FILE}.bak"

    # 1. Remove existing entry (if any) to avoid duplicates or old schedules
    if grep -q "$INSTALL_PATH" "$CRON_FILE"; then
        echo "Removing old schedule..."
        # Use sed to delete lines matching the script path
        sed -i "\#$INSTALL_PATH#d" "$CRON_FILE"
    fi

    # 2. Append new job
    printf "%b\n" "$CRON_JOB" >> "$CRON_FILE"
    printf "Added to %s (Schedule: %02d:%02d)\n" "$CRON_FILE" "$HOUR" "$MIN"

    # 3. Restart cron service
    echo "Restarting cron service..."
    if command -v synoservicectl >/dev/null 2>&1; then
        /usr/syno/sbin/synoservicectl --reload crond
        echo "Restarted via synoservicectl."
    elif command -v synoservice >/dev/null 2>&1; then
        synoservice --restart crond
        echo "Restarted via synoservice."
    elif command -v systemctl >/dev/null 2>&1; then
        systemctl restart crond
        echo "Restarted via systemctl."
    else
        # Fallback: Send SIGHUP to crond to reload configuration
        killall -HUP crond 2>/dev/null
        echo "Reloaded via killall -HUP."
    fi

    echo ""
    echo "======================================================="
    echo "Installation Complete!"
    echo "======================================================="
    printf "The wallpaper will update automatically every day at %02d:%02d.\n" "$HOUR" "$MIN"
    echo ""
    echo "To run manually later:"
    echo "  sudo $INSTALL_PATH"
    echo "======================================================="

    # --- Auto-Apply Wallpaper ---
    echo ""
    echo "Applying wallpaper now..."
    bash "$INSTALL_PATH"
}

if [ "${TEST_MODE}" != "1" ]; then
    main "$@"
fi
