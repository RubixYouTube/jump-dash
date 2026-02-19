-- AdvancedAbilitiesSystemV4_2 (LocalScript)
-- Place in StarterPlayer > StarterPlayerScripts
-- Version 4.2 - Made by rubix

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
	Red = {primary=Color3.fromRGB(200,40,40),secondary=Color3.fromRGB(120,20,20),accent=Color3.fromRGB(255,80,80),bg=Color3.fromRGB(30,15,15),titleBg=Color3.fromRGB(50,20,20),text=Color3.fromRGB(255,200,200),stroke=Color3.fromRGB(200,60,60)},
	Orange = {primary=Color3.fromRGB(220,130,20),secondary=Color3.fromRGB(140,80,10),accent=Color3.fromRGB(255,170,50),bg=Color3.fromRGB(30,22,10),titleBg=Color3.fromRGB(50,35,15),text=Color3.fromRGB(255,220,180),stroke=Color3.fromRGB(220,140,40)},
	Yellow = {primary=Color3.fromRGB(220,200,20),secondary=Color3.fromRGB(140,130,10),accent=Color3.fromRGB(255,240,50),bg=Color3.fromRGB(30,28,10),titleBg=Color3.fromRGB(50,45,15),text=Color3.fromRGB(255,250,200),stroke=Color3.fromRGB(220,200,40)},
	Green = {primary=Color3.fromRGB(40,180,60),secondary=Color3.fromRGB(20,100,30),accent=Color3.fromRGB(80,255,100),bg=Color3.fromRGB(15,30,18),titleBg=Color3.fromRGB(20,50,25),text=Color3.fromRGB(200,255,210),stroke=Color3.fromRGB(60,180,80)},
	Blue = {primary=Color3.fromRGB(40,80,200),secondary=Color3.fromRGB(20,40,120),accent=Color3.fromRGB(100,150,255),bg=Color3.fromRGB(20,20,30),titleBg=Color3.fromRGB(30,30,50),text=Color3.fromRGB(200,200,255),stroke=Color3.fromRGB(80,80,120)},
	Purple = {primary=Color3.fromRGB(140,40,200),secondary=Color3.fromRGB(80,20,120),accent=Color3.fromRGB(180,100,255),bg=Color3.fromRGB(25,15,30),titleBg=Color3.fromRGB(40,25,50),text=Color3.fromRGB(220,200,255),stroke=Color3.fromRGB(140,80,180)},
	Pink = {primary=Color3.fromRGB(220,60,140),secondary=Color3.fromRGB(140,30,80),accent=Color3.fromRGB(255,120,180),bg=Color3.fromRGB(30,15,22),titleBg=Color3.fromRGB(50,25,35),text=Color3.fromRGB(255,210,230),stroke=Color3.fromRGB(220,80,150)},
	Brown = {primary=Color3.fromRGB(140,90,40),secondary=Color3.fromRGB(90,55,20),accent=Color3.fromRGB(180,120,60),bg=Color3.fromRGB(25,18,12),titleBg=Color3.fromRGB(40,28,18),text=Color3.fromRGB(230,210,190),stroke=Color3.fromRGB(140,100,60)},
	Black = {primary=Color3.fromRGB(60,60,60),secondary=Color3.fromRGB(30,30,30),accent=Color3.fromRGB(120,120,120),bg=Color3.fromRGB(10,10,10),titleBg=Color3.fromRGB(20,20,20),text=Color3.fromRGB(200,200,200),stroke=Color3.fromRGB(80,80,80)},
	White = {primary=Color3.fromRGB(220,220,220),secondary=Color3.fromRGB(180,180,180),accent=Color3.fromRGB(255,255,255),bg=Color3.fromRGB(240,240,245),titleBg=Color3.fromRGB(220,220,230),text=Color3.fromRGB(30,30,40),stroke=Color3.fromRGB(180,180,200)},
	Grey = {primary=Color3.fromRGB(120,120,130),secondary=Color3.fromRGB(70,70,80),accent=Color3.fromRGB(170,170,180),bg=Color3.fromRGB(30,30,35),titleBg=Color3.fromRGB(45,45,50),text=Color3.fromRGB(210,210,220),stroke=Color3.fromRGB(100,100,110)},
}
local currentTheme = themes.Blue
local themeCallbacks = {}
local function registerThemeable(cb) table.insert(themeCallbacks, cb); cb(currentTheme) end
local function setTheme(name) if themes[name] then currentTheme = themes[name]; for _, cb in themeCallbacks do cb(currentTheme) end end end

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

local GIGA_JUMP_MULT = 12
local GIGA_JUMP_GRAVITY_SCALE = 0.4
local GIGA_JUMP_COOLDOWN = 8

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
local gigaJumpArmed = false
local canGigaJump = true
local isGigaJumping = false
local gigaJumpGravityActive = false
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
local originalGravity = workspace.Gravity

-- ============================================
-- UTILITY
-- ============================================
local function isVoidBelow(position, maxDist)
	local dist = maxDist or 500
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
	local fl = {}
	if player.Character then table.insert(fl, player.Character) end
	if currentPlatform then table.insert(fl, currentPlatform) end
	if immortalityFloorPart then table.insert(fl, immortalityFloorPart) end
	if immortalityShieldPart then table.insert(fl, immortalityShieldPart) end
	for _, p in shockwaveTunnelParts do if p and p.Parent then table.insert(fl, p) end end
	rp.FilterDescendantsInstances = fl
	return workspace:Raycast(position, Vector3.new(0, -dist, 0), rp) == nil
end

local function isOnCollidableSurface(rootPart)
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
	local fl = {}
	if player.Character then table.insert(fl, player.Character) end
	if currentPlatform then table.insert(fl, currentPlatform) end
	if immortalityFloorPart then table.insert(fl, immortalityFloorPart) end
	if immortalityShieldPart then table.insert(fl, immortalityShieldPart) end
	for _, p in shockwaveTunnelParts do if p and p.Parent then table.insert(fl, p) end end
	rp.FilterDescendantsInstances = fl
	local result = workspace:Raycast(rootPart.Position, Vector3.new(0, -5, 0), rp)
	return result ~= nil and result.Instance ~= nil and result.Instance.CanCollide
end

local function findNearestCollidablePart(position)
	local nearestPos = position
	local nearestDist = math.huge
	local fl = {}
	if player.Character then table.insert(fl, player.Character) end
	if currentPlatform then table.insert(fl, currentPlatform) end
	if immortalityFloorPart then table.insert(fl, immortalityFloorPart) end
	if immortalityShieldPart then table.insert(fl, immortalityShieldPart) end
	for _, p in shockwaveTunnelParts do if p and p.Parent then table.insert(fl, p) end end
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = fl
	for _, dir in {Vector3.new(0,-1,0),Vector3.new(1,0,0),Vector3.new(-1,0,0),Vector3.new(0,0,1),Vector3.new(0,0,-1),Vector3.new(1,-1,0).Unit,Vector3.new(-1,-1,0).Unit,Vector3.new(0,-1,1).Unit,Vector3.new(0,-1,-1).Unit,Vector3.new(1,-1,1).Unit,Vector3.new(-1,-1,1).Unit,Vector3.new(0,1,0)} do
		local result = workspace:Raycast(position, dir * 2000, rp)
		if result and result.Instance and result.Instance.CanCollide then
			local dist = (result.Position - position).Magnitude
			if dist < nearestDist then nearestDist = dist; nearestPos = result.Position + Vector3.new(0, 3, 0) end
		end
	end
	return nil, nearestPos
end

local function checkHeadObstacle(rootPart)
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
	local fl = {player.Character}
	if currentPlatform then table.insert(fl, currentPlatform) end
	if immortalityFloorPart then table.insert(fl, immortalityFloorPart) end
	if immortalityShieldPart then table.insert(fl, immortalityShieldPart) end
	for _, p in shockwaveTunnelParts do if p and p.Parent then table.insert(fl, p) end end
	rp.FilterDescendantsInstances = fl
	local upResult = workspace:Raycast(rootPart.Position, Vector3.new(0, 8, 0), rp)
	if upResult and upResult.Instance and upResult.Instance.CanCollide then
		local av = Vector3.new(upResult.Normal.X, 0, upResult.Normal.Z)
		if av.Magnitude < 0.1 then
			local bestDir, bestDist = nil, 0
			for _, dir in {Vector3.new(1,0,0),Vector3.new(-1,0,0),Vector3.new(0,0,1),Vector3.new(0,0,-1),Vector3.new(1,0,1).Unit,Vector3.new(-1,0,1).Unit,Vector3.new(1,0,-1).Unit,Vector3.new(-1,0,-1).Unit} do
				local sc = workspace:Raycast(rootPart.Position, dir * 20, rp)
				local dist = sc and sc.Distance or 20
				if dist > bestDist then bestDist = dist; bestDir = dir end
			end
			return bestDir
		end
		return av.Unit
	end
	local lookDir = rootPart.CFrame.LookVector
	local diagResult = workspace:Raycast(rootPart.Position + Vector3.new(0, 3, 0), Vector3.new(lookDir.X, 1, lookDir.Z).Unit * 6, rp)
	if diagResult and diagResult.Instance and diagResult.Instance.CanCollide then
		local av = Vector3.new(diagResult.Normal.X, 0, diagResult.Normal.Z)
		if av.Magnitude > 0.1 then return av.Unit end
	end
	return nil
end

local function playSound(parent, id, volume, speed)
	local s = Instance.new("Sound"); s.SoundId = id; s.Volume = volume or 0.5; s.PlaybackSpeed = speed or 1; s.Parent = parent; s:Play(); Debris:AddItem(s, 3)
end

local function getRainbowColor(t) return Color3.fromHSV((t % 1), 1, 1) end
local function getMonochromeColor(t) local v = (math.sin(t * 3) + 1) / 2; return Color3.fromRGB(v * 255, v * 255, v * 255) end

-- ============================================
-- SCREEN GUI
-- ============================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AbilitiesGui"; screenGui.ResetOnSpawn = false; screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; screenGui.Parent = player.PlayerGui

-- ============================================
-- DASH TOGGLE
-- ============================================
local dashToggleStroke
local function createDashToggle()
	local bf = Instance.new("Frame"); bf.Name = "DashToggleFrame"; bf.Size = UDim2.new(0,160,0,50); bf.Position = UDim2.new(1,-175,1,-65); bf.BackgroundColor3 = Color3.fromRGB(30,30,30); bf.BackgroundTransparency = 0.2; bf.BorderSizePixel = 0; bf.Parent = screenGui; Instance.new("UICorner", bf).CornerRadius = UDim.new(0,12)
	local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(0,170,255); st.Thickness = 2; st.Transparency = 0.3; st.Parent = bf; dashToggleStroke = st
	local lb = Instance.new("TextLabel"); lb.Size = UDim2.new(0.6,0,1,0); lb.Position = UDim2.new(0,10,0,0); lb.BackgroundTransparency = 1; lb.Text = "Jump Dash"; lb.TextColor3 = Color3.fromRGB(255,255,255); lb.TextSize = 16; lb.Font = Enum.Font.GothamBold; lb.TextXAlignment = Enum.TextXAlignment.Left; lb.Parent = bf
	local tb = Instance.new("TextButton"); tb.Size = UDim2.new(0,50,0,26); tb.Position = UDim2.new(1,-60,0.5,0); tb.AnchorPoint = Vector2.new(0,0.5); tb.BackgroundColor3 = Color3.fromRGB(0,180,100); tb.BorderSizePixel = 0; tb.Text = "ON"; tb.TextColor3 = Color3.fromRGB(255,255,255); tb.TextSize = 14; tb.Font = Enum.Font.GothamBold; tb.Parent = bf; Instance.new("UICorner", tb).CornerRadius = UDim.new(0,8)
	local cd = Instance.new("Frame"); cd.Name = "CooldownBar"; cd.Size = UDim2.new(1,0,0,3); cd.Position = UDim2.new(0,0,1,-3); cd.BackgroundColor3 = Color3.fromRGB(0,170,255); cd.BorderSizePixel = 0; cd.Parent = bf; Instance.new("UICorner", cd).CornerRadius = UDim.new(0,2)
	tb.MouseButton1Click:Connect(function()
		dashEnabled = not dashEnabled
		if dashEnabled then tb.Text = "ON"; tb.BackgroundColor3 = Color3.fromRGB(0,180,100); st.Color = currentTheme.accent; lb.TextColor3 = Color3.fromRGB(255,255,255)
		else tb.Text = "OFF"; tb.BackgroundColor3 = Color3.fromRGB(180,50,50); st.Color = Color3.fromRGB(100,100,100); lb.TextColor3 = Color3.fromRGB(150,150,150) end
	end)
	return cd
