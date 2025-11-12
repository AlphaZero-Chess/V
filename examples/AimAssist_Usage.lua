--[[
╔═══════════════════════════════════════════════════════════╗
║      SYMPHONY HUB - AIM ASSIST USAGE EXAMPLES             ║
║            Integration & Configuration Guide              ║
╚═══════════════════════════════════════════════════════════╝

This file demonstrates how to integrate the Next-Gen Aim Assist
module into your Roblox script or Symphony Hub.
]]

-- ═══════════════════════════════════════════════════════════
-- EXAMPLE 1: BASIC SETUP
-- ═══════════════════════════════════════════════════════════

local function basicSetup()
    -- Load the aim assist module
    local AimAssist = require(game.ReplicatedStorage.AimAssistModule)
    
    -- Create instance with default config
    local aimAssist = AimAssist.new()
    
    -- Get required services
    local camera = workspace.CurrentCamera
    local runService = game:GetService("RunService")
    local stats = game:GetService("Stats")
    
    -- Initialize
    local success = aimAssist:init(camera, runService, stats)
    
    if not success then
        warn("Failed to initialize AimAssist")
        return
    end
    
    print("✓ AimAssist initialized")
    
    return aimAssist
end

-- ═══════════════════════════════════════════════════════════
-- EXAMPLE 2: CUSTOM CONFIGURATION
-- ═══════════════════════════════════════════════════════════

local function customConfiguration()
    local AimAssist = require(game.ReplicatedStorage.AimAssistModule)
    
    -- Custom config for aggressive tracking
    local config = {
        Quality = "high",              -- Max accuracy
        MaxPredictionTime = 0.4,       -- Longer extrapolation
        
        Kalman = {
            processNoise = 2e-2,       -- More aggressive prediction
            measurementNoise = 5e-2    -- Less trust in measurements
        },
        
        Smoothing = {
            maxAnglePerSec = 900,      -- Faster aim
            lerp = 0.18                -- Quicker response
        },
        
        MaxFOV = 120,                  -- Wide tracking area
        DeadZone = 0.5,                -- Smaller dead zone
        
        Debug = true                   -- Enable debug output
    }
    
    local aimAssist = AimAssist.new(config)
    
    local camera = workspace.CurrentCamera
    local runService = game:GetService("RunService")
    local stats = game:GetService("Stats")
    
    aimAssist:init(camera, runService, stats)
    
    return aimAssist
end

-- ═══════════════════════════════════════════════════════════
-- EXAMPLE 3: TARGET LOCKING
-- ═══════════════════════════════════════════════════════════

local function targetLocking(aimAssist)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    -- Find nearest enemy (example logic)
    local function findNearestEnemy()
        local nearestPlayer = nil
        local nearestDistance = math.huge
        
        local myPosition = LocalPlayer.Character and 
                          LocalPlayer.Character.HumanoidRootPart.Position
        
        if not myPosition then return nil end
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    local distance = (rootPart.Position - myPosition).Magnitude
                    if distance < nearestDistance then
                        nearestDistance = distance
                        nearestPlayer = player
                    end
                end
            end
        end
        
        return nearestPlayer
    end
    
    -- Lock onto nearest enemy
    local target = findNearestEnemy()
    
    if target then
        local success = aimAssist:lock(target)
        if success then
            print("✓ Locked onto:", target.Name)
        else
            warn("✗ Failed to lock target")
        end
    else
        print("No targets found")
    end
end

-- ═══════════════════════════════════════════════════════════
-- EXAMPLE 4: UPDATE LOOP INTEGRATION
-- ═══════════════════════════════════════════════════════════

local function updateLoopIntegration(aimAssist)
    local RunService = game:GetService("RunService")
    local camera = workspace.CurrentCamera
    
    -- Connect to RenderStepped for smooth updates
    local connection = RunService.RenderStepped:Connect(function(dt)
        -- Update aim assist
        local aimData = aimAssist:update(dt)
        
        if aimData then
            -- Apply aim to camera
            camera.CFrame = aimData.cameraLookAt
            
            -- Optional: Use aim vector for other purposes
            local aimVector = aimData.aimVector
            local predictedPosition = aimData.predictedPosition
            local distance = aimData.distance
            
            -- Debug output
            if aimAssist.debugEnabled then
                print(string.format(
                    "Aim: Vector(%.2f, %.2f, %.2f) | Distance: %.1f | FOV: %s",
                    aimVector.X, aimVector.Y, aimVector.Z,
                    distance,
                    tostring(aimData.inFOV)
                ))
            end
        end
    end)
    
    -- Return connection for cleanup
    return connection
