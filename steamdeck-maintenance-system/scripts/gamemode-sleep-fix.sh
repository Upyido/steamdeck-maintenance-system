#!/bin/bash

# Steam Deck Game Mode Sleep Fix - Version 2
# Created: 2025-09-27
# Description: Comprehensive fix for Game Mode sleep button issues

echo "🎮 Steam Deck Game Mode Sleep Fix v2"
echo "===================================="
echo

# Check current mode
if pgrep -f "steam.*-gamepadui" >/dev/null 2>&1; then
    echo "✅ Currently in Game Mode"
    in_game_mode=true
elif pgrep -f "gamescope-session" >/dev/null 2>&1; then
    echo "✅ Gamescope session running (transitioning to Game Mode)"
    in_game_mode=true
else
    echo "📱 Currently in Desktop Mode"
    echo "💡 For Game Mode sleep issues, you should be in Game Mode"
    in_game_mode=false
fi

echo
echo "🔍 Comprehensive Game Mode Sleep Diagnosis..."
echo "============================================="

# Track issues found
issues_found=0
fixes_applied=0

# 1. Check basic suspend capability
echo
echo "1. System Suspend Capability:"
if systemctl --dry-run suspend >/dev/null 2>&1; then
    echo "   ✅ System suspend capability: OK"
else
    echo "   ❌ System suspend capability: FAILED"
    echo "   💡 This is a critical system issue - consider rebooting"
    ((issues_found++))
fi

# 2. Check systemd-logind (critical for all power management)
echo
echo "2. Power Management Service:"
if systemctl is-active systemd-logind >/dev/null 2>&1; then
    echo "   ✅ systemd-logind: RUNNING"
else
    echo "   ❌ systemd-logind: NOT RUNNING"
    echo "   💡 This will prevent all suspend functionality"
    ((issues_found++))
fi

# 3. Check gamescope-session (critical for Game Mode)
echo
echo "3. Game Mode Session Service:"
if systemctl --user is-active gamescope-session.service >/dev/null 2>&1; then
    echo "   ✅ gamescope-session: RUNNING"
    gamescope_running=true
else
    echo "   ❌ gamescope-session: NOT RUNNING"
    echo "   💡 This is required for Game Mode power button handling"
    gamescope_running=false
    ((issues_found++))
fi

# 4. Check steamos-powerbuttond (handles Game Mode power events)
echo
echo "4. Game Mode Power Button Handler:"
if systemctl --user is-active steamos-powerbuttond.service >/dev/null 2>&1; then
    echo "   ✅ steamos-powerbuttond: RUNNING"
    powerbuttond_running=true
else
    echo "   ❌ steamos-powerbuttond: NOT RUNNING"
    if [ "$gamescope_running" = false ]; then
        echo "   💡 Cannot start without gamescope-session"
    else
        echo "   💡 Should be running with gamescope-session"
    fi
    powerbuttond_running=false
    ((issues_found++))
fi

# 5. Check Steam processes
echo
echo "5. Steam Processes:"
steam_running=false
gamepadui_running=false

if pgrep steam >/dev/null 2>&1; then
    echo "   ✅ Steam client: RUNNING"
    steam_running=true
else
    echo "   ❌ Steam client: NOT RUNNING"
    ((issues_found++))
fi

if pgrep -f "steam.*-gamepadui" >/dev/null 2>&1; then
    echo "   ✅ Steam Game Mode UI: RUNNING"
    gamepadui_running=true
else
    echo "   ⚠️  Steam Game Mode UI: NOT RUNNING"
    if [ "$in_game_mode" = true ]; then
        echo "   💡 This indicates you're not fully in Game Mode"
        ((issues_found++))
    fi
fi

# 6. Check power inhibitors
echo
echo "6. Power Management Inhibitors:"
inhibitors=$(systemd-inhibit --list 2>/dev/null | grep -E "handle-power-key|handle-suspend-key")
if [ -n "$inhibitors" ]; then
    echo "   ℹ️  Power button handlers detected:"
    echo "$inhibitors" | while IFS= read -r line; do
        if echo "$line" | grep -q "PowerDevil"; then
            echo "   ✅ PowerDevil (Desktop Mode): Active"
        elif echo "$line" | grep -q "steam"; then
            echo "   ✅ Steam (Game Mode): Active"
        else
            echo "   ℹ️  Other: $line"
        fi
    done
else
    echo "   ⚠️  No power button handlers detected"
    echo "   💡 This may indicate a power management issue"
    ((issues_found++))
fi

# 7. Check sleep configuration
echo
echo "7. Sleep Configuration:"
if [ -f "/sys/power/mem_sleep" ]; then
    sleep_modes=$(cat /sys/power/mem_sleep 2>/dev/null)
    echo "   📋 Available modes: $sleep_modes"
    
    if echo "$sleep_modes" | grep -q "\\[deep\\]"; then
        echo "   ✅ Deep sleep: ENABLED (good for battery)"
    elif echo "$sleep_modes" | grep -q "\\[s2idle\\]"; then
        echo "   ⚠️  S2idle sleep: ENABLED (less efficient)"
    else
        echo "   ⚠️  Unknown sleep mode configuration"
    fi
else
    echo "   ❌ Cannot read sleep configuration"
    ((issues_found++))
fi

echo
echo "=========================================="
echo "📊 DIAGNOSIS SUMMARY:"
echo "   Issues found: $issues_found"
echo "=========================================="

