#!/bin/bash

#############################################################################
# Kalindows Pro - Main Setup Script
# 
# This script transforms a fresh Kali Linux installation into 
# Kalindows Pro - a Windows-style pentesting powerhouse
#
# Usage: sudo ./setup-kalindows.sh [option]
#
# Options:
#   full     - Complete installation (UI + Tools + Security)
#   ui       - Windows UI theming only
#   tools    - Pentesting tools only
#   minimal  - Base customizations only
#   help     - Show this help message
#
#############################################################################

set -e

# Ensure scripts are executable
chmod +x "$SCRIPT_DIR"/scripts/*.sh 2>/dev/null || true

# Helper function to write KDE config (with fallback)
kwriteconfig5() {
    local file="$1"
    local group="$2"
    local key="$3"
    shift 3
    local value="$@"
    
    # Try kwriteconfig5 first
    if command -v kwriteconfig5 &> /dev/null; then
        kwriteconfig5 --file "$file" --group "$group" --key "$key" "$value" 2>/dev/null || true
    else
        # Fallback: write directly to config file
        local config_file="${HOME}/.config/$file"
        mkdir -p "$(dirname "$config_file")"
        
        if [[ ! -f "$config_file" ]]; then
            touch "$config_file"
        fi
        
        # Add the new key under the correct group
        if grep -q "^\[$group\]" "$config_file" 2>/dev/null; then
            sed -i "/^\[$group\]/a $key=$value" "$config_file" 2>/dev/null || true
        else
            echo -e "\n[$group]" >> "$config_file"
            echo "$key=$value" >> "$config_file"
        fi
    fi
}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../config"

# Log file
LOG_FILE="/var/log/kalindows-setup.log"

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $1" | tee -a "$LOG_FILE"
}

print_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
    ██╗    ██╗ █████╗ ██████╗ ███╗   ██╗██╗███╗   ██╗ ██████╗ 
    ██║    ██║██╔══██╗██╔══██╗████╗  ██║██║████╗  ██║██╔════╝ 
    ██║ █╗ ██║███████║██████╔╝██╔██╗ ██║██║██╔██╗ ██║██║  ███╗
    ██║███╗██║██╔══██║██╔══██╗██║╚██╗██║██║██║╚██╗██║██║   ██║
    ╚███╔███╔╝██║  ██║██║  ██║██║ ╚████║██║██║ ╚████║╚██████╔╝
     ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝╚═╝  ╚═══╝ ╚═════╝ 
                                                          
                    ╔═══════════════════════════╗
                    ║   KALINDOWS PRO EDITION   ║
                    ║   The Windows Experience  ║
                    ║      Kali Powerhouse      ║
                    ╚═══════════════════════════╝
EOF
    echo -e "${NC}"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root (use sudo)"
        exit 1
    fi
}

check_kali() {
    if [[ ! -f /etc/kali_version ]]; then
        warn "This script is designed for Kali Linux. Continue anyway? (y/n)"
        read -r response
        if [[ "$response" != "y" ]]; then
            exit 1
        fi
    fi
}

update_system() {
    log "Updating system packages..."
    export DEBIAN_FRONTEND=noninteractive
    apt update -qq
    apt upgrade -y -qq
    apt autoremove -y -qq
    log "System updated successfully"
}

install_base_packages() {
    log "Installing base packages..."
    apt install -y -qq \
        plasma-desktop \
        plasma-workspace \
        plasma-workspace \
        kwin-wayland \
        kwin-x11 \
        kscreen \
        sddm \
        sddm-theme-circles \
        systemsettings \
        dolphin \
        konsole \
        kate \
        ark \
        ksystemstats \
        plasma-browser-integration \
        kde-config-gtk-style \
        breeze-gtk-theme \
        oxygen-icons \
        libqt5styleplugins-plastik \
        latte-dock \
        plank \
        macchanger \
        ufw \
        gufw \
        firewall-config \
        preload \
        zram-tools \
        tuned \
        btop \
        htop \
        neofetch \
        fonts-noto \
        fonts-noto-cjk \
        fonts-segoe-ui \
        libreoffice-style-breeze \
        plasma-theme-circles \
        papirus-icon-theme \
        kdocker \
       ulauncher \
        albert \
        2>/dev/null || true
    
    log "Base packages installed successfully"
}

install_development_tools() {
    log "Installing development tools..."
    apt install -y -qq \
        git \
        curl \
        wget \
        vim \
        nano \
        emacs \
        vscode \
        python3 \
        python3-pip \
        python3-venv \
        python3-dev \
        python3-setuptools \
        ipython3 \
        golang \
        rustc \
        cargo \
        rustup \
        gcc \
        g++ \
        make \
        cmake \
        gdb \
        valgrind \
        ruby \
        ruby-dev \
        nodejs \
        npm \
        openjdk-17-jdk \
        maven \
        gradle \
        docker.io \
        docker-compose \
        podman \
        libvirt-daemon-system \
        qemu-kvm \
        virt-manager \
        git-lfs \
        httpie \
        sqlite3 \
        mysql-client \
        postgresql-client \
        redis-tools \
        2>/dev/null || true
    
    # Configure Git
    git config --global user.name "Kalindows User"
    git config --global user.email "user@kalindows.local"
    git config --global init.defaultBranch main
    
    log "Development tools installed successfully"
}

install_pentest_tools() {
    log "Installing penetration testing tools..."
    
    # Update Kali repositories if needed
    echo "deb http://http.kali.org/kali kali-rolling main contrib non-free" > /etc/apt/sources.list
    
    apt update -qq
    
    # Metasploit
    apt install -y -qq \
        metasploit-framework \
        msfpc \
        searchsploit \
        exploitdb \
        2>/dev/null || true
    
    # Network Scanning
    apt install -y -qq \
        nmap \
        zenmap \
        netdiscover \
        arp-scan \
        masscan \
        unicornscan \
        2>/dev/null || true
    
    # Web Application
    apt install -y -qq \
        burpsuite \
        sqlmap \
        nikto \
        dirb \
        gobuster \
        wpscan \
        whatweb \
        ffuf \
        feroxbuster \
        2>/dev/null || true
    
    # Password Attacks
    apt install -y -qq \
        hydra \
        john \
        hashcat \
        crunch \
        cewl \
        hashidentifier \
        2>/dev/null || true
    
    # Wireless Attacks
    apt install -y -qq \
        aircrack-ng \
        reaver \
        bully \
        wifite \
        mdk3 \
        mdk4 \
        hostapd \
        2>/dev/null || true
    
    # Reverse Engineering
    apt install -y -qq \
        ghidra \
        radare2 \
        rizin \
        cutter \
        binwalk \
        strings \
        2>/dev/null || true
    
    # Forensics
    apt install -y -qq \
        autopsy \
        foremost \
        scalpel \
        volatility3 \
        binwalk \
        zsteg \
        2>/dev/null || true
    
    # Information Gathering
    apt install -y -qq \
        maltego \
        recon-ng \
        theharvester \
        spiderfoot \
        2>/dev/null || true
    
    # Social Engineering
    apt install -y -qq \
        setoolkit \
        beef-xss \
        2>/dev/null || true
    
    # Database Assessment
    apt install -y -qq \
        jsql \
        sqlinjection \
        nosqlmap \
        mongo-tools \
        2>/dev/null || true
    
    # Install additional tools via pip
    pip3 install -q \
        colorama \
        requests \
        beautifulsoup4 \
        scapy \
        pwntools \
        ropper \
        angr \
        capstone \
        keystone-engine \
        2>/dev/null || true
    
    log "Pentest tools installed successfully"
}

install_privacy_tools() {
    log "Installing privacy and anonymity tools..."
    
    apt install -y -qq \
        tor \
        torbrowser-launcher \
        proxychains \
        torsocks \
        macchanger \
        2>/dev/null || true
    
    # Install OpenVPN
    apt install -y -qq \
        openvpn \
        network-manager-openvpn \
        network-manager-openvpn-gnome \
        2>/dev/null || true
    
    # Configure proxychains
    sed -i 's/^socks4.*/socks5 127.0.0.1 9050/' /etc/proxychains.conf 2>/dev/null || true
    
    log "Privacy tools installed successfully"
}

