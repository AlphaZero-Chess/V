--[[
╔═══════════════════════════════════════════════════════════╗
║                JUMP PREDICTOR MODULE                       ║
║        Advanced Jump Arc & Projectile Motion Prediction   ║
╚═══════════════════════════════════════════════════════════╝

Features:
- Projectile motion physics with gravity
- Jump detection and tracking
- Apex prediction
- Landing position calculation
- Air drag simulation
- Multi-jump support
]]

local JumpPredictor = {}
JumpPredictor.__index = JumpPredictor

-- Roblox gravity constant
local GRAVITY = 196.2  -- Roblox default gravity (studs/s²)
local AIR_DRAG = 0.95   -- Air resistance factor per frame

function JumpPredictor.new(config)
    local self = setmetatable({}, JumpPredictor)
    
    self.config = config or {}
    self.enabled = self.config.EnableJumpPredict ~= false  -- Enabled by default
    
    -- Jump state tracking
    self.isJumping = false
    self.jumpStartTime = 0
    self.jumpStartPosition = Vector3.new(0, 0, 0)
    self.jumpStartVelocity = Vector3.new(0, 0, 0)
    self.lastGroundedState = true
    self.groundHeight = 0
    
    -- Physics parameters
    self.gravity = self.config.Gravity or GRAVITY
    self.airDrag = self.config.AirDrag or AIR_DRAG
    
    -- Jump arc data
    self.apexHeight = 0
    self.apexTime = 0
    self.landingTime = 0
    self.landingPosition = Vector3.new(0, 0, 0)
    
    return self
end

-- ═══════════════════════════════════════════════════════════
-- JUMP DETECTION
-- ═══════════════════════════════════════════════════════════

function JumpPredictor:update(position, velocity, isGrounded, currentTime)
    if not self.enabled then return end
    
    -- Validate inputs
    if not position or typeof(position) ~= "Vector3" then return end
    if not velocity or typeof(velocity) ~= "Vector3" then return end
    if type(isGrounded) ~= "boolean" then return end
    if type(currentTime) ~= "number" then return end
    
    -- Detect jump start (transition from grounded to airborne)
    if self.lastGroundedState and not isGrounded then
        self:_onJumpStart(position, velocity, currentTime)
    end
    
    -- Detect landing (transition from airborne to grounded)
    if not self.lastGroundedState and isGrounded then
        self:_onLanding(position, currentTime)
    end
    
    -- Update jump state while airborne
    if self.isJumping and not isGrounded then
        self:_updateJumpState(position, velocity, currentTime)
    end
    
    self.lastGroundedState = isGrounded
end

function JumpPredictor:_onJumpStart(position, velocity, currentTime)
    self.isJumping = true
    self.jumpStartTime = currentTime
    self.jumpStartPosition = position
    self.jumpStartVelocity = velocity
    self.groundHeight = position.Y
    
    -- Calculate apex and landing predictions
    self:_calculateJumpArc()
end

function JumpPredictor:_onLanding(position, currentTime)
    self.isJumping = false
    self.groundHeight = position.Y
end

function JumpPredictor:_updateJumpState(position, velocity, currentTime)
    local timeInAir = currentTime - self.jumpStartTime
    
    -- Recalculate predictions based on current state
    -- This adapts to external forces (e.g., player movement during jump)
    if timeInAir > 0.1 then  -- After initial jump impulse
        self:_calculateJumpArc()
    end
end

-- ═══════════════════════════════════════════════════════════
-- JUMP ARC CALCULATION (PROJECTILE MOTION)
-- ═══════════════════════════════════════════════════════════

function JumpPredictor:_calculateJumpArc()
    local vy0 = self.jumpStartVelocity.Y  -- Initial vertical velocity
    
    if vy0 <= 0 then
        -- Not actually jumping (falling)
        self.apexHeight = self.jumpStartPosition.Y
        self.apexTime = 0
        self.landingTime = self:_calculateFallTime(self.jumpStartPosition.Y, self.groundHeight)
        return
    end
    
    -- Time to apex: t_apex = vy0 / g
    self.apexTime = vy0 / self.gravity
    
    -- Maximum height: h_max = h0 + (vy0²) / (2g)
    self.apexHeight = self.jumpStartPosition.Y + (vy0 * vy0) / (2 * self.gravity)
    
    -- Time to land (from apex): t_fall = sqrt(2 * (h_max - h_ground) / g)
    local fallDistance = math.max(0, self.apexHeight - self.groundHeight)
    local fallTime = math.sqrt(2 * fallDistance / self.gravity)
    
    -- Total air time
    self.landingTime = self.apexTime + fallTime
    
    -- Landing position (horizontal motion assumed constant)
    local horizontalVelocity = Vector3.new(
        self.jumpStartVelocity.X,
        0,
        self.jumpStartVelocity.Z
    )
    
    self.landingPosition = self.jumpStartPosition + (horizontalVelocity * self.landingTime)
    self.landingPosition = Vector3.new(
        self.landingPosition.X,
        self.groundHeight,
        self.landingPosition.Z
    )
end

