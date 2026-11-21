# Steam on Omarchy — a beginner's path from clean install to playable games

This guide is written in the order a person actually does things. You do not
need to understand every term first: each step explains what it does and why it
is there. If you only remember one thing, remember the first-and-last rule below.

## The first-and-last rule

[`find-omarchy-bloat.sh`](find-omarchy-bloat.sh) is the **bookend** of a full
setup:

- Run it **first**, right after a fresh Omarchy install, before you add apps.
  That is your baseline: what did Omarchy ship with?
- Run it **last**, after Steam, ProtonPlus and all the other apps are in place
  and you have reviewed cleanup. Now you can compare and see exactly what you
  added — and whether anything unwanted came back with it.

It is **read-only**: it never removes or changes anything. The cleanup tool
[`debloat-omarchy.sh`](debloat-omarchy.md) is separate, and its default mode is
read-only too.

## The flow (follow the tree; skip branches you do not need)

```text
START — fresh Omarchy install
│
├─ 1. FIRST: ./find-omarchy-bloat.sh          ← baseline, read-only
│
├─ 2. Prepare: update + a quick backup
│
├─ 3. ./install-steam.sh                      ← guided Steam install
│        └─ runs: omarchy install gaming steam
│
├─ 4. Test a Linux-native game (no Proton needed)
│
├─ 5. Does a Windows game refuse to run?
│        ├─ NO  → skip the ProtonPlus branch, go to step 6
│        └─ YES → ProtonPlus branch
│                  ├─ flatpak install flathub com.vysp3r.ProtonPlus
│                  ├─ ProtonPlus → Steam → install GE-Proton
│                  ├─ restart Steam
│                  └─ game Properties → Compatibility → force GE-Proton
│
├─ 6. Optional companions (gaming gpu-lib32, xbox-controllers, retroarch)
│
└─ 7. LAST: ./find-omarchy-bloat.sh           ← compare with step 1
         └─ ./debloat-omarchy.sh --audit      ← read-only cleanup review
```

Every branch rejoins at step 7. Nothing in this flow is permanent until you
actually run an install or cleanup command, and each of those asks first.

---

## Step 1 — FIRST: take the baseline

```bash
chmod +x find-omarchy-bloat.sh install-steam.sh debloat-omarchy.sh
./find-omarchy-bloat.sh
```

You will see a report: known bloatware packages, web-app launchers, the biggest
folders in your home directory, orphaned packages and GUI utilities. **Read it,
do not act on it yet.** This is your "before" picture. Keep the output in mind
(or copy it into a note) for step 7. Optional flags: `--space-only` adds
package sizes; `--verbose` scans one level deeper. The home scan is
time-bounded so a huge archive cannot hang the report.

## Step 2 — update and make a small safety net

```bash
omarchy update
```

`omarchy update` updates the system the Omarchy way. If you have changed configs
in `~/.config/`, copy them somewhere safe before big changes:

```bash
mkdir -p ~/backups
cp -a ~/.config/hypr ~/.config/omarchy ~/backups/
```

That is not a full backup — it is a fast undo for the files most likely to be
touched during setup.

## Step 3 — install Steam the Omarchy way

```bash
./install-steam.sh --check    # read-only: what is already installed?
./install-steam.sh            # guided install; asks before changing anything
```

If Steam is already installed, the script says so and does not reinstall it. If
it is missing, it runs:

```bash
omarchy install gaming steam
```

That is Omarchy's supported installer: it installs Steam **and** the graphics
drivers selected for your machine, which saves you from guessing about 32-bit
libraries by hand. When it finishes, launch Steam once and let it finish its
first-run setup. `pacman -Q steam` confirms the package is present.

Want ProtonPlus at the same time? `./install-steam.sh --with-protonplus` will
*offer* to install it, but never does so silently.

## Step 4 — understand Proton before you add tools

Steam Play / Proton is the translation layer that lets Windows games run on
Linux. Steam already includes several Proton versions. Try a game first with
the default: many simply work. In Steam you can see them under
**Settings → Compatibility → Steam Play**.

Steam being in Arch's `multilib` repository is why 32-bit game libraries are
available at all — the Omarchy installer handles that for you. If a game says a
32-bit library is missing, that is the thing to check first.

## Step 5 — the ProtonPlus branch (only when a game needs it)

### The words, in plain language

| Term | What it really is |
|---|---|
| **Proton** | Valve's Windows-to-Linux compatibility layer built into Steam. |
| **GE-Proton** | A community build of Proton with fixes/newer pieces; often unblocks games the official build cannot. |
| **ProtonPlus** | A GUI that downloads and organizes GE-Proton (and Wine-GE, DXVK, VKD3D) for Steam and other launchers. |
| **ProtonUp-Qt** | Another GUI for the same job. Pick one; you do not need both. |

So: you do **not** need ProtonPlus just because you installed Steam. You need
it when a specific game needs a newer/custom Proton than Steam ships.

### Install it when you need it

```bash
# Easiest — Flatpak, also visible in Bazaar:
flatpak install flathub com.vysp3r.ProtonPlus

# Native AUR alternative (requires an AUR helper):
yay -S protonplus
```

### Use it for one game

1. Launch Steam once, then open ProtonPlus and choose Steam as the launcher.
2. Install a GE-Proton release. Tools are placed in
   `~/.steam/steam/steamapps/common/`.
3. Quit and restart Steam so it notices the new tool.
4. In Steam, right-click the game → **Properties → Compatibility**, tick
   **Force the use of a specific Steam Play compatibility tool**, and choose
   the GE-Proton version.
5. Launch the game. If it works, leave it alone. If not, try another version.

Setting it per game is safer than forcing one Proton for your whole library.

## Step 6 — optional companions

```bash
omarchy install gaming gpu-lib32        # 32-bit graphics drivers
omarchy install gaming xbox-controllers # controllers in Steam/RetroArch/etc.
omarchy install gaming retroarch        # retro games, cores, ~/Games folder
```

Add only what you will actually use — that is the whole point of the baseline
and final comparison.

## Step 7 — LAST: compare, then review cleanup

```bash
./find-omarchy-bloat.sh          # compare this with step 1
./debloat-omarchy.sh --audit     # read-only cleanup review
```

If something new looks unwanted, read
[`debloat-omarchy.md`](debloat-omarchy.md) before running `--apply` or
`--remove`. The script has a guard list (Dolphin file manager, Bazaar, Hermes,
the `claude-*` wrappers and Omarchy core packages are protected), writes a
manifest before removals, and asks for confirmation.

## Troubleshooting, briefly

| Symptom | First thing to check |
|---|---|
| Steam will not start | `pacman -Q steam`; re-run `omarchy install gaming steam`; open a new shell after installing. |
| "Missing 32-bit library" | `omarchy install gaming gpu-lib32` (multilib/32-bit graphics drivers). |
| Windows game will not launch | Try Steam's built-in Proton first; if it still fails, use the ProtonPlus branch. |
| ProtonPlus cannot find Steam | Launch Steam once and sign in, then restart ProtonPlus. |
| Controller not seen | `omarchy install gaming xbox-controllers`; check Steam's controller settings. |
| Want to remove Steam later | `omarchy remove gaming steam` — warning: this removes game libraries, configs and caches; back up `~/.steam` first. |

## Related files

- [`find-omarchy-bloat.sh`](find-omarchy-bloat.sh) — the first and last step.
- [`install-steam.sh`](install-steam.sh) — the guided installer used above.
- [`debloat-omarchy.sh`](debloat-omarchy.md) — safe cleanup with a guard list.
