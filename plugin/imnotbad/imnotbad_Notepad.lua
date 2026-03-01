-- @description Notepad від imnotbad
-- @version 1.0
-- @author imnotbad

--==============================================================
-- Перевірка ReaImGui та JS_ReaScriptAPI
--==============================================================
if not reaper.ImGui_CreateContext then
    reaper.ShowMessageBox("Встановіть ReaImGui через ReaPack", "Помилка", 0)
    return
end

if not reaper.JS_Dialog_BrowseForSaveFile then
    reaper.ShowMessageBox("Встановіть JS_ReaScriptAPI через ReaPack.", "Попередження", 0)
end
--==============================================================
-- Контекст і дані
--==============================================================
local ctx = reaper.ImGui_CreateContext("Notepad від imnotbad")

local function is_mod_pressed()
    return reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Mod_Ctrl())
        or reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Mod_Super())
end
local tabs                      = {}
local active_tab_index          = 1
local pending_active_tab        = nil
local pomodoro_active           = false
local pomodoro_pending_select   = false
local pomo                      = {
    mode              = "work",
    state             = "idle",
    work_duration     = 25 * 60,
    short_break       = 5 * 60,
    long_break        = 15 * 60,
    remaining         = 25 * 60,
    start_time        = 0,
    elapsed_before    = 0,
    completed         = 0,
    long_break_every  = 4,
    auto_start        = false,
    sound_enabled     = true,
    edit_work         = 25,
    edit_short        = 5,
    edit_long         = 15,
    edit_long_every   = 4,
    session_log       = {},
    total_work_sec    = 0,
    show_settings     = false,
    notification_msg  = nil,
    notification_time = 0,
}
local saved_selection_start     = 0
local saved_selection_end       = 0
local tab_font_size             = 16
local current_font_name         = "Sans-serif"
local font_list                 = { "Arial", "Helvetica", "Calibri", "Roboto", "Segoe UI", "Tahoma", "Verdana",
    "Cambria", "Georgia", "Times New Roman",
    "Consolas", "Courier New", "Comic Sans MS" }
local fonts_storage             = {}
local tab_font                  = nil
local filter_text               = ""
local filter_active             = false
local filter_match_index        = 0
local filter_matches            = {}
local filter_view_match_counter = 0
local text_cursor               = 0
local text_sel_start            = 0
local text_sel_end              = 0
local sel_cache_start           = nil
local sel_cache_end             = nil
local script_path               = ({ reaper.get_action_context() })[2]:match("^.+[\\//]")
local save_file                 = script_path .. "imnotbad_notepad_tabs_data.txt"
local function get_font(name, style)
    if not fonts_storage[name] then return nil end
    return fonts_storage[name][style]
end
--==============================================================
-- СТИЛІЗАЦІЯ
--==============================================================
local STYLE_COLORS = {
    GeneralColor = { 0.46, 0.46, 0.46, 1.0 }
}

local function GetGeneralColorHEX()
    return reaper.ImGui_ColorConvertDouble4ToU32(
        STYLE_COLORS.GeneralColor[1],
        STYLE_COLORS.GeneralColor[2],
        STYLE_COLORS.GeneralColor[3],
        STYLE_COLORS.GeneralColor[4]
    )
end

local function push_style(ctx)
    local main_col = GetGeneralColorHEX()
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowRounding(), 10.0)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameRounding(), 7.0)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_TabRounding(), 5.0)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_PopupRounding(), 8.0)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowTitleAlign(), 0.5, 0.5)

    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(), 0x1A1A1AFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgActive(), 0x1A1A1AFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBg(), 0x1A1A1AFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgCollapsed(), 0x1A1A1AFF)

    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Tab(), 0x2D2D2DFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabHovered(), 0x444444FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabSelected(), main_col)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabSelectedOverline(), 0xFFCC0088)

    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), 0x101010FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgHovered(), 0x202020FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgActive(), 0x252525FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TextSelectedBg(), main_col)

    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x101010FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), main_col)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), main_col)

    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderHovered(), main_col)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderActive(), 0xFFCC00FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Header(), main_col)

    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SliderGrab(), main_col)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SliderGrabActive(), main_col)

    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGrip(), main_col)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripActive(), main_col)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripHovered(), main_col)

    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarBg(), 0x1A1A1A00)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrab(), 0x444444FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabActive(), main_col)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabHovered(), main_col)

    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PopupBg(), 0x1A1A1AFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Separator(), 0x444444FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_CheckMark(), main_col)
end

local function pop_style(ctx)
    reaper.ImGui_PopStyleColor(ctx, 30)
    reaper.ImGui_PopStyleVar(ctx, 5)
end
--==============================================================
-- ШРИФТ
--==============================================================
local function rebuild_tab_font()
    if tab_font then
        reaper.ImGui_Detach(ctx, tab_font)
        tab_font = nil
    end
    tab_font = reaper.ImGui_CreateFont(current_font_name, tab_font_size)
    reaper.ImGui_Attach(ctx, tab_font)
end

--==============================================================
-- MARKDOWN HELPER FUNCTIONS
--==============================================================
local function wrap_selected_range(text, sel_start, sel_end, wrapper)
    if not sel_start or not sel_end or sel_start == sel_end then
        return text
    end

    if sel_start > sel_end then
        sel_start, sel_end = sel_end, sel_start
    end

    local before = text:sub(1, sel_start)
    local selected = text:sub(sel_start + 1, sel_end)
    local after = text:sub(sel_end + 1)

    return before .. wrapper .. selected .. wrapper .. after
end

local function insert_at_line_start(text, cursor_pos, prefix)
    local line_start = text:sub(1, cursor_pos):match(".*\n()") or 1
    local before = text:sub(1, line_start - 1)
    local after = text:sub(line_start)
    return before .. prefix .. after, cursor_pos + #prefix
end

--==============================================================
-- ФІЛЬТРАЦІЯ ТЕКСТУ
--==============================================================
local function utf8_to_lower(str)
    local upper = "АБВГҐДЕЄЖЗИІЇЙКЛМНОПРСТУФХЦЧШЩЬЮЯ"
    local lower = "абвгґдеєжзиіїйклмнопрстуфхцчшщьюя"

    str = str:lower()

    for i = 1, #upper / 2 do
        local u = upper:sub(i * 2 - 1, i * 2)
        local l = lower:sub(i * 2 - 1, i * 2)
        str = str:gsub(u, l)
    end
    return str
end

local function filter_content(text, filter)
    if filter == "" then return text end

    local lines = {}
    local search_query = utf8_to_lower(filter)

    for line in text:gmatch("[^\n]+") do
        local line_lower = utf8_to_lower(line)
        if line_lower:find(search_query, 1, true) then
            table.insert(lines, line)
        end
    end
    return table.concat(lines, "\n")
end

local last_synced = ""
local last_matched_indices = {}

local function split_lines(text)
    local t = {}
    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        table.insert(t, line)
    end
    return t
end

local function build_filtered(full_text, filter_text)
    local full_lines = split_lines(full_text)
    local result = {}
    last_matched_indices = {}

    local search_query = utf8_to_lower(filter_text)

    for i, line in ipairs(full_lines) do
        if utf8_to_lower(line):find(search_query, 1, true) then
            table.insert(result, line)
            table.insert(last_matched_indices, i)
        end
    end

    return table.concat(result, "\n")
end


local last_synced = ""
local function sync_filtered_to_full(full_text, old_filtered, new_filtered)
    if new_filtered == last_synced then return full_text end
    last_synced = new_filtered

    local full_lines = {}
    for line in (full_text .. "\n"):gmatch("([^\n]*)\n") do
        table.insert(full_lines, line)
    end

    local search_query = utf8_to_lower(filter_text)
    local matched_indices = {}
    for i, line in ipairs(full_lines) do
        if utf8_to_lower(line):find(search_query, 1, true) then
            table.insert(matched_indices, i)
        end
    end

    if #matched_indices == 0 then return full_text end
    local new_lines = {}
    for line in (new_filtered .. "\n"):gmatch("([^\n]*)\n") do
        table.insert(new_lines, line)
    end

    local result_lines = {}
    local match_idx_ptr = 1
    local inserted_all_new = false

    for i = 1, #full_lines do
        if match_idx_ptr <= #matched_indices and i == matched_indices[match_idx_ptr] then
            if not inserted_all_new then
                for _, nl in ipairs(new_lines) do
                    table.insert(result_lines, nl)
                end
                inserted_all_new = true
            end
            match_idx_ptr = match_idx_ptr + 1
        else
            table.insert(result_lines, full_lines[i])
        end
    end

    return table.concat(result_lines, "\n")
end

--==============================================================
-- ПАРСИНГ MARKDOWN ДЛЯ ВІДОБРАЖЕННЯ (З ПІДТРИМКОЮ МНОЖИННИХ СТИЛІВ)
--==============================================================
local function parse_line_styles(text)
    local segments = {}
    if not text or text == "" then return segments end

    local pos = 1
    while pos <= #text do
        local start_bold_italic, end_bold_italic = text:find("%*%*%*", pos)
        local start_bold, end_bold = text:find("%*%*", pos)
        local start_italic, end_italic = text:find("%*", pos)
        local start_underline, end_underline = text:find("__", pos)

        local first_pos = math.huge
        local tag_type = nil
        local tag_end = 0
        local tag_len = 0

        if start_bold_italic and start_bold_italic < first_pos then
            first_pos, tag_type, tag_len = start_bold_italic, "bold_italic", 3
        end
        if start_bold and start_bold < first_pos then
            first_pos, tag_type, tag_len = start_bold, "bold", 2
        end
        if start_underline and start_underline < first_pos then
            first_pos, tag_type, tag_len = start_underline, "underline", 2
        end
        if start_italic and start_italic < first_pos and (not start_bold or start_italic < start_bold) then
            first_pos, tag_type, tag_len = start_italic, "italic", 1
        end

        if first_pos == math.huge then
            table.insert(segments, { text = text:sub(pos), bold = false, italic = false, underline = false })
            break
        else
            if first_pos > pos then
                table.insert(segments,
                    { text = text:sub(pos, first_pos - 1), bold = false, italic = false, underline = false })
            end

            local closing_tag = (tag_type == "bold_italic") and "%*%*%*" or
                (tag_type == "bold") and "%*%*" or
                (tag_type == "underline") and "__" or "%*"

            local c_start, c_end = text:find(closing_tag, first_pos + tag_len)

            if c_start then
                local content = text:sub(first_pos + tag_len, c_start - 1)
                table.insert(segments, {
                    text = content,
                    bold = (tag_type == "bold" or tag_type == "bold_italic"),
                    italic = (tag_type == "italic" or tag_type == "bold_italic"),
                    underline = (tag_type == "underline")
                })
                pos = c_end + 1
            else
                table.insert(segments,
                    { text = text:sub(first_pos, first_pos + tag_len - 1), bold = false, italic = false, underline = false })
                pos = first_pos + tag_len
            end
        end
    end

    return segments
end


