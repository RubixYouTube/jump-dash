-- AdvancedAbilitiesSystemV4_1 (LocalScript)
-- Place in StarterPlayer > StarterPlayerScripts
-- Version 4.1 - Made by rubix

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ============================================
-- THEME SYSTEM
-- ============================================
local themes = {
	Red = {primary = Color3.fromRGB(200, 40, 40), secondary = Color3.fromRGB(120, 20, 20), accent = Color3.fromRGB(255, 80, 80), bg = Color3.fromRGB(30, 15, 15), titleBg = Color3.fromRGB(50, 20, 20), text = Color3.fromRGB(255, 200, 200), stroke = Color3.fromRGB(200, 60, 60)},
	Orange = {primary = Color3.fromRGB(220, 130, 20), secondary = Color3.fromRGB(140, 80, 10), accent = Color3.fromRGB(255, 170, 50), bg = Color3.fromRGB(30, 22, 10), titleBg = Color3.fromRGB(50, 35, 15), text = Color3.fromRGB(255, 220, 180), stroke = Color3.fromRGB(220, 140, 40)},
	Yellow = {primary = Color3.fromRGB(220, 200, 20), secondary = Color3.fromRGB(140, 130, 10), accent = Color3.fromRGB(255, 240, 50), bg = Color3.fromRGB(30, 28, 10), titleBg = Color3.fromRGB(50, 45, 15), text = Color3.fromRGB(255, 250, 200), stroke = Color3.fromRGB(220, 200, 40)},
	Green = {primary = Color3.fromRGB(40, 180, 60), secondary = Color3.fromRGB(20, 100, 30), accent = Color3.fromRGB(80, 255, 100), bg = Color3.fromRGB(15, 30, 18), titleBg = Color3.fromRGB(20, 50, 25), text = Color3.fromRGB(200, 255, 210), stroke = Color3.fromRGB(60, 180, 80)},
	Blue = {primary = Color3.fromRGB(40, 80, 200), secondary = Color3.fromRGB(20, 40, 120), accent = Color3.fromRGB(100, 150, 255), bg = Color3.fromRGB(20, 20, 30), titleBg = Color3.fromRGB(30, 30, 50), text = Color3.fromRGB(200, 200, 255), stroke = Color3.fromRGB(80, 80, 120)},
	Purple = {primary = Color3.fromRGB(140, 40, 200), secondary = Color3.fromRGB(80, 20, 120), accent = Color3.fromRGB(180, 100, 255), bg = Color3.fromRGB(25, 15, 30), titleBg = Color3.fromRGB(40, 25, 50), text = Color3.fromRGB(220, 200, 255), stroke = Color3.fromRGB(140, 80, 180)},
	Pink = {primary = Color3.fromRGB(220, 60, 140), secondary = Color3.fromRGB(140, 30, 80), accent = Color3.fromRGB(255, 120, 180), bg = Color3.fromRGB(30, 15, 22), titleBg = Color3.fromRGB(50, 25, 35), text = Color3.fromRGB(255, 210, 230), stroke = Color3.fromRGB(220, 80, 150)},
	Brown = {primary = Color3.fromRGB(140, 90, 40), secondary = Color3.fromRGB(90, 55, 20), accent = Color3.fromRGB(180, 120, 60), bg = Color3.fromRGB(25, 18, 12), titleBg = Color3.fromRGB(40, 28, 18), text = Color3.fromRGB(230, 210, 190), stroke = Color3.fromRGB(140, 100, 60)},
	Black = {primary = Color3.fromRGB(60, 60, 60), secondary = Color3.fromRGB(30, 30, 30), accent = Color3.fromRGB(120, 120, 120), bg = Color3.fromRGB(10, 10, 10), titleBg = Color3.fromRGB(20, 20, 20), text = Color3.fromRGB(200, 200, 200), stroke = Color3.fromRGB(80, 80, 80)},
	White = {primary = Color3.fromRGB(220, 220, 220), secondary = Color3.fromRGB(180, 180, 180), accent = Color3.fromRGB(255, 255, 255), bg = Color3.fromRGB(240, 240, 245), titleBg = Color3.fromRGB(220, 220, 230), text = Color3.fromRGB(30, 30, 40), stroke = Color3.fromRGB(180, 180, 200)},
	Grey = {primary = Color3.fromRGB(120, 120, 130), secondary = Color3.fromRGB(70, 70, 80), accent = Color3.fromRGB(170, 170, 180), bg = Color3.fromRGB(30, 30, 35), titleBg = Color3.fromRGB(45, 45, 50), text = Color3.fromRGB(210, 210, 220), stroke = Color3.fromRGB(100, 100, 110)},
}

local currentTheme = themes.Blue
local themeCallbacks = {} -- functions to call when theme changes

local function registerThemeable(callback)
	table.insert(themeCallbacks, callback)
	callback(currentTheme)
end

local function setTheme(name)
	if themes[name] then
		currentTheme = themes[name]
		for _, cb in themeCallbacks do
			cb(currentTheme)
		end
	end
end

-- ============================================
-- CONFIGURATION
-- ============================================
local DASH_DISTANCE = 40
local DASH_DURATION = 0.35
local DASH_COOLDOWN = 0.8

local MINI_DASH_DISTANCE = 20
local MINI_DASH_DURATION = 0.2
local MINI_DASH_COOLDOWN = 0.4

local PLATFORM_DURATION = 15
local PLATFORM_SIZE = Vector3.new(10, 1, 10)
local PLATFORM_COOLDOWN = 3

local LUNGE_DISTANCE = 100
local LUNGE_SPEED_MULT = 1.7
local LUNGE_COOLDOWN = 2

local MEGA_JUMP_MULT = 6
local MEGA_JUMP_GRAVITY_SCALE = 0.6
local MEGA_JUMP_COOLDOWN = 4

local SHOCKWAVE_TRAVEL_DURATION = 25
local SHOCKWAVE_TRAVEL_SPEED = 150
local SHOCKWAVE_TRAVEL_COOLDOWN = 10

local FUSION_DURATION = 15
local FUSION_SPEED_MULT = 1.5
local FUSION_JUMP_POWER_TARGET = 110
local FUSION_GRAVITY_MULT = 0.5
local FUSION_COOLDOWN = 8

local RAINBOW_LOCATOR_COOLDOWN = 12

local IMMORTALITY_DURATION = 60
local IMMORTALITY_COOLDOWN = 30

-- ============================================
-- STATE
-- ============================================
local dashEnabled = true
local canDash = true
local isDashing = false

local canMiniDash = true

local platformActive = false
local canPlatform = true
local currentPlatform = nil
local platformFollowConn = nil

local canLunge = true
local isLunging = false

local megaJumpArmed = false
local canMegaJump = true
local isMegaJumping = false
local megaJumpGravityActive = false

local canShockwaveTravel = true
local isShockwaveTraveling = false
local shockwaveTunnelParts = {}
local shockwaveEmergencyStop = false

local canFusion = true
local isFusionActive = false
local fusionJumpConn = nil

local canRainbowLocator = true
local isRainbowLocatorActive = false
local rainbowFreecamActive = false
local savedWalkSpeedForRainbow = 16

local canImmortality = true
local isImmortal = false
local immortalityShieldPart = nil
local immortalityFloorPart = nil
local immortalityFollowConn = nil
local immortalityScreenGui = nil
local savedImmortalityHealth = nil

local originalGravity = workspace.Gravity

-- ============================================
-- UTILITY
-- ============================================
local function isVoidBelow(position, maxDist)
	local dist = maxDist or 500
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local filterList = {}
	if player.Character then table.insert(filterList, player.Character) end
	if currentPlatform then table.insert(filterList, currentPlatform) end
	if immortalityFloorPart then table.insert(filterList, immortalityFloorPart) end
	if immortalityShieldPart then table.insert(filterList, immortalityShieldPart) end
	for _, p in shockwaveTunnelParts do if p and p.Parent then table.insert(filterList, p) end end
	rayParams.FilterDescendantsInstances = filterList
	return workspace:Raycast(position, Vector3.new(0, -dist, 0), rayParams) == nil
end

local function isOnCollidableSurface(rootPart)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local filterList = {}
	if player.Character then table.insert(filterList, player.Character) end
	if currentPlatform then table.insert(filterList, currentPlatform) end
	if immortalityFloorPart then table.insert(filterList, immortalityFloorPart) end
	if immortalityShieldPart then table.insert(filterList, immortalityShieldPart) end
	for _, p in shockwaveTunnelParts do if p and p.Parent then table.insert(filterList, p) end end
	rayParams.FilterDescendantsInstances = filterList
	local result = workspace:Raycast(rootPart.Position, Vector3.new(0, -5, 0), rayParams)
	return result ~= nil and result.Instance ~= nil and result.Instance.CanCollide
end

local function findNearestCollidablePart(position)
	local nearestDist = math.huge
	local nearestPos = position
	local filterList = {}
	if player.Character then table.insert(filterList, player.Character) end
	if currentPlatform then table.insert(filterList, currentPlatform) end
	if immortalityFloorPart then table.insert(filterList, immortalityFloorPart) end
	if immortalityShieldPart then table.insert(filterList, immortalityShieldPart) end
	for _, p in shockwaveTunnelParts do if p and p.Parent then table.insert(filterList, p) end end
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = filterList
	local directions = {
		Vector3.new(0,-1,0), Vector3.new(1,0,0), Vector3.new(-1,0,0),
		Vector3.new(0,0,1), Vector3.new(0,0,-1),
		Vector3.new(1,-1,0).Unit, Vector3.new(-1,-1,0).Unit,
		Vector3.new(0,-1,1).Unit, Vector3.new(0,-1,-1).Unit,
		Vector3.new(1,-1,1).Unit, Vector3.new(-1,-1,1).Unit,
		Vector3.new(1,-1,-1).Unit, Vector3.new(-1,-1,-1).Unit,
		Vector3.new(0,1,0),
	}
	for _, dir in directions do
		local result = workspace:Raycast(position, dir * 2000, rayParams)
		if result and result.Instance and result.Instance.CanCollide then
			local dist = (result.Position - position).Magnitude
			if dist < nearestDist then
				nearestDist = dist
				nearestPos = result.Position + Vector3.new(0, 3, 0)
			end
		end
	end
	return nil, nearestPos
end

local function checkHeadObstacle(rootPart)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local filterList = {player.Character}
	if currentPlatform then table.insert(filterList, currentPlatform) end
	if immortalityFloorPart then table.insert(filterList, immortalityFloorPart) end
	if immortalityShieldPart then table.insert(filterList, immortalityShieldPart) end
	for _, p in shockwaveTunnelParts do if p and p.Parent then table.insert(filterList, p) end end
	rayParams.FilterDescendantsInstances = filterList

	local upResult = workspace:Raycast(rootPart.Position, Vector3.new(0, 8, 0), rayParams)
	if upResult and upResult.Instance and upResult.Instance.CanCollide then
		local hitNormal = upResult.Normal
		local avoidDir = Vector3.new(hitNormal.X, 0, hitNormal.Z)
		if avoidDir.Magnitude < 0.1 then
			local bestDir, bestDist = nil, 0
			for _, dir in {Vector3.new(1,0,0), Vector3.new(-1,0,0), Vector3.new(0,0,1), Vector3.new(0,0,-1), Vector3.new(1,0,1).Unit, Vector3.new(-1,0,1).Unit, Vector3.new(1,0,-1).Unit, Vector3.new(-1,0,-1).Unit} do
				local sc = workspace:Raycast(rootPart.Position, dir * 20, rayParams)
				local dist = sc and sc.Distance or 20
				if dist > bestDist then bestDist = dist; bestDir = dir end
			end
			return bestDir
		end
		return avoidDir.Unit
	end

	local lookDir = rootPart.CFrame.LookVector
	local diagResult = workspace:Raycast(rootPart.Position + Vector3.new(0, 3, 0), Vector3.new(lookDir.X, 1, lookDir.Z).Unit * 6, rayParams)
	if diagResult and diagResult.Instance and diagResult.Instance.CanCollide then
		local avoidDir = Vector3.new(diagResult.Normal.X, 0, diagResult.Normal.Z)
		if avoidDir.Magnitude > 0.1 then return avoidDir.Unit end
	end
	return nil
