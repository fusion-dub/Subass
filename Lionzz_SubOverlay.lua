--[[ 
    Lionzz Sub Overlay
    Версія: 0.0.2

    checklist:
    ОСНОВНЕ ВІКНО
        Ресайз, закриття, згортання, перетягування
        пін вікна
    КОНТЕКСТНЕ МЕНЮ
        відкриття, закриття
        перемикання всіх налаштувань
        збереження/завантаження налаштувань
    ВІДОБРАЖЕННЯ
        відображення обох рядків та прогрессбара
        поведінка при відсутності регіонів/ітемів
        відображення на початку та в кінці проекту в обох режимах

    to do list:        
]]

if not reaper.ImGui_CreateContext then
    reaper.ShowMessageBox("ReaImGui не знайдено. Встановіть ReaImGui.", "Помилка", 0)
    return
end

local ctx = reaper.ImGui_CreateContext("Lionzz Sub Overlay")
local win_X, win_Y, win_w, win_h = 500, 500, 500, 300
local win_open = true
local close_requested = false

-- Простий кеш для оптимізації
local last_pos = nil
local cached_current, cached_next, cached_start, cached_stop = nil, nil, nil, nil

-- Кеш координат відевікна
local video_cache_valid = false
local cached_video_x1, cached_video_y1, cached_video_x2, cached_video_y2 = nil, nil, nil, nil
local cached_attach_x, cached_attach_y, cached_attach_w = nil, nil, nil
local is_user_resizing = false  -- прапорець для відстеження ресайзу користувачем
local show_wrap_guides = false  -- прапорець для відображення напрямних відступу переносу


-- Налаштування шрифту та масштабу
local BASE_FONT_SIZE = 14 -- базовий розмір шрифту для створення об'єктів
local available_fonts = {
    "Arial","Calibri","Roboto","Segoe UI","Tahoma","Verdana",
    "Cambria","CooperMediumC BT","Georgia","Times New Roman",
    "Consolas","Courier New"
}
local font_objects = {}
for i, name in ipairs(available_fonts) do
    local f = reaper.ImGui_CreateFont(name, BASE_FONT_SIZE)
    font_objects[i] = f
    reaper.ImGui_Attach(ctx, f)
end

local ui_font = font_objects[1]         -- перший шрифт завжди для UI
local UI_FONT_SCALE = 14                -- фіксований масштаб для інтерфейсу
local CONTEXT_MENU_MIN_WIDTH = 200      -- мінімальна ширина контекстного меню
local next_region_offset = 20           -- відступ між поточним та наступним регіоном
local show_progress = true              -- показувати прогрессбар
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
local fill_gaps = true                  -- показувати найближчий регіон/ітем між об'єктами
local show_tooltips = true              -- показувати підказки
local tooltip_delay = 0.5
local tooltip_state = {}
local attach_to_video = false           -- прив'язувати до відеоокна
local attach_bottom = false             -- режим прив'язки: "bottom"
local attach_offset = 0                 -- відступ у відсотках (0-100)
local ignore_newlines = false           -- ігнорувати символи переносу рядка при читанні



local flags = {
    NoTitle = false,
    NoResize = false,
    AlwaysAutoResize = false,
    NoDocking = true,
    HideBackground = false,
    NoMove = false
}



-- ==========================
-- БЛОК ФУНКЦІЙ
-- ==========================

-- Зберігаємо/завантажуємо налаштування
local SETTINGS_SECTION = "LionzzSubOverlay"

