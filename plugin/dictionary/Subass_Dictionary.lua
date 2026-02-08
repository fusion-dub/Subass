-- @description Subass Dictionary
-- @version 1.5
-- @author Fusion (Fusion Dub)
-- @about Dictionary of slang, idioms and terminology for dubbing.

local ctx = reaper.ImGui_CreateContext('Subass Dictionary')
local font_main = reaper.ImGui_CreateFont('sans-serif', 15)
local font_tabs = reaper.ImGui_CreateFont('sans-serif', 17)
reaper.ImGui_Attach(ctx, font_main)
reaper.ImGui_Attach(ctx, font_tabs)

-- Initial window size
local WIN_W, WIN_H = 600, 500

-- Tab Persistence
local last_tab = tonumber(reaper.GetExtState("Subass_Dictionary", "last_tab")) or 0
local restore_tab = true

-- Load dictionary data
local script_path = debug.getinfo(1,'S').source:match([[^@?(.*[\/])]])
-- Global ImGui Style
local Style = dofile(script_path .. "Subass_ReaImGuiGlobalStyle.lua")
local data_file = script_path .. "dictionary_data.lua"
local categories = {}
local cached_results = {}
local last_filter = nil

-- Data paths for Glossary
local data_path = script_path .. "data/"
local glossary_file = data_path .. "glossary.json"

-- Simple JSON Helpers
local function json_encode(v)
    if type(v) == "string" then return string.format("%q", v)
    elseif type(v) == "number" or type(v) == "boolean" then return tostring(v)
    elseif type(v) == "table" then
        local is_array = #v > 0
        local parts = {}
        if is_array then
            for _, val in ipairs(v) do table.insert(parts, json_encode(val)) end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            for k, val in pairs(v) do
                table.insert(parts, string.format("%q:%s", tostring(k), json_encode(val)))
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    end
    return "null"
end

