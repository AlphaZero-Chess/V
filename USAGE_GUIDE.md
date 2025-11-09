# Symphony Hub - Usage Guide

## 🚀 Quick Start

### Basic Installation

```lua
-- Load the refactored script
local Symphony = loadstring(game:HttpGet("your-url-here"))()

-- That's it! Symphony is now loaded and initialized
```

---

## 📖 Basic Usage

### Player Modifications

#### Walk Speed
```lua
-- Simple API
Symphony.SetWalkSpeed(50)

-- Advanced API
Symphony.Player:setWalkSpeed(50)

-- Check if successful
local success = Symphony.Player:setWalkSpeed(50)
if success then
    print("Walk speed updated!")
end
```

#### Jump Power
```lua
-- Simple API
Symphony.SetJumpPower(100)

-- Advanced API  
Symphony.Player:setJumpPower(100)
```

#### Noclip
```lua
-- Enable noclip
Symphony.EnableNoclip(true)

-- Disable noclip
Symphony.EnableNoclip(false)

-- Advanced usage
Symphony.Player:enableNoclip(true)
```

#### Infinite Jump
```lua
-- Enable infinite jump
Symphony.Player:enableInfiniteJump(true)

-- Disable
Symphony.Player:enableInfiniteJump(false)
```

#### Fly
```lua
-- Enable fly with default speed
Symphony.Player:enableFly(true)

-- Enable fly with custom speed
Symphony.Player:enableFly(true, 10)

-- Disable fly
Symphony.Player:enableFly(false)
```

---

### Visual Features

#### ESP (Player Labels)
```lua
-- Enable ESP for all players
Symphony.EnableESP(true)

-- Disable ESP
Symphony.EnableESP(false)

-- Create ESP for specific player
local targetPlayer = Symphony.Utils.findPlayer("PlayerName")
if targetPlayer then
    Symphony.Visual:createESP(targetPlayer)
end

-- Remove ESP from specific player
Symphony.Visual:removeESP(targetPlayer)
```

---

### Notifications

#### Basic Notification
```lua
-- Simple notification
Symphony.Notify("Hello World!")

-- With custom duration
Symphony.Notify("This message lasts 10 seconds", 10)

-- Advanced API
Symphony.Notifications:notify("Custom Title", "Custom Message", 5)
```

#### Chat Message
```lua
-- Send system chat message
Symphony.Notifications:chatMessage("Hello from Symphony!")

-- With custom color
Symphony.Notifications:chatMessage(
    "Red message", 
    Color3.fromRGB(255, 0, 0)
)
```

---

## 🔧 Advanced Usage

### Configuration Management

#### Setting Configuration
```lua
-- Set a config value
Symphony.Config:set("customSetting", true)
Symphony.Config:set("walkSpeed", 50)
Symphony.Config:set("myData", {key = "value"})
```

#### Getting Configuration
```lua
-- Get a config value
local speed = Symphony.Config:get("walkSpeed")

-- Get with default fallback
local setting = Symphony.Config:get("customSetting", false)
```

#### Reset Configuration
```lua
-- Reset all config to defaults
Symphony.Config:reset()
```

---

### Utility Functions

#### Find Players
```lua
-- Find by partial name
local player = Symphony.Utils.findPlayer("john")
-- Finds "John", "Johnny", etc.

-- Find by display name
local player = Symphony.Utils.findPlayer("display")
```

#### Character Utilities
```lua
-- Get player's primary part (HumanoidRootPart)
local rootPart = Symphony.Utils.getPrimaryPart(player)

-- Teleport player
local success = Symphony.Utils.teleportTo(
    player, 
    CFrame.new(0, 10, 0)
)
```

#### Number Formatting
```lua
-- Format large numbers
local formatted = Symphony.Utils.formatNumber(1500000)
-- Output: "1.5M"

local formatted = Symphony.Utils.formatNumber(1234567, 2)
-- Output: "1.23M"
```

#### Function Throttling
```lua
-- Throttle expensive operations
local throttledFunction = Symphony.Utils.throttle(function()
    print("This only runs once per second")
end, 1.0)

-- Call rapidly - only executes once per second
for i = 1, 100 do
    throttledFunction()
end
```

