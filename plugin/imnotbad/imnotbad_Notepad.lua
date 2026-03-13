-------------------------------------------------------------------
-- imnotbad_Notepad.lua
-- Notepad by imnotbad
-- @version 1.2
-- @author imnotbad
-------------------------------------------------------------------

local _early_lang = reaper.GetExtState("imnotbad_Notepad", "language")
if _early_lang ~= "en" and _early_lang ~= "es" then _early_lang = "uk" end

local _WARN = {
    uk = {
        no_imgui_msg   = "Встановіть ReaImGui через ReaPack",
        no_imgui_title = "Помилка",
        no_js_msg      = "Встановіть JS_ReaScriptAPI через ReaPack.",
        no_js_title    = "Попередження",
        no_sws_msg     = "Розширення SWS/S&M не виявлено.\n\nДеякі функції скрипта можуть не працювати.\nВстановіть SWS/S&M через ReaPack:\nExtensions → ReaPack → Browse packages → SWS/S&M",
        no_sws_title   = "Попередження: відсутній SWS/S&M",
        err_save_msg   = "Помилка при збереженні файлу!",
        err_save_title = "Помилка",
        err_read_msg   = "Помилка при читанні файлу!",
        err_read_title = "Помилка",
        dlg_save_as    = "Зберегти як",
        dlg_import     = "Імпортувати текстовий файл",
        import_default = "Імпорт",
    },
    en = {
        no_imgui_msg   = "Please install ReaImGui via ReaPack",
        no_imgui_title = "Error",
        no_js_msg      = "Please install JS_ReaScriptAPI via ReaPack.",
        no_js_title    = "Warning",
        no_sws_msg     = "SWS/S&M extension not found.\n\nSome script features may not work.\nInstall SWS/S&M via ReaPack:\nExtensions → ReaPack → Browse packages → SWS/S&M",
        no_sws_title   = "Warning: SWS/S&M missing",
        err_save_msg   = "Error saving file!",
        err_save_title = "Error",
        err_read_msg   = "Error reading file!",
        err_read_title = "Error",
        dlg_save_as    = "Save as",
        dlg_import     = "Import text file",
        import_default = "Import",
    },
    es = {
        no_imgui_msg   = "Por favor instala ReaImGui mediante ReaPack",
        no_imgui_title = "Error",
        no_js_msg      = "Por favor instala JS_ReaScriptAPI mediante ReaPack.",
        no_js_title    = "Advertencia",
        no_sws_msg     = "Extensión SWS/S&M no encontrada.\n\nAlgunas funciones pueden no funcionar.\nInstala SWS/S&M mediante ReaPack:\nExtensions → ReaPack → Browse packages → SWS/S&M",
        no_sws_title   = "Advertencia: falta SWS/S&M",
        err_save_msg   = "¡Error al guardar el archivo!",
        err_save_title = "Error",
        err_read_msg   = "¡Error al leer el archivo!",
        err_read_title = "Error",
        dlg_save_as    = "Guardar como",
        dlg_import     = "Importar archivo de texto",
        import_default = "Importar",
    },
}
local _W = _WARN[_early_lang]

if not reaper.ImGui_CreateContext then
    reaper.ShowMessageBox(_W.no_imgui_msg, _W.no_imgui_title, 0)
    return
end

if not reaper.JS_Dialog_BrowseForSaveFile then
    reaper.ShowMessageBox(_W.no_js_msg, _W.no_js_title, 0)
end

if not reaper.BR_GetMediaTrackByGUID then
    reaper.ShowMessageBox(_W.no_sws_msg, _W.no_sws_title, 0)
end
--==============================================================
-- Контекст і дані
--==============================================================
local ctx = reaper.ImGui_CreateContext("Notepad v1.2")

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

local notepad_open              = true
local tabs                      = {}
local active_tab_index          = 1
local pending_active_tab        = nil
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
local save_file                 = script_path .. "imnotbad_Notepad_Data.txt"
local current_language          = "uk"

