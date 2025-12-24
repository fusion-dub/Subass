-- @description Subass Notes (SRT Manager - Native GFX)
-- @version 2.1
-- @author Fusion (Fusion Dub)
-- @about Zero-dependency subtitle manager using native Reaper GFX.

local script_title = "Subass Notes v2.1"
local section_name = "Subass_Notes"

local last_dock_state = reaper.GetExtState(section_name, "dock")
if last_dock_state == "" then last_dock_state = 0 else last_dock_state = tonumber(last_dock_state) end

-- Persisted Settings
local function get_set(key, default)
    local val = reaper.GetExtState(section_name, key)
    if val == "" then return default end
    return tonumber(val) or val
end

local cfg = {
    p_fsize = get_set("p_fsize", 40),
    p_cr = get_set("p_cr", 0.05),
    p_cg = get_set("p_cg", 0.05),
    p_cb = get_set("p_cb", 0.05),
    p_next = (get_set("p_next", "1") == "1" or get_set("p_next", 1) == 1),
    
    n_fsize = get_set("n_fsize", 22),
    n_cr = get_set("n_cr", 0.17),
    n_cg = get_set("n_cg", 0.17),
    n_cb = get_set("n_cb", 0.17),
    
    wrap_length = get_set("wrap_length", 42),
    always_next = (get_set("always_next", "1") == "1" or get_set("always_next", 1) == 1),
    random_color_actors = (get_set("random_color_actors", "1") == "1" or get_set("random_color_actors", 1) == 1),
    text_assimilations = (get_set("text_assimilations", "1") == "1" or get_set("text_assimilations", 1) == 1),
    karaoke_mode = (get_set("karaoke_mode", "0") == "1" or get_set("karaoke_mode", 0) == 1),
    all_caps = (get_set("all_caps", "0") == "1" or get_set("all_caps", 0) == 1),
    wave_bg = (get_set("wave_bg", "1") == "1" or get_set("wave_bg", 1) == 1),
    wave_bg_progress = (get_set("wave_bg_progress", "0") == "1" or get_set("wave_bg_progress", 0) == 1),
    count_timer = (get_set("count_timer", "1") == "1" or get_set("count_timer", 1) == 1),
    cps_warning = (get_set("cps_warning", "1") == "1" or get_set("cps_warning", 1) == 1),
    bg_cr = get_set("bg_cr", 0.67),
    bg_cg = get_set("bg_cg", 0.69),
    bg_cb = get_set("bg_cb", 0.69),
    p_align = get_set("p_align", "center"),
    p_font = get_set("p_font", "Arial"),
    p_info = (get_set("p_info", "1") == "1" or get_set("p_info", 1) == 1),
    auto_srt_split = get_set("auto_srt_split", "():"),
    prmt_theme = get_set("prmt_theme", "Бетон"),
    gemini_api_key = get_set("gemini_api_key", ""),
    auto_startup = (get_set("auto_startup", "0") == "1" or get_set("auto_startup", 0) == 1)
}

local gemini_key_status = tonumber(reaper.GetExtState(section_name, "gemini_key_status")) or 0

-- OS Detection for hybrid stress mark rendering
local os_name = reaper.GetOS()
local is_windows = os_name:match("Win") ~= nil

gfx.init(script_title, 600, 400, last_dock_state)
local F = {
    std = 1,
    lrg = 2,
    nxt = 3,
    bld = 4,

    -- Dedicated Dictionary Font Slots
    dict_std = 5,
    dict_bld = 6,
    dict_std_sm = 7, -- 16px
    dict_bld_sm = 8, -- 16px
    tip = 9 -- 12px
}

gfx.setfont(F.std, "Arial", 14)
gfx.setfont(F.lrg, cfg.p_font, cfg.p_fsize)
gfx.setfont(F.nxt, cfg.p_font, cfg.n_fsize)
gfx.setfont(F.bld, "Arial", 18, string.byte('b'))

-- Initialize dictionary slots
gfx.setfont(F.dict_std, "Arial", 17)
gfx.setfont(F.dict_bld, "Arial", 18, string.byte('b'))
gfx.setfont(F.dict_std_sm, "Arial", 16)
gfx.setfont(F.dict_bld_sm, "Arial", 16, string.byte('b'))
gfx.setfont(F.tip, "Arial", 12)

-- State
local current_tab = 3 -- Default to Prompter
local tabs = {"Файл", "Таблиця", "Суфлер", "Налаштування"}
local last_mouse_cap = 0
local mouse_handled = false -- Global flag to suppress context menu if handled by UI
local scroll_y = 0
local target_scroll_y = 0 -- For smooth scrolling
local last_project_id = tostring(reaper.EnumProjects(-1)) -- Track current project
local script_loading_state = { active = false, text = "" } -- Global Loading Indicator State

-- Tooltip State
local tooltip_state = {
    hover_id = nil,
    text = "",
    start_time = 0,
    x = 0,
    y = 0
}
-- Per-tab scroll positions
local tab_scroll_y = {0, 0, 0, 0}
local tab_target_scroll_y = {0, 0, 0, 0}
local last_tracked_pos = 0 -- For auto-scroll detection
local skip_auto_scroll = false -- Skip auto-scroll after manual row click
local last_click_time = 0 -- For double-click detection
local last_click_row = 0 -- Which row was clicked
local regions = {}
local proj_change_count = reaper.GetProjectStateChangeCount(0)

-- Text Editor Modal State
local text_editor_text = ""
local text_editor_cursor = 0
local text_editor_sel_anchor = 0 -- Anchor for text selection
local text_editor_line_idx = nil
local text_editor_callback = nil
local text_editor_history = {}
local text_editor_history_pos = 0
local text_editor_scroll = 0
local text_editor_active = false
local text_editor_context_line_idx = nil -- Index of current line being edited
local text_editor_context_all_lines = nil -- All lines for context

-- Table Filter State
local table_filter_state = {
    text = "",
    cursor = 0,
    anchor = 0,
    focus = false,
    last_click_time = 0,
    last_click_state = 0
}

-- Table Sort State
local table_sort = { col = "Початок", dir = 1 }

local table_selection = {} -- { [row_index] = true }
local last_selected_row = nil -- for Shift range selection

-- Snackbar State
local snackbar_text = ""
local snackbar_show_time = 0
local snackbar_duration = 2.0 -- seconds

-- Constants
local acute = "\204\129" -- UTF-8 Combining Acute Accent (0xCC 0x81)
local stress_marks_black_list = {
    "звук", "звуки", "мене", "уважно", "яке", "можеш", "мені", "саме", "якщо", "такі", "але",
    "знаю", "коли", "має", "немає", "масовка", "неї", "вона", "буду", "пане", "пані", "усі", "або",
    "яка", "мого", "того", "твого", "свого", "себе", "одного", "одному", "тому", "цього", "цьому",
    "тебе", "він", "воно", "вони", "зараз", "дуже", "додому", "мова", "книга", "місто", "село", "мрія",
    "любов", "добрий", "поганий", "великий", "малий", "мало", "багато", "нехай", "мама", "тато", "думаю",
    "їсти", "її", "моєму", "твоєму", "своєму", "завжди", "також", "помилка", "назавжди", "весняний", "замок",
    "брати", "крила", "один", "два", "три", "чотири", "пять", "пʼять", "шість", "сім", "вісім", "девять",
    "девʼять", "десять",
}

-- Seed Random
math.randomseed(os.time())
-- Dictionary Modal State
local dict_modal = {
    show = false,
    word = "",
    content = {}, -- Keyed by category name
    selected_tab = "Словозміна",
    scroll_y = 0,
    target_scroll_y = 0,
    max_scroll = 0,
    history = {} -- History stack for back navigation
}

-- AI Assistant State
local ai_modal = {
    show = false,
    text = "",
    current_step = "SELECT_TASK", -- "SELECT_TASK", "LOADING", "RESULTS", "ERROR"
    suggestions = {},
    sel_min = 0,
    sel_max = 0,
    error_msg = "",
    scroll = 0,
    anchor_x = 0,
    anchor_y = 0,
    was_shown = false,
    last_task = "",
    last_click_time = 0,
    history = {} -- AI operations history (cleared when editor closes)
}

-- Word Lookup Trigger State
local word_trigger = {
    active = false,
    start_time = 0,
    word = "",
    bounds = {x=0, y=0, w=0, h=0},
    triggered = false
}

math.random(); math.random(); math.random() -- Warm up

-- Find and Replace State
local find_replace_state = {
    show = false,
    find = {text = "", cursor = 0, anchor = 0, focus = true},
    replace = {text = "", cursor = 0, anchor = 0, focus = false},
    case_sensitive = false,
    bounds = {x=0, y=0, w=0, h=0}
}

-- Session Management (Isolate UI state per project tab)
local session_states = {}

-- Helper to deep copy table for session isolation
local function deep_copy(obj)
    if type(obj) ~= 'table' then return obj end
    local res = {}
    for k, v in pairs(obj) do res[deep_copy(k)] = deep_copy(v) end
    return res
end

--- Save current UI state for the specific project tab
local function save_session_state(id)
    if not id then return end
    -- Sync current tab's scroll before saving
    tab_scroll_y[current_tab] = scroll_y
    tab_target_scroll_y[current_tab] = target_scroll_y

    session_states[id] = {
        current_tab = current_tab,
        tab_scroll_y = {table.unpack(tab_scroll_y)},
        tab_target_scroll_y = {table.unpack(tab_target_scroll_y)},
        -- Editor state
        text_editor_active = text_editor_active,
        text_editor_text = text_editor_text,
        text_editor_cursor = text_editor_cursor,
        text_editor_sel_anchor = text_editor_sel_anchor,
        text_editor_line_idx = text_editor_line_idx,
        text_editor_callback = text_editor_callback,
        text_editor_history = deep_copy(text_editor_history),
        text_editor_history_pos = text_editor_history_pos,
        text_editor_scroll = text_editor_scroll,
        text_editor_context_line_idx = text_editor_context_line_idx,
        text_editor_context_all_lines = text_editor_context_all_lines,
        -- Modal states (minimal)
        ai_modal_show = ai_modal.show,
        ai_modal_step = ai_modal.current_step,
        dict_modal_show = dict_modal.show,
        -- Table state
        table_filter_state = deep_copy(table_filter_state),
        find_replace_state = deep_copy(find_replace_state),
        table_selection = deep_copy(table_selection),
        table_sort = deep_copy(table_sort),
        last_selected_row = last_selected_row
    }
end

--- Load UI state for the specific project tab
local function load_session_state(id)
    local state = session_states[id]
    if state then
        current_tab = state.current_tab or 3
        tab_scroll_y = {table.unpack(state.tab_scroll_y or {0,0,0,0})}
        tab_target_scroll_y = {table.unpack(state.tab_target_scroll_y or {0,0,0,0})}
        -- Sync global scroll from restored active tab state
        scroll_y = tab_scroll_y[current_tab] or 0
        target_scroll_y = tab_target_scroll_y[current_tab] or 0
        -- Editor
        text_editor_active = state.text_editor_active or false
        text_editor_text = state.text_editor_text or ""
        text_editor_cursor = state.text_editor_cursor or 0
        text_editor_sel_anchor = state.text_editor_sel_anchor or 0
        text_editor_line_idx = state.text_editor_line_idx
        text_editor_callback = state.text_editor_callback
        text_editor_history = deep_copy(state.text_editor_history or {})
        text_editor_history_pos = state.text_editor_history_pos or 0
        text_editor_scroll = state.text_editor_scroll or 0
        text_editor_context_line_idx = state.text_editor_context_line_idx
        text_editor_context_all_lines = state.text_editor_context_all_lines
        -- Modals
        if ai_modal then 
            ai_modal.show = state.ai_modal_show or false 
            ai_modal.current_step = state.ai_modal_step or "SELECT_TASK"
        end
        if dict_modal then dict_modal.show = state.dict_modal_show or false end
        -- Table
        if state.table_filter_state then table_filter_state = deep_copy(state.table_filter_state) end
        if state.find_replace_state then find_replace_state = deep_copy(state.find_replace_state) end
        if state.table_selection then table_selection = deep_copy(state.table_selection) end
        if state.table_sort then table_sort = deep_copy(state.table_sort) end
        last_selected_row = state.last_selected_row
    else
        -- Defaults for new project session
        text_editor_active = false
        if ai_modal then ai_modal.show = false ai_modal.current_step = "SELECT_TASK" end
        if dict_modal then dict_modal.show = false end
        table_selection = {}
        last_selected_row = nil
    end
end

-- =============================================================================
-- DATA STRUCTURES
-- =============================================================================

-- ASS/Subtitle Data
local ass_lines = {}
local ass_actors = {}
local actor_colors = {} -- {ActorName = integerColor}
local ass_file_loaded = false
local current_file_name = nil

local UI = {
    C_BG = {0.15, 0.15, 0.15},
    C_BTN = {0.3, 0.3, 0.3},
    C_BTN_H = {0.4, 0.4, 0.4},
    C_TXT = {0.9, 0.9, 0.9},
    C_ROW = {0.2, 0.2, 0.2},
    C_ROW_ALT = {0.23, 0.23, 0.23},
    C_SEL = {0.6, 0.7, 0.9},
    C_TAB_ACT = {0.25, 0.25, 0.25},
    C_TAB_INA = {0.2, 0.2, 0.2}
}
local bg_palette = {
    UI.C_BG, -- Default Dark
    {0.67, 0.69, 0.69}, -- Light Grey
    {0.96, 0.93, 0.86}, -- текст {0.18, 0.18, 0.18}
    {0.98, 0.98, 0.96}, -- текст {0.1, 0.1, 0.1}
    {0.12, 0.13, 0.14}, -- текст {0.82, 0.82, 0.82}
    {0.06, 0.09, 0.16}, -- текст {0.8, 0.84, 0.88}
    {0.18, 0.2, 0.25}, -- текст {0.85, 0.87, 0.91}
    {0.98, 0.92, 0.82}, -- текст {0.37, 0.29, 0.2}
    {0.99, 0.96, 0.89}, -- текст {0.39, 0.48, 0.51}
    {0, 0.17, 0.21}, -- текст {0.51, 0.58, 0.59}
}
local text_palette = {
    -- Основні кольори для темного фону
    {0.98, 0.98, 0.98},    -- Pure White (Чистий Білий)
    {1.0, 1.0, 0.0},    -- Yellow (Яскравий Жовтий)
    {1.0, 0.3, 0.3},    -- Bright Red (Яскраво-Червоний)
    {0.3, 1.0, 0.3},    -- Bright Green (Яскраво-Зелений)
    {0.3, 0.7, 1.0},    -- Bright Blue (Яскраво-Синій)
    {0.3, 1.0, 1.0},    -- Cyan (Яскраво-Блакитний)
    {1.0, 0.3, 1.0},    -- Magenta (Яскраво-Пурпуровий)

    -- Основні кольори для світлого фону
    {0.17, 0.17, 0.17},
    {0.05, 0.05, 0.05}     -- Pure Black (Чистий Чорний)
}

--- Save current settings to REAPER ExtState (persistent storage)
local function save_settings()
    reaper.SetExtState(section_name, "dock", tostring(last_dock_state), true)
    
    reaper.SetExtState(section_name, "p_fsize", tostring(cfg.p_fsize), true)
    reaper.SetExtState(section_name, "p_cr", tostring(cfg.p_cr), true)
    reaper.SetExtState(section_name, "p_cg", tostring(cfg.p_cg), true)
    reaper.SetExtState(section_name, "p_cb", tostring(cfg.p_cb), true)
    reaper.SetExtState(section_name, "p_next", cfg.p_next and "1" or "0", true)
    reaper.SetExtState(section_name, "p_align", cfg.p_align, true)
    reaper.SetExtState(section_name, "auto_srt_split", cfg.auto_srt_split, true)
    reaper.SetExtState(section_name, "prmt_theme", cfg.prmt_theme, true)

    -- Invalidate prompter cache when settings change (like wrap length)
    if draw_prompter_cache then
        draw_prompter_cache.last_text = nil
        draw_prompter_cache.last_next_text = nil
    end

    reaper.SetExtState(section_name, "p_font", cfg.p_font, true)
    reaper.SetExtState(section_name, "p_info", cfg.p_info and "1" or "0", true)
    
    reaper.SetExtState(section_name, "n_fsize", tostring(cfg.n_fsize), true)
    reaper.SetExtState(section_name, "n_cr", tostring(cfg.n_cr), true)
    reaper.SetExtState(section_name, "n_cg", tostring(cfg.n_cg), true)
    reaper.SetExtState(section_name, "n_cb", tostring(cfg.n_cb), true)
    
    reaper.SetExtState(section_name, "bg_cr", tostring(cfg.bg_cr), true)
    reaper.SetExtState(section_name, "bg_cg", tostring(cfg.bg_cg), true)
    reaper.SetExtState(section_name, "bg_cb", tostring(cfg.bg_cb), true)

    reaper.SetExtState(section_name, "wrap_length", tostring(cfg.wrap_length), true)
    reaper.SetExtState(section_name, "always_next", cfg.always_next and "1" or "0", true)
    reaper.SetExtState(section_name, "random_color_actors", cfg.random_color_actors and "1" or "0", true)
    reaper.SetExtState(section_name, "text_assimilations", cfg.text_assimilations and "1" or "0", true)
    reaper.SetExtState(section_name, "karaoke_mode", cfg.karaoke_mode and "1" or "0", true)
    reaper.SetExtState(section_name, "auto_startup", cfg.auto_startup and "1" or "0", true)
    reaper.SetExtState(section_name, "all_caps", cfg.all_caps and "1" or "0", true)
    reaper.SetExtState(section_name, "wave_bg", cfg.wave_bg and "1" or "0", true)
    reaper.SetExtState(section_name, "wave_bg_progress", cfg.wave_bg_progress and "1" or "0", true)

    reaper.SetExtState(section_name, "count_timer", cfg.count_timer and "1" or "0", true)
    reaper.SetExtState(section_name, "cps_warning", cfg.cps_warning and "1" or "0", true)
    reaper.SetExtState(section_name, "gemini_api_key", cfg.gemini_api_key, true)
end

-- =============================================================================
-- UTILITY FUNCTIONS
-- =============================================================================

--- Set GFX color from RGB array
--- @param c table RGB color array {r, g, b}
local function set_color(c)
    gfx.r, gfx.g, gfx.b = c[1], c[2], c[3]
    gfx.a = c[4] or 1.0
end

--- Compare subtitle text robustly
--- @param s1 string
--- @param s2 string
--- @return boolean
local function compare_sub_text(s1, s2)
    if s1 == s2 then return true end
    if not s1 or not s2 then return false end
    
    -- Normalize for comparison
    local function norm(s)
        if not s then return "" end
        -- 1. Remove Ukrainian stress marks
        local n = s:gsub("\204\129", "")
        -- 2. Normalize line endings and whitespace
        n = n:gsub("\r\n", "\n"):gsub("\r", "\n"):gsub("\\N", "\n"):gsub("\\n", "\n")
        -- 3. Trim
        n = n:gsub("^%s+", ""):gsub("%s+$", "")
        return n
    end
    
    return norm(s1) == norm(s2)
end

--- Draw a vertical scrollbar with drag interaction
--- @param x number X position
--- @param y number Y position
--- @param w number Width
--- @param h number Height
--- @param total_h number Total content height
--- @param visible_h number Visible content height
--- @param scroll_y number Current scroll position
--- @return number New scroll position (updated if dragged)
local function draw_scrollbar(x, y, w, h, total_h, visible_h, scroll_y)
    if total_h <= visible_h then return 0 end
    
    -- Background
    set_color({0, 0, 0, 0.3})
    gfx.rect(x, y, w, h, 1)
    
    local ratio = visible_h / total_h
    local handle_h = math.max(20, h * ratio)
    local max_scroll = total_h - visible_h
    
    -- Clamp scroll_y
    if scroll_y < 0 then scroll_y = 0 end
    if scroll_y > max_scroll then scroll_y = max_scroll end
    
    local handle_y = y + (scroll_y / max_scroll) * (h - handle_h)
    
    -- Draw Handle
    local is_hover = (gfx.mouse_x >= x and gfx.mouse_x <= x + w and gfx.mouse_y >= handle_y and gfx.mouse_y <= handle_y + handle_h)
    if is_hover then
        set_color({0.7, 0.7, 0.7, 0.9})
    else
        set_color({0.5, 0.5, 0.5, 0.8})
    end
    gfx.rect(x + 2, handle_y, w - 4, handle_h, 1)
    
    -- Interaction
    if (gfx.mouse_cap & 1 == 1) then
        if gfx.mouse_x >= x - 5 and gfx.mouse_x <= x + w + 5 and gfx.mouse_y >= y and gfx.mouse_y <= y + h then
            -- Center handle on mouse y
            local rel_y = gfx.mouse_y - y - (handle_h / 2)
            local range = h - handle_h
            if range > 0 then
                local prog = rel_y / range
                if prog < 0 then prog = 0 end
                if prog > 1 then prog = 1 end
                return prog * max_scroll
            end
        end
    end
    
    return scroll_y
end

--- Get color for CPS (Characters Per Second) with smooth gradient for high speeds
--- @param cps number
--- @return table RGB color array
local function get_cps_color(cps)
    if cps < 5 then
        -- Gradient from Blue {0.3, 0.6, 1} to White {1, 1, 1}
        local t = cps / 5
        return {0.3 + 0.7 * t, 0.6 + 0.4 * t, 1.0}
    elseif cps < 14 then
        return {1, 1, 1} -- White (Normal)
    elseif cps < 15 then
        -- Gradient from White {1, 1, 1} to Orange {0.9, 0.6, 0.2}
        local t = cps - 14
        return {1.0 - 0.1 * t, 1.0 - 0.4 * t, 1.0 - 0.8 * t}
    elseif cps <= 20 then
        -- Gradient from Orange {0.9, 0.6, 0.2} to Red {0.9, 0.2, 0.2}
        local t = (cps - 15) / 5
        return {0.9, 0.6 - 0.4 * t, 0.2}
    else
        return {0.9, 0.2, 0.2} -- Red (Max Speed)
    end
end

--- Parse SRT timestamp format (HH:MM:SS,mmm)
--- @param str string Timestamp string
--- @return number Time in seconds
local function parse_timestamp(str)
    local h, m, s, ms = str:match("(%d+):(%d+):(%d+),(%d+)")
    if not h then return 0 end
    return (tonumber(h) * 3600) + (tonumber(m) * 60) + tonumber(s) + (tonumber(ms) / 1000)
end

--- URL Encode string for safe usage in URLs
--- @param str string Input string
--- @return string Encoded string
local function url_encode(str)
    if not str then return "" end
    str = str:gsub("\n", "\r\n")
    str = str:gsub("([^%w %-%_%.%~])",
        function (c) return string.format ("%%%02X", string.byte(c)) end)
    str = str:gsub(" ", "+")
    return str
end

--- URL Decode string
--- @param str string Encoded string
--- @return string Decoded string
local function url_decode(str)
    if not str then return "" end
    str = str:gsub("+", " ")
    str = str:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
    return str
end

--- Parse ASS timestamp format (H:MM:SS.cs) to seconds
--- @param str string Timestamp string
--- @return number Time in seconds or 0 if invalid
local function parse_ass_timestamp(str)
    local h, m, s, cs = str:match("(%d+):(%d+):(%d+)%.(%d+)")
    if not h then return 0 end
    return (tonumber(h) * 3600) + (tonumber(m) * 60) + tonumber(s) + (tonumber(cs) / 100)
end

--- Split text into words and separators for interaction
--- @param text string Input text
--- @return table List of segments {text, is_word}
local function get_words_and_separators(text)
    local result = {}
    local pos = 1
    -- Includes Cyrillic, Latin, apostrophes, and hyphens for compound words
    local pattern = "[%a\128-\255\'%-]+[\128-\255]*"
    
    while pos <= #text do
        local s, e = text:find(pattern, pos)
        if s then
            if s > pos then
                table.insert(result, {text = text:sub(pos, s-1), is_word = false})
            end
            table.insert(result, {text = text:sub(s, e), is_word = true})
            pos = e + 1
        else
            table.insert(result, {text = text:sub(pos), is_word = false})
            break
        end
    end
    return result
end

-- =============================================================================
-- ASYNC COMMAND INFRASTRUCTURE
-- =============================================================================
local global_async_pool = {} -- { { id=str, out_file=str, done_file=str, callback=func } }

--- Execute a shell command asynchronously (background task)
--- @param shell_cmd string Command to execute
--- @param callback function Callback function(output) on completion
local function run_async_command(shell_cmd, callback)
    local id = tostring(os.time()) .. "_" .. math.random(1000,9999)
    local path = reaper.GetResourcePath() .. "/Scripts/"
    local out_file = path .. "async_out_" .. id .. ".tmp"
    local done_file = path .. "async_done_" .. id .. ".marker"
    
    if reaper.GetOS():match("Win") then
        out_file = out_file:gsub("/", "\\")
        done_file = done_file:gsub("/", "\\")
        -- Windows background execution: start /B
        -- We wrap in cmd /c to handle redirects
        local full_cmd = 'start /B cmd /c "' .. shell_cmd .. ' > "' .. out_file .. '" && echo DONE > "' .. done_file .. '"'
        os.execute(full_cmd)
    else
        -- Unix/Mac background execution: &
        local full_cmd = shell_cmd .. ' > "' .. out_file .. '" && touch "' .. done_file .. '" &'
        os.execute(full_cmd)
    end
    
    table.insert(global_async_pool, {
        id = id,
        out_file = out_file,
        done_file = done_file,
        callback = callback
    })
    
    script_loading_state.active = true
    script_loading_state.text = "Завантаження даних..."
end

--- Check statuses of active async tasks and trigger callbacks if done
local function check_async_pool()
    for i = #global_async_pool, 1, -1 do
        local task = global_async_pool[i]
        local f = io.open(task.done_file, "r")
        if f then
            f:close()
            -- Task complete!
            -- Read output
            local output = ""
            local f_out = io.open(task.out_file, "r")
            if f_out then
                output = f_out:read("*a")
                f_out:close()
            end
            
            -- Cleanup files
            os.remove(task.done_file)
            os.remove(task.out_file)
            
            -- Run callback
            if task.callback then
                task.callback(output)
            end
            
            table.remove(global_async_pool, i)
            
            -- Use defer to allow UI update if multiple tasks finish
            if #global_async_pool == 0 and not current_stress_job then
                script_loading_state.active = false
            end
        end
    end
end

--- Draw a global loading overlay with spinner when async tasks are active
local function draw_loader()
    if not script_loading_state.active then return end
    
    -- Overlay
    gfx.set(0, 0, 0, 0.7)
    gfx.rect(0, 0, gfx.w, gfx.h, 1)
    
    -- Loading Text
    gfx.setfont(F.bld)
    set_color(UI.C_TXT)
    
    local str = script_loading_state.text or "Завантаження..."
    local sw, sh = gfx.measurestr(str)
    
    local cx, cy = gfx.w / 2, gfx.h / 2
    
    gfx.x = cx - sw / 2
    gfx.y = cy - sh / 2
    gfx.drawstr(str)
    
    -- Simple Spinner (Visual)
    local radius = 20
    local spinner_y = cy - sh - 30
    local time = os.clock() * 10
    
    for i = 0, 7 do
        local angle = i * (math.pi / 4) + time
        local px = cx + math.cos(angle) * radius
        local py = spinner_y + math.sin(angle) * radius
        
        local alpha = (math.sin(i / 8 * math.pi * 2 + time) + 1) / 2
        gfx.set(1, 1, 1, alpha)
        gfx.circle(px, py, 3, 1)
    end
    
    -- Force update to animate
    reaper.defer(function() end) 
end

-- =============================================================================
-- MOUSE INPUT HELPERS
-- =============================================================================

--- Check if mouse was just clicked (left button down this frame)
--- @return boolean True if clicked this frame
local function is_mouse_clicked()
    return gfx.mouse_cap == 1 and last_mouse_cap == 0
end

--- Check if mouse right button was just clicked
--- @return boolean True if clicked this frame
local function is_right_mouse_clicked()
    return gfx.mouse_cap == 2 and last_mouse_cap == 0
end

-- =============================================================================
-- UI COMPONENT HELPERS
-- =============================================================================

--- Draw selection border (double rectangle outline)
--- @param x number Left position
--- @param y number Top position
--- @param w number Width
--- @param h number Height
local function draw_selection_border(x, y, w, h)
    gfx.rect(x - 4, y - 4, w + 8, h + 8, 0)
    gfx.rect(x - 3, y - 3, w + 6, h + 6, 0)
end

-- --- GUI Components ---
--- Draw a button component
--- @param x number X position
--- @param y number Y position
--- @param w number Width
--- @param h number Height
--- @param text string Button label
--- @param bg_col RGB color array
--- @return boolean True if clicked
local function btn(x, y, w, h, text, bg_col)
    local hover = (gfx.mouse_x >= x and gfx.mouse_x <= x+w and gfx.mouse_y >= y and gfx.mouse_y <= y+h)
    set_color(hover and UI.C_BTN_H or (bg_col or UI.C_BTN))
    gfx.rect(x, y, w, h, 1)
    set_color(UI.C_TXT)
    gfx.setfont(F.std)
    -- Center text roughly
    local str_w, str_h = gfx.measurestr(text)
    gfx.x = x + (w - str_w) / 2
    gfx.y = y + (h - str_h) / 2
    gfx.drawstr(text)
    if hover and is_mouse_clicked() then return true end
    return false
end

-- =============================================================================
-- SNACKBAR NOTIFICATIONS
-- =============================================================================

--- Show temporary notification message
--- @param text string Message to display
local function show_snackbar(text, delay)
    snackbar_duration = delay or 2.0
    snackbar_text = text
    snackbar_show_time = reaper.time_precise()
end

--- Draw tooltip at mouse position
local function draw_tooltip()
    if not tooltip_state.text or tooltip_state.text == "" then return end
    
    local now = reaper.time_precise()
    if now - tooltip_state.start_time < 1.0 then return end
    
    gfx.setfont(F.tip)
    
    -- Split by newline and measure max width
    local lines = {}
    local max_w = 0
    for line in tooltip_state.text:gmatch("[^\r\n]+") do
        table.insert(lines, line)
        local w, h = gfx.measurestr(line)
        if w > max_w then max_w = w end
    end
    
    local padding = 6
    local line_h = 15
    local total_h = #lines * line_h
    
    local tx = gfx.mouse_x + 15
    local ty = gfx.mouse_y + 15
    
    -- Ensure it stays on screen
    if tx + max_w + (padding * 2) > gfx.w then tx = gfx.mouse_x - max_w - (padding * 2) - 5 end
    if ty + total_h + (padding * 2) > gfx.h then ty = gfx.mouse_y - total_h - (padding * 2) - 5 end
    if tx < 0 then tx = 0 end
    if ty < 0 then ty = 0 end
    
    -- Background
    set_color({0.1, 0.1, 0.1, 0.95})
    gfx.rect(tx, ty, max_w + padding * 2, total_h + padding * 2, 1)
    
    -- Border
    set_color({0.7, 0.7, 0.7, 0.8})
    gfx.rect(tx, ty, max_w + padding * 2, total_h + padding * 2, 0)
    
    -- Text
    set_color(UI.C_TXT)
    for i, line in ipairs(lines) do
        gfx.x = tx + padding
        gfx.y = ty + padding + (i-1) * line_h
        gfx.drawstr(line)
    end
end

--- Draw snackbar notification with fade-out animation
local function draw_snackbar()
    if snackbar_text == "" then return end
    
    local current_time = reaper.time_precise()
    local elapsed = current_time - snackbar_show_time
    
    if elapsed > snackbar_duration then
        snackbar_text = "" -- Hide snackbar
        return
    end
    
    -- Calculate fade-out alpha
    local alpha = 1.0
    if elapsed > snackbar_duration - 0.2 then
        -- Fade out in last 0.2 seconds
        alpha = (snackbar_duration - elapsed) / 0.2
    end
    
    -- Measure text
    gfx.setfont(F.std)
    local text_w, text_h = gfx.measurestr(snackbar_text)
    
    -- Snackbar dimensions
    local padding = 15
    local snack_w = text_w + padding * 2
    local snack_h = text_h + padding
    local snack_x = (gfx.w - snack_w) / 2
    local snack_y = gfx.h - snack_h - 10
    
    -- Background
    set_color({0.2, 0.2, 0.2, alpha * 0.9})
    gfx.rect(snack_x, snack_y, snack_w, snack_h, 1)
    
    -- Border
    set_color({0.4, 0.4, 0.4, alpha})
    gfx.rect(snack_x, snack_y, snack_w, snack_h, 0)
    
    -- Text
    set_color({1, 1, 1, alpha})
    gfx.x = snack_x + padding
    gfx.y = snack_y + padding / 2
    gfx.drawstr(snackbar_text)
end

-- =============================================================================
-- UTF-8 TEXT PROCESSING
-- =============================================================================

--- Convert UTF-8 string to lowercase (supports Cyrillic)
--- @param s string Input string
--- @return string Lowercase string
local function utf8_lower(s)
    if not s then return "" end
    local res = {}
    local len = #s
    local i = 1
    while i <= len do
        local b = s:byte(i)
        if b < 128 then
            -- ASCII A-Z
            if b >= 65 and b <= 90 then
                table.insert(res, string.char(b + 32))
            else
                table.insert(res, string.char(b))
            end
            i = i + 1
        else
            -- Multibyte
            local seq_len = 0
            if b >= 240 then seq_len = 4
            elseif b >= 224 then seq_len = 3
            elseif b >= 192 then seq_len = 2
            end
            
            if seq_len > 0 and i + seq_len - 1 <= len then
                -- Valid length, try to decode
                local codepoint = 0
                if seq_len == 2 then
                    codepoint = ((b & 31) << 6) | (s:byte(i+1) & 63)
                elseif seq_len == 3 then
                    codepoint = ((b & 15) << 12) | ((s:byte(i+1) & 63) << 6) | (s:byte(i+2) & 63)
                elseif seq_len == 4 then
                    codepoint = ((b & 7) << 18) | ((s:byte(i+1) & 63) << 12) | ((s:byte(i+2) & 63) << 6) | (s:byte(i+3) & 63)
                end
                
                -- Cyrillic Case Mapping
                -- Basic: 0x0410(1040) - 0x042F(1071) -> +32
                if codepoint >= 1040 and codepoint <= 1071 then codepoint = codepoint + 32 
                -- Special mappings
                elseif codepoint == 1025 then codepoint = 1105 -- Yo
                elseif codepoint == 1028 then codepoint = 1108 -- Ye
                elseif codepoint == 1030 then codepoint = 1110 -- I
                elseif codepoint == 1031 then codepoint = 1111 -- Yi
                elseif codepoint == 1168 then codepoint = 1169 -- Ghe
                end
                
                table.insert(res, utf8.char(codepoint))
                i = i + seq_len
            else
                -- Invalid start byte or truncated: just copy the byte
                table.insert(res, string.char(b))
                i = i + 1
            end
        end
    end
    return table.concat(res)
end

-- Helper: UTF-8 safe uppercase
--- Convert UTF-8 string to uppercase (supports Cyrillic)
--- @param s string Input string
--- @return string Uppercase string
local function utf8_upper(s)
    if not s then return "" end
    local res = {}
    local len = #s
    local i = 1
    while i <= len do
        local b = s:byte(i)
        if b < 128 then
            if b >= 97 and b <= 122 then
                table.insert(res, string.char(b - 32))
            else
                table.insert(res, string.char(b))
            end
            i = i + 1
        else
            local seq_len = 0
            if b >= 240 then seq_len = 4
            elseif b >= 224 then seq_len = 3
            elseif b >= 192 then seq_len = 2
            end
            
            if seq_len > 0 and i + seq_len - 1 <= len then
                local codepoint = 0
                if seq_len == 2 then
                    codepoint = ((b & 31) << 6) | (s:byte(i+1) & 63)
                elseif seq_len == 3 then
                    codepoint = ((b & 15) << 12) | ((s:byte(i+1) & 63) << 6) | (s:byte(i+2) & 63)
                elseif seq_len == 4 then
                    codepoint = ((b & 7) << 18) | ((s:byte(i+1) & 63) << 12) | ((s:byte(i+2) & 63) << 6) | (s:byte(i+3) & 63)
                end
                
                -- Cyrillic Upper Mapping
                if codepoint >= 1072 and codepoint <= 1103 then codepoint = codepoint - 32
                elseif codepoint == 1105 then codepoint = 1025
                elseif codepoint == 1108 then codepoint = 1028
                elseif codepoint == 1110 then codepoint = 1030
                elseif codepoint == 1111 then codepoint = 1031
                elseif codepoint == 1169 then codepoint = 1168
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

--- Capitalize first character of UTF-8 string
--- @param s string Input string
--- @return string String with first character capitalized
local function utf8_capitalize(s)
    if not s or s == "" then return "" end
    local b = s:byte(1)
    local seq_len = 1
    if b >= 240 then seq_len = 4
    elseif b >= 224 then seq_len = 3
    elseif b >= 192 then seq_len = 2
    end
    
    return utf8_upper(s:sub(1, seq_len)) .. s:sub(seq_len + 1)
end

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

--- Drawing primitive for acute accent (stress mark)
--- @param base_x number X position of character
--- @param base_y number Y position of character (top)
--- @param char_width number Width of character
--- @param char_height number Height of font
--- @param is_uppercase boolean Whether character is uppercase (for adaptive positioning)
local function draw_acute_accent_primitive(base_x, base_y, char_width, char_height, is_uppercase)
    -- Acute accent: two tilted lines side by side, right one is red
    local accent_height = char_height * 0.22 
    local left_line_thickness = 3 
    local right_line_thickness = 1 
    
    local center_x = base_x + (char_width / 2)
    
    local top_y
    if is_uppercase then
        top_y = base_y - (char_height * 0.20)
    else
        top_y = base_y - (char_height * 0.05)
    end
    
    local tilt_offset = char_width * 0.08 
    local bottom_y = top_y + accent_height
    local top_y_pos = top_y
    
    local orig_r, orig_g, orig_b = gfx.r, gfx.g, gfx.b
    
    -- Left line (text color)
    local left_x_bottom = center_x - right_line_thickness
    local left_x_top = left_x_bottom + tilt_offset
    
    gfx.set(orig_r, orig_g, orig_b, 1)
    for t = 0, left_line_thickness - 1 do
        gfx.line(left_x_bottom + t, bottom_y, left_x_top + t, top_y_pos)
    end
    
    -- Right line (red)
    local right_x_bottom = center_x + 1.5
    local right_x_top = right_x_bottom + tilt_offset
    local right_bottom_y = bottom_y - (accent_height / 2)
    
    gfx.set(1.0, 0.0, 0.0, 1) -- red color for accent mark
    for t = 0, right_line_thickness - 1 do
        gfx.line(right_x_bottom + t, right_bottom_y, right_x_top + t, top_y_pos)
    end
    
    gfx.set(orig_r, orig_g, orig_b, 1)
end

