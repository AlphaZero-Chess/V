--[[
╔═══════════════════════════════════════════════════════════╗
║              MOVEMENT TRACKER MODULE                      ║
║        Sample Collection & Target State Management        ║
╚═══════════════════════════════════════════════════════════╝

Features:
- Real-time target position and velocity tracking
- Sample history management
- Velocity calculation and smoothing
- Grounded state detection
- Target validation
]]

local MovementTracker = {}
MovementTracker.__index = MovementTracker

function MovementTracker.new(config)
    local self = setmetatable({}, MovementTracker)
    
    self.config = config or {}
    self.sampleHistorySize = self.config.SampleHistorySize or 10
    
    -- Target tracking
    self.currentTarget = nil
    self.targetCharacter = nil
    self.targetRootPart = nil
    self.targetHumanoid = nil
    
    -- Sample data
    self.sampleHistory = {}
    self.lastPosition = nil
    self.lastVelocity = Vector3.new(0, 0, 0)
    self.lastUpdateTime = 0
    
    -- State
    self.isGrounded = true
    self.isValid = false
    
    return self
end

-- ═══════════════════════════════════════════════════════════
-- TARGET MANAGEMENT
-- ═══════════════════════════════════════════════════════════

function MovementTracker:setTarget(player)
    if not player or not player:IsA("Player") then
        self:clearTarget()
        return false
    end
    
    self.currentTarget = player
    self.targetCharacter = player.Character
    
    if not self.targetCharacter then
        self:clearTarget()
        return false
    end
    
    -- Find root part
    self.targetRootPart = self.targetCharacter:FindFirstChild("HumanoidRootPart")
    if not self.targetRootPart then
        self.targetRootPart = self.targetCharacter:FindFirstChild("PrimaryPart")
    end
    
    -- Find humanoid
    self.targetHumanoid = self.targetCharacter:FindFirstChild("Humanoid")
    
    -- Validate
    self.isValid = self.targetRootPart ~= nil
    
    -- Reset tracking data
    if self.isValid then
        self:reset()
    end
    
    return self.isValid
end

function MovementTracker:clearTarget()
    self.currentTarget = nil
    self.targetCharacter = nil
    self.targetRootPart = nil
    self.targetHumanoid = nil
    self.isValid = false
    self:reset()
end

function MovementTracker:validateTarget()
    if not self.currentTarget then
        self.isValid = false
        return false
    end
    
    -- Check if player still exists
    if not self.currentTarget.Parent then
        self:clearTarget()
        return false
    end
    
    -- Check if character exists
    if not self.targetCharacter or not self.targetCharacter.Parent then
        self:clearTarget()
        return false
    end
    
    -- Check if root part exists
    if not self.targetRootPart or not self.targetRootPart.Parent then
        self:clearTarget()
        return false
    end
    
    -- Check if humanoid is alive
    if self.targetHumanoid then
        if self.targetHumanoid.Health <= 0 then
            self:clearTarget()
            return false
        end
    end
    
    self.isValid = true
    return true
end

-- ═══════════════════════════════════════════════════════════
-- SAMPLE COLLECTION
-- ═══════════════════════════════════════════════════════════

function MovementTracker:update(currentTime)
    if not self:validateTarget() then
        return false
    end
    
    -- Get current position
    local position = self.targetRootPart.Position
    local velocity = self:_calculateVelocity(position, currentTime)
    
    -- Update grounded state
    self:_updateGroundedState()
    
    -- Store sample
    local sample = {
        position = position,
        velocity = velocity,
        time = currentTime,
        isGrounded = self.isGrounded
    }
    
    table.insert(self.sampleHistory, sample)
    
    -- Maintain history size
    if #self.sampleHistory > self.sampleHistorySize then
        table.remove(self.sampleHistory, 1)
    end
    
    -- Update state
    self.lastPosition = position
    self.lastVelocity = velocity
    self.lastUpdateTime = currentTime
    
    return true
