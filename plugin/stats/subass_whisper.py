import sys
import os
import subprocess
import shutil
import argparse
import json
import tempfile

# Check if dependencies are installed
try:
    import whisper
    import numpy as np
    import torch
except ImportError:
    print("\n[AI] Необхідні бібліотеки (openai-whisper, numpy, torch) не знайдені.")
    print("Якщо ви хочете встановити бібліотеки зараз, введіть 'install' та натисніть Enter.")
    
    choice = input("\n> ").strip().lower()
    if choice == "install":
        print("\n[AI] Встановлення залежностей... (Це може зайняти деякий час)")
        try:
            # Try installing with --break-system-packages for Homebrew/system Python environments
            subprocess.check_call([sys.executable, "-m", "pip", "install", "openai-whisper", "numpy", "torch", "--break-system-packages"])
            print("[AI] Бібліотеки успішно встановлені!")
            import whisper 
            import numpy as np
            import torch
        except subprocess.CalledProcessError:
            try:
                subprocess.check_call([sys.executable, "-m", "pip", "install", "openai-whisper", "numpy", "torch"])
                print("[AI] Бібліотеки успішно встановлені!")
                import whisper
                import numpy as np
                import torch
            except:
                print("[AI] Помилка встановлення. Спробуйте вручну: 'pip install openai-whisper numpy torch --break-system-packages'")
                sys.exit(1)
    else:
        print("[AI] Встановлення скасовано.")
        sys.exit(0)

# Check for ffmpeg (Required by Whisper)
if not shutil.which("ffmpeg"):
    print("\n[AI] Помилка: 'ffmpeg' не знайдено.")
    print("Whisper вимагає ffmpeg для обробки аудіо.")
    print("Будь ласка, встановіть ffmpeg вручну (наприклад, 'brew install ffmpeg' на macOS або скачайте з ffmpeg.org).")
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

def extract_audio(input_path):
    """Extracts audio to a temporary WAV file for faster processing."""
    temp_wav = tempfile.NamedTemporaryFile(suffix=".wav", delete=False)
    temp_wav.close()
    print(f"[AI] Оптимізація: вилучення аудіо до тимчасового файлу...")
    try:
        # Extract audio as mono 16kHz WAV
        subprocess.run([
            "ffmpeg", "-y", "-i", input_path, 
            "-vn", "-acodec", "pcm_s16le", "-ar", "16000", "-ac", "1", 
            temp_wav.name
        ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return temp_wav.name
    except Exception as e:
        print(f"[AI] Увага: Не вдалося вилучити аудіо автоматично ({e}). Спробуємо завантажити як є.")
        return input_path

def main():
    parser = argparse.ArgumentParser(description="Transcribe a local video/audio file to SRT using OpenAI Whisper.")
    parser.add_argument("input_file", help="Path to the local video or audio file.")
    parser.add_argument("output_path", help="Path where the .srt file should be saved or its directory.")
    parser.add_argument("--lang", default="en", help="Original language of the audio (default: en).")
    args = parser.parse_args()

    # Target model: set to "turbo" for much faster performance on Mac (1.6GB)
    target_model = "turbo" # Change back to "large-v3" only if you need the absolute maximum accuracy (3GB)

    input_path = os.path.abspath(args.input_file)
    output_path = os.path.abspath(args.output_path)
    language = args.lang

    if not os.path.exists(input_path):
        print(f"\n[AI] Помилка: Файл не знайдено: {input_path}")
        sys.exit(1)

    # If output_path is a directory, use the input filename (with .srt extension)
    if os.path.isdir(output_path):
        base_name = os.path.splitext(os.path.basename(input_path))[0]
        output_path = os.path.join(output_path, f"{base_name}.srt")
    
    # Ensure output directory exists
    output_dir = os.path.dirname(output_path)
    if output_dir and not os.path.exists(output_dir):
        os.makedirs(output_dir)

    print(f"\n[AI] Ініціалізація Whisper AI (модель {target_model})...")
    
    # Determine device
    device = "cpu"
    if torch.cuda.is_available():
        device = "cuda"
    elif hasattr(torch.backends, "mps") and torch.backends.mps.is_available():
        device = "mps"
    
    print(f"[AI] Використовується пристрій: {device.upper()}")

    try:
        model = whisper.load_model(target_model, device=device)
    except Exception as e:
        print(f"\n[AI] Помилка завантаження моделі: {e}")
        sys.exit(1)

    # Pre-extract audio to speed up processing
    audio_file = extract_audio(input_path)

    print(f"[AI] Транскрибація файлу: {os.path.basename(input_path)}...")
    print(f"[AI] Мова: {language}")
    print(f"[AI] (Ви побачите текст нижче, коли він почне розпізнаватися)\n")

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
        print(f"\n[AI] Готово! SRT файл збережено: {output_path}")

    except Exception as e:
        print(f"\n[КРИТИЧНА ПОМИЛКА]: {e}")
    finally:
        # Cleanup temporary audio file
        if audio_file != input_path and os.path.exists(audio_file):
            try:
                os.remove(audio_file)
            except:
                pass

if __name__ == "__main__":
    main()
