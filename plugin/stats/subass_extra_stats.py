#!/usr/bin/env python3
"""
Subass Extra Stats - Upload subtitle analytics
Supports: ASS, SRT, VTT formats
"""

import argparse
import hashlib
import os
import re
import sys
import uuid
from datetime import datetime
from pathlib import Path

try:
    import requests
except ImportError:
    print("Error: 'requests' library not found. Install with: pip3 install requests", file=sys.stderr)
    sys.exit(1)


# Firestore configuration
FIRESTORE_PROJECT = "subass-b5c64"
FIRESTORE_BASE_URL = f"https://firestore.googleapis.com/v1/projects/{FIRESTORE_PROJECT}/databases/(default)/documents"


def calculate_md5(content):
    """Calculate MD5 hash of string content"""
    return hashlib.md5(content.encode('utf-8')).hexdigest()


def main():
    parser = argparse.ArgumentParser(description='Upload subtitle analytics to Firestore')
    parser.add_argument('--filepath', help='Full path to subtitle file (.ass, .srt, .vtt) [Required for stats]')
    parser.add_argument('--project_name', help='Project name (e.g., MyProject.RPP)')
    parser.add_argument('--register', action='store_true', help='Register user usage')
    parser.add_argument('--script_title', help='Script title/version for registration')
    
    args = parser.parse_args()

    # Get system username & unique machine ID
    username = os.getenv('USER') or os.getenv('USERNAME') or 'unknown_user'
    safe_username = re.sub(r'[^\w\-]', '_', username)
    
    # Generate unique machine ID (MAC address based)
    machine_id = hex(uuid.getnode())[2:]
    unique_user_id = f"{safe_username}_{machine_id}"

    # --- REGISTRATION MODE ---
    if args.register:
        if not args.script_title:
            print("Error: --script_title required for registration", file=sys.stderr)
            sys.exit(1)
            
        safe_title = re.sub(r'[^\w\-]', '_', args.script_title)
        
        # Path: versions/<script_title>/users/<unique_user_id>
        # We need 4 segments for a valid document path: Col/Doc/Col/Doc
        # using 'versions' as root collection (allowed by rules)
        doc_path_user = f"{FIRESTORE_BASE_URL}/versions/{safe_title}/users/{unique_user_id}"
        
        payload_user = {
            "fields": {
                "username": {"stringValue": username},
                "machine_id": {"stringValue": machine_id},
                "last_active": {"timestampValue": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")},
                "os": {"stringValue": sys.platform}
            }
        }
        
        try:
            resp = requests.patch(
                doc_path_user,
                json=payload_user,
                headers={"Content-Type": "application/json"},
                timeout=10
            )
            
            if resp.status_code not in [200, 201]:
                print(f"Warning: Registration failed with status {resp.status_code}", file=sys.stderr)
                sys.exit(1)
                
            print(f"✓ Registered: {safe_title}/{safe_username}")
            sys.exit(0)
            
        except Exception as e:
            print(f"Error registering: {e}", file=sys.stderr)
            sys.exit(1)

    # --- STATS MODE ---
    if not args.filepath or not args.project_name:
        print("Error: --filepath and --project_name required for stats upload", file=sys.stderr)
        parser.print_help()
        sys.exit(1)
    
    # Validate file exists
    if not os.path.isfile(args.filepath):
        print(f"Error: File not found: {args.filepath}", file=sys.stderr)
        sys.exit(1)
    
    try:
        # Read file content as-is
        with open(args.filepath, 'r', encoding='utf-8-sig') as f:
            file_content = f.read()
        
        if not file_content.strip():
            print("Warning: File is empty", file=sys.stderr)
            sys.exit(0)
        
        # Calculate MD5 of content
        md5_hash = calculate_md5(file_content)
        
        safe_filename = re.sub(r'[^\w\-]', '_', Path(args.filepath).stem)[:64]
        
        # Document IDs
        doc_id_subtitles = md5_hash
        doc_id_analytics = f"{safe_username}_{safe_filename}_{md5_hash}"
        
        # Document paths
        doc_path_subtitles = f"{FIRESTORE_BASE_URL}/subtitles/{doc_id_subtitles}"
        doc_path_analytics = f"{FIRESTORE_BASE_URL}/analytics/{doc_id_analytics}"
        
        # Prepare payloads
        payload_subtitles = {
            "fields": {
                "1_filename": {"stringValue": os.path.basename(args.filepath)},
                "2_content": {"stringValue": file_content}
            }
        }
        
        payload_analytics = {
            "fields": {
                "1_filename": {"stringValue": os.path.basename(args.filepath)},
                "2_project": {"stringValue": args.project_name},
                "3_user": {"stringValue": username},
                "4_timestamp": {"timestampValue": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")},
                "5_relation_to_subtitles": {"referenceValue": f"projects/{FIRESTORE_PROJECT}/databases/(default)/documents/subtitles/{doc_id_subtitles}"}
            }
        }
        
        # Upload analytics
        resp_sub = requests.patch(
            doc_path_subtitles,
            json=payload_subtitles,
            headers={"Content-Type": "application/json"},
            timeout=60
        )
        
        if resp_sub.status_code not in [200, 201]:
            print(f"Warning: Subtitles upload failed with status {resp_sub.status_code}", file=sys.stderr)
            sys.exit(1)
        
        # Upload analytics
        resp_ana = requests.patch(
            doc_path_analytics,
            json=payload_analytics,
            headers={"Content-Type": "application/json"},
            timeout=60
        )
        
        if resp_ana.status_code not in [200, 201]:
            print(f"Warning: Analytics upload failed with status {resp_ana.status_code}", file=sys.stderr)
            sys.exit(1)
        
        print(f"✓ Uploaded: MD5={md5_hash[:8]}... | Analytics={doc_id_analytics}")
        sys.exit(0)
        
    except requests.RequestException as e:
        print(f"Error uploading to Firestore: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()

