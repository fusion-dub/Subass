-- @description Lionzz Sub Overlay (Subass)
-- @version 0.0.5
-- @author Lionzz + Fusion (Fusion Dub)

if not reaper.ImGui_CreateContext then
    reaper.ShowMessageBox("ReaImGui не знайдено. Встановіть ReaImGui.", "Помилка", 0)
    return
end

local ctx = reaper.ImGui_CreateContext("Lionzz Sub Overlay Subass")
local win_X, win_Y, win_w, win_h = 500, 500, 500, 300
local win_open = true
local close_requested = false

-- Простий кеш для оптимізації
local last_pos = nil
local last_proj_change_count = 0
local cached_current, cached_next, cached_start, cached_stop = nil, nil, nil, nil

-- Кеш координат відевікна
local video_cache_valid = false
local cached_video_x1, cached_video_y1, cached_video_x2, cached_video_y2 = nil, nil, nil, nil
local cached_attach_x, cached_attach_y, cached_attach_w = nil, nil, nil
local is_user_resizing = false  -- прапорець для відстеження ресайзу користувачем
local show_wrap_guides = false  -- прапорець для відображення напрямних відступу переносу


-- Налаштування шрифту та масштабу
local BASE_FONT_SIZE = 14 -- base creation size
local is_mac = reaper.GetOS():match("OSX") or reaper.GetOS():match("macOS")
local available_fonts = {
    "Arial","Helvetica","Calibri","Roboto","Segoe UI","Tahoma","Verdana",
    "Cambria","Georgia","Times New Roman",
    "Consolas","Courier New", "Comic Sans MS"
}
local font_objects = {}

-- Load fonts
for i, name in ipairs(available_fonts) do
    local f = reaper.ImGui_CreateFont(name, 14)
    font_objects[i] = f
    reaper.ImGui_Attach(ctx, f)
end

local ui_font = font_objects[1]         -- перший шрифт завжди для UI
local UI_FONT_SCALE = 14                -- фіксований масштаб для інтерфейсу
local CONTEXT_MENU_MIN_WIDTH = 200      -- мінімальна ширина контекстного меню
local next_region_offset = 20           -- відступ між поточним та наступним регіоном
local show_progress = false              -- показувати прогрес-бар
local progress_width = 400              -- ширина за замовчуванням
local progress_height = 4               -- висота за замовчуванням
local progress_offset = 20              -- відступ від першого рядка
local padding_x = 6                     -- відступи для фону під текстом
local padding_y = 3                     -- відступи для фону під текстом
local current_font_index = 1            -- номер шрифту
local font_scale = 30                   -- розмір шрифту
local text_color   = 0xFFBB00FF         -- колір тексту
local shadow_color = 0x000000FF         -- колір тіні
local second_font_index = 1             -- номер шрифту для другого рядка
local second_font_scale = 22            -- розмір другого рядка
local second_text_color = 0x99BB22FF    -- колір другого рядка
local second_shadow_color = 0x000000FF  -- колір тіні другого рядка
local source_mode = nil                 -- 0 = регіони, >0 = номер трека з ітемами
local window_bg_color = 0x00000088      -- чорний з прозорістю
local border = false                    -- малювати фон під текстом
local enable_wrap = true                -- переносити текст по словах
local wrap_margin = 0                   -- відступ від краю вікна для автопереносу (пікселі)
local enable_second_line = true         -- показувати другий рядок
local align_center = true               -- вирівнювання по центру (горизонтально, за замовчуванням увімкн.)
local align_vertical = false            -- вирівнювання по вертикалі (центрування контенту у вікні)
local align_bottom = true              -- вирівнювання по низу
local show_assimilation = true         -- показувати асиміляцію (незалежно від Subass Notes)
local always_show_next = true          -- завжди показувати наступну репліку (навіть у прогалинах)
local fill_gaps = false                  -- показувати найближчий регіон/ітем між об'єктами
local show_tooltips = true              -- показувати підказки
local tooltip_delay = 0.5
local tooltip_state = {}
local attach_to_video = false           -- прив'язувати до відеовікна
local attach_offset = 0                 -- відступ у відсотках (0-100)
local attach_manual_x = 0               -- ручна корекція X (пікселі)
local attach_manual_y = 0               -- ручна корекція Y (пікселі)
local invert_y_axis = false             -- інвертувати вісь Y (для macOS)
local ignore_newlines = false           -- ігнорувати символи переносу рядка при читанні
local word_hold = { start_time = 0, word = "", triggered = false }
local last_window_click = 0

reaper.gmem_attach("SubassSync") -- Shared memory for lightning-fast sync

local flags = {
    NoTitle = false,
    NoResize = false,
    NoDocking = false,
    HideBackground = false,
    NoMove = false
}

-- ==========================
-- БЛОК ФУНКЦІЙ
-- ==========================

-- Зберігаємо/завантажуємо налаштування
local SETTINGS_SECTION = "LionzzSubOverlaySubass"

-- ==========================
-- TEXT PROCESSING HELPERS
-- ==========================

--- Convert codepoint to UTF-8 string
local function utf8_char(cp)
    if not cp then return "" end
    if cp <= 127 then return string.char(cp) end
    local res = ""
    if cp <= 2047 then
        res = string.char(192 + math.floor(cp / 64)) .. string.char(128 + (cp % 64))
    elseif cp <= 65535 then
        res = string.char(224 + math.floor(cp / 4096)) .. string.char(128 + (math.floor(cp / 64) % 64)) .. string.char(128 + (cp % 64))
    elseif cp <= 1114111 then
        res = string.char(240 + math.floor(cp / 262144)) .. string.char(128 + (math.floor(cp / 4096) % 64)) .. string.char(128 + (math.floor(cp / 64) % 64)) .. string.char(128 + (cp % 64))
    end
    return res
end

local function utf8_lower(s)
    if not s then return "" end
    local res = {}
    local len = #s
    local i = 1
    while i <= len do
        local b = s:byte(i)
        if b < 128 then
            if b >= 65 and b <= 90 then table.insert(res, string.char(b + 32)) else table.insert(res, string.char(b)) end
            i = i + 1
        else
            local seq_len = 0
            if b >= 240 then seq_len = 4 elseif b >= 224 then seq_len = 3 elseif b >= 192 then seq_len = 2 end
            if seq_len > 0 and i + seq_len - 1 <= len then
                local codepoint = 0
                if seq_len == 2 then codepoint = ((b & 31) << 6) | (s:byte(i+1) & 63)
                elseif seq_len == 3 then codepoint = ((b & 15) << 12) | ((s:byte(i+1) & 63) << 6) | (s:byte(i+2) & 63)
                elseif seq_len == 4 then codepoint = ((b & 7) << 18) | ((s:byte(i+1) & 63) << 12) | ((s:byte(i+2) & 63) << 6) | (s:byte(i+3) & 63) end
                
                if codepoint >= 1040 and codepoint <= 1071 then codepoint = codepoint + 32 
                elseif codepoint == 1025 then codepoint = 1105 elseif codepoint == 1028 then codepoint = 1108
                elseif codepoint == 1030 then codepoint = 1110 elseif codepoint == 1031 then codepoint = 1111
                elseif codepoint == 1168 then codepoint = 1169 end
                table.insert(res, utf8_char(codepoint))
                i = i + seq_len
            else
                table.insert(res, string.char(b))
                i = i + 1
            end
        end
    end
    return table.concat(res)
end

local function utf8_upper(s)
    if not s then return "" end
    local res = {}
    local len = #s
    local i = 1
    while i <= len do
        local b = s:byte(i)
        if b < 128 then
            if b >= 97 and b <= 122 then table.insert(res, string.char(b - 32)) else table.insert(res, string.char(b)) end
            i = i + 1
        else
            local seq_len = 0
            if b >= 240 then seq_len = 4 elseif b >= 224 then seq_len = 3 elseif b >= 192 then seq_len = 2 end
            if seq_len > 0 and i + seq_len - 1 <= len then
                local codepoint = 0
                if seq_len == 2 then codepoint = ((b & 31) << 6) | (s:byte(i+1) & 63)
                elseif seq_len == 3 then codepoint = ((b & 15) << 12) | ((s:byte(i+1) & 63) << 6) | (s:byte(i+2) & 63)
                elseif seq_len == 4 then codepoint = ((b & 7) << 18) | ((s:byte(i+1) & 63) << 12) | ((s:byte(i+2) & 63) << 6) | (s:byte(i+3) & 63) end
                
                if codepoint >= 1072 and codepoint <= 1103 then codepoint = codepoint - 32
                elseif codepoint == 1105 then codepoint = 1025 elseif codepoint == 1108 then codepoint = 1028
                elseif codepoint == 1110 then codepoint = 1030 elseif codepoint == 1111 then codepoint = 1031
                elseif codepoint == 1169 then codepoint = 1168 end
                table.insert(res, utf8_char(codepoint))
                i = i + seq_len
            else
                table.insert(res, string.char(b))
                i = i + 1
            end
        end
    end
    return table.concat(res)
end

local function utf8_capitalize(s)
    if not s or s == "" then return "" end
    local b = s:byte(1)
    local seq_len = 1
    if b >= 240 then seq_len = 4 elseif b >= 224 then seq_len = 3 elseif b >= 192 then seq_len = 2 end
    return utf8_upper(s:sub(1, seq_len)) .. s:sub(seq_len + 1)
end

