#!/usr/bin/env bash
# omarchy-essentials.sh — installer for the apps, plugins and services new
# Omarchy users don't know they can get (including the Bazaar app store).
#
# SAFETY: with no arguments this only LISTS the catalog. Nothing is installed
# unless you explicitly pass --install / --group / --all (and even then it
# prompts, unless --yes is given).
#
# Companion docs: omarchy-essentials.md

set -euo pipefail

VERSION="1.0"
MODE="list"
DRY_RUN=0
ASSUME_YES=0
TARGETS=()

CATEGORIES=(store agents browsers gaming services plugins system dev)

usage() {
    cat <<'EOF'
omarchy-essentials.sh — install the good stuff Omarchy doesn't advertise

USAGE
  ./omarchy-essentials.sh [MODE] [OPTIONS]

MODES (default: --list; never installs anything by itself)
  --list              Print the catalog with installed/missing status. READ ONLY.
  --install ID [...]  Install named items, e.g. bazaar hermes-cli brave-origin.
  --group CATEGORY    Install every item in a category (store, agents, gaming…).
  --all               Install every missing item in the catalog.
  -h, --help          Show this help.

OPTIONS
  --dry-run           Print the install commands without executing them.
  --yes               Skip per-item confirmation prompts.

EXAMPLES
  ./omarchy-essentials.sh                          # just look
  ./omarchy-essentials.sh --list
  ./omarchy-essentials.sh --install bazaar
  ./omarchy-essentials.sh --install hermes-cli brave-origin ytdlp
  ./omarchy-essentials.sh --group gaming --dry-run
  ./omarchy-essentials.sh --all --yes

Item IDs are listed by --list and documented in omarchy-essentials.md.
EOF
}

log() { printf '%s\n' "$*"; }
hr()  { printf '%s\n' "---------------------------------------------------------------"; }

confirm() {
    local prompt="$1"
    [[ $ASSUME_YES -eq 1 ]] && return 0
    local reply=""
    read -r -p "$prompt [y/N] " reply || return 1
    [[ "$reply" =~ ^[Yy]([Ee][Ss])?$ ]]
}

# Catalog: id <TAB> category <TAB> label <TAB> check-command <TAB> install-command
# Commands use Omarchy's own installers where they exist — they handle themes,
# fonts, drivers and default-app wiring that a raw pacman/flatpak call would miss.
catalog() {
    case "$1" in
        bazaar)
            printf 'store\tBazaar app store (Flatpak)\tflatpak list --app --columns=application 2>/dev/null | grep -qx "io.github.kolunmi.Bazaar"\tflatpak install -y flathub io.github.kolunmi.Bazaar' ;;
        hermes-cli)
            printf 'agents\tHermes Agent CLI (installed by Omarchy)\tcommand -v hermes\t omarchy install hermes cli --now' ;;
        hermes-desktop)
            printf 'agents\tHermes desktop app\tflatpak list --app --columns=application 2>/dev/null | grep -qi "hermes"\tomarchy install ai hermes' ;;
        brave-origin)
            printf 'browsers\tBrave Origin browser\tcommand -v brave-origin-browser || command -v brave-browser\tomarchy install browser brave-origin' ;;
        steam)
            printf 'gaming\tSteam + graphics drivers\tcommand -v steam\tomarchy install gaming steam' ;;
        retroarch)
            printf 'gaming\tRetroArch with full libretro core set\tcommand -v retroarch\tomarchy install gaming retroarch' ;;
        xbox-controllers)
            printf 'gaming\tXbox controller support\tfalse\tomarchy install gaming xbox-controllers' ;;
        tailscale)
            printf 'services\tTailscale mesh VPN + web console\tcommand -v tailscale\tomarchy install service tailscale' ;;
        signal)
            printf 'services\tSignal desktop\tcommand -v signal-desktop\tomarchy install service signal' ;;
        spotify)
            printf 'services\tSpotify (web player where needed)\tcommand -v spotify || [[ -f "$HOME/.local/share/applications/Spotify.desktop" ]]\tomarchy install service spotify' ;;
        onepassword)
            printf 'services\t1Password + browser extension\tcommand -v 1password\tomarchy install service 1password' ;;
        kitty)
            printf 'system\tKitty terminal, wired as Omarchy default\tcommand -v kitty\tomarchy install terminal kitty' ;;
        ytdlp)
            printf 'plugins\tChromium yt-dlp extension + native host\tfalse\tomarchy install chromium ytdlp' ;;
        claude-extension)
            printf 'plugins\tClaude extension for Chromium browsers\tfalse\tomarchy install chromium claude' ;;
        gpg)
            printf 'system\tGnuPG (signing and encryption)\tcommand -v gpg\tsudo pacman -S --noconfirm gnupg' ;;
        ark)
            printf 'system\tArk archive manager\tcommand -v ark\tsudo pacman -S --noconfirm ark' ;;
        libreoffice)
            printf 'system\tLibreOffice office suite (Flatpak)\tflatpak list --app --columns=application 2>/dev/null | grep -qx "org.libreoffice.LibreOffice"\tflatpak install -y flathub org.libreoffice.LibreOffice' ;;
        dev-python)
            printf 'dev\tPython development environment\tcommand -v python3\tomarchy install dev-env python' ;;
        *) return 1 ;;
    esac
}

