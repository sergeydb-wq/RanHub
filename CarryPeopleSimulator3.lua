--[[
╔══════════════════════════════════════════════════════════════════╗
║  Ran Hub — Carry People 3                                        ║
║  UI: NurLib (стиль Nursultan)                                    ║
║                                                                  ║
║  Меню: Right Ctrl   |   Panic: клик по иконке игрока слева снизу ║
╚══════════════════════════════════════════════════════════════════╝
]]

--// ═════════════════════ НАСТРОЙКИ ═════════════════════
local CONFIG = {
    HubName     = "Ran Hub",
    LogoText    = "R",
    LogoUrl     = "https://raw.githubusercontent.com/sergeydb-wq/Logos/refs/heads/main/IMG_3726.png",
    IconsBase   = "https://raw.githubusercontent.com/sergeydb-wq/Logos/refs/heads/main/",
    IconsFolder = "CarryPeople3/icons",           -- иконки вкладок
    LogoFile    = "CarryPeople3/logo.png",         -- логотип
    GuiName     = "NurLibGui",
    AccountName = nil,
    AccountRole = "user",
    AccentColor = Color3.fromRGB(250, 128, 114),
    MenuKey     = Enum.KeyCode.RightControl,
    WindowSize  = Vector2.new(800, 500),
    ConfigFolder= "CarryPeople3/configs",         -- конфиги
    SpeedSuffix = "bps",
    GroupFunctions = "ФУНКЦИИ",
    GroupManage    = "УПРАВЛЕНИЕ",
    SearchPlaceholder = "Поиск",

    AccessKey   = "RAN-CP3-7KQ2-M9PX",          -- единственный рабочий ключ
    SaveDir     = "CarryPeople3",               -- папка в workspace экзекутора (ключ + история)
    KeyFile     = "CarryPeople3/key.txt",
    HistoryFile = "CarryPeople3/history.json",
    LicenseFile = "CarryPeople3/license.json",  -- ID и счётчик запусков для окна User Info
    DiscordInvite = "https://discord.gg/e3Y4EyDGK", -- ссылка на Discord
}
--// ═══════════════════════════════════════════════════════════════════

local Players          = game:GetService("Players")
local UIS              = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local Stats            = game:GetService("Stats")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer

local Library = {
    Flags = {}, Setters = {}, Modules = {}, Binds = {},
    Connections = {}, PanicHooks = {}, Listening = nil, Gui = nil,
}

local Theme = {
    Accent     = CONFIG.AccentColor,
    AccentDim  = CONFIG.AccentColor:Lerp(Color3.new(0, 0, 0), 0.6),
    Background = Color3.fromRGB(13, 13, 15),
    Panel      = Color3.fromRGB(18, 18, 20),
    Field      = Color3.fromRGB(26, 26, 30),
    Selected   = Color3.fromRGB(24, 22, 24),
    Stroke     = Color3.fromRGB(34, 34, 38),
    Off        = Color3.fromRGB(38, 38, 43),
    Text       = Color3.fromRGB(235, 235, 235),
    SubText    = Color3.fromRGB(140, 140, 146),
    Danger     = Color3.fromRGB(235, 87, 87),
}

--// ───────────── файлы экзекутора (ключ / история) ─────────────
local function FsAvailable()
    return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
end
local function EnsureDir(dir)
    pcall(function()
        if type(isfolder) ~= "function" or type(makefolder) ~= "function" then return end
        local path = ""
        for part in string.gmatch(dir, "[^/]+") do
            path = (path == "") and part or (path .. "/" .. part)
            if not isfolder(path) then makefolder(path) end
        end
    end)
end
local function SaveFile(path, content)
    if not FsAvailable() then return false end
    local dir = path:match("^(.*)/[^/]+$")
    if dir then EnsureDir(dir) end
    return (pcall(writefile, path, content))
end
local function LoadFile(path)
    if not FsAvailable() then return nil end
    local ok, result = pcall(function()
        if isfile(path) then return readfile(path) end
        return nil
    end)
    if ok then return result end
    return nil
end
local function DeleteFile(path)
    if type(delfile) ~= "function" then return false end
    return (pcall(function() if isfile(path) then delfile(path) end end))
end

--// ───────────── загрузка логотипа в workspace экзекутора ─────────────
local LogoAsset = nil
do
    local ok = pcall(function()
        if not (CONFIG.LogoUrl and writefile and isfile and getcustomasset and makefolder and isfolder) then return end
        local dir = CONFIG.LogoFile:match("^(.*)/[^/]+$")
        if dir then EnsureDir(dir) end
        if not isfile(CONFIG.LogoFile) then
            writefile(CONFIG.LogoFile, game:HttpGet(CONFIG.LogoUrl))
        end
        LogoAsset = getcustomasset(CONFIG.LogoFile)
    end)
    if not ok then LogoAsset = nil end
end

-- скачивает иконку вкладки (PNG с GitHub); вернёт nil, если не вышло или файл не PNG
local function IconAsset(fileName)
    local result
    pcall(function()
        if not (CONFIG.IconsBase and writefile and isfile and getcustomasset and makefolder and isfolder) then return end
        EnsureDir(CONFIG.IconsFolder)
        local file = CONFIG.IconsFolder .. "/" .. fileName
        if not isfile(file) then
            local data = game:HttpGet(CONFIG.IconsBase .. fileName)
            if type(data) ~= "string" or data:sub(2, 4) ~= "PNG" then return end -- 404 и прочее не сохраняем
            writefile(file, data)
        end
        result = getcustomasset(file)
    end)
    return result
end

--// ───────────── helpers ─────────────
local function New(class, props, children)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    for _, c in ipairs(children or {}) do c.Parent = o end
    return o
end
local function Corner(r) return New("UICorner", { CornerRadius = UDim.new(0, r) }) end
local function Stroke(c, t)
    return New("UIStroke", { Color = c or Theme.Stroke, Thickness = 1, Transparency = t or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end
local function Pad(l, t, r, b)
    return New("UIPadding", { PaddingLeft = UDim.new(0, l), PaddingTop = UDim.new(0, t),
        PaddingRight = UDim.new(0, r), PaddingBottom = UDim.new(0, b) })
end
local function Label(p)
    local d = { BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 13,
        TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0 }
    for k, v in pairs(p) do d[k] = v end
    return New("TextLabel", d)
end
-- логотип: картинка (если загрузилась) или буква
local function Logo(p, textSize)
    if LogoAsset then
        p.BackgroundTransparency = 1
        p.Image = LogoAsset
        p.ScaleType = Enum.ScaleType.Fit
        return New("ImageLabel", p)
    end
    p.Text = CONFIG.LogoText
    p.TextXAlignment = Enum.TextXAlignment.Center
    p.Font = Enum.Font.GothamBlack
    p.TextSize = textSize
    p.TextColor3 = Theme.Accent
    return Label(p)
end
local function Tween(o, props, t, style, dir)
    local tw = TweenService:Create(o, TweenInfo.new(t or 0.15, style or Enum.EasingStyle.Quad,
        dir or Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end
local function Connect(sig, fn)
    local c = sig:Connect(fn)
    table.insert(Library.Connections, c)
    return c
end
local function With(o, flag)
    local n = {}
    for k, v in pairs(o) do n[k] = v end
    n.Flag = flag
    return n
end
local function IsPress(i)
    return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end
local function IsMove(i)
    return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch
end

local function GuiParent(gui)
    local parent
    local okH, hui = pcall(function() return gethui and gethui() end)
    if okH and hui then
        parent = hui
    else
        local okC = pcall(function() gui.Parent = CoreGui end)
        parent = (okC and gui.Parent == CoreGui) and CoreGui or LocalPlayer:WaitForChild("PlayerGui")
    end
    return parent
end

--// Сворачиваемый блок с плавной анимацией высоты.
--// Inner — сюда кладутся элементы (внутри должен быть свой UIListLayout).
local function Collapsible(parent, order, open)
    local clip = New("Frame", { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1,
        ClipsDescendants = true, Visible = open and true or false, LayoutOrder = order or 0, Parent = parent })
    local inner = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, Parent = clip })
    local api = { Clip = clip, Inner = inner, Open = open and true or false }
    local token = 0

    inner:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if api.Open and token == 0 then
            clip.Size = UDim2.new(1, 0, 0, inner.AbsoluteSize.Y)
        end
    end)

    function api:Set(v)
        v = v and true or false
        if v == api.Open then return end
        api.Open = v
        local my = os.clock()
        token = my
        if v then
            clip.Visible = true
            task.spawn(function()
                RunService.RenderStepped:Wait() -- ждём, пока Roblox посчитает высоту содержимого
                if token ~= my then return end
                local tw = Tween(clip, { Size = UDim2.new(1, 0, 0, inner.AbsoluteSize.Y) }, 0.24, Enum.EasingStyle.Quint)
                tw.Completed:Connect(function() if token == my then token = 0 end end)
            end)
        else
            local tw = Tween(clip, { Size = UDim2.new(1, 0, 0, 0) }, 0.2, Enum.EasingStyle.Quint)
            tw.Completed:Connect(function()
                if token == my then
                    token = 0
                    if not api.Open then clip.Visible = false end
                end
            end)
        end
    end
    function api:Toggle() api:Set(not api.Open) end
    return api
end

--// ───────────── уведомления (каналы, позицию которых можно менять) ─────────────
Library.Icon = IconAsset

-- X/Y — положение в долях экрана (0..1). Каналы: general (общие), map (смена карты), bounty (награды)
Library.NotifyChannels = {
    general = { Title = "Общие уведомления", X = 0.985, Y = 0.975 },
    map     = { Title = "Смена карты",       X = 0.5,   Y = 0.06  },
    bounty  = { Title = "Награды (claimed)", X = 0.985, Y = 0.80  },
}
Library.StreamerMode = false       -- скрывает ник/аватар везде в интерфейсе
Library.WatermarkStyle = "left" -- "left" | "center"

local UI_STATE_FILE = CONFIG.SaveDir .. "/ui.json"
do
    local raw = LoadFile(UI_STATE_FILE)
    if raw and raw ~= "" then
        local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
        if ok and type(data) == "table" then
            local chTable = type(data.channels) == "table" and data.channels or data -- совместимость со старым форматом
            for name, ch in pairs(Library.NotifyChannels) do
                local saved = chTable[name]
                if type(saved) == "table" and type(saved.x) == "number" and type(saved.y) == "number" then
                    ch.X = math.clamp(saved.x, 0.03, 0.97)
                    ch.Y = math.clamp(saved.y, 0.04, 0.96)
                end
            end
            if type(data.streamer) == "boolean" then Library.StreamerMode = data.streamer end
            if data.watermarkStyle == "left" or data.watermarkStyle == "center" then
                Library.WatermarkStyle = data.watermarkStyle
            end
        end
    end
end
local function SaveUiState()
    local data = { channels = {}, streamer = Library.StreamerMode, watermarkStyle = Library.WatermarkStyle }
    for name, ch in pairs(Library.NotifyChannels) do
        data.channels[name] = { x = ch.X, y = ch.Y }
    end
    pcall(function() SaveFile(UI_STATE_FILE, HttpService:JSONEncode(data)) end)
end
Library.SaveUiState = SaveUiState

--// ───────────── стример-режим (скрывает ник/аватар везде) ─────────────
Library.StreamerRefs = {}
function Library:RegisterStreamerRef(fn)
    table.insert(Library.StreamerRefs, fn)
    pcall(fn, Library.StreamerMode)
end
function Library:SetStreamerMode(value)
    value = value and true or false
    if value == Library.StreamerMode then return end
    Library.StreamerMode = value
    for _, fn in ipairs(Library.StreamerRefs) do pcall(fn, value) end
    SaveUiState()
end

local function ApplyNotifyLayout(ch)
    local holder = ch.Holder
    if not (holder and holder.Parent) then return end
    local ax = ch.X < 0.33 and 0 or (ch.X > 0.66 and 1 or 0.5)
    local ay = ch.Y < 0.5 and 0 or 1
    holder.AnchorPoint = Vector2.new(ax, ay)
    holder.Position = UDim2.fromScale(ch.X, ch.Y)
    local layout = holder:FindFirstChildOfClass("UIListLayout")
    if layout then
        layout.HorizontalAlignment = ch.X < 0.33 and Enum.HorizontalAlignment.Left
            or (ch.X > 0.66 and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Center)
        layout.VerticalAlignment = ch.Y < 0.5 and Enum.VerticalAlignment.Top or Enum.VerticalAlignment.Bottom
    end
end

local function GetNotifyHolder(ch)
    if ch.Holder and ch.Holder.Parent then return ch.Holder end
    local holder = New("Frame", { Name = "Notify", BackgroundTransparency = 1,
        Size = UDim2.fromOffset(320, 400), ZIndex = 400, Parent = Library.Gui })
    New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = holder })
    ch.Holder = holder
    ApplyNotifyLayout(ch)
    return holder
end

function Library:Notify(text, duration, channel)
    if not Library.Gui then return end
    local ch = Library.NotifyChannels[channel or "general"] or Library.NotifyChannels.general
    local holder = GetNotifyHolder(ch)
    local n = New("CanvasGroup", { Size = UDim2.fromOffset(0, 34), AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = Theme.Background, GroupTransparency = 1, Parent = holder },
        { Corner(7), Stroke(Theme.Accent, 0.4), Pad(12, 0, 12, 0) })
    Label({ Text = tostring(text), Size = UDim2.fromOffset(0, 34), AutomaticSize = Enum.AutomaticSize.X, Parent = n })
    Tween(n, { GroupTransparency = 0 }, 0.28)
    task.delay(duration or 3, function()
        if n and n.Parent then
            Tween(n, { GroupTransparency = 1 }, 0.28)
            task.wait(0.3)
            if n then n:Destroy() end
        end
    end)
end

function Library:PreviewNotify(channel)
    local ch = Library.NotifyChannels[channel or "general"] or Library.NotifyChannels.general
    Library:Notify("Пример уведомления: " .. ch.Title, 3, channel)
end

--// Режим перемещения: появляется окошко, которое можно перетащить; позиция сохраняется
function Library:SetNotifyEdit(channel, on)
    local ch = Library.NotifyChannels[channel or "general"] or Library.NotifyChannels.general
    if not Library.Gui then return end
    if on then
        if ch.Editing then return end
        ch.Editing = true
        local dragger = New("CanvasGroup", { Name = "NotifyDrag", AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(ch.X, ch.Y), Size = UDim2.fromOffset(260, 46),
            BackgroundColor3 = Theme.Background, GroupTransparency = 1, ZIndex = 600, Parent = Library.Gui },
            { Corner(8), Stroke(Theme.Accent, 0.1) })
        Label({ Text = "✥  Перетащи: " .. ch.Title, Size = UDim2.fromScale(1, 1),
            TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = Theme.Accent,
            Font = Enum.Font.GothamBold, TextSize = 13, Parent = dragger })
        ch.Dragger = dragger
        Tween(dragger, { GroupTransparency = 0 }, 0.2)
        local dragging = false
        dragger.InputBegan:Connect(function(input)
            if IsPress(input) then dragging = true end
        end)
        ch.EndConn = Connect(UIS.InputEnded, function(input)
            if dragging and IsPress(input) then
                dragging = false
                SaveUiState()
            end
        end)
        ch.DragConn = Connect(RunService.RenderStepped, function()
            if not dragging or not Library.Gui then return end
            local loc = UIS:GetMouseLocation()
            local size = Library.Gui.AbsoluteSize
            ch.X = math.clamp(loc.X / size.X, 0.03, 0.97)
            ch.Y = math.clamp(loc.Y / size.Y, 0.04, 0.96)
            dragger.Position = UDim2.fromScale(ch.X, ch.Y)
            ApplyNotifyLayout(ch)
        end)
    else
        if not ch.Editing then return end
        ch.Editing = false
        if ch.DragConn then ch.DragConn:Disconnect() ch.DragConn = nil end
        if ch.EndConn then ch.EndConn:Disconnect() ch.EndConn = nil end
        local dragger = ch.Dragger
        ch.Dragger = nil
        if dragger then
            Tween(dragger, { GroupTransparency = 1 }, 0.2)
            task.delay(0.22, function() if dragger then dragger:Destroy() end end)
        end
        SaveUiState()
    end
end

--// ───────────── переключатель (switch) ─────────────
local function MakeSwitch(parent, pos)
    local sw = New("Frame", { Size = UDim2.fromOffset(32, 16), AnchorPoint = Vector2.new(1, 0.5),
        Position = pos, BackgroundColor3 = Theme.Off, Parent = parent }, { Corner(8) })
    local knob = New("Frame", { Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 2, 0.5, 0), BackgroundColor3 = Color3.fromRGB(200, 200, 200), Parent = sw }, { Corner(6) })
    return function(v)
        Tween(sw, { BackgroundColor3 = v and Theme.Accent or Theme.Off }, 0.2)
        Tween(knob, { Position = v and UDim2.new(1, -14, 0.5, 0) or UDim2.new(0, 2, 0.5, 0) }, 0.2, Enum.EasingStyle.Back)
    end
end

--// ───────────── билдеры элементов ─────────────
local function BuildToggle(parent, o)
    local obj = { Value = false }
    local flag = o.Flag or o.Name
    local row = New("TextButton", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1,
        Text = "", AutoButtonColor = false, Parent = parent })
    Label({ Text = o.Name, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -60, 1, 0),
        TextColor3 = Theme.SubText, Parent = row })
    local visual = MakeSwitch(row, UDim2.new(1, -12, 0.5, 0))
    function obj:Set(v, silent)
        v = v and true or false
        obj.Value = v
        if not o.NoFlag then Library.Flags[flag] = v end
        visual(v)
        if not silent and o.Callback then task.spawn(o.Callback, v) end
    end
    row.MouseButton1Click:Connect(function() obj:Set(not obj.Value) end)
    if not o.NoFlag then Library.Setters[flag] = function(v) obj:Set(v) end end
    obj:Set(o.Default or false, true)
    return obj
end

