-- Players Tab (single dropdown + fixed continuous TP / fling)
-- Requires: global Window from your hub

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local LocalPlayer      = Players.LocalPlayer

-- Tab & groupboxes
local PlayerTab = Window:AddTab({
    Name = "Players",
    Icon = "users",
    Description = "Player-related features",
})
local PlayerBox = PlayerTab:AddLeftGroupbox("Player Actions")
local AutoBox   = PlayerTab:AddRightGroupbox("Auto Features")

----------------------------------------------------------------
-- ONE Select Player dropdown (kept in sync with server)
----------------------------------------------------------------
local selectedName
local PlayerDropdown = PlayerBox:AddDropdown("PlayerDropdown", {
    Values = {},
    Default = nil,
    Multi = false,
    Text = "Select Player",
    Callback = function(v) selectedName = v end,
})

local function refreshPlayers()
    local names = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            names[#names+1] = plr.Name
        end
    end
    PlayerDropdown:SetValues(names)
    if selectedName and not table.find(names, selectedName) then
        selectedName = nil
        PlayerDropdown:SetValue(nil)
    end
end
Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(refreshPlayers)
refreshPlayers()

local function getSelected()
    if not selectedName then return nil end
    return Players:FindFirstChild(selectedName)
end

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------
local function pivotToTarget(offsetZ)
    local target = getSelected()
    if not target then return false end
    local tChar = target.Character
    local myChar = LocalPlayer.Character
    if not (tChar and myChar) then return false end
    local tHRP = tChar:FindFirstChild("HumanoidRootPart")
    if not tHRP then return false end
    myChar:PivotTo(tHRP.CFrame * CFrame.new(0,0, offsetZ or 3))
    return true
end

-- strong one-shot fling using BodyVelocity applied to YOUR HRP
local function flingOnceAt(target)
    target = target or getSelected()
    if not target then return end

    local myChar = LocalPlayer.Character
    local tChar  = target.Character
    if not (myChar and tChar) then return end

    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    local tHRP  = tChar:FindFirstChild("HumanoidRootPart")
    if not (myHRP and tHRP) then return end

    -- Snap onto the target then shove for one frame
    myChar:PivotTo(tHRP.CFrame)
    local bv = Instance.new("BodyVelocity")
    bv.Velocity  = Vector3.new(9999, 9999, 9999)
    bv.MaxForce  = Vector3.new(1e9, 1e9, 1e9)
    bv.P         = 1e5
    bv.Parent    = myHRP
    RunService.Heartbeat:Wait()
    bv:Destroy()
end

----------------------------------------------------------------
-- Buttons
----------------------------------------------------------------
PlayerBox:AddButton("TP to Person", function()
    pivotToTarget(3)
end)

PlayerBox:AddButton("Fling Selected", function()
    local target = getSelected()
    if target then flingOnceAt(target) end
end)

PlayerBox:AddButton("Fling All", function()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            flingOnceAt(plr)
            task.wait(0.15)
        end
    end
end)

----------------------------------------------------------------
-- Continuous toggles (Heartbeat based)
----------------------------------------------------------------
local tpConn, flingConn

PlayerBox:AddToggle("ContinuousTP", {
    Text = "Continuous TP to Selected",
    Default = false,
    Callback = function(state)
        if tpConn then tpConn:Disconnect(); tpConn = nil end
        if state then
            tpConn = RunService.Heartbeat:Connect(function()
                pivotToTarget(3)
            end)
        end
    end
})

PlayerBox:AddToggle("ContinuousFling", {
    Text = "Continuous Fling Selected",
    Default = false,
    Callback = function(state)
        if flingConn then flingConn:Disconnect(); flingConn = nil end
        if state then
            local last = 0
            flingConn = RunService.Heartbeat:Connect(function()
                -- rate-limit ~10 flings/sec
                local now = tick()
                if now - last > 0.1 then
                    last = now
                    local target = getSelected()
                    if target then flingOnceAt(target) end
                end
            end)
        end
    end
})

-- One-cycle fling all that turns itself off
PlayerBox:AddToggle("ContinuousFlingAll", {
    Text = "Fling All (One Cycle)",
    Default = false,
    Callback = function(state)
        if state then
            task.spawn(function()
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer then
                        flingOnceAt(plr)
                        task.wait(0.15)
                    end
                end
                Toggles.ContinuousFlingAll:SetValue(false)
            end)
        end
    end
})

----------------------------------------------------------------
-- Auto features (guarded; won’t crash if remotes are missing)
----------------------------------------------------------------
local Remotes          = ReplicatedStorage:FindFirstChild("RemoteEvents")
local PlayerFolder     = Remotes and Remotes:FindFirstChild("Player")
local Cultivation      = PlayerFolder and PlayerFolder:FindFirstChild("Cultivation")
local CultivationRemote= Cultivation and Cultivation:FindFirstChild("CultivationRemote")

local function safeFire(remote, ...)
    if remote and remote.FireServer then
        remote:FireServer(...)
    else
        warn("[Players Tab] Remote missing:", tostring(remote))
    end
end

-- Auto Meditate (freeze + respawn return)
do
    local savedCFrame, saving = nil, false
    local retryConn, charAddedConn

    local function freeze(char, on)
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.Anchored = on and true or false end
    end

    AutoBox:AddToggle("AutoMeditate", {
        Text = "Auto Meditate/Comprehend",
        Default = false,
        Callback = function(state)
            if state then
                saving = true
                safeFire(CultivationRemote, "GSMeditation", "Start")
                if LocalPlayer.Character then freeze(LocalPlayer.Character, true) end

                task.spawn(function()
                    while saving do
                        local c = LocalPlayer.Character
                        local hrp = c and c:FindFirstChild("HumanoidRootPart")
                        if hrp then savedCFrame = hrp.CFrame end
                        task.wait(0.1)
                    end
                end)

                if charAddedConn then charAddedConn:Disconnect() end
                charAddedConn = LocalPlayer.CharacterAdded:Connect(function(char)
                    if not saving then return end
                    local hrp = char:WaitForChild("HumanoidRootPart", 10)
                    if not hrp or not savedCFrame then return end
                    if retryConn then retryConn:Disconnect() end
                    local t0 = tick()
                    retryConn = RunService.Heartbeat:Connect(function()
                        if not saving then retryConn:Disconnect(); retryConn=nil return end
                        if tick()-t0 > 2 then retryConn:Disconnect(); retryConn=nil return end
                        char:PivotTo(savedCFrame)
                        if (hrp.Position - savedCFrame.Position).Magnitude < 5 then
                            retryConn:Disconnect(); retryConn=nil
                            safeFire(CultivationRemote, "GSMeditation", "Start")
                            task.delay(1, function() if saving then freeze(char, true) end end)
                        end
                    end)
                end)
            else
                saving = false
                if retryConn then retryConn:Disconnect(); retryConn=nil end
                if charAddedConn then charAddedConn:Disconnect(); charAddedConn=nil end
                if LocalPlayer.Character then freeze(LocalPlayer.Character, false) end
                safeFire(CultivationRemote, "GSMeditation", "Stop")
            end
        end
    })
end

-- Anti AFK
do
    local conn
    AutoBox:AddToggle("AntiAFK", {
        Text = "Anti AFK",
        Default = false,
        Callback = function(state)
            if conn then conn
