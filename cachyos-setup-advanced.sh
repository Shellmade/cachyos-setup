#!/bin/bash

# CachyOS Advanced Setup Script
# Author: Auto-generated setup script
# Date: $(date +"%Y-%m-%d")
# Description: Automated package installation and system configuration for CachyOS

set -e  # Exit on any error

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/packages.conf"

# Dry run mode
DRY_RUN=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run|--dryrun|-d)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            echo "CachyOS Advanced Setup Script"
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run, -d    Show what would be done without making changes"
            echo "  --help, -h       Show this help message"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

success() {
    echo -e "${CYAN}[SUCCESS] $1${NC}"
}

# Snapshot management
create_snapshot() {
    local description="$1"
    if command -v snapper &> /dev/null && [[ "$DRY_RUN" == false ]]; then
        log "Creating system snapshot: $description"
        sudo snapper create --description "$description" || warn "Failed to create snapshot"
    fi
}

# Disable automatic snapshots during installation
disable_auto_snapshots() {
    if [[ "$DRY_RUN" == false ]] && systemctl is-active --quiet limine-snapper-sync.service; then
        log "Temporarily disabling automatic snapshots during installation"
        sudo systemctl stop limine-snapper-sync.service || true
    fi
}

# Re-enable automatic snapshots
enable_auto_snapshots() {
    if [[ "$DRY_RUN" == false ]] && ! systemctl is-active --quiet limine-snapper-sync.service; then
        log "Re-enabling automatic snapshots"
        sudo systemctl start limine-snapper-sync.service || true
    fi
}
dry_run_execute() {
    local command="$1"
    local description="$2"
    
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${PURPLE}[DRY RUN] Would execute: $description${NC}"
        echo -e "${BLUE}  Command: $command${NC}"
        return 0
    else
        log "$description"
        eval "$command"
    fi
}

# Progress tracking
TOTAL_OPERATIONS=0
CURRENT_OPERATION=0
SCRIPT_START_TIME=""

# Simple progress bar
show_progress() {
    local current=$1
    local total=$2
    local operation="$3"
    
    if [[ $total -eq 0 ]]; then
        return
    fi
    
    local percent=$((current * 100 / total))
    local filled=$((current * 50 / total))
    local empty=$((50 - filled))
    
    printf "\r\033[K"  # Clear line
    printf "Progress: ["
    printf "%*s" $filled | tr ' ' '█'
    printf "%*s" $empty | tr ' ' '░'
    printf "] %3d%% - %s" $percent "$operation"
    
    if [[ $current -eq $total ]]; then
        printf "\n"
    fi
}

# Update progress
update_progress() {
    CURRENT_OPERATION=$((CURRENT_OPERATION + 1))
    show_progress $CURRENT_OPERATION $TOTAL_OPERATIONS "$1"
}