local function parse_simple_markdown(text)
    local lines = {}
    for line in text:gmatch("[^\n]*") do
        if line ~= "" or #lines > 0 then
            table.insert(lines, line)
        end
    end

    local result = {}

    for _, line in ipairs(lines) do
        if line:match("^%s*%-%-%-%s*$") then
            table.insert(result, { type = "separator" })
            table.insert(result, { type = "newline" })
        elseif line:match("^%s*|.*|%s*$") then
            local cells_data = {}
            for cell_text in line:gmatch("[^|]+") do
                local trimmed_text = cell_text:match("^%s*(.-)%s*$")
                local styled_segments = parse_line_styles(trimmed_text)
                table.insert(cells_data, styled_segments)
            end

            local is_header = false
            if #result == 0 or (result[#result].type ~= "table_row" and result[#result].type ~= "newline") then
                is_header = true
            elseif result[#result].type == "newline" and #result > 1 and result[#result - 1].type ~= "table_row" then
                is_header = true
            end

            table.insert(result, { type = "table_row", cells = cells_data, is_header = is_header })
            table.insert(result, { type = "newline" })
        elseif line:match("^(%s*)%[([%sxX])%]%s*(.*)$") then
            local checkbox_indent, checkbox_state, checkbox_text = line:match("^(%s*)%[([%sxX])%]%s*(.*)$")
            table.insert(result, {
                type = "checkbox",
                text = checkbox_text,
                checked = (checkbox_state:lower() == "x"),
                indent = checkbox_indent,
                line = line
            })
            table.insert(result, { type = "newline" })
        else
            local header_level = line:match("^(#+)%s")
            if header_level then
                local header_text = line:match("^#+%s+(.+)$") or ""
                local level = #header_level
                table.insert(result, {
                    type = "header",
                    level = level,
                    text = header_text
                })
                table.insert(result, { type = "newline" })
            else
                local i = 1
                local len = #line

                while i <= len do
                    local styles = {}
                    local start_pos = i
                    local found_format = false

                    while true do
                        if line:sub(i, i + 1) == "**" then
                            table.insert(styles, { type = "bold", marker = "**", len = 2 })
                            i = i + 2
                            found_format = true
                        elseif line:sub(i, i + 1) == "__" then
                            table.insert(styles, { type = "underline", marker = "__", len = 2 })
                            i = i + 2
                            found_format = true
                        elseif line:sub(i, i) == "*" then
                            table.insert(styles, { type = "italic", marker = "*", len = 1 })
                            i = i + 1
                            found_format = true
                        else
                            break
                        end
                    end

                    if found_format and #styles > 0 then
                        local content_start = i
                        local min_close = nil

                        for s = #styles, 1, -1 do
                            local marker = styles[s].marker
                            local close = line:find(marker, i, true)
                            if close then
                                if not min_close or close < min_close then
                                    min_close = close
                                end
                            else
                                found_format = false
                                break
                            end
                        end

                        if found_format and min_close then
                            local temp_pos = min_close
                            local all_closed = true
                            for s = #styles, 1, -1 do
                                local marker = styles[s].marker
                                if line:sub(temp_pos, temp_pos + #marker - 1) == marker then
                                    temp_pos = temp_pos + #marker
                                else
                                    all_closed = false
                                    break
                                end
                            end

                            if all_closed then
                                local formatted_text = line:sub(content_start, min_close - 1)
                                table.insert(result, {
                                    type = "multi_style",
                                    styles = styles,
                                    text = formatted_text
                                })
                                i = temp_pos
                            else
                                table.insert(result, { type = "text", text = line:sub(start_pos, start_pos) })
                                i = start_pos + 1
                            end
                        else
                            table.insert(result, { type = "text", text = line:sub(start_pos, start_pos) })
                            i = start_pos + 1
                        end
                    else
                        local next_special = #line + 1
                        local star2 = line:find("%*%*", i)
                        local star1 = line:find("%*", i)
                        local under = line:find("__", i)

                        if star2 then next_special = math.min(next_special, star2) end
                        if star1 then next_special = math.min(next_special, star1) end
                        if under then next_special = math.min(next_special, under) end

                        if next_special > i then
                            table.insert(result, { type = "text", text = line:sub(i, next_special - 1) })
                            i = next_special
                        else
                            i = i + 1
                        end
                    end
                end
                table.insert(result, { type = "newline" })
            end
        end
    end

    return result
end

local function insert_markdown(text, wrapper)
    if text == "" or text:sub(-1) == "\n" then
        return text .. wrapper .. wrapper
    else
        return text .. "\n" .. wrapper .. wrapper
    end
end

local function rebuild_all_fonts()
    for name, styles in pairs(fonts_storage) do
        for _, font_obj in pairs(styles) do
            reaper.ImGui_Detach(ctx, font_obj)
        end
    end

    fonts_storage = {}

    for _, name in ipairs(font_list) do
        fonts_storage[name] = {
            regular = reaper.ImGui_CreateFont(name, tab_font_size),
            bold    = reaper.ImGui_CreateFont(name, reaper.ImGui_FontFlags_Bold()),
            italic  = reaper.ImGui_CreateFont(name, reaper.ImGui_FontFlags_Italic()),
            bold_it = reaper.ImGui_CreateFont(name, reaper.ImGui_FontFlags_Bold() | reaper.ImGui_FontFlags_Italic())
        }

        reaper.ImGui_Attach(ctx, fonts_storage[name].regular)
        reaper.ImGui_Attach(ctx, fonts_storage[name].bold)
        reaper.ImGui_Attach(ctx, fonts_storage[name].italic)
        reaper.ImGui_Attach(ctx, fonts_storage[name].bold_it)
    end
end


--==============================================================
-- МАРКЕРИ
--==============================================================
local function get_reaper_markers_text()
    local _, num_markers, num_regions = reaper.CountProjectMarkers(0)
    local markers_list = {}

    for i = 0, num_markers + num_regions - 1 do
        local retval, isrgn, pos, rgnend, name, markindex = reaper.EnumProjectMarkers(i)
        if not isrgn then
            local time_str = reaper.format_timestr_pos(pos, "", 0)
            table.insert(markers_list,
                string.format("[%s] - %s", time_str, name ~= "" and name or "Маркер " .. markindex))
        end
    end

    if #markers_list == 0 then return nil end
    return table.concat(markers_list, "\n")
end

local function go_to_time(time_str)
    local clean_time = time_str:match("%[(.-)%]") or time_str
    local seconds = reaper.parse_timestr_pos(clean_time, 0)
    if seconds then
        reaper.SetEditCurPos(seconds, true, false)
    end
end

--==============================================================
-- POMODORO ЗВУК
--==============================================================
local function play_sound()
    local info = debug.getinfo(1, 'S')
    local script_path = info.source:match("@?(.*[\\/])")
    local snd_path = script_path .. "imnotbad_Notepad_Alarm.wav"
    if not reaper.CF_CreatePreview then
        reaper.ShowMessageBox("SWS Extension не знайдено!", "Error", 0)
        return
    end
    local pcm_source = reaper.PCM_Source_CreateFromFile(snd_path) 
    if pcm_source then
        local preview = reaper.CF_CreatePreview(pcm_source) 
        if preview then
            if reaper.CF_Preview_StopAll then reaper.CF_Preview_StopAll() end
            reaper.CF_Preview_Play(preview)
            _G.active_sound_preview = preview
        else
            reaper.ShowConsoleMsg("SWS: Не вдалося створити Preview\n")
        end
    else
        reaper.ShowConsoleMsg("Файл не знайдено: " .. snd_path .. "\n")
    end
end

--==============================================================
-- ЗБЕРЕЖЕННЯ
--==============================================================
local EXT_STATE_SECTION = "imnotbad_Notepad"

local function save_font_settings()
    reaper.SetExtState(EXT_STATE_SECTION, "font_size", tostring(tab_font_size), true)
    reaper.SetExtState(EXT_STATE_SECTION, "font_name", current_font_name, true)
    local c = STYLE_COLORS.GeneralColor
    reaper.SetExtState(EXT_STATE_SECTION, "style_color",
        string.format("%.3f,%.3f,%.3f,%.3f", c[1], c[2], c[3], c[4]), true)
end

local function save_pomo_stats()
    reaper.SetExtState(EXT_STATE_SECTION, "pomo_completed", tostring(pomo.completed), true)
    reaper.SetExtState(EXT_STATE_SECTION, "pomo_total_work", tostring(pomo.total_work_sec), true)
    reaper.SetExtState(EXT_STATE_SECTION, "pomo_work_dur", tostring(pomo.edit_work), true)
    reaper.SetExtState(EXT_STATE_SECTION, "pomo_short_dur", tostring(pomo.edit_short), true)
    reaper.SetExtState(EXT_STATE_SECTION, "pomo_long_dur", tostring(pomo.edit_long), true)
    reaper.SetExtState(EXT_STATE_SECTION, "pomo_long_every", tostring(pomo.long_break_every), true)
    reaper.SetExtState(EXT_STATE_SECTION, "pomo_auto_start", pomo.auto_start and "1" or "0", true)
    reaper.SetExtState(EXT_STATE_SECTION, "pomo_sound", pomo.sound_enabled and "1" or "0", true)
    local log_parts = {}
    for _, e in ipairs(pomo.session_log) do
        table.insert(log_parts, e.mode .. "|" .. tostring(e.duration_sec) .. "|" .. e.completed_at)
    end
    reaper.SetExtState(EXT_STATE_SECTION, "pomo_log", table.concat(log_parts, ";"), true)
end

local function save_data()
    save_font_settings()
    save_pomo_stats()
    reaper.SetExtState(EXT_STATE_SECTION, "active_tab", tostring(active_tab_index), true)
    reaper.SetExtState(EXT_STATE_SECTION, "pomodoro_active", pomodoro_active and "1" or "0", true)
    local f = io.open(save_file, "w")
    if f then
        for _, tab in ipairs(tabs) do
            f:write("[TAB_TITLE]" .. tab.title .. "\n")
            f:write("[TAB_CONTENT]" .. tab.content .. "\n")
            f:write("[TAB_END]\n")
        end
        f:close()
    end
end

--==============================================================
-- ЗАВАНТАЖЕННЯ
--==============================================================
local function load_font_settings()
    local saved_size = reaper.GetExtState(EXT_STATE_SECTION, "font_size")
    if saved_size and saved_size ~= "" then
        tab_font_size = tonumber(saved_size) or tab_font_size
    end

    local saved_font = reaper.GetExtState(EXT_STATE_SECTION, "font_name")
    if saved_font and saved_font ~= "" then
        for _, name in ipairs(font_list) do
            if name == saved_font then
                current_font_name = saved_font
                break
            end
        end
    end

    local saved_color = reaper.GetExtState(EXT_STATE_SECTION, "style_color")
    if saved_color and saved_color ~= "" then
        local r, g, b, a = saved_color:match("([^,]+),([^,]+),([^,]+),([^,]+)")
        if r and g and b and a then
            STYLE_COLORS.GeneralColor = { tonumber(r), tonumber(g), tonumber(b), tonumber(a) }
        end
    end
end

local function load_data()
    load_font_settings()
    local f = io.open(save_file, "r")
    if f then
        local all = f:read("*all")
        f:close()

        for title, text in all:gmatch("%[TAB_TITLE%](.-)\n%[TAB_CONTENT%](.-)\n%[TAB_END%]") do
            table.insert(tabs, {
                title = title,
                content = text,
                editing = false,
                renaming = false
            })
        end
    end

    local saved_idx = tonumber(reaper.GetExtState(EXT_STATE_SECTION, "active_tab")) or 1
    if saved_idx >= 1 and saved_idx <= #tabs then
        pending_active_tab = saved_idx
    end

    local saved_pomodoro = reaper.GetExtState(EXT_STATE_SECTION, "pomodoro_active")
    if saved_pomodoro == "1" then
        pomodoro_pending_select = true
    end

    local sv_completed = tonumber(reaper.GetExtState(EXT_STATE_SECTION, "pomo_completed"))
    if sv_completed then pomo.completed = sv_completed end

    local sv_total = tonumber(reaper.GetExtState(EXT_STATE_SECTION, "pomo_total_work"))
    if sv_total then pomo.total_work_sec = sv_total end

    local sv_work = tonumber(reaper.GetExtState(EXT_STATE_SECTION, "pomo_work_dur"))
    if sv_work then
        pomo.edit_work     = sv_work
        pomo.work_duration = sv_work * 60
        pomo.remaining     = pomo.work_duration
    end

    local sv_short = tonumber(reaper.GetExtState(EXT_STATE_SECTION, "pomo_short_dur"))
    if sv_short then
        pomo.edit_short  = sv_short
        pomo.short_break = sv_short * 60
    end

    local sv_long = tonumber(reaper.GetExtState(EXT_STATE_SECTION, "pomo_long_dur"))
    if sv_long then
        pomo.edit_long  = sv_long
        pomo.long_break = sv_long * 60
    end

    local sv_every = tonumber(reaper.GetExtState(EXT_STATE_SECTION, "pomo_long_every"))
    if sv_every then pomo.long_break_every = sv_every end

    local sv_auto = reaper.GetExtState(EXT_STATE_SECTION, "pomo_auto_start")
    if sv_auto ~= "" then pomo.auto_start = (sv_auto == "1") end

    local sv_sound = reaper.GetExtState(EXT_STATE_SECTION, "pomo_sound")
    if sv_sound ~= "" then pomo.sound_enabled = (sv_sound == "1") end

    local sv_log = reaper.GetExtState(EXT_STATE_SECTION, "pomo_log")
    if sv_log and sv_log ~= "" then
        for entry_str in sv_log:gmatch("[^;]+") do
            local mode, dur, time_str = entry_str:match("([^|]+)|([^|]+)|([^|]+)")
            if mode and dur and time_str then
                table.insert(pomo.session_log, {
                    mode         = mode,
                    duration_sec = tonumber(dur) or 0,
                    completed_at = time_str
                })
            end
        end
    end
    if #tabs == 0 then
        local welcome_content = [[# ПРИВІТАЛЬНА СТОРІНКА
*Для редагування зробіть подвійний клік миші по тексту.*
*Більше інформації у вкладці "Довідка".*
---
# Заголовок 1
## Заголовок 2
### Заголовок 3
---
***ПЕРЕЛІК ЗАВДАНЬ:***
[x] Завдання 1
[ ] Завдання 2
[ ] Завдання 3
---
Звичайний
**Жирний**
*Курсив*
__Підкреслений__
[ ] ***__Всі стилі разом__***
---
|Таблиця 1|Таблиця 1|Таблиця 1|Таблиця 1|
|Рядок 1|Рядок 1|Рядок 1|Рядок 1|
|Рядок 2|Рядок 2|Рядок 2|Рядок 2|
---
*Імпорт маркерів:*
[ ] [4:55.279] - Маркер 1
[ ] [9:41.110] - Маркер 2
[ ] [13:42.059] - Маркер 3
---
https://www.youtube.com/ - посилання відкриваються в браузері
---]]
        tabs[1] = { title = "Нотатник 1", content = welcome_content, editing = false, renaming = false }
    end

    rebuild_tab_font()
    rebuild_all_fonts()
end

load_data()
local last_save_time = reaper.time_precise()
local bold_font = nil
local italic_font = nil
local bold_italic_font = nil

local function rebuild_format_fonts()
    if bold_font then
        reaper.ImGui_Detach(ctx, bold_font)
        bold_font = nil
    end
    if italic_font then
        reaper.ImGui_Detach(ctx, italic_font)
        italic_font = nil
    end
    if bold_italic_font then
        reaper.ImGui_Detach(ctx, bold_italic_font)
        bold_italic_font = nil
    end

    bold_font = reaper.ImGui_CreateFont(current_font_name, reaper.ImGui_FontFlags_Bold())
    italic_font = reaper.ImGui_CreateFont(current_font_name, reaper.ImGui_FontFlags_Italic())
    bold_italic_font = reaper.ImGui_CreateFont(current_font_name,
        reaper.ImGui_FontFlags_Bold() | reaper.ImGui_FontFlags_Italic())

    reaper.ImGui_Attach(ctx, bold_font)
    reaper.ImGui_Attach(ctx, italic_font)
    reaper.ImGui_Attach(ctx, bold_italic_font)
end

rebuild_format_fonts()

--==============================================================
-- ЕКСПОРТ ТА ІМПОРТ
--==============================================================
local last_export_path = ""
local last_import_path = ""

local function strip_markdown(text)
    local result = {}
    for line in text:gmatch("[^\n]*\n?") do
        --  line = line:gsub("^#+%s+(.+)", "%1")
        --  line = line:gsub("%*%*%*(.-)%*%*%*", "%1")
        --  line = line:gsub("%*%*(.-)%*%*", "%1")
        --  line = line:gsub("%*(.-)%*", "%1")
        --  line = line:gsub("__(.-)__", "%1")
        --  line = line:gsub("^(%s*)%[x%]%s*", "%1")
        --  line = line:gsub("^(%s*)%[X%]%s*", "%1")
        --  line = line:gsub("^(%s*)%[ %]%s*", "%1")

        table.insert(result, line)
    end
    return table.concat(result, "")
end

local function export_active_tab(tab_index)
    if not tabs[tab_index] then return end

    local tab = tabs[tab_index]
    local clean_text = strip_markdown(tab.content)

    local default_path = last_export_path
    if default_path == "" then
        default_path = reaper.GetProjectPath("") .. "/" .. tab.title .. ".txt"
    end

    local retval, filename = reaper.JS_Dialog_BrowseForSaveFile("Зберегти як", default_path, tab.title .. ".txt",
        "Text files (*.txt)\0*.txt\0All files (*.*)\0*.*\0")

    if retval == 1 and filename ~= "" then
        if not filename:match("%.txt$") then
            filename = filename .. ".txt"
        end

        local file = io.open(filename, "w")
        if file then
            file:write(clean_text)
            file:close()
            last_export_path = filename:match("^(.+[/\\])")
        else
            reaper.ShowMessageBox("Помилка при збереженні файлу!", "Помилка", 0)
        end
    end
end

local function import_text_file()
    local default_path = last_import_path
    if default_path == "" then
        default_path = reaper.GetProjectPath("")
    end

    local retval, filename = reaper.JS_Dialog_BrowseForOpenFiles("Імпортувати текстовий файл", default_path, "",
        "Text files (*.txt)\0*.txt\0All files (*.*)\0*.*\0", false)

    if retval == 1 and filename ~= "" then
        local file = io.open(filename, "r")
        if file then
            local content = file:read("*all")
            file:close()
            last_import_path = filename:match("^(.+[/\\])")
            local file_name = filename:match("([^/\\]+)%.txt$") or filename:match("([^/\\]+)$") or "Імпорт"
            local target_tab = nil
            for i, tab in ipairs(tabs) do
                if tab.content == "" then
                    target_tab = i
                    break
                end
            end

            if not target_tab then
                table.insert(tabs, {
                    title = file_name,
                    content = content,
                    editing = false,
                    renaming = false,
                    should_focus = true
                })
            else
                tabs[target_tab].content = content
                tabs[target_tab].title = file_name
                tabs[target_tab].should_focus = true
            end
        else
            reaper.ShowMessageBox("Помилка при читанні файлу!", "Помилка", 0)
        end
    end
end
--==============================================================
-- ТОКЕНІЗАТОР
--==============================================================
local function segments_to_word_tokens(segments, is_checked)
    local tokens = {}
    for _, seg in ipairs(segments) do
        local text = seg.text or ""
        if text == "" then goto continue_seg end
        local bold      = seg.bold or false
        local italic    = seg.italic or false
        local underline = seg.underline or false
        if seg.styles then
            for _, s in ipairs(seg.styles) do
                if s.type == "bold" then bold = true end
                if s.type == "italic" then italic = true end
                if s.type == "underline" then underline = true end
            end
        end
        local is_time = text:find("%[%d+[:%d%.]*%]") ~= nil
        local pos = 1
        while pos <= #text do
            local word_start = pos
            while pos <= #text and text:sub(pos, pos) ~= ' ' do
                pos = pos + 1
            end
            local word = text:sub(word_start, pos - 1)
            if word ~= "" then
                local is_link = word:match("^https?://") ~= nil
                table.insert(tokens, {
                    text       = word,
                    bold       = bold,
                    italic     = italic,
                    underline  = underline,
                    is_checked = is_checked,
                    is_time    = is_time and word:find("%[%d+[:%d%.]*%]") ~= nil,
                    is_link    = is_link
                })
            end
            while pos <= #text and text:sub(pos, pos) == ' ' do
                pos = pos + 1
            end
        end
        ::continue_seg::
    end
    return tokens
end

--==============================================================
-- РЕНДЕР ТОКЕНІВ
--==============================================================
local function render_line_tokens(ctx, tokens, line_start_x, wrap_end_x, window_left_x, override_start_y)
    if #tokens == 0 then return end
    local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
    local main_col  = GetGeneralColorHEX()
    reaper.ImGui_PushFont(ctx, tab_font, tab_font_size)
    local line_h  = reaper.ImGui_GetTextLineHeight(ctx)
    local space_w = reaper.ImGui_CalcTextSize(ctx, " ")
    reaper.ImGui_PopFont(ctx)
    local start_screen_x, start_screen_y = reaper.ImGui_GetCursorScreenPos(ctx)
    local avail_w = reaper.ImGui_GetContentRegionAvail(ctx)
    if not wrap_end_x then
        wrap_end_x = start_screen_x + avail_w
    end
    window_left_x = window_left_x or line_start_x
    local function token_width(tok)
        local font
        if tok.bold and tok.italic then
            font = get_font(current_font_name, "bold_it") or tab_font
        elseif tok.bold then
            font = get_font(current_font_name, "bold") or tab_font
        elseif tok.italic then
            font = get_font(current_font_name, "italic") or tab_font
        else
            font = tab_font
        end
        local txt = tok.is_time and tok.text:gsub("[%[%]]", "") or tok.text
        reaper.ImGui_PushFont(ctx, font, tab_font_size)
        local w = reaper.ImGui_CalcTextSize(ctx, txt)
        reaper.ImGui_PopFont(ctx)
        return w, font
    end

    local lines = { {} }
    local cur_w = 0
    local first_line_width = wrap_end_x - line_start_x
    local other_line_width = wrap_end_x - window_left_x

    for _, tok in ipairs(tokens) do
        local w = token_width(tok)
        local needed = (cur_w > 0) and (cur_w + space_w + w) or w
        local avail = (#lines == 1) and first_line_width or other_line_width
        if cur_w > 0 and needed > avail then
            table.insert(lines, {})
            cur_w = 0
        end
        table.insert(lines[#lines], tok)
        cur_w = (cur_w > 0) and (cur_w + space_w + w) or w
    end

    local base_cursor_x, base_cursor_y = reaper.ImGui_GetCursorPos(ctx)
    for line_index, line in ipairs(lines) do
        local indent = (line_index == 1)
            and (line_start_x - start_screen_x)
            or (window_left_x - start_screen_x)
        reaper.ImGui_SetCursorPosX(ctx, base_cursor_x + indent)
        for i, tok in ipairs(line) do
            local w, font = token_width(tok)
            reaper.ImGui_PushFont(ctx, font, tab_font_size)
            if filter_active and filter_text ~= "" then
                local tok_lc     = utf8_to_lower(tok.text)
                local search_lc  = utf8_to_lower(filter_text)
                local hx, hy     = reaper.ImGui_GetCursorScreenPos(ctx)
                local search_pos = 1
                while true do
                    local ms, me = tok_lc:find(search_lc, search_pos, true)
                    if not ms then break end
                    filter_view_match_counter = filter_view_match_counter + 1
                    local x_before            = reaper.ImGui_CalcTextSize(ctx, tok.text:sub(1, ms - 1))
                    local x_matched           = reaper.ImGui_CalcTextSize(ctx, tok.text:sub(ms, me))
                    local col                 = (filter_view_match_counter == filter_match_index) and 0x93f67b60 or
                        0xf6de7b77
                    reaper.ImGui_DrawList_AddRectFilled(draw_list,
                        hx + x_before, hy,
                        hx + x_before + x_matched, hy + line_h,
                        col)
                    search_pos = me + 1
                end
            end
            if tok.is_link then
                reaper.ImGui_TextColored(ctx, main_col, tok.text)
                if reaper.ImGui_IsItemHovered(ctx) then
                    reaper.ImGui_SetMouseCursor(ctx, reaper.ImGui_MouseCursor_Hand())
                    if reaper.ImGui_IsItemClicked(ctx, 0) then
                        reaper.CF_ShellExecute(tok.text)
                    end
                end
            elseif tok.is_time then
                local display = tok.text:gsub("[%[%]]", "")
                if tok.is_checked then
                    reaper.ImGui_TextColored(ctx, 0x888888FF, display)
                else
                    local r, g, b, a = table.unpack(STYLE_COLORS.GeneralColor)
                    reaper.ImGui_TextColored(
                        ctx,
                        reaper.ImGui_ColorConvertDouble4ToU32(r, g, b, a),
                        display
                    )
                    if reaper.ImGui_IsItemHovered(ctx) then
                        reaper.ImGui_SetMouseCursor(ctx, reaper.ImGui_MouseCursor_Hand())
                        if reaper.ImGui_IsItemClicked(ctx, 0) then
                            go_to_time(tok.text)
                        end
                    end
                end
            elseif tok.is_checked then
                reaper.ImGui_TextColored(ctx, 0x888888FF, tok.text)
            else
                reaper.ImGui_Text(ctx, tok.text)
            end
            reaper.ImGui_PopFont(ctx)
            if tok.underline then
                local ix, iy = reaper.ImGui_GetItemRectMin(ctx)
                local ex, ey = reaper.ImGui_GetItemRectMax(ctx)
                reaper.ImGui_DrawList_AddLine(draw_list, ix, ey, ex, ey, main_col, 2.0)
            end
            if i < #line then
                reaper.ImGui_SameLine(ctx, nil, space_w)
            end
        end
    end
end

--==============================================================
-- ФУНКЦІЯ ДЛЯ ПРАВИЛЬНОГО ПЕРЕНОСУ ТЕКСТУ ЗІ СТИЛЯМИ
--==============================================================
local function render_text_with_wrapping(ctx, text, font, font_size, has_underline, is_checked, is_time_clickable)
    local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
    local start_x, start_y = reaper.ImGui_GetCursorScreenPos(ctx)
    local wrap_width = reaper.ImGui_GetContentRegionAvail(ctx)
    local line_height = reaper.ImGui_GetTextLineHeightWithSpacing(ctx)
    local main_col = GetGeneralColorHEX()
    local line_color = main_col
    local thickness = 2.0

    local words = {}
    for word in text:gmatch("%S+%s*") do
        table.insert(words, word)
    end

    if #words == 0 then
        if text ~= "" then
            reaper.ImGui_Text(ctx, text)
        end
        return
    end

    local current_line = ""
    local y_offset = 0
    local line_words = {}

    for i, word in ipairs(words) do
        local test_line = current_line .. word
        local test_w = reaper.ImGui_CalcTextSize(ctx, test_line)

        if test_w > wrap_width and current_line ~= "" then
            reaper.ImGui_SetCursorScreenPos(ctx, start_x, start_y + y_offset)

            if is_time_clickable then
                local line_text = current_line
                local last_pos = 1
                local had_content = false

                for time_match in line_text:gmatch("(%[%d+[:%d%.]*%])") do
                    local s_pos, e_pos = line_text:find(time_match, last_pos, true)
                    if s_pos then
                        local before_text = line_text:sub(last_pos, s_pos - 1)
                        if before_text ~= "" then
                            if had_content then reaper.ImGui_SameLine(ctx, nil, 0) end
                            if is_checked then
                                reaper.ImGui_TextColored(ctx, 0x888888FF, before_text)
                            else
                                reaper.ImGui_Text(ctx, before_text)
                            end
                            had_content = true
                        end

                        if had_content then reaper.ImGui_SameLine(ctx, nil, 0) end
                        local display_time = time_match:gsub("[%[%]]", "")

                        if is_checked then
                            reaper.ImGui_TextColored(ctx, 0x888888FF, display_time)
                        else
                            local r, g, b, a = table.unpack(STYLE_COLORS.GeneralColor)
                            reaper.ImGui_TextColored(ctx, reaper.ImGui_ColorConvertDouble4ToU32(r, g, b, a), display_time)
                            if reaper.ImGui_IsItemHovered(ctx) then
                                reaper.ImGui_SetMouseCursor(ctx, reaper.ImGui_MouseCursor_Hand())
                                if reaper.ImGui_IsItemClicked(ctx, 0) then
                                    go_to_time(time_match)
                                end
                            end
                        end
                        had_content = true
                        last_pos = e_pos + 1
                    end
                end

                local final_text = line_text:sub(last_pos)
                if final_text ~= "" then
                    if had_content then reaper.ImGui_SameLine(ctx, nil, 0) end
                    if is_checked then
                        reaper.ImGui_TextColored(ctx, 0x888888FF, final_text)
                    else
                        reaper.ImGui_Text(ctx, final_text)
                    end
                elseif not had_content then
                    if is_checked then
                        reaper.ImGui_TextColored(ctx, 0x888888FF, line_text)
                    else
                        reaper.ImGui_Text(ctx, line_text)
                    end
                end
            else
                if is_checked then
                    reaper.ImGui_TextColored(ctx, 0x888888FF, current_line)
                else
                    reaper.ImGui_Text(ctx, current_line)
                end
            end

            if has_underline then
                local line_w = reaper.ImGui_CalcTextSize(ctx, current_line)
                local underline_y = start_y + y_offset + line_height - 2

                reaper.ImGui_DrawList_AddLine(draw_list,
                    start_x,
                    underline_y,
                    start_x + line_w,
                    underline_y,
                    line_color,
                    thickness)
            end

            y_offset = y_offset + line_height
            current_line = word
        else
            current_line = test_line
        end
    end

    if current_line ~= "" then
        reaper.ImGui_SetCursorScreenPos(ctx, start_x, start_y + y_offset)

        if is_time_clickable then
            local line_text = current_line
            local last_pos = 1
            local had_content = false

            for time_match in line_text:gmatch("(%[%d+[:%d%.]*%])") do
                local s_pos, e_pos = line_text:find(time_match, last_pos, true)
                if s_pos then
                    local before_text = line_text:sub(last_pos, s_pos - 1)
                    if before_text ~= "" then
                        if had_content then reaper.ImGui_SameLine(ctx, nil, 0) end
                        if is_checked then
                            reaper.ImGui_TextColored(ctx, 0x888888FF, before_text)
                        else
                            reaper.ImGui_Text(ctx, before_text)
                        end
                        had_content = true
                    end

                    if had_content then reaper.ImGui_SameLine(ctx, nil, 0) end
                    local display_time = time_match:gsub("[%[%]]", "")

                    if is_checked then
                        reaper.ImGui_TextColored(ctx, 0x888888FF, display_time)
                    else
                        local r, g, b, a = table.unpack(STYLE_COLORS.GeneralColor)
                        reaper.ImGui_TextColored(ctx, reaper.ImGui_ColorConvertDouble4ToU32(r, g, b, a), display_time)
                        if reaper.ImGui_IsItemHovered(ctx) then
                            reaper.ImGui_SetMouseCursor(ctx, reaper.ImGui_MouseCursor_Hand())
                            if reaper.ImGui_IsItemClicked(ctx, 0) then
                                go_to_time(time_match)
                            end
                        end
                    end
                    had_content = true
                    last_pos = e_pos + 1
                end
            end

            local final_text = line_text:sub(last_pos)
            if final_text ~= "" then
                if had_content then reaper.ImGui_SameLine(ctx, nil, 0) end
                if is_checked then
                    reaper.ImGui_TextColored(ctx, 0x888888FF, final_text)
                else
                    reaper.ImGui_Text(ctx, final_text)
                end
            elseif not had_content then
                if is_checked then
                    reaper.ImGui_TextColored(ctx, 0x888888FF, line_text)
                else
                    reaper.ImGui_Text(ctx, line_text)
                end
            end
        else
            if is_checked then
                reaper.ImGui_TextColored(ctx, 0x888888FF, current_line)
            else
                reaper.ImGui_Text(ctx, current_line)
            end
        end

        if has_underline then
            local line_w = reaper.ImGui_CalcTextSize(ctx, current_line)
            local underline_y = start_y + y_offset + line_height - 2

            reaper.ImGui_DrawList_AddLine(draw_list,
                start_x,
                underline_y,
                start_x + line_w,
                underline_y,
                line_color,
                thickness)
        end

        y_offset = y_offset + line_height
    end

    reaper.ImGui_SetCursorScreenPos(ctx, start_x, start_y + y_offset)
end

--==============================================================
-- АВТОЗАПУСК
--==============================================================
local function get_script_full_path()
    local _, filename = reaper.get_action_context()
    return filename
end

local function is_startup_enabled()
    local resource_path = reaper.GetResourcePath()
    local startup_path = resource_path:gsub("\\", "/") .. "/Scripts/__startup.lua"
    local f = io.open(startup_path, "r")
    if not f then return false end
    local content = f:read("*all")
    f:close()
    return content:find("-- imnotbad_Notepad Startup Start", 1, true) ~= nil
end

local function toggle_reaper_startup(enable)
    local resource_path = reaper.GetResourcePath()
    local startup_path = resource_path:gsub("\\", "/") .. "/Scripts/__startup.lua"
    local full_path = get_script_full_path():gsub("\\", "/")

    if full_path == "" then return false end

    local lines = {}
    local f = io.open(startup_path, "r")
    if f then
        for line in f:lines() do table.insert(lines, line) end
        f:close()
    end

    local new_lines = {}
    local skip = false
    local tag_start = "-- imnotbad_Notepad Startup Start"
    local tag_end = "-- imnotbad_Notepad Startup End"

    for _, line in ipairs(lines) do
        if line:find(tag_start, 1, true) then
            skip = true
        elseif line:find(tag_end, 1, true) then
            skip = false
        elseif not skip then
            if not line:find("imnotbad_Notepad.lua", 1, true) then
                table.insert(new_lines, line)
            end
        end
    end

    if enable then
        local cmd_id = nil
        local kb_path = resource_path .. "/reaper-kb.ini"
        local f_kb = io.open(kb_path, "r")
        if f_kb then
            local escaped_path = full_path:gsub("([%%%^%$%(%)%.%[%]%*%+%-%?])", "%%%1")
            for line in f_kb:lines() do
                if line:find(escaped_path) then
                    local rs_part = line:match("RS([%a%d]+)")
                    if rs_part then
                        cmd_id = "_RS" .. rs_part
                        break
                    end
                end
            end
            f_kb:close()
        end

        local launch_cmd
        if cmd_id then
            launch_cmd = string.format(
                "reaper.defer(function() reaper.Main_OnCommand(reaper.NamedCommandLookup(\"%s\"), 0) end)", cmd_id)
        else
            launch_cmd = string.format("reaper.defer(function() dofile([[%s]]) end)", full_path)
        end

        table.insert(new_lines, 1, tag_end)
        table.insert(new_lines, 1, launch_cmd)
        table.insert(new_lines, 1, tag_start)
    end

    local f_out = io.open(startup_path, "w")
    if f_out then
        for i, line in ipairs(new_lines) do
            f_out:write(line .. (i == #new_lines and "" or "\n"))
        end
        f_out:close()
        return true
    end
    return false
end
--==============================================================
-- ГОЛОВНИЙ ЦИКЛ
--==============================================================
local function loop()
    local active_style_tooltip = ""
    push_style(ctx)

    reaper.ImGui_SetNextWindowSizeConstraints(ctx, 470, 400, 1e10, 1e10)
    reaper.ImGui_SetNextWindowSize(ctx, 800, 600, reaper.ImGui_Cond_FirstUseEver())
    local flags = reaper.ImGui_WindowFlags_MenuBar()
        | reaper.ImGui_WindowFlags_NoCollapse()

    local visible, open = reaper.ImGui_Begin(ctx, "Notepad від imnotbad", true, flags)

    if visible then
        --================ MENU =================
        if reaper.ImGui_BeginMenuBar(ctx) then
            if reaper.ImGui_BeginMenu(ctx, "Notepad") then
                if reaper.ImGui_MenuItem(ctx, "Зберегти Notepad") then save_data() end
                reaper.ImGui_Separator(ctx)

                if reaper.ImGui_MenuItem(ctx, "Відкрити тектстовий документ") then
                    import_text_file()
                end

                local active_tab_index = nil
                for i, tab in ipairs(tabs) do
                    if tab.is_active then
                        active_tab_index = i
                        break
                    end
                end

                if not active_tab_index and #tabs > 0 then
                    active_tab_index = 1
                end

                if reaper.ImGui_MenuItem(ctx, "Зберегти в тектстовому документі") then
                    if active_tab_index then
                        export_active_tab(active_tab_index)
                    end
                end
                reaper.ImGui_Separator(ctx)
                local startup_active = is_startup_enabled()
                if reaper.ImGui_MenuItem(ctx, "Автозапуск при старті REAPER", nil, startup_active) then
                    toggle_reaper_startup(not startup_active)
                    save_data()
                end
                reaper.ImGui_Separator(ctx)
                if reaper.ImGui_MenuItem(ctx, "Закрити Notepad") then
                   open = false
                end
                reaper.ImGui_EndMenu(ctx)
            end
            if reaper.ImGui_BeginMenu(ctx, "Вигляд") then
                reaper.ImGui_SetNextItemWidth(ctx, 150)
                local changed, new_size = reaper.ImGui_SliderInt(ctx, "Розмір", tab_font_size, 12, 42)
                if changed then
                    tab_font_size = new_size
                    rebuild_all_fonts()
                    save_data()
                end

                reaper.ImGui_Separator(ctx)
                reaper.ImGui_TextDisabled(ctx, "Шрифт:")

                for _, name in ipairs(font_list) do
                    local is_selected = (current_font_name == name)
                    if reaper.ImGui_MenuItem(ctx, name, "", is_selected) then
                        current_font_name = name
                        rebuild_tab_font()
                        rebuild_format_fonts()
                        save_data()
                    end
                end

                reaper.ImGui_Separator(ctx)
                reaper.ImGui_TextDisabled(ctx, "Колір інтерфейсу:")

                local c = STYLE_COLORS.GeneralColor
                local col_u32 = reaper.ImGui_ColorConvertDouble4ToU32(c[1], c[2], c[3], c[4])

                local retval, new_col = reaper.ImGui_ColorEdit4(ctx, "##picker", col_u32,
                    reaper.ImGui_ColorEditFlags_NoInputs())

                if retval then
                    local r, g, b, a = reaper.ImGui_ColorConvertU32ToDouble4(new_col)
                    STYLE_COLORS.GeneralColor = { r, g, b, a }
                end

                if reaper.ImGui_MenuItem(ctx, "Скинути колір") then
                    STYLE_COLORS.GeneralColor = { 0.46, 0.46, 0.46, 1.0 }
                    save_data()
                end
                reaper.ImGui_EndMenu(ctx)
            end
            if reaper.ImGui_BeginMenu(ctx, "Pomodoro") then
                reaper.ImGui_SeparatorText(ctx, "Тривалість (хвилини):")
                reaper.ImGui_SetNextItemWidth(ctx, 160)
                local ch1, nv1 = reaper.ImGui_SliderInt(ctx, "Pomodoro##mwork", pomo.edit_work, 1, 60)
                if ch1 then
                    pomo.edit_work     = nv1
                    pomo.work_duration = nv1 * 60
                    if pomo.mode == "work" and pomo.state == "idle" then
                        pomo.remaining = pomo.work_duration
                    end
                    save_data()
                end

                reaper.ImGui_SetNextItemWidth(ctx, 160)
                local ch2, nv2 = reaper.ImGui_SliderInt(ctx, "Коротка перерва##mshort", pomo.edit_short, 1, 30)
                if ch2 then
                    pomo.edit_short  = nv2
                    pomo.short_break = nv2 * 60
                    if pomo.mode == "short_break" and pomo.state == "idle" then
                        pomo.remaining = pomo.short_break
                    end
                    save_data()
                end

                reaper.ImGui_SetNextItemWidth(ctx, 160)
                local ch3, nv3 = reaper.ImGui_SliderInt(ctx, "Довга перерва##mlong", pomo.edit_long, 5, 60)
                if ch3 then
                    pomo.edit_long  = nv3
                    pomo.long_break = nv3 * 60
                    if pomo.mode == "long_break" and pomo.state == "idle" then
                        pomo.remaining = pomo.long_break
                    end
                    save_data()
                end

                reaper.ImGui_SetNextItemWidth(ctx, 160)
                local ch4, nv4 = reaper.ImGui_SliderInt(ctx, "Довга перерва після (pomodoro)##mevery",
                    pomo.long_break_every, 2, 8)
                if ch4 then
                    pomo.long_break_every = nv4
                    save_data()
                end

                reaper.ImGui_Separator(ctx)
                reaper.ImGui_SeparatorText(ctx, "Опції:")
                local ca, av = reaper.ImGui_Checkbox(ctx, "Авто-старт наступного##mauto", pomo.auto_start)
                if ca then
                    pomo.auto_start = av; save_data()
                end

                local cs, sv = reaper.ImGui_Checkbox(ctx, "Звук при завершенні##msound", pomo.sound_enabled)
                if cs then
                    pomo.sound_enabled = sv; save_data()
                end

                reaper.ImGui_Separator(ctx)
                reaper.ImGui_SeparatorText(ctx, "Статистика:")
                reaper.ImGui_TextDisabled(ctx, string.format("Завершено сесій: %d", pomo.completed))
                reaper.ImGui_TextDisabled(ctx,
                    string.format("Загальний час: %d хв", math.floor(pomo.total_work_sec / 60)))

                reaper.ImGui_Separator(ctx)
                if reaper.ImGui_MenuItem(ctx, "Очистити журнал та статистику") then
                    pomo.session_log    = {}
                    pomo.completed      = 0
                    pomo.total_work_sec = 0
                    save_data()
                end

                reaper.ImGui_EndMenu(ctx)
            end
            if reaper.ImGui_BeginMenu(ctx, "Довідка") then
                reaper.ImGui_SeparatorText(ctx, "Загальні:")
                reaper.ImGui_TextDisabled(ctx, "• Для зміни назви блокнота зробіть подвійний клік на Tab")
                reaper.ImGui_TextDisabled(ctx, "• Для збереження назви блокнота натисніть Enter")
                reaper.ImGui_TextDisabled(ctx, "• Для редагування блокнота зробіть подвійний клік всередині Tab")
                reaper.ImGui_TextDisabled(ctx,
                    "• В режимі редагування блокнота зробіть правий клік \n   і натисніть 'Імпортувати макрери'")
                reaper.ImGui_TextDisabled(ctx, "• Для збереження блокнота натисніть Ctrl+S / Cmd+S")
                reaper.ImGui_SeparatorText(ctx, "Markdown:")
                reaper.ImGui_Text(ctx, "Стилі для виділення:")
                reaper.ImGui_Separator(ctx)
                reaper.ImGui_TextDisabled(ctx, "• *Курсив*")
                reaper.ImGui_TextDisabled(ctx, "• **Жирний**")
                reaper.ImGui_TextDisabled(ctx, "• __Підкреслений__")
                reaper.ImGui_TextDisabled(ctx, "• |Комірка|")
                reaper.ImGui_TextDisabled(ctx, "• __***Жирний + Курсив + Підкреслений***__")

                reaper.ImGui_Separator(ctx)
                reaper.ImGui_Text(ctx, "На початку рядка:")
                reaper.ImGui_Separator(ctx)

                reaper.ImGui_TextDisabled(ctx, "• # Заголовок 1")
                reaper.ImGui_TextDisabled(ctx, "• ## Заголовок 2")
                reaper.ImGui_TextDisabled(ctx, "• ### Заголовок 3")
                reaper.ImGui_TextDisabled(ctx, "• [ ] Чекбокс")
                reaper.ImGui_TextDisabled(ctx, "• [x] Чекбокс")
                reaper.ImGui_TextDisabled(ctx, "• [00:00.000] Таймінг")
                reaper.ImGui_TextDisabled(ctx, "• --- Розділова лінія ")
                reaper.ImGui_EndMenu(ctx)
            end

           -- local menu_item_width = 60
           -- local window_width = reaper.ImGui_GetWindowWidth(ctx)
           -- reaper.ImGui_SetCursorPosX(ctx, window_width - menu_item_width - 0)

           -- if reaper.ImGui_MenuItem(ctx, "Закрити") then
           --     open = false
           -- end

            reaper.ImGui_EndMenuBar(ctx)
        end

        --================ POMODORO GLOBAL TICK (незалежно від активної вкладки) =================
        do
            local now_tick = reaper.time_precise()
            local elapsed_tick = pomo.elapsed_before
            if pomo.state == "running" then
                elapsed_tick = elapsed_tick + (now_tick - pomo.start_time)
            end
            local total_dur_tick
            if pomo.mode == "work" then
                total_dur_tick = pomo.work_duration
            elseif pomo.mode == "short_break" then
                total_dur_tick = pomo.short_break
            else
                total_dur_tick = pomo.long_break
            end
            local remaining_tick = math.max(0, total_dur_tick - elapsed_tick)

            if pomo.state == "running" and remaining_tick <= 0 then
                table.insert(pomo.session_log, {
                    mode = pomo.mode,
                    duration_sec = total_dur_tick,
                    completed_at = os.date("%H:%M")
                })
                if pomo.mode == "work" then
                    pomo.completed      = pomo.completed + 1
                    pomo.total_work_sec = pomo.total_work_sec + pomo.work_duration
                end

                if pomo.sound_enabled then play_sound() end

                if pomo.mode == "work" then
                    if pomo.completed % pomo.long_break_every == 0 then
                        pomo.mode = "long_break"
                        pomo.notification_msg = "Час довгої перерви!"
                    else
                        pomo.mode = "short_break"
                        pomo.notification_msg = "Час короткої перерви!"
                    end
                else
                    pomo.mode = "work"
                    pomo.notification_msg = "Час працювати!"
                end
                pomo.notification_time = now_tick
                pomo.elapsed_before    = 0
                pomo.start_time        = now_tick
                if pomo.auto_start then
                    pomo.state = "running"
                else
                    pomo.state = "idle"
                    pomo.remaining = (pomo.mode == "work") and pomo.work_duration
                        or (pomo.mode == "short_break") and pomo.short_break
                        or pomo.long_break
                end
                save_data()
            end
        end

        --================ TAB BAR =================
        if reaper.ImGui_BeginTabBar(ctx, "MyTabBar", reaper.ImGui_TabBarFlags_Reorderable()) then
            if reaper.ImGui_TabItemButton(ctx, "+", reaper.ImGui_TabItemFlags_Trailing()) then
                tabs[#tabs + 1] = {
                    title = "Нотатка " .. (#tabs + 1),
                    content = "",
                    editing = false,
                    renaming = false
                }
                pending_active_tab = #tabs
            end

            local tab_to_remove = nil

            local any_renaming = false
            local renaming_tab_index = nil
            for idx, t in ipairs(tabs) do
                if t.renaming then
                    any_renaming = true
                    renaming_tab_index = idx
                    break
                end
            end

            --================ ФІЛЬТР АБО ПЕРЕЙМЕНУВАННЯ =================
            if not pomodoro_active then
                if any_renaming then
                    reaper.ImGui_SetNextItemWidth(ctx, 220)
                    local rv, new_title = reaper.ImGui_InputText(
                        ctx,
                        "##rename_tab_global",
                        tabs[renaming_tab_index].title,
                        reaper.ImGui_InputTextFlags_EnterReturnsTrue()
                    )

                    if rv then
                        tabs[renaming_tab_index].title = new_title ~= "" and new_title or tabs[renaming_tab_index].title
                        tabs[renaming_tab_index].renaming = false
                        tabs[renaming_tab_index].should_focus = true
                    end

                    if reaper.ImGui_IsItemDeactivated(ctx) then
                        tabs[renaming_tab_index].renaming = false
                        tabs[renaming_tab_index].should_focus = true
                    end

                    reaper.ImGui_SameLine(ctx)
                    reaper.ImGui_TextDisabled(ctx, "Натисніть Enter")
                else
                    reaper.ImGui_SetNextItemWidth(ctx, 160)
                    local changed, new_filter = reaper.ImGui_InputTextWithHint(ctx, "##filter", "Пошук (Ctrl+F/Cmd+F)",
                        filter_text)
                    if changed then
                        filter_text = new_filter
                        filter_active = (filter_text ~= "")
                        filter_match_index = 1
                    end

                    if reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_F())
                        and is_mod_pressed() then
                        reaper.ImGui_SetKeyboardFocusHere(ctx, -1)
                    end

                    reaper.ImGui_SameLine(ctx)

                    if filter_active then
                        local active_tab = tabs[active_tab_index]
                        if active_tab then
                            filter_matches = {}
                            local search_lc = utf8_to_lower(filter_text)
                            local line_idx = 0
                            for line in (active_tab.content .. "\n"):gmatch("([^\n]*)\n") do
                                local line_lc = utf8_to_lower(line)
                                local sp = 1
                                while true do
                                    local ms, me = line_lc:find(search_lc, sp, true)
                                    if not ms then break end
                                    table.insert(filter_matches, { line = line_idx, char_s = ms, char_e = me })
                                    sp = me + 1
                                end
                                line_idx = line_idx + 1
                            end
                            if filter_match_index > #filter_matches then
                                filter_match_index = #filter_matches > 0 and 1 or 0
                            end
                        end

                        if reaper.ImGui_Button(ctx, "X##clear_filter") then
                            filter_text = ""
                            filter_active = false
                            filter_matches = {}
                            filter_match_index = 0
                        end
                        if reaper.ImGui_IsItemHovered(ctx) then
                            active_style_tooltip = "Очистити пошук"
                        end
                        reaper.ImGui_SameLine(ctx)

                        local is_editing_now = tabs[active_tab_index] and tabs[active_tab_index].editing
                        if not is_editing_now then
                            local has_matches = #filter_matches > 0
                            if not has_matches then
                                reaper.ImGui_BeginDisabled(ctx)
                            end
                            if reaper.ImGui_Button(ctx, "<##prev_match") then
                                if has_matches then
                                    filter_match_index = filter_match_index - 1
                                    if filter_match_index < 1 then filter_match_index = #filter_matches end
                                    local m = filter_matches[filter_match_index]
                                    if tabs[active_tab_index] then
                                        tabs[active_tab_index].scroll_to_line = m.line
                                    end
                                end
                            end
                            if reaper.ImGui_IsItemHovered(ctx) then
                                active_style_tooltip = "Попередній збіг"
                            end
                            reaper.ImGui_SameLine(ctx)
                            if reaper.ImGui_Button(ctx, ">##next_match") then
                                if has_matches then
                                    filter_match_index = filter_match_index + 1
                                    if filter_match_index > #filter_matches then filter_match_index = 1 end
                                    local m = filter_matches[filter_match_index]
                                    if tabs[active_tab_index] then
                                        tabs[active_tab_index].scroll_to_line = m.line
                                    end
                                end
                            end
                            if reaper.ImGui_IsItemHovered(ctx) then
                                active_style_tooltip = "Наступний збіг"
                            end
                            if not has_matches then
                                reaper.ImGui_EndDisabled(ctx)
                            end
                            if has_matches then
                                reaper.ImGui_SameLine(ctx)
                                reaper.ImGui_TextDisabled(ctx, filter_match_index .. "/" .. #filter_matches)
                            end
                            reaper.ImGui_SameLine(ctx)
                        end
                    end

                    local active_editing_tab = nil
                    for _, t in ipairs(tabs) do
                        if t.is_active and t.editing then
                            active_editing_tab = t
                            break
                        end
                    end
                    if not active_editing_tab then
                        for _, t in ipairs(tabs) do
                            if t.editing then
                                active_editing_tab = t
                                break
                            end
                        end
                    end

                    if active_editing_tab then
                        local style_buttons = {
                            { label = "-", prefix = "---", tooltip = "Розділова лінія", is_wrap = false },
                            { label = "B", wrapper = "**", tooltip = "Жирний", is_wrap = true },
                            { label = "I", wrapper = "*", tooltip = "Курсив", is_wrap = true },
                            { label = "_", wrapper = "__", tooltip = "Підкреслення", is_wrap = true },
                            { label = "T", wrapper = "|", tooltip = "Таблиця", is_wrap = true },
                            { label = "H1", prefix = "# ", tooltip = "Заголовок 1", is_wrap = false },
                            { label = "H2", prefix = "## ", tooltip = "Заголовок 2", is_wrap = false },
                            { label = "H3", prefix = "### ", tooltip = "Заголовок 3", is_wrap = false },
                            { label = "Ч", prefix = "[ ] ", tooltip = "Чекбокс", is_wrap = false },
                        }

                        local btn_w         = 22
                        local btn_h         = 0
                        local spacing       = 0
                        local total_w       = #style_buttons * btn_w + (#style_buttons - 1) * spacing
                        local win_w         = reaper.ImGui_GetWindowWidth(ctx)
                        reaper.ImGui_SetCursorPosX(ctx, win_w - total_w - 70)

                        for bi, btn in ipairs(style_buttons) do
                            if reaper.ImGui_Button(ctx, btn.label .. "##style_btn_" .. bi, btn_w, btn_h) then
                                local t = active_editing_tab
                                local cur = t.saved_cursor or 0
                                local sel_s = t.saved_sel_start or 0
                                local sel_e = t.saved_sel_end or 0
                                if sel_s > sel_e then sel_s, sel_e = sel_e, sel_s end

                                local current_view_text = filter_active and filter_content(t.content, filter_text) or
                                    t.content
                                local modified_text = ""

                                if btn.is_wrap then
                                    if sel_s ~= sel_e then
                                        local before = current_view_text:sub(1, sel_s)
                                        local selected = current_view_text:sub(sel_s + 1, sel_e)
                                        local after = current_view_text:sub(sel_e + 1)
                                        modified_text = before .. btn.wrapper .. selected .. btn.wrapper .. after
                                    else
                                        local before = current_view_text:sub(1, cur)
                                        local after = current_view_text:sub(cur + 1)
                                        modified_text = before .. btn.wrapper .. btn.wrapper .. after
                                    end
                                else
                                    local search_pos = (sel_s ~= sel_e) and sel_s or cur
                                    local line_start = current_view_text:sub(1, search_pos):match(".*\n()") or 1

                                    if btn.label == "-" then
                                        local line_end = current_view_text:find("\n", search_pos + 1, true)
                                        if line_end then
                                            modified_text = current_view_text:sub(1, line_end) ..
                                                "---\n" .. current_view_text:sub(line_end + 1)
                                        else
                                            local cur_line_text = current_view_text:sub(line_start, search_pos)
                                            modified_text = current_view_text ..
                                                (cur_line_text:match("%S") and "\n---\n" or "---\n")
                                        end
                                    else
                                        modified_text = current_view_text:sub(1, line_start - 1) ..
                                            btn.prefix .. current_view_text:sub(line_start)
                                    end
                                end

                                if filter_active then
                                    t.content = sync_filtered_to_full(t.content, current_view_text, modified_text)
                                else
                                    t.content = modified_text
                                end

                                t.should_focus_edit = true
                            end
                            if reaper.ImGui_IsItemHovered(ctx) then
                                active_style_tooltip = btn.tooltip
                            end
                            reaper.ImGui_SameLine(ctx)
                        end
                    end

                    if filter_active then
                        reaper.ImGui_TextColored(ctx, 0x00FF00FF, " ")
                    else
                        reaper.ImGui_TextDisabled(ctx, " ")
                    end
                end
            end

            reaper.ImGui_Separator(ctx)

            for i, tab in ipairs(tabs) do
                local flags = 0
                if tab.renaming or tab.should_focus then
                    flags = reaper.ImGui_TabItemFlags_SetSelected() | reaper.ImGui_TabItemFlags_NoReorder()
                    tab.should_focus = false
                elseif pending_active_tab == i then
                    flags = reaper.ImGui_TabItemFlags_SetSelected()
                    pending_active_tab = nil
                end

                local is_open, keep_open = reaper.ImGui_BeginTabItem(ctx, tab.title .. "##" .. i, true, flags)

                if reaper.ImGui_IsItemHovered(ctx)
                    and reaper.ImGui_IsMouseDoubleClicked(ctx, 0) then
                    tab.renaming = true
                end

                if is_open then
                    active_tab_index = i
                    pomodoro_active = false
                    local avail_w, avail_h = reaper.ImGui_GetContentRegionAvail(ctx)

                    if tab.reopen_editing then
                        tab.reopen_editing = nil
                        tab.editing = true
                        tab.should_focus_edit = true
                    end

                    local display_content = tab.content

                    --========== EDIT MODE ==========
                    if tab.editing then
                        reaper.ImGui_TextDisabled(ctx, "Редагування:")

                        local save_button_width = 80
                        local save_button_height = 25
                        local window_width = reaper.ImGui_GetWindowWidth(ctx)

                        if active_style_tooltip ~= "" then
                            local tooltip_w = reaper.ImGui_CalcTextSize(ctx, active_style_tooltip)
                            reaper.ImGui_SameLine(ctx, window_width - tooltip_w - save_button_width + 70)
                            reaper.ImGui_TextColored(ctx, 0x62b058FF, active_style_tooltip)
                        end

                        reaper.ImGui_PushFont(ctx, tab_font, tab_font_size)

                        local flags = reaper.ImGui_InputTextFlags_CallbackAlways()

                        if tab.should_focus_edit then
                            reaper.ImGui_SetKeyboardFocusHere(ctx)
                            tab.should_focus_edit = false
                        end

                        if tab.scroll_to_line and tab.cursor_cb_scroll then
                            reaper.ImGui_PushFont(ctx, tab_font, tab_font_size)
                            local lh_edit = reaper.ImGui_GetTextLineHeightWithSpacing(ctx)
                            reaper.ImGui_PopFont(ctx)
                            local target_sy = tab.scroll_to_line * lh_edit - (avail_h - 60) * 0.4
                            if target_sy < 0 then target_sy = 0 end
                            reaper.ImGui_Function_SetValue(tab.cursor_cb_scroll, "g_want_scroll", 1)
                            reaper.ImGui_Function_SetValue(tab.cursor_cb_scroll, "g_scroll_target", target_sy)
                            tab.scroll_to_line = nil
                        end

                        if tab.cursor_cb_scroll then
                            local ok = pcall(function()
                                reaper.ImGui_Function_GetValue(tab.cursor_cb_scroll, "g_want_scroll")
                            end)
                            if not ok then
                                reaper.ImGui_Detach(ctx, tab.cursor_cb_scroll)
                                tab.cursor_cb_scroll = nil
                                tab.cursor_cb = nil
                            end
                        end

                        if not tab.cursor_cb_scroll then
                            tab.cursor_cb_scroll = reaper.ImGui_CreateFunctionFromEEL([[
                                g_cursor    = CursorPos;
                                g_sel_start = SelectionStart;
                                g_sel_end   = SelectionEnd;
                                g_scroll_y  = ScrollY;
                                g_want_scroll ? (ScrollY = g_scroll_target; g_want_scroll = 0;);
                            ]])
                            reaper.ImGui_Attach(ctx, tab.cursor_cb_scroll)
                            tab.cursor_cb = tab.cursor_cb_scroll
                        end

                        local flags = reaper.ImGui_InputTextFlags_CallbackAlways()

                        local edit_h = avail_h - 60
                        local edit_text = filter_active and filter_text ~= "" and
                            filter_content(tab.content, filter_text) or tab.content

                        local rv, new_edit_content = reaper.ImGui_InputTextMultiline(
                            ctx,
                            "##edit" .. i,
                            edit_text,
                            avail_w,
                            edit_h,
                            flags,
                            tab.cursor_cb_scroll
                        )

                        if rv then
                            if filter_active and filter_text ~= "" then
                                tab.content = sync_filtered_to_full(tab.content, edit_text, new_edit_content)
                            else
                                tab.content = new_edit_content
                            end
                        end

                        if tab.cursor_cb_scroll then
                            local cur = math.floor(reaper.ImGui_Function_GetValue(tab.cursor_cb_scroll, "g_cursor"))
                            if cur and cur >= 0 then
                                tab.saved_cursor    = cur
                                tab.saved_sel_start = math.floor(reaper.ImGui_Function_GetValue(tab.cursor_cb_scroll,
                                    "g_sel_start"))
                                tab.saved_sel_end   = math.floor(reaper.ImGui_Function_GetValue(tab.cursor_cb_scroll,
                                    "g_sel_end"))
                            end
                        end

                        if reaper.ImGui_IsItemHovered(ctx) and reaper.ImGui_IsMouseClicked(ctx, 1) then
                            reaper.ImGui_OpenPopup(ctx, "FormatMenu")
                        end

                        reaper.ImGui_PushFont(ctx, tab_font, 14)

                        if reaper.ImGui_BeginPopup(ctx, "FormatMenu") then
                            local sel_s = tab.saved_sel_start or 0
                            local sel_e = tab.saved_sel_end or 0
                            if sel_s > sel_e then sel_s, sel_e = sel_e, sel_s end
                            local has_selection = (sel_s ~= sel_e)

                            if reaper.ImGui_MenuItem(ctx, "Копіювати", "Ctrl+C/Cmd+C", false, has_selection) then
                                if has_selection then
                                    local selected_text = tab.content:sub(sel_s + 1, sel_e)
                                    reaper.ImGui_SetClipboardText(ctx, selected_text)
                                end
                            end

                            if reaper.ImGui_MenuItem(ctx, "Вирізати", "Ctrl+X/Cmd+X", false, has_selection) then
                                if has_selection then
                                    local selected_text = tab.content:sub(sel_s + 1, sel_e)
                                    reaper.ImGui_SetClipboardText(ctx, selected_text)
                                    tab.content         = tab.content:sub(1, sel_s) .. tab.content:sub(sel_e + 1)
                                    tab.saved_sel_start = sel_s
                                    tab.saved_sel_end   = sel_s
                                    tab.saved_cursor    = sel_s
                                    tab.editing         = false
                                    tab.reopen_editing  = true
                                end
                            end

                            if reaper.ImGui_MenuItem(ctx, "Вставити", "Ctrl+V/Cmd+V") then
                                local clipboard = reaper.ImGui_GetClipboardText(ctx)
                                if clipboard and clipboard ~= "" then
                                    local pos = tab.saved_cursor or #tab.content
                                    if has_selection then
                                        tab.content = tab.content:sub(1, sel_s) ..
                                            clipboard .. tab.content:sub(sel_e + 1)
                                    else
                                        tab.content = tab.content:sub(1, pos) ..
                                            clipboard .. tab.content:sub(pos + 1)
                                    end
                                    tab.editing        = false
                                    tab.reopen_editing = true
                                end
                            end

                            if reaper.ImGui_MenuItem(ctx, "Видалити", "Del", false, has_selection) then
                                if has_selection then
                                    tab.content         = tab.content:sub(1, sel_s) .. tab.content:sub(sel_e + 1)
                                    tab.saved_sel_start = sel_s
                                    tab.saved_sel_end   = sel_s
                                    tab.saved_cursor    = sel_s
                                    tab.editing         = false
                                    tab.reopen_editing  = true
                                end
                            end

                            reaper.ImGui_Separator(ctx)

                            if reaper.ImGui_MenuItem(ctx, "Імпортувати маркери") then
                                local markers_text = get_reaper_markers_text()
                                if markers_text then
                                    local formatted_markers = ""
                                    for line in markers_text:gmatch("[^\r\n]+") do
                                        formatted_markers = formatted_markers .. "[ ] " .. line .. "\n"
                                    end
                                    local pos          = tab.saved_cursor or #tab.content
                                    local before       = tab.content:sub(1, pos)
                                    local after        = tab.content:sub(pos + 1)
                                    tab.content        = before .. "\n" .. formatted_markers .. after
                                    tab.editing        = false
                                    tab.reopen_editing = true
                                    tab.reopen_cursor  = pos + 1 + #formatted_markers
                                end
                            end
                            reaper.ImGui_Separator(ctx)
                            reaper.ImGui_TextDisabled(ctx, "Ctrl+S / Cmd+S - зберегти")
                            reaper.ImGui_EndPopup(ctx)
                        end
                        reaper.ImGui_PopFont(ctx)

                        if reaper.ImGui_IsItemActive(ctx) then
                            if reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_A())
                                and is_mod_pressed() then
                                text_sel_start = 0
                                text_sel_end = #tab.content
                            end
                        end

                        reaper.ImGui_PopFont(ctx)

                        reaper.ImGui_PushFont(ctx, font, 16)
                        reaper.ImGui_SetCursorPosX(ctx, window_width - save_button_width / 0.5)
                        if reaper.ImGui_Button(ctx, "Зберегти", 150, 30) then
                            tab.editing = false
                        end
                        if reaper.ImGui_IsItemHovered(ctx) then
                            reaper.ImGui_SetTooltip(ctx, "Ctrl+S / Cmd+S")
                        end
                        if reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_S())
                            and is_mod_pressed() then
                            tab.editing = false
                        end
                        reaper.ImGui_PopFont(ctx)

                        if reaper.ImGui_IsMouseClicked(ctx, 0)
                            and not reaper.ImGui_IsItemHovered(ctx)
                            and not reaper.ImGui_IsAnyItemHovered(ctx)
                            and not reaper.ImGui_IsPopupOpen(ctx, "FormatMenu", 0) then
                            tab.editing = false
                        end
                    else
                        reaper.ImGui_BeginChild(ctx, "view" .. i, avail_w, avail_h)
                        filter_view_match_counter = 0
                        if tab.scroll_to_line then
                            reaper.ImGui_PushFont(ctx, tab_font, tab_font_size)
                            local lh = reaper.ImGui_GetTextLineHeightWithSpacing(ctx)
                            reaper.ImGui_PopFont(ctx)
                            local target_y = tab.scroll_to_line * lh - avail_h * 0.4
                            if target_y < 0 then target_y = 0 end
                            reaper.ImGui_SetScrollY(ctx, target_y)
                            tab.scroll_to_line = nil
                        end

                        if display_content == "" then
                            reaper.ImGui_TextDisabled(ctx, "Подвійний клік для редагування")
                        else
                            local parsed = parse_simple_markdown(display_content)

                            reaper.ImGui_PushTextWrapPos(ctx, 0.0)

                            local win_left_scr_x
                            do
                                local wx, _ = reaper.ImGui_GetWindowPos(ctx)
                                local sx, _ = reaper.ImGui_GetCursorScreenPos(ctx)
                                win_left_scr_x = sx
                            end

                            local paragraph_segments = {}
                            local just_flushed = false
                            local function flush_paragraph(is_checked_ctx)
                                if #paragraph_segments == 0 then return end
                                local scr_x, _ = reaper.ImGui_GetCursorScreenPos(ctx)
                                local tokens = segments_to_word_tokens(paragraph_segments, is_checked_ctx or false)
                                render_line_tokens(ctx, tokens, scr_x, nil, win_left_scr_x)
                                paragraph_segments = {}
                                just_flushed = true
                            end

                            for idx, segment in ipairs(parsed) do
                                local is_text_type = segment.type == "text" or segment.type == "bold"
                                    or segment.type == "italic" or segment.type == "underline"
                                    or segment.type == "multi_style"

                                if is_text_type then
                                    just_flushed = false
                                    local seg_copy = {
                                        text = segment.text or "",
                                        bold = false,
                                        italic = false,
                                        underline = false,
                                        styles = segment.styles
                                    }
                                    if segment.type == "bold" then
                                        seg_copy.bold = true
                                    elseif segment.type == "italic" then
                                        seg_copy.italic = true
                                    elseif segment.type == "underline" then
                                        seg_copy.underline = true
                                    end
                                    table.insert(paragraph_segments, seg_copy)
                                    local next_seg = parsed[idx + 1]
                                    local next_is_text = next_seg and (
                                        next_seg.type == "text" or next_seg.type == "bold"
                                        or next_seg.type == "italic" or next_seg.type == "underline"
                                        or next_seg.type == "multi_style")
                                    if not next_is_text then
                                        flush_paragraph(false)
                                    end
                                elseif segment.type == "newline" then
                                    if #paragraph_segments > 0 then
                                        flush_paragraph(false)
                                    elseif not just_flushed then
                                        reaper.ImGui_NewLine(ctx)
                                    end
                                    just_flushed = false
                                elseif segment.type == "checkbox" then
                                    flush_paragraph(false)
                                    local is_checked = segment.checked

                                    reaper.ImGui_PushFont(ctx, tab_font, tab_font_size)
                                    local line_h_cb = reaper.ImGui_GetTextLineHeight(ctx)
                                    local fp = math.max(1, math.floor((line_h_cb - 100) * 0.45))
                                    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), fp, fp)

                                    if segment.indent and #segment.indent > 0 then
                                        reaper.ImGui_Dummy(ctx, #segment.indent * 10, 0)
                                        reaper.ImGui_SameLine(ctx)
                                    end

                                    local cb_scr_x, cb_scr_y = reaper.ImGui_GetCursorScreenPos(ctx)

                                    local changed, new_state = reaper.ImGui_Checkbox(ctx, "##cb_" .. i .. "_" .. idx,
                                        is_checked)

                                    if changed then
                                        local old_line = segment.line
                                        local new_line = segment.indent ..
                                            "[" .. (new_state and "x" or " ") .. "] " .. segment.text
                                        tab.content = tab.content:gsub(
                                            old_line:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1"), new_line, 1)
                                    end

                                    local text_y = cb_scr_y + fp - 2

                                    reaper.ImGui_SameLine(ctx)
                                    local text_start_x, _ = reaper.ImGui_GetCursorScreenPos(ctx)

                                    local checkbox_parsed = parse_simple_markdown(segment.text)
                                    local cb_segs = {}
                                    for _, cb_seg in ipairs(checkbox_parsed) do
                                        if cb_seg.type ~= "newline" then
                                            local s = {
                                                text = cb_seg.text or "",
                                                bold = (cb_seg.type == "bold"),
                                                italic = (cb_seg.type == "italic"),
                                                underline = (cb_seg.type == "underline"),
                                                styles = cb_seg.styles
                                            }
                                            table.insert(cb_segs, s)
                                        end
                                    end

                                    local cb_tokens = segments_to_word_tokens(cb_segs, is_checked)
                                    render_line_tokens(ctx, cb_tokens, text_start_x, nil, win_left_scr_x, text_y)

                                    reaper.ImGui_PopStyleVar(ctx)
                                    reaper.ImGui_PopFont(ctx)
                                    just_flushed = true
                                elseif segment.type == "table_row" then
                                    local cell_padding = 6
                                    local win_width = reaper.ImGui_GetContentRegionAvail(ctx)
                                    local num_cells = #segment.cells
                                    local cell_width = win_width / num_cells

                                    local start_x, start_y = reaper.ImGui_GetCursorScreenPos(ctx)
                                    local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
                                    local line_h = reaper.ImGui_GetTextLineHeight(ctx) + (cell_padding * 3)

                                    if segment.is_header then
                                        reaper.ImGui_DrawList_AddRectFilled(draw_list, start_x, start_y,
                                            start_x + win_width, start_y + line_h, GetGeneralColorHEX())
                                    end

                                    for c_idx, styled_segments in ipairs(segment.cells) do
                                        local cur_x = start_x + (c_idx - 1) * cell_width
                                        reaper.ImGui_DrawList_AddRect(draw_list, cur_x, start_y, cur_x + cell_width,
                                            start_y + line_h, GetGeneralColorHEX())

                                        reaper.ImGui_SetCursorScreenPos(ctx, cur_x + cell_padding, start_y + cell_padding)

                                        for _, s in ipairs(styled_segments) do
                                            local font = tab_font
                                            if segment.is_header or s.bold then
                                                font = get_font(current_font_name, "Bold") or tab_font
                                            elseif s.italic then
                                                font = get_font(current_font_name, "Italic") or tab_font
                                            end

                                            reaper.ImGui_PushFont(ctx, tab_font, 16)
                                            if filter_active and filter_text ~= "" and s.text ~= "" then
                                                local cell_lc   = utf8_to_lower(s.text)
                                                local search_lc = utf8_to_lower(filter_text)
                                                local cx, cy    = reaper.ImGui_GetCursorScreenPos(ctx)
                                                local cell_lh   = reaper.ImGui_GetTextLineHeight(ctx)
                                                local sp        = 1
                                                while true do
                                                    local ms, me = cell_lc:find(search_lc, sp, true)
                                                    if not ms then break end
                                                    filter_view_match_counter = filter_view_match_counter + 1
                                                    local x_before            = reaper.ImGui_CalcTextSize(ctx,
                                                        s.text:sub(1, ms - 1))
                                                    local x_matched           = reaper.ImGui_CalcTextSize(ctx,
                                                        s.text:sub(ms, me))
                                                    local col                 = (filter_view_match_counter == filter_match_index) and
                                                        0x93f67b60 or 0xf6de7b77
                                                    reaper.ImGui_DrawList_AddRectFilled(draw_list,
                                                        cx + x_before, cy,
                                                        cx + x_before + x_matched, cy + cell_lh, col)
                                                    sp = me + 1
                                                end
                                            end
                                            reaper.ImGui_Text(ctx, s.text)
                                            reaper.ImGui_PopFont(ctx)

                                            if s.underline then
                                                local tx, ty = reaper.ImGui_GetItemRectMin(ctx)
                                                local bx, by = reaper.ImGui_GetItemRectMax(ctx)
                                                reaper.ImGui_DrawList_AddLine(draw_list, tx, by, bx, by, 0xFFFFFFFF)
                                            end

                                            reaper.ImGui_SameLine(ctx, nil, 0)
                                        end
                                    end
                                    reaper.ImGui_SetCursorScreenPos(ctx, win_left_scr_x, start_y + line_h)
                                    reaper.ImGui_Dummy(ctx, 0, 0)
                                    just_flushed = true
                                elseif segment.type == "separator" then
                                    flush_paragraph(false)
                                    reaper.ImGui_Dummy(ctx, 0, 5)
                                    reaper.ImGui_Separator(ctx)
                                    reaper.ImGui_Dummy(ctx, 0, 5)
                                    just_flushed = true
                                elseif segment.type == "header" then
                                    flush_paragraph(false)
                                    local header_sizes = {
                                        [1] = tab_font_size + 14,
                                        [2] = tab_font_size + 10,
                                        [3] = tab_font_size + 6,
                                        [4] = tab_font_size + 4,
                                        [5] = tab_font_size + 2,
                                        [6] = tab_font_size + 1
                                    }
                                    local size = header_sizes[segment.level] or tab_font_size
                                    local main_col = GetGeneralColorHEX()
                                    reaper.ImGui_PushFont(ctx, bold_font, size)
                                    reaper.ImGui_TextColored(ctx, main_col, segment.text)
                                    reaper.ImGui_PopFont(ctx)
                                    if filter_active and filter_text ~= "" then
                                        local hdr_lc    = utf8_to_lower(segment.text)
                                        local search_lc = utf8_to_lower(filter_text)
                                        local hx, hy    = reaper.ImGui_GetItemRectMin(ctx)
                                        local _, hy2    = reaper.ImGui_GetItemRectMax(ctx)
                                        local dl_h      = reaper.ImGui_GetWindowDrawList(ctx)
                                        reaper.ImGui_PushFont(ctx, bold_font, size)
                                        local sp = 1
                                        while true do
                                            local ms, me = hdr_lc:find(search_lc, sp, true)
                                            if not ms then break end
                                            filter_view_match_counter = filter_view_match_counter + 1
                                            local x_before            = reaper.ImGui_CalcTextSize(ctx,
                                                segment.text:sub(1, ms - 1))
                                            local x_matched           = reaper.ImGui_CalcTextSize(ctx,
                                                segment.text:sub(ms, me))
                                            local col                 = (filter_view_match_counter == filter_match_index) and
                                                0x93f67b60 or 0xf6de7b77
                                            reaper.ImGui_DrawList_AddRectFilled(dl_h,
                                                hx + x_before, hy,
                                                hx + x_before + x_matched, hy2,
                                                col)
                                            sp = me + 1
                                        end
                                        reaper.ImGui_PopFont(ctx)
                                    end
                                    just_flushed = true
                                end
                            end
                            flush_paragraph(false)
                            reaper.ImGui_PopTextWrapPos(ctx)
                            reaper.ImGui_Dummy(ctx, 0, 0)
                        end

                        if reaper.ImGui_IsWindowHovered(ctx)
                            and reaper.ImGui_IsMouseDoubleClicked(ctx, 0) then
                            tab.editing = true
                        end
                        reaper.ImGui_EndChild(ctx)
                    end

                    reaper.ImGui_EndTabItem(ctx)
                end

                if not keep_open then tab_to_remove = i end
            end

            if tab_to_remove then table.remove(tabs, tab_to_remove) end

            --================ POMODORO TAB =================

            do
                local pomo_flags = reaper.ImGui_TabItemFlags_Trailing()
                    | reaper.ImGui_TabItemFlags_NoReorder()
                if pomodoro_pending_select then
                    pomo_flags = pomo_flags | reaper.ImGui_TabItemFlags_SetSelected()
                    pomodoro_pending_select = false
                end

                local pomo_open = reaper.ImGui_BeginTabItem(ctx, "Pomodoro##pomodoro_fixed", nil, pomo_flags)
                if pomo_open then
                    pomodoro_active = true
                    local avail_w, avail_h = reaper.ImGui_GetContentRegionAvail(ctx)
                    local now = reaper.time_precise()
                    local elapsed = pomo.elapsed_before
                    if pomo.state == "running" then
                        elapsed = elapsed + (now - pomo.start_time)
                    end
                    local total_dur
                    if pomo.mode == "work" then
                        total_dur = pomo.work_duration
                    elseif pomo.mode == "short_break" then
                        total_dur = pomo.short_break
                    else
                        total_dur = pomo.long_break
                    end
                    pomo.remaining = math.max(0, total_dur - elapsed)
                    local mode_color
                    if pomo.mode == "work" then
                        mode_color = 0xFF5555FF
                    elseif pomo.mode == "short_break" then
                        mode_color = 0x55CC55FF
                    else
                        mode_color = 0x5599FFFF
                    end
                    local mode_color_dim = (mode_color & 0xFFFFFF00) | 0x55
                    reaper.ImGui_BeginChild(ctx, "##pomodoro_child", avail_w, avail_h)

                    local top_pad = 18
                    reaper.ImGui_Dummy(ctx, 0, top_pad)

                    local mode_labels = {
                        work        = "POMODORO",
                        short_break = "КОРОТКА ПЕРЕРВА",
                        long_break  = "ДОВГА ПЕРЕРВА"
                    }
                    local mode_lbl = mode_labels[pomo.mode]
                    reaper.ImGui_PushFont(ctx, tab_font, 40)
                    local tw = reaper.ImGui_CalcTextSize(ctx, mode_lbl)
                    reaper.ImGui_SetCursorPosX(ctx, (avail_w - tw) * 0.5)
                    reaper.ImGui_TextColored(ctx, mode_color, mode_lbl)
                    reaper.ImGui_PopFont(ctx)

                    reaper.ImGui_Dummy(ctx, 0, 8)

                    local cx_pos = avail_w * 0.5
                    local timer_radius = math.min(avail_w, avail_h) * 0.22

                    local scroll_y = reaper.ImGui_GetScrollY(ctx)

                    local cy_pos = reaper.ImGui_GetCursorPosY(ctx) + timer_radius + 10
                    reaper.ImGui_SetCursorPosY(ctx, cy_pos + timer_radius + 14)

                    local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
                    local win_x, win_y = reaper.ImGui_GetWindowPos(ctx)

                    local scr_cx = win_x + cx_pos
                    local scr_cy = win_y + cy_pos - scroll_y

                    reaper.ImGui_DrawList_AddCircleFilled(draw_list, scr_cx, scr_cy, timer_radius, 0x22222270, 80)
                    reaper.ImGui_DrawList_AddCircle(draw_list, scr_cx, scr_cy, timer_radius, 0x33333370, 80, 4)

                    local progress    = (total_dur > 0) and (1.0 - pomo.remaining / total_dur) or 0
                    local seg         = 80
                    local start_angle = -math.pi * 0.5
                    local end_angle   = start_angle + progress * math.pi * 2
                    if progress > 0 then
                        for s = 0, seg - 1 do
                            local a1 = start_angle + (end_angle - start_angle) * (s / seg)
                            local a2 = start_angle + (end_angle - start_angle) * ((s + 1) / seg)
                            local r  = timer_radius - 5
                            reaper.ImGui_DrawList_AddLine(draw_list,
                                scr_cx + math.cos(a1) * r, scr_cy + math.sin(a1) * r,
                                scr_cx + math.cos(a2) * r, scr_cy + math.sin(a2) * r,
                                mode_color, 6)
                        end
                    end

                    local mins = math.floor(pomo.remaining / 60)
                    local secs = math.floor(pomo.remaining % 60)
                    local time_str = string.format("%02d:%02d", mins, secs)
                    reaper.ImGui_PushFont(ctx, tab_font, timer_radius * 0.62)
                    local tsw, tsh = reaper.ImGui_CalcTextSize(ctx, time_str)
                    reaper.ImGui_SetCursorPos(ctx, cx_pos - tsw * 0.5, cy_pos - timer_radius * 0.35)
                    reaper.ImGui_TextColored(ctx, 0xFFFFFFFF, time_str)
                    reaper.ImGui_PopFont(ctx)

                    local state_lbl = (pomo.state == "running") and "Виконується"
                        or (pomo.state == "paused") and "Пауза"
                        or "Зупинено"
                    reaper.ImGui_PushFont(ctx, tab_font, tab_font_size - 3)
                    local slw, slh = reaper.ImGui_CalcTextSize(ctx, state_lbl)
                    reaper.ImGui_SetCursorPos(ctx, cx_pos - slw * 0.5, cy_pos + timer_radius * 0.50)
                    reaper.ImGui_TextColored(ctx, 0xAAAAAA88, state_lbl)
                    reaper.ImGui_PopFont(ctx)

                    reaper.ImGui_SetCursorPosY(ctx, cy_pos + timer_radius + 22)

                    local btn_w        = 90
                    local btn_h        = 32
                    local gap          = 10
                    local total_btns_w = btn_w * 3 + gap * 2
                    reaper.ImGui_SetCursorPosX(ctx, (avail_w - total_btns_w) * 0.5)
                    if pomo.state == "running" then
                        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x885500FF)
                        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0xBB7700FF)
                        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), 0xFF9900FF)
                        if reaper.ImGui_Button(ctx, "Пауза", btn_w, btn_h) then
                            pomo.elapsed_before = pomo.elapsed_before + (now - pomo.start_time)
                            pomo.state = "paused"
                        end
                        reaper.ImGui_PopStyleColor(ctx, 3)
                    else
                        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x226622FF)
                        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0x339933FF)
                        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), 0x44BB44FF)
                        local start_lbl = (pomo.state == "paused") and "Продовжити" or "Старт"
                        if reaper.ImGui_Button(ctx, start_lbl, btn_w, btn_h) then
                            pomo.start_time = now
                            pomo.state = "running"
                        end
                        reaper.ImGui_PopStyleColor(ctx, 3)
                    end

                    reaper.ImGui_SameLine(ctx, nil, gap)
                    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x333333FF)
                    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0x555555FF)
                    if reaper.ImGui_Button(ctx, "Стоп", btn_w, btn_h) then
                        pomo.state          = "idle"
                        pomo.elapsed_before = 0
                        pomo.remaining      = (pomo.mode == "work") and pomo.work_duration
                            or (pomo.mode == "short_break") and pomo.short_break
                            or pomo.long_break
                    end
                    reaper.ImGui_PopStyleColor(ctx, 2)

                    reaper.ImGui_SameLine(ctx, nil, gap)

                    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x333333FF)
                    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0x555555FF)
                    if reaper.ImGui_Button(ctx, "Далі", btn_w, btn_h) then
                        pomo.state          = "idle"
                        pomo.elapsed_before = 0
                        if pomo.mode == "work" then
                            pomo.completed = pomo.completed + 1
                            if pomo.completed % pomo.long_break_every == 0 then
                                pomo.mode = "long_break"
                            else
                                pomo.mode = "short_break"
                            end
                        else
                            pomo.mode = "work"
                        end
                        pomo.remaining = (pomo.mode == "work") and pomo.work_duration
                            or (pomo.mode == "short_break") and pomo.short_break
                            or pomo.long_break
                    end
                    reaper.ImGui_PopStyleColor(ctx, 2)

                    reaper.ImGui_Dummy(ctx, 0, 14)

                    local modes = { { id = "work", lbl = "Pomodoro" }, { id = "short_break", lbl = "Коротка" }, { id = "long_break", lbl = "Довга" } }
                    local mode_btn_w = 100
                    local total_mode_w = mode_btn_w * 3 + gap * 2
                    reaper.ImGui_SetCursorPosX(ctx, (avail_w - total_mode_w) * 0.5)
                    for mi, mdata in ipairs(modes) do
                        local is_active = (pomo.mode == mdata.id)
                        if is_active then
                            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), mode_color)
                            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), mode_color)
                        else
                            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x2A2A2AFF)
                            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0x444444FF)
                        end
                        if reaper.ImGui_Button(ctx, mdata.lbl .. "##mode" .. mi, mode_btn_w, 26) then
                            if pomo.mode ~= mdata.id then
                                pomo.mode           = mdata.id
                                pomo.state          = "idle"
                                pomo.elapsed_before = 0
                                pomo.remaining      = (pomo.mode == "work") and pomo.work_duration
                                    or (pomo.mode == "short_break") and pomo.short_break
                                    or pomo.long_break
                            end
                        end
                        reaper.ImGui_PopStyleColor(ctx, 2)
                        if mi < 3 then reaper.ImGui_SameLine(ctx, nil, gap) end
                    end

                    reaper.ImGui_Dummy(ctx, 0, 10)
                    reaper.ImGui_SetCursorPosX(ctx, 16)
                    reaper.ImGui_Separator(ctx)
                    reaper.ImGui_Dummy(ctx, 0, 6)

                    reaper.ImGui_PushFont(ctx, tab_font, tab_font_size)
                    local total_work_min = math.floor(pomo.total_work_sec / 60)
                    local stat_str = string.format("Завершено: %d   |   Загалом: %d хв", pomo.completed, total_work_min)
                    local stw = reaper.ImGui_CalcTextSize(ctx, stat_str)
                    reaper.ImGui_SetCursorPosX(ctx, (avail_w - stw) * 0.5)
                    reaper.ImGui_TextColored(ctx, 0x888888FF, stat_str)
                    reaper.ImGui_PopFont(ctx)

                    reaper.ImGui_Dummy(ctx, 0, 6)

                    if #pomo.session_log > 0 then
                        reaper.ImGui_Dummy(ctx, 0, 8)
                        reaper.ImGui_PushFont(ctx, tab_font, tab_font_size)

                        local btn_label = (pomo.show_log and "▼" or "▷") .. " Журнал сесії (" .. #pomo.session_log .. ")"
                        local text_w, text_h = reaper.ImGui_CalcTextSize(ctx, btn_label)
                        local win_w = reaper.ImGui_GetWindowWidth(ctx)
                        local center_pos = (win_w - text_w) * 0.5

                        reaper.ImGui_SetCursorPosX(ctx, center_pos)

                        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x17171700)
                        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), 0x171717FF)
                        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0x33333333)
                        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0x666666FF)


                        if reaper.ImGui_Button(ctx, btn_label) then
                            pomo.show_log = not pomo.show_log
                        end

                        reaper.ImGui_PopStyleColor(ctx, 4)
                        reaper.ImGui_PopFont(ctx)
                        if pomo.show_log then
                            reaper.ImGui_Dummy(ctx, 0, 4)
                            local log_h = math.max(40, math.min(120, #pomo.session_log * 40 + 10))

                            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ChildBg(), 0x171717FF)
                            if reaper.ImGui_BeginChild(ctx, "##pomo_log", avail_w - 15, log_h, 1) then
                                for li = #pomo.session_log, 1, -1 do
                                    local entry = pomo.session_log[li]
                                    local dur_min = math.floor(entry.duration_sec / 60)
                                    local lline = string.format("  %s — %d хв о %s",
                                        entry.mode == "work" and "Pomodoro"
                                        or entry.mode == "short_break" and "Коротка перерва"
                                        or "Довга перерва",
                                        dur_min, entry.completed_at)

                                    reaper.ImGui_PushFont(ctx, tab_font, tab_font_size - 3)
                                    reaper.ImGui_TextColored(ctx, 0x888888FF, lline)
                                    reaper.ImGui_PopFont(ctx)
                                end
                                reaper.ImGui_EndChild(ctx)
                            end
                            reaper.ImGui_PopStyleColor(ctx, 1)
                            reaper.ImGui_Dummy(ctx, 0, 20)
                        end
                    end
                    reaper.ImGui_Dummy(ctx, 0, 10)

                    reaper.ImGui_EndChild(ctx)
                    reaper.ImGui_EndTabItem(ctx)
                end
            end

            reaper.ImGui_EndTabBar(ctx)
        end

        --================ ГЛОБАЛЬНЕ СПОВІЩЕННЯ POMODORO =================
        if pomo.notification_msg then
            local now_n = reaper.time_precise()
            local age   = now_n - pomo.notification_time

            if age < 4.0 then
                local alpha = math.max(0.0, 1.0 - age / 4.0)

                local notif_col
                if pomo.mode == "work" then
                    notif_col = 0xFF55FF
                elseif pomo.mode == "short_break" then
                    notif_col = 0x55CCFF
                else
                    notif_col = 0x5599FF
                end

                local nr           = (notif_col >> 16) & 0xFF
                local ng           = (notif_col >> 8) & 0xFF
                local nb           = notif_col & 0xFF
                local na           = math.floor(alpha * 255)

                local text_col32   = (nr << 24) | (ng << 16) | (nb << 8) | na

                local msg          = pomo.notification_msg
                local win_x, win_y = reaper.ImGui_GetWindowPos(ctx)
                local win_w        = reaper.ImGui_GetWindowWidth(ctx)

                reaper.ImGui_PushFont(ctx, tab_font, tab_font_size + 1)
                local tw, th = reaper.ImGui_CalcTextSize(ctx, msg)
                reaper.ImGui_PopFont(ctx)

                local pad    = 14
                local nw     = tw + pad * 2
                local nh     = th + 10
                local nx     = win_x + (win_w - nw) * 0.5
                local ny     = win_y + 350
                local bg_a   = 255
                local bg_col = (0x11 << 24) | (0x11 << 16) | (0x11 << 8) | bg_a
                local dl     = reaper.ImGui_GetForegroundDrawList(ctx)
                reaper.ImGui_DrawList_AddRectFilled(dl, nx, ny, nx + nw, ny + nh, bg_col, 6)
                local border_col = (nr << 24) | (ng << 16) | (nb << 8) | math.floor(alpha * 160)
                reaper.ImGui_DrawList_AddRect(dl, nx, ny, nx + nw, ny + nh, border_col, 6, nil, 1)
                reaper.ImGui_PushFont(ctx, tab_font, tab_font_size + 1)
                reaper.ImGui_DrawList_AddText(dl, nx + pad, ny + 5, text_col32, msg)
                reaper.ImGui_PopFont(ctx)
            else
                pomo.notification_msg = nil
            end
        end

        reaper.ImGui_End(ctx)
    end
    pop_style(ctx)
    if reaper.time_precise() - last_save_time > 5 then
        save_data()
        last_save_time = reaper.time_precise()
    end

    if open then reaper.defer(loop) else save_data() end
end

reaper.defer(loop)

