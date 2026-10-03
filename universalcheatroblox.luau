-- language: Luau, executor: Nexomia, universal Roblox build
-- Vysesaint — 2D box + bone ESP + snapline + name + distance.
-- Players AND NPCs/bots. R15 and R6 rigs. FOV shared by aimbot + silent aim.
-- Anti-AFK in Misc. INSERT or DELETE toggles menu.

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local Workspace         = game:GetService("Workspace")
local VirtualUser       = game:GetService("VirtualUser")
local Camera            = Workspace.CurrentCamera
local LocalPlayer       = Players.LocalPlayer
local Mouse             = LocalPlayer:GetMouse()

-- ============ STATE ============
local Connections = {}
local function track(c) table.insert(Connections, c); return c end
local KILLED = false

-- ============ CONFIG ============
local Config = {
    esp = {
        enabled = true, box2d = true, bone = true, snapline = true,
        name = true, distance = true,
        botEsp = true, teamCheck = false, maxDistance = 3000,
        colors = {
            box      = Color3.fromRGB(255, 96, 118),
            bone     = Color3.fromRGB(255, 96, 118),
            snapline = Color3.fromRGB(255, 96, 118),
            name     = Color3.fromRGB(240, 240, 245),
            distance = Color3.fromRGB(150, 150, 168),
            bot      = Color3.fromRGB(240, 200, 40),
        },
    },
    aimbot = {
        enabled = false, part = "Head", smooth = 0.15, fov = 120,
        key = "RightClick", mode = "Hold", showFov = true,
    },
    silent = { enabled = false, part = "Head" },
    misc = {
        antiAfk = true,
    },
}

local COL = {
    bg      = Color3.fromRGB(10, 10, 14),
    bg2     = Color3.fromRGB(16, 16, 22),
    panel   = Color3.fromRGB(22, 22, 30),
    panel2  = Color3.fromRGB(30, 30, 40),
    line    = Color3.fromRGB(44, 44, 58),
    accent  = Color3.fromRGB(255, 32, 64),
    accent2 = Color3.fromRGB(255, 96, 118),
    text    = Color3.fromRGB(240, 240, 245),
    subtext = Color3.fromRGB(150, 150, 168),
    discord = Color3.fromRGB(88, 101, 242),
}

-- ============ ACCENT REGISTRY ============
local AccentBindings = {}
local function bindAccent(inst, prop)
    table.insert(AccentBindings, { inst = inst, prop = prop })
    inst[prop] = COL.accent
    return inst
end

local function setAccent(color)
    COL.accent = color
    COL.accent2 = Color3.new(
        math.min(color.R + 0.18, 1),
        math.min(color.G + 0.06, 1),
        math.min(color.B + 0.10, 1)
    )
    for _, b in ipairs(AccentBindings) do
        pcall(function() b.inst[b.prop] = COL.accent end)
    end
end

-- ============ UI ROOT ============
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Vysesaint"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() ScreenGui.Parent = gethui() end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 500, 0, 340)
Main.Position = UDim2.new(0.5, -250, 0.5, -170)
Main.BackgroundColor3 = COL.bg
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local MainGrad = Instance.new("UIGradient")
MainGrad.Rotation = 90
MainGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, COL.bg2),
    ColorSequenceKeypoint.new(1, COL.bg),
})
MainGrad.Parent = Main

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = COL.accent
MainStroke.Thickness = 1
MainStroke.Transparency = 0.55
MainStroke.Parent = Main
table.insert(AccentBindings, { inst = MainStroke, prop = "Color" })

local GlowStroke = Instance.new("UIStroke")
GlowStroke.Color = COL.accent
GlowStroke.Thickness = 4
GlowStroke.Transparency = 0.93
GlowStroke.Parent = Main
table.insert(AccentBindings, { inst = GlowStroke, prop = "Color" })

-- ============ HEADER ============
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 44)
Header.BackgroundTransparency = 1
Header.Parent = Main

local Dot = Instance.new("Frame")
Dot.Size = UDim2.new(0, 8, 0, 8)
Dot.Position = UDim2.new(0, 16, 0.5, -4)
Dot.BackgroundColor3 = COL.accent
Dot.BorderSizePixel = 0
Dot.Parent = Header
local DotCorner = Instance.new("UICorner"); DotCorner.CornerRadius = UDim.new(1, 0); DotCorner.Parent = Dot
bindAccent(Dot, "BackgroundColor3")

local TitleBrand = Instance.new("TextLabel")
TitleBrand.Size = UDim2.new(0, 200, 1, 0)
TitleBrand.Position = UDim2.new(0, 30, 0, 0)
TitleBrand.BackgroundTransparency = 1
TitleBrand.Text = "VYVESAINT"
TitleBrand.TextColor3 = COL.text
TitleBrand.Font = Enum.Font.GothamBlack
TitleBrand.TextSize = 16
TitleBrand.TextXAlignment = Enum.TextXAlignment.Left
TitleBrand.Parent = Header

local TitleSub = Instance.new("TextLabel")
TitleSub.Size = UDim2.new(0, 200, 1, 0)
TitleSub.Position = UDim2.new(0, 158, 0, 1)
TitleSub.BackgroundTransparency = 1
TitleSub.Text = "UNIVERSAL"
TitleSub.TextColor3 = COL.accent
TitleSub.Font = Enum.Font.GothamBold
TitleSub.TextSize = 11
TitleSub.TextXAlignment = Enum.TextXAlignment.Left
TitleSub.Parent = Header
bindAccent(TitleSub, "TextColor3")