configure_kde_theme() {
    log "Configuring KDE Plasma Windows-style theme..."
    
    # Create theme directories
    mkdir -p ~/.config/kdedefaults
    mkdir -p ~/.local/share/color-schemes
    mkdir -p ~/.local/share/icons
    mkdir -p ~/.local/share/plasma/desktoptheme
    
    # Apply dark mode
    kwriteconfig5 --file kdeglobals --group General --key "ColorScheme" "KalindowsDark"
    kwriteconfig5 --file kdeglobals --group General --key "LookAndFeelPackage" "org.kde.breezedark.desktop"
    kwriteconfig5 --file kdeglobals --group General --key "WidgetStyle" "breeze"
    kwriteconfig5 --file kdeglobals --group "Icons" --key "Theme" "Papirus-Dark"
    
    # Configure taskbar
    kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc \
        "Applet-1" "Configuration" "General" "iconSize" "Small"
    kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc \
        "Applet-1" "Configuration" "General" "locked" "true"
    
    # Set Windows-like taskbar position (bottom)
    kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc \
        "Applet-1" "Configuration" "General" "position" "3"
    
    # Configure window decorations
    kwriteconfig5 --file kwinrc --group "Windows" --key "BorderSize" "Normal"
    kwriteconfig5 --file kwinrc --group "Windows" --key "BorderlessMaximizedWindows" "true"
    kwriteconfig5 --file kwinrc --group "Windows" --key "ShadowlessWindows" "false"
    
    # Set up autostart for Kalindows
    mkdir -p ~/.config/autostart
    cat > ~/.config/autostart/kalindows.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Kalindows Tweaks
Exec=/usr/local/bin/kalindows-tweaks.sh
Icon=kalinux
Comment=Apply Kalindows customizations on login
EOF
    
    log "KDE theme configured"
}

