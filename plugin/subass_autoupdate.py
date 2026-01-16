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
        urllib.request.urlretrieve(direct_link, zip_path)

        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(tmp_dir)

        # Handle potential nested folder in zip
        # If there's only one folder, we go inside it
        extract_root = tmp_dir
        items = [i for i in os.listdir(tmp_dir) if i != "update.zip" and not i.startswith(".")]
        if len(items) == 1 and os.path.isdir(os.path.join(tmp_dir, items[0])):
            extract_root = os.path.join(tmp_dir, items[0])
            items = os.listdir(extract_root)

        # Copy files to script directory
        for item in items:
            s = os.path.join(extract_root, item)
            d = os.path.join(script_dir, item)
            if os.path.isdir(s):
                if os.path.exists(d): shutil.rmtree(d)
                shutil.copytree(s, d)
            else:
                shutil.copy2(s, d)
        
        print("\nОновлення успішно завершено!\n\n(Будь ласка, перезапустіть скрипт якщо він це не зробив сам.)")
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
