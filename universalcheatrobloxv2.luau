--[[
    vysesaint UI framework — v2
    language: Luau | target: Roblox | executor: Nexomia
    aim assist + silent aim: target pool = ESP-visible only
    player esp + npc esp + anti-afk + config
    universal: character parts via fallback chain
]]

local Players           = game:GetService("Players")
local UIS               = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local CoreGui           = game:GetService("CoreGui")
local Workspace         = game:GetService("Workspace")
local VirtualUser       = game:GetService("VirtualUser")
local LP                = Players.LocalPlayer
local Camera            = Workspace.CurrentCamera
local Mouse             = LP:GetMouse()

local MENU_PALETTE = {
    { name = "Cyan",   color = Color3.fromRGB(0, 229, 255),  accent2 = Color3.fromRGB(0, 120, 170)  },
    { name = "Purple", color = Color3.fromRGB(160, 90, 255), accent2 = Color3.fromRGB(90, 40, 180)  },
    { name = "Green",  color = Color3.fromRGB(0, 255, 140),  accent2 = Color3.fromRGB(0, 160, 90)   },
    { name = "Red",    color = Color3.fromRGB(230, 40, 60),  accent2 = Color3.fromRGB(150, 20, 30)  },
    { name = "Orange", color = Color3.fromRGB(255, 150, 40), accent2 = Color3.fromRGB(200, 90, 20)  },
    { name = "Pink",   color = Color3.fromRGB(255, 90, 200), accent2 = Color3.fromRGB(180, 40, 140) },
}
local ESP_PALETTE = {
    { name = "Red",    color = Color3.fromRGB(255, 70, 90)  },
    { name = "Green",  color = Color3.fromRGB(0, 220, 120)  },
    { name = "Cyan",   color = Color3.fromRGB(0, 229, 255)  },
    { name = "Yellow", color = Color3.fromRGB(255, 210, 60) },
    { name = "Orange", color = Color3.fromRGB(255, 150, 40) },
    { name = "Purple", color = Color3.fromRGB(160, 90, 255) },
}

local T = {
    accent   = MENU_PALETTE[1].color,
    accent2  = MENU_PALETTE[1].accent2,
    bg       = Color3.fromRGB(6, 8, 12),
    bg2      = Color3.fromRGB(10, 13, 19),
    panel    = Color3.fromRGB(11, 14, 20),
    card     = Color3.fromRGB(15, 19, 27),
    hover    = Color3.fromRGB(24, 30, 42),
    text     = Color3.fromRGB(228, 234, 244),
    muted    = Color3.fromRGB(96, 110, 132),
    dim      = Color3.fromRGB(58, 68, 86),
    danger   = Color3.fromRGB(255, 60, 84),
    green    = Color3.fromRGB(0, 255, 120),
    yellow   = Color3.fromRGB(255, 210, 60),
    font     = Enum.Font.GothamMedium,
    fontBold = Enum.Font.GothamBold,
    mono     = Enum.Font.Code,
}

local Theme = { root = nil, current = 1 }
local function colorEq(a, b)
    return math.abs(a.R - b.R) < 0.02 and math.abs(a.G - b.G) < 0.02 and math.abs(a.B - b.B) < 0.02
end
function Theme.apply(entry, idx)
    if not entry or not Theme.root then return end
    if idx then Theme.current = idx end
    local newA, newA2 = entry.color, entry.accent2 or entry.color
    local oldA, oldA2 = T.accent, T.accent2
    for _, d in ipairs(Theme.root:GetDescendants()) do
        if not d:GetAttribute("themeLock") then
            if d:IsA("UIStroke") then
                if colorEq(d.Color, oldA)  then d.Color = newA  end
                if colorEq(d.Color, oldA2) then d.Color = newA2 end
            elseif d:IsA("UIGradient") then
                local kps, changed = {}, false
                for _, kp in ipairs(d.Color.Keypoints) do
                    local c = kp.Value
                    if colorEq(c, oldA)  then c = newA;  changed = true end
                    if colorEq(c, oldA2) then c = newA2; changed = true end
                    table.insert(kps, ColorSequenceKeypoint.new(kp.Time, c))
                end
                if changed then d.Color = ColorSequence.new(kps) end
            end
            if d:IsA("GuiObject") then
                local bg = d.BackgroundColor3
                if colorEq(bg, oldA)  then d.BackgroundColor3 = newA  end
                if colorEq(bg, oldA2) then d.BackgroundColor3 = newA2 end
            end
            if d:IsA("TextLabel") or d:IsA("TextButton") then
                if colorEq(d.TextColor3, oldA) then d.TextColor3 = newA end
            end
        end
    end
    T.accent, T.accent2 = newA, newA2
end

