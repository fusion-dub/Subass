-- @description MP4/MKV Extract
-- @version 1.2
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
  ctx                   = nil,
  open                  = true,
  file                  = "",
  streams               = {},
  status                = "Оберіть .mp4 або .mkv файл",
  diag                  = "",
  processing            = false,
  show_diag             = false,
  show_replace_menu     = false,
  replace_modal         = {
    open = false,
    audio_file = "",
    audio_streams = {},
    keep_subs = true,
    keep_other_audio = true,
    encode_audio = false,
    encode_format = "aac",
    encode_bitrate = "192k",
    processing = false,
    progress = 0,
    progress_text = ""
  },
  preview_sub           = {
    content    = nil,
    title      = nil,
    stream_idx = nil,
    open       = false
  },
  subtitle_import_modal = {
    open = false,
    subtitle_file = "",
    subtitle_content = nil,
    subtitle_lang = "ukr",
    subtitle_title = "",
    keep_existing_subs = true,
    processing = false,
    progress = 0,
    progress_text = "",
    visual_progress = 0
  },
  selected_channels     = {},
  audio_preview         = {
    source             = nil,
    file               = nil,
    playing            = false,
    paused             = false,
    pause_pos          = 0,
    length             = 0,
    name               = "",
    current_stream_idx = nil,
    preview_channels   = {}
  }
}

local C = {
  win_bg    = 0x2c2c34ff,
  title_bg  = 0x24242aff,
  btn       = 0x3e3e48ff,
  btn_hov   = 0x5a5a66ff,
  btn_act   = 0x6e6e7cff,
  btn_dis   = 0x2a2a30ff,
  btn_diag  = 0x4a3a28ff,
  text      = 0xeaeaefff,
  text_dim  = 0xa0a0b0ff,
  text_cyan = 0x7ad0ffff,
  text_warn = 0xffcc66ff,
  text_ok   = 0x88f7b0ff,
  text_err  = 0xff7a8aff,
  col_v     = 0xffcc66ff,
  col_a     = 0x77f7ccff,
  col_s     = 0xffaaddff,
  col_d     = 0xb0b0ddff,
  child_bg  = 0x1e1e24ff,
  diag_bg   = 0x18181eff,
  drop_bg   = 0x26262eff,
  sep       = 0x4a4a5eff,
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
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), C.win_bg)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Separator(), C.btn)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_CheckMark(), C.text_ok)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_PopupBg(), C.win_bg)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ScrollbarGrab(), C.btn)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), C.title_bg)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBgHovered(), C.btn)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBgActive(), C.btn)
  return 16
end

local _, script_path = r.get_action_context()
local SCRIPT_DIR = script_path:match("(.*[/\\])") or ""
local TEMP_PREVIEW_DIR = SCRIPT_DIR .. "temp_preview" .. SEP

local function write_to_file(path, content)
  local f = io.open(path, "wb")
  if f then
    f:write(content)
    f:close()
    return true
  end
  return false
end

local async_tasks = {}

local function poll_task_queue()
  if #async_tasks == 0 then return end
  for i = #async_tasks, 1, -1 do
    local task = async_tasks[i]
    local f = io.open(task.done_file, "r")
    if f then
      f:close()
      local out_content = nil
      local f_out = io.open(task.out_file, "r")
      if f_out then
        out_content = f_out:read("*a")
        f_out:close()
      end
      os.remove(task.done_file)
      if task.out_file then os.remove(task.out_file) end
      table.remove(async_tasks, i)
      if task.callback and out_content and out_content ~= "" then
        task.callback(task.out_file)
      elseif task.callback then
        task.callback(nil)
      end
    end
  end
end

local function run_ffmpeg_async(cmd, on_done)
  local resource_path = r.GetResourcePath()
  local id = tostring(os.time()) .. "_" .. math.random(1000, 9999)
  local script_dir = resource_path .. SEP .. "Scripts" .. SEP
  local out_file = script_dir .. "ffmpeg_out_" .. id .. ".tmp"
  local done_file = script_dir .. "ffmpeg_done_" .. id .. ".marker"
  local bat_file = script_dir .. "ffmpeg_exec_" .. id .. ".bat"
  os.remove(done_file)
  os.remove(out_file)
  if IS_WIN then
    local f_bat = io.open(bat_file, "w")
    if not f_bat then
      if on_done then on_done(nil) end
      return
    end
    f_bat:write("@echo off\r\n")
    f_bat:write("chcp 65001 > NUL\r\n")
    f_bat:write(cmd .. ' > "' .. out_file .. '" 2>&1\r\n')
    f_bat:write('echo DONE > "' .. done_file .. '"\r\n')
    f_bat:write('del "' .. bat_file .. '"\r\n')
    f_bat:close()
    local ps_cmd = 'powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "Start-Process \\"' ..
        bat_file .. '\\" -WindowStyle Hidden"'
    r.ExecProcess(ps_cmd, 0)
    table.insert(async_tasks, {
      id = id,
      out_file = out_file,
      done_file = done_file,
      callback = on_done
    })
  else
    local sh_file = script_dir .. "ffmpeg_exec_" .. id .. ".sh"
    local f_sh = io.open(sh_file, "w")
    if not f_sh then
      if on_done then on_done(nil) end
      return
    end
    f_sh:write("#!/bin/bash\n")
    f_sh:write(cmd .. ' > "' .. out_file .. '" 2>&1\n')
    f_sh:write('echo DONE > "' .. done_file .. '"\n')
    f_sh:write('rm "$0"\n')
    f_sh:close()
    os.execute('chmod +x "' .. sh_file .. '"')
    local full_cmd = '( "' .. sh_file .. '" ) &'
    os.execute(full_cmd)
    table.insert(async_tasks, {
      id = id,
      out_file = out_file,
      done_file = done_file,
      callback = on_done
    })
  end
end

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

