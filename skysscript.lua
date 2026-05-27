------------------------------
-- SUPERMAN FLY SYSTEM
-- Vollständig optimiert für iPad / Touch
-- Features: Joystick, Höhenbuttons, Speed-Slider, Minimize-Animation
-- Touch-Identifier System: kein Hängenbleiben, kein falscher State
------------------------------

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")
local originalGravity = Workspace.Gravity

local isFlying = false
local flightSpeed = 50
local isMinimized = false

-- Flugzustände
local joystickInput = Vector2.new(0, 0)
local heightInput = 0  -- -1 runter, 0 neutral, 1 hoch
local currentVelocity = Vector3.new(0, 0, 0)
local currentCF = nil
local currentRoll = 0
local maxRoll = 35
local lerpCoef = 0.12
local bobbingFrequency = 1
local bobbingAmplitude = 0.4

local flightConns = {}
local currentAnimTrack = nil

-- Touch-Identifier (verhindert Hängenbleiben)
local joystickTouchId = nil
local sliderTouchId = nil
local dragTouchId = nil
local heightUpTouchId = nil
local heightDownTouchId = nil

------------------------------
-- ANIMATION
------------------------------
local function disableDefaultAnimate()
	local a = character:FindFirstChild("Animate")
	if a then a.Disabled = true end
end
local function enableDefaultAnimate()
	local a = character:FindFirstChild("Animate")
	if a then a.Disabled = false end
end
local function playAnimation(animId, startTime, speed)
	if currentAnimTrack then
		currentAnimTrack:Stop(0.1)
		currentAnimTrack = nil
	end
	disableDefaultAnimate()
	for _, t in ipairs(humanoid:GetPlayingAnimationTracks()) do t:Stop() end
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. tostring(animId)
	currentAnimTrack = humanoid:LoadAnimation(anim)
	currentAnimTrack:Play()
	currentAnimTrack.TimePosition = startTime
	currentAnimTrack:AdjustSpeed(speed)
end
local function stopAnimation()
	if currentAnimTrack then
		currentAnimTrack:Stop(0.1)
		currentAnimTrack = nil
	end
	enableDefaultAnimate()
	for _, t in ipairs(humanoid:GetPlayingAnimationTracks()) do t:Stop() end
end

------------------------------
-- HELPER
------------------------------
local function createElement(className, props, parent)
	local obj = Instance.new(className)
	for k, v in pairs(props) do obj[k] = v end
	if parent then obj.Parent = parent end
	return obj
end

local function tween(obj, info, props)
	TweenService:Create(obj, info, props):Play()
end