# Start applying fixes
if [ "$issues_found" -gt 0 ]; then
    echo
    echo "🔧 APPLYING FIXES:"
    echo "=================="
    
    # Fix 1: Restart user services (safe)
    echo
    echo "Fix 1: Refreshing user services..."
    systemctl --user daemon-reload
    echo "   ✅ User service daemon reloaded"
    ((fixes_applied++))
    
    # Fix 2: Try to start gamescope session if we're supposed to be in Game Mode
    if [ "$gamescope_running" = false ] && [ "$in_game_mode" = true ]; then
        echo
        echo "Fix 2: Attempting to start gamescope session..."
        echo "   💡 Note: You may need to switch to Game Mode manually"
        echo "   💡 Go to Steam Menu → Power → Switch to Game Mode"
        # Don't actually try to start it since it has RefuseManualStart=yes
        echo "   ℹ️  This requires switching to Game Mode through Steam"
    fi
    
    # Fix 3: Try to start steamos-powerbuttond if gamescope is running
    if [ "$gamescope_running" = true ] && [ "$powerbuttond_running" = false ]; then
        echo
        echo "Fix 3: Starting Game Mode power button handler..."
        if systemctl --user start steamos-powerbuttond.service 2>/dev/null; then
            echo "   ✅ steamos-powerbuttond started successfully"
            ((fixes_applied++))
        else
            echo "   ⚠️  Could not start steamos-powerbuttond"
            echo "   💡 Try switching to Desktop Mode and back to Game Mode"
        fi
    fi
    
    # Fix 4: Steam client restart (if needed and safe to do)
    if [ "$steam_running" = false ]; then
        echo
        echo "Fix 4: Steam client needs to be running for Game Mode..."
        echo "   💡 Start Steam manually or restart your Steam Deck"
    elif [ "$gamepadui_running" = false ] && [ "$in_game_mode" = true ]; then
        echo
        echo "Fix 4: Game Mode UI not fully active..."
        echo "   💡 Try: Steam Menu → Power → Switch to Game Mode"
        echo "   💡 Or restart Steam Deck to ensure clean Game Mode boot"
    fi
    
    echo
    echo "🔄 Applying final refresh..."
    sleep 2
    
    # Final check
    echo
    echo "📋 POST-FIX STATUS:"
    echo "=================="
    
    if systemctl --user is-active steamos-powerbuttond.service >/dev/null 2>&1; then
        echo "   ✅ Game Mode power handler: NOW RUNNING"
    else
        echo "   ⚠️  Game Mode power handler: Still not running"
    fi
    
    if systemctl --user is-active gamescope-session.service >/dev/null 2>&1; then
        echo "   ✅ Gamescope session: RUNNING"
    else
        echo "   ⚠️  Gamescope session: Still not running"
    fi
    
    echo
    echo "   Fixes applied: $fixes_applied"
else
    echo "✅ No issues detected - Game Mode sleep should be working!"
fi

echo
echo "=========================================="
echo "💡 TESTING INSTRUCTIONS:"
echo "========================"

if [ "$in_game_mode" = true ]; then
    echo
    echo "🎮 In Game Mode - Test These Methods:"
    echo
    echo "Method 1: Power Menu"
    echo "   1. Press power button briefly (don't hold)"
    echo "   2. Steam power menu should appear"
    echo "   3. Select 'Sleep' option"
    echo
    echo "Method 2: Quick Sleep"  
    echo "   1. Hold Steam button + Power button together"
    echo "   2. System should sleep immediately"
    echo
    echo "Method 3: Steam Menu"
    echo "   1. Press Steam button"
    echo "   2. Go to Power → Sleep"
else
    echo
    echo "📱 You're in Desktop Mode. To test Game Mode sleep:"
    echo
    echo "1. Switch to Game Mode:"
    echo "   • Steam Menu → Power → Switch to Game Mode"
    echo "   • Or reboot and boot into Game Mode"
    echo
    echo "2. Then test the power button methods above"
fi

echo
echo "🚨 IF STILL NOT WORKING:"
echo "======================="
echo
echo "• REBOOT your Steam Deck completely"
echo "• Make sure you boot into Game Mode (not Desktop Mode)"
echo "• Check Steam Settings → System → Enable Developer Mode"  
echo "• Try a different game to ensure Steam is fully loaded"
echo "• If the issue persists, it may be a hardware problem"

echo
echo "🔧 ADVANCED TROUBLESHOOTING:"
echo "=========================="
echo
echo "• Check recent Steam Deck updates in Settings"
echo "• Try: steamos-session-select gamescope"
echo "• Reset Steam: Steam → Settings → System → Reset Steam Deck"
echo "• Contact Steam Support if hardware-related"

echo
echo "📄 This diagnosis will be logged for future reference"

# Create a simple log
log_file="$HOME/.local/share/maintenance-logs/gamemode-sleep-diagnosis-$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$(dirname "$log_file")"
{
    echo "Game Mode Sleep Diagnosis - $(date)"
    echo "Issues found: $issues_found"
    echo "Fixes applied: $fixes_applied"
    echo "In Game Mode: $in_game_mode"
    echo "Gamescope running: $gamescope_running"
    echo "Power button daemon running: $powerbuttond_running"
    echo "Steam running: $steam_running"
    echo "Game UI running: $gamepadui_running"
} > "$log_file"

echo "📄 Log saved: $log_file"

echo
echo "Press Enter to continue..."
read