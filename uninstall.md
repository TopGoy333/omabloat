# Uninstall Omabloat

Omabloat is an Omarchy shell plugin (`topgoy333.omabloat`) plus a set of
standalone scripts. Remove the bar widget, the scripts, or both.

## Remove the bar widget

```bash
omarchy plugin remove topgoy333.omabloat --yes
```

That removes the plugin folder (the widget and its panel) and takes the bar
icon with it.

## Remove the scripts too

The plugin folder is the whole repo, so removing the plugin removes the scripts
as well. If you kept a separate clone, delete it:

```bash
rm -rf ~/omabloat
```

## Verify

```bash
omarchy plugin list | grep -i omabloat                 # should print nothing
ls ~/.config/omarchy/plugins/ | grep -i omabloat       # should print nothing
```

## Leftovers worth knowing about

- Debloat logs live in `~/.local/share/omabloat/` and are harmless to keep.
  Delete them with `rm -rf ~/.local/share/omabloat`.
- Nothing else is written outside the plugin folder and that log directory.

## Reinstall

```bash
omarchy plugin add https://github.com/TopGoy333/omabloat --enable
```

---

*Made with ❤️ for the Omarchy community.*