end
local dashCooldownBar = createDashToggle()

-- ============================================
-- ABILITIES MENU
-- ============================================
local menuOpen = true
local menuFrame = Instance.new("Frame"); menuFrame.Name = "AbilitiesMenu"; menuFrame.Size = UDim2.new(0,250,0,450); menuFrame.Position = UDim2.new(0,20,0.5,-225); menuFrame.BackgroundColor3 = currentTheme.bg; menuFrame.BackgroundTransparency = 0.1; menuFrame.BorderSizePixel = 0; menuFrame.ClipsDescendants = true; menuFrame.Parent = screenGui; Instance.new("UICorner", menuFrame).CornerRadius = UDim.new(0,14)
local menuStrokeObj = Instance.new("UIStroke"); menuStrokeObj.Color = currentTheme.stroke; menuStrokeObj.Thickness = 2; menuStrokeObj.Parent = menuFrame
local titleBarObj = Instance.new("Frame"); titleBarObj.Size = UDim2.new(1,0,0,36); titleBarObj.BackgroundColor3 = currentTheme.titleBg; titleBarObj.BackgroundTransparency = 0.1; titleBarObj.BorderSizePixel = 0; titleBarObj.ZIndex = 3; titleBarObj.Parent = menuFrame; Instance.new("UICorner", titleBarObj).CornerRadius = UDim.new(0,14)
local titleBarFixObj = Instance.new("Frame"); titleBarFixObj.Size = UDim2.new(1,0,0,14); titleBarFixObj.Position = UDim2.new(0,0,1,-14); titleBarFixObj.BackgroundColor3 = currentTheme.titleBg; titleBarFixObj.BackgroundTransparency = 0.1; titleBarFixObj.BorderSizePixel = 0; titleBarFixObj.ZIndex = 3; titleBarFixObj.Parent = titleBarObj
local titleLabelObj = Instance.new("TextLabel"); titleLabelObj.Size = UDim2.new(1,-90,1,0); titleLabelObj.Position = UDim2.new(0,12,0,0); titleLabelObj.BackgroundTransparency = 1; titleLabelObj.Text = "⚡ Abilities"; titleLabelObj.TextColor3 = currentTheme.text; titleLabelObj.TextSize = 16; titleLabelObj.Font = Enum.Font.GothamBold; titleLabelObj.TextXAlignment = Enum.TextXAlignment.Left; titleLabelObj.ZIndex = 3; titleLabelObj.Parent = titleBarObj

local minimizeBtn = Instance.new("TextButton"); minimizeBtn.Size = UDim2.new(0,26,0,24); minimizeBtn.Position = UDim2.new(1,-34,0.5,0); minimizeBtn.AnchorPoint = Vector2.new(0,0.5); minimizeBtn.BackgroundColor3 = currentTheme.secondary; minimizeBtn.BorderSizePixel = 0; minimizeBtn.Text = "—"; minimizeBtn.TextColor3 = currentTheme.text; minimizeBtn.TextSize = 16; minimizeBtn.Font = Enum.Font.GothamBold; minimizeBtn.ZIndex = 3; minimizeBtn.Parent = titleBarObj; Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0,6)
local aboutBtn = Instance.new("TextButton"); aboutBtn.Size = UDim2.new(0,26,0,24); aboutBtn.Position = UDim2.new(1,-62,0.5,0); aboutBtn.AnchorPoint = Vector2.new(0,0.5); aboutBtn.BackgroundColor3 = currentTheme.secondary; aboutBtn.BorderSizePixel = 0; aboutBtn.Text = "?"; aboutBtn.TextColor3 = currentTheme.text; aboutBtn.TextSize = 14; aboutBtn.Font = Enum.Font.GothamBold; aboutBtn.ZIndex = 3; aboutBtn.Parent = titleBarObj; Instance.new("UICorner", aboutBtn).CornerRadius = UDim.new(0,6)
local themesBtn = Instance.new("TextButton"); themesBtn.Size = UDim2.new(0,26,0,24); themesBtn.Position = UDim2.new(1,-90,0.5,0); themesBtn.AnchorPoint = Vector2.new(0,0.5); themesBtn.BackgroundColor3 = currentTheme.secondary; themesBtn.BorderSizePixel = 0; themesBtn.Text = "🎨"; themesBtn.TextColor3 = currentTheme.text; themesBtn.TextSize = 12; themesBtn.Font = Enum.Font.GothamBold; themesBtn.ZIndex = 3; themesBtn.Parent = titleBarObj; Instance.new("UICorner", themesBtn).CornerRadius = UDim.new(0,6)

local scrollFrameObj = Instance.new("ScrollingFrame"); scrollFrameObj.Name = "ScrollContent"; scrollFrameObj.Size = UDim2.new(1,-8,1,-80); scrollFrameObj.Position = UDim2.new(0,4,0,40); scrollFrameObj.BackgroundTransparency = 1; scrollFrameObj.ScrollBarThickness = 4; scrollFrameObj.ScrollBarImageColor3 = currentTheme.accent; scrollFrameObj.CanvasSize = UDim2.new(0,0,0,0); scrollFrameObj.AutomaticCanvasSize = Enum.AutomaticSize.Y; scrollFrameObj.Parent = menuFrame
Instance.new("UIListLayout", scrollFrameObj).SortOrder = Enum.SortOrder.LayoutOrder; Instance.new("UIListLayout", scrollFrameObj):Destroy()
local ll = Instance.new("UIListLayout"); ll.SortOrder = Enum.SortOrder.LayoutOrder; ll.Padding = UDim.new(0,6); ll.Parent = scrollFrameObj
local lp = Instance.new("UIPadding"); lp.PaddingLeft = UDim.new(0,4); lp.PaddingRight = UDim.new(0,4); lp.PaddingTop = UDim.new(0,2); lp.PaddingBottom = UDim.new(0,4); lp.Parent = scrollFrameObj

local emergencyBtnObj = Instance.new("TextButton"); emergencyBtnObj.Size = UDim2.new(1,-16,0,30); emergencyBtnObj.Position = UDim2.new(0.5,0,1,-38); emergencyBtnObj.AnchorPoint = Vector2.new(0.5,0); emergencyBtnObj.BackgroundColor3 = Color3.fromRGB(200,30,30); emergencyBtnObj.BorderSizePixel = 0; emergencyBtnObj.Text = "⚠ EMERGENCY STOP"; emergencyBtnObj.TextColor3 = Color3.fromRGB(255,255,255); emergencyBtnObj.TextSize = 13; emergencyBtnObj.Font = Enum.Font.GothamBold; emergencyBtnObj.ZIndex = 3; emergencyBtnObj.Parent = menuFrame; Instance.new("UICorner", emergencyBtnObj).CornerRadius = UDim.new(0,8); Instance.new("UIStroke", emergencyBtnObj).Color = Color3.fromRGB(255,80,80)

registerThemeable(function(t) menuFrame.BackgroundColor3 = t.bg; menuStrokeObj.Color = t.stroke; titleBarObj.BackgroundColor3 = t.titleBg; titleBarFixObj.BackgroundColor3 = t.titleBg; titleLabelObj.TextColor3 = t.text; minimizeBtn.BackgroundColor3 = t.secondary; minimizeBtn.TextColor3 = t.text; aboutBtn.BackgroundColor3 = t.secondary; aboutBtn.TextColor3 = t.text; themesBtn.BackgroundColor3 = t.secondary; themesBtn.TextColor3 = t.text; scrollFrameObj.ScrollBarImageColor3 = t.accent; if dashToggleStroke and dashEnabled then dashToggleStroke.Color = t.accent end end)

-- Dragging
local dragging, dragStart, frameStartPos = false, Vector2.zero, UDim2.new()
titleBarObj.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; dragStart = Vector2.new(i.Position.X, i.Position.Y); frameStartPos = menuFrame.Position end end)
UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local d = Vector2.new(i.Position.X, i.Position.Y) - dragStart; menuFrame.Position = UDim2.new(frameStartPos.X.Scale, frameStartPos.X.Offset + d.X, frameStartPos.Y.Scale, frameStartPos.Y.Offset + d.Y) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)

minimizeBtn.MouseButton1Click:Connect(function() menuOpen = not menuOpen; if menuOpen then menuFrame.Size = UDim2.new(0,250,0,450); scrollFrameObj.Visible = true; emergencyBtnObj.Visible = true; minimizeBtn.Text = "—" else menuFrame.Size = UDim2.new(0,250,0,36); scrollFrameObj.Visible = false; emergencyBtnObj.Visible = false; minimizeBtn.Text = "+" end end)

-- About Window
local aboutWindow = nil
aboutBtn.MouseButton1Click:Connect(function()
	if aboutWindow and aboutWindow.Parent then aboutWindow:Destroy(); aboutWindow = nil; return end
	aboutWindow = Instance.new("Frame"); aboutWindow.Size = UDim2.new(0,320,0,200); aboutWindow.Position = UDim2.new(0.5,0,0.5,0); aboutWindow.AnchorPoint = Vector2.new(0.5,0.5); aboutWindow.BackgroundColor3 = currentTheme.bg; aboutWindow.BackgroundTransparency = 0.05; aboutWindow.BorderSizePixel = 0; aboutWindow.Parent = screenGui; Instance.new("UICorner", aboutWindow).CornerRadius = UDim.new(0,14)
	Instance.new("UIStroke", aboutWindow).Color = currentTheme.stroke
	local ac = Instance.new("TextButton"); ac.Size = UDim2.new(0,30,0,30); ac.Position = UDim2.new(1,-8,0,8); ac.AnchorPoint = Vector2.new(1,0); ac.BackgroundColor3 = Color3.fromRGB(200,40,40); ac.BorderSizePixel = 0; ac.Text = "✕"; ac.TextColor3 = Color3.fromRGB(255,255,255); ac.TextSize = 16; ac.Font = Enum.Font.GothamBold; ac.Parent = aboutWindow; Instance.new("UICorner", ac).CornerRadius = UDim.new(0,8)
	ac.MouseButton1Click:Connect(function() aboutWindow:Destroy(); aboutWindow = nil end)
	local at = Instance.new("TextLabel"); at.Size = UDim2.new(1,-50,0,40); at.Position = UDim2.new(0,16,0,10); at.BackgroundTransparency = 1; at.Text = "About this"; at.TextColor3 = currentTheme.text; at.TextSize = 24; at.Font = Enum.Font.GothamBold; at.TextXAlignment = Enum.TextXAlignment.Left; at.Parent = aboutWindow
	local ab = Instance.new("TextLabel"); ab.Size = UDim2.new(1,-32,0,120); ab.Position = UDim2.new(0,16,0,55); ab.BackgroundTransparency = 1; ab.Text = "This script allows you to have dash abilities and also supernatural abilities.\n\nMade by rubix.\nVersion 4.2"; ab.TextColor3 = currentTheme.text; ab.TextSize = 14; ab.Font = Enum.Font.Gotham; ab.TextXAlignment = Enum.TextXAlignment.Left; ab.TextYAlignment = Enum.TextYAlignment.Top; ab.TextWrapped = true; ab.Parent = aboutWindow
end)

