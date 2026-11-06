--[[
╔══════════════════════════════════════════════════════════════════╗
║  NurLib — UI библиотека в стиле Nursultan для Roblox (Luau)      ║
║                                                                  ║
║  Где менять под себя — ищи пометку:  ◄◄ ИЗМЕНИТЬ                 ║
║   1) блок CONFIG сразу ниже                                      ║
║   2) блок "ТВОЙ СКРИПТ" в самом конце файла                      ║
║                                                                  ║
║  Открыть/закрыть меню: RightCtrl (меняется в CONFIG.MenuKey)     ║
╚══════════════════════════════════════════════════════════════════╝
]]

--// ═════════════════════ ◄◄ ИЗМЕНИТЬ: НАСТРОЙКИ ═════════════════════
local CONFIG = {
    HubName     = "Ran Hub",                  -- ◄◄ ИЗМЕНИТЬ: название хаба (в оверлее слева сверху)
    LogoText    = "R",                          -- ◄◄ ИЗМЕНИТЬ: буква-запасной логотип (если картинка не загрузилась)
    LogoUrl     = "https://raw.githubusercontent.com/sergeydb-wq/Logos/refs/heads/main/IMG_3726.png", -- ◄◄ ИЗМЕНИТЬ: прямая ссылка на PNG (nil = без картинки)
    IconsBase   = "https://raw.githubusercontent.com/sergeydb-wq/Logos/refs/heads/main/", -- ◄◄ ИЗМЕНИТЬ: папка на GitHub, где лежат иконки вкладок
    IconsFolder = "blockcraft/icons",               -- ◄◄ ИЗМЕНИТЬ: куда сохранять иконки в workspace
    LogoFile    = "blockcraft/logo.png",            -- ◄◄ ИЗМЕНИТЬ: куда сохранить картинку в workspace экзекутора
    GuiName     = "NurLibGui",                  -- ◄◄ ИЗМЕНИТЬ: внутреннее имя GUI (любое уникальное)
    AccountName = nil,                          -- ◄◄ ИЗМЕНИТЬ: nil = настоящий ник аккаунта (LocalPlayer.Name, не DisplayName), или свой текст "MyName"
    AccountRole = "user",                       -- ◄◄ ИЗМЕНИТЬ: текст под ником (user / premium / admin ...)
    AccentColor = Color3.fromRGB(250, 128, 114),-- ◄◄ ИЗМЕНИТЬ: главный цвет (лососевый как на фото)
    MenuKey     = Enum.KeyCode.RightControl,      -- ◄◄ ИЗМЕНИТЬ: клавиша открытия меню
    WindowSize  = Vector2.new(800, 500),        -- ◄◄ ИЗМЕНИТЬ: размер окна
    ConfigFolder= "blockcraft/configs",             -- ◄◄ ИЗМЕНИТЬ: папка для конфигов (в workspace экзекутора)
    SpeedSuffix = "bps",                        -- ◄◄ ИЗМЕНИТЬ: подпись скорости (studs/sec)
    GroupFunctions = "ФУНКЦИИ",                 -- ◄◄ ИЗМЕНИТЬ: заголовок первой группы вкладок
    GroupManage    = "УПРАВЛЕНИЕ",              -- ◄◄ ИЗМЕНИТЬ: заголовок второй группы вкладок
    SearchPlaceholder = "Поиск",                -- ◄◄ ИЗМЕНИТЬ: текст в поиске
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
    Connections = {}, Listening = nil, Gui = nil,
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
}

--// ───────────── загрузка логотипа в workspace экзекутора ─────────────
local LogoAsset = nil
do
    local ok = pcall(function()
        if not (CONFIG.LogoUrl and writefile and isfile and getcustomasset and makefolder and isfolder) then return end
        local dir = CONFIG.LogoFile:match("^(.*)/[^/]+$")
        if dir then
            local path = ""
            for part in string.gmatch(dir, "[^/]+") do
                path = (path == "") and part or (path .. "/" .. part)
                if not isfolder(path) then makefolder(path) end
            end
        end
        if not isfile(CONFIG.LogoFile) then
            writefile(CONFIG.LogoFile, game:HttpGet(CONFIG.LogoUrl))
        end
        LogoAsset = getcustomasset(CONFIG.LogoFile)
    end)
    if not ok then LogoAsset = nil end
end

-- скачивает иконку вкладки (PNG с GitHub) в workspace; вернёт nil, если не вышло
local function IconAsset(fileName)
    local result
    pcall(function()
        if not (CONFIG.IconsBase and writefile and isfile and getcustomasset and makefolder and isfolder) then return end
        local path = ""
        for part in string.gmatch(CONFIG.IconsFolder, "[^/]+") do
            path = (path == "") and part or (path .. "/" .. part)
            if not isfolder(path) then makefolder(path) end
        end
        local file = CONFIG.IconsFolder .. "/" .. fileName
        if not isfile(file) then writefile(file, game:HttpGet(CONFIG.IconsBase .. fileName)) end
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
local function Tween(o, props, t)
    TweenService:Create(o, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
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

--// ───────────── уведомления ─────────────
Library.Icon = IconAsset

function Library:Notify(text, duration)
    if not Library.Gui then return end
    local holder = Library.Gui:FindFirstChild("Notifications")
    if not holder then
        holder = New("Frame", { Name = "Notifications", BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -14),
            Size = UDim2.fromOffset(260, 400), Parent = Library.Gui })
        New("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 6),
            HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder, Parent = holder })
    end
    local n = New("Frame", { Size = UDim2.fromOffset(0, 34), AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = Theme.Background, Parent = holder }, { Corner(7), Stroke(Theme.Accent, 0.4), Pad(12, 0, 12, 0) })
    Label({ Text = tostring(text), Size = UDim2.fromOffset(0, 34), AutomaticSize = Enum.AutomaticSize.X, Parent = n })
    task.delay(duration or 3, function() if n then n:Destroy() end end)
end

--// ───────────── переключатель (switch) ─────────────
local function MakeSwitch(parent, pos)
    local sw = New("Frame", { Size = UDim2.fromOffset(32, 16), AnchorPoint = Vector2.new(1, 0.5),
        Position = pos, BackgroundColor3 = Theme.Off, Parent = parent }, { Corner(8) })
    local knob = New("Frame", { Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 2, 0.5, 0), BackgroundColor3 = Color3.fromRGB(200, 200, 200), Parent = sw }, { Corner(6) })
    return function(v)
        Tween(sw, { BackgroundColor3 = v and Theme.Accent or Theme.Off })
        Tween(knob, { Position = v and UDim2.new(1, -14, 0.5, 0) or UDim2.new(0, 2, 0.5, 0) })
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
        Tween(fill, { Size = UDim2.fromScale((v - min) / math.max(max - min, 1e-6), 1) }, 0.08)
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
    local valLbl = Label({ Text = "—", Size = UDim2.new(1, -8, 1, 0), Position = UDim2.fromOffset(8, 0),
        TextTruncate = Enum.TextTruncate.AtEnd, Parent = box })
    local list = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, Visible = false, LayoutOrder = 2, Parent = holder })
    New("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
    list:FindFirstChildOfClass("UIListLayout")
    Pad(12, 2, 12, 4).Parent = list

    local buttons = {}
    local function paint()
        for opt, b in pairs(buttons) do
            b.TextColor3 = (opt == obj.Value) and Theme.Accent or Theme.SubText
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
            b.MouseButton1Click:Connect(function() obj:Set(opt); list.Visible = false end)
            buttons[opt] = b
        end
        paint()
    end
    head.MouseButton1Click:Connect(function() list.Visible = not list.Visible end)
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
    local b = New("TextButton", { Size = UDim2.new(1, -24, 0, 28), Position = UDim2.fromOffset(12, 0),
        BackgroundColor3 = Theme.Field, Text = o.Name, Font = Enum.Font.GothamMedium, TextSize = 13,
        TextColor3 = Theme.Text, AutoButtonColor = false, Parent = parent }, { Corner(6) })
    -- чтобы кнопка имела отступы в списке:
    local wrap = New("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, Parent = parent })
    b.Parent = wrap
    b.Position = UDim2.fromOffset(12, 3)
    b.MouseEnter:Connect(function() Tween(b, { BackgroundColor3 = Theme.Selected }) end)
    b.MouseLeave:Connect(function() Tween(b, { BackgroundColor3 = Theme.Field }) end)
    b.MouseButton1Click:Connect(function() if o.Callback then task.spawn(o.Callback) end end)
    return b
end

local function BuildTextbox(parent, o)
    local obj = { Value = "" }
    local flag = o.Flag or o.Name
    local row = New("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, Parent = parent })
    local box = New("TextBox", { Position = UDim2.fromOffset(12, 3), Size = UDim2.new(1, -24, 0, 28),
        BackgroundColor3 = Theme.Field, Text = "", PlaceholderText = o.Placeholder or o.Name,
        PlaceholderColor3 = Theme.SubText, Font = Enum.Font.GothamMedium, TextSize = 13,
        TextColor3 = Theme.Text, ClearTextOnFocus = false, Parent = row }, { Corner(6), Pad(8, 0, 8, 0) })
    local function commit(t, silent)
        obj.Value = t
        if not o.NoFlag then Library.Flags[flag] = t end
        if not silent and o.Callback then task.spawn(o.Callback, t) end
    end
    box.FocusLost:Connect(function() commit(box.Text) end)
    function obj:Set(t, silent) t = tostring(t or ""); box.Text = t; commit(t, silent) end
    if not o.NoFlag then Library.Setters[flag] = function(v) obj:Set(v) end end
    if o.Default then obj:Set(o.Default, true) end
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
    local settings = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Color3.fromRGB(14, 14, 16), BorderSizePixel = 0, Visible = false, LayoutOrder = 2, Parent = holder })
    New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = settings })
    Pad(0, 4, 0, 4).Parent = settings

    module.Dots, module.Settings, module.Holder = dots, settings, holder

    function module:Set(v, silent)
        v = v and true or false
        module.Value = v
        Library.Flags[module.Flag] = v
        visual(v)
        Tween(nameLbl, { TextColor3 = v and Theme.Text or Theme.SubText })
        if not silent and o.Callback then task.spawn(o.Callback, v) end
    end

    click.MouseButton1Click:Connect(function() module:Set(not module.Value) end)
    click.MouseButton2Click:Connect(function() if dots.Visible then settings.Visible = not settings.Visible end end)
    dots.MouseButton1Click:Connect(function() settings.Visible = not settings.Visible end)

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

