# Game Mode Sleep Issues - Complete Guide

## The Problem

Steam Deck users often experience issues where the power button doesn't work for sleep/suspend in Game Mode, even though it works fine for powering on and shutting down the system.

## Root Causes

### Primary Cause: Missing Game Mode Services

1. **gamescope-session.service** - Not running (provides Game Mode interface)
2. **steamos-powerbuttond.service** - Not running (handles Game Mode power button events)

These services are required for Game Mode power button functionality but may not start if:
- You booted into Desktop Mode instead of Game Mode
- System updates disrupted the Game Mode startup process
- Steam services failed to initialize properly

### Secondary Causes

- Steam client not fully loaded in Game Mode
- Power management conflicts between Desktop Mode (PowerDevil) and Game Mode
- Corrupted user session services

## Solutions

### Solution 1: Switch to Game Mode Properly (Most Common Fix)

1. **From Desktop Mode:**
   - Open Steam
   - Go to **Steam Menu → Power → Switch to Game Mode**
   - Wait for full transition (this can take 30+ seconds)

2. **From Boot:**
   - Reboot your Steam Deck
   - Let it boot into Game Mode automatically
   - Don't switch to Desktop Mode first

### Solution 2: Use the Comprehensive Diagnostic Tool

Run the Game Mode Sleep Fix:
```bash
~/.local/bin/gamemode-sleep-fix-v2.sh
```

This will:
- Detect which services aren't running
- Provide specific instructions for your situation
- Apply safe fixes where possible
- Give you exact testing steps

### Solution 3: Manual Service Restart (Advanced)

If in Game Mode but services still aren't running:
```bash
# Reload user services
systemctl --user daemon-reload

# Try to start the power button daemon (if gamescope-session is running)
systemctl --user start steamos-powerbuttond.service
```

### Solution 4: Complete System Restart

If other solutions don't work:
1. **Power off completely** (hold power button for 10+ seconds)
2. **Boot into Game Mode** (don't go to Desktop Mode first)
3. **Load a game** to ensure Steam is fully active
4. **Test power button functionality**

## Testing Power Button in Game Mode

### Method 1: Power Menu (Recommended)
1. Press power button **briefly** (don't hold)
2. Steam power menu should appear
3. Select "Sleep" option

### Method 2: Quick Sleep Shortcut
1. Hold **Steam button + Power button** together
2. System should sleep immediately

### Method 3: Steam Menu Navigation
1. Press Steam button
2. Navigate to **Power → Sleep**

## Expected Behavior

**In Game Mode:**
- Brief power button press → Steam power menu
- Long power button hold (4+ seconds) → Force shutdown
- Steam + Power buttons → Quick sleep

**In Desktop Mode:**
- Brief power button press → Immediate suspend (handled by PowerDevil)
- Long power button hold → Force shutdown

## Advanced Troubleshooting

### Check Service Status
```bash
# Check if Game Mode services are running
systemctl --user status gamescope-session.service
systemctl --user status steamos-powerbuttond.service

# Check what's handling power events
systemd-inhibit --list
```

### Session Selection
```bash
# Force switch to Game Mode session
steamos-session-select gamescope
```

### Steam Reset (Nuclear Option)
If all else fails:
1. **Steam Settings → System → Reset Steam Deck**
2. This will reset Steam to factory settings
3. You'll need to re-download games and reconfigure settings

## Prevention

1. **Boot into Game Mode by default** - don't switch to Desktop Mode unless needed
2. **Let Steam fully load** before testing power button
3. **Keep system updated** but test power button functionality after updates
4. **Use the maintenance system** to check for issues regularly

## When to Contact Support

Contact Steam Support if:
- Hardware power button doesn't respond at all
- System won't boot into either mode
- Power button works in Desktop Mode but diagnostic shows all services running correctly in Game Mode
- Physical damage to power button

These may indicate hardware issues rather than software configuration problems.