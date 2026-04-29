-- @description MP4/MKV Extract
-- @version 1.0
-- @author imnotbad
-- @required ReaImGui, js_ReaScriptAPI, FFmpeg

local r = reaper

if not r.ImGui_CreateContext then
  r.ShowMessageBox("Потрібне розширення ReaImGui.\nЗавантажте через ReaPack.", "Помилка", 0)
  return
end

if not r.JS_Dialog_BrowseForOpenFiles then
  r.ShowMessageBox("Потрібне розширення JS_ReaScriptAPI.\nЗавантажте через ReaPack.", "Помилка", 0)
  return
end

local WIN_W        = 620
local WIN_H        = 550
local IS_WIN       = package.config:sub(1, 1) == "\\"
local SEP          = IS_WIN and "\\" or "/"

local WIN_FLAGS    = r.ImGui_WindowFlags_NoResize()
    | r.ImGui_WindowFlags_NoCollapse()
    | r.ImGui_WindowFlags_NoDocking()

local CHILD_BORDER = 0
if r.ImGui_ChildFlags_Border then
  CHILD_BORDER = r.ImGui_ChildFlags_Border()
elseif r.ImGui_ChildFlags_FrameStyle then
  CHILD_BORDER = r.ImGui_ChildFlags_FrameStyle()
end

local S = {
  ctx        = nil,
  open       = true,
  file       = "",
  streams    = {},
  status     = "Оберіть .mp4/.mkv файл або перетягніть на айтем",
  diag       = "",
  processing = false,
  show_diag  = false,
}

local function trim(s)
  return (s or ""):match("^%s*(.-)%s*$")
end

local function is_supported_stream(s)
  if s.type == "video" then
    return true, "video"
  elseif s.type == "audio" then
    local supported_audio = {
      aac = true,
      mp3 = true,
      ac3 = true,
      eac3 = true,
      flac = true,
      opus = true,
      vorbis = true,
      dts = true,
      truehd = true,
      ["dts-hd"] = true,
      pcm_s16le = true,
      pcm_s24le = true,
      pcm_f32le = true,
      pcm_s16be = true,
      pcm_s24be = true
    }
    if supported_audio[s.codec] then
      return true, "audio"
    else
      return false, "audio (непідтримуваний кодек: " .. (s.codec or "unknown") .. ")"
    end
  elseif s.type == "subtitle" then
    local supported_sub = {
      subrip = true,
      srt = true,
      ass = true,
      ssa = true,
      mov_text = true,
      webvtt = true,
      text = true
    }
    if supported_sub[s.codec] then
      return true, "subtitle"
    else
      return false, "subtitle (непідтримуваний формат: " .. (s.codec or "unknown") .. ")"
    end
  else
    return false, s.type .. " (непідтримуваний тип потоку)"
  end
end

local function shell_q(p)
  if IS_WIN then
    return '"' .. p:gsub('"', '\\"') .. '"'
  else
    return "'" .. p:gsub("'", "'\\''") .. "'"
  end
end

local function find_exe(name)
  local _, script_path = r.get_action_context()
  local script_dir = script_path:match("(.*[/\\])") or ""
  local exe = IS_WIN and (name .. ".exe") or name

  local candidates = {
    script_dir .. exe,
    r.GetResourcePath() .. SEP .. "UserPlugins" .. SEP .. exe,
    r.GetResourcePath() .. SEP .. exe,
  }

  if IS_WIN then
    table.insert(candidates, "C:\\ffmpeg\\bin\\" .. exe)
    table.insert(candidates, "C:\\Program Files\\ffmpeg\\bin\\" .. exe)
    table.insert(candidates, "C:\\Program Files (x86)\\ffmpeg\\bin\\" .. exe)
    table.insert(candidates,
      os.getenv("USERPROFILE") and (os.getenv("USERPROFILE") .. "\\scoop\\apps\\ffmpeg\\current\\bin\\" .. exe) or "")
    table.insert(candidates, "C:\\ProgramData\\chocolatey\\bin\\" .. exe)
  else
    table.insert(candidates, "/usr/local/bin/" .. exe)
    table.insert(candidates, "/usr/bin/" .. exe)
    table.insert(candidates, "/opt/homebrew/bin/" .. exe)
    table.insert(candidates, "/opt/local/bin/" .. exe)
  end

  for _, c in ipairs(candidates) do
    if c ~= "" then
      local f = io.open(c, "rb")
      if f then
        f:close(); return c
      end
    end
  end
  local which_cmd = IS_WIN and ("where " .. name .. " 2>nul") or ("which " .. name .. " 2>/dev/null")
  local f = io.popen(which_cmd)
  if f then
    local found = f:read("*l")
    f:close()
    if found and trim(found) ~= "" then
      return trim(found)
    end
  end
  return exe
end

local FFPROBE = find_exe("ffprobe")
local FFMPEG  = find_exe("ffmpeg")

local function json_str_val(json, key)
  local v = json:match('"' .. key .. '"%s*:%s*"([^"]*)"')
  return v
end

local function json_num_val(json, key)
  local v = json:match('"' .. key .. '"%s*:%s*(%d+)')
  return v and tonumber(v)
end

