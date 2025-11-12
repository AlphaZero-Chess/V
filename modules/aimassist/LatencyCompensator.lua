--[[
╔═══════════════════════════════════════════════════════════╗
║              LATENCY COMPENSATOR MODULE                   ║
║    Adaptive Ping Detection & Extrapolation Calculation    ║
╚═══════════════════════════════════════════════════════════╝

Features:
- Real-time ping estimation
- Adaptive extrapolation time calculation
- Smoothed latency values to avoid jitter
- Support for low/medium/high latency scenarios
]]

local LatencyCompensator = {}
LatencyCompensator.__index = LatencyCompensator

function LatencyCompensator.new(config)
    local self = setmetatable({}, LatencyCompensator)
    
    self.config = config or {}
    self.pingWindow = self.config.PingSmoothingWindow or 8
    
    -- Ping history for smoothing
    self.pingHistory = {}
    self.currentPing = 0
    self.smoothedPing = 0
    
    -- Latency profile
    self.latencyProfile = "medium"  -- "low", "medium", "high"
    
    -- Extrapolation settings
    self.extrapolationFactor = 0.5  -- Default: compensate for half RTT
    self.maxExtrapolation = 0.25     -- Max 250ms extrapolation
    self.minExtrapolation = 0.0      -- Min 0ms extrapolation
    
    -- Stats tracking
    self.statsUpdateInterval = 1.0   -- Update stats every second
    self.lastStatsUpdate = 0
    self.pingSamples = 0
    
    return self
end

-- ═══════════════════════════════════════════════════════════
-- PING ESTIMATION
-- ═══════════════════════════════════════════════════════════

function LatencyCompensator:updatePing(pingValue)
    if type(pingValue) ~= "number" or pingValue < 0 or pingValue > 5000 then
        return false
    end
    
    -- Add to history
    table.insert(self.pingHistory, pingValue)
    
    -- Maintain window size
    if #self.pingHistory > self.pingWindow then
        table.remove(self.pingHistory, 1)
    end
    
    -- Calculate smoothed ping (moving average)
    local sum = 0
    for _, ping in ipairs(self.pingHistory) do
        sum = sum + ping
    end
    self.smoothedPing = sum / #self.pingHistory
    self.currentPing = pingValue
    
    -- Update latency profile
    self:_updateLatencyProfile()
    
    self.pingSamples = self.pingSamples + 1
    
    return true
end

function LatencyCompensator:_updateLatencyProfile()
    if self.smoothedPing < 50 then
        self.latencyProfile = "low"
        self.extrapolationFactor = 0.4  -- Less aggressive for low ping
    elseif self.smoothedPing < 150 then
        self.latencyProfile = "medium"
        self.extrapolationFactor = 0.5  -- Standard compensation
    else
        self.latencyProfile = "high"
        self.extrapolationFactor = 0.6  -- More aggressive for high ping
    end
end

-- ═══════════════════════════════════════════════════════════
-- EXTRAPOLATION CALCULATION
-- ═══════════════════════════════════════════════════════════

function LatencyCompensator:getExtrapolationTime()
    -- Calculate extrapolation time based on smoothed ping
    -- Formula: extrapolationTime = (ping / 1000) * extrapolationFactor
    local extrapolationTime = (self.smoothedPing / 1000) * self.extrapolationFactor
    
    -- Clamp to reasonable bounds
    extrapolationTime = math.max(self.minExtrapolation, extrapolationTime)
    extrapolationTime = math.min(self.maxExtrapolation, extrapolationTime)
    
    return extrapolationTime
end