end

local function playSound(parent, id, volume, speed)
	local sound = Instance.new("Sound")
	sound.SoundId = id; sound.Volume = volume or 0.5; sound.PlaybackSpeed = speed or 1
	sound.Parent = parent; sound:Play(); Debris:AddItem(sound, 3)
end

local function getRainbowColor(t)
	return Color3.fromHSV((t % 1), 1, 1)
end

local function getMonochromeColor(t)
	local v = (math.sin(t * 3) + 1) / 2
	return Color3.fromRGB(v * 255, v * 255, v * 255)
end

-- ============================================
-- SCREEN GUI
-- ============================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AbilitiesGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player.PlayerGui

-- ============================================
-- DASH TOGGLE
-- ============================================
local dashToggleFrame, dashToggleStroke, dashToggleLabel

local function createDashToggle()
	local buttonFrame = Instance.new("Frame")
	buttonFrame.Name = "DashToggleFrame"
	buttonFrame.Size = UDim2.new(0, 160, 0, 50)
	buttonFrame.Position = UDim2.new(1, -175, 1, -65)
	buttonFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	buttonFrame.BackgroundTransparency = 0.2
	buttonFrame.BorderSizePixel = 0
	buttonFrame.Parent = screenGui
	Instance.new("UICorner", buttonFrame).CornerRadius = UDim.new(0, 12)
	dashToggleFrame = buttonFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 170, 255); stroke.Thickness = 2; stroke.Transparency = 0.3
	stroke.Parent = buttonFrame
	dashToggleStroke = stroke

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.6, 0, 1, 0); label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1; label.Text = "Jump Dash"
	label.TextColor3 = Color3.fromRGB(255, 255, 255); label.TextSize = 16
	label.Font = Enum.Font.GothamBold; label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = buttonFrame
	dashToggleLabel = label

	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Size = UDim2.new(0, 50, 0, 26)
	toggleBtn.Position = UDim2.new(1, -60, 0.5, 0); toggleBtn.AnchorPoint = Vector2.new(0, 0.5)
	toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100); toggleBtn.BorderSizePixel = 0
	toggleBtn.Text = "ON"; toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggleBtn.TextSize = 14; toggleBtn.Font = Enum.Font.GothamBold
	toggleBtn.Parent = buttonFrame
	Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)

	local cdBar = Instance.new("Frame")
	cdBar.Name = "CooldownBar"; cdBar.Size = UDim2.new(1, 0, 0, 3)
	cdBar.Position = UDim2.new(0, 0, 1, -3)
	cdBar.BackgroundColor3 = Color3.fromRGB(0, 170, 255); cdBar.BorderSizePixel = 0
	cdBar.Parent = buttonFrame
	Instance.new("UICorner", cdBar).CornerRadius = UDim.new(0, 2)

	toggleBtn.MouseButton1Click:Connect(function()
		dashEnabled = not dashEnabled
		if dashEnabled then
			toggleBtn.Text = "ON"; toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
			stroke.Color = currentTheme.accent; label.TextColor3 = currentTheme.text
		else
			toggleBtn.Text = "OFF"; toggleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
			stroke.Color = Color3.fromRGB(100, 100, 100); label.TextColor3 = Color3.fromRGB(150, 150, 150)
		end
	end)

	return cdBar
end

local dashCooldownBar = createDashToggle()

-- ============================================
-- ABILITIES MENU
-- ============================================
local menuOpen = true
local menuFrame, menuStrokeObj, titleBarObj, titleBarFixObj, titleLabelObj, scrollFrameObj, emergencyBtnObj

menuFrame = Instance.new("Frame")
menuFrame.Name = "AbilitiesMenu"; menuFrame.Size = UDim2.new(0, 250, 0, 450)
menuFrame.Position = UDim2.new(0, 20, 0.5, -225)
menuFrame.BackgroundColor3 = currentTheme.bg; menuFrame.BackgroundTransparency = 0.1
menuFrame.BorderSizePixel = 0; menuFrame.ClipsDescendants = true; menuFrame.Parent = screenGui
Instance.new("UICorner", menuFrame).CornerRadius = UDim.new(0, 14)

menuStrokeObj = Instance.new("UIStroke")
menuStrokeObj.Color = currentTheme.stroke; menuStrokeObj.Thickness = 2; menuStrokeObj.Parent = menuFrame

titleBarObj = Instance.new("Frame")
titleBarObj.Name = "TitleBar"; titleBarObj.Size = UDim2.new(1, 0, 0, 36)
titleBarObj.BackgroundColor3 = currentTheme.titleBg; titleBarObj.BackgroundTransparency = 0.1
titleBarObj.BorderSizePixel = 0; titleBarObj.ZIndex = 3; titleBarObj.Parent = menuFrame
Instance.new("UICorner", titleBarObj).CornerRadius = UDim.new(0, 14)

titleBarFixObj = Instance.new("Frame")
titleBarFixObj.Size = UDim2.new(1, 0, 0, 14); titleBarFixObj.Position = UDim2.new(0, 0, 1, -14)
titleBarFixObj.BackgroundColor3 = currentTheme.titleBg; titleBarFixObj.BackgroundTransparency = 0.1
titleBarFixObj.BorderSizePixel = 0; titleBarFixObj.ZIndex = 3; titleBarFixObj.Parent = titleBarObj

titleLabelObj = Instance.new("TextLabel")
titleLabelObj.Size = UDim2.new(1, -90, 1, 0); titleLabelObj.Position = UDim2.new(0, 12, 0, 0)
titleLabelObj.BackgroundTransparency = 1; titleLabelObj.Text = "⚡ Abilities"
titleLabelObj.TextColor3 = currentTheme.text; titleLabelObj.TextSize = 16
titleLabelObj.Font = Enum.Font.GothamBold; titleLabelObj.TextXAlignment = Enum.TextXAlignment.Left
titleLabelObj.ZIndex = 3; titleLabelObj.Parent = titleBarObj

-- Minimize button
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 26, 0, 24)
minimizeBtn.Position = UDim2.new(1, -34, 0.5, 0); minimizeBtn.AnchorPoint = Vector2.new(0, 0.5)
minimizeBtn.BackgroundColor3 = currentTheme.secondary; minimizeBtn.BorderSizePixel = 0
minimizeBtn.Text = "—"; minimizeBtn.TextColor3 = currentTheme.text
minimizeBtn.TextSize = 16; minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.ZIndex = 3; minimizeBtn.Parent = titleBarObj
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 6)

-- Question mark button (About)
local aboutBtn = Instance.new("TextButton")
aboutBtn.Size = UDim2.new(0, 26, 0, 24)
aboutBtn.Position = UDim2.new(1, -62, 0.5, 0); aboutBtn.AnchorPoint = Vector2.new(0, 0.5)
aboutBtn.BackgroundColor3 = currentTheme.secondary; aboutBtn.BorderSizePixel = 0
aboutBtn.Text = "?"; aboutBtn.TextColor3 = currentTheme.text
aboutBtn.TextSize = 14; aboutBtn.Font = Enum.Font.GothamBold
aboutBtn.ZIndex = 3; aboutBtn.Parent = titleBarObj
Instance.new("UICorner", aboutBtn).CornerRadius = UDim.new(0, 6)

-- Themes button
local themesBtn = Instance.new("TextButton")
themesBtn.Size = UDim2.new(0, 26, 0, 24)
themesBtn.Position = UDim2.new(1, -90, 0.5, 0); themesBtn.AnchorPoint = Vector2.new(0, 0.5)
themesBtn.BackgroundColor3 = currentTheme.secondary; themesBtn.BorderSizePixel = 0
themesBtn.Text = "🎨"; themesBtn.TextColor3 = currentTheme.text
themesBtn.TextSize = 12; themesBtn.Font = Enum.Font.GothamBold
themesBtn.ZIndex = 3; themesBtn.Parent = titleBarObj
Instance.new("UICorner", themesBtn).CornerRadius = UDim.new(0, 6)

scrollFrameObj = Instance.new("ScrollingFrame")
scrollFrameObj.Name = "ScrollContent"; scrollFrameObj.Size = UDim2.new(1, -8, 1, -80)
scrollFrameObj.Position = UDim2.new(0, 4, 0, 40); scrollFrameObj.BackgroundTransparency = 1
scrollFrameObj.ScrollBarThickness = 4; scrollFrameObj.ScrollBarImageColor3 = currentTheme.accent
scrollFrameObj.CanvasSize = UDim2.new(0, 0, 0, 0); scrollFrameObj.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrameObj.Parent = menuFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder; listLayout.Padding = UDim.new(0, 6)
listLayout.Parent = scrollFrameObj

local listPadding = Instance.new("UIPadding")
listPadding.PaddingLeft = UDim.new(0, 4); listPadding.PaddingRight = UDim.new(0, 4)
listPadding.PaddingTop = UDim.new(0, 2); listPadding.PaddingBottom = UDim.new(0, 4)
listPadding.Parent = scrollFrameObj

emergencyBtnObj = Instance.new("TextButton")
emergencyBtnObj.Name = "EmergencyStop"; emergencyBtnObj.Size = UDim2.new(1, -16, 0, 30)
emergencyBtnObj.Position = UDim2.new(0.5, 0, 1, -38); emergencyBtnObj.AnchorPoint = Vector2.new(0.5, 0)
emergencyBtnObj.BackgroundColor3 = Color3.fromRGB(200, 30, 30); emergencyBtnObj.BorderSizePixel = 0
emergencyBtnObj.Text = "⚠ EMERGENCY STOP"; emergencyBtnObj.TextColor3 = Color3.fromRGB(255, 255, 255)
emergencyBtnObj.TextSize = 13; emergencyBtnObj.Font = Enum.Font.GothamBold
emergencyBtnObj.ZIndex = 3; emergencyBtnObj.Parent = menuFrame
Instance.new("UICorner", emergencyBtnObj).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", emergencyBtnObj).Color = Color3.fromRGB(255, 80, 80)

-- Register theme updates for menu
registerThemeable(function(t)
	menuFrame.BackgroundColor3 = t.bg
	menuStrokeObj.Color = t.stroke
	titleBarObj.BackgroundColor3 = t.titleBg
	titleBarFixObj.BackgroundColor3 = t.titleBg
	titleLabelObj.TextColor3 = t.text
	minimizeBtn.BackgroundColor3 = t.secondary; minimizeBtn.TextColor3 = t.text
	aboutBtn.BackgroundColor3 = t.secondary; aboutBtn.TextColor3 = t.text
	themesBtn.BackgroundColor3 = t.secondary; themesBtn.TextColor3 = t.text
	scrollFrameObj.ScrollBarImageColor3 = t.accent
	if dashToggleStroke and dashEnabled then dashToggleStroke.Color = t.accent end
end)

-- Dragging
local dragging = false
local dragStart = Vector2.zero
local frameStartPos = UDim2.new()

titleBarObj.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = Vector2.new(input.Position.X, input.Position.Y)
		frameStartPos = menuFrame.Position
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
		menuFrame.Position = UDim2.new(frameStartPos.X.Scale, frameStartPos.X.Offset + delta.X, frameStartPos.Y.Scale, frameStartPos.Y.Offset + delta.Y)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

minimizeBtn.MouseButton1Click:Connect(function()
	menuOpen = not menuOpen
	if menuOpen then
		menuFrame.Size = UDim2.new(0, 250, 0, 450)
		scrollFrameObj.Visible = true; emergencyBtnObj.Visible = true; minimizeBtn.Text = "—"
	else
		menuFrame.Size = UDim2.new(0, 250, 0, 36)
		scrollFrameObj.Visible = false; emergencyBtnObj.Visible = false; minimizeBtn.Text = "+"
	end
end)

-- ============================================
-- ABOUT WINDOW
-- ============================================
local aboutWindow = nil

