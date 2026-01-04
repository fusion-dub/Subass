local M = {}

-- === COLORS ===
M.colors = {
    WindowBg        = 0x444444FF,
    TitleBg         = 0x303030FF,
    TitleBgActive   = 0x505050FF,
    Header          = 0x606060FF,
    HeaderHovered   = 0x707070FF,
    HeaderActive    = 0x808080FF,
    Text            = 0xE0E0E0FF,
    Border          = 0x606060FF,

    Button          = 0x353535FF,
    ButtonHovered   = 0x606060FF,
    ButtonActive    = 0x707070FF,

    FrameBg         = 0x353535FF,
    FrameBgHovered  = 0x383838FF,
    FrameBgActive   = 0x484848FF,

    ResizeGrip        = 0x00000000,
    ResizeGripHovered = 0x00000000,
    ResizeGripActive  = 0x00000000,

    WordHighlight   = 0xFFCC00FF,
    MeaningText     = 0xBBBBBBFF
}

-- === STYLE VARS ===
M.vars = {
    WindowRounding  = 12.0,
    ChildRounding   = 8.0,
    FrameRounding   = 6.0,
    GrabRounding    = 6.0,
    TabRounding     = 6.0,
    WindowPadding   = {15.0, 15.0},
    ItemSpacing     = {8.0, 6.0}
}

function M.push(ctx)
    local c = M.colors
    local v = M.vars

    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(),        c.WindowBg)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBg(),         c.TitleBg)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgActive(),   c.TitleBgActive)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Header(),          c.Header)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderHovered(),   c.HeaderHovered)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderActive(),    c.HeaderActive)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(),            c.Text)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(),          c.Border)

    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),          c.Button)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(),   c.ButtonHovered)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(),    c.ButtonActive)

    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(),         c.FrameBg)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgHovered(),  c.FrameBgHovered)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgActive(),   c.FrameBgActive)

    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGrip(),        c.ResizeGrip)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripHovered(), c.ResizeGripHovered)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripActive(),  c.ResizeGripActive)

    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowRounding(), v.WindowRounding)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ChildRounding(),  v.ChildRounding)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameRounding(),  v.FrameRounding)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_GrabRounding(),   v.GrabRounding)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_TabRounding(),    v.TabRounding)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(),  v.WindowPadding[1], v.WindowPadding[2])
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(),    v.ItemSpacing[1], v.ItemSpacing[2])
end

function M.pop(ctx)
    reaper.ImGui_PopStyleColor(ctx, 17)
    reaper.ImGui_PopStyleVar(ctx, 7)
end

return M
