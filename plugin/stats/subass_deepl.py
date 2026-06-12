#!/usr/bin/env python3
"""
subass_deepl.py — DeepL API Key Validation and Helper for Subass Notes

Usage:
    python3 subass_deepl.py --key KEY --check-key
    python3 subass_deepl.py --key-file key.txt --check-key
    python3 subass_deepl.py --key-file key.txt --translate-file payload.json --target-lang UK
"""

import argparse
import json
import sys
import urllib.request
import urllib.error

def check_deepl_key(key):
    key = key.strip()
    if not key:
        raise ValueError("API key is empty")

    # Determine endpoint based on key suffix
    # DeepL Free API keys end with ":fx", Pro keys do not
    if key.endswith(":fx"):
        url = "https://api-free.deepl.com/v2/usage"
        plan = "Free"
    else:
        url = "https://api.deepl.com/v2/usage"
        plan = "Pro"

    req = urllib.request.Request(
        url,
        headers={
            "Authorization": f"DeepL-Auth-Key {key}",
            "User-Agent": "Subass-DeepL/1.0",
        },
        method="GET",
    )

    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            if resp.status == 200:
                # Read usage data (optional, but confirms it works)
                data = json.loads(resp.read().decode("utf-8"))
                return f"Valid ({plan})"
    except urllib.error.HTTPError as e:
        code = e.code
        if code in (401, 403):
            raise RuntimeError(f"Invalid DeepL API key (HTTP {code})")
        raise RuntimeError(f"DeepL API returned HTTP {code}")
    except urllib.error.URLError as e:
        raise RuntimeError(f"Network error: {e.reason}")
    except Exception as e:
        raise RuntimeError(f"Unexpected error: {str(e)}")

def translate_texts(key, texts, target_lang):
    key = key.strip()
    if not key:
        raise ValueError("API key is empty")
    if not texts:
        return []

    # Determine endpoint based on key suffix
    if key.endswith(":fx"):
        url = "https://api-free.deepl.com/v2/translate"
    else:
        url = "https://api.deepl.com/v2/translate"

    body = {
        "text": texts,
        "target_lang": target_lang.upper()
    }
    body_bytes = json.dumps(body, ensure_ascii=False).encode("utf-8")

    req = urllib.request.Request(
        url,
        data=body_bytes,
        headers={
            "Authorization": f"DeepL-Auth-Key {key}",
            "Content-Type": "application/json",
            "User-Agent": "Subass-DeepL/1.0",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            if resp.status == 200:
                data = json.loads(resp.read().decode("utf-8"))
                return [t["text"] for t in data["translations"]]
    except urllib.error.HTTPError as e:
        code = e.code
        try:
            err_body = e.read().decode("utf-8")
        except:
            err_body = ""
        if code in (401, 403):
            raise RuntimeError(f"Invalid DeepL API key (HTTP {code})")
        raise RuntimeError(f"DeepL API returned HTTP {code}: {err_body}")
    except urllib.error.URLError as e:
        raise RuntimeError(f"Network error: {e.reason}")
    except Exception as e:
        raise RuntimeError(f"Unexpected error: {str(e)}")

def main():
    parser = argparse.ArgumentParser(
        description="Subass DeepL — API Key Validation and Helper",
    )

    key_group = parser.add_mutually_exclusive_group(required=True)
    key_group.add_argument("--key", "-k", help="DeepL API key (inline)")
    key_group.add_argument("--key-file", help="Path to a file containing the DeepL API key")

    parser.add_argument(
        "--check-key",
        action="store_true",
        default=False,
        help="Validate the provided DeepL API key",
    )

    parser.add_argument(
        "--translate-file",
        help="Path to a JSON file containing items to translate: [{'id': '...', 'text': '...'}]"
    )

    parser.add_argument(
        "--target-lang",
        default="UK",
        help="Target language for translation (default: UK)"
    )

    args = parser.parse_args()

    # --- Read API key ---
    if args.key_file:
        try:
            with open(args.key_file, "r", encoding="utf-8") as fk:
                api_key = fk.read().strip()
        except OSError as e:
            print(f"Error reading key file: {e}")
            sys.exit(1)
    else:
        api_key = (args.key or "").strip()

    if not api_key:
        print("Error: API key is empty")
        sys.exit(1)

    if args.check_key:
        try:
            result = check_deepl_key(api_key)
            print(result)
            sys.exit(0)
        except Exception as e:
            print(f"Error: {e}")
            sys.exit(1)
    elif args.translate_file:
        try:
            with open(args.translate_file, "r", encoding="utf-8") as f:
                items = json.load(f)
        except Exception as e:
            print(f"Error reading translate file: {e}")
            sys.exit(1)

        if not isinstance(items, list):
            print("Error: translate file must contain a JSON list")
            sys.exit(1)

        texts = [item.get("text", "") for item in items]
        try:
            translated_texts = translate_texts(api_key, texts, args.target_lang)
            # Match back
            output_items = []
            for i, item in enumerate(items):
                output_items.append({
                    "id": item.get("id"),
                    "text": translated_texts[i]
                })
            print(json.dumps(output_items, ensure_ascii=False))
            sys.exit(0)
        except Exception as e:
            print(f"Error: {e}")
            sys.exit(1)
    else:
        print("Error: No action specified (e.g. use --check-key or --translate-file)")
        sys.exit(1)

if __name__ == "__main__":
    main()