aboutBtn.MouseButton1Click:Connect(function()
	if aboutWindow and aboutWindow.Parent then aboutWindow:Destroy(); aboutWindow = nil; return end

	aboutWindow = Instance.new("Frame")
	aboutWindow.Size = UDim2.new(0, 320, 0, 200)
	aboutWindow.Position = UDim2.new(0.5, 0, 0.5, 0); aboutWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	aboutWindow.BackgroundColor3 = currentTheme.bg; aboutWindow.BackgroundTransparency = 0.05
	aboutWindow.BorderSizePixel = 0; aboutWindow.Parent = screenGui
	Instance.new("UICorner", aboutWindow).CornerRadius = UDim.new(0, 14)
	local awStroke = Instance.new("UIStroke"); awStroke.Color = currentTheme.stroke; awStroke.Thickness = 2; awStroke.Parent = aboutWindow

	local awClose = Instance.new("TextButton")
	awClose.Size = UDim2.new(0, 30, 0, 30); awClose.Position = UDim2.new(1, -8, 0, 8)
	awClose.AnchorPoint = Vector2.new(1, 0); awClose.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
	awClose.BorderSizePixel = 0; awClose.Text = "✕"; awClose.TextColor3 = Color3.fromRGB(255, 255, 255)
	awClose.TextSize = 16; awClose.Font = Enum.Font.GothamBold; awClose.Parent = aboutWindow
	Instance.new("UICorner", awClose).CornerRadius = UDim.new(0, 8)
	awClose.MouseButton1Click:Connect(function() aboutWindow:Destroy(); aboutWindow = nil end)

	local awTitle = Instance.new("TextLabel")
	awTitle.Size = UDim2.new(1, -50, 0, 40); awTitle.Position = UDim2.new(0, 16, 0, 10)
	awTitle.BackgroundTransparency = 1; awTitle.Text = "About this"
	awTitle.TextColor3 = currentTheme.text; awTitle.TextSize = 24
	awTitle.Font = Enum.Font.GothamBold; awTitle.TextXAlignment = Enum.TextXAlignment.Left
	awTitle.Parent = aboutWindow

	local awBody = Instance.new("TextLabel")
	awBody.Size = UDim2.new(1, -32, 0, 120); awBody.Position = UDim2.new(0, 16, 0, 55)
	awBody.BackgroundTransparency = 1
	awBody.Text = "This script allows you to have dash abilities and also supernatural abilities.\n\nMade by rubix.\nVersion 4.1"
	awBody.TextColor3 = currentTheme.text; awBody.TextSize = 14
	awBody.Font = Enum.Font.Gotham; awBody.TextXAlignment = Enum.TextXAlignment.Left
	awBody.TextYAlignment = Enum.TextYAlignment.Top; awBody.TextWrapped = true
	awBody.Parent = aboutWindow
end)

-- ============================================
-- THEMES WINDOW
-- ============================================
local themesWindow = nil

themesBtn.MouseButton1Click:Connect(function()
	if themesWindow and themesWindow.Parent then themesWindow:Destroy(); themesWindow = nil; return end

	themesWindow = Instance.new("Frame")
	themesWindow.Size = UDim2.new(0, 280, 0, 300)
	themesWindow.Position = UDim2.new(0.5, 0, 0.5, 0); themesWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	themesWindow.BackgroundColor3 = currentTheme.bg; themesWindow.BackgroundTransparency = 0.05
	themesWindow.BorderSizePixel = 0; themesWindow.Parent = screenGui
	Instance.new("UICorner", themesWindow).CornerRadius = UDim.new(0, 14)
	local twStroke = Instance.new("UIStroke"); twStroke.Color = currentTheme.stroke; twStroke.Thickness = 2; twStroke.Parent = themesWindow

	local twClose = Instance.new("TextButton")
	twClose.Size = UDim2.new(0, 30, 0, 30); twClose.Position = UDim2.new(1, -8, 0, 8)
	twClose.AnchorPoint = Vector2.new(1, 0); twClose.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
	twClose.BorderSizePixel = 0; twClose.Text = "✕"; twClose.TextColor3 = Color3.fromRGB(255, 255, 255)
	twClose.TextSize = 16; twClose.Font = Enum.Font.GothamBold; twClose.Parent = themesWindow
	Instance.new("UICorner", twClose).CornerRadius = UDim.new(0, 8)
	twClose.MouseButton1Click:Connect(function() themesWindow:Destroy(); themesWindow = nil end)

	local twTitle = Instance.new("TextLabel")
	twTitle.Size = UDim2.new(1, -50, 0, 30); twTitle.Position = UDim2.new(0, 16, 0, 10)
	twTitle.BackgroundTransparency = 1; twTitle.Text = "🎨 Themes"
	twTitle.TextColor3 = currentTheme.text; twTitle.TextSize = 18
	twTitle.Font = Enum.Font.GothamBold; twTitle.TextXAlignment = Enum.TextXAlignment.Left
	twTitle.Parent = themesWindow

	local twScroll = Instance.new("ScrollingFrame")
	twScroll.Size = UDim2.new(1, -16, 1, -50); twScroll.Position = UDim2.new(0, 8, 0, 44)
	twScroll.BackgroundTransparency = 1; twScroll.ScrollBarThickness = 3
	twScroll.CanvasSize = UDim2.new(0, 0, 0, 0); twScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	twScroll.Parent = themesWindow

	local twGrid = Instance.new("UIGridLayout")
	twGrid.CellSize = UDim2.new(0, 75, 0, 36); twGrid.CellPadding = UDim2.new(0, 6, 0, 6)
	twGrid.SortOrder = Enum.SortOrder.LayoutOrder; twGrid.Parent = twScroll

	local order = {"Red","Orange","Yellow","Green","Blue","Purple","Pink","Brown","Black","White","Grey"}
	for i, name in order do
		local t = themes[name]
		local tb = Instance.new("TextButton")
		tb.Size = UDim2.new(0, 75, 0, 36); tb.BackgroundColor3 = t.primary
		tb.BorderSizePixel = 0; tb.Text = name; tb.TextSize = 11
		tb.Font = Enum.Font.GothamBold; tb.LayoutOrder = i
		tb.TextColor3 = (name == "Black" or name == "Brown" or name == "Purple" or name == "Blue" or name == "Red") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(20, 20, 20)
		tb.Parent = twScroll
		Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 8)
		tb.MouseButton1Click:Connect(function()
			setTheme(name)
			-- update theme window itself
			themesWindow.BackgroundColor3 = currentTheme.bg
			twStroke.Color = currentTheme.stroke
			twTitle.TextColor3 = currentTheme.text
		end)
	end
end)

-- ============================================
-- ABILITY BUTTON CREATOR
-- ============================================
local abilityButtons = {}

local function createAbilityButton(name, color, description, keybind, layoutOrder, note, rainbowName, opText, monochromeName)
	local totalHeight = 60
	if note then totalHeight = 78 end
	if opText then totalHeight += 16 end

	local btn = Instance.new("TextButton")
	btn.Name = name; btn.Size = UDim2.new(1, 0, 0, totalHeight)
	btn.BackgroundColor3 = Color3.fromRGB(35, 35, 55); btn.BorderSizePixel = 0
	btn.Text = ""; btn.LayoutOrder = layoutOrder; btn.AutoButtonColor = true
	btn.Parent = scrollFrameObj
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = color; btnStroke.Thickness = 1.5; btnStroke.Transparency = 0.4
	btnStroke.Parent = btn

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"; nameLabel.Size = UDim2.new(1, -10, 0, 22)
	nameLabel.Position = UDim2.new(0, 8, 0, 4); nameLabel.BackgroundTransparency = 1
	nameLabel.Text = name .. "  [" .. keybind .. "]"; nameLabel.TextColor3 = color
	nameLabel.TextSize = 14; nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left; nameLabel.Parent = btn

	if rainbowName then
		task.spawn(function()
			local t = 0
			while btn and btn.Parent do
				t += 0.02; nameLabel.TextColor3 = getRainbowColor(t); btnStroke.Color = getRainbowColor(t + 0.3); task.wait(0.03)
			end
		end)
	end

	if monochromeName then
		task.spawn(function()
			local t = 0
			while btn and btn.Parent do
				t += 0.03; nameLabel.TextColor3 = getMonochromeColor(t); btnStroke.Color = getMonochromeColor(t + 1); task.wait(0.03)
			end
		end)
	end

	local yOffset = 24

	if opText then
		local opLabel = Instance.new("TextLabel")
		opLabel.Size = UDim2.new(0, 40, 0, 16); opLabel.Position = UDim2.new(0, 8, 0, yOffset)
		opLabel.BackgroundTransparency = 1; opLabel.Text = "OP!"; opLabel.TextSize = 13
		opLabel.Font = Enum.Font.GothamBold; opLabel.TextXAlignment = Enum.TextXAlignment.Left; opLabel.Parent = btn
		task.spawn(function()
			local t = 0
			while opLabel and opLabel.Parent do t += 0.03; opLabel.TextColor3 = getRainbowColor(t); task.wait(0.03) end
		end)
		yOffset += 16
	end

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, -10, 0, 16); descLabel.Position = UDim2.new(0, 8, 0, yOffset)
	descLabel.BackgroundTransparency = 1; descLabel.Text = description
	descLabel.TextColor3 = Color3.fromRGB(150, 150, 170); descLabel.TextSize = 11
	descLabel.Font = Enum.Font.Gotham; descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextWrapped = true; descLabel.Parent = btn
	yOffset += 16

	if note then
		local noteLabel = Instance.new("TextLabel")
		noteLabel.Size = UDim2.new(1, -10, 0, 14); noteLabel.Position = UDim2.new(0, 8, 0, yOffset)
		noteLabel.BackgroundTransparency = 1; noteLabel.Text = "📌 " .. note
		noteLabel.TextColor3 = Color3.fromRGB(255, 220, 100); noteLabel.TextSize = 10
		noteLabel.Font = Enum.Font.GothamMedium; noteLabel.TextXAlignment = Enum.TextXAlignment.Left
		noteLabel.TextWrapped = true; noteLabel.Parent = btn
	end

	local cdBarBg = Instance.new("Frame")
	cdBarBg.Size = UDim2.new(1, -16, 0, 4); cdBarBg.Position = UDim2.new(0, 8, 1, -10)
	cdBarBg.BackgroundColor3 = Color3.fromRGB(20, 20, 30); cdBarBg.BorderSizePixel = 0; cdBarBg.Parent = btn
	Instance.new("UICorner", cdBarBg).CornerRadius = UDim.new(0, 2)

	local cdBarFill = Instance.new("Frame")
	cdBarFill.Size = UDim2.new(1, 0, 1, 0); cdBarFill.BackgroundColor3 = color
	cdBarFill.BorderSizePixel = 0; cdBarFill.Parent = cdBarBg
	Instance.new("UICorner", cdBarFill).CornerRadius = UDim.new(0, 2)

	if rainbowName then
		task.spawn(function() local t = 0; while cdBarFill and cdBarFill.Parent do t += 0.02; cdBarFill.BackgroundColor3 = getRainbowColor(t); task.wait(0.03) end end)
	end
	if monochromeName then
		task.spawn(function() local t = 0; while cdBarFill and cdBarFill.Parent do t += 0.03; cdBarFill.BackgroundColor3 = getMonochromeColor(t); task.wait(0.03) end end)
	end

	table.insert(abilityButtons, {btn = btn, btnStroke = btnStroke, nameLabel = nameLabel, descLabel = descLabel, cdBarBg = cdBarBg})

	registerThemeable(function(theme)
		if not rainbowName and not monochromeName then
			-- keep original color for special buttons
		end
		btn.BackgroundColor3 = Color3.new(theme.bg.R + 0.06, theme.bg.G + 0.06, theme.bg.B + 0.1)
		descLabel.TextColor3 = Color3.fromRGB(
			math.clamp(theme.text.R * 255 * 0.7, 0, 255),
			math.clamp(theme.text.G * 255 * 0.7, 0, 255),
			math.clamp(theme.text.B * 255 * 0.7, 0, 255)
		)
	end)

	return btn, cdBarFill, btnStroke
end

