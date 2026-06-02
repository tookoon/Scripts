

-- // ============================================================
-- // 1. SERVICES & CONSTANTS
-- // ============================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Z-Index Schichten (nur noch Base-Layer dank Sibling Behavior)
local Z_DOCK = 10
local Z_WINDOW = 20
local Z_NOTIFICATION = 200

-- Globaler Z-Counter fuer Fenster-Fokus (inkrementiert bei Klick)
local topZIndex = Z_WINDOW

-- Tween Infos (Optimiert)
local TWEEN_FAST = TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local TWEEN_NORMAL = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_ROLLUP = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TWEEN_BOUNCE = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- Minimale Fenstergroessen
local MIN_WINDOW_WIDTH = 300
local MIN_WINDOW_HEIGHT = 200
local TOPBAR_HEIGHT = 42

-- Schriftarten
local FONT = Enum.Font.Gotham
local FONT_BOLD = Enum.Font.GothamBold
local FONT_MEDIUM = Enum.Font.GothamMedium

-- Max Apps im Dock
local MAX_DOCK_APPS = 8

-- // ============================================================
-- // 2. ICON BUILDER (Frame-basiert, 100% Roblox-kompatibel)
-- // ============================================================

local function CreateCorner(parent: GuiObject, radius: UDim): UICorner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius
	corner.Parent = parent
	return corner
end

local function BuildIcon(parent: GuiObject, iconKey: string, size: number, color: Color3): Frame
	local container = Instance.new("Frame")
	container.Name = "Icon_" .. iconKey
	container.Size = UDim2.new(0, size, 0, size)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.ZIndex = parent.ZIndex + 1
	container.Parent = parent

	local function bar(x: number, y: number, w: number, h: number, rot: number?): Frame
		local f = Instance.new("Frame")
		f.Size = UDim2.new(0, w, 0, h)
		f.Position = UDim2.new(0, x, 0, y)
		f.BackgroundColor3 = color
		f.BorderSizePixel = 0
		f.Rotation = rot or 0
		f.ZIndex = container.ZIndex
		f.Parent = container
		return f
	end

	local function dot(x: number, y: number, s: number): Frame
		local f = bar(x, y, s, s)
		CreateCorner(f, UDim.new(1, 0))
		return f
	end

	if iconKey == "grid" then
		local s = math.floor(size * 0.38)
		local g = math.floor(size * 0.08)
		local off = s + g
		local margin = math.floor((size - s * 2 - g) / 2)
		for r = 0, 1 do
			for c = 0, 1 do
				local sq = bar(margin + c * off, margin + r * off, s, s)
				CreateCorner(sq, UDim.new(0, 3))
			end
		end

	elseif iconKey == "layout" then
		local m = math.floor(size * 0.15)
		local inner = size - m * 2
		local outline = bar(m, m, inner, inner)
		outline.BackgroundTransparency = 1
		CreateCorner(outline, UDim.new(0, 3))
		local stroke = Instance.new("UIStroke")
		stroke.Color = color
		stroke.Thickness = 2
		stroke.Parent = outline
		bar(m, m + math.floor(inner * 0.35), inner, 2)
		bar(m + math.floor(inner * 0.4), m + math.floor(inner * 0.35), 2, math.floor(inner * 0.65))

	elseif iconKey == "lines" then
		local m = math.floor(size * 0.2)
		local w = size - m * 2
		local h = math.max(2, math.floor(size * 0.08))
		local gap = math.floor((size - m * 2 - h * 3) / 2)
		for i = 0, 2 do
			local b = bar(m, m + i * (h + gap), w, h)
			CreateCorner(b, UDim.new(0, 1))
		end

	elseif iconKey == "diamond" then
		local s = math.floor(size * 0.45)
		local cx = math.floor(size / 2 - s / 2)
		local f = bar(cx, cx, s, s, 45)
		CreateCorner(f, UDim.new(0, 3))

	elseif iconKey == "gear" then
		local cs = math.floor(size * 0.35)
		local cm = math.floor(size / 2 - cs / 2)
		dot(cm, cm, cs)
		local inner = dot(math.floor(size/2 - cs*0.3), math.floor(size/2 - cs*0.3), math.floor(cs*0.6))
		inner.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		inner.BackgroundTransparency = 0.7
		local tw = math.max(2, math.floor(size * 0.12))
		local th = math.floor(size * 0.2)
		local center = math.floor(size / 2)
		bar(center - tw/2, math.floor(size*0.08), tw, th)
		bar(center - tw/2, size - math.floor(size*0.08) - th, tw, th)
		bar(math.floor(size*0.08), center - tw/2, th, tw)
		bar(size - math.floor(size*0.08) - th, center - tw/2, th, tw)

	elseif iconKey == "move" then
		local tw = math.max(2, math.floor(size * 0.15))
		local center = math.floor(size / 2)
		local m = math.floor(size * 0.15)
		bar(center - tw/2, m, tw, size - m*2)
		bar(m, center - tw/2, size - m*2, tw)
		local arrowS = math.floor(size * 0.12)
		dot(center - arrowS/2, m - arrowS/3, arrowS)
		dot(center - arrowS/2, size - m - arrowS*2/3, arrowS)
		dot(m - arrowS/3, center - arrowS/2, arrowS)
		dot(size - m - arrowS*2/3, center - arrowS/2, arrowS)

	elseif iconKey == "rotate" then
		local cs = math.floor(size * 0.55)
		local cm = math.floor(size / 2 - cs / 2)
		local ring = dot(cm, cm, cs)
		ring.BackgroundTransparency = 1
		local stroke = Instance.new("UIStroke")
		stroke.Color = color
		stroke.Thickness = math.max(2, math.floor(size * 0.1))
		stroke.Parent = ring
		local arrowS = math.floor(size * 0.18)
		bar(math.floor(size*0.65), math.floor(size*0.18), arrowS, arrowS, 45)

	elseif iconKey == "chevron" then
		local center = math.floor(size / 2)
		local len = math.floor(size * 0.35)
		local thick = math.max(2, math.floor(size * 0.12))
		bar(center - len + thick/2, center - thick, len, thick, 45)
		bar(center - thick/2, center - thick, len, thick, -45)

	elseif iconKey == "close" then
		local m = math.floor(size * 0.22)
		local len = size - m * 2
		local thick = math.max(2, math.floor(size * 0.12))
		local cx = math.floor(size/2 - len/2)
		local cy = math.floor(size/2 - thick/2)
		bar(cx, cy, len, thick, 45)
		bar(cx, cy, len, thick, -45)

	elseif iconKey == "minimize" then
		local m = math.floor(size * 0.2)
		local thick = math.max(2, math.floor(size * 0.12))
		bar(m, math.floor(size/2 - thick/2), size - m*2, thick)

	elseif iconKey == "pin" then
		local s = math.floor(size * 0.5)
		dot(math.floor(size/2 - s/2), math.floor(size/2 - s/2), s)
	end

	return container
end

-- // ============================================================
-- // 3. THEME ENGINE
-- // ============================================================

local Themes = {
	light = {
		Name = "Clean Light",
		BgPrimary       = Color3.fromHex("#F9FAFB"),
		BgSecondary     = Color3.fromHex("#F3F4F6"),
		BgTertiary      = Color3.fromHex("#E5E7EB"),
		BgSurface       = Color3.fromHex("#FFFFFF"),
		BgDock          = Color3.fromHex("#FFFFFF"),
		AccentPrimary   = Color3.fromHex("#3B82F6"),
		TextPrimary     = Color3.fromHex("#111827"),
		TextSecondary   = Color3.fromHex("#374151"),
		TextTertiary    = Color3.fromHex("#6B7280"),
		BorderColor     = Color3.fromHex("#E5E7EB"),
		BorderActive    = Color3.fromHex("#93C5FD"),
		SurfaceTransparency = 0.05,
		DockTransparency    = 0.1,
	},
	dark = {
		Name = "Modern Dark",
		BgPrimary       = Color3.fromHex("#121212"),
		BgSecondary     = Color3.fromHex("#18181B"),
		BgTertiary      = Color3.fromHex("#27272A"),
		BgSurface       = Color3.fromHex("#18181B"),
		BgDock          = Color3.fromHex("#121212"),
		AccentPrimary   = Color3.fromHex("#6366F1"),
		TextPrimary     = Color3.fromHex("#FAFAFA"),
		TextSecondary   = Color3.fromHex("#A1A1AA"),
		TextTertiary    = Color3.fromHex("#71717A"),
		BorderColor     = Color3.fromHex("#3F3F46"),
		BorderActive    = Color3.fromHex("#4F46E5"),
		SurfaceTransparency = 0.05,
		DockTransparency    = 0.15,
	},
}