local LANG = {
    uk = {
        menu_file         = "Файл",
        menu_new_tab      = "Новий блокнот",
        menu_export       = "Експорт",
        menu_import       = "Імпорт",
        menu_view         = "Вигляд",
        menu_font_size    = "Розмір шрифту:",
        menu_font_type    = "Шрифт:",
        menu_ui_color     = "Тема:",
        menu_reset_color  = "Скинути колір",
        menu_theme        = "Тема:",
        theme_dark        = "Темна",
        theme_light       = "Світла",
        theme_blue        = "Синя",
        theme_red         = "Червона",
        theme_yellow      = "Жовта",
        menu_language     = "Мова",
        menu_lang_uk      = "Українська",
        menu_lang_en      = "English",
        menu_lang_es      = "Español",
        menu_help         = "Довідка",
        menu_close        = "Закрити",
        help_general      = "Загальні:",
        help_1            = "• Для зміни назви блокнота зробіть подвійний клік на Tab",
        help_2            = "• Для збереження назви блокнота натисніть Enter",
        help_3            = "• Для редагування блокнота зробіть подвійний клік всередині Tab",
        help_4            = "• В режимі редагування блокнота зробіть правий клік \n   і натисніть 'Імпортувати макрери'",
        help_5            = "• Для збереження блокнота натисніть Ctrl+S",
        help_markdown     = "Markdown:",
        help_styles       = "Стилі для виділення:",
        help_line_start   = "На початку рядка:",
        tab_new_name      = "Записник",
        tab_empty_hint    = "Подвійний клік, щоб створити нотатку",
        confirm_delete    = "Видалити",
        confirm_cancel    = "Скасувати",
        confirm_msg       = "Видалити",
        export_label      = "Експорт",
        import_label      = "Імпорт",
        export_format     = "Формат:",
        import_format     = "Формат:",
        btn_export        = "Експортувати",
        btn_import        = "Імпортувати",
        ctx_import_markers = "Імпортувати маркери",
        ctx_copy          = "Копіювати",
        ctx_paste         = "Вставити",
        ctx_cut           = "Вирізати",
        ctx_select_all    = "Виділити все",
        menu_save_notepad = "Зберегти Notepad",
        menu_open_txt     = "Відкрити тектстовий документ",
        menu_save_txt     = "Зберегти в тектстовому документі",
        menu_autostart    = "Автозапуск при старті REAPER",
        menu_close_notepad = "Закрити Notepad",
        help_md_italic     = "• *Курсив*",
        help_md_bold       = "• **Жирний**",
        help_md_underline  = "• __Підкреслений__",
        help_md_cell       = "• |Комірка|",
        help_md_all        = "• __***Жирний + Курсив + Підкреслений***__",
        help_md_h1         = "• # Заголовок 1",
        help_md_h2         = "• ## Заголовок 2",
        help_md_h3         = "• ### Заголовок 3",
        help_md_cb_empty   = "• [ ] Чекбокс",
        help_md_cb_done    = "• [x] Чекбокс",
        help_md_timing     = "• [00:00.000] Таймінг",
        help_md_divider    = "• --- Розділова лінія",
        -- toolbar
        tb_divider         = "Розділова лінія",
        tb_bold            = "Жирний",
        tb_italic          = "Курсив",
        tb_underline       = "Підкреслення",
        tb_table           = "Таблиця",
        tb_h1              = "Заголовок 1",
        tb_h2              = "Заголовок 2",
        tb_h3              = "Заголовок 3",
        tb_checkbox        = "Чекбокс",
        -- search
        search_hint        = "Пошук (Ctrl+F)",
        search_clear       = "Очистити пошук",
        search_prev        = "Попередній збіг",
        search_next        = "Наступний збіг",
        rename_hint        = "Натисніть Enter",
        -- edit mode
        edit_mode_label    = "Редагування:",
        btn_save           = "Зберегти",
        hint_dbl_click     = "Подвійний клік для редагування",
        -- context menu
        ctx_delete         = "Видалити",
        ctx_ctrl_s         = "Ctrl+S - зберегти",
        -- confirm modal
        confirm_delete_msg = "Видалити",
        confirm_question   = "?",
        btn_confirm_delete = "Видалити",
        btn_confirm_cancel = "Скасувати",
        -- empty state
        empty_hint         = "Подвійний клік, щоб створити нотатку",
        default_tab_name   = "Записник",
        welcome_content    = "# ВІТАЄМО В NOTEPAD\n*Для редагування зробіть подвійний клік.*\n*Більше інформації у вкладці \"Довідка\".*\n---\n# Заголовок 1\n## Заголовок 2\n### Заголовок 3\n---\n***ПЕРЕЛІК ЗАВДАНЬ:***\n[x] Завдання 1\n[ ] Завдання 2\n[ ] Завдання 3\n---\nЗвичайний\n**Жирний**\n*Курсив*\n__Підкреслений__\n[ ] ***__Всі стилі разом__***\n---\n|Таблиця 1|Таблиця 1|Таблиця 1|Таблиця 1|\n|Рядок 1|Рядок 1|Рядок 1|Рядок 1|\n|Рядок 2|Рядок 2|Рядок 2|Рядок 2|\n---\n*Імпорт маркерів:*\n[ ] [4:55.279] - Маркер 1\n[ ] [9:41.110] - Маркер 2\n[ ] [13:42.059] - Маркер 3\n---\nhttps://www.youtube.com/ - посилання відкриваються в браузері\n---",
    },
    en = {
        menu_file         = "File",
        menu_new_tab      = "New Notepad",
        menu_export       = "Export",
        menu_import       = "Import",
        menu_view         = "View",
        menu_font_size    = "Font size:",
        menu_font_type    = "Font:",
        menu_ui_color     = "Theme:",
        menu_reset_color  = "Reset color",
        menu_theme        = "Theme:",
        theme_dark        = "Dark",
        theme_light       = "Light",
        theme_blue        = "Blue",
        theme_red         = "Red",
        theme_yellow      = "Yellow",
        menu_language     = "Language",
        menu_lang_uk      = "Українська",
        menu_lang_en      = "English",
        menu_lang_es      = "Español",
        menu_help         = "Help",
        menu_close        = "Close",
        help_general      = "General:",
        help_1            = "• Double-click the Tab to rename the notepad",
        help_2            = "• Press Enter to save the notepad name",
        help_3            = "• Double-click inside the Tab to edit",
        help_4            = "• In edit mode, right-click \n   and select 'Import markers'",
        help_5            = "• Press Ctrl+S to save",
        help_markdown     = "Markdown:",
        help_styles       = "Inline styles:",
        help_line_start   = "At line start:",
        tab_new_name      = "Notepad",
        tab_empty_hint    = "Double-click to create a note",
        confirm_delete    = "Delete",
        confirm_cancel    = "Cancel",
        confirm_msg       = "Delete",
        export_label      = "Export",
        import_label      = "Import",
        export_format     = "Format:",
        import_format     = "Format:",
        btn_export        = "Export",
        btn_import        = "Import",
        ctx_import_markers = "Import markers",
        ctx_copy          = "Copy",
        ctx_paste         = "Paste",
        ctx_cut           = "Cut",
        ctx_select_all    = "Select all",
        menu_save_notepad = "Save Notepad",
        menu_open_txt     = "Open text document",
        menu_save_txt     = "Save to text document",
        menu_autostart    = "Auto-start with REAPER",
        menu_close_notepad = "Close Notepad",
        help_md_italic     = "• *Italic*",
        help_md_bold       = "• **Bold**",
        help_md_underline  = "• __Underline__",
        help_md_cell       = "• |Cell|",
        help_md_all        = "• __***Bold + Italic + Underline***__",
        help_md_h1         = "• # Heading 1",
        help_md_h2         = "• ## Heading 2",
        help_md_h3         = "• ### Heading 3",
        help_md_cb_empty   = "• [ ] Checkbox",
        help_md_cb_done    = "• [x] Checkbox",
        help_md_timing     = "• [00:00.000] Timing",
        help_md_divider    = "• --- Divider line",
        -- toolbar
        tb_divider         = "Divider line",
        tb_bold            = "Bold",
        tb_italic          = "Italic",
        tb_underline       = "Underline",
        tb_table           = "Table",
        tb_h1              = "Heading 1",
        tb_h2              = "Heading 2",
        tb_h3              = "Heading 3",
        tb_checkbox        = "Checkbox",
        -- search
        search_hint        = "Search (Ctrl+F)",
        search_clear       = "Clear search",
        search_prev        = "Previous match",
        search_next        = "Next match",
        rename_hint        = "Press Enter",
        -- edit mode
        edit_mode_label    = "Editing:",
        btn_save           = "Save",
        hint_dbl_click     = "Double-click to edit",
        -- context menu
        ctx_delete         = "Delete",
        ctx_ctrl_s         = "Ctrl+S - save",
        -- confirm modal
        confirm_delete_msg = "Delete",
        confirm_question   = "?",
        btn_confirm_delete = "Delete",
        btn_confirm_cancel = "Cancel",
        -- empty state
        empty_hint         = "Double-click to create a note",
        default_tab_name   = "Notepad",
        welcome_content    = "# WELCOME TO NOTEPAD\n*Double-click to edit.*\n*More info in the \"Help\" tab.*\n---\n# Heading 1\n## Heading 2\n### Heading 3\n---\n***TASK LIST:***\n[x] Task 1\n[ ] Task 2\n[ ] Task 3\n---\nNormal\n**Bold**\n*Italic*\n__Underline__\n[ ] ***__All styles combined__***\n---\n|Table 1|Table 1|Table 1|Table 1|\n|Row 1|Row 1|Row 1|Row 1|\n|Row 2|Row 2|Row 2|Row 2|\n---\n*Import markers:*\n[ ] [4:55.279] - Marker 1\n[ ] [9:41.110] - Marker 2\n[ ] [13:42.059] - Marker 3\n---\nhttps://www.youtube.com/ - links open in browser\n---",
    },
    es = {
        menu_file         = "Archivo",
        menu_new_tab      = "Nueva nota",
        menu_export       = "Exportar",
        menu_import       = "Importar",
        menu_view         = "Vista",
        menu_font_size    = "Tamaño de fuente:",
        menu_font_type    = "Fuente:",
        menu_ui_color     = "Tema:",
        menu_reset_color  = "Restablecer color",
        menu_theme        = "Tema:",
        theme_dark        = "Oscuro",
        theme_light       = "Claro",
        theme_blue        = "Azul",
        theme_red         = "Rojo",
        theme_yellow      = "Amarillo",
        menu_language     = "Idioma",
        menu_lang_uk      = "Українська",
        menu_lang_en      = "English",
        menu_lang_es      = "Español",
        menu_help         = "Ayuda",
        menu_close        = "Cerrar",
        help_general      = "General:",
        help_1            = "• Doble clic en la pestaña para renombrar el bloc",
        help_2            = "• Presiona Enter para guardar el nombre",
        help_3            = "• Doble clic dentro de la pestaña para editar",
        help_4            = "• En modo edición, clic derecho \n   y selecciona 'Importar marcadores'",
        help_5            = "• Presiona Ctrl+S para guardar",
        help_markdown     = "Markdown:",
        help_styles       = "Estilos en línea:",
        help_line_start   = "Al inicio de línea:",
        tab_new_name      = "Bloc",
        tab_empty_hint    = "Doble clic para crear una nota",
        confirm_delete    = "Eliminar",
        confirm_cancel    = "Cancelar",
        confirm_msg       = "Eliminar",
        export_label      = "Exportar",
        import_label      = "Importar",
        export_format     = "Formato:",
        import_format     = "Formato:",
        btn_export        = "Exportar",
        btn_import        = "Importar",
        ctx_import_markers = "Importar marcadores",
        ctx_copy          = "Copiar",
        ctx_paste         = "Pegar",
        ctx_cut           = "Cortar",
        ctx_select_all    = "Seleccionar todo",
        menu_save_notepad = "Guardar Notepad",
        menu_open_txt     = "Abrir documento de texto",
        menu_save_txt     = "Guardar en documento de texto",
        menu_autostart    = "Inicio automático con REAPER",
        menu_close_notepad = "Cerrar Notepad",
        help_md_italic     = "• *Cursiva*",
        help_md_bold       = "• **Negrita**",
        help_md_underline  = "• __Subrayado__",
        help_md_cell       = "• |Celda|",
        help_md_all        = "• __***Negrita + Cursiva + Subrayado***__",
        help_md_h1         = "• # Encabezado 1",
        help_md_h2         = "• ## Encabezado 2",
        help_md_h3         = "• ### Encabezado 3",
        help_md_cb_empty   = "• [ ] Casilla",
        help_md_cb_done    = "• [x] Casilla",
        help_md_timing     = "• [00:00.000] Tiempo",
        help_md_divider    = "• --- Línea divisoria",
        -- toolbar
        tb_divider         = "Línea divisoria",
        tb_bold            = "Negrita",
        tb_italic          = "Cursiva",
        tb_underline       = "Subrayado",
        tb_table           = "Tabla",
        tb_h1              = "Encabezado 1",
        tb_h2              = "Encabezado 2",
        tb_h3              = "Encabezado 3",
        tb_checkbox        = "Casilla",
        -- search
        search_hint        = "Buscar (Ctrl+F)",
        search_clear       = "Limpiar búsqueda",
        search_prev        = "Coincidencia anterior",
        search_next        = "Siguiente coincidencia",
        rename_hint        = "Presiona Enter",
        -- edit mode
        edit_mode_label    = "Editando:",
        btn_save           = "Guardar",
        hint_dbl_click     = "Doble clic para editar",
        -- context menu
        ctx_delete         = "Eliminar",
        ctx_ctrl_s         = "Ctrl+S - guardar",
        -- confirm modal
        btn_confirm_delete = "Eliminar",
        btn_confirm_cancel = "Cancelar",
        -- empty state
        empty_hint         = "Doble clic para crear una nota",
        default_tab_name   = "Bloc",
        welcome_content    = "# BIENVENIDO A NOTEPAD\n*Doble clic para editar.*\n*Más información en la pestaña \"Ayuda\".*\n---\n# Encabezado 1\n## Encabezado 2\n### Encabezado 3\n---\n***LISTA DE TAREAS:***\n[x] Tarea 1\n[ ] Tarea 2\n[ ] Tarea 3\n---\nNormal\n**Negrita**\n*Cursiva*\n__Subrayado__\n[ ] ***__Todos los estilos juntos__***\n---\n|Tabla 1|Tabla 1|Tabla 1|Tabla 1|\n|Fila 1|Fila 1|Fila 1|Fila 1|\n|Fila 2|Fila 2|Fila 2|Fila 2|\n---\n*Importar marcadores:*\n[ ] [4:55.279] - Marcador 1\n[ ] [9:41.110] - Marcador 2\n[ ] [13:42.059] - Marcador 3\n---\nhttps://www.youtube.com/ - los enlaces se abren en el navegador\n---",
    },
}

