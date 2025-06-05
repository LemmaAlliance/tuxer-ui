#!/bin/bash
# Test script to run Tuxer-UI on a headless system using Xvfb
# and verify if a window is created.
set -e

# Build the project
make > /tmp/build.log 2>&1

# Start virtual X server
XVFB_DISPLAY=:99
if ! command -v Xvfb >/dev/null; then
    echo "Xvfb not found, attempting to install..."
    sudo apt-get update && sudo apt-get install -y xvfb x11-utils >/tmp/xvfb_install.log 2>&1
fi
rm -f /tmp/.X99-lock
Xvfb $XVFB_DISPLAY -screen 0 1024x768x24 -ac > /tmp/xvfb.log 2>&1 &
XVFB_PID=$!

# Wait for Xvfb to start
sleep 2
export DISPLAY=$XVFB_DISPLAY

# Run the application
./build/main > /tmp/app.log 2>&1 &
APP_PID=$!
# Give it a moment to attempt to create a window
sleep 2

# Query windows
WINDOW_OUTPUT=$(xwininfo -root -tree 2>/dev/null)
echo "$WINDOW_OUTPUT" > /tmp/windows.log
# Cleanup
kill $APP_PID 2>/dev/null || true
kill $XVFB_PID 2>/dev/null || true

# Count child windows
CHILD_COUNT=$(echo "$WINDOW_OUTPUT" | grep -Eo '^[[:space:]]+[0-9]+ children' | awk '{print $1}')

if [ -n "$CHILD_COUNT" ] && [ "$CHILD_COUNT" -gt 0 ]; then
    echo "Window detected."
    exit 0
else
    echo "No window detected." >&2
    cat /tmp/app.log >&2
    exit 1
fi
