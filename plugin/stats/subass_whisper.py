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

import warnings
warnings.filterwarnings("ignore")
os.environ["PYTHONWARNINGS"] = "ignore"
os.environ["TOKENIZERS_PARALLELISM"] = "false"

import logging
logging.basicConfig(level=logging.ERROR)
logging.getLogger("torch").setLevel(logging.ERROR)
logging.getLogger("ctranslate2").setLevel(logging.ERROR)
logging.getLogger("speechbrain").setLevel(logging.ERROR)
logging.getLogger("pyannote").setLevel(logging.ERROR)

# --- Install-check mode (triggered by Lua after user confirmation) ---
# Must be handled BEFORE the whisper import block so we can auto-install
_INSTALL_CHECK = "--install-check" in sys.argv
if _INSTALL_CHECK:
    sys.argv = [a for a in sys.argv if a != "--install-check"]

# Check if dependencies are installed
try:
    import whisperx
    import numpy as np
    import torch

    # ---- INSTALL-CHECK mode: deps already present, just pre-download the model ----
    if _INSTALL_CHECK:
        print("\n[WI] Dependencies are already installed.")
        print("[WI] Downloading model 'turbo' (~1.6 GB), please wait...")
        try:
            device = "cpu"
            if torch.cuda.is_available():
                device = "cuda"
            print(f"[WI] Device: {device.upper()}")
            compute_type = "float16" if device == "cuda" else "int8"
            whisperx.load_model("turbo", device=device, compute_type=compute_type)
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
        print("[WI] ║     Installing WhisperX AI (Speech to Text)      ║")
        print("[WI] ╚══════════════════════════════════════════════════╝")
        print("[WI] Step 1/2: Installing packages (whisperx, numpy, torch)...")
        print("[WI] This may take a few minutes...\n")
        install_ok = False
        for extra_flags in (["--break-system-packages"], []):
            try:
                subprocess.check_call(
                    [sys.executable, "-m", "pip", "install",
                     "whisperx", "numpy", "torch"] + extra_flags
                )
                install_ok = True
                break
            except subprocess.CalledProcessError:
                continue
        if not install_ok:
            print("\n[WI] ❌ Installation error.")
            print("[WI] Common causes on Windows / macOS:")
            print("[WI] 1. You might be using a 32-bit version of Python (ctranslate2/torch require 64-bit Python).")
            print("[WI] 2. You might be using Python 3.13+ (ctranslate2 4.4.0 does not support Python 3.13 yet. Please use Python 3.10, 3.11, or 3.12).")
            print("[WI] 3. Outdated pip. Try running: python -m pip install --upgrade pip setuptools wheel")
            print("[WI] Try manually: pip install whisperx numpy torch --break-system-packages")
            input("Press Enter to exit...")
            sys.exit(1)

        print("\n[WI] ✅ Packages installed!")
        print("[WI] Step 2/2: Downloading model 'turbo' (~1.6 GB)...\n")
        try:
            import whisperx
            import torch
            device = "cpu"
            if torch.cuda.is_available():
                device = "cuda"
            print(f"[WI] Device: {device.upper()}")
            compute_type = "float16" if device == "cuda" else "int8"
            whisperx.load_model("turbo", device=device, compute_type=compute_type)
            print("\n[WI] ✅ Model loaded! WhisperX AI is ready to use.")
        except Exception as e:
            print(f"\n[WI] ⚠️  Error loading model: {e}")
            print("[WI] Model will be downloaded automatically during first use.")
        print("\n[WI] This window can be closed.")
        input("Press Enter to exit...")
        sys.exit(0)

    # ---- Interactive mode: ask user ----
    print("\n[WI] Required packages (whisperx, numpy, torch) not found.")
    print("If you want to install the packages now, type 'install' and press Enter.")

    choice = input("\n> ").strip().lower()
    if choice == "install":
        print("\n[WI] Installing dependencies... (This may take some time)")
        try:
            # Try installing with --break-system-packages for Homebrew/system Python environments
            subprocess.check_call([sys.executable, "-m", "pip", "install", "whisperx", "numpy", "torch", "--break-system-packages"])
            print("[WI] Packages successfully installed!")
            import whisperx
            import numpy as np
            import torch
        except subprocess.CalledProcessError:
            try:
                subprocess.check_call([sys.executable, "-m", "pip", "install", "whisperx", "numpy", "torch"])
                print("[WI] Packages successfully installed!")
                import whisperx
                import numpy as np
                import torch
            except:
                print("[WI] Installation error.")
                print("[WI] Common causes on Windows / macOS:")
                print("[WI] 1. You might be using a 32-bit version of Python (ctranslate2/torch require 64-bit Python).")
                print("[WI] 2. You might be using Python 3.13+ (ctranslate2 4.4.0 does not support Python 3.13 yet. Please use Python 3.10, 3.11, or 3.12).")
                print("[WI] 3. Outdated pip. Try running: python -m pip install --upgrade pip setuptools wheel")
                print("[WI] Try manually: 'pip install whisperx numpy torch --break-system-packages'")
                sys.exit(1)
    else:
        print("[WI] Installation cancelled.")
        sys.exit(0)

