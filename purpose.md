# Purpose

MAKE OMARCHY ACCESSIBLE to the average PC user — and teach people about
plugins and their own software along the way.

This repo is the **detection** half of that goal. The main file,
[`find-omarchy-bloat.sh`](find-omarchy-bloat.sh), looks at an Omarchy install
and reports what is probably bloat: heavy preinstalled apps, Chromium web-app
wrappers, orphaned packages and the folders eating your disk. It changes
nothing. You read the report and decide.

## Why detection comes first

A normal PC experience (Bazaar store, Dolphin files, the apps you actually
use) starts with knowing what is already there. Running the detector first
gives you a baseline; running it again after setup shows what changed. That
"first and last" habit is the whole workflow.

## How the pieces fit

- `find-omarchy-bloat.sh` — the main, read-only detector (this repo).
- `index.html` — a browser-readable overview of the repo and the script.
- `README.md` — the quick-start and file map.
- Cleanup is intentionally a **separate, opt-in** tool, not something this
  script does freely. The companion
  [omababy](https://github.com/TopGoy333/omababy) repo has
  `debloat-omarchy.sh`, which removes only what you name, asks first, and
  protects the apps people rely on.

## What is coming next

- Plugin write-ups in `.md` files so you can read, find and copy a working
  setup instead of guessing.
- Example shell functions / bashrc snippets — shared only after checking they
  contain no secret keys.
- Multiple choose-your-own files rather than one script that runs freely.

## Privacy and safety

- The detector is read-only.
- Nothing with secret keys is published.
- Every removal step elsewhere is explicit and confirmed.

## Detection accuracy

The detector uses exact `pacman -Q` checks, so installed candidates are reported
reliably. An earlier version matched `pacman -Qs` output and could miss installed
packages; that is fixed. The home-directory scan is time-bounded so a large
archive cannot hang the report.
