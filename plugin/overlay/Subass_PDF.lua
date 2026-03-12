-- @description Subass PDF Reader (ReaImGui PDF Module)
-- @version 1.2
-- @author Fusion (Fusion Dub)
-- @about Displays PDF pages in REAPER with interactive metadata. Requires ReaImGui and Python with PyMuPDF.

if not reaper.ImGui_CreateContext then
    reaper.ShowMessageBox('ReaImGui extension is required for this script.\n\nPlease install it via ReaPack (cfillion repository).', 'Subass PDF', 0)
    return
end

-- =============================================================================
-- JSON UTILS (Native Lua Decoder)
-- =============================================================================
local function json_decode(str)
    if not str or str == "" then return nil end
    local pos = 1
    local function skip_whitespace()
        while pos <= #str and str:sub(pos, pos):match("%s") do pos = pos + 1 end
    end
    local decode_value
    local function decode_string()
        pos = pos + 1 -- skip opening "
        local res = ""
        while pos <= #str do
            local char = str:sub(pos, pos)
            if char == '"' then pos = pos + 1 return res
            elseif char == '\\' then
                local next_char = str:sub(pos + 1, pos + 1)
                if next_char == 'n' then res = res .. "\n"
                elseif next_char == 'r' then res = res .. "\r"
                elseif next_char == 't' then res = res .. "\t"
                else res = res .. next_char end
                pos = pos + 2
            else res = res .. char pos = pos + 1 end
        end
        return res
    end
    local function decode_number()
        local start = pos
        while pos <= #str and str:sub(pos, pos):match("[%d%.%-%+eE]") do pos = pos + 1 end
        return tonumber(str:sub(start, pos - 1)) or 0
    end
    local function decode_array()
        pos = pos + 1 -- [
        local res = {}
        skip_whitespace()
        if str:sub(pos, pos) == "]" then pos = pos + 1 return res end
        while pos <= #str do
            table.insert(res, decode_value())
            skip_whitespace()
            local char = str:sub(pos, pos)
            if char == "]" then pos = pos + 1 return res
            elseif char == "," then pos = pos + 1 end
        end
        return res
    end
    local function decode_object()
        pos = pos + 1 -- {
        local res = {}
        skip_whitespace()
        if str:sub(pos, pos) == "}" then pos = pos + 1 return res end
        while pos <= #str do
            skip_whitespace()
            local key = decode_value()
            if key == nil then break end
            skip_whitespace()
            if str:sub(pos, pos) == ":" then pos = pos + 1 end
            skip_whitespace()
            res[tostring(key)] = decode_value()
            skip_whitespace()
            local char = str:sub(pos, pos)
            if char == "}" then pos = pos + 1 return res
            elseif char == "," then pos = pos + 1
            else break end
        end
        return res
    end
    decode_value = function()
        skip_whitespace()
        local char = str:sub(pos, pos)
        if char == "{" then return decode_object()
        elseif char == "[" then return decode_array()
        elseif char == '"' then return decode_string()
        elseif char == "t" and str:sub(pos, pos+3) == "true" then pos = pos + 4 return true
        elseif char == "f" and str:sub(pos, pos+4) == "false" then pos = pos + 5 return false
        elseif char == "n" and str:sub(pos, pos+3) == "null" then pos = pos + 4 return nil
        else return decode_number() end
    end
    local ok, res = pcall(decode_value)
    return ok and res or nil
end

-- =============================================================================
-- CONFIG & STATE
-- =============================================================================
local ctx = reaper.ImGui_CreateContext('Subass PDF Reader')
local script_path = debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])")
local function normalize_path(p)
    if not p then return p end
    local sep = reaper.GetOS():match("Win") and "\\" or "/"
    return p:gsub("[/\\]", sep)
end
local python_script = normalize_path(script_path .. "subass_pdf_processor.py")
reaper.gmem_attach("SubassSync")

-- =============================================================================
-- STYLES
-- =============================================================================
local UI_COLORS = {
    WindowBg        = 0x444444FF,
    TitleBg         = 0x303030FF,
    TitleBgActive   = 0x505050FF,
    Text            = 0xE0E0E0FF,
    Button          = 0x353535FF,
    ButtonHovered   = 0x606060FF,
    ButtonActive    = 0x707070FF
}

local UI_VARS = {
    WindowRounding  = 12.0,
    FrameRounding   = 6.0
}

local function push_theme(ctx)
    local c = UI_COLORS
    local v = UI_VARS
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(),      c.WindowBg)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBg(),       c.TitleBg)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgActive(), c.TitleBgActive)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(),          c.Text)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),        c.Button)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), c.ButtonHovered)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(),  c.ButtonActive)

    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowRounding(), v.WindowRounding)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameRounding(),  v.FrameRounding)
end

local function pop_theme(ctx)
    reaper.ImGui_PopStyleColor(ctx, 7)
    reaper.ImGui_PopStyleVar(ctx, 2)
end

local STATE = {
    documents = {}, -- List of {pdf_name, metadata, cache_dir, current_page, textures, zoom, last_scroll_y}
    active_doc_idx = 0,
    
    is_loading = 0,
    status_msg = "Готово",
    window_open = true,
    show_debug_boxes = false,
    async_pool = {},
    current_proj = nil,
    search_open = false,
    search_text = "",
    search_results = {},
    search_index = 0,
    scroll_to_search = false,
    scroll_to_search_target = nil,
    
    context_item = nil,
    context_doc = nil,
    trigger_context_menu = false,
    notes_cmd_id = nil,
}

-- =============================================================================
-- UTILS
-- =============================================================================