local function BuildSlider(parent, o)
    local obj = { Value = 0 }
    local flag = o.Flag or o.Name
    local min, max, inc = o.Min or 0, o.Max or 100, o.Increment or 1
    local f = New("Frame", { Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1, Parent = parent })
    Label({ Text = o.Name, Position = UDim2.fromOffset(12, 4), Size = UDim2.new(1, -100, 0, 16),
        TextColor3 = Theme.SubText, Parent = f })
    local val = Label({ Text = "", Position = UDim2.new(1, -92, 0, 4), Size = UDim2.fromOffset(80, 16),
        TextXAlignment = Enum.TextXAlignment.Right, Parent = f })
    local track = New("Frame", { Position = UDim2.new(0, 12, 0, 28), Size = UDim2.new(1, -24, 0, 4),
        BackgroundColor3 = Theme.Off, Parent = f }, { Corner(2) })
    local fill = New("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Theme.Accent, Parent = track }, { Corner(2) })
    local hit = New("TextButton", { Position = UDim2.new(0, 12, 0, 20), Size = UDim2.new(1, -24, 0, 20),
        BackgroundTransparency = 1, Text = "", Parent = f })

    function obj:Set(v, silent)
        v = math.clamp(tonumber(v) or min, min, max)
        v = math.floor((v - min) / inc + 0.5) * inc + min
        v = math.clamp(math.floor(v * 10000 + 0.5) / 10000, min, max)
        obj.Value = v
        if not o.NoFlag then Library.Flags[flag] = v end
        Tween(fill, { Size = UDim2.fromScale((v - min) / math.max(max - min, 1e-6), 1) }, 0.1)
        val.Text = tostring(v) .. (o.Suffix or "")
        if not silent and o.Callback then task.spawn(o.Callback, v) end
    end

    local dragging = false
    local function upd(x)
        local a = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        obj:Set(min + (max - min) * a)
    end
    hit.InputBegan:Connect(function(i) if IsPress(i) then dragging = true; upd(i.Position.X) end end)
    Connect(UIS.InputChanged, function(i) if dragging and IsMove(i) then upd(i.Position.X) end end)
    Connect(UIS.InputEnded, function(i) if IsPress(i) then dragging = false end end)

    if not o.NoFlag then Library.Setters[flag] = function(v) obj:Set(v) end end
    obj:Set(o.Default or min, true)
    return obj
end

local function BuildDropdown(parent, o)
    local obj = { Value = nil, Options = o.Options or {} }
    local flag = o.Flag or o.Name
    local holder = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, Parent = parent })
    New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = holder })
    local head = New("TextButton", { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1,
        Text = "", LayoutOrder = 1, Parent = holder })
    Label({ Text = o.Name, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.4, 0, 1, 0),
        TextColor3 = Theme.SubText, Parent = head })
    local box = New("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.new(0.55, -12, 0, 22), BackgroundColor3 = Theme.Field, Parent = head }, { Corner(5) })
    local valLbl = Label({ Text = "—", Size = UDim2.new(1, -24, 1, 0), Position = UDim2.fromOffset(8, 0),
        TextTruncate = Enum.TextTruncate.AtEnd, Parent = box })
    local chevron = Label({ Text = "▾", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0),
        Size = UDim2.fromOffset(12, 12), TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = Theme.SubText,
        TextSize = 12, Parent = box })

    local col = Collapsible(holder, 2, false)
    local list = col.Inner
    New("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
    Pad(12, 2, 12, 4).Parent = list

    local buttons = {}
    local function paint()
        for opt, b in pairs(buttons) do
            Tween(b, { TextColor3 = (opt == obj.Value) and Theme.Accent or Theme.SubText }, 0.15)
        end
    end
    function obj:Set(v, silent)
        obj.Value = v
        valLbl.Text = v ~= nil and tostring(v) or "—"
        if not o.NoFlag then Library.Flags[flag] = v end
        paint()
        if not silent and o.Callback then task.spawn(o.Callback, v) end
    end
    function obj:Refresh(opts)
        obj.Options = opts or {}
        for _, b in pairs(buttons) do b:Destroy() end
        buttons = {}
        for idx, opt in ipairs(obj.Options) do
            local b = New("TextButton", { Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = Theme.Field,
                Text = tostring(opt), Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = Theme.SubText,
                AutoButtonColor = false, LayoutOrder = idx, Parent = list }, { Corner(5) })
            b.MouseEnter:Connect(function() Tween(b, { BackgroundColor3 = Theme.Selected }, 0.12) end)
            b.MouseLeave:Connect(function() Tween(b, { BackgroundColor3 = Theme.Field }, 0.12) end)
            b.MouseButton1Click:Connect(function()
                obj:Set(opt)
                col:Set(false)
                Tween(chevron, { Rotation = 0 }, 0.2)
            end)
            buttons[opt] = b
        end
        paint()
    end
    head.MouseButton1Click:Connect(function()
        col:Toggle()
        Tween(chevron, { Rotation = col.Open and 180 or 0 }, 0.2)
    end)
    if not o.NoFlag then Library.Setters[flag] = function(v) obj:Set(v) end end
    obj:Refresh(obj.Options)
    obj:Set(o.Default, true)
    return obj
end

local function BuildKeybind(parent, o, module)
    local obj = { Value = nil }
    local flag = o.Flag or o.Name
    local row = New("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Parent = parent })
    Label({ Text = o.Name, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.5, 0, 1, 0),
        TextColor3 = Theme.SubText, Parent = row })
    local btn = New("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(80, 22), BackgroundColor3 = Theme.Field, Text = "NONE",
        Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = Theme.Text, AutoButtonColor = false,
        Parent = row }, { Corner(5) })

    function obj:Set(v, silent)
        if typeof(v) == "string" then
            local ok, kc = pcall(function() return Enum.KeyCode[v] end)
            v = ok and kc or nil
        end
        obj.Value = v
        btn.Text = v and v.Name or "NONE"
        if not o.NoFlag then Library.Flags[flag] = v and v.Name or "None" end
    end
    btn.MouseButton1Click:Connect(function()
        btn.Text = "..."
        Library.Listening = function(input)
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
                obj:Set(nil)
            else
                obj:Set(input.KeyCode)
            end
            Library.Listening = nil
        end
    end)
    table.insert(Library.Binds, { obj = obj, fn = function()
        if module then module:Set(not module.Value) end
        if o.Callback then task.spawn(o.Callback) end
    end })
    if not o.NoFlag then Library.Setters[flag] = function(v) obj:Set(v) end end
    obj:Set(o.Default, true)
    return obj
end

local function BuildButton(parent, o)
    local wrap = New("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, Parent = parent })
    local b = New("TextButton", { Size = UDim2.new(1, -24, 0, 28), Position = UDim2.fromOffset(12, 3),
        BackgroundColor3 = Theme.Field, Text = o.Name, Font = Enum.Font.GothamMedium, TextSize = 13,
        TextColor3 = Theme.Text, AutoButtonColor = false, Parent = wrap }, { Corner(6) })
    b.MouseEnter:Connect(function() Tween(b, { BackgroundColor3 = Theme.Selected }, 0.12) end)
    b.MouseLeave:Connect(function() Tween(b, { BackgroundColor3 = Theme.Field }, 0.12) end)
    b.MouseButton1Down:Connect(function() Tween(b, { Size = UDim2.new(1, -28, 0, 26), Position = UDim2.fromOffset(14, 4) }, 0.08) end)
    local function release() Tween(b, { Size = UDim2.new(1, -24, 0, 28), Position = UDim2.fromOffset(12, 3) }, 0.12) end
    b.MouseButton1Up:Connect(release)
    b.MouseLeave:Connect(release)
    b.MouseButton1Click:Connect(function() if o.Callback then task.spawn(o.Callback) end end)
    local obj = { Button = b }
    function obj:SetText(t) b.Text = t end
    return obj
end

local function BuildTextbox(parent, o)
    local obj = { Value = o.Default and tostring(o.Default) or "" }
    local flag = o.Flag or o.Name
    local row = New("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, Parent = parent })
    local box = New("TextBox", { Position = UDim2.fromOffset(12, 3), Size = UDim2.new(1, -24, 0, 28),
        BackgroundColor3 = Theme.Field, Text = obj.Value, PlaceholderText = o.Placeholder or o.Name,
        PlaceholderColor3 = Theme.SubText, Font = Enum.Font.GothamMedium, TextSize = 13,
        TextColor3 = Theme.Text, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row }, { Corner(6), Pad(8, 0, 8, 0) })
    local st = Stroke(Theme.Accent, 1); st.Parent = box
    box.Focused:Connect(function() Tween(st, { Transparency = 0.3 }, 0.15) end)
    box.FocusLost:Connect(function() Tween(st, { Transparency = 1 }, 0.15) end)
    local function commit(silent)
        obj.Value = box.Text
        if not o.NoFlag then Library.Flags[flag] = box.Text end
        if not silent and o.Callback then task.spawn(o.Callback, box.Text) end
    end
    box:GetPropertyChangedSignal("Text"):Connect(function() commit(false) end)
    function obj:Set(t, silent) box.Text = tostring(t or ""); commit(silent) end
    if not o.NoFlag then Library.Setters[flag] = function(v) obj:Set(v) end end
    commit(true)
    return obj
end

-- многострочная подпись (статусы, списки); obj:Set(text)
local function BuildLabel(parent, o)
    local obj = { Value = o.Text or o.Name or "" }
    local lbl = Label({ Text = obj.Value, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = o.Color or Theme.SubText,
        TextSize = o.TextSize or 12, Parent = parent }, nil)
    Pad(12, 4, 12, 4).Parent = lbl
    function obj:Set(t)
        t = tostring(t)
        if t == obj.Value then return end
        obj.Value = t
        lbl.Text = t
    end
    obj.Label = lbl
    return obj
end

--// ───────────── Module (функция с тумблером и "...") ─────────────
local Module = {}
Module.__index = Module

function Module:_reveal() self.Dots.Visible = true end
function Module:AddSlider(o)   self:_reveal(); return BuildSlider(self.Settings, With(o, self.Flag .. "." .. (o.Flag or o.Name))) end
function Module:AddDropdown(o) self:_reveal(); return BuildDropdown(self.Settings, With(o, self.Flag .. "." .. (o.Flag or o.Name))) end
function Module:AddToggle(o)   self:_reveal(); return BuildToggle(self.Settings, With(o, self.Flag .. "." .. (o.Flag or o.Name))) end
function Module:AddKeybind(o)  self:_reveal(); return BuildKeybind(self.Settings, With(o, self.Flag .. ".bind"), self) end
function Module:AddTextbox(o)  self:_reveal(); return BuildTextbox(self.Settings, With(o, self.Flag .. "." .. (o.Flag or o.Name))) end
function Module:AddButton(o)   self:_reveal(); return BuildButton(self.Settings, o) end
function Module:AddLabel(o)    self:_reveal(); return BuildLabel(self.Settings, type(o) == "table" and o or { Text = o }) end

--// ───────────── Section ─────────────
local Section = {}
Section.__index = Section

function Section:AddModule(o)
    local module = setmetatable({ Name = o.Name, Flag = o.Flag or o.Name, Value = false }, Module)
    local holder = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, Parent = self.Body })
    New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = holder })
    local row = New("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, LayoutOrder = 1, Parent = holder })
    local click = New("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "",
        AutoButtonColor = false, Parent = row })
    local nameLbl = Label({ Text = o.Name, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -110, 1, 0),
        TextColor3 = Theme.SubText, TextSize = 14, Parent = row })
    local visual = MakeSwitch(row, UDim2.new(1, -12, 0.5, 0))
    local dots = New("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -52, 0.5, 0),
        Size = UDim2.fromOffset(28, 22), BackgroundTransparency = 1, Text = "•••", Font = Enum.Font.GothamBold,
        TextSize = 11, TextColor3 = Theme.SubText, Visible = false, ZIndex = 2, Parent = row })

    local col = Collapsible(holder, 2, false)
    local settings = col.Inner
    settings.BackgroundTransparency = 0
    settings.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
    settings.BorderSizePixel = 0
    New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = settings })
    Pad(0, 4, 0, 4).Parent = settings

    module.Dots, module.Settings, module.Holder = dots, settings, holder

    function module:Set(v, silent)
        v = v and true or false
        module.Value = v
        Library.Flags[module.Flag] = v
        visual(v)
        Tween(nameLbl, { TextColor3 = v and Theme.Text or Theme.SubText }, 0.2)
        if not silent and o.Callback then task.spawn(o.Callback, v) end
    end

    click.MouseButton1Click:Connect(function() module:Set(not module.Value) end)
    click.MouseButton2Click:Connect(function() if dots.Visible then col:Toggle() end end)
    dots.MouseButton1Click:Connect(function() col:Toggle() end)
    dots.MouseEnter:Connect(function() Tween(dots, { TextColor3 = Theme.Accent }, 0.12) end)
    dots.MouseLeave:Connect(function() Tween(dots, { TextColor3 = Theme.SubText }, 0.12) end)

    Library.Setters[module.Flag] = function(v) module:Set(v) end
    table.insert(Library.Modules, { Name = string.lower(o.Name), Frame = holder })
    module:Set(o.Default or false, true)
    if o.Keybind then module:AddKeybind({ Name = "Бинд", Default = o.Keybind }) end
    return module
end

function Section:AddButton(o)   return BuildButton(self.Body, o) end
function Section:AddTextbox(o)  return BuildTextbox(self.Body, o) end
function Section:AddToggle(o)   return BuildToggle(self.Body, o) end
function Section:AddSlider(o)   return BuildSlider(self.Body, o) end
function Section:AddDropdown(o) return BuildDropdown(self.Body, o) end
function Section:AddKeybind(o)  return BuildKeybind(self.Body, o, nil) end
function Section:AddLabel(o)    return BuildLabel(self.Body, type(o) == "table" and o or { Text = o }) end

--// ───────────── Конфиги (файлы) ─────────────
local function HasFS()
    return writefile and readfile and isfolder and makefolder and listfiles and true or false
end
local function CfgPath(name) return CONFIG.ConfigFolder .. "/" .. name .. ".json" end
local function EnsureFolder()
    if not HasFS() then return false end
    EnsureDir(CONFIG.ConfigFolder)
    return true
end
local function SafeName(n) return (tostring(n):gsub('[\\/:*?"<>|]', ""):gsub("^%s+", ""):gsub("%s+$", "")) end

function Library:GetConfigs()
    if not EnsureFolder() then return {} end
    local out = {}
    for _, f in ipairs(listfiles(CONFIG.ConfigFolder)) do
        local n = f:match("([^/\\]+)%.json$")
        if n then table.insert(out, n) end
    end
    table.sort(out)
    return out
end
function Library:SaveConfig(name)
    name = SafeName(name or "")
    if name == "" then return false, "Введите имя конфига" end
    if not EnsureFolder() then return false, "Экзекутор не поддерживает файлы" end
    local data = {}
    for k, v in pairs(Library.Flags) do data[k] = v end
    writefile(CfgPath(name), HttpService:JSONEncode(data))
    return true
end
function Library:LoadConfig(name)
    if not name or name == "" then return false, "Выберите конфиг" end
    if not EnsureFolder() or not isfile(CfgPath(name)) then return false, "Файл не найден" end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CfgPath(name))) end)
    if not ok then return false, "Файл повреждён" end
    for k, v in pairs(data) do
        local setter = Library.Setters[k]
        if setter then pcall(setter, v) end
    end
    return true
end
function Library:DeleteConfig(name)
    if name and name ~= "" and HasFS() and isfile(CfgPath(name)) then delfile(CfgPath(name)); return true end
    return false, "Файл не найден"
end

--// ───────────── Watermark: два варианта положения — "Слева" и "Центр" ─────────────
local function Pill(parent, order)
    local p = New("Frame", { Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = Theme.Background, BackgroundTransparency = 0.15, LayoutOrder = order, Parent = parent },
        { Corner(6), Stroke(Theme.Stroke), Pad(10, 0, 10, 0) })
    New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12),
        VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = p })
    return p
end
local function PillItem(parent, text, color, order)
    return Label({ Text = text, Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X,
        TextColor3 = color or Theme.Text, TextSize = 12, LayoutOrder = order, Parent = parent })
end
local function PillSep(parent, order)
    return Label({ Text = "•", Size = UDim2.fromOffset(10, 26), TextXAlignment = Enum.TextXAlignment.Center,
        TextColor3 = Theme.SubText, TextSize = 12, LayoutOrder = order, Parent = parent })
end

--// Стиль "Слева": лого + название хаба + ник, fps/ping/время, вторая строка — позиция/скорость
local function BuildWatermarkLeft(root)
    local row1, row2 = Pill(root, 1), Pill(root, 2)
    Logo({ Size = UDim2.fromOffset(18, 18), LayoutOrder = 1, Parent = row1 }, 14)
    PillItem(row1, CONFIG.HubName, Theme.Text, 2)
    local nameL = PillItem(row1, LocalPlayer.Name, Theme.Text, 3)
    local fpsL  = PillItem(row1, "0 fps", Theme.Text, 4)
    local pingL = PillItem(row1, "0ms",   Theme.Text, 5)
    local timeL = PillItem(row1, "00:00:00", Theme.Text, 6)
    local posL  = PillItem(row2, "x0 y0 z0", Theme.Text, 1)
    local spdL  = PillItem(row2, "0.0 " .. CONFIG.SpeedSuffix, Theme.Text, 2)

    Library:RegisterStreamerRef(function(on) nameL.Text = on and "Скрыто" or LocalPlayer.Name end)

    local acc, frames = 0, 0
    return Connect(RunService.RenderStepped, function(dt)
        acc += dt; frames += 1
        if acc < 0.25 then return end
        fpsL.Text = math.floor(frames / acc + 0.5) .. " fps"
        acc, frames = 0, 0
        local ok, ping = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
        pingL.Text = (ok and math.floor(ping) or 0) .. "ms"
        timeL.Text = os.date("%H:%M:%S") -- реальное время компьютера
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local pos, v = hrp.Position, hrp.AssemblyLinearVelocity
            posL.Text = string.format("x%d y%d z%d", math.floor(pos.X), math.floor(pos.Y), math.floor(pos.Z))
            spdL.Text = string.format("%.1f %s", Vector3.new(v.X, 0, v.Z).Magnitude, CONFIG.SpeedSuffix)
        end
    end)
end

--// Стиль "Центр": одна полоска по центру сверху, без иконок и логотипа.
--// Ник, FPS, пинг, позиция, скорость. Без TPS и без времени компьютера.
local function BuildWatermarkCenter(root)
    local row = Pill(root, 1)
    local nameL = PillItem(row, LocalPlayer.Name, Theme.Text, 1)
    PillSep(row, 2)
    local fpsL  = PillItem(row, "0 FPS", Theme.Text, 3)
    PillSep(row, 4)
    local pingL = PillItem(row, "0 ms", Theme.Text, 5)
    PillSep(row, 6)
    local posL  = PillItem(row, "x0 y0 z0", Theme.Text, 7)
    PillSep(row, 8)
    local spdL  = PillItem(row, "0.0 " .. CONFIG.SpeedSuffix, Theme.Text, 9)

    Library:RegisterStreamerRef(function(on) nameL.Text = on and "Скрыто" or LocalPlayer.Name end)

    local acc, frames = 0, 0
    return Connect(RunService.RenderStepped, function(dt)
        acc += dt; frames += 1
        if acc < 0.25 then return end
        fpsL.Text = math.floor(frames / acc + 0.5) .. " FPS"
        acc, frames = 0, 0
        local ok, ping = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
        pingL.Text = (ok and math.floor(ping) or 0) .. " ms"
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local pos, v = hrp.Position, hrp.AssemblyLinearVelocity
            posL.Text = string.format("x%d y%d z%d", math.floor(pos.X), math.floor(pos.Y), math.floor(pos.Z))
            spdL.Text = string.format("%.1f %s", Vector3.new(v.X, 0, v.Z).Magnitude, CONFIG.SpeedSuffix)
        end
    end)
end

function Library:CreateWatermark()
    local centered = Library.WatermarkStyle == "center"
    local root = New("CanvasGroup", {
        Name = "Watermark",
        AnchorPoint = centered and Vector2.new(0.5, 0) or Vector2.new(0, 0),
        Position = centered and UDim2.new(0.5, 0, 0, 10) or UDim2.fromOffset(10, 10),
        Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1, GroupTransparency = 1, Parent = Library.Gui,
    })
    New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = centered and Enum.HorizontalAlignment.Center or Enum.HorizontalAlignment.Left,
        Parent = root })
    Tween(root, { GroupTransparency = Library.WatermarkVisible == false and 1 or 0 }, 0.5)

    local conn = centered and BuildWatermarkCenter(root) or BuildWatermarkLeft(root)
    Library.WatermarkConn = conn
    Library.Watermark = root
    return root
end

--// Переключает стиль оверлея на лету (вызывается из Визуалы → Интерфейс)
function Library:SetWatermarkStyle(style)
    if style ~= "left" and style ~= "center" then return end
    if style == Library.WatermarkStyle and Library.Watermark then return end
    Library.WatermarkStyle = style
    if Library.WatermarkConn then pcall(function() Library.WatermarkConn:Disconnect() end) end
    if Library.Watermark then Library.Watermark:Destroy() end
    Library:CreateWatermark()
    Library.SaveUiState()
end

--// ───────────── Window ─────────────
local Window = {}
Window.__index = Window
local Tab = {}
Tab.__index = Tab

function Tab:AddSection(title, side)
    local col = (side == "Right") and self.Right or self.Left
    local sec = setmetatable({}, Section)
    local frame = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Panel, Parent = col }, { Corner(8), Stroke() })
    New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = frame })
    local head = New("TextButton", { Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, Text = "",
        LayoutOrder = 1, AutoButtonColor = false, Parent = frame })
    Label({ Text = title, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -40, 1, 0),
        Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = Theme.Accent, Parent = head })
    local arrow = Label({ Text = "▾", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -20, 0.5, 0),
        Size = UDim2.fromOffset(16, 16), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 16,
        TextColor3 = Theme.Accent, Parent = head })
    local collapse = Collapsible(frame, 2, true)
    local body = collapse.Inner
    New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = body })
    Pad(0, 0, 0, 4).Parent = body
    head.MouseButton1Click:Connect(function()
        collapse:Toggle()
        Tween(arrow, { Rotation = collapse.Open and 0 or 180 }, 0.22, Enum.EasingStyle.Quint)
    end)
    sec.Body = body
    return sec
