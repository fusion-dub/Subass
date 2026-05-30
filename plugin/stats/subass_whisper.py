import sys
import os
import subprocess
import shutil
import argparse
import json
import tempfile

# On macOS/Linux, ensure common search paths are in PATH environment variable
# (especially important when run from GUI apps like REAPER)
if sys.platform != "win32":
    extra_paths = ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/bin"]
    paths = os.environ.get("PATH", "").split(os.pathsep)
    for p in extra_paths:
        if p not in paths:
            paths.insert(0, p)
    os.environ["PATH"] = os.pathsep.join(paths)

# --- Install-check mode (triggered by Lua after user confirmation) ---
# Must be handled BEFORE the whisper import block so we can auto-install
_INSTALL_CHECK = "--install-check" in sys.argv
if _INSTALL_CHECK:
    sys.argv = [a for a in sys.argv if a != "--install-check"]

# Check if dependencies are installed
try:
    import whisper
    import numpy as np
    import torch

    # ---- INSTALL-CHECK mode: deps already present, just pre-download the model ----
    if _INSTALL_CHECK:
        print("\n[WI] Dependencies are already installed.")
        print("[WI] Downloading model 'turbo' (~1.6 GB), please wait...")
        try:
            device = "cpu"
            if hasattr(torch.backends, "mps") and torch.backends.mps.is_available():
                device = "mps"
            elif torch.cuda.is_available():
                device = "cuda"
            print(f"[WI] Device: {device.upper()}")
            whisper.load_model("turbo", device=device)
            print("\n[WI] ✅ Model successfully loaded and ready to use!")
        except Exception as e:
            print(f"\n[WI] ⚠️  Error loading model: {e}")
        print("\n[WI] This window can be closed.")
        input("Press Enter to exit...")
        sys.exit(0)

except ImportError:
    # ---- INSTALL-CHECK mode: auto-install without prompts (user confirmed in REAPER) ----
    if _INSTALL_CHECK:
        print("\n[WI] ╔══════════════════════════════════════════════════╗")
        print("[WI] ║      Installing Whisper AI (Speech to Text)      ║")
        print("[WI] ╚══════════════════════════════════════════════════╝")
        print("[WI] Step 1/2: Installing packages (openai-whisper, numpy, torch)...")
        print("[WI] This may take a few minutes...\n")
        install_ok = False
        for extra_flags in (["--break-system-packages"], []):
            try:
                subprocess.check_call(
                    [sys.executable, "-m", "pip", "install",
                     "openai-whisper", "numpy", "torch"] + extra_flags
                )
                install_ok = True
                break
            except subprocess.CalledProcessError:
                continue
        if not install_ok:
            print("\n[WI] ❌ Installation error.")
            print("[WI] Try manually: pip install openai-whisper numpy torch --break-system-packages")
            input("Press Enter to exit...")
            sys.exit(1)

        print("\n[WI] ✅ Packages installed!")
        print("[WI] Step 2/2: Downloading model 'turbo' (~1.6 GB)...\n")
        try:
            import whisper
            import torch
            device = "cpu"
            if hasattr(torch.backends, "mps") and torch.backends.mps.is_available():
                device = "mps"
            elif torch.cuda.is_available():
                device = "cuda"
            print(f"[WI] Device: {device.upper()}")
            whisper.load_model("turbo", device=device)
            print("\n[WI] ✅ Model loaded! Whisper AI is ready to use.")
        except Exception as e:
            print(f"\n[WI] ⚠️  Error loading model: {e}")
            print("[WI] Model will be downloaded automatically during first use.")
        print("\n[WI] This window can be closed.")
        input("Press Enter to exit...")
        sys.exit(0)

    # ---- Interactive mode: ask user ----
    print("\n[WI] Required packages (openai-whisper, numpy, torch) not found.")
    print("If you want to install the packages now, type 'install' and press Enter.")

    choice = input("\n> ").strip().lower()
    if choice == "install":
        print("\n[WI] Installing dependencies... (This may take some time)")
        try:
            # Try installing with --break-system-packages for Homebrew/system Python environments
            subprocess.check_call([sys.executable, "-m", "pip", "install", "openai-whisper", "numpy", "torch", "--break-system-packages"])
            print("[WI] Packages successfully installed!")
            import whisper
            import numpy as np
            import torch
        except subprocess.CalledProcessError:
            try:
                subprocess.check_call([sys.executable, "-m", "pip", "install", "openai-whisper", "numpy", "torch"])
                print("[WI] Packages successfully installed!")
                import whisper
                import numpy as np
                import torch
            except:
                print("[WI] Installation error. Try manually: 'pip install openai-whisper numpy torch --break-system-packages'")
                sys.exit(1)
    else:
        print("[WI] Installation cancelled.")
        sys.exit(0)