local function save_settings()
    reaper.SetExtState(SETTINGS_SECTION, "NoTitle", tostring(flags.NoTitle), true)
    reaper.SetExtState(SETTINGS_SECTION, "HideBackground", tostring(flags.HideBackground), true)
    reaper.SetExtState(SETTINGS_SECTION, "NoResize", tostring(flags.NoResize), true)
    reaper.SetExtState(SETTINGS_SECTION, "AlwaysAutoResize", tostring(flags.AlwaysAutoResize), true)
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
    reaper.SetExtState(SETTINGS_SECTION, "fill_gaps", tostring(fill_gaps), true)
    reaper.SetExtState(SETTINGS_SECTION, "show_tooltips", tostring(show_tooltips), true)
    reaper.SetExtState(SETTINGS_SECTION, "attach_to_video", tostring(attach_to_video), true)
    reaper.SetExtState(SETTINGS_SECTION, "attach_bottom", tostring(attach_bottom), true)
    reaper.SetExtState(SETTINGS_SECTION, "attach_offset", tostring(attach_offset), true)
    reaper.SetExtState(SETTINGS_SECTION, "ignore_newlines", tostring(ignore_newlines), true)
    -- Зберігаємо висоту тільки якщо увімкнено прив'язку до відеоокна
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
    flags.AlwaysAutoResize = reaper.GetExtState(SETTINGS_SECTION, "AlwaysAutoResize") == "true"
    flags.NoMove = reaper.GetExtState(SETTINGS_SECTION, "NoMove") == "true"
    flags.NoDocking = reaper.GetExtState(SETTINGS_SECTION, "NoDocking") == "true"
    current_font_index = tonumber(reaper.GetExtState(SETTINGS_SECTION, "current_font_index")) or 1
    font_scale = tonumber(reaper.GetExtState(SETTINGS_SECTION, "font_scale")) or 30
    second_font_index = tonumber(reaper.GetExtState(SETTINGS_SECTION, "second_font_index")) or 1
    second_font_scale = tonumber(reaper.GetExtState(SETTINGS_SECTION, "second_font_scale")) or 30
    next_region_offset = tonumber(reaper.GetExtState(SETTINGS_SECTION, "next_region_offset")) or 40
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
    enable_second_line = (reaper.GetExtState(SETTINGS_SECTION, "enable_second_line") == "true")
    show_progress = (reaper.GetExtState(SETTINGS_SECTION, "show_progress") == "true")
    progress_width = tonumber(reaper.GetExtState(SETTINGS_SECTION, "progress_width")) or 400
    progress_height = tonumber(reaper.GetExtState(SETTINGS_SECTION, "progress_height")) or 4
    progress_offset = tonumber(reaper.GetExtState(SETTINGS_SECTION, "progress_offset")) or 20
    align_center = (reaper.GetExtState(SETTINGS_SECTION, "align_center") ~= "false")
    align_vertical = (reaper.GetExtState(SETTINGS_SECTION, "align_vertical") == "true")
    fill_gaps = (reaper.GetExtState(SETTINGS_SECTION, "fill_gaps") ~= "false")
    show_tooltips = (reaper.GetExtState(SETTINGS_SECTION, "show_tooltips") ~= "false")
    attach_to_video = (reaper.GetExtState(SETTINGS_SECTION, "attach_to_video") == "true")
    attach_bottom = (reaper.GetExtState(SETTINGS_SECTION, "attach_bottom") == "true")
    attach_offset = tonumber(reaper.GetExtState(SETTINGS_SECTION, "attach_offset")) or 0
    ignore_newlines = (reaper.GetExtState(SETTINGS_SECTION, "ignore_newlines") == "true")
    -- Завантажуємо висоту тільки якщо увімкнено прив'язку до відеоокна
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
        align_vertical        = add_change(reaper.ImGui_Checkbox(ctx, "Центрування по вертикалі", align_vertical))
        tooltip("Вирівнює рядки по вертикалі")
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
        flags.AlwaysAutoResize= add_change(reaper.ImGui_Checkbox(ctx, "Авторесайз вікна", flags.AlwaysAutoResize))
        tooltip("Автоматично підбирає розмір вікна під довжину рядків та прогрессбара")
        attach_to_video       = add_change(reaper.ImGui_Checkbox(ctx, "Прив'язати до відеоокна", attach_to_video))
        tooltip("Автоматично позиціонує вікно відносно відеоокна REAPER\nПотрібно js_ReaScriptAPI")
        -- Додаткові налаштування прив'язки (показуємо тільки якщо attach_to_video = true)
        if attach_to_video then
            -- Чекбокс режиму прив'язки
            attach_bottom = add_change(reaper.ImGui_Checkbox(ctx, "Прив'язати до нижньої межі відеоокна", attach_bottom))
            tooltip("Вибір сторони прив'язки")
            
            -- Слайдер відступу
            attach_offset = add_change(reaper.ImGui_SliderInt(ctx, "відступ##attach", attach_offset, 0, 100))
            tooltip("Позиція у відсотках відносно висоти відеоокна")
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

        -- Прогресс-бар
        reaper.ImGui_Separator(ctx)
        show_progress = add_change(reaper.ImGui_Checkbox(ctx, "Прогрессбар", show_progress))
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

