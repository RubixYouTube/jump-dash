-- AdvancedAbilitiesSystemV4 (LocalScript)
-- Place in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ============================================
-- CONFIGURATION
-- ============================================
local DASH_DISTANCE = 40
local DASH_DURATION = 0.35
local DASH_COOLDOWN = 0.8

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

-- ============================================
-- STATE
-- ============================================
local dashEnabled = true
local canDash = true
local isDashing = false

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
local shockwaveTravelConn = nil
local shockwaveTunnelParts = {}
local shockwaveEmergencyStop = false

local canFusion = true
local isFusionActive = false
local fusionJumpConn = nil

local canRainbowLocator = true
local isRainbowLocatorActive = false
local rainbowFreecamActive = false
local savedWalkSpeedForRainbow = 16

local originalGravity = workspace.Gravity

-- ============================================
-- UTILITY
-- ============================================
local function isVoidBelow(position: Vector3, maxDist: number?): boolean
	local dist = maxDist or 500
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local filterList = {}
	if player.Character then table.insert(filterList, player.Character) end
	if currentPlatform then table.insert(filterList, currentPlatform) end
	for _, p in shockwaveTunnelParts do
		if p and p.Parent then table.insert(filterList, p) end
	end
	rayParams.FilterDescendantsInstances = filterList
	return workspace:Raycast(position, Vector3.new(0, -dist, 0), rayParams) == nil
end

local function isOnCollidableSurface(rootPart: BasePart): boolean
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local filterList = {}
	if player.Character then table.insert(filterList, player.Character) end
	if currentPlatform then table.insert(filterList, currentPlatform) end
	for _, p in shockwaveTunnelParts do
		if p and p.Parent then table.insert(filterList, p) end
	end
	rayParams.FilterDescendantsInstances = filterList
	local result = workspace:Raycast(rootPart.Position, Vector3.new(0, -5, 0), rayParams)
	return result ~= nil and result.Instance ~= nil and result.Instance.CanCollide
end

local function findNearestCollidablePart(position: Vector3): (BasePart?, Vector3?)
	local nearest: BasePart? = nil
	local nearestDist = math.huge
	local nearestPos = position
	local filterList = {}
	if player.Character then table.insert(filterList, player.Character) end
	if currentPlatform then table.insert(filterList, currentPlatform) end
	for _, p in shockwaveTunnelParts do
		if p and p.Parent then table.insert(filterList, p) end
	end
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
		Vector3.new(1,0,1).Unit, Vector3.new(-1,0,1).Unit,
		Vector3.new(1,0,-1).Unit, Vector3.new(-1,0,-1).Unit,
	}
	for _, dir in directions do
		local result = workspace:Raycast(position, dir * 2000, rayParams)
		if result and result.Instance and result.Instance.CanCollide then
			local dist = (result.Position - position).Magnitude
			if dist < nearestDist then
				nearestDist = dist
				nearest = result.Instance
				nearestPos = result.Position + Vector3.new(0, 3, 0)
			end
		end
	end
	return nearest, nearestPos
end

-- check for obstacles above head and return avoidance direction
local function checkHeadObstacle(rootPart: BasePart): Vector3?
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local filterList = {player.Character}
	if currentPlatform then table.insert(filterList, currentPlatform) end
	for _, p in shockwaveTunnelParts do
		if p and p.Parent then table.insert(filterList, p) end
	end
	rayParams.FilterDescendantsInstances = filterList

	-- check directly above
	local upResult = workspace:Raycast(rootPart.Position, Vector3.new(0, 8, 0), rayParams)
	if upResult and upResult.Instance and upResult.Instance.CanCollide then
		-- obstacle above! find which direction to move
		local hitNormal = upResult.Normal
		local avoidDir = Vector3.new(hitNormal.X, 0, hitNormal.Z)
		if avoidDir.Magnitude < 0.1 then
			-- normal is straight down, try sides
			local bestDir = nil
			local bestDist = 0
			local testDirs = {
				Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0),
				Vector3.new(0, 0, 1), Vector3.new(0, 0, -1),
				Vector3.new(1, 0, 1).Unit, Vector3.new(-1, 0, 1).Unit,
				Vector3.new(1, 0, -1).Unit, Vector3.new(-1, 0, -1).Unit,
			}
			for _, dir in testDirs do
				local sideCheck = workspace:Raycast(rootPart.Position, dir * 20, rayParams)
				local dist = 20
				if sideCheck then dist = sideCheck.Distance end
				if dist > bestDist then
					bestDist = dist
					bestDir = dir
				end
			end
			return bestDir
		end
		return avoidDir.Unit
	end

	-- also check slightly forward-up for diagonal obstacles
	local lookDir = rootPart.CFrame.LookVector
	local diagResult = workspace:Raycast(rootPart.Position + Vector3.new(0, 3, 0), Vector3.new(lookDir.X, 1, lookDir.Z).Unit * 6, rayParams)
	if diagResult and diagResult.Instance and diagResult.Instance.CanCollide then
		local hitNormal = diagResult.Normal
		local avoidDir = Vector3.new(hitNormal.X, 0, hitNormal.Z)
		if avoidDir.Magnitude > 0.1 then
			return avoidDir.Unit
		end
	end

	return nil
end

local function playSound(parent: Instance, id: string, volume: number?, speed: number?)
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = volume or 0.5
	sound.PlaybackSpeed = speed or 1
	sound.Parent = parent
	sound:Play()
	Debris:AddItem(sound, 3)
end

local function getRainbowColor(t: number): Color3
	return Color3.fromHSV((t % 1), 1, 1)
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
-- DASH TOGGLE (bottom right)
-- ============================================
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

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 170, 255)
	stroke.Thickness = 2
	stroke.Transparency = 0.3
	stroke.Parent = buttonFrame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.6, 0, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = "Jump Dash"
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 16
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = buttonFrame

	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Size = UDim2.new(0, 50, 0, 26)
	toggleBtn.Position = UDim2.new(1, -60, 0.5, 0)
	toggleBtn.AnchorPoint = Vector2.new(0, 0.5)
	toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
	toggleBtn.BorderSizePixel = 0
	toggleBtn.Text = "ON"
	toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggleBtn.TextSize = 14
	toggleBtn.Font = Enum.Font.GothamBold
	toggleBtn.Parent = buttonFrame
	Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)

	local cdBar = Instance.new("Frame")
	cdBar.Name = "CooldownBar"
	cdBar.Size = UDim2.new(1, 0, 0, 3)
	cdBar.Position = UDim2.new(0, 0, 1, -3)
	cdBar.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
	cdBar.BorderSizePixel = 0
	cdBar.Parent = buttonFrame
	Instance.new("UICorner", cdBar).CornerRadius = UDim.new(0, 2)

	toggleBtn.MouseButton1Click:Connect(function()
		dashEnabled = not dashEnabled
		if dashEnabled then
			toggleBtn.Text = "ON"
			toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
			stroke.Color = Color3.fromRGB(0, 170, 255)
			label.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			toggleBtn.Text = "OFF"
			toggleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
			stroke.Color = Color3.fromRGB(100, 100, 100)
			label.TextColor3 = Color3.fromRGB(150, 150, 150)
		end
	end)

	return cdBar
end

local dashCooldownBar = createDashToggle()

-- ============================================
-- ABILITIES MENU
-- ============================================
local menuOpen = true

local menuFrame = Instance.new("Frame")
menuFrame.Name = "AbilitiesMenu"
menuFrame.Size = UDim2.new(0, 240, 0, 420)
menuFrame.Position = UDim2.new(0, 20, 0.5, -210)
menuFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
menuFrame.BackgroundTransparency = 0.1
menuFrame.BorderSizePixel = 0
menuFrame.ClipsDescendants = true
menuFrame.Parent = screenGui
Instance.new("UICorner", menuFrame).CornerRadius = UDim.new(0, 14)

local menuStroke = Instance.new("UIStroke")
menuStroke.Color = Color3.fromRGB(80, 80, 120)
menuStroke.Thickness = 2
menuStroke.Parent = menuFrame

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
titleBar.BackgroundTransparency = 0.1
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 3
titleBar.Parent = menuFrame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 14)

local titleBarFix = Instance.new("Frame")
titleBarFix.Size = UDim2.new(1, 0, 0, 14)
titleBarFix.Position = UDim2.new(0, 0, 1, -14)
titleBarFix.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
titleBarFix.BackgroundTransparency = 0.1
titleBarFix.BorderSizePixel = 0
titleBarFix.ZIndex = 3
titleBarFix.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -50, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "⚡ Abilities"
titleLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
titleLabel.TextSize = 16
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 3
titleLabel.Parent = titleBar

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 30, 0, 24)
minimizeBtn.Position = UDim2.new(1, -38, 0.5, 0)
minimizeBtn.AnchorPoint = Vector2.new(0, 0.5)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Text = "—"
minimizeBtn.TextColor3 = Color3.fromRGB(200, 200, 255)
minimizeBtn.TextSize = 16
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.ZIndex = 3
minimizeBtn.Parent = titleBar
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 6)

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "ScrollContent"
scrollFrame.Size = UDim2.new(1, -8, 1, -80)
scrollFrame.Position = UDim2.new(0, 4, 0, 40)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 4
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 160)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent = menuFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 6)
listLayout.Parent = scrollFrame

local listPadding = Instance.new("UIPadding")
listPadding.PaddingLeft = UDim.new(0, 4)
listPadding.PaddingRight = UDim.new(0, 4)
listPadding.PaddingTop = UDim.new(0, 2)
listPadding.PaddingBottom = UDim.new(0, 4)
listPadding.Parent = scrollFrame