end

-- ═══════════════════════════════════════════════════════════
-- EXAMPLE 5: KEYBIND CONTROL
-- ═══════════════════════════════════════════════════════════

local function keybindControl(aimAssist)
    local UserInputService = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    -- Toggle aim assist on/off
    local aimAssistEnabled = false
    local updateConnection = nil
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        -- Right Mouse Button to toggle
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            aimAssistEnabled = not aimAssistEnabled
            
            if aimAssistEnabled then
                -- Find and lock target
                local target = findClosestTarget()
                if target then
                    aimAssist:lock(target)
                    updateConnection = updateLoopIntegration(aimAssist)
                    print("✓ Aim Assist ENABLED")
                end
            else
                -- Release target
                aimAssist:release()
                if updateConnection then
                    updateConnection:Disconnect()
                end
                print("✗ Aim Assist DISABLED")
            end
        end
        
        -- Tab key to switch targets
        if input.KeyCode == Enum.KeyCode.Tab and aimAssistEnabled then
            local nextTarget = findNextTarget()
            if nextTarget then
                aimAssist:release()
                aimAssist:lock(nextTarget)
                print("→ Switched to:", nextTarget.Name)
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════
-- EXAMPLE 6: QUALITY PRESETS
-- ═══════════════════════════════════════════════════════════

local function qualityPresets(aimAssist)
    -- Low quality for performance
    aimAssist:setQuality("low")
    print("Quality: LOW (performance mode)")
    
    wait(5)
    
    -- Balanced quality (default)
    aimAssist:setQuality("balanced")
    print("Quality: BALANCED")
    
    wait(5)
    
    -- High quality for accuracy
    aimAssist:setQuality("high")
    print("Quality: HIGH (accuracy mode)")
end

-- ═══════════════════════════════════════════════════════════
-- EXAMPLE 7: DYNAMIC PARAMETER TUNING
-- ═══════════════════════════════════════════════════════════

local function dynamicTuning(aimAssist)
    -- Runtime parameter adjustments
    
    -- Adjust smoothing
    aimAssist:setParam("lerp", 0.2)  -- Faster aim
    
    -- Adjust FOV constraints
    aimAssist:setParam("maxFOV", 90)  -- Narrower tracking cone
    
    -- Adjust dead zone
    aimAssist:setParam("deadZone", 1.5)  -- Larger dead zone
    
    -- Adjust max turn speed
    aimAssist:setParam("maxAnglePerSec", 1000)  -- Faster turning
    
    -- Adjust latency compensation
    aimAssist:setParam("extrapolationFactor", 0.65)  -- More aggressive
    
    print("✓ Parameters tuned")
end

-- ═══════════════════════════════════════════════════════════
-- EXAMPLE 8: MANUAL PING MEASUREMENT
-- ═══════════════════════════════════════════════════════════