local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end
local function corner(o, r) return new("UICorner", { CornerRadius = UDim.new(0, r or 6) }, o) end
local function stroke(o, col, thick, trans)
    return new("UIStroke", { Color = col or T.accent, Thickness = thick or 1, Transparency = trans or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
end
local function grad(o, seq, rot) return new("UIGradient", { Color = seq, Rotation = rot or 0 }, o) end
local function getParent()
    if gethui then local ok, h = pcall(gethui); if ok and h then return h end end
    local ok2, cg = pcall(function() return CoreGui end)
    if ok2 and cg then return cg end
    return LP:WaitForChild("PlayerGui")
end
local function bracket(parent, c)
    local size = 14
    local f = new("Frame", { Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, ZIndex = 4 }, parent)
    local function line(w, h, x, y)
        new("Frame", { Size = UDim2.fromOffset(w, h), Position = UDim2.fromOffset(x, y), BackgroundColor3 = T.accent, BorderSizePixel = 0, ZIndex = 4 }, f)
    end
    if c == "tl" then f.Position = UDim2.fromOffset(6, 6); line(size,1,0,0); line(1,size,0,0)
    elseif c == "tr" then f.Position = UDim2.new(1, -size-6, 0, 6); line(size,1,0,0); line(1,size,size-1,0)
    elseif c == "bl" then f.Position = UDim2.new(0, 6, 1, -size-6); line(size,1,0,size-1); line(1,size,0,0)
    elseif c == "br" then f.Position = UDim2.new(1, -size-6, 1, -size-6); line(size,1,0,size-1); line(1,size,size-1,0) end
    return f
end

-- ═══════════ UNIVERSAL CHARACTER RESOLUTION ═══════════
local HEAD_PATTERNS = { "Head", "head", "HEAD", "HeadMesh" }
local ROOT_PATTERNS = { "HumanoidRootPart", "RootPart", "Root", "Torso", "UpperTorso", "Hips", "Pelvis" }
local function firstPartNamed(char, patterns)
    for _, name in ipairs(patterns) do
        local p = char:FindFirstChild(name)
        if p and p:IsA("BasePart") then return p end
    end
    return nil
end
local function resolveParts(char)
    if not char then return nil end
    local hum  = char:FindFirstChildOfClass("Humanoid")
    local head = firstPartNamed(char, HEAD_PATTERNS)
    local root = firstPartNamed(char, ROOT_PATTERNS)
    if not root and hum and hum.RootPart then root = hum.RootPart end
    if not head or not root then
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("BasePart") then
                local n = d.Name:lower()
                if not head and n:find("head") then head = d end
                if not root and (n:find("root") or n:find("torso") or n:find("hip")) then root = d end
            end
        end
    end
    if not root then
        local ok, cf, size = pcall(function()
            local m = char.GetModelCFrame and char:GetModelCFrame() or nil
            local s = char.GetExtentsSize and char:GetExtentsSize() or nil
            return m, s
        end)
        if ok and cf and size then
            root = { Position = cf.Position - Vector3.new(0, size.Y * 0.5, 0), _synthetic = true }
            if not head then head = { Position = cf.Position + Vector3.new(0, size.Y * 0.5, 0), _synthetic = true } end
        end
    end
    if not root then return nil end
    if not head then head = root end
    return { hum = hum, head = head, root = root }
end
local function getHealth(char, hum)
    if hum and hum.Health and hum.MaxHealth and hum.MaxHealth > 0 then return hum.Health, hum.MaxHealth end
    local attr = char:GetAttribute("Health")
    if typeof(attr) == "number" then
        local maxAttr = char:GetAttribute("MaxHealth")
        if typeof(maxAttr) == "number" and maxAttr > 0 then return attr, maxAttr end
        return attr, attr
    end
    for _, d in ipairs(char:GetChildren()) do
        if d:IsA("NumberValue") and (d.Name == "Health" or d.Name == "HP" or d.Name == "Hp") then
            local maxV = char:FindFirstChild(d.Name == "Health" and "MaxHealth" or "MaxHP")
            local maxNum = (maxV and typeof(maxV.Value) == "number" and maxV.Value > 0) and maxV.Value or d.Value
            return d.Value, maxNum
        end
    end
    return 1, 1
end
local function isAlive(char, hum)
    if hum then return hum.Health > 0 end
    local h, m = getHealth(char, nil)
    return h > 0 and m > 0
end

local function getAimPart(model, partName, resolved)
    resolved = resolved or resolveParts(model)
    if not resolved then return nil end
    if partName == "Head" then return resolved.head end
    if partName == "Body" then
        local m = model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso")
            or model:FindFirstChild("Chest") or model:FindFirstChild("Trunk")
        return m or resolved.root
    end
    if partName == "Foot" then
        local m = model:FindFirstChild("LeftFoot") or model:FindFirstChild("RightFoot")
            or model:FindFirstChild("Left Leg") or model:FindFirstChild("Right Leg")
            or model:FindFirstChild("Foot")
        return m or resolved.root
    end
    return resolved.root
end

-- ═══════════ AIM CONFIG ═══════════
local AimConfig = {
    aimAssist    = false,
    silentAim    = false,
    aimMode      = "hold",
    aimBind      = { kind = "mouse", value = Enum.UserInputType.MouseButton2 },
    aimKeyHeld   = false,
    aimToggleOn  = false,
    targetPart   = "Head",
    wallCheck    = false,
    fov          = 200,
    fovVisible   = true,
    smoothness   = 15,
}

local MOUSE_LABELS = {
    [Enum.UserInputType.MouseButton1] = "LMB",
    [Enum.UserInputType.MouseButton2] = "RMB",
    [Enum.UserInputType.MouseButton3] = "MMB",
}
local function bindLabel(b)
    if not b then return "--" end
    if b.kind == "mouse" then return MOUSE_LABELS[b.value] or b.value.Name end
    if b.kind == "key"   then return b.value.Name end
    return "--"
end
local function matchesBind(input)
    local b = AimConfig.aimBind
    if not b then return false end
    if b.kind == "key" then
        return input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == b.value
    elseif b.kind == "mouse" then
        return input.UserInputType == b.value
    end
    return false
end
local function aimActive()
    if not (AimConfig.aimAssist or AimConfig.silentAim) then return false end
    if AimConfig.aimMode == "always" then return true end
    if AimConfig.aimMode == "hold"   then return AimConfig.aimKeyHeld end
    return AimConfig.aimToggleOn
end

-- ═══════════ FOV CIRCLE ═══════════
local fovCircle = (function()
    local ok, c = pcall(function() return Drawing.new("Circle") end)
    if not ok or not c then return nil end
    c.Thickness = 1.5
    c.NumSides = 72
    c.Transparency = 0.7
    c.Color = T.accent
    c.Filled = false
    c.Visible = false
    return c
end)()

-- ═══════════ NPC SCAN ═══════════
local npcCache = {}
local lastNpcRefresh = 0
local NPC_REFRESH_INTERVAL = 2

local function refreshNpcCandidates()
    local list, seen = {}, {}
    local function scan(container, depth)
        if depth > 3 then return end
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("Model") then
                if not seen[child] then
                    local hum = child:FindFirstChildOfClass("Humanoid")
                    if hum and not Players:GetPlayerFromCharacter(child) then
                        seen[child] = true; table.insert(list, child)
                    else
                        scan(child, depth + 1)
                    end
                end
            elseif child:IsA("Folder") then
                scan(child, depth + 1)
            end
        end
    end
    scan(Workspace, 0)
    npcCache = list
end

-- ═══════════ AIM TARGET POOL ═══════════
-- Populated ONLY by ESP.render(). If ESP didn't draw it this frame, it's not
-- aimable and silent aim can't hit it. Wall check happens here too.
local AimTargets = {}

local function hasLineOfSight(char, cam, parts)
    if not AimConfig.wallCheck then return true end
    local target = parts and (parts.head or parts.root)
    if not target then return false end
    local origin = cam.CFrame.Position
    local dir = target.Position - origin
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local filter = { cam }
    if LP.Character then table.insert(filter, LP.Character) end
    params.FilterDescendantsInstances = filter
    local ok, result = pcall(function() return Workspace:Raycast(origin, dir, params) end)
    if not ok or not result then return true end
    return result.Instance:IsDescendantOf(char)
end

local function getClosestTarget(fovRadius, partName)
    local best, bestDist = nil, fovRadius
    local vp = Camera.ViewportSize
    local center = Vector2.new(vp.X / 2, vp.Y / 2)
    for model, entry in pairs(AimTargets) do
        local part = getAimPart(model, partName, entry.parts) or entry.root
        if part then
            local sp, onScreen = Camera:WorldToScreenPoint(part.Position)
            if onScreen and sp.Z > 0 then
                local screenPos = Vector2.new(sp.X, sp.Y)
                local d = (screenPos - center).Magnitude
                if d < bestDist then
                    if hasLineOfSight(model, Camera, entry.parts) then
                        best = { entry = entry, part = part }
                        bestDist = d
                    end
                end
            end
        end
    end
    return best
end

-- ═══════════ AIMBOT — live camera lerp ═══════════
local function aimbotStep()
    if not AimConfig.aimAssist or not aimActive() then return end
    local target = getClosestTarget(AimConfig.fov, AimConfig.targetPart)
    if not target then return end
    local desired = CFrame.new(Camera.CFrame.Position, target.part.Position)
    local factor = math.clamp(AimConfig.smoothness / 100, 0.01, 1)
    Camera.CFrame = Camera.CFrame:Lerp(desired, factor)
end

-- ═══════════ SILENT AIM ═══════════
local oldIndex
oldIndex = hookmetamethod(game, "__index", function(self, key)
    if AimConfig.silentAim and aimActive() and self == Mouse and (key == "Hit" or key == "Target") then
        local target = getClosestTarget(AimConfig.fov, AimConfig.targetPart)
        if target then
            local part = getAimPart(target.entry.model, AimConfig.targetPart, target.entry.parts) or target.entry.root
            if key == "Hit" then return CFrame.new(part.Position) end
            return part
        end
    end
    return oldIndex(self, key)
end)

-- ═══════════ INPUT ═══════════
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if not matchesBind(input) then return end
    if AimConfig.aimMode == "hold" then
        AimConfig.aimKeyHeld = true
    elseif AimConfig.aimMode == "toggle" then
        AimConfig.aimToggleOn = not AimConfig.aimToggleOn
    end
end)
UIS.InputEnded:Connect(function(input)
    if not matchesBind(input) then return end
    AimConfig.aimKeyHeld = false
end)

-- ═══════════ CONFIG ═══════════
local CONFIG_FILE = "vysesaint_config.json"
local Config = { autosave = true }

local function ioAvailable()
    return type(writefile) == "function" and type(readfile) == "function"
end
local function jsonEncode(tbl)
    local ok, res = pcall(function() return game:GetService("HttpService"):JSONEncode(tbl) end)
    return (ok and type(res) == "string") and res or nil
end
local function jsonDecode(str)
    local ok, res = pcall(function() return game:GetService("HttpService"):JSONDecode(str) end)
    return (ok and type(res) == "table") and res or nil
end
local function colorToTable(c) return { r = c.R, g = c.G, b = c.B } end
local function tableToColor(t)
    if type(t) ~= "table" then return nil end
    local r, g, b = tonumber(t.r), tonumber(t.g), tonumber(t.b)
    if not (r and g and b) then return nil end
    return Color3.new(r, g, b)
end
local function bindToTable(b)
    if not b then return nil end
    return { kind = b.kind, name = b.value.Name }
end
local function tableToBind(t)
    if type(t) ~= "table" then return nil end
    if t.kind == "key" then
        local ok, v = pcall(function() return Enum.KeyCode[t.name] end)
        if ok and v then return { kind = "key", value = v } end
    elseif t.kind == "mouse" then
        local ok, v = pcall(function() return Enum.UserInputType[t.name] end)
        if ok and v then return { kind = "mouse", value = v } end
    end
    return nil
end
function Config.save(data)
    if not ioAvailable() then return false, "no io" end
    local json = jsonEncode(data)
    if not json then return false, "encode failed" end
    local ok = pcall(function() writefile(CONFIG_FILE, json) end)
    if not ok then return false, "write failed" end
    return true, CONFIG_FILE
end
function Config.load()
    if not ioAvailable() then return false, "no io" end
    local ok, content = pcall(function() return readfile(CONFIG_FILE) end)
    if not ok or type(content) ~= "string" or #content == 0 then return false, "read failed" end
    local data = jsonDecode(content)
    if type(data) ~= "table" then return false, "parse failed" end
    return true, data
end
function Config.exists()
    if not ioAvailable() then return false end
    local ok = pcall(function() return readfile(CONFIG_FILE) end)
    return ok
end
function Config.status()
    if not ioAvailable() then return "no file IO" end
    if Config.exists() then return "file exists · " .. CONFIG_FILE end
    return "ready · " .. CONFIG_FILE
end
function Config.wipe()
    if not ioAvailable() or type(delfile) ~= "function" then return false, "delfile unavailable" end
    if not Config.exists() then return true, "no file" end
    local ok = pcall(function() delfile(CONFIG_FILE) end)
    return ok, ok and "deleted" or "delete failed"
end

-- ═══════════ ESP CONFIG ═══════════
local ESPConfig = {
    boxes2D = true, bones = false, npcBoxes2D = false, filter = "all",
    nameTags = false, healthBars = false, tracers = true,
    renderDistance = 1000,
    teamColor = Color3.fromRGB(0, 220, 120),
    enemyColor = Color3.fromRGB(255, 70, 90),
    npcColor = Color3.fromRGB(255, 200, 40),
    boxThickness = 1, tracerThickness = 1,
}

local ESP = { playerPool = {}, npcPool = {}, conn = nil }
local function newDrawing(class)
    local ok, d = pcall(Drawing.new, class)
    return ok and d or nil
end
local R15_BONES = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
}
local R6_BONES = {
    {"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"},
}
local BONE_MAX = 14
local function getBoneSet(char)
    if char:FindFirstChild("UpperTorso") and char:FindFirstChild("LowerTorso") then return R15_BONES end
    if char:FindFirstChild("Torso") then return R6_BONES end
    return nil