local emergencyBtn = Instance.new("TextButton")
emergencyBtn.Name = "EmergencyStop"
emergencyBtn.Size = UDim2.new(1, -16, 0, 30)
emergencyBtn.Position = UDim2.new(0.5, 0, 1, -38)
emergencyBtn.AnchorPoint = Vector2.new(0.5, 0)
emergencyBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
emergencyBtn.BorderSizePixel = 0
emergencyBtn.Text = "⚠ EMERGENCY STOP"
emergencyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
emergencyBtn.TextSize = 13
emergencyBtn.Font = Enum.Font.GothamBold
emergencyBtn.ZIndex = 3
emergencyBtn.Parent = menuFrame
Instance.new("UICorner", emergencyBtn).CornerRadius = UDim.new(0, 8)
local emergencyStroke = Instance.new("UIStroke")
emergencyStroke.Color = Color3.fromRGB(255, 80, 80)
emergencyStroke.Thickness = 1.5
emergencyStroke.Parent = emergencyBtn

-- Dragging
local dragging = false
local dragStart = Vector2.zero
local frameStartPos = UDim2.new()

titleBar.InputBegan:Connect(function(input)
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
		menuFrame.Size = UDim2.new(0, 240, 0, 420)
		scrollFrame.Visible = true
		emergencyBtn.Visible = true
		minimizeBtn.Text = "—"
	else
		menuFrame.Size = UDim2.new(0, 240, 0, 36)
		scrollFrame.Visible = false
		emergencyBtn.Visible = false
		minimizeBtn.Text = "+"
	end
end)

-- ============================================
-- ABILITY BUTTON CREATOR
-- ============================================
local function createAbilityButton(name, color, description, keybind, layoutOrder, note, rainbowName, opText)
	local totalHeight = 60
	if note then totalHeight = 78 end
	if opText then totalHeight = totalHeight + 16 end

	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(1, 0, 0, totalHeight)
	btn.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
	btn.BorderSizePixel = 0
	btn.Text = ""
	btn.LayoutOrder = layoutOrder
	btn.AutoButtonColor = true
	btn.Parent = scrollFrame
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = color
	btnStroke.Thickness = 1.5
	btnStroke.Transparency = 0.4
	btnStroke.Parent = btn

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -10, 0, 22)
	nameLabel.Position = UDim2.new(0, 8, 0, 4)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = name .. "  [" .. keybind .. "]"
	nameLabel.TextColor3 = color
	nameLabel.TextSize = 14
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = btn

	if rainbowName then
		task.spawn(function()
			local t = 0
			while btn and btn.Parent do
				t += 0.02
				nameLabel.TextColor3 = getRainbowColor(t)
				btnStroke.Color = getRainbowColor(t + 0.3)
				task.wait(0.03)
			end
		end)
	end

	local yOffset = 24

	if opText then
		local opLabel = Instance.new("TextLabel")
		opLabel.Name = "OPLabel"
		opLabel.Size = UDim2.new(0, 40, 0, 16)
		opLabel.Position = UDim2.new(0, 8, 0, yOffset)
		opLabel.BackgroundTransparency = 1
		opLabel.Text = "OP!"
		opLabel.TextSize = 13
		opLabel.Font = Enum.Font.GothamBold
		opLabel.TextXAlignment = Enum.TextXAlignment.Left
		opLabel.Parent = btn
		task.spawn(function()
			local t = 0
			while opLabel and opLabel.Parent do
				t += 0.03; opLabel.TextColor3 = getRainbowColor(t); task.wait(0.03)
			end
		end)
		yOffset += 16
	end

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, -10, 0, 16)
	descLabel.Position = UDim2.new(0, 8, 0, yOffset)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = description
	descLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
	descLabel.TextSize = 11
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextWrapped = true
	descLabel.Parent = btn
	yOffset += 16

	if note then
		local noteLabel = Instance.new("TextLabel")
		noteLabel.Size = UDim2.new(1, -10, 0, 14)
		noteLabel.Position = UDim2.new(0, 8, 0, yOffset)
		noteLabel.BackgroundTransparency = 1
		noteLabel.Text = "📌 " .. note
		noteLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
		noteLabel.TextSize = 10
		noteLabel.Font = Enum.Font.GothamMedium
		noteLabel.TextXAlignment = Enum.TextXAlignment.Left
		noteLabel.TextWrapped = true
		noteLabel.Parent = btn
	end

	local cdBarBg = Instance.new("Frame")
	cdBarBg.Size = UDim2.new(1, -16, 0, 4)
	cdBarBg.Position = UDim2.new(0, 8, 1, -10)
	cdBarBg.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	cdBarBg.BorderSizePixel = 0
	cdBarBg.Parent = btn
	Instance.new("UICorner", cdBarBg).CornerRadius = UDim.new(0, 2)

	local cdBarFill = Instance.new("Frame")
	cdBarFill.Size = UDim2.new(1, 0, 1, 0)
	cdBarFill.BackgroundColor3 = color
	cdBarFill.BorderSizePixel = 0
	cdBarFill.Parent = cdBarBg
	Instance.new("UICorner", cdBarFill).CornerRadius = UDim.new(0, 2)

	if rainbowName then
		task.spawn(function()
			local t = 0
			while cdBarFill and cdBarFill.Parent do
				t += 0.02; cdBarFill.BackgroundColor3 = getRainbowColor(t); task.wait(0.03)
			end
		end)
	end

	return btn, cdBarFill, btnStroke
end

local platformBtn, platformCdBar = createAbilityButton("Platform", Color3.fromRGB(0, 130, 255), "Spawns a platform that follows you", "Q", 1)
local lungeBtn, lungeCdBar = createAbilityButton("Lunge", Color3.fromRGB(255, 80, 50), "Dash 100 studs at 1.7x speed", "E", 2)
local megaJumpBtn, megaJumpCdBar, megaJumpStroke = createAbilityButton("Mega Jump", Color3.fromRGB(50, 255, 100), "6x jump power + reduced gravity", "R", 3, "Perfect to beat a average tower!")
local shockwaveBtn, shockwaveCdBar = createAbilityButton("Shockwave Travel", Color3.fromRGB(160, 50, 255), "c00lkidd wannabe(s) will LOVE THIS!", "T", 4)
local fusionBtn, fusionCdBar = createAbilityButton("Fusion Leveler", Color3.fromRGB(255, 200, 50), "Speed x1.5, Jump=110, Gravity 50% for 15s", "F", 5)
local rainbowBtn, rainbowCdBar = createAbilityButton("Rainbow Locator", Color3.fromRGB(255, 0, 0), "Select a destination and travel there!", "G", 6, "Go to destinations like never before!", true, true)

-- ============================================
-- COOLDOWN HELPER
-- ============================================
local function animateCooldown(bar, duration)
	bar.Size = UDim2.new(0, 0, 1, 0)
	TweenService:Create(bar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		Size = UDim2.new(1, 0, 1, 0)
	}):Play()
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
	trail.Attachment0 = a0; trail.Attachment1 = a1
	trail.Lifetime = 0.2; trail.MinLength = 0.1; trail.FaceCamera = true
	trail.Color = ColorSequence.new(c)
	trail.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1)})
	trail.WidthScale = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})
	trail.Parent = rootPart
	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(c)
	particles.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0)})
	particles.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1)})
	particles.Lifetime = NumberRange.new(0.15, 0.3); particles.Rate = 100
	particles.Speed = NumberRange.new(5, 15); particles.SpreadAngle = Vector2.new(30, 30)
	particles.Parent = rootPart
	return {
		cleanup = function(d)
			local dt2 = d or DASH_DURATION
			task.delay(dt2, function() particles.Rate = 0 end)
			task.delay(dt2 + 0.5, function() trail:Destroy(); particles:Destroy(); a0:Destroy(); a1:Destroy() end)
		end
	}
end

