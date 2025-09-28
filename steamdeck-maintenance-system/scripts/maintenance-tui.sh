#!/bin/bash

# Steam Deck Maintenance - Simple TUI
# Created: 2025-09-27
# Simple, reliable interface for maintenance operations

# Configuration
LOG_DIR="$HOME/.local/share/maintenance-logs"
SCRIPT_DIR="$HOME/.local/bin"

# Simple colors (using echo -e)
show_header() {
    clear
    echo "=================================================="
    echo "        Steam Deck Maintenance System"
    echo "=================================================="
    echo
}

show_menu() {
    show_header
    echo "Main Menu:"
    echo "=========="
    echo
    echo "1) Run Safe Monthly Maintenance"
    echo "2) Run Quarterly Deep Maintenance" 
    echo "3) Fix Game Mode Sleep Issues (RECOMMENDED)"
    echo "4) Fix Sleep Button Issues (Advanced)"
    echo "5) View System Status"
    echo "6) View Recent Logs"
    echo "7) Enable/Disable Auto Maintenance"
    echo "8) Test Sleep Button"
    echo "q) Quit"
    echo
    echo -n "Choose an option [1-8, q]: "
}

show_system_status() {
    show_header
    echo "System Status:"
    echo "=============="
    echo
    
    # Disk usage
    echo "💾 Disk Usage:"
    df -h /home | grep -v Filesystem
    echo
    
    # Memory
    echo "🧠 Memory Usage:"
    free -h | head -2
    echo
    
    # Uptime
    echo "⏱️  System Uptime:"
    uptime
    echo
    
    # Maintenance timers
    echo "⏰ Maintenance Timers:"
    if systemctl --user is-enabled monthly-maintenance.timer >/dev/null 2>&1; then
        echo "  Monthly: ENABLED"
    else
        echo "  Monthly: DISABLED"
    fi
    
    if systemctl --user is-enabled quarterly-maintenance.timer >/dev/null 2>&1; then
        echo "  Quarterly: ENABLED"
    else
        echo "  Quarterly: DISABLED"
    fi
    echo
    
    echo "Press Enter to continue..."
    read
}

run_monthly_maintenance() {
    show_header
    echo "Running Monthly Maintenance..."
    echo "============================="
    echo
    
    if [ -x "$SCRIPT_DIR/monthly-maintenance-safe.sh" ]; then
        echo "Starting SAFE monthly maintenance. This may take a few minutes..."
        echo "(This version won't break your sleep functionality)"
        echo
        "$SCRIPT_DIR/monthly-maintenance-safe.sh"
        echo
        echo "Safe monthly maintenance completed!"
    else
        echo "Error: Safe monthly maintenance script not found!"
    fi
    
    echo
    echo "Press Enter to continue..."
    read
}

run_quarterly_maintenance() {
    show_header
    echo "Running Quarterly Deep Maintenance..."
    echo "===================================="
    echo
    
    if [ -x "$SCRIPT_DIR/quarterly-maintenance.sh" ]; then
        echo "Starting quarterly maintenance. This may take several minutes..."
        echo
        "$SCRIPT_DIR/quarterly-maintenance.sh"
        echo
        echo "Quarterly maintenance completed!"
    else
        echo "Error: Quarterly maintenance script not found!"
    fi
    
    echo
    echo "Press Enter to continue..."
    read
}

fix_gamemode_sleep() {
    show_header
    echo "Fixing Game Mode Sleep Issues..."
    echo "================================"
    echo
    
    if [ -x "$SCRIPT_DIR/gamemode-sleep-fix-v2.sh" ]; then
        echo "Running comprehensive game mode sleep fix..."
        echo "(This will diagnose and fix the actual Game Mode sleep issues)"
        echo
        "$SCRIPT_DIR/gamemode-sleep-fix-v2.sh"
    else
        echo "Error: Game mode sleep fix v2 script not found!"
    fi
    
    echo
    echo "Press Enter to continue..."
    read
}

fix_sleep_button() {
    show_header
    echo "Advanced Sleep Button Fix..."
    echo "============================"
    echo "⚠️  WARNING: This may restart system services"
    echo
    
    echo "This is the advanced fix that may require sudo password."
    echo "Try the Game Mode Sleep Fix (option 3) first!"
    echo
    echo "Continue with advanced fix? [y/N]: "
    read -r confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        if [ -x "$SCRIPT_DIR/fix-sleep-button.sh" ]; then
            echo "Running advanced sleep button fix..."
            echo
            "$SCRIPT_DIR/fix-sleep-button.sh"
        else
            echo "Error: Advanced sleep button fix script not found!"
        fi
    else
        echo "Cancelled. Try option 3 (Game Mode Sleep Fix) instead."
    fi
    
    echo
    echo "Press Enter to continue..."
    read
}

