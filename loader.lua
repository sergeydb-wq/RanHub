--========================================================--
--  CUSTOM LOADER (config-driven)
--  Всё, что нужно менять, находится в CONFIG и CATALOG.
--========================================================--

local CONFIG = {
    SlateUrl   = "https://raw.githubusercontent.com/PulseZax/Slate/refs/heads/main/.lua",

    HubName    = "My Hub",
    Subtitle   = "script loader",
    Icon       = "zap",              -- иконка из набора lucide
    Size       = UDim2.fromOffset(700, 500),
    ToggleKey  = Enum.KeyCode.LeftControl,

    Theme      = "Ash",              -- пресет темы Slate
    Font       = "JosefinSans",
    Backdrop   = "aurora",           -- фон окна, nil чтобы отключить
    CornerRadius = 6,
    HideStroke = true,               -- убрать обводку окна

    GridColumns   = 2,
    GridHeight    = 206,
    GridMinWidth  = 196,

    AutoRunSupported = true,         -- сразу запускать скрипт, если игра найдена
    ShowUnsupportedNotice = true,    -- показывать предупреждение в неподдерживаемой игре
    LaunchTimeout = 6,               -- сек. ожидания перед "завис"
    ClickDebounce = 0.5,             -- защита от двойного клика
}

--========================================================--
--  КАТАЛОГ ИГР
--  Listed = false -> игра работает по автозапуску, но не видна в меню
--========================================================--
local CATALOG = {}

local function addGame(entry)
    entry.Places = entry.Places or {}
    if entry.Listed == nil then entry.Listed = true end
    entry.Tone = entry.Tone or Color3.fromRGB(90, 169, 255)
    table.insert(CATALOG, entry)
end

-- Image = прямая (raw) ссылка на картинку. Если не указана, берётся иконка игры по PlaceId.
-- ВАЖНО: впиши PlaceId / Universe, иначе автозапуск в самой игре не сработает
-- (в меню карточки при этом будут работать и без них).
addGame({
    Key = "carrypeople3",
    Name = "Carry People Simulator 3 [🎤]",
    Places = { 7267631004 },
    Universe = nil,                  -- TODO: вставь GameId (game.GameId), если знаешь
    Loader = "https://raw.githubusercontent.com/sergeydb-wq/RanHub/refs/heads/main/CarryPeopleSimulator3.lua",
    Image = "https://raw.githubusercontent.com/sergeydb-wq/Logos/main/carrypeoplesimulator3.png",
    Tone = Color3.fromRGB(255, 105, 180),
})

addGame({
    Key = "blockcraft",
    Name = "⛏️BlockCraft💎",
    Places = { 136169205786617 },
    Universe = nil,                  -- TODO: вставь GameId
    Loader = "https://raw.githubusercontent.com/sergeydb-wq/RanHub/refs/heads/main/BlockCraft.lua",
    Image = "https://raw.githubusercontent.com/sergeydb-wq/Logos/main/blockcraft.png",
    Tone = Color3.fromRGB(76, 175, 92),
})

-- addGame({
--     Key = "another",
--     Name = "Another Game",
--     Places = { 111, 222 },
--     Loader = "https://example.com/another.lua",
--     Listed = false,
-- })

--========================================================--
--  ЛОГИКА (обычно трогать не нужно)
--========================================================--
local function thumb(placeId)
    return string.format("rbxthumb://type=Asset&id=%d&w=150&h=150", placeId)
end

-- Скачивает картинку по URL и превращает её в asset, который понимает Roblox.
-- Нужны writefile / getcustomasset в экзекуторе; если их нет - вернётся nil.
local imageCache = {}
local function customImage(entry)
    if not entry.Image then return nil end
    if imageCache[entry.Key] then return imageCache[entry.Key] end
    local ok, asset = pcall(function()
        local folder = "CustomLoaderImages"
        if makefolder and isfolder and not isfolder(folder) then
            makefolder(folder)
        end
        local path = folder .. "/" .. entry.Key .. ".png"
        if not (isfile and isfile(path)) then
            writefile(path, game:HttpGet(entry.Image))
        end
        return getcustomasset(path)
    end)
    if ok and asset then
        imageCache[entry.Key] = asset
        return asset
    end
    return nil
end

local function launch(entry)
    return pcall(function()
        return loadstring(game:HttpGet(entry.Loader), "@" .. entry.Key)()
    end)
end

local function matchPlace(placeId, universeId)
    for _, entry in ipairs(CATALOG) do
        if entry.Universe and entry.Universe == universeId then
            return entry
        end
    end
    for _, entry in ipairs(CATALOG) do
        for _, id in ipairs(entry.Places) do
            if id == placeId then
                return entry
            end
        end
    end
    return nil
end