# Check for ffmpeg (Required by Whisper)
if not shutil.which("ffmpeg"):
    print("\n[WI] Error: 'ffmpeg' not found.")
    print("Whisper requires ffmpeg to process audio.")
    print("Please install ffmpeg manually (e.g., 'brew install ffmpeg' on macOS or download from ffmpeg.org).")
    sys.exit(1)

def format_srt_timestamp(seconds: float) -> str:
    """Converts seconds to HH:MM:SS,mmm format for SRT."""
    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) // 60)
    remaining_seconds = seconds % 60
    millis = int((remaining_seconds - int(remaining_seconds)) * 1000)
    return f"{hours:02d}:{minutes:02d}:{int(remaining_seconds):02d},{millis:03d}"

def write_srt(segments, output_path):
    """Writes Whisper segments to an SRT file."""
    with open(output_path, "w", encoding="utf-8") as f:
        for i, segment in enumerate(segments):
            start = segment['start']
            end = segment['end']
            text = segment['text'].strip()
            
            f.write(f"{i + 1}\n")
            f.write(f"{format_srt_timestamp(start)} --> {format_srt_timestamp(end)}\n")
            f.write(f"{text}\n\n")

def extract_audio(input_path, start=None, duration=None):
    """Extracts audio to a temporary WAV file for faster processing, optionally trimming it."""
    temp_wav = tempfile.NamedTemporaryFile(suffix=".wav", delete=False)
    temp_wav.close()
    print(f"[WI] Optimization: extracting audio to a temporary file...")
    try:
        cmd = ["ffmpeg", "-y"]
        if start is not None:
            cmd += ["-ss", str(start)]
        cmd += ["-i", input_path]
        if duration is not None:
            cmd += ["-t", str(duration)]
        cmd += ["-vn", "-acodec", "pcm_s16le", "-ar", "16000", "-ac", "1", temp_wav.name]
        
        subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return temp_wav.name
    except Exception as e:
        print(f"[WI] Warning: Failed to extract or trim audio ({e}). Attempting to load as is.")
        return input_path

def main():
    parser = argparse.ArgumentParser(description="Transcribe a local video/audio file to SRT using OpenAI Whisper.")
    parser.add_argument("input_file", help="Path to the local video or audio file.")
    parser.add_argument("output_path", help="Path where the .srt file should be saved or its directory.")
    parser.add_argument("--lang", default="en", help="Original language of the audio (default: en).")
    parser.add_argument("--start", type=float, default=None, help="Start offset in seconds")
    parser.add_argument("--duration", type=float, default=None, help="Duration in seconds")
    args = parser.parse_args()

    # Target model: set to "turbo" for much faster performance on Mac (1.6GB)
    target_model = "turbo" # Change back to "large-v3" only if you need the absolute maximum accuracy (3GB)

    input_path = os.path.abspath(args.input_file)
    output_path = os.path.abspath(args.output_path)
    language = args.lang
    if language == "auto" or language == "None":
        language = None

    if not os.path.exists(input_path):
        print(f"\n[WI] Error: File not found: {input_path}")
        sys.exit(1)

    # If output_path is a directory, use the input filename (with .srt extension)
    if os.path.isdir(output_path):
        base_name = os.path.splitext(os.path.basename(input_path))[0]
        output_path = os.path.join(output_path, f"{base_name}.srt")
    
    # Ensure output directory exists
    output_dir = os.path.dirname(output_path)
    if output_dir and not os.path.exists(output_dir):
        os.makedirs(output_dir)

    print(f"\n[WI] Initializing Whisper AI (model: {target_model})...")
    
    # Determine device
    device = "cpu"
    if torch.cuda.is_available():
        device = "cuda"
    elif hasattr(torch.backends, "mps") and torch.backends.mps.is_available():
        device = "mps"
    
    print(f"[WI] Active device: {device.upper()}")

    try:
        model = whisper.load_model(target_model, device=device)
    except Exception as e:
        print(f"\n[WI] Error loading model: {e}")
        sys.exit(1)

    # Pre-extract audio to speed up processing
    audio_file = extract_audio(input_path, args.start, args.duration)

    print(f"[WI] Language: {language}")

    try:
        # Transcribe
        result = model.transcribe(
            audio_file,
            language=language,
            verbose=True, # Show progress in console
            fp16=(device == "cuda"),
            condition_on_previous_text=False # Better stability on Mac
        )

        # Write SRT
        write_srt(result["segments"], output_path)
        print(f"\n[WI] Done! SRT file saved: {output_path}")

    except Exception as e:
        print(f"\n[CRITICAL ERROR]: {e}")
    finally:
        # Cleanup temporary audio file
        if audio_file != input_path and os.path.exists(audio_file):
            try:
                os.remove(audio_file)
            except:
                pass

if __name__ == "__main__":
    main()
