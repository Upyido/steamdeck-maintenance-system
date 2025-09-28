#!/bin/bash

# Steam Deck Monthly Maintenance Script - SAFE VERSION
# Created: 2025-09-27
# Description: Performs regular system maintenance without breaking sleep functionality

# Configuration
LOG_DIR="$HOME/.local/share/maintenance-logs"
LOG_FILE="$LOG_DIR/monthly-maintenance-$(date +%Y-%m).log"
NOTIFICATION_ENABLED=true

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Logging function
log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

# Send notification (if desktop is available)
send_notification() {
    if [ "$NOTIFICATION_ENABLED" = true ] && command -v notify-send >/dev/null 2>&1; then
        notify-send "Steam Deck Maintenance" "$1" --icon=system-software-update
    fi
}

# Start maintenance
log_message "=== SAFE Monthly Maintenance Started ==="
send_notification "Safe monthly maintenance started..."

echo "🛠️  Steam Deck Safe Monthly Maintenance"
echo "======================================="
echo

# 1. Update Flatpak applications
echo "1. Updating Flatpak applications..."
log_message "Updating Flatpak applications..."
if flatpak update -y --noninteractive >>$LOG_FILE 2>&1; then
    log_message "✅ Flatpak update completed successfully"
    echo "   ✅ Flatpak apps updated"
else
    log_message "⚠️  Flatpak update had issues (check logs)"
    echo "   ⚠️  Flatpak update issues (check logs)"
fi

# 2. Update font cache (safe)
echo "2. Updating font cache..."
log_message "Updating font cache..."
if fc-cache -fv >/dev/null 2>&1; then
    log_message "✅ Font cache updated"
    echo "   ✅ Font cache updated"
else
    log_message "⚠️  Font cache update failed"
    echo "   ⚠️  Font cache update failed"
fi

# 3. Update desktop database (safe)
echo "3. Updating desktop database..."
log_message "Updating desktop database..."
if update-desktop-database "$HOME/.local/share/applications/" >/dev/null 2>&1; then
    log_message "✅ Desktop database updated"
    echo "   ✅ Desktop database updated"
else
    log_message "⚠️  Desktop database update failed"
    echo "   ⚠️  Desktop database update failed"
fi

# 4. Update MIME database (safe)
echo "4. Updating MIME database..."
log_message "Updating MIME database..."
if update-mime-database "$HOME/.local/share/mime" >/dev/null 2>&1; then
    log_message "✅ MIME database updated"
    echo "   ✅ MIME database updated"
else
    log_message "⚠️  MIME database update failed"
    echo "   ⚠️  MIME database update failed"
fi

# 5. Clean old cache files (safe - only removes old files)
echo "5. Cleaning old cache files (>30 days)..."
log_message "Cleaning old cache files..."
if [ -d "$HOME/.cache" ]; then
    cache_cleaned=$(find "$HOME/.cache" -type f -mtime +30 -delete 2>/dev/null | wc -l)
    log_message "✅ Cleaned $cache_cleaned old cache files"
    echo "   ✅ Cleaned $cache_cleaned old cache files"
else
    echo "   ℹ️  No cache directory found"
fi

# 6. Clean old maintenance logs (safe - keeps recent logs)
echo "6. Cleaning old maintenance logs (>6 months)..."
log_message "Cleaning old maintenance logs..."
if [ -d "$LOG_DIR" ]; then
    old_logs=$(find "$LOG_DIR" -name "*.log" -mtime +180 -delete 2>/dev/null | wc -l)
    log_message "✅ Cleaned $old_logs old maintenance log files"
    echo "   ✅ Cleaned $old_logs old maintenance log files"
fi

# 7. Check disk usage (informational only)
echo "7. Checking disk usage..."
log_message "Checking disk usage..."
home_usage=$(df /home | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$home_usage" -gt 85 ]; then
    log_message "⚠️  WARNING: Home partition usage is ${home_usage}%"
    send_notification "Warning: Disk usage is high (${home_usage}%)"
    echo "   ⚠️  WARNING: High disk usage (${home_usage}%)"
else
    log_message "✅ Disk usage healthy: ${home_usage}%"
    echo "   ✅ Disk usage healthy: ${home_usage}%"
fi

# 8. Steam maintenance (safe cleaning only)
echo "8. Steam maintenance..."
if [ -d "$HOME/.local/share/Steam" ]; then
    log_message "Performing safe Steam maintenance..."
    
    # Only clean very large caches (>200MB) to avoid breaking things
    steam_cache="$HOME/.local/share/Steam/config/htmlcache"
    if [ -d "$steam_cache" ]; then
        cache_size=$(du -sm "$steam_cache" 2>/dev/null | cut -f1)
        if [ "$cache_size" -gt 200 ]; then
            rm -rf "$steam_cache"/*
            log_message "✅ Cleaned very large Steam HTML cache (${cache_size}MB)"
            echo "   ✅ Cleaned large Steam cache (${cache_size}MB)"
        else
            echo "   ✅ Steam cache size OK (${cache_size}MB)"
        fi
    fi
else
    echo "   ℹ️  No Steam directory found"
fi

# 9. Basic system health check (no fixes, just reporting)
echo "9. Basic system health check..."
log_message "Checking basic system health..."

# Check if important services are running (don't restart them!)
services_ok=true
if ! systemctl is-active systemd-logind >/dev/null 2>&1; then
    log_message "⚠️  systemd-logind is not active"
    echo "   ⚠️  systemd-logind is not active - sleep may not work"
    services_ok=false
fi

if systemctl --user is-failed steam-deck-ui >/dev/null 2>&1; then
    log_message "⚠️  Steam Deck UI service has failed"
    echo "   ⚠️  Steam Deck UI service has failed"
    services_ok=false
fi

if [ "$services_ok" = true ]; then
    echo "   ✅ Critical services are running"
    log_message "✅ Critical services are running"
else
    echo "   💡 Consider rebooting if you experience issues"
fi

# 10. Check system temperatures (informational)
echo "10. System temperature check..."
if command -v sensors >/dev/null 2>&1; then
    log_message "Checking system temperatures..."
    temps=$(sensors 2>/dev/null | grep -E "edge|Composite" | head -2)
    if [ -n "$temps" ]; then
        echo "$temps" >> "$LOG_FILE"
        echo "   ℹ️  Temperature data logged"
        log_message "✅ Temperature check completed"
    else
        echo "   ℹ️  No temperature sensors found"
    fi
else
    echo "   ℹ️  Sensors not available"
fi

# Final report
echo
echo "🎉 Safe maintenance completed!"
log_message "=== SAFE Monthly Maintenance Completed ==="
send_notification "Safe monthly maintenance completed!"

echo "📋 Summary:"
echo "   • Flatpak apps updated"
echo "   • System databases refreshed"
echo "   • Old cache files cleaned"
echo "   • Disk usage: ${home_usage}%"
echo "   • No critical services were restarted"

echo
echo "📄 Log file: $LOG_FILE"
echo "💡 If you experience sleep issues, use the game mode sleep fix instead"

if [ -t 1 ]; then
    echo
    echo "Press Enter to continue..."
    read
fi

exit 0