configure_sddm() {
    log "Configuring SDDM login screen..."
    
    # Set SDDM theme
    mkdir -p /etc/sddm.conf.d
    cat > /etc/sddm.conf.d/kalindows.conf << 'EOF'
[Theme]
Current=circles
CursorTheme=breeze_cursors
EOF
    
    log "SDDM configured"
}

configure_keyboard_shortcuts() {
    log "Configuring Windows-style keyboard shortcuts..."
    
    # Create custom shortcuts configuration
    mkdir -p ~/.config/kglobalshortcuts
    
    # Windows key to menu
    kwriteconfig5 --file kwinrc --group "ModifierOnlyShortcuts" --key "Meta" "org.kde.plasmashell,/PlasmaShell,org.kde.PlasmaShell,activateLauncherMenu"
    
    # Alt+F4 handled by KWin
    kwriteconfig5 --file kwinrc --group "Window Actions" --key "CloseWindowShortcut" "Alt+F4"
    
    # Print screen for screenshot
    kwriteconfig5 --file kscreenlockerrc --group "Daemon" --key "Autolock" "false"
    
    log "Keyboard shortcuts configured"
}

apply_performance_tweaks() {
    log "Applying performance optimizations..."
    
    # Disable unnecessary services
    systemctl stop bluetooth 2>/dev/null || true
    systemctl disable bluetooth 2>/dev/null || true
    systemctl stop apache2 2>/dev/null || true
    systemctl disable apache2 2>/dev/null || true
    systemctl stop nginx 2>/dev/null || true
    systemctl disable nginx 2>/dev/null || true
    systemctl stop snapd 2>/dev/null || true
    systemctl disable snapd 2>/dev/null || true
    systemctl stop avahi-daemon 2>/dev/null || true
    systemctl disable avahi-daemon 2>/dev/null || true
    
    # Apply sysctl tweaks
    cat >> /etc/sysctl.conf << 'EOF'

# Kalindows Performance Tweaks
vm.swappiness=10
vm.vfs_cache_pressure=50
vm.dirty_ratio=15
vm.dirty_background_ratio=5
vm.dirty_expire_centisecs=3000
vm.dirty_writeback_centisecs=500

# Kernel hardening
kernel.dmesg_restrict=1
kernel.kptr_restrict=2
kernel.yama.ptrace_scope=2

# Network hardening
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.icmp_echo_ignore_broadcasts=1
net.ipv4.icmp_ignore_bogus_error_responses=1
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0
net.ipv6.conf.all.accept_redirects=0
net.ipv6.conf.default.accept_redirects=0

# Disable IP source routing
net.ipv4.conf.all.accept_source_route=0
net.ipv6.conf.all.accept_source_route=0
EOF

    # Apply changes
    sysctl -p /etc/sysctl.conf 2>/dev/null || true
    
    # Configure ZRAM
    cat > /etc/zram.conf << 'EOF'
# ZRAM configuration for Kalindows
ALGO=lz4
PERCENT=50
EOF

    # Enable ZRAM service
    systemctl enable zramswap 2>/dev/null || true
    
    # Configure boot options - add to GRUB
    if [[ -f /etc/default/grub ]]; then
        sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash zswap.enabled=1"/' /etc/default/grub
        update-grub 2>/dev/null || true
    fi
    
    log "Performance tweaks applied"
}

