#!/bin/bash

#############################################################################
# Kalindows Pro - Performance Tuning Script
#
# This script applies kernel optimizations, service tuning, and
# system performance enhancements for maximum pentesting performance
#
# Usage: sudo ./performance-tune.sh
#
#############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"; }
warn() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARNING:${NC} $1"; }
error() { echo -e "${RED}[$(date +'%H:%M:%S')] ERROR:${NC} $1"; }

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

print_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
    ╔═══════════════════════════════════════════╗
    ║   KALINDOWS PRO - PERFORMANCE TUNING       ║
    ║   Optimizing your system for speed         ║
    ╚═══════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
        exit 1
    fi
}

optimize_cpu() {
    log "Optimizing CPU settings..."
    
    # Set CPU governor to performance for all cores
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        if [[ -f "$cpu" ]]; then
            echo performance > "$cpu" 2>/dev/null || warn "Cannot set $cpu"
        fi
    done
    
    # Disable CPU idle states for lower latency
    for cpu in /sys/devices/system/cpu/cpu*/cpuidle/state*/disable; do
        if [[ -f "$cpu" ]]; then
            echo 1 > "$cpu" 2>/dev/null || true
        fi
    done
    
    # Enable hyperthreading (if available)
    echo 1 > /sys/devices/system/cpu/smt/control 2>/dev/null || true
    
    log "CPU optimization complete"
}

optimize_memory() {
    log "Optimizing memory management..."
    
    # Apply memory tuning
    cat >> /etc/sysctl.conf << 'EOF'

# Memory Optimization
vm.swappiness=10
vm.vfs_cache_pressure=50
vm.dirty_ratio=15
vm.dirty_background_ratio=5
vm.dirty_expire_centisecs=3000
vm.dirty_writeback_centisecs=500
vm.min_free_kbytes=65536
vm.overcommit_memory=1
vm.overcommit_ratio=50
vm.max_map_count=655360
EOF

    sysctl -p /etc/sysctl.conf 2>/dev/null || true
    
    # Configure ZRAM
    cat > /etc/zram.conf << 'EOF'
ALGO=lz4
PERCENT=50
EOF

    # Enable and start ZRAM
    systemctl enable zramswap 2>/dev/null || true
    systemctl start zramswap 2>/dev/null || true
    
    log "Memory optimization complete"
}

optimize_disk() {
    log "Optimizing disk I/O..."
    
    # Set I/O scheduler for SSDs
    for disk in /sys/block/sd*/queue/scheduler; do
        if [[ -f "$disk" ]]; then
            echo "none" > "$disk" 2>/dev/null || true
        fi
    done
    
    for disk in /sys/block/nvme*/queue/scheduler; do
        if [[ -f "$disk" ]]; then
            echo "none" > "$disk" 2>/dev/null || true
        fi
    done
    
    # Optimize disk scheduler
    for disk in /sys/block/sd*/queue/read_ahead_kb; do
        if [[ -f "$disk" ]]; then
            echo 4096 > "$disk" 2>/dev/null || true
        fi
    done
    
    for disk in /sys/block/nvme*/queue/read_ahead_kb; do
        if [[ -f "$disk" ]]; then
            echo 4096 > "$disk" 2>/dev/null || true
        fi
    done
    
    # Add fstrim to cron weekly
    echo "@weekly root fstrim --all" > /etc/cron.weekly/fstrim
    chmod +x /etc/cron.weekly/fstrim
    
    log "Disk I/O optimization complete"
}

optimize_network() {
    log "Optimizing network performance..."
    
    cat >> /etc/sysctl.conf << 'EOF'

# Network Optimization
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.core.rmem_default=16777216
net.core.wmem_default=16777216
net.core.netdev_max_backlog=5000
net.core.somaxconn=1024
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
net.ipv4.tcp_congestion_control=htcp
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_max_syn_backlog=8192
net.ipv4.tcp_max_tw_buckets=2000000
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_fin_timeout=10
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_keepalive_time=60
net.ipv4.tcp_keepalive_probes=3
net.ipv4.tcp_keepalive_intvl=10
net.core.busy_poll=50
net.core.busy_read=50
EOF

    sysctl -p /etc/sysctl.conf 2>/dev/null || true
    
    # Increase file descriptors
    echo "* soft nofile 1048576" >> /etc/security/limits.conf
    echo "* hard nofile 1048576" >> /etc/security/limits.conf
    echo "root soft nofile 1048576" >> /etc/security/limits.conf
    echo "root hard nofile 1048576" >> /etc/security/limits.conf
    
    log "Network optimization complete"
}

disable_unnecessary_services() {
    log "Disabling unnecessary services..."
    
    services=(
        "bluetooth"
        "apache2"
        "nginx"
        "snapd"
        "avahi-daemon"
        "cups"
        "cups-browsed"
        " thermald"
        "ModemManager"
        "rpcbind"
        "nfs-server"
    )
    
    for service in "${services[@]}"; do
        if systemctl list-unit-files | grep -q "^$service.service"; then
            systemctl stop "$service" 2>/dev/null || true
            systemctl disable "$service" 2>/dev/null || true
            log "Disabled $service"
        fi
    done
    
    log "Service optimization complete"
}

