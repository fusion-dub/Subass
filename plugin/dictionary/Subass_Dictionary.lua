-- @description Subass Dictionary
-- @version 1.9
-- @author Fusion (Fusion Dub)
-- @about Dictionary of slang, idioms and terminology for dubbing.

local ctx = reaper.ImGui_CreateContext('Subass Dictionary')
local font_main = reaper.ImGui_CreateFont('sans-serif', 15)
local font_tabs = reaper.ImGui_CreateFont('sans-serif', 17)

reaper.ImGui_Attach(ctx, font_main)
reaper.ImGui_Attach(ctx, font_tabs)

-- Initial window size
local WIN_W, WIN_H = 600, 500
local dict_open = true

-- Color Constants (Hex)
local C_BTN_OK = 0x50C850FF
local C_BTN_MEDIUM = 0x4B824BFF
local C_BTN_CLOSE = 0x0000000F
local C_SEL_BG = 0x4CA6FFFF

-- Load dictionary data
local script_path = debug.getinfo(1,'S').source:match([[^@?(.*[\/])]])

-- Global ImGui Style
local Style = dofile(script_path .. "Subass_ReaImGuiGlobalStyle.lua")

-- Data paths for Glossary
local data_path = script_path .. "data/"
local glossary_file = data_path .. "glossary.json"

local user_dicts_file = data_path .. "user_dictionaries.json"

local UTILS = {}

local cfg = {
    -- Tab Persistence
    last_tab = tonumber(reaper.GetExtState("Subass_Dictionary", "last_tab")) or 0,
    restore_tab = true,
}

local cfg_ref = {
    categories = {},
    cached_results = {},
    last_filter = nil,
    ref_filter = "",
}

local cfg_glos = {
    glossary_data = { entries = {} },
    add_entry_pending = nil,
    edit_entry_idx = nil,
    edit_entry_data = {},
    open_edit_popup = false,
    current_preview_source = nil,
    layout_has_player = false,
    current_preview_name = "",
    current_preview_file = "",
    current_preview_paused = false,
    current_preview_pause_pos = 0,
    current_preview_length = 0,
    active_tags = {},  -- Set of active tags: { ["tag"] = true }
    glos_filter = "",
}

local cfg_dict = {
    udd = { dictionaries = {} },
    dict_filter = "",
    entry_selection = {}, -- { index = true }
    last_selected_idx = nil,
    new_dict_name = "",
    rename_dict_idx = nil,
    rename_dict_name = "",
    sd_inx = nil,
}

local cfg_dwn = {
    dwn_search = "",
    search_data = nil,
    is_searching = false,
    preview_data = nil,
    loading_item = nil,
    error_tooltip = nil,
    thumbnail_tex = nil,
    thumbnail_path = nil,
}
local temp_path = script_path .. "temp/"
reaper.RecursiveCreateDirectory(temp_path, 0)

-- Read last selected dict from ExtState
local last_dict = tonumber(reaper.GetExtState("Subass_Dictionary", "last_dict_idx"))
if last_dict and last_dict > 0 and last_dict <= #cfg_dict.udd.dictionaries then
    cfg_dict.sd_inx = last_dict
elseif #cfg_dict.udd.dictionaries > 0 then
    cfg_dict.sd_inx = 1
end

-- Async Command Execution
UTILS.async_pool = {}

function UTILS.get_python_cmd(args)
    local script = script_path .. "../stats/subass_download.py"
    if reaper.GetOS():match("Win") then
        return string.format('py -3 "%s" %s || python "%s" %s', script, args, script, args)
    else
        -- On Mac, ensure homebrew paths are available
        return string.format('export PATH=$PATH:/opt/homebrew/bin:/usr/local/bin; python3 "%s" %s', script, args)
    end
end

function UTILS.run_async_command(shell_cmd, callback)
    local id = tostring(os.time()) .. "_" .. math.random(1000, 9999)
    local path = reaper.GetResourcePath() .. "/Scripts/"
    local out_file = path .. "subass_dict_out_" .. id .. ".tmp"
    local done_file = path .. "subass_dict_done_" .. id .. ".marker"
    
    if reaper.GetOS():match("Win") then
        out_file = out_file:gsub("/", "\\")
        done_file = done_file:gsub("/", "\\")
        local bat_file = (path .. "subass_dict_exec_" .. id .. ".bat"):gsub("/", "\\")

        local f_bat = io.open(bat_file, "w")
        if f_bat then
            f_bat:write("@echo off\r\n")
            f_bat:write("chcp 65001 > NUL\r\n")
            local bat_cmd = shell_cmd:gsub("%%", "%%%%")
            f_bat:write(bat_cmd .. ' > "' .. out_file .. '" 2>&1\r\n')
            f_bat:write('echo DONE > "' .. done_file .. '"\r\n')
            f_bat:write('del "%~f0"\r\n')
            f_bat:close()

            local safe_bat = bat_file:gsub("'", "''")
            local ps_cmd = 'powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "Start-Process \'' .. safe_bat .. '\' -WindowStyle Hidden"'
            reaper.ExecProcess(ps_cmd, 0)
        end
    else
        local env_path = "export PATH=/opt/homebrew/bin:/usr/local/bin:$PATH; "
        local full_cmd = '( ' .. env_path .. shell_cmd .. ' > "' .. out_file .. '" 2>&1 ; touch "' .. done_file .. '" ) &'
        os.execute(full_cmd)
    end
    
    table.insert(UTILS.async_pool, {
        id = id,
        out_file = out_file,
        done_file = done_file,
        callback = callback,
        start_time = os.time()
    })
end

function UTILS.check_async_tasks()
    local now = os.time()
    for i = #UTILS.async_pool, 1, -1 do
        local task = UTILS.async_pool[i]
        if reaper.file_exists(task.done_file) then
            local f = io.open(task.out_file, "r")
            local output = ""
            if f then output = f:read("*all"); f:close() end
            
            os.remove(task.out_file)
            os.remove(task.done_file)
            
            if task.callback then task.callback(output) end
            table.remove(UTILS.async_pool, i)
        elseif task.start_time and (now - task.start_time > 30) then
            os.remove(task.out_file)
            os.remove(task.done_file)
            if task.callback then task.callback("TIMEOUT") end
            table.remove(UTILS.async_pool, i)
        end
    end
end

-- Simple JSON Helpers
function UTILS.json_encode(v)
    if type(v) == "string" then return string.format("%q", v)
    elseif type(v) == "number" or type(v) == "boolean" then return tostring(v)
    elseif type(v) == "table" then
        local is_array = #v > 0
        local parts = {}
        if is_array then
            for _, val in ipairs(v) do table.insert(parts, UTILS.json_encode(val)) end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            for k, val in pairs(v) do
                table.insert(parts, string.format("%q:%s", tostring(k), UTILS.json_encode(val)))
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    end
    return "null"
end

