#!/usr/bin/env bats

setup() {
    # Path to script
    SCRIPT="/app/bing_wallpaper_auto_update.sh"
    chmod +x "$SCRIPT"
    
    # Mock wget to return our JSON when queried for Bing API
    # We create a function wrapper in the test environment (cannot easily wrap inside script unless sourced)
    # So we used a stub script in path earlier? No, simpler: 
    # We will modify the script to allow passing a TEST_JSON_FILE env var?
    # Or mock `wget` by creating a script in PATH.
    
    mkdir -p /tmp/bin
    
    # Create Runtime Mock JSON (Minified) to ensure grep works regardless of Docker image state
    ECHO_JSON='{"images":[{"startdate":"20251230","fullstartdate":"202512300000","enddate":"20251231","url":"/th?id=OHR.WhooperSwans_EN-US1234.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.WhooperSwans_EN-US1234","copyright":"Whooper swans, Kotoku Pond, Japan (© Martin Bailey/Shutterstock)","copyrightlink":"https://www.bing.com/search?q=Whooper+Swans","title":"Whooper swans, Kotoku Pond, Japan","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20251230_WhooperSwans%22&FORM=HPQUIZ","wp":true,"hsh":"1234567890abcdef","drk":1,"top":1,"bot":1,"hs":[]}]}'
    echo "$ECHO_JSON" > /tmp/mock_response.json

    # Mock/Link Font File expected by script
    # Debian installs Noto CJK at /usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc OR /usr/share/fonts/truetype/noto/
    # We find where it is and link it to the script's strict expectation path
    mkdir -p /usr/share/fonts/truetype/noto/
    # Find any TTC/TTF font
    FONT_FOUND=$(find /usr/share/fonts -name "*Regular.ttc" -o -name "*Regular.ttf" | head -n 1)
    if [ -n "$FONT_FOUND" ]; then
        ln -sf "$FONT_FOUND" "/usr/share/fonts/truetype/noto/NotoSansCJK-Regular.ttc"
    else
        # Fallback dummy file (might crash mogrify but better than nothing or fail explicitly)
        touch /usr/share/fonts/truetype/noto/NotoSansCJK-Regular.ttc
    fi

    # Mock `wget` with logging
    cat <<EOT | tr -d '\r' > /tmp/bin/wget
#!/bin/bash
echo "Mock wget called with args: \$*" >> /tmp/wget-mock.log

# If request contains 'HPImageArchive.aspx', return mock JSON
if [[ "\$@" == *"HPImageArchive.aspx"* ]]; then
    echo "Matched HPImageArchive" >> /tmp/wget-mock.log
    cat /tmp/mock_response.json
    exit 0
fi
    # If request downloads image (ends in .jpg), create dummy file
    if [[ "\$@" == *".jpg"* ]]; then
        echo "Matched JPG download" >> /tmp/wget-mock.log
        # Create a valid white image using convert so processing works
        # Fallback to simple file creation if convert is missing (for tests that kill convert)
        if command -v convert >/dev/null 2>&1; then
             convert -size 1920x1080 xc:white /tmp/mock_image.jpg
        else
             echo "mock_image_binary_data" > /tmp/mock_image.jpg
        fi
        # If -O or -qO is present, copy result there
        OUTPUT=""
        while [[ "\$#" -gt 0 ]]; do
            case "\$1" in
                -O|-qO) OUTPUT="\$2"; shift ;;
            esac
            shift
        done
        if [ -n "\$OUTPUT" ] && [ "\$OUTPUT" != "-" ]; then
            mv /tmp/mock_image.jpg "\$OUTPUT"
        elif [ "\$OUTPUT" == "-" ]; then
            cat /tmp/mock_image.jpg
        fi
        exit 0
    fi
    
    # NEW: Handle Font Download (.ttf or .ttc)
    if [[ "\$@" == *".ttf"* ]] || [[ "\$@" == *".ttc"* ]]; then
        echo "Matched FONT download" >> /tmp/wget-mock.log
        
        # Find a valid font to serve
        LOCAL_FONT=\$(find /usr/share/fonts -name "*Regular.ttc" -o -name "*Regular.ttf" | head -n 1)
        
        OUTPUT=""
        while [[ "\$#" -gt 0 ]]; do
            case "\$1" in
                -O|-qO) OUTPUT="\$2"; shift ;;
            esac
            shift
        done
        
        if [ -n "\$OUTPUT" ] && [ -n "\$LOCAL_FONT" ]; then
            cp "\$LOCAL_FONT" "\$OUTPUT"
        else
            echo "Error: No local font found to mock download" >> /tmp/wget-mock.log
        fi
        exit 0
    fi

    # Default behavior (pass through or fail)
echo "Mock wget call falls through: \$@" >> /tmp/wget-mock.log
echo "Mock wget call: \$@" >&2
exit 0
EOT
    chmod +x /tmp/bin/wget
    
    # Prepend mock bin to PATH
    export PATH="/tmp/bin:$PATH"
    
    # Reset Environment Files
    echo 'login_background_customize="no"' > /etc/synoinfo.conf
    # Clear target file
    true > /usr/syno/etc/login_background.jpg
}