local currentThemeId = "dark"
local currentTheme = Themes.dark

local themedElements: { { Instance: Instance, Map: { [string]: string } } } = {}

local function RegisterThemed(instance: Instance, propertyMap: { [string]: string })
	table.insert(themedElements, { Instance = instance, Map = propertyMap })
end

local function ApplyTheme(themeId: string, animate: boolean)
	local theme = Themes[themeId]
	if not theme then return end
	currentThemeId = themeId
	currentTheme = theme

	for i = #themedElements, 1, -1 do
		local entry = themedElements[i]
		if entry.Instance and entry.Instance.Parent then
			local goals = {}
			for prop, themeKey in pairs(entry.Map) do
				local value = (theme :: any)[themeKey]
				if value then
					if animate then
						goals[prop] = value
					else
						(entry.Instance :: any)[prop] = value
					end
				end
			end
			if animate and next(goals) then
				TweenService:Create(entry.Instance, TWEEN_NORMAL, goals):Play()
			end
		else
			table.remove(themedElements, i)
		end
	end
end

-- // ============================================================
-- // 4. UTILITY FUNCTIONS
-- // ============================================================

local function BringToFront(guiObject: GuiObject)
	topZIndex += 1
	guiObject.ZIndex = topZIndex
end

local function CreatePadding(parent: GuiObject, top: number?, bottom: number?, left: number?, right: number?): UIPadding
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, top or 0)
	padding.PaddingBottom = UDim.new(0, bottom or 0)
	padding.PaddingLeft = UDim.new(0, left or 0)
	padding.PaddingRight = UDim.new(0, right or 0)
	padding.Parent = parent
	return padding
end

local function CreateStroke(parent: GuiObject, color: Color3, thickness: number?, transparency: number?): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	RegisterThemed(stroke, { Color = "BorderColor" })
	return stroke
end

local function CreateListLayout(parent: GuiObject, direction: Enum.FillDirection, gap: number?, hAlign: Enum.HorizontalAlignment?, vAlign: Enum.VerticalAlignment?): UIListLayout
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = direction
	layout.Padding = UDim.new(0, gap or 0)
	layout.HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left
	layout.VerticalAlignment = vAlign or Enum.VerticalAlignment.Top
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = parent
	return layout
end

local function CreateGridLayout(parent: GuiObject, cellSize: UDim2, cellPadding: UDim2?): UIGridLayout
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = cellSize
	grid.CellPadding = cellPadding or UDim2.new(0, 10, 0, 10)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = parent
	return grid
end

local function GetViewportSize(): Vector2
	local camera = workspace.CurrentCamera
	return if camera then camera.ViewportSize else Vector2.new(1920, 1080)
end

-- // ============================================================
-- // 5. SCREENGUI SETUP
-- // ============================================================

local existingGui = PlayerGui:FindFirstChild("AstraUI")
if existingGui then existingGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AstraUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling 
screenGui.IgnoreGuiInset = false  
screenGui.Parent = PlayerGui

local desktop = Instance.new("Frame")
desktop.Name = "Desktop"
desktop.Size = UDim2.new(1, 0, 1, 0)
desktop.BackgroundTransparency = 1
desktop.BorderSizePixel = 0
desktop.Parent = screenGui

local topbar = Instance.new("Frame")
topbar.Name = "Topbar"
topbar.Size = UDim2.new(1, 0, 0, 32)
topbar.Position = UDim2.new(0, 0, 0, 0)
topbar.BackgroundColor3 = Color3.fromHex("#000000")
topbar.BackgroundTransparency = 0.6
topbar.BorderSizePixel = 0
topbar.ZIndex = Z_DOCK + 50
topbar.Parent = screenGui

local topbarBorder = Instance.new("Frame")
topbarBorder.Name = "Border"
topbarBorder.Size = UDim2.new(1, 0, 0, 1)
topbarBorder.Position = UDim2.new(0, 0, 1, -1)
topbarBorder.BackgroundColor3 = currentTheme.BorderColor
topbarBorder.BorderSizePixel = 0
topbarBorder.Parent = topbar
RegisterThemed(topbarBorder, { BackgroundColor3 = "BorderColor" })

local topbarLogo = Instance.new("TextLabel")
topbarLogo.Name = "Logo"
topbarLogo.Size = UDim2.new(0, 140, 1, 0)
topbarLogo.Position = UDim2.new(0, 16, 0, 0)
topbarLogo.BackgroundTransparency = 1
topbarLogo.Text = "AstraUI"
topbarLogo.TextColor3 = currentTheme.AccentPrimary
topbarLogo.Font = FONT_BOLD
topbarLogo.TextSize = 14
topbarLogo.TextXAlignment = Enum.TextXAlignment.Left
topbarLogo.Parent = topbar
RegisterThemed(topbarLogo, { TextColor3 = "AccentPrimary" })

local topbarClock = Instance.new("TextLabel")
topbarClock.Name = "Clock"
topbarClock.Size = UDim2.new(0, 60, 1, 0)
topbarClock.Position = UDim2.new(1, -76, 0, 0)
topbarClock.BackgroundTransparency = 1
topbarClock.Text = "00:00"
topbarClock.TextColor3 = currentTheme.TextSecondary
topbarClock.Font = FONT
topbarClock.TextSize = 12
topbarClock.TextXAlignment = Enum.TextXAlignment.Right
topbarClock.Parent = topbar
RegisterThemed(topbarClock, { TextColor3 = "TextSecondary" })

task.spawn(function()
	while true do
		local now = os.date("*t")
		topbarClock.Text = string.format("%02d:%02d", now.hour, now.min)
		task.wait(1)
	end
end)

-- // ============================================================
-- // 6. NOTIFICATION SYSTEM
-- // ============================================================

local notifContainer = Instance.new("Frame")
notifContainer.Name = "Notifications"
notifContainer.Size = UDim2.new(0, 260, 1, -48)
notifContainer.Position = UDim2.new(1, -276, 0, 40)
notifContainer.BackgroundTransparency = 1
notifContainer.BorderSizePixel = 0
notifContainer.ZIndex = Z_NOTIFICATION
notifContainer.Parent = screenGui
CreateListLayout(notifContainer, Enum.FillDirection.Vertical, 8, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Top)

local function Notify(text: string)
	local wrapper = Instance.new("Frame")
	wrapper.Size = UDim2.new(1, 0, 0, 36)
	wrapper.BackgroundTransparency = 1
	wrapper.ClipsDescendants = true
	wrapper.Parent = notifContainer

	local toast = Instance.new("Frame")
	toast.Name = "Toast"
	toast.Size = UDim2.new(1, 0, 1, 0)
	toast.BackgroundColor3 = currentTheme.BgSecondary
	toast.BackgroundTransparency = 0.1
	toast.BorderSizePixel = 0
	toast.Position = UDim2.new(1.5, 0, 0, 0)
	toast.ZIndex = Z_NOTIFICATION
	toast.Parent = wrapper
	CreateCorner(toast, UDim.new(0, 10))
	CreateStroke(toast, currentTheme.BorderColor)
	RegisterThemed(toast, { BackgroundColor3 = "BgSecondary" })

	local accent = Instance.new("Frame")
	accent.Size = UDim2.new(0, 4, 0, 16)
	accent.Position = UDim2.new(0, 10, 0.5, -8)
	accent.BackgroundColor3 = currentTheme.AccentPrimary
	accent.BorderSizePixel = 0
	accent.Parent = toast
	CreateCorner(accent, UDim.new(0, 2))
	RegisterThemed(accent, { BackgroundColor3 = "AccentPrimary" })

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -30, 1, 0)
	label.Position = UDim2.new(0, 22, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = currentTheme.TextPrimary
	label.Font = FONT
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Parent = toast
	RegisterThemed(label, { TextColor3 = "TextPrimary" })

	TweenService:Create(toast, TWEEN_BOUNCE, { Position = UDim2.new(0, 0, 0, 0) }):Play()
	task.delay(2.5, function()
		local out = TweenService:Create(toast, TWEEN_NORMAL, { Position = UDim2.new(1.5, 0, 0, 0) })
		out:Play()
		out.Completed:Connect(function() wrapper:Destroy() end)
	end)
end

-- // ============================================================
-- // 7. GUI LIBRARY CLASS
-- // ============================================================

local GuiLibrary = {}
GuiLibrary.__index = GuiLibrary

function GuiLibrary.new()
	local self = setmetatable({}, GuiLibrary)
	self.Windows = {}
	self.Desktop = desktop
	self.LastWindowPos = { X = 80, Y = 80 }
	self._dragging = nil
	self._resizing = nil

	self:_SetupGlobalInputTracking()
	return self
end

function GuiLibrary:_SetupGlobalInputTracking()
	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
		local mx, my = input.Position.X, input.Position.Y

		if self._dragging then
			local d = self._dragging
			d.TargetX = d.StartPosX + (mx - d.StartMouseX)
			d.TargetY = math.max(0, d.StartPosY + (my - d.StartMouseY))
		end

		if self._resizing then
			local r = self._resizing
			r.TargetW = math.max(MIN_WINDOW_WIDTH, r.StartW + (mx - r.StartMouseX))
			r.TargetH = math.max(MIN_WINDOW_HEIGHT, r.StartH + (my - r.StartMouseY))
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self._dragging = nil
			self._resizing = nil
		end
	end)

	RunService.RenderStepped:Connect(function(dt)
		if self._dragging then
			local d = self._dragging
			local curPos = d.El.Position
			local lerpX = curPos.X.Offset + (d.TargetX - curPos.X.Offset) * 0.6
			local lerpY = curPos.Y.Offset + (d.TargetY - curPos.Y.Offset) * 0.6
			d.El.Position = UDim2.new(0, math.floor(lerpX), 0, math.floor(lerpY))
		end
		
		if self._resizing then
			local r = self._resizing
			local curSize = r.El.Size
			local lerpW = curSize.X.Offset + (r.TargetW - curSize.X.Offset) * 0.6
			local lerpH = curSize.Y.Offset + (r.TargetH - curSize.Y.Offset) * 0.6
			r.El.Size = UDim2.new(0, math.floor(lerpW), 0, math.floor(lerpH))
		end
	end)