function UTILS.json_decode(s)
    local pos = 1
    
    local skip_ws = function()
        local next_pos = s:find("[^%s]", pos)
        if next_pos then pos = next_pos end
    end
    
    local parse_val -- forward declaration
    
    local function parse_string()
        local result = {}
        pos = pos + 1 -- skip "
        while pos <= #s do
            local char = s:sub(pos, pos)
            if char == '"' then
                pos = pos + 1
                return table.concat(result)
            elseif char == "\\" then
                local next_char = s:sub(pos + 1, pos + 1)
                if next_char == '"' then table.insert(result, '"')
                elseif next_char == "\\" then table.insert(result, "\\")
                elseif next_char == "/" then table.insert(result, "/")
                elseif next_char == "b" then table.insert(result, "\b")
                elseif next_char == "f" then table.insert(result, "\f")
                elseif next_char == "n" then table.insert(result, "\n")
                elseif next_char == "r" then table.insert(result, "\r")
                elseif next_char == "t" then table.insert(result, "\t")
                elseif next_char == "u" then
                    local hex = s:sub(pos + 2, pos + 5)
                    local cp = tonumber(hex, 16)
                    if cp then
                        -- Simple conversion for basic plane
                        if cp < 128 then table.insert(result, string.char(cp))
                        elseif cp < 2048 then table.insert(result, string.char(192 + (cp >> 6), 128 + (cp & 63)))
                        else table.insert(result, string.char(224 + (cp >> 12), 128 + ((cp >> 6) & 63), 128 + (cp & 63))) end
                    end
                    pos = pos + 4
                end
                pos = pos + 2
            else
                table.insert(result, char)
                pos = pos + 1
            end
        end
        return table.concat(result)
    end
    
    local parse_object = function()
        local obj = {}
        pos = pos + 1 -- skip {
        while pos <= #s do
            skip_ws()
            if s:sub(pos, pos) == "}" then pos = pos + 1 return obj end
            
            local key = parse_string()
            skip_ws()
            if s:sub(pos, pos) ~= ":" then break end
            pos = pos + 1
            obj[key] = parse_val()
            
            skip_ws()
            local sep = s:sub(pos, pos)
            if sep == "," then 
                pos = pos + 1
            elseif sep == "}" then 
                pos = pos + 1
                return obj
            else
                break
            end
        end
        return obj
    end
    
    local parse_array = function()
        local arr = {}
        pos = pos + 1 -- skip [
        while pos <= #s do
            skip_ws()
            if s:sub(pos, pos) == "]" then pos = pos + 1 return arr end
            
            table.insert(arr, parse_val())
            
            skip_ws()
            local sep = s:sub(pos, pos)
            if sep == "," then
                pos = pos + 1
            elseif sep == "]" then
                pos = pos + 1
                return arr
            else
                break
            end
        end
        return arr
    end
    
    parse_val = function()
        skip_ws()
        local char = s:sub(pos, pos)
        if char == "{" then
            return parse_object()
        elseif char == "[" then
            return parse_array()
        elseif char == '"' then
            return parse_string()
        elseif s:match('^true', pos) then 
            pos = pos + 4
            return true
        elseif s:match('^false', pos) then 
            pos = pos + 5
            return false
        elseif s:match('^null', pos) then 
            pos = pos + 4
            return nil
        else
            local val = s:match('^[%d%.%-eE]+', pos)
            if val then
                pos = pos + #val
                return tonumber(val)
            end
        end
        pos = pos + 1
        return nil
    end
    
    local ok, res = pcall(parse_val)
    if ok and type(res) == "table" then return res end
    return {}
end

function UTILS.load_glossary()
    local f = io.open(glossary_file, "r")
    if f then
        local content = f:read("*a")
        f:close()
        cfg_glos.glossary_data = UTILS.json_decode(content)
        if not cfg_glos.glossary_data.entries then cfg_glos.glossary_data = { entries = {} } end
    end
end

function UTILS.save_glossary()
    local f = io.open(glossary_file, "w")
    if f then
        f:write(UTILS.json_encode(cfg_glos.glossary_data))
        f:close()
    end
end

UTILS.load_glossary()

function UTILS.load_user_dicts()
    local f = io.open(user_dicts_file, "r")
    if f then
        local content = f:read("*a")
        f:close()
        cfg_dict.udd = UTILS.json_decode(content)
        if type(cfg_dict.udd) ~= "table" or type(cfg_dict.udd.dictionaries) ~= "table" then 
            cfg_dict.udd = { dictionaries = {} } 
        else
            -- Migration: assign IDs to existing entries
            for _, dict in ipairs(cfg_dict.udd.dictionaries) do
                if not dict.next_id then
                    local max_id = 0
                    for i, entry in ipairs(dict.entries) do
                        if not entry.uid then
                            entry.uid = i
                        end
                        if entry.uid > max_id then max_id = entry.uid end
                    end
                    dict.next_id = max_id + 1
                end
            end
        end
    end
end

local function utf8_lower(s)
    if not s then return "" end
    local res = {}
    local len = #s
    local i = 1
    while i <= len do
        local b = s:byte(i)
        if b < 128 then
            if b >= 65 and b <= 90 then table.insert(res, string.char(b + 32))
            else table.insert(res, string.char(b)) end
            i = i + 1
        else
            local seq_len = 0
            if b >= 240 then seq_len = 4
            elseif b >= 224 then seq_len = 3
            elseif b >= 192 then seq_len = 2 end
            
            if seq_len > 0 and i + seq_len - 1 <= len then
                local codepoint = 0
                if seq_len == 2 then codepoint = ((b & 31) << 6) | (s:byte(i+1) & 63)
                elseif seq_len == 3 then codepoint = ((b & 15) << 12) | ((s:byte(i+1) & 63) << 6) | (s:byte(i+2) & 63)
                elseif seq_len == 4 then codepoint = ((b & 7) << 18) | ((s:byte(i+1) & 63) << 12) | ((s:byte(i+2) & 63) << 6) | (s:byte(i+3) & 63) end
                
                -- Cyrillic Case Mapping
                if codepoint >= 1040 and codepoint <= 1071 then codepoint = codepoint + 32 
                elseif codepoint == 1025 then codepoint = 1105 -- Yo
                elseif codepoint == 1028 then codepoint = 1108 -- Ye
                elseif codepoint == 1030 then codepoint = 1110 -- I
                elseif codepoint == 1031 then codepoint = 1111 -- Yi
                elseif codepoint == 1168 then codepoint = 1169 -- Ghe
                end
                
                if utf8 and utf8.char then
                    table.insert(res, utf8.char(codepoint))
                else
                    -- Fallback to string.char if only ASCII, or just skip if missing utf8 library for high codes
                    if codepoint < 128 then table.insert(res, string.char(codepoint)) end
                end
                i = i + seq_len
            else
                table.insert(res, string.char(b))
                i = i + 1
            end
        end
    end
    return table.concat(res)
end

function UTILS.entry_exists(entries, word, rep, com)
    for _, e in ipairs(entries) do
        if e.word == word and e.replacement == rep and e.comment == com then
            return true
        end
    end
    return false
end

function UTILS.save_user_dicts()
    local f = io.open(user_dicts_file, "w")
    if f then
        f:write(UTILS.json_encode(cfg_dict.udd))
        f:close()
    end
end

UTILS.load_user_dicts()

function UTILS.update_last_selected_dict(idx)
    cfg_dict.sd_inx = idx
    cfg_dict.entry_selection = {}
    cfg_dict.last_selected_idx = nil
    if idx then
        reaper.SetExtState("Subass_Dictionary", "last_dict_idx", tostring(idx), true)
    else
        reaper.SetExtState("Subass_Dictionary", "last_dict_idx", "", true) -- Clear if no dictionary is selected
    end
end

function UTILS.move_dict_to_top(idx)
    if idx and idx > 1 and cfg_dict.udd.dictionaries[idx] then
        local dict = table.remove(cfg_dict.udd.dictionaries, idx)
        table.insert(cfg_dict.udd.dictionaries, 1, dict)
        if cfg_dict.sd_inx == idx then
            cfg_dict.sd_inx = 1
        elseif cfg_dict.sd_inx and cfg_dict.sd_inx < idx then
            cfg_dict.sd_inx = cfg_dict.sd_inx + 1
        end
        UTILS.save_user_dicts()
        UTILS.update_last_selected_dict(cfg_dict.sd_inx)
    end
end

function UTILS.check_dict_name_exists(name, exclude_idx)
    if not name or name == "" then return false end
    for i, d in ipairs(cfg_dict.udd.dictionaries) do
        if i ~= exclude_idx and d.name == name then
            return true
        end
    end
    return false
end

function UTILS.import_dict_csv()
    local retval, filename = reaper.GetUserFileNameForRead(data_path, "Виберіть .csv файл", ".csv")
    if not retval or filename == "" then return end
    
    local f = io.open(filename, "r")
    if not f then return end
    
    local base_name = filename:match("([^/\\]+)%.[a-zA-Z0-9]+$") or "Імпортований словник"
    base_name = base_name:match("^%s*(.-)%s*$") -- Trim whitespace
    local name = base_name
    local counter = 1
    while UTILS.check_dict_name_exists(name) do
        name = base_name .. " (" .. counter .. ")"
        counter = counter + 1
    end
    local counter_id = 1
    local new_dict = { id = "dict_" .. os.time(), name = name, entries = {} }
    
    local is_first = true
    for line in f:lines() do
        -- Skip empty lines
        if line:match("^%s*$") then goto continue end
        
        -- Try to detect separator (, or ;) 
        -- Fallback to tab if none found but tabs exist
        local sep = ","
        if line:find(";") then sep = ";" end
        if not line:find(",") and not line:find(";") and line:find("\t") then sep = "\t" end
        
        -- Simple CSV split ignoring quotes (for basic glossaries this is usually enough)
        local parts = {}
        for part in string.gmatch(line .. sep, "(.-)" .. sep) do
            -- Remove surrounding quotes if they exist
            part = part:match('^"(.*)"$') or part
            table.insert(parts, part)
        end
        
        local word, rep, com = parts[1], parts[2], parts[3]
        if not word or not rep then goto continue end
        
        -- Skip header row if it looks like one
        if is_first then
            is_first = false
            -- Use utf8_lower for Cyrillic support
            local dummy_lower = utf8_lower(word)
            if dummy_lower:find("word") or dummy_lower:find("слово") then 
                goto continue 
            end
        end
        
        -- Skip empty words and duplicates
        if word and word:gsub("%s+", "") ~= "" then
            if not UTILS.entry_exists(new_dict.entries, word, rep or "", com or "") then
                table.insert(new_dict.entries, {
                    uid = counter_id,
                    word = word, 
                    replacement = rep or "", 
                    comment = com or ""
                })
                counter_id = counter_id + 1
            end
        end
        ::continue::
    end
    f:close()
    
    if #new_dict.entries > 0 then
        new_dict.next_id = counter_id
        table.insert(cfg_dict.udd.dictionaries, 1, new_dict)
        UTILS.save_user_dicts()
        UTILS.update_last_selected_dict(1)
        reaper.MB("Імпортовано " .. #new_dict.entries .. " записів.", "Імпорт", 0)
    else
        reaper.MB("Не знайдено записів для імпорту.", "Помилка", 0)
    end
end

function UTILS.export_dict_csv(dict)
    local safe_name = (dict.name or "Словник"):gsub("[^%wА-Яа-яІіЇїЄєҐґ-]", "_")
    local default_filename = safe_name .. "_Dictionary.csv"
    local path = ""
    
    -- Check for js_ReaScriptAPI
    if reaper.JS_Dialog_BrowseForSaveFile then
        local initial_dir = script_path
        local retval, filename = reaper.JS_Dialog_BrowseForSaveFile("Експорт Словника", initial_dir, default_filename, "CSV Files (*.csv)\0*.csv\0All Files (*.*)\0*.*\0")
        if retval and filename ~= "" then
            if not filename:lower():match("%.csv$") then filename = filename .. ".csv" end
            path = filename
        else
            return -- Cancelled
        end
    else
        -- Fallback to basic API if JS is not installed (no initial name though)
        local retval, filename = reaper.GetUserFileNameForRead(script_path, "Виберіть папку та введіть ім'я для збереження (напр. word.csv)", ".csv")
        if retval and filename ~= "" then
            if not filename:lower():match("%.csv$") then filename = filename .. ".csv" end
            path = filename
        else
            return -- Cancelled
        end
    end
    
    local f = io.open(path, "w")
    if f then
        f:write("Слово,Заміна,Коментар\n")
        for _, entry in ipairs(dict.entries) do
            local w = (entry.word or ""):gsub('"', '""')
            local r = (entry.replacement or ""):gsub('"', '""')
            local c = (entry.comment or ""):gsub('"', '""')
            f:write(string.format('"%s","%s","%s"\n', w, r, c))
        end
        f:close()
    else
        reaper.MB("Помилка збереження файлу.", "Помилка", 0)
    end
end

function UTILS.copy_file(src, dst)
    local f_src = io.open(src, "rb")
    if not f_src then return false end
    local content = f_src:read("*a")
    f_src:close()
    
    local f_dst = io.open(dst, "wb")
    if not f_dst then return false end
    f_dst:write(content)
    f_dst:close()
    return true
end

function UTILS.add_from_reaper()
    local item = reaper.GetSelectedMediaItem(0, 0)
    if not item then
        reaper.MB("Будь ласка, виберіть айтем у REAPER", "Помилка", 0)
        return nil
    end
    
    -- 1. Capture Name
    local take = reaper.GetActiveTake(item)
    local name = ""
    if take then
        local retval, take_name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
        if retval then name = take_name end
    end
    
    -- 2. Glue (Render trimmed version)
    -- Use Undo block to safely revert the project change
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)
    
    reaper.Main_OnCommand(41588, 0) -- Item: Glue items
    
    -- 3. Get new glued file
    local new_item = reaper.GetSelectedMediaItem(0, 0)
    local success = false
    local filename_result = nil
    
    local duration = 0
    if new_item then
        local new_take = reaper.GetActiveTake(new_item)
        if new_take then
            local source = reaper.GetMediaItemTake_Source(new_take)
            local src_path = reaper.GetMediaSourceFileName(source, "")
            duration = reaper.GetMediaSourceLength(source)
            
            if src_path and src_path ~= "" then
                local ext = src_path:match("%.([^%.]+)$") or "wav"
                local filename = "snd_" .. os.time() .. "_" .. math.random(100,999) .. "." .. ext
                local dst_path = data_path .. filename
                
                -- 4. Copy to data
                if UTILS.copy_file(src_path, dst_path) then
                    success = true
                    filename_result = filename
                end
            end
        end
    end
    
    reaper.PreventUIRefresh(-1)
    reaper.Undo_EndBlock("Glossary Temp Glue", -1)
    
    -- 5. Undo the Glue (Restore project state)
    reaper.Undo_DoUndo2(0)
    
    if success and filename_result then
         return {
            name = name,
            filename = filename_result,
            duration = duration,
            tags = "",
            desc = "",
            date = os.date("%Y-%m-%d %H:%M:%S")
        }
    else
        reaper.MB("Не вдалося обробити файл (Glue/Copy failed).", "Помилка", 0)
        return nil
    end
end

function UTILS.format_time(seconds)
    if not seconds then return "0:00" end
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%d:%02d", mins, secs)
end

function UTILS.stop_preview()
    if cfg_glos.current_preview_source and reaper.CF_Preview_Stop then
        reaper.CF_Preview_Stop(cfg_glos.current_preview_source)
    end
    cfg_glos.current_preview_source = nil
    cfg_glos.current_preview_name = ""
    cfg_glos.current_preview_paused = false
    cfg_glos.current_preview_pause_pos = 0
end

function UTILS.load_data()
    local f, err = loadfile(script_path .. "dictionary_data.lua")
    if f then
        cfg_ref.categories = f()
    else
        reaper.ShowConsoleMsg("Error loading dictionary data: " .. tostring(err) .. "\n")
        cfg_ref.categories = { { name = "Помилка завантаження", entries = {} } }
    end
    cfg_ref.last_filter = nil -- Force cache rebuild
end

function UTILS.update_search_cache(filter)
    local search_term = utf8_lower(filter)
    cfg_ref.cached_results = {}
    
    -- Categories can be an array or a map
    local sorted_categories = {}
    for k, v in pairs(cfg_ref.categories) do
        local cat_name, entries
        if type(k) == "number" then
            cat_name = v.name
            entries = v.entries
        else
            cat_name = k
            entries = v
        end
        
        if cat_name and entries then
            local items = {}
            for _, entry in ipairs(entries) do
                local word = entry.title or entry.word or ""
                local meaning = entry.definition or entry.meaning or ""
                
                if filter == "" or 
                   utf8_lower(word):find(search_term, 1, true) or 
                   utf8_lower(meaning):find(search_term, 1, true) then
                    table.insert(items, {word = word, meaning = meaning})
                end
            end
            if #items > 0 then
                table.insert(sorted_categories, { name = cat_name, entries = items })
            end
        end
    end
    
    -- Sort categories by name
    table.sort(sorted_categories, function(a, b) return a.name < b.name end)
    cfg_ref.cached_results = sorted_categories
    cfg_ref.last_filter = filter
end

UTILS.load_data()

function UTILS.import_subtitle_to_project(content, title, fmt)
    local prj_path = reaper.GetProjectPath("")
    if prj_path == "" then
        cfg_dwn.error_tooltip = { text = "Спершу збережіть проект!", t = reaper.time_precise() }
        return
    end
    
    local ext = (fmt and fmt:lower():match("^%a+$") and fmt:lower()) or "srt"
    local filename = title:gsub('[\\/:*?"<>|]', "_") .. "." .. ext
    local full_path = prj_path .. "/" .. filename
    
    local f = io.open(full_path, "w")
    if f then
        f:write(content)
        f:close()
        -- Signal Subass_Notes to import the saved file
        reaper.SetExtState("Subass_Notes", "import_request", full_path, false)
    else
        cfg_dwn.error_tooltip = { text = "Не вдалося зберегти файл: " .. filename, t = reaper.time_precise() }
    end
end

function UTILS.trigger_subtitle_download(item, source, mode, item_key)
    local cmd_args = string.format('--get-subtitle --source "%s"', source)
    
    if item.file_id then
        cmd_args = cmd_args .. string.format(' --id "%s"', item.file_id)
    elseif item.download_url then
        cmd_args = cmd_args .. string.format(' --url "%s"', item.download_url)
    elseif item.files_url then
        cmd_args = cmd_args .. string.format(' --url "%s"', item.files_url)
    end
    
    local cmd = UTILS.get_python_cmd(cmd_args)
    
    -- Mark this specific button as loading
    cfg_dwn.loading_item = item_key
    
    UTILS.run_async_command(cmd, function(output)
        cfg_dwn.loading_item = nil
        if output == "TIMEOUT" then
            cfg_dwn.error_tooltip = { text = "Помилка: Час очікування вичерпано.", t = reaper.time_precise() }
        else
            local success, res = pcall(UTILS.json_decode, output)
            if success and res and res.status == "success" then
                if mode == "preview" then
                    cfg_dwn.preview_data = {
                        title = item.title or item.file_name or "Subtitle",
                        content = res.content
                    }
                else
                    UTILS.import_subtitle_to_project(res.content, item.title or item.file_name or "Subtitle", res.format or item.format)
                end
            else
                cfg_dwn.error_tooltip = { text = "Помилка завантаження: " .. (res and (res.error or "невідома відповідь") or "невідома помилка"), t = reaper.time_precise() }
            end
        end
    end)
end

function UTILS.trigger_subtitle_from_url(url, lang, item_key)
    local cmd_args = string.format('--get-sub-from-url --target "%s" --sub-lang "%s"', url, lang)
    local cmd = UTILS.get_python_cmd(cmd_args)
    
    cfg_dwn.loading_item = item_key
    
    UTILS.run_async_command(cmd, function(output)
        cfg_dwn.loading_item = nil
        local success, res = pcall(UTILS.json_decode, output)
        if success and res and res.status == "success" then
            UTILS.import_subtitle_to_project(res.content, "Subtitle_" .. lang, res.format)
        else
            local err_msg = (res and res.error) or "Субтитри не знайдено."
            cfg_dwn.error_tooltip = { text = "Помилка: " .. err_msg, t = reaper.time_precise() }
        end
    end)
end

function UTILS.download_thumbnail(url, callback)
    if not url or url == "" then return end
    local ext = url:match("%.([^%.%?]+)($|%?)") or "jpg"
    local filename = "thumb_" .. reaper.genGuid():gsub("[{}-]", "") .. "." .. ext
    local full_path = temp_path .. filename
    
    local cmd_args = string.format('--download-thumb --target "%s" --output "%s"', url, full_path)
    local cmd = UTILS.get_python_cmd(cmd_args)
    
    UTILS.run_async_command(cmd, function(output)
        local success, res = pcall(UTILS.json_decode, output)
        if success and res and res.status == "success" then
            if callback then callback(full_path) end
        end
    end)
end

function UTILS.download_media(url, format_id, title, ext, m_type, item_key)
    local prj_path = reaper.GetProjectPath("")
    if prj_path == "" then
        cfg_dwn.error_tooltip = { text = "Спершу збережіть проект!", t = reaper.time_precise() }
        return
    end
    
    local filename = title:gsub('[\\/:*?"<>|]', "_") .. "." .. (ext or "mp4")
    local full_path = prj_path .. "/" .. filename
    
    local cmd_args = string.format('--download --target "%s" --format "%s" --type "%s" --output "%s"', 
        url, format_id, m_type or "", full_path)
    local cmd = UTILS.get_python_cmd(cmd_args)
    
    cfg_dwn.loading_item = item_key
    
    UTILS.run_async_command(cmd, function(output)
        cfg_dwn.loading_item = nil
        local success, res = pcall(UTILS.json_decode, output)
        if success and res and res.status == "success" then
            -- Insert into REAPER on a new track
            reaper.defer(function()
                reaper.InsertMedia(res.path, 0) -- 0: add to new track
            end)
        else
            local err_msg = (res and res.error) or "Завантаження не вдалося."
            cfg_dwn.error_tooltip = { text = "Помилка: " .. err_msg, t = reaper.time_precise() }
        end
    end)
end

local function draw_preview_popup()
    if not cfg_dwn.preview_data then return end
    
    local center = {reaper.ImGui_Viewport_GetCenter(reaper.ImGui_GetMainViewport(ctx))}
    reaper.ImGui_SetNextWindowPos(ctx, center[1], center[2], reaper.ImGui_Cond_Appearing(), 0.5, 0.5)
    reaper.ImGui_SetNextWindowSize(ctx, 700, 500, reaper.ImGui_Cond_FirstUseEver())
    
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(), 20, 20)
    local visible, open = reaper.ImGui_Begin(ctx, "Subtitle Preview", true, reaper.ImGui_WindowFlags_NoCollapse())
    reaper.ImGui_PopStyleVar(ctx)
    
    if not open then
        cfg_dwn.preview_data = nil
        reaper.ImGui_End(ctx)
        return
    end

    if visible then
        reaper.ImGui_PushFont(ctx, font_main, 20)
        reaper.ImGui_Text(ctx, cfg_dwn.preview_data.title)
        reaper.ImGui_PopFont(ctx)
        reaper.ImGui_Separator(ctx)
        reaper.ImGui_Dummy(ctx, 0, 10)
        
        if reaper.ImGui_BeginChild(ctx, "preview_text_child", 0, -50, 1) then
            reaper.ImGui_TextWrapped(ctx, cfg_dwn.preview_data.content)
            reaper.ImGui_EndChild(ctx)
        end
        
        reaper.ImGui_Dummy(ctx, 0, 10)
        if reaper.ImGui_Button(ctx, "Import to Project", 150) then
            UTILS.import_subtitle_to_project(cfg_dwn.preview_data.content, cfg_dwn.preview_data.title)
            cfg_dwn.preview_data = nil
        end
        
        reaper.ImGui_SameLine(ctx)
        if reaper.ImGui_Button(ctx, "Close", 100) then
            cfg_dwn.preview_data = nil
        end
        
        reaper.ImGui_End(ctx)
    end
end

local function draw_inline_entry(ctx, title, meaning, title_size, meaning_size)
    local tokens = {}
    
    -- Title tokens
    for word in title:gmatch("%S+") do
        table.insert(tokens, { text = word, color = Style.colors.WordHighlight, size = title_size })
    end
    
    -- Separator token
    table.insert(tokens, { text = " —", color = Style.colors.MeaningText, size = meaning_size })
    
    -- Meaning tokens
    for word in meaning:gmatch("%S+") do
        table.insert(tokens, { text = word, color = Style.colors.MeaningText, size = meaning_size })
    end
    
    -- Calculate height difference for alignment
    local h_title, h_meaning = 0, 0
    if title_size > meaning_size then
        reaper.ImGui_PushFont(ctx, font_main, title_size)
        _, h_title = reaper.ImGui_CalcTextSize(ctx, "A")
        reaper.ImGui_PopFont(ctx)
        
        reaper.ImGui_PushFont(ctx, font_main, meaning_size)
        _, h_meaning = reaper.ImGui_CalcTextSize(ctx, "A")
        reaper.ImGui_PopFont(ctx)
    end
    local align_offset = math.max(0, h_title - h_meaning - 3) -- -3 for visual baseline correction
    
    local line_has_large_text = false 
    
    for i, token in ipairs(tokens) do
        -- Detect if current line has large text (Title)
        if token.size == title_size and title_size > meaning_size then
            line_has_large_text = true
        end

        -- 1. Speculatively attempt to stay on SameLine if not first item
        if i > 1 then
            reaper.ImGui_SameLine(ctx, 0, 0)
            reaper.ImGui_PushFont(ctx, font_main, token.size) 
            reaper.ImGui_Text(ctx, " ")
            reaper.ImGui_PopFont(ctx)
            reaper.ImGui_SameLine(ctx, 0, 0)
        else
            -- First item on a fresh block starts a new line logic
            line_has_large_text = (token.size == title_size and title_size > meaning_size)
        end
        
        -- 2. Measure word
        reaper.ImGui_PushFont(ctx, font_main, token.size)
        local w, h = reaper.ImGui_CalcTextSize(ctx, token.text)
        reaper.ImGui_PopFont(ctx)
        
        local avail_w = reaper.ImGui_GetContentRegionAvail(ctx)
        
        -- 3. Check fit
        if w > (avail_w - 5) then
            -- Force NewLine with correct font height context
            reaper.ImGui_PushFont(ctx, font_main, token.size)
            reaper.ImGui_NewLine(ctx)
            reaper.ImGui_PopFont(ctx)
            
            -- Reset line state
            if token.size == title_size and title_size > meaning_size then
                line_has_large_text = true
            else
                line_has_large_text = false
            end
        end
        
        -- 4. Align Calculation
        local current_y = reaper.ImGui_GetCursorPosY(ctx)
        local need_offset = (line_has_large_text and token.size == meaning_size)
        
        if need_offset then
             reaper.ImGui_SetCursorPosY(ctx, current_y + align_offset)
        end

        -- 5. Render
        reaper.ImGui_PushFont(ctx, font_main, token.size)
        reaper.ImGui_TextColored(ctx, token.color, token.text)
        reaper.ImGui_PopFont(ctx)
        
        if need_offset then
            reaper.ImGui_SetCursorPosY(ctx, current_y) -- Restore Y for next elements
        end
    end
    
    if line_has_large_text then
        local extra = title_size - meaning_size
        if extra > 0 then
            reaper.ImGui_Dummy(ctx, 0, extra)
        end
    end
    
    if line_has_large_text then
        local extra = title_size - meaning_size
        if extra > 0 then
           reaper.ImGui_SetCursorPosY(ctx, reaper.ImGui_GetCursorPosY(ctx) + extra)
        end
    end

    -- Separator
    -- 1. Padding BEFORE separator (Only for large types)
    if title_size > meaning_size then 
        reaper.ImGui_SetCursorPosY(ctx, reaper.ImGui_GetCursorPosY(ctx) + 15)
    else
        reaper.ImGui_SetCursorPosY(ctx, reaper.ImGui_GetCursorPosY(ctx) + 5)
    end
    
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Separator(), 0xFFFFFF0B) 
    reaper.ImGui_Separator(ctx)
    reaper.ImGui_PopStyleColor(ctx)
    
    -- 2. Padding AFTER separator 
    reaper.ImGui_SetCursorPosY(ctx, reaper.ImGui_GetCursorPosY(ctx) + 5)
