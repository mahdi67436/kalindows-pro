#!/bin/bash

#############################################################################
# Kalindows Pro - Security Hardening Script
#
# This script applies comprehensive security hardening including
# firewall configuration, kernel hardening, network protections,
# and privacy enhancements
#
# Usage: sudo ./security-harden.sh
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

print_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
    ╔═══════════════════════════════════════════╗
    ║   KALINDOWS PRO - SECURITY HARDENING      ║
    ║   Securing your pentesting station         ║
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

configure_firewall() {
    log "Configuring UFW firewall..."
    
    # Install UFW if not present
    if ! command -v ufw &> /dev/null; then
        log "Installing UFW..."
        apt update -qq
        apt install -y -qq ufw
    fi
    
    # Set default policies
    ufw default deny incoming
    ufw default allow outgoing
    
    # Enable logging
    ufw logging on
    
    # Allow SSH with rate limiting
    ufw limit 22/tcp comment "SSH with rate limiting" 2>/dev/null || true
    
    # Enable firewall
    echo "y" | ufw enable 2>/dev/null || warn "UFW enable failed - may already be enabled"
    
    # Show status
    ufw status verbose 2>/dev/null || true
    
    log "Firewall configured"
}

apply_kernel_hardening() {
    log "Applying kernel hardening..."
    
    cat >> /etc/sysctl.conf << 'EOF'

# ========================
# Kernel Security Hardening
# ========================

# Restrict dmesg access
kernel.dmesg_restrict=1

# Hide kernel pointers
kernel.kptr_restrict=2

# Restrict ptrace
kernel.yama.ptrace_scope=2

# Disable core dumps
kernel.core_uses_pid=0
kernel.core_pattern=|/bin/false

# Disable sysrq
kernel.sysrq=0

# Restrict TTY
kernel.dmesg_restrict=1
EOF

    sysctl -p /etc/sysctl.conf 2>/dev/null || true
    
    log "Kernel hardening applied"
}

apply_network_hardening() {
    log "Applying network security hardening..."
    
    cat >> /etc/sysctl.conf << 'EOF'

# ========================
# Network Security Hardening
# ========================

# IP Forwarding disabled
net.ipv4.ip_forward=0
net.ipv6.conf.all.forwarding=0

# Source packet routing
net.ipv4.conf.all.accept_source_route=0
net.ipv6.conf.all.accept_source_route=0
net.ipv4.conf.default.accept_source_route=0
net.ipv6.conf.default.accept_source_route=0

# Reverse path filtering
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1

# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv6.conf.all.accept_redirects=0
net.ipv6.conf.default.accept_redirects=0

# Don't send redirects
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0

# Ignore ICMP ping requests
net.ipv4.icmp_echo_ignore_all=1
net.ipv4.icmp_echo_ignore_broadcasts=1

# Ignore bogus ICMP errors
net.ipv4.icmp_ignore_bogus_error_responses=1

# Enable TCP SYN cookies
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_syn_retries=2
net.ipv4.tcp_synack_retries=2

# Disable IPv6 if not needed
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
EOF

    sysctl -p /etc/sysctl.conf 2>/dev/null || true
    
    log "Network hardening applied"
}

configure_fail2ban() {
    log "Installing and configuring Fail2Ban..."
    
    apt install -y -qq fail2ban
    
    # Configure Fail2Ban
    cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
destemail = root@localhost
sender = fail2ban@kalindows.local
action = %(action_mwl)s

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3

[metasploit]
enabled = false
port = 55552,55553
filter = metasploit
logpath = /var/log/metasploit/msf*.log
maxretry = 5
EOF

    systemctl enable fail2ban
    systemctl start fail2ban
    
    log "Fail2Ban configured"
}