#### Function Debouncing
```lua
-- Debounce rapid calls
local debouncedUpdate = Symphony.Utils.debounce(function()
    print("This runs after calls stop")
end, 0.5)

-- Multiple rapid calls
debouncedUpdate() -- Canceled
debouncedUpdate() -- Canceled  
debouncedUpdate() -- Only this one runs (after 0.5s)
```

---

### Logging

```lua
-- Access logger
local logger = Symphony.Logger

-- Different log levels
logger:debug("Debug info: %s", "value")
logger:info("Information: %d", 123)
logger:warn("Warning: Something might be wrong")
logger:error("Error: %s", errorMessage)
```

---

### Event Management

#### Manual Connection Management
```lua
-- Access event manager
local events = Symphony.Core.events

-- Connect a custom event
events:connect("MyEvent", game.SomeSignal, function()
    print("Event fired!")
end)

-- Disconnect specific event
events:disconnect("MyEvent")

-- Store task data
events:setTask("MyTask", {data = "value"})
local taskData = events:getTask("MyTask")
events:clearTask("MyTask")
```

---

## 🎯 Practical Examples

### Example 1: Auto-Farm Setup
```lua
-- Setup auto-farm configuration
Symphony.Config:set("farmEnabled", true)
Symphony.Config:set("farmSpeed", 100)

-- Enable necessary features
Symphony.Player:setWalkSpeed(100)
Symphony.Player:enableNoclip(true)
Symphony.EnableESP(true)

-- Notification
Symphony.Notify("Auto-farm setup complete!", 3)
```

### Example 2: PvP Setup
```lua
-- PvP configuration
Symphony.Player:setWalkSpeed(25)
Symphony.Player:setJumpPower(75)
Symphony.EnableESP(true)

-- Notify
Symphony.Notifications:notify(
    "PvP Mode",
    "Combat features enabled!",
    5
)
```

### Example 3: Spectator Mode
```lua
-- Minimal profile
Symphony.Player:setWalkSpeed(30)
Symphony.Player:enableNoclip(true)
Symphony.Player:enableFly(true, 15)
Symphony.EnableESP(true)

Symphony.Notify("Spectator mode activated")
```

### Example 4: Custom ESP for Specific Players
```lua
local targetNames = {"Player1", "Player2", "Player3"}

for _, name in ipairs(targetNames) do
    local player = Symphony.Utils.findPlayer(name)
    if player then
        Symphony.Visual:createESP(player)
        Symphony.Notifications:chatMessage(
            "Tracking: " .. player.Name
        )
    end
end
```

### Example 5: Safe Teleportation
```lua
local function safeTeleport(x, y, z)
    local player = game.Players.LocalPlayer
    local targetCFrame = CFrame.new(x, y, z)
    
    local success = Symphony.Utils.teleportTo(player, targetCFrame)
    
    if success then
        Symphony.Notify("Teleported successfully!")
    else
        Symphony.Logger:warn("Teleport failed")
        Symphony.Notify("Teleport failed - try again")
    end
end

-- Usage
safeTeleport(100, 50, 200)
```

---

## 🔄 Complete Workflow Example

```lua
-- 1. Load Symphony
local Symphony = loadstring(game:HttpGet("url"))()

-- 2. Configure settings
Symphony.Config:set("walkSpeed", 50)
Symphony.Config:set("espEnabled", true)

-- 3. Apply player modifications
Symphony.Player:setWalkSpeed(Symphony.Config:get("walkSpeed"))
Symphony.Player:setJumpPower(100)
Symphony.Player:enableNoclip(true)

-- 4. Enable visuals
if Symphony.Config:get("espEnabled") then
    Symphony.EnableESP(true)
end

-- 5. Setup notifications
Symphony.Notify("Symphony Hub loaded!", 5)

-- 6. Do your tasks...
-- [Your game-specific code here]

-- 7. Cleanup when done
Symphony.Shutdown()
```

---

## ⚠️ Error Handling

### Handling Failed Operations
```lua
-- Check return values
local success = Symphony.Player:setWalkSpeed(50)
if not success then
    Symphony.Logger:warn("Failed to set walk speed")
    -- Fallback logic
end

-- Safe utility calls
local player = Symphony.Utils.findPlayer("unknown")
if not player then
    Symphony.Notify("Player not found!")
    return
end

-- Protected execution
local success, error = pcall(function()
    -- Your risky code here
    Symphony.Player:setWalkSpeed(999999)
end)

if not success then
    Symphony.Logger:error("Operation failed: %s", error)
end
```