local function truncate_text(text, max_len)
    if not text then return "" end
    if #text <= max_len then return text end
    
    local name = text:match("(.*)%.") or text
    local ext = text:match("%.([^%.]+)$") or ""
    if ext ~= "" then ext = "." .. ext end
    
    local available_for_name = max_len - #ext - 3 -- 3 for "..."
    if available_for_name < 3 then 
        -- If extension is too long or name is too short, just do simple truncation
        return text:sub(1, max_len - 3) .. "..."
    end
    
    local truncated_name = name:sub(1, available_for_name)
    -- Simple UTF-8 aware truncation
    while #truncated_name > 0 and (truncated_name:byte(-1) >= 128 and truncated_name:byte(-1) < 192) do
        truncated_name = truncated_name:sub(1, -2)
    end
    
    return truncated_name .. "..." .. ext
end

local function unload_textures(textures)
    if not textures then return end
    for _, tex in pairs(textures) do
        if reaper.ImGui_Detach then pcall(reaper.ImGui_Detach, ctx, tex) end
        if reaper.ImGui_DeleteTexture then pcall(reaper.ImGui_DeleteTexture, tex) end
    end
end

local function get_active_doc()
    if STATE.active_doc_idx > 0 and STATE.documents[STATE.active_doc_idx] then
        return STATE.documents[STATE.active_doc_idx]
    end
    return nil
end

local function simple_json_encode(v)
    if type(v) == "string" then
        return '"' .. v:gsub('\\', '\\\\'):gsub('"', '\\"') .. '"'
    elseif type(v) == "number" or type(v) == "boolean" then
        return tostring(v)
    elseif type(v) == "table" then
        local is_array = #v > 0
        local parts = {}
        if is_array then
            for _, item in ipairs(v) do
                table.insert(parts, simple_json_encode(item))
            end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            for k, val in pairs(v) do
                table.insert(parts, string.format('"%s":%s', k, simple_json_encode(val)))
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    end
    return "null"
end

local function save_project_state(proj, mark_dirty)
    local target_proj = proj or STATE.current_proj
    if not target_proj or not reaper.ValidatePtr(target_proj, "ReaProject*") then
        target_proj = reaper.EnumProjects(-1)
    end
    if not target_proj then return end

    local docs_to_save = {}
    for _, doc in ipairs(STATE.documents) do
        table.insert(docs_to_save, {
            pdf_name = doc.pdf_name,
            current_page = doc.current_page,
            zoom = doc.zoom,
            scroll_y = doc.scroll_y or 0,
            search_text = doc.search_text or "",
            search_index = doc.search_index or 0,
            search_open = doc.search_open or false
        })
    end
    
    local history = simple_json_encode(docs_to_save)
    reaper.SetProjExtState(target_proj, "Subass_PDF", "doc_history", history)
    
    local active = get_active_doc()
    reaper.SetProjExtState(target_proj, "Subass_PDF", "last_pdf", active and active.pdf_name or "")
    
    if mark_dirty then
        reaper.MarkProjectDirty(target_proj)
    end
end


