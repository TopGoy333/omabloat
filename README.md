# omabloat

A small, **read-only** helper for finding bloat on [Omarchy](https://omarchy.org/)
(and it should work on plain Arch too). The goal is to make Omarchy accessible
to the average PC user: see what is installed, decide what you actually use,
and keep the machine feeling normal — with things like the Bazaar app store
still available.

## See it working

![Example bloat report](assets/demo.png)

<details>
<summary>Full example output (text version)</summary>

```text
╔══════════════════════════════════════════════════════════╗
║  Omarchy Bloatware Detection Report                      ║
╚══════════════════════════════════════════════════════════╝

📦 Checking for preinstalled bloatware packages...
─────────────────────────────────────────────────────────────
[FOUND] kdenlive
[FOUND] obs-studio
[FOUND] xournalpp
[FOUND] evince
[FOUND] chromium
[FOUND] omasnap
[FOUND] ttf-ia-writer
[FOUND] ttf-jetbrains-mono-nerd-basic
[FOUND] docker
[FOUND] docker-buildx
[FOUND] docker-compose
[FOUND] lazydocker
[FOUND] moonlight-qt

🌐 Checking for web app launchers...
─────────────────────────────────────────────────────────────
No web app launchers detected.
💾 Top disk consumers in home directory:
─────────────────────────────────────────────────────────────
225M	~
120M	~/Videos
64M	~/.cache
40M	~/Downloads
0	~/Games
0	~/Documents

🗑️  Orphaned/unneeded packages:
─────────────────────────────────────────────────────────────
No orphaned packages found.

🖥️  Unused GUI utilities (if you prefer terminal):
─────────────────────────────────────────────────────────────

═══════════════════════════════════════════════════════════
📋 Recommendations:
─────────────────────────────────────────────────────────────
- Remove unwanted packages via Omarchy menu → Remove → Package
- Or run: sudo pacman -Rns <package-name>
- Docker storage: 8 (run 'docker system prune' to clean)

═══════════════════════════════════════════════════════════
```

</details>

*Example run on a demo machine; the home directory is shown as `~`. Your report
will list whatever is actually installed on your system.*

## The main file: `find-omarchy-bloat.sh`

This is the heart of the repo. It **detects** bloat; it does **not** remove
anything. Running it is safe at any time.

```bash
chmod +x find-omarchy-bloat.sh
./find-omarchy-bloat.sh              # full read-only report
./find-omarchy-bloat.sh --space-only # adds sizes for the candidates
./find-omarchy-bloat.sh --verbose    # deeper home-directory scan
```

### What the report shows

1. Preinstalled packages that are common bloat candidates (office suites,
   media editors, Chromium web-app wrappers, optional services like Docker).
2. Web-app launchers in `~/.local/share/applications` (Discord, YouTube, …).
3. The biggest folders in your home directory.
4. Orphaned packages (`pacman -Qdtq`) — installed but no longer required.
5. Graphical utilities you may not need if you live in the terminal.
6. With `--space-only`: how much disk each candidate uses.
7. Recommendations — printed as suggestions, never executed.

### The first-and-last rule

Run it **first** (right after a fresh install, before adding apps) and **last**
(after your full setup and cleanup). Compare the two reports to see exactly
what you added and whether anything unwanted came back.

### Safety

- Read-only: no `pacman -R`, no `rm`, no service changes.
- It only prints commands you *could* run; you stay in control.
- Removal is a separate, opt-in step — see the companion project below.

## Files

| File | What it is |
|---|---|
| [`find-omarchy-bloat.sh`](find-omarchy-bloat.sh) | The main read-only detector. |
| [`purpose.md`](purpose.md) | Why this repo exists and how the pieces fit together. |
| [`index.html`](index.html) | A browser-readable overview of the repo and the script. |
| [`assets/demo.png`](assets/demo.png) | The example report screenshot shown above. |

## Detection accuracy

The package check uses exact `pacman -Q "$pkg"` queries, so installed candidates
are reported reliably. An earlier uploaded version matched `pacman -Qs` output
with `grep "^pkg "`, which missed installed packages because those lines start
with `local/`; that is fixed here. Pipelines are SIGPIPE-safe, and the home scan
is time-bounded so a large archive cannot hang the report.

## Companion: actually removing bloat

Detection is step one. For safe, reversible cleanup with a guard list and
confirmation prompts, see
[`debloat-omarchy.sh`](https://github.com/TopGoy333/omababy/blob/main/debloat-omarchy.md)
in omababy. Nothing here runs freely — you always choose.

---

As a new Omarchy user I created this read-only script to find bloat. I would love
some collaboration — I am just getting started, so message me if you would like
to help!