-- Create all ability buttons
local platformBtn, platformCdBar = createAbilityButton("Platform", Color3.fromRGB(0, 130, 255), "Spawns a platform that follows you", "Q", 1)
local lungeBtn, lungeCdBar = createAbilityButton("Lunge", Color3.fromRGB(255, 80, 50), "Dash 100 studs at 1.7x speed", "E", 2)
local megaJumpBtn, megaJumpCdBar, megaJumpStroke = createAbilityButton("Mega Jump", Color3.fromRGB(50, 255, 100), "6x jump power + reduced gravity", "R", 3, "Perfect to beat a average tower!")
local shockwaveBtn, shockwaveCdBar = createAbilityButton("Shockwave Travel", Color3.fromRGB(160, 50, 255), "c00lkidd wannabe(s) will LOVE THIS!", "T", 4)
local fusionBtn, fusionCdBar = createAbilityButton("Fusion Leveler", Color3.fromRGB(255, 200, 50), "Speed x1.5, Jump=110, Gravity 50% for 15s", "F", 5)
local rainbowBtn, rainbowCdBar = createAbilityButton("Rainbow Locator", Color3.fromRGB(255, 0, 0), "Select a destination and travel there!", "G", 6, "Go to destinations like never before!", true, true)
local immortalBtn, immortalCdBar = createAbilityButton("Immortality Shield", Color3.fromRGB(180, 180, 180), "A tool to make you temporairly immortal", "H", 7, nil, false, false, true)
local miniDashBtn, miniDashCdBar = createAbilityButton("Mini Dash", Color3.fromRGB(100, 180, 255), "Quick 20-stud forward dash", "C", 8)

-- ============================================
-- COOLDOWN HELPER
-- ============================================
local function animateCooldown(bar, duration)
	bar.Size = UDim2.new(0, 0, 1, 0)
	TweenService:Create(bar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(1, 0, 1, 0)}):Play()
end

-- ============================================
-- DASH VFX
-- ============================================
local function createDashVFX(character, color)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end
	local c = color or Color3.fromRGB(0, 170, 255)
	local a0 = Instance.new("Attachment"); a0.Position = Vector3.new(0, 1, 0); a0.Parent = rootPart
	local a1 = Instance.new("Attachment"); a1.Position = Vector3.new(0, -1, 0); a1.Parent = rootPart
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0; trail.Attachment1 = a1; trail.Lifetime = 0.2; trail.MinLength = 0.1; trail.FaceCamera = true
	trail.Color = ColorSequence.new(c)
	trail.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1)})
	trail.WidthScale = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})
	trail.Parent = rootPart
	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(c)
	particles.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0)})
	particles.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1)})
	particles.Lifetime = NumberRange.new(0.15, 0.3); particles.Rate = 100
	particles.Speed = NumberRange.new(5, 15); particles.SpreadAngle = Vector2.new(30, 30); particles.Parent = rootPart
	return {cleanup = function(d) local dt2 = d or 0.35; task.delay(dt2, function() particles.Rate = 0 end); task.delay(dt2 + 0.5, function() trail:Destroy(); particles:Destroy(); a0:Destroy(); a1:Destroy() end) end}
end

-- ============================================
-- GENERIC DASH FUNCTION (used by Jump Dash and Mini Dash)
-- ============================================
local function genericDash(distance, duration, color, soundSpeed)
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart or humanoid.Health <= 0 then return end

	local moveDir = humanoid.MoveDirection
	local dashDir
	if moveDir.Magnitude > 0.1 then dashDir = moveDir.Unit else dashDir = rootPart.CFrame.LookVector end
	dashDir = Vector3.new(dashDir.X, 0, dashDir.Z)
	if dashDir.Magnitude < 0.1 then dashDir = Vector3.new(rootPart.CFrame.LookVector.X, 0, rootPart.CFrame.LookVector.Z) end
	dashDir = dashDir.Unit

	local vfx = createDashVFX(character, color)
	playSound(rootPart, "rbxassetid://7471006063", 0.5, soundSpeed or 1.3)
	rootPart.CFrame = CFrame.new(rootPart.Position, rootPart.Position + dashDir)

	local att = Instance.new("Attachment"); att.Parent = rootPart
	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = att; lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector; lv.MaxForce = 50000
	lv.VectorVelocity = dashDir * (distance / duration); lv.Parent = rootPart
	local ag = Instance.new("LinearVelocity")
	ag.Attachment0 = att; ag.RelativeTo = Enum.ActuatorRelativeTo.World
	ag.VelocityConstraintMode = Enum.VelocityConstraintMode.Line; ag.LineDirection = Vector3.yAxis
	ag.MaxForce = 5000; ag.LineVelocity = 0; ag.Parent = rootPart

	task.delay(duration, function()
		while true do
			if not rootPart or not rootPart.Parent then break end
			if humanoid.Health <= 0 then break end
			if not isVoidBelow(rootPart.Position) or isOnCollidableSurface(rootPart) then break end
			local avoidDir = checkHeadObstacle(rootPart)
			if avoidDir and lv.Parent then
				lv.VectorVelocity = (dashDir + avoidDir * 0.5).Unit * lv.VectorVelocity.Magnitude
			end
			task.wait(0.05)
		end
		if lv.Parent then lv:Destroy() end; if ag.Parent then ag:Destroy() end; if att.Parent then att:Destroy() end
		if vfx then vfx.cleanup(0) end
		if rootPart and rootPart.Parent then
			local sa = Instance.new("Attachment"); sa.Parent = rootPart
			local sv = Instance.new("LinearVelocity")
			sv.Attachment0 = sa; sv.RelativeTo = Enum.ActuatorRelativeTo.World
			sv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector; sv.MaxForce = 20000
			sv.VectorVelocity = dashDir * 10; sv.Parent = rootPart
			task.spawn(function()
				for i = 1, 6 do task.wait(0.03); if sv.Parent then sv.VectorVelocity *= 0.5 end end
				if sv.Parent then sv:Destroy() end; if sa.Parent then sa:Destroy() end
			end)
		end
	end)
end

-- ============================================
-- JUMP DASH
-- ============================================
local function performDash()
	if not dashEnabled or not canDash or isDashing then return end
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or humanoid.FloorMaterial ~= Enum.Material.Air then return end
	isDashing = true; canDash = false
	genericDash(DASH_DISTANCE, DASH_DURATION, Color3.fromRGB(0, 170, 255), 1.3)
	task.spawn(function() task.wait(DASH_DURATION + 0.1); isDashing = false end)
	dashCooldownBar.Size = UDim2.new(0, 0, 0, 3)
	TweenService:Create(dashCooldownBar, TweenInfo.new(DASH_COOLDOWN, Enum.EasingStyle.Linear), {Size = UDim2.new(1, 0, 0, 3)}):Play()
	task.spawn(function() task.wait(DASH_COOLDOWN); canDash = true end)
end

-- ============================================
-- MINI DASH
-- ============================================
local function activateMiniDash()
	if not canMiniDash then return end
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	canMiniDash = false
	genericDash(MINI_DASH_DISTANCE, MINI_DASH_DURATION, Color3.fromRGB(100, 180, 255), 1.6)
	animateCooldown(miniDashCdBar, MINI_DASH_COOLDOWN)
	task.spawn(function() task.wait(MINI_DASH_COOLDOWN); canMiniDash = true end)
end

-- ============================================
-- PLATFORM
-- ============================================
local function activatePlatform()
	if not canPlatform or platformActive then return end
	local character = player.Character; if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart or humanoid.Health <= 0 then return end
	platformActive = true; canPlatform = false
	local platform = Instance.new("Part")
	platform.Name = "AbilityPlatform"; platform.Size = PLATFORM_SIZE; platform.Material = Enum.Material.Neon
	platform.Color = Color3.fromRGB(0, 130, 255); platform.Transparency = 0.5; platform.Anchored = true
	platform.CanCollide = true; platform.Position = rootPart.Position - Vector3.new(0, 4, 0); platform.Parent = workspace
	local sparkles = Instance.new("ParticleEmitter"); sparkles.Color = ColorSequence.new(Color3.fromRGB(255, 50, 50))
	sparkles.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(0.5, 0.6), NumberSequenceKeypoint.new(1, 0)})
	sparkles.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)})
	sparkles.Lifetime = NumberRange.new(0.5, 1.2); sparkles.Rate = 40; sparkles.Speed = NumberRange.new(2, 6)
	sparkles.SpreadAngle = Vector2.new(180, 180); sparkles.LightEmission = 0.8
	sparkles.Texture = "rbxassetid://6490035152"; sparkles.Parent = platform
	currentPlatform = platform; playSound(rootPart, "rbxassetid://3199270999", 0.4, 1.2)
	platformFollowConn = RunService.Heartbeat:Connect(function()
		if not platform or not platform.Parent then if platformFollowConn then platformFollowConn:Disconnect(); platformFollowConn = nil end; return end
		if not rootPart or not rootPart.Parent then return end
		platform.Position = platform.Position:Lerp(Vector3.new(rootPart.Position.X, rootPart.Position.Y - 4, rootPart.Position.Z), 0.2)
	end)
	task.spawn(function()
		task.wait(PLATFORM_DURATION - 2)
		if platform and platform.Parent then for i = 1, 20 do task.wait(0.1); if platform and platform.Parent then platform.Transparency = 0.5 + (i/20)*0.5 end end end
		if platformFollowConn then platformFollowConn:Disconnect(); platformFollowConn = nil end
		if platform and platform.Parent then platform:Destroy() end
		currentPlatform = nil; platformActive = false
		animateCooldown(platformCdBar, PLATFORM_COOLDOWN); task.wait(PLATFORM_COOLDOWN); canPlatform = true
	end)
end

-- ============================================
-- LUNGE
-- ============================================
local function activateLunge()
	if not canLunge or isLunging then return end
	local character = player.Character; if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart or humanoid.Health <= 0 then return end
	isLunging = true; canLunge = false
	local moveDir = humanoid.MoveDirection; local lungeDir
	if moveDir.Magnitude > 0.1 then lungeDir = moveDir.Unit else lungeDir = rootPart.CFrame.LookVector end
	lungeDir = Vector3.new(lungeDir.X, 0, lungeDir.Z)
	if lungeDir.Magnitude < 0.1 then lungeDir = Vector3.new(rootPart.CFrame.LookVector.X, 0, rootPart.CFrame.LookVector.Z) end
	lungeDir = lungeDir.Unit
	local lungeSpeed = (DASH_DISTANCE / DASH_DURATION) * LUNGE_SPEED_MULT
	local lungeDuration = LUNGE_DISTANCE / lungeSpeed
	local vfx = createDashVFX(character, Color3.fromRGB(255, 80, 50))
	playSound(rootPart, "rbxassetid://7471006063", 0.7, 0.8)
	rootPart.CFrame = CFrame.new(rootPart.Position, rootPart.Position + lungeDir)
	local att = Instance.new("Attachment"); att.Parent = rootPart
	local lv = Instance.new("LinearVelocity"); lv.Attachment0 = att; lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector; lv.MaxForce = 80000
	lv.VectorVelocity = lungeDir * lungeSpeed; lv.Parent = rootPart
	local ag = Instance.new("LinearVelocity"); ag.Attachment0 = att; ag.RelativeTo = Enum.ActuatorRelativeTo.World
	ag.VelocityConstraintMode = Enum.VelocityConstraintMode.Line; ag.LineDirection = Vector3.yAxis; ag.MaxForce = 8000; ag.LineVelocity = 0; ag.Parent = rootPart
	task.spawn(function() for i = 1, 10 do if not isLunging then break end; humanoid.CameraOffset = Vector3.new(math.random(-10,10)/80, math.random(-10,10)/80, 0); task.wait(0.05) end; humanoid.CameraOffset = Vector3.zero end)
	task.delay(lungeDuration, function()
		while true do
			if not rootPart or not rootPart.Parent or humanoid.Health <= 0 then break end
			if isOnCollidableSurface(rootPart) or not isVoidBelow(rootPart.Position) then break end
			local avoidDir = checkHeadObstacle(rootPart)
			if avoidDir and lv.Parent then lv.VectorVelocity = (lungeDir + avoidDir * 0.5).Unit * lv.VectorVelocity.Magnitude end
			task.wait(0.05)
		end
		if lv.Parent then lv:Destroy() end; if ag.Parent then ag:Destroy() end; if att.Parent then att:Destroy() end
		isLunging = false; if vfx then vfx.cleanup(0) end
		if rootPart and rootPart.Parent then
			local sa = Instance.new("Attachment"); sa.Parent = rootPart
			local sv = Instance.new("LinearVelocity"); sv.Attachment0 = sa; sv.RelativeTo = Enum.ActuatorRelativeTo.World
			sv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector; sv.MaxForce = 30000; sv.VectorVelocity = lungeDir * 20; sv.Parent = rootPart
			task.spawn(function() for i = 1, 10 do task.wait(0.03); if sv.Parent then sv.VectorVelocity *= 0.55 end end; if sv.Parent then sv:Destroy() end; if sa.Parent then sa:Destroy() end end)
		end
		animateCooldown(lungeCdBar, LUNGE_COOLDOWN); task.wait(LUNGE_COOLDOWN); canLunge = true
	end)
