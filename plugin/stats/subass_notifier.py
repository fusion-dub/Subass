#!/usr/bin/env python3
import os
import json
import sys
import subprocess
import time
import shlex
from datetime import datetime

# Ensure common paths are available for launchd
os.environ['PATH'] = '/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:' + os.environ.get('PATH', '')

# CREATE_NO_WINDOW for Windows
SUBPROCESS_FLAGS = 0x08000000 if sys.platform == "win32" else 0

def notify_macos(title, message, proj_path=None):
    # Try to find terminal-notifier
    tn_path = "/opt/homebrew/bin/terminal-notifier" if os.path.exists("/opt/homebrew/bin/terminal-notifier") else "terminal-notifier"
    
    # Check if terminal-notifier is usable
    has_tn = subprocess.run(["which", tn_path], capture_output=True).returncode == 0
    
    if proj_path and has_tn:
        # Use terminal-notifier for clickable banners
        # -execute allows running a full shell command.
        # We use shlex.quote to safely handle spaces and special characters.
        safe_path = shlex.quote(proj_path)
        # Unique group helps ensure multiple notifications don't cancel each other
        group_id = f"subass_deadline_{hash(proj_path) % 10000}"
        
        cmd = [
            tn_path,
            "-title", title,
            "-message", message,
            "-group", group_id,
            "-execute", f"open -a REAPER {safe_path}",
            "-action", "Відкрити",
            "-timeout", "30"
        ]
        
        try:
            # Using run instead of Popen to wait for it and capture results
            subprocess.run(cmd, capture_output=True, text=True)
        except Exception:
            pass
            
    elif proj_path:
        # Fallback to dialog if terminal-notifier is missing
        script = f'''
        set theResult to display dialog "{message}" with title "{title}" buttons {{"Відкрити", "Закрити"}} default button "Відкрити" giving up after 60
        if button returned of theResult is "Відкрити" then
            do shell script "open -a REAPER \\"{proj_path}\\""
        end if
        '''
        print(f"Sending macOS dialog fallback for: {title}")
        try:
            subprocess.run(["osascript", "-e", script])
        except Exception as e:
            print(f"Error launching osascript dialog: {e}")
    else:
        # Non-urgent/Generic notification
        script = f'display notification "{message}" with title "{title}"'
        print(f"Sending macOS simple notification: {title}")
        try:
            subprocess.run(["osascript", "-e", script])
        except Exception as e:
            print(f"Error launching osascript notification: {e}")
    
    # Small sleep to ensure launchd doesn't kill child processes too aggressively
    time.sleep(1)


def notify_windows(title, message, proj_path=None):
    if proj_path:
        # Modern Toast with protocol launch (Win 10+)
        escaped_path = proj_path.replace("\\", "/") 
        ps_script = f"""
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
        $xml = @"
<toast activationType="protocol" launch="file:///{escaped_path}">
    <visual>
        <binding template="ToastGeneric">
            <text>{title}</text>
            <text>{message}</text>
            <text>Натисніть, щоб відкрити проєкт у REAPER</text>
        </binding>
    </visual>
</toast>
"@
        $xmlDoc = New-Object Windows.Data.Xml.Dom.XmlDocument
        $xmlDoc.LoadXml($xml)
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("SubassNotifier").Show((New-Object Windows.UI.Notifications.ToastNotification($xmlDoc)))
        """
        subprocess.run(["powershell", "-Command", ps_script], capture_output=True, creationflags=SUBPROCESS_FLAGS)
    else:
        # Fallback to legacy notification balloon
        ps_script = f"""
        [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
        $objNotifyIcon = New-Object System.Windows.Forms.NotifyIcon
        $objNotifyIcon.Icon = [System.Drawing.SystemIcons]::Information
        $objNotifyIcon.BalloonTipIcon = "Info"
        $objNotifyIcon.BalloonTipText = "{message}"
        $objNotifyIcon.BalloonTipTitle = "{title}"
        $objNotifyIcon.Visible = $True
        $objNotifyIcon.ShowBalloonTip(10000)
        """
        subprocess.run(["powershell", "-Command", ps_script], capture_output=True, creationflags=SUBPROCESS_FLAGS)