-- ============ DISCORD BADGE ============
-- Hand-drawn Clyde mascot — blurple rounded face with two eyes.
-- No external asset, so it renders on every executor.
local DiscordBadge = Instance.new("Frame")
DiscordBadge.Size = UDim2.new(0, 128, 0, 22)
DiscordBadge.Position = UDim2.new(1, -222, 0.5, -11)
DiscordBadge.BackgroundColor3 = COL.panel2
DiscordBadge.BackgroundTransparency = 0.15
DiscordBadge.BorderSizePixel = 0
DiscordBadge.Parent = Header

local dbCorner = Instance.new("UICorner"); dbCorner.CornerRadius = UDim.new(0, 5); dbCorner.Parent = DiscordBadge
local dbStroke = Instance.new("UIStroke"); dbStroke.Color = COL.discord; dbStroke.Transparency = 0.55; dbStroke.Parent = DiscordBadge

-- Clyde face — blurple blob
local ClydeBox = Instance.new("Frame")
ClydeBox.Size = UDim2.new(0, 15, 0, 12)
ClydeBox.Position = UDim2.new(0, 5, 0.5, -6)
ClydeBox.BackgroundColor3 = COL.discord
ClydeBox.BorderSizePixel = 0
ClydeBox.Parent = DiscordBadge
local cbCorner = Instance.new("UICorner"); cbCorner.CornerRadius = UDim.new(0, 6); cbCorner.Parent = ClydeBox

-- left eye
local Eye1 = Instance.new("Frame")
Eye1.Size = UDim2.new(0, 3, 0, 3)
Eye1.Position = UDim2.new(0, 3, 0.5, -1.5)
Eye1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Eye1.BorderSizePixel = 0
Eye1.Parent = ClydeBox
local e1c = Instance.new("UICorner"); e1c.CornerRadius = UDim.new(1, 0); e1c.Parent = Eye1

-- right eye
local Eye2 = Instance.new("Frame")
Eye2.Size = UDim2.new(0, 3, 0, 3)
Eye2.Position = UDim2.new(1, -6, 0.5, -1.5)
Eye2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Eye2.BorderSizePixel = 0
Eye2.Parent = ClydeBox
local e2c = Instance.new("UICorner"); e2c.CornerRadius = UDim.new(1, 0); e2c.Parent = Eye2

-- username
local DbText = Instance.new("TextLabel")
DbText.Size = UDim2.new(1, -26, 1, 0)
DbText.Position = UDim2.new(0, 24, 0, 0)
DbText.BackgroundTransparency = 1
DbText.Text = "marky.cool"
DbText.TextColor3 = COL.text
DbText.Font = Enum.Font.GothamBold
DbText.TextSize = 11
DbText.TextXAlignment = Enum.TextXAlignment.Left
DbText.Parent = DiscordBadge

-- ============ HEADER BUTTONS ============
local function makeHeaderBtn(text, isAccent)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 26, 0, 26)
    btn.BackgroundColor3 = isAccent and COL.accent or COL.panel2
    btn.BackgroundTransparency = isAccent and 0.1 or 0.15
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = COL.text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.AutoButtonColor = false
    btn.Parent = Header
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = btn
    local s = Instance.new("UIStroke"); s.Color = isAccent and COL.accent2 or COL.line; s.Transparency = 0.4; s.Parent = btn
    if isAccent then bindAccent(btn, "BackgroundColor3") end
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundTransparency = isAccent and 0 or 0.05 }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundTransparency = isAccent and 0.1 or 0.15 }):Play()
    end)
    return btn
end

local MinBtn = makeHeaderBtn("—", false)
MinBtn.Position = UDim2.new(1, -68, 0.5, -13)

local CloseBtn = makeHeaderBtn("✕", true)
CloseBtn.Position = UDim2.new(1, -36, 0.5, -13)

local HeaderDiv = Instance.new("Frame")
HeaderDiv.Size = UDim2.new(1, -24, 0, 1)
HeaderDiv.Position = UDim2.new(0, 12, 0, 44)
HeaderDiv.BackgroundColor3 = COL.line
HeaderDiv.BorderSizePixel = 0
HeaderDiv.Parent = Main
local DivGrad = Instance.new("UIGradient")
DivGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.5, 0),
    NumberSequenceKeypoint.new(1, 1),
})
DivGrad.Parent = HeaderDiv

-- ============ TAB BAR ============
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -24, 0, 32)
TabBar.Position = UDim2.new(0, 12, 0, 50)
TabBar.BackgroundTransparency = 1
TabBar.Parent = Main
local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Padding = UDim.new(0, 6)
TabLayout.Parent = TabBar

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -24, 1, -94)
ContentArea.Position = UDim2.new(0, 12, 0, 86)
ContentArea.BackgroundTransparency = 1
ContentArea.ClipsDescendants = true
ContentArea.Parent = Main

-- ============ CONTROL FACTORIES ============
local function makePage()
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = COL.accent
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.ScrollingDirection = Enum.ScrollingDirection.Y
    page.Visible = false
    page.Parent = ContentArea
    local ll = Instance.new("UIListLayout")
    ll.Padding = UDim.new(0, 6)
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    ll.Parent = page
    table.insert(AccentBindings, { inst = page, prop = "ScrollBarImageColor3" })
    return page
end

local function Section(parent, text)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 22)
    f.BackgroundTransparency = 1
    f.Parent = parent
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 2, 0, 12)
    bar.Position = UDim2.new(0, 2, 0.5, -6)
    bar.BackgroundColor3 = COL.accent
    bar.BorderSizePixel = 0
    bar.Parent = f
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(1, 0); bc.Parent = bar
    bindAccent(bar, "BackgroundColor3")
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -14, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = string.upper(text)
    lbl.TextColor3 = COL.text
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = f
    return f
end