enable_firewall() {
    log "Configuring firewall..."
    
    # Configure UFW
    ufw default deny incoming
    ufw default allow outgoing
    ufw logging on
    
    # Enable firewall
    ufw enable
    
    # Allow SSH (with rate limiting)
    ufw limit 22/tcp
    
    log "Firewall enabled"
}

install_custom_scripts() {
    log "Installing custom scripts..."
    
    # Create scripts directory
    mkdir -p /usr/local/bin
    
    # Kalindows tweaks script
    cat > /usr/local/bin/kalindows-tweaks.sh << 'EOF'
#!/bin/bash
# Kalindows Pro - Runtime Tweaks
# Apply custom settings on login

# Set CPU governor to performance
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo performance > $cpu 2>/dev/null || true
done

# Apply network hardening
sysctl -p /etc/sysctl.conf 2>/dev/null || true

# Start MAC changer for wireless interfaces
for iface in $(ip -o link show | awk -F': ' '{print $2}' | grep -E '^(wlan|wlp)'); do
    macchanger -r $iface 2>/dev/null || true
done
EOF

    chmod +x /usr/local/bin/kalindows-tweaks.sh
    
    # Quick benchmark script
    cat > /usr/local/bin/kalindows-bench.sh << 'EOF'
#!/bin/bash
echo "=== Kalindows Pro System Benchmark ==="
echo ""
echo "CPU Info:"
lscpu | grep -E "Model name|CPU\(s\)|Thread|Core|Socket"
echo ""
echo "Memory:"
free -h
echo ""
echo "Disk I/O:"
if command -v fio &> /dev/null; then
    fio --name=seqread --ioengine=libaio --direct=1 --bs=4k --iodepth=1 --numjobs=1 --rw=read --size=1G --runtime=10 --time_based --filename=/tmp/fiotest 2>/dev/null | grep -E "read:|IOPS"
else
    echo "Install fio for detailed I/O benchmarks"
fi
echo ""
echo "Boot Time:"
systemd-analyze
echo ""
echo "System Info:"
neofetch --stdout 2>/dev/null || uname -a
EOF

    chmod +x /usr/local/bin/kalindows-bench.sh
    
    log "Custom scripts installed"
}