end

local function draw_mini_player(ctx)
    if not cfg_glos.layout_has_player or not cfg_glos.current_preview_source then return end

    local ok_p, pos = reaper.CF_Preview_GetValue(cfg_glos.current_preview_source, "D_POSITION")
    local ok_l, len = reaper.CF_Preview_GetValue(cfg_glos.current_preview_source, "D_LENGTH")
    local ok_pause, is_paused = reaper.CF_Preview_GetValue(cfg_glos.current_preview_source, "B_PAUSE")
    
    -- Check if playback has finished
    if not cfg_glos.current_preview_paused and ok_p and ok_l and pos >= len - 0.1 then
        -- Playback finished, auto-pause at the end
        cfg_glos.current_preview_pause_pos = 0  -- Reset to beginning for replay
        cfg_glos.current_preview_length = len
        if reaper.CF_Preview_Stop then
            reaper.CF_Preview_Stop(cfg_glos.current_preview_source)
        end
        cfg_glos.current_preview_paused = true
    end
    
    -- Use saved values when paused
    if cfg_glos.current_preview_paused then
        pos = cfg_glos.current_preview_pause_pos
        len = cfg_glos.current_preview_length
    end

    reaper.ImGui_Separator(ctx)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ChildBg(), 0x222222FF)
    
    -- Height 70
    if reaper.ImGui_BeginChild(ctx, "mini_player_ui", 0, 70, 1, reaper.ImGui_WindowFlags_NoScrollbar()) then
        -- Left column: Play/Pause button
        local play_icon = cfg_glos.current_preview_paused and "▶" or "Ⅱ"
        reaper.ImGui_PushFont(ctx, font_main, 22)
        reaper.ImGui_SetCursorPosY(ctx, 15) -- Center 40px button in 70px height child
        if reaper.ImGui_Button(ctx, play_icon .. "##playpause", 40, 40) then
            if cfg_glos.current_preview_paused then
                -- Resume: recreate preview from file and seek to saved position
                if reaper.PCM_Source_CreateFromFile and reaper.CF_CreatePreview then
                    local source = reaper.PCM_Source_CreateFromFile(cfg_glos.current_preview_file)
                    cfg_glos.current_preview_source = reaper.CF_CreatePreview(source)
                    if cfg_glos.current_preview_pause_pos > 0 then
                        reaper.CF_Preview_SetValue(cfg_glos.current_preview_source, "D_POSITION", cfg_glos.current_preview_pause_pos)
                    end
                    if reaper.CF_Preview_Play then
                        reaper.CF_Preview_Play(cfg_glos.current_preview_source)
                    end
                end
                cfg_glos.current_preview_paused = false
            else
                -- Pause: save position, length and stop preview
                cfg_glos.current_preview_pause_pos = pos or 0
                cfg_glos.current_preview_length = len or 0
                if reaper.CF_Preview_Stop then
                    reaper.CF_Preview_Stop(cfg_glos.current_preview_source)
                end
                cfg_glos.current_preview_paused = true
            end
        end
        reaper.ImGui_PopFont(ctx)
        
        -- Right column: Name, Progress, Timing (always show, even when paused)
        reaper.ImGui_SameLine(ctx, 0, 14)  -- Add 14px spacing from play button
        reaper.ImGui_SetCursorPosY(ctx, 16) -- Start of right column
        
        local start_right_y = reaper.ImGui_GetCursorPosY(ctx)
        reaper.ImGui_BeginGroup(ctx)
            
        -- Name row with timing at the end
        reaper.ImGui_PushFont(ctx, font_main, 13)
        local time_str = string.format("%s / %s", UTILS.format_time(pos), UTILS.format_time(len))
        local time_w = reaper.ImGui_CalcTextSize(ctx, time_str)
        local avail_row_w = reaper.ImGui_GetContentRegionAvail(ctx) - 32 -- Space for 23px button + margin
        local max_name_width = avail_row_w - time_w - 15 -- Gap between name and time
        local name_width = reaper.ImGui_CalcTextSize(ctx, cfg_glos.current_preview_name)
        
        if name_width > max_name_width then
            -- Truncate and add ellipsis
            local truncated = cfg_glos.current_preview_name
            while reaper.ImGui_CalcTextSize(ctx, truncated .. "...") > max_name_width and #truncated > 0 do
                truncated = truncated:sub(1, -2)
            end
            reaper.ImGui_Text(ctx, truncated .. "...")
        else
            reaper.ImGui_Text(ctx, cfg_glos.current_preview_name)
        end
        
        reaper.ImGui_SameLine(ctx, avail_row_w - time_w)
        reaper.ImGui_TextColored(ctx, 0xAAAAAAFF, time_str)
        reaper.ImGui_PopFont(ctx)
        -- Progress bar (clickable for seeking)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PlotHistogram(), 0x50C850AA)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), 0x333333FF)
        local progress = (len and len > 0) and pos/len or 0
        local avail_bar_w = avail_row_w
        
        -- Make progress bar interactive
        local cursor_x, cursor_y = reaper.ImGui_GetCursorScreenPos(ctx)
        reaper.ImGui_ProgressBar(ctx, progress, avail_bar_w, 6, "")
        
        -- Check if progress bar was clicked
        if reaper.ImGui_IsItemClicked(ctx, 0) then
            local mouse_x, mouse_y = reaper.ImGui_GetMousePos(ctx)
            local click_pos = (mouse_x - cursor_x) / avail_bar_w
            click_pos = math.max(0, math.min(1, click_pos))
            local new_time = click_pos * len
            
            if cfg_glos.current_preview_paused then
                -- When paused, just update the saved position
                cfg_glos.current_preview_pause_pos = new_time
            else
                -- When playing, seek the preview
                if cfg_glos.current_preview_source then
                    reaper.CF_Preview_SetValue(cfg_glos.current_preview_source, "D_POSITION", new_time)
                end
            end
        end
        
        reaper.ImGui_PopStyleColor(ctx, 2)
        reaper.ImGui_EndGroup(ctx)
        
        -- Close button aligned with name row
        reaper.ImGui_SameLine(ctx, reaper.ImGui_GetWindowWidth(ctx) - 32)
        reaper.ImGui_SetCursorPosY(ctx, start_right_y - 3)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), C_BTN_CLOSE)
        if reaper.ImGui_Button(ctx, "✕", 23, 23) then
            UTILS.stop_preview()
        end
        reaper.ImGui_PopStyleColor(ctx)

        reaper.ImGui_EndChild(ctx)
    end
    reaper.ImGui_PopStyleColor(ctx)
end