end

-- ============================================
-- MEGA JUMP (compact)
-- ============================================
local function createShockwave(position, color)
	local c = color or Color3.fromRGB(50, 255, 100)
	local ring = Instance.new("Part"); ring.Anchored = true; ring.CanCollide = false; ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.5, 4, 4); ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	ring.Material = Enum.Material.Neon; ring.Color = c; ring.Transparency = 0.3; ring.Parent = workspace
	local t = TweenService:Create(ring, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(0.5, 60, 60), Transparency = 1})
	t:Play(); t.Completed:Connect(function() ring:Destroy() end)
end

local function createPillar(position)
	local pillar = Instance.new("Part"); pillar.Anchored = true; pillar.CanCollide = false
	pillar.Size = Vector3.new(5, 0, 5); pillar.CFrame = CFrame.new(position)
	pillar.Material = Enum.Material.Neon; pillar.Color = Color3.fromRGB(50, 255, 100); pillar.Transparency = 0.5; pillar.Parent = workspace
	TweenService:Create(pillar, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(5, 80, 5), CFrame = CFrame.new(position + Vector3.new(0, 40, 0))}):Play()
	task.delay(0.6, function() local f = TweenService:Create(pillar, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {Transparency = 1, Size = Vector3.new(2, 80, 2)}); f:Play(); f.Completed:Connect(function() pillar:Destroy() end) end)
end

local function createRainbowShockwave(position)
	local ring = Instance.new("Part"); ring.Anchored = true; ring.CanCollide = false; ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.5, 4, 4); ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	ring.Material = Enum.Material.Neon; ring.Transparency = 0.2; ring.Parent = workspace
	task.spawn(function() local st = tick(); while ring and ring.Parent and (tick()-st) < 1 do ring.Color = getRainbowColor((tick()-st)*2); task.wait() end end)
	local t = TweenService:Create(ring, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(0.5, 80, 80), Transparency = 1})
	t:Play(); t.Completed:Connect(function() ring:Destroy() end)
end

local function createRainbowPillar(position)
	local pillar = Instance.new("Part"); pillar.Anchored = true; pillar.CanCollide = false
	pillar.Size = Vector3.new(5, 0, 5); pillar.CFrame = CFrame.new(position); pillar.Material = Enum.Material.Neon; pillar.Transparency = 0.4; pillar.Parent = workspace
	task.spawn(function() local st = tick(); while pillar and pillar.Parent and (tick()-st) < 2 do pillar.Color = getRainbowColor((tick()-st)*1.5); task.wait() end end)
	TweenService:Create(pillar, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(5, 100, 5), CFrame = CFrame.new(position + Vector3.new(0, 50, 0))}):Play()
	task.delay(0.8, function() local f = TweenService:Create(pillar, TweenInfo.new(0.8, Enum.EasingStyle.Quad), {Transparency = 1, Size = Vector3.new(2, 100, 2)}); f:Play(); f.Completed:Connect(function() pillar:Destroy() end) end)
end

local function activateMegaJump()
	if not canMegaJump then return end
	megaJumpArmed = not megaJumpArmed
	if megaJumpArmed then
		megaJumpStroke.Color = Color3.fromRGB(150, 255, 150); megaJumpStroke.Thickness = 3
		task.spawn(function() while megaJumpArmed do if megaJumpStroke then TweenService:Create(megaJumpStroke, TweenInfo.new(0.5), {Transparency = 0.6}):Play() end; task.wait(0.5); if megaJumpArmed and megaJumpStroke then TweenService:Create(megaJumpStroke, TweenInfo.new(0.5), {Transparency = 0}):Play() end; task.wait(0.5) end end)
	else
		megaJumpStroke.Color = Color3.fromRGB(50, 255, 100); megaJumpStroke.Thickness = 1.5; megaJumpStroke.Transparency = 0.4
	end
end

local function performMegaJump()
	if not megaJumpArmed or not canMegaJump then return end
	local character = player.Character; if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid"); local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart or humanoid.Health <= 0 then return end
	megaJumpArmed = false; canMegaJump = false; isMegaJumping = true
	megaJumpStroke.Color = Color3.fromRGB(50, 255, 100); megaJumpStroke.Thickness = 1.5; megaJumpStroke.Transparency = 0.4
	createShockwave(rootPart.Position); createPillar(rootPart.Position); playSound(rootPart, "rbxassetid://3199270999", 0.8, 0.7)
	local njp = humanoid.JumpPower; if njp == 0 then njp = 50 end
	local att = Instance.new("Attachment"); att.Parent = rootPart
	local jv = Instance.new("LinearVelocity"); jv.Attachment0 = att; jv.RelativeTo = Enum.ActuatorRelativeTo.World
	jv.VelocityConstraintMode = Enum.VelocityConstraintMode.Line; jv.LineDirection = Vector3.yAxis; jv.MaxForce = 80000; jv.LineVelocity = njp * MEGA_JUMP_MULT; jv.Parent = rootPart
	task.delay(0.15, function() if jv.Parent then jv:Destroy() end; if att.Parent then att:Destroy() end end)
	megaJumpGravityActive = true; local savedGrav = workspace.Gravity; workspace.Gravity = savedGrav * MEGA_JUMP_GRAVITY_SCALE
	local jp = Instance.new("ParticleEmitter"); jp.Color = ColorSequence.new(Color3.fromRGB(50, 255, 100))
	jp.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0)})
	jp.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1)})
	jp.Lifetime = NumberRange.new(0.3, 0.8); jp.Rate = 60; jp.Speed = NumberRange.new(1, 4); jp.SpreadAngle = Vector2.new(180, 180); jp.LightEmission = 0.6; jp.Parent = rootPart
	task.spawn(function() task.wait(0.3); while true do if not rootPart or not rootPart.Parent or humanoid.Health <= 0 then break end; local s = humanoid:GetState(); if s == Enum.HumanoidStateType.Landed or s == Enum.HumanoidStateType.Running then break end; task.wait(0.05) end
		if megaJumpGravityActive then workspace.Gravity = savedGrav; megaJumpGravityActive = false end; isMegaJumping = false
		if rootPart and rootPart.Parent then createShockwave(rootPart.Position); playSound(rootPart, "rbxassetid://3199270999", 0.4, 1.5) end
		jp.Rate = 0; task.delay(1, function() if jp.Parent then jp:Destroy() end end); animateCooldown(megaJumpCdBar, MEGA_JUMP_COOLDOWN); task.wait(MEGA_JUMP_COOLDOWN); canMegaJump = true end)
end

-- ============================================
-- SHOCKWAVE TRAVEL (compact)
-- ============================================
local function cleanupShockwaveTravel()
	shockwaveEmergencyStop = true; isShockwaveTraveling = false
	for _, part in shockwaveTunnelParts do if part and part.Parent then part:Destroy() end end; shockwaveTunnelParts = {}
	local character = player.Character
	if character then local rp = character:FindFirstChild("HumanoidRootPart"); if rp then for _, c in rp:GetChildren() do if c.Name == "ShockwaveVel" or c.Name == "ShockwaveAntiGrav" or c.Name == "ShockwaveAttach" then c:Destroy() end end end end
end

local function activateShockwaveTravel()
	if not canShockwaveTravel or isShockwaveTraveling then return end
	local character = player.Character; if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid"); local rootPart = character:FindFirstChild("HumanoidRootPart"); local head = character:FindFirstChild("Head")
	if not humanoid or not rootPart or not head or humanoid.Health <= 0 then return end
	canShockwaveTravel = false; shockwaveEmergencyStop = false
	local moveDir = humanoid.MoveDirection; local travelDir
	if moveDir.Magnitude > 0.1 then travelDir = moveDir.Unit else travelDir = rootPart.CFrame.LookVector end
	travelDir = Vector3.new(travelDir.X, 0, travelDir.Z); if travelDir.Magnitude < 0.1 then travelDir = Vector3.new(rootPart.CFrame.LookVector.X, 0, rootPart.CFrame.LookVector.Z) end; travelDir = travelDir.Unit
	for i = 1, 10 do if shockwaveEmergencyStop then break end
		local sphere = Instance.new("Part"); sphere.Shape = Enum.PartType.Ball; sphere.Anchored = true; sphere.CanCollide = false; sphere.Size = Vector3.new(3,3,3); sphere.Position = head.Position; sphere.Material = Enum.Material.Neon; sphere.Color = Color3.fromRGB(160,50,255); sphere.Transparency = 0.3; sphere.Parent = workspace
		playSound(rootPart, "rbxassetid://3199270999", 0.3+(i*0.05), 0.8+(i*0.15)); local es = 8+(i*3)
		local tw = TweenService:Create(sphere, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(es,es,es), Transparency = 1}); tw:Play(); tw.Completed:Connect(function() sphere:Destroy() end)
		local d = 0.4-(i*0.035); if d < 0.05 then d = 0.05 end; task.wait(d) end
	if shockwaveEmergencyStop then animateCooldown(shockwaveCdBar, SHOCKWAVE_TRAVEL_COOLDOWN); task.wait(SHOCKWAVE_TRAVEL_COOLDOWN); canShockwaveTravel = true; return end
	local cube = Instance.new("Part"); cube.Anchored = true; cube.CanCollide = false; cube.Size = Vector3.new(4,4,4); cube.Position = head.Position; cube.Material = Enum.Material.Neon; cube.Color = Color3.fromRGB(160,50,255); cube.Transparency = 0.3; cube.Parent = workspace
	playSound(rootPart, "rbxassetid://3199270999", 1, 0.5)
	task.spawn(function() local st = tick(); while tick()-st < 1 do if cube and cube.Parent then cube.CFrame = cube.CFrame * CFrame.Angles(0.1,0.1,0.05) end; task.wait() end end)
	TweenService:Create(cube, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(30,30,30), Transparency = 1}):Play()
	task.delay(1.1, function() if cube and cube.Parent then cube:Destroy() end end); task.wait(0.5)
	if shockwaveEmergencyStop then animateCooldown(shockwaveCdBar, SHOCKWAVE_TRAVEL_COOLDOWN); task.wait(SHOCKWAVE_TRAVEL_COOLDOWN); canShockwaveTravel = true; return end
	isShockwaveTraveling = true; rootPart.CFrame = CFrame.new(rootPart.Position, rootPart.Position + travelDir)
	local sAtt = Instance.new("Attachment"); sAtt.Name = "ShockwaveAttach"; sAtt.Parent = rootPart
	local sVel = Instance.new("LinearVelocity"); sVel.Name = "ShockwaveVel"; sVel.Attachment0 = sAtt; sVel.RelativeTo = Enum.ActuatorRelativeTo.World; sVel.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector; sVel.MaxForce = 100000; sVel.VectorVelocity = travelDir * SHOCKWAVE_TRAVEL_SPEED; sVel.Parent = rootPart
	local sAG = Instance.new("LinearVelocity"); sAG.Name = "ShockwaveAntiGrav"; sAG.Attachment0 = sAtt; sAG.RelativeTo = Enum.ActuatorRelativeTo.World; sAG.VelocityConstraintMode = Enum.VelocityConstraintMode.Line; sAG.LineDirection = Vector3.yAxis; sAG.MaxForce = 10000; sAG.LineVelocity = 0; sAG.Parent = rootPart
	local tp = Instance.new("ParticleEmitter"); tp.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(160,50,255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(100,20,200))}); tp.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.8), NumberSequenceKeypoint.new(1,0)}); tp.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.3), NumberSequenceKeypoint.new(1,1)}); tp.Lifetime = NumberRange.new(0.2,0.5); tp.Rate = 150; tp.Speed = NumberRange.new(8,20); tp.SpreadAngle = Vector2.new(15,15); tp.LightEmission = 0.8; tp.Parent = head
	task.spawn(function()
		local travelStart = tick(); local lastRing = 0
		while isShockwaveTraveling and not shockwaveEmergencyStop do
			if not rootPart or not rootPart.Parent or humanoid.Health <= 0 then break end
			local avoidDir = checkHeadObstacle(rootPart)
			if avoidDir and sVel.Parent then sVel.VectorVelocity = (travelDir + avoidDir * 0.7).Unit * sVel.VectorVelocity.Magnitude end
			if tick() - lastRing > 0.08 then lastRing = tick()
				local ring = Instance.new("Part"); ring.Name = "TunnelRing"; ring.Anchored = true; ring.CanCollide = false; ring.Shape = Enum.PartType.Cylinder; ring.Size = Vector3.new(0.3,14,14)
				ring.CFrame = CFrame.lookAt(head.Position + travelDir * (15+math.random(0,10)) + Vector3.new(math.random(-20,20)/10, math.random(-20,20)/10, math.random(-20,20)/10), head.Position + travelDir * 30) * CFrame.Angles(0, math.rad(90), 0)
				ring.Material = Enum.Material.Neon; ring.Color = Color3.fromRGB(160,50,255); ring.Transparency = 0.4; ring.Parent = workspace; table.insert(shockwaveTunnelParts, ring)
				task.delay(1.5, function() if ring and ring.Parent then TweenService:Create(ring, TweenInfo.new(1), {Transparency = 1, Size = Vector3.new(0.3,20,20)}):Play(); task.delay(1.1, function() ring:Destroy(); local idx = table.find(shockwaveTunnelParts, ring); if idx then table.remove(shockwaveTunnelParts, idx) end end) end end)
			end
			if tick() - travelStart >= SHOCKWAVE_TRAVEL_DURATION then break end; task.wait()
		end
		isShockwaveTraveling = false
		if rootPart and rootPart.Parent and not shockwaveEmergencyStop then
			if isVoidBelow(rootPart.Position) and not isOnCollidableSurface(rootPart) then
				local _, np = findNearestCollidablePart(rootPart.Position); if np then
					local dt2 = (np - rootPart.Position); if dt2.Magnitude > 1 then local dirTo = dt2.Unit; local tTime = math.clamp(dt2.Magnitude / SHOCKWAVE_TRAVEL_SPEED, 0.5, 5)
					if sVel and sVel.Parent then sVel.VectorVelocity = dirTo * SHOCKWAVE_TRAVEL_SPEED end; local rs = tick()
					while true do if not rootPart or not rootPart.Parent then break end; if (np - rootPart.Position).Magnitude < 8 or isOnCollidableSurface(rootPart) then break end; if tick()-rs > tTime+2 then break end; task.wait(0.05) end end end end
		end
		if sVel and sVel.Parent then sVel:Destroy() end; if sAG and sAG.Parent then sAG:Destroy() end; if sAtt and sAtt.Parent then sAtt:Destroy() end
		tp.Rate = 0; task.delay(1, function() if tp.Parent then tp:Destroy() end end)
		for _, part in shockwaveTunnelParts do if part and part.Parent then part:Destroy() end end; shockwaveTunnelParts = {}
		if rootPart and rootPart.Parent then createShockwave(rootPart.Position, Color3.fromRGB(160,50,255)); playSound(rootPart, "rbxassetid://3199270999", 0.6, 1.2) end
		shockwaveEmergencyStop = false; animateCooldown(shockwaveCdBar, SHOCKWAVE_TRAVEL_COOLDOWN); task.wait(SHOCKWAVE_TRAVEL_COOLDOWN); canShockwaveTravel = true
	end)
