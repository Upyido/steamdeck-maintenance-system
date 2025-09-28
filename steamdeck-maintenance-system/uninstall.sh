#!/bin/bash

# Steam Deck Maintenance System - Uninstall Script

echo "🗑️  Uninstalling Steam Deck Maintenance System..."
echo "================================================="

# Remove scripts
echo "📦 Removing scripts..."
rm -f ~/.local/bin/maintenance-simple-tui.sh
rm -f ~/.local/bin/monthly-maintenance-safe.sh
rm -f ~/.local/bin/gamemode-sleep-fix-v2.sh
rm -f ~/.local/bin/fix-sleep-button.sh

echo "✅ Scripts removed from ~/.local/bin/"

# Remove desktop entries
echo "📱 Removing desktop entries..."
rm -f ~/.local/share/applications/deck-maintenance.desktop
rm -f ~/.local/share/applications/deck-maintenance-tui.desktop
rm -f ~/.local/share/applications/deck-sleep-fix.desktop
rm -f ~/.local/share/applications/maintenance-helper.desktop
rm -f ~/.local/share/applications/maintenance-terminal.desktop

# Update desktop database
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database ~/.local/share/applications/ 2>/dev/null || true
fi

echo "✅ Desktop entries removed"

# Ask about logs and documentation
echo
echo "🗂️  Optional cleanup:"
echo "   Maintenance logs: ~/.local/share/maintenance-logs/"
echo "   Documentation: ~/.local/share/steamdeck-maintenance/"
echo
echo "Remove logs and documentation? [y/N]: "
read -r remove_data

if [[ "$remove_data" =~ ^[Yy]$ ]]; then
    rm -rf ~/.local/share/maintenance-logs/
    rm -rf ~/.local/share/steamdeck-maintenance/
    echo "✅ Logs and documentation removed"
else
    echo "ℹ️  Logs and documentation kept"
fi

echo
echo "🎉 Uninstall Complete!"
echo "====================="
echo
echo "The Steam Deck Maintenance System has been removed."
echo "Thank you for using it!"