--- Draw text string, automatically rendering manual stress marks where the combining acute accent (U+0301) is found.
--- @param text string The string to draw
--- @param use_all_caps boolean? Whether to force uppercase
local function draw_text_with_stress_marks(text, use_all_caps)
    if not text or text == "" then return end
    
    local d_text = text
    if use_all_caps then
        d_text = utf8_upper(text)
    end
    
    if not d_text:find(acute) then
        gfx.drawstr(d_text)
        return
    end
    
    local i = 1
    local len = #d_text
    while i <= len do
        local b = d_text:byte(i)
        local char_len = 1
        if b >= 240 then char_len = 4
        elseif b >= 224 then char_len = 3
        elseif b >= 192 then char_len = 2
        end
        
        local char_end = i + char_len - 1
        local next_char_start = char_end + 1
        
        local has_stress = false
        if next_char_start <= len then
            if d_text:byte(next_char_start) == 204 and d_text:byte(next_char_start+1) == 129 then
                has_stress = true
            end
        end
        
        local char_str = d_text:sub(i, char_end)
        if has_stress then
            local w_base = gfx.measurestr(char_str)
            local h_base = gfx.texth
            local char_start_x = gfx.x
            local char_y = gfx.y
            
            gfx.drawstr(char_str)
            
            local is_uppercase = (char_str == utf8_upper(char_str))
            draw_acute_accent_primitive(char_start_x, char_y, w_base, h_base, is_uppercase)
            
            i = next_char_start + 2
        else
            gfx.drawstr(char_str)
            i = next_char_start
        end
    end
end

--- Strip HTML tags and entities
local function clean_html(html)
    if not html then return "" end
    -- Remove script and style blocks
    html = html:gsub("<script.-/script>", "")
    html = html:gsub("<style.-/style>", "")
    -- Simplest tag removal
    html = html:gsub("<[^>]+>", "")
    -- Common entities
    html = html:gsub("&nbsp;", " ")
    html = html:gsub("&quot;", "\"")
    html = html:gsub("&amp;", "&")
    html = html:gsub("&lt;", "<")
    html = html:gsub("&gt;", ">")
    -- Handle decimal entities &#1234;
    html = html:gsub("&#(%d+)%s*;", function(d) return utf8_char(tonumber(d)) end)
    -- Handle hex entities &#xABCD;
    html = html:gsub("&#x(%x+)%s*;", function(h) return utf8_char(tonumber(h, 16)) end)
    return html
end