end

-- ============================================
-- FUSION LEVELER
-- ============================================
local function activateFusion()
	if not canFusion or isFusionActive then return end
	local character = player.Character; if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid"); local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart or humanoid.Health <= 0 then return end
	isFusionActive = true; canFusion = false
	local savedWS = humanoid.WalkSpeed; local savedGrav = workspace.Gravity
	local savedJP = humanoid.JumpPower; local savedJH = humanoid.JumpHeight; local savedUJP = humanoid.UseJumpPower
	humanoid.UseJumpPower = true; humanoid.JumpPower = FUSION_JUMP_POWER_TARGET
	humanoid.WalkSpeed = savedWS * FUSION_SPEED_MULT; workspace.Gravity = savedGrav * FUSION_GRAVITY_MULT
	local jumpBoostConn = humanoid.StateChanged:Connect(function(_, ns)
		if not isFusionActive then return end
		if ns == Enum.HumanoidStateType.Jumping then
			local att = Instance.new("Attachment"); att.Parent = rootPart
			local jv = Instance.new("LinearVelocity"); jv.Attachment0 = att; jv.RelativeTo = Enum.ActuatorRelativeTo.World
			jv.VelocityConstraintMode = Enum.VelocityConstraintMode.Line; jv.LineDirection = Vector3.yAxis; jv.MaxForce = 50000; jv.LineVelocity = 60; jv.Parent = rootPart
			task.delay(0.12, function() if jv.Parent then jv:Destroy() end; if att.Parent then att:Destroy() end end)
		end
	end)
	fusionJumpConn = jumpBoostConn
	playSound(rootPart, "rbxassetid://3199270999", 0.6, 1.0); createShockwave(rootPart.Position, Color3.fromRGB(255, 200, 50))
	local aura = Instance.new("ParticleEmitter"); aura.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255,200,50)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255,150,0))})
	aura.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.6), NumberSequenceKeypoint.new(0.5,1), NumberSequenceKeypoint.new(1,0)})
	aura.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.4), NumberSequenceKeypoint.new(1,1)}); aura.Lifetime = NumberRange.new(0.4,0.8); aura.Rate = 50; aura.Speed = NumberRange.new(2,5); aura.SpreadAngle = Vector2.new(180,180); aura.LightEmission = 0.7; aura.Parent = rootPart
	local light = Instance.new("PointLight"); light.Color = Color3.fromRGB(255,200,50); light.Brightness = 2; light.Range = 20; light.Parent = rootPart
	task.spawn(function() task.wait(FUSION_DURATION); isFusionActive = false
		if jumpBoostConn then jumpBoostConn:Disconnect() end; fusionJumpConn = nil
		if humanoid and humanoid.Parent then humanoid.WalkSpeed = savedWS; humanoid.UseJumpPower = savedUJP; humanoid.JumpPower = savedJP; humanoid.JumpHeight = savedJH end
		workspace.Gravity = savedGrav
		if rootPart and rootPart.Parent then createShockwave(rootPart.Position, Color3.fromRGB(255,200,50)); playSound(rootPart, "rbxassetid://3199270999", 0.4, 1.5) end
		aura.Rate = 0; task.delay(1, function() if aura.Parent then aura:Destroy() end; if light.Parent then light:Destroy() end end)
		animateCooldown(fusionCdBar, FUSION_COOLDOWN); task.wait(FUSION_COOLDOWN); canFusion = true end)
end

-- ============================================
-- IMMORTALITY SHIELD
-- ============================================
local function cleanupImmortality()
	isImmortal = false
	if immortalityShieldPart and immortalityShieldPart.Parent then immortalityShieldPart:Destroy() end; immortalityShieldPart = nil
	if immortalityFloorPart and immortalityFloorPart.Parent then immortalityFloorPart:Destroy() end; immortalityFloorPart = nil
	if immortalityFollowConn then immortalityFollowConn:Disconnect(); immortalityFollowConn = nil end
	if immortalityScreenGui and immortalityScreenGui.Parent then immortalityScreenGui:Destroy() end; immortalityScreenGui = nil
	-- remove forcefield
	local character = player.Character
	if character then
		for _, c in character:GetChildren() do if c.Name == "ImmortalityFF" then c:Destroy() end end
	end
end

local function activateImmortality()
	if not canImmortality or isImmortal then return end
	local character = player.Character; if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid"); local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart or humanoid.Health <= 0 then return end

	isImmortal = true; canImmortality = false

	-- ForceField for kill protection
	local ff = Instance.new("ForceField")
	ff.Name = "ImmortalityFF"; ff.Visible = false; ff.Parent = character

	-- save health and make effectively immortal
	savedImmortalityHealth = humanoid.MaxHealth

	-- shield bubble (visual)
	immortalityShieldPart = Instance.new("Part")
	immortalityShieldPart.Name = "ImmortalShield"; immortalityShieldPart.Shape = Enum.PartType.Ball
	immortalityShieldPart.Size = Vector3.new(12, 12, 12); immortalityShieldPart.Material = Enum.Material.ForceField
	immortalityShieldPart.Transparency = 0.6; immortalityShieldPart.CanCollide = false; immortalityShieldPart.Anchored = true
	immortalityShieldPart.Parent = workspace

	-- monochrome color cycle
	task.spawn(function()
		local t = 0
		while immortalityShieldPart and immortalityShieldPart.Parent do
			t += 0.02; immortalityShieldPart.Color = getMonochromeColor(t); task.wait(0.03)
		end
	end)

	-- anti-void floor (instant follow)
	immortalityFloorPart = Instance.new("Part")
	immortalityFloorPart.Name = "ImmortalFloor"; immortalityFloorPart.Size = Vector3.new(6, 1, 6)
	immortalityFloorPart.Material = Enum.Material.Neon; immortalityFloorPart.Transparency = 0.7
	immortalityFloorPart.CanCollide = true; immortalityFloorPart.Anchored = true
	immortalityFloorPart.Color = Color3.fromRGB(150, 150, 150); immortalityFloorPart.Parent = workspace

	task.spawn(function()
		local t = 0
		while immortalityFloorPart and immortalityFloorPart.Parent do
			t += 0.02; immortalityFloorPart.Color = getMonochromeColor(t + 0.5); task.wait(0.03)
		end
	end)

	-- follow connection (instant)
	immortalityFollowConn = RunService.Heartbeat:Connect(function()
		if not rootPart or not rootPart.Parent then return end
		if immortalityShieldPart and immortalityShieldPart.Parent then
			immortalityShieldPart.Position = rootPart.Position
		end
		if immortalityFloorPart and immortalityFloorPart.Parent then
			immortalityFloorPart.Position = Vector3.new(rootPart.Position.X, rootPart.Position.Y - 3.5, rootPart.Position.Z)
		end
		-- keep health full
		if humanoid and humanoid.Parent and isImmortal then
			if humanoid.Health < humanoid.MaxHealth then
				humanoid.Health = humanoid.MaxHealth
			end
		end
	end)

	playSound(rootPart, "rbxassetid://3199270999", 0.7, 0.8)
	createShockwave(rootPart.Position, Color3.fromRGB(200, 200, 200))

	-- screen text
	immortalityScreenGui = Instance.new("ScreenGui")
	immortalityScreenGui.Name = "ImmortalityText"; immortalityScreenGui.ResetOnSpawn = false
	immortalityScreenGui.Parent = player.PlayerGui

	local immortalLabel = Instance.new("TextLabel")
	immortalLabel.Size = UDim2.new(0, 500, 0, 40)
	immortalLabel.Position = UDim2.new(0.5, 0, 0.15, 0); immortalLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	immortalLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20); immortalLabel.BackgroundTransparency = 0.4
	immortalLabel.BorderSizePixel = 0; immortalLabel.TextSize = 16; immortalLabel.Font = Enum.Font.GothamBold
	immortalLabel.Parent = immortalityScreenGui
	Instance.new("UICorner", immortalLabel).CornerRadius = UDim.new(0, 10)

	-- monochrome text animation + countdown
	task.spawn(function()
		local t = 0
		local remaining = IMMORTALITY_DURATION
		while immortalLabel and immortalLabel.Parent and remaining > 0 do
			t += 0.03
			immortalLabel.TextColor3 = getMonochromeColor(t)
			immortalLabel.Text = "You are now effectively immortal for " .. math.ceil(remaining) .. " Seconds."
			remaining -= 0.05
			task.wait(0.05)
		end
	end)

	-- timer
	task.spawn(function()
		task.wait(IMMORTALITY_DURATION)
		cleanupImmortality()
		if rootPart and rootPart.Parent then
			createShockwave(rootPart.Position, Color3.fromRGB(200, 200, 200))
			playSound(rootPart, "rbxassetid://3199270999", 0.4, 1.5)
		end
		animateCooldown(immortalCdBar, IMMORTALITY_COOLDOWN)
		task.wait(IMMORTALITY_COOLDOWN); canImmortality = true
	end)
