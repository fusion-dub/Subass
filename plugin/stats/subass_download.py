#!/usr/bin/env python3
import os
import sys
import subprocess
import json
import argparse
import urllib.request
import urllib.parse
import urllib.error

# --- Default API Keys ---
OSUB_DEFAULT_KEY = "5J3F15q8wOSyoydqLoM7R9ghLDnEESmu"
JIMAKU_DEFAULT_KEY = "AAAAAAAAH4guAS7UD3DseWJ4LmRHg6tnZeRzYlmD1KS0NnhY9MtHNMam1A"
SUBDL_DEFAULT_KEY = "uJMHXZhLG1_rpAVOLQJI1kUj0jkF54sB"
# --- End API Keys ---

# --- Dependency Check ---
try:
    import yt_dlp
except ImportError:
    print("\n[DOWNLOAD] Бібліотека 'yt-dlp' не знайдена.")
    print("Якщо ви хочете встановити її зараз, введіть 'install' та натисніть Enter.")
    
    try:
        # Check if we're in a terminal that supports input
        choice = input("\n> ").strip().lower()
        if choice == "install":
            print("\n[DOWNLOAD] Встановлення yt-dlp... (Це може зайняти деякий час)")
            try:
                # Try installing with --break-system-packages for Homebrew/system Python environments
                subprocess.check_call([sys.executable, "-m", "pip", "install", "yt-dlp", "--break-system-packages"])
                print("[DOWNLOAD] yt-dlp успішно встановлено!")
                import yt_dlp
            except subprocess.CalledProcessError:
                try:
                    subprocess.check_call([sys.executable, "-m", "pip", "install", "yt-dlp"])
                    print("[DOWNLOAD] yt-dlp успішно встановлено!")
                    import yt_dlp
                except:
                    print("[DOWNLOAD] Помилка встановлення. Спробуйте вручну: 'pip install yt-dlp --break-system-packages'")
                    sys.exit(1)
        else:
            print("[DOWNLOAD] Встановлення скасовано.")
            sys.exit(0)
    except EOFError:
        print("[DOWNLOAD] Помилка: yt-dlp не встановлено і не вдалося отримати ввід користувача.")
        sys.exit(1)

def get_info(url):
    """Fetch info about the URL and return a simplified JSON structure."""
    ydl_opts = {
        'quiet': True,
        'no_warnings': True,
        'extract_flat': False,
        'noplaylist': True,  # Don't extract playlist info, only the video
    }
    
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=False)
            
            # Simplified result structure
            result = {
                "title": info.get("title", "Unknown"),
                "duration": info.get("duration"),
                "thumbnail": info.get("thumbnail"),
                "formats": [],
                "subtitles": []
            }
            
            # Process formats
            # Sort: audio first, then video; within each type prefer mp4 over other containers
            type_order = {"audio_only": 0, "video+audio": 1, "video_only": 2, "unknown": 3}
            def format_sort_key(f):
                vcodec = f.get("vcodec", "none")
                acodec = f.get("acodec", "none")
                if vcodec != "none" and acodec != "none":
                    t = "video+audio"
                elif vcodec != "none":
                    t = "video_only"
                elif acodec != "none":
                    t = "audio_only"
                else:
                    t = "unknown"

                ext_pref = 0 if f.get("ext") == "mp4" else 1
                return (type_order.get(t, 3), ext_pref)

            all_formats = sorted(info.get("formats", []), key=format_sort_key)
            seen_audio_notes = set()
            seen_video_notes = set()

            for f in all_formats:
                # We care about resolution, extension, and if it's audio/video
                f_info = {
                    "format_id": f.get("format_id"),
                    "ext": f.get("ext"),
                    "resolution": f.get("resolution"),
                    "vcodec": f.get("vcodec"),
                    "acodec": f.get("acodec"),
                    "filesize": f.get("filesize") or f.get("filesize_approx"),
                    "note": f.get("format_note")
                }
                
                # Categorize
                if f.get("vcodec") != "none" and f.get("acodec") != "none":
                    f_info["type"] = "video+audio"
                elif f.get("vcodec") != "none":
                    f_info["type"] = "video_only"
                elif f.get("acodec") != "none":
                    f_info["type"] = "audio_only"
                else:
                    f_info["type"] = "unknown"
                
                # Only include relevant media formats
                if f_info["type"] != "unknown":
                    note = f_info["note"] or "unknown"
                    
                    # Deduplicate audio by quality (note)
                    if f_info["type"] == "audio_only":
                        if note in seen_audio_notes:
                            continue
                        seen_audio_notes.add(note)
                    
                    # Deduplicate video by quality (note/resolution)
                    if f_info["type"] in ["video_only", "video+audio"]:
                        # Use resolution as a fallback for note if it's missing or generic
                        quality_key = note
                        if quality_key in seen_video_notes:
                            continue
                        seen_video_notes.add(quality_key)
                    
                    result["formats"].append(f_info)
            
            # Process subtitles
            subs = info.get("subtitles", {})
            for lang, s_list in subs.items():
                result["subtitles"].append({
                    "lang": lang,
                    "formats": [s.get("ext") for s in s_list]
                })
                
            # Process automatic captions
            auto_subs = info.get("automatic_captions", {})
            for lang, s_list in auto_subs.items():
                # Filter auto-captions to only allow Ukrainian and English
                if lang in ['uk', 'en']:
                    result["subtitles"].append({
                        "lang": lang,
                        "formats": [s.get("ext") for s in s_list],
                        "is_auto": True
                    })
                
            return result
    except Exception as e:
        return {"error": str(e)}

