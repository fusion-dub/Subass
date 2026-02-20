-- @description Subass PDF Reader (ReaImGui PDF Module)
-- @version 1.1
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
local python_script = script_path .. "subass_pdf_processor.py"

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
    pdf_path = "",
    cache_dir = "",
    metadata = nil,
    current_page = 1,
    textures = {},
    is_loading = false,
    status_msg = "Готово",
    window_open = true,
    show_debug_boxes = false,
    async_pool = {},
    zoom = 1.0,
    current_proj = nil,
    search_open = false,
    search_text = "",
    search_results = {},
    search_index = 0,
    scroll_to_search = false
}

-- =============================================================================
-- UTILS
-- =============================================================================

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
        f_bat:write('set _self=%~f0\r\n')
        f_bat:write('cmd /c ping 127.0.0.1 -n 2 > NUL & del "%_self%"\r\n')
        f_bat:close()

        local ps_cmd = 'powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "Start-Process \\\"' .. bat_file .. '\\\" -WindowStyle Hidden"'
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
    local cache = prj_path .. "/subass_pdf_cache"
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

local function perform_search()
    STATE.search_results = {}
    STATE.search_index = 0
    if not STATE.search_text or STATE.search_text == "" then return end
    
    local query = STATE.search_text:lower()
    for p_idx, page in ipairs(STATE.metadata.pages) do
        for i_idx, item in ipairs(page.items or {}) do
            if item.text and item.text:lower():find(query, 1, true) then
                table.insert(STATE.search_results, {page = p_idx, item = i_idx})
            end
        end
    end
    if #STATE.search_results > 0 then
        STATE.search_index = 1
        STATE.scroll_to_search = true
    end
end

-- =============================================================================
-- PDF ENGINE & CACHE
-- =============================================================================
local function load_metadata(output_dir, pdf_name)
    local f = io.open(output_dir .. "/metadata.json", "r")
    if f then
        STATE.metadata = json_decode(f:read("*all"))
        f:close()
        STATE.cache_dir = output_dir
        STATE.status_msg = "Завантажено: " .. pdf_name
        STATE.current_page = 1
        
        -- Save to project state so it auto-loads next time
        reaper.SetProjExtState(0, "Subass_PDF", "last_pdf", pdf_name)
        return true
    end
    return false
end

local function process_pdf(pdf_file)
    STATE.is_loading = true
    STATE.status_msg = "Обробка PDF..."
    
    local prj_cache = get_project_cache_dir()
    if not prj_cache then
        reaper.ShowMessageBox("Спочатку збережіть ваш проект!", "Помилка", 0)
        STATE.is_loading = false
        return
    end
    
    -- Clear old textures safely
    for _, tex in pairs(STATE.textures) do 
        if reaper.ImGui_Detach then pcall(reaper.ImGui_Detach, ctx, tex) end
        if reaper.ImGui_DeleteTexture then pcall(reaper.ImGui_DeleteTexture, tex) end
    end
    STATE.textures = {}
    
    local pdf_name = pdf_file:match("([^/\\]+)%.pdf$") or "temp_pdf"
    local output_dir = prj_cache .. "/" .. pdf_name
    reaper.RecursiveCreateDirectory(output_dir, 0)
    
    local cmd = string.format('python3 "%s" "%s" "%s"', python_script, pdf_file, output_dir)
    if reaper.GetOS():match("Win") then cmd = string.format('python "%s" "%s" "%s"', python_script, pdf_file, output_dir) end
    
    run_async_command(cmd, function(output)
        if not load_metadata(output_dir, pdf_name) then
            STATE.status_msg = "Помилка завантаження метаданих"
        end
        STATE.is_loading = false
    end)
end

local function pick_pdf()
    if reaper.APIExists('JS_Dialog_BrowseForOpenFiles') then
        local retval, file = reaper.JS_Dialog_BrowseForOpenFiles("Оберіть PDF", "", "", "PDF файли (*.pdf)\0*.pdf\0Всі файли (*.*)\0*.*\0", false)
        if retval > 0 and file ~= "" then return file end
    else
        local retval, file = reaper.GetUserInputs("Імпорт PDF", 1, "Повний шлях до PDF:", "")
        if retval and file ~= "" then return file end
    end
    return nil
end

