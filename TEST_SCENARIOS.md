# Symphony Enhanced V2 - Test Scenarios

## Overview
This document provides scripted test scenarios to validate the three core features of Symphony Enhanced V2.

---

## Test Scenario A: Sheriff Safe-Targeting (Innocent Blocking Path)

### Setup:
- LocalPlayer is **Sheriff**
- Target player is **Murderer**
- Innocent player positioned directly between Sheriff and Murderer

### Test Steps:
1. Enable `SheriffSafeTargeting` in Config
2. Position Sheriff at Point A (e.g., `Vector3.new(0, 5, 0)`)
3. Position Innocent at Point B (e.g., `Vector3.new(0, 5, 10)`) 
4. Position Murderer at Point C (e.g., `Vector3.new(0, 5, 20)`)
5. Attempt to fire gun at Murderer

### Expected Result:
- **LOS Check detects Innocent in path**
- **Shot is BLOCKED** (args not modified, returns nil)
- **No damage to Innocent**
- Console log: `[Symphony Enhanced] Shot blocked - Innocent in line of fire`

### Validation:
```lua
-- Check raycast result
local origin = Camera.CFrame.Position
local targetPos = murderer.Character.HumanoidRootPart.Position
local rayResult = workspace:Raycast(origin, (targetPos - origin), raycastParams)

-- Verify hit is Innocent's character
assert(rayResult ~= nil, "Raycast should detect obstruction")
local hitPlayer = Players:GetPlayerFromCharacter(rayResult.Instance:FindFirstAncestorOfClass("Model"))
assert(hitPlayer.Name == innocentPlayer.Name, "Should detect Innocent in path")
```

---

## Test Scenario B: Sheriff Targeting (Murderer Behind Chasing Innocent)

### Setup:
- LocalPlayer is **Sheriff**
- **Murderer** is chasing **Innocent** (Murderer behind)
- Both moving toward Sheriff

### Test Steps:
1. Enable `SheriffSafeTargeting`
2. Set Innocent velocity toward Sheriff: `Vector3.new(0, 0, -16)` (running speed)
3. Set Murderer velocity toward Sheriff: `Vector3.new(0, 0, -20)` (catching up)
4. Position Innocent at `Vector3.new(0, 5, 15)`
5. Position Murderer at `Vector3.new(0, 5, 18)`
6. Attempt to shoot

### Expected Result:
- **Proximity check detects Innocent within 2 studs of bullet path**
- **Shot is BLOCKED**
- Sheriff must wait for clear shot or manually override

### Validation:
```lua
-- Calculate distance from Innocent to line of fire
local lineStart = origin
local lineEnd = murdererPos
local lineVec = lineEnd - lineStart
local innocentVec = innocentPos - lineStart
local t = math.clamp(innocentVec:Dot(lineVec) / lineVec:Dot(lineVec), 0, 1)
local closestPoint = lineStart + lineVec * t
local distToLine = (innocentPos - closestPoint).Magnitude

assert(distToLine < 2.0, "Innocent should be within MinSafeDistance")
assert(shotBlocked == true, "Shot should be blocked")
```

---

## Test Scenario C: Knife Aura on Thrown Knife

### Setup:
- LocalPlayer is **Murderer**
- Multiple victims (Innocent players) clustered in area
- Murderer throws knife through group

### Test Steps:
1. Enable `KnifeAuraOnThrow`
2. Set `AuraRadius = 10` studs
3. Position 3 Innocents within 10 studs of knife path:
   - Innocent1 at `Vector3.new(5, 5, 20)`
   - Innocent2 at `Vector3.new(8, 5, 20)`
   - Innocent3 at `Vector3.new(5, 5, 23)`
4. Throw knife from `Vector3.new(0, 5, 0)` toward `Vector3.new(10, 5, 30)`
5. Monitor workspace for `ThrowingKnife` object
6. Track hit registry

### Expected Result:
- **ThrowingKnife detected** and added to `trackedKnives` array
- **All 3 Innocents hit exactly once** by knife aura
- **Hit registry** shows entries for each victim
- `firetouchinterest` called for each victim with knife Handle
- **No double-hits** on same victim by same knife

### Validation:
```lua
-- Wait for knife to spawn
local knife = workspace:WaitForChild("ThrowingKnife", 2)
assert(knife ~= nil, "ThrowingKnife should spawn")

-- Check tracking
task.wait(0.5)
local tracked = false
for _, k in pairs(KnifeAuraTracker.trackedKnives) do
    if k.instance == knife then
        tracked = true
        break
    end
end
assert(tracked == true, "Knife should be tracked")

-- Verify hits
task.wait(1)
local knifeId = tostring(knife:GetDebugId())
local hitCount = 0
for victimName, hitData in pairs(KnifeAuraTracker.hitRegistry[knifeId]) do
    hitCount = hitCount + 1
    assert(hitData.applied == true, "Hit should be applied")
end
assert(hitCount == 3, "Should hit exactly 3 victims")
```

---

## Test Scenario D: Auto-Dodge (Incoming ThrowingKnife)

### Setup:
- LocalPlayer is **Innocent** or **Sheriff**
- Murderer throws knife directly at LocalPlayer

### Test Steps:
1. Enable `AutoDodge` with mode = `"Lateral"`
2. Set `DodgeThreshold = 12` studs
3. Position LocalPlayer at `Vector3.new(0, 5, 0)`
4. Spawn ThrowingKnife at `Vector3.new(0, 5, 30)`
5. Set knife velocity toward player: `Vector3.new(0, 0, -40)` (fast throw)
6. Monitor knife approach

