# Steam Deck Maintenance System

A simple, safe maintenance system for Steam Deck with an interactive TUI and robust sleep/suspend diagnostics and fixes, especially for Game Mode.

## Features
- Interactive, reliable TUI
- Safe monthly maintenance (no risky service restarts)
- Comprehensive Game Mode sleep/suspend diagnostics and fixes
- Advanced sleep fix (optional)
- Desktop entries for easy launching
- Logs and quick references

## Scripts
- scripts/maintenance-tui.sh — Interactive TUI (recommended entrypoint)
- scripts/monthly-maintenance.sh — Safe monthly maintenance
- scripts/gamemode-sleep-fix.sh — Comprehensive Game Mode sleep fix (v2)
- scripts/advanced-sleep-fix.sh — Advanced sleep fix (restarts services; optional)

## Install
```
./install.sh
```

## Manual Usage
```
~/.local/bin/maintenance-tui.sh
```

## Desktop Entries (optional)
- desktop-entries/deck-maintenance.desktop — Launch TUI
- desktop-entries/deck-sleep-fix.desktop — Quick sleep fix launcher

## Notes
- Designed for SteamOS (Steam Deck)
- All scripts log to ~/.local/share/maintenance-logs
- Safe maintenance avoids restarting critical services

## License
MIT
