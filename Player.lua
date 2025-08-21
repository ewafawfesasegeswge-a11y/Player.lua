-------------------------------
-- Player Tab
------------------------------------------------------
local PlayerTab = Window:AddTab({
    Name = 'Players',
    Icon = 'users',
    Description = 'Player-related features',
})

local PlayerBox = PlayerTab:AddLeftGroupbox('Player Actions')
-------------------------------------------------
-- UI Dropdown for player selection
-------------------------------------------------

local PlayerDropdown = PlayerBox:AddDropdown('Select Player', {
    Values = {},
    Default = '',
    Multi = false,
    Text = 'Select Player',
})

-- Refresh dropdown values
local function refreshPlayers()
    local names = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            table.insert(names, plr.Name)
        end
    end
    PlayerDropdown:SetValues(names)
end

Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(refreshPlayers)
refreshPlayers()

-- Auto Features
local AutoBox = PlayerTab:AddRightGroupbox('Auto Features')

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local LocalPlayer = Players.LocalPlayer

local RunService = game:GetService('RunService')
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local LocalPlayer = Players.LocalPlayer

local CultivationRemote =
    ReplicatedStorage.RemoteEvents.Player.Cultivation.CultivationRemote

-- store last meditation position
local savedPos = nil
local savingPos = false
local retrying = false
local retryConnection

local RunService = game:GetService('RunService')
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local LocalPlayer = Players.LocalPlayer

local CultivationRemote = ReplicatedStorage:WaitForChild('RemoteEvents')
    :WaitForChild('Player')
    :WaitForChild('Cultivation')
    :WaitForChild('CultivationRemote')

-- state
local savedPos = nil
local savingPos = false
local retryConnection = nil
local charAddedConn = nil

-- helpers
local function startMeditating()
    CultivationRemote:FireServer('GSMeditation', 'Start')
end

local function stopMeditating()
    CultivationRemote:FireServer('GSMeditation', 'Stop')
end

local function freezeCharacter(char)
    local root = char and char:FindFirstChild('HumanoidRootPart')
    if root then
        root.Anchored = true
    end
end

local function unfreezeCharacter(char)
    local root = char and char:FindFirstChild('HumanoidRootPart')
    if root then
        root.Anchored = false
    end
end

-- retry teleport loop after respawn
local function tryReturnToSpot(char)
    local root = char:WaitForChild('HumanoidRootPart', 10)
    if not root or not savedPos then
        return
    end

    local startTime = tick()
    if retryConnection then
        retryConnection:Disconnect()
    end

    retryConnection = RunService.Heartbeat:Connect(function()
        if not savingPos then
            -- toggle disabled -> stop retrying immediately
            retryConnection:Disconnect()
            retryConnection = nil
            return
        end

        if tick() - startTime > 2 then
            retryConnection:Disconnect()
            retryConnection = nil
            return
        end

        if savedPos then
            root.CFrame = savedPos
            if (root.Position - savedPos.Position).Magnitude < 5 then
                retryConnection:Disconnect()
                retryConnection = nil

                startMeditating()
                task.delay(1, function()
                    if savingPos then
                        freezeCharacter(char)
                    end
                end)

                print('✅ Returned & resumed meditation')
            end
        end
    end)
end

-- UI toggle
AutoBox:AddToggle('AutoMeditate', {
    Text = 'Auto Meditate/Comprehend',
    Default = false,
    Callback = function(state)
        if state then
            print('Auto Meditate/Comprehend Enabled')
            startMeditating()

            if LocalPlayer.Character then
                freezeCharacter(LocalPlayer.Character)
            end

            savingPos = true
            task.spawn(function()
                while savingPos do
                    local char = LocalPlayer.Character
                    local root = char
                        and char:FindFirstChild('HumanoidRootPart')
                    if root then
                        savedPos = root.CFrame
                    end
                    task.wait(0.1)
                end
            end)

            -- listen for respawn
            if charAddedConn then
                charAddedConn:Disconnect()
            end
            charAddedConn = LocalPlayer.CharacterAdded:Connect(function(char)
                if savingPos then
                    tryReturnToSpot(char)
                end
            end)
        else
            print('Auto Meditate Disabled')
            savingPos = false

            -- 🔴 cleanup everything
            if retryConnection then
                retryConnection:Disconnect()
                retryConnection = nil
            end
            if charAddedConn then
                charAddedConn:Disconnect()
                charAddedConn = nil
            end

            if LocalPlayer.Character then
                unfreezeCharacter(LocalPlayer.Character)
            end

            stopMeditating()
        end
    end,
})

