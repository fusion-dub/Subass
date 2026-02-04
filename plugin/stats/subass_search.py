#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import json
import base64
import argparse
import re
import difflib

# Whitelisted audio extensions
AUDIO_EXTENSIONS = [".wav"]
# Conservative file size limit for a ~60s take recording (48k/24b mono is ~8MB)
MAX_FILE_SIZE_MB = 25

def normalize_text(text):
    """
    Normalizes text for fuzzy searching.
    """
    if not text: return ""
    text = text.lower()
    text = text.replace('\u0301', '')
    text = re.sub(r'[.,/#!$%^&*;:{}=\-_`~()…?!"\']', ' ', text)
    return " ".join(text.split())

def get_similarity(s1, s2):
    """
    Returns string similarity ratio.
    """
    return difflib.SequenceMatcher(None, s1, s2).ratio()

def parse_ass_line(line_str):
    """
    Parses a single line from the decoded ass_lines state.
    """
    parts = line_str.strip().split('|')
    if len(parts) < 7: return None
    try:
        t1, t2 = float(parts[0]), float(parts[1])
        actor = parts[2]
        text = "|".join(parts[6:]).replace("\\n", "\n")
        return {"t1": t1, "t2": t2, "actor": actor, "text": text}
    except: return None

def is_extension_allowed(file_path):
    if not file_path: return False
    ext = os.path.splitext(file_path)[1].lower()
    return ext in AUDIO_EXTENSIONS

def search_in_file(file_path, query_norm, max_item_len=60, max_overlaps=5, verbose=False):
    """
    Parses an RPP file to find subtitle matches and overlapping items.
    """
    project_dir = os.path.dirname(os.path.abspath(file_path))
    matches = []
    
    try:
        base64_chunks = {}
        tracks = []
        current_track = None
        current_item = None
        
        in_bin_block = None
        track_depth = 0
        item_depth = 0
        
        with open(file_path, 'rb') as f:
            for line in f:
                line_str = line.decode('utf-8', errors='ignore').strip()
                if not line_str: continue

                if in_bin_block is not None:
                    if line_str == ">": in_bin_block = None
                    else: base64_chunks[in_bin_block] += line_str
                    continue

                if line_str.startswith('<BIN'):
                    m = re.search(r'ASS_LINES_CHUNK_(\d+)', line_str)
                    if m:
                        idx = int(m.group(1))
                        in_bin_block = idx
                        base64_chunks[idx] = ""
                    continue

                if line_str.startswith("<TRACK"):
                    current_track = {"name": "Unnamed Track", "items": []}
                    tracks.append(current_track)
                    track_depth = 1
                    continue
                
                if current_track and track_depth == 1 and line_str.startswith("NAME "):
                    current_track["name"] = line_str[5:].strip('"')
                    continue

                if line_str.startswith("<ITEM"):
                    current_item = {"name": "Unnamed Item", "pos": 0, "len": 0, "soffs": 0, "is_video": False, "src_file": None, "full_path": None}
                    item_depth = 1
                    if current_track: current_track["items"].append(current_item)
                    continue
                
                if current_item:
                    if line_str.startswith("<"): item_depth += 1
                    elif line_str == ">":
                        item_depth -= 1
                        if item_depth == 0:
                            if (current_item["name"] == "Unnamed Item" or not current_item["name"]) and current_item["src_file"]:
                                current_item["name"] = current_item["src_file"]
                            current_item = None
                    else:
                        if line_str.startswith("POSITION "): 
                            try: current_item["pos"] = float(line_str.split()[1])
                            except: pass
                        elif line_str.startswith("LENGTH "):
                            try: current_item["len"] = float(line_str.split()[1])
                            except: pass
                        elif line_str.startswith("SOFFS "):
                            try: current_item["soffs"] = float(line_str.split()[1])
                            except: pass
                        elif line_str.startswith("NAME "): current_item["name"] = line_str[5:].strip('"')
                        elif line_str.startswith("FILE "):
                            # Robustly parse path between first/last quotes to handle take-index metadata
                            m = re.search(r'"(.*?)"', line_str)
                            rel_path = m.group(1) if m else line_str[5:].strip('"')
                            
                            if not os.path.isabs(rel_path):
                                current_item["full_path"] = os.path.normpath(os.path.join(project_dir, rel_path))
                            else:
                                current_item["full_path"] = rel_path
                            current_item["src_file"] = os.path.basename(current_item["full_path"])
                    continue

                if line_str.startswith("<"):
                    if current_track: track_depth += 1
                elif line_str == ">":
                    if current_track:
                        track_depth -= 1
                        if track_depth == 0: current_track = None

        if not base64_chunks: return None
        sorted_indices = sorted(base64_chunks.keys())
        full_b64 = "".join(base64_chunks[i] for i in sorted_indices)
        
        try:
            decoded_bytes = base64.b64decode(full_b64)
            decoded_data = decoded_bytes.decode('utf-8', errors='ignore')
            ass_lines = [parse_ass_line(l) for l in decoded_data.split('\n') if l.strip()]
        except Exception: return None

        # 4. Global Heuristics (Zero-Cost)
        source_stats = {} # path -> {"max_reach": float, "is_skipped": bool, "overlaps": set}
        for tr in tracks:
            for itm in tr["items"]:
                path = itm.get("full_path")
                if not path or not is_extension_allowed(path): continue
                
                stats = source_stats.setdefault(path, {"max_reach": 0.0, "is_skipped": False, "overlaps": set()})
                reach = itm["soffs"] + itm["len"]
                if reach > stats["max_reach"]: stats["max_reach"] = reach
                if itm["len"] > max_item_len: stats["is_skipped"] = True

                itm_pos = itm["pos"]
                itm_end = itm_pos + itm["len"]
                for idx, line in enumerate(ass_lines):
                    if not line: continue
                    if itm_pos < line["t2"] and itm_end > line["t1"]:
                        stats["overlaps"].add(idx)

        # Apply Global Filters
        for path, stats in source_stats.items():
            if stats["max_reach"] > max_item_len: stats["is_skipped"] = True
            if len(stats["overlaps"]) > max_overlaps: stats["is_skipped"] = True
            if not stats["is_skipped"] and os.path.exists(path):
                size_mb = os.path.getsize(path) / (1024 * 1024)
                if size_mb > MAX_FILE_SIZE_MB: stats["is_skipped"] = True

        # 5. Generate Matches
        for i, line_data in enumerate(ass_lines):
            if not line_data: continue
            text_norm = normalize_text(line_data["text"])
            if query_norm in text_norm:
                t1, t2 = line_data["t1"], line_data["t2"]
                overlapping_items = []
                
                for tr in tracks:
                    for itm in tr["items"]:
                        path = itm.get("full_path")
                        if not path or path not in source_stats or source_stats[path]["is_skipped"]: continue
                        itm_end = itm["pos"] + itm["len"]
                        if itm["pos"] < t2 and itm_end > t1:
                            overlapping_items.append({
                                "track": tr["name"],
                                "item": itm["name"],
                                "pos": itm["pos"],
                                "length": itm["len"],
                                "file_path": path
                            })
                
                if overlapping_items:
                    prev_line = ass_lines[i-1] if i > 0 else None
                    next_line = ass_lines[i+1] if i < len(ass_lines)-1 else None
                    similarity = get_similarity(query_norm, text_norm)
                    matches.append({
                        "text": line_data["text"].strip(),
                        "time": t1,
                        "actor": line_data["actor"],
                        "similarity": similarity,
                        "context_prev": {"text": prev_line["text"].strip(), "actor": prev_line["actor"]} if prev_line else None,
                        "context_next": {"text": next_line["text"].strip(), "actor": next_line["actor"]} if next_line else None,
                        "items": overlapping_items
                    })
            
    except Exception as e:
        if verbose: print(f"DEBUG: Error processing {file_path}: {e}", file=sys.stderr)
        
    if matches:
        mtime = os.path.getmtime(file_path)
        max_sim = max(m.get('similarity', 0) for m in matches)
        return {
            "project_name": os.path.basename(file_path),
            "project_path": file_path,
            "mtime": mtime,
            "max_similarity": max_sim,
            "matches": sorted(matches, key=lambda x: x.get('similarity', 0), reverse=True)
        }
    return None