def send_notification(title, message, proj_path=None):
    if sys.platform == "darwin":
        notify_macos(title, message, proj_path)
    elif sys.platform == "win32":
        notify_windows(title, message, proj_path)
    else:
        print(f"[{title}] {message} (Path: {proj_path})")


def find_extstate_file():
    if sys.platform == "darwin":
        path = os.path.expanduser("~/Library/Application Support/REAPER/reaper-extstate.ini")
    elif sys.platform == "win32":
        appdata = os.environ.get("APPDATA")
        if not appdata: return None
        path = os.path.join(appdata, "REAPER", "reaper-extstate.ini")
    else:
        return None
    
    return path if os.path.exists(path) else None

def parse_deadlines(file_path):
    deadlines = {}
    try:
        with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
            lines = f.readlines()
            
        current_section = ""
        found_key = False
        json_buffer = []
        
        # We need to find "new_project_deadlines" specifically inside [Subass_Notes]
        # or at least prioritize it. The safest bet is to find it in [Subass_Notes].
        
        for line in lines:
            line = line.strip()
            if line.startswith("[") and line.endswith("]"):
                current_section = line[1:-1]
                # If we were building a buffer from a previous section but didn't finish, reset it
                if not found_key:
                    json_buffer = []
                continue
                
            if current_section == "Subass_Notes" and line.startswith("new_project_deadlines="):
                found_key = True
                json_data = line.split("=", 1)[1]
                try:
                    res = json.loads(json_data)
                    print(f"Parsed {len(res)} deadlines from [Subass_Notes].")
                    return res
                except json.JSONDecodeError:
                    # Maybe it's multi-line?
                    json_buffer.append(json_data)
            elif found_key and current_section == "Subass_Notes":
                # If we started finding the key, keep adding lines until next key or section
                if "=" in line or line.startswith("["):
                    break
                json_buffer.append(line)
        
        if json_buffer:
            res = json.loads("".join(json_buffer))
            print(f"Parsed {len(res)} deadlines from [Subass_Notes] (buffered).")
            return res
            
    except Exception as e:
        print(f"Error parsing extstate: {e}")
    
    return deadlines

def monitor():
    print(f"--- Subass Notifier Check: {datetime.now()} ---")
    path = find_extstate_file()
    if not path:
        print("REAPER extstate file not found.")
        return
    
    data = parse_deadlines(path)
    if not data:
        return

    now = time.time()
    notified_any = False
    
    for proj_path, info in data.items():
        deadline_ts = info.get("deadline")
        if not deadline_ts: 
            continue
        
        name = info.get("name", "Project")
        
        # Calculate calendar day difference
        dt_deadline = datetime.fromtimestamp(deadline_ts).date()
        dt_now = datetime.fromtimestamp(now).date()
        days_diff = (dt_deadline - dt_now).days

        # Notify if deadline is within next 2 days and in the future
        print(f"Project: {name}, Days diff: {days_diff}, {dt_deadline}, {dt_now}")
        
        if 0 <= days_diff <= 2:
            print(f"Triggering urgent notification for {name}")
            
            if days_diff == 0:
                msg = f"КРИТИЧНО: Дедлайн '{name}' сьогодні!"
            elif days_diff == 1:
                msg = f"Дедлайн '{name}' завтра!"
            elif days_diff == 2:
                msg = f"Дедлайн '{name}' післязавтра!"
            else:
                msg = f"Дедлайн проєкту '{name}' вже скоро!"
            
            send_notification("Subass Deadline", msg, proj_path)
            notified_any = True
            
    if not notified_any:
        print("No urgent deadlines found.")