local function json_decode(s)
    local pos = 1
    
    local skip_ws = function()
        local next_pos = s:find("[^%s]", pos)
        if next_pos then pos = next_pos end
    end
    
    local parse_val -- forward declaration
    
    local parse_object = function()
        local obj = {}
        pos = pos + 1 -- skip {
        while pos <= #s do
            skip_ws()
            if s:sub(pos, pos) == "}" then pos = pos + 1 return obj end
            
            local key = s:match('^%s*"(.-)"%s*:', pos)
            if not key then break end
            
            pos = s:find(":", pos) + 1
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
            local val = s:match('^"(.-)"', pos)
            if val then 
                pos = pos + #val + 2
                return val
            end
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
    return (ok and res) and res or { entries = {} }
end

local glossary_data = { entries = {} }

local function load_glossary()
    local f = io.open(glossary_file, "r")
    if f then
        local content = f:read("*a")
        f:close()
        glossary_data = json_decode(content)
        if not glossary_data.entries then glossary_data = { entries = {} } end
    end
end

local function save_glossary()
    local f = io.open(glossary_file, "w")
    if f then
        f:write(json_encode(glossary_data))
        f:close()
    end
end

load_glossary()

-- Color Constants (Hex)
local C_BTN_OK = 0x50C850FF
local C_BTN_MEDIUM = 0x4B824BFF
local C_BTN_CLOSE = 0x0000000F
local C_SEL_BG = 0x4CA6FFFF

local function copy_file(src, dst)
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

local function add_from_reaper()
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
                if copy_file(src_path, dst_path) then
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

local add_entry_pending = nil
local edit_entry_idx = nil
local edit_entry_data = {}
local open_edit_popup = false
local current_preview_source = nil
local current_preview_name = ""
local current_preview_file = ""
local current_preview_paused = false
local current_preview_pause_pos = 0
local current_preview_length = 0
local active_tags = {}  -- Set of active tags: { ["tag"] = true }

local function format_time(seconds)
    if not seconds then return "0:00" end
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%d:%02d", mins, secs)
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
                
                table.insert(res, utf8.char(codepoint))
                i = i + seq_len
            else
                table.insert(res, string.char(b))
                i = i + 1
            end
        end
    end
    return table.concat(res)
end

local function load_data()
    local f, err = loadfile(data_file)
    if f then
        categories = f()
    else
        reaper.ShowConsoleMsg("Error loading dictionary data: " .. tostring(err) .. "\n")
        categories = { { name = "Помилка завантаження", entries = {} } }
    end
    last_filter = nil -- Force cache rebuild
end

local function update_search_cache(filter)
    local search_term = utf8_lower(filter)
    cached_results = {}
    
    -- Categories can be an array or a map
    local sorted_categories = {}
    for k, v in pairs(categories) do
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
    cached_results = sorted_categories
    last_filter = filter
end

load_data()

local filter = ""

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
    if not current_preview_source then return end

    local ok_p, pos = reaper.CF_Preview_GetValue(current_preview_source, "D_POSITION")
    local ok_l, len = reaper.CF_Preview_GetValue(current_preview_source, "D_LENGTH")
    local ok_pause, is_paused = reaper.CF_Preview_GetValue(current_preview_source, "B_PAUSE")
    
    -- Check if playback has finished
    if not current_preview_paused and ok_p and ok_l and pos >= len - 0.1 then
        -- Playback finished, auto-pause at the end
        current_preview_pause_pos = 0  -- Reset to beginning for replay
        current_preview_length = len
        if reaper.CF_Preview_Stop then
            reaper.CF_Preview_Stop(current_preview_source)
        end
        current_preview_paused = true
    end
    
    -- Use saved values when paused
    if current_preview_paused then
        pos = current_preview_pause_pos
        len = current_preview_length
    end

    reaper.ImGui_Separator(ctx)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ChildBg(), 0x222222FF)
    
    -- Height 85 (reduced from 100)
    if reaper.ImGui_BeginChild(ctx, "mini_player_ui", 0, 85, 1, reaper.ImGui_WindowFlags_NoScrollbar()) then
        
        -- Left column: Play/Pause button
        local play_icon = current_preview_paused and "▶" or "Ⅱ"
        reaper.ImGui_PushFont(ctx, font_main, 22)
        if reaper.ImGui_Button(ctx, play_icon .. "##playpause", 40, 40) then
            if current_preview_paused then
                -- Resume: recreate preview from file and seek to saved position
                if reaper.PCM_Source_CreateFromFile and reaper.CF_CreatePreview then
                    local source = reaper.PCM_Source_CreateFromFile(current_preview_file)
                    current_preview_source = reaper.CF_CreatePreview(source)
                    if current_preview_pause_pos > 0 then
                        reaper.CF_Preview_SetValue(current_preview_source, "D_POSITION", current_preview_pause_pos)
                    end
                    if reaper.CF_Preview_Play then
                        reaper.CF_Preview_Play(current_preview_source)
                    end
                end
                current_preview_paused = false
            else
                -- Pause: save position, length and stop preview
                current_preview_pause_pos = pos or 0
                current_preview_length = len or 0
                if reaper.CF_Preview_Stop then
                    reaper.CF_Preview_Stop(current_preview_source)
                end
                current_preview_paused = true
            end
        end
        reaper.ImGui_PopFont(ctx)
        
        -- Right column: Name, Progress, Timing (always show, even when paused)
        reaper.ImGui_SameLine(ctx, 0, 14)  -- Add 14px spacing from play button
        reaper.ImGui_SetCursorPosY(ctx, reaper.ImGui_GetCursorPosY(ctx))
        
        reaper.ImGui_BeginGroup(ctx)
            
        -- Name at top (truncated if too long)
        reaper.ImGui_PushFont(ctx, font_main, 13)
        local max_name_width = reaper.ImGui_GetContentRegionAvail(ctx) - 50  -- Leave space for close button
        local name_width = reaper.ImGui_CalcTextSize(ctx, current_preview_name)
        
        if name_width > max_name_width then
            -- Truncate and add ellipsis
            local truncated = current_preview_name
            while reaper.ImGui_CalcTextSize(ctx, truncated .. "...") > max_name_width and #truncated > 0 do
                truncated = truncated:sub(1, -2)
            end
            reaper.ImGui_Text(ctx, truncated .. "...")
        else
            reaper.ImGui_Text(ctx, current_preview_name)
        end
        reaper.ImGui_PopFont(ctx)
        
        -- Progress bar (clickable for seeking)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PlotHistogram(), 0x50C850AA)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), 0x333333FF)
        local progress = (len and len > 0) and pos/len or 0
        local avail_w = reaper.ImGui_GetContentRegionAvail(ctx) - 4  -- Leave space for close button
        
        -- Make progress bar interactive
        local cursor_x, cursor_y = reaper.ImGui_GetCursorScreenPos(ctx)
        reaper.ImGui_ProgressBar(ctx, progress, avail_w, 8, "")
        
        -- Check if progress bar was clicked
        if reaper.ImGui_IsItemClicked(ctx, 0) then
            local mouse_x, mouse_y = reaper.ImGui_GetMousePos(ctx)
            local click_pos = (mouse_x - cursor_x) / avail_w
            click_pos = math.max(0, math.min(1, click_pos))
            local new_time = click_pos * len
            
            if current_preview_paused then
                -- When paused, just update the saved position
                current_preview_pause_pos = new_time
            else
                -- When playing, seek the preview
                if current_preview_source then
                    reaper.CF_Preview_SetValue(current_preview_source, "D_POSITION", new_time)
                end
            end
        end
        
        reaper.ImGui_PopStyleColor(ctx, 2)
        
        -- Timing at bottom
        reaper.ImGui_Text(ctx, string.format("%s / %s", format_time(pos), format_time(len)))
        
        reaper.ImGui_EndGroup(ctx)
        
        -- Close button on the far right
        reaper.ImGui_SameLine(ctx, reaper.ImGui_GetWindowWidth(ctx) - 36)
        reaper.ImGui_SetCursorPosY(ctx, reaper.ImGui_GetCursorPosY(ctx) - 6)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), C_BTN_CLOSE)
        if reaper.ImGui_Button(ctx, "✕", 23, 23) then
            if current_preview_source and reaper.CF_Preview_Stop then
                reaper.CF_Preview_Stop(current_preview_source)
            end
            current_preview_source = nil
            current_preview_name = ""
            current_preview_paused = false
            current_preview_pause_pos = 0
        end
        reaper.ImGui_PopStyleColor(ctx)

        reaper.ImGui_EndChild(ctx)
    end
    reaper.ImGui_PopStyleColor(ctx)
