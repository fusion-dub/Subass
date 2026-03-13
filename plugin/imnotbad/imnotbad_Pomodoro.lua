-------------------------------------------------------------------
-- imnotbad_Pomodoro.lua
-- Pomodoro by imnotbad
-- @version 1.0
-- @author imnotbad
-------------------------------------------------------------------

local LANG_SECTION = "imnotbad_Pomodoro"

local LANGUAGES = { "English", "Español", "Українська" }
local LANG_KEYS  = { "en", "es", "uk" }

local current_lang = "uk"
do
    local saved = reaper.GetExtState(LANG_SECTION, "language")
    if saved == "en" or saved == "es" or saved == "uk" then
        current_lang = saved
    end
end

local T_ALL = {
    en = {
        -- warnings
        warn_reimgui_msg  = "Please install ReaImGui via ReaPack",
        warn_reimgui_ttl  = "Error",
        warn_js_msg       = "Please install JS_ReaScriptAPI via ReaPack.",
        warn_js_ttl       = "Warning",
        warn_sws_msg      = "SWS/S&M extension not found.\n\nSome script features may not work.\nInstall SWS/S&M via ReaPack:\nExtensions → ReaPack → Browse packages → SWS/S&M",
        warn_sws_ttl      = "Warning: SWS/S&M missing",
        -- menu
        menu_file         = "File",
        menu_autostart    = "Auto-start with REAPER",
        menu_close        = "Close",
        menu_view         = "View",
        menu_size         = "Size",
        menu_font         = "Font:",
        menu_themes       = "Themes:",
        menu_language     = "Language",
        -- timer
        mode_work         = "POMODORO",
        mode_short        = "SHORT BREAK",
        mode_long         = "LONG BREAK",
        btn_pause         = "Pause",
        btn_start         = "Start",
        btn_resume        = "Resume",
        btn_stop          = "Stop",
        btn_next          = "Next",
        lbl_pomodoro      = "Pomodoro",
        lbl_short         = "Short",
        lbl_long          = "Long",
        state_running     = "Running",
        state_paused      = "Paused",
        state_idle        = "Stopped",
        -- tasks
        lbl_tasks         = "TASKS",
        hint_new_task     = "Enter task...",
        btn_add_task      = "+ Add",
        ctx_rename        = "Rename task",
        modal_rename_ttl  = "RENAME TASK",
        btn_save          = "Save",
        btn_cancel        = "Cancel",
        lbl_no_tasks      = "No tasks",
        -- stats
        stat_fmt          = "Completed: %d   |   Total: %d min",
        lbl_all_hidden    = "All hidden",
        lbl_work_time     = "work time",
        lbl_sessions      = "%d sessions",
        lbl_show          = "Show",
        lbl_hide          = "Hide",
        -- log
        log_toggle_fmt    = "%s Session log (%d)",
        hint_log_filter   = "Search tasks...",
        log_nothing       = "Nothing found",
        btn_save_log      = "Save log",
        btn_save_log_flt  = "Save filtered log",
        log_header        = "Pomodoro Log",
        log_filter_lbl    = "Filter: ",
        lbl_short_break   = "Short break",
        lbl_long_break    = "Long break",
        -- settings
        settings_toggle   = "%s Settings",
        settings_dur      = "Duration (minutes):",
        settings_opts     = "Options:",
        chk_autostart     = "Auto-start next",
        chk_sound         = "Sound on finish",
        btn_clear         = "Clear log & stats",
        confirm_clear_q   = "Really clear all data?",
        btn_yes_clear     = "Yes, clear",
        -- notifications
        notif_long_break  = "Long break time!",
        notif_short_break = "Short break time!",
        notif_work        = "Time to work!",
        -- tooltip
        tip_time          = "Time:          %d min",
        tip_sessions      = "Sessions:       %d",
        tip_share         = "Share:    %s of work time",
        -- misc
        lbl_min           = " min",
        leg_fmt           = " %s - %s ·  %d ses.  ·  %d min",
        lbl_no_task_key   = "No task",
        lbl_filter_prefix = "Filter: ",
    },
    es = {
        warn_reimgui_msg  = "Instale ReaImGui mediante ReaPack",
        warn_reimgui_ttl  = "Error",
        warn_js_msg       = "Instale JS_ReaScriptAPI mediante ReaPack.",
        warn_js_ttl       = "Advertencia",
        warn_sws_msg      = "No se encontró la extensión SWS/S&M.\n\nAlgunas funciones del script pueden no funcionar.\nInstale SWS/S&M mediante ReaPack:\nExtensiones → ReaPack → Explorar paquetes → SWS/S&M",
        warn_sws_ttl      = "Advertencia: falta SWS/S&M",
        menu_file         = "Archivo",
        menu_autostart    = "Inicio automático con REAPER",
        menu_close        = "Cerrar",
        menu_view         = "Vista",
        menu_size         = "Tamaño",
        menu_font         = "Fuente:",
        menu_themes       = "Temas:",
        menu_language     = "Idioma",
        mode_work         = "POMODORO",
        mode_short        = "PAUSA CORTA",
        mode_long         = "PAUSA LARGA",
        btn_pause         = "Pausa",
        btn_start         = "Inicio",
        btn_resume        = "Continuar",
        btn_stop          = "Detener",
        btn_next          = "Siguiente",
        lbl_pomodoro      = "Pomodoro",
        lbl_short         = "Corta",
        lbl_long          = "Larga",
        state_running     = "En curso",
        state_paused      = "Pausado",
        state_idle        = "Detenido",
        lbl_tasks         = "TAREAS",
        hint_new_task     = "Ingrese tarea...",
        btn_add_task      = "+ Agregar",
        ctx_rename        = "Renombrar tarea",
        modal_rename_ttl  = "RENOMBRAR TAREA",
        btn_save          = "Guardar",
        btn_cancel        = "Cancelar",
        lbl_no_tasks      = "Sin tareas",
        stat_fmt          = "Completados: %d   |   Total: %d min",
        lbl_all_hidden    = "Todos ocultos",
        lbl_work_time     = "tiempo de trabajo",
        lbl_sessions      = "%d sesiones",
        lbl_show          = "Mostrar",
        lbl_hide          = "Ocultar",
        log_toggle_fmt    = "%s Registro de sesión (%d)",
        hint_log_filter   = "Buscar tareas...",
        log_nothing       = "Nada encontrado",
        btn_save_log      = "Guardar registro",
        btn_save_log_flt  = "Guardar registro filtrado",
        log_header        = "Registro Pomodoro",
        log_filter_lbl    = "Filtro: ",
        lbl_short_break   = "Pausa corta",
        lbl_long_break    = "Pausa larga",
        settings_toggle   = "%s Configuración",
        settings_dur      = "Duración (minutos):",
        settings_opts     = "Opciones:",
        chk_autostart     = "Auto-inicio siguiente",
        chk_sound         = "Sonido al terminar",
        btn_clear         = "Borrar registro y estadísticas",
        confirm_clear_q   = "¿Borrar todos los datos?",
        btn_yes_clear     = "Sí, borrar",
        notif_long_break  = "¡Tiempo de pausa larga!",
        notif_short_break = "¡Tiempo de pausa corta!",
        notif_work        = "¡Hora de trabajar!",
        tip_time          = "Tiempo:          %d min",
        tip_sessions      = "Sesiones:       %d",
        tip_share         = "Parte:    %s del tiempo de trabajo",
        lbl_min           = " min",
        leg_fmt           = " %s - %s ·  %d ses.  ·  %d min",
        lbl_no_task_key   = "Sin tarea",
        lbl_filter_prefix = "Filtro: ",
    },
    uk = {
        warn_reimgui_msg  = "Встановіть ReaImGui через ReaPack",
        warn_reimgui_ttl  = "Помилка",
        warn_js_msg       = "Встановіть JS_ReaScriptAPI через ReaPack.",
        warn_js_ttl       = "Попередження",
        warn_sws_msg      = "Розширення SWS/S&M не виявлено.\n\nДеякі функції скрипта можуть не працювати.\nВстановіть SWS/S&M через ReaPack:\nExtensions → ReaPack → Browse packages → SWS/S&M",
        warn_sws_ttl      = "Попередження: відсутній SWS/S&M",
        menu_file         = "Файл",
        menu_autostart    = "Автозапуск при старті REAPER",
        menu_close        = "Закрити",
        menu_view         = "Вигляд",
        menu_size         = "Розмір",
        menu_font         = "Шрифт:",
        menu_themes       = "Теми:",
        menu_language     = "Мова",
        mode_work         = "POMODORO",
        mode_short        = "КОРОТКА ПЕРЕРВА",
        mode_long         = "ДОВГА ПЕРЕРВА",
        btn_pause         = "Пауза",
        btn_start         = "Старт",
        btn_resume        = "Продовжити",
        btn_stop          = "Стоп",
        btn_next          = "Далі",
        lbl_pomodoro      = "Pomodoro",
        lbl_short         = "Коротка",
        lbl_long          = "Довга",
        state_running     = "Виконується",
        state_paused      = "Пауза",
        state_idle        = "Зупинено",
        lbl_tasks         = "ЗАВДАННЯ",
        hint_new_task     = "Введіть завдання...",
        btn_add_task      = "+ Додати",
        ctx_rename        = "Змінити завдання",
        modal_rename_ttl  = "ЗМІНИТИ ЗАВДАННЯ",
        btn_save          = "Зберегти",
        btn_cancel        = "Скасувати",
        lbl_no_tasks      = "Завдань немає",
        stat_fmt          = "Завершено: %d   |   Загалом: %d хв",
        lbl_all_hidden    = "Всі приховані",
        lbl_work_time     = "робочий час",
        lbl_sessions      = "%d сесій",
        lbl_show          = "Показати",
        lbl_hide          = "Приховати",
        log_toggle_fmt    = "%s Журнал сесії (%d)",
        hint_log_filter   = "Пошук завдань...",
        log_nothing       = "Нічого не знайдено",
        btn_save_log      = "Зберегти журнал",
        btn_save_log_flt  = "Зберегти відфільтрований журнал",
        log_header        = "Журнал Pomodoro",
        log_filter_lbl    = "Фільтр: ",
        lbl_short_break   = "Коротка перерва",
        lbl_long_break    = "Довга перерва",
        settings_toggle   = "%s Налаштування",
        settings_dur      = "Тривалість (хвилини):",
        settings_opts     = "Опції:",
        chk_autostart     = "Авто-старт наступного",
        chk_sound         = "Звук при завершенні",
        btn_clear         = "Очистити журнал та статистику",
        confirm_clear_q   = "Справді очистити всі дані?",
        btn_yes_clear     = "Так, очистити",
        notif_long_break  = "Час довгої перерви!",
        notif_short_break = "Час короткої перерви!",
        notif_work        = "Час працювати!",
        tip_time          = "Час:          %d хв",
        tip_sessions      = "Сесій:       %d",
        tip_share         = "Частка:    %s від робочого часу",
        lbl_min           = " хв",
        leg_fmt           = " %s - %s ·  %d сес.  ·  %d хв",
        lbl_no_task_key   = "Без задачі",
        lbl_filter_prefix = "Фільтр: ",
    },
}