local function parse_ffprobe_json(json_text)
  local streams = {}
  local streams_json = json_text:match('"streams"%s*:%s*%[(.-)%]%s*[,}]')
  if not streams_json then
    streams_json = json_text:match('"streams"%s*:%s*%[(.+)%]')
  end
  if not streams_json then
    return streams
  end
  local depth = 0
  local start = nil
  local i = 1
  while i <= #streams_json do
    local ch = streams_json:sub(i, i)
    if ch == "{" then
      depth = depth + 1
      if depth == 1 then start = i end
    elseif ch == "}" then
      depth = depth - 1
      if depth == 0 and start then
        local block      = streams_json:sub(start, i)
        local idx        = json_num_val(block, "index")
        local codec_type = json_str_val(block, "codec_type")
        local codec_name = json_str_val(block, "codec_name")
        local tags_block = block:match('"tags"%s*:%s*(%b{})')
        local title      = ""
        local lang       = ""
        local filename   = ""
        if tags_block then
          title = json_str_val(tags_block, "title") or
              json_str_val(tags_block, "TITLE") or ""
          lang = json_str_val(tags_block, "language") or
              json_str_val(tags_block, "LANGUAGE") or ""
          filename = json_str_val(tags_block, "filename") or
              json_str_val(tags_block, "FILENAME") or ""
        end
        local width = json_num_val(block, "width")
        local height = json_num_val(block, "height")
        local r_frame_rate = json_str_val(block, "r_frame_rate")
        local sample_rate = json_str_val(block, "sample_rate")
        local channels = json_num_val(block, "channels")
        local duration_raw = json_str_val(block, "duration")
        local duration_sec = duration_raw and tonumber(duration_raw)

        if title == "" then
          title = json_str_val(block, "filename") or
              json_str_val(block, "title") or ""
        end

        local function fmt_duration(sec)
          if not sec or sec <= 0 then return nil end
          local h = math.floor(sec / 3600)
          local m = math.floor((sec % 3600) / 60)
          local s = math.floor(sec % 60)
          if h > 0 then
            return string.format("%d:%02d:%02d", h, m, s)
          else
            return string.format("%d:%02d", m, s)
          end
        end

        local function fmt_fps(frac)
          if not frac then return nil end
          local num, den = frac:match("(%d+)/(%d+)")
          if num and den then
            den = tonumber(den)
            if den == 0 then return nil end
            local fps = tonumber(num) / den
            if math.abs(fps - math.floor(fps)) < 0.01 then
              return string.format("%d fps", math.floor(fps))
            else
              return string.format("%.2f fps", fps)
            end
          end
          return nil
        end

        if idx ~= nil and codec_type and codec_type ~= "" then
          local type_labels = {
            video      = "[V] Відео",
            audio      = "[A] Аудіо",
            subtitle   = "[S] Субтитри",
            data       = "[D] Дані",
            attachment = "[T] Вкладення",
          }
          local tl = type_labels[codec_type] or ("[?] " .. codec_type)
          if lang == "und" or lang == "N/A" then lang = "" end
          local lang_str = (lang ~= "") and (" [" .. lang .. "]") or ""
          local extra_parts = {}
          if codec_type == "video" then
            if width and height then
              table.insert(extra_parts, width .. "×" .. height)
            end
            local fps_str = fmt_fps(r_frame_rate)
            if fps_str then table.insert(extra_parts, fps_str) end
            local dur_str = fmt_duration(duration_sec)
            if dur_str then table.insert(extra_parts, dur_str) end
          elseif codec_type == "audio" then
            if sample_rate then
              local sr = tonumber(sample_rate)
              if sr then
                if sr >= 1000 then
                  table.insert(extra_parts, string.format("%.1f kHz", sr / 1000))
                else
                  table.insert(extra_parts, sr .. " Hz")
                end
              end
            end
            if channels then
              local ch_label = channels == 1 and "mono"
                  or channels == 2 and "stereo"
                  or (channels .. "ch")
              table.insert(extra_parts, ch_label)
            end
            local dur_str = fmt_duration(duration_sec)
            if dur_str then table.insert(extra_parts, dur_str) end
          end
          local extra_str = #extra_parts > 0 and ("  [" .. table.concat(extra_parts, ", ") .. "]") or ""

          local lbl
          if title ~= "" and title ~= "und" then
            lbl = string.format("%s: %s%s (%s)%s",
              tl, title, lang_str, codec_name or "?", extra_str)
          elseif filename ~= "" then
            lbl = string.format("%s: %s (%s)%s", tl, filename, codec_name or "?", extra_str)
          else
            lbl = string.format("#%d %s (%s)%s%s",
              idx, tl, codec_name or "?", lang_str, extra_str)
          end
          streams[#streams + 1] = {
            idx      = idx,
            type     = codec_type,
            codec    = codec_name or "?",
            lang     = lang,
            title    = title,
            label    = lbl,
            selected = false,
          }
        end
        start = nil
      end
    end
    i = i + 1
  end
  return streams
end

local function get_media_dir()
  local _, project_path = r.EnumProjects(-1)
  local d
  if project_path ~= "" then
    d = project_path:match("(.*)[\\/]") .. SEP .. "media"
  else
    d = r.GetResourcePath() .. SEP .. "Media"
  end
  r.RecursiveCreateDirectory(d, 0)
  return d