item_field() {
    local line
    line=$(catalog "$1") || return 1
    local category label check install
    IFS=$'\t' read -r category label check install <<< "$line"
    # Trim a single leading space from commands (readability in the catalog).
    check="${check# }"; install="${install# }"
    case "$2" in
        category) printf '%s' "$category" ;;
        label)    printf '%s' "$label" ;;
        check)    printf '%s' "$check" ;;
        install)  printf '%s' "$install" ;;
        *) return 1 ;;
    esac
}

is_known_item() { catalog "$1" >/dev/null 2>&1; }

item_installed() {
    local check
    check=$(item_field "$1" check)
    [[ -n "$check" ]] || return 1
    bash -c "$check" >/dev/null 2>&1
}

list_catalog() {
    log "==============================================================="
    log " Omarchy Essentials v$VERSION — catalog (READ ONLY)"
    log "==============================================================="
    log " Apps, plugins and services new Omarchy users often don't know exist."
    log ""
    local category id state
    for category in "${CATEGORIES[@]}"; do
        log "[$category]"
        hr
        for id in "${ITEMS[@]}"; do
            [[ "$(item_field "$id" category)" == "$category" ]] || continue
            if item_installed "$id"; then state="installed"; else state="not installed"; fi
            printf '  %-18s %-52s [%s]\n' "$id" "$(item_field "$id" label)" "$state"
        done
        log ""
    done
    log "Nothing was installed. Use --install ID or --group CATEGORY to add things."
}

install_one() {
    local id="$1"
    if ! is_known_item "$id"; then
        log "Unknown item: $id (run --list to see valid IDs)"
        return 1
    fi
    local cmd
    cmd=$(item_field "$id" install)

    if [[ "$cmd" == omarchy\ * ]] && ! command -v omarchy >/dev/null 2>&1; then
        log "SKIP $id — 'omarchy' not found (this is not an Omarchy system)"
        return 0
    fi
    if item_installed "$id"; then
        log "SKIP $id — already installed"
        return 0
    fi

    log "PLAN  $id — $(item_field "$id" label)"
    log "      $cmd"
    if [[ $DRY_RUN -eq 1 ]]; then
        return 0
    fi
    if ! confirm "Install $id?"; then
        log "SKIP $id — declined"
        return 0
    fi
    if bash -c "$cmd"; then
        log "OK    $id installed"
    else
        log "FAIL  $id — command returned an error"
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --list)    MODE="list"; shift ;;
        --dry-run) DRY_RUN=1; shift ;;
        --yes)     ASSUME_YES=1; shift ;;
        --install)
            MODE="install"; shift
            while [[ $# -gt 0 && "$1" != --* ]]; do TARGETS+=("$1"); shift; done
            ;;
        --group)
            MODE="group"; shift
            [[ $# -gt 0 && "$1" != --* ]] || { log "--group needs a category"; exit 1; }
            TARGETS+=("$1"); shift
            ;;
        --all)     MODE="all"; shift ;;
        -h|--help) usage; exit 0 ;;
        *) log "Unknown option: $1"; usage; exit 1 ;;
    esac
done

# The catalog IDs, defined once so --list and --install stay in sync.
ITEMS=(
    bazaar hermes-cli hermes-desktop brave-origin steam retroarch
    xbox-controllers tailscale signal spotify onepassword kitty ytdlp
    claude-extension gpg ark libreoffice dev-python
)

if [[ $MODE == "list" ]]; then
    list_catalog
    exit 0
fi

log "Omarchy Essentials — requested mode: $MODE"
[[ $DRY_RUN -eq 1 ]] && log "DRY RUN: no commands will be executed."

case "$MODE" in
    install)
        [[ ${#TARGETS[@]} -gt 0 ]] || { log "--install needs at least one item ID"; exit 1; }
        for id in "${TARGETS[@]}"; do install_one "$id" || true; done
        ;;
    group)
        category="${TARGETS[0]}"
        found=0
        for id in "${ITEMS[@]}"; do
            if [[ "$(item_field "$id" category)" == "$category" ]]; then
                found=1
                install_one "$id" || true
            fi
        done
        [[ $found -eq 0 ]] && { log "Unknown category: $category"; exit 1; }
        ;;
    all)
        for id in "${ITEMS[@]}"; do install_one "$id" || true; done
        ;;
esac

log ""
log "Done. Re-run --list to see what is now installed."
