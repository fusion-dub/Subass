#!/bin/bash
# Ukrainian Stress Tool Launcher for macOS

# Get the directory where this script is located
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change to that directory
cd "$DIR"

clear
echo "================================================"
echo "  🇺🇦 Ukrainian Stress Tool"
echo "================================================"
echo ""

# Run the Python script with GUI
python3 ukrainian_stress_tool.py

# Terminal will be closed automatically by the Python script's exit logic
