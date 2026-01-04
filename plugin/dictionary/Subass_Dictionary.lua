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
                
                local header_name = string.format("%s (%d)", cat.name, #cat.entries)
                if reaper.ImGui_CollapsingHeader( ctx, header_name, header_flags ) then
                    reaper.ImGui_Indent(ctx, 25)
                    reaper.ImGui_Dummy(ctx, 0, 5)
                    for _, entry in ipairs(cat.entries) do
                        if cat.name == "Асиміляція" or cat.name == "Відмінки" then
                            -- Inline Style
                            reaper.ImGui_PushFont(ctx, font_main, 15)
                            reaper.ImGui_TextColored(ctx, Style.colors.WordHighlight, entry.word)
                            reaper.ImGui_SameLine(ctx)
                            
                            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), Style.colors.MeaningText)
                            reaper.ImGui_Text(ctx, "— " .. entry.meaning)
                            reaper.ImGui_PopStyleColor(ctx)
                            reaper.ImGui_PopFont(ctx)
                        else
                            -- Block Style (Standard)
                            -- Word
                            reaper.ImGui_PushFont(ctx, font_main, 30)
                            reaper.ImGui_TextColored(ctx, Style.colors.WordHighlight, entry.word)
                            reaper.ImGui_PopFont(ctx)

                            -- Meaning
                            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), Style.colors.MeaningText)
                            reaper.ImGui_PushFont(ctx, font_main, 15)

                            reaper.ImGui_PushTextWrapPos(ctx, 0.0)
                            reaper.ImGui_Text(ctx, "— " .. entry.meaning)
                            reaper.ImGui_PopTextWrapPos(ctx)

                            reaper.ImGui_PopFont(ctx)
                            reaper.ImGui_PopStyleColor(ctx)

                            reaper.ImGui_Spacing(ctx)
                            reaper.ImGui_Spacing(ctx)
                        end
                    end
                    reaper.ImGui_Dummy(ctx, 0, 10)
                    reaper.ImGui_Unindent(ctx, 25)
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