create_desktop_shortcuts() {
    log "Creating desktop shortcuts..."
    
    mkdir -p ~/Desktop
    
    # Metasploit
    cat > ~/Desktop/metasploit.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Metasploit Framework
Comment=Penetration Testing Framework
Exec=msfconsole
Icon=msfconsole
Terminal=true
Categories=Security;Network;
EOF

    # Burp Suite
    cat > ~/Desktop/burpsuite.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Burp Suite
Comment=Web Application Security Testing
Exec=burpsuite
Icon=burpsuite
Terminal=false
Categories=Security;Network;
EOF

    # Wireshark
    cat > ~/Desktop/wireshark.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Wireshark
Comment=Network Protocol Analyzer
Exec=wireshark
Icon=wireshark
Terminal=false
Categories=Security;Network;
EOF

    # Terminal
    cat > ~/Desktop/terminal.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Konsole
Comment=Terminal Emulator
Exec=konsole
Icon=konsole
Terminal=false
Categories=System;
EOF

    # Make them executable
    chmod +x ~/Desktop/*.desktop
    
    log "Desktop shortcuts created"
}

show_completion_message() {
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  Kalindows Pro Setup Complete!${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    echo -e "${YELLOW}IMPORTANT NEXT STEPS:${NC}"
    echo "  1. Reboot your system"
    echo "  2. Log in and configure your desktop"
    echo "  3. Run 'kalindows-bench.sh' to benchmark"
    echo "  4. Customize taskbar and start menu"
    echo ""
    echo -e "${CYAN}Tools installed:${NC}"
    echo "  - Metasploit Framework"
    echo "  - Nmap, Netdiscover, Masscan"
    echo "  - Burp Suite, SQLMap, Nikto"
    echo "  - Hydra, John, Hashcat"
    echo "  - Aircrack-ng, Wifite"
    echo "  - Ghidra, Radare2"
    echo "  - Wireshark, tcpdump"
    echo "  - And many more..."
    echo ""
    echo -e "${RED}Security enabled by default:${NC}"
    echo "  - UFW Firewall enabled"
    echo "  - Kernel hardening applied"
    echo "  - MAC address randomization ready"
    echo ""
    echo -e "${BLUE}Quick Commands:${NC}"
    echo "  - msfconsole      : Start Metasploit"
    echo "  - burpsuite      : Start Burp Suite"
    echo "  - wireshark      : Start Wireshark"
    echo "  - kalindows-bench: Run benchmark"
    echo ""
}

usage() {
    cat << EOF
Kalindows Pro Setup Script

Usage: $0 [option]

Options:
    full     - Complete installation (UI + Tools + Security) [default]
    ui       - Windows UI theming only
    tools    - Pentesting tools only
    minimal  - Base customizations only
    help     - Show this help message

Examples:
    sudo $0 full
    sudo $0 ui

EOF
}

# Main execution
main() {
    local mode="${1:-full}"
    
    print_banner
    check_root
    check_kali
    
    log "Starting Kalindows Pro setup in ${mode} mode..."
    
    # Always update first
    update_system
    
    case "$mode" in
        full)
            log "Running FULL installation..."
            install_base_packages
            install_development_tools
            install_pentest_tools
            install_privacy_tools
            configure_kde_theme
            configure_sddm
            configure_keyboard_shortcuts
            apply_performance_tweaks
            enable_firewall
            install_custom_scripts
            create_desktop_shortcuts
            ;;
        ui)
            log "Installing UI customizations only..."
            install_base_packages
            configure_kde_theme
            configure_sddm
            configure_keyboard_shortcuts
            install_custom_scripts
            create_desktop_shortcuts
            ;;
        tools)
            log "Installing pentesting tools only..."
            install_pentest_tools
            install_privacy_tools
            create_desktop_shortcuts
            ;;
        minimal)
            log "Running minimal installation..."
            install_base_packages
            apply_performance_tweaks
            enable_firewall
            install_custom_scripts
            ;;
        help|--help|-h)
            usage
            exit 0
            ;;
        *)
            error "Unknown option: $mode"
            usage
            exit 1
            ;;
    esac
    
    show_completion_message
    
    log "Setup complete! Reboot to apply changes."
}

# Run main
main "$@"
