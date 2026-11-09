-- BordeModificador
-- Al mantener Shift / Ctrl / Alt, pinta un borde de color en los botones de accion
-- cuyo atajo usa EXACTAMENTE esa combinacion de modificadores.
--   Shift      -> botones bindeados a SHIFT-x
--   Ctrl       -> botones bindeados a CTRL-x
--   Shift+Ctrl -> botones bindeados a CTRL-SHIFT-x

local NOMBRE = "BordeModificador"
local PREFIJO = "|cff1a8cffBordeModificador|r"

local DEFAULTS = {
    r = 0.10, g = 0.55, b = 1.00, a = 1.00, -- azul
    grosor = 2,
    soloCombate = false,
}

-- Colores con nombre para /bmod color <nombre>
local PRESETS = {
    azul     = { 0.10, 0.55, 1.00 },
    rosa     = { 1.00, 0.41, 0.71 },
    fucsia   = { 1.00, 0.00, 0.80 },
    morado   = { 0.60, 0.30, 1.00 },
    rojo     = { 1.00, 0.15, 0.15 },
    naranja  = { 1.00, 0.55, 0.00 },
    amarillo = { 1.00, 0.90, 0.10 },
    verde    = { 0.20, 1.00, 0.30 },
    cian     = { 0.00, 0.90, 1.00 },
    blanco   = { 1.00, 1.00, 1.00 },
}
local ORDEN_PRESETS = { "azul", "rosa", "fucsia", "morado", "rojo", "naranja", "amarillo", "verde", "cian", "blanco" }

