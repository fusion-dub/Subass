import sys
import os
import subprocess
import shutil
import argparse
import math
import json

# Check if dependencies are installed
try:
    import whisper
    import numpy as np
except ImportError:
    print("\n[AI] Необхідні бібліотеки (openai-whisper, numpy) не знайдені.")
    print("Для роботи цієї функції потрібне програмне забезпечення 'openai-whisper' та 'numpy'.")
    print("УВАГА: Сама AI-модель (вага ~1.6 ГБ) буде завантажена окремо пізніше.")
    print("Якщо ви хочете встановити бібліотеки зараз, введіть 'install' та натисніть Enter.")
    
    choice = input("\n> ").strip().lower()
    if choice == "install":
        print("\n[AI] Встановлення залежностей... (Це може зайняти деякий час)")
        try:
            # Try installing with --break-system-packages for Homebrew/system Python environments
            subprocess.check_call([sys.executable, "-m", "pip", "install", "openai-whisper", "numpy", "--break-system-packages"])
            print("[AI] Бібліотеки успішно встановлені!")
            import whisper 
            import numpy as np
        except subprocess.CalledProcessError:
            try:
                subprocess.check_call([sys.executable, "-m", "pip", "install", "openai-whisper", "numpy"])
                print("[AI] Бібліотеки успішно встановлені!")
                import whisper
                import numpy as np
            except:
                print("[AI] Помилка встановлення. Спробуйте вручну: 'pip install openai-whisper numpy --break-system-packages'")
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

def get_rms(samples):
    """Calculates RMS energy of audio samples."""
    if len(samples) == 0: return 0
    return np.sqrt(np.mean(samples**2))