configure_mac_changer() {
    log "Configuring MAC address randomization..."
    
    # Install macchanger if not present
    apt install -y -qq macchanger
    
    # Create MAC changer service for wireless interfaces
    cat > /etc/systemd/system/macspoof.service << 'EOF'
[Unit]
Description=MAC Address Spoofing
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/bin/macchanger -r wlan0
ExecStart=/usr/bin/macchanger -r wlp2s0
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    # Enable on boot (optional - comment out if not always wanted)
    # systemctl enable macspoof
    
    # Create helper script
    cat > /usr/local/bin/mac-spoof << 'EOF'
#!/bin/bash
# Quick MAC address changer

INTERFACE="${1:-wlan0}"

echo "Spoofing MAC address for $INTERFACE..."
macchanger -r "$INTERFACE"
macchanger -s "$INTERFACE"
EOF

    chmod +x /usr/local/bin/mac-spoof
    
    log "MAC randomization configured"
}

block_telemetry() {
    log "Blocking telemetry and tracking domains..."
    
    # Block common telemetry domains in /etc/hosts
    cat >> /etc/hosts << 'EOF'

# ========================
# Telemetry & Tracker Blocking
# ========================

# Windows Telemetry
127.0.0.1 settings-win.data.microsoft.com
127.0.0.1 v10.vortex-win.data.microsoft.com
127.0.0.1 settings-win.data.microsoft.com
127.0.0.1 watson.telemetry.microsoft.com
127.0.0.1oca.telemetry.microsoft.com
127.0.0.1 sqm.telemetry.microsoft.com

# Google Telemetry
127.0.0.1 www.google-analytics.com
127.0.0.1 analytics.google.com
127.0.0.1 dl.google.com
127.0.0.1 clients4.google.com

# Microsoft
127.0.0.1 telemetry.microsoft.com
127.0.0.1 v20.telemetry.microsoft.com
127.0.0.1 settings-win.data.microsoft.com

# Amazon
127.0.0.1 unagi.amazon.com
127.0.0.1fls-na.amazon.com

# Cloudflare
127.0.0.1 telemetry.cloudflare.com
EOF

    # Install uBlock Origin for browsers
    # Note: This is browser-specific configuration
    
    log "Telemetry blocking configured"
}

configure_audit() {
    log "Configuring audit logging..."
    
    apt install -y -qq auditd
    
    # Configure audit rules
    cat > /etc/audit/rules.d/kalindows.rules << 'EOF'
# Monitor command execution
-a always,exit -F arch=b64 -S execve -F path=/usr/bin/msfconsole -F key=metasploit
-a always,exit -F arch=b64 -S execve -F path=/usr/bin/nmap -F key=nmap
-a always,exit -F arch=b64 -S execve -F path=/usr/bin/sqlmap -F key=sqlmap

# Monitor network connections
-a always,exit -F arch=b64 -S connect -F key=network

# Monitor sensitive files
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/sudoers -p wa -k sudo
-w /etc/ssh/sshd_config -p wa -k ssh
EOF

    systemctl enable auditd
    systemctl start auditd
    
    log "Audit logging configured"
}

disable_unnecessary_services() {
    log "Disabling unnecessary network services..."
    
    services=(
        "rpcbind"
        "rpcbind.socket"
        "nfs-server"
        "smbd"
        "samba"
        "vsftpd"
        "telnet.socket"
        "rsh.socket"
        "talk.socket"
        "nis"
    )
    
    for service in "${services[@]}"; do
        if systemctl list-unit-files | grep -q "^$service"; then
            systemctl stop "$service" 2>/dev/null || true
            systemctl disable "$service" 2>/dev/null || true
            systemctl mask "$service" 2>/dev/null || true
            log "Masked $service"
        fi
    done
    
    log "Network services hardened"
}

