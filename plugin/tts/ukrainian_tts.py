#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Google TTS API wrapper for Ukrainian text-to-speech.
Supports both the Goroh (v1) backend and the direct Gemini Beta (v1beta1) backend.
"""

import re
import os
import sys
import time
import base64
import struct
import hashlib
import platform
import subprocess

def bootstrap():
    """Automatically installs dependencies if they are missing."""
    try:
        import requests
    except ImportError:
        print("--- Subass TTS: First Time Setup ---")
        print("Dependencies missing. Attempting to install 'requests'...")

        packages = ["requests"]

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
                    f"Please try running manually: {sys.executable} -m pip install requests"
                )
                return False

        print("\nDependencies installed successfully!")

        # Invalidate caches so the new package can be found
        import importlib
        importlib.invalidate_caches()

        # Also refresh site-packages for the current process
        import site
        from importlib import reload
        reload(site)

        return True
    return False

# Run bootstrap before other imports
bootstrap()

import requests
from pathlib import Path


def add_wav_header(pcm_data, sample_rate=24000, channels=1, bit_depth=16):
    """Adds a standard WAV header to raw PCM data."""
    num_samples = len(pcm_data) // (bit_depth // 8)
    data_size = num_samples * channels * (bit_depth // 8)
    
    # RIFF header
    header = b'RIFF'
    header += struct.pack('<I', 36 + data_size)
    header += b'WAVE'
    
    # fmt chunk
    header += b'fmt '
    header += struct.pack('<I', 16) # fmt chunk size
    header += struct.pack('<H', 1)  # PCM format
    header += struct.pack('<H', channels)
    header += struct.pack('<I', sample_rate)
    header += struct.pack('<I', sample_rate * channels * (bit_depth // 8)) # Byte rate
    header += struct.pack('<H', channels * (bit_depth // 8)) # Block align
    header += struct.pack('<H', bit_depth)
    
    # data chunk
    header += b'data'
    header += struct.pack('<I', data_size)
    
    return header + pcm_data


def cleanup_old_files(history_dir, days=7):
    """Delete files in the history directory older than specified days."""
    try:
        now = time.time()
        cutoff = now - (days * 24 * 60 * 60)
        
        for file_path in history_dir.glob("*"):
            if file_path.is_file():
                file_time = file_path.stat().st_mtime
                if file_time < cutoff:
                    try:
                        file_path.unlink()
                        print(f"Cleaned up old TTS file: {file_path.name}")
                    except Exception as e:
                        print(f"Warning: Failed to delete {file_path.name}: {e}")
    except Exception as e:
        print(f"Warning: Cleanup failed: {e}")


def get_history_dir():
    """Get or create the history directory for TTS files."""
    script_dir = Path(__file__).parent
    history_dir = script_dir / "history"
    history_dir.mkdir(parents=True, exist_ok=True)
    
    # Clean up old files when accessing the directory
    cleanup_old_files(history_dir)
    
    return history_dir


def generate_filename(text, voice_name, ext):
    """Generate a unique filename based on the text content and voice."""
    # Create a hash of the text for unique filename
    content_to_hash = f"{text}_{voice_name}"
    text_hash = hashlib.md5(content_to_hash.encode('utf-8')).hexdigest()[:12]
    # Sanitize text for filename (first 20 chars)
    safe_text = "".join(c if c.isalnum() or c in (' ', '-', '_') else '_' for c in text)
    safe_text = safe_text[:20].strip().replace(' ', '_')
    return f"{safe_text}_{voice_name}_{text_hash}.{ext}"


def gemini_tts(text, api_key, voice_name="Alnilam"):
    """
    Convert text to speech using the Generative Language API (Gemini Native TTS).
    Works with AI Studio keys without manual Cloud TTS API activation.
    """
    # Get history directory
    history_dir = get_history_dir()
    filename = generate_filename(text, voice_name, "wav")
    output_path = history_dir / filename
    
    # Check if file already exists
    if output_path.exists():
        return str(output_path.absolute())
    
    # Use the Generative Language API endpoint (AI Studio)
    # The correct model name for AI Studio keys is gemini-2.5-flash-preview-tts
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-tts:generateContent?key={api_key}"
    
    headers = {
        'Content-Type': 'application/json'
    }
    
    payload = {
        "system_instruction": {
            "parts": [{
                "text": "This is Ukrainian language. Please respect all stress marks in the text for correct pronunciation."
            }]
        },
        "contents": [{
            "parts": [{
                "text": text
            }]
        }],
        "generationConfig": {
            "responseModalities": ["AUDIO"],
            "speechConfig": {
                "voiceConfig": {
                    "prebuiltVoiceConfig": {
                        "voiceName": voice_name
                    }
                }
            }
        }
    }
    
    response = None
    try:
        print(f"Generating Gemini Native speech for: {text[:50]}...")
        response = requests.post(url, headers=headers, json=payload, timeout=30)
        response.raise_for_status()
        
        result = response.json()
        
        # Extract audio from the response
        # Structure: candidates[0].content.parts[0].inline_data.data
        try:
            audio_base64 = result['candidates'][0]['content']['parts'][0]['inlineData']['data']
            audio_raw = base64.b64decode(audio_base64)
            # Add WAV header (Gemini 2.x Native TTS typically outputs 24kHz mono)
            audio_data = add_wav_header(audio_raw, sample_rate=24000)
        except (KeyError, IndexError) as e:
            raise Exception(f"Unexpected response structure: {e}\nResponse: {result}")
        
        with open(output_path, 'wb') as f:
            f.write(audio_data)
            
        return str(output_path.absolute())
        
    except requests.exceptions.RequestException as e:
        # Handle specific quota errors or 403s with helpful info
        error_msg = str(e)
        if response is not None:
            try:
                error_json = response.json()
                error_msg = error_json.get('error', {}).get('message', str(e))
            except:
                pass
        raise Exception(f"Gemini Native API failed: {error_msg}")
    except Exception as e:
        if output_path.exists():
            output_path.unlink()
        raise Exception(f"Failed to generate Gemini speech: {e}")


def fetch_goroh_api_key():
    """
    Fetches the latest X-Goog-Api-Key from goroh.pp.ua site scripts.
    """
    js_url = "https://goroh.pp.ua/scripts/site.min.js"
    headers = {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:146.0) Gecko/20100101 Firefox/146.0'
    }
    try:
        print(f"Fetching latest Goroh API key from {js_url}...")
        response = requests.get(js_url, headers=headers, timeout=10)
        response.raise_for_status()
        
        # Look for the key assignment (variable 't' before 'n={languageCode:"uk-UA"}')
        match = re.search(r't="([^"]+)",n=\{languageCode:"uk-UA"', response.text)
        if match:
            new_key = match.group(1)
            print(f"Found new Goroh API key: {new_key[:10]}...")
            return new_key
    except Exception as e:
        print(f"Warning: Failed to fetch Goroh API key: {e}")
    return None


def goroh_tts(text, voice_name="uk-UA-Wavenet-A", language_code="uk-UA"):
    """
    Convert text to speech using Google TTS API via goroh.pp.ua (Existing logic).
    """
    history_dir = get_history_dir()
    filename = generate_filename(text, voice_name, "mp3")
    output_path = history_dir / filename
    
    if output_path.exists():
        return str(output_path.absolute())
    
    url = "https://texttospeech.googleapis.com/v1/text:synthesize"
    
    headers = {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:146.0) Gecko/20100101 Firefox/146.0',
        'Accept': '*/*',
        'Accept-Language': 'en-US,en;q=0.5',
        'Accept-Encoding': 'gzip, deflate, br, zstd',
        'Content-Type': 'application/json',
        'Referer': 'https://goroh.pp.ua/',
        'X-Goog-Api-Key': 'AIzaSyCe32t3cVf9POCGO5Sn-6TP4HKCjvC_wQk',
        'Origin': 'https://goroh.pp.ua',
        'Sec-Fetch-Dest': 'empty',
        'Sec-Fetch-Mode': 'cors',
        'Sec-Fetch-Site': 'cross-site',
        'Connection': 'keep-alive',
        'Priority': 'u=0',
        'TE': 'trailers'
    }
    
    payload = {
        "input": {
            "text": text
        },
        "voice": {
            "languageCode": language_code,
            "name": voice_name
        },
        "audioConfig": {
            "audioEncoding": "MP3"
        }
    }
    
    try:
        print(f"Generating Goroh speech for: {text[:50]}...")
        response = requests.post(url, headers=headers, json=payload, timeout=30)
        
        # If 400 Client Error, maybe X-Goog-Api-Key changed
        if response.status_code == 400:
            print("Goroh 400 Error. Attempting to refresh API key...")
            new_key = fetch_goroh_api_key()
            if new_key and new_key != headers['X-Goog-Api-Key']:
                headers['X-Goog-Api-Key'] = new_key
                print("Retrying Goroh request with new key...")
                response = requests.post(url, headers=headers, json=payload, timeout=30)
        
        response.raise_for_status()
        
        result = response.json()
        
        if 'audioContent' not in result:
            raise Exception(f"No audio content in response: {result}")
        
        audio_data = base64.b64decode(result['audioContent'])
        
        with open(output_path, 'wb') as f:
            f.write(audio_data)
        
        return str(output_path.absolute())
        
    except requests.exceptions.RequestException as e:
        raise Exception(f"Goroh API request failed: {e}")
    except Exception as e:
        if output_path.exists():
            output_path.unlink()
        raise Exception(f"Failed to generate Goroh speech: {e}")


def system_tts(text, voice_name=None):
    """
    Generate speech using system-native TTS (say on macOS, PowerShell on Windows).
    """
    history_dir = get_history_dir()
    # Use a descriptive voice name for the filename
    sys_voice = voice_name or "System"
    filename = generate_filename(text, sys_voice, "wav")
    output_path = history_dir / filename
    
    if output_path.exists():
        return str(output_path.absolute())
    
    current_os = platform.system()
    print(f"Generating System TTS ({current_os}) for: {text[:50]}...")
    
    try:
        if current_os == "Darwin": # macOS
            # Try to use Lesya (standard Ukrainian voice) if not specified
            cmd_voice = voice_name or "Lesya"
            # We use --data-format=LEI16@24000 to ensure a standard WAV-compatible PCM format
            cmd = ["say", "-v", cmd_voice, "-o", str(output_path), "--data-format=LEI16@24000", text]
            subprocess.run(cmd, check=True)
            
        elif current_os == "Windows":
            # Use PowerShell to access System.Speech and look for a Ukrainian voice
            ps_script = f"""
            Add-Type -AssemblyName System.Speech
            $synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
            $voice = $synth.GetInstalledVoices() | Where-Object {{ $_.VoiceInfo.Culture.Name -eq 'uk-UA' }} | Select-Object -First 1
            if ($voice) {{ $synth.SelectVoice($voice.VoiceInfo.Name) }}
            $synth.SetOutputToWaveFile('{output_path}')
            $synth.Speak('{text.replace("'", "''")}')
            $synth.Dispose()
            """
            subprocess.run(["powershell", "-Command", ps_script], check=True)
        else:
            raise Exception(f"System TTS not supported on {current_os}")
            
        return str(output_path.absolute())
        
    except Exception as e:
        if output_path.exists():
            output_path.unlink()
        raise Exception(f"System TTS failed: {e}")


def get_eleven_voices(api_key):
    """
    Fetch and return all available voices from ElevenLabs.
    """
    url = "https://api.elevenlabs.io/v1/voices"
    headers = {"xi-api-key": api_key}
    try:
        response = requests.get(url, headers=headers, timeout=10)
        if response.status_code == 200:
            return response.json().get('voices', [])
    except:
        pass
    return []


def elevenlabs_tts(text, api_key, voice_id, voice_name=None):
    """
    Convert text to speech using ElevenLabs API.
    """
    history_dir = get_history_dir()
    # Use human readable name if available, otherwise voice_id as a fallback
    display_name = voice_name or voice_id
    filename = generate_filename(text, display_name, "mp3")
    output_path = history_dir / filename
    
    if output_path.exists():
        return str(output_path.absolute())
    
    url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}"
    
    headers = {
        "Accept": "audio/mpeg",
        "Content-Type": "application/json",
        "xi-api-key": api_key
    }
    
    payload = {
        "text": text,
        "model_id": "eleven_multilingual_v2",
        "voice_settings": {
            "stability": 0.5,
            "similarity_boost": 0.75
        }
    }
    
    response = None
    try:
        print(f"Generating ElevenLabs ({display_name}) speech for: {text[:50]}...")
        response = requests.post(url, json=payload, headers=headers, timeout=30)
        
        if response.status_code != 200:
            error_data = response.text
            try:
                error_data = response.json()
            except:
                pass
            
            # If voice not found, helpful to list available ones
            detail = ""
            if response.status_code == 404:
                voices = get_eleven_voices(api_key)
                if voices:
                    voice_list = "\n".join([f"  - {v['name']}: {v['voice_id']}" for v in voices if 'name' in v and 'voice_id' in v])
                    detail = f"\nAvailable voices for your key:\n{voice_list}"
                else:
                    detail = "\nCould not fetch voice list (check API key)."
            
            raise Exception(f"ElevenLabs API returned {response.status_code}: {error_data}{detail}")
            
        with open(output_path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=1024):
                if chunk:
                    f.write(chunk)
                    
        return str(output_path.absolute())
    except Exception as e:
        if output_path.exists():
            output_path.unlink()
        raise Exception(f"ElevenLabs TTS failed: {e}")


def text_to_speech(text, voice_name=None, gemini_api_key=None, eleven_api_key=None):
    # 0. If no voice is selected, use System TTS directly as requested
    if voice_name == "System":
        return system_tts(text)

    # ElevenLabs IDs mapping
    eleven_voices = {
        "Yaroslava": "0ZQZuw8Sn4cU0rN1Tm2K", 
        "Anton": "GVRiwBELe0czFUAJj0nX",
    }
    
    # 1. Try ElevenLabs if it's an ElevenLabs voice
    if voice_name in eleven_voices:
        if eleven_api_key:
            return elevenlabs_tts(text, eleven_api_key, eleven_voices[voice_name], voice_name)
        else:
            raise Exception(f"ElevenLabs voice '{voice_name}' requested but ElevenLabs API key is missing.")

    # 1. Try Gemini if it's a Gemini voice
    gemini_voices = ["Alnilam", "Charon", "Aoede"]
    if voice_name in gemini_voices:
        if gemini_api_key:
            return gemini_tts(text, gemini_api_key, voice_name)
        else:
            raise Exception(f"Gemini voice '{voice_name}' requested but Gemini API key is missing.")
    
    # 2. Try Gemini if key is present (even if generic voice)
    if gemini_api_key:
        try:
            return gemini_tts(text, gemini_api_key, "Alnilam")
        except Exception as e:
            print(f"Warning: Gemini TTS fallback failed: {e}")

    # 3. Try Goroh (Internet-dependent, no key)
    # Ensure we use a valid Goroh voice
    goroh_voice = voice_name
    if goroh_voice in gemini_voices or goroh_voice in eleven_voices or goroh_voice == "System":
        goroh_voice = "uk-UA-Wavenet-A"
    
    try:
        return goroh_tts(text, goroh_voice or "uk-UA-Wavenet-A")
    except Exception as e:
        print(f"Warning: Goroh TTS failed: {e}")
    
    # 4. Last resort: System TTS
    return system_tts(text)


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Goroh & Gemini TTS Wrapper")
    parser.add_argument("text", nargs="?", help="Text to synthesize (optional if --file is used)")
    parser.add_argument("--file", help="Path to a text file to read content from")
    parser.add_argument("--voice", help="Voice name (Alnilam, Yaroslava, uk-UA-Wavenet-A, etc.)")
    parser.add_argument("--gemini-key", help="Gemini API Key")
    parser.add_argument("--eleven-key", help="ElevenLabs API Key")
    
    args = parser.parse_args()
    
    try:
        input_text = args.text
        if args.file:
            if not os.path.exists(args.file):
                print(f"Error: Input file not found: {args.file}", file=sys.stderr)
                return 1
            with open(args.file, "r", encoding="utf-8") as f:
                input_text = f.read()
        
        if not input_text or not input_text.strip():
            print("Error: No text provided for synthesis", file=sys.stderr)
            return 1
            
        gemini_key = args.gemini_key.strip() if args.gemini_key else None
        eleven_key = args.eleven_key.strip() if args.eleven_key else None
        output_path = text_to_speech(input_text, voice_name=args.voice, gemini_api_key=gemini_key, eleven_api_key=eleven_key)
        print(output_path)
        return 0
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