local function RenderTab_Reference()
    local ref_flags = (cfg.restore_tab and cfg.last_tab == 0) and reaper.ImGui_TabItemFlags_SetSelected() or 0
    if reaper.ImGui_BeginTabItem(ctx, "Довідник", nil, ref_flags) then
        if not cfg.restore_tab and cfg.last_tab ~= 0 then
            cfg.last_tab = 0
            reaper.SetExtState("Subass_Dictionary", "last_tab", "0", true)
            UTILS.stop_preview()
        end
        reaper.ImGui_PopFont(ctx)
        reaper.ImGui_PopStyleVar(ctx)

        -- Search inside Tab
        reaper.ImGui_SetNextItemWidth(ctx, -5)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), 9, 8) -- Increased padding for taller input
        local changed, new_filter = reaper.ImGui_InputTextWithHint(ctx, '##search_ref', "Пошук у довіднику...", cfg_ref.ref_filter)
        if changed then cfg_ref.ref_filter = new_filter end
        if cfg_ref.ref_filter ~= cfg_ref.last_filter then UTILS.update_search_cache(cfg_ref.ref_filter) end
        reaper.ImGui_PopStyleVar(ctx) -- Pop FramePadding for search bar
        reaper.ImGui_Separator(ctx)
        reaper.ImGui_Dummy(ctx, 0, 5)
        -- Content
        local child_h = cfg_glos.layout_has_player and -82 or -5
        if reaper.ImGui_BeginChild(ctx, "content_reference", 0, child_h) then
            for _, cat in ipairs(cfg_ref.cached_results) do
                local header_flags = 0
                local header_name = string.format("%s (%d)###%s", cat.name, #cat.entries, cat.name)
                
                reaper.ImGui_PushFont(ctx, font_main, 16)
                local header_open = reaper.ImGui_CollapsingHeader( ctx, header_name, header_flags )
                reaper.ImGui_PopFont(ctx)
                
                if header_open then
                    reaper.ImGui_Indent(ctx, 29)
                    reaper.ImGui_Dummy(ctx, 0, 5)
                    for _, entry in ipairs(cat.entries) do
                        if cat.name == "Асиміляція" or cat.name == "Відмінки" then
                            draw_inline_entry(ctx, entry.word, entry.meaning, 18, 18)
                        else
                            draw_inline_entry(ctx, entry.word, entry.meaning, 30, 16)
                        end
                    end
                    reaper.ImGui_Dummy(ctx, 0, 10)
                    reaper.ImGui_Unindent(ctx, 29)
                end
            end
            reaper.ImGui_EndChild(ctx)
        end
        reaper.ImGui_EndTabItem(ctx)
        reaper.ImGui_PushFont(ctx, font_tabs, 17)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), 9, 6)
    end
end

local function RenderTab_Glossary()
    local glos_flags = (cfg.restore_tab and cfg.last_tab == 1) and reaper.ImGui_TabItemFlags_SetSelected() or 0
    if reaper.ImGui_BeginTabItem(ctx, "Звуковий Глосарій", nil, glos_flags) then
        if not cfg.restore_tab and cfg.last_tab ~= 1 then
            cfg.last_tab = 1
            reaper.SetExtState("Subass_Dictionary", "last_tab", "1", true)
            UTILS.stop_preview()
        end
        reaper.ImGui_PopFont(ctx)
        reaper.ImGui_PopStyleVar(ctx)

        -- Search and Add on one line (Increased height)
        reaper.ImGui_SetNextItemWidth(ctx, -145)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), 9, 8) -- Increased padding for taller input
        local changed, new_filter = reaper.ImGui_InputTextWithHint(ctx, '##search_glos', "Пошук у глосарії...", cfg_glos.glos_filter)
        if changed then cfg_glos.glos_filter = new_filter end
        
        reaper.ImGui_SameLine(ctx)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), C_BTN_MEDIUM)
        if reaper.ImGui_Button(ctx, "Додати з REAPER", 135) then
            local new_entry = UTILS.add_from_reaper()
            if new_entry then
                cfg_glos.add_entry_pending = new_entry
                reaper.ImGui_OpenPopup(ctx, "GlossaryMetadata")
            end
        end
        reaper.ImGui_PopStyleColor(ctx)
        reaper.ImGui_PopStyleVar(ctx) -- Pop FramePadding for search/add bar
        -- Quick Tags
        local all_tags = {}
        local tag_map = {}
        for _, entry in ipairs(cfg_glos.glossary_data.entries) do
            for tag in entry.tags:gmatch("([^,]+)") do
                tag = tag:gsub("^%s+", ""):gsub("%s+$", "")
                if tag ~= "" and not tag_map[tag] then
                    tag_map[tag] = true
                    table.insert(all_tags, tag)
                end
            end
        end
        table.sort(all_tags)

        if #all_tags > 0 then
            reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(), 5, 5)
            reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), 6, 4) -- Slightly larger tag buttons
            
            for i, tag in ipairs(all_tags) do
                local is_active = cfg_glos.active_tags[tag]
                
                -- Style: Transparent bg with border if inactive, Filled if active
                if is_active then
                    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), C_BTN_MEDIUM)
                    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameBorderSize(), 0)
                else
                    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x00000000) -- Transparent
                    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(), C_BTN_MEDIUM)
                    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameBorderSize(), 1)
                end
                
                -- Calculate button width to check for wrap
                local button_w = reaper.ImGui_CalcTextSize(ctx, tag) + 12 + 10 -- + padding + spacing safety
                local avail_w = reaper.ImGui_GetContentRegionAvail(ctx)
                
                if i > 1 and button_w > avail_w then
                    reaper.ImGui_NewLine(ctx)
                end

                if reaper.ImGui_Button(ctx, tag .. "##tag") then
                    if is_active then
                        cfg_glos.active_tags[tag] = nil -- Toggle off
                    else
                        cfg_glos.active_tags[tag] = true -- Toggle on
                    end
                end
                
                if is_active then
                    reaper.ImGui_PopStyleColor(ctx, 1) -- Button
                    reaper.ImGui_PopStyleVar(ctx, 1)   -- BorderSize
                else
                    reaper.ImGui_PopStyleColor(ctx, 2) -- Button, Border
                    reaper.ImGui_PopStyleVar(ctx, 1)   -- BorderSize
                end
                
                reaper.ImGui_SameLine(ctx)
            end
            reaper.ImGui_NewLine(ctx)
            reaper.ImGui_PopStyleVar(ctx, 2) -- ItemSpacing, FramePadding
        end

        reaper.ImGui_Separator(ctx)
        reaper.ImGui_Dummy(ctx, 0, 5)

        local child_h = cfg_glos.layout_has_player and -82 or -5
        if reaper.ImGui_BeginChild(ctx, "content_glossary", 0, child_h) then
            -- Glossary List
            for i, entry in ipairs(cfg_glos.glossary_data.entries) do
                local match = true
                
                -- 1. Check text filter
                if cfg_glos.glos_filter ~= "" then
                    local s = utf8_lower(cfg_glos.glos_filter)
                    if not (utf8_lower(entry.name):find(s, 1, true) or utf8_lower(entry.tags):find(s, 1, true) or utf8_lower(entry.desc):find(s, 1, true)) then
                        match = false
                    end
                end
                        
                -- 2. Check tag filter (ALL selected tags must be present)
                if match then
                    for needed_tag, _ in pairs(cfg_glos.active_tags) do
                        local has_tag = false
                        for entry_tag in entry.tags:gmatch("([^,]+)") do
                            entry_tag = entry_tag:gsub("^%s+", ""):gsub("%s+$", "")
                            if entry_tag == needed_tag then
                                has_tag = true
                                break
                            end
                        end
                        if not has_tag then
                            match = false
                            break
                        end
                    end
                end

                if match then
                    -- Main Interaction Group
                    reaper.ImGui_BeginGroup(ctx)
                        
                    -- 1. Name & Playback (Top)
                    local play_icon = (cfg_glos.current_preview_name == entry.name and not cfg_glos.current_preview_paused) and "Ⅱ" or "▶"
                            
                    -- Play/Pause Logic (Extraction)
                    local function toggle_playback()
                        local full_path = data_path .. entry.filename
                        
                        -- If same file is playing: toggle pause
                        if cfg_glos.current_preview_name == entry.name and cfg_glos.current_preview_source then
                            if cfg_glos.current_preview_paused then
                                -- Resume
                                if reaper.PCM_Source_CreateFromFile and reaper.CF_CreatePreview then
                                    local source = reaper.PCM_Source_CreateFromFile(cfg_glos.current_preview_file)
                                    cfg_glos.current_preview_source = reaper.CF_CreatePreview(source)
                                    if cfg_glos.current_preview_pause_pos > 0 then
                                        reaper.CF_Preview_SetValue(cfg_glos.current_preview_source, "D_POSITION", cfg_glos.current_preview_pause_pos)
                                    end
                                    if reaper.CF_Preview_Play then reaper.CF_Preview_Play(cfg_glos.current_preview_source) end
                                end
                                cfg_glos.current_preview_paused = false
                            else
                                -- Pause
                                local ok_p, pos = reaper.CF_Preview_GetValue(cfg_glos.current_preview_source, "D_POSITION")
                                local ok_l, len = reaper.CF_Preview_GetValue(cfg_glos.current_preview_source, "D_LENGTH")
                                
                                cfg_glos.current_preview_pause_pos = pos or 0
                                cfg_glos.current_preview_length = len or 0
                                if reaper.CF_Preview_Stop then reaper.CF_Preview_Stop(cfg_glos.current_preview_source) end
                                cfg_glos.current_preview_paused = true
                            end
                        else
                            -- Play new file
                            cfg_glos.current_preview_name = entry.name
                            cfg_glos.current_preview_file = full_path
                            cfg_glos.current_preview_paused = false
                            cfg_glos.current_preview_pause_pos = 0
                            if cfg_glos.current_preview_source then
                                if reaper.CF_Preview_Stop then reaper.CF_Preview_Stop(cfg_glos.current_preview_source) end
                            end
                            if reaper.PCM_Source_CreateFromFile and reaper.CF_CreatePreview then
                                local source = reaper.PCM_Source_CreateFromFile(full_path)
                                cfg_glos.current_preview_source = reaper.CF_CreatePreview(source)
                                if reaper.CF_Preview_Play then reaper.CF_Preview_Play(cfg_glos.current_preview_source) end
                            end
                        end
                    end

                    -- 0. Layout Requirements & Widths
                    local avail_w = reaper.ImGui_GetContentRegionAvail(ctx)
                    local raw_tags = entry.tags or ""
                    local tag_str = raw_tags:gsub(",", ", ")
                    local is_ultra = (tag_str == "") and (not entry.desc or entry.desc == "")
                    
                    reaper.ImGui_PushFont(ctx, font_main, 15)
                    local insert_btn_w = reaper.ImGui_CalcTextSize(ctx, "Вставити в проєкт")
                    reaper.ImGui_PopFont(ctx)
                    local actions_btn_w = 30
                    local total_btns_w = insert_btn_w + actions_btn_w + 8

                    reaper.ImGui_PushFont(ctx, font_main, 13)
                    local tag_w = (tag_str ~= "") and reaper.ImGui_CalcTextSize(ctx, tag_str) or 0
                    reaper.ImGui_PopFont(ctx)
                    
                    local right_margin_w = 0
                    if is_ultra then
                        right_margin_w = total_btns_w
                    else
                        if tag_w > 0 then right_margin_w = right_margin_w + tag_w end
                    end

                    -- Fixed width Play Button
                    local entry_start_y = reaper.ImGui_GetCursorPosY(ctx)
                    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x4B824B50)
                    if reaper.ImGui_Button(ctx, play_icon .. "##playbtn"..i, 30, 30) then
                        toggle_playback()
                    end
                    reaper.ImGui_PopStyleColor(ctx)
                    
                    -- Clickable Name with Truncation
                    reaper.ImGui_SameLine(ctx)
                    reaper.ImGui_SetCursorPosY(ctx, entry_start_y + 3) -- Adjusted for 30px button height
                    local name_avail_w = math.max(50, avail_w - 30 - 8 - (right_margin_w > 0 and (right_margin_w + 15) or 0))
                    
                    -- 1.1 Calculate/Lazy-load Duration
                    if not entry.duration then
                        local full_path = data_path .. (entry.filename or "")
                        if entry.filename and entry.filename ~= "" then
                            local src = reaper.PCM_Source_CreateFromFile(full_path)
                            if src then
                                entry.duration = reaper.GetMediaSourceLength(src)
                                reaper.PCM_Source_Destroy(src)
                                UTILS.save_glossary()
                            end
                        end
                    end
                    
                    local base_name = (entry.name or "Unnamed"):gsub("%s+$", "")
                    local display_name = base_name
                    reaper.ImGui_PushFont(ctx, font_main, 18)
                    local name_w = reaper.ImGui_CalcTextSize(ctx, display_name)
                    
                    if name_w > name_avail_w then
                        local truncated = ""
                        -- Safe UTF-8 iteration
                        local ok, f, s, i = pcall(utf8.codes, base_name)
                        if ok then
                            for _, code in f, s, i do
                                local char = utf8.char(code)
                                if reaper.ImGui_CalcTextSize(ctx, truncated .. char .. "...") > name_avail_w then
                                    display_name = truncated .. "..."
                                    break
                                end
                                truncated = truncated .. char
                            end
                        else
                            display_name = base_name:sub(1, 10) .. "..."
                        end
                    end
                    
                    -- 1.2 Rendering Title Row
                    reaper.ImGui_TextColored(ctx, C_BTN_OK, display_name)
                    if reaper.ImGui_IsItemClicked(ctx, 0) then toggle_playback() end
                    reaper.ImGui_PopFont(ctx)

                    if is_ultra then
                        -- ULTRA-COMPACT: Name, Buttons all on ONE line
                        reaper.ImGui_SameLine(ctx, avail_w - right_margin_w)
                        reaper.ImGui_BeginGroup(ctx)
                            -- Action Buttons - Centered vertically
                            reaper.ImGui_SetCursorPosY(ctx, entry_start_y + 6) -- Match title offset
                            if reaper.ImGui_Button(ctx, "Вставити в проєкт##"..i, insert_btn_w) then
                                local full_path = data_path .. entry.filename
                                local track = reaper.GetSelectedTrack(0, 0)
                                if track then
                                    local cursor_pos = reaper.GetCursorPosition()
                                    reaper.InsertMedia(full_path, 0)
                                    local new_item = reaper.GetSelectedMediaItem(0, 0)
                                    if new_item then
                                        reaper.MoveMediaItemToTrack(new_item, track)
                                        reaper.SetMediaItemInfo_Value(new_item, "D_POSITION", cursor_pos)
                                        reaper.UpdateArrange()
                                    end
                                else
                                    reaper.MB("Будь ласка, виберіть трек для вставки.", "Помилка", 0)
                                end
                            end
                            reaper.ImGui_SameLine(ctx)
                            reaper.ImGui_SetCursorPosY(ctx, entry_start_y + 6)
                            if reaper.ImGui_Button(ctx, "⋮##btn"..i, actions_btn_w) then
                                reaper.ImGui_OpenPopup(ctx, "glossary_actions_popup"..i)
                            end
                        reaper.ImGui_EndGroup(ctx)
                    else
                        -- STANDARD: Multi-line layout
                        -- Tags Row (Right Aligned on title row) - Centered vertically
                        if right_margin_w > 0 then
                            reaper.ImGui_SameLine(ctx)
                            reaper.ImGui_SetCursorPosX(ctx, avail_w - right_margin_w)
                            reaper.ImGui_SetCursorPosY(ctx, entry_start_y + 7) -- Center font 13 in 30px height
                            reaper.ImGui_PushFont(ctx, font_main, 13)
                            
                            if tag_w > 0 then
                                reaper.ImGui_TextColored(ctx, 0xAAAAAAFF, tag_str)
                            end
                            
                            reaper.ImGui_PopFont(ctx)
                        end
                        
                        reaper.ImGui_SetCursorPosY(ctx, entry_start_y + 32) -- Bottom of the 30px button + gap
                        reaper.ImGui_Dummy(ctx, 0, 4)
                        
                        -- Description & Actions Row
                        if entry.desc ~= "" then
                            reaper.ImGui_PushTextWrapPos(ctx, avail_w - total_btns_w - 15)
                            reaper.ImGui_Text(ctx, entry.desc)
                            reaper.ImGui_PopTextWrapPos(ctx)
                            reaper.ImGui_SameLine(ctx, avail_w - total_btns_w)
                        else
                            reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + avail_w - total_btns_w)
                        end
                        
                        reaper.ImGui_BeginGroup(ctx)
                            local insert_label = "Вставити в проєкт##"..i
                            if reaper.ImGui_Button(ctx, insert_label, insert_btn_w) then
                                local full_path = data_path .. entry.filename
                                local track = reaper.GetSelectedTrack(0, 0)
                                if track then
                                    local cursor_pos = reaper.GetCursorPosition()
                                    reaper.InsertMedia(full_path, 0)
                                    local new_item = reaper.GetSelectedMediaItem(0, 0)
                                    if new_item then
                                        reaper.MoveMediaItemToTrack(new_item, track)
                                        reaper.SetMediaItemInfo_Value(new_item, "D_POSITION", cursor_pos)
                                        reaper.UpdateArrange()
                                    end
                                else
                                    reaper.MB("Будь ласка, виберіть трек для вставки.", "Помилка", 0)
                                end
                            end
                            
                            reaper.ImGui_SameLine(ctx)
                            if reaper.ImGui_Button(ctx, "⋮##btn"..i, actions_btn_w) then
                                reaper.ImGui_OpenPopup(ctx, "glossary_actions_popup"..i)
                            end
                        reaper.ImGui_EndGroup(ctx)
                    end

                    -- Common Actions Popup
                    if reaper.ImGui_BeginPopup(ctx, "glossary_actions_popup"..i) then
                        if reaper.ImGui_Selectable(ctx, "✎ Редагувати") then
                            cfg_glos.edit_entry_idx = i
                            cfg_glos.edit_entry_data = {
                                name = entry.name,
                                tags = entry.tags,
                                desc = entry.desc
                            }
                            cfg_glos.open_edit_popup = true
                        end
                        
                        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xFF5050FF)
                        if reaper.ImGui_Selectable(ctx, "× Видалити") then
                            if reaper.MB("Видалити цей звук?", "Підтвердження", 1) == 1 then
                                os.remove(data_path .. entry.filename)
                                table.remove(cfg_glos.glossary_data.entries, i)
                                UTILS.save_glossary()
                            end
                        end
                        reaper.ImGui_PopStyleColor(ctx)
                        reaper.ImGui_EndPopup(ctx)
                    end
                        
                        reaper.ImGui_EndGroup(ctx)
                        
                        reaper.ImGui_Dummy(ctx, 0, 3)
                        reaper.ImGui_Separator(ctx)
                        reaper.ImGui_Dummy(ctx, 0, 2)
                    end
                end

                reaper.ImGui_EndChild(ctx) -- Close glossary list child

                -- Modals (Moved outside child)
                if cfg_glos.open_edit_popup then
                    reaper.ImGui_OpenPopup(ctx, "EditGlossary")
                    cfg_glos.open_edit_popup = false
                end
            if reaper.ImGui_BeginPopupModal(ctx, "GlossaryMetadata", nil, reaper.ImGui_WindowFlags_AlwaysAutoResize()) then
                reaper.ImGui_Text(ctx, "Налаштування нового звуку:")
                reaper.ImGui_Dummy(ctx, 0, 5)
                
                _, cfg_glos.add_entry_pending.name = reaper.ImGui_InputText(ctx, "Назва", cfg_glos.add_entry_pending.name)
                _, cfg_glos.add_entry_pending.tags = reaper.ImGui_InputText(ctx, "Теги (через кому)", cfg_glos.add_entry_pending.tags)
                _, cfg_glos.add_entry_pending.desc = reaper.ImGui_InputTextMultiline(ctx, "Опис", cfg_glos.add_entry_pending.desc, 300, 100)
                
                reaper.ImGui_Dummy(ctx, 0, 10)
                if reaper.ImGui_Button(ctx, "Зберегти", 120) then
                    table.insert(cfg_glos.glossary_data.entries, cfg_glos.add_entry_pending)
                    UTILS.save_glossary()
                    cfg_glos.add_entry_pending = nil
                    reaper.ImGui_CloseCurrentPopup(ctx)
                end
                reaper.ImGui_SameLine(ctx)
                if reaper.ImGui_Button(ctx, "Скасувати", 120) then
                    os.remove(data_path .. cfg_glos.add_entry_pending.filename)
                    cfg_glos.add_entry_pending = nil
                    reaper.ImGui_CloseCurrentPopup(ctx)
                end
                reaper.ImGui_EndPopup(ctx)
            end

            if reaper.ImGui_BeginPopupModal(ctx, "EditGlossary", nil, reaper.ImGui_WindowFlags_AlwaysAutoResize()) then
                reaper.ImGui_Text(ctx, "Редагування:")
                reaper.ImGui_Dummy(ctx, 0, 5)
                
                _, cfg_glos.edit_entry_data.name = reaper.ImGui_InputText(ctx, "Назва", cfg_glos.edit_entry_data.name)
                _, cfg_glos.edit_entry_data.tags = reaper.ImGui_InputText(ctx, "Теги", cfg_glos.edit_entry_data.tags)
                _, cfg_glos.edit_entry_data.desc = reaper.ImGui_InputTextMultiline(ctx, "Опис", cfg_glos.edit_entry_data.desc, 300, 100)
                
                reaper.ImGui_Dummy(ctx, 0, 10)
                if reaper.ImGui_Button(ctx, "Зберегти", 120) then
                    cfg_glos.glossary_data.entries[cfg_glos.edit_entry_idx].name = cfg_glos.edit_entry_data.name
                    cfg_glos.glossary_data.entries[cfg_glos.edit_entry_idx].tags = cfg_glos.edit_entry_data.tags
                    cfg_glos.glossary_data.entries[cfg_glos.edit_entry_idx].desc = cfg_glos.edit_entry_data.desc
                    UTILS.save_glossary()
                    reaper.ImGui_CloseCurrentPopup(ctx)
                end
                reaper.ImGui_SameLine(ctx)
                if reaper.ImGui_Button(ctx, "Скасувати", 120) then
                    reaper.ImGui_CloseCurrentPopup(ctx)
                end
                reaper.ImGui_EndPopup(ctx)
            end
        end
        reaper.ImGui_EndTabItem(ctx)
        reaper.ImGui_PushFont(ctx, font_tabs, 17)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), 9, 6)
    end