def setup(schedule_time="19:00"):
    script_path = os.path.abspath(__file__)
    
    try:
        hour, minute = schedule_time.split(":")
        hour_int = int(hour)
        minute_int = int(minute)
    except Exception:
        print("Invalid time format. Use HH:mm (e.g. 19:00)")
        return

    if sys.platform == "darwin":
        # macOS: Install terminal-notifier if missing (for clickable banners)
        print("Checking for terminal-notifier...")
        tn_path = "/opt/homebrew/bin/terminal-notifier" if os.path.exists("/opt/homebrew/bin/terminal-notifier") else "terminal-notifier"
        has_tn = subprocess.run(["which", tn_path], capture_output=True).returncode == 0
        
        if not has_tn:
            brew_path = "/opt/homebrew/bin/brew" if os.path.exists("/opt/homebrew/bin/brew") else "brew"
            has_brew = subprocess.run(["which", brew_path], capture_output=True).returncode == 0
            if has_brew:
                print("Installing terminal-notifier via Homebrew...")
                subprocess.run([brew_path, "install", "terminal-notifier"], check=False)
            else:
                print("Homebrew not found. Skipping terminal-notifier installation.")

        # macOS: Create LaunchAgent
        label = "com.subass.notifier"
        
        # Use the most robust python path possible
        py_path = sys.executable
        if "Xcode.app" in py_path:
            # If we are in a stub, try to find brew python or use /usr/local/bin/python3
            for p in ["/opt/homebrew/bin/python3", "/usr/local/bin/python3"]:
                if os.path.exists(p):
                    py_path = p
                    break

        plist_path = os.path.expanduser(f"~/Library/LaunchAgents/{label}.plist")
        
        plist_content = f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>{label}</string>
    <key>ProgramArguments</key>
    <array>
        <string>{py_path}</string>
        <string>{script_path}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>{hour_int}</integer>
        <key>Minute</key>
        <integer>{minute_int}</integer>
    </dict>
</dict>
</plist>"""
        
        try:
            os.makedirs(os.path.dirname(plist_path), exist_ok=True)
            with open(plist_path, "w") as f:
                f.write(plist_content)
            
            # Unload if already exists, then load
            subprocess.run(["launchctl", "unload", plist_path], capture_output=True)
            subprocess.run(["launchctl", "load", plist_path], check=True)
            
            send_notification("Subass Setup", f"Сповіщення заплановано на {schedule_time} (macOS)")
            print(f"Setup complete: {plist_path} (Scheduled for {schedule_time})")
        except Exception as e:
            print(f"Failed to setup macOS LaunchAgent: {e}")

    elif sys.platform == "win32":
        # Windows: Create Scheduled Task
        task_name = "SubassNotifier"
        
        # Determine the most silent python executable
        # pythonw.exe is the standard silent runner for Python on Windows
        python_exe = sys.executable
        if "python.exe" in python_exe.lower():
            pythonw = python_exe.lower().replace("python.exe", "pythonw.exe")
            if os.path.exists(pythonw):
                python_exe = pythonw
        elif not python_exe.lower().endswith("pythonw.exe"):
            # Try searching in the same directory
            dir_path = os.path.dirname(python_exe)
            pythonw = os.path.join(dir_path, "pythonw.exe")
            if os.path.exists(pythonw):
                python_exe = pythonw

        cmd = [
            "schtasks", "/create", "/tn", task_name, 
            "/tr", f'"{python_exe}" "{script_path}"',
            "/sc", "daily", "/st", schedule_time, "/f"
        ]
        
        try:
            subprocess.run(cmd, check=True, capture_output=True, creationflags=SUBPROCESS_FLAGS)
            send_notification("Subass Setup", f"Сповіщення заплановано на {schedule_time} (Windows)")
            print(f"Setup complete: Windows Scheduled Task created using {os.path.basename(python_exe)}.")
        except Exception as e:
            print(f"Failed to setup Windows Scheduled Task: {e}")

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Subass Deadline Notifier")
    parser.add_argument("--setup", action="store_true", help="Setup automatic run on system startup")
    parser.add_argument("--time", type=str, default="19:00", help="Time for daily notifications (HH:mm)")
    
    args = parser.parse_args()
    
    if args.setup:
        setup(args.time)
    else:
        monitor()

