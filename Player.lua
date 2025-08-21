

------------------------------------------------------
-- Player Tab
------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerTab = Window:AddTab({
    Name = "Players",
    Icon = "users",
    Description = "Player-related features",
})
local PlayerBox = PlayerTab:AddLeftGroupbox("Player Actions")
local AutoBox   = PlayerTab:AddRightGroupbox("Auto Features")

-------------------------------------------------
-- Single “Select Player” Dropdown
-------------------------------------------------
local PlayerDropdown = PlayerBox:AddDropdown("PlayerDropdown", {
    Values = {},
    Default = nil,
    Multi = false,
    Text = "Select Player",
})
local selectedName

local function refreshPlayers()
    local names = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(names, plr.Name)
        end
    end
    PlayerDropdown:SetValues(names)
    if not table.find(names, selectedName) then
        selectedName = nil
        PlayerDropdown:SetValue(nil)
    end
end

PlayerDropdown:SetCallback(function(val)
    selectedName = val
end)
Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(refreshPlayers)
refreshPlayers()

-- Extract the selected player
local function getTarget()
    return Players:FindFirstChild(selectedName or "")
end

-------------------------------------------------
-- Fling Function (Strong BodyVelocity)
-------------------------------------------------
local function flingPlayer(target)
    local c = LocalPlayer.Character
    local t = target and target.Character
    if not (c and t) then return end

    local hrp = c:FindFirstChild("HumanoidRootPart")
    local thrp= t:FindFirstChild("HumanoidRootPart")
    if not (hrp and thrp) then return end

    -- Strong fling
    hrp.CFrame = thrp.CFrame
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(9999,9999,9999)
    bv.MaxForce = Vector3.new(1e9,1e9,1e9)
    bv.Parent = hrp
    RunService.Heartbeat:Wait()
    bv:Destroy()
end

-------------------------------------------------
-- Buttons
-------------------------------------------------
PlayerBox:AddButton("TP to Person", function()
    local target = getTarget()
    if target and target.Character then
        LocalPlayer.Character:PivotTo(
            target.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,3)
        )
    end
end)

PlayerBox:AddButton("Fling Selected", function()
    local target = getTarget()
    if target then
        flingPlayer(target)
    end
end)

PlayerBox:AddButton("Fling All", function()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            flingPlayer(plr)
            task.wait(0.2)
        end
    end
end)

-------------------------------------------------
-- Continuous Toggles
-------------------------------------------------
local flingConn, tpConn

PlayerBox:AddToggle("ContinuousFling", {
    Text = "Continuous Fling Selected",
    Default = false,
    Callback = function(state)
        if flingConn then flingConn:Disconnect(); flingConn = nil end
        if state then
            flingConn = RunService.Heartbeat:Connect(function()
                local t = getTarget()
                if t then flingPlayer(t) end
            end)
        end
    end,
})

PlayerBox:AddToggle("ContinuousTP", {
    Text = "Continuous TP to Selected",
    Default = false,
    Callback = function(state)
        if tpConn then tpConn:Disconnect(); tpConn = nil end
        if state then
            tpConn = RunService.Heartbeat:Connect(function()
                local t = getTarget()
                if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character:PivotTo(
                        t.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,3)
                    )
                end
            end)
        end
    end,
})

PlayerBox:AddToggle("ContinuousFlingAll", {
    Text = "Fling All (One Cycle)",
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
    end,
})

-------------------------------------------------
-- Qi Zone + Comprehension Zone Autofarm
-------------------------------------------------
local allowedGameId = 14483332676 -- ✅ your real game id
if game.PlaceId == allowedGameId then
    local ZoneRemote = ReplicatedStorage.RemoteEvents.Player.Cultivation:WaitForChild("ZoneEvent")
    local qiZones = { "Statue","YSW","BloodCC","SB","FoH" }
    local selectedQiZone, autoQiEnabled, currentQiZone = qiZones[1], false, nil

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
            if state and selectedQiZone then
                ZoneRemote:FireServer(LocalPlayer, selectedQiZone, "Entered")
                currentQiZone = selectedQiZone
            elseif currentQiZone then
                ZoneRemote:FireServer(LocalPlayer, currentQiZone, "Exited")
                currentQiZone = nil
            end
        end,
    })

    -- Comprehension Zones
    local CompRemote = ReplicatedStorage.RemoteEvents.Player.Comprehension:WaitForChild("ComprehensionZone")
    local compZones = { "EL","HVP" }
    local selectedCompZone, autoCompEnabled, currentCompZone = compZones[1], false, nil

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
            if state and selectedCompZone then
                CompRemote:FireServer(LocalPlayer, selectedCompZone, "Entered")
                currentCompZone = selectedCompZone
            elseif currentCompZone then
                CompRemote:FireServer(LocalPlayer, currentCompZone, "Exited")
                currentCompZone = nil
            end
        end,
    })
end

-------------------------------------------------
-- Anti AFK
-------------------------------------------------
local AntiAFKConn
AutoBox:AddToggle("Anti AFK", {
    Text = "Anti AFK",
    Default = false,
    Callback = function(state)
        if state then
            AntiAFKConn = LocalPlayer.Idled:Connect(function()
                local vu = game:GetService("VirtualUser")
                local cam = workspace.CurrentCamera
                if cam then
                    vu:Button2Down(Vector2.new(0,0), cam.CFrame)
                    task.wait(0.1)
                    vu:Button2Up(Vector2.new(0,0), cam.CFrame)
                end
            end)
        else
            if AntiAFKConn then AntiAFKConn:Disconnect(); AntiAFKConn = nil end
        end
    end,
})