------------------------------------------------------
-- Game-specific Features (Players Tab / AutoBox)
------------------------------------------------------
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local LocalPlayer = Players.LocalPlayer

-- Allowed game (replace with your real PlaceId)
local allowedGameId = 1234567890

if game.PlaceId == allowedGameId then
    ------------------------------
    -- Qi Zone Autofarm
    ------------------------------
    local ZoneRemote =
        ReplicatedStorage.RemoteEvents.Player.Cultivation:WaitForChild(
            'ZoneEvent'
        )

    local qiZones = { 'Statue', 'YSW', 'BloodCC', 'SB', 'FoH' }
    local selectedQiZone = qiZones[1]
    local autoQiEnabled = false
    local currentQiZone = nil

    AutoBox:AddDropdown('QiZoneDropdown', {
        Values = qiZones,
        Value = selectedQiZone,
        Text = 'Select Qi Zone',
        Callback = function(value)
            selectedQiZone = value
            if autoQiEnabled then
                if currentQiZone then
                    ZoneRemote:FireServer(LocalPlayer, currentQiZone, 'Exited')
                end
                ZoneRemote:FireServer(LocalPlayer, value, 'Entered')
                currentQiZone = value
            end
        end,
    })

    AutoBox:AddToggle('AutoQiZoneToggle', {
        Text = 'Enable Auto Qi Zone',
        Default = false,
        Callback = function(state)
            autoQiEnabled = state
            if state then
                if selectedQiZone then
                    ZoneRemote:FireServer(
                        LocalPlayer,
                        selectedQiZone,
                        'Entered'
                    )
                    currentQiZone = selectedQiZone
                end
            else
                if currentQiZone then
                    ZoneRemote:FireServer(LocalPlayer, currentQiZone, 'Exited')
                    currentQiZone = nil
                end
            end
        end,
    })

    ------------------------------
    -- Comprehension Zone Autofarm
    ------------------------------
    local CompRemote =
        ReplicatedStorage.RemoteEvents.Player.Comprehension:WaitForChild(
            'ComprehensionZone'
        )

    local compZones = { 'EL', 'HVP' } -- can add more later
    local selectedCompZone = compZones[1]
    local autoCompEnabled = false
    local currentCompZone = nil

    AutoBox:AddDropdown('CompZoneDropdown', {
        Values = compZones,
        Value = selectedCompZone,
        Text = 'Select Comprehension Zone',
        Callback = function(value)
            selectedCompZone = value
            if autoCompEnabled then
                if currentCompZone then
                    CompRemote:FireServer(
                        LocalPlayer,
                        currentCompZone,
                        'Exited'
                    )
                end
                CompRemote:FireServer(LocalPlayer, value, 'Entered')
                currentCompZone = value
            end
        end,
    })

    AutoBox:AddToggle('AutoCompZoneToggle', {
        Text = 'Enable Auto Comprehension Zone',
        Default = false,
        Callback = function(state)
            autoCompEnabled = state
            if state then
                if selectedCompZone then
                    CompRemote:FireServer(
                        LocalPlayer,
                        selectedCompZone,
                        'Entered'
                    )
                    currentCompZone = selectedCompZone
                end
            else
                if currentCompZone then
                    CompRemote:FireServer(
                        LocalPlayer,
                        currentCompZone,
                        'Exited'
                    )
                    currentCompZone = nil
                end
            end
        end,
    })
end

-- Fling function (Infinite Yield style)
local function flingPlayer(target, duration)
    local char = LocalPlayer.Character
    local targetChar = target.Character
    if not (char and targetChar) then
        return
    end

    local root = char:FindFirstChild('HumanoidRootPart')
    local targetRoot = targetChar:FindFirstChild('HumanoidRootPart')
    if not (root and targetRoot) then
        return
    end

    -- Add BodyThrust to fling
    local bv = Instance.new('BodyThrust')
    bv.Force = Vector3.new(9999, 9999, 9999)
    bv.Parent = root

    local startTime = tick()
    while tick() - startTime < (duration or 0.5) do
        root.CFrame = targetRoot.CFrame
        task.wait()
    end

    bv:Destroy()
end

