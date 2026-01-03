-- @description Subass Dictionary
-- @version 1.2
-- @author Fusion (Fusion Dub)
-- @about Dictionary of slang, idioms and terminology for dubbing.

local ctx = reaper.ImGui_CreateContext('Subass Dictionary')

-- Initial window size
local WIN_W, WIN_H = 600, 500

-- Load dictionary data
local script_path = debug.getinfo(1,'S').source:match([[^@?(.*[\/])]])
local data_file = script_path .. "dictionary_data.lua"
local categories = {}

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
end

load_data()

local filter = ""

function loop()
    if not ctx then return end

    reaper.ImGui_SetNextWindowSize(ctx, WIN_W, WIN_H, reaper.ImGui_Cond_FirstUseEver())
    
    local visible, open = reaper.ImGui_Begin(ctx, 'Subass Dictionary', true, reaper.ImGui_WindowFlags_NoScrollbar())
    if visible then
        -- Search bar
        reaper.ImGui_SetNextItemWidth(ctx, -1)
        local changed, new_filter = reaper.ImGui_InputTextWithHint(ctx, '##search', "Пошук виразів...", filter)
        if changed then filter = new_filter end
        
        reaper.ImGui_Separator(ctx)
        
        -- Main Content Area
        if reaper.ImGui_BeginChild(ctx, "content_area") then
            -- Prepare search term once (UTF-8 case-insensitive)
            local search_term = utf8_lower(filter)
            
            for _, cat in ipairs(categories) do
                local items_to_draw = {}
                for _, entry in ipairs(cat.entries) do
                    if filter == "" or 
                       utf8_lower(entry.word):find(search_term, 1, true) or 
                       utf8_lower(entry.meaning):find(search_term, 1, true) then
                        table.insert(items_to_draw, entry)
                    end
                end

                if #items_to_draw > 0 then
                    if reaper.ImGui_CollapsingHeader(ctx, cat.name, reaper.ImGui_TreeNodeFlags_DefaultOpen()) then
                        for _, entry in ipairs(items_to_draw) do
                            reaper.ImGui_Bullet(ctx)
                            reaper.ImGui_TextColored(ctx, 0xFFCC00FF, entry.word)
                            reaper.ImGui_SameLine(ctx)
                            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xBBBBBBFF)
                            reaper.ImGui_TextWrapped(ctx, " - " .. entry.meaning)
                            reaper.ImGui_PopStyleColor(ctx)
                            reaper.ImGui_Spacing(ctx)
                        end
                    end
                end
            end
            reaper.ImGui_EndChild(ctx)
        end
        
        reaper.ImGui_End(ctx)
    end
    
    if open then
        reaper.defer(loop)
    end
end

reaper.defer(loop)