# Check for ffmpeg (Required by Whisper/WhisperX)
if not shutil.which("ffmpeg"):
    print("\nError: 'ffmpeg' not found.")
    print("Whisper/WhisperX requires ffmpeg to process audio.")
    print("Please install ffmpeg manually (e.g., 'brew install ffmpeg' on macOS or download from ffmpeg.org).")
    sys.exit(1)

def format_srt_timestamp(seconds: float) -> str:
    """Converts seconds to HH:MM:SS,mmm format for SRT."""
    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) // 60)
    remaining_seconds = seconds % 60
    millis = int((remaining_seconds - int(remaining_seconds)) * 1000)
    return f"{hours:02d}:{minutes:02d}:{int(remaining_seconds):02d},{millis:03d}"

def print_segment_progress(start, end, text):
    """Prints a segment in the format expected by REAPER Lua script to track progress."""
    m_start = int(start // 60)
    s_start = int(start % 60)
    ms_start = int((start - int(start)) * 1000)
    
    m_end = int(end // 60)
    s_end = int(end % 60)
    ms_end = int((end - int(end)) * 1000)
    
    print(f"[{m_start:02d}:{s_start:02d}.{ms_start:03d} --> {m_end:02d}:{s_end:02d}.{ms_end:03d}] {text}", flush=True)

def print_console_segment(start, end, text):
    """Prints a segment for the user console, formatted differently to avoid matching REAPER's progress parser."""
    m_start = int(start // 60)
    s_start = int(start % 60)
    ms_start = int((start - int(start)) * 1000)
    
    m_end = int(end // 60)
    s_end = int(end % 60)
    ms_end = int((end - int(end)) * 1000)
    
    print(f"[{m_start:02d}:{s_start:02d}.{ms_start:03d} - {m_end:02d}:{s_end:02d}.{ms_end:03d}] {text}", flush=True)

def make_progress_callback(phase_name, effective_dur, start_pct, end_pct):
    def progress_callback(p):
        percent = p if p > 1.0 else (p * 100.0)
        if percent > 100.0:
            percent = 100.0
        scaled_percent = start_pct + (percent / 100.0) * (end_pct - start_pct)
        current_time = (scaled_percent / 100.0) * effective_dur
        m = int(current_time // 60)
        s = int(current_time % 60)
        ms = int((current_time - int(current_time)) * 1000)
        print(f"[00:00.000 --> {m:02d}:{s:02d}.{ms:03d}] {phase_name} ({scaled_percent:.1f}%)", flush=True)
    return progress_callback

def print_static_progress(phase_name, effective_dur, scaled_percent):
    current_time = (scaled_percent / 100.0) * effective_dur
    m = int(current_time // 60)
    s = int(current_time % 60)
    ms = int((current_time - int(current_time)) * 1000)
    print(f"[00:00.000 --> {m:02d}:{s:02d}.{ms:03d}] {phase_name} ({scaled_percent:.1f}%)", flush=True)

def resegment_by_speaker(result, language_code):
    """Splits transcription segments based on speaker changes at the word level."""
    new_segments = []
    is_no_space_lang = str(language_code).lower() in ["ja", "zh", "japanese", "chinese"]
    
    for segment in result.get("segments", []):
        words = segment.get("words", [])
        if not words:
            new_segments.append(segment)
            continue
            
        current_speaker = None
        current_words = []
        
        for w in words:
            spk = w.get("speaker", segment.get("speaker"))
            
            # If speaker changes, flush the current group of words
            if spk != current_speaker and len(current_words) > 0:
                start_time = None
                for word in current_words:
                    if "start" in word:
                        start_time = word["start"]
                        break
                if start_time is None:
                    start_time = segment.get("start", 0.0)
                    
                end_time = None
                for word in reversed(current_words):
                    if "end" in word:
                        end_time = word["end"]
                        break
                if end_time is None:
                    end_time = segment.get("end", start_time)
                
                word_texts = [x.get("word", "") for x in current_words]
                if is_no_space_lang:
                    text = "".join(word_texts).strip()
                else:
                    text = " ".join(word_texts).strip()
                
                new_seg = {
                    "start": start_time,
                    "end": end_time,
                    "text": text,
                    "speaker": current_speaker,
                    "words": current_words
                }
                new_segments.append(new_seg)
                current_words = []
            
            current_speaker = spk
            current_words.append(w)
            
        # Flush final group
        if current_words:
            start_time = None
            for word in current_words:
                if "start" in word:
                    start_time = word["start"]
                    break
            if start_time is None:
                start_time = segment.get("start", 0.0)
                
            end_time = None
            for word in reversed(current_words):
                if "end" in word:
                    end_time = word["end"]
                    break
            if end_time is None:
                end_time = segment.get("end", start_time)
            
            word_texts = [x.get("word", "") for x in current_words]
            if is_no_space_lang:
                text = "".join(word_texts).strip()
            else:
                text = " ".join(word_texts).strip()
            
            new_seg = {
                "start": start_time,
                "end": end_time,
                "text": text,
                "speaker": current_speaker,
                "words": current_words
            }
            new_segments.append(new_seg)
            
    result["segments"] = new_segments
    return result

def split_long_segments(result, language_code, max_duration=4.0, max_gap=0.4):
    """Splits long segments into smaller ones based on maximum duration and silence gaps between words."""
    new_segments = []
    is_no_space_lang = str(language_code).lower() in ["ja", "zh", "japanese", "chinese"]
    
    for segment in result.get("segments", []):
        words = segment.get("words", [])
        if not words or len(words) <= 1:
            new_segments.append(segment)
            continue
            
        current_words = []
        
        for i, w in enumerate(words):
            should_split = False
            
            if len(current_words) > 0:
                # 1. Split if there is a silence gap between the previous word and this word
                prev_word = current_words[-1]
                if "end" in prev_word and "start" in w:
                    gap = w["start"] - prev_word["end"]
                    if gap >= max_gap:
                        should_split = True
                
                # 2. Split if the current accumulated duration exceeds max_duration
                if not should_split and "start" in w:
                    current_start_time = None
                    for word in current_words:
                        if "start" in word:
                            current_start_time = word["start"]
                            break
                    if current_start_time is None:
                        current_start_time = segment.get("start", 0.0)
                        
                    current_dur = w["start"] - current_start_time
                    if current_dur >= max_duration:
                        should_split = True
            
            # Suppress splitting if the remaining part would have 2 or fewer words
            if should_split:
                remaining_words_count = len(words) - i
                if remaining_words_count <= 2:
                    should_split = False
            
            if should_split and len(current_words) > 0:
                start_time = None
                for word in current_words:
                    if "start" in word:
                        start_time = word["start"]
                        break
                if start_time is None:
                    start_time = segment.get("start", 0.0)
                    
                end_time = None
                for word in reversed(current_words):
                    if "end" in word:
                        end_time = word["end"]
                        break
                if end_time is None:
                    end_time = w.get("start", segment.get("end", start_time))
                
                word_texts = [x.get("word", "") for x in current_words]
                if is_no_space_lang:
                    text = "".join(word_texts).strip()
                else:
                    text = " ".join(word_texts).strip()
                
                new_seg = {
                    "start": start_time,
                    "end": end_time,
                    "text": text,
                    "speaker": segment.get("speaker"),
                    "words": current_words
                }
                new_segments.append(new_seg)
                current_words = []
                
            current_words.append(w)
            
        # Flush the final group
        if current_words:
            start_time = None
            for word in current_words:
                if "start" in word:
                    start_time = word["start"]
                    break
            if start_time is None:
                start_time = segment.get("start", 0.0)
                
            end_time = None
            for word in reversed(current_words):
                if "end" in word:
                    end_time = word["end"]
                    break
            if end_time is None:
                end_time = segment.get("end", start_time)
            
            word_texts = [x.get("word", "") for x in current_words]
            if is_no_space_lang:
                text = "".join(word_texts).strip()
            else:
                text = " ".join(word_texts).strip()
            
            new_seg = {
                "start": start_time,
                "end": end_time,
                "text": text,
                "speaker": segment.get("speaker"),
                "words": current_words
            }
            new_segments.append(new_seg)
            
    result["segments"] = new_segments
    return result

def write_srt(segments, output_path):
    """Writes segments to an SRT file, optionally including speaker labels."""
    with open(output_path, "w", encoding="utf-8") as f:
        for i, segment in enumerate(segments):
            start = segment.get('start', 0.0)
            end = segment.get('end', 0.0)
            text = segment.get('text', '').strip()
            
            speaker = segment.get('speaker', None)
            if speaker:
                text = f"[{speaker}]: {text}"
                
            f.write(f"{i + 1}\n")
            f.write(f"{format_srt_timestamp(start)} --> {format_srt_timestamp(end)}\n")
            f.write(f"{text}\n\n")

def extract_audio(input_path, start=None, duration=None):
    """Extracts audio to a temporary WAV file for faster processing, optionally trimming it."""
    temp_wav = tempfile.NamedTemporaryFile(suffix=".wav", delete=False)
    temp_wav.close()
    print(f"Optimization: extracting audio to a temporary file...")
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
        print(f"Warning: Failed to extract or trim audio ({e}). Attempting to load as is.")
        return input_path

def main():
    parser = argparse.ArgumentParser(description="Transcribe a local video/audio file to SRT using WhisperX.")
    parser.add_argument("input_file", help="Path to the local video or audio file.")
    parser.add_argument("output_path", help="Path where the .srt file should be saved or its directory.")
    parser.add_argument("--lang", default="en", help="Original language of the audio (default: en).")
    parser.add_argument("--start", type=float, default=None, help="Start offset in seconds")
    parser.add_argument("--duration", type=float, default=None, help="Duration in seconds")
    parser.add_argument("--hf-token", default=None, help="Hugging Face user access token for diarization")
    parser.add_argument("--diarize", action="store_true", help="Enable speaker diarization")
    parser.add_argument("--split-segments", action="store_true", help="Enable segment splitting by duration and gaps")
    parser.add_argument("--max-duration", type=float, default=4.0, help="Maximum segment duration in seconds")
    parser.add_argument("--max-gap", type=float, default=0.4, help="Maximum silence gap between words in seconds")
    parser.add_argument("--offset-start", type=float, default=0.0, help="Start offset padding in seconds")
    parser.add_argument("--offset-end", type=float, default=0.0, help="End offset padding in seconds")
    args = parser.parse_args()

    # Target model: set to "turbo" for much faster performance on Mac (1.6GB)
    target_model = "turbo" # Change back to "large-v3" only if you need the absolute maximum accuracy (3GB)

    input_path = os.path.abspath(args.input_file)
    output_path = os.path.abspath(args.output_path)
    language = args.lang
    if language == "auto" or language == "None" or not language:
        language = None

    if not os.path.exists(input_path):
        print(f"\nError: File not found: {input_path}")
        sys.exit(1)

    # If output_path is a directory, use the input filename (with .srt extension)
    if os.path.isdir(output_path):
        base_name = os.path.splitext(os.path.basename(input_path))[0]
        output_path = os.path.join(output_path, f"{base_name}.srt")
    
    # Ensure output directory exists
    output_dir = os.path.dirname(output_path)
    if output_dir and not os.path.exists(output_dir):
        os.makedirs(output_dir)

    print(f"\nInitializing WhisperX AI (model: {target_model})...")
    
    # Determine device
    device = "cpu"
    if torch.cuda.is_available():
        device = "cuda"
    
    print(f"Active device: {device.upper()}")

    # Pre-extract audio to speed up processing
    audio_file = extract_audio(input_path, args.start, args.duration)

    print(f"Language: {language}")

    try:
        compute_type = "float16" if device == "cuda" else "int8"
        model = whisperx.load_model(target_model, device=device, compute_type=compute_type)
        
        # Load audio (numpy array)
        audio = whisperx.load_audio(audio_file)
        duration = len(audio) / 16000.0 if len(audio) > 0 else 1.0
        
        # Determine ranges
        hf_token = args.hf_token
        has_diarization = bool(hf_token and hf_token.strip() and args.diarize)
        tx_start, tx_end = 0.0, 50.0 if has_diarization else 70.0
        al_start, al_end = tx_end, 75.0 if has_diarization else 95.0

        # Transcribe
        print("Transcribing audio...")
        transcribe_cb = make_progress_callback("Transcribing", duration, tx_start, tx_end)
        result = model.transcribe(
            audio,
            batch_size=4,
            language=language,
            print_progress=True,
            progress_callback=transcribe_cb
        )
        for segment in result.get("segments", []):
            print_console_segment(segment.get("start", 0.0), segment.get("end", 0.0), segment.get("text", ""))

        # Align
        detected_lang = result.get("language", language)
        if detected_lang:
            print(f"Aligning timestamps (language: {detected_lang})...")
            try:
                model_a, metadata = whisperx.load_align_model(language_code=detected_lang, device=device)
                align_cb = make_progress_callback("Aligning", duration, al_start, al_end)
                result = whisperx.align(result["segments"], model_a, metadata, audio, device, return_char_alignments=False, progress_callback=align_cb)
            except Exception as ae:
                print(f"Warning: Alignment failed ({ae}), using unaligned segments.")
        else:
            print("Warning: Language not detected, skipping alignment.")

        # Diarization
        if has_diarization:
            print("Performing speaker diarization...")
            try:
                from whisperx.diarize import DiarizationPipeline
                print_static_progress("Diarizing", duration, 75.0)
                diarize_model = DiarizationPipeline(model_name="pyannote/speaker-diarization-3.1", token=hf_token.strip(), device=device)
                print_static_progress("Diarizing", duration, 85.0)
                diarize_segments = diarize_model(audio_file)
                print_static_progress("Diarizing", duration, 95.0)
                result = whisperx.assign_word_speakers(diarize_segments, result)
                result = resegment_by_speaker(result, detected_lang)
            except Exception as de:
                print(f"Warning: Diarization failed ({de}). Proceeding without speaker separation.")

        # Resegment long subtitles to prevent huge blocks (especially for languages like Japanese)
        if detected_lang and args.split_segments:
            result = split_long_segments(result, detected_lang, max_duration=args.max_duration, max_gap=args.max_gap)

        # Apply edge offset padding if specified (with overlap prevention)
        if args.offset_start > 0.0 or args.offset_end > 0.0:
            segments = result.get("segments", [])
            n_segments = len(segments)
            padded_starts = []
            padded_ends = []
            
            # 1. Compute initially padded values
            for i in range(n_segments):
                seg = segments[i]
                padded_starts.append(max(0.0, seg.get("start", 0.0) - args.offset_start))
                padded_ends.append(seg.get("end", 0.0) + args.offset_end)
                
            # 2. Prevent overlapping with neighbors
            for i in range(1, n_segments):
                orig_end_prev = segments[i-1].get("end", 0.0)
                orig_start_curr = segments[i].get("start", 0.0)
                
                p_end_prev = padded_ends[i-1]
                p_start_curr = padded_starts[i]
                
                if p_end_prev > p_start_curr:
                    # Overlap! Limit they meet at the midpoint of their original boundaries
                    midpoint = (orig_end_prev + orig_start_curr) / 2.0
                    padded_ends[i-1] = midpoint
                    padded_starts[i] = midpoint
                    
            # 3. Apply corrected boundaries and clip word timestamps
            for i in range(n_segments):
                seg = segments[i]
                new_start = padded_starts[i]
                new_end = padded_ends[i]
                
                if "words" in seg:
                    for w in seg["words"]:
                        if "start" in w:
                            w_start = w["start"] - args.offset_start
                            w["start"] = max(new_start, min(w_start, new_end))
                        if "end" in w:
                            w_end = w["end"] + args.offset_end
                            w["end"] = max(new_start, min(w_end, new_end))
                            
                seg["start"] = new_start
                seg["end"] = new_end

        # Write SRT
        write_srt(result["segments"], output_path)
        print(f"\nDone! SRT file saved: {output_path}")

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