local function panelRow(parent, h)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, h)
    f.BackgroundColor3 = COL.panel
    f.BackgroundTransparency = 0.15
    f.BorderSizePixel = 0
    f.Parent = parent
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = f
    local s = Instance.new("UIStroke"); s.Color = COL.line; s.Transparency = 0.55; s.Parent = f
    return f
end

local function Toggle(parent, name, default, callback)
    local f = panelRow(parent, 30)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -70, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = COL.text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = f

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 40, 0, 18)
    btn.Position = UDim2.new(1, -54, 0.5, -9)
    btn.BackgroundColor3 = default and COL.accent or COL.panel2
    btn.BackgroundTransparency = 0.05
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = f
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(1, 0); bc.Parent = btn
    local bs = Instance.new("UIStroke"); bs.Color = default and COL.accent2 or COL.line; bs.Transparency = 0.5; bs.Parent = btn
    if default then bindAccent(btn, "BackgroundColor3") end

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = default and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    knob.BackgroundColor3 = COL.text
    knob.BorderSizePixel = 0
    knob.Parent = btn
    local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(1, 0); kc.Parent = knob

    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        local targetPos = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
        local info = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(btn, info, { BackgroundColor3 = state and COL.accent or COL.panel2 }):Play()
        TweenService:Create(knob, info, { Position = targetPos }):Play()
        TweenService:Create(bs, TweenInfo.new(0.18), { Color = state and COL.accent2 or COL.line }):Play()
        callback(state)
    end)
    return f
end

local function Slider(parent, name, min, max, default, callback)
    local f = panelRow(parent, 42)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -120, 0, 16)
    lbl.Position = UDim2.new(0, 14, 0, 3)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = COL.text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = f

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0, 90, 0, 16)
    valLbl.Position = UDim2.new(1, -104, 0, 3)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(default)
    valLbl.TextColor3 = COL.accent2
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 12
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = f
    bindAccent(valLbl, "TextColor3")

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -28, 0, 4)
    bar.Position = UDim2.new(0, 14, 0, 28)
    bar.BackgroundColor3 = COL.panel2
    bar.BorderSizePixel = 0
    bar.Parent = f
    local barc = Instance.new("UICorner"); barc.CornerRadius = UDim.new(1, 0); barc.Parent = bar

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = COL.accent
    fill.BorderSizePixel = 0
    fill.Parent = bar
    local fillc = Instance.new("UICorner"); fillc.CornerRadius = UDim.new(1, 0); fillc.Parent = fill
    bindAccent(fill, "BackgroundColor3")

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 10, 0, 10)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((default - min) / (max - min), 0, 0.5, 0)
    knob.BackgroundColor3 = COL.text
    knob.BorderSizePixel = 0
    knob.ZIndex = 2
    knob.Parent = bar
    local knc = Instance.new("UICorner"); knc.CornerRadius = UDim.new(1, 0); knc.Parent = knob

    local dragging = false
    local function update(input)
        local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * rel)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, 0, 0.5, 0)
        valLbl.Text = tostring(val)
        callback(val)
    end
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; update(i) end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then update(i) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    return f
end

local _openDropdown = nil
local function Dropdown(parent, name, options, default, callback)
    local ROW_H = 32
    local OPT_H = 22
    local listH = #options * OPT_H + 4
    local f = panelRow(parent, ROW_H)
    f.ClipsDescendants = false

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.5, -10, 0, ROW_H)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = COL.text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = f

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 130, 0, 20)
    btn.Position = UDim2.new(1, -144, 0, 6)
    btn.BackgroundColor3 = COL.panel2
    btn.BorderSizePixel = 0
    btn.Text = default
    btn.TextColor3 = COL.text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.AutoButtonColor = false
    btn.ZIndex = 2
    btn.Parent = f
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 6); bc.Parent = btn
    local bs = Instance.new("UIStroke"); bs.Color = COL.line; bs.Transparency = 0.4; bs.Parent = btn

    local caret = Instance.new("TextLabel")
    caret.Size = UDim2.new(0, 14, 0, 20)
    caret.Position = UDim2.new(1, -18, 0, 6)
    caret.BackgroundTransparency = 1
    caret.Text = "▾"
    caret.TextColor3 = COL.accent2
    caret.Font = Enum.Font.GothamBold
    caret.TextSize = 11
    caret.ZIndex = 3
    caret.Parent = f
    bindAccent(caret, "TextColor3")

    local list = Instance.new("Frame")
    list.Size = UDim2.new(0, 130, 0, listH)
    list.Position = UDim2.new(1, -144, 0, ROW_H + 2)
    list.BackgroundColor3 = COL.bg2
    list.BorderSizePixel = 0
    list.Visible = false
    list.ZIndex = 4
    list.Parent = f
    local lc = Instance.new("UICorner"); lc.CornerRadius = UDim.new(0, 6); lc.Parent = list
    local ls = Instance.new("UIStroke"); ls.Color = COL.accent; ls.Transparency = 0.35; ls.Parent = list
    bindAccent(ls, "Color")
    local ll = Instance.new("UIListLayout"); ll.Parent = list

    local open = false
    local function setOpen(v)
        if v and _openDropdown and _openDropdown ~= setOpen then _openDropdown(false) end
        open = v
        list.Visible = v
        f.Size = UDim2.new(1, 0, 0, v and (ROW_H + listH + 4) or ROW_H)
        caret.Text = v and "▴" or "▾"
        if v then _openDropdown = setOpen else _openDropdown = nil end
    end
    btn.MouseButton1Click:Connect(function() setOpen(not open) end)

    for _, opt in ipairs(options) do
        local ob = Instance.new("TextButton")
        ob.Size = UDim2.new(1, -8, 0, OPT_H - 2)
        ob.BackgroundColor3 = COL.accent
        ob.BackgroundTransparency = 1
        ob.BorderSizePixel = 0
        ob.Text = opt
        ob.TextColor3 = COL.text
        ob.Font = Enum.Font.GothamMedium
        ob.TextSize = 11
        ob.AutoButtonColor = false
        ob.ZIndex = 5
        ob.Parent = list
        local obc = Instance.new("UICorner"); obc.CornerRadius = UDim.new(0, 4); obc.Parent = ob
        ob.MouseEnter:Connect(function()
            TweenService:Create(ob, TweenInfo.new(0.1), { BackgroundTransparency = 0.7 }):Play()
        end)
        ob.MouseLeave:Connect(function()
            TweenService:Create(ob, TweenInfo.new(0.1), { BackgroundTransparency = 1 }):Play()
        end)
        ob.MouseButton1Click:Connect(function()
            btn.Text = opt
            setOpen(false)
            callback(opt)
        end)
    end
    return f
