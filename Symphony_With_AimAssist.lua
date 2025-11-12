--[[
╔═══════════════════════════════════════════════════════════╗
║      SYMPHONY HUB - WITH NEXT-GEN AIM ASSIST             ║
║         Enhanced Combat Module Integration               ║
║                 © Symphony Hub 2025                      ║
╚═══════════════════════════════════════════════════════════╝

This version integrates the Next-Gen Aim Assist system into
the Symphony Hub Full Featured script.

FEATURES ADDED:
✓ Kalman Filter + EMA prediction
✓ Adaptive latency compensation
✓ Jump trajectory prediction
✓ Quality presets (Low/Balanced/High)
✓ Real-time parameter tuning
✓ Debug visualization
]]

-- ═══════════════════════════════════════════════════════════
-- STEP 1: LOAD AIM ASSIST MODULES
-- ═══════════════════════════════════════════════════════════

print("[Symphony] Loading Next-Gen Aim Assist modules...")

-- Load all aim assist modules
local AimAssistModule = loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/AlphaZero-Chess/V@refs/heads/main/modules/aimassist/AimAssistModule.lua"))()
local PredictionEngine = loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/AlphaZero-Chess/V@refs/heads/main/modules/aimassist/PredictionEngine.lua"))()
local LatencyCompensator = loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/AlphaZero-Chess/V@refs/heads/main/modules/aimassist/LatencyCompensator.lua"))()
local JumpPredictor = loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/AlphaZero-Chess/V@refs/heads/main/modules/aimassist/JumpPredictor.lua"))()
local MovementTracker = loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/AlphaZero-Chess/V@refs/heads/main/modules/aimassist/MovementTracker.lua"))()
local AimSolver = loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/AlphaZero-Chess/V@refs/heads/main/modules/aimassist/AimSolver.lua"))()

-- Note: Replace URLs above with your actual hosting URLs
-- For local testing, you can use require() if modules are in ReplicatedStorage

print("[Symphony] ✓ Aim Assist modules loaded")

-- ═══════════════════════════════════════════════════════════
-- STEP 2: LOAD SYMPHONY FULL FEATURED
-- ═══════════════════════════════════════════════════════════

-- Execute the original Symphony Full Featured script
-- (This loads all the UI and base features)
loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/AlphaZero-Chess/V@refs/heads/main/Symphony_Full_Featured.lua"))()

-- Wait for Symphony to initialize
local Symphony = _G.Symphony
while not Symphony do
    task.wait(0.1)
    Symphony = _G.Symphony
end

print("[Symphony] Core loaded, integrating aim assist...")

-- ═══════════════════════════════════════════════════════════
-- STEP 3: INITIALIZE AIM ASSIST
-- ═══════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local stats = game:GetService("Stats")

-- Create aim assist instance
local aimAssist = AimAssistModule.new({
    Quality = "balanced",
    MaxFOV = 120,
    Debug = false,
    Smoothing = {
        maxAnglePerSec = 720,
        lerp = 0.12
    }
})

-- Initialize
local initSuccess = aimAssist:init(camera, RunService, stats)

if not initSuccess then
    warn("[Symphony] Failed to initialize Aim Assist!")
else
    print("[Symphony] ✓ Next-Gen Aim Assist initialized")
end

-- Store in Symphony global
Symphony.AimAssist = aimAssist

-- ═══════════════════════════════════════════════════════════
-- STEP 4: FIND AND ENHANCE COMBAT PAGE
-- ═══════════════════════════════════════════════════════════

-- Wait for UI to be created
task.wait(1)

local screenGui = LocalPlayer.PlayerGui:FindFirstChild("SymphonyHubFull")
if not screenGui then
    warn("[Symphony] Could not find Symphony UI!")
    return
end

-- Find the combat page
local mainWindow = screenGui:FindFirstChild("MainWindow")
local contentFrame = mainWindow and mainWindow:FindFirstChild("Content")
local combatPage = contentFrame and contentFrame:FindFirstChild("Combat")

if not combatPage then
    warn("[Symphony] Could not find Combat page!")
    return
end

print("[Symphony] Found Combat page, adding aim assist controls...")

-- ═══════════════════════════════════════════════════════════
-- STEP 5: CREATE AIM ASSIST UI SECTION
-- ═══════════════════════════════════════════════════════════

-- Helper function to create section header
local function createAimAssistSection(parent, text, order)
    local section = Instance.new("Frame")
    section.Name = text
    section.Parent = parent
    section.BackgroundTransparency = 1
    section.Size = UDim2.new(1, -20, 0, 35)
    section.LayoutOrder = order
    
    local label = Instance.new("TextLabel")
    label.Parent = section
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextColor3 = Color3.fromRGB(0, 200, 100)
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    return section
end