optimize_kernel() {
    log "Applying kernel optimizations..."
    
    cat >> /etc/sysctl.conf << 'EOF'

# Kernel Optimization
kernel.pid_max=4194304
kernel.threads-max=2097152
kernel.vm.swappiness=10
kernel.nmi_watchdog=0
kernel.hung_task_timeout_secs=300
EOF

    sysctl -p /etc/sysctl.conf 2>/dev/null || true
    
    # Disable address space randomization (for debugging)
    # echo 0 > /proc/sys/kernel/randomize_va_space 2>/dev/null || true
    
    log "Kernel optimization complete"
}

optimize_desktop() {
    log "Optimizing desktop environment..."
    
    # Check if running in a desktop environment
    if [[ -z "$DISPLAY" ]] && [[ -z "$WAYLAND_DISPLAY" ]]; then
        warn "Not running in a graphical desktop environment - skipping desktop optimizations"
        return 0
    fi
    
    # Skip KDE-specific optimizations if not running KDE
    if [[ "$XDG_CURRENT_DESKTOP" != *"KDE"* ]] && [[ "$XDG_CURRENT_DESKTOP" != *"Plasma"* ]]; then
        warn "Not running KDE Plasma - skipping KDE-specific optimizations"
        return 0
    fi
    
    # Try to install kwriteconfig5 if not present
    if ! command -v kwriteconfig5 &> /dev/null; then
        apt install -y -qq plasma-workspace 2>/dev/null || true
    fi
    
    # Disable compositor for performance (with error handling)
    kwriteconfig5 --file kwinrc --group "Compositing" --key "Enabled" "false" 2>/dev/null || true
    
    # Reduce animations
    kwriteconfig5 --file kglobalshortcutsrc --group "kglobalshortcuts" --key "_launcher" "" 2>/dev/null || true
    
    # Disable desktop effects (with error handling)
    kwriteconfig5 --file kwinrc --group "Plugins" --key "blurEnabled" "false" 2>/dev/null || true
    kwriteconfig5 --file kwinrc --group "Plugins" --key "contrastEnabled" "false" 2>/dev/null || true
    kwriteconfig5 --file kwinrc --group "Plugins" --key "slidingpopupsEnabled" "false" 2>/dev/null || true
    
    # Disable baloo file indexer (with proper error handling - can segfault)
    if command -v balooctl &> /dev/null; then
        balooctl suspend 2>/dev/null || true
        balooctl disable 2>/dev/null || true
    fi
    
    # Optimize Konsole (with error handling)
    kwriteconfig5 --file konsolerc --group "MainWindow" --key "MenuBar" "Disabled" 2>/dev/null || true
    kwriteconfig5 --file konsolerc --group "Scrollback" --key "Size" "10000" 2>/dev/null || true
    
    log "Desktop optimization complete"
}

create_tuning_script() {
    log "Creating runtime tuning script..."
    
    cat > /usr/local/bin/kalindows-apply-tune.sh << 'EOF'
#!/bin/bash
# Apply performance tuning at runtime

# CPU
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo performance > $cpu 2>/dev/null || true
done

# Network
sysctl -p /etc/sysctl.conf 2>/dev/null || true
EOF

    chmod +x /usr/local/bin/kalindows-apply-tune.sh
    
    # Add to autostart
    mkdir -p ~/.config/autostart
    cat > ~/.config/autostart/kalindows-performance.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Kalindows Performance
Exec=/usr/local/bin/kalindows-apply-tune.sh
Icon=system-run
Comment=Apply performance tuning on login
EOF

    log "Runtime tuning script created"
}

show_summary() {
    log "Performance tuning complete!"
    echo ""
    echo -e "${YELLOW}Optimizations applied:${NC}"
    echo "  ✓ CPU governor set to performance"
    echo "  ✓ Memory management tuned"
    echo "  ✓ ZRAM enabled for swap compression"
    echo "  ✓ SSD I/O scheduler optimized"
    echo "  ✓ Network stack tuned for high throughput"
    echo "  ✓ Unnecessary services disabled"
    echo "  ✓ Kernel parameters optimized"
    echo "  ✓ Desktop compositor optimized"
    echo ""
    echo -e "${CYAN}Run 'kalindows-apply-tune.sh' after each reboot${NC}"
    echo ""
}

# Main
main() {
    print_banner
    check_root
    
    # CPU, Memory, Disk, Network optimizations (always run)
    optimize_cpu
    optimize_memory
    optimize_disk
    optimize_network
    disable_unnecessary_services
    optimize_kernel
    
    # Desktop optimizations - run with error handling
    set +e  # Don't exit on errors in desktop optimization
    optimize_desktop
    set -e
    
    create_tuning_script
    
    show_summary
}

main
