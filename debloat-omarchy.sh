#!/usr/bin/env bash
# debloat-omarchy.sh — audit and safely remove Omarchy bloat; optionally install Hermes Agent.
# Companion docs: debloat-omarchy.md
# Inspired by the read-only find-omarchy-bloat.sh detector.

set -euo pipefail

VERSION="1.0"
MODE="audit"          # audit | apply | all
ASSUME_YES=0
INSTALL_HERMES=0
REMOVE_TARGETS=()
PLAN=()
MANIFEST=""

# ---------------------------------------------------------------------------
# Guard list — NEVER auto-removed. These are the apps/tools people actually use
# or that are required for Omarchy / this agent setup to keep working.
# ---------------------------------------------------------------------------
GUARD_EXACT=(
    dolphin
    io.github.kolunmi.Bazaar
    hermes
    claude
    claude-lm
    claude-or
    claude-nous
    omarchy
)

is_guarded() {
    local name="$1"
    local g
    for g in "${GUARD_EXACT[@]}"; do
        [[ "$name" == "$g" ]] && return 0
    done
    # All omarchy-* core packages and any claude wrapper are protected.
    [[ "$name" == omarchy-* ]] && return 0
    [[ "$name" == claude-* ]] && return 0
    return 1
}

valid_name() {
    # Allow letters, digits, dot, dash, underscore, plus, @ — nothing else.
    [[ "$1" =~ ^[A-Za-z0-9._+@-]+$ ]]
}

# Look-alikes: names that resemble an official app but are something else.
# Reported for review only — never removed automatically.
LOOKALIKES=(
    "dolphin-emu|GameCube/Wii emulator (NOT the Dolphin file manager)"
    "libretro-dolphin|RetroArch core (NOT the Dolphin file manager)"
    "dolphin-emu.desktop|Launcher for the Dolphin emulator, not the file manager"
    "org.kde.dolphin.desktop|Official Dolphin file manager launcher — KEEP"
)

WEB_APPS=(
    "Basecamp.desktop" "ChatGPT.desktop" "Discord.desktop" "Figma.desktop"
    "GitHub.desktop" "HEY.desktop" "Google Contacts.desktop" "Google Maps.desktop"
    "Google Messages.desktop" "Google Photos.desktop" "WhatsApp.desktop"
    "X.desktop" "YouTube.desktop" "Zoom.desktop"
)

usage() {
    cat <<'EOF'
debloat-omarchy.sh — safe Omarchy debloating + Hermes installer

USAGE
  ./debloat-omarchy.sh [MODE] [OPTIONS]

MODES (default: --audit)
  --audit              Read-only report. Makes NO changes. Safe to run anytime.
  --apply              Remove conservative bloat: orphaned packages, old pacman
                       cache, old journals, unused Flatpak runtimes. Prompts first.
  --remove NAME [...]  Remove explicitly named package / Flatpak ID (prompts per
                       item). Guarded names are refused. Repeatable.
  --install-hermes     Install Hermes Agent via the official installer if missing.
  --all                Run --audit, then --apply, then --install-hermes.

OPTIONS
  --yes                Skip confirmation prompts (use with care; removals still
                       respect the guard list).
  -h, --help           Show this help.

EXAMPLES
  ./debloat-omarchy.sh                          # audit only
  ./debloat-omarchy.sh --audit
  ./debloat-omarchy.sh --remove dolphin-emu     # explicit, prompted removal
  ./debloat-omarchy.sh --apply --install-hermes
  ./debloat-omarchy.sh --all --yes

A timestamped manifest of every planned command is written to
~/.local/share/omabloat/debloat-<timestamp>.log before any change is made.
See debloat-omarchy.md for the full explanation.
EOF
}

log()  { printf '%s\n' "$*"; }
hr()   { printf '%s\n' "---------------------------------------------------------------"; }