end

local function win_quote(path)
  path = path:gsub("/", "\\")
  return '"' .. path .. '"'
end

local function write_to_file(path, content)
  local f = io.open(path, "wb")
  if f then
    f:write(content)
    f:close()
    return true
  end
  return false
end

local function read_file(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local txt = f:read("*a")
  f:close()
  return txt
end

local function probe_streams(filepath)
  local diag = {}
  local function d(s) diag[#diag + 1] = s end
  if not filepath:lower():match("%.mp4$") and not filepath:lower():match("%.mkv$") then
    d("ПОМИЛКА: Непідтримуваний формат файлу: " .. (filepath:match("[^/\\]+$") or filepath))
    d("Підтримуються тільки .mp4 та .mkv файли")
    S.diag = table.concat(diag, "\n")
    return {}
  end
  d("Аналіз: " .. filepath)
  local test_file = io.open(filepath, "rb")
  if not test_file then
    d("ПОМИЛКА: Файл не знайдено або не вдалося відкрити")
    S.diag = table.concat(diag, "\n")
    return {}
  end
  test_file:close()
  local resource_path = r.GetResourcePath()
  local temp_dir = resource_path .. SEP .. "Scripts"
  r.RecursiveCreateDirectory(temp_dir, 0)
  local json_path = temp_dir .. SEP .. "_media_probe.json"
  local bat_path  = temp_dir .. SEP .. "_media_run.bat"
  os.remove(json_path)
  local bat_content
  if IS_WIN then
    bat_content = string.format(
      '@echo off\nchcp 65001 >nul\n"%s" -v quiet -print_format json -show_streams "%s" > "%s" 2>&1',
      FFPROBE, filepath, json_path
    )
    write_to_file(bat_path, bat_content)
    r.ExecProcess(bat_path, 0)
  else
    local cmd = string.format('%s -v quiet -print_format json -show_streams %s > %s 2>&1',
      shell_q(FFPROBE), shell_q(filepath), shell_q(json_path))
    os.execute(cmd)
  end
  local f = io.open(json_path, "rb")
  if not f then
    d("ПОМИЛКА: ffprobe не зміг створити звіт.")
    d("Можливі причини:")
    d("1. Неправильний шлях до ffprobe: " .. FFPROBE)
    d("2. Файл пошкоджений або має непідтримуваний формат")
    d("3. Спробуйте покласти відео в шлях без кирилиці для тесту")
    S.diag = table.concat(diag, "\n")
    return {}
  end
  local json = f:read("*a")
  f:close()
  os.remove(json_path)
  os.remove(bat_path)
  if not json or #json < 10 then
    d("ПОМИЛКА: Звіт ffprobe порожній або занадто короткий.")
    d("Це означає що ffprobe не зміг проаналізувати файл.")
    d("Ймовірно файл має непідтримуваний формат або пошкоджений.")
    S.diag = table.concat(diag, "\n")
    return {}
  end
  local streams = parse_ffprobe_json(json)
  if #streams > 0 then
    d("✓ Успішно знайдено: " .. #streams .. " потоків")
    local unsupported = {}
    for _, s in ipairs(streams) do
      local supported, reason = is_supported_stream(s)
      if not supported then
        table.insert(unsupported, string.format("   - Потік #%d (%s): %s", s.idx, s.type, reason))
      end
    end
    if #unsupported > 0 then
      d("⚠ УВАГА: Знайдено непідтримувані потоки:")
      for _, msg in ipairs(unsupported) do
        d(msg)
      end
      d("Такі потоки не будуть імпортовані")
    end
  else
    d("ПОМИЛКА: Не вдалося розпізнати структуру JSON")
    d("Можливо файл не містить жодних потоків або має нестандартну структуру")
  end

  S.diag = table.concat(diag, "\n")
  return streams
end

local function stream_ext(s)
  if s.type == "video" then
    local container = "mkv"
    if S.file:lower():match("%.mp4$") then container = "mp4" end
    return container
  end
  if s.type == "subtitle" then
    local sub_ext = {
      ass = "ass",
      ssa = "ass",
      subrip = "srt",
      srt = "srt",
      mov_text = "srt",
      webvtt = "vtt",
      text = "srt",
    }
    return sub_ext[s.codec] or "srt"
  end
  if s.type == "audio" then
    local m = {
      aac = "m4a",
      mp3 = "mp3",
      ac3 = "ac3",
      eac3 = "eac3",
      flac = "flac",
      wav = "wav",
      opus = "opus",
      vorbis = "ogg",
      dts = "dts",
      truehd = "thd",
      ["dts-hd"] = "dts",
      pcm_s16le = "wav",
      pcm_s24le = "wav",
      pcm_f32le = "wav",
      pcm_s16be = "wav",
      pcm_s24be = "wav"
    }
    return m[s.codec] or "wav"
  end
  local codec_to_ext = {
    ttf = "ttf",
    otf = "otf",
    woff = "woff",
    woff2 = "woff2",
    eot = "eot",
    png = "png",
    jpg = "jpg",
    jpeg = "jpg",
    gif = "gif",
    webp = "webp",
    bmp = "bmp",
    tiff = "tiff",
    ico = "ico",
    zip = "zip",
    ["7z"] = "7z",
    rar = "rar",
    gz = "gz",
    tar = "tar",
    bz2 = "bz2",
    xz = "xz",
    zst = "zst",
    pdf = "pdf",
    xml = "xml",
    json = "json",
    txt = "txt",
    html = "html",
    css = "css",
    js = "js",
    bin = "bin",
    dat = "dat",
    icc = "icc",
  }
  if s.codec and codec_to_ext[s.codec] then
    return codec_to_ext[s.codec]
  end
  if s.title and s.title ~= "" then
    local ext_from_title = s.title:match("%.([^%.]+)$")
    if ext_from_title then
      return ext_from_title:lower()
    end
  end
  if s.codec and s.codec ~= "?" and s.codec ~= "" then
    return s.codec:gsub("[^%w]", "_")
  end
  return "bin"
end

local function safe_filename(s)
  return s:gsub('[%*%?%|%<%>%":/\\]+', "_")
end

local function extract_stream(src, s, media_dir)
  local resource_path = r.GetResourcePath()
  local bat_path = resource_path .. SEP .. "Scripts" .. SEP .. "_mkv_extract.bat"

  local base = (src:match("[/\\]([^/\\]+)$") or "track"):gsub("%.[^%.]+$", "")
  local lang_sfx = (s.lang ~= "") and ("_" .. s.lang) or ""
  local ext = stream_ext(s)
  local out_path = media_dir .. SEP .. safe_filename(string.format("%s_s%d%s.%s", base, s.idx, lang_sfx, ext))
  local codec_flag = "-c copy"
  if IS_WIN then
    local bat_content = string.format(
      '@echo off\nchcp 65001 >nul\n"%s" -y -i "%s" -map 0:%d %s "%s"',
      FFMPEG, src, s.idx, codec_flag, out_path
    )
    write_to_file(bat_path, bat_content)
    r.ExecProcess(bat_path, 0)
    os.remove(bat_path)
  else
    local cmd = string.format('%s -y -i %s -map 0:%d %s %s 2>&1',
      shell_q(FFMPEG), shell_q(src), s.idx, codec_flag, shell_q(out_path))
    os.execute(cmd)
  end
  local f = io.open(out_path, "rb")
  if f then
    local size = f:seek("end")
    f:close()
    if size and size > 0 then return out_path end
  end
  return nil
end

local function srt_to_sec(ts)
  local h, m, s, ms = ts:match("(%d+):(%d+):(%d+)[,.](%d+)")
  if not h then return 0 end
  return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s) + tonumber(ms) / 1000
end

local function import_srt_regions(path)
  local f = io.open(path, "r")
  if not f then return 0 end
  local txt = f:read("*a"); f:close()
  txt = txt .. "\n\n"
  local n = 0
  local state = "num"
  local t0, t1, buf = 0, 0, {}
  for line in txt:gmatch("([^\r\n]*)\r?\n") do
    line = trim(line)
    if state == "num" then
      if line:match("^%d+$") then state = "time" end
    elseif state == "time" then
      local s0, s1 = line:match(
        "(%d+:%d+:%d+[,.]%d+)%s*%-%-%>%s*(%d+:%d+:%d+[,.]%d+)")
      if s0 then
        t0, t1, buf = srt_to_sec(s0), srt_to_sec(s1), {}
        state = "text"
      else
        state = "num"
      end
    elseif state == "text" then
      if line == "" then
        local text = table.concat(buf, " "):gsub("<[^>]+>", "")
        if text ~= "" then
          r.AddProjectMarker2(0, true, t0, t1, text, -1, 0)
          n = n + 1
        end
        state = "num"
      else
        buf[#buf + 1] = line
      end
    end
  end
  return n
end

local function ass_to_sec(ts)
  local h, m, s, cs = ts:match("(%d+):(%d+):(%d+)%.(%d+)")
  if not h then return 0 end
  return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s) + tonumber(cs) / 100
end

local function import_ass_regions(path)
  local f = io.open(path, "r")
  if not f then return 0 end
  local txt = f:read("*a"); f:close()
  local n = 0
  for line in txt:gmatch("[^\r\n]+") do
    local start, stop, text = line:match(
    "^Dialogue:%s*%d+,([%d:%.]+),([%d:%.]+),[^,]*,[^,]*,[^,]*,[^,]*,[^,]*,[^,]*,(.*)")
    if start and stop and text then
      -- Видаляємо теги {\...}
      text = text:gsub("{[^}]*}", ""):gsub("\\N", " "):gsub("\\n", " ")
      text = trim(text)
      if text ~= "" then
        r.AddProjectMarker2(0, true, ass_to_sec(start), ass_to_sec(stop), text, -1, 0)
        n = n + 1
      end
    end
  end
  return n
end

local function import_subtitle_regions(path)
  if path:lower():match("%.ass$") then
    return import_ass_regions(path)
  else
    return import_srt_regions(path)
  end
end

local function load_file(path)
  path = trim(path)
  if path == "" then return end
  path = path:gsub('^"(.*)"$', "%1")
  path = path:gsub("^'(.*)'$", "%1")
  local file_lower = path:lower()
  if not file_lower:match("%.mp4$") and not file_lower:match("%.mkv$") then
    local ext = path:match("%.([^%.]+)$") or "без розширення"
    S.status = "Непідтримуваний формат: ." .. ext
    S.diag = string.format("ПОМИЛКА: Файл '%s' має непідтримуваний формат '.%s'\n",
      (path:match("[^/\\]+$") or path), ext)
    S.diag = S.diag .. "Підтримуються тільки .mp4 та .mkv файли\n"
    S.diag = S.diag .. "Обраний файл: " .. path
    S.show_diag = false
    S.streams = {}
    return
  end

  S.file      = path
  S.status    = "Аналізую потоки…"
  S.streams   = {}
  S.diag      = ""
  S.show_diag = false
  S.streams   = probe_streams(path)

  if #S.streams > 0 then
    local supported_count = 0
    local unsupported_list = {}
    for _, s in ipairs(S.streams) do
      local supported, reason = is_supported_stream(s)
      if supported then
        supported_count = supported_count + 1
      else
        table.insert(unsupported_list, string.format("   #%d: %s (%s)", s.idx, s.type, s.codec or "unknown"))
      end
    end
    if supported_count > 0 then
      S.status = string.format("✓ Знайдено %d потоків (%d підтримується) — оберіть та натисніть «Імпортувати»",
        #S.streams, supported_count)
    else
      S.status = "⚠ Знайдено потоки, але жоден не підтримується для імпорту"
    end
    if #unsupported_list > 0 then
      local diag_msg = "⚠ Непідтримувані потоки:\n" .. table.concat(unsupported_list, "\n")
      if S.diag ~= "" then
        S.diag = S.diag .. "\n\n" .. diag_msg
      else
        S.diag = diag_msg
      end
      S.show_diag = false
    end
  else
    S.status    = "Потоки не знайдено — натисніть «Діагностика» для деталей"
    S.show_diag = false
  end
end

local function get_selected_item_media()
  local n = r.CountSelectedMediaItems(0)
  for i = 0, n - 1 do
    local item   = r.GetSelectedMediaItem(0, i)
    local take   = item and r.GetActiveTake(item)
    local source = take and r.GetMediaItemTake_Source(take)
    if source then
      local fname = r.GetMediaSourceFileName(source, "")
      if fname and (fname:lower():match("%.mp4$") or fname:lower():match("%.mkv$")) then
        return fname
      end
    end
  end
  return nil
end

local function get_next_track_number()
  local track_count = r.CountTracks(0)
  local max_track_num = 0

  for i = 0, track_count - 1 do
    local track = r.GetTrack(0, i)
    local track_num = r.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
    if track_num > max_track_num then
      max_track_num = math.floor(track_num)
    end
  end

  return max_track_num + 1
end

local function insert_media_on_new_track(file_path, cursor_pos)
  local new_track_num = get_next_track_number()
  r.InsertTrackAtIndex(new_track_num - 1, true)
  local new_track = r.GetTrack(0, new_track_num - 1)
  r.SetOnlyTrackSelected(new_track)
  local edit_cursor = r.GetCursorPosition()
  if cursor_pos then
    r.SetEditCurPos(cursor_pos, false, false)
  end
  r.InsertMedia(file_path, 0)
  r.SetEditCurPos(edit_cursor, false, false)
end

local function do_import(src, streams_list)
  local mdir = get_media_dir()
  local ok, err, regs = 0, 0, 0
  local error_details = {}
  local first_track = true
  local common_cursor_pos = nil
  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)
  for _, s in ipairs(streams_list) do
    if s.selected then
      local supported, reason = is_supported_stream(s)
      if not supported then
        err = err + 1
        table.insert(error_details, string.format("Потік #%d (%s) пропущено: %s", s.idx, s.type, reason))
        S.status = string.format("⚠ Потік #%d пропущено: %s", s.idx, reason)
      else
        S.status = string.format("Витягую #%d (%s %s)…", s.idx, s.type, s.codec)
        local out = extract_stream(src, s, mdir)
        if out then
          if s.type == "subtitle" then
            local n = import_subtitle_regions(out)
            regs = regs + n
            S.status = string.format("SRT: %d регіонів додано", n)
          else
            if first_track then
              common_cursor_pos = r.GetCursorPosition()
              first_track = false
            end
            insert_media_on_new_track(out, common_cursor_pos)
          end
          ok = ok + 1
        else
          err = err + 1
          table.insert(error_details, string.format("Потік #%d (%s) не вдалося витягнути", s.idx, s.type))
          S.status = string.format("❌ Помилка витягування потоку #%d", s.idx)
        end
      end
    end
  end
  r.PreventUIRefresh(-1)
  r.UpdateArrange()
  r.Undo_EndBlock("MKV/MP4 Extract", -1)
  if err == 0 then
    S.status = string.format("✓ Готово: %d потік(и) імпортовано, %d SRT регіон(и)", ok, regs)
  else
    local diag_msg = string.format("Завершено: %d OK / %d помилок\n", ok, err)
    for _, detail in ipairs(error_details) do
      diag_msg = diag_msg .. detail .. "\n"
    end
    S.diag = diag_msg
    S.status = string.format("⚠ Завершено: %d OK / %d помилок (дивись діагностику)", ok, err)
    S.show_diag = false
  end
  S.processing = false
end

local C = {
  win_bg    = 0x333333ff,
  title_bg  = 0x262626ff,
  btn       = 0x4d4d4dff,
  btn_hov   = 0x737373ff,
  btn_act   = 0x737373ff,
  btn_dis   = 0x1e1e3aff,
  btn_diag  = 0x3a2a10ff,
  text      = 0xd6d6d6ff,
  text_dim  = 0x858585ff,
  text_cyan = 0x66ccffff,
  text_warn = 0xffcc44ff,
  text_ok   = 0x55ff99ff,
  text_err  = 0xff5566ff,
  col_v     = 0xffcc55ff,
  col_a     = 0x55ffbbff,
  col_s     = 0xff88eeff,
  col_d     = 0x8888bbff,
  child_bg  = 0x0d0d1aff,
  diag_bg   = 0x0a0a14ff,
  drop_bg   = 0x181830ff,
  sep       = 0x333366ff,
}

local function push_colors(ctx)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_WindowBg(), C.win_bg)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_TitleBg(), C.title_bg)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_TitleBgActive(), C.title_bg)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), C.btn)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), C.btn_hov)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(), C.btn_act)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), C.text)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ChildBg(), C.child_bg)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), 0x1a1a2eff)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_CheckMark(), 0x77ddffff)

  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Separator(), C.btn)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_CheckMark(), 0x77ddffff)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_CheckMark(), 0x77ddffff)

  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ScrollbarGrab(), C.btn)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), C.title_bg)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBgHovered(), C.btn)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBgActive(), C.btn)
  return 17
