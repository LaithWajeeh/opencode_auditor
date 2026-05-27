#!/usr/bin/env bash
# Audit Vault — single-command install from github.com/CascadeSTEAM/opencode_auditor
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/CascadeSTEAM/opencode_auditor/v0.7.7/bootstrap.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/CascadeSTEAM/opencode_auditor/v0.7.7/bootstrap.sh | bash -s -- --dry-run
#   INSTALL_DIR=/custom/path bash <(curl -fsSL ...)
#   (Replace v0.7.7 with the latest tag; use main for development)

set -euo pipefail

REPO="CascadeSTEAM/opencode_auditor"
BRANCH="main"
INSTALL_DIR="${INSTALL_DIR:-$HOME/Projects/audit}"
GITHUB_RAW="https://raw.githubusercontent.com/$REPO/$BRANCH"

# --- Flags ---
DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --help) echo "Usage: curl -fsSL $GITHUB_RAW/bootstrap.sh | bash"; exit 0 ;;
  esac
done

# --- Colors ---
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}✓${NC} $1"; }
warn()  { echo -e "${YELLOW}⚠${NC} $1"; }
fail()  { echo -e "${RED}✗${NC} $1"; }

# --- Prerequisite check ---
echo "=== Audit Vault — Preflight ==="
echo ""

MISSING_DEPS=false
for dep in git jq; do
  if command -v "$dep" &>/dev/null; then
    info "$dep found"
  else
    fail "$dep is required"
    MISSING_DEPS=true
  fi
done

if $MISSING_DEPS; then
  echo ""
  echo "Install missing dependencies:"
  echo "  Ubuntu/Debian: sudo apt install git jq"
  echo "  Fedora:        sudo dnf install git jq"
  echo "  Arch:          sudo pacman -S git jq"
  echo "  macOS:         brew install git jq"
  exit 1
fi

if ! command -v opencode &>/dev/null; then
  echo ""
  warn "OpenCode not found — needed to run audits."
  echo "  Install: curl -fsSL https://opencode.ai/install | bash"
  echo "  Or:      npm i -g opencode-ai@latest"
  echo "  Or:      brew install anomalyco/tap/opencode"
  echo ""

  if [[ "${YES:-}" != "1" ]] && [[ "$DRY_RUN" != true ]]; then
    read -rp "Install OpenCode now? [Y/n] " REPLY
    if [[ -z "$REPLY" || "$REPLY" =~ ^[Yy] ]]; then
      curl -fsSL https://opencode.ai/install | bash
      info "OpenCode installed"
    else
      warn "Skipping OpenCode install. You'll need it later."
    fi
  fi
  echo ""
fi

# --- Clone or pull ---
echo "=== Audit Vault — Install ==="
echo ""

if [[ -d "$INSTALL_DIR" ]]; then
  if [[ -d "$INSTALL_DIR/.git" ]]; then
    info "Vault exists at $INSTALL_DIR — pulling latest"
    if $DRY_RUN; then
      echo "  Would run: git -C $INSTALL_DIR pull origin $BRANCH"
    else
      git -C "$INSTALL_DIR" pull origin "$BRANCH"
    fi
  else
    fail "$INSTALL_DIR exists but is not a git repo."
    echo "  Remove it or set INSTALL_DIR to a different path, then re-run."
    exit 1
  fi
else
  info "Cloning vault to $INSTALL_DIR"
  if $DRY_RUN; then
    echo "  Would run: git clone --branch $BRANCH https://github.com/$REPO.git $INSTALL_DIR"
  else
    git clone --branch "$BRANCH" "https://github.com/$REPO.git" "$INSTALL_DIR"
  fi
fi

# --- Run vault installer ---
echo ""
if $DRY_RUN; then
  echo "  Would run: bash $INSTALL_DIR/setup/install.sh"
else
  echo "Running vault installer..."
  bash "$INSTALL_DIR/setup/install.sh"
fi

# --- Done ---
echo ""
echo "========================================"
echo "  Audit Vault scaffold complete!"
echo "========================================"
echo ""
echo "  Installer will now finish setup via Opencode."
echo "  Follow the prompts to install security tools and configure Obsidian."
echo ""
