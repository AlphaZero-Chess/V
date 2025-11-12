--[[
╔═══════════════════════════════════════════════════════════╗
║                  AIM SOLVER MODULE                          ║
║      Converts Predictions to Camera/Aim Adjustments        ║
╚═══════════════════════════════════════════════════════════╝

Features:
- World-to-screen conversion
- Camera angle calculation
- Aim smoothing with configurable lerp
- FOV constraints
- Dead zone support
- Target lead calculation
]]

local AimSolver = {}
AimSolver.__index = AimSolver

function AimSolver.new(config, camera)
    local self = setmetatable({}, AimSolver)
    
    self.config = config or {}
    self.camera = camera
    
    -- Smoothing configuration
    self.smoothing = self.config.Smoothing or {}
    self.lerpFactor = self.smoothing.lerp or 0.12
    self.maxAnglePerSec = self.smoothing.maxAnglePerSec or 720  -- degrees/sec
    
    -- FOV constraints
    self.maxFOV = self.config.MaxFOV or 180  -- Maximum FOV in degrees
    self.deadZone = self.config.DeadZone or 1  -- Dead zone in degrees
    
    -- State
    self.lastAimVector = nil
    self.targetInFOV = false
    
    return self
end

-- ═══════════════════════════════════════════════════════════
-- CORE AIM CALCULATION
-- ═══════════════════════════════════════════════════════════

function AimSolver:computeAim(targetPosition, dt)
    if not targetPosition or typeof(targetPosition) ~= "Vector3" then
        return nil
    end
    
    if not self.camera then
        return nil
    end
    
    local cameraPosition = self.camera.CFrame.Position
    local cameraLookVector = self.camera.CFrame.LookVector
    
    -- Calculate direction to target
    local toTarget = (targetPosition - cameraPosition).Unit
    
    -- Check FOV constraints
    local angle = self:_calculateAngle(cameraLookVector, toTarget)
    
    if angle > self.maxFOV then
        self.targetInFOV = false
        return nil  -- Target outside max FOV
    end
    
    self.targetInFOV = true
    
    -- Check dead zone
    if angle < self.deadZone then
        return nil  -- Already on target, no adjustment needed
    end
    
    -- Apply smoothing
    local aimVector = self:_applySmoothing(toTarget, dt)
    
    return aimVector
end

function AimSolver:_calculateAngle(vec1, vec2)
    -- Calculate angle in degrees between two vectors
    local dot = math.clamp(vec1:Dot(vec2), -1, 1)
    local angleRad = math.acos(dot)
    local angleDeg = math.deg(angleRad)
    return angleDeg
end

function AimSolver:_applySmoothing(targetVector, dt)
    if not self.lastAimVector then
        self.lastAimVector = targetVector
        return targetVector
    end
    
    -- Calculate max angle change this frame
    local maxAngleChange = self.maxAnglePerSec * dt
    
    -- Current angle difference
    local currentAngle = self:_calculateAngle(self.lastAimVector, targetVector)
    
    -- Clamp to max angle per frame
    if currentAngle > maxAngleChange then
        local lerpFactor = maxAngleChange / currentAngle
        lerpFactor = math.clamp(lerpFactor, 0, 1)
        targetVector = self.lastAimVector:Lerp(targetVector, lerpFactor)
    else
        -- Use configured lerp factor
        targetVector = self.lastAimVector:Lerp(targetVector, self.lerpFactor)
    end
    
    self.lastAimVector = targetVector
    return targetVector
end

-- ═══════════════════════════════════════════════════════════
-- CAMERA CFRAME CALCULATION
-- ═══════════════════════════════════════════════════════════

function AimSolver:getCameraLookAt(targetPosition)
    if not self.camera or not targetPosition then
        return nil
    end
    
    local cameraPosition = self.camera.CFrame.Position
    return CFrame.lookAt(cameraPosition, targetPosition)
end