local function switch_to_document(idx)
    if idx == STATE.active_doc_idx then return end
    
    -- Save current scroll before switching (captured continuously in draw_gui)
    local current = get_active_doc()
    if current then
        unload_textures(current.textures)
        current.textures = {}
    end
    
    STATE.active_doc_idx = idx
    local new_doc = get_active_doc()
    if new_doc then
        STATE.status_msg = "Переключено на: " .. new_doc.pdf_name
        new_doc.needs_scroll_restore = 20 -- Retry restoration for 20 frames
        
        -- Trigger search re-calculation if search was open
        if new_doc.search_open and new_doc.search_text ~= "" and (not new_doc.search_results or #new_doc.search_results == 0) then
            perform_search(new_doc)
        end

        save_project_state()
    end
end

local function get_notes_cmd_id()
    if STATE.notes_cmd_id then return STATE.notes_cmd_id end
    local kb_path = reaper.GetResourcePath() .. "/reaper-kb.ini"
    local f = io.open(kb_path, "r")
    if not f then return nil end
    
    for line in f:lines() do
        if line:find("Subass_Notes.lua", 1, true) then
            local id = line:match("RS([%a%d ]+)")
            if id then
                id = id:match("^([%a%d]+)")
                STATE.notes_cmd_id = "_RS" .. id
                f:close()
                return STATE.notes_cmd_id
            end
        end
    end
    f:close()
    return nil
end

local function focus_notes_window()
    if not reaper.JS_Window_ArrayAllChild then return false end
    
    -- Helper for recursive search (docked windows are nested children in REAPER)
    local function find_recursively(parent_hwnd)
        local arr = reaper.new_array({}, 1024)
        reaper.JS_Window_ArrayAllChild(parent_hwnd, arr)
        local children = arr.table()
        for _, ptr in ipairs(children) do
            local child = reaper.JS_Window_HandleFromAddress(ptr)
            local title = reaper.JS_Window_GetTitle(child)
            if title:find("Subass Notes", 1, true) then
                return child
            end
            local found = find_recursively(child)
            if found then return found end
        end
        return nil
    end

    -- 1. Search throughout the entire REAPER window hierarchy
    local found_hwnd = find_recursively(reaper.GetMainHwnd())
    
    -- 2. Fallback: Search top-level OS windows (if floating)
    if not found_hwnd and reaper.JS_Window_ArrayAllTop then
        local arr = reaper.new_array({}, 1024)
        reaper.JS_Window_ArrayAllTop(arr)
        for _, ptr in ipairs(arr.table()) do
            local hwnd = reaper.JS_Window_HandleFromAddress(ptr)
            if reaper.JS_Window_GetTitle(hwnd):find("Subass Notes", 1, true) then
                found_hwnd = hwnd
                break
            end
        end
    end

    if found_hwnd then
        -- Native REAPER API to switch tabs in Docker
        reaper.DockWindowActivate(found_hwnd)
        reaper.JS_Window_SetFocus(found_hwnd)
        reaper.JS_Window_SetForeground(found_hwnd)
        return true
    end
    
    -- 3. If truly not found, it might be closed. Launch it.
    local cmd_id = get_notes_cmd_id()
    if cmd_id then
        local cmd = reaper.NamedCommandLookup(cmd_id)
        if cmd ~= 0 then
            reaper.Main_OnCommand(cmd, 0)
            return true
        end
    end
    return false
end

local function run_async_command(shell_cmd, callback)
    local id = tostring(os.time()) .. "_" .. math.random(1000, 9999)
    local path = reaper.GetResourcePath() .. "/Scripts/"
    local out_file = path .. "subass_pdf_out_" .. id .. ".tmp"
    local done_file = path .. "subass_pdf_done_" .. id .. ".marker"
    
    if reaper.GetOS():match("Win") then
        out_file = out_file:gsub("/", "\\")
        done_file = done_file:gsub("/", "\\")
        local bat_file = (path .. "subass_pdf_exec_" .. id .. ".bat"):gsub("/", "\\")

        local f_bat = io.open(bat_file, "w")
        if not f_bat then return end

        f_bat:write("@echo off\r\n")
        f_bat:write("chcp 65001 > NUL\r\n")
        local bat_cmd = shell_cmd:gsub("%%", "%%%%")
        f_bat:write(bat_cmd .. ' > "' .. out_file .. '" 2>&1\r\n')
        f_bat:write('echo DONE > "' .. done_file .. '"\r\n')
        f_bat:write('del "%~f0"\r\n')
        f_bat:close()

        -- Use a simpler PowerShell call or just ExecProcess if possible
        local safe_bat = bat_file:gsub("'", "''")
        local ps_cmd = 'powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "Start-Process \'' .. safe_bat .. '\' -WindowStyle Hidden"'
        reaper.ExecProcess(ps_cmd, 0)
    else
        -- Mac/Linux background execution
        local full_cmd = '( ' .. shell_cmd .. ' > "' .. out_file .. '" 2>&1 ; touch "' .. done_file .. '" ) &'
        os.execute(full_cmd)
    end
    
    table.insert(STATE.async_pool, {
        id = id,
        out_file = out_file,
        done_file = done_file,
        callback = callback
    })
end

local function check_async_tasks()
    for i = #STATE.async_pool, 1, -1 do
        local task = STATE.async_pool[i]
        if reaper.file_exists(task.done_file) then
            -- Read output if needed
            local f = io.open(task.out_file, "r")
            local output = ""
            if f then output = f:read("*all"); f:close() end
            
            -- Cleanup
            os.remove(task.out_file)
            os.remove(task.done_file)
            
            -- Callback
            if task.callback then task.callback(output) end
            table.remove(STATE.async_pool, i)
        end
    end
end

local function get_project_cache_dir()
    local prj_path, _ = reaper.GetProjectPath("")
    if prj_path == "" then return nil end
    local cache = normalize_path(prj_path .. "/subass_pdf_cache")
    if not reaper.RecursiveCreateDirectory(cache, 0) then return nil end
    return cache
end

local function parse_timecode(str)
    -- Clean string
    local s_text = str:gsub("^%s+", ""):gsub("%s+$", "")
    
    -- Format: HH:MM:SS.ms or HH:MM:SS,ms or HH.MM.SS
    local h, m, s, ms = s_text:match("^(%d+)[%.:](%d+)[%.:](%d+)[%.,](%d+)$")
    if h then return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s) + (tonumber(ms) / 1000) end
    
    -- Format: HH:MM:SS or HH.MM.SS
    h, m, s = s_text:match("^(%d+)[%.:](%d+)[%.:](%d+)$")
    if h then return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s) end
    
    -- Format: MM:SS.ms or MM:SS,ms or MM.SS.ms
    m, s, ms = s_text:match("^(%d+)[%.:](%d+)[%.,](%d+)$")
    if m then return tonumber(m) * 60 + tonumber(s) + (tonumber(ms) / 1000) end
    
    -- Format: MM:SS or MM.SS or M.S
    m, s = s_text:match("^(%d+)[%.:](%d+)$")
    if m then return tonumber(m) * 60 + tonumber(s) end

    return nil
end

local function parse_url(str)
    local s_text = str:gsub("^%s+", ""):gsub("%s+$", "")
    if s_text:match("^https?://") or s_text:match("^www%.") then
        if s_text:match("^www%.") then
            return "https://" .. s_text
        end
        return s_text
    end
    return nil
end

local function scroll_to_search(search_result)
    if search_result then
        STATE.scroll_to_search = true
        STATE.scroll_to_search_target = search_result
    end
end