local function T(key)
    local t = LANG[current_language] or LANG["uk"]
    return t[key] or (LANG["uk"][key] or key)
end

local function get_font(name, style)
    if not fonts_storage[name] then return nil end
    return fonts_storage[name][style]
end
--==============================================================
-- ТЕМИ
--==============================================================
local THEMES = {
    {
        key  = "dark",
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
        BG   = 0xD0D0D0FF, TAB = 0xBBBBBBFF, TABHOV = 0xCCCCCCFF,
        MAIN = 0x4488AAFF, OVERLINE = 0x4488AA88,
        FRAME = 0xC0C0C0FF, FRAMEHOV = 0xD5D5D5FF, FRAMEACT = 0xCBCBCBFF,
        BTN  = 0xC2C2C2FF, SCBG = 0xD0D0D000, SCGRAB = 0xBBBBBBFF,
        POPBG = 0xEEEEEEFF, SEP = 0xAAAAAAFF,
        ACCENT = 0x1A1A1AFF, HEADERCOL = 0x4488AAFF,
        TEXT = 0x474747FF, MENUBG = 0xBBBBBBFF,
    },
    {
        key  = "blue",
        BG   = 0x05080FFF, TAB = 0x0A1020FF, TABHOV = 0x1A2A40FF,
        MAIN = 0x0055BBFF, OVERLINE = 0x0044AA88,
        FRAME = 0x080C18FF, FRAMEHOV = 0x101828FF, FRAMEACT = 0x141E30FF,
        BTN  = 0x0A0F1AFF, SCBG = 0x05080F00, SCGRAB = 0x1A3A5AFF,
        POPBG = 0x0A0F1AFF, SEP = 0x224499FF,
        ACCENT = 0x44AAFFFF, HEADERCOL = 0x00EEFFFF,
        TEXT = 0xAADDFFFF, MENUBG = 0x030610FF,
    },
    {
        key  = "red",
        BG   = 0x100505FF, TAB = 0x200808FF, TABHOV = 0x3A1010FF,
        MAIN = 0xBB2200FF, OVERLINE = 0xAA220066,
        FRAME = 0x0D0404FF, FRAMEHOV = 0x1A0808FF, FRAMEACT = 0x200A0AFF,
        BTN  = 0x1A0808FF, SCBG = 0x10050500, SCGRAB = 0x5A1A1AFF,
        POPBG = 0x1A0808FF, SEP = 0x882211FF,
        ACCENT = 0xFF6644FF, HEADERCOL = 0xFFCC00FF,
        TEXT = 0xFFCCBBFF, MENUBG = 0x0A0303FF,
    },
    {
        key  = "yellow",
        BG   = 0x0A0700FF, TAB = 0x1A1000FF, TABHOV = 0x2A1E00FF,
        MAIN = 0xAA6600FF, OVERLINE = 0xAA660066,
        FRAME = 0x080500FF, FRAMEHOV = 0x150F00FF, FRAMEACT = 0x1A1200FF,
        BTN  = 0x150F00FF, SCBG = 0x0A070000, SCGRAB = 0x4A2A00FF,
        POPBG = 0x150F00FF, SEP = 0x885500FF,
        ACCENT = 0xFFAA00FF, HEADERCOL = 0xFFDD44FF,
        TEXT = 0xFFDDAAFF, MENUBG = 0x060400FF,
    },
}

