#!/bin/sh

# ==============================================================================
# Synology SRM 1.3 Bing Daily Wallpaper Script
# Version: 1.0.2
#
# Description:
# This script downloads the daily Bing wallpaper and updates the SRM login screen.
# It is adapted for Synology Router Manager (SRM) 1.3.
#
# Usage:
# Run this script as root or via Task Scheduler (User: root).
# ==============================================================================

# --- Configuration ---

# 1. Resolution Options
# Choose between "4k" (UHD) or "1080p" (FHD).
BING_RESOLUTION="4k"

# 2. Region Options
# Select the Bing market/region to fetch the image from.
# Default: "en-WW" (Global/World Wide)
# Supported regions:
# "en-WW" (Worldwide)
# "en-US" (USA)
# "en-GB" (United Kingdom/England)
# "en-CA" (Canada)
# "en-AU" (Australia)
# "en-NZ" (New Zealand)
# "en-IN" (India)
# "en-SG" (Singapore)
# "zh-CN" (China)
# "ja-JP" (Japan)
# "de-DE" (Germany)
# "fr-FR" (France)
# "it-IT" (Italy)
# "es-ES" (Spain)
# "pt-BR" (Brazil)
BING_MARKET="en-WW"

# 3. Archiving Options
ENABLE_ARCHIVE=false
SAVE_PATH="/volume1/web/wallpapers"

# 4. Login Screen Welcome Message
# Set to true to display wallpaper title and copyright on login screen
# NOTE: This is a DSM-only feature and does NOT work on SRM
SET_WELCOME_MSG=false

# 5. Burn Text Overlay into Image
# Set to true to overlay title and copyright text directly on the wallpaper image
BURN_TEXT_OVERLAY=true

# Font cache (root-owned; not under world-writable /tmp)
FONT_CACHE_DIR="/usr/local/share/bing-wallpaper"
FONT_FILE="$FONT_CACHE_DIR/Lato-Bold.ttf"

# SRM 1.3 standard custom background path (Attempt 1)
SRM_LOGIN_BG="/usr/syno/etc/login_background.jpg"

# SRM 1.3 Desktop Wallpaper Directories (Method B - Replace default wallpapers)
# These paths are for the wallpapers shown in Personal > Display Preferences
SRM_WALLPAPER_DIR="/usr/syno/synoman/webman/resources/images/default_wallpaper"
SRM_ROUTER_THEME_DIR="/usr/syno/synoman/webman/resources/images/theme/router/default_wallpaper"

# --- End Configuration ---

# ==============================================================================
# MAIN LOGIC
# ==============================================================================