end
local function playerSet(plr)
    local s = ESP.playerPool[plr]
    if s then return s end
    s = { box2D = newDrawing("Square"), name = newDrawing("Text"), hpBg = newDrawing("Square"), hpFill = newDrawing("Square"), tracer = newDrawing("Line"), bones = {} }
    for i = 1, BONE_MAX do s.bones[i] = newDrawing("Line") end
    ESP.playerPool[plr] = s
    return s
end
local function hidePlayerSet(s)
    if not s then return end
    if s.box2D then s.box2D.Visible = false end
    if s.name then s.name.Visible = false end
    if s.hpBg then s.hpBg.Visible = false end
    if s.hpFill then s.hpFill.Visible = false end
    if s.tracer then s.tracer.Visible = false end
    for _, l in ipairs(s.bones) do if l then l.Visible = false end end
end
local function destroyPlayerSet(s)
    if not s then return end
    if s.box2D then pcall(function() s.box2D:Remove() end) end
    if s.name then pcall(function() s.name:Remove() end) end
    if s.hpBg then pcall(function() s.hpBg:Remove() end) end
    if s.hpFill then pcall(function() s.hpFill:Remove() end) end
    if s.tracer then pcall(function() s.tracer:Remove() end) end
    for _, l in ipairs(s.bones) do if l then pcall(function() l:Remove() end) end end
end
local function npcSet(model)
    local s = ESP.npcPool[model]
    if s then return s end
    s = { box2D = newDrawing("Square"), name = newDrawing("Text") }
    ESP.npcPool[model] = s
    return s
end
local function hideNpcSet(s)
    if not s then return end
    if s.box2D then s.box2D.Visible = false end
    if s.name then s.name.Visible = false end
end
local function destroyNpcSet(s)
    if not s then return end
    if s.box2D then pcall(function() s.box2D:Remove() end) end
    if s.name then pcall(function() s.name:Remove() end) end
end

-- drawPlayerESP returns entry if visible, nil if skipped/filtered.
local function drawPlayerESP(plr, cam, camPos, vp)
    local char = plr.Character
    if not char then return nil end
    local parts = resolveParts(char)
    if not parts or not isAlive(char, parts.hum) then return nil end
    local dist = (parts.root.Position - camPos).Magnitude
    if dist > ESPConfig.renderDistance then return nil end
    local sameTeam = plr.Team ~= nil and plr.Team == LP.Team
    if (ESPConfig.filter == "enemy" and sameTeam) or (ESPConfig.filter == "team" and not sameTeam) then return nil end

    local headTop = parts.head.Position + Vector3.new(0, 0.5, 0)
    local feet    = parts.root.Position - Vector3.new(0, 3, 0)
    local spHead, onHead = cam:WorldToViewportPoint(headTop)
    local spFeet, onFeet = cam:WorldToViewportPoint(feet)
    if not (onHead and onFeet) then return nil end

    local s = playerSet(plr)
    local color = sameTeam and ESPConfig.teamColor or ESPConfig.enemyColor
    local h = spFeet.Y - spHead.Y
    local w = h * 0.5
    local cx = (spHead.X + spFeet.X) * 0.5
    local boxPos = Vector2.new(cx - w / 2, spHead.Y)

    if ESPConfig.boxes2D and s.box2D then
        s.box2D.Visible = true; s.box2D.Color = color; s.box2D.Thickness = ESPConfig.boxThickness
        s.box2D.Filled = false; s.box2D.Transparency = 1
        s.box2D.Position = boxPos; s.box2D.Size = Vector2.new(w, h)
    end
    if ESPConfig.bones and s.bones then
        local set = getBoneSet(char)
        if set then
            local idx = 0
            for _, pair in ipairs(set) do
                local a, b = char:FindFirstChild(pair[1]), char:FindFirstChild(pair[2])
                if a and b and a:IsA("BasePart") and b:IsA("BasePart") then
                    local pA, onA = cam:WorldToViewportPoint(a.Position)
                    local pB, onB = cam:WorldToViewportPoint(b.Position)
                    if onA and onB then
                        idx = idx + 1
                        local ln = s.bones[idx]
                        if ln then
                            ln.Visible = true; ln.Color = color; ln.Thickness = 1; ln.Transparency = 1
                            ln.From = Vector2.new(pA.X, pA.Y); ln.To = Vector2.new(pB.X, pB.Y)
                        end
                    end
                end
            end
        end
    end
    if ESPConfig.nameTags and s.name then
        s.name.Visible = true; s.name.Text = plr.Name; s.name.Size = 13; s.name.Center = true
        s.name.Outline = true; s.name.OutlineColor = Color3.new(0,0,0); s.name.Color = color
        s.name.Position = Vector2.new(cx, spHead.Y - 16)
    end
    if ESPConfig.healthBars and s.hpBg and s.hpFill then
        local hp, maxHp = getHealth(char, parts.hum)
        local pct = math.clamp(hp / math.max(maxHp, 1), 0, 1)
        local barW, barH = 3, h
        local barX = boxPos.X - 6
        s.hpBg.Visible = true; s.hpBg.Color = Color3.new(0,0,0); s.hpBg.Thickness = 0
        s.hpBg.Filled = true; s.hpBg.Transparency = 0.5
        s.hpBg.Position = Vector2.new(barX, boxPos.Y); s.hpBg.Size = Vector2.new(barW, barH)
        s.hpFill.Visible = true
        s.hpFill.Color = Color3.fromRGB(0,255,0):Lerp(Color3.fromRGB(255,0,0), 1 - pct)
        s.hpFill.Thickness = 0; s.hpFill.Filled = true; s.hpFill.Transparency = 1
        s.hpFill.Position = Vector2.new(barX, boxPos.Y + barH * (1 - pct))
        s.hpFill.Size = Vector2.new(barW, barH * pct)
    end
    if ESPConfig.tracers and s.tracer then
        s.tracer.Visible = true; s.tracer.Color = color; s.tracer.Thickness = ESPConfig.tracerThickness
        s.tracer.Transparency = 1
        s.tracer.From = Vector2.new(vp.X / 2, vp.Y); s.tracer.To = Vector2.new(cx, spFeet.Y)
    end

    return { model = char, parts = parts, root = parts.root, dist = dist }
end

local function drawNpcESP(model, cam, camPos)
    local parts = resolveParts(model)
    if not parts or not isAlive(model, parts.hum) then return nil end
    local dist = (parts.root.Position - camPos).Magnitude
    if dist > ESPConfig.renderDistance then return nil end
    local headTop = parts.head.Position + Vector3.new(0, 0.5, 0)
    local feet    = parts.root.Position - Vector3.new(0, 3, 0)
    local spHead, onHead = cam:WorldToViewportPoint(headTop)
    local spFeet, onFeet = cam:WorldToViewportPoint(feet)
    if not (onHead and onFeet) then return nil end
    local s = npcSet(model)
    local color = ESPConfig.npcColor
    local h = spFeet.Y - spHead.Y
    local w = h * 0.5
    local cx = (spHead.X + spFeet.X) * 0.5
    if s.box2D then
        s.box2D.Visible = true; s.box2D.Color = color; s.box2D.Thickness = ESPConfig.boxThickness
        s.box2D.Filled = false; s.box2D.Transparency = 1
        s.box2D.Position = Vector2.new(cx - w / 2, spHead.Y); s.box2D.Size = Vector2.new(w, h)
    end
    if s.name then
        s.name.Visible = true; s.name.Text = model.Name; s.name.Size = 12; s.name.Center = true
        s.name.Outline = true; s.name.OutlineColor = Color3.new(0,0,0); s.name.Color = color
        s.name.Position = Vector2.new(cx, spHead.Y - 15)
    end
    return { model = model, parts = parts, root = parts.root, dist = dist }
end

-- ESP.render is the sole writer of AimTargets. If ESP skipped a target
-- (filter, off-screen, out of range, dead) it is NOT in the aim pool.
function ESP.render()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local camPos = cam.CFrame.Position
    local vp = cam.ViewportSize

    for _, s in pairs(ESP.playerPool) do hidePlayerSet(s) end
    for _, s in pairs(ESP.npcPool) do hideNpcSet(s) end

    for k in pairs(AimTargets) do AimTargets[k] = nil end

    local anyESP = ESPConfig.boxes2D or ESPConfig.bones or ESPConfig.nameTags
        or ESPConfig.healthBars or ESPConfig.tracers or ESPConfig.npcBoxes2D
    if not anyESP then return end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then
            local entry = drawPlayerESP(plr, cam, camPos, vp)
            if entry then AimTargets[entry.model] = entry end
        end
    end
    if ESPConfig.npcBoxes2D then
        for _, m in ipairs(npcCache) do
            local entry = drawNpcESP(m, cam, camPos)
            if entry then AimTargets[entry.model] = entry end
        end
    end
end
function ESP.start()
    if ESP.conn then return end
    ESP.conn = RunService.RenderStepped:Connect(ESP.render)
end
function ESP.stop()
    if ESP.conn then ESP.conn:Disconnect(); ESP.conn = nil end
    for _, s in pairs(ESP.playerPool) do destroyPlayerSet(s) end
    for _, s in pairs(ESP.npcPool) do destroyNpcSet(s) end
    ESP.playerPool, ESP.npcPool = {}, {}
    for k in pairs(AimTargets) do AimTargets[k] = nil end
