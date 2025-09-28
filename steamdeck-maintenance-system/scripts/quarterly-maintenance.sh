#!/bin/bash

# Steam Deck Quarterly Maintenance Script
# Created: 2025-09-27
# Description: Performs deep system maintenance tasks every 90 days

# Configuration
LOG_DIR="$HOME/.local/share/maintenance-logs"
LOG_FILE="$LOG_DIR/quarterly-maintenance-$(date +%Y-Q%q).log"
NOTIFICATION_ENABLED=true

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
    if [ "$NOTIFICATION_ENABLED" = true ] && command -v notify-send >/dev/null 2>&1; then
        notify-send "Steam Deck Quarterly Maintenance" "$1" --icon=system-software-update
    fi
}

# Start maintenance
log_message "=== Quarterly Deep Maintenance Started ==="
send_notification "Quarterly deep maintenance started..."

# 1. Run monthly maintenance first
log_message "Running monthly maintenance tasks first..."
if [ -f "$HOME/.local/bin/monthly-maintenance.sh" ]; then
    bash "$HOME/.local/bin/monthly-maintenance.sh" >>"$LOG_FILE" 2>&1
    log_message "✅ Monthly maintenance completed"
else
    log_message "⚠️  Monthly maintenance script not found"
fi

# 2. Deep disk analysis
log_message "Performing deep disk analysis..."
{
    echo "=== DISK USAGE ANALYSIS ==="
    df -h
    echo
    echo "=== LARGEST DIRECTORIES IN HOME ==="
    du -h --max-depth=2 "$HOME" 2>/dev/null | sort -hr | head -20
    echo
    echo "=== LARGEST FILES IN HOME (>100MB) ==="
    find "$HOME" -type f -size +100M -exec ls -lh {} \; 2>/dev/null | head -10
} >> "$LOG_FILE"
log_message "✅ Deep disk analysis completed"

# 3. Find and remove orphaned Flatpak data
log_message "Checking for orphaned Flatpak data..."
installed_apps=$(flatpak list --columns=application | tail -n +2)
orphaned_count=0