end

-- ============ COLOR PRESETS ============
local PRESETS = {
    { name = "Red",    color = Color3.fromRGB(255, 32, 64)   },
    { name = "Orange", color = Color3.fromRGB(255, 128, 32)  },
    { name = "Yellow", color = Color3.fromRGB(240, 200, 40)  },
    { name = "Green",  color = Color3.fromRGB(60, 220, 120)  },
    { name = "Cyan",   color = Color3.fromRGB(60, 200, 240)  },
    { name = "Blue",   color = Color3.fromRGB(80, 130, 255)  },
    { name = "Purple", color = Color3.fromRGB(180, 90, 240)  },
    { name = "Pink",   color = Color3.fromRGB(255, 120, 200) },
    { name = "White",  color = Color3.fromRGB(240, 240, 245) },
    { name = "Gray",   color = Color3.fromRGB(140, 140, 155) },
    { name = "Black",  color = Color3.fromRGB(20, 20, 26)    },
}

local function ColorPicker(parent, name, getColor, setColor)
    local f = panelRow(parent, 30)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 100, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = COL.text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = f

    local pad = Instance.new("Frame")
    pad.Size = UDim2.new(1, -122, 1, 0)
    pad.Position = UDim2.new(0, 118, 0, 0)
    pad.BackgroundTransparency = 1
    pad.Parent = f
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 4)
    layout.Parent = pad

    for _, preset in ipairs(PRESETS) do
        local sw = Instance.new("TextButton")
        sw.Size = UDim2.new(0, 14, 0, 14)
        sw.BackgroundColor3 = preset.color
        sw.BorderSizePixel = 0
        sw.Text = ""
        sw.AutoButtonColor = false
        sw.Parent = pad
        local swc = Instance.new("UICorner"); swc.CornerRadius = UDim.new(1, 0); swc.Parent = sw
        local sws = Instance.new("UIStroke"); sws.Color = COL.line; sws.Transparency = 0.4; sws.Parent = sw
        if preset.color == getColor() then sws.Color = COL.text; sws.Transparency = 0 end
        sw.MouseButton1Click:Connect(function()
            setColor(preset.color)
            for _, child in ipairs(pad:GetChildren()) do
                if child:IsA("TextButton") then
                    local stroke = child:FindFirstChildOfClass("UIStroke")
                    if stroke then
                        if child.BackgroundColor3 == preset.color then
                            stroke.Color = COL.text; stroke.Transparency = 0
                        else
                            stroke.Color = COL.line; stroke.Transparency = 0.4
                        end
                    end
                end
            end
        end)
    end
    return f
end

-- ============ TAB REGISTRY ============
local Tabs = {}
local Pages = {}

local function makeTab(name)
    local page = makePage()
    table.insert(Pages, page)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1/3, -4, 1, 0)
    btn.BackgroundColor3 = COL.panel
    btn.BackgroundTransparency = 0.35
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = TabBar
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 6); bc.Parent = btn
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, -3)
    label.BackgroundTransparency = 1
    label.Text = string.upper(name)
    label.TextColor3 = COL.subtext
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11
    label.Parent = btn
    local underline = Instance.new("Frame")
    underline.Size = UDim2.new(1, -16, 0, 2)
    underline.Position = UDim2.new(0, 8, 1, -3)
    underline.BackgroundColor3 = COL.line
    underline.BorderSizePixel = 0
    underline.Parent = btn
    local uc = Instance.new("UICorner"); uc.CornerRadius = UDim.new(1, 0); uc.Parent = underline
    local tab = { Button = btn, Label = label, Underline = underline, Page = page }
    table.insert(Tabs, tab)
    btn.MouseButton1Click:Connect(function() selectTab(tab) end)
    return tab
end

function selectTab(target)
    for _, p in ipairs(Pages) do p.Visible = (p == target.Page) end
    for _, t in ipairs(Tabs) do
        local active = (t == target)
        t.Underline.BackgroundColor3 = active and COL.accent or COL.line
        t.Label.TextColor3 = active and COL.text or COL.subtext
        t.Button.BackgroundTransparency = active and 0.55 or 0.35
    end
end

local AimTab    = makeTab("Aim")
local VisualTab = makeTab("Visual")
local MiscTab   = makeTab("Misc")

-- ============ AIM PAGE ============
Section(AimTab.Page, "Aimbot")
Toggle(AimTab.Page, "Enable",        Config.aimbot.enabled, function(v) Config.aimbot.enabled = v end)
Toggle(AimTab.Page, "Show FOV Ring", Config.aimbot.showFov, function(v) Config.aimbot.showFov = v end)
Dropdown(AimTab.Page, "Target Part", {"Head","Body","Foot","Root"}, Config.aimbot.part, function(v) Config.aimbot.part = v end)
Dropdown(AimTab.Page, "Activation",  {"RightClick","LeftClick","Shift","E","Q","C","F"}, Config.aimbot.key, function(v) Config.aimbot.key = v end)
Dropdown(AimTab.Page, "Mode",        {"Hold","Toggle"}, Config.aimbot.mode, function(v) Config.aimbot.mode = v end)
Slider(AimTab.Page, "Smooth %", 1, 100, math.floor(Config.aimbot.smooth * 100), function(v) Config.aimbot.smooth = v / 100 end)
Slider(AimTab.Page, "FOV",      10, 800, Config.aimbot.fov, function(v) Config.aimbot.fov = v end)

