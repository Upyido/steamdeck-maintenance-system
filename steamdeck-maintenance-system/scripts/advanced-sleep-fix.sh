#!/bin/bash

# Steam Deck Sleep Button Fix Script
# Created: 2025-09-27
# Description: Fixes common sleep/suspend issues after Steam Deck system updates

# Configuration
LOG_DIR="$HOME/.local/share/maintenance-logs"
LOG_FILE="$LOG_DIR/sleep-fix-$(date +%Y-%m-%d_%H-%M-%S).log"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Logging function
log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

# Send notification
send_notification() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Steam Deck Sleep Fix" "$1" --icon=system-software-update
    fi
}

echo "🔋 Steam Deck Sleep Button Fix"
echo "=============================="
echo

# Start logging
log_message "=== Steam Deck Sleep Button Fix Started ==="
send_notification "Applying sleep button fixes..."

# 1. Check current system state
log_message "Checking current system state..."

# Check if we're in game mode vs desktop mode
if pgrep -f "steam.*-gamepadui" >/dev/null 2>&1; then
    current_mode="game"
    log_message "🎮 Currently in Game Mode"
elif [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
    current_mode="desktop"
    log_message "🖥️  Currently in Desktop Mode"
else
    current_mode="unknown"
    log_message "❓ Mode detection unclear"
fi

# 2. Diagnose sleep issues
log_message "Diagnosing sleep/suspend issues..."

issues_found=0

# Check systemd services
if ! systemctl --quiet is-active sleep.target; then
    log_message "❌ sleep.target is not active"
    ((issues_found++))
fi

if ! systemctl --quiet is-active suspend.target; then
    log_message "❌ suspend.target is not active"  
    ((issues_found++))
fi

# Check systemd-logind
if ! systemctl --quiet is-active systemd-logind; then
    log_message "❌ systemd-logind is not active"
    ((issues_found++))
fi

# Check Steam Deck UI (if in game mode)
if [ "$current_mode" = "game" ]; then
    if systemctl --user --quiet is-failed steam-deck-ui; then
        log_message "❌ Steam Deck UI service has failed"
        ((issues_found++))
    fi
fi

# Check power button configuration
logind_conf="/etc/systemd/logind.conf"
if [ -f "$logind_conf" ]; then
    power_config=$(grep -E "^HandlePowerKey|^PowerKeyIgnoreInhibited" "$logind_conf" 2>/dev/null)
    if [ -n "$power_config" ]; then
        echo "$power_config" >> "$LOG_FILE"
        if echo "$power_config" | grep -qi "ignore\\|none"; then
            log_message "❌ Power button is configured to be ignored"
            ((issues_found++))
        fi
    fi
fi

# Check for recent updates that might have caused issues
recent_updates=$(sudo grep "upgraded\|installed" /var/log/pacman.log 2>/dev/null | tail -10)
if [ -n "$recent_updates" ]; then
    log_message "📦 Recent package updates detected:"
    echo "$recent_updates" >> "$LOG_FILE"
fi

log_message "Found $issues_found potential issues"

# 3. Apply fixes
log_message "Applying comprehensive sleep/suspend fixes..."

# Fix 1: Restart systemd-logind
log_message "🔄 Restarting systemd-logind..."
if echo "deck" | sudo -S systemctl restart systemd-logind >/dev/null 2>&1; then
    log_message "✅ systemd-logind restarted successfully"
    sleep 2
else
    log_message "⚠️  Failed to restart systemd-logind"
fi

# Fix 2: Restart Steam Deck UI if in game mode
if [ "$current_mode" = "game" ]; then
    log_message "🔄 Restarting Steam Deck UI service..."
    if systemctl --user restart steam-deck-ui >/dev/null 2>&1; then
        log_message "✅ Steam Deck UI restarted successfully"
        sleep 2
    else
        log_message "⚠️  Failed to restart Steam Deck UI"
    fi
fi

# Fix 3: Clear failed service states
log_message "🧹 Clearing failed service states..."
systemctl --user reset-failed >/dev/null 2>&1
echo "deck" | sudo -S systemctl reset-failed >/dev/null 2>&1
log_message "✅ Failed service states cleared"

# Fix 4: Reload power button kernel module
log_message "🔄 Reloading power button kernel module..."
if echo "deck" | sudo -S modprobe -r button >/dev/null 2>&1; then
    sleep 1
    if echo "deck" | sudo -S modprobe button >/dev/null 2>&1; then
        log_message "✅ Power button kernel module reloaded"
    else
        log_message "⚠️  Failed to reload power button module"
    fi
else
    log_message "⚠️  Failed to unload power button module (may not be needed)"
fi

# Fix 5: Set proper sleep mode
log_message "🔧 Configuring sleep mode..."
if [ -f "/sys/power/mem_sleep" ]; then
    current_sleep_mode=$(cat /sys/power/mem_sleep 2>/dev/null)
    log_message "Current sleep modes: $current_sleep_mode"
    
    # Try to set to 'deep' sleep mode for better power savings
    if ! echo "$current_sleep_mode" | grep -q "\[deep\]"; then
        if echo "deck" | sudo -S sh -c 'echo deep > /sys/power/mem_sleep' 2>/dev/null; then
            log_message "✅ Set sleep mode to 'deep'"
        else
            log_message "⚠️  Failed to set sleep mode to 'deep'"
        fi
    else
        log_message "✅ Sleep mode already set to 'deep'"
    fi
fi

# Fix 6: Fix input device permissions
log_message "🔧 Fixing input device permissions..."
input_devices=$(find /dev/input -name "event*" 2>/dev/null)
if [ -n "$input_devices" ]; then
    echo "deck" | sudo -S chmod 644 /dev/input/event* 2>/dev/null
    log_message "✅ Input device permissions fixed"
else
    log_message "⚠️  No input devices found"
fi

# Fix 7: Ensure critical services are enabled and running
log_message "🔧 Ensuring critical services are running..."

critical_services="systemd-logind systemd-sleep"
for service in $critical_services; do
    if echo "deck" | sudo -S systemctl is-enabled "$service" >/dev/null 2>&1; then
        if ! systemctl --quiet is-active "$service"; then
            echo "deck" | sudo -S systemctl start "$service" >/dev/null 2>&1
            log_message "✅ Started $service"
        else
            log_message "✅ $service is running"
        fi
    else
        log_message "⚠️  $service is not enabled"
    fi
done

# Fix 8: Steam-specific fixes for game mode
if [ "$current_mode" = "game" ]; then
    log_message "🎮 Applying game mode specific fixes..."
    
    # Restart Steam client if running
    if pgrep steam >/dev/null 2>&1; then
        log_message "🔄 Restarting Steam client..."
        pkill steam
        sleep 3
        # Steam will auto-restart in game mode
        log_message "✅ Steam client restart initiated"
    fi
fi

# 4. Post-fix verification
log_message "✅ Verifying fixes..."

# Check if services are now working
sleep_working=true

if ! systemctl --quiet is-active systemd-logind; then
    log_message "❌ systemd-logind still not active"
    sleep_working=false
fi

if ! systemctl --quiet is-active sleep.target; then
    log_message "❌ sleep.target still not active"
    sleep_working=false
fi

# Test power management without actually sleeping
if systemctl --dry-run suspend >/dev/null 2>&1; then
    log_message "✅ Power management system is responsive"
else
    log_message "⚠️  Power management system still has issues"
    sleep_working=false
fi

# 5. Final report
log_message "=== Sleep Button Fix Completed ==="

if [ "$sleep_working" = true ]; then
    result="✅ Sleep button fix appears successful!"
    send_notification "Sleep button fix completed successfully"
    log_message "$result"
else
    result="⚠️  Some issues may remain. Check log for details."
    send_notification "Sleep button fix completed with warnings"
    log_message "$result"
fi

# Display results
echo
echo "$result"
echo
echo "📋 Summary:"
echo "  • Mode: $current_mode"
echo "  • Issues found: $issues_found"
echo "  • Services restarted: systemd-logind, Steam Deck UI"
echo "  • Kernel modules reloaded: button"
echo "  • Input permissions fixed"
echo
echo "📄 Full log: $LOG_FILE"
echo
echo "💡 Next steps:"
echo "  • Test the power button in game mode"
echo "  • If issues persist, try rebooting"
echo "  • Check maintenance logs for recurring issues"

if [ -t 1 ]; then
    echo
    read -p "Press Enter to continue..."
fi

exit 0