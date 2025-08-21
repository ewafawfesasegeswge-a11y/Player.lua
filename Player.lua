------------------------------------------------------
-- Player Tab
------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local PlayerTab = Window:AddTab({
    Name = "Players",
    Icon = "users",
    Description = "Player-related features",
})

local PlayerBox = PlayerTab:AddLeftGroupbox("Player Actions")
local AutoBox = PlayerTab:AddRightGroupbox("Auto Features")

-------------------------------------------------
-- Dropdown: Player Selection
-------------------------------------------------
local PlayerDropdown = PlayerBox:AddDropdown("PlayerDropdown", {
    Values = {},
    Default = nil,
    Multi = false,
    Text = "Select Player",
})

local function refreshPlayers()
    local names = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(names, plr.Name)
        end
    end
    PlayerDropdown:SetValues(names)
end

Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(refreshPlayers)
refreshPlayers()

-------------------------------------------------
-- TP and Fling Logic
-------------------------------------------------
local function flingPlayer(target, duration)
    local char = LocalPlayer.Character
    local targetChar = target.Character
    if not (char and targetChar) then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if not (root and targetRoot) then return end

    -- Crazy fling
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(9999, 9999, 9999)
    bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bv.Parent = root

    root.CFrame = targetRoot.CFrame
    task.wait(0.1)
    bv:Destroy()
end

-------------------------------------------------
-- Buttons
-------------------------------------------------
PlayerBox:AddButton("TP to Person", function()
    local target = Players:FindFirstChild(PlayerDropdown.Value)
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character:PivotTo(
            target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
        )
    end
end)

PlayerBox:AddButton("Fling Selected", function()
    local target = Players:FindFirstChild(PlayerDropdown.Value)
    if target then
        flingPlayer(target, 0.5)
    end
end)

PlayerBox:AddButton("Fling All", function()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            flingPlayer(plr, 0.5)
            task.wait(0.3)
        end
    end
end)

-------------------------------------------------
-- Toggles
-------------------------------------------------
local flingConn
PlayerBox:AddToggle("ContinuousFling", {
    Text = "Continuous Fling Selected",
    Default = false,
    Callback = function(state)
        if state then
            flingConn = RunService.Heartbeat:Connect(function()
                local target = Players:FindFirstChild(PlayerDropdown.Value)
                if target then
                    flingPlayer(target)
                end
            end)
        else
            if flingConn then flingConn:Disconnect() flingConn = nil end
        end
    end,
})

local tpConn
PlayerBox:AddToggle("ContinuousTP", {
    Text = "Continuous TP to Selected",
    Default = false,
    Callback = function(state)
        if state then
            tpConn = RunService.Heartbeat:Connect(function()
                local target = Players:FindFirstChild(PlayerDropdown.Value)
                if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character:PivotTo(
                        target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                    )
                end
            end)
        else
            if tpConn then tpConn:Disconnect() tpConn = nil end
        end
    end,
})

-- Continuous Fling All (one cycle only)
PlayerBox:AddToggle("ContinuousFlingAll", {
    Text = "Continuous Fling All (One Cycle)",
    Default = false,
    Callback = function(state)
        if state then
            task.spawn(function()
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer then
                        flingPlayer(plr)
                        task.wait(0.2)
                    end
                end
                Toggles.ContinuousFlingAll:SetValue(false)
            end)
        end
    end
})

-------------------------------------------------
-- Qi/Comprehension Zone Autofarm (Game-specific)
-------------------------------------------------
local allowedGameId = 14483332676 -- ✅ your game ID

if game.PlaceId == allowedGameId then
    local ZoneRemote = ReplicatedStorage.RemoteEvents.Player.Cultivation:WaitForChild("ZoneEvent")
    local qiZones = { "Statue", "YSW", "BloodCC", "SB", "FoH" }
    local selectedQiZone = qiZones[1]
    local autoQiEnabled = false
    local currentQiZone = nil

    AutoBox:AddDropdown("QiZoneDropdown", {
        Values = qiZones,
        Value = selectedQiZone,
        Text = "Select Qi Zone",
        Callback = function(value)
            selectedQiZone = value
            if autoQiEnabled then
                if currentQiZone then
                    ZoneRemote:FireServer(LocalPlayer, currentQiZone, "Exited")
                end
                ZoneRemote:FireServer(LocalPlayer, value, "Entered")
                currentQiZone = value
            end
        end,
    })

    AutoBox:AddToggle("AutoQiZoneToggle", {
        Text = "Enable Auto Qi Zone",
        Default = false,
        Callback = function(state)
            autoQiEnabled = state
            if state then
                ZoneRemote:FireServer(LocalPlayer, selectedQiZone, "Entered")
                currentQiZone = selectedQiZone
            else
                if currentQiZone then
                    ZoneRemote:FireServer(LocalPlayer, currentQiZone, "Exited")
                    currentQiZone = nil
                end
            end
        end,
    })

    local CompRemote = ReplicatedStorage.RemoteEvents.Player.Comprehension:WaitForChild("ComprehensionZone")
    local compZones = { "EL", "HVP" }
    local selectedCompZone = compZones[1]
    local autoCompEnabled = false
    local currentCompZone = nil

    AutoBox:AddDropdown("CompZoneDropdown", {
        Values = compZones,
        Value = selectedCompZone,
        Text = "Select Comprehension Zone",
        Callback = function(value)
            selectedCompZone = value
            if autoCompEnabled then
                if currentCompZone then
                    CompRemote:FireServer(LocalPlayer, currentCompZone, "Exited")
                end
                CompRemote:FireServer(LocalPlayer, value, "Entered")
                currentCompZone = value
            end
        end,
    })

    AutoBox:AddToggle("AutoCompZoneToggle", {
        Text = "Enable Auto Comprehension Zone",
        Default = false,
        Callback = function(state)
            autoCompEnabled = state
            if state then
                CompRemote:FireServer(LocalPlayer, selectedCompZone, "Entered")
                currentCompZone = selectedCompZone
            else
                if currentCompZone then
                    CompRemote:FireServer(LocalPlayer, currentCompZone, "Exited")
                    currentCompZone = nil
                end
            end
        end,
    })
end

-------------------------------------------------
-- Anti AFK
-------------------------------------------------
local AntiAFKConn
AutoBox:AddToggle("AntiAFK", {
    Text = "Anti AFK",
    Default = false,
    Callback = function(state)
        if state then
            print("Anti AFK Enabled")
            AntiAFKConn = LocalPlayer.Idled:Connect(function()
                local vu = game:GetService("VirtualUser")
                local cam = workspace.CurrentCamera
                if cam then
                    vu:Button2Down(Vector2.new(0, 0), cam.CFrame)
                    task.wait(0.1)
                    vu:Button2Up(Vector2.new(0, 0), cam.CFrame)
                end
            end)
        else
            print("Anti AFK Disabled")
            if AntiAFKConn then
                AntiAFKConn:Disconnect()
                AntiAFKConn = nil
            end
        end
    end,
})