function LatencyCompensator:getAdaptiveExtrapolation(velocity)
    -- Adaptive extrapolation based on target velocity
    local baseExtrapolation = self:getExtrapolationTime()
    
    if not velocity then
        return baseExtrapolation
    end
    
    -- Calculate velocity magnitude
    local velocityMag = 0
    if typeof(velocity) == "Vector3" then
        velocityMag = velocity.Magnitude
    elseif type(velocity) == "table" and velocity[1] then
        velocityMag = math.sqrt(velocity[1]^2 + velocity[2]^2 + velocity[3]^2)
    end
    
    -- Increase extrapolation for fast-moving targets
    local velocityFactor = 1.0
    if velocityMag > 30 then  -- Fast movement (Roblox units/sec)
        velocityFactor = 1.15
    elseif velocityMag > 50 then  -- Very fast movement
        velocityFactor = 1.25
    end
    
    local adaptiveExtrapolation = baseExtrapolation * velocityFactor
    
    -- Still respect max bounds
    return math.min(adaptiveExtrapolation, self.maxExtrapolation)
end

-- ═══════════════════════════════════════════════════════════
-- ROBLOX PING ESTIMATION (STATS-BASED)
-- ═══════════════════════════════════════════════════════════

function LatencyCompensator:estimateFromStats(stats)
    -- Roblox Stats service integration
    if not stats then return end
    
    local success, ping = pcall(function()
        -- Try to get network stats
        local networkStats = stats:FindFirstChild("Network")
        if networkStats then
            local pingStats = networkStats:FindFirstChild("ServerStatsItem")
            if pingStats then
                -- Extract ping value (typically in format "XX ms")
                local pingText = pingStats.ValueText
                if pingText then
                    local pingNum = tonumber(pingText:match("%d+"))
                    if pingNum then
                        return pingNum
                    end
                end
            end
        end
        
        -- Fallback: use DistributedGameTime for rough estimate
        -- This is less accurate but always available
        return 50  -- Default assumption for medium latency
    end)
    
    if success and ping then
        self:updatePing(ping)
    end
end

-- ═══════════════════════════════════════════════════════════
-- MANUAL PING UPDATE (FROM USER MEASUREMENT)
-- ═══════════════════════════════════════════════════════════

function LatencyCompensator:manualUpdate(roundTripTime)
    -- User can provide manual RTT measurement
    if type(roundTripTime) == "number" and roundTripTime > 0 then
        -- Convert to one-way ping (approximate)
        local estimatedPing = roundTripTime / 2
        self:updatePing(estimatedPing)
    end
end

-- ═══════════════════════════════════════════════════════════
-- QUERY METHODS
-- ═══════════════════════════════════════════════════════════

function LatencyCompensator:getCurrentPing()
    return self.currentPing
end

function LatencyCompensator:getSmoothedPing()
    return self.smoothedPing
end

function LatencyCompensator:getLatencyProfile()
    return self.latencyProfile
end

function LatencyCompensator:getPingHistory()
    return self.pingHistory
end

-- ═══════════════════════════════════════════════════════════
-- CONFIGURATION
-- ═══════════════════════════════════════════════════════════

function LatencyCompensator:setExtrapolationFactor(factor)
    if type(factor) == "number" and factor >= 0 and factor <= 1 then
        self.extrapolationFactor = factor
        return true
    end
    return false
end

function LatencyCompensator:setMaxExtrapolation(maxTime)
    if type(maxTime) == "number" and maxTime >= 0 and maxTime <= 1 then
        self.maxExtrapolation = maxTime
        return true
    end
    return false
end

function LatencyCompensator:reset()
    self.pingHistory = {}
    self.currentPing = 0
    self.smoothedPing = 0
    self.latencyProfile = "medium"
    self.pingSamples = 0
end

-- ═══════════════════════════════════════════════════════════
-- DEBUG INFO
-- ═══════════════════════════════════════════════════════════

function LatencyCompensator:getDebugInfo()
    return {
        currentPing = string.format("%.1f ms", self.currentPing),
        smoothedPing = string.format("%.1f ms", self.smoothedPing),
        latencyProfile = self.latencyProfile,
        extrapolationTime = string.format("%.3f s", self:getExtrapolationTime()),
        extrapolationFactor = self.extrapolationFactor,
        pingSamples = self.pingSamples,
        historySize = #self.pingHistory
    }
end

return LatencyCompensator