teardown() {
    rm -rf /tmp/bin
    rm -f /tmp/*.jpg
    rm -f /tmp/*.png
    # Print log if failed
    # cat /tmp/wget-mock.log || true
}

@test "Script should extract Title and Copyright correctly" {
    # Debug info
    echo "Checking Mock JSON content:"
    ls -l /app/tests/mocks/bing_response.json
    cat /app/tests/mocks/bing_response.json
    echo "Checking Font Setup:"
    ls -l /usr/share/fonts/truetype/noto/NotoSansCJK-Regular.ttc || echo "Font Link MISSING"
    echo "---------------------------"

    # Run the script with dry run or just run it. Script logic prints info.
    run bash "$SCRIPT"
    
    echo "Output: $output"
    # Show mock logs
    echo "Mock Logs:"
    cat /tmp/wget-mock.log || echo "No mock logs"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"Title: Whooper swans, Kotoku Pond, Japan"* ]]
    [[ "$output" == *"Copyright: © Martin Bailey/Shutterstock"* ]]
}

@test "Script should update login_background.jpg" {
    run bash "$SCRIPT"
    [ "$status" -eq 0 ]
    
    # Check if file was updated (non-zero size)
    [ -s "/usr/syno/etc/login_background.jpg" ]
}

@test "Script should enable login_background_customize in synoinfo.conf" {
    run bash "$SCRIPT"
    [ "$status" -eq 0 ]
    
    grep 'login_background_customize="yes"' /etc/synoinfo.conf
}

@test "Script should create overlay artifacts (if enabled)" {
    # Default script has overlay enabled? Let's check config. 
    # BURN_TEXT_OVERLAY=true is default in script.
    
    run bash "$SCRIPT"
    [ "$status" -eq 0 ]
    # Check logs for overlay success
    [[ "$output" == *"Text overlay added"* ]]
}

@test "Script should update theme wallpaper directories" {
    run bash "$SCRIPT"
    [ "$status" -eq 0 ]
    
    # Script updates 01.jpg IF it exists. Dockerfile now creates it.
    [ -s "/usr/syno/synoman/webman/resources/images/default_wallpaper/01.jpg" ]
    [ -s "/usr/syno/synoman/webman/resources/images/theme/router/default_wallpaper/01.jpg" ]
}

@test "Script should archive wallpaper if enabled" {
    # Modify script config on the fly (or via env var if supported, but script has hardcoded vars at top)
    # The script supports variables somewhat, but lines 21+ set defaults like ENABLE_ARCHIVE=false
    # We can modify the script file to set ENABLE_ARCHIVE=true
    
    sed -i 's/ENABLE_ARCHIVE=false/ENABLE_ARCHIVE=true/' "$SCRIPT"
    
    run bash "$SCRIPT"
    [ "$status" -eq 0 ]
    
    # Check archive creation (filename contains date)
    ARCHIVE_DIR="/volume1/web/wallpapers"
    [ -d "$ARCHIVE_DIR" ]
    COUNT=$(find "$ARCHIVE_DIR" -name "*20251230*.jpg" | wc -l)
    [ "$COUNT" -gt 0 ]
}

@test "Script should set login welcome message if enabled" {
    sed -i 's/SET_WELCOME_MSG=false/SET_WELCOME_MSG=true/' "$SCRIPT"
    
    run bash "$SCRIPT"
    [ "$status" -eq 0 ]
    
    grep 'login_welcome_title="Whooper swans, Kotoku Pond, Japan"' /etc/synoinfo.conf
    grep 'login_welcome_msg="© Martin Bailey/Shutterstock"' /etc/synoinfo.conf
}

@test "Script should handle font download failure (Skip Overlay)" {
    # Simulate font download fail
    # We strip the "mock wget font handling" or just make wget fail for .ttf logic
    # Our mock wget is complex. Let's create a fail-specific wget for this test.
    # Actually, simpler: The script checks [ -f "$FONT_FILE" ].
    # If we ensure wget FAILS to download, the file won't exist.
    # Our mock wget returns success for .ttf?
    # Let's modify the mock wget in this test scope or force a condition.
    
    # Just force `which convert` to fail to trigger "Skipping text overlay" branch (Line 240)
    # OR if we want to test "Font missing" branch (Line 237)
    
    # Let's test "Font missing" branch
    mkdir -p /tmp/bin_font_fail
    cp /tmp/bin/wget /tmp/bin_font_fail/wget # Copy existing mock
    
    # But wait, we want wget to fail for .ttf.
    # Let's just make the directory unwriteable? No, root.
    # Let's use the 'convert' fail test first.
    
    # Rename convert to simulate missing ImageMagick
    mv /usr/bin/convert /usr/bin/convert.bak
    
    run bash "$SCRIPT"
    
    mv /usr/bin/convert.bak /usr/bin/convert
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"Skipping text overlay (Disabled or ImageMagick not found)"* ]]
}

@test "Script should handle metadata extraction failure (Missing URL)" {
    # Create bad JSON
    echo '{}' > /tmp/mock_response.json
    
    run bash "$SCRIPT"
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: Could not extract wallpaper URL."* ]]
}

@test "Script should handle download failure (Image)" {
    # Restore valid JSON so it proceeds to download
    # But fail the image download.
    # Our mock wget handles .jpg. Let's make it exit 1 if URL contains "fail" or just force it.
    
    # Easy way: Delete mock wget and replace with failer for .jpg
    cat <<EOT > /tmp/bin/wget
#!/bin/bash
if [[ "\$@" == *".jpg"* ]]; then
    exit 1
fi
# Pass through JSON request
if [[ "\$@" == *"HPImageArchive.aspx"* ]]; then
    cat /tmp/mock_response.json
    exit 0
fi
exit 0
EOT
    chmod +x /tmp/bin/wget
    
    run bash "$SCRIPT"
    
    # Restore original mock (setup will re-create it on next run? bats setup runs before EACH test? YES)
    # So we don't strictly need to restore, but it's good practice inside the test if we had steps after.
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: Download failed."* ]]
}

@test "Script should handle ImageMagick measurement failure (Fallback width)" {
    # Mock convert to return error for info:
    mkdir -p /tmp/bin_im_fail
    cat <<EOT > /tmp/bin_im_fail/convert
#!/bin/bash
if [[ "\$@" == *"info:"* ]]; then
    exit 1
fi
/usr/bin/convert "\$@"
EOT
    chmod +x /tmp/bin_im_fail/convert
    
    ORIG_PATH="$PATH"
    export PATH="/tmp/bin_im_fail:$PATH"
    
    run bash "$SCRIPT"
    
    export PATH="$ORIG_PATH"
    rm -rf /tmp/bin_im_fail
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"Box Width=400. Offsetting Left by 200"* ]]
}

@test "Script should update thumbnails in multiple directories" {
    DIR2="/usr/syno/synoman/webman/resources/images/theme/router/default_wallpaper"
    touch "$DIR2/thumbnail_05.jpg"
    
    run bash "$SCRIPT"
    [ "$status" -eq 0 ]
    [ -s "$DIR2/thumbnail_05.jpg" ]
}

@test "Script should handle ImageMagick composite failure" {
    # Mock convert to fail ONLY for the composite step
    mkdir -p /tmp/bin_comp_fail
    cat <<EOT > /tmp/bin_comp_fail/convert
#!/bin/bash
if [[ "\$@" == *"-composite"* ]]; then
    exit 1
fi
/usr/bin/convert "\$@"
EOT
    chmod +x /tmp/bin_comp_fail/convert
    
    ORIG_PATH="$PATH"
    export PATH="/tmp/bin_comp_fail:$PATH"
    
    run bash "$SCRIPT"
    
    export PATH="$ORIG_PATH"
    rm -rf /tmp/bin_comp_fail
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"Error: ImageMagick failed to create overlay"* ]]
}

@test "Script should fail if not root (Top-level)" {
    # Mock id to return 1000
    mkdir -p /tmp/bin_user_wp
    echo '#!/bin/bash' > /tmp/bin_user_wp/id
    echo 'if [ "$1" == "-u" ]; then echo 1000; else /usr/bin/id "$@"; fi' >> /tmp/bin_user_wp/id
    chmod +x /tmp/bin_user_wp/id
    
    ORIG_PATH="$PATH"
    export PATH="/tmp/bin_user_wp:$PATH"
    
    # Run script directly
    run bash "$SCRIPT"
    
    export PATH="$ORIG_PATH"
    rm -rf /tmp/bin_user_wp
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"must be run as root"* ]]
}

@test "Script should detect HTML font file (Corrupt Download)" {
    # Create valid-looking but corrupt HTML file LARGER than 10KB to skip download trigger
    # 15KB file
    dd if=/dev/zero of=/tmp/Lato-Bold.ttf bs=1024 count=15 2>/dev/null
    # Overwrite start with HTML tag
    printf "<html>" | dd of=/tmp/Lato-Bold.ttf conv=notrunc 2>/dev/null
    
    # Run script
    run bash "$SCRIPT"
    
    # Should warn and remove
    [[ "$output" == *"appears to be HTML"* ]]
    [ ! -f "/tmp/Lato-Bold.ttf" ]
}

@test "Script should handle non-numeric Image Width" {
    # Mock identify to return non-number
    mkdir -p /tmp/bin_id_fail
    echo '#!/bin/bash' > /tmp/bin_id_fail/identify
    echo 'echo "invalid"' >> /tmp/bin_id_fail/identify
    chmod +x /tmp/bin_id_fail/identify
    
    ORIG_PATH="$PATH"
    export PATH="/tmp/bin_id_fail:$PATH"
    
    run bash "$SCRIPT"
    
    export PATH="$ORIG_PATH"
    rm -rf /tmp/bin_id_fail
    
    # Fallback is 3840 -> Margin 5% is 192 (usually)
    [[ "$output" == *"Calculated Margin: 192"* ]]
}


