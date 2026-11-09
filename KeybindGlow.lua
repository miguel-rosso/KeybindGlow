-- KeybindGlow
-- While holding Shift / Ctrl / Alt, draws a colored border on the action buttons
-- whose keybind uses EXACTLY that modifier combination.
--   Shift      -> buttons bound to SHIFT-x
--   Ctrl       -> buttons bound to CTRL-x
--   Shift+Ctrl -> buttons bound to CTRL-SHIFT-x

local ADDON_NAME = "KeybindGlow"
local PREFIX = "|cff1a8cffKeybindGlow|r"

---------------------------------------------------------------------------
-- Localization (English default, Spanish for esES / esMX clients)
---------------------------------------------------------------------------
local L = {
    NO_PICKER    = "color picker not available; use /kg color <name> or /kg color #RRGGBB",
    SUBTITLE     = "Highlights the abilities bound to the modifier you are holding.",
    BORDER_COLOR = "Border color:",
    PICK_COLOR   = "Pick color...",
    QUICK_COLORS = "Quick colors:",
    THICKNESS    = "Border thickness: %d px",
    COMBAT_ONLY  = "Combat only",
    PREVIEW      = "Preview (show the border on every button with a modifier binding)",
    RESET        = "Reset (blue)",
    NO_PANEL     = "could not open the options panel; see /kg help",
    COLOR_SET    = "color: %s",
    UNKNOWN      = "unknown color. Try: %s or #RRGGBB",
    COMBAT_STATE = "combat only: %s",
    ON = "ON", OFF = "OFF",
    HELP = {
        "commands:",
        "  /kg                 open the options panel",
        "  /kg color           open the color picker",
        "  /kg color pink      colors: %s",
        "  /kg color #FF69B4   hex color",
        "  /kg color 1 0.4 0.7 RGB color (0-1)",
        "  /kg size N          border thickness 1-8 px",
        "  /kg combat          toggle combat only",
        "  /kg reset           reset to default blue",
        "  Buttons detected: %d",
    },
    COLORS = {
        blue = "blue", pink = "pink", magenta = "magenta", purple = "purple", red = "red",
        orange = "orange", yellow = "yellow", green = "green", cyan = "cyan", white = "white",
        crimson = "crimson", coral = "coral", gold = "gold", lime = "lime", teal = "teal",
        sky = "sky", lavender = "lavender", silver = "silver",
    },
}

local locale = GetLocale()
if locale == "esES" or locale == "esMX" then
    L.NO_PICKER    = "el selector de color no esta disponible; usa /kg color <nombre> o /kg color #RRGGBB"
    L.SUBTITLE     = "Resalta las habilidades bindeadas al modificador que mantienes pulsado."
    L.BORDER_COLOR = "Color del borde:"
    L.PICK_COLOR   = "Elegir color..."
    L.QUICK_COLORS = "Colores rapidos:"
    L.THICKNESS    = "Grosor del borde: %d px"
    L.COMBAT_ONLY  = "Solo en combate"
    L.PREVIEW      = "Vista previa (muestra el borde en todos los botones con modificador)"
    L.RESET        = "Restablecer (azul)"
    L.NO_PANEL     = "no se pudo abrir el panel; usa /kg ayuda"
    L.COLOR_SET    = "color: %s"
    L.UNKNOWN      = "color no reconocido. Prueba: %s o #RRGGBB"
    L.COMBAT_STATE = "solo en combate: %s"
    L.ON, L.OFF = "SI", "NO"
    L.HELP = {
        "comandos:",
        "  /kg                 abre el panel de opciones",
        "  /kg color           abre la rueda de color",
        "  /kg color rosa      colores: %s",
        "  /kg color #FF69B4   color en hexadecimal",
        "  /kg color 1 0.4 0.7 color en RGB (0-1)",
        "  /kg grosor N        grosor 1-8 px",
        "  /kg combate         activar/desactivar solo en combate",
        "  /kg reset           volver al azul por defecto",
        "  Botones detectados: %d",
    }
    L.COLORS = {
        blue = "azul", pink = "rosa", magenta = "fucsia", purple = "morado", red = "rojo",
        orange = "naranja", yellow = "amarillo", green = "verde", cyan = "cian", white = "blanco",
        crimson = "carmesi", coral = "coral", gold = "dorado", lime = "lima", teal = "turquesa",
        sky = "celeste", lavender = "lavanda", silver = "plata",
    }