end

-- ============================================
-- RAINBOW LOCATOR (compact - same as V4)
-- ============================================
local freecamGui, freecamConn, freecamCF, freecamSpeed = nil, nil, CFrame.new(), 1
local destinationMarker, markerBeam, selectedDestination = nil, nil, nil
local freecamInputConns, selectCallback = {}, nil

local function cleanupFreecam()
	rainbowFreecamActive = false
	local character = player.Character; if character then local h = character:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed = savedWalkSpeedForRainbow end end
	if freecamConn then freecamConn:Disconnect(); freecamConn = nil end
	if freecamGui and freecamGui.Parent then freecamGui:Destroy() end; freecamGui = nil
	if destinationMarker and destinationMarker.Parent then destinationMarker:Destroy() end; destinationMarker = nil
	if markerBeam and markerBeam.Parent then markerBeam:Destroy() end; markerBeam = nil
	for _, conn in freecamInputConns do if conn and typeof(conn) == "RBXScriptConnection" and conn.Connected then conn:Disconnect() end end; freecamInputConns = {}; selectCallback = nil
	camera.CameraType = Enum.CameraType.Custom
	local char = player.Character; if char then camera.CameraSubject = char:FindFirstChildOfClass("Humanoid") end
end

local function createFreecamUI()
	if freecamGui then freecamGui:Destroy() end
	freecamGui = Instance.new("ScreenGui"); freecamGui.Name = "FreecamGui"; freecamGui.ResetOnSpawn = false; freecamGui.Parent = player.PlayerGui
	local il = Instance.new("TextLabel"); il.Size = UDim2.new(0,500,0,50); il.Position = UDim2.new(0.5,0,0,20); il.AnchorPoint = Vector2.new(0.5,0); il.BackgroundColor3 = Color3.fromRGB(20,20,30); il.BackgroundTransparency = 0.3; il.BorderSizePixel = 0; il.Text = "🌈 AIM AT DESTINATION — Then press SELECT!"; il.TextSize = 16; il.Font = Enum.Font.GothamBold; il.Parent = freecamGui; Instance.new("UICorner", il).CornerRadius = UDim.new(0,10)
	task.spawn(function() local t = 0; while il and il.Parent do t += 0.02; il.TextColor3 = getRainbowColor(t); task.wait(0.03) end end)
	local cb = Instance.new("TextButton"); cb.Size = UDim2.new(0,120,0,36); cb.Position = UDim2.new(0.5,70,0,78); cb.AnchorPoint = Vector2.new(0.5,0); cb.BackgroundColor3 = Color3.fromRGB(180,40,40); cb.BorderSizePixel = 0; cb.Text = "✕ Cancel"; cb.TextColor3 = Color3.fromRGB(255,255,255); cb.TextSize = 14; cb.Font = Enum.Font.GothamBold; cb.Parent = freecamGui; Instance.new("UICorner", cb).CornerRadius = UDim.new(0,8)
	cb.MouseButton1Click:Connect(function() cleanupFreecam(); isRainbowLocatorActive = false; task.spawn(function() animateCooldown(rainbowCdBar, 2); task.wait(2); canRainbowLocator = true end) end)
	local jc = Instance.new("Frame"); jc.Name = "JoyContainer"; jc.Size = UDim2.new(0,560,0,180); jc.Position = UDim2.new(0.5,0,1,-20); jc.AnchorPoint = Vector2.new(0.5,1); jc.BackgroundColor3 = Color3.fromRGB(20,20,30); jc.BackgroundTransparency = 0.2; jc.BorderSizePixel = 0; jc.Parent = freecamGui; Instance.new("UICorner", jc).CornerRadius = UDim.new(0,14)
	local sb = Instance.new("TextButton"); sb.Size = UDim2.new(0,160,0,40); sb.Position = UDim2.new(0.5,0,0,8); sb.AnchorPoint = Vector2.new(0.5,0); sb.BackgroundColor3 = Color3.fromRGB(40,180,40); sb.BorderSizePixel = 0; sb.Text = "✓ SELECT DESTINATION"; sb.TextColor3 = Color3.fromRGB(255,255,255); sb.TextSize = 14; sb.Font = Enum.Font.GothamBold; sb.ZIndex = 5; sb.Parent = jc; Instance.new("UICorner", sb).CornerRadius = UDim.new(0,10)
	local sbs = Instance.new("UIStroke"); sbs.Color = Color3.fromRGB(80,255,80); sbs.Thickness = 2; sbs.Parent = sb
	task.spawn(function() while sb and sb.Parent do TweenService:Create(sbs, TweenInfo.new(0.6), {Transparency = 0.6}):Play(); task.wait(0.6); if sb and sb.Parent then TweenService:Create(sbs, TweenInfo.new(0.6), {Transparency = 0}):Play(); task.wait(0.6) end end end)
	local sl = Instance.new("TextLabel"); sl.Size = UDim2.new(0,220,0,16); sl.Position = UDim2.new(0.5,0,0,52); sl.AnchorPoint = Vector2.new(0.5,0); sl.BackgroundTransparency = 1; sl.Text = "Aim at a collidable surface"; sl.TextColor3 = Color3.fromRGB(180,180,180); sl.TextSize = 11; sl.Font = Enum.Font.Gotham; sl.ZIndex = 5; sl.Parent = jc
	-- joysticks (simplified)
	local function makeJoy(name, col, pos, anch)
		local f = Instance.new("Frame"); f.Name = name; f.Size = UDim2.new(0,110,0,110); f.Position = pos; f.AnchorPoint = anch; f.BackgroundColor3 = col; f.BackgroundTransparency = 0.3; f.BorderSizePixel = 0; f.Parent = jc; Instance.new("UICorner", f).CornerRadius = UDim.new(1,0)
		local th = Instance.new("Frame"); th.Size = UDim2.new(0,28,0,28); th.Position = UDim2.new(0.5,0,0.5,0); th.AnchorPoint = Vector2.new(0.5,0.5); th.BackgroundColor3 = Color3.new(col.R*2, col.G*2, col.B*2); th.BorderSizePixel = 0; th.Parent = f; Instance.new("UICorner", th).CornerRadius = UDim.new(1,0)
		return f, th
	end
	local mjf, mt = makeJoy("Move", Color3.fromRGB(80,20,20), UDim2.new(0,20,1,-10), Vector2.new(0,1))
	local cjf, ct = makeJoy("Cam", Color3.fromRGB(20,20,80), UDim2.new(1,-20,1,-10), Vector2.new(1,1))
	local moveInput, camInput = Vector2.zero, Vector2.zero
	local moveDrag, camDrag = false, false
	local mouseOverPanel, mouseOverTop = false, false
	jc.MouseEnter:Connect(function() mouseOverPanel = true end); jc.MouseLeave:Connect(function() mouseOverPanel = false end)
	il.MouseEnter:Connect(function() mouseOverTop = true end); il.MouseLeave:Connect(function() mouseOverTop = false end)
	cb.MouseEnter:Connect(function() mouseOverTop = true end); cb.MouseLeave:Connect(function() mouseOverTop = false end)
	mjf.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then moveDrag = true end end)
	cjf.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then camDrag = true end end)
	local ic = UserInputService.InputChanged:Connect(function(i) if not freecamGui or not freecamGui.Parent then return end
		if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
			if moveDrag then local c2 = mjf.AbsolutePosition + mjf.AbsoluteSize/2; local d = (Vector2.new(i.Position.X,i.Position.Y)-c2)/(mjf.AbsoluteSize.X/2); d = Vector2.new(math.clamp(d.X,-1,1), math.clamp(d.Y,-1,1)); moveInput = d; mt.Position = UDim2.new(0.5+d.X*0.35,0,0.5+d.Y*0.35,0) end
			if camDrag then local c2 = cjf.AbsolutePosition + cjf.AbsoluteSize/2; local d = (Vector2.new(i.Position.X,i.Position.Y)-c2)/(cjf.AbsoluteSize.X/2); d = Vector2.new(math.clamp(d.X,-1,1), math.clamp(d.Y,-1,1)); camInput = d; ct.Position = UDim2.new(0.5+d.X*0.35,0,0.5+d.Y*0.35,0) end
		end end); table.insert(freecamInputConns, ic)
	local ie = UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		if moveDrag then moveDrag = false; moveInput = Vector2.zero; mt.Position = UDim2.new(0.5,0,0.5,0) end
		if camDrag then camDrag = false; camInput = Vector2.zero; ct.Position = UDim2.new(0.5,0,0.5,0) end end end); table.insert(freecamInputConns, ie)
	local ks = {}
	table.insert(freecamInputConns, UserInputService.InputBegan:Connect(function(i, gp) if gp then return end; ks[i.KeyCode] = true end))
	table.insert(freecamInputConns, UserInputService.InputEnded:Connect(function(i) ks[i.KeyCode] = false end))
	local lastHit, lastPart = nil, nil
	sb.MouseButton1Click:Connect(function()
		if lastHit and lastPart and lastPart.CanCollide then if selectCallback then selectCallback(lastHit, lastPart) end
		else sl.Text = "⚠ Aim at a collidable surface first!"; sl.TextColor3 = Color3.fromRGB(255,80,80); task.delay(1, function() if sl and sl.Parent then sl.Text = "Aim at a collidable surface"; sl.TextColor3 = Color3.fromRGB(180,180,180) end end) end end)
	return function() return moveInput, camInput, 1, ks, mouseOverPanel or mouseOverTop end,
		function(h, p) lastHit = h; lastPart = p; if h and p and p.CanCollide then sl.Text = "✓ Valid: "..p.Name; sl.TextColor3 = Color3.fromRGB(80,255,80); sb.BackgroundColor3 = Color3.fromRGB(40,200,40) else sl.Text = "Aim at a collidable surface"; sl.TextColor3 = Color3.fromRGB(180,180,180); sb.BackgroundColor3 = Color3.fromRGB(60,60,60) end end
end

