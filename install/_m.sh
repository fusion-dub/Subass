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

check_python() {
    if command -v python3 &> /dev/null; then
        PY_VER=$(python3 --version 2>&1)
        if [[ $PY_VER == *"Python 3"* ]]; then
            return 0
        fi
    fi
    return 1
}

if ! check_python; then
    echo "\033[1;33mPython 3 not found or not working properly.\033[0m"
    
    if command -v brew &> /dev/null; then
        echo "Installing Python through Homebrew..."
        brew install python
    else
        echo "Downloading official Python installer..."
        curl -L "https://www.python.org/ftp/python/3.11.5/python-3.11.5-macos11.pkg" -o "/tmp/python_install.pkg"
        open "/tmp/python_install.pkg"
        echo "\033[1;33mPlease complete the installation in the window that opened and run the Subass installer again.\033[0m"
        exit 1
    fi
else
    echo "\033[1;32m$(python3 --version) installed.\033[0m"
fi

# 3.5 Check FFmpeg
echo "\033[1;34m>> Checking FFmpeg...\033[0m"
if ! command -v ffmpeg &> /dev/null; then
    echo "\033[1;33mFFmpeg not found.\033[0m"
    if command -v brew &> /dev/null; then
        echo "Installing FFmpeg through Homebrew..."
        brew install ffmpeg
    else
        echo "\033[1;33mFFmpeg is required for some functions (e.g., audio processing).\033[0m"
        echo "\033[1;33mPlease install Homebrew (brew.sh) or install FFmpeg manually.\033[0m"
    fi
else
    echo "\033[1;32mFFmpeg installed.\033[0m"
fi

# 4. Download Extensions
ARCH=$(uname -m)
IS_ROSETTA=$(sysctl -n sysctl.proc_translated 2>/dev/null)

if [ "$IS_ROSETTA" = "1" ]; then
    echo "\033[1;33mWARNING: Running under Rosetta emulation.\033[0m"
    echo "Architecture detected: $ARCH (emulated)"
    echo "If you use native ARM REAPER, this might install wrong extension versions."
else
    echo "Detected architecture: $ARCH"
fi

if [ "$ARCH" = "arm64" ]; then
    echo "Selected architecture Apple Silicon (ARM64)"
    PACK_URL="https://github.com/cfillion/reapack/releases/download/v1.2.6/reaper_reapack-arm64.dylib"
    SWS_URL="https://github.com/reaper-oss/sws/releases/download/v2.14.0.7/reaper_sws-arm64.dylib"
    JS_URL="https://github.com/juliansader/ReaExtensions/raw/master/js_ReaScriptAPI/v1.310/reaper_js_ReaScriptAPI64ARM.dylib"
    IMGUI_URL="https://github.com/cfillion/reaimgui/releases/latest/download/reaper_imgui-arm64.dylib"
else
    echo "Selected architecture Intel (x86_64)"
    PACK_URL="https://github.com/cfillion/reapack/releases/download/v1.2.6/reaper_reapack-x86_64.dylib"
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
            # Remove from quarantine if it's a dylib (Gatekeeper fix for M1/M2)
            if [[ "$TARGET" == *.dylib ]]; then
                xattr -d com.apple.quarantine "$TARGET" 2>/dev/null
            fi
        else
            echo "\033[1;31mFailed to download $NAME.\033[0m"
        fi
    else
        echo "\033[1;30m$NAME is already installed.\033[0m"
        # Always try to remove quarantine just in case it was stuck
        if [[ "$TARGET" == *.dylib ]]; then
            xattr -d com.apple.quarantine "$TARGET" 2>/dev/null
        fi
    fi
done

# 5. Copy Scripts
echo "\033[1;34m>> Installing Subass Notes scripts...\033[0m"

# Robust path detection: use the script's location instead of CWD
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")

SCRIPT_SOURCE="$PROJECT_ROOT/plugin/Subass_Notes.lua"
STRESS_SOURCE="$PROJECT_ROOT/plugin/stress"
OVERLAY_SOURCE="$PROJECT_ROOT/plugin/overlay/Lionzz_SubOverlay_Subass.lua"
UPDATE_SOURCE="$PROJECT_ROOT/plugin/subass_autoupdate.py"
DICTIONARY_SOURCE="$PROJECT_ROOT/plugin/dictionary"
TTS_SOURCE="$PROJECT_ROOT/plugin/tts"
STATS_SOURCE="$PROJECT_ROOT/plugin/stats"

