#!/bin/sh
# Build all projects and package them into tar.zst archives

# Projects to build
PROJECTS="BootEnvironments Display GlobalShortcuts StartupDisk LoginWindow globalshortcutsd"

export CC=clang
export OBJC=clang
export OBJCXX=clang++
export CXX=clang++

HERE="$(dirname "$(readlink -f "$0")")"

echo "Building all preference panes and tools..."

# Install build dependencies
echo "Installing build dependencies..."
sudo pkg install -y gnustep-make gnustep-base gnustep-gui gnustep-back gmake systempreferences || {
    echo "Error: Failed to install build dependencies"
    exit 1
}
echo "Build dependencies installed successfully"
echo ""

# If GNUSTEP_MAKEFILES is not set, source GNUstep.sh to set it up
if [ -z "$GNUSTEP_MAKEFILES" ]; then
    . /usr/local/GNUstep/System/Library/Makefiles/GNUstep.sh
fi

# Debug: Show GNUstep environment
echo "GNUstep environment:"
echo "  GNUSTEP_MAKEFILES=$GNUSTEP_MAKEFILES"
echo "  GNUSTEP_SYSTEM_HEADERS=$GNUSTEP_SYSTEM_HEADERS"
echo "  GNUSTEP_SYSTEM_LIBRARIES=$GNUSTEP_SYSTEM_LIBRARIES"
echo ""

# Check for PreferencePanes framework
if [ -d "/System/Library/Frameworks/PreferencePanes.framework" ]; then
    echo "Found PreferencePanes framework in /System/Library/Frameworks/"
elif [ -d "$GNUSTEP_SYSTEM_HEADERS/PreferencePanes" ]; then
    echo "Found PreferencePanes headers in $GNUSTEP_SYSTEM_HEADERS/PreferencePanes"
else
    echo "Warning: PreferencePanes framework not found, checking available frameworks..."
    echo "Available frameworks in /System/Library/Frameworks/:"
    ls -la /System/Library/Frameworks/ 2>/dev/null || echo "  Directory not found"
    echo "Available headers in $GNUSTEP_SYSTEM_HEADERS/:"
    ls -la "$GNUSTEP_SYSTEM_HEADERS/" 2>/dev/null || echo "  Directory not found"
fi
echo ""

# Ensure we're in the base directory
cd "$HERE"

SUCCESS_COUNT=0
FAIL_COUNT=0

for PROJECT in $PROJECTS; do
    echo "Building $PROJECT..."
    
    # Check if project directory exists
    if [ ! -d "$HERE/$PROJECT" ]; then
        echo "Warning: Directory $PROJECT does not exist in $HERE, skipping..."
        FAIL_COUNT=$((FAIL_COUNT + 1))
        continue
    fi
    
    cd "$HERE/$PROJECT"
    
    # Clean any existing root directory
    if [ -d root ]; then
        rm -rf root
    fi
    
    # Build and install with DESTDIR (continue on error)
    if gmake install DESTDIR=root; then
        # Create tar.zst archive if root directory exists
        if [ -d root ]; then
            echo "Creating ${PROJECT}.tar.zst..."
            (cd root && tar --zstd -cf "../${PROJECT}.tar.zst" .)
            echo "Created ${PROJECT}.tar.zst"
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        else
            echo "Warning: No root directory created for $PROJECT"
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    else
        echo "Error: Failed to build $PROJECT"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
    
    echo "Finished $PROJECT"
    echo ""
done

echo "Build summary:"
echo "  Successful: $SUCCESS_COUNT"
echo "  Failed: $FAIL_COUNT"
echo ""

# Create out directory and collect all zst files
echo "Collecting archives into out/ directory..."
mkdir -p "$HERE/out"

COLLECTED_COUNT=0
for PROJECT in $PROJECTS; do
    if [ -f "$HERE/$PROJECT/${PROJECT}.tar.zst" ]; then
        echo "  Copying ${PROJECT}.tar.zst to out/"
        cp "$HERE/$PROJECT/${PROJECT}.tar.zst" "$HERE/out/"
        COLLECTED_COUNT=$((COLLECTED_COUNT + 1))
    fi
done

echo ""
echo "Archives collected in out/ directory: $COLLECTED_COUNT"
if [ "$COLLECTED_COUNT" -gt 0 ]; then
    echo "Contents of out/:"
    ls -la "$HERE/out/"*.tar.zst 2>/dev/null | while read -r line; do
        echo "  $line"
    done
fi