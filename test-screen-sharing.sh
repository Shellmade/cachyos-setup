#!/bin/bash

echo "Testing Screen Sharing Setup"
echo "============================"
echo

echo "1. Checking Portal Services:"
echo "----------------------------"
systemctl --user status xdg-desktop-portal.service --no-pager -l
echo

echo "2. Checking PipeWire Services:"
echo "------------------------------"
systemctl --user status pipewire.service --no-pager -l
echo

echo "3. Current Environment:"
echo "----------------------"
echo "XDG_CURRENT_DESKTOP: $XDG_CURRENT_DESKTOP"
echo "XDG_SESSION_TYPE: $XDG_SESSION_TYPE"
echo "XDG_SESSION_DESKTOP: $XDG_SESSION_DESKTOP"
echo "WAYLAND_DISPLAY: $WAYLAND_DISPLAY"
echo

echo "4. Portal Configuration:"
echo "------------------------"
cat ~/.config/xdg-desktop-portal/portals.conf
echo

echo "5. GTK CSS Check:"
echo "-----------------"
if grep -q "screen-sharing-active" ~/.config/gtk-3.0/gtk.css 2>/dev/null; then
    echo "✓ Red border CSS is configured"
else
    echo "✗ Red border CSS not found"
fi
echo

echo "6. Testing Screen Sharing:"
echo "-------------------------"
echo "To test the red border functionality:"
echo "  1. Open Teams, Zoom, or Chrome"
echo "  2. Start a meeting and share your screen"
echo "  3. Look for:"
echo "     - Red border around the shared window"
echo "     - Red recording indicator in the top panel"
echo "     - Desktop notification about screen sharing"
echo

echo "If you don't see the red border immediately:"
echo "  - Try logging out and back in"
echo "  - Restart the application"
echo "  - Check that the application is using Wayland (not X11)"