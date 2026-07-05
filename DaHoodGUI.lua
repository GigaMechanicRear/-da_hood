-- Da Hood Hub | Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local flags = {
    ESP = false, Aimbot = false, SilentAim = false,
    InfJump = false, NoClip = false,
}
local settings = { WalkSpeed = 16, AimFOV = 120 }
local espObjects = {}

local function getChar() return LocalPlayer.Character end
local function getHRP(c) return c and c:FindFirstChild("HumanoidRootPart") end
local function myHRP() return getHRP(getChar()) end

local function getClosestPlayer(fov)
    local closest, minDist = nil, fov or math.huge
    local mouse = UserInputService:GetMouseLocation()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local head = p.Character:FindFirstChild("Head")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if head and hum and hum.Health > 0 then
                local sp, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local d = (Vector2.new(sp.X, sp.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude
                    if d < minDist then closest, minDist = p, d end
                end
            end
        end
    end
    return closest
end

local Window = Rayfield:CreateWindow({
    Name = "Da Hood Hub",
    LoadingTitle = "Da Hood Hub",
    LoadingSubtitle = "Enjoy!",
    ConfigurationSaving = { Enabled = true, FolderName = "DaHoodHub", FileName = "DaHoodHub" },
})

-- ===== COMBAT TAB =====
local Combat = Window:CreateTab("Combat", 4483362458)
Combat:CreateToggle({ Name="Aimbot (hold Right Mouse)", CurrentValue=false, Callback=function(v) flags.Aimbot=v end })
Combat:CreateToggle({ Name="Silent Aim", CurrentValue=false, Callback=function(v) flags.SilentAim=v end })
Combat:CreateSlider({ Name="Aim FOV", Range={50,500}, Increment=10, CurrentValue=120, Callback=function(v) settings.AimFOV=v end })

-- ===== VISUAL TAB =====
local Visual = Window:CreateTab("Visual", 4483362458)
Visual:CreateToggle({ Name="Player ESP (name + HP)", CurrentValue=false, Callback=function(v)
    flags.ESP=v
    if not v then
        for p,d in pairs(espObjects) do
            if d.hl then d.hl:Destroy() end
            if d.bg then d.bg:Destroy() end
            espObjects[p]=nil
        end
    end
end })

-- ===== MOVEMENT TAB =====
local Move = Window:CreateTab("Movement", 4483362458)
Move:CreateSlider({ Name="WalkSpeed", Range={16,120}, Increment=1, CurrentValue=16, Callback=function(v)
    settings.WalkSpeed=v
    local c=getChar()
    local h=c and c:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed=v end
end })
Move:CreateToggle({ Name="Infinite Jump", CurrentValue=false, Callback=function(v) flags.InfJump=v end })
Move:CreateToggle({ Name="No Clip", CurrentValue=false, Callback=function(v) flags.NoClip=v end })

-- keep walkspeed applied on respawn
LocalPlayer.CharacterAdded:Connect(function(c)
    local h = c:WaitForChild("Humanoid")
    task.wait(1)
    h.WalkSpeed = settings.WalkSpeed
end)

-- infinite jump
UserInputService.JumpRequest:Connect(function()
    if flags.InfJump then
        local h = getChar() and getChar():FindFirstChildOfClass("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- noclip loop
RunService.Stepped:Connect(function()
    if flags.NoClip then
        local c = getChar()
        if c then
            for _, part in ipairs(c:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- aimbot: snap camera to closest head while RMB held
RunService.RenderStepped:Connect(function()
    if flags.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = getClosestPlayer(settings.AimFOV)
        if target and target.Character then
            local head = target.Character:FindFirstChild("Head")
            if head then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
            end
        end
    end
end)

-- ESP loop
RunService.RenderStepped:Connect(function()
    if not flags.ESP then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local char = p.Character
            local hrp = getHRP(char)
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hrp and hum then
                local d = espObjects[p]
                if not d then
                    local hl = Instance.new("Highlight")
                    hl.FillTransparency = 0.6
                    hl.FillColor = Color3.fromRGB(255,60,60)
                    local bg = Instance.new("BillboardGui")
                    bg.Size = UDim2.new(0,140,0,34)
                    bg.StudsOffset = Vector3.new(0,3.2,0)
                    bg.AlwaysOnTop = true
                    local lbl = Instance.new("TextLabel")
                    lbl.Size = UDim2.new(1,0,1,0)
                    lbl.BackgroundTransparency = 1
                    lbl.TextColor3 = Color3.fromRGB(255,255,255)
                    lbl.TextStrokeTransparency = 0
                    lbl.Font = Enum.Font.GothamBold
                    lbl.TextScaled = true
                    lbl.Parent = bg
                    d = {hl=hl, bg=bg, lbl=lbl}
                    espObjects[p] = d
                end
                d.hl.Adornee = char; d.hl.Parent = char
                d.bg.Adornee = hrp; d.bg.Parent = hrp
                d.lbl.Text = string.format("%s | HP %d", p.Name, math.floor(hum.Health))
            end
        end
    end
end)

Players.PlayerRemoving:Connect(function(p)
    local d = espObjects[p]
    if d then if d.hl then d.hl:Destroy() end if d.bg then d.bg:Destroy() end espObjects[p]=nil end
end)

-- Silent Aim: hook not universal; provide FireServer redirect helper note via metatable if supported
if flags then
    pcall(function()
        local mt = getrawmetatable and getrawmetatable(game)
        if mt and setreadonly then
            setreadonly(mt, false)
            local old = mt.__namecall
            mt.__namecall = newcclosure and newcclosure(function(self, ...)
                local args = {...}
                local method = getnamecallmethod and getnamecallmethod()
                if flags.SilentAim and method == "FireServer" then
                    local t = getClosestPlayer(settings.AimFOV)
                    if t and t.Character and t.Character:FindFirstChild("Head") then
                        for i,v in ipairs(args) do
                            if typeof(v) == "Vector3" then args[i] = t.Character.Head.Position end
                        end
                        return old(self, unpack(args))
                    end
                end
                return old(self, ...)
            end) or old
            setreadonly(mt, true)
        end
    end)
end

Rayfield:Notify({Title="Da Hood Hub", Content="Loaded! Silent Aim needs an executor.", Duration=5})
