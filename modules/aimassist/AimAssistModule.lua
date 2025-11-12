--[[
╔═══════════════════════════════════════════════════════════╗
║         SYMPHONY HUB - NEXT-GEN AIM ASSIST MODULE         ║
║          Top-Tier Predictive Tracking System              ║
║                    © Symphony Hub 2025                    ║
╚═══════════════════════════════════════════════════════════╝

FEATURES:
✓ Kalman Filter + EMA prediction algorithms
✓ Adaptive latency compensation (auto ping detection)
✓ Jump trajectory prediction with gravity simulation
✓ Quality presets: Low / Balanced / High
✓ Smooth aim with FOV constraints
✓ Real-time performance monitoring
✓ Debug visualization and tuning

ARCHITECTURE:
- PredictionEngine: Kalman + EMA state estimation
- LatencyCompensator: Ping-aware extrapolation
- JumpPredictor: Projectile motion physics
- MovementTracker: Target state management
- AimSolver: Camera aim adjustments
]]

-- ═══════════════════════════════════════════════════════════
-- MODULE DEPENDENCIES
-- ═══════════════════════════════════════════════════════════

local PredictionEngine = require(script.Parent.PredictionEngine)
local LatencyCompensator = require(script.Parent.LatencyCompensator)
local JumpPredictor = require(script.Parent.JumpPredictor)
local MovementTracker = require(script.Parent.MovementTracker)
local AimSolver = require(script.Parent.AimSolver)

-- ═══════════════════════════════════════════════════════════
-- AIM ASSIST MAIN MODULE
-- ═══════════════════════════════════════════════════════════

local AimAssist = {}
AimAssist.__index = AimAssist

-- Default configuration
local DEFAULT_CONFIG = {
    Quality = "balanced",            -- "low" | "balanced" | "high"
    MaxPredictionTime = 0.35,        -- seconds
    PingSmoothingWindow = 8,         -- samples
    
    Kalman = {
        processNoise = 1e-2,
        measurementNoise = 1e-1
    },
    
    EMA = {
        alpha = 0.6
    },
    
    Smoothing = {
        maxAnglePerSec = 720,        -- degrees/second
        lerp = 0.12                   -- 0-1, higher = faster aim
    },
    
    EnableJumpPredict = true,
    
    MaxFOV = 180,                    -- Maximum FOV in degrees
    DeadZone = 1,                    -- Dead zone in degrees
    
    Debug = false
}

function AimAssist.new(config)
    local self = setmetatable({}, AimAssist)
    
    -- Merge config with defaults
    self.config = {}
    for key, value in pairs(DEFAULT_CONFIG) do
        if config and config[key] ~= nil then
            self.config[key] = config[key]
        else
            self.config[key] = value
        end
    end
    
    -- Deep merge for nested tables
    if config and config.Kalman then
        self.config.Kalman = {}
        for key, value in pairs(DEFAULT_CONFIG.Kalman) do
            self.config.Kalman[key] = config.Kalman[key] or value
        end
    end
    
    if config and config.EMA then
        self.config.EMA = {}
        for key, value in pairs(DEFAULT_CONFIG.EMA) do
            self.config.EMA[key] = config.EMA[key] or value
        end
    end
    
    if config and config.Smoothing then
        self.config.Smoothing = {}
        for key, value in pairs(DEFAULT_CONFIG.Smoothing) do
            self.config.Smoothing[key] = config.Smoothing[key] or value
        end
    end
    
    -- Initialize components
    self.tracker = MovementTracker.new(self.config)
    self.predictor = PredictionEngine.new(self.config)
    self.latency = LatencyCompensator.new(self.config)
    self.jumpPredictor = JumpPredictor.new(self.config)
    self.aimSolver = nil  -- Initialized when camera is set
    
    -- State
    self.active = false
    self.locked = false
    self.initialized = false
    
    -- Services (to be set by init)
    self.camera = nil
    self.runService = nil
    self.stats = nil
    
    -- Performance tracking
    self.frameCount = 0
    self.totalProcessTime = 0
    self.avgFrameTime = 0
    
    -- Debug
    self.debugEnabled = self.config.Debug
    self.debugVisuals = {}
    
    return self
end

-- ═══════════════════════════════════════════════════════════
-- INITIALIZATION
-- ═══════════════════════════════════════════════════════════

function AimAssist:init(camera, runService, stats)
    if self.initialized then
        return true
    end
    
    -- Validate inputs
    if not camera then
        warn("[AimAssist] Camera required for initialization")
        return false
    end
    
    self.camera = camera
    self.runService = runService or game:GetService("RunService")
    self.stats = stats or game:GetService("Stats")
    
    -- Initialize AimSolver with camera
    self.aimSolver = AimSolver.new(self.config, self.camera)
    
    self.initialized = true
    
    return true
end

-- ═══════════════════════════════════════════════════════════
-- TARGET MANAGEMENT
-- ═══════════════════════════════════════════════════════════

