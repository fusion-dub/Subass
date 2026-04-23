#!/usr/bin/env python3
"""
subass_ai.py — Multi-provider AI CLI tool for Subass Notes

Usage:
    # Gemini (default)
    python3 subass_ai.py --key KEY --prompt "text"
    python3 subass_ai.py --key-file key.txt --prompt-file prompt.txt --json-schema

    # Mistral
    python3 subass_ai.py --provider mistral --key KEY --prompt "text"
    python3 subass_ai.py --provider mistral --key-file key.txt --prompt-file prompt.txt

Output:
    Prints extracted text to stdout.
    On error, prints "Error: ..." to stdout and exits with code 1.
"""

import argparse
import json
import sys
import urllib.request
import urllib.error
from typing import Optional


# ---------------------------------------------------------------------------
# Gemini
# ---------------------------------------------------------------------------

GEMINI_MODELS = [
    "gemini-flash-latest",
    "gemini-3-flash-preview",
    "gemini-2.5-flash",
    "gemini-2.5-flash-lite",
    "gemini-2.0-flash",
    "gemini-2.0-flash-lite",
]

GEMINI_API_BASE = "https://generativelanguage.googleapis.com/v1beta/models"


def _gemini_build_body(prompt, use_json_schema):
    body = {"contents": [{"parts": [{"text": prompt}]}]}
    if use_json_schema:
        body["generationConfig"] = {
            "responseMimeType": "application/json",
            "responseSchema": {"type": "ARRAY", "items": {"type": "STRING"}},
        }
    return body


def _gemini_extract(response_json):
    try:
        return response_json["candidates"][0]["content"]["parts"][0]["text"]
    except (KeyError, IndexError, TypeError):
        return None


def call_gemini(key, prompt, use_json_schema=False):
    """Try each Gemini model in order; return text on success or raise RuntimeError."""
    if not key:
        raise ValueError("API key is required")

    body_bytes = json.dumps(_gemini_build_body(prompt, use_json_schema), ensure_ascii=False).encode("utf-8")
    last_error = "All Gemini models failed"

    for model in GEMINI_MODELS:
        url = "{}/{}: generateContent?key={}".format(GEMINI_API_BASE, model, key).replace(": ", ":")
        # rebuild cleanly
        url = "{}/{}:generateContent?key={}".format(GEMINI_API_BASE, model, key)
        req = urllib.request.Request(
            url, data=body_bytes,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                if resp.status == 200:
                    text = _gemini_extract(json.loads(resp.read().decode("utf-8")))
                    if text is not None:
                        return text
                    last_error = "Model {} returned 200 but no text".format(model)
        except urllib.error.HTTPError as e:
            code = e.code
            if code in (401, 403):
                raise RuntimeError("Invalid Gemini API key (HTTP {})".format(code))
            last_error = "HTTP {} on model {}".format(code, model)
        except urllib.error.URLError as e:
            last_error = "Network error on {}: {}".format(model, e.reason)
        except (json.JSONDecodeError, KeyError):
            last_error = "Bad JSON from model {}".format(model)

    raise RuntimeError(last_error)


# ---------------------------------------------------------------------------
# Mistral
# ---------------------------------------------------------------------------

MISTRAL_MODELS = [
    "mistral-small-latest",
    "mistral-large-latest",
    "open-mistral-nemo",
    "mistral-medium-latest",
]

MISTRAL_API_BASE = "https://api.mistral.ai/v1/chat/completions"


def _mistral_build_body(prompt, use_json_schema):
    body = {
        "model": MISTRAL_MODELS[0],  # overridden per-attempt
        "messages": [{"role": "user", "content": prompt}],
        "temperature": 0.7,
    }
    if use_json_schema:
        body["response_format"] = {"type": "json_object"}
    return body


def _mistral_extract(response_json):
    try:
        return response_json["choices"][0]["message"]["content"]
    except (KeyError, IndexError, TypeError):
        return None


def call_mistral(key, prompt, use_json_schema=False):
    """Try each Mistral model in order; return text on success or raise RuntimeError."""
    if not key:
        raise ValueError("API key is required")

    last_error = "All Mistral models failed"

    for model in MISTRAL_MODELS:
        body = _mistral_build_body(prompt, use_json_schema)
        body["model"] = model
        body_bytes = json.dumps(body, ensure_ascii=False).encode("utf-8")

        req = urllib.request.Request(
            MISTRAL_API_BASE,
            data=body_bytes,
            headers={
                "Content-Type": "application/json",
                "Authorization": "Bearer {}".format(key),
            },
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                if resp.status == 200:
                    text = _mistral_extract(json.loads(resp.read().decode("utf-8")))
                    if text is not None:
                        return text
                    last_error = "Model {} returned 200 but no text".format(model)
        except urllib.error.HTTPError as e:
            code = e.code
            if code in (401, 403):
                raise RuntimeError("Invalid Mistral API key (HTTP {})".format(code))
            last_error = "HTTP {} on model {}".format(code, model)
        except urllib.error.URLError as e:
            last_error = "Network error on {}: {}".format(model, e.reason)
        except (json.JSONDecodeError, KeyError):
            last_error = "Bad JSON from model {}".format(model)

    raise RuntimeError(last_error)


# ---------------------------------------------------------------------------
# Unified dispatcher
# ---------------------------------------------------------------------------

def call_ai(provider, key, prompt, use_json_schema=False):
    if provider == "mistral":
        return call_mistral(key, prompt, use_json_schema)
    return call_gemini(key, prompt, use_json_schema)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Subass AI — Multi-provider AI CLI tool",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )

    parser.add_argument(
        "--provider",
        choices=["gemini", "mistral"],
        default="gemini",
        help="AI provider to use (default: gemini)",
    )

    key_group = parser.add_mutually_exclusive_group(required=True)
    key_group.add_argument("--key", "-k", help="API key (inline)")
    key_group.add_argument("--key-file", help="Path to a file containing the API key")

    prompt_group = parser.add_mutually_exclusive_group(required=True)
    prompt_group.add_argument("--prompt", "-p", help="Prompt text")
    prompt_group.add_argument("--prompt-file", "-f", help="Path to a file containing the prompt")

    parser.add_argument(
        "--json-schema",
        action="store_true",
        default=False,
        help="Request structured JSON array output",
    )

    args = parser.parse_args()

    # --- Read API key ---
    if args.key_file:
        try:
            with open(args.key_file, "r", encoding="utf-8") as fk:
                api_key = fk.read().strip()
        except OSError as e:
            print("Error reading key file: {}".format(e))
            sys.exit(1)
    else:
        api_key = (args.key or "").strip()

    if not api_key:
        print("Error: API key is empty")
        sys.exit(1)

    # --- Read prompt ---
    if args.prompt_file:
        try:
            with open(args.prompt_file, "r", encoding="utf-8") as fp:
                prompt = fp.read()
        except OSError as e:
            print("Error reading prompt file: {}".format(e))
            sys.exit(1)
    else:
        prompt = args.prompt

    prompt = prompt.strip()
    if not prompt:
        print("Error: prompt is empty")
        sys.exit(1)

    # --- Call AI ---
    try:
        result = call_ai(args.provider, api_key, prompt, args.json_schema)
        print(result)
    except (ValueError, RuntimeError) as e:
        print("Error: {}".format(e))
        sys.exit(1)


if __name__ == "__main__":
    main()