end
Players.PlayerRemoving:Connect(function(plr)
    local s = ESP.playerPool[plr]
    if s then destroyPlayerSet(s); ESP.playerPool[plr] = nil end
end)

-- ═══════════ ANTI-AFK ═══════════
local AntiAfk = { conn = nil }
function AntiAfk.set(on)
    if on then
        if AntiAfk.conn then return end
        AntiAfk.conn = LP.Idled:Connect(function()
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end)
    else
        if AntiAfk.conn then AntiAfk.conn:Disconnect(); AntiAfk.conn = nil end
    end
end

-- ═══════════ WINDOW ═══════════
local Window = {}
Window.__index = Window
function Window.new(cfg)
    cfg = cfg or {}
    local self = setmetatable({}, Window)
    self.tabs = {}; self.current = nil; self._toasts = {}

    local gui = new("ScreenGui", {
        Name = "vysesaint", ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true,
    }, getParent())

    local main = new("Frame", {
        Name = "Main", Size = UDim2.fromOffset(660, 420),
        Position = UDim2.new(0.5, -330, 0.5, -210),
        BackgroundColor3 = T.bg, BorderSizePixel = 0, ClipsDescendants = true,
    }, gui)
    corner(main, 10)
    grad(main, ColorSequence.new{
        ColorSequenceKeypoint.new(0, T.bg2),
        ColorSequenceKeypoint.new(0.5, T.bg),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(4, 6, 10)),
    }, 135)
    stroke(main, T.accent, 1, 0.35)
    local outerGlow = stroke(main, T.accent2, 2, 0.78)
    bracket(main, "tl"); bracket(main, "tr"); bracket(main, "bl"); bracket(main, "br")

    local scan = new("Frame", {
        Size = UDim2.new(1, 0, 0, 90), Position = UDim2.new(0, 0, 0, -90),
        BackgroundColor3 = T.accent, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 3,
    }, main)
    local scanGrad = grad(scan, ColorSequence.new{
        ColorSequenceKeypoint.new(0, T.accent),
        ColorSequenceKeypoint.new(0.5, T.accent),
        ColorSequenceKeypoint.new(1, T.accent),
    })
    scanGrad.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0.88),
        NumberSequenceKeypoint.new(1, 1),
    }

    local topbar = new("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = T.panel, BorderSizePixel = 0, ZIndex = 2 }, main)
    grad(topbar, ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(16, 20, 28)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(9, 12, 17)),
    }, 0)
    new("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = T.accent, BorderSizePixel = 0, BackgroundTransparency = 0.25, ZIndex = 3 }, topbar)
    local dot = new("Frame", { Size = UDim2.fromOffset(7, 7), Position = UDim2.new(0, 18, 0.5, -3), BackgroundColor3 = T.accent, BorderSizePixel = 0, ZIndex = 3 }, topbar)
    corner(dot, 4)
    local dotGlow = stroke(dot, T.accent, 2, 0.4)
    task.spawn(function()
        while gui.Parent do
            TweenService:Create(dotGlow, TweenInfo.new(1.1, Enum.EasingStyle.Sine), { Transparency = 0.9 }):Play(); task.wait(1.1)
            TweenService:Create(dotGlow, TweenInfo.new(1.1, Enum.EasingStyle.Sine), { Transparency = 0.1 }):Play(); task.wait(1.1)
        end
    end)
    new("TextLabel", { Size = UDim2.new(0, 120, 1, 0), Position = UDim2.new(0, 36, 0, 0), BackgroundTransparency = 1, Font = T.fontBold, Text = "VYESAINT", TextColor3 = T.text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3 }, topbar)
    new("Frame", { Size = UDim2.fromOffset(1, 14), Position = UDim2.new(0, 152, 0.5, -7), BackgroundColor3 = T.dim, BorderSizePixel = 0, ZIndex = 3 }, topbar)
    local discordBadge = new("Frame", { Size = UDim2.fromOffset(14, 14), Position = UDim2.new(0, 164, 0.5, -7), BackgroundColor3 = T.accent, BorderSizePixel = 0, ZIndex = 3 }, topbar)
    corner(discordBadge, 3)
    new("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Font = T.fontBold, Text = "D", TextColor3 = T.bg, TextSize = 10, ZIndex = 4 }, discordBadge)
    new("TextLabel", { Size = UDim2.new(0, 160, 1, 0), Position = UDim2.new(0, 184, 0, 0), BackgroundTransparency = 1, Font = T.mono, Text = "marky.cool", TextColor3 = T.accent, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3 }, topbar)
    new("TextLabel", { Size = UDim2.new(0, 200, 1, 0), Position = UDim2.new(1, -290, 0, 0), BackgroundTransparency = 1, Font = T.mono, Text = "// ONLINE", TextColor3 = T.dim, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 3 }, topbar)

    local minimized = false
    local minBtn = new("TextButton", {
        Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -66, 0.5, -14),
        BackgroundColor3 = T.card, BackgroundTransparency = 1, BorderSizePixel = 0,
        Font = T.fontBold, Text = "–", TextColor3 = T.accent, TextSize = 16, AutoButtonColor = false, ZIndex = 3,
    }, topbar)
    corner(minBtn, 14)
    local minStroke = stroke(minBtn, T.accent, 1.5, 1)
    local minFill = new("Frame", { Size = UDim2.fromOffset(8, 8), Position = UDim2.new(0.5, -4, 0.5, -4), BackgroundColor3 = T.accent, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 3 }, minBtn)
    corner(minFill, 4)
    minBtn.MouseEnter:Connect(function()
        TweenService:Create(minBtn, TweenInfo.new(0.14), { BackgroundTransparency = 0 }):Play()
        TweenService:Create(minStroke, TweenInfo.new(0.14), { Transparency = 0 }):Play()
    end)
    minBtn.MouseLeave:Connect(function()
        if not minimized then
            TweenService:Create(minBtn, TweenInfo.new(0.14), { BackgroundTransparency = 1 }):Play()
            TweenService:Create(minStroke, TweenInfo.new(0.14), { Transparency = 1 }):Play()
        end
    end)
    local closeBtn = new("TextButton", {
        Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -34, 0.5, -14),
        BackgroundColor3 = T.card, BackgroundTransparency = 1, BorderSizePixel = 0,
        Font = T.fontBold, Text = "✕", TextColor3 = T.danger, TextSize = 13, AutoButtonColor = false, ZIndex = 3,
    }, topbar)
    corner(closeBtn, 14)
    local closeStroke = stroke(closeBtn, T.danger, 1.5, 1)
    closeBtn.MouseEnter:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.14), { BackgroundTransparency = 0 }):Play()
        TweenService:Create(closeStroke, TweenInfo.new(0.14), { Transparency = 0 }):Play()
    end)
    closeBtn.MouseLeave:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.14), { BackgroundTransparency = 1 }):Play()
        TweenService:Create(closeStroke, TweenInfo.new(0.14), { Transparency = 1 }):Play()
    end)
    closeBtn.MouseButton1Click:Connect(function()
        ESP.stop(); AntiAfk.set(false)
        if fovCircle then pcall(function() fovCircle:Remove() end) end
        pcall(function() hookmetamethod(game, "__index", oldIndex) end)
        gui:Destroy()
    end)

    local sidebar, content, bottom
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            TweenService:Create(minBtn, TweenInfo.new(0.16), { TextTransparency = 1 }):Play()
            TweenService:Create(minBtn, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
            TweenService:Create(minStroke, TweenInfo.new(0.2), { Transparency = 0 }):Play()
            TweenService:Create(minFill, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
            if sidebar then sidebar.Visible = false end
            if content then content.Visible = false end
            if bottom then bottom.Visible = false end
            TweenService:Create(main, TweenInfo.new(0.24, Enum.EasingStyle.Quad), { Size = UDim2.fromOffset(660, 40) }):Play()
        else
            TweenService:Create(minFill, TweenInfo.new(0.16), { BackgroundTransparency = 1 }):Play()
            TweenService:Create(minBtn, TweenInfo.new(0.16), { TextTransparency = 0 }):Play()
            if sidebar then sidebar.Visible = true end
            if content then content.Visible = true end
            if bottom then bottom.Visible = true end
            TweenService:Create(main, TweenInfo.new(0.24, Enum.EasingStyle.Quad), { Size = UDim2.fromOffset(660, 420) }):Play()
            task.delay(0.24, function()
                if not minimized then
                    TweenService:Create(minBtn, TweenInfo.new(0.14), { BackgroundTransparency = 1 }):Play()
                    TweenService:Create(minStroke, TweenInfo.new(0.14), { Transparency = 1 }):Play()
                end
            end)
        end
    end)

    UIS.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.Delete then
            gui.Enabled = not gui.Enabled
            if gui.Enabled then
                main.Size = minimized and UDim2.fromOffset(660, 40) or UDim2.fromOffset(660, 420)
            end
        end
    end)

    local dragging, dragStart, startPos
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    topbar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                local delta = input.Position - dragStart
                main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end
    end)

    sidebar = new("Frame", { Size = UDim2.new(0, 160, 1, -102), Position = UDim2.new(0, 0, 0, 40), BackgroundColor3 = T.panel, BorderSizePixel = 0, ClipsDescendants = true }, main)
    grad(sidebar, ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(11, 14, 20)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 10, 15)),
    }, 90)
    new("Frame", { Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0), BackgroundColor3 = T.accent, BackgroundTransparency = 0.82, BorderSizePixel = 0 }, sidebar)
    new("TextLabel", { Size = UDim2.new(1, -16, 0, 20), Position = UDim2.new(0, 12, 0, 6), BackgroundTransparency = 1, Font = T.mono, Text = "// MODULES", TextColor3 = T.dim, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left }, sidebar)

    content = new("Frame", { Size = UDim2.new(1, -160, 1, -102), Position = UDim2.new(0, 160, 0, 40), BackgroundColor3 = T.bg, BackgroundTransparency = 1, BorderSizePixel = 0 }, main)
    bottom = new("Frame", { Size = UDim2.new(1, 0, 0, 22), Position = UDim2.new(0, 0, 1, -22), BackgroundColor3 = T.panel, BorderSizePixel = 0, ZIndex = 2 }, main)
    grad(bottom, ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(11, 14, 20)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(7, 9, 13)),
    }, 0)
    new("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.accent, BackgroundTransparency = 0.75, BorderSizePixel = 0 }, bottom)

    local function makeIndicator(xAnchor, dotCol, label)
        local d = new("Frame", { Size = UDim2.fromOffset(6, 6), Position = UDim2.new(0, xAnchor, 0.5, -3), BackgroundColor3 = dotCol, BorderSizePixel = 0, ZIndex = 3 }, bottom)
        corner(d, 3)
        local dGlow = stroke(d, dotCol, 2, 0.3)
        new("TextLabel", { Size = UDim2.new(0, 30, 1, 0), Position = UDim2.new(0, xAnchor + 12, 0, 0), BackgroundTransparency = 1, Font = T.mono, Text = label, TextColor3 = T.dim, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3 }, bottom)
        local val = new("TextLabel", { Size = UDim2.new(0, 60, 1, 0), Position = UDim2.new(0, xAnchor + 44, 0, 0), BackgroundTransparency = 1, Font = T.mono, Text = "--", TextColor3 = dotCol, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3 }, bottom)
        task.spawn(function()
            while gui.Parent do
                TweenService:Create(dGlow, TweenInfo.new(0.45, Enum.EasingStyle.Sine), { Transparency = 0.85 }):Play()
                TweenService:Create(d, TweenInfo.new(0.45, Enum.EasingStyle.Sine), { BackgroundTransparency = 0.55 }):Play()
                task.wait(0.45)
                TweenService:Create(dGlow, TweenInfo.new(0.45, Enum.EasingStyle.Sine), { Transparency = 0 }):Play()
                TweenService:Create(d, TweenInfo.new(0.45, Enum.EasingStyle.Sine), { BackgroundTransparency = 0 }):Play()
                task.wait(0.45)
            end
        end)
        return val
    end
    local msVal = makeIndicator(14, T.green, "MS")
    local fpsVal = makeIndicator(150, T.danger, "FPS")

    new("TextLabel", { Size = UDim2.new(0, 200, 1, 0), Position = UDim2.new(1, -212, 0, 0), BackgroundTransparency = 1, Font = T.mono, Text = "@" .. LP.Name .. " // live", TextColor3 = T.dim, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 3 }, bottom)

    task.spawn(function()
        while gui.Parent do
            local ok, ping = pcall(function() return LP:GetNetworkPing() * 1000 end)
            if ok and ping then
                local ms = math.floor(ping + 0.5)
                msVal.Text = tostring(ms) .. "ms"
                msVal.TextColor3 = ms < 60 and T.green or ms < 120 and T.yellow or T.danger
            end
            task.wait(1)
        end
    end)
    task.spawn(function()
        local frames, elapsed = 0, 0
        RunService.RenderStepped:Connect(function(dt)
            frames = frames + 1; elapsed = elapsed + dt
            if elapsed >= 0.5 then
                local fps = math.floor(frames / elapsed + 0.5)
                frames, elapsed = 0, 0
                fpsVal.Text = tostring(fps)
                fpsVal.TextColor3 = fps > 100 and T.green or fps > 45 and T.yellow or T.danger
            end
        end)
    end)
    task.spawn(function()
        while gui.Parent do
            scan.Position = UDim2.new(0, 0, 0, -90)
            local t = TweenService:Create(scan, TweenInfo.new(4.5, Enum.EasingStyle.Linear), { Position = UDim2.new(0, 0, 1, 0) })
            t:Play(); t.Completed:Wait(); task.wait(0.4)
        end
    end)
    task.spawn(function()
        while gui.Parent do
            TweenService:Create(outerGlow, TweenInfo.new(2, Enum.EasingStyle.Sine), { Transparency = 0.55 }):Play()
            task.wait(2)
            TweenService:Create(outerGlow, TweenInfo.new(2, Enum.EasingStyle.Sine), { Transparency = 0.9 }):Play()
            task.wait(2)
        end
    end)

    self.gui = gui; self.main = main; self.sidebar = sidebar; self.content = content
    return self
end

function Window:Notify(title, body, col)
    col = col or T.accent
    local y = 12 + #self._toasts * 66
    local toast = new("Frame", { Size = UDim2.fromOffset(300, 58), Position = UDim2.new(1, -312, 0, y), BackgroundColor3 = T.card, BorderSizePixel = 0, ZIndex = 100 }, self.gui)
    corner(toast, 8)
    grad(toast, ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 23, 32)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 17, 24)),
    }, 0)
    stroke(toast, col, 1.5, 0.15)
    new("Frame", { Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = col, BorderSizePixel = 0, ZIndex = 101 }, toast)
    new("TextLabel", { Size = UDim2.new(1, -22, 0, 18), Position = UDim2.new(0, 14, 0, 6), BackgroundTransparency = 1, Font = T.fontBold, Text = title, TextColor3 = col, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 101 }, toast)
    new("TextLabel", { Size = UDim2.new(1, -22, 0, 30), Position = UDim2.new(0, 14, 0, 24), BackgroundTransparency = 1, Font = T.mono, Text = body, TextColor3 = T.muted, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, ZIndex = 101 }, toast)
    table.insert(self._toasts, toast)
    for i, t in ipairs(self._toasts) do
        TweenService:Create(t, TweenInfo.new(0.18), { Position = UDim2.new(1, -312, 0, 12 + (i - 1) * 66) }):Play()
    end
    task.delay(3.5, function()
        for i, t in ipairs(self._toasts) do
            if t == toast then table.remove(self._toasts, i); break end
        end
        TweenService:Create(toast, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
        for _, d in ipairs(toast:GetDescendants()) do
            if d:IsA("TextLabel") then TweenService:Create(d, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
            elseif d:IsA("Frame") then TweenService:Create(d, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
            elseif d:IsA("UIStroke") then TweenService:Create(d, TweenInfo.new(0.4), { Transparency = 1 }):Play()
            end
        end
        task.wait(0.5); toast:Destroy()
    end)
end

local Tab = {}
Tab.__index = Tab
function Window:Tab(name)
    local tab = setmetatable({ window = self, name = name }, Tab)
    local idx = #self.tabs
    local btn = new("TextButton", {
        Size = UDim2.new(1, -16, 0, 36), Position = UDim2.new(0, 8, 0, 34 + idx * 42),
        BackgroundColor3 = T.card, BackgroundTransparency = 1, BorderSizePixel = 0,
        Font = T.font, Text = "  " .. name, TextColor3 = T.muted, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, ZIndex = 2,
    }, self.sidebar)
    corner(btn, 8)
    local marker = new("TextLabel", { Size = UDim2.new(0, 14, 1, 0), Position = UDim2.new(0, 6, 0, 0), BackgroundTransparency = 1, Font = T.mono, Text = "▸", TextColor3 = T.accent, TextSize = 12, TextTransparency = 1, ZIndex = 3 }, btn)
    local ind = new("Frame", { Size = UDim2.new(0, 3, 0, 0), Position = UDim2.new(0, 0, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = T.accent, BorderSizePixel = 0, ZIndex = 3 }, btn)
    corner(ind, 2)
    local page = new("ScrollingFrame", {
        Size = UDim2.new(1, -24, 1, -24), Position = UDim2.new(0, 12, 0, 12),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3, ScrollBarImageColor3 = T.accent, Visible = false,
    }, self.content)
    new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, page)
    new("UIPadding", { PaddingRight = UDim.new(0, 8) }, page)
    tab.button, tab.indicator, tab.marker, tab.page = btn, ind, marker, page
    btn.MouseEnter:Connect(function()
        if self.current ~= tab then
            TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundTransparency = 0.55 }):Play()
            TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = T.hover }):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if self.current ~= tab then
            TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundTransparency = 1 }):Play()
        end
    end)
    btn.MouseButton1Click:Connect(function() self:Select(tab) end)
    table.insert(self.tabs, tab)
    if not self.current then self:Select(tab) end
    return tab
