#!/bin/bash

echo "Testing GNOME Screen Sharing Indicators"
echo "======================================"

# Check if we can access the GNOME screen recording portal
echo "1. Testing portal access..."
gdbus introspect --session --dest org.freedesktop.portal.Desktop --object-path /org/freedesktop/portal/desktop 2>/dev/null | grep -i screencast && echo "✓ ScreenCast portal accessible" || echo "✗ ScreenCast portal not accessible"

echo
echo "2. Testing screen sharing detection..."

# Create a simple script to monitor screen sharing
cat > /tmp/monitor_screenshare.py << 'EOF'
#!/usr/bin/env python3
import gi
gi.require_version('Gdk', '4.0')
from gi.repository import Gdk, GLib
import subprocess
import sys

def check_screen_sharing():
    try:
        # Check if any screen sharing processes are running
        result = subprocess.run(['pgrep', '-f', 'pipewire.*screencast'], capture_output=True, text=True)
        if result.returncode == 0:
            print("🔴 Screen sharing detected!")
            return True
        else:
            print("⚪ No screen sharing detected")
            return False
    except Exception as e:
        print(f"Error: {e}")
        return False

def main():
    print("Monitoring screen sharing... (Ctrl+C to stop)")
    try:
        while True:
            check_screen_sharing()
            GLib.timeout_add_seconds(2, lambda: None)
            GLib.MainLoop().run()
    except KeyboardInterrupt:
        print("\nStopping monitor...")

if __name__ == "__main__":
    main()
EOF

chmod +x /tmp/monitor_screenshare.py

echo "3. Starting screen share monitor..."
echo "   Open Teams/Zoom in another terminal and start screen sharing"
echo "   This script will detect when screen sharing is active"
echo
echo "Run: python3 /tmp/monitor_screenshare.py"
echo
echo "4. Testing native GNOME indicators..."

# Check if GNOME has native screen recording indicators
if dbus-send --session --dest=org.gnome.Shell --type=method_call --print-reply /org/gnome/Shell org.gnome.Shell.Eval string:"global.display.get_n_monitors()" 2>/dev/null; then
    echo "✓ GNOME Shell D-Bus accessible"
else
    echo "✗ GNOME Shell D-Bus not accessible"
fi

echo
echo "5. Manual test instructions:"
echo "   1. Open Chrome/Teams/Zoom"
echo "   2. Start a meeting and share screen"
echo "   3. Look for:"
echo "      - Orange/red dot in top panel (GNOME native indicator)"
echo "      - Notification about screen sharing"
echo "      - Recording symbol in top-right corner"
echo
echo "GNOME 49 should show native indicators automatically!"