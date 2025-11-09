--[[
    Symphony Hub - Simple UI Version with Debug
    This version has extensive debug output to help identify issues
]]

print("=== SYMPHONY HUB LOADING ===")
print("Step 1: Starting initialization...")

-- Get required services
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

print("Step 2: Services loaded")

local LocalPlayer = Players.LocalPlayer
print("Step 3: LocalPlayer found: " .. LocalPlayer.Name)

-- Create UI immediately for testing
print("Step 4: Creating UI...")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SymphonyHubSimple"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

print("Step 5: ScreenGui created")

-- Main Frame - Large and centered
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Parent = screenGui
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
mainFrame.BorderSizePixel = 3
mainFrame.BorderColor3 = Color3.fromRGB(0, 255, 100)
mainFrame.Position = UDim2.new(0.5, -250, 0.5, -300)
mainFrame.Size = UDim2.new(0, 500, 0, 600)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Visible = true

print("Step 6: Main frame created and set to visible")

-- Add corner
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Parent = mainFrame
titleBar.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
titleBar.BorderSizePixel = 0
titleBar.Size = UDim2.new(1, 0, 0, 50)
titleBar.Visible = true

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleBar

-- Title Text
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Parent = titleBar
titleLabel.BackgroundTransparency = 1
titleLabel.Size = UDim2.new(1, -100, 1, 0)
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "🎵 SYMPHONY HUB - REFACTORED"
titleLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
titleLabel.TextSize = 20
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Visible = true

print("Step 7: Title created")

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "Status"
statusLabel.Parent = titleBar
statusLabel.BackgroundTransparency = 1
statusLabel.Size = UDim2.new(0, 80, 1, 0)
statusLabel.Position = UDim2.new(1, -85, 0, 0)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.Text = "LOADED"
statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
statusLabel.TextSize = 14
statusLabel.Visible = true

-- Close Button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Parent = titleBar
closeButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
closeButton.Position = UDim2.new(1, -40, 0.5, -15)
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 18
closeButton.Visible = true

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1, 0)
closeCorner.Parent = closeButton

closeButton.MouseButton1Click:Connect(function()
    print("Close button clicked - destroying UI")
    screenGui:Destroy()
end)

print("Step 8: Close button created")

-- Content Frame
local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Parent = mainFrame
contentFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
contentFrame.BorderSizePixel = 0
contentFrame.Position = UDim2.new(0, 10, 0, 60)
contentFrame.Size = UDim2.new(1, -20, 1, -70)
contentFrame.Visible = true

local contentCorner = Instance.new("UICorner")
contentCorner.CornerRadius = UDim.new(0, 8)
contentCorner.Parent = contentFrame

-- Add ScrollingFrame
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "ScrollFrame"
scrollFrame.Parent = contentFrame
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.Size = UDim2.new(1, 0, 1, 0)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 800)
scrollFrame.ScrollBarThickness = 8
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 100)
scrollFrame.Visible = true

local listLayout = Instance.new("UIListLayout")
listLayout.Parent = scrollFrame
listLayout.Padding = UDim.new(0, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 10)
padding.PaddingLeft = UDim.new(0, 10)
padding.PaddingRight = UDim.new(0, 10)
padding.Parent = scrollFrame

print("Step 9: Content frame created")

-- Helper Functions
local function createSectionLabel(text, order)
    local label = Instance.new("TextLabel")
    label.Parent = scrollFrame
    label.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    label.Size = UDim2.new(1, -20, 0, 35)
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextColor3 = Color3.fromRGB(0, 255, 100)
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.LayoutOrder = order
    label.Visible = true
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = label
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 12)
    padding.Parent = label
    
    return label
end

local function createButton(text, order, callback)
    local button = Instance.new("TextButton")
    button.Parent = scrollFrame
    button.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
    button.Size = UDim2.new(1, -20, 0, 40)
    button.Font = Enum.Font.GothamBold
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 15
    button.LayoutOrder = order
    button.Visible = true
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    button.MouseButton1Click:Connect(function()
        local success, err = pcall(callback)
        if not success then
            warn("Button error: " .. tostring(err))
        end
    end)
    
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(0, 220, 100)
    end)
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
    end)
    
    return button
end

