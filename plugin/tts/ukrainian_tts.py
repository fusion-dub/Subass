#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Google TTS API wrapper for Ukrainian text-to-speech.
Supports both the Goroh (v1) backend and the direct Gemini Beta (v1beta1) backend.
"""

import os
import sys
import json
import base64
import hashlib
import requests
import struct
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


def get_history_dir():
    """Get or create the history directory for TTS files."""
    script_dir = Path(__file__).parent
    history_dir = script_dir / "history"
    history_dir.mkdir(parents=True, exist_ok=True)
    return history_dir


def generate_filename(text, voice_name="goroh"):
    """Generate a unique filename based on the text content and voice."""
    # Create a hash of the text for unique filename
    content_to_hash = f"{text}_{voice_name}"
    text_hash = hashlib.md5(content_to_hash.encode('utf-8')).hexdigest()[:12]
    # Sanitize text for filename (first 20 chars)
    safe_text = "".join(c if c.isalnum() or c in (' ', '-', '_') else '_' for c in text)
    safe_text = safe_text[:20].strip().replace(' ', '_')
    # Use different extension for Gemini (WAV) vs Goroh (MP3)
    ext = "wav" if voice_name != "goroh" else "mp3"
    return f"{safe_text}_{voice_name}_{text_hash}.{ext}"


def gemini_tts(text, api_key, voice_name="Achird"):
    """
    Convert text to speech using the Generative Language API (Gemini Native TTS).
    Works with AI Studio keys without manual Cloud TTS API activation.
    """
    # Get history directory
    history_dir = get_history_dir()
    filename = generate_filename(text, voice_name)
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


def goroh_tts(text, voice_name="uk-UA-Wavenet-A", language_code="uk-UA"):
    """
    Convert text to speech using Google TTS API via goroh.pp.ua (Existing logic).
    """
    history_dir = get_history_dir()
    filename = generate_filename(text, "goroh")
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
        'X-Goog-Api-Key': 'AIzaSyBlmX67rfIxwUJ8NplW99uu7uxIag7WV2Q',
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


def text_to_speech(text, voice_name=None, gemini_api_key=None):
    """
    Main function to choose between Gemini and Goroh backends.
    """
    if gemini_api_key:
        return gemini_tts(text, gemini_api_key, voice_name or "Achird")
    else:
        return goroh_tts(text, voice_name or "uk-UA-Wavenet-A")


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Goroh & Gemini TTS Wrapper")
    parser.add_argument("text", help="Text to synthesize")
    parser.add_argument("--voice", help="Voice name (default: Achird for Gemini, uk-UA-Wavenet-A for Goroh)")
    parser.add_argument("--gemini-key", help="Gemini API Key (if provided, uses Gemini Beta endpoint)")
    
    args = parser.parse_args()
    
    try:
        output_path = text_to_speech(args.text, voice_name=args.voice, gemini_api_key=args.gemini_key)
        print(output_path)
        return 0
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