def download_resource(url, format_id, output_path, subtitle_lang=None):
    """Download resource with specific format."""
    ydl_opts = {
        'format': format_id if format_id else 'best',
        'outtmpl': output_path,
        'quiet': False,
        'no_warnings': False,
    }
    
    if subtitle_lang:
        ydl_opts['writesubtitles'] = True
        ydl_opts['subtitleslangs'] = [subtitle_lang]
        # We might want to download only subtitles? 
        # But usually yt-dlp downloads media + subs.
    
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            ydl.download([url])
            return {"status": "success", "path": output_path}
    except Exception as e:
        return {"error": str(e)}

def is_url(text):
    """Check if the text looks like a URL."""
    return text.startswith("http://") or text.startswith("https://")

def is_supported_url(url):
    """Check if yt-dlp has an extractor that supports this URL."""
    extractors = yt_dlp.extractor.gen_extractors()
    for extractor in extractors:
        if extractor.suitable(url) and extractor.IE_NAME != "generic":
            return True
    return False

# ---------------------------------------------------------------------------
# Subtitle Search
# ---------------------------------------------------------------------------

def search_opensubtitles(query, api_key):
    """Search subtitles on OpenSubtitles.com (REST API v1). Requires free API key."""
    encoded = urllib.parse.quote(query)
    url = "https://api.opensubtitles.com/api/v1/subtitles?query={}&languages=uk,en&order_by=download_count&order_direction=desc".format(encoded)
    req = urllib.request.Request(url, headers={
        "Api-Key": api_key,
        "Content-Type": "application/json",
        "User-Agent": "Subass/1.0"
    })
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            results = []
            for item in data.get("data", []):
                attrs = item.get("attributes", {})
                feature = attrs.get("feature_details", {})
                title = feature.get("title") or attrs.get("release", "")
                year = feature.get("year", "")
                for f in attrs.get("files", []):
                    results.append({
                        "title": title,
                        "year": year,
                        "lang": attrs.get("language", ""),
                        "format": "srt",
                        "downloads": attrs.get("download_count", 0),
                        "file_id": f.get("file_id"),
                        "file_name": f.get("file_name", "")
                    })
            return results
    except urllib.error.HTTPError as e:
        if e.code == 401:
            return {"error": "Невірний API ключ OpenSubtitles"}
        return {"error": "HTTP {}".format(e.code)}
    except Exception as e:
        return {"error": str(e)}

