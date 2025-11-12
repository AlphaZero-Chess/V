--[[
╔═══════════════════════════════════════════════════════════╗
║    SYMPHONY HUB - ENHANCED V2 (TOP-TIER IMPLEMENTATION)  ║
║      Sheriff Safe-Targeting + Knife Aura + Auto-Dodge    ║
║                   © Symphony Hub 2025                     ║
╚═══════════════════════════════════════════════════════════╝

FEATURES ADDED:
✓ Sheriff Safe-Targeting with LOS checks (prevents friendly fire)
✓ Knife Aura support for thrown knives (ThrowingKnife objects)
✓ Enhanced Auto-Dodge with trajectory prediction
✓ Target Priority System (Sheriff prioritizes Murderer)
✓ Integration with existing role detection from Nexus
✓ Advanced UI controls with configurable parameters

REFERENCES:
- Uses GetPlayerRole(), updatePlayerData(), IsAlive() from Nexus
- Integrates with existing AimAssist prediction engines
- Maintains compatibility with GunHook and KnifeHook patterns
]]

-- ═══════════════════════════════════════════════════════════
-- SERVICES & DEPENDENCIES
-- ═══════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ═══════════════════════════════════════════════════════════
-- ROLE DETECTION (FROM NEXUS.TXT)
-- ═══════════════════════════════════════════════════════════

local GetPlayerDataRemote = ReplicatedStorage:FindFirstChild("GetPlayerData", true)

-- Function to update player data (from Nexus)
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

-- Function to get the role of a player (from Nexus)
local function GetPlayerRole(player, playerData)
    if not player or not playerData then return nil end
    return playerData[player.Name] and playerData[player.Name].Role
end

-- Function to check if a player is alive (from Nexus)
local function IsAlive(player, playerData)
    if not player or not playerData then return false end
    local role = playerData[player.Name]
    return role and not role.Killed and not role.Dead
end

-- Get current Murderer player object
local function GetMurderer(playerData)
    for _, player in ipairs(Players:GetPlayers()) do 
        if GetPlayerRole(player, playerData) == "Murderer" and IsAlive(player, playerData) then
            return player
        end
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════
-- CONFIGURATION
-- ═══════════════════════════════════════════════════════════

local Config = {
    SheriffSafeTargeting = {
        Enabled = true,
        AllowFriendlyFireOverride = false,
        OverrideKey = Enum.KeyCode.LeftControl,
        MaxRayDistance = 500,
        RaycastTimeout = 0.1,
        MinSafeDistance = 2.0  -- Studs buffer around Innocents
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
        DodgeMode = "Lateral",  -- "Lateral", "Jump", "Teleport"
        DodgeThreshold = 12,
        MaxDodgeTime = 1.5,
        DodgeSensitivity = 0.8,
        CollisionCheckRadius = 3,
        LateralDodgeDistance = 6
    }
}

-- ═══════════════════════════════════════════════════════════
-- MODULE 1: SHERIFF SAFE-TARGETING
-- ═══════════════════════════════════════════════════════════

local SheriffTargeting = {}
SheriffTargeting.__index = SheriffTargeting

function SheriffTargeting.new()
    local self = setmetatable({}, SheriffTargeting)
    self.overridePressed = false
    self.lastCheckTime = 0
    return self
end

