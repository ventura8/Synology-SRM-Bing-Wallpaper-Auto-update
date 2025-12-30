#!/usr/bin/env bats

setup() {
    # Create a temporary directory for our mock environment
    export MOCK_ENV_DIR="$(mktemp -d)"
    export CONFIG_DIR="$MOCK_ENV_DIR/etc"
    export INSTALL_DIR="$MOCK_ENV_DIR/usr/local/bin"
    export SAVE_PATH="$MOCK_ENV_DIR/volume1/web/wallpapers"
    export LOGIN_BG="$MOCK_ENV_DIR/usr/syno/etc/login_background.jpg"
    
    # Mock Synology directories
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$SAVE_PATH"
    mkdir -p "$(dirname "$LOGIN_BG")"
    
    # Create valid mock images
    touch "$LOGIN_BG"
    
    # Source the scripts - BUT without executing main
    # We will rely on calling main or functions directly in tests if needed
    # or executing the script if we want to test that path.
    export SCRIPT_PATH="./bing_wallpaper_auto_update.sh"
    export INSTALL_SCRIPT="./install.sh"
    export UNINSTALL_SCRIPT="./uninstall.sh"
    
    # Point to the local copy for installation
    export LOCAL_INSTALL_PATH="/app/bing_wallpaper_auto_update.sh"
}

teardown() {
    rm -rf "$MOCK_ENV_DIR"
}

@test "E2E: Full Installation, Execution, and Uninstallation Flow" {
    # 1. Install
    # We simulate the install environment
    # Mocking id to return 0 (root)
    # We can't easily mock id inside the script without complex PATH manipulation or function overriding when sourcing.
    # For E2E, we can use `run` and expect failure if not root, OR we use the "main" function wrapper technique.
    
    # Let's try to source the install script and call main with mocked environment variables
    # We need to override global variables in the script via environment if possible, or sed them.
    # Since we refactored to use main, we can potentially overwrite functions or variables.
    
    # However, existing scripts use hardcoded paths like /etc/crontab. 
    # To properly E2E test without root/destroying system, we must use a Docker container (which we do in CI).
    # BUT, if we run `run_tests.sh` locally outside Docker, this might fail.
    # Assuming this runs in the CI Docker container where we are root.
    
    if [ "$(id -u)" -ne 0 ]; then
        skip "E2E tests must be run as root (or in Docker/CI)"
    fi
    
    
    # Execute Install Script
    run bash "$INSTALL_SCRIPT"
    [ "$status" -eq 0 ]
    
    # Verify Installation
    [ -f "/usr/local/bin/bing_wallpaper_auto_update.sh" ]
    run grep -q "bing_wallpaper_auto_update.sh" /etc/crontab
    [ "$status" -eq 0 ]
    
    # 2. Run the Main Script
    run bash /usr/local/bin/bing_wallpaper_auto_update.sh
    [ "$status" -eq 0 ]

    # Verify artifacts
    # The script deletes TMP_FILE at the end.
    # We should check the installation destination or side effects.
    # It copies to SRM_LOGIN_BG="/usr/syno/etc/login_background.jpg"
    
    [ -f "/usr/syno/etc/login_background.jpg" ]
    [ -s "/usr/syno/etc/login_background.jpg" ]
    
    # 3. Uninstall
    run bash "$UNINSTALL_SCRIPT"
    [ "$status" -eq 0 ]
    
    # Verify Uninstallation
    [ ! -f "/usr/local/bin/bing_wallpaper_auto_update.sh" ]
    run grep -q "bing_wallpaper_auto_update.sh" /etc/crontab
    [ "$status" -ne 0 ]
}
