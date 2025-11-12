# Symphony Enhanced V2 - Implementation Guide

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Core Modules Explained](#core-modules-explained)
3. [Pseudocode Implementations](#pseudocode-implementations)
4. [Configuration Reference](#configuration-reference)
5. [Integration Points](#integration-points)
6. [API Reference](#api-reference)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                  Symphony Enhanced V2                   │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────┐  ┌────────────────────────────┐ │
│  │  Role Detection  │  │  Targeting System          │ │
│  │  (from Nexus)    │──│  - Sheriff Safe-Targeting  │ │
│  │                  │  │  - Priority Selection      │ │
│  └──────────────────┘  └────────────────────────────┘ │
│           │                        │                    │
│           ▼                        ▼                    │
│  ┌────────────────────────────────────────────────┐   │
│  │              GunHook / KnifeHook               │   │
│  │         (Silent Aim with Safety Checks)        │   │
│  └────────────────────────────────────────────────┘   │
│                                                         │
│  ┌──────────────────┐  ┌────────────────────────────┐ │
│  │  Knife Aura      │  │  Auto-Dodge                │ │
│  │  Tracker         │  │  - Trajectory Prediction   │ │
│  │  - Thrown Knives │  │  - Lateral/Jump/Teleport   │ │
│  └──────────────────┘  └────────────────────────────┘ │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## Core Modules Explained

### Module 1: Sheriff Safe-Targeting

**Purpose**: Prevent Sheriff from accidentally shooting Innocent players when targeting Murderer.

**How It Works**:
1. When Sheriff attempts to fire, intercept the gun remote call
2. Perform raycast from camera/gun to target (Murderer)
3. Check if raycast hits any Innocent players first
4. Additionally check if any Innocent is within 2 studs of bullet path
5. If any Innocent detected, block the shot (return nil)
6. If clear, allow shot with aim assist to Murderer

**Key Components**:
- `isLineOfSightClear()`: Raycast-based obstruction detection
- `canTargetMurderer()`: Overall safety check
- Override mechanism for advanced users

**Safety Layers**:
```
Layer 1: Direct Raycast
  └─> Detects if ray hits Innocent's character model

Layer 2: Proximity Check
  └─> Calculates distance from Innocent to bullet path
  └─> Blocks if < MinSafeDistance (2 studs)

Layer 3: Override Key
  └─> LeftControl held = bypass (optional feature)
```

---

### Module 2: Knife Aura Tracker

**Purpose**: Extend Kill Aura to work with thrown knives (ThrowingKnife projectiles).

**How It Works**:
1. Monitor `workspace.ChildAdded` for new ThrowingKnife models
2. Track each knife with unique ID and position
3. On each update cycle, check distance from knife to all players
4. If player within AuraRadius, apply hit using `firetouchinterest` + `Knife.Stab:FireServer`
5. Maintain hit registry to prevent double-hits per knife per victim

**Key Components**:
- `startTracking()`: Begins monitoring workspace
- `onKnifeAdded()`: Handles new knife detection
- `processKnifeAura()`: Main aura logic per knife
- `applyKnifeHit()`: Executes damage to victim

**Hit Prevention**:
```lua
hitRegistry = {
    [knifeId] = {
        ["VictimName"] = {
            time = tick(),
            applied = true
        }
    }
}
```

**Flow**:
```
ThrowingKnife spawns
  └─> Detected by ChildAdded listener
  └─> Added to trackedKnives array
  └─> Heartbeat loop checks knife position
  └─> For each player in AuraRadius:
      └─> Check hit registry
      └─> If not hit yet:
          └─> Apply damage
          └─> Register hit
      └─> If hit before:
          └─> Check cooldown (0.5s)
          └─> Allow re-hit if cooldown passed
```

---

### Module 3: Enhanced Auto-Dodge

**Purpose**: Predict incoming ThrowingKnife trajectories and dodge automatically.

**How It Works**:
1. Monitor `workspace.ChildAdded` for ThrowingKnife
2. Read knife's `AssemblyLinearVelocity` and current position
3. Calculate closest approach distance and time to impact
4. If closest approach < DodgeThreshold and time < MaxDodgeTime:
   - Execute dodge maneuver
5. Dodge modes:
   - **Lateral**: Move perpendicular to knife path
   - **Jump**: Humanoid jump + small lateral offset (mobile)
   - **Teleport**: Quick CFrame change away from knife

**Physics Calculation**:
```
Given:
  - Player position: P
  - Knife position: K
  - Knife velocity: V

Calculate:
  - Relative position: R = K - P
  - Time to closest: t = -(R · V) / |V|²
  - Closest position: K_closest = K + V * t
  - Closest distance: d = |K_closest - P|

If d < DodgeThreshold and t < MaxDodgeTime:
  └─> Execute dodge
```

**Collision Safety**:
- Check if dodge position is in bounds (Y between -50 and 500)
- Check if other players are within 3 studs of dodge position
- If unsafe, try opposite direction or alternate mode

---

### Module 4: Integrated Targeting System

**Purpose**: Coordinate target selection based on player role.

**How It Works**:
1. Query player data from Nexus role system
2. If LocalPlayer is Sheriff:
   - Only return Murderer as valid target
   - Apply LOS safety checks
3. If LocalPlayer is Murderer:
   - Return closest valid target
4. Update GunHook and KnifeHook to use this system

**Priority Logic**:
```
Sheriff:
  └─> Target = Murderer
  └─> Verify LOS clear
  └─> If blocked, return nil (no target)

Murderer:
  └─> Target = Closest alive player
  └─> No LOS check (kill anyone)

Innocent:
  └─> No targeting (defensive only)
```

---

## Pseudocode Implementations

### Sheriff LOS Check

```pseudocode
FUNCTION isLineOfSightClear(origin, targetPosition, targetPlayer, playerData):
    // Create raycast parameters
    rayParams = CREATE_RAYCAST_PARAMS()
    rayParams.FilterType = BLACKLIST
    rayParams.FilterList = [LocalPlayer.Character]
    
    // Calculate ray direction
    direction = targetPosition - origin
    distance = MAGNITUDE(direction)
    direction = NORMALIZE(direction)
    
    // Perform raycast
    rayResult = workspace.Raycast(origin, direction * distance, rayParams)
    
    IF rayResult == NULL THEN
        RETURN TRUE  // No obstruction
    END IF
    
    // Check if hit player is Innocent
    hitPart = rayResult.Instance
    hitCharacter = FIND_ANCESTOR_MODEL(hitPart)
    hitPlayer = GET_PLAYER_FROM_CHARACTER(hitCharacter)
    
    IF hitPlayer != NULL AND hitPlayer != targetPlayer THEN
        hitRole = GetPlayerRole(hitPlayer, playerData)
        IF hitRole IN ["Innocent", "Hero", "Sheriff"] THEN
            RETURN FALSE  // Innocent in the way
        END IF
    END IF
    
    // Check proximity to line of fire
    FOR EACH player IN Players:
        IF player != LocalPlayer AND player != targetPlayer THEN
            role = GetPlayerRole(player, playerData)
            IF role IN ["Innocent", "Hero", "Sheriff"] AND IsAlive(player) THEN
                rootPart = GET_HUMANOID_ROOT_PART(player)
                
                // Point-to-line-segment distance
                lineVec = targetPosition - origin
                playerVec = rootPart.Position - origin
                t = CLAMP(DOT(playerVec, lineVec) / DOT(lineVec, lineVec), 0, 1)
                closestPoint = origin + lineVec * t
                distanceToLine = MAGNITUDE(rootPart.Position - closestPoint)
                
                IF distanceToLine < MinSafeDistance THEN
                    RETURN FALSE  // Too close to line of fire
                END IF
            END IF
        END IF
    END FOR
    
    RETURN TRUE  // Clear shot
END FUNCTION
```

---

### Knife Aura Processing

```pseudocode
FUNCTION processKnifeAura(knifeData, playerData, currentTime):
    knife = knifeData.instance
    knifePosition = GET_PIVOT_POSITION(knife)
    knifeId = knifeData.id
    
    // Find knife handle
    knifeHandle = FIND_CHILD(knife, "Handle")
    IF knifeHandle == NULL THEN
        RETURN
    END IF
    
    // Check all players
    FOR EACH player IN Players:
        IF player == LocalPlayer THEN
            CONTINUE  // Skip self
        END IF
        
        IF NOT IsAlive(player, playerData) THEN
            CONTINUE  // Skip dead players
        END IF
        
        rootPart = GET_HUMANOID_ROOT_PART(player)
        IF rootPart == NULL THEN
            CONTINUE
        END IF
        
        // Calculate distance to knife
        distance = MAGNITUDE(rootPart.Position - knifePosition)
        
        IF distance <= AuraRadius THEN
            victimName = player.Name
            
            // Check hit registry
            IF NOT hitRegistry[knifeId][victimName] THEN
                // First hit
                applyKnifeHit(player, knifeHandle, rootPart)
                hitRegistry[knifeId][victimName] = {
                    time: currentTime,
                    applied: TRUE
                }
            ELSE
                // Check cooldown for re-hit
                lastHitTime = hitRegistry[knifeId][victimName].time
                IF currentTime - lastHitTime > HitCooldownPerVictim THEN
                    applyKnifeHit(player, knifeHandle, rootPart)
                    hitRegistry[knifeId][victimName].time = currentTime
                END IF
            END IF
        END IF
    END FOR
END FUNCTION

FUNCTION applyKnifeHit(victim, knifeHandle, victimRootPart):
    TRY:
        // Get knife tool
        knife = FIND_KNIFE_TOOL()
        
        IF knife != NULL AND knife.Stab != NULL THEN
            // Fire stab event
            knife.Stab:FireServer('Down')
            
            // Fire touch interest
            IF firetouchinterest EXISTS THEN
                firetouchinterest(victimRootPart, knifeHandle, 1)
                WAIT(0.05)
                firetouchinterest(victimRootPart, knifeHandle, 0)
            END IF
        END IF
    CATCH error:
        // Silently fail to avoid breaking script
        LOG_ERROR(error)
    END TRY
END FUNCTION
```

---

### Auto-Dodge Trajectory Prediction

```pseudocode
FUNCTION predictClosestApproach(playerPos, knifePos, knifeVel):
    // Relative position of knife to player
    relativePos = knifePos - playerPos
    velocityMag = MAGNITUDE(knifeVel)
    
    IF velocityMag < 1 THEN
        // Knife not moving significantly
        RETURN (MAGNITUDE(relativePos), INFINITY)
    END IF
    
    velocityUnit = NORMALIZE(knifeVel)
    
    // Time to closest approach using dot product
    // Formula: t = -(r · v) / |v|²
    dotProduct = DOT(relativePos, knifeVel)
    timeToClosest = -dotProduct / (velocityMag * velocityMag)
    
    IF timeToClosest < 0 THEN
        // Knife is moving away
        RETURN (MAGNITUDE(relativePos), INFINITY)
    END IF
    
    // Position of knife at closest approach
    closestKnifePos = knifePos + knifeVel * timeToClosest
    closestDistance = MAGNITUDE(closestKnifePos - playerPos)
    
    RETURN (closestDistance, timeToClosest)
END FUNCTION

FUNCTION trackAndDodgeKnife(knife):
    currentTime = CURRENT_TIME()
    
    // Check cooldown
    IF currentTime - lastDodgeTime < dodgeCooldown THEN
        RETURN
    END IF
    
    humanoidRootPart = GET_HUMANOID_ROOT_PART(LocalPlayer)
    IF humanoidRootPart == NULL THEN
        RETURN
    END IF
    
    // Track knife until close or destroyed
    trackingActive = TRUE
    dodgeExecuted = FALSE
    
    WHILE trackingActive AND knife.EXISTS AND NOT dodgeExecuted:
        WAIT(0.05)  // Update every 50ms
        
        knifePosition = GET_PIVOT_POSITION(knife)
        knifeVelocity = GET_VELOCITY(knife.PrimaryPart)
        playerPosition = humanoidRootPart.Position
        
        // Predict trajectory
        (closestApproach, timeToImpact) = predictClosestApproach(
            playerPosition,
            knifePosition,
            knifeVelocity
        )
        
        // Check if dodge needed
        IF closestApproach < DodgeThreshold AND
           timeToImpact < MaxDodgeTime AND
           timeToImpact > 0 THEN
            // Execute dodge
            executeDodge(humanoidRootPart, knifePosition, knifeVelocity)
            dodgeExecuted = TRUE
            lastDodgeTime = CURRENT_TIME()
            trackingActive = FALSE
        END IF
        
        // Stop tracking if too far
        distance = MAGNITUDE(knifePosition - playerPosition)
        IF distance > 50 OR (CURRENT_TIME() - currentTime) > MaxDodgeTime THEN
            trackingActive = FALSE
        END IF
    END WHILE
END FUNCTION

FUNCTION lateralDodge(humanoidRootPart, knifePosition, knifeVelocity):
    // Calculate lateral direction (perpendicular to knife velocity)
    toKnife = NORMALIZE(knifePosition - humanoidRootPart.Position)
    lateralDirection = VECTOR3(-toKnife.Z, 0, toKnife.X)  // Perpendicular on XZ plane
    
    // Test dodge position
    dodgeDistance = LateralDodgeDistance
    testPosition = humanoidRootPart.Position + lateralDirection * dodgeDistance
    
    // Check if position is safe
    IF NOT isPositionSafe(testPosition) THEN
        // Try opposite direction
        lateralDirection = -lateralDirection
        testPosition = humanoidRootPart.Position + lateralDirection * dodgeDistance
    END IF
    
    // Apply dodge
    TRY:
        humanoidRootPart.CFrame = CREATE_CFRAME(testPosition, humanoidRootPart.CFrame.Rotation)
    CATCH:
        // Failed to dodge, position may be invalid
    END TRY
END FUNCTION
```

---

## Configuration Reference

### Default Values

```lua
Config = {
    SheriffSafeTargeting = {
        Enabled = true,                    -- Enable/disable feature
        AllowFriendlyFireOverride = false, -- Allow override key
        OverrideKey = Enum.KeyCode.LeftControl,
        MaxRayDistance = 500,              -- Max raycast distance
        RaycastTimeout = 0.1,              -- Max time for raycast
        MinSafeDistance = 2.0              -- Buffer around Innocents (studs)
    },
    
    KnifeAuraOnThrow = {
        Enabled = false,                   -- Disabled by default
        AuraRadius = 10,                   -- Aura radius (studs)
        Cooldown = 0.3,                    -- Global aura cooldown (seconds)
        MaxKnivesTracked = 5,              -- Max simultaneous knives
        HitCooldownPerVictim = 0.5         -- Per-victim hit cooldown (seconds)
    },
    
    AutoDodge = {
        Enabled = false,                   -- Disabled by default
        DodgeMode = "Lateral",             -- "Lateral", "Jump", "Teleport"
        DodgeThreshold = 12,               -- Trigger distance (studs)
        MaxDodgeTime = 1.5,                -- Max prediction time (seconds)
        DodgeSensitivity = 0.8,            -- 0.0 - 1.0
        CollisionCheckRadius = 3,          -- Safety check radius (studs)
        LateralDodgeDistance = 6           -- How far to dodge (studs)
    }
}
```

### Recommended Settings by Playstyle

**Aggressive Sheriff**:
```lua
SheriffSafeTargeting.Enabled = true
SheriffSafeTargeting.AllowFriendlyFireOverride = true
SheriffSafeTargeting.MinSafeDistance = 1.5  -- Tighter tolerance
```

**Defensive Player**:
```lua
AutoDodge.Enabled = true
AutoDodge.DodgeMode = "Lateral"
AutoDodge.DodgeThreshold = 15  -- Earlier dodge
```

**Aggressive Murderer**:
```lua
KnifeAuraOnThrow.Enabled = true
KnifeAuraOnThrow.AuraRadius = 12  -- Larger radius
KnifeAuraOnThrow.Cooldown = 0.2   -- Faster aura ticks
```

---

## Integration Points

### With Nexus Role System

```lua
-- Symphony Enhanced uses these functions from Nexus:
updatePlayerData()       -- Returns playerData table
GetPlayerRole(player, playerData)  -- Returns "Murderer", "Sheriff", "Innocent", "Hero"
IsAlive(player, playerData)        -- Returns boolean

-- Call frequency:
-- - GunHook: Every shot attempt
-- - KnifeAura: Every 0.3s (configurable)
-- - AutoDodge: When knife detected
```

### With Existing Hooks

```lua
-- GunHook (line 758-812 in Nexus)
-- Symphony Enhanced adds:
1. Role check (if Sheriff)
2. LOS safety check (canTargetMurderer)
3. Conditional aim assist (only if safe)

-- KnifeHook (line 827-852 in Nexus)
-- Symphony Enhanced adds:
1. Target selection (getValidTarget)
2. Prediction for throw aim

-- Both hooks maintain backward compatibility
```

### With AimAssist Modules

```lua
-- Symphony Enhanced can optionally integrate with:
-- - PredictionEngine (for better velocity prediction)
-- - LatencyCompensator (for high-ping scenarios)
-- - JumpPredictor (for jumping targets)

-- Example:
local predictedPosition = PredictionEngine:predict(dt, extrapolationTime)
args[2] = predictedPosition  -- Use in GunHook
```

---

## API Reference

### SheriffTargeting

```lua
-- Create instance
local sheriffTargeting = SheriffTargeting.new()

-- Check if can target murderer safely
local canTarget = sheriffTargeting:canTargetMurderer(murderer, playerData)
-- Returns: boolean

-- Update override key state
sheriffTargeting:updateOverrideKey()
-- Updates internal state based on key press

-- Check line of sight
local isClear = sheriffTargeting:isLineOfSightClear(origin, targetPos, targetPlayer, playerData)
-- Returns: boolean
```

### KnifeAuraTracker

```lua
-- Create instance
local knifeTracker = KnifeAuraTracker.new()

-- Start tracking knives
knifeTracker:startTracking()

-- Stop tracking
knifeTracker:stopTracking()

-- Manual knife addition (if needed)
knifeTracker:onKnifeAdded(knifeModel)

-- Access tracked knives
local knives = knifeTracker.trackedKnives
-- Array of {instance, id, spawnTime, lastAuraApplication}

-- Check hit registry
local wasHit = knifeTracker.hitRegistry[knifeId][victimName]
-- Returns: {time, applied} or nil
```

### AutoDodge

```lua
-- Create instance
local autoDodge = AutoDodge.new()

-- Start dodging system
autoDodge:startDodging()

-- Stop dodging
autoDodge:stopDodging()

-- Manual knife tracking (if needed)
autoDodge:trackAndDodgeKnife(knifeModel)

-- Predict trajectory
local closestDist, timeToImpact = autoDodge:predictClosestApproach(playerPos, knifePos, knifeVel)
-- Returns: (number, number)

-- Check if position is safe
local isSafe = autoDodge:isPositionSafe(position)
-- Returns: boolean
```

### TargetingSystem

```lua
-- Create instance
local targeting = TargetingSystem.new()

-- Get valid target based on role
local target = targeting:getValidTarget(playerData)
-- Returns: Player or nil

-- Get closest target (any role)
local closest = targeting:getClosestTarget(playerData)
-- Returns: Player or nil

-- Update override key
targeting:updateOverrideKey()
```

### Global Access

```lua
-- Access from anywhere
local enhanced = _G.SymphonyEnhanced
local config = _G.SymphonyEnhancedConfig

-- Modify config at runtime
config.AutoDodge.DodgeThreshold = 15
config.SheriffSafeTargeting.Enabled = false

-- Access modules
enhanced.TargetingSystem
enhanced.KnifeAuraTracker
enhanced.AutoDodge
```

---

## Performance Optimization Tips

### Reduce Raycast Calls
```lua
-- Cache raycast results for 0.1s
local raycastCache = {}
local cacheTime = 0.1

function cachedRaycast(origin, target)
    local key = tostring(origin) .. tostring(target)
    local cached = raycastCache[key]
    
    if cached and (tick() - cached.time) < cacheTime then
        return cached.result
    end
    
    local result = workspace:Raycast(origin, target, params)
    raycastCache[key] = {result = result, time = tick()}
    return result
end
```

### Limit Update Frequency
```lua
-- Update knife aura every 0.3s instead of every frame
-- Use Heartbeat with delta time accumulation
local accumulatedTime = 0

RunService.Heartbeat:Connect(function(dt)
    accumulatedTime = accumulatedTime + dt
    
    if accumulatedTime >= 0.3 then
        updateKnifeAuras()
        accumulatedTime = 0
    end
end)
```

### Spatial Optimization
```lua
-- Only check players within reasonable distance
local MAX_AURA_CHECK_DISTANCE = 30

for _, player in pairs(Players:GetPlayers()) do
    if (player.Character.HumanoidRootPart.Position - knifePosition).Magnitude < MAX_AURA_CHECK_DISTANCE then
        -- Process aura check
    end
end
```

---

## Security Considerations

### Anti-Detection Measures
1. **Use pcall** for all remote calls
2. **Respect server authority** - never fabricate impossible actions
3. **Natural timing** - add small random delays
4. **Fallback logic** - if detection fails, revert to safe behavior

### Safe Remote Usage
```lua
-- Always use pcall
pcall(function()
    knife.Stab:FireServer('Down')
end)

-- Check if remote exists first
if knife and knife:FindFirstChild("Stab") then
    knife.Stab:FireServer('Down')
end

-- Never call non-existent remotes
local remote = ReplicatedStorage:FindFirstChild("DesiredRemote")
if remote then
    remote:FireServer(args)
end
```

### Rate Limiting
```lua
-- Limit knife aura applications
local GLOBAL_HIT_LIMIT = 10  -- Max 10 hits per second
local hitCount = 0
local lastResetTime = tick()

function applyHitWithLimit(victim)
    if tick() - lastResetTime > 1 then
        hitCount = 0
        lastResetTime = tick()
    end
    
    if hitCount < GLOBAL_HIT_LIMIT then
        applyKnifeHit(victim)
        hitCount = hitCount + 1
    end
end
```

---

## Troubleshooting Common Issues

### Issue: LOS check always returns false
**Solution**: Verify raycast params don't include target player in filter
```lua
rayParams.FilterDescendantsInstances = {LocalPlayer.Character}  -- Not target!
```

### Issue: Knife aura not working
**Solution**: Check if ThrowingKnife has correct structure
```lua
print(knife.Name)  -- Should be "ThrowingKnife"
print(knife.ClassName)  -- Should be "Model"
print(knife:FindFirstChild("Handle"))  -- Should exist
```

### Issue: Dodge too slow
**Solution**: Reduce DodgeThreshold or increase MaxDodgeTime
```lua
Config.AutoDodge.DodgeThreshold = 15  -- Earlier detection
Config.AutoDodge.MaxDodgeTime = 2.0   -- More time to react
```

### Issue: Memory leak from tracked knives
**Solution**: Implement cleanup
```lua
-- Remove old knives
for i = #trackedKnives, 1, -1 do
    if tick() - trackedKnives[i].spawnTime > 10 then
        table.remove(trackedKnives, i)
    end
end
```

---

**Document Version**: 1.0  
**Last Updated**: 2025-01-XX  
**Author**: Symphony Hub Development Team