local function T(key)
    local tbl = T_ALL[current_lang] or T_ALL["uk"]
    return tbl[key] or (T_ALL["uk"][key] or key)
end

local THEMES = {
    {
        key  = "dark",
        label = { en = "Dark", es = "Oscuro", uk = "Темна" },
        BG   = 0x1A1A1AFF, TAB = 0x2D2D2DFF, TABHOV = 0x444444FF,
        MAIN = 0x757575FF, OVERLINE = 0xFFCC0088,
        FRAME = 0x101010FF, FRAMEHOV = 0x202020FF, FRAMEACT = 0x252525FF,
        BTN  = 0x101010FF, SCBG = 0x1A1A1A00, SCGRAB = 0x444444FF,
        POPBG = 0x212121FF, SEP = 0x444444FF,
        ACCENT = 0xcfcfcfFF, HEADERCOL = 0xFFCC00FF,
        TEXT = 0xEEEEEEFF, MENUBG = 0x111111FF,
    },
    {
        key  = "light",
        label = { en = "Light", es = "Claro", uk = "Світла" },
        BG   = 0xD0D0D0FF, TAB = 0xBBBBBBFF, TABHOV = 0xCCCCCCFF,
        MAIN = 0x4488AAFF, OVERLINE = 0x4488AA88,
        FRAME = 0xC0C0C0FF, FRAMEHOV = 0xD5D5D5FF, FRAMEACT = 0xCBCBCBFF,
        BTN  = 0xC2C2C2FF, SCBG = 0xD0D0D000, SCGRAB = 0xBBBBBBFF,
        POPBG = 0xEEEEEEFF, SEP = 0xAAAAAAFF,
        ACCENT = 0xcfcfcfFF, HEADERCOL = 0x4488AAFF,
        TEXT = 0x474747FF, MENUBG = 0xBBBBBBFF,
    },
    {
        key  = "blue",
        label = { en = "Blue", es = "Azul", uk = "Синя" },
        BG   = 0x0A101FFF, TAB = 0x0A1020FF, TABHOV = 0x1A2A40FF,
        MAIN = 0x0055BBFF, OVERLINE = 0x9AB6D1FF,
        FRAME = 0x080C18FF, FRAMEHOV = 0x101828FF, FRAMEACT = 0x141E30FF,
        BTN  = 0x0A0F1AFF, SCBG = 0x05080F00, SCGRAB = 0x1A3A5AFF,
        POPBG = 0x0A0F1AFF, SEP = 0x224499FF,
        ACCENT = 0xE5EDFFFF, HEADERCOL = 0x00EEFFFF,
        TEXT = 0xE5EDFFFF, MENUBG = 0x030610FF,
    },
    {
        key  = "red",
        label = { en = "Red", es = "Rojo", uk = "Червона" },
        BG   = 0x100505FF, TAB = 0x200808FF, TABHOV = 0x3A1010FF,
        MAIN = 0xBB2200FF, OVERLINE = 0xD4535366,
        FRAME = 0x0D0404FF, FRAMEHOV = 0x1A0808FF, FRAMEACT = 0x200A0AFF,
        BTN  = 0x1A0808FF, SCBG = 0x10050500, SCGRAB = 0x5A1A1AFF,
        POPBG = 0x1A0808FF, SEP = 0x882211FF,
        ACCENT = 0xFFffffFF, HEADERCOL = 0xFFCC00FF,
        TEXT = 0xFFffffFF, MENUBG = 0x0A0303FF,
    },
    {
        key  = "yellow",
        label = { en = "Yellow", es = "Amarillo", uk = "Жовта" },
        BG   = 0x0A0700FF, TAB = 0x1A1000FF, TABHOV = 0x2A1E00FF,
        MAIN = 0xAA6600FF, OVERLINE = 0xAA660066,
        FRAME = 0x080500FF, FRAMEHOV = 0x150F00FF, FRAMEACT = 0x1A1200FF,
        BTN  = 0x150F00FF, SCBG = 0x0A070000, SCGRAB = 0x4A2A00FF,
        POPBG = 0x150F00FF, SEP = 0x885500FF,
        ACCENT = 0xFFFfffFF, HEADERCOL = 0xFFDD44FF,
        TEXT = 0xFFffffFF, MENUBG = 0x060400FF,
    },
}
local current_theme_key = "dark"

local function get_theme()
    for _, th in ipairs(THEMES) do
        if th.key == current_theme_key then return th end
    end
    return THEMES[1]
end

if not reaper.ImGui_CreateContext then
    reaper.ShowMessageBox(T("warn_reimgui_msg"), T("warn_reimgui_ttl"), 0)
    return
end

if not reaper.JS_Dialog_BrowseForSaveFile then
    reaper.ShowMessageBox(T("warn_js_msg"), T("warn_js_ttl"), 0)
end

if not reaper.BR_GetMediaTrackByGUID then
    reaper.ShowMessageBox(T("warn_sws_msg"), T("warn_sws_ttl"), 0)
end

local ctx = reaper.ImGui_CreateContext("Pomodoro by imnotbad")

local IS_MACOS = reaper.GetOS():find("OSX") ~= nil or reaper.GetOS():find("macOS") ~= nil

local function is_mod_pressed()
    if IS_MACOS then
        return reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Mod_Super())
            or reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Mod_Ctrl())
    else
        return reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Mod_Ctrl())
    end
end

local VK_TO_IMGUI_KEY = {
    [65] = function() return reaper.ImGui_Key_A() end,
    [67] = function() return reaper.ImGui_Key_C() end,
    [70] = function() return reaper.ImGui_Key_F() end,
    [83] = function() return reaper.ImGui_Key_S() end,
    [86] = function() return reaper.ImGui_Key_V() end,
    [88] = function() return reaper.ImGui_Key_X() end,
    [90] = function() return reaper.ImGui_Key_Z() end,
}

local function is_mod_key_pressed(key_fn, vk)
    if not is_mod_pressed() then return false end
    if reaper.ImGui_IsKeyPressed(ctx, key_fn()) then return true end
    if vk and reaper.JS_VKeys_GetState then
        local state = reaper.JS_VKeys_GetState(-2)
        if state and #state >= vk and state:byte(vk) == 1 then
            return true
        end
    end
    return false
end

local function is_shortcut_pressed(imgui_key_fn, vk)
    if reaper.ImGui_Shortcut then
        local mod = IS_MACOS and reaper.ImGui_Mod_Super() or reaper.ImGui_Mod_Ctrl()
        local chord = mod | imgui_key_fn()
        if reaper.ImGui_Shortcut(ctx, chord, reaper.ImGui_InputFlags_RouteGlobal and reaper.ImGui_InputFlags_RouteGlobal() or 0) then
            return true
        end
    end
    return is_mod_key_pressed(imgui_key_fn, vk)
end

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
    confirm_clear     = false,
    notification_msg  = nil,
    notification_time = 0,
    tasks             = {},
    selected_task     = 0,
    new_task_buf      = "",
    log_filter        = "",
    hidden_sectors    = {},
}
local saved_selection_start     = 0
local saved_selection_end       = 0
local confirm_close_tab_index   = nil
local confirm_close_prev_active = nil
local rename_task_index         = nil
local rename_task_buf           = ""
local pending_rename_task       = false
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
local save_file                 = script_path .. "imnotbad_Pomodoro_Tasks.txt"

local pomo_menu_font = reaper.ImGui_CreateFont("Arial", reaper.ImGui_FontFlags_Bold())

local function GetGeneralColorHEX()
    local th = get_theme()
    return th.MAIN
end

local function push_style(ctx)
    local th       = get_theme()
    local main_col = th.MAIN
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowRounding(), 10.0)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameRounding(), 7.0)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_TabRounding(), 5.0)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_PopupRounding(), 8.0)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowTitleAlign(), 0.5, 0.5)
    
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(),              th.TEXT)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TextDisabled(),      th.TEXT)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_MenuBarBg(),         th.MENUBG)
    
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(),          th.BG)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgActive(),     th.BG)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBg(),           th.BG)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgCollapsed(),  th.BG)
    
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Tab(),               th.TAB)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabHovered(),        th.TABHOV)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabSelected(),       main_col)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabSelectedOverline(),th.OVERLINE)
    
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(),           th.FRAME)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgHovered(),    th.FRAMEHOV)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgActive(),     th.FRAMEACT)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TextSelectedBg(),    main_col)
    
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),            th.BTN)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(),     main_col)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(),      main_col)
    
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderHovered(),     main_col)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderActive(),      th.HEADERCOL)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Header(),            main_col)
    
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SliderGrab(),        main_col)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SliderGrabActive(),  main_col)
    
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGrip(),        main_col)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripActive(),  main_col)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripHovered(), main_col)
    
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarBg(),      th.SCBG)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrab(),    th.SCGRAB)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabActive(),  main_col)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabHovered(), main_col)
    
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PopupBg(),    th.POPBG)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Separator(),   th.SEP)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_CheckMark(),   main_col)
    
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ModalWindowDimBg(), 0x00000099)
end

local function pop_style(ctx)
    reaper.ImGui_PopStyleColor(ctx, 34)
    reaper.ImGui_PopStyleVar(ctx, 5)
end

local function rebuild_tab_font()
    if tab_font then
        reaper.ImGui_Detach(ctx, tab_font)
        tab_font = nil
    end
    tab_font = reaper.ImGui_CreateFont(current_font_name, tab_font_size)
    reaper.ImGui_Attach(ctx, tab_font)
end

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