end

local function draw_ui()
  local ctx = S.ctx
  if S.font then r.ImGui_PushFont(ctx, S.font, 13) end
  local n_colors = push_colors(ctx)
  r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_WindowRounding(), 10.0)
  r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FrameRounding(), 7.0)
  r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_TabRounding(), 5.0)
  r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_PopupRounding(), 8.0)
  r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_WindowTitleAlign(), 0.5, 0.5)
  r.ImGui_SetNextWindowSize(ctx, WIN_W, WIN_H, r.ImGui_Cond_Always())

  local vis, open = r.ImGui_Begin(ctx, "MKV/MP4 Extract", true, WIN_FLAGS)
  S.open = open

  if vis then
    local inner_w = WIN_W - 16
    local cur_y = r.ImGui_GetCursorPosY(ctx)

    -- ── ВЕРХНЯ ЗОНА ──────────────────────────
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ChildBg(), C.drop_bg)
    if r.ImGui_BeginChild(ctx, "##dropzone", inner_w, 48, CHILD_BORDER, 0) then
      r.ImGui_SetCursorPos(ctx, 8, 6)
      if S.file == "" then
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), C.text_dim)
        r.ImGui_Text(ctx, "Файл не обрано")
        r.ImGui_PopStyleColor(ctx)
      else
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), C.text_cyan)
        local filename = S.file:match("[/\\]([^/\\]+)$") or S.file
        r.ImGui_Text(ctx, "▶  " .. filename)
        r.ImGui_PopStyleColor(ctx)
        if r.ImGui_IsItemHovered(ctx) then r.ImGui_SetTooltip(ctx, S.file) end
      end

      r.ImGui_SetCursorPos(ctx, 8, 26)
      r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), C.text_dim)
      r.ImGui_Text(ctx, "ffprobe: " .. (FFPROBE:match("[/\\]([^/\\]+)$") or FFPROBE))
      r.ImGui_PopStyleColor(ctx)
      r.ImGui_EndChild(ctx)
    end
    r.ImGui_PopStyleColor(ctx)
    r.ImGui_Spacing(ctx)
    local hw = math.floor((inner_w - 4) / 2.01)
    if r.ImGui_Button(ctx, "Обрати mp4/mkv файл…", hw, 30) then
      local extension_mask = "Video files (*.mp4, *.mkv)\0*.mp4;*.mkv\0All Files (*.*)\0*.*\0"
      local ok, f = r.JS_Dialog_BrowseForOpenFiles("Обрати MP4/MKV файл", "", "", extension_mask, false)
      if ok and f and f ~= "" then
        f = f:gsub("%z.*", "")
        local f_lower = f:lower()
        if f_lower:match("%.mp4$") or f_lower:match("%.mkv$") then
          load_file(f)
        else
          S.status = "Підтримуються тільки .mp4 та .mkv файли"
        end
      end
    end
    r.ImGui_SameLine(ctx)
    if r.ImGui_Button(ctx, "З файлу проєкта", hw, 30) then
      local f = get_selected_item_media()
      if f then load_file(f) else S.status = "Немає виділеного MP4/MKV" end
    end
    r.ImGui_Spacing(ctx)
    r.ImGui_TextColored(ctx, C.text_dim, "Доріжки (потоки) файлу:")
    r.ImGui_SameLine(ctx)
    if #S.streams > 0 then
      r.ImGui_SetCursorPosX(ctx, inner_w - 290)
      if r.ImGui_Button(ctx, "Виділити всі...##select_all", 145, 0) then
        for _, s in ipairs(S.streams) do
          local supported, _ = is_supported_stream(s)
          s.selected = supported
        end
      end
      if r.ImGui_IsItemHovered(ctx) then
        r.ImGui_BeginTooltip(ctx)
        r.ImGui_Text(ctx, "Виділити всі потоки, які підтримуються для імпорту")
        r.ImGui_EndTooltip(ctx)
      end
      r.ImGui_SameLine(ctx) 
      local any_selected = false
      for _, s in ipairs(S.streams) do 
        if s.selected then
          any_selected = true
          break
        end 
      end 
      if not any_selected then 
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), C.text_dim) 
      end
      if r.ImGui_Button(ctx, "Зняти все##clear_all", 145, 0) then
        if any_selected then
          for _, s in ipairs(S.streams) do 
            s.selected = false 
          end
        end
      end
      if not any_selected then 
        r.ImGui_PopStyleColor(ctx) 
      end
    end
    
    r.ImGui_Spacing(ctx)
    r.ImGui_Spacing(ctx)

    -- ── СЕРЕДНЯ ЗОНА ──────────
    local bottom_reserved = S.show_diag and 230 or 140
    local list_h = WIN_H - r.ImGui_GetCursorPosY(ctx) - bottom_reserved
    if list_h < 100 then list_h = 100 end
    if r.ImGui_BeginChild(ctx, "##streams_scroll", inner_w, list_h, CHILD_BORDER, r.ImGui_WindowFlags_AlwaysVerticalScrollbar()) then
      if #S.streams == 0 then
        r.ImGui_TextColored(ctx, C.text_dim, "   — потоки не знайдено —")
      else
        for i, s in ipairs(S.streams) do
          if i > 1 then
            r.ImGui_Separator(ctx)
          end
          local col = C.text
          if s.type == "video" then
            col = C.col_v
          elseif s.type == "audio" then
            col = C.col_a
          elseif s.type == "subtitle" then
            col = C.col_s
          end
          r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), col)
          local changed, newval = r.ImGui_Checkbox(ctx, s.label .. "##s" .. i, s.selected)
          r.ImGui_PopStyleColor(ctx)
          if changed then S.streams[i].selected = newval end
          if r.ImGui_IsItemHovered(ctx) then
            r.ImGui_BeginTooltip(ctx)
            r.ImGui_Text(ctx, s.label)
            r.ImGui_EndTooltip(ctx)
          end
        end
      end
      r.ImGui_EndChild(ctx)
    end

    -- ── НИЖНЯ ЗОНА ───────────────
    r.ImGui_Spacing(ctx)
    if S.file ~= "" and #S.streams > 0 then
      local any = false
      for _, s in ipairs(S.streams) do if s.selected then
          any = true; break
        end end
      local disabled = not any or S.processing
      local selected_count = 0
      for _, s in ipairs(S.streams) do
        if s.selected then
          selected_count = selected_count + 1
        end
      end
      local btn_import_w = math.floor((inner_w - 4) / 2)
      local btn_save_w   = inner_w - btn_import_w - 8
      if disabled then r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), C.text_dim) end
      if r.ImGui_Button(ctx, S.processing and "  Обробка…" or "Імпортувати обрані доріжки", btn_import_w, 30) then
        if not disabled then
          S.processing = true; do_import(S.file, S.streams)
        end
      end
      if disabled then r.ImGui_PopStyleColor(ctx) end
      r.ImGui_SameLine(ctx)
      local save_disabled = (selected_count == 0) or S.processing
      if save_disabled then r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), C.text_dim) end
      if r.ImGui_Button(ctx, "Зберегти як файл", btn_save_w, 30) then
        if not save_disabled then
          local init_dir = S.file:match("(.*)[/\\]") or ""
          local ok_dir, out_dir = r.JS_Dialog_BrowseForFolder("Обрати папку для збереження потоків", init_dir)
          if ok_dir and out_dir and out_dir ~= "" then
            out_dir = out_dir:gsub("%z.*", "")
            local saved, failed = 0, 0
            local base = (S.file:match("[/\\]([^/\\]+)$") or "track"):gsub("%.[^%.]+$", "")
            local resource_path = r.GetResourcePath()
            for _, s in ipairs(S.streams) do
              if s.selected then
                local ext = stream_ext(s)
                local lang_sfx = (s.lang ~= "") and ("_" .. s.lang) or ""
                local out_path = out_dir .. SEP .. safe_filename(
                  string.format("%s_s%d%s.%s", base, s.idx, lang_sfx, ext)
                )
                S.status = "Зберігаю потік #" .. s.idx .. "…"
                local bat_path = resource_path .. SEP .. "Scripts" .. SEP .. "_mkv_save_as.bat"
                local ffmpeg_cmd
                if s.type == "attachment" then
                  ffmpeg_cmd = string.format(
                    '"%s" -y -dump_attachment:%d "%s" -i "%s"',
                    FFMPEG, s.idx, out_path, S.file
                  )
                else
                  ffmpeg_cmd = string.format(
                    '"%s" -y -i "%s" -map 0:%d -c copy "%s"',
                    FFMPEG, S.file, s.idx, out_path
                  )
                end
                if IS_WIN then
                  local bat = string.format('@echo off\nchcp 65001 >nul\n%s', ffmpeg_cmd)
                  write_to_file(bat_path, bat)
                  r.ExecProcess(bat_path, 0)
                  os.remove(bat_path)
                else
                  if s.type == "attachment" then
                    ffmpeg_cmd = string.format(
                      '%s -y -dump_attachment:%d %s -i %s',
                      shell_q(FFMPEG), s.idx, shell_q(out_path), shell_q(S.file)
                    )
                  else
                    ffmpeg_cmd = string.format(
                      '%s -y -i %s -map 0:%d -c copy %s 2>&1',
                      shell_q(FFMPEG), shell_q(S.file), s.idx, shell_q(out_path)
                    )
                  end
                  os.execute(ffmpeg_cmd)
                end
                local fcheck = io.open(out_path, "rb")
                if fcheck then
                  local sz = fcheck:seek("end"); fcheck:close()
                  if sz and sz > 0 then
                    saved = saved + 1
                  else
                    failed = failed + 1
                  end
                else
                  failed = failed + 1
                end
              end
            end
            if failed == 0 then
              S.status = string.format("✓ Збережено %d файл(ів) у: %s",
                saved, (out_dir:match("[/\\]([^/\\]+)$") or out_dir))
            else
              S.status = string.format("⚠ Збережено: %d / Помилок: %d", saved, failed)
            end
          end
        end
      end
      if save_disabled then r.ImGui_PopStyleColor(ctx) end
    end
    r.ImGui_Spacing(ctx)
    local sc = C.text_dim
    if S.status:find("✓") then
      sc = C.text_ok
    elseif S.status:find("Немає виділеного MP4/MKV") or S.status:find("Помилка") or S.status:find("не знайдено") then
      sc = C.text_err
    end
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), sc)
    r.ImGui_TextWrapped(ctx, S.status)
    r.ImGui_PopStyleColor(ctx)
    -- ── Панель діагностики ───────────────────────────────
    r.ImGui_Spacing(ctx)
    if S.font then r.ImGui_PushFont(ctx, S.font, 11) end
    local diag_label = S.show_diag and "▼ Діагностика (сховати)" or "▶ Діагностика (показати)"
    if r.ImGui_Button(ctx, diag_label, inner_w, 20) then
      S.show_diag = not S.show_diag
    end
    if S.font then r.ImGui_PopFont(ctx) end
    if S.show_diag and S.diag ~= "" then
      r.ImGui_Spacing(ctx)
      r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ChildBg(), C.diag_bg)
      if r.ImGui_BeginChild(ctx, "##diag", inner_w, 120, CHILD_BORDER, 0) then
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), C.text_warn)
        r.ImGui_TextWrapped(ctx, S.diag:sub(1, 1200))
        r.ImGui_PopStyleColor(ctx)
        r.ImGui_EndChild(ctx)
      end
      r.ImGui_PopStyleColor(ctx)
    end
  end
  if S.font then r.ImGui_PopFont(ctx) end
  r.ImGui_PopStyleVar(ctx, 5)
  r.ImGui_End(ctx)
  r.ImGui_PopStyleColor(ctx, n_colors)