local function build_pan_filter(selected_list)
  if #selected_list == 1 then
    return string.format("pan=mono|c0=c%d", selected_list[1] - 1)
  elseif #selected_list == 2 then
    return string.format("pan=stereo|c0=c%d|c1=c%d", selected_list[1] - 1, selected_list[2] - 1)
  else
    local parts = {}
    for i, ch in ipairs(selected_list) do
      table.insert(parts, string.format("c%d=c%d", i - 1, ch - 1))
    end
    return string.format("pan=%dc|%s", #selected_list, table.concat(parts, "|"))
  end
end

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
            channels = channels or 0,
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
      d("УВАГА: Знайдено непідтримувані потоки:")
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

local function extract_stream_async(src, s, media_dir, on_done)
  local base = (src:match("[/\\]([^/\\]+)$") or "track"):gsub("%.[^%.]+$", "")
  local lang_sfx = (s.lang ~= "") and ("_" .. s.lang) or ""
  local ext = stream_ext(s)
  local out_path = media_dir .. SEP .. safe_filename(
    string.format("%s_s%d%s.%s", base, s.idx, lang_sfx, ext)
  )
  local ffmpeg_cmd = string.format(
    '"%s" -y -i "%s" -map 0:%d -c copy "%s"',
    FFMPEG, src, s.idx, out_path
  )
  run_ffmpeg_async(ffmpeg_cmd, function()
    local f = io.open(out_path, "rb")
    if f then
      local size = f:seek("end")
      f:close()
      if size and size > 0 then
        on_done(out_path)
        return
      end
    end
    os.remove(out_path)
    on_done(nil)
  end)
end

local function stop_audio_preview()
  if S.audio_preview.source then
    r.CF_Preview_Stop(S.audio_preview.source)
    S.audio_preview.source = nil
  end
  S.audio_preview.file = nil
  S.audio_preview.playing = false
  S.audio_preview.paused = false
  S.audio_preview.pause_pos = 0
  S.audio_preview.length = 0
  S.audio_preview.name = nil
  S.audio_preview.current_stream_idx = nil
  S.audio_preview.preview_channels = {}
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
  S.file              = path
  S.status            = "Аналізую потоки…"
  S.streams           = {}
  S.diag              = ""
  S.show_diag         = false
  S.streams           = probe_streams(path)
  S.selected_channels = {}
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
      S.status = "Знайдено потоки, але жоден не підтримується для імпорту"
    end
    if #unsupported_list > 0 then
      local diag_msg = "Непідтримувані потоки:\n" .. table.concat(unsupported_list, "\n")
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

local function read_subtitle_preview(path, max_chars)
  local f = io.open(path, "rb")
  if not f then return nil end
  local content = f:read("*all")
  f:close()
  if not content or content == "" then return nil end
  return content
end

local function probe_audio_file(filepath)
  local streams = {}
  local resource_path = r.GetResourcePath()
  local temp_dir = resource_path .. SEP .. "Scripts"
  r.RecursiveCreateDirectory(temp_dir, 0)
  local json_path = temp_dir .. SEP .. "_audio_probe.json"
  os.remove(json_path)
  local cmd
  if IS_WIN then
    local bat_path = temp_dir .. SEP .. "_audio_run.bat"
    local bat_content = string.format(
      '@echo off\nchcp 65001 >nul\n"%s" -v quiet -print_format json -show_streams "%s" > "%s" 2>&1',
      FFPROBE, filepath, json_path
    )
    write_to_file(bat_path, bat_content)
    r.ExecProcess(bat_path, 0)
    os.remove(bat_path)
  else
    cmd = string.format('%s -v quiet -print_format json -show_streams %s > %s 2>&1',
      shell_q(FFPROBE), shell_q(filepath), shell_q(json_path))
    os.execute(cmd)
  end
  local f = io.open(json_path, "rb")
  if f then
    local json = f:read("*a")
    f:close()
    os.remove(json_path)
    if json and #json > 10 then
      streams = parse_ffprobe_json(json)
    end
  end
  local audio_only = {}
  for _, s in ipairs(streams) do
    if s.type == "audio" then
      s.selected = (#audio_only == 0)
      table.insert(audio_only, s)
    end
  end
  return audio_only
end

local function draw_subtitle_preview()
  if not S.preview_sub.open or not S.preview_sub.content then return end
  local win_x, win_y = r.ImGui_GetWindowPos(S.ctx)
  local win_w, win_h = r.ImGui_GetWindowSize(S.ctx)
  local popup_w, popup_h = 600, 450
  local center_x = win_x + (win_w - popup_w) * 0.5
  local center_y = win_y + (win_h - popup_h) * 0.5
  center_x = math.max(10, center_x)
  center_y = math.max(10, center_y)
  r.ImGui_SetNextWindowPos(S.ctx, center_x, center_y, r.ImGui_Cond_FirstUseEver())
  r.ImGui_SetNextWindowSize(S.ctx, popup_w, popup_h, r.ImGui_Cond_FirstUseEver())
  local flags = r.ImGui_WindowFlags_NoCollapse() | r.ImGui_WindowFlags_NoResize() |
      r.ImGui_WindowFlags_NoDocking()
  local visible, open = r.ImGui_Begin(S.ctx, "Перегляд субтитрів: " .. (S.preview_sub.title or ""), true, flags)
  if not open then
    S.preview_sub.open = false
    S.preview_sub.content = nil
    S.preview_sub.title = nil
    r.ImGui_End(S.ctx)
    return
  end
  if visible then
    r.ImGui_PushFont(S.ctx, S.font, 13)
    r.ImGui_PushStyleVar(S.ctx, r.ImGui_StyleVar_ChildRounding(), 8.0)
    r.ImGui_PushStyleColor(S.ctx, r.ImGui_Col_ChildBg(), C.title_bg)
    if r.ImGui_BeginChild(S.ctx, "##preview_text", 0, -55, 1) then
      r.ImGui_PushTextWrapPos(S.ctx, 0)
      r.ImGui_Text(S.ctx, S.preview_sub.content or "Немає тексту")
      r.ImGui_PopFont(S.ctx)
      r.ImGui_PopTextWrapPos(S.ctx)
      r.ImGui_EndChild(S.ctx)
    end
    r.ImGui_PopStyleColor(S.ctx, 1)
    r.ImGui_PopStyleVar(S.ctx, 1)
    r.ImGui_Separator(S.ctx)
    r.ImGui_Dummy(S.ctx, 0, 5)
    if r.ImGui_Button(S.ctx, "Імпортувати в проєкт", 140, 30) then
      if S.preview_sub.stream_idx then
        for _, s in ipairs(S.streams) do
          if s.idx == S.preview_sub.stream_idx and s.type == "subtitle" then
            local mdir = get_media_dir()
            local out = extract_stream(S.file, s, mdir)
            if out then
              r.SetExtState("Subass_Notes", "import_request", out, false)
              S.status = string.format("✓ Субтитри відправлено в Subass_Notes: %s", out:match("[^/\\]+$"))
            end
            break
          end
        end
      end
      S.preview_sub.open = false
    end
    r.ImGui_SameLine(S.ctx)
    if r.ImGui_Button(S.ctx, "Зберегти як файл", 140, 30) then
      if S.preview_sub.stream_idx then
        for _, s in ipairs(S.streams) do
          if s.idx == S.preview_sub.stream_idx and s.type == "subtitle" then
            local init_dir = S.file:match("(.*)[/\\]") or ""
            local ok_dir, out_dir = r.JS_Dialog_BrowseForFolder("Обрати папку для збереження субтитрів", init_dir)
            if ok_dir and out_dir and out_dir ~= "" then
              out_dir = out_dir:gsub("%z.*", "")
              local base = (S.file:match("[/\\]([^/\\]+)$") or "subtitle"):gsub("%.[^%.]+$", "")
              local ext = stream_ext(s)
              local lang_sfx = (s.lang ~= "") and ("_" .. s.lang) or ""
              local out_path = out_dir .. SEP .. safe_filename(string.format("%s_s%d%s.%s", base, s.idx, lang_sfx, ext))
              local content = S.preview_sub.content
              if content then
                local f = io.open(out_path, "wb")
                if f then
                  f:write(content)
                  f:close()
                  S.status = string.format("✓ Збережено: %s", out_path:match("[^/\\]+$"))
                end
              end
            end
            break
          end
        end
      end
    end
    r.ImGui_SameLine(S.ctx)
    r.ImGui_SameLine(S.ctx, r.ImGui_GetWindowWidth(S.ctx) - 110)
    if r.ImGui_Button(S.ctx, "Закрити", 100, 30) then
      S.preview_sub.open = false
      S.preview_sub.content = nil
    end
    r.ImGui_End(S.ctx)
  end
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

local function table_index_of(t, value)
  for i, v in ipairs(t) do
    if v == value then return i end
  end
  return nil
end

local function do_replace_audio_async(save_path)
  local video_file = S.file
  local audio_file = S.replace_modal.audio_file
  local keep_subs = S.replace_modal.keep_subs
  local keep_other_audio = S.replace_modal.keep_other_audio
  local encode_audio = S.replace_modal.encode_audio
  local start_time = os.clock()
  local selected_audio_streams = {}
  for _, s in ipairs(S.replace_modal.audio_streams) do
    if s.selected then
      table.insert(selected_audio_streams, s.idx)
    end
  end

  local function execute_replace(input_audio)
    local map_args = {}
    table.insert(map_args, "-map 0:v")
    table.insert(map_args, "-map 1:a")
    if keep_other_audio then table.insert(map_args, "-map 0:a?") end
    if keep_subs then table.insert(map_args, "-map 0:s?") end
    local ffmpeg_cmd = string.format(
      '"%s" -y -i "%s" -i "%s" -c:v copy -c:a copy -shortest -map_metadata 0 -map_chapters 0 %s "%s"',
      FFMPEG, video_file, input_audio,
      table.concat(map_args, " "),
      save_path
    )
    S.replace_modal.progress = 0.5
    S.replace_modal.progress_text = "Об'єднання відео з аудіо..."
    S.status = "Заміна аудіо..."
    run_ffmpeg_async(ffmpeg_cmd, function(out_file)
      S.replace_modal.progress = 1.0
      S.replace_modal.progress_text = "Завершено"
      local f = io.open(save_path, "rb")
      if f then
        local size = f:seek("end")
        f:close()
        if size and size > 0 then
          S.replace_modal.processing = false
          S.replace_modal.open = false
          S.replace_modal.progress = 0
          S.replace_modal.progress_text = ""
          S.status = "✓ Аудіо успішно замінено: " .. (save_path:match("[/\\]([^/\\]+)$") or save_path)
        else
          S.replace_modal.processing = false
          S.replace_modal.progress = 0
          S.status = "Помилка: вихідний файл порожній"
          os.remove(save_path)
        end
      else
        S.replace_modal.processing = false
        S.replace_modal.progress = 0
        S.status = "Помилка: не вдалося створити вихідний файл"
        if out_file then
          local f_diag = io.open(out_file, "r")
          if f_diag then
            S.diag = "FFmpeg помилка:\n" .. f_diag:read("*a")
            f_diag:close()
            S.show_diag = true
          end
        end
      end
    end)
  end
  if encode_audio then
    local fmt = S.replace_modal.encode_format
    local br = S.replace_modal.encode_bitrate
    local temp_converted = get_media_dir() .. SEP .. "temp_converted_audio." ..
        (fmt == "mp3" and "mp3" or fmt == "flac" and "flac" or fmt == "opus" and "opus" or fmt == "ac3" and "ac3" or "m4a")
    local filter_parts = {}
    for i, idx in ipairs(selected_audio_streams) do
      table.insert(filter_parts, string.format("-map 0:%d", idx))
    end
    local codec_args = ""
    if fmt == "aac" then
      codec_args = string.format("-c:a aac -b:a %s", br)
    elseif fmt == "mp3" then
      codec_args = string.format("-c:a libmp3lame -b:a %s", br)
    elseif fmt == "flac" then
      codec_args = "-c:a flac"
    elseif fmt == "opus" then
      codec_args = string.format("-c:a libopus -b:a %s", br)
    elseif fmt == "ac3" then
      codec_args = string.format("-c:a ac3 -b:a %s", br)
    end
    local convert_cmd = string.format(
      '"%s" -y -i "%s" %s %s "%s"',
      FFMPEG, audio_file,
      table.concat(filter_parts, " "),
      codec_args,
      temp_converted
    )
    S.replace_modal.progress = 0.05
    S.replace_modal.progress_text = "Конвертація аудіо в " .. fmt:upper() .. "..."
    S.status = "Конвертація аудіо..."
    run_ffmpeg_async(convert_cmd, function()
      S.replace_modal.progress = 0.4
      S.replace_modal.progress_text = "Конвертацію завершено"
      local f = io.open(temp_converted, "rb")
      if f then
        local size = f:seek("end")
        f:close()
        if size and size > 0 then
          execute_replace(temp_converted)
        else
          S.replace_modal.processing = false
          S.replace_modal.progress = 0
          S.status = "Помилка конвертації аудіо"
        end
      else
        S.replace_modal.processing = false
        S.replace_modal.progress = 0
        S.status = "Помилка конвертації аудіо"
      end
    end)
  else
    S.replace_modal.progress = 0.2
    S.replace_modal.progress_text = "Підготовка..."
    execute_replace(audio_file)
  end
end

local function draw_replace_audio_modal()
  if S.replace_modal.open then
    local win_x, win_y = r.ImGui_GetWindowPos(S.ctx)
    local win_w, win_h = r.ImGui_GetWindowSize(S.ctx)
    local modal_w, modal_h = 500, 420
    r.ImGui_SetNextWindowPos(S.ctx,
      win_x + (win_w - modal_w) * 0.5,
      win_y + (win_h - modal_h) * 0.5,
      r.ImGui_Cond_Always()
    )
    r.ImGui_SetNextWindowSize(S.ctx, modal_w, modal_h, r.ImGui_Cond_Always())
    r.ImGui_OpenPopup(S.ctx, "Заміна аудіо у відео##modal")
    S.replace_modal.open = false
  end
  local ctx = S.ctx
  local modal_w = 500
  local flags = r.ImGui_WindowFlags_NoResize()
      | r.ImGui_WindowFlags_NoCollapse()
      | r.ImGui_WindowFlags_NoDocking()
      | r.ImGui_WindowFlags_NoMove()
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ModalWindowDimBg(), 0x15151a99)
  local visible, open = r.ImGui_BeginPopupModal(ctx, "Заміна аудіо у відео##modal", true, flags)
  r.ImGui_PopStyleColor(ctx)
  if not visible then return end
  if not open then
    r.ImGui_CloseCurrentPopup(ctx)
    r.ImGui_EndPopup(ctx)
    return
  end
  if visible then
    r.ImGui_PushFont(S.ctx, S.font, 13)
    r.ImGui_TextColored(ctx, C.text_dim, "Відеофайл:")
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), C.text_cyan)
    local video_name = S.file:match("[/\\]([^/\\]+)$") or S.file
    r.ImGui_TextWrapped(ctx, "▶ " .. video_name)
    r.ImGui_PopStyleColor(ctx)
    if r.ImGui_IsItemHovered(ctx) then
      r.ImGui_SetTooltip(ctx, S.file)
    end
    r.ImGui_Spacing(ctx)
    r.ImGui_Separator(ctx)
    r.ImGui_Spacing(ctx)
    r.ImGui_TextColored(ctx, C.text_dim, "Аудіофайл для заміни:")
    local hw = math.floor((modal_w - 32) / 2.01)
    if r.ImGui_Button(ctx, "Обрати аудіофайл...", hw, 28) then
      local extension_mask =
      "Audio files (*.m4a;*.mp3;*.wav;*.flac;*.aac;*.ogg;*.opus;*.ac3)\0*.m4a;*.mp3;*.wav;*.flac;*.aac;*.ogg;*.opus;*.ac3\0All Files (*.*)\0*.*\0"
      local ok, f = r.JS_Dialog_BrowseForOpenFiles("Обрати аудіофайл", "", "", extension_mask, false)
      if ok and f and f ~= "" then
        f = f:gsub("%z.*", "")
        S.replace_modal.audio_file = f
        S.replace_modal.audio_streams = probe_audio_file(f)
      end
    end
    r.ImGui_SameLine(ctx)
    if r.ImGui_Button(ctx, "Обрати з файлу проєкта", hw, 28) then
      local n = r.CountSelectedMediaItems(0)
      if n > 0 then
        local item = r.GetSelectedMediaItem(0, 0)
        local take = item and r.GetActiveTake(item)
        local source = take and r.GetMediaItemTake_Source(take)
        if source then
          local fname = r.GetMediaSourceFileName(source, "")
          if fname and fname ~= "" then
            S.replace_modal.audio_file = fname
            S.replace_modal.audio_streams = probe_audio_file(fname)
          end
        end
      else
        S.status = "Виділіть аудіо у проєкті"
      end
    end
    if S.replace_modal.audio_file ~= "" then
      r.ImGui_Spacing(ctx)
      local audio_name = S.replace_modal.audio_file:match("[/\\]([^/\\]+)$") or S.replace_modal.audio_file
      r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), C.text_ok)
      r.ImGui_TextWrapped(ctx, "✓ " .. audio_name)
      r.ImGui_PopStyleColor(ctx)
      if #S.replace_modal.audio_streams > 0 then
        r.ImGui_Spacing(ctx)
        r.ImGui_TextColored(ctx, C.text_dim, "Аудіодоріжки:")
        for i, s in ipairs(S.replace_modal.audio_streams) do
          local changed, val = r.ImGui_Checkbox(ctx, s.label .. "##ra" .. i, s.selected)
          if changed then S.replace_modal.audio_streams[i].selected = val end
        end
      end
    end
    r.ImGui_TextColored(ctx, C.text_dim, "Опції:")
    r.ImGui_SameLine(ctx)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), C.text_err)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), 0x00000000)
    if r.ImGui_Button(ctx, "?", 20, 20) then
    end
    r.ImGui_PopStyleColor(ctx, 2)
    if r.ImGui_IsItemHovered(ctx) then
      r.ImGui_SetTooltip(ctx,
        "• Якщо один з файлів буде коротшим за інший,\nто збережене відео обріжиться по довжині\nнайкоротшого з файлів.")
    end
    local keep_subs_changed, keep_subs = r.ImGui_Checkbox(ctx,
      "Зберегти разом з субтитрами##keep_subs", S.replace_modal.keep_subs)
    if keep_subs_changed then S.replace_modal.keep_subs = keep_subs end
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), C.text_warn)
    if r.ImGui_IsItemHovered(ctx) then
      r.ImGui_SetTooltip(ctx, "Якщо вимкнути цю опцію, субтитри\nз оригінального відео не потраплять у новий файл.")
    end
    r.ImGui_PopStyleColor(ctx)
    local keep_audio_changed, keep_audio = r.ImGui_Checkbox(ctx,
      "Зберегти інші аудіодоріжки##keep_audio", S.replace_modal.keep_other_audio)
    if keep_audio_changed then S.replace_modal.keep_other_audio = keep_audio end
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), C.text_warn)
    if r.ImGui_IsItemHovered(ctx) then
      r.ImGui_SetTooltip(ctx, "Якщо вимкнути цю опцію, аудіодоріжки\nз оригінального відео не потраплять у новий файл.")
    end
    r.ImGui_PopStyleColor(ctx)
    r.ImGui_Spacing(ctx)
    local encode_changed, encode = r.ImGui_Checkbox(ctx,
      "Кодувати аудіо перед заміною##encode_audio", S.replace_modal.encode_audio)
    if encode_changed then S.replace_modal.encode_audio = encode end
    if S.replace_modal.encode_audio then
      r.ImGui_Indent(ctx, 20)
      r.ImGui_TextColored(ctx, C.text_dim, "Формат:")
      local formats = { "aac", "mp3", "flac", "opus", "ac3" }
      local format_names = { "AAC (.m4a)", "MP3 (.mp3)", "FLAC (.flac)", "Opus (.opus)", "AC3 (.ac3)" }
      local current_format = S.replace_modal.encode_format
      local current_idx = table_index_of(formats, current_format) or 1
      if r.ImGui_BeginCombo(ctx, "##encode_format", format_names[current_idx]) then
        for i, fmt in ipairs(formats) do
          local selected = (current_format == fmt)
          if r.ImGui_Selectable(ctx, format_names[i], selected) then
            S.replace_modal.encode_format = fmt
          end
          if selected then
            r.ImGui_SetItemDefaultFocus(ctx)
          end
        end
        r.ImGui_EndCombo(ctx)
      end
      r.ImGui_TextColored(ctx, C.text_dim, "Бітрейт:")
      local bitrates = { "96k", "128k", "192k", "256k", "320k" }
      local current_br = S.replace_modal.encode_bitrate
      if r.ImGui_BeginCombo(ctx, "##bitrate", current_br) then
        for _, br in ipairs(bitrates) do
          local selected = (current_br == br)
          if r.ImGui_Selectable(ctx, br, selected) then
            S.replace_modal.encode_bitrate = br
          end
          if selected then
            r.ImGui_SetItemDefaultFocus(ctx)
          end
        end
        r.ImGui_EndCombo(ctx)
      end
      r.ImGui_Unindent(ctx, 20)
    end
    r.ImGui_Spacing(ctx)
    r.ImGui_Separator(ctx)
    r.ImGui_Spacing(ctx)
    local has_audio = (S.replace_modal.audio_file ~= "")
    local has_selected = false
    for _, s in ipairs(S.replace_modal.audio_streams) do
      if s.selected then
        has_selected = true; break
      end
    end
    local can_replace = has_audio and (has_selected or #S.replace_modal.audio_streams == 0)
    local disabled = not can_replace or S.replace_modal.processing
    if S.replace_modal.processing then
      r.ImGui_Spacing(ctx)
      r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), C.text_warn)
      r.ImGui_TextWrapped(ctx, S.status or "Обробка...")
      r.ImGui_PopStyleColor(ctx)
      r.ImGui_Spacing(ctx)
      S.replace_modal.visual_progress = S.replace_modal.visual_progress or 0
      local target_progress = S.replace_modal.progress
      if target_progress > 0 then
        S.replace_modal.visual_progress = S.replace_modal.visual_progress +
            (target_progress - S.replace_modal.visual_progress) * 0.08
        if math.abs(target_progress - S.replace_modal.visual_progress) < 0.001 then
          S.replace_modal.visual_progress = target_progress
        end
        local display_prog = math.max(0.0, math.min(1.0, S.replace_modal.visual_progress))
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), C.btn)
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_PlotHistogram(), C.text_ok)
        r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FrameRounding(), 4.0)
        r.ImGui_ProgressBar(ctx, display_prog, modal_w - 60, 20,
          string.format("%d%%", math.floor(display_prog * 100)))
        r.ImGui_PopStyleVar(ctx)
        r.ImGui_PopStyleColor(ctx, 2)
      else
        local spinner_chars = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
        local spin_idx = math.floor(os.clock() * 10) % #spinner_chars + 1
        local spin = spinner_chars[spin_idx]
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), C.btn)
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), C.text_warn)
        r.ImGui_Button(ctx, spin .. "  " .. (S.replace_modal.progress_text or "Очікування..."),
          modal_w - 32, 20)
        r.ImGui_PopStyleColor(ctx, 2)
      end
      if S.replace_modal.progress_text ~= "" and target_progress > 0 then
        r.ImGui_Spacing(ctx)
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), C.text_dim)
        r.ImGui_TextWrapped(ctx, S.replace_modal.progress_text)
        r.ImGui_PopStyleColor(ctx)
      end
    else
      if disabled then
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), C.text_dim)
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), C.btn_dis)
      end
      if r.ImGui_Button(ctx, "Замінити аудіо", modal_w - 28, 35) then
        if not disabled then
          local init_dir = S.file:match("(.*)[/\\]") or ""
          local video_name_noext = (S.file:match("[/\\]([^/\\]+)$") or "video"):gsub("%.[^%.]+$", "")
          local ext = S.file:match("%.([^%.]+)$") or "mp4"
          local default_name = video_name_noext .. "_new_audio." .. ext
          local ok_save, save_path = r.JS_Dialog_BrowseForSaveFile(
            "Зберегти відео з новим аудіо",
            init_dir,
            default_name,
            "Video files (*." .. ext .. ")\0*." .. ext .. "\0All Files (*.*)\0*.*\0"
          )
          if ok_save and save_path and save_path ~= "" then
            save_path = save_path:gsub("%z.*", "")
            S.replace_modal.processing = true
            S.replace_modal.progress = 0
            S.replace_modal.visual_progress = 0
            S.replace_modal.progress_text = "Початок..."
            do_replace_audio_async(save_path)
          end
        end
      end
      if disabled then
        r.ImGui_PopStyleColor(ctx, 2)
      end
    end
  end
  r.ImGui_PopFont(ctx)
  r.ImGui_End(ctx)