local function manualPingMeasurement(aimAssist)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")
    
    -- Ping measurement using remote function (example)
    local function measurePing()
        local startTime = tick()
        
        -- Send ping to server and wait for response
        -- (This requires a server-side RemoteFunction)
        local success, response = pcall(function()
            return ReplicatedStorage.PingRemote:InvokeServer()
        end)
        
        if success then
            local roundTripTime = (tick() - startTime) * 1000  -- Convert to ms
            return roundTripTime
        end
        
        return nil
    end
    
    -- Update aim assist with measured ping
    spawn(function()
        while true do
            wait(2)  -- Measure every 2 seconds
            
            local ping = measurePing()
            if ping then
                aimAssist:manualPingUpdate(ping)
                print(string.format("Ping updated: %.1f ms", ping))
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════
-- EXAMPLE 9: DEBUG & DIAGNOSTICS
-- ═══════════════════════════════════════════════════════════

local function debugDiagnostics(aimAssist)
    -- Enable debug mode
    aimAssist:debugToggle(true)
    
    -- Print debug info every 5 seconds
    spawn(function()
        while true do
            wait(5)
            aimAssist:printDebugInfo()
        end
    end)
    
    -- Get performance stats
    local stats = aimAssist:getPerformanceStats()
    print("Performance:")
    print("  Frame Count:", stats.frameCount)
    print("  Avg Frame Time:", string.format("%.3f ms", stats.avgFrameTime * 1000))
    print("  Effective FPS:", math.floor(stats.fps))
end

-- ═══════════════════════════════════════════════════════════
-- EXAMPLE 10: INTEGRATION WITH SYMPHONY HUB
-- ═══════════════════════════════════════════════════════════

local function symphonyHubIntegration()
    -- Assuming Symphony Hub is already loaded
    local Symphony = _G.Symphony or require(game.ReplicatedStorage.SymphonyHub)
    
    -- Load aim assist
    local AimAssist = require(game.ReplicatedStorage.AimAssistModule)
    local aimAssist = AimAssist.new({
        Quality = "balanced",
        Debug = false
    })
    
    -- Initialize with Symphony's services
    local camera = workspace.CurrentCamera
    local runService = game:GetService("RunService")
    local stats = game:GetService("Stats")
    
    aimAssist:init(camera, runService, stats)
    
    -- Add to Symphony's module system
    Symphony.AimAssist = aimAssist
    
    -- Create UI toggle in Symphony
    local MainTab = Symphony.UI:CreateTab("Combat", "rbxassetid://4483345998")
    
    local aimAssistSection = MainTab:CreateSection("Aim Assist")
    
    aimAssistSection:CreateToggle("Enable Aim Assist", function(enabled)
        if enabled then
            local target = findClosestTarget()
            if target then
                aimAssist:lock(target)
            end
        else
            aimAssist:release()
        end
    end)
    
    aimAssistSection:CreateDropdown("Quality", {"low", "balanced", "high"}, function(selected)
        aimAssist:setQuality(selected)
    end)
    
    aimAssistSection:CreateSlider("Smoothing", 0.05, 0.3, 0.12, function(value)
        aimAssist:setParam("lerp", value)
    end)
    
    aimAssistSection:CreateSlider("Max FOV", 30, 180, 120, function(value)
        aimAssist:setParam("maxFOV", value)
    end)
    
    print("✓ Aim Assist integrated with Symphony Hub")
end

-- ═══════════════════════════════════════════════════════════
-- COMPLETE EXAMPLE: FULL IMPLEMENTATION
-- ═══════════════════════════════════════════════════════════

local function fullImplementation()
    print("Initializing Next-Gen Aim Assist...")
    
    -- 1. Setup
    local aimAssist = basicSetup()
    
    -- 2. Configure for competitive play
    aimAssist:setQuality("balanced")
    aimAssist:setParam("maxFOV", 90)
    aimAssist:setParam("lerp", 0.15)
    
    -- 3. Setup keybinds
    keybindControl(aimAssist)
    
    -- 4. Enable diagnostics
    aimAssist:debugToggle(false)  -- Disable in production
    
    print("✓ Aim Assist fully operational")
    print("Controls:")
    print("  Right Click - Toggle Aim Assist")
    print("  Tab - Switch Targets")
end

-- ═══════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS (FOR EXAMPLES)
-- ═══════════════════════════════════════════════════════════

function findClosestTarget()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    if not LocalPlayer.Character then return nil end
    
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position
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

function findNextTarget()
    -- Implement target cycling logic
    return findClosestTarget()
end

-- ═══════════════════════════════════════════════════════════
-- RUN EXAMPLE
-- ═══════════════════════════════════════════════════════════

-- Uncomment to run a specific example:
-- fullImplementation()

return {
    basicSetup = basicSetup,
    customConfiguration = customConfiguration,
    targetLocking = targetLocking,
    updateLoopIntegration = updateLoopIntegration,
    keybindControl = keybindControl,
    qualityPresets = qualityPresets,
    dynamicTuning = dynamicTuning,
    manualPingMeasurement = manualPingMeasurement,
    debugDiagnostics = debugDiagnostics,
    symphonyHubIntegration = symphonyHubIntegration,
    fullImplementation = fullImplementation
}