local function quickTween(obj, props, t, style, dir)
	tween(obj, TweenInfo.new(t or 0.25, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
end

------------------------------
-- GUI ROOT
------------------------------
local flyGui = createElement("ScreenGui", {
	Name = "FlyGuiIPad",
	ResetOnSpawn = false,
	IgnoreGuiInset = true
}, player:WaitForChild("PlayerGui"))

------------------------------
-- PANEL (unten Mitte)
------------------------------
local PANEL_HEIGHT_MAX = 100
local PANEL_HEIGHT_MIN = 50

local panel = createElement("Frame", {
	Name = "Panel",
	Size = UDim2.new(0.7, 0, 0, PANEL_HEIGHT_MAX),
	Position = UDim2.new(0.15, 0, 1, -PANEL_HEIGHT_MAX - 10),
	BackgroundColor3 = Color3.fromRGB(20, 20, 25),
	BackgroundTransparency = 0.2,
	BorderSizePixel = 0,
	ZIndex = 10
}, flyGui)
createElement("UICorner", {CornerRadius = UDim.new(0, 18)}, panel)

-- Panel Stroke
local stroke = createElement("UIStroke", {
	Color = Color3.fromRGB(80, 80, 100),
	Thickness = 1,
	Transparency = 0.5
}, panel)

------------------------------
-- FLY TOGGLE (im Panel, links)
------------------------------
local flyToggle = createElement("TextButton", {
	Name = "FlyToggle",
	Size = UDim2.new(0, 75, 0, 65),
	Position = UDim2.new(0, 12, 0.5, -32),
	BackgroundColor3 = Color3.fromRGB(200, 50, 50),
	Text = "FLY\nOFF",
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	TextColor3 = Color3.new(1, 1, 1),
	BorderSizePixel = 0,
	ZIndex = 11
}, panel)
createElement("UICorner", {CornerRadius = UDim.new(0, 14)}, flyToggle)

------------------------------
-- SPEED SLIDER (im Panel, Mitte)
------------------------------
local sliderLabel = createElement("TextLabel", {
	Name = "SliderLabel",
	Size = UDim2.new(0, 60, 0, 20),
	Position = UDim2.new(0.5, -100, 0, 6),
	BackgroundTransparency = 1,
	Text = "SPEED",
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	TextColor3 = Color3.fromRGB(180, 180, 210),
	ZIndex = 11
}, panel)

local sliderTrack = createElement("Frame", {
	Name = "SliderTrack",
	Size = UDim2.new(0, 190, 0, 8),
	Position = UDim2.new(0.5, -95, 0.5, 8),
	BackgroundColor3 = Color3.fromRGB(60, 60, 75),
	BorderSizePixel = 0,
	ZIndex = 11
}, panel)
createElement("UICorner", {CornerRadius = UDim.new(1, 0)}, sliderTrack)

local sliderFill = createElement("Frame", {
	Name = "SliderFill",
	Size = UDim2.new(0.5, 0, 1, 0),
	Position = UDim2.new(0, 0, 0, 0),
	BackgroundColor3 = Color3.fromRGB(100, 160, 255),
	BorderSizePixel = 0,
	ZIndex = 12
}, sliderTrack)
createElement("UICorner", {CornerRadius = UDim.new(1, 0)}, sliderFill)

local sliderKnob = createElement("Frame", {
	Name = "SliderKnob",
	Size = UDim2.new(0, 28, 0, 28),
	Position = UDim2.new(0.5, -14, 0.5, -14),
	BackgroundColor3 = Color3.fromRGB(220, 230, 255),
	BorderSizePixel = 0,
	ZIndex = 13
}, sliderTrack)
createElement("UICorner", {CornerRadius = UDim.new(1, 0)}, sliderKnob)

local speedValueLabel = createElement("TextLabel", {
	Name = "SpeedValue",
	Size = UDim2.new(0, 40, 0, 20),
	Position = UDim2.new(0.5, 100, 0, 6),
	BackgroundTransparency = 1,
	Text = tostring(flightSpeed),
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	TextColor3 = Color3.fromRGB(220, 230, 255),
	ZIndex = 11
}, panel)

------------------------------
-- MINIMIZE BUTTON (im Panel, oben Mitte)
------------------------------
local minimizeBtn = createElement("TextButton", {
	Name = "MinimizeBtn",
	Size = UDim2.new(0, 40, 0, 22),
	Position = UDim2.new(0.5, -20, 0, -14),
	BackgroundColor3 = Color3.fromRGB(50, 50, 65),
	Text = "▼",
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	TextColor3 = Color3.fromRGB(180, 180, 210),
	BorderSizePixel = 0,
	ZIndex = 15
}, panel)
createElement("UICorner", {CornerRadius = UDim.new(0, 8)}, minimizeBtn)

------------------------------
-- CLOSE BUTTON (im Panel, rechts)
------------------------------
local closeBtn = createElement("TextButton", {
	Name = "CloseBtn",
	Size = UDim2.new(0, 36, 0, 36),
	Position = UDim2.new(1, -48, 0.5, -18),
	BackgroundColor3 = Color3.fromRGB(180, 40, 40),
	Text = "✕",
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	TextColor3 = Color3.new(1, 1, 1),
	BorderSizePixel = 0,
	ZIndex = 11
}, panel)
createElement("UICorner", {CornerRadius = UDim.new(1, 0)}, closeBtn)

------------------------------
-- MINI FLY BUTTON (nur sichtbar wenn minimiert)
------------------------------
local miniFlyBtn = createElement("TextButton", {
	Name = "MiniFlyBtn",
	Size = UDim2.new(0, 60, 0, 34),
	Position = UDim2.new(0.5, -30, 0.5, -17),
	BackgroundColor3 = Color3.fromRGB(200, 50, 50),
	Text = "FLY OFF",
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	TextColor3 = Color3.new(1, 1, 1),
	BorderSizePixel = 0,
	ZIndex = 11,
	Visible = false
}, panel)
createElement("UICorner", {CornerRadius = UDim.new(0, 10)}, miniFlyBtn)

------------------------------
-- JOYSTICK (unten links)
------------------------------
local joystickBG = createElement("Frame", {
	Name = "JoystickBG",
	Size = UDim2.new(0, 140, 0, 140),
	Position = UDim2.new(0, 30, 1, -175),
	BackgroundColor3 = Color3.fromRGB(30, 30, 40),
	BackgroundTransparency = 0.3,
	BorderSizePixel = 0,
	ZIndex = 8
}, flyGui)
createElement("UICorner", {CornerRadius = UDim.new(1, 0)}, joystickBG)
createElement("UIStroke", {Color = Color3.fromRGB(80, 80, 120), Thickness = 2, Transparency = 0.4}, joystickBG)

local joystickKnob = createElement("Frame", {
	Name = "JoystickKnob",
	Size = UDim2.new(0, 60, 0, 60),
	Position = UDim2.new(0.5, -30, 0.5, -30),
	BackgroundColor3 = Color3.fromRGB(120, 150, 255),
	BackgroundTransparency = 0.1,
	BorderSizePixel = 0,
	ZIndex = 9
}, joystickBG)
createElement("UICorner", {CornerRadius = UDim.new(1, 0)}, joystickKnob)

------------------------------
-- HÖHENBUTTONS (unten rechts)
------------------------------
local heightContainer = createElement("Frame", {
	Name = "HeightContainer",
	Size = UDim2.new(0, 70, 0, 150),
	Position = UDim2.new(1, -100, 1, -175),
	BackgroundTransparency = 1,
	ZIndex = 8
}, flyGui)

local upBtn = createElement("TextButton", {
	Name = "UpBtn",
	Size = UDim2.new(1, 0, 0, 65),
	Position = UDim2.new(0, 0, 0, 0),
	BackgroundColor3 = Color3.fromRGB(30, 30, 40),
	BackgroundTransparency = 0.3,
	Text = "▲",
	Font = Enum.Font.GothamBold,
	TextSize = 26,
	TextColor3 = Color3.fromRGB(160, 200, 255),
	BorderSizePixel = 0,
	ZIndex = 9
}, heightContainer)
createElement("UICorner", {CornerRadius = UDim.new(0, 18)}, upBtn)
createElement("UIStroke", {Color = Color3.fromRGB(80, 80, 120), Thickness = 2, Transparency = 0.4}, upBtn)

local downBtn = createElement("TextButton", {
	Name = "DownBtn",
	Size = UDim2.new(1, 0, 0, 65),
	Position = UDim2.new(0, 0, 1, -65),
	BackgroundColor3 = Color3.fromRGB(30, 30, 40),
	BackgroundTransparency = 0.3,
	Text = "▼",
	Font = Enum.Font.GothamBold,
	TextSize = 26,
	TextColor3 = Color3.fromRGB(160, 200, 255),
	BorderSizePixel = 0,
	ZIndex = 9
}, heightContainer)
createElement("UICorner", {CornerRadius = UDim.new(0, 18)}, downBtn)
createElement("UIStroke", {Color = Color3.fromRGB(80, 80, 120), Thickness = 2, Transparency = 0.4}, downBtn)

------------------------------
-- ALLE TOUCH-UI ELEMENTE (für Minimize)
------------------------------
local touchElements = {joystickBG, heightContainer}
local panelElements = {flyToggle, sliderLabel, sliderTrack, speedValueLabel, closeBtn}

------------------------------
-- MINIMIZE / MAXIMIZE
------------------------------
local PANEL_Y_MAX = UDim2.new(0.15, 0, 1, -PANEL_HEIGHT_MAX - 10)
local PANEL_Y_MIN = UDim2.new(0.15, 0, 1, -PANEL_HEIGHT_MIN - 10)

local function setMinimized(state)
	isMinimized = state
	local tweenTime = 0.35
	local tweenStyle = Enum.EasingStyle.Quint
	local tweenDir = Enum.EasingDirection.Out

	if state then
		-- Minimieren
		minimizeBtn.Text = "▲"
		-- Panel runterfahren
		quickTween(panel, {Position = PANEL_Y_MIN, Size = UDim2.new(0.7, 0, 0, PANEL_HEIGHT_MIN)}, tweenTime, tweenStyle, tweenDir)
		-- Panel-Elemente ausblenden
		for _, el in ipairs(panelElements) do
			quickTween(el, {BackgroundTransparency = 1, TextTransparency = 1}, 0.2)
		end
		quickTween(sliderFill, {BackgroundTransparency = 1}, 0.2)
		quickTween(sliderKnob, {BackgroundTransparency = 1}, 0.2)
		-- Joystick & Höhenbuttons ausblenden
		for _, el in ipairs(touchElements) do
			quickTween(el, {BackgroundTransparency = 1}, 0.2)
		end
		quickTween(joystickKnob, {BackgroundTransparency = 1}, 0.2)
		quickTween(upBtn, {BackgroundTransparency = 1, TextTransparency = 1}, 0.2)
		quickTween(downBtn, {BackgroundTransparency = 1, TextTransparency = 1}, 0.2)
		-- Mini-Button einblenden
		task.delay(0.15, function()
			miniFlyBtn.Visible = true
			quickTween(miniFlyBtn, {BackgroundTransparency = 0}, 0.2)
		end)
		-- Interaktivität deaktivieren
		joystickBG.Active = false
		upBtn.Active = false
		downBtn.Active = false
		-- Joystick zurücksetzen
		joystickInput = Vector2.new(0, 0)
		joystickKnob.Position = UDim2.new(0.5, -30, 0.5, -30)
		joystickTouchId = nil
		heightInput = 0
		heightUpTouchId = nil
		heightDownTouchId = nil
	else
		-- Maximieren
		minimizeBtn.Text = "▼"
		miniFlyBtn.Visible = false
		-- Panel hochfahren
		quickTween(panel, {Position = PANEL_Y_MAX, Size = UDim2.new(0.7, 0, 0, PANEL_HEIGHT_MAX)}, tweenTime, tweenStyle, tweenDir)
		-- Panel-Elemente einblenden
		for _, el in ipairs(panelElements) do
			quickTween(el, {BackgroundTransparency = 0, TextTransparency = 0}, 0.25)
		end
		quickTween(sliderFill, {BackgroundTransparency = 0}, 0.25)
		quickTween(sliderKnob, {BackgroundTransparency = 0}, 0.25)
		-- Joystick & Höhenbuttons einblenden
		quickTween(joystickBG, {BackgroundTransparency = 0.3}, 0.25)
		quickTween(joystickKnob, {BackgroundTransparency = 0.1}, 0.25)
		quickTween(upBtn, {BackgroundTransparency = 0.3, TextTransparency = 0}, 0.25)
		quickTween(downBtn, {BackgroundTransparency = 0.3, TextTransparency = 0}, 0.25)
		-- Interaktivität aktivieren
		joystickBG.Active = true
		upBtn.Active = true
		downBtn.Active = true
	end
end

minimizeBtn.MouseButton1Click:Connect(function()
	setMinimized(not isMinimized)
end)

------------------------------
-- SLIDER LOGIK (Touch-safe)
------------------------------
local MIN_SPEED = 10
local MAX_SPEED = 200

local function updateSliderFromX(absX)
	local trackPos = sliderTrack.AbsolutePosition.X
	local trackSize = sliderTrack.AbsoluteSize.X
	local rel = math.clamp((absX - trackPos) / trackSize, 0, 1)
	flightSpeed = math.floor(MIN_SPEED + rel * (MAX_SPEED - MIN_SPEED))
	speedValueLabel.Text = tostring(flightSpeed)
	sliderFill.Size = UDim2.new(rel, 0, 1, 0)
	sliderKnob.Position = UDim2.new(rel, -14, 0.5, -14)
end

-- Initialer Slider-Zustand (50/200 = 0.2)
local initRel = (flightSpeed - MIN_SPEED) / (MAX_SPEED - MIN_SPEED)
sliderFill.Size = UDim2.new(initRel, 0, 1, 0)
sliderKnob.Position = UDim2.new(initRel, -14, 0.5, -14)

sliderTrack.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		if sliderTouchId == nil then
			sliderTouchId = input
			updateSliderFromX(input.Position.X)
		end
	end
end)

-- Global InputChanged: nur wenn sliderTouchId aktiv
UserInputService.InputChanged:Connect(function(input)
	if sliderTouchId and input == sliderTouchId then
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
			updateSliderFromX(input.Position.X)
		end
	end
end)

-- Global InputEnded: Slider sicher beenden (egal wo der Finger loslässt)
UserInputService.InputEnded:Connect(function(input)
	if sliderTouchId and input == sliderTouchId then
		sliderTouchId = nil
	end
end)

------------------------------
-- JOYSTICK LOGIK (Touch-safe)
------------------------------
local JOYSTICK_RADIUS = 70   -- Hälfte von 140
local KNOB_HALF = 30         -- Hälfte von 60

joystickBG.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		if joystickTouchId == nil and not isMinimized then
			joystickTouchId = input
			local bgAbs = joystickBG.AbsolutePosition
			local bgSize = joystickBG.AbsoluteSize
			local center = Vector2.new(bgAbs.X + bgSize.X / 2, bgAbs.Y + bgSize.Y / 2)
			local offset = Vector2.new(input.Position.X - center.X, input.Position.Y - center.Y)
			local mag = offset.Magnitude
			if mag > JOYSTICK_RADIUS then
				offset = offset.Unit * JOYSTICK_RADIUS
			end
			joystickKnob.Position = UDim2.new(0.5, offset.X - KNOB_HALF, 0.5, offset.Y - KNOB_HALF)
			joystickInput = Vector2.new(offset.X / JOYSTICK_RADIUS, -offset.Y / JOYSTICK_RADIUS)
		end
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if joystickTouchId and input == joystickTouchId then
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
			local bgAbs = joystickBG.AbsolutePosition
			local bgSize = joystickBG.AbsoluteSize
			local center = Vector2.new(bgAbs.X + bgSize.X / 2, bgAbs.Y + bgSize.Y / 2)
			local offset = Vector2.new(input.Position.X - center.X, input.Position.Y - center.Y)
			local mag = offset.Magnitude
			if mag > JOYSTICK_RADIUS then
				offset = offset.Unit * JOYSTICK_RADIUS
			end
			joystickKnob.Position = UDim2.new(0.5, offset.X - KNOB_HALF, 0.5, offset.Y - KNOB_HALF)
			joystickInput = Vector2.new(offset.X / JOYSTICK_RADIUS, -offset.Y / JOYSTICK_RADIUS)
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if joystickTouchId and input == joystickTouchId then
		joystickTouchId = nil
		joystickInput = Vector2.new(0, 0)
		quickTween(joystickKnob, {Position = UDim2.new(0.5, -KNOB_HALF, 0.5, -KNOB_HALF)}, 0.15)
	end
end)

