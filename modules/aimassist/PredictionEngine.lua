--[[
╔═══════════════════════════════════════════════════════════╗
║           PREDICTION ENGINE - KALMAN + EMA                ║
║        Advanced Target Position & Velocity Prediction     ║
╚═══════════════════════════════════════════════════════════╝

Implements:
- Kalman Filter for optimal state estimation
- EMA (Exponential Moving Average) fallback
- Adaptive algorithm switching based on performance
]]

local PredictionEngine = {}
PredictionEngine.__index = PredictionEngine

-- ═══════════════════════════════════════════════════════════
-- KALMAN FILTER IMPLEMENTATION
-- ═══════════════════════════════════════════════════════════

local KalmanFilter = {}
KalmanFilter.__index = KalmanFilter

function KalmanFilter.new(config)
    local self = setmetatable({}, KalmanFilter)
    
    -- State vector: [x, y, z, vx, vy, vz]
    self.state = {0, 0, 0, 0, 0, 0}
    
    -- Error covariance matrix (6x6) - simplified diagonal
    self.errorCovariance = {
        1, 0, 0, 0, 0, 0,
        0, 1, 0, 0, 0, 0,
        0, 0, 1, 0, 0, 0,
        0, 0, 0, 1, 0, 0,
        0, 0, 0, 0, 1, 0,
        0, 0, 0, 0, 0, 1
    }
    
    -- Process noise (Q matrix) - how much we trust the motion model
    self.processNoise = config.processNoise or 1e-2
    
    -- Measurement noise (R matrix) - how much we trust measurements
    self.measurementNoise = config.measurementNoise or 1e-1
    
    self.initialized = false
    
    return self
end

function KalmanFilter:predict(dt)
    if not self.initialized then return end
    
    -- Validate inputs
    if type(dt) ~= "number" or dt <= 0 or dt > 1 then
        return
    end
    
    -- State transition: position += velocity * dt
    local newState = {
        self.state[1] + self.state[4] * dt,  -- x += vx * dt
        self.state[2] + self.state[5] * dt,  -- y += vy * dt
        self.state[3] + self.state[6] * dt,  -- z += vz * dt
        self.state[4],                        -- vx (constant velocity model)
        self.state[5],                        -- vy
        self.state[6]                         -- vz
    }
    
    -- Validate state
    for i = 1, 6 do
        if type(newState[i]) ~= "number" or newState[i] ~= newState[i] then  -- NaN check
            return
        end
    end
    
    self.state = newState
    
    -- Increase uncertainty (simplified)
    for i = 1, 36 do
        if i % 7 == 1 then  -- Diagonal elements
            self.errorCovariance[i] = self.errorCovariance[i] + self.processNoise
        end
    end
end

function KalmanFilter:update(measurement)
    -- measurement is {x, y, z}
    if not measurement or type(measurement) ~= "table" then return false end
    if not measurement[1] or not measurement[2] or not measurement[3] then return false end
    
    -- Validate measurement
    for i = 1, 3 do
        if type(measurement[i]) ~= "number" or measurement[i] ~= measurement[i] then
            return false
        end
    end
    
    if not self.initialized then
        -- Initialize state with first measurement
        self.state = {measurement[1], measurement[2], measurement[3], 0, 0, 0}
        self.initialized = true
        return true
    end
    
    -- Kalman gain calculation (simplified)
    local kalmanGain = {}
    for i = 1, 3 do
        local idx = (i-1) * 6 + i
        local denominator = self.errorCovariance[idx] + self.measurementNoise
        if denominator > 0 then
            kalmanGain[i] = self.errorCovariance[idx] / denominator
        else
            kalmanGain[i] = 0
        end
    end
    
    -- Update state with measurement
    for i = 1, 3 do
        local innovation = measurement[i] - self.state[i]
        self.state[i] = self.state[i] + kalmanGain[i] * innovation
        
        -- Update error covariance (simplified)
        local idx = (i-1) * 6 + i
        self.errorCovariance[idx] = (1 - kalmanGain[i]) * self.errorCovariance[idx]
    end
    
    return true
end

function KalmanFilter:updateVelocity(velocity)
    -- Update velocity estimate from external source
    if not velocity or type(velocity) ~= "table" then return end
    if not velocity[1] or not velocity[2] or not velocity[3] then return end
    
    -- Blend with current velocity estimate
    local alpha = 0.3  -- Trust new velocity measurement moderately
    for i = 4, 6 do
        local vIdx = i - 3
        if type(velocity[vIdx]) == "number" and velocity[vIdx] == velocity[vIdx] then
            self.state[i] = self.state[i] * (1 - alpha) + velocity[vIdx] * alpha
        end
    end
end

function KalmanFilter:getState()
    return {
        position = {self.state[1], self.state[2], self.state[3]},
        velocity = {self.state[4], self.state[5], self.state[6]}
    }
end

function KalmanFilter:reset()
    self.state = {0, 0, 0, 0, 0, 0}
    self.initialized = false
end

-- ═══════════════════════════════════════════════════════════
-- EMA PREDICTOR (LIGHTWEIGHT FALLBACK)
-- ═══════════════════════════════════════════════════════════

local EMAPredictor = {}
EMAPredictor.__index = EMAPredictor

function EMAPredictor.new(config)
    local self = setmetatable({}, EMAPredictor)
    
    self.alpha = config.alpha or 0.6  -- Smoothing factor
    self.lastPosition = nil
    self.lastVelocity = {0, 0, 0}
    self.lastTime = 0
    
    return self