--// ───────────── Конфиги (файлы) ─────────────
local function HasFS()
    return writefile and readfile and isfolder and makefolder and listfiles and true or false
end
local function CfgPath(name) return CONFIG.ConfigFolder .. "/" .. name .. ".json" end
local function EnsureFolder()
    if not HasFS() then return false end
    local path = ""
    for part in string.gmatch(CONFIG.ConfigFolder, "[^/]+") do
        path = (path == "") and part or (path .. "/" .. part)
        if not isfolder(path) then makefolder(path) end
    end
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

--// ───────────── Watermark (слева сверху, БЕЗ TPS) ─────────────
function Library:CreateWatermark()
    local root = New("Frame", { Name = "Watermark", Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(0, 0),
        AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1, Parent = Library.Gui })
    New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = root })

    local function Pill(order)
        local p = New("Frame", { Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = Theme.Background, BackgroundTransparency = 0.15, LayoutOrder = order, Parent = root },
            { Corner(6), Stroke(Theme.Stroke), Pad(10, 0, 10, 0) })
        New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12),
            VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = p })
        return p
    end
    local function Item(parent, text, color, order)
        return Label({ Text = text, Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X,
            TextColor3 = color or Theme.Text, TextSize = 12, LayoutOrder = order, Parent = parent })
    end

    local row1, row2 = Pill(1), Pill(2)
    Logo({ Size = UDim2.fromOffset(18, 18), LayoutOrder = 1, Parent = row1 }, 14)
    Item(row1, CONFIG.HubName, Theme.Text, 2)
    Item(row1, LocalPlayer.Name, Theme.Text, 3)
    local fpsL  = Item(row1, "0 fps", Theme.Text, 4)
    local pingL = Item(row1, "0ms",   Theme.Text, 5)
    local timeL = Item(row1, "00:00:00", Theme.Text, 6)
    local posL  = Item(row2, "x0 y0 z0", Theme.Text, 1)
    local spdL  = Item(row2, "0.0 " .. CONFIG.SpeedSuffix, Theme.Text, 2)

    local acc, frames = 0, 0
    Connect(RunService.RenderStepped, function(dt)
        acc += dt; frames += 1
        if acc < 0.25 then return end
        fpsL.Text = math.floor(frames / acc + 0.5) .. " fps"
        acc, frames = 0, 0
        local ok, ping = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
        pingL.Text = (ok and math.floor(ping) or 0) .. "ms"
        timeL.Text = os.date("%H:%M:%S")
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local p, v = hrp.Position, hrp.AssemblyLinearVelocity
            posL.Text = string.format("x%d y%d z%d", math.floor(p.X), math.floor(p.Y), math.floor(p.Z))
            spdL.Text = string.format("%.1f %s", Vector3.new(v.X, 0, v.Z).Magnitude, CONFIG.SpeedSuffix)
        end
    end)
    Library.Watermark = root
    return root
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
    local arrow = Label({ Text = "▾", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(16, 16), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 16,
        TextColor3 = Theme.Accent, Parent = head })
    local body = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, LayoutOrder = 2, Parent = frame })
    New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = body })
    Pad(0, 0, 0, 4).Parent = body
    head.MouseButton1Click:Connect(function()
        body.Visible = not body.Visible
        arrow.Rotation = body.Visible and 0 or 180
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
    local tab = setmetatable({ Name = name }, Tab)

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

    local page = New("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Accent, AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(), Visible = false, Parent = self.Pages })
    Pad(0, 0, 6, 8).Parent = page
    tab.Left = New("Frame", { Size = UDim2.new(0.5, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, Parent = page })
    tab.Right = New("Frame", { Position = UDim2.new(0.5, 6, 0, 0), Size = UDim2.new(0.5, -6, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = page })
    for _, c in ipairs({ tab.Left, tab.Right }) do
        New("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = c })
    end

    function tab:_paint(active)
        page.Visible = active
        Tween(btn, { BackgroundTransparency = active and 0 or 1 })
        Tween(st, { Transparency = active and 0 or 1 })
        Tween(tx, { TextColor3 = active and Theme.Text or Theme.SubText })
        if ic:IsA("TextLabel") then Tween(ic, { TextColor3 = active and Theme.Accent or Theme.SubText })
        else Tween(ic, { ImageColor3 = active and Theme.Accent or Theme.SubText }) end
    end
    function tab:Select()
        for _, t in ipairs(self.Window.TabsList) do t:_paint(false) end
        self:_paint(true)
    end
    tab.Window = self
    btn.MouseButton1Click:Connect(function() tab:Select() end)
    table.insert(self.TabsList, tab)
    if #self.TabsList == 1 then tab:Select() end
    return tab
end

--// Вкладка "Конфиги" (вместо Пресеты / Авто покупка / Аккаунты)
function Window:AddConfigTab(name, icon)
    local tab = self:AddTab(name or "Конфиги", icon or "📁", CONFIG.GroupManage)
    local left = tab:AddSection("Конфиги", "Left")
    local nameBox = left:AddTextbox({ Name = "Название", Placeholder = "Название конфига" })
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

--// Вкладка "Настройки"
function Window:AddSettingsTab(name, icon)
    local tab = self:AddTab(name or "Настройки", icon or "⚙", CONFIG.GroupManage)
    local sec = tab:AddSection("Интерфейс", "Left")
    sec:AddToggle({ Name = "Оверлей слева сверху", Default = true, NoFlag = true, Callback = function(v)
        if Library.Watermark then Library.Watermark.Visible = v end
    end })
    sec:AddButton({ Name = "Выгрузить скрипт", Callback = function() Library:Unload() end })
    return tab
end

function Window:Toggle(v)
    if v == nil then v = not self.Main.Visible end
    self.Main.Visible = v
end

function Library:Unload()
    for _, c in ipairs(Library.Connections) do pcall(function() c:Disconnect() end) end
    if Library.Gui then Library.Gui:Destroy() end
end

function Library:CreateWindow()
    -- родитель GUI
    local gui = New("ScreenGui", { Name = CONFIG.GuiName, ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999 })
    local parent
    local okH, hui = pcall(function() return gethui and gethui() end)
    if okH and hui then parent = hui
    else
        local okC = pcall(function() gui.Parent = CoreGui end)
        parent = (okC and gui.Parent == CoreGui) and CoreGui or LocalPlayer:WaitForChild("PlayerGui")
    end
    local old = parent:FindFirstChild(CONFIG.GuiName)
    if old then old:Destroy() end
    gui.Parent = parent
    Library.Gui = gui

    local win = setmetatable({ Order = 0, Groups = {}, TabsList = {} }, Window)
    local size = CONFIG.WindowSize
    local main = New("Frame", { Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(size.X, size.Y), BackgroundColor3 = Theme.Background, BorderSizePixel = 0,
        Parent = gui }, { Corner(10), Stroke(Theme.Stroke) })
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

    -- аккаунт слева снизу: имя + user
    local acc = New("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1),
        Size = UDim2.new(1, 0, 0, 58), BackgroundTransparency = 1, Parent = sidebar })
    New("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, Parent = acc })
    local accName = CONFIG.AccountName or LocalPlayer.Name
    local av = New("Frame", { Position = UDim2.fromOffset(14, 14), Size = UDim2.fromOffset(30, 30),
        BackgroundColor3 = Theme.Field, Parent = acc }, { Corner(15) })
    Label({ Text = string.upper(string.sub(accName, 1, 1)), Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 14, Parent = av })
    Label({ Text = accName, Position = UDim2.fromOffset(54, 13), Size = UDim2.new(1, -62, 0, 16),
        Font = Enum.Font.GothamBold, TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd, Parent = acc })
    Label({ Text = CONFIG.AccountRole, Position = UDim2.fromOffset(54, 29), Size = UDim2.new(1, -62, 0, 14),
        TextSize = 11, TextColor3 = Theme.SubText, Parent = acc })

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

    -- открытие/закрытие + бинды
    Connect(UIS.InputBegan, function(input, gpe)
        if Library.Listening then Library.Listening(input); return end
        if gpe or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if input.KeyCode == CONFIG.MenuKey then win:Toggle(); return end
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

--// ═══════════════════════════════════════════════════════════════════
--// ═══ ◄◄ ТВОЙ СКРИПТ ═══

local Window = Library:CreateWindow()
Library:CreateWatermark()

local Combat  = Window:AddTab("Бой",      Library.Icon("icon_fight.png")     or "⚔")
local Movement = Window:AddTab("Движение", Library.Icon("icon_movement.png") or "➤")
local FarmTab  = Window:AddTab("Фарм",     Library.Icon("icon_farm.png")      or "⛏")
local Visuals = Window:AddTab("Визуалы", Library.Icon("icon_visuals.png") or "👁")
Window:AddConfigTab("Конфиги",     Library.Icon("icon_configs.png")  or "📁")
Window:AddSettingsTab("Настройки", Library.Icon("icon_settings.png") or "⚙")

--// ═══════════════════════════════════════════════════════════════════
--// ORE ESP
--// ═══════════════════════════════════════════════════════════════════
local OreConfig = {
    Enabled = false,
    Transparency = 0.5,
    LimitDistance = true,   -- ограничивать дальность показа
    MaxDistance = 250,      -- дальность в стадах
    Ores = {
        -- Name = имя объекта в чанке; Label = как называется в меню
        CoalOre    = { Label = "Уголь",  Enabled = true, Color = Color3.fromRGB(60, 60, 60) },
        DiamondOre = { Label = "Алмаз",  Enabled = true, Color = Color3.fromRGB(0, 255, 255) },
        GoldOre    = { Label = "Золото", Enabled = true, Color = Color3.fromRGB(255, 215, 0) },
        RubyOre    = { Label = "Рубин",  Enabled = true, Color = Color3.fromRGB(255, 0, 60) },
        SteelOre   = { Label = "Железо", Enabled = true, Color = Color3.fromRGB(200, 200, 200) },
        SapphireOre = { Label = "Сапфир", Enabled = true, Color = Color3.fromRGB(40, 110, 255), WholeMap = true },  -- сапфир: по умолчанию видно на всей карте
    },
    Order = { "CoalOre", "DiamondOre", "GoldOre", "RubyOre", "SteelOre", "SapphireOre" },
}

local Blocks = workspace:WaitForChild("Blocks")
local adornments, ancestryConns, conns = {}, {}, {}

local function getSize(obj)
    if obj:IsA("BasePart") then return obj.Size end
    if obj:IsA("Model") then
        local _, size = obj:GetBoundingBox()
        return size
    end
end

local function removeESP(obj)
    local a = adornments[obj]
    if a then a:Destroy(); adornments[obj] = nil end
    local c = ancestryConns[obj]
    if c then c:Disconnect(); ancestryConns[obj] = nil end
end

local function addESP(obj)
    if adornments[obj] then return end
    local s = OreConfig.Ores[obj.Name]
    if not (OreConfig.Enabled and s and s.Enabled) then return end
    local size = getSize(obj)
    if not size then return end

    local a = Instance.new("BoxHandleAdornment")
    a.Adornee = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or obj
    a.Size = size + Vector3.new(0.05, 0.05, 0.05)
    a.Color3 = s.Color
    a.Transparency = OreConfig.Transparency
    a.AlwaysOnTop = true
    a.ZIndex = 5
    a.Parent = obj
    adornments[obj] = a

    ancestryConns[obj] = obj.AncestryChanged:Connect(function(_, parent)
        if not parent then removeESP(obj) end
    end)
end

local function Refresh()
    for obj in pairs(adornments) do removeESP(obj) end
    if not OreConfig.Enabled then return end
    for _, chunk in ipairs(Blocks:GetChildren()) do
        for _, obj in ipairs(chunk:GetChildren()) do addESP(obj) end
    end
end

local function watchChunk(chunk)
    table.insert(conns, chunk.ChildAdded:Connect(addESP))
end
for _, chunk in ipairs(Blocks:GetChildren()) do watchChunk(chunk) end
table.insert(conns, Blocks.ChildAdded:Connect(function(chunk)
    watchChunk(chunk)
    for _, obj in ipairs(chunk:GetChildren()) do addESP(obj) end
end))

-- дальность показа: раз в 0.2 сек скрываем/показываем подсветку
local lastCheck = 0
table.insert(conns, RunService.Heartbeat:Connect(function()
    local now = os.clock()
    if now - lastCheck < 0.2 then return end
    lastCheck = now

    local origin
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        origin = hrp.Position
    elseif workspace.CurrentCamera then
        origin = workspace.CurrentCamera.CFrame.Position
    end

    for obj, a in pairs(adornments) do
        local part = a.Adornee
        local oc = OreConfig.Ores[obj.Name]
        if not OreConfig.LimitDistance or (oc and oc.WholeMap) or not origin or not part then
            a.Visible = true
        else
            a.Visible = (part.Position - origin).Magnitude <= OreConfig.MaxDistance
        end
    end
end))

-- очистка при выгрузке скрипта
local oldUnload = Library.Unload
function Library:Unload()
    for obj in pairs(adornments) do removeESP(obj) end
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    oldUnload(self)
end

--// ═══════════════════════════════════════════════════════════════════
--// МЕНЮ
--// ═══════════════════════════════════════════════════════════════════
local Main = Visuals:AddSection("Ore ESP", "Left")
local mainModule = Main:AddModule({
    Name = "Ore ESP",
    Default = false,
    Callback = function(state)
        OreConfig.Enabled = state
        Refresh()
    end,
})
mainModule:AddSlider({
    Name = "Прозрачность", Min = 0, Max = 1, Default = OreConfig.Transparency, Increment = 0.05,
    Callback = function(v)
        OreConfig.Transparency = v
        for _, a in pairs(adornments) do a.Transparency = v end
    end,
})

mainModule:AddToggle({
    Name = "Ограничить дальность", Default = OreConfig.LimitDistance,
    Callback = function(v) OreConfig.LimitDistance = v end,
})
mainModule:AddSlider({
    Name = "Дальность", Min = 10, Max = 2000, Default = OreConfig.MaxDistance, Increment = 10, Suffix = " st",
    Callback = function(v) OreConfig.MaxDistance = v end,
})

-- по модулю на каждую руду: тумблер = вкл/выкл, "•••" = цвет (R, G, B)
local OresSec = Visuals:AddSection("Руды", "Right")
for _, oreName in ipairs(OreConfig.Order) do
    local s = OreConfig.Ores[oreName]
    local rgb = {
        r = math.floor(s.Color.R * 255 + 0.5),
        g = math.floor(s.Color.G * 255 + 0.5),
        b = math.floor(s.Color.B * 255 + 0.5),
    }
    local function applyColor()
        s.Color = Color3.fromRGB(rgb.r, rgb.g, rgb.b)
        for obj, a in pairs(adornments) do
            if obj.Name == oreName then a.Color3 = s.Color end
        end
    end

    local m = OresSec:AddModule({
        Name = s.Label,
        Flag = "Ore." .. oreName,
        Default = s.Enabled,
        Callback = function(state)
            s.Enabled = state
            Refresh()
        end,
    })
    m:AddSlider({ Name = "R", Min = 0, Max = 255, Default = rgb.r, Increment = 1,
        Callback = function(v) rgb.r = v; applyColor() end })
    m:AddSlider({ Name = "G", Min = 0, Max = 255, Default = rgb.g, Increment = 1,
        Callback = function(v) rgb.g = v; applyColor() end })
    m:AddSlider({ Name = "B", Min = 0, Max = 255, Default = rgb.b, Increment = 1,
        Callback = function(v) rgb.b = v; applyColor() end })
    m:AddToggle({ Name = "Вся карта (без лимита дальности)", Default = s.WholeMap or false,
        Callback = function(v) s.WholeMap = v end })
end


--// ═══════════════════════════════════════════════════════════════════
--// ОБЩЕЕ: размер блока, друзья (blockcraft/friends.json)
--// ═══════════════════════════════════════════════════════════════════
local BLOCK_SIZE = 3                       -- ◄◄ ИЗМЕНИТЬ: сколько стадов в одном блоке (для дальности в блоках)
local SAVE_DIR = "blockcraft"
local FRIENDS_FILE = SAVE_DIR .. "/friends.json"
local FRIEND_COLOR = Color3.fromRGB(0, 255, 80)  -- ◄◄ ИЗМЕНИТЬ: цвет друзей
local Friends = {}                         -- [ник] = true

local function fsOK()
    return (writefile and readfile and isfile and isfolder and makefolder) and true or false
end

local function saveFriends()
    if not fsOK() then return end
    pcall(function()
        if not isfolder(SAVE_DIR) then makefolder(SAVE_DIR) end
        local list = {}
        for n in pairs(Friends) do table.insert(list, n) end
        table.sort(list)
        writefile(FRIENDS_FILE, HttpService:JSONEncode(list))
    end)
end

local function loadFriends()
    if not fsOK() then return end
    pcall(function()
        if isfile(FRIENDS_FILE) then
            for _, n in ipairs(HttpService:JSONDecode(readfile(FRIENDS_FILE))) do
                Friends[tostring(n)] = true
            end
        end
    end)
end
loadFriends()

local function isFriend(player) return Friends[player.Name] == true end

local function sortedFriends()
    local list = {}
    for n in pairs(Friends) do table.insert(list, n) end
    table.sort(list)
    return list
end

--// ═══════════════════════════════════════════════════════════════════
--// ATTACK AURA + АВТО-ДОГОН (кружится вокруг цели)
--// ═══════════════════════════════════════════════════════════════════
local TargetState = { Player = nil, Char = nil, WantHud = false }  -- текущая цель (читает Target HUD)

do
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Aura = {
        Enabled = false, Range = 6, CPS = 10, Mode = "Ближайший",
        Chase = false, ChaseRange = 40, OrbitRadius = 1.5, OrbitSpeed = 2, Debug = false,
    }
    local remote
    local angle = 0
    local attackTimer = 0

    local function getRemote()
        if remote and remote.Parent then return remote end
        local gr = ReplicatedStorage:FindFirstChild("GameRemotes")
        remote = gr and gr:FindFirstChild("Attack")
        return remote
    end

    local function myRoot()
        local char = LocalPlayer.Character
        return char and char:FindFirstChild("HumanoidRootPart")
    end

    -- проверка игрока: жив, не друг, в радиусе. Возвращает char, hrp, dist
    local function evalPlayer(p, myPos, maxStuds)
        if not p or p == LocalPlayer or p.Parent ~= Players or isFriend(p) then return end
        local c = p.Character
        local th = c and c:FindFirstChild("HumanoidRootPart")
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        if not (th and hum and hum.Health > 0) then return end
        local d = (th.Position - myPos).Magnitude
        if d > maxStuds then return end
        return c, th, d
    end

    local function getTargets(maxStuds)
        local hrp = myRoot()
        if not hrp then return {} end
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            local c, _, d = evalPlayer(p, hrp.Position, maxStuds)
            if c then table.insert(list, { player = p, char = c, dist = d }) end
        end
        table.sort(list, function(a, b) return a.dist < b.dist end)
        return list
    end

    -- один "клик": бьём цели в радиусе (цель погони — первой)
    local function fireAura()
        local r = getRemote()
        if not r then return end
        local targets = getTargets(Aura.Range * BLOCK_SIZE)
        if TargetState.Char then
            for i, t in ipairs(targets) do
                if t.char == TargetState.Char then
                    table.remove(targets, i)
                    table.insert(targets, 1, t)
                    break
                end
            end
        end
        local n = (Aura.Mode == "Все") and #targets or math.min(#targets, 1)
        for i = 1, n do
            local c = targets[i].char
            task.spawn(function()
                local ok, res = pcall(function() return r:InvokeServer(c) end)
                if Aura.Debug then print("[Attack Aura]", c.Name, ok, res) end
            end)
        end
    end

    -- выбор цели (раз в 0.1 сек) + кружение (каждый кадр) + удары сразу после перемещения
    local lastSelect = 0
    table.insert(conns, RunService.Heartbeat:Connect(function(dt)
        if not (Aura.Enabled or TargetState.WantHud) then
            TargetState.Player, TargetState.Char = nil, nil
            return
        end
        local hrp = myRoot()
        if not hrp then TargetState.Player, TargetState.Char = nil, nil return end

        local chasing = Aura.Enabled and Aura.Chase
        local searchStuds = (chasing and Aura.ChaseRange or Aura.Range) * BLOCK_SIZE

        local now = os.clock()
        if now - lastSelect >= 0.1 then
            lastSelect = now
            local keep = evalPlayer(TargetState.Player, hrp.Position, searchStuds)
            if not keep then
                local list = getTargets(searchStuds)
                if list[1] then
                    TargetState.Player, TargetState.Char = list[1].player, list[1].char
                else
                    TargetState.Player, TargetState.Char = nil, nil
                end
            end
        end

        if chasing and TargetState.Char then
            local th = TargetState.Char:FindFirstChild("HumanoidRootPart")
            if th then
                -- радиус круга не больше дальности удара, чтобы удары доходили
                local radius = math.min(Aura.OrbitRadius * BLOCK_SIZE, Aura.Range * BLOCK_SIZE - 1)
                radius = math.max(radius, 1.5)
                angle = (angle + Aura.OrbitSpeed * dt) % (math.pi * 2)
                local tp = th.Position
                local pos = Vector3.new(tp.X + math.cos(angle) * radius, tp.Y, tp.Z + math.sin(angle) * radius)
                hrp.CFrame = CFrame.lookAt(pos, Vector3.new(tp.X, pos.Y, tp.Z))
                hrp.AssemblyLinearVelocity = Vector3.zero
            end
        end

        if Aura.Enabled then
            attackTimer += dt
            local interval = 1 / Aura.CPS
            if attackTimer >= interval then
                attackTimer -= interval
                if attackTimer > interval then attackTimer = 0 end
                fireAura()
            end
        end
    end))

    local prevUnload = Library.Unload
    function Library:Unload()
        Aura.Enabled = false
        prevUnload(self)
    end

    local Sec = Combat:AddSection("Attack Aura", "Left")
    local m = Sec:AddModule({
        Name = "Attack Aura",
        Default = false,
        Callback = function(state)
            Aura.Enabled = state
            attackTimer = 0
        end,
    })
    m:AddSlider({ Name = "Дальность", Min = 1, Max = 30, Default = Aura.Range, Increment = 1, Suffix = " бл",
        Callback = function(v) Aura.Range = v end })
    m:AddSlider({ Name = "Кликов в секунду", Min = 1, Max = 30, Default = Aura.CPS, Increment = 1,
        Callback = function(v) Aura.CPS = v end })
    m:AddDropdown({ Name = "Цели", Options = { "Ближайший", "Все" }, Default = Aura.Mode,
        Callback = function(v) Aura.Mode = v or "Ближайший" end })
    m:AddToggle({ Name = "Авто-догон", Default = false,
        Callback = function(v) Aura.Chase = v end })
    m:AddSlider({ Name = "Радиус погони", Min = 5, Max = 100, Default = Aura.ChaseRange, Increment = 1, Suffix = " бл",
        Callback = function(v) Aura.ChaseRange = v end })
    m:AddSlider({ Name = "Радиус круга", Min = 0.5, Max = 15, Default = Aura.OrbitRadius, Increment = 0.5, Suffix = " бл",
        Callback = function(v) Aura.OrbitRadius = v end })
    m:AddSlider({ Name = "Скорость кружения", Min = 1, Max = 20, Default = Aura.OrbitSpeed, Increment = 1,
        Callback = function(v) Aura.OrbitSpeed = v end })
    m:AddToggle({ Name = "Debug (print в консоль)", Default = false,
        Callback = function(v) Aura.Debug = v end })
    m:AddKeybind({ Name = "Бинд" })
end

--// ═══════════════════════════════════════════════════════════════════
--// FRIEND LIST (вкладка "Бой")
--// ═══════════════════════════════════════════════════════════════════
do
    local FSec = Combat:AddSection("Friend List", "Right")

    local playerDD = FSec:AddDropdown({ Name = "Игроки", Options = {}, NoFlag = true })
    local friendDD = FSec:AddDropdown({ Name = "Друзья", Options = sortedFriends(), NoFlag = true })

    local function refreshPlayers()
        local names = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then table.insert(names, p.Name) end
        end
        table.sort(names)
        playerDD:Refresh(names)
        if playerDD.Value and not table.find(names, playerDD.Value) then playerDD:Set(nil, true) end
    end
    local function refreshFriends()
        friendDD:Refresh(sortedFriends())
        if friendDD.Value and not Friends[friendDD.Value] then friendDD:Set(nil, true) end
    end

    FSec:AddButton({ Name = "Добавить в друзья", Callback = function()
        local n = playerDD.Value
        if not n then Library:Notify("Выбери игрока в списке «Игроки»", 3) return end
        Friends[n] = true
        saveFriends()
        refreshFriends()
        Library:Notify(n .. " добавлен в друзья", 3)
    end })
    FSec:AddButton({ Name = "Убрать из друзей", Callback = function()
        local n = friendDD.Value
        if not n then Library:Notify("Выбери друга в списке «Друзья»", 3) return end
        Friends[n] = nil
        saveFriends()
        refreshFriends()
        Library:Notify(n .. " удалён из друзей", 3)
    end })

    refreshPlayers()
    table.insert(conns, Players.PlayerAdded:Connect(refreshPlayers))
    table.insert(conns, Players.PlayerRemoving:Connect(function() task.defer(refreshPlayers) end))
end

--// ═══════════════════════════════════════════════════════════════════
--// PLAYER ESP (подсветка + имя; друзья — зелёным)
--// ═══════════════════════════════════════════════════════════════════
do
    local PESP = { Enabled = false, Transparency = 0.5, ShowDistance = true, Color = Color3.fromRGB(255, 50, 50) }
    local entries = {}  -- [player] = { char, hl, gui, label }

    local function clearEntry(p)
        local e = entries[p]
        if not e then return end
        if e.hl then e.hl:Destroy() end
        if e.gui then e.gui:Destroy() end
        entries[p] = nil
    end

    local function createEntry(p, char, hrp)
        local hl = Instance.new("Highlight")
        hl.Adornee = char
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.OutlineTransparency = 0
        hl.Parent = char

        local gui = Instance.new("BillboardGui")
        gui.Adornee = hrp
        gui.AlwaysOnTop = true
        gui.Size = UDim2.fromOffset(220, 20)
        gui.StudsOffset = Vector3.new(0, 3.5, 0)
        gui.Parent = hrp

        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Size = UDim2.fromScale(1, 1)
        label.Font = Enum.Font.GothamBold
        label.TextSize = 14
        label.TextStrokeTransparency = 0.4
        label.Parent = gui

        entries[p] = { char = char, hl = hl, gui = gui, label = label }
        return entries[p]
    end

    local function update()
        for p, e in pairs(entries) do
            if not PESP.Enabled or p.Parent ~= Players or p.Character ~= e.char or not e.char.Parent then
                clearEntry(p)
            end
        end
        if not PESP.Enabled then return end

        local myChar = LocalPlayer.Character
        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local char = p.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if char and hrp then
                    local e = entries[p] or createEntry(p, char, hrp)
                    local color = isFriend(p) and FRIEND_COLOR or PESP.Color
                    e.hl.FillColor = color
                    e.hl.OutlineColor = color
                    e.hl.FillTransparency = PESP.Transparency
                    e.label.TextColor3 = color
                    if PESP.ShowDistance and myHrp then
                        local blocks = math.floor((hrp.Position - myHrp.Position).Magnitude / BLOCK_SIZE + 0.5)
                        e.label.Text = string.format("%s [%d бл]", p.Name, blocks)
                    else
                        e.label.Text = p.Name
                    end
                end
            end
        end
    end

    local last = 0
    table.insert(conns, RunService.Heartbeat:Connect(function()
        local now = os.clock()
        if now - last < 0.1 then return end
        last = now
        update()
    end))

    local prevUnload = Library.Unload
    function Library:Unload()
        PESP.Enabled = false
        for p in pairs(entries) do clearEntry(p) end
        prevUnload(self)
    end

    local rgb = { r = 255, g = 50, b = 50 }
    local function applyColor() PESP.Color = Color3.fromRGB(rgb.r, rgb.g, rgb.b) end

    local Sec = Visuals:AddSection("Игроки", "Left")
    local m = Sec:AddModule({
        Name = "Player ESP",
        Default = false,
        Callback = function(state)
            PESP.Enabled = state
            update()
        end,
    })
    m:AddSlider({ Name = "Прозрачность", Min = 0, Max = 1, Default = PESP.Transparency, Increment = 0.05,
        Callback = function(v) PESP.Transparency = v end })
    m:AddToggle({ Name = "Показывать расстояние", Default = true,
        Callback = function(v) PESP.ShowDistance = v end })
    m:AddSlider({ Name = "Враги R", Min = 0, Max = 255, Default = rgb.r, Increment = 1,
        Callback = function(v) rgb.r = v; applyColor() end })
    m:AddSlider({ Name = "Враги G", Min = 0, Max = 255, Default = rgb.g, Increment = 1,
        Callback = function(v) rgb.g = v; applyColor() end })
    m:AddSlider({ Name = "Враги B", Min = 0, Max = 255, Default = rgb.b, Increment = 1,
        Callback = function(v) rgb.b = v; applyColor() end })
end


--// ═══════════════════════════════════════════════════════════════════
--// SPEED (вкладка "Движение")
--// ═══════════════════════════════════════════════════════════════════
do
    local Speed = { Enabled = false, Value = 32, Mode = "WalkSpeed" }
    local lastHum, defaultSpeed

    local function restore()
        if lastHum and defaultSpeed then
            pcall(function() lastHum.WalkSpeed = defaultSpeed end)
        end
        lastHum, defaultSpeed = nil, nil
    end

    table.insert(conns, RunService.Heartbeat:Connect(function(dt)
        if not Speed.Enabled then return end
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not (hum and hrp) then return end

        if hum ~= lastHum then
            lastHum = hum
            defaultSpeed = hum.WalkSpeed
        end

        if Speed.Mode == "WalkSpeed" then
            hum.WalkSpeed = Speed.Value
        else
            -- CFrame: обычная скорость остаётся, лишнее добавляем смещением
            hum.WalkSpeed = defaultSpeed
            local extra = Speed.Value - defaultSpeed
            local dir = hum.MoveDirection
            if extra > 0 and dir.Magnitude > 0 then
                hrp.CFrame = hrp.CFrame + dir * extra * dt
            end
        end
    end))

    local prevUnload = Library.Unload
    function Library:Unload()
        Speed.Enabled = false
        restore()
        prevUnload(self)
    end

    local Sec = Movement:AddSection("Передвижение", "Left")
    local m = Sec:AddModule({
        Name = "Speed",
        Default = false,
        Callback = function(state)
            Speed.Enabled = state
            if not state then restore() end
        end,
    })
    m:AddSlider({ Name = "Скорость", Min = 1, Max = 200, Default = Speed.Value, Increment = 1, Suffix = " st/s",
        Callback = function(v) Speed.Value = v end })
    m:AddDropdown({ Name = "Режим", Options = { "WalkSpeed", "CFrame" }, Default = Speed.Mode,
        Callback = function(v)
            if v ~= Speed.Mode then restore() end
            Speed.Mode = v or "WalkSpeed"
        end })
    m:AddKeybind({ Name = "Бинд" })
end

--// ═══════════════════════════════════════════════════════════════════
--// ТЕЛЕПОРТ К ИГРОКУ (вкладка "Движение")
--// ═══════════════════════════════════════════════════════════════════
do
    local Sec = Movement:AddSection("Телепорт", "Right")
    local playerDD = Sec:AddDropdown({ Name = "Игрок", Options = {}, NoFlag = true })

    local function refresh()
        local names = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then table.insert(names, p.Name) end
        end
        table.sort(names)
        playerDD:Refresh(names)
        if playerDD.Value and not table.find(names, playerDD.Value) then playerDD:Set(nil, true) end
    end

    Sec:AddButton({ Name = "Телепортироваться", Callback = function()
        local name = playerDD.Value
        if not name then Library:Notify("Выбери игрока в списке", 3) return end
        local target = Players:FindFirstChild(name)
        local tChar = target and target.Character
        local tHrp = tChar and tChar:FindFirstChild("HumanoidRootPart")
        local myChar = LocalPlayer.Character
        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not (tHrp and myHrp) then Library:Notify("Игрок или твой персонаж недоступен", 3) return end
        myHrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, 3)  -- на 3 стада позади цели
        Library:Notify("Телепорт к " .. name, 2)
    end })
    Sec:AddButton({ Name = "Обновить список", Callback = refresh })

    refresh()
    table.insert(conns, Players.PlayerAdded:Connect(refresh))
    table.insert(conns, Players.PlayerRemoving:Connect(function() task.defer(refresh) end))
end

--// ═══════════════════════════════════════════════════════════════════
--// TARGET HUD (вкладка "Визуалы"): аватар, ник, HP, полоска; двигается мышью, если не залочен
--// ═══════════════════════════════════════════════════════════════════
do
    local HUD = { Enabled = false, Locked = false }
    local HUD_FILE = SAVE_DIR .. "/hud.json"
    local TweenService = game:GetService("TweenService")
    local W, H = 250, 74

    local function viewport()
        local cam = workspace.CurrentCamera
        return cam and cam.ViewportSize or Vector2.new(1280, 720)
    end

    -- позиция (сохраняется в blockcraft/hud.json)
    local vp = viewport()
    local posX, posY = vp.X / 2 + 80, vp.Y / 2 + 60
    if fsOK() then
        pcall(function()
            if isfile(HUD_FILE) then
                local d = HttpService:JSONDecode(readfile(HUD_FILE))
                posX, posY = tonumber(d.x) or posX, tonumber(d.y) or posY
            end
        end)
    end
    posX = math.clamp(posX, 0, math.max(vp.X - W, 0))
    posY = math.clamp(posY, 0, math.max(vp.Y - H, 0))

    local function savePos()
        if not fsOK() then return end
        pcall(function()
            if not isfolder(SAVE_DIR) then makefolder(SAVE_DIR) end
            writefile(HUD_FILE, HttpService:JSONEncode({ x = posX, y = posY }))
        end)
    end

    local function make(class, props, children)
        local o = Instance.new(class)
        for k, v in pairs(props) do o[k] = v end
        for _, c in ipairs(children or {}) do c.Parent = o end
        return o
    end
    local function corner(r) return make("UICorner", { CornerRadius = UDim.new(0, r) }) end

    local frame = make("Frame", {
        Name = "TargetHUD", Size = UDim2.fromOffset(W, H), Position = UDim2.fromOffset(posX, posY),
        BackgroundColor3 = Theme.Background, Visible = false, Parent = Library.Gui,
    }, { corner(12), make("UIStroke", { Color = Theme.Stroke, Thickness = 1 }) })

    local avatar = make("ImageLabel", {
        Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(40, 40),
        BackgroundColor3 = Theme.Field, Image = "", Parent = frame,
    }, { corner(8) })
    local nameLbl = make("TextLabel", {
        Position = UDim2.fromOffset(60, 10), Size = UDim2.new(1, -70, 0, 20), BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = Theme.Text, Text = "Target",
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
    })
    local hpLbl = make("TextLabel", {
        Position = UDim2.fromOffset(60, 31), Size = UDim2.new(1, -70, 0, 18), BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = Theme.SubText, Text = "HP / 20,0",
        TextXAlignment = Enum.TextXAlignment.Left, Parent = frame,
    })
    local track = make("Frame", {
        Position = UDim2.fromOffset(10, 58), Size = UDim2.new(1, -20, 0, 6),
        BackgroundColor3 = Theme.Off, BorderSizePixel = 0, Parent = frame,
    }, { corner(3) })
    local trail = make("Frame", {            -- "потерянная" часть полоски, догоняет с задержкой
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.7, BorderSizePixel = 0, Parent = track,
    }, { corner(3) })
    local fill = make("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
        ZIndex = 2, Parent = track,
    }, { corner(3) })
    local hit = make("TextButton", {         -- слой для перетаскивания
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
        ZIndex = 10, Visible = false, Parent = frame,
    })

    -- перетаскивание
    local dragging, dragStart, startX, startY = false, nil, 0, 0
    hit.InputBegan:Connect(function(i)
        if not HUD.Locked and IsPress(i) then
            dragging = true
            dragStart = i.Position
            startX, startY = posX, posY
        end
    end)
    Connect(UIS.InputChanged, function(i)
        if dragging and IsMove(i) then
            local d = i.Position - dragStart
            local v = viewport()
            posX = math.clamp(startX + d.X, 0, math.max(v.X - W, 0))
            posY = math.clamp(startY + d.Y, 0, math.max(v.Y - H, 0))
            frame.Position = UDim2.fromOffset(posX, posY)
        end
    end)
    Connect(UIS.InputEnded, function(i)
        if dragging and IsPress(i) then
            dragging = false
            savePos()
        end
    end)

    local shownId, lastRatio = nil, 1
    local function fmt(n) return (string.format("%.1f", n):gsub("%.", ",")) end

    local function setBar(ratio)
        ratio = math.clamp(ratio, 0, 1)
        if ratio == lastRatio then return end
        TweenService:Create(fill, TweenInfo.new(0.15, Enum.EasingStyle.Quad), { Size = UDim2.fromScale(ratio, 1) }):Play()
        if ratio < lastRatio then
            TweenService:Create(trail, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.2),
                { Size = UDim2.fromScale(ratio, 1) }):Play()
        else
            trail.Size = UDim2.fromScale(ratio, 1)
        end
        lastRatio = ratio
    end

    table.insert(conns, RunService.Heartbeat:Connect(function()
        hit.Visible = frame.Visible and not HUD.Locked
        if not HUD.Enabled then frame.Visible = false return end

        local p, char = TargetState.Player, TargetState.Char
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if p and hum then
            frame.Visible = true
            nameLbl.Text = p.Name
            if shownId ~= p.UserId then
                shownId = p.UserId
                avatar.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=100&h=100", p.UserId)
                lastRatio = -1  -- сброс полоски под нового игрока
                fill.Size = UDim2.fromScale(1, 1); trail.Size = UDim2.fromScale(1, 1)
            end
            local maxHp = math.max(hum.MaxHealth, 1)
            hpLbl.Text = "HP / " .. fmt(hum.Health)
            if lastRatio == -1 then
                lastRatio = math.clamp(hum.Health / maxHp, 0, 1)
                fill.Size = UDim2.fromScale(lastRatio, 1); trail.Size = UDim2.fromScale(lastRatio, 1)
            else
                setBar(hum.Health / maxHp)
            end
        else
            -- нет цели: HUD остаётся на экране с заглушкой (и при закрытом меню)
            frame.Visible = true
            nameLbl.Text = "Target"
            hpLbl.Text = "HP / 20,0"
            avatar.Image = ""
            shownId = nil
            lastRatio = 1
            fill.Size = UDim2.fromScale(1, 1); trail.Size = UDim2.fromScale(1, 1)
        end
    end))

    local Sec = Visuals:AddSection("Target HUD", "Right")
    local m = Sec:AddModule({
        Name = "Target HUD",
        Default = false,
        Callback = function(state)
            HUD.Enabled = state
            TargetState.WantHud = state
        end,
    })
    m:AddToggle({ Name = "Lock HUD", Default = false,
        Callback = function(v)
            HUD.Locked = v
            dragging = false
            if v then savePos() end
        end })
end

--// ═══════════════════════════════════════════════════════════════════
--// 3RD PERSON — вид сверху под углом (вкладка "Визуалы")
--// ═══════════════════════════════════════════════════════════════════
do
    local TP = { Enabled = false, Distance = 14, Angle = 45 }
    local BIND = "NurLib_3rdPerson"
    local saved  -- исходные настройки камеры

    local function restore()
        pcall(function() RunService:UnbindFromRenderStep(BIND) end)
        if saved then
            pcall(function()
                LocalPlayer.CameraMode = saved.mode
                LocalPlayer.CameraMinZoomDistance = saved.min
                LocalPlayer.CameraMaxZoomDistance = saved.max
            end)
            saved = nil
        end
    end

    local function step()
        local cam = workspace.CurrentCamera
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not (cam and hrp) then return end

        -- игра может каждый кадр возвращать первое лицо, поэтому перезаписываем
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        LocalPlayer.CameraMinZoomDistance = TP.Distance
        LocalPlayer.CameraMaxZoomDistance = TP.Distance

        -- горизонтальный поворот берём у обычной камеры (мышь крутит как обычно),
        -- наклон фиксируем: камера над персонажем и смотрит вниз
        local look = cam.CFrame.LookVector
        local flat = Vector3.new(look.X, 0, look.Z)
        if flat.Magnitude < 1e-3 then return end
        flat = flat.Unit

        local pitch = math.rad(TP.Angle)
        local focus = hrp.Position + Vector3.new(0, 2, 0)
        local offset = (-flat * math.cos(pitch) + Vector3.new(0, math.sin(pitch), 0)) * TP.Distance
        cam.CFrame = CFrame.lookAt(focus + offset, focus)
    end

    local function enable()
        saved = saved or {
            mode = LocalPlayer.CameraMode,
            min = LocalPlayer.CameraMinZoomDistance,
            max = LocalPlayer.CameraMaxZoomDistance,
        }
        pcall(function() RunService:UnbindFromRenderStep(BIND) end)
        -- приоритет после стандартной камеры Roblox, чтобы наш CFrame был последним
        RunService:BindToRenderStep(BIND, Enum.RenderPriority.Camera.Value + 1, step)
    end

    local prevUnload = Library.Unload
    function Library:Unload()
        TP.Enabled = false
        restore()
        prevUnload(self)
    end

    local Sec = Visuals:AddSection("Камера", "Right")
    local m = Sec:AddModule({
        Name = "3rd Person",
        Default = false,
        Callback = function(state)
            TP.Enabled = state
            if state then enable() else restore() end
        end,
    })
    m:AddSlider({ Name = "Дистанция", Min = 3, Max = 60, Default = TP.Distance, Increment = 1, Suffix = " st",
        Callback = function(v) TP.Distance = v end })
    m:AddSlider({ Name = "Угол сверху", Min = 10, Max = 89, Default = TP.Angle, Increment = 1, Suffix = "°",
        Callback = function(v) TP.Angle = v end })
    m:AddKeybind({ Name = "Бинд" })
end

--// ═══════════════════════════════════════════════════════════════════
--// NO SUFFOCATION — блокируем отправку урона от удушья (GameRemotes.Demo)
--// Хук ставится ТОЛЬКО когда ты сам включаешь модуль (не при запуске скрипта),
--// и не через __namecall: игра кикает за него (Error 267, namecallInstance detector).
--// ═══════════════════════════════════════════════════════════════════
local Guard = { Suffocation = false, Installed = false }

local function installSuffocationHook()
    if Guard.Installed then return true end
    local ok = pcall(function()
        assert(hookfunction, "no hookfunction")
        local wrap = newcclosure or function(f) return f end
        local probe = Instance.new("RemoteEvent")
        local old
        old = hookfunction(probe.FireServer, wrap(function(self, ...)
            if Guard.Suffocation and typeof(self) == "Instance" and self.Name == "Demo" then
                local args = { ... }
                if args[2] == "suffocation" then return end  -- урон от удушья не отправляется
            end
            return old(self, ...)
        end))
        probe:Destroy()
    end)
    Guard.Installed = ok
    return ok
end

--// ═══════════════════════════════════════════════════════════════════
--// ORE FARM + WEBHOOK-ОТЧЁТЫ (вкладка "Фарм")
--// ═══════════════════════════════════════════════════════════════════
do
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local FARM_OFFSET  = Vector3.new(0, BLOCK_SIZE, BLOCK_SIZE)  -- ◄◄ где стоять относительно руды (над ней и чуть сбоку)
    -- Ломание: зажимаем ЛКМ и наводим камеру на руду, дальше игра сама отправляет BreakBlock/Accept.

    local ICONS = { CoalOre = "⚫", DiamondOre = "💎", GoldOre = "🟡", RubyOre = "🔴", SteelOre = "⚪", SapphireOre = "🔵" }

    local Farm = {
        Enabled = false,
        Ores = { DiamondOre = true, GoldOre = true, RubyOre = true, SapphireOre = true },
        ClickMode = "VirtualInput", Timeout = 8, HpLow = 40, HpFull = 90, PickSlot = 0, FoodSlot = 2, Debug = false,
    }
    local Web = { Url = "", Send = true, Interval = 60 }

    local session, allTime, pending = {}, {}, {}
    local skip = setmetatable({}, { __mode = "k" })
    local token = 0
    local farmModule
    local lastFlush = os.clock()

    --// ───────────── статистика (blockcraft/farm_stats.json) ─────────────
    local STATS_FILE = SAVE_DIR .. "/farm_stats.json"
    local function loadStats()
        if not fsOK() then return end
        pcall(function()
            if isfile(STATS_FILE) then
                for k, v in pairs(HttpService:JSONDecode(readfile(STATS_FILE))) do allTime[k] = tonumber(v) or 0 end
            end
        end)
    end
    local function saveStats()
        if not fsOK() then return end
        pcall(function()
            if not isfolder(SAVE_DIR) then makefolder(SAVE_DIR) end
            writefile(STATS_FILE, HttpService:JSONEncode(allTime))
        end)
    end
    loadStats()

    local function record(name)
        session[name] = (session[name] or 0) + 1
        allTime[name] = (allTime[name] or 0) + 1
        pending[name] = (pending[name] or 0) + 1
    end

    --// ───────────── вебхук ─────────────
    local function labelOf(k)
        local o = OreConfig.Ores[k]
        return o and o.Label or k
    end
    local function lines(tbl)
        local keys = {}
        for k in pairs(tbl) do table.insert(keys, k) end
        table.sort(keys)
        local out = {}
        for _, k in ipairs(keys) do
            table.insert(out, string.format("%s %s ×%d", ICONS[k] or "▪️", labelOf(k), tbl[k]))
        end
        return #out > 0 and table.concat(out, "\n") or "—"
    end

    local function buildEmbed(title, period, desc)
        return {
            title = title,
            description = desc,
            color = 16416882,
            fields = {
                { name = "⛏️ Добыто за период", value = lines(period), inline = false },
                { name = "📦 За сессию",        value = lines(session), inline = true },
                { name = "🏆 Всего",            value = lines(allTime), inline = true },
            },
            footer = { text = "NurLib • " .. LocalPlayer.Name },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        }
    end

    local function validUrl(u)
        return u:match("^https://discord%.com/api/webhooks/") or u:match("^https://discordapp%.com/api/webhooks/")
            or u:match("^https://ptb%.discord%.com/api/webhooks/") or u:match("^https://canary%.discord%.com/api/webhooks/")
    end

    local function post(embed, silent)
        local url = (Web.Url or ""):gsub("%s", "")
        if url == "" then
            if not silent then Library:Notify("Вставь ссылку вебхука", 3) end
            return false
        end
        if not validUrl(url) then
            if not silent then Library:Notify("Это не ссылка Discord-вебхука", 3) end
            return false
        end
        local req = request or http_request or (syn and syn.request)
        if not req then
            if not silent then Library:Notify("Экзекутор не поддерживает request", 3) end
            return false
        end
        local ok, res = pcall(req, {
            Url = url, Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode({ embeds = { embed } }),
        })
        local code = ok and type(res) == "table" and res.StatusCode
        if not (code and code >= 200 and code < 300) then
            local body = (ok and type(res) == "table" and res.Body) or tostring(res)
            if Farm.Debug then print("[Webhook] ошибка", code, body) end
            if not silent then
                if tostring(body):find("thread") then
                    Library:Notify("Форум-канал: добавь ?thread_id=ID к ссылке вебхука", 5)
                else
                    Library:Notify("Вебхук: ошибка " .. tostring(code or "запроса"), 4)
                end
            end
            return false
        end
        return true
    end

    local function flush()
        local total = 0
        for _, n in pairs(pending) do total += n end
        lastFlush = os.clock()
        if total == 0 then return end
        saveStats()
        if not Web.Send then pending = {} return end
        local snap = pending
        pending = {}
        task.spawn(function()
            if not post(buildEmbed("⛏️ Ore Farm", snap), true) then
                for k, n in pairs(snap) do pending[k] = (pending[k] or 0) + n end  -- вернуть, отправим позже
            end
        end)
    end

    table.insert(conns, RunService.Heartbeat:Connect(function()
        if Web.Send and os.clock() - lastFlush >= Web.Interval then flush() end
    end))

    --// ───────────── игровые действия ─────────────
    local function remote(name)
        local gr = ReplicatedStorage:FindFirstChild("GameRemotes")
        return gr and gr:FindFirstChild(name)
    end
    local function myRoot()
        local c = LocalPlayer.Character
        return c and c:FindFirstChild("HumanoidRootPart")
    end
    local function hpPercent()
        local c = LocalPlayer.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if not h or h.MaxHealth <= 0 or h.Health <= 0 then return nil end
        return h.Health / h.MaxHealth * 100
    end
    local function tpTo(pos)
        local hrp = myRoot()
        if not hrp then return end
        hrp.CFrame = CFrame.new(pos)
        hrp.AssemblyLinearVelocity = Vector3.zero
    end
    local function changeSlot(n)
        local r = remote("ChangeSlot")
        if r then pcall(function() r:InvokeServer(n) end) end
    end
    local function eat(slot)
        local r = remote("ConsumeItem")
        local inv = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Inventory")
        if r and inv then pcall(function() r:InvokeServer(inv, slot) end) end
    end
    --// зажатие ЛКМ + наведение камеры на руду
    local VIM = game:GetService("VirtualInputManager")
    local AIM_BIND = "NurLib_FarmAim"
    local holding, aimTarget = false, nil

    local function lmb(down)
        if down == holding then return end
        holding = down
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(800, 600)
        if Farm.ClickMode == "mouse1press" and mouse1press and mouse1release then
            pcall(down and mouse1press or mouse1release)
        else
            pcall(function() VIM:SendMouseButtonEvent(vp.X / 2, vp.Y / 2, 0, down, game, 0) end)
        end
    end

    local function aimStep()
        if not aimTarget then return end
        local cam = workspace.CurrentCamera
        if cam then cam.CFrame = CFrame.lookAt(cam.CFrame.Position, aimTarget) end
    end

    local function stopInput()
        lmb(false)
        aimTarget = nil
        pcall(function() RunService:UnbindFromRenderStep(AIM_BIND) end)
    end

    -- "наверх": точка на поверхности над текущим местом (луч сверху вниз)
    local function surfacePos(hrp)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { LocalPlayer.Character }
        local p = hrp.Position
        local res = workspace:Raycast(Vector3.new(p.X, 2000, p.Z), Vector3.new(0, -4000, 0), params)
        if res then return res.Position + Vector3.new(0, 4, 0) end
        return p + Vector3.new(0, 80, 0)
    end

    local function healUp(my)
        local hrp = myRoot()
        if not hrp then return end
        local pos = surfacePos(hrp)
        local fails = 0
        while Farm.Enabled and my == token do
            local hp = hpPercent()
            if not hp then return end
            if hp >= Farm.HpFull then break end
            tpTo(pos)
            changeSlot(Farm.FoodSlot)
            eat(Farm.FoodSlot)
            task.wait(1.2)
            local after = hpPercent() or hp
            if after <= hp then
                fails += 1
                if fails >= 6 then
                    Library:Notify("Нет еды или HP не растёт — фарм остановлен", 5)
                    if farmModule then farmModule:Set(false) end
                    return
                end
            else
                fails = 0
            end
        end
        changeSlot(Farm.PickSlot)
    end

    local function nearestOre()
        local hrp = myRoot()
        if not hrp then return end
        local best, bestD
        local now = os.clock()
        for _, chunk in ipairs(Blocks:GetChildren()) do
            for _, obj in ipairs(chunk:GetChildren()) do
                if Farm.Ores[obj.Name] and (not skip[obj] or skip[obj] < now) and obj:IsA("PVInstance") then
                    local d = (obj:GetPivot().Position - hrp.Position).Magnitude
                    if not bestD or d < bestD then best, bestD = obj, d end
                end
            end
        end
        return best
    end

    local function mineOre(ore, my)
        local orePos = ore:GetPivot().Position
        local hold = orePos + FARM_OFFSET
        local name, start = ore.Name, os.clock()
        if Farm.Debug then print("[Ore Farm] ломаем", name, orePos) end

        aimTarget = orePos
        tpTo(hold)
        task.wait(0.15)   -- даём камере и игре "увидеть" блок
        lmb(true)         -- зажимаем ЛКМ
        while Farm.Enabled and my == token and ore:IsDescendantOf(workspace) and os.clock() - start < Farm.Timeout do
            local hp = hpPercent()
            if hp and hp < Farm.HpLow then break end  -- мало HP: главный цикл отправит лечиться
            tpTo(hold)
            task.wait(0.1)
        end
        lmb(false)        -- отпускаем ЛКМ
        aimTarget = nil

        if not ore:IsDescendantOf(workspace) then
            record(name)
        elseif Farm.Enabled and my == token and os.clock() - start >= Farm.Timeout then
            skip[ore] = os.clock() + 60  -- не сломалась за таймаут: пропускаем на минуту
        end
    end

    local function startFarm()
        token += 1
        local my = token
        pcall(function() RunService:UnbindFromRenderStep(AIM_BIND) end)
        RunService:BindToRenderStep(AIM_BIND, Enum.RenderPriority.Camera.Value + 2, aimStep)
        task.spawn(function()
            changeSlot(Farm.PickSlot)
            local lastIdle = 0
            while Farm.Enabled and my == token do
                if not myRoot() then
                    task.wait(0.5)
                    continue
                end
                local hp = hpPercent()
                if hp and hp < Farm.HpLow then healUp(my) end
                if not (Farm.Enabled and my == token) then break end
                local ore = nearestOre()
                if not ore then
                    if os.clock() - lastIdle > 10 then
                        lastIdle = os.clock()
                        Library:Notify("Ore Farm: выбранных руд в загруженных чанках нет", 3)
                    end
                    task.wait(1)
                else
                    mineOre(ore, my)
                end
                task.wait()
            end
        end)
    end

    local prevUnload = Library.Unload
    function Library:Unload()
        Farm.Enabled = false
        Guard.Suffocation = false
        token += 1
        stopInput()
        saveStats()
        prevUnload(self)
    end

    --// ───────────── меню ─────────────
    local Sec = FarmTab:AddSection("Ore Farm", "Left")
    farmModule = Sec:AddModule({
        Name = "Ore Farm",
        Default = false,
        Callback = function(state)
            Farm.Enabled = state
            if state then
                startFarm()
            else
                token += 1
                stopInput()
                flush()
                saveStats()
            end
        end,
    })
    for _, name in ipairs(OreConfig.Order) do
        farmModule:AddToggle({ Name = "Фармить: " .. labelOf(name), Default = Farm.Ores[name] or false,
            Callback = function(v) Farm.Ores[name] = v end })
    end
    farmModule:AddDropdown({ Name = "Метод клика", Options = { "VirtualInput", "mouse1press" }, Default = Farm.ClickMode,
        Callback = function(v) Farm.ClickMode = v or "VirtualInput" end })
    farmModule:AddSlider({ Name = "Таймаут руды", Min = 2, Max = 30, Default = Farm.Timeout, Increment = 1, Suffix = " с",
        Callback = function(v) Farm.Timeout = v end })
    farmModule:AddSlider({ Name = "Лечиться при HP ниже", Min = 10, Max = 90, Default = Farm.HpLow, Increment = 1, Suffix = "%",
        Callback = function(v) Farm.HpLow = v end })
    farmModule:AddSlider({ Name = "Есть до HP", Min = 50, Max = 100, Default = Farm.HpFull, Increment = 1, Suffix = "%",
        Callback = function(v) Farm.HpFull = v end })
    farmModule:AddSlider({ Name = "Слот кирки", Min = 0, Max = 8, Default = Farm.PickSlot, Increment = 1,
        Callback = function(v) Farm.PickSlot = v end })
    farmModule:AddSlider({ Name = "Слот еды", Min = 0, Max = 8, Default = Farm.FoodSlot, Increment = 1,
        Callback = function(v) Farm.FoodSlot = v end })
    farmModule:AddToggle({ Name = "Debug (print в консоль)", Default = false,
        Callback = function(v) Farm.Debug = v end })

    local Prot = FarmTab:AddSection("Защита", "Right")
    local sufMod
    sufMod = Prot:AddModule({
        Name = "No Suffocation",
        Default = false,
        Callback = function(state)
            if state then
                if not installSuffocationHook() then
                    Library:Notify("No Suffocation не включён: экзекутор не поддерживает hookfunction", 5)
                    Guard.Suffocation = false
                    sufMod:Set(false, true)
                    return
                end
                Library:Notify("No Suffocation использует хук. Если игра кикнет — не включай его", 6)
            end
            Guard.Suffocation = state
        end,
    })

    local WSec = FarmTab:AddSection("Webhook", "Right")
    WSec:AddTextbox({ Name = "Webhook URL", Flag = "Webhook.Url",
        Placeholder = "Ссылка вебхука (для форума: ...?thread_id=ID)",
        Callback = function(t) Web.Url = t end })
    WSec:AddToggle({ Name = "Отправлять отчёты", Flag = "Webhook.Send", Default = true,
        Callback = function(v) Web.Send = v end })
    WSec:AddSlider({ Name = "Интервал отправки", Flag = "Webhook.Interval", Min = 10, Max = 600, Default = Web.Interval,
        Increment = 5, Suffix = " с", Callback = function(v) Web.Interval = v end })
    WSec:AddButton({ Name = "Тест вебхука", Callback = function()
        task.spawn(function()
            if post(buildEmbed("✅ Тест вебхука", {}, "Вебхук подключён, отчёты о добыче будут приходить сюда."), false) then
                Library:Notify("Тест отправлен", 3)
            end
        end)
    end })
    WSec:AddButton({ Name = "Отправить отчёт сейчас", Callback = function()
        task.spawn(function()
            local snap = pending
            if post(buildEmbed("⛏️ Ore Farm", snap), false) then
                pending = {}
                lastFlush = os.clock()
                saveStats()
                Library:Notify("Отчёт отправлен", 3)
            end
        end)
    end })
end