---

## 🧹 Cleanup

### Manual Cleanup
```lua
-- Disable all features
Symphony.Player:enableNoclip(false)
Symphony.Player:enableInfiniteJump(false)
Symphony.EnableESP(false)

-- Full shutdown
Symphony.Shutdown()
```

### Automatic Cleanup
```lua
-- Symphony automatically cleans up when player leaves
-- or character resets

-- You can also add custom cleanup
game.Players.LocalPlayer.CharacterAdded:Connect(function()
    -- Re-enable features on respawn
    Symphony.Player:setWalkSpeed(50)
    Symphony.EnableESP(true)
end)
```

---

## 💡 Pro Tips

### Tip 1: Configuration Persistence
```lua
-- Save settings for next run (you'd implement storage)
local function saveConfig()
    local settings = {
        walkSpeed = Symphony.Config:get("walkSpeed"),
        espEnabled = Symphony.Config:get("espEnabled"),
        -- ... other settings
    }
    -- Save to DataStore or file
end

local function loadConfig(settings)
    for key, value in pairs(settings) do
        Symphony.Config:set(key, value)
    end
end
```

### Tip 2: Chaining Operations
```lua
-- Chain multiple operations
local function setupCharacter()
    Symphony.Player:setWalkSpeed(50)
    Symphony.Player:setJumpPower(75)
    Symphony.Player:enableNoclip(true)
    Symphony.EnableESP(true)
    Symphony.Notify("Character setup complete!")
end

setupCharacter()
```

### Tip 3: Conditional Features
```lua
-- Enable features based on conditions
local isPremium = true -- Your premium check

if isPremium then
    Symphony.Player:setWalkSpeed(100)
    Symphony.Notify("Premium features enabled!")
else
    Symphony.Player:setWalkSpeed(50)
    Symphony.Notify("Standard features enabled")
end
```

### Tip 4: Performance Monitoring
```lua
-- Monitor operations
local startTime = tick()
Symphony.Player:setWalkSpeed(50)
local elapsed = tick() - startTime

Symphony.Logger:debug("Operation took %.4f seconds", elapsed)
```

---

## 🐛 Debugging

### Enable Debug Logging
```lua
-- Set logger to debug level for verbose output
Symphony.Logger.minLevel = 1 -- DEBUG level

-- Now all debug messages will show
Symphony.Player:setWalkSpeed(50)
-- Output: [Symphony][DEBUG] Walk speed set to 50
```

### Check System State
```lua
-- Check if features are enabled
local isNoclipEnabled = Symphony.Config:get("noclipEnabled")
local isEspEnabled = Symphony.Config:get("espEnabled")

print("Noclip:", isNoclipEnabled)
print("ESP:", isEspEnabled)
```

### Monitor Connections
```lua
-- Check active connections
for name, connection in pairs(Symphony.Core.events._connections) do
    print("Active connection:", name)
end
```

---

## 📞 Getting Help

If something doesn't work:

1. **Check the logs**: Enable debug logging
2. **Verify character exists**: Some functions need character loaded
3. **Check return values**: Functions return success status
4. **Review error messages**: Logger provides detailed errors
5. **Test in isolation**: Try one feature at a time

---

## 🔗 Integration with Other Scripts

```lua
-- Symphony plays nice with other scripts
local Symphony = loadstring(game:HttpGet("url"))()
local OtherScript = loadstring(game:HttpGet("other-url"))()

-- Use both together
Symphony.Player:setWalkSpeed(50)
OtherScript.DoSomething()

-- Share configuration
local speed = Symphony.Config:get("walkSpeed")
OtherScript.SetSpeed(speed)
```

---

## 📊 Performance Tips

1. **Use throttling** for rapid operations
2. **Disconnect unused events** when features disabled
3. **Use simple API** for one-off operations
4. **Use advanced API** when you need control
5. **Monitor memory** with cleanup

---

## ✅ Checklist for New Users

- [ ] Load Symphony
- [ ] Test basic features (walk speed, jump)
- [ ] Try visual features (ESP)
- [ ] Experiment with utilities
- [ ] Configure settings
- [ ] Implement error handling
- [ ] Add cleanup on exit
- [ ] Test in your game

---

**Happy coding with Symphony Hub!** 🎵

For architecture details, see `ARCHITECTURE.md`