end

local function format_preview_time(seconds)
  if not seconds or seconds <= 0 then return "0:00" end
  local mins = math.floor(seconds / 60)
  local secs = math.floor(seconds % 60)
  return string.format("%d:%02d", mins, secs)
end

local function draw_mini_audio_player()
  if not S.audio_preview.source then return end
  local ctx = S.ctx
  local pos_ok, pos = r.CF_Preview_GetValue(S.audio_preview.source, "D_POSITION")
  local len_ok, len = r.CF_Preview_GetValue(S.audio_preview.source, "D_LENGTH")
  if not S.audio_preview.paused and pos_ok and len_ok and pos >= len - 0.05 then
    S.audio_preview.paused = true
    S.audio_preview.pause_pos = 0
    S.audio_preview.playing = false
  end
  if S.audio_preview.paused then
    pos = S.audio_preview.pause_pos
    len = S.audio_preview.length
  end
  local win_h = r.ImGui_GetWindowHeight(ctx)
  local player_h = 65
  local cursor_y = r.ImGui_GetCursorPosY(ctx)
  local bottom_y = win_h - player_h - 20
  if cursor_y < bottom_y then
    r.ImGui_SetCursorPosY(ctx, bottom_y)
  end
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ChildBg(), C.title_bg)
  r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ChildRounding(), 8.0)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_PlotHistogram(), C.text_ok)
  if r.ImGui_BeginChild(ctx, "##audio_player", 0, player_h, 1, 0) then
    r.ImGui_Dummy(ctx, 0, 0)
    local play_icon = S.audio_preview.paused and "▶" or "Ⅱ"
    r.ImGui_PushFont(ctx, S.font, 20)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), C.btn)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), C.btn_hov)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(), C.btn_act)
    if r.ImGui_Button(ctx, play_icon .. "##playpause", 40, 40) then
      if S.audio_preview.paused then
        if S.audio_preview.file and r.PCM_Source_CreateFromFile and r.CF_CreatePreview then
          if S.audio_preview.source then
            r.CF_Preview_Stop(S.audio_preview.source)
          end
          local source = r.PCM_Source_CreateFromFile(S.audio_preview.file)
          S.audio_preview.source = r.CF_CreatePreview(source)
          if S.audio_preview.pause_pos > 0 then
            r.CF_Preview_SetValue(S.audio_preview.source, "D_POSITION", S.audio_preview.pause_pos)
          end
          r.CF_Preview_Play(S.audio_preview.source)
        end
        S.audio_preview.paused = false
        S.audio_preview.playing = true
      else
        local ok_p, cur_pos = r.CF_Preview_GetValue(S.audio_preview.source, "D_POSITION")
        local ok_l, cur_len = r.CF_Preview_GetValue(S.audio_preview.source, "D_LENGTH")
        S.audio_preview.pause_pos = cur_pos or 0
        S.audio_preview.length = cur_len or 0
        if S.audio_preview.source then
          r.CF_Preview_Stop(S.audio_preview.source)
        end
        S.audio_preview.paused = true
        S.audio_preview.playing = false
      end
    end
    r.ImGui_PopStyleColor(ctx, 3)
    r.ImGui_PopFont(ctx)
    r.ImGui_SameLine(ctx, 0, 10)
    r.ImGui_BeginGroup(ctx)
    local full_name = S.audio_preview.name or "Аудіо"
    local display_name = full_name
    local avail_w = r.ImGui_GetContentRegionAvail(ctx) - 50
    local name_w = r.ImGui_CalcTextSize(ctx, full_name)
    if name_w > avail_w - 100 then
      display_name = full_name:sub(1, 40) .. "..."
    end
    r.ImGui_PushFont(ctx, S.font, 13)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), C.text_warn)
    r.ImGui_Text(ctx, display_name)
    r.ImGui_PopStyleColor(ctx)
    if r.ImGui_IsItemHovered(ctx) and full_name ~= display_name then
      r.ImGui_BeginTooltip(ctx)
      r.ImGui_Text(ctx, full_name)
      r.ImGui_EndTooltip(ctx)
    end
    local time_str = format_preview_time(pos) .. " / " .. format_preview_time(len)
    local time_w = r.ImGui_CalcTextSize(ctx, time_str)
    r.ImGui_SameLine(ctx, avail_w - time_w)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), C.text_dim)
    r.ImGui_Text(ctx, time_str)
    r.ImGui_PopStyleColor(ctx)
    local progress = (len > 0) and (pos / len) or 0
    local bar_w = avail_w
    local cursor_x, cursor_y_pos = r.ImGui_GetCursorScreenPos(ctx)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), C.btn)
    r.ImGui_ProgressBar(ctx, progress, bar_w, 6, "")
    r.ImGui_PopStyleColor(ctx, 1)
    if r.ImGui_IsItemClicked(ctx, 0) then
      local mouse_x, mouse_y = r.ImGui_GetMousePos(ctx)
      local click_pos = (mouse_x - cursor_x) / bar_w
      click_pos = math.max(0, math.min(1, click_pos))
      local new_time = click_pos * len
      if S.audio_preview.paused then
        S.audio_preview.pause_pos = new_time
      else
        if S.audio_preview.source then
          r.CF_Preview_SetValue(S.audio_preview.source, "D_POSITION", new_time)
        end
      end
    end
    r.ImGui_PopFont(ctx)
    r.ImGui_EndGroup(ctx)
    r.ImGui_SameLine(ctx, r.ImGui_GetWindowWidth(ctx) - 32)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), C.btn)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), C.btn_hov)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(), C.btn_act)
    if r.ImGui_Button(ctx, "✕", 23, 23) then
      if S.audio_preview.source then
        r.CF_Preview_Stop(S.audio_preview.source)
      end
      S.audio_preview.source = nil
      S.audio_preview.playing = false
      S.audio_preview.paused = false
      S.audio_preview.file = nil
      S.status = "Відтворення зупинено"
    end
    r.ImGui_PopStyleColor(ctx, 3)
    r.ImGui_EndChild(ctx)
  end
  r.ImGui_PopStyleColor(ctx, 2)
  r.ImGui_PopStyleVar(ctx)
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