-- Fallback: Joystick-Identifier prüfen (verhindert "hängen" wenn Touch nicht sauber endet)
RunService.Heartbeat:Connect(function()
	if joystickTouchId then
		local stillActive = false
		for _, inp in ipairs(UserInputService:GetTouchState()) do
			if inp == joystickTouchId then
				stillActive = true
				break
			end
		end
		if not stillActive then
			joystickTouchId = nil
			joystickInput = Vector2.new(0, 0)
			joystickKnob.Position = UDim2.new(0.5, -KNOB_HALF, 0.5, -KNOB_HALF)
		end
	end
end)

------------------------------
-- HÖHENBUTTONS LOGIK (Touch-safe)
------------------------------
upBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		if heightUpTouchId == nil and not isMinimized then
			heightUpTouchId = input
			heightInput = 1
			quickTween(upBtn, {Size = UDim2.new(0.9, 0, 0, 60)}, 0.1)
		end
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if heightUpTouchId and input == heightUpTouchId then
		heightUpTouchId = nil
		if heightDownTouchId == nil then heightInput = 0 end
		quickTween(upBtn, {Size = UDim2.new(1, 0, 0, 65)}, 0.1)
	end
end)

downBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		if heightDownTouchId == nil and not isMinimized then
			heightDownTouchId = input
			heightInput = -1
			quickTween(downBtn, {Size = UDim2.new(0.9, 0, 0, 60)}, 0.1)
		end
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if heightDownTouchId and input == heightDownTouchId then
		heightDownTouchId = nil
		if heightUpTouchId == nil then heightInput = 0 end
		quickTween(downBtn, {Size = UDim2.new(1, 0, 0, 65)}, 0.1)
	end