local function perform_search(doc)
    doc = doc or get_active_doc()
    if not doc or not doc.metadata then return end

    doc.search_results = {}
    doc.search_index = 0
    if not doc.search_text or doc.search_text == "" then return end

    local upper_to_lower = {
        ["А"]="а",["Б"]="б",["В"]="в",["Г"]="г",["Ґ"]="ґ",["Д"]="д",["Е"]="е",["Є"]="є",
        ["Ж"]="ж",["З"]="з",["И"]="и",["І"]="і",["Ї"]="ї",["Й"]="й",["К"]="к",
        ["Л"]="л",["М"]="м",["Н"]="н",["О"]="о",["П"]="п",["Р"]="р",["С"]="с",
        ["Т"]="т",["У"]="у",["Ф"]="ф",["Х"]="х",["Ц"]="ц",["Ч"]="ч",["Ш"]="ш",
        ["Щ"]="щ",["Ь"]="ь",["Ю"]="ю",["Я"]="я", 
    }
    local function lower_unicode(s)
        s = s:lower()
        return (s:gsub("([%z\1-\127\194-\244][\128-\191]*)", function(c)
            return upper_to_lower[c] or c
        end))
    end

    local query = lower_unicode(doc.search_text)
    for p_idx, page in ipairs(doc.metadata.pages) do
        local items = page.items or {}
        local full_text = ""
        local item_starts = {}
        local item_ends = {}

        for i_idx, item in ipairs(items) do
            local start_pos = #full_text + 1
            full_text = full_text .. (item.text or "") .. " "
            item_starts[i_idx] = start_pos
            item_ends[i_idx] = #full_text - 1
        end

        full_text = lower_unicode(full_text)

        local search_pos = 1
        while true do
            local s, e = full_text:find(query, search_pos, true)
            if not s then break end

            local start_item, end_item
            for i_idx = 1, #items do
                if not start_item and s <= item_ends[i_idx] then
                    start_item = i_idx
                end
                if e >= item_starts[i_idx] then
                    end_item = i_idx
                end
            end

            if start_item and end_item then
                table.insert(doc.search_results, {
                    page = p_idx,
                    items = {start_item, end_item}
                })
            end
            search_pos = e + 1
        end
    end

    local res_count = #doc.search_results
    if res_count > 0 then
        doc.search_index = 1
        scroll_to_search(doc.search_results[1])
    end
end