-- Helper function to create toggle
local function createAimToggle(parent, text, order, defaultValue, callback)
    local toggle = Instance.new("Frame")
    toggle.Name = text
    toggle.Parent = parent
    toggle.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    toggle.BorderSizePixel = 0
    toggle.Size = UDim2.new(1, -20, 0, 40)
    toggle.LayoutOrder = order
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = toggle
    
    local label = Instance.new("TextLabel")
    label.Parent = toggle
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 15, 0, 0)
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local button = Instance.new("TextButton")
    button.Parent = toggle
    button.BackgroundColor3 = defaultValue and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 65)
    button.BorderSizePixel = 0
    button.Position = UDim2.new(1, -60, 0.5, -12)
    button.Size = UDim2.new(0, 45, 0, 24)
    button.Font = Enum.Font.GothamBold
    button.Text = defaultValue and "ON" or "OFF"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 12
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = button
    
    local enabled = defaultValue
    
    button.MouseButton1Click:Connect(function()
        enabled = not enabled
        button.Text = enabled and "ON" or "OFF"
        button.BackgroundColor3 = enabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 65)
        callback(enabled)
    end)
    
    return toggle
end

-- Helper function to create dropdown
local function createAimDropdown(parent, text, options, order, callback)
    local dropdown = Instance.new("Frame")
    dropdown.Name = text
    dropdown.Parent = parent
    dropdown.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    dropdown.BorderSizePixel = 0
    dropdown.Size = UDim2.new(1, -20, 0, 40)
    dropdown.LayoutOrder = order
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = dropdown
    
    local label = Instance.new("TextLabel")
    label.Parent = dropdown
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 15, 0, 0)
    label.Size = UDim2.new(0.4, 0, 1, 0)
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local button = Instance.new("TextButton")
    button.Parent = dropdown
    button.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    button.BorderSizePixel = 0
    button.Position = UDim2.new(0.5, 0, 0.5, -12)
    button.Size = UDim2.new(0.45, -15, 0, 24)
    button.Font = Enum.Font.Gotham
    button.Text = options[1]
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 12
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = button
    
    local currentIndex = 1
    
    button.MouseButton1Click:Connect(function()
        currentIndex = (currentIndex % #options) + 1
        button.Text = options[currentIndex]
        callback(options[currentIndex])
    end)
    
    return dropdown
end

-- Helper function to create slider
local function createAimSlider(parent, text, min, max, default, order, callback)
    local slider = Instance.new("Frame")
    slider.Name = text
    slider.Parent = parent
    slider.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    slider.BorderSizePixel = 0
    slider.Size = UDim2.new(1, -20, 0, 50)
    slider.LayoutOrder = order
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = slider
    
    local label = Instance.new("TextLabel")
    label.Parent = slider
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 15, 0, 5)
    label.Size = UDim2.new(1, -30, 0, 20)
    label.Font = Enum.Font.Gotham
    label.Text = text .. ": " .. tostring(default)
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local sliderBar = Instance.new("Frame")
    sliderBar.Parent = slider
    sliderBar.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    sliderBar.BorderSizePixel = 0
    sliderBar.Position = UDim2.new(0, 15, 1, -20)
    sliderBar.Size = UDim2.new(1, -30, 0, 6)
    
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(1, 0)
    barCorner.Parent = sliderBar
    
    local fill = Instance.new("Frame")
    fill.Parent = sliderBar
    fill.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    fill.BorderSizePixel = 0
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill
    
    local button = Instance.new("TextButton")
    button.Parent = sliderBar
    button.BackgroundTransparency = 1
    button.Size = UDim2.new(1, 0, 1, 0)
    button.Text = ""
    
    local dragging = false
    
    button.MouseButton1Down:Connect(function()
        dragging = true
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local pos = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
            local value = min + (max - min) * pos
            value = math.floor(value * 100) / 100  -- Round to 2 decimals
            
            fill.Size = UDim2.new(pos, 0, 1, 0)
            label.Text = text .. ": " .. tostring(value)
            callback(value)
        end
    end)
    
    return slider
end

-- ═══════════════════════════════════════════════════════════
-- STEP 6: ADD AIM ASSIST CONTROLS TO COMBAT PAGE
-- ═══════════════════════════════════════════════════════════

-- Add section header
createAimAssistSection(combatPage, "🎯 NEXT-GEN AIM ASSIST", 100)

-- Main toggle
local aimEnabled = false
local updateConnection = nil
local currentTarget = nil

