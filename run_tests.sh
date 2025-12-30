#!/bin/bash
set -e

# Internal Test Runner (runs inside Docker container)

# Default to running all if no flags provided
UNIT=false
COMPONENT=false
E2E=false
HAS_FLAG=false

for arg in "$@"; do
    case "$arg" in
        --unit-only)
            UNIT=true
            HAS_FLAG=true
            ;;
        --component-only)
            COMPONENT=true
            HAS_FLAG=true
            ;;
        --e2e-only)
            E2E=true
            HAS_FLAG=true
            ;;
        --unit-install)
            UNIT_INSTALL=true
            HAS_FLAG=true
            ;;
        --unit-uninstall)
            UNIT_UNINSTALL=true
            HAS_FLAG=true
            ;;
        --unit-wallpaper)
            UNIT_WALLPAPER=true
            HAS_FLAG=true
            ;;
        --installer-only) # Backward compatibility
            UNIT=true
            HAS_FLAG=true
            ;;
    esac
done

if [ "$HAS_FLAG" = "false" ]; then
    UNIT=true
    COMPONENT=true
    E2E=true
fi

COVERAGE_OUTPUT=${COVERAGE_OUTPUT:-"/home/pi/coverage"}
mkdir -p "$COVERAGE_OUTPUT"

# Helper to run tests with or without coverage
run_bats_suite() {
    TYPE=$1
    PATTERN=$2
    shift 2
    TEST_FILES="$*"

    echo "Running $TYPE Tests..."

    if [ "$COVERAGE" = "1" ]; then
        # Ensure kcov output dir exists
        mkdir -p "$COVERAGE_OUTPUT/$TYPE"
        
        # shellcheck disable=SC2086
        kcov --include-pattern="$PATTERN" \
             "$COVERAGE_OUTPUT/$TYPE" \
             bats $TEST_FILES
    else
        # shellcheck disable=SC2086
        bats $TEST_FILES
    fi
}

if [ "$UNIT" = "true" ] || [ "$UNIT_INSTALL" = "true" ]; then
    run_bats_suite "unit/install" "/app" tests/install.bats
fi

if [ "$UNIT" = "true" ] || [ "$UNIT_UNINSTALL" = "true" ]; then
    run_bats_suite "unit/uninstall" "/app" tests/uninstall.bats
fi

if [ "$UNIT" = "true" ] || [ "$UNIT_WALLPAPER" = "true" ]; then
    run_bats_suite "unit/wallpaper" "/app" tests/wallpaper.bats
fi

if [ "$COMPONENT" = "true" ]; then
    run_bats_suite "component" "/app" tests/component.bats
fi

if [ "$E2E" = "true" ]; then
    # E2E tests
    run_bats_suite "e2e" "bing_wallpaper_auto_update.sh,install.sh,uninstall.sh" \
        tests/e2e_tests.bats
fi

if [ "$COVERAGE" = "1" ] && [ "$UNIT" = "true" ] && [ "$E2E" = "true" ]; then
    echo "Merging Coverage Reports..."
    mkdir -p "$COVERAGE_OUTPUT/final"
    kcov --merge "$COVERAGE_OUTPUT/final" \
         "$COVERAGE_OUTPUT/unit/install" \
         "$COVERAGE_OUTPUT/unit/uninstall" \
         "$COVERAGE_OUTPUT/unit/wallpaper" \
         "$COVERAGE_OUTPUT/component" \
         "$COVERAGE_OUTPUT/e2e"
    
    if [ -f "$COVERAGE_OUTPUT/final/cobertura.xml" ]; then
        echo "Updating coverage badge..."
        python3 tests/transform_coverage.py "$COVERAGE_OUTPUT/final/cobertura.xml"
    fi
    echo "Coverage Report generated at: $COVERAGE_OUTPUT/final/index.html"
fi

echo "All requested tests execution completed."