-- =============================================================================
-- PDF ENGINE & CACHE
-- =============================================================================
local function load_metadata(output_dir, pdf_name, saved_state, no_switch)
    local meta_path = normalize_path(output_dir .. "/metadata.json")
    local f = io.open(meta_path, "r")
    if f then
        local meta = json_decode(f:read("*all"))
        f:close()
        
        -- Check if document already exists in history
        local existing_idx = 0
        for i, d in ipairs(STATE.documents) do
            if d.pdf_name == pdf_name then existing_idx = i; break end
        end
        
        local doc_data = {
            pdf_name = pdf_name,
            metadata = meta,
            cache_dir = output_dir,
            current_page = saved_state and saved_state.current_page or 1,
            textures = {},
            zoom = saved_state and saved_state.zoom or 1.0,
            scroll_y = saved_state and saved_state.scroll_y or 0,
            needs_scroll_restore = (saved_state and saved_state.scroll_y and saved_state.scroll_y > 0) and 20 or 0,
            skip_scroll_capture = 0,
            search_text = saved_state and saved_state.search_text or "",
            search_index = saved_state and saved_state.search_index or 0,
            search_open = saved_state and saved_state.search_open or false,
            search_results = {}
        }
        
        if doc_data.search_open and doc_data.search_text ~= "" then
            perform_search(doc_data)
            if saved_state and saved_state.search_index then
                doc_data.search_index = math.min(saved_state.search_index, #doc_data.search_results)
            end
        end
        
        if existing_idx > 0 then
            -- Update existing
            unload_textures(STATE.documents[existing_idx].textures)
            STATE.documents[existing_idx] = doc_data
            if not no_switch then switch_to_document(existing_idx) end
        else
            -- Add new
            table.insert(STATE.documents, doc_data)
            if not no_switch then switch_to_document(#STATE.documents) end
        end
        
        if not no_switch then save_project_state(nil, true) end
        STATE.status_msg = "Завантажено: " .. pdf_name
        return true
    end
    return false
end

local function process_pdf(pdf_file)
    if not pdf_file or pdf_file == "" then return end
    
    pdf_file = normalize_path(pdf_file)
    
    STATE.is_loading = STATE.is_loading + 1
    STATE.status_msg = "Обробка..."
    
    local prj_cache = get_project_cache_dir()
    if not prj_cache then
        reaper.ShowMessageBox("Спочатку збережіть ваш проект!", "Помилка", 0)
        STATE.is_loading = STATE.is_loading - 1
        return
    end
    
    local pdf_name = pdf_file:match("([^/\\]+)$") or "temp_doc"
    
    -- Warning for Word files
    local ext = pdf_file:match("%.([^%.]+)$")
    if ext then
        ext = ext:lower()
        if ext == "doc" or ext == "docx" then
            reaper.MB("Плагін може не розпізнати цей файл, рекомендуємо вручну конвертувати його в PDF", "Попередження", 0)
        end
    end
    
    local output_dir = normalize_path(prj_cache .. "/" .. pdf_name)
    reaper.RecursiveCreateDirectory(output_dir, 0)
    
    local cmd = string.format('python3 "%s" "%s" "%s"', python_script, pdf_file, output_dir)
    if reaper.GetOS():match("Win") then 
        -- On Windows, 'py' (Python Launcher) is often more reliable than 'python'
        -- We'll use a CMD trick to try 'py' and fallback to 'python'
        cmd = string.format('py -3 "%s" "%s" "%s" || python "%s" "%s" "%s"', 
            python_script, pdf_file, output_dir,
            python_script, pdf_file, output_dir) 
    end
    
    run_async_command(cmd, function(output)
        if not load_metadata(output_dir, pdf_name) then
            if output:match("not found") or output:match("not recognized") then
                STATE.status_msg = "Помилка: Python не знайдено"
            else
                STATE.status_msg = "Помилка завантаження метаданих"
            end
        end
        STATE.is_loading = math.max(0, STATE.is_loading - 1)
        if STATE.is_loading == 0 then STATE.status_msg = "Готово" end
    end)
end

local function pick_pdf()
    if reaper.APIExists('JS_Dialog_BrowseForOpenFiles') then
        local filter = "Усі підтримувані файли\0*.pdf;*.docx;*.doc;*.epub;*.mobi;*.txt;*.html;*.xps;*.fb2;*.cbz;*.svg;*.png;*.jpg;*.jpeg;*.gif;*.tiff;*.webp\0PDF файли (*.pdf)\0*.pdf\0Word файли (*.docx, *.doc)\0*.docx;*.doc\0Зображення (*.png, *.jpg, *.webp, etc)\0*.png;*.jpg;*.jpeg;*.gif;*.tiff;*.webp\0Електронні книги (*.epub, *.mobi, *.fb2)\0*.epub;*.mobi;*.fb2\0Інші (*.txt, *.html, *.svg, *.xps, *.cbz)\0*.txt;*.html;*.svg;*.xps;*.cbz\0Всі файли (*.*)\0*.*\0"
        local retval, files_str = reaper.JS_Dialog_BrowseForOpenFiles("Оберіть файл для імпорту", "", "", filter, true)
        
        if retval > 0 and files_str ~= "" then 
            local entries = {}
            for entry in files_str:gmatch("[^\n\r%z]+") do
                table.insert(entries, entry)
            end
            
            if #entries == 0 then return nil end
            if #entries == 1 then return {entries[1]} end
            
            -- Detect format: 
            --   On Mac it usually returns full paths: /Path/File1, /Path/File2
            --   On Win it returns: Dir, File1, File2
            -- Heuristic: If the second entry is NOT an absolute path, it's Windows style (Dir + Filenames)
            local first = entries[1]
            local second = entries[2]
            local is_windows_style = false
            
            if second and not (second:match("^/") or second:match("^%a:")) then
                is_windows_style = true
            end

            if is_windows_style then
                local dir = first
                if not dir:match("[/\\]$") then
                    local sep = dir:match("\\") and "\\" or "/"
                    dir = dir .. sep
                end
                local paths = {}
                for i = 2, #entries do
                    table.insert(paths, dir .. entries[i])
                end
                return paths
            else
                -- Already full paths (macOS style or multiple absolute paths)
                return entries
            end
        end
    else
        local retval, file = reaper.GetUserInputs("Імпорт документа", 1, "Шлях до файлу (PDF, Word, EBook, etc):", "")
        if retval and file ~= "" then return {file} end
    end
    return nil
end

-- =============================================================================
-- DRAWING
-- =============================================================================
local function draw_page(page_index, page_data, avail_w, doc)
    if not doc then return end
    local tex_path = doc.cache_dir .. "/" .. page_data.image
    local tex = doc.textures[page_index]
    
    local tw, th = page_data.width * 2, page_data.height * 2
    if tex and reaper.ImGui_Image_GetSize then
        local ok, w_sz, h_sz = pcall(reaper.ImGui_Image_GetSize, tex)
        if ok and type(w_sz) == "number" then tw, th = w_sz, h_sz end
    end
    
    local padding = 0
    local scale = ((avail_w - padding * 2) / (page_data.width or tw/2)) * doc.zoom
    local draw_w = (page_data.width or tw/2) * scale
    local draw_h = (page_data.height or th/2) * scale
    
    -- Track current visible page
    local cursor_y = reaper.ImGui_GetCursorPosY(ctx)
    local scroll_y = reaper.ImGui_GetScrollY(ctx)
    local win_h = reaper.ImGui_GetWindowHeight(ctx)
    local view_center = scroll_y + (win_h / 2)
    
    if view_center >= cursor_y and view_center <= (cursor_y + draw_h) then
        doc.current_page = page_index
    end
    
    -- Handle scrolling to search result even if page is off-screen
    if STATE.scroll_to_search and STATE.scroll_to_search_target then
        local active_res = STATE.scroll_to_search_target
        if active_res.page == page_index then
            local item_idx = active_res.items and active_res.items[1] or 1
            local item = page_data.items and page_data.items[item_idx]
            if item then
                local target_y = cursor_y + (item.y * scale)
                reaper.ImGui_SetScrollY(ctx, target_y - (win_h / 2))
                STATE.scroll_to_search = false
                STATE.scroll_to_search_target = nil
            end
        end
    end

    -- Visibility Check for Lazy Loading
    if not reaper.ImGui_IsRectVisible(ctx, draw_w, draw_h) then
        reaper.ImGui_Dummy(ctx, draw_w, draw_h)
        -- Unload texture if it goes out of view to save memory
        if tex then
            unload_textures({tex})
            doc.textures[page_index] = nil
        end
        return
    end

    if not tex then
        if reaper.file_exists(tex_path) then
            if reaper.ImGui_CreateImage then
                -- ReaImGui 0.9+ API
                local img = reaper.ImGui_CreateImage(tex_path)
                if reaper.ImGui_Attach then reaper.ImGui_Attach(ctx, img) end
                doc.textures[page_index] = img
            elseif reaper.ImGui_CreateTextureFromFile then
                -- ReaImGui 0.8.x
                local ok, img = pcall(reaper.ImGui_CreateTextureFromFile, ctx, tex_path)
                if not ok or not img then ok, img = pcall(reaper.ImGui_CreateTextureFromFile, tex_path) end
                doc.textures[page_index] = img
            elseif reaper.ImGui_CreateTexture then
                -- Legacy (v0.7 and older)
                local ok, img = pcall(reaper.ImGui_CreateTexture, ctx, tex_path)
                if not ok or not img then ok, img = pcall(reaper.ImGui_CreateTexture, tex_path) end
                doc.textures[page_index] = img
            end
        end
        tex = doc.textures[page_index]
    end
    
    if not tex then 
        reaper.ImGui_Dummy(ctx, draw_w, draw_h)
        return 
    end
    
    local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
    local start_x, start_y = reaper.ImGui_GetCursorScreenPos(ctx)
    local draw_x = start_x + padding
    local draw_y = start_y
    
    reaper.ImGui_SetCursorScreenPos(ctx, draw_x, draw_y)
    
    -- Draw Page Image
    reaper.ImGui_Image(ctx, tex, draw_w, draw_h)
    
    -- Draw Interactive Elements
    for i, item in ipairs(page_data.items or {}) do
        local x = draw_x + (item.x * scale)
        local y = draw_y + (item.y * scale)
        local w = item.w * scale
        local h = item.h * scale
        
        -- Highlight Search Results
        local is_search_match = false
        local is_active_search = false
        if doc.search_open and #doc.search_results > 0 then
            for r_idx, res in ipairs(doc.search_results) do
                if res.page == page_index then
                    -- Phrase support: match if index is within start/end range
                    local in_range = false
                    if res.items and #res.items == 2 then
                        in_range = (i >= res.items[1] and i <= res.items[2])
                    end

                    if in_range then
                        is_search_match = true
                        if r_idx == doc.search_index then
                            is_active_search = true
                        end
                        -- Don't break here, we need to check if it's ALSO an active search 
                        -- (another result might cover this item and NOT be active)
                    end
                end
            end
        end

        if is_active_search then
            reaper.ImGui_DrawList_AddRect(draw_list, x, y, x + w, y + h, 0xFFFF00AA, 0, 0, 3)
        elseif is_search_match then
            reaper.ImGui_DrawList_AddRect(draw_list, x, y, x + w, y + h, 0xFFFF0055, 0, 0, 2)
        end
        
        -- Create invisible button for interaction (only if size is valid)
        if w > 0 and h > 0 then
            reaper.ImGui_SetCursorScreenPos(ctx, x, y)
            reaper.ImGui_InvisibleButton(ctx, "##item_"..page_index.."_"..i, w, h)
            
            -- Trigger Context Menu
            if reaper.ImGui_IsItemHovered(ctx) and reaper.ImGui_IsMouseClicked(ctx, 1) then
                STATE.context_item = item
                STATE.context_doc = doc
                STATE.trigger_context_menu = true
            end
        end
        
        if reaper.ImGui_IsItemHovered(ctx) then
            -- Highlight on hover
            reaper.ImGui_DrawList_AddRect(draw_list, x, y, x + w, y + h, 0x44FFFF88, 0, 0, 2)
            if reaper.ImGui_IsItemClicked(ctx, 0) then -- Left click
                local time = parse_timecode(item.text)
                if time then
                    reaper.SetEditCurPos(time, true, false)
                end
            end
        end
    end
    
    -- Restore cursor position below the image
    reaper.ImGui_SetCursorScreenPos(ctx, start_x, start_y + draw_h)
end

local function draw_gui()
    reaper.ImGui_SetNextWindowSize(ctx, 600, 800, reaper.ImGui_Cond_FirstUseEver())
    
    push_theme(ctx)
    local visible, open = reaper.ImGui_Begin(ctx, 'Subass PDF Reader', true)
    
    if not open or reaper.GetExtState("Subass_Global", "ForceCloseComplementary") == "1" then 
        STATE.window_open = false 
    end
    
    if visible then
        local doc = get_active_doc()

        -- Item Context Menu (Global scope - stable definition)
        reaper.ImGui_PushID(ctx, "GlobalContextScope")
        
        -- Trigger (must be in same scope as BeginPopup)
        if STATE.trigger_context_menu then
            reaper.ImGui_OpenPopup(ctx, "ItemContextMenu")
            STATE.trigger_context_menu = false
        end

        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(), 10, 10)
        if reaper.ImGui_BeginPopup(ctx, "ItemContextMenu") then
            local item = STATE.context_item
            local d = STATE.context_doc
            if item and d then
                local time = parse_timecode(item.text)
                local url = item.url or parse_url(item.text)
                if time then
                    if reaper.ImGui_MenuItem(ctx, "Швидке переміщення на: " .. item.text) then
                        reaper.SetEditCurPos(time, true, false)
                    end
                    reaper.ImGui_Separator(ctx)
                end
                if url then
                    if reaper.ImGui_MenuItem(ctx, "Відкрити посилання") then
                        if reaper.CF_ShellExecute then reaper.CF_ShellExecute(url) end
                    end
                    reaper.ImGui_Separator(ctx)
                end
                if reaper.ImGui_MenuItem(ctx, "Скопіювати") then
                    if reaper.ImGui_SetClipboardText then reaper.ImGui_SetClipboardText(ctx, item.text) end
                end
                if reaper.ImGui_MenuItem(ctx, "Шукати") then
                    d.search_open = true
                    d.search_text = item.text
                    perform_search(d)
                    save_project_state()
                end
                if not time and not url then
                    if reaper.ImGui_MenuItem(ctx, "Переглянути у ГОРОСі") then
                        local dict_word = item.text:gsub("[%p]+$", ""):gsub("^[%p]+", "")
                        reaper.SetExtState("SubassSync", "WORD", dict_word, false)
                        reaper.gmem_write(0, 2)
                        focus_notes_window()
                    end
                end
            end
            reaper.ImGui_EndPopup(ctx)
        end
        reaper.ImGui_PopStyleVar(ctx)
        reaper.ImGui_PopID(ctx)

        -- Header
        if reaper.ImGui_Button(ctx, "Імпортувати PDF") then
            local files = pick_pdf()
            if files then 
                for _, file in ipairs(files) do
                    process_pdf(file) 
                end
            end
        end
        if doc and doc.metadata then
            -- Search Toggle Button
            reaper.ImGui_SameLine(ctx)
            if reaper.ImGui_Button(ctx, "Шукати") then 
                doc.search_open = not doc.search_open
                if not doc.search_open then
                    doc.search_results = {}
                    doc.search_text = ""
                    doc.search_index = 0
                end
                save_project_state()
            end
            
            reaper.ImGui_SameLine(ctx, 0, 20)
            reaper.ImGui_Text(ctx, string.format("Зум: %d%%", math.floor(doc.zoom * 100 + 0.5)))
            reaper.ImGui_SameLine(ctx)
            if reaper.ImGui_Button(ctx, "-", 24, 0) then doc.zoom = math.max(0.1, doc.zoom - 0.1); save_project_state() end
            reaper.ImGui_SameLine(ctx)
            if reaper.ImGui_Button(ctx, "+", 24, 0) then doc.zoom = math.min(5.0, doc.zoom + 0.1); save_project_state() end
            
            -- Right aligned page indicator and menu
            local page_str = string.format("%d / %d", doc.current_page, doc.metadata.page_count)
            local btn_w = 24
            local text_w = reaper.ImGui_CalcTextSize(ctx, page_str)
            local avail_xw = reaper.ImGui_GetContentRegionAvail(ctx)
            
            reaper.ImGui_SameLine(ctx, avail_xw - text_w - btn_w - 5)
            reaper.ImGui_Text(ctx, page_str)
            
            reaper.ImGui_SameLine(ctx)
            if reaper.ImGui_Button(ctx, "≡", btn_w, 0) then
                reaper.ImGui_OpenPopup(ctx, "DocMenu")
            end
            
            if reaper.ImGui_BeginPopup(ctx, "DocMenu") then
                -- List all documents
                for i, d in ipairs(STATE.documents) do
                    local label = truncate_text(d.pdf_name, 50)
                    if reaper.ImGui_MenuItem(ctx, label, nil, i == STATE.active_doc_idx) then
                        switch_to_document(i)
                    end
                end
                
                reaper.ImGui_Separator(ctx)
                if reaper.ImGui_MenuItem(ctx, "Закрити документ") then
                    unload_textures(doc.textures)
                    table.remove(STATE.documents, STATE.active_doc_idx)
                    if #STATE.documents > 0 then
                        STATE.active_doc_idx = math.min(STATE.active_doc_idx, #STATE.documents)
                    else
                        STATE.active_doc_idx = 0
                    end
                    
                    -- Hide search when closing documents
                    doc.search_open = false
                    doc.search_results = {}
                    doc.search_text = ""
                    doc.search_index = 0
                    
                    save_project_state()
                    STATE.status_msg = "Документ закрито"
                end
                reaper.ImGui_EndPopup(ctx)
            end
        end
        
        reaper.ImGui_Separator(ctx)
        
        -- Search Bar Row
        if doc and doc.search_open then
            reaper.ImGui_SetNextItemWidth(ctx, 200)
            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), 0xFFFFFFFF)
            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0x000000FF)
            local changed, new_text = reaper.ImGui_InputTextWithHint(ctx, "##SearchInput", "Шукати...", doc.search_text)
            reaper.ImGui_PopStyleColor(ctx, 2)
            
            if changed then
                doc.search_text = new_text
                perform_search(doc)
                save_project_state()
            end
            
            reaper.ImGui_SameLine(ctx)
            local res_count = doc.search_results and #doc.search_results or 0
            if res_count > 0 then
                reaper.ImGui_Text(ctx, string.format("%d / %d", doc.search_index, res_count))
                reaper.ImGui_SameLine(ctx)
                if reaper.ImGui_Button(ctx, "<", 24, 0) then
                    doc.search_index = doc.search_index - 1
                    if doc.search_index < 1 then doc.search_index = res_count end
                    scroll_to_search(doc.search_results[doc.search_index])
                    save_project_state()
                end
                reaper.ImGui_SameLine(ctx)
                if reaper.ImGui_Button(ctx, ">", 24, 0) then
                    doc.search_index = doc.search_index + 1
                    if doc.search_index > res_count then doc.search_index = 1 end
                    scroll_to_search(doc.search_results[doc.search_index])
                    save_project_state()
                end
            else
                reaper.ImGui_Text(ctx, "0 / 0")
            end
            
            local avail_xw = reaper.ImGui_GetContentRegionAvail(ctx)
            reaper.ImGui_SameLine(ctx, avail_xw - 20)
            if reaper.ImGui_Button(ctx, "X", 24, 0) then
                doc.search_open = false
                doc.search_results = {}
                doc.search_text = ""
                doc.search_index = 0
                save_project_state()
            end
            
            reaper.ImGui_Separator(ctx)
        end

        -- Content Area
        reaper.ImGui_BeginGroup(ctx) -- Start group to catch drops for any item inside
        if STATE.is_loading and STATE.is_loading > 0 then
            reaper.ImGui_Text(ctx, "Обробка... зачекайте, будь ласка.")
            local aw, ah = reaper.ImGui_GetContentRegionAvail(ctx)
            if ah > 0 then reaper.ImGui_InvisibleButton(ctx, "##LoadingTarget", aw, ah) end
        elseif doc and doc.metadata then
            local child_flags = reaper.ImGui_ChildFlags_Border and reaper.ImGui_ChildFlags_Border() or 1
            reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(), 0, 0)
            
            -- Use unique ID per document to avoid scroll bleeding between docs
            local viewer_id = "Viewer_" .. doc.pdf_name
            if reaper.ImGui_BeginChild(ctx, viewer_id, 0, 0, child_flags, reaper.ImGui_WindowFlags_HorizontalScrollbar()) then
                local avail_w = reaper.ImGui_GetContentRegionAvail(ctx)
                for i, page in ipairs(doc.metadata.pages) do
                    draw_page(i, page, avail_w, doc)
                    reaper.ImGui_Dummy(ctx, 0, 10)
                end
                
                -- Robust scroll restoration (retry for several frames as layout stabilizes)
                -- We do this AFTER drawing content so ImGui knows the total height
                if doc.needs_scroll_restore and doc.needs_scroll_restore > 0 then
                    reaper.ImGui_SetScrollY(ctx, doc.scroll_y)
                    doc.needs_scroll_restore = doc.needs_scroll_restore - 1
                    doc.skip_scroll_capture = 30 -- Wait 30 frames after last restore attempt
                end

                -- Capture current scroll for persistence (unless we just restored)
                if not doc.skip_scroll_capture or doc.skip_scroll_capture <= 0 then
                    local current_scroll = reaper.ImGui_GetScrollY(ctx)
                    -- Only capture if we are NOT in restoration mode
                    if not doc.needs_scroll_restore or doc.needs_scroll_restore <= 0 then
                        doc.scroll_y = current_scroll
                    end
                else
                    doc.skip_scroll_capture = doc.skip_scroll_capture - 1
                end

                reaper.ImGui_EndChild(ctx)
            end
            reaper.ImGui_PopStyleVar(ctx)
        else
            reaper.ImGui_Text(ctx, "PDF не завантажено. Натисніть 'Імпортувати PDF'.")
            local aw, ah = reaper.ImGui_GetContentRegionAvail(ctx)
            if ah > 0 then reaper.ImGui_InvisibleButton(ctx, "##EmptyTarget", aw, ah) end
        end
        reaper.ImGui_EndGroup(ctx)

        -- Drag & Drop Target for the content group
        if reaper.ImGui_BeginDragDropTarget(ctx) then
            -- 1. Try to accept the drop (released)
            local dropped, d_count = reaper.ImGui_AcceptDragDropPayloadFiles(ctx)
            if dropped then
                for i = 0, d_count - 1 do
                    local ok, file = reaper.ImGui_GetDragDropPayloadFile(ctx, i)
                    if ok and file ~= "" then
                        process_pdf(file)
                    end
                end
            else
                -- 2. If not dropped, show hover feedback
                local hovered, h_count = reaper.ImGui_AcceptDragDropPayloadFiles(ctx, reaper.ImGui_DragDropFlags_AcceptBeforeDelivery())
                if hovered then
                    reaper.ImGui_SetTooltip(ctx, "Відпустіть файл для імпорту")
                end
            end
            reaper.ImGui_EndDragDropTarget(ctx)
        end
        
        reaper.ImGui_End(ctx)
    end
    pop_theme(ctx)