-- Barras de Blizzard (API Mainline, la que usa Forever) y su comando de atajo
local BARRAS = {
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

local ORDEN_MODS = { "ALT", "CTRL", "SHIFT", "META" }
local ES_MOD = { ALT = true, CTRL = true, SHIFT = true, META = true }

local db
local botones = {}   -- { boton, comando, bordes = {4 texturas}, combos = { ["SHIFT"]=true, ... } }
local vistaPrevia = false
local panel, categoria

-- "ALT-CTRL-1" -> "ALT-CTRL" ; "1" -> ""
local function modsDeAtajo(atajo)
    local presentes = {}
    for parte in string.gmatch(atajo, "[^%-]+") do
        if ES_MOD[parte] then presentes[parte] = true end
    end
    local out = {}
    for _, m in ipairs(ORDEN_MODS) do
        if presentes[m] then out[#out + 1] = m end
    end
    return table.concat(out, "-")
end

local function modsPulsados()
    local out = {}
    if IsAltKeyDown() then out[#out + 1] = "ALT" end
    if IsControlKeyDown() then out[#out + 1] = "CTRL" end
    if IsShiftKeyDown() then out[#out + 1] = "SHIFT" end
    if IsMetaKeyDown and IsMetaKeyDown() then out[#out + 1] = "META" end
    return table.concat(out, "-")
end

local function crearBordes(boton)
    local t = {}
    for i = 1, 4 do
        local tex = boton:CreateTexture(nil, "OVERLAY", nil, 7)
        tex:Hide()
        t[i] = tex
    end
    return t
end

local function aplicarEstilo(entry)
    local b, g = entry.boton, db.grosor
    local top, bot, izq, der = unpack(entry.bordes)
    for _, tex in ipairs(entry.bordes) do
        tex:SetColorTexture(db.r, db.g, db.b, db.a)
        tex:ClearAllPoints()
    end
    top:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", b, "TOPRIGHT", 0, 0)
    top:SetHeight(g)
    bot:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 0, 0)
    bot:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 0, 0)
    bot:SetHeight(g)
    izq:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
    izq:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 0, 0)
    izq:SetWidth(g)
    der:SetPoint("TOPRIGHT", b, "TOPRIGHT", 0, 0)
    der:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 0, 0)
    der:SetWidth(g)
end

local function mostrar(entry, si)
    for _, tex in ipairs(entry.bordes) do
        if si then tex:Show() else tex:Hide() end
    end
end

local function recolectarBotones()
    for _, def in ipairs(BARRAS) do
        local prefijo, comando, n = def[1], def[2], def[3]
        for i = 1, n do
            local boton = _G[prefijo .. i]
            if boton and not boton.__BordeMod then
                local entry = { boton = boton, comando = comando .. i, bordes = crearBordes(boton), combos = {} }
                boton.__BordeMod = entry
                aplicarEstilo(entry)
                botones[#botones + 1] = entry
            end
        end
    end
end

local function actualizarAtajos()
    for _, entry in ipairs(botones) do
        wipe(entry.combos)
        local atajos = { GetBindingKey(entry.comando) }
        for _, atajo in ipairs(atajos) do
            local m = modsDeAtajo(atajo)
            if m ~= "" then entry.combos[m] = true end
        end
    end
end

local function refrescar()
    if not db then return end
    if vistaPrevia then
        -- Muestra el borde en todos los botones que tengan algun atajo con modificador
        for _, entry in ipairs(botones) do
            mostrar(entry, next(entry.combos) ~= nil and entry.boton:IsVisible())
        end
        return
    end
    local mods = modsPulsados()
    if db.soloCombate and not InCombatLockdown() then mods = "" end
    local activo = mods ~= ""
    for _, entry in ipairs(botones) do
        mostrar(entry, activo and entry.combos[mods] == true and entry.boton:IsVisible())
    end
end

local actualizarPanel -- se define mas abajo

local function aplicarTodo()
    for _, entry in ipairs(botones) do aplicarEstilo(entry) end
    refrescar()
    if actualizarPanel then actualizarPanel() end
end

local function ponerColor(r, g, b)
    db.r = math.max(0, math.min(1, r))
    db.g = math.max(0, math.min(1, g))
    db.b = math.max(0, math.min(1, b))
    aplicarTodo()
end

-- "#ff69b4" o "ff69b4" -> r, g, b (0-1)
local function hexARgb(hex)
    hex = hex:gsub("#", "")
    if not hex:match("^%x%x%x%x%x%x$") then return nil end
    return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
end

---------------------------------------------------------------------------
-- Selector de color de Blizzard (rueda de color)
---------------------------------------------------------------------------
local function abrirSelectorColor()
    if not (ColorPickerFrame and ColorPickerFrame.SetupColorPickerAndShow) then
        print(PREFIJO .. " el selector de color no esta disponible; usa /bmod color <nombre> o /bmod color #RRGGBB")
        return
    end
    local antes = { db.r, db.g, db.b }
    ColorPickerFrame:SetupColorPickerAndShow({
        r = db.r, g = db.g, b = db.b,
        hasOpacity = false,
        swatchFunc = function()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            ponerColor(r, g, b)
        end,
        cancelFunc = function()
            ponerColor(antes[1], antes[2], antes[3])
        end,
    })
end

---------------------------------------------------------------------------
-- Panel de opciones (Opciones > AddOns > BordeModificador)
---------------------------------------------------------------------------
local function crearPanel()
    if panel or not (Settings and Settings.RegisterCanvasLayoutCategory) then return end

    panel = CreateFrame("Frame")
    panel.name = NOMBRE

    local titulo = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    titulo:SetPoint("TOPLEFT", 16, -16)
    titulo:SetText(NOMBRE)

    local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", titulo, "BOTTOMLEFT", 0, -6)
    sub:SetText("Borde en las habilidades bindeadas al modificador que mantienes pulsado.")

    -- Muestra del color actual + boton que abre la rueda de color
    local lblColor = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    lblColor:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -24)
    lblColor:SetText("Color del borde:")

    local muestra = CreateFrame("Button", nil, panel)
    muestra:SetSize(26, 26)
    muestra:SetPoint("LEFT", lblColor, "RIGHT", 10, 0)
    local fondo = muestra:CreateTexture(nil, "BACKGROUND")
    fondo:SetAllPoints()
    fondo:SetColorTexture(0, 0, 0, 1)
    local swatch = muestra:CreateTexture(nil, "ARTWORK")
    swatch:SetPoint("TOPLEFT", 2, -2)
    swatch:SetPoint("BOTTOMRIGHT", -2, 2)
    muestra:SetScript("OnClick", abrirSelectorColor)

    local btnRueda = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btnRueda:SetSize(150, 24)
    btnRueda:SetPoint("LEFT", muestra, "RIGHT", 10, 0)
    btnRueda:SetText("Elegir color...")
    btnRueda:SetScript("OnClick", abrirSelectorColor)

    -- Colores rapidos
    local lblRapidos = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    lblRapidos:SetPoint("TOPLEFT", lblColor, "BOTTOMLEFT", 0, -26)
    lblRapidos:SetText("Colores rapidos:")

    local anterior
    for i, nombre in ipairs(ORDEN_PRESETS) do
        local c = PRESETS[nombre]
        local p = CreateFrame("Button", nil, panel)
        p:SetSize(22, 22)
        if i == 1 then
            p:SetPoint("TOPLEFT", lblRapidos, "BOTTOMLEFT", 0, -8)
        else
            p:SetPoint("LEFT", anterior, "RIGHT", 6, 0)
        end
        local bg = p:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0, 0, 0, 1)
        local tex = p:CreateTexture(nil, "ARTWORK")
        tex:SetPoint("TOPLEFT", 2, -2)
        tex:SetPoint("BOTTOMRIGHT", -2, 2)
        tex:SetColorTexture(c[1], c[2], c[3], 1)
        p:SetScript("OnClick", function() ponerColor(c[1], c[2], c[3]) end)
        p:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(nombre:sub(1, 1):upper() .. nombre:sub(2))
            GameTooltip:Show()
        end)
        p:SetScript("OnLeave", function() GameTooltip:Hide() end)
        anterior = p
    end

    -- Grosor
    local lblGrosor = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    lblGrosor:SetPoint("TOPLEFT", lblRapidos, "BOTTOMLEFT", 0, -50)

    local menos = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    menos:SetSize(28, 22)
    menos:SetPoint("LEFT", lblGrosor, "RIGHT", 10, 0)
    menos:SetText("-")
    menos:SetScript("OnClick", function() db.grosor = math.max(1, db.grosor - 1); aplicarTodo() end)

    local mas = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    mas:SetSize(28, 22)
    mas:SetPoint("LEFT", menos, "RIGHT", 4, 0)
    mas:SetText("+")
    mas:SetScript("OnClick", function() db.grosor = math.min(8, db.grosor + 1); aplicarTodo() end)

    -- Solo en combate
    local chkCombate = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    chkCombate:SetPoint("TOPLEFT", lblGrosor, "BOTTOMLEFT", -4, -16)
    local lblCombate = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    lblCombate:SetPoint("LEFT", chkCombate, "RIGHT", 4, 0)
    lblCombate:SetText("Solo en combate")
    chkCombate:SetScript("OnClick", function(self)
        db.soloCombate = self:GetChecked() and true or false
        refrescar()
    end)

    -- Vista previa
    local chkPrevia = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    chkPrevia:SetPoint("TOPLEFT", chkCombate, "BOTTOMLEFT", 0, -4)
    local lblPrevia = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    lblPrevia:SetPoint("LEFT", chkPrevia, "RIGHT", 4, 0)
    lblPrevia:SetText("Vista previa (muestra el borde en todos los botones con modificador)")
    chkPrevia:SetScript("OnClick", function(self)
        vistaPrevia = self:GetChecked() and true or false
        refrescar()
    end)
    panel:SetScript("OnHide", function()
        vistaPrevia = false
        chkPrevia:SetChecked(false)
        refrescar()
    end)

    -- Restablecer
    local btnReset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btnReset:SetSize(150, 24)
    btnReset:SetPoint("TOPLEFT", chkPrevia, "BOTTOMLEFT", 4, -16)
    btnReset:SetText("Restablecer (azul)")
    btnReset:SetScript("OnClick", function()
        for k, v in pairs(DEFAULTS) do db[k] = v end
        aplicarTodo()
    end)

    actualizarPanel = function()
        swatch:SetColorTexture(db.r, db.g, db.b, 1)
        lblGrosor:SetText("Grosor del borde: " .. db.grosor .. " px")
        chkCombate:SetChecked(db.soloCombate)
    end
    panel:SetScript("OnShow", actualizarPanel)
    actualizarPanel()

    categoria = Settings.RegisterCanvasLayoutCategory(panel, NOMBRE)
    Settings.RegisterAddOnCategory(categoria)