Section(AimTab.Page, "Silent Aim")
Toggle(AimTab.Page, "Enable", Config.silent.enabled, function(v) Config.silent.enabled = v end)
Dropdown(AimTab.Page, "Target Part", {"Head","Body","Foot","Root"}, Config.silent.part, function(v) Config.silent.part = v end)

-- ============ VISUAL PAGE ============
Section(VisualTab.Page, "ESP")
Toggle(VisualTab.Page, "ESP",        Config.esp.enabled, function(v) Config.esp.enabled = v end)
Toggle(VisualTab.Page, "2D Box",     Config.esp.box2d,   function(v) Config.esp.box2d = v end)
Toggle(VisualTab.Page, "Bone",       Config.esp.bone,    function(v) Config.esp.bone = v end)
Toggle(VisualTab.Page, "Snapline",   Config.esp.snapline,function(v) Config.esp.snapline = v end)
Toggle(VisualTab.Page, "Name",       Config.esp.name,    function(v) Config.esp.name = v end)
Toggle(VisualTab.Page, "Distance",   Config.esp.distance,function(v) Config.esp.distance = v end)
Toggle(VisualTab.Page, "NPC / Bot ESP", Config.esp.botEsp, function(v) Config.esp.botEsp = v end)
Toggle(VisualTab.Page, "Team Check", Config.esp.teamCheck, function(v) Config.esp.teamCheck = v end)
Slider(VisualTab.Page, "Max Distance", 100, 10000, Config.esp.maxDistance, function(v) Config.esp.maxDistance = v end)

-- ============ MISC PAGE ============
Section(MiscTab.Page, "Utility")
Toggle(MiscTab.Page, "Anti-AFK", Config.misc.antiAfk, function(v) Config.misc.antiAfk = v end)

Section(MiscTab.Page, "Accent Color")
local swatchRow = panelRow(MiscTab.Page, 40)
local swatchPad = Instance.new("Frame")
swatchPad.Size = UDim2.new(1, -20, 1, 0)
swatchPad.Position = UDim2.new(0, 10, 0, 0)
swatchPad.BackgroundTransparency = 1
swatchPad.Parent = swatchRow
local spLayout = Instance.new("UIListLayout")
spLayout.FillDirection = Enum.FillDirection.Horizontal
spLayout.VerticalAlignment = Enum.VerticalAlignment.Center
spLayout.Padding = UDim.new(0, 8)
spLayout.Parent = swatchPad

for _, preset in ipairs(PRESETS) do
    local sw = Instance.new("TextButton")
    sw.Size = UDim2.new(0, 22, 0, 22)
    sw.BackgroundColor3 = preset.color
    sw.BorderSizePixel = 0
    sw.Text = ""
    sw.AutoButtonColor = false
    sw.Parent = swatchPad
    local swc = Instance.new("UICorner"); swc.CornerRadius = UDim.new(1, 0); swc.Parent = sw
    local sws = Instance.new("UIStroke"); sws.Color = COL.line; sws.Transparency = 0.3; sws.Parent = sw
    sw.MouseButton1Click:Connect(function()
        setAccent(preset.color)
        for _, t in ipairs(Tabs) do
            t.Underline.BackgroundColor3 = t.Page.Visible and COL.accent or COL.line
        end
    end)
end

Section(MiscTab.Page, "ESP Colors")
ColorPicker(MiscTab.Page, "Box",       function() return Config.esp.colors.box      end, function(c) Config.esp.colors.box = c      end)
ColorPicker(MiscTab.Page, "Bone",      function() return Config.esp.colors.bone     end, function(c) Config.esp.colors.bone = c     end)
ColorPicker(MiscTab.Page, "Snapline",  function() return Config.esp.colors.snapline end, function(c) Config.esp.colors.snapline = c end)
ColorPicker(MiscTab.Page, "Name",      function() return Config.esp.colors.name     end, function(c) Config.esp.colors.name = c     end)
ColorPicker(MiscTab.Page, "Distance",  function() return Config.esp.colors.distance end, function(c) Config.esp.colors.distance = c end)
ColorPicker(MiscTab.Page, "NPC / Bot", function() return Config.esp.colors.bot      end, function(c) Config.esp.colors.bot = c      end)

Section(MiscTab.Page, "Menu Control")
local killRow = panelRow(MiscTab.Page, 42)
local killBtn = Instance.new("TextButton")
killBtn.Size = UDim2.new(1, -20, 0, 30)
killBtn.Position = UDim2.new(0, 10, 0.5, -15)
killBtn.BackgroundColor3 = COL.accent
killBtn.BackgroundTransparency = 0.05
killBtn.BorderSizePixel = 0
killBtn.Text = "DELETE MENU"
killBtn.TextColor3 = COL.text
killBtn.Font = Enum.Font.GothamBold
killBtn.TextSize = 12
killBtn.AutoButtonColor = false
killBtn.Parent = killRow
bindAccent(killBtn, "BackgroundColor3")
local kbc = Instance.new("UICorner"); kbc.CornerRadius = UDim.new(0, 6); kbc.Parent = killBtn
local kbs = Instance.new("UIStroke"); kbs.Color = COL.accent2; kbs.Transparency = 0.35; kbs.Parent = killBtn
bindAccent(kbs, "Color")

