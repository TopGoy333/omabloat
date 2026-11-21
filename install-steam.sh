#!/usr/bin/env bash
# install-steam.sh — guided Steam install for Omarchy + ProtonPlus orientation.
# Companion docs: steam-setup.md
# Part of the omabloat flow: run find-omarchy-bloat.sh first and last.

set -euo pipefail

VERSION="1.0"
MODE="install"
ASSUME_YES=0
WITH_PROTONPLUS=0
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

log() { printf '%s\n' "$*"; }
hr()  { printf '%s\n' "---------------------------------------------------------------"; }

usage() {
    cat <<'EOF'
install-steam.sh — guided Steam install for Omarchy (with ProtonPlus guidance)

USAGE
  ./install-steam.sh [OPTIONS]

OPTIONS
  (no options)       Guided install: check state, explain, ask, then install Steam
                     with Omarchy's supported installer. Already installed = no-op.
  --install          Explicit form of the default guided install.
  --check            Read-only report. Changes nothing.
  --with-protonplus  After Steam, offer to install ProtonPlus (never automatic).
  --yes              Skip confirmation prompts. Only use when you know what runs.
  -h, --help         Show this help.

WHAT IT DOES
  1. Checks Steam, Omarchy CLI, multilib availability and ProtonPlus status.
  2. If Steam is missing, runs: omarchy install gaming steam
     (Omarchy installs Steam and the graphics drivers picked for this machine).
  3. Explains ProtonPlus: what it is, when you actually need it, where to get
     it, and how to choose GE-Proton for a single game in Steam.
  4. Reminds you to run find-omarchy-bloat.sh first and last.

No curl|bash. Installs only via Omarchy's supported installer or Flatpak.
No changes in --check mode.
See steam-setup.md for the full beginner walkthrough.
EOF
}

confirm() {
    local prompt="$1" reply=""
    [[ $ASSUME_YES -eq 1 ]] && return 0
    read -r -p "$prompt [y/N] " reply || return 1
    [[ "$reply" =~ ^[Yy]([Ee][Ss])?$ ]]
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --check)            MODE="check"; shift ;;
        --install)          MODE="install"; shift ;;
        --with-protonplus)  WITH_PROTONPLUS=1; shift ;;
        --yes)              ASSUME_YES=1; shift ;;
        -h|--help)          usage; exit 0 ;;
        *) log "Unknown option: $1"; usage; exit 1 ;;
    esac
done

# ---------------------------------------------------------------------------
# State checks (all read-only)
# ---------------------------------------------------------------------------
omarchy_present()      { command -v omarchy >/dev/null 2>&1; }
steam_pkg_installed()  { pacman -Q steam >/dev/null 2>&1; }
steam_launcher()       { command -v steam >/dev/null 2>&1 || [[ -x /usr/bin/steam ]]; }
steam_ready()          { steam_pkg_installed || steam_launcher; }
steam_available()      { pacman -Si steam >/dev/null 2>&1; }

protonplus_flatpak() {
    command -v flatpak >/dev/null 2>&1 &&
        flatpak list --app --columns=application 2>/dev/null | grep -x 'com.vysp3r.ProtonPlus' >/dev/null
}
protonplus_aur()       { pacman -Q protonplus >/dev/null 2>&1; }
protonplus_ready()     { protonplus_flatpak || protonplus_aur; }

show_state() {
    log ""
    log "==============================================================="
    log " Steam / ProtonPlus state  (v$VERSION)"
    log "==============================================================="

    log ""
    log "1) Platform"
    hr
    if omarchy_present; then
        log "[OK] Omarchy CLI: $(command -v omarchy)"
    else
        log "[MISSING] omarchy CLI — this script is written for Omarchy"
    fi
    if steam_available; then
        log "[OK] Steam package is visible from your repos (multilib enabled)."
    else
        log "[WARN] Steam package is not visible — multilib may be disabled."
    fi

    log ""
    log "2) Steam"
    hr
    local steam_info
    steam_info=$(pacman -Q steam 2>/dev/null || true)
    if [[ -n "$steam_info" ]]; then
        log "[OK] pacman package: $steam_info"
    else
        log "[--] steam package is not installed"
    fi
    if steam_launcher; then
        log "[OK] launcher: $(command -v steam 2>/dev/null || printf '/usr/bin/steam')"
    else
        log "[--] steam launcher is not on PATH yet"
    fi

    log ""
    log "3) ProtonPlus (optional — only for tricky games)"
    hr
    if protonplus_flatpak; then
        log "[OK] ProtonPlus Flatpak: com.vysp3r.ProtonPlus"
    elif protonplus_aur; then
        log "[OK] ProtonPlus AUR package: protonplus"
    else
        log "[--] ProtonPlus not installed. Steam's built-in Proton is enough for most games."
    fi
}

