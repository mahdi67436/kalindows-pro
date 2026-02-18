#!/bin/bash

#############################################################################
# Kalindows Pro - Advanced UI Implementation
#
# Complete Windows 11-style desktop customization with all visual enhancements
# Includes: Plasma theming, window manager, effects, notifications, shortcuts
#
# Usage: sudo ./apply-ui-theme.sh
#
#############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"; }
warn() { echo -e "${YELLOW}[$(date +'%H:%M:%S')]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../config"

# Ensure all scripts are executable
chmod +x "${SCRIPT_DIR}"/*.sh 2>/dev/null || true
chmod +x "${SCRIPT_DIR}"/../scripts/*.sh 2>/dev/null || true

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
        
        # Remove existing key if present
        if grep -q "^\[$group\]" "$config_file" 2>/dev/null; then
            sed -i "/^\[$group\]/,/^[\[.*]/ { s/^\s*$key\s*=.*$/# $key=/; }" "$config_file" 2>/dev/null || true
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

print_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
    ╔═══════════════════════════════════════════════════════════════════╗
    ║        KALINDOWS PRO - ADVANCED UI IMPLEMENTATION                  ║
    ║        Premium Windows 11-Style Desktop Experience                 ║
    ╚═══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        warn "Running without root - some features may not work"
    fi
}

install_theme_dependencies() {
    log "Installing UI theme dependencies..."
    
    # Install packages (with fallbacks for package name changes)
    apt install -y -qq \
        plasma-desktop \
        plasma-workspace \
        kwin-wayland \
        kwin-x11 \
        systemsettings \
        breeze-gtk-theme \
        breeze-icon-theme \
        oxygen-icons \
        papirus-icon-theme \
        latte-dock \
        ksystemstats \
        libksysguard-bin \
        ark \
        dolphin \
        konsole \
        kate \
        plasma-browser-integration \
        kde-config-gtk-style \
        plasma-theme-circles \
        libqt5quick5 \
        qml-module-qtquick2 \
        2>/dev/null || true
    
    # Install kwriteconfig5 if not present
    if ! command -v kwriteconfig5 &> /dev/null; then
        apt install -y -qq plasma-workspace 2>/dev/null || true
    fi
    
    log "Dependencies installed"
}

apply_plasma_theme() {
    log "Applying Plasma desktop theme configuration..."
    
    # Create config directories
    mkdir -p ~/.config/kdedefaults
    mkdir -p ~/.local/share/color-schemes
    mkdir -p ~/.local/share/icons
    mkdir -p ~/.local/share/plasma/desktoptheme
    mkdir -p ~/.local/share/plasma/look-and-feel
    mkdir -p ~/.config/plasma-dconf
    
    # Apply KDE global settings
    kwriteconfig5 --file kdeglobals --group "General" --key "ColorScheme" "KalindowsDark"
    kwriteconfig5 --file kdeglobals --group "General" --key "LookAndFeelPackage" "org.kde.breezedark.desktop"
    kwriteconfig5 --file kdeglobals --group "General" --key "WidgetStyle" "breeze"
    kwriteconfig5 --file kdeglobals --group "General" --key "ShellShortcuts" "noticesSettings,showActivityManager,stopAll,locked,start-overlay,keyboard"
    
    # Icons
    kwriteconfig5 --file kdeglobals --group "Icons" --key "Theme" "Papirus-Dark"
    
    # Fonts
    kwriteconfig5 --file kdeglobals --group "General" --key "font" "Segoe UI,10,-1,5,50,0,0,0,1,0"
    kwriteconfig5 --file kdeglobals --group "General" --key "menuFont" "Segoe UI,10,-1,5,50,0,0,0,1,0"
    kwriteconfig5 --file kdeglobals --group "General" --key "toolBarFont" "Segoe UI,9,-1,5,50,0,0,0,1,0"
    kwriteconfig5 --file kdeglobals --group "General" --key "windowTitleFont" "Segoe UI,10,-1,5,75,0,0,0,1,0"
    
    # Plasma settings
    kwriteconfig5 --file plasmarc --group "Plasma" --key "LookAndFeelPackage" "org.kde.breezedark.desktop"
    kwriteconfig5 --file plasmarc --group "Plasma" --key "ShowDesktop" "true"
    kwriteconfig5 --file plasmarc --group "Plasma" --key "UseTranslucency" "true"
    kwriteconfig5 --file plasmarc --group "Plasma" --key "BlurBehindEnabled" "true"
    
    # Desktop theme
    kwriteconfig5 --file plasmarc --group "Plasma" --key "DesktopByScreen" "1"
    kwriteconfig5 --file plasmarc --group "Plasma" --key "ToolTipsEnabled" "true"
    kwriteconfig5 --file plasmarc --group "Plasma" --key "ToolButtonStyle" "0"
    kwriteconfig5 --file plasmarc --group "Plasma" --key "DialogButtonLayout" "0"
    kwriteconfig5 --file plasmarc --group "Plasma" --key "ButtonsHaveIcons" "true"
    
    log "Plasma theme configured"
}

configure_window_manager() {
    log "Configuring KWin window manager..."
    
    # Window behavior
    kwriteconfig5 --file kwinrc --group "Windows" --key "BorderSize" "Normal"
    kwriteconfig5 --file kwinrc --group "Windows" --key "BorderlessMaximizedWindows" "true"
    kwriteconfig5 --file kwinrc --group "Windows" --key "ShadowlessWindows" "false"
    kwriteconfig5 --file kwinrc --group "Windows" --key "TransparentDolphinView" "true"
    kwriteconfig5 --file kwinrc --group "Windows" --key "TransparentKonsoleView" "true"
    kwriteconfig5 --file kwinrc --group "Windows" --key "TransparentKCalcView" "true"
    kwriteconfig5 --file kwinrc --group "Windows" --key "WindowPlacement" "Smart"
    kwriteconfig5 --file kwinrc --group "Windows" --key "FocusPolicy" "ClickToFocus"
    kwriteconfig5 --file kwinrc --group "Windows" --key "ClickRaise" "false"
    kwriteconfig5 --file kwinrc --group "Windows" --key "AutoRaise" "false"
    kwriteconfig5 --file kwinrc --group "Windows" --key "AutoRaiseInterval" "50"
    
    # Title bar buttons - Windows style
    kwriteconfig5 --file kwinrc --group "Windows" --key "ButtonsOnLeft" "MS"
    kwriteconfig5 --file kwinrc --group "Windows" --key "ButtonsOnRight" "IAX"
    
    # Snap settings
    kwriteconfig5 --file kwinrc --group "Windows" --key "WindowSnapZone" "10"
    kwriteconfig5 --file kwinrc --group "Windows" --key "SnapOnlyWhenMoving" "true"
    
    log "Window manager configured"
}

configure_compositor() {
    log "Configuring compositor with blur and transparency..."
    
    # Enable compositor
    kwriteconfig5 --file kwinrc --group "Compositing" --key "Enabled" "true"
    kwriteconfig5 --file kwinrc --group "Compositing" --key "OpenGLIsUnsafe" "false"
    kwriteconfig5 --file kwinrc --group "Compositing" --key "GLCoreContext" "true"
    kwriteconfig5 --file kwinrc --group "Compositing" --key "HiddenPreviews" "4"
    kwriteconfig5 --file kwinrc --group "Compositing" --key "MaxFPS" "60"
    kwriteconfig5 --file kwinrc --group "Compositing" --key "XRenderSurface" "true"
    kwriteconfig5 --file kwinrc --group "Compositing" --key "ScaleMethod" "Quality"
    
    # Blur settings
    kwriteconfig5 --file kwinrc --group "Plugins" --key "blurEnabled" "true"
    kwriteconfig5 --file kwinrc --group "blur" --key "radius" "40"
    kwriteconfig5 --file kwinrc --group "blur" --key "strength" "8"
    kwriteconfig5 --file kwinrc --group "blur" --key "noGaussian" "false"
    kwriteconfig5 --file kwinrc --group "blur" --key "exclude" "dialogs,menus,tasks,transients,osd,notificati"
    
    # Other effects
    kwriteconfig5 --file kwinrc --group "Plugins" --key "contrastEnabled" "true"
    kwriteconfig5 --file kwinrc --group "contrast" --key "contrast" "1.0"
    kwriteconfig5 --file kwinrc --group "contrast" --key "saturation" "1.0"
    
    # Translucency
    kwriteconfig5 --file kwinrc --group "Windows" --key "TransparentDolphinView" "true"
    kwriteconfig5 --file kwinrc --group "Windows" --key "TransparentKonsoleView" "true"
    
    log "Compositor configured with blur effects"
}

configure_desktop_effects() {
    log "Configuring desktop effects..."
    
    # Window animations
    kwriteconfig5 --file kwinrc --group "Plugins" --key "slideEnabled" "true"
    kwriteconfig5 --file kwinrc --group "slide" --key "vertical-timeout" "6"
    kwriteconfig5 --file kwinrc --group "slide" --key "vertical-duration" "300"
    kwriteconfig5 --file kwinrc --group "slide" --key "horizontal-timeout" "6"
    kwriteconfig5 --file kwinrc --group "slide" --key "horizontal-duration" "300"
    
    # Sliding popups
    kwriteconfig5 --file kwinrc --group "Plugins" --key "slidingpopupsEnabled" "true"
    kwriteconfig5 --file kwinrc --group "slidingpopups" --key "duration" "300"
    kwriteconfig5 --file kwinrc --group "slidingpopups" --key "fade-duration" "200"
    
    # Window opening animation
    kwriteconfig5 --file kwinrc --group "Plugins" --key "windowopeningEnabled" "true"
    kwriteconfig5 --file kwinrc --group "windowopening" --key "duration" "250"
    
    # Window closing animation
    kwriteconfig5 --file kwinrc --group "Plugins" --key "windowclosingEnabled" "true"
    kwriteconfig5 --file kwinrc --group "windowclosing" --key "duration" "200"
    
    # Magic lamp effect
    kwriteconfig5 --file kwinrc --group "Plugins" --key "magiclampEnabled" "true"
    kwriteconfig5 --file kwinrc --group "magiclamp" --key "duration" "400"
    
    # Present windows
    kwriteconfig5 --file kwinrc --group "Plugins" --key "presentwindowsEnabled" "true"
    kwriteconfig5 --file kwinrc --group "presentwindows" --key "layout" "1"
    
    # Desktop grid
    kwriteconfig5 --file kwinrc --group "Plugins" --key "desktopgridEnabled" "true"
    
    # Dim screen
    kwriteconfig5 --file kwinrc --group "Plugins" --key "diminactiveEnabled" "true"
    kwriteconfig5 --file kwinrc --group "diminactive" --key "intensity" "0.5"
    
    log "Desktop effects configured"
}

configure_notifications() {
    log "Configuring notification settings..."
    
    mkdir -p ~/.config
    
    # Notification settings
    kwriteconfig5 --file plasmanotifyrc --group "General" --key "popupPosition" "8"
    kwriteconfig5 --file plasmanotifyrc --group "General" --key "popupTimeout" "5000"
    kwriteconfig5 --file plasmanotifyrc --group "General" --key "masterPassword" ""
    kwriteconfig5 --file plasmanotifyrc --group "General" --key "soundEnabled" "true"
    kwriteconfig5 --file plasmanotifyrc --group "General" --key "eventSoundEnabled" "true"
    kwriteconfig5 --file plasmanotifyrc --group "General" --key "notifyOnScreenLock" "false"
    kwriteconfig5 --file plasmanotifyrc --group "General" --key "inhibitionsAllowed" "true"
    kwriteconfig5 --file plasmanotifyrc --group "General" --key "autoDeleteOldPopups" "true"
    kwriteconfig5 --file plasmanotifyrc --group "General" --key "maxPopups" "5"
    kwriteconfig5 --file plasmanotifyrc --group "General" --key "popupHeight" "90"
    kwriteconfig5 --file plasmanotifyrc --group "General" --key "popupWidth" "360"
    kwriteconfig5 --file plasmanotifyrc --group "Appearance" --key "showIcons" "true"
    kwriteconfig5 --file plasmanotifyrc --group "Appearance" --key "showApplicationName" "true"
    kwriteconfig5 --file plasmanotifyrc --group "Appearance" --key "useAltMonochromeIcon" "false"
    kwriteconfig5 --file plasmanotifyrc --group "Behavior" --key "autoHidePopups" "true"
    kwriteconfig5 --file plasmanotifyrc --group "Behavior" --key "closeOnHover" "false"
    kwriteconfig5 --file plasmanotifyrc --group "Behavior" --key "hoverClose" "true"
    kwriteconfig5 --file plasmanotifyrc --group "Behavior" --key "hoverTimeout" "5000"
    
    log "Notifications configured"
}

configure_global_shortcuts() {
    log "Configuring Windows-style global shortcuts..."
    
    # System shortcuts
    kwriteconfig5 --file kglobalshortcutsrc --group "kglobalaccel" --key "Component khelpcenter" ""
    kwriteconfig5 --file kglobalshortcutsrc --group "kglobalaccel" --key "Plasma Desktop" ""
    
    # KWin shortcuts - Windows style
    kwriteconfig5 --file kglobalshortcutsrc --group "kwin" --key "Window Close" "Alt+F4"
    kwriteconfig5 --file kglobalshortcutsrc --group "kwin" --key "Window Maximize" "Win+Up,Win+W"
    kwriteconfig5 --file kglobalshortcutsrc --group "kwin" --key "Window Minimize" "Win+Down,Win+H"
    kwriteconfig5 --file kglobalshortcutsrc --group "kwin" --key "Window Move" "Win+M"
    kwriteconfig5 --file kglobalshortcutsrc --group "kwin" --key "Window Resize" "Win+R"
    kwriteconfig5 --file kglobalshortcutsrc --group "kwin" --key "Show Desktop" "Win+D"
    kwriteconfig5 --file kglobalshortcutsrc --group "kwin" --key "Lock Screen" "Win+L"
    kwriteconfig5 --file kglobalshortcutsrc --group "kwin" --key "Task View" "Win+Tab"
    kwriteconfig5 --file kglobalshortcutsrc --group "kwin" --key "Next Window" "Alt+Tab"
    kwriteconfig5 --file kglobalshortcutsrc --group "kwin" --key "Previous Window" "Alt+Shift+Tab"
    kwriteconfig5 --file kglobalshortcutsrc --group "kwin" --key "Window One Screen Left" "Win+Left"
    kwriteconfig5 --file kglobalshortcutsrc --group "kwin" --key "Window One Screen Right" "Win+Right"
    
    # Modifier shortcuts - Windows key
    kwriteconfig5 --file kwinrc --group "ModifierOnlyShortcuts" --key "Meta" "org.kde.plasmashell,/PlasmaShell,org.kde.PlasmaShell,activateLauncherMenu"
    
    # Shortcuts for launchers
    kwriteconfig5 --file kglobalshortcutsrc --group "plasmashell" --key "krunner" "Alt+Space,Alt+F2"
    kwriteconfig5 --file kglobalshortcutsrc --group "plasmashell" --key "show dashboard" "Win+A"
    kwriteconfig5 --file kglobalshortcutsrc --group "plasmashell" --key "toggle doks" "Win+E"
    
    # Konsole shortcuts
    kwriteconfig5 --file kglobalshortcutsrc --group "konsole" --key "new window" "Win+T"
    kwriteconfig5 --file kglobalshortcutsrc --group "konsole" --key "new tab" "Win+Shift+T"
    
    # Dolphin shortcuts
    kwriteconfig5 --file kglobalshortcutsrc --group "dolphin" --key "new window" "Win+E"
    
    log "Global shortcuts configured"
}

configure_taskbar() {
    log "Configuring Windows-style taskbar..."
    
    mkdir -p ~/.config/plasma-dconf
    mkdir -p ~/.config/autostart
    
    # Taskbar (panel) configuration
    kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc \
        "Applet-1" "Configuration" "General" "iconSize" "Small"
    kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc \
        "Applet-1" "Configuration" "General" "locked" "true"
    kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc \
        "Applet-1" "Configuration" "General" "position" "3"
    kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc \
        "Applet-1" "Configuration" "General" "panelVisibility" "2"
    
    # System tray configuration
    kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc \
        "Applet-2" "Configuration" "General" "extraItems" "org.kde.plasma.battery,org.kde.plasma.volume,org.kde.plasma.network,org.kde.plasma.bluetooth,org.kde.plasma.notifications"
    kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc \
        "Applet-2" "Configuration" "General" "knownItems" "org.kde.plasma.battery,org.kde.plasma.volume,org.kde.plasma.network,org.kde.plasma.bluetooth,org.kde.plasma.notifications"
    
    # Clock configuration
    kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc \
        "Applet-3" "Configuration" "General" "showSeconds" "false"
    kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc \
        "Applet-3" "Configuration" "General" "use24hFormat" "true"
    kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc \
        "Applet-3" "Configuration" "General" "calendarPlugin" ""
    kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc \
        "Applet-3" "Configuration" "Appearance" "firstDayOfWeek" "0"
    
    # Start menu configuration
    kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc \
        "Applet-4" "Configuration" "General" "alphaSort" "true"
    kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc \
        "Applet-4" "Configuration" "General" "favoritesPortedToFavorites" "true"
    kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc \
        "Applet-4" "Configuration" "General" "showPowerOptions" "true"
    kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc \
        "Applet-4" "Configuration" "General" "showRecentApps" "false"
    kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc \
        "Applet-4" "Configuration" "General" "showRecentFiles" "false"
    
    log "Taskbar configured"
}

configure_system_tray() {
    log "Configuring system tray components..."
    
    # Enable system tray
    kwriteconfig5 --file kwinrc --group "SystemTray" --key "Enabled" "true"
    kwriteconfig5 --file kwinrc --group "SystemTray" --key "AutoHideAll" "false"
    
    # Tray icons
    mkdir -p ~/.config/autostart
    
    # Network applet
    kwriteconfig5 --file plasma-org.kde.plasma.networkpanel.appletrc \
        "General" "showSignalStrength" "true"
    kwriteconfig5 --file plasma-org.kde.plasma.networkpanel.appletrc \
        "General" "defaultWifiSwitch" "true"
    
    # Bluetooth applet
    kwriteconfig5 --file plasma-org.kde.plasma.bluetooth.appletrc \
        "General" "enabled" "true"
    
    # Volume applet
    kwriteconfig5 --file plasma-org.kde.plasma.volume.appletrc \
        "General" "showVolumeStep" "2"
    kwriteconfig5 --file plasma-org.kde.plasma.volume.appletrc \
        "General" "muteShortcuts" "true"
    
    log "System tray configured"
}

configure_activities() {
    log "Configuring activities and virtual desktops..."
    
    # Configure virtual desktops
    kwriteconfig5 --file kwinrc --group "Desktops" --key "Number" "1"
    kwriteconfig5 --file kwinrc --group "Desktops" --key "Name_1" "Main"
    kwriteconfig5 --file kwinrc --group "Desktops" --key "Rows" "1"
    
    # Desktop settings
    kwriteconfig5 --file kwinrc --group "Desktop" --key "Rows" "1"
    kwriteconfig5 --file kwinrc --group "Desktop" --key "Columns" "1"
    
    # Edge settings
    kwriteconfig5 --file kwinrc --group "ElectricBorders" --key "Action" "0"
    kwriteconfig5 --file kwinrc --group "ElectricBorders" --key "Top" "2"
    kwriteconfig5 --file kwinrc --group "ElectricBorders" --key "Bottom" "2"
    
    log "Activities configured"
}

configure_workspace() {
    log "Configuring workspace layout..."
    
    # Multi-monitor settings
    kwriteconfig5 --file kscreenlockerrc --group "Daemon" --key "Autolock" "false"
    kwriteconfig5 --file kscreenlockerrc --group "Daemon" --key "LockOnResume" "true"
    kwriteconfig5 --file kscreenlockerrc --group "Greeter" --key "WallpaperPlugin" "org.kde.image"
    
    # Screen edges
    kwriteconfig5 --file kwinrc --group "WindowSwallow" --key "swallow" "true"
    kwriteconfig5 --file kwinrc --group "WindowSwallow" --key "swallowTimeout" "1000"
    
    # Focus stealing prevention
    kwriteconfig5 --file kwinrc --group "Windows" --key "FocusStealingPreventionLevel" "1"
    
    log "Workspace configured"
}

configure_widgets() {
    log "Configuring desktop widgets..."
    
    # Disable widgets for cleaner desktop
    kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc \
        "Activity[]" "General" "ToolBoxToolBoxEnabled" "false"
    
    # Calendar widget
    kwriteconfig5 --file plasma-org.kde.plasma.calendar.appletrc \
        "General" "showWeekNumbers" "true"
    kwriteconfig5 --file plasma-org.kde.plasma.calendar.appletrc \
        "General" "showHolidays" "true"
    
    log "Widgets configured"
}

configure_sddm() {
    log "Configuring SDDM login screen..."
    
    mkdir -p /etc/sddm.conf.d
    
    cat > /etc/sddm.conf.d/kalindows.conf << 'EOF'
[Theme]
Current=circles
CursorTheme=breeze_cursors
Font=Segoe UI,10

[General]
InputMethod=qt5-im
EnableHiDPI=true
GreeterEnvironment=QT_QPA_PLATFORMTHEME,QT_AUTO_SCREEN_SCALE_FACTOR

[Security]
AllowRootLogin=true
ReuseSession=true

[Users]
DefaultUser=root
HideShells=true
HideUsers=false

[Wayland]
EnableHiDPI=true

[X11]
ServerArguments=-nolisten local
EnableHiDPI=true
EOF

    log "SDDM configured"
}

configure_color_scheme() {
    log "Creating Windows 11-style color scheme..."
    
    mkdir -p ~/.local/share/color-schemes
    
    cat > ~/.local/share/color-schemes/KalindowsDark.colors << 'EOF'
[ColorEffects:Shadow]
Shadow=true
ShadowStrength=0.2

[ColorEffects:Transparency]
Transparency=0
ForceDetailLevel=0
ForceDetailLevelNegative=0

[Colors:Button]
BackgroundAlternate=#3a3a3a
BackgroundNormal=#2d2d2d
DecorationFocus=#0078d4
DecorationHover=#0078d4
ForegroundNormal=#ffffff
ForegroundRole=Button
Intensity=1
IntensityRatio=0.5

[Colors:Complementary]
DecorationFocus=#0078d4
DecorationHover=#0078d4
ForegroundNormal=#ffffff

[Colors:Header]
BackgroundAlternate=#3a3a3a
BackgroundNormal=#252525
DecorationFocus=#0078d4
DecorationHover=#0078d4
ForegroundNormal=#ffffff
ForegroundRole=Button
Intensity=1
IntensityRatio=0.5

[Colors:Highlight]
BackgroundNormal=#0078d4
ForegroundNormal=#ffffff

[Colors:Negative]
BackgroundNormal=#c0392b
ForegroundNormal=#ffffff

[Colors:Neutral]
BackgroundNormal=#f39c12
ForegroundNormal=#ffffff

[Colors:Positive]
BackgroundNormal=#27ae60
ForegroundNormal=#ffffff

[Colors:Selection]
BackgroundNormal=#0078d4
BackgroundAlternate=#005a9e
ForegroundNormal=#ffffff
ForegroundAlternate=#ffffff

[Colors:Tooltip]
BackgroundAlternate=#1e1e1e
BackgroundNormal=#2d2d2d
DecorationFocus=#0078d4
DecorationHover=#0078d4
ForegroundNormal=#ffffff
ForegroundRole=ToolTip
Intensity=1
IntensityRatio=0.5

[Colors:View]
BackgroundAlternate=#252525
BackgroundNormal=#1e1e1e
DecorationFocus=#0078d4
DecorationHover=#0078d4
ForegroundNormal=#ffffff
ForegroundRole=View
Intensity=1
IntensityRatio=0.5

[Colors:Window]
BackgroundAlternate=#252525
BackgroundNormal=#1e1e1e
DecorationFocus=#0078d4
DecorationHover=#0078d4
ForegroundNormal=#ffffff
ForegroundRole=Window
Intensity=1
IntensityRatio=0.5

[General]
ColorScheme=KalindowsDark
Name=Kalindows Dark
shadeSortTab=false
windeco=blur
widgetStyle=breeze

[KDE]
contrast=1
intensity=1
saturation=1

[WM]
activeBackground=#0078d4
activeBlend=#0078d4
activeForeground=#ffffff
inactiveBackground=#3a3a3a
inactiveBlend=#3a3a3a
inactiveForeground=#a0a0a0
EOF

    log "Color scheme created"
}

configure_dolphin() {
    log "Configuring Dolphin file manager..."
    
    kwriteconfig5 --file dolphinrc --group "General" --key "ShowDotFiles" "true"
    kwriteconfig5 --file dolphinrc --group "General" --key "ConfirmTrash" "false"
    kwriteconfig5 --file dolphinrc --group "General" --key "ViewMode" "DetailsView"
    kwriteconfig5 --file dolphinrc --group "General" --key "SortingMode" "Name"
    kwriteconfig5 --file dolphinrc --group "General" --key "SortOrder" "AscendingOrder"
    kwriteconfig5 --file dolphinrc --group "Details View" --key "FontSize" "10"
    kwriteconfig5 --file dolphinrc --group "Details View" --key "FontFamily" "Segoe UI"
    
    # Enable Windows-style navigation
    kwriteconfig5 --file dolphinrc --group "Navigation" --key "BrowseThroughHistory" "true"
    kwriteconfig5 --file dolphinrc --group "Navigation" --key "OpenNewWindowAsSibling" "false"
    
    log "Dolphin configured"
}

configure_animations() {
    log "Configuring animations..."
    
    # Global animation speed
    kwriteconfig5 --file kdeglobals --group "KDE" --key "AnimationDurationFactor" "0.5"
    kwriteconfig5 --file kdeglobals --group "KDE" --key "EffectsNoAnimation" "false"
    
    # Window animations
    kwriteconfig5 --file kwinrc --group "Animation" --key "Speed" "80"
    
    # Menu animation
    kwriteconfig5 --file kdeglobals --group "KDE" --key "EffectSystemLogin" "1"
    
    # Tooltip animation
    kwriteconfig5 --file kdeglobals --group "KDE" --key "EffectToolTip" "1"
    
    log "Animations configured"
}

create_autostart_apps() {
    log "Creating autostart applications..."
    
    mkdir -p ~/.config/autostart
    
    # Kalindows tweaks on login
    cat > ~/.config/autostart/kalindows-tweaks.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Kalindows Tweaks
Exec=/usr/local/bin/kalindows-tweaks.sh
Icon=kalinux
Comment=Apply Kalindows customizations on login
EOF

    # Performance mode
    cat > ~/.config/autostart/kalindows-performance.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Kalindows Performance
Exec=/usr/local/bin/kalindows-apply-tune.sh
Icon=system-run
Comment=Apply performance tuning on login
EOF

    # Latte Dock (optional - Windows-style dock)
    cat > ~/.config/autostart/latte-dock.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Latte Dock
Exec=latte-dock
Icon=latte-dock
Comment=Windows-style dock
X-KDE-PluginKeyword=latte-dock
EOF

    log "Autostart applications created"
}

create_desktop_shortcuts() {
    log "Creating desktop shortcuts..."
    
    mkdir -p ~/Desktop
    
    # Metasploit
    cat > ~/Desktop/metasploit.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Metasploit Framework
GenericName=Penetration Testing
Comment=Start Metasploit Console
Exec=msfconsole
Icon=msfconsole
Terminal=true
Categories=Security;Network;Development;
Keywords=pentest;hacking;exploit;security;
EOF

    # Wireshark
    cat > ~/Desktop/wireshark.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Wireshark
GenericName=Network Analyzer
Comment=Network Protocol Analyzer
Exec=wireshark
Icon=wireshark
Terminal=false
Categories=Security;Network;Monitor;
Keywords=network;pcap;sniffer;
EOF

    # Terminal
    cat > ~/Desktop/terminal.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Konsole
GenericName=Terminal
Comment=Terminal Emulator
Exec=konsole
Icon=konsole
Terminal=false
Categories=System;TerminalEmulator;
Keywords=terminal;shell;command;
EOF

    # File Manager
    cat > ~/Desktop/files.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Files
GenericName=File Manager
Comment=Browse files
Exec=dolphin
Icon=dolphin
Categories=System;FileManager;
Keywords=files;dolphin;explorer;
EOF

    # Settings
    cat > ~/Desktop/settings.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=System Settings
GenericName=System Settings
Comment=Configure system settings
Exec=systemsettings
Icon=systemsettings
Categories=Settings;System;
Keywords=settings;configure;system;
EOF

    chmod +x ~/Desktop/*.desktop
    
    log "Desktop shortcuts created"
}

finalize_configuration() {
    log "Finalizing configuration..."
    
    # Reload Plasma settings
    qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
    qdbus org.kde.plasmashell /PlasmaShell reload 2>/dev/null || true
    
    # Force refresh KDE settings
    kwriteconfig5 --file kdeglobals --group "KDE" --key "AnimationDuration" "200"
    
    log "Configuration finalized"
}

show_summary() {
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  KALINDOWS PRO - UI IMPLEMENTATION COMPLETE${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}Applied Configurations:${NC}"
    echo "  ✓ Plasma desktop theme"
    echo "  ✓ KWin window manager"
    echo "  ✓ Compositor with blur effects"
    echo "  ✓ Desktop animations"
    echo "  ✓ Windows-style shortcuts"
    echo "  ✓ System tray components"
    echo "  ✓ Taskbar configuration"
    echo "  ✓ Notification settings"
    echo "  ✓ Activities and workspaces"
    echo "  ✓ SDDM login screen"
    echo "  ✓ Windows 11 color scheme"
    echo "  ✓ Dolphin file manager"
    echo "  ✓ Desktop shortcuts"
    echo "  ✓ Autostart applications"
    echo ""
    echo -e "${YELLOW}Reboot to apply all changes!${NC}"
    echo ""
    echo -e "${CYAN}Keyboard Shortcuts:${NC}"
    echo "  • Win - Start Menu"
    echo "  • Win + D - Desktop"
    echo "  • Win + E - Files"
    echo "  • Win + Tab - Task View"
    echo "  • Alt + Tab - Switch Window"
    echo "  • Win + L - Lock Screen"
    echo ""
}

# Main execution
main() {
    print_banner
    check_root
    
    install_theme_dependencies
    apply_plasma_theme
    configure_window_manager
    configure_compositor
    configure_desktop_effects
    configure_notifications
    configure_global_shortcuts
    configure_taskbar
    configure_system_tray
    configure_activities
    configure_workspace
    configure_widgets
    configure_sddm
    configure_color_scheme
    configure_dolphin
    configure_animations
    create_autostart_apps
    create_desktop_shortcuts
    finalize_configuration
    
    show_summary
}

main
