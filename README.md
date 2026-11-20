docs/explain-bloat-detector
# omabloat

A small, **read-only** helper for finding bloat on [Omarchy](https://omarchy.org/)
(and it should work on plain Arch too). The goal is to make Omarchy accessible
to the average PC user: see what is installed, decide what you actually use,
and keep the machine feeling normal — with things like the Bazaar app store
still available.

## The main file: `find-omarchy-bloat.sh`

This is the heart of the repo. It **detects** bloat; it does **not** remove
anything. Running it is safe at any time.

bash
chmod +x find-omarchy-bloat.sh
./find-omarchy-bloat.sh              # full read-only report
./find-omarchy-bloat.sh --space-only # adds sizes for the candidates
./find-omarchy-bloat.sh --verbose    # deeper home-directory scan


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

## Known limitation (current uploaded version)

The package check uses `pacman -Qs "$pkg" | grep "^$pkg "`, but `pacman -Qs`
prints lines like `local/pkg …`, so installed packages can be missed. A
corrected copy (exact `pacman -Q` checks, SIGPIPE-safe pipelines, bounded home
scan) lives in the companion repo
[omababy](https://github.com/TopGoy333/omababy). This change only improves the
explanatory files; the script itself is unchanged.

## Companion: actually removing bloat

Detection is step one. For safe, reversible cleanup with a guard list and
confirmation prompts, see
[`debloat-omarchy.sh`](https://github.com/TopGoy333/omababy/blob/main/debloat-omarchy.md)
in omababy. Nothing here runs freely — you always choose.

As a new omarchy user I created a script to find bloat that is read only. i would love some collaboration as i am just getting started so message me if you'd like
 main