if [ -d "$HOME/.var/app" ]; then
    for app_dir in "$HOME/.var/app"/*; do
        if [ -d "$app_dir" ]; then
            app_name=$(basename "$app_dir")
            if ! echo "$installed_apps" | grep -q "^$app_name$"; then
                size=$(du -sh "$app_dir" 2>/dev/null | cut -f1)
                log_message "Found orphaned app data: $app_name ($size)"
                rm -rf "$app_dir"
                ((orphaned_count++))
            fi
        fi
    done
fi
log_message "✅ Removed $orphaned_count orphaned app data directories"

# 4. Steam deep cleanup
if [ -d "$HOME/.local/share/Steam" ]; then
    log_message "Performing Steam deep cleanup..."
    
    # Clear all shader cache (will regenerate)
    if [ -d "$HOME/.local/share/Steam/steamapps/shadercache" ]; then
        shader_size=$(du -sh "$HOME/.local/share/Steam/steamapps/shadercache" | cut -f1)
        rm -rf "$HOME/.local/share/Steam/steamapps/shadercache"/*
        log_message "✅ Cleared all shader cache ($shader_size)"
    fi
    
    # Clean up old compatibility tool versions (keep latest 3)
    if [ -d "$HOME/.local/share/Steam/compatibilitytools.d" ]; then
        cd "$HOME/.local/share/Steam/compatibilitytools.d"
        proton_dirs=$(ls -1t | grep -E "GE-Proton|Proton" | tail -n +4)
        if [ -n "$proton_dirs" ]; then
            echo "$proton_dirs" | while read dir; do
                if [ -d "$dir" ]; then
                    size=$(du -sh "$dir" | cut -f1)
                    rm -rf "$dir"
                    log_message "Removed old Proton version: $dir ($size)"
                fi
            done
        fi
    fi
    
    # Clean Steam logs
    if [ -d "$HOME/.local/share/Steam/logs" ]; then
        find "$HOME/.local/share/Steam/logs" -name "*.log" -mtime +30 -delete
        log_message "✅ Cleaned old Steam logs"
    fi
fi

# 5. System health checks
log_message "Performing system health checks..."

# Check for disk errors
if command -v smartctl >/dev/null 2>&1; then
    if sudo smartctl -H /dev/nvme0n1 2>/dev/null | grep -q "PASSED"; then
        log_message "✅ NVMe drive health: PASSED"
    else
        log_message "⚠️  NVMe drive health check failed or unavailable"
    fi
fi

# Memory test summary
memory_total=$(free -h | awk '/^Mem:/ {print $2}')
memory_available=$(free -h | awk '/^Mem:/ {print $7}')
log_message "💾 Memory status: $memory_available available of $memory_total total"

# Check for system updates (informational)
if steamos-readonly status | grep -q "enabled"; then
    log_message "🔒 SteamOS read-only mode: enabled (system protected)"
else
    log_message "⚠️  SteamOS read-only mode: disabled"
fi

# 6. Clean up broken symbolic links system-wide
log_message "Searching for broken symbolic links in home directory..."
broken_links=$(find "$HOME" -xtype l 2>/dev/null)
if [ -n "$broken_links" ]; then
    echo "$broken_links" | wc -l | xargs -I {} log_message "Found {} broken symbolic links"
    echo "$broken_links" | xargs rm -f
    log_message "✅ Removed broken symbolic links"
else
    log_message "✅ No broken symbolic links found"
fi

# 7. Optimize Flatpak
log_message "Optimizing Flatpak installations..."
if flatpak uninstall --unused -y >>"$LOG_FILE" 2>&1; then
    log_message "✅ Removed unused Flatpak runtimes"
else
    log_message "⚠️  No unused Flatpak runtimes to remove"
fi

# 8. Generate system report
log_message "Generating system report..."
{
    echo "=== QUARTERLY SYSTEM REPORT ==="
    echo "Date: $(date)"
    echo "Uptime: $(uptime)"
    echo
    echo "=== STORAGE SUMMARY ==="
    df -h | grep -E "/(home|var|)$"
    echo
    echo "=== TEMPERATURE CHECK ==="
    if command -v sensors >/dev/null 2>&1; then
        sensors 2>/dev/null | grep -E "(edge|Composite):"
    else
        echo "Sensors not available"
    fi
    echo
    echo "=== INSTALLED FLATPAK APPS ==="
    flatpak list --columns=name,version,branch | head -20
    echo
    echo "=== STEAM GAMES COUNT ==="
    if [ -d "$HOME/.local/share/Steam/steamapps/common" ]; then
        game_count=$(ls "$HOME/.local/share/Steam/steamapps/common" | wc -l)
        echo "Installed games: $game_count"
    else
        echo "Steam not installed or no games found"
    fi
} >> "$LOG_FILE"

# 9. Clean up large log files
log_message "Checking for large log files..."
large_logs=$(find "$HOME" -name "*.log" -size +10M 2>/dev/null)
if [ -n "$large_logs" ]; then
    echo "$large_logs" | while read logfile; do
        size=$(du -sh "$logfile" | cut -f1)
        # Keep last 100 lines of large logs
        tail -100 "$logfile" > "${logfile}.tmp" && mv "${logfile}.tmp" "$logfile"
        log_message "Truncated large log file: $logfile ($size)"
    done
else
    log_message "✅ No large log files found"
fi

# Final summary
total_space=$(df /home | awk 'NR==2 {print $2}' | numfmt --to=iec)
used_space=$(df /home | awk 'NR==2 {print $3}' | numfmt --to=iec)
free_space=$(df /home | awk 'NR==2 {print $4}' | numfmt --to=iec)
usage_percent=$(df /home | awk 'NR==2 {print $5}')

log_message "=== Quarterly Deep Maintenance Completed ==="
log_message "📊 Storage Summary: $used_space used / $free_space free / $total_space total ($usage_percent)"

# Send completion notification
send_notification "Quarterly maintenance completed! Check logs for details."

# Display summary if running interactively  
if [ -t 1 ]; then
    echo "🎉 Quarterly deep maintenance completed!"
    echo "📄 Full report: $LOG_FILE"
    echo "💾 Storage: $used_space used / $free_space free ($usage_percent)"
    echo
    echo "Key actions performed:"
    echo "  • Deep disk analysis and cleanup"
    echo "  • Removed orphaned application data"
    echo "  • Steam deep cleanup (shaders, old Proton versions)"
    echo "  • System health checks"
    echo "  • Flatpak optimization"
    echo
    echo "📋 To view full report: cat '$LOG_FILE'"
fi

exit 0