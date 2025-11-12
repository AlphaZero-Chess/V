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
-- COMPLETION
-- ═══════════════════════════════════════════════════════════

print("╔═══════════════════════════════════════════════════════╗")
print("║  SYMPHONY HUB - NEXT-GEN AIM ASSIST LOADED ✓         ║")
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

return {
    AimAssist = aimAssist,
    Symphony = Symphony
}