end

function GuiLibrary:_StartDrag(windowFrame: Frame, input: InputObject)
	BringToFront(windowFrame)
	self._dragging = {
		El = windowFrame,
		StartMouseX = input.Position.X,
		StartMouseY = input.Position.Y,
		StartPosX = windowFrame.Position.X.Offset,
		StartPosY = windowFrame.Position.Y.Offset,
		TargetX = windowFrame.Position.X.Offset,
		TargetY = windowFrame.Position.Y.Offset,
	}
end

function GuiLibrary:_StartResize(windowFrame: Frame, input: InputObject)
	BringToFront(windowFrame)
	self._resizing = {
		El = windowFrame,
		StartMouseX = input.Position.X,
		StartMouseY = input.Position.Y,
		StartW = windowFrame.AbsoluteSize.X,
		StartH = windowFrame.AbsoluteSize.Y,
		TargetW = windowFrame.AbsoluteSize.X,
		TargetH = windowFrame.AbsoluteSize.Y,
	}
end

function GuiLibrary:CreateWindow(config: { id: string, title: string, width: number?, height: number? })
	local id = config.id
	if self.Windows[id] then return self.Windows[id] end

	local windowFrame = Instance.new("TextButton")
	windowFrame.Name = "Window_" .. id
	windowFrame.Size = UDim2.new(0, config.width or 500, 0, config.height or 400)
	windowFrame.BackgroundColor3 = currentTheme.BgSurface
	windowFrame.BackgroundTransparency = currentTheme.SurfaceTransparency
	windowFrame.BorderSizePixel = 0
	windowFrame.Text = ""
	windowFrame.AutoButtonColor = false
	windowFrame.Visible = false
	windowFrame.ClipsDescendants = false 
	windowFrame.Active = true 
	windowFrame.ZIndex = topZIndex
	windowFrame.Parent = self.Desktop
	CreateCorner(windowFrame, UDim.new(0, 14))
	CreateStroke(windowFrame, currentTheme.BorderColor)
	RegisterThemed(windowFrame, { BackgroundColor3 = "BgSurface" })

	windowFrame.Position = UDim2.new(0, self.LastWindowPos.X, 0, self.LastWindowPos.Y)
	self.LastWindowPos.X += 30
	self.LastWindowPos.Y += 30
	local vp = GetViewportSize()
	if self.LastWindowPos.X > vp.X - 300 then self.LastWindowPos.X = 80 end
	if self.LastWindowPos.Y > vp.Y - 200 then self.LastWindowPos.Y = 80 end

	local winTopbar = Instance.new("Frame")
	winTopbar.Name = "Topbar"
	winTopbar.Size = UDim2.new(1, 0, 0, TOPBAR_HEIGHT)
	winTopbar.BackgroundTransparency = 1 
	winTopbar.BorderSizePixel = 0
	winTopbar.Active = true
	winTopbar.Parent = windowFrame

	local winTopbarBorder = Instance.new("Frame")
	winTopbarBorder.Size = UDim2.new(1, 0, 0, 1)
	winTopbarBorder.Position = UDim2.new(0, 0, 1, -1)
	winTopbarBorder.BackgroundColor3 = currentTheme.BorderColor
	winTopbarBorder.BorderSizePixel = 0
	winTopbarBorder.Parent = winTopbar
	RegisterThemed(winTopbarBorder, { BackgroundColor3 = "BorderColor" })

	local controls = Instance.new("Frame")
	controls.Name = "Controls"
	controls.Size = UDim2.new(0, 40, 0, TOPBAR_HEIGHT)
	controls.Position = UDim2.new(0, 10, 0, 0)
	controls.BackgroundTransparency = 1
	controls.Parent = winTopbar
	CreateListLayout(controls, Enum.FillDirection.Horizontal, 7, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 13, 0, 13)
	closeBtn.BackgroundColor3 = Color3.fromHex("#FF5F57")
	closeBtn.Text = ""
	closeBtn.BorderSizePixel = 0
	closeBtn.AutoButtonColor = false
	closeBtn.Parent = controls
	CreateCorner(closeBtn, UDim.new(1, 0))

	local closeSymbol = Instance.new("TextLabel")
	closeSymbol.Size = UDim2.new(1, 0, 1, 0)
	closeSymbol.BackgroundTransparency = 1
	closeSymbol.Text = "x"
	closeSymbol.TextColor3 = Color3.fromHex("#4A0000")
	closeSymbol.Font = FONT_BOLD
	closeSymbol.TextSize = 9
	closeSymbol.TextTransparency = 1
	closeSymbol.Parent = closeBtn

	local minBtn = Instance.new("TextButton")
	minBtn.Size = UDim2.new(0, 13, 0, 13)
	minBtn.BackgroundColor3 = Color3.fromHex("#FEBC2E")
	minBtn.Text = ""
	minBtn.BorderSizePixel = 0
	minBtn.AutoButtonColor = false
	minBtn.Parent = controls
	CreateCorner(minBtn, UDim.new(1, 0))

	local minSymbol = Instance.new("TextLabel")
	minSymbol.Size = UDim2.new(1, 0, 1, -2)
	minSymbol.BackgroundTransparency = 1
	minSymbol.Text = "-"
	minSymbol.TextColor3 = Color3.fromHex("#5A4000")
	minSymbol.Font = FONT_BOLD
	minSymbol.TextSize = 14
	minSymbol.TextTransparency = 1
	minSymbol.Parent = minBtn

	winTopbar.MouseEnter:Connect(function()
		TweenService:Create(closeSymbol, TWEEN_FAST, { TextTransparency = 0 }):Play()
		TweenService:Create(minSymbol, TWEEN_FAST, { TextTransparency = 0 }):Play()
	end)
	winTopbar.MouseLeave:Connect(function()
		TweenService:Create(closeSymbol, TWEEN_FAST, { TextTransparency = 1 }):Play()
		TweenService:Create(minSymbol, TWEEN_FAST, { TextTransparency = 1 }):Play()
	end)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -100, 1, 0)
	titleLabel.Position = UDim2.new(0, 50, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = config.title
	titleLabel.TextColor3 = currentTheme.TextSecondary
	titleLabel.Font = FONT_MEDIUM
	titleLabel.TextSize = 12.5
	titleLabel.TextXAlignment = Enum.TextXAlignment.Center
	titleLabel.Parent = winTopbar
	RegisterThemed(titleLabel, { TextColor3 = "TextSecondary" })

	local body = Instance.new("Frame")
	body.Name = "Body"
	body.Size = UDim2.new(1, 0, 1, -TOPBAR_HEIGHT)
	body.Position = UDim2.new(0, 0, 0, TOPBAR_HEIGHT)
	body.BackgroundTransparency = 1
	body.BorderSizePixel = 0
	body.ClipsDescendants = false
	body.Active = true
	body.Parent = windowFrame

	local resizer = Instance.new("TextButton")
	resizer.Name = "Resizer"
	resizer.Size = UDim2.new(0, 18, 0, 18)
	resizer.Position = UDim2.new(1, -18, 1, -18)
	resizer.BackgroundTransparency = 1
	resizer.Text = ""
	resizer.AutoButtonColor = false
	resizer.Parent = windowFrame

	local resizerLine = Instance.new("Frame")
	resizerLine.Size = UDim2.new(0, 8, 0, 2)
	resizerLine.Position = UDim2.new(1, -11, 1, -5)
	resizerLine.Rotation = -45
	resizerLine.BackgroundColor3 = currentTheme.TextTertiary
	resizerLine.BackgroundTransparency = 0.5
	resizerLine.BorderSizePixel = 0
	resizerLine.Parent = windowFrame
	RegisterThemed(resizerLine, { BackgroundColor3 = "TextTertiary" })

	winTopbar.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		local mx, my = input.Position.X, input.Position.Y
		local cp = controls.AbsolutePosition
		local cs = controls.AbsoluteSize
		if not (mx >= cp.X and mx <= cp.X + cs.X and my >= cp.Y and my <= cp.Y + cs.Y) then
			self:_StartDrag(windowFrame, input)
		end
	end)

	resizer.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self:_StartResize(windowFrame, input)
		end
	end)

	windowFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			BringToFront(windowFrame)
		end
	end)

	closeBtn.MouseButton1Click:Connect(function() self:CloseWindow(id) end)
	minBtn.MouseButton1Click:Connect(function() self:MinimizeWindow(id) end)

	local winObj = {
		Id = id,
		El = windowFrame,
		Body = body,
		Topbar = winTopbar,
		Resizer = resizer,
		ResizerLine = resizerLine,
		Tabs = {},
		TabSidebar = nil :: Frame?,
		TabContent = nil :: ScrollingFrame?,
		IsRolledUp = false,
		OriginalHeight = config.height or 400,
	}

	self.Windows[id] = winObj
	return winObj
