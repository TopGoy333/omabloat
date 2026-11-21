# Omabloat bar widget

An [Omarchy](https://omarchy.org/) bar widget for the `omabloat` repo.

`manifest.json`, `BarWidget.qml`, and `Panel.qml` sit at the **repo root**, so
installing the plugin installs the scripts beside them — no separate folder, and
the widget always finds `find-omarchy-bloat.sh` next to itself.

Click the bar icon to open a small panel. The buttons run the repo's scripts in
your terminal through `xdg-terminal-exec`, so you see the real output.

## Install

```bash
omarchy plugin add https://github.com/TopGoy333/omabloat --enable
```

That installs `topgoy333.omabloat`. Move it if you like:

```bash
omarchy bar move topgoy333.omabloat --section right
```

## What it does

- Opens a panel from the bar.
- Offers a read-only scan, a space report, a debloat audit, and a Steam check.
- Runs each script in your terminal; the bar itself never changes the system.

## Layout

```
manifest.json        plugin manifest (id: topgoy333.omabloat)
BarWidget.qml        bar icon + panel loader
Panel.qml            the popup and its actions
find-omarchy-bloat.sh  read-only detector
debloat-omarchy.sh     guarded cleanup
install-steam.sh       Steam setup
```

## Remove

```bash
omarchy plugin remove topgoy333.omabloat
```

## License

MIT — see the repo root.
