-- @description Subass Notes (SRT Manager - Native GFX)
-- @version 4.8.2
-- @author Fusion (Fusion Dub)
-- @about Subtitle manager using native Reaper GFX. (required: SWS, ReaImGui, js_ReaScriptAPI)

-- Clear force close signal for other scripts on startup
reaper.SetExtState("Subass_Global", "ForceCloseComplementary", "0", false)

local section_name = "Subass_Notes"

local GL = {
    script_title = "Subass Notes v4.8.2",
    last_dock_state = reaper.GetExtState(section_name, "dock"),
}

if GL.last_dock_state == "" then GL.last_dock_state = 0 else GL.last_dock_state = tonumber(GL.last_dock_state) end

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
    p_lheight = get_set("p_lheight", 1.1),
    n_lheight = get_set("n_lheight", 1.1),
    c_lheight = get_set("c_lheight", 1.0),
    
    n_fsize = get_set("n_fsize", 22),
    n_cr = get_set("n_cr", 0.17),
    n_cg = get_set("n_cg", 0.17),
    n_cb = get_set("n_cb", 0.17),

    t_ar_r = get_set("t_ar_r", 0.2),
    t_ar_g = get_set("t_ar_g", 0.9),
    t_ar_b = get_set("t_ar_b", 0.2),
    t_ar_alpha = get_set("t_ar_alpha", 0.1),
    t_r_size = get_set("t_r_size", "tr_M"),
    
    next_attach = (get_set("next_attach", "0") == "1" or get_set("next_attach", 0) == 1),
    next_padding = get_set("next_padding", 30),
    show_next_two = (get_set("show_next_two", "0") == "1" or get_set("show_next_two", 0) == 1),

    wrap_length = get_set("wrap_length", 42),
    always_next = (get_set("always_next", "1") == "1" or get_set("always_next", 1) == 1),
    random_color_actors = (get_set("random_color_actors", "1") == "1" or get_set("random_color_actors", 1) == 1),
    text_assimilations = (get_set("text_assimilations", "1") == "1" or get_set("text_assimilations", 1) == 1),
    fix_CP1251 = (get_set("fix_CP1251", "0") == "1" or get_set("fix_CP1251", 0) == 1),

    karaoke_mode = (get_set("karaoke_mode", "0") == "1" or get_set("karaoke_mode", 0) == 1),
    all_caps = (get_set("all_caps", "0") == "1" or get_set("all_caps", 0) == 1),
    show_actor_name_infront = (get_set("show_actor_name_infront", "0") == "1" or get_set("show_actor_name_infront", 0) == 1),
    wave_bg = (get_set("wave_bg", "1") == "1" or get_set("wave_bg", 1) == 1),
    wave_bg_progress = (get_set("wave_bg_progress", "0") == "1" or get_set("wave_bg_progress", 0) == 1),
    count_timer = (get_set("count_timer", "1") == "1" or get_set("count_timer", 1) == 1),
    count_timer_bottom = (get_set("count_timer_bottom", "0") == "1" or get_set("count_timer_bottom", 0) == 1),
    cps_warning = (get_set("cps_warning", "1") == "1" or get_set("cps_warning", 1) == 1),
    bg_cr = get_set("bg_cr", 0.67),
    bg_cg = get_set("bg_cg", 0.69),
    bg_cb = get_set("bg_cb", 0.69),
    p_align = get_set("p_align", "center"),
    p_valign = get_set("p_valign", "center"),
    p_font = get_set("p_font", "Arial"),
    p_info = (get_set("p_info", "1") == "1" or get_set("p_info", 1) == 1),
    auto_srt_split = get_set("auto_srt_split", "():"),
    prmt_theme = get_set("prmt_theme", "Бетон"),
    ui_theme = get_set("ui_theme", "Titanium"),
    gemini_api_key = get_set("gemini_api_key", ""),
    eleven_api_key = get_set("eleven_api_key", ""),
    p_drawer = (get_set("p_drawer", "1") == "1" or get_set("p_drawer", 1) == 1),
    p_drawer_left = (get_set("p_drawer_left", "1") == "1" or get_set("p_drawer_left", 1) == 1),
    p_corr = (get_set("p_corr", "1") == "1" or get_set("p_corr", 1) == 1),
    c_fsize = get_set("c_fsize", 18),
    c_cr = get_set("c_cr", 1.0),
    c_cg = get_set("c_cg", 0.3),
    c_cb = get_set("c_cb", 0.3),
    
    reader_mode = (get_set("reader_mode", "0") == "1" or get_set("reader_mode", 0) == 1),
    auto_startup = (get_set("auto_startup", "0") == "1" or get_set("auto_startup", 0) == 1),
    gemini_key_status = tonumber(reaper.GetExtState(section_name, "gemini_key_status")) or 0,
    eleven_key_status = tonumber(reaper.GetExtState(section_name, "eleven_key_status")) or 0,

    col_table_index = (get_set("col_table_index", "1") == "1" or get_set("col_table_index", 1) == 1),
    col_table_start = (get_set("col_table_start", "1") == "1" or get_set("col_table_start", 1) == 1),
    col_table_end = (get_set("col_table_end", "1") == "1" or get_set("col_table_end", 1) == 1),
    col_table_cps = (get_set("col_table_cps", "1") == "1" or get_set("col_table_cps", 1) == 1),
    col_table_actor = (get_set("col_table_actor", "1") == "1" or get_set("col_table_actor", 1) == 1),
    
    show_markers_in_table = (get_set("show_markers_in_table", "1") == "1" or get_set("show_markers_in_table", 1) == 1),

    -- Column Widths
    col_w_enabled = get_set("col_w_enabled", 25),
    col_w_index = get_set("col_w_index", 35),
    col_w_start = get_set("col_w_start", 75),
    col_w_end = get_set("col_w_end", 73),
    col_w_cps = get_set("col_w_cps", 55),
    col_w_actor = get_set("col_w_actor", 100),

    gui_scale = get_set("gui_scale", 1.1),
    director_mode = (get_set("director_mode", "0") == "1" or get_set("director_mode", 0) == 1),
    director_layout = get_set("director_layout", "bottom"),
    prompter_slider_mode = (get_set("prompter_slider_mode", "0") == "1" or get_set("prompter_slider_mode", 0) == 1),
    auto_trim = (get_set("auto_trim", "0") == "1" or get_set("auto_trim", 0) == 1),
    trim_start = get_set("trim_start", 40),
    trim_end = get_set("trim_end", 80),
    check_clipping = (get_set("check_clipping", "1") == "1" or get_set("check_clipping", 1) == 1),

    tts_voice = get_set("tts_voice", "Горох: Оксана (Wavenet)"),
    tts_voice_map = {
        ["Горох: Оксана (Wavenet)"] = { engine = "goroh", voice = "uk-UA-Wavenet-A" },
        ["ElevenLabs: Ярослава (Yaroslava)"] = { engine = "eleven", voice = "Yaroslava" },
        ["ElevenLabs: Антон (Anton)"] = { engine = "eleven", voice = "Anton" },
        ["Системний"]  = { engine = "", voice = "System" }
    },
    tts_voices_order = {
        "Горох: Оксана (Wavenet)",
        "ElevenLabs: Ярослава (Yaroslava)",
        "ElevenLabs: Антон (Anton)",
        "Системний"
    },
    search_item_path = get_set("search_item_path", ""),
}

local OTHER = {
    col_resize = {
        dragging = false,
        key = nil,
        start_x = 0,
        start_w = 0
    },
    rec_state = {
        show = false,
        checked = false,
        checking = false, -- New flag for async check status
        sws = false,
        reapack = false,
        js_api = false,
        reaimgui = false,
        python = { ok = false, version = "N/A", executable = "python" },
        all_ok = false,
        scroll_y = 0,
        target_scroll_y = 0
    }
}

-- Global Scale Helper
local function S(val)
    return math.floor(val * cfg.gui_scale)
end

cfg.w_director = get_set("w_director", S(300))
cfg.h_director = get_set("h_director", S(120))

-- OS Detection for hybrid stress mark rendering
local is_windows = reaper.GetOS():match("Win") ~= nil

gfx.init(GL.script_title, 600, 400, GL.last_dock_state)
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
    tip = 9, -- 12px
    cor = 10, -- Corrections font
    tip_bld = 11, -- Bold tooltip font

    -- Table fonts
    tr_S = 12,
    tr_M = 13,
    tr_L = 14,
    tr_XL = 15,
    title = 16,
}

-- Prompter Rendering Cache (moved to global for invalidation on font change)
local draw_prompter_cache = {
    last_text = nil,
    lines = {},
    next_cache = {} -- Map of text -> parsed lines for Next replicas
}

local prompter_slider_cache = {
    state_count = -1,
    project_id = "",
    w = -1,
    fsize = -1,
    font = "",
    items = {}, -- { {h, lines}, ... }
    total_h = 0
}

--- Re-initialize prompter font slots and invalidate measurements
local function update_prompter_fonts()
    draw_prompter_cache.last_text = nil
    draw_prompter_cache.next_cache = {}
    
    -- Prompter-specific fonts (User Configurable)
    gfx.setfont(F.lrg, cfg.p_font, S(cfg.p_fsize))
    gfx.setfont(F.nxt, cfg.p_font, S(cfg.n_fsize))
    gfx.setfont(F.cor, cfg.p_font, S(cfg.c_fsize))

    -- UI Standard Fonts (Fixed but Scaled)
    gfx.setfont(F.std, "Arial", S(14))
    gfx.setfont(F.bld, "Arial", S(14), string.byte('b')) -- Reduced from 16
    gfx.setfont(F.title, "Arial", S(22), string.byte('b'))
    
    -- Dictionary Fonts
    gfx.setfont(F.dict_std, "Arial", S(17))
    gfx.setfont(F.dict_bld, "Arial", S(18), string.byte('b'))
    gfx.setfont(F.dict_std_sm, "Arial", S(16))
    gfx.setfont(F.dict_bld_sm, "Arial", S(16), string.byte('b'))
    
    -- Tooltip / Small Font
    gfx.setfont(F.tip, "Arial", S(12))
    gfx.setfont(F.tip_bld, "Arial", S(12), string.byte('b'))

    -- Reader Mode Table Font
    gfx.setfont(F.tr_S, cfg.p_font, S(18))
    gfx.setfont(F.tr_M, cfg.p_font, S(20))
    gfx.setfont(F.tr_L, cfg.p_font, S(24))
    gfx.setfont(F.tr_XL, cfg.p_font, S(30))

    -- Force re-measuring of text layout by clearing cache
    if draw_prompter_cache then
        draw_prompter_cache.last_text = nil
        draw_prompter_cache.last_next_text = nil
    end
end

-- Initial font setup
update_prompter_fonts()

-- Grouped State (to fix Lua local variable limit)
local UI_STATE = {
    tabs = {"Файл", "Репліки", "Суфлер", "Налаштування"},
    current_tab = get_set("last_tab", 1),
    last_mouse_cap = 0,
    mouse_handled = false,
    scroll_y = 0,
    target_scroll_y = 0,
    prompter_slider_y = 0,
    prompter_slider_target_y = 0,
    last_project_id = "",
    dash_scroll_y = 0,
    dash_target_scroll_y = 0,
    tab_scroll_y = {0, 0, 0, 0},
    tab_target_scroll_y = {0, 0, 0, 0},
    last_tracked_pos = 0,
    skip_auto_scroll = false,
    last_click_time = 0,
    last_click_row = 0,
    latched_overlay_time = nil,
    latched_overlay_region = nil,
    last_edit_cursor = 0,
    ass_file_loaded = false,
    current_file_name = nil,
    
    script_loading_state = {
        active = false,
        text = ""
    },
    
    tooltip_state = {
        hover_id = nil,
        text = "",
        start_time = 0,
        x = 0,
        y = 0,
        immediate = false
    },
    snackbar_state = {
        text = "",
        show_time = 0,
        duration = 3.0,
        type = "info"
    },
    last_is_recording = false,
    window_focused = true, -- Track if window is focused
    inside_window = false, -- Track if mouse is within window bounds
    AUTO_UPDATE_INTERVAL = 86400, -- 24 hours
    last_update_check_time = 0,
    is_restarting = false
}

local DEADLINE = {
    project_deadline = nil, -- Unix timestamp
    modal = {
        show = false,
        year = 0,
        month = 0,
        selected_day = 0,
        initial_date = nil, -- Store initial date for highlighting
        callback = nil,
        w = 340,
        h = 320,
        x = 0,
        y = 0
    }
}

local DUBBERS = {
    show_dashboard = false,
    active_dubber_idx = 1,
    data = {
        names = {}, -- List of dubber names
        assignments = {} -- Map of dubber_name -> { actor1 = true, actor2 = true }
    },
    scroll_y = 0,
    target_scroll_y = 0,
    last_project_id = "" -- Track project changes
}

local regions = {}
local proj_change_count = reaper.GetProjectStateChangeCount(0)

-- Text Editor Modal State
local text_editor_state = {
    text = "",
    cursor = 0,
    anchor = 0, -- renamed from sel_anchor for consistency
    line_idx = nil,
    callback = nil,
    history = {},
    history_pos = 0,
    scroll = 0,
    target_scroll = 0,
    suppress_auto_scroll_until = 0,
    active = false,
    focus = true, -- Default to focused when opened
    context_line_idx = nil, -- Index of current line being edited
    context_all_lines = nil, -- All lines for context
    needs_focus_nudge = 0, -- Frames to aggressively request focus
}

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
local table_sort = { col = "start", dir = 1 }
local table_layout_cache = {} -- Stores {y, h} for each row
local last_layout_state = { w = 0, count = 0, mode = nil, filter = "", sort_col = "", sort_dir = 0, gui_scale = 0 }
local table_selection = {} -- { [row_index] = true }
local table_data_cache = { state_count = -1, project_id = "", filter = "", sort_dir = 0, show_markers = nil, case_sensitive = nil, list = {} }
local last_selected_row = nil -- for Shift range selection

-- Constants
local acute = "\204\129" -- UTF-8 Combining Acute Accent (0xCC 0x81)

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
    history = {}, -- History stack for back navigation
    tts_loading = false, -- TTS loading state
    tts_preview = nil, -- Active audio preview handle
    tts_current_word = "", -- Word currently being processed for TTS
    selection = { active = false, start_x = 0, start_y = 0, end_x = 0, end_y = 0, text = "" } -- Text selection state
}

-- Director Mode State
local director_actors = {}
local director_state = {
    input = { text = "", cursor = 0, anchor = 0, focus = false },
    last_marker_id = nil,
    last_time = -1,
    original_text = "",
    pending_scroll_id = nil,
    has_recent_notes = false,
    recent_indices = {}
}

-- Proximity helper for marker detection
local function is_near(t1, t2) return math.abs(t1-t2) < 0.001 end

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
    triggered = false,
    hit_x = 0,
    hit_y = 0,
    hit_w = 0,
    hit_h = 0
}

-- Prompter Drawer State
local prompter_drawer = {
    open = false,
    width = get_set("prompter_drawer_width", 300),
    dragging = false,
    filter = {text = "", cursor = 0, anchor = 0, focus = false},
    scroll_y = 0,
    target_scroll_y = 0,
    last_active_markindex = -1,
    active_markindex = nil,
    last_click_time = 0,
    last_click_idx = -1,
    selection = {}, -- { [markindex] = true }
    last_selected_idx = nil, -- for Shift range selection
    has_markers_cache = { count = -1, result = false },
    marker_cache = { count = -1, markers = {} },
    filtered_cache = { state_count = -1, query = "", width = -1, gui_scale = -1, list = {}, total_h = 0 }
}

-- ═══════════════════════════════════════════════════════════════
-- STATISTICS MODULE - JSON Utilities & Data Tracking
-- ═══════════════════════════════════════════════════════════════

--- Statistics Module
local STATS = {
    file_path = nil, -- Will be set dynamically per project
    stats_dir = nil, -- Will be initialized below
    data = nil,
    dirty = false,
    last_save_time = 0,
    current_project_id = nil
}

-- Initialize stats directory path
do
    local script_path = debug.getinfo(1, "S").source:match("^@?(.+[/\\])") or ""
    STATS.stats_dir = script_path .. "stats/"
end

--- Simple JSON encoder (handles basic types: string, number, boolean, table)
function STATS.json_encode(val, indent)
    indent = indent or 0
    local t = type(val)
    
    if t == "string" then
        return '"' .. val:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r') .. '"'
    elseif t == "number" or t == "boolean" then
        return tostring(val)
    elseif t == "table" then
        local is_array = true
        local max_idx = 0
        local count = 0
        for k, v in pairs(val) do
            count = count + 1
            if type(k) ~= "number" or k < 1 or k ~= math.floor(k) then
                is_array = false
            else
                max_idx = math.max(max_idx, k)
            end
        end
        if is_array and count ~= max_idx then is_array = false end
        if count == 0 then
            -- Heuristic: if key is 'duration' or 'actors' (when array), it might be an array
            return "[]" 
        end
        
        local spacing = string.rep("  ", indent)
        local inner_spacing = string.rep("  ", indent + 1)
        
        if is_array then
            local parts = {}
            for i = 1, max_idx do
                table.insert(parts, inner_spacing .. STATS.json_encode(val[i], indent + 1))
            end
            return "[\n" .. table.concat(parts, ",\n") .. "\n" .. spacing .. "]"
        else
            local parts = {}
            local keys = {}
            for k in pairs(val) do table.insert(keys, tostring(k)) end
            table.sort(keys)
            
            for _, k_str in ipairs(keys) do
                local k = k_str
                if val[tonumber(k_str)] ~= nil then k = tonumber(k_str) end
                if val[k_str] == nil and val[k] == nil then k = k_str end 

                local v = val[k]
                local key_part = '"' .. tostring(k):gsub('\\', '\\\\'):gsub('"', '\\"') .. '"'
                table.insert(parts, inner_spacing .. key_part .. ": " .. STATS.json_encode(v, indent + 1))
            end
            return "{\n" .. table.concat(parts, ",\n") .. "\n" .. spacing .. "}"
        end
    else
        return "null"
    end
end

--- Simple JSON decoder (handles basic JSON structures)
function STATS.json_decode(str)
    if not str or str == "" then return nil end
    
    local pos = 1
    
    local function skip_whitespace()
        while pos <= #str and str:sub(pos, pos):match("%s") do
            pos = pos + 1
        end
    end
    
    local decode_value -- forward declaration
    
    local function decode_string()
        pos = pos + 1 -- skip opening "
        local res = ""
        while pos <= #str do
            local char = str:sub(pos, pos)
            if char == '"' then
                pos = pos + 1
                return res
            elseif char == '\\' then
                local next_char = str:sub(pos + 1, pos + 1)
                if next_char == 'n' then res = res .. "\n"
                elseif next_char == 'r' then res = res .. "\r"
                elseif next_char == 't' then res = res .. "\t"
                else res = res .. next_char end
                pos = pos + 2
            else
                res = res .. char
                pos = pos + 1
            end
        end
        return res
    end
    
    local function decode_number()
        local start = pos
        while pos <= #str and str:sub(pos, pos):match("[%d%.%-eE]") do
            pos = pos + 1
        end
        return tonumber(str:sub(start, pos - 1))
    end
    
    local function decode_array()
        pos = pos + 1 -- [
        local res = {}
        skip_whitespace()
        if str:sub(pos, pos) == "]" then
            pos = pos + 1
            return res
        end
        while pos <= #str do
            table.insert(res, decode_value())
            skip_whitespace()
            local char = str:sub(pos, pos)
            if char == "]" then
                pos = pos + 1
                return res
            elseif char == "," then
                pos = pos + 1
            end
        end
        return res
    end
    
    local function decode_object()
        pos = pos + 1 -- {
        local res = {}
        skip_whitespace()
        if str:sub(pos, pos) == "}" then
            pos = pos + 1
            return res
        end
        while pos <= #str do
            skip_whitespace()
            local key = decode_value()
            skip_whitespace()
            if str:sub(pos, pos) == ":" then
                pos = pos + 1
            end
            res[key] = decode_value()
            skip_whitespace()
            local char = str:sub(pos, pos)
            if char == "}" then
                pos = pos + 1
                return res
            elseif char == "," then
                pos = pos + 1
            end
        end
        return res
    end
    
    decode_value = function()
        skip_whitespace()
        local char = str:sub(pos, pos)
        if char == "{" then
            return decode_object()
        elseif char == "[" then
            return decode_array()
        elseif char == '"' then
            return decode_string()
        elseif char == "t" and str:sub(pos, pos+3) == "true" then
            pos = pos + 4
            return true
        elseif char == "f" and str:sub(pos, pos+4) == "false" then
            pos = pos + 5
            return false
        elseif char == "n" and str:sub(pos, pos+3) == "null" then
            pos = pos + 4
            return nil
        else
            return decode_number()
        end
    end
    
    local ok, res = pcall(decode_value)
    if not ok then 
        reaper.ShowConsoleMsg("JSON Decode Error: " .. tostring(res) .. " at pos " .. pos .. "\n")
        return {} 
    end
    return res
end


--- Generate unique project ID from project path
function STATS.get_project_id()
    local proj_path = reaper.GetProjectPath("") .. "/" .. reaper.GetProjectName(0, "")
    if proj_path == "/" then return nil end -- No project loaded
    
    -- Simple hash: sum of character codes
    local hash = 0
    for i = 1, #proj_path do
        hash = (hash * 31 + string.byte(proj_path, i)) % 0xFFFFFFFF
    end
    return string.format("%08x", hash)
end

--- Get current date string (YYYY-MM-DD)
function STATS.get_date_string()
    return os.date("%Y-%m-%d")
end

--- Get file path for current project (creates new file with date if needed)
function STATS.get_project_file_path()
    local proj_id = STATS.get_project_id()
    if not proj_id then return nil end
    
    -- Check if we already have a file path for this project
    if STATS.current_project_id == proj_id and STATS.file_path then
        return STATS.file_path
    end
    
    -- Look for existing file for this project
    local pattern = "stats_" .. proj_id .. "_*.json"
    local files = {}
    
    -- Scan stats directory for matching files
    local i = 0
    repeat
        local file = reaper.EnumerateFiles(STATS.stats_dir, i)
        if file and file:match("^stats_" .. proj_id .. "_") then
            table.insert(files, file)
        end
        i = i + 1
    until not file
    
    -- Use existing file or create new one with current date
    local filename
    if #files > 0 then
        -- Use the first (oldest) file found
        table.sort(files)
        filename = files[1]
    else
        -- Create new file with current date
        filename = "stats_" .. proj_id .. "_" .. STATS.get_date_string() .. ".json"
    end
    
    STATS.current_project_id = proj_id
    STATS.file_path = STATS.stats_dir .. filename
    return STATS.file_path
end

--- Load statistics from file
function STATS.load()
    local file_path = STATS.get_project_file_path()
    if not file_path then
        STATS.data = nil
        return
    end
    
    local file = io.open(file_path, "r")
    if not file then
        -- Initialize default structure for this project
        STATS.data = {
            meta_version = 1,
            project_id = STATS.get_project_id(),
            project_name = reaper.GetProjectName(0, ""),
            project_path = reaper.GetProjectPath("") .. "/" .. reaper.GetProjectName(0, ""),
            created_date = STATS.get_date_string(),
            last_updated = os.time(),
            metadata = {
                total_lines_in_script = 0,
                total_words = 0,
                edits_count = 0
            },
            total = {
                lines_recorded = 0
            },
            duration = {},
            daily_stats = {}
        }
        STATS.dirty = true
        return
    end
    
    local content = file:read("*all")
    file:close()
    
    local decoded = STATS.json_decode(content)
    if decoded and decoded.project_id then
        STATS.data = decoded
        if not STATS.data.duration then STATS.data.duration = {} end
    else
        -- Fallback: initialize default structure
        STATS.data = {
            meta_version = 1,
            project_id = STATS.get_project_id(),
            project_name = reaper.GetProjectName(0, ""),
            project_path = reaper.GetProjectPath("") .. "/" .. reaper.GetProjectName(0, ""),
            created_date = STATS.get_date_string(),
            last_updated = os.time(),
            metadata = {
                total_lines_in_script = 0,
                total_words = 0,
                edits_count = 0
            },
            total = {
                lines_recorded = 0
            },
            duration = {},
            daily_stats = {}
        }
        STATS.dirty = true
    end
end

--- Save statistics to file
function STATS.save()
    if not STATS.data or not STATS.dirty then return end
    
    local file_path = STATS.get_project_file_path()
    if not file_path then return end
    
    -- Ensure directory exists
    local dir = STATS.file_path:match("^(.+[/\\])")
    if dir then
        reaper.RecursiveCreateDirectory(dir, 0)
    end
    
    local file = io.open(file_path, "w")
    if not file then return end
    
    file:write(STATS.json_encode(STATS.data))
    file:close()
    
    STATS.dirty = false
    STATS.last_save_time = reaper.time_precise()
end

--- Get or create project entry (now returns the main data object)
function STATS.get_project()
    if not STATS.data then
        STATS.load()
    end
    
    -- Reload if project changed
    local current_proj_id = STATS.get_project_id()
    if current_proj_id ~= STATS.current_project_id then
        STATS.load()
    end
    
    return STATS.data
end

--- Increment outside recordings counter
function STATS.increment_outside()
    local proj = STATS.get_project()
    if not proj then return end
    
    local date = STATS.get_date_string()
    
    -- Ensure daily stats entry exists
    if not proj.daily_stats[date] then
        proj.daily_stats[date] = {
            lines = 0,
            actors = {}
        }
    end
    
    -- Initialize outside counter if missing
    if not proj.total.lines_recorded_outside then
        proj.total.lines_recorded_outside = 0
    end
    if not proj.daily_stats[date].lines_outside then
        proj.daily_stats[date].lines_outside = 0
    end
    
    -- Increment counters
    proj.total.lines_recorded_outside = proj.total.lines_recorded_outside + 1
    proj.daily_stats[date].lines_outside = proj.daily_stats[date].lines_outside + 1
    
    proj.last_updated = os.time()
    STATS.dirty = true
end


--- Increment recorded lines counter
function STATS.increment_recorded(actor_name)
    local proj = STATS.get_project()
    if not proj then return end
    
    local date = STATS.get_date_string()
    
    -- Ensure daily stats entry exists
    if not proj.daily_stats[date] then
        proj.daily_stats[date] = {
            lines = 0,
            actors = {}
        }
    end
    
    -- Increment counters
    proj.total.lines_recorded = proj.total.lines_recorded + 1
    proj.daily_stats[date].lines = proj.daily_stats[date].lines + 1
    
    -- Track per-actor
    if actor_name then
        if not proj.daily_stats[date].actors[actor_name] then
            proj.daily_stats[date].actors[actor_name] = { lines = 0 }
        end
        proj.daily_stats[date].actors[actor_name].lines = proj.daily_stats[date].actors[actor_name].lines + 1
    end
    
    proj.last_updated = os.time()
    STATS.dirty = true
end

--- Increment edits counter
function STATS.increment_edit()
    local proj = STATS.get_project()
    if not proj then return end
    
    proj.metadata.edits_count = proj.metadata.edits_count + 1
    proj.last_updated = os.time()
    STATS.dirty = true
end

--- Initialize stats on script load
STATS.load()


--- Update the global marker cache used by both drawer and prompter
local function update_marker_cache()
    local state_count = reaper.GetProjectStateChangeCount(0)
    if state_count ~= prompter_drawer.marker_cache.count then
        prompter_drawer.marker_cache.count = state_count
        prompter_drawer.marker_cache.markers = {}
        local count = reaper.CountProjectMarkers(0)
        for i = 0, count - 1 do
            local retval, isrgn, pos, rgnend, name, markindex, color = reaper.EnumProjectMarkers3(0, i)
            if not isrgn then
                table.insert(prompter_drawer.marker_cache.markers, {
                    markindex = markindex,
                    enum_idx = i, -- Store internal REAPER index
                    name = (name == "" and "<пусто>" or name),
                    pos = pos,
                    color = (color ~= 0 and color or nil)
                })
            end
        end
    end
end

math.random(); math.random(); math.random() -- Warm up

-- Find and Replace State
local find_replace_state = {
    show = false,
    find = {text = "", cursor = 0, anchor = 0, focus = true},
    replace = {text = "", cursor = 0, anchor = 0, focus = false},
    case_sensitive = false,
    bounds = {x=0, y=0, w=0, h=0}
}
 
-- Column Visibility Menu State
local col_vis_menu = {
    show = false,
    x = 0,
    y = 0,
    w = 180,
    h = 0 -- Calculated dynamically
}

local time_shift_menu = {
    show = false,
    x = 0,
    y = 0,
    w = 280,
    only_selected = false
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
    UI_STATE.tab_scroll_y[UI_STATE.current_tab] = UI_STATE.scroll_y
    UI_STATE.tab_target_scroll_y[UI_STATE.current_tab] = UI_STATE.target_scroll_y

    session_states[id] = {
        current_tab = UI_STATE.current_tab,
        tab_scroll_y = {table.unpack(UI_STATE.tab_scroll_y)},
        tab_target_scroll_y = {table.unpack(UI_STATE.tab_target_scroll_y)},
        -- Editor state
        text_editor_state = deep_copy(text_editor_state),
        -- Modal states (minimal)
        ai_modal_show = ai_modal.show,
        ai_modal_step = ai_modal.current_step,
        dict_modal_show = dict_modal.show,
        -- Table state
        table_filter_state = deep_copy(table_filter_state),
        find_replace_state = deep_copy(find_replace_state),
        table_selection = deep_copy(table_selection),
        table_sort = deep_copy(table_sort),
        last_selected_row = last_selected_row,
        -- Prompter Drawer state
        prompter_drawer = deep_copy(prompter_drawer)
    }
    -- Ensure selection is explicitly saved if deep_copy misses it or for clarity
    session_states[id].prompter_drawer_selection = deep_copy(prompter_drawer.selection)
    session_states[id].prompter_drawer_last_selected_idx = prompter_drawer.last_selected_idx
end

--- Load UI state for the specific project tab
local function load_session_state(id)
    local state = session_states[id]
    if state then
        UI_STATE.current_tab = state.current_tab or 3
        UI_STATE.tab_scroll_y = {table.unpack(state.tab_scroll_y or {0,0,0,0})}
        UI_STATE.tab_target_scroll_y = {table.unpack(state.tab_target_scroll_y or {0,0,0,0})}
        -- Sync global scroll from restored active tab state
        UI_STATE.scroll_y = UI_STATE.tab_scroll_y[UI_STATE.current_tab] or 0
        UI_STATE.target_scroll_y = UI_STATE.tab_target_scroll_y[UI_STATE.current_tab] or 0
        -- Editor
        if state.text_editor_state then
            text_editor_state = deep_copy(state.text_editor_state)
        end
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
        if state.prompter_drawer then 
            prompter_drawer.open = state.prompter_drawer.open or false
            prompter_drawer.width = state.prompter_drawer.width or prompter_drawer.width
            if state.prompter_drawer.filter then
                prompter_drawer.filter = deep_copy(state.prompter_drawer.filter)
            end
            prompter_drawer.scroll_y = state.prompter_drawer.scroll_y or 0
            prompter_drawer.selection = deep_copy(state.prompter_drawer_selection or {})
            prompter_drawer.last_selected_idx = state.prompter_drawer_last_selected_idx
        end
    else
        -- Defaults for new project session
        text_editor_state.active = false
        if ai_modal then ai_modal.show = false ai_modal.current_step = "SELECT_TASK" end
        if dict_modal then dict_modal.show = false end
        table_selection = {}
        last_selected_row = nil
        -- Reset drawer for new project
        prompter_drawer.open = false
        prompter_drawer.filter.text = ""
        prompter_drawer.filter.cursor = 0
        prompter_drawer.scroll_y = 0
    end
end

-- =============================================================================
-- DATA STRUCTURES
-- =============================================================================

-- ASS/Subtitle Data
local ass_lines = {}
local ass_actors = {}
local ass_markers = {} -- { {pos, name, markindex, color}, ... }
local actor_colors = {} -- {ActorName = integerColor}

UI_STATE.ass_file_loaded = false
UI_STATE.current_file_name = nil
UI_STATE.current_file_path = nil

--- Update project metadata (total lines, words)
function STATS.update_metadata()
    local proj = STATS.get_project()
    if not proj then return end
    
    local total_lines = 0
    local total_words = 0
    local selected_lines = 0
    local selected_words = 0
    local actor_stats = {}
    
    -- Iterate ass_lines directly (defined locally above)
    if ass_lines then
        for _, line in ipairs(ass_lines) do
            -- Count every line (we want total lines in script)
            total_lines = total_lines + 1
            
            -- Word count logic matching line 10094 (strip tags, convert breaks, count non-whitespace)
            local clean = (line.text or ""):gsub("{.-}", ""):gsub("\\[Nnh]", " ")
            local _, count = clean:gsub("%S+", "")
            total_words = total_words + count
            
            -- Count selected/enabled lines
            if line.enabled ~= false then
                selected_lines = selected_lines + 1
                selected_words = selected_words + count
            end
            
            -- Track per-actor stats (total in script)
            local actor = line.actor
            if actor and actor ~= "" then
                if not actor_stats[actor] then
                    -- Check selection status from ass_actors global table
                    -- ass_actors[name] is true if selected/visible, nil/false if hidden
                    local is_selected = false
                    if ass_actors and ass_actors[actor] == true then
                        is_selected = true
                    end

                    actor_stats[actor] = {
                        lines = 0,
                        words = 0,
                        id = actor,
                        selected = is_selected
                    }
                end
                actor_stats[actor].lines = actor_stats[actor].lines + 1
                actor_stats[actor].words = actor_stats[actor].words + count
            end
        end
    end
    
    -- Always update metadata if values differ
    -- We'll assume if total counts changed, actor stats might have too, so we update the actors table
    if proj.metadata.total_lines_in_script ~= total_lines or 
       proj.metadata.total_words ~= total_words or
       proj.metadata.selected_lines_count ~= selected_lines or
       proj.metadata.selected_words_count ~= selected_words or
       not proj.metadata.actors or
       (total_lines > 0 and proj.metadata.total_lines_in_script == 0) then
        proj.metadata.total_lines_in_script = total_lines
        proj.metadata.total_words = total_words
        proj.metadata.selected_lines_count = selected_lines
        proj.metadata.selected_words_count = selected_words
        proj.metadata.actors = actor_stats
        proj.last_updated = os.time()
        STATS.dirty = true
    end
end

local UI = {
    -- === 1. Core Interface ===
    C_SEL_BG = {0.3, 0.6, 1.0, 0.15},  -- Subtle selection background (blue tint)

    -- === 2. Buttons ===
    C_BTN_DARK = {0.3, 0.4, 0.3, 1},    -- Muted/Dark button background

    -- === 3. Notifications (Snackbars) ===
    C_SNACK_SUCCESS = {0.1, 0.35, 0.1, 0.95}, -- Success message background
    C_SNACK_ERROR = {0.4, 0.1, 0.1, 0.95},   -- Error message background
    C_SNACK_WARN = {0.35, 0.3, 0.1, 0.95},    -- Warning message background
    C_SNACK_BORDER = {0.4, 0.4, 0.4, 1.0},   -- Snackbar border color
    C_SNACK_TXT = {1, 1, 1, 1.0},            -- Snackbar text color
    C_SNACK_SHADOW = {0, 0, 0, 0.3},         -- Snackbar shadow

    -- === 4. Modals & Overlays (Frames) ===
    C_FR_BG = {0, 0, 0, 0.5},                -- Modal/Frame overlay background
    C_FR_BORDER = {0.4, 0.4, 0.4, 0.5},      -- Modal/Frame border
    C_FR_CLOSE = {0.8, 0.3, 0.3},            -- Close button highlight (reddish)
    C_FR_MATCH_BG = {0.2, 0.25, 0.3, 1.0},   -- "Match" state background in modals
    C_FR_MATCH_INA = {0.14, 0.14, 0.14, 1.0}, -- Inactive "Match" state
    C_FR_MATCH_BORDER = {0.3, 0.3, 0.3, 1.0}, -- "Match" state border
    C_FR_MATCH_TXT = {1, 1, 1, 1.0},         -- "Match" state text

    -- === 5. Text Editor Syntax ===
    C_ED_HILI_G = {0.5, 0.8, 0.3, 0.2},      -- Green highlight (subtle)
    C_ED_HILI_B = {0.3, 0.4, 0.7, 0.5},      -- Blue highlight (stronger)
    C_ED_GUTTER = {0.5, 0.5, 0.5},           -- Gutter color (line numbers)

    -- === 6. Status & Semantic Highlights ===
    C_HILI_RED = {1.0, 0.3, 0.3, 0.2},
    C_HILI_BLUE = {0.0, 0.4, 1.0, 0.3},
    C_HILI_GREEN = {0.1, 0.35, 0.2, 0.5},
    C_HILI_YELLOW = {1, 1, 0, 0.3},
    C_HILI_WHITE = {1, 1, 1, 0.1},
    C_HILI_WHITE_LOW = {1, 1, 1, 0.05},
    C_HILI_WHITE_MID = {1, 1, 1, 0.3},
    C_HILI_WHITE_BRIGHT = {1, 1, 1, 0.2},
    C_HILI_GREY_LOW = {0.5, 0.5, 0.5, 0.3},
    C_HILI_GREY_MID = {0.5, 0.5, 0.5, 0.6},
    C_HILI_GREY_HIGH = {0.5, 0.5, 0.5, 0.8},
    C_BORDER_MUTED = {0.5, 0.5, 0.5, 0.5},
    C_SHADOW = {0, 0, 0, 0.3},

    -- === 7. Standard Color Palette ===
    C_WHITE = {1, 1, 1, 1},
    C_BLACK = {0, 0, 0, 1},
    C_RED = {1, 0.3, 0.3, 1},
    C_GREEN = {0.2, 0.8, 0.2, 1},
    C_ORANGE = {1, 0.5, 0, 1},
    C_YELLOW = {1, 0.9, 0, 1},
    C_DARK_GREY = {0.15, 0.15, 0.15, 1},
    C_BLUE_BRIGHT = {0.3, 0.6, 1, 1},

    -- === 8. Specialized Elements ===
    C_RESIZE_HDL = {0.5, 0.5, 0.8, 0.6},      -- Resize handle color
    C_BLACK_OVERLAY = {0, 0, 0, 0.5},         -- General dark overlay
    C_BLACK_TRANSP = {0, 0, 0, 0.5},          -- Semi-transparent black
    C_HILI_BLUE_LIGHT = {0.4, 0.7, 1.0, 1},
    C_HILI_RED_DARK = {0.6, 0.1, 0.1, 1},
    C_HILI_RED_BRIGHT = {0.8, 0.2, 0.2, 1},

    -- === 9. Dynamic Color Helpers ===
    -- Use these to get colors that react to user configuration (cfg.*)
    GET_T_AR_COLOR = function(a) return {cfg.t_ar_r, cfg.t_ar_g, cfg.t_ar_b, a} end, -- Table active row Color
    GET_P_COLOR = function(a) return {cfg.p_cr, cfg.p_cg, cfg.p_cb, a} end, -- Prompter Color
    GET_N_COLOR = function(a) return {cfg.n_cr, cfg.n_cg, cfg.n_cb, a} end, -- Note Color
    GET_C_COLOR = function(a) return {cfg.c_cr, cfg.c_cg, cfg.c_cb, a} end, -- Correction Color
    GET_BG_COLOR = function(a) return {cfg.bg_cr, cfg.bg_cg, cfg.bg_cb, a} end -- Custom Background
}

UI.UI_THEMES = {
    ["Titanium"] = {
        C_BG = {0.15, 0.15, 0.15},
        C_TXT = {0.9, 0.9, 0.9},
        C_BTN = {0.3, 0.3, 0.3},
        C_BTN_H = {0.4, 0.4, 0.4},
        C_ROW = {0.2, 0.2, 0.2},
        C_ROW_ALT = {0.23, 0.23, 0.23},
        C_SEL = {0.6, 0.7, 0.9},
        C_TAB_ACT = {0.25, 0.25, 0.25},
        C_TAB_INA = {0.2, 0.2, 0.2},
        C_SNACK_INFO = {0.1, 0.1, 0.1},      -- Darker Header
        C_LIGHT_GREY = {0.7, 0.7, 0.7},     -- Section Title
        C_MEDIUM_GREY = {0.3, 0.3, 0.3},    -- Section Line
        C_HILI_HEADER = {0.2, 0.3, 0.35},   -- Header Hover
        C_ACCENT_G = {0.2, 0.6, 0.2},       -- Green (Active)
        C_ACCENT_N = {0.3, 0.35, 0.3},      -- Neutral
        C_MARKER_BG = {0.3, 0.1, 0.1},      -- Dark Red Row
        C_MARKER_SEL = {0.5, 0.4, 0.0},     -- Dark Orange Selection
        C_TOOLTIP_BG = {0, 0, 0, 0.9},      -- Dark Tooltip BG
        C_TOOLTIP_TXT = {1, 1, 1, 1},       -- White Tooltip Text
        C_BTN_MEDIUM = {0.3, 0.5, 0.3, 1},
        C_BTN_UPDATE = {0.35, 0.55, 0.8, 1},
        C_BTN_ERROR = {0.8, 0.3, 0.3},
        C_TXT_ERROR = {1.0, 0.4, 0.4},          -- Bright Red (Text on Dark BG)
        C_DICT_TITLE_NORM = {0.6, 0.7, 0.9},    -- Same as C_SEL
        C_DICT_TITLE_HOVER = {0.5, 0.8, 1.0},   -- Bright Blue Hover
        C_SCROLL_BG = {0, 0, 0, 0.3},      -- Scrollbar track background
        C_SCROLL_HDL = {0.5, 0.5, 0.5, 0.8}, -- Scrollbar handle
        C_SCROLL_HDL_H = {0.7, 0.7, 0.7, 0.9}, -- Scrollbar handle (hovered)
    },
    ["Obsidian"] = {
        C_BG = {0.08, 0.08, 0.08},
        C_TXT = {0.8, 0.8, 0.8},
        C_BTN = {0.15, 0.15, 0.15},
        C_BTN_H = {0.25, 0.25, 0.25},
        C_ROW = {0.12, 0.12, 0.12},
        C_ROW_ALT = {0.14, 0.14, 0.14},
        C_SEL = {0.4, 0.5, 0.7},
        C_TAB_ACT = {0.15, 0.15, 0.15},
        C_TAB_INA = {0.1, 0.1, 0.1},
        C_SNACK_INFO = {0.05, 0.05, 0.05},  -- Deeper Header
        C_LIGHT_GREY = {0.6, 0.6, 0.6},     -- Softer Section Title
        C_MEDIUM_GREY = {0.2, 0.2, 0.2},    -- Subtle Section Line
        C_HILI_HEADER = {0.15, 0.2, 0.25},  -- Deeper Header Hover
        C_ACCENT_G = {0.15, 0.5, 0.15},     -- Deeper Green
        C_ACCENT_N = {0.2, 0.25, 0.2},      -- Deeper Neutral
        C_MARKER_BG = {0.25, 0.08, 0.08},   -- Deep Dark Red Row
        C_MARKER_SEL = {0.45, 0.35, 0.05},  -- Deep Orange Selection
        C_TOOLTIP_BG = {0, 0, 0, 0.95},     -- Black Tooltip BG
        C_TOOLTIP_TXT = {0.9, 0.9, 0.9, 1}, -- Off-White Tooltip Text
        C_BTN_MEDIUM = {0.25, 0.5, 0.25, 1},
        C_BTN_UPDATE = {0.3, 0.5, 0.75, 1},
        C_BTN_ERROR = {0.7, 0.2, 0.2},
        C_TXT_ERROR = {1.0, 0.3, 0.3},          -- Bright Red (Text on Dark BG)
        C_DICT_TITLE_NORM = {0.4, 0.5, 0.7},    -- Same as C_SEL
        C_DICT_TITLE_HOVER = {0.5, 0.8, 1.0},   -- Bright Blue Hover
        C_SCROLL_BG = {1, 1, 1, 0.05},      -- Scrollbar track background
        C_SCROLL_HDL = {0.5, 0.5, 0.5, 0.8}, -- Scrollbar handle
        C_SCROLL_HDL_H = {0.7, 0.7, 0.7, 0.9}, -- Scrollbar handle (hovered)
    },
    ["Quartz"] = {
        C_BG = {0.80, 0.80, 0.78}, -- High Contrast Grey Matte
        C_TXT = {0.05, 0.05, 0.05},
        C_BTN = {0.72, 0.72, 0.70},
        C_BTN_H = {0.65, 0.65, 0.63},
        C_ROW = {0.76, 0.76, 0.74},
        C_ROW_ALT = {0.72, 0.72, 0.70},
        C_SEL = {0.3, 0.55, 0.85},
        C_TAB_ACT = {0.72, 0.72, 0.70},
        C_TAB_INA = {0.78, 0.78, 0.76},
        C_SNACK_INFO = {0.70, 0.70, 0.68}, -- Table Header Background
        C_LIGHT_GREY = {0.2, 0.2, 0.2},     -- Section Title Text
        C_MEDIUM_GREY = {0.6, 0.6, 0.6},    -- Section Divider Line
        C_HILI_HEADER = {0.60, 0.60, 0.70},  -- Header Hover Highlight
        C_ACCENT_G = {0.70, 0.95, 0.70},    -- Pastel Green (Light)
        C_ACCENT_N = {0.55, 0.55, 0.53},    -- Neutral Grey
        C_MARKER_BG = {0.95, 0.35, 0.35},   -- Strong Red Row
        C_MARKER_SEL = {0.92, 0.65, 0.45},  -- Pastel Orange Selection (Light)
        C_TOOLTIP_BG = {0.95, 0.95, 0.93, 1}, -- Light Opaque Tooltip BG
        C_TOOLTIP_TXT = {0.1, 0.1, 0.1, 1},   -- Dark Tooltip Text
        C_BTN_MEDIUM = {0.3, 0.5, 0.3, 1},
        C_BTN_UPDATE = {0.35, 0.45, 0.75, 1},
        C_BTN_ERROR = {0.8, 0.3, 0.3},
        C_TXT_ERROR = {0.8, 0.2, 0.2},          -- Dark Red (Text on Light BG)
        C_DICT_TITLE_NORM = {0.08, 0.22, 0.50}, -- Dark Royal Blue
        C_DICT_TITLE_HOVER = {0.15, 0.30, 0.60},
        C_SCROLL_BG = {0, 0, 0, 0.1},      -- Scrollbar track background
        C_SCROLL_HDL = {0.5, 0.5, 0.5, 0.7}, -- Scrollbar handle
        C_SCROLL_HDL_H = {0.5, 0.5, 0.5, 1}, -- Scrollbar handle (hovered)
    },
}

function UI.apply_ui_theme(theme_name)    
    local theme = UI.UI_THEMES[theme_name] or UI.UI_THEMES["Titanium"]
    for k, v in pairs(theme) do
        UI[k] = v
    end
    cfg.ui_theme = theme_name
end

-- Apply initial theme
UI.apply_ui_theme(cfg.ui_theme)

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
    reaper.SetExtState(section_name, "last_tab", tostring(UI_STATE.current_tab), true)
    reaper.SetExtState(section_name, "dock", tostring(GL.last_dock_state), true)
    
    reaper.SetExtState(section_name, "p_fsize", tostring(cfg.p_fsize), true)
    reaper.SetExtState(section_name, "p_cr", tostring(cfg.p_cr), true)
    reaper.SetExtState(section_name, "p_cg", tostring(cfg.p_cg), true)
    reaper.SetExtState(section_name, "p_cb", tostring(cfg.p_cb), true)
    reaper.SetExtState(section_name, "p_next", cfg.p_next and "1" or "0", true)
    reaper.SetExtState(section_name, "p_align", cfg.p_align, true)
    reaper.SetExtState(section_name, "p_valign", cfg.p_valign, true)
    reaper.SetExtState(section_name, "auto_srt_split", cfg.auto_srt_split, true)
    reaper.SetExtState(section_name, "prmt_theme", cfg.prmt_theme, true)
    reaper.SetExtState(section_name, "ui_theme", cfg.ui_theme, true)
    reaper.SetExtState(section_name, "tts_voice", cfg.tts_voice, true)
    reaper.SetExtState(section_name, "search_item_path", cfg.search_item_path or "", true)

    reaper.SetExtState(section_name, "t_ar_r", tostring(cfg.t_ar_r), true)
    reaper.SetExtState(section_name, "t_ar_g", tostring(cfg.t_ar_g), true)
    reaper.SetExtState(section_name, "t_ar_b", tostring(cfg.t_ar_b), true)
    reaper.SetExtState(section_name, "t_ar_alpha", tostring(cfg.t_ar_alpha), true)
    reaper.SetExtState(section_name, "t_r_size", cfg.t_r_size, true)

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

    reaper.SetExtState(section_name, "c_cr", tostring(cfg.c_cr), true)
    reaper.SetExtState(section_name, "c_cg", tostring(cfg.c_cg), true)
    reaper.SetExtState(section_name, "c_cb", tostring(cfg.c_cb), true)
    reaper.SetExtState(section_name, "c_fsize", tostring(cfg.c_fsize), true)
    reaper.SetExtState(section_name, "p_corr", cfg.p_corr and "1" or "0", true)

    reaper.SetExtState(section_name, "wrap_length", tostring(cfg.wrap_length), true)
    reaper.SetExtState(section_name, "always_next", cfg.always_next and "1" or "0", true)
    reaper.SetExtState(section_name, "next_attach", cfg.next_attach and "1" or "0", true)
    reaper.SetExtState(section_name, "next_padding", tostring(cfg.next_padding), true)
    reaper.SetExtState(section_name, "show_next_two", cfg.show_next_two and "1" or "0", true)
    
    reaper.SetExtState(section_name, "p_lheight", tostring(cfg.p_lheight), true)
    reaper.SetExtState(section_name, "n_lheight", tostring(cfg.n_lheight), true)
    reaper.SetExtState(section_name, "c_lheight", tostring(cfg.c_lheight), true)

    reaper.SetExtState(section_name, "random_color_actors", cfg.random_color_actors and "1" or "0", true)
    reaper.SetExtState(section_name, "text_assimilations", cfg.text_assimilations and "1" or "0", true)
    reaper.SetExtState(section_name, "fix_CP1251", cfg.fix_CP1251 and "1" or "0", true)

    reaper.SetExtState(section_name, "karaoke_mode", cfg.karaoke_mode and "1" or "0", true)
    reaper.SetExtState(section_name, "auto_startup", cfg.auto_startup and "1" or "0", true)
    reaper.SetExtState(section_name, "all_caps", cfg.all_caps and "1" or "0", true)
    reaper.SetExtState(section_name, "show_actor_name_infront", cfg.show_actor_name_infront and "1" or "0", true)

    reaper.SetExtState(section_name, "wave_bg", cfg.wave_bg and "1" or "0", true)
    reaper.SetExtState(section_name, "wave_bg_progress", cfg.wave_bg_progress and "1" or "0", true)

    reaper.SetExtState(section_name, "count_timer", cfg.count_timer and "1" or "0", true)
    reaper.SetExtState(section_name, "count_timer_bottom", cfg.count_timer_bottom and "1" or "0", true)

    reaper.SetExtState(section_name, "cps_warning", cfg.cps_warning and "1" or "0", true)
    reaper.SetExtState(section_name, "prompter_slider_mode", cfg.prompter_slider_mode and "1" or "0", true)
    reaper.SetExtState(section_name, "gemini_api_key", cfg.gemini_api_key, true)
    reaper.SetExtState(section_name, "eleven_api_key", cfg.eleven_api_key, true)
    reaper.SetExtState(section_name, "p_drawer", cfg.p_drawer and "1" or "0", true)
    reaper.SetExtState(section_name, "p_drawer_left", cfg.p_drawer_left and "1" or "0", true)
    reaper.SetExtState(section_name, "prompter_drawer_width", tostring(prompter_drawer.width), true)

    reaper.SetExtState(section_name, "col_table_index", cfg.col_table_index and "1" or "0", true)
    reaper.SetExtState(section_name, "col_table_start", cfg.col_table_start and "1" or "0", true)
    reaper.SetExtState(section_name, "col_table_end", cfg.col_table_end and "1" or "0", true)
    reaper.SetExtState(section_name, "col_table_cps", cfg.col_table_cps and "1" or "0", true)
    reaper.SetExtState(section_name, "col_table_actor", cfg.col_table_actor and "1" or "0", true)
    reaper.SetExtState(section_name, "reader_mode", cfg.reader_mode and "1" or "0", true)
    reaper.SetExtState(section_name, "show_markers_in_table", cfg.show_markers_in_table and "1" or "0", true)
    reaper.SetExtState(section_name, "gui_scale", tostring(cfg.gui_scale), true)
    reaper.SetExtState(section_name, "director_mode", cfg.director_mode and "1" or "0", true)
    reaper.SetExtState(section_name, "director_layout", cfg.director_layout, true)
    reaper.SetExtState(section_name, "w_director", tostring(cfg.w_director), true)
    reaper.SetExtState(section_name, "h_director", tostring(cfg.h_director), true)

    reaper.SetExtState(section_name, "auto_trim", cfg.auto_trim and "1" or "0", true)
    reaper.SetExtState(section_name, "trim_start", tostring(cfg.trim_start), true)
    reaper.SetExtState(section_name, "trim_end", tostring(cfg.trim_end), true)
    reaper.SetExtState(section_name, "check_clipping", cfg.check_clipping and "1" or "0", true)

    update_prompter_fonts()
end

-- =============================================================================
-- SHARED OVERLAY SYNC
-- =============================================================================

--- Serialize and send Prompter data to ExtState for the satellite Overlay script

local function run_satellite_script(folder, filename, label)
    local sep = package.config:sub(1, 1)
    local script_path = debug.getinfo(1,'S').source:match([[^@?(.*[\/])]])
    local full_path = script_path .. folder .. sep .. filename
    
    -- Check if file exists
    local f_check = io.open(full_path, "r")
    if not f_check then
        reaper.MB("Файл не знайдено за шляхом:\n" .. full_path, "Помилка", 0)
        return
    end
    f_check:close()

    -- Dependency Check: ReaImGui
    local has_reapack = reaper.ReaPack_GetOwner ~= nil
    local has_imgui = reaper.ImGui_CreateContext ~= nil

    if not has_imgui then
        local msg = "Для роботи " .. label .. " необхідне розширення ReaImGui.\n\n"
        if not has_reapack then
            msg = msg .. "1. Встановіть ReaPack (reapack.com)\n2. Перезавантажте REAPER\n3. Встановіть ReaImGui через ReaPack"
        else
            msg = msg .. "Будь ласка, встановіть 'ReaImGui' через Extensions -> ReaPack -> Browse packages. (потім перезавантажте REAPER)"
        end
        reaper.MB(msg, "Відсутні компоненти", 0)
        return
    end

    -- Try to find the Command ID in reaper-kb.ini
    local kb_path = reaper.GetResourcePath() .. "/reaper-kb.ini"
    local f = io.open(kb_path, "r")
    local cmd_id = nil
    if f then
        local pattern = folder .. "[\\/]" .. filename
        for line in f:lines() do
            if line:find(pattern) then
                local rs_part = line:match("RS([%a%d]+)")
                if rs_part then
                    cmd_id = "_RS" .. rs_part
                    break
                end
            end
        end
        f:close()
    end

    -- If found, run it. If not, ask the user to register it once.
    if cmd_id and reaper.NamedCommandLookup(cmd_id) ~= 0 then
        reaper.Main_OnCommand(reaper.NamedCommandLookup(cmd_id), 0)
    else
        reaper.MB("REAPER потребує одноразової реєстрації нового вікна:\n\n1. Відкрийте Actions -> Show action list\n2. Натисніть New action -> Load script\n3. Оберіть файл " .. filename .. " з папки " .. folder .. "\n\nПісля цього вікно буде відкриватися миттєво з меню.", "Потрібна реєстрація", 0)
    end
end

-- =============================================================================
-- UTILITY FUNCTIONS
-- =============================================================================

-- Helper to open URLs safely (fallback if SWS not installed)
local UTILS = {}

-- Helper to open URLs safely (fallback if SWS not installed)
function UTILS.open_url(url)
    if reaper.CF_ShellExecute then
        reaper.CF_ShellExecute(url)
    else
        local os_name = reaper.GetOS()
        if os_name:match("Win") then
            reaper.ExecProcess('cmd.exe /C start "" "' .. url .. '"', 0)
        elseif os_name:match("OSX") or os_name:match("macOS") then
            os.execute('open "' .. url .. '"')
        else
            os.execute('xdg-open "' .. url .. '"')
        end
    end
end

-- Function to automatically restart the current script
function UTILS.restart_script()
    -- Signal other scripts to close
    reaper.SetExtState("Subass_Global", "ForceCloseComplementary", "1", false)
    
    local script_path = debug.getinfo(1, 'S').source:match("^@?(.*)")
    if gfx.quit then gfx.quit() end
    
    UI_STATE.is_restarting = true
    
    reaper.defer(function()
        dofile(script_path)
    end)
end

--- Launch external python script
function UTILS.launch_python_script(script_relative_path)
    local script_path = debug.getinfo(1,'S').source:match([[^@?(.*[\/])]])
    local py_script = script_path .. script_relative_path
    local os_name = reaper.GetOS()
    
    if os_name:match("Win") then
        local py_exe = OTHER.rec_state.python.executable or "python"
        py_script = py_script:gsub("/", "\\")
        reaper.ExecProcess('cmd.exe /C start "" "' .. py_exe .. '" "' .. py_script .. '"', -1)
    elseif os_name:match("OSX") or os_name:match("macOS") then
        local cmd = string.format('/usr/bin/open -n -a Terminal.app "%s"', py_script)
        reaper.ExecProcess(cmd, -1)
    else
        local py_script = script_path .. script_relative_path
        reaper.ExecProcess('python3 "' .. py_script .. '" &', -1)
    end
end

--- Set GFX color from RGB array
--- @param c table RGB color array {r, g, b, [a]}
--- @param a_override number? Optional alpha override
local function set_color(c, a_override)
    if not c or type(c) ~= "table" then return end
    gfx.r, gfx.g, gfx.b = c[1], c[2], c[3]
    gfx.a = a_override or c[4] or 1.0
end

--- Compare subtitle text robustly
--- @param s1 string
--- @param s2 string
--- @return boolean
function UTILS.compare_sub_text(s1, s2)
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
--- @param UI_STATE.scroll_y number Current scroll position
--- @return number New scroll position (updated if dragged)
local function draw_scrollbar(x, y, w, h, total_h, visible_h, scroll_y)
    if total_h <= visible_h then return 0 end
    
    -- Background
    set_color(UI.C_SCROLL_BG)
    gfx.rect(x, y, w, h, 1)
    
    local ratio = visible_h / total_h
    local handle_h = math.max(20, h * ratio)
    local max_scroll = total_h - visible_h
    
    -- Clamp local scroll_y (input might be raw)
    local local_scroll = scroll_y
    if local_scroll < 0 then local_scroll = 0 end
    if local_scroll > max_scroll then local_scroll = max_scroll end
    
    local handle_y = y + (local_scroll / max_scroll) * (h - handle_h)
    
    -- Draw Handle
    local is_hover = UI_STATE.window_focused and (gfx.mouse_x >= x and gfx.mouse_x <= x + w and gfx.mouse_y >= handle_y and gfx.mouse_y <= handle_y + handle_h)
    if is_hover then
        set_color(UI.C_SCROLL_HDL_H)
    else
        set_color(UI.C_SCROLL_HDL)
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
    
    return local_scroll
end

--- Get color for CPS (Characters Per Second) with smooth gradient for high speeds
--- @param cps number
--- @return table RGB color array
function UTILS.get_cps_color(cps)
    if cps < 6 then
        -- Interpolate from Blue to Normal (Text)
        -- t=0 -> Blue, t=1 -> Text
        local t = cps / 6.0
        local c1 = UI.C_DICT_TITLE_HOVER -- Blue (Themed)
        local c2 = UI.C_TXT
        return {
            c1[1] + (c2[1] - c1[1]) * t,
            c1[2] + (c2[2] - c1[2]) * t,
            c1[3] + (c2[3] - c1[3]) * t,
            1
        }
    elseif cps < 14 then
        return UI.C_TXT -- Always visible (Theme Aware)
    elseif cps <= 20 then
        -- Interpolate from Normal (Text) to Error (Red)
        local t = (cps - 14) / 6.0
        local c1 = UI.C_TXT
        local c2 = UI.C_TXT_ERROR
        return {
            c1[1] + (c2[1] - c1[1]) * t,
            c1[2] + (c2[2] - c1[2]) * t,
            c1[3] + (c2[3] - c1[3]) * t,
            1
        }
    else
        return UI.C_TXT_ERROR -- Max Warning (Theme Aware)
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
function UTILS.url_encode(str)
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
function UTILS.url_decode(str)
    if not str then return "" end
    return str:gsub("+", " "):gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
end

--- Check if string is valid UTF-8
--- @param str string Input string
--- @return boolean True if valid UTF-8
local function is_valid_utf8(str)
    local i, len = 1, #str
    while i <= len do
        local b = str:byte(i)
        if b < 0x80 then
            i = i + 1
        elseif b >= 0xC2 and b <= 0xDF then
            if i + 1 > len or str:byte(i+1) < 0x80 or str:byte(i+1) > 0xBF then return false end
            i = i + 2
        elseif b >= 0xE0 and b <= 0xEF then
            if i + 2 > len then return false end
            local b2, b3 = str:byte(i+1), str:byte(i+2)
            if b2 < 0x80 or b2 > 0xBF or b3 < 0x80 or b3 > 0xBF then return false end
            if b == 0xE0 and b2 < 0xA0 then return false end
            if b == 0xED and b2 > 0x9F then return false end
            i = i + 3
        elseif b >= 0xF0 and b <= 0xF4 then
            if i + 3 > len then return false end
            local b2, b3, b4 = str:byte(i+1), str:byte(i+2), str:byte(i+3)
            if b2 < 0x80 or b2 > 0xBF or b3 < 0x80 or b3 > 0xBF or b4 < 0x80 or b4 > 0xBF then return false end
            if b == 0xF0 and b2 < 0x90 then return false end
            if b == 0xF4 and b2 > 0x8F then return false end
            i = i + 4
        else
            return false
        end
    end
    return true
end

--- Fit text to width by truncating with ellipsis
--- @param str string Text to fit
--- @param max_w number Maximum width in pixels
--- @return string Fitted text
local function fit_text_width(str, max_w)
    str = tostring(str or "")
    
    local is_valid = is_valid_utf8(str)
    if is_valid then
        if gfx.measurestr(str) <= max_w then return str end
    end
    
    local dots = "..."
    local dots_w = gfx.measurestr(dots)
    
    if dots_w > max_w then return dots end -- Not enough space even for dots
    
    local acc = ""
    if is_valid then
        -- Safe to use utf8.codes
        for p, c in utf8.codes(str) do
            local char = utf8.char(c)
            if gfx.measurestr(acc .. char .. dots) > max_w then
                return acc .. dots
            end
            acc = acc .. char
        end
    else
        -- Fallback for invalid UTF-16/UTF-8: byte-by-byte
        for i = 1, #str do
            local char = str:sub(i, i)
            if gfx.measurestr(acc .. char .. dots) > max_w then
                return acc .. dots
            end
            acc = acc .. char
        end
    end
    
    return acc .. dots
end

--- Convert legacy CP1251 content to UTF-8 if not already UTF-8
--- @param str string Input string
--- @return string Fixed string
local function fix_encoding(str)
    if not str or str == "" then return "" end
    
    -- Always check if it's already valid UTF-8 first
    if is_valid_utf8(str) then return str end
    
    -- Not valid UTF-8. We MUST sanitize it to prevent crashes in the UI (utf8.codes etc.)
    -- if cfg.fix_CP1251 is true, we convert CP1251 -> UTF-8
    -- otherwise, we replace invalid bytes with '?'

    local cp1251_map = {
        [128] = "\208\130", [129] = "\208\131", [130] = "\226\128\154", [131] = "\209\147", [132] = "\226\128\158", [133] = "\226\128\166", [134] = "\226\128\160", [135] = "\226\128\161",
        [136] = "\226\130\172", [137] = "\226\128\176", [138] = "\208\137", [139] = "\226\128\185", [140] = "\208\138", [141] = "\208\140", [142] = "\208\139", [143] = "\208\141",
        [144] = "\208\146", [145] = "\226\128\152", [146] = "\226\128\153", [147] = "\226\128\156", [148] = "\226\128\157", [149] = "\226\128\162", [150] = "\226\128\147", [151] = "\226\128\148",
        [152] = "\194\152", [153] = "\226\132\162", [154] = "\209\153", [155] = "\226\128\186", [156] = "\209\154", [157] = "\209\156", [158] = "\209\155", [159] = "\209\157",
        [160] = "\194\160", [161] = "\208\142", [162] = "\209\158", [163] = "\208\147", [164] = "\194\164", [165] = "\210\144", [166] = "\194\166", [167] = "\194\167",
        [168] = "\208\129", [169] = "\194\169", [170] = "\208\132", [171] = "\194\171", [172] = "\194\172", [173] = "\194\173", [174] = "\194\174", [175] = "\208\135",
        [176] = "\194\176", [177] = "\194\177", [178] = "\208\134", [179] = "\209\150", [180] = "\210\145", [181] = "\194\181", [182] = "\194\182", [183] = "\194\183",
        [184] = "\209\145", [185] = "\226\132\150", [186] = "\209\148", [187] = "\194\187", [188] = "\209\152", [189] = "\208\133", [190] = "\209\149", [191] = "\209\151",
        [192] = "\208\144", [193] = "\208\145", [194] = "\208\146", [195] = "\208\147", [196] = "\208\148", [197] = "\208\149", [198] = "\208\150", [199] = "\208\151",
        [200] = "\208\152", [201] = "\208\153", [202] = "\208\154", [203] = "\208\155", [204] = "\208\156", [205] = "\208\157", [206] = "\208\158", [207] = "\208\159",
        [208] = "\208\160", [209] = "\208\161", [210] = "\208\162", [211] = "\208\163", [212] = "\208\164", [213] = "\208\165", [214] = "\208\166", [215] = "\208\167",
        [216] = "\208\168", [217] = "\208\169", [218] = "\208\170", [219] = "\208\171", [220] = "\208\172", [221] = "\208\173", [222] = "\208\174", [223] = "\208\175",
        [224] = "\208\176", [225] = "\208\177", [226] = "\208\178", [227] = "\208\179", [228] = "\208\180", [229] = "\208\181", [230] = "\208\182", [231] = "\208\183",
        [232] = "\208\184", [233] = "\208\185", [234] = "\208\186", [235] = "\208\187", [236] = "\208\188", [237] = "\208\189", [238] = "\208\190", [239] = "\208\191",
        [240] = "\209\128", [241] = "\209\129", [242] = "\209\130", [243] = "\209\131", [244] = "\209\132", [245] = "\209\133", [246] = "\209\134", [247] = "\209\135",
        [248] = "\209\136", [249] = "\209\137", [250] = "\209\138", [251] = "\209\139", [252] = "\209\140", [253] = "\209\141", [254] = "\209\142", [255] = "\209\143"
    }
    
    local res = {}
    for i = 1, #str do
        local b = str:byte(i)
        if b < 128 then
            table.insert(res, string.char(b))
        else
            if cfg.fix_CP1251 then
                table.insert(res, cp1251_map[b] or "?")
            else
                -- Sanitization: replace non-UTF8 bytes with '?' if conversion is disabled
                table.insert(res, "?")
            end
        end
    end
    return table.concat(res)
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
--- @param is_silent boolean? If true, don't show "Loading..." loader
--- @param loading_text string? Optional custom loading text
--- @param is_visible boolean? If true, show system terminal
local function run_async_command(shell_cmd, callback, is_silent, loading_text, is_visible)
    local id = tostring(os.time()) .. "_" .. math.random(1000,9999)
    local path = reaper.GetResourcePath() .. "/Scripts/"
    local out_file = path .. "async_out_" .. id .. ".tmp"
    local done_file = path .. "async_done_" .. id .. ".marker"
    
    if reaper.GetOS():match("Win") then
        out_file = out_file:gsub("/", "\\")
        done_file = done_file:gsub("/", "\\")
        local bat_file = (path .. "async_exec_" .. id .. ".bat"):gsub("/", "\\")

        local f_bat = io.open(bat_file, "w")
        if not f_bat then return end

        f_bat:write("@echo off\r\n")
        f_bat:write("chcp 65001 > NUL\r\n")
        f_bat:write("set PYTHONUTF8=1\r\n")

        local bat_cmd = shell_cmd:gsub("%%", "%%%%")

        if is_visible then
            -- For visible terminal, we use 'tee' equivalent or just redirect for file but user won't see...
            -- Actually, let's just run and then echo to file.
            f_bat:write("echo [AI] Початок аналізу... \r\n")
            f_bat:write(bat_cmd .. ' > "' .. out_file .. '" 2>&1\r\n')
            f_bat:write('type "' .. out_file .. '"\r\n') -- Show output once done if visible
        else
            if bat_cmd:find(">") then
                f_bat:write(bat_cmd .. "\r\n")
            else
                f_bat:write(bat_cmd .. ' > "' .. out_file .. '" 2>&1\r\n')
            end
        end

        f_bat:write('echo DONE > "' .. done_file .. '"\r\n')
        
        if is_visible then
            f_bat:write("echo [AI] Аналіз завершено. Це вікно можна закрити.\r\n")
            f_bat:write("pause\r\n")
        end

        f_bat:write('set _self=%~f0\r\n')
        f_bat:write('cmd /c ping 127.0.0.1 -n 2 > NUL & del "%_self%"\r\n')

        f_bat:close()

        local win_style = is_visible and "" or "-WindowStyle Hidden"
        local ps_cmd =
            'powershell -NoProfile -ExecutionPolicy Bypass ' ..
            win_style ..' -Command "Start-Process ' ..
            '\\\"' .. bat_file .. '\\\" ' .. win_style .. '"'

        reaper.ExecProcess(ps_cmd, 0)
    else
        -- Unix/Mac background execution
        if is_visible then
            -- On Mac, we create a temporary .sh script and open it with Terminal.app.
            -- This is more robust than osascript for complex commands with quotes.
            local sh_file = path .. "async_exec_" .. id .. ".sh"
            local f_sh = io.open(sh_file, "w")
            if f_sh then
                f_sh:write("#!/bin/bash\n")
                f_sh:write('echo "[AI] Whisper Аналіз..." \n')
                -- Capture both stdout and stderr while showing it to the user
                f_sh:write(shell_cmd .. ' 2>&1 | tee "' .. out_file .. '"\n')
                f_sh:write('echo DONE > "' .. done_file .. '"\n')
                f_sh:write('echo ""\n')
                f_sh:write('echo "[AI] Аналіз завершено. Це вікно можна закрити."\n')
                f_sh:write('read -p "Натисніть Enter для виходу..."\n')
                f_sh:write('rm "$0"\n') -- Self-delete script after execution
                f_sh:close()
                
                os.execute('chmod +x "' .. sh_file .. '"')
                os.execute('open -a Terminal "' .. sh_file .. '"')
            end
        else
            local full_cmd
            if shell_cmd:find(" > ") then
                full_cmd = '( ' .. shell_cmd .. ' ; touch "' .. done_file .. '" ) &'
            else
                full_cmd = '( ' .. shell_cmd .. ' > "' .. out_file .. '" 2>&1 ; touch "' .. done_file .. '" ) &'
            end
            os.execute(full_cmd)
        end
    end
    
    table.insert(global_async_pool, {
        id = id,
        out_file = out_file,
        done_file = done_file,
        callback = callback
    })
    
    if not is_silent then
        UI_STATE.script_loading_state.active = true
        UI_STATE.script_loading_state.text = loading_text or "Завантаження даних..."
    end
end

local sws_alert_shown = false

--- Set system clipboard text
--- @param text string Text to copy to clipboard
local function set_clipboard(text)
    if not text then return end
    text = text:match("^%s*(.-)%s*$")
    if text == "" then return end
    
    if reaper.CF_SetClipboard then 
        reaper.CF_SetClipboard(text)
        return
    end
    
    if not sws_alert_shown then
        reaper.MB("Для кращої роботи буфера обміну рекомендується встановити SWS Extension.", "Subass", 0)
        sws_alert_shown = true
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
                -- DEBUG: Print output start
                -- reaper.ShowConsoleMsg("Async Output (" .. task.id .. "): " .. output:sub(1, 500) .. "\n")
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
                UI_STATE.script_loading_state.active = false
            end
        end
    end
end

--- Draw a global loading overlay with spinner when async tasks are active
local function draw_loader()
    if not UI_STATE.script_loading_state.active then return end
    
    -- Overlay
    gfx.set(0, 0, 0, 0.7)
    gfx.rect(0, 0, gfx.w, gfx.h, 1)
    
    -- Loading Text
    gfx.setfont(F.bld)
    set_color(UI.C_TXT)
    
    local str = UI_STATE.script_loading_state.text or "Завантаження..."
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
local function is_mouse_clicked(btn)
    local cap = btn or 1
    -- Check specific bit for the requested button (1=L, 2=R)
    -- Cap 1 is bit 0, Cap 2 is bit 1. 
    -- But gfx.mouse_cap usually returns 1 for Left, 2 for Right.
    -- Strict check: 
    return (gfx.mouse_cap & cap == cap) and (UI_STATE.last_mouse_cap & cap == 0)
end

--- Check if mouse right button was just clicked
--- @return boolean True if clicked this frame
local function is_right_mouse_clicked()
    return gfx.mouse_cap == 2 and UI_STATE.last_mouse_cap == 0
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

--- Check if any UI text input (filter, find/replace) is currently focused
--- @return boolean
local function is_any_text_input_focused()
    if text_editor_state.active then return true end
    if table_filter_state and table_filter_state.focus then return true end
    if prompter_drawer and prompter_drawer.filter and prompter_drawer.filter.focus then return true end
    if director_state and director_state.input and director_state.input.focus then return true end
    if find_replace_state and find_replace_state.show then
        if find_replace_state.find and find_replace_state.find.focus then return true end
        if find_replace_state.replace and find_replace_state.replace.focus then return true end
    end
    return false
end

local function return_focus_to_reaper(force)
    -- Safeguards: don't steal focus if user is actively typing or manipulating UI
    if not force then
        if is_any_text_input_focused() then return end
        if gfx.mouse_cap ~= 0 then return end -- Don't return focus if mouse is held
    end

    -- Aggressive focus payload
    local function exec_focus()
        reaper.SetCursorContext(1, 0) -- Focus Arrange context
        reaper.UpdateArrange() -- Nudge UI
    end
    
    exec_focus()
    reaper.defer(exec_focus) -- Deferred pass to ensure it sticks on macOS
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
local function btn(x, y, w, h, text, bg_col, txt_col)
    local hover = UI_STATE.window_focused and (gfx.mouse_x >= x and gfx.mouse_x <= x+w and gfx.mouse_y >= y and gfx.mouse_y <= y+h)
    set_color(hover and UI.C_BTN_H or (bg_col or UI.C_BTN))
    gfx.rect(x, y, w, h, 1)
    set_color(txt_col or UI.C_TXT)
    gfx.setfont(F.std)
    local margin = S(4)
    local draw_txt = fit_text_width(text, w - margin * 2)
    
    -- Center text roughly
    local str_w, str_h = gfx.measurestr(draw_txt)
    gfx.x = x + (w - str_w) / 2
    gfx.y = y + (h - str_h) / 2
    gfx.drawstr(draw_txt)
    if hover and is_mouse_clicked() then return true end
    return false
end

-- =============================================================================
-- SNACKBAR NOTIFICATIONS
-- =============================================================================

--- Show temporary notification message
--- @param text string Message to display
--- @param type string? Notification type: "success", "error", "info" (default)
--- @param delay number? Optional duration in seconds
local function show_snackbar(text, type, delay)
    UI_STATE.snackbar_state.duration = delay or 3.0
    UI_STATE.snackbar_state.text = text
    UI_STATE.snackbar_state.type = type or "info"
    UI_STATE.snackbar_state.show_time = reaper.time_precise()
end

--- Draw tooltip at mouse position
local function draw_tooltip()
    if not UI_STATE.tooltip_state.text or UI_STATE.tooltip_state.text == "" then return end
    
    local now = reaper.time_precise()
    if not UI_STATE.tooltip_state.immediate and (now - UI_STATE.tooltip_state.start_time < 1.0) then return end
    
    gfx.setfont(F.tip)
    
    local max_allowed_w = math.min(400, gfx.w - 40)
    local padding = 8
    local line_spacing = 2
    local char_h = gfx.texth
    local line_h = char_h + line_spacing
    
    -- 1. Word Wrap the text
    local wrapped_lines = {}
    local current_max_w = 0
    
    for paragraph in UI_STATE.tooltip_state.text:gmatch("[^\r\n]+") do
        local words = {}
        for w in paragraph:gmatch("%S+") do table.insert(words, w) end
        
        local current_line = ""
        for i, word in ipairs(words) do
            local test_line = (current_line == "") and word or (current_line .. " " .. word)
            local tw, th = gfx.measurestr(test_line)
            
            if tw > max_allowed_w and current_line ~= "" then
                table.insert(wrapped_lines, current_line)
                local lw = gfx.measurestr(current_line)
                if lw > current_max_w then current_max_w = lw end
                current_line = word
            else
                current_line = test_line
            end
        end
        if current_line ~= "" then
            table.insert(wrapped_lines, current_line)
            local lw = gfx.measurestr(current_line)
            if lw > current_max_w then current_max_w = lw end
        end
    end
    
    if #wrapped_lines == 0 then return end
    
    local total_h = #wrapped_lines * line_h - line_spacing
    local box_w = current_max_w + padding * 2
    local box_h = total_h + padding * 2
    
    -- 2. Position with Screen Clamping
    local tx = gfx.mouse_x + 15
    local ty = gfx.mouse_y + 15
    
    -- Horizontal check
    if tx + box_w > gfx.w - 10 then
        tx = gfx.mouse_x - box_w - 10
    end
    if tx < 10 then tx = 10 end
    
    -- Vertical check
    if ty + box_h > gfx.h - 10 then
        ty = gfx.mouse_y - box_h - 10
    end
    if ty < 10 then ty = 10 end
    
    -- 3. Draw
    -- Shadow (subtle)
    set_color(UI.C_SCROLL_BG)
    gfx.rect(tx + 2, ty + 2, box_w, box_h, 1)
    
    -- Background
    set_color(UI.C_TOOLTIP_BG)
    gfx.rect(tx, ty, box_w, box_h, 1)
    
    -- Border
    set_color(UI.C_FR_BORDER)
    gfx.rect(tx, ty, box_w, box_h, 0)
    
    -- Text
    set_color(UI.C_TOOLTIP_TXT)
    for i, line in ipairs(wrapped_lines) do
        gfx.x = tx + padding
        gfx.y = ty + padding + (i-1) * line_h
        gfx.drawstr(line)
    end
end

--- Draw snackbar notification with fade-out animation
local function draw_snackbar()
    if UI_STATE.snackbar_state.text == "" then return end
    
    local current_time = reaper.time_precise()
    local elapsed = current_time - UI_STATE.snackbar_state.show_time
    
    if elapsed > UI_STATE.snackbar_state.duration then
        UI_STATE.snackbar_state.text = "" -- Hide snackbar
        return
    end
    
    -- Calculate fade-out alpha
    local alpha = 1.0
    if elapsed > UI_STATE.snackbar_state.duration - 0.2 then
        -- Fade out in last 0.2 seconds
        alpha = (UI_STATE.snackbar_state.duration - elapsed) / 0.2
    end
    
    -- Measure text
    gfx.setfont(F.std)
    local text_w, text_h = gfx.measurestr(UI_STATE.snackbar_state.text)
    
    -- Snackbar dimensions
    local padding = 15
    local snack_w = text_w + padding * 2
    local snack_h = text_h + padding
    local snack_x = (gfx.w - snack_w) / 2
    local snack_y = gfx.h - snack_h - 10
    
    -- Use shorter names for convenience
    local sx, sy, sw, sh = snack_x, snack_y, snack_w, snack_h
    local type = UI_STATE.snackbar_state.type
    
    -- Shadow
    set_color(UI.C_SNACK_SHADOW, alpha * 0.3)
    gfx.rect(sx + 2, sy + 2, sw, sh, 1)
    
    -- Background
    set_color(UI.C_SNACK_INFO, alpha * 0.95)
    if type == "success" then 
        set_color(UI.C_SNACK_SUCCESS, alpha * 0.95)
    elseif type == "error" then 
        set_color(UI.C_SNACK_ERROR, alpha * 0.95)
    elseif type == "warning" then
        set_color(UI.C_SNACK_WARN, alpha * 0.95)
    end
    gfx.rect(sx, sy, sw, sh, 1)
    
    -- Border
    set_color(UI.C_SNACK_BORDER, alpha)
    gfx.rect(sx, sy, sw, sh, 0)
    
    -- Text
    set_color(UI.C_SNACK_TXT, alpha)
    gfx.x = snack_x + padding
    gfx.y = snack_y + padding / 2
    gfx.drawstr(UI_STATE.snackbar_state.text)
end

-- ═══════════════════════════════════════════════════════════════
-- DEADLINE MODULE - Methods
-- ═══════════════════════════════════════════════════════════════

--- Get project-wide deadline
--- @return number|nil Project deadline as Unix timestamp
function DEADLINE.get()
    local retval, val = reaper.GetProjExtState(0, "Subass_Notes", "project_deadline")
    if retval and val ~= "" then
        return tonumber(val)
    end
    return nil
end

--- Set project-wide deadline
--- @param timestamp number|nil Unix timestamp or nil to clear
function DEADLINE.set(timestamp)
    reaper.SetProjExtState(0, "Subass_Notes", "project_deadline", timestamp and tostring(timestamp) or "")
    DEADLINE.project_deadline = timestamp
    
    -- Update global storage
    local proj_path, proj_name = DEADLINE.get_project_info()
    if proj_path then
        DEADLINE.save_global(proj_path, proj_name, timestamp)
    end
end

--- Get current project path and name
--- @return string|nil, string|nil Project path and name, or nil if unsaved
function DEADLINE.get_project_info()
    local proj, full_path = reaper.EnumProjects(-1)
    if not full_path or full_path == "" then
        -- Return project pointer as a stable ID for unsaved tabs
        local ptr_id = "PTR:" .. tostring(proj)
        return ptr_id, "Без назви (unsaved)"
    end
    
    local proj_name = reaper.GetProjectName(0)
    if not proj_name or proj_name == "" then
        proj_name = "Untitled"
    end
    
    return full_path, proj_name
end

--- Normalize path for comparison (lower case, separators)
--- @param path string
--- @return string
function DEADLINE.normalize_path(path)
    if not path then return "" end
    path = path:lower()
    path = path:gsub("\\", "/")
    path = path:gsub("^%s*(.-)%s*$", "%1") -- trim
    return path
end

--- Smartly open a project: switch if open, else new tab.
--- Handles missing files by asking user to locate them.
--- @param proj_data table {path, name, deadline}
function DEADLINE.open_project_smart(proj_data)
    if not proj_data or not proj_data.path then return end
    local target_path = proj_data.path
    
    -- PASS 0: Project Pointer Match (for unsaved projects)
    if target_path:match("^PTR:") then
        local target_ptr = target_path:gsub("^PTR:", "")
        local i = 0
        while true do
            local proj = reaper.EnumProjects(i, "")
            if not proj then break end
            if tostring(proj) == target_ptr then
                reaper.SelectProjectInstance(proj)
                return
            end
            i = i + 1
        end
        -- If we are here, the unsaved project tab was closed
        reaper.MB("Тимчасовий проєкт більше не відкритий.", "Помилка", 0)
        return
    end

    -- Normalize target path for comparison
    local norm_target = DEADLINE.normalize_path(target_path)
    local target_filename = norm_target:match("([^/]+)$")
    
    -- PASS 1: Exact Path Match
    local i = 0
    while true do
        local proj = reaper.EnumProjects(i, "")
        if not proj then break end
        
        local _, path = reaper.EnumProjects(i, "")
        if path and path ~= "" then
            local norm_path = DEADLINE.normalize_path(path)
            if norm_path == norm_target then
                reaper.SelectProjectInstance(proj)
                return
            end
        end
        i = i + 1
    end

    -- PASS 2: Filename Match (Fallback)
    if target_filename then
        i = 0
        while true do
            local proj = reaper.EnumProjects(i, "")
            if not proj then break end
            
            local _, path = reaper.EnumProjects(i, "")
            if path and path ~= "" then
                local norm_path = DEADLINE.normalize_path(path)
                local filename = norm_path:match("([^/]+)$")
                
                if filename == target_filename then
                    reaper.SelectProjectInstance(proj)
                    return
                end
            end
            i = i + 1
        end
    end
    
    -- PASS 3: Open New Tab (or Recover)
    if reaper.file_exists(target_path) then
        reaper.Main_OnCommand(40859, 0) -- New project tab
        reaper.Main_openProject(target_path)
    else
        -- Smart Recovery: File not found
        local result = reaper.MB("Файл проєкту не знайдено:\n" .. target_path .. "\n\nЗнайти файл вручну?", "Помилка відкриття", 4) -- 4 = Yes/No
        if result == 6 then -- 6 = Yes
            local retval, new_path = reaper.GetUserFileNameForRead(target_path, "Знайти проєкт " .. (proj_data.name or ""), "rpp")
            if retval and new_path then
                -- Open found file
                reaper.Main_OnCommand(40859, 0)
                reaper.Main_openProject(new_path)
                
                -- Update Database
                DEADLINE.save_global(target_path, proj_data.name, nil) -- Delete old
                DEADLINE.save_global(new_path, proj_data.name, proj_data.deadline) -- Save new
                show_snackbar("Шлях оновлено та збережено!", "success")
            end
        end
    end
end

--- Save deadline to global storage
--- @param project_path string Full path to project file
--- @param project_name string Project name
--- @param deadline_ts number|nil Unix timestamp or nil to remove
function DEADLINE.save_global(project_path, project_name, deadline_ts)
    local data = DEADLINE.load_global()
    
    if deadline_ts then
        -- Add or update deadline
        data[project_path] = {
            name = project_name,
            deadline = deadline_ts
        }
    else
        -- Remove deadline
        data[project_path] = nil
    end
    
    -- Save as JSON
    local json_str = STATS.json_encode(data)
    reaper.SetExtState("Subass_Global", "project_deadlines", json_str, true)
    
    -- Invalidate urgency cache for immediate update
    DEADLINE.urgency_cache.last_check = 0
end

--- Load all project deadlines from global storage
--- @return table Map of project_path -> {name, deadline}
function DEADLINE.load_global()
    local json_str = reaper.GetExtState("Subass_Global", "project_deadlines")
    if not json_str or json_str == "" then
        return {}
    end
    
    -- Simple JSON decode (assumes valid format)
    local data = {}
    local success, result = pcall(function()
        return STATS.json_decode(json_str)
    end)
    
    if success and type(result) == "table" then
        return result
    end
    
    return {}
end

--- Get overall urgency color for dashboard button
--- @return number color constant
DEADLINE.urgency_cache = {
    color = nil,
    last_check = 0
}

function DEADLINE.get_overall_urgency()
    local now = reaper.time_precise()
    
    -- Return cached value if less than 10 second passed
    if DEADLINE.urgency_cache.color and (now - DEADLINE.urgency_cache.last_check < 10.0) then
        return DEADLINE.urgency_cache.color
    end

    local data = DEADLINE.load_global()
    local highest_urgency = 0 -- 0: none, 1: orange, 2: red
    local ts_now = os.time()
    
    for _, proj in pairs(data) do
        if proj.deadline then
            local days = math.ceil((proj.deadline - ts_now) / 86400)
            if days <= 0 then
                highest_urgency = 2
            elseif days == 1 and highest_urgency < 1 then
                highest_urgency = 1
            end
        end
    end
    
    local final_col = UI.C_TAB_INA
    if highest_urgency == 2 then final_col = UI.C_RED end
    if highest_urgency == 1 then final_col = UI.C_ORANGE end
    
    DEADLINE.urgency_cache.color = final_col
    DEADLINE.urgency_cache.last_check = now
    
    return final_col
end

--- Sync local project deadline with global storage on load
function DEADLINE.sync_project()
    local proj_path, proj_name = DEADLINE.get_project_info()
    if not proj_path then return end
    
    local global_data = DEADLINE.load_global()
    local changed = false
    
    -- MIGRATION: Check if we have an entry for this project as "unsaved" (via pointer)
    local proj_ptr, _ = reaper.EnumProjects(-1)
    local ptr_id = "PTR:" .. tostring(proj_ptr)
    local ptr_entry = global_data[ptr_id]
    
    if ptr_entry and not proj_path:match("^PTR:") then
        -- Move deadline from temporary pointer ID to the real project path
        global_data[proj_path] = {
            name = proj_name or "Untitled",
            deadline = ptr_entry.deadline
        }
        global_data[ptr_id] = nil
        changed = true
    end

    local global_entry = global_data[proj_path]
    if global_entry then
        -- Sync local with global if different
        if DEADLINE.project_deadline ~= global_entry.deadline then
            reaper.SetProjExtState(0, "Subass_Notes", "project_deadline", tostring(global_entry.deadline))
            DEADLINE.project_deadline = global_entry.deadline
        end
    else
        -- If no global entry but we have a local one, maybe clear it or update cache
        if DEADLINE.project_deadline ~= nil then
            local local_dl = DEADLINE.get()
            if not local_dl then
                DEADLINE.project_deadline = nil
            end
        end
    end
    
    if changed then
        -- Save the migrated data
        local json_str = STATS.json_encode(global_data)
        reaper.SetExtState("Subass_Global", "project_deadlines", json_str, true)
    end
end
-- Run sync on script start
DEADLINE.sync_project()

--- Sort projects by urgency: Passed -> Today -> Soon -> Later
local function sort_deadlines(a, b)
    local now = os.time()
    
    -- Helper to get days remaining
    local function get_days(ts)
        return math.ceil((ts - now) / 86400)
    end
    
    local days_a = get_days(a.deadline)
    local days_b = get_days(b.deadline)
    
    -- Priority 1: Passed deadlines (negative days)
    if days_a < 0 and days_b >= 0 then return true end
    if days_b < 0 and days_a >= 0 then return false end
    
    -- Priority 2: Today (0 days)
    if days_a == 0 and days_b ~= 0 then return true end
    if days_b == 0 and days_a ~= 0 then return false end
    
    -- Priority 3: Ascending order (sooner first)
    return a.deadline < b.deadline
end

--- Draw Deadline Dashboard
function DEADLINE.draw_dashboard(input_queue)
    local pad = S(20)
    
    -- Background overlay
    set_color(UI.C_BG, 0.98)
    gfx.rect(0, 0, gfx.w, gfx.h, 1)
    
    -- Header measuring (for list_y)
    gfx.setfont(F.title)
    local title = "Мої Дедлайни"
    local tw, th = gfx.measurestr(title)
    local is_narrow = gfx.w < S(450)
    local list_y = pad + th + S(12)

    -- Load and Sort Data
    local all_deadlines = DEADLINE.load_global()
    local sorted_projects = {}
    for path, data in pairs(all_deadlines) do
        if data.deadline then
            table.insert(sorted_projects, {
                path = path,
                name = data.name,
                deadline = data.deadline
            })
        end
    end
    table.sort(sorted_projects, sort_deadlines)
    
    -- Scroll Configuration
    local row_h = is_narrow and S(100) or S(60)
    local avail_h = gfx.h - list_y - pad
    local content_h = #sorted_projects * row_h
    local max_scroll = math.max(0, content_h - avail_h)
    
    -- Mouse Wheel Handling
    if gfx.mouse_wheel ~= 0 then
        UI_STATE.dash_target_scroll_y = UI_STATE.dash_target_scroll_y - (gfx.mouse_wheel * 0.25)
        gfx.mouse_wheel = 0
    end
    
    -- Bound & Smooth Scroll
    UI_STATE.dash_target_scroll_y = math.max(0, math.min(UI_STATE.dash_target_scroll_y, max_scroll))
    local diff = UI_STATE.dash_target_scroll_y - UI_STATE.dash_scroll_y
    if math.abs(diff) > 0.5 then
        UI_STATE.dash_scroll_y = UI_STATE.dash_scroll_y + (diff * 0.8)
    else
        UI_STATE.dash_scroll_y = UI_STATE.dash_target_scroll_y
    end

    local function get_y(offset)
        return list_y + offset - math.floor(UI_STATE.dash_scroll_y)
    end

    -- Column Config
    local status_col_w = S(100)
    local btn_col_w = S(150)
    
    local status_x = pad + S(5)
    local btn_x = gfx.w - pad - btn_col_w
    local name_x = status_x + status_col_w + S(2)
    local name_col_w = btn_x - name_x - S(10)
    
    if is_narrow then
        btn_col_w = (gfx.w - pad * 2 - S(10)) / 2
        btn_x = pad
    end
    
    -- Empty State
    if #sorted_projects == 0 then
        set_color(UI.C_TXT, 0.5)
        gfx.setfont(F.std)
        local msg = "Немає активних дедлайнів"
        local mw, mh = gfx.measurestr(msg)
        gfx.x, gfx.y = (gfx.w - mw)/2, list_y + S(50)
        gfx.drawstr(msg)
    else
        -- Draw List
        for i, proj in ipairs(sorted_projects) do
            local y_offset = (i-1) * row_h
            local row_y = get_y(y_offset)
            
            -- Only draw if visible
            if row_y + row_h > list_y and row_y < gfx.h then
                -- Separator line
                set_color(UI.C_TAB_INA, 0.2)
                gfx.line(pad, row_y + row_h - 1, gfx.w - pad, row_y + row_h - 1)
                
                -- Calculations
                local days = math.ceil((proj.deadline - os.time()) / 86400)
                local date_txt = os.date("%d.%m.%Y", proj.deadline)
                local status_txt, status_col = "", UI.C_TXT
                
                if days < 0 then
                    status_txt, status_col = "ПРОЙШОВ!", UI.C_SNACK_ERROR
                elseif days == 0 then
                    status_txt, status_col = "СЬОГОДНІ!", UI.C_RED
                elseif days == 1 then
                    status_txt, status_col = "Завтра", UI.C_ORANGE
                else
                    status_txt, status_col = "Активний", UI.C_SNACK_SUCCESS
                end
                
                -- --- COLUMN 1: Status & Date ---
                gfx.setfont(F.std)
                local cur_y = row_y + S(10)
                
                local br_w = status_col_w - S(15)
                if days <= 1 then
                    local sw, sh = gfx.measurestr(status_txt)
                    local dw, dh = gfx.measurestr(date_txt)
                    local bh = sh + dh + S(6)
                    
                    set_color(status_col)
                    gfx.rect(status_x - S(5), cur_y - S(2), br_w, bh, 1)
                    
                    local txt_col = UI.C_TXT
                    if days < 0 and cfg.ui_theme == "Quartz" then txt_col = UI.C_WHITE end
                    set_color(txt_col)
                    
                    gfx.x, gfx.y = status_x, cur_y
                    gfx.drawstr(status_txt)
                    gfx.x, gfx.y = status_x, cur_y + sh + S(2)
                    gfx.drawstr(date_txt)
                else
                    set_color(status_col)
                    gfx.x, gfx.y = status_x, cur_y
                    gfx.drawstr(status_txt)
                    set_color(UI.C_TXT, 0.7)
                    gfx.x, gfx.y = status_x, cur_y + S(16)
                    gfx.drawstr(date_txt)
                end
                
                -- --- COLUMN 2: Name & Path ---
                local nx = is_narrow and (status_x + br_w + S(10)) or name_x
                local ny = cur_y
                local nw = is_narrow and (gfx.w - nx - pad) or name_col_w
                
                set_color(UI.C_TXT)
                gfx.setfont(F.bld)
                gfx.x, gfx.y = nx, ny
                local trunk_name = fit_text_width(proj.name, nw)
                gfx.drawstr(trunk_name)
                
                set_color(UI.C_TXT, 0.5)
                gfx.setfont(F.tip)
                gfx.x, gfx.y = nx, ny + S(18)
                local trunk_path = fit_text_width(proj.path, nw)
                gfx.drawstr(trunk_path)
                
                -- --- COLUMN 3: Actions ---
                local btn_w = is_narrow and btn_col_w or (btn_col_w / 2 - S(5))
                local btn_h = S(28)
                local bx = is_narrow and pad or btn_x
                local by = is_narrow and (row_y + S(55)) or (row_y + (row_h - btn_h)/2)
                
                if btn(bx, by, btn_w, btn_h, "Змінити", UI.C_BTN, UI.C_TXT) and gfx.mouse_y > list_y then
                    DEADLINE.open_picker(proj.deadline, function(new_ts)
                        DEADLINE.save_global(proj.path, proj.name, new_ts)
                        local cp_path, _ = DEADLINE.get_project_info()
                        if cp_path == proj.path then
                            DEADLINE.set(new_ts)
                        end
                    end)
                end
                
                if btn(bx + btn_w + S(10), by, btn_w, btn_h, "Відкрити", UI.C_ROW, UI.C_TXT) and gfx.mouse_y > list_y then
                    DEADLINE.open_project_smart(proj)
                end
            end
        end
        
        -- Draw Scrollbar
        if max_scroll > 0 then
            local sb_w = S(4)
            local sb_h = (avail_h / content_h) * avail_h
            local sb_y = list_y + (UI_STATE.dash_scroll_y / content_h) * avail_h
            set_color(UI.C_BTN, 0.3)
            gfx.rect(gfx.w - sb_w - S(2), sb_y, sb_w, sb_h, 1)
        end
    end

    -- --- HEADER OVERLAY (Mask scrolling rows) ---
    set_color(UI.C_BG, 1.0)
    gfx.rect(0, 0, gfx.w, list_y, 1)

    -- Close button (Top Right)
    local close_sz = S(24)
    local cx = gfx.w - pad - close_sz
    local cy = pad

    -- --- HEADER CONTENTS ---
    gfx.setfont(F.title)
    set_color(UI.C_TXT)
    gfx.x, gfx.y = pad, pad
    
    -- Truncate title if it gets too close to the close button
    local avail_tw = cx - pad - S(10)
    local draw_title = fit_text_width(title, avail_tw)
    gfx.drawstr(draw_title)
    
    local function close_dash()
        DEADLINE.dashboard_show = false
    end
    
    if btn(cx, cy, close_sz, close_sz, "X", UI.C_BTN, UI.C_TXT) then
        close_dash()
    end
    
    -- Escape key check
    if input_queue then
        for _, c in ipairs(input_queue) do
            if c == 27 then -- ESC
                close_dash()
                break
            end
        end
    end
end

--- Helper: Is leap year?
function DEADLINE.is_leap_year(y)
    return (y % 4 == 0 and y % 100 ~= 0) or (y % 400 == 0)
end

--- Helper: Get days in month
function DEADLINE.get_days_in_month(m, y)
    local days = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
    if m == 2 and DEADLINE.is_leap_year(y) then return 29 end
    return days[m] or 31
end

--- Open the date picker modal
--- @param initial_ts number|nil Initial timestamp
--- @param callback function Function to call on select(timestamp)
function DEADLINE.open_picker(initial_ts, callback)
    local now = os.date("*t")
    local t = initial_ts and os.date("*t", initial_ts) or now
    
    DEADLINE.modal.year = t.year
    DEADLINE.modal.month = t.month
    DEADLINE.modal.selected_day = t.day
    DEADLINE.modal.initial_date = initial_ts and os.date("*t", initial_ts) or nil
    DEADLINE.modal.callback = callback
    DEADLINE.modal.show = true
end

--- Draw the Date Picker Modal
function DEADLINE.draw_picker(input_queue)
    if not DEADLINE.modal.show then return end
    
    UI_STATE.mouse_handled = true -- Block interaction with background
    
    local w, h = S(DEADLINE.modal.w), S(DEADLINE.modal.h)
    local x, y = (gfx.w - w) / 2, (gfx.h - h) / 2
    
    -- Dim background
    set_color({0, 0, 0, 0.5})
    gfx.rect(0, 0, gfx.w, gfx.h, 1)
    
    -- Modal Background
    set_color(UI.C_BG)
    gfx.rect(x, y, w, h, 1)
    set_color(UI.C_MEDIUM_GREY)
    gfx.rect(x, y, w, h, 0)
    
    -- Header (Month Year)
    local month_names = {"Січень", "Лютий", "Березень", "Квітень", "Травень", "Червень", 
                         "Липень", "Серпень", "Вересень", "Жовтень", "Листопад", "Грудень"}
    local title = month_names[DEADLINE.modal.month] .. " " .. DEADLINE.modal.year
    gfx.setfont(F.dict_bld)
    set_color(UI.C_TXT)
    local tw, th = gfx.measurestr(title)
    gfx.x, gfx.y = x + (w - tw) / 2, y + S(15)
    gfx.drawstr(title)
    
    -- Month Navigation
    if btn(x + S(10), y + S(12), S(30), S(25), "<", UI.C_ROW) then
        DEADLINE.modal.month = DEADLINE.modal.month - 1
        if DEADLINE.modal.month < 1 then
            DEADLINE.modal.month = 12
            DEADLINE.modal.year = DEADLINE.modal.year - 1
        end
    end
    
    if btn(x + w - S(40), y + S(12), S(30), S(25), ">", UI.C_ROW) then
        DEADLINE.modal.month = DEADLINE.modal.month + 1
        if DEADLINE.modal.month > 12 then
            DEADLINE.modal.month = 1
            DEADLINE.modal.year = DEADLINE.modal.year + 1
        end
    end
    
    -- Weekdays Header
    local wd_names = {"Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Нд"}
    gfx.setfont(F.dict_std_sm)
    local cell_w = (w - S(20)) / 7
    for i, wd in ipairs(wd_names) do
        set_color(i > 5 and UI.C_RED or UI.C_MEDIUM_GREY)
        local wdw = gfx.measurestr(wd)
        gfx.x = x + S(10) + (i - 1) * cell_w + (cell_w - wdw) / 2
        gfx.y = y + S(50)
        gfx.drawstr(wd)
    end
    
    -- Calendar Grid
    local first_day_t = os.time({year=DEADLINE.modal.year, month=DEADLINE.modal.month, day=1})
    local first_wd = tonumber(os.date("%w", first_day_t)) -- 0=Sun
    first_wd = (first_wd == 0) and 7 or first_wd -- Map to 1=Mon...7=Sun
    
    local days_in_month = DEADLINE.get_days_in_month(DEADLINE.modal.month, DEADLINE.modal.year)
    local day_cursor = 1
    local row = 0
    local now = os.date("*t")
    
    while day_cursor <= days_in_month do
        for col = 1, 7 do
            local current_wd_idx = row * 7 + col
            if current_wd_idx >= first_wd and day_cursor <= days_in_month then
                local cx = x + S(10) + (col - 1) * cell_w
                local cy = y + S(75) + row * S(30)
                
                -- Highlight if it matches the current set deadline
                local cur_dl = DEADLINE.modal.initial_date
                local is_highlighted = cur_dl and cur_dl.day == day_cursor and cur_dl.month == DEADLINE.modal.month and cur_dl.year == DEADLINE.modal.year
                
                local is_today = (day_cursor == now.day and DEADLINE.modal.month == now.month and DEADLINE.modal.year == now.year)
                
                -- Cell Background
                if is_highlighted then
                    set_color(UI.C_GREEN)
                    gfx.rect(cx + 2, cy + 2, cell_w - 4, S(26), 1)
                elseif is_today then
                    set_color(UI.C_RED) -- Use a distinct color for today
                    gfx.rect(cx + 2, cy + 2, cell_w - 4, S(26), 0) -- Outline
                end
                
                -- Click
                if is_mouse_clicked() and gfx.mouse_x >= cx and gfx.mouse_x < cx + cell_w and
                   gfx.mouse_y >= cy and gfx.mouse_y < cy + S(30) then
                    local new_ts = os.time({year=DEADLINE.modal.year, month=DEADLINE.modal.month, day=day_cursor, hour=0, min=0, sec=0})
                    if DEADLINE.modal.callback then DEADLINE.modal.callback(new_ts) end
                    DEADLINE.modal.show = false
                end
                
                -- Day Number
                set_color(is_highlighted and UI.C_BLACK or UI.C_TXT)
                local ds = tostring(day_cursor)
                local dw, dh = gfx.measurestr(ds)
                gfx.x = cx + (cell_w - dw) / 2
                gfx.y = cy + (S(30) - dh) / 2
                gfx.drawstr(ds)
                
                day_cursor = day_cursor + 1
            end
        end
        row = row + 1
    end
    
    -- Bottom Buttons
    local b_w = (w - S(30)) / 2
    local b_y = y + h - S(45)
    
    if btn(x + S(10), b_y, b_w, S(30), "Видалити Дедлайн") then
        if DEADLINE.modal.callback then DEADLINE.modal.callback(nil) end
        DEADLINE.modal.show = false
    end
    
    if btn(x + S(20) + b_w, b_y, b_w, S(30), "Закрити", UI.C_ROW) then
        DEADLINE.modal.show = false
    end

    -- Escape key check
    if input_queue then
        for _, c in ipairs(input_queue) do
            if c == 27 then -- ESC
                DEADLINE.modal.show = false
                break
            end
        end
    end
end

--- Parse deadline from name (e.g. [15.02.2026] or [15.02])
--- @param name string Text to parse
--- @return number|nil Unix timestamp of start of day
function DEADLINE.parse_from_name(name)
    -- Pattern: [DD.MM.YYYY] or [DD.MM]
    local d, m, y = name:match("%[(%d%d)%.(%d%d)%.?(%d?%d?%d?%d?)%]")
    if d and m then
        d, m = tonumber(d), tonumber(m)
        y = tonumber(y)
        local now = os.date("*t")
        if not y or y == 0 then
            y = now.year
        elseif y < 100 then
            y = 2000 + y
        end
        
        -- Return start of day (00:00:00)
        local success, res = pcall(os.time, {day=d, month=m, year=y, hour=0, min=0, sec=0})
        if success then return res end
    end
    return nil
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

--- Remove combining acute accents (stress marks) from a UTF-8 string
--- @param s string Input string
--- @return string Clean string
local function strip_accents(s)
    if not s then return "" end
    return s:gsub(acute, "")
end

--- Remove ASS/RTF style tags and newline codes from a string
--- @param s string Input string
--- @return string Clean string
local function strip_tags(s)
    if not s then return "" end
    return s:gsub("{.-}", ""):gsub("\\N", " "):gsub("\\n", " ")
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

--- Find substring in a UTF-8 string ignoring case and stress marks
--- Returns the START and END byte indices in the ORIGINAL string
--- @param s string Source string
--- @param query string Query string (unnormalized)
--- @return number, number Start and End indices
local function utf8_find_accent_blind(s, query)
    if not s or not query or query == "" then return nil end
    local q_clean = strip_accents(utf8_lower(query))
    if q_clean == "" then return nil end
    
    local s_lower = utf8_lower(s)
    local s_clean = strip_accents(s_lower)
    
    local start_c, end_c = s_clean:find(q_clean, 1, true)
    if not start_c then return nil end
    
    -- Map byte positions from s_clean back to s_lower
    local byte_map = {} 
    local clean_byte_idx = 1
    local i = 1
    local len = #s_lower
    
    while i <= len do
        local b = s_lower:byte(i)
        if b == 204 and (i < len and s_lower:byte(i+1) == 129) then
            i = i + 2 -- skip acute in mapping
        else
            local clen = 1
            if b >= 240 then clen = 4
            elseif b >= 224 then clen = 3
            elseif b >= 192 then clen = 2
            end
            
            for k = 0, clen - 1 do
                byte_map[clean_byte_idx + k] = i + k
            end
            
            i = i + clen
            clean_byte_idx = clean_byte_idx + clen
        end
    end
    
    local start_orig = byte_map[start_c]
    local end_orig = byte_map[end_c]
    
    if not start_orig or not end_orig then return nil end
    
    -- Include trailing stress marks in the final range
    while end_orig + 2 <= #s_lower do
        if s_lower:byte(end_orig + 1) == 204 and s_lower:byte(end_orig + 2) == 129 then
            end_orig = end_orig + 2
        else
            break
        end
    end
    
    return start_orig, end_orig
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
    
    local orig_r, orig_g, orig_b, orig_a = gfx.r, gfx.g, gfx.b, gfx.a
    
    -- Left line (text color)
    local left_x_bottom = center_x - right_line_thickness
    local left_x_top = left_x_bottom + tilt_offset
    
    gfx.set(orig_r, orig_g, orig_b, orig_a)
    for t = 0, left_line_thickness - 1 do
        gfx.line(left_x_bottom + t, bottom_y, left_x_top + t, top_y_pos)
    end
    
    -- Right line (red)
    local right_x_bottom = center_x + 1.5
    local right_x_top = right_x_bottom + tilt_offset
    local right_bottom_y = bottom_y - (accent_height / 2)
    
    gfx.set(1.0, 0.0, 0.0, orig_a) -- red color for accent mark (obeying alpha)
    for t = 0, right_line_thickness - 1 do
        gfx.line(right_x_bottom + t, right_bottom_y, right_x_top + t, top_y_pos)
    end
    
    gfx.set(orig_r, orig_g, orig_b, orig_a)
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
local function hex_to_rgb(hex)
    local h = hex:lower()
    -- Remap dark blues to lighter shades for dark background
    if h == "#000080" then return {0.4, 0.7, 1.0, 1} end -- Was Navy, now Light Blue
    if h == "#333399" then return {0.6, 0.7, 1.0, 1} end -- Was Dark Periwinkle, now Lighter
    
    hex = hex:gsub("#","")
    if #hex == 3 then
        local r = tonumber("0x"..hex:sub(1,1)..hex:sub(1,1))
        local g = tonumber("0x"..hex:sub(2,2)..hex:sub(2,2))
        local b = tonumber("0x"..hex:sub(3,3)..hex:sub(3,3))
        return {r/255, g/255, b/255, 1}
    elseif #hex == 6 then
        local r = tonumber("0x"..hex:sub(1,2))
        local g = tonumber("0x"..hex:sub(3,4))
        local b = tonumber("0x"..hex:sub(5,6))
        return {r/255, g/255, b/255, 1}
    end
    return nil
end

local function parse_html_to_spans(html, inherited)
    local segments = {}
    local remaining = html:gsub("%s+", " ")
    inherited = inherited or {}
    
    local tags = {
        { tag = "a",      pattern = "<a%s+([^>]-)>([^\0]-)</a>" },
        { tag = "span",   pattern = "<span%s+([^>]-)>([^\0]-)</span>" },
        { tag = "b",      pattern = "<b([^>]-)>([^\0]-)</b>" },
        { tag = "strong", pattern = "<strong([^>]-)>([^\0]-)</strong>" },
        { tag = "i",      pattern = "<i([^>]-)>([^\0]-)</i>" },
        { tag = "em",     pattern = "<em([^>]-)>([^\0]-)</em>" }
    }
    
    -- Fallback for tags without any attributes/spaces
    local tags_fallback = {
        { tag = "a",      pattern = "<a()>([^\0]-)</a>" },
        { tag = "span",   pattern = "<span()>([^\0]-)</span>" }
    }
    
    while #remaining > 0 do
        local best_start = 1000000
        local best_end = 0
        local chosen_tag = nil
        local chosen_attr = ""
        local chosen_text = ""
        
        for _, t in ipairs(tags) do
            local s, e, a, txt = remaining:find(t.pattern)
            if s and s < best_start then
                best_start = s
                best_end = e
                chosen_tag = t.tag
                chosen_attr = a or ""
                chosen_text = txt or ""
            end
        end
        
        for _, t in ipairs(tags_fallback) do
            local s, e, a, txt = remaining:find(t.pattern)
            if s and s < best_start then
                best_start = s
                best_end = e
                chosen_tag = t.tag
                chosen_attr = ""
                chosen_text = txt or ""
            end
        end
        
        if chosen_tag then
            -- Prefix
            local prefix = remaining:sub(1, best_start - 1)
            if #prefix > 0 then
                table.insert(segments, {
                    text = clean_html(prefix),
                    is_bold = inherited.is_bold,
                    is_italic = inherited.is_italic,
                    is_plain = inherited.is_plain,
                    color = inherited.color,
                    is_link = inherited.is_link,
                    word = inherited.word
                })
            end
            
            local next_inherited = {
                is_bold = inherited.is_bold,
                is_italic = inherited.is_italic,
                is_plain = inherited.is_plain,
                color = inherited.color,
                is_link = inherited.is_link,
                word = inherited.word
            }
            
            if chosen_tag == "a" then
                local word = chosen_attr:match('href=".-/([^/"]+)"') or chosen_text
                word = UTILS.url_decode(clean_html(word)):gsub("^%s+", ""):gsub("%s+$", "")
                next_inherited.is_link = true
                next_inherited.word = word
            elseif chosen_tag == "span" then
                local attr_lower = chosen_attr:lower()
                local is_plain_class = attr_lower:find('short%-interpret') or attr_lower:find('interpret') or 
                    attr_lower:find('remark') or attr_lower:find('gram') or 
                    attr_lower:find('info') or attr_lower:find('description') or
                    attr_lower:find('term') or attr_lower:find('note') or
                    attr_lower:find('interpret%-formula')
                
                if is_plain_class then next_inherited.is_plain = true end
                
                -- Extract color
                local color_hex = chosen_attr:match("[Cc][Oo][Ll][Oo][Rr]%s*:%s*(#[0-9a-fA-F]+)")
                if color_hex then
                    next_inherited.color = hex_to_rgb(color_hex)
                end
            elseif chosen_tag == "b" or chosen_tag == "strong" then
                next_inherited.is_bold = true
            elseif chosen_tag == "i" or chosen_tag == "em" then
                next_inherited.is_italic = true
                next_inherited.is_plain = true
            end
            
            local inner = parse_html_to_spans(chosen_text, next_inherited)
            for _, s in ipairs(inner) do table.insert(segments, s) end
            
            remaining = remaining:sub(best_end + 1)
        else
            table.insert(segments, {
                text = clean_html(remaining),
                is_bold = inherited.is_bold,
                is_italic = inherited.is_italic,
                is_plain = inherited.is_plain,
                color = inherited.color,
                is_link = inherited.is_link,
                word = inherited.word
            })
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
        seg.is_italic = seg.is_italic or false
        seg.word = seg.word or ""
        -- Color comparison logic needs to be careful with tables
        
        if #seg.text > 0 or seg.is_link then
            local last = merged[#merged]
            
            -- Helper to compare colors
            local colors_match = false
            if not last then
                 -- No last segment
            elseif not last.color and not seg.color then
                colors_match = true
            elseif last.color and seg.color then
                colors_match = (last.color[1] == seg.color[1] and 
                                last.color[2] == seg.color[2] and 
                                last.color[3] == seg.color[3])
            end

            local can_merge = last and 
                (last.is_link == seg.is_link) and 
                (last.is_plain == seg.is_plain) and 
                (last.is_bold == seg.is_bold) and
                (last.is_italic == seg.is_italic) and
                colors_match and
                (not seg.is_link or (last.word == seg.word))
           
            if can_merge then
                last.text = last.text .. seg.text
            else
                table.insert(merged, {
                    text = seg.text,
                    is_link = seg.is_link,
                    is_plain = seg.is_plain,
                    is_bold = seg.is_bold,
                    is_italic = seg.is_italic,
                    word = seg.word,
                    color = seg.color
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
            
            -- Use rich text parsing for cell content to support colors/styles
            local segments = parse_html_to_spans(cell_html)
            
            -- Also keep a plain text version for debugging or fallback if needed
            local cleaned = clean_html(cell_html)
            cleaned = cleaned:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
            
            table.insert(row_data.cells, {
                text = cleaned,
                segments = segments,
                colspan = colspan,
                rowspan = rowspan,
                is_cell_header = is_cell_header
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
    -- Clean up raw HTML from sidebar and ads globally
    html = html:gsub('<aside[^>]-class="column_sidebar"[^>]->.-</aside>', "")
    html = html:gsub('<div[^>]-class="ad%-wrapper.-"[^>]->.-</div>%s-</div>', "")
    html = html:gsub('<div[^>]-class="ad%-wrapper.-"[^>]->.-</div>', "")

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
            -- Add separator BEFORE subsequent blocks
            if _ > 1 and #lines > 0 then table.insert(lines, { is_separator = true }) end
            
            -- 1. Header (Word + remarks)
            local header_html = block:match('<h2 [^>]-class="page__sub%-header"[^>]->([^\0]-)</h2>')
            if header_html then
                local rich = parse_html_to_spans(header_html)
                if #rich > 0 then
                   table.insert(lines, { segments = rich, indent = 0, is_header = true })
                end
            end

            -- Interpretation body: extract the entire article-block__body content
            local body = block:match('<div class="article%-block__body">([^\0]-)<footer') 
                      or block:match('<div class="article%-block__body">([^\0]-)</div>%s-</div>') -- More robust for nested divs
                      or block:match('<div class="article%-block__body">([^\0]-)$')
                      or block
            
            -- Remove "Приклади" button text which clutters the view
            body = body:gsub('<span[^>]-class="show%-examples_btn"[^>]->.-</span>', "")

            -- Aggressive Cleanup: Remove source info and additional blocks from body 
            -- to prevent them from leaking into the definitions as messy text.
            body = body:gsub("<div[^>]*class=['\"][^'\"]*source%-info[^'\"]*['\"][^>]*>[^\0]-</div>", "")
            body = body:gsub("<span[^>]*class=['\"][^'\"]*source%-info[^'\"]*['\"][^>]*>[^\0]-</span>", "")
            body = body:gsub("<a[^>]*class=['\"][^'\"]*source%-info[^'\"]*['\"][^>]*>[^\0]-</a>", "")
            body = body:gsub('<div[^>]-class="page__additional%-block"[^>]->.-</div>%s-</div>', "")
            body = body:gsub('<div[^>]-class="[^"]*section_watch%-also[^"]*"[^>]->.-</div>', "")

            -- SPLIT BODY BY INTERPRET BLOCKS robustly (to handle nested divs like examples)
            local items = {}
            local last_search_pos = 1
            while true do
                local s, e = body:find('<div [^>]-class="interpret.-"[^>]->', last_search_pos)
                if not s then break end
                
                local next_s = body:find('<div [^>]-class="interpret.-"[^>]->', e + 1)
                local content
                if next_s then
                    content = body:sub(e + 1, next_s - 1)
                    last_search_pos = next_s
                else
                    content = body:sub(e + 1)
                    table.insert(items, content)
                    break
                end
                table.insert(items, content)
            end

            for _, item in ipairs(items) do
               local rich = parse_html_to_spans(item)
                if #rich > 0 then
                    rich[1].text = "• " .. rich[1].text
                    table.insert(lines, { segments = rich, indent = 1, is_header = false }) 
                end
            end
        elseif category == "Словозміна" then
            -- 1. Header (Word + short interpret)
            local header_html = block:match('<h2 [^>]-class="page__sub%-header"[^>]->([^\0]-)</h2>')
            if header_html then
                -- Add " - " prefix to short-interpret span
                header_html = header_html:gsub('(<span[^>]-class="short%-interpret"[^>]->)', '%1 — ')
                local rich = parse_html_to_spans(header_html)

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
            -- Add separator BEFORE subsequent blocks (if any lines were added in previous blocks)
            if _ > 1 and #lines > 0 then
                table.insert(lines, { is_separator = true })
            end
            
            -- 1. Header (Word + short interpret)
            local header_html = block:match('<h2 [^>]-class="page__sub%-header"[^>]->([^\0]-)</h2>')
            if header_html then
                -- Add "- " prefix to short-interpret span
                header_html = header_html:gsub('%s*(<span[^>]-class="short%-interpret"[^>]->)', '%1 — ')
                local rich = parse_html_to_spans(header_html)

                if #rich > 0 then
                    table.insert(lines, { segments = rich, indent = 0, is_header = true, block_idx = _ })
                end
            end
            -- 2. Indented items (synonyms or phrase interprets)
            for item in block:gmatch('<div [^>]-class="interpret.-"[^>]->([^\0]-)</div>') do
                local rich = parse_html_to_spans(item)
                if #rich > 0 then
                    rich[1].text = "• " .. rich[1].text
                    table.insert(lines, { segments = rich, indent = 1, is_header = false })
                end
            end
            
            for item in block:gmatch('<div [^>]-class="list%-item.-">([^\0]-)</div>') do
                local rich = parse_html_to_spans(item)
                if #rich > 0 then
                    rich[1].text = "• " .. rich[1].text
                    table.insert(lines, { segments = rich, indent = 1, is_header = false })
                end
            end
        elseif category == "Слововживання" then
            -- 1. Header (Word + short interpret)
            local header_html = block:match('<h2 [^>]-class="page__sub%-header"[^>]->([^\0]-)</h2>')
            if header_html then
                local rich = parse_html_to_spans(header_html)
                if #rich > 0 then
                   table.insert(lines, { segments = rich, indent = 0, is_header = true })
                end
            end

            -- Clean up source info manually on the whole block first
            -- Remove divs with source-info
            block = block:gsub("<div[^>]*class=['\"][^'\"]*source%-info[^'\"]*['\"][^>]*>[^\0]-</div>", "")
            -- Remove spans with source-info
            block = block:gsub("<span[^>]*class=['\"][^'\"]*source%-info[^'\"]*['\"][^>]*>[^\0]-</span>", "")
            -- Remove links with source-info (including source-info__link)
            block = block:gsub("<a[^>]*class=['\"][^'\"]*source%-info[^'\"]*['\"][^>]*>[^\0]-</a>", "")
            
            -- 2. Body (Content with colored spans)
            -- Use match to extract the body content
            local body = block:match('<div class="article%-block__body">([^\0]-)</div>%s-</div>') 
                      or block:match('<div class="article%-block__body">([^\0]-)</div>')
            if body then
                local pos = 1
                while true do
                    local t_start, t_end = body:find('<table.-</table>', pos)
                    if not t_start then
                        -- Remaining text
                        local rem = body:sub(pos)
                        if #rem > 0 then
                            -- Clean up extra newlines/spaces
                            local rich = parse_html_to_spans(rem)
                            if #rich > 0 then 
                                table.insert(lines, { segments = rich, indent = 1 }) 
                            end
                        end
                        break
                    end
                    
                    -- Text before table
                    if t_start > pos then
                        local pre = body:sub(pos, t_start - 1)
                        if pre:match("%S") then -- Only if meaningful text
                             local rich = parse_html_to_spans(pre)
                             if #rich > 0 then 
                                table.insert(lines, { segments = rich, indent = 1 }) 
                             end
                        end
                    end
                    
                    -- Table
                    local table_html = body:sub(t_start, t_end)
                    local grid = parse_dictionary_table_html(table_html)
                    if grid then
                        table.insert(lines, grid)
                        table.insert(lines, { segments = "" }) -- Spacing after table
                    end
                    
                    pos = t_end + 1
                end
            end

            if _ < #blocks then
                table.insert(lines, { is_separator = true })
            else
                table.insert(lines, { segments = "" })
            end
        end
    end
    
    -- Cleanup: Limit consecutive empty lines to max 2
    local cleaned_lines = {}
    local empty_count = 0
    
    local function is_item_empty(item)
        if type(item) ~= "table" then return false end
        if item.is_table then return false end -- Tables are content
        
        local segs = item.segments
        if not segs then return true end
        
        if type(segs) == "string" then 
            -- Remove NBSP (\194\160) and standard whitespace
            local s = segs:gsub("\194\160", ""):gsub("%s+", "")
            return s == ""
        end
        
        if type(segs) == "table" then
            if #segs == 0 then return true end
            for _, s in ipairs(segs) do
                if s.text then
                     -- Check for content after removing NBSP
                    local txt = s.text:gsub("\194\160", " ")
                    if txt:match("%S") then return false end
                end
            end
            return true
        end
        
        return false
    end
    
    -- Cleanup Phase
    for _, line in ipairs(lines) do
        -- Trim segments if it's a paragraph
        if type(line) == "table" and not line.is_table then
            if type(line.segments) == "string" then
                line.segments = line.segments:gsub("^%s+", ""):gsub("%s+$", "")
            elseif type(line.segments) == "table" then
                -- Trim start of first segment and end of last segment
                if #line.segments > 0 then
                    line.segments[1].text = line.segments[1].text:gsub("^%s+", "")
                    line.segments[#line.segments].text = line.segments[#line.segments].text:gsub("%s+$", "")
                end
            end
        end

        if is_item_empty(line) then
            if empty_count < 1 then -- Reduced to max 1 empty line
                table.insert(cleaned_lines, line)
                empty_count = empty_count + 1
            end
        else
            table.insert(cleaned_lines, line)
            empty_count = 0
        end
    end
    
    -- Remove trailing/leading empty lines
    while #cleaned_lines > 0 and is_item_empty(cleaned_lines[1]) do
        table.remove(cleaned_lines, 1)
    end
    while #cleaned_lines > 0 and is_item_empty(cleaned_lines[#cleaned_lines]) do
        table.remove(cleaned_lines)
    end
    
    -- 2. Handle "Watch Also" section (usually at the bottom of the page)
    -- This section is only relevant for Interpretation
    if category == "Тлумачення" then
        local watch_also = html:match('<div[^>]-class="[^"]*section_watch%-also[^"]*"[^>]->(.-)</div>%s-</div>')
                        or html:match('<div[^>]-class="[^"]*section_watch%-also[^"]*"[^>]->(.-)</div>%s-</div>%s-</div>') -- Handle potential wrapper depth
        if watch_also then
            -- Add separator if we already have content
            if #cleaned_lines > 0 then table.insert(cleaned_lines, { is_separator = true }) end
            
            -- Extract title (e.g. "Усталені словосполучення")
            local title = watch_also:match('<div[^>]-class="section%-header__title"[^>]->%s*(.-)%s*</div>') or "Дивіться також:"
            table.insert(cleaned_lines, { segments = parse_html_to_spans("<b>" .. title .. "</b>"), indent = 0, is_header = true })
            
            -- Extract list items from <li> tags
            for item in watch_also:gmatch('<li[^>]->(.-)</li>') do
                local rich = parse_html_to_spans(item)
                if #rich > 0 then
                    rich[1].text = "• " .. rich[1].text
                    table.insert(cleaned_lines, { segments = rich, indent = 1, is_header = false })
                end
            end
        end
    end
    
    return cleaned_lines
end

--- Fetch combined dictionary data
--- Fetch a specific dictionary category (Lazy loading)
local function fetch_dictionary_category(word, display_name)
    local categories = {
        ["Тлумачення"] = "Тлумачення",
        ["Словозміна"] = "Словозміна",
        ["Синоніми"] = "Синонімія",
        ["Фразеологія"] = "Фразеологія",
        ["Слововживання"] = "Слововживання"
    }
    
    local url_part = categories[display_name]
    if not url_part then return nil end
    
    local encoded = word
    if not word:find("%%") then encoded = UTILS.url_encode(word) end
    
    local url = "https://goroh.pp.ua/" .. UTILS.url_encode(url_part) .. "/" .. encoded
    
    -- Construct curl command
    -- Add User Agent to avoid 403 blocks
    -- Add --ssl-no-revoke for Windows compatibility
    -- Production: -s (silent) -S (show errors)
    local cmd = "curl -s -S -L --ssl-no-revoke -A \"Mozilla/5.0\" \"" .. url .. "\""
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

--- Asynchronous call to ElevenLabs API to check key validity
--- @param key string API Key
--- @param callback function Callback function(status, body)
local function eleven_api_call_async(key, callback)
    if not key or key == "" then 
        callback(0, "No API Key")
        return 
    end

    local url = "https://api.elevenlabs.io/v1/user"
    local cmd
    if reaper.GetOS():match("Win") then
        cmd = 'curl -s -k --ssl-no-revoke -w "\\n%{http_code}" -X GET "' .. url .. '" -H "xi-api-key: ' .. key .. '"'
    else
        cmd = "curl -s -w '\\n%{http_code}' -X GET '" .. url .. "' -H 'xi-api-key: " .. key .. "'"
    end
    
    run_async_command(cmd, function(output)
        if output and output ~= "" then
            local lines = {}
            for line in output:gmatch("[^\r\n]+") do table.insert(lines, line) end
            local status = tonumber(lines[#lines]) or 0
            local body = ""
            for i = 1, #lines - 1 do body = body .. lines[i] .. "\n" end
            callback(status, body)
        else
            callback(0, "No output")
        end
    end)
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
    show_snackbar("Перевірка ключа...", "info")
    gemini_api_call_async(key, "hi", function(status, body)
        cfg.gemini_key_status = status
        reaper.SetExtState(section_name, "gemini_key_status", tostring(status), true)
        
        if status == 200 then
            show_snackbar("API ключ валідний", "success")
        elseif status == 429 then
            show_snackbar("Ліміти вичерпані (429)", "error")
        else
            show_snackbar("Помилка API ключа (код: " .. tostring(status) .. ")", "error")
        end
    end)
end

--- Validate ElevenLabs API Key
--- @param key string API Key
local function validate_eleven_key(key)
    local trimmed_key = key:gsub("^%s*(.-)%s*$", "%1")
    show_snackbar("Перевірка ElevenLabs ключа...", "info")
    eleven_api_call_async(trimmed_key, function(status, body)
        local is_valid = (status == 200)
        
        -- Special case: some keys are restricted (e.g. synthesis only)
        -- but they return 401 with "missing_permissions" instead of "invalid_api_key"
        if status == 401 and body:match("missing_permissions") then
            is_valid = true
            status = 200 -- Treat as valid for UI purposes
        end

        cfg.eleven_key_status = status
        reaper.SetExtState(section_name, "eleven_key_status", tostring(status), true)
        
        if is_valid then
            show_snackbar("ElevenLabs ключ валідний", "success")
        else
            show_snackbar("Помилка ElevenLabs ключа (код: " .. tostring(status) .. ")", "error")
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
    
    if text_editor_state.context_line_idx and text_editor_state.context_all_lines then
        local idx = text_editor_state.context_line_idx
        local lines = text_editor_state.context_all_lines
        
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
    -- Clean word from extra symbols (quotes, ellipses, dots, etc)
    -- Include both standard dots and the single-char ellipsis '…'
    word = word:gsub('^["\'«»%.…]+', ''):gsub('["\'«»%.…]+$', ''):gsub(acute, "")
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

    if not sws_alert_shown then
        reaper.MB("Для кращої роботи буфера обміну рекомендується встановити SWS Extension.", "Subass", 0)
        sws_alert_shown = true
    end
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

--- Format seconds to simple timestamp string (HH:MM:SS or MM:SS) without milliseconds
--- @param seconds number Time in seconds
--- @return string Formatted timestamp
local function format_time_hms(seconds)
    local s = math.floor(seconds)
    local hours = math.floor(s / 3600)
    local minutes = math.floor((s % 3600) / 60)
    local secs = s % 60
    
    if hours > 0 then
        return string.format("%d:%02d:%02d", hours, minutes, secs)
    else
        return string.format("%02d:%02d", minutes, secs)
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
    if not text or text == "" then return "" end
    
    -- Check cache
    local cache_key = text .. "|" .. max_length
    if wrap_cache[cache_key] then return wrap_cache[cache_key] end

    -- Normalize existing newlines to \N for uniform processing
    local normalized_text = text:gsub("\n", "\\N"):gsub("\\n", "\\N")
    
    -- Tokenizer: tags, newlines, spaces, words
    local tokens = {}
    local cursor = 1
    while cursor <= #normalized_text do
        local token
        local nl_s, nl_e = normalized_text:find("^\\N", cursor)
        if nl_s then
            token = "\\N"
            cursor = nl_e + 1
        else
            local tag_s, tag_e = normalized_text:find("^{.-}", cursor)
            if tag_s == cursor then
                token = normalized_text:sub(tag_s, tag_e)
                cursor = tag_e + 1
            else
                local htm_s, htm_e = normalized_text:find("^<.->", cursor)
                if htm_s == cursor then
                    token = normalized_text:sub(htm_s, htm_e)
                    cursor = htm_e + 1
                else
                    local sp_s, sp_e = normalized_text:find("^%s+", cursor)
                    if sp_s == cursor then
                        token = normalized_text:sub(sp_s, sp_e)
                        cursor = sp_e + 1
                    else
                        -- Find word until next special char or space
                        local wd_s, wd_e = normalized_text:find("^[^%s{}<\\]+", cursor)
                        if wd_s then
                            token = normalized_text:sub(wd_s, wd_e)
                            cursor = wd_e + 1
                        else
                            -- Fallback for backslash or single special char
                            token = normalized_text:sub(cursor, cursor)
                            cursor = cursor + 1
                        end
                    end
                end
            end
        end
        if token then table.insert(tokens, token) end
    end

    local result = ""
    local current_line = ""
    local current_line_len = 0
    
    for _, t in ipairs(tokens) do
        if t == "\\N" then
            result = result .. (result == "" and "" or "\\N") .. current_line:gsub("%s+$", "")
            current_line = ""
            current_line_len = 0
        elseif t:find("^{") or t:find("^<") then
            -- Tags/Comments don't add to layout length
            current_line = current_line .. t
        elseif t:find("^%s+$") then
            -- Only count spaces if they aren't at the start of a line
            if current_line_len > 0 then
                current_line = current_line .. t
                current_line_len = current_line_len + (utf8.len(t) or #t)
            end
        else
            -- Word
            local w_len = utf8.len(t) or #t
            if current_line_len + w_len > max_length and current_line_len > 0 then
                -- Wrap
                result = result .. (result == "" and "" or "\\N") .. current_line:gsub("%s+$", "")
                current_line = t
                current_line_len = w_len
            else
                current_line = current_line .. t
                current_line_len = current_line_len + w_len
            end
        end
    end
    
    if current_line ~= "" then
        result = result .. (result == "" and "" or "\\N") .. current_line:gsub("%s+$", "")
    end

    if #wrap_cache > 100 then wrap_cache = {} end
    wrap_cache[cache_key] = result
    
    return result
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

local function parse_prompter_to_lines(str)
    local lines = {}
    local current_line = {}
    
    local state = {b=false, i=false, u=false, s=false}
    local cursor = 1
    local pending_comment = nil
    local global_comment = nil
    local has_text = false
    
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
                if pending_comment or global_comment then
                    local word_end = remainder:find("%s")
                    if word_end and word_end < #remainder then
                        local word = remainder:sub(1, word_end - 1)
                        local rest = remainder:sub(word_end)
                        table.insert(current_line, {text=word, b=state.b, i=state.i, u=state.u, s=state.s, comment=pending_comment or global_comment})
                        table.insert(current_line, {text=rest, b=state.b, i=state.i, u=state.u, s=state.s, comment=global_comment})
                    else
                        table.insert(current_line, {text=remainder, b=state.b, i=state.i, u=state.u, s=state.s, comment=pending_comment or global_comment})
                    end
                    pending_comment = nil
                else
                    table.insert(current_line, {text=remainder, b=state.b, i=state.i, u=state.u, s=state.s})
                end
                has_text = true
            end
            break
        end
        
        -- Append text before tag
        if tag_start > cursor then
            local segment = str:sub(cursor, tag_start - 1)
            if pending_comment or global_comment then
                local word_end = segment:find("%s")
                if word_end and word_end < #segment then
                    local word = segment:sub(1, word_end - 1)
                    local rest = segment:sub(word_end)
                    table.insert(current_line, {text=word, b=state.b, i=state.i, u=state.u, s=state.s, comment=pending_comment or global_comment})
                    table.insert(current_line, {text=rest, b=state.b, i=state.i, u=state.u, s=state.s, comment=global_comment})
                else
                    table.insert(current_line, {text=segment, b=state.b, i=state.i, u=state.u, s=state.s, comment=pending_comment or global_comment})
                end
                pending_comment = nil
            else
                table.insert(current_line, {text=segment, b=state.b, i=state.i, u=state.u, s=state.s})
            end
            if segment:find("%S") then has_text = true end
        end
        
        -- Handle Newline
        if str:sub(tag_start, tag_start+1) == "\\N" then
            table.insert(lines, current_line)
            current_line = {}
            cursor = tag_start + 2
            
        elseif str:sub(tag_start, tag_start) == "{" then
            -- Handle ASS Tag or Comment
            local tag_end = str:find("}", tag_start)
            if tag_end then
                local content = str:sub(tag_start+1, tag_end-1)
                
                local is_formatting = false
                -- Parse supported tags: \b1, \b0, \i1, \u1, \s1
                for tag in content:gmatch("\\[bius]%d") do
                    local t = tag:sub(2,2)
                    local v = (tag:sub(3,3) == "1")
                    if t == "b" then state.b = v
                    elseif t == "i" then state.i = v
                    elseif t == "u" then state.u = v
                    elseif t == "s" then state.s = v
                    end
                    is_formatting = true
                end
                
                -- Check for other formatting tags (starting with backslash)
                if not is_formatting and content:find("^\\") then
                    is_formatting = true
                end
                
                if not is_formatting and content ~= "" then
                    content = content:gsub("^%s+", ""):gsub("%s+$", "") -- Trim
                    if not has_text or #current_line == 0 then
                        global_comment = merge_comments(global_comment, content)
                    elseif #current_line > 0 then
                        -- SPLIT LAST SPAN to attach only to the last word
                        local last_span = current_line[#current_line]
                        if last_span.comment then
                            last_span.comment = merge_comments(last_span.comment, content)
                        else
                            local text = last_span.text
                            local word_start = text:find("[^%s]+%s*$")
                            if word_start and word_start > 1 then
                                local prefix = text:sub(1, word_start - 1)
                                local word = text:sub(word_start)
                                last_span.text = prefix
                                table.insert(current_line, {
                                    text = word, b=last_span.b, i=last_span.i, u=last_span.u, s=last_span.s, 
                                    comment = content
                                })
                            else
                                last_span.comment = content
                            end
                        end
                    else
                        pending_comment = merge_comments(pending_comment, content)
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
                local tag_found = true
                if content == "b" then state.b = true
                elseif content == "/b" then state.b = false
                elseif content == "i" then state.i = true
                elseif content == "/i" then state.i = false
                elseif content == "u" then state.u = true
                elseif content == "/u" then state.u = false
                elseif content == "s" then state.s = true
                elseif content == "/s" then state.s = false
                else
                    tag_found = false
                end
                
                if tag_found then
                    cursor = tag_end + 1
                else
                    -- Treat as text
                    local segment = str:sub(tag_start, tag_end)
                    table.insert(current_line, {text=segment, b=state.b, i=state.i, u=state.u, s=state.s})
                    if segment:find("%S") then has_text = true end
                    cursor = tag_end + 1
                end
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
    
    -- Final Pass: Apply global_comment to all spans that don't have a specific comment
    if global_comment then
        for _, line in ipairs(lines) do
            for _, span in ipairs(line) do
                if not span.comment then
                    span.comment = global_comment
                end
            end
        end
    end
    
    return lines
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
    -- Chunked saving to avoid 64KB limit
    local CHUNK_SIZE = 60000 
    
    local function save_chunked(base_key, data_tbl)
        local full_str = table.concat(data_tbl)
        local len = #full_str
        local chunks = math.ceil(len / CHUNK_SIZE)
        
        -- Store total chunk count
        reaper.SetProjExtState(0, section_name, base_key .. "_count", tostring(chunks))
        
        for i = 1, chunks do
            local start_p = (i - 1) * CHUNK_SIZE + 1
            local end_p = math.min(i * CHUNK_SIZE, len)
            local chunk = full_str:sub(start_p, end_p)
            reaper.SetProjExtState(0, section_name, base_key .. "_chunk_" .. i, chunk)
        end
        
        -- Legacy fallback (first chunk only)
        reaper.SetProjExtState(0, section_name, base_key, full_str:sub(1, CHUNK_SIZE))
    end

    -- Prepare lines data
    local dump_tbl = {}
    for i, l in ipairs(ass_lines) do
        local en = (l.enabled == nil or l.enabled) and "1" or "0"
        local r_idx = l.rgn_idx or -1
        local index = l.index or i
        table.insert(dump_tbl, string.format("%.3f|%.3f|%s|%s|%d|%d|%s\n", l.t1, l.t2, l.actor, en, r_idx, index, l.text:gsub("\n","\\n")))
    end
    save_chunked("ass_lines", dump_tbl)
    
    local act_tbl = {}
    for k,v in pairs(ass_actors) do
        table.insert(act_tbl, k .. "|" .. (v and "1" or "0") .. "\n")
    end
    reaper.SetProjExtState(0, section_name, "ass_actors", table.concat(act_tbl))
    
    reaper.SetProjExtState(0, section_name, "dir_actors", table.concat(director_actors, "|"))
    
    local col_tbl = {}
    for k,v in pairs(actor_colors) do
        table.insert(col_tbl, k .. "|" .. tostring(v) .. "\n")
    end
    reaper.SetProjExtState(0, section_name, "actor_colors", table.concat(col_tbl))

    reaper.SetProjExtState(0, section_name, "ass_loaded", UI_STATE.ass_file_loaded and "1" or "0")
    if UI_STATE.current_file_name then
        reaper.SetProjExtState(0, section_name, "ass_fname", UI_STATE.current_file_name)
    end
    
    -- Track edit in statistics
    STATS.increment_edit()

    local mark_tbl = {}
    for _, m in ipairs(ass_markers) do
        table.insert(mark_tbl, string.format("%.3f|%s|%d|%d\n", m.pos, m.name:gsub("\n", "\\n"), m.markindex, m.color))
    end
    save_chunked("ass_markers", mark_tbl)
end

--- Ensure all ass_lines have unique numeric indices
local function sanitize_indices()
    if not ass_lines then return end
    local used = {}
    local next_id = 1
    
    -- First pass: find max used numeric index to avoid collisions
    for _, l in ipairs(ass_lines) do
        if type(l.index) == "number" and l.index >= next_id then
            next_id = l.index + 1
        end
    end
    
    -- Second pass: fix missing or duplicate indices
    for _, l in ipairs(ass_lines) do
        if not l.index or type(l.index) ~= "number" or used[l.index] then
            l.index = next_id
            next_id = next_id + 1
        end
        used[l.index] = true
    end
end

--- Load director actors from ProjectExtState
local function load_director_actors_from_state()
    local okD, d_dump = reaper.GetProjExtState(0, section_name, "dir_actors")
    if okD and d_dump ~= "" then
        director_actors = {}
        for act in d_dump:gmatch("([^|]+)") do
            table.insert(director_actors, act)
        end
    else
        director_actors = {}
    end
end

--- Add actors to director_actors list if not already present
--- @param new_actors table|string Table of actor names or string containing [Actor] prefix
local function ensure_director_actors(new_actors)
    if not new_actors then return end
    local actors_to_add = {}
    
    if type(new_actors) == "string" then
        -- Extract from [Name] or [Name 1, Name 2] at the start of string
        local bracket_content = new_actors:match("^%[([^%]]+)%]")
        if bracket_content then
            for name in bracket_content:gmatch("[^,]+") do
                name = name:match("^%s*(.-)%s*$") -- Trim
                if name ~= "" then table.insert(actors_to_add, name) end
            end
        end
    elseif type(new_actors) == "table" then
        actors_to_add = new_actors
    end
    
    local changed = false
    local existing = {}
    for _, a in ipairs(director_actors) do existing[a] = true end
    
    for _, name in ipairs(actors_to_add) do
        if name and name ~= "" and not existing[name] then
            table.insert(director_actors, name)
            existing[name] = true
            changed = true
        end
    end
    
    if changed then
        -- Sort actors alphabetically for better UI
        table.sort(director_actors)
        save_project_data()
    end
end

--- Load project data from ProjectExtState
local function load_project_data()
    -- ALWAYS reset state first
    ass_lines = {}
    ass_actors = {}
    actor_colors = {}
    ass_markers = {} -- Added explicit reset
    UI_STATE.ass_file_loaded = false
    UI_STATE.current_file_name = nil
    
    local ok, loaded = reaper.GetProjExtState(0, section_name, "ass_loaded")
    
    if not ok or loaded ~= "1" then
        -- NEW PROJECT: No data loaded -> Switch to File tab
        UI_STATE.current_tab = 1
    end

    if ok and loaded == "1" then
        UI_STATE.ass_file_loaded = true
        
        local okF, fname = reaper.GetProjExtState(0, section_name, "ass_fname")
        if okF then UI_STATE.current_file_name = fname end
        
        -- Load chunked lines
        local l_dump = ""
        local okC, count_str = reaper.GetProjExtState(0, section_name, "ass_lines_count")
        if okC and count_str ~= "" then
            local count = tonumber(count_str) or 0
            for i = 1, count do
                local okX, chunk = reaper.GetProjExtState(0, section_name, "ass_lines_chunk_" .. i)
                if okX then l_dump = l_dump .. chunk end
            end
        else
            -- Legacy fallback
            local okL, legacy_dump = reaper.GetProjExtState(0, section_name, "ass_lines")
            if okL then l_dump = legacy_dump end
        end

        if l_dump ~= "" then
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
                            -- Older formats...
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
        
        -- Load chunked markers
        local m_dump = ""
        local okMC, m_count_str = reaper.GetProjExtState(0, section_name, "ass_markers_count")
        if okMC and m_count_str ~= "" then
            local count = tonumber(m_count_str) or 0
            for i = 1, count do
                local okX, chunk = reaper.GetProjExtState(0, section_name, "ass_markers_chunk_" .. i)
                if okX then m_dump = m_dump .. chunk end
            end
        else
            local okML, m_legacy = reaper.GetProjExtState(0, section_name, "ass_markers")
            if okML then m_dump = m_legacy end
        end

        if m_dump ~= "" then
            ass_markers = {} -- Reset before populating
            for line in m_dump:gmatch("([^\n]*)\n?") do
                if line ~= "" then
                    local pos, name, midx, col = line:match("^(.-)|(.-)|(.-)|(.*)$")
                    if pos and name then
                        table.insert(ass_markers, {
                            pos = tonumber(pos),
                            name = name:gsub("\\n", "\n"),
                            markindex = tonumber(midx) or 0,
                            color = tonumber(col) or 0
                        })
                    end
                end
            end
        end
        
        load_director_actors_from_state()
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

    STATS.update_metadata()
end

-- LOAD DATA ON STARTUP
load_project_data()
sanitize_indices()

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
            -- Ensure it exists in ass_actors
            if ass_actors[line.actor] == nil then
                ass_actors[line.actor] = true
            end
        end
    end
    
    -- Remove actors from ass_actors if they are no longer in any line
    -- AND remove from actor_colors if needed
    for act in pairs(ass_actors) do
        if not current_actors[act] then
            ass_actors[act] = nil
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

--- Check if a replica with same actor, timing and text already exists
--- @param actor string Actor name
--- @param t1 number Start time
--- @param t2 number End time
--- @param text string Replica text
--- @return boolean True if duplicate found
local function is_duplicate_replica(actor, t1, t2, text)
    if not ass_lines then return false end
    for _, l in ipairs(ass_lines) do
        -- Compare with small epsilon for timing
        if l.actor == actor and 
           math.abs(l.t1 - t1) < 0.005 and 
           math.abs(l.t2 - t2) < 0.005 and 
           l.text == text then
            return true
        end
    end
    return false
end

local function capture_project_markers()
    local markers = {}
    local i = 0
    while true do
        local retval, isrgn, pos, rgnend, name, markindex, color = reaper.EnumProjectMarkers3(0, i)
        if retval == 0 then break end
        if not isrgn then
            table.insert(markers, {
                pos = pos,
                name = name,
                markindex = markindex,
                color = color
            })
        end
        i = i + 1
    end
    return markers
end

local function update_regions_cache()
    regions = {}
    local retval, num_markers, num_regions = reaper.CountProjectMarkers(0)
    local i = 0
    local rgn_map = {}
    while i < (num_markers + num_regions) do
        local retval, isrgn, pos, rgnend, name, idx = reaper.EnumProjectMarkers(i)
        if isrgn then
            local rgn_obj = {idx = idx, pos = pos, rgnend = rgnend, name = name, rgn_index = i, actor = ""}
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
            if line.enabled == false then goto skip_sync end
            if line.rgn_idx then
                if tracked_rgn_idxs[line.rgn_idx] then
                    -- DUPLICATE ID: Another line already uses this region ID. 
                    -- Unlink this one so it can find its own region in orphan pass.
                    line.rgn_idx = nil
                    changed = true
                else
                    local rgn = rgn_map[line.rgn_idx]
                    if rgn then
                        rgn.actor = line.actor
                        -- Update times if changed in REAPER
                        if math.abs(line.t1 - rgn.pos) > 0.0001 or math.abs(line.t2 - rgn.rgnend) > 0.0001 or (line.text ~= rgn.name and rgn.name ~= "<пусто>") then
                            line.t1 = rgn.pos
                            line.t2 = rgn.rgnend
                            line.text = rgn.name
                            changed = true
                        end
                        tracked_rgn_idxs[line.rgn_idx] = true
                    else
                        -- Region ID is gone from project.
                        -- UNLINK instead of DELETE to prevent data loss on transient ID issues.
                        line.rgn_idx = nil
                        changed = true
                    end
                end
            end
            ::skip_sync::
        end
        
        -- 1.5. Try to RE-BIND orphans to available regions match by Time AND TEXT
        for i, line in ipairs(ass_lines) do
            if not line.rgn_idx and line.enabled ~= false then
                for idx, rgn in pairs(rgn_map) do
                    if not tracked_rgn_idxs[idx] then
                        -- Strict Time Match (approx 1ms tolerance)
                        if math.abs(line.t1 - rgn.pos) < 0.001 and math.abs(line.t2 - rgn.rgnend) < 0.001 then
                            -- Also check text to minimize wrong actor binding if times are identical
                            if UTILS.compare_sub_text(line.text, rgn.name) then 
                                line.rgn_idx = idx
                                rgn.actor = line.actor
                                tracked_rgn_idxs[idx] = true
                                changed = true
                                break 
                            end
                        end
                    end
                end
            end
        end
        
        -- 2. Adopt "foreign" regions (created manually in REAPER)
        for idx, rgn in pairs(rgn_map) do
            if not tracked_rgn_idxs[idx] then
                -- This is a new region! Adopt it.
                if not UI_STATE.ass_file_loaded then UI_STATE.ass_file_loaded = true end
                
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
                rgn.actor = "REAPER"
            end
        end
        
        if changed then
            cleanup_actors()
            save_project_data()
        end

        -- Sync markers (non-regions)
        ass_markers = capture_project_markers()
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
    
    -- Clear all tracked region indices for ass_lines before rebuild
    if ass_lines then
        for _, line in ipairs(ass_lines) do
            line.rgn_idx = nil
        end
    end
    
    -- Fast Delete: Repeatedly delete the first marker until none remain.
    local safety_cnt = 0
    local max_markers = reaper.CountProjectMarkers(0) + 10 -- Add Buffer
    while true do
        local retval, isrgn, pos, rgnend, name, idx = reaper.EnumProjectMarkers(0)
        if not retval or retval == 0 then break end
        reaper.DeleteProjectMarker(0, idx, isrgn)
        
        safety_cnt = safety_cnt + 1
        if safety_cnt > max_markers then 
            -- ERROR: Something is not being deleted. Break to prevent freeze.
            break 
        end 
    end
    
    -- Add from ass_lines if line is enabled
    local count = 0
    local last_t1, last_t2, last_text = -1, -1, ""
    for i, line in ipairs(ass_lines) do
        if line.enabled ~= false then -- Default true if nil
            local col = get_actor_color(line.actor)
            if col == 0 and cfg.random_color_actors then
                col = get_actor_color(line.actor) 
            end
            
            -- Force uniqueness for REAPER by adding a 10ms epsilon to identical overlapping regions
            local t1, t2 = line.t1, line.t2
            if math.abs(t1 - last_t1) < 0.001 and math.abs(t2 - last_t2) < 0.001 and line.text == last_text then
                t2 = t2 + 0.001
            end
            
            local rgn_idx = reaper.AddProjectMarker2(0, true, t1, t2, line.text, -1, col)
            line.rgn_idx = rgn_idx
            
            last_t1, last_t2, last_text = t1, t2, line.text
            count = count + 1
        end
    end
    
    -- Sync back markers (non-regions) from ass_markers
    for _, m in ipairs(ass_markers) do
        reaper.AddProjectMarker2(0, false, m.pos, 0, m.name, m.markindex, m.color)
    end
    
    reaper.Undo_EndBlock("Update Synced Regions", -1)
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()

    update_regions_cache() -- Update cache immediately execution
    save_project_data() -- SAVE ON CHANGE
    STATS.update_metadata()
end

local function push_undo(label)
    if not ass_lines then return end
    
    -- Capture markers from project
    ass_markers = capture_project_markers()
    
    -- Capture state
    local state = {
        lines = deep_copy_table(ass_lines),
        actors = deep_copy_table(ass_actors),
        dir_actors = deep_copy_table(director_actors),
        markers = deep_copy_table(ass_markers),
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
    
    -- Capture current state to redo stack before restoring
    local current_state = {
        lines = deep_copy_table(ass_lines),
        actors = deep_copy_table(ass_actors),
        dir_actors = deep_copy_table(director_actors),
        markers = capture_project_markers(),
        label = undo_stack[#undo_stack].label
    }
    
    local last_state = table.remove(undo_stack)
    
    table.insert(redo_stack, current_state)
    if #redo_stack > max_undo_depth then
        table.remove(redo_stack, 1)
    end

    ass_lines = last_state.lines
    ass_actors = last_state.actors
    ass_markers = last_state.markers
    if last_state.dir_actors then director_actors = last_state.dir_actors end
    
    cleanup_actors()
    rebuild_regions()
    save_project_data(UI_STATE.last_project_id) -- Sync to metadata
    show_snackbar("Відмінено: " .. last_state.label, "info")
end

local function redo_action()
    if #redo_stack == 0 then return end
    
    local next_state = table.remove(redo_stack)
    
    -- Save current state back to undo stack
    local current_state = {
        lines = deep_copy_table(ass_lines),
        actors = deep_copy_table(ass_actors),
        dir_actors = deep_copy_table(director_actors),
        markers = capture_project_markers(),
        label = next_state.label
    }
    
    table.insert(undo_stack, current_state)
    if #undo_stack > max_undo_depth then
        table.remove(undo_stack, 1)
    end

    ass_lines = next_state.lines
    ass_actors = next_state.actors
    ass_markers = next_state.markers
    if next_state.dir_actors then director_actors = next_state.dir_actors end
    
    cleanup_actors()
    rebuild_regions()
    save_project_data(UI_STATE.last_project_id) -- Sync to metadata
    show_snackbar("Повторено: " .. next_state.label, "info")
end

local function apply_item_coloring(reset)
    local items = {}
    local item_count = reaper.CountSelectedMediaItems(0)
    
    if item_count > 0 then
        for i = 0, item_count - 1 do
            table.insert(items, reaper.GetSelectedMediaItem(0, i))
        end
    else
        local track_count = reaper.CountSelectedTracks(0)
        if track_count > 0 then
            local processed_tracks = {}
            for i = 0, track_count - 1 do
                local track = reaper.GetSelectedTrack(0, i)
                if not processed_tracks[track] then
                    processed_tracks[track] = true
                    local depth = reaper.GetTrackDepth(track)
                    local track_idx = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
                    local total_tracks = reaper.CountTracks(0)
                    for j = track_idx, total_tracks - 1 do
                        local child = reaper.GetTrack(0, j)
                        if child and reaper.GetTrackDepth(child) > depth then
                            processed_tracks[child] = true
                        else break end
                    end
                end
            end
            for tr in pairs(processed_tracks) do
                local track_item_count = reaper.CountTrackMediaItems(tr)
                for j = 0, track_item_count - 1 do
                    table.insert(items, reaper.GetTrackMediaItem(tr, j))
                end
            end
        end
    end

    if #items == 0 then
        show_snackbar("Виберіть Media Item або Треки", "info")
        return
    end

    if not reset then
        local msg = "Ця функція розфарбує айтеми на вибраних треках (включаючи дочірні).\n\n" ..
                    "УВАГА: Розфарбовування працює тільки для айтемів у межах ВИДИМИХ регіонів.\n" ..
                    "Приховані регіони (через фільтр акторів) будуть ігноруватися.\n\n" ..
                    "Бажаєте продовжити?"
        local res = reaper.MB(msg, "Розфарбувати за акторами", 1) -- 1 = OK/Cancel
        if res ~= 1 then return end
    end

    local colored = 0
    for _, item in ipairs(items) do
        if item then
            if reset then
                reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", 0)
                colored = colored + 1
            else
                local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
                local item_end = item_start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
                
                local max_overlap = 0
                local best_color = nil
                
                -- Efficiently find overlapping regions
                local _, num_markers, num_regions = reaper.CountProjectMarkers(0)
                local total = num_markers + num_regions
                
                for j = 0, total - 1 do
                    local _, isrgn, r_start, r_end, _, _, color = reaper.EnumProjectMarkers3(0, j)
                    if isrgn and color ~= 0 then
                            -- Calculate intersection
                            local overlap_start = math.max(item_start, r_start)
                            local overlap_end = math.min(item_end, r_end)
                            local overlap = overlap_end - overlap_start
                            
                            if overlap > max_overlap then
                                max_overlap = overlap
                                best_color = color
                        end
                    end
                end
                
                local item_len = item_end - item_start
                if best_color and max_overlap > 0 then
                    -- Higher precision thresholds:
                    -- At least 0.8s (substantial chunk) OR more than 50% of the item
                    if max_overlap > 0.8 or (max_overlap / item_len) > 0.5 then
                        -- For Media Items, we need the 0x1000000 flag for custom colors
                        reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", best_color | 0x1000000)
                        colored = colored + 1
                    end
                end
            end
        end
    end
    
    reaper.UpdateArrange()
    if not reset then
        show_snackbar("Розфарбовано " .. colored .. " айтемів", "success")
    else
        show_snackbar("Розфарбування скинуто (" .. colored .. ")", "success")
    end
end

--- LUFS Normalization (ITU-R BS.1770-4 via SWS Extension)
--- Uses true LUFS measurement with K-weighting and integrated gating.
--- Includes "De-Boomer" spectral correction (cuts only) for muddy voices.
--- 
--- ADAPTIVE GAIN LIMITING:
--- Short clips naturally measure lower LUFS (less integration time).
--- To prevent over-amplification, gain is limited relative to LONG CLIPS median (>=2s):
---   - <0.5s clips: max 120% of long clips median gain
---   - 0.5-2s clips: max 150% of long clips median gain  
---   - >2s clips: max 250% of long clips median gain
--- This uses dialogue as baseline, preventing short clips from skewing the reference.
local function ebu_r128_replicas_normalize()
    -- Check SWS Extension availability
    if not reaper.APIExists("NF_AnalyzeTakeLoudness_IntegratedOnly") then
        show_snackbar("SWS Extension потрібен для LUFS нормалізації", "error")
        reaper.MB("Ця функція потребує SWS Extension.\n\nЗавантажте та встановіть з:\nhttps://www.sws-extension.org/", "SWS Extension не знайдено", 0)
        return
    end

    local items = {}
    local sel_item_count = reaper.CountSelectedMediaItems(0)
    
    if sel_item_count > 0 then
        for i = 0, sel_item_count - 1 do
            table.insert(items, reaper.GetSelectedMediaItem(0, i))
        end
    else
        local track_count = reaper.CountSelectedTracks(0)
        if track_count > 0 then
            local processed_tracks = {}
            for i = 0, track_count - 1 do
                local track = reaper.GetSelectedTrack(0, i)
                if not processed_tracks[track] then
                    processed_tracks[track] = true
                    local depth = reaper.GetTrackDepth(track)
                    local track_idx = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
                    local total_tracks = reaper.CountTracks(0)
                    for j = track_idx, total_tracks - 1 do
                        local child = reaper.GetTrack(0, j)
                        if child and reaper.GetTrackDepth(child) > depth then
                            processed_tracks[child] = true
                        else break end
                    end
                end
            end
            for tr in pairs(processed_tracks) do
                local track_item_count = reaper.CountTrackMediaItems(tr)
                for j = 0, track_item_count - 1 do
                    table.insert(items, reaper.GetTrackMediaItem(tr, j))
                end
            end
        end
    end

    if #items == 0 then
        show_snackbar("Виберіть Media Item або Треки", "error")
        return
    end

    local last_val = reaper.GetExtState(section_name, "lufs_norm_target")
    if last_val == "" then last_val = "-16.0" end

    local ok, ret_val = reaper.GetUserInputs("Нормалізація реплік (LUFS)", 1, "Цільова гучність LUFS (-5 до -40):,extrawidth=50", last_val)
    if not ok then return end
    
    local target_lufs = tonumber(ret_val)
    if not target_lufs or target_lufs > -5 or target_lufs < -40 then
        show_snackbar("Будь ласка, введіть число від -5 до -40 LUFS", "error")
        return
    end
    
    reaper.SetExtState(section_name, "lufs_norm_target", tostring(target_lufs), true)

    local start_time = reaper.time_precise()

    -- Helper: Measures spectral balance for De-Boomer AND robust RMS for peak handling
    local function analyze_take_structure(take)
        local source = reaper.GetMediaItemTake_Source(take)
        if not source then return -100, -100 end
        local samplerate = reaper.GetMediaSourceSampleRate(source)
        if not samplerate or samplerate < 1 then return -100, -100 end
        local accessor = reaper.CreateTakeAudioAccessor(take)
        local starttime = reaper.GetAudioAccessorStartTime(accessor)
        local endtime = reaper.GetAudioAccessorEndTime(accessor)
        local duration = endtime - starttime
        
        if duration <= 0 then reaper.DestroyAudioAccessor(accessor); return -100, -100 end
        if duration > 60 then duration = 60 end 

        local chunk_size_ms = 0.050 -- 50ms window
        local samples_per_chunk = math.floor(samplerate * chunk_size_ms)
        local buf = reaper.new_array(samples_per_chunk)
        
        -- Highpass Filter State (for presence analysis)
        local xp, yp = 0, 0
        local alpha = 0.93 -- ~500Hz HPF at 44.1k
        
        local bp_energy_sum = 0
        local chunk_count = 0
        local rms_list = {}
        local total_chunks = math.floor(duration / chunk_size_ms)
        
        if total_chunks < 1 then reaper.DestroyAudioAccessor(accessor); return -100, -100 end

        for i = 0, total_chunks - 1 do
            local t = i * chunk_size_ms
            reaper.GetAudioAccessorSamples(accessor, samplerate, 1, t, samples_per_chunk, buf)
            
            local bp_chunk_sum = 0
            local raw_chunk_sum = 0
            for j = 1, samples_per_chunk do
                local x = buf[j]
                raw_chunk_sum = raw_chunk_sum + (x*x)
                -- Highpass Energy (Presence)
                local y = x - xp + (alpha * yp)
                xp, yp = x, y
                bp_chunk_sum = bp_chunk_sum + (y*y)
            end
            
            bp_energy_sum = bp_energy_sum + bp_chunk_sum
            chunk_count = chunk_count + 1
            
            local rms = math.sqrt(raw_chunk_sum / samples_per_chunk)
            if rms > 0.001 then -- Gate -60dB
                table.insert(rms_list, 20 * math.log(rms, 10))
            end
        end
        reaper.DestroyAudioAccessor(accessor)

        if chunk_count == 0 then return -100, -100 end
        
        local avg_bp_energy = bp_energy_sum / (chunk_count * samples_per_chunk)
        local bp_db = 20 * math.log(math.sqrt(avg_bp_energy), 10)
        
        local median_rms = -100
        if #rms_list > 0 then
            table.sort(rms_list)
            median_rms = rms_list[math.ceil(#rms_list * 0.5)]
        end
        return bp_db, median_rms
    end

    reaper.Undo_BeginBlock()
    reaper.ShowConsoleMsg("═══════════════════════════════════════════\n")
    reaper.ShowConsoleMsg("[LUFS Normalization] Press ESC to ABORT\n")
    reaper.ShowConsoleMsg("═══════════════════════════════════════════\n\n")
    
    -- PASS 1: Group items by TRACK and Analyze
    local track_groups = {}
    local normalized_count = 0
    
    for i = 1, #items do
        local item = items[i]
        local take = reaper.GetActiveTake(item)
        if take then
            local track = reaper.GetMediaItem_Track(item)
            if not track_groups[track] then track_groups[track] = { items = {}, bp_sum = 0, bp_cnt = 0 } end
            
            -- Reset Volume for Analysis
            local original_vol = reaper.GetMediaItemTakeInfo_Value(take, "D_VOL")
            reaper.SetMediaItemTakeInfo_Value(take, "D_VOL", 1.0)
            
            local retval, lufs = reaper.NF_AnalyzeTakeLoudness_IntegratedOnly(take)
            
            -- Check for cancellation (ESC or SWS Cancel)
            local abort = false
            if not retval then abort = true end -- SWS window cancelled
            
            local char = gfx.getchar() 
            if char == 27 or char == -1 then abort = true end
            
            if not abort and reaper.JS_VKeys_GetState then
                local state = reaper.JS_VKeys_GetState(0)
                if state:byte(28) ~= 0 then abort = true end
            end

            if abort then
                reaper.ShowConsoleMsg("\n⚠️ ABORTED BY USER.\n")
                show_snackbar("Нормалізацію перервано користувачем", "error")
                reaper.Undo_EndBlock("LUFS Normalization (Aborted)", -1)
                return
            end

            local bp_db, median_rms = analyze_take_structure(take)
            reaper.SetMediaItemTakeInfo_Value(take, "D_VOL", original_vol)
            
            if lufs and lufs > -100 then
                local item_data = {
                    take = take,
                    item = item,
                    lufs = lufs, 
                    bp_db = bp_db, 
                    med_rms = median_rms,
                    len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
                }
                table.insert(track_groups[track].items, item_data)
                
                track_groups[track].bp_sum = track_groups[track].bp_sum + bp_db
                track_groups[track].bp_cnt = track_groups[track].bp_cnt + 1

                local progress_pct = (i / #items) * 100
                reaper.ShowConsoleMsg(string.format("Processed %d/%d (%.3f%%) - LUFS: %.1f\n", i, #items, progress_pct, lufs))
            end
        end
    end
    
    -- PROCESS PER TRACK
    for track, group in pairs(track_groups) do
        -- A. Pre-calculate gains for ALL items to allow fast lookups
        -- structure: { pos = number, len = number, gain_needed = number, bp_db = number, is_anchor = boolean }
        local item_gains = {}
        for _, res in ipairs(group.items) do
            local gain = target_lufs - res.lufs
            -- Identify "Anchors" (Long reliable clips > 2.0s)
            local is_anchor = (res.len >= 2.0)
            table.insert(item_gains, {
                pos = reaper.GetMediaItemInfo_Value(res.item, "D_POSITION"),
                len = res.len,
                gain_needed = gain,
                bp_db = res.bp_db,
                is_anchor = is_anchor
            })
        end
        
        -- Helper: Find Median Gain AND Mean BP (Spectral) of ANCHORS within time window
        local function get_local_context(center_pos, window_sec)
            local local_gains = {}
            local local_bp_sum = 0
            local local_bp_cnt = 0
            
            for _, d in ipairs(item_gains) do
                if d.is_anchor then
                    local dist = math.abs(d.pos - center_pos)
                    if dist <= window_sec then
                        table.insert(local_gains, d.gain_needed)
                        if d.bp_db > -100 then
                            local_bp_sum = local_bp_sum + d.bp_db
                            local_bp_cnt = local_bp_cnt + 1
                        end
                    end
                end
            end
            
            if #local_gains == 0 then return nil, nil end
            table.sort(local_gains)
            local median_gain = local_gains[math.floor(#local_gains * 0.5) + 1]
            local mean_bp = (local_bp_cnt > 0) and (local_bp_sum / local_bp_cnt) or -100
            
            return median_gain, mean_bp
        end

        -- Fallback: Global context
        local global_gains = {}
        local global_bp_sum = 0
        local global_bp_cnt = 0
        for _, d in ipairs(item_gains) do
            if d.is_anchor then 
                table.insert(global_gains, d.gain_needed)
                if d.bp_db > -100 then
                    global_bp_sum = global_bp_sum + d.bp_db
                    global_bp_cnt = global_bp_cnt + 1
                end
            end
        end
        table.sort(global_gains)
        local global_median = global_gains[math.floor(#global_gains * 0.5) + 1] or 0
        local global_mean_bp = (global_bp_cnt > 0) and (global_bp_sum / global_bp_cnt) or -100

        
        -- B. Apply Normalization with Relative Logic
        local track_stats = { norm=0, noise=0, boom=0, gain_sum=0 }
        
        for i, res in ipairs(group.items) do
            local gain_db = 0
            local classification = "Normal"
            local correction_db = 0
            
            -- Find Local Context (Window +/- 60s)
            local item_pos = reaper.GetMediaItemInfo_Value(res.item, "D_POSITION")
            local anchor_gain, anchor_bp = get_local_context(item_pos, 60.0)
            
            -- Fallbacks
            if not anchor_gain then anchor_gain, anchor_bp = get_local_context(item_pos, 120.0) end
            if not anchor_gain then anchor_gain, anchor_bp = global_median, global_mean_bp end
            
            -- SAFETY GATE: If item is too quiet (<-42 LUFS), it's likely noise/roomtone.
            if res.lufs < -42.0 then
                gain_db = 0.0
                classification = "Ignored (Noise Floor)"
                track_stats.noise = track_stats.noise + 1
            else
                -- Gain Logic
                if res.len < 0.5 then
                    gain_db = anchor_gain
                    classification = "Breath (Rel)"
                elseif res.len < 2.0 then
                    local strict_gain = target_lufs - res.lufs
                    local deviation = strict_gain - anchor_gain
                    if deviation > 4.0 then strict_gain = anchor_gain + 4.0 end
                    if deviation < -4.0 then strict_gain = anchor_gain - 4.0 end
                    gain_db = strict_gain
                    classification = "Short (Hyb)"
                else
                    gain_db = target_lufs - res.lufs
                    classification = "Long (Strict)"
                end
                
                -- De-Boomer (Local Context)
                if anchor_bp and anchor_bp > -100 then
                    local presence_diff = anchor_bp - res.bp_db 
                    if presence_diff > 0 then
                        correction_db = presence_diff * 0.15 
                        if correction_db < -6.0 then correction_db = -6.0 end
                        if correction_db < -0.5 then track_stats.boom = track_stats.boom + 1 end
                    end
                end
                
                track_stats.norm = track_stats.norm + 1
                track_stats.gain_sum = track_stats.gain_sum + (gain_db - correction_db)
            end

            local final_vol = 10 ^ ((gain_db - correction_db) / 20)
            
            -- Safety limits
            if final_vol > 32.0 then final_vol = 32.0 end
            if final_vol < 0.01 then final_vol = 0.01 end
            
            reaper.SetMediaItemTakeInfo_Value(res.take, "D_VOL", final_vol)
            normalized_count = normalized_count + 1
        end
        
        -- Print Track Report
        local _, tr_name = reaper.GetTrackName(track)
        local avg_gain = (track_stats.norm > 0) and (track_stats.gain_sum / track_stats.norm) or 0
        local avg_sign = (avg_gain >= 0) and "+" or ""
        reaper.ShowConsoleMsg(string.format("TRACK: %s\n  Normalized: %d\n  Avg Gain: %s%.1fdB\n  Ignored (Noise): %d\n  De-Boomed: %d\n-----------------------\n", tr_name, track_stats.norm, avg_sign, avg_gain, track_stats.noise, track_stats.boom))
    end
    
    local elapsed = reaper.time_precise() - start_time
    reaper.ShowConsoleMsg(string.format("═══════════════════════\nTOTAL: %d items normalized in %.2f seconds.\n", normalized_count, elapsed))
    reaper.UpdateArrange()
    reaper.Undo_EndBlock("LUFS Normalization (Track-Smart)", -1)
    
    if normalized_count > 0 then
        show_snackbar("Оброблено " .. normalized_count .. " айтемів. Див. консоль.", "success")
    else
        show_snackbar("Помилка: нічого не оброблено", "error")
    end
end

local function filter_unique_item_replicas()
    local track_count = reaper.CountSelectedTracks(0)
    if track_count ~= 2 then
        show_snackbar("Виберіть рівно 2 треки для порівняння", "error")
        return
    end

    local tr1 = reaper.GetSelectedTrack(0, 0)
    local tr2 = reaper.GetSelectedTrack(0, 1)
    local _, tr1_name = reaper.GetTrackName(tr1)
    local _, tr2_name = reaper.GetTrackName(tr2)

    local msg = "ЯК ЦЕ ПРАЦЮЄ:\n" ..
                "Ця функція порівняє форму хвилі (waveform) айтемів на двох вибраних треках.\n" ..
                "Дублікати будуть автоматично видалені з ТАРГЕТ-треку, якщо вони збігаються з ОСНОВНИМ треком на 96% і більше.\n\n" ..
                "Виберіть ОСНОВНИЙ (еталонний) трек:\n\n" ..
                "YES: " .. tr1_name .. "\n" ..
                "NO: " .. tr2_name .. "\n" ..
                "CANCEL: Скасувати"
    local ret = reaper.ShowMessageBox(msg, "Waveform Match: Вибір основного треку", 3)

    local main_tr, target_tr
    if ret == 6 then main_tr, target_tr = tr1, tr2
    elseif ret == 7 then main_tr, target_tr = tr2, tr1
    else return end

    reaper.ClearConsole()
    reaper.ShowConsoleMsg("Waveform Match Analysis (Track Mode)\n")
    reaper.ShowConsoleMsg("Main: " .. (ret == 6 and tr1_name or tr2_name) .. "\n")
    reaper.ShowConsoleMsg("Target: " .. (ret == 6 and tr2_name or tr1_name) .. "\n\n")

    -- Version 1.0 Health Check: Project Params
    local proj_sr = tonumber(reaper.format_timestr_pos(1, "", 4):match(".-(%d+)$")) or 44100
    reaper.ShowConsoleMsg("HEALTH: Project Sample Rate ~" .. proj_sr .. "Hz\n")

    -- Track Accessors
    local main_aa = reaper.CreateTrackAudioAccessor(main_tr)
    local target_aa = reaper.CreateTrackAudioAccessor(target_tr)
    
    if not main_aa or not target_aa then
        reaper.ShowConsoleMsg("ERROR: Could not create Track Audio Accessors.\n")
        if main_aa then reaper.DestroyAudioAccessor(main_aa) end
        if target_aa then reaper.DestroyAudioAccessor(target_aa) end
        return
    end

    local aa_start = reaper.GetAudioAccessorStartTime(main_aa)
    local aa_end = reaper.GetAudioAccessorEndTime(main_aa)
    reaper.ShowConsoleMsg("HEALTH: Track Accessor range: " .. string.format("%.1fs to %.1fs", aa_start, aa_end) .. "\n\n")

    -- Helper: Read signature from Track Accessor
    local function get_signature_from_track(aa, item, item_name)
        local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        if item_len < 0.1 then return nil end

        local sr = 44100 -- Use standard SR for analysis (REAPER resamples)
        local channels = 1 -- Mono analysis is sufficient for signatures
        local sample_res = 0.01 -- 10ms intervals
        
        local raw_sig = {}
        local all_rms = {}
        local buf_samples = math.ceil(sample_res * sr)
        local buffer = reaper.new_array(buf_samples) -- Mono buffer
        
        local total_samples_read = 0
        local non_zero_chunks = 0

        for t = item_pos, item_pos + item_len - sample_res, sample_res do
            -- TrackAccessor reads in PROJECT time
            local r = reaper.GetAudioAccessorSamples(aa, sr, channels, t, buf_samples, buffer)
            
            local rms = 0
            if r > 0 then
                total_samples_read = total_samples_read + r
                local sum_sq = 0
                for j = 1, buf_samples do
                    local val = buffer[j]
                    sum_sq = sum_sq + (val * val)
                end
                rms = math.sqrt(sum_sq / buf_samples)
                if rms > 1e-7 then non_zero_chunks = non_zero_chunks + 1 end
            end
            table.insert(raw_sig, rms)
            table.insert(all_rms, rms)
        end

        if #all_rms == 0 or non_zero_chunks == 0 then 
            reaper.ShowConsoleMsg("DEBUG: '" .. item_name .. "' is SILENT (Read: " .. total_samples_read .. " samples at " .. string.format("%.2f", item_pos) .. "s)\n")
            return nil 
        end
        
        -- Apply Version 3.3 Dynamic Noise Logic
        local sorted_rms = {}
        for i=1, #all_rms do sorted_rms[i] = all_rms[i] end
        table.sort(sorted_rms)
        
        local floor_idx = math.max(1, math.floor(#sorted_rms * 0.1))
        local noise_floor = sorted_rms[floor_idx] or 0
        local max_rms = sorted_rms[#sorted_rms] or 0
        
        if max_rms <= noise_floor + 1e-6 then return nil end
        
        local range = max_rms - noise_floor
        local threshold = noise_floor + range * 0.03
        local start_idx, end_idx = 1, #raw_sig
        while start_idx < #raw_sig and raw_sig[start_idx] < threshold do start_idx = start_idx + 1 end
        while end_idx > start_idx and raw_sig[end_idx] < threshold do end_idx = end_idx - 1 end
        
        start_idx = math.max(1, start_idx - 2)
        end_idx = math.min(#raw_sig, end_idx + 2)
        
        if end_idx - start_idx < 5 then return nil end
        
        local sig = {}
        local trim_max = 0
        for i = start_idx, end_idx do
            local v = math.max(0, raw_sig[i] - noise_floor)
            table.insert(sig, v)
            if v > trim_max then trim_max = v end
        end
        
        if trim_max > 0 then
            for i = 1, #sig do sig[i] = sig[i] / trim_max end
        end
        
        return sig
    end

    local function compare_signatures(sig1, sig2)
        local n1, n2 = #sig1, #sig2
        local s, l = sig1, sig2
        if n1 > n2 then s, l = sig2, sig1 end
        local sn, ln = #s, #l
        if sn / ln < 0.2 then return 0 end

        local max_sim = 0
        local max_offset = ln - sn
        for offset = 0, max_offset do
            local dot, magS, magL = 0, 0, 0
            for i = 1, sn do
                local vS = s[i]
                local vL = l[offset + i]
                dot = dot + (vS * vL)
                magS = magS + (vS * vS)
                magL = magL + (vL * vL)
            end
            if magS > 1e-9 and magL > 1e-9 then
                local sim = dot / (math.sqrt(magS) * math.sqrt(magL))
                if sim > max_sim then max_sim = sim end
                if max_sim > 0.99 then break end 
            end
        end
        return max_sim
    end

    -- Process Main Track
    show_snackbar("Аналіз основного треку... (Track AA)", "info")
    local main_sigs = {}
    local main_count = reaper.CountTrackMediaItems(main_tr)
    for i = 0, main_count - 1 do
        local item = reaper.GetTrackMediaItem(main_tr, i)
        local _, name = reaper.GetSetMediaItemTakeInfo_String(reaper.GetActiveTake(item), "P_NAME", "", false)
        local sig = get_signature_from_track(main_aa, item, name)
        if sig then table.insert(main_sigs, {sig = sig, name = name, used = false}) end
    end
    reaper.ShowConsoleMsg("HEALTH: Loaded " .. #main_sigs .. " signatures from main track.\n\n")

    -- Process Target Track
    show_snackbar("Аналіз другорядного треку...", "info")
    local to_delete = {}
    local target_count = reaper.CountTrackMediaItems(target_tr)
    local global_max_sim = 0
    
    for i = 0, target_count - 1 do
        local item = reaper.GetTrackMediaItem(target_tr, i)
        local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local _, name = reaper.GetSetMediaItemTakeInfo_String(reaper.GetActiveTake(item), "P_NAME", "", false)
        local sig = get_signature_from_track(target_aa, item, name)
        
        if sig then
            local max_item_sim = 0
            local best_match_idx = -1
            for idx, m in ipairs(main_sigs) do
                if not m.used then
                    local sim = compare_signatures(sig, m.sig)
                    if sim > max_item_sim then 
                        max_item_sim = sim 
                        best_match_idx = idx
                    end
                    if sim > 0.96 then break end
                end
            end
            
            if max_item_sim > global_max_sim then global_max_sim = max_item_sim end
            
            local time_str = "[" .. format_timestamp(item_pos) .. "]"
            if max_item_sim > 0.96 then
                local m = main_sigs[best_match_idx]
                reaper.ShowConsoleMsg("MATCH " .. time_str .. ": '" .. name .. "' (" .. math.floor(max_item_sim*100) .. "%) matches '" .. m.name .. "'\n")
                m.used = true -- Consume the reference item (1-to-1 match)
                table.insert(to_delete, item)
            else
                local best_name = best_match_idx ~= -1 and main_sigs[best_match_idx].name or "N/A"
                reaper.ShowConsoleMsg("UNIQUE " .. time_str .. ": '" .. name .. "' (Best: " .. math.floor(max_item_sim*100) .. "% with '" .. best_name .. "')\n")
            end
        end
    end

    reaper.DestroyAudioAccessor(main_aa)
    reaper.DestroyAudioAccessor(target_aa)

    if #to_delete > 0 then
        push_undo("Видалення дублікатів (Waveform Match)")
        for _, item in ipairs(to_delete) do reaper.DeleteTrackMediaItem(target_tr, item) end
        reaper.UpdateArrange()
        show_snackbar("Видалено " .. #to_delete .. " дублікатів.", "success")
    else
        local pct = math.floor(global_max_sim * 100)
        show_snackbar("Дублікатів не знайдено. (Найкраща схожість: " .. pct .. "%)", "info")
    end
end

--- Upload current subtitles to analytics via Python script
function upload_subtitles_analytics()
    if not ass_lines or #ass_lines == 0 then return end
    
    -- Get current file path (full path, not just name)
    local filepath = UI_STATE.current_file_path
    if not filepath or filepath == "" then
        -- Fallback: if no path, skip upload
        return
    end
    
    -- Get project name
    local _, proj_path = reaper.EnumProjects(-1)
    local proj_name = "Project"
    if proj_path and proj_path ~= "" then
        proj_name = proj_path:match("([^/\\%s]+)%.[Rr][Pp][Pp]$") or "Project"
    end

    -- Build Python script path
    local source = debug.getinfo(1,'S').source
    local script_path = source:match([[^@?(.*[\\/])]]) or ""
    local full_script_path = script_path .. "stats/subass_extra_stats.py"
    
    -- Execute in background (fire-and-forget, completely silent)
    if reaper.GetOS():match("Win") then
        full_script_path = full_script_path:gsub("/", "\\")
        filepath = filepath:gsub("/", "\\")
        local py_exe = OTHER.rec_state.python and OTHER.rec_state.python.executable or "python"
        
        -- Use cmd /C start /B for background execution on Windows
        -- We quote everything to handle paths with spaces
        local cmd = string.format('cmd.exe /C start /B "" "%s" "%s" --filepath "%s" --project_name "%s"', 
                                   py_exe, full_script_path, filepath, proj_name)
        
        reaper.ExecProcess(cmd, 0)
    else
        -- macOS/Linux: simple background execution with nohup for complete detachment
        local cmd = string.format('nohup python3 "%s" --filepath "%s" --project_name "%s" > /dev/null 2>&1 &', 
                                  full_script_path, filepath, proj_name)
        os.execute(cmd)
    end
end


-- ═══════════════════════════════════════════════════════════════
-- DUBBERS MODULE - Methods
-- ═══════════════════════════════════════════════════════════════

--- Format seconds as M:SS
function DUBBERS.format_duration(s)
    if not s or s < 0 then return "0:00" end
    local m = math.floor(s / 60)
    local sec = math.floor(s % 60)
    return string.format("%d:%02d", m, sec)
end

--- Get statistics for a specific actor
function DUBBERS.get_actor_stats(actor_name)
    local stats = { replicas = 0, words = 0, time = 0 }
    if not ass_lines then return stats end
    
    for _, line in ipairs(ass_lines) do
        if line.actor == actor_name then
            stats.replicas = stats.replicas + 1
            stats.time = stats.time + (line.t2 - line.t1)
            
            -- Word count logic from draw_file
            local clean = (line.text or ""):gsub("{.-}", ""):gsub("\\[Nnh]", " ")
            local _, count = clean:gsub("%S+", "")
            stats.words = stats.words + count
        end
    end
    return stats
end

--- Get statistics for a dubber (sum of assigned actors)
function DUBBERS.get_dubber_stats(dubber_name)
    local total = { replicas = 0, words = 0, time = 0, actors_count = 0 }
    local assigned = DUBBERS.data.assignments[dubber_name]
    if not assigned then return total end
    
    for act_name, is_on in pairs(assigned) do
        if is_on then
            total.actors_count = total.actors_count + 1
            local s = DUBBERS.get_actor_stats(act_name)
            total.replicas = total.replicas + s.replicas
            total.words = total.words + s.words
            total.time = total.time + s.time
        end
    end
    return total
end

--- Load dubber data from project extented state
function DUBBERS.load()
    local retval, json_str = reaper.GetProjExtState(0, "Subass_Notes", "dubber_data")
    if retval and json_str ~= "" then
        local success, result = pcall(function() return STATS.json_decode(json_str) end)
        if success and type(result) == "table" then
            DUBBERS.data = result
            return
        end
    end
    -- Default/Empty state if not found
    DUBBERS.data = {
        names = {},
        assignments = {} -- dubber_name -> { actor1 = true, ... }
    }
end

--- Save dubber data to project extented state
function DUBBERS.save()
    local json_str = STATS.json_encode(DUBBERS.data)
    reaper.SetProjExtState(0, "Subass_Notes", "dubber_data", json_str)
end

--- Copy distribution result to clipboard
--- @param extended boolean if true, adds per-actor stats and totals
function DUBBERS.copy_to_clipboard(extended)
    local lines = {}
    for _, name in ipairs(DUBBERS.data.names) do
        local assigned = DUBBERS.data.assignments[name] or {}
        local actors = {}
        for act, is_assigned in pairs(assigned) do
            if is_assigned then table.insert(actors, act) end
        end
        table.sort(actors)
        
        if not extended then
            -- Short mode
            if #actors > 0 then
                table.insert(lines, name .. ": " .. table.concat(actors, ", "))
            else
                table.insert(lines, name .. ": (порожньо)")
            end
        else
            -- Extended mode
            local dubber_block = { "【 " .. name .. " 】" }
            if #actors > 0 then
                for _, act in ipairs(actors) do
                    local s = DUBBERS.get_actor_stats(act)
                    table.insert(dubber_block, string.format("  • %s: %d репл. | %d сл. | %s", act, s.replicas, s.words, DUBBERS.format_duration(s.time)))
                end
                
                -- Add total for dubber
                local ts = DUBBERS.get_dubber_stats(name)
                table.insert(dubber_block, string.format("  Всього: %d акт. | %d репл. | %d сл. | %s", ts.actors_count, ts.replicas, ts.words, DUBBERS.format_duration(ts.time)))
            else
                table.insert(dubber_block, "  (немає призначених акторів)")
            end
            table.insert(lines, table.concat(dubber_block, "\n"))
        end
    end
    
    if #lines == 0 then
        show_snackbar("Список даберів порожній", "error")
        return
    end
    
    local out = table.concat(lines, "\n\n")
    set_clipboard(out)
    show_snackbar("Розподіл скопійовано в буфер", "success")
end

--- Export distibution as ASS with embedded metadata
--- @param deadline_str string|nil Optional deadline prefix like "[31.01.26]"
function DUBBERS.export_as_ass(deadline_str)
    if not ass_lines then 
        show_snackbar("Немає реплік для експорту", "error")
        return 
    end

    -- Construct filename
    local _, proj_path = reaper.EnumProjects(-1)
    local proj_name = "Project"
    if proj_path and proj_path ~= "" then
        proj_name = proj_path:match("([^/\\%s]+)%.[Rr][Pp][Pp]$") or proj_name
    end
    
    local default_filename = proj_name .. "_Distribution.ass"
    if deadline_str then
        default_filename = deadline_str .. " " .. default_filename
    end

    -- Save Dialog
    local retval, filename = reaper.JS_Dialog_BrowseForSaveFile("Експорт розподілу в ASS", "", default_filename, "ASS files (.ass)\0*.ass\0All Files (*.*)\0*.*\0")
    
    if retval == 1 and filename ~= "" then
        if not filename:match("%.ass$") then filename = filename .. ".ass" end
        
        local file = io.open(filename, "w")
        if not file then
            reaper.ShowMessageBox("Не вдалося створити файл: " .. filename, "Помилка", 0)
            return
        end

        local fmt_time = function(secs)
            local h = math.floor(secs / 3600)
            local m = math.floor((secs % 3600) / 60)
            local s = math.floor(secs % 60)
            local ms = math.floor((secs % 1) * 100)
            return string.format("%d:%02d:%02d.%02d", h, m, s, ms)
        end

        file:write("[Script Info]\n")
        
        -- Filter assignments to only include dubbers with at least one assigned actor
        -- AND only include actors that exist in the current project (ass_actors)
        local filtered_assignments = {}
        for dubber_name, actors in pairs(DUBBERS.data.assignments) do
            local filtered_actors = {}
            for actor, is_assigned in pairs(actors) do
                -- Only include if assigned AND exists in current project
                if is_assigned and ass_actors[actor] ~= nil then
                    filtered_actors[actor] = true
                end
            end
            -- Only add dubber if they have at least one valid actor
            if next(filtered_actors) then
                filtered_assignments[dubber_name] = filtered_actors
            end
        end
        
        local json_meta = STATS.json_encode(filtered_assignments):gsub("\r", ""):gsub("\n", ""):gsub("%s%s+", " ")
        file:write("Title: Subass Dubber Distribution\n")
        file:write("ScriptType: v4.00+\n")
        file:write("PlayResX: 1920\n")
        file:write("PlayResY: 1080\n")
        file:write("ScaledBorderAndShadow: yes\n\n")
        
        file:write("[V4+ Styles]\n")
        file:write("Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding\n")
        file:write("Style: Default,Arial,20,&H00FFFFFF,&H000000FF,&H00000000,&H00000000,0,0,0,0,100,100,0,0,1,2,2,2,10,10,10,1\n\n")
        
        file:write("[Events]\n")
        file:write("Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text\n")

        -- Metadata Dialogue line (for persistence across external editors)
        file:write(string.format("Dialogue: 0,0:00:00.00,0:00:00.00,Default,SubassMetadata,0,0,0,,%s\n", json_meta))

        local out_lines = {}
        for _, l in ipairs(ass_lines) do
            table.insert(out_lines, l)
        end
        table.sort(out_lines, function(a, b) return a.t1 < b.t1 end)

        local export_count = 0
        for _, l in ipairs(out_lines) do
            local actor = l.actor or "Unknown"
            if actor == "" then actor = "Unknown" end
            
            local text = l.text:gsub("\n", "\\N")
            file:write(string.format("Dialogue: 0,%s,%s,Default,%s,0,0,0,,%s\n", fmt_time(l.t1), fmt_time(l.t2), actor, text))
            export_count = export_count + 1
        end
        
        file:close()
        show_snackbar("Експортовано " .. export_count .. " реплік з метаданими", "success")
    end
end

--- Draw Dubber Distribution Dashboard
--- @param input_queue table Queue of character/keyboard inputs
--- Draw Dubber Distribution Dashboard
--- @param input_queue table Queue of character/keyboard inputs
function DUBBERS.draw_dashboard(input_queue)
    local pad = S(20)
    UI_STATE.mouse_handled = true -- Block interaction with background
    
    -- Background overlay
    set_color(UI.C_BG, 0.98)
    gfx.rect(0, 0, gfx.w, gfx.h, 1)
    
    -- --- DIMENSIONS & MEASUREMENTS ---
    gfx.setfont(F.title)
    local title = "Розподіл по даберам"
    local tw, th = gfx.measurestr(title)
    local header_h = pad + th + S(15)
    
    local dubber_item_h = S(50)
    local actor_item_h = S(55)
    local section_gap = S(30)
    local grid_w = gfx.w - pad*2
    local actor_col_w = S(220)
    local cols = math.floor(grid_w / actor_col_w)
    if cols < 1 then cols = 1 end
    
    -- --- DATA PREP ---
    local sorted_actors = {}
    for act in pairs(ass_actors) do table.insert(sorted_actors, act) end
    table.sort(sorted_actors)
    
    local actor_to_dubbers = {}
    for _, d_name in ipairs(DUBBERS.data.names) do
        local assigned = DUBBERS.data.assignments[d_name] or {}
        for act, is_on in pairs(assigned) do
            if is_on then
                if not actor_to_dubbers[act] then actor_to_dubbers[act] = {} end
                table.insert(actor_to_dubbers[act], d_name)
            end
        end
    end
    
    -- Content Height Calculation
    local d_cols = 3
    local d_col_w = grid_w / d_cols
    local d_rows = math.ceil(#DUBBERS.data.names / d_cols)
    local dubbers_h = (d_rows * dubber_item_h) + S(75) -- + Title & Add button room
    
    local actors_start_relative = dubbers_h + section_gap
    local rows = math.ceil(#sorted_actors / cols)
    local actors_h = rows * actor_item_h
    local total_content_h = actors_start_relative + actors_h + pad + S(40) -- EXTRA PADDING AT BOTTOM
    
    local view_h = gfx.h - header_h
    local max_scroll = math.max(0, total_content_h - view_h)
    
    -- SCROLL CONTROL
    if gfx.mouse_wheel ~= 0 then
        DUBBERS.target_scroll_y = math.max(0, math.min(DUBBERS.target_scroll_y - (gfx.mouse_wheel * 0.25), max_scroll))
        gfx.mouse_wheel = 0
    end
    local diff = DUBBERS.target_scroll_y - DUBBERS.scroll_y
    if math.abs(diff) > 0.5 then DUBBERS.scroll_y = DUBBERS.scroll_y + (diff * 0.8) else DUBBERS.scroll_y = DUBBERS.target_scroll_y end
    
    -- --- SCROLLABLE CONTENT ---
    local function get_y(rel_y) return header_h + rel_y - math.floor(DUBBERS.scroll_y) end
    
    -- 1. Dubbers Section
    local dy = get_y(0)
    if dy + S(25) > header_h then
        set_color(UI.C_TXT, 0.6)
        gfx.setfont(F.bld)
        gfx.x, gfx.y = pad, dy
        gfx.drawstr("ДАБЕРИ")
    end
    
    dy = dy + S(25)
    
    -- Add Dubber Button
    local add_w = S(120)
    if dy + S(25) > header_h and dy < gfx.h then
        if btn(pad, dy, add_w, S(25), "+ Додати дабера", UI.C_BTN, UI.C_TXT) then
            local ok, name = reaper.GetUserInputs("Новий дабер", 1, "Ім'я дабера:", "")
            if ok and name ~= "" then
                table.insert(DUBBERS.data.names, name)
                DUBBERS.save()
            end
        end
    end
    
    dy = dy + S(35)
    
    for i, name in ipairs(DUBBERS.data.names) do
        local col = (i-1) % d_cols
        local row = math.floor((i-1) / d_cols)
        local dx = pad + col * d_col_w
        local item_y = dy + row * dubber_item_h
        
        local is_active = (i == DUBBERS.active_dubber_idx)
        
        if item_y + dubber_item_h > header_h and item_y < gfx.h then
            local bg = is_active and UI.C_ACCENT_N or UI.C_ROW
            local txt_c = is_active and UI.C_WHITE or UI.C_TXT
            
            -- Draw Row Background
            set_color(bg, is_active and 0.9 or 0.3)
            gfx.rect(dx, item_y, d_col_w - S(5), dubber_item_h - S(4), 1)
            
            -- Selection Logic
            if is_mouse_clicked() and gfx.mouse_x >= dx and gfx.mouse_x <= dx + d_col_w and
               gfx.mouse_y >= item_y and gfx.mouse_y <= item_y + dubber_item_h and gfx.mouse_y > header_h then
                DUBBERS.active_dubber_idx = i
            end
            
            -- ПКМ: Rename/Delete
            if is_mouse_clicked(2) and gfx.mouse_x >= dx and gfx.mouse_x <= dx + d_col_w and
               gfx.mouse_y >= item_y and gfx.mouse_y <= item_y + dubber_item_h and gfx.mouse_y > header_h then
                gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
                local ret = gfx.showmenu("Вибрати цього дабера||Перейменувати|Видалити")
                if ret == 1 then
                    -- Select dubber logic: Filter main list by this dubber's actors
                    local assigned_actors = DUBBERS.data.assignments[name] or {}
                    
                    -- Reset all filters
                    for k in pairs(ass_actors) do ass_actors[k] = false end
                    if ass_lines then
                        for _, l in ipairs(ass_lines) do l.enabled = false end
                    end
                    
                    -- Apply assignments from this dubber
                    local found_any = false
                    for act, is_on in pairs(assigned_actors) do
                        if is_on and ass_actors[act] ~= nil then
                            ass_actors[act] = true
                            found_any = true
                        end
                    end
                    
                    -- Sync lines enabled state
                    if ass_lines then
                        for _, l in ipairs(ass_lines) do
                            if assigned_actors[l.actor] then
                                l.enabled = true
                            end
                        end
                    end
                    
                    rebuild_regions()
                    if found_any then
                        show_snackbar("Вибрано акторів дабера: " .. name, "success")
                    else
                        show_snackbar("У дабера '" .. name .. "' немає призначених акторів у цьому проекті", "warning")
                    end
                    
                elseif ret == 2 then
                    local ok, n_name = reaper.GetUserInputs("Rename", 1, "New name:", name)
                    if ok and n_name ~= "" then
                        DUBBERS.data.assignments[n_name] = DUBBERS.data.assignments[name]
                        DUBBERS.data.assignments[name] = nil
                        DUBBERS.data.names[i] = n_name
                        DUBBERS.save()
                    end
                elseif ret == 3 then
                    if reaper.MB("Видалити '"..name.."'?", "Confirm", 4) == 6 then
                        table.remove(DUBBERS.data.names, i); DUBBERS.data.assignments[name] = nil
                        DUBBERS.active_dubber_idx = math.max(1, math.min(DUBBERS.active_dubber_idx, #DUBBERS.data.names))
                        DUBBERS.save()
                    end
                end
            end
            
            -- Labels
            gfx.setfont(F.bld)
            set_color(txt_c)
            gfx.x, gfx.y = dx + S(15), item_y + S(8)
            gfx.drawstr(fit_text_width(name, d_col_w - S(25)))
            
            local s = DUBBERS.get_dubber_stats(name)
            local meta = string.format("%d репл. | %d сл. | %s | %d акт.", s.replicas, s.words, DUBBERS.format_duration(s.time), s.actors_count)
            gfx.setfont(F.tip)
            set_color(txt_c, 0.7)
            gfx.x, gfx.y = dx + S(15), item_y + S(28)
            gfx.drawstr(fit_text_width(meta, d_col_w - S(25)))
        end
    end
    
    -- 2. Actors Section
    local ay = get_y(actors_start_relative)
    local active_dubber = DUBBERS.data.names[DUBBERS.active_dubber_idx]
    
    if ay + S(40) > header_h and ay < gfx.h then
        set_color(UI.C_TXT, 0.6)
        gfx.setfont(F.bld)
        gfx.x, gfx.y = pad, ay
        local a_title = "АКТОРИ"
        if active_dubber then a_title = a_title .. " (Призначення для: " .. active_dubber .. ")" end
        gfx.drawstr(a_title)
    end
    
    ay = ay + S(30)
    
    for i, act in ipairs(sorted_actors) do
        local col = (i-1) % cols
        local row = math.floor((i-1) / cols)
        local ax = pad + col * actor_col_w
        local cur_ay = ay + row * actor_item_h
        
        if cur_ay + actor_item_h > header_h and cur_ay < gfx.h then
            local is_assigned = active_dubber and DUBBERS.data.assignments[active_dubber] and DUBBERS.data.assignments[active_dubber][act]
            local dbs = actor_to_dubbers[act]
            local has_any_assignment = (dbs and #dbs > 0)
            local fade = has_any_assignment and 1.0 or 0.4 -- Pale if no dubber assigned at all
            
            -- Card BG
            if is_assigned then
                set_color(UI.C_GREEN, 0.15) -- User preferred value
            else
                set_color(UI.C_ROW, 0.2 * fade)
            end
            gfx.rect(ax, cur_ay, actor_col_w - S(5), actor_item_h - S(5), 1)
            
            -- Light Border for assigned actors
            if has_any_assignment then
                set_color(UI.C_GREEN, 0.15)
                gfx.rect(ax, cur_ay, actor_col_w - S(5), actor_item_h - S(5), 0)
            end
            
            -- Checkbox / Assignment
            local a_col = get_actor_color(act)
            local r, g, b = reaper.ColorFromNative(a_col & 0xFFFFFF)
            
            if is_assigned then
                set_color({r/255, g/255, b/255})
                gfx.rect(ax + S(8), cur_ay + S(11), S(18), S(18), 1)
                set_color(UI.C_BLACK)
                gfx.line(ax + S(11), cur_ay + S(20), ax + S(15), cur_ay + S(25))
                gfx.line(ax + S(15), cur_ay + S(25), ax + S(22), cur_ay + S(14))
            else
                set_color(UI.C_BTN, fade)
                gfx.rect(ax + S(8), cur_ay + S(11), S(18), S(18), 0)
                set_color({r/255, g/255, b/255}, 0.3 * fade)
                gfx.rect(ax + S(13), cur_ay + S(16), S(8), S(8), 1)
            end
            
            -- Actor Name + Dubbers
            local label = act
            if has_any_assignment then label = label .. " [" .. table.concat(dbs, ", ") .. "]" end
            
            set_color(UI.C_TXT, fade)
            gfx.setfont(F.bld)
            gfx.x, gfx.y = ax + S(32), cur_ay + S(8)
            gfx.drawstr(fit_text_width(label, actor_col_w - S(40)))
            
            local s = DUBBERS.get_actor_stats(act)
            local meta = string.format("%d репл. | %d сл. | %s", s.replicas, s.words, DUBBERS.format_duration(s.time))
            gfx.setfont(F.tip)
            set_color(UI.C_TXT, 0.6 * fade)
            gfx.x, gfx.y = ax + S(32), cur_ay + S(28)
            gfx.drawstr(fit_text_width(meta, actor_col_w - S(40)))
            
            -- Click logic
            if is_mouse_clicked() and gfx.mouse_x >= ax and gfx.mouse_x <= ax + actor_col_w and
               gfx.mouse_y >= cur_ay and gfx.mouse_y <= cur_ay + actor_item_h and gfx.mouse_y > header_h then
                if active_dubber then
                    if not DUBBERS.data.assignments[active_dubber] then DUBBERS.data.assignments[active_dubber] = {} end
                    DUBBERS.data.assignments[active_dubber][act] = not is_assigned
                    DUBBERS.save()
                else
                    show_snackbar("Оберіть дабера зверху", "info")
                end
            end
        end
    end
    
    -- --- FIXED HEADER OVERLAY (Drawn last to stay on top) ---
    set_color(UI.C_BG, 1.0)
    gfx.rect(0, 0, gfx.w, header_h, 1)
    
    local close_sz = S(24)
    local copy_w = S(100)
    local export_w = S(170)
    local right_edge = gfx.w - pad - close_sz - S(10)
    
    set_color(UI.C_TXT)
    gfx.setfont(F.title)
    gfx.x, gfx.y = pad, pad
    local reserved_w = close_sz + copy_w + export_w + S(50)
    gfx.drawstr(fit_text_width(title, gfx.w - pad - reserved_w))
    
    local function close_dash() DUBBERS.show_dashboard = false end
    if btn(gfx.w - pad - close_sz, pad, close_sz, close_sz, "X", UI.C_BTN, UI.C_TXT) then close_dash() end
    
    if btn(right_edge - copy_w, pad, copy_w, close_sz, "Копіювати", UI.C_TAB_INA, UI.C_TXT) then
        gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
        local ret = gfx.showmenu("Короткий (тільки імена)|Розширений (з аналітикою)")
        if ret == 1 then
            DUBBERS.copy_to_clipboard(false)
        elseif ret == 2 then
            DUBBERS.copy_to_clipboard(true)
        end
    end

    if btn(right_edge - copy_w - S(10) - export_w, pad, export_w, close_sz, "Експортувати як ASS", UI.C_TAB_INA, UI.C_TXT) then
        gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
        local ret = gfx.showmenu("Просто експорт||Експорт з дедлайном")
        if ret == 1 then
            DUBBERS.export_as_ass()
        elseif ret == 2 then
            DEADLINE.open_picker(nil, function(ts)
                if not ts then return end
                local dt = os.date("*t", ts)
                local d_str = string.format("[%02d.%02d.%02d]", dt.day, dt.month, dt.year % 100)
                DUBBERS.export_as_ass(d_str)
            end)
        end
    end
    
    -- ESC key to close
    if input_queue then
        for _, c in ipairs(input_queue) do if c == 27 then close_dash() break end end
    end
end

-- =============================================================================
-- FILE IMPORT (SRT/ASS)
-- =============================================================================

--- Import SRT subtitle file
local function import_srt(file_path, dont_rebuild, forced_actor)
    local file = file_path
    if not file then
        local retval
        retval, file = reaper.GetUserFileNameForRead("", "Import SRT", "srt")
        if not retval then return end
    end
    local f = io.open(file, "r")
    if not f then 
        reaper.MB("Не вдалося відкрити файл для імпорту:\n" .. tostring(file), "Помилка імпорту", 0)
        return 
    end
    UI_STATE.current_file_name = file:match("([^/\\]+)$")
    UI_STATE.current_file_path = file
    
    local content = fix_encoding(f:read("*all"))
    f:close()
    content = content:gsub("\r\n", "\n")
    -- Ensure trailing double newline for matching last block
    if not content:match("\n\n$") then
        content = content .. "\n\n"
    end
    
    -- Derive Actor Name from Filename or use forced_actor
    local actor_name = forced_actor or UI_STATE.current_file_name:gsub("%.srt$", ""):gsub("%.SRT$", "")
    
    -- Check for deadline in filename
    local dl = DEADLINE.parse_from_name(UI_STATE.current_file_name)
    if dl then DEADLINE.set(dl) end
    
    -- Ensure State Init
    if not ass_lines then ass_lines = {} end
    if not ass_actors then ass_actors = {} end
    
    if not dont_rebuild then
        push_undo("Імпорт SRT")
    end
    
    UI_STATE.ass_file_loaded = true -- Enable Actor view

    -- Clear UI state
    table_filter_state.text = ""
    table_selection = {}
    last_selected_row = nil
    
    -- We will rebuild ALL regions at the end, so we don't need to add markers manually here.
    -- Just populate ass_lines.
    local line_idx_counter = get_next_line_index()
    
    -- Robust SRT parsing: handle comma/dot, optional spaces, and ensure last block is captured
    local duplicates_skipped = 0
    for s_start, s_end, text in content:gmatch("(%d+:%d+:%d+[,.]%d+)%s*%-%->%s*(%d+:%d+:%d+[,.]%d+)%s*\n(.-)\n%s*\n") do
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
                
                -- Push segments with duplicate check
                for _, seg in ipairs(segments) do
                    if not is_duplicate_replica(seg.actor, t1, t2, seg.text) then
                        -- Lazy register actor
                        ass_actors[seg.actor] = true
                        
                        table.insert(ass_lines, {
                            t1 = t1,
                            t2 = t2,
                            text = seg.text,
                            actor = seg.actor,
                            enabled = true,
                            index = line_idx_counter
                        })
                        line_idx_counter = line_idx_counter + 1
                    else
                        duplicates_skipped = duplicates_skipped + 1
                    end
                end
            end
        end
        
        -- Fallback: If not processed by auto-split, check split_multiline
        if not lines_processed and cfg.split_multiline then
            local lines_list = {}
            for l in (text.."\n"):gmatch("(.-)\n") do
                l = l:gsub("\r", ""):match("^%s*(.-)%s*$")
                if l ~= "" then table.insert(lines_list, l) end
            end
             
            if #lines_list > 1 then
                lines_processed = true
                local dur = t2 - t1
                local step = dur / #lines_list
                for i, l in ipairs(lines_list) do
                    if not is_duplicate_replica(actor_name, t1 + (i-1) * step, t1 + i * step, l) then
                        ass_actors[actor_name] = true
                        table.insert(ass_lines, {
                            t1 = t1 + (i-1) * step,
                            t2 = t1 + i * step,
                            text = l,
                            actor = actor_name,
                            enabled = true,
                            index = line_idx_counter
                        })
                        line_idx_counter = line_idx_counter + 1
                    else
                        duplicates_skipped = duplicates_skipped + 1
                    end
                end
            end
        end
        
        if not lines_processed then
            local clean_text = text:gsub("\r", "")
            if not is_duplicate_replica(actor_name, t1, t2, clean_text) then
                ass_actors[actor_name] = true
                table.insert(ass_lines, {
                    t1 = t1,
                    t2 = t2,
                    text = clean_text,
                    actor = actor_name,
                    enabled = true,
                    index = line_idx_counter
                })
                line_idx_counter = line_idx_counter + 1
            else
                duplicates_skipped = duplicates_skipped + 1
            end
        end
    end
    
    if duplicates_skipped > 0 and not dont_rebuild then
        show_snackbar("Пропущено дублікатів: " .. duplicates_skipped, "info")
    end
    
    if not dont_rebuild then
        rebuild_regions() -- This handles clearing old regions and re-adding all (including new ones)
    end
    
    -- Auto-upload to Firestore
    upload_subtitles_analytics()
    
    return duplicates_skipped
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
local function import_vtt(file_path, dont_rebuild)
    local file = file_path
    if not file then
        local retval
        retval, file = reaper.GetUserFileNameForRead("", "Import VTT", "vtt")
        if not retval then return end
    end
    local f = io.open(file, "r")
    if not f then return end
    UI_STATE.current_file_name = file:match("([^/\\]+)$")
    UI_STATE.current_file_path = file
    
    -- Check for deadline in filename
    local dl = DEADLINE.parse_from_name(UI_STATE.current_file_name)
    if dl then DEADLINE.set(dl) end
    
    local content = fix_encoding(f:read("*all"))
    f:close()
    content = content:gsub("\r\n", "\n")
    
    -- Derive Actor Name from Filename
    local actor_name = UI_STATE.current_file_name:gsub("%.vtt$", ""):gsub("%.VTT$", "")
    
    -- Ensure State Init
    if not ass_lines then ass_lines = {} end
    if not ass_actors then ass_actors = {} end
    
    if not dont_rebuild then
        push_undo("Імпорт VTT")
    end
    
    UI_STATE.ass_file_loaded = true

    -- Clear UI state
    table_filter_state.text = ""
    table_selection = {}
    last_selected_row = nil
    
    -- Register Actor
    ass_actors[actor_name] = true
    
    local line_idx_counter = get_next_line_index()
    
    local duplicates_skipped = 0
    -- VTT format: timestamp --> timestamp followed by text
    -- Skip WEBVTT header and optional metadata
    for s_start, s_end, text in content:gmatch("(%d[%d:%.]+) %-%-> (%d[%d:%.]+)[^\n]*\n(.-)\n\n") do
        local t1 = parse_vtt_timestamp(s_start)
        local t2 = parse_vtt_timestamp(s_end)
        
        -- Remove VTT tags like <v Name> or <c.classname>
        text = text:gsub("<[^>]+>", "")
        
        if not is_duplicate_replica(actor_name, t1, t2, text) then
            table.insert(ass_lines, {
                t1 = t1,
                t2 = t2,
                text = text,
                actor = actor_name,
                enabled = true,
                index = line_idx_counter
            })
            line_idx_counter = line_idx_counter + 1
        else
            duplicates_skipped = duplicates_skipped + 1
        end
    end
    
    if duplicates_skipped > 0 and not dont_rebuild then
        show_snackbar("Пропущено дублікатів: " .. duplicates_skipped, "info")
    end
    
    if not dont_rebuild then
        rebuild_regions()
    end
    
    -- Auto-upload to Firestore
    upload_subtitles_analytics()
    
    return duplicates_skipped
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

--- Export selected subtitles to SRT format
local function export_as_srt()
    if not reaper.JS_Dialog_BrowseForSaveFile then
        local msg = "Для роботи експорту необхідне розширення JS_ReaScriptAPI.\n\n"
        if not has_reapack then
            msg = msg .. "1. Встановіть ReaPack (reapack.com)\n2. Перезавантажте REAPER\n3. Встановіть JS_ReaScriptAPI через ReaPack"
        else
            msg = msg .. "Будь ласка, встановіть 'JS_ReaScriptAPI' через Extensions -> ReaPack -> Browse packages. (потім перезавантажте REAPER)"
        end
        reaper.MB(msg, "Відсутні компоненти", 0)
        return
    end

    -- Filter enabled lines
    local out_lines = {}
    local selected_actors = {}
    
    for _, l in ipairs(ass_lines) do
        if l.enabled then
            table.insert(out_lines, l)
            if l.actor and l.actor ~= "" then
                selected_actors[l.actor] = true
            end
        end
    end

    table.sort(out_lines, function(a, b) return a.t1 < b.t1 end)

    if #out_lines == 0 then
        show_snackbar("Немає активних реплік для експорту", "info")
        return
    end

    -- Construct filename
    local _, proj_path = reaper.EnumProjects(-1)
    local proj_name = "Project"
    if proj_path and proj_path ~= "" then
        proj_name = proj_path:match("([^/\\%s]+)%.[Rr][Pp][Pp]$") or proj_name
    end

    local actors_list = {}
    for act in pairs(selected_actors) do
        table.insert(actors_list, act)
    end
    table.sort(actors_list)
    
    local suffix = ""
    if #actors_list > 0 then
        -- Limit to first 100 actors to avoid super long filenames
        local limit = 100
        local parts = {}
        for i = 1, math.min(#actors_list, limit) do
            table.insert(parts, actors_list[i])
        end
        suffix = "_" .. table.concat(parts, "_")
        if #actors_list > limit then
            suffix = suffix .. "_etc"
        end
    else
        suffix = "_All"
    end
    
    -- Clean filename chars (Sanitize illegal chars, allow unicode)
    suffix = suffix:gsub("[<>:\"/\\|?*]", "_")
    
    local default_filename = proj_name .. suffix .. ".srt"

    -- Save Dialog
    local retval, filename = reaper.JS_Dialog_BrowseForSaveFile("Експорт в SRT", "", default_filename, "SRT files (.srt)\0*.srt\0All Files (*.*)\0*.*\0")
    
    if retval == 1 and filename ~= "" then
        if not filename:match("%.srt$") then
            filename = filename .. ".srt"
        end
        
        local file = io.open(filename, "w")
        if not file then
            reaper.ShowMessageBox("Не вдалося створити файл: " .. filename, "Помилка", 0)
            return
        end

        local fmt_time = function(secs)
            local h = math.floor(secs / 3600)
            local m = math.floor((secs % 3600) / 60)
            local s = math.floor(secs % 60)
            local ms = math.floor((secs % 1) * 1000)
            return string.format("%02d:%02d:%02d,%03d", h, m, s, ms)
        end

        for i, l in ipairs(out_lines) do
            -- SRT Index
            file:write(tostring(i) .. "\n")
            
            -- Timecode
            file:write(fmt_time(l.t1) .. " --> " .. fmt_time(l.t2) .. "\n")
            
            -- Text with optional Actor name
            local text = l.text
            if cfg.auto_srt_split == "():" then
                if l.actor and l.actor ~= "" then
                    text = "(" .. l.actor .. "): " .. text
                end
            elseif cfg.auto_srt_split == "[]:" then
                if l.actor and l.actor ~= "" then
                    text = "[" .. l.actor .. "]: " .. text
                end
            end
            
            file:write(text .. "\n\n")
        end
        
        file:close()
        show_snackbar("Експортовано " .. #out_lines .. " реплік", "success")
    end
end

local function export_as_ass()
    if not reaper.JS_Dialog_BrowseForSaveFile then
        local msg = "Для роботи експорту необхідне розширення JS_ReaScriptAPI.\n\n"
        if not has_reapack then
            msg = msg .. "1. Встановіть ReaPack (reapack.com)\n2. Перезавантажте REAPER\n3. Встановіть JS_ReaScriptAPI через ReaPack"
        else
            msg = msg .. "Будь ласка, встановіть 'JS_ReaScriptAPI' через Extensions -> ReaPack -> Browse packages. (потім перезавантажте REAPER)"
        end
        reaper.MB(msg, "Відсутні компоненти", 0)
        return
    end

    -- Filter enabled lines
    local out_lines = {}
    local selected_actors = {}
    
    for _, l in ipairs(ass_lines) do
        if l.enabled then
            table.insert(out_lines, l)
            if l.actor and l.actor ~= "" then
                selected_actors[l.actor] = true
            end
        end
    end

    table.sort(out_lines, function(a, b) return a.t1 < b.t1 end)

    if #out_lines == 0 then
        show_snackbar("Немає активних реплік для експорту", "info")
        return
    end

    -- Construct filename
    local _, proj_path = reaper.EnumProjects(-1)
    local proj_name = "Project"
    if proj_path and proj_path ~= "" then
        proj_name = proj_path:match("([^/\\%s]+)%.[Rr][Pp][Pp]$") or proj_name
    end

    local actors_list = {}
    for act in pairs(selected_actors) do
        table.insert(actors_list, act)
    end
    table.sort(actors_list)
    
    local suffix = ""
    if #actors_list > 0 then
        local limit = 100
        local parts = {}
        for i = 1, math.min(#actors_list, limit) do
            table.insert(parts, actors_list[i])
        end
        suffix = "_" .. table.concat(parts, "_")
        if #actors_list > limit then
            suffix = suffix .. "_etc"
        end
    else
        suffix = "_All"
    end
    
    -- Clean filename chars
    suffix = suffix:gsub("[<>:\"/\\|?*]", "_")
    
    local default_filename = proj_name .. suffix .. ".ass"

    -- Save Dialog
    local retval, filename = reaper.JS_Dialog_BrowseForSaveFile("Експорт в ASS", "", default_filename, "ASS files (.ass)\0*.ass\0All Files (*.*)\0*.*\0")
    
    if retval == 1 and filename ~= "" then
        if not filename:match("%.ass$") then
            filename = filename .. ".ass"
        end
        
        local file = io.open(filename, "w")
        if not file then
            reaper.ShowMessageBox("Не вдалося створити файл: " .. filename, "Помилка", 0)
            return
        end

        local fmt_time = function(secs)
            local h = math.floor(secs / 3600)
            local m = math.floor((secs % 3600) / 60)
            local s = math.floor(secs % 60)
            local ms = math.floor((secs % 1) * 100) -- ASS uses 2 digits for ms (centiseconds)
            return string.format("%d:%02d:%02d.%02d", h, m, s, ms)
        end

        file:write("[Script Info]\n")
        file:write("Title: Subass Export\n")
        file:write("ScriptType: v4.00+\n")
        file:write("PlayResX: 1920\n")
        file:write("PlayResY: 1080\n")
        file:write("ScaledBorderAndShadow: yes\n\n")
        
        file:write("[V4+ Styles]\n")
        file:write("Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding\n")
        file:write("Style: Default,Arial,20,&H00FFFFFF,&H000000FF,&H00000000,&H00000000,0,0,0,0,100,100,0,0,1,2,2,2,10,10,10,1\n\n")
        
        file:write("[Events]\n")
        file:write("Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text\n")

        for _, l in ipairs(out_lines) do
            local actor = l.actor or "Default"
            -- Convert newlines to ASS \N
            local text = l.text:gsub("\n", "\\N")
            file:write(string.format("Dialogue: 0,%s,%s,Default,%s,0,0,0,,%s\n", fmt_time(l.t1), fmt_time(l.t2), actor, text))
        end
        
        file:close()
        show_snackbar("Експортовано " .. #out_lines .. " реплік в ASS", "success")
    end
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
        "• ⭐ Ім'я (групування за актором)\n" ..
        "• Багаторядковий текст",
        "Імпорт правок",
        1  -- OK/Cancel
    )

    if response ~= 1 then return end
    
    -- Read from clipboard
    local input = fix_encoding(get_clipboard())
    if not input or input == "" then
        show_snackbar("Буфер обміну порожній", "error")
        return
    end
    
    -- Parse input
    local raw_notes = {}
    local failed_lines = {} -- Track lines that couldn't be parsed
    local current_actor = nil -- Track active actor (single, persistent)
    
    for line in input:gmatch("[^\r\n]+") do
        line = line:match("^%s*(.-)%s*$") -- Trim
        if line ~= "" then
            local matched = false
            
            -- Check for actor line: ⭐ Name
            local actor_name = line:match("^⭐(.*)$")
            if actor_name then
                -- Remove variation selector (U+FE0F = \239\184\143) and trim spaces
                actor_name = actor_name:gsub("\239\184\143", ""):match("^%s*(.-)%s*$")
                
                if actor_name == "" or actor_name == "-- без актора --" then
                    current_actor = nil -- Clear active actor
                else
                    current_actor = actor_name -- Set new persistent actor
                end
                matched = true
            else
                -- Check if line starts with timestamp or # (new entry)
                -- If not, it's a continuation of previous note
                local is_continuation = not line:match("^[#%d]")
                
                if is_continuation and #raw_notes > 0 then
                    -- Append to last note's text
                    raw_notes[#raw_notes].text = raw_notes[#raw_notes].text .. "\n" .. line
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
                                    table.insert(raw_notes, {time = ass_line.t1, text = note_text, actor = current_actor})
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
                                table.insert(raw_notes, {time = time1, text = full_text, actor = current_actor})
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
                                    table.insert(raw_notes, {time = time, text = note_text, actor = current_actor})
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
    end

    -- Merge duplicate notes (same time and text) and combine actors
    local merged_notes = {}
    local note_map = {} -- key: "time_text", value: index in merged_notes

    for _, note in ipairs(raw_notes) do
        -- Create a unique key for matching duplicates (using formatted time to avoid float precision issues)
        local key = string.format("%.3f_%s", note.time, note.text)
        
        if note_map[key] then
            -- Note exists, check if we need to add actor
            local existing_note = merged_notes[note_map[key]]
            if note.actor then
                -- Check if actor is already in the list
                local has_actor = false
                for _, act in ipairs(existing_note.actors) do
                    if act == note.actor then has_actor = true; break; end
                end
                
                if not has_actor then
                    table.insert(existing_note.actors, note.actor)
                end
            end
        else
            -- New unique note
            local new_entry = {
                time = note.time,
                text = note.text,
                actors = {}
            }
            if note.actor then
                table.insert(new_entry.actors, note.actor)
            end
            table.insert(merged_notes, new_entry)
            note_map[key] = #merged_notes
        end
    end
    
    -- Finalize notes list for creation
    local notes = {}
    for _, note in ipairs(merged_notes) do
        if #note.actors > 0 then
            ensure_director_actors(note.actors)
        end

        local final_text = note.text
        if #note.actors > 0 then
            table.sort(note.actors) -- Sort actors alphabetically for consistency
            local actor_prefix = "[" .. table.concat(note.actors, ", ") .. "] "
            final_text = actor_prefix .. final_text
        end
        table.insert(notes, {time = note.time, text = final_text})
    end

    if #notes == 0 then
        show_snackbar("Не знайдено жодної правки у правильному форматі", "error")
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
    reaper.Undo_BeginBlock()
    for _, note in ipairs(notes) do
        -- Always create marker (not region)
        reaper.AddProjectMarker2(0, false, note.time, 0, note.text, -1, reaper.ColorToNative(255, 200, 100) | 0x1000000)
    end
    reaper.Undo_EndBlock("Імпорт правок", -1)
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    
    -- Force prompter drawer caches to refresh
    prompter_drawer.marker_cache.count = -1
    prompter_drawer.filtered_cache.state_count = -1
    prompter_drawer.has_markers_cache.count = -1

    show_snackbar("Створено маркерів: " .. #notes, "success")
    UI_STATE.ass_file_loaded = true -- Enable Actor view
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
        show_snackbar("Не вдалося відкрити файл", "error")
        return
    end
    
    local content = fix_encoding(f:read("*all"))
    f:close()
    
    -- Parse CSV (RFC 4180 compliant - handles multiline quoted fields)
    local notes = {}
    
    -- Character-by-character parser to handle quoted fields with newlines
    local function parse_csv_content(text)
        local records = {}
        local current_record = {}
        local current_field = ""
        local in_quotes = false
        local i = 1
        
        while i <= #text do
            local char = text:sub(i, i)
            local next_char = text:sub(i+1, i+1)
            
            if in_quotes then
                if char == '"' then
                    if next_char == '"' then
                        -- Escaped quote ""
                        current_field = current_field .. '"'
                        i = i + 1
                    else
                        -- End of quoted field
                        in_quotes = false
                    end
                else
                    -- Any character inside quotes (including \n, \r)
                    current_field = current_field .. char
                end
            else
                if char == '"' then
                    -- Start of quoted field
                    in_quotes = true
                elseif char == ',' then
                    -- Field separator
                    table.insert(current_record, current_field)
                    current_field = ""
                elseif char == '\n' or char == '\r' then
                    -- End of record (skip \r\n combinations)
                    if char == '\r' and next_char == '\n' then
                        i = i + 1
                    end
                    if #current_field > 0 or #current_record > 0 then
                        table.insert(current_record, current_field)
                        if #current_record > 0 then
                            table.insert(records, current_record)
                        end
                        current_record = {}
                        current_field = ""
                    end
                else
                    -- Regular character
                    current_field = current_field .. char
                end
            end
            
            i = i + 1
        end
        
        -- Add last field and record if any
        if #current_field > 0 or #current_record > 0 then
            table.insert(current_record, current_field)
            if #current_record > 0 then
                table.insert(records, current_record)
            end
        end
        
        return records
    end
    
    local records = parse_csv_content(content)
    
    -- Process parsed records
    for line_num, parts in ipairs(records) do
        -- Skip header line (starts with #)
        if #parts >= 3 and not (parts[1] or ""):match("^#") then
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
                ensure_director_actors(name)
                table.insert(notes, {time = time, text = name})
            end
        end
    end
    
    if #notes == 0 then
        show_snackbar("Не знайдено жодного маркера у файлі", "error")
        return
    end
    
    -- Create markers
    push_undo("Імпорт правок з CSV")
    
    reaper.PreventUIRefresh(1)
    reaper.Undo_BeginBlock()
    for _, note in ipairs(notes) do
        reaper.AddProjectMarker2(0, false, note.time, 0, note.text, -1, reaper.ColorToNative(255, 200, 100) | 0x1000000)
    end
    reaper.Undo_EndBlock("Імпорт правок з CSV", -1)
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    
    -- Force prompter drawer caches to refresh
    prompter_drawer.marker_cache.count = -1
    prompter_drawer.filtered_cache.state_count = -1
    prompter_drawer.has_markers_cache.count = -1

    show_snackbar("Створено маркерів: " .. #notes, "success")
end

--- Import ASS/SSA subtitle file, parsing styles and events
--- @param file_path string|nil Absolute path to file or nil to prompt user
local function import_ass(file_path, dont_rebuild)
    local file = file_path
    if not file then
        local retval
        retval, file = reaper.GetUserFileNameForRead("", "Import ASS", "ass")
        if not retval then return end
    end
    local f = io.open(file, "r")
    if not f then return end
    UI_STATE.current_file_name = file:match("([^/\\]+)$")
    UI_STATE.current_file_path = file
    
    -- Check for deadline in filename
    local dl = DEADLINE.parse_from_name(UI_STATE.current_file_name)
    if dl then DEADLINE.set(dl) end
    
    local content = fix_encoding(f:read("*all"))
    f:close()
    
    content = content:gsub("\r\n", "\n")
    
    -- Ensure State Init
    if not ass_lines then ass_lines = {} end
    if not ass_actors then ass_actors = {} end
    
    UI_STATE.ass_file_loaded = true
    local line_idx_counter = get_next_line_index()
    
    -- Clear UI state
    table_filter_state.text = ""
    table_selection = {}
    last_selected_row = nil
    
    local duplicates_skipped = 0
    local in_events = false
    local format_def = nil
    
    -- Dubber metadata detection
    local metadata_str = content:match("; SubassDubbers: ([^\n]+)")
    
    -- If not found in comments, scan Dialogue lines for SubassMetadata
    if not metadata_str then
        metadata_str = content:match("Dialogue:[^,]+,[^,]+,[^,]+,[^,]+,SubassMetadata,[^,]+,[^,]+,[^,]+,,([^\n]+)")
    end

    local selected_dubber_actors = nil
    if metadata_str then
        local success, assignments = pcall(function() return STATS.json_decode(metadata_str) end)
        if success and type(assignments) == "table" then
            -- Sync with DUBBERS data
            if DUBBERS and DUBBERS.load then
                DUBBERS.load() -- Ensure latest data
                local dubber_names_map = {}
                for _, n in ipairs(DUBBERS.data.names) do dubber_names_map[n] = true end
                
                for name, assigned_actors in pairs(assignments) do
                    if not dubber_names_map[name] then
                        table.insert(DUBBERS.data.names, name)
                        dubber_names_map[name] = true
                    end
                    if not DUBBERS.data.assignments[name] then
                        DUBBERS.data.assignments[name] = {}
                    end
                    for actor, is_on in pairs(assigned_actors) do
                        DUBBERS.data.assignments[name][actor] = is_on
                    end
                end
                DUBBERS.save()
            end

            local dubber_names = {}
            for name in pairs(assignments) do table.insert(dubber_names, name) end
            table.sort(dubber_names)
            
            if #dubber_names > 0 then
                local menu_str = "Відкрити весь скрипт|" .. table.concat(dubber_names, "|")
                gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
                local ret = gfx.showmenu(menu_str)
                if ret > 1 then
                    local chosen = dubber_names[ret - 1]
                    selected_dubber_actors = assignments[chosen] or {}
                    show_snackbar("Режим дабера: " .. chosen, "info")
                end
            end
        end
    end

    for line in content:gmatch("([^\n]*)\n?") do
        if line:match("^%[Events%]") then in_events = true 
        elseif line:match("^%[.*%]") then in_events = false end
        
        if in_events then
            if line:match("^Format:") then
                format_def = {}
                local fmt_str = line:match("^Format:%s*(.*)")
                local idx = 1
                for field in (fmt_str .. ","):gmatch("(.-),") do
                    field = field:match("^%s*(.-)%s*$")
                    if field ~= "" then
                        format_def[field] = idx
                        idx = idx + 1
                    end
                end
            elseif line:match("^Dialogue:") and format_def then
                -- Skip metadata line if it's in the actual event list
                if line:match(",SubassMetadata,") then goto next_line end

                local body = line:match("^Dialogue:%s*(.*)")
                local fields = {}
                local max_field_idx = 0
                for _, f_idx in pairs(format_def) do
                    if f_idx > max_field_idx then max_field_idx = f_idx end
                end
                
                local search_start = 1
                for i = 1, max_field_idx - 1 do
                    local comma_pos = body:find(",", search_start)
                    if not comma_pos then break end
                    table.insert(fields, body:sub(search_start, comma_pos - 1))
                    search_start = comma_pos + 1
                end
                -- The rest of the line is the last field (usually 'Text')
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
                    
                    if not is_duplicate_replica(actor, t1, t2, text) then
                        local is_enabled = true
                        if selected_dubber_actors then
                            is_enabled = selected_dubber_actors[actor] == true
                        end

                        table.insert(ass_lines, {
                            t1=t1, t2=t2, text=text, actor=actor, enabled=is_enabled,
                            index = line_idx_counter
                        })
                        line_idx_counter = line_idx_counter + 1
                        
                        if ass_actors[actor] == nil then 
                            ass_actors[actor] = is_enabled 
                        else
                            -- If actor already exists, we only enable it if it's assigned to us
                            if selected_dubber_actors then
                                ass_actors[actor] = ass_actors[actor] or (selected_dubber_actors[actor] == true)
                            end
                        end
                    else
                        duplicates_skipped = duplicates_skipped + 1
                    end
                end
            end
        end
        ::next_line::
    end

    -- Push undo if single import
    if not dont_rebuild then
        push_undo("Імпорт ASS")
    end

    -- Initial Build
    if not dont_rebuild then
        update_regions_cache() 
        rebuild_regions() -- This calls save_project_data
    end

    -- Auto-upload to Firestore
    upload_subtitles_analytics()

    return duplicates_skipped or 0
end

-- =============================================================================
-- STRESS MARKS (UKRAINIAN ACCENT MARKS)
-- =============================================================================

--- Apply stress marks from dictionary file to all subtitles
-- Forward declaration
local global_coroutine = nil
local apply_stress_marks_async 

-- Callback for when stress tool finishes
local function on_stress_complete(output, script_path, export_count, temp_out, log_file, temp_in, is_windows, python_success)
    local changed_lines = 0
    local ai_error_type = nil
    
    UI_STATE.script_loading_state.active = false
    
    -- Check if success by verifying output file content (run_async_command manages process wait)
    -- In run_async_command callback, 'output' is the STDOUT of the command wrapper.
    -- But we care about 'temp_out' file existence/content or log file errors.
    
    -- 1. Check temp_out
    local f_out = io.open(temp_out, "r")
    if f_out then
        local head = f_out:read(10) -- Peek
        f_out:close()
        
        if head and head ~= "" then
            -- SUCCESS: Parse output
            f_out = io.open(temp_out, "r")
            local content = f_out:read("*all")
            f_out:close()
            
            local stressed_texts = {}
            local current_text = ""
            local state = 0 -- 0: Index, 1: Time, 2: Text
            for l in (content .. "\n"):gmatch("(.-)\r?\n") do
                l = l:match("^%s*(.-)%s*$") or l -- Trim
                if state == 0 then
                    if l:match("^%d+$") then state = 1 end
                elseif state == 1 then
                    if l:match("%-%->") then 
                        state = 2; current_text = "" 
                    end
                elseif state == 2 then
                    if l == "" then
                        table.insert(stressed_texts, (current_text == "" and "" or current_text:sub(1,-2)))
                        state = 0
                    else
                        current_text = current_text .. l .. "\n"
                    end
                end
            end
            if state == 2 then table.insert(stressed_texts, (current_text == "" and "" or current_text:sub(1,-2))) end
            
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
    end
    
    if not python_success then
        -- Check logs for errors
        local f_log = io.open(log_file, "r")
        if f_log then
            local logs = f_log:read("*all")
            f_log:close()
            if logs:find("PYTHON_VERSION_TOO_OLD") then ai_error_type = "VERSION"
            elseif logs:find("DEPENDENCY_INSTALL_FAILED") then ai_error_type = "DEPENDENCY"
            elseif logs:find("Operation not permitted") or logs:find("Access is denied") then ai_error_type = "PERMISSION"
            elseif logs:find("not recognized") or logs:find("not found") then ai_error_type = "PYTHON_MISSING"
            else ai_error_type = "UNKNOWN" end
                reaper.ShowConsoleMsg("AI Tool Failure Info:\n" .. logs .. "\n")
        else
            ai_error_type = "TIMEOUT_OR_CRASH"
        end
    end
    os.remove(temp_in)
    
    -- ERROR HANDLING (No fallback)
    if not python_success then
        UI_STATE.script_loading_state.active = false
        
        local msg = "Не вдалося розставити наголоси.\n--------------------------------------------------\n\n"
        if ai_error_type == "PERMISSION" then
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
        elseif ai_error_type == "TIMEOUT" or ai_error_type == "TIMEOUT_OR_CRASH" then
            msg = msg .. "⚠️ ПЕРЕВИЩЕНО ЧАС ОЧІКУВАННЯ (Timeout):\n"
            msg = msg .. "AI-інструмент не встиг обробити текст (або стався збій).\n\n"
            msg = msg .. "ЯК ВИПРАВИТИ:\n"
            msg = msg .. "1. Якщо це перший запуск — можливо, триває завантаження моделей. Спробуйте ще раз.\n"
            msg = msg .. "2. Перевірте консоль REAPER на наявність помилок.\n"
        else
            msg = msg .. "❌ НЕВІДОМА ПОМИЛКА.\n\n"
        end
        
        msg = msg .. "Шлях до скрипта: " .. script_path
        reaper.MB(msg, "Помилка наголосів", 0)
        return
    end
    
    UI_STATE.script_loading_state.active = false
    
    if changed_lines > 0 then
        push_undo("Авто-наголоси (" .. changed_lines .. ")")
        cleanup_actors()
        rebuild_regions()
        save_project_data(UI_STATE.last_project_id)
        show_snackbar("Наголоси додано: " .. changed_lines .. " рядків", "success")
    else
        show_snackbar("Наголоси не потрібні або не знайдені", "info")
    end
end

--- Apply stress marks asynchronously
apply_stress_marks_async = function()
    UI_STATE.script_loading_state.active = true
    UI_STATE.script_loading_state.text = "Ініціалізація..."
    
    -- Calculate paths OUTSIDE coroutine to avoid debug.getinfo issues
    local is_windows = reaper.GetOS():match("Win") ~= nil
    local function get_actual_script_path()
        local info = debug.getinfo(1, "S")
        local path = info.source
        if path:sub(1, 1) == "@" then path = path:sub(2) end
        
        -- Fallback: try to get absolute path from action context if path is just a filename
        if not path:find("[\\/]") then
            local _, filename = reaper.get_action_context()
            if filename and filename ~= "" and filename:find("[\\/]") then
                path = filename
            end
        end

        local separator = package.config:sub(1, 1)
        local opposite_sep = (separator == "/" and "\\" or "/")
        
        -- Normalize path separators
        path = path:gsub(opposite_sep, separator)
        
        -- Extract the directory part (everything up to the last separator)
        local dir = path:gsub("[^" .. (separator == "\\" and "\\\\" or separator) .. "]*$", "")

        if not dir or dir == "" then 
            -- Ultimate fallback to ResourcePath/Scripts
            dir = reaper.GetResourcePath() .. separator .. "Scripts" .. separator
            dir = dir:gsub(opposite_sep, separator)
        end

        -- Ensure trailing separator and append 'stress'
        if dir:sub(-1) ~= separator then
            dir = dir .. separator
        end
        
        return dir .. "stress" .. separator
    end
    local script_path = get_actual_script_path()

    -- Use global coroutine for setup phase to allow yielding (fix initial freeze)
    global_coroutine = coroutine.create(function()
        coroutine.yield() -- Yield once to ensure Loader draws immediately
        
        local python_tool = script_path .. "ukrainian_stress_tool.py"
        
        -- Check Tool Existence
        local f_tool = io.open(python_tool, "r")
        local has_python_tool = (f_tool ~= nil)
        if f_tool then f_tool:close() end
    
        local export_count = 0
        local temp_in = script_path .. "temp_stress_in.srt"
        local temp_out = script_path .. "temp_stress_out.srt"
        local log_file = script_path .. "stress_debug.log"
        
        -- Prepare Data
        if has_python_tool then
            UI_STATE.script_loading_state.text = "Експорт тексту..."
            coroutine.yield()
            
            os.remove(temp_out)
            local f_in = io.open(temp_in, "w")
            if f_in then
                local time_batch_start = os.clock()
                for i, line in ipairs(ass_lines) do
                    if ass_actors[line.actor] then
                        export_count = export_count + 1
                        f_in:write(export_count .. "\n")
                        f_in:write("00:00:00,000 --> 00:00:01,000\n")
                        f_in:write(line.text .. "\n\n")
                    end
                    -- More aggressive yielding to prevent "Export Text" freeze
                    if (i % 50 == 0) and (os.clock() - time_batch_start > 0.01) then
                        coroutine.yield()
                        time_batch_start = os.clock()
                    end
                end
                
                -- Yield before closing file (heavy flush)
                coroutine.yield() 
                f_in:close()
                
                if export_count > 0 then
                    UI_STATE.script_loading_state.text = "AI обробка..."
                    coroutine.yield()
                    
                    local tool_p = python_tool
                    local in_p = temp_in
                    local out_p = temp_out
                    
                    local cmd_to_run = ""
                    
                    if is_windows then 
                        -- Windows: Directly run command to avoid blocking 'where python' check.
                        -- If python is missing, cmd will print error to log_file.
                        tool_p = tool_p:gsub("/", "\\")
                        in_p = in_p:gsub("/", "\\")
                        out_p = out_p:gsub("/", "\\")
                        log_file = log_file:gsub("/", "\\")
                        local py_exe = OTHER.rec_state.python.executable or "python"
                        cmd_to_run = string.format('%s "%s" "%s" -o "%s" > "%s" 2>&1', py_exe, tool_p, in_p, out_p, log_file)
                    else
                        -- Mac/Linux: Assume python3
                        cmd_to_run = string.format('python3 "%s" "%s" -o "%s" > "%s" 2>&1', tool_p, in_p, out_p, log_file)
                    end
                    
                    if cmd_to_run ~= "" then
                        -- We are done with coroutine setup, hand off to async system
                        run_async_command(cmd_to_run, function(out)
                            on_stress_complete(out, script_path, export_count, temp_out, log_file, temp_in, is_windows, false)
                        end)
                        global_coroutine = nil -- Coroutine finished its job
                        return 
                    end
                end
            end
        end
        
        -- If we got here, AI failed or tool missing, proceed immediately to fallback
        global_coroutine = nil
        on_stress_complete("", script_path, export_count, temp_out, log_file, temp_in, is_windows, false)
    end)
    
    -- Initial resume
    local ok, err = coroutine.resume(global_coroutine)
    if not ok then
        reaper.ShowConsoleMsg("Coroutine Error: " .. tostring(err) .. "\n")
        UI_STATE.script_loading_state.active = false
        global_coroutine = nil
    end
end

--- Handle Drag & Drop of SRT/ASS files
local function handle_drag_drop()
    local file_idx = 0
    local retval, dropped_file = gfx.getdropfile(file_idx)
    local imported_count = 0
    local total_duplicates = 0
    
    if retval > 0 then
        push_undo("Імпорт (Drag & Drop)")
    end
    
    while retval > 0 do
        local ext = dropped_file:match("%.([^.]+)$")
        if ext then
            ext = ext:lower()
            if ext == "srt" then
                total_duplicates = total_duplicates + import_srt(dropped_file, true)
                imported_count = imported_count + 1
            elseif ext == "ass" then
                total_duplicates = total_duplicates + import_ass(dropped_file, true)
                imported_count = imported_count + 1
            elseif ext == "vtt" then
                total_duplicates = total_duplicates + import_vtt(dropped_file, true)
                imported_count = imported_count + 1
            elseif ext == "csv" then
                import_notes_from_csv(dropped_file)
            else
                show_snackbar("Формат ." .. ext:upper() .. " не підтримується", "error")
            end
        else
            show_snackbar("Не вдалося визначити формат файлу", "error")
        end
        
        file_idx = file_idx + 1
        retval, dropped_file = gfx.getdropfile(file_idx)
    end
    
    if imported_count > 0 then
        update_regions_cache()
        rebuild_regions()
        local msg = "Імпортовано файлів: " .. imported_count
        if total_duplicates > 0 then msg = msg .. " (Дублікатів: " .. total_duplicates .. ")" end
        show_snackbar(msg, "success")
    end
    
    gfx.getdropfile(-1) -- Clear drop queue
end

--- Delete all project regions
local function delete_all_regions()
    local resp = reaper.ShowMessageBox("Ви впевнені, що хочете видалити ВСІ регіони та очистити дані?\n\n!!ДІЯ НЕЗВОРОТНА!!!", "Видалення", 4)
    if resp ~= 6 then return end

    -- Clear project data
    ass_lines = {}
    ass_actors = {}
    UI_STATE.ass_file_loaded = false

    -- Clear undo/redo history
    undo_stack = {}
    redo_stack = {}

    rebuild_regions()
    save_project_data()

    if show_snackbar then
        show_snackbar("Всі дані та регіони видалено", "error")
    end
end

--- Get current script absolute path
local function get_script_path()
    local info = debug.getinfo(1, 'S')
    local path = ""
    if info and info.source then
        path = info.source:match("@?(.*)")
    end
    
    -- Fallback: try to get absolute path from action context
    if path == "" or not path:find("[\\/]") then
        local _, filename = reaper.get_action_context()
        if filename and filename ~= "" then
            path = filename
        end
    end

    local separator = package.config:sub(1, 1)
    local opposite_sep = (separator == "/" and "\\" or "/")
    return path:gsub(opposite_sep, separator)
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
            -- Cleanup legacy entries (untagged) that might contain unescaped Windows paths
            if not line:find("Subass_Notes.lua", 1, true) then
                table.insert(new_lines, line)
            end
        end
    end
    
    if enable then
        -- Find Command ID for better isolation
        local cmd_id = nil
        local kb_path = resource_path .. "/reaper-kb.ini"
        local f_kb = io.open(kb_path, "r")
        if f_kb then
            local escaped_path = script_path:gsub("([%%%^%$%(%)%.%[%]%*%+%-%?])", "%%%1")
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
            launch_cmd = string.format("reaper.defer(function() reaper.Main_OnCommand(reaper.NamedCommandLookup(\"%s\"), 0) end)", cmd_id)
        else
            -- Fallback to dofile if not registered
            launch_cmd = string.format("reaper.defer(function() dofile([[%s]]) end)", script_path)
        end

        -- Add at the beginning to ensure it runs
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

--- Run auto-update script and show results
--- @param is_silent boolean If true, don't show "checking" loader or "up-to-date" message
local function check_for_updates(is_silent)
    local script_path = debug.getinfo(1,'S').source:match([[^@?(.*[\/])]])
    local py_script = script_path .. "subass_autoupdate.py"
    
    local py_exe = OTHER.rec_state.python.executable or (reaper.GetOS():match("Win") and "python" or "python3")
    local is_windows = reaper.GetOS():match("Win")
    
    local cmd
    if is_windows then
        py_script = py_script:gsub("/", "\\")
        cmd = string.format('%s "%s" "%s"', py_exe, py_script, GL.script_title)
    else
        cmd = string.format("'%s' '%s' '%s'", py_exe, py_script, GL.script_title)
    end

    run_async_command(cmd, function(output)
        if not is_silent then UI_STATE.script_loading_state.active = false end
        if output and output ~= "" then
            -- Parse line-based format
            local data = {}
            data.update_available = output:match("UPDATE_AVAILABLE: (%a+)") == "true"
            data.current_title = output:match("CURRENT_TITLE: (.-)[\r\n]")
            data.latest_title = output:match("LATEST_TITLE: (.-)[\r\n]")
            data.manual_update = output:match("MANUAL_UPDATE: (%a+)") == "true"
            data.download_url = output:match("DOWNLOAD_URL: (.-)[\r\n]") or output:match("PATH: (.-)[\r\n]")
            data.description = output:match("DESCRIPTION_START[\r\n]*(.-)[\r\n]*DESCRIPTION_END")
            
            if data.update_available then
                local msg = string.format("Доступна нова версія: %s\n(У вас: %s)\n\n", data.latest_title or "v?", data.current_title or "v?")
                if data.description and data.description ~= "" then
                    msg = msg .. "Що нового:\n" .. data.description .. "\n\n"
                end
                
                if data.manual_update then
                    msg = msg .. "Це оновлення потребує ручного встановлення.\nПерейти до Telegram каналу для завантаження?"
                    
                    -- MB Type 4 = Yes/No (Yes=6, No=7)
                    local res = reaper.MB(msg, "Ручне оновлення", 4)
                    if res == 6 then
                        UTILS.open_url("https://t.me/subass_notes")
                    end
                else
                    msg = msg .. "Бажаєте оновити?"
                    
                    -- MB Type 4 = Yes/No (Yes=6, No=7)
                    local res = reaper.MB(msg, "Доступне оновлення", 4)
                    if res == 6 then
                        -- Trigger update in python
                        local update_cmd
                        if is_windows then
                            update_cmd = string.format('%s "%s" --update "%s"', py_exe, py_script, data.download_url or "")
                        else
                            update_cmd = string.format("'%s' '%s' --update '%s'", py_exe, py_script, data.download_url or "")
                        end
                        
                        run_async_command(update_cmd, function(upd_output)
                            UI_STATE.script_loading_state.active = false
                            local ok_msg = "Оновлення успішно завершено!"
                            if upd_output and upd_output:find(ok_msg) then
                                reaper.MB(upd_output, "Автооновитель", 0)
                                UTILS.restart_script()
                            else
                                reaper.MB(upd_output or "Помилка оновлення.", "Автооновитель", 0)
                            end
                        end, false, "Оновлюю...")
                    end
                end
            elseif not is_silent then
                -- If not available and NOT silent, we show either the python msg or "you have latest"
                local clean_out = output:gsub("UPDATE_AVAILABLE: false[\r\n]*", ""):gsub("CURRENT_TITLE: .-[\r\n]*", ""):match("^%s*(.-)%s*$")
                reaper.MB(clean_out ~= "" and clean_out or "У вас вже встановлена актуальна версія.", "Перевірка оновлень", 0)
            end
        elseif not is_silent then
            reaper.MB("Не вдалося отримати відповідь від сервера оновлень.\nКоманда: " .. cmd, "Помилка", 0)
        end
    end, is_silent, "Перевіряю оновлення...")
end

--- Wrap rich text (segments) to fit width
local function wrap_rich_text(segments, max_w, font_slot, font_name, base_size, is_header, first_line_indent)
    local lines = {}
    local current_line = {}
    local current_w = 0
    local is_first_line = true
    
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
            local f_flags, effective_font = 0, font_name
            local is_bold = seg.b or seg.is_bold or (is_header and not (seg.is_plain or seg.s))
            local is_italic = seg.i or seg.is_italic
            
            if is_italic then
                if font_name == "Helvetica" then effective_font = "Helvetica Oblique"
                else f_flags = f_flags + string.byte('i') end
            end
            if is_bold then
                if effective_font == font_name then 
                    if is_italic then f_flags = string.byte('b') | (string.byte('i') << 8)
                    else f_flags = string.byte('b') end
                elseif is_italic and font_name == "Helvetica" then 
                    effective_font = "Helvetica Bold Oblique"
                    f_flags = 0
                end
            end
            gfx.setfont(font_slot, effective_font, base_size, f_flags)
            
            -- Ignore stress marks for layout measurement
            local measure_word_for_width = test_word:gsub(acute, "")
            local word_w = gfx.measurestr(measure_word_for_width)
            
            local effective_max_w = (is_first_line and first_line_indent) and (max_w - first_line_indent) or max_w
            
            if current_w + word_w > effective_max_w and current_w > 0 then
                table.insert(lines, current_line)
                current_line = {}
                current_w = 0
                is_first_line = false
                test_word = w
                word_w = gfx.measurestr((test_word:gsub(acute, "")))
            end
            
            local last_seg = current_line[#current_line]
            
            -- Helper to compare colors
            local colors_match = false
            if not last_seg then
            elseif not last_seg.color and not seg.color then
                colors_match = true
            elseif last_seg.color and seg.color then
                colors_match = (last_seg.color[1] == seg.color[1] and 
                                last_seg.color[2] == seg.color[2] and 
                                last_seg.color[3] == seg.color[3])
            end

            local can_merge = last_seg and 
                (last_seg.is_link == seg.is_link) and 
                (last_seg.is_plain == seg.is_plain) and 
                ((last_seg.b or last_seg.is_bold) == (seg.b or seg.is_bold)) and
                ((last_seg.i or last_seg.is_italic) == (seg.i or seg.is_italic)) and
                ((last_seg.u or false) == (seg.u or false)) and
                ((last_seg.u_wave or false) == (seg.u_wave or false)) and
                ((last_seg.s or false) == (seg.s or false)) and
                (last_seg.comment == seg.comment) and
                (last_seg.word == seg.word) and
                colors_match
            
            if can_merge then
                last_seg.text = last_seg.text .. test_word
            else
                local new_seg = {}
                for k, v in pairs(seg) do new_seg[k] = v end
                new_seg.text = test_word
                -- Ensure both old and new flag names are present for compatibility
                new_seg.b = seg.b or seg.is_bold
                new_seg.i = seg.i or seg.is_italic
                new_seg.is_bold = new_seg.b
                new_seg.is_italic = new_seg.i
                new_seg.is_plain = seg.is_plain or false  -- Explicitly preserve is_plain
                
                table.insert(current_line, new_seg)
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
        { name = "Визначити головне слово", count = 1, task = "Проаналізуй наступну репліку. Знайди ОДНЕ головне слово, яке є смисловим центром (ремою) речення, і постав після нього тег {Головне слово} без пробілу.\n\nКритерії вибору:\n1. Логічний наголос: Слово, яке несе основну вагу. У питаннях — це суть запиту, у наказах — суть дії.\n2. Тільки повнозначні слова: Ігноруй прийменники, сполучники та частки (не, і, на, б).\n3. Контекст: У звертаннях головним є поняття або дія, а не ім'я (наприклад: \"Вілл, СОВІСТЬ май\").\n4. Рема: Шукай «нове» у реченні, те, заради чого воно сказане.\n\nФормат відповіді: Поверни ТІЛЬКИ текст репліки з коментарем {Головне слово} одразу за словом (приклад: слово{Головне слово}). Жодних пояснень." },
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

    -- Store bounds for focus checks
    ai_modal.x, ai_modal.y = x, y
    ai_modal.w, ai_modal.h = menu_w, menu_h

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
                                    local before = text_editor_state.text:sub(1, ai_modal.sel_min)
                                    local after = text_editor_state.text:sub(ai_modal.sel_max + 1)
                                    text_editor_state.text = before .. sugg.text .. after
                                    text_editor_state.cursor = ai_modal.sel_min + #sugg.text
                                    text_editor_state.anchor = text_editor_state.cursor
                                    
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
    local mouse_in_menu = UI_STATE.window_focused and (gfx.mouse_x >= x and gfx.mouse_x <= x + menu_w and
                           gfx.mouse_y >= y and gfx.mouse_y <= y + menu_h)

    -- Draw Menu Shadow
    set_color(UI.C_BLACK_OVERLAY)
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
            if by + btn_h > 0 and by < view_h then -- Visible?
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
            set_color(UI.C_FR_BORDER)
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
            
            set_color(hover and {UI.C_FR_MATCH_BG[1]*alpha, UI.C_FR_MATCH_BG[2]*alpha, UI.C_FR_MATCH_BG[3]*alpha, 1.0 * alpha} or 
                      {UI.C_FR_MATCH_INA[1]*alpha, UI.C_FR_MATCH_INA[2]*alpha, UI.C_FR_MATCH_INA[3]*alpha, 1.0 * alpha})
            gfx.rect(bx, by, bw, block_h, 1)
            set_color(UI.C_FR_MATCH_BORDER, alpha)
            gfx.rect(bx, by, bw, block_h, 0)
            
            set_color(UI.C_FR_MATCH_TXT, alpha)
            for li, line in ipairs(wrapped_lines) do
                gfx.x, gfx.y = bx + 8, by + 5 + (li-1) * 18
                gfx.drawstr(line)
            end
            curr_y = curr_y + block_h + 5
        end
        
        -- Fixed Footer with Back and Retry Buttons
        set_color(UI.C_TAB_INA)
        gfx.rect(0, view_h, menu_w, footer_h, 1)
        set_color(UI.C_FR_BORDER)
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
        set_color(hover_more and UI.C_SEL or UI.C_BTN_DARK)
        gfx.rect(rbx, rby, rbw, rbh, 1)
        set_color(UI.C_TXT)
        local msw, msh = gfx.measurestr("ЩЕ")
        gfx.x, gfx.y = rbx + (rbw - msw) / 2, rby + (rbh - msh) / 2
        gfx.drawstr("ЩЕ")

    elseif ai_modal.current_step == "ERROR" then
        set_color(UI.C_FR_CLOSE)
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
        set_color(UI.C_SCROLL_HDL)
        gfx.rect(x + menu_w - 8, sb_y, 4, sb_h, 1)
    end
    
    return changed
end


--- Play text-to-speech audio for Ukrainian word using ukrainian_tts.py
--- @param text string Text to synthesize
--- @param save_to_timeline boolean|nil If true, insert audio into active track at cursor
local function play_tts_audio(text, save_to_timeline)
    if not text then return end
    text = text:match("^%s*(.-)%s*$")
    if text == "" then return end

    if dict_modal.tts_loading then return end
    
    -- Set loading state immediately to prevent concurrent calls
    dict_modal.tts_loading = true
    dict_modal.tts_current_word = text
    UI_STATE.script_loading_state.active = true
    UI_STATE.script_loading_state.text = save_to_timeline and "Генерую та зберігаю..." or "Озвучую..."
    
    -- Stop any existing preview
    if dict_modal.tts_preview and reaper.CF_Preview_Stop then
        reaper.CF_Preview_Stop(dict_modal.tts_preview)
        dict_modal.tts_preview = nil
    end

    -- Path to python script
    local script_path = debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])")
    local tts_script = script_path .. "tts/ukrainian_tts.py"
    
    -- Check if TTS script exists
    local f = io.open(tts_script, "r")
    if not f then
        show_snackbar("TTS скрипт не знайдено", "error")
        dict_modal.tts_loading = false
        UI_STATE.script_loading_state.active = false
        return
    end
    f:close()
    
    -- Determine voice and key based on configuration
    local voice_arg = ""
    local key_arg = ""

    local v_cfg = cfg.tts_voice_map[cfg.tts_voice] or cfg.tts_voice_map["Горох: Оксана (Wavenet)"]
    voice_arg = string.format('--voice "%s"', v_cfg.voice)

    if v_cfg.engine == "eleven" then
        if cfg.eleven_api_key ~= "" then 
            key_arg = string.format('--eleven-key "%s"', cfg.eleven_api_key) 
        end
    end
    
    -- Build command using standardized python executable if available
    local is_windows = reaper.GetOS():match("Win")
    local tts_input_file = (script_path .. "/tts/tts_input.txt")
    if is_windows then tts_input_file = tts_input_file:gsub("/", "\\") end
    
    local f_in = io.open(tts_input_file, "w")
    if f_in then
        f_in:write(text)
        f_in:close()
    else
        show_snackbar("Помилка запису тимчасового файлу", "error")
        dict_modal.tts_loading = false
        UI_STATE.script_loading_state.active = false
        return
    end

    local cmd
    if is_windows then
        -- Normalize paths for Windows to avoid issues
        tts_script = tts_script:gsub("/", "\\")
        
        -- Use configured python executable from requirements state if available
        local py_exe = OTHER.rec_state.python.executable or "python"
        
        -- Pass text via file to avoid shell expansion/multiline issues
        cmd = string.format('%s "%s" --file "%s" %s %s', py_exe, tts_script, tts_input_file, voice_arg, key_arg)
    else
        -- Use detected python or fallback
        local py_exe = OTHER.rec_state.python.executable or "python3"
        -- Pass text via file for consistency and robustness
        cmd = string.format("'%s' '%s' --file '%s' %s %s", py_exe, tts_script, tts_input_file, voice_arg, key_arg)
    end
    
    -- Run command asynchronously using the standardized function
    run_async_command(cmd, function(output)
        dict_modal.tts_loading = false
        UI_STATE.script_loading_state.active = false
        
        if not output then
            show_snackbar("Помилка виконання TTS", "error")
            return
        end
        
        -- Extract MP3 path (last non-empty line of output)
        local mp3_path = nil
        for line in output:gmatch("[^\r\n]+") do
            if line and line ~= "" and not line:match("^Using cached") and not line:match("^Generating") and not line:match("^Successfully") then
                mp3_path = line
            end
        end
        
        if mp3_path then
            mp3_path = mp3_path:match("^%s*(.-)%s*$") -- Trim whitespace
        end
        
        if mp3_path and mp3_path ~= "" and not mp3_path:match("Error") and not mp3_path:match("Traceback") then
            -- Check if file exists
            local test_f = io.open(mp3_path, "r")
            if test_f then
                test_f:close()
                
                -- 1. Preview (Always for "Speak", or as requested)
                if not save_to_timeline then
                    local pcm_source = reaper.PCM_Source_CreateFromFile(mp3_path)
                    if pcm_source then
                        if reaper.CF_CreatePreview and reaper.CF_Preview_Play then
                            local preview = reaper.CF_CreatePreview(pcm_source)
                            if preview then
                                reaper.CF_Preview_Play(preview)
                                dict_modal.tts_preview = preview
                                show_snackbar("▶ Відтворення аудіо", "success")
                            end
                        end
                    end
                end

                -- 2. Save to Timeline
                if save_to_timeline then
                    local track = reaper.GetSelectedTrack(0, 0)
                    if not track then
                        show_snackbar("Виберіть трек для вставки", "error")
                    else
                        -- mode 0 = insert at edit cursor, move cursor? 
                        -- actually, mode 0 is standard. mode 1 = new track. 
                        reaper.InsertMedia(mp3_path, 0)
                        show_snackbar("Аудіо додано на трек", "success")
                    end
                end
            else
                show_snackbar("Аудіо файл не знайдено", "error")
            end
        else
            show_snackbar("Помилка генерації TTS", "error")
            reaper.ShowConsoleMsg("\n══════════ TTS ERROR REPORT ══════════\n")
            reaper.ShowConsoleMsg(output or "No output available")
            reaper.ShowConsoleMsg("\n══════════════════════════════════════\n")
        end
    end)
end

--- Handle keyboard input for a text field state
--- @param input_queue table Key inputs
--- @param state table Input state {text, cursor, anchor}
--- @param is_multiline boolean Allow newlines
--- @return boolean True if text changed
local function process_input_events(input_queue, state, is_multiline, visual_lines)
    if not input_queue or #input_queue == 0 then return false end
    
    -- Reset auto-scroll suppression on any keyboard activity
    state.suppress_auto_scroll_until = 0
    
    local cap = gfx.mouse_cap
    local is_ctrl = (cap & 4 == 4)
    local is_cmd = (cap & 32 == 32)
    local is_shift = (cap & 8 == 8)
    local is_mod = (is_ctrl or is_cmd)
    
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
        -- Select All (Mod+A)
        if char == 1 or (is_mod and (char == 97 or char == 65)) then
            anchor = 0
            cursor = #text
        elseif char == 4 then -- Ctrl+D (Deselect All)
            anchor = cursor
        -- Copy
        elseif (char == 3) or (is_mod and (char == 99 or char == 67)) then
            if has_sel then
                local s_min, s_max = math.min(cursor, anchor), math.max(cursor, anchor)
                set_clipboard(text:sub(s_min + 1, s_max))
            end
        -- Cut
        elseif (char == 24) or (is_mod and (char == 120 or char == 88)) then
            if has_sel then
                local s_min, s_max = math.min(cursor, anchor), math.max(cursor, anchor)
                set_clipboard(text:sub(s_min + 1, s_max))
                delete_selection()
            end
        -- Paste
        elseif (is_mod and (char == 118 or char == 86)) or (char == 22) then
            delete_selection()
            local clipboard = get_clipboard()
            if clipboard and clipboard ~= "" then
                if not is_multiline then clipboard = clipboard:gsub("\n", " "):gsub("\r", "") end
                text = text:sub(1, cursor) .. clipboard .. text:sub(cursor + 1)
                cursor = cursor + #clipboard
                anchor = cursor
                changed = true
            end
        -- Undo / Redo
        elseif (char == 26) or (is_mod and (char == 122 or char == 90)) then
            if state.history and state.history_pos then
                if is_shift then
                    -- Redo
                    if state.history_pos < #state.history then
                        state.history_pos = state.history_pos + 1
                        local snap = state.history[state.history_pos]
                        text, cursor, anchor = snap.text, snap.cursor, snap.anchor
                        changed = true
                    end
                else
                    -- Undo
                    if state.history_pos > 1 then
                        state.history_pos = state.history_pos - 1
                        local snap = state.history[state.history_pos]
                        text, cursor, anchor = snap.text, snap.cursor, snap.anchor
                        changed = true
                    end
                end
            end
        elseif is_mod and (char == 121 or char == 89) then -- Redo (Ctrl+Y)
            if state.history and state.history_pos and state.history_pos < #state.history then
                state.history_pos = state.history_pos + 1
                local snap = state.history[state.history_pos]
                text, cursor, anchor = snap.text, snap.cursor, snap.anchor
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
        elseif char == 30064 then -- Up
            if not is_multiline or not visual_lines then
                cursor = 0
            else
                local cur_vi = 1
                for i, v in ipairs(visual_lines) do if cursor >= v.start_idx then cur_vi = i else break end end
                if cur_vi > 1 then
                    local cvl, pvl = visual_lines[cur_vi], visual_lines[cur_vi-1]
                    local rx = gfx.measurestr(cvl.text:sub(1, math.max(0, cursor - cvl.start_idx)))
                    local bd, bi = math.huge, 0
                    local coff = 0
                    while coff <= #pvl.text do
                        local d = math.abs(gfx.measurestr(pvl.text:sub(1, coff)) - rx)
                        if d < bd then bd, bi = d, coff end
                        if coff >= #pvl.text then break end
                        local b = pvl.text:byte(coff + 1); local len = 1
                        if b >= 240 then len = 4 elseif b >= 224 then len = 3 elseif b >= 192 then len = 2 end
                        coff = coff + len
                    end
                    cursor = pvl.start_idx + bi
                end
            end
            if not is_shift then anchor = cursor end
        elseif char == 1685026670 then -- Down
            if not is_multiline or not visual_lines then
                cursor = #text
            else
                local cur_vi = 1
                for i, v in ipairs(visual_lines) do
                    if cursor <= v.start_idx + #v.text then cur_vi = i; break end
                    cur_vi = i
                end
                if cur_vi < #visual_lines then
                    local cvl, nvl = visual_lines[cur_vi], visual_lines[cur_vi+1]
                    local rx = gfx.measurestr(cvl.text:sub(1, math.max(0, cursor - cvl.start_idx)))
                    local bd, bi = math.huge, 0
                    local coff = 0
                    while coff <= #nvl.text do
                        local d = math.abs(gfx.measurestr(nvl.text:sub(1, coff)) - rx)
                        if d < bd then bd, bi = d, coff end
                        if coff >= #nvl.text then break end
                        local b = nvl.text:byte(coff + 1); local len = 1
                        if b >= 240 then len = 4 elseif b >= 224 then len = 3 elseif b >= 192 then len = 2 end
                        coff = coff + len
                    end
                    cursor = nvl.start_idx + bi
                end
            end
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
        elseif char == 6579564 or char == 6647396 then -- Home
            if not is_multiline or not visual_lines then
                cursor = 0
            else
                local cur_vi = 1
                for i, v in ipairs(visual_lines) do if cursor >= v.start_idx and cursor <= v.start_idx + #v.text then cur_vi = i; break end end
                cursor = visual_lines[cur_vi].start_idx
            end
            if not is_shift then anchor = cursor end
        elseif char == 1701734758 or char == 1752132965 then -- End
            if not is_multiline or not visual_lines then
                cursor = #text
            else
                local cur_vi = 1
                for i, v in ipairs(visual_lines) do if cursor >= v.start_idx and cursor <= v.start_idx + #v.text then cur_vi = i; break end end
                cursor = visual_lines[cur_vi].start_idx + #visual_lines[cur_vi].text
            end
            if not is_shift then anchor = cursor end
        -- Typing (Safe UTF-8)
        elseif not is_mod then
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

local function record_field_history(state)
    if not state.history then state.history = {} end
    if not state.history_pos then state.history_pos = 0 end
    
    -- Only record if something actually changed from the last history point
    local last_hist = state.history[state.history_pos]
    if last_hist and last_hist.text == state.text and 
       last_hist.cursor == state.cursor and 
       last_hist.anchor == state.anchor then
        return
    end

    if state.history_pos < #state.history then
        for i = #state.history, state.history_pos + 1, -1 do
            table.remove(state.history, i)
        end
    end
    table.insert(state.history, {
        text = state.text or "",
        cursor = state.cursor or 0,
        anchor = state.anchor or 0
    })
    state.history_pos = #state.history
    if #state.history > 100 then
        table.remove(state.history, 1)
        state.history_pos = state.history_pos - 1
    end
end

local function ui_text_input(x, y, w, h, state, placeholder, input_queue, is_multiline, is_director_mode)
    gfx.setfont(F.std)
    local padding = S(5)
    local line_h = gfx.texth
    local text_w = w - padding * 2
    
    state.scroll = state.scroll or 0
    state.target_scroll = state.target_scroll or state.scroll
    state.suppress_auto_scroll_until = state.suppress_auto_scroll_until or 0
    state.cursor = state.cursor or 0
    state.anchor = state.anchor or state.cursor
    
    -- Initialize history if not present
    if not state.history then
        state.history = {}
        state.history_pos = 0
        record_field_history(state)
    end

    local before_text = state.text or ""

    -- --- LAYOUT: Visual Wrapping ---
    local visual_lines = {}
    if is_multiline then
        local raw_pos = 0
        for ln in (before_text .. "\n"):gmatch("(.-)\n") do
            if ln == "" then
                table.insert(visual_lines, {text = "", start_idx = raw_pos, is_wrapped = false})
            else
                local remaining = ln
                local line_start = raw_pos
                while #remaining > 0 do
                    local fit_count = 0
                    local char_len = utf8.len(remaining) or #remaining
                    local low, high = 1, char_len
                    while low <= high do
                        local mid = math.floor((low + high) / 2)
                        local CharEnd = utf8.offset(remaining, mid + 1) or (#remaining + 1)
                        if gfx.measurestr(remaining:sub(1, CharEnd - 1)) <= text_w - S(5) then
                            fit_count = CharEnd - 1
                            low = mid + 1
                        else
                            high = mid - 1
                        end
                    end
                    if fit_count == 0 then 
                        local first_char_end = utf8.offset(remaining, 2) or (#remaining + 1)
                        fit_count = first_char_end - 1 
                    end
                    local segment = remaining:sub(1, fit_count)
                    remaining = remaining:sub(fit_count + 1)
                    table.insert(visual_lines, {text = segment, start_idx = line_start, is_wrapped = (#remaining > 0)})
                    line_start = line_start + fit_count
                end
            end
            raw_pos = raw_pos + #ln + 1
        end
        if #visual_lines == 0 then table.insert(visual_lines, {text = "", start_idx = 0}) end
    end

    -- --- INTERACTION ---
    local hover = UI_STATE.window_focused and (gfx.mouse_x >= x and gfx.mouse_x <= x + w and gfx.mouse_y >= y and gfx.mouse_y <= y + h)
    
    local function get_cursor_from_xy(mx, my)
        if not is_multiline then
            local rel_x = mx - (x + padding) + state.scroll
            return get_char_index_at_x(state.text, rel_x)
        else
            local rel_y = my - (y + padding) + state.scroll
            local v_idx = math.floor(rel_y / line_h) + 1
            v_idx = math.max(1, math.min(v_idx, #visual_lines))
            local v_line = visual_lines[v_idx]
            local rel_x = mx - (x + padding)
            local char_idx = get_char_index_at_x(v_line.text, rel_x)
            return v_line.start_idx + char_idx
        end
    end

    if gfx.mouse_cap == 1 then
        if UI_STATE.last_mouse_cap == 0 and hover then
            -- Check for interaction suppression (e.g., preventing bleed-through from opening click)
            if state.interaction_start_time and reaper.time_precise() < state.interaction_start_time then
                -- Ignore this click
            else
                state.focus = true
                local idx = get_cursor_from_xy(gfx.mouse_x, gfx.mouse_y)
                local now = reaper.time_precise()
            if (now - (state.last_click_time or 0)) < 0.3 then
                state.last_click_state = (state.last_click_state or 0) + 1
            else
                state.last_click_state = 1
            end
            state.last_click_time = now
            
            if state.last_click_state == 1 then
                state.cursor, state.anchor = idx, idx
            elseif state.last_click_state == 2 then
                local s, e = idx, idx
                while s > 0 do
                    local c = state.text:sub(s, s)
                    if c:match("[%s%p]") then break end
                    s = s - 1
                end
                while e < #state.text do
                    local c = state.text:sub(e+1, e+1)
                    if c:match("[%s%p]") then break end
                    e = e + 1

                    end
                    state.cursor, state.anchor = e, s
                elseif state.last_click_state >= 3 then
                    state.cursor, state.anchor = #state.text, 0
                end
            end

    elseif state.focus and UI_STATE.last_mouse_cap == 1 then
        -- Check for interaction suppression
        if state.interaction_start_time and reaper.time_precise() < state.interaction_start_time then
            -- Ignore drag during suppression period
        else
            -- Dragging
            if (state.last_click_state or 0) >= 3 then
                -- Triple click (Select All) should adhere to full selection even if mouse jitters
                state.cursor, state.anchor = #state.text, 0
            elseif (state.last_click_state or 0) == 2 then
                -- Double click (Word Select) - Snap to word boundaries
                local raw = get_cursor_from_xy(gfx.mouse_x, gfx.mouse_y)
                if raw >= state.anchor then
                    -- Dragging Right: Snap to End of Word
                    local e = raw
                    while e < #state.text do
                        local c = state.text:sub(e+1, e+1)
                        if c:match("[%s%p]") then break end
                        e = e + 1
                    end
                    state.cursor = e
                else
                    -- Dragging Left: Snap to Start of Word
                    local s = raw
                    while s > 0 do
                        local c = state.text:sub(s, s)
                        if c:match("[%s%p]") then break end
                        s = s - 1
                    end
                    state.cursor = s
                end
            else
                state.cursor = get_cursor_from_xy(gfx.mouse_x, gfx.mouse_y)
            end
        end

        elseif not hover and UI_STATE.last_mouse_cap == 0 then
            -- Guard: Don't lose focus if clicking inside the AI modal OR if ai_modal was JUST shown (prevents closing focus on suggestion selection)
            local in_ai = false
            if ai_modal and ai_modal.show and ai_modal.x then
                if gfx.mouse_x >= ai_modal.x and gfx.mouse_x <= ai_modal.x + ai_modal.w and
                   gfx.mouse_y >= ai_modal.y and gfx.mouse_y <= ai_modal.y + ai_modal.h then
                    in_ai = true
                end
            end
            
            -- Also check if we just clicked the AI button itself to prevent focus flickers
            local ai_btn_hover = UI_STATE.window_focused and (gfx.mouse_x >= ai_modal.anchor_x - 40 and gfx.mouse_x <= ai_modal.anchor_x and 
                                  gfx.mouse_y >= ai_modal.anchor_y - 24 and gfx.mouse_y <= ai_modal.anchor_y)

            if not in_ai and not ai_btn_hover then
                state.focus = false
            end
        end
    elseif (gfx.mouse_cap & 2 == 2) and (UI_STATE.last_mouse_cap & 2 == 0) and hover and not UI_STATE.mouse_handled then
        -- Context Menu (Right Click) - Rising Edge Detection
        UI_STATE.mouse_handled = true -- Prevent global context menu from opening
        state.focus = true
        gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
        local sel_min, sel_max = math.min(state.cursor, state.anchor), math.max(state.cursor, state.anchor)
        local has_sel = sel_min ~= sel_max
        
        -- Build Dynamic Menu
        local dict_label = has_sel and "Шукати в ГОРОСі" or "Знайти нове слово в ГОРОСі"
        local menu_items = { "Вирізати", "Копіювати", "Вставити", "Виділити все", "", dict_label, "", "Озвучити", "Озвучити та зберегти", "", ">Змінити голос" }
        for _, v_name in ipairs(cfg.tts_voices_order) do
            local check = (v_name == cfg.tts_voice) and "• " or ""
            table.insert(menu_items, check .. (v_name:gsub("|", "||")))
        end
        table.insert(menu_items, "<")
        
        local menu_str = table.concat(menu_items, "|")
        local ret = gfx.showmenu(menu_str)
        
        -- Force update UI_STATE.last_mouse_cap to current state to prevent immediate re-trigger loop 
        -- if the user is somehow still holding the button (though showmenu blocks).
        UI_STATE.last_mouse_cap = gfx.mouse_cap 
        
        if ret == 1 and has_sel then
            -- Cut
            set_clipboard(state.text:sub(sel_min + 1, sel_max))
            state.text = state.text:sub(1, sel_min) .. state.text:sub(sel_max + 1)
            state.cursor, state.anchor = sel_min, sel_min
            record_field_history(state)
        elseif ret == 2 and has_sel then
            -- Copy
            set_clipboard(state.text:sub(sel_min + 1, sel_max))
        elseif ret == 3 then
            -- Paste
            local clip = get_clipboard()
            if clip and clip ~= "" then
                if not is_multiline then clip = clip:gsub("\n", " "):gsub("\r", "") end
                if has_sel then
                    state.text = state.text:sub(1, sel_min) .. clip .. state.text:sub(sel_max + 1)
                    state.cursor = sel_min + #clip
                else
                    state.text = state.text:sub(1, state.cursor) .. clip .. state.text:sub(state.cursor + 1)
                    state.cursor = state.cursor + #clip
                end
                state.anchor = state.cursor
                record_field_history(state)
            end
        elseif ret == 4 then
            -- Select All
            state.anchor = 0
            state.cursor = #state.text
        elseif ret == 5 then
            -- Search in GOROH
            if has_sel then
                local target = state.text:sub(sel_min + 1, sel_max)
                if target and target ~= "" then
                    trigger_dictionary_lookup(target)
                end
            else
                local ok, input = reaper.GetUserInputs("ГОРОХ", 1, "Слово для пошуку:,extrawidth=200", "")
                if ok and input ~= "" then
                    trigger_dictionary_lookup(input)
                end
            end
        elseif ret == 6 or ret == 7 then
            -- Speak (Озвучити) / Speak & Save
            local text_to_speak = ""
            if not has_sel then
                -- Select All first
                state.anchor = 0
                state.cursor = #state.text
                text_to_speak = state.text
            else
                text_to_speak = state.text:sub(sel_min + 1, sel_max)
            end

            if text_to_speak ~= "" then
                play_tts_audio(text_to_speak, ret == 7)
            end
        elseif ret >= 8 and ret < 8 + #cfg.tts_voices_order then
            -- Change TTS Voice
            cfg.tts_voice = cfg.tts_voices_order[ret - 7]
            save_settings()
            show_snackbar("Голос змінено на " .. cfg.tts_voice)
        end
    end
    
    if state.focus then process_input_events(input_queue, state, is_multiline, visual_lines) end

    -- Scroll Handling
    if hover and gfx.mouse_wheel ~= 0 then
        local scroll_step = (gfx.mouse_wheel / 120) * line_h * 3
        if is_multiline then
            state.target_scroll = state.target_scroll - scroll_step
            local max_s = math.max(0, (#visual_lines * line_h) - (h - padding*2))
            state.target_scroll = math.max(0, math.min(state.target_scroll, max_s))
        else
            state.target_scroll = state.target_scroll - (gfx.mouse_wheel * 0.5)
            local txt_w = gfx.measurestr(state.text)
            local max_s = math.max(0, txt_w - text_w)
            state.target_scroll = math.max(0, math.min(state.target_scroll, max_s))
        end
        state.suppress_auto_scroll_until = reaper.time_precise() + 1.0
        gfx.mouse_wheel = 0 -- Consume
    end

    -- Smooth Interpolation
    local s_diff = state.target_scroll - state.scroll
    if math.abs(s_diff) > 0.1 then
        state.scroll = state.scroll + s_diff * 0.4
    else
        state.scroll = state.target_scroll
    end

    -- --- RENDERING ---
    local prev_dest = gfx.dest
    gfx.setimgdim(98, w, h)
    gfx.dest = 98
    set_color(state.focus and UI.C_BG or UI.C_TAB_INA)
    gfx.rect(0, 0, w, h, 1)

    if #state.text == 0 and not state.focus then
        set_color(UI.C_ED_GUTTER)
        gfx.x, gfx.y = padding, is_multiline and padding or (h - line_h) / 2
        gfx.drawstr(placeholder or "")
    else
        local sel_min, sel_max = math.min(state.cursor, state.anchor), math.max(state.cursor, state.anchor)
        local has_sel = (sel_min ~= sel_max)
        
        -- Director mode highlight detection ([Actor])
        local bracket_end = -1
        if is_director_mode and state.text and state.text:sub(1,1) == "[" then
            bracket_end = state.text:find("]") or -1
        end

        if not is_multiline then
            -- Single line logic
            local cx = gfx.measurestr(state.text:sub(1, state.cursor))
            if state.focus and reaper.time_precise() > state.suppress_auto_scroll_until then
                if cx < state.target_scroll then state.target_scroll = cx
                elseif cx > state.target_scroll + text_w then state.target_scroll = cx - text_w end
            end
            if not state.focus then state.target_scroll = 0 end

            local ty = (h - line_h) / 2
            
            -- Director mode highlight for single line
            if is_director_mode and bracket_end > 0 then
                local b_end = math.min(#state.text, bracket_end)
                local bw = gfx.measurestr(state.text:sub(1, b_end))
                set_color(UI.C_ED_HILI_G) -- Subtle green highlight
                gfx.rect(padding - state.scroll - S(2), ty - S(1), bw + S(4), line_h + S(2), 1)
            end

            if has_sel then
                local w_before = gfx.measurestr(state.text:sub(1, sel_min))
                local w_sel = gfx.measurestr(state.text:sub(sel_min + 1, sel_max))
                set_color(UI.C_ED_HILI_B)
                gfx.rect(padding + w_before - state.scroll, S(3), w_sel, h - S(6), 1)
            end
            set_color(UI.C_TXT)
            gfx.x, gfx.y = padding - state.scroll, ty
            gfx.drawstr(state.focus and state.text or fit_text_width(state.text, text_w))
            
            if state.focus and (math.floor(reaper.time_precise() * 2) % 2 == 0) then
                local cur_x = padding + cx - state.scroll
                set_color(UI.C_TXT)
                gfx.line(cur_x, S(3), cur_x, h - S(3))
            end
        else
            -- Multiline logic
            local total_h = #visual_lines * line_h
            if state.focus and reaper.time_precise() > state.suppress_auto_scroll_until then
                local cur_vi = 1
                for i, v in ipairs(visual_lines) do if state.cursor >= v.start_idx then cur_vi = i end end
                local cur_y = (cur_vi - 1) * line_h
                if cur_y < state.target_scroll then state.target_scroll = cur_y
                elseif cur_y + line_h > state.target_scroll + h - padding*2 then state.target_scroll = cur_y + line_h - (h - padding*2) end
            end

            for i, v_line in ipairs(visual_lines) do
                local ly = padding + (i-1) * line_h - state.scroll
                if ly + line_h > 0 and ly < h then
                    local l_start, l_end = v_line.start_idx, v_line.start_idx + #v_line.text
                    if has_sel then
                        local s_start, s_end = math.max(l_start, sel_min), math.min(l_end, sel_max)
                        if s_start < s_end then
                            local x1 = padding + gfx.measurestr(v_line.text:sub(1, s_start - l_start))
                            local sw = gfx.measurestr(v_line.text:sub(s_start - l_start + 1, s_end - l_start))
                            set_color(UI.C_ED_HILI_B)
                            gfx.rect(x1, ly, sw, line_h, 1)
                        end
                        if not v_line.is_wrapped and sel_max > l_end and sel_min <= l_end then
                            set_color(UI.C_ED_HILI_B)
                            gfx.rect(padding + gfx.measurestr(v_line.text), ly, S(5), line_h, 1)
                        end
                    end
                    -- Director mode syntax highlighting ([Actor])
                    if is_director_mode and bracket_end > 0 then
                        local l_start, l_end = v_line.start_idx, v_line.start_idx + #v_line.text
                        local b_start, b_end = math.max(l_start, 0), math.min(l_end, bracket_end)
                        if b_start < b_end then
                            local x1 = padding + gfx.measurestr(v_line.text:sub(1, b_start - l_start))
                            local x2 = padding + gfx.measurestr(v_line.text:sub(1, b_end - l_start))
                            set_color(UI.C_ED_HILI_G) -- Subtle green highlight
                            gfx.rect(x1 - S(2), ly - S(1), (x2 - x1) + S(4), line_h + S(2), 1)
                        end
                    end

                    set_color(UI.C_TXT)
                    gfx.x, gfx.y = padding, ly
                    gfx.drawstr(v_line.text)
                    
                    if state.focus and (math.floor(reaper.time_precise() * 2) % 2 == 0) then
                        if state.cursor >= l_start and state.cursor <= l_end then
                            -- Check if cursor is at the very end of a wrapped line (should stay on this line, but if empty, it's ambiguous)
                            local show_here = true
                            if state.cursor == l_end and v_line.is_wrapped then show_here = false end
                            if show_here then
                                local cx = padding + gfx.measurestr(v_line.text:sub(1, state.cursor - l_start))
                                set_color(UI.C_TXT)
                                gfx.line(cx, ly, cx, ly + line_h)
                            end
                        elseif state.cursor == l_start and i == #visual_lines and #v_line.text == 0 then
                            -- Empty last line
                            set_color(UI.C_TXT)
                            gfx.line(padding, ly, padding, ly + line_h)
                        end
                    end
                end
            end
        end
    end
    if state.text ~= before_text then
        record_field_history(state)
    end

    gfx.dest = prev_dest
    gfx.blit(98, 1, 0, 0, 0, w, h, x, y, w, h)
    set_color(state.focus and {0.7, 0.7, 1.0} or UI.C_BTN_H)
    gfx.rect(x, y, w, h, 0)
end

--- Draw and handle text editor modal dialog
--- @param input_queue table Input events queue
--- @return boolean True if editor consumed the input
local function draw_text_editor(input_queue)
    if not text_editor_state.active then return false end
    
    local content_changed = false
    
    -- AI Modal Input Pass
    if draw_ai_modal(true) then 
        content_changed = true 
        -- Update history via the new unified helper for AI changes
        record_field_history(text_editor_state)
        -- Reset auto-scroll suppression for immediate feedback
        text_editor_state.suppress_auto_scroll_until = 0
    end
    
    -- Darken background
    gfx.set(0, 0, 0, 0.7)
    gfx.rect(0, 0, gfx.w, gfx.h, 1)
    
    -- Editor box
    local pad = 25
    local box_x, box_y = pad, pad
    local box_w, box_h = gfx.w - pad * 2, gfx.h - pad * 2
    
    set_color(UI.C_TAB_INA)
    gfx.rect(box_x, box_y, box_w, box_h, 1)
    
    -- AI Button dimensions
    local ai_btn_w, ai_btn_h = S(40), S(24)
    local ai_btn_x, ai_btn_y = box_x + box_w - ai_btn_w - S(10), box_y + S(8)

    -- AI History Button
    local hist_btn_w, hist_btn_h = S(30), S(24)
    local hist_btn_x, hist_btn_y = box_x + box_w - ai_btn_w - hist_btn_w - S(15), box_y + S(8)

    -- Title with Truncation
    set_color(UI.C_TXT)
    gfx.setfont(F.std)
    gfx.x, gfx.y = box_x + S(10), box_y + S(10)
    
    local title_txt = "Редагування тексту (Enter = новий рядок, Esc = скасування)"
    local limit_x = hist_btn_x - S(10)
    local max_title_w = limit_x - gfx.x
    
    local tw, th = gfx.measurestr(title_txt)
    if tw > max_title_w then
        while tw > max_title_w and #title_txt > 0 do
            title_txt = title_txt:sub(1, -2)
            tw = gfx.measurestr(title_txt .. "...")
        end
        title_txt = title_txt .. "..."
    end
    gfx.drawstr(title_txt)
    
    if #ai_modal.history > 0 then
        if btn(hist_btn_x, hist_btn_y, hist_btn_w, hist_btn_h, "#") then
            -- Build history text for display
            reaper.ShowConsoleMsg("")
            local history_text = "=== ІСТОРІЯ AI ОПЕРАЦІЙ ===\n\n"
            for i = #ai_modal.history, 1, -1 do
                local entry = ai_modal.history[i]
                history_text = history_text .. string.format("[%s] %s\n\n", entry.timestamp, entry.task)
                history_text = history_text .. "ОРИГІНАЛЬНИЙ ТЕКСТ:\n" .. entry.original .. "\n\n"
                history_text = history_text .. "ВАРІАНТИ ВІД GEMINI:\n"
                for j, variant in ipairs(entry.variants) do
                    history_text = history_text .. string.format("%d. %s\n", j, variant)
                end
                history_text = history_text .. "\n" .. string.rep("=", 80) .. "\n\n"
            end
            reaper.ShowConsoleMsg(history_text)
            if reaper.GetToggleCommandState(40004) == 0 then reaper.Main_OnCommand(40004, 0) end
        end
    end

    -- AI Button interaction
    local sel_min = math.min(text_editor_state.cursor, text_editor_state.anchor)
    local sel_max = math.max(text_editor_state.cursor, text_editor_state.anchor)
    local has_sel = (sel_min ~= sel_max)

    if btn(ai_btn_x, ai_btn_y, ai_btn_w, ai_btn_h, "AI") then
        if not cfg.gemini_api_key or cfg.gemini_api_key == "" or (cfg.gemini_key_status ~= 200 and cfg.gemini_key_status ~= 429) then
            show_snackbar("Ключ Gemini API не валідний або відсутній", "error")
        else
            if has_sel then
                -- Word wrap selection logic
                local word_pattern = "[%a\128-\255\'%-]+[\128-\255]*"
                local new_min, new_max = sel_min, sel_max
                local pos = 1
                while pos <= #text_editor_state.text do
                    local s, e = text_editor_state.text:find(word_pattern, pos)
                    if not s then break end
                    local w_min, w_max = s - 1, e
                    if w_max > sel_min and w_min < sel_max then
                        if w_min < new_min then new_min = w_min end
                        if w_max > new_max then new_max = w_max end
                    end
                    pos = e + 1
                end
                if text_editor_state.cursor > text_editor_state.anchor then
                    text_editor_state.cursor, text_editor_state.anchor = new_max, new_min
                else
                    text_editor_state.cursor, text_editor_state.anchor = new_min, new_max
                end
                sel_min, sel_max = new_min, new_max
            end

            local function init_selection(s_min, s_max)
                ai_modal.text = text_editor_state.text:sub(s_min + 1, s_max)
                ai_modal.sel_min, ai_modal.sel_max = s_min, s_max
                ai_modal.current_step = "SELECT_TASK"
                ai_modal.suggestions = {}
                ai_modal.scroll = 0
                ai_modal.anchor_x, ai_modal.anchor_y = ai_btn_x, ai_btn_y + ai_btn_h
                ai_modal.show = true
            end
            
            if has_sel and sel_max - sel_min < 8 then
                show_snackbar("Треба виділити більше тексту", "error")
            elseif has_sel then
                if (ai_modal.text ~= "") and sel_min == ai_modal.sel_min and sel_max == ai_modal.sel_max then
                    ai_modal.show = true
                else
                    init_selection(sel_min, sel_max)
                end
            elseif (ai_modal.text ~= "") then
                text_editor_state.cursor, text_editor_state.anchor = ai_modal.sel_max, ai_modal.sel_min
                ai_modal.anchor_x, ai_modal.anchor_y = ai_btn_x, ai_btn_y + ai_btn_h
                ai_modal.show = true
            elseif #text_editor_state.text > 0 then
                text_editor_state.anchor, text_editor_state.cursor = 0, #text_editor_state.text
                init_selection(0, #text_editor_state.text)
            else
                show_snackbar("Треба виділити цільовий текст для роботи", "error")
            end
        end
    end
    
    local text_x, text_y = box_x + S(10), box_y + S(35)
    local text_w, text_h = box_w - S(20), box_h - S(80)

    -- Main editor interaction
    ui_text_input(text_x, text_y, text_w, text_h, text_editor_state, "Введіть текст...", input_queue, true, text_editor_state.is_director_mode)

    local btn_y = box_y + box_h - S(40)
    if btn(box_x + S(10), btn_y, S(90), S(30), "Скасування") then 
        text_editor_state.active = false
        ai_modal.text = ""
        ai_modal.suggestions = {}
        ai_modal.history = {}
    end
    if btn(box_x + box_w - S(90), btn_y, S(80), S(30), "Зберегти") then
        if text_editor_state.callback then text_editor_state.callback(text_editor_state.text) end
        text_editor_state.active = false
        ai_modal.text = ""
        ai_modal.suggestions = {}
        ai_modal.history = {}
    end

    -- Global Shortcuts Pass (Fallback for when input focus is lost)
    if input_queue then
        local cap = gfx.mouse_cap
        local is_ctrl = (cap & 4 == 4)
        local is_cmd = (cap & 32 == 32)
        local is_shift = (cap & 8 == 8)
        local is_mod = (is_ctrl or is_cmd)
        
        for _, char in ipairs(input_queue) do
            -- Undo / Redo (Fallback for focus loss)
            if not text_editor_state.focus then -- Only run here if ui_text_input didn't already process it
                if (char == 26) or (is_mod and (char == 122 or char == 90)) then
                    if text_editor_state.history and text_editor_state.history_pos then
                        if is_shift then
                            if text_editor_state.history_pos < #text_editor_state.history then
                                text_editor_state.history_pos = text_editor_state.history_pos + 1
                                local snap = text_editor_state.history[text_editor_state.history_pos]
                                text_editor_state.text, text_editor_state.cursor, text_editor_state.anchor = snap.text, snap.cursor, snap.anchor
                                content_changed = true
                            end
                        else
                            if text_editor_state.history_pos > 1 then
                                text_editor_state.history_pos = text_editor_state.history_pos - 1
                                local snap = text_editor_state.history[text_editor_state.history_pos]
                                text_editor_state.text, text_editor_state.cursor, text_editor_state.anchor = snap.text, snap.cursor, snap.anchor
                                content_changed = true
                            end
                        end
                    end
                elseif is_mod and (char == 121 or char == 89) then -- Redo (Ctrl+Y)
                    if text_editor_state.history and text_editor_state.history_pos and text_editor_state.history_pos < #text_editor_state.history then
                        text_editor_state.history_pos = text_editor_state.history_pos + 1
                        local snap = text_editor_state.history[text_editor_state.history_pos]
                        text_editor_state.text, text_editor_state.cursor, text_editor_state.anchor = snap.text, snap.cursor, snap.anchor
                        content_changed = true
                    end
                end
            end
        end
    end

    -- Draw pass for AI modal
    draw_ai_modal(false)
    
    return true
end

-- --- Search Item Modal ---

local SEARCH_ITEM = {
    show = false,
    input = { text = "", focus = false, cursor = 1, anchor = 1, scroll = 0 },
    results = nil,
    loading = false,
    scroll_y = 0,
    target_scroll_y = 0,
    last_query = "",
    -- Player State
    current_preview = nil,
    current_item = nil,
    preview_length = 0,
    player_paused = false,
    pause_pos = 0
}

function SEARCH_ITEM.open()
    SEARCH_ITEM.show = true
    SEARCH_ITEM.input.focus = false
    SEARCH_ITEM.results = nil
    
    local play_state = reaper.GetPlayState()
    local cur_pos = (play_state & 1 == 1) and reaper.GetPlayPosition() or reaper.GetCursorPosition()
    
    for _, rgn in ipairs(regions) do
        if cur_pos >= rgn.pos and cur_pos < rgn.rgnend then
            local t = rgn.name:gsub("{.-}", ""):gsub("\\n", " "):gsub("\n", " "):gsub("  +", " "):gsub("^%s+", ""):gsub("%s+$", "")
            SEARCH_ITEM.input.text = t
            local l = utf8.len(t) or #t
            SEARCH_ITEM.input.cursor = l + 1
            SEARCH_ITEM.input.anchor = l + 1
            break
        end
    end
end

function SEARCH_ITEM.pick_folder(callback)
    if reaper.JS_Dialog_BrowseForFolder then
        local retval, folder = reaper.JS_Dialog_BrowseForFolder("Виберіть папку для пошуку проектів", cfg.search_item_path or "")
        if retval == 1 and folder ~= "" then
            cfg.search_item_path = folder
            save_settings()
            if callback then callback() end
            return true
        end
    else
        show_snackbar("Потрібен JS_API для вибору папки", "error")
    end
    return false
end

function SEARCH_ITEM.perform_search()
    local q = SEARCH_ITEM.input.text
    if q == "" then return end

    if not cfg.search_item_path or cfg.search_item_path == "" then
        SEARCH_ITEM.pick_folder(function()
            SEARCH_ITEM.perform_search()
        end)
        return
    end

    SEARCH_ITEM.last_query = q
    SEARCH_ITEM.loading = true
    
    local info = debug.getinfo(1, 'S')
    local path = info.source:match("@?(.*)")
    local dir = path:match("(.*[/\\])")
    
    if not dir then
        show_snackbar("Помилка шляху: " .. tostring(path), "error")
        SEARCH_ITEM.loading = false
        return
    end

    local separator = package.config:sub(1,1)
    local python_tool = dir .. "stats" .. separator .. "subass_search.py"
    local search_item_path = cfg.search_item_path
    
    local is_windows = reaper.GetOS():match("Win") ~= nil
    local py_exe = is_windows and (OTHER.rec_state.python.executable or "python") or "python3"
    
    local cmd = string.format('%s "%s" "%s" "%s"', py_exe, python_tool, q:gsub('"', '\\"'), search_item_path)
    
    run_async_command(cmd, function(out)
        SEARCH_ITEM.loading = false
        if out and out ~= "" then
            local status, data = pcall(function() return STATS.json_decode(out) end)
            if status and type(data) == "table" then
                SEARCH_ITEM.results = data
            else
                SEARCH_ITEM.results = {}
            end
        else
            SEARCH_ITEM.results = {}
        end
        SEARCH_ITEM.scroll_y = 0
        SEARCH_ITEM.target_scroll_y = 0
    end, false, "Пошук...")
end

function SEARCH_ITEM.play_item(item, from_pos)
    -- Cleanup any leftover hidden track from the failed experiment
    local tr_count = reaper.CountTracks(0)
    for i = tr_count - 1, 0, -1 do
        local tr = reaper.GetTrack(0, i)
        local _, name = reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
        if name == "Subass Preview" then reaper.DeleteTrack(tr) end
    end

    if SEARCH_ITEM.current_preview and reaper.CF_Preview_Stop then
        reaper.CF_Preview_Stop(SEARCH_ITEM.current_preview)
        SEARCH_ITEM.current_preview = nil
    end
    
    if not item or not item.file_path then 
        SEARCH_ITEM.current_item = nil
        SEARCH_ITEM.player_paused = false
        SEARCH_ITEM.pause_pos = 0
        SEARCH_ITEM.play_start_time = nil
        return 
    end
    
    local clean_path = item.file_path:gsub("\\", "/")
    
    -- Verify path
    local f = io.open(clean_path, "r")
    if not f then
        show_snackbar("Файл не знайдено", "error")
        return
    end
    f:close()

    local pcm_source = reaper.PCM_Source_CreateFromFile(clean_path)
    if not pcm_source then
        show_snackbar("Не вдалося відкрити аудіо джерело", "error")
        return
    end

    if reaper.CF_CreatePreview and reaper.CF_Preview_Play then
        local preview = reaper.CF_CreatePreview(pcm_source)
        if preview then
            local start_pos = from_pos or item.pos or 0
            local length = item.length or reaper.GetMediaSourceLength(pcm_source)
            
            -- Simplest possible approach: just play
            reaper.CF_Preview_Play(preview)
            
            local fname = clean_path:match("([^/\\]+)$")
            
            SEARCH_ITEM.current_preview = preview
            SEARCH_ITEM.current_source = pcm_source
            SEARCH_ITEM.current_item = item
            SEARCH_ITEM.segment_start = 0  -- Always from start for now
            SEARCH_ITEM.preview_length = length
            SEARCH_ITEM.player_paused = false
            SEARCH_ITEM.wait_frames = 0
            SEARCH_ITEM.last_tracked_pos = -1
            SEARCH_ITEM.play_start_time = reaper.time_precise()  -- Track time manually
            SEARCH_ITEM.open_time = reaper.time_precise() -- Track open time for debounce
        end
    end
end

function SEARCH_ITEM.toggle_pause()
    if not SEARCH_ITEM.current_item then return end
    
    if SEARCH_ITEM.player_paused then
        -- Resume
        SEARCH_ITEM.play_item(SEARCH_ITEM.current_item, SEARCH_ITEM.pause_pos)
    else
        -- Pause
        if reaper.CF_Preview_GetValue then
            local val = reaper.CF_Preview_GetValue(SEARCH_ITEM.current_preview, "D_POSITION")
            SEARCH_ITEM.pause_pos = type(val) == "number" and val or 0
        end
        if SEARCH_ITEM.current_preview and reaper.CF_Preview_Stop then
            reaper.CF_Preview_Stop(SEARCH_ITEM.current_preview)
        end
        SEARCH_ITEM.current_preview = nil
        SEARCH_ITEM.player_paused = true
    end
end

function SEARCH_ITEM.draw_mini_player()
    if not SEARCH_ITEM.current_item and not SEARCH_ITEM.player_paused then return end
    
    local h = S(60)  -- Reduced height
    local x, y, w = S(20), gfx.h - h - S(20), gfx.w - S(40)
    
    -- Background
    set_color(UI.C_BG, 0.98)
    gfx.rect(x, y, w, h, 1)
    set_color(UI.C_TXT, 0.2)
    gfx.rect(x, y, w, h, 0) -- border
    
    local pad = S(10)
    local btn_sz = S(40)
    local btn_x = x + pad
    local btn_y = y + pad
    
    -- Play/Pause Button
    local label = SEARCH_ITEM.player_paused and "▶" or "Ⅱ"
    if btn(btn_x, btn_y, btn_sz, btn_sz, label, UI.C_BTN, UI.C_TXT) then
        -- Debounce: prevent immediate interaction if player just opened
        if reaper.time_precise() - (SEARCH_ITEM.open_time or 0) > 0.3 then
            SEARCH_ITEM.toggle_pause()
        end
        UI_STATE.mouse_handled = true
    end
    
    -- File name
    local name_x = btn_x + btn_sz + pad
    local item = SEARCH_ITEM.current_item
    local name = item.item or item.file_path:match("([^/\\]+)$")
    gfx.setfont(F.bld)
    set_color(UI.C_TXT)
    local avail_nw = w - (name_x - x) - S(120)  -- Space for close and menu buttons
    local draw_name = fit_text_width(name, avail_nw)
    gfx.x, gfx.y = name_x, y + pad - S(2) -- Slightly higher
    gfx.drawstr(draw_name)
    
    -- Calculate playback position
    local abs_pos = 0 
    if SEARCH_ITEM.player_paused then
        abs_pos = SEARCH_ITEM.pause_pos or 0
    elseif SEARCH_ITEM.current_preview then
        if not SEARCH_ITEM.play_start_time then
            SEARCH_ITEM.play_start_time = reaper.time_precise()
        end
        
        local elapsed = reaper.time_precise() - SEARCH_ITEM.play_start_time
        abs_pos = elapsed
        
        -- Auto-stop at end (but keep player open)
        if abs_pos >= (SEARCH_ITEM.preview_length or 0) then
            if SEARCH_ITEM.current_preview and reaper.CF_Preview_Stop then
                reaper.CF_Preview_Stop(SEARCH_ITEM.current_preview)
            end
            SEARCH_ITEM.current_preview = nil
            SEARCH_ITEM.player_paused = true
            SEARCH_ITEM.pause_pos = SEARCH_ITEM.preview_length or 0
            abs_pos = SEARCH_ITEM.pause_pos
        end
    end
    
    local cur_pos = math.max(0, abs_pos - (SEARCH_ITEM.segment_start or 0))
    local display_length = SEARCH_ITEM.preview_length or 0
    
    -- Progress Bar (below file name)
    local pb_x = name_x
    local pb_y = y + pad + S(22)  -- Below file name (increased spacing)
    local pb_w = w - (pb_x - x) - S(120)
    local pb_h = S(4)
    
    set_color(UI.C_TXT, 0.2)
    gfx.rect(pb_x, pb_y, pb_w, pb_h, 1)
    
    if display_length > 0 then
        local prog = math.min(1, math.max(0, cur_pos / display_length))
        set_color(UI.C_ORANGE)
        gfx.rect(pb_x, pb_y, pb_w * prog, pb_h, 1)
    end
    
    -- Timer (below progress bar)
    local raw_timer = string.format("%s / %s", format_timestamp(cur_pos), format_timestamp(display_length))
    local timer_text = fit_text_width(raw_timer, pb_w)
    gfx.setfont(F.tip)
    set_color(UI.C_TXT, 0.5)
    gfx.x, gfx.y = pb_x, pb_y + S(8)
    gfx.drawstr(timer_text)
    
    -- Menu Button (≡)
    local menu_sz = S(30)
    local menu_x = x + w - pad - menu_sz - S(40)  -- Space for close button
    local menu_y = y + pad
    if btn(menu_x, menu_y, menu_sz, menu_sz, "≡", UI.C_BTN, UI.C_TXT) then
        local menu_str = "Вставити аудіо на доріжку||Відкрити проєкт з цим аудіо"
        local ret = gfx.showmenu(menu_str)
        
        if ret == 1 then
            -- Insert audio
            if item and item.file_path then
                reaper.InsertMedia(item.file_path, 0)
                show_snackbar("Аудіо додано", "success")
            end
        elseif ret == 2 then
            -- Open project
            if item and item.project_path then
                local target_path = item.project_path
                local target_pos = item.pos
                local target_track = item.track

                -- Definition of function to jump to position
                local function jump_to_pos()
                    if target_pos then
                        reaper.SetEditCurPos(target_pos, true, false)
                        
                        -- Try to find track and scroll to it
                        if target_track and target_track ~= "" then
                            local tr_count = reaper.CountTracks(0)
                            for i = 0, tr_count - 1 do
                                local tr = reaper.GetTrack(0, i)
                                local _, tr_name = reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
                                if tr_name == target_track then
                                    reaper.SetOnlyTrackSelected(tr)
                                    reaper.Main_OnCommand(40913, 0) -- Track: Vertical scroll to selected tracks
                                    break
                                end
                            end
                        end
                    end
                end

                if reaper.file_exists(target_path) then
                    -- Check if project is already open
                    local found_proj = nil
                    local i = 0
                    while true do
                        local proj, projfn = reaper.EnumProjects(i, "")
                        if not proj then break end
                        if projfn and projfn:gsub("\\", "/") == target_path:gsub("\\", "/") then
                            found_proj = proj
                            break
                        end
                        i = i + 1
                    end

                    if found_proj then
                        reaper.SelectProjectInstance(found_proj)
                        show_snackbar("Переключено на відкритий проєкт", "success")
                    else
                        reaper.Main_OnCommand(40859, 0) -- New project tab
                        reaper.Main_openProject(target_path)
                        show_snackbar("Проєкт відкрито", "success")
                    end
                    
                    jump_to_pos()
                else
                    local result = reaper.MB("Файл проєкту не знайдено:\n" .. target_path .. "\n\nЗнайти файл вручну?", "Помилка відкриття", 4)
                    if result == 6 then -- Yes
                        local retval, new_path = reaper.GetUserFileNameForRead(target_path, "Знайти проєкт", "rpp")
                        if retval and new_path then
                            -- Check if project is already open
                            local found_proj = nil
                            local i = 0
                            while true do
                                local proj, projfn = reaper.EnumProjects(i, "")
                                if not proj then break end
                                if projfn and projfn:gsub("\\", "/") == new_path:gsub("\\", "/") then
                                    found_proj = proj
                                    break
                                end
                                i = i + 1
                            end

                            if found_proj then
                                reaper.SelectProjectInstance(found_proj)
                                show_snackbar("Переключено на відкритий проєкт", "success")
                            else
                                reaper.Main_OnCommand(40859, 0)
                                reaper.Main_openProject(new_path)
                                show_snackbar("Проєкт відкрито", "success")
                            end
                            
                            jump_to_pos()
                        end
                    end
                end
            else
                show_snackbar("Шлях до проєкту не знайдено", "error")
            end
        end
        UI_STATE.mouse_handled = true
    end
    
    -- Close Button (×)
    local close_sz = S(30)
    local close_x = x + w - pad - close_sz
    local close_y = y + pad
    if btn(close_x, close_y, close_sz, close_sz, "x", UI.C_BTN, UI.C_TXT) then
        SEARCH_ITEM.play_item(nil)  -- Close player
        UI_STATE.mouse_handled = true
    end
end

function SEARCH_ITEM.show_item_menu(items)
    local menu_str = ""
    for i, item in ipairs(items) do
        local name = item.item or item.file_path:match("([^/\\]+)$")
        local track = item.track or ""
        local display = string.format("%s (Tr: %s)", name, track)
        menu_str = menu_str .. (i > 1 and "|" or "") .. display
    end
    
    local ret = gfx.showmenu(menu_str)
    if ret > 0 then
        SEARCH_ITEM.play_item(items[ret])
    end
end


function SEARCH_ITEM.draw_window(input_queue)
    if not SEARCH_ITEM.show then return end
    
    -- Block clicks on player area FIRST (before processing any other UI elements)
    if SEARCH_ITEM.current_item or SEARCH_ITEM.player_paused then
        local player_h = S(70)
        local player_x = S(20)
        local player_y = gfx.h - player_h - S(20)
        local player_w = gfx.w - S(40)
        
        if gfx.mouse_x >= player_x and gfx.mouse_x <= player_x + player_w and 
           gfx.mouse_y >= player_y and gfx.mouse_y <= player_y + player_h then
            if gfx.mouse_cap & 1 == 1 then  -- Left click
                UI_STATE.mouse_handled = true
            end
        end
    end
    
    -- Background overlay (Full Screen)
    set_color(UI.C_BG, 1.0)
    gfx.rect(0, 0, gfx.w, gfx.h, 1)
    
    local pad = S(20)
    
    -- 1. Calculate Header Height and res_y
    local th = S(30) -- Title height
    local input_h = S(32)
    local path_h = (cfg.search_item_path and cfg.search_item_path ~= "") and (S(14) + S(4)) or 0
    local header_h = pad + th + S(15) + input_h + S(4) + path_h + S(10)
    
    local res_y = header_h
    local res_h = gfx.h - res_y - pad
    
    -- 2. Draw Background
    set_color(UI.C_BG, 1.0)
    gfx.rect(0, 0, gfx.w, gfx.h, 1)

    -- 3. Draw Results List
    
    if SEARCH_ITEM.results then
        local rect_x, rect_y, rect_w, rect_h = pad, res_y, gfx.w - pad*2, res_h
        
        -- Measure total height
        local total_h = 0
        for _, proj in ipairs(SEARCH_ITEM.results) do
            total_h = total_h + S(30) -- Project title
            for _, m in ipairs(proj.matches) do
                total_h = total_h + S(45) -- Match row
            end
            total_h = total_h + S(10) -- Padding per project
        end
        
        -- Add bottom padding if player is visible
        if SEARCH_ITEM.current_item or SEARCH_ITEM.player_paused then
            total_h = total_h + S(90)  -- Player height (70) + spacing (20)
        end
        
        local max_scroll = math.max(0, total_h - res_h)
        if gfx.mouse_x >= rect_x and gfx.mouse_x <= rect_x + rect_w and gfx.mouse_y >= rect_y and gfx.mouse_y <= rect_y + rect_h then
            if gfx.mouse_wheel ~= 0 then
                SEARCH_ITEM.target_scroll_y = math.max(0, math.min(max_scroll, SEARCH_ITEM.target_scroll_y - gfx.mouse_wheel * 0.5))
                gfx.mouse_wheel = 0
            end
        end
        SEARCH_ITEM.scroll_y = SEARCH_ITEM.scroll_y + (SEARCH_ITEM.target_scroll_y - SEARCH_ITEM.scroll_y) * 0.3
        
        -- Draw List with Clipping
        local draw_y = res_y - math.floor(SEARCH_ITEM.scroll_y)
        
        for _, proj in ipairs(SEARCH_ITEM.results) do
            if draw_y + S(30) > res_y and draw_y < res_y + res_h then
                set_color(UI.C_TXT, 0.4)
                gfx.setfont(F.std)
                gfx.x, gfx.y = rect_x, draw_y + S(5)
                gfx.drawstr(proj.project_name:upper())
            end
            draw_y = draw_y + S(30)
            
            for _, m in ipairs(proj.matches) do
                if draw_y + S(45) > res_y and draw_y < res_y + res_h then
                    local row_y = draw_y
                    -- Background for row
                    set_color(UI.C_TXT, 0.05)
                    gfx.rect(rect_x, row_y, rect_w, S(40), 1)
                    
                    -- Play button
                    local p_btn_sz = S(30)
                    local p_btn_x = rect_x + S(5)
                    local p_btn_y = row_y + S(5)
                    if btn(p_btn_x, p_btn_y, p_btn_sz, p_btn_sz, "▶", UI.C_BTN, UI.C_ORANGE) and not UI_STATE.mouse_handled then
                        if m.items and #m.items > 0 then
                            -- Inject project path into items
                            for _, it in ipairs(m.items) do
                                it.project_path = proj.project_path
                            end

                            if #m.items == 1 then
                                SEARCH_ITEM.play_item(m.items[1])
                            else
                                SEARCH_ITEM.show_item_menu(m.items)
                            end
                        else
                            show_snackbar("Немає аудіо для цього фрагмента", "error")
                        end
                        UI_STATE.mouse_handled = true
                    end
                    
                    local content_start_x = p_btn_x + p_btn_sz + S(10)
                    
                    set_color(UI.C_ORANGE)
                    gfx.setfont(F.bld)
                    gfx.x, gfx.y = content_start_x, row_y + S(5)
                    local actor_name = m.actor
                    if #actor_name > 30 then 
                        -- Simple byte truncation for now as requested
                        actor_name = actor_name:sub(1, 27) .. "..." 
                    end
                    local disp_actor = actor_name .. ": "
                    gfx.drawstr(disp_actor)
                    
                    local actor_w = gfx.measurestr(disp_actor)
                    set_color(UI.C_TXT)
                    gfx.setfont(F.std)
                    local avail_tw = rect_w - (content_start_x - rect_x) - actor_w - S(10)
                    local clean_text = m.text:gsub("[\n\r]+", " ")
                    local draw_text = fit_text_width(clean_text, avail_tw)
                    gfx.drawstr(draw_text)
                    
                    set_color(UI.C_TXT, 0.5)
                    gfx.x, gfx.y = content_start_x, row_y + S(22)
                    gfx.setfont(F.tip)
                    gfx.drawstr(string.format("%.2f s", m.time / 1000))
                end
                draw_y = draw_y + S(45)
            end
            draw_y = draw_y + S(10)
        end
        
        -- Draw Scrollbar
        if max_scroll > 0 then
            local sb_w = S(6)
            local sb_x = gfx.w - pad/2 - sb_w
            local sb_track_h = res_h
            local sb_h = math.max(S(20), (res_h / total_h) * sb_track_h)
            local sb_y = res_y + (SEARCH_ITEM.scroll_y / max_scroll) * (sb_track_h - sb_h)
            set_color(UI.C_TXT, 0.1)
            gfx.rect(sb_x, res_y, sb_w, sb_track_h, 1)
            set_color(UI.C_TXT, 0.3)
            gfx.rect(sb_x, sb_y, sb_w, sb_h, 1)
        end
        
    elseif SEARCH_ITEM.loading then
        set_color(UI.C_TXT, 0.5)
        gfx.setfont(F.std)
        local s = "Шукаю у всіх проектах..."
        local sw, sh = gfx.measurestr(s)
        gfx.x, gfx.y = pad + (gfx.w - pad*2 - sw)/2, res_y + (res_h - sh)/2
        gfx.drawstr(s)
    elseif SEARCH_ITEM.last_query ~= "" then
        set_color(UI.C_TXT, 0.5)
        gfx.setfont(F.std)
        local s = "Нічого не знайдено"
        local sw, sh = gfx.measurestr(s)
        gfx.x, gfx.y = pad + (gfx.w - pad*2 - sw)/2, res_y + (res_h - sh)/2
        gfx.drawstr(s)
    end

    -- 4. Draw Header Overlay (draw ON TOP of results)
    set_color(UI.C_BG, 1.0)
    gfx.rect(0, 0, gfx.w, res_y, 1) -- Opaque background to hide results behind it
    
    -- Close button (Top Right)
    local close_sz = S(24)
    local close_x, close_y = gfx.w - pad - close_sz, pad
    local function close_search()
        SEARCH_ITEM.show = false
        UI_STATE.mouse_handled = true
        SEARCH_ITEM.play_item(nil) -- Stop preview
    end
    if btn(close_x, close_y, close_sz, close_sz, "X", UI.C_BTN, UI.C_TXT) then
        close_search()
    end

    -- Title
    gfx.setfont(F.title)
    set_color(UI.C_TXT)
    local title = "Глобальний пошук реплік"
    local avail_tw = close_x - pad - S(10)
    local draw_title = fit_text_width(title, avail_tw)
    gfx.x, gfx.y = pad, pad
    gfx.drawstr(draw_title)
    
    local content_y = pad + th + S(15)
    
    -- Search Input + Buttons
    local f_btn_sz = S(32)
    local s_btn_w = S(80) 
    local spacing = S(8)
    local input_w = gfx.w - pad*2 - s_btn_w - f_btn_sz - spacing*2
    
    ui_text_input(pad, content_y, input_w, input_h, SEARCH_ITEM.input, "Введіть текст для пошуку...", input_queue)
    
    -- Search Button next to input
    local s_btn_x = pad + input_w + spacing
    if btn(s_btn_x, content_y, s_btn_w, input_h, "Шукати", UI.C_SNACK_SUCCESS, UI.C_TXT) then
        SEARCH_ITEM.perform_search()
        UI_STATE.mouse_handled = true
    end

    -- Folder Button next to search
    local f_btn_x = s_btn_x + s_btn_w + spacing
    if btn(f_btn_x, content_y, f_btn_sz, input_h, "≡", UI.C_BTN, UI.C_TXT) then
        SEARCH_ITEM.pick_folder()
        UI_STATE.mouse_handled = true
    end

    -- Tooltip for folder button
    if gfx.mouse_x >= f_btn_x and gfx.mouse_x <= f_btn_x + f_btn_sz and gfx.mouse_y >= content_y and gfx.mouse_y <= content_y + input_h then
        UI_STATE.tooltip = "Вибрати папку для пошуку проектів: " .. (cfg.search_item_path or "Не вибрано")
    end
    
    if input_queue then
        for _, char in ipairs(input_queue) do
            if char == 13 and SEARCH_ITEM.input.focus then -- Enter
                SEARCH_ITEM.perform_search()
            elseif char == 27 then -- Esc
                close_search()
            end
        end
    end
    
    -- Path info
    if cfg.search_item_path and cfg.search_item_path ~= "" then
        local path_y = content_y + input_h + S(4)
        set_color(UI.C_TXT, 0.4)
        gfx.setfont(F.tip)
        local p_text = "Папка: " .. cfg.search_item_path
        local avail_pw = gfx.w - pad*2
        local draw_path = fit_text_width(p_text, avail_pw)
        gfx.x, gfx.y = pad, path_y
        gfx.drawstr(draw_path)
    end
    
    SEARCH_ITEM.draw_mini_player()
end

--- Draw dictionary modal with definitions and synonyms, ГОРОХ
--- @param input_queue table List of key inputs
local function draw_dictionary_modal(input_queue)
    if not dict_modal.show then return end
    
    local hovered_segment = nil

    -- Helper to find word under cursor within a text string (Character-accurate)
    local function get_word_at_x(text, rel_x)
        if not text or text == "" then return 0, 0, "" end
        
        local cur_x = 0
        local i = 1
        local len = #text
        
        local current_word = ""
        local word_start_x = 0
        local word_width = 0
        
        -- Helper: check if a character is a word character (letter or apostrophe)
        local function is_word_char(char)
            local clean = char:gsub(acute, "")
            -- Accept Cyrillic, Latin letters, and apostrophes
            if clean:match("[%a']") then return true end
            if clean:match("[А-Яа-яЁёІіЇїЄєҐґ]") then return true end
            return false
        end
        
        while i <= len do
            -- Decode char (bytes check)
            local b = text:byte(i)
            local char_len = 1
            if b >= 240 then char_len = 4
            elseif b >= 224 then char_len = 3
            elseif b >= 192 then char_len = 2
            end
            
            local char_start = i
            local char_end = i + char_len - 1
            local next_i = i + char_len
            
            -- Handle acute accent (combining char)
            if next_i <= len and text:byte(next_i) == 204 and text:byte(next_i+1) == 129 then
                char_end = next_i + 1
                next_i = next_i + 2
            end
            
            local char = text:sub(char_start, char_end)
            local sw = gfx.measurestr((char:gsub(acute, "")))
            
            -- Check if this is a word character or separator
            if not is_word_char(char) then
                -- Separator: check if we just finished a word
                if current_word ~= "" then
                    if rel_x >= word_start_x and rel_x < cur_x then
                        return word_start_x, word_width, current_word 
                    end
                end
                
                -- Reset for next word
                current_word = ""
                word_width = 0
                word_start_x = cur_x + sw
            else
                -- Word character
                if current_word == "" then word_start_x = cur_x end
                current_word = current_word .. char
                word_width = word_width + sw
            end
            
            cur_x = cur_x + sw
            i = next_i
        end
        
        -- Check last word
        if current_word ~= "" then
            if rel_x >= word_start_x and rel_x <= cur_x then
                return word_start_x, word_width, current_word
            end
        end
        
        return 0, 0, ""
    end

    local function process_context_menu(target_text)
        if not target_text then return end
        target_text = target_text:match("^%s*(.-)%s*$")
        if target_text == "" then return end
        
        local menu_items = { "Копіювати", "", "Шукати в ГОРОСі", "", "Озвучити", "Озвучити та зберегти", "", ">Змінити голос" }
        for _, v_name in ipairs(cfg.tts_voices_order) do
            local check = (v_name == cfg.tts_voice) and "• " or ""
            table.insert(menu_items, check .. (v_name:gsub("|", "||")))
        end
        table.insert(menu_items, "<")
        
        local menu_str = table.concat(menu_items, "|")
        gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
        local ret = gfx.showmenu(menu_str)
        UI_STATE.last_mouse_cap = gfx.mouse_cap 
        
        -- Reset dragging state and handle mouse to prevent expansion-drag on menu click
        dict_modal.selection.active = false
        UI_STATE.mouse_handled = true
        if ret == 1 then
            set_clipboard(target_text)
            show_snackbar("Текст скопійовано")
        elseif ret == 2 then
            trigger_dictionary_lookup(target_text)
        elseif ret == 3 or ret == 4 then
            play_tts_audio(target_text, ret == 4)
        elseif ret >= 5 and ret < 5 + #cfg.tts_voices_order then
            cfg.tts_voice = cfg.tts_voices_order[ret - 4]
            save_settings()
            show_snackbar("Голос змінено на " .. cfg.tts_voice)
        end
    end

    -- Check for resize (clear selection as layout shifts)
    if dict_modal.last_w ~= gfx.w or dict_modal.last_h ~= gfx.h then
        dict_modal.selection = { active = false, start_x = 0, start_y = 0, end_x = 0, end_y = 0, text = "" }
        dict_modal.last_w, dict_modal.last_h = gfx.w, gfx.h
    end

    -- Handle pending context menu from previous frame (so selection draws first)
    if dict_modal.pending_menu then
        process_context_menu(dict_modal.pending_menu)
        dict_modal.pending_menu = nil
    end

    if dict_modal.pending_empty_menu then
        dict_modal.pending_empty_menu = nil
        gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
        local ret = gfx.showmenu("Знайти нове слово в ГОРОСі")
        if ret == 1 then
            local ok, input = reaper.GetUserInputs("ГОРОХ", 1, "Слово для пошуку:,extrawidth=200", "")
            if ok and input ~= "" then
                trigger_dictionary_lookup(input)
            end
        end
    end

    -- 1. Navigation & History (Handle FIRST to ensure state is clean for layout)
    local navigated = false
    
    -- Selection and Context Menu Globals (PRE-CALCULATE)
    local mouse_x, mouse_y = gfx.mouse_x, gfx.mouse_y
    local is_lmb_down = gfx.mouse_cap & 1 == 1
    local is_lmb_released = (gfx.mouse_cap & 1 == 0) and (UI_STATE.last_mouse_cap & 1 == 1)
    local is_rmb_clicked = (gfx.mouse_cap & 2 == 2) and (UI_STATE.last_mouse_cap & 2 == 0)
    
    -- Keyboard shortcuts handling
    if input_queue then
        for i, key in ipairs(input_queue) do
            if key == 27 then -- ESC
                dict_modal.show = false
                dict_modal.selection = { active = false, start_x = 0, start_y = 0, end_x = 0, end_y = 0, text = "" }
                return
            elseif key == 8 then -- BACKSPACE
                if dict_modal.history and #dict_modal.history > 0 then
                    local prev_state = table.remove(dict_modal.history)
                    dict_modal.word = prev_state.word
                    dict_modal.content = prev_state.content
                    dict_modal.selected_tab = prev_state.selected_tab
                    dict_modal.scroll_y = prev_state.scroll_y
                    dict_modal.target_scroll_y = prev_state.target_scroll_y
                    navigated = true
                end

                dict_modal.selection = { active = false, start_x = 0, start_y = 0, end_x = 0, end_y = 0, text = "" }
            end
        end
    end

    -- Back Button Detection (Early)
    local pad = 0
    local box_x, box_y = pad, pad
    local box_w, box_h = gfx.w - pad * 2, gfx.h - pad * 2
    local btn_w, btn_h = S(85), S(25)
    local btn_back_x = box_x + box_w - S(200)
    local btn_back_y = box_y + box_h - S(35)
    
    local close_sz = S(30)
    local close_x = box_x + box_w - close_sz - S(10)
    local close_y = box_y + S(10)
    local close_hover = UI_STATE.window_focused and (gfx.mouse_x >= close_x and gfx.mouse_x <= close_x + close_sz and
                        gfx.mouse_y >= close_y and gfx.mouse_y <= close_y + close_sz)

    local is_hover_back_btn = false
    if #dict_modal.history > 0 then
        is_hover_back_btn = UI_STATE.window_focused and not close_hover and 
                            gfx.mouse_x >= btn_back_x and gfx.mouse_x <= btn_back_x + btn_w and
                            gfx.mouse_y >= btn_back_y and gfx.mouse_y <= btn_back_y + btn_h
        
        if is_hover_back_btn and is_mouse_clicked() then
            local last = table.remove(dict_modal.history)
            dict_modal.word = last.word
            dict_modal.content = last.content
            dict_modal.selected_tab = last.selected_tab
            dict_modal.scroll_y = last.scroll_y
            dict_modal.target_scroll_y = last.target_scroll_y
            navigated = true
        end
    end

    if navigated then return end -- Skip one frame to re-trigger with new state

    local function draw_dict_text_with_selection(text, use_all_caps, line_h, text_color)
        if not text or text == "" then return 0 end
        
        local d_text = text
        if use_all_caps then d_text = utf8_upper(text) end
        
        local sel = dict_modal.selection
        local has_any_sel = (sel.start_x ~= sel.end_x or sel.start_y ~= sel.end_y)
        
        if not sel.active and not has_any_sel then
            if text_color then set_color(text_color) end
            draw_text_with_stress_marks(d_text)
            return gfx.measurestr((d_text:gsub(acute, "")))
        end

        local cur_x, cur_y = gfx.x, gfx.y
        local v_scroll = dict_modal.scroll_y or 0
        local x1, y1 = sel.start_x, sel.start_y
        local x2, y2 = sel.end_x, sel.end_y
        
        -- Convert Absolute Selection to Visual for rendering check
        y1 = y1 + v_scroll
        y2 = y2 + v_scroll
        
        -- Point to tiny selection range
        if y1 == y2 then y2 = y2 + 0.001 end
        
        -- Normalize for logic: sy1 is always the top one
        local iy1, ix1, iy2, ix2
        if (y2 - y1) > line_h * 0.5 or (math.abs(y1 - y2) < line_h * 0.5 and x1 < x2) then
            iy1, ix1, iy2, ix2 = y1, x1, y2, x2
        else
            iy1, ix1, iy2, ix2 = y2, x2, y1, x1
        end

        local i = 1
        local len = #d_text
        local total_sw = 0
        
        while i <= len do
            local b = d_text:byte(i)
            local char_len = 1
            if b >= 240 then char_len = 4
            elseif b >= 224 then char_len = 3
            elseif b >= 192 then char_len = 2
            end
            
            local char = d_text:sub(i, i + char_len - 1)
            local next_i = i + char_len
            if next_i <= len and d_text:byte(next_i) == 204 and d_text:byte(next_i+1) == 129 then
                char = char .. acute
                next_i = next_i + 2
            end
            
            local sw = gfx.measurestr((char:gsub(acute, "")))
            
            local is_selected = false
            
            -- Tighten Overlap Logic
            local line_top = cur_y
            local line_bot = cur_y + line_h
            
            -- Use iy1 as TOP and iy2 as BOTTOM (already normalized)
            local iy1_in = (iy1 >= line_top and iy1 < line_bot)
            local iy2_in = (iy2 > line_top and iy2 <= line_bot)
            
            if iy1_in and iy2_in then
                -- Single line selection match
                local char_x2 = cur_x + sw
                if cur_x < ix2 and ix1 < char_x2 then is_selected = true end
            elseif iy1_in then
                -- Starts on this line
                if cur_x + sw > ix1 then is_selected = true end 
            elseif iy2_in then
                -- Ends on this line
                if cur_x < ix2 then is_selected = true end
            elseif iy1 < line_top and iy2 >= line_bot then
                -- Middle lines: spans across this line completely
                is_selected = true
            end
            
            if is_selected then
                set_color(UI.C_HILI_BLUE)
                gfx.rect(cur_x, cur_y, sw, line_h, 1)
                sel.text = sel.text .. char
            end
            
            if text_color then set_color(text_color) else set_color(UI.C_TXT) end
            gfx.x, gfx.y = cur_x, cur_y
            draw_text_with_stress_marks(char)
            
            cur_x = cur_x + sw
            total_sw = total_sw + sw
            i = next_i
        end
        
        gfx.x = cur_x
        return total_sw
    end
    
    -- Helper to check if mouse is within the current selection relative to the current line being hovered
    local function is_mouse_in_selection(line_h, line_y)
        -- Check if there is ANY selection (active or persisted)
        local sel = dict_modal.selection
        if not sel.active and (sel.start_x == sel.end_x and sel.start_y == sel.end_y) then return false end
        
        local v_scroll = dict_modal.scroll_y or 0
        local mx = gfx.mouse_x
        local iy1, ix1, iy2, ix2
        local x1, y1 = dict_modal.selection.start_x, dict_modal.selection.start_y
        local x2, y2 = dict_modal.selection.end_x, dict_modal.selection.end_y
        
        -- Convert Absolute Selection to Visual for hit detection
        y1 = y1 + v_scroll
        y2 = y2 + v_scroll
        
        -- Point to tiny selection range
        if y1 == y2 then y2 = y2 + 0.001 end
        
        -- Normalize
        if (y2 - y1) > line_h * 0.5 or (math.abs(y1 - y2) < line_h * 0.5 and x1 < x2) then
            iy1, ix1, iy2, ix2 = y1, x1, y2, x2
        else
            iy1, ix1, iy2, ix2 = y2, x2, y1, x1
        end
        
        -- Tighten Overlap Logic
        local line_top = line_y
        local line_bot = line_y + line_h
        
        local iy1_in = (iy1 >= line_top and iy1 < line_bot)
        local iy2_in = (iy2 > line_top and iy2 <= line_bot)
        
        if iy1_in and iy2_in then
            -- Entire selection is visually on this line (Single Line)
            return mx >= ix1 and mx <= ix2
        elseif iy1_in then
            -- Starts on this line
            return mx >= ix1
        elseif iy2_in then
            -- Ends on this line
            return mx <= ix2
        elseif iy1 < line_top and iy2 >= line_bot then
            -- Selection spans across this line completely
            return true
        end
        
        return false
    end
    
    -- Darken background
    gfx.set(0, 0, 0, 0.85)
    gfx.rect(0, 0, gfx.w, gfx.h, 1)
    
    -- Modal box
    set_color(UI.C_TAB_INA)
    gfx.rect(box_x, box_y, box_w, box_h, 1)

    -- Title (Clickable for TTS)
    gfx.setfont(F.lrg, "Comic Sans MS", S(35), string.byte('b'))
    local title_x = box_x + S(15)
    local title_y = box_y
    
    -- Calculate available width for title before it hits the close button
    local max_title_w = (close_x - title_x) - S(10)
    local display_word = fit_text_width(dict_modal.word, max_title_w)
    
    local title_w = gfx.measurestr(display_word)
    local title_h = gfx.texth
    
    -- Hover detection (Blocked by close button)
    local title_hover = UI_STATE.window_focused and not close_hover and 
                        gfx.mouse_x >= title_x and gfx.mouse_x <= title_x + title_w and
                        gfx.mouse_y >= title_y and gfx.mouse_y <= title_y + title_h
    
    -- Draw hover background
    if title_hover and not dict_modal.tts_loading then
        set_color(UI.C_HILI_RED)
        gfx.rect(title_x - S(5), title_y - S(2), title_w + S(10), title_h + S(4), 1)
        
        -- Support context menu for title -> Auto-select
        if is_rmb_clicked and not is_mouse_in_selection(title_h, title_y) then
            local rel_x = gfx.mouse_x - title_x
            local wx, ww, wtxt = get_word_at_x(dict_modal.word, rel_x)
            
            hovered_segment = { text = wtxt }
            -- Visual selection
            dict_modal.selection = {
                active = true,
                start_x = title_x + wx, start_y = title_y - (dict_modal.scroll_y or 0),
                end_x = title_x + wx + ww, end_y = title_y - (dict_modal.scroll_y or 0),
                text = wtxt
            }
        end
    end
    
    -- Draw title text
    set_color(title_hover and UI.C_DICT_TITLE_HOVER or UI.C_DICT_TITLE_NORM)
    gfx.x = title_x
    gfx.y = title_y
    gfx.drawstr(display_word)
    
    -- Click detection
    if title_hover and is_mouse_clicked() and not dict_modal.tts_loading then
        play_tts_audio(dict_modal.word)
    end
    
    -- Render Close Button
    if close_hover then
        set_color(UI.C_HILI_RED)
        gfx.rect(close_x, close_y, close_sz, close_sz, 1)
    end
    set_color(close_hover and UI.C_BTN_ERROR or UI.C_TXT)
    gfx.setfont(F.std)
    gfx.x = close_x + (close_sz - gfx.measurestr("X")) / 2
    gfx.y = close_y + (close_sz - gfx.texth) / 2
    gfx.drawstr("X")
    
    if close_hover and gfx.mouse_cap == 1 and UI_STATE.last_mouse_cap == 0 then
        dict_modal.show = false
        return
    end
    
    -- Tabs UI
    local categories = {"Тлумачення", "Словозміна", "Синоніми", "Фразеологія", "Слововживання"}
    local tab_x = box_x + S(15)
    local tab_y = box_y + S(55)
    local tab_w = S(125)
    
    -- Dynamic resizing if UI_STATE.tabs don't fit
    local max_width = box_w - S(50) -- Available width minus margins (increased right padding)
    local total_req_w = #categories * tab_w
    if total_req_w > max_width then
        tab_w = math.floor(max_width / #categories)
    end
    
    local tab_h = S(30)
    
    gfx.setfont(F.dict_std_sm)
    for _, cat in ipairs(categories) do
        local is_sel = (dict_modal.selected_tab == cat)
        local bx = tab_x
        local by = tab_y
        
        -- Tab button
        if is_sel then
            set_color(UI.C_DICT_TITLE_NORM)
            gfx.rect(bx, by, tab_w, tab_h, 1)
            set_color(UI.C_BG)
        else
            set_color(UI.C_TAB_INA)
            gfx.rect(bx, by, tab_w, tab_h, 1)
            set_color(UI.C_BORDER_MUTED) -- Border
            gfx.rect(bx, by, tab_w, tab_h, 0)
            set_color(UI.C_TXT)
        end
        
        -- Tab Label
        local display_text = fit_text_width(cat, tab_w - S(10))
        local tw, th = gfx.measurestr(display_text)
        gfx.x = bx + (tab_w - tw) / 2
        gfx.y = by + (tab_h - th) / 2
        gfx.drawstr(display_text)
        
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
                    -- Reset selection on tab switch
                    dict_modal.selection = {
                        active = false,
                        start_x = 0, start_y = 0,
                        end_x = 0, end_y = 0,
                        text = ""
                    }
                end
            end
        end
        
        tab_x = tab_x + tab_w + S(5)
    end
    
    -- Content Area
    local content_x = box_x + S(15)
    local content_y = tab_y + tab_h + S(25)
    local content_w = box_w - S(30)
    local content_h = box_h - (content_y - box_y) - S(5)
    
    gfx.setfont(F.dict_std)
    local line_h = gfx.texth + S(4)
    
    -- Inputs (ESC to close)
    
    -- Layout Helper (Extracted to ensure copy works on unrendered items)
    local function ensure_item_layout(item, width)
        if item.layout and item.layout.width == width then return end
        
        item.layout = { width = width }
                
        if item.is_separator then
            -- Separator Layout
            item.layout = { width = width, is_separator = true, total_h = math.ceil(S(30)) }
        elseif type(item) == "table" and item.is_table then
            -- Table Layout (Pass 1)
            local col_w = width / item.cols
            local occupancy = {} 
            local is_start = {}
            local row_heights = {}
            local row_y_pos = {}
            local running_y = 0
            
            item.layout.col_w = col_w
            item.layout.occupancy = occupancy
            item.layout.is_start = is_start
            item.layout.row_heights = row_heights
            
            for r_idx, grid_row in ipairs(item.rows) do
                occupancy[r_idx] = occupancy[r_idx] or {}
                is_start[r_idx] = is_start[r_idx] or {}
                local l_col = 1
                local max_row_h = line_h 
                
                for _, cell in ipairs(grid_row.cells) do
                    while occupancy[r_idx][l_col] do l_col = l_col + 1 end
                    
                    local cell_w = col_w * cell.colspan
                    
                    -- Wrapping
                    local wrapped = wrap_rich_text(cell.segments, cell_w - 8, F.dict_std, "Arial", S(17), cell.is_header or grid_row.is_header)
                    local needed_h = #wrapped * line_h
                    
                    local cell_info = {
                        text = cell.text, 
                        wrapped = wrapped,
                        colspan = cell.colspan,
                        rowspan = cell.rowspan,
                        is_header = cell.is_header or grid_row.is_header,
                        w = cell_w,
                        x = (l_col - 1) * col_w
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
                    
                    if cell.rowspan == 1 then
                        if needed_h > max_row_h then max_row_h = needed_h end
                    end
                    l_col = l_col + cell.colspan
                end
                row_heights[r_idx] = max_row_h + 20
                row_y_pos[r_idx] = running_y
                running_y = running_y + row_heights[r_idx]
            end
            item.layout.row_y_pos = row_y_pos
            item.layout.total_h = math.ceil(running_y + 48) -- + margin
            
        else
            -- Paragraph Layout
            local para_data = item
             -- Support legacy string
            if type(item) == "string" then para_data = {segments = {{text = item}}, indent = 0} end
            
            local segments = para_data.segments or {}
            local indent = para_data.indent or 0
            -- Fix for phantom header issue: ensure is_header is respected from data
            local is_header = para_data.is_header or false
            
            local indent_x = indent * 24
            local effective_w = width - indent_x - 100
            
            local lines_to_draw = wrap_rich_text(segments, effective_w, F.dict_std, "Arial", S(17), is_header)
            
            item.layout.wrapped = lines_to_draw
            item.layout.indent_x = indent_x
            item.layout.is_header = is_header
            local h_calc = #lines_to_draw * line_h + S(10) -- slight margin
            
            -- Headers have tighter spacing
            if is_header then h_calc = h_calc + 4 else h_calc = h_calc + 12 end
            item.layout.total_h = math.ceil(h_calc)
        end
    end

    -- On-Demand Selection Text Generation (Iterates full content)
    local function reconstruct_selection_text()
        local s = dict_modal.selection
        if (s.start_x == s.end_x and s.start_y == s.end_y) then return "" end
       
        -- Normalize selection: sy1 is top, sy2 is bottom (Use Absolute Content Space)
        local sy1, sy2 = s.start_y, s.end_y
        local sx1, sx2 = s.start_x, s.end_x
        local iy1, ix1, iy2, ix2
        if (sy2 - sy1) > line_h * 0.5 or (math.abs(sy1 - sy2) < line_h * 0.5 and sx1 < sx2) then
            iy1, ix1, iy2, ix2 = sy1, sx1, sy2, sx2
        else
            iy1, ix1, iy2, ix2 = sy2, sx2, sy1, sx1
        end
        
        -- Use normalized coordinates for the rest of the function
        sy1, sx1, sy2, sx2 = iy1, ix1, iy2, ix2
        
        -- Convert point selection to tiny range to ensure consistent logic [top, bot)
        if sy1 == sy2 then sy2 = sy2 + 0.001 end
        
        local res_text = ""
        local cur_scan_y = content_y
        
        local items = dict_modal.filtered_data or (dict_modal.content and dict_modal.content[dict_modal.selected_tab])
        if not items then return "" end

        -- Helper to parse rich lines with character accuracy
        local function get_line_selection(rich_line, line_top, line_bot, start_cx)
            -- Exclusive hit test: [top, bot)
            if sy1 >= line_bot or sy2 < line_top then return "" end
            
            local take_full = (sy1 <= line_top and sy2 >= line_bot)
            local take_from = (sy1 >= line_top and sy1 < line_bot)
            local take_to = (sy2 > line_top and sy2 <= line_bot)
            
            if not (take_full or take_from or take_to) then return "" end
            
            local line_txt = ""
            local cx = start_cx
            
            for _, seg in ipairs(rich_line) do
                if seg and seg.text then
                    local is_bld = seg.is_bold or (is_header and not seg.is_plain)
                    gfx.setfont(is_bld and F.dict_bld or F.dict_std)
                    local full_seg_w = gfx.measurestr((seg.text:gsub(acute, "")))
                    
                    if take_full then
                        line_txt = line_txt .. seg.text
                        cx = cx + full_seg_w
                    else
                        -- Character-accurate split
                        local d_text = seg.text
                        local i = 1
                        local len = #d_text
                        while i <= len do
                            local b = d_text:byte(i)
                            local char_len = 1
                            if b >= 240 then char_len = 4
                            elseif b >= 224 then char_len = 3
                            elseif b >= 192 then char_len = 2
                            end
                            local char = d_text:sub(i, i + char_len - 1)
                            local next_i = i + char_len
                            if next_i <= len and d_text:byte(next_i) == 204 and d_text:byte(next_i+1) == 129 then
                                char = char .. acute
                                next_i = next_i + 2
                            end
                            
                            local sw = gfx.measurestr((char:gsub(acute, "")))
                            local char_x2 = cx + sw
                            
                            local is_selected = false
                            if take_from and take_to then
                                -- Selection starts and ends on this line
                                if cx < sx2 and sx1 < char_x2 then is_selected = true end
                            elseif take_from then
                                -- Selection starts here (continues below)
                                if char_x2 > sx1 then is_selected = true end
                            elseif take_to then
                                -- Selection ends here (started above)
                                if cx < sx2 then is_selected = true end
                            end
                            
                            if is_selected then line_txt = line_txt .. char end
                            cx = char_x2
                            i = next_i
                        end
                    end
                end
            end
            return line_txt
        end

        for _, item in ipairs(items) do
            ensure_item_layout(item, content_w)
            local item_h = (item.layout and item.layout.total_h) or 0
            
            if sy2 >= cur_scan_y and sy1 < cur_scan_y + item_h then
                if item.is_table then
                    local L = item.layout
                    if L and L.row_heights and L.occupancy then
                        for r_idx=1, #L.row_heights do
                            local row_rel_y = L.row_y_pos[r_idx] or 0
                            local row_y = cur_scan_y + row_rel_y
                            for l_col = 1, item.cols do
                                if L.is_start[r_idx] and L.is_start[r_idx][l_col] then
                                    local cell = L.occupancy[r_idx][l_col]
                                    if cell and cell.wrapped then
                                        local total_cell_h = 0
                                        for rr = 0, cell.rowspan - 1 do total_cell_h = total_cell_h + (L.row_heights[r_idx + rr] or 0) end
                                        local ty = row_y + (total_cell_h - (#cell.wrapped * line_h))/2
                                        for l_idx, rich_line in ipairs(cell.wrapped) do
                                            local ly = ty + (l_idx - 1) * line_h
                                            
                                            local current_x = content_x + (cell.x or 0) + 4
                                            if (cell.colspan == item.cols) then -- Spanned Header Centering
                                                local tw = 0
                                                for _, seg in ipairs(rich_line) do
                                                    local bld = seg.is_bold or (cell.is_header and not seg.is_plain)
                                                    gfx.setfont(bld and F.dict_bld or F.dict_std)
                                                    tw = tw + gfx.measurestr((seg.text:gsub(acute, "")))
                                                end
                                                current_x = content_x + (cell.x or 0) + (cell.w - tw) / 2
                                            end

                                            local line_txt = get_line_selection(rich_line, ly, ly + line_h, current_x, cell.is_header)
                                           
                                            if line_txt ~= "" then
                                                res_text = res_text .. line_txt
                                                if l_idx < #cell.wrapped then
                                                    if res_text:sub(-1) ~= "-" and res_text:sub(-1) ~= " " then res_text = res_text .. " " end
                                                else
                                                    local is_last_in_row = (l_col + cell.colspan - 1 == item.cols)
                                                    if is_last_in_row then
                                                        if res_text:sub(-1) ~= "\n" then res_text = res_text .. "\n" end
                                                    else
                                                        if res_text:sub(-1) ~= " " then res_text = res_text .. " " end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                elseif item.is_separator then
                    if res_text ~= "" and res_text:sub(-1) ~= "\n" then res_text = res_text .. "\n" end
                    res_text = res_text .. "\n"
                else
                    local L = item.layout
                    if L and L.wrapped then
                        local para_y = cur_scan_y
                        for l_idx, rich_line in ipairs(L.wrapped) do
                            local ly = para_y + (l_idx - 1) * line_h
                            local line_txt = get_line_selection(rich_line, ly, ly + line_h, content_x + (L.indent_x or 0))
                           
                            if line_txt ~= "" then
                                res_text = res_text .. line_txt
                                if l_idx < #L.wrapped then
                                    if res_text:sub(-1) ~= "-" and res_text:sub(-1) ~= " " then res_text = res_text .. " " end
                                else
                                    if res_text:sub(-1) ~= "\n" then res_text = res_text .. "\n" end
                                end
                            end
                        end
                    end
                end
            end
            cur_scan_y = cur_scan_y + item_h
        end
        return res_text
    end

    if input_queue then
        for _, char in ipairs(input_queue) do
            -- Check for Ctrl+C (3) OR Command+C (Mac)
            local is_copy = (char == 3)
            
            -- Alternative: Check modifiers globally
            local is_cmd = (gfx.mouse_cap & 4 == 4)
            if is_cmd and (char == 99 or char == 67) then is_copy = true end -- c or C
            
            if char == 27 then -- ESC
                dict_modal.show = false
            elseif is_copy then
                local s = dict_modal.selection
                if (s.start_x ~= s.end_x or s.start_y ~= s.end_y) then
                    local txt = reconstruct_selection_text()
                    if txt and txt ~= "" then
                        set_clipboard(txt:match("^%s*(.-)%s*$"))
                        show_snackbar("Текст скопійовано")
                    end
                end
            end
        end
    end
    
    local in_content_area = mouse_x >= content_x and mouse_x <= content_x + content_w and
                            mouse_y >= content_y and mouse_y <= content_y + content_h

    if is_lmb_down and in_content_area and not UI_STATE.mouse_handled and not is_obstructed then
        if not dict_modal.selection.active then
            local is_shift = (gfx.mouse_cap & 8 == 8)
            local s = dict_modal.selection
            local has_sel = (s.start_x ~= s.end_x or s.start_y ~= s.end_y)
            
            if is_shift and has_sel then
                -- Shift-Click: Extend selection
                local mx, my = mouse_x, mouse_y - (dict_modal.scroll_y or 0)
                local d1 = (mx - s.start_x)^2 + (my - s.start_y)^2
                local d2 = (mx - s.end_x)^2 + (my - s.end_y)^2
                
                if d1 < d2 then
                    -- Closer to Start: anchored at End, drag new Start (which becomes visual End logic)
                    s.start_x, s.start_y = s.end_x, s.end_y
                end
                -- If closer to End: anchored at Start (default), dragging End.
                
                -- Update active state immediately
                s.active = true
                s.end_x, s.end_y = mx, my
                s.text = "" 
            else
                -- New Selection
                dict_modal.selection.active = true
                dict_modal.selection.start_x = mouse_x
                dict_modal.selection.start_y = mouse_y - (dict_modal.scroll_y or 0)
                dict_modal.selection.end_x = mouse_x
                dict_modal.selection.end_y = mouse_y - (dict_modal.scroll_y or 0)
                dict_modal.selection.text = ""
            end
        else
            dict_modal.selection.end_x = mouse_x
            dict_modal.selection.end_y = mouse_y - (dict_modal.scroll_y or 0)
            dict_modal.selection.text = ""
        end
    elseif not is_lmb_down then
        dict_modal.selection.active = false
    end

    -- Reset selection if clicking elsewhere
    if is_mouse_clicked(1) and (not in_content_area or is_obstructed) then
        dict_modal.selection = { active = false, start_x = 0, start_y = 0, end_x = 0, end_y = 0, text = "" }
    end
    
    -- Draw text within clip
    local cur_y = content_y + dict_modal.scroll_y
    local total_h = 0
    
    local is_hover_close_btn = UI_STATE.window_focused and 
                               gfx.mouse_x >= (box_x + box_w - S(100)) and gfx.mouse_x <= (box_x + box_w - S(100) + btn_w) and
                               gfx.mouse_y >= (box_y + box_h - S(35)) and gfx.mouse_y <= (box_y + box_h - S(35) + btn_h)
    
    local is_obstructed = is_hover_close_btn or is_hover_back_btn or close_hover

    local active_content = dict_modal.content[dict_modal.selected_tab]
    
    if active_content and #active_content == 0 then
        set_color(UI.C_BORDER_MUTED)
        gfx.x = content_x
        gfx.y = content_y + 20
        gfx.drawstr("Нічого немає для " .. dict_modal.selected_tab)
    elseif not active_content then
        set_color(UI.C_BORDER_MUTED)
        gfx.x = content_x
        gfx.y = content_y + 20
        gfx.drawstr("Немає даних для цієї категорії (або ГОРОХ знову впав).")
    else
        local hovered_segment = nil
        for _, item in ipairs(active_content) do
            
            -- LAYOUT PHASE (Cache results)
            ensure_item_layout(item, content_w)
            
            -- RENDER PHASE (Clipping)
            local item_h = item.layout.total_h
            local item_y = cur_y
            
            -- Check visibility
            if item_y + item_h > content_y and item_y < content_y + content_h then
                if item.is_separator then
                    -- Render Horizontal Rule
                    local line_y = item_y + item_h / 2
                    set_color(UI.C_HILI_WHITE_BRIGHT) -- Subtle white
                    gfx.line(content_x, line_y, content_x + content_w, line_y)
                elseif type(item) == "table" and item.is_table then
                    -- Render Table from Cached Layout
                    local table_start_y = item_y
                    local L = item.layout
                    
                    -- Background for top line
                    set_color(UI.C_HILI_WHITE)
                    if table_start_y > content_y and table_start_y < content_y + content_h then
                        gfx.line(content_x, table_start_y, content_x + content_w, table_start_y)
                    end
                    
                    for r_idx=1, #L.row_heights do
                        local row_rel_y = L.row_y_pos[r_idx]
                        local row_y = table_start_y + row_rel_y
                        local row_h = L.row_heights[r_idx]
                        
                        -- Row clipping optimization
                        if row_y + row_h > content_y and row_y < content_y + content_h then
                            for l_col = 1, item.cols do
                                if L.is_start[r_idx] and L.is_start[r_idx][l_col] then
                                    local cell = L.occupancy[r_idx][l_col]
                                    local cell_x = content_x + cell.x
                                    local cell_w = cell.w
                                    
                                    -- Calculate total height of this spanned cell
                                    local total_cell_h = 0
                                    for rr = 0, cell.rowspan - 1 do
                                        total_cell_h = total_cell_h + (L.row_heights[r_idx + rr] or 0)
                                    end
                                    
                                    -- Background
                                    local is_span_header = (cell.colspan == item.cols)
                                    if cell.is_header or is_span_header then
                                        set_color(UI.C_HILI_WHITE)
                                        local bg_y = math.max(row_y, content_y)
                                        local bg_h = math.min(row_y + total_cell_h, content_y + content_h) - bg_y
                                        if bg_h > 0 then gfx.rect(cell_x, bg_y, cell_w, bg_h, 1) end
                                    end
                                    
                                    -- Text
                                    local text_h = #cell.wrapped * line_h
                                    local text_y = row_y + (total_cell_h - text_h) / 2
                                    
                                    for l_idx, rich_line in ipairs(cell.wrapped) do
                                        local ly = text_y + (l_idx - 1) * line_h
                                        -- Clip individual lines
                                        if ly + line_h > content_y and ly < content_y + content_h then
                                            local current_x = cell_x + 4
                                            if is_span_header then
                                                local tw = 0
                                                for _, seg in ipairs(rich_line) do
                                                    gfx.setfont(seg.is_bold and F.dict_bld or F.dict_std)
                                                    tw = tw + gfx.measurestr((seg.text:gsub(acute, "")))
                                                end
                                                current_x = cell_x + (cell_w - tw) / 2
                                            end
                                            
                                            gfx.y = ly
                                            
                                            for _, seg in ipairs(rich_line) do
                                                if seg.is_bold or (cell.is_header and not seg.is_plain) then gfx.setfont(F.dict_bld) else gfx.setfont(F.dict_std) end
                                                local sw = gfx.measurestr((seg.text:gsub(acute, "")))
                                                local seg_hover = UI_STATE.window_focused and gfx.mouse_x >= current_x and gfx.mouse_x <= current_x + sw and gfx.mouse_y >= ly and gfx.mouse_y < ly + line_h
                                                    
                                                if seg_hover and is_rmb_clicked and not is_obstructed and not is_mouse_in_selection(line_h, ly) then
                                                    local rel_x = gfx.mouse_x - current_x
                                                    local wx, ww, wtxt = get_word_at_x(seg.text, rel_x)
                                                    
                                                    hovered_segment = { text = wtxt, word = seg.word } 
                                                    
                                                    -- Auto-select for visual feedback
                                                    dict_modal.selection = {
                                                        active = true,
                                                        start_x = current_x + wx, start_y = ly - (dict_modal.scroll_y or 0),
                                                        end_x = current_x + wx + ww, end_y = ly - (dict_modal.scroll_y or 0),
                                                        text = "" 
                                                    }
                                                end

                                                if seg.is_link then
                                                    set_color(UI.C_DICT_TITLE_NORM)
                                                    gfx.line(current_x, ly + gfx.texth, current_x + sw, ly + gfx.texth)
                                                    if is_lmb_released and not is_obstructed and seg_hover then
                                                        local s = dict_modal.selection
                                                        local dist = math.abs(s.start_x - s.end_x) + math.abs(s.start_y - s.end_y)
                                                        if dist < 3 then
                                                            dict_modal.selection = { active = false, start_x=0, start_y=0, end_x=0, end_y=0, text="" }
                                                            trigger_dictionary_lookup(seg.word)
                                                        end
                                                    end
                                                elseif not cell.is_header and not is_excluded then
                                                    local is_inflection_tab = dict_modal.selected_tab == "Словозміна"
                                                    if is_inflection_tab and seg_hover and not is_obstructed then
                                                        set_color(UI.C_HILI_RED)
                                                        gfx.rect(current_x - 2, ly - 1, sw + 4, line_h + 2, 1)
                                                        set_color(UI.C_ACCENT or UI.C_SEL)
                                                        if is_mouse_clicked(1) and (gfx.mouse_cap & 2 == 0) and not dict_modal.tts_loading then
                                                            local tts_text = seg.word
                                                            if not tts_text or tts_text == "" then tts_text = seg.text end
                                                            play_tts_audio(tts_text)
                                                        end
                                                    end
                                                end
                                                
                                                gfx.x = current_x; gfx.y = ly
                                                local eff_color = seg.is_link and UI.C_DICT_TITLE_NORM or (seg.color or UI.C_TXT)
                                                local drawn_w = draw_dict_text_with_selection(seg.text, false, line_h, eff_color)
                                                current_x = current_x + drawn_w
                                            end
                                        end
                                    end
                                    
                                    -- Borders
                                    set_color(UI.C_HILI_WHITE)
                                    local line_y = row_y + total_cell_h
                                    if line_y > content_y and line_y < content_y + content_h then gfx.line(cell_x, line_y, cell_x + cell_w, line_y) end
                                    if l_col + cell.colspan - 1 < item.cols then
                                        local vline_x = cell_x + cell_w
                                        local vline_start = math.max(row_y, content_y)
                                        local vline_end = math.min(row_y + total_cell_h, content_y + content_h)
                                        if vline_start < vline_end then gfx.line(vline_x, vline_start, vline_x, vline_end) end
                                    end
                                end
                            end
                        end
                    end
                else
                     -- Render Paragraph
                    local L = item.layout
                    local current_line_y = cur_y
                    
                    for l_idx, rich_line in ipairs(L.wrapped) do
                        if current_line_y + line_h > content_y and current_line_y < content_y + content_h then
                            local segment_x = content_x + L.indent_x
                            for _, seg in ipairs(rich_line) do
                                if seg.is_bold or (L.is_header and not seg.is_plain) then gfx.setfont(F.dict_bld) else gfx.setfont(F.dict_std) end
                                gfx.x = segment_x; gfx.y = current_line_y
                                
                                local sw = gfx.measurestr((seg.text:gsub(acute, "")))
                                
                                local seg_hover = UI_STATE.window_focused and gfx.mouse_x >= gfx.x and gfx.mouse_x <= gfx.x + sw and gfx.mouse_y >= gfx.y and gfx.mouse_y < gfx.y + line_h

                                if seg_hover and is_rmb_clicked and not is_obstructed and not is_mouse_in_selection(line_h, gfx.y) then
                                    local rel_x = gfx.mouse_x - gfx.x
                                    local wx, ww, wtxt = get_word_at_x(seg.text, rel_x)
                                    
                                    hovered_segment = { text = wtxt, word = seg.word }
                                    
                                    -- Auto-select for visual feedback
                                    dict_modal.selection = {
                                        active = true,
                                        start_x = gfx.x + wx, start_y = gfx.y - (dict_modal.scroll_y or 0),
                                        end_x = gfx.x + wx + ww, end_y = gfx.y - (dict_modal.scroll_y or 0),
                                        text = "" 
                                    }
                                end

                                if seg.is_link then
                                    set_color(UI.C_HILI_BLUE_LIGHT)
                                    gfx.line(gfx.x, gfx.y + gfx.texth, gfx.x + sw, gfx.y + gfx.texth)
                                    if is_lmb_released and not is_obstructed and seg_hover then
                                        local s = dict_modal.selection
                                        local dist = math.abs(s.start_x - s.end_x) + math.abs(s.start_y - s.end_y)
                                        if dist < 3 then
                                            dict_modal.selection = { active = false, start_x=0, start_y=0, end_x=0, end_y=0, text="" }
                                            trigger_dictionary_lookup(seg.word)
                                        end
                                    end
                                else
                                    -- Text / Selection
                                    if L.is_header and not seg.is_plain and seg.text:match("%S") then
                                        local clean_txt = seg.text:gsub(acute, ""):match("^%s*(.-)%s*$")
                                        local is_symbol = clean_txt:match("^[%p%s]+$")
                                        local is_inflection_tab = dict_modal.selected_tab == "Словозміна"
                                        if is_inflection_tab and not is_symbol and seg_hover and not is_obstructed then
                                            set_color(UI.C_HILI_RED)
                                            gfx.rect(gfx.x - 2, gfx.y - 1, sw + 4, line_h + 2, 1)
                                            set_color(UI.C_ACCENT or UI.C_SEL)
                                            if is_mouse_clicked(1) and (gfx.mouse_cap & 2 == 0) and not dict_modal.tts_loading then
                                                local tts_text = seg.word
                                                if not tts_text or tts_text == "" then tts_text = seg.text end
                                                play_tts_audio(tts_text)
                                            end
                                        end
                                    end
                                end
                                gfx.x = segment_x; gfx.y = current_line_y
                                local eff_color = seg.is_link and UI.C_DICT_TITLE_NORM or (seg.color or UI.C_TXT)
                                local drawn_w = draw_dict_text_with_selection(seg.text, false, line_h, eff_color)
                                segment_x = segment_x + drawn_w
                            end     
                        end
                        current_line_y = current_line_y + line_h
                    end
                end
            end
            
            -- Advance cursor by total height regardless of visibility
            cur_y = item_y + item.layout.total_h
            total_h = total_h + item.layout.total_h
        end
    end

    -- Trigger context menu if needed
    if is_rmb_clicked and not is_obstructed then
        local target_text = ""
        
        -- On-Demand Reconstruction for Context Menu
        if dict_modal.selection.active or (dict_modal.selection.start_x ~= dict_modal.selection.end_x) then
            local txt = reconstruct_selection_text()
            if txt and txt ~= "" then
                dict_modal.selection.text = txt -- Populate for external consumer!
                target_text = txt
            end
        end
        
        if target_text == "" and hovered_segment then
            target_text = hovered_segment.text
        end

        if target_text ~= "" then
            -- Defer menu to next frame to allow selection to draw
            dict_modal.pending_menu = target_text
        else
            -- Empty area click
            dict_modal.pending_empty_menu = true
        end
    end
    
    dict_modal.max_scroll = math.ceil(math.max(0, total_h - content_h))
    
    -- 1. Handle mouse wheel
    if gfx.mouse_wheel ~= 0 then
        dict_modal.target_scroll_y = dict_modal.target_scroll_y + (gfx.mouse_wheel > 0 and 1 or -1) * line_h * 2
        gfx.mouse_wheel = 0
    end

    -- 2. Handle scrollbar (Update target only on drag)
    local current_abs_scroll = -dict_modal.target_scroll_y
    local new_abs_scroll = draw_scrollbar(box_x + box_w - S(10), content_y, S(10), content_h, total_h, content_h, current_abs_scroll)
    
    if (gfx.mouse_cap & 1 == 1) and math.abs(new_abs_scroll - current_abs_scroll) > 0.001 then
        dict_modal.target_scroll_y = -new_abs_scroll
    end
    
    -- 3. Final Clamping
    if dict_modal.target_scroll_y > 0 then dict_modal.target_scroll_y = 0 end
    if dict_modal.target_scroll_y < -dict_modal.max_scroll then dict_modal.target_scroll_y = -dict_modal.max_scroll end

    -- 4. Smooth scroll interpolation (Apply to scroll_y for NEXT frame)
    dict_modal.scroll_y = dict_modal.scroll_y + (dict_modal.target_scroll_y - dict_modal.scroll_y) * 0.8
    if math.abs(dict_modal.target_scroll_y - dict_modal.scroll_y) < 0.5 then
        dict_modal.scroll_y = dict_modal.target_scroll_y
    end
    
    -- Bottom Buttons
    if btn(box_x + box_w - S(100), box_y + box_h - S(35), S(85), S(25), "Закрити") then
        dict_modal.show = false
    end
    
    if #dict_modal.history > 0 then
        local back_label = "Назад"
        if is_hover_back_btn then set_color(UI.C_SEL_BG) end
        if btn(btn_back_x, btn_back_y, S(85), S(25), back_label) then
            -- Logic handled at top
        end
    end
    
    -- Also close if clicked outside
    if is_mouse_clicked() then
        if gfx.mouse_x < box_x or gfx.mouse_x > box_x + box_w or
           gfx.mouse_y < box_y or gfx.mouse_y > box_y + box_h then
            dict_modal.show = false
        end
    end
end

--- Check Python version
-- @return boolean support, string version
local function get_py_ver()
    local function extract_ver(s)
        if not s or type(s) ~= "string" or s == "" then return nil end
        s = s:gsub("Python%s+", "")
        for v in s:gmatch("[%d%.]+") do
            local major, minor = v:match("(%d+)%.(%d+)")
            if major and minor then
                local n_maj, n_min = tonumber(major), tonumber(minor)
                if n_maj and n_min then
                    if n_maj > 3 or (n_maj == 3 and n_min >= 9) then return true, v end
                    return false, v
                end
            end
        end
        return nil
    end

    local os_name = reaper.GetOS()
    if os_name:match("Win") then
        -- Async check for Windows to avoid terminal popup
        local cmds = {
            { cmd = "python --version", exe = "python" },
            { cmd = "python3 --version", exe = "python3" },
            { cmd = "py -3 --version", exe = "py -3" }
        }
        
        local function try_next_cmd(idx)
            if idx > #cmds then
                OTHER.rec_state.python.version = "N/A"
                OTHER.rec_state.python.ok = false
                OTHER.rec_state.checking = false -- Check finished
                return
            end
            
            run_async_command(cmds[idx].cmd, function(output)
                local success, version = extract_ver(output)
                if success ~= nil then
                    OTHER.rec_state.python.ok = success
                    OTHER.rec_state.python.version = version
                    OTHER.rec_state.python.executable = cmds[idx].exe
                    -- Updates state if success
                    if OTHER.rec_state.python.ok then
                        OTHER.rec_state.all_ok = (OTHER.rec_state.sws and OTHER.rec_state.reapack and 
                                                    OTHER.rec_state.js_api and OTHER.rec_state.reaimgui and 
                                                    OTHER.rec_state.python.ok)
                        -- If everything became OK, we can potentially hide window or re-layout
                        if OTHER.rec_state.all_ok then OTHER.rec_state.show = false end
                    end
                    OTHER.rec_state.checking = false -- Check finished
                else
                    try_next_cmd(idx + 1)
                end
            end)
        end
            
        -- Start async chain
        OTHER.rec_state.python.version = "Checking..."
        OTHER.rec_state.checking = true -- checking started
        try_next_cmd(1)
        
        -- Return pending state
        return false, "Checking..." 
    else
        -- macOS/Linux - Keep synchronous as it works fine
        local p = "PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin "
        local cmds = {
            "/opt/homebrew/bin/python3 --version",
            "/usr/local/bin/python3 --version",
            "/usr/bin/python3 --version",
            '/bin/sh -c "' .. p .. 'python3 --version 2>&1"',
            '/bin/sh -c "' .. p .. 'python --version 2>&1"',
            "python3 --version",
            "python --version"
        }
        
        -- 1. Try ExecProcess
        for _, cmd in ipairs(cmds) do
            local _, output = reaper.ExecProcess(cmd, 2000)
            local success, version = extract_ver(output)
            if success ~= nil then 
                -- Extract executable name from command (first word)
                local exe = cmd:match("^%S+")
                -- Special handling for /bin/sh -c commands
                if cmd:find("/bin/sh -c") then
                    exe = "python3" -- Fallback for the complex shell command
                end
                OTHER.rec_state.python.executable = exe
                return success, version 
            end
        end
    
        -- 2. Try io.popen
        for _, cmd in ipairs(cmds) do
            local f = io.popen(cmd)
            if f then
                local output = f:read("*a")
                f:close()
                local success, version = extract_ver(output)
                if success ~= nil then 
                    -- Extract executable name
                    local exe = cmd:match("^/bin/sh %-c \".-([%w%d/._-]+) %-%-version")
                    if not exe then exe = cmd:match("^%S+") end
                    if cmd:find("/bin/sh -c") and not exe then exe = "python3" end
                    OTHER.rec_state.python.executable = exe
                    return success, version 
                end
            end
        end
    
        -- 3. Direct path probing
        local paths = {"/opt/homebrew/bin/python3", "/usr/local/bin/python3", "/usr/bin/python3", "/usr/bin/python"}
        for _, path in ipairs(paths) do
            local file = io.open(path, "rb")
            if file then
                file:close()
                OTHER.rec_state.python.executable = path
                local _, output = reaper.ExecProcess(path .. " --version 2>&1", 2000)
                local success, version = extract_ver(output)
                if success ~= nil then return success, version end
            end
        end
            
        return false, "N/A"
    end
end

--- Perform requirements check
local function do_check()
    OTHER.rec_state.sws = (reaper.CF_SetClipboard ~= nil)
    OTHER.rec_state.reapack = (reaper.ReaPack_GetOwner ~= nil)
    OTHER.rec_state.js_api = (reaper.JS_Window_Find ~= nil)
    OTHER.rec_state.reaimgui = (reaper.ImGui_CreateContext ~= nil)

    local py_ok, py_ver = get_py_ver()
    
    -- If sync check returned definitive result (or for non-Windows), set it. 
    -- For Windows async, 'py_ver' will be "Checking..." initially.
    if py_ver ~= "Checking..." or not reaper.GetOS():match("Win") then
        OTHER.rec_state.python.ok = py_ok
        OTHER.rec_state.python.version = py_ver
    end

    OTHER.rec_state.all_ok = (OTHER.rec_state.sws and OTHER.rec_state.reapack and 
                                OTHER.rec_state.js_api and OTHER.rec_state.reaimgui and 
                                OTHER.rec_state.python.ok)
    if not OTHER.rec_state.all_ok then OTHER.rec_state.show = true end
    OTHER.rec_state.checked = true
end

local function draw_requirements_window()
    if not OTHER.rec_state.checked then do_check() end

    -- STARTUP LOADING SCREEN (Prevent flash)
    if OTHER.rec_state.checking then
        -- Backdrop
        gfx.set(0, 0, 0, 0.7)
        gfx.rect(0, 0, gfx.w, gfx.h, 1)
        
        -- Centered Text
        gfx.setfont(F.dict_bld)
        set_color(UI.C_WHITE)
        local str = "Checking environment..."
        local sw, sh = gfx.measurestr(str)
        gfx.x, gfx.y = (gfx.w - sw)/2, (gfx.h - sh)/2
        gfx.drawstr(str)
        return
    end

    if not OTHER.rec_state.show then return end

    -- Backdrop
    gfx.set(0, 0, 0, 0.7)
    gfx.rect(0, 0, gfx.w, gfx.h, 1)
    
    -- Responsive Main Box (70% width, 80% height, with smaller min constraints)
    local bw = math.max(S(200), math.min(S(700), gfx.w * 0.85))
    local bh = math.max(S(200), math.min(S(600), gfx.h * 0.85))
    local bx, by = (gfx.w - bw) / 2, (gfx.h - bh) / 2
    
    -- Background
    set_color(UI.C_DARK_GREY)
    gfx.rect(bx, by, bw, bh, 1)

    --- Draw a bold dashed rectangle to draw attention
    dash_len = 15
    thickness = 4
    set_color(UI.C_YELLOW) -- Yellow
    
    for t = 0, thickness - 1 do
        local tx, ty, tw, th = bx - t, by - t, bw + t*2, bh + t*2
        -- Top
        for i = tx, tx + tw, dash_len * 2 do
            gfx.line(i, ty, math.min(i + dash_len, tx + tw), ty)
        end
        -- Bottom
        for i = tx, tx + tw, dash_len * 2 do
            gfx.line(i, ty + th, math.min(i + dash_len, tx + tw), ty + th)
        end
        -- Left
        for i = ty, ty + th, dash_len * 2 do
            gfx.line(tx, i, tx, math.min(i + dash_len, ty + th))
        end
        -- Right
        for i = ty, ty + th, dash_len * 2 do
            gfx.line(tx + tw, i, tx + tw, math.min(i + dash_len, ty + th))
        end
    end

    -- List Requirements
    local items = {
        { 
            name = "SWS Extension", 
            ok = OTHER.rec_state.sws, 
            info = "Необхідно для роботи з буфером обміну.\n\n**КРОК 1:** Натисніть на посилання [sws-extension.org](https://www.sws-extension.org/) і завантажте версію для вашої ОС.\n\n**КРОК 2 (WINDOWS):** Запустіть завантажений інсталятор і слідуйте інструкціям.\n\n**КРОК 2 (macOS):** Відкрийте .dmg файл. У REAPER натисніть **Options** -> **Show REAPER resource path**. Відкрийте папку **UserPlugins**. Перетягніть файл `reaper_sws...dylib` з .dmg у цю папку.\n\n**КРОК 3:** Після встановлення **ОБОВ'ЯЗКОВО** перезапустіть REAPER." 
        },
        { 
            name = "ReaPack", 
            ok = OTHER.rec_state.reapack, 
            info = "Менеджер розширень для REAPER.\n\n**КРОК 1:** Натисніть на посилання [reapack.com](https://reapack.com/) і завантажте файл для вашої ОС.\n\n**КРОК 2:** У REAPER відкрийте меню **'Options'** (вгорі) і виберіть **'Show REAPER resource path in explorer/finder'**.\n\n**КРОК 3:** У відкритій папці знайдіть або створіть папку **'UserPlugins'**.\n\n**КРОК 4:** Скопіюйте завантажений файл ReaPack (.dll для Windows або .dylib для macOS) у цю папку 'UserPlugins'.\n\n**КРОК 5:** Перезапустіть REAPER.\n\n**КРОК 6:** Перевірте, що в меню 'Extensions' з'явився пункт 'ReaPack'." 
        },
        { 
            name = "JS_ReaScriptAPI", 
            ok = OTHER.rec_state.js_api, 
            reapack_search = "js_ReaScriptAPI: API functions for ReaScripts",
            info = "Розширений API для скриптів.\n\n**ВАЖЛИВО:** Спочатку встановіть ReaPack (див. вище)!\n\n**КРОК 1:** У REAPER відкрийте меню **'Extensions'** (вгорі).\n\n**КРОК 2:** Виберіть **'ReaPack'** → **'Browse packages'**.\n\n**КРОК 3:** У вікні що відкрилося, у полі пошуку вгорі введіть **'js_ReaScriptAPI'**.\n\n**КРОК 4:** Знайдіть пакет 'js_ReaScriptAPI' у списку, клацніть по ньому **ПРАВОЮ кнопкою миші**.\n\n**КРОК 5:** У меню виберіть **'Install'**.\n\n**КРОК 6:** **ОБОВ'ЯЗКОВО** натисніть кнопку **'Apply'** внизу вікна ReaPack.\n\n**КРОК 7:** Дочекайтеся завершення встановлення (з'явиться повідомлення)." 
        },
        { 
            name = "ReaImGui", 
            ok = OTHER.rec_state.reaimgui, 
            reapack_search = "ReaImGui: ReaScript binding for Dear ImGui",
            info = "Графічний движок для інтерфейсу оверлея.\n\n**ВАЖЛИВО:** Спочатку встановіть ReaPack!\n\n**КРОК 1:** Відкрийте **'Extensions'** → **'ReaPack'** → **'Browse packages'**.\n\n**КРОК 2:** У полі пошуку введіть **'ReaImGui'** (без пробілів).\n\n**КРОК 3:** Знайдіть пакет 'ReaImGui' від 'cfillion' у списку результатів.\n\n**КРОК 4:** Клацніть по ньому **ПРАВОЮ кнопкою миші** і виберіть **'Install'**.\n\n**КРОК 5:** Натисніть кнопку **'Apply'** внизу вікна ReaPack (почекайте встановлення).\n\n**КРОК 6:** **ОБОВ'ЯЗКОВО** перезапустіть REAPER (навіть якщо не просить)." 
        },
        {
            name = "Python (>= 3.9)", 
            ok = OTHER.rec_state.python.ok, 
            info = "Поточна версія: " .. OTHER.rec_state.python.version .. ". Мова програмування для зупуску ШІ наголосів.\n\n**КРОК 1:** Натисніть [python.org](https://www.python.org/downloads/) і завантажте Python 3.11+.\n\n**КРОК 2 (WINDOWS):** Під час встановлення **ОБОВ'ЯЗКОВО** поставте галочку **'Add Python to PATH'**!\n\n**КРОК 2 (macOS):** Запустіть інсталятор і слідуйте інструкціям.\n\n**КРОК 3:** Перезапустіть REAPER.\n\n**КРОК 4:** Перевірка (не обов'язково): у терміналі введіть **'python --version'** (або **'python3 --version'**). Має бути 3.9+." 
        }
    }
    
    -- Content Area Setup (increased spacing after title)
    local view_y = by + S(60)
    local view_h = bh - S(70)
    local col_x = bx + S(40)
    
    -- Calculate layout and total height (cache layout to ensure stable rendering)
    local total_h = 0
    gfx.setfont(F.dict_std_sm)
    local wrap_w = bw - S(120)
    
    for i, item in ipairs(items) do
        local entry_base_h = S(28)  -- Icon + name height
        item.render_lines = {} -- Store laid out lines here: array of {parts}
        
        if item.ok then
            -- If requirement is met, only show header (collapsed)
            item.entry_h = entry_base_h + S(5) -- Minimal spacing
        else
            -- Split by newlines first
            local lines_raw = {}
            for line in (item.info .. "\n"):gmatch("(.-)\n") do
                table.insert(lines_raw, line)
            end
            
            -- Process each line
            for _, raw_line in ipairs(lines_raw) do
                if raw_line ~= "" then
                    -- Parse line into segments (text, links, bold)
                    local segments = {}
                    local remaining = raw_line
                    
                    while remaining ~= "" do
                        local link_start, link_end, link_text, link_url = remaining:find("%[(.-)%]%((.-)%)")
                        local bold_start, bold_end, bold_text = remaining:find("%*%*(.-)%*%*")
                        
                        local next_special = nil
                        local next_pos = math.huge
                        
                        if link_start and link_start < next_pos then
                            next_special = "link"
                            next_pos = link_start
                        end
                        if bold_start and bold_start < next_pos then
                            next_special = "bold"
                            next_pos = bold_start
                        end
                        
                        if next_special == "link" then
                            if link_start > 1 then
                                table.insert(segments, {type = "text", content = remaining:sub(1, link_start - 1)})
                            end
                            table.insert(segments, {type = "link", text = link_text, url = link_url})
                            remaining = remaining:sub(link_end + 1)
                        elseif next_special == "bold" then
                            if bold_start > 1 then
                                table.insert(segments, {type = "text", content = remaining:sub(1, bold_start - 1)})
                            end
                            table.insert(segments, {type = "bold", content = bold_text})
                            remaining = remaining:sub(bold_end + 1)
                        else
                            table.insert(segments, {type = "text", content = remaining})
                            remaining = ""
                        end
                    end
                    
                    -- Build line parts
                    local line_parts = {}
                    for _, seg in ipairs(segments) do
                        if seg.type == "text" then
                            for word in seg.content:gmatch("%S+") do
                                table.insert(line_parts, {type = "text", content = word})
                            end
                        elseif seg.type == "bold" then
                            for word in seg.content:gmatch("%S+") do
                                table.insert(line_parts, {type = "bold", content = word})
                            end
                        else
                            table.insert(line_parts, {type = "link", content = seg.text, url = seg.url})
                        end
                    end
                    
                    -- Wrap lines and store in render_lines
                    local current_line = {}
                    local current_width = 0
                    
                    for i, part in ipairs(line_parts) do
                        local part_text = part.content
                        
                        -- Measure with appropriate font
                        if part.type == "bold" then
                            gfx.setfont(F.dict_bld_sm)
                        else
                            gfx.setfont(F.dict_std_sm)
                        end
                        
                        local test_text = (#current_line > 0) and " " .. part_text or part_text
                        local test_w = gfx.measurestr(test_text)
                        
                        if current_width + test_w > wrap_w and #current_line > 0 then
                            -- Flush current line
                            table.insert(item.render_lines, current_line)
                            
                            -- Start new line
                            current_line = {part}
                            current_width = gfx.measurestr(part_text)
                        else
                            table.insert(current_line, part)
                            current_width = current_width + test_w
                        end
                    end
                    if #current_line > 0 then
                        table.insert(item.render_lines, current_line)
                    end
                else
                    -- Empty line
                    table.insert(item.render_lines, {})
                end
            end
            
            local text_h = #item.render_lines * S(22)
            
            -- Extra space for ReaPack button if available
            if OTHER.rec_state.reapack and item.reapack_search then
                text_h = text_h + S(35)
            end
            
            item.entry_h = entry_base_h + text_h + S(20)  -- Add spacing between entries
        end
        total_h = total_h + item.entry_h
    end
    
    -- Smooth Scroll Logic (similar to draw_file)
    local max_scroll = math.max(0, total_h - view_h)
    
    if gfx.mouse_x >= bx and gfx.mouse_x <= bx + bw and gfx.mouse_y >= by and gfx.mouse_y <= by + bh then
        if gfx.mouse_wheel ~= 0 then
            OTHER.rec_state.target_scroll_y = OTHER.rec_state.target_scroll_y - (gfx.mouse_wheel * 0.25)
            if OTHER.rec_state.target_scroll_y < 0 then OTHER.rec_state.target_scroll_y = 0 end
            if OTHER.rec_state.target_scroll_y > max_scroll then OTHER.rec_state.target_scroll_y = max_scroll end
            gfx.mouse_wheel = 0
        end
    end
    
    -- Interpolate scroll position
    local diff = OTHER.rec_state.target_scroll_y - OTHER.rec_state.scroll_y
    if math.abs(diff) > 0.5 then
        OTHER.rec_state.scroll_y = OTHER.rec_state.scroll_y + (diff * 0.8)
    else
        OTHER.rec_state.scroll_y = OTHER.rec_state.target_scroll_y
    end
    
    -- Clamp scroll
    if OTHER.rec_state.scroll_y < 0 then OTHER.rec_state.scroll_y = 0 end
    if OTHER.rec_state.scroll_y > max_scroll then OTHER.rec_state.scroll_y = max_scroll end

    -- Draw content with scroll offset (clipped to view area)
    local draw_y = view_y - math.floor(OTHER.rec_state.scroll_y)

    for _, item in ipairs(items) do
        -- Use cached height from layout calculation
        local entry_h = item.entry_h or (S(28) + S(20)) -- Fallback if not calculated
        
        -- Check visibility (draw if any part is in view)
        if draw_y + entry_h > view_y and draw_y < view_y + view_h then
            
            -- Header (Icon + Name)
            -- Only draw if header is visible below the mask area
            if draw_y + S(28) > view_y then
                gfx.setfont(F.dict_bld)

                if item.ok then
                    set_color(UI.C_GREEN) -- Green
                    gfx.x, gfx.y = col_x, draw_y
                    gfx.drawstr("[OK]")
                else
                    set_color(UI.C_RED) -- Red
                    gfx.x, gfx.y = col_x, draw_y
                    gfx.drawstr("[ X ]")
                end
                
                -- Name
                set_color(UI.C_TXT)
                gfx.x = col_x + S(50)
                gfx.y = draw_y
                gfx.drawstr(item.name)
            end
            
            local line_y = draw_y + S(28)
            
            -- Draw cached lines
            if item.render_lines then
                for _, line_parts in ipairs(item.render_lines) do
                    if #line_parts == 0 then
                        -- Empty line
                        line_y = line_y + S(22)
                    else
                        -- Draw visible lines only
                        if line_y + S(22) > view_y and line_y < view_y + view_h then
                            local draw_x = col_x + S(50)
                            
                            for j, p in ipairs(line_parts) do
                                -- Add space if not first
                                if j > 1 then
                                    gfx.setfont(F.dict_std_sm)
                                    set_color(UI.C_LIGHT_GREY)
                                    gfx.x, gfx.y = draw_x, line_y
                                    local space_w = gfx.measurestr(" ")
                                    gfx.drawstr(" ")
                                    draw_x = draw_x + space_w
                                end
                                
                                if p.type == "link" then
                                    gfx.setfont(F.dict_std_sm)
                                    set_color(UI.C_BLUE_BRIGHT)
                                    gfx.x, gfx.y = draw_x, line_y
                                    local link_w = gfx.measurestr(p.content)
                                    gfx.drawstr(p.content)
                                    
                                    if is_mouse_clicked() and gfx.mouse_x >= draw_x and gfx.mouse_x <= draw_x + link_w and
                                       gfx.mouse_y >= line_y and gfx.mouse_y <= line_y + S(22) then
                                        UTILS.open_url(p.url)
                                        UI_STATE.mouse_handled = true
                                    end
                                    draw_x = draw_x + link_w
                                elseif p.type == "bold" then
                                    gfx.setfont(F.dict_bld_sm)
                                    set_color(UI.C_WHITE)
                                    gfx.x, gfx.y = draw_x, line_y
                                    local bold_w = gfx.measurestr(p.content)
                                    gfx.drawstr(p.content)
                                    draw_x = draw_x + bold_w
                                else
                                    gfx.setfont(F.dict_std_sm)
                                    set_color(UI.C_LIGHT_GREY)
                                    gfx.x, gfx.y = draw_x, line_y
                                    local text_w = gfx.measurestr(p.content)
                                    gfx.drawstr(p.content)
                                    draw_x = draw_x + text_w
                                end
                            end
                        end
                        line_y = line_y + S(22)
                    end
                end
                
                -- Draw "Open in ReaPack" button
                if OTHER.rec_state.reapack and item.reapack_search and not item.ok then
                    local btn_y = line_y + S(5)
                    local btn_h = S(24)
                    local btn_w = S(180)
                    local btn_x = col_x + S(50)
                    
                    if btn_y + btn_h > view_y and btn_y < view_y + view_h then
                        if btn(btn_x, btn_y, btn_w, btn_h, "Відкрити в ReaPack") then
                            if reaper.ReaPack_BrowsePackages then
                                reaper.ReaPack_BrowsePackages(item.reapack_search)
                            else
                                reaper.MB("ReaPack не знайдено, хоча перевірка каже ОК.", "Error", 0)
                            end
                        end
                    end
                end
            end
        end
        draw_y = draw_y + entry_h
    end
    
    -- Header Background (Mask) & Title Elements (Moved here for Z-ordering)
    -- Opaque background to mask scrolling content (inset to preserve border)
    set_color(UI.C_DARK_GREY) 
    gfx.rect(bx + S(4), by + S(4), bw - S(8), S(56), 1)

    -- Close Button (Red X)
    local btn_size = S(24)
    local cbx, cby = bx + bw - btn_size - S(10), by + S(10)
    local over_close = gfx.mouse_x >= cbx and gfx.mouse_x <= cbx + btn_size and 
                      gfx.mouse_y >= cby and gfx.mouse_y <= cby + btn_size
    
    if over_close then
        set_color(UI.C_HILI_RED_BRIGHT)
        if is_mouse_clicked() then
            OTHER.rec_state.show = false
            return
        end
    else
        set_color(UI.C_HILI_RED_DARK)
    end

    gfx.rect(cbx, cby, btn_size, btn_size, 1)
    set_color(UI.C_WHITE)
    gfx.line(cbx + 5, cby + 5, cbx + btn_size - 5, cby + btn_size - 5)
    gfx.line(cbx + btn_size - 5, cby + 5, cbx + 5, cby + btn_size - 5)
    
    -- Content Header (Re-drawn over mask)
    local title = "Налаштування середовища"
    gfx.setfont(F.dict_bld)
    set_color(UI.C_TXT)
    local title_max_w = bw - S(80)
    local title_display = fit_text_width(title, title_max_w)
    
    gfx.x, gfx.y = bx + S(20), by + S(15)
    gfx.drawstr(title_display)

    -- Scrollbar indicator if needed (thicker for visibility)
    if total_h > view_h then
        set_color(UI.C_MEDIUM_GREY)
        local sbw = S(8)  -- Increased from S(4)
        local sbx = bx + bw - sbw - S(4)
        local progress = OTHER.rec_state.scroll_y / max_scroll
        local sb_track_h = view_h - S(10)
        local sbh = math.max(S(20), (view_h / total_h) * sb_track_h)
        local sby = view_y + progress * (sb_track_h - sbh)
        gfx.rect(sbx, sby, sbw, sbh, 1)
    end

    UI_STATE.mouse_handled = true
end

--- Open the text editor modal
--- @param initial_text string Text to edit
--- @param callback function Function to call on save(new_text)
--- @param line_idx number|nil Optional context line index
--- @param all_lines table|nil Optional context all lines
local function open_text_editor(initial_text, callback, line_idx, all_lines, is_director_mode)
    text_editor_state.active = true
    text_editor_state.focus = true -- Auto-focus the input field
    text_editor_state.needs_focus_nudge = 10 -- Nudge focus for several frames to overcome OS delays
    text_editor_state.text = initial_text or ""
    text_editor_state.cursor = #text_editor_state.text
    text_editor_state.anchor = text_editor_state.cursor
    text_editor_state.is_director_mode = is_director_mode
    text_editor_state.callback = callback
    text_editor_state.context_line_idx = line_idx
    text_editor_state.context_all_lines = all_lines

    if dict_modal.show then
        dict_modal.show = false
    end
    
    -- Suppress interaction for a split second to prevent double-click bleed-through
    text_editor_state.interaction_start_time = reaper.time_precise() + 0.25
    
    -- Init History
    text_editor_state.history = {
        {
            text = text_editor_state.text,
            cursor = text_editor_state.cursor,
            anchor = text_editor_state.anchor
        }
    }
    text_editor_state.history_pos = 1
end

--- Draw main navigation UI_STATE.tabs
local function draw_tabs()
    local btn_scan_w = S(30)
    local btn_dash_w = S(30) -- New "D" button width
    local gap_w = 1 -- 1 pixel gap
    
    -- Calculate available width for main tabs
    -- Total = Dashboard + gap + Tabs + gap + Scan
    local total_tab_w = gfx.w - btn_scan_w - btn_dash_w - (gap_w * 2)
    local tab_w_base = total_tab_w / #UI_STATE.tabs
    local h = S(25)
    
    -- 1. Dashboard Button ("Д")
    local d_x = 0
    local dash_col = DEADLINE.get_overall_urgency()
    set_color(dash_col)
    gfx.rect(d_x, 0, btn_dash_w, h, 1)
    
    set_color(UI.C_TXT)
    gfx.setfont(F.std)
    local dw, dh = gfx.measurestr("Д")
    gfx.x = d_x + (btn_dash_w - dw)/2
    gfx.y = (h - dh)/2
    gfx.drawstr("Д")
    
    if is_mouse_clicked() and not dict_modal.show then
        if gfx.mouse_x >= d_x and gfx.mouse_x < d_x + btn_dash_w and gfx.mouse_y >= 0 and gfx.mouse_y <= h then
            DEADLINE.dashboard_show = true
        end
    end
    
    -- 2. Main Tabs
    local tabs_start_x = btn_dash_w + gap_w
    
    for i, name in ipairs(UI_STATE.tabs) do
        -- Integer calculation to prevent gaps
        local x_start = tabs_start_x + math.floor((i - 1) * total_tab_w / #UI_STATE.tabs)
        local x_end = tabs_start_x + math.floor(i * total_tab_w / #UI_STATE.tabs)
        local tab_w = x_end - x_start
        local x = x_start
        
        local is_act = (UI_STATE.current_tab == i)
        
        set_color(is_act and UI.C_TAB_ACT or UI.C_TAB_INA)
        gfx.rect(x, 0, tab_w, h, 1)


        set_color(UI.C_TXT)
        gfx.setfont(F.std)
        local display_name = fit_text_width(name, tab_w - S(10))
        local str_w, str_h = gfx.measurestr(display_name)
        gfx.x = x + (tab_w - str_w) / 2
        gfx.y = (h - dh) / 2 -- Use same vertical centering
        gfx.drawstr(display_name)
        
        -- Click
        if is_mouse_clicked() and not dict_modal.show then
            if gfx.mouse_x >= x and gfx.mouse_x < x+tab_w and gfx.mouse_y >= 0 and gfx.mouse_y <= h then
                -- Save current tab's scroll position
                UI_STATE.tab_scroll_y[UI_STATE.current_tab] = UI_STATE.scroll_y
                UI_STATE.tab_target_scroll_y[UI_STATE.current_tab] = UI_STATE.target_scroll_y
                -- Switch tab
                UI_STATE.current_tab = i
                -- Restore new tab's scroll position
                UI_STATE.scroll_y = UI_STATE.tab_scroll_y[UI_STATE.current_tab] or 0
                UI_STATE.target_scroll_y = UI_STATE.tab_target_scroll_y[UI_STATE.current_tab] or 0
            end
        end
    end
    
    -- 3. Jump to Region Button (Small Tab at the end)
    local btn_x = tabs_start_x + total_tab_w + gap_w
    
    set_color(UI.C_TAB_INA) -- Use inactive tab color
    gfx.rect(btn_x, 0, btn_scan_w, h, 1)
    
    set_color(UI.C_TXT)
    gfx.setfont(F.std)
    local bw, bh = gfx.measurestr("#")
    
    gfx.x = btn_x + (btn_scan_w - bw)/2
    gfx.y = (h - bh)/2
    gfx.drawstr("#")
    
    if is_mouse_clicked() and not dict_modal.show then
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
                        local found = false
                        local num_markers = reaper.CountProjectMarkers(0)
                        for i = 0, num_markers - 1 do
                            local retval, isrgn, pos, rgnend, name, idx = reaper.EnumProjectMarkers(i)
                            if isrgn and idx == target_idx then
                                reaper.SetEditCurPos(pos, true, true)
                                found = true
                                break
                            end
                        end
                        
                        -- Fallback: Search internal ass_lines if not found as physical marker
                        if not found then
                            for _, line in ipairs(ass_lines) do
                                if line.index == target_idx then
                                    reaper.SetEditCurPos(line.t1, true, true)
                                    break
                                end
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

--- Tabs Views ---
--- Draw the detailed file view with import buttons and actor stats
local function draw_file()
    -- PRE-CALCULATE CONTENT HEIGHT FOR SCROLLING
    local is_narrow = gfx.w < S(470)
    local content_h = 0
    
    -- 1. Action Buttons Height
    if is_narrow then
        content_h = content_h + S(40) + S(5) + S(40) -- Two rows
    else
        content_h = content_h + S(40) -- One row
    end
    
    -- 2. Filename display row
    if UI_STATE.ass_file_loaded and UI_STATE.current_file_name then
        content_h = content_h + S(25)
    end
    
    -- 3. Spacer before filter
    content_h = content_h + S(60)
    
    -- 4. Actor Filter Section
    if UI_STATE.ass_file_loaded then
        -- Header rows
        if is_narrow then 
            content_h = content_h + S(25) + S(25) + S(45)
        else 
            content_h = content_h + S(35) 
        end
        
        -- Actors grid
        local actor_count = 0
        for _ in pairs(ass_actors) do actor_count = actor_count + 1 end
        local cols = math.floor((gfx.w - S(40)) / S(150))
        if cols < 1 then cols = 1 end
        local row_count = math.ceil(actor_count / cols)
        
        content_h = content_h + (row_count * S(30)) + S(20)
        
        -- Statistics row
        content_h = content_h + S(45)
        
        -- Stress marks button
        content_h = content_h + S(50)
    else
        -- Help text
        content_h = content_h + S(30)
    end
    
    -- 5. Drop zone area
    content_h = content_h + S(80)

    local start_y = S(50)
    local avail_h = gfx.h - start_y
    local max_scroll = math.max(0, content_h - avail_h)
    
    -- Smooth Scroll Logic
    if gfx.mouse_wheel ~= 0 then
        UI_STATE.target_scroll_y = UI_STATE.target_scroll_y - (gfx.mouse_wheel * 0.25)
        gfx.mouse_wheel = 0
    end
    
    if UI_STATE.target_scroll_y < 0 then UI_STATE.target_scroll_y = 0 end
    if UI_STATE.target_scroll_y > max_scroll then UI_STATE.target_scroll_y = max_scroll end

    local diff = UI_STATE.target_scroll_y - UI_STATE.scroll_y
    if math.abs(diff) > 0.5 then
        UI_STATE.scroll_y = UI_STATE.scroll_y + (diff * 0.8)
    else
        UI_STATE.scroll_y = UI_STATE.target_scroll_y
    end
    
    if UI_STATE.scroll_y < 0 then UI_STATE.scroll_y = 0 end
    if UI_STATE.scroll_y > max_scroll then UI_STATE.scroll_y = max_scroll end

    local function get_y(offset)
        return start_y + offset - math.floor(UI_STATE.scroll_y)
    end

    -- Action Buttons Layout
    local padding = S(20)
    local spacing = S(5)
    local btn_h = S(40)
    
    local y_cursor = 0
    local cur_y = get_y(y_cursor)
    
    -- Calculate widths based on mode
    local import_w, notes_w, deadline_w
    if is_narrow then
        import_w = gfx.w - padding * 2
        notes_w = (gfx.w - padding * 2 - spacing) / 2
        deadline_w = notes_w
    else
        import_w = S(230)
        notes_w = S(80)
        deadline_w = S(105)
    end
    
    -- 1. Import Button
    if cur_y + btn_h > start_y and cur_y < gfx.h then
        if btn(padding, cur_y, import_w, btn_h, fit_text_width("Імпорт субтитрів (.srt/.ass/.vtt)", import_w - S(10))) then
            local retval, file_list
            if reaper.JS_Dialog_BrowseForOpenFiles then
                retval, file_list = reaper.JS_Dialog_BrowseForOpenFiles("Імпорт субтитрів", "", "", "Subtitle files (*.srt;*.ass;*.vtt)\0*.srt;*.ass;*.vtt\0All files\0*\0", true)
            else
                retval, file_list = reaper.GetUserFileNameForRead("", "Імпорт субтитрів", "*.srt;*.ass;*.vtt")
            end
            
            if retval and file_list ~= "" then
                push_undo("Імпорт субтитрів")
                local files = {}
                if reaper.JS_Dialog_BrowseForOpenFiles then
                    local dir = file_list:match("^(.-)\0")
                    if dir then
                        for f in file_list:gmatch("\0([^\0]+)") do
                            if f ~= "" then
                                table.insert(files, dir .. "/" .. f)
                            end
                        end
                    else
                        -- Only one file selected
                        table.insert(files, file_list)
                    end
                else
                    table.insert(files, file_list)
                end
                
                local imported_count = 0
                local total_duplicates = 0
                for _, file in ipairs(files) do
                    local ext = file:match("%.([^.]+)$")
                    if ext then
                        ext = ext:lower()
                        if ext == "srt" then
                            total_duplicates = total_duplicates + import_srt(file, true)
                            imported_count = imported_count + 1
                        elseif ext == "ass" then
                            total_duplicates = total_duplicates + import_ass(file, true)
                            imported_count = imported_count + 1
                        elseif ext == "vtt" then
                            total_duplicates = total_duplicates + import_vtt(file, true)
                            imported_count = imported_count + 1
                        else
                            show_snackbar("Формат ." .. ext:upper() .. " не підтримується", "error")
                        end
                    else
                        show_snackbar("Не вдалося визначити формат файлу", "error")
                    end
                end
                
                if imported_count > 0 then
                    update_regions_cache()
                    rebuild_regions()
                    local msg = "Імпортовано файлів: " .. imported_count
                    if total_duplicates > 0 then msg = msg .. " (Дублікатів: " .. total_duplicates .. ")" end
                    show_snackbar(msg, "success")
                end
            end
        end
    end
    
    -- Positions for the remaining buttons
    local nx, dx, ny
    if is_narrow then
        -- Wrap to second row (Full Width distribution)
        y_cursor = y_cursor + btn_h + S(5)
        ny = get_y(y_cursor)
        nx = padding
        dx = padding + notes_w + spacing
    else
        -- Same row, align right
        ny = cur_y
        dx = gfx.w - padding - deadline_w
        nx = dx - spacing - notes_w
    end
    
    -- 2. Notes Button
    if ny + btn_h > start_y and ny < gfx.h then
        if btn(nx, ny, notes_w, btn_h, fit_text_width("Правки", notes_w - S(10))) then
            gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
            local ret = gfx.showmenu("Імпорт з тексту|Імпорт з файлу (CSV)")
            if ret == 1 then import_notes()
            elseif ret == 2 then import_notes_from_csv() end
        end
    end
    
    -- 3. Deadline Button
    if ny + btn_h > start_y and ny < gfx.h then
        local dl_text = "Дедлайн"
        local dl_bg = UI.C_ROW
        local dl_txt = nil -- Use default text color
        if DEADLINE.project_deadline then
            local days = math.ceil((DEADLINE.project_deadline - os.time()) / 86400)
            if days < 0 then
                dl_text = "ПРОЙШОВ!"
                dl_bg = UI.C_SNACK_ERROR
                dl_txt = UI.C_WHITE
            elseif days == 0 then
                dl_text = "СЬОГОДНІ!"
                dl_bg = UI.C_RED
            else
                dl_text = os.date("%d.%m", DEADLINE.project_deadline) .. " (" .. days .. "д)"
                if days == 1 then
                    dl_bg = UI.C_ORANGE
                else
                    dl_bg = UI.C_SNACK_SUCCESS
                    dl_txt = UI.C_WHITE
                end
            end
        end
        
        if btn(dx, ny, deadline_w, btn_h, fit_text_width(dl_text, deadline_w - S(10)), dl_bg, dl_txt) then
            DEADLINE.open_picker(DEADLINE.project_deadline, function(ts)
                DEADLINE.set(ts)
                show_snackbar(ts and ("Дедлайн встановлено: " .. os.date("%d.%m.%Y", ts)) or "Дедлайн скасовано", "info")
            end)
        end
    end
    
    y_cursor = y_cursor + btn_h + S(10)
    
    -- Filename Display Row
    if UI_STATE.ass_file_loaded and UI_STATE.current_file_name then
        local fn_y = get_y(y_cursor)
        if fn_y + S(20) > start_y and fn_y < gfx.h then
            gfx.setfont(F.tip)
            set_color(UI.C_MEDIUM_GREY)
            local str = "Обрано: " .. UI_STATE.current_file_name
            str = fit_text_width(str, gfx.w - padding * 2)
            gfx.x = padding
            gfx.y = fn_y
            gfx.drawstr(str)
        end
        y_cursor = y_cursor + S(25)
    end
    
    y_cursor = y_cursor + S(25)
    
    -- Actor Filter (if loaded)
    if UI_STATE.ass_file_loaded then
        local t_y = get_y(y_cursor)
        local actor_header_y = t_y
        
        -- Statistics calculation (needed for both layouts)
        local selected_count = 0
        local total_count = 0
        for _, v in pairs(ass_actors) do
            total_count = total_count + 1
            if v then selected_count = selected_count + 1 end
        end
        local count_text = selected_count .. "/" .. total_count

        if is_narrow then
            -- NARROW LAYOUT
            if t_y + S(60) > start_y and t_y < gfx.h then
                -- Row 1: Title + Count
                set_color(UI.C_TXT)
                gfx.setfont(F.std)
                gfx.x, gfx.y = S(20), t_y
                gfx.drawstr(fit_text_width("Фільтр акторів:", gfx.w - S(100)))
                
                local tw, th = gfx.measurestr(count_text)
                gfx.x = gfx.w - S(20) - tw
                gfx.drawstr(count_text)
            end

            y_cursor = y_cursor + S(25)
            t_y = get_y(y_cursor)
            
            if t_y + S(20) > start_y and t_y < gfx.h then
                -- Row 2: Quick Select
                if btn(S(20), t_y, gfx.w - S(40), S(20), fit_text_width("Швидкий вибір", gfx.w - S(50)), UI.C_ROW) then
                    local ret, csv = reaper.GetUserInputs("Швидкий вибір акторів", 1, "Список акторів (через кому):,extrawidth=200", "")
                    if ret then
                        push_undo("Швидкий вибір акторів")
                        for k in pairs(ass_actors) do ass_actors[k] = false end
                        for _, l in ipairs(ass_lines) do l.enabled = false end
                        local selected = {}
                        for act_name in csv:gmatch("([^,]+)") do
                            act_name = act_name:match("^%s*(.-)%s*$")
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
            end

            y_cursor = y_cursor + S(25)
            t_y = get_y(y_cursor)
            
            if t_y + S(20) > start_y and t_y < gfx.h then
                -- Row 3: None / All
                local half_w = (gfx.w - S(50)) / 2
                if btn(S(20), t_y, half_w, S(20), fit_text_width("НІКОГО", half_w - S(10)), UI.C_ROW) then
                    push_undo("Приховати всіх")
                    for k in pairs(ass_actors) do ass_actors[k] = false end
                    for _, l in ipairs(ass_lines) do l.enabled = false end
                    rebuild_regions()
                end
                if btn(S(20) + half_w + S(10), t_y, half_w, S(20), fit_text_width("ВСІ", half_w - S(10)), UI.C_ROW) then
                    push_undo("Показати всіх")
                    for k in pairs(ass_actors) do ass_actors[k] = true end
                    for _, l in ipairs(ass_lines) do l.enabled = true end
                    rebuild_regions()
                end
            end
            
            y_cursor = y_cursor + S(45)
        else
            -- WIDE LAYOUT
            if t_y + S(20) > start_y and t_y < gfx.h then
                set_color(UI.C_TXT)
                gfx.setfont(F.std)
                gfx.x, gfx.y = S(20), t_y
                gfx.drawstr(fit_text_width("Фільтр:", S(60)))
                
                -- Batch Select
                local quick_btn_w = S(110)
                if btn(S(80), t_y - S(2), quick_btn_w, S(20), fit_text_width("Швидкий вибір", quick_btn_w - S(5)), UI.C_ROW) then
                    local ret, csv = reaper.GetUserInputs("Швидкий вибір акторів", 1, "Список акторів (через кому):,extrawidth=200", "")
                    if ret then
                        push_undo("Швидкий вибір акторів")
                        for k in pairs(ass_actors) do ass_actors[k] = false end
                        for _, l in ipairs(ass_lines) do l.enabled = false end
                        local selected = {}
                        for act_name in csv:gmatch("([^,]+)") do
                            act_name = act_name:match("^%s*(.-)%s*$")
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
                local right_edge = gfx.w - S(20)
                local all_btn_w = S(50)
                local none_btn_w = S(75)
                
                local all_btn_x = right_edge - all_btn_w
                local none_btn_x = all_btn_x - none_btn_w - S(5)
                
                local tw, th = gfx.measurestr(count_text)
                local count_x = none_btn_x - tw - S(10)
                
                -- Check for overlap between Quick Select and Count
                if count_x < S(80) + quick_btn_w + S(10) then
                    count_x = S(80) + quick_btn_w + S(10)
                end
                
                gfx.x, gfx.y = count_x, t_y
                gfx.drawstr(count_text)
                
                if btn(none_btn_x, t_y - S(2), none_btn_w, S(20), fit_text_width("НІКОГО", none_btn_w - S(5)), UI.C_ROW) then
                    push_undo("Приховати всіх")
                    for k in pairs(ass_actors) do ass_actors[k] = false end
                    for _, l in ipairs(ass_lines) do l.enabled = false end
                    rebuild_regions()
                end
                
                if btn(all_btn_x, t_y - S(2), all_btn_w, S(20), fit_text_width("ВСІ", all_btn_w - S(5)), UI.C_ROW) then
                    push_undo("Показати всіх")
                    for k in pairs(ass_actors) do ass_actors[k] = true end
                    for _, l in ipairs(ass_lines) do l.enabled = true end
                    rebuild_regions()
                end
            end
            y_cursor = y_cursor + S(35)
        end
        
        -- Sort actors for consistent display
        local sorted_actors = {}
        for act in pairs(ass_actors) do table.insert(sorted_actors, act) end
        table.sort(sorted_actors)
        
        -- AUTO-GRID CALCULATION
        local item_w = S(150) -- Min width per item
        local cols = math.floor((gfx.w - S(40)) / item_w)
        if cols < 1 then cols = 1 end
        
        -- Calculate rows needed
        local row_count = math.ceil(#sorted_actors / cols)
        
        -- Pre-calculate stats per actor for tooltips
        local actor_tooltips = {}
        for _, line in ipairs(ass_lines) do
            local act = line.actor or "Default"
            if not actor_tooltips[act] then actor_tooltips[act] = {replicas = 0, words = 0} end
            actor_tooltips[act].replicas = actor_tooltips[act].replicas + 1
            local clean = (line.text or ""):gsub("{.-}", ""):gsub("\\[Nnh]", " ")
            local _, count = clean:gsub("%S+", "")
            actor_tooltips[act].words = actor_tooltips[act].words + count
        end

        for i, act in ipairs(sorted_actors) do
            -- Grid Indexing (0-based for math)
            local idx = i - 1
            local col = idx % cols
            local row = math.floor(idx / cols)
            
            local x_pos = S(20) + (col * item_w)
            local y_rel = y_cursor + (row * S(30)) -- 30px per row
            local chk_y = get_y(y_rel)
            
            if chk_y + S(20) > start_y and chk_y < gfx.h then
                local enabled = ass_actors[act]
                
                -- HOVER CHECK
                if UI_STATE.window_focused and
                   gfx.mouse_x >= x_pos - S(2) and gfx.mouse_x <= x_pos + item_w - S(5) and
                   gfx.mouse_y >= chk_y - S(2) and gfx.mouse_y <= chk_y + S(22) then
                    set_color(UI.C_HILI_WHITE) -- Slight white highlight
                    gfx.rect(x_pos - S(2), chk_y - S(2), item_w - S(3), S(24), 1)
                end
                
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
                    gfx.rect(x_pos, chk_y, S(20), S(20), 1) -- Filled

                    set_color(UI.C_ED_GUTTER)
                    gfx.rect(x_pos, chk_y, S(20), S(20), 0)
                    
                    -- Checkmark (Contrast color? Black or White depending on luminance)
                    local lum = (native_r * 0.299 + native_g * 0.587 + native_b * 0.114) / 255
                    if lum > 0.5 then set_color(UI.C_BLACK) else set_color(UI.C_WHITE) end
                else
                    -- Disabled: Grey outline
                    set_color(UI.C_ED_GUTTER)
                    gfx.rect(x_pos, chk_y, S(20), S(20), 0) -- Outline
                    
                    -- Small indicator of their color inside?
                    set_color({native_r/255, native_g/255, native_b/255})
                    gfx.rect(x_pos + S(6), chk_y + S(6), S(8), S(8), 1)
                end

                if enabled then
                    -- Checkmark (tick)
                    -- Left stroke (shorter)
                    gfx.line(x_pos + S(4), chk_y + S(10), x_pos + S(8), chk_y + S(16))
                    gfx.line(x_pos + S(5), chk_y + S(10), x_pos + S(9), chk_y + S(16)) -- Bold
                    
                    -- Right stroke (longer)
                    gfx.line(x_pos + S(8), chk_y + S(16), x_pos + S(16), chk_y + S(4))
                    gfx.line(x_pos + S(9), chk_y + S(16), x_pos + S(17), chk_y + S(4)) -- Bold
                end
                
                -- Label (Truncate if too long)
                set_color(UI.C_TXT)
                gfx.setfont(F.std)  -- Explicitly set font to prevent jumping
                gfx.x, gfx.y = x_pos + S(25), chk_y + S(2)
                
                local max_txt_w = item_w - S(30) -- padding
                local display_act = fit_text_width(act, max_txt_w)
                
                gfx.setfont(F.std)  -- Re-set after fit_text_width in case it changed
                gfx.drawstr(display_act, 4 | 256, x_pos + item_w - S(5), chk_y + S(20))

                -- Tooltip Logic
                if UI_STATE.window_focused and
                   gfx.mouse_x >= x_pos - S(2) and gfx.mouse_x <= x_pos + item_w - S(5) and
                   gfx.mouse_y >= chk_y - S(2) and gfx.mouse_y <= chk_y + S(22) then
                    
                    local stats = actor_tooltips[act] or {replicas = 0, words = 0}
                    local tooltip = string.format("%s\nРеплік: %d\nСлів: %d", act, stats.replicas, stats.words)
                    
                    local tip_id = "actor_tip_" .. act
                    if UI_STATE.tooltip_state.hover_id ~= tip_id then
                        UI_STATE.tooltip_state.hover_id = tip_id
                        UI_STATE.tooltip_state.start_time = reaper.time_precise()
                    end
                    UI_STATE.tooltip_state.text = tooltip
                end
            
                -- Click Logic
                if is_mouse_clicked() then
                    -- Hit test
                    if gfx.mouse_x >= x_pos and gfx.mouse_x <= x_pos + item_w - S(5) and
                       gfx.mouse_y >= chk_y and gfx.mouse_y <= chk_y + S(20) then
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
                    if gfx.mouse_x >= x_pos and gfx.mouse_x <= x_pos + item_w - S(5) and
                       gfx.mouse_y >= chk_y and gfx.mouse_y <= chk_y + S(20) then
                        
                        gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
                        local ret = gfx.showmenu("Змінити колір|Змінити ім'я актора||Видалити актора")
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
                                -- Remove variation selector (U+FE0F = \239\184\143) and trim spaces
                                new_name = new_name:gsub("\239\184\143", ""):match("^%s*(.-)%s*$")
                                
                                push_undo("Зміна імені актора")
                                -- Update lines
                                for _, l in ipairs(ass_lines) do
                                    if l.actor == act then l.actor = new_name end
                                end
                                -- Update actors state
                                local state = ass_actors[act]
                                ass_actors[act] = nil
                                if state ~= nil then
                                    ass_actors[new_name] = state
                                else
                                    ass_actors[new_name] = true
                                end
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
                                
                                -- Remove all lines for this actor in one pass (O(N) vs O(N^2))
                                local new_lines = {}
                                for _, line in ipairs(ass_lines) do
                                    if line.actor ~= act then
                                        table.insert(new_lines, line)
                                    end
                                end
                                ass_lines = new_lines
                                
                                cleanup_actors()
                                rebuild_regions()
                                save_project_data()
                            end
                        end
                        UI_STATE.mouse_handled = true -- Suppress global context menu
                    end
                end
            end
        end
        
        y_cursor = y_cursor + (row_count * S(30)) + S(20)


        -- Statistics: Count Replicas and Words for Selected Actors
        local stats_replicas = 0
        local stats_words = 0
        local stats_time = 0
        
        for _, line in ipairs(ass_lines) do
            if line.enabled then
                stats_replicas = stats_replicas + 1
                -- Word count: Strip tags, convert breaks to spaces, count non-whitespace chunks
                local clean = (line.text or ""):gsub("{.-}", ""):gsub("\\[Nnh]", " ")
                local _, count = clean:gsub("%S+", "")
                stats_words = stats_words + count
                -- Calculate time
                if line.t1 and line.t2 then
                    stats_time = stats_time + (line.t2 - line.t1)
                end
            end
        end
        
        local stats_y = get_y(y_cursor)
        if stats_y + S(40) > start_y and stats_y < gfx.h then
            set_color(UI.C_TXT)
            gfx.setfont(F.std)
            gfx.x = S(20)
            gfx.y = stats_y
            local time_str = format_time_hms(stats_time)
            local str = "Обрано: " .. stats_replicas .. " реплік, " .. stats_words .. " слів, час: " .. time_str
            gfx.drawstr(fit_text_width(str, gfx.w - S(40)))
        end
        y_cursor = y_cursor + S(45)

        -- Apply Stress Marks Button
        local s_y = get_y(y_cursor)
        if s_y + S(25) > start_y and s_y < gfx.h then
            local is_running = UI_STATE.script_loading_state.active
            local btn_text = is_running and "AI обробка..." or ">  Застосувати наголоси  <"
            local btn_col = is_running and UI.C_BTN_H or UI.C_TAB_ACT
            
            if btn(S(20), s_y, gfx.w - S(40), S(40), fit_text_width(btn_text, gfx.w - S(60)), btn_col) and not is_running then
                push_undo("Застосування наголосів")
                apply_stress_marks_async()
            end
        end
        y_cursor = y_cursor + S(50)
    else
        y_cursor = y_cursor + (is_narrow and S(30) or 0)
        -- Default text
        local t_y = get_y(y_cursor)
        if t_y + S(20) > start_y and t_y < gfx.h then
            gfx.setfont(F.std)
            gfx.x, gfx.y = S(20), t_y
            gfx.drawstr("Імпортуй файл аби побачити більше опцій.")
        end
        y_cursor = y_cursor + S(30)
    end
    
    -- Drop Zone Visual
    local drop_y = get_y(y_cursor)
    if drop_y + S(60) > start_y and drop_y < gfx.h then
        local dw = gfx.w - S(40)
        local dh = S(60)
        local dx = S(20)
        
        -- Dashed Border
        set_color(UI.C_HILI_GREY_LOW)
        for dash_x = dx, dx + dw - S(10), S(10) do
            gfx.line(dash_x, drop_y, dash_x + S(5), drop_y)
            gfx.line(dash_x, drop_y + dh, dash_x + S(5), drop_y + dh)
        end
        for dash_y = drop_y, drop_y + dh - S(10), S(10) do
            gfx.line(dx, dash_y, dx, dash_y + S(5))
            gfx.line(dx + dw, dash_y, dx + dw, dash_y + S(5))
        end
        
        -- Text
        set_color(UI.C_HILI_GREY_MID)
        gfx.setfont(F.std)
        local str = fit_text_width("Перетягніть .SRT, .ASS, .VTT або .CSV (правки) файл сюди для імпорту", dw - S(20))
        local sw, sh = gfx.measurestr(str)
        gfx.x, gfx.y = dx + (dw - sw) / 2, drop_y + (dh - sh) / 2
        gfx.drawstr(str)
    end
    y_cursor = y_cursor + S(80)

    -- Context Menu (Right Click on background)
    if is_mouse_clicked(2) and not UI_STATE.mouse_handled then
        gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
        local is_docked = gfx.dock(-1) > 0
        local dock_check = is_docked and "!" or ""
        local menu = "Видалити ВСІ регіони||Відкрити WEB-менеджер наголосів|Відкрити мою Статистику||Розділення по Даберам|Відкрити мої Дедлайни||>Експортувати субтитри|Експортувати як SRT|Експортувати як ASS|<|Аналіз/Пошук звуків (Експериментально!!)||" .. dock_check .. "Закріпити вікно (Dock)"
        
        local ret = gfx.showmenu(menu)
        UI_STATE.mouse_handled = true -- Tell framework we handled this click
        
        if ret == 1 then
            delete_all_regions()
        elseif ret == 2 then
            -- Open web-based stress manager
            UTILS.launch_python_script("stress/ukrainian_stress_tool.py")
        elseif ret == 3 then
            -- Open web-based STATS manager
            UTILS.launch_python_script("stats/subass_stats.py")
        elseif ret == 4 then
            DUBBERS.show_dashboard = true
            DUBBERS.load()
        elseif ret == 5 then
            DEADLINE.dashboard_show = true
        elseif ret == 6 then
            -- Export as SRT
            export_as_srt()
        elseif ret == 7 then
            -- Export as ASS
            export_as_ass()
        elseif ret == 8 then
            -- Whisper Analysis
            local item = reaper.GetSelectedMediaItem(0, 0)
            if not item then
                reaper.MB("Будь ласка, оберіть аудіо-айтем на таймлайні для аналізу.", "Whisper AI", 0)
                return
            end
            local take = reaper.GetActiveTake(item)
            if not take then return end
            local source = reaper.GetMediaItemTake_Source(take)
            local path = reaper.GetMediaSourceFileName(source, "")
            
            if path == "" then
                reaper.MB("Не вдалося знайти шлях до файлу.", "Whisper AI", 0)
                return
            end

            local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local it_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            local offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
            local playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
            
            -- Adjust effective length and offset for playrate if needed
            -- Whisper analysis will happen on the original source but we only crop the visible part
            -- Source coords: offset to (offset + it_len * playrate)
            local source_len = it_len * playrate

            local script_dir = debug.getinfo(1, "S").source:match([[^@?(.*[\/])]])
            local py_script = script_dir .. "stats/subass_whisper.py"
            
            local cmd = string.format('python3 "%s" "%s" --offset %.3f --length %.3f --start_time %.3f', 
                                      py_script, path, offset, source_len, pos)

            run_async_command(cmd, function(output)
                if not output or output == "" then
                    reaper.MB("Whisper AI: Отримано порожній результат або сталася помилка.", "Whisper AI", 0)
                    return
                end

                -- Strip ANSI escape codes
                output = output:gsub("[\27\155][][()#;?%d]*[A-PRZcf-ntqry=><~]", "")

                -- Extract SRT path from output
                local srt_path = output:match("[-][-][-]SRT_PATH_START[-][-][-][-]*%s*(.-)%s*[-][-][-][-]*SRT_PATH_END[-][-][-][-]*")
                if not srt_path or srt_path == "" then
                    reaper.MB("Whisper AI: Не вдалося знайти шлях до SRT файлу у відповіді.", "Whisper AI", 0)
                    return
                end

                -- Trim any potential whitespace from path
                srt_path = srt_path:match("^%s*(.-)%s*$")

                -- Import the generated SRT silently first (dont_rebuild = true)
                import_srt(srt_path, true, "Можливі звуки")
                
                -- Post-processing: Remove "Possible sounds" that overlap with existing speech
                local sounds_actor = "Можливі звуки"
                local removed_count = 0
                
                -- Iterate backwards to safely remove from table
                for i = #ass_lines, 1, -1 do
                    local line = ass_lines[i]
                    if line.actor == sounds_actor then
                        local overlaps = false
                        for j, other in ipairs(ass_lines) do
                            if i ~= j and other.actor ~= sounds_actor then
                                -- Strict overlap check: if the sound is within or overlaps a speech block
                                -- We add a small 100ms tolerance to favor existing text
                                if not (line.t2 <= other.t1 + 0.1 or line.t1 >= other.t2 - 0.1) then
                                    overlaps = true
                                    break
                                end
                            end
                        end
                        
                        if overlaps then
                            table.remove(ass_lines, i)
                            removed_count = removed_count + 1
                        end
                    end
                end
                
                -- Now rebuild everything to sync with REAPER
                rebuild_regions()
                
                if removed_count > 0 then
                    show_snackbar(string.format("Whisper AI: Аналіз завершено. Додано звуки, %d дублікатів відфільтровано.", removed_count), "success")
                else
                    show_snackbar("Whisper AI: Аналіз завершено, звуки додано.", "success")
                end
            end, true, "Whisper аналіз...", true)
        elseif ret == 6 then
            -- Toggle Docking
            if is_docked then
                gfx.dock(0)
                reaper.SetExtState(section_name, "dock", "0", true)
            else
                gfx.dock(1) -- Dock to last valid docker
                reaper.SetExtState(section_name, "dock", tostring(gfx.dock(-1)), true)
            end
        end
    end

    last_file_h = y_cursor
    
    -- Scrollbar
    UI_STATE.target_scroll_y = draw_scrollbar(gfx.w - 10, start_y, 10, avail_h, last_file_h, avail_h, UI_STATE.target_scroll_y)
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

-- Helper: Delete corrections logic for prompter drawer
local function prompter_delete_logic()
    local sel_indices = {}
    for idx, _ in pairs(prompter_drawer.selection) do table.insert(sel_indices, idx) end
    
    if #sel_indices > 0 then
        push_undo("Видалення правок")
        -- Sort descending to avoid index shift issues (though markers are by index, it's safer)
        table.sort(sel_indices, function(a,b) return a > b end)
        for _, m_idx in ipairs(sel_indices) do
            reaper.DeleteProjectMarker(0, m_idx, false)
        end
        prompter_drawer.selection = {}
        prompter_drawer.last_selected_idx = nil
        reaper.UpdateTimeline()
        -- Invalidate caches
        ass_markers = capture_project_markers()
        prompter_drawer.marker_cache.count = -1
        prompter_drawer.filtered_cache.state_count = -1
        prompter_drawer.has_markers_cache.count = -1
        table_data_cache.state_count = -1
        last_layout_state.state_count = -1
        
        show_snackbar("Видалено правок: " .. #sel_indices, "error")
    end
end

--- Draw prompter display with current and next subtitles
local function draw_prompter_drawer(input_queue)
    update_marker_cache()
    
    local drawer_top_y = S(25)
    local drawer_x = cfg.p_drawer_left and 0 or (gfx.w - prompter_drawer.width)
    local max_w = math.floor(gfx.w * 0.95)

    if not prompter_drawer.open then
        -- Performance-optimized marker check
        local state_count = reaper.GetProjectStateChangeCount(0)
        if state_count ~= prompter_drawer.has_markers_cache.count then
            prompter_drawer.has_markers_cache.count = state_count
            prompter_drawer.has_markers_cache.result = false
            local i = 0
            while true do
                local retval, isrgn = reaper.EnumProjectMarkers(i)
                if retval == 0 then break end
                if not isrgn then
                    prompter_drawer.has_markers_cache.result = true
                    break
                end
                i = i + 1
            end
        end

        if not prompter_drawer.has_markers_cache.result then return end

        -- Draw vertical "ПРАВКИ" button
        gfx.setfont(F.tip)
        local text = "ПРАВКИ"
        local btn_w = S(15)
        
        -- Calculate dynamic height based on text
        local btn_h = S(16) -- Top/Bottom padding S(8)*2
        for _, code in utf8.codes(text) do
            local _, ch = gfx.measurestr(utf8.char(code))
            btn_h = btn_h + ch - 1
        end

        local btn_x = cfg.p_drawer_left and 0 or (gfx.w - btn_w)
        local btn_y = drawer_top_y + (gfx.h - drawer_top_y - btn_h) / 2
        
        local hover = UI_STATE.window_focused and (gfx.mouse_x >= btn_x and gfx.mouse_x <= btn_x + btn_w and
                       gfx.mouse_y >= btn_y and gfx.mouse_y <= btn_y + btn_h)
        
        set_color(hover and UI.C_BTN_H or UI.C_BTN)
        gfx.rect(btn_x, btn_y, btn_w, btn_h, 1)
        
        -- Draw vertical text "ПРАВКИ"
        set_color(UI.C_TXT)

        -- Rotate text 90 degrees (draw character by character vertically)
        local char_y = btn_y + S(8)
        for _, code in utf8.codes(text) do
            local char = utf8.char(code)
            local cw, ch = gfx.measurestr(char)
            gfx.x = btn_x + (btn_w - cw) / 2
            gfx.y = char_y
            gfx.drawstr(char)
            char_y = char_y + ch - 1
        end
        
        -- Use robust click detection
        if hover and is_mouse_clicked(1) and not UI_STATE.mouse_handled then
            prompter_drawer.open = true
            UI_STATE.mouse_handled = true
            -- Ensure width is sane when opening
            if not prompter_drawer.width or prompter_drawer.width < S(80) then
                prompter_drawer.width = S(300)
            end
        end
    else
        -- Drawer is open
        -- Clamp width
        if prompter_drawer.width > max_w then
            prompter_drawer.width = max_w
        end
        
        -- Auto-close if too narrow
        if prompter_drawer.width < S(80) and not prompter_drawer.dragging then
            prompter_drawer.open = false
            prompter_drawer.width = S(300)
            save_settings()
        else
            -- Draw drawer panel
            set_color(UI.C_TAB_INA)
            gfx.rect(drawer_x, drawer_top_y, prompter_drawer.width, gfx.h - drawer_top_y, 1)
            
            -- --- HEADER ROW (Filter + Close) ---
            local header_h = S(34)
            local padding = S(5)
            local close_sz = S(24)
            local filter_w = prompter_drawer.width - close_sz - (padding * 3)
            
            -- Filter Input
            ui_text_input(drawer_x + padding, drawer_top_y + padding, filter_w, close_sz, prompter_drawer.filter, "Пошук...", input_queue)
            
            -- Close Button next to filter
            local close_x = drawer_x + padding + filter_w + padding
            local close_y = drawer_top_y + padding
            local close_hover = UI_STATE.window_focused and (gfx.mouse_x >= close_x and gfx.mouse_x <= close_x + close_sz and
                                 gfx.mouse_y >= close_y and gfx.mouse_y <= close_y + close_sz)
            
            if close_hover then
                set_color(UI.C_HILI_RED)
                gfx.rect(close_x, close_y, close_sz, close_sz, 1)
            end

            set_color(close_hover and UI.C_BTN_ERROR or UI.C_TXT)
            gfx.setfont(F.std)
            gfx.x = close_x + (close_sz - gfx.measurestr("X")) / 2
            gfx.y = close_y + (close_sz - gfx.texth) / 2
            gfx.drawstr("X")
            
            if close_hover and gfx.mouse_cap == 1 and UI_STATE.last_mouse_cap == 0 and not UI_STATE.mouse_handled then
                prompter_drawer.open = false
                save_settings()
                UI_STATE.mouse_handled = true
            end

            local table_y = drawer_top_y + header_h
            local base_row_h = S(28)
            local col_id_w = S(40)
            local col_text_x = drawer_x + col_id_w
            local col_text_w = prompter_drawer.width - col_id_w - S(5)
            
            local state_count = reaper.GetProjectStateChangeCount(0)
            local raw_query = prompter_drawer.filter.text
            local query = strip_accents(utf8_lower(raw_query))
            
            -- 1. Update RAW Marker Cache if project changed
            update_marker_cache()
            
            -- 2. Update FILTERED and LAYOUT Cache if needed
            if state_count ~= prompter_drawer.filtered_cache.state_count or 
               query ~= prompter_drawer.filtered_cache.query or
               prompter_drawer.width ~= prompter_drawer.filtered_cache.width or
               cfg.gui_scale ~= prompter_drawer.filtered_cache.gui_scale then
                
                prompter_drawer.filtered_cache.state_count = state_count
                prompter_drawer.filtered_cache.query = query
                prompter_drawer.filtered_cache.width = prompter_drawer.width
                prompter_drawer.filtered_cache.gui_scale = cfg.gui_scale
                prompter_drawer.filtered_cache.list = {}
                prompter_drawer.filtered_cache.total_h = 0
                
                gfx.setfont(F.std)
                for _, m in ipairs(prompter_drawer.marker_cache.markers) do
                    local full_id = "M" .. tostring(m.markindex)
                    local clean_name = strip_accents(utf8_lower(m.name))
                    local clean_id = utf8_lower(full_id)
                    
                    if query == "" or clean_id:find(query, 1, true) or clean_name:find(query, 1, true) then
                        local lines = {}
                        
                        -- Split by newlines first
                        local raw_lines = {}
                        for line in (m.name .. "\n"):gmatch("(.-)\n") do
                            table.insert(raw_lines, line)
                        end
                        if #raw_lines == 0 then table.insert(raw_lines, "") end

                        for _, raw_line in ipairs(raw_lines) do
                            local current_text = raw_line
                            if current_text == "" then
                                table.insert(lines, "")
                            else
                                -- Improved Word-based wrapping with hyphenation
                                local words = {}
                                for w in current_text:gmatch("%S+") do table.insert(words, w) end
                                if #words == 0 and #current_text > 0 then words = {current_text} end
                                
                                local cur_l = ""
                                local max_wrap_w = col_text_w - S(10)
                                
                                for _, w in ipairs(words) do
                                    local test_l = cur_l == "" and w or (cur_l .. " " .. w)
                                    if gfx.measurestr(test_l) <= max_wrap_w then
                                        cur_l = test_l
                                    else
                                        if cur_l ~= "" then table.insert(lines, cur_l) end
                                        
                                        -- If word itself is too long, break it with hyphenation
                                        if gfx.measurestr(w) > max_wrap_w then
                                            local partial = ""
                                            local w_len = utf8.len(w) or #w
                                            for j = 1, w_len do
                                                local char_start = utf8.offset(w, j)
                                                local char_end = (utf8.offset(w, j+1) or #w+1) - 1
                                                local char = w:sub(char_start, char_end)
                                                
                                                -- Check if adding char + optional hyphen fits
                                                local test_char = char
                                                if j < w_len then test_char = char .. "-" end
                                                
                                                if gfx.measurestr(partial .. test_char) > max_wrap_w then
                                                    if partial ~= "" then 
                                                        table.insert(lines, partial .. "-") 
                                                    end
                                                    partial = char
                                                else
                                                    partial = partial .. char
                                                end
                                            end
                                            cur_l = partial
                                        else
                                            cur_l = w
                                        end
                                    end
                                end
                                if cur_l ~= "" then table.insert(lines, cur_l) end
                            end
                        end
                        
                        local m_h = math.max(1, #lines) * base_row_h
                        table.insert(prompter_drawer.filtered_cache.list, {
                            id = full_id,
                            markindex = m.markindex,
                            name = m.name,
                            pos = m.pos,
                            color = m.color,
                            lines = lines,
                            h = m_h,
                            y_start = prompter_drawer.filtered_cache.total_h
                        })
                        prompter_drawer.filtered_cache.total_h = prompter_drawer.filtered_cache.total_h + m_h
                    end
                end
            end
            
            local filtered_markers = prompter_drawer.filtered_cache.list
            local total_list_h = prompter_drawer.filtered_cache.total_h
            
            -- --- KEYBOARD SHORTCUTS ---
            if input_queue then
                for _, key in ipairs(input_queue) do
                    if not prompter_drawer.filter.focus then
                        -- Ctrl+A (Select All Filtered)
                        if key == 1 then
                            prompter_drawer.selection = {}
                            for _, m in ipairs(filtered_markers) do
                                prompter_drawer.selection[m.markindex] = true
                            end
                            prompter_drawer.last_selected_idx = nil
                        end
                        -- Ctrl+D (Deselect All)
                        if key == 4 then
                            prompter_drawer.selection = {}
                            prompter_drawer.last_selected_idx = nil
                        end
                        -- Delete (6579564) or Backspace (8)
                        if key == 6579564 or key == 8 then
                            prompter_delete_logic()
                        end

                        -- Arrow Navigation: Up (30064), Down (1685026670)
                        if (key == 30064 or key == 1685026670) and #filtered_markers > 0 then
                            local curr_idx = prompter_drawer.last_selected_idx or 0
                            if curr_idx == 0 then curr_idx = 1 end
                            
                            local new_idx = (key == 30064) and (curr_idx - 1) or (curr_idx + 1)
                            new_idx = math.max(1, math.min(new_idx, #filtered_markers))
                            
                            local m = filtered_markers[new_idx]
                            if m then
                                prompter_drawer.selection = {[m.markindex] = true}
                                prompter_drawer.last_selected_idx = new_idx
                                reaper.SetEditCurPos(m.pos, true, false)
                                
                                -- Auto-Scroll
                                local view_h = gfx.h - table_y - S(10)
                                local item_top = m.y_start
                                local item_bottom = m.y_start + m.h
                                
                                if item_top < prompter_drawer.scroll_y then
                                    prompter_drawer.scroll_y = item_top
                                elseif item_bottom > prompter_drawer.scroll_y + view_h then
                                    prompter_drawer.scroll_y = item_bottom - view_h
                                end
                            end
                        end
                    end
                end
            end
            
            -- Draw List with Scroll
            local view_h = gfx.h - table_y - S(10)
            
            -- Handle Mousewheel (Update TARGET)
            if prompter_drawer.width > S(50) then
                if gfx.mouse_x >= drawer_x and gfx.mouse_x <= drawer_x + prompter_drawer.width and
                   gfx.mouse_y >= table_y and gfx.mouse_y <= gfx.h then
                    if gfx.mouse_wheel ~= 0 then
                        prompter_drawer.target_scroll_y = (prompter_drawer.target_scroll_y or prompter_drawer.scroll_y) - (gfx.mouse_wheel / 120 * base_row_h * 3)
                        gfx.mouse_wheel = 0
                    end
                end
            end

            -- Clamp Target Scroll
            local max_scroll = math.max(0, total_list_h - view_h)
            prompter_drawer.target_scroll_y = math.max(0, math.min(prompter_drawer.target_scroll_y or 0, max_scroll))

            -- Auto-Scroll to Active Marker (Centering)
            if prompter_drawer.active_markindex and prompter_drawer.active_markindex ~= prompter_drawer.last_active_markindex then
                -- Only trigger if not intentionally scrolling manually (mouse button not held in drawer)
                if not (gfx.mouse_cap & 1 == 1 and gfx.mouse_x >= drawer_x) then
                    -- Find target item in filtered list
                    local target_m = nil
                    for _, m in ipairs(filtered_markers) do
                        if m.markindex == prompter_drawer.active_markindex then
                            target_m = m
                            break
                        end
                    end
                    
                    if target_m then
                        local item_top = target_m.y_start
                        local item_bottom = target_m.y_start + target_m.h
                        -- Set NEW target to center item
                        prompter_drawer.target_scroll_y = (item_top + item_bottom) / 2 - (view_h / 2)
                        prompter_drawer.last_active_markindex = prompter_drawer.active_markindex
                    end
                end
            end

            -- Reset last_active if index is cleared
            if not prompter_drawer.active_markindex then prompter_drawer.last_active_markindex = -1 end

            -- Smooth Interpolation (Lerp)
            if math.abs((prompter_drawer.target_scroll_y or 0) - prompter_drawer.scroll_y) > 0.1 then
                prompter_drawer.scroll_y = prompter_drawer.scroll_y + ((prompter_drawer.target_scroll_y or 0) - prompter_drawer.scroll_y) * 0.2
            else
                prompter_drawer.scroll_y = prompter_drawer.target_scroll_y or 0
            end

            -- Final clamp for safety
            prompter_drawer.scroll_y = math.max(0, math.min(prompter_drawer.scroll_y, max_scroll))
            
            -- Draw Rows
            for idx, m in ipairs(filtered_markers) do
                local row_y = table_y + m.y_start - prompter_drawer.scroll_y
                
                -- Check visibility
                if row_y + m.h > table_y and row_y < gfx.h then
                    local row_hover = UI_STATE.window_focused and (gfx.mouse_x >= drawer_x and gfx.mouse_x <= drawer_x + prompter_drawer.width and
                                       gfx.mouse_y >= row_y and gfx.mouse_y <= row_y + m.h and
                                       gfx.mouse_y >= table_y)
                    
                    -- Strictly clip backgrounds to table_y
                    local bg_draw_y = math.max(row_y, table_y)
                    local bg_draw_h = math.min(row_y + m.h, gfx.h) - bg_draw_y
                    
                    if bg_draw_h > 0 then
                        -- Zebra Stripe
                        if idx % 2 == 0 then
                            set_color(UI.C_HILI_WHITE_LOW) -- Slight white highlight
                            gfx.rect(drawer_x, bg_draw_y, prompter_drawer.width, bg_draw_h, 1)
                        end
                        
                        if prompter_drawer.selection[m.markindex] then
                            set_color(UI.C_HILI_GREEN) -- Green selection (matching table)
                            gfx.rect(drawer_x, bg_draw_y, prompter_drawer.width, bg_draw_h, 1)
                        elseif m.markindex == prompter_drawer.active_markindex then
                            set_color(UI.C_HILI_GREEN) -- Active marker highlight (p_color)
                            gfx.rect(drawer_x, bg_draw_y, prompter_drawer.width, bg_draw_h, 1)
                        end
                        
                        if row_hover then
                            set_color(UI.C_HILI_WHITE)
                            gfx.rect(drawer_x, bg_draw_y, prompter_drawer.width, bg_draw_h, 1)
                            
                            -- LEFT CLICK
                            if gfx.mouse_cap & 1 == 1 and UI_STATE.last_mouse_cap & 1 == 0 and not UI_STATE.mouse_handled then
                                local now = reaper.time_precise()
                                local cap = gfx.mouse_cap
                                local is_ctrl = (cap & 4 == 4) or (cap & 32 == 32)
                                local is_shift = (cap & 8 == 8)
                                
                                if is_ctrl then
                                    if prompter_drawer.selection[m.markindex] then
                                        prompter_drawer.selection[m.markindex] = nil
                                    else
                                        prompter_drawer.selection[m.markindex] = true
                                        prompter_drawer.last_selected_idx = idx
                                    end
                                elseif is_shift and prompter_drawer.last_selected_idx then
                                    local start_v = math.min(prompter_drawer.last_selected_idx, idx)
                                    local end_v = math.max(prompter_drawer.last_selected_idx, idx)
                                    prompter_drawer.selection = {}
                                    for k = start_v, end_v do
                                        local d_m = filtered_markers[k]
                                        if d_m then prompter_drawer.selection[d_m.markindex] = true end
                                    end
                                else
                                    -- Normal Click
                                    if prompter_drawer.last_click_idx == m.markindex and (now - prompter_drawer.last_click_time < 0.35) then
                                        -- Double Click Zone Check
                                        if gfx.mouse_x < col_text_x then
                                            -- ID Column: Cycle Color
                                            local g_r, g_g, g_b = 0, 255, 0
                                            local orange_r, orange_g, orange_b = 255, 100, 100
                                            local target_color
                                            local cur_r, cur_g, cur_b = reaper.ColorFromNative((m.color or 0) & 0xFFFFFF)
                                            if cur_r == 0 and cur_g == 255 and cur_b == 0 then
                                                target_color = reaper.ColorToNative(orange_r, orange_g, orange_b) | 0x1000000
                                            else
                                                target_color = reaper.ColorToNative(g_r, g_g, g_b) | 0x1000000
                                            end
                                            reaper.SetProjectMarker4(0, m.markindex, false, m.pos, 0, m.name == "<пусто>" and "" or m.name, target_color, 0)
                                            reaper.UpdateTimeline()
                                            prompter_drawer.marker_cache.count = -1
                                            prompter_drawer.filtered_cache.state_count = -1
                                            table_data_cache.state_count = -1 -- FORCE UPDATE TABLE
                                            last_layout_state.state_count = -1 -- FORCE UPDATE LAYOUT
                                        else
                                            -- Text Column: Edit Text
                                            local mock_lines = {}
                                            local current_edit_idx = 1
                                            for l_idx, flt_m in ipairs(filtered_markers) do
                                                table.insert(mock_lines, { text = flt_m.name == "<пусто>" and "" or flt_m.name })
                                                if flt_m.markindex == m.markindex then current_edit_idx = l_idx end
                                            end

                                            local function drawer_marker_callback(new_text)
                                                push_undo("Редагування правки")
                                                -- Find marker index again (robustly)
                                                local target_idx = -1
                                                local m_count = reaper.CountProjectMarkers(0)
                                                for i = 0, m_count - 1 do
                                                    local _, isrgn, pos, _, _, markindex = reaper.EnumProjectMarkers3(0, i)
                                                    if not isrgn and (markindex == m.markindex or math.abs(pos - m.pos) < 0.001) then
                                                        target_idx = i
                                                        break
                                                    end
                                                end
                                                if target_idx ~= -1 then
                                                    reaper.SetProjectMarkerByIndex(0, target_idx, false, m.pos, 0, m.markindex, new_text, m.color or 0)
                                                else
                                                    reaper.SetProjectMarker4(0, m.markindex, false, m.pos, 0, new_text, m.color or 0, 0)
                                                end
                                                 
                                                ass_markers = capture_project_markers()
                                                prompter_drawer.marker_cache.count = -1
                                                prompter_drawer.filtered_cache.state_count = -1
                                                table_data_cache.state_count = -1 -- FORCE UPDATE TABLE
                                                last_layout_state.state_count = -1 -- FORCE UPDATE LAYOUT
                                                update_marker_cache()
                                                rebuild_regions()
                                                reaper.UpdateTimeline()
                                                reaper.UpdateArrange()
                                             end

                                            open_text_editor(m.name == "<пусто>" and "" or m.name, drawer_marker_callback, current_edit_idx, mock_lines, true)
                                        end
                                        prompter_drawer.last_click_idx = -1
                                    else
                                        -- Single Click: Navigation & Selection
                                        reaper.SetEditCurPos(m.pos, true, false)
                                        prompter_drawer.selection = {[m.markindex] = true}
                                        prompter_drawer.last_selected_idx = idx
                                        prompter_drawer.last_click_idx = m.markindex
                                        prompter_drawer.last_click_time = now
                                    end
                                end
                                UI_STATE.mouse_handled = true
                            -- RIGHT CLICK
                            elseif gfx.mouse_cap & 2 == 2 and UI_STATE.last_mouse_cap & 2 == 0 and not UI_STATE.mouse_handled then
                                if not prompter_drawer.selection[m.markindex] then
                                    prompter_drawer.selection = {[m.markindex] = true}
                                    prompter_drawer.last_selected_idx = idx
                                end
                                
                                gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
                                local sel_count = 0
                                for _ in pairs(prompter_drawer.selection) do sel_count = sel_count + 1 end
                                local menu_str = (sel_count > 1) and "Видалити обрані правки ("..sel_count..")" or "Видалити правку"
                                local ret = gfx.showmenu(menu_str)
                                if ret == 1 then
                                    prompter_delete_logic()
                                end
                                UI_STATE.mouse_handled = true
                            end
                        end
                    end
                    
                    -- ID ("M" + ID, respect boundary)
                    if row_y >= table_y and row_y + base_row_h <= gfx.h then
                        gfx.setfont(F.tip)
                        local draw_x = drawer_x + S(5)
                        local draw_y = row_y + (base_row_h - gfx.texth) / 2
                        
                        -- Entire ID string with marker color
                        if m.color and m.color ~= 0 then
                            local r, g, b = reaper.ColorFromNative(m.color & 0xFFFFFF)
                            set_color({r/255, g/255, b/255, 1})
                        else
                            -- Default marker color (Red in REAPER by default)
                            set_color(UI.C_RED)
                        end
                        gfx.x, gfx.y = draw_x, draw_y
                        gfx.drawstr(m.id)
                    end
                    
                    -- Name (Multiline + Highlighting)
                    gfx.setfont(F.std)
                    for l_idx, line_text in ipairs(m.lines) do
                        local line_y = row_y + (l_idx - 1) * base_row_h
                        -- Strictly clip each line to table_y
                        if line_y >= table_y and line_y + base_row_h <= gfx.h then
                            local lx = col_text_x + S(5)
                            local ly = line_y + (base_row_h - gfx.texth) / 2
                            
                            -- Search Highlighting
                            if #query > 0 then
                                local low_line = utf8_lower(line_text)
                                local start_pos = 1
                                while true do
                                    local s, e = low_line:find(query, start_pos, true)
                                    if not s then break end
                                    
                                    -- Calculate pixel position of the match
                                    local prefix = line_text:sub(1, s - 1)
                                    local match_str = line_text:sub(s, e)
                                    local px = lx + gfx.measurestr(prefix)
                                    local pw = gfx.measurestr(match_str)
                                    
                                    set_color(UI.C_HILI_YELLOW) -- Yellow highlight
                                    gfx.rect(px, line_y + S(2), pw, base_row_h - S(4), 1)
                                    
                                    start_pos = e + 1
                                end
                            end
                            
                            set_color(UI.C_TXT)
                            gfx.x, gfx.y = lx, ly
                            gfx.drawstr(line_text)
                        end
                    end
                end
            end
            
            -- Draw Scrollbar if needed
            if max_scroll > 0 then
                local sb_w = S(4)
                local sb_h = (view_h / total_list_h) * view_h
                local sb_y = table_y + (prompter_drawer.scroll_y / total_list_h) * view_h
                set_color(UI.C_HILI_WHITE_MID)
                gfx.rect(drawer_x + prompter_drawer.width - sb_w - S(1), sb_y, sb_w, sb_h, 1)
            end
            
            -- Draw resize handle
            local strip_w = S(2)
            local grab_w = S(12)
            local grab_h = S(40)
            
            local grab_x = cfg.p_drawer_left and (drawer_x + prompter_drawer.width) or (drawer_x - grab_w)
            local grab_y = drawer_top_y + (gfx.h - drawer_top_y - grab_h) / 2
            
            -- Helper: Check if mouse is strictly inside window
            -- Hover detection
            local handle_hover = UI_STATE.window_focused and UI_STATE.inside_window and (gfx.mouse_x >= grab_x - S(4) and gfx.mouse_x <= grab_x + grab_w + S(4))
            
            -- Draw 2px vertical line
            set_color(handle_hover and UI.C_HILI_WHITE_MID or UI.C_HILI_WHITE)
            gfx.rect(cfg.p_drawer_left and (drawer_x + prompter_drawer.width - S(1)) or drawer_x, drawer_top_y, strip_w, gfx.h - drawer_top_y, 1)
            
            -- Draw the central grab handle square only on hover
            if handle_hover or prompter_drawer.dragging then
                set_color(UI.C_WHITE, 0.8)
                gfx.rect(grab_x, grab_y, grab_w, grab_h, 1)
                
                -- Subtle border for the grab handle
                set_color(UI.C_BLACK_TRANSP)
                gfx.rect(grab_x, grab_y, grab_w, grab_h, 0)
            end
            
            -- Handle dragging (Priority: ignore UI_STATE.mouse_handled if hovering the handle strip)
            if handle_hover and (gfx.mouse_cap & 1 == 1) and UI_STATE.last_mouse_cap == 0 then
                prompter_drawer.dragging = true
                UI_STATE.mouse_handled = true
            end
            
            if prompter_drawer.dragging then
                if (gfx.mouse_cap & 1 == 1) then
                    local new_width
                    if cfg.p_drawer_left then
                        new_width = gfx.mouse_x - drawer_x
                    else
                        new_width = (drawer_x + prompter_drawer.width) - gfx.mouse_x
                    end
                    new_width = math.max(0, math.min(new_width, max_w))
                    
                    if new_width < S(80) then
                        prompter_drawer.open = false
                        prompter_drawer.dragging = false
                        prompter_drawer.width = S(300)
                        save_settings()
                    else
                        prompter_drawer.width = new_width
                    end
                else
                    -- Mouse released
                    prompter_drawer.dragging = false
                    save_settings()
                end
            end
        end
    end
end

local function draw_rich_line(line_spans, center_x, y_base, font_slot, font_name, base_size, no_assimilation, actor_name, available_w, content_offset_left, content_offset_right)
    -- ASSIMILATION LOGIC
    if cfg.text_assimilations and not no_assimilation then
        local rules = {
            -- 1. Найдовші ланцюжки та специфічні спрощення (4 та 3 літери)
            {"ться", "цця"},
            {"стськ", "сськ"},
            {"нтськ", "нськ"},
            {"нтст", "нст"},
            {"стці", "сці"},
            {"стч", "шч"},
            {"стд", "зд"},
            {"стс", "сс"},

            -- 2. Специфічні випадки дієслів (3 літери)
            {"шся", "сся"},
            {"чся", "цся"},

            -- 3. Подвійні приголосні на межі (2 літери)
            {"жці", "зці"},
            {"чці", "цці"},
            {"тці", "цці"},
            {"зж", "жж"},
            {"зш", "шш"},
            {"сш", "шш"},
            {"зч", "жч"},
            {"сч", "шч"},
            {"тч", "чч"},
            {"дч", "чч"},
            {"тс", "ц"} 
        }

        local new_spans = {}
        local function process_text(text, style_span, orig_word)
            if text == "" then return end
            local best_pos, best_rule = nil, nil
            local l_text = utf8_lower(text)
            for _, r in ipairs(rules) do
                local p = l_text:find(r[1], 1, true)
                if p and (not best_pos or p < best_pos) then best_pos, best_rule = p, r end
            end
            
            if best_pos then
                local before = text:sub(1, best_pos - 1)
                local match_len = #best_rule[1]
                local original_match = text:sub(best_pos, best_pos + match_len - 1)
                local remainder = text:sub(best_pos + match_len)
                local replacement = best_rule[2]
                if original_match == utf8_upper(original_match) then replacement = utf8_upper(replacement)
                elseif original_match == utf8_capitalize(utf8_lower(original_match)) then replacement = utf8_capitalize(replacement) end
                if before ~= "" then table.insert(new_spans, {text=before, b=style_span.b, i=style_span.i, u=style_span.u, s=style_span.s, orig_word=orig_word, comment=style_span.comment}) end
                table.insert(new_spans, {text = replacement, b=style_span.b, i=style_span.i, u=false, u_wave=true, s=style_span.s, orig_word=orig_word, comment=style_span.comment})
                process_text(remainder, style_span, orig_word)
            else
                table.insert(new_spans, {text=text, b=style_span.b, i=style_span.i, u=style_span.u, s=style_span.s, orig_word=orig_word, comment=style_span.comment})
            end
        end

        for _, span in ipairs(line_spans) do
            local segments = get_words_and_separators(span.text)
            for _, seg in ipairs(segments) do
                if seg.is_word and (not dict_modal.show) then process_text(seg.text, span, seg.text:gsub(acute, ""))
                else table.insert(new_spans, {text=seg.text, b=span.b, i=span.i, u=span.u, s=span.s, comment=span.comment}) end
            end
        end
        line_spans = new_spans
    end
    
    local total_w, pending_karaoke_comp = 0, 0
    for i, span in ipairs(line_spans) do
        local f_flags, effective_font = 0, font_name
        local measure_bold = span.b
        if cfg.karaoke_mode and (font_slot == F.lrg or font_slot == F.nxt) then measure_bold = true end
        if span.i then
            if font_name == "Helvetica" then effective_font = "Helvetica Oblique"
            else f_flags = f_flags + string.byte('i') end
        end
        if measure_bold then
            if effective_font == font_name then 
                if span.i then f_flags = string.byte('b') | (string.byte('i') << 8)
                else f_flags = string.byte('b') end
            elseif span.i and font_name == "Helvetica" then 
                effective_font = "Helvetica Bold Oblique"
                f_flags = 0
            end
        end
        gfx.setfont(font_slot, effective_font, base_size, f_flags)
        local measure_text = span.text:gsub(acute, "")
        if cfg.all_caps then measure_text = utf8_upper(measure_text) end
        span.width = gfx.measurestr(measure_text)
        span.height = gfx.texth
        
        if cfg.karaoke_mode and (font_slot == F.lrg or font_slot == F.nxt) then
            local nf, nfl = effective_font, f_flags
            if not span.b then
                if nf == "Helvetica Bold Oblique" then nf = "Helvetica Oblique" end
                if nfl == string.byte('b') then nfl = 0 end
            end
            gfx.setfont(font_slot, nf, base_size, nfl)
            local normal_w = gfx.measurestr(measure_text)
            gfx.setfont(font_slot, effective_font, base_size, f_flags)
            local target_w = gfx.measurestr(measure_text)
            local is_connected = false
            if i < #line_spans then
                local next_s = line_spans[i+1]
                if not span.text:match("%s$") and not next_s.text:match("^%s") then is_connected = true end
            end
            if is_connected then
                span.text_width = normal_w
                if span.i then
                    gfx.setfont(font_slot, effective_font, base_size, f_flags)
                    span.width = gfx.measurestr(measure_text)
                else span.width = normal_w end
                pending_karaoke_comp = pending_karaoke_comp + (target_w - normal_w)
            else
                span.width = target_w + pending_karaoke_comp
                if span.i then
                    gfx.setfont(font_slot, effective_font, base_size, f_flags)
                    span.text_width = gfx.measurestr(measure_text)
                else span.text_width = normal_w end
                pending_karaoke_comp = 0
            end
        end
        total_w = total_w + span.width
    end
    
    local actor_w, full_actor_text = 0, ""
    if cfg.show_actor_name_infront and actor_name and actor_name ~= "" then
        full_actor_text = "[" .. actor_name .. "] "
        gfx.setfont(font_slot, font_name, math.max(10, base_size - 2))
        actor_w = gfx.measurestr(full_actor_text)
        total_w = total_w + actor_w
    end

    local start_x 
    if cfg.p_align == "left" then 
        start_x = content_offset_left + 20
    elseif cfg.p_align == "right" then 
        start_x = gfx.w - content_offset_right - total_w - 20
    else 
        start_x = center_x - (total_w / 2) 
    end

    -- Clamp to visible area
    local min_x = content_offset_left + 20
    local max_x = gfx.w - content_offset_right - 20
    if start_x < min_x then start_x = min_x end
    if start_x + total_w > max_x and total_w < (max_x - min_x) then
        start_x = max_x - total_w
    end
    
    local cursor_x = start_x
    
    if cfg.show_actor_name_infront and actor_name and actor_name ~= "" then
        local r, g, b, a = gfx.r, gfx.g, gfx.b, gfx.a
        gfx.set(r, g, b, a * 0.45)
        gfx.setfont(font_slot, font_name, math.max(10, base_size - 2))
        gfx.x, gfx.y = cursor_x, y_base + 1
        gfx.drawstr(full_actor_text)
        gfx.set(r, g, b, a)
        cursor_x = cursor_x + actor_w
    end

    for _, span in ipairs(line_spans) do
        local f_flags, effective_font = 0, font_name
        if span.i then
           if font_name == "Helvetica" then effective_font = "Helvetica Oblique"
           else f_flags = f_flags + string.byte('i') end
        end
        if span.b then
            if effective_font == font_name then 
                if span.i then f_flags = string.byte('b') | (string.byte('i') << 8)
                else f_flags = string.byte('b') end
            elseif span.i and font_name == "Helvetica" then 
                effective_font = "Helvetica Bold Oblique"
                f_flags = 0
            end
        end
        gfx.setfont(font_slot, effective_font, base_size, f_flags)
        gfx.x, gfx.y = cursor_x, y_base
        
        local segments = get_words_and_separators(span.text)
        local temp_x = cursor_x
        for _, seg in ipairs(segments) do
            local measure_text = seg.text:gsub(acute, "")
            if cfg.all_caps then measure_text = utf8_upper(measure_text) end
            local sw = gfx.measurestr(measure_text)
            if seg.is_word and (not dict_modal.show) then
                local is_over = gfx.mouse_x >= temp_x - 2 and gfx.mouse_x <= temp_x + sw + 2 and gfx.mouse_y >= y_base - 5 and gfx.mouse_y <= y_base + span.height + 5
                if is_over then
                    if gfx.mouse_cap & 1 == 1 then
                        if UI_STATE.last_mouse_cap == 0 then
                            local clean = seg.text:gsub(acute, "")
                            if clean:find("[%a\128-\255]") then
                                word_trigger.active, word_trigger.start_time, word_trigger.word, word_trigger.triggered = true, reaper.time_precise(), span.orig_word or clean, false
                                word_trigger.hit_x, word_trigger.hit_y, word_trigger.hit_w, word_trigger.hit_h = temp_x, y_base, sw, span.height
                            end
                        elseif word_trigger.active and not word_trigger.triggered then
                            if reaper.time_precise() - word_trigger.start_time > 0.4 then word_trigger.triggered = true; trigger_dictionary_lookup(word_trigger.word) end
                        end
                    end
                elseif word_trigger.active and not word_trigger.triggered then
                    if not (gfx.mouse_x >= word_trigger.hit_x - 10 and gfx.mouse_x <= word_trigger.hit_x + word_trigger.hit_w + 10 and gfx.mouse_y >= word_trigger.hit_y - 10 and gfx.mouse_y <= word_trigger.hit_y + word_trigger.hit_h + 10) then word_trigger.active = false end
                end
            end
            temp_x = temp_x + sw
        end
        if word_trigger.active and gfx.mouse_cap & 1 == 0 then word_trigger.active = false end
        if span.comment and (not dict_modal.show) then
            if gfx.mouse_x >= cursor_x and gfx.mouse_x <= cursor_x + span.width and gfx.mouse_y >= y_base and gfx.mouse_y <= y_base + span.height then
                local id = tostring(span)
                if UI_STATE.tooltip_state.hover_id ~= id then UI_STATE.tooltip_state.hover_id, UI_STATE.tooltip_state.start_time = id, reaper.time_precise() end
                UI_STATE.tooltip_state.text, UI_STATE.tooltip_state.immediate = span.comment, true
            end
        end
        draw_text_with_stress_marks(span.text, cfg.all_caps)
        if span.comment then
            local sr, sg, sb, sa = gfx.r, gfx.g, gfx.b, gfx.a
            set_color(UI.GET_P_COLOR(0.15))
            local comment_width = span.text_width or span.width
            local comm_len = utf8.len(span.comment) or #span.comment
            local dash_w = math.max(S(3), S(8) - math.min(S(5), math.floor(comm_len / 15)))
            local gap_w = math.max(S(3), dash_w - S(1))
            local cur_dash_x = cursor_x
            while cur_dash_x < cursor_x + comment_width do
                local draw_w = math.min(dash_w, cursor_x + comment_width - cur_dash_x)
                gfx.rect(cur_dash_x, y_base + span.height - 2, draw_w, 3, 1)
                cur_dash_x = cur_dash_x + dash_w + gap_w
            end
            gfx.r, gfx.g, gfx.b, gfx.a = sr, sg, sb, sa
        end
        if span.u then local ly = y_base + span.height - 2; local uw = span.text_width or span.width; gfx.line(cursor_x, ly, cursor_x + uw, ly) end
        if span.u_wave then
            local wave_y, wave_h, step, x_pos, uw = y_base + span.height - S(2), S(2), S(3), cursor_x, span.text_width or span.width
            local end_x, up = x_pos + uw, true
            while x_pos < end_x do
                local next_x = math.min(x_pos + step, end_x)
                local y1, y2 = up and wave_y or (wave_y + wave_h), up and (wave_y + wave_h) or wave_y
                gfx.line(x_pos, y1, next_x, y2); x_pos, up = next_x, not up
            end
        end
        if span.s then local ly = y_base + span.height / 2; local sw = span.text_width or span.width; gfx.line(cursor_x, ly, cursor_x + sw, ly) end
        cursor_x = cursor_x + span.width
    end
    return start_x, y_base, total_w, (#line_spans > 0 and line_spans[1].height or gfx.texth)
end

local function handle_prompter_context_menu()
    if is_mouse_clicked(2) and not UI_STATE.mouse_handled then
        gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
        local is_docked = gfx.dock(-1) > 0
        local dock_check = is_docked and "!" or ""
        local slider_check = cfg.prompter_slider_mode and "• " or ""
        local menu = "Відобразити SubOverlay від Lionzz||Знайти нове слово в ГОРОСі|Відобразити Словник|" .. slider_check .. "Режим Слайдера||Глобальний пошук реплік||" .. dock_check .. "Закріпити вікно (Dock)"
        
        local ret = gfx.showmenu(menu)
        UI_STATE.mouse_handled = true -- Tell framework we handled this click
        
        if ret == 1 then
            run_satellite_script("overlay", "Lionzz_SubOverlay_Subass.lua", "Оверлею")
        elseif ret == 2 then
            local ok, input = reaper.GetUserInputs("ГОРОХ", 1, "Слово для пошуку:,extrawidth=200", "")
            if ok and input ~= "" then
                trigger_dictionary_lookup(input)
            end
        elseif ret == 3 then
            run_satellite_script("dictionary", "Subass_Dictionary.lua", "Словника")
        elseif ret == 4 then
            cfg.prompter_slider_mode = not cfg.prompter_slider_mode
            save_settings()
        elseif ret == 5 then
            if SEARCH_ITEM.open then SEARCH_ITEM.open() end
        elseif ret == 6 then
            -- Toggle Docking
            if is_docked then
                gfx.dock(0)
                reaper.SetExtState(section_name, "dock", "0", true)
            else
                gfx.dock(1) -- Dock to last valid docker
                reaper.SetExtState(section_name, "dock", tostring(gfx.dock(-1)), true)
            end
        end
    end
end

-- --- Shared Prompter Helpers ---

--- Helper: Count words in lines
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

--- Helper: Apply Karaoke Styling
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
                        local new_seg = {}
                        for k, v in pairs(span) do new_seg[k] = v end
                        new_seg.text = remainder
                        new_seg.b = (word_counter < active_idx) or span.b
                        table.insert(new_line, new_seg)
                    end
                    break
                end
                
                -- Space before word
                if s_start > current_idx then
                    local space = text:sub(current_idx, s_start - 1)
                    local new_seg = {}
                    for k, v in pairs(span) do new_seg[k] = v end
                    new_seg.text = space
                    new_seg.b = (word_counter < active_idx) or span.b
                    table.insert(new_line, new_seg)
                end
                
                -- The Word
                word_counter = word_counter + 1
                local word = text:sub(s_start, s_end)
                local new_seg = {}
                for k, v in pairs(span) do new_seg[k] = v end
                new_seg.text = word
                new_seg.b = (word_counter <= active_idx) or span.b
                table.insert(new_line, new_seg)
                
                current_idx = s_end + 1
            end
        end
        table.insert(new_lines, new_line)
    end
    return new_lines
end

--- Get corrections to display based on timing rules
--- @param cur_pos number
--- @param active_rgns table Current regions list
--- @return table markers, number total_h
local function get_corrections_to_draw(cur_pos, active_rgns, override_fsize)
    if not cfg.p_corr then return {}, 0 end
    
    local seen = {}
    local cor_markers = {}
    
    local function add(m)
        if not seen[m.markindex] then
            table.insert(cor_markers, m)
            seen[m.markindex] = true
        end
    end

    local m_list = prompter_drawer.marker_cache.markers
    if #m_list == 0 then return {}, 0 end

    -- RULE 1: Inside active region (Show all for full duration)
    if active_rgns and #active_rgns > 0 then
        for _, r in ipairs(active_rgns) do
            for _, m in ipairs(m_list) do
                if m.pos >= r.pos and m.pos < r.rgnend then
                    add(m)
                end
            end
        end
    end

    -- RULE 2: Outside regions (Show next upcoming marker regardless of time)
    local r_ptr = 1
    for _, m in ipairs(m_list) do
        local is_inside_any = false
        while r_ptr <= #regions and regions[r_ptr].rgnend <= m.pos do
            r_ptr = r_ptr + 1
        end
        
        if r_ptr <= #regions and m.pos >= regions[r_ptr].pos then
            is_inside_any = true
        end
        
        if not is_inside_any then
            if cur_pos >= m.pos and cur_pos < m.pos + 10 then
                add(m)
            end
        end
    end

    if #cor_markers == 0 then return {}, 0 end
    
    table.sort(cor_markers, function(a, b) return a.pos < b.pos end)
    
    local project_last_passed_pos = -1
    for _, m in ipairs(m_list) do
        if m.pos <= cur_pos and m.pos > project_last_passed_pos then
            project_last_passed_pos = m.pos
        end
    end
    
    local filtered_candidates = {}
    for _, m in ipairs(cor_markers) do
        if m.pos >= project_last_passed_pos then
            table.insert(filtered_candidates, m)
        end
    end
    
    if #filtered_candidates == 0 then return {}, 0 end

    local best_m = nil
    for _, m in ipairs(filtered_candidates) do
        if m.pos > cur_pos then
            best_m = m
            break
        end
    end
    
    if not best_m then
        best_m = filtered_candidates[#filtered_candidates]
    end
    
    cor_markers = { best_m }
    
    gfx.setfont(F.cor, cfg.p_font, override_fsize or cfg.c_fsize)
    local raw_lh = gfx.texth
    local line_h = math.floor(raw_lh * (cfg.c_lheight or 1.0))
    
    local total_lines = 0
    for _, m in ipairs(cor_markers) do
        local lines = parse_prompter_to_lines(m.name or "")
        total_lines = total_lines + #lines
    end
    
    return cor_markers, total_lines * line_h
end

--- Render corrections (markers) 
--- @param cor_markers table
--- @param y_offset number
local function render_corrections(cor_markers, y_offset, font_size, center_x, available_w, content_offset_left, content_offset_right)
    if #cor_markers == 0 then return end
    
    local fsize = font_size or cfg.c_fsize
    set_color(UI.GET_C_COLOR())
    gfx.setfont(F.cor, cfg.p_font, fsize)
    
    local raw_lh = gfx.texth
    local line_h = math.floor(raw_lh * (cfg.c_lheight or 1.0))
    local y_off = math.floor((line_h - raw_lh) / 2)
    local total_h = 0
    
    for i, m in ipairs(cor_markers) do
        local name = m.name or ""
        if name == "" then name = "<пусто>" end
        
        local c_x1, c_y1, c_x2, c_y2 = gfx.w, gfx.h, 0, 0
        local c_y = y_offset + total_h
        local spans_lines = parse_prompter_to_lines(name)
        
        for i_line, spans in ipairs(spans_lines) do
            local y = c_y + (i_line-1) * line_h
            local lx, ly, lw, l_h = draw_rich_line(spans, center_x, y + y_off, F.cor, cfg.p_font, fsize, true, nil, available_w, content_offset_left, content_offset_right)
            
            if lx < c_x1 then c_x1 = lx end
            if ly < c_y1 then c_y1 = ly end
            if lx + lw > c_x2 then c_x2 = lx + lw end
            if ly + l_h > c_y2 then c_y2 = ly + l_h end
            
            total_h = total_h + line_h
        end

        if is_mouse_clicked() and (not dict_modal.show) and (not UI_STATE.mouse_handled) then
            if gfx.mouse_x >= c_x1 - 20 and gfx.mouse_x <= c_x2 + 20 and
               gfx.mouse_y >= c_y1 - 10 and gfx.mouse_y <= c_y2 + 10 then
                UI_STATE.mouse_handled = true
                local now = reaper.time_precise()
                if UI_STATE.last_click_row == -5 and (now - UI_STATE.last_click_time) < 0.5 then
                    local mock_lines = {}
                    local current_edit_idx = 1
                    for idx, cm in ipairs(cor_markers) do
                        table.insert(mock_lines, { text = cm.name:gsub("<пусто>", "") })
                        if cm.markindex == m.markindex then current_edit_idx = idx end
                    end

                    local function marker_callback(new_text)
                        push_undo("Редагування правки")
                        local target_idx = -1
                        local marker_count = reaper.CountProjectMarkers(0)
                        for j = 0, marker_count - 1 do
                            local _, isrgn, pos, _, _, markindex = reaper.EnumProjectMarkers3(0, j)
                            if not isrgn then
                                if markindex == m.markindex or math.abs(pos - m.pos) < 0.001 then
                                    target_idx = j
                                    m.pos = pos
                                    break
                                end
                            end
                        end
                        if target_idx ~= -1 then reaper.SetProjectMarkerByIndex(0, target_idx, false, m.pos, 0, m.markindex, new_text, m.color or 0)
                        else reaper.SetProjectMarker4(0, m.markindex, false, m.pos, 0, new_text, m.color or 0, 0) end
                        ass_markers = capture_project_markers()
                        prompter_drawer.marker_cache.count = -1
                        table_data_cache.state_count = -1 
                        last_layout_state.state_count = -1 
                        update_marker_cache()
                        rebuild_regions()
                        reaper.UpdateTimeline()
                        reaper.UpdateArrange()
                    end
                    open_text_editor(m.name:gsub("<пусто>", ""), marker_callback, current_edit_idx, mock_lines, true)
                    UI_STATE.last_click_row = 0
                else
                    UI_STATE.last_click_time = now
                    UI_STATE.last_click_row = -5
                end
            end
        end
    end
end

local function handle_info_overlay_interaction(content_offset_left, content_offset_right, active_regions, override_time)
    if not cfg.p_info then return end
    
    local display_time = override_time or (reaper.GetPlayState() & 1 == 1 and reaper.GetPlayPosition() or reaper.GetCursorPosition())
    local left_str = format_timestamp(display_time + 0.001)
    
    -- Interaction: Left Info
    if left_str ~= "" then
        gfx.setfont(F.std)
        local tw, th = gfx.measurestr(left_str)
        if gfx.mouse_x >= (content_offset_left + S(10)) and gfx.mouse_x <= (content_offset_left + S(10)) + tw and
           gfx.mouse_y >= S(30) and gfx.mouse_y <= S(30) + th then
             if is_mouse_clicked() and not UI_STATE.mouse_handled then
                UI_STATE.mouse_handled = true
                local now = reaper.time_precise()
                if UI_STATE.last_click_row == -6 and (now - UI_STATE.last_click_time) < 0.3 then
                    set_clipboard(left_str)
                    show_snackbar("Скопійовано: " .. left_str, "info")
                    UI_STATE.last_click_row = 0
                else
                    UI_STATE.last_click_time = now
                    UI_STATE.last_click_row = -6
                end
            end
        end
    end
end

local function draw_info_overlay_graphics(content_offset_left, content_offset_right, active_regions, override_time)
    if not cfg.p_info then return end
    
    gfx.setfont(F.std)
    gfx.set(cfg.p_cr, cfg.p_cg, cfg.p_cb, 0.5)
    
    local display_time = override_time or (reaper.GetPlayState() & 1 == 1 and reaper.GetPlayPosition() or reaper.GetCursorPosition())
    local left_str = format_timestamp(display_time + 0.001)
    local right_str = ""
    
    if active_regions and #active_regions > 0 then
        local r = active_regions[1]
        right_str = tostring(r.idx) .. "/" .. tostring(#regions)
    end
    
    if left_str ~= "" then
        gfx.x = content_offset_left + S(10)
        gfx.y = S(30)
        gfx.drawstr(left_str)
    end
    
    if right_str ~= "" then
        local iw, ih = gfx.measurestr(right_str)
        gfx.x = gfx.w - iw - S(10) - content_offset_right
        gfx.y = S(30)
        gfx.drawstr(right_str)
    end
    
    gfx.set(cfg.p_cr, cfg.p_cg, cfg.p_cb, 1)
end

local function draw_prompter_slider(input_queue)
    local bg_r, bg_g, bg_b = cfg.bg_cr, cfg.bg_cg, cfg.bg_cb
    set_color({bg_r, bg_g, bg_b})
    gfx.rect(0, 0, gfx.w, gfx.h, 1)

    update_marker_cache()

    -- === EARLY DRAWER BUTTON CLICK CHECK ===
    if not prompter_drawer.open and prompter_drawer.has_markers_cache and prompter_drawer.has_markers_cache.result then
        local drawer_top_y = S(25)
        local btn_w = S(15)
        
        -- Calculate dynamic height (consistent with draw_prompter_drawer)
        gfx.setfont(F.tip)
        local btn_h = S(16)
        for _, code in utf8.codes("ПРАВКИ") do
            local _, ch = gfx.measurestr(utf8.char(code))
            btn_h = btn_h + ch - 1
        end

        local btn_x = cfg.p_drawer_left and 0 or (gfx.w - btn_w)
        local btn_y = drawer_top_y + (gfx.h - drawer_top_y - btn_h) / 2
        
        if gfx.mouse_x >= btn_x and gfx.mouse_x <= btn_x + btn_w and
           gfx.mouse_y >= btn_y and gfx.mouse_y <= btn_y + btn_h then
             if is_mouse_clicked(1) and not UI_STATE.mouse_handled then
                prompter_drawer.open = true
                UI_STATE.mouse_handled = true
                if not prompter_drawer.width or prompter_drawer.width < S(80) then
                    prompter_drawer.width = S(300)
                end
             end
        end
    end

    local content_offset_left, content_offset_right = 0, 0
    local mouse_over_drawer = false
    if prompter_drawer.open and prompter_drawer.width >= S(80) then
        if cfg.p_drawer_left then content_offset_left = prompter_drawer.width else content_offset_right = prompter_drawer.width end
        if cfg.p_drawer_left then
            if gfx.mouse_x < content_offset_left then mouse_over_drawer = true end
        else
            if gfx.mouse_x > gfx.w - content_offset_right then mouse_over_drawer = true end
        end
    end
    local available_w = gfx.w - content_offset_left - content_offset_right
    local center_x = content_offset_left + (available_w / 2)
    
    -- Catch Info Overlay Interaction EARLY to prevent fall-through
    local active_idx = -1
    local play_pos = reaper.GetPlayState() & 1 == 1 and reaper.GetPlayPosition() or reaper.GetCursorPosition()
    for i, rgn in ipairs(regions) do
        if play_pos >= rgn.pos and play_pos < rgn.rgnend then active_idx = i; break end
    end
    
    local current_active_regions = {}
    if active_idx ~= -1 then table.insert(current_active_regions, regions[active_idx]) end
    
    -- Initialize latched time if not set
    if not UI_STATE.latched_overlay_time then
        if active_idx ~= -1 then
            UI_STATE.latched_overlay_time = regions[active_idx].pos
            UI_STATE.latched_overlay_region = regions[active_idx]
        else
            UI_STATE.latched_overlay_time = play_pos
        end
    end
    
    -- Detect manual jump
    local edit_cursor = reaper.GetCursorPosition()
    local edit_cursor_changed = math.abs(edit_cursor - UI_STATE.last_edit_cursor) > 0.01
    local is_playing = (reaper.GetPlayState() & 1) == 1
    UI_STATE.last_edit_cursor = edit_cursor
    
    -- Update latched time on replica change or manual click
    if active_idx ~= -1 then
        if not UI_STATE.latched_overlay_region or UI_STATE.latched_overlay_region.idx ~= regions[active_idx].idx then
            UI_STATE.latched_overlay_time = regions[active_idx].pos
            UI_STATE.latched_overlay_region = regions[active_idx]
        elseif edit_cursor_changed then
            -- Manual click within region - show click position
            UI_STATE.latched_overlay_time = edit_cursor
        end
    elseif edit_cursor_changed then
        -- Manual click outside regions - show click position
        UI_STATE.latched_overlay_time = edit_cursor
        UI_STATE.latched_overlay_region = nil
    end
    
    handle_info_overlay_interaction(content_offset_left, content_offset_right, current_active_regions, UI_STATE.latched_overlay_time)

    local state_count = reaper.GetProjectStateChangeCount(0)
    local marker_state = prompter_drawer.marker_cache.count
    if prompter_slider_cache.state_count ~= state_count or prompter_slider_cache.marker_state ~= marker_state or prompter_slider_cache.w ~= available_w or 
       prompter_slider_cache.fsize ~= cfg.p_fsize or prompter_slider_cache.font ~= cfg.p_font or prompter_slider_cache.project_id ~= reaper.GetProjectName(0, "") or
       prompter_slider_cache.p_corr ~= cfg.p_corr or 
       prompter_slider_cache.p_lheight ~= cfg.p_lheight or prompter_slider_cache.c_lheight ~= cfg.c_lheight then
        
        prompter_slider_cache.state_count, prompter_slider_cache.marker_state, prompter_slider_cache.w, prompter_slider_cache.fsize, prompter_slider_cache.font = state_count, marker_state, available_w, cfg.p_fsize, cfg.p_font
        prompter_slider_cache.project_id = reaper.GetProjectName(0, "")
        prompter_slider_cache.p_corr = cfg.p_corr
        prompter_slider_cache.p_lheight = cfg.p_lheight
        prompter_slider_cache.c_lheight = cfg.c_lheight
        prompter_slider_cache.items, prompter_slider_cache.total_h = {}, 0
        
        local raw_items = {}
        for idx, rgn in ipairs(regions) do
            table.insert(raw_items, { type = "region", pos = rgn.pos, data = rgn, idx = idx })
        end
        if cfg.p_corr then
            for idx, m in ipairs(prompter_drawer.marker_cache.markers) do
                table.insert(raw_items, { type = "correction", pos = m.pos, data = m, idx = idx })
            end
        end
        table.sort(raw_items, function(a, b) return a.pos < b.pos end)

        local max_w = available_w - S(40)
        
        for _, raw in ipairs(raw_items) do
            if raw.type == "region" then
                local rgn = raw.data
                local p_lines = parse_prompter_to_lines(rgn.name)
                local flattened = {}
                for _, pl in ipairs(p_lines) do
                    for _, span in ipairs(pl) do table.insert(flattened, span) end
                end
                
                local target_fsize = cfg.p_fsize
                local min_fsize = 12
                local lines, item_h, lh
                
                local actor_indent = 0
                if cfg.show_actor_name_infront and rgn.actor and rgn.actor ~= "" then
                    gfx.setfont(F.lrg, cfg.p_font, S(target_fsize - 2))
                    actor_indent = gfx.measurestr("[" .. rgn.actor .. "] ")
                end

                repeat
                    gfx.setfont(F.lrg, cfg.p_font, S(target_fsize))
                    lh = math.floor(gfx.texth * cfg.p_lheight)
                    
                    local current_actor_indent = 0
                    if actor_indent > 0 then
                        gfx.setfont(F.lrg, cfg.p_font, S(target_fsize - 2))
                        current_actor_indent = gfx.measurestr("[" .. rgn.actor .. "] ")
                    end

                    lines = wrap_rich_text(flattened, max_w, F.lrg, cfg.p_font, S(target_fsize), false, current_actor_indent)
                    item_h = #lines * lh + S(40)
                    if item_h < gfx.h * 0.7 or target_fsize <= min_fsize then break end
                    target_fsize = target_fsize - 2
                until false
                
                table.insert(prompter_slider_cache.items, {type = "region", h = item_h, lines = lines, y = prompter_slider_cache.total_h, fsize = S(target_fsize), lh = lh, region = rgn, region_idx = raw.idx})
                prompter_slider_cache.total_h = prompter_slider_cache.total_h + item_h
            else
                -- Correction Item
                local m = raw.data
                local name = m.name or ""
                if name == "" then name = "<пусто>" end
                local p_lines = parse_prompter_to_lines(name)
                local flattened = {}
                for _, pl in ipairs(p_lines) do
                    for _, span in ipairs(pl) do table.insert(flattened, span) end
                end
                
                gfx.setfont(F.cor, cfg.p_font, S(cfg.c_fsize))
                local lh = math.floor(gfx.texth * (cfg.c_lheight or 1.0))
                local lines = wrap_rich_text(flattened, max_w, F.cor, cfg.p_font, S(cfg.c_fsize), false, 0)
                local item_h = #lines * lh + S(20)
                
                table.insert(prompter_slider_cache.items, {type = "correction", h = item_h, lines = lines, y = prompter_slider_cache.total_h, fsize = S(cfg.c_fsize), lh = lh, marker = m})
                prompter_slider_cache.total_h = prompter_slider_cache.total_h + item_h
            end
        end
    end

    local now = reaper.time_precise()
    local is_playing = reaper.GetPlayState() & 1 == 1
    local pos_jumped = math.abs(play_pos - (UI_STATE.last_tracked_pos or 0)) > 0.5

    -- Auto-resume auto-scroll on significant jump or playback start
    if pos_jumped or (is_playing and not UI_STATE.last_play_state) then
        UI_STATE.skip_auto_scroll = false
    end
    UI_STATE.last_tracked_pos = play_pos
    UI_STATE.last_play_state = is_playing

    if gfx.mouse_wheel ~= 0 and not mouse_over_drawer then
        UI_STATE.prompter_slider_target_y = UI_STATE.prompter_slider_target_y - (gfx.mouse_wheel * 0.5)
        
        -- Clamp scroll position to content bounds
        local min_y = 0
        local max_y = prompter_slider_cache.total_h
        if prompter_slider_cache.items and #prompter_slider_cache.items > 0 then
            local first_item = prompter_slider_cache.items[1]
            local last_item = prompter_slider_cache.items[#prompter_slider_cache.items]
            min_y = first_item.y + first_item.h / 2
            max_y = last_item.y + last_item.h / 2
        end
        UI_STATE.prompter_slider_target_y = math.max(min_y, math.min(max_y, UI_STATE.prompter_slider_target_y))
        
        gfx.mouse_wheel = 0
        UI_STATE.skip_auto_scroll = true
    end
    if is_mouse_clicked(1) then
        if not UI_STATE.mouse_handled then
            UI_STATE.skip_auto_scroll = false 
        end
    end

    if active_idx ~= -1 and not UI_STATE.skip_auto_scroll then
        for _, item in ipairs(prompter_slider_cache.items) do
            if item.type == "region" and item.region_idx == active_idx then
                UI_STATE.prompter_slider_target_y = item.y + item.h / 2
                break
            end
        end
    end

    local diff = UI_STATE.prompter_slider_target_y - UI_STATE.prompter_slider_y
    if math.abs(diff) > 0.1 then UI_STATE.prompter_slider_y = UI_STATE.prompter_slider_y + diff * 0.15 else UI_STATE.prompter_slider_y = UI_STATE.prompter_slider_target_y end

    local screen_center_y = gfx.h / 2
    local draw_y_offset = screen_center_y - UI_STATE.prompter_slider_y

    for i, item in ipairs(prompter_slider_cache.items) do
        local y_top = item.y + draw_y_offset
        local y_bottom = y_top + item.h
        if y_bottom > 0 and y_top < gfx.h then
            -- Interaction detection
            if is_mouse_clicked(1) and not UI_STATE.mouse_handled then
                if gfx.mouse_x >= content_offset_left and gfx.mouse_x <= gfx.w - content_offset_right and
                   gfx.mouse_y >= y_top and gfx.mouse_y <= y_bottom then
                    
                    if item.type == "region" then
                        if UI_STATE.last_click_row == -100 - i and (now - UI_STATE.last_click_time) < 0.35 then
                            -- DOUBLE CLICK: Open Editor
                            local rgn = item.region
                            for idx, line in ipairs(ass_lines) do
                                if math.abs(line.t1 - rgn.pos) < 0.01 and 
                                   math.abs(line.t2 - rgn.rgnend) < 0.01 and
                                   UTILS.compare_sub_text(line.text, rgn.name) then
                                    local edit_line = line
                                    open_text_editor(line.text, function(new_text)
                                        push_undo("Редагування тексту")
                                        edit_line.text = new_text
                                        rebuild_regions()
                                    end, idx, ass_lines)
                                    break
                                end
                            end
                            UI_STATE.last_click_row = 0
                        else
                            -- SINGLE CLICK: Scroll to
                            reaper.SetEditCurPos(item.region.pos, true, false)
                            UI_STATE.skip_auto_scroll = false
                            UI_STATE.last_click_time = now
                            UI_STATE.last_click_row = -100 - i
                        end
                    elseif item.type == "correction" then
                         if UI_STATE.last_click_row == -100 - i and (now - UI_STATE.last_click_time) < 0.35 then
                            -- DOUBLE CLICK: Open Editor for Correction
                            local m = item.marker
                            local function marker_callback(new_text)
                                push_undo("Редагування правки")
                                local target_idx = -1
                                local marker_count = reaper.CountProjectMarkers(0)
                                for j = 0, marker_count - 1 do
                                    local _, isrgn, pos, _, _, markindex = reaper.EnumProjectMarkers3(0, j)
                                    if not isrgn then
                                        if markindex == m.markindex or math.abs(pos - m.pos) < 0.001 then
                                            target_idx = j; m.pos = pos; break
                                        end
                                    end
                                end

                                if target_idx ~= -1 then
                                    reaper.SetProjectMarkerByIndex(0, target_idx, false, m.pos, 0, m.markindex, new_text, m.color or 0)
                                else
                                    reaper.SetProjectMarker4(0, m.markindex, false, m.pos, 0, new_text, m.color or 0, 0)
                                end
                                ass_markers = capture_project_markers()
                                prompter_drawer.marker_cache.count = -1
                                table_data_cache.state_count = -1 
                                last_layout_state.state_count = -1 
                                update_marker_cache()
                                rebuild_regions()
                                reaper.UpdateTimeline()
                                reaper.UpdateArrange()
                            end
                            open_text_editor(m.name:gsub("<пусто>", ""), marker_callback, 1, {{text = m.name:gsub("<пусто>", "")}}, true)
                            UI_STATE.last_click_row = 0
                        else
                            -- SINGLE CLICK: Scroll to
                            reaper.SetEditCurPos(item.marker.pos, true, false)
                            UI_STATE.skip_auto_scroll = false
                            UI_STATE.last_click_time = now
                            UI_STATE.last_click_row = -100 - i
                        end
                    end
                    UI_STATE.mouse_handled = true
                end
            end

            -- Drawing
            local lines_to_draw = item.lines
            local text_y = y_top + (item.type == "region" and S(20) or S(10))
            
            if item.type == "region" then
                local is_active = (item.region_idx == active_idx)
                local alpha = is_active and 1.0 or 0.2
                set_color(UI.GET_P_COLOR(alpha))
                
                if cfg.karaoke_mode and is_active then
                    local w_count = count_words_in_lines(item.lines)
                    local k_idx = get_karaoke_word_index(item.region.pos, item.region.rgnend, play_pos, w_count)
                    if k_idx then
                        lines_to_draw = apply_karaoke_style(item.lines, k_idx)
                    end
                end

                for idx, line in ipairs(lines_to_draw) do
                    local act = (idx == 1) and item.region.actor or nil
                    draw_rich_line(line, center_x, text_y, F.lrg, cfg.p_font, item.fsize, false, act, available_w, content_offset_left, content_offset_right)
                    text_y = text_y + item.lh
                end
            else
                -- Correction Rendering
                local m = item.marker
                local alpha = 1.0 -- Corrections are always visible if they are in view? 
                -- Or maybe dim them if they are far? Let's keep them bright for now as they are "pravki".
                set_color(UI.GET_C_COLOR(alpha))
                
                for idx, line in ipairs(lines_to_draw) do
                    draw_rich_line(line, center_x, text_y, F.cor, cfg.p_font, item.fsize, true, nil, available_w, content_offset_left, content_offset_right)
                    text_y = text_y + item.lh
                end
            end
        end
    end

    -- Info Overlay graphics (at the end of content)
    local current_active_regions = {}
    if active_idx ~= -1 then table.insert(current_active_regions, regions[active_idx]) end
    draw_info_overlay_graphics(content_offset_left, content_offset_right, current_active_regions, UI_STATE.latched_overlay_time)

    if cfg.p_drawer then draw_prompter_drawer(input_queue) end

    handle_prompter_context_menu()
end

local function draw_prompter(input_queue)
    if cfg.prompter_slider_mode then
        draw_prompter_slider(input_queue)
        return
    end

    -- Draw Custom Background
    set_color(UI.GET_BG_COLOR())
    gfx.rect(0, 0, gfx.w, gfx.h, 1)

    -- === EARLY DRAWER BUTTON CLICK CHECK ===
    if not prompter_drawer.open and prompter_drawer.has_markers_cache and prompter_drawer.has_markers_cache.result then
        local drawer_top_y = S(25)
        local btn_w = S(15)
        
        -- Calculate dynamic height (consistent with draw_prompter_drawer)
        gfx.setfont(F.tip)
        local btn_h = S(16)
        for _, code in utf8.codes("ПРАВКИ") do
            local _, ch = gfx.measurestr(utf8.char(code))
            btn_h = btn_h + ch - 1
        end

        local btn_x = cfg.p_drawer_left and 0 or (gfx.w - btn_w)
        local btn_y = drawer_top_y + (gfx.h - drawer_top_y - btn_h) / 2
        
        if gfx.mouse_x >= btn_x and gfx.mouse_x <= btn_x + btn_w and
           gfx.mouse_y >= btn_y and gfx.mouse_y <= btn_y + btn_h then
             if is_mouse_clicked(1) and not UI_STATE.mouse_handled then
                prompter_drawer.open = true
                UI_STATE.mouse_handled = true
                if not prompter_drawer.width or prompter_drawer.width < S(80) then
                    prompter_drawer.width = S(300)
                end
             end
        end
    end

    -- === DRAWER CONTENT OFFSET CALCULATION ===
    local content_offset_left = 0
    local content_offset_right = 0
    if prompter_drawer.open and prompter_drawer.width >= S(80) then
        if cfg.p_drawer_left then
            content_offset_left = prompter_drawer.width
        else
            content_offset_right = prompter_drawer.width
        end
    end
    local available_w = gfx.w - content_offset_left - content_offset_right
    local center_x = content_offset_left + (available_w / 2)
    -- === END DRAWER OFFSET ===

    -- Logic: Use Play Position if playing, otherwise Edit Cursor
    local play_state = reaper.GetPlayState()
    local cur_pos = 0
    if (play_state & 1) == 1 then
        cur_pos = reaper.GetPlayPosition()
    else
        cur_pos = reaper.GetCursorPosition()
    end

    -- EARLY INTERACTION CHECK
    local active_regions_for_info = {}
    for _, rgn in ipairs(regions) do
        if cur_pos >= rgn.pos and cur_pos < rgn.rgnend then
            table.insert(active_regions_for_info, rgn)
        end
    end
    
    -- Initialize latched time if not set
    if not UI_STATE.latched_overlay_time then
        if #active_regions_for_info > 0 then
            UI_STATE.latched_overlay_time = active_regions_for_info[1].pos
            UI_STATE.latched_overlay_region = active_regions_for_info[1]
        else
            UI_STATE.latched_overlay_time = cur_pos
        end
    end
    
    -- Detect manual jump (edit cursor change)
    local edit_cursor = reaper.GetCursorPosition()
    local edit_cursor_changed = math.abs(edit_cursor - UI_STATE.last_edit_cursor) > 0.01
    UI_STATE.last_edit_cursor = edit_cursor
    
    -- Update latched time on replica change or manual click
    if #active_regions_for_info > 0 then
        if not UI_STATE.latched_overlay_region or UI_STATE.latched_overlay_region.idx ~= active_regions_for_info[1].idx then
            UI_STATE.latched_overlay_time = active_regions_for_info[1].pos
            UI_STATE.latched_overlay_region = active_regions_for_info[1]
        elseif edit_cursor_changed then
            -- Manual click within region - show click position
            UI_STATE.latched_overlay_time = edit_cursor
        end
    elseif edit_cursor_changed then
        -- Manual click outside regions - show click position
        UI_STATE.latched_overlay_time = edit_cursor
        UI_STATE.latched_overlay_region = nil
    end
    
    handle_info_overlay_interaction(content_offset_left, content_offset_right, active_regions_for_info, UI_STATE.latched_overlay_time)

    update_marker_cache()

    -- Find ALL regions that contain the current position
    local active_regions = {}
    local next_rgn = nil
    local next_rgn2 = nil
    local prev_rgn_end = 0
    for _, rgn in ipairs(regions) do
        if cur_pos >= rgn.pos and cur_pos < rgn.rgnend then
            table.insert(active_regions, rgn)
        end
        if rgn.pos > cur_pos then
            if not next_rgn then
                next_rgn = rgn
            elseif not next_rgn2 then
                next_rgn2 = rgn
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
                local col = UTILS.get_cps_color(max_cps)
                set_color({col[1], col[2], col[3], 0.8})
                gfx.rect(content_offset_left, S(25), available_w, S(2), 1) -- Top warning strip
            end
        end
    end
    
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
    local function render_next_replica(next_rgn, y_position_mode, override_fsize, y_offset)
        if not next_rgn then return 0, 0 end
        y_offset = y_offset or 0
        
        set_color(UI.GET_N_COLOR())
        
        -- Parse Text (with Cache)
        local display_name = next_rgn.name
        if not display_name or display_name:gsub("{.-}", ""):match("^%s*$") then display_name = "<пусто>" end
        if not draw_prompter_cache.next_cache[display_name] then
            draw_prompter_cache.next_cache[display_name] = parse_prompter_to_lines(display_name)
        end
        local n_lines = draw_prompter_cache.next_cache[display_name]
        
        -- Scale Next
        local max_w = available_w - S(40)
        local n_max_raw_w = 0
        local n_flags = 0
        if cfg.karaoke_mode then n_flags = string.byte('b') end
        
        local base_fsize = override_fsize or cfg.n_fsize
        gfx.setfont(F.nxt, cfg.p_font, base_fsize, n_flags)
        
        local next_actor_w = 0
        if cfg.show_actor_name_infront and next_rgn.actor and next_rgn.actor ~= "" then
            gfx.setfont(F.nxt, cfg.p_font, math.max(10, base_fsize - 2))
            next_actor_w = gfx.measurestr("[" .. next_rgn.actor .. "] ")
            gfx.setfont(F.nxt, cfg.p_font, base_fsize, n_flags)
        end

        for _, line in ipairs(n_lines) do
            local raw = ""
            for _, span in ipairs(line) do 
                local t = span.text:gsub(acute, "")
                if cfg.all_caps then t = utf8_upper(t) end
                raw = raw .. t 
            end
            local w = gfx.measurestr(raw) + next_actor_w
            if w > n_max_raw_w then n_max_raw_w = w end
        end
        
        local n_draw_size = base_fsize
        if n_max_raw_w > max_w then
            local ratio = max_w / n_max_raw_w
            n_draw_size = math.floor(n_draw_size * ratio)
            if n_draw_size < S(10) then n_draw_size = S(10) end
        end
        
        gfx.setfont(F.nxt, cfg.p_font, n_draw_size, n_flags)
        local raw_lh = gfx.texth
        local n_lh = math.floor(raw_lh * (cfg.n_lheight or 1.0))
        local n_total_h = #n_lines * n_lh
        
        -- Center text vertically within line height if needed
        local y_off = math.floor((n_lh - raw_lh) / 2)
        
        -- Position: bottom (when in region) or center (when not in region)
        local n_start_y
        if type(y_position_mode) == "number" then
            n_start_y = y_position_mode + y_offset
        elseif y_position_mode == "bottom" then
            n_start_y = gfx.h - n_total_h - S(10) - y_offset
        elseif y_position_mode == "top" then
            n_start_y = S(50) + y_offset
        else -- "center"
            n_start_y = (gfx.h - n_total_h) / 2 + y_offset
        end
        
        -- Bounds for click
        local n_x1, n_y1, n_x2, n_y2 = gfx.w, gfx.h, 0, 0
        
        for i, line in ipairs(n_lines) do
            local y = n_start_y + (i-1) * n_lh
            -- Pass next_rgn.actor if available
            local actor_arg = (i==1 and next_rgn) and next_rgn.actor or nil 
            -- Assuming we only show actor on first line of multi-line? 
            if i > 1 then actor_arg = nil end
            
            local lx, ly, lw, l_h = draw_rich_line(line, center_x, y + y_off, F.nxt, cfg.p_font, n_draw_size, false, actor_arg, available_w, content_offset_left, content_offset_right)
            
            if lx < n_x1 then n_x1 = lx end
            if ly < n_y1 then n_y1 = ly end
            if lx + lw > n_x2 then n_x2 = lx + lw end
            if ly + l_h > n_y2 then n_y2 = ly + l_h end
        end
        
        -- Double-click on next text to edit
        if is_mouse_clicked() and (not dict_modal.show) and (not UI_STATE.mouse_handled) then
            if gfx.mouse_x >= n_x1 - 20 and gfx.mouse_x <= n_x2 + 20 and
               gfx.mouse_y >= n_y1 - 10 and gfx.mouse_y <= n_y2 + 10 then
                UI_STATE.mouse_handled = true
                local now = reaper.time_precise()
                if UI_STATE.last_click_row == -2 and (now - UI_STATE.last_click_time) < 0.5 then
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
                    UI_STATE.last_click_row = 0
                else
                    UI_STATE.last_click_time = now
                    UI_STATE.last_click_row = -2 -- Use -2 as marker for next text
                end
            end
        end
        
        return n_total_h, n_start_y
    end


    
    if region_idx >= 0 then
        local retval, isrgn, pos, rgnend, name, idx = reaper.EnumProjectMarkers(region_idx)
        
        if isrgn then
            -- Collect ALL text blocks to display
            local max_w = available_w - S(40)
            local total_combined_height = 0
            local all_text_blocks = {}
            local S_GAP = S(15)
            


            for region_num, rgn in ipairs(active_regions) do
                local lines
                
                -- Use cache for first region (optimization)
                if region_num == 1 then
                    local display_name = rgn.name
                    if not display_name or display_name:gsub("{.-}", ""):match("^%s*$") then display_name = "<пусто>" end
                    if display_name ~= draw_prompter_cache.last_text then
                        draw_prompter_cache.lines = parse_prompter_to_lines(display_name)
                        draw_prompter_cache.last_text = display_name
                    end
                    lines = draw_prompter_cache.lines
                    
                    -- KARAOKE LOGIC APPLICATION
                    if cfg.karaoke_mode then
                        -- Clone structure to avoid modifying cache permanently for this frame
                        -- (Actually we parse every time lazily, but modifying 'lines' which is ref to cache is bad)
                        local w_count = count_words_in_lines(lines)
                        local k_idx = get_karaoke_word_index(rgn.pos, rgn.rgnend, cur_pos, w_count)
                        if k_idx then
                            lines = apply_karaoke_style(lines, k_idx)
                        end
                    end
                else
                    -- Parse text for other regions
                    local display_name = rgn.name
                    if not display_name or display_name:gsub("{.-}", ""):match("^%s*$") then display_name = "<пусто>" end
                    lines = parse_prompter_to_lines(display_name)
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
                
                local current_actor_w = 0
                if cfg.show_actor_name_infront and rgn.actor and rgn.actor ~= "" then
                    gfx.setfont(F.lrg, cfg.p_font, math.max(10, cfg.p_fsize - 2))
                    current_actor_w = gfx.measurestr("[" .. rgn.actor .. "] ")
                end

                gfx.setfont(F.lrg, cfg.p_font, cfg.p_fsize, p_flags)
                
                for _, line in ipairs(lines) do
                    local raw = ""
                    for _, span in ipairs(line) do 
                        local t = span.text:gsub(acute, "")
                        if cfg.all_caps then t = utf8_upper(t) end
                        raw = raw .. t 
                    end
                    local w = gfx.measurestr(raw) + current_actor_w
                    if w > max_raw_w then max_raw_w = w end
                end
                
                local draw_size = cfg.p_fsize
                if max_raw_w > max_w then
                    local ratio = max_w / max_raw_w
                    draw_size = math.floor(draw_size * ratio)
                    if draw_size < 10 then draw_size = 10 end
                end
                
                gfx.setfont(F.lrg, cfg.p_font, draw_size, p_flags)
                local raw_lh = gfx.texth
                local lh = math.floor(raw_lh * (cfg.p_lheight or 1.0))
                local block_height = #lines * lh
                
                table.insert(all_text_blocks, {
                    lines = lines,
                    draw_size = draw_size,
                    lh = lh,
                    raw_lh = raw_lh,
                    block_height = block_height,
                    actor = rgn.actor -- Capture actor
                })
                
                if #all_text_blocks > 1 then
                    total_combined_height = total_combined_height + S_GAP
                end
                total_combined_height = total_combined_height + block_height
            end
            
            -- --- VERTICAL SCALING LOGIC ---
            local next_r = nil
            local next_r2 = nil
            for _, r in ipairs(regions) do
                if r.pos > cur_pos then
                    if not next_r then next_r = r
                    else next_r2 = r break end
                end
            end
            
            -- --- COORDINATED LAYOUT LOGIC ---
            -- 1. Estimate Unscaled Heights
            local unscaled_next_h = 0
            if cfg.p_next and next_r then
                gfx.setfont(F.nxt, cfg.p_font, cfg.n_fsize)
                local n_lines = parse_prompter_to_lines(next_r.name)
                unscaled_next_h = #n_lines * math.floor(gfx.texth * (cfg.n_lheight or 1.0))
                
                if cfg.show_next_two and next_r2 then
                    local n_lines2 = parse_prompter_to_lines(next_r2.name)
                    unscaled_next_h = unscaled_next_h + S(15) + #n_lines2 * math.floor(gfx.texth * (cfg.n_lheight or 1.0))
                end
            end
            
            local cms, unscaled_ch = get_corrections_to_draw(cur_pos, active_regions)
            
            -- Calculate total unscaled stack height
            local total_unscaled_h = total_combined_height
            if unscaled_ch > 0 then 
                total_unscaled_h = total_unscaled_h + (total_unscaled_h > 0 and S_GAP or 0) + unscaled_ch 
            end
            if unscaled_next_h > 0 then 
                total_unscaled_h = total_unscaled_h + (total_unscaled_h > 0 and S_GAP or 0) + unscaled_next_h 
            end
            
            local available_h = gfx.h - 100 -- Margin for info overlay and padding
            local v_scale = 1.0
            if total_unscaled_h > available_h then
                v_scale = available_h / total_unscaled_h
            end

            -- 2. Apply scaling and update final heights
            total_combined_height = 0
            for i, block in ipairs(all_text_blocks) do
                block.draw_size = math.max(10, math.floor(block.draw_size * v_scale))
                gfx.setfont(F.lrg, cfg.p_font, block.draw_size, p_flags)
                block.raw_lh = gfx.texth
                block.lh = math.floor(block.raw_lh * (cfg.p_lheight or 1.0))
                block.block_height = #block.lines * block.lh
                
                if i > 1 then total_combined_height = total_combined_height + S_GAP end
                total_combined_height = total_combined_height + block.block_height
            end
            
            local scaled_n_fsize = math.max(10, math.floor(cfg.n_fsize * v_scale))
            local next_h = 0
            if cfg.p_next and next_r then
                gfx.setfont(F.nxt, cfg.p_font, scaled_n_fsize)
                local n_lines = parse_prompter_to_lines(next_r.name)
                next_h = #n_lines * math.floor(gfx.texth * (cfg.n_lheight or 1.0))
                
                if cfg.show_next_two and next_r2 then
                    local n_lines2 = parse_prompter_to_lines(next_r2.name)
                    next_h = next_h + S(15) + #n_lines2 * math.floor(gfx.texth * (cfg.n_lheight or 1.0))
                end
            end

            local cms, _ = get_corrections_to_draw(cur_pos, active_regions)
            local max_c_raw_w = 0
            gfx.setfont(F.cor, cfg.p_font, cfg.c_fsize)
            for _, m in ipairs(cms) do
                local c_lines = parse_prompter_to_lines(m.name or "")
                for _, line in ipairs(c_lines) do
                    local raw = ""
                    for _, span in ipairs(line) do raw = raw .. span.text:gsub(acute, "") end
                    if cfg.all_caps then raw = utf8_upper(raw) end
                    local w = gfx.measurestr(raw)
                    if w > max_c_raw_w then max_c_raw_w = w end
                end
            end
            
            local c_draw_size = cfg.c_fsize
            if max_c_raw_w > max_w then
                c_draw_size = math.floor(c_draw_size * (max_w / max_c_raw_w))
            end

            local scaled_c_fsize = math.max(10, math.floor(c_draw_size * v_scale))
            local _, corrections_h = get_corrections_to_draw(cur_pos, active_regions, scaled_c_fsize)
            
            -- Recalculate Final Pooled Height for Centering
            local active_corr_h = total_combined_height
            if corrections_h > 0 then 
                active_corr_h = active_corr_h + (active_corr_h > 0 and S_GAP or 0) + corrections_h 
            end

            -- Set active marker for drawer synchronization
            prompter_drawer.active_markindex = (corrections_h > 0) and cms[1].markindex or nil
            -- --- END VERTICAL SCALING ---

            -- Calculate starting Y position: 
            local start_y = (gfx.h - active_corr_h) / 2
            if cfg.p_valign == "top" then
                start_y = S(60)
            elseif cfg.p_valign == "bottom" then
                local next_reserve = S(30)
                if cfg.p_next and next_r then
                    next_reserve = next_h + S(30)
                end
                start_y = gfx.h - active_corr_h - next_reserve
            end

            local top_limit = S(50) -- Account for info overlay and top margin
            local bottom_limit = (next_h > 0) and (gfx.h - next_h - S(30)) or (gfx.h - S(50))
            
            -- Resolve collisions: if we hit boundaries, shift text
            if start_y < top_limit then start_y = top_limit end
            if start_y + active_corr_h > bottom_limit then
                start_y = bottom_limit - active_corr_h
                -- Final safety check against top if everything is too tight
                if start_y < top_limit then start_y = top_limit end
            end
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
                    -- Draw centered on screen (accounting for drawer offset)
                    local wave_h = gfx.h * 0.5 
                    local progress = (cur_pos - rgn.pos) / (rgn.rgnend - rgn.pos)
                    draw_waveform_bg(map, content_offset_left + 20, (gfx.h - wave_h) / 2, available_w - 40, wave_h, progress)
                end
            end
 
            -- Draw all text blocks with prompt color
            set_color(UI.GET_P_COLOR())
            for block_idx, block in ipairs(all_text_blocks) do
                local block_x1, block_y1, block_x2, block_y2 = gfx.w, gfx.h, 0, 0
                
                -- Apply vertical scaling to block dimensions
                local scaled_draw_size = math.max(10, math.floor(block.draw_size * v_scale))
                local scaled_lh = math.floor(block.lh * v_scale)
                local scaled_raw_lh = math.floor(block.raw_lh * v_scale)
                local y_off = math.floor((scaled_lh - scaled_raw_lh) / 2)
                
                for i, line in ipairs(block.lines) do
                    local y = current_y + (i-1) * scaled_lh
                    -- Show actor on first line of block only
                    local act = (i == 1) and block.actor or nil
                    local lx, ly, lw, l_h = draw_rich_line(line, center_x, y + y_off, F.lrg, cfg.p_font, scaled_draw_size, false, act, available_w, content_offset_left, content_offset_right)
                    
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
                
                local actual_block_h = #block.lines * scaled_lh
                current_y = current_y + actual_block_h + S_GAP
                
                -- Draw separator if not the last block
                if block_idx < #all_text_blocks then
                    local sep_w = S(40)
                    local sep_y = current_y - S_GAP / 2
                    set_color(UI.GET_P_COLOR(0.2))
                    gfx.line(center_x - sep_w/2, sep_y, center_x + sep_w/2, sep_y)
                    set_color(UI.GET_P_COLOR(1.0))
                end
            end
            
            -- Double-click to edit (check all blocks)
            if is_mouse_clicked() and (not dict_modal.show) and (not UI_STATE.mouse_handled) then
                -- Check which block was clicked
                for _, bounds in ipairs(block_bounds) do
                    if gfx.mouse_x >= bounds.x1 and gfx.mouse_x <= bounds.x2 and
                       gfx.mouse_y >= bounds.y1 and gfx.mouse_y <= bounds.y2 then
                        UI_STATE.mouse_handled = true
                        local now = reaper.time_precise()
                        if UI_STATE.last_click_row == -1 and (now - UI_STATE.last_click_time) < 0.5 then
                            -- Find the corresponding ass_line for this region
                            for i, line in ipairs(ass_lines) do
                                if math.abs(line.t1 - bounds.region.pos) < 0.01 and 
                                   math.abs(line.t2 - bounds.region.rgnend) < 0.01 and
                                   UTILS.compare_sub_text(line.text, bounds.region.name) then
                                    local edit_line = line
                                    open_text_editor(line.text, function(new_text)
                                        push_undo("Редагування тексту")
                                        edit_line.text = new_text
                                        rebuild_regions()
                                    end, i, ass_lines)
                                    break
                                end
                            end
                            UI_STATE.last_click_row = 0
                        else
                            UI_STATE.last_click_time = now
                            UI_STATE.last_click_row = -1
                        end
                        break -- Stop checking other blocks once we found a hit
                    end
                end
            end
            
            -- Show Next Line & Corrections Drawing
            -- (next_r and current_k were already calculated above)
            if corrections_h > 0 then
                render_corrections(cms, current_y, scaled_c_fsize, center_x, available_w, content_offset_left, content_offset_right)
                current_y = current_y + corrections_h + S_GAP
            end
            
            -- Draw Next Line
            if cfg.p_next and next_r then
                local next_y = "bottom"
                if cfg.next_attach then
                    next_y = current_y + S(cfg.next_padding)
                end
                
                if cfg.show_next_two and next_r2 then
                    if cfg.next_attach then
                        local h1, y1 = render_next_replica(next_r, next_y, scaled_n_fsize)
                        render_next_replica(next_r2, y1 + h1 + S(15), scaled_n_fsize)
                    else
                        local h2, y2 = render_next_replica(next_r2, "bottom", scaled_n_fsize)
                        render_next_replica(next_r, "bottom", scaled_n_fsize, h2 + S(15))
                    end
                else
                    render_next_replica(next_r, next_y, scaled_n_fsize)
                end
            end
        else
            set_color(UI.GET_P_COLOR(0.3))
            gfx.setfont(F.std)
            local txt = "Нічого немає (Суфлер не активний)"
            local tw, th = gfx.measurestr(txt)
            gfx.x = content_offset_left + (available_w - tw) / 2
            gfx.y = (gfx.h - th) / 2
            if cfg.p_valign == "top" then gfx.y = S(70)
            elseif cfg.p_valign == "bottom" then gfx.y = gfx.h - th - S(50) end
            gfx.drawstr(txt)
        end
    else
        -- Not in any region, but show next upcoming region if enabled
        -- Minimal Fix: Allow entering this block if markers exist, even if regions are empty
        if (cfg.p_next and cfg.always_next and #regions > 0) or (#prompter_drawer.marker_cache.markers > 0) then
            -- Find the next region after current position
            local next_rgn = nil
            local next_rgn2 = nil
            for _, rgn in ipairs(regions) do
                if rgn.pos > cur_pos then
                    if not next_rgn then next_rgn = rgn
                    else next_rgn2 = rgn break end
                end
            end
            
            if next_rgn then
                -- Estimate height for wait mode
                gfx.setfont(F.nxt, cfg.p_font, cfg.n_fsize)
                local n_lines = parse_prompter_to_lines(next_rgn.name)
                local n_h_est = #n_lines * math.floor(gfx.texth * (cfg.n_lheight or 1.0)) + 30
                if cfg.show_next_two and next_rgn2 then
                    local n_lines2 = parse_prompter_to_lines(next_rgn2.name)
                    n_h_est = n_h_est + #n_lines2 * math.floor(gfx.texth * (cfg.n_lheight or 1.0)) + 15
                end
                
                local cms, ch = get_corrections_to_draw(cur_pos, nil)
                prompter_drawer.active_markindex = (ch > 0) and cms[1].markindex or nil
                local c_h_est = ch -- get_corrections_to_draw now returns pixel height!
                if ch > 0 then c_h_est = ch + 20 end
                
                local total_wait_h = n_h_est + c_h_est
                local available_h = gfx.h - 100
                
                local wait_draw_n_fsize = cfg.n_fsize
                local wait_draw_c_fsize = cfg.c_fsize
                
                if total_wait_h > available_h then
                    local v_scale = available_h / total_wait_h
                    wait_draw_n_fsize = math.max(10, math.floor(wait_draw_n_fsize * v_scale))
                    wait_draw_c_fsize = math.max(10, math.floor(wait_draw_c_fsize * v_scale))
                end

                local n_h, n_y = 0, gfx.h - 10
                if cfg.p_next and cfg.always_next then
                    if cfg.show_next_two and next_rgn2 then
                        local h2, y2 = render_next_replica(next_rgn2, "bottom", wait_draw_n_fsize)
                        n_h, n_y = render_next_replica(next_rgn, "bottom", wait_draw_n_fsize, h2 + S(15))
                        n_h = n_h + h2 + S(15) -- Total group height for corrections positioning
                    else
                        n_h, n_y = render_next_replica(next_rgn, "bottom", wait_draw_n_fsize)
                    end
                end
                
                if ch > 0 then
                    gfx.setfont(F.cor, cfg.p_font, wait_draw_c_fsize)
                    render_corrections(cms, n_y - ch - 15, wait_draw_c_fsize, center_x, available_w, content_offset_left, content_offset_right)
                end
            else
                -- Just corrections? (if playhead after all subtitles but markers are ahead, or no regions at all)
                local cms, ch = get_corrections_to_draw(cur_pos, nil)
                prompter_drawer.active_markindex = (ch > 0) and cms[1].markindex or nil

                if ch > 0 then
                    -- Minimal Fix: Render the actual corrections instead of just a placeholder text
                    local cor_fsize = cfg.c_fsize
                    gfx.setfont(F.cor, cfg.p_font, cor_fsize)
                    local cor_y = (gfx.h - ch) / 2
                    if cfg.p_valign == "top" then cor_y = S(70)
                    elseif cfg.p_valign == "bottom" then cor_y = gfx.h - ch - S(50) end
                    render_corrections(cms, cor_y, cor_fsize, center_x, available_w, content_offset_left, content_offset_right)
                else
                    set_color(UI.GET_P_COLOR(0.3))
                    gfx.setfont(F.std)
                    local txt = "Нічого немає (Суфлер не активний)"
                    local tw, th = gfx.measurestr(txt)
                    gfx.x = content_offset_left + (available_w - tw) / 2
                    gfx.y = (gfx.h - th) / 2
                    if cfg.p_valign == "top" then gfx.y = S(70)
                    elseif cfg.p_valign == "bottom" then gfx.y = gfx.h - th - S(50) end
                    gfx.drawstr(txt)
                end
            end
        end
    end
    
    -- Draw Countdown Timer (Only in gaps when no active replica is present)
    if cfg.count_timer and next_rgn and #active_regions == 0 then
        local gap_to_next = next_rgn.pos - cur_pos
        local total_gap = next_rgn.pos - prev_rgn_end

        -- --- JUMP TO NEXT BUTTON ---
        if gap_to_next > 10 then
            local btn_w, btn_h = 60, 100
            local btn_x = gfx.w - content_offset_right - btn_w - 20
            local btn_y = (gfx.h - btn_h) / 2
            
            local hover = UI_STATE.window_focused and (gfx.mouse_x >= btn_x and gfx.mouse_x <= btn_x + btn_w and
                           gfx.mouse_y >= btn_y and gfx.mouse_y <= btn_y + btn_h)
                   
            -- Draw arrow (vector)
            set_color(hover and {cfg.p_cr, cfg.p_cg, cfg.p_cb, 0.8} or {cfg.p_cr, cfg.p_cg, cfg.p_cb, 0.4})
            local ax = btn_x + 25
            local ay = btn_y + btn_h / 2
            local sz = 25
            gfx.line(ax, ay - sz, ax + sz, ay, 1)
            gfx.line(ax + sz, ay, ax, ay + sz, 1)
            -- Double arrow for "fast forward" feel
            gfx.line(ax - 15, ay - sz, ax + sz - 15, ay, 1)
            gfx.line(ax + sz - 15, ay, ax - 15, ay + sz, 1)

            if hover and gfx.mouse_cap == 1 and UI_STATE.last_mouse_cap == 0 and not UI_STATE.mouse_handled then
                reaper.SetEditCurPos(next_rgn.pos, true, true) -- true, true = move view AND seek play
                
                -- Robust focus return for macOS
                return_focus_to_reaper()
                
                UI_STATE.mouse_handled = true
            end
        end

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
            
            -- Center of available space
            local tw, th = gfx.measurestr(countdown_str)
            gfx.x = content_offset_left + (available_w - tw) / 2
            gfx.y = (gfx.h - th) / 2
            gfx.drawstr(countdown_str)
        end

        -- Progress Bars
        if gap_to_next > 0 and total_gap >= 0.1 then
            local progress = 1.0 - math.min(1.0, gap_to_next / math.max(1.0, total_gap))
            
            if cfg.count_timer_bottom then
                -- Bottom Horizontal Progress Bar
                local bar_h = 6
                local avail_w = gfx.w - content_offset_left - content_offset_right
                local bar_w = avail_w * progress
                -- Draw centered
                gfx.rect(content_offset_left + (avail_w - bar_w)/2, gfx.h - bar_h, bar_w, bar_h, 1)
            else
                -- Side Progress Bars (Vertical)
                local bar_w = 8
                local bar_h = gfx.h * progress
                -- Left Bar
                gfx.rect(content_offset_left, gfx.h - bar_h + 25, bar_w, bar_h, 1)
                -- Right Bar
                gfx.rect(gfx.w - content_offset_right - bar_w, gfx.h - bar_h + 25, bar_w, bar_h, 1)
            end
        end

        gfx.set(cfg.p_cr, cfg.p_cg, cfg.p_cb)
    end

    -- Info Overlay graphics (OVER EVERYTHING ELSE)
    draw_info_overlay_graphics(content_offset_left, content_offset_right, active_regions, UI_STATE.latched_overlay_time)

    -- === DRAWER UI DRAWING (OVER EVERYTHING) ===
    if cfg.p_drawer then
        draw_prompter_drawer(input_queue)
    end
    -- === END DRAWER UI ===

    -- Handle Right-Click Context Menu for Overlay
    handle_prompter_context_menu()
end

local last_settings_h = 0 -- Persistent storage for Settings height

-- Helper to draw a custom color picker square
local function draw_custom_color_box(bx, screen_y, box_sz, r, g, b, on_change, is_selected)
    -- Background
    if is_selected then
        set_color({r, g, b})
    else
        set_color(UI.C_BLACK_OVERLAY)
    end
    gfx.rect(bx, screen_y, box_sz, box_sz, 1)
    
    -- Border
    if is_selected then
        set_color(UI.C_WHITE)
        draw_selection_border(bx, screen_y, box_sz, box_sz)
    else
        set_color(UI.C_HILI_WHITE_MID)
        gfx.rect(bx, screen_y, box_sz, box_sz, 0)
    end
    
    -- Plus sign
    if is_selected then
        local lum = (r * 0.299 + g * 0.587 + b * 0.114)
        set_color(lum > 0.5 and UI.C_BLACK or UI.C_WHITE)
    else
        set_color(UI.C_LIGHT_GREY)
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
    local x_start = S(20)
    local start_y = S(50)
    local content_h = 0 
    
    -- Setup Scroll Logic for Settings (Smooth)
    local avail_h = gfx.h - start_y
    local max_scroll = math.max(0, last_settings_h - avail_h) -- Use PREVIOUS frame's height
    
    -- Accumulate target scroll
    if gfx.mouse_wheel ~= 0 then
        UI_STATE.target_scroll_y = UI_STATE.target_scroll_y - (gfx.mouse_wheel * 0.25)
        -- Immediate Clamp on input
        if UI_STATE.target_scroll_y < 0 then UI_STATE.target_scroll_y = 0 end
        if UI_STATE.target_scroll_y > max_scroll then UI_STATE.target_scroll_y = max_scroll end
        
        gfx.mouse_wheel = 0
    end
    
    -- Smoothly interpolate
    local diff = UI_STATE.target_scroll_y - UI_STATE.scroll_y
    if math.abs(diff) > 0.5 then
        UI_STATE.scroll_y = UI_STATE.scroll_y + (diff * 0.8)
    else
        UI_STATE.scroll_y = UI_STATE.target_scroll_y
    end
    
    -- HARD Clamp UI_STATE.scroll_y before drawing to prevent "blinking"
    if UI_STATE.scroll_y < 0 then UI_STATE.scroll_y = 0 end
    if UI_STATE.scroll_y > max_scroll then UI_STATE.scroll_y = max_scroll end
    
    -- Reset tooltip state at the start of settings drawing
    UI_STATE.tooltip_state.text = ""
    gfx.setfont(F.std)

    -- Helper to offset Y and check boundaries (INTEGER ROUNDING)
    local function get_y(offset)
        return start_y + offset - math.floor(UI_STATE.scroll_y)
    end
    
    -- Button Helper wrapper for scrolling
    local y_cursor = 0 -- Relative Y from start (Moved up for closure capture)
    
    local function s_btn(x, y_rel, w, h, text, tooltip, bg_col)
        local screen_y = get_y(y_rel)
        if screen_y + h < start_y or screen_y > gfx.h then return false end -- Cull
        
        local hover = UI_STATE.window_focused and (gfx.mouse_x >= x and gfx.mouse_x <= x+w and gfx.mouse_y >= screen_y and gfx.mouse_y <= screen_y+h)
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
            if UI_STATE.tooltip_state.hover_id ~= id then
                UI_STATE.tooltip_state.hover_id = id
                UI_STATE.tooltip_state.start_time = reaper.time_precise()
            end
            UI_STATE.tooltip_state.text = tooltip
        end

        if hover and is_mouse_clicked() then return true end
        return false
    end

    local function checkbox_box(show_param_checkbox, x_checkbox_start, y_checkbox_start)
        set_color(UI.C_ED_GUTTER)
        gfx.rect(x_checkbox_start, y_checkbox_start, S(20), S(20), 0)
        if show_param_checkbox then
            set_color(UI.C_TXT)
            gfx.line(x_checkbox_start + S(4), y_checkbox_start + S(10), x_checkbox_start + S(8), y_checkbox_start + S(16))
            gfx.line(x_checkbox_start + S(5), y_checkbox_start + S(10), x_checkbox_start + S(9), y_checkbox_start + S(16))
            gfx.line(x_checkbox_start + S(8), y_checkbox_start + S(16), x_checkbox_start + S(16), y_checkbox_start + S(4))
            gfx.line(x_checkbox_start + S(9), y_checkbox_start + S(16), x_checkbox_start + S(17), y_checkbox_start + S(4))
        end
    end

    -- Checkbox Helper
    local function checkbox(x, y_rel, text, checked, tooltip)
        local chk_sz = S(20)
        local screen_y = get_y(y_rel)
        if screen_y + chk_sz < start_y or screen_y > gfx.h then return false end -- Cull
        
        checkbox_box(checked, x, screen_y)
    
        gfx.setfont(F.std)
        gfx.x, gfx.y = x + chk_sz + S(10), screen_y + S(2)
        gfx.drawstr(text)
        set_color(UI.C_TXT)
        
        local hover = UI_STATE.window_focused and (gfx.mouse_x >= x and gfx.mouse_x <= x + chk_sz + gfx.measurestr(text) + S(10) and
                       gfx.mouse_y >= screen_y and gfx.mouse_y <= screen_y + chk_sz)

        if hover then
            set_color(UI.C_HILI_WHITE) -- Slight white highlight
            gfx.rect(x - S(2), screen_y - S(2), chk_sz + gfx.measurestr(text) + S(18), chk_sz + S(4), 1)
            set_color(UI.C_TXT)
        end
        
        if hover and tooltip then
            local id = "chk_" .. text .. "_" .. y_rel
            if UI_STATE.tooltip_state.hover_id ~= id then
                UI_STATE.tooltip_state.hover_id = id
                UI_STATE.tooltip_state.start_time = reaper.time_precise()
            end
            UI_STATE.tooltip_state.text = tooltip
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
            local hover = UI_STATE.window_focused and (gfx.mouse_x >= x and gfx.mouse_x <= x + tw and gfx.mouse_y >= screen_y and gfx.mouse_y <= screen_y + th)
            if hover then
                local id = "txt_" .. text .. "_" .. y_rel
                if UI_STATE.tooltip_state.hover_id ~= id then
                    UI_STATE.tooltip_state.hover_id = id
                    UI_STATE.tooltip_state.start_time = reaper.time_precise()
                end
                UI_STATE.tooltip_state.text = tooltip
            end
        end
    end
    
    -- Section Header helper
    local function s_section(y_rel, title)
        local screen_y = get_y(y_rel)
        if screen_y + S(30) < start_y or screen_y > gfx.h then return end
        
        -- Line
        set_color(UI.C_MEDIUM_GREY)
        gfx.rect(x_start, screen_y + S(10), gfx.w - S(40), 1, 1)
        
        -- Title background
        gfx.setfont(F.std)
        local tw = gfx.measurestr(title)
        set_color(UI.C_BG)
        gfx.rect(x_start, screen_y, tw + S(10), S(20), 1)
        
        -- Title text
        set_color(UI.C_LIGHT_GREY)
        gfx.setfont(F.std)
        gfx.x = x_start
        gfx.y = screen_y
        gfx.drawstr(title)
    end
    
    -- Color Palette Helper
    local function draw_color_palette(x, palette, cur_r, cur_g, cur_b, on_change, scale)
        scale = scale or 1.0
        local box_sz = S(30)
        local gap = S(10)
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
                    set_color(UI.C_WHITE)
                    draw_selection_border(bx, screen_y, box_sz, box_sz)
                else
                    set_color(UI.C_HILI_WHITE_MID)
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
    -- 0. API КЛЮЧІ
    -- ═══════════════════════════════════════════
    s_section(y_cursor, "API КЛЮЧІ")
    y_cursor = y_cursor + S(35)
    
    -- Gemini API Key
    local gemini_btn_col = UI.C_BTN
    if cfg.gemini_key_status == 200 or cfg.gemini_key_status == 429 then
        gemini_btn_col = UI.C_BTN_MEDIUM -- Greenish (Theme Aware)
    elseif cfg.gemini_api_key ~= "" and cfg.gemini_key_status ~= 0 then
        gemini_btn_col = UI.C_BTN_ERROR -- Reddish (Theme Aware)
    end

    if s_btn(x_start, y_cursor, S(200), S(30), "Gemini API ключ", "Ключ доступу до Gemini AI для функцій перефразування та редагування тексту.", gemini_btn_col) then
        local retval, key = reaper.GetUserInputs("Gemini API Key", 1, "Ключ API:,extrawidth=300", cfg.gemini_api_key)
        if retval then
            cfg.gemini_api_key = key
            save_settings()
            validate_gemini_key(cfg.gemini_api_key)
        end
    end

    -- ElevenLabs API Key
    local eleven_btn_col = UI.C_BTN
    if cfg.eleven_key_status == 200 then
        eleven_btn_col = UI.C_BTN_MEDIUM -- Greenish (Theme Aware)
    elseif cfg.eleven_api_key ~= "" and cfg.eleven_key_status ~= 0 then
        eleven_btn_col = UI.C_BTN_ERROR -- Reddish (Theme Aware)
    end

    if s_btn(x_start + S(220), y_cursor, S(200), S(30), "ElevenLabs API ключ", "Ключ доступу до ElevenLabs для озвучування преміальними голосами.", eleven_btn_col) then
        local retval, key = reaper.GetUserInputs("ElevenLabs API Key", 1, "Ключ API:,extrawidth=300", cfg.eleven_api_key)
        if retval then
            cfg.eleven_api_key = key
            save_settings()
            validate_eleven_key(cfg.eleven_api_key)
        end
    end

    y_cursor = y_cursor + S(60)
    -- ═══════════════════════════════════════════
    -- 1. ГЛОБАЛЬНІ ДІЇ
    -- ═══════════════════════════════════════════
    s_section(y_cursor, "ГЛОБАЛЬНІ ДІЇ")
    y_cursor = y_cursor + S(35)

    -- Delete regions (Danger Zone)
    if s_btn(x_start, y_cursor, S(200), S(30), "Видалити ВСІ регіони", "Видаляє всі регіони з проекту REAPER.\nДія незворотна!", UI.C_BTN_ERROR) then
        delete_all_regions()
    end

    -- Update Check
    if s_btn(x_start + S(220), y_cursor, S(200), S(30), "Перевірити оновлення", "Перевірити наявність нових версій Subass на сервері.") then
        check_for_updates()
    end
    y_cursor = y_cursor + S(60)

    -- ═══════════════════════════════════════════
    -- 2. ІМПОРТ ТА РОБОТА З ТЕКСТОМ (Import & Data)
    -- ═══════════════════════════════════════════
    s_section(y_cursor, "ІМПОРТ ТА РОБОТА З ТЕКСТОМ")
    y_cursor = y_cursor + S(35)

    -- Max Wrap Length
    local t_y = get_y(y_cursor)
    if t_y + S(20) > start_y and t_y < gfx.h then
        s_text(x_start, y_cursor, "Макс. довжина рядка:", F.std, "Максимальна кількість символів у рядку до переносу.")
        gfx.x = x_start + S(150)
        gfx.drawstr(tostring(cfg.wrap_length))
        if s_btn(x_start + S(200), y_cursor - S(10), S(30), S(30), "－") then
            cfg.wrap_length = math.max(10, cfg.wrap_length - 2)
            save_settings()
        end
        if s_btn(x_start + S(235), y_cursor - S(10), S(30), S(30), "＋") then
            cfg.wrap_length = math.min(100, cfg.wrap_length + 2)
            save_settings()
        end
    end
    y_cursor = y_cursor + S(45)

    -- Split Actors in SRT
    s_text(x_start, y_cursor, "Розбивка SRT за акторами:", F.std, "Автоматичне визначення акторів за шаблонами (ім'я): або [ім'я]:")
    y_cursor = y_cursor + S(25)
    local srt_split_options = {"():", "[]:", "none"}
    local srt_split_labels = {"(Актор):", "[Актор]:", "Вимк."}
    local split_btn_w = S(90)
    for i, opt in ipairs(srt_split_options) do
        local bx = x_start + ((i-1) * (split_btn_w + S(10)))
        local is_sel = (cfg.auto_srt_split == opt)
        local btn_bg = is_sel and UI.C_BTN_MEDIUM or UI.C_BTN
        if s_btn(bx, y_cursor, split_btn_w, S(30), srt_split_labels[i], nil, btn_bg) then
            cfg.auto_srt_split = opt
            save_settings()
        end
    end
    y_cursor = y_cursor + S(60)

    if checkbox(x_start, y_cursor, "Випадковий колір актора при імпорті", cfg.random_color_actors, "Кожному новому актору буде присвоєно унікальний колір.") then
        cfg.random_color_actors = not cfg.random_color_actors
        rebuild_regions()
        save_project_data()
        save_settings()
    end
    y_cursor = y_cursor + S(35)
    if checkbox(x_start, y_cursor, "Показувати асиміляцію", cfg.text_assimilations, "Відображати фонетичні підказки (асиміляції) в тексті.") then
        cfg.text_assimilations = not cfg.text_assimilations
        save_settings()
    end
    y_cursor = y_cursor + S(35)
    if checkbox(x_start, y_cursor, "Автоматично виправляти невірне кодування (CP1251)", cfg.fix_CP1251, "Якщо файл містить побите кодування CP1251, він буде автоматично виправлений.\n!!Це може призвести до втрати деяких символів!!\nПриклад: перетворить це \"œŒ¯Û, ÏÂÏ.\" в це \"ПрОшу, мем.\"") then
        cfg.fix_CP1251 = not cfg.fix_CP1251
        save_settings()
    end
    y_cursor = y_cursor + S(60)

    -- ═══════════════════════════════════════════
    -- 3. СИСТЕМА (System)
    -- ═══════════════════════════════════════════
    s_section(y_cursor, "СИСТЕМА")
    y_cursor = y_cursor + S(35)
    if checkbox(x_start, y_cursor, "Автозапуск разом із REAPER", cfg.auto_startup, "Скрипт буде запускатися автоматично при старті програми.") then
        cfg.auto_startup = not cfg.auto_startup
        toggle_reaper_startup(cfg.auto_startup)
        save_settings()
    end
    y_cursor = y_cursor + S(40)

    -- GUI Scale Control
    local scale_txt = string.format("Масштаб інтерфейсу: %.1fx", cfg.gui_scale)
    s_text(x_start, y_cursor, scale_txt)
    
    if s_btn(x_start + S(220), y_cursor - S(5), S(30), S(30), "－") then
        cfg.gui_scale = math.max(0.1, math.floor((cfg.gui_scale - 0.1) * 10 + 0.5) / 10)
        save_settings()
    end

    if s_btn(x_start + S(260), y_cursor - S(5), S(30), S(30), "＋") then
        cfg.gui_scale = math.min(5.0, math.floor((cfg.gui_scale + 0.1) * 10 + 0.5) / 10)
        save_settings()
    end
    y_cursor = y_cursor + S(60)

    -- ═══════════════════════════════════════════
    -- 4. ЕКРАН СУФЛЕРА (Prompter Elements)
    -- ═══════════════════════════════════════════
    s_section(y_cursor, "ЕКРАН СУФЛЕРА")
    y_cursor = y_cursor + S(35)
    
    if checkbox(x_start, y_cursor, "Відображати менеджер правок", cfg.p_drawer, "Додати бічну панель для керування маркерами проекту.\n(Відображається лише при наявності маркерів)") then
        cfg.p_drawer = not cfg.p_drawer
        save_settings()
    end
    y_cursor = y_cursor + S(35)
    if cfg.p_drawer then
        if checkbox(x_start + S(30), y_cursor, "Показувати ліворуч", cfg.p_drawer_left, "Якщо вимкнено — панель буде малюватися праворуч.") then
            cfg.p_drawer_left = not cfg.p_drawer_left
            save_settings()
        end
        y_cursor = y_cursor + S(35)
    end
    if checkbox(x_start, y_cursor, "Відображати метадані (ID, час)", cfg.p_info, "Показувати індекс репліки та час початку зверху.") then
        cfg.p_info = not cfg.p_info
        save_settings()
    end
    y_cursor = y_cursor + S(35)
    if checkbox(x_start, y_cursor, "Таймер зворотного відліку", cfg.count_timer, "Показувати час до початку наступної репліки.\nТакож відображає стрілку для прокручення до наступної репліки (якщо час більше 10 секунд).") then
        cfg.count_timer = not cfg.count_timer
        save_settings()
    end

    y_cursor = y_cursor + S(35)
    if cfg.count_timer then
        if checkbox(x_start + S(30), y_cursor, "Відображати прогрес знизу", cfg.count_timer_bottom, "Відображати прогрес не по краям, а знизу.") then
            cfg.count_timer_bottom = not cfg.count_timer_bottom
            save_settings()
        end
        y_cursor = y_cursor + S(35)
    end

    if checkbox(x_start, y_cursor, "Попередження про швидкість (CPS)", cfg.cps_warning, "Червона смуга при занадто високій швидкості читання.") then
        cfg.cps_warning = not cfg.cps_warning
        save_settings()
    end
    y_cursor = y_cursor + S(35)
    if checkbox(x_start, y_cursor, "Відображати осцилограму (Waveform)", cfg.wave_bg, "Малювати форму хвилі активного треку на фоні.") then
        cfg.wave_bg = not cfg.wave_bg
        save_settings()
    end
    y_cursor = y_cursor + S(35)
    if cfg.wave_bg then
        if checkbox(x_start + S(30), y_cursor, "Прогрес заповнення осцилограми", cfg.wave_bg_progress, "Зафарбовувати пройдену частину хвилі.") then
            cfg.wave_bg_progress = not cfg.wave_bg_progress
            save_settings()
        end
        y_cursor = y_cursor + S(35)
    end
    if checkbox(x_start, y_cursor, "Режим Караоке", cfg.karaoke_mode, "Підсвічувати активне слово під час відтворення.") then
        cfg.karaoke_mode = not cfg.karaoke_mode
        save_settings()
    end
    y_cursor = y_cursor + S(35)
    if checkbox(x_start, y_cursor, "Режим ВЕЛИКИМИ ЛІТЕРАМИ", cfg.all_caps, "Весь текст відображатиметься ВЕЛИКИМИ ЛІТЕРАМИ.") then
        cfg.all_caps = not cfg.all_caps
        save_settings()
    end
    y_cursor = y_cursor + S(35)
    if checkbox(x_start, y_cursor, "Відображати ім'я актора", cfg.show_actor_name_infront, "Відображення імені актора перед реплікою.") then
        cfg.show_actor_name_infront = not cfg.show_actor_name_infront
        save_settings()
    end
    y_cursor = y_cursor + S(60)

    -- ═══════════════════════════════════════════
    -- 5. ТЕМА ІНТЕРФЕЙСУ (Interface Theme)
    -- ═══════════════════════════════════════════
    s_section(y_cursor, "ТЕМА ІНТЕРФЕЙСУ")
    y_cursor = y_cursor + S(35)

    local ui_theme_options = {"Titanium", "Obsidian", "Quartz"}
    local ui_theme_labels = {"Титан", "Обсидіан", "Кварц"}
    local ui_btn_w = S(135)
    
    for i, opt in ipairs(ui_theme_options) do
        local bx = x_start + ((i-1) * (ui_btn_w + S(10)))
        local sy = get_y(y_cursor)
        local is_sel = (cfg.ui_theme == opt)
        local theme_data = UI.UI_THEMES[opt]
        
        if sy + S(30) > start_y and sy < gfx.h then
            -- Selection highlight
            if is_sel then
                set_color(UI.C_GREEN)
                gfx.rect(bx - S(2), sy - S(2), ui_btn_w + S(4), S(34), 0)
            end
            
            -- Theme preview swatch
            set_color(theme_data.C_BG)
            gfx.rect(bx, sy, ui_btn_w, S(30), 1)
            
            -- Label in theme colors
            set_color(theme_data.C_TXT)
            gfx.setfont(F.std)
            local lw, lh = gfx.measurestr(ui_theme_labels[i])
            gfx.x, gfx.y = bx + (ui_btn_w - lw)/2, sy + (S(30) - lh)/2
            gfx.drawstr(ui_theme_labels[i])
            
            if is_mouse_clicked() and gfx.mouse_x >= bx and gfx.mouse_x <= bx + ui_btn_w and 
               gfx.mouse_y >= sy and gfx.mouse_y <= sy + S(30) then
                UI.apply_ui_theme(opt)
                save_settings()
                -- Force cache rebuild for color updates (CPS, etc)
                table_data_cache.state_count = -1 
                last_layout_state.state_count = -1
            end
        end
    end
    y_cursor = y_cursor + S(60)

    -- ═══════════════════════════════════════════
    -- 6. ТЕМИ ТА ДИЗАЙН СУФЛЕРА (Prompter Themes)
    -- ═══════════════════════════════════════════
    s_section(y_cursor, "ТЕМИ ТА ДИЗАЙН СУФЛЕРА")
    y_cursor = y_cursor + S(35)
    
    local theme_options = {
        {{0.67, 0.69, 0.69}, {0.05, 0.05, 0.05}}, {{0.96, 0.93, 0.86}, {0.18, 0.18, 0.18}},
        {{0.98, 0.98, 0.96}, {0.1, 0.1, 0.1}}, {{0.12, 0.13, 0.14}, {0.82, 0.82, 0.82}},
        {{0.06, 0.09, 0.16}, {0.8, 0.84, 0.88}}, {{0.18, 0.2, 0.25}, {0.85, 0.87, 0.91}},
        {{0.98, 0.92, 0.82}, {0.37, 0.29, 0.2}}, {{0.99, 0.96, 0.89}, {0.39, 0.48, 0.51}},
        {{0, 0.17, 0.21}, {0.51, 0.58, 0.59}}, {{0.94, 0.97, 0.95}, {0.15, 0.12, 0.10}},
    }
    local theme_labels = {"Бетон", "Пергамент", "Порцеляна", "Вугілля", "Безодня", "Сутінки", "Сепія", "Пісок", "Глибина", "М’ята"}
    local theme_btn_w = S(110)
    for i, opt in ipairs(theme_labels) do
        local r, c = math.floor((i-1)/5), (i-1)%5
        local bx = x_start + c * (theme_btn_w + S(10))
        local sy = get_y(y_cursor + r * S(40))
        local is_sel = (cfg.prmt_theme == opt)
        if sy + S(30) > start_y and sy < gfx.h then
            if is_sel then set_color(UI.C_GREEN) gfx.rect(bx - S(2), sy - S(2), theme_btn_w + S(4), S(34), 0) end
            set_color(theme_options[i][1]) gfx.rect(bx, sy, theme_btn_w, S(30), 1)
            set_color(theme_options[i][2])
            gfx.setfont(F.std)
            local lw, lh = gfx.measurestr(opt)
            gfx.x, gfx.y = bx + (theme_btn_w - lw)/2, sy + (S(30) - lh)/2
            gfx.drawstr(opt)
            if is_mouse_clicked() and gfx.mouse_x >= bx and gfx.mouse_x <= bx + theme_btn_w and gfx.mouse_y >= sy and gfx.mouse_y <= sy+S(30) then
                cfg.prmt_theme = opt
                local res = theme_options[i]
                cfg.bg_cr, cfg.bg_cg, cfg.bg_cb = res[1][1], res[1][2], res[1][3]
                cfg.p_cr, cfg.p_cg, cfg.p_cb = res[2][1], res[2][2], res[2][3]
                cfg.n_cr, cfg.n_cg, cfg.n_cb = res[2][1]*0.7, res[2][2]*0.7, res[2][3]*0.7
                save_settings()
            end
        end
    end
    y_cursor = y_cursor + S(90)
    
    set_color(UI.C_TXT)
    s_text(x_start, y_cursor, "Ручне налаштування фону:")
    y_cursor = y_cursor + S(25)
    y_cursor = y_cursor + draw_color_palette(x_start, bg_palette, cfg.bg_cr, cfg.bg_cg, cfg.bg_cb, function(r, g, b)
        cfg.bg_cr, cfg.bg_cg, cfg.bg_cb = r, g, b
        save_settings()
    end)
    y_cursor = y_cursor + S(20)

    -- ═══════════════════════════════════════════
    -- 7. ОСНОВНИЙ ТЕКСТ (Main Text Layout)
    -- ═══════════════════════════════════════════
    s_section(y_cursor, "ОСНОВНИЙ ТЕКСТ")
    y_cursor = y_cursor + S(35)

    set_color(UI.C_TXT)
    
    -- Font Size
    s_text(x_start, y_cursor, "Розмір шрифту: " .. cfg.p_fsize)
    if s_btn(x_start + S(155), y_cursor - S(10), S(30), S(30), "－") then
        cfg.p_fsize = math.max(10, cfg.p_fsize - 2)
        save_settings()
    end
    if s_btn(x_start + S(190), y_cursor - S(10), S(30), S(30), "＋") then
        cfg.p_fsize = math.min(200, cfg.p_fsize + 2)
        save_settings()
    end
    y_cursor = y_cursor + S(45)
    
    -- Line Height
    s_text(x_start, y_cursor, string.format("Висота рядка: %.1f", cfg.p_lheight))
    if s_btn(x_start + S(155), y_cursor - S(10), S(30), S(30), "－") then
        cfg.p_lheight = math.max(0.2, cfg.p_lheight - 0.1)
        save_settings()
    end
    if s_btn(x_start + S(190), y_cursor - S(10), S(30), S(30), "＋") then
        cfg.p_lheight = math.min(5.0, cfg.p_lheight + 0.1)
        save_settings()
    end
    y_cursor = y_cursor + S(45)
    
    -- Alignment
    s_text(x_start, y_cursor, "Вирівнювання по горизонталі:")
    y_cursor = y_cursor + S(25)
    local align_options = {"left", "center", "right"}
    local align_labels = {"Ліворуч", "Центр", "Праворуч"}
    for i, opt in ipairs(align_options) do
        local bx = x_start + ((i-1) * S(100))
        local is_sel = (cfg.p_align == opt)
        local btn_bg = is_sel and UI.C_BTN_MEDIUM or UI.C_BTN
        if s_btn(bx, y_cursor, S(90), S(30), align_labels[i], nil, btn_bg) then
            cfg.p_align = opt
            save_settings()
        end
    end
    y_cursor = y_cursor + S(50)

    s_text(x_start, y_cursor, "Вирівнювання по вертикалі:")
    y_cursor = y_cursor + S(25)
    local valign_options = {"top", "center", "bottom"}
    local valign_labels = {"Вгорі", "Центр", "Внизу"}
    for i, opt in ipairs(valign_options) do
        local bx = x_start + ((i-1) * S(100))
        local is_sel = (cfg.p_valign == opt)
        local btn_bg = is_sel and UI.C_BTN_MEDIUM or UI.C_BTN
        if s_btn(bx, y_cursor, S(90), S(30), valign_labels[i], nil, btn_bg) then
            cfg.p_valign = opt
            save_settings()
        end
    end
    y_cursor = y_cursor + S(50)

    -- Font Selection
    s_text(x_start, y_cursor, "Шрифт:")
    y_cursor = y_cursor + S(25)
    local font_options = {"Arial", "Comic Sans MS", "Verdana", "Tahoma", "Helvetica"}
    local font_btn_w = S(110)
    for i, f_name in ipairs(font_options) do
        local r, c = math.floor((i-1)/5), (i-1)%5
        local bx = x_start + c * (font_btn_w + S(10))
        local is_sel = (cfg.p_font == f_name)
        local btn_bg = is_sel and UI.C_BTN_MEDIUM or UI.C_BTN
        if s_btn(bx, y_cursor + r * S(35), font_btn_w, S(30), f_name, nil, btn_bg) then
            cfg.p_font = f_name
            save_settings()
        end
    end
    -- Custom Font
    local is_preset = false
    for _, f in ipairs(font_options) do if f == cfg.p_font then is_preset = true break end end
    local font_btn_custom_w = (font_btn_w * 5) + S(40)
    local d_name = not is_preset and cfg.p_font or "Свій..."
    local btn_bg = (not is_preset) and UI.C_BTN_MEDIUM or UI.C_BTN
    if s_btn(x_start, y_cursor + S(40), font_btn_custom_w, S(30), d_name, nil, btn_bg) then
        local ok, nf = reaper.GetUserInputs("Вибір шрифту", 1, "Назва шрифту:,extrawidth=200", cfg.p_font)
        if ok and nf ~= "" then cfg.p_font = nf save_settings() end
    end
    y_cursor = y_cursor + S(85)

    -- Text Color
    s_text(x_start, y_cursor, "Колір тексту:")
    y_cursor = y_cursor + S(25)
    y_cursor = y_cursor + draw_color_palette(x_start, text_palette, cfg.p_cr, cfg.p_cg, cfg.p_cb, function(r, g, b)
        cfg.p_cr, cfg.p_cg, cfg.p_cb = r, g, b
        save_settings()
    end)
    y_cursor = y_cursor + S(20)

    -- ═══════════════════════════════════════════
    -- 8. НАСТУПНА РЕПЛІКА (Next Line)
    -- ═══════════════════════════════════════════
    s_section(y_cursor, "НАСТУПНА РЕПЛІКА")
    y_cursor = y_cursor + S(35)
    if checkbox(x_start, y_cursor, "Відображати наступну репліку", cfg.p_next, "Показувати текст наступної репліки під поточною.") then
        cfg.p_next = not cfg.p_next
        save_settings()
    end
    y_cursor = y_cursor + S(45)
    if cfg.p_next then
        s_text(x_start + S(30), y_cursor, "Розмір шрифту: " .. cfg.n_fsize)
        if s_btn(x_start + S(175), y_cursor - S(10), S(30), S(30), "－") then
            cfg.n_fsize = math.max(10, cfg.n_fsize - 2)
            save_settings()
        end
        if s_btn(x_start + S(210), y_cursor - S(10), S(30), S(30), "＋") then
            cfg.n_fsize = math.min(100, cfg.n_fsize + 2)
            save_settings()
        end
        y_cursor = y_cursor + S(45)
        
        -- Next Line Height
        s_text(x_start + S(30), y_cursor, string.format("Висота рядка: %.1f", cfg.n_lheight))
        if s_btn(x_start + S(175), y_cursor - S(10), S(30), S(30), "－") then
            cfg.n_lheight = math.max(0.2, cfg.n_lheight - 0.1)
            save_settings()
        end
        if s_btn(x_start + S(210), y_cursor - S(10), S(30), S(30), "＋") then
            cfg.n_lheight = math.min(5.0, cfg.n_lheight + 0.1)
            save_settings()
        end
        y_cursor = y_cursor + S(45)
        
        if checkbox(x_start + S(30), y_cursor, "Завжди показувати (між регіонами)", cfg.always_next, "Наступна репліка не ховатиметься, коли немає активної.") then
            cfg.always_next = not cfg.always_next
            save_settings()
        end
        y_cursor = y_cursor + S(40)

        if checkbox(x_start + S(30), y_cursor, "Відображати ДВІ наступні репліки", cfg.show_next_two, "Відображення відразу 2 наступних реплік в суфлері.") then
            cfg.show_next_two = not cfg.show_next_two
            save_settings()
        end

        y_cursor = y_cursor + S(40)

        if checkbox(x_start + S(30), y_cursor, "Прикріпити до основної репліки", cfg.next_attach, "Наступна репліка не прикріплюватиметься до низу екрану, а буде під основною.") then
            cfg.next_attach = not cfg.next_attach
            save_settings()
        end

        y_cursor = y_cursor + S(45)

        if cfg.next_attach then
            s_text(x_start + S(60), y_cursor, "Відступ до репліки: " .. cfg.next_padding)
            if s_btn(x_start + S(225), y_cursor - S(10), S(30), S(30), "－") then
                cfg.next_padding = math.max(0, cfg.next_padding - 5)
                save_settings()
            end
            if s_btn(x_start + S(260), y_cursor - S(10), S(30), S(30), "＋") then
                cfg.next_padding = math.min(500, cfg.next_padding + 5)
                save_settings()
            end
            y_cursor = y_cursor + S(45)
        end

        y_cursor = y_cursor + draw_color_palette(x_start + S(30), text_palette, cfg.n_cr, cfg.n_cg, cfg.n_cb, function(r, g, b)
            cfg.n_cr, cfg.n_cg, cfg.n_cb = r, g, b
            save_settings()
        end, 0.7)
    end
    y_cursor = y_cursor + S(40)

    -- ═══════════════════════════════════════════
    -- 9. ПРАВКИ (Corrections)
    -- ═══════════════════════════════════════════
    s_section(y_cursor, "ПРАВКИ")
    y_cursor = y_cursor + S(35)
    if checkbox(x_start, y_cursor, "Відображати правки", cfg.p_corr, "Показувати текст маркерів-правок між репліками.") then
        cfg.p_corr = not cfg.p_corr
        save_settings()
    end
    y_cursor = y_cursor + S(45)
    if cfg.p_corr then
        s_text(x_start + S(30), y_cursor, "Розмір шрифту: " .. cfg.c_fsize)
        if s_btn(x_start + S(175), y_cursor - S(10), S(30), S(30), "－") then
            cfg.c_fsize = math.max(10, cfg.c_fsize - 2)
            update_prompter_fonts()
            save_settings()
        end
        if s_btn(x_start + S(210), y_cursor - S(10), S(30), S(30), "＋") then
            cfg.c_fsize = math.min(100, cfg.c_fsize + 2)
            update_prompter_fonts()
            save_settings()
        end
        y_cursor = y_cursor + S(45)
        
        s_text(x_start + S(30), y_cursor, string.format("Висота рядка: %.1f", cfg.c_lheight))
        if s_btn(x_start + S(175), y_cursor - S(10), S(30), S(30), "－") then
            cfg.c_lheight = math.max(0.2, cfg.c_lheight - 0.1)
            save_settings()
        end
        if s_btn(x_start + S(210), y_cursor - S(10), S(30), S(30), "＋") then
            cfg.c_lheight = math.min(5.0, cfg.c_lheight + 0.1)
            save_settings()
        end
        y_cursor = y_cursor + S(45)
        y_cursor = y_cursor + draw_color_palette(x_start + S(30), text_palette, cfg.c_cr, cfg.c_cg, cfg.c_cb, function(r, g, b)
            cfg.c_cr, cfg.c_cg, cfg.c_cb = r, g, b
            save_settings()
        end, 0.7)
    end
    y_cursor = y_cursor + S(40)

    -- ═══════════════════════════════════════════
    -- 10. ТАБЛИЦЯ
    -- ═══════════════════════════════════════════
    s_section(y_cursor, "ТАБЛИЦЯ")
    y_cursor = y_cursor + S(35)

    s_text(x_start, y_cursor, "Колір активної репліки:")
    y_cursor = y_cursor + S(25)
    y_cursor = y_cursor + draw_color_palette(x_start, {{0.2, 0.9, 0.2}, {1.0, 1.0, 0.0}}, cfg.t_ar_r, cfg.t_ar_g, cfg.t_ar_b, function(r, g, b)
        cfg.t_ar_r, cfg.t_ar_g, cfg.t_ar_b = r, g, b
        save_settings()
    end)
    y_cursor = y_cursor + S(20)

    s_text(x_start, y_cursor, string.format("Прозорість ар.: %.2f", cfg.t_ar_alpha))
    if s_btn(x_start + S(155), y_cursor - S(10), S(30), S(30), "－") then
        cfg.t_ar_alpha = math.max(0.05, cfg.t_ar_alpha - 0.05)
        save_settings()
    end
    if s_btn(x_start + S(190), y_cursor - S(10), S(30), S(30), "＋") then
        cfg.t_ar_alpha = math.min(0.8, cfg.t_ar_alpha + 0.05)
        save_settings()
    end

    y_cursor = y_cursor + S(45)

    -- Alignment
    s_text(x_start, y_cursor, "Розмір шрифту рядків:")
    y_cursor = y_cursor + S(25)
    local align_options = {"tr_S", "tr_M", "tr_L", "tr_XL"}
    local align_labels = {"S", "M", "L", "XL"}
    for i, opt in ipairs(align_options) do
        local bx = x_start + ((i-1) * S(70))
        local is_sel = (cfg.t_r_size == opt)
        local btn_bg = is_sel and UI.C_BTN_MEDIUM or UI.C_BTN
        if s_btn(bx, y_cursor, S(60), S(30), align_labels[i], nil, btn_bg) then
            cfg.t_r_size = opt
            save_settings()
        end
    end

    y_cursor = y_cursor + S(60)

    -- ═══════════════════════════════════════════
    -- 11. ЗАПИС ТА АВТО-ПІДРІЗАННЯ (Recording)
    -- ═══════════════════════════════════════════
    s_section(y_cursor, "ЗАПИС ТА АВТО-ПІДРІЗАННЯ")
    y_cursor = y_cursor + S(35)
    
    if checkbox(x_start, y_cursor, "Авто-підрізання щойно записаних реплік", cfg.auto_trim, "Автоматично підрізає початок та кінець щойно записаної репліки (аби прибрати кліки клавіатури)") then
        cfg.auto_trim = not cfg.auto_trim
        save_settings()
    end
    y_cursor = y_cursor + S(45)
    
    if cfg.auto_trim then
        s_text(x_start + S(25), y_cursor, "Підрізати початок (мс): " .. cfg.trim_start, F.std)
        if s_btn(x_start + S(250), y_cursor - S(10), S(30), S(30), "－") then
            cfg.trim_start = math.max(0, cfg.trim_start - 10)
            save_settings()
        end
        if s_btn(x_start + S(285), y_cursor - S(10), S(30), S(30), "＋") then
            cfg.trim_start = math.min(2000, cfg.trim_start + 10)
            save_settings()
        end
        y_cursor = y_cursor + S(45)
        
        s_text(x_start + S(25), y_cursor, "Підрізати кінець (мс): " .. cfg.trim_end, F.std)
        if s_btn(x_start + S(250), y_cursor - S(10), S(30), S(30), "－") then
            cfg.trim_end = math.max(0, cfg.trim_end - 10)
            save_settings()
        end
        if s_btn(x_start + S(285), y_cursor - S(10), S(30), S(30), "＋") then
            cfg.trim_end = math.min(2000, cfg.trim_end + 10)
            save_settings()
        end
        y_cursor = y_cursor + S(40)
    end

    if checkbox(x_start, y_cursor, "Перевіряти на перегруз (Clipping)", cfg.check_clipping, "Показувати попередження, якщо запис має піки 0dB або вище.") then
        cfg.check_clipping = not cfg.check_clipping
        save_settings()
    end
    y_cursor = y_cursor + S(65)
    
    -- ═══════════════════════════════════════════
    -- 12. ТЕКСТ У МОВУ (Text-to-Speech)
    -- ═══════════════════════════════════════════
    s_section(y_cursor, "ТЕКСТ У МОВУ")
    y_cursor = y_cursor + S(35)
    
    s_text(x_start, y_cursor, "Двигун та голос для озвучення:", F.std, "Провайдер і голос для озвучення")
    y_cursor = y_cursor + S(25)

    local tts_btn_w = S(240)
    local cur_voice = cfg.tts_voice or "Горох: Оксана (Wavenet)"
    
    if s_btn(x_start, y_cursor, tts_btn_w, S(30), cur_voice .. "  ▿") then        
        local menu_parts = {}
        for i, opt in ipairs(cfg.tts_voices_order) do
            local mark = (opt == cur_voice) and "!" or ""
            table.insert(menu_parts, mark .. opt)
        end
        gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
        local ret = gfx.showmenu(table.concat(menu_parts, "|"))
        if ret > 0 then
            cfg.tts_voice = cfg.tts_voices_order[ret]
            save_settings()
            
            -- Auto-preview on choice
            play_tts_audio("Широка доро́га, дорога́ як пам'ять")
        end
    end
    y_cursor = y_cursor + S(80)

    -- Footer
    set_color(UI.C_TXT)
    local footer_txt = "Знайшли баг або маєте ідею — пишіть: @fusion_ford"
    s_text(x_start, y_cursor, footer_txt, F.std)

    -- Click to Copy handle (using existing helpers)
    local f_sy = get_y(y_cursor)
    if f_sy + S(20) > start_y and f_sy < gfx.h then
        local tw, th = gfx.measurestr(footer_txt)
        if is_mouse_clicked() and gfx.mouse_x >= x_start and gfx.mouse_x <= x_start + tw and
           gfx.mouse_y >= f_sy and gfx.mouse_y <= f_sy + th then
            set_clipboard("@fusion_ford")
            show_snackbar("Скопійовано: @fusion_ford", "info")
        end
    end
    y_cursor = y_cursor + S(40)
    
    last_settings_h = y_cursor
    UI_STATE.target_scroll_y = draw_scrollbar(gfx.w - S(10), start_y, S(10), avail_h, last_settings_h, avail_h, UI_STATE.target_scroll_y)
end

-- Helper to calculate sort value for a table row
local function get_sort_value(item, col, is_ass)
    if col == "#" or col == "index" then return item.index or 0 end
    
    -- Robust fallback mapping
    local t1 = item.t1 or item.pos or 0
    local t2 = item.t2 or item.rgnend or 0
    local txt = item.text or item.name or ""
    local actor = item.actor or ""
    
    if col == "Ак." or col == "enabled" then return (item.enabled ~= false and 1 or 0) end
    if col == "Початок" or col == "start" then return t1 end
    if col == "Кінець" or col == "end" then return t2 end
    if col == "CPS" or col == "cps" then
        local dur = t2 - t1
        local clean = txt:gsub(acute, ""):gsub("%s+", "")
        local chars = utf8.len(clean) or #clean
        return dur > 0 and (chars / dur) or 0
    end
    if col == "Актор" or col == "actor" then return utf8_lower(actor) end
    if col == "Репліка" or col == "text" then return utf8_lower(txt) end
    
    return 0
end

-- Helper for manual text wrapping with character fallback
local function wrap_text_manual(text, max_w)
    local lines = {}
    local words = {}
    local display_txt = text:gsub("[\n\r]", " ")
    for word in display_txt:gmatch("%S+") do table.insert(words, word) end
    if #words == 0 and #display_txt > 0 then words = {display_txt} end
    
    local current_line = ""
    for _, word in ipairs(words) do
        local test = current_line == "" and word or current_line .. " " .. word
        if gfx.measurestr(test) <= max_w then
            current_line = test
        else
            if current_line ~= "" then table.insert(lines, current_line) end
            
            -- If single word is still too long, character wrap it
            if gfx.measurestr(word) > max_w then
                local partial = ""
                local word_len = utf8.len(word) or #word
                for j = 1, word_len do
                    local char_start = utf8.offset(word, j)
                    local char_end = (utf8.offset(word, j+1) or #word+1) - 1
                    local char = word:sub(char_start, char_end)
                    
                    if gfx.measurestr(partial .. char) > max_w then
                        if partial ~= "" then table.insert(lines, partial) end
                        partial = char
                    else
                        partial = partial .. char
                    end
                end
                current_line = partial
            else
                current_line = word
            end
        end
    end
    if current_line ~= "" then table.insert(lines, current_line) end
    return lines
end

-- =============================================================================
-- UI: TABLE TAB (SUBTITLE EDITOR)
-- =============================================================================

local last_auto_scroll_idx = nil
local suppress_auto_scroll_frames = 0

-- Helper for inline buttons
local function draw_btn_inline(x, y, w, h, text, bg_col)
    local hover = UI_STATE.window_focused and (gfx.mouse_x >= x and gfx.mouse_x <= x + w and gfx.mouse_y >= y and gfx.mouse_y <= y + h)
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

-- Helper: Get current actor from text
-- Helper: Parse actors from text (supports comma-separated "Actor1, Actor2")
local function get_actors_from_text(text)
    local content = text:match("^%[(.-)%]")
    if not content then return {}, {} end
    
    local list = {}
    local set = {}
    for part in string.gmatch(content, "([^,]+)") do
        local name = part:match("^%s*(.-)%s*$")
        if name and name ~= "" then
            table.insert(list, name)
            set[name] = true
        end
    end
    return list, set
end

-- Helper: Rename actor globally in all project markers
local function rename_actor_globally(old_name, new_name)
    local count = 0
    
    -- 1. Update Project Markers/Regions
    local i = 0
    while true do
        local retval, isrgn, pos, rgnend, mark_name, markindex = reaper.EnumProjectMarkers3(0, i)
        if not retval or retval == 0 then break end
        
        local actors, actor_set = get_actors_from_text(mark_name)
        if actor_set[old_name] then
            -- Replace in the list
            local new_actors = {}
            for _, a in ipairs(actors) do
                table.insert(new_actors, (a == old_name) and new_name or a)
            end
            
            -- Rebuild text
            local clean_text = mark_name:gsub("^%[.-%]%s*", "")
            local new_text = "[" .. table.concat(new_actors, ", ") .. "] " .. clean_text
            
            reaper.SetProjectMarker4(0, markindex, isrgn, pos, rgnend, new_text, 0, 0)
            count = count + 1
        end
        i = i + 1
    end
    
    -- 2. Invalidate caches
    ass_markers = capture_project_markers()
    prompter_drawer.marker_cache.count = -1
    table_data_cache.state_count = -1
    last_layout_state.state_count = -1
    
    return count
end

-- Helper: Delete actor prefix globally in all project markers
local function delete_actor_globally(name)
    local count = 0
    
    -- 1. Update Project Markers/Regions
    local i = 0
    while true do
        local retval, isrgn, pos, rgnend, mark_name, markindex = reaper.EnumProjectMarkers3(0, i)
        if not retval or retval == 0 then break end
        
        local actors, actor_set = get_actors_from_text(mark_name)
        if actor_set[name] then
            -- Remove from the list
            local new_actors = {}
            for _, a in ipairs(actors) do
                if a ~= name then table.insert(new_actors, a) end
            end
            
            -- Rebuild text
            local clean_text = mark_name:gsub("^%[.-%]%s*", "")
            local new_text = clean_text
            if #new_actors > 0 then
                new_text = "[" .. table.concat(new_actors, ", ") .. "] " .. clean_text
            end
            
            reaper.SetProjectMarker4(0, markindex, isrgn, pos, rgnend, new_text, 0, 0)
            count = count + 1
        end
        i = i + 1
    end
    
    -- 2. Invalidate caches
    ass_markers = capture_project_markers()
    prompter_drawer.marker_cache.count = -1
    table_data_cache.state_count = -1
    last_layout_state.state_count = -1
    
    return count
end

local function draw_director_panel(panel_x, panel_y, panel_w, panel_h, input_queue, calc_only)
    if not calc_only then
        set_color(UI.C_BG)
        gfx.rect(panel_x, panel_y, panel_w, panel_h, 1)
        gfx.setfont(F.std)
    end
    
    local is_dir_right = (cfg.director_layout == "right")

    local padding = S(10)
    local btn_h = S(24)
    -- --- AUTO-DETECT CURRENT MARKER ---
    local play_pos = reaper.GetPlayPosition()
    local edit_pos = reaper.GetCursorPosition()
    local cur_time = reaper.GetPlayState() > 0 and play_pos or edit_pos
    
    -- Only update if time jump or first run
    -- But first: Validate that the currently held marker ID still exists (it might have been deleted externally)
    if director_state.last_marker_id then
        local found_sync = nil
        for _, m in ipairs(ass_markers) do
            if m.markindex == director_state.last_marker_id then
                found_sync = m
                break
            end
        end
        if not found_sync then
            director_state.last_marker_id = nil
            director_state.input.text = ""
            director_state.input.cursor = 0
        else
            -- Sync with external changes (e.g. from modal text editor)
            if found_sync.name ~= (director_state.original_text or "") then
                -- Only update input if it hasn't been significantly modified by the user here, 
                -- or if it was exactly matching the previous state.
                if director_state.input.text == director_state.original_text then
                    director_state.input.text = found_sync.name
                    director_state.input.cursor = #found_sync.name
                    director_state.input.anchor = director_state.input.cursor
                end
                director_state.original_text = found_sync.name
            end
        end
    end

    if not is_near(cur_time, director_state.last_time) then
        director_state.last_time = cur_time
        
        local found_m = nil
        for _, m in ipairs(ass_markers) do
            if is_near(m.pos, cur_time) then
                found_m = m
                break
            end
        end
        
        if found_m then
            if found_m.markindex ~= director_state.last_marker_id then
                director_state.last_marker_id = found_m.markindex
                director_state.input.text = found_m.name
                director_state.original_text = found_m.name
                director_state.input.cursor = #found_m.name
                director_state.input.anchor = director_state.input.cursor -- Reset selection
            end
        else
            if director_state.last_marker_id ~= nil then
                director_state.last_marker_id = nil
                director_state.input.text = ""
                director_state.original_text = ""
                director_state.input.cursor = 0
                director_state.input.anchor = 0 -- Reset selection
            end
        end
    end

    local btn_h = S(24) -- Standard button height
    
    -- --- ROW 1: ACTORS ---
    local x = padding
    -- Use smaller top padding for Right layout to save space
    local y = (cfg.director_layout == "right") and S(2) or padding
    
    if not calc_only then
        -- Draw Background
        set_color(UI.C_BG)
        gfx.rect(panel_x, panel_y, panel_w, panel_h, 1)
        
        -- Draw Separator (Left or Top depending on layout? For now basic border)
        set_color(UI.C_MEDIUM_GREY)
        if cfg.director_layout == "right" then
            gfx.line(panel_x, panel_y, panel_x, panel_y + panel_h)
        else
            gfx.line(panel_x, panel_y, panel_x + panel_w, panel_y)
        end
    end
    
    -- Adjust coordinates for drawing
    local draw_x = panel_x + x
    local draw_y = panel_y + y
    
    local _, current_actors_set = get_actors_from_text(director_state.input.text)
    
    local save_btn_w = S(100)
    -- Detect narrow mode (Right layout) for proper input width calculation
    local is_right_layout = (cfg.director_layout == "right")
    local input_w = is_right_layout and (panel_w - padding*2) or (panel_w - padding*2 - save_btn_w - S(10))
    
    -- Options Menu Button (Top-Right)
    local opt_btn_w = S(30)
    local opt_x = panel_x + panel_w - padding - opt_btn_w
    
    -- Actor buttons should wrap before reaching the options button
    local limit_x = opt_x - S(5) -- Leave small gap before options button
    
    if not calc_only and draw_btn_inline(opt_x, draw_y, opt_btn_w, btn_h, "≡", UI.C_ACCENT_N) then
        local dock_check = gfx.dock(-1) > 0 and "!" or ""
        local layout_label = (cfg.director_layout == "right") and "Прикріпити вікно знизу" or "Прикріпити вікно праворуч"
        local menu_str = "Копіювати правки в буфер||Експортувати правки в CSV|Імпортувати імена акторів з субтитрів||" .. layout_label .. "|Закрити вікно"
        
        gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
        local ret = gfx.showmenu(menu_str)
        
        if ret == 1 then
            -- Copy
            if #ass_markers > 0 then
                local groups = {}
                local no_actor_key = "-- без актора --"
                local actors_list = {} -- Keep track of actors found for sorting
                local seen_actors = {}

                for _, m in ipairs(ass_markers) do
                    local text = m.name
                    local list, _ = get_actors_from_text(text)
                    local content = ""
                    
                    if #list > 0 then
                        content = text:gsub("^%[.-%]%s*", "")
                    else
                        -- Fallback: Try pattern "Actor: Text"
                        local s, e, act = string.find(text, "^(.-):%s*")
                        if s then
                            table.insert(list, act)
                            content = string.sub(text, e + 1)
                        else
                            content = text
                            table.insert(list, no_actor_key)
                        end
                    end

                    for _, actor in ipairs(list) do
                        if not groups[actor] then
                            groups[actor] = {}
                            if not seen_actors[actor] then
                                table.insert(actors_list, actor)
                                seen_actors[actor] = true
                            end
                        end
                        table.insert(groups[actor], {time = m.pos, text = content})
                    end
                end

                -- Sort actors alphabetically, but put no_actor_key last
                table.sort(actors_list, function(a, b)
                    if a == no_actor_key then return false end
                    if b == no_actor_key then return true end
                    return a < b
                end)

                local out_lines = {}
                for _, act in ipairs(actors_list) do
                    -- Clean actor name: remove VS16 and trim spaces
                    local clean_act = act:gsub("\239\184\143", ""):match("^%s*(.-)%s*$")
                    table.insert(out_lines, "⭐ " .. clean_act)
                    -- Sort markers by time
                    table.sort(groups[act], function(a, b) return a.time < b.time end)
                    
                    for _, entry in ipairs(groups[act]) do
                        local time_str = reaper.format_timestr(entry.time, "")
                        table.insert(out_lines, time_str .. " - " .. entry.text)
                    end
                    table.insert(out_lines, "") -- Empty line between groups
                end
                
                set_clipboard(table.concat(out_lines, "\n"))
                show_snackbar("Скопійовано " .. #ass_markers .. " правок", "success")
            else
                show_snackbar("Немає правок для копіювання", "info")
            end
        elseif ret == 2 then
            if not reaper.JS_Dialog_BrowseForSaveFile then
                local msg = "Для роботи експорту необхідне розширення JS_ReaScriptAPI.\n\n"
                if not has_reapack then
                    msg = msg .. "1. Встановіть ReaPack (reapack.com)\n2. Перезавантажте REAPER\n3. Встановіть JS_ReaScriptAPI через ReaPack"
                else
                    msg = msg .. "Будь ласка, встановіть 'JS_ReaScriptAPI' через Extensions -> ReaPack -> Browse packages. (потім перезавантажте REAPER)"
                end
                reaper.MB(msg, "Відсутні компоненти", 0)
                return -- STRICT STOP
            end

            if #ass_markers == 0 then
                show_snackbar("Немає правок для експорту", "info")
                return
            end

            -- Отримуємо ім'я проекту для дефолтної назви файлу
            local _, proj_path = reaper.EnumProjects(-1)
            local proj_name = "Project"
            if proj_path and proj_path ~= "" then
                -- Витягуємо ім'я файлу без шляху та розширення (кейс-незалежно)
                proj_name = proj_path:match("([^/\\%s]+)%.[Rr][Pp][Pp]$") or proj_name
            end
            local default_filename = proj_name .. "_правки.csv"

            -- Відкриваємо діалог збереження файлу
            local retval, filename = reaper.JS_Dialog_BrowseForSaveFile("Зберегти маркери як CSV", "", default_filename, "CSV files (.csv)\0*.csv\0All Files (*.*)\0*.*\0")
            
            if retval == 1 and filename ~= "" then
                -- Додаємо розширення .csv якщо його немає
                if not filename:match("%.csv$") then
                    filename = filename .. ".csv"
                end
                
                -- Відкриваємо файл для запису
                local file = io.open(filename, "w")
                if not file then
                    reaper.ShowMessageBox("Не вдалося створити файл: " .. filename, "Помилка", 0)
                    return
                end
                
                -- Записуємо заголовок CSV
                file:write("#,Name,Start,Color\n")
                
                -- Перебираємо всі маркери (вже захоплені в ass_markers)
                for _, m in ipairs(ass_markers) do
                    -- Формуємо ID маркера (M + номер)
                    local marker_id = "M" .. m.markindex
                    
                    -- Конвертуємо позицію у стандартний формат (H:M:S.ms)
                    local time_str = reaper.format_timestr(m.pos, "")
                    
                    -- Екрануємо назву якщо містить коми, лапки або переходи на новий рядок
                    local escaped_name = m.name
                    if m.name:match('[,"\n\r]') then
                        escaped_name = '"' .. m.name:gsub('"', '""') .. '"'
                    end
                    
                    -- Конвертуємо колір з BGR у RGB hex формат без #
                    local color_str = ""
                    if m.color and m.color > 0 then
                        local r = (m.color & 0xFF)
                        local g = (m.color >> 8) & 0xFF
                        local b = (m.color >> 16) & 0xFF
                        color_str = string.format("%02X%02X%02X", r, g, b)
                    end
                    
                    -- Записуємо рядок у CSV
                    file:write(string.format("%s,%s,%s,%s\n", 
                        marker_id,
                        escaped_name,
                        time_str,
                        color_str))
                end
                
                file:close()
                show_snackbar("Експортовано " .. #ass_markers .. " правок у CSV", "success")
            end
        elseif ret == 3 then
            -- Import
            local existing = {}
            for _, a in ipairs(director_actors) do existing[a] = true end
            
            -- Pass 1: Count new actors
            local new_actors = {}
            local count = 0
            for _, line in ipairs(ass_lines) do
                if line.actor and line.actor ~= "" and not existing[line.actor] and not new_actors[line.actor] then
                    new_actors[line.actor] = true
                    count = count + 1
                end
            end
            
            if count > 0 then
                -- Push undo BEFORE modification
                push_undo("Імпортувати імена акторів з субтитрів (" .. count .. ")")
                
                -- Pass 2: Actually add them
                for _, line in ipairs(ass_lines) do
                    if line.actor and line.actor ~= "" and not existing[line.actor] then
                        table.insert(director_actors, line.actor)
                        existing[line.actor] = true -- Prevent duplicates from same multi-replica import
                    end
                end
                
                save_project_data(UI_STATE.last_project_id)
                show_snackbar("Імпортовано " .. count .. " акторів", "success")
            else
                show_snackbar("Нових акторів не знайдено", "info")
            end
        elseif ret == 4 then
            -- Toggle Layout
            if cfg.director_layout == "right" then
                cfg.director_layout = "bottom"
            else
                cfg.director_layout = "right"
            end
            save_settings() -- Save state immediately
            last_layout_state.state_count = -1 -- Force redraw
        elseif ret == 5 then
            cfg.director_mode = not cfg.director_mode
            save_settings()
        end
    end

    for i, actor in ipairs(director_actors) do
        local label = actor
        local w, _ = gfx.measurestr(label)
        local btn_w = w + S(20)
        
        -- Wrap Check relative to panel start
        if draw_x + btn_w > limit_x then
            x = padding
            y = y + btn_h + S(5)
            draw_x = panel_x + x
            draw_y = panel_y + y
        end
        
        if not calc_only then
             -- Logic drawing ...
             -- Active state determination
            local is_active = current_actors_set[actor]
            local bg_col = is_active and UI.C_ACCENT_G or UI.C_BTN
            
            -- Hover Check for Right Click
            -- Adjust hit test to relative coords
            local hover = UI_STATE.window_focused and (gfx.mouse_x >= draw_x and gfx.mouse_x <= draw_x + btn_w and gfx.mouse_y >= draw_y and gfx.mouse_y <= draw_y + btn_h)
            
            if draw_btn_inline(draw_x, draw_y, btn_w, btn_h, label, bg_col) then
                -- Toggle Logic
                local txt = director_state.input.text
                local list, _ = get_actors_from_text(txt)
                local clean = txt:gsub("^%[.-%]%s*", "")
                
                if is_active then
                    -- Toggle Off (Remove from list)
                    local new_list = {}
                    for _, a in ipairs(list) do
                        if a ~= actor then table.insert(new_list, a) end
                    end
                    if #new_list > 0 then
                        director_state.input.text = "[" .. table.concat(new_list, ", ") .. "] " .. clean
                    else
                        director_state.input.text = clean
                    end
                else
                    -- Toggle On (Add to list)
                    table.insert(list, actor)
                    director_state.input.text = "[" .. table.concat(list, ", ") .. "] " .. clean
                end
                director_state.input.cursor = #director_state.input.text
                director_state.input.anchor = director_state.input.cursor
                director_state.input.focus = true
            end
            
            -- Right Click
            if hover and is_right_mouse_clicked() then
                -- ... (Context Menu Logic) ...
                UI_STATE.mouse_handled = true

                gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
                local menu_str2 = "Змінити ім'я||Видалити ім'я"
                local ret2 = gfx.showmenu(menu_str2)
                if ret2 == 1 then
                    -- RENAME
                    local ok, new_name = reaper.GetUserInputs("Змінити ім'я актора", 1, "Нове ім'я:", actor)
                    if ok then
                        -- Remove variation selector (U+FE0F = \239\184\143) and trim spaces
                        new_name = new_name:gsub("\239\184\143", ""):match("^%s*(.-)%s*$")
                        
                        if new_name ~= "" and new_name ~= actor then
                            -- Merge check
                            local target_exists = false
                            for _, act in ipairs(director_actors) do
                                if act == new_name then target_exists = true break end
                            end
                            
                            if target_exists then
                                push_undo("Об'єднати актора '" .. actor .. "' з '" .. new_name.. "' (Режисер)")
                                table.remove(director_actors, i)
                                save_project_data(UI_STATE.last_project_id)
                                local ops = rename_actor_globally(actor, new_name)

                                -- Force prompter drawer caches to refresh
                                prompter_drawer.marker_cache.count = -1
                                prompter_drawer.filtered_cache.state_count = -1
                                prompter_drawer.has_markers_cache.count = -1
                                
                                -- Update Input if needed
                                local list, set = get_actors_from_text(director_state.input.text)
                                if set[actor] then
                                    local new_list = {}
                                    for _, a in ipairs(list) do
                                        table.insert(new_list, (a == actor) and new_name or a)
                                    end
                                    local clean = director_state.input.text:gsub("^%[.-%]%s*", "")
                                    director_state.input.text = "[" .. table.concat(new_list, ", ") .. "] " .. clean
                                    director_state.input.cursor = #director_state.input.text
                                    director_state.input.anchor = director_state.input.cursor
                                end

                                show_snackbar("Об'єднано з '" .. new_name .. "' (" .. ops .. " змін) (Режисер)", "success")
                            else
                                push_undo("Змінити ім'я актора " .. actor .. " -> " .. new_name)
                                director_actors[i] = new_name
                                save_project_data(UI_STATE.last_project_id)
                                local ops = rename_actor_globally(actor, new_name)

                                -- Force prompter drawer caches to refresh
                                prompter_drawer.marker_cache.count = -1
                                prompter_drawer.filtered_cache.state_count = -1
                                prompter_drawer.has_markers_cache.count = -1
                                
                                -- Update Input if needed
                                local list, set = get_actors_from_text(director_state.input.text)
                                if set[actor] then
                                    local new_list = {}
                                    for _, a in ipairs(list) do
                                        table.insert(new_list, (a == actor) and new_name or a)
                                    end
                                    local clean = director_state.input.text:gsub("^%[.-%]%s*", "")
                                    director_state.input.text = "[" .. table.concat(new_list, ", ") .. "] " .. clean
                                    director_state.input.cursor = #director_state.input.text
                                    director_state.input.anchor = director_state.input.cursor
                                end

                                show_snackbar("Змінено ім'я у '" .. ops .. "' місцях (Режисер)", "success")
                            end
                        end
                    end
                elseif ret2 == 2 then
                    -- DELETE
                    local ok = reaper.MB("Ви дійсно хочете видалити ім'я актора '" .. actor .. "'? Це видалить його префікс з усіх правок, але не самі правки.", "Підтвердження", 4)
                    if ok == 6 then
                        push_undo("Видалити актора '" .. actor .. "' (Режисер)")
                        table.remove(director_actors, i)
                        save_project_data(UI_STATE.last_project_id)
                        local ops = delete_actor_globally(actor)

                        -- Force prompter drawer caches to refresh
                        prompter_drawer.marker_cache.count = -1
                        prompter_drawer.filtered_cache.state_count = -1
                        prompter_drawer.has_markers_cache.count = -1
                        
                        -- Update Input if needed
                        local list, set = get_actors_from_text(director_state.input.text)
                        if set[actor] then
                            local new_list = {}
                            for _, a in ipairs(list) do
                                if a ~= actor then table.insert(new_list, a) end
                            end
                            local clean = director_state.input.text:gsub("^%[.-%]%s*", "")
                            if #new_list > 0 then
                                director_state.input.text = "[" .. table.concat(new_list, ", ") .. "] " .. clean
                            else
                                director_state.input.text = clean
                            end
                            director_state.input.cursor = #director_state.input.text
                            director_state.input.anchor = director_state.input.cursor
                        end
                        
                        show_snackbar("Видалено актора та '" .. ops .. "' префіксів (Режисер)", "info")
                    end
                end
            end
        end
        x = x + btn_w + S(5)
        draw_x = panel_x + x -- Update draw X
    end
    
    -- Check for recent notes visibility
    director_state.has_recent_notes = false
    for _, m in ipairs(ass_markers) do
        if m.name and m.name:gsub("%s", "") ~= "" then
            director_state.has_recent_notes = true
            break
        end
    end

    if not calc_only then
        -- Draw # Button (Recent Notes)
        if director_state.has_recent_notes then
            if draw_x + S(24) > limit_x then
                x = padding
                y = y + btn_h + S(5)
                draw_x = panel_x + x
                draw_y = panel_y + y
            end
            
            if draw_btn_inline(draw_x, draw_y, S(24), btn_h, "#", UI.C_ACCENT_N) then
                -- Collect Unique Notes
                local unique_notes = {}
                local used_text = {}
                
                -- 1. Try Recent Indices First
                local markers_by_id = {}
                for _, m in ipairs(ass_markers) do markers_by_id[m.markindex] = m end
                
                for _, rid in ipairs(director_state.recent_indices) do
                    local m = markers_by_id[rid]
                    if m and m.name and m.name ~= "" and not used_text[m.name] then
                        table.insert(unique_notes, m.name)
                        used_text[m.name] = true
                        if #unique_notes >= 15 then break end
                    end
                end
                
                -- 2. Fill with Newest Markers if space remains
                if #unique_notes < 15 then
                    for i = #ass_markers, 1, -1 do
                        local m = ass_markers[i]
                        if m and m.name and m.name ~= "" and not used_text[m.name] then
                            table.insert(unique_notes, m.name)
                            used_text[m.name] = true
                            if #unique_notes >= 15 then break end
                        end
                    end
                end
                
                if #unique_notes > 0 then
                    local menu_items = {}
                    for _, note in ipairs(unique_notes) do
                        table.insert(menu_items, (note:gsub("|", "||")))
                    end
                    local menu_str = table.concat(menu_items, "|")
                    
                    gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
                    local ret = gfx.showmenu(menu_str)
                    if ret > 0 and unique_notes[ret] then
                        director_state.input.text = unique_notes[ret]
                        director_state.input.cursor = #director_state.input.text
                        director_state.input.anchor = director_state.input.cursor
                        director_state.input.focus = true
                    end
                end
            end
            draw_x = draw_x + S(24) + S(5)
            x = x + S(24) + S(5)
        end

        -- Check wrap for "+" button
        if draw_x + S(24) > limit_x then
            x = padding
            y = y + btn_h + S(5)
            draw_x = panel_x + x
            draw_y = panel_y + y
        end

        if draw_btn_inline(draw_x, draw_y, S(24), btn_h, "+", UI.C_ACCENT_N) then
            local ok, name = reaper.GetUserInputs("Додати актора (Режисер)", 1, "Ім'я актора:", "")
            if ok then
                -- Remove variation selector (U+FE0F = \239\184\143) and trim spaces
                name = name:gsub("\239\184\143", ""):match("^%s*(.-)%s*$")
                
                if name ~= "" then
                    -- Check duplication
                    local exists = false
                    for _, act in ipairs(director_actors) do
                        if act == name then exists = true break end
                    end
                    
                    if not exists then
                        push_undo("Додати актора '" .. name .. "' (Режисер)")
                        table.insert(director_actors, name)
                        save_project_data(UI_STATE.last_project_id)
                    end
                end
            end
        end
    end
    
    -- --- ROW 2: INPUT & SAVE ---
    x = padding -- Reset X to start of line
    y = y + btn_h + S(10) -- Move down from last button row
    draw_x = panel_x + x -- Update absolute draw X
    draw_y = panel_y + y -- Update absolute draw Y
    
    -- Recalculate Input Height dynamically based on remaining space
    
    local min_input_h = S(50)
    local input_h = min_input_h
    
    -- Reserve space for save button in Right layout (vertical stacking)
    local is_right_layout = (cfg.director_layout == "right")
    local save_btn_space = is_right_layout and (S(30) + S(10)) or 0 -- Button height + gap
    
    if panel_h > (y + min_input_h + padding + save_btn_space) then
        input_h = panel_h - y - padding - save_btn_space
    end
    
    if not calc_only then
        ui_text_input(draw_x, draw_y, input_w, input_h, director_state.input, "Введіть текст правки...", input_queue, true, true)
    
        -- Check for changes to highlight button
        local has_changes = false
        if director_state.last_marker_id then
            if director_state.input.text ~= director_state.original_text then 
                has_changes = true 
            end
        elseif director_state.input.text ~= "" then
            has_changes = true
        end

        local save_col = has_changes and (director_state.last_marker_id and UI.C_BTN_UPDATE or UI.C_BTN_MEDIUM) or UI.C_BTN
        local save_label = director_state.last_marker_id and "Оновити" or "Зберегти"
        
        -- Position save button: vertical stack for Right mode, horizontal for Bottom mode
        local is_right_layout = (cfg.director_layout == "right")
        local save_x = is_right_layout and draw_x or (draw_x + input_w + S(10))
        local save_y = is_right_layout and (draw_y + input_h + S(10)) or draw_y
        local save_h = is_right_layout and S(30) or input_h

        if is_right_layout then
            save_btn_w = input_w
        end
        
        if draw_btn_inline(save_x, save_y, save_btn_w, save_h, save_label, save_col) then
            local txt = director_state.input.text
            if txt ~= "" then
                push_undo(save_label .. " правку (Режисер)")
                if director_state.last_marker_id then
                    reaper.SetProjectMarker4(0, director_state.last_marker_id, false, cur_time, 0, txt, 0, 0)
                    director_state.pending_scroll_id = director_state.last_marker_id
                else
                    local new_idx = reaper.AddProjectMarker(0, false, cur_time, 0, txt, -1)
                    director_state.pending_scroll_id = new_idx
                end
                ass_markers = capture_project_markers()
                update_regions_cache()
                
                -- Force table refresh
                table_data_cache.state_count = -1
                last_layout_state.state_count = -1
                prompter_drawer.marker_cache.count = -1
                
                -- Update Recent Indices
                local mid = director_state.pending_scroll_id
                if mid then
                    local new_indices = {mid}
                    for _, old_mid in ipairs(director_state.recent_indices) do
                        if old_mid ~= mid then table.insert(new_indices, old_mid) end
                    end
                    director_state.recent_indices = new_indices
                end
                
                director_state.last_marker_id = nil
                director_state.input.text = ""
                show_snackbar("Збережено", "success")

                -- Adjust playhead/cursor position +150ms
                reaper.SetEditCurPos(cur_time + 0.15, true, false)
            end
        end
    end
    
    -- Return total needed height
    return y + input_h + padding
end

local function draw_table(input_queue)
    local show_actor = UI_STATE.ass_file_loaded
    local start_y = S(65)
    col_vis_menu.handled = false -- Reset per frame
    
    local h_header = cfg.reader_mode and 0 or S(25)
    local row_h = cfg.reader_mode and S(80) or S(24)

    -- DO NOT modify F.std/F.bld globally
    -- Table Specific Font Logic
    local tr_sizes_reader = {tr_S=18, tr_M=20, tr_L=24, tr_XL=30}
    local tr_sizes_normal = {tr_S=14, tr_M=16, tr_L=18, tr_XL=22}
    local use_sz = (cfg.reader_mode and tr_sizes_reader[cfg.t_r_size] or tr_sizes_normal[cfg.t_r_size]) or 16
    
    gfx.setfont(F[cfg.t_r_size], cfg.p_font, S(use_sz))

    -- --- FILTER INPUT ---
    gfx.setfont(F.std) -- Use the (possibly locally scaled) standard font for global elements
    local filter_y = S(35)
    local filter_h = S(25)
    -- LAYOUT INITIALIZATION (Calculate avail sizes first)
    local w_director = cfg.w_director or S(300)
    local is_dir_right = (cfg.director_layout == "right")
    local h_director = (cfg.director_mode and not is_dir_right) and (dynamic_director_h or S(150)) or 0
    if cfg.director_mode and is_dir_right then h_director = 0 end
    
    local avail_w = gfx.w
    if cfg.director_mode and is_dir_right then avail_w = gfx.w - w_director end

    local filter_x = S(10)
    local opt_btn_w = S(30)
    local chk_w = S(25)
    local gap = S(5)
    
    local filter_w = avail_w - S(20) - opt_btn_w - chk_w - (gap * 2)
    
    local prev_text = table_filter_state.text
    ui_text_input(filter_x, filter_y, filter_w, filter_h, table_filter_state, "Фільтр (Текст або Актор)...", input_queue)

    -- Case Sensitive Toggle (Aa) - Always visible
    local chk_x = filter_x + filter_w + gap
    local case_col = find_replace_state.case_sensitive and UI.C_ACCENT_G or UI.C_BTN
    if draw_btn_inline(chk_x, filter_y, chk_w, filter_h, "Aa", case_col) then
        find_replace_state.case_sensitive = not find_replace_state.case_sensitive
    end

    -- Options / Close Toggle Button
    local btn_x = chk_x + chk_w + gap
    
    local mouse_in_menu = false
    if col_vis_menu.show then
        local m_h = 4 * S(24) + S(10) -- 4 items * 24h
        mouse_in_menu = gfx.mouse_x >= col_vis_menu.x and gfx.mouse_x <= col_vis_menu.x + col_vis_menu.w and
                        gfx.mouse_y >= col_vis_menu.y and gfx.mouse_y <= col_vis_menu.y + m_h
    elseif time_shift_menu.show then
        local m_h = S(125) -- Matches the visual height
        mouse_in_menu = gfx.mouse_x >= time_shift_menu.x and gfx.mouse_x <= time_shift_menu.x + time_shift_menu.w and
                        gfx.mouse_y >= time_shift_menu.y and gfx.mouse_y <= time_shift_menu.y + m_h
    end

    if find_replace_state.show then
        -- CLOSE BUTTON (Reddish)
        if draw_btn_inline(btn_x, filter_y, opt_btn_w, filter_h, "X", UI.C_BTN_ERROR) then
            find_replace_state.show = false
        end
    else
        -- MENU BUTTON (Standard)
        if draw_btn_inline(btn_x, filter_y, opt_btn_w, filter_h, "≡", UI.C_BTN) then
            -- Clear input focus on menu click
            director_state.input.focus = false
            table_filter_state.focus = false
            find_replace_state.find.focus = false
            find_replace_state.replace.focus = false
            
            if col_vis_menu.show or time_shift_menu.show then
                col_vis_menu.show = false
                time_shift_menu.show = false
            else
                local any_hidden = not (cfg.col_table_index and cfg.col_table_start and cfg.col_table_end and cfg.col_table_cps and cfg.col_table_actor)
                local col_label = (any_hidden and "• " or "") .. "Колонки..."
                local reader_label = (cfg.reader_mode and "• " or "") .. "Режим читача"
                local markers_label = (cfg.show_markers_in_table and "• " or "") .. "Відображати правки в таблиці"
                local director_label = (cfg.director_mode and "• " or "") .. "Режим Режисера"
                
                gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
                local menu_str = "Знайти та замінити|" .. reader_label .. "|" .. col_label .. "|Здвиг часу||" .. markers_label .. "|" .. director_label .. "||Розділення по Даберам||>Дії з Item|Розфарбувати за акторами|Прибрати розфарбування||Прибрати дублікати реплік (Waveform Match)||Нормалізація гучності реплік (EBU R128)|<"
                local ret = gfx.showmenu(menu_str)
                if ret == 1 then
                    find_replace_state.show = true
                    show_snackbar("'Знайти та замінити' працює лише для колонки 'Репліка'", "info")
                elseif ret == 2 then
                    cfg.reader_mode = not cfg.reader_mode
                    if cfg.reader_mode then
                        table_sort.col = "start"
                        table_sort.dir = 1
                    end
                    save_settings()
                    update_prompter_fonts()
                elseif ret == 3 then
                    col_vis_menu.show = true
                    col_vis_menu.x = (btn_x + opt_btn_w) - S(180)
                    col_vis_menu.y = filter_y + filter_h + gap
                elseif ret == 4 then
                    time_shift_menu.show = true
                    time_shift_menu.x = (btn_x + opt_btn_w) - S(280)
                    time_shift_menu.y = filter_y + filter_h + gap
                elseif ret == 5 then
                    cfg.show_markers_in_table = not cfg.show_markers_in_table
                    save_settings()
                elseif ret == 6 then
                    cfg.director_mode = not cfg.director_mode
                    if cfg.director_mode then
                        cfg.show_markers_in_table = true
                    end
                    save_settings()
                elseif ret == 7 then
                    DUBBERS.show_dashboard = true
                    DUBBERS.load()
                elseif ret == 8 then
                    apply_item_coloring(false) -- Colorize
                elseif ret == 9 then
                    apply_item_coloring(true) -- Reset
                elseif ret == 10 then
                    filter_unique_item_replicas()
                elseif ret == 11 then
                    ebu_r128_replicas_normalize()
                end
            end
        end

        -- Red Dot indicator for hidden columns or enabled markers
        local any_hidden = cfg.reader_mode or cfg.show_markers_in_table or not (cfg.col_table_index and cfg.col_table_start and cfg.col_table_end and cfg.col_table_cps and cfg.col_table_actor)
        if any_hidden then
            set_color(UI.C_RED) -- Red
            gfx.circle(btn_x + opt_btn_w - 4, filter_y + 4, 3, 1)
        end
    end
    
    if table_filter_state.text ~= prev_text then
        UI_STATE.scroll_y = 0
    end
    
    -- INLINE FIND/REPLACE UI
    if find_replace_state.show then
        local fr_y = filter_y + filter_h + S(5)
        local fr_h = S(25)
        
        -- Replace Input
        local btn_apply_w = S(80)
        local rep_w = gfx.w - S(20) - btn_apply_w - gap
        
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
                        
                        local start_idx, end_idx = utf8_find_accent_blind(txt, search)
                        while start_idx do
                            table.insert(res_tbl, txt:sub(last_pos, start_idx - 1))
                            table.insert(res_tbl, replace)
                            last_pos = end_idx + 1
                            count = count + 1 
                            
                            local remaining = txt:sub(last_pos)
                            local next_s, next_e = utf8_find_accent_blind(remaining, search)
                            if next_s then
                                start_idx = last_pos + next_s - 1
                                end_idx = last_pos + next_e - 1
                            else
                                start_idx = nil
                            end
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
                show_snackbar("Замінено " .. count .. " входжень", "success")
                
                -- Clear inputs after successful replacement
                table_filter_state.text = ""
                table_filter_state.cursor = 0
                table_filter_state.anchor = 0
                find_replace_state.replace.text = ""
                find_replace_state.replace.cursor = 0
                find_replace_state.replace.anchor = 0
                table_data_cache.state_count = -1
                last_layout_state.state_count = -1
            else
                show_snackbar("Введіть текст в фільтр", "error")
            end
        end
        
        start_y = start_y + S(35) -- Shift content down
    end
    
    -- Helper: Delete Logic
    local function delete_logic()
        -- Separate ASS lines and markers
        local selected_ass_entries = {}
        local selected_marker_indices = {}
        
        -- Collect selected ASS lines
        for p, l in ipairs(ass_lines) do
            if table_selection[l.index or p] then
                table.insert(selected_ass_entries, {line = l, pos = p})
            end
        end
        
        -- Collect selected markers (string indices like "M12")
        for idx in pairs(table_selection) do
            if type(idx) == "string" and idx:sub(1,1) == "M" then
                local markindex = tonumber(idx:sub(2))
                if markindex then
                    table.insert(selected_marker_indices, markindex)
                end
            end
        end
        
        local total_deleted = 0
        
        -- Delete markers (Robust Method)
        if #selected_marker_indices > 0 then
            if #selected_ass_entries > 0 then
                push_undo("Видалення реплік та правок")
            else
                push_undo("Видалення правок")
            end
            
            -- Build a lookup set of IDs to delete
            local markers_to_delete = {}
            for _, id in ipairs(selected_marker_indices) do markers_to_delete[id] = true end
            
            -- 1. Sync internal ass_markers table (Prevent resurrection by rebuild_regions)
            local new_ass_markers = {}
            for _, m in ipairs(ass_markers) do
                if not markers_to_delete[m.markindex] then
                    table.insert(new_ass_markers, m)
                end
            end
            ass_markers = new_ass_markers
            
            -- 2. Delete from Project
            local i = reaper.CountProjectMarkers(0) - 1
            while i >= 0 do
                local _, isrgn, _, _, _, mark_id = reaper.EnumProjectMarkers3(0, i)
                if not isrgn and markers_to_delete[mark_id] then
                    reaper.DeleteProjectMarkerByIndex(0, i)
                    total_deleted = total_deleted + 1
                end
                i = i - 1
            end
        end
        
        -- Delete ASS lines
        if #selected_ass_entries > 0 then
            if #selected_marker_indices == 0 then
                push_undo("Видалення реплік")
            end
            -- Optimized removal: One pass O(N)
            local new_lines = {}
            local to_delete = {}
            for _, ent in ipairs(selected_ass_entries) do to_delete[ent.pos] = true end
            
            for p, l in ipairs(ass_lines) do
                if not to_delete[p] then
                    table.insert(new_lines, l)
                else
                    total_deleted = total_deleted + 1
                end
            end
            ass_lines = new_lines
            cleanup_actors()
            rebuild_regions()
            save_project_data(UI_STATE.last_project_id)
        end
        
        if total_deleted > 0 then
            table_selection = {}
            last_selected_row = nil
            table_data_cache.state_count = -1
            last_layout_state.state_count = -1
            prompter_drawer.marker_cache.count = -1
            show_snackbar("Видалено: " .. total_deleted, "error")
        end
    end

    local function duplicate_logic(target_id)
        local original_pos = nil
        for p, l in ipairs(ass_lines) do
            if (l.index or p) == target_id then
                original_pos = p
                break
            end
        end

        if original_pos then
            local source = ass_lines[original_pos]
            push_undo("Продублювати репліку")
            
            -- Create copy
            local new_replica = {}
            for k, v in pairs(source) do new_replica[k] = v end
            
            -- Generate new unique index
            local max_idx = 0
            for _, l in ipairs(ass_lines) do
                if type(l.index) == "number" and l.index > max_idx then
                    max_idx = l.index
                end
            end
            new_replica.index = max_idx + 1
            
            -- Insert after original
            table.insert(ass_lines, original_pos + 1, new_replica)
            
            cleanup_actors()
            rebuild_regions()
            save_project_data(UI_STATE.last_project_id)
            
            table_selection = {}
            table_selection[new_replica.index] = true
            table_data_cache.state_count = -1
            last_layout_state.state_count = -1
            show_snackbar("Репліку продубльовано", "success")
            return true
        end
        return false
    end

    -- Keyboard Shortcuts
    if input_queue then
        for _, key in ipairs(input_queue) do
            -- Verify we are not typing in a text field
            if not table_filter_state.focus and not find_replace_state.find.focus and 
               not find_replace_state.replace.focus and not director_state.input.focus then
                -- Ctrl+A (Select All Filtered)
                if key == 1 then
                    table_selection = {}
                    local current_data = table_data_cache.list or {}
                    for _, line in ipairs(current_data) do
                        table_selection[line.index] = true
                    end
                    last_selected_row = nil
                end

                -- Delete (6579564) or Backspace (8)
                if key == 6579564 or key == 8 then
                    delete_logic()
                end

                -- Ctrl+D (Duplicate or Deselect All)
                if key == 4 then
                    local sel_count = 0
                    local target_id = nil
                    for idx, _ in pairs(table_selection) do
                        sel_count = sel_count + 1
                        target_id = idx
                    end
                    
                    if sel_count == 1 and type(target_id) == "number" then
                        duplicate_logic(target_id)
                    else
                        table_selection = {}
                        last_selected_row = nil
                        show_snackbar("Знято виділення з реплік", "info")
                    end
                end

                -- Navigation: Up (30064), Down (1685026670)
                if key == 30064 or key == 1685026670 then
                    local ds = ass_lines
                    local curr_idx = 0
                    
                    -- Find last selected index
                    for i, l in ipairs(ds) do
                        if table_selection[l.index or i] then curr_idx = i end
                    end
                    
                    if curr_idx == 0 and #ds > 0 then curr_idx = 1 end
                    
                    local new_idx = curr_idx
                    if key == 30064 then new_idx = new_idx - 1 else new_idx = new_idx + 1 end
                    
                    -- Clamp
                    if new_idx < 1 then new_idx = 1 end
                    if new_idx > #ds then new_idx = #ds end
                    
                    -- Apply Selection
                    local item = ds[new_idx]
                    if item then
                        table_selection = {}
                        table_selection[item.index or new_idx] = true
                        last_selected_row = new_idx
                        
                        -- Auto-Scroll (Dynamic)
                        local layout = table_layout_cache[new_idx]
                        if layout then
                            local item_y = layout.y
                            local row_h_local = layout.h
                            local view_h = gfx.h - S(110) -- Approximate available height
                            
                            if item_y < UI_STATE.target_scroll_y then
                                UI_STATE.target_scroll_y = item_y
                            elseif item_y + row_h_local > UI_STATE.target_scroll_y + view_h then
                                UI_STATE.target_scroll_y = item_y + row_h_local - view_h
                            end
                        end
                    end
                end
            end
        end
    end

    -- --- DATA SOURCE PREPARATION (CACHED) ---
    local current_state_count = reaper.GetProjectStateChangeCount(0)
    local current_proj_id = UI_STATE.last_project_id
    local cache_invalid = (table_data_cache.state_count ~= current_state_count or
                           table_data_cache.project_id ~= current_proj_id or
                           table_data_cache.filter ~= table_filter_state.text or
                           table_data_cache.sort_col ~= table_sort.col or
                           table_data_cache.sort_dir ~= table_sort.dir or
                           table_data_cache.show_markers ~= cfg.show_markers_in_table or
                           table_data_cache.case_sensitive ~= find_replace_state.case_sensitive or
                           table_data_cache.fr_show ~= find_replace_state.show)

    if cache_invalid then
        local raw_data = {}
        for i, line in ipairs(ass_lines) do
            raw_data[i] = line
            if not line.index then line.index = i end
        end
        
        if cfg.show_markers_in_table then
            update_marker_cache() -- Reuse shared prompter cache
            for _, m in ipairs(prompter_drawer.marker_cache.markers) do
                table.insert(raw_data, {
                    t1 = m.pos, t2 = m.pos, text = m.name, actor = ":ПРАВКА:",
                    -- Add redundant fields for robust filtering/sorting in Regions mode
                    pos = m.pos, rgnend = m.pos, name = m.name,
                    is_marker = true, marker_color = m.color, markindex = m.markindex,
                    index = "M" .. m.markindex
                })
            end
        end

        local filtered = {}
        local query = table_filter_state.text
        local query_lower = utf8_lower(query)
        local query_clean = strip_accents(query_lower)
        local use_case = find_replace_state.case_sensitive

        for _, line in ipairs(raw_data) do
            local target_text = line.text or line.name or "" -- Robust text selection
            local text_match, actor_match, index_match = false, false, false
            local h_text, h_actor

            if use_case then
                text_match = target_text:find(query, 1, true)
                if text_match then h_text = {target_text:find(query, 1, true)} end
                if show_actor and line.actor then
                    actor_match = line.actor:find(query, 1, true)
                    if actor_match then h_actor = {line.actor:find(query, 1, true)} end
                end
                index_match = tostring(line.index or ""):find(query, 1, true)
            else
                local clean_text = strip_accents(utf8_lower(strip_tags(target_text)))
                text_match = clean_text:find(query_clean, 1, true)
                if text_match then 
                    local s, e = utf8_find_accent_blind(target_text, query)
                    if s then h_text = {s, e} end
                end
                if show_actor and line.actor then
                    local clean_actor = strip_accents(utf8_lower(line.actor))
                    actor_match = clean_actor:find(query_clean, 1, true)
                    if actor_match then
                        local s, e = utf8_find_accent_blind(line.actor, query)
                        if s then h_actor = {s, e} end
                    end
                end
                index_match = tostring(line.index or ""):lower():find(query_clean, 1, true)
            end

            if query == "" or text_match or (not find_replace_state.show and (actor_match or index_match)) then
                line.h_text = h_text -- Store pre-calculated highlight
                line.h_actor = h_actor
                
                -- Pre-calculate CPS and strings for table view
                local duration = (line.t2 or 0) - (line.t1 or 0)
                local clean_txt = (line.text or ""):gsub(acute, ""):gsub("%s+", "")
                local char_count = utf8.len(clean_txt) or #clean_txt
                line.cps = duration > 0 and (char_count / duration) or 0
                line.cps_str = line.is_marker and "" or string.format("%.1f", line.cps)
                line.cps_color = UTILS.get_cps_color(line.cps)
                
                line.t1_str = reaper.format_timestr(line.t1 or 0, "")
                line.t2_str = line.is_marker and "" or reaper.format_timestr(line.t2 or 0, "")
                line.idx_str = tostring(line.index or "")
                
                table.insert(filtered, line)
            end
        end

        -- Sorting
        if table_sort.col ~= "#" or table_sort.dir ~= 1 then
            local temp = {}
            for i, item in ipairs(filtered) do
                temp[i] = { item = item, val = get_sort_value(item, table_sort.col, show_actor) }
            end
            table.sort(temp, function(a, b)
                if a.val == b.val then
                    if (table_sort.col == "Ак." or table_sort.col == "enabled") then
                        local t1_a = a.item.t1 or 0; local t1_b = b.item.t1 or 0
                        if t1_a ~= t1_b then return t1_a < t1_b end
                    end
                    local idx_a, idx_b = a.item.index or 0, b.item.index or 0
                    if type(idx_a) ~= type(idx_b) then return type(idx_a) == "number" end
                    return idx_a < idx_b
                end
                if type(a.val) ~= type(b.val) then
                    return (table_sort.dir == 1) == (type(a.val) == "number")
                end
                if table_sort.dir == 1 then
                    return a.val < b.val
                else
                    return a.val > b.val
                end
            end)
            filtered = {}
            for i, t in ipairs(temp) do filtered[i] = t.item end
        end

        table_data_cache.list = filtered
        table_data_cache.state_count = current_state_count
        table_data_cache.project_id = current_proj_id
        table_data_cache.filter = query
        table_data_cache.sort_col = table_sort.col
        table_data_cache.sort_dir = table_sort.dir
        table_data_cache.show_markers = cfg.show_markers_in_table
        table_data_cache.case_sensitive = use_case
        table_data_cache.fr_show = find_replace_state.show
        
        -- Cleanup selection of stale marker indices (only those not in current raw_data)
        -- We do NOT cleanup based on 'filtered' as that would wipe selection during search
        local project_indices = {}
        for _, line in ipairs(raw_data) do
            project_indices[line.index] = true
        end
        for idx in pairs(table_selection) do
            if not project_indices[idx] then
                table_selection[idx] = nil
            end
        end
    end

    local data_source = table_data_cache.list

    -- Column layout: Build x_off based on visible columns only (CACHED)
    local raw_data_count = #ass_lines + (cfg.show_markers_in_table and #prompter_drawer.marker_cache.markers or 0)
    local layout_changed = (last_layout_state.w ~= gfx.w or 
                            last_layout_state.count ~= raw_data_count or 
                            last_layout_state.mode ~= cfg.reader_mode or
                            last_layout_state.filter ~= table_filter_state.text or
                            last_layout_state.sort_col ~= table_sort.col or
                            last_layout_state.sort_dir ~= table_sort.dir or
                            last_layout_state.show_markers ~= cfg.show_markers_in_table or
                            last_layout_state.gui_scale ~= cfg.gui_scale or
                            last_layout_state.state_count ~= current_state_count or
                            last_layout_state.col_vis_index ~= cfg.col_table_index or
                            last_layout_state.col_vis_start ~= cfg.col_table_start or
                            last_layout_state.col_vis_end ~= cfg.col_table_end or
                            last_layout_state.col_vis_cps ~= cfg.col_table_cps or
                            last_layout_state.col_vis_actor ~= cfg.col_table_actor or
                            OTHER.col_resize.dragging or
                            last_layout_state.col_w_enabled ~= cfg.col_w_enabled or
                            last_layout_state.col_w_index ~= cfg.col_w_index or
                            last_layout_state.col_w_start ~= cfg.col_w_start or
                            last_layout_state.col_w_end ~= cfg.col_w_end or
                            last_layout_state.col_w_cps ~= cfg.col_w_cps or
                            last_layout_state.col_w_actor ~= cfg.col_w_actor or
                            last_layout_state.fr_show ~= find_replace_state.show or
                            last_layout_state.t_r_size ~= cfg.t_r_size)

    local x_off = last_layout_state.x_off or {S(10)}
    local col_keys = last_layout_state.col_keys or {}
    if layout_changed then
        x_off = {S(10)}
        col_keys = {}
        local function add_col(w, key) 
            table.insert(x_off, x_off[#x_off] + w) 
            table.insert(col_keys, key)
        end
        if not cfg.reader_mode then
            add_col(S(cfg.col_w_enabled), "col_w_enabled")
            if cfg.col_table_index then add_col(S(cfg.col_w_index), "col_w_index") end
            if cfg.col_table_start then add_col(S(cfg.col_w_start), "col_w_start") end
            if cfg.col_table_end then add_col(S(cfg.col_w_end), "col_w_end") end
            if cfg.col_table_cps then add_col(S(cfg.col_w_cps), "col_w_cps") end
            if cfg.col_table_actor then add_col(S(cfg.col_w_actor), "col_w_actor") end
        end
    end

    if layout_changed then
        table_layout_cache = {}
        local current_y_offset = 0
        
        -- Calculate height for each row using the already prepared data_source
        local content_x_start = x_off[#x_off] or S(10)
        local max_w = avail_w - content_x_start - 30 -- padding + scrollbar (updated to use avail_w)
        
        -- Ensure font is set to the correct size for the NEW mode
        local use_sz_layout = (cfg.reader_mode and tr_sizes_reader[cfg.t_r_size] or tr_sizes_normal[cfg.t_r_size]) or 16
        gfx.setfont(F[cfg.t_r_size], cfg.p_font, S(use_sz_layout))
        local line_h = gfx.texth
        
        -- Dynamic min_row_h based on font
        local extra_pad = S(6)
        if cfg.t_r_size == "tr_XL" then extra_pad = S(9)
        elseif cfg.t_r_size == "tr_L" then extra_pad = S(8)
        elseif cfg.t_r_size == "tr_M" then extra_pad = S(8)
        else extra_pad = S(8) end

        local min_row_h = cfg.reader_mode and S(60) or (line_h + extra_pad)
        local padding_v = cfg.reader_mode and 20 or 8

        for i, line in ipairs(data_source) do
            local h = min_row_h
            local cached_lines = nil
            if cfg.reader_mode then
                local display_txt = (line.text or ""):gsub("[\n\r]", " ")
                if line.is_marker and line.markindex then
                    display_txt = "(M" .. line.markindex .. ") - " .. display_txt
                end
                cached_lines = wrap_text_manual(display_txt, max_w)
                h = math.max(min_row_h, #cached_lines * line_h + padding_v)
            end
            table.insert(table_layout_cache, {y = current_y_offset, h = h, lines = cached_lines})
            current_y_offset = current_y_offset + h
        end
        
        last_layout_state = {
            w = gfx.w, count = raw_data_count, mode = cfg.reader_mode, 
            filter = table_filter_state.text, sort_col = table_sort.col, 
            sort_dir = table_sort.dir, gui_scale = cfg.gui_scale,
            show_markers = cfg.show_markers_in_table,
            state_count = current_state_count,
            x_off = x_off,
            col_keys = col_keys,
            col_w_enabled = cfg.col_w_enabled,
            col_w_index = cfg.col_w_index,
            col_w_start = cfg.col_w_start,
            col_w_end = cfg.col_w_end,
            col_w_cps = cfg.col_w_cps,
            col_w_actor = cfg.col_w_actor,
            col_vis_index = cfg.col_table_index,
            col_vis_start = cfg.col_table_start,
            col_vis_end = cfg.col_table_end,
            col_vis_cps = cfg.col_table_cps,
            col_vis_actor = cfg.col_table_actor,
            fr_show = find_replace_state.show,
            t_r_size = cfg.t_r_size
        }
    end

    local total_h = #table_layout_cache > 0 and (table_layout_cache[#table_layout_cache].y + table_layout_cache[#table_layout_cache].h) or 0
    
    -- Dynamic Layout Variables
    local is_dir_right = (cfg.director_mode and cfg.director_layout == "right")
    -- (Variables w_director, is_dir_right, avail_w, h_director already calculated at top of function)

    -- Logic for manual vs dynamic height is handled at top.
    -- Just need to ensure `h_director` variable is correct for Bottom/Manual logic below.
    if cfg.director_mode and not is_dir_right and cfg.h_director then
        local manual = cfg.h_director or S(150)
        if dynamic_director_h and dynamic_director_h > manual and not director_resize_drag then
            h_director = dynamic_director_h
        else
            h_director = manual
        end
    end
    
    local content_y = start_y + h_header
    local avail_h = gfx.h - content_y - h_director
    if avail_h < 0 then avail_h = 0 end

    local max_scroll = math.max(0, total_h - avail_h)
    
    -- Auto-scroll to specific marker (e.g. after Save/Update in Director Panel)
    if director_state.pending_scroll_id then
        for i, line in ipairs(data_source) do
            if line.is_marker and line.markindex == director_state.pending_scroll_id then
                -- 1. Update Selection
                table_selection = {}
                table_selection[line.index] = true 
                last_selected_row = i

                -- 2. Scroll
                if table_layout_cache[i] then
                    local layout = table_layout_cache[i]
                    UI_STATE.target_scroll_y = math.max(0, math.min(max_scroll, layout.y - (avail_h / 2) + (layout.h / 2)))
                end
                
                director_state.pending_scroll_id = nil
                break
            end
        end
    end
    
    -- Auto-scroll to current playback position (only when position changes)
    local play_pos = reaper.GetPlayPosition()
    local edit_pos = reaper.GetCursorPosition()
    local current_pos = reaper.GetPlayState() > 0 and play_pos or edit_pos
    
    -- Only auto-scroll if position changed significantly (user jumped) OR line changed
    local pos_changed = math.abs(current_pos - UI_STATE.last_tracked_pos) > 0.5
    
    -- Find which line corresponds to current position
    local active_line_idx = nil
    for i, line in ipairs(data_source) do
        if current_pos >= line.t1 and current_pos < line.t2 then
            active_line_idx = i
            break
        end
    end

    -- Trigger auto-scroll if:
    -- 1. Playhead jumped significantly (>0.5s)
    -- 2. OR the active line index changed (progression)
    -- 3. AND not suppressed by manual interaction
    
    -- Suppress auto-scroll immediately if user just clicked in the table area
    if (gfx.mouse_cap & 1 == 1) and (UI_STATE.last_mouse_cap & 1 == 0) and gfx.mouse_y >= content_y and gfx.mouse_y < content_y + avail_h then
        suppress_auto_scroll_frames = 5
    end
    
    if suppress_auto_scroll_frames > 0 then
        suppress_auto_scroll_frames = suppress_auto_scroll_frames - 1
    end
    
    local line_changed = (active_line_idx ~= last_auto_scroll_idx)
    if (pos_changed or line_changed) and not UI_STATE.skip_auto_scroll and suppress_auto_scroll_frames == 0 then
        UI_STATE.last_tracked_pos = current_pos
        last_auto_scroll_idx = active_line_idx
        
        if active_line_idx and table_layout_cache[active_line_idx] then
            local layout = table_layout_cache[active_line_idx]
            -- Center the line
            UI_STATE.target_scroll_y = math.max(0, math.min(max_scroll, layout.y - (avail_h / 2) + (layout.h / 2)))
        end
    end
    
    -- Smooth Scroll Logic
    local mouse_in_director = cfg.director_mode and gfx.mouse_y >= gfx.h - h_director
    if gfx.mouse_wheel ~= 0 and not mouse_in_director then
        UI_STATE.target_scroll_y = UI_STATE.target_scroll_y - (gfx.mouse_wheel * 0.25)
        if UI_STATE.target_scroll_y < 0 then UI_STATE.target_scroll_y = 0 end
        if UI_STATE.target_scroll_y > max_scroll then UI_STATE.target_scroll_y = max_scroll end
        gfx.mouse_wheel = 0
    end

    local diff = UI_STATE.target_scroll_y - UI_STATE.scroll_y
    if math.abs(diff) > 0.5 then
        UI_STATE.scroll_y = UI_STATE.scroll_y + (diff * 0.8)
    else
        UI_STATE.scroll_y = UI_STATE.target_scroll_y
    end

    -- Prepare Buffer 98 for Rows (Clipping)
    local prev_dest = gfx.dest
    gfx.dest = 98
    gfx.setimgdim(98, gfx.w, math.max(1, avail_h))
    set_color(UI.C_BG)
    gfx.rect(0, 0, avail_w, avail_h, 1)
    
    -- Find starting index based on UI_STATE.scroll_y and layout cache
    local start_idx = 1
    for i, layout in ipairs(table_layout_cache) do
        if layout.y + layout.h > UI_STATE.scroll_y then
            start_idx = i
            break
        end
    end
    
    for i = start_idx, #data_source do
        local layout = table_layout_cache[i]
        if not layout then break end
        
        local screen_y = content_y + (layout.y - UI_STATE.scroll_y)
        local row_h_dynamic = layout.h
        
        -- Stop if we are below visible area
        if screen_y > content_y + avail_h then break end
        
        local buf_y = layout.y - UI_STATE.scroll_y

        -- ASS mode: show all lines with checkbox
        local line = data_source[i]
        
        -- Special background for markers
        if line.is_marker then
            set_color(UI.C_MARKER_BG) -- Dark reddish background for markers
            gfx.rect(0, buf_y, avail_w, row_h_dynamic, 1)
        else
            -- zebra
            if i % 2 == 0 then set_color(UI.C_ROW) else set_color(UI.C_ROW_ALT) end
            gfx.rect(0, buf_y, avail_w, row_h_dynamic, 1)
        end
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
                if line.is_marker then
                    set_color(UI.C_MARKER_SEL) -- Dark Orange Selection for markers
                else
                    set_color(UI.C_HILI_GREEN) -- Darker Green Selection
                end
                gfx.rect(0, buf_y, avail_w, row_h_dynamic, 1)
            end
            
            -- Hover Effect
            local row_hover = UI_STATE.window_focused and (gfx.mouse_x >= 0 and gfx.mouse_x < avail_w and
                                 gfx.mouse_y >= screen_y and gfx.mouse_y < screen_y + row_h_dynamic and
                                 gfx.mouse_y >= content_y and gfx.mouse_y < content_y + avail_h)
            
            if row_hover then
                set_color(UI.C_HILI_WHITE)
                gfx.rect(0, buf_y, avail_w, row_h_dynamic, 1)
            end

            if is_active_row then
                set_color(UI.GET_T_AR_COLOR(1)) -- Bright Green Border
                gfx.rect(0, buf_y, 5, row_h_dynamic, 1)

                set_color(UI.GET_T_AR_COLOR(cfg.t_ar_alpha))
                gfx.rect(0, buf_y, avail_w, row_h_dynamic, 1)
            end
            
            local chk_sz = S(16)
            local chk_x = x_off[1]
            if not cfg.reader_mode and not line.is_marker then
                -- Checkbox column (skip for markers)
                local chk_y = buf_y + (row_h_dynamic - chk_sz)/2
                
                set_color(UI.C_ED_GUTTER)
                gfx.rect(chk_x, chk_y, chk_sz, chk_sz, 0)
                
                if line.enabled ~= false then
                    set_color(UI.C_TXT)
                    -- Checkmark
                    gfx.line(chk_x + S(3), chk_y + S(8), chk_x + S(7), chk_y + S(12))
                    gfx.line(chk_x + S(4), chk_y + S(8), chk_x + S(8), chk_y + S(12))
                    gfx.line(chk_x + S(7), chk_y + S(12), chk_x + S(13), chk_y + S(4))
                    gfx.line(chk_x + S(8), chk_y + S(12), chk_x + S(14), chk_y + S(4))
                end
            end
            
            local row_base_color = UI.C_TXT
            if cfg.reader_mode then
                if is_enabled then
                    row_base_color = UI.C_TXT -- Enabled = White
                else
                    row_base_color = {0.5, 0.5, 0.5, 1} -- Disabled = Gray
                end
            end
            set_color(row_base_color)
            local buf_y_text = buf_y + (cfg.reader_mode and 10 or 4)
            gfx.setfont(F[cfg.t_r_size]) -- Always use our dedicated slot for row content
            
            -- Use original index if possible
            -- Helper to draw truncated text in cell
            local col_ptr = cfg.reader_mode and 1 or 2
            local function draw_cell_txt(txt, idx)
                if not idx or not x_off[idx] then return end
                local x = x_off[idx]
                local next_x = x_off[idx + 1] or gfx.w
                local w = next_x - x - S(4) -- padding
                if w > S(5) then
                    gfx.x = x; gfx.y = buf_y_text
                    gfx.drawstr(fit_text_width(txt, w))
                end
            end

            if not cfg.reader_mode then
                if cfg.col_table_index then
                    draw_cell_txt(line.idx_str, col_ptr); col_ptr = col_ptr + 1
                end

                if cfg.col_table_start then
                    draw_cell_txt(line.t1_str, col_ptr); col_ptr = col_ptr + 1
                end

                if cfg.col_table_end then
                    draw_cell_txt(line.t2_str, col_ptr); col_ptr = col_ptr + 1
                end
            end

            if not cfg.reader_mode and cfg.col_table_cps then
                set_color(line.cps_color)
                draw_cell_txt(line.cps_str, col_ptr); col_ptr = col_ptr + 1
            end
            
            -- Helper for highlighting and wrapping
            local function draw_highlighted_text(txt, x, y, max_w, row_h_passed, h_range, cached_lines)
                set_color(row_base_color)
                
                if not cfg.reader_mode then
                    -- Standard Mode: Truncate and draw single line
                    local display_txt = txt:gsub("[\n\r]", " ")
                    display_txt = fit_text_width(display_txt, max_w)
                    
                    if h_range then
                        local s_start, s_end = h_range[1], h_range[2]
                        -- Ensure highlight is within visible/truncated text
                        if s_start <= #display_txt then
                            local pre_match = display_txt:sub(1, s_start - 1)
                            local match_str = display_txt:sub(s_start, math.min(s_end, #display_txt))
                            local pre_w = gfx.measurestr(pre_match)
                            local match_w = gfx.measurestr(match_str)
                            set_color(UI.C_HILI_YELLOW, 0.4)
                            gfx.rect(x + pre_w, y, match_w, gfx.texth, 1)
                            set_color(row_base_color)
                        end
                    end
                    gfx.x, gfx.y = x, y
                    gfx.drawstr(display_txt)
                elseif cached_lines then
                    -- Reader Mode: Use cached wrapped lines
                    local total_text_h = #cached_lines * gfx.texth
                    local cur_y = buf_y + (row_h_passed - total_text_h) / 2
                    local query = table_filter_state.text
                    local first_match_done = false

                    for _, line_str in ipairs(cached_lines) do
                        local line_h = gfx.texth
                        if cur_y + line_h > buf_y + row_h_passed then break end
                        
                        if #query > 0 and not first_match_done then
                            local s_start, s_end
                            if find_replace_state.case_sensitive then
                                s_start, s_end = line_str:find(query, 1, true)
                            else
                                s_start, s_end = utf8_find_accent_blind(line_str, query)
                            end
                            if s_start then
                                local pre_match = line_str:sub(1, s_start - 1)
                                local match_str = line_str:sub(s_start, s_end)
                                local pre_w = gfx.measurestr(pre_match)
                                local match_w = gfx.measurestr(match_str)
                                set_color(UI.C_HILI_YELLOW, 0.4)
                                gfx.rect(x + pre_w, cur_y, match_w, line_h, 1)
                                set_color(row_base_color)
                                first_match_done = true 
                            end
                        end
                        
                        gfx.x, gfx.y = x, cur_y
                        gfx.drawstr(line_str)
                        cur_y = cur_y + line_h
                    end
                end
            end

            if not cfg.reader_mode and cfg.col_table_actor then
                gfx.x = x_off[col_ptr]; gfx.y = buf_y_text; 
                draw_highlighted_text(actor, x_off[col_ptr], buf_y_text, x_off[col_ptr+1] - x_off[col_ptr] - 10, row_h_dynamic, line.h_actor)
                col_ptr = col_ptr + 1
            end
            
            draw_highlighted_text(line.text or "", x_off[col_ptr], buf_y_text, gfx.w - x_off[col_ptr] - 10, row_h_dynamic, line.h_text, layout.lines)
            
            -- Click logic
            -- FIX: Check bit 1 (Left Mouse) regardless of other flags
            if (gfx.mouse_cap & 1 == 1) and (UI_STATE.last_mouse_cap & 1 == 0) and not mouse_in_menu and not col_vis_menu.handled then
                -- Safety check: click must be within both the visible content area AND the row itself
                -- Also check horizontal bounds to prevent clicks in Director Panel (when docked right)
                if gfx.mouse_x < avail_w and
                   gfx.mouse_y >= content_y and gfx.mouse_y < content_y + avail_h and
                   gfx.mouse_y >= screen_y and gfx.mouse_y < screen_y + row_h_dynamic then
                    -- Checkbox click? (Only if visible and not a marker)
                    if not cfg.reader_mode and not line.is_marker and chk_x and gfx.mouse_x >= chk_x - S(5) and gfx.mouse_x <= chk_x + chk_sz + S(10) then
                        -- BULK CHECKBOX LOGIC
                        push_undo("Перемикання видимості")
                        
                        -- Clear input focus on checkbox click
                        director_state.input.focus = false
                        table_filter_state.focus = false
                        find_replace_state.find.focus = false
                        find_replace_state.replace.focus = false
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
                            UI_STATE.last_tracked_pos = line.t1 -- Always sync position on click
                            last_auto_scroll_idx = i -- Sync to prevent auto-centering immediately after click
                            
                            -- Clear input focus on row click
                            director_state.input.focus = false
                            table_filter_state.focus = false
                            find_replace_state.find.focus = false
                            find_replace_state.replace.focus = false
                            
                            -- Navigate logic
                            local replica_x_start = cfg.reader_mode and 0 or x_off[#x_off]
                            if gfx.mouse_x >= replica_x_start then
                                local now = reaper.time_precise()
                                if UI_STATE.last_click_row == i and (now - UI_STATE.last_click_time) < 0.5 then
                                    -- Double-click on text
                                    if line.is_marker then
                                        -- Edit marker name
                                        local edit_marker = line
                                        open_text_editor(line.text, function(new_text)
                                            push_undo("Редагування правки")
                                            -- Find marker index
                                            local target_idx = -1
                                            local m_count = reaper.CountProjectMarkers(0)
                                            for j = 0, m_count - 1 do
                                                local _, isrgn, pos, _, _, markindex = reaper.EnumProjectMarkers3(0, j)
                                                if not isrgn and (markindex == edit_marker.markindex or math.abs(pos - edit_marker.t1) < 0.001) then
                                                    target_idx = j
                                                    break
                                                end
                                            end
                                            if target_idx ~= -1 then
                                                reaper.SetProjectMarkerByIndex(0, target_idx, false, edit_marker.t1, 0, edit_marker.markindex, new_text, edit_marker.marker_color or 0)
                                            end
                                            
                                            ass_markers = capture_project_markers()
                                            table_data_cache.state_count = -1 -- FORCE UPDATE TABLE
                                            last_layout_state.state_count = -1 -- FORCE UPDATE LAYOUT
                                            prompter_drawer.marker_cache.count = -1 -- FORCE UPDATE MARKERS
                                        end, original_idx, nil, true)
                                    else
                                        -- Edit ASS line
                                        local edit_line = line
                                        open_text_editor(line.text, function(new_text)
                                            push_undo("Редагування тексту")
                                            edit_line.text = new_text
                                            rebuild_regions()
                                            table_data_cache.state_count = -1 -- FORCE UPDATE TABLE
                                            last_layout_state.state_count = -1 -- FORCE UPDATE LAYOUT
                                        end, original_idx, ass_lines)
                                    end
                                    UI_STATE.last_click_row = 0
                                else
                                    UI_STATE.last_click_time = now
                                    UI_STATE.last_click_row = i
                                    reaper.SetEditCurPos(line.t1, true, false)
                                end
                            else
                                -- Just Navigate
                                reaper.SetEditCurPos(line.t1, true, false)
                            end
                        end
                    end
                end
            -- Fixed duplicate block logic
                    
            elseif (gfx.mouse_cap & 2 == 2) and (UI_STATE.last_mouse_cap & 2 == 0) and not mouse_in_menu then
                -- Right Click on Row (with safety check)
                if gfx.mouse_x < avail_w and
                   gfx.mouse_y >= content_y and gfx.mouse_y < content_y + avail_h and
                   gfx.mouse_y >= screen_y and gfx.mouse_y < screen_y + row_h_dynamic then
                    UI_STATE.mouse_handled = true -- Suppress global menu
                    
                    -- If right-clicked on non-selected row (marker or line), select it first
                    if not table_selection[original_idx] then
                        table_selection = {}
                        table_selection[original_idx] = true
                        last_selected_row = i
                    end
                    
                    -- Count selected
                    local sel_indices = {}
                    local marker_count = 0
                    local ass_count = 0
                    
                    for idx, _ in pairs(table_selection) do
                        if type(idx) == "number" then
                            table.insert(sel_indices, idx)
                            ass_count = ass_count + 1
                        elseif type(idx) == "string" and idx:sub(1,1) == "M" then
                            marker_count = marker_count + 1
                        end
                    end
                    table.sort(sel_indices)
                    
                    local menu_str = ""
                    
                    -- If only markers are selected
                    if ass_count == 0 and marker_count > 0 then
                        if marker_count == 1 then
                            menu_str = "Видалити правку"
                        else
                            menu_str = "Видалити правки"
                        end
                        
                        gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
                        local ret = gfx.showmenu(menu_str)
                        if ret == 1 then
                            delete_logic()
                        end

                    -- Mixed Selection (Markers + ASS lines)
                    elseif ass_count > 0 and marker_count > 0 then
                        menu_str = "Видалити вибрані репліки та правки"
                        
                        gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
                        local ret = gfx.showmenu(menu_str)
                        if ret == 1 then
                            delete_logic()
                        end

                    -- Only ASS lines selected
                    else
                        local sorted_actors = {}
                        for a in pairs(ass_actors) do
                            table.insert(sorted_actors, a)
                        end
                        table.sort(sorted_actors)
                        
                        local menu_items = { ">Змінити ім'я актора", "-  Нове ім'я -" }
                        for _, a in ipairs(sorted_actors) do
                            table.insert(menu_items, (a:gsub("|", "||")))
                        end
                        table.insert(menu_items, "<")
                        
                        local has_merge = #sel_indices > 1 and #sel_indices <= 5
                        if has_merge then
                            table.insert(menu_items, "Об'єднати репліки в одну")
                        end
                        
                        if #sel_indices == 1 then
                            table.insert(menu_items, "Продублювати репліку")
                            table.insert(menu_items, "|Видалити репліку")
                        else
                            table.insert(menu_items, "|Видалити вибрані репліки")
                        end
                        
                        local menu_str = table.concat(menu_items, "|")
                        
                        gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
                        local ret = gfx.showmenu(menu_str)
                        
                        local actor_count = #sorted_actors
                        local rename_end_idx = 1 + actor_count
                        
                        if ret >= 1 and ret <= rename_end_idx then
                            -- Change Actor Name
                            local selected_entries = {}
                            for p, l in ipairs(ass_lines) do
                                if table_selection[l.index or p] then
                                    table.insert(selected_entries, l)
                                end
                            end
                            
                            if #selected_entries > 0 then
                                local ok, new_actor
                                if ret == 1 then
                                    local first_actor = selected_entries[1].actor or ""
                                    ok, new_actor = reaper.GetUserInputs("Зміна імені актора", 1, "Нове ім'я:,extrawidth=200", first_actor)
                                else
                                    new_actor = sorted_actors[ret - 1]
                                    ok = true
                                end
                                
                                if ok and new_actor then
                                    -- Remove variation selector (U+FE0F = \239\184\143) and trim spaces
                                    new_actor = new_actor:gsub("\239\184\143", ""):match("^%s*(.-)%s*$")
                                    
                                    push_undo("Зміна імені актора")
                                    if ass_actors[new_actor] == nil then ass_actors[new_actor] = true end
                                    for _, l in ipairs(selected_entries) do
                                        l.actor = new_actor
                                    end
                                    cleanup_actors()
                                    rebuild_regions()
                                    show_snackbar("Ім'я актора змінено (" .. #selected_entries .. ")", "success")
                                end
                            end
                        elseif has_merge and ret == rename_end_idx + 1 then
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
                                    merged_text = (merged_text == "") and (l.text or "") or (merged_text .. "\n" .. (l.text or ""))
                                    if l.t1 < t1_min then t1_min = l.t1 end
                                    if l.t2 > t2_max then t2_max = l.t2 end
                                end
                                
                                ass_lines[base_pos].text = merged_text
                                ass_lines[base_pos].t1 = t1_min
                                ass_lines[base_pos].t2 = t2_max
                                
                                for i = #selected_entries, 2, -1 do
                                    table.remove(ass_lines, selected_entries[i].pos)
                                end
                                
                                table_selection = {}
                                table_selection[base_id] = true
                                cleanup_actors()
                                rebuild_regions()
                                table_data_cache.state_count = -1 -- FORCE UPDATE TABLE
                                last_layout_state.state_count = -1 -- FORCE UPDATE LAYOUT
                                show_snackbar("Репліки об'єднано (" .. #selected_entries .. ")", "success")
                            end
                        elseif (has_merge and ret == rename_end_idx + 2) or (not has_merge and ret == rename_end_idx + 1) then
                            -- Duplicate or Delete Selected Replicas
                            if #sel_indices == 1 and ret == rename_end_idx + 1 then
                                -- Duplicate Logic
                                duplicate_logic(sel_indices[1])
                            else
                                -- Delete Logic
                                delete_logic()
                            end
                        elseif (has_merge and ret == rename_end_idx + 3) or (not has_merge and ret == rename_end_idx + 2) then
                            -- Delete Selected Replicas (if it was offset by Duplicate)
                            delete_logic()
                        end
                    end -- End of selection type check
                end
            end
        ::continue::
    end
    
    -- Blit back to screen
    gfx.dest = prev_dest
    -- Blit table canvas to available area
    -- If Right Layout: blit to 0..avail_w
    gfx.blit(98, 1, 0, 0, 0, avail_w, avail_h, 0, content_y)
    
    gfx.setfont(F.std) -- RESTORE standard font for menus and bars
    
    -- Scrollbar
    UI_STATE.target_scroll_y = draw_scrollbar(gfx.w - 10, content_y, 10, avail_h, total_h, avail_h, UI_STATE.target_scroll_y)
    
    -- Draw Director Panel
    if cfg.director_mode then
        if is_dir_right then
            -- Right Layout (Align with filters: S(35))
            local dir_y = S(35)
            draw_director_panel(avail_w, dir_y, w_director, gfx.h - dir_y, input_queue, false)
        else
            -- Bottom Layout
            local draw_y = gfx.h - h_director
            
            -- Draw
            draw_director_panel(0, draw_y, gfx.w, h_director, input_queue, false)
            
            -- Recalculate height for NEXT frame to ensure smooth resizing
            local needed = draw_director_panel(0, draw_y, gfx.w, h_director, nil, true)
            if needed < S(100) then needed = S(100) end
            
            -- Auto-expand logic: If content needs more than current setting AND we are not resizing
            if not director_resize_drag and needed > h_director then
                cfg.h_director = needed
            end
            dynamic_director_h = needed -- Keep tracking for ref
        end
        
        -- RESIZE HANDLE LOGIC (Moved to end for Z-order)
        local resize_zone = S(8)
        local strip_sz = S(2)
        local grab_long = S(40)
        local grab_thick = S(12)
        local handle_x, handle_y, handle_w, handle_h
        local is_hover = false
        
        -- Helper: Check if mouse is strictly inside window
        if is_dir_right then
            local dir_y = S(35)
            local border_x = avail_w
            handle_w = grab_thick
            handle_h = grab_long
            handle_x = border_x - (handle_w / 2)
            handle_y = dir_y + (gfx.h - dir_y - handle_h) / 2
            
            -- Draw Separator
            is_hover = UI_STATE.inside_window and UI_STATE.window_focused and math.abs(gfx.mouse_x - border_x) <= resize_zone and (gfx.mouse_y >= dir_y)
            set_color(is_hover and UI.C_HILI_WHITE_MID or UI.C_HILI_WHITE)
            gfx.rect(border_x, dir_y, strip_sz, gfx.h - dir_y, 1)

            -- Logic
            if is_hover or director_resize_drag then
                reaper.SetCursorContext(2, 0)
                if is_hover and gfx.mouse_cap == 1 and not OTHER.col_resize.dragging then
                    director_resize_drag = true
                    OTHER.col_resize.key = nil
                end
            end
            
            if director_resize_drag and gfx.mouse_cap == 1 then
                local new_w = gfx.w - gfx.mouse_x
                if new_w < S(250) then new_w = S(250) end
                if new_w > gfx.w - S(150) then new_w = gfx.w - S(150) end
                cfg.w_director = new_w
            elseif director_resize_drag then
                director_resize_drag = false
                save_settings()
                reaper.SetCursorContext(0, 0)
            end
        else
            -- Bottom
            local border_y = gfx.h - h_director
            handle_w = grab_long
            handle_h = grab_thick
            handle_x = (gfx.w - handle_w) / 2
            handle_y = border_y - (handle_h / 2)

            is_hover = UI_STATE.inside_window and UI_STATE.window_focused and math.abs(gfx.mouse_y - border_y) <= resize_zone
            set_color(is_hover and UI.C_HILI_WHITE_MID or UI.C_HILI_WHITE)
            gfx.rect(0, border_y, gfx.w, strip_sz, 1)

            if is_hover or director_resize_drag then
                reaper.SetCursorContext(1, 0)
                if is_hover and gfx.mouse_cap == 1 and not OTHER.col_resize.dragging then
                    director_resize_drag = true
                end
            end
            
            if director_resize_drag and gfx.mouse_cap == 1 then
                local new_h = gfx.h - gfx.mouse_y
                if new_h < S(120) then new_h = S(120) end
                local max_h = gfx.h - S(150)
                if new_h > max_h then new_h = max_h end
                cfg.h_director = new_h
            elseif director_resize_drag then
                director_resize_drag = false
                save_settings()
                reaper.SetCursorContext(0, 0)
            end
        end

        -- Draw Handle Pill (Only on hover or drag)
        if is_hover or director_resize_drag then
            set_color(UI.C_WHITE, 0.8)
            gfx.rect(handle_x, handle_y, handle_w, handle_h, 1)
            set_color(UI.C_BLACK_OVERLAY)
            gfx.rect(handle_x, handle_y, handle_w, handle_h, 0)
        end
    end

    -- Draw Header LAST (always on top)
    if not cfg.reader_mode then
        set_color(UI.C_SNACK_INFO)
        gfx.rect(0, start_y, avail_w, h_header, 1)
    end
    
    local function draw_header_cell(idx, label, x, y, col_name)
        -- Clamp next_x to avail_w to prevent overlap with Director Panel
        local next_start = x_off[idx + 1] or avail_w
        local next_x = math.min(next_start, avail_w)
        local cell_w = next_x - x
        local arrow_w = S(12)
        local text_padding = S(5)
        local resize_key = col_keys[idx]
        
        -- Header cells should only draw if they have space
        if cell_w <= 0 then return end

        -- Use (locally scaled) F.bld for headers
        gfx.setfont(F.bld)
        
        local max_text_w = cell_w - text_padding
        if table_sort.col == col_name then max_text_w = max_text_w - arrow_w end
        
        local display_label = label
        if not cfg.reader_mode then
            display_label = fit_text_width(label, max_text_w)
        end
        
        -- Hover & Click detection
        local is_hover = false
        local is_resize_hover = false
        
        if UI_STATE.window_focused and gfx.mouse_y >= y and gfx.mouse_y < y + h_header then
            if gfx.mouse_x >= x and gfx.mouse_x < next_x then
                is_hover = true
            end
            
            -- Detect resize handle (right edge)
            if resize_key and math.abs(gfx.mouse_x - next_x) < S(5) then
                is_resize_hover = true
                is_hover = false -- Prioritize resize
            end
        end

        -- Handle Resizing
        if OTHER.col_resize.dragging and OTHER.col_resize.key == resize_key then
            local delta = gfx.mouse_x - OTHER.col_resize.start_x
            local new_w = OTHER.col_resize.start_w + delta
            if new_w < S(25) then new_w = S(25) end -- Minimum width (S(25) like 1st col)
            
            -- Store unscaled
            cfg[resize_key] = math.floor(new_w / cfg.gui_scale)
            
            -- Force refresh next frame? (implicit via loop)
        elseif is_resize_hover and is_mouse_clicked() then
            OTHER.col_resize.dragging = true
            OTHER.col_resize.key = resize_key
            OTHER.col_resize.start_x = gfx.mouse_x
            OTHER.col_resize.start_w = cell_w
        end
        
        -- Stop dragging
        if OTHER.col_resize.dragging and gfx.mouse_cap & 1 == 0 then
            OTHER.col_resize.dragging = false
            OTHER.col_resize.key = nil
            save_settings()
        end

        if is_hover then
            if not mouse_in_menu and not OTHER.col_resize.dragging then -- Checks if custom menus are open
                set_color(UI.C_HILI_HEADER)
                gfx.rect(x, y, cell_w, h_header, 1)
                
                if is_mouse_clicked() then
                    if table_sort.col == col_name then
                        table_sort.dir = table_sort.dir * -1
                    else
                        table_sort.col = col_name
                        table_sort.dir = 1
                    end
                end
            end
        end
        
        -- Draw resize handle highlight
        if is_resize_hover or (OTHER.col_resize.dragging and OTHER.col_resize.key == resize_key) then
            set_color(UI.C_RESIZE_HDL)
            gfx.rect(next_x - S(2), y, S(4), h_header, 1)
        end

        set_color(UI.C_TXT)
        gfx.x = x + text_padding; 
        gfx.y = y + (h_header - gfx.texth) / 2; 
        
        if cfg.reader_mode then
            gfx.drawstr(display_label, 4, x + max_text_w, y + h_header)
        else
            gfx.drawstr(display_label)
        end
        local dspt_w, dspt_h = gfx.measurestr(display_label)
        
        -- Draw vector arrow if sorted
        if table_sort.col == col_name then
            local ax = x + dspt_w + text_padding + S(2)
            local ay = y + (h_header - S(10)) / 2 -- Center arrow
            set_color(UI.C_TXT)
            if table_sort.dir == 1 then
                -- Up arrow
                gfx.line(ax + S(2), ay + S(6), ax + S(5), ay + S(2))
                gfx.line(ax + S(5), ay + S(2), ax + S(8), ay + S(6))
                gfx.line(ax + S(3), ay + S(6), ax + S(7), ay + S(6))
            else
                -- Down arrow
                gfx.line(ax + S(2), ay + S(2), ax + S(5), ay + S(6))
                gfx.line(ax + S(5), ay + S(6), ax + S(8), ay + S(2))
                gfx.line(ax + S(3), ay + S(2), ax + S(7), ay + S(2))
            end
        end
    end

    local col_ptr = 1
    if not cfg.reader_mode then
        draw_header_cell(col_ptr, "Ак.", x_off[col_ptr], start_y, "enabled"); col_ptr = col_ptr + 1
        if cfg.col_table_index then draw_header_cell(col_ptr, "#", x_off[col_ptr], start_y, "index"); col_ptr = col_ptr + 1 end
        if cfg.col_table_start then draw_header_cell(col_ptr, "Початок", x_off[col_ptr], start_y, "start"); col_ptr = col_ptr + 1 end
        if cfg.col_table_end then draw_header_cell(col_ptr, "Кінець", x_off[col_ptr], start_y, "end"); col_ptr = col_ptr + 1 end
        if cfg.col_table_cps then draw_header_cell(col_ptr, "CPS", x_off[col_ptr], start_y, "cps"); col_ptr = col_ptr + 1 end
        if cfg.col_table_actor then draw_header_cell(col_ptr, "Актор", x_off[col_ptr], start_y, "actor"); col_ptr = col_ptr + 1 end
        draw_header_cell(col_ptr, "Репліка", x_off[col_ptr], start_y, "text")
    end

    -- --- COLUMN VISIBILITY FLOATING MENU ---
    if col_vis_menu.show then
        local m_w = S(180)
        local m_x, m_y = col_vis_menu.x, col_vis_menu.y
        local item_h = S(24)
        local items = {
            {label = "#", key = "col_table_index"},
            {label = "Початок", key = "col_table_start"},
            {label = "Кінець", key = "col_table_end"},
            {label = "CPS", key = "col_table_cps"},
            {label = "Актор", key = "col_table_actor"}
        }
        local m_h = #items * item_h + S(10)
        
        -- Background with shadow
        set_color(UI.C_SHADOW); gfx.rect(m_x+S(2), m_y+S(2), m_w, m_h, 1) -- Shadow
        set_color(UI.C_BG); gfx.rect(m_x, m_y, m_w, m_h, 1)
        set_color(UI.C_BTN_H); gfx.rect(m_x, m_y, m_w, m_h, 0)
        
        for idx, item in ipairs(items) do
            if item.separator then
                set_color(UI.C_HILI_GREY_LOW)
                gfx.line(m_x + S(5), m_y + S(5) + (idx-1) * item_h + item_h/2, m_x + m_w - S(5), m_y + S(5) + (idx-1) * item_h + item_h/2)
            else
                local iy = m_y + S(5) + (idx-1) * item_h
                local hover = UI_STATE.window_focused and (gfx.mouse_x >= m_x and gfx.mouse_x <= m_x + m_w and gfx.mouse_y >= iy and gfx.mouse_y < iy + item_h)
                
                if hover then
                    set_color(UI.C_HILI_WHITE)
                    gfx.rect(m_x, iy, m_w, item_h, 1)
                end
                
                -- Checkbox
                local chk_sz = S(14)
                local chk_x = m_x + S(8)
                local chk_y = iy + (item_h - chk_sz)/2
                set_color(UI.C_ED_GUTTER)
                gfx.rect(chk_x, chk_y, chk_sz, chk_sz, 0)
                
                if cfg[item.key] then
                    set_color(UI.C_TXT)
                    if item.key == "reader_mode" then
                        gfx.circle(chk_x + chk_sz/2, chk_y + chk_sz/2, S(4), 1) -- Bullet point
                    else
                        gfx.line(chk_x+S(3), chk_y+S(7), chk_x+S(6), chk_y+S(10))
                        gfx.line(chk_x+S(6), chk_y+S(10), chk_x+S(11), chk_y+S(3))
                    end
                end
                
                set_color(UI.C_TXT)
                gfx.x = m_x + S(30)
                gfx.y = iy + (item_h - gfx.texth) / 2
                local label = item.label
                if cfg[item.key] and item.key == "reader_mode" then label = "• " .. label end
                gfx.drawstr(label)
                
                if hover and is_mouse_clicked() then
                    col_vis_menu.handled = true
                    if item.action then
                        item.action()
                        update_prompter_fonts()
                    else
                        cfg[item.key] = not cfg[item.key]
                        save_settings()
                        update_prompter_fonts()
                        
                        -- Fallback sorting to # if hidden
                        if not cfg[item.key] and tostring(table_sort.col) == tostring(item.label) then
                            table_sort.col = "#"
                            table_sort.dir = 1
                        end
                    end
                end
            end
        end
        
        -- Close if clicked outside
        if is_mouse_clicked() and not (gfx.mouse_x >= m_x and gfx.mouse_x <= m_x + m_w and gfx.mouse_y >= m_y and gfx.mouse_y <= m_y + m_h) then
             -- BUT check if it was the menu button itself (to avoid immediate close-reopen)
             if not (gfx.mouse_x >= btn_x and gfx.mouse_x <= btn_x + opt_btn_w and 
                     gfx.mouse_y >= filter_y and gfx.mouse_y <= filter_y + filter_h) then
                 col_vis_menu.show = false
             end
        end
    end

    -- --- TIME SHIFT FLOATING MENU ---
    if time_shift_menu.show then
        local m_w = S(280)
        local m_x, m_y = time_shift_menu.x, time_shift_menu.y
        local m_h = S(125)
        
        -- Background with shadow
        set_color(UI.C_SHADOW); gfx.rect(m_x+S(2), m_y+S(2), m_w, m_h, 1) -- Shadow
        set_color(UI.C_BG); gfx.rect(m_x, m_y, m_w, m_h, 1)
        set_color(UI.C_BTN_H); gfx.rect(m_x, m_y, m_w, m_h, 0)
        
        -- Header/Checkbox Row
        local iy = m_y + S(10)
        local chk_sz = S(14)
        local chk_x = m_x + S(10)
        local hover_chk = UI_STATE.window_focused and (gfx.mouse_x >= m_x and gfx.mouse_x <= m_x + m_w and gfx.mouse_y >= iy and gfx.mouse_y < iy + S(24))
        
        if hover_chk then
            set_color(UI.C_HILI_WHITE_LOW)
            gfx.rect(m_x, iy-S(4), m_w, S(24), 1)
        end
        
        set_color(UI.C_ED_GUTTER)
        gfx.rect(chk_x, iy + S(4), chk_sz, chk_sz, 0)
        if time_shift_menu.only_selected then
            set_color(UI.C_TXT)
            gfx.line(chk_x+S(3), iy+S(11), chk_x+S(6), iy+S(14))
            gfx.line(chk_x+S(6), iy+S(14), chk_x+S(11), iy+S(7))
        end
        
        set_color(UI.C_TXT)
        gfx.x, gfx.y = chk_x + chk_sz + S(8), iy + S(4)
        gfx.drawstr("Лише для вибраних")
        
        if hover_chk and is_mouse_clicked() then
            time_shift_menu.only_selected = not time_shift_menu.only_selected
        end
        
        -- Buttons Grid (2 Rows)
        local btn_w = (m_w - S(20) - S(5)*4) / 6
        local btn_h = S(24)
        local neg_offsets = {-5, -2, -1, -0.5, -0.25, -0.1}
        local pos_offsets = {5, 2, 1, 0.5, 0.25, 0.1}
        
        local function draw_row(offsets, start_y)
            for i, off in ipairs(offsets) do
                local bx = m_x + S(10) + (i-1) * (btn_w + S(4))
                local by = start_y
                
                local label = (off > 0 and "+" or "") .. off .. "s"
                if math.abs(off) < 1 then
                    label = (off < 0 and "-" or "+") .. tostring(math.abs(off)):gsub("^0", "") .. "s"
                end
                
                if draw_btn_inline(bx, by, btn_w, btn_h, label, UI.C_BTN) then
                    push_undo("Здвиг часу (" .. off .. "s)")
                    local affected = 0
                    for _, line in ipairs(ass_lines) do
                        if not time_shift_menu.only_selected or table_selection[line.index or 0] then
                            line.t1 = line.t1 + off
                            line.t2 = line.t2 + off
                            affected = affected + 1
                        end
                    end
                    rebuild_regions()
                    show_snackbar("Здвинуто на " .. label .. " (" .. affected .. ")", "success")
                end
            end
        end

        draw_row(neg_offsets, m_y + S(42))
        
        -- Separator
        set_color(UI.C_HILI_WHITE)
        gfx.line(m_x + S(10), m_y + S(76), m_x + m_w - S(10), m_y + S(76))
        
        draw_row(pos_offsets, m_y + S(90))
        
        -- Close if clicked outside
        if is_mouse_clicked() and not (gfx.mouse_x >= m_x and gfx.mouse_x <= m_x + m_w and gfx.mouse_y >= m_y and gfx.mouse_y <= m_y + m_h) then
             if not (gfx.mouse_x >= btn_x and gfx.mouse_x <= btn_x + opt_btn_w and 
                     gfx.mouse_y >= filter_y and gfx.mouse_y <= filter_y + filter_h) then
                 time_shift_menu.show = false
             end
        end
    end

    -- --- FINAL FONT RESET ---
    -- Ensure F.std and F.bld are returned to standard 14px size for other UI elements (Tabs etc.)
    gfx.setfont(F.std, "Arial", S(14))
    gfx.setfont(F.bld, "Arial", S(14), string.byte('b'))
end

-- --- Main Loop ---
reaper.gmem_attach("SubassSync")

local function focus_plugin_window()
    if reaper.JS_Window_Find then
        -- Non-exact match (false) is more robust
        local hwnd = reaper.JS_Window_Find(GL.script_title, false)
        if hwnd then
            reaper.JS_Window_SetForeground(hwnd) -- Grab OS focus
            reaper.JS_Window_SetFocus(hwnd) -- Set internal focus
        end
    end
end

local function handle_remote_commands()
    local cmd_id = reaper.gmem_read(0)
    if cmd_id == 0 then return end
    
    -- Clear command immediately
    reaper.gmem_write(0, 0)
    
    if cmd_id == 1 then -- EDIT
        local play_state = reaper.GetPlayState()
        local pos = (play_state & 1) == 1 and reaper.GetPlayPosition() or reaper.GetCursorPosition()
        update_regions_cache()
        
        for _, r in ipairs(regions) do
            if pos >= r.pos and pos < r.rgnend then
                for i, line in ipairs(ass_lines) do
                    if math.abs(line.t1 - r.pos) < 0.01 and math.abs(line.t2 - r.rgnend) < 0.01 then
                        focus_plugin_window()
                        open_text_editor(line.text, function(new_text)
                            push_undo("Редагування тексту (Remote)")
                            line.text = new_text
                            rebuild_regions()
                        end, i, ass_lines)
                        return
                    end
                end
            end
        end
    elseif cmd_id == 3 then -- EDIT_NEXT
        local play_state = reaper.GetPlayState()
        local pos = (play_state & 1) == 1 and reaper.GetPlayPosition() or reaper.GetCursorPosition()
        update_regions_cache()
        
        local current_rgn_idx = nil
        -- Find current region index
        for idx, r in ipairs(regions) do
            if pos >= r.pos and pos < r.rgnend then
                current_rgn_idx = idx
                break
            end
        end
        
        -- If current found, try to get next
        if current_rgn_idx and regions[current_rgn_idx + 1] then
            local next_rgn = regions[current_rgn_idx + 1]
             for i, line in ipairs(ass_lines) do
                if math.abs(line.t1 - next_rgn.pos) < 0.01 and math.abs(line.t2 - next_rgn.rgnend) < 0.01 then
                    focus_plugin_window()
                    open_text_editor(line.text, function(new_text)
                        push_undo("Редагування тексту (Remote Next)")
                        line.text = new_text
                        rebuild_regions()
                    end, i, ass_lines)
                    return
                end
            end
        end
    elseif cmd_id == 2 then -- DICT
        local word = reaper.GetExtState("SubassSync", "WORD")
        if word ~= "" then
            trigger_dictionary_lookup(word)
        end
    elseif cmd_id == 4 then -- EDIT_SPECIFIC (with exact times)
        local t1 = reaper.gmem_read(1)
        local t2 = reaper.gmem_read(2)
        local target_id = reaper.gmem_read(3)
        local is_marker_cmd = reaper.gmem_read(4) == 1
        
        -- NEW: Prioritize Marker lookup if it's explicitly a marker or smells like one
        local looks_like_marker = is_marker_cmd or (math.abs(t1 - t2) < 0.001)
        
        if looks_like_marker then
            local m_count = reaper.CountProjectMarkers(0)
            local found_match = false
            for i = 0, m_count - 1 do
                local retval, isrgn, m_pos, _, m_name, markindex = reaper.EnumProjectMarkers3(0, i)
                local matches = false
                if not isrgn then
                    if target_id and target_id ~= -1 then
                        matches = (markindex == target_id)
                    else
                        matches = (math.abs(m_pos - t1) < 0.005) -- Slightly higher tolerance for rounded T1
                    end
                end

                if matches then
                    found_match = true
                    focus_plugin_window()
                    open_text_editor(m_name, function(new_text)
                        push_undo("Редагування правки (Remote Overlay)")
                        -- Знаходимо індекс знову (бо він міг змінитись)
                        local find_idx = -1
                        for j = 0, reaper.CountProjectMarkers(0) - 1 do
                            local _, cur_isrgn, _, _, _, cur_idx = reaper.EnumProjectMarkers3(0, j)
                            if not cur_isrgn and cur_idx == markindex then find_idx = j break end
                        end
                        
                        if find_idx ~= -1 then
                            local _, _, _, _, _, _, m_col = reaper.EnumProjectMarkers3(0, find_idx)
                            reaper.SetProjectMarkerByIndex(0, find_idx, false, m_pos, 0, markindex, new_text, m_col)
                        else
                            -- Fallback за позицією
                            reaper.SetProjectMarker(markindex, false, m_pos, 0, new_text)
                        end
                        
                        -- ПОВНЕ ОНОВЛЕННЯ ВСІХ КЕШІВ
                        ass_markers = capture_project_markers()
                        update_regions_cache()
                        table_data_cache.state_count = -1
                        last_layout_state.state_count = -1
                        prompter_drawer.marker_cache.count = -1
                        prompter_drawer.filtered_cache.state_count = -1
                        
                        rebuild_regions() -- Оновлення решти
                    end, nil, nil, true)
                    return
                end
            end
            if not found_match then
                show_snackbar(string.format("Marker with ID %d not found at %.3f", target_id, t1), "error")
            end
        end

        -- 1. Спроба знайти збіг серед реплік (ass_lines)
        -- Prioritize target_id matching ONLY IF NOT A MARKER to avoid collisions
        if not looks_like_marker and target_id and target_id ~= -1 then
            for i, line in ipairs(ass_lines) do
                if line.rgn_idx == target_id then
                    focus_plugin_window()
                    open_text_editor(line.text, function(new_text)
                        push_undo("Редагування тексту (Remote Specific)")
                        line.text = new_text
                        rebuild_regions()
                    end, i, ass_lines)
                    return
                end
            end
        end
        
        -- Fallback to time-based matching (safe because t1==t2 vs t1<t2)
        for i, line in ipairs(ass_lines) do
            if not looks_like_marker and math.abs(line.t1 - t1) < 0.01 and math.abs(line.t2 - t2) < 0.01 then
                focus_plugin_window()
                open_text_editor(line.text, function(new_text)
                    push_undo("Редагування тексту (Remote Specific)")
                    line.text = new_text
                    rebuild_regions()
                end, i, ass_lines)
                return
            end
        end

        -- 2. Якщо не знайдено серед реплік — шукаємо серед маркерів (якщо не знайшли раніше)
        if not looks_like_marker then
            local m_count = reaper.CountProjectMarkers(0)
            for i = 0, m_count - 1 do
                local retval, isrgn, m_pos, _, m_name, markindex = reaper.EnumProjectMarkers3(0, i)
                
                local matches = false
                if target_id and target_id ~= -1 then
                    matches = (not isrgn and markindex == target_id)
                else
                    matches = (not isrgn and math.abs(m_pos - t1) < 0.001)
                end

                if matches then
                    focus_plugin_window()
                    open_text_editor(m_name, function(new_text)
                        push_undo("Редагування правки (Remote Overlay)")
                        -- Знаходимо індекс знову (бо він міг змінитись)
                        local find_idx = -1
                        for j = 0, reaper.CountProjectMarkers(0) - 1 do
                            local _, _, cur_pos, _, _, cur_idx = reaper.EnumProjectMarkers3(0, j)
                            if cur_idx == markindex then find_idx = j break end
                        end
                        
                        if find_idx ~= -1 then
                            local _, _, _, _, _, _, m_col = reaper.EnumProjectMarkers3(0, find_idx)
                            reaper.SetProjectMarkerByIndex(0, find_idx, false, m_pos, 0, markindex, new_text, m_col)
                        else
                            -- Fallback за позицією
                            reaper.SetProjectMarker(markindex, false, m_pos, 0, new_text)
                        end
                        
                        -- ПОВНЕ ОНОВЛЕННЯ ВСІХ КЕШІВ
                        ass_markers = capture_project_markers()
                        update_regions_cache()
                        table_data_cache.state_count = -1
                        last_layout_state.state_count = -1
                        prompter_drawer.marker_cache.count = -1
                        prompter_drawer.filtered_cache.state_count = -1
                        
                        rebuild_regions() -- Оновлення решти
                    end, nil, nil, true)
                    return
                end
            end
        end
    end
end

--- Automatically trim start/end and check for clipping of newly recorded items
local function process_post_recording()
    local play_state = reaper.GetPlayState()
    local is_recording = (play_state & 4) == 4
    
    -- Track duration sessions
    if not UI_STATE.last_is_recording and is_recording then
        -- Recording just started
        local proj = STATS.get_project()
        if proj then
            local now = os.time()
            if #proj.duration == 0 or (now - proj.duration[#proj.duration]["end"] > 600) then
                -- New session (more than 10 mins gap or first session)
                table.insert(proj.duration, { start = now, ["end"] = now })
            else
                -- Continue existing session (update end to start time of recording)
                proj.duration[#proj.duration]["end"] = now
            end
            STATS.dirty = true
        end
    elseif UI_STATE.last_is_recording and not is_recording then
        -- Recording just stopped
        local proj = STATS.get_project()
        if proj and #proj.duration > 0 then
            proj.duration[#proj.duration]["end"] = os.time()
            STATS.dirty = true
            STATS.save()
        end
        
        -- Recording just stopped (Existing items processing)
        local item_count = reaper.CountSelectedMediaItems(0)
        if item_count > 0 then
            
            -- Track statistics: count recorded items and get actor names
            local recorded_actors = {}
            for i = 0, item_count - 1 do
                local item = reaper.GetSelectedMediaItem(0, i)
                if item then
                    -- Find actor by matching item position to ass_lines
                    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
                    local item_end = item_pos + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
                    
                    local found_actor = false
                    if ass_lines then
                        for _, line in ipairs(ass_lines) do
                            -- Check if item overlaps line time range
                            if line.enabled ~= false and line.t1 and line.t2 then
                                -- Simple check: does the item start near this line?
                                -- Giving 0.5s tolerance
                                if item_pos >= (line.t1 - 0.5) and item_pos < (line.t2 + 0.5) then
                                    if line.actor and line.actor ~= "" then
                                        recorded_actors[line.actor] = (recorded_actors[line.actor] or 0) + 1
                                        found_actor = true
                                        break -- Count once per item
                                    end
                                end
                            end
                        end
                    end
                    
                    -- If no actor found, count as "outside" recording
                    if not found_actor then
                        recorded_actors["_OUTSIDE_"] = (recorded_actors["_OUTSIDE_"] or 0) + 1
                    end
                end
            end
            
            -- Increment stats for each actor
            for actor, count in pairs(recorded_actors) do
                for _ = 1, count do
                    if actor == "_OUTSIDE_" then
                        STATS.increment_outside()
                    else
                        STATS.increment_recorded(actor)
                    end
                end
            end
            
            -- Save stats immediately after recording
            STATS.save()
            
            -- Only proceed with trim/clipping if enabled
            if not cfg.auto_trim and not cfg.check_clipping then
                UI_STATE.last_is_recording = is_recording
                return
            end
            
            -- 1. Auto Trim
            if cfg.auto_trim then
                reaper.Undo_BeginBlock()
                local trimmed_count = 0
                for i = 0, item_count - 1 do
                    local item = reaper.GetSelectedMediaItem(0, i)
                    if item then
                        local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
                        local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
                        
                        local trim_start_sec = cfg.trim_start / 1000
                        local trim_end_sec = cfg.trim_end / 1000
                        
                        if item_len > (trim_start_sec + trim_end_sec) then
                            -- Trim start
                            local take = reaper.GetActiveTake(item)
                            if take then
                                -- Adjust source offset to keep content aligned
                                local offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
                                reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", offset + trim_start_sec)
                            end
                            reaper.SetMediaItemInfo_Value(item, "D_POSITION", item_pos + trim_start_sec)
                            -- Adjust length (minus both start and end trims)
                            reaper.SetMediaItemInfo_Value(item, "D_LENGTH", item_len - trim_start_sec - trim_end_sec)
                            trimmed_count = trimmed_count + 1
                        end
                    end
                end
                
                if trimmed_count > 0 then
                    reaper.UpdateArrange()
                    reaper.Undo_EndBlock("Авто-підрізання запису", -1)
                    show_snackbar("Запис підрізано (" .. trimmed_count .. " шт.)", "info")
                else
                    reaper.Undo_EndBlock("Авто-підрізання запису", -1)
                end
            end

            -- 2. Clipping Check
            if cfg.check_clipping then
                local clipped_count = 0
                local max_peak_warning = 0.85
                -- Small defer to let audio buffer/files finalize? usually fine immediately after stop
                for i = 0, item_count - 1 do
                    local item = reaper.GetSelectedMediaItem(0, i)
                    if item then
                        local take = reaper.GetActiveTake(item)
                        if take and not reaper.TakeIsMIDI(take) then
                            local accessor = reaper.CreateTakeAudioAccessor(take)
                            local src = reaper.GetMediaItemTake_Source(take)
                            local start_offs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
                            local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
                            
                            -- Get source properties
                            local samplerate = 44100
                            if src then samplerate = reaper.GetMediaSourceSampleRate(src) end
                             if samplerate == 0 then samplerate = 44100 end -- Safety

                            local channels = reaper.GetMediaItemTakeInfo_Value(take, "I_CHANMODE")
                            if channels <= 0 then 
                                if src then channels = reaper.GetMediaSourceNumChannels(src) else channels = 1 end
                            end
                            if channels < 1 then channels = 1 end
                            
                            -- Volume Compensation logic
                            local item_vol = reaper.GetMediaItemInfo_Value(item, "D_VOL")
                            local take_vol = reaper.GetMediaItemTakeInfo_Value(take, "D_VOL")
                            local total_gain = item_vol * take_vol
                            
                            local block_size = 4096 -- Smaller chunks for UI responsiveness
                            local buffer = reaper.new_array(block_size * channels)
                            local max_peak = 0
                            
                            local pos = 0
                            while pos < len do
                                local chunk_len = math.min(len - pos, block_size / samplerate)
                                local retval = reaper.GetAudioAccessorSamples(accessor, samplerate, channels, start_offs + pos, math.ceil(chunk_len * samplerate), buffer)
                                
                                if retval > 0 then
                                    local size = retval * channels
                                    for j = 1, size do
                                        -- Compensate for gain
                                        local val = math.abs(buffer[j]) / total_gain
                                        
                                        if val > max_peak then max_peak = val end
                                        
                                        -- Optimization: If we found a peak that triggers RED, we can stop early 
                                        -- unless we wanted to count HOW MANY samples clipped (not needed now)
                                        if max_peak >= 0.99 then 
                                            break -- Exit inner loop
                                        end
                                    end
                                end
                                
                                if max_peak >= 0.99 then break end -- Exit outer loop
                                
                                pos = pos + chunk_len
                            end
                            
                            reaper.DestroyAudioAccessor(accessor)
                            
                            if max_peak >= max_peak_warning then
                                local r, g, b
                                
                                if max_peak >= 0.99 then
                                    -- Pure RED
                                    r, g, b = 255, 0, 0
                                    clipped_count = clipped_count + 1
                                else
                                    -- Gradient from Yellow (255,255,0) at max_peak_warning to Red (255,0,0) at 0.99
                                    local t = (max_peak - max_peak_warning) / (0.99 - max_peak_warning) -- 0.0 at max_peak_warning, 1.0 at 0.99
                                    r = 255
                                    g = math.floor(255 * (1 - t)) -- 255 at max_peak_warning, 0 at 0.99
                                    b = 0
                                end
                                
                                reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", reaper.ColorToNative(r, g, b)|0x1000000)
                            end
                        end
                    end
                end

                if clipped_count > 0 then
                    reaper.UpdateArrange()
                    show_snackbar("⚠️ УВАГА: ЗАПИС КЛІПУЄ! (" .. clipped_count .. " шт.)", "error")
                end
            end
        end
    end
    UI_STATE.last_is_recording = is_recording
end

local function main()
    if UI_STATE.is_restarting then return end
    
    -- Initial project state load (if first run)
    if UI_STATE.last_project_id == "" then
        local proj, filename = reaper.EnumProjects(-1)
        local id_fname = (not filename or filename == "") and "unsaved" or filename
        UI_STATE.last_project_id = proj and (tostring(proj) .. "_" .. id_fname) or "none"
        DEADLINE.project_deadline = DEADLINE.get()
        DUBBERS.load() -- Load dubber data for initial project
        DUBBERS.last_project_id = UI_STATE.last_project_id
    end
    
    -- Heartbeat for Lionzz
    reaper.gmem_write(100, reaper.time_precise())
    handle_remote_commands()
    
    -- Save statistics every 1 minute
    local now = reaper.time_precise()
    if now - STATS.last_save_time > 60 then -- 1 minute
        STATS.save()
    end

    -- Persistently nudge focus if requested (to overcome OS race conditions)
    if text_editor_state.needs_focus_nudge and text_editor_state.needs_focus_nudge > 0 then
        focus_plugin_window()
        text_editor_state.needs_focus_nudge = text_editor_state.needs_focus_nudge - 1
    end

    UI_STATE.tooltip_state.text = ""
    UI_STATE.tooltip_state.immediate = false
    UI_STATE.mouse_handled = false
    -- Check if project changed (tab switch)
    local proj, filename = reaper.EnumProjects(-1)
    local id_fname = (not filename or filename == "") and "unsaved" or filename
    local current_project_id = proj and (tostring(proj) .. "_" .. id_fname) or "none"
    if current_project_id ~= UI_STATE.last_project_id then
        save_session_state(UI_STATE.last_project_id)
        UI_STATE.last_project_id = current_project_id
        
        -- Reset and load
        load_project_data()
        load_session_state(current_project_id)
        DEADLINE.sync_project() -- Synchronize local state with global registry
        DEADLINE.project_deadline = DEADLINE.get()
        DUBBERS.load() -- Reload dubber data for this project
        DUBBERS.last_project_id = current_project_id
        
        -- Immediate cache update after loading
        update_regions_cache()
        proj_change_count = reaper.GetProjectStateChangeCount(0)
    end
    
    local curs_state = reaper.GetProjectStateChangeCount(0)
    if curs_state ~= proj_change_count then
        update_regions_cache()
        load_director_actors_from_state()
        proj_change_count = curs_state
    end

    -- --- WINDOW FOCUS & INTERACTION DETECTION ---
    UI_STATE.inside_window = (gfx.mouse_x >= 0 and gfx.mouse_x < gfx.w and 
                              gfx.mouse_y >= 0 and gfx.mouse_y < gfx.h)
    
    local has_focus = UI_STATE.inside_window

    -- If JS_API is available, we can check if REAPER or our window is actually in foreground
    if reaper.JS_Window_GetForeground then
        local fg_hwnd = reaper.JS_Window_GetForeground()
        local my_hwnd = reaper.JS_Window_Find(GL.script_title, true)
        local main_hwnd = reaper.GetMainHwnd()
        
        if fg_hwnd then
            -- We are focused if foreground is our window OR the main REAPER window
            if fg_hwnd ~= my_hwnd and fg_hwnd ~= main_hwnd then
                -- One extra check: is it another REAPER window (like MIDI editor)?
                local title = reaper.JS_Window_GetTitle(fg_hwnd) or ""
                if not title:match("REAPER") and not title:match(GL.script_title) then
                    has_focus = false
                end
            end
        else
            has_focus = false
        end
    end
    UI_STATE.window_focused = has_focus

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
    if not text_editor_state.active then
        for _, c in ipairs(input_queue) do
            if c == 26 then -- Ctrl+Z / Cmd+Z
                if not is_any_text_input_focused() then
                    if gfx.mouse_cap & 8 ~= 0 then -- Shift is held
                        redo_action()
                    else
                        undo_action()
                    end
                end
            elseif not dict_modal.show and not text_editor_state.active then
                -- Global Pass-Through Shortcuts (Standard Defaults)
                -- Dynamic lookup of user shortcuts is not supported by API
                local global_cmds = {
                    [32] = 40044, -- Space: Play/Stop
                    [19] = 40026, -- Ctrl+S: Save Project
                    [18] = 1013   -- Ctrl+R: Record
                }
                
                if global_cmds[c] then
                    if not is_any_text_input_focused() then
                        reaper.Main_OnCommand(global_cmds[c], 0)
                        return_focus_to_reaper(true)
                    end
                end
            end
        end
    end

    set_color(UI.C_BG)
    gfx.rect(0, 0, gfx.w, gfx.h, 1)
    
    -- Main Drawing Logic
    if DEADLINE.modal.show then 
        DEADLINE.draw_picker(input_queue)
    elseif DUBBERS.show_dashboard then
        DUBBERS.draw_dashboard(input_queue)
    elseif DEADLINE.dashboard_show then
        DEADLINE.draw_dashboard(input_queue)
    elseif SEARCH_ITEM.show then
        if SEARCH_ITEM.draw_window then SEARCH_ITEM.draw_window(input_queue) end
    elseif dict_modal.show then
        draw_dictionary_modal(input_queue)
    elseif text_editor_state.active then
        draw_text_editor(input_queue)
    else
        if UI_STATE.current_tab == 1 then 
            if UI_STATE.inside_window then handle_drag_drop() end
            draw_file()
        elseif UI_STATE.current_tab == 2 then draw_table(input_queue)
        elseif UI_STATE.current_tab == 3 then draw_prompter(input_queue) 
        elseif UI_STATE.current_tab == 4 then draw_settings() end
        
        -- Draw Tabs LAST (Z-Index top)
        draw_tabs()
        
        -- Context Menu logic (Right-click on tab bar / empty space)
        -- Must strictly check UI_STATE.mouse_handled AND window bounds to avoid global capture.
        if UI_STATE.inside_window and gfx.mouse_cap == 2 and UI_STATE.last_mouse_cap == 0 and not UI_STATE.mouse_handled then
            gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
            local dock_state = gfx.dock(-1)
            local check = (dock_state > 0) and "!" or ""
            local ret = gfx.showmenu(check .. "Закріпити вікно (Dock)")
            if ret == 1 then
                local target_dock = dock_state > 0 and 0 or 1
                gfx.dock(target_dock)
                GL.last_dock_state = gfx.dock(-1) -- Get the actual new index
                save_settings()
            end
        end
    end

    draw_snackbar()
    draw_tooltip()
    
    -- Draw Requirements Overlay (top-most priority, but below snackbar/tooltip)
    draw_requirements_window()

    local cur_dock = gfx.dock(-1)
    if cur_dock > 0 and cur_dock ~= GL.last_dock_state then
        GL.last_dock_state = cur_dock
        reaper.SetExtState(section_name, "dock", tostring(GL.last_dock_state), true)
    elseif cur_dock == 0 and GL.last_dock_state ~= 0 then
        -- Only set to 0 if the window is actually floating and NOT closing
        -- This is a bit tricky, but checking if char != -1 helps
        if gfx.getchar() ~= -1 then
            GL.last_dock_state = 0
            reaper.SetExtState(section_name, "dock", "0", true)
        end
    end

    -- Async handling and Loader must be drawn BEFORE gfx.update
    check_async_pool()
    
    -- Periodic Update Check
    if reaper.time_precise() - UI_STATE.last_update_check_time > UI_STATE.AUTO_UPDATE_INTERVAL then
        UI_STATE.last_update_check_time = reaper.time_precise()
        -- Only check if we are not already doing something async
        if not UI_STATE.script_loading_state.active then 
            check_for_updates(true) -- Silent check
        end
    end

    draw_loader()
    
    process_post_recording()

    gfx.update()

    -- Coroutine Handling (for heavy sync tasks like Dictionary scan)
    if global_coroutine then
        local status = coroutine.status(global_coroutine)
        if status == "suspended" then
            local ok, err = coroutine.resume(global_coroutine)
            if not ok then
                reaper.ShowConsoleMsg("Coroutine Error: " .. tostring(err) .. "\n")
                global_coroutine = nil
                UI_STATE.script_loading_state.active = false
            end
        elseif status == "dead" then
            global_coroutine = nil
            -- Only turn off loader if no other async tasks are pending
            if #global_async_pool == 0 then
                UI_STATE.script_loading_state.active = false
            end
        end
    end

    UI_STATE.last_mouse_cap = gfx.mouse_cap

    reaper.defer(main)
end

update_regions_cache()
reaper.atexit(function()
    save_settings()
    STATS.save()
end)

main()