end

function Window:AddTab(name, icon, group)
    group = group or CONFIG.GroupFunctions
    self.Order += 1
    if not self.Groups[group] then
        self.Groups[group] = true
        self.Order += 1
        Label({ Text = group, Size = UDim2.new(1, 0, 0, 28), TextColor3 = Theme.SubText, TextSize = 11,
            Font = Enum.Font.GothamMedium, LayoutOrder = self.Order - 1, Parent = self.TabList })
    end
    local tab = setmetatable({ Name = name, Active = false }, Tab)

    local btn = New("TextButton", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Theme.Selected,
        BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = self.Order, Parent = self.TabList },
        { Corner(7) })
    local st = Stroke(Theme.AccentDim, 1); st.Parent = btn
    local ic
    if type(icon) == "string" and icon:find("rbxasset") then
        ic = New("ImageLabel", { BackgroundTransparency = 1, Image = icon, Size = UDim2.fromOffset(16, 16),
            Position = UDim2.fromOffset(14, 9), ImageColor3 = Theme.SubText, Parent = btn })
    else
        ic = Label({ Text = icon or "•", Size = UDim2.fromOffset(20, 34), Position = UDim2.fromOffset(12, 0),
            TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = Theme.SubText, TextSize = 14, Parent = btn })
    end
    local tx = Label({ Text = name, Position = UDim2.fromOffset(42, 0), Size = UDim2.new(1, -50, 1, 0),
        TextColor3 = Theme.SubText, TextSize = 14, Parent = btn })

    local container = New("CanvasGroup", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        GroupTransparency = 1, Visible = false, Parent = self.Pages })
    local page = New("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Accent, AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(), Parent = container })
    Pad(0, 0, 6, 8).Parent = page
    tab.Left = New("Frame", { Size = UDim2.new(0.5, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, Parent = page })
    tab.Right = New("Frame", { Position = UDim2.new(0.5, 6, 0, 0), Size = UDim2.new(0.5, -6, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = page })
    for _, c in ipairs({ tab.Left, tab.Right }) do
        New("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = c })
    end

    function tab:_paint(active)
        if tab.Active == active then return end
        tab.Active = active
        Tween(btn, { BackgroundTransparency = active and 0 or 1 }, 0.2)
        Tween(st, { Transparency = active and 0 or 1 }, 0.2)
        Tween(tx, { TextColor3 = active and Theme.Text or Theme.SubText }, 0.2)
        if ic:IsA("TextLabel") then Tween(ic, { TextColor3 = active and Theme.Accent or Theme.SubText }, 0.2)
        else Tween(ic, { ImageColor3 = active and Theme.Accent or Theme.SubText }, 0.2) end
        if active then
            container.Position = UDim2.fromOffset(0, 12)
            container.GroupTransparency = 1
            container.Visible = true
            Tween(container, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) }, 0.3, Enum.EasingStyle.Quint)
        else
            container.Visible = false
        end
    end
    function tab:Select()
        for _, t in ipairs(self.Window.TabsList) do
            if t ~= self then t:_paint(false) end
        end
        self:_paint(true)
    end
    tab.Window = self
    btn.MouseButton1Click:Connect(function() tab:Select() end)
    btn.MouseEnter:Connect(function() if not tab.Active then Tween(btn, { BackgroundTransparency = 0.7 }, 0.12) end end)
    btn.MouseLeave:Connect(function() if not tab.Active then Tween(btn, { BackgroundTransparency = 1 }, 0.12) end end)
    table.insert(self.TabsList, tab)
    if #self.TabsList == 1 then self.FirstTab = tab end
    return tab
end

--// Вкладка "Конфиги"
function Window:AddConfigTab(name, icon)
    local tab = self:AddTab(name or "Конфиги", icon or "📁", CONFIG.GroupManage)
    local left = tab:AddSection("Конфиги", "Left")
    local nameBox = left:AddTextbox({ Name = "Название", Placeholder = "Название конфига", NoFlag = true })
    local list = left:AddDropdown({ Name = "Список", Options = Library:GetConfigs(), NoFlag = true })
    local function refresh() list:Refresh(Library:GetConfigs()) end
    left:AddButton({ Name = "Создать / сохранить", Callback = function()
        local n = (nameBox.Value ~= "" and nameBox.Value) or list.Value
        local ok, err = Library:SaveConfig(n)
        Library:Notify(ok and ("Сохранено: " .. SafeName(n)) or err)
        refresh()
    end })
    left:AddButton({ Name = "Загрузить", Callback = function()
        local ok, err = Library:LoadConfig(list.Value)
        Library:Notify(ok and ("Загружено: " .. tostring(list.Value)) or err)
    end })
    left:AddButton({ Name = "Удалить", Callback = function()
        local ok, err = Library:DeleteConfig(list.Value)
        Library:Notify(ok and "Удалено" or err)
        list:Set(nil, true); refresh()
    end })
    left:AddButton({ Name = "Обновить список", Callback = refresh })
    return tab
end

--// Вкладка "Настройки" (разделы добавляются снаружи)
function Window:AddSettingsTab(name, icon)
    return self:AddTab(name or "Настройки", icon or "⚙", CONFIG.GroupManage)
end

function Window:Toggle(v)
    if v == nil then v = not self.Opened end
    if v == self.Opened then return end
    self.Opened = v
    local main = self.Main
    if v then
        main.Visible = true
        main.GroupTransparency = 1
        local base = self.BasePos or main.Position
        main.Position = base + UDim2.fromOffset(0, 20)
        Tween(main, { GroupTransparency = 0, Position = base }, 0.35, Enum.EasingStyle.Quint)
    else
        local base = main.Position
        self.BasePos = base
        Tween(main, { GroupTransparency = 1, Position = base + UDim2.fromOffset(0, 20) }, 0.25, Enum.EasingStyle.Quint)
        task.delay(0.27, function()
            if not self.Opened and main and main.Parent then
                main.Visible = false
                main.Position = base
            end
        end)
    end
end

--// ───────────── PANIC (полная выгрузка) ─────────────
function Library:AddPanicHook(fn)
    table.insert(Library.PanicHooks, fn)
end

local Panicking = false
function Library:Panic()
    if Panicking then return end
    Panicking = true
    for _, fn in ipairs(Library.PanicHooks) do pcall(fn) end
    if Library.Window and Library.Window.Main and Library.Window.Main.Parent then
        local main = Library.Window.Main
        Tween(main, { GroupTransparency = 1, Position = main.Position + UDim2.fromOffset(0, 20) }, 0.25, Enum.EasingStyle.Quint)
    end
    if Library.Watermark and Library.Watermark.Parent then Tween(Library.Watermark, { GroupTransparency = 1 }, 0.25) end
    task.wait(0.3)
    for _, c in ipairs(Library.Connections) do pcall(function() c:Disconnect() end) end
    table.clear(Library.Connections)
    if Library.Gui then pcall(function() Library.Gui:Destroy() end) end
    if Library.KeyGui then pcall(function() Library.KeyGui:Destroy() end) end
    if Library.InfoGui then pcall(function() Library.InfoGui:Destroy() end) end
    Library.Gui, Library.KeyGui, Library.InfoGui = nil, nil, nil
end
Library.Unload = Library.Panic

function Library:CreateWindow()
    local gui = New("ScreenGui", { Name = CONFIG.GuiName, ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999 })
    local parent = GuiParent(gui)
    local old = parent:FindFirstChild(CONFIG.GuiName)
    if old then old:Destroy() end
    gui.Parent = parent
    Library.Gui = gui

    local win = setmetatable({ Order = 0, Groups = {}, TabsList = {}, Opened = false }, Window)
    Library.Window = win
    local size = CONFIG.WindowSize
    local main = New("CanvasGroup", { Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(size.X, size.Y), BackgroundColor3 = Theme.Background, BorderSizePixel = 0,
        GroupTransparency = 1, Visible = false, Parent = gui }, { Corner(10), Stroke(Theme.Stroke) })
    win.Main = main

    -- верхняя панель (за неё таскаем окно)
    local header = New("Frame", { Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1, Parent = main })
    local dragging, dragStart, startPos
    header.InputBegan:Connect(function(i)
        if IsPress(i) then dragging, dragStart, startPos = true, i.Position, main.Position end
    end)
    Connect(UIS.InputChanged, function(i)
        if dragging and IsMove(i) then
            local d = i.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    Connect(UIS.InputEnded, function(i) if IsPress(i) then dragging = false end end)

    -- сайдбар
    local sidebar = New("Frame", { Size = UDim2.new(0, 190, 1, 0), BackgroundTransparency = 1, Parent = main })
    New("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, Parent = sidebar })
    Logo({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 14),
        Size = UDim2.fromOffset(46, 46), Parent = sidebar }, 38)
    win.TabList = New("Frame", { Position = UDim2.fromOffset(0, 70), Size = UDim2.new(1, 0, 1, -130),
        BackgroundTransparency = 1, Parent = sidebar })
    New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = win.TabList })
    Pad(12, 0, 12, 0).Parent = win.TabList

    -- аккаунт слева снизу (клик = меню с Panic)
    local acc = New("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1),
        Size = UDim2.new(1, 0, 0, 58), BackgroundTransparency = 1, Parent = sidebar })
    New("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, Parent = acc })
    local accHover = New("Frame", { Size = UDim2.new(1, -16, 1, -10), Position = UDim2.fromOffset(8, 7),
        BackgroundColor3 = Theme.Selected, BackgroundTransparency = 1, Parent = acc }, { Corner(8) })
    local accName = CONFIG.AccountName or LocalPlayer.Name
    local av = New("Frame", { Position = UDim2.fromOffset(14, 14), Size = UDim2.fromOffset(30, 30),
        BackgroundColor3 = Theme.Field, ClipsDescendants = true, Parent = acc }, { Corner(15) })
    local avLetter = Label({ Text = string.upper(string.sub(accName, 1, 1)), Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 14, Parent = av })
    local avImage = New("ImageLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = av,
        Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=60&h=60" })
    local accNameLabel = Label({ Text = accName, Position = UDim2.fromOffset(54, 13), Size = UDim2.new(1, -62, 0, 16),
        Font = Enum.Font.GothamBold, TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd, Parent = acc })
    Label({ Text = CONFIG.AccountRole, Position = UDim2.fromOffset(54, 29), Size = UDim2.new(1, -62, 0, 14),
        TextSize = 11, TextColor3 = Theme.SubText, Parent = acc })
    Library:RegisterStreamerRef(function(on)
        accNameLabel.Text = on and "Скрыто" or accName
        avImage.Visible = not on
        avLetter.Text = on and "?" or string.upper(string.sub(accName, 1, 1))
    end)
    local accClick = New("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "",
        AutoButtonColor = false, ZIndex = 5, Parent = acc })
    accClick.MouseEnter:Connect(function() Tween(accHover, { BackgroundTransparency = 0.4 }, 0.15) end)
    accClick.MouseLeave:Connect(function() Tween(accHover, { BackgroundTransparency = 1 }, 0.15) end)

    -- всплывающее меню над аккаунтом: Panic
    local popup = New("CanvasGroup", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -58),
        Size = UDim2.new(1, -24, 0, 42), BackgroundColor3 = Theme.Panel, GroupTransparency = 1, Visible = false,
        ZIndex = 20, Parent = sidebar }, { Corner(8), Stroke(Theme.Stroke) })
    local panicBtn = New("TextButton", { Size = UDim2.new(1, -12, 1, -12), Position = UDim2.fromOffset(6, 6),
        BackgroundColor3 = Theme.Field, Text = "Panic", Font = Enum.Font.GothamBold, TextSize = 14,
        TextColor3 = Theme.Danger, AutoButtonColor = false, ZIndex = 21, Parent = popup }, { Corner(6) })
    panicBtn.MouseEnter:Connect(function() Tween(panicBtn, { BackgroundColor3 = Color3.fromRGB(46, 26, 28) }, 0.12) end)
    panicBtn.MouseLeave:Connect(function() Tween(panicBtn, { BackgroundColor3 = Theme.Field }, 0.12) end)
    panicBtn.MouseButton1Click:Connect(function() task.spawn(function() Library:Panic() end) end)
    local popupOpen = false
    local function setPopup(v)
        if v == popupOpen then return end
        popupOpen = v
        if v then
            popup.Visible = true
            popup.Position = UDim2.new(0, 12, 1, -50)
            Tween(popup, { GroupTransparency = 0, Position = UDim2.new(0, 12, 1, -58) }, 0.22, Enum.EasingStyle.Quint)
        else
            Tween(popup, { GroupTransparency = 1, Position = UDim2.new(0, 12, 1, -50) }, 0.18)
            task.delay(0.2, function() if not popupOpen then popup.Visible = false end end)
        end
    end
    accClick.MouseButton1Click:Connect(function() setPopup(not popupOpen) end)
    Connect(UIS.InputBegan, function(i)
        if popupOpen and IsPress(i) then
            local p = i.Position
            local function inside(g)
                local a, s = g.AbsolutePosition, g.AbsoluteSize
                return p.X >= a.X and p.X <= a.X + s.X and p.Y >= a.Y and p.Y <= a.Y + s.Y
            end
            if not inside(popup) and not inside(acc) then setPopup(false) end
        end
    end)

    -- контент
    local content = New("Frame", { Position = UDim2.fromOffset(190, 0), Size = UDim2.new(1, -190, 1, 0),
        BackgroundTransparency = 1, Parent = main })
    local searchWrap = New("Frame", { Position = UDim2.fromOffset(14, 14), Size = UDim2.new(1, -28, 0, 30),
        BackgroundColor3 = Theme.Panel, Parent = content }, { Corner(6), Stroke() })
    local search = New("TextBox", { Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1, Text = "", PlaceholderText = CONFIG.SearchPlaceholder,
        PlaceholderColor3 = Theme.SubText, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Parent = searchWrap })
    search:GetPropertyChangedSignal("Text"):Connect(function()
        local q = string.lower(search.Text)
        for _, m in ipairs(Library.Modules) do
            m.Frame.Visible = (q == "") or (string.find(m.Name, q, 1, true) ~= nil)
        end
    end)
    win.Pages = New("Frame", { Position = UDim2.fromOffset(14, 58), Size = UDim2.new(1, -28, 1, -70),
        BackgroundTransparency = 1, Parent = content })

    -- открытие/закрытие + бинды + R открывает окно User Info, пока хаб открыт
    Connect(UIS.InputBegan, function(input, gpe)
        if Library.Listening then Library.Listening(input); return end
        if gpe or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if input.KeyCode == CONFIG.MenuKey then win:Toggle(); return end
        if input.KeyCode == Enum.KeyCode.R and win.Opened then
            Library:ToggleInfoWindow()
            return
        end
        for _, b in ipairs(Library.Binds) do
            if b.obj.Value and input.KeyCode == b.obj.Value then b.fn() end
        end
    end)

    -- кнопка для телефона
    if UIS.TouchEnabled and not UIS.KeyboardEnabled then
        local tb = New("TextButton", { Position = UDim2.new(1, -56, 0, 10), Size = UDim2.fromOffset(44, 44),
            BackgroundColor3 = Theme.Background, Text = CONFIG.LogoText, Font = Enum.Font.GothamBlack, TextSize = 22,
            TextColor3 = Theme.Accent, Parent = gui }, { Corner(10), Stroke(Theme.Accent, 0.5) })
        if LogoAsset then
            tb.Text = ""
            Logo({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(28, 28), Parent = tb }, 22)
        end
        tb.MouseButton1Click:Connect(function() win:Toggle() end)
    end

    return win
end