end)

------------------------------
-- FLUGMODUS STARTEN / BEENDEN
------------------------------
local function startFlight()
	if isFlying then return end
	isFlying = true

	-- Toggle-Buttons updaten
	flyToggle.Text = "FLY\nON"
	quickTween(flyToggle, {BackgroundColor3 = Color3.fromRGB(60, 210, 100)}, 0.3)
	miniFlyBtn.Text = "FLY ON"
	quickTween(miniFlyBtn, {BackgroundColor3 = Color3.fromRGB(60, 210, 100)}, 0.3)

	Workspace.Gravity = 0
	humanoid.PlatformStand = true
	playAnimation(10714347256, 4, 0)

	local gyro = Instance.new("BodyGyro")
	gyro.Name = "FlyGyro"
	gyro.Parent = hrp
	gyro.P = 90000
	gyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
	gyro.CFrame = hrp.CFrame

	local bv = Instance.new("BodyVelocity")
	bv.Name = "FlyVelocity"
	bv.Parent = hrp
	bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
	bv.Velocity = Vector3.new(0, 0.1, 0)

	currentVelocity = Vector3.new(0, 0, 0)
	currentCF = nil

	local flightUpdate = RunService.RenderStepped:Connect(function(dt)
		local cam = Workspace.CurrentCamera
		local fwd = joystickInput.Y
		local side = joystickInput.X

		local inputVec = (cam.CFrame.LookVector * fwd) + (cam.CFrame.RightVector * side)
		if fwd ~= 0 then
			inputVec = inputVec + Vector3.new(0, 0.1 * fwd, 0)
		end

		-- Höhe durch dedizierte Buttons
		local heightVec = Vector3.new(0, heightInput * flightSpeed * 0.6, 0)

		local desiredVelocity
		if inputVec.Magnitude > 0 or heightInput ~= 0 then
			local moveVec = Vector3.new(0, 0, 0)
			if inputVec.Magnitude > 0 then
				moveVec = inputVec.Unit * flightSpeed
			end
			desiredVelocity = moveVec + heightVec
		else
			-- Bobbing im Schwebezustand
			local bobbing = math.sin(tick() * bobbingFrequency) * bobbingAmplitude
			desiredVelocity = Vector3.new(0, bobbing, 0)
		end

		currentVelocity = currentVelocity:Lerp(desiredVelocity, 0.1)
		bv.Velocity = currentVelocity

		-- Rotation
		local desiredCF
		if fwd > 0.1 then
			desiredCF = cam.CFrame * CFrame.Angles(math.rad(-85), 0, math.rad(currentRoll))
		elseif fwd < -0.1 then
			desiredCF = cam.CFrame * CFrame.Angles(math.rad(30), 0, math.rad(currentRoll))
		else
			desiredCF = cam.CFrame * CFrame.Angles(math.rad(-10), 0, math.rad(currentRoll))
		end

		-- Roll bei seitlicher Bewegung
		local targetRoll = -side * maxRoll
		currentRoll = currentRoll + (targetRoll - currentRoll) * 0.1

		if currentCF then
			currentCF = currentCF:Lerp(desiredCF, lerpCoef)
		else
			currentCF = desiredCF
		end
		gyro.CFrame = currentCF

		-- Animation basierend auf Joystick
		-- (nur bei Zustandswechsel, nicht jeden Frame)
	end)
	table.insert(flightConns, flightUpdate)