-- Themes Window
local themesWindow = nil
themesBtn.MouseButton1Click:Connect(function()
	if themesWindow and themesWindow.Parent then themesWindow:Destroy(); themesWindow = nil; return end
	themesWindow = Instance.new("Frame"); themesWindow.Size = UDim2.new(0,280,0,300); themesWindow.Position = UDim2.new(0.5,0,0.5,0); themesWindow.AnchorPoint = Vector2.new(0.5,0.5); themesWindow.BackgroundColor3 = currentTheme.bg; themesWindow.BackgroundTransparency = 0.05; themesWindow.BorderSizePixel = 0; themesWindow.Parent = screenGui; Instance.new("UICorner", themesWindow).CornerRadius = UDim.new(0,14)
	local tws = Instance.new("UIStroke"); tws.Color = currentTheme.stroke; tws.Thickness = 2; tws.Parent = themesWindow
	local twc = Instance.new("TextButton"); twc.Size = UDim2.new(0,30,0,30); twc.Position = UDim2.new(1,-8,0,8); twc.AnchorPoint = Vector2.new(1,0); twc.BackgroundColor3 = Color3.fromRGB(200,40,40); twc.BorderSizePixel = 0; twc.Text = "✕"; twc.TextColor3 = Color3.fromRGB(255,255,255); twc.TextSize = 16; twc.Font = Enum.Font.GothamBold; twc.Parent = themesWindow; Instance.new("UICorner", twc).CornerRadius = UDim.new(0,8)
	twc.MouseButton1Click:Connect(function() themesWindow:Destroy(); themesWindow = nil end)
	local twt = Instance.new("TextLabel"); twt.Size = UDim2.new(1,-50,0,30); twt.Position = UDim2.new(0,16,0,10); twt.BackgroundTransparency = 1; twt.Text = "🎨 Themes"; twt.TextColor3 = currentTheme.text; twt.TextSize = 18; twt.Font = Enum.Font.GothamBold; twt.TextXAlignment = Enum.TextXAlignment.Left; twt.Parent = themesWindow
	local twsf = Instance.new("ScrollingFrame"); twsf.Size = UDim2.new(1,-16,1,-50); twsf.Position = UDim2.new(0,8,0,44); twsf.BackgroundTransparency = 1; twsf.ScrollBarThickness = 3; twsf.CanvasSize = UDim2.new(0,0,0,0); twsf.AutomaticCanvasSize = Enum.AutomaticSize.Y; twsf.Parent = themesWindow
	local twg = Instance.new("UIGridLayout"); twg.CellSize = UDim2.new(0,75,0,36); twg.CellPadding = UDim2.new(0,6,0,6); twg.SortOrder = Enum.SortOrder.LayoutOrder; twg.Parent = twsf
	for i, name in {"Red","Orange","Yellow","Green","Blue","Purple","Pink","Brown","Black","White","Grey"} do
		local t = themes[name]; local tb = Instance.new("TextButton"); tb.Size = UDim2.new(0,75,0,36); tb.BackgroundColor3 = t.primary; tb.BorderSizePixel = 0; tb.Text = name; tb.TextSize = 11; tb.Font = Enum.Font.GothamBold; tb.LayoutOrder = i
		tb.TextColor3 = (name == "Black" or name == "Brown" or name == "Purple" or name == "Blue" or name == "Red") and Color3.fromRGB(255,255,255) or Color3.fromRGB(20,20,20)
		tb.Parent = twsf; Instance.new("UICorner", tb).CornerRadius = UDim.new(0,8)
		tb.MouseButton1Click:Connect(function() setTheme(name); themesWindow.BackgroundColor3 = currentTheme.bg; tws.Color = currentTheme.stroke; twt.TextColor3 = currentTheme.text end)
	end
end)

-- ============================================
-- ABILITY BUTTON CREATOR
-- ============================================
local function createAbilityButton(name, color, description, keybind, layoutOrder, note, rainbowName, opText, monochromeName)
	local totalHeight = 60; if note then totalHeight = 78 end; if opText then totalHeight += 16 end
	local btn = Instance.new("TextButton"); btn.Name = name; btn.Size = UDim2.new(1,0,0,totalHeight); btn.BackgroundColor3 = Color3.fromRGB(35,35,55); btn.BorderSizePixel = 0; btn.Text = ""; btn.LayoutOrder = layoutOrder; btn.AutoButtonColor = true; btn.Parent = scrollFrameObj; Instance.new("UICorner", btn).CornerRadius = UDim.new(0,10)
	local bs = Instance.new("UIStroke"); bs.Color = color; bs.Thickness = 1.5; bs.Transparency = 0.4; bs.Parent = btn
	local nl = Instance.new("TextLabel"); nl.Size = UDim2.new(1,-10,0,22); nl.Position = UDim2.new(0,8,0,4); nl.BackgroundTransparency = 1; nl.Text = name.."  ["..keybind.."]"; nl.TextColor3 = color; nl.TextSize = 14; nl.Font = Enum.Font.GothamBold; nl.TextXAlignment = Enum.TextXAlignment.Left; nl.Parent = btn
	if rainbowName then task.spawn(function() local t = 0; while btn and btn.Parent do t += 0.02; nl.TextColor3 = getRainbowColor(t); bs.Color = getRainbowColor(t+0.3); task.wait(0.03) end end) end
	if monochromeName then task.spawn(function() local t = 0; while btn and btn.Parent do t += 0.03; nl.TextColor3 = getMonochromeColor(t); bs.Color = getMonochromeColor(t+1); task.wait(0.03) end end) end
	local yO = 24
	if opText then local ol = Instance.new("TextLabel"); ol.Size = UDim2.new(0,40,0,16); ol.Position = UDim2.new(0,8,0,yO); ol.BackgroundTransparency = 1; ol.Text = "OP!"; ol.TextSize = 13; ol.Font = Enum.Font.GothamBold; ol.TextXAlignment = Enum.TextXAlignment.Left; ol.Parent = btn; task.spawn(function() local t = 0; while ol and ol.Parent do t += 0.03; ol.TextColor3 = getRainbowColor(t); task.wait(0.03) end end); yO += 16 end
	local dl = Instance.new("TextLabel"); dl.Size = UDim2.new(1,-10,0,16); dl.Position = UDim2.new(0,8,0,yO); dl.BackgroundTransparency = 1; dl.Text = description; dl.TextColor3 = Color3.fromRGB(150,150,170); dl.TextSize = 11; dl.Font = Enum.Font.Gotham; dl.TextXAlignment = Enum.TextXAlignment.Left; dl.TextWrapped = true; dl.Parent = btn; yO += 16
	if note then local ntl = Instance.new("TextLabel"); ntl.Size = UDim2.new(1,-10,0,14); ntl.Position = UDim2.new(0,8,0,yO); ntl.BackgroundTransparency = 1; ntl.Text = "📌 "..note; ntl.TextColor3 = Color3.fromRGB(255,220,100); ntl.TextSize = 10; ntl.Font = Enum.Font.GothamMedium; ntl.TextXAlignment = Enum.TextXAlignment.Left; ntl.TextWrapped = true; ntl.Parent = btn end
	local cdbg = Instance.new("Frame"); cdbg.Size = UDim2.new(1,-16,0,4); cdbg.Position = UDim2.new(0,8,1,-10); cdbg.BackgroundColor3 = Color3.fromRGB(20,20,30); cdbg.BorderSizePixel = 0; cdbg.Parent = btn; Instance.new("UICorner", cdbg).CornerRadius = UDim.new(0,2)
	local cdf = Instance.new("Frame"); cdf.Size = UDim2.new(1,0,1,0); cdf.BackgroundColor3 = color; cdf.BorderSizePixel = 0; cdf.Parent = cdbg; Instance.new("UICorner", cdf).CornerRadius = UDim.new(0,2)
	if rainbowName then task.spawn(function() local t = 0; while cdf and cdf.Parent do t += 0.02; cdf.BackgroundColor3 = getRainbowColor(t); task.wait(0.03) end end) end
	if monochromeName then task.spawn(function() local t = 0; while cdf and cdf.Parent do t += 0.03; cdf.BackgroundColor3 = getMonochromeColor(t); task.wait(0.03) end end) end
	registerThemeable(function(theme) btn.BackgroundColor3 = Color3.new(theme.bg.R+0.06, theme.bg.G+0.06, theme.bg.B+0.1); dl.TextColor3 = Color3.fromRGB(math.clamp(theme.text.R*255*0.7,0,255), math.clamp(theme.text.G*255*0.7,0,255), math.clamp(theme.text.B*255*0.7,0,255)) end)
	return btn, cdf, bs
end

local platformBtn, platformCdBar = createAbilityButton("Platform", Color3.fromRGB(0,130,255), "Spawns a platform that follows you", "Q", 1)
local lungeBtn, lungeCdBar = createAbilityButton("Lunge", Color3.fromRGB(255,80,50), "Dash 100 studs at 1.7x speed", "E", 2)
local megaJumpBtn, megaJumpCdBar, megaJumpStroke = createAbilityButton("Mega Jump", Color3.fromRGB(50,255,100), "6x jump power + reduced gravity", "R", 3, "Perfect to beat a average tower!")
local gigaJumpBtn, gigaJumpCdBar, gigaJumpStroke = createAbilityButton("Giga Jump", Color3.fromRGB(255,140,30), "12x jump power + 0.4x gravity", "V", 4, "When Mega Jump isn't enough!")
local shockwaveBtn, shockwaveCdBar = createAbilityButton("Shockwave Travel", Color3.fromRGB(160,50,255), "c00lkidd wannabe(s) will LOVE THIS!", "T", 5)
local fusionBtn, fusionCdBar = createAbilityButton("Fusion Leveler", Color3.fromRGB(255,200,50), "Speed x1.5, Jump=110, Gravity 50% for 15s", "F", 6)
local rainbowBtn, rainbowCdBar = createAbilityButton("Rainbow Locator", Color3.fromRGB(255,0,0), "Select a destination and travel there!", "G", 7, "Go to destinations like never before!", true, true)
local immortalBtn, immortalCdBar = createAbilityButton("Immortality Shield", Color3.fromRGB(180,180,180), "A tool to make you temporairly immortal", "H", 8, nil, false, false, true)
local miniDashBtn, miniDashCdBar = createAbilityButton("Mini Dash", Color3.fromRGB(100,180,255), "Quick 20-stud forward dash", "C", 9)

local function animateCooldown(bar, duration) bar.Size = UDim2.new(0,0,1,0); TweenService:Create(bar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(1,0,1,0)}):Play() end

-- ============================================
-- DASH VFX
-- ============================================
local function createDashVFX(character, color)
	local rp = character:FindFirstChild("HumanoidRootPart"); if not rp then return end
	local c = color or Color3.fromRGB(0,170,255)
	local a0 = Instance.new("Attachment"); a0.Position = Vector3.new(0,1,0); a0.Parent = rp
	local a1 = Instance.new("Attachment"); a1.Position = Vector3.new(0,-1,0); a1.Parent = rp
	local tr = Instance.new("Trail"); tr.Attachment0 = a0; tr.Attachment1 = a1; tr.Lifetime = 0.2; tr.MinLength = 0.1; tr.FaceCamera = true; tr.Color = ColorSequence.new(c)
	tr.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.3), NumberSequenceKeypoint.new(1,1)}); tr.WidthScale = NumberSequence.new({NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0)}); tr.Parent = rp
	local pe = Instance.new("ParticleEmitter"); pe.Color = ColorSequence.new(c); pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.5), NumberSequenceKeypoint.new(1,0)}); pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.5), NumberSequenceKeypoint.new(1,1)}); pe.Lifetime = NumberRange.new(0.15,0.3); pe.Rate = 100; pe.Speed = NumberRange.new(5,15); pe.SpreadAngle = Vector2.new(30,30); pe.Parent = rp
	return {cleanup = function(d) local dt2 = d or 0.35; task.delay(dt2, function() pe.Rate = 0 end); task.delay(dt2+0.5, function() tr:Destroy(); pe:Destroy(); a0:Destroy(); a1:Destroy() end) end}
end