end

local function RenderTab_Dictionaries()
    local dict_flags = (cfg.restore_tab and cfg.last_tab == 2) and reaper.ImGui_TabItemFlags_SetSelected() or 0
    if reaper.ImGui_BeginTabItem(ctx, "Словники", nil, dict_flags) then
        if not cfg.restore_tab and cfg.last_tab ~= 2 then
            cfg.last_tab = 2
            reaper.SetExtState("Subass_Dictionary", "last_tab", "2", true)
            UTILS.stop_preview()
        end
        reaper.ImGui_PopFont(ctx)
        reaper.ImGui_PopStyleVar(ctx)

        local avail_h = cfg_glos.layout_has_player and -82 or -5
                
        -- Split view Left: Dictionary List
        if reaper.ImGui_BeginChild(ctx, "dict_split_left", 200, avail_h, 1) then
            reaper.ImGui_Text(ctx, "Користувацькі словники")
            reaper.ImGui_Separator(ctx)
            reaper.ImGui_Dummy(ctx, 0, 5)
            
            if reaper.ImGui_Button(ctx, "Створити новий", -1) then
                reaper.ImGui_OpenPopup(ctx, "new_dict_popup")
            end
            if reaper.ImGui_Button(ctx, "Імпорт з .csv", -1) then
                UTILS.import_dict_csv()
            end
            reaper.ImGui_Dummy(ctx, 0, 5)
            
            if reaper.ImGui_BeginPopup(ctx, "new_dict_popup") then
                reaper.ImGui_Text(ctx, "Назва нового словника:")
                _, cfg_dict.new_dict_name = reaper.ImGui_InputText(ctx, "##new_dict_name", cfg_dict.new_dict_name)
                if reaper.ImGui_Button(ctx, "Створити", 130) then
                    local trimmed_name = (cfg_dict.new_dict_name or ""):match("^%s*(.-)%s*$")
                    if trimmed_name and trimmed_name ~= "" then
                        if UTILS.check_dict_name_exists(trimmed_name) then
                            reaper.MB("Словник з такою назвою вже існує!", "Помилка", 0)
                        else
                            table.insert(cfg_dict.udd.dictionaries, 1, {
                                id = "dict_" .. os.time(),
                                name = trimmed_name,
                                entries = {}
                            })
                            UTILS.save_user_dicts()
                            UTILS.update_last_selected_dict(1)
                            cfg_dict.new_dict_name = ""
                            reaper.ImGui_CloseCurrentPopup(ctx)
                        end
                    end
                end
                reaper.ImGui_EndPopup(ctx)
            end

            if cfg_dict.rename_dict_idx then
                reaper.ImGui_OpenPopup(ctx, "rename_dict_popup")
            end

            if reaper.ImGui_BeginPopup(ctx, "rename_dict_popup") then
                reaper.ImGui_Text(ctx, "Перейменувати словник:")
                _, cfg_dict.rename_dict_name = reaper.ImGui_InputText(ctx, "##rename_dict_name", cfg_dict.rename_dict_name)
                if reaper.ImGui_Button(ctx, "Зберегти", 100) then
                    local trimmed_name = (cfg_dict.rename_dict_name or ""):match("^%s*(.-)%s*$")
                    if cfg_dict.rename_dict_idx and trimmed_name and trimmed_name ~= "" and cfg_dict.udd.dictionaries[cfg_dict.rename_dict_idx] then
                        if UTILS.check_dict_name_exists(trimmed_name, cfg_dict.rename_dict_idx) then
                            reaper.MB("Словник з такою назвою вже існує!", "Помилка", 0)
                        else
                            cfg_dict.udd.dictionaries[cfg_dict.rename_dict_idx].name = trimmed_name
                            UTILS.save_user_dicts()
                            UTILS.move_dict_to_top(cfg_dict.rename_dict_idx)
                            cfg_dict.rename_dict_idx = nil
                            cfg_dict.rename_dict_name = ""
                            reaper.ImGui_CloseCurrentPopup(ctx)
                        end
                    end
                end
                reaper.ImGui_SameLine(ctx)
                if reaper.ImGui_Button(ctx, "Скасувати", 100) then
                    cfg_dict.rename_dict_idx = nil
                    cfg_dict.rename_dict_name = ""
                    reaper.ImGui_CloseCurrentPopup(ctx)
                end
                reaper.ImGui_EndPopup(ctx)
            end
                    
            reaper.ImGui_Dummy(ctx, 0, 2)
            reaper.ImGui_Separator(ctx)

            -- Pre-calculate list width for truncation
            local list_w = reaper.ImGui_GetContentRegionAvail(ctx) - 5
            
            for i, dict in ipairs(cfg_dict.udd.dictionaries) do
                local is_selected = (cfg_dict.sd_inx == i)
                
                -- Truncate name if it's too long
                local display_name = dict.name or "Unnamed"
                local name_w = reaper.ImGui_CalcTextSize(ctx, display_name)
                
                if name_w > list_w then
                    local truncated = ""
                    local ok, f, s, idx = pcall(function() return utf8.codes(display_name) end)
                    if ok and f then
                        for _, code in f, s, idx do
                            local char = utf8.char(code)
                            if reaper.ImGui_CalcTextSize(ctx, truncated .. char .. "...") > list_w then
                                display_name = truncated .. "..."
                                break
                            end
                            truncated = truncated .. char
                        end
                    else
                        display_name = display_name:sub(1, 15) .. "..."
                    end
                end
                
                if reaper.ImGui_Selectable(ctx, display_name .. "##dict" .. i, is_selected) then
                    if cfg_dict.sd_inx ~= i then cfg_dict.dict_filter = "" end -- Clear filter on dict switch
                    UTILS.update_last_selected_dict(i)
                end
                if reaper.ImGui_IsItemHovered(ctx) and display_name ~= dict.name then
                    reaper.ImGui_SetTooltip(ctx, dict.name) -- Show full name on hover if truncated
                end
                if reaper.ImGui_IsItemClicked(ctx, 1) then -- Right click
                    reaper.ImGui_OpenPopup(ctx, "dict_context_" .. i)
                end
                reaper.ImGui_Separator(ctx)
                
                if reaper.ImGui_BeginPopup(ctx, "dict_context_" .. i) then
                    if reaper.ImGui_Selectable(ctx, "Перейменувати") then
                        cfg_dict.rename_dict_idx = i
                        cfg_dict.rename_dict_name = dict.name
                    end
                    if reaper.ImGui_Selectable(ctx, "Експорт у .csv") then
                        UTILS.export_dict_csv(dict)
                    end
                    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xFF5050FF)
                    if reaper.ImGui_Selectable(ctx, "Видалити") then
                        local confirm = true
                        if #dict.entries > 0 then
                            local resp = reaper.MB("Словник '" .. dict.name .. "' містить записів: " .. #dict.entries .. ".\nВи впевнені, що хочете видалити його?", "Підтвердження видалення", 4) -- 4 = Yes/No
                            if resp ~= 6 then confirm = false end -- 6 = Yes
                        end
                        
                        if confirm then
                            table.remove(cfg_dict.udd.dictionaries, i)
                            UTILS.save_user_dicts()
                            if cfg_dict.sd_inx == i then
                                UTILS.update_last_selected_dict(cfg_dict.udd.dictionaries[1] and 1 or nil)
                            elseif cfg_dict.sd_inx and cfg_dict.sd_inx > i then
                                UTILS.update_last_selected_dict(cfg_dict.sd_inx - 1)
                            end
                        end
                    end
                    reaper.ImGui_PopStyleColor(ctx)
                    reaper.ImGui_EndPopup(ctx)
                end
            end
                    
            reaper.ImGui_EndChild(ctx)
        end
                
        reaper.ImGui_SameLine(ctx)
        
        -- Split view Right: Editor
        if reaper.ImGui_BeginChild(ctx, "dict_split_right", 0, avail_h, 1) then
            if cfg_dict.sd_inx and cfg_dict.udd.dictionaries[cfg_dict.sd_inx] then
                local active_dict = cfg_dict.udd.dictionaries[cfg_dict.sd_inx]
                
                -- Truncate header dictionary name
                local header_prefix = "Словник: "
                local header_prefix_w = reaper.ImGui_CalcTextSize(ctx, header_prefix)
                -- Available width minus the button space (110 button + 10 padding roughly)
                local header_avail_w = reaper.ImGui_GetContentRegionAvail(ctx) - 120 - header_prefix_w
                
                local header_dict_name = active_dict.name or "Unnamed"
                local header_dict_w = reaper.ImGui_CalcTextSize(ctx, header_dict_name)
                
                if header_dict_w > header_avail_w and header_avail_w > 0 then
                    local truncated = ""
                    local ok, f, s, idx = pcall(function() return utf8.codes(header_dict_name) end)
                    if ok and f then
                        for _, code in f, s, idx do
                            local char = utf8.char(code)
                            if reaper.ImGui_CalcTextSize(ctx, truncated .. char .. "...") > header_avail_w then
                                header_dict_name = truncated .. "..."
                                break
                            end
                            truncated = truncated .. char
                        end
                    else
                        header_dict_name = header_dict_name:sub(1, 15) .. "..."
                    end
                end
                
                reaper.ImGui_Text(ctx, header_prefix .. header_dict_name)
                if header_dict_name ~= active_dict.name and reaper.ImGui_IsItemHovered(ctx) then
                    reaper.ImGui_SetTooltip(ctx, active_dict.name)
                end
                
                reaper.ImGui_SameLine(ctx, reaper.ImGui_GetContentRegionAvail(ctx) - 100)
                if reaper.ImGui_Button(ctx, "+ Додати запис", 110) then
                    local nid = active_dict.next_id or (#active_dict.entries + 1)
                    table.insert(active_dict.entries, 1, {uid = nid, word = "", replacement = "", comment = ""})
                    active_dict.next_id = nid + 1
                    cfg_dict.dict_filter = "" -- Clear filter on add
                    UTILS.save_user_dicts()
                    UTILS.move_dict_to_top(cfg_dict.sd_inx)
                end
                reaper.ImGui_Separator(ctx)
                
                -- Search Filter
                reaper.ImGui_SetNextItemWidth(ctx, -5)
                local filter_changed, new_filter = reaper.ImGui_InputTextWithHint(ctx, "##dict_filter_input", "Пошук у словнику...", cfg_dict.dict_filter)
                if filter_changed then 
                    cfg_dict.dict_filter = new_filter 
                    cfg_dict.entry_selection = {} -- Clear selection on filter change
                end
                
                reaper.ImGui_Dummy(ctx, 0, 5)
                
                local table_flags = reaper.ImGui_TableFlags_Borders() | reaper.ImGui_TableFlags_RowBg() | reaper.ImGui_TableFlags_Resizable() | reaper.ImGui_TableFlags_ScrollY() | reaper.ImGui_TableFlags_Sortable()
                if reaper.ImGui_BeginTable(ctx, 'dict_entries_table', 5, table_flags) then
                    reaper.ImGui_TableSetupScrollFreeze(ctx, 0, 1)
                    reaper.ImGui_TableSetupColumn(ctx, "#", reaper.ImGui_TableColumnFlags_WidthFixed() | reaper.ImGui_TableColumnFlags_DefaultSort(), 30)
                    reaper.ImGui_TableSetupColumn(ctx, "Слово", reaper.ImGui_TableColumnFlags_WidthStretch(), 1)
                    reaper.ImGui_TableSetupColumn(ctx, "Заміна (в суфлер)", reaper.ImGui_TableColumnFlags_WidthStretch(), 1)
                    reaper.ImGui_TableSetupColumn(ctx, "Коментар", reaper.ImGui_TableColumnFlags_WidthStretch(), 1)
                    reaper.ImGui_TableSetupColumn(ctx, "Дія", reaper.ImGui_TableColumnFlags_WidthFixed() | reaper.ImGui_TableColumnFlags_NoSort(), 30)
                    reaper.ImGui_TableHeadersRow(ctx)

                    -- Handle Sorting
                    if reaper.ImGui_TableNeedSort(ctx) then
                        local ok, col_idx, user_id, sort_dir = reaper.ImGui_TableGetColumnSortSpecs(ctx, 0)
                        
                        if ok then
                            table.sort(active_dict.entries, function(a, b)
                                local val_a, val_b
                                if col_idx == 0 then
                                    val_a = a.uid or 0
                                    val_b = b.uid or 0
                                elseif col_idx == 1 then
                                    val_a = (a.word or ""):lower()
                                    val_b = (b.word or ""):lower()
                                elseif col_idx == 2 then
                                    val_a = (a.replacement or ""):lower()
                                    val_b = (b.replacement or ""):lower()
                                elseif col_idx == 3 then
                                    val_a = (a.comment or ""):lower()
                                    val_b = (b.comment or ""):lower()
                                end
                                
                                if val_a == nil or val_b == nil then return false end
                                
                                if sort_dir == 1 then -- Ascending
                                    return val_a < val_b
                                else -- Descending
                                    return val_a > val_b
                                end
                            end)
                            UTILS.save_user_dicts() -- Save the new sorted order
                        end
                    end

                    local to_remove = nil
                    local filter_lower = utf8_lower(cfg_dict.dict_filter)
                    local open_entry_popup = false
                    
                    for e_i, entry in ipairs(active_dict.entries) do
                        -- 0. Safety Guard: Ensure UID exists (Fix for "table index is nil" crash)
                        if not entry.uid then
                            entry.uid = active_dict.next_id or (#active_dict.entries + 100)
                            active_dict.next_id = entry.uid + 1
                            UTILS.save_user_dicts()
                        end

                        -- Filtering logic
                        if filter_lower ~= "" then
                            local match = false
                            local w_lower = utf8_lower(entry.word or "")
                            local r_lower = utf8_lower(entry.replacement or "")
                            local c_lower = utf8_lower(entry.comment or "")
                            
                            if w_lower:find(filter_lower, 1, true) or 
                               r_lower:find(filter_lower, 1, true) or 
                               c_lower:find(filter_lower, 1, true) then
                                match = true
                            end
                            
                            if not match then goto next_entry end
                        end

                        reaper.ImGui_TableNextRow(ctx)
                        reaper.ImGui_PushID(ctx, "entry_" .. e_i)

                        local row_selected = cfg_dict.entry_selection[entry.uid] == true
                        
                        -- 1. Highlighting Row (Visual)
                        if row_selected then
                            reaper.ImGui_TableSetBgColor(ctx, reaper.ImGui_TableBgTarget_RowBg0(), 0x22AA2244, -1)
                        end

                        -- 2. Selection Hit Area (Logical)
                        reaper.ImGui_TableSetColumnIndex(ctx, 0)
                        local row_y = reaper.ImGui_GetCursorPosY(ctx)
                        local frame_h = reaper.ImGui_GetFrameHeight(ctx)
                        local row_padding = 4
                        local row_h = frame_h + row_padding
                        local content_y = row_y + (row_padding / 2)
                        
                        -- Fix: Push transparent selection colors to avoid "grey over green" visual glitch on Mac
                        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Header(), 0)
                        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderHovered(), 0x22AA2222) -- Subtle hover
                        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderActive(), 0x22AA2233)
                        
                        -- Selectable spanning all columns
                        if reaper.ImGui_Selectable(ctx, "##row_sel" .. e_i, row_selected, reaper.ImGui_SelectableFlags_SpanAllColumns() | reaper.ImGui_SelectableFlags_AllowOverlap(), 0, row_h) then
                            local is_shift = reaper.ImGui_GetKeyMods(ctx) == reaper.ImGui_Mod_Shift()
                            local is_ctrl = (reaper.ImGui_GetKeyMods(ctx) == reaper.ImGui_Mod_Ctrl()) or (reaper.ImGui_GetKeyMods(ctx) == reaper.ImGui_Mod_Super())
                            
                            if is_shift and cfg_dict.last_selected_idx then
                                -- For Shift, we still need to know the VISUAL range [cfg_dict.last_selected_idx, e_i]
                                local start_idx = math.min(cfg_dict.last_selected_idx, e_i)
                                local end_idx = math.max(cfg_dict.last_selected_idx, e_i)
                                if not is_ctrl then cfg_dict.entry_selection = {} end
                                for i = start_idx, end_idx do 
                                    local ent = active_dict.entries[i]
                                    if ent and ent.uid then cfg_dict.entry_selection[ent.uid] = true end
                                end
                            elseif is_ctrl then
                                cfg_dict.entry_selection[entry.uid] = not row_selected
                                if cfg_dict.entry_selection[entry.uid] then cfg_dict.last_selected_idx = e_i end
                            else
                                cfg_dict.entry_selection = { [entry.uid] = true }
                                cfg_dict.last_selected_idx = e_i
                            end
                        end
                        reaper.ImGui_PopStyleColor(ctx, 3)

                        if reaper.ImGui_IsItemClicked(ctx, 1) then
                            if not row_selected then
                                cfg_dict.entry_selection = { [entry.uid] = true }
                                cfg_dict.last_selected_idx = e_i
                            end
                            open_entry_popup = true
                        end

                        -- 3. Draw Columns (RESET CURSOR Y with calculated balance)
                        local content_y = row_y + (row_padding / 2)
                        reaper.ImGui_SetCursorPosY(ctx, content_y)

                        -- Column 0: Index
                        reaper.ImGui_TableSetColumnIndex(ctx, 0)
                        local col0_x, col0_y = reaper.ImGui_GetCursorScreenPos(ctx)
                        reaper.ImGui_SetCursorScreenPos(ctx, col0_x, col0_y)
                        reaper.ImGui_TextDisabled(ctx, "#" .. (entry.uid or e_i))
                        
                        -- Column 1: Word
                        reaper.ImGui_TableSetColumnIndex(ctx, 1)
                        reaper.ImGui_SetCursorPosY(ctx, content_y)
                        reaper.ImGui_SetNextItemWidth(ctx, -1)
                        local changed_w, new_w = reaper.ImGui_InputText(ctx, "##w", entry.word)
                        if reaper.ImGui_IsItemFocused(ctx) and not row_selected then
                            cfg_dict.entry_selection = { [entry.uid] = true }
                            cfg_dict.last_selected_idx = e_i
                        end
                        if changed_w then entry.word = new_w; UTILS.save_user_dicts(); UTILS.move_dict_to_top(cfg_dict.sd_inx) end

                        -- Column 2: Replacement
                        reaper.ImGui_TableSetColumnIndex(ctx, 2)
                        reaper.ImGui_SetCursorPosY(ctx, content_y)
                        reaper.ImGui_SetNextItemWidth(ctx, -1)
                        local changed_r, new_r = reaper.ImGui_InputText(ctx, "##r", entry.replacement)
                        if reaper.ImGui_IsItemFocused(ctx) and not row_selected then
                            cfg_dict.entry_selection = { [entry.uid] = true }
                            cfg_dict.last_selected_idx = e_i
                        end
                        if changed_r then entry.replacement = new_r; UTILS.save_user_dicts(); UTILS.move_dict_to_top(cfg_dict.sd_inx) end

                        -- Column 3: Comment
                        reaper.ImGui_TableSetColumnIndex(ctx, 3)
                        reaper.ImGui_SetCursorPosY(ctx, content_y)
                        reaper.ImGui_SetNextItemWidth(ctx, -1)
                        local changed_c, new_c = reaper.ImGui_InputText(ctx, "##c", entry.comment)
                        if reaper.ImGui_IsItemFocused(ctx) and not row_selected then
                            cfg_dict.entry_selection = { [entry.uid] = true }
                            cfg_dict.last_selected_idx = e_i
                        end
                        if changed_c then entry.comment = new_c; UTILS.save_user_dicts(); UTILS.move_dict_to_top(cfg_dict.sd_inx) end

                        -- Column 4: Delete Button
                        reaper.ImGui_TableSetColumnIndex(ctx, 4)
                        reaper.ImGui_SetCursorPosY(ctx, content_y)
                        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), C_BTN_CLOSE)
                        if reaper.ImGui_Button(ctx, "×##del", 25, 0) then
                            to_remove = e_i
                        end
                        reaper.ImGui_PopStyleColor(ctx)
                        
                        reaper.ImGui_PopID(ctx)
                        
                        ::next_entry::
                    end
                    
                    reaper.ImGui_EndTable(ctx)
                    
                    -- Table Context Menu (for empty space) 
                    if reaper.ImGui_IsWindowHovered(ctx, reaper.ImGui_HoveredFlags_ChildWindows()) and reaper.ImGui_IsMouseClicked(ctx, 1) and not reaper.ImGui_IsAnyItemHovered(ctx) then
                        reaper.ImGui_OpenPopup(ctx, "table_bg_popup")
                    end
                            
                    if reaper.ImGui_BeginPopup(ctx, "table_bg_popup") then
                        if reaper.ImGui_Selectable(ctx, "Вставити") then
                            local text = reaper.ImGui_GetClipboardText(ctx)
                            if text and text ~= "" and active_dict then
                                local added = 0
                                local nid = active_dict.next_id or (#active_dict.entries + 1)
                                for line in text:gmatch("[^\r\n]+") do
                                    local skip = false
                                    local l_lower = utf8_lower(line)
                                    if l_lower:find("слово") and l_lower:find("заміна") then skip = true end
                                    
                                    if not skip then
                                        local parts = {}
                                        local current_line = line .. ","
                                        local i = 1
                                        while i <= #current_line do
                                            local s, e, cap = current_line:find('^%s*"([^"]*)"%s*[, \t]', i)
                                            if not s then
                                                s, e, cap = current_line:find('^([^,\t]*)%s*[, \t]', i)
                                            end
                                            if s then
                                                table.insert(parts, cap or "")
                                                i = e + 1
                                            else
                                                break
                                            end
                                        end
                                        
                                        local w, r, c = parts[1], parts[2], parts[3]
                                        if w and w:gsub("%s+", "") ~= "" then
                                            w = w:gsub('""', '"')
                                            r = (r or ""):gsub('""', '"')
                                            c = (c or ""):gsub('""', '"')
                                            if not UTILS.entry_exists(active_dict.entries, w, r, c) then
                                                table.insert(active_dict.entries, 1, {uid = nid, word = w, replacement = r, comment = c})
                                                nid = nid + 1
                                                added = added + 1
                                            end
                                        end
                                    end
                                end
                                if added > 0 then
                                    active_dict.next_id = nid
                                    UTILS.save_user_dicts()
                                    UTILS.move_dict_to_top(cfg_dict.sd_inx)
                                end
                            end
                        end
                        reaper.ImGui_EndPopup(ctx)
                    end

                    if open_entry_popup then
                        reaper.ImGui_OpenPopup(ctx, "entry_context_menu")
                    end

                    -- Entry Context Menu
                    if reaper.ImGui_BeginPopup(ctx, "entry_context_menu") then
                        local selected_count = 0
                        for _ in pairs(cfg_dict.entry_selection) do selected_count = selected_count + 1 end
                        
                        if reaper.ImGui_Selectable(ctx, "Копіювати (" .. selected_count .. ")") then
                            local lines = {}
                            -- We need to find entries by UIDs now
                            for _, e in ipairs(active_dict.entries) do
                                if cfg_dict.entry_selection[e.uid] then
                                    local w = (e.word or ""):gsub('"', '""')
                                    local r = (e.replacement or ""):gsub('"', '""')
                                    local c = (e.comment or ""):gsub('"', '""')
                                    table.insert(lines, string.format('"%s","%s","%s"', w, r, c))
                                end
                            end
                            reaper.ImGui_SetClipboardText(ctx, table.concat(lines, "\n"))
                        end
                        
                        if reaper.ImGui_Selectable(ctx, "Вирізати (" .. selected_count .. ")") then
                            local lines = {}
                            local to_del_uids = {}
                            for uid, sel in pairs(cfg_dict.entry_selection) do if sel then to_del_uids[uid] = true end end
                            
                            for _, e in ipairs(active_dict.entries) do
                                if to_del_uids[e.uid] then
                                    local w = (e.word or ""):gsub('"', '""')
                                    local r = (e.replacement or ""):gsub('"', '""')
                                    local c = (e.comment or ""):gsub('"', '""')
                                    table.insert(lines, string.format('"%s","%s","%s"', w, r, c))
                                end
                            end
                            reaper.ImGui_SetClipboardText(ctx, table.concat(lines, "\n"))
                            
                            -- Actual remove logic (backwards)
                            for i = #active_dict.entries, 1, -1 do
                                if to_del_uids[active_dict.entries[i].uid] then
                                    table.remove(active_dict.entries, i)
                                end
                            end
                            cfg_dict.entry_selection = {}
                            UTILS.save_user_dicts()
                            UTILS.move_dict_to_top(cfg_dict.sd_inx)
                        end

                        if reaper.ImGui_Selectable(ctx, "Вставити") then
                            local text = reaper.ImGui_GetClipboardText(ctx)
                            if text and text ~= "" then
                                local added = 0
                                local nid = active_dict.next_id or (#active_dict.entries + 1)
                                for line in text:gmatch("[^\r\n]+") do
                                    local skip = false
                                    local l_lower = utf8_lower(line)
                                    if l_lower:find("слово") and l_lower:find("заміна") then skip = true end
                                    
                                    if not skip then
                                        local parts = {}
                                        -- Robust CSV/TSV parser for clipboard
                                        -- Matches: "field",field, or field followed by , or tab
                                        local pattern = '[ \t]*"([^"]*)"[ \t]*' -- Quoted
                                        local alt_pattern = '([^,\t]+)' -- Unquoted
                                        
                                        local current_line = line .. ","
                                        local i = 1
                                        while i <= #current_line do
                                            local s, e, cap = current_line:find('^%s*"([^"]*)"%s*[, \t]', i)
                                            if not s then
                                                s, e, cap = current_line:find('^([^,\t]*)%s*[, \t]', i)
                                            end
                                            if s then
                                                table.insert(parts, cap or "")
                                                i = e + 1
                                            else
                                                break
                                            end
                                        end
                                        
                                        local w, r, c = parts[1], parts[2], parts[3]
                                        if w and w:gsub("%s+", "") ~= "" then
                                            w = w:gsub('""', '"')
                                            r = (r or ""):gsub('""', '"')
                                            c = (c or ""):gsub('""', '"')
                                            if not UTILS.entry_exists(active_dict.entries, w, r, c) then
                                                table.insert(active_dict.entries, 1, {uid = nid, word = w, replacement = r, comment = c})
                                                nid = nid + 1
                                                added = added + 1
                                            end
                                        end
                                    end
                                end
                                if added > 0 then
                                    active_dict.next_id = nid
                                    UTILS.save_user_dicts()
                                    UTILS.move_dict_to_top(cfg_dict.sd_inx)
                                end
                            end
                        end

                        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xFF5050FF)
                        if reaper.ImGui_Selectable(ctx, "Видалити (" .. selected_count .. ")") then
                            local confirm = true
                            if selected_count > 1 then
                                local resp = reaper.MB("Видалити " .. selected_count .. " виділених записів?", "Підтвердження", 4)
                                if resp ~= 6 then confirm = false end
                            end
                            
                            if confirm then
                                local to_del_uids = {}
                                for uid, sel in pairs(cfg_dict.entry_selection) do if sel then to_del_uids[uid] = true end end
                                
                                for i = #active_dict.entries, 1, -1 do
                                    if to_del_uids[active_dict.entries[i].uid] then
                                        table.remove(active_dict.entries, i)
                                    end
                                end
                                cfg_dict.entry_selection = {}
                                UTILS.save_user_dicts()
                                UTILS.move_dict_to_top(cfg_dict.sd_inx)
                            end
                        end
                        reaper.ImGui_PopStyleColor(ctx)
                        
                        reaper.ImGui_EndPopup(ctx)
                    end

                    if to_remove then
                        local entry = active_dict.entries[to_remove]
                        local is_empty = true
                        if entry then
                            if (entry.word and entry.word:gsub("%s+", "") ~= "") or
                               (entry.replacement and entry.replacement:gsub("%s+", "") ~= "") or
                               (entry.comment and entry.comment:gsub("%s+", "") ~= "") then
                                is_empty = false
                            end
                        end

                        if is_empty or reaper.MB("Видалити цей запис?", "Підтвердження", 1) == 1 then
                            if entry and entry.uid then
                                cfg_dict.entry_selection[entry.uid] = nil
                            end
                            table.remove(active_dict.entries, to_remove)
                            UTILS.save_user_dicts()
                            UTILS.move_dict_to_top(cfg_dict.sd_inx)
                        end
                    end
                 end
            else
                reaper.ImGui_TextWrapped(ctx, "Виберіть словник зліва або створіть новий для редагування записів.")
            end
            reaper.ImGui_EndChild(ctx)
        end
                
        reaper.ImGui_EndTabItem(ctx)
        reaper.ImGui_PushFont(ctx, font_tabs, 17)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), 9, 6)
    end