selectTab(AimTab)

-- ============ TARGET SCAN ============
local scanCache = {}
local lastScan = 0
local SCAN_INTERVAL = 0.15

local npcCache = {}
local lastNpcRefresh = 0
local NPC_REFRESH_INTERVAL = 2

local function refreshNpcCandidates()
    local list = {}
    local seen = {}
    local function scan(container, depth)
        if depth > 3 then return end
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("Model") then
                if not seen[child] then
                    local hum = child:FindFirstChildOfClass("Humanoid")
                    if hum and not Players:GetPlayerFromCharacter(child) then
                        seen[child] = true
                        table.insert(list, child)
                    else
                        scan(child, depth + 1)
                    end
                end
            elseif child:IsA("Folder") or child:IsA("Model") then
                scan(child, depth + 1)
            end
        end
    end
    scan(Workspace, 0)
    npcCache = list
end

local function isEnemy(model, isBot)
    if model == LocalPlayer.Character then return false end
    if isBot then return true end
    if Config.esp.teamCheck then
        local p = Players:GetPlayerFromCharacter(model)
        if p and LocalPlayer.Team and p.Team == LocalPlayer.Team then return false end
    end
    return true
end

local function collectTargets()
    local list = {}
    local seen = {}
    local camPos = Camera.CFrame.Position
    local maxDist = Config.esp.maxDistance
    local maxSq = maxDist * maxDist

    local function tryAdd(model, isBot)
        if not model or seen[model] then return end
        if model == LocalPlayer.Character then return end
        seen[model] = true
        local hum = model:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return end
        local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or model:FindFirstChild("Torso") or model:FindFirstChild("Head")
        if not root then return end
        if not isEnemy(model, isBot) then return end
        local delta = root.Position - camPos
        local d2 = delta.X*delta.X + delta.Y*delta.Y + delta.Z*delta.Z
        if d2 > maxSq then return end
        table.insert(list, { model = model, hum = hum, root = root, dist = math.sqrt(d2), isBot = isBot })
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            tryAdd(p.Character, false)
        end
    end

    if Config.esp.botEsp then
        for _, m in ipairs(npcCache) do
            tryAdd(m, true)
        end
    end

    return list
end

-- ============ FOV RING ============
local fovCircle = (function()
    local ok, c = pcall(function() return Drawing.new("Circle") end)
    if not ok or not c then return nil end
    c.Thickness = 1.5
    c.NumSides = 72
    c.Transparency = 0.7
    c.Color = COL.accent
    c.Filled = false
    c.Visible = false
    return c
end)()

-- ============ DRAWING POOL ============
local DrawPool = {}

local R15_ORDER = {
    "Head", "UpperTorso", "LowerTorso",
    "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "RightUpperLeg", "RightLowerLeg", "RightFoot",
}
local R15_CONNECTIONS = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"},
}

local R6_ORDER = {
    "Head", "Torso", "Torso",
    "Left Arm", "Left Arm", "Left Arm",
    "Right Arm", "Right Arm", "Right Arm",
    "Left Leg", "Left Leg", "Left Leg",
    "Right Leg", "Right Leg", "Right Leg",
}
local R6_CONNECTIONS = {
    {"Head", "Torso"}, {"Torso", "Torso"},
    {"Torso", "Left Arm"}, {"Left Arm", "Left Arm"},
    {"Left Arm", "Left Arm"},
    {"Torso", "Right Arm"}, {"Right Arm", "Right Arm"},
    {"Right Arm", "Right Arm"},
    {"Torso", "Left Leg"}, {"Left Leg", "Left Leg"},
    {"Left Leg", "Left Leg"},
    {"Torso", "Right Leg"}, {"Right Leg", "Right Leg"},
    {"Right Leg", "Right Leg"},
}

local function newDraw(kind)
    local ok, d = pcall(function() return Drawing.new(kind) end)
    if ok and d then return d end
    return nil
end

local function ensurePool(model)
    if DrawPool[model] then return DrawPool[model] end
    local p = {
        box      = newDraw("Square"),
        snapline = newDraw("Line"),
        bone     = {},
        name     = newDraw("Text"),
        distance = newDraw("Text"),
    }
    for i = 1, #R15_CONNECTIONS do
        p.bone[i] = newDraw("Line")
    end
    DrawPool[model] = p
    return p
end

local function hidePool(p)
    if not p then return end
    if p.box then p.box.Visible = false end
    if p.snapline then p.snapline.Visible = false end
    if p.name then p.name.Visible = false end
    if p.distance then p.distance.Visible = false end
    if p.bone then
        for _, l in ipairs(p.bone) do if l then l.Visible = false end end
    end
end

local function project(pos)
    local sp = Camera:WorldToViewportPoint(pos)
    if sp.Z <= 0 then return nil end
    return Vector2.new(sp.X, sp.Y)
end

local function getRigKind(model)
    if model:FindFirstChild("UpperTorso") then return "R15" end
    if model:FindFirstChild("Torso") then return "R6" end
    return nil
end

local function getBox(model)
    local head = model:FindFirstChild("Head")
    local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
        or model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso")
    if not root then return nil end

    local top, bottom
    if head then
        top = head.Position + Vector3.new(0, head.Size.Y * 0.6, 0)
    else
        top = root.Position + Vector3.new(0, 2.5, 0)
    end
    bottom = root.Position - Vector3.new(0, 3, 0)

    local topScreen = project(top)
    local bottomScreen = project(bottom)
    if not topScreen or not bottomScreen then return nil end

    local height = math.abs(bottomScreen.Y - topScreen.Y)
    local width = height * 0.55
    local cx = (topScreen.X + bottomScreen.X) / 2
    local boxTop = math.min(topScreen.Y, bottomScreen.Y)
    local boxBottom = math.max(topScreen.Y, bottomScreen.Y)

    return {
        left = cx - width / 2,
        top = boxTop,
        width = width,
        height = height,
        centerX = cx,
        bottom = boxBottom,
    }
