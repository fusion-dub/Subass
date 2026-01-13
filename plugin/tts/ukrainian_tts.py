#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Google TTS API wrapper for Ukrainian text-to-speech.
Supports both the Goroh (v1) backend and the direct Gemini Beta (v1beta1) backend.
"""

import re
import sys
import base64
import hashlib
import requests
import time
import struct
import platform
import subprocess
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
    
    try:
        print(f"Generating ElevenLabs ({display_name}) speech for: {text[:50]}...")
        response = requests.post(url, json=payload, headers=headers, timeout=30)
        response.raise_for_status()
        
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
        "Vira": "nCqaTnIbLdME87OuQaZY"
    }
    
    # 1. Try ElevenLabs if it's an ElevenLabs voice and key is present
    if voice_name in eleven_voices:
        if eleven_api_key:
            try:
                return elevenlabs_tts(text, eleven_api_key, eleven_voices[voice_name], voice_name)
            except Exception as e:
                print(f"Warning: ElevenLabs TTS failed, falling back to Goroh: {e}")
        else:
            print(f"Warning: ElevenLabs voice '{voice_name}' requested but ElevenLabs API key is missing. Falling back to Goroh.")

    # Strategy: Gemini -> Goroh -> System TTS
    gemini_voices = ["Alnilam", "Charon", "Aoede"]
    
    # 1. Try Gemini if key is present
    if gemini_api_key:
        try:
            # If the requested voice is not a Gemini voice, use Alnilam as default for this backend
            gem_voice = voice_name if voice_name in gemini_voices else "Alnilam"
            return gemini_tts(text, gemini_api_key, gem_voice)
        except Exception as e:
            print(f"Warning: Gemini TTS failed, falling back to Goroh: {e}")
    elif voice_name in gemini_voices:
        print(f"Warning: Gemini voice '{voice_name}' requested but Gemini API key is missing. Falling back to Goroh.")

    # 2. Try Goroh (Internet-dependent, no key)
    # Ensure we use a valid Goroh voice (if the current one is Gemini or ElevenLabs, use Wavenet-A)
    goroh_voice = voice_name
    if goroh_voice in gemini_voices or goroh_voice in eleven_voices or goroh_voice == "System":
        goroh_voice = "uk-UA-Wavenet-A"
    
    try:
        return goroh_tts(text, goroh_voice or "uk-UA-Wavenet-A")
    except Exception as e:
        print(f"Warning: Goroh TTS failed, falling back to System TTS: {e}")
    
    # 3. Last resort: System TTS (Offline, OS-dependent)
    # Use a descriptive voice name for fallback if possible
    sys_voice = voice_name
    if sys_voice in gemini_voices or sys_voice == "uk-UA-Wavenet-A" or sys_voice in eleven_voices:
        # We append _System to the name so we know it's a system voice representing that character
        sys_voice = f"{voice_name}_System"
        
    return system_tts(text, sys_voice)


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Goroh & Gemini TTS Wrapper")
    parser.add_argument("text", help="Text to synthesize")
    parser.add_argument("--voice", help="Voice name (Alnilam, Yaroslava, uk-UA-Wavenet-A, etc.)")
    parser.add_argument("--gemini-key", help="Gemini API Key")
    parser.add_argument("--eleven-key", help="ElevenLabs API Key")
    
    args = parser.parse_args()
    
    try:
        gemini_key = args.gemini_key.strip() if args.gemini_key else None
        eleven_key = args.eleven_key.strip() if args.eleven_key else None
        output_path = text_to_speech(args.text, voice_name=args.voice, gemini_api_key=gemini_key, eleven_api_key=eleven_key)
        print(output_path)
        return 0
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
