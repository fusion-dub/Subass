-- @description Subass Dictionary
-- @version 1.3
-- @author Fusion (Fusion Dub)
-- @about Dictionary of slang, idioms and terminology for dubbing.

local ctx = reaper.ImGui_CreateContext('Subass Dictionary')
local font_main = reaper.ImGui_CreateFont('sans-serif', 15)
reaper.ImGui_Attach(ctx, font_main)

-- Initial window size
local WIN_W, WIN_H = 600, 500

-- Load dictionary data
local script_path = debug.getinfo(1,'S').source:match([[^@?(.*[\/])]])
-- Global ImGui Style
local Style = dofile(script_path .. "Subass_ReaImGuiGlobalStyle.lua")
local data_file = script_path .. "dictionary_data.lua"
local categories = {}
local cached_results = {}
local last_filter = nil

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

local function loop()
    if not ctx then return end

    reaper.ImGui_SetNextWindowSize(ctx, WIN_W, WIN_H, reaper.ImGui_Cond_FirstUseEver())

    -- APPLY GLOBAL STYLE
    Style.push(ctx)

    local visible, open = reaper.ImGui_Begin(ctx, 'Subass Dictionary', true, reaper.ImGui_WindowFlags_NoScrollbar())

    if visible then
        -- Search
        reaper.ImGui_SetNextItemWidth(ctx, -120)
        local changed, new_filter =
            reaper.ImGui_InputTextWithHint(ctx, '##search', "Пошук виразів...", filter)
        if changed then filter = new_filter end

        reaper.ImGui_SameLine(ctx)
        if reaper.ImGui_Button(ctx, "Оновити", 110) then
            load_data()
        end

        reaper.ImGui_Separator(ctx)

        if filter ~= last_filter then
            update_search_cache(filter)
        end

        -- Content
        if reaper.ImGui_BeginChild(ctx, "content_area") then
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

        reaper.ImGui_End(ctx)
    end

    -- POP GLOBAL STYLE
    Style.pop(ctx)

    if open then
        reaper.defer(loop)
    end
end

reaper.defer(loop)