end

local DEFAULTS = {
    r = 0.10, g = 0.55, b = 1.00, a = 1.00, -- blue
    thickness = 2,
    combatOnly = false,
}

-- Named colors for /kg color <name>
local PRESETS = {
    blue    = { 0.10, 0.55, 1.00 },
    pink    = { 1.00, 0.41, 0.71 },
    magenta = { 1.00, 0.00, 0.80 },
    purple  = { 0.60, 0.30, 1.00 },
    red     = { 1.00, 0.15, 0.15 },
    orange  = { 1.00, 0.55, 0.00 },
    yellow  = { 1.00, 0.90, 0.10 },
    green   = { 0.20, 1.00, 0.30 },
    cyan    = { 0.00, 0.90, 1.00 },
    white   = { 1.00, 1.00, 1.00 },
    crimson  = { 0.75, 0.05, 0.20 },
    coral    = { 1.00, 0.50, 0.40 },
    gold     = { 1.00, 0.75, 0.00 },
    lime     = { 0.70, 1.00, 0.00 },
    teal     = { 0.00, 0.70, 0.60 },
    sky      = { 0.50, 0.80, 1.00 },
    lavender = { 0.75, 0.65, 1.00 },
    silver   = { 0.70, 0.70, 0.75 },
}
local PRESET_ORDER = {
    "blue", "sky", "cyan", "teal", "green", "lime", "yellow", "gold", "orange",
    "coral", "red", "crimson", "pink", "magenta", "purple", "lavender", "silver", "white",
}
local SWATCHES_PER_ROW = 9

-- Spanish color names are always accepted as aliases
local COLOR_ALIASES = {
    azul = "blue", rosa = "pink", fucsia = "magenta", morado = "purple", rojo = "red",
    naranja = "orange", amarillo = "yellow", verde = "green", cian = "cyan", blanco = "white",
    carmesi = "crimson", ["carmesí"] = "crimson", dorado = "gold", oro = "gold", lima = "lime",
    turquesa = "teal", celeste = "sky", lavanda = "lavender", plata = "silver", gris = "silver",
}

local function localizedColorList()
    local out = {}
    for i, name in ipairs(PRESET_ORDER) do out[i] = L.COLORS[name] end
    return table.concat(out, ", ")
end

-- Blizzard action bars (Mainline API) and their binding command
local BARS = {
    { "ActionButton",              "ACTIONBUTTON",           12 },
    { "MultiBarBottomLeftButton",  "MULTIACTIONBAR1BUTTON",  12 },
    { "MultiBarBottomRightButton", "MULTIACTIONBAR2BUTTON",  12 },
    { "MultiBarRightButton",       "MULTIACTIONBAR3BUTTON",  12 },
    { "MultiBarLeftButton",        "MULTIACTIONBAR4BUTTON",  12 },
    { "MultiBar5Button",           "MULTIACTIONBAR5BUTTON",  12 },
    { "MultiBar6Button",           "MULTIACTIONBAR6BUTTON",  12 },
    { "MultiBar7Button",           "MULTIACTIONBAR7BUTTON",  12 },
    { "PetActionButton",           "BONUSACTIONBUTTON",      10 },
    { "StanceButton",              "SHAPESHIFTBUTTON",       10 },
}

local MOD_ORDER = { "ALT", "CTRL", "SHIFT", "META" }
local IS_MOD = { ALT = true, CTRL = true, SHIFT = true, META = true }

local db
local buttons = {}   -- { button, command, borders = {4 textures}, combos = { ["SHIFT"]=true, ... } }
local preview = false
local panel, category

