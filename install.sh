#!/bin/bash
# Viska Installer - https://viska.app
# Usage: curl -fsSL https://raw.githubusercontent.com/PenPlanner/viska-updates/main/install.sh | bash

set -e

# Colors
BOLD='\033[1m'
DIM='\033[2m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Config
REPO="PenPlanner/viska-updates"
APP_NAME="Viska-Ai"
INSTALL_DIR="/Applications"

# ─────────────────────────────────────────────────────────

banner() {
    echo ""
    echo -e "${CYAN}${BOLD}"
    echo "  ╦  ╦╦╔═╗╦╔═╔═╗"
    echo "  ╚╗╔╝║╚═╗╠╩╗╠═╣"
    echo "   ╚╝ ╩╚═╝╩ ╩╩ ╩"
    echo -e "${NC}"
    echo -e "  ${DIM}Voice-to-text, reimagined.${NC}"
    echo ""
}

info()    { echo -e "  ${BLUE}${BOLD}>${NC} $1"; }
success() { echo -e "  ${GREEN}${BOLD}>${NC} $1"; }
warn()    { echo -e "  ${YELLOW}${BOLD}>${NC} $1"; }
error()   { echo -e "  ${RED}${BOLD}>${NC} $1"; exit 1; }

# ─────────────────────────────────────────────────────────

check_requirements() {
    # macOS only
    if [[ "$(uname)" != "Darwin" ]]; then
        error "Viska requires macOS. Visit ${CYAN}https://viska.app${NC} for more info."
    fi

    # Apple Silicon only
    if [[ "$(uname -m)" != "arm64" ]]; then
        error "Viska requires Apple Silicon (M1 or later)."
    fi

    # macOS 14+
    local macos_version
    macos_version=$(sw_vers -productVersion | cut -d. -f1)
    if [[ "$macos_version" -lt 14 ]]; then
        error "Viska requires macOS 14 Sonoma or later. You have $(sw_vers -productVersion)."
    fi

    # curl required
    if ! command -v curl &>/dev/null; then
        error "curl is required but not found."
    fi
}

get_latest_version() {
    info "Checking for latest version..."

    # Get latest release tag from GitHub API
    LATEST_TAG=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
        | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"//;s/".*//')

    if [[ -z "$LATEST_TAG" ]]; then
        error "Could not determine latest version."
    fi

    VERSION="${LATEST_TAG#v}"
    DOWNLOAD_URL="https://github.com/$REPO/releases/download/$LATEST_TAG/Viska.zip"

    info "Latest version: ${BOLD}$VERSION${NC}"
}

download_and_install() {
    local tmp_dir
    tmp_dir=$(mktemp -d)
    local zip_path="$tmp_dir/Viska.zip"

    # Download
    info "Downloading Viska $VERSION..."
    if ! curl -fSL --progress-bar "$DOWNLOAD_URL" -o "$zip_path"; then
        rm -rf "$tmp_dir"
        error "Download failed. Check your internet connection."
    fi

    # Check if already installed
    if [[ -d "$INSTALL_DIR/$APP_NAME.app" ]]; then
        warn "Existing installation found. Updating..."
        # Move old version to trash instead of deleting
        mv "$INSTALL_DIR/$APP_NAME.app" "$HOME/.Trash/$APP_NAME.app.$(date +%s)" 2>/dev/null || true
    fi

    # Extract
    info "Installing to $INSTALL_DIR..."
    ditto -xk "$zip_path" "$INSTALL_DIR"

    # Cleanup
    rm -rf "$tmp_dir"

    # Remove quarantine (user downloaded via curl, not browser)
    xattr -cr "$INSTALL_DIR/$APP_NAME.app" 2>/dev/null || true
}

finish() {
    echo ""
    success "${GREEN}${BOLD}Viska $VERSION installed successfully!${NC}"
    echo ""
    echo -e "  ${DIM}Location:${NC}  $INSTALL_DIR/$APP_NAME.app"
    echo -e "  ${DIM}Launch:${NC}    open -a \"$APP_NAME\""
    echo -e "  ${DIM}Updates:${NC}   Automatic via Sparkle"
    echo ""

    # Ask to launch
    if [[ -t 0 ]]; then
        echo -ne "  ${CYAN}Launch Viska now? [Y/n]${NC} "
        read -r answer
        if [[ ! "$answer" =~ ^[Nn] ]]; then
            open -a "$APP_NAME"
        fi
    else
        info "Run ${BOLD}open -a \"$APP_NAME\"${NC} to launch."
    fi

    echo ""
}

# ─────────────────────────────────────────────────────────

main() {
    banner
    check_requirements
    get_latest_version
    download_and_install
    finish
}

main