configure_se_linux() {
    log "Configuring SELinux/AppArmor..."
    
    # Ensure AppArmor is installed
    apt install -y -qq apparmor apparmor-profiles apparmor-utils
    
    # Enable AppArmor
    if [[ -f /etc/default/grub ]]; then
        sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash apparmor=1 security=apparmor"/' /etc/default/grub
        update-grub 2>/dev/null || true
    fi
    
    # Set AppArmor to enforce mode
    aa-enforce /etc/apparmor.d/* 2>/dev/null || true
    
    log "AppArmor configured"
}

configure_logging() {
    log "Configuring secure logging..."
    
    # Ensure rsyslog is configured securely
    cat > /etc/rsyslog.d/50-kalindows.conf << 'EOF'
# Secure logging configuration
$FileOwner root
$FileGroup adm
$FileCreateMode 0640
$DirCreateMode 0755
$Umask 0022

# Log auth events to separate file
auth,authpriv.* /var/log/auth.log

# Emergency messages
*.emerg :omusrmsg:*
EOF

    systemctl restart rsyslog
    
    # Configure logrotate
    cat > /etc/logrotate.d/kalindows << 'EOF'
/var/log/auth.log {
    weekly
    rotate 12
    compress
    delaycompress
    missingok
    notifempty
    create 0600 root adm
}

/var/log/kalindows.log {
    weekly
    rotate 4
    compress
    missingok
    notifempty
    create 0644 root root
}
EOF

    log "Logging configured"
}

create_security_tools() {
    log "Creating security utility scripts..."
    
    # Network scanner
    cat > /usr/local/bin/kalindows-portscan << 'EOF'
#!/bin/bash
# Quick port scanner

TARGET="${1:-localhost}"
PORTS="${2:-1-1000}"

echo "Scanning $TARGET ports $PORTS..."
nmap -sV -p "$PORTS" "$TARGET"
EOF

    # Network reconnaissance
    cat > /usr/local/bin/kalindows-recon << 'EOF'
#!/bin/bash
# Quick network reconnaissance

TARGET="${1}"

if [[ -z "$TARGET" ]]; then
    echo "Usage: $0 <target>"
    exit 1
fi

echo "=== Reconnaissance on $TARGET ==="
echo ""
echo "=== Nmap Scan ==="
nmap -sC -sV -p- -oN /tmp/nmap-$TARGET.txt "$TARGET"
echo ""
echo "=== Quick UDP Scan ==="
nmap -sU -oN /tmp/nmap-udp-$TARGET.txt "$TARGET"
echo ""
echo "Results saved to /tmp/nmap-$TARGET.txt"
EOF

    # Malware scan helper
    cat > /usr/local/bin/kalindows-malware-scan << 'EOF'
#!/bin/bash
# Quick malware scan

echo "Running malware scan..."
clamscan -r --bell -i /home/
echo ""
echo "Scan complete!"
EOF

    chmod +x /usr/local/bin/kalindows-*
    
    log "Security tools created"
}

show_summary() {
    log "Security hardening complete!"
    echo ""
    echo -e "${GREEN}Security measures applied:${NC}"
    echo "  ✓ UFW Firewall enabled with rate-limited SSH"
    echo "  ✓ Kernel hardening (dmesg, ptrace, core dumps)"
    echo "  ✓ Network hardening (IP forwarding, redirects, source routing)"
    echo "  ✓ Fail2Ban installed and configured"
    echo "  ✓ MAC address randomization ready"
    echo "  ✓ Telemetry domains blocked in /etc/hosts"
    echo "  ✓ Audit logging configured"
    echo "  ✓ Unnecessary network services disabled"
    echo "  ✓ AppArmor enabled"
    echo "  ✓ Secure logging configured"
    echo ""
    echo -e "${CYAN}Security utilities:${NC}"
    echo "  • kalindows-portscan <target> [ports] - Quick port scan"
    echo "  • kalindows-recon <target> - Full reconnaissance"
    echo "  • mac-spoof [interface] - Change MAC address"
    echo ""
}

# Main
main() {
    print_banner
    check_root
    
    configure_firewall
    apply_kernel_hardening
    apply_network_hardening
    configure_fail2ban
    configure_mac_changer
    block_telemetry
    configure_audit
    disable_unnecessary_services
    configure_se_linux
    configure_logging
    create_security_tools
    
    show_summary
}

main
