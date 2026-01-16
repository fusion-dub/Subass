#!/usr/bin/env python3
import warnings

# Suppress noisy warnings
warnings.filterwarnings("ignore", message="TypedStorage is deprecated")
warnings.filterwarnings("ignore", message="urllib3 v2 only supports OpenSSL")

import sys
import argparse
import re
import os
import subprocess
import io

# Fix for Windows UnicodeEncodeError when printing Ukrainian characters to console
if sys.platform == "win32":
    try:
        # Python 3.7+ approach for reconfiguring standard streams
        sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')
        sys.stderr.reconfigure(encoding='utf-8', errors='backslashreplace')
    except (AttributeError, Exception):
        # Fallback for older Python versions or unexpected errors
        try:
            sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="backslashreplace")
            sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="backslashreplace")
        except Exception:
            pass


# Python 3.9+ is required for ukrainian-word-stress internal usage of importlib.resources
if sys.version_info < (3, 9):
    print("--- ERROR: PYTHON_VERSION_TOO_OLD ---")
    print(f"Python 3.9 or higher is required. Your current version: {sys.version}")
    print("\nTo fix this on Windows, run this in PowerShell:")
    print("winget install -e --id Python.Python.3.11")
    print("\nTo fix this on macOS, run this in Terminal:")
    print("brew install python@3.11")
    print("\nAfter installing, restart your terminal or REAPER.")
    sys.exit(1)


# Set stanza resources directory to local plugin folder BEFORE any imports
stanza_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "stanza_resources")
if not os.path.exists(stanza_dir):
    os.makedirs(stanza_dir, exist_ok=True)
os.environ["STANZA_RESOURCES_DIR"] = stanza_dir