-- ============================================
-- JUMP DASH
-- ============================================
local function performDash()
	if not dashEnabled or not canDash or isDashing then return end
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then return end
	if humanoid.Health <= 0 or humanoid.FloorMaterial ~= Enum.Material.Air then return end

	isDashing = true; canDash = false
	local moveDir = humanoid.MoveDirection
	local dashDir
	if moveDir.Magnitude > 0.1 then dashDir = moveDir.Unit else dashDir = rootPart.CFrame.LookVector end
	dashDir = Vector3.new(dashDir.X, 0, dashDir.Z)
	if dashDir.Magnitude < 0.1 then dashDir = Vector3.new(rootPart.CFrame.LookVector.X, 0, rootPart.CFrame.LookVector.Z) end
	dashDir = dashDir.Unit

	local vfx = createDashVFX(character)
	playSound(rootPart, "rbxassetid://7471006063", 0.5, 1.3)
	rootPart.CFrame = CFrame.new(rootPart.Position, rootPart.Position + dashDir)

	local att = Instance.new("Attachment"); att.Parent = rootPart
	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = att; lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector; lv.MaxForce = 50000
	lv.VectorVelocity = dashDir * (DASH_DISTANCE / DASH_DURATION); lv.Parent = rootPart
	local ag = Instance.new("LinearVelocity")
	ag.Attachment0 = att; ag.RelativeTo = Enum.ActuatorRelativeTo.World
	ag.VelocityConstraintMode = Enum.VelocityConstraintMode.Line; ag.LineDirection = Vector3.yAxis
	ag.MaxForce = 5000; ag.LineVelocity = 0; ag.Parent = rootPart

	task.delay(DASH_DURATION, function()
		while true do
			if not rootPart or not rootPart.Parent then break end
			if humanoid.Health <= 0 then break end
			if not isVoidBelow(rootPart.Position) or isOnCollidableSurface(rootPart) then break end

			-- obstacle avoidance during void continuation
			local avoidDir = checkHeadObstacle(rootPart)
			if avoidDir and lv.Parent then
				local currentVel = lv.VectorVelocity
				local speed = currentVel.Magnitude
				local newDir = (dashDir + avoidDir * 0.5).Unit
				lv.VectorVelocity = newDir * speed
			end

			task.wait(0.05)
		end
		if lv.Parent then lv:Destroy() end
		if ag.Parent then ag:Destroy() end
		if att.Parent then att:Destroy() end
		isDashing = false
		if vfx then vfx.cleanup(0) end
		if rootPart and rootPart.Parent then
			local sa = Instance.new("Attachment"); sa.Parent = rootPart
			local sv = Instance.new("LinearVelocity")
			sv.Attachment0 = sa; sv.RelativeTo = Enum.ActuatorRelativeTo.World
			sv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector; sv.MaxForce = 20000
			sv.VectorVelocity = dashDir * 15; sv.Parent = rootPart
			task.spawn(function()
				for i = 1, 8 do task.wait(0.03); if sv.Parent then sv.VectorVelocity *= 0.6 end end
				if sv.Parent then sv:Destroy() end; if sa.Parent then sa:Destroy() end
			end)
		end
	end)

	dashCooldownBar.Size = UDim2.new(0, 0, 0, 3)
	TweenService:Create(dashCooldownBar, TweenInfo.new(DASH_COOLDOWN, Enum.EasingStyle.Linear), {
		Size = UDim2.new(1, 0, 0, 3)
	}):Play()
	task.spawn(function() task.wait(DASH_COOLDOWN); canDash = true end)
end

-- ============================================
-- PLATFORM
-- ============================================
local function activatePlatform()
	if not canPlatform or platformActive then return end
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart or humanoid.Health <= 0 then return end

	platformActive = true; canPlatform = false
	local platform = Instance.new("Part")
	platform.Name = "AbilityPlatform"; platform.Size = PLATFORM_SIZE
	platform.Material = Enum.Material.Neon; platform.Color = Color3.fromRGB(0, 130, 255)
	platform.Transparency = 0.5; platform.Anchored = true; platform.CanCollide = true
	platform.Position = rootPart.Position - Vector3.new(0, 4, 0); platform.Parent = workspace

	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Color = ColorSequence.new(Color3.fromRGB(255, 50, 50))
	sparkles.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(0.5, 0.6), NumberSequenceKeypoint.new(1, 0)})
	sparkles.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)})
	sparkles.Lifetime = NumberRange.new(0.5, 1.2); sparkles.Rate = 40; sparkles.Speed = NumberRange.new(2, 6)
	sparkles.SpreadAngle = Vector2.new(180, 180); sparkles.LightEmission = 0.8
	sparkles.Texture = "rbxassetid://6490035152"; sparkles.Parent = platform

	currentPlatform = platform
	playSound(rootPart, "rbxassetid://3199270999", 0.4, 1.2)

	platformFollowConn = RunService.Heartbeat:Connect(function()
		if not platform or not platform.Parent then
			if platformFollowConn then platformFollowConn:Disconnect(); platformFollowConn = nil end; return
		end
		if not rootPart or not rootPart.Parent then return end
		platform.Position = platform.Position:Lerp(Vector3.new(rootPart.Position.X, rootPart.Position.Y - 4, rootPart.Position.Z), 0.2)
	end)

	task.spawn(function()
		task.wait(PLATFORM_DURATION - 2)
		if platform and platform.Parent then
			for i = 1, 20 do task.wait(0.1)
				if platform and platform.Parent then platform.Transparency = 0.5 + (i / 20) * 0.5 end
			end
		end
		if platformFollowConn then platformFollowConn:Disconnect(); platformFollowConn = nil end
		if platform and platform.Parent then platform:Destroy() end
		currentPlatform = nil; platformActive = false
		animateCooldown(platformCdBar, PLATFORM_COOLDOWN)
		task.wait(PLATFORM_COOLDOWN); canPlatform = true
	end)
end

-- ============================================
-- LUNGE
-- ============================================
local function activateLunge()
	if not canLunge or isLunging then return end
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart or humanoid.Health <= 0 then return end

	isLunging = true; canLunge = false
	local moveDir = humanoid.MoveDirection
	local lungeDir
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
	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = att; lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector; lv.MaxForce = 80000
	lv.VectorVelocity = lungeDir * lungeSpeed; lv.Parent = rootPart
	local ag = Instance.new("LinearVelocity")
	ag.Attachment0 = att; ag.RelativeTo = Enum.ActuatorRelativeTo.World
	ag.VelocityConstraintMode = Enum.VelocityConstraintMode.Line; ag.LineDirection = Vector3.yAxis
	ag.MaxForce = 8000; ag.LineVelocity = 0; ag.Parent = rootPart

	task.spawn(function()
		for i = 1, 10 do
			if not isLunging then break end
			humanoid.CameraOffset = Vector3.new(math.random(-10, 10) / 80, math.random(-10, 10) / 80, 0)
			task.wait(0.05)
		end
		humanoid.CameraOffset = Vector3.zero
	end)

	task.delay(lungeDuration, function()
		while true do
			if not rootPart or not rootPart.Parent or humanoid.Health <= 0 then break end
			if isOnCollidableSurface(rootPart) or not isVoidBelow(rootPart.Position) then break end

			local avoidDir = checkHeadObstacle(rootPart)
			if avoidDir and lv.Parent then
				local currentVel = lv.VectorVelocity
				local spd = currentVel.Magnitude
				local newDir = (lungeDir + avoidDir * 0.5).Unit
				lv.VectorVelocity = newDir * spd
			end

			task.wait(0.05)
		end
		if lv.Parent then lv:Destroy() end; if ag.Parent then ag:Destroy() end; if att.Parent then att:Destroy() end
		isLunging = false; if vfx then vfx.cleanup(0) end
		if rootPart and rootPart.Parent then
			local sa = Instance.new("Attachment"); sa.Parent = rootPart
			local sv = Instance.new("LinearVelocity")
			sv.Attachment0 = sa; sv.RelativeTo = Enum.ActuatorRelativeTo.World
			sv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector; sv.MaxForce = 30000
			sv.VectorVelocity = lungeDir * 20; sv.Parent = rootPart
			task.spawn(function()
				for i = 1, 10 do task.wait(0.03); if sv.Parent then sv.VectorVelocity *= 0.55 end end
				if sv.Parent then sv:Destroy() end; if sa.Parent then sa:Destroy() end
			end)
		end
		animateCooldown(lungeCdBar, LUNGE_COOLDOWN); task.wait(LUNGE_COOLDOWN); canLunge = true
	end)
end

-- ============================================
-- MEGA JUMP
-- ============================================
local function createShockwave(position, color)
	local c = color or Color3.fromRGB(50, 255, 100)
	local ring = Instance.new("Part")
	ring.Anchored = true; ring.CanCollide = false; ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.5, 4, 4)
	ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	ring.Material = Enum.Material.Neon; ring.Color = c; ring.Transparency = 0.3; ring.Parent = workspace
	local t = TweenService:Create(ring, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.5, 60, 60), Transparency = 1
	})
	t:Play(); t.Completed:Connect(function() ring:Destroy() end)
end

local function createRainbowShockwave(position)
	local ring = Instance.new("Part")
	ring.Anchored = true; ring.CanCollide = false; ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.5, 4, 4)
	ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	ring.Material = Enum.Material.Neon; ring.Color = Color3.fromRGB(255, 0, 0); ring.Transparency = 0.2
	ring.Parent = workspace
	task.spawn(function()
		local st = tick()
		while ring and ring.Parent and (tick() - st) < 1 do
			ring.Color = getRainbowColor((tick() - st) * 2); task.wait()
		end
	end)
	local t = TweenService:Create(ring, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.5, 80, 80), Transparency = 1
	})
	t:Play(); t.Completed:Connect(function() ring:Destroy() end)
end

local function createRainbowPillar(position)
	local pillar = Instance.new("Part")
	pillar.Anchored = true; pillar.CanCollide = false
	pillar.Size = Vector3.new(5, 0, 5); pillar.CFrame = CFrame.new(position)
	pillar.Material = Enum.Material.Neon; pillar.Color = Color3.fromRGB(255, 0, 0)
	pillar.Transparency = 0.4; pillar.Parent = workspace
	task.spawn(function()
		local st = tick()
		while pillar and pillar.Parent and (tick() - st) < 2 do
			pillar.Color = getRainbowColor((tick() - st) * 1.5); task.wait()
		end
	end)
	TweenService:Create(pillar, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(5, 100, 5), CFrame = CFrame.new(position + Vector3.new(0, 50, 0))
	}):Play()
	task.delay(0.8, function()
		local fade = TweenService:Create(pillar, TweenInfo.new(0.8, Enum.EasingStyle.Quad), {Transparency = 1, Size = Vector3.new(2, 100, 2)})
		fade:Play(); fade.Completed:Connect(function() pillar:Destroy() end)
	end)
end

local function createPillar(position)
	local pillar = Instance.new("Part")
	pillar.Anchored = true; pillar.CanCollide = false
	pillar.Size = Vector3.new(5, 0, 5); pillar.CFrame = CFrame.new(position)
	pillar.Material = Enum.Material.Neon; pillar.Color = Color3.fromRGB(50, 255, 100)
	pillar.Transparency = 0.5; pillar.Parent = workspace
	TweenService:Create(pillar, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(5, 80, 5), CFrame = CFrame.new(position + Vector3.new(0, 40, 0))
	}):Play()
	task.delay(0.6, function()
		local fade = TweenService:Create(pillar, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {Transparency = 1, Size = Vector3.new(2, 80, 2)})
		fade:Play(); fade.Completed:Connect(function() pillar:Destroy() end)
	end)