local function do_import(src, streams_list)
  local mdir = get_media_dir()
  local ok_count, err_count = 0, 0
  local error_details = {}
  local first_track = true
  local common_cursor_pos = nil
  local to_process = {}
  for _, s in ipairs(streams_list) do
    if s.selected then
      local supported, reason = is_supported_stream(s)
      if supported then
        table.insert(to_process, s)
      else
        err_count = err_count + 1
        table.insert(error_details, string.format(
          "Потік #%d (%s) пропущено: %s", s.idx, s.type, reason))
      end
    end
  end
  if #to_process == 0 then
    S.processing = false
    S.status = "Немає підтримуваних потоків для імпорту"
    return
  end
  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)
  common_cursor_pos = r.GetCursorPosition()
  local idx = 0
  local subtitle_path = nil
  local function process_next()
    idx = idx + 1
    if idx > #to_process then
      if subtitle_path then
        r.SetExtState("Subass_Notes", "import_request", subtitle_path, false)
      end
      r.PreventUIRefresh(-1)
      r.UpdateArrange()
      r.Undo_EndBlock("MKV/MP4 Extract", -1)
      S.processing = false
      if err_count == 0 then
        S.status = string.format("✓ Готово: %d потік(и) імпортовано", ok_count)
      else
        S.diag = string.format("Завершено: %d OK / %d помилок\n", ok_count, err_count)
        for _, d in ipairs(error_details) do
          S.diag = S.diag .. d .. "\n"
        end
        S.status = string.format(
          "Завершено: %d OK / %d помилок (дивись діагностику)", ok_count, err_count)
      end
      return
    end
    local s = to_process[idx]
    S.status = string.format(
      "Витягую %d/%d: #%d (%s %s)…", idx, #to_process, s.idx, s.type, s.codec)
    local base = (src:match("[/\\]([^/\\]+)$") or "track"):gsub("%.[^%.]+$", "")
    local lang_sfx = (s.lang ~= "") and ("_" .. s.lang) or ""
    local ext = stream_ext(s)
    local use_channel_selection = false
    local selected_list = {}
    if s.type == "audio" and S.selected_channels[s.idx] then
      for ch, selected in pairs(S.selected_channels[s.idx]) do
        if selected then table.insert(selected_list, ch) end
      end
      if #selected_list > 0 and #selected_list < s.channels then
        use_channel_selection = true
      end
    end
    local out_path
    local ffmpeg_cmd
    if use_channel_selection then
      local ch_sfx = "_ch" .. table.concat(selected_list, "")
      out_path = mdir .. SEP .. safe_filename(
        string.format("%s_s%d%s%s.wav", base, s.idx, lang_sfx, ch_sfx))
      ffmpeg_cmd = string.format(
        '"%s" -y -i "%s" -map 0:%d -af "%s" -ac %d "%s"',
        FFMPEG, src, s.idx, build_pan_filter(selected_list), #selected_list, out_path)
    else
      out_path = mdir .. SEP .. safe_filename(
        string.format("%s_s%d%s.%s", base, s.idx, lang_sfx, ext))
      ffmpeg_cmd = string.format(
        '"%s" -y -i "%s" -map 0:%d -c copy "%s"',
        FFMPEG, src, s.idx, out_path)
    end
    run_ffmpeg_async(ffmpeg_cmd, function()
      local f = io.open(out_path, "rb")
      local size = f and f:seek("end")
      if f then f:close() end
      if size and size > 0 then
        if s.type == "subtitle" then
          subtitle_path = out_path
        else
          insert_media_on_new_track(out_path, common_cursor_pos)
        end
        ok_count = ok_count + 1
      else
        err_count = err_count + 1
        table.insert(error_details,
          string.format("Потік #%d (%s) не вдалося витягнути", s.idx, s.type))
      end
      process_next()
    end)
  end
  process_next()
end

local function do_add_subtitle_async(save_path)
  local video_file = S.file
  local sub_file = S.subtitle_import_modal.subtitle_file
  local sub_lang = S.subtitle_import_modal.subtitle_lang or "ukr"
  local sub_title = S.subtitle_import_modal.subtitle_title or ""
  local keep_existing_subs = S.subtitle_import_modal.keep_existing_subs
  local resource_path = r.GetResourcePath()
  local temp_dir = resource_path .. SEP .. "Scripts"
  r.RecursiveCreateDirectory(temp_dir, 0)
  local input_ext = video_file:match("^.+(%.[^%.]+)$"):lower()
  local is_mp4 = input_ext == ".mp4"
  local temp_files = {}
  local final_output_path = save_path
  local mkv_temp_file = nil
  if is_mp4 then
    mkv_temp_file = temp_dir .. SEP .. "temp_subtitles_" .. os.time() .. "_" .. math.random(1000, 9999) .. ".mkv"
    table.insert(temp_files, mkv_temp_file)
    save_path = mkv_temp_file
  end
  local function exec_sync(cmd, error_msg)
    if IS_WIN then
      local bat = temp_dir .. SEP .. "_cmd_" .. os.time() .. "_" .. math.random(1000, 9999) .. ".bat"
      write_to_file(bat, "@echo off\nchcp 65001 >nul\n" .. cmd .. "\necho ERRORLEVEL=%ERRORLEVEL%")
      local result = r.ExecProcess(bat, 0)
      os.remove(bat)
      if result and result:match("ERRORLEVEL=[1-9]") then
        if error_msg then S.status = error_msg end
        return false
      end
      return true
    else
      local ret = os.execute(cmd)
      if ret ~= 0 and error_msg then S.status = error_msg end
      return ret == 0
    end
  end
  local function get_file_ext(path)
    return (path:match("^.+(%.[^%.]+)$") or ".srt"):lower()
  end
  local function codec_to_ext(codec_name)
    local map = {
      ass               = ".ass",
      ssa               = ".ass",
      subrip            = ".srt",
      srt               = ".srt",
      webvtt            = ".vtt",
      vtt               = ".vtt",
      mov_text          = ".srt",
      hdmv_pgs_subtitle = ".sup",
      dvd_subtitle      = ".sub",
      dvb_subtitle      = ".sub",
      microdvd          = ".sub",
      subviewer         = ".sub",
      subviewer1        = ".sub",
      jacosub           = ".jss",
      mpl2              = ".mpl",
      pjs               = ".pjs",
      realtext          = ".rt",
      sami              = ".smi",
      stl               = ".stl",
      ttml              = ".ttml",
      lrc               = ".lrc",
    }
    if not codec_name then return ".srt" end
    return map[codec_name:lower()] or ".srt"
  end
  local function ensure_utf8_with_bom(filepath)
    local ext = get_file_ext(filepath)
    local text_formats = {
      [".srt"] = true,
      [".ass"] = true,
      [".ssa"] = true,
      [".vtt"] = true,
      [".ttml"] = true,
      [".lrc"] = true,
      [".smi"] = true,
      [".sub"] = true,
      [".jss"] = true,
      [".mpl"] = true,
      [".rt"] = true,
      [".stl"] = true,
    }
    if not text_formats[ext] then return filepath end
    local f_in = io.open(filepath, "rb")
    if not f_in then return filepath end
    local content = f_in:read("*a")
    f_in:close()
    if not content or #content == 0 then return filepath end
    if content:sub(1, 3) == "\239\187\191" then return filepath end
    local out_path = temp_dir .. SEP .. "utf8_" .. os.time() .. "_" .. math.random(1000, 9999) .. ext
    local f_out = io.open(out_path, "wb")
    if not f_out then return filepath end
    f_out:write("\239\187\191")

    local function write_cp(cp)
      if cp < 0x80 then
        f_out:write(string.char(cp))
      elseif cp < 0x800 then
        f_out:write(string.char(0xC0 + math.floor(cp / 64), 0x80 + (cp % 64)))
      elseif cp < 0xD800 or cp >= 0xE000 then
        f_out:write(string.char(
          0xE0 + math.floor(cp / 4096),
          0x80 + math.floor((cp % 4096) / 64),
          0x80 + (cp % 64)))
      end
    end

    if content:sub(1, 2) == "\255\254" then
      local i = 3
      while i <= #content - 1 do
        write_cp(content:byte(i + 1) * 256 + content:byte(i))
        i = i + 2
      end
      f_out:close(); return out_path
    elseif content:sub(1, 2) == "\254\255" then
      local i = 3
      while i <= #content - 1 do
        write_cp(content:byte(i) * 256 + content:byte(i + 1))
        i = i + 2
      end
      f_out:close(); return out_path
    end
    f_out:write(content)
    f_out:close()
    return out_path
  end
  local probe_out = temp_dir .. SEP .. "_probe_" .. os.time() .. ".txt"
  local probe_cmd
  if IS_WIN then
    probe_cmd = string.format(
      '"%s" -v error -select_streams s -show_entries stream=index,codec_name:stream_tags=language,title -of csv=p=0 "%s" > "%s" 2>&1',
      FFPROBE, video_file, probe_out)
  else
    probe_cmd = string.format(
      '%s -v error -select_streams s -show_entries stream=index,codec_name:stream_tags=language,title -of csv=p=0 %s > %s 2>&1',
      shell_q(FFPROBE), shell_q(video_file), shell_q(probe_out))
  end
  exec_sync(probe_cmd, nil)
  local dur_out = temp_dir .. SEP .. "_dur_" .. os.time() .. ".txt"
  local dur_cmd
  if IS_WIN then
    dur_cmd = string.format(
      '"%s" -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "%s" > "%s" 2>&1',
      FFPROBE, video_file, dur_out)
  else
    dur_cmd = string.format(
      '%s -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 %s > %s 2>&1',
      shell_q(FFPROBE), shell_q(video_file), shell_q(dur_out))
  end
  exec_sync(dur_cmd, nil)
  local video_duration = nil
  local f_dur = io.open(dur_out, "r")
  if f_dur then
    local v = f_dur:read("*l")
    f_dur:close()
    if v and v:match("^%d") then video_duration = v:match("([%d%.]+)") end
  end
  os.remove(dur_out)
  local existing_subs = {}
  local f_probe = io.open(probe_out, "r")
  if f_probe then
    for line in f_probe:lines() do
      line = line:match("^%s*(.-)%s*$")
      if line ~= "" then
        local parts = {}
        for field in (line .. ","):gmatch("([^,]*),") do
          table.insert(parts, field)
        end
        local codec = parts[2] or ""
        local lang  = parts[3] or ""
        local title = parts[4] or ""
        if lang == "N/A" then lang = "und" end
        if title == "N/A" then title = "" end
        if codec == "N/A" then codec = "" end
        table.insert(existing_subs, { codec = codec, lang = lang, title = title })
      end
    end
    f_probe:close()
  end
  os.remove(probe_out)
  local input_sub = ensure_utf8_with_bom(sub_file)
  if input_sub ~= sub_file then table.insert(temp_files, input_sub) end
  local chk = io.open(input_sub, "rb")
  if not chk then
    S.status = "Помилка: не вдалося відкрити файл субтитрів"
    return
  end
  local chk_size = chk:seek("end"); chk:close()
  if chk_size == 0 then
    S.status = "Помилка: файл субтитрів порожній"
    return
  end
  local exported = {}
  if keep_existing_subs and #existing_subs > 0 then
    for si, sub_info in ipairs(existing_subs) do
      local ext      = codec_to_ext(sub_info.codec)
      local exp_path = temp_dir .. SEP .. "_expsub_" .. si .. "_" .. os.time() .. "_" .. math.random(1000, 9999) .. ext
      local exp_cmd
      if IS_WIN then
        exp_cmd = string.format(
          '"%s" -y -i "%s" -map 0:s:%d -c:s copy "%s" 2>&1',
          FFMPEG, video_file, si - 1, exp_path)
      else
        exp_cmd = string.format(
          '%s -y -i %s -map 0:s:%d -c:s copy %s 2>&1',
          shell_q(FFMPEG), shell_q(video_file), si - 1, shell_q(exp_path))
      end
      exec_sync(exp_cmd, nil)
      local ef = io.open(exp_path, "rb")
      if ef then
        local sz = ef:seek("end"); ef:close()
        if sz and sz > 0 then
          local final = ensure_utf8_with_bom(exp_path)
          if final ~= exp_path then
            os.remove(exp_path)
            table.insert(temp_files, final)
          else
            table.insert(temp_files, exp_path)
          end
          table.insert(exported, {
            file  = final,
            lang  = sub_info.lang,
            title = sub_info.title,
          })
        else
          os.remove(exp_path)
        end
      end
    end
  end
  local inputs_parts = {}
  local map_parts    = {}
  local meta_parts   = {}
  local disp_parts   = {}
  if IS_WIN then
    table.insert(inputs_parts, string.format('-i "%s"', video_file))
  else
    table.insert(inputs_parts, string.format('-i %s', shell_q(video_file)))
  end
  table.insert(map_parts, "-map 0:v")
  table.insert(map_parts, "-map 0:a")
  local sub_stream_count = 0
  if keep_existing_subs then
    for ei, exp in ipairs(exported) do
      local inp_idx = ei
      if IS_WIN then
        table.insert(inputs_parts, string.format('-i "%s"', exp.file))
      else
        table.insert(inputs_parts, string.format('-i %s', shell_q(exp.file)))
      end
      table.insert(map_parts, string.format("-map %d:0", inp_idx))
      table.insert(meta_parts, string.format(
        '-metadata:s:s:%d language=%s', sub_stream_count, exp.lang))
      if exp.title ~= "" then
        table.insert(meta_parts, string.format(
          '-metadata:s:s:%d title="%s"', sub_stream_count, exp.title:gsub('"', '\\"')))
      end
      table.insert(disp_parts, string.format("-disposition:s:%d 0", sub_stream_count))
      sub_stream_count = sub_stream_count + 1
    end
  end
  local new_inp_idx = (keep_existing_subs and #exported or 0) + 1
  if IS_WIN then
    table.insert(inputs_parts, string.format('-i "%s"', input_sub))
  else
    table.insert(inputs_parts, string.format('-i %s', shell_q(input_sub)))
  end
  table.insert(map_parts, string.format("-map %d:0", new_inp_idx))
  table.insert(meta_parts, string.format(
    '-metadata:s:s:%d language=%s', sub_stream_count, sub_lang))
  if sub_title ~= "" then
    table.insert(meta_parts, string.format(
      '-metadata:s:s:%d title="%s"', sub_stream_count, sub_title:gsub('"', '\\"')))
  end
  table.insert(disp_parts, string.format("-disposition:s:%d default", sub_stream_count))
  local dur_flag                        = video_duration and ("-t " .. video_duration .. " ") or ""
  local ffmpeg_cmd                      = string.format(
    '"%s" -y %s %s -c:v copy -c:a copy -c:s copy %s %s -map_metadata 0 -map_chapters 0 %s"%s"',
    FFMPEG,
    table.concat(inputs_parts, " "),
    table.concat(map_parts, " "),
    table.concat(meta_parts, " "),
    table.concat(disp_parts, " "),
    dur_flag,
    save_path
  )
  S.subtitle_import_modal.progress      = 0.3
  S.subtitle_import_modal.progress_text = "Додавання субтитрів..."
  S.status                              = "Додавання субтитрів у відео..."
  run_ffmpeg_async(ffmpeg_cmd, function()
    local f_check = io.open(save_path, "rb")
    if not f_check then
      for _, tmp in ipairs(temp_files) do
        if tmp then os.remove(tmp) end
      end
      S.subtitle_import_modal.processing = false
      S.status = "Помилка: не вдалося створити файл з субтитрами"
      return
    end
    local file_size = f_check:seek("end")
    f_check:close()
    if file_size == 0 then
      for _, tmp in ipairs(temp_files) do
        if tmp then os.remove(tmp) end
      end
      S.subtitle_import_modal.processing = false
      S.status = "Помилка: створено порожній файл"
      return
    end
    if is_mp4 then
      local copy_cmd
      if IS_WIN then
        copy_cmd = string.format('copy /Y "%s" "%s"', save_path, final_output_path)
      else
        copy_cmd = string.format('cp "%s" "%s"', save_path, final_output_path)
      end
      exec_sync(copy_cmd, nil)
      local f_final = io.open(final_output_path, "rb")
      if not f_final or f_final:seek("end") == 0 then
        if f_final then f_final:close() end
        for _, tmp in ipairs(temp_files) do
          if tmp then os.remove(tmp) end
        end
        S.subtitle_import_modal.processing = false
        S.status = "Помилка: не вдалося зберегти файл"
        return
      end
      f_final:close()
    end
    for _, tmp in ipairs(temp_files) do
      if tmp and tmp ~= final_output_path then
        os.remove(tmp)
      end
    end
    S.subtitle_import_modal.progress      = 1.0
    S.subtitle_import_modal.progress_text = "Завершено"
    local output_file                     = is_mp4 and final_output_path or save_path
    local f                               = io.open(output_file, "rb")
    if f then
      local size = f:seek("end"); f:close()
      if size and size > 0 then
        S.subtitle_import_modal.processing      = false
        S.subtitle_import_modal.open            = false
        S.subtitle_import_modal.progress        = 0
        S.subtitle_import_modal.visual_progress = 0
        S.subtitle_import_modal.progress_text   = ""
        if is_mp4 then
          S.status = "✓ Субтитри (" .. sub_lang .. ") додано"
          S.file = final_output_path
        else
          S.status = "✓ Субтитри (" .. sub_lang .. ") додано"
        end
      else
        S.subtitle_import_modal.processing = false
        S.status = "Помилка: вихідний файл порожній"
        os.remove(output_file)
      end
    else
      S.subtitle_import_modal.processing = false
      S.status = "Помилка: не вдалося створити вихідний файл"
    end
  end)
end

local function draw_subtitle_import_modal()
  if S.subtitle_import_modal.open then
    local win_x, win_y = r.ImGui_GetWindowPos(S.ctx)
    local win_w, win_h = r.ImGui_GetWindowSize(S.ctx)
    local modal_w, modal_h = 550, 500
    r.ImGui_SetNextWindowPos(S.ctx,
      win_x + (win_w - modal_w) * 0.5,
      win_y + (win_h - modal_h) * 0.5,
      r.ImGui_Cond_Always()
    )
    r.ImGui_SetNextWindowSize(S.ctx, modal_w, modal_h, r.ImGui_Cond_Always())
    r.ImGui_OpenPopup(S.ctx, "Додати субтитри##modal")
    S.subtitle_import_modal.open = false
  end
  local ctx = S.ctx
  local modal_w = 550
  local flags = r.ImGui_WindowFlags_NoResize()
      | r.ImGui_WindowFlags_NoCollapse()
      | r.ImGui_WindowFlags_NoDocking()
      | r.ImGui_WindowFlags_NoMove()
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ModalWindowDimBg(), 0x15151a99)
  local visible, open = r.ImGui_BeginPopupModal(ctx, "Додати субтитри##modal", true, flags)
  r.ImGui_PopStyleColor(ctx)
  if not visible then return end
  if not open then
    r.ImGui_CloseCurrentPopup(ctx)
    r.ImGui_EndPopup(ctx)
    return
  end
  if visible then
    r.ImGui_PushFont(S.ctx, S.font, 13)
    r.ImGui_TextColored(ctx, C.text_dim, "Відеофайл:")
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), C.text_cyan)
    local video_name = S.file:match("[/\\]([^/\\]+)$") or S.file
    r.ImGui_TextWrapped(ctx, "▶ " .. video_name)
    r.ImGui_PopStyleColor(ctx)
    if r.ImGui_IsItemHovered(ctx) then
      r.ImGui_SetTooltip(ctx, S.file)
    end
    r.ImGui_Spacing(ctx)
    r.ImGui_Separator(ctx)
    r.ImGui_Spacing(ctx)
    r.ImGui_TextColored(ctx, C.text_dim, "Файл субтитрів:")
    local btn_w = math.floor((modal_w - 32) / 2.01)
    if r.ImGui_Button(ctx, "Обрати .srt/.ass файл...", btn_w, 28) then
      local extension_mask =
      "Subtitle files (*.srt;*.ass)\0*.srt;*.ass\0All Files (*.*)\0*.*\0"
      local ok, f = r.JS_Dialog_BrowseForOpenFiles("Обрати файл субтитрів", "", "", extension_mask, false)
      if ok and f and f ~= "" then
        f = f:gsub("%z.*", "")
        S.subtitle_import_modal.subtitle_file = f
        S.subtitle_import_modal.subtitle_content = read_subtitle_preview(f)
      end
    end
    if S.subtitle_import_modal.subtitle_file ~= "" then
      r.ImGui_Spacing(ctx)
      local sub_name = S.subtitle_import_modal.subtitle_file:match("[/\\]([^/\\]+)$") or
          S.subtitle_import_modal.subtitle_file
      r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), C.text_ok)
      r.ImGui_TextWrapped(ctx, "✓ " .. sub_name)
      r.ImGui_PopStyleColor(ctx)
      if S.subtitle_import_modal.subtitle_content then
        r.ImGui_Spacing(ctx)
        r.ImGui_TextColored(ctx, C.text_dim, "Попередній перегляд:")
        r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ChildRounding(), 8.0)
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ChildBg(), C.title_bg)
        if r.ImGui_BeginChild(ctx, "##sub_preview", modal_w - 32, 120, 1) then
          r.ImGui_PushTextWrapPos(ctx, 0)
          local preview = S.subtitle_import_modal.subtitle_content:sub(1)
          if #S.subtitle_import_modal.subtitle_content > 500 then
            preview = preview .. "..."
          end
          r.ImGui_Text(ctx, preview)
          r.ImGui_PopTextWrapPos(ctx)
          r.ImGui_EndChild(ctx)
        end
        r.ImGui_PopStyleVar(ctx)
        r.ImGui_PopStyleColor(ctx)
      end
      r.ImGui_Spacing(ctx)
      r.ImGui_Separator(ctx)
      r.ImGui_Spacing(ctx)
      r.ImGui_TextColored(ctx, C.text_dim, "Мова субтитрів:")
      r.ImGui_SameLine(ctx)
      r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), C.text_err)
      r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), 0x00000000)
      if r.ImGui_Button(ctx, "?", 20, 20) then end
      r.ImGui_PopStyleColor(ctx, 2)
      if r.ImGui_IsItemHovered(ctx) then
        r.ImGui_SetTooltip(ctx, "Виберіть мову для субтитрів")
      end
      local languages = {
        { code = "ukr", name = "Українська" },
        { code = "eng", name = "Англійська" },
        { code = "kor", name = "Корейська" },
        { code = "fra", name = "Французька" },
        { code = "deu", name = "Німецька" },
        { code = "spa", name = "Іспанська" },
        { code = "ita", name = "Італійська" },
        { code = "pol", name = "Польська" },
        { code = "ces", name = "Чеська" },
        { code = "jpn", name = "Японська" },
        { code = "zho", name = "Китайська" },
        { code = "und", name = "Невизначена" }
      }
      local current_lang_name = "Українська"
      for _, lang in ipairs(languages) do
        if lang.code == S.subtitle_import_modal.subtitle_lang then
          current_lang_name = lang.name
          break
        end
      end
      r.ImGui_PushID(ctx, "subtitle_lang_combo")
      if r.ImGui_BeginCombo(ctx, "##sub_lang", current_lang_name) then
        for _, lang in ipairs(languages) do
          local selected = (S.subtitle_import_modal.subtitle_lang == lang.code)
          if r.ImGui_Selectable(ctx, lang.name, selected) then
            S.subtitle_import_modal.subtitle_lang = lang.code
          end
          if selected then
            r.ImGui_SetItemDefaultFocus(ctx)
          end
        end
        r.ImGui_EndCombo(ctx)
      end
      r.ImGui_PopID(ctx)
      r.ImGui_Spacing(ctx)
      local keep_changed, keep_subs = r.ImGui_Checkbox(ctx,
        "Зберегти існуючі субтитри з оригінального відео##keep_subs",
        S.subtitle_import_modal.keep_existing_subs)
      if keep_changed then
        S.subtitle_import_modal.keep_existing_subs = keep_subs
      end
      r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), C.text_warn)
      if r.ImGui_IsItemHovered(ctx) then
        r.ImGui_SetTooltip(ctx, "Якщо вимкнути, оригінальні субтитри не будуть скопійовані у новий файл")
      end
      r.ImGui_PopStyleColor(ctx)
      r.ImGui_Spacing(ctx)
      r.ImGui_TextColored(ctx, C.text_dim, "Назва субтитрів:")
      S.subtitle_import_modal.subtitle_title = S.subtitle_import_modal.subtitle_title or ""
      r.ImGui_PushID(ctx, "subtitle_title_input")
      r.ImGui_SetNextItemWidth(ctx, 360)
      local changed, new_title = r.ImGui_InputText(
        ctx, "##sub_title",
        S.subtitle_import_modal.subtitle_title,
        128
      )
      if changed then
        S.subtitle_import_modal.subtitle_title = new_title
      end
      r.ImGui_PopID(ctx)
    else
      r.ImGui_Spacing(ctx)
      r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), C.text_dim)
      r.ImGui_TextWrapped(ctx, "Оберіть файл субтитрів для продовження...")
      r.ImGui_PopStyleColor(ctx)
    end
    r.ImGui_Spacing(ctx)
    r.ImGui_Separator(ctx)
    r.ImGui_Spacing(ctx)
    local has_subtitle = (S.subtitle_import_modal.subtitle_file ~= "")
    local disabled = not has_subtitle or S.subtitle_import_modal.processing
    if S.subtitle_import_modal.processing then
      r.ImGui_Spacing(ctx)
      r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), C.text_warn)
      r.ImGui_TextWrapped(ctx, S.status or "Обробка...")
      r.ImGui_PopStyleColor(ctx)
      r.ImGui_Spacing(ctx)
      S.subtitle_import_modal.visual_progress = S.subtitle_import_modal.visual_progress or 0
      local target_progress = S.subtitle_import_modal.progress
      if target_progress > 0 then
        S.subtitle_import_modal.visual_progress = S.subtitle_import_modal.visual_progress +
            (target_progress - S.subtitle_import_modal.visual_progress) * 0.08
        if math.abs(target_progress - S.subtitle_import_modal.visual_progress) < 0.001 then
          S.subtitle_import_modal.visual_progress = target_progress
        end
        local display_prog = math.max(0.0, math.min(1.0, S.subtitle_import_modal.visual_progress))
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), C.btn)
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_PlotHistogram(), C.text_ok)
        r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FrameRounding(), 4.0)
        r.ImGui_ProgressBar(ctx, display_prog, modal_w - 60, 20,
          string.format("%d%%", math.floor(display_prog * 100)))
        r.ImGui_PopStyleVar(ctx)
        r.ImGui_PopStyleColor(ctx, 2)
      else
        local spinner_chars = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
        local spin_idx = math.floor(os.clock() * 10) % #spinner_chars + 1
        local spin = spinner_chars[spin_idx]
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), C.btn)
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), C.text_warn)
        r.ImGui_Button(ctx, spin .. "  " .. (S.subtitle_import_modal.progress_text or "Очікування..."),
          modal_w - 32, 20)
        r.ImGui_PopStyleColor(ctx, 2)
      end
      if S.subtitle_import_modal.progress_text ~= "" and target_progress > 0 then
        r.ImGui_Spacing(ctx)
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), C.text_dim)
        r.ImGui_TextWrapped(ctx, S.subtitle_import_modal.progress_text)
        r.ImGui_PopStyleColor(ctx)
      end
    else
      if disabled then
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), C.text_dim)
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), C.btn_dis)
      end
      if r.ImGui_Button(ctx, "Додати субтитри", modal_w - 28, 35) then
        if not disabled then
          local init_dir = S.file:match("(.*)[/\\]") or ""
          local video_name_noext = (S.file:match("[/\\]([^/\\]+)$") or "video"):gsub("%.[^%.]+$", "")
          local ext = S.file:match("%.([^%.]+)$") or "mkv"
          local default_name = video_name_noext .. "_with_subs." .. ext
          local ok_save, save_path = r.JS_Dialog_BrowseForSaveFile(
            "Зберегти відео з субтитрами",
            init_dir,
            default_name,
            "Video files (*." .. ext .. ")\0*." .. ext .. "\0All Files (*.*)\0*.*\0"
          )
          if ok_save and save_path and save_path ~= "" then
            save_path = save_path:gsub("%z.*", "")
            S.subtitle_import_modal.processing = true
            S.subtitle_import_modal.progress = 0
            S.subtitle_import_modal.visual_progress = 0
            S.subtitle_import_modal.progress_text = "Початок..."
            do_add_subtitle_async(save_path)
          end
        end
      end
      if disabled then
        r.ImGui_PopStyleColor(ctx, 2)
      end
    end
    r.ImGui_PopFont(ctx)
    r.ImGui_End(ctx)
  end
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
    if r.ImGui_BeginChild(ctx, "##dropzone", inner_w, 50, CHILD_BORDER, 0) then
      local btn_width = 140
      local spacing = 8
      local has_file = S.file ~= ""
      r.ImGui_SetCursorPos(ctx, 8, 6)
      if not has_file then
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), C.text_dim)
        r.ImGui_Text(ctx, "Файл не обрано")
        r.ImGui_PopStyleColor(ctx)
      else
        local filename = S.file:match("[/\\]([^/\\]+)$") or S.file
        local display_name = "▶  " .. filename
        local avail_w = inner_w - btn_width - (spacing * 2) + 140
        local max_chars = math.floor(avail_w / 8)
        if #display_name > max_chars and max_chars > 10 then
          display_name = display_name:sub(1, max_chars - 3) .. "..."
        end
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), C.text_cyan)
        r.ImGui_Text(ctx, display_name)
        r.ImGui_PopStyleColor(ctx)
        if r.ImGui_IsItemHovered(ctx) then
          r.ImGui_SetTooltip(ctx, S.file)
        end
      end
      r.ImGui_SetCursorPos(ctx, 8, 26)
      r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), C.text_dim)
      local ff_text = "ffprobe: " .. (FFPROBE:match("[/\\]([^/\\]+)$") or FFPROBE)
      local ff_max_chars = math.floor((inner_w - btn_width - 20) / 8)
      if #ff_text > ff_max_chars then ff_text = ff_text:sub(1, ff_max_chars - 3) .. "..." end
      r.ImGui_Text(ctx, ff_text)
      r.ImGui_PopStyleColor(ctx)
      if has_file then
        local x = inner_w - btn_width - spacing
        r.ImGui_SetCursorPos(ctx, x + 20, 10)
        if r.ImGui_Button(ctx, "Додатково ▾", 120, 30) then
          r.ImGui_OpenPopup(ctx, "extra_menu")
        end
        if r.ImGui_BeginPopup(ctx, "extra_menu") then
          if r.ImGui_MenuItem(ctx, "Замінити аудіо...") then
            S.replace_modal.open = true
          end
          if r.ImGui_MenuItem(ctx, "Додати субтитри...") then
            S.subtitle_import_modal.open = true
          end
          r.ImGui_Separator(ctx)
          if r.ImGui_MenuItem(ctx, "Копіювати шлях") then
            r.CF_SetClipboard(S.file)
            S.status = "✓ Шлях скопійовано"
          end
          r.ImGui_EndPopup(ctx)
        end
      end
      r.ImGui_EndChild(ctx)
    end
    r.ImGui_PopStyleColor(ctx)
    r.ImGui_Spacing(ctx)
    local hw = math.floor((inner_w - 4) / 2.01)
    if r.ImGui_Button(ctx, "Обрати .mp4/.mkv файл…", hw, 30) then
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
    if r.ImGui_Button(ctx, "Обрати з файлу проєкта", hw, 30) then
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
          local avail_w = r.ImGui_GetContentRegionAvail(ctx) + 70
          local max_chars = math.floor(avail_w / 8)
          local display_label = s.label
          if #s.label > max_chars and max_chars > 10 then
            display_label = s.label:sub(1, max_chars - 3) .. "..."
          end
          local changed, newval = r.ImGui_Checkbox(ctx, display_label .. "##s" .. i, s.selected)
          if changed then
            S.streams[i].selected = newval
          end
          if r.ImGui_IsItemHovered(ctx) then
            r.ImGui_BeginTooltip(ctx)
            r.ImGui_TextColored(ctx, C.text, s.label)
            r.ImGui_EndTooltip(ctx)
          end
          if s.type == "audio" and s.selected and s.channels and s.channels > 0 then
            r.ImGui_Indent(ctx, 20)
            if not S.selected_channels[s.idx] then
              S.selected_channels[s.idx] = {}
              for ch = 1, s.channels do
                S.selected_channels[s.idx][ch] = true
              end
            end
            for ch = 1, s.channels do
              local ch_label = (s.channels <= 6) and
                  (ch == 1 and "L" or ch == 2 and "R" or ch == 3 and "C" or
                    ch == 4 and "LFE" or ch == 5 and "Ls" or ch == 6 and "Rs" or string.format("ch%d", ch))
                  or string.format("ch%d", ch)
              if r.ImGui_Checkbox(ctx, ch_label .. "##ch" .. s.idx .. "_" .. ch, S.selected_channels[s.idx][ch]) then
                S.selected_channels[s.idx][ch] = not S.selected_channels[s.idx][ch]
              end
              r.ImGui_SameLine(ctx, 0, 8)
            end
            r.ImGui_Unindent(ctx, 20)
          end
          r.ImGui_PopStyleColor(ctx)
          if changed then S.streams[i].selected = newval end
          local btn_width = 80
          local spacing = 40
          if s.type == "subtitle" then
            r.ImGui_SameLine(ctx, WIN_W - btn_width - spacing)
            if r.ImGui_Button(ctx, "Перегляд##sub" .. i, btn_width, 0) then
              S.status = "Витягую субтитри для перегляду..."
              local mdir = get_media_dir()
              extract_stream_async(S.file, s, mdir, function(out)
                if out then
                  local content = read_subtitle_preview(out)
                  if content then
                    S.preview_sub.content = content
                    S.preview_sub.title = (s.title ~= "" and s.title or ("Потік #" .. s.idx))
                    S.preview_sub.stream_idx = s.idx
                    S.preview_sub.open = true
                    S.status = "Готово до перегляду"
                  else
                    S.status = "Помилка: не вдалося прочитати субтитри"
                  end
                  os.remove(out)
                else
                  S.status = "Помилка витягування субтитрів"
                end
              end)
            end
          end
          if s.type == "audio" then
            local is_current = (S.audio_preview.current_stream_idx == s.idx)
            local is_playing = is_current and S.audio_preview.playing and not S.audio_preview.paused
            r.ImGui_SameLine(ctx, WIN_W - btn_width - spacing)
            if is_playing then
              r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), 0x8a3a3aff)
              r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), 0x9a4a4aff)
            else
              r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), 0x3e3e48ff)
              r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), 0x5a5a66ff)
            end
            local btn_label = is_playing and "▉" or "▶"
            if r.ImGui_Button(ctx, btn_label .. "##aud" .. i, btn_width, 0) then
              if is_current and S.audio_preview.source then
                stop_audio_preview()
                S.status = "Відтворення зупинено"
              else
                stop_audio_preview()
                local use_channel_selection = false
                local selected_channels_list = {}
                if S.selected_channels[s.idx] then
                  local selected_count = 0
                  for ch = 1, s.channels do
                    if S.selected_channels[s.idx][ch] then
                      selected_count = selected_count + 1
                      table.insert(selected_channels_list, ch)
                    end
                  end
                  if selected_count > 0 and selected_count < s.channels then
                    use_channel_selection = true
                  end
                end
                local ffmpeg_cmd
                local out_path
                if use_channel_selection then
                  r.RecursiveCreateDirectory(TEMP_PREVIEW_DIR, 0)
                  out_path = TEMP_PREVIEW_DIR .. string.format("preview_%d_%d.m4a", s.idx, os.time())
                  ffmpeg_cmd = string.format(
                    '"%s" -y -i "%s" -map 0:%d -af "%s" -t 180 -c:a aac -b:a 96k "%s"',
                    FFMPEG, S.file, s.idx, build_pan_filter(selected_channels_list), out_path)
                else
                  local mdir = get_media_dir()
                  local base = (S.file:match("[/\\]([^/\\]+)$") or "track"):gsub("%.[^%.]+$", "")
                  local lang_sfx = (s.lang ~= "") and ("_" .. s.lang) or ""
                  local ext = stream_ext(s)
                  out_path = mdir .. SEP .. safe_filename(
                    string.format("%s_s%d%s.%s", base, s.idx, lang_sfx, ext))
                  ffmpeg_cmd = string.format(
                    '"%s" -y -i "%s" -map 0:%d -c copy "%s"',
                    FFMPEG, S.file, s.idx, out_path)
                end
                local stream_label = s.label
                local stream_idx = s.idx
                local stream_title = s.title
                if use_channel_selection then
                  local ch_names = {}
                  for _, ch in ipairs(selected_channels_list) do
                    local ch_name
                    if s.channels <= 6 then
                      local names = { [1] = "L", [2] = "R", [3] = "C", [4] = "LFE", [5] = "Ls", [6] = "Rs" }
                      ch_name = names[ch] or string.format("%d", ch)
                    else
                      local names_7_1 = {
                        [1] = "L",
                        [2] = "R",
                        [3] = "C",
                        [4] = "LFE",
                        [5] = "Lss",
                        [6] = "Rss",
                        [7] =
                        "Lrs",
                        [8] = "Rrs"
                      }
                      ch_name = names_7_1[ch] or string.format("%d", ch)
                    end
                    table.insert(ch_names, ch_name)
                  end
                  S.audio_preview.name = string.format("%s [тільки %s]",
                    stream_title ~= "" and stream_title or ("Потік #" .. stream_idx),
                    table.concat(ch_names, ","))
                else
                  S.audio_preview.name = stream_label
                end
                S.audio_preview.current_stream_idx = stream_idx
                S.status = "Витягую аудіо…"
                run_ffmpeg_async(ffmpeg_cmd, function()
                  local f = io.open(out_path, "rb")
                  local size = f and f:seek("end")
                  if f then f:close() end
                  if size and size > 0 then
                    if r.PCM_Source_CreateFromFile and r.CF_CreatePreview then
                      local source = r.PCM_Source_CreateFromFile(out_path)
                      S.audio_preview.source = r.CF_CreatePreview(source)
                      S.audio_preview.file = out_path
                      S.audio_preview.playing = true
                      S.audio_preview.paused = false
                      S.audio_preview.pause_pos = 0
                      local _, len = r.CF_Preview_GetValue(S.audio_preview.source, "D_LENGTH")
                      S.audio_preview.length = len or 0
                      r.CF_Preview_Play(S.audio_preview.source)
                      S.status = "Відтворення: " .. (S.audio_preview.name or "")
                    else
                      S.status = "Помилка: не вдалося створити аудіо-джерело"
                    end
                  else
                    S.status = "Помилка витягування аудіо"
                    S.audio_preview.current_stream_idx = nil
                    S.audio_preview.name = nil
                  end
                end)
              end
            end
            if r.ImGui_IsItemHovered(ctx) then
              local show_tip = false
              if S.selected_channels[s.idx] then
                local selected_count = 0
                for ch = 1, s.channels do
                  if S.selected_channels[s.idx][ch] then
                    selected_count = selected_count + 1
                  end
                end
                if selected_count > 0 and selected_count < s.channels then
                  show_tip = true
                end
              end
              if show_tip then
                r.ImGui_BeginTooltip(ctx)
                r.ImGui_PushTextWrapPos(ctx, 300)
                r.ImGui_TextColored(ctx, C.text_warn,
                  "Обрано не всі канали\n" ..
                  "Прев'ю обмежено: 3 хв.")
                r.ImGui_PopTextWrapPos(ctx)
                r.ImGui_EndTooltip(ctx)
              end
            end
            r.ImGui_PopStyleColor(ctx, 2)
          end
        end
      end
      r.ImGui_EndChild(ctx)
    end

    -- ── НИЖНЯ ЗОНА ───────────────
    r.ImGui_Spacing(ctx)
    if S.file ~= "" and #S.streams > 0 then
      local any = false
      for _, s in ipairs(S.streams) do
        if s.selected then
          any = true; break
        end
      end
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
            local to_save = {}
            local base = (S.file:match("[/\\]([^/\\]+)$") or "track"):gsub("%.[^%.]+$", "")
            for _, s in ipairs(S.streams) do
              if s.selected then
                local ext = stream_ext(s)
                local lang_sfx = (s.lang ~= "") and ("_" .. s.lang) or ""
                local ch_sfx = ""
                local use_channel_selection = false
                local selected_list = {}
                if s.type == "audio" and S.selected_channels[s.idx] then
                  for ch, selected in pairs(S.selected_channels[s.idx]) do
                    if selected then table.insert(selected_list, ch) end
                  end
                  table.sort(selected_list)
                  if #selected_list > 0 and #selected_list < s.channels then
                    use_channel_selection = true
                    ch_sfx = "_ch" .. table.concat(selected_list, "")
                    ext = "wav"
                  end
                end
                local out_path = out_dir .. SEP .. safe_filename(
                  string.format("%s_s%d%s%s.%s", base, s.idx, lang_sfx, ch_sfx, ext))
                local ffmpeg_cmd
                if use_channel_selection then
                  ffmpeg_cmd = string.format(
                    '"%s" -y -i "%s" -map 0:%d -af "%s" -ac %d "%s"',
                    FFMPEG, S.file, s.idx, build_pan_filter(selected_list), #selected_list, out_path)
                elseif s.type == "attachment" then
                  ffmpeg_cmd = string.format(
                    '"%s" -y -dump_attachment:%d "%s" -i "%s"',
                    FFMPEG, s.idx, out_path, S.file)
                else
                  ffmpeg_cmd = string.format(
                    '"%s" -y -i "%s" -map 0:%d -c copy "%s"',
                    FFMPEG, S.file, s.idx, out_path)
                end
                table.insert(to_save, {
                  s        = s,
                  out_path = out_path,
                  cmd      = ffmpeg_cmd,
                })
              end
            end
            if #to_save == 0 then return end
            local save_idx = 0
            local saved, failed = 0, 0
            S.processing = true
            local function save_next()
              save_idx = save_idx + 1
              if save_idx > #to_save then
                S.processing = false
                if failed == 0 then
                  S.status = string.format("✓ Збережено %d файл(ів) у: %s",
                    saved, (out_dir:match("[/\\]([^/\\]+)$") or out_dir))
                else
                  S.status = string.format("Збережено: %d / Помилок: %d", saved, failed)
                end
                return
              end
              local item = to_save[save_idx]
              S.status = string.format("Зберігаю %d/%d: потік #%d…",
                save_idx, #to_save, item.s.idx)
              run_ffmpeg_async(item.cmd, function()
                local f = io.open(item.out_path, "rb")
                local size = f and f:seek("end")
                if f then f:close() end
                if size and size > 0 then
                  saved = saved + 1
                else
                  failed = failed + 1
                end
                save_next()
              end)
            end
            save_next()
          end
        end
      end
      if save_disabled then r.ImGui_PopStyleColor(ctx) end
    end
    r.ImGui_Spacing(ctx)
    if not S.audio_preview.source then
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
    end
    if not S.audio_preview.source and S.show_diag and S.diag ~= "" then
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
  draw_subtitle_preview()
  draw_replace_audio_modal()
  draw_subtitle_import_modal()
  draw_mini_audio_player()
  r.ImGui_PopStyleVar(ctx, 5)
  r.ImGui_End(ctx)
  r.ImGui_PopStyleColor(ctx, n_colors)
end

local function cleanup_preview_resources()
  if S.audio_preview.source then
    r.CF_Preview_Stop(S.audio_preview.source)
    S.audio_preview.source = nil
  end
  S.preview_sub.open = false
  S.preview_sub.content = nil
  S.audio_preview.playing = false
  S.audio_preview.paused = false
  S.audio_preview.name = nil
  S.audio_preview.current_stream_idx = nil
  S.audio_preview.pause_pos = 0
  S.audio_preview.length = 0
end

local function clean_old_preview_files()
  if TEMP_PREVIEW_DIR and TEMP_PREVIEW_DIR ~= "" then
    r.RecursiveCreateDirectory(TEMP_PREVIEW_DIR, 0)
    if r.EnumerateFiles then
      local idx = 0
      while true do
        local filename = r.EnumerateFiles(TEMP_PREVIEW_DIR, idx)
        if not filename then break end
        local full_path = TEMP_PREVIEW_DIR .. filename
        local success, err = pcall(os.remove, full_path)
        idx = idx + 1
      end
    end
  end
end

local function on_window_close()
  cleanup_preview_resources()
  for _, task in ipairs(async_tasks) do
    if task.out_file then pcall(os.remove, task.out_file) end
    if task.done_file then pcall(os.remove, task.done_file) end
  end
  async_tasks = {}
end

S.ctx = r.ImGui_CreateContext("MKV/MP4 Extract")
clean_old_preview_files()

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
    S.status    = "ffmpeg не знайдено! Діагностика для деталей."
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
  if not S.ctx or not r.ImGui_ValidatePtr(S.ctx, 'ImGui_Context*') then return end
  poll_task_queue()
  local force_close = r.GetExtState("Subass_Global", "ForceCloseComplementary")
  if force_close == "1" or force_close == "imnotbad_MP4_MKV_Extract.lua" then
    if force_close == "imnotbad_MP4_MKV_Extract.lua" then
      r.SetExtState("Subass_Global", "ForceCloseComplementary", "0", false)
    end
    S.open = false
  end
  if not S.open then
    return
  end
  draw_ui()
  r.defer(loop)
end

if r.atexit then
  r.atexit(on_window_close)
end

r.defer(loop)
