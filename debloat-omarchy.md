# debloat-omarchy.sh — what it does and how to use it

`debloat-omarchy.sh` is the safe, reversible companion to the older read-only
`find-omarchy-bloat.sh` detector. It reports what is bloating an Omarchy install,
removes only clearly safe leftovers when you ask it to, and can install
[Hermes Agent](https://hermes-agent.nousresearch.com/docs/) if it is missing.

**Golden rule: running the script with no arguments changes nothing.**

---

## Quick start

```bash
chmod +x debloat-omarchy.sh

./debloat-omarchy.sh                       # audit only — read-only report
./debloat-omarchy.sh --audit               # same thing, explicit
./debloat-omarchy.sh --apply               # clean orphans, old cache, journals
./debloat-omarchy.sh --remove dolphin-emu  # remove one explicitly named package
./debloat-omarchy.sh --install-hermes      # add Hermes Agent if not installed
./debloat-omarchy.sh --all                 # audit + apply + install Hermes
```

Add `--yes` to skip the interactive prompts, e.g.
`./debloat-omarchy.sh --apply --install-hermes --yes`. Use it only when you know
exactly what will be removed.

Run `./debloat-omarchy.sh --help` for the built-in usage text.

---

## Modes in detail

| Mode | Changes anything? | What it does |
|---|---|---|
| `--audit` (default) | **No** | Prints a 7-section report: installed apps by source, look-alike names, cross-source duplicates, web-app launchers, orphaned packages, reclaimable disk space, and Hermes status. |
| `--apply` | Yes, after prompts | Removes orphaned packages, trims pacman cache to the 2 newest versions with `paccache -rk2`, vacuums journals older than 30 days, and uninstalls unused Flatpak runtimes. |
| `--remove NAME...` | Yes, after prompts | Removes each named pacman package (`sudo pacman -Rns`) or Flatpak ID (`flatpak uninstall`). Guarded names are refused. Names are validated to contain only safe characters. |
| `--install-hermes` | Yes, after prompt | If `hermes` is not on `PATH`, runs the official installer: `curl -fsSL https://hermes-agent.nousresearch.com/install.sh \| bash`, then verifies with `hermes --version`. Idempotent: does nothing when already installed. |
| `--all` | Yes, after prompts | Runs audit, then apply, then the Hermes install check. |

---

## What the audit looks for

1. **Installed apps by source** — counts pacman/AUR packages and Flatpak apps so
   you can see when both package systems are in play.
2. **Look-alikes** — names that resemble an official app but are something else.
   On this machine `dolphin-emu` (a GameCube/Wii emulator) and `libretro-dolphin`
   (a RetroArch core) show up here: neither is the Dolphin file manager. The
   official `org.kde.dolphin.desktop` launcher is labelled **KEEP**.
3. **Cross-source duplicates** — when a Flatpak ID's short name also exists as a
   pacman package (e.g. `org.gimp.GIMP` → `gimp`), it is flagged for review.
4. **Web-app launchers** — Chromium-based `.desktop` wrappers in
   `~/.local/share/applications` (Discord, YouTube, Figma, etc.).
5. **Orphaned packages** — `pacman -Qdtq` output; these are no longer required
   by anything and are the only packages `--apply` touches.
6. **Reclaimable space** — sizes of `~/.cache`, Trash, pacman cache, Flatpak
   storage, plus `journalctl --disk-usage`.
7. **Hermes status** — installed path and version, or a note that it is missing.

Everything in sections 1–4 is **informational**. The script never deletes a
look-alike, duplicate, or web-app launcher automatically — those are judgement
calls, so you decide with `--remove` or by hand.

---

## Safety rules

**Never auto-removed (hard guard list):**

- `dolphin` — the official KDE file manager
- `io.github.kolunmi.Bazaar` — the Bazaar app store
- `hermes` and all `claude-*` wrappers (`claude`, `claude-lm`, `claude-or`,
  `claude-nous`) — breaking these would break your working agent setups
- `omarchy` and every `omarchy-*` core package

`--remove` also refuses these names and anything containing shell-unfriendly
characters.

**Other safety behaviour:**

- The default is a read-only audit; removals require an explicit mode.
- Each destructive batch asks for confirmation unless `--yes` is given.
- Before *any* removal, a timestamped manifest of the exact planned commands is
  written to `~/.local/share/omabloat/debloat-YYYYMMDD-HHMMSS.log`.
- Removal commands use `sudo pacman -Rns` / `flatpak uninstall --noninteractive`
  so dependencies and Flatpak state are handled properly.
- A failed command is reported as a warning and the remaining plan continues, so
  one bad package does not silently abort the rest of the cleanup.

---

## Reviewing and undoing

```bash
cat ~/.local/share/omabloat/debloat-*.log | tail -40     # latest plan
```

The manifest records what was planned. To reverse a package removal, reinstall
from the repo/AUR, e.g.:

```bash
sudo pacman -S dolphin-emu
flatpak install flathub io.github.kolunmi.Bazaar
```

Cache and journal cleanup is not reversible, but only removes old downloads and
old log entries — no application data.

---

## Typical workflow for this project

1. `./debloat-omarchy.sh --audit` and read the look-alike / duplicate sections.
2. Decide which named apps are genuinely unwanted; remove them one at a time:
   `./debloat-omarchy.sh --remove NAME`.
3. `./debloat-omarchy.sh --apply` to clean orphans, old cache and journals.
4. `./debloat-omarchy.sh --install-hermes` so the lean system still has a capable
   agent available.
5. Re-run `--audit` to confirm the system is smaller and the apps you actually
   use (Dolphin file manager, Bazaar store, Hermes, Claude wrappers) are intact.

The goal is an Omarchy that is bloat-free but still has the apps people actually
use — not a stripped-down box that breaks the workflows built on it.