end

local function activateMegaJump()
	if not canMegaJump then return end
	megaJumpArmed = not megaJumpArmed
	if megaJumpArmed then
		megaJumpStroke.Color = Color3.fromRGB(150, 255, 150); megaJumpStroke.Thickness = 3
		task.spawn(function()
			while megaJumpArmed do
				if megaJumpStroke then TweenService:Create(megaJumpStroke, TweenInfo.new(0.5), {Transparency = 0.6}):Play() end
				task.wait(0.5)
				if megaJumpArmed and megaJumpStroke then TweenService:Create(megaJumpStroke, TweenInfo.new(0.5), {Transparency = 0}):Play() end
				task.wait(0.5)
			end
		end)
	else
		megaJumpStroke.Color = Color3.fromRGB(50, 255, 100); megaJumpStroke.Thickness = 1.5; megaJumpStroke.Transparency = 0.4
	end
end

local function performMegaJump()
	if not megaJumpArmed or not canMegaJump then return end
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart or humanoid.Health <= 0 then return end

	megaJumpArmed = false; canMegaJump = false; isMegaJumping = true
	megaJumpStroke.Color = Color3.fromRGB(50, 255, 100); megaJumpStroke.Thickness = 1.5; megaJumpStroke.Transparency = 0.4

	createShockwave(rootPart.Position); createPillar(rootPart.Position)
	playSound(rootPart, "rbxassetid://3199270999", 0.8, 0.7)

	local njp = humanoid.JumpPower; if njp == 0 then njp = 50 end
	local att = Instance.new("Attachment"); att.Parent = rootPart
	local jv = Instance.new("LinearVelocity")
	jv.Attachment0 = att; jv.RelativeTo = Enum.ActuatorRelativeTo.World
	jv.VelocityConstraintMode = Enum.VelocityConstraintMode.Line; jv.LineDirection = Vector3.yAxis
	jv.MaxForce = 80000; jv.LineVelocity = njp * MEGA_JUMP_MULT; jv.Parent = rootPart
	task.delay(0.15, function() if jv.Parent then jv:Destroy() end; if att.Parent then att:Destroy() end end)

	megaJumpGravityActive = true
	local savedGrav = workspace.Gravity
	workspace.Gravity = savedGrav * MEGA_JUMP_GRAVITY_SCALE

	local jp = Instance.new("ParticleEmitter")
	jp.Color = ColorSequence.new(Color3.fromRGB(50, 255, 100))
	jp.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0)})
	jp.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1)})
	jp.Lifetime = NumberRange.new(0.3, 0.8); jp.Rate = 60; jp.Speed = NumberRange.new(1, 4)
	jp.SpreadAngle = Vector2.new(180, 180); jp.LightEmission = 0.6; jp.Parent = rootPart

	task.spawn(function()
		task.wait(0.3)
		while true do
			if not rootPart or not rootPart.Parent or humanoid.Health <= 0 then break end
			local s = humanoid:GetState()
			if s == Enum.HumanoidStateType.Landed or s == Enum.HumanoidStateType.Running then break end
			task.wait(0.05)
		end
		if megaJumpGravityActive then workspace.Gravity = savedGrav; megaJumpGravityActive = false end
		isMegaJumping = false
		if rootPart and rootPart.Parent then createShockwave(rootPart.Position); playSound(rootPart, "rbxassetid://3199270999", 0.4, 1.5) end
		jp.Rate = 0; task.delay(1, function() if jp.Parent then jp:Destroy() end end)
		animateCooldown(megaJumpCdBar, MEGA_JUMP_COOLDOWN); task.wait(MEGA_JUMP_COOLDOWN); canMegaJump = true
	end)
end

-- ============================================
-- SHOCKWAVE TRAVEL
-- ============================================
local function cleanupShockwaveTravel()
	shockwaveEmergencyStop = true; isShockwaveTraveling = false
	if shockwaveTravelConn then shockwaveTravelConn:Disconnect(); shockwaveTravelConn = nil end
	for _, part in shockwaveTunnelParts do if part and part.Parent then part:Destroy() end end
	shockwaveTunnelParts = {}
	local character = player.Character
	if character then
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			for _, child in rootPart:GetChildren() do
				if child.Name == "ShockwaveVel" or child.Name == "ShockwaveAntiGrav" or child.Name == "ShockwaveAttach" then child:Destroy() end
			end
		end
	end
end

local function createPurpleTunnelRing(position, lookDir)
	local ring = Instance.new("Part")
	ring.Name = "TunnelRing"; ring.Anchored = true; ring.CanCollide = false
	ring.Shape = Enum.PartType.Cylinder; ring.Size = Vector3.new(0.3, 14, 14)
	ring.CFrame = CFrame.lookAt(position, position + lookDir) * CFrame.Angles(0, math.rad(90), 0)
	ring.Material = Enum.Material.Neon; ring.Color = Color3.fromRGB(160, 50, 255); ring.Transparency = 0.4
	ring.Parent = workspace
	table.insert(shockwaveTunnelParts, ring)
	task.delay(1.5, function()
		if ring and ring.Parent then
			local fade = TweenService:Create(ring, TweenInfo.new(1, Enum.EasingStyle.Quad), {Transparency = 1, Size = Vector3.new(0.3, 20, 20)})
			fade:Play(); fade.Completed:Connect(function()
				ring:Destroy()
				local idx = table.find(shockwaveTunnelParts, ring)
				if idx then table.remove(shockwaveTunnelParts, idx) end
			end)
		end
	end)
	return ring
end

