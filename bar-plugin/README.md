# Omabloat bar widget

An [Omarchy](https://omarchy.org/) bar widget for the `omabloat` repo.

Click the bar icon to open a small panel. The buttons run the repo's scripts in
your terminal through `xdg-terminal-exec`, so you see the real output.

## Install

```bash
omarchy plugin add https://github.com/TopGoy333/omabloat --enable
```

That installs `topgoy333.omabloat` from this folder. Move it if you like:

```bash
omarchy bar move topgoy333.omabloat --section right
```

## What it does

- Opens a panel from the bar.
- Offers a read-only scan, a space report, and a read-only debloat audit.
- Runs each script in your terminal; the bar itself never changes the system.

## Remove

```bash
omarchy plugin remove topgoy333.omabloat
```

## License

MIT — see the repo root.