-- ============================================
-- GENERIC DASH
-- ============================================
local function genericDash(distance, duration, color, soundSpeed)
	local ch = player.Character; if not ch then return end
	local hum = ch:FindFirstChildOfClass("Humanoid"); local rp = ch:FindFirstChild("HumanoidRootPart")
	if not hum or not rp or hum.Health <= 0 then return end
	local md = hum.MoveDirection; local dd
	if md.Magnitude > 0.1 then dd = md.Unit else dd = rp.CFrame.LookVector end
	dd = Vector3.new(dd.X,0,dd.Z); if dd.Magnitude < 0.1 then dd = Vector3.new(rp.CFrame.LookVector.X,0,rp.CFrame.LookVector.Z) end; dd = dd.Unit
	local vfx = createDashVFX(ch, color); playSound(rp, "rbxassetid://7471006063", 0.5, soundSpeed or 1.3)
	rp.CFrame = CFrame.new(rp.Position, rp.Position + dd)
	local att = Instance.new("Attachment"); att.Parent = rp
	local lv = Instance.new("LinearVelocity"); lv.Attachment0 = att; lv.RelativeTo = Enum.ActuatorRelativeTo.World; lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector; lv.MaxForce = 50000; lv.VectorVelocity = dd * (distance/duration); lv.Parent = rp
	local ag = Instance.new("LinearVelocity"); ag.Attachment0 = att; ag.RelativeTo = Enum.ActuatorRelativeTo.World; ag.VelocityConstraintMode = Enum.VelocityConstraintMode.Line; ag.LineDirection = Vector3.yAxis; ag.MaxForce = 5000; ag.LineVelocity = 0; ag.Parent = rp
	task.delay(duration, function()
		while true do if not rp or not rp.Parent or hum.Health <= 0 then break end
			if not isVoidBelow(rp.Position) or isOnCollidableSurface(rp) then break end
			local av = checkHeadObstacle(rp); if av and lv.Parent then lv.VectorVelocity = (dd+av*0.5).Unit * lv.VectorVelocity.Magnitude end; task.wait(0.05) end
		if lv.Parent then lv:Destroy() end; if ag.Parent then ag:Destroy() end; if att.Parent then att:Destroy() end
		if vfx then vfx.cleanup(0) end
		if rp and rp.Parent then local sa = Instance.new("Attachment"); sa.Parent = rp; local sv = Instance.new("LinearVelocity"); sv.Attachment0 = sa; sv.RelativeTo = Enum.ActuatorRelativeTo.World; sv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector; sv.MaxForce = 20000; sv.VectorVelocity = dd*10; sv.Parent = rp
			task.spawn(function() for i = 1, 6 do task.wait(0.03); if sv.Parent then sv.VectorVelocity *= 0.5 end end; if sv.Parent then sv:Destroy() end; if sa.Parent then sa:Destroy() end end) end
	end)
end

-- JUMP DASH
local function performDash()
	if not dashEnabled or not canDash or isDashing then return end
	local ch = player.Character; if not ch then return end; local hum = ch:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 or hum.FloorMaterial ~= Enum.Material.Air then return end
	isDashing = true; canDash = false; genericDash(DASH_DISTANCE, DASH_DURATION, Color3.fromRGB(0,170,255), 1.3)
	task.spawn(function() task.wait(DASH_DURATION+0.1); isDashing = false end)
	dashCooldownBar.Size = UDim2.new(0,0,0,3); TweenService:Create(dashCooldownBar, TweenInfo.new(DASH_COOLDOWN, Enum.EasingStyle.Linear), {Size = UDim2.new(1,0,0,3)}):Play()
	task.spawn(function() task.wait(DASH_COOLDOWN); canDash = true end)
end

-- MINI DASH
local function activateMiniDash()
	if not canMiniDash then return end; local ch = player.Character; if not ch then return end; local hum = ch:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health <= 0 then return end
	canMiniDash = false; genericDash(MINI_DASH_DISTANCE, MINI_DASH_DURATION, Color3.fromRGB(100,180,255), 1.6)
	animateCooldown(miniDashCdBar, MINI_DASH_COOLDOWN); task.spawn(function() task.wait(MINI_DASH_COOLDOWN); canMiniDash = true end)
end

-- PLATFORM
local function activatePlatform()
	if not canPlatform or platformActive then return end; local ch = player.Character; if not ch then return end
	local hum = ch:FindFirstChildOfClass("Humanoid"); local rp = ch:FindFirstChild("HumanoidRootPart")
	if not hum or not rp or hum.Health <= 0 then return end
	platformActive = true; canPlatform = false
	local pl = Instance.new("Part"); pl.Name = "AbilityPlatform"; pl.Size = PLATFORM_SIZE; pl.Material = Enum.Material.Neon; pl.Color = Color3.fromRGB(0,130,255); pl.Transparency = 0.5; pl.Anchored = true; pl.CanCollide = true; pl.Position = rp.Position - Vector3.new(0,4,0); pl.Parent = workspace
	local sp = Instance.new("ParticleEmitter"); sp.Color = ColorSequence.new(Color3.fromRGB(255,50,50)); sp.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.3), NumberSequenceKeypoint.new(0.5,0.6), NumberSequenceKeypoint.new(1,0)}); sp.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.2), NumberSequenceKeypoint.new(1,1)}); sp.Lifetime = NumberRange.new(0.5,1.2); sp.Rate = 40; sp.Speed = NumberRange.new(2,6); sp.SpreadAngle = Vector2.new(180,180); sp.LightEmission = 0.8; sp.Texture = "rbxassetid://6490035152"; sp.Parent = pl
	currentPlatform = pl; playSound(rp, "rbxassetid://3199270999", 0.4, 1.2)
	platformFollowConn = RunService.Heartbeat:Connect(function() if not pl or not pl.Parent then if platformFollowConn then platformFollowConn:Disconnect(); platformFollowConn = nil end; return end; if not rp or not rp.Parent then return end; pl.Position = pl.Position:Lerp(Vector3.new(rp.Position.X, rp.Position.Y-4, rp.Position.Z), 0.2) end)
	task.spawn(function() task.wait(PLATFORM_DURATION-2); if pl and pl.Parent then for i = 1, 20 do task.wait(0.1); if pl and pl.Parent then pl.Transparency = 0.5+(i/20)*0.5 end end end; if platformFollowConn then platformFollowConn:Disconnect(); platformFollowConn = nil end; if pl and pl.Parent then pl:Destroy() end; currentPlatform = nil; platformActive = false; animateCooldown(platformCdBar, PLATFORM_COOLDOWN); task.wait(PLATFORM_COOLDOWN); canPlatform = true end)
end

-- LUNGE
local function activateLunge()
	if not canLunge or isLunging then return end; local ch = player.Character; if not ch then return end
	local hum = ch:FindFirstChildOfClass("Humanoid"); local rp = ch:FindFirstChild("HumanoidRootPart")
	if not hum or not rp or hum.Health <= 0 then return end
	isLunging = true; canLunge = false
	local md = hum.MoveDirection; local ld; if md.Magnitude > 0.1 then ld = md.Unit else ld = rp.CFrame.LookVector end
	ld = Vector3.new(ld.X,0,ld.Z); if ld.Magnitude < 0.1 then ld = Vector3.new(rp.CFrame.LookVector.X,0,rp.CFrame.LookVector.Z) end; ld = ld.Unit
	local ls = (DASH_DISTANCE/DASH_DURATION)*LUNGE_SPEED_MULT; local ldur = LUNGE_DISTANCE/ls
	local vfx = createDashVFX(ch, Color3.fromRGB(255,80,50)); playSound(rp, "rbxassetid://7471006063", 0.7, 0.8)
	rp.CFrame = CFrame.new(rp.Position, rp.Position+ld)
	local att = Instance.new("Attachment"); att.Parent = rp
	local lv = Instance.new("LinearVelocity"); lv.Attachment0 = att; lv.RelativeTo = Enum.ActuatorRelativeTo.World; lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector; lv.MaxForce = 80000; lv.VectorVelocity = ld*ls; lv.Parent = rp
	local ag = Instance.new("LinearVelocity"); ag.Attachment0 = att; ag.RelativeTo = Enum.ActuatorRelativeTo.World; ag.VelocityConstraintMode = Enum.VelocityConstraintMode.Line; ag.LineDirection = Vector3.yAxis; ag.MaxForce = 8000; ag.LineVelocity = 0; ag.Parent = rp
	task.spawn(function() for i = 1, 10 do if not isLunging then break end; hum.CameraOffset = Vector3.new(math.random(-10,10)/80, math.random(-10,10)/80, 0); task.wait(0.05) end; hum.CameraOffset = Vector3.zero end)
	task.delay(ldur, function()
		while true do if not rp or not rp.Parent or hum.Health <= 0 then break end; if isOnCollidableSurface(rp) or not isVoidBelow(rp.Position) then break end
			local av = checkHeadObstacle(rp); if av and lv.Parent then lv.VectorVelocity = (ld+av*0.5).Unit*lv.VectorVelocity.Magnitude end; task.wait(0.05) end
		if lv.Parent then lv:Destroy() end; if ag.Parent then ag:Destroy() end; if att.Parent then att:Destroy() end; isLunging = false; if vfx then vfx.cleanup(0) end
		if rp and rp.Parent then local sa = Instance.new("Attachment"); sa.Parent = rp; local sv = Instance.new("LinearVelocity"); sv.Attachment0 = sa; sv.RelativeTo = Enum.ActuatorRelativeTo.World; sv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector; sv.MaxForce = 30000; sv.VectorVelocity = ld*20; sv.Parent = rp
			task.spawn(function() for i = 1, 10 do task.wait(0.03); if sv.Parent then sv.VectorVelocity *= 0.55 end end; if sv.Parent then sv:Destroy() end; if sa.Parent then sa:Destroy() end end) end
		animateCooldown(lungeCdBar, LUNGE_COOLDOWN); task.wait(LUNGE_COOLDOWN); canLunge = true end)
end

-- ============================================
-- VFX HELPERS
-- ============================================
local function createShockwave(position, color)
	local c = color or Color3.fromRGB(50,255,100); local r = Instance.new("Part"); r.Anchored = true; r.CanCollide = false; r.Shape = Enum.PartType.Cylinder; r.Size = Vector3.new(0.5,4,4); r.CFrame = CFrame.new(position)*CFrame.Angles(0,0,math.rad(90)); r.Material = Enum.Material.Neon; r.Color = c; r.Transparency = 0.3; r.Parent = workspace
	local t = TweenService:Create(r, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(0.5,60,60), Transparency = 1}); t:Play(); t.Completed:Connect(function() r:Destroy() end)
end
local function createPillar(position, color, height)
	local c = color or Color3.fromRGB(50,255,100); local h = height or 80
	local p = Instance.new("Part"); p.Anchored = true; p.CanCollide = false; p.Size = Vector3.new(5,0,5); p.CFrame = CFrame.new(position); p.Material = Enum.Material.Neon; p.Color = c; p.Transparency = 0.5; p.Parent = workspace
	TweenService:Create(p, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(5,h,5), CFrame = CFrame.new(position+Vector3.new(0,h/2,0))}):Play()
	task.delay(0.6, function() local f = TweenService:Create(p, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {Transparency = 1, Size = Vector3.new(2,h,2)}); f:Play(); f.Completed:Connect(function() p:Destroy() end) end)
end
local function createRainbowShockwave(position)
	local r = Instance.new("Part"); r.Anchored = true; r.CanCollide = false; r.Shape = Enum.PartType.Cylinder; r.Size = Vector3.new(0.5,4,4); r.CFrame = CFrame.new(position)*CFrame.Angles(0,0,math.rad(90)); r.Material = Enum.Material.Neon; r.Transparency = 0.2; r.Parent = workspace
	task.spawn(function() local st = tick(); while r and r.Parent and (tick()-st) < 1 do r.Color = getRainbowColor((tick()-st)*2); task.wait() end end)
	local t = TweenService:Create(r, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(0.5,80,80), Transparency = 1}); t:Play(); t.Completed:Connect(function() r:Destroy() end)