end

function GuiLibrary:ShowWindow(id: string)
	local win = self.Windows[id]
	if not win then return end
	win.El.Visible = true
	BringToFront(win.El)
	win.El.BackgroundTransparency = 1
	TweenService:Create(win.El, TWEEN_NORMAL, { BackgroundTransparency = currentTheme.SurfaceTransparency }):Play()
	self:_SetDockActive(id, true)
end

function GuiLibrary:CloseWindow(id: string)
	local win = self.Windows[id]
	if not win then return end
	local tween = TweenService:Create(win.El, TWEEN_FAST, { BackgroundTransparency = 1 })
	tween:Play()
	tween.Completed:Connect(function()
		win.El.Visible = false
		win.El.BackgroundTransparency = currentTheme.SurfaceTransparency
	end)
	self:_SetDockActive(id, false)
end

function GuiLibrary:MinimizeWindow(id: string)
	local win = self.Windows[id]
	if not win then return end
	win.IsRolledUp = not win.IsRolledUp

	if win.IsRolledUp then
		win.OriginalHeight = win.El.AbsoluteSize.Y
		win.Body.Visible = false
		win.Resizer.Visible = false
		win.ResizerLine.Visible = false
		TweenService:Create(win.El, TWEEN_ROLLUP, { Size = UDim2.new(0, win.El.AbsoluteSize.X, 0, TOPBAR_HEIGHT) }):Play()
	else
		local tween = TweenService:Create(win.El, TWEEN_ROLLUP, { Size = UDim2.new(0, win.El.AbsoluteSize.X, 0, win.OriginalHeight) })
		tween:Play()
		tween.Completed:Connect(function()
			win.Body.Visible = true
			win.Resizer.Visible = true
			win.ResizerLine.Visible = true
		end)
	end
end

function GuiLibrary:ToggleWindow(id: string)
	local win = self.Windows[id]
	if not win then return end
	if win.El.Visible then self:CloseWindow(id) else self:ShowWindow(id) end
end

function GuiLibrary:_SetDockActive(appId: string, active: boolean)
	local dock = screenGui:FindFirstChild("Dock")
	if not dock then return end
	for _, item in dock:GetChildren() do
		if item:GetAttribute("AppId") == appId then
			local dot = item:FindFirstChild("Dot")
			if dot then
				TweenService:Create(dot, TWEEN_FAST, { BackgroundTransparency = if active then 0 else 1 }):Play()
			end
			break
		end
	end
end

function GuiLibrary:_NextOrder(parent: GuiObject): number
	local max = 0
	for _, child in parent:GetChildren() do
		if child:IsA("GuiObject") then max = math.max(max, child.LayoutOrder) end
	end
	return max + 1
end

function GuiLibrary:CreateTab(window: any, config: { id: string, label: string, icon: string? }): Frame
	if not window.TabSidebar then
		local sidebar = Instance.new("Frame")
		sidebar.Name = "TabSidebar"
		sidebar.Size = UDim2.new(0, 160, 1, 0)
		sidebar.BackgroundColor3 = Color3.fromHex("#000000")
		sidebar.BackgroundTransparency = 0.85
		sidebar.BorderSizePixel = 0
		sidebar.Parent = window.Body

		local sidebarBorder = Instance.new("Frame")
		sidebarBorder.Size = UDim2.new(0, 1, 1, 0)
		sidebarBorder.Position = UDim2.new(1, -1, 0, 0)
		sidebarBorder.BackgroundColor3 = currentTheme.BorderColor
		sidebarBorder.BorderSizePixel = 0
		sidebarBorder.Parent = sidebar
		RegisterThemed(sidebarBorder, { BackgroundColor3 = "BorderColor" })

		local sidebarContent = Instance.new("Frame")
		sidebarContent.Size = UDim2.new(1, -2, 1, 0)
		sidebarContent.BackgroundTransparency = 1
		sidebarContent.Parent = sidebar
		CreatePadding(sidebarContent, 10, 10, 8, 8)
		CreateListLayout(sidebarContent, Enum.FillDirection.Vertical, 2)

		local tabContent = Instance.new("ScrollingFrame")
		tabContent.Name = "TabContent"
		tabContent.Size = UDim2.new(1, -160, 1, 0)
		tabContent.Position = UDim2.new(0, 160, 0, 0)
		tabContent.BackgroundTransparency = 1
		tabContent.BorderSizePixel = 0
		tabContent.ScrollBarThickness = 4
		tabContent.ScrollBarImageColor3 = currentTheme.TextTertiary
		tabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
		tabContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
		tabContent.Parent = window.Body
		RegisterThemed(tabContent, { ScrollBarImageColor3 = "TextTertiary" })

		window.TabSidebar = sidebarContent
		window.TabContent = tabContent
	end

	local tabBtn = Instance.new("TextButton")
	tabBtn.Size = UDim2.new(1, 0, 0, 34)
	tabBtn.BackgroundTransparency = 1
	tabBtn.BorderSizePixel = 0
	tabBtn.Text = ""
	tabBtn.AutoButtonColor = false
	tabBtn.LayoutOrder = #window.Tabs
	tabBtn.Parent = window.TabSidebar
	CreateCorner(tabBtn, UDim.new(0, 10))

	local tabLabel = Instance.new("TextLabel")
	tabLabel.Size = UDim2.new(1, -36, 1, 0)
	tabLabel.Position = UDim2.new(0, 32, 0, 0)
	tabLabel.BackgroundTransparency = 1
	tabLabel.Text = config.label
	tabLabel.TextColor3 = currentTheme.TextSecondary
	tabLabel.Font = FONT_MEDIUM
	tabLabel.TextSize = 13
	tabLabel.TextXAlignment = Enum.TextXAlignment.Left
	tabLabel.Parent = tabBtn
	RegisterThemed(tabLabel, { TextColor3 = "TextSecondary" })

	if config.icon then
		BuildIcon(tabBtn, config.icon, 16, currentTheme.TextSecondary).Position = UDim2.new(0, 8, 0.5, -8)
	end

	local panel = Instance.new("Frame")
	panel.Size = UDim2.new(1, 0, 0, 0)
	panel.AutomaticSize = Enum.AutomaticSize.Y
	panel.BackgroundTransparency = 1
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.LayoutOrder = #window.Tabs
	panel.Parent = window.TabContent
	CreatePadding(panel, 20, 20, 20, 20)
	CreateListLayout(panel, Enum.FillDirection.Vertical, 14)

	tabBtn.MouseButton1Click:Connect(function()
		for _, tab in window.Tabs do
			tab.Btn.BackgroundTransparency = 1
			tab.Label.TextColor3 = currentTheme.TextSecondary
			tab.Panel.Visible = false
		end
		tabBtn.BackgroundColor3 = currentTheme.TextPrimary
		tabBtn.BackgroundTransparency = 0.92
		tabLabel.TextColor3 = currentTheme.AccentPrimary
		panel.Visible = true
	end)

	tabBtn.MouseEnter:Connect(function()
		if not panel.Visible then TweenService:Create(tabBtn, TWEEN_FAST, { BackgroundTransparency = 0.95 }):Play() end
	end)
	tabBtn.MouseLeave:Connect(function()
		if not panel.Visible then TweenService:Create(tabBtn, TWEEN_FAST, { BackgroundTransparency = 1 }):Play() end
	end)

	local tabInfo = { Id = config.id, Btn = tabBtn, Label = tabLabel, Panel = panel }
	table.insert(window.Tabs, tabInfo)

	if #window.Tabs == 1 then
		tabBtn.BackgroundColor3 = currentTheme.TextPrimary
		tabBtn.BackgroundTransparency = 0.92
		tabLabel.TextColor3 = currentTheme.AccentPrimary
		panel.Visible = true
	end
	return panel