def bootstrap():
    """Automatically installs dependencies if they are missing."""
    try:
        import ukrainian_word_stress
    except ImportError:
        print("--- Ukrainian Word Stress Tool: First Time Setup ---")
        print("Dependencies missing. Attempting to install 'ukrainian-word-stress'...")

        packages = ["ukrainian-word-stress"]

        print(f"Using Python: {sys.executable}")
        
        # Base install command
        cmd = [
            sys.executable,
            "-m",
            "pip",
            "install",
            "--disable-pip-version-check",
        ] + packages

        try:
            # Check if pip is available
            subprocess.check_call([sys.executable, "-m", "pip", "--version"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except subprocess.CalledProcessError:
            print("--- ERROR: PIP_MISSING ---")
            print("Python install does not have 'pip'.")
            if sys.platform == "win32":
                print("Try: python -m ensurepip --default-pip")
            else:
                print("Try: python3 -m ensurepip --default-pip")
            return False

        try:
            # Try normal install
            print(f"Running: {' '.join(cmd)}")
            subprocess.check_call(cmd)
        except subprocess.CalledProcessError:
            # Try with --break-system-packages for macOS/Linux system Python
            try:
                print("Standard install failed. Trying with --break-system-packages...")
                subprocess.check_call(cmd + ["--break-system-packages"])
            except subprocess.CalledProcessError as e:
                print("--- ERROR: DEPENDENCY_INSTALL_FAILED ---")
                print(f"\nError: Could not install dependencies automatically (Exit Code: {e.returncode}).")
                print(
                    f"Please try running manually: {sys.executable} -m pip install ukrainian-word-stress"
                )
                return False

        print("\nDependencies installed successfully!")
        print(
            "Please wait while the AI models are being initialized (this may take a minute during the first run)..."
        )

        # Invalidate caches so the new package can be found
        import importlib

        importlib.invalidate_caches()

        # Also refresh site-packages for the current process
        import site
        from importlib import reload

        reload(site)

        # Ensure we can import it now
        import ukrainian_word_stress

        return True
    return False


# Run bootstrap before other imports from the library
bootstrap()

from ukrainian_word_stress import Stressifier, StressSymbol

# Internal stressifier instance to avoid re-creation

_stressifier = None


def get_stressifier():
    global _stressifier
    if _stressifier is None:
        try:
            _stressifier = Stressifier(stress_symbol=StressSymbol.CombiningAcuteAccent)
        except PermissionError as e:
            print("--- ERROR: STANZA_PERMISSION_DENIED ---")
            print(f"Permission error accessing stanza resources: {e}")
            print(f"\nThe AI models folder has incorrect permissions.")
            print(f"Location: {os.environ.get('STANZA_RESOURCES_DIR', 'unknown')}")
            print("\nTo fix this:")
            print("1. Close REAPER completely")
            print("2. Delete the 'stanza_resources' folder manually:")
            print(f"   {os.environ.get('STANZA_RESOURCES_DIR', 'unknown')}")
            print("3. Restart REAPER and try again")
            print("\nThe tool will attempt to delete it automatically now...")
            
            # Try to delete the corrupted folder
            stanza_dir = os.environ.get('STANZA_RESOURCES_DIR')
            if stanza_dir and os.path.exists(stanza_dir):
                import shutil
                try:
                    shutil.rmtree(stanza_dir)
                    print(f"✓ Successfully deleted {stanza_dir}")
                    print("Please restart REAPER and try again.")
                except Exception as cleanup_err:
                    print(f"✗ Could not delete automatically: {cleanup_err}")
                    print("Please delete the folder manually as described above.")
            
            sys.exit(1)
    return _stressifier


def add_stress(text):
    """
    Main function: takes a string and returns it with Ukrainian stress marks.
    """
    if not text or not text.strip():
        return text
    stressifier = get_stressifier()
    return stressifier(text)


def process_srt(content):
    """Processes SRT file content and adds stress marks to the subtitle text."""
    lines = content.splitlines()
    processed_lines = []

    # SRT state: 0=Index, 1=Time, 2=Text
    state = 0
    for line in lines:
        if not line.strip():
            processed_lines.append(line)
            state = 0
            continue

        if state == 0:
            if line.strip().isdigit():
                processed_lines.append(line)
                state = 1
            else:
                processed_lines.append(add_stress(line))
        elif state == 1:
            if "-->" in line:
                processed_lines.append(line)
                state = 2
            else:
                processed_lines.append(add_stress(line))
        elif state == 2:
            processed_lines.append(add_stress(line))

    return "\n".join(processed_lines)


def process_ass(content):
    """Processes ASS file content and adds stress marks to the Dialogue lines."""
    lines = content.splitlines()
    processed_lines = []

    for line in lines:
        if line.startswith("Dialogue:"):
            # ASS Dialogue format: Dialogue: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
            parts = line.split(",", 9)
            if len(parts) > 9:
                prefix = ",".join(parts[:9])
                text = parts[9]

                # Handle ASS tags like {\pos(100,100)}
                text_parts = re.split(r"(\{.*?\})", text)
                processed_text_parts = []
                for p in text_parts:
                    if p.startswith("{") and p.endswith("}"):
                        processed_text_parts.append(p)
                    else:
                        processed_text_parts.append(add_stress(p))

                processed_lines.append(f"{prefix},{''.join(processed_text_parts)}")
            else:
                processed_lines.append(line)
        else:
            processed_lines.append(line)

    return "\n".join(processed_lines)


def main():
    parser = argparse.ArgumentParser(
        description="Add Ukrainian word stress marks to text or subtitle files."
    )
    parser.add_argument("input", help="The input string, or path to a .srt/.ass file.")
    parser.add_argument(
        "-o", "--output", help="Path to the output file (optional for strings)."
    )

    args = parser.parse_args()
    input_val = args.input

    # Check if input is a file
    if os.path.isfile(input_val):
        ext = os.path.splitext(input_val)[1].lower()
        with open(input_val, "r", encoding="utf-8") as f:
            content = f.read()

        if ext == ".srt":
            print(f"Processing SRT file: {input_val}")
            result = process_srt(content)
        elif ext == ".ass":
            print(f"Processing ASS file: {input_val}")
            result = process_ass(content)
        else:
            print(f"Treating file as plain text: {input_val}")
            result = add_stress(content)

        if args.output:
            with open(args.output, "w", encoding="utf-8") as f:
                f.write(result)
            print(f"Result saved to: {args.output}")
        else:
            base, ext = os.path.splitext(input_val)
            out_path = f"{base}_stressed{ext}"
            with open(out_path, "w", encoding="utf-8") as f:
                f.write(result)
            print(f"Result saved to: {out_path}")
    else:
        # Input is a string
        result = add_stress(input_val)
        if args.output:
            with open(args.output, "w", encoding="utf-8") as f:
                f.write(result)
            print(f"Result saved to: {args.output}")
        else:
            print("\nStressed text:")
            print(result)


def launch_gui():
    """Launch the web-based graphical user interface."""
    import webbrowser
    import json
    import urllib.parse
    from http.server import HTTPServer, BaseHTTPRequestHandler
    from threading import Thread

    # HTML template for the GUI
    HTML_TEMPLATE = """<!DOCTYPE html>
    <html lang="uk">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Ukrainian Stress Tool</title>
        <style>
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                min-height: 100vh;
                padding: 20px;
            }
            .container {
                max-width: 900px;
                margin: 0 auto;
                background: white;
                border-radius: 16px;
                box-shadow: 0 20px 60px rgba(0,0,0,0.3);
                overflow: hidden;
            }
            .header {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 30px;
                text-align: center;
            }
            .header h1 {
                font-size: 28px;
                margin-bottom: 8px;
            }
            .header p {
                opacity: 0.9;
                font-size: 14px;
            }
            .content {
                padding: 30px;
            }
            .section {
                margin-bottom: 30px;
                padding: 25px;
                background: #f8f9fa;
                border-radius: 12px;
                border: 2px solid #e9ecef;
            }
            .section h2 {
                color: #495057;
                margin-bottom: 20px;
                font-size: 20px;
                display: flex;
                align-items: center;
            }
            .section h2::before {
                content: '';
                width: 4px;
                height: 24px;
                background: #667eea;
                margin-right: 12px;
                border-radius: 2px;
            }
            textarea {
                width: 100%;
                min-height: 200px;
                padding: 15px;
                border: 2px solid #dee2e6;
                border-radius: 8px;
                font-size: 15px;
                font-family: inherit;
                resize: vertical;
                transition: border-color 0.3s;
            }
            textarea:focus {
                outline: none;
                border-color: #667eea;
            }
            .file-input-group {
                margin-bottom: 15px;
            }
            .file-input-group label {
                display: block;
                margin-bottom: 8px;
                color: #495057;
                font-weight: 500;
            }
            input[type="text"], input[type="file"] {
                width: 100%;
                padding: 12px 15px;
                border: 2px solid #dee2e6;
                border-radius: 8px;
                font-size: 14px;
                transition: border-color 0.3s;
            }
            input[type="text"]:focus, input[type="file"]:focus {
                outline: none;
                border-color: #667eea;
            }
            button {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                border: none;
                padding: 14px 28px;
                border-radius: 8px;
                font-size: 15px;
                font-weight: 600;
                cursor: pointer;
                transition: transform 0.2s, box-shadow 0.2s;
                width: 100%;
            }
            button:hover {
                transform: translateY(-2px);
                box-shadow: 0 8px 20px rgba(102, 126, 234, 0.4);
            }
            button:active {
                transform: translateY(0);
            }
            .status {
                margin-top: 15px;
                padding: 12px 15px;
                border-radius: 8px;
                font-size: 14px;
                display: none;
            }
            .status.success {
                background: #d4edda;
                color: #155724;
                border: 1px solid #c3e6cb;
                display: block;
            }
            .status.error {
                background: #f8d7da;
                color: #721c24;
                border: 1px solid #f5c6cb;
                display: block;
            }
            .status.info {
                background: #d1ecf1;
                color: #0c5460;
                border: 1px solid #bee5eb;
                display: block;
            }
            .file-hint {
                font-size: 12px;
                color: #6c757d;
                margin-top: 6px;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🇺🇦 Ukrainian Stress Tool</h1>
                <p>Інструмент для автоматичного додавання наголосів до українського тексту</p>
            </div>
            
            <div class="content">
                <!-- File Processing Section -->
                <div class="section">
                    <h2>Обробка файлу</h2>
                    <div class="file-input-group">
                        <label for="inputFile">Вхідний файл (.srt, .ass, .txt):</label>
                        <input type="file" id="inputFile" accept=".srt,.ass,.txt">
                        <div class="file-hint">Виберіть файл для обробки</div>
                    </div>
                    <div class="file-input-group">
                        <label for="outputName">Назва вихідного файлу:</label>
                        <input type="text" id="outputName" placeholder="output_stressed.txt">
                    </div>
                    <button onclick="processFile()">Обробити файл</button>
                    <div id="fileStatus" class="status"></div>
                </div>
                <!-- Text Editor Section -->
                <div class="section">
                    <h2>Текстовий редактор</h2>
                    <textarea id="textInput" placeholder="Введіть текст українською мовою..."></textarea>
                    <button onclick="applyStressToText()">Застосувати наголоси до тексту</button>
                    <div id="textStatus" class="status"></div>
                </div>
                
            </div>
        </div>
        
        <script>
            function showStatus(elementId, message, type) {
                const el = document.getElementById(elementId);
                el.textContent = message;
                el.className = 'status ' + type;
            }
            
            async function applyStressToText() {
                const text = document.getElementById('textInput').value;
                if (!text.trim()) {
                    showStatus('textStatus', 'Текстове поле порожнє!', 'error');
                    return;
                }
                
                showStatus('textStatus', 'Застосування наголосів...', 'info');
                
                try {
                    const response = await fetch('/api/stress-text', {
                        method: 'POST',
                        headers: {'Content-Type': 'application/json'},
                        body: JSON.stringify({text: text})
                    });
                    
                    const data = await response.json();
                    
                    if (data.success) {
                        document.getElementById('textInput').value = data.result;
                        showStatus('textStatus', 'Наголоси успішно застосовані!', 'success');
                    } else {
                        showStatus('textStatus', 'Помилка: ' + data.error, 'error');
                    }
                } catch (error) {
                    showStatus('textStatus', 'Помилка підключення: ' + error, 'error');
                }
            }
            
            async function processFile() {
                const fileInput = document.getElementById('inputFile');
                const outputName = document.getElementById('outputName').value;
                
                if (!fileInput.files.length) {
                    showStatus('fileStatus', 'Будь ласка, виберіть файл!', 'error');
                    return;
                }
                
                if (!outputName.trim()) {
                    showStatus('fileStatus', 'Будь ласка, вкажіть назву вихідного файлу!', 'error');
                    return;
                }
                
                showStatus('fileStatus', 'Обробка файлу...', 'info');
                
                const file = fileInput.files[0];
                const reader = new FileReader();
                
                reader.onload = async function(e) {
                    try {
                        const response = await fetch('/api/process-file', {
                            method: 'POST',
                            headers: {'Content-Type': 'application/json'},
                            body: JSON.stringify({
                                content: e.target.result,
                                filename: file.name,
                                outputName: outputName
                            })
                        });
                        
                        const data = await response.json();
                        
                        if (data.success) {
                            // Download the processed file
                            const blob = new Blob([data.result], {type: 'text/plain;charset=utf-8'});
                            const url = window.URL.createObjectURL(blob);
                            const a = document.createElement('a');
                            a.href = url;
                            a.download = outputName;
                            a.click();
                            window.URL.revokeObjectURL(url);
                            
                            showStatus('fileStatus', 'Файл успішно оброблено та завантажено!', 'success');
                        } else {
                            showStatus('fileStatus', 'Помилка: ' + data.error, 'error');
                        }
                    } catch (error) {
                        showStatus('fileStatus', 'Помилка обробки: ' + error, 'error');
                    }
                };
                
                reader.readAsText(file);
            }
            
            // Auto-suggest output filename when input file is selected
            document.getElementById('inputFile').addEventListener('change', function(e) {
                if (e.target.files.length) {
                    const filename = e.target.files[0].name;
                    const lastDot = filename.lastIndexOf('.');
                    const name = lastDot > 0 ? filename.substring(0, lastDot) : filename;
                    const ext = lastDot > 0 ? filename.substring(lastDot) : '.txt';
                    document.getElementById('outputName').value = name + '_stressed' + ext;
                }
            });
        </script>
    </body>
    </html>"""

    class StressToolHandler(BaseHTTPRequestHandler):
        def log_message(self, format, *args):
            # Suppress default logging
            pass

        def do_GET(self):
            if self.path == "/" or self.path == "/index.html":
                self.send_response(200)
                self.send_header("Content-type", "text/html; charset=utf-8")
                self.end_headers()
                self.wfile.write(HTML_TEMPLATE.encode("utf-8"))
            else:
                self.send_response(404)
                self.end_headers()

        def do_POST(self):
            content_length = int(self.headers["Content-Length"])
            post_data = self.rfile.read(content_length)

            try:
                data = json.loads(post_data.decode("utf-8"))

                if self.path == "/api/stress-text":
                    text = data.get("text", "")
                    result = add_stress(text)
                    response = {"success": True, "result": result}

                elif self.path == "/api/process-file":
                    content = data.get("content", "")
                    filename = data.get("filename", "")
                    ext = os.path.splitext(filename)[1].lower()

                    if ext == ".srt":
                        result = process_srt(content)
                    elif ext == ".ass":
                        result = process_ass(content)
                    else:
                        result = add_stress(content)

                    response = {"success": True, "result": result}

                else:
                    response = {"success": False, "error": "Unknown endpoint"}

                self.send_response(200)
                self.send_header("Content-type", "application/json; charset=utf-8")
                self.end_headers()
                self.wfile.write(json.dumps(response).encode("utf-8"))

            except Exception as e:
                response = {"success": False, "error": str(e)}
                self.send_response(500)
                self.send_header("Content-type", "application/json; charset=utf-8")
                self.end_headers()
                self.wfile.write(json.dumps(response).encode("utf-8"))

    # Start the server - find available port
    PORT = 8765
    MAX_ATTEMPTS = 10
    server = None

    for attempt in range(MAX_ATTEMPTS):
        try:
            server = HTTPServer(("localhost", PORT), StressToolHandler)
            break
        except OSError as e:
            if e.errno == 48:  # Address already in use
                PORT += 1
            else:
                raise

    if server is None:
        print(f"❌ Помилка: Не вдалося знайти вільний порт після {MAX_ATTEMPTS} спроб.")
        print(f"Спробуйте закрити інші програми або перезавантажити комп'ютер.")
        sys.exit(1)

    print(f"🚀 Ukrainian Stress Tool запущено!")
    print(f"📱 Відкрийте у браузері: http://localhost:{PORT}")
    print(f"⌨️  Натисніть Ctrl+C для виходу\n")

    # Open browser
    webbrowser.open(f"http://localhost:{PORT}")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n\n👋 Дякуємо за використання Ukrainian Stress Tool!")
    finally:
        server.server_close()
        # On macOS, try to close the terminal window automatically
        if sys.platform == "darwin":
            try:
                # Use AppleScript to close the front window of Terminal without confirmation
                os.system("osascript -e 'tell application \"Terminal\" to close front window saving no' &")
            except:
                pass
        elif sys.platform == "win32":
            try:
                # On Windows, taskkill can be used to close the parent cmd window
                # We target the parent PID if possible, or just exit and let the .bat finish
                # If we want it to close IMMEDIATELY on Ctrl+C without further batch processing:
                os.system("taskkill /F /PID " + str(os.getppid()) + " >nul 2>&1")
            except:
                pass
        sys.exit(0)


if __name__ == "__main__":
    # If no command-line arguments provided, launch GUI
    if len(sys.argv) == 1:
        launch_gui()
    else:
        # Use command-line interface
        main()