test_sleep_button() {
    show_header
    echo "Testing Sleep Button..."
    echo "======================"
    echo
    
    echo "Checking sleep/suspend status..."
    echo
    
    # Check if suspend targets are available
    echo "🔍 Checking suspend targets:"
    if systemctl status suspend.target >/dev/null 2>&1; then
        echo "  ✅ suspend.target is available"
    else
        echo "  ❌ suspend.target is not available"
    fi
    
    if systemctl status sleep.target >/dev/null 2>&1; then
        echo "  ✅ sleep.target is available"  
    else
        echo "  ❌ sleep.target is not available"
    fi
    
    echo
    echo "🔍 Checking logind service:"
    if systemctl is-active systemd-logind >/dev/null 2>&1; then
        echo "  ✅ systemd-logind is active"
    else
        echo "  ❌ systemd-logind is not active"
    fi
    
    echo
    echo "💡 To test manually:"
    echo "  1. Try pressing the power button briefly"
    echo "  2. Or run: systemctl suspend"
    echo "  3. If that doesn't work, run the sleep button fix (option 3)"
    
    echo
    echo "Press Enter to continue..."
    read
}

view_recent_logs() {
    show_header
    echo "Recent Maintenance Logs:"
    echo "======================="
    echo
    
    if [ -d "$LOG_DIR" ]; then
        echo "Available log files (newest first):"
        echo
        ls -lt "$LOG_DIR"/*.log 2>/dev/null | head -10 | while read -r line; do
            filename=$(echo "$line" | awk '{print $9}')
            if [ -n "$filename" ]; then
                basename_file=$(basename "$filename")
                filesize=$(echo "$line" | awk '{print $5}')
                filedate=$(echo "$line" | awk '{print $6, $7, $8}')
                echo "  📄 $basename_file ($filesize bytes, $filedate)"
            fi
        done
        
        echo
        echo "To view a specific log file:"
        echo "  less $LOG_DIR/[filename]"
        echo
        echo "To view the latest log:"
        latest_log=$(ls -t "$LOG_DIR"/*.log 2>/dev/null | head -1)
        if [ -n "$latest_log" ]; then
            echo "  less \"$latest_log\""
            echo
            echo "Show latest log now? [y/N]: "
            read -r show_log
            if [[ "$show_log" =~ ^[Yy]$ ]]; then
                less "$latest_log"
            fi
        fi
    else
        echo "No maintenance logs found yet."
        echo "Run some maintenance operations to generate logs."
    fi
    
    echo
    echo "Press Enter to continue..."
    read
}

toggle_auto_maintenance() {
    show_header
    echo "Auto Maintenance Settings:"
    echo "========================="
    echo
    
    # Check current status
    monthly_enabled=$(systemctl --user is-enabled monthly-maintenance.timer 2>/dev/null || echo "disabled")
    quarterly_enabled=$(systemctl --user is-enabled quarterly-maintenance.timer 2>/dev/null || echo "disabled")
    
    echo "Current status:"
    echo "  Monthly maintenance: $monthly_enabled"
    echo "  Quarterly maintenance: $quarterly_enabled"
    echo
    
    if [ "$monthly_enabled" = "enabled" ]; then
        echo "Auto maintenance is currently ENABLED."
        echo
        echo "Disable automatic maintenance? [y/N]: "
        read -r disable_auto
        if [[ "$disable_auto" =~ ^[Yy]$ ]]; then
            echo "Disabling automatic maintenance..."
            systemctl --user disable monthly-maintenance.timer quarterly-maintenance.timer 2>/dev/null
            systemctl --user stop monthly-maintenance.timer quarterly-maintenance.timer 2>/dev/null
            echo "✅ Automatic maintenance disabled."
        fi
    else
        echo "Auto maintenance is currently DISABLED."
        echo
        echo "Enable automatic maintenance? [y/N]: "
        read -r enable_auto
        if [[ "$enable_auto" =~ ^[Yy]$ ]]; then
            echo "Enabling automatic maintenance..."
            systemctl --user enable monthly-maintenance.timer quarterly-maintenance.timer 2>/dev/null
            systemctl --user start monthly-maintenance.timer quarterly-maintenance.timer 2>/dev/null
            echo "✅ Automatic maintenance enabled."
            echo
            echo "Next scheduled runs:"
            systemctl --user list-timers maintenance-* 2>/dev/null || echo "Timer info unavailable"
        fi
    fi
    
    echo
    echo "Press Enter to continue..."
    read
}

# Main menu loop
main_loop() {
    while true; do
        show_menu
        read -r choice
        
        case "$choice" in
            1)
                run_monthly_maintenance
                ;;
            2) 
                run_quarterly_maintenance
                ;;
            3)
                fix_gamemode_sleep
                ;;
            4)
                fix_sleep_button
                ;;
            5)
                show_system_status
                ;;
            6)
                view_recent_logs
                ;;
            7)
                toggle_auto_maintenance
                ;;
            8)
                test_sleep_button
                ;;
            q|Q|quit|exit)
                clear
                echo "Thanks for using Steam Deck Maintenance!"
                echo "Your system will continue automated maintenance if enabled."
                echo
                exit 0
                ;;
            *)
                echo
                echo "Invalid option. Please try again."
                echo "Press Enter to continue..."
                read
                ;;
        esac
    done
}

# Initialize
mkdir -p "$LOG_DIR"
main_loop