#!/bin/bash

# Steam Deck Maintenance System - Installation Script
# Creates: ~/.local/bin/ scripts and desktop entries

echo "🛠️  Installing Steam Deck Maintenance System..."
echo "================================================"

# Create directories
mkdir -p ~/.local/bin
mkdir -p ~/.local/share/applications
mkdir -p ~/.local/share/maintenance-logs

# Install scripts
echo "📦 Installing scripts..."
cp scripts/maintenance-tui.sh ~/.local/bin/maintenance-simple-tui.sh
cp scripts/monthly-maintenance.sh ~/.local/bin/monthly-maintenance-safe.sh
cp scripts/gamemode-sleep-fix.sh ~/.local/bin/gamemode-sleep-fix-v2.sh
cp scripts/advanced-sleep-fix.sh ~/.local/bin/fix-sleep-button.sh

# Make executable
chmod +x ~/.local/bin/maintenance-simple-tui.sh
chmod +x ~/.local/bin/monthly-maintenance-safe.sh
chmod +x ~/.local/bin/gamemode-sleep-fix-v2.sh
chmod +x ~/.local/bin/fix-sleep-button.sh

echo "✅ Scripts installed to ~/.local/bin/"

# Install desktop entries (optional)
echo "📱 Installing desktop entries..."
cp desktop-entries/deck-maintenance.desktop ~/.local/share/applications/
cp desktop-entries/deck-sleep-fix.desktop ~/.local/share/applications/

# Fix paths in desktop entries
sed -i "s|/home/deck/.local/bin/maintenance-simple-tui.sh|$HOME/.local/bin/maintenance-simple-tui.sh|g" ~/.local/share/applications/deck-maintenance.desktop
sed -i "s|/home/deck/.local/bin/gamemode-sleep-fix-v2.sh|$HOME/.local/bin/gamemode-sleep-fix-v2.sh|g" ~/.local/share/applications/deck-sleep-fix.desktop

# Make desktop entries executable
chmod +x ~/.local/share/applications/deck-maintenance.desktop
chmod +x ~/.local/share/applications/deck-sleep-fix.desktop

# Update desktop database
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database ~/.local/share/applications/ 2>/dev/null || true
fi

echo "✅ Desktop entries installed"

# Copy documentation
echo "📚 Installing documentation..."
mkdir -p ~/.local/share/steamdeck-maintenance/
cp README.md ~/.local/share/steamdeck-maintenance/
cp docs/* ~/.local/share/steamdeck-maintenance/ 2>/dev/null || true

echo
echo "🎉 Installation Complete!"
echo "=========================="
echo
echo "🚀 Launch Options:"
echo "1. From Applications Menu: 'Steam Deck Maintenance'"
echo "2. From Terminal: ~/.local/bin/maintenance-simple-tui.sh"
echo "3. Game Mode Sleep Fix: ~/.local/bin/gamemode-sleep-fix-v2.sh"
echo
echo "📁 Files installed:"
echo "   Scripts: ~/.local/bin/"
echo "   Desktop entries: ~/.local/share/applications/"
echo "   Logs: ~/.local/share/maintenance-logs/"
echo "   Docs: ~/.local/share/steamdeck-maintenance/"
echo
echo "💡 To uninstall, run: ./uninstall.sh"