# Count total operations
count_operations() {
    TOTAL_OPERATIONS=0
    
    # Always count these
    TOTAL_OPERATIONS=$((TOTAL_OPERATIONS + 1))  # System update
    TOTAL_OPERATIONS=$((TOTAL_OPERATIONS + 1))  # AUR helper
    
    # Count packages
    if [[ "${#OFFICIAL_PACKAGES[@]}" -gt 0 ]]; then
        for package in "${OFFICIAL_PACKAGES[@]}"; do
            [[ "$package" =~ ^#.*$ ]] || [[ -z "$package" ]] && continue
            TOTAL_OPERATIONS=$((TOTAL_OPERATIONS + 1))
        done
    fi
    
    if [[ "${#AUR_PACKAGES[@]}" -gt 0 ]]; then
        for package in "${AUR_PACKAGES[@]}"; do
            [[ "$package" =~ ^#.*$ ]] || [[ -z "$package" ]] && continue
            TOTAL_OPERATIONS=$((TOTAL_OPERATIONS + 1))
        done
    fi
    
    # Add other operations
    TOTAL_OPERATIONS=$((TOTAL_OPERATIONS + 5))  # Services, directories, wayland, defaults, cleanup
}

step() {
    update_progress "$1"
}

# Load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        info "Loading configuration from $CONFIG_FILE"
        source "$CONFIG_FILE"
    else
        warn "Configuration file not found at $CONFIG_FILE"
        warn "Using default package lists..."
    fi
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root!"
        error "Run as regular user with sudo privileges"
        exit 1
    fi
}

# Check if sudo is available and cache credentials
check_sudo() {
    if [[ "$DRY_RUN" == false ]]; then
        if ! sudo -n true 2>/dev/null; then
            info "This script requires sudo privileges for package installation"
            info "Please enter your password once to cache credentials for the entire session:"
            sudo -v
            
            # Keep sudo alive throughout the script execution
            while true; do
                sudo -n true
                sleep 60
                kill -0 "$$" || exit
            done 2>/dev/null &
            
            success "Sudo credentials cached for the session"
        fi
    fi
}

# Update system
update_system() {
    step "Updating system packages"
    dry_run_execute "sudo pacman -Syu --noconfirm" "Update all system packages"
}

# Install AUR helper (yay)
install_aur_helper() {
    step "Installing AUR helper"
    if ! command -v yay &> /dev/null; then
        dry_run_execute "sudo pacman -S --needed --noconfirm base-devel git" "Install build dependencies"
        dry_run_execute "cd /tmp && git clone https://aur.archlinux.org/yay.git" "Clone yay repository"
        dry_run_execute "cd /tmp/yay && makepkg -si --noconfirm" "Build and install yay"
        dry_run_execute "rm -rf /tmp/yay" "Clean up yay build directory"
    fi
}

# Install official packages
install_official_packages() {
    for package in "${OFFICIAL_PACKAGES[@]}"; do
        [[ "$package" =~ ^#.*$ ]] || [[ -z "$package" ]] && continue
        
        step "Installing $package"
        
        if [[ "$DRY_RUN" == true ]]; then
            continue
        fi
        
        if pacman -Q "$package" &> /dev/null; then
            continue
        else
            if ! sudo pacman -S --noconfirm "$package" &>/dev/null; then
                warn "Failed to install $package"
            fi
        fi
    done
}

# Install AUR packages  
install_aur_packages() {
    for package in "${AUR_PACKAGES[@]}"; do
        [[ "$package" =~ ^#.*$ ]] || [[ -z "$package" ]] && continue
        
        step "Installing $package (AUR)"
        
        if [[ "$DRY_RUN" == true ]]; then
            continue
        fi
        
        if pacman -Q "$package" &> /dev/null; then
            continue
        else
            if ! yay -S --noconfirm "$package" &>/dev/null; then
                warn "Failed to install $package"
            fi
        fi
    done
}



# Enable services
enable_services() {
    if [[ "$DRY_RUN" == true ]]; then
        return
    fi
    
    for service in "${SERVICES[@]}"; do
        [[ "$service" =~ ^#.*$ ]] || [[ -z "$service" ]] && continue
        
        if systemctl is-enabled "$service" &> /dev/null; then
            continue
        else
            if sudo systemctl enable "$service" &>/dev/null; then
                if ! systemctl is-active --quiet "$service"; then
                    sudo systemctl start "$service" &>/dev/null || true
                fi
            fi
        fi
    done
}





# Install Node.js packages
install_node_packages() {
    step "Installing Node.js packages"
    
    local installed_count=0
    
    for package in "${NODE_PACKAGES[@]}"; do
        [[ "$package" =~ ^#.*$ ]] || [[ -z "$package" ]] && continue
        
        log "Installing Node.js package: $package"
        if npm install -g "$package"; then
            installed_count=$((installed_count + 1))
        else
            warn "Failed to install Node.js package: $package"
        fi
    done
    
    success "Installed $installed_count Node.js packages"
}

# Configure Wayland screen sharing
configure_wayland_screensharing() {
    step "Configuring Wayland screen sharing"
    
    # Add user to necessary groups for media access and screen sharing
    log "Adding user to required groups for screen sharing..."
    
    # Groups needed for Wayland screen sharing and media access
    MEDIA_GROUPS=("video" "audio" "input" "render")
    
    for group in "${MEDIA_GROUPS[@]}"; do
        if getent group "$group" > /dev/null 2>&1; then
            if ! groups "$USER" | grep -q "\b$group\b"; then
                sudo usermod -aG "$group" "$USER"
                log "Added $USER to $group group"
            else
                info "$USER is already in $group group"
            fi
        else
            warn "Group $group does not exist on this system"
        fi
    done
    
    # Install enhanced portal packages for better screen sharing
    log "Installing enhanced portal packages for screen sharing..."
    PORTAL_PACKAGES=("xdg-desktop-portal-gnome" "gjs")
    
    for package in "${PORTAL_PACKAGES[@]}"; do
        if ! pacman -Q "$package" &>/dev/null; then
            if ! sudo pacman -S --noconfirm "$package" &>/dev/null; then
                warn "Failed to install $package - continuing anyway"
            fi
        fi
    done
    
    # Create XDG portal configuration directory
    mkdir -p ~/.config/xdg-desktop-portal
    
    # Create enhanced portal configuration for screen sharing
    log "Setting up enhanced XDG desktop portal configuration..."
    
    # Detect desktop environment and configure accordingly
    if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
        # GNOME-specific configuration with enhanced indicators
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
    else
        # Generic Wayland configuration
        cat > ~/.config/xdg-desktop-portal/portals.conf << 'EOF'
[preferred]
default=gtk
org.freedesktop.impl.portal.ScreenCast=wlr
org.freedesktop.impl.portal.Screenshot=wlr
org.freedesktop.impl.portal.Wallpaper=gtk
org.freedesktop.impl.portal.FileChooser=gtk
EOF
    fi

    # Ensure PipeWire is properly configured
    log "Configuring PipeWire for screen sharing..."
    
    # Enable and start PipeWire services
    systemctl --user enable pipewire.service
    systemctl --user enable pipewire-pulse.service
    systemctl --user enable wireplumber.service
    
    # Create PipeWire configuration directory if it doesn't exist
    mkdir -p ~/.config/pipewire
    
    # Configure GNOME settings for screen sharing indicators (if on GNOME)
    if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
        log "Configuring GNOME screen sharing settings..."
        
        # Enable screen sharing permissions in GNOME
        gsettings set org.gnome.desktop.screensaver lock-enabled true 2>/dev/null || true
        gsettings set org.gnome.desktop.privacy disable-camera false 2>/dev/null || true
        gsettings set org.gnome.desktop.privacy disable-microphone false 2>/dev/null || true
        
        # Enable screen recording indicator
        dconf write /org/gnome/shell/screen-recorder/enable-indicator true 2>/dev/null || true
    fi
    
    # Add environment variables for Wayland screen sharing
    log "Setting up environment variables..."
    
    # Create or update shell configurations
    mkdir -p ~/.config/fish
    
    # Enhanced environment variables for better portal integration
    cat >> ~/.bashrc << 'EOF'

# Enhanced Wayland screen sharing environment variables
export XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP:-wayland}
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=${XDG_SESSION_DESKTOP:-gnome}
export QT_QPA_PLATFORM=wayland
export GDK_BACKEND=wayland
export MOZ_ENABLE_WAYLAND=1
export CLUTTER_BACKEND=wayland
export SDL_VIDEODRIVER=wayland
EOF

    cat >> ~/.config/fish/config.fish << 'EOF'

# Enhanced Wayland screen sharing environment variables
set -gx XDG_CURRENT_DESKTOP (test -z "$XDG_CURRENT_DESKTOP"; and echo wayland; or echo $XDG_CURRENT_DESKTOP)
set -gx XDG_SESSION_TYPE wayland
set -gx XDG_SESSION_DESKTOP (test -z "$XDG_SESSION_DESKTOP"; and echo gnome; or echo $XDG_SESSION_DESKTOP)
set -gx QT_QPA_PLATFORM wayland
set -gx GDK_BACKEND wayland
set -gx MOZ_ENABLE_WAYLAND 1
set -gx CLUTTER_BACKEND wayland
set -gx SDL_VIDEODRIVER wayland
EOF

    # Create desktop entry for applications that need screen sharing
    log "Configuring applications for Wayland screen sharing..."
    
    # Create applications directory
    mkdir -p ~/.local/share/applications
    
    # Configure browser flags for better Wayland support
    if [[ -f /usr/share/applications/zen-browser.desktop ]]; then
        cp /usr/share/applications/zen-browser.desktop ~/.local/share/applications/
        sed -i 's/Exec=zen-browser/Exec=zen-browser --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer --ozone-platform=wayland --enable-wayland-ime/' ~/.local/share/applications/zen-browser.desktop 2>/dev/null || true
    fi
    
    # Teams for Linux Wayland flags with enhanced screen sharing
    if [[ -f /usr/share/applications/teams-for-linux.desktop ]]; then
        cp /usr/share/applications/teams-for-linux.desktop ~/.local/share/applications/
        sed -i 's/Exec=teams-for-linux/Exec=teams-for-linux --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer --ozone-platform=wayland --disable-features=WebRtcHideLocalIpsWithMdns/' ~/.local/share/applications/teams-for-linux.desktop 2>/dev/null || true
    fi
    
    # Slack Wayland flags
    if [[ -f /usr/share/applications/slack.desktop ]]; then
        cp /usr/share/applications/slack.desktop ~/.local/share/applications/
        sed -i 's/Exec=\/usr\/bin\/slack/Exec=\/usr\/bin\/slack --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer --ozone-platform=wayland/' ~/.local/share/applications/slack.desktop 2>/dev/null || true
    fi
    
    # Zoom Wayland flags
    if [[ -f /usr/share/applications/Zoom.desktop ]]; then
        cp /usr/share/applications/Zoom.desktop ~/.local/share/applications/
        sed -i 's/Exec=\/usr\/bin\/zoom/Exec=env QT_QPA_PLATFORM=wayland XDG_CURRENT_DESKTOP=GNOME \/usr\/bin\/zoom/' ~/.local/share/applications/Zoom.desktop 2>/dev/null || true
    fi
    
    # Chrome/Chromium with enhanced screen sharing
    if [[ -f /usr/share/applications/google-chrome.desktop ]]; then
        cp /usr/share/applications/google-chrome.desktop ~/.local/share/applications/
        sed -i 's/Exec=\/usr\/bin\/google-chrome-stable/Exec=\/usr\/bin\/google-chrome-stable --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer --ozone-platform=wayland --enable-wayland-ime/' ~/.local/share/applications/google-chrome.desktop 2>/dev/null || true
    fi
    
    # Restart portal services for enhanced integration
    log "Restarting portal services for enhanced screen sharing..."
    systemctl --user restart xdg-desktop-portal.service 2>/dev/null || true
    systemctl --user restart xdg-desktop-portal-gnome.service 2>/dev/null || true
    
    success "Wayland screen sharing configuration completed"
    warn "You MUST log out and back in (or reboot) for group changes to take effect"
    info "For OBS Studio, make sure to use 'PipeWire Audio Output Capture' and 'Screen Capture (PipeWire)'"
    info "Applications like Teams, Slack, and Zoom should now support screen sharing properly"
    
    # Create test script for verification
    cat > ~/test-screen-sharing.sh << 'EOF'
#!/bin/bash
echo "Testing screen sharing setup..."
echo "=============================="
echo "1. Portal services:"
systemctl --user status xdg-desktop-portal.service
echo "2. PipeWire status:"
systemctl --user status pipewire.service
echo "3. Environment:"
echo "XDG_CURRENT_DESKTOP: $XDG_CURRENT_DESKTOP"
echo "XDG_SESSION_TYPE: $XDG_SESSION_TYPE"
echo "4. To test: Start screen sharing in Teams/Zoom and check functionality"
EOF
    chmod +x ~/test-screen-sharing.sh
    info "Test script created: ~/test-screen-sharing.sh"
}

# Configure default applications
configure_default_applications() {
    step "Configuring default applications"
    
    # Set Zen Browser as default browser
    if command -v zen-browser &> /dev/null || command -v zen &> /dev/null; then
        log "Setting Zen Browser as default web browser..."
        
        # Try different possible zen browser commands
        if command -v zen-browser &> /dev/null; then
            ZEN_COMMAND="zen-browser"
        elif command -v zen &> /dev/null; then
            ZEN_COMMAND="zen"
        fi
        
        # Set as default browser
        xdg-settings set default-web-browser zen-browser.desktop 2>/dev/null || \
        xdg-settings set default-web-browser zen.desktop 2>/dev/null || \
        warn "Could not set Zen Browser as default (desktop file may not exist yet)"
        
        # Set MIME types for web content
        xdg-mime default zen-browser.desktop text/html 2>/dev/null || \
        xdg-mime default zen.desktop text/html 2>/dev/null || true
        
        xdg-mime default zen-browser.desktop x-scheme-handler/http 2>/dev/null || \
        xdg-mime default zen.desktop x-scheme-handler/http 2>/dev/null || true
        
        xdg-mime default zen-browser.desktop x-scheme-handler/https 2>/dev/null || \
        xdg-mime default zen.desktop x-scheme-handler/https 2>/dev/null || true
        
        log "Zen Browser configured as default browser"
    else
        warn "Zen Browser not found, skipping browser default configuration"
    fi
    
    # Set Ghostty as default terminal
    if command -v ghostty &> /dev/null; then
        log "Setting Ghostty as default terminal..."
        
        # Set MIME type for terminal
        xdg-mime default com.mitchellh.ghostty.desktop application/x-terminal-emulator 2>/dev/null || \
        warn "Could not set Ghostty as default terminal"
        
        # Set environment variable for terminal
        echo 'export TERMINAL=ghostty' >> ~/.bashrc 2>/dev/null || true
        echo 'set -gx TERMINAL ghostty' >> ~/.config/fish/config.fish 2>/dev/null || true
        
        # Create/update alternatives if available
        if command -v update-alternatives &> /dev/null; then
            sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/ghostty 50 2>/dev/null || true
        fi
        
        log "Ghostty configured as default terminal"
    else
        warn "Ghostty not found, skipping terminal default configuration"
    fi
    
    # Update desktop database
    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database ~/.local/share/applications/ 2>/dev/null || true
    fi
    
    success "Default applications configuration completed"
}

# Configure Git
configure_git() {
    if [[ "$CONFIGURE_GIT" == true ]]; then
        step "Configuring Git"
        
        read -p "Enter your Git username: " git_username
        read -p "Enter your Git email: " git_email
        
        git config --global user.name "$git_username"
        git config --global user.email "$git_email"
        git config --global init.defaultBranch main
        git config --global pull.rebase false
        
        success "Git configured successfully"
    fi
}

# Create directories
create_directories() {
    step "Creating directory structure"
    
    for dir in "${DIRECTORIES[@]}"; do
        [[ "$dir" =~ ^#.*$ ]] || [[ -z "$dir" ]] && continue
        
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log "Created directory: $dir"
        else
            info "Directory already exists: $dir"
        fi
    done
    
    success "Directory structure created"
}

# Install additional fonts
install_fonts() {
    if [[ "$INSTALL_FONTS" == true ]]; then
        step "Installing additional fonts"
        
        # Install Nerd Fonts via AUR
        yay -S --noconfirm nerd-fonts-fira-code nerd-fonts-hack || warn "Failed to install Nerd Fonts"
        
        # Update font cache
        fc-cache -fv
        
        success "Font installation completed"
    fi
}

# Cleanup
cleanup() {
    if [[ "$DRY_RUN" == true ]]; then
        return
    fi
    
    # Clean package cache
    sudo pacman -Sc --noconfirm
    yay -Sc --noconfirm
    
    # Clean npm cache if npm is available
    if command -v npm &> /dev/null; then
        npm cache clean --force &>/dev/null || true
    fi
}



# Show summary
show_summary() {
    echo
    echo "=================================="
    echo "  CachyOS Setup Script Summary"
    echo "=================================="
    echo "✓ System packages updated"
    echo "✓ Official packages installed"
    echo "✓ AUR packages installed"
    echo "✓ System services configured"
    echo "✓ Development environment set up"
    echo "✓ Directory structure created"
    echo
    warn "IMPORTANT: Please reboot your system to ensure all changes take effect"
    info "You may need to log out and back in for group changes to take effect"
    echo
}

# Main menu
show_menu() {
    echo "CachyOS Setup Script"
    echo "===================="
    echo "1) Full installation (recommended)"
    echo "2) Official packages only"
    echo "3) AUR packages only"
    echo "4) Development environment only"
    echo "5) Custom selection"
    echo "6) Exit"
    echo
    read -p "Choose an option (1-6): " choice
    echo
}

# Custom installation menu
custom_installation() {
    echo "Custom Installation Options:"
    echo "============================"
    
    read -p "Install official packages? (y/n): " install_official
    read -p "Install AUR packages? (y/n): " install_aur
    read -p "Setup Flatpak? (y/n): " setup_flat
    read -p "Install Python packages? (y/n): " install_python
    read -p "Install Node.js packages? (y/n): " install_node
    read -p "Configure Git? (y/n): " config_git
    read -p "Install fonts? (y/n): " install_font
    
    echo
}

# Main execution
main() {
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${PURPLE}===========================================${NC}"
        echo -e "${PURPLE}         DRY RUN MODE ACTIVATED           ${NC}"
        echo -e "${PURPLE}    No changes will be made to system    ${NC}"
        echo -e "${PURPLE}===========================================${NC}"
        echo
    fi
    
    echo "Starting CachyOS Setup Script..."
    echo "==============================="
    
    check_root
    check_sudo
    load_config
    
    # Record start time
    SCRIPT_START_TIME=$(date +%s)
    
    show_menu
    
    case $choice in
        1)  # Full installation
            count_operations
            echo
            info "Starting full installation with $TOTAL_OPERATIONS operations..."
            echo
            
            [[ "$DRY_RUN" == false ]] && create_snapshot "CachyOS Setup - Before Installation"
            [[ "$DRY_RUN" == false ]] && disable_auto_snapshots
            
            update_system
            install_aur_helper
            install_official_packages
            install_aur_packages
            step "Configuring services"
            enable_services
            step "Configuring Wayland screen sharing"
            configure_wayland_screensharing
            step "Setting default applications"
            configure_default_applications
            step "Creating directories"
            create_directories
            step "Performing cleanup"
            cleanup
            
            [[ "$DRY_RUN" == false ]] && enable_auto_snapshots
            [[ "$DRY_RUN" == false ]] && create_snapshot "CachyOS Setup - After Installation"
            ;;
        2)  # Official packages only
            update_system
            install_official_packages
            enable_services
            create_directories
            ;;
        3)  # AUR packages only
            install_aur_helper
            install_aur_packages
            ;;
        4)  # Development environment only
            install_python_packages
            install_node_packages
            configure_git
            create_directories
            ;;
        5)  # Custom selection
            custom_installation
            
            [[ "$install_official" =~ ^[Yy]$ ]] && { update_system; install_official_packages; }
            [[ "$install_aur" =~ ^[Yy]$ ]] && { install_aur_helper; install_aur_packages; }
            [[ "$setup_flat" =~ ^[Yy]$ ]] && setup_flatpak
            [[ "$install_python" =~ ^[Yy]$ ]] && install_python_packages
            [[ "$install_node" =~ ^[Yy]$ ]] && install_node_packages
            [[ "$config_git" =~ ^[Yy]$ ]] && configure_git
            [[ "$install_font" =~ ^[Yy]$ ]] && install_fonts
            
            enable_services
            create_directories
            configure_default_applications
            cleanup
            ;;
        6)  # Exit
            info "Exiting..."
            exit 0
            ;;
        *)
            error "Invalid option"
            exit 1
            ;;
    esac
    
    show_summary
    success "CachyOS setup completed successfully!"
}

# Run main function
main "$@"