### Expected Result:
- **Trajectory prediction** calculates closest approach < 12 studs
- **Dodge executed** before knife reaches player
- **LocalPlayer position changes** by ~6 studs laterally
- **No hit registered** on LocalPlayer

### Validation:
```lua
-- Record initial position
local initialPos = LocalPlayer.Character.HumanoidRootPart.Position

-- Spawn knife
local knife = Instance.new("Model")
knife.Name = "ThrowingKnife"
local knifePart = Instance.new("Part")
knifePart.Name = "Handle"
knifePart.Parent = knife
knife.PrimaryPart = knifePart
knifePart.Position = Vector3.new(0, 5, 30)
knifePart.AssemblyLinearVelocity = Vector3.new(0, 0, -40)
knife.Parent = workspace

-- Wait for dodge
task.wait(0.5)

-- Check if player moved
local finalPos = LocalPlayer.Character.HumanoidRootPart.Position
local displacement = (finalPos - initialPos).Magnitude

assert(displacement > 3, "Player should have dodged (moved >3 studs)")

-- Verify lateral movement (Y should be similar, X or Z changed)
assert(math.abs(finalPos.Y - initialPos.Y) < 1, "Dodge should be lateral (not vertical)")
```

---

## Integration Test: Combined Scenario

### Setup:
- 4 players in game: Sheriff, Murderer, Innocent1, Innocent2
- Test all features in realistic combat situation

### Test Sequence:
1. **Phase 1**: Murderer attempts to kill Innocent1
   - Sheriff aims at Murderer but Innocent2 runs between them
   - **Expected**: Shot blocked by Safe-Targeting
   
2. **Phase 2**: Innocent2 moves away, clear LOS
   - Sheriff fires at Murderer
   - **Expected**: Shot goes through, hits Murderer with prediction

3. **Phase 3**: Murderer throws knife at Sheriff
   - Sheriff auto-dodges
   - **Expected**: Knife misses, Sheriff survives

4. **Phase 4**: Murderer throws knife into group of Innocents
   - Knife Aura activates
   - **Expected**: All Innocents in 10-stud radius are hit once

### Success Criteria:
- All 4 phases pass without errors
- No friendly fire from Sheriff
- Dodge successfully avoids knife
- Aura correctly processes thrown knife hits

---

## Performance Benchmarks

### Target Metrics:
- **LOS Check**: < 2ms per check
- **Knife Tracking**: < 1ms per tracked knife per frame
- **Dodge Prediction**: < 3ms per prediction
- **Memory**: < 10MB additional overhead

### Profiling Commands:
```lua
-- Enable debug mode
Config.Debug = true

-- Profile LOS check
local start = tick()
local result = SheriffTargeting:isLineOfSightClear(origin, target, player, data)
local elapsed = (tick() - start) * 1000
print("LOS Check took:", elapsed, "ms")

-- Profile knife aura update
local start = tick()
KnifeAuraTracker:updateKnifeAuras(0.016)
local elapsed = (tick() - start) * 1000
print("Knife Aura Update took:", elapsed, "ms")
```

---

## Common Issues & Troubleshooting

### Issue 1: Shot not blocked when it should be
**Cause**: Raycast params not filtering correctly
**Fix**: Verify `FilterDescendantsInstances` includes LocalPlayer character

### Issue 2: Knife aura not hitting anyone
**Cause**: ThrowingKnife not being detected
**Fix**: Check if knife model has correct name and structure

### Issue 3: Dodge not triggering
**Cause**: Trajectory prediction failing
**Fix**: Verify knife has `AssemblyLinearVelocity` property and is moving

### Issue 4: Performance degradation
**Cause**: Too many tracked knives or frequent raycasts
**Fix**: Reduce `MaxKnivesTracked` and increase cooldowns

---

## Regression Tests

### After Each Update:
1. Run all test scenarios A-D
2. Verify no console errors
3. Check memory usage hasn't increased >20%
4. Validate config changes persist
5. Test UI toggles function correctly

### Compatibility Checks:
- Test with different Roblox executors
- Verify works on mobile (touch input)
- Check performance on low-end devices
- Test with high ping (>200ms)

---

## Test Automation Script

```lua
-- Auto-test runner (pseudo-code)
local TestRunner = {}

function TestRunner:runAll()
    print("=== Starting Test Suite ===")
    
    local results = {
        scenarioA = self:testScenarioA(),
        scenarioB = self:testScenarioB(),
        scenarioC = self:testScenarioC(),
        scenarioD = self:testScenarioD()
    }
    
    local passed = 0
    local failed = 0
    
    for name, result in pairs(results) do
        if result then
            passed = passed + 1
            print("✓", name, "PASSED")
        else
            failed = failed + 1
            print("✗", name, "FAILED")
        end
    end
    
    print("")
    print("=== Test Results ===")
    print("Passed:", passed)
    print("Failed:", failed)
    print("Total:", passed + failed)
    
    return failed == 0
end

-- Run tests
TestRunner:runAll()
```

---

## Manual Testing Checklist

- [ ] Sheriff Safe-Targeting blocks shots when Innocent in path
- [ ] Sheriff Safe-Targeting allows shots when clear LOS
- [ ] Override key (LeftControl) bypasses Safe-Targeting
- [ ] Knife Aura detects thrown knives
- [ ] Knife Aura hits all players in radius
- [ ] Knife Aura prevents double-hits
- [ ] Auto-Dodge detects incoming knives
- [ ] Auto-Dodge executes lateral dodge
- [ ] Auto-Dodge respects cooldown
- [ ] Config toggles work correctly
- [ ] No errors in console during normal gameplay
- [ ] Performance is acceptable (>30 FPS)

---

**Document Version**: 1.0  
**Last Updated**: 2025-01-XX  
**Author**: Symphony Hub Development Team