local current_theme_key = "dark"

local function get_theme()
    for _, th in ipairs(THEMES) do
        if th.key == current_theme_key then return th end
    end
    return THEMES[1]
end

local function GetGeneralColorHEX()
    return get_theme().MAIN
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
    reaper.ImGui_PopStyleColor(ctx, 34)  -- 31 + 3 (Text, TextDisabled, MenuBarBg)
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
-- ПАРСИНГ MARKDOWN
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
-- ЗБЕРЕЖЕННЯ
--==============================================================
local EXT_STATE_SECTION = "imnotbad_Notepad"

local function save_font_settings()
    reaper.SetExtState(EXT_STATE_SECTION, "font_size", tostring(tab_font_size), true)
    reaper.SetExtState(EXT_STATE_SECTION, "font_name", current_font_name, true)
    reaper.SetExtState(EXT_STATE_SECTION, "theme", current_theme_key, true)
    reaper.SetExtState(EXT_STATE_SECTION, "language", current_language, true)
end

local function save_data()
    save_font_settings()
    reaper.SetExtState(EXT_STATE_SECTION, "active_tab", tostring(active_tab_index), true)
    
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
    if saved_lang and saved_lang ~= "" and LANG[saved_lang] then
        current_language = saved_lang
    end
end

local function load_data()
    load_font_settings()
    local f = io.open(save_file, "r")
    if f then
        local all = f:read("*all")
        f:close() 

        tabs = {}  
       
        for title, text in all:gmatch("%[TAB_TITLE%](.-)\n%[TAB_CONTENT%](.-)\n%[TAB_END%]") do
            table.insert(tabs, {
                title = title,
                content = text,
                editing = false,
                renaming = false
            })
        end   
    end 
  
    if #tabs == 0 then
        local welcome_content = T("welcome_content")
        tabs[1] = { title = T("default_tab_name") .. " 1", content = welcome_content, editing = false, renaming = false }
    end 
    
    local saved_idx = tonumber(reaper.GetExtState(EXT_STATE_SECTION, "active_tab")) or 1
    if saved_idx >= 1 and saved_idx <= #tabs then
        pending_active_tab = saved_idx
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

    local retval, filename = reaper.JS_Dialog_BrowseForSaveFile(_W.dlg_save_as, default_path, tab.title .. ".txt",
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
            reaper.ShowMessageBox(_W.err_save_msg, _W.err_save_title, 0)
        end
    end
end

local function import_text_file()
    local default_path = last_import_path
    if default_path == "" then
        default_path = reaper.GetProjectPath("")
    end

    local retval, filename = reaper.JS_Dialog_BrowseForOpenFiles(_W.dlg_import, default_path, "",
        "Text files (*.txt)\0*.txt\0All files (*.*)\0*.*\0", false)

    if retval == 1 and filename ~= "" then
        local file = io.open(filename, "r")
        if file then
            local content = file:read("*all")
            file:close()
            last_import_path = filename:match("^(.+[/\\])")
            local file_name = filename:match("([^/\\]+)%.txt$") or filename:match("([^/\\]+)$") or _W.import_default
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
            reaper.ShowMessageBox(_W.err_read_msg, _W.err_read_title, 0)
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
                    reaper.ImGui_TextColored(ctx, GetGeneralColorHEX(), display)
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
                            reaper.ImGui_TextColored(ctx, GetGeneralColorHEX(), display_time)
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
                        reaper.ImGui_TextColored(ctx, GetGeneralColorHEX(), display_time)
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
-- ОБРОБКА ХОТКЕЇВ ДЛЯ MACOS
--==============================================================
local mac_hotkey_debounce = {}

local function handle_mac_hotkeys()
    if not IS_MACOS then return end
    if not reaper.JS_VKeys_GetState then return end

    local tab = tabs[active_tab_index]
    if not tab or not tab.editing then return end

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

--==============================================================
-- ГОЛОВНИЙ ЦИКЛ
--==============================================================
local function loop()
    if not ctx or not reaper.ImGui_ValidatePtr(ctx, 'ImGui_Context*') then return end
    local force_close = reaper.GetExtState("Subass_Global", "ForceCloseComplementary")
    if force_close == "1" or force_close == "imnotbad_Notepad.lua" then 
        if force_close == "imnotbad_Notepad.lua" then
            reaper.SetExtState("Subass_Global", "ForceCloseComplementary", "0", false)
        end
        notepad_open = false
    end

    local active_style_tooltip = ""
    handle_mac_hotkeys()

    push_style(ctx)

    reaper.ImGui_SetNextWindowSizeConstraints(ctx, 475, 400, 1e10, 1e10)
    reaper.ImGui_SetNextWindowSize(ctx, 800, 600, reaper.ImGui_Cond_FirstUseEver())
    local flags = reaper.ImGui_WindowFlags_MenuBar()
        | reaper.ImGui_WindowFlags_NoCollapse()

    local visible, open_imgui = reaper.ImGui_Begin(ctx, "Notepad v1.2", notepad_open, flags)
    if not open_imgui then notepad_open = false end

    if visible then
        --================ MENU =================
        if reaper.ImGui_BeginMenuBar(ctx) then
            if reaper.ImGui_BeginMenu(ctx, T("menu_file")) then
                if reaper.ImGui_MenuItem(ctx, T("menu_save_notepad")) then save_data() end
                reaper.ImGui_Separator(ctx)

                if reaper.ImGui_MenuItem(ctx, T("menu_open_txt")) then
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

                if reaper.ImGui_MenuItem(ctx, T("menu_save_txt")) then
                    if active_tab_index then
                        export_active_tab(active_tab_index)
                    end
                end
                reaper.ImGui_Separator(ctx)
                local startup_active = is_startup_enabled()
                if reaper.ImGui_MenuItem(ctx, T("menu_autostart"), nil, startup_active) then
                    toggle_reaper_startup(not startup_active)
                    save_data()
                end
                reaper.ImGui_Separator(ctx)
                if reaper.ImGui_MenuItem(ctx, T("menu_close_notepad")) then
                    notepad_open = false
                end
                reaper.ImGui_EndMenu(ctx)
            end
            if reaper.ImGui_BeginMenu(ctx, T("menu_view")) then
                reaper.ImGui_SetNextItemWidth(ctx, 150)
                local changed, new_size = reaper.ImGui_SliderInt(ctx, T("menu_font_size"), tab_font_size, 12, 42)
                if changed then
                    tab_font_size = new_size
                    rebuild_all_fonts()
                    save_data()
                end
               
                reaper.ImGui_SeparatorText(ctx, T("menu_font_type"))

                for _, name in ipairs(font_list) do
                    local is_selected = (current_font_name == name)
                    if reaper.ImGui_MenuItem(ctx, name, "", is_selected) then
                        current_font_name = name
                        rebuild_tab_font()
                        rebuild_format_fonts()
                        save_data()
                    end
                end
                
                reaper.ImGui_SeparatorText(ctx, T("menu_theme"))
                for _, th in ipairs(THEMES) do
                    local is_sel = (current_theme_key == th.key)
                    -- кольоровий квадратик теми
                    local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
                    local cx, cy = reaper.ImGui_GetCursorScreenPos(ctx)
                    reaper.ImGui_Dummy(ctx, 12, 12)
                    reaper.ImGui_DrawList_AddRectFilled(draw_list, cx, cy + 2, cx + 12, cy + 14, th.MAIN)
                    reaper.ImGui_SameLine(ctx)
                    if reaper.ImGui_MenuItem(ctx, T("theme_" .. th.key), "", is_sel) then
                        current_theme_key = th.key
                        save_data()
                    end
                end
                reaper.ImGui_EndMenu(ctx)
            end

            if reaper.ImGui_BeginMenu(ctx, T("menu_language")) then
                if reaper.ImGui_MenuItem(ctx, T("menu_lang_uk"), "", current_language == "uk") then
                    current_language = "uk"
                    save_data()
                end
                if reaper.ImGui_MenuItem(ctx, T("menu_lang_en"), "", current_language == "en") then
                    current_language = "en"
                    save_data()
                end
                if reaper.ImGui_MenuItem(ctx, T("menu_lang_es"), "", current_language == "es") then
                    current_language = "es"
                    save_data()
                end
                reaper.ImGui_EndMenu(ctx)
            end

            if reaper.ImGui_BeginMenu(ctx, T("menu_help")) then
                reaper.ImGui_SeparatorText(ctx, T("help_general"))
                reaper.ImGui_TextDisabled(ctx, T("help_1"))
                reaper.ImGui_TextDisabled(ctx, T("help_2"))
                reaper.ImGui_TextDisabled(ctx, T("help_3"))
                reaper.ImGui_TextDisabled(ctx, T("help_4"))
                reaper.ImGui_TextDisabled(ctx, T("help_5"))
                reaper.ImGui_SeparatorText(ctx, T("help_markdown"))
                reaper.ImGui_Text(ctx, T("help_styles"))
                reaper.ImGui_Separator(ctx)
                reaper.ImGui_TextDisabled(ctx, T("help_md_italic"))
                reaper.ImGui_TextDisabled(ctx, T("help_md_bold"))
                reaper.ImGui_TextDisabled(ctx, T("help_md_underline"))
                reaper.ImGui_TextDisabled(ctx, T("help_md_cell"))
                reaper.ImGui_TextDisabled(ctx, T("help_md_all"))

                reaper.ImGui_Separator(ctx)
                reaper.ImGui_Text(ctx, T("help_line_start"))
                reaper.ImGui_Separator(ctx)

                reaper.ImGui_TextDisabled(ctx, T("help_md_h1"))
                reaper.ImGui_TextDisabled(ctx, T("help_md_h2"))
                reaper.ImGui_TextDisabled(ctx, T("help_md_h3"))
                reaper.ImGui_TextDisabled(ctx, T("help_md_cb_empty"))
                reaper.ImGui_TextDisabled(ctx, T("help_md_cb_done"))
                reaper.ImGui_TextDisabled(ctx, T("help_md_timing"))
                reaper.ImGui_TextDisabled(ctx, T("help_md_divider"))
                reaper.ImGui_EndMenu(ctx)
            end 
            
            reaper.ImGui_EndMenuBar(ctx)
        end 

        --================ TAB BAR =================
        if not pomodoro_active then
            if reaper.ImGui_BeginTabBar(ctx, "MyTabBar", reaper.ImGui_TabBarFlags_Reorderable()) then
                if reaper.ImGui_TabItemButton(ctx, "+", reaper.ImGui_TabItemFlags_Trailing()) then
                    tabs[#tabs + 1] = {
                        title = T("default_tab_name") .. " " .. (#tabs + 1),
                        content = "",
                        editing = false,
                        renaming = false
                    }
                    pending_active_tab = #tabs
                end

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
                            tabs[renaming_tab_index].title = new_title ~= "" and new_title or
                                tabs[renaming_tab_index].title
                            tabs[renaming_tab_index].renaming = false
                            tabs[renaming_tab_index].should_focus = true
                        end

                        if reaper.ImGui_IsItemDeactivated(ctx) then
                            tabs[renaming_tab_index].renaming = false
                            tabs[renaming_tab_index].should_focus = true
                        end

                        reaper.ImGui_SameLine(ctx)
                        reaper.ImGui_TextDisabled(ctx, T("rename_hint"))
                    else
                        reaper.ImGui_SetNextItemWidth(ctx, 160)
                        local changed, new_filter = reaper.ImGui_InputTextWithHint(ctx, "##filter",
                            T("search_hint"),
                            filter_text)
                        if changed then
                            filter_text = new_filter
                            filter_active = (filter_text ~= "")
                            filter_match_index = 1
                        end

                        local want_search = is_mod_key_pressed(reaper.ImGui_Key_F, 70)
                        if not want_search and IS_MACOS and reaper.JS_VKeys_GetState then
                            local cmd_down = reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Mod_Super())
                            if cmd_down then
                                local st = reaper.JS_VKeys_GetState(-2)
                                if st and #st >= 70 and st:byte(70) == 1 then
                                    if not mac_hotkey_debounce[70] then
                                        mac_hotkey_debounce[70] = true
                                        want_search = true
                                    end
                                else
                                    mac_hotkey_debounce[70] = false
                                end
                            end
                        end
                        if want_search then
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

                            if reaper.ImGui_Button(ctx, "X##clear_filter", 24) then
                                filter_text = ""
                                filter_active = false
                                filter_matches = {}
                                filter_match_index = 0
                            end
                            if reaper.ImGui_IsItemHovered(ctx) then
                                active_style_tooltip = T("search_clear")
                            end
                            reaper.ImGui_SameLine(ctx)

                            local is_editing_now = tabs[active_tab_index] and tabs[active_tab_index].editing
                            if not is_editing_now then
                                local has_matches = #filter_matches > 0
                                if not has_matches then
                                    reaper.ImGui_BeginDisabled(ctx)
                                end

                                if reaper.ImGui_Button(ctx, "<##prev_match", 24) then
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
                                    active_style_tooltip = T("search_prev")
                                end
                                reaper.ImGui_SameLine(ctx)
                                if reaper.ImGui_Button(ctx, ">##next_match", 24) then
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
                                    active_style_tooltip = T("search_next")
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
                        local current_active = tabs[active_tab_index]
                        if current_active and current_active.editing then
                            active_editing_tab = current_active
                        end

                        if active_editing_tab then
                            local style_buttons = {
                                { label = "-",  prefix = "---", tooltip_key = "tb_divider",  is_wrap = false },
                                { label = "B",  wrapper = "**", tooltip_key = "tb_bold",     is_wrap = true },
                                { label = "I",  wrapper = "*",  tooltip_key = "tb_italic",   is_wrap = true },
                                { label = "_",  wrapper = "__", tooltip_key = "tb_underline",is_wrap = true },
                                { label = "T",  wrapper = "|",  tooltip_key = "tb_table",    is_wrap = true },
                                { label = "H1", prefix = "# ",  tooltip_key = "tb_h1",       is_wrap = false },
                                { label = "H2", prefix = "## ", tooltip_key = "tb_h2",       is_wrap = false },
                                { label = "H3", prefix = "### ",tooltip_key = "tb_h3",       is_wrap = false },
                                { label = "☑",  prefix = "[ ] ",tooltip_key = "tb_checkbox", is_wrap = false },
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
                                    active_style_tooltip = T(btn.tooltip_key)
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
                        
                        local avail_w, avail_h = reaper.ImGui_GetContentRegionAvail(ctx)

                        if tab.reopen_editing then
                            tab.reopen_editing = nil
                            tab.editing = true
                            tab.should_focus_edit = true
                        end

                        local display_content = tab.content

                        --========== EDIT MODE ==========
                        if tab.editing then
                            reaper.ImGui_TextDisabled(ctx, T("edit_mode_label"))

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

                                if reaper.ImGui_MenuItem(ctx, T("ctx_copy"), "Ctrl+C", false, has_selection) then
                                    if has_selection then
                                        local selected_text = tab.content:sub(sel_s + 1, sel_e)
                                        reaper.ImGui_SetClipboardText(ctx, selected_text)
                                    end
                                end

                                if reaper.ImGui_MenuItem(ctx, T("ctx_cut"), "Ctrl+X", false, has_selection) then
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

                                if reaper.ImGui_MenuItem(ctx, T("ctx_paste"), "Ctrl+V") then
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

                                if reaper.ImGui_MenuItem(ctx, T("ctx_delete"), "Del", false, has_selection) then
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

                                if reaper.ImGui_MenuItem(ctx, T("ctx_import_markers")) then
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
                                reaper.ImGui_TextDisabled(ctx, T("ctx_ctrl_s"))
                                reaper.ImGui_EndPopup(ctx)
                            end
                            reaper.ImGui_PopFont(ctx)

                            if reaper.ImGui_IsItemActive(ctx) then
                                if is_mod_key_pressed(reaper.ImGui_Key_A, 65) then
                                    text_sel_start = 0
                                    text_sel_end = #tab.content
                                end
                            end

                            reaper.ImGui_PopFont(ctx)

                            reaper.ImGui_PushFont(ctx, font, 16)
                            reaper.ImGui_SetCursorPosX(ctx, window_width - save_button_width / 0.5)
                            if reaper.ImGui_Button(ctx, T("btn_save"), 150, 30) then
                                tab.editing = false
                            end
                            if reaper.ImGui_IsItemHovered(ctx) then
                                reaper.ImGui_SetTooltip(ctx, "Ctrl+S")
                            end
                            if is_mod_key_pressed(reaper.ImGui_Key_S, 83) then
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
                                reaper.ImGui_TextDisabled(ctx, T("hint_dbl_click"))
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

                                            reaper.ImGui_SetCursorScreenPos(ctx, cur_x + cell_padding,
                                                start_y + cell_padding)

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

                    if not keep_open and confirm_close_tab_index == nil then
                        local tab_has_content = tabs[i] and tabs[i].content and tabs[i].content:match("%S") ~= nil
                        if tab_has_content then
                            confirm_close_tab_index = i
                            confirm_close_prev_active = active_tab_index
                            pending_active_tab = i
                            reaper.ImGui_OpenPopup(ctx, "ConfirmCloseTab")
                        else
                            local del_idx = i
                            table.remove(tabs, del_idx)
                            local target = active_tab_index
                            if target > del_idx then target = target - 1 end
                            if target > #tabs then target = #tabs end
                            if target < 1 then target = 1 end
                            if #tabs > 0 then
                                pending_active_tab = target
                            end
                            save_data()
                        end
                    end
                end

                local modal_win_w   = 380
                local modal_pad     = 20
                local btn_w         = 135
                local btn_h         = 30
                local btn_gap       = 14
                local text_max_w    = modal_win_w - modal_pad * 2
                local font_size     = 16
                local char_w_approx = font_size * 0.60
                local line_h        = font_size - 6

                local modal_text_h  = line_h
                if confirm_close_tab_index and tabs[confirm_close_tab_index] then
                    local full_msg  = T("btn_confirm_delete") .. " \"" .. tabs[confirm_close_tab_index].title .. "\"?"
                    local msg_px_w  = #full_msg * char_w_approx
                    local num_lines = math.ceil(msg_px_w / text_max_w)
                    if num_lines < 1 then num_lines = 1 end
                    modal_text_h = num_lines * line_h
                end

                local modal_win_h            = modal_pad + 6 + modal_text_h + 8 + 6 + btn_h + modal_pad

                local main_win_x, main_win_y = reaper.ImGui_GetWindowPos(ctx)
                local main_win_w_m           = reaper.ImGui_GetWindowWidth(ctx)
                local main_win_h_m           = reaper.ImGui_GetWindowHeight(ctx)
                local modal_cx               = main_win_x + (main_win_w_m - modal_win_w) * 0.5
                local modal_cy               = main_win_y + (main_win_h_m - modal_win_h) * 0.5
                reaper.ImGui_SetNextWindowPos(ctx, modal_cx, modal_cy, reaper.ImGui_Cond_Always())
                reaper.ImGui_SetNextWindowSize(ctx, modal_win_w, modal_win_h, reaper.ImGui_Cond_Always())

                local modal_flags = reaper.ImGui_WindowFlags_NoResize()
                    | reaper.ImGui_WindowFlags_NoScrollbar()
                    | reaper.ImGui_WindowFlags_NoDocking()
                    | reaper.ImGui_WindowFlags_TopMost()
                    | reaper.ImGui_WindowFlags_NoDecoration()

                local popup_open = reaper.ImGui_BeginPopupModal(ctx, "ConfirmCloseTab", true, modal_flags)
                if popup_open then
                    local tab_name = (confirm_close_tab_index and tabs[confirm_close_tab_index])
                        and tabs[confirm_close_tab_index].title or "?"
                    local full_msg = T("btn_confirm_delete") .. " \"" .. tab_name .. "\"?"

                    reaper.ImGui_Dummy(ctx, 0, 6)
                    reaper.ImGui_SetCursorPosX(ctx, modal_pad)
                    reaper.ImGui_PushFont(ctx, font, 16)
                    reaper.ImGui_PushTextWrapPos(ctx, modal_win_w - modal_pad)
                    reaper.ImGui_Text(ctx, full_msg)
                    reaper.ImGui_PopTextWrapPos(ctx)
                    reaper.ImGui_PopFont(ctx)
                    reaper.ImGui_Dummy(ctx, 0, 8)

                    local total_btns_w = btn_w * 2 + btn_gap
                    local btn_start_x  = (modal_win_w - total_btns_w) * 0.5
                    reaper.ImGui_SetCursorPosX(ctx, btn_start_x)

                    -- фіксований білий текст для кнопок незалежно від теми
                    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xFFFFFFFF)

                    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x551111FF)
                    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0xAA2222FF)
                    reaper.ImGui_PushFont(ctx, bold_font, 14)
                    if reaper.ImGui_Button(ctx, T("btn_confirm_delete") .. "##confirm_close", btn_w, btn_h) then
                        if confirm_close_tab_index then
                            local del_idx = confirm_close_tab_index
                            table.remove(tabs, del_idx)
                            local target = confirm_close_prev_active or del_idx
                            if target > del_idx then target = target - 1 end
                            if target > #tabs then target = #tabs end
                            if target < 1 then target = 1 end
                            pending_active_tab = target
                            save_data()
                        end
                        confirm_close_tab_index   = nil
                        confirm_close_prev_active = nil
                        reaper.ImGui_CloseCurrentPopup(ctx)
                    end
                    reaper.ImGui_PopFont(ctx)
                    reaper.ImGui_PopStyleColor(ctx, 2)

                    reaper.ImGui_SameLine(ctx, nil, btn_gap)

                    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x1A1A1AFF)
                    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), GetGeneralColorHEX())
                    reaper.ImGui_PushFont(ctx, bold_font, 14)
                    if reaper.ImGui_Button(ctx, T("btn_confirm_cancel") .. "##cancel_close", btn_w, btn_h) then
                        if confirm_close_prev_active then
                            pending_active_tab = confirm_close_prev_active
                        end
                        confirm_close_tab_index   = nil
                        confirm_close_prev_active = nil
                        reaper.ImGui_CloseCurrentPopup(ctx)
                    end
                    reaper.ImGui_PopFont(ctx)
                    reaper.ImGui_PopStyleColor(ctx, 2)

                    -- знімаємо фіксований колір тексту
                    reaper.ImGui_PopStyleColor(ctx, 1)

                    reaper.ImGui_EndPopup(ctx)
                elseif not reaper.ImGui_IsPopupOpen(ctx, "ConfirmCloseTab") and confirm_close_tab_index ~= nil then
                    confirm_close_tab_index   = nil
                    confirm_close_prev_active = nil
                end

                reaper.ImGui_EndTabBar(ctx)
            end

            if #tabs == 0 and not pomodoro_active then
                local avail_w, avail_h = reaper.ImGui_GetContentRegionAvail(ctx)
                local msg = T("empty_hint")
                reaper.ImGui_PushFont(ctx, tab_font, tab_font_size + 2)
                local tw, th = reaper.ImGui_CalcTextSize(ctx, msg)
                reaper.ImGui_PopFont(ctx)
                local cx = (avail_w - tw) * 0.5
                local cy = (avail_h - th) * 0.5
                reaper.ImGui_SetCursorPos(ctx, cx, reaper.ImGui_GetCursorPosY(ctx) + cy)
                reaper.ImGui_PushFont(ctx, tab_font, tab_font_size + 2)
                reaper.ImGui_TextDisabled(ctx, msg)
                reaper.ImGui_PopFont(ctx)
                local win_hovered = reaper.ImGui_IsWindowHovered(ctx, reaper.ImGui_HoveredFlags_ChildWindows())
                if win_hovered and reaper.ImGui_IsMouseDoubleClicked(ctx, 0) then
                    tabs[1] = {
                        title = T("default_tab_name") .. " 1",
                        content = "",
                        editing = true,
                        renaming = false,
                        should_focus_edit = true
                    }
                    pending_active_tab = 1
                end
            end
        end
        reaper.ImGui_End(ctx)
    end
    pop_style(ctx)
    if reaper.time_precise() - last_save_time > 5 then
        save_data()
        last_save_time = reaper.time_precise()
    end

    if notepad_open then reaper.defer(loop) else save_data() end
end

reaper.defer(loop)