if [ -f "$SCRIPT_SOURCE" ]; then
    cp "$SCRIPT_SOURCE" "$SCRIPTS_PATH/"
    if [ -d "$STRESS_SOURCE" ]; then
        # Preserve stanza_resources folder during update
        if [ -d "$SCRIPTS_PATH/stress" ]; then
        # Update existing stress folder, excluding stanza_resources
        rsync -av --exclude='stanza_resources' --exclude='stress_debug.log' "$STRESS_SOURCE/" "$SCRIPTS_PATH/stress/"
        else
            # First install - copy everything
            cp -R "$STRESS_SOURCE" "$SCRIPTS_PATH/"
        fi
    fi
    if [ -f "$OVERLAY_SOURCE" ]; then
        mkdir -p "$SCRIPTS_PATH/overlay"
        cp "$OVERLAY_SOURCE" "$SCRIPTS_PATH/overlay/Lionzz_SubOverlay_Subass.lua"
    fi
    if [ -f "$UPDATE_SOURCE" ]; then
        cp "$UPDATE_SOURCE" "$SCRIPTS_PATH/"
    fi
    if [ -d "$STATS_SOURCE" ]; then
        mkdir -p "$SCRIPTS_PATH/stats"
        # Copy python scripts and other files (force update)
        cp -f "$STATS_SOURCE"/!(*.json) "$SCRIPTS_PATH/stats/" 2>/dev/null || true
        # Copy everything else but don't overwrite existing files (for new json templates if any)
        # Note: zsh extended globbing might not be enabled by default in sh mode if run as sh, 
        # but this script starts with #!/bin/zsh.
        # Fallback safe copy for all files using -n (no clobber)
        cp -Rn "$STATS_SOURCE/" "$SCRIPTS_PATH/stats/"
        # Ideally we want to Force update .py files.
        # Let's iterate to be safe and cross-shell compatible if possible, 
        # or rely on zsh features since shebang is zsh.
        # Simple Logic:
        # 1. Copy everything with -n (no overwrite) - safely adds new JSONs and Code
        # 2. Copy *.py with -f (overwrite) - updates Code
        cp -f "$STATS_SOURCE"/*.py "$SCRIPTS_PATH/stats/" 2>/dev/null
    fi
    if [ -d "$DICTIONARY_SOURCE" ]; then
        cp -R "$DICTIONARY_SOURCE" "$SCRIPTS_PATH/"
    fi
    if [ -d "$TTS_SOURCE" ]; then
        # Preserve history folder during update
        if [ -d "$SCRIPTS_PATH/tts" ]; then
        # Update existing tts folder, excluding history
        rsync -av --exclude='history' "$TTS_SOURCE/" "$SCRIPTS_PATH/tts/"
        else
            # First install - copy everything
            cp -R "$TTS_SOURCE" "$SCRIPTS_PATH/"
        fi
    fi
    echo "\033[1;32mScripts copied to $SCRIPTS_PATH\033[0m"
else
    echo "\033[1;31mERROR: Could not find plugin in $PROJECT_ROOT/plugin\033[0m"
    echo "\033[1;33mPlease make sure you extracted the entire ZIP file.\033[0m"
fi

# 5.5 Verify Stress Tool Dependencies
echo "\033[1;34m>> Verifying Ukrainian Stress Tool...\033[0m"
STRESS_TOOL="$SCRIPTS_PATH/stress/ukrainian_stress_tool.py"
if [ -f "$STRESS_TOOL" ]; then
    echo "Running stress tool self-check (may install dependencies)..."
    python3 "$STRESS_TOOL" "Привіт" > /dev/null
    if [ $? -eq 0 ]; then
        echo "\033[1;32mStress tool verification successful.\033[0m"
    else
        echo "\033[1;33mWARNING: Stress tool verification failed. You may need to run it manually to check for errors.\033[0m"
    fi
else
    echo "\033[1;33mStress tool not found at $STRESS_TOOL\033[0m"
fi

# 6. Register Action and Menu Item
echo "\033[1;34m>> Registering Action and Menu Item...\033[0m"
KB_FILE="$REAPER_PATH/reaper-kb.ini"
MENU_FILE="$REAPER_PATH/reaper-menu.ini"
ACTION_ID="RS7777777777777777777777777777777777777777"
OVERLAY_ID="RS8888888888888888888888888888888888888888"
DICT_ID="RS9999999999999999999999999999999999999999"

# Python helper to update INI files
python3 <<EOF
import os, re, sys

def update_ini():
    try:
        kb_file = "$KB_FILE"
        menu_file = "$MENU_FILE"
        action_id_target = "$ACTION_ID"
        overlay_id_target = "$OVERLAY_ID"
        dict_id_target = "$DICT_ID"
        rel_path = "Subass/Subass_Notes.lua"
        overlay_rel = "Subass/overlay/Lionzz_SubOverlay_Subass.lua"
        dict_rel = "Subass/dictionary/Subass_Dictionary.lua"

        # 1. Update reaper-kb.ini
        if os.path.exists(kb_file):
            print(f"Updating {os.path.basename(kb_file)}...")
            with open(kb_file, 'r', encoding='utf-8', errors='ignore') as f:
                kb_lines = f.readlines()
            
            new_kb_lines = []
            found_main = found_overlay = found_dict = False
            
            for line in kb_lines:
                # Keep unrelated lines
                if "Subass_Notes.lua" not in line and "Lionzz_SubOverlay_Subass.lua" not in line and "Subass_Dictionary.lua" not in line:
                    new_kb_lines.append(line)
                    continue
                
                if "Subass_Notes.lua" in line and rel_path in line and not found_main:
                    m = re.search(r'SCR 4 0 (RS[0-9a-fA-F]+)', line)
                    if m: action_id_target = m.group(1)
                    new_kb_lines.append(line)
                    found_main = True
                elif "Lionzz_SubOverlay_Subass.lua" in line and overlay_rel in line and not found_overlay:
                    m = re.search(r'SCR 4 0 (RS[0-9a-fA-F]+)', line)
                    if m: overlay_id_target = m.group(1)
                    new_kb_lines.append(line)
                    found_overlay = True
                elif "Subass_Dictionary.lua" in line and dict_rel in line and not found_dict:
                    m = re.search(r'SCR 4 0 (RS[0-9a-fA-F]+)', line)
                    if m: dict_id_target = m.group(1)
                    new_kb_lines.append(line)
                    found_dict = True

            if not found_main: new_kb_lines.append(f'SCR 4 0 {action_id_target} "Custom: Subass Notes" "{rel_path}"\n')
            if not found_overlay: new_kb_lines.append(f'SCR 4 0 {overlay_id_target} "Custom: Subass SubOverlay (Lionzz)" "{overlay_rel}"\n')
            if not found_dict: new_kb_lines.append(f'SCR 4 0 {dict_id_target} "Custom: Subass Dictionary" "{dict_rel}"\n')
            
            # Use standard UTF-8 WITHOUT BOM (Python default, but being explicit)
            with open(kb_file, 'w', encoding='utf-8', newline='\n') as f:
                f.writelines(new_kb_lines)

        # 2. Update reaper-menu.ini
        print(f"Updating {os.path.basename(menu_file)}...")
        lines = []
        if os.path.exists(menu_file):
            with open(menu_file, 'r', encoding='utf-8', errors='ignore') as f:
                lines = f.readlines()
        
        content_before = []
        content_after = []
        other_items = []
        state = "before"
        
        # Regex to find section, case-insensitive and whitespace-tolerant
        section_re = re.compile(r'^\[\s*Main Extensions\s*\]$', re.IGNORECASE)
        
        for line in lines:
            clean = line.strip()
            if section_re.match(clean):
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
                if clean.startswith("item_"):
                    val = clean.split("=", 1)[1]
                    if "Subass" not in val and val not in ["0", "-1000", "-1001"]:
                         other_items.append(val)

        if state == "before":
            print("Section [Main Extensions] not found. Creating it...")
            if content_before and content_before[-1].strip() != "":
                content_before.append("\n")
            content_before.append("[Main Extensions]\n")

        final_items = other_items + ["0", f"_{action_id_target} Subass: Notes", f"_{overlay_id_target} Subass: SubOverlay (Lionzz)", f"_{dict_id_target} Subass: Dictionary", "0"]
        
        new_lines = content_before
        for i, item_val in enumerate(final_items):
            new_lines.append(f"item_{i}={item_val}\n")
        
        if content_after:
            if new_lines[-1].strip() != "": new_lines.append("\n")
            new_lines.extend(content_after)
            
        # Use standard UTF-8 WITHOUT BOM
        with open(menu_file, 'w', encoding='utf-8', newline='\n') as f:
            f.writelines(new_lines)
            
    except Exception as e:
        print(f"ERROR updating INI files: {e}")
        sys.exit(1)

update_ini()
EOF

echo "\033[1;32mRegistered in Actions and Extensions menu (cleaned up duplicates).\033[0m"

echo ""
echo "\033[1;32m================================================\033[0m"
echo "\033[1;32m   INSTALLATION COMPLETE!                       \033[0m"
echo "\033[1;32m   You can now open REAPER and find 'Subass Notes'\033[0m"
echo "\033[1;32m   directly in the 'Extensions' menu!           \033[0m"
echo "\033[1;32m================================================\033[0m"
echo ""