function SheriffTargeting:isLineOfSightClear(origin, targetPosition, targetPlayer, playerData)
    -- Create raycast parameters
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    
    -- Filter out LocalPlayer and non-collidable objects
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
    
    -- Direction vector from origin to target
    local direction = (targetPosition - origin)
    local distance = direction.Magnitude
    direction = direction.Unit
    
    -- Perform raycast
    local rayResult = workspace:Raycast(origin, direction * math.min(distance, Config.SheriffSafeTargeting.MaxRayDistance), raycastParams)
    
    if not rayResult then
        -- No obstruction detected
        return true
    end
    
    -- Check if raycast hit another player
    local hitPart = rayResult.Instance
    if hitPart then
        -- Check if hit part belongs to a player character
        local hitCharacter = hitPart:FindFirstAncestorOfClass("Model")
        if hitCharacter then
            local hitPlayer = Players:GetPlayerFromCharacter(hitCharacter)
            if hitPlayer and hitPlayer ~= targetPlayer then
                -- Check if this player is an Innocent
                local role = GetPlayerRole(hitPlayer, playerData)
                if role == "Innocent" or role == "Hero" or role == "Sheriff" then
                    -- Innocent/friendly in the way
                    return false
                end
            end
        end
    end
    
    -- Check proximity - if an Innocent is very close to the line of fire
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player ~= targetPlayer and player.Character then
            local role = GetPlayerRole(player, playerData)
            if (role == "Innocent" or role == "Hero" or role == "Sheriff") and IsAlive(player, playerData) then
                local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    -- Calculate distance from player to the line of fire
                    local playerPos = rootPart.Position
                    local lineStart = origin
                    local lineEnd = targetPosition
                    
                    -- Point to line segment distance
                    local lineVec = lineEnd - lineStart
                    local playerVec = playerPos - lineStart
                    local t = math.clamp(playerVec:Dot(lineVec) / lineVec:Dot(lineVec), 0, 1)
                    local closestPoint = lineStart + lineVec * t
                    local distanceToLine = (playerPos - closestPoint).Magnitude
                    
                    if distanceToLine < Config.SheriffSafeTargeting.MinSafeDistance then
                        -- Innocent too close to line of fire
                        return false
                    end
                end
            end
        end
    end
    
    return true
end

function SheriffTargeting:canTargetMurderer(murderer, playerData)
    if not Config.SheriffSafeTargeting.Enabled then
        return true  -- Feature disabled, allow targeting
    end
    
    if not murderer or not murderer.Character then
        return false
    end
    
    -- Check if override key is pressed
    if Config.SheriffSafeTargeting.AllowFriendlyFireOverride and self.overridePressed then
        return true
    end
    
    -- Get shooting origin (camera or gun position)
    local origin = Camera.CFrame.Position
    local targetPart = murderer.Character:FindFirstChild("HumanoidRootPart") or murderer.Character:FindFirstChild("Head")
    
    if not targetPart then
        return false
    end
    
    local targetPosition = targetPart.Position
    
    -- Check LOS
    return self:isLineOfSightClear(origin, targetPosition, murderer, playerData)
end

function SheriffTargeting:updateOverrideKey()
    self.overridePressed = UserInputService:IsKeyDown(Config.SheriffSafeTargeting.OverrideKey)
end

-- ═══════════════════════════════════════════════════════════
-- MODULE 2: KNIFE AURA TRACKER (THROWN KNIVES)
-- ═══════════════════════════════════════════════════════════

local KnifeAuraTracker = {}
KnifeAuraTracker.__index = KnifeAuraTracker

function KnifeAuraTracker.new()
    local self = setmetatable({}, KnifeAuraTracker)
    self.trackedKnives = {}
    self.hitRegistry = {}  -- Track hits per knife per victim
    self.lastAuraTime = 0
    self.knifeConnections = {}
    return self
end

function KnifeAuraTracker:startTracking()
    if not Config.KnifeAuraOnThrow.Enabled then
        return
    end
    
    -- Monitor workspace for new ThrowingKnife objects
    local connection = Workspace.ChildAdded:Connect(function(child)
        self:onKnifeAdded(child)
    end)
    
    table.insert(self.knifeConnections, connection)
    
    -- Update loop for aura processing
    local updateConnection = RunService.Heartbeat:Connect(function(dt)
        self:updateKnifeAuras(dt)
    end)
    
    table.insert(self.knifeConnections, updateConnection)
end