-- Dropdown
local PlayerDropdown
local function refreshPlayers()
    if not PlayerDropdown then
        return
    end
    local names = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(names, plr.Name)
        end
    end
    PlayerDropdown:SetValues(names)
end

PlayerDropdown = PlayerBox:AddDropdown('PlayerDropdown', {
    Values = {},
    Default = nil,
    Multi = false,
    Text = 'Select Player',
    Callback = function(val)
        print('Selected player:', val)
    end,
})

local Players = game:GetService('Players')
local LocalPlayer = Players.LocalPlayer

-- Fling function (Infinite Yield style)
local function flingPlayer(target, duration)
    local char = LocalPlayer.Character
    local targetChar = target.Character
    if not (char and targetChar) then
        return
    end

    local root = char:FindFirstChild('HumanoidRootPart')
    local targetRoot = targetChar:FindFirstChild('HumanoidRootPart')
    if not (root and targetRoot) then
        return
    end

    -- Add BodyThrust to fling
    local bv = Instance.new('BodyThrust')
    bv.Force = Vector3.new(9999, 9999, 9999)
    bv.Parent = root

    local startTime = tick()
    while tick() - startTime < (duration or 0.5) do
        root.CFrame = targetRoot.CFrame
        task.wait()
    end

    bv:Destroy()
end

-- Dropdown
local PlayerDropdown
local function refreshPlayers()
    if not PlayerDropdown then
        return
    end
    local names = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(names, plr.Name)
        end
    end
    PlayerDropdown:SetValues(names)
end

PlayerDropdown = PlayerBox:AddDropdown('PlayerDropdown', {
    Values = {},
    Default = nil,
    Multi = false,
    Text = 'Select Player',
    Callback = function(val)
        print('Selected player:', val)
    end,
})

-- Buttons
PlayerBox:AddButton('TP to Person', function()
    local target = Players:FindFirstChild(PlayerDropdown.Value)
    if
        target
        and target.Character
        and target.Character:FindFirstChild('HumanoidRootPart')
    then
        LocalPlayer.Character:PivotTo(
            target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
        )
    end
end)

PlayerBox:AddButton('Fling Selected', function()
    local target = Players:FindFirstChild(PlayerDropdown.Value)
    if target then
        flingPlayer(target, 0.5)
    end
end)

PlayerBox:AddButton('Fling All', function()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            flingPlayer(plr, 0.5)
            task.wait(0.5)
        end
    end
end)

-- Toggles
PlayerBox:AddToggle('ContinuousFling', {
    Text = 'Continuous Fling Selected',
    Default = false,
    Callback = function(state)
        if state then
            task.spawn(function()
                while Toggles.ContinuousFling.Value do
                    local target = Players:FindFirstChild(PlayerDropdown.Value)
                    if target then
                        flingPlayer(target, 0.5)
                    end
                    task.wait(0.5)
                end
            end)
        end
    end,
})

PlayerBox:AddToggle('ContinuousTP', {
    Text = 'Continuous TP to Selected',
    Default = false,
    Callback = function(state)
        if state then
            task.spawn(function()
                while Toggles.ContinuousTP.Value do
                    local target = Players:FindFirstChild(PlayerDropdown.Value)
                    if
                        target
                        and target.Character
                        and target.Character:FindFirstChild('HumanoidRootPart')
                    then
                        LocalPlayer.Character:PivotTo(
                            target.Character.HumanoidRootPart.CFrame
                                * CFrame.new(0, 0, 3)
                        )
                    end
                    task.wait(0.2)
                end
            end)
        end
    end,
})

-- Refresh when players join/leave
Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(refreshPlayers)
refreshPlayers()

-- toggle in UI
AutoBox:AddToggle('AntiAFK', {
    Text = 'Anti AFK',
    Default = false,
    Callback = function(state)
        if state then
            print('Anti AFK Enabled')

            AntiAFKConn = game:GetService('Players').LocalPlayer.Idled
                :Connect(function()
                    local vu = game:GetService('VirtualUser')
                    local cam = workspace.CurrentCamera
                    if cam then
                        vu:Button2Down(Vector2.new(0, 0), cam.CFrame)
                        task.wait(0.1)
                        vu:Button2Up(Vector2.new(0, 0), cam.CFrame)
                        print('[Anti AFK] simulated input')
                    end
                end)
        else
            print('Anti AFK Disabled')

            if AntiAFKConn then
                AntiAFKConn:Disconnect()
                AntiAFKConn = nil
            end
        end
    end,
})
