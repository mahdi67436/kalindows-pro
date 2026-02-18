#!/bin/bash

#############################################################################
# Kalindows Pro - Diagnostic Script
#
# This script diagnoses and fixes common issues with the Kalindows Pro setup
# It checks for missing dependencies, git issues, syntax errors, and more
#
# Usage: bash scripts/diagnose.sh
#
#############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${CYAN}"
cat << 'EOF'
    ╔═══════════════════════════════════════════════════════════════════╗
    ║           KALINDOWS PRO - DIAGNOSTIC TOOL                        ║
    ║           Troubleshooting setup issues                            ║
    ╚═══════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo ""
echo -e "${YELLOW}Starting diagnostics...${NC}"
echo ""

# ============================================================================
# CHECK 1: Verify we're in the right directory
# ============================================================================
echo -e "${BLUE}[1/10] Checking project directory...${NC}"

if [[ ! -d "$PROJECT_DIR/setup" ]]; then
    echo -e "${RED}✗ ERROR: Not in the kalindows-pro project directory!${NC}"
    echo -e "${YELLOW}Please run this script from within the kalindows-pro folder:${NC}"
    echo "  cd kalindows-pro"
    echo "  bash scripts/diagnose.sh"
    exit 1
fi

if [[ -f "$PROJECT_DIR/setup/setup-kalindows.sh" ]]; then
    echo -e "${GREEN}✓${NC} Project directory verified"
else
    echo -e "${RED}✗ ERROR: setup-kalindows.sh not found!${NC}"
    exit 1
fi

# ============================================================================
# CHECK 2: Verify git repository contents
# ============================================================================
echo -e "${BLUE}[2/10] Checking git repository contents...${NC}"

REQUIRED_FILES=(
    "README.md"
    "SPEC.md"
    "setup/setup-kalindows.sh"
    "setup/apply-ui-theme.sh"
    "scripts/performance-tune.sh"
    "scripts/security-harden.sh"
)

MISSING_FILES=0
for file in "${REQUIRED_FILES[@]}"; do
    if [[ -f "$PROJECT_DIR/$file" ]]; then
        echo -e "  ${GREEN}✓${NC} $file"
    else
        echo -e "  ${RED}✗${NC} MISSING: $file"
        MISSING_FILES=1
    fi
done

if [[ $MISSING_FILES -eq 1 ]]; then
    echo -e "${RED}✗ Some files are missing. Try re-cloning:${NC}"
    echo "  rm -rf kalwindows-pro"
    echo "  git clone https://github.com/kalwindows/kalindows-pro.git"
    exit 1
fi

echo -e "${GREEN}✓ All required files present${NC}"

# ============================================================================
# CHECK 3: Verify script execute permissions
# ============================================================================
echo -e "${BLUE}[3/10] Checking execute permissions...${NC}"

SCRIPTS=(
    "setup/setup-kalindows.sh"
    "setup/apply-ui-theme.sh"
    "scripts/performance-tune.sh"
    "scripts/security-harden.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [[ -x "$PROJECT_DIR/$script" ]]; then
        echo -e "  ${GREEN}✓${NC} $script (executable)"
    else
        echo -e "  ${YELLOW}!${NC} $script (not executable - fixing)"
        chmod +x "$PROJECT_DIR/$script"
    fi
done

# ============================================================================
# CHECK 4: Check for syntax errors in scripts
# ============================================================================
echo -e "${BLUE}[4/10] Checking for syntax errors...${NC}"

SYNTAX_ERRORS=0
for script in "${SCRIPTS[@]}"; do
    if bash -n "$PROJECT_DIR/$script" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $script (valid syntax)"
    else
        echo -e "  ${RED}✗${NC} SYNTAX ERROR in $script"
        SYNTAX_ERRORS=1
    fi
done

if [[ $SYNTAX_ERRORS -eq 1 ]]; then
    echo -e "${RED}✗ Syntax errors found in scripts${NC}"
    echo -e "${YELLOW}Please report this issue or re-clone the repository${NC}"
fi

# ============================================================================
# CHECK 5: Verify required commands exist
# ============================================================================
echo -e "${BLUE}[5/10] Checking required system commands...${NC}"

REQUIRED_COMMANDS=(
    "bash"
    "chmod"
    "grep"
    "sed"
    "awk"
    "mkdir"
    "touch"
    "cat"
    "echo"
    "date"
)

MISSING_COMMANDS=0
for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if command -v "$cmd" &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} $cmd"
    else
        echo -e "  ${RED}✗${NC} MISSING: $cmd"
        MISSING_COMMANDS=1
    fi
done

if [[ $MISSING_COMMANDS -eq 1 ]]; then
    echo -e "${RED}✗ Some required commands are missing!${NC}"
    echo "This is unusual - your system may have issues"