end
function Window:Select(tab)
    if self.current then
        local p = self.current
        TweenService:Create(p.button, TweenInfo.new(0.18), { BackgroundTransparency = 1 }):Play()
        TweenService:Create(p.button, TweenInfo.new(0.18), { TextColor3 = T.muted }):Play()
        TweenService:Create(p.indicator, TweenInfo.new(0.18), { Size = UDim2.new(0, 3, 0, 0) }):Play()
        TweenService:Create(p.marker, TweenInfo.new(0.14), { TextTransparency = 1 }):Play()
        p.page.Visible = false
    end
    self.current = tab
    TweenService:Create(tab.button, TweenInfo.new(0.18), { BackgroundTransparency = 0.75 }):Play()
    TweenService:Create(tab.button, TweenInfo.new(0.18), { BackgroundColor3 = T.card }):Play()
    TweenService:Create(tab.button, TweenInfo.new(0.18), { TextColor3 = T.text }):Play()
    TweenService:Create(tab.marker, TweenInfo.new(0.18), { TextTransparency = 0 }):Play()
    TweenService:Create(tab.indicator, TweenInfo.new(0.28, Enum.EasingStyle.Back), { Size = UDim2.new(0, 3, 0, 22) }):Play()
    tab.page.Visible = true
end
local function makeRow(page, height)
    local row = new("Frame", { Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = T.card, BorderSizePixel = 0, ClipsDescendants = true }, page)
    corner(row, 8)
    grad(row, ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 23, 32)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 17, 24)),
    }, 0)
    local bar = new("Frame", { Size = UDim2.new(0, 2, 1, 0), BackgroundColor3 = T.accent, BackgroundTransparency = 0.35, BorderSizePixel = 0 }, row)
    return row, bar