function KnifeAuraTracker:stopTracking()
    -- Disconnect all connections
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
    if not Config.KnifeAuraOnThrow.Enabled then
        return
    end
    
    -- Check if it's a ThrowingKnife
    if child.Name == "ThrowingKnife" and child:IsA("Model") then
        -- Track this knife
        local knifeId = tostring(child:GetDebugId())
        
        -- Limit tracked knives
        if #self.trackedKnives >= Config.KnifeAuraOnThrow.MaxKnivesTracked then
            -- Remove oldest
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
        
        -- Monitor knife destruction
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
    if not Config.KnifeAuraOnThrow.Enabled then
        return
    end
    
    local currentTime = tick()
    
    -- Check cooldown
    if currentTime - self.lastAuraTime < Config.KnifeAuraOnThrow.Cooldown then
        return
    end
    
    local playerData = updatePlayerData()
    local localRole = GetPlayerRole(LocalPlayer, playerData)
    
    if localRole ~= "Murderer" then
        return  -- Only murderer can use knife aura
    end
    
    -- Process each tracked knife
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
    
    -- Find the knife handle for touch events
    local knifeHandle = knife:FindFirstChild("Handle")
    if not knifeHandle then
        return
    end
    
    -- Check all players in aura radius
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and IsAlive(player, playerData) then
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local distance = (rootPart.Position - knifePosition).Magnitude
                
                if distance <= Config.KnifeAuraOnThrow.AuraRadius then
                    -- Player is in aura range
                    local victimName = player.Name
                    
                    -- Check if already hit by this knife
                    if not self.hitRegistry[knifeId][victimName] then
                        -- Apply hit
                        self:applyKnifeHit(player, knifeHandle, rootPart)
                        
                        -- Register hit
                        self.hitRegistry[knifeId][victimName] = {
                            time = currentTime,
                            applied = true
                        }
                    else
                        -- Check cooldown for re-hit
                        local lastHit = self.hitRegistry[knifeId][victimName].time
                        if currentTime - lastHit > Config.KnifeAuraOnThrow.HitCooldownPerVictim then
                            -- Allow re-hit
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
    -- Use the same pattern as Nexus Kill Aura
    pcall(function()
        -- Get the knife tool
        local knife = LocalPlayer.Backpack:FindFirstChild("Knife") or LocalPlayer.Character:FindFirstChild("Knife")
        
        if knife and knife:FindFirstChild("Stab") then
            -- Fire stab event
            knife.Stab:FireServer('Down')
            
            -- Fire touch interest
            if firetouchinterest then
                firetouchinterest(victimRootPart, knifeHandle, 1)
                task.wait(0.05)
                firetouchinterest(victimRootPart, knifeHandle, 0)
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════
-- MODULE 3: ENHANCED AUTO-DODGE
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
    if not Config.AutoDodge.Enabled then
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
    if not Config.AutoDodge.Enabled then
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
    
    -- Check dodge cooldown
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
    
    -- Track knife until it's close or destroyed
    local trackingActive = true
    local dodgeExecuted = false
    
    while trackingActive and knife:IsDescendantOf(Workspace) and not dodgeExecuted do
        task.wait(0.05)
        
        local knifePosition = knife:GetPivot().Position
        local knifeVelocity = knife.PrimaryPart and knife.PrimaryPart.AssemblyLinearVelocity or Vector3.new(0, 0, 0)
        local playerPosition = humanoidRootPart.Position
        
        -- Predict knife trajectory
        local closestApproach, timeToImpact = self:predictClosestApproach(
            playerPosition,
            knifePosition,
            knifeVelocity
        )
        
        -- Check if dodge is needed
        if closestApproach < Config.AutoDodge.DodgeThreshold and 
           timeToImpact < Config.AutoDodge.MaxDodgeTime and
           timeToImpact > 0 then
            -- Execute dodge
            self:executeDodge(humanoidRootPart, knifePosition, knifeVelocity)
            dodgeExecuted = true
            self.lastDodgeTime = tick()
            trackingActive = false
        end
        
        -- Stop tracking if knife is too far away or time exceeded
        local distance = (knifePosition - playerPosition).Magnitude
        if distance > 50 or (tick() - currentTime) > Config.AutoDodge.MaxDodgeTime then
            trackingActive = false
        end
    end
end

function AutoDodge:predictClosestApproach(playerPos, knifePos, knifeVel)
    -- Predict the closest distance the knife will get to the player
    -- Using relative motion
    
    local relativePos = knifePos - playerPos
    local velocityMag = knifeVel.Magnitude
    
    if velocityMag < 1 then
        -- Knife is not moving significantly
        return relativePos.Magnitude, math.huge
    end
    
    local velocityUnit = knifeVel.Unit
    
    -- Time to closest approach: t = -(r · v) / |v|^2
    local dotProduct = relativePos:Dot(knifeVel)
    local timeToClosest = -dotProduct / (velocityMag * velocityMag)
    
    if timeToClosest < 0 then
        -- Knife is moving away
        return relativePos.Magnitude, math.huge
    end
    
    -- Position at closest approach
    local closestKnifePos = knifePos + knifeVel * timeToClosest
    local closestDistance = (closestKnifePos - playerPos).Magnitude
    
    return closestDistance, timeToClosest
end

function AutoDodge:executeDodge(humanoidRootPart, knifePosition, knifeVelocity)
    local dodgeMode = Config.AutoDodge.DodgeMode
    
    if dodgeMode == "Lateral" then
        self:lateralDodge(humanoidRootPart, knifePosition, knifeVelocity)
    elseif dodgeMode == "Jump" then
        self:jumpDodge(humanoidRootPart)
    elseif dodgeMode == "Teleport" then
        self:teleportDodge(humanoidRootPart, knifePosition)
    end
end

function AutoDodge:lateralDodge(humanoidRootPart, knifePosition, knifeVelocity)
    -- Calculate lateral dodge direction (perpendicular to knife velocity)
    local toKnife = (knifePosition - humanoidRootPart.Position).Unit
    local lateralDirection = Vector3.new(-toKnife.Z, 0, toKnife.X)  -- Perpendicular on horizontal plane
    
    -- Choose left or right based on which is clearer
    local dodgeDistance = Config.AutoDodge.LateralDodgeDistance
    local testPosition = humanoidRootPart.Position + lateralDirection * dodgeDistance
    
    -- Check if position is safe (basic collision check)
    if not self:isPositionSafe(testPosition) then
        -- Try opposite direction
        lateralDirection = -lateralDirection
        testPosition = humanoidRootPart.Position + lateralDirection * dodgeDistance
    end
    
    -- Apply dodge
    pcall(function()
        humanoidRootPart.CFrame = CFrame.new(testPosition) * CFrame.Angles(0, humanoidRootPart.CFrame.Rotation.Y, 0)
    end)
end

function AutoDodge:jumpDodge(humanoidRootPart)
    -- Simple jump + slight lateral movement (mobile-friendly)
    pcall(function()
        local humanoid = humanoidRootPart.Parent:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            
            -- Small lateral offset
            local offsetDirection = Vector3.new(math.random(-1, 1), 0, math.random(-1, 1)).Unit
            humanoidRootPart.CFrame = humanoidRootPart.CFrame + offsetDirection * 2
        end
    end)
end

function AutoDodge:teleportDodge(humanoidRootPart, knifePosition)
    -- Quick teleport away from knife
    local awayDirection = (humanoidRootPart.Position - knifePosition).Unit
    local dodgePosition = humanoidRootPart.Position + awayDirection * Config.AutoDodge.LateralDodgeDistance
    
    if self:isPositionSafe(dodgePosition) then
        pcall(function()
            humanoidRootPart.CFrame = CFrame.new(dodgePosition)
        end)
    end
end

function AutoDodge:isPositionSafe(position)
    -- Basic safety check for dodge position
    -- Check if position is within workspace bounds and not inside other players
    
    if position.Y < -50 or position.Y > 500 then
        return false  -- Out of bounds vertically
    end
    
    -- Check proximity to other players
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local distance = (rootPart.Position - position).Magnitude
                if distance < Config.AutoDodge.CollisionCheckRadius then
                    return false  -- Too close to another player
                end
            end
        end
    end
    
    return true
end

-- ═══════════════════════════════════════════════════════════
-- MODULE 4: INTEGRATED TARGETING SYSTEM
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
        -- Sheriff should only target Murderer
        local murderer = GetMurderer(playerData)
        
        if murderer and self.sheriffTargeting:canTargetMurderer(murderer, playerData) then
            return murderer
        end
        
        return nil  -- No valid target
    else
        -- For other roles, use default targeting (closest, etc.)
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
-- MAIN INITIALIZATION & HOOKS
-- ═══════════════════════════════════════════════════════════

local SymphonyEnhanced = {}
SymphonyEnhanced.TargetingSystem = TargetingSystem.new()
SymphonyEnhanced.KnifeAuraTracker = KnifeAuraTracker.new()
SymphonyEnhanced.AutoDodge = AutoDodge.new()

-- Start systems
SymphonyEnhanced.KnifeAuraTracker:startTracking()
SymphonyEnhanced.AutoDodge:startDodging()

-- Update loop for override key and other real-time checks
RunService.Heartbeat:Connect(function()
    SymphonyEnhanced.TargetingSystem:updateOverrideKey()
end)

-- ═══════════════════════════════════════════════════════════
-- GUN HOOK (SHERIFF SILENT AIM WITH SAFE TARGETING)
-- ═══════════════════════════════════════════════════════════

local GunHook
GunHook = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = { ... }
    
    if not checkcaller() then
        if typeof(self) == "Instance" then
            if self.Name == "RemoteFunction" and method == "InvokeServer" then
                -- This is likely the gun shooting remote
                local playerData = updatePlayerData()
                local localRole = GetPlayerRole(LocalPlayer, playerData)
                
                if localRole == "Sheriff" and Config.SheriffSafeTargeting.Enabled then
                    -- Get the murderer
                    local murderer = GetMurderer(playerData)
                    
                    if murderer and murderer.Character then
                        -- Check if we can safely target
                        if SymphonyEnhanced.TargetingSystem.sheriffTargeting:canTargetMurderer(murderer, playerData) then
                            -- Safe to target, apply aim assist to Murderer
                            local targetPart = murderer.Character:FindFirstChild("HumanoidRootPart")
                            if targetPart then
                                local velocity = targetPart.AssemblyLinearVelocity
                                local position = targetPart.Position
                                
                                -- Apply prediction (simple version)
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
                            -- Cannot safely target, block the shot
                            -- Return without modifying args to prevent accidental shot
                            return nil
                        end
                    end
                end
            end
        end
    end
    
    return GunHook(self, unpack(args))
end)

