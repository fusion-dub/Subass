#!/bin/zsh

# Subass Notes Installer for macOS
# This script automates the installation of Python and REAPER extensions.

# Use bold cyan for headers
echo "\033[1;36m================================================\033[0m"
echo "\033[1;36m   Subass Notes - Automated Installer (macOS)   \033[0m"
echo "\033[1;36m================================================\033[0m"
echo ""

# 1. Check if REAPER is running
if pgrep -x "REAPER" > /dev/null; then
    echo "\033[1;31mERROR: REAPER is currently running.\033[0m"
    echo "\033[1;33mPlease close REAPER and run this installer again.\033[0m"
    exit 1
fi

# 2. Paths
REAPER_PATH="$HOME/Library/Application Support/REAPER"
if [ ! -d "$REAPER_PATH" ]; then
    echo "\033[1;31mERROR: Could not find REAPER folder at $REAPER_PATH\033[0m"
    exit 1
fi

USER_PLUGINS="$REAPER_PATH/UserPlugins"
SCRIPTS_PATH="$REAPER_PATH/Scripts/Subass"
mkdir -p "$USER_PLUGINS"
mkdir -p "$SCRIPTS_PATH"

# 3. Check Python 3
echo "\033[1;34m>> Checking Python 3...\033[0m"
if ! command -v python3 &> /dev/null; then
    echo "\033[1;33mPython 3 не знайдено.\033[0m"
    
    if command -v brew &> /dev/null; then
        echo "Знайдено Homebrew. Встановлюю Python..."
        brew install python
    else
        echo "Завантажую офіційний інсталятор Python..."
        curl -L "https://www.python.org/ftp/python/3.11.5/python-3.11.5-macos11.pkg" -o "/tmp/python_install.pkg"
        open "/tmp/python_install.pkg"
        echo "\033[1;33mБудь ласка, завершіть встановлення у вікні, що відкрилося, і запустіть інсталятор Subass знову.\033[0m"
        exit 1
    fi
else
    echo "\033[1;32mPython 3 встановлено.\033[0m"
fi

# 4. Download Extensions
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    echo "Вибрано архітектуру Apple Silicon (ARM64)"
    PACK_URL="https://reapack.com/download/reaper_reapack-arm64.dylib"
    SWS_URL="https://github.com/reaper-oss/sws/releases/download/v2.14.0.7/reaper_sws-arm64.dylib"
    JS_URL="https://github.com/juliansader/ReaExtensions/raw/master/js_ReaScriptAPI/v1.310/reaper_js_ReaScriptAPI64ARM.dylib"
    IMGUI_URL="https://github.com/cfillion/reaimgui/releases/latest/download/reaper_imgui-arm64.dylib"
else
    echo "Вибрано архітектуру Intel (x86_64)"
    PACK_URL="https://reapack.com/download/reaper_reapack-x86_64.dylib"
    SWS_URL="https://github.com/reaper-oss/sws/releases/download/v2.14.0.7/reaper_sws-x86_64.dylib"
    JS_URL="https://github.com/juliansader/ReaExtensions/raw/master/js_ReaScriptAPI/v1.310/reaper_js_ReaScriptAPI64.dylib"
    IMGUI_URL="https://github.com/cfillion/reaimgui/releases/latest/download/reaper_imgui-x86_64.dylib"
fi

declare -A EXTS=(
    ["ReaPack"]="$PACK_URL"
    ["SWS Extension"]="$SWS_URL"
    ["js_ReaScriptAPI"]="$JS_URL"
    ["ReaImGui"]="$IMGUI_URL"
)

for NAME in "${(@k)EXTS}"; do
    URL=${EXTS[$NAME]}
    FILE=$(basename "$URL")
    TARGET="$USER_PLUGINS/$FILE"
    
    if [ ! -f "$TARGET" ]; then
        echo "\033[1;34m>> Downloading $NAME...\033[0m"
        curl -L "$URL" -o "$TARGET"
        if [ $? -eq 0 ]; then
            echo "\033[1;32m$NAME installed.\033[0m"
        else
            echo "\033[1;31mFailed to download $NAME.\033[0m"
        fi
    else
        echo "\033[1;30m$NAME is already installed.\033[0m"
    fi
done

# 5. Copy Scripts
echo "\033[1;34m>> Installing Subass Notes scripts...\033[0m"
SCRIPT_FILE="plugin/Subass_Notes.lua"
STRESS_FOLDER="plugin/stress"
OVERLAY_FILE="plugin/overlay/Lionzz_SubOverlay_Subass.lua"

if [ -f "$SCRIPT_FILE" ]; then
    cp "$SCRIPT_FILE" "$SCRIPTS_PATH/"
    if [ -d "$STRESS_FOLDER" ]; then
        cp -R "$STRESS_FOLDER" "$SCRIPTS_PATH/"
    fi
    if [ -f "$OVERLAY_FILE" ]; then
        mkdir -p "$SCRIPTS_PATH/overlay"
        cp "$OVERLAY_FILE" "$SCRIPTS_PATH/overlay/Lionzz_SubOverlay_Subass.lua"
    fi
    echo "\033[1;32mScripts copied to $SCRIPTS_PATH\033[0m"