end
function Tab:Section(name)
    local wrap = new("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1 }, self.page)
    new("Frame", { Size = UDim2.fromOffset(3, 12), Position = UDim2.new(0, 0, 0.5, -6), BackgroundColor3 = T.accent, BorderSizePixel = 0 }, wrap)
    new("TextLabel", { Size = UDim2.new(1, -14, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Font = T.fontBold, Text = string.upper(name), TextColor3 = T.accent, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left }, wrap)
    new("Frame", { Size = UDim2.new(0, 120, 0, 1), Position = UDim2.new(0, 90, 0.5, 0), BackgroundColor3 = T.accent, BackgroundTransparency = 0.85, BorderSizePixel = 0 }, wrap)
end
function Tab:Label(text)
    new("TextLabel", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Font = T.font, Text = text, TextColor3 = T.muted, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left }, self.page)
end
function Tab:Button(cfg)
    cfg = cfg or {}
    local row, bar = makeRow(self.page, 34)
    local btn = new("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Font = T.fontBold, Text = string.upper(cfg.name or "button"), TextColor3 = T.text, TextSize = 12, AutoButtonColor = false }, row)
    btn.MouseEnter:Connect(function()
        TweenService:Create(bar, TweenInfo.new(0.14), { BackgroundTransparency = 0 }):Play()
        TweenService:Create(btn, TweenInfo.new(0.14), { TextColor3 = T.accent }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(bar, TweenInfo.new(0.14), { BackgroundTransparency = 0.35 }):Play()
        TweenService:Create(btn, TweenInfo.new(0.14), { TextColor3 = T.text }):Play()
    end)
    btn.MouseButton1Click:Connect(function() if cfg.callback then cfg.callback() end end)
    return btn
end
function Tab:Toggle(cfg)
    cfg = cfg or {}
    local state = cfg.default or false
    local row, bar = makeRow(self.page, 36)
    new("TextLabel", { Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 14, 0, 0), BackgroundTransparency = 1, Font = T.font, Text = cfg.name or "Toggle", TextColor3 = T.text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, row)
    local switch = new("Frame", { Size = UDim2.fromOffset(36, 18), Position = UDim2.new(1, -48, 0.5, -9), BackgroundColor3 = state and T.accent or T.hover, BorderSizePixel = 0 }, row)
    corner(switch, 9)
    local knob = new("Frame", { Size = UDim2.fromOffset(14, 14), Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7), BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0 }, switch)
    corner(knob, 7)
    local knobGlow = stroke(knob, T.accent, 2, state and 0.4 or 1)
    local btn = new("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "" }, row)
    local function set(v, silent)
        state = v
        TweenService:Create(knob, TweenInfo.new(0.16, Enum.EasingStyle.Quad), { Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7) }):Play()
        TweenService:Create(switch, TweenInfo.new(0.16), { BackgroundColor3 = state and T.accent or T.hover }):Play()
        TweenService:Create(knobGlow, TweenInfo.new(0.2), { Transparency = state and 0.4 or 1 }):Play()
        TweenService:Create(bar, TweenInfo.new(0.2), { BackgroundTransparency = state and 0 or 0.35 }):Play()
        if not silent and cfg.callback then cfg.callback(state) end
    end
    btn.MouseButton1Click:Connect(function() set(not state) end)
    if cfg.callback then cfg.callback(state) end
    return { set = function(v) set(v) end, get = function() return state end }
end
function Tab:Slider(cfg)
    cfg = cfg or {}
    local min, max = cfg.min or 0, cfg.max or 100
    local value = cfg.default or min
    local suffix = cfg.suffix or ""
    local row, bar = makeRow(self.page, 48)
    new("TextLabel", { Size = UDim2.new(1, -110, 0, 20), Position = UDim2.new(0, 14, 0, 4), BackgroundTransparency = 1, Font = T.font, Text = cfg.name or "Slider", TextColor3 = T.text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, row)
    local valLabel = new("TextLabel", { Size = UDim2.new(0, 90, 0, 20), Position = UDim2.new(1, -102, 0, 4), BackgroundTransparency = 1, Font = T.mono, Text = tostring(value) .. suffix, TextColor3 = T.accent, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right }, row)
    local track = new("Frame", { Size = UDim2.new(1, -28, 0, 6), Position = UDim2.new(0, 14, 1, -18), BackgroundColor3 = T.hover, BorderSizePixel = 0 }, row)
    corner(track, 3)
    local rel = (value - min) / (max - min)
    local fill = new("Frame", { Size = UDim2.new(rel, 0, 1, 0), BackgroundColor3 = T.accent, BorderSizePixel = 0 }, track)
    corner(fill, 3)
    grad(fill, ColorSequence.new{ ColorSequenceKeypoint.new(0, T.accent2), ColorSequenceKeypoint.new(1, T.accent) }, 0)
    local knob = new("Frame", { Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(rel, 0, 0.5, 0), BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, ZIndex = 2 }, track)
    corner(knob, 6)
    stroke(knob, T.accent, 2, 0)
    local dragging = false
    local function update(input)
        local r = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        value = math.floor(min + (max - min) * r + 0.5)
        fill.Size = UDim2.new(r, 0, 1, 0); knob.Position = UDim2.new(r, 0, 0.5, 0)
        valLabel.Text = tostring(value) .. suffix
        if cfg.callback then cfg.callback(value) end
    end
    local function setVal(v, silent)
        v = math.clamp(v or min, min, max); value = v
        local r = (v - min) / (max - min)
        fill.Size = UDim2.new(r, 0, 1, 0); knob.Position = UDim2.new(r, 0, 0.5, 0)
        valLabel.Text = tostring(v) .. suffix
        if not silent and cfg.callback then cfg.callback(v) end
    end
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            TweenService:Create(bar, TweenInfo.new(0.14), { BackgroundTransparency = 0 }):Play()
            update(input)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then update(input) end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            TweenService:Create(bar, TweenInfo.new(0.2), { BackgroundTransparency = 0.35 }):Play()
        end
    end)
    if cfg.callback then cfg.callback(value) end
    return { set = function(v) setVal(v) end, get = function() return value end }
end
function Tab:Selector(cfg)
    cfg = cfg or {}
    local options = cfg.options or {}
    local current = cfg.default or options[1]
    local row, bar = makeRow(self.page, 46)
    new("TextLabel", { Size = UDim2.new(1, -24, 0, 18), Position = UDim2.new(0, 14, 0, 4), BackgroundTransparency = 1, Font = T.font, Text = cfg.name or "Select", TextColor3 = T.text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, row)
    local pill = new("Frame", { Size = UDim2.new(1, -28, 0, 20), Position = UDim2.new(0, 14, 1, -24), BackgroundColor3 = T.bg, BorderSizePixel = 0 }, row)
    corner(pill, 6)
    stroke(pill, T.accent, 1, 0.7)
    new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center }, pill)
    new("UIPadding", { PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 2) }, pill)
    local buttons = {}
    local function select(opt, silent)
        current = opt
        for name, b in pairs(buttons) do
            if name == opt then
                TweenService:Create(b, TweenInfo.new(0.14), { BackgroundColor3 = T.accent, BackgroundTransparency = 0 }):Play()
                TweenService:Create(b, TweenInfo.new(0.14), { TextColor3 = T.bg }):Play()
            else
                TweenService:Create(b, TweenInfo.new(0.14), { BackgroundColor3 = T.card, BackgroundTransparency = 0.4 }):Play()
                TweenService:Create(b, TweenInfo.new(0.14), { TextColor3 = T.muted }):Play()
            end
        end
        TweenService:Create(bar, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
        if not silent and cfg.callback then cfg.callback(opt) end
    end
    for _, opt in ipairs(options) do
        local seg = new("TextButton", { Size = UDim2.new(1 / #options, -2, 1, -4), BackgroundColor3 = T.card, BackgroundTransparency = 0.4, BorderSizePixel = 0, Font = T.mono, Text = string.upper(opt), TextColor3 = T.muted, TextSize = 10, AutoButtonColor = false }, pill)
        corner(seg, 4)
        buttons[opt] = seg
        seg.MouseButton1Click:Connect(function() select(opt) end)
    end
    select(current, true)
    return { get = function() return current end, set = function(opt) select(opt) end }
end
function Tab:ColorPicker(cfg)
    cfg = cfg or {}
    local palette = cfg.palette or {}
    local current = cfg.default or 1
    local row, bar = makeRow(self.page, 50)
    new("TextLabel", { Size = UDim2.new(1, -24, 0, 18), Position = UDim2.new(0, 14, 0, 4), BackgroundTransparency = 1, Font = T.font, Text = cfg.name or "Color", TextColor3 = T.text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, row)
    local swatchRow = new("Frame", { Size = UDim2.new(1, -28, 0, 22), Position = UDim2.new(0, 14, 1, -26), BackgroundTransparency = 1 }, row)
    new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center }, swatchRow)
    local swatches = {}
    local function select(idx, silent)
        current = idx
        for i, sw in ipairs(swatches) do
            local isSel = (i == idx)
            TweenService:Create(sw.stroke, TweenInfo.new(0.14), { Transparency = isSel and 0 or 0.75, Thickness = isSel and 2 or 1 }):Play()
            TweenService:Create(sw.btn, TweenInfo.new(0.14), { Size = isSel and UDim2.fromOffset(20,20) or UDim2.fromOffset(16,16) }):Play()
        end
        TweenService:Create(bar, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
        if not silent and cfg.callback then cfg.callback(palette[idx], idx) end
    end
    for i, entry in ipairs(palette) do
        local sw = new("TextButton", { Size = UDim2.fromOffset(16, 16), BackgroundColor3 = entry.color, BorderSizePixel = 0, Text = "", AutoButtonColor = false }, swatchRow)
        sw:SetAttribute("themeLock", true)
        corner(sw, 10)
        local st = stroke(sw, Color3.new(1,1,1), 1, 0.75)
        st:SetAttribute("themeLock", true)
        swatches[i] = { btn = sw, stroke = st }
        sw.MouseButton1Click:Connect(function() select(i) end)
    end
    select(current, true)
    return { get = function() return current end, set = function(idx) select(idx) end }
end
function Tab:Keybind(cfg)
    cfg = cfg or {}
    local default = cfg.default or { kind = "key", value = Enum.KeyCode.LeftAlt }
    local binding = default
    local listening = false
    local row, bar = makeRow(self.page, 36)
    new("TextLabel", { Size = UDim2.new(1, -120, 1, 0), Position = UDim2.new(0, 14, 0, 0), BackgroundTransparency = 1, Font = T.font, Text = cfg.name or "Keybind", TextColor3 = T.text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, row)
    local keyBtn = new("TextButton", {
        Size = UDim2.new(0, 90, 0, 22), Position = UDim2.new(1, -104, 0.5, -11),
        BackgroundColor3 = T.bg, BorderSizePixel = 0, Font = T.mono,
        Text = bindLabel(binding), TextColor3 = T.accent, TextSize = 11, AutoButtonColor = false,
    }, row)
    corner(keyBtn, 6)
    local keyStroke = stroke(keyBtn, T.accent, 1, 0.6)
    local function setBind(b, silent)
        binding = b
        keyBtn.Text = bindLabel(b)
        if not silent and cfg.callback then cfg.callback(b) end
    end
    local function stopListening()
        listening = false
        keyBtn.Text = bindLabel(binding)
        TweenService:Create(keyStroke, TweenInfo.new(0.14), { Transparency = 0.6 }):Play()
        TweenService:Create(bar, TweenInfo.new(0.2), { BackgroundTransparency = 0.35 }):Play()
    end
    keyBtn.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        keyBtn.Text = "[ ... ]"
        TweenService:Create(keyStroke, TweenInfo.new(0.14), { Transparency = 0 }):Play()
        TweenService:Create(bar, TweenInfo.new(0.14), { BackgroundTransparency = 0 }):Play()
    end)
    keyBtn.MouseButton2Click:Connect(function()
        if listening then return end
        setBind(default)
    end)
    UIS.InputBegan:Connect(function(input, gpe)
        if not listening then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == Enum.KeyCode.Escape then stopListening(); return end
            stopListening()
            setBind({ kind = "key", value = input.KeyCode })
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.MouseButton2
        or input.UserInputType == Enum.UserInputType.MouseButton3 then
            stopListening()
            setBind({ kind = "mouse", value = input.UserInputType })
        end
    end)
    if cfg.callback then cfg.callback(binding) end
    return { get = function() return binding end, set = function(b) setBind(b) end }
end

-- ═══════════ INSTANTIATE ═══════════
local win = Window.new({ title = "vysesaint" })
Theme.root = win.gui
local UI = { toggles = {}, sliders = {}, selectors = {}, colors = {}, keybinds = {} }

local aimTab      = win:Tab("Aim")
local visualTab   = win:Tab("Visual")
local miscTab     = win:Tab("Misc")
local settingsTab = win:Tab("Settings")

aimTab:Section("targeting — only esp-visible")
UI.toggles.aimAssist = aimTab:Toggle({
    name = "Aim Assist", default = false,
    callback = function(v) AimConfig.aimAssist = v end,
})
UI.toggles.silentAim = aimTab:Toggle({
    name = "Silent Aim", default = false,
    callback = function(v) AimConfig.silentAim = v end,
})
UI.selectors.aimMode = aimTab:Selector({
    name = "Mode",
    options = { "hold", "toggle", "always" },
    default = "hold",
    callback = function(v) AimConfig.aimMode = v end,
})
UI.keybinds.aimKey = aimTab:Keybind({
    name = "Activation",
    default = { kind = "mouse", value = Enum.UserInputType.MouseButton2 },
    callback = function(b) AimConfig.aimBind = b end,
})
UI.selectors.targetPart = aimTab:Selector({
    name = "Target Part",
    options = { "Head", "Body", "Root", "Foot" },
    default = "Head",
    callback = function(v) AimConfig.targetPart = v end,
})
UI.toggles.wallCheck = aimTab:Toggle({
    name = "Wall Check", default = false,
    callback = function(v) AimConfig.wallCheck = v end,
})
aimTab:Section("parameters")
UI.sliders.fov = aimTab:Slider({
    name = "FOV", min = 10, max = 800, default = 200, suffix = "px",
    callback = function(v) AimConfig.fov = v end,
})
UI.sliders.smoothness = aimTab:Slider({
    name = "Smoothing %", min = 1, max = 100, default = 15, suffix = "%",
    callback = function(v) AimConfig.smoothness = v end,
})
aimTab:Section("display")
UI.toggles.fovVisible = aimTab:Toggle({
    name = "FOV Visible", default = true,
    callback = function(v) AimConfig.fovVisible = v end,
})

visualTab:Section("esp")
UI.toggles.boxes2D = visualTab:Toggle({ name = "Player Boxes 2D", default = true, callback = function(v) ESPConfig.boxes2D = v end })
UI.toggles.bones = visualTab:Toggle({ name = "Player Bones", default = false, callback = function(v) ESPConfig.bones = v end })
UI.toggles.npcBoxes2D = visualTab:Toggle({ name = "NPC Boxes 2D", default = false, callback = function(v) ESPConfig.npcBoxes2D = v end })
UI.selectors.filter = visualTab:Selector({ name = "ESP Filter", options = { "all", "enemy", "team" }, default = "all", callback = function(v) ESPConfig.filter = v end })
UI.toggles.nameTags = visualTab:Toggle({ name = "Name Tags", default = false, callback = function(v) ESPConfig.nameTags = v end })
UI.toggles.healthBars = visualTab:Toggle({ name = "Health Bars", default = false, callback = function(v) ESPConfig.healthBars = v end })
UI.toggles.tracers = visualTab:Toggle({ name = "Tracers", default = true, callback = function(v) ESPConfig.tracers = v end })
visualTab:Section("render")
UI.sliders.renderDistance = visualTab:Slider({ name = "Render Distance", min = 100, max = 5000, default = 1000, suffix = "st", callback = function(v) ESPConfig.renderDistance = v end })

miscTab:Section("player")
UI.toggles.antiAfk = miscTab:Toggle({ name = "Anti AFK", default = false, callback = function(v) AntiAfk.set(v) end })

settingsTab:Section("appearance")
UI.colors.menuColor = settingsTab:ColorPicker({ name = "Menu Color", palette = MENU_PALETTE, default = 1, callback = function(entry, idx) if entry then Theme.apply(entry, idx) end end })
settingsTab:Section("esp colors")
UI.colors.teamColor = settingsTab:ColorPicker({ name = "Team Color", palette = ESP_PALETTE, default = 2, callback = function(entry) if entry then ESPConfig.teamColor = entry.color end end })
UI.colors.enemyColor = settingsTab:ColorPicker({ name = "Enemy Color", palette = ESP_PALETTE, default = 1, callback = function(entry) if entry then ESPConfig.enemyColor = entry.color end end })
settingsTab:Section("esp thickness")
UI.sliders.boxThickness = settingsTab:Slider({ name = "Box Thickness", min = 1, max = 5, default = 1, suffix = "px", callback = function(v) ESPConfig.boxThickness = v end })
UI.sliders.tracerThickness = settingsTab:Slider({ name = "Tracer Thickness", min = 1, max = 5, default = 1, suffix = "px", callback = function(v) ESPConfig.tracerThickness = v end })
settingsTab:Section("configuration")
settingsTab:Label("File IO: " .. Config.status())

settingsTab:Section("actions")
settingsTab:Button({
    name = "Save Config",
    callback = function()
        local data = {
            aimAssist = AimConfig.aimAssist, silentAim = AimConfig.silentAim,
            aimMode = AimConfig.aimMode, aimBind = bindToTable(AimConfig.aimBind),
            targetPart = AimConfig.targetPart, wallCheck = AimConfig.wallCheck,
            fov = AimConfig.fov, fovVisible = AimConfig.fovVisible, smoothness = AimConfig.smoothness,
            boxes2D = ESPConfig.boxes2D, bones = ESPConfig.bones, npcBoxes2D = ESPConfig.npcBoxes2D,
            filter = ESPConfig.filter, nameTags = ESPConfig.nameTags, healthBars = ESPConfig.healthBars,
            tracers = ESPConfig.tracers, renderDistance = ESPConfig.renderDistance,
            boxThickness = ESPConfig.boxThickness, tracerThickness = ESPConfig.tracerThickness,
            teamColor = colorToTable(ESPConfig.teamColor), enemyColor = colorToTable(ESPConfig.enemyColor),
            menuColor = Theme.current,
        }
        local ok, path = Config.save(data)
        if ok then win:Notify("CONFIG SAVED", "to " .. path, T.green)
        else win:Notify("SAVE FAILED", tostring(path), T.danger) end
    end,
})
settingsTab:Button({
    name = "Load Config",
    callback = function()
        local ok, data = Config.load()
        if not ok then win:Notify("LOAD FAILED", tostring(data), T.danger); return end
        pcall(function()
            if data.aimAssist ~= nil then UI.toggles.aimAssist.set(data.aimAssist) end
            if data.silentAim ~= nil then UI.toggles.silentAim.set(data.silentAim) end
            if data.aimMode then UI.selectors.aimMode.set(data.aimMode) end
            if data.aimBind then local b = tableToBind(data.aimBind); if b then UI.keybinds.aimKey.set(b) end end
            if data.targetPart then UI.selectors.targetPart.set(data.targetPart) end
            if data.wallCheck ~= nil then UI.toggles.wallCheck.set(data.wallCheck) end
            if data.fov then UI.sliders.fov.set(data.fov) end
            if data.fovVisible ~= nil then UI.toggles.fovVisible.set(data.fovVisible) end
            if data.smoothness then UI.sliders.smoothness.set(data.smoothness) end
            if data.boxes2D ~= nil then UI.toggles.boxes2D.set(data.boxes2D) end
            if data.bones ~= nil then UI.toggles.bones.set(data.bones) end
            if data.npcBoxes2D ~= nil then UI.toggles.npcBoxes2D.set(data.npcBoxes2D) end
            if data.filter then UI.selectors.filter.set(data.filter) end
            if data.nameTags ~= nil then UI.toggles.nameTags.set(data.nameTags) end
            if data.healthBars ~= nil then UI.toggles.healthBars.set(data.healthBars) end
            if data.tracers ~= nil then UI.toggles.tracers.set(data.tracers) end
            if data.renderDistance then UI.sliders.renderDistance.set(data.renderDistance) end
            if data.boxThickness then UI.sliders.boxThickness.set(data.boxThickness) end
            if data.tracerThickness then UI.sliders.tracerThickness.set(data.tracerThickness) end
            if data.teamColor then local c = tableToColor(data.teamColor); if c then ESPConfig.teamColor = c end end
            if data.enemyColor then local c = tableToColor(data.enemyColor); if c then ESPConfig.enemyColor = c end end
            if data.menuColor then UI.colors.menuColor.set(data.menuColor) end
        end)
        win:Notify("CONFIG LOADED", "from " .. CONFIG_FILE, T.green)
    end,
})
settingsTab:Button({
    name = "Reset",
    callback = function()
        local wiped = Config.wipe()
        AimConfig.aimAssist, AimConfig.silentAim = false, false
        AimConfig.aimMode = "hold"
        AimConfig.aimBind = { kind = "mouse", value = Enum.UserInputType.MouseButton2 }
        AimConfig.targetPart, AimConfig.wallCheck = "Head", false
        AimConfig.fov, AimConfig.fovVisible, AimConfig.smoothness = 200, true, 15
        ESPConfig.boxes2D, ESPConfig.bones, ESPConfig.npcBoxes2D = true, false, false
        ESPConfig.filter, ESPConfig.nameTags, ESPConfig.healthBars = "all", false, false
        ESPConfig.tracers, ESPConfig.renderDistance = true, 1000
        ESPConfig.boxThickness, ESPConfig.tracerThickness = 1, 1
        if UI.toggles.aimAssist then UI.toggles.aimAssist.set(false) end
        if UI.toggles.silentAim then UI.toggles.silentAim.set(false) end
        if UI.selectors.aimMode then UI.selectors.aimMode.set("hold") end
        if UI.keybinds.aimKey then UI.keybinds.aimKey.set({ kind = "mouse", value = Enum.UserInputType.MouseButton2 }) end
        if UI.selectors.targetPart then UI.selectors.targetPart.set("Head") end
        if UI.toggles.wallCheck then UI.toggles.wallCheck.set(false) end
        if UI.sliders.fov then UI.sliders.fov.set(200) end
        if UI.sliders.smoothness then UI.sliders.smoothness.set(15) end
        if UI.toggles.boxes2D then UI.toggles.boxes2D.set(true) end
        if UI.toggles.bones then UI.toggles.bones.set(false) end
        if UI.toggles.npcBoxes2D then UI.toggles.npcBoxes2D.set(false) end
        if UI.toggles.nameTags then UI.toggles.nameTags.set(false) end
        if UI.toggles.healthBars then UI.toggles.healthBars.set(false) end
        if UI.toggles.tracers then UI.toggles.tracers.set(true) end
        if UI.toggles.antiAfk then UI.toggles.antiAfk.set(false) end
        if UI.selectors.filter then UI.selectors.filter.set("all") end
        if UI.sliders.renderDistance then UI.sliders.renderDistance.set(1000) end
        win:Notify("RESET", wiped and "defaults restored" or "defaults restored (no file)", T.yellow)
    end,
})
settingsTab:Button({
    name = "Unload Menu",
    callback = function()
        ESP.stop(); AntiAfk.set(false)
        if fovCircle then pcall(function() fovCircle:Remove() end) end
        pcall(function() hookmetamethod(game, "__index", oldIndex) end)
        win.gui:Destroy()
    end,
})

ESP.start()

-- ═══════════ MAIN LOOP ═══════════
RunService.RenderStepped:Connect(function()
    local now = tick()
    if now - lastNpcRefresh >= NPC_REFRESH_INTERVAL then
        lastNpcRefresh = now
        refreshNpcCandidates()
    end

    if fovCircle then
        local showRing = (AimConfig.aimAssist and AimConfig.fovVisible) or AimConfig.silentAim
        if showRing then
            local vp = Camera.ViewportSize
            fovCircle.Visible = true
            fovCircle.Position = Vector2.new(vp.X / 2, vp.Y / 2)
            fovCircle.Radius = AimConfig.fov
            if AimConfig.silentAim and not AimConfig.aimAssist then
                fovCircle.Color = T.accent2
                fovCircle.Transparency = 0.7
            else
                fovCircle.Color = aimActive() and T.accent2 or T.accent
                fovCircle.Transparency = aimActive() and 0.9 or 0.65
            end
        else
            fovCircle.Visible = false
        end
    end

    aimbotStep()
end)

-- ═══════════ AUTO-LOAD ═══════════
task.spawn(function()
    task.wait(0.6)
    if Config.exists() then
        local ok, data = Config.load()
        if ok then
            pcall(function()
                if data.aimAssist ~= nil then UI.toggles.aimAssist.set(data.aimAssist) end
                if data.silentAim ~= nil then UI.toggles.silentAim.set(data.silentAim) end
                if data.aimMode then UI.selectors.aimMode.set(data.aimMode) end
                if data.aimBind then local b = tableToBind(data.aimBind); if b then UI.keybinds.aimKey.set(b) end end
                if data.targetPart then UI.selectors.targetPart.set(data.targetPart) end
                if data.wallCheck ~= nil then UI.toggles.wallCheck.set(data.wallCheck) end
                if data.fov then UI.sliders.fov.set(data.fov) end
                if data.fovVisible ~= nil then UI.toggles.fovVisible.set(data.fovVisible) end
                if data.smoothness then UI.sliders.smoothness.set(data.smoothness) end
                if data.boxes2D ~= nil then UI.toggles.boxes2D.set(data.boxes2D) end
                if data.bones ~= nil then UI.toggles.bones.set(data.bones) end
                if data.npcBoxes2D ~= nil then UI.toggles.npcBoxes2D.set(data.npcBoxes2D) end
                if data.filter then UI.selectors.filter.set(data.filter) end
                if data.nameTags ~= nil then UI.toggles.nameTags.set(data.nameTags) end
                if data.healthBars ~= nil then UI.toggles.healthBars.set(data.healthBars) end
                if data.tracers ~= nil then UI.toggles.tracers.set(data.tracers) end
                if data.renderDistance then UI.sliders.renderDistance.set(data.renderDistance) end
                if data.boxThickness then UI.sliders.boxThickness.set(data.boxThickness) end
                if data.tracerThickness then UI.sliders.tracerThickness.set(data.tracerThickness) end
                if data.teamColor then local c = tableToColor(data.teamColor); if c then ESPConfig.teamColor = c end end
                if data.enemyColor then local c = tableToColor(data.enemyColor); if c then ESPConfig.enemyColor = c end end
                if data.menuColor then UI.colors.menuColor.set(data.menuColor) end
            end)
            win:Notify("CONFIG AUTO-LOADED", CONFIG_FILE, T.accent)
        end
    end
end)

-- ═══════════ KEYPRESS ═══════════
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.Delete then
        win.gui.Enabled = not win.gui.Enabled
    end
end)