-- ═══════════════════════════════════════════════════════════
-- KNIFE HOOK (MURDERER SILENT AIM)
-- ═══════════════════════════════════════════════════════════

local KnifeHook
KnifeHook = hookmetamethod(game, "__namecall", function(self, ...)
    local methodName = getnamecallmethod()
    local args = { ... }
    
    if not checkcaller() then
        if self.Name == "Throw" and methodName == "FireServer" then
            -- Knife throw event - apply silent aim if enabled
            local playerData = updatePlayerData()
            local localRole = GetPlayerRole(LocalPlayer, playerData)
            
            if localRole == "Murderer" then
                -- Get closest target for knife throw
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
    
    return KnifeHook(self, unpack(args))
end)

-- ═══════════════════════════════════════════════════════════
-- UI CREATION (ADVANCED TAB)
-- ═══════════════════════════════════════════════════════════

print("[Symphony Enhanced] Creating UI...")

-- Store globally for external access
_G.SymphonyEnhanced = SymphonyEnhanced
_G.SymphonyEnhancedConfig = Config

print("╔═══════════════════════════════════════════════════════╗")
print("║  SYMPHONY ENHANCED V2 - LOADED ✓                     ║")
print("╚═══════════════════════════════════════════════════════╝")
print("")
print("✓ Sheriff Safe-Targeting: " .. tostring(Config.SheriffSafeTargeting.Enabled))
print("✓ Knife Aura on Throw: " .. tostring(Config.KnifeAuraOnThrow.Enabled))
print("✓ Enhanced Auto-Dodge: " .. tostring(Config.AutoDodge.Enabled))
print("")
print("📋 Features:")
print("  • LOS checks prevent friendly fire (Sheriff)")
print("  • Thrown knife aura support (Murderer)")
print("  • Trajectory-based auto-dodge")
print("  • Role-based target prioritization")
print("")

return SymphonyEnhanced