--// ───────────── ЭКРАН КЛЮЧА ─────────────
--// onSuccess вызывается после правильного ключа (когда окно ключа уже плавно скрылось)
function Library:KeyGate(onSuccess)
    local gui = New("ScreenGui", { Name = CONFIG.GuiName .. "_Key", ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 1000 })
    local parent = GuiParent(gui)
    local old = parent:FindFirstChild(CONFIG.GuiName .. "_Key")
    if old then old:Destroy() end
    gui.Parent = parent
    Library.KeyGui = gui

    local card = New("CanvasGroup", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 24),
        Size = UDim2.fromOffset(360, 250), BackgroundColor3 = Theme.Background, GroupTransparency = 1, Parent = gui },
        { Corner(12), Stroke(Theme.Stroke) })
    Logo({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 18),
        Size = UDim2.fromOffset(54, 54), Parent = card }, 42)
    Label({ Text = CONFIG.HubName, Position = UDim2.fromOffset(0, 80), Size = UDim2.new(1, 0, 0, 22),
        TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 18, Parent = card })
    Label({ Text = "Введите ключ доступа", Position = UDim2.fromOffset(0, 102), Size = UDim2.new(1, 0, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = Theme.SubText, TextSize = 12, Parent = card })

    local boxWrap = New("Frame", { Position = UDim2.fromOffset(24, 130), Size = UDim2.new(1, -48, 0, 36),
        BackgroundColor3 = Theme.Panel, Parent = card }, { Corner(8) })
    local boxStroke = Stroke(Theme.Stroke); boxStroke.Parent = boxWrap
    local box = New("TextBox", { Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1, Text = "", PlaceholderText = "RAN-XXX-XXXX-XXXX",
        PlaceholderColor3 = Theme.SubText, Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Center, ClearTextOnFocus = false, Parent = boxWrap })
    box.Focused:Connect(function() Tween(boxStroke, { Color = Theme.Accent }, 0.15) end)
    box.FocusLost:Connect(function() Tween(boxStroke, { Color = Theme.Stroke }, 0.15) end)

    local btn = New("TextButton", { Position = UDim2.fromOffset(24, 178), Size = UDim2.new(1, -48, 0, 36),
        BackgroundColor3 = Theme.Accent, Text = "Войти", Font = Enum.Font.GothamBold, TextSize = 14,
        TextColor3 = Color3.fromRGB(20, 20, 22), AutoButtonColor = false, Parent = card }, { Corner(8) })
    btn.MouseEnter:Connect(function() Tween(btn, { BackgroundColor3 = Theme.Accent:Lerp(Color3.new(1, 1, 1), 0.15) }, 0.12) end)
    btn.MouseLeave:Connect(function() Tween(btn, { BackgroundColor3 = Theme.Accent }, 0.12) end)
    local status = Label({ Text = "", Position = UDim2.fromOffset(0, 220), Size = UDim2.new(1, 0, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Center, TextSize = 12, Parent = card })

    -- сохранённый ключ только подставляется, вход — вручную
    local saved = LoadFile(CONFIG.KeyFile)
    if saved then
        saved = (saved:gsub("%s+", ""))
        if saved ~= "" then box.Text = saved end
    end

    Tween(card, { GroupTransparency = 0, Position = UDim2.new(0.5, 0, 0.5, 0) }, 0.45, Enum.EasingStyle.Quint)

    local busy = false
    local function shake()
        local base = card.Position
        for _, dx in ipairs({ 10, -10, 6, -6, 0 }) do
            Tween(card, { Position = base + UDim2.fromOffset(dx, 0) }, 0.05)
            task.wait(0.05)
        end
    end
    local function submit()
        if busy then return end
        busy = true
        local entered = (box.Text:gsub("%s+", "")):upper()
        if entered == CONFIG.AccessKey then
            status.TextColor3 = Color3.fromRGB(110, 220, 140)
            status.Text = "Доступ разрешён"
            SaveFile(CONFIG.KeyFile, entered)
            task.wait(0.35)
            Tween(card, { GroupTransparency = 1, Position = UDim2.new(0.5, 0, 0.5, -24) }, 0.35, Enum.EasingStyle.Quint)
            task.wait(0.4)
            gui:Destroy()
            Library.KeyGui = nil
            onSuccess()
        else
            status.TextColor3 = Theme.Danger
            status.Text = "Неверный ключ"
            shake()
            busy = false
        end
    end
    btn.MouseButton1Click:Connect(submit)
    box.FocusLost:Connect(function(enter) if enter then submit() end end)
end


--// ───────────── ЛИЦЕНЗИЯ (ID + счётчик запусков для окна User Info) ─────────────
local function LoadLicense()
    local id, executions = nil, 0
    local raw = LoadFile(CONFIG.LicenseFile)
    if raw and raw ~= "" then
        local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
        if ok and type(data) == "table" then
            if type(data.id) == "string" and data.id ~= "" then id = data.id end
            if type(data.executions) == "number" then executions = data.executions end
        end
    end
    if not id then
        local chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        local parts = {}
        for i = 1, 10 do
            local n = math.random(1, #chars)
            parts[i] = chars:sub(n, n)
        end
        id = table.concat(parts)
    end
    executions = executions + 1
    pcall(function() SaveFile(CONFIG.LicenseFile, HttpService:JSONEncode({ id = id, executions = executions })) end)
    return id, executions
end
local LicenseId, LicenseExecutions = LoadLicense()

--// ───────────── СПИСОК ОБНОВЛЕНИЙ ─────────────
local CHANGELOG = {
    { v = "v3.5", d = "01.11.2026", t = "Bounty Farm и Wanted List Farm разделены и работают вместе без конфликтов (общий движок депозита). Вкладка «История» — отдельная история для каждой функции." },
    { v = "v3.4", t = "ESP Glow и ESP 2D Boxes в цвете клиента. Kill Farm: бьёт всех, свой счёт по каждому игроку, повторно берёт только через 6 секунд после его смерти." },
    { v = "v3.3", t = "Телепорт на карты по точным координатам — вручную и автоматически в фарме при смене карты." },
    { v = "v3.2", t = "Убраны лишние оверлеи, «Сервер» перенесён в «Настройки», у Force reset выбор высоты, меню на Right Ctrl, Anti Grab — в «Разное», уведомления можно двигать и смотреть превью, новые плавные стрелки." },
    { v = "v3.1", t = "При смене карты фарм сам телепортируется на новую карту." },
    { v = "v3.0", t = "Переход на Ran Hub (NurLib): вкладки Бой / Движение / Игрок / Визуалы / Разное, Panic по клику на аккаунт, один ключ доступа, всё хранится в папке CarryPeople3." },
    { v = "v2.1", t = "Wanted List теперь читается из атрибута WantedBounty игроков этого сервера — глобальная доска не считается. Настоящие названия карт." },
    { v = "v2.0", t = "Горизонтальное положение в пропасти, режим Wanted List, стрелки на игроков, трекер карт, сброс через teleportRequest." },
    { v = "v1.7", t = "Полная выгрузка скрипта, Force reset на фиксированную высоту." },
    { v = "v1.6", t = "Сохранение истории депозитов и ключа доступа в папке экзекутора." },
    { v = "v1.5", t = "Кулдаун депозита 100 секунд, постоянный поиск целей, укрытие на высоте, если целей нет." },
    { v = "v1.4", t = "Пауза после смерти, повторные попытки граба без риска умереть, Auto Deposit." },
    { v = "v1.3", t = "Депозит исправлен (InvokeServer с суммой), статус показывает честный ответ сервера." },
    { v = "v1.2", t = "Проверка «держу ли игрока», зависание телепортом, сброс серией в несколько человек." },
    { v = "v1.1", t = "Ты остаёшься жив на дне: выброс цели, депозит, пауза, затем падение." },
    { v = "v1.0", t = "Первая версия Bounty Farm: телепорт к цели, граб, выброс, депозит в клан, повтор." },
}

--// Копирует ссылку на Discord в буфер обмена
function Library:CopyDiscord()
    if setclipboard then
        local ok = pcall(setclipboard, CONFIG.DiscordInvite)
        Library:Notify(ok and "Ссылка на Discord скопирована" or "Не удалось скопировать ссылку")
    else
        Library:Notify("Экзекутор не умеет копировать в буфер: " .. CONFIG.DiscordInvite, 6)
    end
end

--// ───────────── ОКНО USER INFO (появляется при загрузке, R — пока хаб открыт) ─────────────
function Library:ToggleInfoWindow()
    if Library.InfoGui and Library.InfoGui.Parent then
        Library:HideInfoWindow()
    else
        Library:ShowInfoWindow()
    end
end

function Library:HideInfoWindow()
    local gui = Library.InfoGui
    if not gui then return end
    local card = gui:FindFirstChild("Card")
    if card then
        Tween(card, { GroupTransparency = 1, Position = card.Position + UDim2.fromOffset(0, 16) }, 0.22, Enum.EasingStyle.Quint)
    end
    task.delay(0.24, function()
        if Library.InfoGui == gui then
            gui:Destroy()
            Library.InfoGui = nil
        end
    end)
end

function Library:ShowInfoWindow()
    if Library.InfoGui and Library.InfoGui.Parent then return end
    local gui = New("ScreenGui", { Name = CONFIG.GuiName .. "_Info", ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 950 })
    gui.Parent = GuiParent(gui)
    Library.InfoGui = gui

    local backdrop = New("TextButton", { Name = "Backdrop", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = gui })
    Tween(backdrop, { BackgroundTransparency = 0.45 }, 0.25)
    backdrop.MouseButton1Click:Connect(function() Library:HideInfoWindow() end)

    local card = New("CanvasGroup", { Name = "Card", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 16),
        Size = UDim2.fromOffset(640, 420), BackgroundColor3 = Theme.Background, GroupTransparency = 1, Parent = gui },
        { Corner(12), Stroke(Theme.Stroke) })
    Tween(card, { GroupTransparency = 0, Position = UDim2.fromScale(0.5, 0.5) }, 0.32, Enum.EasingStyle.Quint)

    local closeBtn = New("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12),
        Size = UDim2.fromOffset(26, 26), BackgroundColor3 = Theme.Field, Text = "✕", Font = Enum.Font.GothamBold,
        TextSize = 14, TextColor3 = Theme.SubText, AutoButtonColor = false, ZIndex = 5, Parent = card }, { Corner(6) })
    closeBtn.MouseEnter:Connect(function() Tween(closeBtn, { TextColor3 = Theme.Danger }, 0.12) end)
    closeBtn.MouseLeave:Connect(function() Tween(closeBtn, { TextColor3 = Theme.SubText }, 0.12) end)
    closeBtn.MouseButton1Click:Connect(function() Library:HideInfoWindow() end)

    -- ───── левая колонка: User Info ─────
    local left = New("Frame", { Position = UDim2.fromOffset(20, 20), Size = UDim2.fromOffset(230, 380),
        BackgroundColor3 = Theme.Panel, Parent = card }, { Corner(10), Stroke() })
    Label({ Text = "User Info", Position = UDim2.fromOffset(16, 14), Size = UDim2.new(1, -32, 0, 20),
        Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = Theme.Accent, Parent = left })

    local avatarBox = New("Frame", { Position = UDim2.fromOffset(16, 44), Size = UDim2.fromOffset(198, 150),
        BackgroundColor3 = Theme.Field, ClipsDescendants = true, Parent = left }, { Corner(8), Stroke() })
    local avatarImage = New("ImageLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        ScaleType = Enum.ScaleType.Crop,
        Image = "rbxthumb://type=AvatarBust&id=" .. tostring(LocalPlayer.UserId) .. "&w=420&h=420",
        Parent = avatarBox })
    Library:RegisterStreamerRef(function(on) avatarImage.Visible = not on end)

    Label({ Text = "ID: " .. LicenseId, Position = UDim2.fromOffset(16, 204), Size = UDim2.new(1, -32, 0, 18),
        TextSize = 13, TextColor3 = Theme.Text, Parent = left })
    Label({ Text = "Total Executions: " .. tostring(LicenseExecutions), Position = UDim2.fromOffset(16, 224),
        Size = UDim2.new(1, -32, 0, 18), TextSize = 13, TextColor3 = Theme.Text, Parent = left })

    New("Frame", { Position = UDim2.fromOffset(16, 258), Size = UDim2.new(1, -32, 0, 1),
        BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, Parent = left })

    Label({ Text = "Community", Position = UDim2.fromOffset(16, 270), Size = UDim2.new(1, -32, 0, 20),
        Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Theme.Accent, Parent = left })
    local discordBtn = New("TextButton", { Position = UDim2.fromOffset(16, 298), Size = UDim2.new(1, -32, 0, 32),
        BackgroundColor3 = Theme.Field, Text = "Copy Discord Invite", Font = Enum.Font.GothamMedium, TextSize = 13,
        TextColor3 = Theme.Text, AutoButtonColor = false, Parent = left }, { Corner(7) })
    discordBtn.MouseEnter:Connect(function() Tween(discordBtn, { BackgroundColor3 = Theme.Selected }, 0.12) end)
    discordBtn.MouseLeave:Connect(function() Tween(discordBtn, { BackgroundColor3 = Theme.Field }, 0.12) end)
    discordBtn.MouseButton1Click:Connect(function() Library:CopyDiscord() end)

    -- ───── правая колонка: список обновлений ─────
    local right = New("Frame", { Position = UDim2.fromOffset(264, 20), Size = UDim2.fromOffset(356, 380),
        BackgroundColor3 = Theme.Panel, Parent = card }, { Corner(10), Stroke() })
    Label({ Text = "Обновления", Position = UDim2.fromOffset(16, 14), Size = UDim2.new(1, -32, 0, 20),
        Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = Theme.Accent, Parent = right })
    local scroller = New("ScrollingFrame", { Position = UDim2.fromOffset(12, 42), Size = UDim2.new(1, -24, 1, -54),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Accent,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = right })
    New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroller })
    for index, entry in ipairs(CHANGELOG) do
        local row = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1, LayoutOrder = index, Parent = scroller })
        local header = entry.v .. (entry.d and ("  —  " .. entry.d) or "")
        Label({ Text = header, Size = UDim2.new(1, 0, 0, 16), Font = Enum.Font.GothamBold, TextSize = 13,
            TextColor3 = Theme.Text, Parent = row })
        Label({ Text = entry.t, Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextColor3 = Theme.SubText, TextSize = 12,
            Parent = row })
    end
end

--// ═══════════════════════════════════════════════════════════════════
--// ИГРОВЫЕ ФУНКЦИИ
--// ═══════════════════════════════════════════════════════════════════
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService   = game:GetService("TeleportService")
local Mouse             = LocalPlayer:GetMouse()

local Shared = {
    playerDropdowns = {},
    antiGrabPaused = false,   -- Force reset ставит на паузу, чтобы Anti Grab не тянул вверх
    mapChangeHooks = {},      -- функции, которые зовутся при смене карты
}

--// Карты: id из Events.mapChange -> название и точка телепорта (координаты из файла)
local MAPS = {
    ["1"] = { name = "Castle Cliffs", pos = Vector3.new(-2573, 71, 357) },
    ["2"] = { name = "Cliffside",     pos = Vector3.new(-2117, 26, 2623) },
    ["3"] = { name = "Desert Temple", pos = Vector3.new(-128, 99, 2681) },
    ["4"] = { name = "City Map",      pos = Vector3.new(-488, 84, 324) },
    ["5"] = { name = "Ice Map",       pos = Vector3.new(-1993, 175, -2182) },
    ["6"] = { name = "Train Map",     pos = Vector3.new(-2368, 111, -4337) },
    ["7"] = { name = "Halloween Map", pos = Vector3.new(-4575, 36, 425) },
}
local MAP_ORDER = { "1", "2", "3", "4", "5", "6", "7" }

--// ───────────── общие хелперы ─────────────
local function keepConnection(connection)
    table.insert(Library.Connections, connection)
    return connection
end

local function getCharacterParts(player)
    local character = player and player.Character
    if not character then
        return nil
    end
    return character, character:FindFirstChildOfClass("Humanoid"), character:FindFirstChild("HumanoidRootPart")
end

local function getGrabPart(character)
    if not character then return nil end
    return character:FindFirstChild("Right Arm")
        or character:FindFirstChild("RightHand")
        or character:FindFirstChild("RightLowerArm")
        or character:FindFirstChild("Left Arm")
        or character:FindFirstChild("LeftHand")
end

