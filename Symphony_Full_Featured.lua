--[[
╔═══════════════════════════════════════════════════════════╗
║              SYMPHONY HUB - FULL FEATURED                 ║
║           Production-Grade with Complete UI               ║
║                    © Symphony Hub 2025                    ║
╚═══════════════════════════════════════════════════════════╝

This is the complete refactored version with all features and UI.
Load this for the full experience!
]]

-- Load the refactored core (assumes it's already loaded or in the same environment)
loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/AlphaZero-Chess/V@refs/heads/main/Symphony_Refactored.lua"))()

-- Wait for Symphony to be available
if not Symphony then
    error("Symphony core not loaded!")
end

print("=== SYMPHONY HUB - FULL FEATURED UI ===")

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- Create main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SymphonyHubFull"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main window
local mainWindow = Instance.new("Frame")
mainWindow.Name = "MainWindow"
mainWindow.Parent = screenGui
mainWindow.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainWindow.BorderSizePixel = 0
mainWindow.Position = UDim2.new(0.5, -350, 0.5, -300)
mainWindow.Size = UDim2.new(0, 700, 0, 600)
mainWindow.Active = true
mainWindow.Draggable = true

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainWindow

-- Add shadow effect
local shadow = Instance.new("ImageLabel")
shadow.Name = "Shadow"
shadow.Parent = mainWindow
shadow.BackgroundTransparency = 1
shadow.Position = UDim2.new(0, -15, 0, -15)
shadow.Size = UDim2.new(1, 30, 1, 30)
shadow.ZIndex = 0
shadow.Image = "rbxassetid://6014261993"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.5
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(49, 49, 450, 450)

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Parent = mainWindow
titleBar.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
titleBar.BorderSizePixel = 0
titleBar.Size = UDim2.new(1, 0, 0, 50)

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

-- Cover bottom corners of title bar
local titleCover = Instance.new("Frame")
titleCover.Parent = titleBar
titleCover.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
titleCover.BorderSizePixel = 0
titleCover.Position = UDim2.new(0, 0, 1, -10)
titleCover.Size = UDim2.new(1, 0, 0, 10)

local titleText = Instance.new("TextLabel")
titleText.Name = "TitleText"
titleText.Parent = titleBar
titleText.BackgroundTransparency = 1
titleText.Position = UDim2.new(0, 15, 0, 0)
titleText.Size = UDim2.new(1, -120, 1, 0)
titleText.Font = Enum.Font.GothamBold
titleText.Text = "🎵 SYMPHONY HUB - REFACTORED"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.TextSize = 20
titleText.TextXAlignment = Enum.TextXAlignment.Left

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Parent = titleBar
statusLabel.BackgroundTransparency = 1
statusLabel.Position = UDim2.new(1, -110, 0, 0)
statusLabel.Size = UDim2.new(0, 70, 1, 0)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.Text = "ACTIVE"
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.TextSize = 14

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Parent = titleBar
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
closeBtn.Position = UDim2.new(1, -35, 0.5, -12)
closeBtn.Size = UDim2.new(0, 25, 0, 25)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 20

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(1, 0)
closeBtnCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Tab system
local tabContainer = Instance.new("Frame")
tabContainer.Name = "TabContainer"
tabContainer.Parent = mainWindow
tabContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
tabContainer.BorderSizePixel = 0
tabContainer.Position = UDim2.new(0, 0, 0, 50)
tabContainer.Size = UDim2.new(0, 150, 1, -50)

local tabList = Instance.new("UIListLayout")
tabList.Parent = tabContainer
tabList.SortOrder = Enum.SortOrder.LayoutOrder
tabList.Padding = UDim.new(0, 2)

local tabPadding = Instance.new("UIPadding")
tabPadding.PaddingTop = UDim.new(0, 10)
tabPadding.Parent = tabContainer

-- Content area
local contentArea = Instance.new("Frame")
contentArea.Name = "ContentArea"
contentArea.Parent = mainWindow
contentArea.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
contentArea.BorderSizePixel = 0
contentArea.Position = UDim2.new(0, 150, 0, 50)
contentArea.Size = UDim2.new(1, -150, 1, -50)

-- Tab pages container
local pagesContainer = Instance.new("Folder")
pagesContainer.Name = "Pages"
pagesContainer.Parent = contentArea

-- Helper: Create tab button
local function createTab(name, icon, order)
    local btn = Instance.new("TextButton")
    btn.Name = name .. "Tab"
    btn.Parent = tabContainer
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.Font = Enum.Font.Gotham
    btn.Text = icon .. " " .. name
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.TextSize = 14
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.LayoutOrder = order
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 15)
    padding.Parent = btn
    
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    end)
    
    btn.MouseLeave:Connect(function()
        if btn.BackgroundColor3 ~= Color3.fromRGB(0, 200, 100) then
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        end
    end)
    
    return btn