end

S.ctx = r.ImGui_CreateContext("MKV/MP4 Extract")

if r.ImGui_CreateFont then
  local font_paths
  if IS_WIN then
    font_paths = {
      "C:\\Windows\\Fonts\\segoeui.ttf",
      "C:\\Windows\\Fonts\\calibri.ttf",
      "C:\\Windows\\Fonts\\arial.ttf",
      "C:\\Windows\\Fonts\\tahoma.ttf",
    }
  else
    font_paths = {
      "/System/Library/Fonts/Supplemental/Arial.ttf",
      "/System/Library/Fonts/Helvetica.ttc",
      "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
      "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
    }
  end
  for _, fp in ipairs(font_paths) do
    local f = io.open(fp, "rb")
    if f then
      f:close()
      local font = r.ImGui_CreateFont(fp, 16)
      if font then
        r.ImGui_Attach(S.ctx, font)
        S.font = font
      end
      break
    end
  end
end

do
  local f = io.open(FFMPEG, "rb")
  if not f then
    S.status    = "⚠ ffmpeg не знайдено! Діагностика для деталей."
    S.diag      = "ffmpeg шлях: " .. FFMPEG .. "\n"
        .. "ffprobe шлях: " .. FFPROBE .. "\n\n"
        .. "Покладіть ffmpeg.exe і ffprobe.exe у папку:\n"
        .. r.GetResourcePath() .. "\\UserPlugins\\\n\n"
        .. "або у ту ж папку що й цей скрипт.\n"
        .. "або встановіть FFmpeg і додайте до системного PATH."
    S.show_diag = true
  else
    f:close()
    S.diag = "✓ ffmpeg: " .. FFMPEG .. "\n✓ ffprobe: " .. FFPROBE
  end
end

local function loop()
  if not S.open then return end
  draw_ui()
  r.defer(loop)
end

r.defer(loop)