main() {
    # Check for root
    if [ "$(id -u)" -ne 0 ]; then
        echo "Error: This script must be run as root."
        echo "Try: sudo $0"
        exit 1
    fi

    # Private temp directory (avoids /tmp symlink races)
    WORKDIR=$(mktemp -d /tmp/bing_srm.XXXXXX) || {
        echo "Error: Could not create temporary directory."
        exit 1
    }
    chmod 700 "$WORKDIR"
    # EXIT cleans up; INT/TERM must exit so execution does not resume after cleanup
    trap 'rm -rf "$WORKDIR"' EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM

    TMP_FILE="$WORKDIR/daily.jpg"
    TMP_LOGIN_FILE="$WORKDIR/daily_login.jpg"
    TMP_OVERLAY="$WORKDIR/overlay_output.jpg"
    TMP_TITLE="$WORKDIR/title.png"
    TMP_COPY="$WORKDIR/copy.png"
    TMP_BOX="$WORKDIR/combined.png"

    # --- Step 1: Fetch Image Info ---
    echo "Fetching Bing Wallpaper info ($BING_RESOLUTION - $BING_MARKET)..."
    API_URL="https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=$BING_MARKET"
    JSON=$(wget -qO- "$API_URL") || {
        echo "Error: Failed to fetch Bing API (check network/TLS certificates)."
        exit 1
    }

    SUFFIX="_1920x1080.jpg"
    if [ "$BING_RESOLUTION" = "4k" ]; then
        SUFFIX="_UHD.jpg"
    fi

    URL_PART=$(echo "$JSON" | grep -o '"urlbase":"[^"]*"' | cut -d'"' -f4)
    PIC_URL="https://www.bing.com${URL_PART}${SUFFIX}"

    # Extract Metadata
    DATE=$(echo "$JSON" | grep -o '"startdate":"[^"]*"' | cut -d'"' -f4)
    FULL_COPYRIGHT=$(echo "$JSON" | grep -o '"copyright":"[^"]*"' | cut -d'"' -f4)

    # Extract Title: Everything before the " ("
    TITLE="${FULL_COPYRIGHT%% (*}" # Everything before ' ('

    # Extract Copyright Credit: Everything inside the last parentheses
    COPYRIGHT="${FULL_COPYRIGHT#* (}"
    COPYRIGHT="${COPYRIGHT%)}"

    # Reject empty / non-absolute / path tricks from crafted API JSON.
    # Absolute /path under www.bing.com makes PIC_URL host-safe by construction.
    case "$URL_PART" in
        /*)
            case "$URL_PART" in
                *://* | *@* | *..*)
                    echo "Error: Wallpaper URL path contains unexpected characters."
                    exit 1
                    ;;
            esac
            ;;
        *)
            echo "Error: Could not extract wallpaper URL."
            exit 1
            ;;
    esac

    echo "Date: $DATE"
    echo "Title: $TITLE"
    echo "Copyright: $COPYRIGHT"

    # --- Step 2: Download Image ---
    wget -t 5 --user-agent="Mozilla/5.0" "$PIC_URL" -qO "$TMP_FILE" || {
        echo "Error: Download failed (check network/TLS certificates)."
        exit 1
    }
    [ -s "$TMP_FILE" ] || {
        echo "Error: Download failed."
        exit 1
    }

    # Reject non-JPEG before ImageMagick processing (SOI = FF D8 FF)
    MAGIC=$(od -An -tx1 -N3 "$TMP_FILE" | tr -d ' \n' | tr 'A-F' 'a-f')
    case "$MAGIC" in
        ffd8ff) ;;
        *)
            echo "Error: Downloaded file does not start with a JPEG SOI marker."
            exit 1
            ;;
    esac

    # Create a copy for the login screen (which might get text overlay)
    cp -f "$TMP_FILE" "$TMP_LOGIN_FILE"

    # --- Step 2.5: Burn Text Overlay (Optional - Login Screen ONLY) ---
    if [ "$BURN_TEXT_OVERLAY" = "true" ] && which convert >/dev/null 2>&1; then
        echo "Adding text overlay to login wallpaper..."

        # Download a standalone font to bypass system font config errors
        # Use JSDelivr (reliable GitHub proxy) to get Lato-Bold from Google Fonts repo
        FONT_URL="https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/lato/Lato-Bold.ttf"
        mkdir -p "$FONT_CACHE_DIR"
        chmod 700 "$FONT_CACHE_DIR"

        # Download when missing or too small (< 10KB)
        FONT_KB=$(du -k "$FONT_FILE" 2>/dev/null | cut -f1)
        FONT_KB=${FONT_KB:-0}
        if [ "$FONT_KB" -lt 10 ]; then
            echo "Downloading overlay font..."
            FONT_STAGED="$WORKDIR/Lato-Bold.ttf"
            wget --user-agent="Mozilla/5.0" -qO "$FONT_STAGED" "$FONT_URL" || rm -f "$FONT_STAGED"
            if [ -s "$FONT_STAGED" ]; then
                mv -f "$FONT_STAGED" "$FONT_FILE"
                chmod 644 "$FONT_FILE"
            fi
        fi

        if [ -s "$FONT_FILE" ]; then
            if head -c 5 "$FONT_FILE" | grep -q "<"; then
                echo "Error: Downloaded font appears to be HTML. Removing..."
                rm -f "$FONT_FILE"
                echo "Warning: Font missing or zero size. Skipping text overlay."
            else
                # identify may be absent; empty W falls through to default width
                W=$(identify -format "%w" "$TMP_LOGIN_FILE" 2>/dev/null)

                # Validate W is a number, otherwise default
                case $W in
                    '' | *[!0-9]*) WIDTH=3840 ;;
                    *) WIDTH=$W ;;
                esac

                # Calculate responsive dimensions (integer math)
                # Margin: 5% of width
                MARGIN_X=$((WIDTH * 5 / 100))
                # Box Width: 40% of width
                BOX_WIDTH=$((WIDTH * 40 / 100))
                # Padding inside box: Fixed 25px
                PADDING=25

                echo "Calculated Margin: $MARGIN_X, Max Box Width: $BOX_WIDTH"

                # Method: Responsive Text Generation (Safe Trim)
                # Uses 'BorderGuard' to allow shrinking without clipping

                # --- Generate TITLE ---
                # 1. Caption at Max width (wraps if long)
                # 2. Add Border (Protection for anti-aliasing pixels)
                # 3. Trim (Removes empty space + border)
                convert -background "rgba(0,0,0,0)" -fill white -font "$FONT_FILE" -pointsize 24 \
                    -size ${BOX_WIDTH}x -gravity NorthWest caption:"$TITLE" \
                    -bordercolor "rgba(0,0,0,0)" -border 20 \
                    -trim +repage \
                    "$TMP_TITLE"

                # --- Generate COPYRIGHT ---
                convert -background "rgba(0,0,0,0)" -fill white -font "$FONT_FILE" -pointsize 16 \
                    -size ${BOX_WIDTH}x -gravity NorthWest caption:"$COPYRIGHT" \
                    -bordercolor "rgba(0,0,0,0)" -border 20 \
                    -trim +repage \
                    "$TMP_COPY"

                # Combine them vertically
                # Align Left (West)
                convert "$TMP_TITLE" "$TMP_COPY" -background "rgba(0,0,0,0)" -gravity West -append \
                    -bordercolor "rgba(0,0,0,0)" -border $PADDING \
                    -background "rgba(0,0,0,0.5)" -flatten \
                    +repage \
                    "$TMP_BOX"

                # Composite onto main image
                # Revert to NorthWest (Top-Left) for reliability, using calculated center.
                if [ -s "$TMP_BOX" ]; then
                    BOX_REAL_W=$(convert "$TMP_BOX" -format "%w" info: | tr -cd '0-9')
                    BOX_REAL_W=${BOX_REAL_W:-400}

                    # User requested: Offset left by HALF width (Align Right Edge to Center)
                    OFFSET=$((BOX_REAL_W / 2))

                    echo "DEBUG: Box Width=$BOX_REAL_W. Offsetting Left by $OFFSET"

                    # User requested: CENTER gravity - offset left by half width
                    convert "$TMP_LOGIN_FILE" "$TMP_BOX" \
                        -gravity Center -geometry -${OFFSET}+0 -composite \
                        "$TMP_OVERLAY"
                fi

                if [ -s "$TMP_OVERLAY" ]; then
                    mv -f "$TMP_OVERLAY" "$TMP_LOGIN_FILE"
                    echo "Text overlay added (Login Screen Only): $TITLE | $COPYRIGHT"
                else
                    echo "Error: ImageMagick failed to create overlay."
                fi
            fi
        else
            echo "Warning: Font missing or zero size. Skipping text overlay."
        fi
    else
        echo "Skipping text overlay (Disabled or ImageMagick not found)."
    fi

    # --- Step 3: Apply Wallpaper to SRM (Login Screen) ---
    echo "Applying wallpaper to SRM..."

    # Method A: Standard location
    if [ -f "$SRM_LOGIN_BG" ]; then
        # Use the version with potential text overlay
        cp -f "$TMP_LOGIN_FILE" "$SRM_LOGIN_BG"
        chmod 644 "$SRM_LOGIN_BG"
        echo "Updated $SRM_LOGIN_BG"
    fi

    # Method B: Update Default Desktop Wallpapers (Fully Automated)
    # Replace wallpapers in ALL possible directories (SRM uses different paths)
    # NOTE: We use TMP_FILE (Clean version) for desktop wallpapers!
    WALLPAPER_DIRS="$SRM_WALLPAPER_DIR
    $SRM_ROUTER_THEME_DIR
    /usr/syno/synoman/synohdpack/images/dsm/resources/images/default_wallpaper
    /usr/syno/synoman/synohdpack/images/dsm/resources/images/theme/router/default_wallpaper"

    echo "$WALLPAPER_DIRS" | while read -r DIR; do
        if [ -d "$DIR" ]; then
            echo "Updating wallpapers in: $DIR"
            for i in 01 02 03 04 05; do
                if [ -f "$DIR/${i}.jpg" ]; then
                    cp -f "$TMP_FILE" "$DIR/${i}.jpg"
                    chmod 644 "$DIR/${i}.jpg"
                fi
                # Also update thumbnails if they exist
                if [ -f "$DIR/thumbnail_${i}.jpg" ]; then
                    cp -f "$TMP_FILE" "$DIR/thumbnail_${i}.jpg"
                    chmod 644 "$DIR/${i}.jpg"
                fi
            done
        fi
    done

    echo "Desktop wallpaper updated in all directories!"
    echo "Note: Hard refresh your browser (Ctrl+Shift+R) or logout/login."

    # --- Step 4: Update Synoinfo (Attempt) ---
    # SRM usually uses synoinfo.conf for these flags too.
    if [ -f /etc/synoinfo.conf ]; then
        # Set login_background_customize="yes" to force it to look at the custom file (Method A)
        sed -i s/login_background_customize=.*//g /etc/synoinfo.conf
        echo "login_background_customize=\"yes\"" >>/etc/synoinfo.conf
        echo "Updated synoinfo.conf: login_background_customize=yes"

        # Update Welcome Message if enabled
        if [ "$SET_WELCOME_MSG" = "true" ]; then
            sed -i s/login_welcome_title=.*//g /etc/synoinfo.conf
            echo "login_welcome_title=\"$TITLE\"" >>/etc/synoinfo.conf

            sed -i s/login_welcome_msg=.*//g /etc/synoinfo.conf
            echo "login_welcome_msg=\"$COPYRIGHT\"" >>/etc/synoinfo.conf
            echo "Updated login screen message: $TITLE"
            echo "Note: You may need to logout or refresh the login page to see changes."
        fi
    fi

    # --- Step 5: Archive (Optional) ---
    if [ "$ENABLE_ARCHIVE" = "true" ]; then
        mkdir -p "$SAVE_PATH"
        SAFE_TITLE=$(echo "$TITLE" | tr -cd '[:alnum:] .-')
        SAFE_COPYRIGHT=$(echo "$COPYRIGHT" | tr -cd '[:alnum:] .-')
        case "$DATE" in
            [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9])
                SAFE_DATE=$DATE
                ARCHIVE_FILE="$SAVE_PATH/${SAFE_DATE} - ${SAFE_TITLE} - ${SAFE_COPYRIGHT}.jpg"
                cp -f "$TMP_FILE" "$ARCHIVE_FILE" || {
                    echo "Error: Failed to archive wallpaper to $ARCHIVE_FILE"
                    exit 1
                }
                chmod 644 "$ARCHIVE_FILE"
                echo "Archived: $ARCHIVE_FILE"
                ;;
            *)
                echo "Warning: Invalid startdate '$DATE'; skipping archive."
                ;;
        esac
    fi

    # Temp files removed by trap on WORKDIR
    echo "Done."
}

if [ "${TEST_MODE}" != "1" ]; then
    main "$@"
fi