end
local function createRainbowPillar(position)
	local p = Instance.new("Part"); p.Anchored = true; p.CanCollide = false; p.Size = Vector3.new(5,0,5); p.CFrame = CFrame.new(position); p.Material = Enum.Material.Neon; p.Transparency = 0.4; p.Parent = workspace
	task.spawn(function() local st = tick(); while p and p.Parent and (tick()-st) < 2 do p.Color = getRainbowColor((tick()-st)*1.5); task.wait() end end)
	TweenService:Create(p, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(5,100,5), CFrame = CFrame.new(position+Vector3.new(0,50,0))}):Play()
	task.delay(0.8, function() local f = TweenService:Create(p, TweenInfo.new(0.8, Enum.EasingStyle.Quad), {Transparency = 1, Size = Vector3.new(2,100,2)}); f:Play(); f.Completed:Connect(function() p:Destroy() end) end)
end

-- ============================================
-- MEGA JUMP
-- ============================================
local function activateMegaJump() if not canMegaJump then return end; megaJumpArmed = not megaJumpArmed
	if megaJumpArmed then megaJumpStroke.Color = Color3.fromRGB(150,255,150); megaJumpStroke.Thickness = 3; task.spawn(function() while megaJumpArmed do if megaJumpStroke then TweenService:Create(megaJumpStroke, TweenInfo.new(0.5), {Transparency = 0.6}):Play() end; task.wait(0.5); if megaJumpArmed and megaJumpStroke then TweenService:Create(megaJumpStroke, TweenInfo.new(0.5), {Transparency = 0}):Play() end; task.wait(0.5) end end)
	else megaJumpStroke.Color = Color3.fromRGB(50,255,100); megaJumpStroke.Thickness = 1.5; megaJumpStroke.Transparency = 0.4 end end

local function performMegaJump()
	if not megaJumpArmed or not canMegaJump then return end; local ch = player.Character; if not ch then return end
	local hum = ch:FindFirstChildOfClass("Humanoid"); local rp = ch:FindFirstChild("HumanoidRootPart"); if not hum or not rp or hum.Health <= 0 then return end
	megaJumpArmed = false; canMegaJump = false; isMegaJumping = true; megaJumpStroke.Color = Color3.fromRGB(50,255,100); megaJumpStroke.Thickness = 1.5; megaJumpStroke.Transparency = 0.4
	createShockwave(rp.Position); createPillar(rp.Position); playSound(rp, "rbxassetid://3199270999", 0.8, 0.7)
	local njp = hum.JumpPower; if njp == 0 then njp = 50 end
	local att = Instance.new("Attachment"); att.Parent = rp; local jv = Instance.new("LinearVelocity"); jv.Attachment0 = att; jv.RelativeTo = Enum.ActuatorRelativeTo.World; jv.VelocityConstraintMode = Enum.VelocityConstraintMode.Line; jv.LineDirection = Vector3.yAxis; jv.MaxForce = 80000; jv.LineVelocity = njp*MEGA_JUMP_MULT; jv.Parent = rp
	task.delay(0.15, function() if jv.Parent then jv:Destroy() end; if att.Parent then att:Destroy() end end)
	megaJumpGravityActive = true; local sg = workspace.Gravity; workspace.Gravity = sg*MEGA_JUMP_GRAVITY_SCALE
	local jp = Instance.new("ParticleEmitter"); jp.Color = ColorSequence.new(Color3.fromRGB(50,255,100)); jp.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.4), NumberSequenceKeypoint.new(1,0)}); jp.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.3), NumberSequenceKeypoint.new(1,1)}); jp.Lifetime = NumberRange.new(0.3,0.8); jp.Rate = 60; jp.Speed = NumberRange.new(1,4); jp.SpreadAngle = Vector2.new(180,180); jp.LightEmission = 0.6; jp.Parent = rp
	task.spawn(function() task.wait(0.3); while true do if not rp or not rp.Parent or hum.Health <= 0 then break end; local s = hum:GetState(); if s == Enum.HumanoidStateType.Landed or s == Enum.HumanoidStateType.Running then break end; task.wait(0.05) end
		if megaJumpGravityActive then workspace.Gravity = sg; megaJumpGravityActive = false end; isMegaJumping = false
		if rp and rp.Parent then createShockwave(rp.Position); playSound(rp, "rbxassetid://3199270999", 0.4, 1.5) end
		jp.Rate = 0; task.delay(1, function() if jp.Parent then jp:Destroy() end end); animateCooldown(megaJumpCdBar, MEGA_JUMP_COOLDOWN); task.wait(MEGA_JUMP_COOLDOWN); canMegaJump = true end)
end

-- ============================================
-- GIGA JUMP
-- ============================================
local function activateGigaJump() if not canGigaJump then return end; gigaJumpArmed = not gigaJumpArmed
	if gigaJumpArmed then gigaJumpStroke.Color = Color3.fromRGB(255,200,100); gigaJumpStroke.Thickness = 3; task.spawn(function() while gigaJumpArmed do if gigaJumpStroke then TweenService:Create(gigaJumpStroke, TweenInfo.new(0.4), {Transparency = 0.6}):Play() end; task.wait(0.4); if gigaJumpArmed and gigaJumpStroke then TweenService:Create(gigaJumpStroke, TweenInfo.new(0.4), {Transparency = 0}):Play() end; task.wait(0.4) end end)
	else gigaJumpStroke.Color = Color3.fromRGB(255,140,30); gigaJumpStroke.Thickness = 1.5; gigaJumpStroke.Transparency = 0.4 end end

local function performGigaJump()
	if not gigaJumpArmed or not canGigaJump then return end; local ch = player.Character; if not ch then return end
	local hum = ch:FindFirstChildOfClass("Humanoid"); local rp = ch:FindFirstChild("HumanoidRootPart"); if not hum or not rp or hum.Health <= 0 then return end
	gigaJumpArmed = false; canGigaJump = false; isGigaJumping = true; gigaJumpStroke.Color = Color3.fromRGB(255,140,30); gigaJumpStroke.Thickness = 1.5; gigaJumpStroke.Transparency = 0.4
	local oc = Color3.fromRGB(255,140,30)
	createShockwave(rp.Position, oc); task.delay(0.1, function() createShockwave(rp.Position, Color3.fromRGB(255,80,0)) end)
	createPillar(rp.Position, oc, 120); playSound(rp, "rbxassetid://3199270999", 1, 0.5)
	local njp = hum.JumpPower; if njp == 0 then njp = 50 end
	local att = Instance.new("Attachment"); att.Parent = rp; local jv = Instance.new("LinearVelocity"); jv.Attachment0 = att; jv.RelativeTo = Enum.ActuatorRelativeTo.World; jv.VelocityConstraintMode = Enum.VelocityConstraintMode.Line; jv.LineDirection = Vector3.yAxis; jv.MaxForce = 120000; jv.LineVelocity = njp*GIGA_JUMP_MULT; jv.Parent = rp
	task.delay(0.18, function() if jv.Parent then jv:Destroy() end; if att.Parent then att:Destroy() end end)
	gigaJumpGravityActive = true; local sg = workspace.Gravity; workspace.Gravity = sg*GIGA_JUMP_GRAVITY_SCALE
	local jp = Instance.new("ParticleEmitter"); jp.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,160,30)), ColorSequenceKeypoint.new(1,Color3.fromRGB(255,80,0))}); jp.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.6), NumberSequenceKeypoint.new(1,0)}); jp.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.2), NumberSequenceKeypoint.new(1,1)}); jp.Lifetime = NumberRange.new(0.4,1); jp.Rate = 80; jp.Speed = NumberRange.new(2,6); jp.SpreadAngle = Vector2.new(180,180); jp.LightEmission = 0.8; jp.Parent = rp
	local lt = Instance.new("PointLight"); lt.Color = oc; lt.Brightness = 3; lt.Range = 30; lt.Parent = rp
	task.spawn(function() for i = 1, 15 do if not rp or not rp.Parent then break end; hum.CameraOffset = Vector3.new(math.random(-15,15)/50, math.random(-15,15)/50, 0); task.wait(0.04) end; if hum and hum.Parent then hum.CameraOffset = Vector3.zero end end)
	task.spawn(function() task.wait(0.4); while true do if not rp or not rp.Parent or hum.Health <= 0 then break end; local s = hum:GetState(); if s == Enum.HumanoidStateType.Landed or s == Enum.HumanoidStateType.Running then break end; task.wait(0.05) end
		if gigaJumpGravityActive then workspace.Gravity = sg; gigaJumpGravityActive = false end; isGigaJumping = false
		if rp and rp.Parent then createShockwave(rp.Position, oc); createShockwave(rp.Position, Color3.fromRGB(255,80,0)); playSound(rp, "rbxassetid://3199270999", 0.6, 1.3)
			task.spawn(function() for i = 1, 10 do if not hum or not hum.Parent then break end; hum.CameraOffset = Vector3.new(math.random(-20,20)/50, math.random(-20,20)/50, 0); task.wait(0.03) end; if hum and hum.Parent then hum.CameraOffset = Vector3.zero end end) end
		jp.Rate = 0; task.delay(1, function() if jp.Parent then jp:Destroy() end; if lt.Parent then lt:Destroy() end end)
		animateCooldown(gigaJumpCdBar, GIGA_JUMP_COOLDOWN); task.wait(GIGA_JUMP_COOLDOWN); canGigaJump = true end)
end

-- ============================================
-- SHOCKWAVE TRAVEL
-- ============================================
local function cleanupShockwaveTravel() shockwaveEmergencyStop = true; isShockwaveTraveling = false; for _, p in shockwaveTunnelParts do if p and p.Parent then p:Destroy() end end; shockwaveTunnelParts = {}; local ch = player.Character; if ch then local rp = ch:FindFirstChild("HumanoidRootPart"); if rp then for _, c in rp:GetChildren() do if c.Name == "ShockwaveVel" or c.Name == "ShockwaveAntiGrav" or c.Name == "ShockwaveAttach" then c:Destroy() end end end end end