end

local function init_from_project()
    STATE.current_proj = reaper.EnumProjects(-1)
    if not STATE.current_proj or not reaper.ValidatePtr(STATE.current_proj, "ReaProject*") then return end
    
    local retval_hist, history_json = reaper.GetProjExtState(STATE.current_proj, "Subass_PDF", "doc_history")
    
    local history_data = {}
    if retval_hist > 0 and history_json ~= "" then
        history_data = json_decode(history_json) or {}
    end
    
    -- Fallback for migration from older versions (single string list or just last_pdf)
    if #history_data > 0 and type(history_data[1]) == "string" then
        local old_names = history_data
        history_data = {}
        for _, name in ipairs(old_names) do
            table.insert(history_data, {pdf_name = name})
        end
    elseif #history_data == 0 then
        local r, last_pdf = reaper.GetProjExtState(STATE.current_proj, "Subass_PDF", "last_pdf")
        if r > 0 and last_pdf ~= "" then table.insert(history_data, {pdf_name = last_pdf}) end
    end

    local prj_cache = get_project_cache_dir()

    for _, doc_state in ipairs(history_data) do
        local pdf_name = doc_state.pdf_name
        if prj_cache then
            local output_dir = normalize_path(prj_cache .. "/" .. pdf_name)
            if reaper.file_exists(normalize_path(output_dir .. "/metadata.json")) then
                -- Use silent load (no_switch=true) to avoid overwriting last_pdf state during bulk load
                load_metadata(output_dir, pdf_name, doc_state, true)
            end
        end
    end
    
    -- Set correct active doc from last_pdf
    local retval_last, last_pdf = reaper.GetProjExtState(STATE.current_proj, "Subass_PDF", "last_pdf")
    if retval_last > 0 and last_pdf ~= "" then
        for i, d in ipairs(STATE.documents) do
            if d.pdf_name == last_pdf then
                -- Final switch to the correct last document
                STATE.active_doc_idx = i
                local active = get_active_doc()
                if active then active.needs_scroll_restore = 20 end
                break
            end
        end
    end
end

local function loop()
    -- Check for project tab switch
    local active_proj, proj_fn = reaper.EnumProjects(-1)
    if active_proj ~= STATE.current_proj then
        -- Save state of the project we are leaving
        if STATE.current_proj and reaper.ValidatePtr(STATE.current_proj, "ReaProject*") then
            save_project_state()
        end
        
        -- Project changed, clear everything
        for _, doc in ipairs(STATE.documents) do
            unload_textures(doc.textures)
        end
        STATE.documents = {}
        STATE.active_doc_idx = 0
        STATE.status_msg = "Готово"
        STATE.is_loading = 0
        init_from_project()
    end

    check_async_tasks()
    draw_gui()
    if STATE.window_open then reaper.defer(loop) end
end

reaper.atexit(function()
    save_project_state() -- Flush final scroll positions/zoom
    for _, doc in ipairs(STATE.documents) do
        unload_textures(doc.textures)
    end
end)

init_from_project()
loop()
