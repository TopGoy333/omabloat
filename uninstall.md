# Uninstall Omabloat Plugin

This guide shows you how to completely remove the Omabloat plugin from your Omarchy system.

## Quick Remove (Recommended)

Run this single command in your terminal:

```bash
sudo omarchy plugin uninstall topgoy333.omabloat
```

This will:
- Remove the plugin files from `/home/jimmyk/.config/omarchy/plugins/topgoy333.omabloat/`
- Clean up any configuration files created during installation
- Leave your system completely clean with no traces left behind

## Manual Removal (If Quick Method Fails)

If you prefer to remove the plugin manually, or if the quick method doesn't work:

### Step 1: Remove Plugin Files

```bash
sudo rm -rf ~/.config/omarchy/plugins/topgoy333.omabloat/
```

This removes all plugin files including your scripts, configuration, and any cached data.

### Step 2: Clean Up Configuration (Optional)

If you created any custom configurations during use:

```bash
# Remove any Omabloat-specific configs in your home directory
rm -f ~/.omarchy-omabloat/*
```

### Step 3: Verify Removal

Check that the plugin is gone:

```bash
ls ~/.config/omarchy/plugins/
# You should NOT see 'topgoy333.omabloat' in this list

# Also verify it's not available anymore
omarchy plugin list | grep -i omabloat
# Should return nothing
```

## What Gets Removed

- **Plugin files**: All scripts (`find-omarchy-bloat.sh`, `install-steam.sh`, etc.)
- **Configuration files**: Any settings or configs created during installation
- **Documentation**: README, manifest.json, uninstall.md, and other docs
- **Cached data**: Any temporary files or databases the plugin created

## Important Notes

⚠️ **Your system is safe** — Omabloat only modifies user-level configuration, not system-critical files. Removing it won't affect your installed applications or system stability.

⚠️ **Steam games are NOT affected** — This plugin only helps with Steam installation and doesn't modify any game files. Your games will remain intact.

## After Uninstall

Once removed, you can reinstall the plugin anytime by running:

```bash
cd /home/jimmyk/git
sudo omarchy plugin install topgoy333.omabloat
```

Or simply clone this repository again and run the setup scripts.

---

*Made with ❤️ for the Omarchy community. If you found this guide helpful, consider starring the repo!* 😄