-- Делает карточку кликабельной целиком (мышь + тач)
local function arm(element, action)
    if type(element) ~= "table" then return end
    local last = 0
    for _, part in ipairs({ element.button, element.card, element.hitbox }) do
        if typeof(part) == "Instance" then
            pcall(function()
                part.Active = true
                part.InputBegan:Connect(function(input)
                    local t = input.UserInputType
                    if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then
                        return
                    end
                    if os.clock() - last < CONFIG.ClickDebounce then return end
                    last = os.clock()
                    action()
                end)
            end)
        end
    end
end

-- 1) Игра поддерживается -> запускаем и выходим
if CONFIG.AutoRunSupported then
    local supported = matchPlace(game.PlaceId, game.GameId)
    if supported then
        local ok, err = launch(supported)
        if not ok then
            warn(CONFIG.HubName .. ": " .. supported.Name .. " failed - " .. tostring(err))
        end
        return
    end
end

-- 2) Игра не найдена -> меню выбора
if type(_G.CustomLoader) == "table" then
    pcall(function() _G.CustomLoader.Window:Destroy() end)
end
_G.CustomLoader = {}

local Slate = loadstring(game:HttpGet(CONFIG.SlateUrl), "@Slate")()

pcall(function() Slate.Cleanup() end)
pcall(function() Slate:PreloadIcons({ "lucide" }) end)

local Window = Slate:CreateWindow({
    Name = CONFIG.HubName,
    Subtitle = CONFIG.Subtitle,
    Icon = CONFIG.Icon,
    Logo = true,
    Size = CONFIG.Size,
    ToggleKey = CONFIG.ToggleKey,
})

pcall(function() Slate.Theme.Preset(CONFIG.Theme) end)
pcall(function() Slate:SetFontFamily(CONFIG.Font) end)
if CONFIG.Backdrop then
    pcall(function() Window:SetBackdrop(CONFIG.Backdrop) end)
end
pcall(function()
    local corner = Window.root:FindFirstChildOfClass("UICorner")
    if corner then corner.CornerRadius = UDim.new(0, CONFIG.CornerRadius) end
    if CONFIG.HideStroke then
        local stroke = Window.root:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Thickness = 0 end
    end
end)

_G.CustomLoader.Window = Window

local function notify(desc, icon, tone, duration)
    Slate:Notify({
        Title = CONFIG.HubName,
        Description = desc,
        Icon = icon,
        Tone = tone,
        Duration = duration or 5,
    })
end

local Tab = Window:CreateTab({ Name = "Scripts", Icon = "layout-grid" })

local placeName = "this game"
pcall(function()
    local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
    if info and info.Name then placeName = info.Name end
end)

if CONFIG.ShowUnsupportedNotice then
    local notice = Tab:CreateSection({ Name = "Unsupported game" })
    notice:Paragraph({
        Name = "No script for " .. placeName,
        Description = "Scripts below may not work in this game.",
    })
end

do
    local list = Tab:CreateSection({ Name = "Available scripts" })
    local grid = list:Grid({
        Columns = CONFIG.GridColumns,
        Height = CONFIG.GridHeight,
        MinWidth = CONFIG.GridMinWidth,
    })

    for _, entry in ipairs(CATALOG) do
        if entry.Listed then
            local function start()
                notify("Starting " .. entry.Name, "play", nil, 5)
                task.spawn(function()
                    local finished, ok, err = false, nil, nil
                    task.spawn(function()
                        ok, err = launch(entry)
                        finished = true
                    end)
                    local waited = 0
                    while not finished and waited < CONFIG.LaunchTimeout do
                        task.wait(0.25)
                        waited += 0.25
                    end
                    if not finished then
                        notify(entry.Name .. " is taking too long", "triangle-alert", "Warning", 10)
                    elseif not ok then
                        notify(entry.Name .. " failed: " .. tostring(err), "circle-alert", "Danger", 10)
                    else
                        notify(entry.Name .. " started", "circle-check", "Success", 8)
                    end
                end)
            end

            local firstPlace = entry.Places[1]
            local card = grid:Invite({
                Name = entry.Name,
                Icon = customImage(entry) or (firstPlace and thumb(firstPlace)) or "gamepad-2",
                Stats = {
                    { Text = firstPlace and ("Place " .. tostring(firstPlace)) or "Custom", Dot = entry.Tone },
                },
                Game = "ROBLOX",
                GameIcon = "gamepad-2",
                Tone = entry.Tone,
                Glyph = "play",
                ButtonText = "Run",
                ButtonColor = entry.Tone,
                CopiedText = "Starting",
                Callback = start,
            })
            arm(card, start)
        end
    end
end

do
    local menu = Tab:CreateSection({ Name = "Menu" })
    menu:Button({
        Name = "Close menu",
        Icon = "x",
        Callback = function()
            pcall(function() Window:Destroy() end)
            _G.CustomLoader = nil
        end,
    })
end

if CONFIG.ShowUnsupportedNotice then
    notify("No script for " .. placeName .. ". Pick one to run it anyway.", "triangle-alert", "Warning", 10)
end