local function getClosestPlayer()
    local _, _, myRoot = getCharacterParts(LocalPlayer)
    if not myRoot then
        return nil
    end
    local closest
    local shortestDistance = math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local _, humanoid, root = getCharacterParts(player)
            if humanoid and humanoid.Health > 0 and root then
                local distance = (root.Position - myRoot.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closest = player
                end
            end
        end
    end
    return closest, shortestDistance
end

local function getGrabRemote()
    local events = ReplicatedStorage:FindFirstChild("Events")
    local remote = events and events:FindFirstChild("Grab")
    if remote and remote:IsA("RemoteEvent") then
        return remote
    end
    return nil
end

local function findPlayerByName(name)
    if not name then return nil end
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name == name then return player end
    end
    return nil
end

-- присваивание proxy.Text = "..." обновляет подпись в меню
local function StatusProxy(labelObject)
    return setmetatable({}, {
        __index = function(_, key)
            if key == "Text" then return labelObject.Value end
        end,
        __newindex = function(_, key, value)
            if key == "Text" then labelObject:Set(value) end
        end,
    })
end

--// выпадающие списки игроков обновляются сами при входе/выходе игроков
local function registerPlayerDropdown(dropdown)
    table.insert(Shared.playerDropdowns, dropdown)
end

local function refreshPlayerDropdowns()
    local names = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            names[#names + 1] = player.Name
        end
    end
    table.sort(names, function(a, b) return a:lower() < b:lower() end)
    for _, dropdown in ipairs(Shared.playerDropdowns) do
        dropdown:Refresh(names)
        if dropdown.Value and not findPlayerByName(dropdown.Value) then
            dropdown:Set(nil, true)
        end
    end
end

--// Кнопки "Preview notification" и "Переместить уведомления" для любого канала уведомлений
local function AddNotifyControls(target, channel)
    target:AddButton({ Name = "Preview notification", Callback = function()
        Library:PreviewNotify(channel)
    end })
    local moveButton
    moveButton = target:AddButton({ Name = "Переместить уведомления", Callback = function()
        local ch = Library.NotifyChannels[channel]
        local turnOn = not (ch and ch.Editing)
        Library:SetNotifyEdit(channel, turnOn)
        moveButton:SetText(turnOn and "Готово (сохранить позицию)" or "Переместить уведомления")
    end })
end

--// ═════════════════════════ БОЙ ═════════════════════════
local function SetupCombat(tab)
    --// ГРАБ
    local grabSection = tab:AddSection("Граб", "Left")
    local grabStatus = StatusProxy(grabSection:AddLabel({ Text = "Статус: готов" }))

    local function performGrab(target, useTeleport)
        if not target or target == LocalPlayer then
            grabStatus.Text = "Статус: выбери игрока"
            return
        end
        local _, targetHumanoid, targetRoot = getCharacterParts(target)
        local _, _, myRoot = getCharacterParts(LocalPlayer)
        if not targetHumanoid or targetHumanoid.Health <= 0 or not targetRoot or not myRoot then
            grabStatus.Text = "Статус: персонаж недоступен"
            return
        end
        local remote = getGrabRemote()
        if not remote then
            grabStatus.Text = "Статус: ремоут Grab не найден"
            return
        end
        local arm = getGrabPart(target.Character)
        if not arm then
            grabStatus.Text = "Статус: рука цели не найдена"
            return
        end
        local oldCFrame = myRoot.CFrame
        if useTeleport then
            myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 2)
            task.wait(0.12)
            local _, _, refreshedRoot = getCharacterParts(LocalPlayer)
            if refreshedRoot then
                myRoot = refreshedRoot
            end
        end
        local argsOK = pcall(function()
            remote:FireServer(
                arm,
                "Grab",
                targetRoot.Position,
                CFrame.lookAt(targetRoot.Position, myRoot.Position)
            )
        end)
        if useTeleport then
            task.wait(0.12)
            local _, _, refreshedRoot = getCharacterParts(LocalPlayer)
            if refreshedRoot then
                refreshedRoot.CFrame = oldCFrame
            end
        end
        grabStatus.Text = argsOK
            and ("Статус: запрос на граб отправлен → " .. target.Name)
            or "Статус: запрос не прошёл"
    end

    grabSection:AddKeybind({ Name = "Бинд граба (без TP)", Default = Enum.KeyCode.R, Callback = function()
        performGrab(getClosestPlayer(), false)
    end })
    grabSection:AddButton({ Name = "Схватить ближайшего (без TP)", Callback = function()
        performGrab(getClosestPlayer(), false)
    end })
    local grabDropdown = grabSection:AddDropdown({ Name = "Игрок", Options = {}, NoFlag = true })
    registerPlayerDropdown(grabDropdown)
    grabSection:AddButton({ Name = "Схватить выбранного (с TP)", Callback = function()
        local target = findPlayerByName(grabDropdown.Value)
        if not target then
            grabStatus.Text = "Статус: сначала выбери игрока"
            return
        end
        performGrab(target, true)
    end })
    grabSection:AddLabel({ Text = "Дальность без TP лучше держать 3–5 studs. Сервер может отклонить запрос." })

    --// ───────────── KILL FARM ─────────────
    --// Как Bounty Farm, но бьёт всех подряд: схватить → Y = -100 → выбросить → ждать смерть.
    --// У каждого игрока в скрипте есть счёт; после смерти игрока его можно брать снова только через N секунд (по умолчанию 6).
    local killSection = tab:AddSection("Kill Farm", "Right")
    local killStatus = StatusProxy(killSection:AddLabel({ Text = "Статус: выключен" }))
    local killScoreLabel = killSection:AddLabel({ Text = "Всего убийств: 0" })

    local KILL_PIT_Y = -100
    local KILL_HIDE_Y = 5000
    local kf = {
        running = false,
        runId = 0,
        total = 0,
        scores = {},      -- [player] = сколько раз убит нами
        deathAt = {},     -- [player] = os.clock() его последней смерти
        skipUntil = {},   -- [player] = не трогать до этого времени (неудачные попытки)
        pause = 6,        -- через сколько секунд после смерти его можно брать снова
        attempts = 8,
        hideWhenIdle = true,
        freezeCF = nil,
        freezeConn = nil,
        savedAntiVoid = nil,
    }
    local killModule = nil

    local function kfRefreshScore()
        local list = {}
        for player, count in pairs(kf.scores) do
            if player.Parent then
                list[#list + 1] = { name = player.Name, count = count }
            end
        end
        table.sort(list, function(a, b)
            if a.count ~= b.count then return a.count > b.count end
            return a.name < b.name
        end)
        local lines = { "Всего убийств: " .. kf.total }
        for index = 1, math.min(#list, 8) do
            lines[#lines + 1] = string.format("%s — %d", list[index].name, list[index].count)
        end
        killScoreLabel:Set(table.concat(lines, "\n"))
    end

    --// Отслеживаем смерти всех игроков (нужны для паузы повторного взятия)
    local function kfTrackPlayer(player)
        if player == LocalPlayer then return end
        local function hook(character)
            local humanoid = character:WaitForChild("Humanoid", 5)
            if humanoid then
                humanoid.Died:Connect(function()
                    kf.deathAt[player] = os.clock()
                end)
            end
        end
        if player.Character then task.spawn(hook, player.Character) end
        keepConnection(player.CharacterAdded:Connect(hook))
    end
    for _, player in ipairs(Players:GetPlayers()) do kfTrackPlayer(player) end
    keepConnection(Players.PlayerAdded:Connect(kfTrackPlayer))
    keepConnection(Players.PlayerRemoving:Connect(function(player)
        kf.scores[player] = nil
        kf.deathAt[player] = nil
        kf.skipUntil[player] = nil
        task.defer(kfRefreshScore)
    end))

    --// Зависание телепортом (без Anchored)
    local function kfFreeze(cf)
        kf.freezeCF = cf
        if kf.freezeConn then return end
        kf.freezeConn = RunService.Heartbeat:Connect(function()
            if not kf.freezeCF then return end
            local _, humanoid, root = getCharacterParts(LocalPlayer)
            if root and humanoid and humanoid.Health > 0 then
                root.CFrame = kf.freezeCF
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end
        end)
    end
    local function kfUnfreeze()
        kf.freezeCF = nil
        if kf.freezeConn then
            kf.freezeConn:Disconnect()
            kf.freezeConn = nil
        end
    end
    local function kfHideHigh()
        local _, humanoid, root = getCharacterParts(LocalPlayer)
        if root and humanoid and humanoid.Health > 0 then
            local position = root.Position
            kfFreeze(CFrame.new(position.X, KILL_HIDE_Y, position.Z))
            return true
        end
        return false
    end

    --// Держу ли я этого игрока (вызывать, когда уже отошёл от места граба)
    local function kfIsHolding(target)
        local myChar = LocalPlayer.Character
        local targetChar = target and target.Character
        if not myChar or not targetChar then return false end
        local _, _, myRoot = getCharacterParts(LocalPlayer)
        local _, _, targetRoot = getCharacterParts(target)
        if not myRoot or not targetRoot then return false end
        if (targetRoot.Position - myRoot.Position).Magnitude <= 15 then
            return true
        end
        local function linkedBetween(a, b)
            if not a or not b then return false end
            return (a:IsDescendantOf(myChar) and b:IsDescendantOf(targetChar))
                or (a:IsDescendantOf(targetChar) and b:IsDescendantOf(myChar))
        end
        for _, container in ipairs({ myChar, targetChar }) do
            for _, d in ipairs(container:GetDescendants()) do
                if d:IsA("Weld") or d:IsA("WeldConstraint") or d:IsA("Motor6D") then
                    if linkedBetween(d.Part0, d.Part1) then return true end
                elseif d:IsA("Constraint") then
                    local a0 = d.Attachment0 and d.Attachment0.Parent
                    local a1 = d.Attachment1 and d.Attachment1.Parent
                    if linkedBetween(a0, a1) then return true end
                end
            end
        end
        return false
    end

    local function kfRelease(arm, target)
        local _, _, myRoot = getCharacterParts(LocalPlayer)
        local _, _, targetRoot = getCharacterParts(target)
        if not myRoot or not targetRoot then return end
        local events = ReplicatedStorage:FindFirstChild("Events")
        if not events then return end
        local grab = events:FindFirstChild("Grab")
        if grab and grab:IsA("RemoteEvent") then
            for _, action in ipairs({ "Release", "Drop", "Throw", "Let go", "Ungrab" }) do
                pcall(function()
                    grab:FireServer(arm, action, targetRoot.Position, CFrame.lookAt(targetRoot.Position, myRoot.Position))
                end)
            end
        end
        for _, name in ipairs({ "Release", "Drop", "Ungrab", "Throw" }) do
            local remote = events:FindFirstChild(name)
            if remote and remote:IsA("RemoteEvent") then
                pcall(function() remote:FireServer() end)
            end
        end
    end

    --// Цель: сначала тот, кого убивали меньше всего, при равенстве — ближайший
    local function kfPickTarget()
        local _, _, myRoot = getCharacterParts(LocalPlayer)
        local now = os.clock()
        local best, bestScore, bestDistance
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and (kf.skipUntil[player] or 0) <= now then
                local lastDeath = kf.deathAt[player]
                if not lastDeath or now - lastDeath >= kf.pause then
                    local _, humanoid, root = getCharacterParts(player)
                    if humanoid and humanoid.Health > 0 and root then
                        local score = kf.scores[player] or 0
                        local distance = myRoot and (root.Position - myRoot.Position).Magnitude or 0
                        if not best or score < bestScore or (score == bestScore and distance < bestDistance) then
                            best, bestScore, bestDistance = player, score, distance
                        end
                    end
                end
            end
        end
        return best
    end

    local function kfAlive(runId)
        return kf.running and kf.runId == runId and Library.Gui and Library.Gui.Parent
    end

    local function kfLoop(runId)
        while kfAlive(runId) do
            local _, myHumanoid, myRoot = getCharacterParts(LocalPlayer)
            if not myHumanoid or myHumanoid.Health <= 0 or not myRoot then
                kfUnfreeze()
                killStatus.Text = "Жду респавн..."
                task.wait(0.5)
                continue
            end

            local target = kfPickTarget()
            if not target then
                -- никого нельзя брать: зависаем высоко и продолжаем проверять
                if kf.hideWhenIdle and (not kf.freezeCF or math.abs(kf.freezeCF.Position.Y - KILL_HIDE_Y) > 1) then
                    kfHideHigh()
                end
                killStatus.Text = "Нет целей (все на паузе после смерти) — жду"
                task.wait(0.4)
                continue
            end

            local remote = getGrabRemote()
            if not remote then
                killStatus.Text = "Ремоут Grab не найден"
                task.wait(1)
                continue
            end

            -- 1) взять: телепорт к цели → граб → Y = -100 (лёжа) → проверка, что он у меня в руках
            local held, arm, died = false, nil, false
            for attempt = 1, kf.attempts do
                if not kfAlive(runId) then break end
                local _, hum, root = getCharacterParts(LocalPlayer)
                if not hum or hum.Health <= 0 or not root then
                    died = true
                    break
                end
                local _, targetHum, targetRoot = getCharacterParts(target)
                if not targetHum or targetHum.Health <= 0 or not targetRoot then break end
                arm = getGrabPart(hum.Parent)
                if not arm then break end

                kfUnfreeze()
                killStatus.Text = string.format("Беру %s — попытка %d/%d", target.Name, attempt, kf.attempts)
                root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 2)
                task.wait(0.15)
                pcall(function()
                    remote:FireServer(
                        getGrabPart(target.Character) or arm,
                        "Grab",
                        targetRoot.Position,
                        CFrame.lookAt(targetRoot.Position, root.Position)
                    )
                end)
                task.wait(0.35)
                local position = root.Position
                kfFreeze(CFrame.new(position.X, KILL_PIT_Y, position.Z) * CFrame.Angles(math.rad(90), 0, 0))
                task.wait(0.5)
                if kfIsHolding(target) then
                    held = true
                    break
                end
            end
            if died then
                kfUnfreeze()
                continue
            end
            if not kfAlive(runId) then break end
            if not held then
                kf.skipUntil[target] = os.clock() + 8
                killStatus.Text = "Не удалось взять " .. target.Name .. " — следующий"
                task.wait(0.3)
                continue
            end

            -- 2) выбросить
            killStatus.Text = "Выбрасываю " .. target.Name
            local dropTime = os.clock()
            local released = false
            for _ = 1, 4 do
                kfRelease(arm, target)
                task.wait(0.4)
                local _, targetHum = getCharacterParts(target)
                if not kfIsHolding(target) or not targetHum or targetHum.Health <= 0 then
                    released = true
                    break
                end
            end
            if not released then
                kf.skipUntil[target] = os.clock() + 8
                killStatus.Text = "Не удалось выбросить " .. target.Name
                continue
            end

            -- 3) дождаться его смерти и записать счёт
            local deadSeen = false
            local waitStart = os.clock()
            while kfAlive(runId) and os.clock() - waitStart < 6 do
                local _, targetHum = getCharacterParts(target)
                if not target.Parent then break end
                if (kf.deathAt[target] and kf.deathAt[target] >= dropTime) or (targetHum and targetHum.Health <= 0) then
                    deadSeen = true
                    break
                end
                task.wait(0.15)
            end
            if deadSeen and target.Parent then
                kf.scores[target] = (kf.scores[target] or 0) + 1
                kf.total = kf.total + 1
                kf.deathAt[target] = kf.deathAt[target] or os.clock()
                kf.skipUntil[target] = nil
                kfRefreshScore()
                if Shared.historyAdd then
                    Shared.historyAdd("kill", string.format("Убит %s (его счёт: %d)", target.Name, kf.scores[target]), nil, "kill")
                end
                killStatus.Text = string.format("Убит %s (его счёт: %d)", target.Name, kf.scores[target])
            else
                kf.skipUntil[target] = os.clock() + 8
                killStatus.Text = target.Name .. " не умер — пропускаю"
            end
        end
        if kf.runId == runId then kfUnfreeze() end
    end

    local function kfStop()
        kf.running = false
        kf.runId = kf.runId + 1
        kfUnfreeze()
        if kf.savedAntiVoid ~= nil then
            Shared.setAntiVoid(kf.savedAntiVoid)
            kf.savedAntiVoid = nil
        end
        Shared.antiGrabPaused = false
        if killModule then killModule:Set(false, true) end
        killStatus.Text = "Статус: остановлен"
    end
    Shared.killFarmStop = function()
        if kf.running then kfStop() end
    end

    killModule = killSection:AddModule({ Name = "Kill Farm", Callback = function(state)
        if state then
            if kf.running then return end
            if Shared.farmStop then Shared.farmStop() end -- Bounty Farm и Kill Farm вместе не работают
            kf.running = true
            kf.runId = kf.runId + 1
            kf.savedAntiVoid = Shared.getAntiVoid()
            Shared.setAntiVoid(false)       -- иначе Anti Void вытащит с Y = -100
            Shared.antiGrabPaused = true    -- и Anti Grab не должен тянуть вверх
            killStatus.Text = "Статус: работает"
            task.spawn(kfLoop, kf.runId)
        else
            if kf.running then kfStop() end
        end
    end })
    killModule:AddSlider({ Name = "Пауза после смерти", Min = 1, Max = 30, Default = 6, Increment = 1, Suffix = " с",
        Callback = function(value) kf.pause = value end })
    killModule:AddSlider({ Name = "Попыток граба", Min = 2, Max = 15, Default = 8, Increment = 1,
        Callback = function(value) kf.attempts = value end })
    killModule:AddToggle({ Name = "Прятаться, если целей нет", Default = true, Callback = function(value)
        kf.hideWhenIdle = value
    end })
    killModule:AddButton({ Name = "Сбросить счёт", Callback = function()
        table.clear(kf.scores)
        kf.total = 0
        kfRefreshScore()
    end })
    killSection:AddLabel({ Text = "Берёт того, кого убивали меньше всех (при равенстве — ближайшего), выбрасывает в пропасть и ждёт смерть. После смерти игрока его снова берут только через заданную паузу (6 с)." })

    Library:AddPanicHook(function()
        kf.running = false
        kf.runId = kf.runId + 1
        kfUnfreeze()
    end)
end