def main():
    print("\n[AI] Ініціалізація двигуна Whisper AI...")
    
    # 'turbo' is an alias for large-v3-turbo in the latest openai-whisper
    target_model = "turbo"
    model_marker_path = os.path.join(os.path.dirname(__file__), ".whisper_turbo_installed")
    
    if not os.path.exists(model_marker_path):
        print(f"\n[AI] Для цієї функції потрібна модель Whisper '{target_model}'.")
        print("УВАГА: Розмір моделі складає приблизно 1.6 ГБ.")
        print("При першому запуску вона буде завантажена на ваш комп'ютер.")
        print("Це може зайняти певний час залежно від швидкості інтернету.")
        print("\nВведіть 'install', щоб підтвердити завантаження та продовжити.")
        
        choice = input("\n> ").strip().lower()
        if choice != "install":
            print("[AI] Операцію скасовано.")
            sys.exit(0)

    # Argument parsing
    parser = argparse.ArgumentParser(description="Transcribe audio using OpenAI Whisper and detect non-speech events.")
    parser.add_argument("audio_file", help="Path to the audio file to transcribe.")
    parser.add_argument("--offset", type=float, default=0.0, help="Source offset in seconds.")
    parser.add_argument("--length", type=float, default=None, help="Length of the item in seconds.")
    parser.add_argument("--start_time", type=float, default=0.0, help="Project start time for the item.")
    args = parser.parse_args()
    
    audio_path = args.audio_file
    if not os.path.exists(audio_path):
        print(f"\n[AI] Помилка: Файл не знайдено: {audio_path}")
        sys.exit(1)

    # 1. Prepare Cache directory and filename
    script_dir = os.path.dirname(os.path.abspath(__file__))
    cache_dir = os.path.join(script_dir, "cache")
    if not os.path.exists(cache_dir):
        os.makedirs(cache_dir)
        
    print(f"[AI] Отримання та нормалізація аудіо...")
    try:
        audio = whisper.load_audio(audio_path)
        
        # Crop audio based on offset and length
        sample_rate = whisper.audio.SAMPLE_RATE
        start_sample = int(args.offset * sample_rate)
        
        if args.length:
            end_sample = start_sample + int(args.length * sample_rate)
            audio = audio[start_sample:end_sample]
        elif start_sample > 0:
            audio = audio[start_sample:]
            
        duration_ms = int((len(audio) / sample_rate) * 1000)
        
        # Audio Normalization (Percentile)
        # We use 99.8 to avoid being tricked by single clicks
        max_val = np.max(np.abs(audio))
        peak_val = np.percentile(np.abs(audio), 99.8) if len(audio) > 0 else 0
        
        if peak_val > 0.0001:
            audio = audio / peak_val
            audio = np.clip(audio, -1.0, 1.0)
            print(f"[AI] Аудіо нормалізовано (пік був {max_val:.2f}, 99.8% поріг: {peak_val:.2f}).")
        else:
             print(f"[AI] УВАГА: Аудіо занадто тихе або порожнє!")
            
    except Exception as e:
        print(f"[AI] Помилка обробки аудіо (Numpy/Load): {e}")
        sys.exit(1)

    base_name = os.path.basename(audio_path)
    # Cache key now includes offset and length to ensure unique analysis for different trims
    cache_key = f"{base_name}_{duration_ms}_off{args.offset:.2f}_len{args.length or 'full'}"
    cache_file = os.path.join(cache_dir, f"whisper_{cache_key}.json")
    # 2. Check Cache
    result = None
    if os.path.exists(cache_file):
        print(f"[AI] Знайдено кешований результат для: {os.path.basename(cache_file)}")
        try:
            with open(cache_file, "r", encoding="utf-8") as f:
                result = json.load(f)
        except Exception as e:
            print(f"[AI] Помилка читання кешу: {e}. Перезапуск транскрибації...")
    if result is None:
        print(f"[AI] Стартуємо аналіз (кеш ігнорується для точності детекції)...")

    if not result:
        print(f"[AI] Завантаження моделі '{target_model}' (~1.6 ГБ)...")
        try:
            device = "cpu"
            try:
                import torch
                if torch.cuda.is_available():
                    device = "cuda"
                elif torch.backends.mps.is_available():
                    device = "mps"
            except:
                pass
                
            print(f"[AI] Використовується пристрій: {device.upper()}")
            model = whisper.load_model(target_model, device=device)
            
            if not os.path.exists(model_marker_path):
                with open(model_marker_path, "w") as f:
                    f.write("installed")
                    
            print(f"[AI] Модель '{target_model}' успішно завантажена!")
            
        except Exception as e:
            print(f"\n[AI] Помилка завантаження моделі: {e}")
            sys.exit(1)

        print(f"[AI] Аналіз файлу (це може зайняти час): {base_name}...")
        try:
            use_fp16 = True if device == "cuda" else False 
            
            try:
                result = model.transcribe(
                    audio, 
                    verbose=False, 
                    fp16=use_fp16, 
                    word_timestamps=True,
                    initial_prompt="[breath], [laughter], [sigh], [noise], [отдышка], [вдих], [сміх], [зітхання], [шум]."
                ) 
            except Exception as e:
                # Fallback to CPU if MPS fails with float64 error (common on Mac)
                if "MPS" in str(e) and "float64" in str(e):
                    print("[AI] Попередження: MPS не підтримує високу точність (float64) для полів 'word_timestamps'.")
                    print("[AI] Перемикання на CPU для забезпечення точності...")
                    model = whisper.load_model(target_model, device="cpu")
                    result = model.transcribe(
                        audio, 
                        verbose=False, 
                        fp16=False, 
                        word_timestamps=True,
                        initial_prompt="[breath], [laughter], [sigh], [noise], [отдышка], [вдих], [сміх], [зітхання], [шум]."
                    )
                else:
                    raise e
            
            # Save to cache
            with open(cache_file, "w", encoding="utf-8") as f:
                json.dump(result, f, ensure_ascii=False, indent=2)
            print(f"[AI] Результат збережено в кеш: {os.path.basename(cache_file)}")
            
        except Exception as e:
            print(f"[AI] Помилка транскрибації: {e}")
            sys.exit(1)

    # --- Post-processing (High Sensitivity Analysis) ---
    print(f"[AI] Пост-обробка даних (підвищена чутливість)...")
    
    detected_events = []
    # Expanded fillers list with more variations
    fillers = ["е-е", "а-а", "м-м", "гм", "ну", "цей", "типу", "ээ", "мм", "аа", "ээм", "уум", "хмм"]
    sound_markers = ["...", "..", ".", "!", "?", "h", "uh", "um", "ah", "っ", "(", ")", "[", "]", "*"] 
    non_speech_tokens = ["[дихання]", "[зітхання]", "[сміх]", "[шум]", "[тиша]", "[breathing]", "[sigh]", "[laughter]", "[noise]"]
    
    print(f"[AI] Отримано {len(result['segments'])} сегментів від Whisper.")
    
    for i, segment in enumerate(result["segments"]):
        start = segment["start"]
        end = segment["end"]
        duration = end - start
        text = segment["text"].strip().lower()
        no_speech_prob = segment.get("no_speech_prob", 0)
        avg_logprob = segment.get("avg_logprob", 0)
        compression_ratio = segment.get("compression_ratio", 0)
        
        # Calculate RMS energy for the segment
        start_sample = int(start * whisper.audio.SAMPLE_RATE)
        end_sample = int(end * whisper.audio.SAMPLE_RATE)
        segment_samples = audio[start_sample:end_sample]
        rms = get_rms(segment_samples)
        
        # Heuristics for detection (Maximum sensitivity)
        is_low_energy = rms < 0.0001 # Near-noise threshold
        is_hallucination = compression_ratio > 3.5 # Very tolerant
        
        # Check if text looks like a filler
        is_filler = any(f in text for f in fillers) or text.strip() in fillers
        
        # Check if text has sound markers
        has_marker = any(m in text for m in sound_markers)

        event_type = "speech"
        
        # 1. High-probability non-speech (Breaths, Silences, Grunts)
        if no_speech_prob > 0.15: # Very low threshold (was 0.25)
            if is_low_energy:
                continue # Only ignore pure silence
            if is_hallucination:
                event_type = "noise_hallucination"
            else:
                event_type = "vocal_sound_prob"
                 
        # 2. Check for explicit non-speech tokens
        for token in non_speech_tokens:
            if token in text:
                event_type = "vocal_sound"
                break
                
        # 3. Filler check (Robust substring matching)
        if is_filler:
            event_type = "filler"
            
        # 4. "Breath" & Small sounds Heuristic
        if event_type == "speech":
            # If very short OR has markers OR low confidence
            if (duration < 1.5 and (avg_logprob < -0.6 or has_marker)) and not is_low_energy:
                event_type = "potential_sound"
            elif avg_logprob < -1.2 and not is_low_energy:
                event_type = "uncertain_noise"

        # Filter out obvious trash, but keep everything else
        if event_type == "noise_hallucination" and avg_logprob < -1.8:
            continue

        # Debug segments that were categorized as non-speech
        if i < 20 and event_type != "speech":
            print(f"  - Seg {i}: '{text}', no_speech_p: {no_speech_prob:.3f}, logp: {avg_logprob:.3f}, rms: {rms:.5f} => {event_type}")

        # Add event if not standard speech
        if event_type != "speech":
            detected_events.append({
                "start_sec": start,
                "end_sec": end,
                "text": segment["text"].strip(),
                "type": event_type,
                "rms": rms
            })

    print(f"[AI] Всього виявлено звукових подій (сегменти): {len(detected_events)}")

    # 5. Gap Analysis (Catching breaths and sounds Whisper skips entirely)
    # This is often where the most important non-speech sounds are hiding
    print(f"[AI] Аналіз пауз та пропущених ділянок...")
    all_segments = sorted(result.get("segments", []), key=lambda x: x["start"])
    
    gap_regions = []
    if not all_segments:
        # If Whisper found NOTHING, analyze the entire duration as one big gap
        gap_regions.append((0.0, len(audio) / whisper.audio.SAMPLE_RATE))
    else:
        # Start and end of file
        if all_segments[0]["start"] > 0.3:
            gap_regions.append((0.0, all_segments[0]["start"]))
        
        for i in range(len(all_segments) - 1):
            prev_end = all_segments[i]["end"]
            next_start = all_segments[i+1]["start"]
            if next_start - prev_end > 0.2:
                gap_regions.append((prev_end, next_start))
        
        file_duration = len(audio) / whisper.audio.SAMPLE_RATE
        if file_duration - all_segments[-1]["end"] > 0.3:
            gap_regions.append((all_segments[-1]["end"], file_duration))

    gap_events = []
    print(f"[AI] Перевірка {len(gap_regions)} підозрілих ділянок...")
    for g_start, g_end in gap_regions:
        start_sample = int(g_start * whisper.audio.SAMPLE_RATE)
        end_sample = int(g_end * whisper.audio.SAMPLE_RATE)
        gap_samples = audio[start_sample:end_sample]
        
        if len(gap_samples) > 200: # Min samples to check
            gap_rms = get_rms(gap_samples)
            # If gap has significant energy, split it into chunks to find the exact sound
            if gap_rms > 0.0003:
                # Add as a general detection area
                gap_events.append({
                    "start_sec": g_start,
                    "end_sec": g_end,
                    "text": "...",
                    "type": "gap_sound_detected",
                    "rms": gap_rms
                })

    detected_events.extend(gap_events)
    print(f"[AI] Знайдено додатково в паузах: {len(gap_events)}")

    # --- Final Processing ---
    # Merge adjacent short sounds only if they are very close (< 100ms)
    detected_events.sort(key=lambda x: x["start_sec"])
    merged_events = []
    if detected_events:
        curr = detected_events[0]
        for next_ev in detected_events[1:]:
            # If gap < 0.1s AND types are similar, merge
            gap = next_ev["start_sec"] - curr["end_sec"]
            if gap < 0.1:
                curr["end_sec"] = next_ev["end_sec"]
            else:
                merged_events.append(curr)
                curr = next_ev
        merged_events.append(curr)
    
    detected_events = merged_events
    print(f"[AI] Аналіз завершено. Фінальна кількість звуків: {len(detected_events)}")

    # --- Generate SRT ---
    actor_name = "Можливі звуки"
    srt_lines = []
    project_start = args.start_time
    for i, event in enumerate(detected_events):
        # Shift timestamps into project-global time
        s_start = event['start_sec'] + project_start
        s_end = event['end_sec'] + project_start
        
        srt_lines.append(f"{i+1}")
        srt_lines.append(f"{format_srt_timestamp(s_start)} --> {format_srt_timestamp(s_end)}")
        srt_lines.append(f"{actor_name}")
        srt_lines.append("")

    # Save temporary SRT
    temp_srt_path = cache_file.replace(".json", ".srt")
    with open(temp_srt_path, "w", encoding="utf-8") as f:
        f.write("\n".join(srt_lines))

    # Output for REAPER
    print("\n---SRT_PATH_START---")
    print(temp_srt_path)
    print("---SRT_PATH_END---")
    print(f"[AI] Готово! Результати збережені у REAPER.")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"\n[КРИТИЧНА ПОМИЛКА]: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