# ---------------------------------------------------------------------------
# ProtonPlus explanation — printed on EVERY run, including --check.
# This is the part people need to read once before they go looking for tools.
# ---------------------------------------------------------------------------
protonplus_section() {
    log ""
    log "==============================================================="
    log " ProtonPlus — do you need it?"
    log "==============================================================="
    log "WHAT IT IS"
    log "  ProtonPlus is a small GUI manager for Windows-compatibility tools"
    log "  (GE-Proton, Wine-GE, DXVK, VKD3D) used by Steam and other launchers."
    log "  Think of it as a tool shelf, not a game launcher."
    log ""
    log "WHEN YOU NEED IT"
    log "  Most games run fine on the Proton that ships inside Steam. You only"
    log "  need ProtonPlus when a Windows game will not start, crashes, or needs"
    log "  a newer/custom Proton build than Steam offers. Do not install it just"
    log "  to have it — install it when a game asks for it."
    log ""
    log "HOW TO INSTALL IT (when you need it)"
    log "  Flatpak (easiest, works with Bazaar):"
    log "    flatpak install flathub com.vysp3r.ProtonPlus"
    log "  AUR (native build, needs an AUR helper):"
    log "    yay -S protonplus"
    log ""
    log "HOW TO USE IT WITH STEAM"
    log "  1. Launch Steam once, then open ProtonPlus and pick Steam as launcher."
    log "  2. Install a GE-Proton release. Tools land in:"
    log "       ~/.steam/steam/steamapps/common/"
    log "  3. Quit and restart Steam so it sees the new tool."
    log "  4. In Steam: right-click game -> Properties -> Compatibility ->"
    log "     tick 'Force the use of a specific Steam Play compatibility tool'"
    log "     and choose the GE-Proton version. Per-game is safer than global."
    log ""
    log "  ProtonUp-Qt is another manager for the same idea; GE-Proton is the"
    log "  tool itself. ProtonPlus simply downloads and organizes the tools."
}

companions() {
    log ""
    log "Optional gaming companions (Omarchy-supported, run only if wanted)"
    hr
    log "  omarchy install gaming gpu-lib32        # 32-bit graphics drivers"
    log "  omarchy install gaming xbox-controllers # controller support"
    log "  omarchy install gaming retroarch        # retro games + cores"
}

first_last_reminder() {
    local detector="$SCRIPT_DIR/find-omarchy-bloat.sh"
    log ""
    log "The first-and-last rule"
    hr
    if [[ -x "$detector" ]]; then
        log "  FIRST:  \"$detector\"   # baseline before installs"
        log "  LAST:   \"$detector\"   # compare after full setup"
    else
        log "  Run find-omarchy-bloat.sh from this repo FIRST and LAST."
    fi
    log "  Then:   \"$SCRIPT_DIR/debloat-omarchy.sh\" --audit   # read-only cleanup review"
    log "  See steam-setup.md for the whole flow."
}

# ---------------------------------------------------------------------------
# Actions
# ---------------------------------------------------------------------------
install_steam() {
    log ""
    log "Steam install"
    hr
    if steam_ready; then
        log "[OK] Steam is already installed — nothing to do."
        return 0
    fi
    if ! omarchy_present; then
        log "[ERROR] Omarchy CLI not found. On plain Arch you would enable [multilib]"
        log "        and run: sudo pacman -S steam  (this script stays Omarchy-first)."
        return 1
    fi

    log "Planned command: omarchy install gaming steam"
    log "This installs Steam and the graphics drivers selected for this machine."
    if ! confirm "Run the Omarchy Steam installer now?"; then
        log "Skipped. Re-run ./install-steam.sh when you are ready."
        return 0
    fi
    if omarchy install gaming steam; then
        hash -r
        log "[OK] Installer finished."
    else
        log "[WARN] The installer reported a failure — read its output above."
        return 1
    fi
    if steam_ready; then
        log "[OK] Steam is now installed and ready."
    else
        log "[WARN] Steam is not detected yet — open a new shell or log out/in."
    fi
}

install_protonplus() {
    [[ $WITH_PROTONPLUS -eq 1 ]] || return 0
    log ""
    log "ProtonPlus (requested with --with-protonplus)"
    hr
    if protonplus_ready; then
        log "[OK] ProtonPlus is already installed — nothing to do."
        return 0
    fi
    if ! command -v flatpak >/dev/null 2>&1; then
        log "[--] Flatpak is not available. Install it with your package manager,"
        log "     or use the AUR route later: yay -S protonplus"
        return 0
    fi
    if ! flatpak remote-list --columns=name 2>/dev/null | grep -x flathub >/dev/null; then
        log "[--] Flathub remote is not configured. Add it first:"
        log "     flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo"
        return 0
    fi
    log "Planned command: flatpak install -y flathub com.vysp3r.ProtonPlus"
    if confirm "Install ProtonPlus from Flathub now?"; then
        if flatpak install -y flathub com.vysp3r.ProtonPlus; then
            log "[OK] ProtonPlus installed. Launch Steam once before opening it."
        else
            log "[WARN] Flatpak install failed. AUR alternative: yay -S protonplus"
        fi
    else
        log "Skipped. Later: flatpak install flathub com.vysp3r.ProtonPlus"
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
show_state

if [[ $MODE == "check" ]]; then
    if [[ $WITH_PROTONPLUS -eq 1 ]]; then
        log "Note: --with-protonplus is ignored in --check mode."
    fi
    log ""
    log "Read-only check complete — no changes were made."
else
    install_steam || log "Steam install did not complete; see the messages above."
    install_protonplus
fi

protonplus_section
companions
first_last_reminder