end

local function abrirPanel()
    if categoria and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(categoria:GetID())
    else
        print(PREFIJO .. " no se pudo abrir el panel; usa los comandos de /bmod ayuda")
    end
end

---------------------------------------------------------------------------
-- Eventos
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
        if arg1 ~= NOMBRE then return end
        BordeModificadorDB = BordeModificadorDB or {}
        db = BordeModificadorDB
        for k, v in pairs(DEFAULTS) do
            if db[k] == nil then db[k] = v end
        end
        crearPanel()
        return
    end
    if not db then return end

    if event == "PLAYER_ENTERING_WORLD" or event == "UPDATE_BINDINGS" then
        recolectarBotones()
        actualizarAtajos()
        refrescar()
    else -- MODIFIER_STATE_CHANGED / entrar-salir de combate
        refrescar()
    end
end)

---------------------------------------------------------------------------
-- Comandos: /bmod
---------------------------------------------------------------------------
local function ayuda()
    print(PREFIJO .. " comandos:")
    print("  /bmod                 abre el panel de opciones")
    print("  /bmod color           abre la rueda de color")
    print("  /bmod color rosa      colores: " .. table.concat(ORDEN_PRESETS, ", "))
    print("  /bmod color #FF69B4   color en hexadecimal")
    print("  /bmod color 1 0.4 0.7 color en RGB (0-1)")
    print("  /bmod grosor N        grosor 1-8 px")
    print("  /bmod combate         activar/desactivar solo en combate")
    print("  /bmod reset           volver al azul por defecto")
    print("  Botones detectados: " .. #botones)
end

SLASH_BORDEMODIFICADOR1 = "/bmod"
SlashCmdList.BORDEMODIFICADOR = function(msg)
    local cmd, a, b, c = strsplit(" ", strtrim(msg or ""):lower())
    if cmd == "" then
        if categoria then abrirPanel() else ayuda() end
    elseif cmd == "color" then
        if not a or a == "" then
            abrirSelectorColor()
        elseif PRESETS[a] then
            local p = PRESETS[a]
            ponerColor(p[1], p[2], p[3])
            print(PREFIJO .. " color: " .. a)
        elseif hexARgb(a) then
            ponerColor(hexARgb(a))
        elseif tonumber(a) and tonumber(b) and tonumber(c) then
            ponerColor(tonumber(a), tonumber(b), tonumber(c))
        else
            print(PREFIJO .. " color no reconocido. Prueba: " .. table.concat(ORDEN_PRESETS, ", ") .. " o #RRGGBB")
        end
    elseif cmd == "grosor" and tonumber(a) then
        db.grosor = math.max(1, math.min(8, math.floor(tonumber(a))))
        aplicarTodo()
    elseif cmd == "combate" then
        db.soloCombate = not db.soloCombate
        print(PREFIJO .. " solo en combate: " .. (db.soloCombate and "SI" or "NO"))
        aplicarTodo()
    elseif cmd == "reset" then
        for k, v in pairs(DEFAULTS) do db[k] = v end
        aplicarTodo()
    else
        ayuda()
    end
end