end

local function stopFlight()
	if not isFlying then return end
	isFlying = false

	flyToggle.Text = "FLY\nOFF"
	quickTween(flyToggle, {BackgroundColor3 = Color3.fromRGB(200, 50, 50)}, 0.3)
	miniFlyBtn.Text = "FLY OFF"
	quickTween(miniFlyBtn, {BackgroundColor3 = Color3.fromRGB(200, 50, 50)}, 0.3)

	Workspace.Gravity = originalGravity
	humanoid.PlatformStand = false
	stopAnimation()
	if hrp:FindFirstChild("FlyGyro") then hrp.FlyGyro:Destroy() end
	if hrp:FindFirstChild("FlyVelocity") then hrp.FlyVelocity:Destroy() end

	for _, conn in ipairs(flightConns) do
		if conn.Connected then conn:Disconnect() end
	end
	flightConns = {}

	joystickInput = Vector2.new(0, 0)
	joystickKnob.Position = UDim2.new(0.5, -KNOB_HALF, 0.5, -KNOB_HALF)
	joystickTouchId = nil
	heightInput = 0
	heightUpTouchId = nil
	heightDownTouchId = nil
	currentVelocity = Vector3.new(0, 0, 0)
	currentCF = nil
end

------------------------------
-- TOGGLE BUTTONS
------------------------------
flyToggle.MouseButton1Click:Connect(function()
	if isFlying then stopFlight() else startFlight() end
end)