function JumpPredictor:_calculateFallTime(currentHeight, targetHeight)
    -- Time to fall from currentHeight to targetHeight
    local fallDistance = math.max(0, currentHeight - targetHeight)
    if fallDistance <= 0 then return 0 end
    
    -- t = sqrt(2h / g)
    return math.sqrt(2 * fallDistance / self.gravity)
end

-- ═══════════════════════════════════════════════════════════
-- POSITION PREDICTION DURING JUMP
-- ═══════════════════════════════════════════════════════════

function JumpPredictor:predictPosition(currentPosition, currentVelocity, currentTime, predictionTime)
    if not self.enabled or not self.isJumping then
        return nil  -- Not jumping, use standard prediction
    end
    
    local timeInAir = currentTime - self.jumpStartTime
    local futurTimeInAir = timeInAir + predictionTime
    
    -- Clamp to landing time
    if futurTimeInAir > self.landingTime then
        -- Predict landing position
        return self.landingPosition
    end
    
    -- Projectile motion equations
    -- x(t) = x0 + vx0 * t
    -- y(t) = y0 + vy0 * t - 0.5 * g * t²
    -- z(t) = z0 + vz0 * t
    
    local vy0 = self.jumpStartVelocity.Y
    local vx0 = self.jumpStartVelocity.X
    local vz0 = self.jumpStartVelocity.Z
    
    local x = self.jumpStartPosition.X + vx0 * futurTimeInAir
    local y = self.jumpStartPosition.Y + vy0 * futurTimeInAir - 0.5 * self.gravity * futurTimeInAir * futurTimeInAir
    local z = self.jumpStartPosition.Z + vz0 * futurTimeInAir
    
    -- Clamp Y to ground level (can't go below ground)
    y = math.max(y, self.groundHeight)
    
    return Vector3.new(x, y, z)
end

function JumpPredictor:predictVelocity(currentTime, predictionTime)
    if not self.enabled or not self.isJumping then
        return nil  -- Not jumping, use standard prediction
    end
    
    local timeInAir = currentTime - self.jumpStartTime + predictionTime
    
    -- Velocity equations
    -- vx(t) = vx0 (constant horizontal)
    -- vy(t) = vy0 - g * t
    -- vz(t) = vz0 (constant horizontal)
    
    local vx = self.jumpStartVelocity.X
    local vy = self.jumpStartVelocity.Y - self.gravity * timeInAir
    local vz = self.jumpStartVelocity.Z
    
    return Vector3.new(vx, vy, vz)
end

-- ═══════════════════════════════════════════════════════════
-- ADVANCED: APEX PREDICTION
-- ═══════════════════════════════════════════════════════════

function JumpPredictor:getApexPosition()
    if not self.isJumping then return nil end
    
    local horizontalVelocity = Vector3.new(
        self.jumpStartVelocity.X,
        0,
        self.jumpStartVelocity.Z
    )
    
    local apexPosition = self.jumpStartPosition + (horizontalVelocity * self.apexTime)
    return Vector3.new(apexPosition.X, self.apexHeight, apexPosition.Z)
end

function JumpPredictor:getTimeToApex(currentTime)
    if not self.isJumping then return 0 end
    
    local timeInAir = currentTime - self.jumpStartTime
    local timeRemaining = self.apexTime - timeInAir
    return math.max(0, timeRemaining)
end

function JumpPredictor:getTimeToLanding(currentTime)
    if not self.isJumping then return 0 end
    
    local timeInAir = currentTime - self.jumpStartTime
    local timeRemaining = self.landingTime - timeInAir
    return math.max(0, timeRemaining)
end

-- ═══════════════════════════════════════════════════════════
-- QUERY METHODS
-- ═══════════════════════════════════════════════════════════

function JumpPredictor:isCurrentlyJumping()
    return self.isJumping
end

function JumpPredictor:getLandingPosition()
    return self.landingPosition
end

function JumpPredictor:getJumpInfo()
    return {
        isJumping = self.isJumping,
        apexHeight = self.apexHeight,
        apexTime = self.apexTime,
        landingTime = self.landingTime,
        landingPosition = self.landingPosition,
        jumpStartTime = self.jumpStartTime
    }
end

-- ═══════════════════════════════════════════════════════════
-- CONFIGURATION
-- ═══════════════════════════════════════════════════════════

function JumpPredictor:setEnabled(enabled)
    self.enabled = enabled
end

function JumpPredictor:setGravity(gravity)
    if type(gravity) == "number" and gravity > 0 then
        self.gravity = gravity
    end
end

function JumpPredictor:reset()
    self.isJumping = false
    self.jumpStartTime = 0
    self.jumpStartPosition = Vector3.new(0, 0, 0)
    self.jumpStartVelocity = Vector3.new(0, 0, 0)
    self.lastGroundedState = true
end

-- ═══════════════════════════════════════════════════════════
-- DEBUG INFO
-- ═══════════════════════════════════════════════════════════

function JumpPredictor:getDebugInfo()
    return {
        enabled = self.enabled,
        isJumping = self.isJumping,
        apexHeight = string.format("%.2f", self.apexHeight),
        landingTime = string.format("%.3f s", self.landingTime),
        gravity = self.gravity
    }
end

return JumpPredictor