createAimToggle(combatPage, "Enable Aim Assist", 101, false, function(enabled)
    aimEnabled = enabled
    
    if enabled then
        -- Find closest target
        local function findClosestTarget()
            local myPos = LocalPlayer.Character and LocalPlayer.Character.HumanoidRootPart.Position
            if not myPos then return nil end
            
            local closest = nil
            local closestDist = math.huge
            
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
                    if rootPart then
                        local dist = (rootPart.Position - myPos).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                            closest = player
                        end
                    end
                end
            end
            
            return closest
        end
        
        currentTarget = findClosestTarget()
        
        if currentTarget then
            aimAssist:lock(currentTarget)
            
            -- Update loop
            updateConnection = RunService.RenderStepped:Connect(function(dt)
                if aimEnabled then
                    local aimData = aimAssist:update(dt)
                    
                    if aimData then
                        camera.CFrame = aimData.cameraLookAt
                    end
                end
            end)
            
            print("[Symphony] Aim Assist locked on:", currentTarget.Name)
        else
            print("[Symphony] No targets found")
        end
    else
        -- Release
        aimAssist:release()
        if updateConnection then
            updateConnection:Disconnect()
            updateConnection = nil
        end
        print("[Symphony] Aim Assist disabled")
    end
end)

-- Quality preset dropdown
createAimDropdown(combatPage, "Quality", {"low", "balanced", "high"}, 102, function(quality)
    aimAssist:setQuality(quality)
    print("[Symphony] Quality set to:", quality)
end)

-- Smoothing slider
createAimSlider(combatPage, "Smoothing", 0.05, 0.3, 0.12, 103, function(value)
    aimAssist:setParam("lerp", value)
end)

-- FOV slider
createAimSlider(combatPage, "Max FOV", 30, 180, 120, 104, function(value)
    aimAssist:setParam("maxFOV", value)
end)

-- Dead zone slider
createAimSlider(combatPage, "Dead Zone", 0, 5, 1, 105, function(value)
    aimAssist:setParam("deadZone", value)
end)

-- Debug toggle
createAimToggle(combatPage, "Debug Mode", 106, false, function(enabled)
    aimAssist:debugToggle(enabled)
    
    if enabled then
        spawn(function()
            while enabled do
                wait(3)
                if aimAssist.debugEnabled then
                    aimAssist:printDebugInfo()
                end
            end
        end)
    end
end)

-- ═══════════════════════════════════════════════════════════
-- STEP 7: ADD KEYBIND SUPPORT
-- ═══════════════════════════════════════════════════════════

