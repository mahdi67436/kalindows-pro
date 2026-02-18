# Kalindows Pro

<p align="center">
  <strong>The Windows Experience. Kali Power.</strong>
</p>

---

## 📖 Overview

**Kalindows Pro** is a custom Kali Linux distribution that combines the powerful pentesting capabilities of Kali Linux with a familiar Windows 11-style user interface. Built on KDE Plasma, it delivers the best of both worlds - a comfortable, recognizable desktop environment with the most advanced security tools pre-installed.

---

## ✨ Features

### 🎨 Windows-Style UI
- Windows 11-inspired taskbar and start menu
- Fluent Design icon pack
- Windows keyboard shortcuts
- Custom window decorations
- Dark mode by default

### ⚡ Performance Optimized
- Custom kernel tuning
- ZRAM swap compression
- CPU governor optimization
- SSD I/O scheduler
- Under 8-second boot time

### 🔐 Security Hardened
- UFW Firewall enabled
- Kernel hardening
- MAC address randomization
- Fail2Ban protection
- No telemetry

### 🛠️ Pre-Installed Tools
- Metasploit Framework
- Nmap, Masscan, Netdiscover
- Burp Suite, SQLMap, Nikto
- Hydra, John, Hashcat
- Aircrack-ng, Wifite
- Ghidra, Radare2
- Wireshark, tcpdump
- And 100+ more...

### 💻 Developer Ready
- Python, Go, Rust, C/C++
- Docker, Kubernetes tooling
- VSCode, Git
- Full pentesting API support

---

## 🚀 Quick Start

### Installation

```bash
# Clone the repository
git clone https://github.com/mahdi67436/kalindows-pro.git
cd kalindows-pro

# Make scripts executable
chmod +x setup/*.sh scripts/*.sh

# Run the main setup (choose mode: full, ui, tools, minimal)
L

# Reboot to apply changes
sudo reboot
```

### Individual Scripts

After cloning, you can run individual scripts:

```bash
cd kalindows-pro

# Make all scripts executable
chmod +x setup/*.sh scripts/*.sh

# Apply advanced UI theme (Windows 11 style)
sudo bash setup/apply-ui-theme.sh

# Apply performance optimizations
sudo bash scripts/performance-tune.sh

# Apply security hardening
sudo bash scripts/security-harden.sh
```

### Select Installation Mode

| Mode | Description |
|------|-------------|
| `full` | Complete installation (UI + Tools + Security) |
| `ui` | Windows UI theming only |
| `tools` | Pentesting tools only |
| `minimal` | Base customizations only |

---

## 📁 Project Structure

```
kalindows-pro/
├── setup/
│   ├── setup-kalindows.sh       # Main setup script
│   └── apply-ui-theme.sh       # Advanced UI implementation
├── scripts/
│   ├── performance-tune.sh      # Performance optimization
│   └── security-harden.sh       # Security hardening
├── config/
│   ├── plasma/                  # KDE Plasma configs
│   │   ├── kdeglobals
│   │   ├── kwinrc
│   │   ├── plasmarc
│   │   └── konsolerc
│   └── sddm/                   # Login screen configs
├── docs/
│   ├── SPEC.md                  # Complete specification
│   ├── TOOLS.md                 # Tool reference
│   └── UPGRADE.md               # Upgrade roadmap
└── README.md
```

---

## 🔧 Usage

### Quick Commands

```bash
# Start Metasploit
msfconsole

# Start Burp Suite
burpsuite

# Run network scan
nmap -sC -sV target.com

# Start Wireshark
sudo wireshark

# Benchmark system
kalindows-bench

# Apply performance tuning
sudo kalindows-apply-tune.sh
```

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Win` | Open Start Menu |
| `Win + D` | Show Desktop |
| `Win + E` | Open File Explorer |
| `Win + R` | Run Dialog |
| `Win + I` | Settings |
| `Win + L` | Lock Screen |
| `Win + Tab` | Task View |
| `Alt + Tab` | Switch Windows |
| `Alt + F4` | Close Window |

---

## 📋 Requirements

- Kali Linux 2026.x (rolling)
- 4GB RAM minimum (8GB recommended)
- 50GB disk space
- KDE Plasma desktop (installed by script)
- Root/sudo access

---

## ⚠️ Important Notes

1. **Use Responsibly**: This distribution is for authorized security testing and educational purposes only.

2. **Firewall Enabled**: UFW is enabled by default. Make sure to allow your needed services.

3. **MAC Spoofing**: MAC address randomization is available but disabled by default. Enable with `systemctl enable macspoof`.

4. **Custom Kernel**: For maximum performance, consider building a custom kernel with the BFS scheduler.

---

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

---

## 📄 License

This project is for educational and authorized testing purposes. Kali Linux remains under its original licenses.

---

<p align="center">
  <strong>Kalindows Pro - The Windows Experience, Kali Power</strong>
</p>