end

function MovementTracker:_calculateVelocity(currentPosition, currentTime)
    if not self.lastPosition then
        return Vector3.new(0, 0, 0)
    end
    
    local dt = currentTime - self.lastUpdateTime
    
    if dt <= 0 or dt > 1 then  -- Sanity check
        return self.lastVelocity
    end
    
    -- Calculate instantaneous velocity
    local displacement = currentPosition - self.lastPosition
    local instantVelocity = displacement / dt
    
    -- Smooth with previous velocity (simple low-pass filter)
    local alpha = 0.7  -- Smoothing factor
    local smoothedVelocity = instantVelocity * alpha + self.lastVelocity * (1 - alpha)
    
    return smoothedVelocity
end

function MovementTracker:_updateGroundedState()
    if not self.targetHumanoid then
        self.isGrounded = true  -- Assume grounded if no humanoid
        return
    end
    
    local state = self.targetHumanoid:GetState()
    
    -- Check humanoid state
    local groundedStates = {
        [Enum.HumanoidStateType.Running] = true,
        [Enum.HumanoidStateType.RunningNoPhysics] = true,
        [Enum.HumanoidStateType.Landed] = true,
        [Enum.HumanoidStateType.GettingUp] = true,
        [Enum.HumanoidStateType.Climbing] = true,
        [Enum.HumanoidStateType.Seated] = true,
    }
    
    self.isGrounded = groundedStates[state] == true
end

-- ═══════════════════════════════════════════════════════════
-- QUERY METHODS
-- ═══════════════════════════════════════════════════════════

function MovementTracker:getPosition()
    return self.lastPosition
end

function MovementTracker:getVelocity()
    return self.lastVelocity
end

function MovementTracker:isTargetGrounded()
    return self.isGrounded
end

function MovementTracker:getTarget()
    return self.currentTarget
end

function MovementTracker:getTargetRootPart()
    return self.targetRootPart
end

function MovementTracker:isTargetValid()
    return self.isValid
end

function MovementTracker:getSampleHistory()
    return self.sampleHistory
end

function MovementTracker:getLatestSample()
    if #self.sampleHistory == 0 then return nil end
    return self.sampleHistory[#self.sampleHistory]
end

-- ═══════════════════════════════════════════════════════════
-- STATISTICS
-- ═══════════════════════════════════════════════════════════

function MovementTracker:getAverageVelocity()
    if #self.sampleHistory < 2 then
        return Vector3.new(0, 0, 0)
    end
    
    local sumVel = Vector3.new(0, 0, 0)
    for _, sample in ipairs(self.sampleHistory) do
        sumVel = sumVel + sample.velocity
    end
    
    return sumVel / #self.sampleHistory
end

function MovementTracker:getSpeed()
    return self.lastVelocity.Magnitude
end

function MovementTracker:getAverageSpeed()
    local avgVel = self:getAverageVelocity()
    return avgVel.Magnitude
end

-- ═══════════════════════════════════════════════════════════
-- RESET
-- ═══════════════════════════════════════════════════════════

function MovementTracker:reset()
    self.sampleHistory = {}
    self.lastPosition = nil
    self.lastVelocity = Vector3.new(0, 0, 0)
    self.lastUpdateTime = 0
    self.isGrounded = true
end

-- ═══════════════════════════════════════════════════════════
-- DEBUG INFO
-- ═══════════════════════════════════════════════════════════

function MovementTracker:getDebugInfo()
    local targetName = "None"
    if self.currentTarget then
        targetName = self.currentTarget.Name
    end
    
    return {
        target = targetName,
        isValid = self.isValid,
        isGrounded = self.isGrounded,
        position = self.lastPosition,
        velocity = self.lastVelocity,
        speed = string.format("%.2f studs/s", self:getSpeed()),
        sampleCount = #self.sampleHistory
    }
end

return MovementTracker