-- Tab key to switch targets
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Tab and aimEnabled then
        local function findNextTarget()
            local players = Players:GetPlayers()
            local currentIndex = nil
            
            for i, player in ipairs(players) do
                if player == currentTarget then
                    currentIndex = i
                    break
                end
            end
            
            if currentIndex then
                local nextIndex = (currentIndex % #players) + 1
                return players[nextIndex]
            end
            
            return nil
        end
        
        local nextTarget = findNextTarget()
        if nextTarget and nextTarget ~= LocalPlayer then
            currentTarget = nextTarget
            aimAssist:release()
            aimAssist:lock(currentTarget)
            print("[Symphony] Switched target to:", currentTarget.Name)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════
-- STEP 8: ENHANCED FEATURES INTEGRATION
-- ═══════════════════════════════════════════════════════════
--[[
    ENHANCED FEATURES ADDED:
    ✓ Sheriff Safe-Targeting (prevents friendly fire)
    ✓ Knife Aura for thrown knives (ThrowingKnife objects)
    ✓ Enhanced Auto-Dodge (trajectory prediction)
    ✓ Target Priority System (role-based targeting)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- ═══════════════════════════════════════════════════════════
-- ROLE DETECTION (FROM NEXUS)
-- ═══════════════════════════════════════════════════════════

local GetPlayerDataRemote = ReplicatedStorage:FindFirstChild("GetPlayerData", true)

local function updatePlayerData()
    if GetPlayerDataRemote then
        local success, data = pcall(function()
            return GetPlayerDataRemote:InvokeServer()
        end)
        if success and data then
            local playerData = {}
            for _, player in pairs(Players:GetPlayers()) do
                playerData[player.Name] = data[player.Name] or { Role = "", Killed = false, Dead = false }
            end
            return playerData
        end
    end
    return {}
end

local function GetPlayerRole(player, playerData)
    if not player or not playerData then return nil end
    return playerData[player.Name] and playerData[player.Name].Role
end

local function IsAlive(player, playerData)
    if not player or not playerData then return false end
    local role = playerData[player.Name]
    return role and not role.Killed and not role.Dead
end

local function GetMurderer(playerData)
    for _, player in ipairs(Players:GetPlayers()) do 
        if GetPlayerRole(player, playerData) == "Murderer" and IsAlive(player, playerData) then
            return player
        end
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════
-- ENHANCED CONFIGURATION
-- ═══════════════════════════════════════════════════════════

local EnhancedConfig = {
    SheriffSafeTargeting = {
        Enabled = true,
        AllowFriendlyFireOverride = false,
        OverrideKey = Enum.KeyCode.LeftControl,
        MaxRayDistance = 500,
        MinSafeDistance = 2.0
    },
    
    KnifeAuraOnThrow = {
        Enabled = false,
        AuraRadius = 10,
        Cooldown = 0.3,
        MaxKnivesTracked = 5,
        HitCooldownPerVictim = 0.5
    },
    
    AutoDodge = {
        Enabled = false,
        DodgeMode = "Lateral",
        DodgeThreshold = 12,
        MaxDodgeTime = 1.5,
        LateralDodgeDistance = 6,
        CollisionCheckRadius = 3
    }
}

-- ═══════════════════════════════════════════════════════════
-- MODULE: SHERIFF SAFE-TARGETING
-- ═══════════════════════════════════════════════════════════

local SheriffTargeting = {}
SheriffTargeting.__index = SheriffTargeting

function SheriffTargeting.new()
    local self = setmetatable({}, SheriffTargeting)
    self.overridePressed = false
    return self
end

function SheriffTargeting:isLineOfSightClear(origin, targetPosition, targetPlayer, playerData)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    
    local filterList = {LocalPlayer.Character}
    if LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                table.insert(filterList, part)
            end
        end
    end
    raycastParams.FilterDescendantsInstances = filterList
    raycastParams.IgnoreWater = true
    
    local direction = (targetPosition - origin)
    local distance = direction.Magnitude
    direction = direction.Unit
    
    local rayResult = workspace:Raycast(origin, direction * math.min(distance, EnhancedConfig.SheriffSafeTargeting.MaxRayDistance), raycastParams)
    
    if not rayResult then
        return true
    end
    
    local hitPart = rayResult.Instance
    if hitPart then
        local hitCharacter = hitPart:FindFirstAncestorOfClass("Model")
        if hitCharacter then
            local hitPlayer = Players:GetPlayerFromCharacter(hitCharacter)
            if hitPlayer and hitPlayer ~= targetPlayer then
                local role = GetPlayerRole(hitPlayer, playerData)
                if role == "Innocent" or role == "Hero" or role == "Sheriff" then
                    return false
                end
            end
        end
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player ~= targetPlayer and player.Character then
            local role = GetPlayerRole(player, playerData)
            if (role == "Innocent" or role == "Hero" or role == "Sheriff") and IsAlive(player, playerData) then
                local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    local playerPos = rootPart.Position
                    local lineVec = targetPosition - origin
                    local playerVec = playerPos - origin
                    local t = math.clamp(playerVec:Dot(lineVec) / lineVec:Dot(lineVec), 0, 1)
                    local closestPoint = origin + lineVec * t
                    local distanceToLine = (playerPos - closestPoint).Magnitude
                    
                    if distanceToLine < EnhancedConfig.SheriffSafeTargeting.MinSafeDistance then
                        return false
                    end
                end
            end
        end
    end
    
    return true
end

function SheriffTargeting:canTargetMurderer(murderer, playerData)
    if not EnhancedConfig.SheriffSafeTargeting.Enabled then
        return true
    end
    
    if not murderer or not murderer.Character then
        return false
    end
    
    if EnhancedConfig.SheriffSafeTargeting.AllowFriendlyFireOverride and self.overridePressed then
        return true
    end
    
    local origin = Camera.CFrame.Position
    local targetPart = murderer.Character:FindFirstChild("HumanoidRootPart") or murderer.Character:FindFirstChild("Head")
    
    if not targetPart then
        return false
    end
    
    return self:isLineOfSightClear(origin, targetPart.Position, murderer, playerData)
end

function SheriffTargeting:updateOverrideKey()
    self.overridePressed = UserInputService:IsKeyDown(EnhancedConfig.SheriffSafeTargeting.OverrideKey)
end

-- ═══════════════════════════════════════════════════════════
-- MODULE: KNIFE AURA TRACKER (THROWN KNIVES)
-- ═══════════════════════════════════════════════════════════

local KnifeAuraTracker = {}
KnifeAuraTracker.__index = KnifeAuraTracker

function KnifeAuraTracker.new()
    local self = setmetatable({}, KnifeAuraTracker)
    self.trackedKnives = {}
    self.hitRegistry = {}
    self.lastAuraTime = 0
    self.knifeConnections = {}
    return self
end

function KnifeAuraTracker:startTracking()
    if not EnhancedConfig.KnifeAuraOnThrow.Enabled then
        return
    end
    
    local connection = Workspace.ChildAdded:Connect(function(child)
        self:onKnifeAdded(child)
    end)
    
    table.insert(self.knifeConnections, connection)
    
    local updateConnection = RunService.Heartbeat:Connect(function(dt)
        self:updateKnifeAuras(dt)
    end)
    
    table.insert(self.knifeConnections, updateConnection)
end

function KnifeAuraTracker:stopTracking()
    for _, conn in pairs(self.knifeConnections) do
        if conn then
            conn:Disconnect()
        end
    end
    self.knifeConnections = {}
    self.trackedKnives = {}
    self.hitRegistry = {}
end

function KnifeAuraTracker:onKnifeAdded(child)
    if not EnhancedConfig.KnifeAuraOnThrow.Enabled then
        return
    end
    
    if child.Name == "ThrowingKnife" and child:IsA("Model") then
        local knifeId = tostring(child:GetDebugId())
        
        if #self.trackedKnives >= EnhancedConfig.KnifeAuraOnThrow.MaxKnivesTracked then
            table.remove(self.trackedKnives, 1)
        end
        
        local knifeData = {
            instance = child,
            id = knifeId,
            spawnTime = tick(),
            lastAuraApplication = 0
        }
        
        table.insert(self.trackedKnives, knifeData)
        self.hitRegistry[knifeId] = {}
        
        child.AncestryChanged:Connect(function()
            if not child:IsDescendantOf(Workspace) then
                self:removeKnife(knifeId)
            end
        end)
    end
end

function KnifeAuraTracker:removeKnife(knifeId)
    for i, knifeData in ipairs(self.trackedKnives) do
        if knifeData.id == knifeId then
            table.remove(self.trackedKnives, i)
            break
        end
    end
    self.hitRegistry[knifeId] = nil
end

function KnifeAuraTracker:updateKnifeAuras(dt)
    if not EnhancedConfig.KnifeAuraOnThrow.Enabled then
        return
    end
    
    local currentTime = tick()
    
    if currentTime - self.lastAuraTime < EnhancedConfig.KnifeAuraOnThrow.Cooldown then
        return
    end
    
    local playerData = updatePlayerData()
    local localRole = GetPlayerRole(LocalPlayer, playerData)
    
    if localRole ~= "Murderer" then
        return
    end
    
    for i = #self.trackedKnives, 1, -1 do
        local knifeData = self.trackedKnives[i]
        local knife = knifeData.instance
        
        if not knife or not knife:IsDescendantOf(Workspace) then
            table.remove(self.trackedKnives, i)
        else
            self:processKnifeAura(knifeData, playerData, currentTime)
        end
    end
    
    self.lastAuraTime = currentTime
end

function KnifeAuraTracker:processKnifeAura(knifeData, playerData, currentTime)
    local knife = knifeData.instance
    local knifePosition = knife:GetPivot().Position
    local knifeId = knifeData.id
    
    local knifeHandle = knife:FindFirstChild("Handle")
    if not knifeHandle then
        return
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and IsAlive(player, playerData) then
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local distance = (rootPart.Position - knifePosition).Magnitude
                
                if distance <= EnhancedConfig.KnifeAuraOnThrow.AuraRadius then
                    local victimName = player.Name
                    
                    if not self.hitRegistry[knifeId][victimName] then
                        self:applyKnifeHit(player, knifeHandle, rootPart)
                        self.hitRegistry[knifeId][victimName] = {
                            time = currentTime,
                            applied = true
                        }
                    else
                        local lastHit = self.hitRegistry[knifeId][victimName].time
                        if currentTime - lastHit > EnhancedConfig.KnifeAuraOnThrow.HitCooldownPerVictim then
                            self:applyKnifeHit(player, knifeHandle, rootPart)
                            self.hitRegistry[knifeId][victimName].time = currentTime
                        end
                    end
                end
            end
        end
    end
end

function KnifeAuraTracker:applyKnifeHit(victim, knifeHandle, victimRootPart)
    pcall(function()
        local knife = LocalPlayer.Backpack:FindFirstChild("Knife") or LocalPlayer.Character:FindFirstChild("Knife")
        
        if knife and knife:FindFirstChild("Stab") then
            knife.Stab:FireServer('Down')
            
            if firetouchinterest then
                firetouchinterest(victimRootPart, knifeHandle, 1)
                task.wait(0.05)
                firetouchinterest(victimRootPart, knifeHandle, 0)
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════
-- MODULE: ENHANCED AUTO-DODGE
-- ═══════════════════════════════════════════════════════════

local AutoDodge = {}
AutoDodge.__index = AutoDodge

function AutoDodge.new()
    local self = setmetatable({}, AutoDodge)
    self.dodgeConnections = {}
    self.lastDodgeTime = 0
    self.dodgeCooldown = 0.5
    return self
end

function AutoDodge:startDodging()
    if not EnhancedConfig.AutoDodge.Enabled then
        return
    end
    
    local connection = Workspace.ChildAdded:Connect(function(child)
        self:onKnifeDetected(child)
    end)
    
    table.insert(self.dodgeConnections, connection)
end

function AutoDodge:stopDodging()
    for _, conn in pairs(self.dodgeConnections) do
        if conn then
            conn:Disconnect()
        end
    end
    self.dodgeConnections = {}
end

function AutoDodge:onKnifeDetected(child)
    if not EnhancedConfig.AutoDodge.Enabled then
        return
    end
    
    if child.Name == "ThrowingKnife" and child:IsA("Model") then
        task.spawn(function()
            self:trackAndDodgeKnife(child)
        end)
    end
end

function AutoDodge:trackAndDodgeKnife(knife)
    local currentTime = tick()
    
    if currentTime - self.lastDodgeTime < self.dodgeCooldown then
        return
    end
    
    if not LocalPlayer.Character then
        return
    end
    
    local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        return
    end
    
    local trackingActive = true
    local dodgeExecuted = false
    
    while trackingActive and knife:IsDescendantOf(Workspace) and not dodgeExecuted do
        task.wait(0.05)
        
        local knifePosition = knife:GetPivot().Position
        local knifeVelocity = knife.PrimaryPart and knife.PrimaryPart.AssemblyLinearVelocity or Vector3.new(0, 0, 0)
        local playerPosition = humanoidRootPart.Position
        
        local closestApproach, timeToImpact = self:predictClosestApproach(
            playerPosition,
            knifePosition,
            knifeVelocity
        )
        
        if closestApproach < EnhancedConfig.AutoDodge.DodgeThreshold and 
           timeToImpact < EnhancedConfig.AutoDodge.MaxDodgeTime and
           timeToImpact > 0 then
            self:executeDodge(humanoidRootPart, knifePosition, knifeVelocity)
            dodgeExecuted = true
            self.lastDodgeTime = tick()
            trackingActive = false
        end
        
        local distance = (knifePosition - playerPosition).Magnitude
        if distance > 50 or (tick() - currentTime) > EnhancedConfig.AutoDodge.MaxDodgeTime then
            trackingActive = false
        end
    end
end

function AutoDodge:predictClosestApproach(playerPos, knifePos, knifeVel)
    local relativePos = knifePos - playerPos
    local velocityMag = knifeVel.Magnitude
    
    if velocityMag < 1 then
        return relativePos.Magnitude, math.huge
    end
    
    local dotProduct = relativePos:Dot(knifeVel)
    local timeToClosest = -dotProduct / (velocityMag * velocityMag)
    
    if timeToClosest < 0 then
        return relativePos.Magnitude, math.huge
    end
    
    local closestKnifePos = knifePos + knifeVel * timeToClosest
    local closestDistance = (closestKnifePos - playerPos).Magnitude
    
    return closestDistance, timeToClosest
end

function AutoDodge:executeDodge(humanoidRootPart, knifePosition, knifeVelocity)
    local dodgeMode = EnhancedConfig.AutoDodge.DodgeMode
    
    if dodgeMode == "Lateral" then
        self:lateralDodge(humanoidRootPart, knifePosition, knifeVelocity)
    elseif dodgeMode == "Jump" then
        self:jumpDodge(humanoidRootPart)
    elseif dodgeMode == "Teleport" then
        self:teleportDodge(humanoidRootPart, knifePosition)
    end
end

function AutoDodge:lateralDodge(humanoidRootPart, knifePosition, knifeVelocity)
    local toKnife = (knifePosition - humanoidRootPart.Position).Unit
    local lateralDirection = Vector3.new(-toKnife.Z, 0, toKnife.X)
    
    local dodgeDistance = EnhancedConfig.AutoDodge.LateralDodgeDistance
    local testPosition = humanoidRootPart.Position + lateralDirection * dodgeDistance
    
    if not self:isPositionSafe(testPosition) then
        lateralDirection = -lateralDirection
        testPosition = humanoidRootPart.Position + lateralDirection * dodgeDistance
    end
    
    pcall(function()
        humanoidRootPart.CFrame = CFrame.new(testPosition) * CFrame.Angles(0, humanoidRootPart.CFrame.Rotation.Y, 0)
    end)
end

function AutoDodge:jumpDodge(humanoidRootPart)
    pcall(function()
        local humanoid = humanoidRootPart.Parent:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            
            local offsetDirection = Vector3.new(math.random(-1, 1), 0, math.random(-1, 1)).Unit
            humanoidRootPart.CFrame = humanoidRootPart.CFrame + offsetDirection * 2
        end
    end)
end

function AutoDodge:teleportDodge(humanoidRootPart, knifePosition)
    local awayDirection = (humanoidRootPart.Position - knifePosition).Unit
    local dodgePosition = humanoidRootPart.Position + awayDirection * EnhancedConfig.AutoDodge.LateralDodgeDistance
    
    if self:isPositionSafe(dodgePosition) then
        pcall(function()
            humanoidRootPart.CFrame = CFrame.new(dodgePosition)
        end)
    end
end

function AutoDodge:isPositionSafe(position)
    if position.Y < -50 or position.Y > 500 then
        return false
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local distance = (rootPart.Position - position).Magnitude
                if distance < EnhancedConfig.AutoDodge.CollisionCheckRadius then
                    return false
                end
            end
        end
    end
    
    return true
end

-- ═══════════════════════════════════════════════════════════
-- MODULE: TARGET PRIORITY SYSTEM
-- ═══════════════════════════════════════════════════════════

local TargetingSystem = {}
TargetingSystem.__index = TargetingSystem

function TargetingSystem.new()
    local self = setmetatable({}, TargetingSystem)
    self.sheriffTargeting = SheriffTargeting.new()
    return self
end

function TargetingSystem:getValidTarget(playerData)
    local localRole = GetPlayerRole(LocalPlayer, playerData)
    
    if localRole == "Sheriff" then
        local murderer = GetMurderer(playerData)
        
        if murderer and self.sheriffTargeting:canTargetMurderer(murderer, playerData) then
            return murderer
        end
        
        return nil
    else
        return self:getClosestTarget(playerData)
    end
end

function TargetingSystem:getClosestTarget(playerData)
    local myPos = LocalPlayer.Character and LocalPlayer.Character.HumanoidRootPart
    if not myPos then return nil end
    
    local closest = nil
    local closestDist = math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and IsAlive(player, playerData) then
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local dist = (rootPart.Position - myPos.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = player
                end
            end
        end
    end
    
    return closest
end

function TargetingSystem:updateOverrideKey()
    self.sheriffTargeting:updateOverrideKey()
end

-- ═══════════════════════════════════════════════════════════
-- INITIALIZE ENHANCED SYSTEMS
-- ═══════════════════════════════════════════════════════════

local SymphonyEnhanced = {}
SymphonyEnhanced.TargetingSystem = TargetingSystem.new()
SymphonyEnhanced.KnifeAuraTracker = KnifeAuraTracker.new()
SymphonyEnhanced.AutoDodge = AutoDodge.new()

-- Start systems
SymphonyEnhanced.KnifeAuraTracker:startTracking()
SymphonyEnhanced.AutoDodge:startDodging()

-- Update loop
RunService.Heartbeat:Connect(function()
    SymphonyEnhanced.TargetingSystem:updateOverrideKey()
end)

-- ═══════════════════════════════════════════════════════════
-- ENHANCED GUN HOOK (SHERIFF SAFE TARGETING)
-- ═══════════════════════════════════════════════════════════

local EnhancedGunHook
EnhancedGunHook = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = { ... }
    
    if not checkcaller() then
        if typeof(self) == "Instance" then
            if self.Name == "RemoteFunction" and method == "InvokeServer" then
                local playerData = updatePlayerData()
                local localRole = GetPlayerRole(LocalPlayer, playerData)
                
                if localRole == "Sheriff" and EnhancedConfig.SheriffSafeTargeting.Enabled then
                    local murderer = GetMurderer(playerData)
                    
                    if murderer and murderer.Character then
                        if SymphonyEnhanced.TargetingSystem.sheriffTargeting:canTargetMurderer(murderer, playerData) then
                            local targetPart = murderer.Character:FindFirstChild("HumanoidRootPart")
                            if targetPart then
                                local velocity = targetPart.AssemblyLinearVelocity
                                local position = targetPart.Position
                                
                                if velocity.Magnitude > 0 then
                                    local velocityUnit = velocity.Unit
                                    local velocityMagnitude = velocity.Magnitude
                                    local silentAimPosition = position + Vector3.new((velocityUnit * velocityMagnitude) / 17)
                                    args[2] = silentAimPosition
                                else
                                    args[2] = position
                                end
                            end
                        else
                            return nil
                        end
                    end
                end
            end
        end
    end
    
    return EnhancedGunHook(self, unpack(args))
end)

-- ═══════════════════════════════════════════════════════════
-- ENHANCED KNIFE HOOK (MURDERER TARGETING)
-- ═══════════════════════════════════════════════════════════

local EnhancedKnifeHook
EnhancedKnifeHook = hookmetamethod(game, "__namecall", function(self, ...)
    local methodName = getnamecallmethod()
    local args = { ... }
    
    if not checkcaller() then
        if self.Name == "Throw" and methodName == "FireServer" then
            local playerData = updatePlayerData()
            local localRole = GetPlayerRole(LocalPlayer, playerData)
            
            if localRole == "Murderer" then
                local target = SymphonyEnhanced.TargetingSystem:getClosestTarget(playerData)
                
                if target and target.Character then
                    local targetPart = target.Character:FindFirstChild("HumanoidRootPart")
                    if targetPart then
                        local velocity = targetPart.AssemblyLinearVelocity / 3
                        args[1] = CFrame.new(targetPart.Position + Vector3.new(velocity.X, velocity.Y / 1.5, velocity.Z))
                    end
                end
            end
        end
    end
    
    return EnhancedKnifeHook(self, unpack(args))
end)

-- ═══════════════════════════════════════════════════════════
-- ADD ENHANCED UI CONTROLS
-- ═══════════════════════════════════════════════════════════

print("[Symphony] Adding Enhanced Features UI...")

-- Create Advanced section (after debug toggle)
createAimAssistSection(combatPage, "⚡ ADVANCED FEATURES", 200)

-- Sheriff Safe-Targeting toggle
createAimToggle(combatPage, "Sheriff Safe-Targeting", 201, true, function(enabled)
    EnhancedConfig.SheriffSafeTargeting.Enabled = enabled
    print("[Symphony] Sheriff Safe-Targeting:", enabled and "Enabled" or "Disabled")
end)

-- Knife Aura toggle
createAimToggle(combatPage, "Knife Aura (Thrown)", 202, false, function(enabled)
    EnhancedConfig.KnifeAuraOnThrow.Enabled = enabled
    if enabled then
        SymphonyEnhanced.KnifeAuraTracker:startTracking()
    else
        SymphonyEnhanced.KnifeAuraTracker:stopTracking()
    end
    print("[Symphony] Knife Aura on Throw:", enabled and "Enabled" or "Disabled")
end)

-- Knife Aura Radius slider
createAimSlider(combatPage, "Knife Aura Radius", 5, 20, 10, 203, function(value)
    EnhancedConfig.KnifeAuraOnThrow.AuraRadius = value
end)

-- Auto-Dodge toggle
createAimToggle(combatPage, "Auto-Dodge", 204, false, function(enabled)
    EnhancedConfig.AutoDodge.Enabled = enabled
    if enabled then
        SymphonyEnhanced.AutoDodge:startDodging()
    else
        SymphonyEnhanced.AutoDodge:stopDodging()
    end
    print("[Symphony] Auto-Dodge:", enabled and "Enabled" or "Disabled")
end)

-- Dodge Mode dropdown
createAimDropdown(combatPage, "Dodge Mode", {"Lateral", "Jump", "Teleport"}, 205, function(mode)
    EnhancedConfig.AutoDodge.DodgeMode = mode
    print("[Symphony] Dodge Mode:", mode)
end)

-- Dodge Threshold slider
createAimSlider(combatPage, "Dodge Threshold", 5, 20, 12, 206, function(value)
    EnhancedConfig.AutoDodge.DodgeThreshold = value
end)

-- Store globally
_G.SymphonyEnhanced = SymphonyEnhanced
_G.SymphonyEnhancedConfig = EnhancedConfig

-- ═══════════════════════════════════════════════════════════
-- COMPLETION
-- ═══════════════════════════════════════════════════════════

print("╔═══════════════════════════════════════════════════════╗")
print("║  SYMPHONY HUB - ENHANCED V2 LOADED ✓                 ║")
print("╚═══════════════════════════════════════════════════════╝")
print("")
print("📋 Controls:")
print("  • Enable aim assist from Combat tab")
print("  • Tab key - Switch targets")
print("  • Configure quality and smoothing in UI")
print("")
print("⚙️ Current Settings:")
print("  • Quality: balanced")
print("  • Max FOV: 120°")
print("  • Smoothing: 0.12")
print("")
print("⚡ Enhanced Features:")
print("  ✓ Sheriff Safe-Targeting: Enabled")
print("  ✓ Knife Aura on Throw: Disabled (toggle in UI)")
print("  ✓ Enhanced Auto-Dodge: Disabled (toggle in UI)")
print("  ✓ Target Priority System: Active")
print("")

return {
    AimAssist = aimAssist,
    Symphony = Symphony,
    Enhanced = SymphonyEnhanced,
    Config = EnhancedConfig
}