end

function GuiLibrary:CreateSectionHeader(parent: GuiObject, text: string): TextLabel
	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, 0, 0, 16)
	header.BackgroundTransparency = 1
	header.Text = string.upper(text)
	header.TextColor3 = currentTheme.TextTertiary
	header.Font = FONT_BOLD
	header.TextSize = 11
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.LayoutOrder = self:_NextOrder(parent)
	header.Parent = parent
	RegisterThemed(header, { TextColor3 = "TextTertiary" })
	return header
end

function GuiLibrary:CreateButton(parent: GuiObject, config: { label: string, secondary: boolean?, onClick: (() -> ())? }): TextButton
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 0, 0, 36)
	btn.AutomaticSize = Enum.AutomaticSize.X
	btn.BorderSizePixel = 0
	btn.Text = config.label
	btn.Font = FONT_MEDIUM
	btn.TextSize = 13
	btn.AutoButtonColor = false
	btn.LayoutOrder = self:_NextOrder(parent)
	btn.Parent = parent
	CreateCorner(btn, UDim.new(0, 10))
	CreatePadding(btn, 0, 0, 18, 18)

	if config.secondary then
		btn.BackgroundColor3 = currentTheme.BgTertiary
		btn.TextColor3 = currentTheme.TextPrimary
		CreateStroke(btn, currentTheme.BorderColor)
		RegisterThemed(btn, { BackgroundColor3 = "BgTertiary", TextColor3 = "TextPrimary" })
	else
		btn.BackgroundColor3 = currentTheme.AccentPrimary
		btn.TextColor3 = currentTheme.BgPrimary
		RegisterThemed(btn, { BackgroundColor3 = "AccentPrimary", TextColor3 = "BgPrimary" })
	end

	btn.MouseEnter:Connect(function() TweenService:Create(btn, TWEEN_FAST, { BackgroundTransparency = 0.15 }):Play() end)
	btn.MouseLeave:Connect(function() TweenService:Create(btn, TWEEN_FAST, { BackgroundTransparency = 0 }):Play() end)
	if config.onClick then btn.MouseButton1Click:Connect(config.onClick) end
	return btn
end

function GuiLibrary:CreateToggle(parent: GuiObject, config: { label: string, default: boolean?, onChange: ((boolean) -> ())? }): TextButton
	local state = if config.default == true then true else false

	local row = Instance.new("TextButton")
	row.Size = UDim2.new(1, 0, 0, 44)
	row.BackgroundColor3 = currentTheme.BgTertiary
	row.BorderSizePixel = 0
	row.Text = ""
	row.AutoButtonColor = false
	row.LayoutOrder = self:_NextOrder(parent)
	row.Parent = parent
	CreateCorner(row, UDim.new(0, 10))
	CreateStroke(row, currentTheme.BorderColor)
	RegisterThemed(row, { BackgroundColor3 = "BgTertiary" })

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -70, 1, 0)
	label.Position = UDim2.new(0, 14, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = config.label
	label.TextColor3 = currentTheme.TextPrimary
	label.Font = FONT_MEDIUM
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row
	RegisterThemed(label, { TextColor3 = "TextPrimary" })

	local switchFrame = Instance.new("Frame")
	switchFrame.Size = UDim2.new(0, 40, 0, 22)
	switchFrame.Position = UDim2.new(1, -54, 0.5, -11)
	switchFrame.BackgroundColor3 = if state then currentTheme.AccentPrimary else Color3.fromRGB(60, 60, 60)
	switchFrame.BorderSizePixel = 0
	switchFrame.Parent = row
	CreateCorner(switchFrame, UDim.new(1, 0))

	local thumb = Instance.new("Frame")
	thumb.Size = UDim2.new(0, 16, 0, 16)
	thumb.Position = if state then UDim2.new(0, 21, 0, 3) else UDim2.new(0, 3, 0, 3)
	thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	thumb.BorderSizePixel = 0
	thumb.Parent = switchFrame
	CreateCorner(thumb, UDim.new(1, 0))

	row.MouseButton1Click:Connect(function()
		state = not state
		TweenService:Create(thumb, TWEEN_FAST, { Position = if state then UDim2.new(0, 21, 0, 3) else UDim2.new(0, 3, 0, 3) }):Play()
		TweenService:Create(switchFrame, TWEEN_FAST, { BackgroundColor3 = if state then currentTheme.AccentPrimary else Color3.fromRGB(60, 60, 60) }):Play()
		if config.onChange then config.onChange(state) end
	end)
	return row
end

function GuiLibrary:CreateSlider(parent: GuiObject, config: { label: string, min: number?, max: number?, default: number?, onChange: ((number) -> ())? }): Frame
	local minVal = config.min or 0
	local maxVal = config.max or 100
	local curVal = config.default or 50
	local range = maxVal - minVal
	local initPct = (curVal - minVal) / range

	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 60)
	row.BackgroundColor3 = currentTheme.BgTertiary
	row.BorderSizePixel = 0
	row.LayoutOrder = self:_NextOrder(parent)
	row.Parent = parent
	CreateCorner(row, UDim.new(0, 10))
	CreateStroke(row, currentTheme.BorderColor)
	RegisterThemed(row, { BackgroundColor3 = "BgTertiary" })

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.5, -14, 0, 20)
	label.Position = UDim2.new(0, 14, 0, 10)
	label.BackgroundTransparency = 1
	label.Text = config.label
	label.TextColor3 = currentTheme.TextPrimary
	label.Font = FONT_MEDIUM
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row
	RegisterThemed(label, { TextColor3 = "TextPrimary" })

	local valLabel = Instance.new("TextLabel")
	valLabel.Size = UDim2.new(0.5, -14, 0, 20)
	valLabel.Position = UDim2.new(0.5, 0, 0, 10)
	valLabel.BackgroundTransparency = 1
	valLabel.Text = tostring(curVal)
	valLabel.TextColor3 = currentTheme.AccentPrimary
	valLabel.Font = FONT_BOLD
	valLabel.TextSize = 13
	valLabel.TextXAlignment = Enum.TextXAlignment.Right
	valLabel.Parent = row
	RegisterThemed(valLabel, { TextColor3 = "AccentPrimary" })

	local track = Instance.new("TextButton")
	track.Size = UDim2.new(1, -28, 0, 6)
	track.Position = UDim2.new(0, 14, 0, 40)
	track.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	track.BorderSizePixel = 0
	track.Text = ""
	track.AutoButtonColor = false
	track.Parent = row  -- BEHOBEN: Hier war zuvor ein falscher Zuweisungsfehler!
	CreateCorner(track, UDim.new(1, 0))

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(initPct, 0, 1, 0)
	fill.BackgroundColor3 = currentTheme.AccentPrimary
	fill.BorderSizePixel = 0
	fill.Parent = track
	CreateCorner(fill, UDim.new(1, 0))
	RegisterThemed(fill, { BackgroundColor3 = "AccentPrimary" })

	local thumb = Instance.new("Frame")
	thumb.Size = UDim2.new(0, 16, 0, 16)
	thumb.Position = UDim2.new(initPct, -8, 0.5, -8)
	thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	thumb.BorderSizePixel = 0
	thumb.Parent = track
	CreateCorner(thumb, UDim.new(1, 0))

	local thumbStroke = Instance.new("UIStroke")
	thumbStroke.Color = currentTheme.AccentPrimary
	thumbStroke.Thickness = 2
	thumbStroke.Parent = thumb
	RegisterThemed(thumbStroke, { Color = "AccentPrimary" })

	local sliderDragging = false
	local connection = nil

	local function updateSlider(inputX: number)
		local trackPos = track.AbsolutePosition.X
		local pct = math.clamp((inputX - trackPos) / track.AbsoluteSize.X, 0, 1)
		local v = math.round(minVal + pct * range)
		fill.Size = UDim2.new(pct, 0, 1, 0)
		thumb.Position = UDim2.new(pct, -8, 0.5, -8)
		valLabel.Text = tostring(v)
		if config.onChange then config.onChange(v) end
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			sliderDragging = true
			updateSlider(input.Position.X)
			if connection then connection:Disconnect() end
			connection = RunService.RenderStepped:Connect(function()
				if sliderDragging then
					local ms = UserInputService:GetMouseLocation()
					updateSlider(ms.X)
				end
			end)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			sliderDragging = false
			if connection then connection:Disconnect(); connection = nil end
		end
	end)

	return row