end

local function loop()
    if not ctx then return end

    reaper.ImGui_SetNextWindowSize(ctx, WIN_W, WIN_H, reaper.ImGui_Cond_FirstUseEver())

    -- APPLY GLOBAL STYLE
    Style.push(ctx)

    local visible, open = reaper.ImGui_Begin(ctx, 'Subass Dictionary', true, reaper.ImGui_WindowFlags_NoScrollbar())

    if visible then

        -- TABS
        reaper.ImGui_PushFont(ctx, font_tabs, 17)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), 9, 6)
        local tabs_visible = reaper.ImGui_BeginTabBar(ctx, "DictionaryTabs")

        if tabs_visible then
            -- Reference Tab
            local ref_flags = (restore_tab and last_tab == 0) and reaper.ImGui_TabItemFlags_SetSelected() or 0
            if reaper.ImGui_BeginTabItem(ctx, "Довідник", nil, ref_flags) then
                if not restore_tab and last_tab ~= 0 then
                    last_tab = 0
                    reaper.SetExtState("Subass_Dictionary", "last_tab", "0", true)
                end
                reaper.ImGui_PopFont(ctx)
                reaper.ImGui_PopStyleVar(ctx)

                -- Search inside Tab
                reaper.ImGui_SetNextItemWidth(ctx, -5)
                local changed, new_filter = reaper.ImGui_InputTextWithHint(ctx, '##search_ref', "Пошук у довіднику...", filter)
                if changed then filter = new_filter end
                if filter ~= last_filter then update_search_cache(filter) end
                reaper.ImGui_Separator(ctx)
                reaper.ImGui_Dummy(ctx, 0, 5)
                -- Content
                local child_h = current_preview_source and -95 or -5
                if reaper.ImGui_BeginChild(ctx, "content_reference", 0, child_h) then
                    for _, cat in ipairs(cached_results) do
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

            -- Glossary Tab
            local glos_flags = (restore_tab and last_tab == 1) and reaper.ImGui_TabItemFlags_SetSelected() or 0
            if reaper.ImGui_BeginTabItem(ctx, "Звуковий Глосарій", nil, glos_flags) then
                if not restore_tab and last_tab ~= 1 then
                    last_tab = 1
                    reaper.SetExtState("Subass_Dictionary", "last_tab", "1", true)
                end
                reaper.ImGui_PopFont(ctx)
                reaper.ImGui_PopStyleVar(ctx)

                -- Search and Add on one line (Increased height)
                reaper.ImGui_SetNextItemWidth(ctx, -145)
                reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), 9, 8) -- Increased padding for taller input
                local changed, new_filter = reaper.ImGui_InputTextWithHint(ctx, '##search_glos', "Пошук у глосарії...", filter)
                if changed then filter = new_filter end
                
                reaper.ImGui_SameLine(ctx)
                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), C_BTN_MEDIUM)
                if reaper.ImGui_Button(ctx, "Додати з REAPER", 135) then
                    local new_entry = add_from_reaper()
                    if new_entry then
                        add_entry_pending = new_entry
                        reaper.ImGui_OpenPopup(ctx, "GlossaryMetadata")
                    end
                end
                reaper.ImGui_PopStyleColor(ctx)
                reaper.ImGui_PopStyleVar(ctx) -- Pop FramePadding for search/add bar
                -- Quick Tags
                local all_tags = {}
                local tag_map = {}
                for _, entry in ipairs(glossary_data.entries) do
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
                        local is_active = active_tags[tag]
                        
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
                                active_tags[tag] = nil -- Toggle off
                            else
                                active_tags[tag] = true -- Toggle on
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

                local child_h = current_preview_source and -95 or -5
                if reaper.ImGui_BeginChild(ctx, "content_glossary", 0, child_h) then

                    -- Glossary List
                    for i, entry in ipairs(glossary_data.entries) do
                        local match = true
                        
                        -- 1. Check text filter
                        if filter ~= "" then
                            local s = utf8_lower(filter)
                            if not (utf8_lower(entry.name):find(s, 1, true) or utf8_lower(entry.tags):find(s, 1, true) or utf8_lower(entry.desc):find(s, 1, true)) then
                                match = false
                            end
                        end
                        
                        -- 2. Check tag filter (ALL selected tags must be present)
                        if match then
                            for needed_tag, _ in pairs(active_tags) do
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
                                local play_icon = (current_preview_name == entry.name and not current_preview_paused) and "Ⅱ" or "▶"
                                
                                -- Play/Pause Logic (Extraction)
                                local function toggle_playback()
                                    local full_path = data_path .. entry.filename
                                    
                                    -- If same file is playing: toggle pause
                                    if current_preview_name == entry.name and current_preview_source then
                                        if current_preview_paused then
                                            -- Resume
                                            if reaper.PCM_Source_CreateFromFile and reaper.CF_CreatePreview then
                                                local source = reaper.PCM_Source_CreateFromFile(current_preview_file)
                                                current_preview_source = reaper.CF_CreatePreview(source)
                                                if current_preview_pause_pos > 0 then
                                                    reaper.CF_Preview_SetValue(current_preview_source, "D_POSITION", current_preview_pause_pos)
                                                end
                                                if reaper.CF_Preview_Play then reaper.CF_Preview_Play(current_preview_source) end
                                            end
                                            current_preview_paused = false
                                        else
                                            -- Pause
                                            local ok_p, pos = reaper.CF_Preview_GetValue(current_preview_source, "D_POSITION")
                                            local ok_l, len = reaper.CF_Preview_GetValue(current_preview_source, "D_LENGTH")
                                            
                                            current_preview_pause_pos = pos or 0
                                            current_preview_length = len or 0
                                            if reaper.CF_Preview_Stop then reaper.CF_Preview_Stop(current_preview_source) end
                                            current_preview_paused = true
                                        end
                                    else
                                        -- Play new file
                                        current_preview_name = entry.name
                                        current_preview_file = full_path
                                        current_preview_paused = false
                                        current_preview_pause_pos = 0
                                        if current_preview_source then
                                            if reaper.CF_Preview_Stop then reaper.CF_Preview_Stop(current_preview_source) end
                                        end
                                        if reaper.PCM_Source_CreateFromFile and reaper.CF_CreatePreview then
                                            local source = reaper.PCM_Source_CreateFromFile(full_path)
                                            current_preview_source = reaper.CF_CreatePreview(source)
                                            if reaper.CF_Preview_Play then reaper.CF_Preview_Play(current_preview_source) end
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
                                            save_glossary()
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
                                        edit_entry_idx = i
                                        edit_entry_data = {
                                            name = entry.name,
                                            tags = entry.tags,
                                            desc = entry.desc
                                        }
                                        open_edit_popup = true
                                    end
                                    
                                    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xFF5050FF)
                                    if reaper.ImGui_Selectable(ctx, "× Видалити") then
                                        if reaper.MB("Видалити цей звук?", "Підтвердження", 1) == 1 then
                                            os.remove(data_path .. entry.filename)
                                            table.remove(glossary_data.entries, i)
                                            save_glossary()
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
                    if open_edit_popup then
                        reaper.ImGui_OpenPopup(ctx, "EditGlossary")
                        open_edit_popup = false
                    end
                    if reaper.ImGui_BeginPopupModal(ctx, "GlossaryMetadata", nil, reaper.ImGui_WindowFlags_AlwaysAutoResize()) then
                        reaper.ImGui_Text(ctx, "Налаштування нового звуку:")
                        reaper.ImGui_Dummy(ctx, 0, 5)
                        
                        _, add_entry_pending.name = reaper.ImGui_InputText(ctx, "Назва", add_entry_pending.name)
                        _, add_entry_pending.tags = reaper.ImGui_InputText(ctx, "Теги (через кому)", add_entry_pending.tags)
                        _, add_entry_pending.desc = reaper.ImGui_InputTextMultiline(ctx, "Опис", add_entry_pending.desc, 300, 100)
                        
                        reaper.ImGui_Dummy(ctx, 0, 10)
                        if reaper.ImGui_Button(ctx, "Зберегти", 120) then
                            table.insert(glossary_data.entries, add_entry_pending)
                            save_glossary()
                            add_entry_pending = nil
                            reaper.ImGui_CloseCurrentPopup(ctx)
                        end
                        reaper.ImGui_SameLine(ctx)
                        if reaper.ImGui_Button(ctx, "Скасувати", 120) then
                            os.remove(data_path .. add_entry_pending.filename)
                            add_entry_pending = nil
                            reaper.ImGui_CloseCurrentPopup(ctx)
                        end
                        reaper.ImGui_EndPopup(ctx)
                    end

                    if reaper.ImGui_BeginPopupModal(ctx, "EditGlossary", nil, reaper.ImGui_WindowFlags_AlwaysAutoResize()) then
                        reaper.ImGui_Text(ctx, "Редагування:")
                        reaper.ImGui_Dummy(ctx, 0, 5)
                        
                        _, edit_entry_data.name = reaper.ImGui_InputText(ctx, "Назва", edit_entry_data.name)
                        _, edit_entry_data.tags = reaper.ImGui_InputText(ctx, "Теги", edit_entry_data.tags)
                        _, edit_entry_data.desc = reaper.ImGui_InputTextMultiline(ctx, "Опис", edit_entry_data.desc, 300, 100)
                        
                        reaper.ImGui_Dummy(ctx, 0, 10)
                        if reaper.ImGui_Button(ctx, "Зберегти", 120) then
                            glossary_data.entries[edit_entry_idx].name = edit_entry_data.name
                            glossary_data.entries[edit_entry_idx].tags = edit_entry_data.tags
                            glossary_data.entries[edit_entry_idx].desc = edit_entry_data.desc
                            save_glossary()
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

            reaper.ImGui_EndTabBar(ctx)
            restore_tab = false
        end
        reaper.ImGui_PopStyleVar(ctx)
        reaper.ImGui_PopFont(ctx)

        draw_mini_player(ctx)

        reaper.ImGui_End(ctx)
    end

    -- POP GLOBAL STYLE
    Style.pop(ctx)

    if open and reaper.GetExtState("Subass_Global", "ForceCloseComplementary") ~= "1" then
        reaper.defer(loop)
    end
end

reaper.defer(loop)