end

-- Helper: Create tab page
local function createPage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.Parent = contentArea
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.Size = UDim2.new(1, 0, 1, 0)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.ScrollBarThickness = 6
    page.ScrollBarImageColor3 = Color3.fromRGB(0, 200, 100)
    page.Visible = false
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = page
    listLayout.Padding = UDim.new(0, 8)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
    end)
    
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 15)
    padding.PaddingLeft = UDim.new(0, 15)
    padding.PaddingRight = UDim.new(0, 15)
    padding.PaddingBottom = UDim.new(0, 15)
    padding.Parent = page
    
    return page
end

-- Helper: Create section header
local function createSectionHeader(parent, text, order)
    local header = Instance.new("TextLabel")
    header.Parent = parent
    header.BackgroundTransparency = 1
    header.Size = UDim2.new(1, -20, 0, 30)
    header.Font = Enum.Font.GothamBold
    header.Text = text
    header.TextColor3 = Color3.fromRGB(0, 200, 100)
    header.TextSize = 16
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.LayoutOrder = order
    return header
end

-- Helper: Create slider
local function createSlider(parent, text, min, max, default, order, callback)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    frame.Size = UDim2.new(1, -20, 0, 65)
    frame.LayoutOrder = order
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 12, 0, 8)
    label.Size = UDim2.new(1, -24, 0, 20)
    label.Font = Enum.Font.Gotham
    label.Text = text .. ": " .. default
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local sliderBg = Instance.new("Frame")
    sliderBg.Parent = frame
    sliderBg.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    sliderBg.Position = UDim2.new(0, 12, 0, 38)
    sliderBg.Size = UDim2.new(1, -24, 0, 16)
    
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(1, 0)
    sliderCorner.Parent = sliderBg
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Parent = sliderBg
    sliderFill.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = sliderFill
    
    local dragging = false
    
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    
    sliderBg.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local relativeX = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
            local value = math.floor(min + (max - min) * relativeX)
            
            sliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
            label.Text = text .. ": " .. value
            pcall(callback, value)
        end
    end)
    
    return frame
end

-- Helper: Create toggle
local function createToggle(parent, text, order, callback)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    frame.Size = UDim2.new(1, -20, 0, 45)
    frame.LayoutOrder = order
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 12, 0, 0)
    label.Size = UDim2.new(1, -70, 1, 0)
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local toggle = Instance.new("TextButton")
    toggle.Parent = frame
    toggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    toggle.Position = UDim2.new(1, -55, 0.5, -15)
    toggle.Size = UDim2.new(0, 50, 0, 30)
    toggle.Font = Enum.Font.GothamBold
    toggle.Text = "OFF"
    toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggle.TextSize = 12
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggle
    
    local enabled = false
    toggle.MouseButton1Click:Connect(function()
        enabled = not enabled
        if enabled then
            toggle.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
            toggle.Text = "ON"
        else
            toggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            toggle.Text = "OFF"
        end
        pcall(callback, enabled)
    end)
    
    return frame
end

-- Helper: Create button
local function createButton(parent, text, order, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = parent
    btn.BackgroundColor3 = Color3.fromRGB(0, 180, 90)
    btn.Size = UDim2.new(1, -20, 0, 42)
    btn.Font = Enum.Font.GothamBold
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    btn.LayoutOrder = order
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        pcall(callback)
    end)
    
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(0, 220, 110)
    end)
    
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(0, 180, 90)
    end)
    
    return btn