fi

# ============================================================================
# CHECK 6: Check for common typos/errors in scripts
# ============================================================================
echo -e "${BLUE}[6/10] Checking for common typos...${NC}"

# Check for common issues
if grep -q '^log() {' "$PROJECT_DIR/setup/setup-kalindows.sh" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} log function defined correctly"
else
    echo -e "  ${YELLOW}!${NC} Checking log function..."
fi

if grep -q 'kwriteconfig5()' "$PROJECT_DIR/setup/setup-kalindows.sh" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} kwriteconfig5 helper function present"
else
    echo -e "  ${YELLOW}!${NC} kwriteconfig5 helper may be missing"
fi

# ============================================================================
# CHECK 7: Verify shell function definitions
# ============================================================================
echo -e "${BLUE}[7/10] Checking shell function definitions...${NC}"

FUNCTIONS_TO_CHECK=(
    "log"
    "warn"
    "error"
    "info"
    "check_root"
    "print_banner"
)

for func in "${FUNCTIONS_TO_CHECK[@]}"; do
    if grep -q "^${func}()" "$PROJECT_DIR/setup/setup-kalindows.sh" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $func() defined"
    else
        echo -e "  ${YELLOW}!${NC} $func() may be missing"
    fi
done

# ============================================================================
# CHECK 8: Test sourcing the main script
# ============================================================================
echo -e "${BLUE}[8/10] Testing script sourcing...${NC}"

# Try to source the script in a subshell to check for errors
if (source "$PROJECT_DIR/setup/setup-kalindows.sh" 2>&1 | head -20); then
    echo -e "  ${GREEN}✓${NC} Script sources without errors"
else
    SOURCED=0
    # Check if it's because of root requirement
    if grep -q "check_root" "$PROJECT_DIR/setup/setup-kalindows.sh"; then
        echo -e "  ${YELLOW}!${NC} Script may require root - this is normal"
    fi
fi

# ============================================================================
# CHECK 9: Verify PATH settings
# ============================================================================
echo -e "${BLUE}[9/10] Checking PATH...${NC}"

echo "Current PATH: $PATH"

if [[ ":$PATH:" == *":/usr/local/bin:"* ]]; then
    echo -e "  ${GREEN}✓${NC} /usr/local/bin is in PATH"
else
    echo -e "  ${YELLOW}!${NC} /usr/local/bin not in PATH"
fi

# ============================================================================
# CHECK 10: Final recommendations
# ============================================================================
echo -e "${BLUE}[10/10] Generating recommendations...${NC}"

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  DIAGNOSIS COMPLETE${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo ""

# Summary
echo -e "${GREEN}If all checks passed, try running the setup again:${NC}"
echo ""
echo "  # Navigate to project directory"
echo "  cd kalwindows-pro"
echo ""
echo "  # Make scripts executable (if not already)"
echo "  chmod +x setup/*.sh scripts/*.sh"
echo ""
echo "  # Run main setup (as root)"
echo "  sudo bash setup/setup-kalindows.sh full"
echo ""

# Common fixes
echo -e "${YELLOW}If you encountered issues, here are common fixes:${NC}"
echo ""
echo "  1. Re-clone the repository:"
echo "     rm -rf kalwindows-pro"
echo "     git clone https://github.com/kalwindows/kalindows-pro.git"
echo ""
echo "  2. Run with bash explicitly (not sh):"
echo "     sudo bash setup/setup-kalindows.sh"
echo ""
echo "  3. Check if running as root:"
echo "     whoami  # Should return 'root'"
echo ""
echo "  4. Update package lists first:"
echo "     sudo apt update"
echo ""

# Error-specific fixes
echo -e "${RED}For 'command not found' errors:${NC}"
echo "  • Install missing packages: sudo apt install <package-name>"
echo "  • Check PATH: echo \$PATH"
echo "  • Use full path to commands: /bin/bash instead of bash"
echo ""

echo -e "${GREEN}For 'syntax error' errors:${NC}"
echo "  • Re-clone the repository (files may be corrupted)"
echo "  • Make sure you're using bash: bash setup/setup-kalindows.sh"
echo "  • Check for Windows line endings: dos2unix setup/*.sh"
echo ""

echo -e "${YELLOW}For 'kwriteconfig5' not found:${NC}"
echo "  • This is normal on minimal KDE installations"
echo "  • The script now has a fallback that writes configs directly"
echo "  • Install plasma-workspace if you want full functionality"
echo ""

echo -e "${CYAN}For more help, please open an issue on GitHub:${NC}"
echo "  https://github.com/kalwindows/kalindows-pro/issues"
echo ""
