#!/usr/bin/env bash
# find-omarchy-bloat.sh - Detect preinstalled Omarchy bloatware candidates
# Usage: ./find-omarchy-bloat.sh [--verbose] [--space-only]

set -euo pipefail

VERBOSE=0
SPACE_ONLY=0
DU_DEPTH=1

while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose) VERBOSE=1; shift ;;
        --space-only) SPACE_ONLY=1; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

if [[ $VERBOSE -eq 1 ]]; then DU_DEPTH=2; fi

# Omarchy-specific preinstall packages (from base.packages + common additions)
OMARCHY_BLOAT=(
    # Office suite - heavy, rarely used by devs
    libreoffice-fresh
    
    # Media/graphics - bloated desktop apps
    kdenlive obs-studio pinta xournalpp evince document-viewer
    
    # Communication web-apps (Chromium-based)
    chromium cliamp
    
    # Omarchy-specific utilities most users don't need
    omacalc omacut omawrite omasnap aether ttf-ia-writer ttf-jetbrains-mono-nerd-basic
    
    # Optional services
    docker docker-buildx docker-compose lazydocker moonlight-qt
)

# Web app .desktop files typically found in user dirs
WEB_APPS=(
    "Basecamp.desktop" "ChatGPT.desktop" "Discord.desktop"
    "Figma.desktop" "GitHub.desktop" "HEY.desktop"
    "Google Contacts.desktop" "Google Maps.desktop" "Google Messages.desktop"
    "Google Photos.desktop" "WhatsApp.desktop" "X.desktop" "YouTube.desktop"
    "Zoom.desktop"
)

echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Omarchy Bloatware Detection Report                      ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# 1. Check installed packages against bloat list
echo "📦 Checking for preinstalled bloatware packages..."
echo "─────────────────────────────────────────────────────────────"

BLOAT_FOUND=0
for pkg in "${OMARCHY_BLOAT[@]}"; do
    if pacman -Q "$pkg" >/dev/null 2>&1; then
        echo "[FOUND] $pkg"
        BLOAT_FOUND=1
    fi
done

if [[ $BLOAT_FOUND -eq 0 ]]; then
    echo "No known bloatware packages detected."
else
    echo ""
fi

# 2. Check for web app .desktop files (indicates installed web apps)
echo "🌐 Checking for web app launchers..."
echo "─────────────────────────────────────────────────────────────"

WEB_FOUND=0
for desktop in "${WEB_APPS[@]}"; do
    if [[ -f "$HOME/.local/share/applications/$desktop" ]]; then
        echo "[FOUND] $desktop → opens Chromium-based web app"
        WEB_FOUND=1
    fi
done

if [[ $WEB_FOUND -eq 0 ]]; then
    echo "No web app launchers detected."
else
    echo ""
fi

# 3. Disk usage by top directories (spot common bloat)
echo "💾 Top disk consumers in home directory:"
echo "─────────────────────────────────────────────────────────────"

if command -v du &>/dev/null; then
    # Limit output to avoid overwhelming, focus on large dirs
    timeout 20 du -h --max-depth="$DU_DEPTH" "$HOME" 2>/dev/null | sort -rh | sed -n '1,10p' || echo "Home scan skipped (too large or timed out)."
fi
echo ""

# 4. Check for orphaned packages (installed but no files)
echo "🗑️  Orphaned/unneeded packages:"
echo "─────────────────────────────────────────────────────────────"

if command -v pacman &>/dev/null; then
    ORPHANS=$(pacman -Qdtq 2>/dev/null || echo "")
    if [[ -n "$ORPHANS" ]]; then
        echo "$ORPHANS" | while read -r pkg; do
            # Filter out known useful orphans (cache, etc.)
            case "$pkg" in
                cache|gpg-keys-*|pacman-db) continue ;;
            esac
            echo "[ORPHAN] $pkg"
        done
    else
        echo "No orphaned packages found."
    fi
fi
echo ""

# 5. Check for unused desktop environments / GUI tools
echo "🖥️  Unused GUI utilities (if you prefer terminal):"
echo "─────────────────────────────────────────────────────────────"

GUI_UTILS=(nautilus disktree-bin gnome-disk-utility)
for util in "${GUI_UTILS[@]}"; do
    if command -v "$util" &>/dev/null; then
        echo "[INSTALLED] $util (graphical utility)"
    fi
done
echo ""

# 6. Space usage by specific bloatware candidates
if [[ $SPACE_ONLY -eq 1 ]]; then
    echo "📊 Space used by potential bloatware:"
    echo "─────────────────────────────────────────────────────────────"
    
    for pkg in "${OMARCHY_BLOAT[@]}"; do
        if pacman -Q "$pkg" >/dev/null 2>&1; then
            # Get package size from pacman database
            PKG_SIZE=$(pacman -Qi "$pkg" 2>/dev/null | grep "Installed Size" | awk '{print $4, $5}' || echo "?")
            if [[ "$PKG_SIZE" != "?" && "$PKG_SIZE" != "" ]]; then
                echo "$pkg: $PKG_SIZE"
            fi
        fi
    done
    
    # Check web apps in Chromium profile
    CHROMIUM_PROFILE="$HOME/.config/chromium/Default"
    if [[ -d "$CHROMIUM_PROFILE" ]]; then
        PROFILE_SIZE=$(du -sh "$CHROMIUM_PROFILE" 2>/dev/null | cut -f1 || echo "?")
        echo "Chromium profile: $PROFILE_SIZE"
    fi
    
    # Check .local/share for web app data
    WEB_DATA_DIR="$HOME/.local/share"
    if [[ -d "$WEB_DATA_DIR" ]]; then
        du -h --max-depth=1 "$WEB_DATA_DIR" 2>/dev/null | sort -rh | sed -n '1,5p' || true
    fi
    
    echo ""
fi

# Summary recommendations
echo "═══════════════════════════════════════════════════════════"
echo "📋 Recommendations:"
echo "─────────────────────────────────────────────────────────────"

if [[ $BLOAT_FOUND -gt 0 ]]; then
    echo "- Remove unwanted packages via Omarchy menu → Remove → Package"
    echo "- Or run: sudo pacman -Rns <package-name>"
fi

if [[ $WEB_FOUND -gt 0 ]]; then
    echo "- Delete web app .desktop files to remove Chromium launchers:"
    for desktop in "${WEB_APPS[@]}"; do
        if [[ -f "$HOME/.local/share/applications/$desktop" ]]; then
            echo "  rm \"$HOME/.local/share/applications/$desktop\""
        fi
    done
fi

if command -v pacman &>/dev/null; then
    ORPHANS=$(pacman -Qdtq 2>/dev/null || true)
    if [[ -n "$ORPHANS" ]]; then
        echo "- Clean orphaned packages: sudo pacman -Rns $(echo $ORPHANS | tr '\n' ' ')"
    fi
fi

if command -v docker &>/dev/null; then
    DOCKER_SIZE=$(docker system df 2>/dev/null | tail -1 | awk '{print $3}' || echo "?")
    if [[ "$DOCKER_SIZE" != "?" && "$DOCKER_SIZE" =~ ^[0-9] ]]; then
        echo "- Docker storage: $DOCKER_SIZE (run 'docker system prune' to clean)"
    fi
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