end

-- ============ ESP RENDER ============
local function renderESP()
    if KILLED then return end
    if not Config.esp.enabled then
        for _, pool in pairs(DrawPool) do hidePool(pool) end
        return
    end

    local vp = Camera.ViewportSize
    local active = {}

    for _, entry in ipairs(scanCache) do
        local model = entry.model
        local hum = entry.hum
        local root = entry.root
        local isBot = entry.isBot
        if model and root and hum and hum.Health > 0 then
            if (not isBot) or Config.esp.botEsp then
                active[model] = true
                local pool = ensurePool(model)
                local box = getBox(model)

                if box then
                    local boxC  = isBot and Config.esp.colors.bot or Config.esp.colors.box
                    local boneC = isBot and Config.esp.colors.bot or Config.esp.colors.bone
                    local snapC = isBot and Config.esp.colors.bot or Config.esp.colors.snapline

                    if pool.box then
                        pool.box.Visible = Config.esp.box2d
                        if Config.esp.box2d then
                            pool.box.Color = boxC
                            pool.box.Thickness = 1
                            pool.box.Transparency = 1
                            pool.box.Filled = false
                            pool.box.Size = Vector2.new(box.width, box.height)
                            pool.box.Position = Vector2.new(box.left, box.top)
                        end
                    end

                    if pool.snapline then
                        pool.snapline.Visible = Config.esp.snapline
                        if Config.esp.snapline then
                            pool.snapline.Color = snapC
                            pool.snapline.Thickness = 1
                            pool.snapline.Transparency = 0.6
                            pool.snapline.From = Vector2.new(vp.X / 2, vp.Y)
                            pool.snapline.To = Vector2.new(box.centerX, box.bottom)
                        end
                    end

                    if Config.esp.bone then
                        local rig = getRigKind(model)
                        local order = rig == "R6" and R6_ORDER or R15_ORDER
                        local conns = rig == "R6" and R6_CONNECTIONS or R15_CONNECTIONS
                        local positions = {}
                        for _, name in ipairs(order) do
                            if not positions[name] then
                                local part = model:FindFirstChild(name)
                                if part and part:IsA("BasePart") then
                                    positions[name] = project(part.Position)
                                end
                            end
                        end
                        for i, conn in ipairs(conns) do
                            local a, b = positions[conn[1]], positions[conn[2]]
                            local line = pool.bone[i]
                            if line then
                                if a and b and conn[1] ~= conn[2] then
                                    line.Visible = true
                                    line.Color = boneC
                                    line.Thickness = 1
                                    line.Transparency = 0.7
                                    line.From = a
                                    line.To = b
                                else
                                    line.Visible = false
                                end
                            end
                        end
                    else
                        for _, line in ipairs(pool.bone) do
                            if line then line.Visible = false end
                        end
                    end

                    if pool.name then
                        pool.name.Visible = Config.esp.name
                        if Config.esp.name then
                            local display
                            if isBot then
                                display = "NPC"
                            else
                                local p = Players:GetPlayerFromCharacter(model)
                                display = p and p.DisplayName or "?"
                            end
                            pool.name.Text = display
                            pool.name.Color = isBot and Config.esp.colors.bot or Config.esp.colors.name
                            pool.name.Size = 13
                            pool.name.Center = true
                            pool.name.Outline = true
                            pool.name.OutlineColor = Color3.new(0, 0, 0)
                            pool.name.Position = Vector2.new(box.centerX, box.top - 16)
                        end
                    end

                    if pool.distance then
                        pool.distance.Visible = Config.esp.distance
                        if Config.esp.distance then
                            local dist = math.floor(entry.dist)
                            pool.distance.Text = tostring(dist) .. "m"
                            pool.distance.Color = Config.esp.colors.distance
                            pool.distance.Size = 12
                            pool.distance.Center = true
                            pool.distance.Outline = true
                            pool.distance.OutlineColor = Color3.new(0, 0, 0)
                            pool.distance.Position = Vector2.new(box.centerX, box.bottom + 4)
                        end
                    end
                else
                    hidePool(pool)
                end
            else
                if DrawPool[model] then hidePool(DrawPool[model]) end
            end
        else
            if DrawPool[model] then hidePool(DrawPool[model]) end
        end
    end

    for model, pool in pairs(DrawPool) do
        if not active[model] then
            hidePool(pool)
        end
    end
end

-- ============ AIMBOT ============
local KEYMAP = {
    RightClick = Enum.UserInputType.MouseButton2,
    LeftClick  = Enum.UserInputType.MouseButton1,
    Shift      = Enum.KeyCode.LeftShift,
    E          = Enum.KeyCode.E,
    Q          = Enum.KeyCode.Q,
    C          = Enum.KeyCode.C,
    F          = Enum.KeyCode.F,
}

local aimActive = false
local function resolveKey(name) return KEYMAP[name] or Enum.UserInputType.MouseButton2 end
local function inputMatches(input, key) return input.UserInputType == key or input.KeyCode == key end

local function getPart(model, partName)
    if not model or not model:IsA("Model") then return nil end
    local map = {
        Head = {"Head"},
        Body = {"UpperTorso", "Torso", "Chest", "Trunk"},
        Foot = {"LeftFoot", "RightFoot", "Left Leg", "Right Leg", "Foot"},
        Root = {"HumanoidRootPart", "UpperTorso", "Torso"},
    }
    for _, n in ipairs(map[partName] or {}) do
        local p = model:FindFirstChild(n, true)
        if p and p:IsA("BasePart") then return p end
    end
    return model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