end

function GuiLibrary:CreateTextbox(parent: GuiObject, config: { placeholder: string? }): TextBox
	local tb = Instance.new("TextBox")
	tb.Size = UDim2.new(1, 0, 0, 38)
	tb.BackgroundColor3 = currentTheme.BgTertiary
	tb.BorderSizePixel = 0
	tb.Text = ""
	tb.PlaceholderText = config.placeholder or ""
	tb.PlaceholderColor3 = currentTheme.TextTertiary
	tb.TextColor3 = currentTheme.TextPrimary
	tb.Font = FONT
	tb.TextSize = 13
	tb.TextXAlignment = Enum.TextXAlignment.Left
	tb.ClearTextOnFocus = false
	tb.LayoutOrder = self:_NextOrder(parent)
	tb.Parent = parent
	CreateCorner(tb, UDim.new(0, 10))
	local stroke = CreateStroke(tb, currentTheme.BorderColor)
	CreatePadding(tb, 0, 0, 14, 14)
	RegisterThemed(tb, { BackgroundColor3 = "BgTertiary", TextColor3 = "TextPrimary", PlaceholderColor3 = "TextTertiary" })

	tb.Focused:Connect(function() TweenService:Create(stroke, TWEEN_FAST, { Color = currentTheme.AccentPrimary }):Play() end)
	tb.FocusLost:Connect(function() TweenService:Create(stroke, TWEEN_FAST, { Color = currentTheme.BorderColor }):Play() end)
	return tb
end

function GuiLibrary:CreateDropdown(parent: GuiObject, config: { label: string, options: { string }, onChange: ((string) -> ())? }): Frame
	local selectedOpt = config.options[1] or ""
	local isOpen = false

	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 38)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.LayoutOrder = self:_NextOrder(parent)
	container.Parent = parent

	local trigger = Instance.new("TextButton")
	trigger.Size = UDim2.new(1, 0, 0, 38)
	trigger.BackgroundColor3 = currentTheme.BgTertiary
	trigger.BorderSizePixel = 0
	trigger.Text = config.label .. ": " .. selectedOpt .. "  v"
	trigger.TextColor3 = currentTheme.TextPrimary
	trigger.Font = FONT
	trigger.TextSize = 13
	trigger.TextXAlignment = Enum.TextXAlignment.Left
	trigger.AutoButtonColor = false
	trigger.Parent = container
	CreateCorner(trigger, UDim.new(0, 10))
	CreateStroke(trigger, currentTheme.BorderColor)
	CreatePadding(trigger, 0, 0, 14, 14)
	RegisterThemed(trigger, { BackgroundColor3 = "BgTertiary", TextColor3 = "TextPrimary" })

	local menu = Instance.new("Frame")
	menu.Size = UDim2.new(1, 0, 0, 0)
	menu.Position = UDim2.new(0, 0, 0, 42)
	menu.BackgroundColor3 = currentTheme.BgSecondary
	menu.BorderSizePixel = 0
	menu.ClipsDescendants = true
	menu.Visible = false
	menu.ZIndex = topZIndex + 5
	menu.Parent = container
	CreateCorner(menu, UDim.new(0, 10))
	CreateStroke(menu, currentTheme.BorderColor)
	RegisterThemed(menu, { BackgroundColor3 = "BgSecondary" })

	CreateListLayout(menu, Enum.FillDirection.Vertical, 0)
	local totalH = 0

	for i, optText in config.options do
		local opt = Instance.new("TextButton")
		opt.Size = UDim2.new(1, 0, 0, 32)
		opt.BackgroundTransparency = 1
		opt.BorderSizePixel = 0
		opt.Text = optText
		opt.TextColor3 = currentTheme.TextSecondary
		opt.Font = FONT
		opt.TextSize = 13
		opt.TextXAlignment = Enum.TextXAlignment.Left
		opt.AutoButtonColor = false
		opt.LayoutOrder = i
		opt.Parent = menu
		CreatePadding(opt, 0, 0, 14, 14)
		RegisterThemed(opt, { TextColor3 = "TextSecondary" })

		opt.MouseEnter:Connect(function() TweenService:Create(opt, TWEEN_FAST, { BackgroundTransparency = 0.94, TextColor3 = currentTheme.AccentPrimary }):Play() end)
		opt.MouseLeave:Connect(function() TweenService:Create(opt, TWEEN_FAST, { BackgroundTransparency = 1, TextColor3 = currentTheme.TextSecondary }):Play() end)

		opt.MouseButton1Click:Connect(function()
			selectedOpt = optText
			trigger.Text = config.label .. ": " .. selectedOpt .. "  v"
			isOpen = false
			TweenService:Create(menu, TWEEN_FAST, { Size = UDim2.new(1, 0, 0, 0) }):Play()
			task.delay(0.15, function() menu.Visible = false end)
			if config.onChange then config.onChange(selectedOpt) end
		end)
		totalH += 32
	end

	trigger.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		if isOpen then
			container.ZIndex = topZIndex + 50
			menu.ZIndex = topZIndex + 51
			for _, ch in menu:GetChildren() do if ch:IsA("GuiObject") then ch.ZIndex = menu.ZIndex end end
			menu.Visible = true
			TweenService:Create(menu, TWEEN_FAST, { Size = UDim2.new(1, 0, 0, math.min(totalH, 200)) }):Play()
		else
			container.ZIndex = 1
			TweenService:Create(menu, TWEEN_FAST, { Size = UDim2.new(1, 0, 0, 0) }):Play()
			task.delay(0.15, function() menu.Visible = false end)
		end
	end)

	return container
end

function GuiLibrary:CreateInfoCard(parent: GuiObject, config: { label: string, value: string }): Frame
	local card = Instance.new("Frame")
	card.Size = UDim2.new(0, 130, 0, 56)
	card.BackgroundColor3 = currentTheme.BgTertiary
	card.BorderSizePixel = 0
	card.LayoutOrder = self:_NextOrder(parent)
	card.Parent = parent
	CreateCorner(card, UDim.new(0, 10))
	CreateStroke(card, currentTheme.BorderColor)
	CreatePadding(card, 10, 10, 12, 12)
	RegisterThemed(card, { BackgroundColor3 = "BgTertiary" })

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 14)
	lbl.BackgroundTransparency = 1
	lbl.Text = string.upper(config.label)
	lbl.TextColor3 = currentTheme.TextTertiary
	lbl.Font = FONT_MEDIUM
	lbl.TextSize = 11
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = card
	RegisterThemed(lbl, { TextColor3 = "TextTertiary" })

	local val = Instance.new("TextLabel")
	val.Size = UDim2.new(1, 0, 0, 18)
	val.Position = UDim2.new(0, 0, 0, 20)
	val.BackgroundTransparency = 1
	val.Text = config.value
	val.TextColor3 = currentTheme.TextPrimary
	val.Font = FONT_MEDIUM
	val.TextSize = 14
	val.TextXAlignment = Enum.TextXAlignment.Left
	val.Parent = card
	RegisterThemed(val, { TextColor3 = "TextPrimary" })
	return card
end

function GuiLibrary:CreateCardGrid(parent: GuiObject): Frame
	local grid = Instance.new("Frame")
	grid.Size = UDim2.new(1, 0, 0, 0)
	grid.AutomaticSize = Enum.AutomaticSize.Y
	grid.BackgroundTransparency = 1
	grid.BorderSizePixel = 0
	grid.LayoutOrder = self:_NextOrder(parent)
	grid.Parent = parent
	CreateGridLayout(grid, UDim2.new(0, 130, 0, 56), UDim2.new(0, 10, 0, 10))
	return grid
end

-- // ============================================================
-- // 8. DOCK SYSTEM
-- // ============================================================