function AimAssist:lock(target)
    if not self.initialized then
        warn("[AimAssist] Not initialized. Call init() first.")
        return false
    end
    
    if not target then
        return false
    end
    
    -- Set target in tracker
    local success = self.tracker:setTarget(target)
    
    if success then
        self.locked = true
        self.active = true
        
        -- Reset predictors for new target
        self.predictor:reset()
        self.jumpPredictor:reset()
        self.aimSolver:reset()
        
        return true
    end
    
    return false
end

function AimAssist:release()
    self.locked = false
    self.active = false
    self.tracker:clearTarget()
    self.predictor:reset()
    self.jumpPredictor:reset()
    self.aimSolver:reset()
end

function AimAssist:getTarget()
    return self.tracker:getTarget()
end

function AimAssist:isLocked()
    return self.locked and self.tracker:isTargetValid()
end

-- ═══════════════════════════════════════════════════════════
-- MAIN UPDATE LOOP
-- ═══════════════════════════════════════════════════════════

function AimAssist:update(dt)
    if not self.active or not self.locked then
        return nil
    end
    
    if not self.initialized then
        return nil
    end
    
    local startTime = tick()
    
    -- Validate target
    if not self.tracker:validateTarget() then
        self:release()
        return nil
    end
    
    local currentTime = tick()
    
    -- Update tracker (sample target state)
    if not self.tracker:update(currentTime) then
        return nil
    end
    
    local position = self.tracker:getPosition()
    local velocity = self.tracker:getVelocity()
    local isGrounded = self.tracker:isTargetGrounded()
    
    if not position then
        return nil
    end
    
    -- Update latency estimator
    self.latency:estimateFromStats(self.stats)
    local extrapolationTime = self.latency:getAdaptiveExtrapolation(velocity)
    
    -- Update jump predictor
    self.jumpPredictor:update(position, velocity, isGrounded, currentTime)
    
    -- Update prediction engine
    self.predictor:update(position, velocity, currentTime)
    
    -- Get prediction
    local predictedPosition, predictedVelocity
    
    -- Check if jump prediction should override
    if self.jumpPredictor:isCurrentlyJumping() then
        predictedPosition = self.jumpPredictor:predictPosition(
            position, velocity, currentTime, extrapolationTime
        )
        predictedVelocity = self.jumpPredictor:predictVelocity(
            currentTime, extrapolationTime
        )
    end
    
    -- Fallback to standard prediction
    if not predictedPosition then
        predictedPosition, predictedVelocity = self.predictor:predict(dt, extrapolationTime)
    end
    
    if not predictedPosition then
        return nil
    end
    
    -- Compute aim adjustment
    local aimVector = self.aimSolver:computeAim(predictedPosition, dt)
    
    if not aimVector then
        return nil  -- Target outside FOV or in dead zone
    end
    
    -- Calculate camera CFrame
    local cameraLookAt = self.aimSolver:getCameraLookAt(predictedPosition)
    
    -- Performance tracking
    local processTime = tick() - startTime
    self.frameCount = self.frameCount + 1
    self.totalProcessTime = self.totalProcessTime + processTime
    self.avgFrameTime = self.totalProcessTime / self.frameCount
    
    -- Debug visualization
    if self.debugEnabled then
        self:_updateDebugVisuals(position, predictedPosition, aimVector)
    end
    
    return {
        aimVector = aimVector,
        cameraLookAt = cameraLookAt,
        predictedPosition = predictedPosition,
        predictedVelocity = predictedVelocity,
        currentPosition = position,
        currentVelocity = velocity,
        extrapolationTime = extrapolationTime,
        inFOV = self.aimSolver:isTargetInFOV(),
        distance = self.aimSolver:getDistanceToTarget(predictedPosition)
    }
end

-- ═══════════════════════════════════════════════════════════
-- QUALITY & CONFIGURATION
-- ═══════════════════════════════════════════════════════════

function AimAssist:setQuality(quality)
    if quality ~= "low" and quality ~= "balanced" and quality ~= "high" then
        warn("[AimAssist] Invalid quality: " .. tostring(quality))
        return false
    end
    
    self.config.Quality = quality
    self.predictor:setQuality(quality)
    
    -- Adjust smoothing based on quality
    if quality == "low" then
        self.aimSolver:setLerpFactor(0.08)
        self.aimSolver:setMaxAnglePerSec(600)
    elseif quality == "balanced" then
        self.aimSolver:setLerpFactor(0.12)
        self.aimSolver:setMaxAnglePerSec(720)
    elseif quality == "high" then
        self.aimSolver:setLerpFactor(0.15)
        self.aimSolver:setMaxAnglePerSec(900)
    end
    
    return true
end

function AimAssist:setParam(name, value)
    -- Dynamic parameter tuning
    if name == "lerp" then
        self.aimSolver:setLerpFactor(value)
    elseif name == "maxFOV" then
        self.aimSolver:setMaxFOV(value)
    elseif name == "deadZone" then
        self.aimSolver:setDeadZone(value)
    elseif name == "maxAnglePerSec" then
        self.aimSolver:setMaxAnglePerSec(value)
    elseif name == "extrapolationFactor" then
        self.latency:setExtrapolationFactor(value)
    elseif name == "maxExtrapolation" then
        self.latency:setMaxExtrapolation(value)
    elseif name == "gravity" then
        self.jumpPredictor:setGravity(value)
    else
        warn("[AimAssist] Unknown parameter: " .. name)
        return false
    end
    
    return true