local function activateShockwaveTravel()
	if not canShockwaveTravel or isShockwaveTraveling then return end; local ch = player.Character; if not ch then return end
	local hum = ch:FindFirstChildOfClass("Humanoid"); local rp = ch:FindFirstChild("HumanoidRootPart"); local head = ch:FindFirstChild("Head")
	if not hum or not rp or not head or hum.Health <= 0 then return end
	canShockwaveTravel = false; shockwaveEmergencyStop = false
	local md = hum.MoveDirection; local td; if md.Magnitude > 0.1 then td = md.Unit else td = rp.CFrame.LookVector end
	td = Vector3.new(td.X,0,td.Z); if td.Magnitude < 0.1 then td = Vector3.new(rp.CFrame.LookVector.X,0,rp.CFrame.LookVector.Z) end; td = td.Unit
	for i = 1, 10 do if shockwaveEmergencyStop then break end
		local sp = Instance.new("Part"); sp.Shape = Enum.PartType.Ball; sp.Anchored = true; sp.CanCollide = false; sp.Size = Vector3.new(3,3,3); sp.Position = head.Position; sp.Material = Enum.Material.Neon; sp.Color = Color3.fromRGB(160,50,255); sp.Transparency = 0.3; sp.Parent = workspace
		playSound(rp, "rbxassetid://3199270999", 0.3+(i*0.05), 0.8+(i*0.15)); local es = 8+(i*3)
		local tw = TweenService:Create(sp, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(es,es,es), Transparency = 1}); tw:Play(); tw.Completed:Connect(function() sp:Destroy() end)
		local d = 0.4-(i*0.035); if d < 0.05 then d = 0.05 end; task.wait(d) end
	if shockwaveEmergencyStop then animateCooldown(shockwaveCdBar, SHOCKWAVE_TRAVEL_COOLDOWN); task.wait(SHOCKWAVE_TRAVEL_COOLDOWN); canShockwaveTravel = true; return end
	local cube = Instance.new("Part"); cube.Anchored = true; cube.CanCollide = false; cube.Size = Vector3.new(4,4,4); cube.Position = head.Position; cube.Material = Enum.Material.Neon; cube.Color = Color3.fromRGB(160,50,255); cube.Transparency = 0.3; cube.Parent = workspace
	playSound(rp, "rbxassetid://3199270999", 1, 0.5); task.spawn(function() local st = tick(); while tick()-st < 1 do if cube and cube.Parent then cube.CFrame = cube.CFrame*CFrame.Angles(0.1,0.1,0.05) end; task.wait() end end)
	TweenService:Create(cube, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(30,30,30), Transparency = 1}):Play(); task.delay(1.1, function() if cube and cube.Parent then cube:Destroy() end end); task.wait(0.5)
	if shockwaveEmergencyStop then animateCooldown(shockwaveCdBar, SHOCKWAVE_TRAVEL_COOLDOWN); task.wait(SHOCKWAVE_TRAVEL_COOLDOWN); canShockwaveTravel = true; return end
	isShockwaveTraveling = true; rp.CFrame = CFrame.new(rp.Position, rp.Position+td)
	local sA = Instance.new("Attachment"); sA.Name = "ShockwaveAttach"; sA.Parent = rp
	local sV = Instance.new("LinearVelocity"); sV.Name = "ShockwaveVel"; sV.Attachment0 = sA; sV.RelativeTo = Enum.ActuatorRelativeTo.World; sV.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector; sV.MaxForce = 100000; sV.VectorVelocity = td*SHOCKWAVE_TRAVEL_SPEED; sV.Parent = rp
	local sG = Instance.new("LinearVelocity"); sG.Name = "ShockwaveAntiGrav"; sG.Attachment0 = sA; sG.RelativeTo = Enum.ActuatorRelativeTo.World; sG.VelocityConstraintMode = Enum.VelocityConstraintMode.Line; sG.LineDirection = Vector3.yAxis; sG.MaxForce = 10000; sG.LineVelocity = 0; sG.Parent = rp
	local tp = Instance.new("ParticleEmitter"); tp.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(160,50,255)), ColorSequenceKeypoint.new(1,Color3.fromRGB(100,20,200))}); tp.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.8), NumberSequenceKeypoint.new(1,0)}); tp.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.3), NumberSequenceKeypoint.new(1,1)}); tp.Lifetime = NumberRange.new(0.2,0.5); tp.Rate = 150; tp.Speed = NumberRange.new(8,20); tp.SpreadAngle = Vector2.new(15,15); tp.LightEmission = 0.8; tp.Parent = head
	task.spawn(function()
		local tS = tick(); local lR = 0
		while isShockwaveTraveling and not shockwaveEmergencyStop do if not rp or not rp.Parent or hum.Health <= 0 then break end
			local av = checkHeadObstacle(rp); if av and sV.Parent then sV.VectorVelocity = (td+av*0.7).Unit*sV.VectorVelocity.Magnitude end
			if tick()-lR > 0.08 then lR = tick(); local ring = Instance.new("Part"); ring.Name = "TunnelRing"; ring.Anchored = true; ring.CanCollide = false; ring.Shape = Enum.PartType.Cylinder; ring.Size = Vector3.new(0.3,14,14)
				ring.CFrame = CFrame.lookAt(head.Position+td*(15+math.random(0,10))+Vector3.new(math.random(-20,20)/10,math.random(-20,20)/10,math.random(-20,20)/10), head.Position+td*30)*CFrame.Angles(0,math.rad(90),0)
				ring.Material = Enum.Material.Neon; ring.Color = Color3.fromRGB(160,50,255); ring.Transparency = 0.4; ring.Parent = workspace; table.insert(shockwaveTunnelParts, ring)
				task.delay(1.5, function() if ring and ring.Parent then TweenService:Create(ring, TweenInfo.new(1), {Transparency = 1, Size = Vector3.new(0.3,20,20)}):Play(); task.delay(1.1, function() ring:Destroy(); local idx = table.find(shockwaveTunnelParts, ring); if idx then table.remove(shockwaveTunnelParts, idx) end end) end end) end
			if tick()-tS >= SHOCKWAVE_TRAVEL_DURATION then break end; task.wait() end
		isShockwaveTraveling = false
		if rp and rp.Parent and not shockwaveEmergencyStop then if isVoidBelow(rp.Position) and not isOnCollidableSurface(rp) then local _, np = findNearestCollidablePart(rp.Position); if np then local dt2 = (np-rp.Position); if dt2.Magnitude > 1 then if sV and sV.Parent then sV.VectorVelocity = dt2.Unit*SHOCKWAVE_TRAVEL_SPEED end; local rs = tick(); while true do if not rp or not rp.Parent then break end; if (np-rp.Position).Magnitude < 8 or isOnCollidableSurface(rp) then break end; if tick()-rs > 5 then break end; task.wait(0.05) end end end end end
		if sV and sV.Parent then sV:Destroy() end; if sG and sG.Parent then sG:Destroy() end; if sA and sA.Parent then sA:Destroy() end
		tp.Rate = 0; task.delay(1, function() if tp.Parent then tp:Destroy() end end)
		for _, p in shockwaveTunnelParts do if p and p.Parent then p:Destroy() end end; shockwaveTunnelParts = {}
		if rp and rp.Parent then createShockwave(rp.Position, Color3.fromRGB(160,50,255)); playSound(rp, "rbxassetid://3199270999", 0.6, 1.2) end
		shockwaveEmergencyStop = false; animateCooldown(shockwaveCdBar, SHOCKWAVE_TRAVEL_COOLDOWN); task.wait(SHOCKWAVE_TRAVEL_COOLDOWN); canShockwaveTravel = true end)
end

-- ============================================
-- FUSION LEVELER
-- ============================================
local function activateFusion()
	if not canFusion or isFusionActive then return end; local ch = player.Character; if not ch then return end
	local hum = ch:FindFirstChildOfClass("Humanoid"); local rp = ch:FindFirstChild("HumanoidRootPart"); if not hum or not rp or hum.Health <= 0 then return end
	isFusionActive = true; canFusion = false
	local sWS = hum.WalkSpeed; local sG = workspace.Gravity; local sJP = hum.JumpPower; local sJH = hum.JumpHeight; local sUJP = hum.UseJumpPower
	hum.UseJumpPower = true; hum.JumpPower = FUSION_JUMP_POWER_TARGET; hum.WalkSpeed = sWS*FUSION_SPEED_MULT; workspace.Gravity = sG*FUSION_GRAVITY_MULT
	local jbc = hum.StateChanged:Connect(function(_, ns) if not isFusionActive then return end; if ns == Enum.HumanoidStateType.Jumping then
		local a = Instance.new("Attachment"); a.Parent = rp; local j = Instance.new("LinearVelocity"); j.Attachment0 = a; j.RelativeTo = Enum.ActuatorRelativeTo.World; j.VelocityConstraintMode = Enum.VelocityConstraintMode.Line; j.LineDirection = Vector3.yAxis; j.MaxForce = 50000; j.LineVelocity = 60; j.Parent = rp
		task.delay(0.12, function() if j.Parent then j:Destroy() end; if a.Parent then a:Destroy() end end) end end)
	fusionJumpConn = jbc; playSound(rp, "rbxassetid://3199270999", 0.6, 1.0); createShockwave(rp.Position, Color3.fromRGB(255,200,50))
	local aura = Instance.new("ParticleEmitter"); aura.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,200,50)), ColorSequenceKeypoint.new(1,Color3.fromRGB(255,150,0))}); aura.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.6), NumberSequenceKeypoint.new(0.5,1), NumberSequenceKeypoint.new(1,0)}); aura.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.4), NumberSequenceKeypoint.new(1,1)}); aura.Lifetime = NumberRange.new(0.4,0.8); aura.Rate = 50; aura.Speed = NumberRange.new(2,5); aura.SpreadAngle = Vector2.new(180,180); aura.LightEmission = 0.7; aura.Parent = rp
	local lt = Instance.new("PointLight"); lt.Color = Color3.fromRGB(255,200,50); lt.Brightness = 2; lt.Range = 20; lt.Parent = rp
	task.spawn(function() task.wait(FUSION_DURATION); isFusionActive = false; if jbc then jbc:Disconnect() end; fusionJumpConn = nil
		if hum and hum.Parent then hum.WalkSpeed = sWS; hum.UseJumpPower = sUJP; hum.JumpPower = sJP; hum.JumpHeight = sJH end; workspace.Gravity = sG
		if rp and rp.Parent then createShockwave(rp.Position, Color3.fromRGB(255,200,50)); playSound(rp, "rbxassetid://3199270999", 0.4, 1.5) end
		aura.Rate = 0; task.delay(1, function() if aura.Parent then aura:Destroy() end; if lt.Parent then lt:Destroy() end end); animateCooldown(fusionCdBar, FUSION_COOLDOWN); task.wait(FUSION_COOLDOWN); canFusion = true end)
end

-- ============================================
-- IMMORTALITY SHIELD
-- ============================================
local function cleanupImmortality() isImmortal = false; if immortalityShieldPart and immortalityShieldPart.Parent then immortalityShieldPart:Destroy() end; immortalityShieldPart = nil; if immortalityFloorPart and immortalityFloorPart.Parent then immortalityFloorPart:Destroy() end; immortalityFloorPart = nil; if immortalityFollowConn then immortalityFollowConn:Disconnect(); immortalityFollowConn = nil end; if immortalityScreenGui and immortalityScreenGui.Parent then immortalityScreenGui:Destroy() end; immortalityScreenGui = nil; local ch = player.Character; if ch then for _, c in ch:GetChildren() do if c.Name == "ImmortalityFF" then c:Destroy() end end end end

local function activateImmortality()
	if not canImmortality or isImmortal then return end; local ch = player.Character; if not ch then return end
	local hum = ch:FindFirstChildOfClass("Humanoid"); local rp = ch:FindFirstChild("HumanoidRootPart"); if not hum or not rp or hum.Health <= 0 then return end
	isImmortal = true; canImmortality = false
	local ff = Instance.new("ForceField"); ff.Name = "ImmortalityFF"; ff.Visible = false; ff.Parent = ch
	immortalityShieldPart = Instance.new("Part"); immortalityShieldPart.Name = "ImmortalShield"; immortalityShieldPart.Shape = Enum.PartType.Ball; immortalityShieldPart.Size = Vector3.new(12,12,12); immortalityShieldPart.Material = Enum.Material.ForceField; immortalityShieldPart.Transparency = 0.6; immortalityShieldPart.CanCollide = false; immortalityShieldPart.Anchored = true; immortalityShieldPart.Parent = workspace
	task.spawn(function() local t = 0; while immortalityShieldPart and immortalityShieldPart.Parent do t += 0.02; immortalityShieldPart.Color = getMonochromeColor(t); task.wait(0.03) end end)
	immortalityFloorPart = Instance.new("Part"); immortalityFloorPart.Name = "ImmortalFloor"; immortalityFloorPart.Size = Vector3.new(6,1,6); immortalityFloorPart.Material = Enum.Material.Neon; immortalityFloorPart.Transparency = 0.7; immortalityFloorPart.CanCollide = true; immortalityFloorPart.Anchored = true; immortalityFloorPart.Parent = workspace
	task.spawn(function() local t = 0; while immortalityFloorPart and immortalityFloorPart.Parent do t += 0.02; immortalityFloorPart.Color = getMonochromeColor(t+0.5); task.wait(0.03) end end)
	immortalityFollowConn = RunService.Heartbeat:Connect(function() if not rp or not rp.Parent then return end
		if immortalityShieldPart and immortalityShieldPart.Parent then immortalityShieldPart.Position = rp.Position end
		if immortalityFloorPart and immortalityFloorPart.Parent then immortalityFloorPart.Position = Vector3.new(rp.Position.X, rp.Position.Y-3.5, rp.Position.Z) end
		if hum and hum.Parent and isImmortal and hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end end)
	playSound(rp, "rbxassetid://3199270999", 0.7, 0.8); createShockwave(rp.Position, Color3.fromRGB(200,200,200))
	immortalityScreenGui = Instance.new("ScreenGui"); immortalityScreenGui.Name = "ImmortalityText"; immortalityScreenGui.ResetOnSpawn = false; immortalityScreenGui.Parent = player.PlayerGui
	local il = Instance.new("TextLabel"); il.Size = UDim2.new(0,500,0,40); il.Position = UDim2.new(0.5,0,0.15,0); il.AnchorPoint = Vector2.new(0.5,0.5); il.BackgroundColor3 = Color3.fromRGB(20,20,20); il.BackgroundTransparency = 0.4; il.BorderSizePixel = 0; il.TextSize = 16; il.Font = Enum.Font.GothamBold; il.Parent = immortalityScreenGui; Instance.new("UICorner", il).CornerRadius = UDim.new(0,10)
	task.spawn(function() local t = 0; local rem = IMMORTALITY_DURATION; while il and il.Parent and rem > 0 do t += 0.03; il.TextColor3 = getMonochromeColor(t); il.Text = "You are now effectively immortal for "..math.ceil(rem).." Seconds."; rem -= 0.05; task.wait(0.05) end end)
	task.spawn(function() task.wait(IMMORTALITY_DURATION); cleanupImmortality(); if rp and rp.Parent then createShockwave(rp.Position, Color3.fromRGB(200,200,200)); playSound(rp, "rbxassetid://3199270999", 0.4, 1.5) end; animateCooldown(immortalCdBar, IMMORTALITY_COOLDOWN); task.wait(IMMORTALITY_COOLDOWN); canImmortality = true end)
