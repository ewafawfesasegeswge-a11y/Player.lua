--// Zenith Hub - Player Tab
-- This script requires: getgenv().Window = Window

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local HRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

local PlayerTab = getgenv().Window:AddTab("Players", "user")

-- Left group: Player Actions
local PlayerBox = PlayerTab:AddLeftGroupbox("Player Actions")

-- Dropdown for player selection
local selectedPlayer = nil
local playerDropdown
playerDropdown = PlayerBox:AddDropdown("SelectPlayer", {
    Values = {},
    Default = "",
    Multi = false,
    Text = "Select Player",
    Callback = function(value)
        selectedPlayer = Players:FindFirstChild(value)
    end
})

-- Refresh dropdown when players join/leave
local function refreshPlayers()
    local names = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(names, plr.Name)
        end
    end
    playerDropdown:SetValues(names)
end
Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(refreshPlayers)
refreshPlayers()

-- Actions
PlayerBox:AddButton("TP to Person", function()
    if selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = selectedPlayer.Character.HumanoidRootPart.CFrame
    end
end)

local function fling(target)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if root and targetRoot then
        local bv = Instance.new("BodyVelocity")
        bv.Velocity = Vector3.new(9999, 9999, 9999)
        bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        bv.Parent = root

        root.CFrame = targetRoot.CFrame
        task.wait(0.1)
        bv:Destroy()
    end
end

PlayerBox:AddButton("Fling Selected", function()
    if selectedPlayer then
        fling(selectedPlayer)
    end
end)

PlayerBox:AddButton("Fling All", function()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            fling(plr)
        end
    end
end)

-- Toggles
local continuousTP = false
PlayerBox:AddToggle("ContinuousTP", {
    Text = "Continuous TP to Selected",
    Default = false,
    Callback = function(state)
        continuousTP = state
    end
})

local continuousFling = false
PlayerBox:AddToggle("ContinuousFling", {
    Text = "Continuous Fling Selected",
    Default = false,
    Callback = function(state)
        continuousFling = state
    end
})

-- Run loops
RunService.Heartbeat:Connect(function()
    if continuousTP and selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = selectedPlayer.Character.HumanoidRootPart.CFrame
    end
    if continuousFling and selectedPlayer then
        fling(selectedPlayer)
    end
end)

-- Right group: Auto Features
local AutoBox = PlayerTab:AddRightGroupbox("Auto Features")

AutoBox:AddToggle("AutoMeditate", {
    Text = "Auto Meditate/Comprehend",
    Default = false,
    Callback = function(state)
        -- Insert meditation logic here
    end
})

AutoBox:AddToggle("AntiAFK", {
    Text = "Anti AFK",
    Default = true,
    Callback = function(state)
        if state then
            LocalPlayer.Idled:Connect(function()
                game:GetService("VirtualUser"):Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                task.wait(1)
                game:GetService("VirtualUser"):Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            end)
        end
    end
})

local zones = { "Zone1", "Zone2", "Zone3" } -- put your Qi zones
local selectedZone
AutoBox:AddDropdown("QiZones", {
    Values = zones,
    Default = "",
    Multi = false,
    Text = "Select Qi Zone",
    Callback = function(val)
        selectedZone = val
    end
})

AutoBox:AddToggle("AutoQi", {
    Text = "Enable Auto Qi Zone",
    Default = false,
    Callback = function(state)
        if state and selectedZone then
            print("Teleporting to Qi Zone:", selectedZone)
        end
    end
})
