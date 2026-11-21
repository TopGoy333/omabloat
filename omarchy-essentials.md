# omarchy-essentials.sh — the "how was I supposed to know about that?" installer

New Omarchy users get a great base, but a lot of genuinely useful software is
hidden behind `omarchy install ...` subcommands that never show up in the menu.
This script puts those commands in one place, adds a few things Omarchy doesn't
ship (most notably the **Bazaar** app store), and installs them with the official
installers so themes, fonts, drivers and default-app wiring stay intact.

**It changes nothing by default.** Running `./omarchy-essentials.sh` with no
arguments only prints the catalog.

---

## Why this exists

`omarchy install --help` reveals installers for:

- **AI agents** — Hermes CLI and Hermes desktop app
- **Browsers** — Brave Origin, Chrome, Firefox, Zen, Edge
- **Gaming** — Steam, RetroArch with the full libretro core set, Xbox controllers
- **Services** — Tailscale, Signal, Spotify, 1Password, Dropbox
- **Plugins** — yt-dlp and Claude extensions for Chromium-based browsers
- **System** — approved terminals (Kitty, Ghostty, Alacritty, Foot), dev environments

Most new users never run `omarchy install --help`, so they never see any of it.
Bazaar isn't even in that list — it is a Flatpak app store
(`io.github.kolunmi.Bazaar`) that gives new users a graphical way to discover
and manage software. This script surfaces all of it in one catalog.

---

## Usage

```bash
chmod +x omarchy-essentials.sh

./omarchy-essentials.sh                              # list everything (READ ONLY)
./omarchy-essentials.sh --list                       # same, explicit

./omarchy-essentials.sh --install bazaar             # add the Bazaar app store
./omarchy-essentials.sh --install hermes-cli ytdlp   # add several at once
./omarchy-essentials.sh --group gaming               # Steam + RetroArch + controllers
./omarchy-essentials.sh --all                        # everything that is missing

./omarchy-essentials.sh --group gaming --dry-run     # show commands, install nothing
./omarchy-essentials.sh --all --yes                  # unattended install
```

`--install` and `--group` prompt before each item; `--yes` skips the prompts.
`--dry-run` prints every command it *would* run and executes none of them.

If the `omarchy` command is not present, Omarchy-specific items are skipped with
an explanation; plain Flatpak/pacman items still work.

---

## Catalog

| ID | Category | What it adds |
|---|---|---|
| `bazaar` | store | Bazaar app store via Flatpak — the discoverability piece new users are missing |
| `hermes-cli` | agents | Hermes Agent CLI via `omarchy install hermes cli --now` |
| `hermes-desktop` | agents | Hermes desktop app via `omarchy install ai hermes` |
| `brave-origin` | browsers | Brave Origin browser with Omarchy defaults |
| `steam` | gaming | Steam plus the graphics drivers this system needs |
| `retroarch` | gaming | RetroArch with the full libretro core set and a `~/Games` ROM directory |
| `xbox-controllers` | gaming | Xbox controller support for Steam/RetroArch |
| `tailscale` | services | Tailscale mesh VPN and its web console |
| `signal` | services | Signal Desktop |
| `spotify` | services | Spotify (web player where no Linux client exists) |
| `onepassword` | services | 1Password and its Chromium extension |
| `kitty` | system | Kitty terminal, wired as the Omarchy default |
| `ytdlp` | plugins | yt-dlp native messaging host + Chromium extension |
| `claude-extension` | plugins | Claude extension for Chromium-based browsers |
| `gpg` | system | GnuPG for signing and encryption |
| `ark` | system | Ark archive manager |
| `libreoffice` | system | LibreOffice suite as a Flatpak |
| `dev-python` | dev | Python development environment via `omarchy install dev-env python` |

Categories: `store`, `agents`, `browsers`, `gaming`, `services`, `plugins`,
`system`, `dev`.

---

## Safety

- Default mode is `--list`, which only runs read-only checks (`command -v`,
  `flatpak list`, `pacman -Q`-style lookups).
- Already-installed items are skipped, so re-running is safe and idempotent.
- Every item prompts unless `--yes` is passed.
- Install commands are fixed entries in the catalog; item IDs are validated
  against that catalog, so user input never becomes a shell command.
- Omarchy's own installers are preferred over raw package-manager calls because
  they also configure themes, fonts, drivers and default applications.
- This script installs; it does **not** remove anything. For cleanup, use the
  companion `debloat-omarchy.sh` (audit-only by default, with a command manifest
  before any removal).

---

## Recommended order for a new machine

1. `./omarchy-essentials.sh --list` — see what is already there.
2. `./omarchy-essentials.sh --install bazaar` — get a graphical app store first.
3. `./omarchy-essentials.sh --install hermes-cli hermes-desktop` — add an agent.
4. `./omarchy-essentials.sh --install brave-origin kitty ytdlp` — daily drivers.
5. Add `gaming`, `services` or `dev` groups only if you need them — that is the
   point of a lean Omarchy: bloat-free, but with the apps people actually use.

Re-run `--list` at any time to confirm the state of the machine.