-- Функція для збалансованого переносу тексту
local function balanced_wrap(ctx, text, max_w)
    local words = {}
    for word in string.gmatch(text, "%S+") do
        table.insert(words, word)
    end
    if #words <= 1 then return {text} end

    -- якщо рядок поміщається цілком → без переносу
    local total_w = reaper.ImGui_CalcTextSize(ctx, text)
    if total_w <= max_w then
        return {text}
    end

    -- шукаємо оптимальне місце для розриву
    local best_diff = math.huge
    local best_idx = nil
    for i = 1, #words-1 do
        local left = table.concat(words, " ", 1, i)
        local right = table.concat(words, " ", i+1, #words)
        local w_left = reaper.ImGui_CalcTextSize(ctx, left)
        local w_right = reaper.ImGui_CalcTextSize(ctx, right)

        -- обидві половини повинні мати шанс влізти
        if w_left <= max_w and w_right <= max_w * 1.5 then
            local diff = math.abs(w_left - w_right)
            if diff < best_diff then
                best_diff = diff
                best_idx = i
            end
        end
    end

    if not best_idx then
        -- fallback: звичайний wrap по max_w
        local lines, current = {}, ""
        for _, word in ipairs(words) do
            local test_line = (current == "") and word or (current .. " " .. word)
            local w = reaper.ImGui_CalcTextSize(ctx, test_line)
            if w > max_w and current ~= "" then
                table.insert(lines, current)
                current = word
            else
                current = test_line
            end
        end
        if current ~= "" then table.insert(lines, current) end
        return lines
    end

    -- ділимо рядок на дві частини
    local left = table.concat(words, " ", 1, best_idx)
    local right = table.concat(words, " ", best_idx+1, #words)

    -- рекурсивно обробляємо обидві частини
    local left_lines = balanced_wrap(ctx, left, max_w)
    local right_lines = balanced_wrap(ctx, right, max_w)

    -- об'єднуємо
    for i = 1, #right_lines do table.insert(left_lines, right_lines[i]) end
    return left_lines
end

-- Функція відображення тексту
local function draw_centered_text(ctx, text, font_index, font_scale, text_color, shadow_color, win_w)
    local font_to_push = font_objects[font_index] or font_objects[1]
    reaper.ImGui_PushFont(ctx, font_to_push, font_scale)

    local lines = {}
    for line in string.gmatch(text .. "\n", "(.-)\n") do
        if enable_wrap and line ~= "" then
            -- Враховуємо відступи padding та wrap_margin з обох сторін
            local max_wrap_width = win_w - padding_x*2 - wrap_margin*2
            local wrapped = balanced_wrap(ctx, line, max_wrap_width)
            for _, l in ipairs(wrapped) do
                table.insert(lines, l)
            end
        else
            table.insert(lines, line)
        end

    end
    if #lines == 0 then lines = {" "} end

    local max_w = 0
    for _, line in ipairs(lines) do
        local w = reaper.ImGui_CalcTextSize(ctx, line) or 0
        if w > max_w then max_w = w end
    end

    local shadow_offset = 2
    local line_h = reaper.ImGui_GetTextLineHeight(ctx)
    local draw_list = reaper.ImGui_GetWindowDrawList(ctx)

    for _, line in ipairs(lines) do
        local w = reaper.ImGui_CalcTextSize(ctx, line) or 0
        local cur_y = reaper.ImGui_GetCursorPosY(ctx)
        local cur_x
        if align_center then
            cur_x = (win_w - max_w)/2 + (max_w - w)/2
        else
            cur_x = wrap_margin  -- вирівнювання вліво з урахуванням відступу
        end

        if line ~= "" then
            if border then
                local win_x, win_y = reaper.ImGui_GetWindowPos(ctx)
                local rect_x1 = win_x + cur_x - padding_x
                local rect_y1 = win_y + cur_y - padding_y
                local rect_x2 = rect_x1 + w + padding_x*2
                local rect_y2 = rect_y1 + line_h + padding_y*2
                reaper.ImGui_DrawList_AddRectFilled(draw_list, rect_x1, rect_y1, rect_x2, rect_y2, window_bg_color or 0x000000AA, 4)
            end

            reaper.ImGui_SetCursorPosX(ctx, cur_x + shadow_offset)
            reaper.ImGui_SetCursorPosY(ctx, cur_y + shadow_offset)
            reaper.ImGui_TextColored(ctx, shadow_color, line)

            reaper.ImGui_SetCursorPosX(ctx, cur_x)
            reaper.ImGui_SetCursorPosY(ctx, cur_y)
            reaper.ImGui_TextColored(ctx, text_color, line)
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

    local current, nextreg = "", ""
    local nearest_dist = math.huge
    local nearest_idx = nil

    for i, r in ipairs(regions) do
        -- якщо всередині регіону → він стає поточним
        if pos >= r.start and pos < r.stop then
            current = r.name
            if regions[i+1] then
                nextreg = regions[i+1].name
            end
            return current, nextreg, r.start, r.stop
        end

        -- інакше шукаємо найближчий регіон по старту/кінцю
        local dist = math.min(math.abs(pos - r.start), math.abs(pos - r.stop))
        if dist < nearest_dist then
            nearest_dist = dist
            nearest_idx = i
        end
    end

    -- якщо не всередині регіону → найближчий стає поточним
    if fill_gaps and nearest_idx then
        current = regions[nearest_idx].name
        if regions[nearest_idx+1] then
            nextreg = regions[nearest_idx+1].name
        end
        return current, nextreg, regions[nearest_idx].start, regions[nearest_idx].stop
    end

    -- fallback: регіонів немає або fill_gaps вимкнено
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
    local items = reaper.CountTrackMediaItems(track)
    local current, next_item = "", ""
    local nearest_dist, nearest_idx = math.huge, nil
    local start_pos, stop_pos = 0, 0

    for i = 0, items-1 do
        local it = reaper.GetTrackMediaItem(track, i)
        start_pos = reaper.GetMediaItemInfo_Value(it, "D_POSITION")
        local len = reaper.GetMediaItemInfo_Value(it, "D_LENGTH")
        stop_pos = start_pos + len
        local name = get_text_item_name(it)

        if name then
            if pos >= start_pos and pos < stop_pos then
                current = name
                next_item = find_next_text_item(track, i+1)
                return current, next_item, start_pos, stop_pos
            end
            local dist = math.min(math.abs(pos - start_pos), math.abs(pos - stop_pos))
            if dist < nearest_dist then
                nearest_dist = dist
                nearest_idx = i
            end
        end
    end

    if fill_gaps and nearest_idx then
        local it = reaper.GetTrackMediaItem(track, nearest_idx)
        local name = get_text_item_name(it)
        if name then
            current = name
            next_item = find_next_text_item(track, nearest_idx+1)
            start_pos = reaper.GetMediaItemInfo_Value(it, "D_POSITION")
            local len = reaper.GetMediaItemInfo_Value(it, "D_LENGTH")
            stop_pos = start_pos + len
        end
        return current, next_item, start_pos, stop_pos
    end

    return "", "", 0, 0
end

-- Функція для отримання координат відеоокна REAPER
local function get_video_window_pos()
    if not reaper.JS_Window_Find then
        return nil, nil, nil, nil  -- js_ReaScriptAPI не встановлено
    end
    
    -- Шукаємо відеоокно (Video Window)
    local video_hwnd = reaper.JS_Window_Find("Video Window", true)
    
    if video_hwnd then
        local retval, x1, y1, x2, y2 = reaper.JS_Window_GetRect(video_hwnd)
        if retval then
            return x1, y1, x2, y2
        end
    end
    
    return nil, nil, nil, nil
end

-- Перевірка зміни позиції відеоокна та перерахунок координат прив'язки
local function check_video_window_moved()
    -- Отримуємо поточні координати відеоокна
    local x1, y1, x2, y2 = get_video_window_pos()
    
    -- Якщо відеоокна немає - виходимо
    if not x1 then
        video_cache_valid = false
        return false
    end
    
    -- Перевіряємо, чи змінилися координати
    if video_cache_valid and cached_video_x1 == x1 and cached_video_y1 == y1 and 
       cached_video_x2 == x2 and cached_video_y2 == y2 then
        -- Координати не змінилися, використовуємо кеш
        return true
    end
    
    -- Координати змінилися або кеш невалідний - перераховуємо позиції
    local video_width = x2 - x1
    local video_height = y2 - y1
    
    -- Вікно розтягується по ширині відеоокна
    attach_x = x1
    attach_w = video_width
    
    -- Розраховуємо Y позицію в залежності від режиму прив'язки
    -- Обмежуємо offset, щоб вікно не виходило за межі відеоокна
    local max_offset = math.max(0, video_height - win_h)
    local offset_pixels = math.min(attach_offset * video_height / 100, max_offset)
    
    if attach_bottom then
        -- Прив'язка до низу: y2 - висота вікна - offset
        attach_y = y2 - win_h - offset_pixels
    else
        -- Прив'язка до верху: y1 + offset
        attach_y = y1 + offset_pixels
    end
    
    -- Зберігаємо в кеш
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
            reaper.ImGui_Text(ctx, string.format("Attach X: %.0f", attach_x))
            reaper.ImGui_Text(ctx, string.format("Attach Y: %.0f", attach_y))
            reaper.ImGui_Text(ctx, string.format("Attach W: %.0f", attach_w or 0))
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
    
    local window_flags = reaper.ImGui_WindowFlags_NoScrollbar()
    if flags.NoTitle then window_flags = window_flags | reaper.ImGui_WindowFlags_NoTitleBar() end
    if flags.NoResize then window_flags = window_flags | reaper.ImGui_WindowFlags_NoResize() end
    if flags.AlwaysAutoResize then window_flags = window_flags | reaper.ImGui_WindowFlags_AlwaysAutoResize() end
    if flags.NoDocking then window_flags = window_flags | reaper.ImGui_WindowFlags_NoDocking() end
    if flags.NoMove then window_flags = window_flags | reaper.ImGui_WindowFlags_NoMove() end

    if flags.HideBackground and reaper.ImGui_SetNextWindowBgAlpha then
        reaper.ImGui_SetNextWindowBgAlpha(ctx, 0)
    end

    -- Встановлюємо початковий розмір та позицію вікна (тільки при першому запуску)
    reaper.ImGui_SetNextWindowSize(ctx, win_w, win_h, reaper.ImGui_Cond_FirstUseEver())
    reaper.ImGui_SetNextWindowPos(ctx, win_X, win_Y, reaper.ImGui_Cond_FirstUseEver())
    
    -- Якщо увімкнено прив'язку до відеоокна та користувач НЕ змінює розмір - застосовуємо позиції
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
        if pos ~= last_pos then
            -- Позиція змінилася - оновлюємо дані
            last_pos = pos
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
        else
            -- Позиція не змінилася - використовуємо кеш
            current, nextreg, start_pos, stop_pos = cached_current, cached_next, cached_start, cached_stop
        end

        local progress = 0.0
        if start_pos and stop_pos and stop_pos > start_pos then
            if pos >= start_pos and pos <= stop_pos then
                local rel = (pos - start_pos) / (stop_pos - start_pos)
                progress = math.max(0, math.min(1, rel))
            end
        end

        -- Вертикальне центрування (якщо увімкнено)
        if align_vertical then
            -- Розраховуємо загальну висоту контенту
            local total_height = 0
            
            -- Висота першого рядка
            reaper.ImGui_PushFont(ctx, font_objects[current_font_index] or font_objects[1], font_scale)
            local calc_width = win_w - padding_x*2 - wrap_margin*2
            local _, first_line_height = reaper.ImGui_CalcTextSize(ctx, current or " ", 0, 0, false, calc_width)
            reaper.ImGui_PopFont(ctx)
            total_height = total_height + first_line_height
            
            -- Висота прогресс-бара (якщо увімкнено)
            if show_progress then
                total_height = total_height + progress_offset + progress_height
            end
            
            -- Висота другого рядка (якщо увімкнено)
            if enable_second_line then
                reaper.ImGui_PushFont(ctx, font_objects[second_font_index] or font_objects[1], second_font_scale)
                local _, second_line_height = reaper.ImGui_CalcTextSize(ctx, nextreg or " ", 0, 0, false, calc_width)
                reaper.ImGui_PopFont(ctx)
                total_height = total_height + next_region_offset + second_line_height
            end
            
            -- Встановлюємо початкову позицію Y для центрування
            local start_y = math.max(0, (win_h - total_height) / 2)
            reaper.ImGui_SetCursorPosY(ctx, start_y)
        end
        
        -- відображення тексту
        draw_centered_text(ctx, current, current_font_index, font_scale, text_color, shadow_color, win_w) -- перший рядок

        -- прогресс-бар
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

        if enable_second_line then -- перевірка на увімкнення другого рядка
            local cur_y = reaper.ImGui_GetCursorPosY(ctx)
            reaper.ImGui_SetCursorPosY(ctx, cur_y + next_region_offset) -- відступ до другого рядка
            draw_centered_text(ctx, nextreg, second_font_index, second_font_scale, second_text_color, second_shadow_color, win_w) -- другий рядок
        end


        
        win_X, win_Y = reaper.ImGui_GetWindowPos(ctx)
        local hovered = reaper.ImGui_IsWindowHovered(ctx)
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
            if reaper.ImGui_IsWindowHovered(ctx) then
                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xFFFFFFFF)  -- білий при наведенні
            else
                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xFFFFFF00)  -- напівпрозорий
            end
            if reaper.ImGui_Button(ctx, "✕##close", button_size, button_size) then
                close_requested = true
            end
            reaper.ImGui_PopStyleColor(ctx, 4)
        end

        if hovered and reaper.ImGui_IsMouseClicked(ctx, 1, false) then
            reaper.ImGui_SetNextWindowSize(ctx, 200, 0, reaper.ImGui_Cond_Appearing())
            reaper.ImGui_OpenPopup(ctx, "context_menu")
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