local function activateShockwaveTravel()
	if not canShockwaveTravel or isShockwaveTraveling then return end
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local head = character:FindFirstChild("Head")
	if not humanoid or not rootPart or not head or humanoid.Health <= 0 then return end

	canShockwaveTravel = false; shockwaveEmergencyStop = false

	local moveDir = humanoid.MoveDirection
	local travelDir
	if moveDir.Magnitude > 0.1 then travelDir = moveDir.Unit else travelDir = rootPart.CFrame.LookVector end
	travelDir = Vector3.new(travelDir.X, 0, travelDir.Z)
	if travelDir.Magnitude < 0.1 then travelDir = Vector3.new(rootPart.CFrame.LookVector.X, 0, rootPart.CFrame.LookVector.Z) end
	travelDir = travelDir.Unit

	for i = 1, 10 do
		if shockwaveEmergencyStop then break end
		local sphere = Instance.new("Part")
		sphere.Shape = Enum.PartType.Ball; sphere.Anchored = true; sphere.CanCollide = false
		sphere.Size = Vector3.new(3, 3, 3); sphere.Position = head.Position
		sphere.Material = Enum.Material.Neon; sphere.Color = Color3.fromRGB(160, 50, 255); sphere.Transparency = 0.3
		sphere.Parent = workspace
		playSound(rootPart, "rbxassetid://3199270999", 0.3 + (i * 0.05), 0.8 + (i * 0.15))
		local es = 8 + (i * 3)
		local tw = TweenService:Create(sphere, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(es, es, es), Transparency = 1
		})
		tw:Play(); tw.Completed:Connect(function() sphere:Destroy() end)
		local d = 0.4 - (i * 0.035); if d < 0.05 then d = 0.05 end
		task.wait(d)
	end

	if shockwaveEmergencyStop then
		animateCooldown(shockwaveCdBar, SHOCKWAVE_TRAVEL_COOLDOWN)
		task.wait(SHOCKWAVE_TRAVEL_COOLDOWN); canShockwaveTravel = true; return
	end

	local cube = Instance.new("Part")
	cube.Anchored = true; cube.CanCollide = false; cube.Size = Vector3.new(4, 4, 4)
	cube.Position = head.Position; cube.Material = Enum.Material.Neon
	cube.Color = Color3.fromRGB(160, 50, 255); cube.Transparency = 0.3; cube.Parent = workspace
	playSound(rootPart, "rbxassetid://3199270999", 1, 0.5)
	task.spawn(function()
		local st = tick()
		while tick() - st < 1 do
			if cube and cube.Parent then cube.CFrame = cube.CFrame * CFrame.Angles(0.1, 0.1, 0.05) end; task.wait()
		end
	end)
	TweenService:Create(cube, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(30, 30, 30), Transparency = 1
	}):Play()
	task.delay(1.1, function() if cube and cube.Parent then cube:Destroy() end end)
	task.wait(0.5)

	if shockwaveEmergencyStop then
		animateCooldown(shockwaveCdBar, SHOCKWAVE_TRAVEL_COOLDOWN)
		task.wait(SHOCKWAVE_TRAVEL_COOLDOWN); canShockwaveTravel = true; return
	end

	isShockwaveTraveling = true
	rootPart.CFrame = CFrame.new(rootPart.Position, rootPart.Position + travelDir)

	local sAtt = Instance.new("Attachment"); sAtt.Name = "ShockwaveAttach"; sAtt.Parent = rootPart
	local sVel = Instance.new("LinearVelocity"); sVel.Name = "ShockwaveVel"
	sVel.Attachment0 = sAtt; sVel.RelativeTo = Enum.ActuatorRelativeTo.World
	sVel.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector; sVel.MaxForce = 100000
	sVel.VectorVelocity = travelDir * SHOCKWAVE_TRAVEL_SPEED; sVel.Parent = rootPart
	local sAG = Instance.new("LinearVelocity"); sAG.Name = "ShockwaveAntiGrav"
	sAG.Attachment0 = sAtt; sAG.RelativeTo = Enum.ActuatorRelativeTo.World
	sAG.VelocityConstraintMode = Enum.VelocityConstraintMode.Line; sAG.LineDirection = Vector3.yAxis
	sAG.MaxForce = 10000; sAG.LineVelocity = 0; sAG.Parent = rootPart

	local tp = Instance.new("ParticleEmitter")
	tp.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 50, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 20, 200))})
	tp.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0)})
	tp.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1)})
	tp.Lifetime = NumberRange.new(0.2, 0.5); tp.Rate = 150; tp.Speed = NumberRange.new(8, 20)
	tp.SpreadAngle = Vector2.new(15, 15); tp.LightEmission = 0.8; tp.Parent = head

	task.spawn(function()
		local travelStart = tick(); local lastRing = 0
		while isShockwaveTraveling and not shockwaveEmergencyStop do
			if not rootPart or not rootPart.Parent or humanoid.Health <= 0 then break end

			-- obstacle avoidance
			local avoidDir = checkHeadObstacle(rootPart)
			if avoidDir and sVel.Parent then
				local spd = sVel.VectorVelocity.Magnitude
				local newDir = (travelDir + avoidDir * 0.7).Unit
				sVel.VectorVelocity = newDir * spd
			end

			if tick() - lastRing > 0.08 then
				lastRing = tick()
				local ahead = head.Position + travelDir * (15 + math.random(0, 10))
				local offset = Vector3.new(math.random(-20, 20) / 10, math.random(-20, 20) / 10, math.random(-20, 20) / 10)
				createPurpleTunnelRing(ahead + offset, travelDir)
			end
			if tick() - travelStart >= SHOCKWAVE_TRAVEL_DURATION then break end
			task.wait()
		end

		isShockwaveTraveling = false

		if rootPart and rootPart.Parent and not shockwaveEmergencyStop then
			if isVoidBelow(rootPart.Position) and not isOnCollidableSurface(rootPart) then
				local _, nearestPos = findNearestCollidablePart(rootPart.Position)
				if nearestPos then
					local dirTo = (nearestPos - rootPart.Position).Unit
					local distTo = (nearestPos - rootPart.Position).Magnitude
					local tTime = math.clamp(distTo / SHOCKWAVE_TRAVEL_SPEED, 0.5, 5)
					if sVel and sVel.Parent then sVel.VectorVelocity = dirTo * SHOCKWAVE_TRAVEL_SPEED end
					local rs = tick()
					while true do
						if not rootPart or not rootPart.Parent then break end
						if (nearestPos - rootPart.Position).Magnitude < 8 or isOnCollidableSurface(rootPart) then break end
						if tick() - rs > tTime + 2 then break end
						task.wait(0.05)
					end
				end
			end
		end

		if sVel and sVel.Parent then sVel:Destroy() end
		if sAG and sAG.Parent then sAG:Destroy() end
		if sAtt and sAtt.Parent then sAtt:Destroy() end
		tp.Rate = 0; task.delay(1, function() if tp.Parent then tp:Destroy() end end)

		task.spawn(function()
			for _, part in shockwaveTunnelParts do
				if part and part.Parent then TweenService:Create(part, TweenInfo.new(0.5), {Transparency = 1}):Play() end
			end
			task.wait(0.6)
			for _, part in shockwaveTunnelParts do if part and part.Parent then part:Destroy() end end
			shockwaveTunnelParts = {}
		end)

		if rootPart and rootPart.Parent then
			local sa = Instance.new("Attachment"); sa.Parent = rootPart
			local sv = Instance.new("LinearVelocity")
			sv.Attachment0 = sa; sv.RelativeTo = Enum.ActuatorRelativeTo.World
			sv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector; sv.MaxForce = 40000
			sv.VectorVelocity = travelDir * 30; sv.Parent = rootPart
			task.spawn(function()
				for i = 1, 15 do task.wait(0.04); if sv.Parent then sv.VectorVelocity *= 0.5 end end
				if sv.Parent then sv:Destroy() end; if sa.Parent then sa:Destroy() end
			end)
			createShockwave(rootPart.Position, Color3.fromRGB(160, 50, 255))
			playSound(rootPart, "rbxassetid://3199270999", 0.6, 1.2)
		end

		shockwaveEmergencyStop = false
		animateCooldown(shockwaveCdBar, SHOCKWAVE_TRAVEL_COOLDOWN)
		task.wait(SHOCKWAVE_TRAVEL_COOLDOWN); canShockwaveTravel = true
	end)
end

-- ============================================
-- FUSION LEVELER (jump power = 110, gravity = 50%)
-- ============================================
local function activateFusion()
	if not canFusion or isFusionActive then return end
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart or humanoid.Health <= 0 then return end

	isFusionActive = true; canFusion = false

	local savedWalkSpeed = humanoid.WalkSpeed
	local savedGravity = workspace.Gravity

	-- save original jump values
	local savedJumpPower = humanoid.JumpPower
	local savedJumpHeight = humanoid.JumpHeight
	local savedUseJumpPower = humanoid.UseJumpPower

	-- force UseJumpPower = true and set to 110
	humanoid.UseJumpPower = true
	humanoid.JumpPower = FUSION_JUMP_POWER_TARGET

	humanoid.WalkSpeed = savedWalkSpeed * FUSION_SPEED_MULT
	workspace.Gravity = savedGravity * FUSION_GRAVITY_MULT

	-- also add velocity boost on each jump for guaranteed power
	local jumpBoostConn = nil
	jumpBoostConn = humanoid.StateChanged:Connect(function(_, newState)
		if not isFusionActive then
			if jumpBoostConn then jumpBoostConn:Disconnect(); jumpBoostConn = nil end
			return
		end
		if newState == Enum.HumanoidStateType.Jumping then
			-- extra upward velocity to guarantee the 110 jump power feels right
			local att = Instance.new("Attachment"); att.Parent = rootPart
			local jv = Instance.new("LinearVelocity")
			jv.Attachment0 = att; jv.RelativeTo = Enum.ActuatorRelativeTo.World
			jv.VelocityConstraintMode = Enum.VelocityConstraintMode.Line; jv.LineDirection = Vector3.yAxis
			jv.MaxForce = 50000
			-- boost = target - whatever the engine gives (add extra 60 on top)
			jv.LineVelocity = 60
			jv.Parent = rootPart
			task.delay(0.12, function()
				if jv.Parent then jv:Destroy() end
				if att.Parent then att:Destroy() end
			end)
		end
	end)
	fusionJumpConn = jumpBoostConn

	playSound(rootPart, "rbxassetid://3199270999", 0.6, 1.0)
	createShockwave(rootPart.Position, Color3.fromRGB(255, 200, 50))

	local aura = Instance.new("ParticleEmitter")
	aura.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 50)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 150, 0))})
	aura.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(0.5, 1), NumberSequenceKeypoint.new(1, 0)})
	aura.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1)})
	aura.Lifetime = NumberRange.new(0.4, 0.8); aura.Rate = 50; aura.Speed = NumberRange.new(2, 5)
	aura.SpreadAngle = Vector2.new(180, 180); aura.LightEmission = 0.7; aura.Parent = rootPart

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 200, 50); light.Brightness = 2; light.Range = 20; light.Parent = rootPart

	task.spawn(function()
		task.wait(FUSION_DURATION)
		isFusionActive = false
		if jumpBoostConn then jumpBoostConn:Disconnect(); jumpBoostConn = nil end
		fusionJumpConn = nil

		if humanoid and humanoid.Parent then
			humanoid.WalkSpeed = savedWalkSpeed
			humanoid.UseJumpPower = savedUseJumpPower
			humanoid.JumpPower = savedJumpPower
			humanoid.JumpHeight = savedJumpHeight
		end
		workspace.Gravity = savedGravity

		if rootPart and rootPart.Parent then
			createShockwave(rootPart.Position, Color3.fromRGB(255, 200, 50))
			playSound(rootPart, "rbxassetid://3199270999", 0.4, 1.5)
		end
		aura.Rate = 0
		task.delay(1, function() if aura.Parent then aura:Destroy() end; if light.Parent then light:Destroy() end end)
		animateCooldown(fusionCdBar, FUSION_COOLDOWN); task.wait(FUSION_COOLDOWN); canFusion = true
	end)
end

-- ============================================
-- RAINBOW LOCATOR
-- ============================================
local freecamGui = nil
local freecamConn = nil
local freecamCF = CFrame.new()
local freecamSpeed = 1
local destinationMarker = nil
local markerBeam = nil
local selectedDestination = nil
local freecamInputConns = {}
local selectCallback = nil

local function cleanupFreecam()
	rainbowFreecamActive = false

	-- restore walkspeed
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = savedWalkSpeedForRainbow
		end
	end

	if freecamConn then freecamConn:Disconnect(); freecamConn = nil end
	if freecamGui and freecamGui.Parent then freecamGui:Destroy() end
	freecamGui = nil
	if destinationMarker and destinationMarker.Parent then destinationMarker:Destroy() end
	destinationMarker = nil
	if markerBeam and markerBeam.Parent then markerBeam:Destroy() end
	markerBeam = nil
	for _, conn in freecamInputConns do
		if conn and typeof(conn) == "RBXScriptConnection" and conn.Connected then conn:Disconnect() end
	end
	freecamInputConns = {}
	selectCallback = nil

	camera.CameraType = Enum.CameraType.Custom
	if character then
		camera.CameraSubject = character:FindFirstChildOfClass("Humanoid")
	end