else
    echo "\033[1;31mERROR: Could not find $SCRIPT_FILE in current directory.\033[0m"
fi

# 6. Register Action and Menu Item
echo "\033[1;34m>> Registering Action and Menu Item...\033[0m"
KB_FILE="$REAPER_PATH/reaper-kb.ini"
MENU_FILE="$REAPER_PATH/reaper-menu.ini"
ACTION_ID="RS77777777777777777777777777777777"
OVERLAY_ID="RS88888888888888888888888888888888"

# Python helper to update INI files
python3 <<EOF
import os, re

kb_file = "$KB_FILE"
menu_file = "$MENU_FILE"
action_id_target = "$ACTION_ID"
overlay_id_target = "$OVERLAY_ID"
rel_path = "Subass/Subass_Notes.lua"
overlay_rel = "Subass/overlay/Lionzz_SubOverlay_Subass.lua"

# 1. Update reaper-kb.ini - Clean up old paths and duplicates
if os.path.exists(kb_file):
    with open(kb_file, 'r', encoding='utf-8', errors='ignore') as f:
        kb_lines = f.readlines()
    
    new_kb_lines = []
    found_main = False
    found_overlay = False
    
    for line in kb_lines:
        # Keep unrelated lines
        if "Subass_Notes.lua" not in line and "Lionzz_SubOverlay_Subass.lua" not in line:
            new_kb_lines.append(line)
            continue
        
        # If it's our main script, only keep the ONE with the relative path we want
        if "Subass_Notes.lua" in line:
            if rel_path in line and not found_main:
                # Extract the actual ID REAPER might have assigned
                m = re.search(r'SCR 4 0 (RS[0-9a-f]+)', line)
                if m: action_id_target = m.group(1)
                new_kb_lines.append(line)
                found_main = True
        
        # If it's our overlay script
        if "Lionzz_SubOverlay_Subass.lua" in line:
            if overlay_rel in line and not found_overlay:
                m = re.search(r'SCR 4 0 (RS[0-9a-f]+)', line)
                if m: overlay_id_target = m.group(1)
                new_kb_lines.append(line)
                found_overlay = True

    if not found_main:
        new_kb_lines.append(f'SCR 4 0 {action_id_target} "Custom: Subass Notes" "{rel_path}"\n')
    if not found_overlay:
        new_kb_lines.append(f'SCR 4 0 {overlay_id_target} "Custom: Subass Overlay" "{overlay_rel}"\n')

    with open(kb_file, 'w', encoding='utf-8') as f:
        f.writelines(new_kb_lines)

# 2. Update reaper-menu.ini - Reconstruct [Main Extensions] section
if os.path.exists(menu_file):
    with open(menu_file, 'r', encoding='utf-8', errors='ignore') as f:
        lines = f.readlines()
    
    new_lines = []
    in_section = False
    other_items = [] # Non-Subass items in this section
    
    # 1. Parse entire file and extract non-Subass items from [Main Extensions]
    content_before = []
    content_after = []
    state = "before"
    
    for line in lines:
        clean = line.strip()
        if clean == "[Main Extensions]":
            state = "in"
            content_before.append(line)
            continue
        
        if state == "in" and clean.startswith("["):
            state = "after"
        
        if state == "before":
            content_before.append(line)
        elif state == "after":
            content_after.append(line)
        elif state == "in":
            # We are inside [Main Extensions]. Collect items that are NOT Subass and NOT our separators
            # ( separators are item_N=0 )
            if clean.startswith("item_"):
                val = clean.split("=", 1)[1]
                # Filter out: Subass name, 0 (our separator), -1000/-1001 (our submenus)
                if "Subass" not in val and val != "0" and val != "-1000" and val != "-1001":
                     other_items.append(val)

    # 2. Build the new section items
    final_items = other_items + ["0", f"_{action_id_target} Subass: Notes", f"_{overlay_id_target} Subass: Overlay", "0"]
    
    # 3. Assemble the file
    new_lines = content_before
    for i, item_val in enumerate(final_items):
        new_lines.append(f"item_{i}={item_val}\n")
    
    # Add a blank line if missing before next section
    if content_after and not content_after[0].strip() == "":
        new_lines.append("\n")
        
    new_lines.extend(content_after)

    with open(menu_file, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
EOF

echo "\033[1;32mRegistered in Actions and Extensions menu (cleaned up duplicates).\033[0m"

echo ""
echo "\033[1;32m================================================\033[0m"
echo "\033[1;32m   INSTALLATION COMPLETE!                       \033[0m"
echo "\033[1;32m   You can now open REAPER and find 'Subass Notes'\033[0m"
echo "\033[1;32m   directly in the 'Extensions' menu!           \033[0m"
echo "\033[1;32m================================================\033[0m"
echo ""
