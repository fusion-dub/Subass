#!/bin/bash
# Ukrainian Stress Tool Launcher for macOS

# Get the directory where this script is located
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change to that directory
cd "$DIR"

echo "================================================"
echo "  🇺🇦 Ukrainian Stress Tool"
echo "================================================"
echo ""

# Run the Python script with GUI
python3 ukrainian_stress_tool.py

# This will run until user presses Ctrl+C
echo ""
echo "Сервер зупинено."
echo "Натисніть Enter для закриття вікна..."
read