local dockDragState = {
	Active = false,
	StartMouseX = 0,
	StartMouseY = 0,
	StartPosX = 0,
	StartPosY = 0,
	DockFrame = nil :: Frame?,
}

UserInputService.InputChanged:Connect(function(input)
	if not dockDragState.Active then return end
	if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
	local dock = dockDragState.DockFrame
	if not dock then return end
	local dx = input.Position.X - dockDragState.StartMouseX
	local dy = input.Position.Y - dockDragState.StartMouseY
	dock.Position = UDim2.new(0, dockDragState.StartPosX + dx, 0, dockDragState.StartPosY + dy)
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dockDragState.Active = false
	end
end)

local DockSystem = {}
DockSystem.__index = DockSystem

function DockSystem.new(gui: any, systemRef: any)
	local self = setmetatable({}, DockSystem)
	self.Gui = gui
	self.System = systemRef
	self.Orientation = "horizontal"
	self.DockFrame = nil :: Frame?
	return self
end

function DockSystem.BuildDock(self: any)
	if self.DockFrame then self.DockFrame:Destroy() end

	local dockApps = {}
	for _, app in self.System.Apps do
		if app.inDock then table.insert(dockApps, app) end
	end
	local numApps = #dockApps
	local itemSize = 48
	local padding = 4

	local dock = Instance.new("Frame")
	dock.Name = "Dock"
	dock.BackgroundColor3 = currentTheme.BgDock
	dock.BackgroundTransparency = currentTheme.DockTransparency
	dock.BorderSizePixel = 0
	dock.Active = true 
	dock.Parent = screenGui
	CreateCorner(dock, UDim.new(0, 18))
	CreateStroke(dock, currentTheme.BorderColor)
	RegisterThemed(dock, { BackgroundColor3 = "BgDock" })

	self.DockFrame = dock
	dockDragState.DockFrame = dock

	local handleSize = 24
	local sepSize = 1
	local extraItems = 2
	local contentSize = handleSize + padding + numApps * (itemSize + padding) + sepSize + padding * 2 + extraItems * (itemSize + padding) + 12

	if self.Orientation == "horizontal" then
		dock.Size = UDim2.new(0, contentSize, 0, itemSize + 16)
		dock.Position = UDim2.new(0.5, -math.floor(contentSize / 2), 1, -(itemSize + 40))
		CreateListLayout(dock, Enum.FillDirection.Horizontal, padding, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
	else
		local maxH = GetViewportSize().Y - 80
		local actualH = math.min(contentSize, maxH)
		dock.Size = UDim2.new(0, itemSize + 16, 0, actualH)
		dock.Position = UDim2.new(1, -(itemSize + 40), 0.5, -math.floor(actualH / 2))
		CreateListLayout(dock, Enum.FillDirection.Vertical, padding, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top)
	end
	CreatePadding(dock, 6, 6, 6, 6)

	local handle = Instance.new("TextButton")
	handle.BackgroundColor3 = currentTheme.TextTertiary
	handle.BackgroundTransparency = 0.9
	handle.BorderSizePixel = 0
	handle.Text = ""
	handle.AutoButtonColor = false
	handle.LayoutOrder = 0
	handle.Parent = dock
	CreateCorner(handle, UDim.new(0, 6))
	handle.Size = if self.Orientation == "horizontal" then UDim2.new(0, handleSize, 0, itemSize) else UDim2.new(0, itemSize, 0, handleSize)
	BuildIcon(handle, "move", 14, currentTheme.TextTertiary).Position = UDim2.new(0.5, -7, 0.5, -7)

	handle.MouseEnter:Connect(function() TweenService:Create(handle, TWEEN_FAST, { BackgroundTransparency = 0.8 }):Play() end)
	handle.MouseLeave:Connect(function() TweenService:Create(handle, TWEEN_FAST, { BackgroundTransparency = 0.9 }):Play() end)

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local absPos = dock.AbsolutePosition
			dock.Position = UDim2.new(0, absPos.X, 0, absPos.Y)
			dockDragState.Active = true
			dockDragState.StartMouseX = input.Position.X
			dockDragState.StartMouseY = input.Position.Y
			dockDragState.StartPosX = absPos.X
			dockDragState.StartPosY = absPos.Y
			dockDragState.DockFrame = dock
		end
	end)

	for i, app in dockApps do
		local item = Instance.new("Frame")
		item.BackgroundTransparency = 1
		item.LayoutOrder = i
		item.Parent = dock
		item:SetAttribute("AppId", app.id)
		item.Size = if self.Orientation == "horizontal" then UDim2.new(0, itemSize, 0, itemSize + 8) else UDim2.new(0, itemSize, 0, itemSize + 4)

		local iconBtn = Instance.new("TextButton")
		iconBtn.Size = UDim2.new(0, itemSize, 0, itemSize)
		iconBtn.BackgroundColor3 = currentTheme.BgTertiary
		iconBtn.BorderSizePixel = 0
		iconBtn.Text = ""
		iconBtn.AutoButtonColor = false
		iconBtn.Parent = item
		CreateCorner(iconBtn, UDim.new(0, 12))
		CreateStroke(iconBtn, currentTheme.BorderColor)
		RegisterThemed(iconBtn, { BackgroundColor3 = "BgTertiary" })
		BuildIcon(iconBtn, app.icon, 22, currentTheme.AccentPrimary).Position = UDim2.new(0.5, -11, 0.5, -11)

		local dot = Instance.new("Frame")
		dot.Name = "Dot"
		dot.Size = UDim2.new(0, 4, 0, 4)
		dot.BackgroundColor3 = currentTheme.AccentPrimary
		dot.BackgroundTransparency = 1
		dot.BorderSizePixel = 0
		dot.Parent = item
		CreateCorner(dot, UDim.new(1, 0))
		RegisterThemed(dot, { BackgroundColor3 = "AccentPrimary" })
		dot.Position = if self.Orientation == "horizontal" then UDim2.new(0.5, -2, 1, -2) else UDim2.new(1, 2, 0.5, -2)

		iconBtn.MouseEnter:Connect(function() TweenService:Create(iconBtn, TWEEN_FAST, { BackgroundTransparency = 0 }):Play() end)
		iconBtn.MouseLeave:Connect(function() TweenService:Create(iconBtn, TWEEN_FAST, { BackgroundTransparency = 0 }):Play() end)
		iconBtn.MouseButton1Click:Connect(function()
			if not self.Gui.Windows[app.id] then app.build(self.Gui:CreateWindow({ id = app.id, title = app.name })) end
			self.Gui:ToggleWindow(app.id)
		end)
		if self.Gui.Windows[app.id] and self.Gui.Windows[app.id].El.Visible then dot.BackgroundTransparency = 0 end
	end

	local sep = Instance.new("Frame")
	sep.BackgroundColor3 = currentTheme.BorderColor
	sep.BorderSizePixel = 0
	sep.LayoutOrder = numApps + 1
	sep.Parent = dock
	RegisterThemed(sep, { BackgroundColor3 = "BorderColor" })
	sep.Size = if self.Orientation == "horizontal" then UDim2.new(0, 1, 0, 36) else UDim2.new(0, 36, 0, 1)

	local launcherBtn = Instance.new("TextButton")
	launcherBtn.Size = UDim2.new(0, itemSize, 0, itemSize)
	launcherBtn.BackgroundColor3 = currentTheme.BgTertiary
	launcherBtn.BorderSizePixel = 0
	launcherBtn.Text = ""
	launcherBtn.AutoButtonColor = false
	launcherBtn.LayoutOrder = numApps + 2
	launcherBtn.Parent = dock
	CreateCorner(launcherBtn, UDim.new(0, 12))
	CreateStroke(launcherBtn, currentTheme.BorderColor)
	RegisterThemed(launcherBtn, { BackgroundColor3 = "BgTertiary" })
	BuildIcon(launcherBtn, "grid", 22, currentTheme.AccentPrimary).Position = UDim2.new(0.5, -11, 0.5, -11)
	launcherBtn.MouseButton1Click:Connect(function() self.System:ToggleLauncher() end)

	local orientBtn = Instance.new("TextButton")
	orientBtn.Size = UDim2.new(0, itemSize, 0, itemSize)
	orientBtn.BackgroundColor3 = currentTheme.BgSecondary
	orientBtn.BorderSizePixel = 0
	orientBtn.Text = ""
	orientBtn.AutoButtonColor = false
	orientBtn.LayoutOrder = numApps + 3
	orientBtn.Parent = dock
	CreateCorner(orientBtn, UDim.new(0, 12))
	CreateStroke(orientBtn, currentTheme.BorderColor)
	RegisterThemed(orientBtn, { BackgroundColor3 = "BgSecondary" })
	BuildIcon(orientBtn, "rotate", 18, currentTheme.AccentPrimary).Position = UDim2.new(0.5, -9, 0.5, -9)
	orientBtn.MouseButton1Click:Connect(function()
		self.Orientation = if self.Orientation == "horizontal" then "vertical" else "horizontal"
		self:BuildDock()
	end)