end

-- ═══════════════════════════════════════════════════════════
-- DEBUG & DIAGNOSTICS
-- ═══════════════════════════════════════════════════════════

function AimAssist:debugToggle(enabled)
    self.debugEnabled = enabled
    
    if not enabled then
        self:_clearDebugVisuals()
    end
end

function AimAssist:getDebugInfo()
    if not self.initialized then
        return {status = "Not Initialized"}
    end
    
    local info = {
        -- Status
        active = self.active,
        locked = self.locked,
        target = self.tracker:getTarget() and self.tracker:getTarget().Name or "None",
        
        -- Performance
        frameCount = self.frameCount,
        avgFrameTime = string.format("%.3f ms", self.avgFrameTime * 1000),
        
        -- Components
        tracker = self.tracker:getDebugInfo(),
        predictor = self.predictor:getDebugInfo(),
        latency = self.latency:getDebugInfo(),
        jumpPredictor = self.jumpPredictor:getDebugInfo(),
        aimSolver = self.aimSolver:getDebugInfo()
    }
    
    return info
end

function AimAssist:printDebugInfo()
    local info = self:getDebugInfo()
    
    print("╔═══════════════════════════════════════╗")
    print("║   SYMPHONY AIM ASSIST - DEBUG INFO    ║")
    print("╚═══════════════════════════════════════╝")
    print("")
    print("[STATUS]")
    print("  Active:", info.active)
    print("  Locked:", info.locked)
    print("  Target:", info.target)
    print("")
    print("[PERFORMANCE]")
    print("  Frame Count:", info.frameCount)
    print("  Avg Frame Time:", info.avgFrameTime)
    print("")
    print("[PREDICTION]")
    print("  Algorithm:", info.predictor.predictor)
    print("  Quality:", info.predictor.quality)
    print("")
    print("[LATENCY]")
    print("  Current Ping:", info.latency.currentPing)
    print("  Smoothed Ping:", info.latency.smoothedPing)
    print("  Profile:", info.latency.latencyProfile)
    print("  Extrapolation:", info.latency.extrapolationTime)
    print("")
    print("[JUMP]")
    print("  Is Jumping:", info.jumpPredictor.isJumping)
    print("  Apex Height:", info.jumpPredictor.apexHeight)
    print("")
    print("[AIM]")
    print("  Lerp Factor:", info.aimSolver.lerpFactor)
    print("  Max FOV:", info.aimSolver.maxFOV)
    print("  Target in FOV:", info.aimSolver.targetInFOV)
end

function AimAssist:_updateDebugVisuals(currentPos, predictedPos, aimVector)
    -- Create visual indicators for debugging
    -- Implementation depends on rendering system
    -- This is a placeholder for visual debugging
end

function AimAssist:_clearDebugVisuals()
    for _, visual in pairs(self.debugVisuals) do
        if visual and visual.Destroy then
            visual:Destroy()
        end
    end
    self.debugVisuals = {}
end

-- ═══════════════════════════════════════════════════════════
-- UTILITY METHODS
-- ═══════════════════════════════════════════════════════════

function AimAssist:getPerformanceStats()
    return {
        frameCount = self.frameCount,
        totalTime = self.totalProcessTime,
        avgFrameTime = self.avgFrameTime,
        fps = self.avgFrameTime > 0 and (1 / self.avgFrameTime) or 0
    }
end

function AimAssist:resetPerformanceStats()
    self.frameCount = 0
    self.totalProcessTime = 0
    self.avgFrameTime = 0
end

function AimAssist:shutdown()
    self:release()
    self:_clearDebugVisuals()
    self.initialized = false
end

-- ═══════════════════════════════════════════════════════════
-- ADVANCED API
-- ═══════════════════════════════════════════════════════════

function AimAssist:attachTarget(player)
    -- Alias for lock()
    return self:lock(player)
end

function AimAssist:detachTarget()
    -- Alias for release()
    self:release()
end

function AimAssist:getPredictedPosition()
    if not self.locked or not self.tracker:isTargetValid() then
        return nil
    end
    
    local currentTime = tick()
    local position = self.tracker:getPosition()
    local velocity = self.tracker:getVelocity()
    
    if not position then return nil end
    
    local extrapolationTime = self.latency:getAdaptiveExtrapolation(velocity)
    local predictedPosition, _ = self.predictor:predict(0, extrapolationTime)
    
    return predictedPosition
end

function AimAssist:manualPingUpdate(roundTripTime)
    self.latency:manualUpdate(roundTripTime)
end

-- ═══════════════════════════════════════════════════════════
-- MODULE EXPORT
-- ═══════════════════════════════════════════════════════════

return AimAssist
