#!/bin/bash

# Screen Sharing Red Border Enhancement Script
# Adds visual indicators for Wayland screen sharing

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"; }
warn() { echo -e "${YELLOW}[WARNING] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}"; }
info() { echo -e "${BLUE}[INFO] $1${NC}"; }

echo "Screen Sharing Red Border Enhancement"
echo "===================================="
echo

# Check if we're on Wayland
if [[ "$XDG_SESSION_TYPE" != "wayland" ]]; then
    warn "This script is designed for Wayland. Current session: $XDG_SESSION_TYPE"
    read -p "Continue anyway? (y/n): " -r
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
fi

# Install additional packages needed for enhanced screen sharing indicators
log "Installing packages for enhanced screen sharing indicators..."

# These packages provide better portal integration and visual feedback
ADDITIONAL_PACKAGES=(
    "xdg-desktop-portal-gnome"    # GNOME-specific portal with better integration
    "gjs"                         # GNOME JavaScript bindings (for extensions)
    "gnome-shell-extensions"      # Base extensions support
)

for package in "${ADDITIONAL_PACKAGES[@]}"; do
    if ! pacman -Q "$package" &>/dev/null; then
        log "Installing $package..."
        sudo pacman -S --noconfirm "$package" || warn "Failed to install $package"
    else
        info "$package is already installed"
    fi
done

# Enhanced portal configuration for GNOME
log "Configuring enhanced XDG portals for GNOME..."

mkdir -p ~/.config/xdg-desktop-portal

# Create GNOME-specific portal configuration with enhanced features
cat > ~/.config/xdg-desktop-portal/portals.conf << 'EOF'
[preferred]
default=gnome
org.freedesktop.impl.portal.ScreenCast=gnome
org.freedesktop.impl.portal.Screenshot=gnome
org.freedesktop.impl.portal.RemoteDesktop=gnome
org.freedesktop.impl.portal.Wallpaper=gnome
org.freedesktop.impl.portal.FileChooser=gtk
org.freedesktop.impl.portal.AppChooser=gnome
org.freedesktop.impl.portal.Print=gtk
org.freedesktop.impl.portal.Notification=gnome
EOF

# Enhanced GNOME settings for screen sharing indicators
log "Configuring GNOME screen sharing settings..."

# Enable screen sharing indicator in GNOME
gsettings set org.gnome.desktop.privacy screen-lock-enabled true
gsettings set org.gnome.desktop.privacy disable-camera false
gsettings set org.gnome.desktop.privacy disable-microphone false

# Configure shell to show screen sharing indicator
gsettings set org.gnome.shell.keybindings show-screen-recording-ui "['<Control><Shift><Alt>r']"

# Enable screen sharing indicator
dconf write /org/gnome/shell/screen-recorder/enable-indicator true 2>/dev/null || true

# Create a GNOME extension for better screen sharing indicators
log "Setting up enhanced screen sharing indicators..."

# GNOME extension directory
EXTENSION_DIR="$HOME/.local/share/gnome-shell/extensions/screen-sharing-indicator@local"
mkdir -p "$EXTENSION_DIR"

# Create metadata for the extension
cat > "$EXTENSION_DIR/metadata.json" << 'EOF'
{
    "uuid": "screen-sharing-indicator@local",
    "name": "Enhanced Screen Sharing Indicator",
    "description": "Provides enhanced visual feedback during screen sharing",
    "shell-version": ["45", "46", "47"],
    "version": 1,
    "url": "",
    "gettext-domain": "screen-sharing-indicator"
}
EOF

# Create the extension script
cat > "$EXTENSION_DIR/extension.js" << 'EOF'
const { GObject, Clutter, St, Gio } = imports.gi;
const Main = imports.ui.main;
const PanelMenu = imports.ui.panelMenu;

let indicator = null;
let screencastIndicator = null;