local function createToggle(text, order, callback)
    local frame = Instance.new("Frame")
    frame.Parent = scrollFrame
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    frame.Size = UDim2.new(1, -20, 0, 40)
    frame.LayoutOrder = order
    frame.Visible = true
    
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
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Visible = true
    
    local toggle = Instance.new("TextButton")
    toggle.Parent = frame
    toggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    toggle.Position = UDim2.new(1, -55, 0.5, -15)
    toggle.Size = UDim2.new(0, 50, 0, 30)
    toggle.Font = Enum.Font.GothamBold
    toggle.Text = "OFF"
    toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggle.TextSize = 12
    toggle.Visible = true
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggle
    
    local enabled = false
    toggle.MouseButton1Click:Connect(function()
        enabled = not enabled
        if enabled then
            toggle.BackgroundColor3 = Color3.fromRGB(50, 200, 80)
            toggle.Text = "ON"
        else
            toggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            toggle.Text = "OFF"
        end
        local success, err = pcall(callback, enabled)
        if not success then
            warn("Toggle error: " .. tostring(err))
        end
    end)
    
    return frame
end

local function createSlider(text, min, max, default, order, callback)
    local frame = Instance.new("Frame")
    frame.Parent = scrollFrame
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    frame.Size = UDim2.new(1, -20, 0, 60)
    frame.LayoutOrder = order
    frame.Visible = true
    
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
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Visible = true
    
    local sliderBg = Instance.new("Frame")
    sliderBg.Parent = frame
    sliderBg.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    sliderBg.Position = UDim2.new(0, 12, 0, 35)
    sliderBg.Size = UDim2.new(1, -24, 0, 15)
    
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(1, 0)
    sliderCorner.Parent = sliderBg
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Parent = sliderBg
    sliderFill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
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
            
            local success, err = pcall(callback, value)
            if not success then
                warn("Slider error: " .. tostring(err))
            end
        end
    end)
    
    return frame
end

print("Step 10: Helper functions created")

-- Create UI Elements
createSectionLabel("⚡ PLAYER MODIFICATIONS", 1)

createSlider("Walk Speed", 16, 200, 16, 2, function(value)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = value
        print("Walk speed set to: " .. value)
    end
end)

createSlider("Jump Power", 50, 200, 50, 3, function(value)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.JumpPower = value
        print("Jump power set to: " .. value)
    end
end)

createToggle("Noclip", 4, function(enabled)
    print("Noclip toggled: " .. tostring(enabled))
    if enabled then
        game:GetService("RunService").Stepped:Connect(function()
            if LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
end)

createToggle("Infinite Jump", 5, function(enabled)
    print("Infinite jump toggled: " .. tostring(enabled))
    if enabled then
        UserInputService.JumpRequest:Connect(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end)

createSectionLabel("🔧 UTILITIES", 6)

createButton("✅ Test Notification", 7, function()
    game.StarterGui:SetCore("SendNotification", {
        Title = "Symphony Hub",
        Text = "UI is working perfectly!",
        Duration = 3
    })
    print("Test notification sent!")
end)

createButton("🔄 Reset Character", 8, function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.Health = 0
        print("Character reset")
    end
end)

createSectionLabel("ℹ️ INFORMATION", 9)

createButton("📖 View Console Info", 10, function()
    print("=================================")
    print("SYMPHONY HUB - REFACTORED")
    print("Version: 2.0.0")
    print("Architecture: Modular Library")
    print("Status: Fully Functional")
    print("=================================")
    print("Simple API Examples:")
    print("  Symphony.SetWalkSpeed(50)")
    print("  Symphony.EnableNoclip(true)")
    print("=================================")
end)

print("Step 11: All UI elements created")

-- Try to parent to CoreGui first, then PlayerGui
local success = pcall(function()
    screenGui.Parent = CoreGui
    print("Step 12: UI parented to CoreGui")
end)

if not success then
    print("Step 12: CoreGui failed, trying PlayerGui...")
    local success2 = pcall(function()
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        print("Step 12: UI parented to PlayerGui")
    end)
    if not success2 then
        print("ERROR: Could not parent UI to either CoreGui or PlayerGui!")
    end
end

-- Verify UI is visible
wait(0.5)
print("Step 13: Checking UI visibility...")
print("ScreenGui Parent: " .. tostring(screenGui.Parent))
print("ScreenGui Visible: " .. tostring(screenGui.Enabled))
print("MainFrame Visible: " .. tostring(mainFrame.Visible))
print("MainFrame Position: " .. tostring(mainFrame.Position))
print("MainFrame Size: " .. tostring(mainFrame.Size))

-- Final notification
game.StarterGui:SetCore("SendNotification", {
    Title = "Symphony Hub",
    Text = "Loaded! Check your screen for the UI!",
    Duration = 5
})

print("=== SYMPHONY HUB FULLY LOADED ===")
print("If you don't see the UI, check the console output above for errors")
print("The UI should be a draggable green-bordered window in the center of your screen")

return screenGui