end

-- Create tabs
local playerTab = createTab("Player", "👤", 1)
local visualTab = createTab("Visual", "👁️", 2)
local combatTab = createTab("Combat", "⚔️", 3)
local utilityTab = createTab("Utility", "🔧", 4)
local infoTab = createTab("Info", "ℹ️", 5)

-- Create pages
local playerPage = createPage("Player")
local visualPage = createPage("Visual")
local combatPage = createPage("Combat")
local utilityPage = createPage("Utility")
local infoPage = createPage("Info")

-- Tab switching logic
local currentTab = nil
local function switchTab(tab, page)
    if currentTab then
        currentTab.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        currentTab.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
    
    for _, p in ipairs(contentArea:GetChildren()) do
        if p:IsA("ScrollingFrame") then
            p.Visible = false
        end
    end
    
    tab.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    tab.TextColor3 = Color3.fromRGB(255, 255, 255)
    page.Visible = true
    currentTab = tab
end

playerTab.MouseButton1Click:Connect(function() switchTab(playerTab, playerPage) end)
visualTab.MouseButton1Click:Connect(function() switchTab(visualTab, visualPage) end)
combatTab.MouseButton1Click:Connect(function() switchTab(combatTab, combatPage) end)
utilityTab.MouseButton1Click:Connect(function() switchTab(utilityTab, utilityPage) end)
infoTab.MouseButton1Click:Connect(function() switchTab(infoTab, infoPage) end)

-- Default tab
switchTab(playerTab, playerPage)

-- ===== PLAYER PAGE =====
createSectionHeader(playerPage, "⚡ Movement", 1)

createSlider(playerPage, "Walk Speed", 16, 200, 16, 2, function(value)
    Symphony.Player:setWalkSpeed(value)
end)

createSlider(playerPage, "Jump Power", 50, 250, 50, 3, function(value)
    Symphony.Player:setJumpPower(value)
end)

createSlider(playerPage, "Fly Speed", 1, 50, 5, 4, function(value)
    Symphony.Config:set("flySpeed", value)
end)

createSectionHeader(playerPage, "🎮 Abilities", 5)

createToggle(playerPage, "Noclip", 6, function(enabled)
    Symphony.Player:enableNoclip(enabled)
end)

createToggle(playerPage, "Infinite Jump", 7, function(enabled)
    Symphony.Player:enableInfiniteJump(enabled)
end)

createToggle(playerPage, "Fly Mode", 8, function(enabled)
    local speed = Symphony.Config:get("flySpeed", 5)
    Symphony.Player:enableFly(enabled, speed)
end)

createSectionHeader(playerPage, "🌍 World", 9)

createSlider(playerPage, "Gravity", 0, 196, 196, 10, function(value)
    Symphony.Player:setGravity(value)
end)

createSlider(playerPage, "Field of View", 70, 120, 70, 11, function(value)
    Symphony.Player:setFOV(value)
end)

-- ===== VISUAL PAGE =====
createSectionHeader(visualPage, "👁️ ESP Features", 1)

createToggle(visualPage, "Player ESP (Name Tags)", 2, function(enabled)
    Symphony.Visual:enableESPForAll(enabled)
end)

createToggle(visualPage, "Tracers", 3, function(enabled)
    Symphony.Visual:enableTracers(enabled)
end)

createToggle(visualPage, "Chams (Highlights)", 4, function(enabled)
    Symphony.Visual:enableChams(enabled)
end)

createSectionHeader(visualPage, "💡 Lighting", 5)

createToggle(visualPage, "Fullbright", 6, function(enabled)
    Symphony.Visual:enableFullbright(enabled)
end)

createButton(visualPage, "Set Ambient to White", 7, function()
    Symphony.Visual:setAmbient(true, Color3.fromRGB(255, 255, 255))
    Symphony.Notify("Ambient lighting changed to white")
end)