end

local function createFreecamUI()
	if freecamGui then freecamGui:Destroy() end

	freecamGui = Instance.new("ScreenGui")
	freecamGui.Name = "FreecamGui"
	freecamGui.ResetOnSpawn = false
	freecamGui.Parent = player.PlayerGui

	local instructionLabel = Instance.new("TextLabel")
	instructionLabel.Size = UDim2.new(0, 500, 0, 50)
	instructionLabel.Position = UDim2.new(0.5, 0, 0, 20)
	instructionLabel.AnchorPoint = Vector2.new(0.5, 0)
	instructionLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	instructionLabel.BackgroundTransparency = 0.3
	instructionLabel.BorderSizePixel = 0
	instructionLabel.Text = "🌈 AIM AT DESTINATION — Then press SELECT!"
	instructionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	instructionLabel.TextSize = 16
	instructionLabel.Font = Enum.Font.GothamBold
	instructionLabel.Parent = freecamGui
	Instance.new("UICorner", instructionLabel).CornerRadius = UDim.new(0, 10)

	task.spawn(function()
		local t = 0
		while instructionLabel and instructionLabel.Parent do
			t += 0.02; instructionLabel.TextColor3 = getRainbowColor(t); task.wait(0.03)
		end
	end)

	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Size = UDim2.new(0, 120, 0, 36)
	cancelBtn.Position = UDim2.new(0.5, 70, 0, 78)
	cancelBtn.AnchorPoint = Vector2.new(0.5, 0)
	cancelBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
	cancelBtn.BorderSizePixel = 0
	cancelBtn.Text = "✕ Cancel"
	cancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	cancelBtn.TextSize = 14
	cancelBtn.Font = Enum.Font.GothamBold
	cancelBtn.Parent = freecamGui
	Instance.new("UICorner", cancelBtn).CornerRadius = UDim.new(0, 8)
	cancelBtn.MouseButton1Click:Connect(function()
		cleanupFreecam()
		isRainbowLocatorActive = false
		task.spawn(function() animateCooldown(rainbowCdBar, 2); task.wait(2); canRainbowLocator = true end)
	end)

	local joyContainer = Instance.new("Frame")
	joyContainer.Name = "JoyContainer"
	joyContainer.Size = UDim2.new(0, 560, 0, 180)
	joyContainer.Position = UDim2.new(0.5, 0, 1, -20)
	joyContainer.AnchorPoint = Vector2.new(0.5, 1)
	joyContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	joyContainer.BackgroundTransparency = 0.2
	joyContainer.BorderSizePixel = 0
	joyContainer.Parent = freecamGui
	Instance.new("UICorner", joyContainer).CornerRadius = UDim.new(0, 14)

	local selectBtn = Instance.new("TextButton")
	selectBtn.Name = "SelectBtn"
	selectBtn.Size = UDim2.new(0, 160, 0, 40)
	selectBtn.Position = UDim2.new(0.5, 0, 0, 8)
	selectBtn.AnchorPoint = Vector2.new(0.5, 0)
	selectBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
	selectBtn.BorderSizePixel = 0
	selectBtn.Text = "✓ SELECT DESTINATION"
	selectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	selectBtn.TextSize = 14
	selectBtn.Font = Enum.Font.GothamBold
	selectBtn.ZIndex = 5
	selectBtn.Parent = joyContainer
	Instance.new("UICorner", selectBtn).CornerRadius = UDim.new(0, 10)

	local selectStroke = Instance.new("UIStroke")
	selectStroke.Color = Color3.fromRGB(80, 255, 80)
	selectStroke.Thickness = 2
	selectStroke.Parent = selectBtn

	task.spawn(function()
		while selectBtn and selectBtn.Parent do
			TweenService:Create(selectStroke, TweenInfo.new(0.6), {Transparency = 0.6}):Play()
			task.wait(0.6)
			if selectBtn and selectBtn.Parent then
				TweenService:Create(selectStroke, TweenInfo.new(0.6), {Transparency = 0}):Play()
				task.wait(0.6)
			end
		end
	end)

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(0, 220, 0, 16)
	statusLabel.Position = UDim2.new(0.5, 0, 0, 52)
	statusLabel.AnchorPoint = Vector2.new(0.5, 0)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = "Aim at a collidable surface"
	statusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	statusLabel.TextSize = 11
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.ZIndex = 5
	statusLabel.Parent = joyContainer

	-- Move joystick RED
	local moveJoyFrame = Instance.new("Frame")
	moveJoyFrame.Name = "MoveJoy"
	moveJoyFrame.Size = UDim2.new(0, 110, 0, 110)
	moveJoyFrame.Position = UDim2.new(0, 20, 1, -10)
	moveJoyFrame.AnchorPoint = Vector2.new(0, 1)
	moveJoyFrame.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
	moveJoyFrame.BackgroundTransparency = 0.3
	moveJoyFrame.BorderSizePixel = 0
	moveJoyFrame.Parent = joyContainer
	Instance.new("UICorner", moveJoyFrame).CornerRadius = UDim.new(1, 0)
	local mjs = Instance.new("UIStroke"); mjs.Color = Color3.fromRGB(255, 80, 80); mjs.Thickness = 2; mjs.Parent = moveJoyFrame

	local mjl = Instance.new("TextLabel")
	mjl.Size = UDim2.new(1, 0, 0, 14); mjl.Position = UDim2.new(0, 0, 0, -16)
	mjl.BackgroundTransparency = 1; mjl.Text = "MOVE"; mjl.TextColor3 = Color3.fromRGB(255, 100, 100)
	mjl.TextSize = 10; mjl.Font = Enum.Font.GothamBold; mjl.Parent = moveJoyFrame

	local moveThumb = Instance.new("Frame")
	moveThumb.Size = UDim2.new(0, 28, 0, 28)
	moveThumb.Position = UDim2.new(0.5, 0, 0.5, 0); moveThumb.AnchorPoint = Vector2.new(0.5, 0.5)
	moveThumb.BackgroundColor3 = Color3.fromRGB(255, 60, 60); moveThumb.BorderSizePixel = 0
	moveThumb.Parent = moveJoyFrame
	Instance.new("UICorner", moveThumb).CornerRadius = UDim.new(1, 0)

	-- Camera joystick BLUE
	local camJoyFrame = Instance.new("Frame")
	camJoyFrame.Name = "CamJoy"
	camJoyFrame.Size = UDim2.new(0, 110, 0, 110)
	camJoyFrame.Position = UDim2.new(1, -20, 1, -10)
	camJoyFrame.AnchorPoint = Vector2.new(1, 1)
	camJoyFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 80)
	camJoyFrame.BackgroundTransparency = 0.3
	camJoyFrame.BorderSizePixel = 0
	camJoyFrame.Parent = joyContainer
	Instance.new("UICorner", camJoyFrame).CornerRadius = UDim.new(1, 0)
	local cjs = Instance.new("UIStroke"); cjs.Color = Color3.fromRGB(80, 80, 255); cjs.Thickness = 2; cjs.Parent = camJoyFrame

	local cjl = Instance.new("TextLabel")
	cjl.Size = UDim2.new(1, 0, 0, 14); cjl.Position = UDim2.new(0, 0, 0, -16)
	cjl.BackgroundTransparency = 1; cjl.Text = "CAMERA"; cjl.TextColor3 = Color3.fromRGB(100, 100, 255)
	cjl.TextSize = 10; cjl.Font = Enum.Font.GothamBold; cjl.Parent = camJoyFrame

	local camThumb = Instance.new("Frame")
	camThumb.Size = UDim2.new(0, 28, 0, 28)
	camThumb.Position = UDim2.new(0.5, 0, 0.5, 0); camThumb.AnchorPoint = Vector2.new(0.5, 0.5)
	camThumb.BackgroundColor3 = Color3.fromRGB(60, 60, 255); camThumb.BorderSizePixel = 0
	camThumb.Parent = camJoyFrame
	Instance.new("UICorner", camThumb).CornerRadius = UDim.new(1, 0)

	-- Speed slider GREEN
	local sliderFrame = Instance.new("Frame")
	sliderFrame.Name = "SpeedSlider"
	sliderFrame.Size = UDim2.new(0, 28, 0, 100)
	sliderFrame.Position = UDim2.new(0.5, 0, 1, -10); sliderFrame.AnchorPoint = Vector2.new(0.5, 1)
	sliderFrame.BackgroundColor3 = Color3.fromRGB(20, 60, 20)
	sliderFrame.BackgroundTransparency = 0.3; sliderFrame.BorderSizePixel = 0
	sliderFrame.Parent = joyContainer
	Instance.new("UICorner", sliderFrame).CornerRadius = UDim.new(0, 8)
	local sfs = Instance.new("UIStroke"); sfs.Color = Color3.fromRGB(80, 255, 80); sfs.Thickness = 2; sfs.Parent = sliderFrame

	local sfl = Instance.new("TextLabel")
	sfl.Size = UDim2.new(0, 60, 0, 14); sfl.Position = UDim2.new(0.5, 0, 0, -16)
	sfl.AnchorPoint = Vector2.new(0.5, 0); sfl.BackgroundTransparency = 1; sfl.Text = "SPEED"
	sfl.TextColor3 = Color3.fromRGB(100, 255, 100); sfl.TextSize = 10; sfl.Font = Enum.Font.GothamBold; sfl.Parent = sliderFrame

	local sliderThumb = Instance.new("Frame")
	sliderThumb.Size = UDim2.new(1, -4, 0, 18)
	sliderThumb.Position = UDim2.new(0.5, 0, 0.5, 0); sliderThumb.AnchorPoint = Vector2.new(0.5, 0.5)
	sliderThumb.BackgroundColor3 = Color3.fromRGB(60, 255, 60); sliderThumb.BorderSizePixel = 0
	sliderThumb.Parent = sliderFrame
	Instance.new("UICorner", sliderThumb).CornerRadius = UDim.new(0, 6)

	local sliderValue = Instance.new("TextLabel")
	sliderValue.Size = UDim2.new(0, 60, 0, 14)
	sliderValue.Position = UDim2.new(0.5, 0, 1, 4); sliderValue.AnchorPoint = Vector2.new(0.5, 0)
	sliderValue.BackgroundTransparency = 1; sliderValue.Text = "1.0x"
	sliderValue.TextColor3 = Color3.fromRGB(100, 255, 100); sliderValue.TextSize = 10
	sliderValue.Font = Enum.Font.GothamBold; sliderValue.Parent = sliderFrame

	local moveInput = Vector2.zero
	local camInput = Vector2.zero
	local moveDragging = false
	local camDragging = false
	local sliderDragging = false
	local mouseOverPanel = false
	local mouseOverTopUI = false

	joyContainer.MouseEnter:Connect(function() mouseOverPanel = true end)
	joyContainer.MouseLeave:Connect(function() mouseOverPanel = false end)
	instructionLabel.MouseEnter:Connect(function() mouseOverTopUI = true end)
	instructionLabel.MouseLeave:Connect(function() mouseOverTopUI = false end)
	cancelBtn.MouseEnter:Connect(function() mouseOverTopUI = true end)
	cancelBtn.MouseLeave:Connect(function() mouseOverTopUI = false end)

	moveJoyFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then moveDragging = true end
	end)
	camJoyFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then camDragging = true end
	end)
	sliderFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then sliderDragging = true end
	end)

	local ic = UserInputService.InputChanged:Connect(function(input)
		if not freecamGui or not freecamGui.Parent then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			if moveDragging then
				local center = moveJoyFrame.AbsolutePosition + moveJoyFrame.AbsoluteSize / 2
				local pos = Vector2.new(input.Position.X, input.Position.Y)
				local delta = (pos - center) / (moveJoyFrame.AbsoluteSize.X / 2)
				delta = Vector2.new(math.clamp(delta.X, -1, 1), math.clamp(delta.Y, -1, 1))
				moveInput = delta
				moveThumb.Position = UDim2.new(0.5 + delta.X * 0.35, 0, 0.5 + delta.Y * 0.35, 0)
			end
			if camDragging then
				local center = camJoyFrame.AbsolutePosition + camJoyFrame.AbsoluteSize / 2
				local pos = Vector2.new(input.Position.X, input.Position.Y)
				local delta = (pos - center) / (camJoyFrame.AbsoluteSize.X / 2)
				delta = Vector2.new(math.clamp(delta.X, -1, 1), math.clamp(delta.Y, -1, 1))
				camInput = delta
				camThumb.Position = UDim2.new(0.5 + delta.X * 0.35, 0, 0.5 + delta.Y * 0.35, 0)
			end
			if sliderDragging then
				local top = sliderFrame.AbsolutePosition.Y
				local height = sliderFrame.AbsoluteSize.Y
				local relY = math.clamp((input.Position.Y - top) / height, 0, 1)
				freecamSpeed = 0.2 + (1 - relY) * 3.8
				sliderThumb.Position = UDim2.new(0.5, 0, relY, 0)
				sliderValue.Text = string.format("%.1fx", freecamSpeed)
			end
		end
	end)
	table.insert(freecamInputConns, ic)

	local ie = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if moveDragging then moveDragging = false; moveInput = Vector2.zero; moveThumb.Position = UDim2.new(0.5, 0, 0.5, 0) end
			if camDragging then camDragging = false; camInput = Vector2.zero; camThumb.Position = UDim2.new(0.5, 0, 0.5, 0) end
			sliderDragging = false
		end
	end)
	table.insert(freecamInputConns, ie)

	local keyState = {}
	local kc1 = UserInputService.InputBegan:Connect(function(input, gp) if gp then return end; keyState[input.KeyCode] = true end)
	table.insert(freecamInputConns, kc1)
	local kc2 = UserInputService.InputEnded:Connect(function(input) keyState[input.KeyCode] = false end)
	table.insert(freecamInputConns, kc2)

	local lastValidHit = nil
	local lastValidPart = nil

	selectBtn.MouseButton1Click:Connect(function()
		if lastValidHit and lastValidPart and lastValidPart.CanCollide then
			if selectCallback then selectCallback(lastValidHit, lastValidPart) end
		else
			statusLabel.Text = "⚠ Aim at a collidable surface first!"
			statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
			task.delay(1, function()
				if statusLabel and statusLabel.Parent then
					statusLabel.Text = "Aim at a collidable surface"
					statusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
				end
			end)
		end
	end)

	return function()
		return moveInput, camInput, freecamSpeed, keyState, mouseOverPanel or mouseOverTopUI
	end, function(hit, part)
		lastValidHit = hit; lastValidPart = part
		if hit and part and part.CanCollide then
			statusLabel.Text = "✓ Valid: " .. part.Name
			statusLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
			selectBtn.BackgroundColor3 = Color3.fromRGB(40, 200, 40)
		else
			statusLabel.Text = "Aim at a collidable surface"
			statusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
			selectBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		end
	end
