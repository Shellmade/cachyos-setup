# CachyOS Setup Script

🚀 **Automated CachyOS installation and configuration script for a complete development and productivity environment.**

## ✨ Features

- **📦 Package Management**: Installs packages via pacman and AUR (yay)
- **🖥️ Wayland Screen Sharing**: Full configuration for Teams, Slack, Zoom, Discord
- **🌐 Default Applications**: Sets Zen Browser and Ghostty as defaults
- **👥 User Permissions**: Adds user to required groups for media access
- **📊 Progress Tracking**: Beautiful progress bar with real-time updates
- **💾 Snapshot Management**: Creates before/after system snapshots
- **🔐 Single Password**: Caches sudo credentials for seamless installation

## 📋 Included Packages

### Official Repository (pacman)
- **System Tools**: btop, tree, yazi, htop
- **Network Tools**: openvpn, nmap, curl, wget, wireshark-qt
- **Wayland/PipeWire**: xdg-desktop-portal-wlr, pipewire, wireplumber
- **Development**: git, base-devel

### AUR Packages (yay)
- **Browsers**: zen-browser-bin, microsoft-edge-stable-bin
- **Communication**: teams-for-linux, slack-desktop, zoom
- **Media**: spotify
- **Productivity**: obsidian, 1password
- **Terminal**: ghostty-bin
- **Network**: openvpn3
- **Hardware**: displaylink, evdi (USB-C display support)

## 🚀 Quick Start

### Prerequisites
- Fresh CachyOS installation
- Internet connection
- User with sudo privileges

### Installation

1. **Clone this repository:**
   ```bash
   git clone https://github.com/Shellmade/cachyos-setup.git
   cd cachyos-setup
   ```

2. **Make script executable:**
   ```bash
   chmod +x cachyos-setup-advanced.sh
   ```

3. **Run the script:**
   ```bash
   ./cachyos-setup-advanced.sh
   ```

4. **Choose option 1** (Full installation) from the menu

5. **Enter your password once** when prompted

6. **Enjoy your fully configured system!** ☕

## 🧪 Testing

Before running the full installation, you can test the script:

```bash
# Validate configuration and script
./test-setup.sh

# See what would be installed (dry run)
./cachyos-setup-advanced.sh --dry-run
```

## ⚙️ Customization

Edit `packages.conf` to customize your package selection:

```bash
# Official Repository Packages
OFFICIAL_PACKAGES=(
    "btop"
    "tree"
    # Add your packages here
)

# AUR Packages  
AUR_PACKAGES=(
    "spotify"
    "zen-browser-bin"
    # Add your packages here
)
```

## 🎯 What Gets Configured

### Wayland Screen Sharing
- ✅ XDG desktop portals
- ✅ PipeWire audio/video capture
- ✅ User group permissions (video, audio, input, render)
- ✅ Application Wayland flags (Teams, Slack, browsers)

### Default Applications
- ✅ Zen Browser as default web browser
- ✅ Ghostty as default terminal
- ✅ MIME type associations

### System Services
- ✅ Bluetooth
- ✅ Printing (CUPS)
- ✅ Network discovery (Avahi)

### Directory Structure
```
~/Development/
  ├── projects/
  ├── scripts/
  └── tools/
~/Downloads/Software/
~/Documents/Scripts/
~/.local/bin/
```

## 🛠️ Options

The script offers multiple installation modes:

1. **Full installation** - Complete setup (recommended)
2. **Official packages only** - Skip AUR packages
3. **AUR packages only** - Skip official packages  
4. **Development environment** - Minimal setup
5. **Custom selection** - Choose components individually

## 📸 Snapshots

The script automatically creates system snapshots:
- **Before installation**: "CachyOS Setup - Before Installation"
- **After installation**: "CachyOS Setup - After Installation"

Automatic snapshots are temporarily disabled during installation to avoid creating dozens of individual package snapshots.

## 🔧 Troubleshooting

### Common Issues

**Screen sharing not working:**
- Make sure to **log out and back in** after installation
- Check that you're in the required groups: `groups $USER`

**Package installation fails:**
- Check internet connection
- Update keyring: `sudo pacman -S archlinux-keyring`

**Permission errors:**
- Ensure your user has sudo privileges
- Run: `sudo usermod -aG wheel $USER`

### Getting Help

If you encounter issues:
1. Check the installation logs
2. Run the test suite: `./test-setup.sh`
3. Try a dry run: `./cachyos-setup-advanced.sh --dry-run`

## 📝 License

MIT License - Feel free to modify and distribute!

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

---

**Made with ❤️ for the CachyOS community**

*This script automates the tedious setup process so you can focus on what matters - getting work done!*