-- =============================================================================
-- DRAWING
-- =============================================================================
local function draw_page(page_index, page_data, avail_w)
    local tex_path = STATE.cache_dir .. "/" .. page_data.image
    local tex = STATE.textures[page_index]
    
    local tw, th = page_data.width * 2, page_data.height * 2
    if tex and reaper.ImGui_Image_GetSize then
        local ok, w_sz, h_sz = pcall(reaper.ImGui_Image_GetSize, tex)
        if ok and type(w_sz) == "number" then tw, th = w_sz, h_sz end
    end
    
    local padding = 0
    local scale = ((avail_w - padding * 2) / (page_data.width or tw/2)) * STATE.zoom
    local draw_w = (page_data.width or tw/2) * scale
    local draw_h = (page_data.height or th/2) * scale
    
    -- Track current visible page
    local cursor_y = reaper.ImGui_GetCursorPosY(ctx)
    local scroll_y = reaper.ImGui_GetScrollY(ctx)
    local win_h = reaper.ImGui_GetWindowHeight(ctx)
    local view_center = scroll_y + (win_h / 2)
    
    if view_center >= cursor_y and view_center <= (cursor_y + draw_h) then
        STATE.current_page = page_index
    end
    
    -- Handle scrolling to search result even if page is off-screen
    if STATE.scroll_to_search and STATE.search_open and #STATE.search_results > 0 then
        local active_res = STATE.search_results[STATE.search_index]
        if active_res and active_res.page == page_index then
            local item = page_data.items and page_data.items[active_res.item]
            if item then
                local target_y = cursor_y + (item.y * scale)
                reaper.ImGui_SetScrollY(ctx, target_y - (win_h / 2))
                STATE.scroll_to_search = false
            end
        end
    end

    -- Visibility Check for Lazy Loading
    if not reaper.ImGui_IsRectVisible(ctx, draw_w, draw_h) then
        reaper.ImGui_Dummy(ctx, draw_w, draw_h)
        -- Unload texture if it goes out of view to save memory
        if tex then
            if reaper.ImGui_Detach then pcall(reaper.ImGui_Detach, ctx, tex) end
            if reaper.ImGui_DeleteTexture then pcall(reaper.ImGui_DeleteTexture, tex) end
            STATE.textures[page_index] = nil
        end
        return
    end

    if not tex then
        if reaper.file_exists(tex_path) then
            if reaper.ImGui_CreateImage then
                -- ReaImGui 0.9+ API
                local img = reaper.ImGui_CreateImage(tex_path)
                if reaper.ImGui_Attach then reaper.ImGui_Attach(ctx, img) end
                STATE.textures[page_index] = img
            elseif reaper.ImGui_CreateTextureFromFile then
                -- ReaImGui 0.8.x
                local ok, img = pcall(reaper.ImGui_CreateTextureFromFile, ctx, tex_path)
                if not ok or not img then ok, img = pcall(reaper.ImGui_CreateTextureFromFile, tex_path) end
                STATE.textures[page_index] = img
            elseif reaper.ImGui_CreateTexture then
                -- Legacy (v0.7 and older)
                local ok, img = pcall(reaper.ImGui_CreateTexture, ctx, tex_path)
                if not ok or not img then ok, img = pcall(reaper.ImGui_CreateTexture, tex_path) end
                STATE.textures[page_index] = img
            end
        end
        tex = STATE.textures[page_index]
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
        if STATE.search_open and #STATE.search_results > 0 then
            for r_idx, res in ipairs(STATE.search_results) do
                if res.page == page_index and res.item == i then
                    is_search_match = true
                    if r_idx == STATE.search_index then
                        is_active_search = true
                    end
                    break
                end
            end
        end

        if is_active_search then
            reaper.ImGui_DrawList_AddRect(draw_list, x, y, x + w, y + h, 0xFFFF00FF, 0, 0, 3)
        elseif is_search_match then
            reaper.ImGui_DrawList_AddRect(draw_list, x, y, x + w, y + h, 0xFFFF0088, 0, 0, 2)
        end
        
        -- Create invisible button for interaction
        reaper.ImGui_SetCursorScreenPos(ctx, x, y)
        reaper.ImGui_InvisibleButton(ctx, "##item_"..page_index.."_"..i, w, h)
        
        -- Context Menu on Right Click (Item 1 = default right click)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(), 10, 10)
        local ctx_open = reaper.ImGui_BeginPopupContextItem(ctx, "##CtxMenu"..page_index.."_"..i, 1)
        reaper.ImGui_PopStyleVar(ctx)
        
        if ctx_open then
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
                    if reaper.CF_ShellExecute then
                        reaper.CF_ShellExecute(url)
                    end
                end
                reaper.ImGui_Separator(ctx)
            end
            
            if reaper.ImGui_MenuItem(ctx, "Скопіювати") then
                if reaper.ImGui_SetClipboardText then
                    reaper.ImGui_SetClipboardText(ctx, item.text)
                end
            end
            if reaper.ImGui_MenuItem(ctx, "Шукати") then
                STATE.search_open = true
                STATE.search_text = item.text
                perform_search()
            end
            reaper.ImGui_EndPopup(ctx)
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
    
    if not open then STATE.window_open = false end
    
    if visible then
        -- Header
        if reaper.ImGui_Button(ctx, "Імпортувати PDF") then
            local file = pick_pdf()
            if file then process_pdf(file) end
        end
        if STATE.metadata then
            -- Search Toggle Button
            reaper.ImGui_SameLine(ctx)
            if reaper.ImGui_Button(ctx, "Шукати") then 
                STATE.search_open = not STATE.search_open
                if not STATE.search_open then
                    STATE.search_results = {}
                    STATE.search_text = ""
                    STATE.search_index = 0
                end
            end
            
            reaper.ImGui_SameLine(ctx, 0, 20)
            reaper.ImGui_Text(ctx, string.format("Зум: %d%%", math.floor(STATE.zoom * 100 + 0.5)))
            reaper.ImGui_SameLine(ctx)
            if reaper.ImGui_Button(ctx, "-", 24, 0) then STATE.zoom = math.max(0.1, STATE.zoom - 0.1) end
            reaper.ImGui_SameLine(ctx)
            if reaper.ImGui_Button(ctx, "+", 24, 0) then STATE.zoom = math.min(5.0, STATE.zoom + 0.1) end
            
            -- Right aligned page indicator
            local page_str = string.format("%d / %d", STATE.current_page, STATE.metadata.page_count)
            local text_w = reaper.ImGui_CalcTextSize(ctx, page_str)
            local avail_xw = reaper.ImGui_GetContentRegionAvail(ctx)
            reaper.ImGui_SameLine(ctx, avail_xw - text_w)
            reaper.ImGui_Text(ctx, page_str)
        end
        
        reaper.ImGui_Separator(ctx)
        
        -- Search Bar Row
        if STATE.search_open then
            reaper.ImGui_SetNextItemWidth(ctx, 200)
            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), 0xFFFFFFFF)
            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0x000000FF)
            local changed, new_text = reaper.ImGui_InputTextWithHint(ctx, "##SearchInput", "Шукати...", STATE.search_text)
            reaper.ImGui_PopStyleColor(ctx, 2)
            
            if changed then
                STATE.search_text = new_text
                perform_search()
            end
            
            reaper.ImGui_SameLine(ctx)
            local res_count = #STATE.search_results
            if res_count > 0 then
                reaper.ImGui_Text(ctx, string.format("%d / %d", STATE.search_index, res_count))
                reaper.ImGui_SameLine(ctx)
                if reaper.ImGui_Button(ctx, "<", 24, 0) then
                    STATE.search_index = STATE.search_index - 1
                    if STATE.search_index < 1 then STATE.search_index = res_count end
                    STATE.scroll_to_search = true
                end
                reaper.ImGui_SameLine(ctx)
                if reaper.ImGui_Button(ctx, ">", 24, 0) then
                    STATE.search_index = STATE.search_index + 1
                    if STATE.search_index > res_count then STATE.search_index = 1 end
                    STATE.scroll_to_search = true
                end
            else
                reaper.ImGui_Text(ctx, "0 / 0")
            end
            
            local avail_xw = reaper.ImGui_GetContentRegionAvail(ctx)
            reaper.ImGui_SameLine(ctx, avail_xw - 24)
            if reaper.ImGui_Button(ctx, "X", 24, 0) then
                STATE.search_open = false
                STATE.search_results = {}
                STATE.search_text = ""
                STATE.search_index = 0
            end
            
            reaper.ImGui_Separator(ctx)
        end
        
        -- Content Area
        if STATE.is_loading then
            reaper.ImGui_Text(ctx, "Обробка... зачекайте, будь ласка.")
        elseif STATE.metadata then
            local child_flags = reaper.ImGui_ChildFlags_Border and reaper.ImGui_ChildFlags_Border() or 1
            reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(), 0, 0)
            reaper.ImGui_BeginChild(ctx, "Viewer", 0, 0, child_flags, reaper.ImGui_WindowFlags_HorizontalScrollbar())
            
            local avail_w = reaper.ImGui_GetContentRegionAvail(ctx)
            
            for i, page in ipairs(STATE.metadata.pages) do
                draw_page(i, page, avail_w)
                reaper.ImGui_Dummy(ctx, 0, 10)
            end
            
            reaper.ImGui_EndChild(ctx)
            reaper.ImGui_PopStyleVar(ctx)
        else
            reaper.ImGui_Text(ctx, "PDF не завантажено. Натисніть 'Імпортувати PDF'.")
        end
        
        reaper.ImGui_End(ctx)
    end
    pop_theme(ctx)