--// ═════════════════════════ ANTI GRAB (вкладка Разное) ═════════════════════════
local function SetupAntiGrab(tab)
    --// ANTI GRAB
    local antiSection = tab:AddSection("Anti Grab", "Right")
    local antiStatus = StatusProxy(antiSection:AddLabel({ Text = "Выбери игроков, за которыми следить." }))

    local ag = {
        enabled = true,
        holding = false,
        saved = nil,
        targets = {},        -- [player] = true
        distance = 30,
        height = 300,
    }
    Shared.antiGrab = ag

    -- кнопка UNSTUCK по центру внизу
    local unstuckButton = New("TextButton", {
        Name = "Unstuck",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -30),
        Size = UDim2.fromOffset(140, 42),
        BackgroundColor3 = Theme.Panel,
        BackgroundTransparency = 1,
        Text = "UNSTUCK",
        TextTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Theme.Accent,
        AutoButtonColor = false,
        Visible = false,
        ZIndex = 100,
        Parent = Library.Gui,
    }, { Corner(8) })
    local unstuckStroke = Stroke(Theme.Accent, 1)
    unstuckStroke.Parent = unstuckButton
    local function showUnstuck(visible)
        if visible then
            unstuckButton.Visible = true
            Tween(unstuckButton, { BackgroundTransparency = 0, TextTransparency = 0 }, 0.22)
            Tween(unstuckStroke, { Transparency = 0.2 }, 0.22)
        else
            Tween(unstuckButton, { BackgroundTransparency = 1, TextTransparency = 1 }, 0.2)
            Tween(unstuckStroke, { Transparency = 1 }, 0.2)
            task.delay(0.22, function()
                if unstuckButton and unstuckButton.Parent and unstuckButton.TextTransparency >= 0.99 then
                    unstuckButton.Visible = false
                end
            end)
        end
    end

    local function agRelease(restore)
        ag.holding = false
        local savedPosition = ag.saved
        ag.saved = nil
        local _, _, root = getCharacterParts(LocalPlayer)
        if root then
            if restore and savedPosition then
                root.CFrame = savedPosition
            end
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
        showUnstuck(false)
    end
    Shared.antiGrabRelease = agRelease

    unstuckButton.MouseButton1Click:Connect(function()
        agRelease(true)
        antiStatus.Text = "Unstuck: вернул на прежнее место."
    end)

    local antiModule = antiSection:AddModule({ Name = "Anti Grab", Default = true, Callback = function(state)
        ag.enabled = state
        if not state and ag.holding then
            agRelease(true)
        end
        antiStatus.Text = state and "Anti Grab включён." or "Anti Grab выключен."
    end })
    antiModule:AddSlider({ Name = "Дистанция", Min = 5, Max = 100, Default = 30, Increment = 1, Suffix = " st",
        Callback = function(value) ag.distance = value end })
    antiModule:AddSlider({ Name = "Высота зависания", Min = 100, Max = 1000, Default = 300, Increment = 10,
        Callback = function(value) ag.height = value end })
    local antiDropdown = antiModule:AddDropdown({ Name = "Игрок", Options = {}, NoFlag = true })
    registerPlayerDropdown(antiDropdown)
    local antiList = antiModule:AddLabel({ Text = "Список слежения: пусто" })

    local function refreshAntiList()
        local names = {}
        for player in pairs(ag.targets) do
            names[#names + 1] = player.Name
        end
        table.sort(names, function(a, b) return a:lower() < b:lower() end)
        antiList:Set(#names == 0 and "Список слежения: пусто" or ("Список слежения (" .. #names .. "): " .. table.concat(names, ", ")))
    end
    antiModule:AddButton({ Name = "Добавить выбранного", Callback = function()
        local player = findPlayerByName(antiDropdown.Value)
        if player then ag.targets[player] = true end
        refreshAntiList()
    end })
    antiModule:AddButton({ Name = "Убрать выбранного", Callback = function()
        local player = findPlayerByName(antiDropdown.Value)
        if player then ag.targets[player] = nil end
        refreshAntiList()
    end })
    antiModule:AddButton({ Name = "Добавить всех", Callback = function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then ag.targets[player] = true end
        end
        refreshAntiList()
    end })
    antiModule:AddButton({ Name = "Очистить список", Callback = function()
        table.clear(ag.targets)
        refreshAntiList()
    end })
    antiModule:AddButton({ Name = "Unstuck (вернуть назад)", Callback = function()
        agRelease(true)
        antiStatus.Text = "Unstuck: вернул на прежнее место."
    end })
    antiSection:AddLabel({ Text = "Если выбранный игрок подходит ближе заданной дистанции, ты поднимаешься вверх и зависаешь." })

    keepConnection(Players.PlayerRemoving:Connect(function(player)
        ag.targets[player] = nil
        task.defer(refreshAntiList)
    end))

    keepConnection(RunService.Heartbeat:Connect(function()
        if not Library.Gui or not ag.enabled or Shared.antiGrabPaused then return end
        local _, humanoid, root = getCharacterParts(LocalPlayer)
        if not humanoid or humanoid.Health <= 0 or not root then return end
        if ag.holding then
            root.CFrame = CFrame.new(root.Position.X, ag.height, root.Position.Z)
                * (ag.saved and ag.saved.Rotation or CFrame.identity)
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            return
        end
        for target, enabled in pairs(ag.targets) do
            if enabled and target and target.Parent then
                local _, targetHumanoid, targetRoot = getCharacterParts(target)
                if targetHumanoid and targetHumanoid.Health > 0 and targetRoot
                    and (root.Position - targetRoot.Position).Magnitude <= ag.distance then
                    ag.saved = root.CFrame
                    ag.holding = true
                    root.CFrame = CFrame.new(root.Position.X, ag.height, root.Position.Z) * ag.saved.Rotation
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                    showUnstuck(true)
                    antiStatus.Text = "Сработал на " .. target.Name .. " — зависаю на высоте " .. ag.height .. "."
                    break
                end
            end
        end
    end))

    Library:AddPanicHook(function()
        ag.enabled = false
        ag.holding = false
    end)
end

--// ═════════════════════════ ДВИЖЕНИЕ ═════════════════════════
local function SetupMovement(tab)
    --// ТЕЛЕПОРТ
    local tpSection = tab:AddSection("Телепорт", "Left")
    local tpStatus = StatusProxy(tpSection:AddLabel({ Text = "Статус: готов" }))
    local tpDropdown = tpSection:AddDropdown({ Name = "Игрок", Options = {}, NoFlag = true })
    registerPlayerDropdown(tpDropdown)
    tpSection:AddButton({ Name = "Телепорт к выбранному игроку", Callback = function()
        local target = findPlayerByName(tpDropdown.Value)
        if not target then
            tpStatus.Text = "Статус: сначала выбери игрока"
            return
        end
        local _, humanoid, targetRoot = getCharacterParts(target)
        local _, _, myRoot = getCharacterParts(LocalPlayer)
        if not humanoid or humanoid.Health <= 0 or not targetRoot or not myRoot then
            tpStatus.Text = "Статус: персонаж недоступен"
            return
        end
        local success = pcall(function()
            myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
        end)
        tpStatus.Text = success and ("Статус: телепорт к " .. target.Name) or "Статус: телепорт не удался"
    end })

    local clickTPEnabled = false
    local clickTPModule
    clickTPModule = tpSection:AddModule({ Name = "Click TP", Callback = function(state)
        clickTPEnabled = state
        tpStatus.Text = state and "Статус: кликни в точку мира" or "Статус: Click TP выключен"
    end })
    tpSection:AddLabel({ Text = "Включи Click TP и кликни по месту в мире — один раз, потом он выключится." })

    keepConnection(UIS.InputBegan:Connect(function(input, processed)
        if processed or not clickTPEnabled then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local _, _, root = getCharacterParts(LocalPlayer)
            local target = Mouse.Hit
            if root and target then
                local success = pcall(function()
                    root.CFrame = CFrame.new(target.Position + Vector3.new(0, 3, 0))
                end)
                tpStatus.Text = success and "Статус: Click TP выполнен" or "Статус: телепорт не удался"
                clickTPEnabled = false
                clickTPModule:Set(false, true)
            end
        end
    end))

    --// FORCE RESET
    local FORCE_RESET_Y = -150
    local resetSection = tab:AddSection("Force reset", "Right")
    resetSection:AddLabel({ Text = "Телепортирует на выбранную высоту (X и Z те же). Останавливает фарм и на несколько секунд ставит на паузу Anti Void и Anti Grab, чтобы ничего не тянуло обратно." })
    resetSection:AddSlider({ Name = "Высота для TP (Y)", Min = -1000, Max = 1000, Default = -150, Increment = 10,
        Callback = function(value) FORCE_RESET_Y = value end })
    local resetBusy = false
    resetSection:AddButton({ Name = "Force reset", Callback = function()
        if resetBusy then return end
        local _, humanoid, root = getCharacterParts(LocalPlayer)
        if not humanoid or humanoid.Health <= 0 or not root then
            Library:Notify("Нет живого персонажа")
            return
        end
        resetBusy = true
        if Shared.farmStop then Shared.farmStop() end
        if Shared.killFarmStop then Shared.killFarmStop() end
        local savedAntiVoid = Shared.getAntiVoid and Shared.getAntiVoid()
        if Shared.setAntiVoid then Shared.setAntiVoid(false) end
        Shared.antiGrabPaused = true
        if Shared.antiGrabRelease then Shared.antiGrabRelease(false) end
        local myChar = LocalPlayer.Character
        root.CFrame = CFrame.new(root.Position.X, FORCE_RESET_Y, root.Position.Z)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        Library:Notify("Force reset: Y = " .. FORCE_RESET_Y)
        task.spawn(function()
            local t0 = os.clock()
            while os.clock() - t0 < 6 do
                local _, h, r = getCharacterParts(LocalPlayer)
                if LocalPlayer.Character ~= myChar or not h or h.Health <= 0 or not r then break end
                task.wait(0.2)
            end
            if Shared.setAntiVoid and savedAntiVoid ~= nil then Shared.setAntiVoid(savedAntiVoid) end
            Shared.antiGrabPaused = false
            resetBusy = false
        end)
    end })
end

--// ═════════════════════════ РАЗНОЕ ═════════════════════════
local function SetupMisc(tab)
    --// ЗАЩИТА
    local protectSection = tab:AddSection("Защита", "Left")

    local av = { enabled = true, threshold = -130, height = 200 }
    local antiVoidModule
    antiVoidModule = protectSection:AddModule({ Name = "Anti Void", Default = true, Callback = function(state)
        av.enabled = state
    end })
    antiVoidModule:AddSlider({ Name = "Порог Y", Min = -500, Max = -50, Default = -130, Increment = 5,
        Callback = function(value) av.threshold = value end })
    antiVoidModule:AddSlider({ Name = "Высота возврата", Min = 50, Max = 500, Default = 200, Increment = 10,
        Callback = function(value) av.height = value end })
    Shared.getAntiVoid = function() return av.enabled end
    Shared.setAntiVoid = function(value)
        av.enabled = value and true or false
        antiVoidModule:Set(av.enabled, true) -- только картинка, без повторного вызова
    end
    keepConnection(RunService.Heartbeat:Connect(function()
        if not av.enabled then return end
        local _, humanoid, root = getCharacterParts(LocalPlayer)
        if humanoid and humanoid.Health > 0 and root and root.Position.Y <= av.threshold then
            local position = root.Position
            root.CFrame = CFrame.new(position.X, av.height, position.Z)
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
    end))

    local antiAfkConnection = nil
    protectSection:AddModule({ Name = "Anti-AFK", Callback = function(state)
        if antiAfkConnection then
            antiAfkConnection:Disconnect()
            antiAfkConnection = nil
        end
        if state then
            antiAfkConnection = LocalPlayer.Idled:Connect(function()
                pcall(function()
                    local VirtualUser = game:GetService("VirtualUser")
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new(0, 0))
                end)
            end)
        end
    end })
    Library:AddPanicHook(function()
        av.enabled = false
        if antiAfkConnection then
            antiAfkConnection:Disconnect()
            antiAfkConnection = nil
        end
    end)

    --// КАРТЫ
    local mapSection = tab:AddSection("Карты", "Right")
    local mapLabel = mapSection:AddLabel({ Text = "Текущая карта: неизвестна" })
    local currentMapKey = nil

    --// Телепорт на карту по координатам (не через teleportRequest)
    local mapOptions, mapKeyByName = {}, {}
    for _, key in ipairs(MAP_ORDER) do
        mapOptions[#mapOptions + 1] = MAPS[key].name
        mapKeyByName[MAPS[key].name] = key
    end
    local function teleportToMap(key)
        local info = key and MAPS[key]
        if not info then
            Library:Notify("Сначала выбери карту")
            return
        end
        local _, humanoid, root = getCharacterParts(LocalPlayer)
        if not humanoid or humanoid.Health <= 0 or not root then
            Library:Notify("Нет живого персонажа")
            return
        end
        root.CFrame = CFrame.new(info.pos)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        Library:Notify("Телепорт: " .. info.name)
    end
    local mapDropdown = mapSection:AddDropdown({ Name = "Карта", Options = mapOptions, NoFlag = true })
    mapSection:AddButton({ Name = "Телепорт на выбранную карту", Callback = function()
        teleportToMap(mapKeyByName[mapDropdown.Value])
    end })
    mapSection:AddButton({ Name = "Телепорт на текущую карту", Callback = function()
        if currentMapKey then
            teleportToMap(currentMapKey)
        else
            Library:Notify("Текущая карта ещё не известна — дождись смены карты")
        end
    end })
    local mapNotifyEnabled = true
    local mapNotifyModule = mapSection:AddModule({ Name = "Уведомления о картах", Default = true, Callback = function(state)
        mapNotifyEnabled = state
    end })
    AddNotifyControls(mapNotifyModule, "map")
    do
        local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
        local mapEvent = eventsFolder and eventsFolder:FindFirstChild("mapChange")
        if mapEvent and mapEvent:IsA("RemoteEvent") then
            keepConnection(mapEvent.OnClientEvent:Connect(function(mapId)
                local key = tostring(mapId)
                local name = (MAPS[key] and MAPS[key].name) or ("Map " .. key)
                currentMapKey = key
                mapLabel:Set("Текущая карта: " .. name .. "  (" .. os.date("%H:%M:%S") .. ")")
                if mapNotifyEnabled then
                    Library:Notify("Смена карты: " .. name, 5, "map")
                end
                for _, hook in ipairs(Shared.mapChangeHooks) do
                    task.spawn(hook, name, key)
                end
            end))
        else
            mapLabel:Set("Текущая карта: Events.mapChange не найден")
        end
    end

    --// КЛЮЧ
    local keySection = tab:AddSection("Ключ", "Left")
    keySection:AddButton({ Name = "Забыть сохранённый ключ", Callback = function()
        DeleteFile(CONFIG.KeyFile)
        SaveFile(CONFIG.KeyFile, "") -- если у экзекутора нет delfile, хотя бы очищаем
        Library:Notify("Сохранённый ключ удалён")
    end })
end

--// ═════════════════════════ ИГРОК (баунти) ═════════════════════════
local function SetupPlayer(tab)
    local farmSection = tab:AddSection("Bounty Farm", "Left")
    local bountyStatusLabel = farmSection:AddLabel({ Text = "Статус: выключен" })
    local wantedSection = tab:AddSection("Wanted List Farm", "Right")
    local wantedStatusLabel = wantedSection:AddLabel({ Text = "Статус: выключен" })

    --// Одна общая "машина" фарма на две независимые функции: Bounty Farm и Wanted List Farm.
    --// Они включаются по отдельности или вместе и не конфликтуют: движок один, он берёт цели из обоих списков.
    local farmSources = { bounty = false, wanted = false }
    -- статус движка показывается у тех функций, которые сейчас включены
    local farmStatus = setmetatable({}, {
        __newindex = function(_, key, value)
            if key ~= "Text" then return end
            if farmSources.bounty then bountyStatusLabel:Set(value) end
            if farmSources.wanted then wantedStatusLabel:Set(value) end
        end,
    })
    local farmMinInput = { Text = "1000" }     -- Bounty Farm: минимум баунти у цели
    local farmBatchInput = { Text = "5" }      -- Bounty Farm: сбросов до депозита
    local wantedMinInput = { Text = "100" }    -- Wanted List Farm: минимум награды
    local wantedBatchInput = { Text = "5" }    -- Wanted List Farm: сбросов до депозита
    local farmBountyModule = nil               -- создаются ниже
    local farmWantedModule = nil
    local wantedClaimed, wantedClaimedTotal = 0, 0
    local farmMapChanged = false -- карта сменилась: фарм должен сразу уйти на новую
    local farmMapKey = nil       -- id новой карты (для координат)
    local bountyNotifyEnabled = true

    --// Wanted: награда лежит в атрибуте "WantedBounty" у игроков ЭТОГО сервера (глобальная доска не считается)
    local function wantedRead()
        local result = {}
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= LocalPlayer then
                local amount = tonumber(pl:GetAttribute("WantedBounty")) or 0
                if amount > 0 then
                    result[pl] = { amount = amount }
                end
            end
        end
        return result
    end

    local function wantedDescribe()
        local list = {}
        for pl, entry in pairs(wantedRead()) do
            list[#list + 1] = { name = pl.Name, amount = entry.amount }
        end
        table.sort(list, function(a, b) return a.amount > b.amount end)
        if #list == 0 then
            return "Wanted (этот сервер): сейчас ни у кого нет награды"
        end
        local parts = {}
        for _, item in ipairs(list) do
            parts[#parts + 1] = string.format("%s — %d B$", item.name, item.amount)
        end
        return "Wanted (этот сервер): " .. table.concat(parts, " | ")
    end

    ---------------------------------------------------------------- ЛОГИКА ФАРМА
    local FARM_KILL_Y = -100
    local FARM_WAIT_AFTER_DEPOSIT = 5
    local FARM_MAX_ATTEMPTS = 8   -- grab retries per target before moving on
    local FARM_RESPAWN_WAIT = 4   -- seconds to wait after you respawn
    local FARM_HIDE_Y = 5000      -- hover this high while there is nobody to throw out
    local FARM_DEPOSIT_COOLDOWN = 100 -- the game's clan deposit cooldown, seconds
    local farmLastDepositAt = nil  -- os.clock() of the last successful deposit
    local FARM_CARRY_DISTANCE = 15 -- target closer than this to you = you are holding him
    local farmRunning = false
    local farmRunId = 0
    local farmCooldown = {} -- [player] = os.clock() until which it is skipped
    local farmSavedAntiVoid = nil
    local farmFreezeCF = nil
    local farmFreezeConn = nil
    --// Freeze in the air by re-teleporting every frame (no Anchored, no Anti Void)
    local function farmFreeze(cf)
        farmFreezeCF = cf
        if farmFreezeConn then return end
        farmFreezeConn = RunService.Heartbeat:Connect(function()
            if not farmFreezeCF then return end
            local _, hum, root = getCharacterParts(LocalPlayer)
            if root and hum and hum.Health > 0 then
                root.CFrame = farmFreezeCF
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end
        end)
    end
    local function farmUnfreeze()
        farmFreezeCF = nil
        if farmFreezeConn then
            farmFreezeConn:Disconnect()
            farmFreezeConn = nil
        end
    end
    local function farmGetBounty(player)
        local stats = player:FindFirstChild("leaderstats")
        local value = stats and stats:FindFirstChild("Bounty")
        return value and tonumber(value.Value) or 0
    end
    --// Цели из обеих функций. Wanted (награда за голову) в приоритете, потом глобальный баунти.
    --// Возвращает: игрок, сумма, "wanted" | "bounty"
    local function farmPickTarget()
        local now = os.clock()
        local function usable(player)
            if player == LocalPlayer or (farmCooldown[player] or 0) >= now then return false end
            local _, humanoid, root = getCharacterParts(player)
            return humanoid ~= nil and humanoid.Health > 0 and root ~= nil
        end
        if farmSources.wanted then
            local minAmount = tonumber(wantedMinInput.Text) or 0
            local best, bestAmount = nil, -1
            for player, entry in pairs(wantedRead()) do
                if usable(player) and entry.amount >= minAmount and entry.amount > bestAmount then
                    best, bestAmount = player, entry.amount
                end
            end
            if best then return best, bestAmount, "wanted" end
        end
        if farmSources.bounty then
            local minAmount = tonumber(farmMinInput.Text) or 0
            local best, bestAmount = nil, -1
            for _, player in ipairs(Players:GetPlayers()) do
                if usable(player) then
                    local amount = farmGetBounty(player)
                    if amount >= minAmount and amount > bestAmount then
                        best, bestAmount = player, amount
                    end
                end
            end
            if best then return best, bestAmount, "bounty" end
        end
        return nil
    end
    --// Are you holding this player right now?
    --// True if a weld/constraint links your character with his, or he is physically right next to you.
    --// (Call it AFTER you moved away from where you grabbed him - otherwise "next to you" is always true.)
    local function farmIsHolding(target)
        local myChar = LocalPlayer.Character
        local tChar = target and target.Character
        if not myChar or not tChar then return false end
        local _, _, myRoot = getCharacterParts(LocalPlayer)
        local _, _, tRoot = getCharacterParts(target)
        if not myRoot or not tRoot then return false end
        if (tRoot.Position - myRoot.Position).Magnitude <= FARM_CARRY_DISTANCE then
            return true
        end
        local function linkedBetween(a, b)
            if not a or not b then return false end
            return (a:IsDescendantOf(myChar) and b:IsDescendantOf(tChar))
                or (a:IsDescendantOf(tChar) and b:IsDescendantOf(myChar))
        end
        for _, container in ipairs({myChar, tChar}) do
            for _, d in ipairs(container:GetDescendants()) do
                if d:IsA("Weld") or d:IsA("WeldConstraint") or d:IsA("Motor6D") then
                    if linkedBetween(d.Part0, d.Part1) then return true end
                elseif d:IsA("Constraint") then
                    local a0 = d.Attachment0 and d.Attachment0.Parent
                    local a1 = d.Attachment1 and d.Attachment1.Parent
                    if linkedBetween(a0, a1) then return true end
                end
            end
        end
        return false
    end
    local function farmRelease(arm, target)
        -- The script has no known release remote, so try the most likely variants.
        local _, _, myRoot = getCharacterParts(LocalPlayer)
        local _, _, targetRoot = getCharacterParts(target)
        if not myRoot or not targetRoot then return end
        local events = ReplicatedStorage:FindFirstChild("Events")
        if not events then return end
        local grab = events:FindFirstChild("Grab")
        if grab and grab:IsA("RemoteEvent") then
            for _, action in ipairs({"Release", "Drop", "Throw", "Let go", "Ungrab"}) do
                pcall(function()
                    grab:FireServer(arm, action, targetRoot.Position, CFrame.lookAt(targetRoot.Position, myRoot.Position))
                end)
            end
        end
        for _, name in ipairs({"Release", "Drop", "Ungrab", "Throw"}) do
            local remote = events:FindFirstChild(name)
            if remote and remote:IsA("RemoteEvent") then
                pcall(function() remote:FireServer() end)
            end
        end
    end
    --// Остановка самого движка (модули уже выключены)
    local function farmShutdown()
        farmRunning = false
        farmRunId = farmRunId + 1
        farmUnfreeze()
        if farmSavedAntiVoid ~= nil then
            Shared.setAntiVoid(farmSavedAntiVoid)
            farmSavedAntiVoid = nil
        end
    end
    --// Полная остановка: выключает обе функции
    local function farmStop()
        farmSources.bounty, farmSources.wanted = false, false
        if farmBountyModule then farmBountyModule:Set(false, true) end
        if farmWantedModule then farmWantedModule:Set(false, true) end
        bountyStatusLabel:Set("Статус: остановлен")
        wantedStatusLabel:Set("Статус: остановлен")
        farmShutdown()
    end
    local function farmAlive(runId)
        return farmRunning and farmRunId == runId and Library.Gui and Library.Gui.Parent
    end
    --// One deposit attempt. Returns ok (server answered true), text.
    local function farmTryDeposit(amount, source)
        local events = ReplicatedStorage:FindFirstChild("Events")
        local deposit = events and events:FindFirstChild("depositClanBounty")
        if not deposit then return false, "depositClanBounty NOT FOUND" end
        local res = table.pack(pcall(function() return deposit:InvokeServer(amount) end))
        if not res[1] then return false, "deposit error: " .. tostring(res[2]) end
        local parts = {}
        for i = 2, res.n do parts[#parts + 1] = tostring(res[i]) end
        local text = table.concat(parts, ", ")
        if res[2] == true then
            if source == "Auto" and Shared.historyAdd then
                Shared.historyAdd("auto", "Депозит", amount, "deposit")
            end
            return true, "server: true"
        end
        return false, "rejected (cooldown?) reply: " .. (text ~= "" and text or "none")
    end
    local function farmHideHigh()
        local _, hum, root = getCharacterParts(LocalPlayer)
        if root and hum and hum.Health > 0 then
            local pos = root.Position
            farmFreeze(CFrame.new(pos.X, FARM_HIDE_Y, pos.Z))
            return true
        end
        return false
    end
    local function farmWaitRespawn(runId)
        while farmAlive(runId) do
            local _, hum, root = getCharacterParts(LocalPlayer)
            if hum and hum.Health > 0 and root then break end
            farmStatus.Text = "Waiting for respawn..."
            task.wait(0.3)
        end
        for i = FARM_RESPAWN_WAIT, 1, -1 do
            if not farmAlive(runId) then return end
            farmStatus.Text = "Waiting " .. i .. "s..."
            task.wait(1)
        end
    end
    --// Карта сменилась: снимаем зависание и телепортируемся на новую карту ПО КООРДИНАТАМ.
    --// Если координат этой карты нет — запасной вариант: Events.teleportRequest.
    local function farmGoToNewMap(runId)
        farmUnfreeze()
        local mapInfo = farmMapKey and MAPS[farmMapKey]
        if mapInfo then
            local _, hum, root = getCharacterParts(LocalPlayer)
            if not hum or hum.Health <= 0 or not root then return end -- умер: основной цикл дождётся респавна
            farmStatus.Text = "Карта сменилась — телепорт на " .. mapInfo.name
            local target = CFrame.new(mapInfo.pos)
            root.CFrame = target
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            -- пару секунд стоим на точке, пока карта прогрузится (чтобы не провалиться)
            farmFreeze(target)
            local t0 = os.clock()
            while farmAlive(runId) and os.clock() - t0 < 2 do
                local _, h, r = getCharacterParts(LocalPlayer)
                if not h or h.Health <= 0 or not r then
                    farmUnfreeze()
                    return
                end
                if farmMapChanged then break end -- пришла ещё одна смена карты
                task.wait(0.1)
            end
            farmUnfreeze()
            farmStatus.Text = "Телепорт на карту выполнен: " .. mapInfo.name
            return
        end
        local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
        local tpRequest = eventsFolder and eventsFolder:FindFirstChild("teleportRequest")
        local moved = false
        for attempt = 1, 3 do
            if not farmAlive(runId) then return end
            local _, hum, root = getCharacterParts(LocalPlayer)
            if not hum or hum.Health <= 0 or not root then return end -- умер: основной цикл дождётся респавна
            local posBefore = root.Position
            farmStatus.Text = string.format("Карта сменилась — teleportRequest (%d/3)", attempt)
            if tpRequest then
                pcall(function() tpRequest:FireServer() end)
            end
            local t0 = os.clock()
            while farmAlive(runId) and os.clock() - t0 < 3 do
                local _, h, r = getCharacterParts(LocalPlayer)
                if not h or h.Health <= 0 or not r then return end
                if (r.Position - posBefore).Magnitude > 30 then
                    moved = true
                    break
                end
                task.wait(0.2)
            end
            if moved then break end
        end
        if not farmAlive(runId) then return end
        if moved then
            farmStatus.Text = "Телепорт на новую карту выполнен"
        else
            -- teleportRequest ничего не сделал: прячемся высоко, чтобы не упасть
            farmHideHigh()
            farmStatus.Text = tpRequest and "teleportRequest не сработал — жду на высоте"
                or "teleportRequest не найден — жду на высоте"
        end
    end

    --// Депозит движка: записываем в историю тех функций, у которых были сбросы (сумма делится по числу сбросов)
    local function farmRecordDeposit(amount, killsNow)
        if not Shared.historyAdd then return end
        local b, w = killsNow.bounty, killsNow.wanted
        local total = b + w
        if total <= 0 then
            Shared.historyAdd("bounty", "Депозит", amount, "deposit")
            return
        end
        local bountyShare = math.floor(amount * b / total)
        if b > 0 then
            Shared.historyAdd("bounty", string.format("Депозит (сбросов: %d)", b), bountyShare, "deposit")
        end
        if w > 0 then
            Shared.historyAdd("wanted", string.format("Депозит (сбросов: %d)", w), amount - bountyShare, "deposit")
        end
    end

    local function farmDepositReady()
        return farmLastDepositAt == nil or os.clock() - farmLastDepositAt >= FARM_DEPOSIT_COOLDOWN
    end
    local function farmLoop(runId)
        local kills = { bounty = 0, wanted = 0 } -- сбросы с последнего депозита по функциям
        local noTargetSince = nil
        local nextDepositTry = 0
        while farmAlive(runId) do
            -- dead? wait for respawn + 4s, then go on
            local _, myHumanoid, myRoot = getCharacterParts(LocalPlayer)
            if not myHumanoid or myHumanoid.Health <= 0 or not myRoot then
                farmUnfreeze()
                farmWaitRespawn(runId)
                continue
            end

            if farmMapChanged then
                farmMapChanged = false
                farmGoToNewMap(runId)
                continue
            end
            local bountyBatch = math.max(1, math.floor(tonumber(farmBatchInput.Text) or 5))
            local wantedBatch = math.max(1, math.floor(tonumber(wantedBatchInput.Text) or 5))
            -- ALWAYS look for someone who can be thrown out
            local target, targetBounty, targetSource = farmPickTarget()
            if target then
                noTargetSince = nil
            else
                noTargetSince = noTargetSince or os.clock()
            end
            local idle = noTargetSince ~= nil and os.clock() - noTargetSince >= 5
            --// DEPOSIT: only when the 100s cooldown is over and there is something to deposit
            local totalKills = kills.bounty + kills.wanted
            local batchReached = (farmSources.bounty and kills.bounty >= bountyBatch)
                or (farmSources.wanted and kills.wanted >= wantedBatch)
            if totalKills > 0 and farmDepositReady() and os.clock() >= nextDepositTry and (batchReached or idle) then
                if not farmFreezeCF then farmHideHigh() end
                task.wait(1) -- let the server add the bounty from the last kill
                local myBounty = math.floor(farmGetBounty(LocalPlayer))
                if myBounty <= 0 then
                    farmStatus.Text = "Your bounty is 0, nothing to deposit"
                    kills.bounty, kills.wanted = 0, 0
                else
                    local ok, text = farmTryDeposit(myBounty, "Farm")
                    if ok then
                        farmLastDepositAt = os.clock()
                        farmRecordDeposit(myBounty, kills)
                        kills.bounty, kills.wanted = 0, 0
                        local depositText = string.format("deposited %d B, %s", myBounty, text)
                        for i = FARM_WAIT_AFTER_DEPOSIT, 1, -1 do
                            if not farmAlive(runId) then break end
                            farmStatus.Text = depositText .. " | waiting " .. i .. "s..."
                            task.wait(1)
                        end
                        if not farmAlive(runId) then break end
                        -- reset with the game's teleportRequest remote (no death), then wait 4s
                        farmStatus.Text = "teleportRequest..."
                        farmUnfreeze()
                        local _, _, rootBefore = getCharacterParts(LocalPlayer)
                        local posBefore = rootBefore and rootBefore.Position
                        local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
                        local tpRequest = eventsFolder and eventsFolder:FindFirstChild("teleportRequest")
                        if tpRequest then
                            pcall(function() tpRequest:FireServer() end)
                        end
                        local moved = false
                        local t0 = os.clock()
                        while farmAlive(runId) and os.clock() - t0 < 5 do
                            local _, h, r = getCharacterParts(LocalPlayer)
                            if not h or h.Health <= 0 or not r then break end
                            if posBefore and (r.Position - posBefore).Magnitude > 30 then
                                moved = true
                                break
                            end
                            task.wait(0.2)
                        end
                        if not moved and farmAlive(runId) then
                            -- teleportRequest did nothing: stay safe up high instead of falling
                            local _, h2 = getCharacterParts(LocalPlayer)
                            if h2 and h2.Health > 0 then farmHideHigh() end
                            farmStatus.Text = tpRequest and "teleportRequest did not move you - hiding high"
                                or "teleportRequest NOT FOUND - hiding high"
                        end
                        farmWaitRespawn(runId)
                    else
                        -- refused (maybe an older cooldown): keep hunting, try again in 5s
                        nextDepositTry = os.clock() + 5
                        farmStatus.Text = "Deposit refused, retry in 5s - " .. text
                    end
                end
                continue
            end
            --// NOBODY to throw out: hang high and keep checking
            if not target then
                local cd = farmLastDepositAt and math.max(0, math.ceil(FARM_DEPOSIT_COOLDOWN - (os.clock() - farmLastDepositAt))) or 0
                farmStatus.Text = string.format("No targets, hiding high | kills %d | deposit cd %ds",
                    totalKills, cd)
                if not farmFreezeCF or math.abs(farmFreezeCF.Position.Y - FARM_HIDE_Y) > 1 then
                    farmHideHigh()
                end
                task.wait(0.5)
                continue
            end
            --// SOMEONE IS THERE: grab him and throw him out
            local remote = getGrabRemote()
            if not remote then
                farmStatus.Text = "Status: grab remote not found"
                task.wait(1)
                continue
            end
            -- go to the target, grab, hang at Y=-100, check that he is really in your hands.
            -- If not - try again (you stay frozen between attempts, so you never fall and die).
            local held, arm = false, nil
            local died = false
            for attempt = 1, FARM_MAX_ATTEMPTS do
                if not farmAlive(runId) or farmMapChanged then break end
                local _, myHum, myRoot2 = getCharacterParts(LocalPlayer)
                if not myHum or myHum.Health <= 0 or not myRoot2 then
                    died = true
                    break
                end
                local _, tHum, tRoot = getCharacterParts(target)
                if not tHum or tHum.Health <= 0 or not tRoot then break end -- target died / left
                arm = getGrabPart(myHum.Parent)
                if not arm then break end
                farmUnfreeze()
                farmStatus.Text = string.format("[%s] Grabbing %s (%d B) - attempt %d/%d | kills %d",
                    targetSource, target.Name, targetBounty, attempt, FARM_MAX_ATTEMPTS, totalKills)
                myRoot2.CFrame = tRoot.CFrame * CFrame.new(0, 0, 2)
                task.wait(0.15)
                pcall(function()
                    remote:FireServer(
                        getGrabPart(target.Character) or arm,
                        "Grab",
                        tRoot.Position,
                        CFrame.lookAt(tRoot.Position, myRoot2.Position)
                    )
                end)
                task.wait(0.35)
                local pos = myRoot2.Position
                farmFreeze(CFrame.new(pos.X, FARM_KILL_Y, pos.Z) * CFrame.Angles(math.rad(90), 0, 0)) -- lying horizontally
                task.wait(0.5)
                if farmIsHolding(target) then
                    held = true
                    break
                end
            end
            if farmMapChanged then continue end -- обработается в начале цикла
            if died then
                farmUnfreeze()
                continue
            end
            if not farmAlive(runId) then break end
            if not held then
                farmCooldown[target] = os.clock() + 8
                farmStatus.Text = "Could not grab " .. target.Name .. " - next target"
                task.wait(0.3)
                continue
            end
            -- drop him (retry until he is no longer in your hands)
            farmStatus.Text = "Throwing out " .. target.Name
            local released = false
            for _ = 1, 4 do
                farmRelease(arm, target)
                task.wait(0.4)
                local _, targetHumanoid = getCharacterParts(target)
                if not farmIsHolding(target) or not targetHumanoid or targetHumanoid.Health <= 0 then
                    released = true
                    break
                end
            end
            farmCooldown[target] = os.clock() + (released and 3 or 8)
            if released then
                kills[targetSource] = kills[targetSource] + 1
                if Shared.historyAdd then
                    Shared.historyAdd(targetSource, string.format("Сброшен %s (%d B)", target.Name, targetBounty), nil, "kill")
                end
            else
                farmStatus.Text = "Could not drop " .. target.Name .. " - next target"
            end
        end
        if farmRunId == runId then farmUnfreeze() end
    end

    ---------------------------------------------------------------- /ЛОГИКА ФАРМА

    Shared.farmStop = function()
        if farmRunning then farmStop() end
    end
    table.insert(Shared.mapChangeHooks, function(_, key)
        if farmRunning then
            farmMapChanged = true
            farmMapKey = key
            farmStatus.Text = "Карта сменилась — иду на новую"
        end
    end)

    --// Движок стартует, когда включена хоть одна функция, и останавливается, когда выключены обе
    local function farmApplySources()
        local anyEnabled = farmSources.bounty or farmSources.wanted
        if anyEnabled and not farmRunning then
            if Shared.killFarmStop then Shared.killFarmStop() end -- Kill Farm и этот фарм вместе не работают
            farmRunning = true
            farmRunId = farmRunId + 1
            farmSavedAntiVoid = Shared.getAntiVoid()
            Shared.setAntiVoid(false) -- иначе Anti Void вытащит тебя с Y = -100
            farmMapChanged = false
            task.spawn(farmLoop, farmRunId)
        elseif not anyEnabled and farmRunning then
            farmShutdown()
        end
    end

    --// ───────────── BOUNTY FARM ─────────────
    farmBountyModule = farmSection:AddModule({ Name = "Bounty Farm", Callback = function(state)
        farmSources.bounty = state
        bountyStatusLabel:Set(state and "Статус: работает" or "Статус: выключен")
        farmApplySources()
    end })
    farmBountyModule:AddTextbox({ Name = "Мин. баунти", Default = "1000", Callback = function(text)
        farmMinInput.Text = text
    end })
    farmBountyModule:AddTextbox({ Name = "Сбросов до депозита", Default = "5", Callback = function(text)
        farmBatchInput.Text = text
    end })
    farmSection:AddLabel({ Text = "Бьёт игроков с большим глобальным баунти (leaderstats). Схватить → Y = -100 → выбросить → депозит (кулдаун 100 с) → teleportRequest. Если целей нет, зависаешь на Y = 5000." })

    --// ───────────── WANTED LIST FARM ─────────────
    farmWantedModule = wantedSection:AddModule({ Name = "Wanted List Farm", Callback = function(state)
        farmSources.wanted = state
        wantedStatusLabel:Set(state and "Статус: работает" or "Статус: выключен")
        farmApplySources()
    end })
    farmWantedModule:AddTextbox({ Name = "Мин. wanted-награда", Default = "100", Callback = function(text)
        wantedMinInput.Text = text
    end })
    farmWantedModule:AddTextbox({ Name = "Сбросов до депозита", Default = "5", Callback = function(text)
        wantedBatchInput.Text = text
    end })
    local wantedListLabel = farmWantedModule:AddLabel({ Text = "Wanted: нажми «Показать wanted»" })
    local wantedClaimLabel = farmWantedModule:AddLabel({ Text = "Wanted claims: 0 (+0 B)" })
    farmWantedModule:AddToggle({ Name = "Уведомлять о claimed", Default = true, Callback = function(value)
        bountyNotifyEnabled = value
    end })
    AddNotifyControls(farmWantedModule, "bounty")
    farmWantedModule:AddButton({ Name = "Показать wanted", Callback = function()
        wantedListLabel:Set(wantedDescribe())
    end })
    wantedSection:AddLabel({ Text = "Бьёт игроков этого сервера, на которых кто-то поставил награду (Wanted). Если включены обе функции, Wanted в приоритете, а депозит общий." })

    task.spawn(function() -- список wanted обновляется сам, пока функция включена
        while Library.Gui do
            task.wait(2)
            if farmSources.wanted and Library.Gui then
                wantedListLabel:Set(wantedDescribe())
            end
        end
    end)

    --// Events.BountyNotice: ("claimed", {victim = name, amount = n}) приходит тебе после убийства
    do
        local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
        local noticeEvent = eventsFolder and eventsFolder:FindFirstChild("BountyNotice")
        if noticeEvent and noticeEvent:IsA("RemoteEvent") then
            keepConnection(noticeEvent.OnClientEvent:Connect(function(kind, data)
                if kind == "claimed" and type(data) == "table" then
                    local victim = tostring(data.victim or "?")
                    local amount = tonumber(data.amount) or 0
                    wantedClaimed = wantedClaimed + 1
                    wantedClaimedTotal = wantedClaimedTotal + amount
                    for _, pl in ipairs(Players:GetPlayers()) do
                        if pl.Name == victim or pl.DisplayName == victim then
                            farmCooldown[pl] = os.clock() + 30 -- он уже обработан, не гоняемся сразу снова
                        end
                    end
                    wantedClaimLabel:Set(string.format("Wanted claims: %d (+%d B)", wantedClaimed, wantedClaimedTotal))
                    if Shared.historyAdd then
                        Shared.historyAdd("wanted", "Claimed: " .. victim, amount, "claim")
                    end
                    if bountyNotifyEnabled then
                        Library:Notify(string.format("Bounty claimed: %s  +%d", victim, amount), 4, "bounty")
                    end
                end
            end))
        end
    end

    --// ───────────── АВТО-ДЕПОЗИТ ─────────────
    local depositSection = tab:AddSection("Авто-депозит", "Right")
    local autoDepStatus = StatusProxy(depositSection:AddLabel({ Text = "Статус: выключен" }))
    local autoDepAmountInput = { Text = "100" }
    local autoDepIntervalInput = { Text = "5" }
    local autoDepRunning = false
    local autoDepRunId = 0
    local autoDepModule = nil

    local function autoDepStop()
        autoDepRunning = false
        autoDepRunId = autoDepRunId + 1
        if autoDepModule then autoDepModule:Set(false, true) end
        autoDepStatus.Text = "Статус: остановлен"
    end

    autoDepModule = depositSection:AddModule({ Name = "Auto Deposit", Callback = function(state)
        if not state then
            if autoDepRunning then autoDepStop() end
            return
        end
        if autoDepRunning then return end
        local amount = math.floor(tonumber(autoDepAmountInput.Text) or 0)
        if amount <= 0 then
            autoDepStatus.Text = "Статус: укажи сумму больше 0"
            autoDepModule:Set(false, true)
            return
        end
        autoDepRunning = true
        autoDepRunId = autoDepRunId + 1
        local runId = autoDepRunId
        autoDepStatus.Text = "Статус: работает"
        task.spawn(function()
            local function alive()
                return autoDepRunning and autoDepRunId == runId and Library.Gui and Library.Gui.Parent
            end
            while alive() do
                -- значения читаются каждый круг, их можно менять на ходу
                local amountNow = math.floor(tonumber(autoDepAmountInput.Text) or 0)
                local intervalNow = math.max(5, tonumber(autoDepIntervalInput.Text) or 5)
                local myBounty = math.floor(farmGetBounty(LocalPlayer))
                local events = ReplicatedStorage:FindFirstChild("Events")
                local deposit = events and events:FindFirstChild("depositClanBounty")
                if not deposit then
                    autoDepStatus.Text = "depositClanBounty не найден"
                elseif amountNow <= 0 then
                    autoDepStatus.Text = "Укажи сумму больше 0"
                elseif myBounty < amountNow then
                    autoDepStatus.Text = string.format("Не хватает баунти: есть %d, нужно %d", myBounty, amountNow)
                else
                    local ok, text = farmTryDeposit(amountNow, "Auto")
                    if ok then farmLastDepositAt = os.clock() end
                    autoDepStatus.Text = string.format("%s %d B, %s (%s)",
                        ok and "Депозит:" or "Не прошло:", amountNow, text, os.date("%H:%M:%S"))
                end
                local waited = 0
                while alive() and waited < intervalNow do
                    task.wait(0.25)
                    waited = waited + 0.25
                end
            end
        end)
    end })
    autoDepModule:AddTextbox({ Name = "Сумма", Default = "100", Callback = function(text)
        autoDepAmountInput.Text = text
    end })
    autoDepModule:AddTextbox({ Name = "Раз в N секунд (мин. 5)", Default = "5", Callback = function(text)
        autoDepIntervalInput.Text = text
    end })
    depositSection:AddLabel({ Text = "Кулдаун депозита в игре 100 секунд: чаще раза в 100 с сервер откажет." })

    Library:AddPanicHook(function()
        if farmRunning then farmStop() end
        autoDepRunning = false
        autoDepRunId = autoDepRunId + 1
        farmUnfreeze()
    end)
end

--// ═════════════════════════ ВИЗУАЛЫ ═════════════════════════
local function SetupVisuals(tab)
    --// ИНТЕРФЕЙС (раньше был в настройках)
    local uiSection = tab:AddSection("Интерфейс", "Left")
    Library.WatermarkVisible = true
    uiSection:AddToggle({ Name = "Оверлей слева сверху", Default = true, NoFlag = true, Callback = function(value)
        Library.WatermarkVisible = value
        if Library.Watermark then
            Library.Watermark.Visible = true
            Tween(Library.Watermark, { GroupTransparency = value and 0 or 1 }, 0.25)
        end
    end })
    uiSection:AddDropdown({ Name = "Положение оверлея", Options = { "Слева", "Центр" }, NoFlag = true,
        Default = (Library.WatermarkStyle == "center") and "Центр" or "Слева", Callback = function(value)
            Library:SetWatermarkStyle(value == "Центр" and "center" or "left")
        end })
    uiSection:AddLabel({ Text = "«Слева» — лого, ник, FPS, пинг, время, позиция и скорость. «Центр» — полоска по центру без иконок: ник, FPS, пинг, позиция, скорость (без времени и TPS)." })

    --// УВЕДОМЛЕНИЯ (общий канал)
    local notifySection = tab:AddSection("Уведомления", "Left")
    notifySection:AddLabel({ Text = "Общие уведомления (конфиги, сервер и т.д.). Нажми «Переместить» и перетащи окошко туда, где они должны появляться. У смены карты и наград свои настройки в их модулях." })
    AddNotifyControls(notifySection, "general")

    --// СТРЕЛКИ
    local arrowSection = tab:AddSection("Стрелки", "Right")
    local cfg = {
        enabled = false,
        size = 26,
        radius = 240,
        smooth = 14,
        showDistance = true,
        onlyOffscreen = false,
    }
    local arrowModule = arrowSection:AddModule({ Name = "Стрелки на игроков", Callback = function(state)
        cfg.enabled = state
    end })
    arrowModule:AddSlider({ Name = "Размер стрелок", Min = 12, Max = 60, Default = 26, Increment = 1, Suffix = " px",
        Callback = function(value) cfg.size = value end })
    arrowModule:AddSlider({ Name = "Радиус от центра", Min = 60, Max = 600, Default = 240, Increment = 5, Suffix = " px",
        Callback = function(value) cfg.radius = value end })
    arrowModule:AddSlider({ Name = "Плавность", Min = 3, Max = 30, Default = 14, Increment = 1,
        Callback = function(value) cfg.smooth = value end })
    arrowModule:AddToggle({ Name = "Показывать дистанцию", Default = true, Callback = function(value)
        cfg.showDistance = value
    end })
    arrowModule:AddToggle({ Name = "Только если игрока не видно", Default = false, Callback = function(value)
        cfg.onlyOffscreen = value
    end })
    arrowSection:AddLabel({ Text = "Стрелка смотрит в сторону игрока (вперёд = вверх). Чем ближе игрок, тем краснее и ярче стрелка; далеко стоящие бледнеют." })

    local container = New("Frame", {
        Name = "Arrows",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = -10, -- под окном меню
        Parent = Library.Gui,
    })
    local entries = {}

    local function makeGlyph(textSize)
        return New("TextLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Text = "▶",
            Font = Enum.Font.GothamBlack,
            TextColor3 = Theme.Accent,
            TextSize = textSize,
            TextTransparency = 1,
            TextStrokeColor3 = Color3.new(0, 0, 0),
            TextStrokeTransparency = 1,
            Size = UDim2.fromOffset(textSize, textSize),
            Visible = false,
            Parent = container,
        })
    end

    local function createEntry(player)
        if player == LocalPlayer or entries[player] then return end
        local glow = makeGlyph(40)
        local arrow = makeGlyph(26)
        local distance = Label({
            AnchorPoint = Vector2.new(0.5, 0),
            Size = UDim2.fromOffset(60, 14),
            Text = "",
            TextXAlignment = Enum.TextXAlignment.Center,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            TextTransparency = 1,
            TextStrokeColor3 = Color3.new(0, 0, 0),
            TextStrokeTransparency = 0.6,
            Visible = false,
            Parent = container,
        })
        entries[player] = {
            arrow = arrow, glow = glow, distanceLabel = distance,
            angle = 0, radius = cfg.radius, size = cfg.size,
            alpha = 0, ready = false, distance = 0,
        }
    end

    local function removeEntry(player)
        local entry = entries[player]
        if not entry then return end
        entry.arrow:Destroy()
        entry.glow:Destroy()
        entry.distanceLabel:Destroy()
        entries[player] = nil
    end

    for _, player in ipairs(Players:GetPlayers()) do createEntry(player) end
    keepConnection(Players.PlayerAdded:Connect(createEntry))
    keepConnection(Players.PlayerRemoving:Connect(removeEntry))

    keepConnection(RunService.RenderStepped:Connect(function(dt)
        if not Library.Gui then return end
        local camera = workspace.CurrentCamera
        if not camera then return end
        local center = camera.ViewportSize / 2
        local _, _, myRoot = getCharacterParts(LocalPlayer)
        local follow = 1 - math.exp(-dt * cfg.smooth)   -- плавное движение к цели
        local fadeStep = 1 - math.exp(-dt * 10)          -- плавное появление / исчезновение

        for player, entry in pairs(entries) do
            local character, humanoid, root = getCharacterParts(player)
            local show = cfg.enabled and character ~= nil and humanoid ~= nil
                and humanoid.Health > 0 and root ~= nil
            if show and cfg.onlyOffscreen then
                local _, onScreen = camera:WorldToViewportPoint(root.Position)
                if onScreen then show = false end
            end
            entry.alpha = entry.alpha + ((show and 1 or 0) - entry.alpha) * fadeStep

            if entry.alpha < 0.02 and not show then
                if entry.arrow.Visible then
                    entry.arrow.Visible = false
                    entry.glow.Visible = false
                    entry.distanceLabel.Visible = false
                    entry.ready = false
                end
            else
                if show then
                    -- вид сверху: вперёд по камере = вверх на экране
                    local rel = camera.CFrame:PointToObjectSpace(root.Position)
                    local dir = Vector2.new(rel.X, rel.Z)
                    if dir.Magnitude < 0.001 then dir = Vector2.new(0, -1) end
                    local targetAngle = math.deg(math.atan2(dir.Y, dir.X))
                    if not entry.ready then
                        entry.angle, entry.radius, entry.size = targetAngle, cfg.radius, cfg.size
                        entry.ready = true
                    end
                    local delta = ((targetAngle - entry.angle + 180) % 360) - 180 -- кратчайший поворот
                    entry.angle = entry.angle + delta * follow
                    entry.radius = entry.radius + (cfg.radius - entry.radius) * follow
                    entry.size = entry.size + (cfg.size - entry.size) * follow
                    entry.distance = myRoot and (root.Position - myRoot.Position).Magnitude or 0
                end

                local rad = math.rad(entry.angle)
                local px = center.X + math.cos(rad) * entry.radius
                local py = center.Y + math.sin(rad) * entry.radius
                local t = math.clamp(entry.distance / 500, 0, 1)
                local color = Theme.Danger:Lerp(Theme.Accent, t)
                local fade = 1 - 0.45 * t
                local a = entry.alpha

                local size = math.clamp(math.floor(entry.size + 0.5), 8, 100)
                local glowSize = math.clamp(math.floor(entry.size * 1.7 + 0.5), 8, 100)

                entry.arrow.Visible = true
                entry.arrow.Size = UDim2.fromOffset(size, size)
                entry.arrow.TextSize = size
                entry.arrow.Position = UDim2.fromOffset(px, py)
                entry.arrow.Rotation = entry.angle
                entry.arrow.TextColor3 = color
                entry.arrow.TextTransparency = 1 - a * fade
                entry.arrow.TextStrokeTransparency = 1 - a * 0.5

                entry.glow.Visible = true
                entry.glow.Size = UDim2.fromOffset(glowSize, glowSize)
                entry.glow.TextSize = glowSize
                entry.glow.Position = UDim2.fromOffset(px, py)
                entry.glow.Rotation = entry.angle
                entry.glow.TextColor3 = color
                entry.glow.TextTransparency = 1 - a * 0.28 * fade

                entry.distanceLabel.Visible = cfg.showDistance
                if cfg.showDistance then
                    entry.distanceLabel.Position = UDim2.fromOffset(px, py + size * 0.9 + 4)
                    entry.distanceLabel.Text = tostring(math.floor(entry.distance))
                    entry.distanceLabel.TextColor3 = color
                    entry.distanceLabel.TextTransparency = 1 - a * fade
                end
            end
        end
    end))

    --// ───────────── ESP ИГРОКОВ (цвет клиента) ─────────────
    local espSection = tab:AddSection("ESP игроков", "Right")
    espSection:AddLabel({ Text = "Цвет ESP = цвет клиента (акцент меню). Два вида: Glow (подсветка силуэта) и 2D Boxes (рамки)." })
    local espCfg = {
        glow = false, glowFill = 0.6,
        boxes = false, boxName = true, boxDistance = true, boxHealth = true,
        maxDistance = 1500,
    }

    local glowModule = espSection:AddModule({ Name = "ESP Glow", Callback = function(state)
        espCfg.glow = state
    end })
    glowModule:AddSlider({ Name = "Прозрачность заливки", Min = 0, Max = 1, Default = 0.6, Increment = 0.05,
        Callback = function(value) espCfg.glowFill = value end })

    local boxModule = espSection:AddModule({ Name = "ESP 2D Boxes", Callback = function(state)
        espCfg.boxes = state
    end })
    boxModule:AddToggle({ Name = "Имя", Default = true, Callback = function(value) espCfg.boxName = value end })
    boxModule:AddToggle({ Name = "Дистанция", Default = true, Callback = function(value) espCfg.boxDistance = value end })
    boxModule:AddToggle({ Name = "Здоровье", Default = true, Callback = function(value) espCfg.boxHealth = value end })
    espSection:AddSlider({ Name = "Макс. дистанция ESP", Min = 100, Max = 3000, Default = 1500, Increment = 50, Suffix = " st",
        Callback = function(value) espCfg.maxDistance = value end })

    local glowFolder = New("Folder", { Name = "EspGlow", Parent = Library.Gui })
    local boxContainer = New("Frame", {
        Name = "EspBoxes",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = -9, -- под окном меню
        Parent = Library.Gui,
    })
    local espEntries = {}

    local function createEspEntry(player)
        if player == LocalPlayer or espEntries[player] then return end
        local highlight = New("Highlight", {
            Name = "Glow_" .. player.Name,
            FillColor = Theme.Accent,
            OutlineColor = Theme.Accent,
            FillTransparency = 1,
            OutlineTransparency = 1,
            DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
            Enabled = false,
            Parent = glowFolder,
        })
        local box = New("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, Parent = boxContainer })
        local boxStroke = Stroke(Theme.Accent, 1)
        boxStroke.Thickness = 1.5
        boxStroke.Parent = box
        local nameLabel = Label({
            AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.fromOffset(160, 14), Text = player.Name,
            TextXAlignment = Enum.TextXAlignment.Center, TextSize = 12, Font = Enum.Font.GothamBold,
            TextColor3 = Theme.Accent, TextTransparency = 1, TextStrokeColor3 = Color3.new(0, 0, 0),
            TextStrokeTransparency = 0.6, Visible = false, Parent = boxContainer,
        })
        local distanceLabel = Label({
            AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromOffset(100, 14), Text = "",
            TextXAlignment = Enum.TextXAlignment.Center, TextSize = 11, Font = Enum.Font.GothamBold,
            TextColor3 = Theme.Accent, TextTransparency = 1, TextStrokeColor3 = Color3.new(0, 0, 0),
            TextStrokeTransparency = 0.6, Visible = false, Parent = boxContainer,
        })
        local healthBackground = New("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
            Visible = false, Parent = boxContainer,
        })
        local healthFill = New("Frame", {
            AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(110, 220, 140), BorderSizePixel = 0, Parent = healthBackground,
        })
        espEntries[player] = {
            highlight = highlight, box = box, boxStroke = boxStroke, nameLabel = nameLabel,
            distanceLabel = distanceLabel, healthBackground = healthBackground, healthFill = healthFill,
            glowAlpha = 0, boxAlpha = 0, top = nil, bottom = nil, distance = 0, health = 1,
        }
    end

    local function removeEspEntry(player)
        local entry = espEntries[player]
        if not entry then return end
        entry.highlight:Destroy()
        entry.box:Destroy()
        entry.nameLabel:Destroy()
        entry.distanceLabel:Destroy()
        entry.healthBackground:Destroy()
        espEntries[player] = nil
    end

    for _, player in ipairs(Players:GetPlayers()) do createEspEntry(player) end
    keepConnection(Players.PlayerAdded:Connect(createEspEntry))
    keepConnection(Players.PlayerRemoving:Connect(removeEspEntry))

    keepConnection(RunService.RenderStepped:Connect(function(dt)
        if not Library.Gui then return end
        local camera = workspace.CurrentCamera
        if not camera then return end
        local fadeStep = 1 - math.exp(-dt * 10)
        local _, _, myRoot = getCharacterParts(LocalPlayer)

        for player, entry in pairs(espEntries) do
            local character, humanoid, root = getCharacterParts(player)
            local alive = character ~= nil and humanoid ~= nil and humanoid.Health > 0 and root ~= nil
            if alive then
                entry.distance = myRoot and (root.Position - myRoot.Position).Magnitude or 0
                entry.health = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
            end
            local inRange = alive and entry.distance <= espCfg.maxDistance

            --// Glow
            local glowOn = espCfg.glow and inRange
            entry.glowAlpha = entry.glowAlpha + ((glowOn and 1 or 0) - entry.glowAlpha) * fadeStep
            if alive and entry.highlight.Adornee ~= character then
                entry.highlight.Adornee = character
            end
            entry.highlight.Enabled = entry.glowAlpha > 0.02
            entry.highlight.FillTransparency = 1 - (1 - espCfg.glowFill) * entry.glowAlpha
            entry.highlight.OutlineTransparency = 1 - entry.glowAlpha

            --// 2D Boxes
            local boxOn = espCfg.boxes and inRange
            if boxOn then
                local head = character:FindFirstChild("Head")
                local topWorld = (head and head.Position or (root.Position + Vector3.new(0, 2, 0))) + Vector3.new(0, 0.8, 0)
                local bottomWorld = root.Position - Vector3.new(0, 3.2, 0)
                local top = camera:WorldToViewportPoint(topWorld)
                local bottom = camera:WorldToViewportPoint(bottomWorld)
                if top.Z > 0 and bottom.Z > 0 then
                    entry.top, entry.bottom = top, bottom
                else
                    boxOn = false
                end
            end
            entry.boxAlpha = entry.boxAlpha + ((boxOn and 1 or 0) - entry.boxAlpha) * fadeStep

            if entry.boxAlpha < 0.02 and not boxOn then
                if entry.box.Visible then
                    entry.box.Visible = false
                    entry.nameLabel.Visible = false
                    entry.distanceLabel.Visible = false
                    entry.healthBackground.Visible = false
                end
            elseif entry.top and entry.bottom then
                local a = entry.boxAlpha
                local top, bottom = entry.top, entry.bottom
                local height = math.max(math.abs(bottom.Y - top.Y), 4)
                local width = height * 0.55
                local centerX = (top.X + bottom.X) / 2

                entry.box.Visible = true
                entry.box.Position = UDim2.fromOffset(centerX - width / 2, top.Y)
                entry.box.Size = UDim2.fromOffset(width, height)
                entry.boxStroke.Transparency = 1 - a

                entry.nameLabel.Visible = espCfg.boxName
                entry.nameLabel.Position = UDim2.fromOffset(centerX, top.Y - 3)
                entry.nameLabel.TextTransparency = 1 - a

                entry.distanceLabel.Visible = espCfg.boxDistance
                entry.distanceLabel.Position = UDim2.fromOffset(centerX, bottom.Y + 2)
                entry.distanceLabel.Text = math.floor(entry.distance) .. " st"
                entry.distanceLabel.TextTransparency = 1 - a

                entry.healthBackground.Visible = espCfg.boxHealth
                entry.healthBackground.Position = UDim2.fromOffset(centerX - width / 2 - 6, top.Y)
                entry.healthBackground.Size = UDim2.fromOffset(3, height)
                entry.healthBackground.BackgroundTransparency = 1 - 0.5 * a
                entry.healthFill.Size = UDim2.fromScale(1, entry.health)
                entry.healthFill.BackgroundTransparency = 1 - a
                entry.healthFill.BackgroundColor3 = Color3.fromRGB(235, 87, 87):Lerp(Color3.fromRGB(110, 220, 140), entry.health)
            end
        end
    end))
end

--// ═════════════════════════ НАСТРОЙКИ ═════════════════════════
local function SetupSettings(tab)
    --// СТРИМЕР-РЕЖИМ
    local streamSection = tab:AddSection("Приватность", "Right")
    streamSection:AddToggle({ Name = "Streamer Mode", Default = Library.StreamerMode, NoFlag = true, Callback = function(value)
        Library:SetStreamerMode(value)
    end })
    streamSection:AddLabel({ Text = "Скрывает твой ник и аватар в оверлее и в меню (аккаунт слева снизу)." })

    --// СЕРВЕР
    local discordSection = tab:AddSection("Discord", "Right")
    discordSection:AddLabel({ Text = CONFIG.DiscordInvite })
    discordSection:AddButton({ Name = "Скопировать ссылку на Discord", Callback = function()
        Library:CopyDiscord()
    end })

    local serverSection = tab:AddSection("Сервер", "Left")
    serverSection:AddLabel({ Text = "Job ID: " .. tostring(game.JobId) })
    serverSection:AddButton({ Name = "Скопировать Job ID", Callback = function()
        if setclipboard then
            pcall(setclipboard, tostring(game.JobId))
            Library:Notify("Job ID скопирован")
        else
            Library:Notify("Экзекутор не умеет копировать в буфер")
        end
    end })
    serverSection:AddButton({ Name = "Перезайти на сервер", Callback = function()
        Library:Notify("Перезаход...")
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end)
    end })
    serverSection:AddButton({ Name = "Server Hop", Callback = function()
        Library:Notify("Ищу сервер...")
        task.spawn(function()
            local ok, result = pcall(function()
                local url = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100"
                local body
                if game.HttpGet then
                    body = game:HttpGet(url)
                else
                    error("HTTP-запросы недоступны в этом экзекуторе")
                end
                local data = HttpService:JSONDecode(body)
                local candidates = {}
                for _, server in ipairs(data.data or {}) do
                    if server.id and server.id ~= game.JobId and (server.playing or 0) < (server.maxPlayers or 0) then
                        table.insert(candidates, server.id)
                    end
                end
                if #candidates == 0 then error("Публичные серверы не найдены") end
                local target = candidates[math.random(1, #candidates)]
                TeleportService:TeleportToPlaceInstance(game.PlaceId, target, LocalPlayer)
            end)
            if not ok then
                Library:Notify("Server Hop не удался, попробуй ещё раз")
                warn("CarryPeople3 Server Hop: " .. tostring(result))
            end
        end)
    end })
end

--// ═════════════════════════ ИСТОРИЯ (отдельная вкладка) ═════════════════════════
--// Для каждой функции своя история. Хранится в workspace/CarryPeople3/history.json
local function SetupHistory(tab)
    local KINDS = {
        { kind = "bounty", title = "История Bounty Farm",      side = "Left"  },
        { kind = "wanted", title = "История Wanted List Farm", side = "Right" },
        { kind = "kill",   title = "История Kill Farm",        side = "Left"  },
        { kind = "auto",   title = "История Auto Deposit",     side = "Right" },
    }
    local history = { bounty = {}, wanted = {}, kill = {}, auto = {} } -- новые записи первыми
    local labels = {}

    do -- загрузка (поддерживается и старый формат: список депозитов)
        local raw = LoadFile(CONFIG.HistoryFile)
        if raw and raw ~= "" then
            local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
            if ok and type(data) == "table" then
                if data.version == 2 then
                    for kind, list in pairs(history) do
                        if type(data[kind]) == "table" then
                            for _, entry in ipairs(data[kind]) do
                                if type(entry) == "table" and type(entry.text) == "string" then
                                    table.insert(list, {
                                        time = tostring(entry.time or "?"),
                                        text = entry.text,
                                        amount = type(entry.amount) == "number" and entry.amount or nil,
                                        flag = tostring(entry.flag or ""),
                                    })
                                end
                            end
                        end
                    end
                else
                    for _, entry in ipairs(data) do
                        if type(entry) == "table" and type(entry.amount) == "number" then
                            local kind = (entry.source == "Auto") and "auto" or "bounty"
                            table.insert(history[kind], {
                                time = tostring(entry.time or "?"),
                                text = "Депозит",
                                amount = entry.amount,
                                flag = "deposit",
                            })
                        end
                    end
                end
            end
        end
    end

    local function save()
        local data = { version = 2 }
        for kind, list in pairs(history) do
            data[kind] = list
        end
        pcall(function() SaveFile(CONFIG.HistoryFile, HttpService:JSONEncode(data)) end)
    end

    local function refresh(kind)
        local label = labels[kind]
        if not label then return end
        local list = history[kind]
        if #list == 0 then
            label:Set("Пока пусто.")
            return
        end
        local kills, claims, claimTotal, deposits, depositTotal = 0, 0, 0, 0, 0
        for _, entry in ipairs(list) do
            if entry.flag == "kill" then
                kills = kills + 1
            elseif entry.flag == "claim" then
                claims = claims + 1
                claimTotal = claimTotal + (entry.amount or 0)
            elseif entry.flag == "deposit" then
                deposits = deposits + 1
                depositTotal = depositTotal + (entry.amount or 0)
            end
        end
        local parts = {}
        if kills > 0 then parts[#parts + 1] = "Сбросов/убийств: " .. kills end
        if claims > 0 then parts[#parts + 1] = string.format("Claimed: %d (+%d B)", claims, claimTotal) end
        if deposits > 0 then parts[#parts + 1] = string.format("Депозитов: %d (%d B)", deposits, depositTotal) end
        local lines = { table.concat(parts, "  |  ") }
        for index = 1, math.min(#list, 15) do
            local entry = list[index]
            lines[#lines + 1] = string.format("[%s]  %s%s", entry.time, entry.text,
                entry.amount and (" — " .. entry.amount .. " B") or "")
        end
        if #list > 15 then
            lines[#lines + 1] = "… и ещё " .. (#list - 15)
        end
        label:Set(table.concat(lines, "\n"))
    end

    --// Запись из функций: kind = bounty | wanted | kill | auto; flag = kill | claim | deposit
    Shared.historyAdd = function(kind, text, amount, flag)
        local list = history[kind]
        if not list then return end
        table.insert(list, 1, { time = os.date("%d.%m %H:%M:%S"), text = text, amount = amount, flag = flag or "" })
        while #list > 200 do table.remove(list) end
        save()
        pcall(refresh, kind)
    end

    for _, info in ipairs(KINDS) do
        local section = tab:AddSection(info.title, info.side)
        labels[info.kind] = section:AddLabel({ Text = "Пока пусто." })
        section:AddButton({ Name = "Очистить историю", Callback = function()
            table.clear(history[info.kind])
            save()
            refresh(info.kind)
        end })
        refresh(info.kind)
    end
end

--// ═════════════════════════ СБОРКА ═════════════════════════
local function BuildHub()
    local Hub = Library:CreateWindow()
    Library:CreateWatermark()

    -- Вкладки: порядок как в меню. Если картинка не скачалась, берётся символ после "or".
    local Combat    = Hub:AddTab("Бой",      Library.Icon("icon_fight.png")     or "⚔")
    local Movement  = Hub:AddTab("Движение", Library.Icon("icon_movement.png")  or "➤")
    local PlayerTab = Hub:AddTab("Игрок",    Library.Icon("icon_player.png")    or "👤")
    local Visuals   = Hub:AddTab("Визуалы",  Library.Icon("icon_visuals.png")   or "👁")
    local Misc      = Hub:AddTab("Разное",   Library.Icon("icon_utilities.png") or "🔧")
    local HistoryTab = Hub:AddTab("История", Library.Icon("icon_history.png") or "🕒", CONFIG.GroupManage)
    Hub:AddConfigTab("Конфиги",              Library.Icon("icon_configs.png")   or "📁")
    local SettingsTab = Hub:AddSettingsTab("Настройки", Library.Icon("icon_settings.png") or "⚙")

    -- Разное первым: Anti Void нужен фарму из вкладки Игрок
    SetupMisc(Misc)
    SetupHistory(HistoryTab)
    SetupAntiGrab(Misc)
    SetupCombat(Combat)
    SetupMovement(Movement)
    SetupPlayer(PlayerTab)
    SetupVisuals(Visuals)
    SetupSettings(SettingsTab)

    refreshPlayerDropdowns()
    Connect(Players.PlayerAdded, function() task.defer(refreshPlayerDropdowns) end)
    Connect(Players.PlayerRemoving, function() task.defer(refreshPlayerDropdowns) end)

    Hub.FirstTab:Select()
    Hub:Toggle(true)
    Library:ShowInfoWindow() -- окно User Info / список обновлений при загрузке; R — показать/скрыть его снова
    Library:Notify("Ran Hub загружен. Меню: Right Ctrl, окно инфо: R", 4)
end

Library:KeyGate(BuildHub)
