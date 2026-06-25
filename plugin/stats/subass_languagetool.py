#!/usr/bin/env python3
import sys
import json
import argparse
import os
import io

# Set output encoding to UTF-8 for compatibility
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

# Parse args first to handle --output-file in case of early errors
parser = argparse.ArgumentParser(description="LanguageTool Spell and Grammar Checker for Subass")
parser.add_argument("--text", help="Text to check for spelling and grammar")
parser.add_argument("--text-file", help="Path to file containing text to check")
parser.add_argument("--output-file", help="Path to file to write JSON results to")
parser.add_argument("--lang", default="uk-UA", help="Language code (default: uk-UA)")
args, unknown = parser.parse_known_args()

def write_response(data, status_code=0):
    json_output = json.dumps(data, ensure_ascii=False)
    if args.output_file:
        try:
            with open(args.output_file, "w", encoding="utf-8") as f:
                f.write(json_output)
        except Exception as e:
            sys.stderr.write(f"Failed to write output file: {str(e)}\n")
    print(json_output)
    sys.exit(status_code)

# Try to import or auto-install language-tool-python
try:
    import language_tool_python
except ImportError:
    import subprocess
    try:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "language-tool-python", "--break-system-packages"],
                              stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except:
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", "language-tool-python"],
                                  stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except:
            write_response({"error": "Failed to install 'language-tool-python' library."}, 1)
            
    try:
        import language_tool_python
    except ImportError:
        write_response({"error": "Failed to import 'language-tool-python' after auto-installation."}, 1)

def main():
    text = ""
    if args.text_file:
        try:
            with open(args.text_file, "r", encoding="utf-8") as f:
                text = f.read()
        except Exception as e:
            write_response({"error": f"Failed to read text file: {str(e)}"}, 1)
    else:
        text = args.text or ""
        
    if not text.strip():
        write_response([], 0)
        
    try:
        # Initialize LanguageTool server (downloads server JAR on first use)
        tool = language_tool_python.LanguageTool(args.lang)
        matches = tool.check(text)
        
        results = []
        for m in matches:
            results.append({
                "rule_id": getattr(m, "ruleId", getattr(m, "rule_id", "")),
                "message": getattr(m, "message", ""),
                "replacements": getattr(m, "replacements", []),
                "offset": getattr(m, "offset", 0),
                "error_length": getattr(m, "errorLength", getattr(m, "error_length", 0)),
                "category": getattr(m, "category", ""),
                "rule_issue_type": getattr(m, "ruleIssueType", getattr(m, "rule_issue_type", "")),
                "context": getattr(m, "context", "")
            })
            
        write_response(results, 0)
    except Exception as e:
        write_response({"error": str(e)}, 1)

if __name__ == "__main__":
    main()