end

local function RenderTab_DownloadCenter()
    -- Download Center Tab
    local dl_flags = (cfg.restore_tab and cfg.last_tab == 3) and reaper.ImGui_TabItemFlags_SetSelected() or 0
    if reaper.ImGui_BeginTabItem(ctx, "Центр Завантажень", nil, dl_flags) then
        if not cfg.restore_tab and cfg.last_tab ~= 3 then
            cfg.last_tab = 3
            reaper.SetExtState("Subass_Dictionary", "last_tab", "3", true)
            UTILS.stop_preview()
        end
        reaper.ImGui_PopFont(ctx)
        reaper.ImGui_PopStyleVar(ctx)

        if not cfg_dwn.dwn_search then cfg_dwn.dwn_search = "" end
        reaper.ImGui_SetNextItemWidth(ctx, -120)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), 9, 8) -- Increased padding for taller input
        local changed, new_query = reaper.ImGui_InputTextWithHint(ctx, "##dl_search", "Введіть назву (напр. Inception) або посилання...", cfg_dwn.dwn_search)
        if changed then cfg_dwn.dwn_search = new_query end

        reaper.ImGui_SameLine(ctx)
        local is_searching = (dl_search_results ~= nil and dl_search_results:find("Шукаєм"))
        local spinner_chars = { "|" , "/", "-", "\\" }
        local spin_label = is_searching
            and (spinner_chars[math.floor(reaper.time_precise() * 6) % 4 + 1] .. " ...")
            or "Шукати"

        if is_searching then
            reaper.ImGui_BeginDisabled(ctx)
            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x444444FF)
        else
            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), C_BTN_MEDIUM)
        end

        if reaper.ImGui_Button(ctx, spin_label, 110) then
            if cfg_dwn.dwn_search ~= "" then
                -- Cleanup old thumbnail
                if cfg_dwn.thumbnail_tex then
                    if reaper.ImGui_Detach then reaper.ImGui_Detach(ctx, cfg_dwn.thumbnail_tex) end
                    if reaper.ImGui_DeleteTexture then reaper.ImGui_DeleteTexture(cfg_dwn.thumbnail_tex) end
                    cfg_dwn.thumbnail_tex = nil
                end
                if cfg_dwn.thumbnail_path then
                    os.remove(cfg_dwn.thumbnail_path)
                    cfg_dwn.thumbnail_path = nil
                end

                cfg_dwn.search_data = nil
                dl_search_results = "Шукаєм"
                
                local query = cfg_dwn.dwn_search:gsub('"', '\\"')
                local cmd_args = string.format('--info --target "%s"', query)
                local cmd = UTILS.get_python_cmd(cmd_args)

                UTILS.run_async_command(cmd, function(output)
                    if output == "TIMEOUT" then
                        dl_search_results = nil
                        cfg_dwn.error_tooltip = { text = "Помилка: Час очікування вичерпано.", t = reaper.time_precise() }
                    elseif output and output:match("}%s*$") then
                        local success, data = pcall(UTILS.json_decode, output)
                        if success and type(data) == "table" then
                            cfg_dwn.search_data = data
                            dl_search_results = nil
                        else
                            dl_search_results = nil
                            cfg_dwn.error_tooltip = { text = "Помилка обробки JSON.", t = reaper.time_precise() }
                        end
                    else
                        dl_search_results = nil
                        cfg_dwn.error_tooltip = { text = "Скрипт повернув помилку.", t = reaper.time_precise() }
                    end
                end)
            end
        end
        reaper.ImGui_PopStyleColor(ctx)
        if is_searching then reaper.ImGui_EndDisabled(ctx) end
        reaper.ImGui_PopStyleVar(ctx) -- Pop FramePadding for search/add bar

        reaper.ImGui_Dummy(ctx, 0, 10)
        reaper.ImGui_Separator(ctx)
        reaper.ImGui_Dummy(ctx, 0, 10)


        -- Error banner: fixed at bottom-center of the current window, auto-dismiss after 4s
        if cfg_dwn.error_tooltip then
            local elapsed = reaper.time_precise() - cfg_dwn.error_tooltip.t
            if elapsed < 4.0 then
                local wx, wy = reaper.ImGui_GetWindowPos(ctx)
                local ww, wh = reaper.ImGui_GetWindowSize(ctx)
                local msg = "⚠  " .. cfg_dwn.error_tooltip.text
                local msg_w = reaper.ImGui_CalcTextSize(ctx, msg) + 32
                local banner_h = 32
                local bx = wx + (ww - msg_w) * 0.5
                local by = wy + wh - banner_h - 10
                reaper.ImGui_SetNextWindowPos(ctx, bx, by)
                reaper.ImGui_SetNextWindowSize(ctx, msg_w, banner_h)
                reaper.ImGui_SetNextWindowBgAlpha(ctx, 0.93)
                local wflags = reaper.ImGui_WindowFlags_NoDecoration()
                             | reaper.ImGui_WindowFlags_NoInputs()
                             | reaper.ImGui_WindowFlags_NoNav()
                             | reaper.ImGui_WindowFlags_NoMove()
                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(), 0x882222EE)
                reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowRounding(), 6)
                if reaper.ImGui_Begin(ctx, "##err_banner", nil, wflags) then
                    reaper.ImGui_SetCursorPosY(ctx, (banner_h - reaper.ImGui_GetTextLineHeight(ctx)) * 0.5)
                    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xFFCCCCFF)
                    reaper.ImGui_Text(ctx, msg)
                    reaper.ImGui_PopStyleColor(ctx)
                    reaper.ImGui_End(ctx)
                end
                reaper.ImGui_PopStyleVar(ctx)
                reaper.ImGui_PopStyleColor(ctx)
            else
                cfg_dwn.error_tooltip = nil
            end
        end

        local avail_h = cfg_glos.layout_has_player and -82 or -5
        if reaper.ImGui_BeginChild(ctx, "dl_center_child", 0, avail_h) then
            if dl_search_results then
                reaper.ImGui_TextWrapped(ctx, dl_search_results)
            elseif cfg_dwn.search_data then
                local has_results = false
                
                if cfg_dwn.search_data.formats then
                    -- =========================================================
                    -- LARGE CARD (URL INFO)
                    -- =========================================================
                    local data = cfg_dwn.search_data
                    
                    -- Load thumbnail if available
                    if data.thumbnail and not cfg_dwn.thumbnail_tex and not cfg_dwn.is_loading_thumb then
                        cfg_dwn.is_loading_thumb = true
                        UTILS.download_thumbnail(data.thumbnail, function(path)
                            cfg_dwn.thumbnail_path = path
                            if reaper.ImGui_CreateImage then
                                local img = reaper.ImGui_CreateImage(path)
                                if reaper.ImGui_Attach then reaper.ImGui_Attach(ctx, img) end
                                cfg_dwn.thumbnail_tex = img
                            end
                            cfg_dwn.is_loading_thumb = false
                        end)
                    end

                    reaper.ImGui_BeginGroup(ctx)
                    
                    -- Header Section: Thumbnail + Title
                    local avail_w = reaper.ImGui_GetContentRegionAvail(ctx)
                    local thumb_w = math.min(180, avail_w * 0.4)
                    local thumb_h = thumb_w * 9 / 16
                    
                    if cfg_dwn.thumbnail_tex then
                        reaper.ImGui_Image(ctx, cfg_dwn.thumbnail_tex, thumb_w, thumb_h)
                        reaper.ImGui_SameLine(ctx, nil, 15)
                    else
                        reaper.ImGui_Dummy(ctx, thumb_w, thumb_h)
                        reaper.ImGui_SameLine(ctx, nil, 15)
                    end
                    
                    reaper.ImGui_BeginGroup(ctx)
                    reaper.ImGui_PushFont(ctx, font_main, 19)
                    reaper.ImGui_TextWrapped(ctx, data.title or "Unknown Video")
                    reaper.ImGui_PopFont(ctx)
                    if data.duration then
                        local m = math.floor(data.duration / 60)
                        local s = data.duration % 60
                        reaper.ImGui_TextDisabled(ctx, string.format("Тривалість: %d:%02d", m, s))
                    end
                    reaper.ImGui_EndGroup(ctx)
                    
                    reaper.ImGui_Dummy(ctx, 0, 10)
                    reaper.ImGui_Separator(ctx)
                    reaper.ImGui_Dummy(ctx, 0, 10)
                    
                    -- Subtitles Section
                    if data.subtitles and #data.subtitles > 0 then
                        reaper.ImGui_PushFont(ctx, font_main, 17)
                        reaper.ImGui_Text(ctx, "Субтитри (вбудовані)")
                        reaper.ImGui_PopFont(ctx)
                        reaper.ImGui_Dummy(ctx, 0, 5)
                        
                        local spin_chars = { "|", "/", "-", "\\" }
                        local spin = spin_chars[math.floor(reaper.time_precise() * 6) % 4 + 1]
                        
                        for i, s in ipairs(data.subtitles) do
                            local label = s.lang:upper() .. (s.is_auto and " (Auto)" or "")
                            local btn_key = "url_sub_" .. s.lang
                            local is_loading = (cfg_dwn.loading_item == btn_key)
                            
                            reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameRounding(), 3)
                            reaper.ImGui_Text(ctx, label)
                            reaper.ImGui_SameLine(ctx, avail_w - 60)
                            
                            if is_loading then
                                reaper.ImGui_BeginDisabled(ctx)
                                reaper.ImGui_Button(ctx, spin .. "##" .. btn_key, 56)
                                reaper.ImGui_EndDisabled(ctx)
                            else
                                if reaper.ImGui_Button(ctx, "DL##" .. btn_key, 56) then
                                    UTILS.trigger_subtitle_from_url(cfg_dwn.dwn_search, s.lang, btn_key)
                                end
                            end
                            reaper.ImGui_PopStyleVar(ctx)
                            reaper.ImGui_Separator(ctx)
                        end
                        reaper.ImGui_Dummy(ctx, 0, 10)
                    end
                    
                    -- Formats Section (Media download)
                    if data.formats and #data.formats > 0 then
                        reaper.ImGui_PushFont(ctx, font_main, 17)
                        reaper.ImGui_Text(ctx, "Медіа (тільки відео/аудіо)")
                        reaper.ImGui_PopFont(ctx)
                        reaper.ImGui_Dummy(ctx, 0, 5)
                        
                        local spin_chars = { "|", "/", "-", "\\" }
                        local spin = spin_chars[math.floor(reaper.time_precise() * 6) % 4 + 1]
                        
                        for i, f in ipairs(data.formats) do
                            local f_label = string.format("[%s] %s %s", f.ext:upper(), f.type:upper(), f.note or f.resolution or "")
                            local btn_key = "url_fmt_" .. (f.format_id or i)
                            local is_loading = (cfg_dwn.loading_item == btn_key)
                            
                            reaper.ImGui_Text(ctx, f_label)
                            reaper.ImGui_SameLine(ctx, avail_w - 60)
                            
                            if is_loading then
                                reaper.ImGui_BeginDisabled(ctx)
                                reaper.ImGui_Button(ctx, spin .. "##" .. btn_key, 56)
                                reaper.ImGui_EndDisabled(ctx)
                            else
                                if reaper.ImGui_Button(ctx, "DL##" .. btn_key, 56) then
                                    UTILS.download_media(cfg_dwn.dwn_search, f.format_id, data.title or "Video", f.ext, f.type, btn_key)
                                end
                            end
                            reaper.ImGui_Separator(ctx)
                        end
                    end
                    
                    reaper.ImGui_EndGroup(ctx)
                    has_results = true
                end

                for _, source_group in ipairs(cfg_dwn.search_data.sources or {}) do
                    local items = source_group.items or {}
                    if #items > 0 then
                        has_results = true
                        reaper.ImGui_PushFont(ctx, font_main, 18)
                        reaper.ImGui_Text(ctx, string.upper(source_group.source))
                        reaper.ImGui_PopFont(ctx)
                        reaper.ImGui_Separator(ctx)
                        reaper.ImGui_Dummy(ctx, 0, 5)
                        
                        for i, item in ipairs(items) do
                            -- Compact single-row card
                            local avail_w = reaper.ImGui_GetContentRegionAvail(ctx)
                            local btn_w = 56
                            local btn_gap = 4
                            local text_w = avail_w - (btn_w * 2) - btn_gap * 3 - 8
                            local spin_chars = { "|", "/", "-", "\\" }
                            local spin = spin_chars[math.floor(reaper.time_precise() * 6) % 4 + 1]
                            local prev_key = i .. source_group.source .. "preview"
                            local add_key  = i .. source_group.source .. "import"
                            local prev_loading = (cfg_dwn.loading_item == prev_key)
                            local add_loading  = (cfg_dwn.loading_item == add_key)
                            local any_loading  = (cfg_dwn.loading_item ~= nil)

                            -- Title (truncated to fit)
                            local title = item.title or item.file_name or "Unknown"
                            local info_parts = {}
                            if item.lang then table.insert(info_parts, item.lang:upper()) end
                            if item.format then table.insert(info_parts, item.format:upper()) end
                            if item.year and item.year ~= "" then table.insert(info_parts, item.year) end
                            if item.downloads then table.insert(info_parts, "DL:"..item.downloads) end
                            local meta = table.concat(info_parts, "  ")

                            -- Truncate title dynamically
                            local meta_w = meta ~= "" and (reaper.ImGui_CalcTextSize(ctx, "  " .. meta) + 10) or 0
                            local title_avail = text_w - meta_w
                            while #title > 4 and reaper.ImGui_CalcTextSize(ctx, title) > title_avail do
                                title = title:sub(1, -2)
                            end
                            if title ~= (item.title or item.file_name or "Unknown") then title = title:sub(1,-2) .. "…" end

                            reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameRounding(), 3)

                            -- Title text
                            reaper.ImGui_Text(ctx, title)
                            reaper.ImGui_SameLine(ctx, nil, 6)
                            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0x777777FF)
                            reaper.ImGui_Text(ctx, meta)
                            reaper.ImGui_PopStyleColor(ctx)

                            -- Preview button
                            reaper.ImGui_SameLine(ctx, avail_w - btn_w * 2 - btn_gap - 4)
                            if prev_loading then
                                reaper.ImGui_BeginDisabled(ctx)
                                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x444444FF)
                                reaper.ImGui_Button(ctx, spin .. "##prev" .. i .. source_group.source, btn_w)
                                reaper.ImGui_PopStyleColor(ctx)
                                reaper.ImGui_EndDisabled(ctx)
                            else
                                if any_loading then reaper.ImGui_BeginDisabled(ctx) end
                                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x3A3A3AFF)
                                if reaper.ImGui_Button(ctx, ">##prev" .. i .. source_group.source, btn_w) then
                                    UTILS.trigger_subtitle_download(item, source_group.source, "preview", prev_key)
                                end
                                reaper.ImGui_PopStyleColor(ctx)
                                if any_loading then reaper.ImGui_EndDisabled(ctx) end
                            end
                            if reaper.ImGui_IsItemHovered(ctx) then reaper.ImGui_SetTooltip(ctx, "Preview") end

                            -- Add button
                            reaper.ImGui_SameLine(ctx, nil, btn_gap)
                            if add_loading then
                                reaper.ImGui_BeginDisabled(ctx)
                                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x444444FF)
                                reaper.ImGui_Button(ctx, spin .. "##add" .. i .. source_group.source, btn_w)
                                reaper.ImGui_PopStyleColor(ctx)
                                reaper.ImGui_EndDisabled(ctx)
                            else
                                if any_loading then reaper.ImGui_BeginDisabled(ctx) end
                                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), C_BTN_MEDIUM)
                                if reaper.ImGui_Button(ctx, "+##add" .. i .. source_group.source, btn_w) then
                                    UTILS.trigger_subtitle_download(item, source_group.source, "import", add_key)
                                end
                                reaper.ImGui_PopStyleColor(ctx)
                                if any_loading then reaper.ImGui_EndDisabled(ctx) end
                            end
                            if reaper.ImGui_IsItemHovered(ctx) then reaper.ImGui_SetTooltip(ctx, "Add to project") end

                            reaper.ImGui_PopStyleVar(ctx)
                            reaper.ImGui_Separator(ctx)
                        end
                        reaper.ImGui_Dummy(ctx, 0, 10)
                    end
                end
                if not has_results then
                    reaper.ImGui_TextDisabled(ctx, "Нічого не знайдено.")
                end
            else
                reaper.ImGui_TextDisabled(ctx, "Введіть пошуковий запит для початку.")
            end

            reaper.ImGui_EndChild(ctx)
        end
        
        reaper.ImGui_EndTabItem(ctx)
        reaper.ImGui_PushFont(ctx, font_tabs, 17)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), 9, 6)
    end