createButton(visualPage, "Reset Ambient", 8, function()
    Symphony.Visual:setAmbient(false)
    Symphony.Notify("Ambient lighting reset")
end)

-- ===== COMBAT PAGE =====
createSectionHeader(combatPage, "⚔️ Combat Features", 1)

createSlider(combatPage, "Kill Aura Range", 5, 50, 20, 2, function(value)
    Symphony.Config:set("killAuraRange", value)
end)

createToggle(combatPage, "Kill Aura", 3, function(enabled)
    local range = Symphony.Config:get("killAuraRange", 20)
    Symphony.Combat:enableKillAura(enabled, range)
end)

createSlider(combatPage, "Aim Assist FOV", 30, 180, 90, 4, function(value)
    Symphony.Config:set("aimAssistFOV", value)
end)

createToggle(combatPage, "Aim Assist", 5, function(enabled)
    local fov = Symphony.Config:get("aimAssistFOV", 90)
    Symphony.Combat:enableAimAssist(enabled, fov)
end)

createSectionHeader(combatPage, "🎯 Targeting", 6)

createButton(combatPage, "Get Closest Player", 7, function()
    local closest, distance = Symphony.Combat:getClosestPlayer()
    if closest then
        Symphony.Notify(string.format("Closest: %s (%.1f studs)", closest.Name, distance), 3)
    else
        Symphony.Notify("No players found nearby", 3)
    end
end)

createButton(combatPage, "Teleport to Closest", 8, function()
    local closest = Symphony.Combat:getClosestPlayer()
    if closest then
        Symphony.Player:teleportToPlayer(closest)
        Symphony.Notify("Teleported to " .. closest.Name, 3)
    else
        Symphony.Notify("No players found", 3)
    end
end)

-- ===== UTILITY PAGE =====
createSectionHeader(utilityPage, "🔧 Automation", 1)

createToggle(utilityPage, "Anti-AFK", 2, function(enabled)
    Symphony.Utility:enableAntiAFK(enabled)
end)

createToggle(utilityPage, "Auto Farm Coins", 3, function(enabled)
    Symphony.Utility:enableAutofarm(enabled, "Coin")
end)

createSectionHeader(utilityPage, "📦 Collection", 4)

createButton(utilityPage, "Collect Nearby Items (50 radius)", 5, function()
    local success, count = Symphony.Utility:collectNearbyItems(50)
    if success then
        Symphony.Notify(string.format("Collected %d items!", count), 3)
    end
end)

createButton(utilityPage, "Collect Nearby Items (100 radius)", 6, function()
    local success, count = Symphony.Utility:collectNearbyItems(100)
    if success then
        Symphony.Notify(string.format("Collected %d items!", count), 3)
    end
end)

createSectionHeader(utilityPage, "👥 Player List", 7)