-- "ALT-CTRL-1" -> "ALT-CTRL" ; "1" -> ""
local function modsFromBinding(binding)
    local present = {}
    for part in string.gmatch(binding, "[^%-]+") do
        if IS_MOD[part] then present[part] = true end
    end
    local out = {}
    for _, m in ipairs(MOD_ORDER) do
        if present[m] then out[#out + 1] = m end
    end
    return table.concat(out, "-")
end

local function pressedMods()
    local out = {}
    if IsAltKeyDown() then out[#out + 1] = "ALT" end
    if IsControlKeyDown() then out[#out + 1] = "CTRL" end
    if IsShiftKeyDown() then out[#out + 1] = "SHIFT" end
    if IsMetaKeyDown and IsMetaKeyDown() then out[#out + 1] = "META" end
    return table.concat(out, "-")
end

local function createBorders(button)
    local t = {}
    for i = 1, 4 do
        local tex = button:CreateTexture(nil, "OVERLAY", nil, 7)
        tex:Hide()
        t[i] = tex
    end
    return t
end

local function applyStyle(entry)
    local b, g = entry.button, db.thickness
    local top, bottom, left, right = unpack(entry.borders)
    for _, tex in ipairs(entry.borders) do
        tex:SetColorTexture(db.r, db.g, db.b, db.a)
        tex:ClearAllPoints()
    end
    top:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", b, "TOPRIGHT", 0, 0)
    top:SetHeight(g)
    bottom:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 0, 0)
    bottom:SetHeight(g)
    left:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 0, 0)
    left:SetWidth(g)
    right:SetPoint("TOPRIGHT", b, "TOPRIGHT", 0, 0)
    right:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 0, 0)
    right:SetWidth(g)
end

local function show(entry, visible)
    for _, tex in ipairs(entry.borders) do
        if visible then tex:Show() else tex:Hide() end
    end
end

local function collectButtons()
    for _, def in ipairs(BARS) do
        local prefix, command, n = def[1], def[2], def[3]
        for i = 1, n do
            local button = _G[prefix .. i]
            if button and not button.__KeybindGlow then
                local entry = { button = button, command = command .. i, borders = createBorders(button), combos = {} }
                button.__KeybindGlow = entry
                applyStyle(entry)
                buttons[#buttons + 1] = entry
            end
        end
    end
end

local function updateBindings()
    for _, entry in ipairs(buttons) do
        wipe(entry.combos)
        local bindings = { GetBindingKey(entry.command) }
        for _, binding in ipairs(bindings) do
            local m = modsFromBinding(binding)
            if m ~= "" then entry.combos[m] = true end
        end
    end
end

local function refresh()
    if not db then return end
    if preview then
        -- Show the border on every button that has a binding with a modifier
        for _, entry in ipairs(buttons) do
            show(entry, next(entry.combos) ~= nil and entry.button:IsVisible())
        end
        return
    end
    local mods = pressedMods()
    if db.combatOnly and not InCombatLockdown() then mods = "" end
    local active = mods ~= ""
    for _, entry in ipairs(buttons) do
        show(entry, active and entry.combos[mods] == true and entry.button:IsVisible())
    end
end

local updatePanel -- defined below

local function applyAll()
    for _, entry in ipairs(buttons) do applyStyle(entry) end
    refresh()
    if updatePanel then updatePanel() end
end

local function setColor(r, g, b)
    db.r = math.max(0, math.min(1, r))
    db.g = math.max(0, math.min(1, g))
    db.b = math.max(0, math.min(1, b))
    applyAll()
end

-- "#ff69b4" or "ff69b4" -> r, g, b (0-1)
local function hexToRgb(hex)
    hex = hex:gsub("#", "")
    if not hex:match("^%x%x%x%x%x%x$") then return nil end
    return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
end

---------------------------------------------------------------------------
-- Blizzard color picker
---------------------------------------------------------------------------
local function openColorPicker()
    if not (ColorPickerFrame and ColorPickerFrame.SetupColorPickerAndShow) then
        print(PREFIX .. " " .. L.NO_PICKER)
        return
    end
    local before = { db.r, db.g, db.b }
    ColorPickerFrame:SetupColorPickerAndShow({
        r = db.r, g = db.g, b = db.b,
        hasOpacity = false,
        swatchFunc = function()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            setColor(r, g, b)
        end,
        cancelFunc = function()
            setColor(before[1], before[2], before[3])
        end,
    })
end

---------------------------------------------------------------------------
-- Options panel (Options > AddOns > KeybindGlow)
---------------------------------------------------------------------------
local function createPanel()
    if panel or not (Settings and Settings.RegisterCanvasLayoutCategory) then return end

    panel = CreateFrame("Frame")
    panel.name = ADDON_NAME

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(ADDON_NAME)

    local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    sub:SetText(L.SUBTITLE)

    -- Current color swatch + button that opens the color picker
    local lblColor = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    lblColor:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -24)
    lblColor:SetText(L.BORDER_COLOR)

    local sample = CreateFrame("Button", nil, panel)
    sample:SetSize(26, 26)
    sample:SetPoint("LEFT", lblColor, "RIGHT", 10, 0)
    local bgSample = sample:CreateTexture(nil, "BACKGROUND")
    bgSample:SetAllPoints()
    bgSample:SetColorTexture(0, 0, 0, 1)
    local swatch = sample:CreateTexture(nil, "ARTWORK")
    swatch:SetPoint("TOPLEFT", 2, -2)
    swatch:SetPoint("BOTTOMRIGHT", -2, 2)
    sample:SetScript("OnClick", openColorPicker)

    local btnPicker = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btnPicker:SetSize(150, 24)
    btnPicker:SetPoint("LEFT", sample, "RIGHT", 10, 0)
    btnPicker:SetText(L.PICK_COLOR)
    btnPicker:SetScript("OnClick", openColorPicker)

    -- Quick colors
    local lblQuick = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    lblQuick:SetPoint("TOPLEFT", lblColor, "BOTTOMLEFT", 0, -26)
    lblQuick:SetText(L.QUICK_COLORS)

    local previous, rowStart
    for i, name in ipairs(PRESET_ORDER) do
        local c = PRESETS[name]
        local p = CreateFrame("Button", nil, panel)
        p:SetSize(22, 22)
        if i == 1 then
            p:SetPoint("TOPLEFT", lblQuick, "BOTTOMLEFT", 0, -8)
            rowStart = p
        elseif (i - 1) % SWATCHES_PER_ROW == 0 then
            p:SetPoint("TOPLEFT", rowStart, "BOTTOMLEFT", 0, -6)
            rowStart = p
        else
            p:SetPoint("LEFT", previous, "RIGHT", 6, 0)
        end
        local bg = p:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0, 0, 0, 1)
        local tex = p:CreateTexture(nil, "ARTWORK")
        tex:SetPoint("TOPLEFT", 2, -2)
        tex:SetPoint("BOTTOMRIGHT", -2, 2)
        tex:SetColorTexture(c[1], c[2], c[3], 1)
        p:SetScript("OnClick", function() setColor(c[1], c[2], c[3]) end)
        p:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            local label = L.COLORS[name]
            GameTooltip:SetText(label:sub(1, 1):upper() .. label:sub(2))
            GameTooltip:Show()
        end)
        p:SetScript("OnLeave", function() GameTooltip:Hide() end)
        previous = p
    end

    -- Thickness
    local lblThickness = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    local swatchRows = math.ceil(#PRESET_ORDER / SWATCHES_PER_ROW)
    lblThickness:SetPoint("TOPLEFT", lblQuick, "BOTTOMLEFT", 0, -22 - swatchRows * 28)

    local minus = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    minus:SetSize(28, 22)
    minus:SetPoint("LEFT", lblThickness, "RIGHT", 10, 0)
    minus:SetText("-")
    minus:SetScript("OnClick", function() db.thickness = math.max(1, db.thickness - 1); applyAll() end)

    local plus = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    plus:SetSize(28, 22)
    plus:SetPoint("LEFT", minus, "RIGHT", 4, 0)
    plus:SetText("+")
    plus:SetScript("OnClick", function() db.thickness = math.min(8, db.thickness + 1); applyAll() end)

    -- Combat only
    local chkCombat = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    chkCombat:SetPoint("TOPLEFT", lblThickness, "BOTTOMLEFT", -4, -16)
    local lblCombat = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    lblCombat:SetPoint("LEFT", chkCombat, "RIGHT", 4, 0)
    lblCombat:SetText(L.COMBAT_ONLY)
    chkCombat:SetScript("OnClick", function(self)
        db.combatOnly = self:GetChecked() and true or false
        refresh()
    end)

    -- Preview
    local chkPreview = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    chkPreview:SetPoint("TOPLEFT", chkCombat, "BOTTOMLEFT", 0, -4)
    local lblPreview = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    lblPreview:SetPoint("LEFT", chkPreview, "RIGHT", 4, 0)
    lblPreview:SetText(L.PREVIEW)
    chkPreview:SetScript("OnClick", function(self)
        preview = self:GetChecked() and true or false
        refresh()
    end)
    panel:SetScript("OnHide", function()
        preview = false
        chkPreview:SetChecked(false)
        refresh()
    end)

    -- Reset
    local btnReset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btnReset:SetSize(150, 24)
    btnReset:SetPoint("TOPLEFT", chkPreview, "BOTTOMLEFT", 4, -16)
    btnReset:SetText(L.RESET)
    btnReset:SetScript("OnClick", function()
        for k, v in pairs(DEFAULTS) do db[k] = v end
        applyAll()
    end)

    updatePanel = function()
        swatch:SetColorTexture(db.r, db.g, db.b, 1)
        lblThickness:SetText(L.THICKNESS:format(db.thickness))
        chkCombat:SetChecked(db.combatOnly)
    end
    panel:SetScript("OnShow", updatePanel)
    updatePanel()

    category = Settings.RegisterCanvasLayoutCategory(panel, ADDON_NAME)
    Settings.RegisterAddOnCategory(category)
end

local function openPanel()
    if category and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(category:GetID())
    else
        print(PREFIX .. " " .. L.NO_PANEL)
    end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("UPDATE_BINDINGS")
f:RegisterEvent("MODIFIER_STATE_CHANGED")
f:RegisterEvent("PLAYER_REGEN_DISABLED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")

f:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= ADDON_NAME then return end
        KeybindGlowDB = KeybindGlowDB or {}
        db = KeybindGlowDB
        for k, v in pairs(DEFAULTS) do
            if db[k] == nil then db[k] = v end
        end
        createPanel()
        return
    end
    if not db then return end

    if event == "PLAYER_ENTERING_WORLD" or event == "UPDATE_BINDINGS" then
        collectButtons()
        updateBindings()
        refresh()
    else -- MODIFIER_STATE_CHANGED / entering-leaving combat
        refresh()
    end
end)