end

local function init_from_project()
    STATE.current_proj = reaper.EnumProjects(-1)
    
    local prj_cache = get_project_cache_dir()
    if not prj_cache then return end
    
    local retval, last_pdf = reaper.GetProjExtState(0, "Subass_PDF", "last_pdf")
    if retval > 0 and last_pdf ~= "" then
        local output_dir = prj_cache .. "/" .. last_pdf
        if reaper.file_exists(output_dir .. "/metadata.json") then
            load_metadata(output_dir, last_pdf)
        end
    end
end

local function loop()
    -- Check for project tab switch
    local active_proj = reaper.EnumProjects(-1)
    if active_proj ~= STATE.current_proj then
        -- Project changed, clear view and try to load new state
        for _, tex in pairs(STATE.textures) do 
            if reaper.ImGui_Detach then pcall(reaper.ImGui_Detach, ctx, tex) end
            if reaper.ImGui_DeleteTexture then pcall(reaper.ImGui_DeleteTexture, tex) end
        end
        STATE.textures = {}
        STATE.metadata = nil
        STATE.cache_dir = ""
        STATE.status_msg = "Готово"
        STATE.is_loading = false
        init_from_project()
    end

    check_async_tasks()
    draw_gui()
    if STATE.window_open then reaper.defer(loop) end
end

init_from_project()
loop()