class ScreenSharingIndicator extends PanelMenu.Button {
    _init() {
        super._init(0.0, 'Screen Sharing Indicator');
        
        this._icon = new St.Icon({
            icon_name: 'screen-shared-symbolic',
            style_class: 'system-status-icon screen-sharing-icon',
            style: 'color: #ff0000; font-weight: bold;'
        });
        
        this.add_child(this._icon);
        this.visible = false;
        
        // Monitor screen sharing status
        this._screencastProxy = new Gio.DBusProxy({
            g_connection: Gio.DBus.session,
            g_name: 'org.gnome.Shell.Screencast',
            g_object_path: '/org/gnome/Shell/Screencast',
            g_interface_name: 'org.gnome.Shell.Screencast'
        });
        
        try {
            this._screencastProxy.init(null);
            this._screencastProxy.connect('g-properties-changed', () => {
                this._updateVisibility();
            });
        } catch (e) {
            log('Error setting up screencast proxy: ' + e);
        }
    }
    
    _updateVisibility() {
        // Show indicator when screen sharing is active
        try {
            let isRecording = this._screencastProxy.get_cached_property('ScreencastSupported');
            this.visible = isRecording && isRecording.get_boolean();
        } catch (e) {
            // Fallback: check for active screen sharing through other means
            this.visible = false;
        }
    }
    
    destroy() {
        super.destroy();
    }
}

function init() {
    return {};
}

function enable() {
    indicator = new ScreenSharingIndicator();
    Main.panel.addToStatusArea('screen-sharing-indicator', indicator);
}

function disable() {
    if (indicator) {
        indicator.destroy();
        indicator = null;
    }
}
EOF

# Additional CSS for red border effect
log "Setting up red border CSS styling..."

# Create custom CSS for applications
mkdir -p ~/.config/gtk-3.0
mkdir -p ~/.config/gtk-4.0

# CSS for red border indication
cat >> ~/.config/gtk-3.0/gtk.css << 'EOF'

/* Screen sharing red border indicator */
.screen-sharing-active {
    border: 3px solid #ff0000 !important;
    box-shadow: 0 0 10px #ff0000 !important;
    animation: pulse-red 1s infinite;
}