miniFlyBtn.MouseButton1Click:Connect(function()
	if isFlying then stopFlight() else startFlight() end
end)

------------------------------
-- PANEL DRAG (Touch-safe, global tracking)
------------------------------
local dragActive = false
local dragStartPanelPos = nil
local dragStartTouchPos = nil

panel.InputBegan:Connect(function(input)
	-- Nur starten wenn kein anderes Element getroffen wurde
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		if dragTouchId == nil then
			dragTouchId = input
			dragActive = true
			dragStartPanelPos = panel.Position
			dragStartTouchPos = Vector2.new(input.Position.X, input.Position.Y)
		end
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragActive and dragTouchId and input == dragTouchId then
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStartTouchPos
			panel.Position = UDim2.new(
				dragStartPanelPos.X.Scale,
				dragStartPanelPos.X.Offset + delta.X,
				dragStartPanelPos.Y.Scale,
				dragStartPanelPos.Y.Offset + delta.Y
			)
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if dragTouchId and input == dragTouchId then
		dragActive = false
		dragTouchId = nil
	end
end)

------------------------------
-- CLOSE BUTTON
------------------------------
closeBtn.MouseButton1Click:Connect(function()
	stopFlight()
	flyGui:Destroy()
	script:Destroy()
end)

------------------------------
-- CHARACTER RELOAD
------------------------------
player.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoid = character:WaitForChild("Humanoid")
	hrp = character:WaitForChild("HumanoidRootPart")
	if isFlying then
		isFlying = false
		flyToggle.Text = "FLY\nOFF"
		quickTween(flyToggle, {BackgroundColor3 = Color3.fromRGB(200, 50, 50)}, 0.3)
		miniFlyBtn.Text = "FLY OFF"
		Workspace.Gravity = originalGravity
		humanoid.PlatformStand = false
		stopAnimation()
		if hrp:FindFirstChild("FlyGyro") then hrp.FlyGyro:Destroy() end
		if hrp:FindFirstChild("FlyVelocity") then hrp.FlyVelocity:Destroy() end
		for _, conn in ipairs(flightConns) do
			if conn.Connected then conn:Disconnect() end
		end
		flightConns = {}
		joystickInput = Vector2.new(0, 0)
		joystickTouchId = nil
		heightInput = 0
		currentVelocity = Vector3.new(0, 0, 0)
	end
end)

-- Keyboard-Support (optional, für PC-Nutzer die das Script auch benutzen)
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.X then
		if isFlying then stopFlight() else startFlight() end
	end
end)
