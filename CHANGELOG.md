# Changelog

## [2.0.0] - 2025-09-27

### Major Rewrite
- Complete rewrite of maintenance system for safety and reliability
- Fixed critical issues with Game Mode sleep/suspend functionality

### Added
- **Comprehensive Game Mode Sleep Fix (v2)** - Properly diagnoses and fixes Game Mode power button issues
- **Safe Monthly Maintenance** - No longer restarts critical services that can break sleep functionality
- **Simple TUI** - Reliable interface that works without complex dependencies
- **Desktop Entries** - Easy launching from Steam Deck application menu
- **Comprehensive Logging** - All operations logged with timestamps
- **Installation/Uninstall Scripts** - Easy setup and removal

### Fixed
- **Game Mode Sleep Button Issues** - Root cause identified as missing `gamescope-session.service` and `steamos-powerbuttond.service`
- **Mouse Cursor Disappearing** - Removed service restarts that caused display issues
- **TUI Dependencies** - Replaced complex terminal manipulation with simple, reliable interface
- **Maintenance Safety** - Scripts no longer restart `systemd-logind`, Steam services, or manipulate kernel modules unnecessarily

### Changed
- Maintenance scripts now focus on safe operations only (Flatpak updates, cache cleaning, database updates)
- Sleep fixes are separate, targeted tools rather than automatic maintenance actions
- TUI uses simple echo/read instead of complex terminal control
- All scripts properly handle errors and provide user feedback

### Removed
- Risky automatic service restarts during maintenance
- Complex terminal UI dependencies (tput, bc, etc.)
- Hardcoded password attempts
- Automatic kernel module manipulation

### Technical Details

#### Game Mode Sleep Fix
- Detects `gamescope-session.service` status (required for Game Mode)
- Checks `steamos-powerbuttond.service` status (handles Game Mode power events)
- Identifies Steam process status (`steam -gamepadui`)
- Provides mode-specific testing instructions
- Creates diagnostic logs for troubleshooting

#### Safe Maintenance
- Flatpak application updates
- Font and desktop database updates
- Old cache file cleanup (>30 days)
- Old log cleanup (>6 months)
- Steam cache cleanup (only very large caches >200MB)
- Disk usage monitoring
- System health reporting (no fixes, just alerts)

## [1.0.0] - 2025-09-27 (Initial Version)

### Issues in Original Version
- Restarted critical services (`systemd-logind`, `steam-deck-ui`)
- Used hardcoded passwords that often failed
- Complex TUI had dependency issues
- Sleep fixes were too aggressive and caused other problems
- Mixed desktop and game mode functionality

### Why Complete Rewrite Was Necessary
The original version was causing more problems than it solved:
1. **Breaking Sleep Functionality** - By restarting `systemd-logind` and other critical services
2. **Mouse Cursor Issues** - Service restarts affected display management
3. **Authentication Problems** - Hardcoded password attempts failed
4. **Wrong Problem Diagnosis** - Tried to fix desktop mode sleep issues instead of Game Mode specific problems

The v2.0.0 rewrite addresses the actual root causes and provides safe, targeted solutions.