def main():
    parser = argparse.ArgumentParser(description="Subass Global Search Tool")
    parser.add_argument("query", help="Text to search for")
    parser.add_argument("paths", nargs="+", help="Directories or files to search in")
    parser.add_argument("-o", "--output", help="Save results to a JSON file and print its path")
    parser.add_argument("-m", "--max-len", type=float, default=60.0, help="Maximum audio item length/offset to include (default: 60s)")
    parser.add_argument("--max-overlaps", type=int, default=5, help="Max unique subtitles a SOURCE FILE can overlap with (default: 5)")
    parser.add_argument("--verbose", action="store_true", help="Enable debug output")
    
    args = parser.parse_args()
    query_norm = normalize_text(args.query)
    all_results = []
    
    for start_path in set([os.path.abspath(p) for p in args.paths]):
        if not os.path.exists(start_path): continue
        if os.path.isfile(start_path):
            if start_path.lower().endswith(".rpp"):
                result = search_in_file(start_path, query_norm, args.max_len, args.max_overlaps, verbose=args.verbose)
                if result: all_results.append(result)
            continue
        for root, _, files in os.walk(start_path):
            for file in files:
                if file.lower().endswith(".rpp") and not file.startswith("._"):
                    result = search_in_file(os.path.join(root, file), query_norm, args.max_len, args.max_overlaps, verbose=args.verbose)
                    if result: all_results.append(result)

    # Sort results by max similarity (descending) and then by file modification time (descending)
    all_results.sort(key=lambda x: (x.get('max_similarity', 0), x.get('mtime', 0)), reverse=True)

    json_data = json.dumps(all_results, ensure_ascii=False, indent=2)
    if args.output:
        try:
            with open(os.path.abspath(args.output), 'w', encoding='utf-8') as f: f.write(json_data)
            print(os.path.abspath(args.output))
        except Exception as e:
            print(f"ERROR: {e}", file=sys.stderr)
            sys.exit(1)
    else: print(json_data)

if __name__ == "__main__":
    main()