function AimSolver:getAimAngles(targetPosition)
    -- Returns pitch and yaw angles to target
    if not self.camera or not targetPosition then
        return nil, nil
    end
    
    local cameraPosition = self.camera.CFrame.Position
    local direction = (targetPosition - cameraPosition).Unit
    
    -- Calculate yaw (horizontal angle)
    local yaw = math.atan2(direction.X, direction.Z)
    
    -- Calculate pitch (vertical angle)
    local horizontalDistance = math.sqrt(direction.X^2 + direction.Z^2)
    local pitch = math.atan2(direction.Y, horizontalDistance)
    
    return math.deg(pitch), math.deg(yaw)
end

-- ═══════════════════════════════════════════════════════════
-- WORLD-TO-SCREEN CONVERSION
-- ═══════════════════════════════════════════════════════════

function AimSolver:worldToScreen(worldPosition)
    if not self.camera or not worldPosition then
        return nil, false
    end
    
    local screenPoint, onScreen = self.camera:WorldToScreenPoint(worldPosition)
    return Vector2.new(screenPoint.X, screenPoint.Y), onScreen
end

function AimSolver:worldToViewport(worldPosition)
    if not self.camera or not worldPosition then
        return nil, false
    end
    
    local viewportPoint, onScreen = self.camera:WorldToViewportPoint(worldPosition)
    return Vector2.new(viewportPoint.X, viewportPoint.Y), onScreen
end

-- ═══════════════════════════════════════════════════════════
-- TARGET LEAD CALCULATION (PROJECTILE WEAPONS)
-- ═══════════════════════════════════════════════════════════

function AimSolver:calculateLead(targetPosition, targetVelocity, projectileSpeed)
    -- Calculate where to aim for projectile weapons
    if not self.camera or not targetPosition or not targetVelocity then
        return targetPosition
    end
    
    if not projectileSpeed or projectileSpeed <= 0 then
        return targetPosition  -- Hitscan weapon
    end
    
    local shooterPosition = self.camera.CFrame.Position
    local distance = (targetPosition - shooterPosition).Magnitude
    
    -- Time for projectile to reach target
    local timeToHit = distance / projectileSpeed
    
    -- Predict target position at time of hit
    local leadPosition = targetPosition + (targetVelocity * timeToHit)
    
    return leadPosition
end

-- ═══════════════════════════════════════════════════════════
-- DISTANCE CALCULATION
-- ═══════════════════════════════════════════════════════════

function AimSolver:getDistanceToTarget(targetPosition)
    if not self.camera or not targetPosition then
        return nil
    end
    
    local cameraPosition = self.camera.CFrame.Position
    return (targetPosition - cameraPosition).Magnitude
end

-- ═══════════════════════════════════════════════════════════
-- CONFIGURATION
-- ═══════════════════════════════════════════════════════════

function AimSolver:setLerpFactor(factor)
    if type(factor) == "number" and factor >= 0 and factor <= 1 then
        self.lerpFactor = factor
    end
end

function AimSolver:setMaxFOV(fov)
    if type(fov) == "number" and fov > 0 and fov <= 180 then
        self.maxFOV = fov
    end
end

function AimSolver:setDeadZone(deadZone)
    if type(deadZone) == "number" and deadZone >= 0 then
        self.deadZone = deadZone
    end
end

function AimSolver:setMaxAnglePerSec(angle)
    if type(angle) == "number" and angle > 0 then
        self.maxAnglePerSec = angle
    end
end

function AimSolver:setCamera(camera)
    self.camera = camera
end

-- ═══════════════════════════════════════════════════════════
-- QUERY METHODS
-- ═══════════════════════════════════════════════════════════

function AimSolver:isTargetInFOV()
    return self.targetInFOV
end

function AimSolver:reset()
    self.lastAimVector = nil
    self.targetInFOV = false
end

-- ═══════════════════════════════════════════════════════════
-- DEBUG INFO
-- ═══════════════════════════════════════════════════════════

function AimSolver:getDebugInfo()
    return {
        lerpFactor = self.lerpFactor,
        maxFOV = string.format("%.1f°", self.maxFOV),
        deadZone = string.format("%.1f°", self.deadZone),
        maxAnglePerSec = string.format("%.1f°/s", self.maxAnglePerSec),
        targetInFOV = self.targetInFOV,
        hasLastAim = self.lastAimVector ~= nil
    }
end

return AimSolver