end

-- ============================================
-- RAINBOW LOCATOR
-- ============================================
local freecamGui, freecamConn, freecamCF, freecamSpeed = nil, nil, CFrame.new(), 1
local destinationMarker, markerBeam, selectedDestination = nil, nil, nil
local freecamInputConns, selectCallback = {}, nil

local function cleanupFreecam() rainbowFreecamActive = false; local ch = player.Character; if ch then local h = ch:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed = savedWalkSpeedForRainbow end end
	if freecamConn then freecamConn:Disconnect(); freecamConn = nil end; if freecamGui and freecamGui.Parent then freecamGui:Destroy() end; freecamGui = nil
	if destinationMarker and destinationMarker.Parent then destinationMarker:Destroy() end; destinationMarker = nil; if markerBeam and markerBeam.Parent then markerBeam:Destroy() end; markerBeam = nil
	for _, conn in freecamInputConns do if conn and typeof(conn) == "RBXScriptConnection" and conn.Connected then conn:Disconnect() end end; freecamInputConns = {}; selectCallback = nil
	camera.CameraType = Enum.CameraType.Custom; local ch2 = player.Character; if ch2 then camera.CameraSubject = ch2:FindFirstChildOfClass("Humanoid") end end

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
	-- MOVE JOY
	local mjf = Instance.new("Frame"); mjf.Size = UDim2.new(0,110,0,110); mjf.Position = UDim2.new(0,20,1,-10); mjf.AnchorPoint = Vector2.new(0,1); mjf.BackgroundColor3 = Color3.fromRGB(80,20,20); mjf.BackgroundTransparency = 0.3; mjf.BorderSizePixel = 0; mjf.Parent = jc; Instance.new("UICorner", mjf).CornerRadius = UDim.new(1,0); Instance.new("UIStroke", mjf).Color = Color3.fromRGB(255,80,80)
	local mjl = Instance.new("TextLabel"); mjl.Size = UDim2.new(1,0,0,14); mjl.Position = UDim2.new(0,0,0,-16); mjl.BackgroundTransparency = 1; mjl.Text = "MOVE"; mjl.TextColor3 = Color3.fromRGB(255,100,100); mjl.TextSize = 10; mjl.Font = Enum.Font.GothamBold; mjl.Parent = mjf
	local mt = Instance.new("Frame"); mt.Size = UDim2.new(0,28,0,28); mt.Position = UDim2.new(0.5,0,0.5,0); mt.AnchorPoint = Vector2.new(0.5,0.5); mt.BackgroundColor3 = Color3.fromRGB(255,60,60); mt.BorderSizePixel = 0; mt.Parent = mjf; Instance.new("UICorner", mt).CornerRadius = UDim.new(1,0)
	-- CAM JOY
	local cjf = Instance.new("Frame"); cjf.Size = UDim2.new(0,110,0,110); cjf.Position = UDim2.new(1,-20,1,-10); cjf.AnchorPoint = Vector2.new(1,1); cjf.BackgroundColor3 = Color3.fromRGB(20,20,80); cjf.BackgroundTransparency = 0.3; cjf.BorderSizePixel = 0; cjf.Parent = jc; Instance.new("UICorner", cjf).CornerRadius = UDim.new(1,0); Instance.new("UIStroke", cjf).Color = Color3.fromRGB(80,80,255)
	local cjl = Instance.new("TextLabel"); cjl.Size = UDim2.new(1,0,0,14); cjl.Position = UDim2.new(0,0,0,-16); cjl.BackgroundTransparency = 1; cjl.Text = "CAMERA"; cjl.TextColor3 = Color3.fromRGB(100,100,255); cjl.TextSize = 10; cjl.Font = Enum.Font.GothamBold; cjl.Parent = cjf
	local ct = Instance.new("Frame"); ct.Size = UDim2.new(0,28,0,28); ct.Position = UDim2.new(0.5,0,0.5,0); ct.AnchorPoint = Vector2.new(0.5,0.5); ct.BackgroundColor3 = Color3.fromRGB(60,60,255); ct.BorderSizePixel = 0; ct.Parent = cjf; Instance.new("UICorner", ct).CornerRadius = UDim.new(1,0)
	-- SPEED SLIDER
	local sf = Instance.new("Frame"); sf.Size = UDim2.new(0,28,0,100); sf.Position = UDim2.new(0.5,0,1,-10); sf.AnchorPoint = Vector2.new(0.5,1); sf.BackgroundColor3 = Color3.fromRGB(20,60,20); sf.BackgroundTransparency = 0.3; sf.BorderSizePixel = 0; sf.Parent = jc; Instance.new("UICorner", sf).CornerRadius = UDim.new(0,8); Instance.new("UIStroke", sf).Color = Color3.fromRGB(80,255,80)
	local sfl = Instance.new("TextLabel"); sfl.Size = UDim2.new(0,60,0,14); sfl.Position = UDim2.new(0.5,0,0,-16); sfl.AnchorPoint = Vector2.new(0.5,0); sfl.BackgroundTransparency = 1; sfl.Text = "SPEED"; sfl.TextColor3 = Color3.fromRGB(100,255,100); sfl.TextSize = 10; sfl.Font = Enum.Font.GothamBold; sfl.Parent = sf
	local sft = Instance.new("Frame"); sft.Size = UDim2.new(1,-4,0,18); sft.Position = UDim2.new(0.5,0,0.5,0); sft.AnchorPoint = Vector2.new(0.5,0.5); sft.BackgroundColor3 = Color3.fromRGB(60,255,60); sft.BorderSizePixel = 0; sft.Parent = sf; Instance.new("UICorner", sft).CornerRadius = UDim.new(0,6)
	local sfv = Instance.new("TextLabel"); sfv.Size = UDim2.new(0,60,0,14); sfv.Position = UDim2.new(0.5,0,1,4); sfv.AnchorPoint = Vector2.new(0.5,0); sfv.BackgroundTransparency = 1; sfv.Text = "1.0x"; sfv.TextColor3 = Color3.fromRGB(100,255,100); sfv.TextSize = 10; sfv.Font = Enum.Font.GothamBold; sfv.Parent = sf
	local moveInput, camInput, localSpeed = Vector2.zero, Vector2.zero, 1
	local moveDrag, camDrag, sliderDrag = false, false, false
	local mouseOverPanel, mouseOverTop = false, false
	jc.MouseEnter:Connect(function() mouseOverPanel = true end); jc.MouseLeave:Connect(function() mouseOverPanel = false end)
	il.MouseEnter:Connect(function() mouseOverTop = true end); il.MouseLeave:Connect(function() mouseOverTop = false end)
	cb.MouseEnter:Connect(function() mouseOverTop = true end); cb.MouseLeave:Connect(function() mouseOverTop = false end)
	mjf.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then moveDrag = true end end)
	cjf.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then camDrag = true end end)
	sf.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then sliderDrag = true end end)
	local ic = UserInputService.InputChanged:Connect(function(i) if not freecamGui or not freecamGui.Parent then return end
		if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
			if moveDrag then local c2 = mjf.AbsolutePosition+mjf.AbsoluteSize/2; local d = (Vector2.new(i.Position.X,i.Position.Y)-c2)/(mjf.AbsoluteSize.X/2); d = Vector2.new(math.clamp(d.X,-1,1), math.clamp(d.Y,-1,1)); moveInput = d; mt.Position = UDim2.new(0.5+d.X*0.35,0,0.5+d.Y*0.35,0) end
			if camDrag then local c2 = cjf.AbsolutePosition+cjf.AbsoluteSize/2; local d = (Vector2.new(i.Position.X,i.Position.Y)-c2)/(cjf.AbsoluteSize.X/2); d = Vector2.new(math.clamp(d.X,-1,1), math.clamp(d.Y,-1,1)); camInput = d; ct.Position = UDim2.new(0.5+d.X*0.35,0,0.5+d.Y*0.35,0) end
			if sliderDrag then local top = sf.AbsolutePosition.Y; local h = sf.AbsoluteSize.Y; local rY = math.clamp((i.Position.Y-top)/h, 0, 1); localSpeed = 0.2+(1-rY)*3.8; sft.Position = UDim2.new(0.5,0,rY,0); sfv.Text = string.format("%.1fx", localSpeed) end
		end end); table.insert(freecamInputConns, ic)
	local ie = UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		if moveDrag then moveDrag = false; moveInput = Vector2.zero; mt.Position = UDim2.new(0.5,0,0.5,0) end
		if camDrag then camDrag = false; camInput = Vector2.zero; ct.Position = UDim2.new(0.5,0,0.5,0) end; sliderDrag = false end end); table.insert(freecamInputConns, ie)
	local ks = {}; table.insert(freecamInputConns, UserInputService.InputBegan:Connect(function(i, gp) if gp then return end; ks[i.KeyCode] = true end)); table.insert(freecamInputConns, UserInputService.InputEnded:Connect(function(i) ks[i.KeyCode] = false end))
	local lastHit, lastPart = nil, nil
	sb.MouseButton1Click:Connect(function() if lastHit and lastPart and lastPart.CanCollide then if selectCallback then selectCallback(lastHit, lastPart) end else sl.Text = "⚠ Aim at a collidable surface first!"; sl.TextColor3 = Color3.fromRGB(255,80,80); task.delay(1, function() if sl and sl.Parent then sl.Text = "Aim at a collidable surface"; sl.TextColor3 = Color3.fromRGB(180,180,180) end end) end end)
	return function() return moveInput, camInput, localSpeed, ks, mouseOverPanel or mouseOverTop end,
		function(h, p) lastHit = h; lastPart = p; if h and p and p.CanCollide then sl.Text = "✓ Valid: "..p.Name; sl.TextColor3 = Color3.fromRGB(80,255,80); sb.BackgroundColor3 = Color3.fromRGB(40,200,40) else sl.Text = "Aim at a collidable surface"; sl.TextColor3 = Color3.fromRGB(180,180,180); sb.BackgroundColor3 = Color3.fromRGB(60,60,60) end end
end