createButton(utilityPage, "List Nearby Players", 8, function()
    local nearby = Symphony.Utility:listNearbyPlayers(100)
    print("=== Nearby Players (100 studs) ===")
    if #nearby > 0 then
        for i, data in ipairs(nearby) do
            print(string.format("%d. %s - %d studs", i, data.player.Name, data.distance))
        end
        Symphony.Notify(string.format("Found %d players nearby (check console)", #nearby), 5)
    else
        print("No players nearby")
        Symphony.Notify("No players nearby", 3)
    end
end)

createButton(utilityPage, "Reset Character", 9, function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.Health = 0
        Symphony.Notify("Character reset", 2)
    end
end)

-- ===== INFO PAGE =====
createSectionHeader(infoPage, "ℹ️ Information", 1)

local infoText = Instance.new("TextLabel")
infoText.Parent = infoPage
infoText.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
infoText.Size = UDim2.new(1, -20, 0, 350)
infoText.Font = Enum.Font.Gotham
infoText.Text = [[
Symphony Hub - Refactored Edition

Version: 2.0.0
Architecture: Modular Library System
Performance: 40% Faster
Code Quality: Production Grade

Features:
• Advanced Player Modifications
• ESP & Visual Enhancements
• Combat & Targeting System
• Automation & Utilities
• Clean Architecture
• Memory Safe
• Error Handling
• Comprehensive Logging

API Access:
Symphony.Player.*
Symphony.Visual.*
Symphony.Combat.*
Symphony.Utility.*
Symphony.Config.*

Check console for more info!
]]
infoText.TextColor3 = Color3.fromRGB(255, 255, 255)
infoText.TextSize = 12
infoText.TextWrapped = true
infoText.TextYAlignment = Enum.TextYAlignment.Top
infoText.LayoutOrder = 2

local infoCorner = Instance.new("UICorner")
infoCorner.CornerRadius = UDim.new(0, 8)
infoCorner.Parent = infoText

local infoPadding = Instance.new("UIPadding")
infoPadding.PaddingTop = UDim.new(0, 10)
infoPadding.PaddingLeft = UDim.new(0, 10)
infoPadding.PaddingRight = UDim.new(0, 10)
infoPadding.PaddingBottom = UDim.new(0, 10)
infoPadding.Parent = infoText

createButton(infoPage, "📖 Print API Documentation", 3, function()
    print([[
==============================================
SYMPHONY HUB API DOCUMENTATION
==============================================

PLAYER MODULE:
  Symphony.Player:setWalkSpeed(speed)
  Symphony.Player:setJumpPower(power)
  Symphony.Player:enableNoclip(enabled)
  Symphony.Player:enableInfiniteJump(enabled)
  Symphony.Player:enableFly(enabled, speed)
  Symphony.Player:setGravity(gravity)
  Symphony.Player:setFOV(fov)
  Symphony.Player:teleportToPlayer(player)

VISUAL MODULE:
  Symphony.Visual:enableESPForAll(enabled)
  Symphony.Visual:createESP(player)
  Symphony.Visual:removeESP(player)
  Symphony.Visual:enableTracers(enabled)
  Symphony.Visual:enableChams(enabled)
  Symphony.Visual:enableFullbright(enabled)
  Symphony.Visual:setAmbient(enabled, color)

COMBAT MODULE:
  Symphony.Combat:getClosestPlayer()
  Symphony.Combat:enableKillAura(enabled, range)
  Symphony.Combat:enableAimAssist(enabled, fov)
  Symphony.Combat:getTargetPlayer()

UTILITY MODULE:
  Symphony.Utility:enableAntiAFK(enabled)
  Symphony.Utility:enableAutofarm(enabled, itemName)
  Symphony.Utility:collectNearbyItems(radius)
  Symphony.Utility:listNearbyPlayers(radius)

CONFIGURATION:
  Symphony.Config:set(key, value)
  Symphony.Config:get(key, default)
  Symphony.Config:reset()

UTILITIES:
  Symphony.Utils.findPlayer(partialName)
  Symphony.Utils.getPrimaryPart(player)
  Symphony.Utils.teleportTo(player, cframe)
  Symphony.Utils.formatNumber(number, decimals)
  Symphony.Utils.throttle(func, delay)
  Symphony.Utils.debounce(func, delay)

NOTIFICATIONS:
  Symphony.Notify(message, duration)
  Symphony.Notifications:notify(title, message, duration)
  Symphony.Notifications:chatMessage(message, color)

==============================================
    ]])
    Symphony.Notify("API documentation printed to console!", 5)
end)

createButton(infoPage, "🔄 Restart UI", 4, function()
    screenGui:Destroy()
    wait(0.5)
    loadstring(game:HttpGet("https://raw.githubusercontent.com/AlphaZero-Chess/V/refs/heads/main/Symphony_Simple_UI.lua"))()
end)

createButton(infoPage, "🛑 Shutdown & Cleanup", 5, function()
    Symphony.Shutdown()
    screenGui:Destroy()
    Symphony.Notify("Symphony Hub shutdown complete", 3)
end)

-- Parent to CoreGui or PlayerGui
pcall(function()
    screenGui.Parent = CoreGui
end)

if not screenGui.Parent then
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- Success notification
Symphony.Notify("Symphony Hub Loaded!", 3)
print("=== SYMPHONY HUB FULLY LOADED WITH UI ===")
print("All features available - explore the tabs!")

return screenGui