end

local function activateRainbowLocator()
	if not canRainbowLocator or isRainbowLocatorActive then return end
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart or humanoid.Health <= 0 then return end

	isRainbowLocatorActive = true; canRainbowLocator = false; rainbowFreecamActive = true
	selectedDestination = nil

	-- freeze player movement
	savedWalkSpeedForRainbow = humanoid.WalkSpeed
	humanoid.WalkSpeed = 0.01

	destinationMarker = Instance.new("Part")
	destinationMarker.Name = "DestMarker"; destinationMarker.Anchored = true; destinationMarker.CanCollide = false
	destinationMarker.Size = Vector3.new(3, 3, 3); destinationMarker.Shape = Enum.PartType.Ball
	destinationMarker.Material = Enum.Material.Neon; destinationMarker.Transparency = 0.8
	destinationMarker.Color = Color3.fromRGB(255, 0, 0); destinationMarker.Parent = workspace

	task.spawn(function()
		local t = 0
		while destinationMarker and destinationMarker.Parent do
			t += 0.03; destinationMarker.Color = getRainbowColor(t); task.wait(0.03)
		end
	end)

	markerBeam = Instance.new("Part")
	markerBeam.Name = "MarkerBeam"; markerBeam.Anchored = true; markerBeam.CanCollide = false
	markerBeam.Size = Vector3.new(0.3, 50, 0.3); markerBeam.Material = Enum.Material.Neon
	markerBeam.Transparency = 0.5; markerBeam.Parent = workspace

	task.spawn(function()
		local t = 0
		while markerBeam and markerBeam.Parent do
			t += 0.03; markerBeam.Color = getRainbowColor(t + 0.5)
			if destinationMarker and destinationMarker.Parent then
				markerBeam.CFrame = CFrame.new(destinationMarker.Position + Vector3.new(0, 25, 0))
			end
			task.wait(0.03)
		end
	end)

	camera.CameraType = Enum.CameraType.Scriptable
	freecamCF = camera.CFrame

	local getInputs, updateHitInfo = createFreecamUI()

	selectCallback = function(hitPos, hitPart)
		selectedDestination = hitPos + Vector3.new(0, 3, 0)
		cleanupFreecam() -- this restores walkspeed

		task.spawn(function()
			local char = player.Character
			if not char then
				isRainbowLocatorActive = false
				task.spawn(function() animateCooldown(rainbowCdBar, 2); task.wait(2); canRainbowLocator = true end)
				return
			end
			local hum = char:FindFirstChildOfClass("Humanoid")
			local rp = char:FindFirstChild("HumanoidRootPart")
			if not hum or not rp or hum.Health <= 0 or not selectedDestination then
				isRainbowLocatorActive = false
				task.spawn(function() animateCooldown(rainbowCdBar, 2); task.wait(2); canRainbowLocator = true end)
				return
			end

			local dest = selectedDestination
			createRainbowPillar(rp.Position); createRainbowShockwave(rp.Position)
			playSound(rp, "rbxassetid://3199270999", 0.8, 0.6)

			local travelAura = Instance.new("ParticleEmitter")
			travelAura.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0)})
			travelAura.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1)})
			travelAura.Lifetime = NumberRange.new(0.3, 0.6); travelAura.Rate = 80
			travelAura.Speed = NumberRange.new(3, 8); travelAura.SpreadAngle = Vector2.new(180, 180)
			travelAura.LightEmission = 0.8; travelAura.Parent = rp
			task.spawn(function()
				local t = 0
				while travelAura and travelAura.Parent do
					t += 0.02; travelAura.Color = ColorSequence.new(getRainbowColor(t)); task.wait(0.03)
				end
			end)

			-- phase 1: altitude with obstacle avoidance
			local targetY = dest.Y
			local yDiff = targetY - rp.Position.Y

			if math.abs(yDiff) > 3 then
				local riseAtt = Instance.new("Attachment"); riseAtt.Parent = rp
				local riseVel = Instance.new("LinearVelocity")
				riseVel.Attachment0 = riseAtt; riseVel.RelativeTo = Enum.ActuatorRelativeTo.World
				riseVel.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector; riseVel.MaxForce = 60000
				riseVel.VectorVelocity = Vector3.new(0, yDiff > 0 and 80 or -80, 0); riseVel.Parent = rp

				local holdH = Instance.new("LinearVelocity")
				holdH.Attachment0 = riseAtt; holdH.RelativeTo = Enum.ActuatorRelativeTo.World
				holdH.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
				holdH.PrimaryTangentAxis = Vector3.new(1, 0, 0)
				holdH.SecondaryTangentAxis = Vector3.new(0, 0, 1)
				holdH.MaxForce = 40000; holdH.PlaneVelocity = Vector2.zero; holdH.Parent = rp

				while true do
					if not rp or not rp.Parent or hum.Health <= 0 then break end
					if math.abs(rp.Position.Y - targetY) < 3 then break end

					-- obstacle avoidance while rising
					local avoidDir = checkHeadObstacle(rp)
					if avoidDir then
						holdH.PlaneVelocity = Vector2.new(avoidDir.X * 40, avoidDir.Z * 40)
					else
						holdH.PlaneVelocity = Vector2.zero
					end

					task.wait(0.05)
				end
				if riseVel.Parent then riseVel:Destroy() end
				if holdH.Parent then holdH:Destroy() end
				if riseAtt.Parent then riseAtt:Destroy() end
			end

			-- phase 2: horizontal with obstacle avoidance
			local startPos = rp.Position
			local endPos = Vector3.new(dest.X, rp.Position.Y, dest.Z)
			local horizontalDist = (endPos - startPos).Magnitude

			if horizontalDist > 3 then
				local hDir = (endPos - startPos).Unit
				rp.CFrame = CFrame.new(rp.Position, rp.Position + hDir)

				local hAtt = Instance.new("Attachment"); hAtt.Parent = rp
				local hVel = Instance.new("LinearVelocity")
				hVel.Attachment0 = hAtt; hVel.RelativeTo = Enum.ActuatorRelativeTo.World
				hVel.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector; hVel.MaxForce = 60000
				hVel.VectorVelocity = Vector3.zero; hVel.Parent = rp

				local hAntiGrav = Instance.new("LinearVelocity")
				hAntiGrav.Attachment0 = hAtt; hAntiGrav.RelativeTo = Enum.ActuatorRelativeTo.World
				hAntiGrav.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
				hAntiGrav.LineDirection = Vector3.yAxis; hAntiGrav.MaxForce = 8000
				hAntiGrav.LineVelocity = 0; hAntiGrav.Parent = rp

				local travelTime = math.clamp(horizontalDist / 120, 0.5, 8)
				local elapsed = 0

				while elapsed < travelTime do
					if not rp or not rp.Parent or hum.Health <= 0 then break end
					local alpha = elapsed / travelTime
					local speedMult = math.max(math.sin(alpha * math.pi), 0.1)
					local baseVel = hDir * (horizontalDist / travelTime) * speedMult * 1.6

					-- obstacle avoidance
					local avoidDir = checkHeadObstacle(rp)
					if avoidDir then
						local avoidVel = avoidDir * 50
						baseVel = baseVel + avoidVel
					end

					hVel.VectorVelocity = baseVel

					local remain = Vector3.new(endPos.X - rp.Position.X, 0, endPos.Z - rp.Position.Z)
					if remain.Magnitude < 5 then break end
					elapsed += task.wait()
				end

				if hVel.Parent then hVel:Destroy() end
				if hAntiGrav.Parent then hAntiGrav:Destroy() end
				if hAtt.Parent then hAtt:Destroy() end
			end

			if rp and rp.Parent then
				createRainbowPillar(rp.Position); createRainbowShockwave(rp.Position)
				playSound(rp, "rbxassetid://3199270999", 0.6, 1.2)
			end
			travelAura.Rate = 0
			task.delay(1, function() if travelAura.Parent then travelAura:Destroy() end end)

			isRainbowLocatorActive = false
			animateCooldown(rainbowCdBar, RAINBOW_LOCATOR_COOLDOWN)
			task.wait(RAINBOW_LOCATOR_COOLDOWN); canRainbowLocator = true
		end)
	end

	freecamConn = RunService.RenderStepped:Connect(function(dt)
		if not rainbowFreecamActive then return end

		local moveIn, camIn, speed, keys, overUI = getInputs()

		local kbMove = Vector3.zero
		if keys[Enum.KeyCode.W] then kbMove += Vector3.new(0, 0, -1) end
		if keys[Enum.KeyCode.S] then kbMove += Vector3.new(0, 0, 1) end
		if keys[Enum.KeyCode.A] then kbMove += Vector3.new(-1, 0, 0) end
		if keys[Enum.KeyCode.D] then kbMove += Vector3.new(1, 0, 0) end
		if keys[Enum.KeyCode.Space] then kbMove += Vector3.new(0, 1, 0) end
		if keys[Enum.KeyCode.LeftShift] then kbMove += Vector3.new(0, -1, 0) end

		local moveVec = Vector3.new(moveIn.X, 0, moveIn.Y) * speed + kbMove
		local camRotX = camIn.X * 2 * dt
		local camRotY = camIn.Y * 2 * dt

		local rx, ry, _ = freecamCF:ToEulerAnglesYXZ()
		ry = ry - camRotX
		rx = math.clamp(rx - camRotY, -math.rad(85), math.rad(85))
		freecamCF = CFrame.new(freecamCF.Position) * CFrame.fromEulerAnglesYXZ(rx, ry, 0)
		freecamCF = freecamCF + freecamCF:VectorToWorldSpace(moveVec * 60 * speed * dt)
		camera.CFrame = freecamCF

		if not overUI then
			local mousePos = UserInputService:GetMouseLocation()
			local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
			local rayParams = RaycastParams.new()
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			local filterList = {}
			if player.Character then table.insert(filterList, player.Character) end
			if destinationMarker then table.insert(filterList, destinationMarker) end
			if markerBeam then table.insert(filterList, markerBeam) end
			rayParams.FilterDescendantsInstances = filterList

			local result = workspace:Raycast(ray.Origin, ray.Direction * 5000, rayParams)
			if result and result.Instance then
				if destinationMarker and destinationMarker.Parent then
					destinationMarker.Position = result.Position + Vector3.new(0, 1.5, 0)
					destinationMarker.Transparency = 0.3
					destinationMarker.Size = Vector3.new(3, 3, 3)
				end
				updateHitInfo(result.Position, result.Instance)
			else
				if destinationMarker and destinationMarker.Parent then
					destinationMarker.Transparency = 0.8
					destinationMarker.Size = Vector3.new(1, 1, 1)
				end
				updateHitInfo(nil, nil)
			end
		end
	end)