local function play_sound()
    local info = debug.getinfo(1, 'S')
    local script_path = info.source:match("@?(.*[\\/])")
    local snd_path = script_path .. "imnotbad_Pomodoro_Alarm.wav"
    if not reaper.CF_CreatePreview then
        reaper.ShowMessageBox(T_ALL[current_lang]["warn_sws_ttl"] or "SWS Extension not found!", "Error", 0)
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

local EXT_STATE_SECTION = "imnotbad_Pomodoro"

local function save_font_settings()
    reaper.SetExtState(EXT_STATE_SECTION, "font_size", tostring(tab_font_size), true)
    reaper.SetExtState(EXT_STATE_SECTION, "font_name", current_font_name, true)
    reaper.SetExtState(EXT_STATE_SECTION, "theme", current_theme_key, true)
    reaper.SetExtState(EXT_STATE_SECTION, "language", current_lang, true)
end

local function save_data()
    save_font_settings()
    reaper.SetExtState(EXT_STATE_SECTION, "active_tab", tostring(active_tab_index), true)
    reaper.SetExtState(EXT_STATE_SECTION, "pomodoro_active", pomodoro_active and "1" or "0", true)
    
    local f = io.open(save_file, "w")
    if f then 
        f:write("[POMODORO_START]\n") 
        f:write("mode=" .. pomo.mode .. "\n")
        f:write("work_duration=" .. pomo.work_duration .. "\n")
        f:write("short_break=" .. pomo.short_break .. "\n")
        f:write("long_break=" .. pomo.long_break .. "\n")
        f:write("completed=" .. pomo.completed .. "\n")
        f:write("total_work_sec=" .. pomo.total_work_sec .. "\n")
        f:write("long_break_every=" .. pomo.long_break_every .. "\n")
        f:write("auto_start=" .. (pomo.auto_start and "1" or "0") .. "\n")
        f:write("sound_enabled=" .. (pomo.sound_enabled and "1" or "0") .. "\n")  
        f:write("edit_work=" .. pomo.edit_work .. "\n")
        f:write("edit_short=" .. pomo.edit_short .. "\n")
        f:write("edit_long=" .. pomo.edit_long .. "\n")
        f:write("edit_long_every=" .. pomo.edit_long_every .. "\n") 
       
        f:write("[TASKS]\n")
        for _, task in ipairs(pomo.tasks) do
            local safe_task = task:gsub("\n", "\\n")
            f:write(safe_task .. "\n")
        end
        f:write("[TASKS_END]\n")
        f:write("selected_task=" .. pomo.selected_task .. "\n")
        f:write("[SESSION_LOG]\n")
        for _, entry in ipairs(pomo.session_log) do
            local task_name = entry.task_name or "" 
            task_name = task_name:gsub("\n", "\\n"):gsub("|", "\\p")
            local completed_at = entry.completed_at:gsub("\n", "\\n")
            f:write(string.format("%s|%d|%s|%s\n", 
                entry.mode, 
                entry.duration_sec or 0, 
                completed_at, 
                task_name))
        end
        f:write("[SESSION_LOG_END]\n") 
        f:write("[POMODORO_END]\n") 
        f:close()
    end
end

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

    local saved_theme = reaper.GetExtState(EXT_STATE_SECTION, "theme")
    if saved_theme and saved_theme ~= "" then
        for _, th in ipairs(THEMES) do
            if th.key == saved_theme then
                current_theme_key = saved_theme
                break
            end
        end
    end

    local saved_lang = reaper.GetExtState(EXT_STATE_SECTION, "language")
    if saved_lang == "en" or saved_lang == "es" or saved_lang == "uk" then
        current_lang = saved_lang
    end
end

local function load_data()
    load_font_settings()
    local f = io.open(save_file, "r")
    if f then
        local all = f:read("*all")
        f:close()  
        
        pomo = {
            mode = "work", state = "idle", work_duration = 25 * 60,
            short_break = 5 * 60, long_break = 15 * 60, remaining = 25 * 60,
            start_time = 0, elapsed_before = 0, completed = 0,
            long_break_every = 4, auto_start = false, sound_enabled = true,
            edit_work = 25, edit_short = 5, edit_long = 15, edit_long_every = 4,
            session_log = {}, total_work_sec = 0, show_settings = false,
            confirm_clear = false, notification_msg = nil, notification_time = 0,
            tasks = {}, selected_task = 0, new_task_buf = "", log_filter = "",
            hidden_sectors = {},
        }  
        
        
        local pomo_block = all:match("%[POMODORO_START%]\n(.-)%[POMODORO_END%]")
        if pomo_block then 
            pomo.mode = pomo_block:match("mode=(%w+)") or "work"
            pomo.work_duration = tonumber(pomo_block:match("work_duration=(%d+)")) or 25*60
            pomo.short_break = tonumber(pomo_block:match("short_break=(%d+)")) or 5*60
            pomo.long_break = tonumber(pomo_block:match("long_break=(%d+)")) or 15*60
            pomo.completed = tonumber(pomo_block:match("completed=(%d+)")) or 0
            pomo.total_work_sec = tonumber(pomo_block:match("total_work_sec=(%d+)")) or 0
            pomo.long_break_every = tonumber(pomo_block:match("long_break_every=(%d+)")) or 4
            pomo.auto_start = (pomo_block:match("auto_start=([01])") or "0") == "1"
            pomo.sound_enabled = (pomo_block:match("sound_enabled=([01])") or "1") == "1" 
           
            pomo.edit_work = tonumber(pomo_block:match("edit_work=(%d+)")) or 25
            pomo.edit_short = tonumber(pomo_block:match("edit_short=(%d+)")) or 5
            pomo.edit_long = tonumber(pomo_block:match("edit_long=(%d+)")) or 15
            pomo.edit_long_every = tonumber(pomo_block:match("edit_long_every=(%d+)")) or 4
           
            if pomo.mode == "work" then
                pomo.remaining = pomo.work_duration
            elseif pomo.mode == "short_break" then
                pomo.remaining = pomo.short_break
            else
                pomo.remaining = pomo.long_break
            end 
           
            local tasks_block = pomo_block:match("%[TASKS%]\n(.-)%[TASKS_END%]")
            if tasks_block then
                pomo.tasks = {}
                for task in tasks_block:gmatch("([^\n]+)") do 
                    task = task:gsub("\\n", "\n"):gsub("\\p", "|")
                    table.insert(pomo.tasks, task)
                end
            end 

            pomo.selected_task = tonumber(pomo_block:match("selected_task=(%d+)")) or 0 
            
            local log_block = pomo_block:match("%[SESSION_LOG%]\n(.-)%[SESSION_LOG_END%]")
            if log_block then
                pomo.session_log = {}
                for line in log_block:gmatch("([^\n]+)") do
                    local mode, dur, time_str, task_name = line:match("^([^|]+)|([^|]+)|([^|]+)|?(.*)$")
                    if mode and dur and time_str then 
                        task_name = task_name:gsub("\\n", "\n"):gsub("\\p", "|")
                        time_str = time_str:gsub("\\n", "\n")
                        table.insert(pomo.session_log, {
                            mode = mode,
                            duration_sec = tonumber(dur) or 0,
                            completed_at = time_str,
                            task_name = (task_name and task_name ~= "") and task_name or nil
                        })
                    end
                end
            end
        end 
    end   
    
    pomodoro_pending_select = true 
    
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
    return content:find("-- imnotbad_Pomodoro Startup Start", 1, true) ~= nil
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
    local tag_start = "-- imnotbad_Pomodoro Startup Start"
    local tag_end = "-- imnotbad_Pomodoro Startup End"

    for _, line in ipairs(lines) do
        if line:find(tag_start, 1, true) then
            skip = true
        elseif line:find(tag_end, 1, true) then
            skip = false
        elseif not skip then
            if not line:find("imnotbad_Pomodoro.lua", 1, true) then
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

local mac_hotkey_debounce = {}