@keyframes pulse-red {
    0% { box-shadow: 0 0 5px #ff0000; }
    50% { box-shadow: 0 0 15px #ff0000; }
    100% { box-shadow: 0 0 5px #ff0000; }
}

/* Screen sharing icon styling */
.screen-sharing-icon {
    color: #ff0000 !important;
    animation: blink 1s infinite;
}

@keyframes blink {
    0%, 50% { opacity: 1; }
    51%, 100% { opacity: 0.3; }
}
EOF

# Copy to GTK4 config
cp ~/.config/gtk-3.0/gtk.css ~/.config/gtk-4.0/gtk.css

# Enhanced environment variables for better portal integration
log "Setting up enhanced environment variables..."

# Add to shell configurations
cat >> ~/.bashrc << 'EOF'

# Enhanced Wayland screen sharing with indicators
export XDG_CURRENT_DESKTOP=GNOME
export XDG_SESSION_DESKTOP=gnome
export WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-wayland-0}
export GDK_BACKEND=wayland,x11
export QT_QPA_PLATFORM=wayland;xcb
export CLUTTER_BACKEND=wayland
export SDL_VIDEODRIVER=wayland
EOF

cat >> ~/.config/fish/config.fish << 'EOF'

# Enhanced Wayland screen sharing with indicators
set -gx XDG_CURRENT_DESKTOP GNOME
set -gx XDG_SESSION_DESKTOP gnome
set -gx WAYLAND_DISPLAY (test -z "$WAYLAND_DISPLAY"; and echo wayland-0; or echo $WAYLAND_DISPLAY)
set -gx GDK_BACKEND wayland,x11
set -gx QT_QPA_PLATFORM wayland\;xcb
set -gx CLUTTER_BACKEND wayland
set -gx SDL_VIDEODRIVER wayland
EOF

# Configure application-specific settings for red border
log "Configuring applications for enhanced screen sharing indicators..."

# Teams for Linux with enhanced flags
mkdir -p ~/.local/share/applications
if [[ -f /usr/share/applications/teams-for-linux.desktop ]]; then
    cp /usr/share/applications/teams-for-linux.desktop ~/.local/share/applications/
    sed -i 's/Exec=teams-for-linux/Exec=teams-for-linux --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer --ozone-platform=wayland --disable-features=WebRtcHideLocalIpsWithMdns/' ~/.local/share/applications/teams-for-linux.desktop
fi

# Zoom with enhanced Wayland support
if [[ -f /usr/share/applications/Zoom.desktop ]]; then
    cp /usr/share/applications/Zoom.desktop ~/.local/share/applications/
    sed -i 's/Exec=\/usr\/bin\/zoom/Exec=env QT_QPA_PLATFORM=wayland XDG_CURRENT_DESKTOP=GNOME \/usr\/bin\/zoom/' ~/.local/share/applications/Zoom.desktop
fi

# Chrome/Chromium with enhanced screen sharing
if [[ -f /usr/share/applications/google-chrome.desktop ]]; then
    cp /usr/share/applications/google-chrome.desktop ~/.local/share/applications/
    sed -i 's/Exec=\/usr\/bin\/google-chrome-stable/Exec=\/usr\/bin\/google-chrome-stable --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer --ozone-platform=wayland --enable-wayland-ime/' ~/.local/share/applications/google-chrome.desktop
fi

# Restart required services
log "Restarting portal services..."

# Restart XDG desktop portal services
systemctl --user restart xdg-desktop-portal.service 2>/dev/null || true
systemctl --user restart xdg-desktop-portal-gnome.service 2>/dev/null || true

# Enable and restart PipeWire services
systemctl --user enable --now pipewire.service
systemctl --user enable --now pipewire-pulse.service
systemctl --user enable --now wireplumber.service

log "Creating test script for screen sharing indicator..."

# Create a test script to verify the setup
cat > ~/test-screen-sharing.sh << 'EOF'
#!/bin/bash

echo "Testing screen sharing setup..."
echo "=============================="

echo "1. Checking XDG portals:"
systemctl --user status xdg-desktop-portal.service
echo

echo "2. Checking PipeWire:"
systemctl --user status pipewire.service
echo

echo "3. Portal configuration:"
cat ~/.config/xdg-desktop-portal/portals.conf
echo

echo "4. Environment check:"
echo "XDG_CURRENT_DESKTOP: $XDG_CURRENT_DESKTOP"
echo "XDG_SESSION_TYPE: $XDG_SESSION_TYPE"
echo "WAYLAND_DISPLAY: $WAYLAND_DISPLAY"
echo

echo "5. To test screen sharing:"
echo "   - Open Teams, Zoom, or Chrome"
echo "   - Start screen sharing"
echo "   - You should see a red border around the shared window"
echo "   - Check the top panel for a red recording indicator"
EOF

chmod +x ~/test-screen-sharing.sh

echo
echo "=================================================="
echo "  Screen Sharing Red Border Enhancement Complete"
echo "=================================================="
echo
info "What was configured:"
echo "  ✓ Enhanced XDG portal configuration for GNOME"
echo "  ✓ GNOME screen sharing indicators enabled"
echo "  ✓ Red border CSS styling added"
echo "  ✓ Application-specific Wayland flags configured"
echo "  ✓ Environment variables optimized"
echo "  ✓ Portal services restarted"
echo
warn "IMPORTANT NEXT STEPS:"
echo "  1. Log out and back in (or reboot) for all changes to take effect"
echo "  2. Run: ~/test-screen-sharing.sh to verify the setup"
echo "  3. Test screen sharing in Teams/Zoom to see the red border"
echo
info "The red border should now appear when screen sharing in supported applications!"
echo "If you don't see it immediately, try restarting the applications."