def download_opensubtitles(file_id, api_key):
    """Download subtitle content from OpenSubtitles.com."""
    url = "https://api.opensubtitles.com/api/v1/download"
    payload = json.dumps({"file_id": int(file_id)})
    req = urllib.request.Request(url, data=payload.encode("utf-8"), headers={
        "Api-Key": api_key,
        "Content-Type": "application/json",
        "User-Agent": "Subass/1.0"
    }, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            link = data.get("link")
            if not link:
                return {"error": "OpenSubtitles did not return a download link. (Maybe limit reached?)"}
            
            # Follow the link to get raw content
            with urllib.request.urlopen(link, timeout=10) as final_resp:
                content = final_resp.read()
                # Try to decode, handle zip if necessary (OSub usually returns raw srt if requested via /download)
                return {
                    "status": "success",
                    "content": content.decode("utf-8", errors="replace"),
                    "file_name": data.get("file_name", "subtitle.srt")
                }
    except Exception as e:
        return {"error": str(e)}

def download_url_content(url, headers=None):
    """Simple helper to download content from a direct URL with optional headers."""
    try:
        req_headers = {"User-Agent": "Subass/1.0"}
        if headers:
            req_headers.update(headers)
        req = urllib.request.Request(url, headers=req_headers)
        with urllib.request.urlopen(req, timeout=10) as resp:
            content = resp.read()
            return {
                "status": "success",
                "content": content.decode("utf-8", errors="replace")
            }
    except Exception as e:
        return {"error": str(e)}

def download_jimaku(entry_id_or_url, api_key):
    """Download subtitle content from Jimaku.cc."""
    # If we got a full URL (api/entries/ID/files), extract ID or use URL
    url = entry_id_or_url
    if not url.startswith("http"):
        url = "https://jimaku.cc/api/entries/{}/files".format(entry_id_or_url)
    
    headers = {"Authorization": api_key}
    
    try:
        # 1. Get file list
        res = download_url_content(url, headers=headers)
        if "error" in res:
            return res
        
        files = json.loads(res["content"])
        if not files:
            return {"error": "Jimaku entry has no files"}
        
        # 2. Pick the best file (prefer .ass or .srt)
        target = None
        for f in files:
            name = f.get("name", "").lower()
            if name.endswith(".ass") or name.endswith(".srt"):
                target = f
                break
        if not target:
            target = files[0]
            
        file_url = target.get("url")
        if not file_url:
            return {"error": "Could not find download URL in Jimaku file data"}
            
        # 3. Download the actual file content
        return download_url_content(file_url, headers=headers)
        
    except Exception as e:
        return {"error": "Jimaku error: " + str(e)}

def search_subsplease(query):
    """Search anime on SubsPlease.org (no key needed). Returns unique shows."""
    encoded = urllib.parse.quote(query)
    url = "https://subsplease.org/api/?f=search&tz=UTC&s={}".format(encoded)
    req = urllib.request.Request(url, headers={"User-Agent": "Subass/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            results = []
            seen_pages = set()
            if not data:
                return results
            for title, info in data.items():
                page = info.get("page", "")
                page_url = "https://subsplease.org/shows/{}/".format(page)
                # Deduplicate — one entry per show, not per episode
                if page_url in seen_pages:
                    continue
                seen_pages.add(page_url)
                # Extract clean show title (remove episode suffix like "- 293")
                import re
                show_title = re.sub(r'\s*-\s*\d+\w*\s*$', '', title).strip()
                results.append({
                    "title": show_title,
                    "page_url": page_url,
                    "sid": info.get("sid", "")
                })
            return results
    except Exception as e:
        return {"error": str(e)}

def search_subdl(query, api_key):
    """Search subtitles on SubDL.com (official API, free key at subdl.com)."""
    encoded = urllib.parse.quote(query)
    url = "https://api.subdl.com/api/v1/subtitles?api_key={}&film_name={}&languages=EN,UK&subs_per_page=30".format(api_key, encoded)
    req = urllib.request.Request(url, headers={"User-Agent": "Subass/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            if not data.get("status"):
                return {"error": data.get("error", "SubDL error")}
            results = []
            # Get movie info from results[0] if available
            movie_info = data.get("results", [{}])[0] if data.get("results") else {}
            title = movie_info.get("name", query)
            year = movie_info.get("year", "")
            for sub in data.get("subtitles", []):
                url_path = sub.get("url", "")
                results.append({
                    "title": title,
                    "year": year,
                    "lang": sub.get("language", ""),
                    "release_name": sub.get("release_name", ""),
                    "author": sub.get("author", ""),
                    "downloads": sub.get("download_count", 0),
                    "hi": sub.get("hi", False),
                    "download_url": "https://dl.subdl.com{}".format(url_path) if url_path else ""
                })
            return results
    except urllib.error.HTTPError as e:
        if e.code == 401:
            return {"error": "Невірний API ключ SubDL"}
        return {"error": "HTTP {}".format(e.code)}
    except Exception as e:
        return {"error": str(e)}

def search_animetosho(query):
    """Search anime subtitles on Animetosho (JSON API, no key needed)."""
    encoded = urllib.parse.quote(query)
    url = "https://feed.animetosho.org/json?qx=1&q={}".format(encoded)
    req = urllib.request.Request(url, headers={"User-Agent": "Subass/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            results = []
            seen_titles = set()
            for item in data:
                title = item.get("title", "")
                # Only include entries that have subtitles listed
                if not item.get("num_files"):
                    continue
                if title in seen_titles:
                    continue
                seen_titles.add(title)
                results.append({
                    "title": title,
                    "torrent_url": item.get("torrent_url", ""),
                    "magnet_uri": item.get("magnet_uri", ""),
                    "info_url": "https://animetosho.org/view/{}".format(item.get("id", ""))
                })
            return results
    except Exception as e:
        return {"error": str(e)}

def search_jimaku(query, api_key):
    """Search Japanese subtitles on Jimaku.cc (requires free account API key)."""
    # The Jimaku API returns the entire database; filter client-side
    url = "https://jimaku.cc/api/entries/search"
    req = urllib.request.Request(url, headers={
        "Authorization": api_key,
        "User-Agent": "Subass/1.0"
    })
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            results = []
            q_lower = query.lower()
            for item in data:
                name = item.get("name", "")
                en_name = item.get("english_name", "")
                if q_lower in name.lower() or q_lower in en_name.lower():
                    results.append({
                        "title": name,
                        "english_name": en_name,
                        "last_modified": item.get("last_modified", ""),
                        "flags": item.get("flags", []),
                        "files_url": "https://jimaku.cc/api/entries/{}/files".format(item.get("id", ""))
                    })
            return results
    except urllib.error.HTTPError as e:
        if e.code == 401:
            return {"error": "Невірний API ключ Jimaku.cc"}
        return {"error": "HTTP {}".format(e.code)}
    except Exception as e:
        return {"error": str(e)}

def _append_source(result, source_name, data):
    """Helper to append a source entry to result['sources']."""
    entry = {"source": source_name}
    if isinstance(data, list):
        entry["items"] = data
    else:
        entry["items"] = []
        entry["error"] = data.get("error", "Unknown error")
    result["sources"].append(entry)

def search_subtitles(query, osub_key=None, jimaku_key=None, subdl_key=None):
    """Search for subtitles from multiple sources by title name."""
    result = {
        "query": query,
        "sources": []
    }

    # OpenSubtitles.com (uk + en, requires API key — default provided)
    if osub_key:
        _append_source(result, "opensubtitles", search_opensubtitles(query, osub_key))

    # SubDL.com (uk + en, requires free API key)
    if subdl_key:
        _append_source(result, "subdl", search_subdl(query, subdl_key))

    # Jimaku.cc (Japanese subtitles, optional key)
    if jimaku_key:
        _append_source(result, "jimaku", search_jimaku(query, jimaku_key))

    return result

def main():
    parser = argparse.ArgumentParser(description="Subass Download Tool (yt-dlp wrapper)")
    parser.add_argument("--target", help="URL or search query for the resource")
    parser.add_argument("--info", action="store_true", help="Get info in JSON format")
    parser.add_argument("--download", action="store_true", help="Download the resource")
    parser.add_argument("--format", help="Format ID to download")
    parser.add_argument("--output", help="Output path for download")
    parser.add_argument("--sub-lang", help="Subtitle language to download")
    parser.add_argument("--osub-key", help="OpenSubtitles.com API key (free at opensubtitles.com)")
    parser.add_argument("--jimaku-key", help="Jimaku.cc API key for Japanese subtitles (free account required)")
    
    # Subtitle download specific
    parser.add_argument("--get-subtitle", action="store_true", help="Download subtitle content to stdout")
    parser.add_argument("--source", help="Source name (opensubtitles, subdl, etc.)")
    parser.add_argument("--id", help="File ID or unique identifier for the subtitle")
    parser.add_argument("--url", help="Direct URL for the subtitle file")
    
    args = parser.parse_args()
    target = args.target if args.target else ""

    # --- Subtitle Content Download ---
    if args.get_subtitle:
        osub_key = getattr(args, 'osub_key', None) or OSUB_DEFAULT_KEY
        jimaku_key = getattr(args, 'jimaku_key', None) or JIMAKU_DEFAULT_KEY
        
        if args.source == "jimaku" and (args.url or args.id):
            target_id = args.id or args.url
            res = download_jimaku(target_id, jimaku_key)
            print(json.dumps(res, ensure_ascii=False))
            return
        elif args.url:
            res = download_url_content(args.url)
            print(json.dumps(res, ensure_ascii=False))
            return
        elif args.source == "opensubtitles" and args.id:
            res = download_opensubtitles(args.id, osub_key)
            print(json.dumps(res, ensure_ascii=False))
            return
        else:
            print(json.dumps({"error": "Missing source/id or url for subtitle download"}, ensure_ascii=False))
            return

    # --- Determine target type ---
    if target and is_url(target):
        if not is_supported_url(target):
            print(json.dumps({"error": "Це посилання не підтримується. Спробуйте посилання на YouTube, SoundCloud тощо."}, ensure_ascii=False))
            sys.exit(1)
        # Supported URL — proceed normally
        if args.info:
            info = get_info(target)
            print(json.dumps(info, ensure_ascii=False, indent=2))
            return

        if args.download:
            if not args.output:
                print(json.dumps({"error": "Output path is required for download"}, ensure_ascii=False))
                sys.exit(1)
            res = download_resource(target, args.format, args.output, args.sub_lang)
            print(json.dumps(res, ensure_ascii=False))
            return
    else:
        # Plain text — search subtitles by title
        osub_key = getattr(args, 'osub_key', None) or OSUB_DEFAULT_KEY
        jimaku_key = getattr(args, 'jimaku_key', None) or JIMAKU_DEFAULT_KEY
        result = search_subtitles(target, osub_key=osub_key, jimaku_key=jimaku_key)
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return

    parser.print_help()

if __name__ == "__main__":
    main()