local function get_words_and_separators(text)
    local result = {}
    local pos = 1
    local pattern = "[%a\128-\255\'%-]+[\128-\255]*"
    while pos <= #text do
        local s, e = text:find(pattern, pos)
        if s then
            if s > pos then table.insert(result, {text = text:sub(pos, s-1), is_word = false}) end
            table.insert(result, {text = text:sub(s, e), is_word = true})
            pos = e + 1
        else
            table.insert(result, {text = text:sub(pos), is_word = false})
            break
        end
    end
    return result
end

local assimilation_rules = {
    {"ться", "цця"}, {"зш", "шш"}, {"сш", "шш"}, {"зч", "чч"}, {"стч", "шч"},
    {"сч", "чч"}, {"тч", "чч"}, {"дч", "чч"}, {"шся", "сся"}, {"чся", "цся"},
    {"зж", "жж"}, {"чці", "цці"}, {"жці", "зці"}, {"стд", "зд"}, {"стці", "сці"},
    {"нтст", "нст"}, {"стськ", "сськ"}, {"нтськ", "нськ"}, {"стс", "сс"}, {"тс", "ц"}
}

local function apply_assimilation_recursive(text, offset)
    offset = offset or 0
    if text == "" then return "", {} end
    local l_text = utf8_lower(text)
    local best_pos, best_rule = nil, nil
    
    for _, r in ipairs(assimilation_rules) do
        local p = l_text:find(r[1], 1, true)
        if p then
            if not best_pos or p < best_pos then
                best_pos = p
                best_rule = r
            end
        end
    end
    
    if best_pos then
        local before = text:sub(1, best_pos - 1)
        local match_len = #best_rule[1]
        local original_match = text:sub(best_pos, best_pos + match_len - 1)
        local remainder = text:sub(best_pos + match_len)
        
        local replacement = best_rule[2]
        if original_match == utf8_upper(original_match) then
            replacement = utf8_upper(replacement)
        elseif original_match == utf8_capitalize(utf8_lower(original_match)) then
            replacement = utf8_capitalize(replacement)
        end
        
        local current_ranges = { {start_idx = offset + #before + 1, stop_idx = offset + #before + #replacement} }
        
        local final_remainder, remainder_ranges = apply_assimilation_recursive(remainder, offset + #before + #replacement)
        
        -- Merge ranges
        for _, rg in ipairs(remainder_ranges) do
            table.insert(current_ranges, rg)
        end
        
        return before .. replacement .. final_remainder, current_ranges
    else
        return text, {}
    end
end

--- Merge two comments with dash prefixes and newline separation
--- @param old string|nil Previous comment
--- @param new string Current comment
--- @return string Merged comment
local function merge_comments(old, new)
    if not new or new == "" then return old end
    local s2 = new:gsub("^%s+", ""):gsub("%s+$", "")
    if s2 == "" then return old end
    
    if not old or old == "" then return s2 end
    local s1 = old:gsub("^%s+", ""):gsub("%s+$", "")
    
    if not s1:match("^%-") then s1 = "-" .. s1 end
    if not s2:match("^%-") then s2 = "-" .. s2 end
    
    return s1 .. "\n" .. s2
end

local function parse_to_tokens(text)
    local tokens = {}
    local cursor = 1
    local global_comment = nil
    local pending_comment = nil
    local has_text = false
    
    -- Formatting state
    local state = {b=false, i=false, u=false, s=false, meta_t1=nil, meta_t2=nil}

    -- Normalize newlines
    text = text:gsub("\r\n", "\n"):gsub("\r", "\n")

    while cursor <= #text do
        local tag_start = text:find("[{<\n]", cursor)
        
        -- Segment before the next tag/newline
        local segment_end = (tag_start or (#text + 1)) - 1
        local segment = text:sub(cursor, segment_end)
        
        if segment ~= "" then
            for word in segment:gmatch("%S+") do 
                 local effective_comment = pending_comment or nil -- Initially use nil, global_comment applied in final pass
                 table.insert(tokens, {
                     text = word,
                     orig_text = word, 
                     comment = effective_comment,
                     is_newline = false,
                     b = state.b, s = state.s, u = state.u, i = state.i,
                     meta_t1 = state.meta_t1, meta_t2 = state.meta_t2
                 })
                 pending_comment = nil
                 has_text = true
            end
        end

        if not tag_start then break end

        local char = text:sub(tag_start, tag_start)
        
        if char == "\n" then
             table.insert(tokens, { is_newline = true, text = "\n" })
             has_text = false -- Reset for new line
             cursor = tag_start + 1
             
        elseif char == "{" then
            -- ASS tag or comment
            local tag_end = text:find("}", tag_start)
            if tag_end then
                local content = text:sub(tag_start + 1, tag_end - 1)
                
                local is_formatting = false
                
                -- Check for metadata tags first
                local meta_t1_match = content:match("\\meta_t1:([%d%.]+)")
                local meta_t2_match = content:match("\\meta_t2:([%d%.]+)")
                if meta_t1_match and meta_t2_match then
                    state.meta_t1 = tonumber(meta_t1_match)
                    state.meta_t2 = tonumber(meta_t2_match)
                    is_formatting = true
                end
                
                -- Parse supported tags: \b1, \b0, \i1, \u1, \s1
                -- Parse supported tags: \b1, \b0, \i1, \i0, \u1, \u0, \s1, \s0
                -- Also handle case-insensitive and tags without digits (defaults to 1)
                for tag in content:gmatch("\\[bius]%d?") do
                    local t = tag:sub(2,2):lower()
                    local val_str = tag:sub(3,3)
                    local v = (val_str == "" or val_str == "1")
                    if t == "b" then state.b = v
                    elseif t == "i" then 
                        state.i = v 
                    elseif t == "u" then state.u = v
                    elseif t == "s" then state.s = v
                    end
                    is_formatting = true
                end
                
                -- Check for other formatting tags (starting with backslash)
                if not is_formatting and content:find("^\\") then
                    is_formatting = true
                end

                -- If not formatting (and not empty), it's a comment
                if not is_formatting and content ~= "" then
                    content = content:gsub("^%s+", ""):gsub("%s+$", "") -- Trim
                    if not has_text or (#tokens > 0 and tokens[#tokens].is_newline) then
                        global_comment = merge_comments(global_comment, content)
                    elseif #tokens > 0 and not tokens[#tokens].is_newline then
                        -- Attach to last token
                        tokens[#tokens].comment = merge_comments(tokens[#tokens].comment, content)
                    else
                        pending_comment = merge_comments(pending_comment, content)
                    end
                end
                cursor = tag_end + 1
            else
                cursor = tag_start + 1 -- Broken tag, treat brace as char? Or skip? Treating as char for now (loop will pick it up next iter if not handled)
                -- Actually to treat as char we should advance just 1 but the logic above assumes segment handles text. 
                -- If we are here, tag_start was found. If broken, we should probably output brace as text? 
                -- For simplicity let's just skip the brace to avoid infinite loop or just print it.
                -- Better: treat '{' as text if no closing '}'
                -- But current logic splits text by delimiters. 
                -- Let's just advance cursor. Ideally we'd backtrack but that's complex.
                -- Simplest robust fix: If broken tag, just consume '{' 
                cursor = tag_start + 1
            end
            
        elseif char == "<" then
            -- HTML tag
            local tag_end = text:find(">", tag_start)
            if tag_end then
                local content = text:sub(tag_start + 1, tag_end - 1):lower()
                if content == "b" then state.b = true
                elseif content == "/b" then state.b = false
                elseif content == "i" then state.i = true
                elseif content == "/i" then state.i = false
                elseif content == "u" then state.u = true
                elseif content == "/u" then state.u = false
                elseif content == "s" then state.s = true
                elseif content == "/s" then state.s = false
                end
                cursor = tag_end + 1
            else
                cursor = tag_start + 1
            end
        end
    end
    
    -- Final Pass: Apply global_comment to all tokens that don't have a specific comment
    if global_comment then
        for _, tok in ipairs(tokens) do
            if not tok.is_newline and not tok.comment then
                tok.comment = global_comment
            end
        end
    end
    
    return tokens
end

local function process_assimilation_tokens(tokens)
    for _, tok in ipairs(tokens) do
        if not tok.is_newline then
            local new_text, ranges = apply_assimilation_recursive(tok.text)
            tok.text = new_text
            tok.assimilation_ranges = ranges
        end
    end
    return tokens
end

local function save_settings()
    reaper.SetExtState(SETTINGS_SECTION, "NoTitle", tostring(flags.NoTitle), true)
    reaper.SetExtState(SETTINGS_SECTION, "HideBackground", tostring(flags.HideBackground), true)
    reaper.SetExtState(SETTINGS_SECTION, "NoResize", tostring(flags.NoResize), true)
    reaper.SetExtState(SETTINGS_SECTION, "NoMove", tostring(flags.NoMove), true)
    reaper.SetExtState(SETTINGS_SECTION, "NoDocking", tostring(flags.NoDocking), true)  
    reaper.SetExtState(SETTINGS_SECTION, "current_font_index", tostring(current_font_index), true)
    reaper.SetExtState(SETTINGS_SECTION, "font_scale", tostring(font_scale), true)
    reaper.SetExtState(SETTINGS_SECTION, "text_color", string.format("%08X", text_color), true)
    reaper.SetExtState(SETTINGS_SECTION, "shadow_color", string.format("%08X", shadow_color), true)
    reaper.SetExtState(SETTINGS_SECTION, "second_font_index", tostring(second_font_index), true)
    reaper.SetExtState(SETTINGS_SECTION, "second_font_scale", tostring(second_font_scale), true)
    reaper.SetExtState(SETTINGS_SECTION, "next_region_offset", tostring(next_region_offset), true)
    reaper.SetExtState(SETTINGS_SECTION, "second_text_color", string.format("%08X", second_text_color), true)
    reaper.SetExtState(SETTINGS_SECTION, "second_shadow_color", string.format("%08X", second_shadow_color), true)
    reaper.SetExtState(SETTINGS_SECTION, "window_bg_color", string.format("%08X", window_bg_color), true)
    reaper.SetExtState(SETTINGS_SECTION, "border", tostring(border), true)
    reaper.SetExtState(SETTINGS_SECTION, "enable_wrap", tostring(enable_wrap), true)
    reaper.SetExtState(SETTINGS_SECTION, "wrap_margin", tostring(wrap_margin), true)
    reaper.SetExtState(SETTINGS_SECTION, "enable_second_line", tostring(enable_second_line), true)
    reaper.SetExtState(SETTINGS_SECTION, "show_progress", tostring(show_progress), true)
    reaper.SetExtState(SETTINGS_SECTION, "progress_width", tostring(progress_width), true)
    reaper.SetExtState(SETTINGS_SECTION, "progress_height", tostring(progress_height), true)
    reaper.SetExtState(SETTINGS_SECTION, "progress_offset", tostring(progress_offset), true)
    reaper.SetExtState(SETTINGS_SECTION, "align_center", tostring(align_center), true)
    reaper.SetExtState(SETTINGS_SECTION, "align_vertical", tostring(align_vertical), true)
    reaper.SetExtState(SETTINGS_SECTION, "align_bottom", tostring(align_bottom), true)
    reaper.SetExtState(SETTINGS_SECTION, "show_assimilation", tostring(show_assimilation), true)
    reaper.SetExtState(SETTINGS_SECTION, "always_show_next", tostring(always_show_next), true)
    reaper.SetExtState(SETTINGS_SECTION, "fill_gaps", tostring(fill_gaps), true)
    reaper.SetExtState(SETTINGS_SECTION, "show_tooltips", tostring(show_tooltips), true)
    reaper.SetExtState(SETTINGS_SECTION, "attach_to_video", tostring(attach_to_video), true)
    reaper.SetExtState(SETTINGS_SECTION, "attach_offset", tostring(attach_offset), true)
    reaper.SetExtState(SETTINGS_SECTION, "attach_manual_x", tostring(attach_manual_x), true)
    reaper.SetExtState(SETTINGS_SECTION, "attach_manual_y", tostring(attach_manual_y), true)
    reaper.SetExtState(SETTINGS_SECTION, "invert_y_axis", tostring(invert_y_axis), true)
    reaper.SetExtState(SETTINGS_SECTION, "ignore_newlines", tostring(ignore_newlines), true)
    -- Зберігаємо висоту тільки якщо увімкнено прив'язку до відеовікна
    if attach_to_video then
        reaper.SetExtState(SETTINGS_SECTION, "win_h", tostring(win_h), true)
    end
    
    -- Інвалідуємо кеш координат при збереженні налаштувань
    video_cache_valid = false
end

local function load_settings()
    flags.NoTitle = reaper.GetExtState(SETTINGS_SECTION, "NoTitle") == "true"
    flags.HideBackground = reaper.GetExtState(SETTINGS_SECTION, "HideBackground") == "true"
    flags.NoResize = reaper.GetExtState(SETTINGS_SECTION, "NoResize") == "true"
    flags.NoMove = reaper.GetExtState(SETTINGS_SECTION, "NoMove") == "true"
    flags.NoDocking = (reaper.GetExtState(SETTINGS_SECTION, "NoDocking") ~= "false")
    current_font_index = tonumber(reaper.GetExtState(SETTINGS_SECTION, "current_font_index")) or 1
    font_scale = tonumber(reaper.GetExtState(SETTINGS_SECTION, "font_scale")) or 30
    second_font_index = tonumber(reaper.GetExtState(SETTINGS_SECTION, "second_font_index")) or 1
    second_font_scale = tonumber(reaper.GetExtState(SETTINGS_SECTION, "second_font_scale")) or 22
    next_region_offset = tonumber(reaper.GetExtState(SETTINGS_SECTION, "next_region_offset")) or 30
    local txt_col = reaper.GetExtState(SETTINGS_SECTION, "text_color")
    if txt_col ~= "" then text_color = tonumber(txt_col,16) or text_color end
    local shd_col = reaper.GetExtState(SETTINGS_SECTION, "shadow_color")
    if shd_col ~= "" then shadow_color = tonumber(shd_col,16) or shadow_color end
    local txt2_col = reaper.GetExtState(SETTINGS_SECTION, "second_text_color")
    if txt2_col ~= "" then second_text_color = tonumber(txt2_col,16) or second_text_color end
    local shd2_col = reaper.GetExtState(SETTINGS_SECTION, "second_shadow_color")
    if shd2_col ~= "" then second_shadow_color = tonumber(shd2_col,16) or second_shadow_color end
    local winbg_col = reaper.GetExtState(SETTINGS_SECTION, "window_bg_color")
    if winbg_col ~= "" then window_bg_color = tonumber(winbg_col,16) or window_bg_color end
    border = (reaper.GetExtState(SETTINGS_SECTION, "border") == "true")
    enable_wrap = (reaper.GetExtState(SETTINGS_SECTION, "enable_wrap") ~= "false")
    wrap_margin = tonumber(reaper.GetExtState(SETTINGS_SECTION, "wrap_margin")) or 0
    enable_second_line = (reaper.GetExtState(SETTINGS_SECTION, "enable_second_line") ~= "false")
    show_progress = (reaper.GetExtState(SETTINGS_SECTION, "show_progress") == "true")
    progress_width = tonumber(reaper.GetExtState(SETTINGS_SECTION, "progress_width")) or 400
    progress_height = tonumber(reaper.GetExtState(SETTINGS_SECTION, "progress_height")) or 4
    progress_offset = tonumber(reaper.GetExtState(SETTINGS_SECTION, "progress_offset")) or 20
    align_center = (reaper.GetExtState(SETTINGS_SECTION, "align_center") ~= "false")
    align_vertical = (reaper.GetExtState(SETTINGS_SECTION, "align_vertical") == "true")
    align_bottom = (reaper.GetExtState(SETTINGS_SECTION, "align_bottom") ~= "false")
    show_assimilation = (reaper.GetExtState(SETTINGS_SECTION, "show_assimilation") ~= "false")
    always_show_next = (reaper.GetExtState(SETTINGS_SECTION, "always_show_next") ~= "false")
    fill_gaps = (reaper.GetExtState(SETTINGS_SECTION, "fill_gaps") == "true")
    show_tooltips = (reaper.GetExtState(SETTINGS_SECTION, "show_tooltips") ~= "false")
    attach_to_video = (reaper.GetExtState(SETTINGS_SECTION, "attach_to_video") == "true")
    attach_offset = tonumber(reaper.GetExtState(SETTINGS_SECTION, "attach_offset")) or 0
    attach_manual_x = tonumber(reaper.GetExtState(SETTINGS_SECTION, "attach_manual_x")) or 0
    attach_manual_y = tonumber(reaper.GetExtState(SETTINGS_SECTION, "attach_manual_y")) or 0
    invert_y_axis = (reaper.GetExtState(SETTINGS_SECTION, "invert_y_axis") == "true")
    ignore_newlines = (reaper.GetExtState(SETTINGS_SECTION, "ignore_newlines") == "true")
    -- Завантажуємо висоту тільки якщо увімкнено прив'язку до відеовікна
    if attach_to_video then
        win_h = tonumber(reaper.GetExtState(SETTINGS_SECTION, "win_h")) or 300
    end
end

load_settings()

-- Функція збору списку джерел
local function collect_source_modes()
    local modes = {}

    -- спочатку перевіряємо наявність регіонів
    local _, num_markers, num_regions = reaper.CountProjectMarkers(0)
    if num_regions > 0 then
        table.insert(modes, { id = 0, label = "0: Регіони" })
    end

    -- пробігаємо всі треки та шукаємо ітеми з текстом
    local track_count = reaper.CountTracks(0)
    for t = 0, track_count-1 do
        local tr = reaper.GetTrack(0, t)
        local items = reaper.CountTrackMediaItems(tr)
        local has_text = false
        for i = 0, items-1 do
            local it = reaper.GetTrackMediaItem(tr, i)
            local take = reaper.GetActiveTake(it)
            if not (take and reaper.ValidatePtr(take, "MediaItem_Take*")) then
                local notes = reaper.ULT_GetMediaItemNote(it)
                if notes and notes ~= "" then
                    has_text = true
                    break
                end
            end
        end
        if has_text then
            table.insert(modes, {
                id = t+1,
                label = (t+1) .. ": Ітеми (трек " .. (t+1) .. ")"
            })
        end
    end

    return modes
end

-- переконатися, що вибраний source_mode реально доступний
local function ensure_valid_source_mode()
    local modes = collect_source_modes()
    local valid = false
    for _, m in ipairs(modes) do
        if m.id == source_mode then
            valid = true
            break
        end
    end
    if not valid then
        if #modes > 0 then
            source_mode = modes[1].id
        else
            source_mode = 0 -- fallback: нічого немає
        end
    end
end
ensure_valid_source_mode()

-- функція відображення підказки
local function tooltip(text)
    if not show_tooltips then return end  -- глобальне вимкнення

    if reaper.ImGui_IsItemHovered(ctx) then
        local now = reaper.time_precise()
        local state = tooltip_state[text]

        if not state then
            -- перший раз навели на цей елемент
            tooltip_state[text] = { start = now }
        else
            -- перевіряємо глобальну затримку
            if now - state.start >= tooltip_delay then
                reaper.ImGui_SetTooltip(ctx, text)
            end
        end
    else
        -- скидання, коли відводимо мишу
        tooltip_state[text] = nil
    end
end

-- Контекстне меню
local function draw_context_menu()
    if reaper.ImGui_BeginPopup(ctx, "context_menu",
        reaper.ImGui_WindowFlags_NoResize() | reaper.ImGui_WindowFlags_NoSavedSettings()) then
        reaper.ImGui_PushItemWidth(ctx, CONTEXT_MENU_MIN_WIDTH)

        local changes = 0
        local function add_change(changed, new_value)
            changes = changes + (changed and 1 or 0)
            return new_value
        end

        -- Режим джерела
        local label = (source_mode == 0) and "0: Регіони"
                    or (source_mode .. ": Ітеми (трек " .. source_mode .. ")")

        if reaper.ImGui_BeginCombo(ctx, "Режим", label) then
            local modes = collect_source_modes() -- <== ось тут збираємо список
            for _, mode in ipairs(modes) do
                if reaper.ImGui_Selectable(ctx, mode.label, source_mode == mode.id) then
                    source_mode = mode.id
                end
            end
            reaper.ImGui_EndCombo(ctx)
        end
        tooltip("Дозволяє вибрати режим відображення виходячи з доступності регіонів або ітемів на треках")

        -- Прапорці вікна
        reaper.ImGui_Separator(ctx)
        flags.NoMove          = add_change(reaper.ImGui_Checkbox(ctx, "Закріпити", flags.NoMove))
        tooltip("Вимикає можливість перетягувати вікно")
        flags.NoTitle         = add_change(reaper.ImGui_Checkbox(ctx, "Приховати заголовок", flags.NoTitle))
        tooltip("Вимикає заголовок вікна")
        flags.HideBackground  = add_change(reaper.ImGui_Checkbox(ctx, "Приховати фон", flags.HideBackground))
        tooltip("Повністю прибирає фон вікна, роблячи його прозорим")
        border                = add_change(reaper.ImGui_Checkbox(ctx, "Фон під текстом", border))
        tooltip("Увімкнує підкладку під кожним рядком. Кольором виступає колір фону")
        window_bg_color       = add_change(reaper.ImGui_ColorEdit4(ctx, "Колір фону вікна", window_bg_color, reaper.ImGui_ColorEditFlags_NoInputs() | reaper.ImGui_ColorEditFlags_AlphaBar()))
        tooltip("Задає колір фону та підкладки")
        align_center          = add_change(reaper.ImGui_Checkbox(ctx, "Центрування по горизонталі", align_center))
        tooltip("Вирівнює рядки по центру вікна (горизонтально)")

        local assim_changed, new_assim = reaper.ImGui_Checkbox(ctx, "Показувати асиміляцію", show_assimilation)
        if assim_changed then
            show_assimilation = new_assim
            changes = changes + 1
        end
        tooltip("Вмикає відображення асимільованого тексту в оверлеї (незалежно від Subass Notes)")

        reaper.ImGui_Separator(ctx)
        if reaper.ImGui_Checkbox(ctx, "Центрування по вертикалі", align_vertical) then
            align_vertical = not align_vertical
            if align_vertical then align_bottom = false end -- Mutual exclusion
            changes = changes + 1
        end
        tooltip("Вирівнює рядки по вертикалі (центр)")

        if reaper.ImGui_Checkbox(ctx, "Центрування по низу", align_bottom) then
            align_bottom = not align_bottom
            if align_bottom then align_vertical = false end -- Mutual exclusion
            changes = changes + 1
        end
        tooltip("Притискає рядки до низу вікна")
        enable_wrap           = add_change(reaper.ImGui_Checkbox(ctx, "Перенос рядків", enable_wrap))
        tooltip("Не дозволяє рядкам вилазити за межі вікна, розбиваючи їх на рівні відрізки")
        if enable_wrap then
            wrap_margin       = add_change(reaper.ImGui_SliderInt(ctx, "відступ переносу", wrap_margin, 0, 300))
            tooltip("Відступ від краю вікна при автопереносі (пікселі)\nВраховується з обох сторін")
            -- Показуємо напрямні якщо слайдер активний або на нього наведена миша
            show_wrap_guides = reaper.ImGui_IsItemActive(ctx) or reaper.ImGui_IsItemHovered(ctx)
        else
            show_wrap_guides = false
        end
        local old_ignore_newlines = ignore_newlines
        ignore_newlines       = add_change(reaper.ImGui_Checkbox(ctx, "Ігнорувати переноси", ignore_newlines))
        tooltip("Ігнорувати символи переносу рядка \\n при читанні тексту з регіонів/ітемів")
        if old_ignore_newlines ~= ignore_newlines then
            last_pos = nil -- Скидаємо кеш при зміні опції
        end
        fill_gaps             = add_change(reaper.ImGui_Checkbox(ctx, "Заповнювати пробіли", fill_gaps))
        tooltip("Дозволяє відображати рядки і за межами регіонів/ітемів")
        flags.NoResize        = add_change(reaper.ImGui_Checkbox(ctx, "Не змінювати розміри", flags.NoResize))
        tooltip("Вимикає можливість змінювати розміри вікна")
        attach_to_video       = add_change(reaper.ImGui_Checkbox(ctx, "Прив'язати до відеовікна", attach_to_video))
        tooltip("Автоматично позиціонує вікно відносно відеовікна REAPER\nПотрібно js_ReaScriptAPI")
        -- Додаткові налаштування прив'язки (показуємо тільки якщо attach_to_video = true)
        if attach_to_video then
            -- Слайдер позиції (0% - зверху, 100% - знизу)
            attach_offset = add_change(reaper.ImGui_SliderInt(ctx, "Верт. позиція %", attach_offset, 0, 100))
            tooltip("Позиція оверлею відносно висоти відеовікна")
            
            -- Ручна корекція X
            attach_manual_x = add_change(reaper.ImGui_SliderInt(ctx, "Корекція X (px)", attach_manual_x, -2000, 2000))
            tooltip("Додаткове зміщення по горизонталі")

            -- Ручна корекція Y
            attach_manual_y = add_change(reaper.ImGui_SliderInt(ctx, "Корекція Y (px)", attach_manual_y, -2000, 2000))
            tooltip("Додаткове зміщення по вертикалі")

            -- macOS Fix
            invert_y_axis = add_change(reaper.ImGui_Checkbox(ctx, "Інвертувати рух (macOS Fix)", invert_y_axis))
            tooltip("Увімкніть, якщо при зміні розміру вікна оверлей рухається в протилежний бік.\nВиправляє різницю в системах координат Cocoa/ImGui.")
        end
        
        
        -- Стиль першого рядка
        reaper.ImGui_Separator(ctx)
        reaper.ImGui_Text(ctx, "Перший рядок")
        if reaper.ImGui_BeginCombo(ctx, "шрифт", available_fonts[current_font_index]) then
            for i, name in ipairs(available_fonts) do
                if reaper.ImGui_Selectable(ctx, name, i == current_font_index) then
                    current_font_index = i
                    changes = 1
                end
            end
            reaper.ImGui_EndCombo(ctx)
        end
        font_scale      = add_change(reaper.ImGui_SliderInt(ctx, "масштаб", font_scale, 10, 100))
        text_color      = add_change(reaper.ImGui_ColorEdit4(ctx, "колір", text_color, reaper.ImGui_ColorEditFlags_NoInputs() | reaper.ImGui_ColorEditFlags_AlphaBar()))
        shadow_color    = add_change(reaper.ImGui_ColorEdit4(ctx, "тінь", shadow_color, reaper.ImGui_ColorEditFlags_NoInputs() | reaper.ImGui_ColorEditFlags_AlphaBar()))

        -- прогрес-бар
        reaper.ImGui_Separator(ctx)
        show_progress = add_change(reaper.ImGui_Checkbox(ctx, "Прогрес-бар", show_progress))
        tooltip("Увімкнує анімацію тривалості поточного регіону/ітема")
        if show_progress then
            progress_width  = add_change(reaper.ImGui_SliderInt(ctx, "довжина", progress_width, 200, 2000))
            progress_height = add_change(reaper.ImGui_SliderInt(ctx, "товщина", progress_height, 1, 10))
            progress_offset = add_change(reaper.ImGui_SliderInt(ctx, "відступ", progress_offset, 0, 200))
        end
        
        -- Стиль другого рядка
        reaper.ImGui_Separator(ctx)
        enable_second_line = add_change(reaper.ImGui_Checkbox(ctx, "Другий рядок", enable_second_line))
        tooltip("Увімкнує відображення рядка наступного регіону/ітема")
        if enable_second_line then
            if reaper.ImGui_BeginCombo(ctx, "шрифт 2", available_fonts[second_font_index]) then
                for i, name in ipairs(available_fonts) do
                if reaper.ImGui_Selectable(ctx, name, i == second_font_index) then
                    second_font_index = i
                    changes = 1
                end
                end
                reaper.ImGui_EndCombo(ctx)
            end
            second_font_scale   = add_change(reaper.ImGui_SliderInt(ctx, "масштаб 2", second_font_scale, 10, 100))
            next_region_offset  = add_change(reaper.ImGui_SliderInt(ctx, "відступ 2", next_region_offset, 0, 200))
            second_text_color   = add_change(reaper.ImGui_ColorEdit4(ctx, "колір 2", second_text_color, reaper.ImGui_ColorEditFlags_NoInputs() | reaper.ImGui_ColorEditFlags_AlphaBar()))
            second_shadow_color = add_change(reaper.ImGui_ColorEdit4(ctx, "тінь 2", second_shadow_color, reaper.ImGui_ColorEditFlags_NoInputs() | reaper.ImGui_ColorEditFlags_AlphaBar()))
        end

        fill_gaps             = add_change(reaper.ImGui_Checkbox(ctx, "Заповнювати прогалини", fill_gaps))
        tooltip("Показувати найближчий майбутній регіон, якщо курсор знаходиться між регіонами (у тиші)")

        always_show_next = add_change(reaper.ImGui_Checkbox(ctx, "Завжди показувати наступну", always_show_next))
        tooltip("Показувати наступну репліку, навіть якщо курсор знаходиться між регіонами (ігноруючи 'Заповнювати прогалини')")
        
        reaper.ImGui_Separator(ctx)
        flags.NoDocking = add_change(reaper.ImGui_Checkbox(ctx, "Не стикувати", flags.NoDocking))
        tooltip("Вимикає можливість вбудовування та прилипання вікна. Перетягувати необхідно за заголовок або верхню межу вікна")
        
        show_tooltips   = add_change(reaper.ImGui_Checkbox(ctx, "Підказки", show_tooltips))
        tooltip("Увімкнує відображення спливаючих підказок")

        -- Зберігаємо налаштування, якщо були зміни
        if changes > 0 then save_settings() end

        -- Роздільник та кнопка закриття
        reaper.ImGui_Separator(ctx)
        if reaper.ImGui_Button(ctx, "Закрити вікно") then
            close_requested = true
            reaper.ImGui_CloseCurrentPopup(ctx)
        end

        reaper.ImGui_PopItemWidth(ctx)
        reaper.ImGui_EndPopup(ctx)
    end
end

-- Helper function to draw wavy line (for assimilation)
local function draw_wavy_line(draw_list, x, y, width, color, step, amplitude)
    if width <= 0 then return end
    step = step or 3 -- Frequency of the wave
    amplitude = amplitude or 1.3
    local cur_x = x
    local up = true
    while cur_x < x + width do
        local next_x = math.min(cur_x + step, x + width)
        local y1 = y + (up and amplitude or -amplitude)
        local y2 = y + (up and -amplitude or amplitude)
        reaper.ImGui_DrawList_AddLine(draw_list, cur_x, y1, next_x, y2, color, 1.2)
        cur_x = next_x
        up = not up
    end
end

-- Helper function to calculate actual line count including wrapping
local function calculate_line_count(tokens, font_index, font_scale, win_w)
    if #tokens == 0 then return 1 end
    
    local font_main = font_objects[font_index] or font_objects[1]
    
    reaper.ImGui_PushFont(ctx, font_main, font_scale)
    
    local line_count = 1
    local current_line_width = 0
    local max_width = win_w - padding_x*2 - wrap_margin*2
    local space_w = reaper.ImGui_CalcTextSize(ctx, " ")
    
    for _, tok in ipairs(tokens) do
        if tok.is_newline then
            line_count = line_count + 1
            current_line_width = 0
        else
            local w = reaper.ImGui_CalcTextSize(ctx, tok.text)
            
            if enable_wrap and current_line_width + w > max_width and current_line_width > 0 then
                line_count = line_count + 1
                current_line_width = 0
            end
            
            current_line_width = current_line_width + w + space_w
        end
    end
    
    reaper.ImGui_PopFont(ctx)
    return line_count
end

-- Функція відображення токенів
local function draw_tokens(ctx, tokens, font_index, font_scale, text_color, shadow_color, win_w, is_next_line)
    local font_main = font_objects[font_index] or font_objects[1]

    -- We push Main font as default
    reaper.ImGui_PushFont(ctx, font_main, font_scale)

    -- Simple wrapping logic
    local lines = {{}} -- list of lines, each is list of tokens
    local current_line_width = 0
    local max_width = win_w - padding_x*2 - wrap_margin*2
    local space_w_main = reaper.ImGui_CalcTextSize(ctx, " ") 
    -- Assuming space width is similar, or we re-calc. TextSize depends on CURRENT font.
    
    for _, tok in ipairs(tokens) do
        if tok.is_newline then
            table.insert(lines, {})
            current_line_width = 0
        else
            -- Measure with correct font
            local w = reaper.ImGui_CalcTextSize(ctx, tok.text)
            if tok.i then
                w = w + (font_scale * 0.2)
            end

            local space_w = space_w_main -- Simplify: use main font space width to avoid constant switching for spaces
            
            -- Check wrap
            if enable_wrap and current_line_width + w > max_width and current_line_width > 0 then
                table.insert(lines, {})
                current_line_width = 0
            end
            
            table.insert(lines[#lines], tok)
            current_line_width = current_line_width + w + space_w
        end
    end

    local line_h = reaper.ImGui_GetTextLineHeight(ctx)
    local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
    local shadow_offset = 2

    for line_idx, line in ipairs(lines) do
        -- Measure line total width for centering
        local line_total_w = 0
        for i, tok in ipairs(line) do
            local w = reaper.ImGui_CalcTextSize(ctx, tok.text)
            
            line_total_w = line_total_w + w
            if i < #line then line_total_w = line_total_w + space_w_main end
        end

        -- Determine X start
        local cur_x
        if align_center then
            cur_x = (win_w - line_total_w) / 2
        else
            cur_x = wrap_margin
        end
        local cur_y = reaper.ImGui_GetCursorPosY(ctx)

        if #line > 0 then
            local win_x, win_y = reaper.ImGui_GetWindowPos(ctx)
            
            -- Draw Background
            if border then
                local rect_x1 = win_x + cur_x - padding_x
                local rect_y1 = win_y + cur_y - padding_y
                local rect_x2 = rect_x1 + line_total_w + padding_x*2
                local rect_y2 = rect_y1 + line_h + padding_y*2
                reaper.ImGui_DrawList_AddRectFilled(draw_list, rect_x1, rect_y1, rect_x2, rect_y2, window_bg_color or 0x000000AA, 4)
            end

            local temp_x = win_x + cur_x
            local line_base_y = win_y + cur_y

            for i, tok in ipairs(line) do
                -- Measure (again, needed for positioning)
                local w = reaper.ImGui_CalcTextSize(ctx, tok.text)

                -- 1. Interaction (Invisible Button)
                -- Use line index + token index for unique ID
                reaper.ImGui_SetCursorPos(ctx, temp_x - win_x - 2, line_base_y - win_y - 2)
                local stable_id = string.format("##tok_L%d_T%d_%s", line_idx, i, tok.orig_text)
                reaper.ImGui_InvisibleButton(ctx, stable_id, w + 4, line_h + 4)
                
                -- Comment Tooltip
                if tok.comment and reaper.ImGui_IsItemHovered(ctx) then
                    reaper.ImGui_SetTooltip(ctx, tok.comment)
                end

                -- Dictionary / Edit Logic
                local dict_word = tok.orig_text:gsub("[%p]+$", ""):gsub("^[%p]+", "")
                if reaper.ImGui_IsItemActive(ctx) then
                    if word_hold.word ~= dict_word then
                        word_hold.word = dict_word
                        word_hold.start_time = reaper.time_precise()
                        word_hold.triggered = false
                    elseif not word_hold.triggered then
                        local dur = reaper.time_precise() - word_hold.start_time
                        if dur > 0.4 then
                            reaper.SetExtState("SubassSync", "WORD", dict_word, false)
                            reaper.gmem_write(0, 2) -- Signal DICT
                            word_hold.triggered = true
                        end
                    end
                else
                    if word_hold.word == dict_word then
                        word_hold.word = ""
                        word_hold.triggered = false
                    end
                end

                if reaper.ImGui_IsItemHovered(ctx) and reaper.ImGui_IsMouseDoubleClicked(ctx, 0) then
                    -- Use metadata if available for exact sync
                    if tok.meta_t1 and tok.meta_t2 then
                        reaper.gmem_write(1, tok.meta_t1)
                        reaper.gmem_write(2, tok.meta_t2)
                        reaper.gmem_write(0, 4) -- CMD_EDIT_SPECIFIC
                    else
                        -- Fallback to old behavior
                        reaper.gmem_write(0, is_next_line and 3 or 1)
                    end
                end

                -- 2. Draw Text (Shadow + Main + Bold)
                local function draw_text_inner(x, y, color)
                    reaper.ImGui_DrawList_AddText(draw_list, x, y, color, tok.text)
                end

                draw_text_inner(temp_x + shadow_offset, line_base_y + shadow_offset, shadow_color)
                draw_text_inner(temp_x, line_base_y, text_color)
                
                -- BOLD Simulation
                if tok.b then
                    draw_text_inner(temp_x + 1, line_base_y, text_color)
                end

                -- ITALIC (Wavy Underline) - Less intense wave
                if tok.i then
                    local wave_y = line_base_y + line_h - 2
                    draw_wavy_line(draw_list, temp_x, wave_y, w, text_color, 8, 2.0)
                end

                -- UNDERLINE
                if tok.u then
                    local ul_y = line_base_y + line_h - 2
                    reaper.ImGui_DrawList_AddLine(draw_list, temp_x, ul_y, temp_x + w, ul_y, text_color, 1.0)
                end

                -- STRIKEOUT
                if tok.s then
                    local st_y = line_base_y + line_h / 2
                    reaper.ImGui_DrawList_AddLine(draw_list, temp_x, st_y, temp_x + w, st_y, text_color, 1.2)
                end

                -- ASSIMILATION WAVY UNDERLINE
                if show_assimilation and tok.assimilation_ranges and #tok.assimilation_ranges > 0 then
                    for _, rg in ipairs(tok.assimilation_ranges) do
                        local before_text = tok.text:sub(1, rg.start_idx - 1)
                        local match_text = tok.text:sub(rg.start_idx, rg.stop_idx)
                        local offset_w, _ = reaper.ImGui_CalcTextSize(ctx, before_text)
                        local match_w, _ = reaper.ImGui_CalcTextSize(ctx, match_text)
                        
                        -- No additional slant offset needed for waves now
                        local wave_y = line_base_y + line_h - 2
                        draw_wavy_line(draw_list, temp_x + offset_w, wave_y, match_w, text_color, 3, 1.3)
                    end
                end

                -- 3. Draw Comment Dash
                if tok.comment then
                    local dash_color = text_color 
                    -- Apply alpha 0.4 roughly to integer color
                    local alpha = (dash_color & 0xFF) * 0.4
                    dash_color = (dash_color & 0xFFFFFF00) | math.floor(alpha)

                    local comm_len = utf8.len(tok.comment) or #tok.comment
                    local dash_w = math.max(3, 8 - math.min(5, math.floor(comm_len/15)))
                    local gap_w = math.max(3, dash_w - 1)
                    
                    local dash_cur = temp_x
                    local dash_end = temp_x + w
                    local y_dash = line_base_y + line_h - 2
                    
                    while dash_cur < dash_end do
                        local dw = math.min(dash_w, dash_end - dash_cur)
                        reaper.ImGui_DrawList_AddRectFilled(draw_list, dash_cur, y_dash, dash_cur + dw, y_dash + 3, dash_color)
                        dash_cur = dash_cur + dash_w + gap_w
                    end
                end

                temp_x = temp_x + w + space_w_main
            end
        else
             reaper.ImGui_Dummy(ctx, 1, line_h)
        end
    end

    reaper.ImGui_PopFont(ctx)
end

-- Отримання поточного та наступного регіонів
local function get_current_and_next_region_names()
    local play_state = reaper.GetPlayState()
    local pos = (play_state & 1) == 1 and reaper.GetPlayPosition() or reaper.GetCursorPosition()
    local _, num_markers, num_regions = reaper.CountProjectMarkers(0)

    local regions = {}
    for i = 0, (num_markers + num_regions) - 1 do
        local ret, isrgn, startpos, endpos, name = reaper.EnumProjectMarkers3(0, i)
        if isrgn then
            if ignore_newlines then name = string.gsub(name or "", "\n", " ") end
            table.insert(regions, {start = startpos, stop = endpos, name = name or ""})
        end
    end

    table.sort(regions, function(a,b) return a.start < b.start end)

    local current_list = {}
    local start_pos, stop_pos = nil, nil
    local last_overlapping_idx = 0
    local found_overlap = false

    -- 1. Find ALL overlapping regions
    for i, r in ipairs(regions) do
        if pos >= r.start and pos < r.stop then
            -- Inject metadata tag with exact times
            local text_with_meta = string.format("{\\meta_t1:%.3f \\meta_t2:%.3f}%s", r.start, r.stop, r.name)
            table.insert(current_list, text_with_meta)
            if not start_pos then start_pos = r.start end
            stop_pos = r.stop
            last_overlapping_idx = i
            found_overlap = true
        end
    end

    local current = table.concat(current_list, "\n")
    local nextreg = ""

    -- 2. Find Next
    if found_overlap then
        -- Next is the first region after the last overlapping one
        if regions[last_overlapping_idx + 1] then
             local next_r = regions[last_overlapping_idx + 1]
             nextreg = string.format("{\\meta_t1:%.3f \\meta_t2:%.3f}%s", next_r.start, next_r.stop, next_r.name)
        end
        return current, nextreg, start_pos, stop_pos
    end

    -- 3. No overlap (Gap logic)
    -- Find nearest if fill_gaps OR always_show_next logic needed
    
    local nearest_dist = math.huge
    local nearest_idx = nil

    for i, r in ipairs(regions) do
        local dist = math.min(math.abs(pos - r.start), math.abs(pos - r.stop))
        if dist < nearest_dist then
            nearest_dist = dist
            nearest_idx = i
        end
    end

    if fill_gaps and nearest_idx then
        current = regions[nearest_idx].name
        if regions[nearest_idx+1] then
            nextreg = regions[nearest_idx+1].name
        end
        return current, nextreg, regions[nearest_idx].start, regions[nearest_idx].stop
    end
    
    -- always_show_next logic (when in gap and fill_gaps is OFF)
    if always_show_next then
         for i, r in ipairs(regions) do
             if r.start > pos then
                 return "", r.name, 0, 0 
             end
         end
    end

    return "", "", 0, 0
end

-- Отримання поточного та наступного текстового ітема на заданому треку
local function get_text_item_name(item)
    local take = reaper.GetActiveTake(item)
    if take and reaper.ValidatePtr(take, "MediaItem_Take*") then
        return nil
    end
    local notes = reaper.ULT_GetMediaItemNote(item)
    if notes and notes ~= "" then
        if ignore_newlines then notes = string.gsub(notes, "\n", " ") end
        return notes
    end
    return nil
end
-- Допоміжна функція для пошуку наступного текстового ітема
local function find_next_text_item(track, start_idx)
    local items = reaper.CountTrackMediaItems(track)
    for j = start_idx, items-1 do
        local it = reaper.GetTrackMediaItem(track, j)
        local name = get_text_item_name(it)
        if name then
            return name
        end
    end
    return ""
end

local function get_current_and_next_items(track)
    local play_state = reaper.GetPlayState()
    local pos = (play_state & 1) == 1 and reaper.GetPlayPosition() or reaper.GetCursorPosition()
    local items_table = {} 
    local count = reaper.CountTrackMediaItems(track)
    
    -- Pre-fetch items to sort/iterate easily (items on track are usually sorted by pos but overlapping items might not be perfectly indexed)
    -- Actually `GetTrackMediaItem` index is usually spatial but let's iterate safely.
    for i = 0, count-1 do
        local it = reaper.GetTrackMediaItem(track, i)
        local start = reaper.GetMediaItemInfo_Value(it, "D_POSITION")
        local len = reaper.GetMediaItemInfo_Value(it, "D_LENGTH")
        local stop = start + len
        local name = get_text_item_name(it)
        if name then
            table.insert(items_table, {it=it, start=start, stop=stop, name=name})
        end
    end

    local current_list = {}
    local start_pos, stop_pos = nil, nil
    local last_overlapping_idx = 0
    local found_overlap = false
    
    for i, item in ipairs(items_table) do
        if pos >= item.start and pos < item.stop then
             table.insert(current_list, item.name)
             if not start_pos then start_pos = item.start end
             stop_pos = item.stop
             last_overlapping_idx = i
             found_overlap = true
        end
    end
    
    local current = table.concat(current_list, "\n")
    local next_item = ""

    if found_overlap then
        if items_table[last_overlapping_idx + 1] then
            next_item = items_table[last_overlapping_idx + 1].name
        end
        return current, next_item, start_pos, stop_pos
    end

    -- Fallback / Gap logic
    local nearest_dist, nearest_idx = math.huge, nil

    for i, item in ipairs(items_table) do
            local dist = math.min(math.abs(pos - item.start), math.abs(pos - item.stop))
            if dist < nearest_dist then
                nearest_dist = dist
                nearest_idx = i
            end
    end

    if fill_gaps and nearest_idx then
        current = items_table[nearest_idx].name
        if items_table[nearest_idx+1] then
            next_item = items_table[nearest_idx+1].name
        end
        return current, next_item, items_table[nearest_idx].start, items_table[nearest_idx].stop
    end

    if always_show_next then
        for i, item in ipairs(items_table) do
             if item.start > pos then
                 return "", item.name, 0, 0
             end
        end
    end

    return "", "", 0, 0
end

-- Функція для отримання координат відеовікна REAPER
local function get_video_window_pos()
    if not reaper.JS_Window_Find then
        return nil, nil, nil, nil  -- js_ReaScriptAPI не встановлено
    end
    
    -- Шукаємо основне відеовікно
    local video_hwnd = reaper.JS_Window_Find("Video Window", true)
    
    -- На деяких ОС або версіях REAPER в доці вікно може мати іншу назву або бути обгорнутим
    if not video_hwnd then
        -- Спробуємо знайти за назвою, яка часта для дока
        video_hwnd = reaper.JS_Window_Find("Video", false)
    end
    
    if video_hwnd then
        local retval, x1, y1, x2, y2 = reaper.JS_Window_GetRect(video_hwnd)
        if retval and x1 and y1 and x2 and y2 then
            -- 1. Try automated conversion (best, works with both viewports ON and OFF)
            if reaper.ImGui_PointConvertNative then
                -- TRUE = from native screen coordinates to ImGui logical points
                local rv1, im_x1, im_y1 = reaper.ImGui_PointConvertNative(ctx, x1, y1, true)
                local rv2, im_x2, im_y2 = reaper.ImGui_PointConvertNative(ctx, x2, y2, true)
                
                -- Ensure we got valid numbers
                if rv1 and rv2 and type(im_x1) == 'number' and type(im_y2) == 'number' then 
                    return im_x1, im_y1, im_x2, im_y2, true 
                end
            end
            
            -- 2. Manual Fallback (must account for DPI and Viewports state)
            local dpi = reaper.ImGui_GetWindowDpiScale(ctx)
            if not dpi or dpi == 0 then dpi = 1.0 end
            
            local main_viewport = reaper.ImGui_GetMainViewport(ctx)
            local vp_x, vp_y = 0, 0
            if main_viewport and reaper.ValidatePtr(main_viewport, 'ImGui_Viewport*') then
                vp_x, vp_y = reaper.ImGui_Viewport_GetPos(main_viewport)
            end
            
            local has_viewports = false
            if reaper.ImGui_GetConfigFlags then
                local config = reaper.ImGui_GetConfigFlags(ctx)
                has_viewports = (config & 0x400) ~= 0 -- reaper.ImGui_ConfigFlags_ViewportsBinding()
            end
            
            -- If viewports are off, coordinates must be relative to the main window.
            -- If viewports are on, they are absolute screen coordinates in points.
            local off_x = has_viewports and 0 or vp_x
            local off_y = has_viewports and 0 or vp_y
            
            -- Explicitly ensure we return numbers
            local os = reaper.GetOS()
            if os:match("Win") then
                local res_x1 = tonumber(x1)/dpi - off_x
                local res_y1 = tonumber(y1)/dpi - off_y
                local res_x2 = tonumber(x2)/dpi - off_x
                local res_y2 = tonumber(y2)/dpi - off_y
                return res_x1, res_y1, res_x2, res_y2
            else
                -- Mac/Linux fallback: return raw, let check_video_window_moved handle inversion
                return x1 - off_x, y1 - off_y, x2 - off_x, y2 - off_y, false
            end
        end
    end
    
    return nil, nil, nil, nil, false
end

-- Перевірка зміни позиції відеовікна та перерахунок координат прив'язки
local function check_video_window_moved()
    local x1, y1, x2, y2, is_points = get_video_window_pos()
    
    -- Strict numeric check to prevent "arithmetic on boolean" errors
    if not x1 or type(x1) ~= 'number' or type(y2) ~= 'number' then
        video_cache_valid = false
        return false
    end
    
    if video_cache_valid and cached_video_x1 == x1 and cached_video_y1 == y1 and 
       cached_video_x2 == x2 and cached_video_y2 == y2 then
        return true
    end
    
    local video_width = math.abs(x2 - x1)
    local video_height = math.abs(y2 - y1)
    
    -- Determine actual top-left even if coordinates are inverted
    local top_y = math.min(y1, y2)
    local left_x = math.min(x1, x2)
    
    -- Final positions
    attach_w = video_width
    local available_range = math.max(0, video_height - win_h)
    local offset_pixels = (attach_offset / 100) * available_range
    attach_x = left_x + attach_manual_x
    
    if invert_y_axis and not is_points then
        -- Logic for inverted coordinate change (macOS Cocoa logic: Y=0 is bottom, Y increases Up)
        -- To convert to ImGui (Top-Left): ImGui_Y = ScreenHeight - Cocoa_Y
        local main_viewport = reaper.ImGui_GetMainViewport(ctx)
        local vp_w, vp_h = reaper.ImGui_Viewport_GetSize(main_viewport)
        
        -- We assume the video window is on the main screen for this calculation to hold well
        local video_top_y = math.max(y1, y2)
        
        -- Formula: ScreenHeight - VideoTop + Offset + Manual
        attach_y = vp_h - video_top_y + offset_pixels + attach_manual_y
    else
        attach_y = top_y + offset_pixels + attach_manual_y
    end
    
    cached_video_x1, cached_video_y1, cached_video_x2, cached_video_y2 = x1, y1, x2, y2
    cached_attach_x, cached_attach_y, cached_attach_w = attach_x, attach_y, attach_w
    video_cache_valid = true
    
    return true
end

local function debug_window()
    local debugger_visible, debugger_open = reaper.ImGui_Begin(ctx, "Debugger", true)
    if debugger_visible then
        reaper.ImGui_Text(ctx, "=== Video Window Coordinates ===")
        reaper.ImGui_Separator(ctx)
        
        local x1, y1, x2, y2 = get_video_window_pos()
        if x1 then
            local video_width = x2 - x1
            local video_height = y2 - y1
            reaper.ImGui_Text(ctx, string.format("Size: %.0f x %.0f", video_width, video_height))
            reaper.ImGui_Text(ctx, string.format("X: %.0f, %.0f", x1, x2))
            reaper.ImGui_Text(ctx, string.format("Y: %.0f, %.0f", y1, y2))
        else
            reaper.ImGui_Text(ctx, "Video Window NOT FOUND")
            reaper.ImGui_Separator(ctx)
            if not reaper.JS_Window_Find then
                reaper.ImGui_TextWrapped(ctx, "js_ReaScriptAPI not installed")
                reaper.ImGui_TextWrapped(ctx, "Install via ReaPack -> ReaTeam Extensions")
            else
                reaper.ImGui_TextWrapped(ctx, "Video Window is not open")
                reaper.ImGui_Text(ctx, "or window title is different")
            end
        end

        reaper.ImGui_Separator(ctx)
        reaper.ImGui_Text(ctx, "=== Cache Status ===")
        reaper.ImGui_Separator(ctx)
        reaper.ImGui_Text(ctx, string.format("Video Cache: %s", video_cache_valid and "VALID (using cache)" or "INVALID (recalculating)"))
        reaper.ImGui_Text(ctx, string.format("User Resizing: %s", is_user_resizing and "YES (attach disabled)" or "NO"))
        reaper.ImGui_TextWrapped(ctx, "Cache invalidates on: 1st run, video window moved, settings changed, SubOverlay resized")
        
        reaper.ImGui_Separator(ctx)
        reaper.ImGui_Text(ctx, "=== Current SubOverlay Window ===")
        reaper.ImGui_Separator(ctx)
        if win_w and win_h then
            reaper.ImGui_Text(ctx, string.format("Position: %.0f x %.0f", win_X, win_Y))
            reaper.ImGui_Text(ctx, string.format("Size: %.0f x %.0f", win_w, win_h))
        else
            reaper.ImGui_Text(ctx, "Window size not available yet")
        end
        
        reaper.ImGui_Separator(ctx)
        reaper.ImGui_Text(ctx, "=== Current Attach Position ===")
        reaper.ImGui_Separator(ctx)
        if attach_x and attach_y then
            reaper.ImGui_Text(ctx, string.format("Attach X: %.1f", attach_x))
            reaper.ImGui_Text(ctx, string.format("Attach Y: %.1f", attach_y))
            reaper.ImGui_Text(ctx, string.format("Attach W: %.1f", attach_w or 0))
            
            local x1, y1, x2, y2 = get_video_window_pos()
            if x1 then
                reaper.ImGui_Text(ctx, string.format("Relative to Video Top: %.1f px", attach_y - y1))
            end
        else
            reaper.ImGui_Text(ctx, "Not attached or video window not found")
        end
        
        reaper.ImGui_End(ctx)
    end

end

-- =========================
-- Решта основного циклу
-- =========================
local function loop()
    reaper.ImGui_PushFont(ctx, ui_font, UI_FONT_SCALE)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowBorderSize(), 0)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(), window_bg_color)
    
    local window_flags = reaper.ImGui_WindowFlags_NoScrollbar() | reaper.ImGui_WindowFlags_NoScrollWithMouse()
    if flags.NoTitle then window_flags = window_flags | reaper.ImGui_WindowFlags_NoTitleBar() end
    if flags.NoResize then window_flags = window_flags | reaper.ImGui_WindowFlags_NoResize() end
    if flags.NoDocking then window_flags = window_flags | reaper.ImGui_WindowFlags_NoDocking() end
    if flags.NoMove then window_flags = window_flags | reaper.ImGui_WindowFlags_NoMove() end

    if flags.HideBackground and reaper.ImGui_SetNextWindowBgAlpha then
        reaper.ImGui_SetNextWindowBgAlpha(ctx, 0)
    end

    -- Встановлюємо початковий розмір та позицію вікна (тільки при першому запуску)
    reaper.ImGui_SetNextWindowSize(ctx, win_w, win_h, reaper.ImGui_Cond_FirstUseEver())
    reaper.ImGui_SetNextWindowPos(ctx, win_X, win_Y, reaper.ImGui_Cond_FirstUseEver())
    
    -- Якщо увімкнено прив'язку до відеовікна та користувач НЕ змінює розмір - застосовуємо позиції
    if attach_to_video and not is_user_resizing and check_video_window_moved() then
        reaper.ImGui_SetNextWindowPos(ctx, attach_x, attach_y)
        reaper.ImGui_SetNextWindowSize(ctx, attach_w, win_h)
    end

    local visible, open = reaper.ImGui_Begin(ctx, "SubOverlay", win_open, window_flags)

    if visible then
        local new_win_w, new_win_h = reaper.ImGui_GetWindowSize(ctx)
        
        -- Перевіряємо, чи змінився розмір вікна
        local size_changed = (new_win_w ~= win_w or new_win_h ~= win_h)
        
        -- Визначаємо, чи змінює користувач розмір вікна (затиснута ліва кнопка миші + розмір змінюється)
        local mouse_down = reaper.ImGui_IsMouseDown(ctx, 0)
        
        if size_changed and mouse_down then
            -- Користувач змінює розмір вікна
            is_user_resizing = true
        elseif not mouse_down then
            -- Кнопка миші відпущена - завершуємо ресайз
            if is_user_resizing then
                is_user_resizing = false
                if attach_to_video then
                    video_cache_valid = false -- Інвалідуємо кеш для перерахунку позицій
                    save_settings() -- Зберігаємо висоту вікна для прив'язки до відео
                end
            end
        end
        
        if size_changed then
            win_w, win_h = new_win_w, new_win_h
            if attach_to_video and not is_user_resizing then
                video_cache_valid = false -- Інвалідуємо кеш при зміні розміру
            end
        end
        
        ensure_valid_source_mode()

        
        -- Визначаємо поточну позицію плейхеда/курсора
        local play_state = reaper.GetPlayState()
        local pos = (play_state & 1) == 1 and reaper.GetPlayPosition() or reaper.GetCursorPosition()
        
        -- Перевіряємо, чи потрібно оновлювати дані
        local current, nextreg, start_pos, stop_pos
        local cur_proj_change_count = reaper.GetProjectStateChangeCount(0)
        
        -- FORCE UPDATE EVERY FRAME (Fixes region update lag)
        -- if pos ~= last_pos or cur_proj_change_count ~= last_proj_change_count then
            -- Позиція або проект змінилися - оновлюємо дані
            last_pos = pos
            last_proj_change_count = cur_proj_change_count
            
            if source_mode == 0 then
                current, nextreg, start_pos, stop_pos = get_current_and_next_region_names()
            else
                local tr = reaper.GetTrack(0, source_mode-1)
                if tr then
                    current, nextreg, start_pos, stop_pos = get_current_and_next_items(tr)
                else
                    current, nextreg, start_pos, stop_pos = "", "", 0, 0
                end
            end
            -- Зберігаємо в кеш
            cached_current, cached_next, cached_start, cached_stop = current, nextreg, start_pos, stop_pos
        -- else
            -- -- Позиція не змінилася - використовуємо кеш
            -- current, nextreg, start_pos, stop_pos = cached_current, cached_next, cached_start, cached_stop
        -- end

        -- PARSE TO TOKENS (Handles comments, newlines, etc.)
        local current_tokens = parse_to_tokens(current)
        local next_tokens = parse_to_tokens(nextreg)

        -- ASSIMILATION (Works on tokens)
        -- Use LOCAL setting instead of global ExtState
        if show_assimilation then
            current_tokens = process_assimilation_tokens(current_tokens)
            next_tokens = process_assimilation_tokens(next_tokens)
        end

        local progress = 0.0
        if start_pos and stop_pos and stop_pos > start_pos then
            if pos >= start_pos and pos <= stop_pos then
                local rel = (pos - start_pos) / (stop_pos - start_pos)
                progress = math.max(0, math.min(1, rel))
            end
        end

        -- USE FIXED FONT SCALES (Auto-scaling removed)
        local actual_font_scale = font_scale
        local actual_second_font_scale = second_font_scale

        -- Вертикальне вирівнювання (центр або низ)
        if align_vertical or align_bottom then
            -- Розраховуємо загальну висоту контенту
            local total_height = 0
            
            -- Висота першого рядка - використовуємо функцію підрахунку з урахуванням wrapping
            reaper.ImGui_PushFont(ctx, font_objects[current_font_index] or font_objects[1], actual_font_scale)
            local line_h = reaper.ImGui_GetTextLineHeight(ctx)
            reaper.ImGui_PopFont(ctx)
            
            local current_line_count = calculate_line_count(current_tokens, current_font_index, actual_font_scale, win_w)
            total_height = total_height + (line_h * current_line_count)
            
            -- Висота прогрес-бара (якщо увімкнено)
            if show_progress then
                total_height = total_height + progress_offset + progress_height
            end
            
            -- Висота другого рядка - завжди враховуємо для стабільності
            if enable_second_line then
                reaper.ImGui_PushFont(ctx, font_objects[second_font_index] or font_objects[1], actual_second_font_scale)
                local second_line_h = reaper.ImGui_GetTextLineHeight(ctx)
                reaper.ImGui_PopFont(ctx)
                
                local next_line_count = calculate_line_count(next_tokens, second_font_index, actual_second_font_scale, win_w)
                total_height = total_height + next_region_offset + (second_line_h * next_line_count)
            end
            
            -- Розрахунок позиції Y (округлюємо щоб уникнути "стрибання")
            local start_y = 0
            if align_vertical then
                start_y = math.floor((win_h - total_height) / 2 + 0.5)
            elseif align_bottom then
                start_y = math.floor(win_h - total_height - padding_y * 12 + 0.5)
            end
            start_y = math.max(0, start_y)
            
            reaper.ImGui_SetCursorPosY(ctx, start_y)
        end
        
        -- відображення тексту (використовуємо auto-scaled значення)
            draw_tokens(ctx, current_tokens, current_font_index, actual_font_scale, text_color, shadow_color, win_w, false) -- перший рядок

        -- прогрес-бар
        if show_progress then
            local cur_y = reaper.ImGui_GetCursorPosY(ctx)
            reaper.ImGui_SetCursorPosY(ctx, cur_y + progress_offset)
            if progress > 0 then
                if align_center then
                    reaper.ImGui_SetCursorPosX(ctx, (win_w - progress_width) / 2)
                end
                reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameRounding(), 6)
                reaper.ImGui_ProgressBar(ctx, progress, progress_width, progress_height, "")
                reaper.ImGui_PopStyleVar(ctx)
            else
                -- якщо бар "невидимий" (між регіонами/ітемами)
                reaper.ImGui_Dummy(ctx, progress_width, progress_height)
            end
        end

        if enable_second_line then 
            -- СТАБІЛЬНЕ ВИРІВНЮВАННЯ ПО НИЗУ
            if align_bottom then
                reaper.ImGui_PushFont(ctx, font_objects[second_font_index] or font_objects[1], actual_second_font_scale)
                local second_line_h = reaper.ImGui_GetTextLineHeight(ctx)
                reaper.ImGui_PopFont(ctx)
                local next_line_count = calculate_line_count(next_tokens, second_font_index, actual_second_font_scale, win_w)
                local next_total_h = second_line_h * next_line_count
                
                -- Фіксована позиція для другого рядка відносно низу вікна
                local bottom_y = win_h - next_total_h - padding_y * 12
                reaper.ImGui_SetCursorPosY(ctx, bottom_y)
            else
                local cur_y = reaper.ImGui_GetCursorPosY(ctx)
                reaper.ImGui_SetCursorPosY(ctx, cur_y + next_region_offset) 
            end
            
            draw_tokens(ctx, next_tokens, second_font_index, actual_second_font_scale, second_text_color, second_shadow_color, win_w, true)
        end
        
        win_X, win_Y = reaper.ImGui_GetWindowPos(ctx)
        local hovered = reaper.ImGui_IsWindowHovered(ctx) -- Simplified for maximum compatibility
        
        -- Кнопка закриття в правому верхньому куті
        if flags.NoTitle then
            local button_size = 20
            local button_x = win_w - button_size - 10
            local button_y = 10
            reaper.ImGui_SetCursorPos(ctx, button_x, button_y)
            -- Прозора кнопка з хрестиком
            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x00000000)  -- прозора
            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0xFF000088)  -- червонувата при наведенні
            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), 0xFF0000FF)  -- червона при кліку
            if hovered then
                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xFFFFFFFF)  -- білий при наведенні
            else
                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xFFFFFF00)  -- напівпрозорий
            end
            if reaper.ImGui_Button(ctx, "✕##close", button_size, button_size) then
                close_requested = true
            end
            reaper.ImGui_PopStyleColor(ctx, 4)
        end

        if hovered then
            if reaper.ImGui_IsMouseClicked(ctx, 1, false) then
                reaper.ImGui_SetNextWindowSize(ctx, 200, 0, reaper.ImGui_Cond_Appearing())
                reaper.ImGui_OpenPopup(ctx, "context_menu")
            elseif reaper.ImGui_IsMouseDoubleClicked(ctx, 0) then
                reaper.gmem_write(0, 1) -- Signal EDIT
            end
        end
        
        -- Heartbeat check indicator (small dot)
        local sb_heartbeat = reaper.gmem_read(100)
        local sb_active = (reaper.time_precise() - sb_heartbeat) < 0.5
        if sb_active then
           local dl = reaper.ImGui_GetWindowDrawList(ctx)
           reaper.ImGui_DrawList_AddCircleFilled(dl, win_X + 5, win_Y + 5, 3, 0x00FF00FF)
        end

        -- Відображення напрямних ліній для відступу переносу
        if show_wrap_guides and wrap_margin > 0 then
            local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
            local guide_color = 0x00FFFFFF  -- яскравий бірюзовий (cyan)
            
            -- Ліва лінія
            local left_x = win_X + wrap_margin
            reaper.ImGui_DrawList_AddLine(draw_list, left_x, win_Y, left_x, win_Y + win_h, guide_color, 1.0)
            
            -- Права лінія
            local right_x = win_X + win_w - wrap_margin
            reaper.ImGui_DrawList_AddLine(draw_list, right_x, win_Y, right_x, win_Y + win_h, guide_color, 1.0)
        end
        
        --debug_window()
        draw_context_menu()
        reaper.ImGui_End(ctx)
    end

    reaper.ImGui_PopStyleColor(ctx)
    reaper.ImGui_PopStyleVar(ctx)
    reaper.ImGui_PopFont(ctx)
    
    local continue_running = (open ~= false) and not close_requested
    if continue_running then
        reaper.defer(loop)
    else
        -- скидаємо прапорець на випадок повторного запуску скрипта
        close_requested = false
    end
end


reaper.defer(loop)