end

function EMAPredictor:update(position, currentTime)
    if not position or type(position) ~= "table" then return false end
    if not position[1] or not position[2] or not position[3] then return false end
    
    -- Validate position
    for i = 1, 3 do
        if type(position[i]) ~= "number" or position[i] ~= position[i] then
            return false
        end
    end
    
    if not self.lastPosition then
        self.lastPosition = {position[1], position[2], position[3]}
        self.lastTime = currentTime
        return true
    end
    
    -- Calculate velocity
    local dt = currentTime - self.lastTime
    if dt > 0 and dt < 1 then  -- Sanity check
        local newVelocity = {}
        for i = 1, 3 do
            newVelocity[i] = (position[i] - self.lastPosition[i]) / dt
            -- Apply EMA smoothing to velocity
            self.lastVelocity[i] = self.alpha * newVelocity[i] + (1 - self.alpha) * self.lastVelocity[i]
        end
    end
    
    -- Update position with EMA
    for i = 1, 3 do
        self.lastPosition[i] = self.alpha * position[i] + (1 - self.alpha) * self.lastPosition[i]
    end
    
    self.lastTime = currentTime
    return true
end

function EMAPredictor:predict(dt)
    if not self.lastPosition then
        return {position = {0, 0, 0}, velocity = {0, 0, 0}}
    end
    
    -- Simple linear extrapolation
    local predictedPosition = {}
    for i = 1, 3 do
        predictedPosition[i] = self.lastPosition[i] + self.lastVelocity[i] * dt
    end
    
    return {
        position = predictedPosition,
        velocity = self.lastVelocity
    }
end

function EMAPredictor:reset()
    self.lastPosition = nil
    self.lastVelocity = {0, 0, 0}
    self.lastTime = 0
end

-- ═══════════════════════════════════════════════════════════
-- PREDICTION ENGINE (MAIN API)
-- ═══════════════════════════════════════════════════════════

function PredictionEngine.new(config)
    local self = setmetatable({}, PredictionEngine)
    
    self.config = config or {}
    self.quality = self.config.Quality or "balanced"
    
    -- Initialize predictors
    self.kalman = KalmanFilter.new({
        processNoise = self.config.Kalman and self.config.Kalman.processNoise or 1e-2,
        measurementNoise = self.config.Kalman and self.config.Kalman.measurementNoise or 1e-1
    })
    
    self.ema = EMAPredictor.new({
        alpha = self.config.EMA and self.config.EMA.alpha or 0.6
    })
    
    -- State
    self.currentPredictor = "kalman"  -- "kalman" or "ema"
    self.performanceHistory = {}
    self.lastUpdateTime = 0
    
    return self
end

function PredictionEngine:update(position, velocity, currentTime)
    -- Update both predictors
    local kalmanSuccess = false
    local emaSuccess = false
    
    -- Try Kalman filter
    if self.currentPredictor == "kalman" or self.quality == "high" then
        local posArray = {position.X, position.Y, position.Z}
        kalmanSuccess = self.kalman:update(posArray)
        
        if velocity and kalmanSuccess then
            local velArray = {velocity.X, velocity.Y, velocity.Z}
            self.kalman:updateVelocity(velArray)
        end
    end
    
    -- Always update EMA as fallback
    local posArray = {position.X, position.Y, position.Z}
    emaSuccess = self.ema:update(posArray, currentTime)
    
    -- Switch predictor based on quality and success
    if not kalmanSuccess and self.quality ~= "low" then
        self.currentPredictor = "ema"
    elseif kalmanSuccess and self.quality == "high" then
        self.currentPredictor = "kalman"
    end
    
    self.lastUpdateTime = currentTime
    
    return kalmanSuccess or emaSuccess
end

function PredictionEngine:predict(dt, extrapolationTime)
    local totalPredictionTime = dt + (extrapolationTime or 0)
    
    -- Clamp prediction time
    local maxPredictionTime = self.config.MaxPredictionTime or 0.35
    totalPredictionTime = math.min(totalPredictionTime, maxPredictionTime)
    totalPredictionTime = math.max(totalPredictionTime, 0)
    
    local state
    
    if self.currentPredictor == "kalman" and self.kalman.initialized then
        -- Use Kalman filter
        self.kalman:predict(totalPredictionTime)
        state = self.kalman:getState()
    else
        -- Use EMA predictor
        state = self.ema:predict(totalPredictionTime)
    end
    
    -- Convert to Vector3
    local predictedPosition = Vector3.new(
        state.position[1],
        state.position[2],
        state.position[3]
    )
    
    local predictedVelocity = Vector3.new(
        state.velocity[1],
        state.velocity[2],
        state.velocity[3]
    )
    
    return predictedPosition, predictedVelocity
end

function PredictionEngine:setQuality(quality)
    self.quality = quality
    
    if quality == "low" then
        self.currentPredictor = "ema"
    elseif quality == "high" then
        self.currentPredictor = "kalman"
    end
end

function PredictionEngine:reset()
    self.kalman:reset()
    self.ema:reset()
    self.currentPredictor = "kalman"
end

function PredictionEngine:getDebugInfo()
    return {
        predictor = self.currentPredictor,
        quality = self.quality,
        kalmanInitialized = self.kalman.initialized,
        lastUpdateTime = self.lastUpdateTime
    }
end

return PredictionEngine
