#!/usr/bin/env python3
import sys
import os
import json
import subprocess
import io
from pathlib import Path

# Fix for Windows Unicode issue
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')
        sys.stderr.reconfigure(encoding='utf-8', errors='backslashreplace')
    except (AttributeError, Exception):
        try:
            sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="backslashreplace")
            sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="backslashreplace")
        except Exception:
            pass

def bootstrap():
    """Automatically installs dependencies if they are missing."""
    needed = []
    try:
        import fitz
    except ImportError:
        needed.append("pymupdf")

    if not needed:
        return

    print("--- Subass PDF Processor: Перше налаштування ---")
    print(f"Відсутні необхідні залежності: {', '.join(needed)}. Спроба встановити...")
    
    cmd = [sys.executable, "-m", "pip", "install", "--disable-pip-version-check"] + needed

    try:
        subprocess.check_call(cmd)
    except subprocess.CalledProcessError:
        try:
            print("Стандартна інсталяція не вдалася. Спроба з --break-system-packages...")
            subprocess.check_call(cmd + ["--break-system-packages"])
        except subprocess.CalledProcessError as e:
            print(f"Помилка: Не вдалося автоматично встановити залежності (Код помилки: {e.returncode}).")
            print(f"Будь ласка, спробуйте встановити вручну: {sys.executable} -m pip install {' '.join(needed)}")
            sys.exit(1)

    print("\nЗалежності успішно встановлені!\n")
    import importlib
    importlib.invalidate_caches()
    import site
    from importlib import reload
    reload(site)

# Run bootstrap before other imports
bootstrap()
import fitz  # PyMuPDF

import re

def extract_url_from_text(text):
    # More robust URL regex to find links anywhere in the string
    # Matches http://, https:// or www.
    url_pattern = r'(https?://[^\s\)\]]+|www\.[^\s\)\]]+)'
    match = re.search(url_pattern, text)
    if match:
        url = match.group(1).rstrip(r'.,;:!?)\]')
        if url.startswith("www."):
            return "https://" + url
        return url
    return None

def process_pdf(pdf_path, output_dir):
    pdf_path = Path(pdf_path)
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    try:
        # PyMuPDF supports PDF, XPS, EPUB, MOBI, FB2, CBZ, SVG, TXT, HTML and DOCX
        doc = fitz.open(pdf_path)
    except Exception as e:
        print(f"Помилка: Не вдалося відкрити файл: {e}")
        sys.exit(1)

    metadata = {
        "filename": pdf_path.name,
        "page_count": len(doc),
        "pages": []
    }
    
    for page_num in range(len(doc)):
        page = doc[page_num]
        
        # 1. Render page to Image (PNG)
        # zoom = 2 means 2x resolution (higher quality for ImGui)
        mat = fitz.Matrix(2, 2)
        pix = page.get_pixmap(matrix=mat)
        img_filename = f"page_{page_num + 1}.png"
        img_path = output_dir / img_filename
        pix.save(img_path)
        
        # 2. Extract words and coordinates
        words = page.get_text("words")
        links = [l for l in page.get_links() if l.get("kind") == fitz.LINK_URI]
        
        page_data = {
            "page_num": page_num + 1,
            "width": page.rect.width,
            "height": page.rect.height,
            "image": img_filename,
            "items": []
        }
        
        for w in words:
            text = w[4]
            word_rect = fitz.Rect(w[:4])
            item = {
                "text": text,
                "x": w[0],
                "y": w[1],
                "w": w[2] - w[0],
                "h": w[3] - w[1]
            }
            
            # Match word to native PDF links
            for link in links:
                link_rect = fitz.Rect(link["from"])
                if word_rect.intersects(link_rect):
                    item["url"] = link["uri"]
                    break
            
            # Fallback to text-based URL extraction
            if "url" not in item:
                url = extract_url_from_text(text)
                if url:
                    item["url"] = url
                    
            page_data["items"].append(item)
            
        # 3. Add explicit link blocks (for images/hotspots)
        for link in links:
            rect = fitz.Rect(link["from"])
            uri = link.get("uri")
            if uri:
                page_data["items"].append({
                    "text": uri,
                    "url": uri,
                    "x": rect.x0,
                    "y": rect.y0,
                    "w": rect.width,
                    "h": rect.height
                })
            
        metadata["pages"].append(page_data)
        
    # Save metadata to JSON
    json_path = output_dir / "metadata.json"
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(metadata, f, ensure_ascii=False, indent=2)
        
    print(f"Успішно оброблено {pdf_path.name}")
    print(f"Дані збережено у: {output_dir}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Використання: python subass_pdf_processor.py <input_pdf> <output_directory>")
        sys.exit(1)
        
    process_pdf(sys.argv[1], sys.argv[2])
