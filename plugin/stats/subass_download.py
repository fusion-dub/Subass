#!/usr/bin/env python3
import os
import sys
import subprocess
import json
import argparse
import urllib.request
import urllib.parse
import urllib.error
import time

# --- Default API Keys ---
OSUB_DEFAULT_KEY = "5J3F15q8wOSyoydqLoM7R9ghLDnEESmu"
JIMAKU_DEFAULT_KEY = "AAAAAAAAH4guAS7UD3DseWJ4LmRHg6tnZeRzYlmD1KS0NnhY9MtHNMam1A"

COMMON_HEADERS = {
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Accept": "application/json, text/plain, */*",
    "Accept-Encoding": "identity"
}
SUBDL_DEFAULT_KEY = "uJMHXZhLG1_rpAVOLQJI1kUj0jkF54sB"
# --- End API Keys ---

# --- Dependency Check ---
def ensure_dependencies():
    """Check for yt-dlp and other needed tools. Install if missing."""
    # 1. yt-dlp (Core)
    try:
        import yt_dlp
    except ImportError:
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", "yt-dlp", "--break-system-packages"],
                                  stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            import yt_dlp
        except:
            try:
                subprocess.check_call([sys.executable, "-m", "pip", "install", "yt-dlp"],
                                      stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                import yt_dlp
            except:
                pass

    # 2. py7zr (7z support)
    try:
        import py7zr
    except ImportError:
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", "py7zr", "--break-system-packages"],
                                  stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except:
            try:
                subprocess.check_call([sys.executable, "-m", "pip", "install", "py7zr"],
                                      stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            except:
                pass

    # 3. sevenzip (System tool for RAR/7z)
    import shutil
    if not (shutil.which("7zz") or shutil.which("7z")):
        if sys.platform == "darwin" and shutil.which("brew"):
            try:
                subprocess.check_call(["brew", "install", "sevenzip"],
                                      stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            except:
                pass
        elif sys.platform == "win32" and shutil.which("winget"):
            try:
                subprocess.check_call(["winget", "install", "7zip.7zip"],
                                      stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            except:
                pass

ensure_dependencies()

import zipfile
import io
try:
    import py7zr
except ImportError:
    py7zr = None

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
                vcodec = f.get("vcodec", "none")
                acodec = f.get("acodec", "none")
                
                if vcodec != "none":
                    m_type = "video"
                elif acodec != "none":
                    m_type = "audio"
                else:
                    continue

                note = f.get("format_note") or f.get("resolution") or ""
                
                # If it's a video-only DASH format, mention we'll add audio
                if m_type == "video" and acodec == "none":
                    note = f"{note} (+Best Audio)"

                f_info = {
                    "format_id": f.get("format_id"),
                    "ext": "mp4" if m_type == "video" else f.get("ext"),
                    "type": m_type,
                    "note": note,
                    "filesize": f.get("filesize") or f.get("filesize_approx"),
                }
                
                # Deduplicate audio by note
                if m_type == "audio":
                    if note in seen_audio_notes: continue
                    seen_audio_notes.add(note)
                
                # Deduplicate video by note/resolution
                if m_type == "video":
                    if note in seen_video_notes: continue
                    seen_video_notes.add(note)
                
                result["formats"].append(f_info)
            
            # Process subtitles (Manual)
            subs = info.get("subtitles", {})
            manual_langs = set()
            for lang, s_list in subs.items():
                if lang == "live_chat": continue
                manual_langs.add(lang)
                result["subtitles"].append({
                    "lang": lang,
                    "formats": [s.get("ext") for s in s_list]
                })
                
            # Process automatic captions
            auto_subs = info.get("automatic_captions", {})
            for lang, s_list in auto_subs.items():
                if lang == "live_chat": continue
                # Skip if we already have manual subtitles for this language
                if lang in manual_langs: continue
                
                # Only include auto-captions for Ukrainian and English
                if lang in ['uk', 'en']:
                    result["subtitles"].append({
                        "lang": lang,
                        "formats": [s.get("ext") for s in s_list],
                        "is_auto": True
                    })
                
            return result
    except Exception as e:
        return {"error": str(e)}

def download_resource(url, format_id, output_path, subtitle_lang=None, media_type=None):
    """Download resource with specific format."""
    # If it's a video, we always want the best audio to go with it
    if not format_id:
        final_format = 'best'
    elif media_type == "video":
        # Force merge chosen video with best audio track, but fallback to original format
        # This fixes issues with platforms like TikTok where audio/video are already combined.
        final_format = f"{format_id}+bestaudio/{format_id}"
    else:
        # Audio or specific combined format
        final_format = format_id

    ydl_opts = {
        'format': final_format,
        'outtmpl': output_path,
        'quiet': True,
        'no_warnings': True,
        'noprogress': True,
        'noplaylist': True,
        'merge_output_format': 'mp4',
        'overwrites': True,
    }
    
    if sys.platform == "darwin":
        ydl_opts['ffmpeg_location'] = '/opt/homebrew/bin/ffmpeg'
        # Also check if it's in /usr/local/bin
        if not os.path.exists(ydl_opts['ffmpeg_location']):
            ydl_opts['ffmpeg_location'] = '/usr/local/bin/ffmpeg'
    
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
    url = "https://api.opensubtitles.com/api/v1/subtitles?query={}&languages=uk,en".format(encoded)
    req_headers = {
        "Api-Key": api_key,
        "Content-Type": "application/json",
        "User-Agent": "VLSub 0.11.0",
        "X-User-Agent": "VLSub 0.11.0"
    }
    req = urllib.request.Request(url, headers=req_headers)
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode("utf-8-sig"))
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
    req_headers = {
        "Api-Key": api_key,
        "Content-Type": "application/json",
        "User-Agent": "VLSub 0.11.0",
        "X-User-Agent": "VLSub 0.11.0"
    }
    req = urllib.request.Request(url, data=payload.encode("utf-8"), headers=req_headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode("utf-8-sig"))
        link = data.get("link")
        if not link:
            return {"error": "OpenSubtitles did not return a download link. (Maybe limit reached?)"}
            
        # Follow the link to get raw content
        with urllib.request.urlopen(link, timeout=10) as final_resp:
            content = final_resp.read()
            
        # Check if it's a ZIP (starts with PK)
        file_name = data.get("file_name", "subtitle.srt")
        if content.startswith(b"PK\x03\x04"):
            content, extracted_name = extract_subtitle_from_zip(content)
            if extracted_name: file_name = extracted_name

        return {
            "status": "success",
            "content": content.decode("utf-8", errors="replace"),
            "file_name": file_name
        }
    except Exception as e:
        return {"error": str(e)}

def extract_subtitle_from_archive(data, target_name=None, format="zip"):
    """Extract a specific file from ZIP, 7z, or RAR. Returns (extracted_data, file_name, error_msg)."""
    try:
        if format == "zip":
            with zipfile.ZipFile(io.BytesIO(data)) as z:
                names = z.namelist()
                target = target_name if target_name in names else None
                if not target:
                    for n in names:
                        if n.lower().endswith((".ass", ".srt")):
                            target = n; break
                if target: return z.read(target), target, None
                return data, None, "No subtitles (.ass/.srt) found in ZIP"
        
        elif format == "7z" and py7zr:
            try:
                with py7zr.SevenZipFile(io.BytesIO(data), mode='r') as z:
                    files = z.getnames()
                    target = target_name if target_name in files else None
                    if not target:
                        for n in files:
                            if n.lower().endswith((".ass", ".srt")):
                                target = n; break
                    if target:
                        extracted = z.read(targets=[target])
                        return extracted[target].read(), target, None
                    return data, None, "No subtitles found in 7z"
            except Exception as e:
                # Fallback to 7zz if py7zr fails (e.g. unsupported compression)
                pass

        if format in ["rar", "7z"]:
            import shutil, tempfile
            bin_7z = None
            for b in ["7zz", "7z", "7za"]:
                bin_7z = shutil.which(b) or next((os.path.join(p, b) for p in ["/opt/homebrew/bin", "/usr/local/bin"] if os.path.isfile(os.path.join(p, b))), None)
                if bin_7z: break
            
            if not bin_7z:
                return data, None, "Extraction tool (7zz/7z) not found"
            
            with tempfile.TemporaryDirectory() as tmp:
                archive_path = os.path.join(tmp, "archive." + format)
                with open(archive_path, "wb") as f: f.write(data)
                
                # # DEBUG: Save archive near script for user inspection
                # try:
                #     debug_path = os.path.join(os.path.dirname(__file__), "debug_last_archive." + format)
                #     with open(debug_path, "wb") as df: df.write(data)
                # except: pass
                
                try:
                    out = subprocess.check_output([bin_7z, "l", archive_path], stderr=subprocess.STDOUT).decode(errors="replace")
                    found_file = target_name
                    if not found_file:
                        import re
                        for line in out.splitlines():
                            # Match anything ending in .ass or .srt at the end of the line
                            m = re.search(r"(\S.*\.(ass|srt))$", line, re.I)
                            if m:
                                found_file = m.group(1).strip()
                                break
                    
                    if found_file:
                        raw_ext = subprocess.check_output([bin_7z, "e", archive_path, found_file, "-so"], stderr=subprocess.STDOUT)
                        return raw_ext, found_file, None
                    return data, None, "No subtitles found in " + format.upper()
                except subprocess.CalledProcessError as e:
                    return data, None, "7z Error: " + (e.output.decode(errors="replace") if e.output else str(e))

    except Exception as e:
        return data, None, str(e)
    return data, None, "Unsupported format or extraction failed"

def download_url_content(url, headers=None, zip_internal_name=None):
    """Simple helper to download content from a direct URL with optional headers."""
    try:
        req_headers = COMMON_HEADERS.copy()
        if headers:
            req_headers.update(headers)
        req = urllib.request.Request(url, headers=req_headers)
        with urllib.request.urlopen(req, timeout=10) as resp:
            raw = resp.read()
            if not raw:
                return {"error": "Отримано порожню відповідь від сервера."}
            
            is_binary = False
            fmt = None
            error = None
            if raw.startswith(b"PK\x03\x04"):
                fmt = "zip"
                raw, file_name, error = extract_subtitle_from_archive(raw, target_name=zip_internal_name, format="zip")
            elif raw.startswith(b"Rar!"):
                fmt = "rar"
                raw, file_name, error = extract_subtitle_from_archive(raw, target_name=zip_internal_name, format="rar")
            elif raw.startswith(b"7z\xbc\xaf\x27\x1c"):
                fmt = "7z"
                raw, file_name, error = extract_subtitle_from_archive(raw, target_name=zip_internal_name, format="7z")
            
            # If after extraction it still looks like an archive, it's binary
            if raw.startswith((b"PK\x03\x04", b"Rar!", b"7z\xbc\xaf\x27\x1c")):
                is_binary = True

            result = {
                "status": "success",
                "is_binary": is_binary,
                "format": fmt,
                "size": len(raw),
                "extraction_error": error
            }

            if is_binary:
                # We cannot send raw bytes via JSON. 
                # If it's an archive, we don't send content at all.
                pass
            else:
                try:
                    content = raw.decode("utf-8-sig", errors="replace")
                    result["content"] = content
                except:
                    result["content"] = str(raw) # Fallback to string representation

            return result
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
        
        content = res.get("content")
        is_binary = res.get("is_binary", False) or isinstance(content, (bytes, bytearray))
        
        if is_binary and not content:
            ext_err = res.get("extraction_error")
            if ext_err:
                return {"error": "Помилка розпакування: " + ext_err}
            pkg = "7-Zip (7zip.org)" if sys.platform == "win32" else "Homebrew and 'sevenzip'"
            return {"error": "Jimaku returned an archive ({}) that could not be automatically extracted. Please install {}.".format(res.get("format", "unknown"), pkg)}
        
        # Check if it's actually a subtitle file instead of a JSON list
        is_subtitle = False
        if not is_binary:
            trimmed = content.strip()
            if trimmed.startswith("[Script Info]") or " --> " in trimmed:
                is_subtitle = True
        elif isinstance(content, (bytes, bytearray)):
            if content.startswith(b"[Script Info]") or b" --> " in content:
                is_subtitle = True
        
        if is_subtitle:
            fmt = "ass" if (isinstance(content, str) and "[Script Info]" in content) or (isinstance(content, bytes) and b"[Script Info]" in content) else "srt"
            return {"status": "success", "content": content, "format": fmt}

        # If it's binary but not a known subtitle, it might be an archive
        if is_binary:
            if res.get("format") in ["rar", "7z"]:
                return res # Return as is
            return res
 
        trimmed = content.strip()
        if not (trimmed.startswith("[") or trimmed.startswith("{")):
            return {"error": "Jimaku повернув некоректні дані: " + trimmed[:50] + "..."}
            
        try:
            files = json.loads(trimmed)
        except Exception as je:
            return {"error": "Jimaku JSON parse error: " + str(je) + " | Content: " + trimmed[:100]}
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

def list_archive_contents(url):
    """Download a ZIP, 7z or RAR and list its subtitle files."""
    try:
        req = urllib.request.Request(url, headers=COMMON_HEADERS)
        with urllib.request.urlopen(req, timeout=10) as resp:
            raw = resp.read()
        
        format = "zip"
        if raw.startswith(b"Rar!"): format = "rar"
        elif raw.startswith(b"7z\xbc\xaf\x27\x1c"): format = "7z"
        
        files = []
        if format == "zip":
            with zipfile.ZipFile(io.BytesIO(raw)) as z:
                for n in z.namelist():
                    if n.lower().endswith((".ass", ".srt")):
                        files.append({"file_name": n, "download_url": url, "zip_internal_file": n, "size": z.getinfo(n).file_size})
        
        elif format == "7z" and py7zr:
            with py7zr.SevenZipFile(io.BytesIO(raw), mode='r') as z:
                for n in z.getnames():
                    if n.lower().endswith((".ass", ".srt")):
                        files.append({"file_name": n, "download_url": url, "zip_internal_file": n, "size": 0})
        
        else: # Use 7zz fallback
            import shutil
            import tempfile
            bin_7z = shutil.which("7zz") or shutil.which("7z")
            if bin_7z:
                with tempfile.TemporaryDirectory() as tmp:
                    archive_path = os.path.join(tmp, "archive")
                    with open(archive_path, "wb") as f: f.write(raw)
                    out = subprocess.check_output([bin_7z, "l", archive_path], stderr=subprocess.DEVNULL).decode(errors="replace")
                    import re
                    for line in out.splitlines():
                        m = re.search(r"\s+([^\s]+\.(ass|srt))$", line, re.I)
                        if m:
                            files.append({"file_name": m.group(1), "download_url": url, "zip_internal_file": m.group(1), "size": 0})
        
        if files:
            return {"status": "success", "files": files}
        return {"error": "No subtitles found in archive"}
    except Exception as e:
        return {"error": "Archive Error: " + str(e)}

def search_subsplease(query):
    """Search anime on SubsPlease.org (no key needed). Returns unique shows."""
    encoded = urllib.parse.quote(query)
    url = "https://subsplease.org/api/?f=search&tz=UTC&s={}".format(encoded)
    req = urllib.request.Request(url, headers={"User-Agent": "Subass/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode("utf-8-sig"))
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

def search_subdl(query, api_key, is_id=False):
    """Search subtitles on SubDL.com (official API, free key at subdl.com)."""
    encoded = urllib.parse.quote(str(query))
    param = "sd_id" if is_id else "film_name"
    url = "https://api.subdl.com/api/v1/subtitles?api_key={}&{}={}&languages=EN,UK&subs_per_page=30".format(api_key, param, encoded)
    req = urllib.request.Request(url, headers={"User-Agent": "Subass/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode("utf-8-sig"))
            if not data.get("status"):
                return {"error": data.get("error", "SubDL error")}
            
            subtitles = data.get("subtitles", [])
            
            # If no subtitles but we have movie results, fetch for the first result
            if not subtitles and data.get("results"):
                first_id = data["results"][0].get("sd_id")
                if first_id:
                    new_url = "https://api.subdl.com/api/v1/subtitles?api_key={}&sd_id={}&languages=EN,UK".format(api_key, first_id)
                    new_req = urllib.request.Request(new_url, headers={"User-Agent": "Subass/1.0"})
                    with urllib.request.urlopen(new_req, timeout=10) as new_resp:
                        new_data = json.loads(new_resp.read().decode("utf-8-sig"))
                        if new_data.get("status"):
                            subtitles = new_data.get("subtitles", [])
                            # Update movie info for the merged result
                            if new_data.get("results"):
                                data["results"] = new_data["results"]

            # We want to show Movie/TV entries as folders (like Jimaku) 
            # so user can pick the right one (e.g. Movie vs TV show)
            # BUT only if we are not already searching by a specific ID.
            results = []
            movie_results = data.get("results", [])
            
            if not is_id:
                # If we have multiple results or it's a TV show, show folders
                if len(movie_results) > 1 or (movie_results and movie_results[0].get("type") == "tv"):
                    for m in movie_results:
                        results.append({
                            "title": m.get("name", query),
                            "year": m.get("year", ""),
                            "is_folder": True,
                            "sd_id": m.get("sd_id"),
                            "type": m.get("type", "movie")
                        })
                    return results
            
            # Fallback/Direct: show subtitles directly (for movies or when already inside a folder)
            subtitles = data.get("subtitles", [])
            movie_info = movie_results[0] if movie_results else {}
            title = movie_info.get("name", query)
            year = movie_info.get("year", "")
            
            for sub in subtitles:
                url_path = sub.get("url", "")
                rel_name = sub.get("release_name", "")
                display_title = rel_name if rel_name and rel_name.lower() != title.lower() else title
                
                # Detect if it's a pack / folder
                is_folder = sub.get("full_season", False)
                if not is_folder:
                    e_from = sub.get("episode_from")
                    e_end = sub.get("episode_end")
                    if e_from is not None and e_end is not None and e_from != e_end:
                        is_folder = True
                
                if not is_folder and rel_name:
                    low_rel = rel_name.lower()
                    import re
                    # Match "Pack", "Complete", "Season", or episode ranges like "E01-24" or "01-24" (if not resolution-like)
                    if "pack" in low_rel or "complete" in low_rel or "season" in low_rel:
                        is_folder = True
                    elif re.search(r"(?:^|[^0-9])(?:[es]\d+\s*-\s*\d+|\d+\s*-\s*\d+)(?:$|[^0-9])", low_rel):
                        # Avoid matching 1920-1080
                        if "1920" not in low_rel and "1280" not in low_rel:
                            is_folder = True

                results.append({
                    "title": display_title,
                    "movie_title": title,
                    "year": year,
                    "lang": sub.get("language", ""),
                    "release_name": rel_name,
                    "author": sub.get("author", ""),
                    "downloads": sub.get("download_count", 0),
                    "hi": sub.get("hi", False),
                    "is_folder": is_folder,
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
            data = json.loads(resp.read().decode("utf-8-sig"))
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
            data = json.loads(resp.read().decode("utf-8-sig"))
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

def get_subtitle_from_url(url, lang):
    """Extract subtitle for a given language from a video URL via yt-dlp."""
    import tempfile, os, glob
    tmp_dir = tempfile.gettempdir()
    # Use a unique ID for this download to avoid collisions
    uid = str(os.getpid()) + "_" + str(int(time.time()))
    out_tmpl = os.path.join(tmp_dir, f'subass_sub_{uid}_%(id)s.%(ext)s')
    
    ydl_opts = {
        'quiet': True, 
        'no_warnings': True,
        'noprogress': True,
        'writesubtitles': True, 
        'writeautomaticsub': True,
        'subtitleslangs': [lang], # Just the requested lang
        'skip_download': True,
        'noplaylist': True,
        'outtmpl': out_tmpl,
    }
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=True)
            vid_id = info.get('id', '')
        
        # Search for the file
        pattern = os.path.join(tmp_dir, f'subass_sub_{uid}_{vid_id}*')
        matches = glob.glob(pattern)
        
        if not matches:
            return {"error": f"No subtitle found for language '{lang}' in this video."}
            
        # Pick the best match (smallest extension/most likely subtitle)
        # Filters out .json if it exists
        matches = [m for m in matches if not m.endswith('.json') and not m.endswith('.info')]
        if not matches:
            return {"error": f"Subtitle file found but extension not supported."}
            
        best_match = matches[0]
        ext = best_match.rsplit('.', 1)[-1]
        
        with open(best_match, 'r', encoding='utf-8', errors='replace') as f:
            content = f.read()
        
        # Cleanup
        for m in glob.glob(pattern):
            try: os.remove(m)
            except: pass
            
        return {"status": "success", "content": content, "format": ext}
    except Exception as e:
        return {"error": str(e)}

def download_thumbnail(url, output_path):
    """Download thumbnail image to output_path."""
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Subass/1.0"})
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = resp.read()
        with open(output_path, 'wb') as f:
            f.write(data)
        return {"status": "success", "path": output_path}
    except Exception as e:
        return {"error": str(e)}

def search_subtitles(query, osub_key=None, jimaku_key=None, subdl_key=None, exclude_list=None):
    """Search for subtitles from multiple sources by title name."""
    if exclude_list is None: exclude_list = []
    
    result = {
        "query": query,
        "sources": []
    }

    # OpenSubtitles.com
    if osub_key and "opensubtitles" not in exclude_list:
        _append_source(result, "opensubtitles", search_opensubtitles(query, osub_key))

    # SubDL.com
    if subdl_key and "subdl" not in exclude_list:
        _append_source(result, "subdl", search_subdl(query, subdl_key))

    # Jimaku.cc
    if jimaku_key and "jimaku" not in exclude_list:
        _append_source(result, "jimaku", search_jimaku(query, jimaku_key))

    return result

def main():
    parser = argparse.ArgumentParser(description="Subass Download Tool (yt-dlp wrapper)")
    parser.add_argument("--target", help="URL or search query for the resource")
    parser.add_argument("--info", action="store_true", help="Get info in JSON format")
    parser.add_argument("--download", action="store_true", help="Download the resource")
    parser.add_argument("--format", help="Format ID to download")
    parser.add_argument("--type", help="Media type (video/audio)")
    parser.add_argument("--output", help="Output path for download")
    parser.add_argument("--sub-lang", help="Subtitle language to download")
    parser.add_argument("--osub-key", help="OpenSubtitles.com API key (free at opensubtitles.com)")
    parser.add_argument("--jimaku-key", help="Jimaku.cc API key for Japanese subtitles (free account required)")
    
    # Subtitle download specific
    parser.add_argument("--get-subtitle", action="store_true", help="Download subtitle content to stdout")
    parser.add_argument("--get-sub-from-url", action="store_true", help="Extract embedded subtitle from video URL")
    parser.add_argument("--download-thumb", action="store_true", help="Download thumbnail image to --output path")
    parser.add_argument("--get-jimaku-files", action="store_true", help="Get list of files for a Jimaku entry")
    parser.add_argument("--list-zip", action="store_true", help="List contents of a ZIP file")
    parser.add_argument("--source", help="Source name (opensubtitles, subdl, etc.)")
    parser.add_argument("--id", help="File ID or unique identifier for the subtitle")
    parser.add_argument("--url", help="Direct URL for the subtitle file")
    parser.add_argument("--zip-file", help="Specific file name to extract from ZIP")
    parser.add_argument("--exclude", help="Comma-separated list of sources to exclude (opensubtitles,subdl,jimaku)")
    
    args = parser.parse_args()
    target = args.target if args.target else ""

    # --- List Archive Contents (ZIP, 7z, RAR) ---
    if getattr(args, 'list_zip', False):
        if not target:
            print(json.dumps({"error": "URL is required for --list-zip"}, ensure_ascii=False))
            sys.exit(1)
        res = list_archive_contents(target)
        print(json.dumps(res, ensure_ascii=False))
        return

    # --- Jimaku File List ---
    if getattr(args, 'get_jimaku_files', False):
        if not args.id:
            print(json.dumps({"error": "Need --id for Jimaku files"}, ensure_ascii=False))
            return
        jimaku_key = getattr(args, 'jimaku_key', None) or JIMAKU_DEFAULT_KEY
        url = "https://jimaku.cc/api/entries/{}/files".format(args.id)
        headers = {"Authorization": jimaku_key}
        res = download_url_content(url, headers=headers)
        if "content" in res:
            try:
                content = res["content"]
                is_rar = res.get("format") == "rar"
                is_7z = res.get("format") == "7z"
                is_binary = res.get("is_binary", False) or isinstance(content, (bytes, bytearray))
                
                # If it's already a subtitle or an archive (RAR/7z), wrap it into a single-file list
                is_subtitle = False
                if not is_binary:
                    trimmed = content.strip()
                    if trimmed.startswith("[Script Info]") or " --> " in trimmed:
                        is_subtitle = True
                elif isinstance(content, (bytes, bytearray)):
                    if content.startswith(b"[Script Info]") or b" --> " in content:
                        is_subtitle = True
                
                if is_subtitle or is_rar or is_7z:
                    is_archive = is_rar or is_7z
                    simplified = [{
                        "file_name": "Direct Download (Archive)" if is_archive else "Direct Download (Subtitle File)",
                        "download_url": url,
                        "is_folder": is_archive, # Treat as folder so it can be expanded
                        "size": len(content) if not is_binary else 0
                    }]
                    print(json.dumps({"status": "success", "files": simplified}, ensure_ascii=False))
                    return

                # If it's binary or doesn't look like JSON, show as error
                if is_binary:
                    prev_text = str(content[:50])
                else:
                    trimmed = content.strip()
                    if not (trimmed.startswith("[") or trimmed.startswith("{")):
                        prev_text = trimmed[:50]
                    else:
                        prev_text = None # It's JSON
                
                if prev_text:
                    print(json.dumps({"error": "Jimaku повернув некоректні дані: " + prev_text + "..."}, ensure_ascii=False))
                    return
                try:
                    files = json.loads(content)
                except Exception as je:
                    print(json.dumps({"error": "Jimaku JSON parse error: " + str(je) + " | Content: " + content[:100]}, ensure_ascii=False))
                    return
                # Simplify for the UI
                simplified = []
                for f in files:
                    simplified.append({
                        "file_name": f.get("name"),
                        "download_url": f.get("url"),
                        "size": f.get("size")
                    })
                print(json.dumps({"status": "success", "files": simplified}, ensure_ascii=False))
            except:
                print(json.dumps({"error": "Failed to parse Jimaku files JSON"}, ensure_ascii=False))
        else:
            print(json.dumps(res, ensure_ascii=False))
        return

    # --- Thumbnail Download ---
    if getattr(args, 'download_thumb', False):
        if not target or not args.output:
            print(json.dumps({"error": "Need --target URL and --output PATH"}, ensure_ascii=False))
            return
        res = download_thumbnail(target, args.output)
        print(json.dumps(res, ensure_ascii=False))
        return

    # --- Subtitle from URL (embedded tracks via yt-dlp) ---
    if getattr(args, 'get_sub_from_url', False):
        if not target:
            print(json.dumps({"error": "Need --target URL"}, ensure_ascii=False))
            return
        lang = getattr(args, 'sub_lang', None) or 'en'
        res = get_subtitle_from_url(target, lang)
        print(json.dumps(res, ensure_ascii=False))
        return

    # --- Subtitle Content Download ---
    if getattr(args, 'get_subtitle', False):
        osub_key = getattr(args, 'osub_key', None) or OSUB_DEFAULT_KEY
        jimaku_key = getattr(args, 'jimaku_key', None) or JIMAKU_DEFAULT_KEY
        subdl_key = getattr(args, 'subdl_key', None) or SUBDL_DEFAULT_KEY
        
        source = getattr(args, 'source', None)
        url = getattr(args, 'url', None)
        id_ = getattr(args, 'id', None)
        zip_file = getattr(args, 'zip_file', None)

        if source == "jimaku" and (url or id_):
            res = download_jimaku(id_ or url, jimaku_key)
        elif source == "subdl" and id_:
            # This is for fetching subtitles for a specific Movie/TV ID (used in folders)
            raw_results = search_subdl(id_, subdl_key, is_id=True)
            if isinstance(raw_results, list):
                files = []
                for r in raw_results:
                    files.append({
                        "file_name": r.get("title") or r.get("release_name", "Subtitle"),
                        "download_url": r.get("download_url"),
                        "lang": r.get("lang"),
                        "hi": r.get("hi", False),
                        "is_folder": r.get("is_folder", False),
                        "zip_internal_file": r.get("zip_internal_file")
                    })
                res = {"status": "success", "files": files}
            else:
                res = raw_results
        elif (source == "opensubtitles" or not source) and id_:
            res = download_opensubtitles(id_, osub_key)
        elif (source == "subdl" or not source) and url:
            res = download_url_content(url, zip_internal_name=zip_file)
        elif url:
            res = download_url_content(url, zip_internal_name=zip_file)
        else:
            res = {"error": f"Missing data for {source or 'unknown'} download (ID:{id_}, URL:{url})"}
            
        print(json.dumps(res, ensure_ascii=False))
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
            res = download_resource(target, args.format, args.output, args.sub_lang, args.type)
            print(json.dumps(res, ensure_ascii=False))
            return
    else:
        # Plain text — search subtitles by title
        osub_key = getattr(args, 'osub_key', None) or OSUB_DEFAULT_KEY
        jimaku_key = getattr(args, 'jimaku_key', None) or JIMAKU_DEFAULT_KEY
        subdl_key = getattr(args, 'subdl_key', None) or SUBDL_DEFAULT_KEY
        
        exclude = args.exclude.split(",") if args.exclude else []
        result = search_subtitles(target, osub_key=osub_key, jimaku_key=jimaku_key, subdl_key=subdl_key, exclude_list=exclude)
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return

    parser.print_help()

if __name__ == "__main__":
    main()