---------------------------------------------------------------------------
-- Slash commands: /kg, /keybindglow (English and Spanish subcommands)
---------------------------------------------------------------------------
local function help()
    print(PREFIX .. " " .. L.HELP[1])
    for i = 2, #L.HELP - 1 do
        local line = L.HELP[i]
        if line:find("%s", 1, true) then line = line:format(localizedColorList()) end
        print(line)
    end
    print(L.HELP[#L.HELP]:format(#buttons))
end

SLASH_KEYBINDGLOW1 = "/kg"
SLASH_KEYBINDGLOW2 = "/keybindglow"
SlashCmdList.KEYBINDGLOW = function(msg)
    local cmd, a, b, c = strsplit(" ", strtrim(msg or ""):lower())
    if cmd == "" then
        if category then openPanel() else help() end
    elseif cmd == "color" then
        if not a or a == "" then
            openColorPicker()
        elseif PRESETS[COLOR_ALIASES[a] or a] then
            local key = COLOR_ALIASES[a] or a
            local p = PRESETS[key]
            setColor(p[1], p[2], p[3])
            print(PREFIX .. " " .. L.COLOR_SET:format(L.COLORS[key]))
        elseif hexToRgb(a) then
            setColor(hexToRgb(a))
        elseif tonumber(a) and tonumber(b) and tonumber(c) then
            setColor(tonumber(a), tonumber(b), tonumber(c))
        else
            print(PREFIX .. " " .. L.UNKNOWN:format(localizedColorList()))
        end
    elseif (cmd == "size" or cmd == "grosor") and tonumber(a) then
        db.thickness = math.max(1, math.min(8, math.floor(tonumber(a))))
        applyAll()
    elseif cmd == "combat" or cmd == "combate" then
        db.combatOnly = not db.combatOnly
        print(PREFIX .. " " .. L.COMBAT_STATE:format(db.combatOnly and L.ON or L.OFF))
        applyAll()
    elseif cmd == "reset" then
        for k, v in pairs(DEFAULTS) do db[k] = v end
        applyAll()
    else
        help()
    end
end