local function handle_mac_hotkeys()
    if not IS_MACOS then return end
    if not reaper.JS_VKeys_GetState then return end


    local cmd_down = reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Mod_Super())
    if not cmd_down then
        mac_hotkey_debounce = {}
        return
    end

    local state = reaper.JS_VKeys_GetState(-2)
    if not state then return end

    local function vk_just_pressed(vk)
        local pressed = (#state >= vk) and (state:byte(vk) == 1)
        if pressed and not mac_hotkey_debounce[vk] then
            mac_hotkey_debounce[vk] = true
            return true
        elseif not pressed then
            mac_hotkey_debounce[vk] = false
        end
        return false
    end

    if vk_just_pressed(67) then
        local sel_s = tab.saved_sel_start or 0
        local sel_e = tab.saved_sel_end or 0
        if sel_s > sel_e then sel_s, sel_e = sel_e, sel_s end
        if sel_s ~= sel_e then
            reaper.ImGui_SetClipboardText(ctx, tab.content:sub(sel_s + 1, sel_e))
        end
        return
    end

    if vk_just_pressed(88) then
        local sel_s = tab.saved_sel_start or 0
        local sel_e = tab.saved_sel_end or 0
        if sel_s > sel_e then sel_s, sel_e = sel_e, sel_s end
        if sel_s ~= sel_e then
            reaper.ImGui_SetClipboardText(ctx, tab.content:sub(sel_s + 1, sel_e))
            tab.content         = tab.content:sub(1, sel_s) .. tab.content:sub(sel_e + 1)
            tab.saved_sel_start = sel_s
            tab.saved_sel_end   = sel_s
            tab.saved_cursor    = sel_s
            tab.editing         = false
            tab.reopen_editing  = true
        end
        return
    end

    if vk_just_pressed(86) then
        local clipboard = reaper.ImGui_GetClipboardText(ctx)
        if clipboard and clipboard ~= "" then
            local sel_s = tab.saved_sel_start or 0
            local sel_e = tab.saved_sel_end or 0
            if sel_s > sel_e then sel_s, sel_e = sel_e, sel_s end
            local has_sel = (sel_s ~= sel_e)
            local pos = tab.saved_cursor or #tab.content
            if has_sel then
                tab.content = tab.content:sub(1, sel_s) .. clipboard .. tab.content:sub(sel_e + 1)
            else
                tab.content = tab.content:sub(1, pos) .. clipboard .. tab.content:sub(pos + 1)
            end
            tab.editing        = false
            tab.reopen_editing = true
        end
        return
    end

    if vk_just_pressed(83) then
        tab.editing = false
        return
    end

    vk_just_pressed(70)
    vk_just_pressed(65)
end

local function loop()
    local active_style_tooltip = ""
    handle_mac_hotkeys()

    push_style(ctx)

    reaper.ImGui_SetNextWindowSizeConstraints(ctx, 475, 400, 1e10, 1e10)
    reaper.ImGui_SetNextWindowSize(ctx, 800, 600, reaper.ImGui_Cond_FirstUseEver())
    local flags = reaper.ImGui_WindowFlags_MenuBar()
        | reaper.ImGui_WindowFlags_NoCollapse()

    local visible, open = reaper.ImGui_Begin(ctx, "POMODORO by imnotbad", true, flags)
local th       = get_theme()
    if visible then
        --================ MENU =================
        if reaper.ImGui_BeginMenuBar(ctx) then
            if reaper.ImGui_BeginMenu(ctx, T("menu_file")) then
                local startup_active = is_startup_enabled()
                if reaper.ImGui_MenuItem(ctx, T("menu_autostart"), nil, startup_active) then
                    toggle_reaper_startup(not startup_active)
                    save_data()
                end
                reaper.ImGui_Separator(ctx)
                if reaper.ImGui_MenuItem(ctx, T("menu_close")) then
                    open = false
                end
                reaper.ImGui_EndMenu(ctx)
            end
            if reaper.ImGui_BeginMenu(ctx, T("menu_view")) then 
                reaper.ImGui_SeparatorText(ctx, T("menu_font"))

                for _, name in ipairs(font_list) do
                    local is_selected = (current_font_name == name)
                    if reaper.ImGui_MenuItem(ctx, name, "", is_selected) then
                        current_font_name = name
                        rebuild_tab_font()
                        rebuild_format_fonts()
                        save_data()
                    end
                end
                
                reaper.ImGui_SeparatorText(ctx, T("menu_themes"))
                
                for _, th in ipairs(THEMES) do
                    local is_sel = (current_theme_key == th.key)
                    local lbl = (th.label and th.label[current_lang]) or th.key 
                    
                    local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
                    local cx, cy = reaper.ImGui_GetCursorScreenPos(ctx)
                
                    reaper.ImGui_Dummy(ctx, 12, 12)
                    reaper.ImGui_DrawList_AddRectFilled(draw_list, cx, cy + 2, cx + 12, cy + 14, th.MAIN)
                
                    reaper.ImGui_SameLine(ctx)
                
                    if reaper.ImGui_MenuItem(ctx, lbl, "", is_sel) then
                        current_theme_key = th.key
                        save_data()
                    end
                end

                reaper.ImGui_EndMenu(ctx)
            end

            if reaper.ImGui_BeginMenu(ctx, T("menu_language")) then
                for i, lname in ipairs(LANGUAGES) do
                    local lkey = LANG_KEYS[i]
                    local is_sel = (current_lang == lkey)
                    if reaper.ImGui_MenuItem(ctx, lname, "", is_sel) then
                        current_lang = lkey
                        save_data()
                    end
                end
                reaper.ImGui_EndMenu(ctx)
            end

            reaper.ImGui_EndMenuBar(ctx)
        end

        --================ POMODORO GLOBAL TICK =================
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

            if pomo.state == "running" or pomo.state == "paused" then
                pomo.remaining = remaining_tick
            end

            if pomo.state == "running" and remaining_tick <= 0 then
                local cur_task_name = (pomo.selected_task > 0 and pomo.tasks[pomo.selected_task]) or nil
                table.insert(pomo.session_log, {
                    mode         = pomo.mode,
                    duration_sec = total_dur_tick,
                    completed_at = os.date("%H:%M %d.%m.%Y"),
                    task_name    = cur_task_name
                })
                if pomo.mode == "work" then
                    pomo.completed      = pomo.completed + 1
                    pomo.total_work_sec = pomo.total_work_sec + pomo.work_duration
                end

                if pomo.sound_enabled then play_sound() end

                if pomo.mode == "work" then
                    if pomo.completed % pomo.long_break_every == 0 then
                        pomo.mode = "long_break"
                        pomo.notification_msg = T("notif_long_break")
                    else
                        pomo.mode = "short_break"
                        pomo.notification_msg = T("notif_short_break")
                    end
                else
                    pomo.mode = "work"
                    pomo.notification_msg = T("notif_work")
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

        --================ POMODORO PANEL =================
        do
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
                    work        = T("mode_work"),
                    short_break = T("mode_short"),
                    long_break  = T("mode_long")
                }
                local mode_lbl = mode_labels[pomo.mode]
                reaper.ImGui_PushFont(ctx, tab_font, 46)
                local tw = reaper.ImGui_CalcTextSize(ctx, mode_lbl)
                reaper.ImGui_SetCursorPosX(ctx, (avail_w - tw) * 0.5)
                reaper.ImGui_TextColored(ctx, GetGeneralColorHEX(), mode_lbl)
                reaper.ImGui_PopFont(ctx)

                reaper.ImGui_Dummy(ctx, 0, 8)

                local cx_pos = avail_w * 0.5
                local timer_radius = math.max(40, math.min(avail_w, avail_h) * 0.22)

                local scroll_y = reaper.ImGui_GetScrollY(ctx)

                local cy_pos = reaper.ImGui_GetCursorPosY(ctx) + timer_radius + 10
                reaper.ImGui_SetCursorPosY(ctx, cy_pos + timer_radius + 14)

                local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
                local win_x, win_y = reaper.ImGui_GetWindowPos(ctx)

                local scr_cx = win_x + cx_pos
                local scr_cy = win_y + cy_pos - scroll_y

                reaper.ImGui_DrawList_AddCircleFilled(draw_list, scr_cx, scr_cy, timer_radius, th.TAB, 80)
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
                reaper.ImGui_PushFont(ctx, tab_font, math.max(12, timer_radius * 0.6))
                local tsw, tsh = reaper.ImGui_CalcTextSize(ctx, time_str)
                reaper.ImGui_SetCursorPos(ctx, cx_pos - tsw * 0.5, cy_pos - timer_radius * 0.5)
                reaper.ImGui_TextColored(ctx, th.TEXT, time_str)
                reaper.ImGui_PopFont(ctx)

                local state_lbl = (pomo.state == "running") and T("state_running")
                    or (pomo.state == "paused") and T("state_paused")
                    or T("state_idle")
                reaper.ImGui_PushFont(ctx, tab_font, math.max(10, timer_radius * 0.2))
                local slw, slh = reaper.ImGui_CalcTextSize(ctx, state_lbl)
                reaper.ImGui_SetCursorPos(ctx, cx_pos - slw * 0.5, cy_pos + timer_radius * 0.2)
                reaper.ImGui_TextColored(ctx,  th.TEXT, state_lbl)
                reaper.ImGui_PopFont(ctx)

                reaper.ImGui_SetCursorPosY(ctx, cy_pos + timer_radius + 22)

                local btn_w        = 115
                local btn_h        = 40
                local gap          = 15
                local total_btns_w = btn_w * 3 + gap * 2
                reaper.ImGui_SetCursorPosX(ctx, (avail_w - total_btns_w) * 0.5)
                
                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), th.ACCENT )
                if pomo.state == "running" then
                    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x885500FF)
                    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0xBB7700FF)
                    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), 0xFF9900FF)
                    reaper.ImGui_PushFont(ctx, bold_font, 16)
                    if reaper.ImGui_Button(ctx, T("btn_pause"), btn_w, btn_h) then
                        pomo.elapsed_before = pomo.elapsed_before + (now - pomo.start_time)
                        pomo.state = "paused"
                    end
                    reaper.ImGui_PopFont(ctx)
                    reaper.ImGui_PopStyleColor(ctx, 3)
                else
                    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x226622FF)
                    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0x339933FF)
                    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), 0x44BB44FF)
                    reaper.ImGui_PushFont(ctx, bold_font, 16)
                    local start_lbl = (pomo.state == "paused") and T("btn_resume") or T("btn_start")
                    if reaper.ImGui_Button(ctx, start_lbl, btn_w, btn_h) then
                        pomo.start_time = now
                        pomo.state = "running"
                    end
                    reaper.ImGui_PopFont(ctx)
                    reaper.ImGui_PopStyleColor(ctx, 3)
                end

                reaper.ImGui_SameLine(ctx, nil, gap)
                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), th.MAIN)
                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), th.OVERLINE)
                reaper.ImGui_PushFont(ctx, bold_font, 16)
                if reaper.ImGui_Button(ctx, T("btn_stop"), btn_w, btn_h) then
                    pomo.state          = "idle"
                    pomo.elapsed_before = 0
                    pomo.remaining      = (pomo.mode == "work") and pomo.work_duration
                        or (pomo.mode == "short_break") and pomo.short_break
                        or pomo.long_break
                end
                reaper.ImGui_PopFont(ctx)
                reaper.ImGui_PopStyleColor(ctx, 2)

                reaper.ImGui_SameLine(ctx, nil, gap)

                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), th.MAIN)
                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), th.OVERLINE)
                reaper.ImGui_PushFont(ctx, bold_font, 16)
                if reaper.ImGui_Button(ctx, T("btn_next"), btn_w, btn_h) then
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
                reaper.ImGui_PopFont(ctx)
                reaper.ImGui_PopStyleColor(ctx, 2)

                reaper.ImGui_Dummy(ctx, 0, 14)

                local modes = { { id = "work", lbl = T("lbl_pomodoro") }, { id = "short_break", lbl = T("lbl_short") }, { id = "long_break", lbl = T("lbl_long") } }
                local mode_btn_w = 115
                local total_mode_w = mode_btn_w * 3 + gap * 2
                reaper.ImGui_SetCursorPosX(ctx, (avail_w - total_mode_w) * 0.5)
                for mi, mdata in ipairs(modes) do
                    local is_active = (pomo.mode == mdata.id)
                    if is_active then
                        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), mode_color)
                        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), mode_color)
                    else
                        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), th.MAIN)
                        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), th.OVERLINE)
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
                reaper.ImGui_PopStyleColor(ctx, 1)
                reaper.ImGui_Dummy(ctx, 0, 10)
                reaper.ImGui_SetCursorPosX(ctx, 16)
                reaper.ImGui_Separator(ctx)

                -- ======= TASKS =======
                reaper.ImGui_Dummy(ctx, 0, 8)

                local tasks_avail_w = reaper.ImGui_GetContentRegionAvail(ctx)

                reaper.ImGui_PushFont(ctx, bold_font, 38)
                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), th.MAIN)
                reaper.ImGui_SetCursorPosX(ctx, (tasks_avail_w - reaper.ImGui_CalcTextSize(ctx, T("lbl_tasks"))) * 0.5)
                reaper.ImGui_Text(ctx, T("lbl_tasks"))
                reaper.ImGui_PopStyleColor(ctx, 1)
                reaper.ImGui_PopFont(ctx)

                reaper.ImGui_Dummy(ctx, 0, 6)

                do
                    local pad       = 20
                    local btn_add_w = 90
                    local item_h    = 32
                    local input_w   = tasks_avail_w - btn_add_w - pad * 2 - 8

                    reaper.ImGui_SetCursorPosX(ctx, pad)
                    reaper.ImGui_SetNextItemWidth(ctx, input_w)
                    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), 8, 7)
                    reaper.ImGui_PushFont(ctx, italic_font, 15)

                    local _, new_task_text = reaper.ImGui_InputTextWithHint(
                        ctx, "##new_task_input", T("hint_new_task"), pomo.new_task_buf
                    )

                    if reaper.ImGui_IsItemActive(ctx) then
                        pomo.new_task_buf = new_task_text
                    end

                    local enter_pressed = reaper.ImGui_IsItemFocused(ctx)
                        and reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Enter())

                    reaper.ImGui_PopFont(ctx)
                    reaper.ImGui_PopStyleVar(ctx)

                    reaper.ImGui_SameLine(ctx, nil, 10)
                    reaper.ImGui_PushFont(ctx, bold_font, 16)
                    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), th. ACCENT )
                    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x1E4A1EFF)
                    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0x2E6B2EFF)
                    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), 0x3A8A3AFF)
                    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), 0, 0)
                    local btn_clicked = reaper.ImGui_Button(ctx, T("btn_add_task") .. "##add_task", btn_add_w, item_h + 2)
                    reaper.ImGui_PopStyleVar(ctx)
                    reaper.ImGui_PopStyleColor(ctx, 4)
                    reaper.ImGui_PopFont(ctx)

                    if btn_clicked or enter_pressed then
                        local trimmed = pomo.new_task_buf:match("^%s*(.-)%s*$")
                        if trimmed and trimmed ~= "" then
                            table.insert(pomo.tasks, trimmed)
                            pomo.new_task_buf = ""
                            save_data()
                        end
                    end
                end

                if #pomo.tasks > 0 then
                    reaper.ImGui_Dummy(ctx, 0, 6)
                    local task_item_h = 26
                    local del_btn_w   = 26
                    local pad         = 20

                    for ti = 1, #pomo.tasks do
                        local task_name = pomo.tasks[ti]
                        if task_name then
                            local is_sel = (pomo.selected_task == ti)
                            local task_w = tasks_avail_w - del_btn_w - pad * 2 - 6

                            reaper.ImGui_SetCursorPosX(ctx, pad)
                            reaper.ImGui_PushFont(ctx, tab_font, 14)

                            if is_sel then
                                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), mode_color)
                                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), mode_color)
                                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), mode_color)
                                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xFFFFFFFF)
                            else
                                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x252525FF)
                                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0x383838FF)
                                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), 0x454545FF)
                                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xAAAAAAFF)
                            end

                            if reaper.ImGui_Button(ctx, task_name .. "##task_sel" .. ti, task_w, task_item_h) then
                                pomo.selected_task = (pomo.selected_task == ti) and 0 or ti
                                save_data()
                            end
                            reaper.ImGui_PopStyleColor(ctx, 4)
                            reaper.ImGui_PopFont(ctx)

                            if reaper.ImGui_IsItemHovered(ctx) and reaper.ImGui_IsMouseClicked(ctx, 1) then
                                reaper.ImGui_OpenPopup(ctx, "TaskContextMenu_" .. ti)
                            end

                            if reaper.ImGui_BeginPopup(ctx, "TaskContextMenu_" .. ti) then
                                reaper.ImGui_PushFont(ctx, tab_font, 14)
                                if reaper.ImGui_MenuItem(ctx, T("ctx_rename")) then
                                    rename_task_index = ti
                                    rename_task_buf = pomo.tasks[ti] or ""
                                    pending_rename_task = true
                                end
                                reaper.ImGui_PopFont(ctx)
                                reaper.ImGui_EndPopup(ctx)
                            end

                            reaper.ImGui_SameLine(ctx, nil, 6)
                            reaper.ImGui_PushFont(ctx, tab_font, 12)
                            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), th.BTN)
                            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0x7A1A1AFF)
                            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), 0xAA2222FF)
                            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0x888888FF)
                            if reaper.ImGui_Button(ctx, "✕##del_task" .. ti, del_btn_w, task_item_h) then
                                if pomo.selected_task == ti then
                                    pomo.selected_task = 0
                                elseif pomo.selected_task > ti then
                                    pomo.selected_task = pomo.selected_task - 1
                                end
                                table.remove(pomo.tasks, ti)
                                save_data()
                            end
                            reaper.ImGui_PopStyleColor(ctx, 4)
                            reaper.ImGui_PopFont(ctx)

                            reaper.ImGui_Dummy(ctx, 0, 2)
                        end
                    end
                else
                    reaper.ImGui_Dummy(ctx, 0, 4)
                    reaper.ImGui_PushFont(ctx, tab_font, 18)
                    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), th.MAIN)
                    local hint = T("lbl_no_tasks")
                    reaper.ImGui_SetCursorPosX(ctx, (tasks_avail_w - reaper.ImGui_CalcTextSize(ctx, hint)) * 0.5)
                    reaper.ImGui_Text(ctx, hint)
                    reaper.ImGui_PopStyleColor(ctx, 1)
                    reaper.ImGui_PopFont(ctx)
                end

                if pomo.selected_task > 0 and pomo.tasks[pomo.selected_task] then
                    reaper.ImGui_Dummy(ctx, 0, 6)
                    reaper.ImGui_PushFont(ctx, tab_font, 13)
                    local sel_lbl = "▶ " .. pomo.tasks[pomo.selected_task]
                    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), mode_color)
                    reaper.ImGui_SetCursorPosX(ctx, (tasks_avail_w - reaper.ImGui_CalcTextSize(ctx, sel_lbl)) * 0.5)
                    reaper.ImGui_Text(ctx, sel_lbl)
                    reaper.ImGui_PopStyleColor(ctx, 1)
                    reaper.ImGui_PopFont(ctx)
                end

                -- ======= MODAL WINDOW =======
                do
                    local rt_win_w   = 400
                    local rt_pad     = 20
                    local rt_btn_w   = 140
                    local rt_btn_h   = 32
                    local rt_btn_gap = 14
                    local rt_input_h = 38
                    local rt_win_h   = rt_pad + 20 + 8 + rt_input_h + 14 + rt_btn_h + rt_pad

                    local mwx, mwy   = reaper.ImGui_GetWindowPos(ctx)
                    local mww        = reaper.ImGui_GetWindowWidth(ctx)
                    local mwh        = reaper.ImGui_GetWindowHeight(ctx)
                    reaper.ImGui_SetNextWindowPos(ctx, mwx + (mww - rt_win_w) * 0.5, mwy + (mwh - rt_win_h) * 0.5,
                        reaper.ImGui_Cond_Always())
                    reaper.ImGui_SetNextWindowSize(ctx, rt_win_w, rt_win_h, reaper.ImGui_Cond_Always())

                    local rt_flags = reaper.ImGui_WindowFlags_NoResize()
                        | reaper.ImGui_WindowFlags_NoScrollbar()
                        | reaper.ImGui_WindowFlags_NoDocking()
                        | reaper.ImGui_WindowFlags_TopMost()
                        | reaper.ImGui_WindowFlags_NoDecoration()

                    if pending_rename_task then
                        pending_rename_task = false
                        reaper.ImGui_OpenPopup(ctx, "RenameTask")
                    end

                    local rt_open = reaper.ImGui_BeginPopupModal(ctx, "RenameTask", true, rt_flags)
                    if rt_open then
                        reaper.ImGui_Dummy(ctx, 0, 6)
                        reaper.ImGui_SetCursorPosX(ctx, rt_pad)
                        reaper.ImGui_PushFont(ctx, bold_font, 16)
                        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xCCCCCCFF)
                        reaper.ImGui_Text(ctx, T("modal_rename_ttl"))
                        reaper.ImGui_PopStyleColor(ctx, 1)
                        reaper.ImGui_PopFont(ctx)

                        reaper.ImGui_Dummy(ctx, 0, 6)
                        reaper.ImGui_SetCursorPosX(ctx, rt_pad)
                        reaper.ImGui_SetNextItemWidth(ctx, rt_win_w - rt_pad * 2)
                        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), 8, 9)
                        reaper.ImGui_PushFont(ctx, tab_font, 15)

                        if reaper.ImGui_IsWindowAppearing(ctx) then
                            reaper.ImGui_SetKeyboardFocusHere(ctx)
                        end

                        local _, new_name = reaper.ImGui_InputText(ctx, "##rename_task_input", rename_task_buf)
                        if reaper.ImGui_IsItemActive(ctx) then
                            rename_task_buf = new_name
                        end

                        local enter_confirm = reaper.ImGui_IsItemFocused(ctx)
                            and reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Enter())

                        reaper.ImGui_PopFont(ctx)
                        reaper.ImGui_PopStyleVar(ctx)

                        reaper.ImGui_Dummy(ctx, 0, 6)

                        local total_btns_w = rt_btn_w * 2 + rt_btn_gap
                        reaper.ImGui_SetCursorPosX(ctx, (rt_win_w - total_btns_w) * 0.5)

                        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x1E3D1EFF)
                        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0x2E6B2EFF)
                        reaper.ImGui_PushFont(ctx, bold_font, 14)
                        local do_rename = reaper.ImGui_Button(ctx, T("btn_save") .. "##rename_task_ok", rt_btn_w, rt_btn_h)
                            or enter_confirm
                        reaper.ImGui_PopFont(ctx)
                        reaper.ImGui_PopStyleColor(ctx, 2)

                        if do_rename then
                            local trimmed = rename_task_buf:match("^%s*(.-)%s*$")
                            if trimmed and trimmed ~= "" and rename_task_index then
                                local old_name = pomo.tasks[rename_task_index]
                                pomo.tasks[rename_task_index] = trimmed
                                if old_name then
                                    for _, e in ipairs(pomo.session_log) do
                                        if e.task_name == old_name then
                                            e.task_name = trimmed
                                        end
                                    end
                                end
                                save_data()
                            end
                            rename_task_index = nil
                            rename_task_buf   = ""
                            reaper.ImGui_CloseCurrentPopup(ctx)
                        end

                        reaper.ImGui_SameLine(ctx, nil, rt_btn_gap)
                        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), th.MAIN)

                        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), GetGeneralColorHEX())
                        reaper.ImGui_PushFont(ctx, bold_font, 14)
                        if reaper.ImGui_Button(ctx, T("btn_cancel") .. "##rename_task_cancel", rt_btn_w, rt_btn_h) then
                            rename_task_index = nil
                            rename_task_buf   = ""
                            reaper.ImGui_CloseCurrentPopup(ctx)
                        end
                        reaper.ImGui_PopFont(ctx)
                        reaper.ImGui_PopStyleColor(ctx, 2)

                        reaper.ImGui_EndPopup(ctx)
                    elseif not reaper.ImGui_IsPopupOpen(ctx, "RenameTask") and rename_task_index ~= nil then
                        rename_task_index = nil
                        rename_task_buf   = ""
                    end
                end

                reaper.ImGui_Dummy(ctx, 0, 10)
                reaper.ImGui_SetCursorPosX(ctx, 16)
                reaper.ImGui_Separator(ctx)
                
                
                reaper.ImGui_PushFont(ctx, tab_font, 18)
                
                local total_work_min = math.floor(pomo.total_work_sec / 60)
                local stat_str = string.format(T("stat_fmt"), pomo.completed, total_work_min)
                local stw = reaper.ImGui_CalcTextSize(ctx, stat_str)
                reaper.ImGui_SetCursorPosX(ctx, (avail_w - stw) * 0.5)
                reaper.ImGui_TextColored(ctx, th.MAIN, stat_str)
                reaper.ImGui_PopFont(ctx) 

                reaper.ImGui_Dummy(ctx, 0, 6)

                -- ======= TASKS DIAGRAM =======
                if #pomo.session_log > 0 and not reaper.ImGui_IsPopupOpen(ctx, "RenameTask") then
                    local task_time  = {}
                    local task_count = {}
                    local task_order = {}
                    for _, e in ipairs(pomo.session_log) do
                        if e.mode == "work" then
                            local key = (e.task_name and e.task_name ~= "") and e.task_name or T("lbl_no_task_key")
                            if not task_time[key] then
                                task_time[key]  = 0
                                task_count[key] = 0
                                table.insert(task_order, key)
                            end
                            task_time[key]  = task_time[key] + (e.duration_sec or 0)
                            task_count[key] = task_count[key] + 1
                        end
                    end

                    local total_sec = 0
                    for _, k in ipairs(task_order) do total_sec = total_sec + task_time[k] end

                    if total_sec > 0 and #task_order > 0 then
                        local sector_colors    = {
                            0xE76F51FF, 0x6BCB77FF, 0x4D96FFFF, 0xFFD93DFF,
                            0xC77DFFFF, 0xFF9A3CFF, 0x4ECDC4FF, 0xF72585FF,
                            0x7B9E87FF, 0xE9C46AFF, 0x52B788FF, 0xFF6B6BFF,
                            0xa024bfFF, 0x176bc2FF, 0x164371FF, 0x711616FF,
                        }

                        local chart_avail_w    = reaper.ImGui_GetContentRegionAvail(ctx)
                        local pad_side         = 14
                        local radius           = math.min((chart_avail_w - pad_side * 2) * 0.45, 130)
                        local seg_count        = 160
                        local cx_off           = chart_avail_w * 0.5
                        local cy_extra         = radius + 20

                        local leg_line_h       = 25
                        local leg_pad          = 16
                        local leg_total_h      = #task_order * (leg_line_h + 3) + 10
                        local chart_h          = radius * 2 + 40 + leg_total_h

                        local cur_x, cur_y     = reaper.ImGui_GetCursorScreenPos(ctx)
                        local scr_cx           = cur_x + cx_off
                        local scr_cy           = cur_y + cy_extra
                        local dl               = reaper.ImGui_GetWindowDrawList(ctx)
                        local mouse_x, mouse_y = reaper.ImGui_GetMousePos(ctx)
                        local mouse_clicked    = reaper.ImGui_IsMouseClicked(ctx, 0)

                        local visible_sec      = 0
                        for _, key in ipairs(task_order) do
                            if not pomo.hidden_sectors[key] then
                                visible_sec = visible_sec + task_time[key]
                            end
                        end
                        if visible_sec == 0 then visible_sec = 1 end

                        local sectors = {}
                        local angle   = -math.pi * 0.5
                        for si, key in ipairs(task_order) do
                            if not pomo.hidden_sectors[key] then
                                local frac  = task_time[key] / visible_sec
                                local sweep = frac * math.pi * 2
                                table.insert(sectors, {
                                    key           = key,
                                    frac          = frac,
                                    frac_of_total = task_time[key] / total_sec,
                                    sweep         = sweep,
                                    a_start       = angle,
                                    a_end         = angle + sweep,
                                    color         = sector_colors[((si - 1) % #sector_colors) + 1],
                                    dur_sec       = task_time[key],
                                    count         = task_count[key],
                                    orig_idx      = si,
                                })
                                angle = angle + sweep
                            end
                        end

                        local TWO_PI = math.pi * 2
                        local function norm_angle(a)
                            return ((a % TWO_PI) + TWO_PI) % TWO_PI
                        end

                        local hovered_sector = nil
                        local dx0            = mouse_x - scr_cx
                        local dy0            = mouse_y - scr_cy
                        local dist0          = math.sqrt(dx0 * dx0 + dy0 * dy0)
                        if dist0 >= radius * 0.36 and dist0 <= radius + 10 then
                            local m = norm_angle(math.atan(dy0, dx0))
                            for si, s in ipairs(sectors) do
                                local a_s = norm_angle(s.a_start)
                                local a_e = norm_angle(s.a_end)
                                local inside
                                if a_s <= a_e then
                                    inside = (m >= a_s and m <= a_e)
                                else
                                    inside = (m >= a_s or m <= a_e)
                                end
                                if inside then
                                    hovered_sector = si; break
                                end
                            end
                        end

                        local leg_top_scr_y = cur_y + radius * 2 + 40
                        local hovered_leg   = nil
                        for oi, key in ipairs(task_order) do
                            local row_y = leg_top_scr_y + (oi - 1) * (leg_line_h + 3)
                            if mouse_x >= cur_x + leg_pad - 4
                                and mouse_x <= cur_x + chart_avail_w - leg_pad
                                and mouse_y >= row_y
                                and mouse_y <= row_y + leg_line_h then
                                hovered_leg = oi
                                if not pomo.hidden_sectors[key] then
                                    for si, s in ipairs(sectors) do
                                        if s.key == key then
                                            if hovered_sector == nil then
                                                hovered_sector = si
                                            end
                                            break
                                        end
                                    end
                                end
                                if mouse_clicked then
                                    if pomo.hidden_sectors[key] then
                                        pomo.hidden_sectors[key] = nil
                                    else
                                        pomo.hidden_sectors[key] = true
                                    end
                                end
                                break
                            end
                        end

                        reaper.ImGui_DrawList_AddCircleFilled(dl, scr_cx + 5, scr_cy + 5, radius, 0x1111150, seg_count)

                        for si, s in ipairs(sectors) do
                            local is_hov = (hovered_sector == si)
                            local r_draw = is_hov and (radius + 8) or radius
                            local col    = is_hov and ((s.color & 0xFFFFFF00) | 0xFF) or s.color
                            local steps  = math.max(4, math.floor(s.sweep * seg_count / (math.pi * 2)))
                            for i = 0, steps - 1 do
                                local a1 = s.a_start + s.sweep * (i / steps)
                                local a2 = s.a_start + s.sweep * ((i + 1) / steps)
                                reaper.ImGui_DrawList_AddTriangleFilled(dl,
                                    scr_cx, scr_cy,
                                    scr_cx + math.cos(a1) * r_draw, scr_cy + math.sin(a1) * r_draw,
                                    scr_cx + math.cos(a2) * r_draw, scr_cy + math.sin(a2) * r_draw,
                                    col)
                            end
                            reaper.ImGui_DrawList_AddLine(dl,
                                scr_cx, scr_cy,
                                scr_cx + math.cos(s.a_start) * r_draw,
                                scr_cy + math.sin(s.a_start) * r_draw,
                                0x1A1A1AFF, 1.5)
                        end

                        for si, s in ipairs(sectors) do
                            if s.frac >= 0.06 then
                                local mid_a   = s.a_start + s.sweep * 0.5
                                local lbl_r   = radius * 0.65
                                local lx      = scr_cx + math.cos(mid_a) * lbl_r
                                local ly      = scr_cy + math.sin(mid_a) * lbl_r
                                local pct_str = string.format("%d%%", math.floor(s.frac * 100 + 0.5))
                                reaper.ImGui_PushFont(ctx, bold_font, 13)
                                local tw2 = reaper.ImGui_CalcTextSize(ctx, pct_str)
                                reaper.ImGui_DrawList_AddText(dl, lx - tw2 * 0.5 + 1, ly - 7 + 1, 0x000000AA, pct_str)
                                reaper.ImGui_DrawList_AddText(dl, lx - tw2 * 0.5, ly - 7, 0xFFFFFFEE, pct_str)
                                reaper.ImGui_PopFont(ctx)
                            end
                        end

                        if #sectors == 0 then
                            reaper.ImGui_DrawList_AddCircleFilled(dl, scr_cx, scr_cy, radius, 0x222222FF, seg_count)
                            reaper.ImGui_PushFont(ctx, tab_font, 12)
                            local hint_c = T("lbl_all_hidden")
                            local hw = reaper.ImGui_CalcTextSize(ctx, hint_c)
                            reaper.ImGui_DrawList_AddText(dl, scr_cx - hw * 0.5, scr_cy - 7, 0x555555FF, hint_c)
                            reaper.ImGui_PopFont(ctx)
                        end

                        local hole_r = radius * 0.4
                        reaper.ImGui_DrawList_AddCircleFilled(dl, scr_cx, scr_cy, hole_r, 0x1A1A1AFF, seg_count)
                        reaper.ImGui_DrawList_AddCircle(dl, scr_cx, scr_cy, hole_r, 0x333333FF, seg_count, 1.5)

                        local total_min_c = math.floor(total_sec / 60)
                        local total_ses_c = 0
                        for _, s in ipairs(sectors) do total_ses_c = total_ses_c + s.count end
                        reaper.ImGui_PushFont(ctx, bold_font, 13)
                        local c1  = tostring(total_min_c) .. T("lbl_min")
                        local c1w = reaper.ImGui_CalcTextSize(ctx, c1)
                        reaper.ImGui_DrawList_AddText(dl, scr_cx - c1w * 0.5, scr_cy - 17, 0xCCCCCCFF, c1)
                        reaper.ImGui_PopFont(ctx)
                        reaper.ImGui_PushFont(ctx, tab_font, 11)
                        local c2  = T("lbl_work_time")
                        local c2w = reaper.ImGui_CalcTextSize(ctx, c2)
                        reaper.ImGui_DrawList_AddText(dl, scr_cx - c2w * 0.5, scr_cy - 3, 0x666666FF, c2)
                        local c3  = string.format(T("lbl_sessions"), total_ses_c)
                        local c3w = reaper.ImGui_CalcTextSize(ctx, c3)
                        reaper.ImGui_DrawList_AddText(dl, scr_cx - c3w * 0.5, scr_cy + 10, 0x555555FF, c3)
                        reaper.ImGui_PopFont(ctx)

                        reaper.ImGui_Dummy(ctx, chart_avail_w, radius * 2 + 0)

                        for oi, key in ipairs(task_order) do
                            local si_color  = ((oi - 1) % #sector_colors) + 1
                            local row_color = sector_colors[si_color]
                            local is_hidden = pomo.hidden_sectors[key] == true
                            local is_hov_l  = (hovered_leg == oi)

                            local row_scr_y = leg_top_scr_y + (oi - 1) * (leg_line_h + 3)
                            local dur_m     = math.floor(task_time[key] / 60)
                            local pct_l     = string.format("%.1f%%", task_time[key] / total_sec * 100)

                            if is_hov_l then
                                reaper.ImGui_DrawList_AddRectFilled(dl,
                                    cur_x + leg_pad - 4, row_scr_y,
                                    cur_x + chart_avail_w - leg_pad, row_scr_y + leg_line_h,
                                    0x33333355, 4)
                            end

                            local sq_col = is_hidden and 0x444444FF or row_color
                            reaper.ImGui_DrawList_AddRectFilled(dl,
                                cur_x + leg_pad, row_scr_y + 5,
                                cur_x + leg_pad + 13, row_scr_y + 18,
                                sq_col, 3)
                            if is_hidden then
                                reaper.ImGui_DrawList_AddLine(dl,
                                    cur_x + leg_pad, row_scr_y + 5,
                                    cur_x + leg_pad + 13, row_scr_y + 18, 0x666666FF, 1)
                                reaper.ImGui_DrawList_AddLine(dl,
                                    cur_x + leg_pad + 13, row_scr_y + 5,
                                    cur_x + leg_pad, row_scr_y + 18, 0x666666FF, 1)
                            end

                            local dur_s_rem = task_time[key] % 60
                            local leg_str = string.format(T("leg_fmt"),
                                key, pct_l, task_count[key], dur_m)
                            reaper.ImGui_PushFont(ctx, tab_font, 13)
                            local max_w = chart_avail_w - leg_pad * 2 - 18
                            while #leg_str > 6 and reaper.ImGui_CalcTextSize(ctx, leg_str) > max_w do
                                leg_str = leg_str:sub(1, -2)
                            end
                            reaper.ImGui_PopFont(ctx)

                            local txt_col
                            if is_hidden then
                                txt_col = 0x444444FF
                            elseif is_hov_l then
                                txt_col = 0xFFFFFFFF
                            else
                                txt_col = 0x888888FF
                            end
                            reaper.ImGui_PushFont(ctx, tab_font, 12)
                            reaper.ImGui_DrawList_AddText(dl,
                                cur_x + leg_pad + 16, row_scr_y + 3, txt_col, leg_str)
                            reaper.ImGui_PopFont(ctx)

                            if is_hov_l then
                                local hint_s = is_hidden and T("lbl_show") or T("lbl_hide")
                                reaper.ImGui_PushFont(ctx, tab_font, 11)
                                local hint_w = reaper.ImGui_CalcTextSize(ctx, hint_s)
                                reaper.ImGui_DrawList_AddText(dl,
                                    cur_x + chart_avail_w - leg_pad - hint_w - 4,
                                    row_scr_y + 5,
                                    0x555555FF, hint_s)
                                reaper.ImGui_PopFont(ctx)
                            end

                            reaper.ImGui_InvisibleButton(ctx, "##leg" .. oi,
                                chart_avail_w - leg_pad * 2, leg_line_h)
                            reaper.ImGui_Dummy(ctx, 0, 3)
                        end

                        if hovered_sector and sectors[hovered_sector] then
                            local s      = sectors[hovered_sector]
                            local dur_m2 = math.floor(s.dur_sec / 60)
                            local dur_s2 = s.dur_sec % 60
                            local pct2   = string.format("%.1f%%", s.frac_of_total * 100)
                            reaper.ImGui_BeginTooltip(ctx)
                            reaper.ImGui_PushFont(ctx, bold_font, 14)
                            reaper.ImGui_TextColored(ctx, s.color,
                                string.format("%s  (%s)", s.key, pct2))
                            reaper.ImGui_PopFont(ctx)
                            reaper.ImGui_Separator(ctx)
                            reaper.ImGui_PushFont(ctx, tab_font, 12)
                            reaper.ImGui_TextColored(ctx, 0xAAAAAAFF,
                                string.format(T("tip_time"), dur_m2, dur_s2))
                            reaper.ImGui_TextColored(ctx, 0xAAAAAAFF,
                                string.format(T("tip_sessions"), s.count))
                            reaper.ImGui_TextColored(ctx, 0xAAAAAAFF,
                                string.format(T("tip_share"), pct2))
                            reaper.ImGui_PopFont(ctx)
                            reaper.ImGui_EndTooltip(ctx)
                        end

                        reaper.ImGui_Dummy(ctx, 0, 8)
                    end
                end

                if #pomo.session_log > 0 then
                    reaper.ImGui_Dummy(ctx, 0, 8)
                    reaper.ImGui_PushFont(ctx, tab_font, 14)

                    local btn_label = string.format(T("log_toggle_fmt"), (pomo.show_log and "▼" or "▷"), #pomo.session_log)
                    local text_w = reaper.ImGui_CalcTextSize(ctx, btn_label)
                    local win_w = reaper.ImGui_GetWindowWidth(ctx)
                    reaper.ImGui_SetCursorPosX(ctx, (win_w - text_w) * 0.5)

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

                        local log_avail_w = reaper.ImGui_GetContentRegionAvail(ctx)
                        local filter_pad  = 20
                        local clear_btn_w = pomo.log_filter ~= "" and 24 or 1
                        local input_w_log = log_avail_w - filter_pad * 2 - clear_btn_w - (clear_btn_w > 0 and 6 or 0)
                        reaper.ImGui_SetCursorPosX(ctx, filter_pad)
                        reaper.ImGui_SetNextItemWidth(ctx, input_w_log)
                        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), 5, 6)
                        reaper.ImGui_PushFont(ctx, italic_font, 14)
                        local _, new_filter = reaper.ImGui_InputTextWithHint(
                            ctx, "##log_filter", T("hint_log_filter"), pomo.log_filter
                        )
                        if reaper.ImGui_IsItemActive(ctx) then
                            pomo.log_filter = new_filter
                        end
                        reaper.ImGui_PopFont(ctx)
                        reaper.ImGui_PopStyleVar(ctx)

                        if pomo.log_filter ~= "" then
                            reaper.ImGui_SameLine(ctx, nil, 6)
                            reaper.ImGui_PushFont(ctx, tab_font, 14)
                            reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), 8, 6)
                            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x1A1A1AFF)
                            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0x7A1A1AFF)
                            if reaper.ImGui_Button(ctx, "✕##clear_log_filter") then
                                pomo.log_filter = ""
                            end
                            reaper.ImGui_PopStyleColor(ctx, 2)
                            reaper.ImGui_PopFont(ctx)
                            reaper.ImGui_PopStyleVar(ctx)
                        end

                        reaper.ImGui_Dummy(ctx, 0, 4)

                        local filter_lc    = utf8_to_lower(pomo.log_filter)
                        local filtered_log = {}
                        for li = #pomo.session_log, 1, -1 do
                            local e = pomo.session_log[li]
                            if filter_lc == "" then
                                table.insert(filtered_log, e)
                            else
                                local mode_lbl = e.mode == "work" and "pomodoro"
                                    or e.mode == "short_break" and utf8_to_lower(T("lbl_short_break"))
                                    or utf8_to_lower(T("lbl_long_break"))
                                local haystack = utf8_to_lower(mode_lbl
                                    .. " " .. (e.task_name or "")
                                    .. " " .. e.completed_at)
                                if haystack:find(filter_lc, 1, true) then
                                    table.insert(filtered_log, e)
                                end
                            end
                        end

                        local log_h = math.max(60, math.min(220, #filtered_log * 52 + 10))
                        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ChildBg(), th.FRAME)
                        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ChildRounding(), 8.0)
                        if reaper.ImGui_BeginChild(ctx, "##pomo_log", log_avail_w - 15, log_h, 1) then
                            if #filtered_log == 0 then
                                reaper.ImGui_Dummy(ctx, 0, 8)
                                reaper.ImGui_PushFont(ctx, tab_font, 13)
                                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0x444444FF)
                                local no_msg = T("log_nothing")
                                reaper.ImGui_SetCursorPosX(ctx,
                                    (log_avail_w - reaper.ImGui_CalcTextSize(ctx, no_msg)) * 0.5)
                                reaper.ImGui_Text(ctx, no_msg)
                                reaper.ImGui_PopStyleColor(ctx, 1)
                                reaper.ImGui_PopFont(ctx)
                            else
                                for _, entry in ipairs(filtered_log) do
                                    local dur_min = math.floor(entry.duration_sec / 60)
                                    local mode_lbl_log = entry.mode == "work" and "Pomodoro"
                                        or entry.mode == "short_break" and T("lbl_short_break")
                                        or T("lbl_long_break")

                                    local lline1
                                    if entry.task_name and entry.task_name ~= "" then
                                        lline1 = string.format("  %s [%s] — %d хв",
                                            mode_lbl_log, entry.task_name, dur_min)
                                    else
                                        lline1 = string.format("  %s — %d хв", mode_lbl_log, dur_min)
                                    end
                                    local lline2 = "  " .. entry.completed_at

                                    reaper.ImGui_PushFont(ctx, tab_font, 15)
                                    reaper.ImGui_TextColored(ctx, th.TEXT, lline1)
                                    reaper.ImGui_PopFont(ctx)

                                    reaper.ImGui_PushFont(ctx, tab_font, 12)
                                    reaper.ImGui_TextColored(ctx, th.MAIN, lline2)
                                    reaper.ImGui_PopFont(ctx)

                                    reaper.ImGui_Dummy(ctx, 0, 2)
                                end
                            end
                            reaper.ImGui_EndChild(ctx)
                        end
                        reaper.ImGui_PopStyleColor(ctx, 1)
                        reaper.ImGui_PopStyleVar(ctx)

                        reaper.ImGui_Dummy(ctx, 0, 8)
                        reaper.ImGui_SetCursorPosX(ctx, filter_pad)
                        reaper.ImGui_PushFont(ctx, tab_font, 14)
                        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), th.FRAME)
                        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), GetGeneralColorHEX())
                        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), th.FRAME)
                        local save_lbl = (pomo.log_filter ~= "")
                            and T("btn_save_log_flt")
                            or T("btn_save_log")
                        if reaper.ImGui_Button(ctx, save_lbl .. "##save_log", log_avail_w - filter_pad * 2 - 15, 40) then
                            if reaper.JS_Dialog_BrowseForSaveFile then
                                local def_path = reaper.GetProjectPath("") .. "/pomodoro_log.txt"
                                local ok, filepath = reaper.JS_Dialog_BrowseForSaveFile(
                                    T("btn_save_log"), def_path, "pomodoro_log.txt",
                                    "Text files (*.txt)\0*.txt\0All files (*.*)\0*.*\0"
                                )
                                if ok == 1 and filepath ~= "" then
                                    if not filepath:match("%.txt$") then
                                        filepath = filepath .. ".txt"
                                    end
                                    local lines = {}
                                    if pomo.log_filter ~= "" then
                                        table.insert(lines, T("lbl_filter_prefix") .. pomo.log_filter)
                                        table.insert(lines, string.rep("-", 40))
                                    end
                                    table.insert(lines, T("log_header"))
                                    table.insert(lines, string.rep("=", 40))
                                    for _, entry in ipairs(filtered_log) do
                                        local dur_min = math.floor(entry.duration_sec / 60)
                                        local mode_lbl_log = entry.mode == "work" and "Pomodoro"
                                            or entry.mode == "short_break" and T("lbl_short_break")
                                            or T("lbl_long_break")
                                        local l1
                                        if entry.task_name and entry.task_name ~= "" then
                                            l1 = string.format("%s [%s] — %d хв", mode_lbl_log, entry.task_name, dur_min)
                                        else
                                            l1 = string.format("%s — %d хв", mode_lbl_log, dur_min)
                                        end
                                        table.insert(lines, l1)
                                        table.insert(lines, entry.completed_at)
                                        table.insert(lines, "")
                                    end
                                    local f = io.open(filepath, "w")
                                    if f then
                                        f:write(table.concat(lines, "\n"))
                                        f:close()
                                    end
                                end
                            end
                        end
                        reaper.ImGui_PopStyleColor(ctx, 3)
                        reaper.ImGui_PopFont(ctx)

                        reaper.ImGui_Dummy(ctx, 0, 14)
                    end
                end
                -- ======= SETTINGS BUTTON =======
                reaper.ImGui_Dummy(ctx, 0, 8)
                reaper.ImGui_PushFont(ctx, tab_font, 14)

                local settings_label = string.format(T("settings_toggle"), (pomo.show_settings and "▼" or "▷"))
                local stw2, sth2 = reaper.ImGui_CalcTextSize(ctx, settings_label)
                local win_w2 = reaper.ImGui_GetWindowWidth(ctx)
                local center_pos2 = (win_w2 - stw2) * 0.5

                reaper.ImGui_SetCursorPosX(ctx, center_pos2)

                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x17171700)
                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), 0x171717FF)
                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0x33333333)
                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0x666666FF)

                if reaper.ImGui_Button(ctx, settings_label) then
                    pomo.show_settings = not pomo.show_settings
                end

                reaper.ImGui_PopStyleColor(ctx, 4)
                reaper.ImGui_PopFont(ctx)

                if pomo.show_settings then
                    reaper.ImGui_Dummy(ctx, 0, 4)
                    local settings_h = 315
                    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ChildBg(), th.FRAME)
                    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ChildRounding(), 8.0)
                    if reaper.ImGui_BeginChild(ctx, "##pomo_settings", avail_w - 15, settings_h, 1) then
                        reaper.ImGui_Dummy(ctx, 0, 8)
                        reaper.ImGui_PushFont(ctx, tab_font, 14)
                        reaper.ImGui_SeparatorText(ctx, T("settings_dur"))
                        reaper.ImGui_PopFont(ctx)

                        local slider_w = avail_w - 210
                        reaper.ImGui_SetNextItemWidth(ctx, slider_w)
                        local ch1, nv1 = reaper.ImGui_SliderInt(ctx, "Pomodoro##twork", pomo.edit_work, 1, 60)
                        if ch1 then
                            pomo.edit_work     = nv1
                            pomo.work_duration = nv1 * 60
                            if pomo.mode == "work" and pomo.state == "idle" then
                                pomo.remaining = pomo.work_duration
                            end
                            save_data()
                        end

                        reaper.ImGui_SetNextItemWidth(ctx, slider_w)
                        local ch2, nv2 = reaper.ImGui_SliderInt(ctx, T("lbl_short_break") .. "##tshort", pomo.edit_short, 1, 30)
                        if ch2 then
                            pomo.edit_short  = nv2
                            pomo.short_break = nv2 * 60
                            if pomo.mode == "short_break" and pomo.state == "idle" then
                                pomo.remaining = pomo.short_break
                            end
                            save_data()
                        end

                        reaper.ImGui_SetNextItemWidth(ctx, slider_w)
                        local ch3, nv3 = reaper.ImGui_SliderInt(ctx, T("lbl_long_break") .. "##tlong", pomo.edit_long, 5, 60)
                        if ch3 then
                            pomo.edit_long  = nv3
                            pomo.long_break = nv3 * 60
                            if pomo.mode == "long_break" and pomo.state == "idle" then
                                pomo.remaining = pomo.long_break
                            end
                            save_data()
                        end

                        reaper.ImGui_SetNextItemWidth(ctx, slider_w)
                        local ch4, nv4 = reaper.ImGui_SliderInt(ctx, T("lbl_long_break") .. " after (Pomodoro)##tevery",
                            pomo.long_break_every, 2, 8)
                        if ch4 then
                            pomo.long_break_every = nv4
                            save_data()
                        end

                        reaper.ImGui_Separator(ctx)
                        reaper.ImGui_PushFont(ctx, tab_font, 14)
                        reaper.ImGui_SeparatorText(ctx, T("settings_opts"))
                        reaper.ImGui_PopFont(ctx)

                        local ca, av = reaper.ImGui_Checkbox(ctx, T("chk_autostart") .. "##tauto", pomo.auto_start)
                        if ca then
                            pomo.auto_start = av; save_data()
                        end

                        local cs, sv = reaper.ImGui_Checkbox(ctx, T("chk_sound") .. "##tsound", pomo.sound_enabled)
                        if cs then
                            pomo.sound_enabled = sv; save_data()
                        end

                        reaper.ImGui_Separator(ctx)
                        if not pomo.confirm_clear then
                            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), th.BG)
                            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), GetGeneralColorHEX())
                            reaper.ImGui_Dummy(ctx, 0, 8)
                            reaper.ImGui_PushFont(ctx, bold_font, 16)
                            if reaper.ImGui_Button(ctx, T("btn_clear") .. "##tclear", avail_w - 30, 40) then
                                pomo.confirm_clear = true
                            end
                            reaper.ImGui_PopFont(ctx)
                            reaper.ImGui_PopStyleColor(ctx, 2)
                        else
                            reaper.ImGui_PushFont(ctx, bold_font, 14)
                            reaper.ImGui_TextColored(ctx, GetGeneralColorHEX(), T("confirm_clear_q"))
                            reaper.ImGui_PopFont(ctx)
                            reaper.ImGui_Dummy(ctx, 0, 2)
                            local half_w = (avail_w - 45) * 0.5
                            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(),              th.ACCENT)
                            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x551111FF)
                            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0xAA2222FF)
                            reaper.ImGui_PushFont(ctx, bold_font, 14)
                            if reaper.ImGui_Button(ctx, T("btn_yes_clear") .. "##tconfirm", half_w, 26) then
                                pomo.session_log    = {}
                                pomo.completed      = 0
                                pomo.total_work_sec = 0
                                pomo.confirm_clear  = false
                                save_data()
                            end
                            reaper.ImGui_PopFont(ctx)
                            reaper.ImGui_PopStyleColor(ctx, 2)
                            reaper.ImGui_SameLine(ctx, nil, 8)
                            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x1A1A1AFF)
                            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), GetGeneralColorHEX())
                            reaper.ImGui_PushFont(ctx, bold_font, 14)
                            if reaper.ImGui_Button(ctx, T("btn_cancel") .. "##tcancel", half_w, 26) then
                                pomo.confirm_clear = false
                            end
                            reaper.ImGui_PopFont(ctx)
                            reaper.ImGui_PopStyleColor(ctx, 3)
                        end
                        reaper.ImGui_Dummy(ctx, 0, 6)
                        reaper.ImGui_EndChild(ctx)
                    end
                    reaper.ImGui_PopStyleVar(ctx)
                    reaper.ImGui_PopStyleColor(ctx, 1)
                    reaper.ImGui_Dummy(ctx, 0, 10)
                end
                reaper.ImGui_Dummy(ctx, 0, 10)
                reaper.ImGui_EndChild(ctx)
        end

        --================ GLOBAL NOTIFICATION POMODORO =================
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
                local ny     = win_y + 50
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