end

-- // ============================================================
-- // 9. APP LAUNCHER
-- // ============================================================

local AppLauncher = {}
AppLauncher.__index = AppLauncher

function AppLauncher.new(gui: any, systemRef: any)
	local self = setmetatable({}, AppLauncher)
	self.Gui = gui
	self.System = systemRef
	self.IsVisible = false
	self.Frame = nil :: Frame?
	return self
end

function AppLauncher.Build(self: any)
	if self.Frame then self.Frame:Destroy() end

	local launcher = Instance.new("TextButton")
	launcher.Size = UDim2.new(1, 0, 1, 0)
	launcher.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	launcher.BackgroundTransparency = 0.4
	launcher.BorderSizePixel = 0
	launcher.Text = ""
	launcher.AutoButtonColor = false
	launcher.Visible = false
	launcher.Parent = screenGui
	self.Frame = launcher

	launcher.MouseButton1Click:Connect(function() self:Toggle() end)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0, 500, 0, 30)
	title.Position = UDim2.new(0.5, -250, 0, 50)
	title.BackgroundTransparency = 1
	title.Text = "App Launcher"
	title.TextColor3 = currentTheme.TextPrimary
	title.Font = FONT_BOLD
	title.TextSize = 22
	title.Parent = launcher
	RegisterThemed(title, { TextColor3 = "TextPrimary" })

	local hint = Instance.new("TextLabel")
	hint.Size = UDim2.new(0, 500, 0, 20)
	hint.Position = UDim2.new(0.5, -250, 0, 82)
	hint.BackgroundTransparency = 1
	local dockCount = 0
	for _, app in self.System.Apps do if app.inDock then dockCount += 1 end end
	hint.Text = "Click app to open  |  Click pin to toggle dock (" .. dockCount .. "/" .. MAX_DOCK_APPS .. ")"
	hint.TextColor3 = currentTheme.TextTertiary
	hint.Font = FONT
	hint.TextSize = 13
	hint.Parent = launcher
	RegisterThemed(hint, { TextColor3 = "TextTertiary" })

	local gridFrame = Instance.new("Frame")
	gridFrame.Size = UDim2.new(0.8, 0, 0, 0)
	gridFrame.AutomaticSize = Enum.AutomaticSize.Y
	gridFrame.Position = UDim2.new(0.1, 0, 0, 115)
	gridFrame.BackgroundTransparency = 1
	gridFrame.Parent = launcher
	CreateGridLayout(gridFrame, UDim2.new(0, 100, 0, 110), UDim2.new(0, 20, 0, 15))

	for i, app in self.System.Apps do
		local item = Instance.new("Frame")
		item.BackgroundTransparency = 1
		item.LayoutOrder = i
		item.Parent = gridFrame

		local icon = Instance.new("TextButton")
		icon.Size = UDim2.new(0, 64, 0, 64)
		icon.Position = UDim2.new(0.5, -32, 0, 0)
		icon.BackgroundColor3 = currentTheme.BgTertiary
		icon.BorderSizePixel = 0
		icon.Text = ""
		icon.AutoButtonColor = false
		icon.Parent = item
		CreateCorner(icon, UDim.new(0, 16))
		CreateStroke(icon, currentTheme.BorderColor)
		RegisterThemed(icon, { BackgroundColor3 = "BgTertiary" })
		BuildIcon(icon, app.icon, 28, currentTheme.AccentPrimary).Position = UDim2.new(0.5, -14, 0.5, -14)

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, 16)
		label.Position = UDim2.new(0, 0, 0, 70)
		label.BackgroundTransparency = 1
		label.Text = app.name
		label.TextColor3 = currentTheme.TextPrimary
		label.Font = FONT_MEDIUM
		label.TextSize = 12
		label.Parent = item
		RegisterThemed(label, { TextColor3 = "TextPrimary" })

		local pinBtn = Instance.new("TextButton")
		pinBtn.Size = UDim2.new(0, 20, 0, 20)
		pinBtn.Position = UDim2.new(1, -24, 0, -4)
		pinBtn.BackgroundColor3 = if app.inDock then currentTheme.AccentPrimary else Color3.fromRGB(50, 50, 50)
		pinBtn.BackgroundTransparency = if app.inDock then 0.2 else 0.5
		pinBtn.BorderSizePixel = 0
		pinBtn.Text = if app.inDock then "D" else "+"
		pinBtn.TextColor3 = if app.inDock then currentTheme.BgPrimary else currentTheme.TextTertiary
		pinBtn.Font = FONT_BOLD
		pinBtn.TextSize = 10
		pinBtn.AutoButtonColor = false
		pinBtn.Parent = item
		CreateCorner(pinBtn, UDim.new(1, 0))

		pinBtn.MouseButton1Click:Connect(function() self.System:ToggleDockPin(app.id) end)
		icon.MouseButton1Click:Connect(function()
			if not self.Gui.Windows[app.id] then app.build(self.Gui:CreateWindow({ id = app.id, title = app.name })) end
			self.Gui:ShowWindow(app.id)
			self:Toggle()
		end)
		icon.MouseEnter:Connect(function() TweenService:Create(icon, TWEEN_FAST, { BackgroundTransparency = 0.1 }):Play() end)
		icon.MouseLeave:Connect(function() TweenService:Create(icon, TWEEN_FAST, { BackgroundTransparency = 0 }):Play() end)
	end
end

function AppLauncher.Toggle(self: any)
	self.IsVisible = not self.IsVisible
	if self.IsVisible then
		self.Frame.Visible = true
		self.Frame.BackgroundTransparency = 1
		TweenService:Create(self.Frame, TWEEN_NORMAL, { BackgroundTransparency = 0.4 }):Play()
	else
		local tween = TweenService:Create(self.Frame, TWEEN_FAST, { BackgroundTransparency = 1 })
		tween:Play()
		tween.Completed:Connect(function() self.Frame.Visible = false end)
	end
end

-- // ============================================================
-- // 10. SYSTEM & APP REGISTRATION API
-- // ============================================================

local SystemAPI = {}
SystemAPI.__index = SystemAPI

function SystemAPI.new()
	local self = setmetatable({}, SystemAPI)
	self.Apps = {}
	self.Gui = nil :: any
	self.Dock = nil :: any
	self.Launcher = nil :: any
	return self
end

function SystemAPI.Init(self: any, gui: any)
	self.Gui = gui
	self.Dock = DockSystem.new(gui, self)
	self.Launcher = AppLauncher.new(gui, self)
end

function SystemAPI.RegisterApp(self: any, config: { id: string, name: string, icon: string, build: (any) -> () })
	local dockCount = 0
	for _, app in self.Apps do if app.inDock then dockCount += 1 end end
	local canDock = dockCount < MAX_DOCK_APPS

	table.insert(self.Apps, { id = config.id, name = config.name, icon = config.icon, build = config.build, inDock = canDock })
	self:RebuildAll()
end

function SystemAPI.ToggleDockPin(self: any, appId: string)
	local dockCount = 0
	local target = nil
	for _, app in self.Apps do
		if app.inDock then dockCount += 1 end
		if app.id == appId then target = app end
	end
	if not target then return end

	if target.inDock then
		target.inDock = false
		Notify(target.name .. " aus Dock entfernt")
	else
		if dockCount >= MAX_DOCK_APPS then Notify("Dock voll!"); return end
		target.inDock = true
		Notify(target.name .. " zum Dock hinzugefuegt")
	end
	self:RebuildAll()
end

function SystemAPI.RebuildAll(self: any)
	if self.Dock then self.Dock:BuildDock() end
	if self.Launcher then self.Launcher:Build() end
end

function SystemAPI.ToggleLauncher(self: any)
	if self.Launcher then self.Launcher:Toggle() end
end

-- // ============================================================
-- // 11. BOOT SEQUENCE & EXPORTS (Ohne Default-Apps)
-- // ============================================================

local Gui = GuiLibrary.new()
local System = SystemAPI.new()
System:Init(Gui)
ApplyTheme("dark", false)

task.delay(0.5, function() Notify("AstraUI Loaded via GitHub!") end)

return {
	Gui = Gui,
	System = System,
	Notify = Notify,
	Themes = Themes,
	ApplyTheme = ApplyTheme
}