--- Parse mixed text with <a> tags into segments
local function parse_rich_text(html)
    local segments = {}
    local remaining = html:gsub("%s+", " ")
    
    local tags = {
        { tag = "a", pattern = "<a%s+([^>]-)>([^\0]-)</a>" },
        { tag = "span", pattern = "<span%s+([^>]-)>([^\0]-)</span>" },
        { tag = "b", pattern = "<b[^>]*>([^\0]-)</b>" },
        { tag = "strong", pattern = "<strong[^>]*>([^\0]-)</strong>" },
        { tag = "i", pattern = "<i[^>]*>([^\0]-)</i>" },
        { tag = "em", pattern = "<em[^>]*>([^\0]-)</em>" }
    }
    
    while #remaining > 0 do
        local best_start = 1000000
        local best_end = 0
        local chosen_tag = nil
        local chosen_attr = ""
        local chosen_text = ""
        
        for _, t in ipairs(tags) do
            local s, e, a, txt
            if t.tag == "a" or t.tag == "span" then
                s, e, a, txt = remaining:find(t.pattern)
            else
                s, e, txt = remaining:find(t.pattern)
                a = ""
            end
            
            if s and s < best_start then
                best_start = s
                best_end = e
                chosen_tag = t.tag
                chosen_attr = a or ""
                chosen_text = txt or ""
            end
        end
        
        if chosen_tag then
            -- Prefix (plain text before tag)
            local prefix = remaining:sub(1, best_start - 1)
            if #prefix > 0 then
                table.insert(segments, {text = clean_html(prefix)})
            end
            
            -- Tag specific logic
            if chosen_tag == "a" then
                local word = chosen_attr:match('href=".-/([^/"]+)"') or chosen_text
                word = url_decode(clean_html(word)):gsub("^%s+", ""):gsub("%s+$", "")
                table.insert(segments, {
                    text = clean_html(chosen_text),
                    is_link = true,
                    word = word
                })
            elseif chosen_tag == "span" then
                local is_plain_class = chosen_attr:find('short.interpret') or chosen_attr:find('interpret') or 
                    chosen_attr:find('remark') or 
                    chosen_attr:find('gram') or 
                    chosen_attr:find('info') or
                    chosen_attr:find('description') or
                    chosen_attr:find('term') or
                    chosen_attr:find('note') or
                    chosen_attr:find('interpret%-formula')
               
                -- Support nested tags within span by recursive parsing
                local inner_segments = parse_rich_text(chosen_text)
                for _, s in ipairs(inner_segments) do
                    if is_plain_class then s.is_plain = true end
                    table.insert(segments, s)
                end
            elseif chosen_tag == "b" or chosen_tag == "strong"  then
                table.insert(segments, {
                    text = clean_html(chosen_text),
                    is_bold = true
                })
            elseif chosen_tag == "i" or chosen_tag == "em" then
                table.insert(segments, {
                    text = clean_html(chosen_text),
                    is_italic = true,
                    is_plain = true
                })
            end
            
            remaining = remaining:sub(best_end + 1)
        else
            table.insert(segments, {text = clean_html(remaining)})
            remaining = ""
        end
    end
    
    -- Cleanup whitespace across segments and merge identical formats
    local merged = {}
    for _, seg in ipairs(segments) do
        -- Normalize fields
        seg.is_link = seg.is_link or false
        seg.is_plain = (seg.is_plain == true) -- Force boolean
        seg.is_bold = seg.is_bold or false
        seg.word = seg.word or ""
        
        if #seg.text > 0 or seg.is_link then
            local last = merged[#merged]
            local can_merge = last and 
                (last.is_link == seg.is_link) and 
                (last.is_plain == seg.is_plain) and 
                (last.is_bold == seg.is_bold) and
                (last.is_italic == seg.is_italic) and
                (not seg.is_link or (last.word == seg.word))
           
            if can_merge then
                last.text = last.text .. seg.text
            else
                table.insert(merged, {
                    text = seg.text,
                    is_link = seg.is_link,
                    word = seg.word,
                    is_plain = seg.is_plain, is_bold = seg.is_bold, is_italic = seg.is_italic
                })
            end
        end
    end
    
    return merged
end

--- Parse a <table> HTML string into a grid object
local function parse_dictionary_table_html(table_html)
    local grid = {is_table = true, rows = {}}
    for row_attr, row_content in table_html:gmatch('<tr%s*([^>]-)>([^\0]-)</tr>') do
        local row_data = {
            cells = {},
            is_header = row_attr:find('column%-header') or row_attr:find('subgroup%-header')
        }
        for cell_attr, cell_html in row_content:gmatch('<t[dh]%s*([^>]-)>([^\0]-)</t[dh]>') do
            local colspan = tonumber(cell_attr:match('colspan="?(%d+)"?')) or 1
            local rowspan = tonumber(cell_attr:match('rowspan="?(%d+)"?')) or 1
            local is_cell_header = cell_attr:find('class="[^"]*header[^"]*"')
            local cleaned = clean_html(cell_html)
            cleaned = cleaned:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
            table.insert(row_data.cells, {
                text = cleaned,
                colspan = colspan,
                rowspan = rowspan,
                is_header = is_cell_header
            })
        end
        if #row_data.cells > 0 then 
            table.insert(grid.rows, row_data) 
        end
    end
    
    -- Calculate max logical columns
    local max_cols = 0
    if #grid.rows > 0 then
        for _, cell in ipairs(grid.rows[1].cells) do
            max_cols = max_cols + (cell.colspan or 1)
        end
        grid.cols = max_cols
        return grid
    end
    return nil
end

--- Parse dictionary definition from HTML
local function parse_dictionary_definition(html, category)
    if not html or html == "" then return nil end
    
    -- Detect "Word not found" page pattern
    if html:find("Словник%s+«.-»%s+не%s+містить%s+слова") or 
       html:find("відсутнє%s+для%s+цього%s+словника") then
        return {}
    end

    local lines = {}

    -- Helper to split by article-block
    local blocks = {}
    local last_pos = 1
    while true do
        local b_start, b_end = html:find('<div[^>]-class="article%-block"[^>]->', last_pos)
        if not b_start then break end
        
        local next_b_start = html:find('<div[^>]-class="article%-block"[^>]->', b_end + 1)
        local block_content
        if next_b_start then
            block_content = html:sub(b_start, next_b_start - 1)
            last_pos = next_b_start
        else
            block_content = html:sub(b_start)
            table.insert(blocks, block_content)
            break
        end
        table.insert(blocks, block_content)
    end
    
    if #blocks == 0 then
        -- Fallback: use whole HTML as one block if no article-block found (might happen for some pages)
        blocks = { html }
    end

    for _, block in ipairs(blocks) do
        if category == "Тлумачення" then
            -- Interpretation body: extract the entire article-block__body content
            -- Instead of a non-greedy gmatch on div, let's find the content after the header
            local body = block:match('<div class="article%-block__body">([^\0]-)<footer') 
                      or block:match('<div class="article%-block__body">([^\0]-)</div>%s-</div>') -- More robust for nested divs
                      or block:match('<div class="article%-block__body">([^\0]-)$')
                      or block
            
            for item in body:gmatch('class="interpret.-"[^>]->([^\0]-)</div>') do
               local rich = parse_rich_text(item)
                if #rich > 0 then
                    rich[1].text = "• " .. rich[1].text
                    table.insert(lines, { segments = rich, indent = 0, is_header = false }) 
                end
            end
            
            -- Fallback items
            for item in body:gmatch('<div class="list%-item.-">([^\0]-)</div>') do
                local rich = parse_rich_text(item)
                if #rich > 0 then
                    rich[1].text = "• " .. rich[1].text
                    table.insert(lines, { segments = rich, indent = 0, is_header = false })
                end
            end
        elseif category == "Словозміна" then
            -- 1. Header (Word + short interpret)
            local header_html = block:match('<div [^>]-class="page__sub%-header"[^>]->([^\0]-)</div>')
           if header_html then
                -- Add " - " prefix to short-interpret span
                header_html = header_html:gsub('(<span[^>]-class="short%-interpret"[^>]->)', '%1 — ')
                local rich = parse_rich_text(header_html)

                if #rich > 0 then
                    table.insert(lines, { segments = rich, indent = 0, is_header = true })
                end
            end
           
            -- 3. All Tables in this block
            for table_html in block:gmatch('<table class="table">([^\0]-)</table>') do
                local grid = parse_dictionary_table_html(table_html)
                if grid then
                    table.insert(lines, grid)
                end
            end
        elseif category == "Синонімія" or category == "Фразеологія" then
            -- 1. Header (Word + short interpret)
            local header_html = block:match('<h2 [^>]-class="page__sub%-header"[^>]->([^\0]-)</h2>')
            if header_html then
                -- Add "- " prefix to short-interpret span
                header_html = header_html:gsub('%s*(<span[^>]-class="short%-interpret"[^>]->)', '%1 — ')
                local rich = parse_rich_text(header_html)

                if #rich > 0 then
                    table.insert(lines, { segments = rich, indent = 0, is_header = true })
                end
            end
            -- 2. Indented items (synonyms or phrase interprets)
            for item in block:gmatch('class="interpret.-"[^>]->([^\0]-)</div>') do
                local rich = parse_rich_text(item)
                if #rich > 0 then
                    rich[1].text = "• " .. rich[1].text
                    table.insert(lines, { segments = rich, indent = 1, is_header = false })
                end
            end
            
            for item in block:gmatch('class="list%-item.-">([^\0]-)</div>') do
                local rich = parse_rich_text(item)
                if #rich > 0 then
                    rich[1].text = "• " .. rich[1].text
                    table.insert(lines, { segments = rich, indent = 1, is_header = false })
                end
            end

            table.insert(lines, { segments = "" })
        end
    end
    
    if #lines == 0 then return {} end
    return lines
end

--- Fetch combined dictionary data
--- Fetch a specific dictionary category (Lazy loading)
local function fetch_dictionary_category(word, display_name)
    local categories = {
        ["Тлумачення"] = "Тлумачення",
        ["Словозміна"] = "Словозміна",
        ["Синоніми"] = "Синонімія",
        ["Фразеологія"] = "Фразеологія"
    }
    
    local url_part = categories[display_name]
    if not url_part then return nil end
    
    local encoded = word
    if not word:find("%%") then encoded = url_encode(word) end
    
    local url = "https://goroh.pp.ua/" .. url_encode(url_part) .. "/" .. encoded
    
    -- Construct curl command (for background execution)
    local cmd = "curl -s -L \"" .. url .. "\""
    -- Note: run_async_command handles OS specific wrapping / redirects
    
    run_async_command(cmd, function(html)
        if html and html ~= "" then
            local parsed = parse_dictionary_definition(html, url_part)
            -- Update Modal Content via Closure
            if dict_modal.show then
                dict_modal.content[display_name] = parsed
            end
        else
            if dict_modal.show then
                dict_modal.content[display_name] = "Не вдалося завантажити дані (або нічого не знайдено)."
            end
        end
    end)
    
    return "Завантаження..." -- Placeholder
end

--- Call Gemini API Asynchronously
--- @param key string API Key
--- @param prompt string Prompt text
--- @param final_callback function(status, body)
--- @param use_json_schema boolean|nil Use structured JSON output
local function gemini_api_call_async(key, prompt, final_callback, use_json_schema)
    if not key or key == "" then 
        final_callback(0, "No API Key")
        return 
    end

    local models = {
        "gemini-flash-latest",
        "gemini-3-flash-preview",
        "gemini-2.5-flash",
        "gemini-2.5-flash-lite",
        "gemini-2.0-flash",
        "gemini-2.0-flash-lite",
    }
    
    -- Improved JSON text escaping
    local escaped_prompt = prompt:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", "")
    
    local data
    if use_json_schema then
        data = '{"contents": [{"parts":[{"text": "' .. escaped_prompt .. '"}]}], "generationConfig": {"responseMimeType": "application/json", "responseSchema": {"type": "ARRAY", "items": {"type": "STRING"}}}}'
    else
        data = '{"contents": [{"parts":[{"text": "' .. escaped_prompt .. '"}]}]}'
    end
    
    -- Create temporary file for request body (Safer than CLI arguments)
    local temp_file = reaper.GetResourcePath() .. "/subass_gemini_req.json"
    if reaper.GetOS():match("Win") then temp_file = temp_file:gsub("/", "\\") end
    
    local f = io.open(temp_file, "w")
    if f then
        f:write(data)
        f:close()
    else
        final_callback(0, "Failed to create temp request file")
        return
    end

    -- Recursive function to try models one by one
    local function try_model(idx)
        if idx > #models then
            -- All failed
            if temp_file then os.remove(temp_file) end
            final_callback(0, "All models failed")
            return
        end
        
        local model = models[idx]
        local url = "https://generativelanguage.googleapis.com/v1beta/models/" .. model .. ":generateContent?key=" .. key
        
        local cmd
        if reaper.GetOS():match("Win") then
            -- Use --ssl-no-revoke to avoid common Windows curl issues
            cmd = 'curl -s -k --ssl-no-revoke -w "\\n%{http_code}" -X POST "' .. url .. '" -H "Content-Type: application/json" -d "@' .. temp_file .. '"'
        else
            -- macOS/Linux
            cmd = "curl -s -w '\\n%{http_code}' -X POST '" .. url .. "' -H 'Content-Type: application/json' -d '@" .. temp_file .. "'"
        end
        
        -- Async Execution
        run_async_command(cmd, function(output)
            if output and output ~= "" then
                local lines = {}
                for line in output:gmatch("[^\r\n]+") do table.insert(lines, line) end
                
                if #lines > 0 then
                    local status_code = tonumber(lines[#lines]) or 0
                    table.remove(lines, #lines)
                    local body = table.concat(lines, "\n")
                    
                    if status_code == 200 then
                        -- Success!
                        if temp_file then os.remove(temp_file) end
                        final_callback(status_code, body)
                    else
                        -- Failed, try next
                        try_model(idx + 1)
                    end
                else
                     try_model(idx + 1)
                end
            else
                try_model(idx + 1)
            end
        end)
    end
    
    -- Start chain
    try_model(1)
end

--- Extract text from Gemini JSON response using patterns (Robust)
--- @param json string JSON response body
--- @return string|nil Parsed text content
local function gemini_extract_text(json)
    if not json then return nil end
    
    -- Find "text": "
    local start_pattern = '"text"%s*:%s*"'
    local s, e = json:find(start_pattern)
    if not e then return nil end
    
    local start_index = e + 1
    local len = #json
    local end_index = nil
    
    -- Scan for closing quote, ignoring escaped ones
    local i = start_index
    while i <= len do
        local char = json:sub(i, i)
        if char == '"' then
            -- Check if escaped by counting preceding backslashes
            local backslashes = 0
            local j = i - 1
            while j >= start_index and json:sub(j, j) == '\\' do
                backslashes = backslashes + 1
                j = j - 1
            end
            
            if backslashes % 2 == 0 then
                -- Even backslashes -> Not escaped -> Found end!
                end_index = i - 1
                break
            end
        end
        i = i + 1
    end
    
    if end_index then
        local content = json:sub(start_index, end_index)
        -- Unescape JSON string
        content = content:gsub('\\"', '"'):gsub('\\n', '\n'):gsub('\\r', ''):gsub('\\t', '\t'):gsub('\\\\', '\\')
        return content
    end
    
    return nil
end

--- Parse simple JSON array of strings: ["a", "b"]
--- Handles escaped quotes inside strings
local function parse_json_string_array(json_str)
    local results = {}
    if not json_str then return results end
    
    -- Simple state machine parser
    local pos = 1
    local len = #json_str
    
    while pos <= len do
        -- Find start of string
        local start_quote = json_str:find('"', pos)
        if not start_quote then break end
        
        -- Find end of string, skipping escaped quotes
        local current = start_quote + 1
        local str_content = nil
        while current <= len do
            local end_quote = json_str:find('"', current)
            if not end_quote then break end
            
            -- Check if escaped
            local preceding_backslashes = 0
            local check_idx = end_quote - 1
            while check_idx >= current and json_str:sub(check_idx, check_idx) == "\\" do
                preceding_backslashes = preceding_backslashes + 1
                check_idx = check_idx - 1
            end
            
            if preceding_backslashes % 2 == 0 then
                -- Even backslashes means the quote is NOT escaped (it terminates the string)
                str_content = json_str:sub(start_quote + 1, end_quote - 1)
                pos = end_quote + 1
                break
            else
                -- Odd backslashes means quote IS escaped, continue searching
                current = end_quote + 1
            end
        end
        
        if str_content then
            -- Unescape JSON string
            str_content = str_content:gsub('\\"', '"'):gsub('\\\\', '\\'):gsub('\\n', '\n'):gsub('\\r', ''):gsub('\\t', '\t')
            table.insert(results, str_content)
        else
            pos = start_quote + 1 -- Should not happen in valid JSON
        end
    end
    return results
end

--- Parse 1. 2. 3. format into a table (Legacy fallback)
--- @param text string Multiline text
--- @return table List of suggestions
local function parse_ai_suggestions(text)
    local results = {}
    for line in text:gmatch("[^\r\n]+") do
        local cleaned = line:match("^%d+%.%s*(.+)$") or line:match("^[^%d]+%s*(.+)$") or line
        cleaned = cleaned:gsub("^%s+", ""):gsub("%s+$", "")
        if #cleaned > 0 then
            table.insert(results, cleaned)
        end
    end
    return results
end

--- Validate Gemini API Key with a simple prompt
--- @param key string API Key
local function validate_gemini_key(key)
    show_snackbar("Перевірка ключа...")
    gemini_api_call_async(key, "hi", function(status, body)
        gemini_key_status = status
        reaper.SetExtState(section_name, "gemini_key_status", tostring(status), true)
        
        if status == 200 then
            show_snackbar("API ключ валідний")
        elseif status == 429 then
            show_snackbar("Ліміти вичерпані (429)", 3.0)
        else
            show_snackbar("Помилка API ключа (код: " .. tostring(status) .. ")", 3.0)
        end
    end)
end

--- Trigger Gemini request for a specific task
--- @param task_name string Task name (e.g. "Перефразувати")
--- @param text string Selected text
--- @param variant_count integer|nil Number of variants to return (default: 3)
local function request_ai_assistant_task(task_name, text, variant_count)
    ai_modal.current_step = "LOADING"
    ai_modal.last_task = task_name
    
    local count = variant_count or 3
    
    -- Build context from surrounding replicas
    local context_before = ""
    local context_after = ""
    
    if text_editor_context_line_idx and text_editor_context_all_lines then
        local idx = text_editor_context_line_idx
        local lines = text_editor_context_all_lines
        
        -- Get 3 previous replicas
        for i = math.max(1, idx - 3), idx - 1 do
            if lines[i] then
                local actor = lines[i].actor or "Невідомо"
                context_before = context_before .. string.format("[%s]: %s\n", actor, lines[i].text)
            end
        end
        
        -- Get 3 next replicas
        for i = idx + 1, math.min(#lines, idx + 3) do
            if lines[i] then
                local actor = lines[i].actor or "Невідомо"
                context_after = context_after .. string.format("[%s]: %s\n", actor, lines[i].text)
            end
        end
    end
    
    -- Build prompt with context
    local instruction_suffix = (count == 1) and "варіант" or "варіанти"
    local instruction = string.format("Поверни JSON масив (array of strings), що містить рівно %d %s українською мовою. Не додавай ніякого іншого тексту, пояснень чи коментарів. Тільки чистий JSON.", 
        count, instruction_suffix)
    
    local prompt = "Завдання: " .. task_name .. ".\n\n"
    
    if context_before ~= "" then
        prompt = prompt .. "Попередні репліки:\n" .. context_before .. "\n"
    end
    
    if text then
        prompt = prompt .. "Текст для обробки: \"" .. text .. "\"\n\n"
    end
    
    if context_after ~= "" then
        prompt = prompt .. "Наступні репліки:\n" .. context_after .. "\n"
    end
    
    prompt = prompt .. instruction
    
    gemini_api_call_async(cfg.gemini_api_key, prompt, function(status, response)
        -- Callback executed when async request finishes
        if status == 200 then
            local content = gemini_extract_text(response)
            if content then
                -- Try to parse structured output first
                local new_suggs = parse_json_string_array(content)
                
                -- Fallback to old parser only if empty (e.g. model ignored JSON schema)
                if #new_suggs == 0 then
                    new_suggs = parse_ai_suggestions(content)
                end
                
                if #new_suggs > 0 then
                    -- Mark current ones as old
                    for _, s in ipairs(ai_modal.suggestions) do s.is_old = true end
                    -- Prepend new ones
                    for i = #new_suggs, 1, -1 do
                        table.insert(ai_modal.suggestions, 1, { text = new_suggs[i], is_old = false })
                    end
                    
                    -- Record in history (all variants from Gemini)
                    table.insert(ai_modal.history, {
                        original = text,
                        task = task_name,
                        variants = new_suggs, -- All variants from Gemini
                        context_before = context_before, -- Added context
                        context_after = context_after,   -- Added context
                        timestamp = os.date("%H:%M:%S")
                    })
                    
                    ai_modal.current_step = "RESULTS"
                else
                    ai_modal.error_msg = "AI не повернув варіантів."
                    ai_modal.current_step = "ERROR"
                end
            else
                ai_modal.error_msg = "Не вдалося розпізнати відповідь AI."
                ai_modal.current_step = "ERROR"
            end
        else
            ai_modal.error_msg = "Помилка запиту: " .. status .. "\n" .. (response or "")
            ai_modal.current_step = "ERROR"
        end
    end, true) -- USE JSON SCHEMA = TRUE
end

--- Unified trigger for dictionary lookup
local function trigger_dictionary_lookup(word)
    -- Clean word from extra symbols
    word = word:gsub('^["\'«»]+', ''):gsub('["\'«»]+$', '')    
    local first_tab = "Словозміна"
    
    -- Manage history: If already showing, push current state
    if dict_modal.show then
        table.insert(dict_modal.history, {
            word = dict_modal.word,
            content = dict_modal.content,
            selected_tab = dict_modal.selected_tab,
            scroll_y = dict_modal.scroll_y,
            target_scroll_y = dict_modal.target_scroll_y
        })
    else
        -- Initial open, clear history
        dict_modal.history = {}
    end

    local content = fetch_dictionary_category(word, first_tab)
    if content then
        dict_modal.word = word
        dict_modal.content = { [first_tab] = content }
        dict_modal.selected_tab = first_tab
        dict_modal.show = true
        dict_modal.scroll_y = 0
        dict_modal.target_scroll_y = 0
        return true
    end
    return false
end

--- Strip HTML tags and entities

-- =============================================================================
-- CLIPBOARD OPERATIONS
-- =============================================================================

--- Get text from system clipboard
--- @return string|nil Clipboard content or nil if unavailable
local function get_clipboard()
    if reaper.CF_GetClipboard then return reaper.CF_GetClipboard("") end
    local os_name = reaper.GetOS()
    if os_name:match("OSX") or os_name:match("macOS") then
        local f = io.popen("pbpaste", "r")
        if f then local c = f:read("*a"); f:close(); return c end
    else
        local f = io.popen('powershell.exe -command "Get-Clipboard"', "r")
        if f then local c = f:read("*a"); f:close(); return c end
    end
    return nil
end

-- Clipboard Helper (Set)
--- Set system clipboard text
--- @param text string Text to copy to clipboard
local function set_clipboard(text)
    if reaper.CF_SetClipboard then 
        reaper.CF_SetClipboard(text)
        return
    end
    
    local os_name = reaper.GetOS()
    if os_name:match("OSX") or os_name:match("macOS") then
        -- Use pbcopy
        local escaped = text:gsub("'", "'\\''") -- escape single quotes
        io.popen("printf '"..escaped.."' | pbcopy", "w")
    else
        -- Windows clip
        -- Note: 'clip' reads from stdin, but io.popen("clip", "w") might not work as easily with pure Lua write.
        -- Echoing is easier but restricted length. 
        -- Try PowerShell Set-Clipboard
        local escaped = text:gsub('"', '\\"')
        io.popen('powershell.exe -command "Set-Clipboard -Value \\"' .. escaped .. '\\""', "w")
    end
end

--- Format seconds to timestamp string (HH:MM:SS.mmm or MM:SS.mmm)
--- @param seconds number Time in seconds
--- @return string Formatted timestamp
local function format_timestamp(seconds)
    local s = math.floor(seconds)
    local ms = math.floor((seconds - s) * 1000)
    
    local hours = math.floor(s / 3600)
    local minutes = math.floor((s % 3600) / 60)
    local secs = s % 60
    
    if hours > 0 then
        return string.format("%d:%02d:%02d.%03d", hours, minutes, secs, ms)
    else
        return string.format("%02d:%02d.%03d", minutes, secs, ms)
    end
end

-- =============================================================================
-- RICH TEXT PARSING
-- =============================================================================
-- Format: { {text="foo", b=true, i=false, u=false, s=false}, ... }
-- Supports splitting lines by \N or \n

--- Smart text wrapping at natural break points (with cache)
--- @param text string Text to wrap
--- @param max_length number Maximum line length
--- @return string Wrapped text
local wrap_cache = {}
local function wrap_long_text(text, max_length)
    -- Ignore tags for length calculation
    local clean_for_len = text:gsub("{.-}", "")
    local len = utf8.len(clean_for_len) or #clean_for_len
    if len <= max_length then return text end
    
    -- Check cache
    local cache_key = text .. "|" .. max_length
    if wrap_cache[cache_key] then
        return wrap_cache[cache_key]
    end
    
    local result = ""
    local current_line = ""
    local current_line_len = 0
    
    -- Split by space but preserve it
    for word in text:gmatch("%S+") do
        local clean_word = word:gsub("{.-}", "")
        local word_len = utf8.len(clean_word) or #clean_word
        
        if current_line == "" then
            current_line = word
            current_line_len = word_len
        else
            if current_line_len + 1 + word_len > max_length then
                result = result .. (result == "" and "" or "\\N") .. current_line
                current_line = word
                current_line_len = word_len
            else
                current_line = current_line .. " " .. word
                current_line_len = current_line_len + 1 + word_len
            end
        end
    end
    
    if current_line ~= "" then
        result = result .. (result == "" and "" or "\\N") .. current_line
    end
    
    -- Store in cache (limit cache size to prevent memory issues)
    if #wrap_cache > 100 then
        wrap_cache = {} -- Clear cache if too large
    end
    wrap_cache[cache_key] = result
    
    return result
end

local function parse_rich_text(str)
    local lines = {}
    local current_line = {}
    
    local state = {b=false, i=false, u=false, s=false}
    local cursor = 1
    
    -- Wrap long text first (configurable max length)
    str = wrap_long_text(str, cfg.wrap_length)
    
    -- Normalize newlines
    str = str:gsub("\\n", "\\N"):gsub("\n", "\\N")
    
    while cursor <= #str do
        -- Check for tag start '{', HTML '<', or newline '\N'
        local tag_start = str:find("[{<\\]", cursor)
        
        if not tag_start then
            -- Rest is text
            local remainder = str:sub(cursor)
            if remainder ~= "" then
                table.insert(current_line, {text=remainder, b=state.b, i=state.i, u=state.u, s=state.s})
            end
            break
        end
        
        -- Append text before tag
        if tag_start > cursor then
            local segment = str:sub(cursor, tag_start - 1)
            table.insert(current_line, {text=segment, b=state.b, i=state.i, u=state.u, s=state.s})
        end
        
        -- Handle Newline
        if str:sub(tag_start, tag_start+1) == "\\N" then
            table.insert(lines, current_line)
            current_line = {}
            cursor = tag_start + 2
            
        elseif str:sub(tag_start, tag_start) == "{" then
            -- Handle ASS Tag
            local tag_end = str:find("}", tag_start)
            if tag_end then
                local content = str:sub(tag_start+1, tag_end-1)
                -- Parse supported tags
                -- \b1, \b0, \i1, \u1, \s1
                for tag in content:gmatch("\\[bius]%d") do
                    local t = tag:sub(2,2)
                    local v = (tag:sub(3,3) == "1")
                    if t == "b" then state.b = v
                    elseif t == "i" then state.i = v
                    elseif t == "u" then state.u = v
                    elseif t == "s" then state.s = v
                    end
                end
                cursor = tag_end + 1
            else
                -- Broken tag
                table.insert(current_line, {text="{", b=state.b, i=state.i, u=state.u, s=state.s})
                cursor = tag_start + 1
            end
            
        elseif str:sub(tag_start, tag_start) == "<" then
            -- Handle HTML Tag
            local tag_end = str:find(">", tag_start)
            if tag_end then
                local content = str:sub(tag_start+1, tag_end-1):lower()
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
                -- Broken tag, treat as text
                table.insert(current_line, {text="<", b=state.b, i=state.i, u=state.u, s=state.s})
                cursor = tag_start + 1
            end
        else
            -- Should not happen unless pattern matches backslash alone not followed by N?
            -- Treat as text
            table.insert(current_line, {text=str:sub(tag_start, tag_start), b=state.b, i=state.i, u=state.u, s=state.s})
            cursor = tag_start + 1
        end
    end
    
    if #current_line > 0 then
        table.insert(lines, current_line)
    elseif #lines == 0 then
        -- Empty string
        table.insert(lines, {})
    end
    
    return lines
end

--- Fit text to width by truncating with ellipsis
--- @param str string Text to fit
--- @param max_w number Maximum width in pixels
--- @return string Fitted text
local function fit_text_width(str, max_w)
    if gfx.measurestr(str) <= max_w then return str end
    
    local len = #str
    while len > 0 do
        local sub = str:sub(1, len) .. "..."
        if gfx.measurestr(sub) <= max_w then return sub end
        len = len - 1
    end
    return "..."
end

-- Serialization Helpers
local function serialize_table(val, name, skipnewlines, depth)
    skipnewlines = skipnewlines or false
    depth = depth or 0
    local tmp = string.rep(" ", depth)
    if name then tmp = tmp .. name .. " = " end
    if type(val) == "table" then
        tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")
        for k, v in pairs(val) do
            tmp =  tmp .. serialize_table(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
        end
        tmp = tmp .. string.rep(" ", depth) .. "}"
    elseif type(val) == "number" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    elseif type(val) == "boolean" then
        tmp = tmp .. (val and "true" or "false")
    else
        tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
    end
    return tmp
end

-- =============================================================================
-- PROJECT DATA PERSISTENCE
-- =============================================================================

--- Save subtitle data to project extended state
local function save_project_data()
    -- Create a simplified structure to save
    local data = {
        lines = ass_lines,
        actors = ass_actors,
        loaded = ass_file_loaded,
        fname = current_file_name
    }

    -- Using a very compact string format: t1|t2|actor|enabled|text\n
    local dump = ""
    for i, l in ipairs(ass_lines) do
        local en = (l.enabled == nil or l.enabled) and "1" or "0"
        local r_idx = l.rgn_idx or -1
        local index = l.index or i
        dump = dump .. string.format("%.3f|%.3f|%s|%s|%d|%d|%s\n", l.t1, l.t2, l.actor, en, r_idx, index, l.text:gsub("\n","\\n"))
    end
    reaper.SetProjExtState(0, section_name, "ass_lines", dump)
    
    local act_dump = ""
    for k,v in pairs(ass_actors) do
        act_dump = act_dump .. k .. "|" .. (v and "1" or "0") .. "\n"
    end
    reaper.SetProjExtState(0, section_name, "ass_actors", act_dump)
    
    local col_dump = ""
    for k,v in pairs(actor_colors) do
        col_dump = col_dump .. k .. "|" .. tostring(v) .. "\n"
    end
    reaper.SetProjExtState(0, section_name, "actor_colors", col_dump)

    reaper.SetProjExtState(0, section_name, "ass_loaded", ass_file_loaded and "1" or "0")
    if current_file_name then
        reaper.SetProjExtState(0, section_name, "ass_fname", current_file_name)
    end
end

--- Load project data from ProjectExtState
local function load_project_data()
    -- ALWAYS reset state first
    ass_lines = {}
    ass_actors = {}
    actor_colors = {}
    ass_file_loaded = false
    current_file_name = nil
    
    local ok, loaded = reaper.GetProjExtState(0, section_name, "ass_loaded")
    if ok and loaded == "1" then
        ass_file_loaded = true
        
        local okF, fname = reaper.GetProjExtState(0, section_name, "ass_fname")
        if okF then current_file_name = fname end
        
        local ok2, l_dump = reaper.GetProjExtState(0, section_name, "ass_lines")
        if ok2 then
            for line in l_dump:gmatch("([^\n]*)\n?") do
                if line ~= "" then
                    -- Try new sync format: t1|t2|actor|enabled|rgn_idx|index|text
                    local t1, t2, act, en, r_idx, idx, txt = line:match("^(.-)|(.-)|(.-)|(.-)|(.-)|(.-)|(.*)$")
                    if t1 and idx then
                        table.insert(ass_lines, {
                            t1 = tonumber(t1),
                            t2 = tonumber(t2),
                            actor = act,
                            enabled = (en == "1"),
                            rgn_idx = tonumber(r_idx),
                            index = tonumber(idx),
                            text = txt:gsub("\\n", "\n")
                        })
                    else
                        -- Try previous sync format: t1|t2|actor|enabled|rgn_idx|text
                        local t1, t2, act, en, r_idx, txt = line:match("^(.-)|(.-)|(.-)|(.-)|(.-)|(.*)$")
                        if t1 and r_idx then
                            table.insert(ass_lines, {
                                t1 = tonumber(t1),
                                t2 = tonumber(t2),
                                actor = act,
                                enabled = (en == "1"),
                                rgn_idx = tonumber(r_idx),
                                text = txt:gsub("\\n", "\n")
                            })
                        else
                            -- Try older format: t1|t2|actor|enabled|text
                            local t1, t2, act, en, txt = line:match("^(.-)|(.-)|(.-)|(.-)|(.*)$")
                            if t1 and en then
                                table.insert(ass_lines, {
                                    t1 = tonumber(t1),
                                    t2 = tonumber(t2),
                                    actor = act,
                                    enabled = (en == "1"),
                                    text = txt:gsub("\\n", "\n")
                                })
                            else
                                -- Fallback: old format t1|t2|actor|text
                                t1, t2, act, txt = line:match("^(.-)|(.-)|(.-)|(.*)$")
                                if t1 then
                                    table.insert(ass_lines, {
                                        t1 = tonumber(t1),
                                        t2 = tonumber(t2),
                                        actor = act,
                                        enabled = true,
                                        text = txt:gsub("\\n", "\n")
                                    })
                                end
                            end
                        end
                    end
                end
            end
        end
        
        local ok3, a_dump = reaper.GetProjExtState(0, section_name, "ass_actors")
        if ok3 then
            for line in a_dump:gmatch("([^\n]*)\n?") do
                if line ~= "" then
                    local act, val = line:match("^(.-)|(.*)$")
                    if act then
                        ass_actors[act] = (val == "1")
                    end
                end
            end
        end
        
        local ok4, c_dump = reaper.GetProjExtState(0, section_name, "actor_colors")
        if ok4 then
            for line in c_dump:gmatch("([^\n]*)\n?") do
                if line ~= "" then
                    local act, col_str = line:match("^(.-)|(.*)$")
                    if act and col_str then
                        actor_colors[act] = tonumber(col_str)
                    end
                end
            end
        end
    end
end
-- LOAD DATA ON STARTUP
load_project_data()

-- =============================================================================
-- REAPER REGIONS MANAGEMENT
-- =============================================================================

-- Helper: Unique Random Color per Actor
--- Get consistent color for an actor (hashing name if not set)
--- @param actor string Actor name
--- @return number Native color integer
local function get_actor_color(actor)
    if not actor or actor == "" or not cfg.random_color_actors then return 0 end
    if actor_colors[actor] then return actor_colors[actor] end
    
    -- Generate random color (but avoid too dark/black)
    -- Simple approach: Random R, G, B
    -- Ensure visible against track background?
    -- Reaper color is int: R | (G<<8) | (B<<16) | 0x1000000(OS specific flags?)
    -- Native Reaper Color: reaper.ColorToNative(r,g,b). 
    -- Marker color adds | 0x1000000 usually.
    
    local r = math.random(50, 255)
    local g = math.random(50, 255)
    local b = math.random(50, 255)
    
    local native_col = reaper.ColorToNative(r, g, b) | 0x1000000
    actor_colors[actor] = native_col
    return native_col
end

--- Sync ass_actors with current ass_lines (Remove actors with 0 replicas)
--- Identify used actors and remove unused ones from list
local function cleanup_actors()
    if not ass_lines then return end
    
    local current_actors = {}
    for _, line in ipairs(ass_lines) do
        if line.actor then
            current_actors[line.actor] = true
        end
    end
    
    -- Remove actors from ass_actors if they are no longer in any line
    for act in pairs(ass_actors) do
        if not current_actors[act] then
            ass_actors[act] = nil
            -- Also cleanup color if exists
            if actor_colors then actor_colors[act] = nil end
        end
    end
end

--- Find the highest current region index and return next available
local function get_next_line_index()
    if not ass_lines then return 1 end
    local max_idx = 0
    for _, l in ipairs(ass_lines) do
        if l.index and l.index > max_idx then max_idx = l.index end
    end
    return max_idx + 1
end

local function update_regions_cache()
    regions = {}
    local retval, num_markers, num_regions = reaper.CountProjectMarkers(0)
    local i = 0
    local rgn_map = {}
    while i < (num_markers + num_regions) do
        local retval, isrgn, pos, rgnend, name, idx = reaper.EnumProjectMarkers(i)
        if isrgn then
            local rgn_obj = {idx = idx, pos = pos, rgnend = rgnend, name = name, rgn_index = i}
            table.insert(regions, rgn_obj)
            rgn_map[idx] = rgn_obj
        end
        i = i + 1
    end
    
    -- Sync internal ass_lines with actual project regions
    if ass_lines and #ass_lines >= 0 then
        local changed = false
        local tracked_rgn_idxs = {}
        local lines_to_remove = {}
        
        -- 1. Sync existing tracked lines and check for deletions
        for i, line in ipairs(ass_lines) do
            if line.rgn_idx then
                local rgn = rgn_map[line.rgn_idx]
                if rgn then
                    -- Update times if changed in REAPER
                    if math.abs(line.t1 - rgn.pos) > 0.0001 or math.abs(line.t2 - rgn.rgnend) > 0.0001 or line.text ~= rgn.name then
                        line.t1 = rgn.pos
                        line.t2 = rgn.rgnend
                        line.text = rgn.name
                        changed = true
                    end
                    tracked_rgn_idxs[line.rgn_idx] = true
                else
                    -- Region was deleted in REAPER manually
                    if line.enabled ~= false then
                        -- If it was enabled but now gone, mark for removal or disable
                        -- We remove it because the user explicitly deleted it from timeline
                        table.insert(lines_to_remove, i)
                        changed = true
                    end
                end
            end
        end
        
        -- Remove lines deleted in REAPER (reverse order to keep indices valid)
        for i = #lines_to_remove, 1, -1 do
            table.remove(ass_lines, lines_to_remove[i])
        end
        
        -- 2. Adopt "foreign" regions (created manually in REAPER)
        for idx, rgn in pairs(rgn_map) do
            if not tracked_rgn_idxs[idx] then
                -- This is a new region! Adopt it.
                if not ass_file_loaded then ass_file_loaded = true end
                
                local new_line = {
                    t1 = rgn.pos,
                    t2 = rgn.rgnend,
                    text = rgn.name,
                    actor = "REAPER",
                    enabled = true,
                    index = get_next_line_index(),
                    rgn_idx = rgn.idx
                }
                table.insert(ass_lines, new_line)
                if ass_actors["REAPER"] == nil then ass_actors["REAPER"] = true end
                changed = true
                tracked_rgn_idxs[idx] = true -- Don't adopt twice
            end
        end
        
        if changed then
            cleanup_actors()
            save_project_data()
        end
    end
end

-- --- INTERNAL UNDO HISTORY ---
local undo_stack = {}
local redo_stack = {}
local max_undo_depth = 20

local function deep_copy_table(t)
    if type(t) ~= 'table' then return t end
    local res = {}
    for k, v in pairs(t) do
        res[deep_copy_table(k)] = deep_copy_table(v)
    end
    return res
end

local function rebuild_regions()
    reaper.PreventUIRefresh(1)
    reaper.Undo_BeginBlock()
    
    -- Fast Delete: Repeatedly delete the first marker until none remain.
    -- This avoids O(N^2) complexity of deleting from end/searching by index.
    local i = 0
    while true do
        local retval, isrgn, pos, rgnend, name, idx = reaper.EnumProjectMarkers(0)
        if not retval or retval == 0 then break end
        reaper.DeleteProjectMarker(0, idx, isrgn)
        
        -- Safety Break (optional but good practice)
        i = i + 1
        if i > 10000 then break end 
    end
    
    -- Add from ass_lines if line is enabled
    local count = 0
    for i, line in ipairs(ass_lines) do
        if line.enabled ~= false then -- Default true if nil
            local col = get_actor_color(line.actor)
            -- If user picked manual color, 'col' should be consistent.
            -- If 'col' is 0, explicitly set?
            if col == 0 and cfg.random_color_actors then
                -- Should already be cached in actor_colors
                 col = get_actor_color(line.actor) 
            end
            
            local target_idx = line.index or i
            local rgn_idx = reaper.AddProjectMarker2(0, true, line.t1, line.t2, line.text, target_idx, col)
            line.rgn_idx = rgn_idx
            count = count + 1
        end
    end
    
    reaper.Undo_EndBlock("Update Synced Regions", -1)
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()

    update_regions_cache() -- Update cache immediately execution
    save_project_data() -- SAVE ON CHANGE
end

local function push_undo(label)
    if not ass_lines then return end
    
    -- Capture state
    local state = {
        lines = deep_copy_table(ass_lines),
        actors = deep_copy_table(ass_actors),
        label = label or "Action"
    }
    
    table.insert(undo_stack, state)
    if #undo_stack > max_undo_depth then
        table.remove(undo_stack, 1)
    end
    
    -- Clear redo stack on new action
    redo_stack = {}
end

local function undo_action()
    if #undo_stack == 0 then return end
    
    -- Save current state to redo stack before restoring
    local current_state = {
        lines = deep_copy_table(ass_lines),
        actors = deep_copy_table(ass_actors),
        label = undo_stack[#undo_stack].label
    }
    
    local last_state = table.remove(undo_stack)
    
    table.insert(redo_stack, current_state)
    if #redo_stack > max_undo_depth then
        table.remove(redo_stack, 1)
    end

    ass_lines = last_state.lines
    ass_actors = last_state.actors
    
    cleanup_actors()
    rebuild_regions()
    show_snackbar("Відмінено: " .. last_state.label)
end

local function redo_action()
    if #redo_stack == 0 then return end
    
    local next_state = table.remove(redo_stack)
    
    -- Save current state back to undo stack
    local current_state = {
        lines = deep_copy_table(ass_lines),
        actors = deep_copy_table(ass_actors),
        label = next_state.label
    }
    
    table.insert(undo_stack, current_state)
    if #undo_stack > max_undo_depth then
        table.remove(undo_stack, 1)
    end

    ass_lines = next_state.lines
    ass_actors = next_state.actors
    
    cleanup_actors()
    rebuild_regions()
    show_snackbar("Повторено: " .. next_state.label)
end

-- =============================================================================
-- FILE IMPORT (SRT/ASS)
-- =============================================================================

--- Import SRT subtitle file
local function import_srt(file_path)
    local file = file_path
    if not file then
        local retval
        retval, file = reaper.GetUserFileNameForRead("", "Import SRT", "srt")
        if not retval then return end
    end
    local f = io.open(file, "r")
    if not f then return end
    current_file_name = file:match("([^/\\]+)$")
    
    local content = f:read("*all")
    f:close()
    content = content:gsub("\r\n", "\n")
    
    -- Derive Actor Name from Filename
    local actor_name = current_file_name:gsub("%.srt$", ""):gsub("%.SRT$", "")
    
    -- Ensure State Init (Additive)
    if not ass_lines then ass_lines = {} end
    if not ass_actors then ass_actors = {} end
    ass_file_loaded = true -- Enable Actor view

    -- Clear UI state
    table_filter_state.text = ""
    table_selection = {}
    last_selected_row = nil
    
    -- Register Actor
    ass_actors[actor_name] = true
    
    -- We will rebuild ALL regions at the end, so we don't need to add markers manually here.
    -- Just populate ass_lines.
    local line_idx_counter = 1
    
    for s_start, s_end, text in content:gmatch("(%d%d:%d%d:%d%d,%d%d%d) %-%-> (%d%d:%d%d:%d%d,%d%d%d)\n(.-)\n\n") do
        local t1 = parse_timestamp(s_start)
        local t2 = parse_timestamp(s_end)
        
        local lines_processed = false
        
        -- Logic: If auto-split enabled, iterate lines
        if cfg.auto_srt_split == "():" or cfg.auto_srt_split == "[]:" then
            local lines_list = {}
            for l in (text.."\n"):gmatch("(.-)\n") do 
                -- Trim carriage returns just in case
                l = l:gsub("\r", "")
                if l ~= "" then table.insert(lines_list, l) end 
            end
            
            if #lines_list > 0 then
                lines_processed = true
                
                local current_block_actor = actor_name
                local segments = {} -- { {actor=A, text=T} }

                for _, line_txt in ipairs(lines_list) do
                    local found_act, found_txt
                    
                    if cfg.auto_srt_split == "():" then
                        -- Check for prefix before actor
                        local pre, act, post = line_txt:match("^(.-)%s*%(%s*(.-)%s*%):%s*(.*)")
                        if act then 
                            found_act = act
                            found_txt = (pre ~= "" and (pre .. " ") or "") .. post
                        end
                    elseif cfg.auto_srt_split == "[]:" then
                        local pre, act, post = line_txt:match("^(.-)%s*%[%s*(.-)%s*%]:%s*(.*)")
                        if act then
                            found_act = act
                            found_txt = (pre ~= "" and (pre .. " ") or "") .. post
                        end
                    end
                    
                    if found_act then
                        -- New actor detected
                        current_block_actor = found_act
                        -- Register
                        if not ass_actors[current_block_actor] then ass_actors[current_block_actor] = true end
                        
                        -- Add new segment
                        table.insert(segments, {actor=current_block_actor, text=found_txt})
                    else
                        -- No actor detected -> continuation or start of default
                        if #segments > 0 then
                            -- Append to last segment
                            local last = segments[#segments]
                            if last.text == "" then
                                last.text = line_txt
                            else
                                last.text = last.text .. "\n" .. line_txt
                            end
                        else
                            -- First line has no actor -> use filename actor (current_block_actor)
                            table.insert(segments, {actor=current_block_actor, text=line_txt})
                        end
                    end
                end
                
                -- Push segments
                for _, seg in ipairs(segments) do
                    table.insert(ass_lines, {
                        t1 = t1,
                        t2 = t2,
                        text = seg.text,
                        actor = seg.actor,
                        enabled = true,
                        index = line_idx_counter
                    })
                    line_idx_counter = line_idx_counter + 1
                end
            end
        end
        
        -- Fallback: If not processed (not split mode or empty text resulted in 0 lines?), 
        -- logic above handles >0 lines. If text is empty/whitespace, lines_list might be empty.
        -- Original code allowed text. If text was just newlines, it would be inserted.
        -- Check if we should insert the original block if lines_processed is false.
        if not lines_processed then
            table.insert(ass_lines, {
                t1 = t1,
                t2 = t2,
                text = text,
                actor = actor_name,
                enabled = true,
                index = line_idx_counter
            })
            line_idx_counter = line_idx_counter + 1
        end
    end
    
    rebuild_regions() -- This handles clearing old regions and re-adding all (including new ones)
end

--- Parse VTT timestamp format (HH:MM:SS.mmm or MM:SS.mmm)
--- @param str string Timestamp string
--- @return number Time in seconds
local function parse_vtt_timestamp(str)
    local h, m, s, ms = str:match("(%d+):(%d+):(%d+)%.(%d+)")
    if h then
        return (tonumber(h) * 3600) + (tonumber(m) * 60) + tonumber(s) + (tonumber(ms) / 1000)
    end
    -- Try MM:SS.mmm format
    m, s, ms = str:match("(%d+):(%d+)%.(%d+)")
    if m then
        return (tonumber(m) * 60) + tonumber(s) + (tonumber(ms) / 1000)
    end
    return 0
end

--- Import VTT subtitle file
--- @param file_path string|nil Absolute path to file or nil to prompt user
local function import_vtt(file_path)
    local file = file_path
    if not file then
        local retval
        retval, file = reaper.GetUserFileNameForRead("", "Import VTT", "vtt")
        if not retval then return end
    end
    local f = io.open(file, "r")
    if not f then return end
    current_file_name = file:match("([^/\\]+)$")
    
    local content = f:read("*all")
    f:close()
    content = content:gsub("\r\n", "\n")
    
    -- Derive Actor Name from Filename
    local actor_name = current_file_name:gsub("%.vtt$", ""):gsub("%.VTT$", "")
    
    -- Ensure State Init (Additive)
    if not ass_lines then ass_lines = {} end
    if not ass_actors then ass_actors = {} end
    ass_file_loaded = true

    -- Clear UI state
    table_filter_state.text = ""
    table_selection = {}
    last_selected_row = nil
    
    -- Register Actor
    ass_actors[actor_name] = true
    
    local line_idx_counter = 1
    
    -- VTT format: timestamp --> timestamp followed by text
    -- Skip WEBVTT header and optional metadata
    for s_start, s_end, text in content:gmatch("(%d[%d:%.]+) %-%-> (%d[%d:%.]+)[^\n]*\n(.-)\n\n") do
        local t1 = parse_vtt_timestamp(s_start)
        local t2 = parse_vtt_timestamp(s_end)
        
        -- Remove VTT tags like <v Name> or <c.classname>
        text = text:gsub("<[^>]+>", "")
        
        table.insert(ass_lines, {
            t1 = t1,
            t2 = t2,
            text = text,
            actor = actor_name,
            enabled = true,
            index = line_idx_counter
        })
        line_idx_counter = line_idx_counter + 1
    end
    
    rebuild_regions()
end

--- Parse timestamp in various formats to seconds
--- Supports: MM:SS, M:SS, MM.SS, HH:MM:SS, HH:MM:SS.mmm, MM:SS.mmm, HH.MM.SS
--- @param str string Timestamp string
--- @return number|nil Time in seconds or nil if invalid
local function parse_notes_timestamp(str)
    -- Try HH:MM:SS.mmm format
    local h, m, s, ms = str:match("^(%d+):(%d+):(%d+)%.(%d+)$")
    if h then
        return (tonumber(h) * 3600) + (tonumber(m) * 60) + tonumber(s) + (tonumber(ms) / 1000)
    end
    
    -- Try MM:SS.mmm format (without hours)
    m, s, ms = str:match("^(%d+):(%d+)%.(%d+)$")
    if m then
        return (tonumber(m) * 60) + tonumber(s) + (tonumber(ms) / 1000)
    end
    
    -- Try HH:MM:SS format
    h, m, s = str:match("^(%d+):(%d+):(%d+)$")
    if h then
        return (tonumber(h) * 3600) + (tonumber(m) * 60) + tonumber(s)
    end
    
    -- Try HH.MM.SS format (dots instead of colons)
    h, m, s = str:match("^(%d+)%.(%d+)%.(%d+)$")
    if h then
        return (tonumber(h) * 3600) + (tonumber(m) * 60) + tonumber(s)
    end
    
    -- Try MM:SS format
    m, s = str:match("^(%d+):(%d+)$")
    if m then
        return (tonumber(m) * 60) + tonumber(s)
    end
    
    -- Try MM.SS format (dots instead of colons)
    m, s = str:match("^(%d+)%.(%d+)$")
    if m then
        return (tonumber(m) * 60) + tonumber(s)
    end
    
    return nil
end

--- Import director notes from text format and create markers
local function import_notes()
    -- Show instruction dialog
    local response = reaper.ShowMessageBox(
        "Скопіюйте список правок у буфер обміну і натисніть OK.\n\n" ..
        "Підтримувані формати:\n" ..
        "• MM:SS - текст\n" ..
        "• MM:SS - MM:SS - текст (діапазон)\n" ..
        "• #N - текст (індекс регіону)\n" ..
        "• Багаторядковий текст",
        "Імпорт правок",
        1  -- OK/Cancel
    )

    if response ~= 1 then return end
    
    -- Read from clipboard
    local input = get_clipboard()
    if not input or input == "" then
        show_snackbar("Буфер обміну порожній")
        return
    end
    
    -- Parse input
    local notes = {}
    local failed_lines = {} -- Track lines that couldn't be parsed
    
    for line in input:gmatch("[^\r\n]+") do
        line = line:match("^%s*(.-)%s*$") -- Trim
        if line ~= "" then
            local matched = false
            
            -- Check if line starts with timestamp or # (new entry)
            -- If not, it's a continuation of previous note
            local is_continuation = not line:match("^[#%d]")
            
            if is_continuation and #notes > 0 then
                -- Append to last note's text
                notes[#notes].text = notes[#notes].text .. "\n" .. line
                matched = true
            else
                -- Try region index format first: #N - text
                local region_idx, note_text = line:match("^#(%d+)%s*%-%s*(.+)$")
                if region_idx then
                    region_idx = tonumber(region_idx)
                    
                    -- Find region by index in ass_lines
                    local found = false
                    if ass_lines then
                        for _, ass_line in ipairs(ass_lines) do
                            if ass_line.index == region_idx then
                                table.insert(notes, {time = ass_line.t1, text = note_text})
                                found = true
                                matched = true
                                break
                            end
                        end
                    end
                    
                    if not found then
                        table.insert(failed_lines, line)
                    end
                else
                    -- More precise timestamp pattern that doesn't capture text
                    -- Match: digits, then colons/dots with digits, ending before " - "
                    -- Examples: 2:26, 02:38.080, 1:2:26, 2.30
                    
                    -- Try to match time range format: TIME - TIME - text
                    -- Pattern: capture timestamp, space-dash-space, another timestamp, space-dash-space, then text
                    local time1_str, time2_str, note_text = line:match("^([%d:.]+)%s*%-%s*([%d:.]+)%s*%-%s*(.+)$")
                    
                    if time1_str and time2_str and note_text then
                        -- Time range format: create marker at first time with end time in text
                        local time1 = parse_notes_timestamp(time1_str)
                        local time2 = parse_notes_timestamp(time2_str)
                        if time1 and time2 then
                            local full_text = string.format("аж до %s - %s", time2_str, note_text)
                            table.insert(notes, {time = time1, text = full_text})
                            matched = true
                        else
                            table.insert(failed_lines, line)
                        end
                    else
                        -- Try single time format: TIME - text
                        time1_str, note_text = line:match("^([%d:.]+)%s*%-%s*(.+)$")
                        if time1_str and note_text then
                            local time = parse_notes_timestamp(time1_str)
                            if time then
                                table.insert(notes, {time = time, text = note_text})
                                matched = true
                            else
                                table.insert(failed_lines, line)
                            end
                        else
                            table.insert(failed_lines, line)
                        end
                    end
                end
            end
        end
    end

    if #notes == 0 then
        show_snackbar("Не знайдено жодної правки у правильному форматі")
        return
    end
    
    -- Show warning if some lines failed to parse
    if #failed_lines > 0 then
        local warning_msg = string.format("⚠️ Не вдалося розпізнати %d рядків:\n\n", #failed_lines)
        for i, failed_line in ipairs(failed_lines) do
            if i <= 10 then -- Show max 10 failed lines
                warning_msg = warning_msg .. "• " .. failed_line .. "\n"
            end
        end
        if #failed_lines > 10 then
            warning_msg = warning_msg .. string.format("\n... та ще %d рядків", #failed_lines - 10)
        end
        warning_msg = warning_msg .. "\n\nПродовжити створення маркерів для розпізнаних рядків?"
        
        local response = reaper.ShowMessageBox(warning_msg, "Попередження", 4) -- 4 = Yes/No
        if response ~= 6 then -- 6 = Yes
            return
        end
    end
    
    -- Create markers
    push_undo("Імпорт правок")
    
    reaper.PreventUIRefresh(1)
    for _, note in ipairs(notes) do
        -- Always create marker (not region)
        reaper.AddProjectMarker2(0, false, note.time, 0, note.text, -1, reaper.ColorToNative(255, 200, 100) | 0x1000000)
    end
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    
    show_snackbar("Створено маркерів: " .. #notes)
end

--- Import director notes from CSV file and create markers
--- CSV format: #,Name,Start
--- @param file_path string|nil Optional file path, if nil shows file dialog
local function import_notes_from_csv(file_path)
    local file = file_path
    if not file then
        local retval
        retval, file = reaper.GetUserFileNameForRead("", "Імпорт правок з CSV", "*.csv")
        if not retval or not file then return end
    end
    
    local f = io.open(file, "r")
    if not f then
        show_snackbar("Не вдалося відкрити файл")
        return
    end
    
    local content = f:read("*all")
    f:close()
    
    -- Parse CSV
    local notes = {}
    local line_num = 0
    
    for line in content:gmatch("[^\r\n]+") do
        line_num = line_num + 1
        line = line:match("^%s*(.-)%s*$") -- Trim

        -- Skip header line and empty lines
        if line ~= "" and not line:match("^#,Name,Start") then
            -- Parse CSV with proper quote handling
            -- Format: M1,"text with, commas",80.3.00,FFC864
            -- or: M1,simple text,0:40.273
            
            local parts = {}
            local current = ""
            local in_quotes = false
            local i = 1
            
            while i <= #line do
                local char = line:sub(i, i)
                
                if char == '"' then
                    -- Check for escaped quote ""
                    if i < #line and line:sub(i+1, i+1) == '"' then
                        current = current .. '"'
                        i = i + 1
                    else
                        in_quotes = not in_quotes
                    end
                elseif char == ',' and not in_quotes then
                    table.insert(parts, current)
                    current = ""
                else
                    current = current .. char
                end
                
                i = i + 1
            end
            table.insert(parts, current) -- Add last part
            
            if #parts >= 3 then
                -- parts[1] = ID (M1, M2, etc)
                -- parts[2] = Name (text)
                -- parts[3] = Start (time)
                -- parts[4] = Color (optional)
                
                local name = parts[2]
                local time_str = parts[3]
                
                -- Parse REAPER time format: seconds.frames.subframes (e.g., 80.3.00)
                -- Or standard format: MM:SS.mmm
                local time
                
                -- Try REAPER format first (NNN.F.SS)
                local sec, frames = time_str:match("^(%d+)%.%d+%.%d+$")
                if sec then
                    time = tonumber(sec)
                else
                    -- Try standard timestamp formats
                    time = parse_notes_timestamp(time_str)
                end
                
                if time and name then
                    table.insert(notes, {time = time, text = name})
                end
            end
        end
    end
    
    if #notes == 0 then
        show_snackbar("Не знайдено жодного маркера у файлі")
        return
    end
    
    -- Create markers
    push_undo("Імпорт правок з CSV")
    
    reaper.PreventUIRefresh(1)
    for _, note in ipairs(notes) do
        reaper.AddProjectMarker2(0, false, note.time, 0, note.text, -1, reaper.ColorToNative(255, 200, 100) | 0x1000000)
    end
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    
    show_snackbar("Створено маркерів: " .. #notes)
end

--- Import ASS/SSA subtitle file, parsing styles and events
--- @param file_path string|nil Absolute path to file or nil to prompt user
local function import_ass(file_path)
    local file = file_path
    if not file then
        local retval
        retval, file = reaper.GetUserFileNameForRead("", "Import ASS", "ass")
        if not retval then return end
    end
    local f = io.open(file, "r")
    if not f then return end
    current_file_name = file:match("([^/\\]+)$")
    
    local content = f:read("*all")
    f:close()
    
    content = content:gsub("\r\n", "\n")
    
    -- Reset Cache
    ass_lines = {}
    ass_actors = {}
    ass_file_loaded = true
    local line_idx_counter = 1
    
    -- Clear UI state
    table_filter_state.text = ""
    table_selection = {}
    last_selected_row = nil
    
    local in_events = false
    local format_def = nil
    
    for line in content:gmatch("([^\n]*)\n?") do
        if line:match("^%[Events%]") then in_events = true 
        elseif line:match("^%[.*%]") then in_events = false end
        
        if in_events then
            if line:match("^Format:") then
                format_def = {}
                local fmt_str = line:match("^Format:%s*(.*)")
                local idx = 1
                for field in fmt_str:gmatch("([^,]+)") do
                    field = field:match("^%s*(.-)%s*$")
                    format_def[field] = idx
                    idx = idx + 1
                end
            elseif line:match("^Dialogue:") and format_def then
                local body = line:match("^Dialogue:%s*(.*)")
                local fields = {}
                local current_idx = 1
                local max_idx = 0
                for _ in pairs(format_def) do max_idx = max_idx + 1 end
                
                local search_start = 1
                while current_idx < max_idx do
                    local comma_pos = body:find(",", search_start)
                    if not comma_pos then break end
                    table.insert(fields, body:sub(search_start, comma_pos - 1))
                    search_start = comma_pos + 1
                    current_idx = current_idx + 1
                end
                table.insert(fields, body:sub(search_start))
                
                local i_start = format_def["Start"]
                local i_end = format_def["End"]
                local i_text = format_def["Text"]
                local i_name = format_def["Name"] or format_def["Actor"] -- Usually "Name" in ASS
                
                if i_start and i_end and i_text then
                    local t1 = parse_ass_timestamp(fields[i_start])
                    local t2 = parse_ass_timestamp(fields[i_end])
                    local text = fields[i_text]
                    local actor = i_name and fields[i_name] or "Unknown"
                    actor = actor:match("^%s*(.-)%s*$") -- Clean
                    if actor == "" then actor = "Unknown" end

                    text = text:gsub("\\N", "\n"):gsub("\\n", "\n")
                    
                    table.insert(ass_lines, {
                        t1=t1, t2=t2, text=text, actor=actor, enabled=true,
                        index = line_idx_counter
                    })
                    line_idx_counter = line_idx_counter + 1
                    
                    if ass_actors[actor] == nil then ass_actors[actor] = true end
                end
            end
        end
    end

    -- reset Undo/Redo Stacks
    undo_stack = {}
    redo_stack = {}

    -- Initial Build
    update_regions_cache() 
    rebuild_regions() -- This calls save_project_data
end

-- =============================================================================
-- STRESS MARKS (UKRAINIAN ACCENT MARKS)
-- =============================================================================

--- Apply stress marks from dictionary file to all subtitles
local function apply_stress_marks_coroutine()
    script_loading_state.active = true
    script_loading_state.text = "Ініціалізація..."
    coroutine.yield()

    -- OS Detection
    local os_name = reaper.GetOS()
    local is_windows = os_name:match("Win") ~= nil

    -- 1. Locate script directory
    local function get_actual_script_path()
        local info = debug.getinfo(1, "S")
        local path = info.source
        if path:sub(1, 1) == "@" then path = path:sub(2) end
        -- Handle both Windows and Unix paths
        local dir = path:match("(.*[\\/])")
        if not dir then dir = reaper.GetResourcePath() .. "/Scripts/" end
        return dir
    end
    
    local script_path = get_actual_script_path()
    
    local python_tool = script_path .. "ukrainian_stress_tool.py"
    local has_python_tool = false
    local f_tool, err_tool = io.open(python_tool, "r")
    if f_tool then
        has_python_tool = true
        f_tool:close()
    end

    local changed_lines = 0
    local python_success = false
    local ai_error_type = nil -- "PERMISSION", "VERSION", "DEPENDENCY", "UNKNOWN"
    local di_error_type = nil -- "PERMISSION", "MISSING"
    if has_python_tool then
        script_loading_state.text = "Використання AI-наголосів..."
        coroutine.yield()

        local temp_in = script_path .. "temp_stress_in.srt"
        local temp_out = script_path .. "temp_stress_out.srt"
        
        os.remove(temp_out) -- Remove old result if exists
        
        local f_in = io.open(temp_in, "w")
        if f_in then
            local export_count = 0
            for i, line in ipairs(ass_lines) do
                if ass_actors[line.actor] then
                    export_count = export_count + 1
                    f_in:write(export_count .. "\n")
                    f_in:write("00:00:00,000 --> 00:00:01,000\n")
                    f_in:write(line.text:gsub("\n", "\n") .. "\n\n")
                end
            end
            f_in:close()

            if export_count > 0 then
                local log_file = script_path .. "stress_debug.log"
                local python_cmd = "python3"
                local tool_p = python_tool
                local in_p = temp_in
                local out_p = temp_out
                
                if is_windows then 
                    -- Check if python command exists on Windows
                    if not os.execute("where python >nul 2>nul") then 
                        ai_error_type = "PYTHON_MISSING"
                    else
                        python_cmd = "python"
                        tool_p = tool_p:gsub("/", "\\")
                        in_p = in_p:gsub("/", "\\")
                        out_p = out_p:gsub("/", "\\")
                        log_file = log_file:gsub("/", "\\")
                        
                        local cmd = string.format('%s "%s" "%s" -o "%s" > "%s" 2>&1', python_cmd, tool_p, in_p, out_p, log_file)
                        os.execute('start /B "" cmd /c ' .. cmd)
                    end
                else
                    -- On macOS/Linux, try to find the full path to python3
                    local p_handle = io.popen("which python3")
                    if p_handle then
                        local found_path = p_handle:read("*l")
                        p_handle:close()
                        if found_path and found_path ~= "" then
                            python_cmd = found_path
                        end
                    end
                    
                    -- Verify python executable
                    if not os.execute(string.format('command -v "%s" >/dev/null 2>&1', python_cmd)) then
                        ai_error_type = "PYTHON_MISSING"
                    else
                        local cmd = string.format('"%s" "%s" "%s" -o "%s" > "%s" 2>&1', python_cmd, tool_p, in_p, out_p, log_file)
                        os.execute(cmd .. " &")
                    end
                end
                
                -- Polling Loop (Non-blocking wait)
                local start_time = os.clock()
                local timeout = 120 -- 2 minutes for model loading/processing
                local success = false
                
                if not ai_error_type then
                    while os.clock() - start_time < timeout do
                        local f_check = io.open(temp_out, "r")
                        if f_check then
                            local head = f_check:read(10)
                            f_check:close()
                            if head and head ~= "" then
                                success = true
                                break
                            end
                        end
                        
                        local elapsed = math.floor(os.clock() - start_time)
                        script_loading_state.text = "AI-наголоси (" .. elapsed .. "с)..."
                        coroutine.yield()
                    end
                    if not success then ai_error_type = "TIMEOUT" end
                end
                
                if success then
                    local f_out = io.open(temp_out, "r")
                    if f_out then
                        local content = f_out:read("*all")
                        f_out:close()
                    
                        local stressed_texts = {}
                        local current_text = ""
                        local state = 0 -- 0: Index, 1: Time, 2: Text
                        for l in (content .. "\n"):gmatch("(.-)\r?\n") do
                            l = l:match("^%s*(.-)%s*$") or l -- Trim whitespace
                            if state == 0 then
                                if l:match("^%d+$") then state = 1 end
                            elseif state == 1 then
                                if l:match("%-%->") then 
                                    state = 2 
                                    current_text = "" 
                                end
                            elseif state == 2 then
                                if l == "" then
                                    if current_text ~= "" then
                                        table.insert(stressed_texts, current_text:sub(1,-2))
                                    end
                                    state = 0
                                else
                                    current_text = current_text .. l .. "\n"
                                end
                            end
                        end
                        -- Force add last block if file didn't end with empty line
                        if state == 2 and current_text ~= "" then
                            table.insert(stressed_texts, current_text:sub(1,-2))
                        end
                        
                        if #stressed_texts == export_count then
                            local ptr = 1
                            for i, line in ipairs(ass_lines) do
                                if ass_actors[line.actor] then
                                    if line.text ~= stressed_texts[ptr] then
                                        line.text = stressed_texts[ptr]
                                        changed_lines = changed_lines + 1
                                    end
                                    ptr = ptr + 1
                                end
                            end
                            python_success = true
                        else
                            reaper.ShowConsoleMsg(string.format("Warning: AI results count mismatch. Expected %d, got %d.\n", export_count, #stressed_texts))
                        end
                        os.remove(temp_out)
                    end
                else
                    -- Check log file for specific errors
                    local f_log = io.open(log_file, "r")
                    if f_log then
                        local logs = f_log:read("*all")
                        f_log:close()
                        
                        if logs:find("PYTHON_VERSION_TOO_OLD") then
                            ai_error_type = "VERSION"
                        elseif logs:find("DEPENDENCY_INSTALL_FAILED") then
                            ai_error_type = "DEPENDENCY"
                        elseif logs:find("Operation not permitted") or logs:find("Access is denied") then
                            ai_error_type = "PERMISSION"
                        else
                            ai_error_type = "UNKNOWN"
                        end
                        reaper.ShowConsoleMsg("AI Tool Failure Info:\n" .. logs .. "\n")
                    end
                end
                os.remove(temp_in)
            end
        else
            if err_tool and (err_tool:find("not permitted") or err_tool:find("Access is denied")) then
                ai_error_type = "PERMISSION"
            end
        end
    end

    -- --- STRATEGY 2: MANUAL DICTIONARY (FALLBACK) ---
    if not python_success then
        local dict_file = script_path .. "stress_dictionary.txt"
        local f, err_dict = io.open(dict_file, "r")
        if not f then
            if err_dict and (err_dict:find("not permitted") or err_dict:find("Access is denied")) then
                di_error_type = "PERMISSION"
            else
                di_error_type = "MISSING"
            end

            script_loading_state.active = false
            
            local msg = "Жодна стратегія наголосів не спрацювала.\n--------------------------------------------------\n\n"
            
            if ai_error_type == "PERMISSION" or di_error_type == "PERMISSION" then
                if is_windows then
                    msg = msg .. "⚠️ ПОМИЛКА ДОСТУПУ (Windows):\n"
                    msg = msg .. "Антивірус або права доступу блокують роботу з файлами.\n\n"
                    msg = msg .. "ЯК ВИПРАВИТИ:\n"
                    msg = msg .. "1. Спробуйте запустити REAPER від імені Адміністратора.\n"
                    msg = msg .. "2. Додайте папку '" .. script_path .. "' у виключення антивірусу.\n\n"
                else
                    msg = msg .. "⚠️ ПОМИЛКА ДОСТУПУ (macOS Sandbox):\n"
                    msg = msg .. "У REAPER немає прав на читання файлів у цій папці.\n\n"
                    msg = msg .. "ЯК ВИПРАВИТИ:\n"
                    msg = msg .. "1. Відкрийте 'Системні налаштування' -> 'Конфіденційність та безпека'.\n"
                    msg = msg .. "2. Знайдіть 'Повний доступ до диска' (Full Disk Access).\n"
                    msg = msg .. "3. Додайте REAPER до списку та увімкніть перемикач.\n"
                    msg = msg .. "4. ПЕРЕЗАПУСТІТЬ REAPER.\n\n"
                end
            elseif ai_error_type == "PYTHON_MISSING" then
                msg = msg .. "⚠️ PYTHON НЕ ЗНАЙДЕНО:\n"
                if is_windows then
                    msg = msg .. "Python не встановлено або не додано в PATH.\n\n"
                    msg = msg .. "ЯК ВИПРАВИТИ:\n"
                    msg = msg .. "1. Встановіть Python з Microsoft Store (виберіть версію 3.11+).\n"
                    msg = msg .. "2. АБО завантажте інсталятор з python.org і ОБОВ'ЯЗКОВО поставте галочку 'Add Python to PATH' при встановленні.\n\n"
                else
                    msg = msg .. "Команда 'python3' не знайдена.\n\n"
                    msg = msg .. "ЯК ВИПРАВИТИ:\n"
                    msg = msg .. "Встановіть Python 3.9+ з офіційного сайту або через Homebrew: 'brew install python'.\n\n"
                end
            elseif ai_error_type == "VERSION" then
                msg = msg .. "⚠️ СТАРА ВЕРСІЯ PYTHON:\n"
                msg = msg .. "Для роботи AI-наголосів потрібен Python 3.9 або новіше.\n\n"
                if is_windows then
                    msg = msg .. "ЯК ВИПРАВИТИ:\n"
                    msg = msg .. "Оновіть Python (завантажте нову версію 3.11+ з python.org).\n\n"
                else
                    msg = msg .. "ЯК ВИПРАВИТИ:\n"
                    msg = msg .. "Встановіть нову версію через Homebrew: 'brew install python@3.11'\n\n"
                end
            elseif ai_error_type == "DEPENDENCY" then
                msg = msg .. "⚠️ ПОМИЛКА ВСТАНОВЛЕННЯ ЗАЛЕЖНОСТЕЙ:\n"
                msg = msg .. "Не вдалося автоматично встановити 'ukrainian-word-stress'.\n\n"
                msg = msg .. "ЯК ВИПРАВИТИ:\n"
                msg = msg .. "1. Перевірте підключення до інтернету (потрібно для завантаження бібліотек).\n"
                msg = msg .. "2. Спробуйте встановити вручную: відкрийте термінал/CMD і введіть: 'pip install ukrainian-word-stress'\n\n"
            elseif ai_error_type == "TIMEOUT" then
                msg = msg .. "⚠️ ПЕРЕВИЩЕНО ЧАС ОЧІКУВАННЯ (Timeout):\n"
                msg = msg .. "AI-інструмент не встиг обробити текст за 120 секунд.\n\n"
                msg = msg .. "ЯК ВИПРАВИТИ:\n"
                msg = msg .. "1. Якщо це перший запуск — можливо, триває завантаження моделей (залежить від швидкості інтернету). Спробуйте ще раз.\n"
                msg = msg .. "2. Перевірте консоль REAPER (View -> Show console) на наявність помилок.\n\n"
            elseif not has_python_tool then
                msg = msg .. "❌ ФАЙЛ НЕ ЗНАЙДЕНО:\n"
                msg = msg .. "Скрипт не знаходить 'ukrainian_stress_tool.py'.\n"
                msg = msg .. "Переконайтеся, що всі файли плагіна лежать в одній папці.\n\n"
            else
                msg = msg .. "❌ AI-МОДЕЛЬ: Не вдалося отримати результат (див. консоль).\n"
                if di_error_type == "MISSING" then
                    msg = msg .. "❌ СЛОВНИК: Файл '" .. dict_file .. "' не знайдено.\n\n"
                end
            end
            
            msg = msg .. "Шлях до скрипта: " .. script_path
            
            reaper.MB(msg, "Помилка наголосів", 0)
            return
        end

        -- 1.5 Prepare blacklist lookup
        local blacklist_lookup = {}
        if stress_marks_black_list then
            for _, word in ipairs(stress_marks_black_list) do
                blacklist_lookup[utf8_lower(word)] = true
            end
        end
        
        -- 2. Build NEEDED words list
        script_loading_state.text = "Аналіз субтитрів..."
        coroutine.yield()
        local needed_words = {}
        local time_batch_start = os.clock()
        for i, line in ipairs(ass_lines) do
            if ass_actors[line.actor] then
                for word in line.text:gmatch("[%a\128-\255\']+[\128-\255]*") do
                     local lower = utf8_lower(word)
                     if not needed_words[lower] then needed_words[lower] = true end
                end
            end
            if (i % 100 == 0) and (os.clock() - time_batch_start > 0.03) then 
                coroutine.yield()
                time_batch_start = os.clock()
            end
        end
        
        -- 3. Scan Dictionary
        script_loading_state.text = "Сканування словника..."
        coroutine.yield()
        local replacements = {}
        local file_size = f:seek("end")
        f:seek("set", 0)
        time_batch_start = os.clock()
        local chunk_counter = 0
        for line in f:lines() do
            chunk_counter = chunk_counter + 1
            if chunk_counter % 2000 == 0 then
                if os.clock() - time_batch_start > 0.03 then
                    local cur_pos = f:seek("cur")
                    local pct = math.floor((cur_pos / file_size) * 100)
                    script_loading_state.text = "AI-наголоси НЕ СПРАЦЮВАЛИ !!!, застосовую наголосів через словник: " .. pct .. "%"
                    coroutine.yield()
                    time_batch_start = os.clock()
                end
            end
            line = line:match("^%s*(.-)%s*$")
            if line ~= "" then
                local key = line:gsub(acute, "")
                key = utf8_lower(key)
                if needed_words[key] and not replacements[key] then
                    replacements[key] = line
                end
            end
        end
        f:close()
        
        -- 4. Apply Replacements
        script_loading_state.text = "Застосування..."
        coroutine.yield()
        time_batch_start = os.clock()
        for i, line in ipairs(ass_lines) do
            if ass_actors[line.actor] then
                local original_text = line.text
                local new_text = line.text:gsub("([%a\128-\255\']+[\128-\255]*)", function(w)
                    local lower = utf8_lower(w)
                    if blacklist_lookup[lower] then return w end
        
                    if replacements[lower] then
                        local dict_word = replacements[lower]
                        local upper = utf8_upper(w)
                        if w == upper then return utf8_upper(dict_word)
                        elseif w:sub(1,1) == upper:sub(1,1) then
                            local first_len = 1
                            local b = string.byte(w, 1)
                            if b >= 240 then first_len = 4
                            elseif b >= 224 then first_len = 3
                            elseif b >= 192 then first_len = 2 end
                            local first_char = utf8_upper(dict_word:sub(1, first_len))
                            return first_char .. dict_word:sub(first_len + 1)
                        else return dict_word end
                    end
                    return w
                end)
                if new_text ~= original_text then
                    line.text = new_text
                    changed_lines = changed_lines + 1
                end
            end
            if (i % 50 == 0) and (os.clock() - time_batch_start > 0.03) then 
                coroutine.yield()
                time_batch_start = os.clock()
            end
        end
    end

    rebuild_regions()
    script_loading_state.active = false
    local strategy_name = python_success and "AI-модель" or "Словник"
    reaper.MB("Наголоси застосовано (" .. strategy_name .. ")!\nЗмінено рядків: " .. changed_lines, "Успіх", 0)
    save_project_data()
    update_regions_cache()
    draw_prompter_cache = {} 
    reaper.UpdateArrange()
end

local current_stress_job = nil
local function apply_stress_marks()
    -- Start async job
    current_stress_job = coroutine.create(apply_stress_marks_coroutine)
    
    -- Initial resume to start
    local ok, err = coroutine.resume(current_stress_job)
    if not ok then 
        reaper.ShowConsoleMsg("Error in stress coroutine: " .. tostring(err) .. "\n")
        script_loading_state.active = false
        current_stress_job = nil
    end
end

--- Handle Drag & Drop of SRT/ASS files
local function handle_drag_drop()
    local file_idx = 0
    local retval, dropped_file = gfx.getdropfile(file_idx)
    
    while retval > 0 do
        local ext = dropped_file:match("%.([^.]+)$")
        if ext then
            ext = ext:lower()
            if ext == "srt" then
                import_srt(dropped_file)
            elseif ext == "ass" then
                import_ass(dropped_file)
            elseif ext == "vtt" then
                import_vtt(dropped_file)
            elseif ext == "csv" then
                import_notes_from_csv(dropped_file)
            end
        end
        
        file_idx = file_idx + 1
        retval, dropped_file = gfx.getdropfile(file_idx)
    end
    
    gfx.getdropfile(-1) -- Clear drop queue
end

--- Delete all project regions
local function delete_all_regions()
    local resp = reaper.ShowMessageBox("Ви впевнені, що хочете видалити ВСІ регіони та очистити дані?", "Видалення", 4)
    if resp ~= 6 then return end

    -- Clear project data
    ass_lines = {}
    ass_actors = {}
    ass_file_loaded = false

    -- Clear undo/redo history
    undo_stack = {}
    redo_stack = {}

    rebuild_regions()
    save_project_data()

    if show_snackbar then
        show_snackbar("Всі дані та регіони видалено")
    end
end

--- Get current script absolute path
local function get_script_path()
    local info = debug.getinfo(1, 'S')
    if info and info.source then
        return info.source:match("@?(.*)")
    end
    return ""
end

--- Manage REAPER startup script. Edit REAPER __startup.lua file with our startup logic
--- @param enable boolean
local function toggle_reaper_startup(enable)
    local resource_path = reaper.GetResourcePath()
    local startup_path = resource_path:gsub("\\", "/") .. "/Scripts/__startup.lua"
    local script_path = get_script_path():gsub("\\", "/")
    
    if script_path == "" then return false end
    
    local lines = {}
    local f = io.open(startup_path, "r")
    if f then
        for line in f:lines() do
            table.insert(lines, line)
        end
        f:close()
    end
    
    -- Filter out existing subass startup lines
    local new_lines = {}
    local skip = false
    local tag_start = "-- Subass_Notes Startup Start"
    local tag_end = "-- Subass_Notes Startup End"
    
    for _, line in ipairs(lines) do
        if line:find(tag_start, 1, true) then
            skip = true
        elseif line:find(tag_end, 1, true) then
            skip = false
        elseif not skip then
            table.insert(new_lines, line)
        end
    end
    
    if enable then
        -- Add at the beginning to ensure it runs
        table.insert(new_lines, 1, tag_end)
        table.insert(new_lines, 1, string.format("reaper.defer(function() dofile([[%s]]) end)", script_path))
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

-- =============================================================================
-- TEXT EDITOR MODAL
-- =============================================================================

--- Wrap text to fit width
local function wrap_text(text, max_w)
    local lines = {}
    local words = {}
    for w in text:gmatch("%S+") do table.insert(words, w) end
    
    local current_line = ""
    for _, w in ipairs(words) do
        local test_line = current_line == "" and w or (current_line .. " " .. w)
        -- Ignore stress marks for layout measurement
        local measure_line = test_line:gsub(acute, "")
        if gfx.measurestr(measure_line) > max_w then
            table.insert(lines, current_line)
            current_line = w
        else
            current_line = test_line
        end
    end
    if current_line ~= "" then table.insert(lines, current_line) end
    return lines
end

--- Wrap rich text (segments) to fit width
local function wrap_rich_text(segments, max_w, is_header)
    local lines = {}
    local current_line = {}
    local current_w = 0
    
    for _, seg in ipairs(segments) do
        local words = {}
        for w in seg.text:gmatch("%S+") do table.insert(words, w) end
        
        if #words == 0 and #seg.text > 0 then
            table.insert(words, seg.text)
        end
        
        for i, w in ipairs(words) do
            local test_word = (i > 1 or current_w > 0) and (" " .. w) or w
            if #words == 1 and seg.text:sub(1,1) ~= " " and current_w == 0 then test_word = w end
            
            -- Apply font based on segment/header status for measurement
            if seg.is_bold or (is_header and not seg.is_plain) then
                gfx.setfont(F.dict_bld)
            else
                gfx.setfont(F.dict_std)
            end
            
            -- Ignore stress marks for layout measurement
            local measure_word_for_width = test_word:gsub(acute, "")
            local word_w = gfx.measurestr(measure_word_for_width)
            
            if current_w + word_w > max_w and current_w > 0 then
                table.insert(lines, current_line)
                current_line = {}
                current_w = 0
                test_word = w
                word_w = gfx.measurestr((test_word:gsub(acute, "")))
            end
            
            local last_seg = current_line[#current_line]
            local can_merge = last_seg and 
                (last_seg.is_link == seg.is_link) and 
                (last_seg.is_plain == seg.is_plain) and 
                (last_seg.is_bold == seg.is_bold) and
                (last_seg.is_italic == seg.is_italic) and
                (last_seg.word == seg.word)
            
            if can_merge then
                last_seg.text = last_seg.text .. test_word
            else
                table.insert(current_line, {
                    text = test_word,
                    is_link = seg.is_link,
                    word = seg.word,
                    is_plain = seg.is_plain, 
                    is_bold = seg.is_bold, 
                    is_italic = seg.is_italic
                })
            end
           current_w = current_w + word_w
        end
    end
    
    if #current_line > 0 then
        table.insert(lines, current_line)
    end
    return lines
end

--- Draw and handle AI Assistant Overlay (Refined to Dropdown)
local function draw_ai_modal(skip_draw)
    if not ai_modal.show then 
        ai_modal.was_shown = false
        return 
    end

    local ai_tasks = {
        { name = "Перефразувати", task = "Перефразуй (збережи сенс, але використай інші слова та синоніми)" },
        { name = "Зробити довше", task = "Зроби довшим (надай варіанти різної довжини: деякі лише на 1-3 слова довші, інші — значно довші)" },
        { name = "Зробити коротше", task = "Зроби коротшим (надай варіанти різної довжини: деякі лише на 1-3 слова коротші, інші — значно коротші)" },
        { name = "Перевірити наголоси", count = 1, task = "Перевір наголоси в словах відповідно до норм сучасної української мови. Поверни текст, де наголошена голосна у кожному слові (крім односкладних) виділена ВЕЛИКОЮ літерою ТА постав після неї символ наголосу (наприклад: розмО́ва, договІ́р). Особливу увагу приділи словам з подвійним наголосом або складним випадкам (наприклад: завждИ, фенОмен)." },
        { name = "Веселіше", task = "Зроби тон більш позитивним, жартівливим або життєрадісним" },
        { name = "Більше драми", task = "Зроби репліку більш емоційною, напруженою або трагічною" },
        { name = "Більше сарказму", task = "Додай іронії, сарказму або насмішкуватості" },
        { name = "Більш погрозливо", task = "Зроби тон небезпечним, суворим або таким, що залякує" },
        { name = "Максимально просто", task = "Використовуй прості слова та розмовну лексику, зроби репліку максимально природною для повсякденної мови" },
        { name = "<Свій варіант>", task = "CUSTOM" },
    }

    local menu_w = 350
    local x = ai_modal.anchor_x - menu_w + 40
    local y = ai_modal.anchor_y + 5

    -- Pre-calculate content height to determine menu height
    local content_h = 0
    if ai_modal.current_step == "SELECT_TASK" then
        local list_h = #ai_tasks * (35 + 2) + 10
        local has_back = (#ai_modal.suggestions > 0)
        content_h = list_h + (has_back and 35 or 0)
    elseif ai_modal.current_step == "LOADING" then
        content_h = 60
    elseif ai_modal.current_step == "RESULTS" then
        local th = 0
        for _, sugg in ipairs(ai_modal.suggestions) do
            local wrapped = wrap_text(sugg.text, menu_w - 30)
            th = th + #wrapped * 18 + 15 + 5
        end
        content_h = th + 5 + 35 -- th + padding + footer
    elseif ai_modal.current_step == "ERROR" then
        content_h = 100
    end

    local menu_max_limit = 450
    local menu_h = math.min(content_h, menu_max_limit)
    
    -- Safety: don't go off screen vertically
    if y + menu_h > gfx.h - 10 then
        menu_h = gfx.h - y - 10
    end
    if menu_h < 40 then menu_h = 40 end

    -- Safety: don't go off screen horizontally
    if x < 10 then x = 10 end
    if x + menu_w > gfx.w - 10 then x = gfx.w - menu_w - 10 end

    -- Mouse Wheel Handling (High Priority)
    if gfx.mouse_wheel ~= 0 then
        if gfx.mouse_x >= x and gfx.mouse_x <= x + menu_w and gfx.mouse_y >= y and gfx.mouse_y <= y + menu_h then
            ai_modal.scroll = ai_modal.scroll + (gfx.mouse_wheel > 0 and -40 or 40)
            gfx.mouse_wheel = 0 -- Consume
        end
    end

    ai_modal.was_shown = true

    -- Clamp scroll (Unified)
    if ai_modal.scroll < 0 then ai_modal.scroll = 0 end
    if content_h > menu_h and ai_modal.scroll > content_h - menu_h then 
        ai_modal.scroll = content_h - menu_h 
    elseif content_h <= menu_h then
        ai_modal.scroll = 0
    end

    local changed = false
    
    if skip_draw then
        -- Interaction Handling (Only run in input pass)
        local mouse_in_menu = (gfx.mouse_x >= x and gfx.mouse_x <= x + menu_w and gfx.mouse_y >= y and gfx.mouse_y <= y + menu_h)
        local clicked = is_mouse_clicked()
        local now = os.clock()
        
        -- Transparent overlay to capture clicks outside
        -- Added debounce to prevent closing immediately after clicking a button (phantom click issue)
        if clicked and ai_modal.was_shown and (now - (ai_modal.last_click_time or 0) > 0.2) then
            if not mouse_in_menu and gfx.mouse_y < ai_modal.anchor_y - 30 then
                ai_modal.show = false
                return false
            elseif not mouse_in_menu then
                ai_modal.show = false
                return false
            end
        end
        
        -- Consume click only if enough time passed since last interaction
        local can_click = clicked and (now - (ai_modal.last_click_time or 0) > 0.2)

        if ai_modal.current_step == "SELECT_TASK" then
            local has_back = (#ai_modal.suggestions > 0)
            local footer_h = has_back and 35 or 0
            local view_h = menu_h - footer_h
            
            local btn_h = 35
            if can_click and mouse_in_menu then
                -- Check List Items
                if gfx.mouse_y < y + view_h then
                    for i, t in ipairs(ai_tasks) do
                        local bx, by = x + 5, y + 5 + (i-1) * (btn_h + 2) - ai_modal.scroll
                        local bw = menu_w - 10
                        if by + btn_h > y and by < y + view_h then -- Visible?
                            if gfx.mouse_x >= bx and gfx.mouse_x <= bx + bw and gfx.mouse_y >= by and gfx.mouse_y <= by + btn_h then
                                ai_modal.last_click_time = now
                                if t.task == "CUSTOM" then
                                    local ok, input = reaper.GetUserInputs("AI Варіант", 1, "наприклад: Більше сленгу,extrawidth=200", "")
                                    if ok and input ~= "" then
                                        request_ai_assistant_task(input, ai_modal.text, 3)
                                    end
                                else
                                    request_ai_assistant_task(t.task, ai_modal.text, t.count)
                                end
                                break
                            end
                        end
                    end
                end
                
                -- Check Back Button
                if has_back then
                    local bbx, bby, bbw, bbh = x + 5, y + view_h + 5, menu_w - 10, footer_h - 10
                    if gfx.mouse_x >= bbx and gfx.mouse_x <= bbx + bbw and gfx.mouse_y >= bby and gfx.mouse_y <= bby + bbh then
                        ai_modal.last_click_time = now
                        ai_modal.current_step = "RESULTS"
                        ai_modal.scroll = 0
                    end
                end
            end
            
        elseif ai_modal.current_step == "RESULTS" then
            local footer_h = 35
            local view_h = menu_h - footer_h
            local curr_y = y + 5 - ai_modal.scroll
            
            if can_click and mouse_in_menu then
                -- Check Back button first
                local bbx, bby, bbw, bbh = x + 5, y + view_h + 5, (menu_w / 2) - 7, footer_h - 10
                if gfx.mouse_x >= bbx and gfx.mouse_x <= bbx + bbw and
                   gfx.mouse_y >= bby and gfx.mouse_y <= bby + bbh then
                    ai_modal.last_click_time = now
                    ai_modal.current_step = "SELECT_TASK"
                    ai_modal.scroll = 0
                else
                    -- Check Retry button
                    local rbx, rby, rbw, rbh = x + (menu_w / 2) + 2, y + view_h + 5, (menu_w / 2) - 7, footer_h - 10
                    if gfx.mouse_x >= rbx and gfx.mouse_x <= rbx + rbw and
                       gfx.mouse_y >= rby and gfx.mouse_y <= rby + rbh then
                        ai_modal.last_click_time = now
                        request_ai_assistant_task(ai_modal.last_task, ai_modal.text)
                        ai_modal.scroll = 0
                    else
                        -- Check Suggestions
                        for i, sugg in ipairs(ai_modal.suggestions) do
                            local wrapped_lines = wrap_text(sugg.text, menu_w - 30)
                            local block_h = #wrapped_lines * 18 + 15
                            local bx, by = x + 5, curr_y
                            local bw = menu_w - 20
                            
                            if (by + block_h > y and by < y + view_h) and (gfx.mouse_y < y + view_h) then
                                if gfx.mouse_x >= bx and gfx.mouse_x <= bx + bw and
                                   gfx.mouse_y >= by and gfx.mouse_y <= by + block_h then
                                    ai_modal.last_click_time = now
                                    local before = text_editor_text:sub(1, ai_modal.sel_min)
                                    local after = text_editor_text:sub(ai_modal.sel_max + 1)
                                    text_editor_text = before .. sugg.text .. after
                                    text_editor_cursor = ai_modal.sel_min + #sugg.text
                                    text_editor_sel_anchor = text_editor_cursor
                                    
                                    changed = true
                                    ai_modal.show = false
                                    ai_modal.text = "" -- Clear session state on success
                                    break
                                end
                            end
                            curr_y = curr_y + block_h + 5
                        end
                    end
                end
            end
        elseif ai_modal.current_step == "ERROR" then
            if can_click and mouse_in_menu then
                local bbx, bby, bbw, bbh = x + (menu_w - 80) / 2, y + menu_h - 35, 80, 25
                if gfx.mouse_x >= bbx and gfx.mouse_x <= bbx + bbw and
                   gfx.mouse_y >= bby and gfx.mouse_y <= bby + bbh then
                    ai_modal.last_click_time = now
                    ai_modal.current_step = "SELECT_TASK"
                    ai_modal.scroll = 0
                end
            end
        end
        
        -- If mouse is interacting with this modal, blocking it from underlying elements
        if mouse_in_menu then
            gfx.mouse_cap = 0 
        end
        
        return changed
    end

    -- Draw Pass starts here
    local mouse_in_menu = (gfx.mouse_x >= x and gfx.mouse_x <= x + menu_w and
                           gfx.mouse_y >= y and gfx.mouse_y <= y + menu_h)

    -- Draw Menu Shadow
    set_color({0, 0, 0, 0.5})
    gfx.rect(x+3, y+3, menu_w, menu_h, 1)
    
    -- Capture current destination to return later
    local prev_dest = gfx.dest
    
    -- Prepare Buffer 99
    gfx.dest = 99
    gfx.setimgdim(99, menu_w, menu_h)
    set_color(UI.C_TAB_INA)
    gfx.rect(0, 0, menu_w, menu_h, 1) -- Clear buffer with menu background
    
    if ai_modal.current_step == "SELECT_TASK" then
        local has_back = (#ai_modal.suggestions > 0)
        local footer_h = has_back and 35 or 0
        local view_h = menu_h - footer_h

        local btn_h = 35
        for i, t in ipairs(ai_tasks) do
            local bx, by = 5, 5 + (i-1) * (btn_h + 2) - ai_modal.scroll
            local bw = menu_w - 10
            
            -- Only draw if visible in view_h
            if by + btn_h > 0 and by < view_h then
                local hover = mouse_in_menu and 
                              (gfx.mouse_x >= x + bx and gfx.mouse_x <= x + bx + bw and
                               gfx.mouse_y >= y + by and gfx.mouse_y <= y + by + btn_h and
                               gfx.mouse_y < y + view_h)
                
                set_color(hover and UI.C_BTN_H or UI.C_BTN)
                gfx.rect(bx, by, bw, btn_h, 1)
                set_color(UI.C_TXT)
                gfx.setfont(F.std)
                local sw, sh = gfx.measurestr(t.name)
                gfx.x, gfx.y = bx + (bw - sw) / 2, by + (btn_h - sh) / 2
                gfx.drawstr(t.name)
            end
        end
        
        -- Draw Back Button Footer
        if has_back then
            set_color(UI.C_TAB_INA)
            gfx.rect(0, view_h, menu_w, footer_h, 1)
            set_color({0.4, 0.4, 0.4, 0.5})
            gfx.line(0, view_h, menu_w, view_h)
            
            local bbx, bby, bbw, bbh = 5, view_h + 5, menu_w - 10, footer_h - 10
            local hover_back = mouse_in_menu and
                               (gfx.mouse_x >= x + bbx and gfx.mouse_x <= x + bbx + bbw and
                                gfx.mouse_y >= y + bby and gfx.mouse_y <= y + bby + bbh)
            
            set_color(hover_back and UI.C_TAB_ACT or UI.C_TAB_INA)

            gfx.rect(bbx, bby, bbw, bbh, 1)
            set_color(UI.C_TXT)
            local sw, sh = gfx.measurestr("Назад до результатів")
            gfx.x, gfx.y = bbx + (bbw - sw) / 2, bby + (bbh - sh) / 2
            gfx.drawstr("Назад до результатів")
        end
        
    elseif ai_modal.current_step == "LOADING" then
        gfx.setfont(F.std)
        local msg = "Зачекайте, AI чаклує..."
        local mw, mh = gfx.measurestr(msg)
        gfx.x = (menu_w - mw) / 2
        gfx.y = (menu_h - mh) / 2
        gfx.drawstr(msg)
        
    elseif ai_modal.current_step == "RESULTS" then
        local footer_h = 35
        local view_h = menu_h - footer_h
        local curr_y = 5 - ai_modal.scroll
        
        for i, sugg in ipairs(ai_modal.suggestions) do
            local wrapped_lines = wrap_text(sugg.text, menu_w - 30)
            local block_h = #wrapped_lines * 18 + 15
            local bx, by = 5, curr_y
            local bw = menu_w - 20
            
            local alpha = sugg.is_old and 0.7 or 1.0
            
            local hover = mouse_in_menu and (by + block_h > 0 and by < view_h) and
                         (gfx.mouse_y < y + view_h) and
                         (gfx.mouse_x >= x + bx and gfx.mouse_x <= x + bx + bw and
                          gfx.mouse_y >= y + by and gfx.mouse_y <= y + by + block_h)
            
            set_color(hover and {0.2 * alpha, 0.25 * alpha, 0.3 * alpha, 1.0 * alpha} or {0.14 * alpha, 0.14 * alpha, 0.14 * alpha, 1.0 * alpha})
            gfx.rect(bx, by, bw, block_h, 1)
            set_color({0.3 * alpha, 0.3 * alpha, 0.3 * alpha, 1.0 * alpha})
            gfx.rect(bx, by, bw, block_h, 0)
            
            set_color({1 * alpha, 1 * alpha, 1 * alpha, 1.0 * alpha})
            for li, line in ipairs(wrapped_lines) do
                gfx.x, gfx.y = bx + 8, by + 5 + (li-1) * 18
                gfx.drawstr(line)
            end
            curr_y = curr_y + block_h + 5
        end
        
        -- Fixed Footer with Back and Retry Buttons
        set_color(UI.C_TAB_INA)
        gfx.rect(0, view_h, menu_w, footer_h, 1)
        set_color({0.4, 0.4, 0.4, 0.5})
        gfx.line(0, view_h, menu_w, view_h)
        
        local bbx, bby, bbw, bbh = 5, view_h + 5, (menu_w / 2) - 7, footer_h - 10
        local hover_back = mouse_in_menu and
                          (gfx.mouse_x >= x + bbx and gfx.mouse_x <= x + bbx + bbw and
                           gfx.mouse_y >= y + bby and gfx.mouse_y <= y + bby + bbh)
        set_color(hover_back and UI.C_BTN_H or UI.C_BTN)
        gfx.rect(bbx, bby, bbw, bbh, 1)
        set_color(UI.C_TXT)
        local sw, sh = gfx.measurestr("Назад")
        gfx.x, gfx.y = bbx + (bbw - sw) / 2, bby + (bbh - sh) / 2
        gfx.drawstr("Назад")
        
        -- ЩЕ Button
        local rbx, rby, rbw, rbh = (menu_w / 2) + 2, view_h + 5, (menu_w / 2) - 7, footer_h - 10
        local hover_more = mouse_in_menu and
                           (gfx.mouse_x >= x + rbx and gfx.mouse_x <= x + rbx + rbw and
                            gfx.mouse_y >= y + rby and gfx.mouse_y <= y + rby + rbh)
        set_color(hover_more and UI.C_SEL or {0.3, 0.4, 0.3})
        gfx.rect(rbx, rby, rbw, rbh, 1)
        set_color(UI.C_TXT)
        local msw, msh = gfx.measurestr("ЩЕ")
        gfx.x, gfx.y = rbx + (rbw - msw) / 2, rby + (rbh - msh) / 2
        gfx.drawstr("ЩЕ")

    elseif ai_modal.current_step == "ERROR" then
        set_color({0.8, 0.3, 0.3})
        gfx.setfont(F.std)
        local mw, mh = gfx.measurestr(ai_modal.error_msg)
        gfx.x, gfx.y = (menu_w - mw) / 2, (menu_h - mh) / 2 - 20
        gfx.drawstr(ai_modal.error_msg)
        
        -- Back Button
        local bbx, bby, bbw, bbh = (menu_w - 80) / 2, menu_h - 35, 80, 25
        local hover = mouse_in_menu and
                     (gfx.mouse_x >= x + bbx and gfx.mouse_x <= x + bbx + bbw and
                      gfx.mouse_y >= y + bby and gfx.mouse_y <= y + bby + bbh)
        set_color(hover and UI.C_BTN_H or UI.C_BTN)
        gfx.rect(bbx, bby, bbw, bbh, 1)
        set_color(UI.C_TXT)
        local sw, sh = gfx.measurestr("Назад")
        gfx.x, gfx.y = bbx + (bbw-sw)/2, bby + (bbh-sh)/2
        gfx.drawstr("Назад")
    end

    -- Blit back to main destination
    gfx.dest = prev_dest
    gfx.blit(99, 1, 0, 0, 0, menu_w, menu_h, x, y, menu_w, menu_h)

    -- Draw Menu Border
    set_color(UI.C_TXT)
    gfx.rect(x, y, menu_w, menu_h, 0)

    -- Unified Scrollbar
    if content_h > menu_h then
        local sb_h = (menu_h / content_h) * menu_h
        local sb_y = y + (ai_modal.scroll / content_h) * menu_h
        set_color({0.5, 0.5, 0.5, 0.8})
        gfx.rect(x + menu_w - 8, sb_y, 4, sb_h, 1)
    end
    
    return changed
end

--- Draw and handle text editor modal dialog
--- @param input_queue table Input events queue
--- @return boolean True if editor consumed the input
local function draw_text_editor(input_queue)
    if not text_editor_active then return false end
    
    -- History Helper and Changed flag
    local content_changed = false
    local function record_history()
        -- Truncate future if we diverged
        if text_editor_history_pos < #text_editor_history then
            for i = #text_editor_history, text_editor_history_pos + 1, -1 do
                table.remove(text_editor_history, i)
            end
        end
        -- Push
        table.insert(text_editor_history, {
            text = text_editor_text,
            cursor = text_editor_cursor,
            anchor = text_editor_sel_anchor
        })
        text_editor_history_pos = #text_editor_history
        -- Cap size (e.g. 100)
        if #text_editor_history > 100 then
            table.remove(text_editor_history, 1)
            text_editor_history_pos = text_editor_history_pos - 1
        end
    end

    -- AI Modal Input First (Priority)
    if draw_ai_modal(true) then content_changed = true end
    
    -- Darken background
    gfx.set(0, 0, 0, 0.7)
    gfx.rect(0, 0, gfx.w, gfx.h, 1)
    
    -- Editor box
    local pad = 25
    local box_x = pad
    local box_y = pad
    local box_w = gfx.w - pad * 2
    local box_h = gfx.h - pad * 2
    
    set_color(UI.C_TAB_INA)
    gfx.rect(box_x, box_y, box_w, box_h, 1)
    
    -- Title
    set_color(UI.C_TXT)
    gfx.setfont(F.std)
    gfx.x = box_x + 10
    gfx.y = box_y + 10
    gfx.drawstr("Редагування тексту (Enter = новий рядок, Esc = скасування)")

    -- AI Button dimensions (needed for history button positioning)
    local ai_btn_w = 40
    local ai_btn_h = 24
    local ai_btn_x = box_x + box_w - ai_btn_w - 10
    local ai_btn_y = box_y + 8

    -- AI History Button (only show if history exists)
    local hist_btn_w = 30
    local hist_btn_h = 24
    local hist_btn_x = box_x + box_w - ai_btn_w - hist_btn_w - 15
    local hist_btn_y = box_y + 8
    
    if #ai_modal.history > 0 then
        if btn(hist_btn_x, hist_btn_y, hist_btn_w, hist_btn_h, "#") then
            -- Clear console first
            reaper.ShowConsoleMsg("")
            
            -- Build history text for display
            local history_text = "=== ІСТОРІЯ AI ОПЕРАЦІЙ ===\n\n"
            for i = #ai_modal.history, 1, -1 do -- Reverse order (newest first)
                local entry = ai_modal.history[i]
                history_text = history_text .. string.format(
                    "[%s] %s\n\n",
                    entry.timestamp,
                    entry.task
                )
                
                history_text = history_text .. "ОРИГІНАЛЬНИЙ ТЕКСТ:\n" .. entry.original .. "\n\n"
                history_text = history_text .. "ВАРІАНТИ ВІД GEMINI:\n"
                
                -- Add all variants
                for j, variant in ipairs(entry.variants) do
                    history_text = history_text .. string.format("%d. %s\n", j, variant)
                end
                
                history_text = history_text .. "\n" .. string.rep("=", 80) .. "\n\n"
            end
            
            -- Show in REAPER's console (scrollable)
            reaper.ShowConsoleMsg(history_text)
            
            -- Open console window only if it's not already open
            local console_state = reaper.GetToggleCommandState(40004)
            if console_state == 0 then
                reaper.Main_OnCommand(40004, 0) -- View: Show console window
            end
        end
    end

    -- AI Button interaction
    local sel_min = math.min(text_editor_cursor, text_editor_sel_anchor)
    local sel_max = math.max(text_editor_cursor, text_editor_sel_anchor)
    local has_sel = (sel_min ~= sel_max)

    if btn(ai_btn_x, ai_btn_y, ai_btn_w, ai_btn_h, "AI") then
        if not cfg.gemini_api_key or cfg.gemini_api_key == "" or (gemini_key_status ~= 200 and gemini_key_status ~= 429) then
            show_snackbar("Ключ Gemini API не валідний або відсутній", 3.0)
        else
            -- Expand selection to words if any word is partially touched
            if has_sel then
                local word_pattern = "[%a\128-\255\'%-]+[\128-\255]*"
                local new_min, new_max = sel_min, sel_max
                local pos = 1
                while pos <= #text_editor_text do
                    local s, e = text_editor_text:find(word_pattern, pos)
                    if not s then break end
                    local w_min = s - 1
                    local w_max = e
                    -- If word overlaps current selection
                    if w_max > sel_min and w_min < sel_max then
                        if w_min < new_min then new_min = w_min end
                        if w_max > new_max then new_max = w_max end
                    end
                    pos = e + 1
                end
                sel_min, sel_max = new_min, new_max
                -- Update actual editor state
                if text_editor_cursor > text_editor_sel_anchor then
                    text_editor_cursor, text_editor_sel_anchor = sel_max, sel_min
                else
                    text_editor_cursor, text_editor_sel_anchor = sel_min, sel_max
                end
            end

            local can_restore = (ai_modal.text ~= "")

            local function init_selection(s_min, s_max)
                -- Open Modal with new selection
                ai_modal.text = text_editor_text:sub(s_min + 1, s_max)
                ai_modal.sel_min = s_min
                ai_modal.sel_max = s_max
                ai_modal.current_step = "SELECT_TASK"
                ai_modal.suggestions = {}
                ai_modal.scroll = 0
                ai_modal.anchor_x = ai_btn_x
                ai_modal.anchor_y = ai_btn_y + ai_btn_h
                ai_modal.show = true
            end
            
            if has_sel and sel_max - sel_min < 8 then
                show_snackbar("Треба виділити більше тексту")
            elseif has_sel then
                -- Compare with current session
                if can_restore and sel_min == ai_modal.sel_min and sel_max == ai_modal.sel_max then
                    ai_modal.show = true
                else
                    -- Start new session
                    init_selection(sel_min, sel_max)
                end
            elseif can_restore then
                -- Restore selection and show modal
                text_editor_cursor = ai_modal.sel_max
                text_editor_sel_anchor = ai_modal.sel_min
                ai_modal.anchor_x = ai_btn_x
                ai_modal.anchor_y = ai_btn_y + ai_btn_h
                ai_modal.show = true
            elseif #text_editor_text > 0 then
                -- Auto-select ALL text if nothing is selected (First-click convenience)
                text_editor_sel_anchor = 0
                text_editor_cursor = #text_editor_text

                -- Open Modal with new selection
                init_selection(0, #text_editor_text)
            else
                show_snackbar("Треба виділити цільовий текст для роботи")
            end
        end
    end
    
    -- Text area
    local text_x = box_x + 10
    local text_y = box_y + 35
    local text_w = box_w - 20
    local text_h = box_h - 80
    local line_h = 18

    -- Mouse Wheel Handling
    if gfx.mouse_x >= text_x and gfx.mouse_x <= text_x + text_w and
       gfx.mouse_y >= text_y and gfx.mouse_y <= text_y + text_h then
        if gfx.mouse_wheel ~= 0 then
            text_editor_scroll = text_editor_scroll + (gfx.mouse_wheel > 0 and -line_h * 3 or line_h * 3)
            gfx.mouse_wheel = 0
        end
    end
    
    set_color({0.12, 0.12, 0.12})
    gfx.rect(text_x, text_y, text_w, text_h, 1)
    
    -- Prepare lines (Visual Wrapping)
    set_color(UI.C_TXT)
    gfx.setfont(F.std)
    local visual_lines = {}
    
    local raw_pos = 0
    for ln in (text_editor_text .. "\n"):gmatch("(.-)\n") do
        if ln == "" then
            table.insert(visual_lines, {text = "", start_idx = raw_pos, is_wrapped = false})
        else
            local remaining = ln
            local line_start = raw_pos
            while #remaining > 0 do
                local fit_count = 0
                local low, high = 1, #remaining
                
                -- Binary search for how much text fits in text_w (Character-aware)
                local char_len = utf8.len(remaining) or #remaining
                local low, high = 1, char_len
                
                while low <= high do
                    local mid = math.floor((low + high) / 2)
                    local CharStart = utf8.offset(remaining, mid)
                    local CharEnd = utf8.offset(remaining, mid + 1) or (#remaining + 1)
                    local byte_mid = CharEnd - 1
                    
                    if gfx.measurestr(remaining:sub(1, byte_mid)) <= text_w - 10 then
                        fit_count = byte_mid
                        low = mid + 1
                    else
                        high = mid - 1
                    end
                end
                
                if fit_count == 0 then 
                    -- Safety: take at least one full character
                    local first_char_end = utf8.offset(remaining, 2) or (#remaining + 1)
                    fit_count = first_char_end - 1 
                end
                
                local segment = remaining:sub(1, fit_count)
                remaining = remaining:sub(fit_count + 1)
                
                table.insert(visual_lines, {
                    text = segment, 
                    start_idx = line_start, 
                    is_wrapped = (#remaining > 0)
                })
                line_start = line_start + fit_count
            end
        end
        raw_pos = raw_pos + #ln + 1 -- +1 for newline
    end
    if #visual_lines == 0 then table.insert(visual_lines, {text = "", start_idx = 0}) end

    -- Scroll Clamping
    local total_text_h = #visual_lines * line_h
    if text_editor_scroll > total_text_h - text_h + 10 then 
        text_editor_scroll = math.max(0, total_text_h - text_h + 10) 
    end
    if text_editor_scroll < 0 then text_editor_scroll = 0 end

    -- Helper: Convert X/Y to Cursor Index
    local function get_cursor_from_xy(mx, my)
        local click_rel_y = my - (text_y + 5) + text_editor_scroll
        local click_line_idx = math.floor(click_rel_y / line_h) + 1
        
        if click_line_idx < 1 then click_line_idx = 1 end
        if click_line_idx > #visual_lines then click_line_idx = #visual_lines end
        
        local v_line = visual_lines[click_line_idx]
        local target_text = v_line.text
        local click_rel_x = mx - (text_x + 5)
        
        local char_idx = 0
        local best_dist = math.huge
        local current_offset = 0
        while current_offset <= #target_text do
            local w = gfx.measurestr(target_text:sub(1, current_offset))
            local dist = math.abs(w - click_rel_x)
            if dist < best_dist then
                best_dist = dist
                char_idx = current_offset
            end
            if current_offset >= #target_text then break end
            
            local b = target_text:byte(current_offset + 1)
            local len = 1
            if b >= 240 then len = 4 elseif b >= 224 then len = 3 elseif b >= 192 then len = 2 end
            current_offset = current_offset + len
        end
        
        return v_line.start_idx + char_idx
    end

    -- Helper: Get current visual line index for cursor (Greedy/Boundary safe)
    local function get_cur_vi(idx)
        local cur_vi = 1
        for i = 2, #visual_lines do
            if idx >= visual_lines[i].start_idx then
                cur_vi = i
            else
                break
            end
        end
        return cur_vi
    end

    -- Selection Logic
    local sel_min = math.min(text_editor_cursor, text_editor_sel_anchor)
    local sel_max = math.max(text_editor_cursor, text_editor_sel_anchor)
    local has_sel = (sel_min ~= sel_max)

    -- MOUSE HANDLING
    local in_rect = (gfx.mouse_x >= text_x and gfx.mouse_x <= text_x + text_w and
                     gfx.mouse_y >= text_y and gfx.mouse_y <= text_y + text_h)

    if gfx.mouse_cap == 1 then
        if last_mouse_cap == 0 and in_rect then
            local now = reaper.time_precise()
            if last_click_row == -999 and (now - last_click_time) < 0.5 then
                text_editor_sel_anchor = 0
                text_editor_cursor = #text_editor_text
                last_click_row = 0
            elseif last_click_row == 999 and (now - last_click_time) < 0.5 then
                local cx = get_cursor_from_xy(gfx.mouse_x, gfx.mouse_y)
                local s, e = cx, cx
                local i = cx
                while i > 0 do
                    local c = text_editor_text:sub(i, i)
                    if c:match("[%s%p]") then break end
                    i = i - 1
                end
                s = i
                i = cx + 1
                while i <= #text_editor_text do
                    local c = text_editor_text:sub(i, i)
                    if c:match("[%s%p]") then i = i - 1; break end
                    i = i + 1
                end
                e = i
                text_editor_sel_anchor, text_editor_cursor = s, math.max(s, e)
                last_click_row, last_click_time = -999, now
            else
                local new_cur = get_cursor_from_xy(gfx.mouse_x, gfx.mouse_y)
                text_editor_cursor, text_editor_sel_anchor = new_cur, new_cur
                last_click_row, last_click_time = 999, now
            end
        elseif in_rect and last_click_row ~= -999 then 
            text_editor_cursor = get_cursor_from_xy(gfx.mouse_x, gfx.mouse_y)
        end
    end

    -- DRAW TEXT & SELECTION
    for i, v_line in ipairs(visual_lines) do
        local y = text_y + 5 + (i-1) * line_h - text_editor_scroll
        if y >= text_y + text_h - 10 then break end
        if y >= text_y then
            local line_start = v_line.start_idx
            local line_end = line_start + #v_line.text
            
            -- Selection highlighting
            if has_sel then
                local s_start = math.max(line_start, sel_min)
                local s_end = math.min(line_end, sel_max)
                if s_start < s_end then
                    local x1 = text_x + 5 + gfx.measurestr(v_line.text:sub(1, s_start - line_start))
                    local sw = gfx.measurestr(v_line.text:sub(s_start - line_start + 1, s_end - line_start))
                    set_color({0.3, 0.4, 0.6})
                    gfx.rect(x1, y, sw, line_h, 1)
                end
                -- Newline selection indicator (only if not a wrapped line)
                if not v_line.is_wrapped and sel_max > line_end and sel_min <= line_end then
                    local fw = gfx.measurestr(v_line.text)
                    set_color({0.3, 0.4, 0.6})
                    gfx.rect(text_x + 5 + fw, y, 5, line_h, 1)
                end
            end
            
            set_color(UI.C_TXT)
            gfx.x, gfx.y = text_x + 5, y
            gfx.drawstr(v_line.text)
        end
    end
    
    -- Blinking cursor
    if math.floor(reaper.time_precise() * 2) % 2 == 0 then
        local cur_v_line_idx = 1
        for i, v_line in ipairs(visual_lines) do
            if text_editor_cursor <= v_line.start_idx + #v_line.text then
                cur_v_line_idx = i; break
            else
                cur_v_line_idx = i
            end
        end
        local target_v_line = visual_lines[cur_v_line_idx]
        local cur_rel_offset = text_editor_cursor - target_v_line.start_idx
        local cur_x = text_x + 5 + gfx.measurestr(target_v_line.text:sub(1, math.max(0, cur_rel_offset)))
        local cur_y = text_y + 5 + (cur_v_line_idx - 1) * line_h - text_editor_scroll
        
        if cur_y >= text_y and cur_y < text_y + text_h - 10 then
            set_color({1, 1, 1})
            gfx.rect(cur_x, cur_y, 2, line_h, 1)
        end
    end

    -- Scrollbar
    if total_text_h > text_h then
        local sb_w = 6
        local sb_h = (text_h / total_text_h) * text_h
        local sb_y = text_y + (text_editor_scroll / total_text_h) * text_h
        local sb_x = text_x + text_w - sb_w - 2
        set_color({0.4, 0.4, 0.4, 0.6})
        gfx.rect(sb_x, sb_y, sb_w, sb_h, 1)
    end
    
    -- Buttons
    local btn_y = box_y + box_h - 40
    if btn(box_x + 10, btn_y, 90, 30, "Скасування") then 
        text_editor_active = false 
        ai_modal.text = ""
        ai_modal.suggestions = {}
        ai_modal.history = {} -- Clear history
        text_editor_context_line_idx = nil
        text_editor_context_all_lines = nil
    end
    if btn(box_x + box_w - 90, btn_y, 80, 30, "Зберегти") then
        if text_editor_callback then text_editor_callback(text_editor_text) end
        text_editor_active = false
        ai_modal.text = ""
        ai_modal.suggestions = {}
        ai_modal.history = {} -- Clear history
        text_editor_context_line_idx = nil
        text_editor_context_all_lines = nil
    end

    -- Handle Keyboard Input from QUEUE
    if input_queue then
        local cap = gfx.mouse_cap
        local is_cmd = (reaper.GetOS():find("OSX") and (cap & 4 == 4))
        local is_ctrl = (cap & 4 == 4)
        local is_shift = (cap & 8 == 8)
        local is_paste_mod = (is_ctrl or is_cmd) 
        
        -- Helper: Delete Selection
        local function delete_selection()
            if not has_sel then return end
            local s_min, s_max = math.min(text_editor_cursor, text_editor_sel_anchor), math.max(text_editor_cursor, text_editor_sel_anchor)
            local before = text_editor_text:sub(1, s_min)
            local after = text_editor_text:sub(s_max + 1)
            text_editor_text = before .. after
            text_editor_cursor = s_min
            text_editor_sel_anchor = s_min
        end

        for _, char in ipairs(input_queue) do
            local handled_history = false

            -- Undo / Redo
            if ((char == 26) or (is_paste_mod and (char == 122 or char == 90))) then
                if is_shift then
                    -- Redo
                    if text_editor_history_pos < #text_editor_history then
                        text_editor_history_pos = text_editor_history_pos + 1
                        local snapshot = text_editor_history[text_editor_history_pos]
                        text_editor_text, text_editor_cursor, text_editor_sel_anchor = snapshot.text, snapshot.cursor, snapshot.anchor
                    end
                else
                    -- Undo
                    if text_editor_history_pos > 1 then
                        text_editor_history_pos = text_editor_history_pos - 1
                        local snapshot = text_editor_history[text_editor_history_pos]
                        text_editor_text, text_editor_cursor, text_editor_sel_anchor = snapshot.text, snapshot.cursor, snapshot.anchor
                    end
                end
                handled_history = true
            end

            if not handled_history then
                if char == 1 or (is_cmd and (char == 97 or char == 65)) then -- Select All
                    text_editor_sel_anchor, text_editor_cursor = 0, #text_editor_text
                elseif (char == 3) or (is_paste_mod and (char == 99 or char == 67)) then -- Copy
                    if has_sel then
                        local sm, sx = math.min(text_editor_cursor, text_editor_sel_anchor), math.max(text_editor_cursor, text_editor_sel_anchor)
                        set_clipboard(text_editor_text:sub(sm + 1, sx))
                    end
                elseif (char == 24) or (is_paste_mod and (char == 120 or char == 88)) then -- Cut
                    if has_sel then
                        local sm, sx = math.min(text_editor_cursor, text_editor_sel_anchor), math.max(text_editor_cursor, text_editor_sel_anchor)
                        set_clipboard(text_editor_text:sub(sm + 1, sx))
                        delete_selection()
                        content_changed = true
                    end
                elseif (is_paste_mod and (char == 118 or char == 86)) or (char == 22) then -- Paste
                    delete_selection() 
                    local clp = get_clipboard()
                    if clp and clp ~= "" then
                        clp = clp:gsub("\r\n", "\n"):gsub("\r", "\n")
                        text_editor_text = text_editor_text:sub(1, text_editor_cursor) .. clp .. text_editor_text:sub(text_editor_cursor + 1)
                        text_editor_cursor = text_editor_cursor + #clp
                        text_editor_sel_anchor = text_editor_cursor 
                        content_changed = true
                    end
                elseif char == 27 then -- Esc
                    text_editor_active = false
                    ai_modal.text = ""
                    ai_modal.suggestions = {}
                    ai_modal.history = {} -- Clear history
                    text_editor_context_line_idx = nil
                    text_editor_context_all_lines = nil
                    return true
                elseif char == 13 then -- Enter
                    delete_selection()
                    text_editor_text = text_editor_text:sub(1, text_editor_cursor) .. "\n" .. text_editor_text:sub(text_editor_cursor + 1)
                    text_editor_cursor, text_editor_sel_anchor = text_editor_cursor + 1, text_editor_cursor + 1
                    content_changed = true
                elseif char == 8 then -- Backspace
                    if has_sel then delete_selection(); content_changed = true
                    elseif text_editor_cursor > 0 then
                        local cur = text_editor_cursor
                        while cur > 1 do
                            local b = text_editor_text:byte(cur)
                            if b < 128 or b >= 192 then break end
                            cur = cur - 1
                        end
                        text_editor_text = text_editor_text:sub(1, cur - 1) .. text_editor_text:sub(text_editor_cursor + 1)
                        text_editor_cursor = cur - 1
                        text_editor_sel_anchor = text_editor_cursor
                        content_changed = true
                    end
                elseif char == 1818584692 then -- Left
                    if text_editor_cursor > 0 then
                        local cur = text_editor_cursor
                        while cur > 1 do
                            local b = text_editor_text:byte(cur); if b < 128 or b >= 192 then break end
                            cur = cur - 1
                        end
                        text_editor_cursor = cur - 1
                        if not is_shift then text_editor_sel_anchor = text_editor_cursor end
                    end
                elseif char == 1919379572 then -- Right
                    if text_editor_cursor < #text_editor_text then
                        local cur = text_editor_cursor + 1
                        while cur < #text_editor_text do
                            local b = text_editor_text:byte(cur + 1); if b < 128 or b >= 192 then break end
                            cur = cur + 1
                        end
                        text_editor_cursor = cur
                        if not is_shift then text_editor_sel_anchor = text_editor_cursor end
                    end
                elseif char == 30064 then -- Up
                    -- Greedy lookup: prefer later line at wrap boundary to move to the one above it
                    local cur_vi = 1
                    for i, v_line in ipairs(visual_lines) do
                        if text_editor_cursor >= v_line.start_idx then cur_vi = i else break end
                    end
                    if cur_vi > 1 then
                        local cvl, pvl = visual_lines[cur_vi], visual_lines[cur_vi-1]
                        local rx = gfx.measurestr(cvl.text:sub(1, math.max(0, text_editor_cursor - cvl.start_idx)))
                        local bd, bi = math.huge, 0
                        local coff = 0
                        while coff <= #pvl.text do
                            local d = math.abs(gfx.measurestr(pvl.text:sub(1, coff)) - rx)
                            if d < bd then bd, bi = d, coff end
                            if coff >= #pvl.text then break end
                            local b = pvl.text:byte(coff + 1)
                            local len = 1
                            if b >= 240 then len = 4 elseif b >= 224 then len = 3 elseif b >= 192 then len = 2 end
                            coff = coff + len
                        end
                        text_editor_cursor = pvl.start_idx + bi
                        if not is_shift then text_editor_sel_anchor = text_editor_cursor end
                    end
                elseif char == 1685026670 then -- Down
                    -- Determine current visual line (use simple boundary-based lookup)
                    local cur_vi = 1
                    for i, v_line in ipairs(visual_lines) do
                        if text_editor_cursor <= v_line.start_idx + #v_line.text then
                            cur_vi = i
                            break
                        end
                        cur_vi = i
                    end
                    
                    if cur_vi < #visual_lines then
                        local cvl, nvl = visual_lines[cur_vi], visual_lines[cur_vi+1]
                        local rx = gfx.measurestr(cvl.text:sub(1, math.max(0, text_editor_cursor - cvl.start_idx)))
                        local bd, bi = math.huge, 0
                        local coff = 0
                        while coff <= #nvl.text do
                            local d = math.abs(gfx.measurestr(nvl.text:sub(1, coff)) - rx)
                            if d < bd then bd, bi = d, coff end
                            if coff >= #nvl.text then break end
                            local b = nvl.text:byte(coff + 1)
                            local len = 1
                            if b >= 240 then len = 4 elseif b >= 224 then len = 3 elseif b >= 192 then len = 2 end
                            coff = coff + len
                        end
                        text_editor_cursor = nvl.start_idx + bi
                        if not is_shift then text_editor_sel_anchor = text_editor_cursor end
                    end
                elseif char == 6647396 then -- Home
                    local cur_vi = 1
                    for i, v_line in ipairs(visual_lines) do
                        if text_editor_cursor >= v_line.start_idx and text_editor_cursor <= v_line.start_idx + #v_line.text then
                            cur_vi = i; break
                        end
                    end
                    text_editor_cursor = visual_lines[cur_vi].start_idx
                    if not is_shift then text_editor_sel_anchor = text_editor_cursor end
                elseif char == 1752132965 then -- End
                    local cur_vi = 1
                    for i, v_line in ipairs(visual_lines) do
                        if text_editor_cursor >= v_line.start_idx and text_editor_cursor <= v_line.start_idx + #v_line.text then
                            cur_vi = i; break
                        end
                    end
                    text_editor_cursor = visual_lines[cur_vi].start_idx + #visual_lines[cur_vi].text
                    if not is_shift then text_editor_sel_anchor = text_editor_cursor end
                elseif not is_paste_mod then
                    local unicode_flag = 0x75000000 
                    local cp, is_u = char, false
                    if char >= unicode_flag and char < unicode_flag + 0x1000000 then
                        cp, is_u = char - unicode_flag, true
                    end
                    if is_u or (cp >= 32 and cp ~= 127) then
                        delete_selection()
                        local cs
                        if cp < 0x80 then cs = string.char(cp)
                        elseif cp < 0x800 then cs = string.char(0xC0 + math.floor(cp / 64), 0x80 + (cp % 64))
                        elseif cp < 0x10000 then cs = string.char(0xE0 + math.floor(cp / 4096), 0x80 + math.floor((cp % 4096) / 64), 0x80 + (cp % 64))
                        else cs = string.char(0xF0 + math.floor(cp / 262144), 0x80 + math.floor((cp % 262144) / 4096), 0x80 + math.floor((cp % 4096) / 64), 0x80 + (cp % 64))
                        end
                        text_editor_text = text_editor_text:sub(1, text_editor_cursor) .. cs .. text_editor_text:sub(text_editor_cursor + 1)
                        text_editor_cursor = text_editor_cursor + #cs
                        text_editor_sel_anchor = text_editor_cursor
                        content_changed = true
                    end
                end
            end -- if not handled_history
        end -- for input_queue

        -- Auto-scroll to cursor (Only on input)
        if #input_queue > 0 then
            local cur_v_line_idx = get_cur_vi(text_editor_cursor)
            local cursor_y_rel = (cur_v_line_idx - 1) * line_h
            if cursor_y_rel < text_editor_scroll then
                text_editor_scroll = cursor_y_rel
            elseif cursor_y_rel > text_editor_scroll + text_h - line_h * 2 then
                text_editor_scroll = cursor_y_rel - text_h + line_h * 2
            end
        end
    end -- if input_queue

    if draw_ai_modal(false) then content_changed = true end

    if content_changed then
        record_history()
    end
    
    return true -- Modal is active
end

--- Draw dictionary modal with definitions and synonyms, ГОРОХ
--- @param input_queue table List of key inputs
local function draw_dictionary_modal(input_queue)
    if not dict_modal.show then return end
    
    -- Darken background
    gfx.set(0, 0, 0, 0.85)
    gfx.rect(0, 0, gfx.w, gfx.h, 1)
    
    -- Modal box
    local pad = 0
    local box_x = pad
    local box_y = pad
    local box_w = gfx.w - pad * 2
    local box_h = gfx.h - pad * 2
    
    set_color(UI.C_TAB_INA)
    gfx.rect(box_x, box_y, box_w, box_h, 1)
    
    -- Title
    set_color(UI.C_SEL)
    gfx.setfont(F.lrg, "Comic Sans MS", 35, string.byte('b'))
    gfx.x = box_x + 15
    gfx.y = box_y
    gfx.drawstr(dict_modal.word)
    
    -- Tabs UI
    local categories = {"Тлумачення", "Словозміна", "Синоніми", "Фразеологія"}
    local tab_x = box_x + 15
    local tab_y = box_y + 55
    local tab_w = 115 -- Wider tabs as requested
    local tab_h = 30
    
    gfx.setfont(F.std, "Arial", 16)
    for _, cat in ipairs(categories) do
        local is_sel = (dict_modal.selected_tab == cat)
        local bx = tab_x
        local by = tab_y
        
        -- Tab button
        if is_sel then
            set_color(UI.C_SEL)
            gfx.rect(bx, by, tab_w, tab_h, 1)
            set_color(UI.C_BG)
        else
            set_color(UI.C_TAB_INA)
            gfx.rect(bx, by, tab_w, tab_h, 1)
            set_color({0.5, 0.5, 0.5, 0.5}) -- Border
            gfx.rect(bx, by, tab_w, tab_h, 0)
            set_color(UI.C_TXT)
        end
        
        -- Tab Label
        local tw, th = gfx.measurestr(cat)
        gfx.x = bx + (tab_w - tw) / 2
        gfx.y = by + (tab_h - th) / 2
        gfx.drawstr(cat)
        
        -- Click detection
        if is_mouse_clicked() then
            if gfx.mouse_x >= bx and gfx.mouse_x <= bx + tab_w and
               gfx.mouse_y >= by and gfx.mouse_y <= by + tab_h then
                if dict_modal.selected_tab ~= cat then
                    dict_modal.selected_tab = cat
                    dict_modal.scroll_y = 0
                    dict_modal.target_scroll_y = 0
                    -- Lazy load content for this tab if missing
                    if not dict_modal.content[cat] then
                        dict_modal.content[cat] = fetch_dictionary_category(dict_modal.word, cat)
                    end
                end
            end
        end
        
        tab_x = tab_x + tab_w + 5
    end
    
    -- Content Area
    local content_x = box_x + 15
    local content_y = tab_y + tab_h + 25
    local content_w = box_w - 30
    local content_h = box_h - (content_y - box_y) - 5
    
    gfx.setfont(F.std, "Arial", 17)
    local line_h = gfx.texth + 4
    
    -- Inputs (ESC to close)
    if input_queue then
        for _, char in ipairs(input_queue) do
            if char == 27 then -- ESC
                dict_modal.show = false
            end
        end
    end
    
    -- Mouse wheel for scroll
    if gfx.mouse_wheel ~= 0 then
        dict_modal.target_scroll_y = dict_modal.target_scroll_y + (gfx.mouse_wheel > 0 and 1 or -1) * line_h * 2
        gfx.mouse_wheel = 0
    end
    
    -- Clamp scroll
    if dict_modal.target_scroll_y > 0 then dict_modal.target_scroll_y = 0 end
    if dict_modal.target_scroll_y < -dict_modal.max_scroll then dict_modal.target_scroll_y = -dict_modal.max_scroll end
    
    -- Smooth scroll
    dict_modal.scroll_y = dict_modal.scroll_y + (dict_modal.target_scroll_y - dict_modal.scroll_y) * 0.8
    if math.abs(dict_modal.target_scroll_y - dict_modal.scroll_y) < 0.5 then
        dict_modal.scroll_y = dict_modal.target_scroll_y
    end
    
    -- Draw text within clip
    local cur_y = content_y + dict_modal.scroll_y
    local total_h = 0
    
    local active_content = dict_modal.content[dict_modal.selected_tab]
    
    if active_content and #active_content == 0 then
        set_color({0.5, 0.5, 0.5, 0.5})
        gfx.x = content_x
        gfx.y = content_y + 20
        gfx.drawstr("Нічого немає для " .. dict_modal.selected_tab)
    elseif not active_content then
        set_color({0.5, 0.5, 0.5, 0.5})
        gfx.x = content_x
        gfx.y = content_y + 20
        gfx.drawstr("Немає даних для цієї категорії (або ГОРОХ знову впав).")
    else
        for _, item in ipairs(active_content) do
            if type(item) == "table" and item.is_table then
                -- Render Table with robust Colspan/Rowspan support (Two-Pass)
                local col_w = content_w / item.cols
                local occupancy = {} -- [r][c] = cell_info (shared object)
                local is_start = {} -- [r][c] = bool (true if this r,c is the top-left of the span)
                local row_heights = {}
                
                -- Pass 1: Measurement & Occupancy Map
                for r_idx, grid_row in ipairs(item.rows) do
                    occupancy[r_idx] = occupancy[r_idx] or {}
                    is_start[r_idx] = is_start[r_idx] or {}
                    local l_col = 1
                    local max_row_h = line_h -- Minimum height
                    
                    for _, cell in ipairs(grid_row.cells) do
                        -- Skip occupied logical columns
                        while occupancy[r_idx][l_col] do l_col = l_col + 1 end
                        
                        local cell_w = col_w * cell.colspan
                        local wrapped = wrap_text(cell.text, cell_w - 8)
                        local needed_h = #wrapped * line_h
                        
                        -- Store cell info
                        local cell_info = {
                            text = cell.text,
                            wrapped = wrapped,
                            colspan = cell.colspan,
                            rowspan = cell.rowspan,
                            is_header = cell.is_header or grid_row.is_header
                        }
                        
                        is_start[r_idx][l_col] = true
                        for rr = 0, cell.rowspan - 1 do
                            local target_r = r_idx + rr
                            occupancy[target_r] = occupancy[target_r] or {}
                            is_start[target_r] = is_start[target_r] or {}
                            for cc = 0, cell.colspan - 1 do
                                occupancy[target_r][l_col + cc] = cell_info
                            end
                        end
                        
                        -- Single-row cells define the base row height
                        if cell.rowspan == 1 then
                            if needed_h > max_row_h then max_row_h = needed_h end
                        end
                        
                        l_col = l_col + cell.colspan
                    end
                    row_heights[r_idx] = max_row_h + 20 -- Add extra padding
                end
                
                -- Pass 2: Drawing
                local table_start_y = cur_y
                local row_y_pos = {} -- Stores absolute Y for each row start
                local running_y = table_start_y
                for i, h in ipairs(row_heights) do
                    row_y_pos[i] = running_y
                    running_y = running_y + h
                end
                
                -- Final table height for scroll calc
                local table_total_h = running_y - table_start_y
                
                for r_idx=1, #row_heights do
                    local row_y = row_y_pos[r_idx]
                    local row_h = row_heights[r_idx]
                    
                    -- For each logical column, check if a cell starts here
                    for l_col = 1, item.cols do
                        if is_start[r_idx] and is_start[r_idx][l_col] then
                            local cell = occupancy[r_idx][l_col]
                            local cell_x = content_x + (l_col - 1) * col_w
                            local cell_w = col_w * cell.colspan
                            
                            -- Calculate total height of this spanned cell
                            local total_cell_h = 0
                            for rr = 0, cell.rowspan - 1 do
                                total_cell_h = total_cell_h + (row_heights[r_idx + rr] or 0)
                            end
                            
                            -- Draw ONLY if some part of the spanning cell is visible
                            if row_y + total_cell_h > content_y and row_y < content_y + content_h then
                                -- Background for headers (based on CSS class or full width)
                                local is_span_header = (cell.colspan == item.cols)
                                if cell.is_header or is_span_header then
                                    set_color({1, 1, 1, 0.08}) -- Subtle but visible transparent white
                                    local bg_y = math.max(row_y, content_y)
                                    local bg_h = math.min(row_y + total_cell_h, content_y + content_h) - bg_y
                                    if bg_h > 0 then
                                        gfx.rect(cell_x, bg_y, cell_w, bg_h, 1)
                                    end
                                end

                                -- Draw text with vertical centering within total_cell_h
                                local text_h = #cell.wrapped * line_h
                                local text_y = row_y + (total_cell_h - text_h) / 2
                                
                                set_color(UI.C_TXT)
                                for l_idx, line in ipairs(cell.wrapped) do
                                    local ly = text_y + (l_idx - 1) * line_h
                                    -- Clip individual lines
                                    if ly + line_h > content_y and ly < content_y + content_h then
                                        if is_span_header then
                                            local tw = gfx.measurestr((line:gsub(acute, "")))
                                            gfx.x = cell_x + (cell_w - tw) / 2
                                        else
                                            gfx.x = cell_x + 4
                                        end
                                        gfx.y = ly
                                        draw_text_with_stress_marks(line)
                                   end
                                end
                               
                                -- Draw cell borders (bottom and right separators)
                                set_color({1, 1, 1, 0.1})
                                -- Horizontal line at the bottom of the SPANNED area
                                local line_y = row_y + total_cell_h
                                if line_y > content_y and line_y < content_y + content_h then
                                    gfx.line(cell_x, line_y, cell_x + cell_w, line_y)
                                end
                                -- Vertical line on the right
                                if l_col + cell.colspan - 1 < item.cols then
                                    local vline_x = cell_x + cell_w
                                    local vline_start = math.max(row_y, content_y)
                                    local vline_end = math.min(row_y + total_cell_h, content_y + content_h)
                                    if vline_start < vline_end then
                                        gfx.line(vline_x, vline_start, vline_x, vline_end)
                                    end
                                end
                            end
                        end
                    end
                end
                
                -- Top boundary of the whole table
                set_color({1, 1, 1, 0.1})
                if table_start_y > content_y and table_start_y < content_y + content_h then
                    gfx.line(content_x, table_start_y, content_x + content_w, table_start_y)
                end
                
                cur_y = table_start_y + table_total_h + 48
                total_h = total_h + table_total_h + 48
            else
                -- Render Hierarchical Paragraph (rich segments with indent/header metadata)
                local para_data = item
                local segments = para_data.segments or {}
                local indent = para_data.indent or 0
                local is_header = para_data.is_header or false
                
                -- Indentation offset (24px per level)
                local indent_x = indent * 24
                local effective_w = content_w - indent_x - 100
                
                -- Support legacy string items just in case
                if type(item) == "string" then
                    segments = {{text = item}}
                    indent_x = 0
                end

                local lines_to_draw = wrap_rich_text(segments, effective_w, is_header)

                for _, rich_line in ipairs(lines_to_draw) do
                    if cur_y + line_h > content_y and cur_y < content_y + content_h then
                        local segment_x = content_x + indent_x
                        for _, seg in ipairs(rich_line) do
                            -- Set font per segment
                            if seg.is_bold or (is_header and not seg.is_plain) then
                                gfx.setfont(F.dict_bld)
                            else
                                gfx.setfont(F.dict_std)
                            end
                            
                            gfx.x = segment_x
                            gfx.y = cur_y
                           
                            if seg.is_link then
                                set_color(UI.C_SEL) -- Cyan/Blue for links
                                local sw = gfx.measurestr(seg.text)
                                -- Underline
                                gfx.line(gfx.x, gfx.y + gfx.texth, gfx.x + sw, gfx.y + gfx.texth)
                                
                                -- Click detection
                                if is_mouse_clicked() then
                                    if gfx.mouse_x >= gfx.x and gfx.mouse_x <= gfx.x + sw and
                                       gfx.mouse_y >= gfx.y and gfx.mouse_y < gfx.y + line_h then
                                        -- Trigger new lookup (Lazy)
                                        trigger_dictionary_lookup(seg.word)
                                    end
                                end
                            else
                                set_color(UI.C_TXT)
                            end
                            
                            draw_text_with_stress_marks(seg.text)
                            -- Important: increment must match the measurement logic in wrap_rich_text
                            segment_x = segment_x + gfx.measurestr((seg.text:gsub(acute, "")))
                        end
                   end
                    cur_y = cur_y + line_h
                    total_h = total_h + line_h
                end
                -- Spacing: headers have tighter spacing to their lists
                local spacing = is_header and 4 or 12
                cur_y = cur_y + spacing
                total_h = total_h + spacing
            end
        end
    end
    
    dict_modal.max_scroll = math.max(0, total_h - content_h)
    
    -- Scrollbar
    local abs_scroll = draw_scrollbar(box_x + box_w - 10, content_y, 10, content_h, total_h, content_h, -dict_modal.target_scroll_y)
    dict_modal.target_scroll_y = -abs_scroll
    
    -- Close button
    if btn(box_x + box_w - 100, box_y + box_h - 35, 85, 25, "Закрити") then
        dict_modal.show = false
    end
    
    -- Back button (if history available)
    if #dict_modal.history > 0 then
        if btn(box_x + box_w - 200, box_y + box_h - 35, 85, 25, "Назад") then
            local last = table.remove(dict_modal.history)
            dict_modal.word = last.word
            dict_modal.content = last.content
            dict_modal.selected_tab = last.selected_tab
            dict_modal.scroll_y = last.scroll_y
            dict_modal.target_scroll_y = last.target_scroll_y
        end
    end
    
    -- Also close if clicked outside
    if is_mouse_clicked() then
        if gfx.mouse_x < box_x or gfx.mouse_x > box_x + box_w or
           gfx.mouse_y < box_y or gfx.mouse_y > box_y + box_h then
            dict_modal.show = false
        end
    end

    gfx.setfont(F.std, "Arial", 14)
end

--- Open the text editor modal
--- @param initial_text string Text to edit
--- @param callback function Function to call on save(new_text)
--- @param line_idx number|nil Optional context line index
--- @param all_lines table|nil Optional context all lines
local function open_text_editor(initial_text, callback, line_idx, all_lines)
    text_editor_active = true
    text_editor_text = initial_text or ""
    text_editor_cursor = #text_editor_text
    text_editor_sel_anchor = text_editor_cursor
    text_editor_callback = callback
    text_editor_context_line_idx = line_idx
    text_editor_context_all_lines = all_lines
    
    -- Init History
    text_editor_history = {
        {
            text = text_editor_text,
            cursor = text_editor_cursor,
            anchor = text_editor_sel_anchor
        }
    }
    text_editor_history_pos = 1
end

--- Draw main navigation tabs
local function draw_tabs()
    local btn_scan_w = 30
    local total_tab_w = gfx.w - btn_scan_w
    local tab_w = total_tab_w / #tabs
    local h = 25
    
    for i, name in ipairs(tabs) do
        local x = (i - 1) * tab_w
        local is_act = (current_tab == i)
        
        set_color(is_act and UI.C_TAB_ACT or UI.C_TAB_INA)
        gfx.rect(x, 0, tab_w, h, 1)

        -- Separator
        set_color({0,0,0})
        gfx.line(x+tab_w, 0, x+tab_w, h)
        
        set_color(UI.C_TXT)
        gfx.setfont(F.std)
        local str_w, str_h = gfx.measurestr(name)
        gfx.x = x + (tab_w - str_w) / 2
        gfx.y = (h - str_h) / 2
        gfx.drawstr(name)
        
        -- Click
        if is_mouse_clicked() then
            if gfx.mouse_x >= x and gfx.mouse_x < x+tab_w and gfx.mouse_y >= 0 and gfx.mouse_y <= h then
                -- Save current tab's scroll position
                tab_scroll_y[current_tab] = scroll_y
                tab_target_scroll_y[current_tab] = target_scroll_y
                -- Switch tab
                current_tab = i
                -- Restore new tab's scroll position
                scroll_y = tab_scroll_y[current_tab] or 0
                target_scroll_y = tab_target_scroll_y[current_tab] or 0
            end
        end
    end
    
    -- Jump to Region Button (Small Tab at the end)
    local btn_x = total_tab_w
    
    set_color(UI.C_TAB_INA) -- Use inactive tab color
    gfx.rect(btn_x, 0, btn_scan_w, h, 1)
    
    set_color(UI.C_TXT)
    gfx.setfont(F.std)
    local bw, bh = gfx.measurestr("#")
    
    gfx.x = btn_x + (btn_scan_w - bw)/2
    gfx.y = (h - bh)/2
    gfx.drawstr("#")
    
    if is_mouse_clicked() then
        if gfx.mouse_x >= btn_x and gfx.mouse_x <= gfx.w and
           gfx.mouse_y >= 0 and gfx.mouse_y <= h then
            
            -- Ask for Region Index or Time
            local retval, input = reaper.GetUserInputs("Перейти", 1, "Регіон # або Час (Х:CC):", "")
            if retval and input ~= "" then
                -- Check format
                local clean_input = input:gsub("^#", "")
                
                -- If purely digits, treat as Region Index
                if clean_input:match("^%d+$") then
                    local target_idx = tonumber(clean_input)
                    if target_idx then
                        local num_markers = reaper.CountProjectMarkers(0)
                        for i = 0, num_markers - 1 do
                            local retval, isrgn, pos, rgnend, name, idx = reaper.EnumProjectMarkers(i)
                            if isrgn and idx == target_idx then
                                reaper.SetEditCurPos(pos, true, true)
                                break
                            end
                        end
                    end
                else
                    -- Treat as Time
                    -- Heuristic: If input has NO colon but has dots, assume "2.24" -> "2:24" (mm:ss) style.
                    -- If input HAS colon (e.g. "01:13.82"), respect the dot as decimal.
                    local time_str = clean_input
                    if not time_str:find(":") and time_str:find("%.") then
                         time_str = time_str:gsub("%.", ":")
                    end
                    
                    local pos = reaper.parse_timestr(time_str)
                    if pos >= 0 then
                        reaper.SetEditCurPos(pos, true, true)
                    end
                end
            end
        end
    end
end

--- Handle keyboard input for a text field state
--- @param input_queue table Key inputs
--- @param state table Input state {text, cursor, anchor}
--- @param is_multiline boolean Allow newlines
--- @return boolean True if text changed
local function process_input_events(input_queue, state, is_multiline)
    if not input_queue or #input_queue == 0 then return false end
    
    local cap = gfx.mouse_cap
    local is_ctrl = (cap & 4 == 4)
    local is_cmd = (cap & 32 == 32)
    local is_shift = (cap & 8 == 8)
    local is_paste_mod = (is_ctrl or is_cmd)
    
    local changed = false
    local text = state.text or ""
    local cursor = state.cursor or #text
    local anchor = state.anchor or cursor
    
    local has_sel = (cursor ~= anchor)
    
    local function delete_selection()
        if not has_sel then return end
        local s_min, s_max = math.min(cursor, anchor), math.max(cursor, anchor)
        local before = text:sub(1, s_min)
        local after = text:sub(s_max + 1)
        text = before .. after
        cursor = s_min
        anchor = s_min
        has_sel = false
        changed = true
    end
    
    for _, char in ipairs(input_queue) do
        -- Select All (Ctrl+A / Cmd+A)
        if char == 1 or (is_cmd and (char == 97 or char == 65)) then
            anchor = 0
            cursor = #text
        -- Copy
        elseif (char == 3) or (is_paste_mod and (char == 99 or char == 67)) then
            if has_sel then
                local s_min, s_max = math.min(cursor, anchor), math.max(cursor, anchor)
                set_clipboard(text:sub(s_min + 1, s_max))
            end
        -- Cut
        elseif (char == 24) or (is_paste_mod and (char == 120 or char == 88)) then
            if has_sel then
                local s_min, s_max = math.min(cursor, anchor), math.max(cursor, anchor)
                set_clipboard(text:sub(s_min + 1, s_max))
                delete_selection()
            end
        -- Paste
        elseif (is_paste_mod and (char == 118 or char == 86)) or (char == 22) then
            delete_selection()
            local clipboard = get_clipboard()
            if clipboard and clipboard ~= "" then
                if not is_multiline then clipboard = clipboard:gsub("\n", " "):gsub("\r", "") end
                text = text:sub(1, cursor) .. clipboard .. text:sub(cursor + 1)
                cursor = cursor + #clipboard
                anchor = cursor
                changed = true
            end
        -- Escape / Enter
        elseif char == 27 or char == 13 then
            if char == 13 and is_multiline then
                delete_selection()
                text = text:sub(1, cursor) .. "\n" .. text:sub(cursor + 1)
                cursor = cursor + 1
                anchor = cursor
                changed = true
            else
                state.focus = false
            end
        -- Backspace
        elseif char == 8 then
            if has_sel then
                delete_selection()
            elseif cursor > 0 then
                local before = text:sub(1, cursor)
                local after = text:sub(cursor + 1)
                local last_char_start = cursor
                while last_char_start > 1 do
                    local b = before:byte(last_char_start)
                    if b < 128 or b >= 192 then break end
                    last_char_start = last_char_start - 1
                end
                text = before:sub(1, last_char_start - 1) .. after
                cursor = last_char_start - 1
                anchor = cursor
                changed = true
            end 
        -- Navigation
        elseif char == 30064 then -- Up arrow - go to start
            cursor = 0
            if not is_shift then anchor = cursor end
        elseif char == 1685026670 then -- Down arrow - go to end  
            cursor = #text
            if not is_shift then anchor = cursor end
        elseif char == 1818584692 then -- Left
            if cursor > 0 then
                local cur = cursor
                while cur > 1 do
                    local b = text:byte(cur)
                    if b < 128 or b >= 192 then break end
                    cur = cur - 1
                end
                cursor = cur - 1
                if not is_shift then anchor = cursor end
            end
        elseif char == 1919379572 then -- Right
            if cursor < #text then
                local cur = cursor + 1
                while cur < #text do
                    local b = text:byte(cur + 1)
                    if b < 128 or b >= 192 then break end
                    cur = cur + 1
                end
                cursor = cur
                if not is_shift then anchor = cursor end
            end
        elseif char == 6579564 then -- Home
            cursor = 0
            if not is_shift then anchor = cursor end
        elseif char == 1701734758 then -- End
            cursor = #text
            if not is_shift then anchor = cursor end
        -- Typing (Safe UTF-8)
        elseif not is_paste_mod then
            -- Filter control codes
            if char >= 32 or char < 0 then
                delete_selection()
                local char_str = ""
                
                -- Handle high-bit flags from Reaper if present (unlikely for simple chars but possible)
                local unicode_flag = 0x75000000
                local cp = char
                if cp >= unicode_flag and cp < unicode_flag + 0x1000000 then
                    cp = cp - unicode_flag
                end
                
                -- Full UTF-8 Encode
                if cp < 128 then char_str = string.char(cp)
                elseif cp < 2048 then
                    char_str = string.char(192 + math.floor(cp/64), 128 + (cp % 64))
                elseif cp < 65536 then
                    char_str = string.char(224 + math.floor(cp/4096), 128 + math.floor((cp % 4096)/64), 128 + (cp % 64))
                elseif cp <= 1114111 then
                    char_str = string.char(0xF0 + math.floor(cp/262144), 0x80 + math.floor((cp % 262144)/4096), 0x80 + math.floor((cp % 4096)/64), 0x80 + (cp % 64))
                end
                
                if #char_str > 0 then
                    text = text:sub(1, cursor) .. char_str .. text:sub(cursor + 1)
                    cursor = cursor + #char_str
                    anchor = cursor
                    changed = true
                end
            end
        end
    end
    
    state.text = text
    state.cursor = cursor
    state.anchor = anchor
    return changed
end

-- Helper: Get char index from relative X
local function get_char_index_at_x(text, rel_x)
    if not text or text == "" then return 0 end
    local best_idx = 0
    local best_dist = 1000000
    
    local idx = 0
    while idx <= #text do
        local w = gfx.measurestr(text:sub(1, idx))
        local dist = math.abs(w - rel_x)
        if dist < best_dist then
            best_dist = dist
            best_idx = idx
        end
        
        if idx >= #text then break end
        
        -- Advance utf8
        local b = text:byte(idx + 1)
        local adv = 1
        if b then
            if b >= 240 then adv = 4
            elseif b >= 224 then adv = 3
            elseif b >= 192 then adv = 2
            end
        end
        idx = idx + adv
    end
    return best_idx
end

local function ui_text_input(x, y, w, h, state, placeholder, input_queue, is_multiline)
    -- Background
    set_color(state.focus and UI.C_BG or UI.C_TAB_INA)
    gfx.rect(x, y, w, h, 1)
    
    -- Border
    set_color(state.focus and {0.7, 0.7, 1.0} or UI.C_BTN_H)
    gfx.rect(x, y, w, h, 0)
    
    -- Interaction
    local hover = (gfx.mouse_x >= x and gfx.mouse_x <= x + w and gfx.mouse_y >= y and gfx.mouse_y <= y + h)
    
    if gfx.mouse_cap == 1 then
        if last_mouse_cap == 0 and hover then
            -- CLICK
            state.focus = true
            local rel_x = gfx.mouse_x - (x + 5)
            local idx = get_char_index_at_x(state.text, rel_x)
            
            local now = reaper.time_precise()
            if (now - (state.last_click_time or 0)) < 0.3 then
                state.last_click_state = (state.last_click_state or 0) + 1
            else
                state.last_click_state = 1
            end
            state.last_click_time = now
            
            if state.last_click_state == 1 then
                -- Single Click
                state.cursor = idx
                state.anchor = idx
            elseif state.last_click_state == 2 then
                -- Double Click (Word)
                local s, e = idx, idx
                -- Scan back
                while s > 0 do
                    local c = state.text:sub(s, s)
                    if c:match("[%s%p]") then break end
                    s = s - 1
                end
                -- Scan forward
                while e < #state.text do
                    local c = state.text:sub(e+1, e+1)
                    if c:match("[%s%p]") then break end
                    e = e + 1
                end
                state.cursor = e
                state.anchor = s
            elseif state.last_click_state >= 3 then
                -- Triple Click (All)
                state.cursor = #state.text
                state.anchor = 0
            end
            
        elseif state.focus and hover and last_mouse_cap == 1 then
            -- DRAG (only if focused)
            if state.last_click_state == 1 then -- Only drag if single clicked
                local rel_x = gfx.mouse_x - (x + 5)
                state.cursor = get_char_index_at_x(state.text, rel_x)
            end
        elseif not hover and last_mouse_cap == 0 then
            state.focus = false
        end
    end
    
    if state.focus then
        process_input_events(input_queue, state, is_multiline)
    end
    
    -- Render Text
    set_color(UI.C_TXT)
    gfx.setfont(F.std)
    gfx.x = x + 5
    gfx.y = y + 5
    
    local display_text = state.text
    if #display_text == 0 and not state.focus then
        set_color({0.5, 0.5, 0.5})
        gfx.drawstr(placeholder or "")
    else
        -- Draw Selection
        if state.focus and state.cursor ~= state.anchor then
            local s_min, s_max = math.min(state.cursor, state.anchor), math.max(state.cursor, state.anchor)
            local before = display_text:sub(1, s_min)
            local sel = display_text:sub(s_min + 1, s_max)
            
            local w_before = gfx.measurestr(before)
            local w_sel = gfx.measurestr(sel)
            
            set_color({0.3, 0.3, 0.5}) -- Selection Blue
            gfx.rect(x + 5 + w_before, y + 3, w_sel, h - 6, 1)
            set_color(UI.C_TXT)
        end
        
        gfx.drawstr(display_text)
        
        -- Draw Cursor (blink faster)
        if state.focus and (math.floor(reaper.time_precise() * 2) % 2 == 0) then
            local pre_cursor = display_text:sub(1, state.cursor)
            local cx = x + 5 + gfx.measurestr(pre_cursor)
            set_color(UI.C_TXT)
            gfx.line(cx, y + 3, cx, y + h - 3)
        end
    end
end

--- Tabs Views ---
local last_file_h = 0
--- Draw the detailed file view with import buttons and actor stats
local function draw_file()
    local start_y = 50
    local avail_h = gfx.h - start_y
    local max_scroll = math.max(0, last_file_h - avail_h)
    
    -- Smooth Scroll Logic
    if gfx.mouse_wheel ~= 0 then
        target_scroll_y = target_scroll_y - (gfx.mouse_wheel * 0.25)
        if target_scroll_y < 0 then target_scroll_y = 0 end
        if target_scroll_y > max_scroll then target_scroll_y = max_scroll end
        gfx.mouse_wheel = 0
    end
    
     local diff = target_scroll_y - scroll_y
    if math.abs(diff) > 0.5 then
        scroll_y = scroll_y + (diff * 0.2)
    else
        scroll_y = target_scroll_y
    end
    
    if scroll_y < 0 then scroll_y = 0 end
    if scroll_y > max_scroll then scroll_y = max_scroll end

    local function get_y(offset)
        return start_y + offset - math.floor(scroll_y)
    end
    
    -- Content
    local y_cursor = 0
    
    -- Import Button (unified for .srt, .ass, and .vtt)
    local b_y = get_y(y_cursor)
    if b_y + 40 > start_y and b_y < gfx.h then
        if btn(20, b_y, 230, 40, "Імпорт субтитрів (.srt/.ass/.vtt)") then
            local retval, file = reaper.GetUserFileNameForRead("", "Імпорт субтитрів", "*.srt;*.ass;*.vtt")
            if retval and file then
                local ext = file:match("%.([^.]+)$")
                if ext then
                    ext = ext:lower()
                    if ext == "srt" then
                        import_srt(file)
                    elseif ext == "ass" then
                        import_ass(file)
                    elseif ext == "vtt" then
                        import_vtt(file)
                    else
                        show_snackbar("Непідтримуваний формат файлу")
                    end
                end
            end
        end
        
        -- Import Notes Button (Top-right corner)
        local notes_btn_w = 80
        local notes_btn_x = gfx.w - notes_btn_w - 20
        if btn(notes_btn_x, b_y, notes_btn_w, 40, "Правки") then
            gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
            local ret = gfx.showmenu("Імпорт з тексту|Імпорт з файлу (CSV)")
            if ret == 1 then
                import_notes()
            elseif ret == 2 then
                import_notes_from_csv()
            end
        end
        
        -- Filename Display (Next to import button)
        if ass_file_loaded and current_file_name then
            gfx.setfont(F.std)
            set_color(UI.C_TXT)
            -- Vertical center relative to button
            local str = "Обрано: " .. current_file_name
            local max_width = notes_btn_x - 265 - 10 -- Space between subtitle button and notes button
            str = fit_text_width(str, max_width)
            gfx.x = 265
            gfx.y = b_y + (40 - gfx.texth) / 2
            gfx.drawstr(str)
        end
    end
    y_cursor = y_cursor + 80
    
    -- Actor Filter (if loaded)
    if ass_file_loaded then
        local t_y = get_y(y_cursor)
        if t_y + 20 > start_y and t_y < gfx.h then
            set_color(UI.C_TXT)
            gfx.setfont(F.std)
            gfx.x, gfx.y = 20, t_y
            gfx.drawstr("Фільтр акторів:")
            
            -- Batch Select (left side)
            if btn(130, t_y - 2, 120, 20, "Швидкий вибір", UI.C_ROW) then
                local ret, csv = reaper.GetUserInputs("Швидкий вибір акторів", 1, "Список акторів (через кому):,extrawidth=200", "")
                if ret then
                    push_undo("Швидкий вибір акторів")
                    -- Deselect all first
                    for k in pairs(ass_actors) do ass_actors[k] = false end
                    for _, l in ipairs(ass_lines) do l.enabled = false end
                    -- Parse CSV and enable matching
                    local selected = {}
                    for act_name in csv:gmatch("([^,]+)") do
                        act_name = act_name:match("^%s*(.-)%s*$") -- trim
                        if ass_actors[act_name] ~= nil then
                            ass_actors[act_name] = true
                            selected[act_name] = true
                        end
                    end
                    for _, l in ipairs(ass_lines) do
                        if selected[l.actor] then l.enabled = true end
                    end
                    rebuild_regions()
                end
            end
            
            -- Right side layout: [count text] [None] [All]
            local selected_count = 0
            local total_count = 0
            for _, v in pairs(ass_actors) do
                total_count = total_count + 1
                if v then selected_count = selected_count + 1 end
            end
            local count_text = selected_count .. "/" .. total_count
            set_color(UI.C_TXT)
            gfx.setfont(F.std)
            
            -- Calculate positions from right edge
            local right_edge = gfx.w - 30
            local all_btn_x = right_edge - 40
            local none_btn_x = all_btn_x - 75
            local tw = gfx.measurestr(count_text)
            local count_x = none_btn_x - tw - 15
            
            -- Draw count text
            gfx.x = count_x
            gfx.y = t_y
            gfx.drawstr(count_text)
            
            -- None button
            if btn(none_btn_x, t_y - 2, 70, 20, "НІКОГО", UI.C_ROW) then
                push_undo("Приховати всіх")
                for k in pairs(ass_actors) do ass_actors[k] = false end
                for _, l in ipairs(ass_lines) do l.enabled = false end
                rebuild_regions()
            end
            
            -- All button
            if btn(all_btn_x, t_y - 2, 50, 20, "ВСІ", UI.C_ROW) then
                push_undo("Показати всіх")
                for k in pairs(ass_actors) do ass_actors[k] = true end
                for _, l in ipairs(ass_lines) do l.enabled = true end
                rebuild_regions()
            end
        end

        y_cursor = y_cursor + 35
        
        -- Sort actors for consistent display
        local sorted_actors = {}
        for act in pairs(ass_actors) do table.insert(sorted_actors, act) end
        table.sort(sorted_actors)
        
        -- AUTO-GRID CALCULATION
        local item_w = 150 -- Min width per item
        local cols = math.floor((gfx.w - 40) / item_w)
        if cols < 1 then cols = 1 end
        
        -- Calculate rows needed
        local row_count = math.ceil(#sorted_actors / cols)
        
        for i, act in ipairs(sorted_actors) do
            -- Grid Indexing (0-based for math)
            local idx = i - 1
            local col = idx % cols
            local row = math.floor(idx / cols)
            
            local x_pos = 20 + (col * item_w)
            local y_rel = y_cursor + (row * 30) -- 30px per row
            local chk_y = get_y(y_rel)
            
            if chk_y + 20 > start_y and chk_y < gfx.h then
                local enabled = ass_actors[act]
                
                -- Checkbox
                -- Use actor color for visual feedback
                local a_col = get_actor_color(act)

                if not cfg.random_color_actors then
                    a_col = 2500134 -- Default color {0.15, 0.15, 0.15}
                end

                local native_r, native_g, native_b = reaper.ColorFromNative(a_col & 0xFFFFFF)
                
                -- Draw filled background with actor color (dimmed slightly?)
                -- Or stroke? Let's do filled for visibility.
                if enabled then
                    set_color({native_r/255, native_g/255, native_b/255})
                    gfx.rect(x_pos, chk_y, 20, 20, 1) -- Filled

                    set_color({0.5, 0.5, 0.5})
                    gfx.rect(x_pos, chk_y, 20, 20, 0)
                    
                    -- Checkmark (Contrast color? Black or White depending on luminance)
                    local lum = (native_r * 0.299 + native_g * 0.587 + native_b * 0.114) / 255
                    if lum > 0.5 then set_color({0,0,0}) else set_color({1,1,1}) end
                else
                    -- Disabled: Grey outline
                    set_color({0.5, 0.5, 0.5})
                    gfx.rect(x_pos, chk_y, 20, 20, 0) -- Outline
                    
                    -- Small indicator of their color inside?
                    set_color({native_r/255, native_g/255, native_b/255})
                    gfx.rect(x_pos + 6, chk_y + 6, 8, 8, 1)
                end

                if enabled then
                    -- Checkmark (tick)
                    -- Left stroke (shorter)
                    gfx.line(x_pos + 4, chk_y + 10, x_pos + 8, chk_y + 16)
                    gfx.line(x_pos + 5, chk_y + 10, x_pos + 9, chk_y + 16) -- Bold
                    
                    -- Right stroke (longer)
                    gfx.line(x_pos + 8, chk_y + 16, x_pos + 16, chk_y + 4)
                    gfx.line(x_pos + 9, chk_y + 16, x_pos + 17, chk_y + 4) -- Bold
                end
                
                -- Label (Truncate if too long)
                set_color(UI.C_TXT)
                gfx.x, gfx.y = x_pos + 25, chk_y + 2
                
                local max_txt_w = item_w - 30 -- padding
                local display_act = fit_text_width(act, max_txt_w)
                
                gfx.drawstr(display_act, 4 | 256, x_pos + item_w - 5, chk_y + 20)
            
                -- Click Logic
                if is_mouse_clicked() then
                    -- Hit test
                    if gfx.mouse_x >= x_pos and gfx.mouse_x <= x_pos + item_w - 5 and
                       gfx.mouse_y >= chk_y and gfx.mouse_y <= chk_y + 20 then
                        push_undo("Зміна видимості актора " .. act)
                        local new_state = not enabled
                        ass_actors[act] = new_state
                        -- Batch update all lines for this actor
                        for _, l in ipairs(ass_lines) do
                            if l.actor == act then l.enabled = new_state end
                        end
                        rebuild_regions()
                    end
                elseif is_right_mouse_clicked() then
                    -- Right-click hit test for actor management menu
                    if gfx.mouse_x >= x_pos and gfx.mouse_x <= x_pos + item_w - 5 and
                       gfx.mouse_y >= chk_y and gfx.mouse_y <= chk_y + 20 then
                        
                        gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
                        local ret = gfx.showmenu("Змінити колір|Змінити ім'я актора|Видалити актора")
                        if ret == 1 then
                            -- Handle Scheduled Color Picker (Move from main to draw_file)
                            local current_native = get_actor_color(act)

                            if current_native == 0 then current_native = 2500134 end
                            local retval, color = reaper.GR_SelectColor(reaper.GetMainHwnd(), current_native)
                            if retval > 0 then
                                actor_colors[act] = color | 0x1000000
                                cfg.random_color_actors = true
                                rebuild_regions()
                                save_project_data()
                            end
                        elseif ret == 2 then
                            local ok, new_name = reaper.GetUserInputs("Зміна імені актора", 1, "Нове ім'я:,extrawidth=200", act)
                            if ok then
                                push_undo("Зміна імені актора")
                                -- Update lines
                                for _, l in ipairs(ass_lines) do
                                    if l.actor == act then l.actor = new_name end
                                end
                                -- Update actors state
                                local state = ass_actors[act]
                                ass_actors[act] = nil
                                ass_actors[new_name] = (state ~= nil) and state or true
                                -- Update color
                                if actor_colors[act] then
                                    actor_colors[new_name] = actor_colors[act]
                                    actor_colors[act] = nil
                                end
                                cleanup_actors()
                                rebuild_regions()
                                save_project_data()
                            end
                        elseif ret == 3 then
                            local confirm = reaper.MB("Видалити актора '" .. act .. "' і всі його репліки?", "Підтвердження", 4)
                            if confirm == 6 then
                                push_undo("Видалення актора " .. act)
                                
                                -- Remove from actors list
                                ass_actors[act] = nil
                                actor_colors[act] = nil
                                
                                -- Remove all lines for this actor
                                for i = #ass_lines, 1, -1 do
                                    if ass_lines[i].actor == act then
                                        table.remove(ass_lines, i)
                                    end
                                end
                                
                                cleanup_actors()
                                rebuild_regions()
                                save_project_data()
                            end
                        end
                        mouse_handled = true -- Suppress global context menu
                    end
                end
            end
        end
        
        y_cursor = y_cursor + (row_count * 30) + 20


        -- Statistics: Count Replicas and Words for Selected Actors
        local stats_replicas = 0
        local stats_words = 0
        
        for _, line in ipairs(ass_lines) do
            if line.enabled then
                stats_replicas = stats_replicas + 1
                -- Word count: Strip tags, convert breaks to spaces, count non-whitespace chunks
                local clean = (line.text or ""):gsub("{.-}", ""):gsub("\\[Nnh]", " ")
                local _, count = clean:gsub("%S+", "")
                stats_words = stats_words + count
            end
        end
        
        local stats_y = get_y(y_cursor)
        if stats_y + 40 > start_y and stats_y < gfx.h then
            set_color(UI.C_TXT)
            gfx.setfont(F.std)
            gfx.x = 20
            gfx.y = stats_y
            gfx.drawstr("Обрано: " .. stats_replicas .. " реплік, " .. stats_words .. " слів")
        end
        y_cursor = y_cursor + 45

        -- Apply Stress Marks Button
        local s_y = get_y(y_cursor)
        if s_y + 25 > start_y and s_y < gfx.h then
            if btn(20, s_y, gfx.w - 40, 40, ">  Застосувати наголоси  <", UI.C_TAB_ACT) then
                push_undo("Застосування наголосів")
                apply_stress_marks()
            end
        end
        y_cursor = y_cursor + 50
    else
        -- Default text
        local t_y = get_y(y_cursor)
        if t_y + 20 > start_y and t_y < gfx.h then
            gfx.setfont(F.std)
            gfx.x, gfx.y = 20, t_y
            gfx.drawstr("Імпортуй файл аби побачити більше опцій.")
        end
        y_cursor = y_cursor + 30
    end
    
    -- Drop Zone Visual
    local drop_y = get_y(y_cursor)
    if drop_y + 60 > start_y and drop_y < gfx.h then
        local dw = gfx.w - 40
        local dh = 60
        local dx = 20
        
        -- Dashed Border
        set_color({0.5, 0.5, 0.5, 0.3})
        for dash_x = dx, dx + dw - 10, 10 do
            gfx.line(dash_x, drop_y, dash_x + 5, drop_y)
            gfx.line(dash_x, drop_y + dh, dash_x + 5, drop_y + dh)
        end
        for dash_y = drop_y, drop_y + dh - 10, 10 do
            gfx.line(dx, dash_y, dx, dash_y + 5)
            gfx.line(dx + dw, dash_y, dx + dw, dash_y + 5)
        end
        
        -- Text
        set_color({0.5, 0.5, 0.5, 0.6})
        gfx.setfont(F.std)
        local str = "Перетягніть .SRT, .ASS, .VTT або .CSV (правки) файл сюди для імпорту"
        local sw, sh = gfx.measurestr(str)
        gfx.x, gfx.y = dx + (dw - sw) / 2, drop_y + (dh - sh) / 2
        gfx.drawstr(str)
    end
    y_cursor = y_cursor + 80

    last_file_h = y_cursor
    
    -- Scrollbar
    target_scroll_y = draw_scrollbar(gfx.w - 10, start_y, 10, avail_h, last_file_h, avail_h, target_scroll_y)
end

-- =============================================================================
-- UI: PROMPTER TAB (MAIN SUBTITLE DISPLAY)
-- =============================================================================
-- =============================================================================
-- KARAOKE MODE HELPERS
-- =============================================================================

local karaoke_cache = {} -- Cache for energy maps: [region_id] = {total_energy, points={{t, cum_energy}...}}
local KARAOKE_SAMPLES_PER_SEC = 20 -- 50ms resolution

--- Find the first track that is not muted and has items
--- @return MediaTrack|nil The track object or nil
local function get_first_valid_audio_track()
    local count = reaper.CountTracks(0)
    for i = 0, count - 1 do
        local tr = reaper.GetTrack(0, i)
        local mute = reaper.GetMediaTrackInfo_Value(tr, "B_MUTE")
        -- Simple heuristic: if not muted and has items
        if mute == 0 and reaper.CountTrackMediaItems(tr) > 0 then
            return tr
        end
    end
    return nil
end

--- Collect audio energy (RMS) map for a time range
--- @param start_time number Region start time
--- @param end_time number Region end time
--- @return table|nil Map of energy points {total, points={{t,e,cum}}}
local function get_audio_energy_map(start_time, end_time)
    local tr = get_first_valid_audio_track()
    if not tr then return nil end

    local duration = end_time - start_time
    if duration <= 0 then return nil end
    
    local sample_points = math.floor(duration * KARAOKE_SAMPLES_PER_SEC)
    if sample_points < 1 then sample_points = 1 end
    
    local step_size = duration / sample_points
    
    -- We need to access audio. 
    -- Since we can't easily access "track output" directly without playing, 
    -- we have to iterate items on the track that overlap this range.
    -- For simplicity/performance, let's assume one item or just scan the track logic 
    -- using a specialized function if possible, but Lua API for "render track audio" is complex.
    -- ALTERNATIVE: Use GetMediaItemTake_Peaks? Or AudioAccessor on specific takes.
    -- Let's iterate items in range.
    
    local mapping = {}
    local total_energy = 0
    
    -- Pre-fill mapping with time points
    for i = 0, sample_points - 1 do
        mapping[i+1] = {
            t = start_time + (i * step_size),
            e = 0, 
            cum = 0
        }
    end
    
    local item_count = reaper.CountTrackMediaItems(tr)
    for i = 0, item_count - 1 do
        local item = reaper.GetTrackMediaItem(tr, i)
        local i_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local i_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local i_end = i_pos + i_len
        
        -- Check overlap
        if i_end > start_time and i_pos < end_time then
            local take = reaper.GetActiveTake(item)
            if take and not reaper.TakeIsMIDI(take) then
                local aa = reaper.CreateTakeAudioAccessor(take)
                local src = reaper.GetMediaItemTake_Source(take)
                local src_sr = reaper.GetMediaSourceSampleRate(src)
                if src_sr == 0 then src_sr = 44100 end
                local num_channels = reaper.GetMediaSourceNumChannels(src)
                
                -- Rate mapping
                local play_rate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
                local start_offs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
                
                -- Iterate our sample points
                for k, point in ipairs(mapping) do
                    if point.t >= i_pos and point.t < i_end then
                        local time_in_item = point.t - i_pos
                        local time_in_take = start_offs + (time_in_item * play_rate)
                        
                        -- Read a small chunk (approx step_size)
                        local buf_size = math.ceil(step_size * src_sr) 
                        -- Limit buffer for performance (don't read massive chunks if step is huge)
                        if buf_size > 2048 then buf_size = 2048 end
                        
                        local buffer = reaper.new_array(buf_size * num_channels)
                        local ret = reaper.GetAudioAccessorSamples(aa, src_sr, num_channels, time_in_take, buf_size, buffer)
                        
                        if ret > 0 then
                            local sum_sq = 0
                            local count_s = 0
                            for s_idx = 1, #buffer do
                                local s = buffer[s_idx]
                                sum_sq = sum_sq + (s * s)
                                count_s = count_s + 1
                            end
                            if count_s > 0 then
                                local rms = math.sqrt(sum_sq / count_s)
                                point.e = point.e + rms -- Accumulate if overlapping items? rare but ok
                            end
                        end
                    end
                end
                
                reaper.DestroyAudioAccessor(aa)
            end
        end
    end
    
    -- Integrate energy and calculate dynamic noise floor
    local all_energies = {}
    local non_zero_sum = 0
    local non_zero_count = 0
    for _, point in ipairs(mapping) do
        table.insert(all_energies, point.e)
    end
    
    -- Calculate noise floor (e.g. 20th percentile)
    table.sort(all_energies)
    local floor_idx = math.max(1, math.floor(#all_energies * 0.20))
    local noise_floor = all_energies[floor_idx] or 0
    if noise_floor < 0.05 then noise_floor = 0.05 end
    
    -- Step 1: Subtract noise floor and collect adjusted energy
    local adj_energies = {}
    for i, point in ipairs(mapping) do
        local e_adj = math.max(0, point.e - noise_floor)
        adj_energies[i] = e_adj
        if e_adj > 0 then
            non_zero_sum = non_zero_sum + e_adj
            non_zero_count = non_zero_count + 1
        end
    end
    
    -- Step 2: Peak Limiting (Cap individual points to prevent jumps on loud plosives)
    local avg_e = (non_zero_count > 0) and (non_zero_sum / non_zero_count) or 0
    local peak_cap = avg_e * 2.5 -- Slightly tighter cap for more consistency
    if peak_cap < 0.15 then peak_cap = 0.15 end
    
    for i = 1, #adj_energies do
        if adj_energies[i] > peak_cap then
            adj_energies[i] = peak_cap
        end
    end

    -- Step 3: Extra Temporal Smoothing (5-point moving average for "liquid" feel)
    local smoothed = {}
    for i = 1, #adj_energies do
        local sum = 0
        local count = 0
        -- Look 2 points back and 2 points forward
        for j = i - 2, i + 2 do
            if adj_energies[j] then
                sum = sum + adj_energies[j]
                count = count + 1
            end
        end
        smoothed[i] = sum / count
    end
    
    -- Step 4: Add Bias (Ensures constant slow flow even during silence)
    -- This prevents the "stuck" feeling during gaps.
    local bias = avg_e * 0.2 -- 20% of average speech energy as a constant floor
    if bias < 0.01 then bias = 0.01 end

    -- Final integration
    total_energy = 0
    for i, point in ipairs(mapping) do
        point.e = smoothed[i] + bias
        total_energy = total_energy + point.e
        point.cum = total_energy
    end
    
    return {
        total = total_energy,
        points = mapping
    }
end

--- Calculate current word index based on audio energy
--- @param rgn_start number Region start
--- @param rgn_end number Region end
--- @param cur_pos number Current playhead position
--- @param word_count number Total words in line
--- @return number Current word index (1-based)
local function get_karaoke_word_index(rgn_start, rgn_end, cur_pos, word_count)
    if word_count <= 1 then return 1 end
    
    -- Cache Key: region start/end (simple)
    local cache_key = tostring(rgn_start) .. "_" .. tostring(rgn_end)
    local map = karaoke_cache[cache_key]
    
    if not map then
        -- Generate map
        map = get_audio_energy_map(rgn_start, rgn_end)
        if not map or map.total <= 0.0001 then
            -- Fallback or empty audio
            -- Return nil to trigger linear fallback? Or just handle as linear.
            karaoke_cache[cache_key] = { empty = true }
             return nil
        end
        karaoke_cache[cache_key] = map
    elseif map.empty then
        return nil -- Fallback to linear
    end
    
    -- Find current cumulative energy
    local current_energy = 0
    local found = false
    
    -- Binary search or simple loop? Simple loop is fast enough for ~100 points
    local points = map.points
    if not points then return nil end
    
    -- Optimization: points are sorted by time
    -- Find point closest to cur_pos
    for i = 1, #points do
        if points[i].t >= cur_pos then
            current_energy = points[i].cum
            found = true
            break
        end
    end
    
    if not found then 
        -- Past the end?
        if cur_pos >= rgn_end then current_energy = map.total end
    end
    
    local energy_per_word = map.total / word_count
    local idx = math.floor(current_energy / energy_per_word) + 1
    if idx > word_count then idx = word_count end
    
    return idx
end

--- Draw ambient audio waveform background
--- @param map table Energy map from get_audio_energy_map
--- @param x number X pos
--- @param y number Y pos
--- @param w number Width
--- @param h number Height
--- @param progress number 0.0-1.0 Completion progress
local function draw_waveform_bg(map, x, y, w, h, progress)
    if not map or not map.points or #map.points < 2 then return end
    
    -- Save color
    local orig_r, orig_g, orig_b, orig_a = gfx.r, gfx.g, gfx.b, gfx.a

    local points = map.points
    local n_points = #points
    local step_x = w / n_points
    
    -- Find max energy to normalize
    local max_e = 0.0001
    for i = 1, n_points do
        if points[i].e > max_e then max_e = points[i].e end
    end
    
    local center_y = y + h / 2
    local half_h = h * 0.75
    
    -- Draw continuous filled symmetric wave using triangles
    for i = 1, n_points - 1 do
        -- Determine alpha based on progress (Requested: past part 0.05, future part 0.035)
        local segment_progress = i / n_points
        local alpha = 0.025
        if cfg.wave_bg_progress and segment_progress <= (progress or 0) then
            alpha = 0.04
        end
        gfx.set(cfg.p_cr, cfg.p_cg, cfg.p_cb, alpha)

        local e1 = points[i].e / max_e
        local e2 = points[i+1].e / max_e
        
        local px1 = 1 + x + (i-1) * step_x
        local px2 = x + i * step_x
        
        local ph1 = e1 * half_h
        local ph2 = e2 * half_h
        
        -- Top Trapezoid
        gfx.triangle(px1, center_y, px2, center_y, px2, center_y - ph2, px1, center_y - ph1)
        -- Bottom Trapezoid
        gfx.triangle(px1, center_y + 1, px2, center_y, px2, center_y + ph2, px1, center_y + ph1)
    end
    
    -- Restore
    gfx.set(orig_r, orig_g, orig_b, orig_a)
end

--- Draw prompter display with current and next subtitles
local function draw_prompter()
    -- Draw Custom Background
    set_color({cfg.bg_cr, cfg.bg_cg, cfg.bg_cb})
    gfx.rect(0, 0, gfx.w, gfx.h, 1)

    -- Logic: Use Play Position if playing, otherwise Edit Cursor
    local play_state = reaper.GetPlayState()
    local cur_pos = 0
    if (play_state & 1) == 1 then
        cur_pos = reaper.GetPlayPosition()
    else
        cur_pos = reaper.GetCursorPosition()
    end

    -- Find ALL regions that contain the current position
    local active_regions = {}
    local next_rgn = nil
    local prev_rgn_end = 0
    for _, rgn in ipairs(regions) do
        if cur_pos >= rgn.pos and cur_pos < rgn.rgnend then
            table.insert(active_regions, rgn)
        end
        if rgn.pos > cur_pos then
            if not next_rgn or rgn.pos < next_rgn.pos then
                next_rgn = rgn
            end
        end
        if rgn.rgnend <= cur_pos then
            if rgn.rgnend > prev_rgn_end then
                prev_rgn_end = rgn.rgnend
            end
        end
    end

    -- CPS Warning Strip
    if cfg.cps_warning then
        local max_cps = 0
        local regions_to_check = active_regions
        
        -- If no active regions, check the next available region
        if #active_regions == 0 and next_rgn then
             regions_to_check = {next_rgn}
        end

        if #regions_to_check > 0 then
            for _, rgn in ipairs(regions_to_check) do
                local dur = rgn.rgnend - rgn.pos
                if dur > 0 then
                    -- Strip formatting for accurate char count
                    local clean_text = rgn.name:gsub("{.-}", ""):gsub("\\N", ""):gsub("\n", ""):gsub(" ", ""):gsub(acute, "")
                    -- Use utf8.len
                    local char_count = utf8.len(clean_text) or #clean_text
                    local cps = char_count / dur
                    if cps > max_cps then max_cps = cps end
                end
            end

            if max_cps >= 15 then
                local col = get_cps_color(max_cps)
                set_color({col[1], col[2], col[3], 0.8})
                gfx.rect(0, 25, gfx.w, 2, 1) -- Top warning strip
            end
        end
    end
    
    -- --- HELPER: Draw Rich Line ---
    -- returns x, y, w, h
    -- line is { {text="foo", b=true, ...}, ... }
    
    local function draw_rich_line(line_spans, center_x, y_base, font_slot, font_name, base_size)
    
        -- ASSIMILATION LOGIC
        if cfg.text_assimilations then
            local rules = {
                {"ться", "цця"},
                {"зш", "шш"},
                {"сш", "шш"},
                {"зч", "чч"},
                {"стч", "шч"},
                {"сч", "чч"},
                {"тч", "чч"},
                {"дч", "чч"},
                {"шся", "сся"},
                {"чся", "цся"},
                {"зж", "жж"},
                {"чці", "цці"},
                {"жці", "зці"},
                {"стд", "зд"},
                {"стці", "сці"},
                {"нтст", "нст"},
                {"стськ", "сськ"},
                {"нтськ", "нськ"},
                {"стс", "сс"},
                {"тс", "ц"},
            }
             
            local new_spans = {}
             
            local function process_text(text, style_span, orig_word)
                if text == "" then return end
                
                local best_pos = nil
                local best_rule = nil
                
                -- Case Insensitive Search
                local l_text = utf8_lower(text)
                
                -- Find first occurring rule
                for _, r in ipairs(rules) do
                    local p = l_text:find(r[1], 1, true)
                    if p then
                        if not best_pos or p < best_pos then
                            best_pos = p
                            best_rule = r
                        end
                    end
                end
                
                if best_pos then
                    -- Split: Before, Replacement, After
                    local before = text:sub(1, best_pos - 1)
                    
                    local match_len = #best_rule[1]
                    local original_match = text:sub(best_pos, best_pos + match_len - 1)
                    local remainder = text:sub(best_pos + match_len)
                    
                    -- Determine replacement case
                    local replacement = best_rule[2]
                    if original_match == utf8_upper(original_match) then
                        replacement = utf8_upper(replacement)
                    elseif original_match == utf8_capitalize(utf8_lower(original_match)) then
                        replacement = utf8_capitalize(replacement)
                    end
                    
                    -- Add Before
                    if before ~= "" then
                        table.insert(new_spans, {text=before, b=style_span.b, i=style_span.i, u=style_span.u, s=style_span.s, orig_word=orig_word})
                    end
                    
                    -- Add Replacement (forcing Wavy Underline)
                    table.insert(new_spans, {
                        text = replacement, 
                        b=style_span.b, 
                        i=style_span.i, 
                        u=false, -- standard underline OFF
                        u_wave=true, -- Wavy underline ON
                        s=style_span.s,
                        orig_word=orig_word
                    })
                    
                    -- Process Remainder
                    process_text(remainder, style_span, orig_word)
                else
                    -- No matches, keep as is
                    table.insert(new_spans, {text=text, b=style_span.b, i=style_span.i, u=style_span.u, s=style_span.s, orig_word=orig_word})
                end
            end

            for _, span in ipairs(line_spans) do
                -- Process word by word to keep original context
                local segments = get_words_and_separators(span.text)
                for _, seg in ipairs(segments) do
                    if seg.is_word and (not dict_modal.show) then
                        process_text(seg.text, span, seg.text:gsub(acute, ""))
                    else
                        table.insert(new_spans, {text=seg.text, b=span.b, i=span.i, u=span.u, s=span.s})
                    end
                end
            end
             
            line_spans = new_spans
        end
        
        -- 1. Measure Total Width
        local total_w = 0
        for _, span in ipairs(line_spans) do
            -- Build flags: 'b' is usually handled by font selection or separate font ID,
            -- but 'i' implies italics. 
            -- Reaper GFX flags: 'b' (bold)=? No standard flag for Bold in `setfont`, 
            -- normally you load "Arial Bold" etc. 
            -- But we can simulate or use flag 'BI' strings if supported? No, setfont takes (id, face, size, flags).
            -- Flags: 'b', 'i' works on Windows usually.
            
            local f_flags = 0
            local effective_font = font_name
            
            -- Stable layout for Karaoke: measure ALL words as bold to prevent shifting
            local measure_bold = span.b
            if cfg.karaoke_mode and (font_slot == F.lrg or font_slot == F.nxt) then
                measure_bold = true
            end

            -- Fix Flag Combination and Helvetica on Mac
            if span.i then
                if font_name == "Helvetica" then
                    effective_font = "Helvetica Oblique"
                else
                    f_flags = string.byte('i')
                end
            end
            
            if measure_bold then
                -- If we already have italic, we might struggle to do both with simple flags.
                -- Start with Bold flag if Italic handled by name, or try to override?
                -- Simple fallback: Bold takes precedence in flags if name not changed, 
                -- or just use 'b' and hope for the best if both? 
                -- Actually, if we have both, usually we need a specific font face.
                -- Let's prioritize Bold flag if we didn't change name for Italic.
                if effective_font == font_name then
                     f_flags = string.byte('b')
                end
                
                -- Improvement: If we have both, maybe append "Bold"? 
                -- Ideally we'd map "Helvetica Oblique" -> "Helvetica Bold Oblique"
                if span.i and font_name == "Helvetica" then
                    effective_font = "Helvetica Bold Oblique"
                end
            end
            
            -- We must setup font to measure
            gfx.setfont(font_slot, effective_font, base_size, f_flags)
            -- Correct width measurement for stress marks
            -- If we are going to draw manually, we should measure effectively 0 width for stress mark char?
            -- Actually, if we correct it visually but return total path width including it, alignment might be off.
            -- We should measure as if stress mark doesn't exist for layout purposes.
            local measure_text = span.text:gsub(acute, "") -- Remove stress marks for width calculation
            if cfg.all_caps then
                measure_text = utf8_upper(measure_text)
            end
            
            gfx.setfont(font_slot, effective_font, base_size, f_flags)
            span.width = gfx.measurestr(measure_text)
            span.height = gfx.texth
            total_w = total_w + span.width
        end
        
        -- 2. Draw
        local start_x 
        if cfg.p_align == "left" then start_x = 20
        elseif cfg.p_align == "right" then start_x = gfx.w - total_w - 20
        else start_x = (gfx.w - total_w) / 2 end
        
        local cursor_x = start_x
        
        -- Helper for corrected drawing
        local function draw_string_corrected(text)
             draw_text_with_stress_marks(text, cfg.all_caps)
        end

        for _, span in ipairs(line_spans) do
            local f_flags = 0
            local effective_font = font_name
            
            if span.i then
               if font_name == "Helvetica" then effective_font = "Helvetica Oblique"
               else f_flags = string.byte('i') end
            end
            
            if span.b then
                if effective_font == font_name then f_flags = string.byte('b') end
                if span.i and font_name == "Helvetica" then effective_font = "Helvetica Bold Oblique" end
            end
            
            gfx.setfont(font_slot, effective_font, base_size, f_flags)
            
            -- set_color removed to respect caller's color (e.g. Next Replica)
            
            gfx.x = cursor_x
            gfx.y = y_base
            
            -- WORD LONG-CLICK DETECTION (Dictionary Lookup)
            local segments = get_words_and_separators(span.text)
            local temp_x = cursor_x
            for _, seg in ipairs(segments) do
                local measure_text = seg.text:gsub(acute, "")
                if cfg.all_caps then measure_text = utf8_upper(measure_text) end
                local sw = gfx.measurestr(measure_text)
                
                if seg.is_word and (not dict_modal.show) then
                    local is_over = gfx.mouse_x >= temp_x and gfx.mouse_x <= temp_x + sw and
                                    gfx.mouse_y >= y_base and gfx.mouse_y <= y_base + span.height
                    
                    if is_over then
                        if gfx.mouse_cap & 1 == 1 then
                            if last_mouse_cap == 0 then
                                -- Start tracking
                                word_trigger.active = true
                                word_trigger.start_time = reaper.time_precise()
                                -- Use original word context if it exists (for assimilated text)
                                word_trigger.word = span.orig_word or seg.text:gsub(acute, "")
                                word_trigger.triggered = false
                            elseif word_trigger.active and not word_trigger.triggered then
                                local hold_time = reaper.time_precise() - word_trigger.start_time
                                if hold_time > 0.4 then
                                    -- TRIGGER LOOKUP (Unified & Lazy)
                                    word_trigger.triggered = true
                                    trigger_dictionary_lookup(word_trigger.word)
                                end
                            end
                        end
                    end
                end
                temp_x = temp_x + sw
            end
             
            -- Cleanup trigger if mouse released
            if word_trigger.active and gfx.mouse_cap & 1 == 0 then
                word_trigger.active = false
            end

            -- USE CORRECTED DRAWING
            draw_string_corrected(span.text)
            
            -- Manual Rendering of Underline / Strikeout
            if span.u then
                local ly = y_base + span.height - 2
                gfx.line(cursor_x, ly, cursor_x + span.width, ly)
            end
            
            -- Wavy Underline logic
            if span.u_wave then
                local wave_y = y_base + span.height - 2
                local wave_h = 2
                local step = 3
                local x_pos = cursor_x
                local end_x = cursor_x + span.width
                
                local up = true
                while x_pos < end_x do
                    local next_x = math.min(x_pos + step, end_x)
                    local y1 = up and wave_y or (wave_y + wave_h)
                    local y2 = up and (wave_y + wave_h) or wave_y
                    
                    gfx.line(x_pos, y1, next_x, y2)
                    x_pos = next_x
                    up = not up
                end
            end

            if span.s then
                local ly = y_base + span.height / 2
                gfx.line(cursor_x, ly, cursor_x + span.width, ly)
            end
            
            cursor_x = cursor_x + span.width
        end
        
        -- Return Bounding Rect for Click detection
        local h = 0
        if #line_spans > 0 then h = line_spans[1].height end -- assume uniform height
        return start_x, y_base, total_w, h
    end

    -- ------------------------------
    -- Cache for Prompter Parsing (Optimization)    
    if not draw_prompter_cache then
        draw_prompter_cache = {
            last_text = nil,
            lines = {},
            last_next_text = nil,
            next_lines = {}
        }
    end
    -- ------------------------------

    -- Use first active region for interactions (backward compatibility)
    local region_idx = -1
    if #active_regions > 0 then
        -- Find the region_idx for the first active region
        for i = 0, reaper.CountProjectMarkers(0) - 1 do
            local retval, isrgn, pos, rgnend, name, idx = reaper.EnumProjectMarkers(i)
            if isrgn and idx == active_regions[1].idx then
                region_idx = i
                break
            end
        end
    end
    
    -- Helper function to render next replica (defined here to be accessible in both branches)
    local function render_next_replica(next_rgn, y_position_mode)
        if not next_rgn then return end
        
        set_color({cfg.n_cr, cfg.n_cg, cfg.n_cb})
        
        -- Parse Text (with Cache)
        if next_rgn.name ~= draw_prompter_cache.last_next_text then
            draw_prompter_cache.next_lines = parse_rich_text(next_rgn.name)
            draw_prompter_cache.last_next_text = next_rgn.name
        end
        local n_lines = draw_prompter_cache.next_lines
        
        -- Scale Next
        local max_w = gfx.w - 40
        local n_max_raw_w = 0
        local n_flags = 0
        if cfg.karaoke_mode then n_flags = string.byte('b') end
        gfx.setfont(F.nxt, cfg.p_font, cfg.n_fsize, n_flags)
        for _, line in ipairs(n_lines) do
            local raw = ""
            for _, span in ipairs(line) do 
                local t = span.text:gsub(acute, "")
                if cfg.all_caps then t = utf8_upper(t) end
                raw = raw .. t 
            end
            local w = gfx.measurestr(raw)
            if w > n_max_raw_w then n_max_raw_w = w end
        end
        
        local n_draw_size = cfg.n_fsize
        if n_max_raw_w > max_w then
            local ratio = max_w / n_max_raw_w
            n_draw_size = math.floor(n_draw_size * ratio)
            if n_draw_size < 10 then n_draw_size = 10 end
        end
        
        gfx.setfont(F.nxt, cfg.p_font, n_draw_size, n_flags)
        local n_lh = gfx.texth
        local n_total_h = #n_lines * n_lh
        
        -- Position: bottom (when in region) or center (when not in region)
        local n_start_y
        if y_position_mode == "bottom" then
            n_start_y = gfx.h - n_total_h - 10
        else -- "center"
            n_start_y = (gfx.h - n_total_h) / 2
        end
        
        -- Bounds for click
        local n_x1, n_y1, n_x2, n_y2 = gfx.w, gfx.h, 0, 0
        
        for i, line in ipairs(n_lines) do
            local y = n_start_y + (i-1) * n_lh
            local lx, ly, lw, l_h = draw_rich_line(line, gfx.w/2, y, F.nxt, cfg.p_font, n_draw_size)
            
            if lx < n_x1 then n_x1 = lx end
            if ly < n_y1 then n_y1 = ly end
            if lx + lw > n_x2 then n_x2 = lx + lw end
            if ly + l_h > n_y2 then n_y2 = ly + l_h end
        end
        
        -- Double-click on next text to edit
        if is_mouse_clicked() and (not dict_modal.show) then
            if gfx.mouse_x >= n_x1 - 20 and gfx.mouse_x <= n_x2 + 20 and
               gfx.mouse_y >= n_y1 - 10 and gfx.mouse_y <= n_y2 + 10 then
                local now = reaper.time_precise()
                if last_click_row == -2 and (now - last_click_time) < 0.5 then
                    -- Find corresponding ass_line
                    for i, line in ipairs(ass_lines) do
                        if math.abs(line.t1 - next_rgn.pos) < 0.01 and math.abs(line.t2 - next_rgn.rgnend) < 0.01 then
                            local edit_line = line
                            open_text_editor(line.text, function(new_text)
                                push_undo("Редагування тексту")
                                edit_line.text = new_text
                                rebuild_regions()
                            end, i, ass_lines)
                            break
                        end
                    end
                    last_click_row = 0
                else
                    last_click_time = now
                    last_click_row = -2 -- Use -2 as marker for next text
                end
            end
        end
    end
    
    if region_idx >= 0 then
        local retval, isrgn, pos, rgnend, name, idx = reaper.EnumProjectMarkers(region_idx)
        
        if isrgn then
            -- Collect ALL text blocks to display
            local all_text_blocks = {}
            local total_combined_height = 0
            local max_w = gfx.w - 40
            
            -- Helper: Count words in lines
            local function count_words_in_lines(lines_structure)
                local count = 0
                for _, line in ipairs(lines_structure) do
                    for _, span in ipairs(line) do
                        for _ in span.text:gmatch("[^%s]+") do
                            count = count + 1
                        end
                    end
                end
                return count
            end
            
            -- Helper: Apply Karaoke Styling
            local function apply_karaoke_style(lines_structure, active_idx)
                if not active_idx then return lines_structure end
                
                local new_lines = {}
                local word_counter = 0
                
                for _, line in ipairs(lines_structure) do
                    local new_line = {}
                    for _, span in ipairs(line) do
                        local text = span.text
                        
                        -- Manual tokenizer to preserve exact original text and spacing
                        local current_idx = 1
                        while current_idx <= #text do
                            -- Find next non-space
                            local s_start, s_end = text:find("[^%s]+", current_idx)
                            
                            if not s_start then
                                -- Only whitespace remaining
                                local remainder = text:sub(current_idx)
                                if #remainder > 0 then
                                    table.insert(new_line, {
                                        text = remainder,
                                        b = (word_counter < active_idx) or span.b, -- If we finished words, this is trailing space
                                        i = span.i, u = span.u, s = span.s, u_wave = span.u_wave
                                    })
                                end
                                break
                            end
                            
                            -- Space before word
                            if s_start > current_idx then
                                local space = text:sub(current_idx, s_start - 1)
                                table.insert(new_line, {
                                    text = space,
                                    b = (word_counter < active_idx) or span.b, -- Space after previous word belongs to "active" state of previous?
                                    -- Or better: space belongs to the upcoming word's state? 
                                    -- Generally, if we just finished word X, the space after it is passed.
                                    -- Here we are BEFORE word (word_counter is not incremented yet).
                                    -- So this space is effectively AFTER the previous word.
                                    -- `word_counter` is currently at previous count.
                                    
                                    b = (word_counter < active_idx) or span.b,
                                    i = span.i, u = span.u, s = span.s, u_wave = span.u_wave
                                })
                            end
                            
                            -- The Word
                            word_counter = word_counter + 1
                            local word = text:sub(s_start, s_end)
                             table.insert(new_line, {
                                text = word,
                                b = (word_counter <= active_idx) or span.b,
                                i = span.i, u = span.u, s = span.s, u_wave = span.u_wave
                            })
                            
                            current_idx = s_end + 1
                        end
                    end
                    table.insert(new_lines, new_line)
                end
                return new_lines
            end

            for region_num, rgn in ipairs(active_regions) do
                local lines
                
                -- Use cache for first region (optimization)
                if region_num == 1 then
                    if name ~= draw_prompter_cache.last_text then
                        draw_prompter_cache.lines = parse_rich_text(name)
                        draw_prompter_cache.last_text = name
                    end
                    lines = draw_prompter_cache.lines
                    
                    -- KARAOKE LOGIC APPLICATION
                    if cfg.karaoke_mode then
                        -- Clone structure to avoid modifying cache permanently for this frame
                        -- (Actually we parse every time lazily, but modifying 'lines' which is ref to cache is bad)
                        -- We must deep copy if we modify.
                        -- Or just re-parse next frame? 
                        -- Efficiency: if we modify cache, next frame we might have formatted text.
                        -- But active_idx changes.
                        -- So we should probably NOT modify the cached `lines`.
                        -- We should generate `display_lines` from `lines`.
                        
                        local w_count = count_words_in_lines(lines)
                        local k_idx = get_karaoke_word_index(rgn.pos, rgn.rgnend, cur_pos, w_count)
                        if k_idx then
                            lines = apply_karaoke_style(lines, k_idx)
                        end
                    end
                else
                    -- Parse text for other regions
                    lines = parse_rich_text(rgn.name)
                    if cfg.karaoke_mode then
                        local w_count = count_words_in_lines(lines)
                        local k_idx = get_karaoke_word_index(rgn.pos, rgn.rgnend, cur_pos, w_count)
                        if k_idx then
                            lines = apply_karaoke_style(lines, k_idx)
                        end
                    end
                end
                
                -- Find max width and calculate scale
                local max_raw_w = 0
                local p_flags = 0
                if cfg.karaoke_mode then p_flags = string.byte('b') end
                gfx.setfont(F.lrg, cfg.p_font, cfg.p_fsize, p_flags)
                
                for _, line in ipairs(lines) do
                    local raw = ""
                    for _, span in ipairs(line) do 
                        local t = span.text:gsub(acute, "")
                        if cfg.all_caps then t = utf8_upper(t) end
                        raw = raw .. t 
                    end
                    local w = gfx.measurestr(raw)
                    if w > max_raw_w then max_raw_w = w end
                end
                
                local draw_size = cfg.p_fsize
                if max_raw_w > max_w then
                    local ratio = max_w / max_raw_w
                    draw_size = math.floor(draw_size * ratio)
                    if draw_size < 10 then draw_size = 10 end
                end
                
                gfx.setfont(F.lrg, cfg.p_font, draw_size, p_flags)
                local lh = gfx.texth
                local block_height = #lines * lh
                
                table.insert(all_text_blocks, {
                    lines = lines,
                    draw_size = draw_size,
                    lh = lh,
                    block_height = block_height
                })
                
                total_combined_height = total_combined_height + block_height + 15 -- spacing
            end
            
            -- Calculate starting Y position to center all blocks
            local start_y = (gfx.h - total_combined_height) / 2
            local current_y = start_y
            
            -- Store bounds for each block for click detection
            local block_bounds = {}
            
            -- Draw Waveform Background FIRST (behind text, centered on screen)
            if cfg.wave_bg and #active_regions > 0 then
                local rgn = active_regions[1]
                local cache_key = tostring(rgn.pos) .. "_" .. tostring(rgn.rgnend)
                local map = karaoke_cache[cache_key]
                
                if not map then
                    -- Trigger analysis if not in cache (Decoupled from Karaoke Logic)
                    map = get_audio_energy_map(rgn.pos, rgn.rgnend)
                    if map then
                       karaoke_cache[cache_key] = map
                    else
                       karaoke_cache[cache_key] = { empty = true }
                    end
                elseif not map.empty then
                    -- Draw centered on screen
                    -- Height: use a significant portion of the screen
                    local wave_h = gfx.h * 0.5 
                    local progress = (cur_pos - rgn.pos) / (rgn.rgnend - rgn.pos)
                    draw_waveform_bg(map, 20, (gfx.h - wave_h) / 2, gfx.w - 40, wave_h, progress)
                end
            end

            -- Draw all text blocks with prompt color
            set_color({cfg.p_cr, cfg.p_cg, cfg.p_cb})
            for block_idx, block in ipairs(all_text_blocks) do
                local block_x1, block_y1, block_x2, block_y2 = gfx.w, gfx.h, 0, 0
                
                for i, line in ipairs(block.lines) do
                    local y = current_y + (i-1) * block.lh
                    local lx, ly, lw, l_h = draw_rich_line(line, gfx.w/2, y, F.lrg, cfg.p_font, block.draw_size)
                    
                    -- Update bounds for this block
                    if lx < block_x1 then block_x1 = lx end
                    if ly < block_y1 then block_y1 = ly end
                    if lx + lw > block_x2 then block_x2 = lx + lw end
                    if ly + l_h > block_y2 then block_y2 = ly + l_h end
                end
                
                -- Store bounds with padding for this block
                table.insert(block_bounds, {
                    x1 = block_x1 - 20,
                    y1 = block_y1 - 10,
                    x2 = block_x2 + 20,
                    y2 = block_y2 + 10,
                    region = active_regions[block_idx]
                })
                
                current_y = current_y + block.block_height + 15
            end
            
            -- Info Overlay
            if cfg.p_info then
                gfx.setfont(F.std) -- Small font
                gfx.set(cfg.p_cr, cfg.p_cg, cfg.p_cb, 0.5)
                
                -- Top Left: Time Range
                local time_str = format_timestamp(pos + 0.001) .. " - " .. format_timestamp(rgnend + 0.001)
                gfx.x = 10
                gfx.y = 30
                gfx.drawstr(time_str)
                
                -- Interaction: Copy Time on Double Click
                if is_mouse_clicked() then
                    local tw, th = gfx.measurestr(time_str)
                    if gfx.mouse_x >= 10 and gfx.mouse_x <= 10 + tw and
                       gfx.mouse_y >= 30 and gfx.mouse_y <= 30 + th then
                        
                        local now = reaper.time_precise()
                         if last_click_row == -3 and (now - last_click_time) < 0.5 then -- -3 for Time Overlay
                            set_clipboard(format_timestamp(pos + 0.001))
                            show_snackbar("Скопійовано: " .. format_timestamp(pos + 0.001))
                            last_click_row = 0
                        else
                            last_click_time = now
                            last_click_row = -3
                        end
                    end
                end
                
                -- Top Right: Index (or count if multiple)
                local idx_str = "#" .. tostring(idx)
                local iw, ih = gfx.measurestr(idx_str)
                gfx.x = gfx.w - iw - 5
                gfx.y = 30
                gfx.drawstr(idx_str)

                -- Interaction: Copy Index on Double Click
                if is_mouse_clicked() then
                    if gfx.mouse_x >= gfx.w - iw - 5 and gfx.mouse_x <= gfx.w - 5 and
                       gfx.mouse_y >= 30 and gfx.mouse_y <= 30 + ih then
                        
                        local now = reaper.time_precise()
                        if last_click_row == -4 and (now - last_click_time) < 0.5 then -- -4 for Index Overlay
                            set_clipboard(idx_str)
                            show_snackbar("Скопійовано: " .. idx_str)
                            last_click_row = 0
                        else
                            last_click_time = now
                            last_click_row = -4
                        end
                    end
                end

                gfx.set(cfg.p_cr, cfg.p_cg, cfg.p_cb, 1)
            end
            
            -- Double-click to edit (check all blocks)
            if is_mouse_clicked() and (not dict_modal.show) then
                -- Check which block was clicked
                for _, bounds in ipairs(block_bounds) do
                    if gfx.mouse_x >= bounds.x1 and gfx.mouse_x <= bounds.x2 and
                       gfx.mouse_y >= bounds.y1 and gfx.mouse_y <= bounds.y2 then
                        local now = reaper.time_precise()
                        if last_click_row == -1 and (now - last_click_time) < 0.5 then
                            -- Find the corresponding ass_line for this region
                            for i, line in ipairs(ass_lines) do
                                if math.abs(line.t1 - bounds.region.pos) < 0.01 and 
                                   math.abs(line.t2 - bounds.region.rgnend) < 0.01 and
                                   compare_sub_text(line.text, bounds.region.name) then
                                    local edit_line = line
                                    open_text_editor(line.text, function(new_text)
                                        push_undo("Редагування тексту")
                                        edit_line.text = new_text
                                        rebuild_regions()
                                    end, i, ass_lines)
                                    break
                                end
                            end
                            last_click_row = 0
                        else
                            last_click_time = now
                            last_click_row = -1
                        end
                        break -- Stop checking other blocks once we found a hit
                    end
                end
            end
            
            -- Show Next Line Logic
            if cfg.p_next then
                local current_k = -1
                for k, rgn in ipairs(regions) do
                     if rgn.rgn_index == region_idx then current_k = k break end
                end
                
                if current_k ~= -1 and regions[current_k + 1] then
                    render_next_replica(regions[current_k + 1], "bottom")
                end
            end
        else
            set_color(UI.C_TXT)
            gfx.setfont(F.std)
            gfx.x, gfx.y = 50, 50
            gfx.drawstr("Нічого немає (Суфлер не активний)")
        end
    else
        -- Not in any region, but show next upcoming region if enabled
        if cfg.p_next and cfg.always_next and #regions > 0 then
            -- Find the next region after current position
            local next_rgn = nil
            for _, rgn in ipairs(regions) do
                if rgn.pos > cur_pos then
                    next_rgn = rgn
                    break
                end
            end
            
            if next_rgn then
                render_next_replica(next_rgn, "bottom")
            else
                set_color(UI.C_TXT)
                gfx.setfont(F.std)
                gfx.x, gfx.y = 50, 50
                gfx.drawstr("Нічого немає")
            end
        else
            set_color(UI.C_TXT)
            gfx.setfont(F.std)
            gfx.x, gfx.y = 50, 50
            gfx.drawstr("Нічого немає")
        end
    end
    
    -- Draw Countdown Timer (Only in gaps when no active replica is present)
    if cfg.count_timer and next_rgn and #active_regions == 0 then
        local gap_to_next = next_rgn.pos - cur_pos
        local total_gap = next_rgn.pos - prev_rgn_end

        local alpha = 0.04 -- Very faint for long wait
        if gap_to_next <= 3.0 then alpha = 0.25 end -- Prominent for entry

        -- Set color with determined alpha
        gfx.set(cfg.p_cr, cfg.p_cg, cfg.p_cb, alpha)
        
        if gap_to_next > 0 and total_gap >= 3.0 then
            local countdown_str = ""
            if gap_to_next > 60 then
                local m = math.floor(gap_to_next / 60)
                local s = math.floor(gap_to_next % 60)
                countdown_str = string.format("%d:%02d", m, s)
            else
                countdown_str = tostring(math.ceil(gap_to_next))
            end
            
            -- Use a huge font size for impact
            local count_font_size = math.min(gfx.h, gfx.w) * 0.4
            gfx.setfont(10, cfg.p_font or "Arial", count_font_size, string.byte('b'))
            
            -- Center of screen
            local tw, th = gfx.measurestr(countdown_str)
            gfx.x = (gfx.w - tw) / 2
            gfx.y = (gfx.h - th) / 2
            gfx.drawstr(countdown_str)
        end

        -- Side Progress Bars (Vertical)
        if gap_to_next > 0 and total_gap >= 0.1 then
            local bar_w = 8
            -- Progress from bottom (0) to top (1)
            -- We use total_gap to normalize if possible, or a fixed reasonable window (e.g. 10s)
            -- Actually, user said "rising according to timer". Let's use a 0->1 factor.
            -- If we want it to reach top at gap=0: 1 - (gap_to_next / total_gap)
            -- but total_gap can be huge. Let's use a 5-second window for the visual "rise" 
            -- or just map it to the countdown phase.
            
            local progress = 1.0 - math.min(1.0, gap_to_next / math.max(1.0, total_gap))
            local bar_h = gfx.h * progress
            
            -- Left Bar
            gfx.rect(0, gfx.h - bar_h + 25, bar_w, bar_h, 1)
            -- Right Bar
            gfx.rect(gfx.w - bar_w, gfx.h - bar_h + 25, bar_w, bar_h, 1)
        end

        gfx.set(cfg.p_cr, cfg.p_cg, cfg.p_cb)
    end
end

local last_settings_h = 0 -- Persistent storage for Settings height

-- Helper to draw a custom color picker square
local function draw_custom_color_box(bx, screen_y, box_sz, r, g, b, on_change, is_selected)
    -- Background
    if is_selected then
        set_color({r, g, b})
    else
        set_color({0.2, 0.2, 0.2, 0.5})
    end
    gfx.rect(bx, screen_y, box_sz, box_sz, 1)
    
    -- Border
    if is_selected then
        set_color({1, 1, 1})
        draw_selection_border(bx, screen_y, box_sz, box_sz)
    else
        set_color({1, 1, 1, 0.3})
        gfx.rect(bx, screen_y, box_sz, box_sz, 0)
    end
    
    -- Plus sign
    if is_selected then
        local lum = (r * 0.299 + g * 0.587 + b * 0.114)
        set_color(lum > 0.5 and {0, 0, 0} or {1, 1, 1})
    else
        set_color({0.8, 0.8, 0.8})
    end

    gfx.setfont(F.std)
    local tw, th = gfx.measurestr("＋")
    gfx.x = bx + (box_sz - tw) / 2
    gfx.y = screen_y + (box_sz - th) / 2
    gfx.drawstr("＋")
    
    if is_mouse_clicked() then
        if gfx.mouse_x >= bx and gfx.mouse_x <= bx + box_sz and gfx.mouse_y >= screen_y and gfx.mouse_y <= screen_y + box_sz then
            local initial_color = reaper.ColorToNative(math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
            local retval, selected_color = reaper.GR_SelectColor(reaper.GetMainHwnd(), initial_color)
            if retval > 0 then
                local nr, ng, nb = reaper.ColorFromNative(selected_color)
                on_change(nr / 255, ng / 255, nb / 255)
            end
        end
    end
end

-- =============================================================================
-- UI: SETTINGS TAB
-- =============================================================================

local function draw_settings()
    local x_start = 20
    local start_y = 50
    local content_h = 0 
    
    -- Setup Scroll Logic for Settings (Smooth)
    local avail_h = gfx.h - start_y
    local max_scroll = math.max(0, last_settings_h - avail_h) -- Use PREVIOUS frame's height
    
    -- Accumulate target scroll
    if gfx.mouse_wheel ~= 0 then
        target_scroll_y = target_scroll_y - (gfx.mouse_wheel * 0.25)
        -- Immediate Clamp on input
        if target_scroll_y < 0 then target_scroll_y = 0 end
        if target_scroll_y > max_scroll then target_scroll_y = max_scroll end
        
        gfx.mouse_wheel = 0
    end
    
    -- Smoothly interpolate
    local diff = target_scroll_y - scroll_y
    if math.abs(diff) > 0.5 then
        scroll_y = scroll_y + (diff * 0.2)
    else
        scroll_y = target_scroll_y
    end
    
    -- HARD Clamp scroll_y before drawing to prevent "blinking"
    if scroll_y < 0 then scroll_y = 0 end
    if scroll_y > max_scroll then scroll_y = max_scroll end
    
    -- Reset tooltip state at the start of settings drawing
    tooltip_state.text = ""
    gfx.setfont(F.std)

    -- Helper to offset Y and check boundaries (INTEGER ROUNDING)
    local function get_y(offset)
        return start_y + offset - math.floor(scroll_y)
    end
    
    local y_cursor = 0 -- Relative Y from start
    
    -- Button Helper wrapper for scrolling
    local function s_btn(x, y_rel, w, h, text, tooltip, bg_col)
        local screen_y = get_y(y_rel)
        if screen_y + h < start_y or screen_y > gfx.h then return false end -- Cull
        
        local hover = (gfx.mouse_x >= x and gfx.mouse_x <= x+w and gfx.mouse_y >= screen_y and gfx.mouse_y <= screen_y+h)
        set_color(hover and UI.C_BTN_H or (bg_col or UI.C_BTN))
        gfx.rect(x, screen_y, w, h, 1)
        set_color(UI.C_TXT)
        gfx.setfont(F.std)
        local str_w, str_h = gfx.measurestr(text)
        gfx.x = x + (w - str_w) / 2
        gfx.y = screen_y + (h - str_h) / 2
        gfx.drawstr(text)

        if hover and tooltip then
            local id = "btn_" .. text .. "_" .. y_rel
            if tooltip_state.hover_id ~= id then
                tooltip_state.hover_id = id
                tooltip_state.start_time = reaper.time_precise()
            end
            tooltip_state.text = tooltip
        end

        if hover and is_mouse_clicked() then return true end
        return false
    end

    local function checkbox_box(show_param_checkbox, x_checkbox_start, y_checkbox_start)
        set_color({0.5, 0.5, 0.5})
        gfx.rect(x_checkbox_start, y_checkbox_start, 20, 20, 0)
        if show_param_checkbox then
            set_color(UI.C_TXT)
            gfx.line(x_checkbox_start + 4, y_checkbox_start + 10, x_checkbox_start + 8, y_checkbox_start + 16)
            gfx.line(x_checkbox_start + 5, y_checkbox_start + 10, x_checkbox_start + 9, y_checkbox_start + 16)
            gfx.line(x_checkbox_start + 8, y_checkbox_start + 16, x_checkbox_start + 16, y_checkbox_start + 4)
            gfx.line(x_checkbox_start + 9, y_checkbox_start + 16, x_checkbox_start + 17, y_checkbox_start + 4)
        end
    end

    -- Checkbox Helper
    local function checkbox(x, y_rel, text, checked, tooltip)
        local chk_sz = 20
        local screen_y = get_y(y_rel)
        if screen_y + chk_sz < start_y or screen_y > gfx.h then return false end -- Cull
        
        checkbox_box(checked, x, screen_y)
    
        gfx.setfont(F.std)
        gfx.x, gfx.y = x + chk_sz + 10, screen_y + 2
        gfx.drawstr(text)
        set_color(UI.C_TXT)
        
        local hover = (gfx.mouse_x >= x and gfx.mouse_x <= x + chk_sz + gfx.measurestr(text) + 10 and
                       gfx.mouse_y >= screen_y and gfx.mouse_y <= screen_y + chk_sz)
        
        if hover and tooltip then
            local id = "chk_" .. text .. "_" .. y_rel
            if tooltip_state.hover_id ~= id then
                tooltip_state.hover_id = id
                tooltip_state.start_time = reaper.time_precise()
            end
            tooltip_state.text = tooltip
        end

        return hover and is_mouse_clicked()
    end

    -- Text Helper
    local function s_text(x, y_rel, text, font, tooltip)
        local screen_y = get_y(y_rel)
        if screen_y + 15 < start_y or screen_y > gfx.h then return end
        gfx.setfont(font or F.std)
        gfx.x, gfx.y = x, screen_y
        gfx.drawstr(text)

        if tooltip then
            local tw, th = gfx.measurestr(text)
            local hover = (gfx.mouse_x >= x and gfx.mouse_x <= x + tw and gfx.mouse_y >= screen_y and gfx.mouse_y <= screen_y + th)
            if hover then
                local id = "txt_" .. text .. "_" .. y_rel
                if tooltip_state.hover_id ~= id then
                    tooltip_state.hover_id = id
                    tooltip_state.start_time = reaper.time_precise()
                end
                tooltip_state.text = tooltip
            end
        end
    end
    
    -- Section Header helper
    local function s_section(y_rel, title)
        local screen_y = get_y(y_rel)
        if screen_y + 30 < start_y or screen_y > gfx.h then return end
        
        -- Line
        set_color({0.35, 0.35, 0.35})
        gfx.rect(x_start, screen_y + 10, gfx.w - 40, 1, 1)
        
        -- Title background
        local tw = gfx.measurestr(title)
        set_color(UI.C_BG)
        gfx.rect(x_start, screen_y, tw + 10, 20, 1)
        
        -- Title text
        set_color({0.7, 0.7, 0.7})
        gfx.setfont(F.std)
        gfx.x = x_start
        gfx.y = screen_y
        gfx.drawstr(title)
    end
    
    -- Color Palette Helper
    local function draw_color_palette(x, palette, cur_r, cur_g, cur_b, on_change, scale)
        scale = scale or 1.0
        local box_sz = 30
        local gap = 10
        local pal_sel = false
        
        for i, col in ipairs(palette) do
            local bx = x + ((i-1) * (box_sz + gap))
            local screen_y = get_y(y_cursor)
            
            if screen_y + box_sz > start_y and screen_y < gfx.h then
                local r, g, b = col[1] * scale, col[2] * scale, col[3] * scale
                set_color({r, g, b})
                gfx.rect(bx, screen_y, box_sz, box_sz, 1)
                
                local is_sel = (math.abs(cur_r - r) < 0.01 and 
                                math.abs(cur_g - g) < 0.01 and 
                                math.abs(cur_b - b) < 0.01)
                if is_sel then
                    pal_sel = true
                    set_color({1,1,1})
                    draw_selection_border(bx, screen_y, box_sz, box_sz)
                else
                    set_color({1, 1, 1, 0.3})
                    gfx.rect(bx, screen_y, box_sz, box_sz, 0)
                end
                
                if is_mouse_clicked() then
                    if gfx.mouse_x >= bx and gfx.mouse_x <= bx + box_sz and gfx.mouse_y >= screen_y and gfx.mouse_y <= screen_y + box_sz then
                        on_change(r, g, b)
                    end
                end
            end
        end
        
        -- Custom Box
        local custom_bx = x + (#palette * (box_sz + gap))
        local custom_y = get_y(y_cursor)
        if custom_y + box_sz > start_y and custom_y < gfx.h then
            draw_custom_color_box(custom_bx, custom_y, box_sz, cur_r / scale, cur_g / scale, cur_b / scale, function(r, g, b)
                on_change(r * scale, g * scale, b * scale)
            end, not pal_sel)
        end
        
        return box_sz + 10
    end
    
    -- ═══════════════════════════════════════════
    -- 1. СЕРВІСИ ТА ДІЇ (Services & Actions)
    -- ═══════════════════════════════════════════
    s_section(y_cursor, "СЕРВІСИ ТА ДІЇ")
    y_cursor = y_cursor + 35
    
    -- Gemini API Key
    local gemini_btn_col = UI.C_BTN
    if gemini_key_status == 200 or gemini_key_status == 429 then
        gemini_btn_col = {0.2, 0.4, 0.2} -- Greenish
    elseif cfg.gemini_api_key ~= "" and gemini_key_status ~= 0 then
        gemini_btn_col = {0.5, 0.2, 0.2} -- Reddish
    end

    if s_btn(x_start, y_cursor, 200, 30, "Gemini API ключ", "Ключ доступу до Gemini AI для функцій перефразування та редагування тексту.", gemini_btn_col) then
        local retval, key = reaper.GetUserInputs("Gemini API Key", 1, "Ключ API:,extrawidth=300", cfg.gemini_api_key)
        if retval then
            cfg.gemini_api_key = key
            save_settings()
            validate_gemini_key(cfg.gemini_api_key)
        end
    end

    -- Delete regions (Danger Zone)
    if s_btn(x_start + 220, y_cursor, 180, 30, "Видалити ВСІ регіони", "Видаляє всі регіони з проекту REAPER.\nДія незворотна!", {0.4, 0.2, 0.2}) then
        delete_all_regions()
    end
    y_cursor = y_cursor + 60

    -- ═══════════════════════════════════════════
    -- 2. ІМПОРТ ТА РОБОТА З ТЕКСТОМ (Import & Data)
    -- ═══════════════════════════════════════════
    s_section(y_cursor, "ІМПОРТ ТА РОБОТА З ТЕКСТОМ")
    y_cursor = y_cursor + 35

    -- Max Wrap Length
    local t_y = get_y(y_cursor)
    if t_y + 20 > start_y and t_y < gfx.h then
        s_text(x_start, y_cursor, "Макс. довжина рядка:", F.std, "Максимальна кількість символів у рядку до переносу.")
        gfx.x = x_start + 150
        gfx.drawstr(tostring(cfg.wrap_length))
        if s_btn(x_start + 200, y_cursor - 10, 30, 30, "－") then
            cfg.wrap_length = math.max(10, cfg.wrap_length - 2)
            save_settings()
        end
        if s_btn(x_start + 235, y_cursor - 10, 30, 30, "＋") then
            cfg.wrap_length = math.min(100, cfg.wrap_length + 2)
            save_settings()
        end
    end
    y_cursor = y_cursor + 45

    -- Split Actors in SRT
    s_text(x_start, y_cursor, "Розбивка SRT за акторами:", F.std, "Автоматичне визначення акторів за шаблонами (ім'я): або [ім'я]:")
    y_cursor = y_cursor + 25
    local srt_split_options = {"():", "[]:", "none"}
    local srt_split_labels = {"(Актор):", "[Актор]:", "Вимк."}
    local split_btn_w = 90
    for i, opt in ipairs(srt_split_options) do
        local bx = x_start + ((i-1) * (split_btn_w + 10))
        local is_sel = (cfg.auto_srt_split == opt)
        local btn_bg = is_sel and {0.3, 0.5, 0.3} or UI.C_BTN
        if s_btn(bx, y_cursor, split_btn_w, 30, srt_split_labels[i], nil, btn_bg) then
            cfg.auto_srt_split = opt
            save_settings()
        end
    end
    y_cursor = y_cursor + 60

    if checkbox(x_start, y_cursor, "Випадковий колір актора при імпорті", cfg.random_color_actors, "Кожному новому актору буде присвоєно унікальний колір.") then
        cfg.random_color_actors = not cfg.random_color_actors
        rebuild_regions()
        save_project_data()
        save_settings()
    end
    y_cursor = y_cursor + 35
    if checkbox(x_start, y_cursor, "Показувати асиміляцію", cfg.text_assimilations, "Відображати фонетичні підказки (асиміляції) в тексті.") then
        cfg.text_assimilations = not cfg.text_assimilations
        save_settings()
    end
    y_cursor = y_cursor + 60

    -- ═══════════════════════════════════════════
    -- 3. СИСТЕМА (System)
    -- ═══════════════════════════════════════════
    s_section(y_cursor, "СИСТЕМА")
    y_cursor = y_cursor + 35
    if checkbox(x_start, y_cursor, "Автозапуск разом із REAPER", cfg.auto_startup, "Скрипт буде запускатися автоматично при старті програми.") then
        cfg.auto_startup = not cfg.auto_startup
        toggle_reaper_startup(cfg.auto_startup)
        save_settings()
    end
    y_cursor = y_cursor + 60

    -- ═══════════════════════════════════════════
    -- 4. ЕКРАН СУФЛЕРА (Prompter Elements)
    -- ═══════════════════════════════════════════
    s_section(y_cursor, "ЕКРАН СУФЛЕРА")
    y_cursor = y_cursor + 35
    
    if checkbox(x_start, y_cursor, "Відображати метадані (ID, час)", cfg.p_info, "Показувати індекс репліки та час початку зверху.") then
        cfg.p_info = not cfg.p_info
        save_settings()
    end
    y_cursor = y_cursor + 35
    if checkbox(x_start, y_cursor, "Таймер зворотного відліку", cfg.count_timer, "Показувати час до початку наступної репліки.") then
        cfg.count_timer = not cfg.count_timer
        save_settings()
    end
    y_cursor = y_cursor + 35
    if checkbox(x_start, y_cursor, "Попередження про швидкість (CPS)", cfg.cps_warning, "Червона смуга при занадто високій швидкості читання.") then
        cfg.cps_warning = not cfg.cps_warning
        save_settings()
    end
    y_cursor = y_cursor + 35
    if checkbox(x_start, y_cursor, "Режим Караоке", cfg.karaoke_mode, "Підсвічувати активне слово під час відтворення.") then
        cfg.karaoke_mode = not cfg.karaoke_mode
        save_settings()
    end
    y_cursor = y_cursor + 35
    if checkbox(x_start, y_cursor, "Режим ВЕЛИКИМИ ЛІТЕРАМИ", cfg.all_caps, "Весь текст відображатиметься ВЕЛИКИМИ ЛІТЕРАМИ.") then
        cfg.all_caps = not cfg.all_caps
        save_settings()
    end
    y_cursor = y_cursor + 35
    if checkbox(x_start, y_cursor, "Відображати осцилограму (Waveform)", cfg.wave_bg, "Малювати форму хвилі активного треку на фоні.") then
        cfg.wave_bg = not cfg.wave_bg
        save_settings()
    end
    y_cursor = y_cursor + 35
    if cfg.wave_bg then
        if checkbox(x_start + 20, y_cursor, "Прогрес заповнення осцилограми", cfg.wave_bg_progress, "Зафарбовувати пройдену частину хвилі.") then
            cfg.wave_bg_progress = not cfg.wave_bg_progress
            save_settings()
        end
    end
    y_cursor = y_cursor + 60

    -- ═══════════════════════════════════════════
    -- 5. ТЕМИ ТА ДИЗАЙН (Themes & Design)
    -- ═══════════════════════════════════════════
    s_section(y_cursor, "ТЕМИ ТА ДИЗАЙН")
    y_cursor = y_cursor + 35
    
    local theme_options = {
        {{0.67, 0.69, 0.69}, {0.05, 0.05, 0.05}}, {{0.96, 0.93, 0.86}, {0.18, 0.18, 0.18}},
        {{0.98, 0.98, 0.96}, {0.1, 0.1, 0.1}}, {{0.12, 0.13, 0.14}, {0.82, 0.82, 0.82}},
        {{0.06, 0.09, 0.16}, {0.8, 0.84, 0.88}}, {{0.18, 0.2, 0.25}, {0.85, 0.87, 0.91}},
        {{0.98, 0.92, 0.82}, {0.37, 0.29, 0.2}}, {{0.99, 0.96, 0.89}, {0.39, 0.48, 0.51}},
        {{0, 0.17, 0.21}, {0.51, 0.58, 0.59}}, {{0.94, 0.97, 0.95}, {0.15, 0.12, 0.10}},
    }
    local theme_labels = {"Бетон", "Пергамент", "Порцеляна", "Вугілля", "Безодня", "Сутінки", "Сепія", "Пісок", "Глибина", "М’ята"}
    local theme_btn_w = 110
    for i, opt in ipairs(theme_labels) do
        local r, c = math.floor((i-1)/5), (i-1)%5
        local bx = x_start + c * (theme_btn_w + 10)
        local sy = get_y(y_cursor + r * 40)
        local is_sel = (cfg.prmt_theme == opt)
        if sy + 30 > start_y and sy < gfx.h then
            if is_sel then set_color({0.2, 0.8, 0.2}) gfx.rect(bx - 2, sy - 2, theme_btn_w + 4, 34, 0) end
            set_color(theme_options[i][1]) gfx.rect(bx, sy, theme_btn_w, 30, 1)
            set_color(theme_options[i][2])
            local lw, lh = gfx.measurestr(opt)
            gfx.x, gfx.y = bx + (theme_btn_w - lw)/2, sy + (30 - lh)/2
            gfx.drawstr(opt)
            if is_mouse_clicked() and gfx.mouse_x >= bx and gfx.mouse_x <= bx + theme_btn_w and gfx.mouse_y >= sy and gfx.mouse_y <= sy+30 then
                cfg.prmt_theme = opt
                local res = theme_options[i]
                cfg.bg_cr, cfg.bg_cg, cfg.bg_cb = res[1][1], res[1][2], res[1][3]
                cfg.p_cr, cfg.p_cg, cfg.p_cb = res[2][1], res[2][2], res[2][3]
                cfg.n_cr, cfg.n_cg, cfg.n_cb = res[2][1]*0.7, res[2][2]*0.7, res[2][3]*0.7
                save_settings()
            end
        end
    end
    y_cursor = y_cursor + 90
    
    set_color(UI.C_TXT)
    s_text(x_start, y_cursor, "Ручне налаштування фону:")
    y_cursor = y_cursor + 25
    y_cursor = y_cursor + draw_color_palette(x_start, bg_palette, cfg.bg_cr, cfg.bg_cg, cfg.bg_cb, function(r, g, b)
        cfg.bg_cr, cfg.bg_cg, cfg.bg_cb = r, g, b
        save_settings()
    end)
    y_cursor = y_cursor + 20

    -- ═══════════════════════════════════════════
    -- 6. ОСНОВНИЙ ТЕКСТ (Main Text Layout)
    -- ═══════════════════════════════════════════
    s_section(y_cursor, "ОСНОВНИЙ ТЕКСТ")
    y_cursor = y_cursor + 35
    
    -- Font Size
    s_text(x_start, y_cursor, "Розмір шрифту: " .. cfg.p_fsize)
    if s_btn(x_start + 155, y_cursor - 10, 30, 30, "－") then
        cfg.p_fsize = math.max(10, cfg.p_fsize - 2)
        save_settings()
    end
    if s_btn(x_start + 190, y_cursor - 10, 30, 30, "＋") then
        cfg.p_fsize = math.min(200, cfg.p_fsize + 2)
        save_settings()
    end
    y_cursor = y_cursor + 45
    
    -- Alignment
    s_text(x_start, y_cursor, "Вирівнювання:")
    y_cursor = y_cursor + 25
    local align_options = {"left", "center", "right"}
    local align_labels = {"Ліворуч", "Центр", "Праворуч"}
    for i, opt in ipairs(align_options) do
        local bx = x_start + ((i-1) * 100)
        local is_sel = (cfg.p_align == opt)
        local btn_bg = is_sel and {0.3, 0.5, 0.3} or UI.C_BTN
        if s_btn(bx, y_cursor, 90, 30, align_labels[i], nil, btn_bg) then
            cfg.p_align = opt
            save_settings()
        end
    end
    y_cursor = y_cursor + 50

    -- Font Selection
    s_text(x_start, y_cursor, "Шрифт:")
    y_cursor = y_cursor + 25
    local font_options = {"Arial", "Comic Sans MS", "Verdana", "Tahoma", "Helvetica"}
    local font_btn_w = 110
    for i, f_name in ipairs(font_options) do
        local r, c = math.floor((i-1)/5), (i-1)%5
        local bx = x_start + c * (font_btn_w + 10)
        local is_sel = (cfg.p_font == f_name)
        local btn_bg = is_sel and {0.3, 0.5, 0.3} or UI.C_BTN
        if s_btn(bx, y_cursor + r * 35, font_btn_w, 30, f_name, nil, btn_bg) then
            cfg.p_font = f_name
            save_settings()
        end
    end
    -- Custom Font
    local is_preset = false
    for _, f in ipairs(font_options) do if f == cfg.p_font then is_preset = true break end end
    local font_btn_custom_w = (font_btn_w * 5) + 40
    local d_name = not is_preset and cfg.p_font or "Свій..."
    local btn_bg = (not is_preset) and {0.3, 0.5, 0.3} or UI.C_BTN
    if s_btn(x_start, y_cursor + 40, font_btn_custom_w, 30, d_name, nil, btn_bg) then
        local ok, nf = reaper.GetUserInputs("Вибір шрифту", 1, "Назва шрифту:,extrawidth=200", cfg.p_font)
        if ok and nf ~= "" then cfg.p_font = nf save_settings() end
    end
    y_cursor = y_cursor + 85

    -- Text Color
    s_text(x_start, y_cursor, "Колір тексту:")
    y_cursor = y_cursor + 25
    y_cursor = y_cursor + draw_color_palette(x_start, text_palette, cfg.p_cr, cfg.p_cg, cfg.p_cb, function(r, g, b)
        cfg.p_cr, cfg.p_cg, cfg.p_cb = r, g, b
        save_settings()
    end)
    y_cursor = y_cursor + 20

    -- ═══════════════════════════════════════════
    -- 7. НАСТУПНА РЕПЛІКА (Next Line)
    -- ═══════════════════════════════════════════
    s_section(y_cursor, "НАСТУПНА РЕПЛІКА")
    y_cursor = y_cursor + 35
    if checkbox(x_start, y_cursor, "Відображати наступну репліку", cfg.p_next, "Показувати текст наступної репліки під поточною.") then
        cfg.p_next = not cfg.p_next
        save_settings()
    end
    y_cursor = y_cursor + 45
    if cfg.p_next then
        s_text(x_start + 20, y_cursor, "Розмір шрифту: " .. cfg.n_fsize)
        if s_btn(x_start + 175, y_cursor - 10, 30, 30, "－") then
            cfg.n_fsize = math.max(10, cfg.n_fsize - 2)
            save_settings()
        end
        if s_btn(x_start + 210, y_cursor - 10, 30, 30, "＋") then
            cfg.n_fsize = math.min(100, cfg.n_fsize + 2)
            save_settings()
        end
        y_cursor = y_cursor + 45
        if checkbox(x_start + 20, y_cursor, "Завжди показувати (між регіонами)", cfg.always_next, "Наступна репліка не ховатиметься, коли немає активної.") then
            cfg.always_next = not cfg.always_next
            save_settings()
        end
        y_cursor = y_cursor + 40
        y_cursor = y_cursor + draw_color_palette(x_start + 20, text_palette, cfg.n_cr, cfg.n_cg, cfg.n_cb, function(r, g, b)
            cfg.n_cr, cfg.n_cg, cfg.n_cb = r, g, b
            save_settings()
        end, 0.7)
    end
    y_cursor = y_cursor + 40

    -- Footer
    set_color(UI.C_TXT)
    local footer_txt = "Знайшли баг або маєте ідею — пишіть: @fusion_ford"
    s_text(x_start, y_cursor, footer_txt, F.std)

    -- Click to Copy handle (using existing helpers)
    local f_sy = get_y(y_cursor)
    if f_sy + 20 > start_y and f_sy < gfx.h then
        local tw, th = gfx.measurestr(footer_txt)
        if is_mouse_clicked() and gfx.mouse_x >= x_start and gfx.mouse_x <= x_start + tw and
           gfx.mouse_y >= f_sy and gfx.mouse_y <= f_sy + th then
            set_clipboard("@fusion_ford")
            show_snackbar("Скопійовано: @fusion_ford")
        end
    end
    y_cursor = y_cursor + 40
    
    last_settings_h = y_cursor
    target_scroll_y = draw_scrollbar(gfx.w - 10, start_y, 10, avail_h, last_settings_h, avail_h, target_scroll_y)
end

-- Helper to find actor by timestamp
local function get_actor_at_time(t)
    -- Simple fuzzy match in ass_lines
    if ass_lines then
        for _, l in ipairs(ass_lines) do
            if math.abs(l.t1 - t) < 0.01 then -- Tolerance
                return l.actor
            end
        end
    end
    return nil
end

-- Helper to calculate sort value for a table row
local function get_sort_value(item, col, is_ass)
    if col == "#" then return item.index or 0 end
    if is_ass then
        if col == "Ак." then return (item.enabled ~= false and 1 or 0) end
        if col == "Початок" then return item.t1 or 0 end
        if col == "Кінець" then return item.t2 or 0 end
        if col == "CPS" then
            local dur = item.t2 - item.t1
            local clean = (item.text or ""):gsub(acute, ""):gsub("%s+", "")
            local chars = utf8.len(clean) or #clean
            return dur > 0 and (chars / dur) or 0
        end
        if col == "Актор" then return utf8_lower(item.actor or "") end
        if col == "Репліка" then return utf8_lower(item.text or "") end
    else
        -- Regions mode
        if col == "Початок" then return item.pos or 0 end
        if col == "Кінець" then return item.rgnend or 0 end
        if col == "CPS" then
            local dur = item.rgnend - item.pos
            local clean = (item.name or ""):gsub(acute, ""):gsub("%s+", "")
            local chars = utf8.len(clean) or #clean
            return dur > 0 and (chars / dur) or 0
        end
        if col == "Репліка" then return utf8_lower(item.name or "") end
    end
    return 0
end

-- =============================================================================
-- UI: TABLE TAB (SUBTITLE EDITOR)
-- =============================================================================

local last_table_h = 0
local function draw_table(input_queue)
    local start_y = 65

    -- Helper for inline buttons
    local function draw_btn_inline(x, y, w, h, text, bg_col)
        local hover = (gfx.mouse_x >= x and gfx.mouse_x <= x + w and gfx.mouse_y >= y and gfx.mouse_y <= y + h)
        set_color(hover and UI.C_BTN_H or (bg_col or UI.C_BTN))
        gfx.rect(x, y, w, h, 1)
        set_color(UI.C_TXT)
        local str_w, str_h = gfx.measurestr(text)
        gfx.x = x + (w - str_w) / 2
        gfx.y = y + (h - str_h) / 2
        gfx.drawstr(text)
        if hover and is_mouse_clicked() then return true end
        return false
    end

    local h_header = 25
    local row_h = 24
    
    -- --- FILTER INPUT ---
    local filter_y = 35
    local filter_h = 25
    local filter_x = 10
    local opt_btn_w = 30
    local chk_w = 25
    local gap = 5
    
    local filter_w = gfx.w - 20 - opt_btn_w - chk_w - (gap * 2)
    
    local prev_text = table_filter_state.text
    ui_text_input(filter_x, filter_y, filter_w, filter_h, table_filter_state, "Фільтр (Текст або Актор)...", input_queue)

    -- Case Sensitive Toggle (Aa) - Always visible
    local chk_x = filter_x + filter_w + gap
    local case_col = find_replace_state.case_sensitive and {0.2, 0.8, 0.2} or {0.3, 0.3, 0.3}
    if draw_btn_inline(chk_x, filter_y, chk_w, filter_h, "Aa", case_col) then
        find_replace_state.case_sensitive = not find_replace_state.case_sensitive
    end

    -- Options / Close Toggle Button
    local btn_x = chk_x + chk_w + gap
    
    if find_replace_state.show then
        -- CLOSE BUTTON (Reddish)
        if draw_btn_inline(btn_x, filter_y, opt_btn_w, filter_h, "✕", {0.3, 0.2, 0.2}) then
            find_replace_state.show = false
        end
    else
        -- MENU BUTTON (Standard)
        if draw_btn_inline(btn_x, filter_y, opt_btn_w, filter_h, "≡", UI.C_BTN) then
            gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
            local ret = gfx.showmenu("Знайти та замінити")
            if ret == 1 then
                find_replace_state.show = true
            end
        end
    end
    
    if table_filter_state.text ~= prev_text then
        scroll_y = 0
    end
    
    -- INLINE FIND/REPLACE UI
    if find_replace_state.show then
        local fr_y = filter_y + filter_h + 5
        local fr_h = 25
        
        -- Replace Input
        local btn_apply_w = 80
        local rep_w = gfx.w - 20 - btn_apply_w - gap
        
        ui_text_input(filter_x, fr_y, rep_w, fr_h, find_replace_state.replace, "Замінити на...", input_queue)

        -- Apply Button
        local apply_x = filter_x + rep_w + gap
        if draw_btn_inline(apply_x, fr_y, btn_apply_w, fr_h, "Замінити", UI.C_BTN) then
            local search = table_filter_state.text -- Use filter as search text
            local replace = find_replace_state.replace.text
            local case = find_replace_state.case_sensitive
            
            if #search > 0 then
                push_undo("Знайти та замінити")
                local count = 0
                
                for _, line in ipairs(ass_lines) do
                    local txt = line.text or ""
                    local new_txt = ""
                    local matches = 0
                    
                    if case then
                        -- Escape magic chars for literal search if needed
                        local s_pat = search:gsub("([%%%^%$%(%)%.%[%]%*%+%-%?])", "%%%1")
                        new_txt, matches = txt:gsub(s_pat, function() return replace end)
                    else
                        local res_tbl = {}
                        local last_pos = 1
                        local s_lower = utf8_lower(search)
                        local t_lower = utf8_lower(txt)
                        
                        local start_idx, end_idx = t_lower:find(s_lower, 1, true)
                        while start_idx do
                            table.insert(res_tbl, txt:sub(last_pos, start_idx - 1))
                            table.insert(res_tbl, replace)
                            last_pos = end_idx + 1
                            count = count + 1 
                            start_idx, end_idx = t_lower:find(s_lower, last_pos, true)
                        end
                        table.insert(res_tbl, txt:sub(last_pos))
                        new_txt = table.concat(res_tbl)
                        if new_txt ~= txt then matches = 1 else matches = 0 end
                    end
                    
                    if new_txt ~= txt then
                        line.text = new_txt
                        if case then count = count + matches end 
                    end
                end
                
                rebuild_regions()
                show_snackbar("Замінено " .. count .. " входжень")
                
                -- Clear inputs after successful replacement
                table_filter_state.text = ""
                table_filter_state.cursor = 0
                table_filter_state.anchor = 0
                find_replace_state.replace.text = ""
                find_replace_state.replace.cursor = 0
                find_replace_state.replace.anchor = 0
            else
                show_snackbar("Введіть текст в фільтр")
            end
        end
        
        start_y = start_y + 35 -- Shift content down
    end
    
    -- Handle Ctrl+A to select all (when no input is focused)
    if not table_filter_state.focus and not find_replace_state.replace.focus then
        for _, char in ipairs(input_queue) do
            -- Check for Ctrl+A (char 1) or Cmd+A
            if char == 1 then
                -- Select all visible rows
                table_selection = {}
                for i, line in ipairs(ass_lines) do
                    table_selection[line.index or i] = true
                end
                break
            end
        end
    end

    -- Choose data source: ASS lines or Project Regions
    local show_actor = ass_file_loaded and #ass_lines > 0
    local raw_data = show_actor and ass_lines or regions
    local data_source = {}
    
    -- Ensure index is populated for all lines for stable sorting and selection
    -- For Regions, we use the Enum index if available, else k
    for i, line in ipairs(raw_data) do
        line.index = line.index or i
    end

    -- Filter Data
    if #table_filter_state.text > 0 then
        local query = utf8_lower(table_filter_state.text)
        local raw_query = table_filter_state.text
        
        for i, line in ipairs(raw_data) do
            -- ASS mode uses .text, Regions mode uses .name
            local target_text = show_actor and line.text or line.name
            -- Strip accents for filtering
            local clean_text = target_text and target_text:gsub(acute, "") or ""
            local text_match = false
            local actor_match = false
            
            if find_replace_state.case_sensitive then
                text_match = clean_text:find(raw_query, 1, true)
                if show_actor and line.actor then
                    actor_match = line.actor:find(raw_query, 1, true)
                end
            else
                text_match = utf8_lower(clean_text):find(query, 1, true)
                if show_actor and line.actor then
                    actor_match = utf8_lower(line.actor):find(query, 1, true)
                end
            end
            
            if text_match or actor_match then
                table.insert(data_source, line)
            end
        end
    else
        for i, line in ipairs(raw_data) do
            table.insert(data_source, line) -- Use a copy to avoid mutating raw_data ordering
        end
    end
    -- Sorting
    if table_sort.col ~= "#" or table_sort.dir ~= 1 then
        local temp = {}
        for i, item in ipairs(data_source) do
            temp[i] = { item = item, val = get_sort_value(item, table_sort.col, show_actor) }
        end
        
        table.sort(temp, function(a, b)
            if a.val == b.val then
                -- Stable sort fallback to index
                local idx_a = a.item.index or 0
                local idx_b = b.item.index or 0
                return idx_a < idx_b
            end
            if table_sort.dir == 1 then
                return a.val < b.val
            else
                return a.val > b.val
            end
        end)
        
        data_source = {}
        for i, t in ipairs(temp) do
            data_source[i] = t.item
        end
    end

    local row_count = #data_source
    local show_actor = ass_file_loaded and #raw_data > 0
    
    -- Column layout: [On][#][Start][End][CPS][Actor?][Text]
    local x_off
    if show_actor then
        x_off = {10, 35, 70, 145, 218, 273, 373} -- On, #, Start, End, CPS, Actor, Text
    else
        x_off = {10, 45, 120, 193, 248, 348} -- #, Start, End, CPS, Text (fallback to regions)
    end
    
    -- Header will be drawn at the end to stay on top
    local header_y = start_y + 5
    
    local content_y = start_y + h_header
    local avail_h = gfx.h - content_y
    
    local total_h = row_count * row_h
    local max_scroll = math.max(0, total_h - avail_h)
    
    -- Auto-scroll to current playback position (only when position changes)
    local play_pos = reaper.GetPlayPosition()
    local edit_pos = reaper.GetCursorPosition()
    local current_pos = reaper.GetPlayState() > 0 and play_pos or edit_pos
    
    -- Only auto-scroll if position changed significantly (user jumped) AND not skipped
    local pos_changed = math.abs(current_pos - last_tracked_pos) > 0.5
    
    if pos_changed and not skip_auto_scroll then
        last_tracked_pos = current_pos
        
        -- Find which line corresponds to current position
        local current_line_idx = nil
        if show_actor then
            for i, line in ipairs(data_source) do
                if current_pos >= line.t1 and current_pos < line.t2 then
                    current_line_idx = i
                    break
                end
            end
        else
            for i, rgn in ipairs(data_source) do
                if current_pos >= rgn.pos and current_pos < rgn.rgnend then
                    current_line_idx = i
                    break
                end
            end
        end
        
        -- Always center current line when position changes
        if current_line_idx then
            local line_y = (current_line_idx - 1) * row_h
            -- Center the line
            target_scroll_y = math.max(0, math.min(max_scroll, line_y - avail_h / 2))
        end
    end
    
    -- Smooth Scroll Logic
    if gfx.mouse_wheel ~= 0 then
        target_scroll_y = target_scroll_y - (gfx.mouse_wheel * 0.25)
        if target_scroll_y < 0 then target_scroll_y = 0 end
        if target_scroll_y > max_scroll then target_scroll_y = max_scroll end
        gfx.mouse_wheel = 0
    end

    local diff = target_scroll_y - scroll_y
    if math.abs(diff) > 0.5 then
        scroll_y = scroll_y + (diff * 0.2)
    else
        scroll_y = target_scroll_y
    end

    -- Draw Rows
    local start_idx = math.floor(scroll_y / row_h) + 1
    local visible_rows = math.ceil(avail_h / row_h) + 1
    
    for i = start_idx, math.min(row_count, start_idx + visible_rows) do
        local y_rel = (i-1) * row_h
        local screen_y = content_y + y_rel - math.floor(scroll_y)

        -- zebra
        if i % 2 == 0 then set_color(UI.C_ROW) else set_color(UI.C_ROW_ALT) end
        gfx.rect(0, screen_y, gfx.w, row_h, 1)
        
        if show_actor then
            -- ASS mode: show all lines with checkbox
            local line = data_source[i]
            local actor = line.actor or ""
            local is_enabled = (line.enabled ~= false) -- Per-line enabled state
            
            -- Determine original index for selection tracking
            local original_idx = line.index or i
            local is_selected = table_selection[original_idx]
            
            -- Highlight if current time is within this line's range (Active)
            local play_pos = reaper.GetPlayPosition()
            local edit_pos = reaper.GetCursorPosition()
            local current_time = reaper.GetPlayState() > 0 and play_pos or edit_pos
            local is_active_row = (current_time >= line.t1 and current_time < line.t2)
            
            if is_selected then
                set_color({0.1, 0.35, 0.2}) -- Darker Green Selection
                gfx.rect(0, screen_y, gfx.w, row_h, 1)
            end
            
            if is_active_row then
                set_color({0.2, 0.9, 0.2}) -- Bright Green Border
                gfx.rect(0, screen_y, 5, row_h, 1)
            end
            
            -- Checkbox column
            local chk_sz = 16
            local chk_x = x_off[1]
            local chk_y = screen_y + (row_h - chk_sz)/2
            
            set_color({0.5, 0.5, 0.5})
            gfx.rect(chk_x, chk_y, chk_sz, chk_sz, 0)
            
            if is_enabled then
                set_color(UI.C_TXT)
                -- Checkmark
                gfx.line(chk_x + 3, chk_y + 8, chk_x + 7, chk_y + 12)
                gfx.line(chk_x + 4, chk_y + 8, chk_x + 8, chk_y + 12)
                gfx.line(chk_x + 7, chk_y + 12, chk_x + 13, chk_y + 4)
                gfx.line(chk_x + 8, chk_y + 12, chk_x + 14, chk_y + 4)
            end
            
            set_color(UI.C_TXT)
            local y_text = screen_y + 4
            
            -- Use original index if possible
            gfx.x = x_off[2]; gfx.y = y_text; gfx.drawstr(tostring(line.index or i))
            gfx.x = x_off[3]; gfx.y = y_text; gfx.drawstr(reaper.format_timestr(line.t1, ""))
            gfx.x = x_off[4]; gfx.y = y_text; gfx.drawstr(reaper.format_timestr(line.t2, ""))
            -- Truncate Actor
            local max_act_w = x_off[7] - x_off[6] - 10
            local display_act = fit_text_width(actor, max_act_w)
            
            -- CPS Calculation
            local duration = line.t2 - line.t1
            local clean_text = (line.text or ""):gsub(acute, ""):gsub("%s+", "")
            local char_count = utf8.len(clean_text) or #clean_text
            local cps = duration > 0 and (char_count / duration) or 0
            
            -- CPS Color
            local cps_color = get_cps_color(cps)
            
            set_color(cps_color)
            gfx.x = x_off[5]; gfx.y = y_text; gfx.drawstr(string.format("%.1f", cps))
            
            -- Helper for highlighting
            local function draw_highlighted_text(txt, x, y, max_w)
                local display_txt = fit_text_width(txt, max_w)
                local filter_s = utf8_lower(table_filter_state.text)
                
                -- Only highlight if filter is active
                if #filter_s > 0 then
                    local lower_display = utf8_lower(display_txt)
                    local s_start, s_end = lower_display:find(filter_s, 1, true)
                    
                    if s_start then
                        local pre_match = display_txt:sub(1, s_start - 1)
                        local match_str = display_txt:sub(s_start, s_end)
                        
                        local pre_w = gfx.measurestr(pre_match)
                        local match_w = gfx.measurestr(match_str)
                        
                        set_color({1, 1, 0, 0.4}) -- Yellow Highlight
                        gfx.rect(x + pre_w, y, match_w, row_h - 4, 1) -- Slightly smaller height
                        set_color(UI.C_TXT) -- Reset to text color
                    end
                end
                
                gfx.x = x; gfx.y = y; gfx.drawstr(display_txt)
            end

            set_color(UI.C_TXT)
            gfx.x = x_off[6]; gfx.y = y_text; 
            draw_highlighted_text(actor, x_off[6], y_text, x_off[7] - x_off[6] - 10)
            
            local replica_text = (line.text or ""):gsub("[\n\r]", " ")
            draw_highlighted_text(replica_text, x_off[7], y_text, gfx.w - x_off[7] - 10)
            
            -- Click logic
            -- FIX: Check bit 1 (Left Mouse) regardless of other flags
            if (gfx.mouse_cap & 1 == 1) and (last_mouse_cap & 1 == 0) then
                if gfx.mouse_y >= screen_y and gfx.mouse_y < screen_y + row_h then
                    -- Checkbox click?
                    if gfx.mouse_x >= chk_x - 5 and gfx.mouse_x <= chk_x + chk_sz + 10 then
                        -- BULK CHECKBOX LOGIC
                        push_undo("Перемикання видимості")
                        local new_state = not is_enabled
                        
                        if is_selected then
                            -- Apply to all selected
                            local count = 0
                             for k, l in ipairs(ass_lines) do
                                  if table_selection[l.index or k] then
                                      l.enabled = new_state
                                      count = count + 1
                                  end
                             end
                            if count == 0 then line.enabled = new_state end
                        else
                            -- Just toggle self
                            line.enabled = new_state
                        end
                        rebuild_regions() 
                    else
                        -- CLICK ON ROW (Selection Logic)
                        local cap = gfx.mouse_cap
                        local is_ctrl = (cap & 4 == 4) or (cap & 32 == 32) -- Ctrl or Cmd
                        local is_shift = (cap & 8 == 8)
                        
                        if is_ctrl then
                            -- Toggle Selection ONLY (No navigation)
                            if table_selection[original_idx] then
                                table_selection[original_idx] = nil
                            else
                                table_selection[original_idx] = true
                                last_selected_row = i -- Update anchor to current visual index
                            end
                        elseif is_shift and last_selected_row then
                            -- Range Selection ONLY (No navigation)
                            local start_v = math.min(last_selected_row, i)
                            local end_v = math.max(last_selected_row, i)
                            
                            table_selection = {}
                            for k = start_v, end_v do
                                local d_line = data_source[k]
                                if d_line then
                                    table_selection[d_line.index or k] = true
                                end
                            end
                        else
                            -- Single Click (Standard) -> Navigate & Clear Selection
                            table_selection = {}
                            table_selection[original_idx] = true
                            last_selected_row = i 
                            
                            -- Navigate logic
                             if gfx.mouse_x >= x_off[7] then
                                local now = reaper.time_precise()
                                if last_click_row == i and (now - last_click_time) < 0.5 then
                                    -- Double-click on text - open custom editor
                                    local edit_line = line
                                    open_text_editor(line.text, function(new_text)
                                        push_undo("Редагування тексту")
                                        edit_line.text = new_text
                                        rebuild_regions()
                                    end, original_idx, ass_lines)
                                    last_click_row = 0
                                else
                                    last_click_time = now
                                    last_click_row = i
                                    last_tracked_pos = line.t1
                                    reaper.SetEditCurPos(line.t1, true, false)
                                end
                            else
                                -- Just Navigate
                                last_tracked_pos = line.t1
                                reaper.SetEditCurPos(line.t1, true, false)
                            end
                        end
                    end
                end
            elseif (gfx.mouse_cap & 2 == 2) and (last_mouse_cap & 2 == 0) then
                -- Right Click on Row
                if gfx.mouse_y >= screen_y and gfx.mouse_y < screen_y + row_h then
                    mouse_handled = true -- Suppress global menu
                    
                    -- If right-clicked on non-selected row, select it first
                    if not table_selection[original_idx] then
                        table_selection = {}
                        table_selection[original_idx] = true
                        last_selected_row = i
                    end
                    
                    -- Count selected
                    local sel_indices = {}
                    for idx, _ in pairs(table_selection) do table.insert(sel_indices, idx) end
                    table.sort(sel_indices)
                    
                    local menu_str = "Змінити ім'я актора"
                    local has_merge = #sel_indices > 1 and #sel_indices <= 5
                    if has_merge then
                        menu_str = menu_str .. "|Об'єднати репліки в одну"
                    end
                    
                    if #sel_indices == 1 then
                        menu_str = menu_str .. "|Видалити репліку"
                    else
                        menu_str = menu_str .. "|Видалити вибрані репліки"
                    end
                    
                    gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y -- Set menu position
                    local ret = gfx.showmenu(menu_str)
                    if ret == 1 then
                        -- Change Actor Name
                        local selected_entries = {}
                        for p, l in ipairs(ass_lines) do
                            if table_selection[l.index or p] then
                                table.insert(selected_entries, l)
                            end
                        end
                        
                        if #selected_entries > 0 then
                            local first_actor = selected_entries[1].actor or ""
                            local ok, new_actor = reaper.GetUserInputs("Зміна імені актора", 1, "Нове ім'я:,extrawidth=200", first_actor)
                            if ok then
                                push_undo("Зміна імені актора")
                                -- Add to actors list if new
                                if ass_actors[new_actor] == nil then 
                                    ass_actors[new_actor] = true 
                                end
                                
                                for _, l in ipairs(selected_entries) do
                                    l.actor = new_actor
                                end
                                cleanup_actors()
                                rebuild_regions()
                                show_snackbar("Ім'я актора змінено (" .. #selected_entries .. ")")
                            end
                        end
                    elseif has_merge and ret == 2 then
                        -- Merge Replicas
                        local selected_entries = {}
                        for p, l in ipairs(ass_lines) do
                            if table_selection[l.index or p] then
                                table.insert(selected_entries, {line = l, pos = p})
                            end
                        end
                        
                        table.sort(selected_entries, function(a,b) return a.pos < b.pos end)
                        
                        if #selected_entries > 1 then
                            push_undo("Об'єднання реплік")
                            local merged_text = ""
                            local t1_min = math.huge
                            local t2_max = -math.huge
                            local base_pos = selected_entries[1].pos
                            local base_id = selected_entries[1].line.index or base_pos
                            
                            for _, ent in ipairs(selected_entries) do
                                local l = ent.line
                                if merged_text == "" then
                                    merged_text = l.text or ""
                                else
                                    merged_text = merged_text .. "\n" .. (l.text or "")
                                end
                                if l.t1 < t1_min then t1_min = l.t1 end
                                if l.t2 > t2_max then t2_max = l.t2 end
                            end
                            
                            ass_lines[base_pos].text = merged_text
                            ass_lines[base_pos].t1 = t1_min
                            ass_lines[base_pos].t2 = t2_max
                            
                            -- Remove others in reverse
                            for i = #selected_entries, 2, -1 do
                                table.remove(ass_lines, selected_entries[i].pos)
                            end
                            
                            table_selection = {}
                            table_selection[base_id] = true
                            
                            cleanup_actors()
                            rebuild_regions()
                            show_snackbar("Репліки об'єднано (" .. #selected_entries .. ")")
                        end
                    elseif (has_merge and ret == 3) or (not has_merge and ret == 2) then
                        -- Delete Selected Replicas
                        local selected_entries = {}
                        for p, l in ipairs(ass_lines) do
                            if table_selection[l.index or p] then
                                table.insert(selected_entries, {line = l, pos = p})
                            end
                        end
                        
                        if #selected_entries > 0 then
                            push_undo("Видалення реплік")
                            
                            -- Sort by position descending to safely remove
                            table.sort(selected_entries, function(a,b) return a.pos > b.pos end)
                            
                            for _, ent in ipairs(selected_entries) do
                                 table.remove(ass_lines, ent.pos)
                            end
                            
                            table_selection = {}
                            last_selected_row = nil
                            
                            cleanup_actors()
                            rebuild_regions()
                            save_project_data(last_project_id)
                            show_snackbar("Видалено реплік: " .. #selected_entries)
                        end
                    end
                end
            end
        else
            -- Fallback: regions mode (no ASS)
            local rgn = data_source[i]
            if rgn then
                local play_pos = reaper.GetPlayPosition()
                if play_pos >= rgn.pos and play_pos < rgn.rgnend then
                     set_color({0.3, 0.4, 0.2, 0.4})
                     gfx.rect(0, screen_y, gfx.w, row_h, 1)
                end
                
                set_color(UI.C_TXT)
                local y_text = screen_y + 4
                
                gfx.x = x_off[1]; gfx.y = y_text; gfx.drawstr(tostring(rgn.index or i))
                gfx.x = x_off[2]; gfx.y = y_text; gfx.drawstr(reaper.format_timestr(rgn.pos, ""))
                gfx.x = x_off[3]; gfx.y = y_text; gfx.drawstr(reaper.format_timestr(rgn.rgnend, ""))
                
                -- CPS for regions
                local duration = rgn.rgnend - rgn.pos
                local clean_text = (rgn.name or ""):gsub(acute, ""):gsub("%s+", "")
                local char_count = utf8.len(clean_text) or #clean_text
                local cps = duration > 0 and (char_count / duration) or 0
                
                local cps_color = get_cps_color(cps)
                
                set_color(cps_color)
                gfx.x = x_off[4]; gfx.y = y_text; gfx.drawstr(string.format("%.1f", cps))
                
                set_color(UI.C_TXT)
                local rgn_text = (rgn.name or ""):gsub("[\n\r]", " ")
                local display_rgn = fit_text_width(rgn_text, gfx.w - x_off[5] - 10)
                gfx.x = x_off[5]; gfx.y = y_text; gfx.drawstr(display_rgn)
                
                if is_mouse_clicked() then
                    if gfx.mouse_y >= screen_y and gfx.mouse_y < screen_y + row_h then
                        reaper.SetEditCurPos(rgn.pos, true, false)
                    end
                end
            end
        end
        ::continue::
    end
    
    -- Scrollbar
    target_scroll_y = draw_scrollbar(gfx.w - 10, content_y, 10, avail_h, total_h, avail_h, target_scroll_y)
    
    -- Draw Header LAST (always on top)
    set_color({0.1, 0.1, 0.1})
    gfx.rect(0, start_y, gfx.w, h_header, 1)
    
    local function draw_header_cell(idx, label, x, y, col_name)
        local next_x = x_off[idx + 1] or gfx.w
        local cell_w = next_x - x
        local arrow_w = 12
        local text_padding = 5
        
        -- Truncate label if it doesn't fit with arrow
        local max_text_w = cell_w - arrow_w - text_padding
        local display_label = fit_text_width(label, max_text_w)
        
        set_color(UI.C_TXT)
        gfx.x = x; gfx.y = y; 
        gfx.drawstr(display_label)
        local dspt_w, dspt_h = gfx.measurestr(display_label)
        
        -- Draw vector arrow if sorted
        if table_sort.col == col_name then
            local ax = x + dspt_w
            local ay = y + 4.5
            set_color(UI.C_TXT)
            if table_sort.dir == 1 then
                -- Up arrow ▲
                gfx.line(ax + 2, ay + 6, ax + 5, ay + 2)
                gfx.line(ax + 5, ay + 2, ax + 8, ay + 6)
                gfx.line(ax + 3, ay + 6, ax + 7, ay + 6)
            else
                -- Down arrow ▼
                gfx.line(ax + 2, ay + 2, ax + 5, ay + 6)
                gfx.line(ax + 5, ay + 6, ax + 8, ay + 2)
                gfx.line(ax + 3, ay + 2, ax + 7, ay + 2)
            end
        end
        
        -- Click detection
        if is_mouse_clicked() then
            if gfx.mouse_y >= start_y and gfx.mouse_y < start_y + h_header then
                if gfx.mouse_x >= x and gfx.mouse_x < next_x then
                    if table_sort.col == col_name then
                        table_sort.dir = table_sort.dir * -1
                    else
                        table_sort.col = col_name
                        table_sort.dir = 1
                    end
                end
            end
        end
    end

    if show_actor then
        draw_header_cell(1, "Ак.", x_off[1], header_y, "Ак.")
        draw_header_cell(2, "#", x_off[2], header_y, "#")
        draw_header_cell(3, "Початок", x_off[3], header_y, "Початок")
        draw_header_cell(4, "Кінець", x_off[4], header_y, "Кінець")
        draw_header_cell(5, "CPS", x_off[5], header_y, "CPS")
        draw_header_cell(6, "Актор", x_off[6], header_y, "Актор")
        draw_header_cell(7, "Репліка", x_off[7], header_y, "Репліка")
    else
        draw_header_cell(1, "#", x_off[1], header_y, "#")
        draw_header_cell(2, "Початок", x_off[2], header_y, "Початок")
        draw_header_cell(3, "Кінець", x_off[3], header_y, "Кінець")
        draw_header_cell(4, "CPS", x_off[4], header_y, "CPS")
        draw_header_cell(5, "Репліка", x_off[5], header_y, "Репліка")
    end
end

-- --- Main Loop ---
local function main()
    mouse_handled = false
    -- Check if project changed (tab switch)
    local current_project_id = tostring(reaper.EnumProjects(-1))
    if current_project_id ~= last_project_id then
        save_session_state(last_project_id)
        last_project_id = current_project_id
        load_project_data()
        load_session_state(current_project_id)
        update_regions_cache()
        proj_change_count = reaper.GetProjectStateChangeCount(0)
    end
    
    local curs_state = reaper.GetProjectStateChangeCount(0)
    if curs_state ~= proj_change_count then
        update_regions_cache()
        proj_change_count = curs_state
    end

    -- --- INPUT GATHERING ---
    local input_queue = {}
    local char = gfx.getchar()
    while char ~= 0 do
        if char == -1 then return -- EXIT on window close
        else
            table.insert(input_queue, char)
        end
        char = gfx.getchar() -- Consume next
    end

    -- --- UNDO HANDLING (GLOBAL) ---
    if not text_editor_active then
        for _, c in ipairs(input_queue) do
            if c == 26 then -- Ctrl+Z / Cmd+Z
                if gfx.mouse_cap & 8 ~= 0 then -- Shift is held
                    redo_action()
                else
                    undo_action()
                end
                break
            end
        end
    end

    set_color(UI.C_BG)
    gfx.rect(0, 0, gfx.w, gfx.h, 1)
    
    -- Only draw main content if text editor not active
    if not text_editor_active then
        if current_tab == 1 then 
            handle_drag_drop()
            draw_file()
        elseif current_tab == 2 then draw_table(input_queue)
        elseif current_tab == 3 then draw_prompter() 
        elseif current_tab == 4 then draw_settings() end
        
        -- Draw Tabs LAST (Z-Index top)
        draw_tabs()
        
        -- Dictionary Modal (Z-index top-most)
        if dict_modal.show then
            draw_dictionary_modal(input_queue)
        end
        
        -- Context Menu logic (Right-click on tab bar / empty space)
        -- Must strictly check mouse_handled AND window bounds to avoid global capture.
        local inside_window = gfx.mouse_x >= 0 and gfx.mouse_x <= gfx.w and gfx.mouse_y >= 0 and gfx.mouse_y <= gfx.h
        
        if inside_window and gfx.mouse_cap == 2 and last_mouse_cap == 0 and not mouse_handled then
            gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
            local dock_state = gfx.dock(-1)
            local check = (dock_state > 0) and "!" or ""
            local ret = gfx.showmenu(check .. "Dock Window")
            if ret == 1 then
                local target_dock = dock_state > 0 and 0 or 1
                gfx.dock(target_dock)
                last_dock_state = gfx.dock(-1) -- Get the actual new index
                save_settings()
            end
        end
    else
        -- Draw text editor overlay
        -- Pass input queue to editor
        draw_text_editor(input_queue)
    end

    draw_snackbar()
    draw_tooltip()

    local cur_dock = gfx.dock(-1)
    if cur_dock > 0 and cur_dock ~= last_dock_state then
        last_dock_state = cur_dock
        reaper.SetExtState(section_name, "dock", tostring(last_dock_state), true)
    elseif cur_dock == 0 and last_dock_state ~= 0 then
        -- Only set to 0 if the window is actually floating and NOT closing
        -- This is a bit tricky, but checking if char != -1 helps
        if gfx.getchar() ~= -1 then
            last_dock_state = 0
            reaper.SetExtState(section_name, "dock", "0", true)
        end
    end

    last_mouse_cap = gfx.mouse_cap
    gfx.update()

    -- Handle Async Stress Job
    if current_stress_job then
        local status = coroutine.status(current_stress_job)
        if status == "suspended" then
            local ok, err = coroutine.resume(current_stress_job)
            if not ok then
                reaper.ShowConsoleMsg("Coroutine Error: " .. tostring(err) .. "\n")
                current_stress_job = nil
                script_loading_state.active = false
            end
        elseif status == "dead" then
            current_stress_job = nil
            -- Only hide loader if no other async tasks are running
            if #global_async_pool == 0 then
                script_loading_state.active = false
            end
        end
    end

    check_async_pool()
    draw_loader()
    
    reaper.defer(main)
end

update_regions_cache()
reaper.atexit(save_settings)

main()