end

local function loop()
    if not ctx or not reaper.ImGui_ValidatePtr(ctx, 'ImGui_Context*') then return end
    local force_close = reaper.GetExtState("Subass_Global", "ForceCloseComplementary")
    if force_close == "1" or force_close == "Subass_Dictionary.lua" then 
        if force_close == "Subass_Dictionary.lua" then
            reaper.SetExtState("Subass_Global", "ForceCloseComplementary", "0", false)
        end
        dict_open = false
    end

    reaper.ImGui_SetNextWindowSize(ctx, WIN_W, WIN_H, reaper.ImGui_Cond_FirstUseEver())

    -- APPLY GLOBAL STYLE
    Style.push(ctx)

    local visible, open = reaper.ImGui_Begin(ctx, 'Subass Dictionary', dict_open, reaper.ImGui_WindowFlags_NoScrollbar())
    if not open then dict_open = false end

    if visible then
        cfg_glos.layout_has_player = (cfg_glos.current_preview_source ~= nil)

        -- TABS
        reaper.ImGui_PushFont(ctx, font_tabs, 17)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), 9, 6)
        local tabs_visible = reaper.ImGui_BeginTabBar(ctx, "DictionaryTabs")

        if tabs_visible then
            RenderTab_Reference()
            RenderTab_Glossary()
            RenderTab_Dictionaries()
            RenderTab_DownloadCenter()

            reaper.ImGui_EndTabBar(ctx)
            cfg.restore_tab = false
        end
        reaper.ImGui_PopStyleVar(ctx)
        reaper.ImGui_PopFont(ctx)

        draw_mini_player(ctx)
        draw_preview_popup()
        reaper.ImGui_End(ctx)
    end

    -- POP GLOBAL STYLE
    Style.pop(ctx)
    
    UTILS.check_async_tasks()

    if dict_open then
        reaper.defer(loop)
    end
end

reaper.defer(loop)