local function activateRainbowLocator()
	if not canRainbowLocator or isRainbowLocatorActive then return end
	local character = player.Character; if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid"); local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart or humanoid.Health <= 0 then return end
	isRainbowLocatorActive = true; canRainbowLocator = false; rainbowFreecamActive = true; selectedDestination = nil
	savedWalkSpeedForRainbow = humanoid.WalkSpeed; humanoid.WalkSpeed = 0.01
	destinationMarker = Instance.new("Part"); destinationMarker.Name = "DestMarker"; destinationMarker.Anchored = true; destinationMarker.CanCollide = false; destinationMarker.Size = Vector3.new(3,3,3); destinationMarker.Shape = Enum.PartType.Ball; destinationMarker.Material = Enum.Material.Neon; destinationMarker.Transparency = 0.8; destinationMarker.Parent = workspace
	task.spawn(function() local t = 0; while destinationMarker and destinationMarker.Parent do t += 0.03; destinationMarker.Color = getRainbowColor(t); task.wait(0.03) end end)
	markerBeam = Instance.new("Part"); markerBeam.Name = "MarkerBeam"; markerBeam.Anchored = true; markerBeam.CanCollide = false; markerBeam.Size = Vector3.new(0.3,50,0.3); markerBeam.Material = Enum.Material.Neon; markerBeam.Transparency = 0.5; markerBeam.Parent = workspace
	task.spawn(function() local t = 0; while markerBeam and markerBeam.Parent do t += 0.03; markerBeam.Color = getRainbowColor(t+0.5); if destinationMarker and destinationMarker.Parent then markerBeam.CFrame = CFrame.new(destinationMarker.Position + Vector3.new(0,25,0)) end; task.wait(0.03) end end)
	camera.CameraType = Enum.CameraType.Scriptable; freecamCF = camera.CFrame
	local getInputs, updateHitInfo = createFreecamUI()
	selectCallback = function(hitPos)
		selectedDestination = hitPos + Vector3.new(0, 3, 0); cleanupFreecam()
		task.spawn(function()
			local char = player.Character; if not char then isRainbowLocatorActive = false; task.spawn(function() animateCooldown(rainbowCdBar, 2); task.wait(2); canRainbowLocator = true end); return end
			local hum = char:FindFirstChildOfClass("Humanoid"); local rp = char:FindFirstChild("HumanoidRootPart")
			if not hum or not rp or hum.Health <= 0 or not selectedDestination then isRainbowLocatorActive = false; task.spawn(function() animateCooldown(rainbowCdBar, 2); task.wait(2); canRainbowLocator = true end); return end
			local dest = selectedDestination; createRainbowPillar(rp.Position); createRainbowShockwave(rp.Position); playSound(rp, "rbxassetid://3199270999", 0.8, 0.6)
			local ta = Instance.new("ParticleEmitter"); ta.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.8), NumberSequenceKeypoint.new(1,0)}); ta.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.3), NumberSequenceKeypoint.new(1,1)}); ta.Lifetime = NumberRange.new(0.3,0.6); ta.Rate = 80; ta.Speed = NumberRange.new(3,8); ta.SpreadAngle = Vector2.new(180,180); ta.LightEmission = 0.8; ta.Parent = rp
			task.spawn(function() local t = 0; while ta and ta.Parent do t += 0.02; ta.Color = ColorSequence.new(getRainbowColor(t)); task.wait(0.03) end end)
			local tY = dest.Y; if math.abs(tY - rp.Position.Y) > 3 then
				local ra = Instance.new("Attachment"); ra.Parent = rp; local rv = Instance.new("LinearVelocity"); rv.Attachment0 = ra; rv.RelativeTo = Enum.ActuatorRelativeTo.World; rv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector; rv.MaxForce = 60000; rv.VectorVelocity = Vector3.new(0, tY > rp.Position.Y and 80 or -80, 0); rv.Parent = rp
				local hh = Instance.new("LinearVelocity"); hh.Attachment0 = ra; hh.RelativeTo = Enum.ActuatorRelativeTo.World; hh.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane; hh.PrimaryTangentAxis = Vector3.new(1,0,0); hh.SecondaryTangentAxis = Vector3.new(0,0,1); hh.MaxForce = 40000; hh.PlaneVelocity = Vector2.zero; hh.Parent = rp
				while true do if not rp or not rp.Parent or hum.Health <= 0 then break end; if math.abs(rp.Position.Y - tY) < 3 then break end
					local av = checkHeadObstacle(rp); if av then hh.PlaneVelocity = Vector2.new(av.X*40, av.Z*40) else hh.PlaneVelocity = Vector2.zero end; task.wait(0.05) end
				if rv.Parent then rv:Destroy() end; if hh.Parent then hh:Destroy() end; if ra.Parent then ra:Destroy() end end
			local ep = Vector3.new(dest.X, rp.Position.Y, dest.Z); local hd = (ep - rp.Position).Magnitude
			if hd > 3 then local hDir = (ep - rp.Position).Unit; rp.CFrame = CFrame.new(rp.Position, rp.Position + hDir)
				local ha = Instance.new("Attachment"); ha.Parent = rp; local hv = Instance.new("LinearVelocity"); hv.Attachment0 = ha; hv.RelativeTo = Enum.ActuatorRelativeTo.World; hv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector; hv.MaxForce = 60000; hv.VectorVelocity = Vector3.zero; hv.Parent = rp
				local hag = Instance.new("LinearVelocity"); hag.Attachment0 = ha; hag.RelativeTo = Enum.ActuatorRelativeTo.World; hag.VelocityConstraintMode = Enum.VelocityConstraintMode.Line; hag.LineDirection = Vector3.yAxis; hag.MaxForce = 8000; hag.LineVelocity = 0; hag.Parent = rp
				local tt = math.clamp(hd/120, 0.5, 8); local el = 0
				while el < tt do if not rp or not rp.Parent or hum.Health <= 0 then break end; local al = el/tt; local sm = math.max(math.sin(al*math.pi), 0.1); local bv = hDir * (hd/tt) * sm * 1.6
					local av = checkHeadObstacle(rp); if av then bv = bv + av * 50 end; hv.VectorVelocity = bv
					if Vector3.new(ep.X-rp.Position.X, 0, ep.Z-rp.Position.Z).Magnitude < 5 then break end; el += task.wait() end
				if hv.Parent then hv:Destroy() end; if hag.Parent then hag:Destroy() end; if ha.Parent then ha:Destroy() end end
			if rp and rp.Parent then createRainbowPillar(rp.Position); createRainbowShockwave(rp.Position); playSound(rp, "rbxassetid://3199270999", 0.6, 1.2) end
			ta.Rate = 0; task.delay(1, function() if ta.Parent then ta:Destroy() end end)
			isRainbowLocatorActive = false; animateCooldown(rainbowCdBar, RAINBOW_LOCATOR_COOLDOWN); task.wait(RAINBOW_LOCATOR_COOLDOWN); canRainbowLocator = true
		end)
	end
	freecamConn = RunService.RenderStepped:Connect(function(dt)
		if not rainbowFreecamActive then return end
		local mi, ci, sp, ks, oU = getInputs()
		local kb = Vector3.zero
		if ks[Enum.KeyCode.W] then kb += Vector3.new(0,0,-1) end; if ks[Enum.KeyCode.S] then kb += Vector3.new(0,0,1) end
		if ks[Enum.KeyCode.A] then kb += Vector3.new(-1,0,0) end; if ks[Enum.KeyCode.D] then kb += Vector3.new(1,0,0) end
		if ks[Enum.KeyCode.Space] then kb += Vector3.new(0,1,0) end; if ks[Enum.KeyCode.LeftShift] then kb += Vector3.new(0,-1,0) end
		local mv = Vector3.new(mi.X, 0, mi.Y) * sp + kb
		local rx, ry, _ = freecamCF:ToEulerAnglesYXZ()
		ry -= ci.X * 2 * dt; rx = math.clamp(rx - ci.Y * 2 * dt, -math.rad(85), math.rad(85))
		freecamCF = CFrame.new(freecamCF.Position) * CFrame.fromEulerAnglesYXZ(rx, ry, 0)
		freecamCF = freecamCF + freecamCF:VectorToWorldSpace(mv * 60 * sp * dt); camera.CFrame = freecamCF
		if not oU then
			local mp = UserInputService:GetMouseLocation(); local r = camera:ViewportPointToRay(mp.X, mp.Y)
			local rp2 = RaycastParams.new(); rp2.FilterType = Enum.RaycastFilterType.Exclude
			local fl = {}; if player.Character then table.insert(fl, player.Character) end; if destinationMarker then table.insert(fl, destinationMarker) end; if markerBeam then table.insert(fl, markerBeam) end; rp2.FilterDescendantsInstances = fl
			local res = workspace:Raycast(r.Origin, r.Direction * 5000, rp2)
			if res and res.Instance then
				if destinationMarker and destinationMarker.Parent then destinationMarker.Position = res.Position + Vector3.new(0,1.5,0); destinationMarker.Transparency = 0.3; destinationMarker.Size = Vector3.new(3,3,3) end
				updateHitInfo(res.Position, res.Instance)
			else if destinationMarker and destinationMarker.Parent then destinationMarker.Transparency = 0.8; destinationMarker.Size = Vector3.new(1,1,1) end; updateHitInfo(nil, nil) end
		end
	end)
end

-- ============================================
-- EMERGENCY STOP
-- ============================================
local function emergencyStop()
	if isShockwaveTraveling then cleanupShockwaveTravel() end
	local character = player.Character
	if character then local rp = character:FindFirstChild("HumanoidRootPart"); if rp then for _, c in rp:GetChildren() do if c:IsA("LinearVelocity") or (c:IsA("Attachment") and c.Name ~= "RootAttachment") then c:Destroy() end end end end
	if isLunging then isLunging = false end; if isDashing then isDashing = false end
	if rainbowFreecamActive then cleanupFreecam(); isRainbowLocatorActive = false; task.spawn(function() animateCooldown(rainbowCdBar, 2); task.wait(2); canRainbowLocator = true end) end
	emergencyBtnObj.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
	task.delay(0.3, function() emergencyBtnObj.BackgroundColor3 = Color3.fromRGB(200, 30, 30) end)
	if character and character:FindFirstChild("HumanoidRootPart") then playSound(character.HumanoidRootPart, "rbxassetid://3199270999", 0.5, 2) end
end

emergencyBtnObj.MouseButton1Click:Connect(emergencyStop)

-- ============================================
-- BUTTON CLICKS
-- ============================================
platformBtn.MouseButton1Click:Connect(activatePlatform)
lungeBtn.MouseButton1Click:Connect(activateLunge)
megaJumpBtn.MouseButton1Click:Connect(activateMegaJump)
shockwaveBtn.MouseButton1Click:Connect(activateShockwaveTravel)
fusionBtn.MouseButton1Click:Connect(activateFusion)
rainbowBtn.MouseButton1Click:Connect(activateRainbowLocator)
immortalBtn.MouseButton1Click:Connect(activateImmortality)
miniDashBtn.MouseButton1Click:Connect(activateMiniDash)

-- ============================================
-- KEYBINDS
-- ============================================
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end; if rainbowFreecamActive then return end
	if input.KeyCode == Enum.KeyCode.Q then activatePlatform()
	elseif input.KeyCode == Enum.KeyCode.E then activateLunge()
	elseif input.KeyCode == Enum.KeyCode.R then activateMegaJump()
	elseif input.KeyCode == Enum.KeyCode.T then activateShockwaveTravel()
	elseif input.KeyCode == Enum.KeyCode.F then activateFusion()
	elseif input.KeyCode == Enum.KeyCode.G then activateRainbowLocator()
	elseif input.KeyCode == Enum.KeyCode.H then activateImmortality()
	elseif input.KeyCode == Enum.KeyCode.C then activateMiniDash()
	elseif input.KeyCode == Enum.KeyCode.X then emergencyStop()
	end
end)

-- ============================================
-- CHARACTER SETUP
-- ============================================
local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid")
	local dashedThisJump = false
	isDashing = false; canDash = true; isLunging = false; isMegaJumping = false
	if megaJumpGravityActive then workspace.Gravity = originalGravity; megaJumpGravityActive = false end
	if isShockwaveTraveling then cleanupShockwaveTravel() end
	if rainbowFreecamActive then cleanupFreecam() end
	if isFusionActive then workspace.Gravity = originalGravity; isFusionActive = false end
	if fusionJumpConn then fusionJumpConn:Disconnect(); fusionJumpConn = nil end
	if isImmortal then cleanupImmortality() end
	if platformFollowConn then platformFollowConn:Disconnect(); platformFollowConn = nil end
	if currentPlatform and currentPlatform.Parent then currentPlatform:Destroy() end; currentPlatform = nil; platformActive = false

	humanoid.StateChanged:Connect(function(_, ns)
		if ns == Enum.HumanoidStateType.Jumping then
			if megaJumpArmed and canMegaJump then performMegaJump() end
			if not dashedThisJump then task.delay(0.05, function() if dashEnabled and not dashedThisJump and humanoid.Health > 0 then dashedThisJump = true; performDash() end end) end
		elseif ns == Enum.HumanoidStateType.Landed or ns == Enum.HumanoidStateType.Running then dashedThisJump = false end
	end)
end

if player.Character then onCharacterAdded(player.Character) end
player.CharacterAdded:Connect(onCharacterAdded)

print("[Abilities V4.1] Q=Platform E=Lunge R=MegaJump T=Shockwave F=Fusion G=Rainbow H=Immortality C=MiniDash X=Stop")
