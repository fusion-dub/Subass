#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Google TTS API wrapper for Ukrainian text-to-speech using goroh.pp.ua API key.
Accepts a word/text and returns the path to the generated MP3 file.
"""

import os
import sys
import json
import base64
import hashlib
import requests
from pathlib import Path


def get_history_dir():
    """Get or create the history directory for TTS files."""
    script_dir = Path(__file__).parent
    history_dir = script_dir / "history"
    history_dir.mkdir(parents=True, exist_ok=True)
    return history_dir


def generate_filename(text):
    """Generate a unique filename based on the text content."""
    # Create a hash of the text for unique filename
    text_hash = hashlib.md5(text.encode('utf-8')).hexdigest()[:12]
    # Sanitize text for filename (first 30 chars)
    safe_text = "".join(c if c.isalnum() or c in (' ', '-', '_') else '_' for c in text)
    safe_text = safe_text[:30].strip().replace(' ', '_')
    return f"{safe_text}_{text_hash}.mp3"


def text_to_speech(text, voice_name="uk-UA-Wavenet-A", language_code="uk-UA"):
    """
    Convert text to speech using Google TTS API via goroh.pp.ua.
    
    Args:
        text (str): The text to convert to speech
        voice_name (str): Voice model name (default: uk-UA-Wavenet-A)
        language_code (str): Language code (default: uk-UA)
    
    Returns:
        str: Path to the generated MP3 file
    
    Raises:
        Exception: If the API request fails
    """
    # Get history directory
    history_dir = get_history_dir()
    
    # Generate filename
    filename = generate_filename(text)
    output_path = history_dir / filename
    
    # Check if file already exists
    if output_path.exists():
        print(f"Using cached file: {output_path}")
        return str(output_path)
    
    # Prepare API request
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
        # Make API request
        print(f"Generating speech for: {text}")
        response = requests.post(url, headers=headers, json=payload, timeout=30)
        response.raise_for_status()
        
        # Parse response
        result = response.json()
        
        if 'audioContent' not in result:
            raise Exception(f"No audio content in response: {result}")
        
        # Decode base64 audio content
        audio_data = base64.b64decode(result['audioContent'])
        
        # Save to file
        with open(output_path, 'wb') as f:
            f.write(audio_data)
        
        print(f"Successfully saved to: {output_path}")
        return str(output_path)
        
    except requests.exceptions.RequestException as e:
        raise Exception(f"API request failed: {e}")
    except Exception as e:
        raise Exception(f"Failed to generate speech: {e}")


def main():
    """Main entry point for command-line usage."""
    if len(sys.argv) < 2:
        print("Usage: python goroh_tts.py <text>")
        print("Example: python goroh_tts.py 'дорога'")
        sys.exit(1)
    
    text = " ".join(sys.argv[1:])
    
    try:
        output_path = text_to_speech(text)
        print(output_path)
        return 0
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
