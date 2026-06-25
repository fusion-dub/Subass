#!/usr/bin/env python3
import sys
import json
import argparse
import os
import io
import time

# Set output encoding to UTF-8 for compatibility
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

# Parse args first to handle --output-file in case of early errors
parser = argparse.ArgumentParser(description="LanguageTool Spell and Grammar Checker for Subass")
parser.add_argument("--text", help="Text to check for spelling and grammar")
parser.add_argument("--text-file", help="Path to file containing text to check")
parser.add_argument("--output-file", help="Path to file to write JSON results to")
parser.add_argument("--lang", default="uk-UA", help="Language code (default: uk-UA)")
parser.add_argument("--daemon", action="store_true", help="Start in daemon mode")
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

def run_daemon():
    script_dir = os.path.dirname(os.path.realpath(__file__))
    status_file = os.path.join(script_dir, "async_lt_daemon.json")
    activity_file = os.path.join(script_dir, "async_lt_activity.tmp")
    
    # Touch activity file to initialize timer
    try:
        with open(activity_file, "w") as f:
            f.write(str(time.time()))
    except:
        pass
        
    try:
        # Initialize LanguageTool server
        tool = language_tool_python.LanguageTool(args.lang)
        
        # Write status file with port
        status_data = {
            "port": tool.port,
            "pid": os.getpid()
        }
        with open(status_file, "w") as f:
            json.dump(status_data, f)
            
        # Daemon loop: check activity every 5 seconds
        while True:
            time.sleep(5)
            # Read last activity time from activity_file
            last_activity = 0
            if os.path.exists(activity_file):
                try:
                    last_activity = os.path.getmtime(activity_file)
                except:
                    last_activity = time.time()
            else:
                last_activity = time.time()
                
            if time.time() - last_activity > 120: # 2 minutes timeout
                break
                
    except Exception as e:
        sys.stderr.write(f"Daemon error: {str(e)}\n")
    finally:
        # Clean up files on exit
        if os.path.exists(status_file):
            try: os.remove(status_file)
            except: pass
        if os.path.exists(activity_file):
            try: os.remove(activity_file)
            except: pass

def main():
    if args.daemon:
        run_daemon()
        return

    import urllib.request
    
    script_dir = os.path.dirname(os.path.realpath(__file__))
    status_file = os.path.join(script_dir, "async_lt_daemon.json")
    activity_file = os.path.join(script_dir, "async_lt_activity.tmp")
    
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
        
    # Check if daemon is running and responsive
    port = None
    if os.path.exists(status_file):
        try:
            with open(status_file, "r") as f:
                data = json.load(f)
                port = data.get("port")
        except:
            pass
            
    is_running = False
    if port:
        # Test if server is responsive
        try:
            url = f"http://localhost:{port}/v2/languages"
            req = urllib.request.Request(url)
            with urllib.request.urlopen(req, timeout=0.5) as response:
                if response.status == 200:
                    is_running = True
        except:
            pass
            
    if not is_running:
        # Launch daemon in the background
        import subprocess
        py_exe = sys.executable
        py_script = os.path.realpath(__file__)
        
        try:
            creationflags = 0
            if sys.platform == "win32":
                creationflags = 0x00000008 # DETACHED_PROCESS
                
            subprocess.Popen([py_exe, py_script, "--daemon", "--lang", args.lang], 
                             stdout=subprocess.DEVNULL, 
                             stderr=subprocess.DEVNULL,
                             creationflags=creationflags,
                             close_fds=True)
        except Exception as e:
            pass
            
        # Poll status file for up to 4 seconds to wait for daemon to boot
        start_time = time.time()
        while time.time() - start_time < 4.0:
            time.sleep(0.1)
            if os.path.exists(status_file):
                try:
                    with open(status_file, "r") as f:
                        data = json.load(f)
                        port = data.get("port")
                except:
                    port = None
                    
                if port:
                    # Test if responsive
                    try:
                        url = f"http://localhost:{port}/v2/languages"
                        req = urllib.request.Request(url)
                        with urllib.request.urlopen(req, timeout=0.5) as response:
                            if response.status == 200:
                                is_running = True
                                break
                    except:
                        pass
                        
    # Run check
    try:
        if is_running and port:
            # Reset timer
            try:
                with open(activity_file, "w") as f:
                    f.write(str(time.time()))
            except:
                pass
            # Use remote server (running daemon)
            tool = language_tool_python.LanguageTool(args.lang, remote_server=f"http://localhost:{port}")
        else:
            # Fallback to standard local server run
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
