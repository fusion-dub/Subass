import sys
import urllib.request
import json
import os
import re
import zipfile
import shutil
import tempfile

# Remote version file URL (Google Drive direct download)
VERSION_URL = "https://drive.google.com/uc?export=download&id=1AXQOsOrNEls_bF1pxJ4CqWZYJwEqGEq4"

def get_latest_info():
    try:
        with urllib.request.urlopen(VERSION_URL) as response:
            data = response.read().decode('utf-8')
            try:
                return json.loads(data)
            except json.JSONDecodeError:
                info = {}
                for line in data.splitlines():
                    if '=' in line:
                        k, v = line.split('=', 1)
                        info[k.strip()] = v.strip()
                return info
    except Exception as e:
        print(f"Помилка при перевірці оновлень: {e}")
        return None

def extract_gdrive_id(url):
    """Extract file ID from various Google Drive URL formats."""
    if not url: return None
    # match /d/{id}/ or id={id}
    match = re.search(r'/d/([a-zA-Z0-9_-]{25,})', url)
    if not match:
        match = re.search(r'id=([a-zA-Z0-9_-]{25,})', url)
    return match.group(1) if match else None

def perform_update(zip_url):
    if not zip_url:
        print("Помилка: URL для завантаження не вказано.")
        return
    
    file_id = extract_gdrive_id(zip_url)
    if not file_id:
        print(f"Помилка: Не вдалося отримати ID файлу з посилання: {zip_url}")
        return

    direct_link = f"https://drive.google.com/uc?export=download&id={file_id}"
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    tmp_dir = tempfile.mkdtemp()
    zip_path = os.path.join(tmp_dir, "update.zip")

    try:
        print(f"Завантаження оновлення...")
        urllib.request.urlretrieve(direct_link, zip_path)

        # Check if it's really a zip file
        if not zipfile.is_zipfile(zip_path):
            with open(zip_path, 'r', encoding='utf-8', errors='ignore') as f:
                header = f.read(1000)
                if "Virus scan warning" in header:
                    print("ПОМИЛКА: Файл занадто великий для автоматичного завантаження (Google Drive virus scan warning).")
                    print("Будь ласка, завантажте оновлення вручну за посиланням:")
                    print(zip_url)
                    return
            print("ПОМИЛКА: Завантажений файл не є ZIP-архівом.")
            return

        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(tmp_dir)
            
        # Restore executable permissions on Unix systems (+x for scripts)
        if os.name != 'nt': # Not Windows
            for root, dirs, files in os.walk(tmp_dir):
                for f in files:
                    if f.endswith(('.py', '.sh', '.command')):
                        p = os.path.join(root, f)
                        st = os.stat(p)
                        os.chmod(p, st.st_mode | 0o111)

        # Smarter root detection: find folder containing Subass_Notes.lua
        found_root = None
        for root, dirs, files in os.walk(tmp_dir):
            if "Subass_Notes.lua" in files:
                found_root = root
                break
        
        if found_root:
            extract_root = found_root
        else:
            # Fallback: if Subass_Notes.lua not found, find ANY .lua file to anchor
            for root, dirs, files in os.walk(tmp_dir):
                if any(f.endswith(".lua") for f in files):
                    found_root = root
                    break
            if found_root:
                extract_root = found_root
            else:
                # Last resort: use the first non-hidden folder or the root itself
                items = [i for i in os.listdir(tmp_dir) if i != "update.zip" and not i.startswith(".")]
                if len(items) == 1 and os.path.isdir(os.path.join(tmp_dir, items[0])):
                    extract_root = os.path.join(tmp_dir, items[0])
                else:
                    extract_root = tmp_dir
        
        # Final item list to copy (including EVERYTHING except the update zip itself)
        # We don't skip hidden files anymore to satisfy "absolutely all"
        items_to_copy = [i for i in os.listdir(extract_root) if i != "update.zip"]

        print(f"Виявлено елементів для оновлення: {len(items_to_copy)}")
        
        # Copy files to script directory with verification and data preservation
        updated_count = 0
        for item in items_to_copy:
            s = os.path.join(extract_root, item)
            d = os.path.join(script_dir, item)
            
            try:
                if os.path.isdir(s):
                    # For directories, we handle preservation (matching installers)
                    if item == "stress":
                        # Preserve stanza_resources and logs
                        if not os.path.exists(d): os.makedirs(d)
                        for sub_item in os.listdir(s):
                            if sub_item not in ["stanza_resources", "stress_debug.log"]:
                                sub_s = os.path.join(s, sub_item)
                                sub_d = os.path.join(d, sub_item)
                                if os.path.isdir(sub_s):
                                    if os.path.exists(sub_d): shutil.rmtree(sub_d)
                                    shutil.copytree(sub_s, sub_d)
                                else:
                                    shutil.copy2(sub_s, sub_d)
                    elif item == "tts":
                        # Preserve history
                        if not os.path.exists(d): os.makedirs(d)
                        for sub_item in os.listdir(s):
                            if sub_item != "history":
                                sub_s = os.path.join(s, sub_item)
                                sub_d = os.path.join(d, sub_item)
                                if os.path.isdir(sub_s):
                                    if os.path.exists(sub_d): shutil.rmtree(sub_d)
                                    shutil.copytree(sub_s, sub_d)
                                else:
                                    shutil.copy2(sub_s, sub_d)
                    else:
                        # For other folders (overlay, dictionary, etc), replace entirely
                        if os.path.exists(d): 
                            shutil.rmtree(d)
                        shutil.copytree(s, d)
                else:
                    # For individual files (Subass_Notes.lua, subass_autoupdate.py, etc)
                    shutil.copy2(s, d)
                
                print(f"  + {item}")
                updated_count += 1
            except Exception as e:
                print(f"  - Помилка при копіюванні {item}: {e}")
        
        print(f"\nОновлення успішно завершено! Оновлено елементів: {updated_count}")
        print("\n(Будь ласка, перезапустіть скрипт якщо він це не зробив сам.)")
    except Exception as e:
        print(f"Помилка під час оновлення: {e}")
    finally:
        shutil.rmtree(tmp_dir)

def main():
    if "--update" in sys.argv:
        url = sys.argv[sys.argv.index("--update") + 1] if sys.argv.index("--update") + 1 < len(sys.argv) else None
        perform_update(url)
        return

    latest_info = get_latest_info()
    if not latest_info:
        return

    latest_title = latest_info.get("script_title") or latest_info.get("version")
    download_url = latest_info.get("path") or latest_info.get("download_url") or ""
    manual_update_val = latest_info.get("manual_update", False)
    manual_update = "true" if str(manual_update_val).lower() == "true" else "false"
    description = latest_info.get("description") or latest_info.get("changelog", "")

    if not latest_title:
        print("Не вдалося визначити версію на сервері.")
        return

    current_title = sys.argv[1] if len(sys.argv) > 1 else ""

    if latest_title != current_title:
        print("UPDATE_AVAILABLE: true")
        print(f"CURRENT_TITLE: {current_title}")
        print(f"LATEST_TITLE: {latest_title}")
        print(f"MANUAL_UPDATE: {manual_update}")
        print(f"DOWNLOAD_URL: {download_url}")
        print(f"PATH: {download_url}") # Support both names
        print("DESCRIPTION_START")
        print(description)
        print("DESCRIPTION_END")
    else:
        print("UPDATE_AVAILABLE: false")
        print(f"CURRENT_TITLE: {current_title}")

if __name__ == "__main__":
    main()