end

local function getClosestTarget(fovRadius, partName)
    local best, bestDist = nil, fovRadius
    local vp = Camera.ViewportSize
    local center = Vector2.new(vp.X / 2, vp.Y / 2)
    for _, entry in ipairs(scanCache) do
        local part = getPart(entry.model, partName) or entry.root
        if part then
            local sp = Camera:WorldToScreenPoint(part.Position)
            if sp.Z > 0 then
                local screenPos = Vector2.new(sp.X, sp.Y)
                local d = (screenPos - center).Magnitude
                if d < bestDist then
                    best = { entry = entry, part = part }
                    bestDist = d
                end
            end
        end
    end
    return best
end

local function aimbotStep()
    if not Config.aimbot.enabled or not aimActive then return end
    local target = getClosestTarget(Config.aimbot.fov, Config.aimbot.part)
    if not target then return end
    local desired = CFrame.new(Camera.CFrame.Position, target.part.Position)
    Camera.CFrame = Camera.CFrame:Lerp(desired, math.clamp(Config.aimbot.smooth, 0.01, 1))
end

track(UserInputService.InputBegan:Connect(function(input, gp)
    if gp or KILLED then return end
    if inputMatches(input, resolveKey(Config.aimbot.key)) then
        if Config.aimbot.mode == "Toggle" then aimActive = not aimActive
        else aimActive = true end
    end
end))

track(UserInputService.InputEnded:Connect(function(input)
    if KILLED then return end
    if inputMatches(input, resolveKey(Config.aimbot.key)) then
        if Config.aimbot.mode == "Hold" then aimActive = false end
    end
end))

-- ============ SILENT AIM ============
local oldIndex
oldIndex = hookmetamethod(game, "__index", function(self, key)
    if KILLED then return oldIndex(self, key) end
    if Config.silent.enabled and self == Mouse and (key == "Hit" or key == "Target") then
        local target = getClosestTarget(Config.aimbot.fov, Config.silent.part)
        if target then
            local part = getPart(target.entry.model, Config.silent.part) or target.entry.root
            if key == "Hit" then return CFrame.new(part.Position) else return part end
        end
    end
    return oldIndex(self, key)
end)

-- ============ ANTI-AFK ============
local antiAfkThread = nil

local function startAntiAfk()
    if antiAfkThread then return end
    antiAfkThread = task.spawn(function()
        while not KILLED and Config.misc.antiAfk do
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton1(Vector2.new(0, 0))
            end)
            task.wait(60)
        end
        antiAfkThread = nil
    end)
end

local function stopAntiAfk()
    if antiAfkThread then
        pcall(function() task.cancel(antiAfkThread) end)
        antiAfkThread = nil
    end
end

if Config.misc.antiAfk then startAntiAfk() end

-- ============ MAIN LOOP ============
track(RunService.RenderStepped:Connect(function()
    if KILLED then return end
    local now = tick()

    if Config.esp.botEsp and (now - lastNpcRefresh >= NPC_REFRESH_INTERVAL) then
        lastNpcRefresh = now
        refreshNpcCandidates()
    end

    if now - lastScan >= SCAN_INTERVAL then
        lastScan = now
        scanCache = collectTargets()
    end

    if fovCircle then
        local showRing = (Config.aimbot.enabled and Config.aimbot.showFov) or Config.silent.enabled
        if showRing then
            local vp = Camera.ViewportSize
            fovCircle.Visible = true
            fovCircle.Position = Vector2.new(vp.X / 2, vp.Y / 2)
            fovCircle.Radius = Config.aimbot.fov
            if Config.silent.enabled and not Config.aimbot.enabled then
                fovCircle.Color = COL.accent2
                fovCircle.Transparency = 0.7
            else
                fovCircle.Color = aimActive and COL.accent2 or COL.accent
                fovCircle.Transparency = aimActive and 0.9 or 0.65
            end
        else
            fovCircle.Visible = false
        end
    end

    renderESP()
    aimbotStep()
end))

-- ============ UI TOGGLE — INSERT or DELETE ============
track(UserInputService.InputBegan:Connect(function(input, gp)
    if gp or KILLED then return end
    if input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.Delete then
        ScreenGui.Enabled = not ScreenGui.Enabled
    end
end))

-- ============ MINIMIZE / CLOSE ============
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    TabBar.Visible = not minimized
    ContentArea.Visible = not minimized
    HeaderDiv.Visible = not minimized
    Main.Size = minimized and UDim2.new(0, 500, 0, 44) or UDim2.new(0, 500, 0, 340)
    MinBtn.Text = minimized and "+" or "—"
end)

local function killMenu()
    if KILLED then return end
    KILLED = true
    stopAntiAfk()
    for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
    if fovCircle then pcall(function() fovCircle:Remove() end) end
    for model, pool in pairs(DrawPool) do
        pcall(function()
            hidePool(pool)
            for k, v in pairs(pool) do
                if k == "bone" then
                    for _, l in ipairs(v) do pcall(function() l:Remove() end) end
                elseif v and typeof(v) == "userdata" then
                    pcall(function() v:Remove() end)
                end
            end
        end)
    end
    DrawPool = {}
    pcall(function() hookmetamethod(game, "__index", oldIndex) end)
    pcall(function() ScreenGui:Destroy() end)
    print("[Vysesaint] unloaded")
end

CloseBtn.MouseButton1Click:Connect(killMenu)
killBtn.MouseButton1Click:Connect(killMenu)

print("[Vysesaint] loaded — INSERT or DELETE toggles menu · X to unload")