end

-- ============================================
-- EMERGENCY STOP
-- ============================================
local function emergencyStop()
	if isShockwaveTraveling then cleanupShockwaveTravel() end

	local character = player.Character
	if character then
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			for _, child in rootPart:GetChildren() do
				if child:IsA("LinearVelocity") or (child:IsA("Attachment") and child.Name ~= "RootAttachment") then
					child:Destroy()
				end
			end
		end
	end

	if isLunging then isLunging = false end
	if isDashing then isDashing = false end

	if rainbowFreecamActive then
		cleanupFreecam()
		isRainbowLocatorActive = false
		task.spawn(function() animateCooldown(rainbowCdBar, 2); task.wait(2); canRainbowLocator = true end)
	end

	emergencyBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
	task.delay(0.3, function() emergencyBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30) end)
	if character and character:FindFirstChild("HumanoidRootPart") then
		playSound(character.HumanoidRootPart, "rbxassetid://3199270999", 0.5, 2)
	end
end

emergencyBtn.MouseButton1Click:Connect(emergencyStop)

-- ============================================
-- BUTTON CLICKS
-- ============================================
platformBtn.MouseButton1Click:Connect(activatePlatform)
lungeBtn.MouseButton1Click:Connect(activateLunge)
megaJumpBtn.MouseButton1Click:Connect(activateMegaJump)
shockwaveBtn.MouseButton1Click:Connect(activateShockwaveTravel)
fusionBtn.MouseButton1Click:Connect(activateFusion)
rainbowBtn.MouseButton1Click:Connect(activateRainbowLocator)

-- ============================================
-- KEYBINDS
-- ============================================
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if rainbowFreecamActive then return end

	if input.KeyCode == Enum.KeyCode.Q then activatePlatform()
	elseif input.KeyCode == Enum.KeyCode.E then activateLunge()
	elseif input.KeyCode == Enum.KeyCode.R then activateMegaJump()
	elseif input.KeyCode == Enum.KeyCode.T then activateShockwaveTravel()
	elseif input.KeyCode == Enum.KeyCode.F then activateFusion()
	elseif input.KeyCode == Enum.KeyCode.G then activateRainbowLocator()
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
	if platformFollowConn then platformFollowConn:Disconnect(); platformFollowConn = nil end
	if currentPlatform and currentPlatform.Parent then currentPlatform:Destroy() end
	currentPlatform = nil; platformActive = false

	humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Jumping then
			if megaJumpArmed and canMegaJump then performMegaJump() end
			if not dashedThisJump then
				task.delay(0.05, function()
					if dashEnabled and not dashedThisJump and humanoid.Health > 0 then
						dashedThisJump = true; performDash()
					end
				end)
			end
		elseif newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.Running then
			dashedThisJump = false
		end
	end)
end

if player.Character then onCharacterAdded(player.Character) end
player.CharacterAdded:Connect(onCharacterAdded)

print("[Abilities V4] Q=Platform E=Lunge R=MegaJump T=ShockwaveTravel F=Fusion G=RainbowLocator X=EmergencyStop")
