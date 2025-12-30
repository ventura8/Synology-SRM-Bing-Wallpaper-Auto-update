#!/bin/sh
# Uninstaller for Synology SRM 1.3 Bing Wallpaper Script


main() {
    USER_ID=$(id -u)
    if [ "$USER_ID" -ne 0 ]; then
        echo "Error: This script must be run as root. Try 'sudo -i' first."
        exit 1
    fi

    SCRIPT_NAME="bing_wallpaper_auto_update.sh"
    INSTALL_DIR="/usr/local/bin"
    INSTALL_PATH="$INSTALL_DIR/$SCRIPT_NAME"

    echo "Uninstalling SRM Wallpaper Script..."

    # 1. Remove Script File
    if [ -f "$INSTALL_PATH" ]; then
        rm -f "$INSTALL_PATH"
        echo "Removed script: $INSTALL_PATH"
    else
        echo "Script not found at $INSTALL_PATH. Skipping removal."
    fi

    # 2. Remove Cron Job
    CRON_FILE="/etc/crontab"
    if grep -q "$INSTALL_PATH" "$CRON_FILE"; then
        echo "Removing schedule from $CRON_FILE..."
        # Use sed to delete lines matching the script path
        sed -i "\#$INSTALL_PATH#d" "$CRON_FILE"
    else
        echo "No schedule found in $CRON_FILE."
    fi

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
    echo "Uninstallation Complete!"
    echo "======================================================="
    echo "Note: Any changes made to /etc/synoinfo.conf (e.g., enabling custom login background)"
    echo "have NOT been reverted to prevent affecting other custom settings."
    echo "If you wish to disable the custom login background, check your Control Panel settings."
    echo "======================================================="
}

if [ "${TEST_MODE}" != "1" ]; then
    main "$@"
fi
