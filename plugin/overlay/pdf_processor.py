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
    try:
        import fitz
    except ImportError:
        print("--- Subass PDF Processor: Перше налаштування ---")
        print("Відсутні необхідні залежності. Спроба встановити 'pymupdf'...")
        
        packages = ["pymupdf"]
        cmd = [sys.executable, "-m", "pip", "install", "--disable-pip-version-check"] + packages

        try:
            subprocess.check_call(cmd)
        except subprocess.CalledProcessError:
            try:
                print("Стандартна інсталяція не вдалася. Спроба з --break-system-packages...")
                subprocess.check_call(cmd + ["--break-system-packages"])
            except subprocess.CalledProcessError as e:
                print(f"Помилка: Не вдалося автоматично встановити залежності (Код помилки: {e.returncode}).")
                print(f"Будь ласка, спробуйте встановити вручну: {sys.executable} -m pip install pymupdf")
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

def process_pdf(pdf_path, output_dir):
    pdf_path = Path(pdf_path)
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    try:
        doc = fitz.open(pdf_path)
    except Exception as e:
        print(f"Помилка: Не вдалося відкрити PDF файл: {e}")
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
        
        page_data = {
            "page_num": page_num + 1,
            "width": page.rect.width,
            "height": page.rect.height,
            "image": img_filename,
            "items": []
        }
        
        for w in words:
            page_data["items"].append({
                "text": w[4],
                "x": w[0],
                "y": w[1],
                "w": w[2] - w[0],
                "h": w[3] - w[1]
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
        print("Використання: python pdf_processor.py <input_pdf> <output_directory>")
        sys.exit(1)
        
    process_pdf(sys.argv[1], sys.argv[2])