local function activateRainbowLocator()
	if not canRainbowLocator or isRainbowLocatorActive then return end; local ch = player.Character; if not ch then return end
	local hum = ch:FindFirstChildOfClass("Humanoid"); local rp = ch:FindFirstChild("HumanoidRootPart"); if not hum or not rp or hum.Health <= 0 then return end
	isRainbowLocatorActive = true; canRainbowLocator = false; rainbowFreecamActive = true; selectedDestination = nil
	savedWalkSpeedForRainbow = hum.WalkSpeed; hum.WalkSpeed = 0.01
	destinationMarker = Instance.new("Part"); destinationMarker.Name = "DestMarker"; destinationMarker.Anchored = true; destinationMarker.CanCollide = false; destinationMarker.Size = Vector3.new(3,3,3); destinationMarker.Shape = Enum.PartType.Ball; destinationMarker.Material = Enum.Material.Neon; destinationMarker.Transparency = 0.8; destinationMarker.Parent = workspace
	task.spawn(function() local t = 0; while destinationMarker and destinationMarker.Parent do t += 0.03; destinationMarker.Color = getRainbowColor(t); task.wait(0.03) end end)
	markerBeam = Instance.new("Part"); markerBeam.Name = "MarkerBeam"; markerBeam.Anchored = true; markerBeam.CanCollide = false; markerBeam.Size = Vector3.new(0.3,50,0.3); markerBeam.Material = Enum.Material.Neon; markerBeam.Transparency = 0.5; markerBeam.Parent = workspace
	task.spawn(function() local t = 0; while markerBeam and markerBeam.Parent do t += 0.03; markerBeam.Color = getRainbowColor(t+0.5); if destinationMarker and destinationMarker.Parent then markerBeam.CFrame = CFrame.new(destinationMarker.Position+Vector3.new(0,25,0)) end; task.wait(0.03) end end)
	camera.CameraType = Enum.CameraType.Scriptable; freecamCF = camera.CFrame
	local getInputs, updateHitInfo = createFreecamUI()
	selectCallback = function(hitPos)
		selectedDestination = hitPos + Vector3.new(0,3,0); cleanupFreecam()
		task.spawn(function()
			local ch2 = player.Character; if not ch2 then isRainbowLocatorActive = false; task.spawn(function() animateCooldown(rainbowCdBar, 2); task.wait(2); canRainbowLocator = true end); return end
			local hum2 = ch2:FindFirstChildOfClass("Humanoid"); local rp2 = ch2:FindFirstChild("HumanoidRootPart"); if not hum2 or not rp2 or hum2.Health <= 0 or not selectedDestination then isRainbowLocatorActive = false; task.spawn(function() animateCooldown(rainbowCdBar, 2); task.wait(2); canRainbowLocator = true end); return end
			local dest = selectedDestination; createRainbowPillar(rp2.Position); createRainbowShockwave(rp2.Position); playSound(rp2, "rbxassetid://3199270999", 0.8, 0.6)
			local ta = Instance.new("ParticleEmitter"); ta.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.8), NumberSequenceKeypoint.new(1,0)}); ta.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.3), NumberSequenceKeypoint.new(1,1)}); ta.Lifetime = NumberRange.new(0.3,0.6); ta.Rate = 80; ta.Speed = NumberRange.new(3,8); ta.SpreadAngle = Vector2.new(180,180); ta.LightEmission = 0.8; ta.Parent = rp2
			task.spawn(function() local t = 0; while ta and ta.Parent do t += 0.02; ta.Color = ColorSequence.new(getRainbowColor(t)); task.wait(0.03) end end)
			local tY = dest.Y; if math.abs(tY-rp2.Position.Y) > 3 then
				local ra = Instance.new("Attachment"); ra.Parent = rp2; local rv = Instance.new("LinearVelocity"); rv.Attachment0 = ra; rv.RelativeTo = Enum.ActuatorRelativeTo.World; rv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector; rv.MaxForce = 60000; rv.VectorVelocity = Vector3.new(0, tY > rp2.Position.Y and 80 or -80, 0); rv.Parent = rp2
				local hh = Instance.new("LinearVelocity"); hh.Attachment0 = ra; hh.RelativeTo = Enum.ActuatorRelativeTo.World; hh.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane; hh.PrimaryTangentAxis = Vector3.new(1,0,0); hh.SecondaryTangentAxis = Vector3.new(0,0,1); hh.MaxForce = 40000; hh.PlaneVelocity = Vector2.zero; hh.Parent = rp2
				while true do if not rp2 or not rp2.Parent or hum2.Health <= 0 then break end; if math.abs(rp2.Position.Y-tY) < 3 then break end
					local av = checkHeadObstacle(rp2); if av then hh.PlaneVelocity = Vector2.new(av.X*40, av.Z*40) else hh.PlaneVelocity = Vector2.zero end; task.wait(0.05) end
				if rv.Parent then rv:Destroy() end; if hh.Parent then hh:Destroy() end; if ra.Parent then ra:Destroy() end end
			local ep = Vector3.new(dest.X, rp2.Position.Y, dest.Z); local hd = (ep-rp2.Position).Magnitude
			if hd > 3 then local hDir = (ep-rp2.Position).Unit; rp2.CFrame = CFrame.new(rp2.Position, rp2.Position+hDir)
				local ha = Instance.new("Attachment"); ha.Parent = rp2; local hv = Instance.new("LinearVelocity"); hv.Attachment0 = ha; hv.RelativeTo = Enum.ActuatorRelativeTo.World; hv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector; hv.MaxForce = 60000; hv.VectorVelocity = Vector3.zero; hv.Parent = rp2
				local hag = Instance.new("LinearVelocity"); hag.Attachment0 = ha; hag.RelativeTo = Enum.ActuatorRelativeTo.World; hag.VelocityConstraintMode = Enum.VelocityConstraintMode.Line; hag.LineDirection = Vector3.yAxis; hag.MaxForce = 8000; hag.LineVelocity = 0; hag.Parent = rp2
				local tt = math.clamp(hd/120, 0.5, 8); local el = 0
				while el < tt do if not rp2 or not rp2.Parent or hum2.Health <= 0 then break end; local al = el/tt; local sm = math.max(math.sin(al*math.pi), 0.1); local bv = hDir*(hd/tt)*sm*1.6
					local av = checkHeadObstacle(rp2); if av then bv = bv+av*50 end; hv.VectorVelocity = bv
					if Vector3.new(ep.X-rp2.Position.X, 0, ep.Z-rp2.Position.Z).Magnitude < 5 then break end; el += task.wait() end
				if hv.Parent then hv:Destroy() end; if hag.Parent then hag:Destroy() end; if ha.Parent then ha:Destroy() end end
			if rp2 and rp2.Parent then createRainbowPillar(rp2.Position); createRainbowShockwave(rp2.Position); playSound(rp2, "rbxassetid://3199270999", 0.6, 1.2) end
			ta.Rate = 0; task.delay(1, function() if ta.Parent then ta:Destroy() end end)
			isRainbowLocatorActive = false; animateCooldown(rainbowCdBar, RAINBOW_LOCATOR_COOLDOWN); task.wait(RAINBOW_LOCATOR_COOLDOWN); canRainbowLocator = true end)
	end
	freecamConn = RunService.RenderStepped:Connect(function(dt)
		if not rainbowFreecamActive then return end
		local mi, ci, sp, ks, oU = getInputs()
		local kb = Vector3.zero
		if ks[Enum.KeyCode.W] then kb += Vector3.new(0,0,-1) end; if ks[Enum.KeyCode.S] then kb += Vector3.new(0,0,1) end
		if ks[Enum.KeyCode.A] then kb += Vector3.new(-1,0,0) end; if ks[Enum.KeyCode.D] then kb += Vector3.new(1,0,0) end
		if ks[Enum.KeyCode.Space] then kb += Vector3.new(0,1,0) end; if ks[Enum.KeyCode.LeftShift] then kb += Vector3.new(0,-1,0) end
		local mv = Vector3.new(mi.X, 0, mi.Y)*sp + kb
		local rx, ry, _ = freecamCF:ToEulerAnglesYXZ(); ry -= ci.X*2*dt; rx = math.clamp(rx-ci.Y*2*dt, -math.rad(85), math.rad(85))
		freecamCF = CFrame.new(freecamCF.Position)*CFrame.fromEulerAnglesYXZ(rx, ry, 0); freecamCF = freecamCF + freecamCF:VectorToWorldSpace(mv*60*sp*dt); camera.CFrame = freecamCF
		if not oU then local mp = UserInputService:GetMouseLocation(); local r = camera:ViewportPointToRay(mp.X, mp.Y)
			local rp2 = RaycastParams.new(); rp2.FilterType = Enum.RaycastFilterType.Exclude; local fl = {}; if player.Character then table.insert(fl, player.Character) end; if destinationMarker then table.insert(fl, destinationMarker) end; if markerBeam then table.insert(fl, markerBeam) end; rp2.FilterDescendantsInstances = fl
			local res = workspace:Raycast(r.Origin, r.Direction*5000, rp2)
			if res and res.Instance then if destinationMarker and destinationMarker.Parent then destinationMarker.Position = res.Position+Vector3.new(0,1.5,0); destinationMarker.Transparency = 0.3; destinationMarker.Size = Vector3.new(3,3,3) end; updateHitInfo(res.Position, res.Instance)
			else if destinationMarker and destinationMarker.Parent then destinationMarker.Transparency = 0.8; destinationMarker.Size = Vector3.new(1,1,1) end; updateHitInfo(nil, nil) end end
	end)
end

-- ============================================
-- EMERGENCY STOP
-- ============================================
local function emergencyStop()
	if isShockwaveTraveling then cleanupShockwaveTravel() end
	local ch = player.Character; if ch then local rp = ch:FindFirstChild("HumanoidRootPart"); if rp then for _, c in rp:GetChildren() do if c:IsA("LinearVelocity") or (c:IsA("Attachment") and c.Name ~= "RootAttachment") then c:Destroy() end end end end
	if isLunging then isLunging = false end; if isDashing then isDashing = false end
	if rainbowFreecamActive then cleanupFreecam(); isRainbowLocatorActive = false; task.spawn(function() animateCooldown(rainbowCdBar, 2); task.wait(2); canRainbowLocator = true end) end
	emergencyBtnObj.BackgroundColor3 = Color3.fromRGB(255,100,100); task.delay(0.3, function() emergencyBtnObj.BackgroundColor3 = Color3.fromRGB(200,30,30) end)
	if ch and ch:FindFirstChild("HumanoidRootPart") then playSound(ch.HumanoidRootPart, "rbxassetid://3199270999", 0.5, 2) end
end
emergencyBtnObj.MouseButton1Click:Connect(emergencyStop)

-- ============================================
-- BUTTON CLICKS
-- ============================================
platformBtn.MouseButton1Click:Connect(activatePlatform)
lungeBtn.MouseButton1Click:Connect(activateLunge)
megaJumpBtn.MouseButton1Click:Connect(activateMegaJump)
gigaJumpBtn.MouseButton1Click:Connect(activateGigaJump)
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
	elseif input.KeyCode == Enum.KeyCode.V then activateGigaJump()
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
	local humanoid = character:WaitForChild("Humanoid"); local dashedThisJump = false
	isDashing = false; canDash = true; isLunging = false; isMegaJumping = false; isGigaJumping = false
	if megaJumpGravityActive then workspace.Gravity = originalGravity; megaJumpGravityActive = false end
	if gigaJumpGravityActive then workspace.Gravity = originalGravity; gigaJumpGravityActive = false end
	if isShockwaveTraveling then cleanupShockwaveTravel() end
	if rainbowFreecamActive then cleanupFreecam() end
	if isFusionActive then workspace.Gravity = originalGravity; isFusionActive = false end
	if fusionJumpConn then fusionJumpConn:Disconnect(); fusionJumpConn = nil end
	if isImmortal then cleanupImmortality() end
	if platformFollowConn then platformFollowConn:Disconnect(); platformFollowConn = nil end
	if currentPlatform and currentPlatform.Parent then currentPlatform:Destroy() end; currentPlatform = nil; platformActive = false

	humanoid.StateChanged:Connect(function(_, ns)
		if ns == Enum.HumanoidStateType.Jumping then
			if gigaJumpArmed and canGigaJump then performGigaJump() end
			if megaJumpArmed and canMegaJump then performMegaJump() end
			if not dashedThisJump then task.delay(0.05, function() if dashEnabled and not dashedThisJump and humanoid.Health > 0 then dashedThisJump = true; performDash() end end) end
		elseif ns == Enum.HumanoidStateType.Landed or ns == Enum.HumanoidStateType.Running then dashedThisJump = false end
	end)
end

if player.Character then onCharacterAdded(player.Character) end
player.CharacterAdded:Connect(onCharacterAdded)

print("[Abilities V4.2] Q=Platform E=Lunge R=MegaJump V=GigaJump T=Shockwave F=Fusion G=Rainbow H=Immortality C=MiniDash X=Stop")