confirm() {
    local prompt="$1"
    [[ $ASSUME_YES -eq 1 ]] && return 0
    local reply=""
    read -r -p "$prompt [y/N] " reply || return 1
    [[ "$reply" =~ ^[Yy]([Ee][Ss])?$ ]]
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --audit)          MODE="audit"; shift ;;
        --apply)          MODE="apply"; shift ;;
        --all)            MODE="all"; shift ;;
        --install-hermes) INSTALL_HERMES=1; shift ;;
        --yes)            ASSUME_YES=1; shift ;;
        --remove)
            shift
            while [[ $# -gt 0 && "$1" != --* ]]; do
                REMOVE_TARGETS+=("$1"); shift
            done
            ;;
        -h|--help)        usage; exit 0 ;;
        *) log "Unknown option: $1"; usage; exit 1 ;;
    esac
done

if [[ $MODE == "all" ]]; then
    APPLY=1
    INSTALL_HERMES=1
elif [[ $MODE == "apply" ]]; then
    APPLY=1
else
    APPLY=0
fi

# ---------------------------------------------------------------------------
# Audit (always read-only)
# ---------------------------------------------------------------------------
audit() {
    log "==============================================================="
    log " Omarchy debloat audit  (v$VERSION) — READ ONLY"
    log "==============================================================="
    log ""

    log "1) Installed apps by source"
    hr
    local pacman_count flatpak_count
    pacman_count=$(pacman -Q 2>/dev/null | wc -l || echo 0)
    flatpak_count=$(flatpak list --app --columns=application 2>/dev/null | wc -l || echo 0)
    log "pacman/AUR packages: $pacman_count"
    log "Flatpak apps:        $flatpak_count"
    log ""

    log "2) Look-alikes / misleading names (REVIEW — never auto-removed)"
    hr
    local entry name desc found=0
    for entry in "${LOOKALIKES[@]}"; do
        name="${entry%%|*}"; desc="${entry#*|}"
        if pacman -Q "$name" >/dev/null 2>&1 \
           || compgen -G "/usr/share/applications/$name" >/dev/null 2>&1 \
           || [[ -f "$HOME/.local/share/applications/$name" ]]; then
            log "[LOOKALIKE] $name — $desc"
            found=1
        fi
    done
    [[ $found -eq 0 ]] && log "None detected."
    log ""

    log "3) Same app installed via more than one source"
    hr
    found=0
    local id short
    while IFS= read -r id; do
        [[ -z "$id" ]] && continue
        short="${id##*.}"
        short="${short,,}"
        [[ ${#short} -lt 3 ]] && continue
        if pacman -Q "$short" >/dev/null 2>&1; then
            log "[DUPLICATE?] $short — pacman package + Flatpak $id"
            found=1
        fi
    done < <(flatpak list --app --columns=application 2>/dev/null || true)
    [[ $found -eq 0 ]] && log "No obvious cross-source duplicates."
    log ""

    log "4) Web-app launchers (Chromium wrappers)"
    hr
    found=0
    local desktop
    for desktop in "${WEB_APPS[@]}"; do
        if [[ -f "$HOME/.local/share/applications/$desktop" ]]; then
            log "[WEBAPP] $HOME/.local/share/applications/$desktop"
            found=1
        fi
    done
    [[ $found -eq 0 ]] && log "No web-app launchers found."
    log ""

    log "5) Orphaned packages (safe cleanup candidates)"
    hr
    local orphans
    orphans=$(pacman -Qdtq 2>/dev/null || true)
    if [[ -n "$orphans" ]]; then
        printf '%s\n' "$orphans" | while IFS= read -r pkg; do
            log "[ORPHAN] $pkg"
        done
    else
        log "No orphaned packages."
    fi
    log ""

    log "6) Reclaimable disk space"
    hr
    du -sh "$HOME/.cache" "$HOME/.local/share/Trash" /var/cache/pacman/pkg \
        /var/lib/flatpak 2>/dev/null || true
    if command -v journalctl >/dev/null 2>&1; then
        journalctl --disk-usage 2>/dev/null || true
    fi
    log ""

    log "7) Hermes Agent"
    hr
    if command -v hermes >/dev/null 2>&1; then
        log "[OK] Hermes installed at $(command -v hermes)"
        hermes --version 2>/dev/null | head -1 || true
    else
        log "[MISSING] Hermes — run with --install-hermes to add it"
    fi
    log ""
    log "Audit complete. No changes were made."
}

# ---------------------------------------------------------------------------
# Manifest + plan execution
# ---------------------------------------------------------------------------
write_manifest() {
    if [[ ${#PLAN[@]} -eq 0 ]]; then
        log "Nothing to do — no manifest written."
        return 0
    fi
    local dir="$HOME/.local/share/omabloat"
    mkdir -p "$dir"
    MANIFEST="$dir/debloat-$(date +%Y%m%d-%H%M%S).log"
    {
        log "# debloat-omarchy manifest"
        log "date: $(date -Is)"
        log "host: $(hostname)"
        log "mode: $MODE"
        log ""
        log "Planned commands (one per line):"
        printf '  %s\n' "${PLAN[@]}"
    } > "$MANIFEST"
    log "Manifest written to: $MANIFEST"
}

run_plan() {
    [[ ${#PLAN[@]} -eq 0 ]] && return 0
    log ""
    log "Planned actions:"
    printf '  - %s\n' "${PLAN[@]}"
    write_manifest
    if ! confirm "Execute ${#PLAN[@]} planned action(s)?"; then
        log "Aborted — nothing was changed."
        return 0
    fi
    local cmd
    for cmd in "${PLAN[@]}"; do
        log "→ $cmd"
        if ! bash -c "$cmd"; then
            log "WARNING: command failed: $cmd"
        fi
    done
    log "Done. Review the manifest above if you need to undo anything."
}

plan_apply() {
    local orphans
    orphans=$(pacman -Qdtq 2>/dev/null || true)
    if [[ -n "$orphans" ]]; then
        local pkg
        while IFS= read -r pkg; do
            is_guarded "$pkg" && continue
            if [[ $ASSUME_YES -eq 1 ]]; then
                PLAN+=("sudo pacman -Rns --noconfirm $(printf '%q' "$pkg")")
            else
                PLAN+=("sudo pacman -Rns $(printf '%q' "$pkg")")
            fi
        done <<< "$orphans"
    fi

    if command -v paccache >/dev/null 2>&1; then
        PLAN+=("sudo paccache -rk2")
    else
        log "paccache not found — skipping old-package-cache cleanup."
    fi

    if command -v journalctl >/dev/null 2>&1; then
        PLAN+=("sudo journalctl --vacuum-time=30d")
    fi

    if command -v flatpak >/dev/null 2>&1; then
        PLAN+=("flatpak uninstall --unused --noninteractive")
    fi
}

plan_removals() {
    local target
    for target in "${REMOVE_TARGETS[@]}"; do
        if ! valid_name "$target"; then
            log "REFUSED (invalid characters): $target"
            continue
        fi
        if is_guarded "$target"; then
            log "REFUSED (protected app/tool): $target"
            continue
        fi
        if [[ "$target" == *.* ]]; then
            PLAN+=("flatpak uninstall --noninteractive $(printf '%q' "$target")")
        else
            if [[ $ASSUME_YES -eq 1 ]]; then
                PLAN+=("sudo pacman -Rns --noconfirm $(printf '%q' "$target")")
            else
                PLAN+=("sudo pacman -Rns $(printf '%q' "$target")")
            fi
        fi
    done
}

install_hermes() {
    log ""
    log "Hermes Agent"
    hr
    if command -v hermes >/dev/null 2>&1; then
        log "Hermes already installed: $(command -v hermes)"
        hermes --version 2>/dev/null | head -1 || true
        return 0
    fi
    if ! confirm "Install Hermes Agent from https://hermes-agent.nousresearch.com/install.sh ?"; then
        log "Skipped. Run 'curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash' yourself later."
        return 0
    fi
    log "Running official installer..."
    # shellcheck disable=SC2312
    curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
    hash -r
    if command -v hermes >/dev/null 2>&1; then
        log "Hermes installed: $(command -v hermes)"
        hermes --version 2>/dev/null | head -1 || true
        log "Next: hermes setup"
    else
        log "Installer finished but 'hermes' is not on PATH yet — open a new shell."
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
audit

if [[ $APPLY -eq 1 ]]; then
    plan_apply
fi
if [[ ${#REMOVE_TARGETS[@]} -gt 0 ]]; then
    plan_removals
fi
run_plan

if [[ $INSTALL_HERMES -eq 1 ]]; then
    install_hermes
fi
