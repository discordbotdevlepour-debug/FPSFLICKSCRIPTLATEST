--[[
	════════════════════════════════════════════════════════════════════
	 UN-AUTHORIZED — Cinematic Futuristic Menu System
	════════════════════════════════════════════════════════════════════

	SETUP:
	  1. Place this script as a LocalScript inside StarterGui.
	  2. Everything below is built procedurally at runtime — no images,
	     decals, or external assets are required.
	  3. All tunable values live in the CONFIG table directly below.

	FLOW:
	  MAIN MENU  --(CHECK pressed)-->  CHECKING  -->  404/ERROR  -->  MAIN MENU
	  LINK button = placeholder "copy link" action (shows COPIED toast).

	Organized into: CONFIG → HELPERS → LAYERED BACKGROUND FX →
	MAIN MENU UI → CHECKING UI → ERROR UI → STATE MACHINE → INPUT WIRING
	════════════════════════════════════════════════════════════════════
]]

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

----------------------------------------------------------------------
-- CONFIG  ── change anything here ──
----------------------------------------------------------------------
local CONFIG = {

	MainTitle = "UN-AUTHORIZED",
	Subtitle  = "You need to follow the creator of this game to continue.",

	CheckButtonText = "CHECK",
	LinkButtonText  = "LINK",

	-- I will change this later. Do not hard-code the real link elsewhere.
	PlaceholderLink = "PLACEHOLDER",

	CheckingTitle    = "CHECKING",
	CheckingSubtitle = "Our API is Finding It In your follow list! If it doesn't work Try following with the link!",

	CheckingStatusLines = {
		"ESTABLISHING SECURE LINK...",
		"QUERYING FOLLOW DATABASE...",
		"CROSS-REFERENCING USER ID...",
		"VALIDATING RESPONSE...",
	},

	ErrorTitle       = "NOT FOUND IN FOLLOWLIST!",
	ErrorExplanation = "We couldn't find you in the creator's follow list. Make sure you're following, then press CHECK again — or use LINK below to follow instantly.",

	Durations = {
		Transition     = 0.85,   -- cinematic wipe transition length
		CheckingHold   = 4.5,    -- how long the checking screen plays
		ErrorHold      = 4.4,    -- how long the error screen plays
		GlitchInterval = 1.2,    -- time between periodic re-glitch pulses on the error title
		ButtonHover    = 0.16,
		ButtonPress    = 0.08,
		CopiedToast    = 1.6,
		TitlePulse     = 2.6,
	},

	Colors = {
		Background  = Color3.fromRGB(5, 7, 12),
		Background2 = Color3.fromRGB(11, 15, 26),
		Accent      = Color3.fromRGB(70, 195, 255),
		AccentDim   = Color3.fromRGB(34, 90, 122),
		Danger      = Color3.fromRGB(255, 68, 92),
		DangerDim   = Color3.fromRGB(110, 30, 44),
		DangerBright = Color3.fromRGB(255, 145, 130),
		DangerWash  = Color3.fromRGB(28, 6, 10),
		White       = Color3.fromRGB(235, 245, 255),
		Muted       = Color3.fromRGB(140, 162, 188),
	},

	Rockets = {
		Count      = 3,
		SpeedRange = {4.5, 7.5},       -- seconds to cross the screen
		Size       = UDim2.new(0, 44, 0, 8),
		TrailEvery = 0.045,             -- seconds between trail puffs
	},

	Particles = {
		Count = 34,
	},

	LightStreaks = {
		Count = 4,
	},
}

----------------------------------------------------------------------
-- HELPERS
----------------------------------------------------------------------
local function create(className, props, children)
	local inst = Instance.new(className)
	if props then
		for k, v in pairs(props) do
			inst[k] = v
		end
	end
	if children then
		for _, c in ipairs(children) do
			c.Parent = inst
		end
	end
	return inst
end

local function corner(radius)
	return create("UICorner", { CornerRadius = radius or UDim.new(0, 12) })
end

local function stroke(color, thickness, transparency)
	return create("UIStroke", {
		Color = color or CONFIG.Colors.Accent,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function tween(inst, info, props, playImmediately)
	local t = TweenService:Create(inst, info, props)
	if playImmediately ~= false then
		t:Play()
	end
	return t
end

local function ease(duration, style, direction)
	return TweenInfo.new(duration, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out)
end

local function rand(a, b)
	return a + math.random() * (b - a)
end

----------------------------------------------------------------------
-- ROOT
----------------------------------------------------------------------
local oldGui = playerGui:FindFirstChild("UnauthorizedUI")
if oldGui then oldGui:Destroy() end

local screenGui = create("ScreenGui", {
	Name = "UnauthorizedUI",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 50,
	Parent = playerGui,
})

local root = create("Frame", {
	Name = "Root",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = CONFIG.Colors.Background,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Parent = screenGui,
})

----------------------------------------------------------------------
-- LAYERED BACKGROUND FX
----------------------------------------------------------------------

-- Base gradient backdrop (slowly rotating hue for a living feel)
local bgGradient = create("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, CONFIG.Colors.Background2),
		ColorSequenceKeypoint.new(0.5, CONFIG.Colors.Background),
		ColorSequenceKeypoint.new(1, CONFIG.Colors.Background2),
	}),
	Rotation = 0,
	Parent = root,
})

task.spawn(function()
	while root.Parent do
		tween(bgGradient, ease(14, Enum.EasingStyle.Linear), { Rotation = bgGradient.Rotation + 360 })
		task.wait(14)
	end
end)

-- Procedural grid overlay (no image assets needed)
local gridLayer = create("Frame", {
	Name = "Grid",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	ZIndex = 2,
	Parent = root,
})

for i = 1, 11 do
	create("Frame", {
		Size = UDim2.new(0, 1, 1, 0),
		Position = UDim2.new(i / 12, 0, 0, 0),
		BackgroundColor3 = CONFIG.Colors.AccentDim,
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
		Parent = gridLayer,
	})
end
for i = 1, 7 do
	create("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, i / 8, 0),
		BackgroundColor3 = CONFIG.Colors.AccentDim,
		BackgroundTransparency = 0.94,
		BorderSizePixel = 0,
		Parent = gridLayer,
	})
end

-- Floating particle field
local particleLayer = create("Frame", {
	Name = "Particles",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	ZIndex = 3,
	Parent = root,
})

local function runParticle(p)
	while p.Parent do
		local startX = rand(0, 1)
		local dur = rand(5, 10)
		p.Position = UDim2.fromScale(startX, 1.08)
		p.BackgroundTransparency = 1
		tween(p, ease(0.6, Enum.EasingStyle.Sine), { BackgroundTransparency = rand(0.4, 0.75) })
		local t = tween(p, ease(dur, Enum.EasingStyle.Linear), {
			Position = UDim2.fromScale(startX + rand(-0.05, 0.05), -0.08),
		})
		t.Completed:Wait()
	end
end

for i = 1, CONFIG.Particles.Count do
	local size = rand(2, 4)
	local p = create("Frame", {
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = CONFIG.Colors.Accent,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		Parent = particleLayer,
	}, { corner(UDim.new(1, 0)) })
	task.spawn(runParticle, p)
end

-- Moving diagonal light streaks
local streakLayer = create("Frame", {
	Name = "Streaks",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	ZIndex = 4,
	Parent = root,
})

local function runStreak(s)
	while s.Parent do
		s.Position = UDim2.fromScale(-0.3, rand(0, 1))
		local t = tween(s, ease(rand(3, 5), Enum.EasingStyle.Sine), {
			Position = UDim2.fromScale(1.3, s.Position.Y.Scale + rand(-0.05, 0.05)),
		})
		task.wait(rand(2, 5))
		t.Completed:Wait()
	end
end

for i = 1, CONFIG.LightStreaks.Count do
	local s = create("Frame", {
		Size = UDim2.new(0, 260, 0, 2),
		Rotation = 18,
		BackgroundColor3 = CONFIG.Colors.Accent,
		BorderSizePixel = 0,
		Parent = streakLayer,
	})
	create("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.55),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = s,
	})
	task.spawn(runStreak, s)
end

-- Horizontal scanline sweep
local scanline = create("Frame", {
	Size = UDim2.new(1, 0, 0, 3),
	Position = UDim2.fromScale(0, -0.05),
	BackgroundColor3 = CONFIG.Colors.Accent,
	BackgroundTransparency = 0.55,
	BorderSizePixel = 0,
	ZIndex = 5,
	Parent = root,
})
create("UIGradient", {
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	}),
	Parent = scanline,
})

task.spawn(function()
	while root.Parent do
		scanline.Position = UDim2.fromScale(0, -0.05)
		local t = tween(scanline, ease(3.2, Enum.EasingStyle.Linear), { Position = UDim2.fromScale(0, 1.05) })
		t.Completed:Wait()
		task.wait(0.4)
	end
end)

----------------------------------------------------------------------
-- SCREENS CONTAINER
----------------------------------------------------------------------
local screens = create("Frame", {
	Name = "Screens",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	ZIndex = 10,
	Parent = root,
})

local function screenFrame(name)
	return create("Frame", {
		Name = name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 10,
		Parent = screens,
	})
end

----------------------------------------------------------------------
-- REUSABLE: BIG BUTTON
----------------------------------------------------------------------
local function bigButton(text, accentColor, layoutOrder)
	local holder = create("Frame", {
		Size = UDim2.new(0, 260, 0, 64),
		BackgroundTransparency = 1,
		LayoutOrder = layoutOrder,
	})

	local btn = create("TextButton", {
		Name = "Button",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = CONFIG.Colors.Background2,
		AutoButtonColor = false,
		Text = "",
		Parent = holder,
	}, {
		corner(UDim.new(0, 10)),
		stroke(accentColor, 1.4, 0.25),
		create("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 24, 34)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 13, 20)),
			}),
			Rotation = 90,
		}),
	})

	local label = create("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = text,
		Font = Enum.Font.GothamBlack,
		TextSize = 22,
		TextColor3 = CONFIG.Colors.White,
		TextTransparency = 0,
		ZIndex = 2,
		Parent = btn,
	})

	local glowStroke = btn:FindFirstChildOfClass("UIStroke")

	btn.MouseEnter:Connect(function()
		tween(btn, ease(CONFIG.Durations.ButtonHover, Enum.EasingStyle.Quad), {
			BackgroundColor3 = Color3.fromRGB(20, 28, 40),
		})
		tween(glowStroke, ease(CONFIG.Durations.ButtonHover, Enum.EasingStyle.Quad), {
			Transparency = 0, Thickness = 2,
		})
		tween(holder, ease(CONFIG.Durations.ButtonHover, Enum.EasingStyle.Back), {
			Size = UDim2.new(0, 270, 0, 68),
		})
	end)

	btn.MouseLeave:Connect(function()
		tween(btn, ease(CONFIG.Durations.ButtonHover, Enum.EasingStyle.Quad), {
			BackgroundColor3 = CONFIG.Colors.Background2,
		})
		tween(glowStroke, ease(CONFIG.Durations.ButtonHover, Enum.EasingStyle.Quad), {
			Transparency = 0.25, Thickness = 1.4,
		})
		tween(holder, ease(CONFIG.Durations.ButtonHover, Enum.EasingStyle.Quad), {
			Size = UDim2.new(0, 260, 0, 64),
		})
	end)

	btn.MouseButton1Down:Connect(function()
		tween(holder, ease(CONFIG.Durations.ButtonPress, Enum.EasingStyle.Quad), {
			Size = UDim2.new(0, 250, 0, 60),
		})
	end)

	btn.MouseButton1Up:Connect(function()
		tween(holder, ease(CONFIG.Durations.ButtonPress, Enum.EasingStyle.Quad), {
			Size = UDim2.new(0, 270, 0, 68),
		})
	end)

	return holder, btn
end

----------------------------------------------------------------------
-- MAIN MENU
----------------------------------------------------------------------
local mainScreen = screenFrame("MainMenu")
mainScreen.Visible = true

local titleWrap = create("Frame", {
	Size = UDim2.new(0, 900, 0, 140),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.38),
	BackgroundTransparency = 1,
	Parent = mainScreen,
})

-- glow copy behind main title
local titleGlow = create("TextLabel", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Text = CONFIG.MainTitle,
	Font = Enum.Font.GothamBlack,
	TextSize = 62,
	TextColor3 = CONFIG.Colors.Accent,
	TextTransparency = 0.55,
	ZIndex = 1,
	Parent = titleWrap,
})
create("UIStroke", { Color = CONFIG.Colors.Accent, Thickness = 4, Transparency = 0.6, Parent = titleGlow })

local titleLabel = create("TextLabel", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Text = CONFIG.MainTitle,
	Font = Enum.Font.GothamBlack,
	TextSize = 62,
	TextColor3 = CONFIG.Colors.White,
	ZIndex = 2,
	Parent = titleWrap,
})

task.spawn(function()
	while mainScreen.Parent do
		tween(titleGlow, ease(CONFIG.Durations.TitlePulse, Enum.EasingStyle.Sine), { TextTransparency = 0.8 })
		task.wait(CONFIG.Durations.TitlePulse)
		tween(titleGlow, ease(CONFIG.Durations.TitlePulse, Enum.EasingStyle.Sine), { TextTransparency = 0.45 })
		task.wait(CONFIG.Durations.TitlePulse)
	end
end)

local subtitleLabel = create("TextLabel", {
	Size = UDim2.new(0, 640, 0, 50),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.49),
	BackgroundTransparency = 1,
	Text = CONFIG.Subtitle,
	Font = Enum.Font.Gotham,
	TextWrapped = true,
	TextSize = 16,
	TextColor3 = CONFIG.Colors.Muted,
	Parent = mainScreen,
})

local buttonRow = create("Frame", {
	Size = UDim2.new(0, 560, 0, 68),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.66),
	BackgroundTransparency = 1,
	Parent = mainScreen,
}, {
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 40),
	}),
})

local checkHolder, checkButton = bigButton(CONFIG.CheckButtonText, CONFIG.Colors.Accent, 1)
checkHolder.Parent = buttonRow
local linkHolder, linkButton = bigButton(CONFIG.LinkButtonText, CONFIG.Colors.Muted, 2)
linkHolder.Parent = buttonRow

-- COPIED toast
local copiedToast = create("TextLabel", {
	Size = UDim2.new(0, 140, 0, 34),
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 1, 8),
	BackgroundColor3 = CONFIG.Colors.Background2,
	Text = "COPIED",
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	TextColor3 = CONFIG.Colors.Accent,
	TextTransparency = 1,
	BackgroundTransparency = 1,
	ZIndex = 5,
	Parent = linkHolder,
}, { corner(UDim.new(0, 8)), stroke(CONFIG.Colors.Accent, 1, 0.3) })

local function showCopiedToast()
	copiedToast.Position = UDim2.new(0.5, 0, 1, 8)
	tween(copiedToast, ease(0.25, Enum.EasingStyle.Back), {
		TextTransparency = 0, BackgroundTransparency = 0.15, Position = UDim2.new(0.5, 0, 1, 14),
	})
	task.delay(CONFIG.Durations.CopiedToast, function()
		tween(copiedToast, ease(0.3, Enum.EasingStyle.Quad), {
			TextTransparency = 1, BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 1, 8),
		})
	end)
end

----------------------------------------------------------------------
-- CHECKING SCREEN
----------------------------------------------------------------------
local checkingScreen = screenFrame("Checking")

local checkingTitle = create("TextLabel", {
	Size = UDim2.new(0, 700, 0, 90),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.22),
	BackgroundTransparency = 1,
	Text = CONFIG.CheckingTitle,
	Font = Enum.Font.GothamBlack,
	TextSize = 48,
	TextColor3 = CONFIG.Colors.White,
	Parent = checkingScreen,
}, { stroke(CONFIG.Colors.Accent, 1.5, 0.5) })

local checkingSubtitle = create("TextLabel", {
	Size = UDim2.new(0, 600, 0, 50),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.3),
	BackgroundTransparency = 1,
	Text = CONFIG.CheckingSubtitle,
	Font = Enum.Font.Gotham,
	TextWrapped = true,
	TextSize = 14,
	TextColor3 = CONFIG.Colors.Muted,
	Parent = checkingScreen,
})

-- Orbital rings
local orbitCenter = create("Frame", {
	Size = UDim2.fromOffset(1, 1),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.58),
	BackgroundTransparency = 1,
	Parent = checkingScreen,
})

local ringSizes = {200, 260, 320}
local ringSpeeds = {6, 9, 13}
for i, sz in ipairs(ringSizes) do
	local ring = create("Frame", {
		Size = UDim2.fromOffset(sz, sz),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 1,
		Parent = orbitCenter,
	}, { corner(UDim.new(1, 0)), stroke(CONFIG.Colors.Accent, 1, 0.75 - i * 0.1) })

	task.spawn(function()
		while checkingScreen.Parent do
			tween(ring, ease(ringSpeeds[i], Enum.EasingStyle.Linear), { Rotation = ring.Rotation + 360 })
			task.wait(ringSpeeds[i])
		end
	end)
end

-- Progress bar + percentage
local progressTrack = create("Frame", {
	Size = UDim2.new(0, 420, 0, 8),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.82),
	BackgroundColor3 = CONFIG.Colors.Background2,
	Parent = checkingScreen,
}, { corner(UDim.new(1, 0)), stroke(CONFIG.Colors.AccentDim, 1, 0.4) })

local progressFill = create("Frame", {
	Size = UDim2.new(0, 0, 1, 0),
	BackgroundColor3 = CONFIG.Colors.Accent,
	Parent = progressTrack,
}, { corner(UDim.new(1, 0)) })

local percentLabel = create("TextLabel", {
	Size = UDim2.new(0, 420, 0, 24),
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.845),
	BackgroundTransparency = 1,
	Text = "0%",
	Font = Enum.Font.Code,
	TextSize = 14,
	TextColor3 = CONFIG.Colors.Accent,
	Parent = checkingScreen,
})

local statusLabel = create("TextLabel", {
	Size = UDim2.new(0, 500, 0, 22),
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.88),
	BackgroundTransparency = 1,
	Text = "",
	Font = Enum.Font.Code,
	TextSize = 13,
	TextColor3 = CONFIG.Colors.Muted,
	Parent = checkingScreen,
})

-- Rockets (built from primitives, not emoji)
local rocketLayer = create("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Parent = checkingScreen,
})

local rocketsActive = false

local function spawnRocketTrail(x, y)
	local puff = create("Frame", {
		Size = UDim2.fromOffset(6, 6),
		Position = UDim2.fromScale(x, y),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = CONFIG.Colors.Accent,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Parent = rocketLayer,
	}, { corner(UDim.new(1, 0)) })
	local t = tween(puff, ease(0.5, Enum.EasingStyle.Quad), {
		Size = UDim2.fromOffset(1, 1), BackgroundTransparency = 1,
	})
	t.Completed:Connect(function() puff:Destroy() end)
end

local function runRocket(index)
	while rocketsActive do
		local fromLeft = math.random() > 0.5
		local startX = fromLeft and -0.1 or 1.1
		local endX = fromLeft and 1.1 or -0.1
		local y0 = rand(0.15, 0.85)
		local y1 = y0 + rand(-0.25, 0.25)
		local angle = math.deg(math.atan2(y1 - y0, endX - startX))

		local rocket = create("Frame", {
			Size = CONFIG.Rockets.Size,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(startX, y0),
			Rotation = angle,
			BackgroundColor3 = CONFIG.Colors.White,
			BorderSizePixel = 0,
			Parent = rocketLayer,
		}, {
			corner(UDim.new(1, 0)),
			create("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, CONFIG.Colors.Accent),
					ColorSequenceKeypoint.new(1, CONFIG.Colors.White),
				}),
			}),
		})
		create("UIStroke", { Color = CONFIG.Colors.Accent, Thickness = 1.2, Transparency = 0.2, Parent = rocket })

		local duration = rand(CONFIG.Rockets.SpeedRange[1], CONFIG.Rockets.SpeedRange[2])
		local elapsed = 0
		local trailAcc = 0
		local conn
		conn = RunService.Heartbeat:Connect(function(dt)
			if not rocket.Parent then return end
			elapsed += dt
			trailAcc += dt
			local alpha = math.clamp(elapsed / duration, 0, 1)
			local x = startX + (endX - startX) * alpha
			local y = y0 + (y1 - y0) * alpha
			rocket.Position = UDim2.fromScale(x, y)
			if trailAcc >= CONFIG.Rockets.TrailEvery then
				trailAcc = 0
				spawnRocketTrail(x - math.cos(math.rad(angle)) * 0.02, y - math.sin(math.rad(angle)) * 0.02)
			end
			if alpha >= 1 then
				conn:Disconnect()
			end
		end)

		task.wait(duration)
		rocket:Destroy()
		task.wait(rand(0.3, 1.2))
	end
end

-- Data readout particles (HUD-style)
local function spawnDataBit()
	if not checkingScreen.Visible then return end
	local chars = "01ABCDEF#$%"
	local txt = ""
	for i = 1, math.random(3, 6) do
		txt = txt .. string.sub(chars, math.random(1, #chars), math.random(1, #chars))
	end
	local lbl = create("TextLabel", {
		Size = UDim2.fromOffset(80, 16),
		Position = UDim2.fromScale(rand(0.05, 0.95), rand(0.1, 0.9)),
		BackgroundTransparency = 1,
		Text = txt,
		Font = Enum.Font.Code,
		TextSize = 12,
		TextColor3 = CONFIG.Colors.Accent,
		TextTransparency = 0.3,
		Parent = rocketLayer,
	})
	local t = tween(lbl, ease(0.9, Enum.EasingStyle.Quad), { TextTransparency = 1 })
	t.Completed:Connect(function() lbl:Destroy() end)
end

----------------------------------------------------------------------
-- ERROR / 404 SCREEN — red-themed space
----------------------------------------------------------------------
local errorScreen = screenFrame("Error")
local errorActive = false

-- red space wash (sits behind everything else on this screen)
local errorWash = create("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = CONFIG.Colors.DangerWash,
	BackgroundTransparency = 0.15,
	BorderSizePixel = 0,
	ZIndex = 1,
	Parent = errorScreen,
})
create("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, CONFIG.Colors.DangerWash),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(46, 10, 16)),
		ColorSequenceKeypoint.new(1, CONFIG.Colors.DangerWash),
	}),
	Rotation = 90,
	Parent = errorWash,
})

-- soft red glow behind the cross
local errorGlow = create("Frame", {
	Size = UDim2.fromOffset(560, 560),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.58),
	BackgroundColor3 = CONFIG.Colors.Danger,
	BackgroundTransparency = 0.9,
	BorderSizePixel = 0,
	ZIndex = 1,
	Parent = errorScreen,
}, { corner(UDim.new(1, 0)) })

task.spawn(function()
	while errorScreen.Parent do
		if errorActive then
			tween(errorGlow, ease(2.4, Enum.EasingStyle.Sine), { BackgroundTransparency = 0.82 })
			task.wait(2.4)
			tween(errorGlow, ease(2.4, Enum.EasingStyle.Sine), { BackgroundTransparency = 0.92 })
			task.wait(2.4)
		else
			task.wait(0.3)
		end
	end
end)

-- red starfield, only alive while this screen is showing
local errorStars = create("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	ZIndex = 2,
	Parent = errorScreen,
})

local function runErrorStar(star)
	while star.Parent do
		if errorActive then
			local x = rand(0, 1)
			star.Position = UDim2.fromScale(x, rand(0, 1))
			star.BackgroundTransparency = 1
			tween(star, ease(0.4, Enum.EasingStyle.Sine), { BackgroundTransparency = rand(0.2, 0.6) })
			task.wait(rand(1.2, 3))
			tween(star, ease(0.6, Enum.EasingStyle.Sine), { BackgroundTransparency = 1 })
			task.wait(rand(0.2, 0.6))
		else
			task.wait(0.3)
		end
	end
end

for i = 1, 26 do
	local sz = rand(1, 3)
	local star = create("Frame", {
		Size = UDim2.fromOffset(sz, sz),
		BackgroundColor3 = math.random() > 0.4 and CONFIG.Colors.White or CONFIG.Colors.Danger,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		Parent = errorStars,
	}, { corner(UDim.new(1, 0)) })
	task.spawn(runErrorStar, star)
end

-- title (glitch RGB-split, stays on one fixed message)
local errorTitleWrap = create("Frame", {
	Size = UDim2.new(0, 900, 0, 110),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.28),
	BackgroundTransparency = 1,
	ZIndex = 4,
	Parent = errorScreen,
})

local errorGhostA = create("TextLabel", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Text = CONFIG.ErrorTitle,
	Font = Enum.Font.GothamBlack,
	TextSize = 40,
	TextColor3 = CONFIG.Colors.Danger,
	TextTransparency = 0.5,
	TextWrapped = true,
	ZIndex = 1,
	Parent = errorTitleWrap,
})
local errorGhostB = create("TextLabel", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Text = CONFIG.ErrorTitle,
	Font = Enum.Font.GothamBlack,
	TextSize = 40,
	TextColor3 = CONFIG.Colors.DangerBright,
	TextTransparency = 0.5,
	TextWrapped = true,
	ZIndex = 1,
	Parent = errorTitleWrap,
})
local errorMain = create("TextLabel", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Text = CONFIG.ErrorTitle,
	Font = Enum.Font.GothamBlack,
	TextSize = 40,
	TextColor3 = CONFIG.Colors.White,
	TextWrapped = true,
	ZIndex = 2,
	Parent = errorTitleWrap,
}, { stroke(CONFIG.Colors.Danger, 1.2, 0.55) })

-- big cross beneath the title
local crossHolder = create("Frame", {
	Size = UDim2.fromOffset(130, 130),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.52),
	BackgroundTransparency = 1,
	ZIndex = 3,
	Parent = errorScreen,
})

local function crossBar(rotation, big)
	return create("Frame", {
		Size = big and UDim2.new(0, 160, 0, 22) or UDim2.new(0, 140, 0, 14),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Rotation = rotation,
		BackgroundColor3 = CONFIG.Colors.Danger,
		BackgroundTransparency = big and 0.75 or 0,
		BorderSizePixel = 0,
		Parent = crossHolder,
	}, { corner(UDim.new(1, 0)) })
end

-- soft glow bars behind
crossBar(45, true)
crossBar(-45, true)
-- crisp bars on top
local crossFront1 = crossBar(45, false)
local crossFront2 = crossBar(-45, false)
create("UIStroke", { Color = CONFIG.Colors.White, Thickness = 1, Transparency = 0.4, Parent = crossFront1 })
create("UIStroke", { Color = CONFIG.Colors.White, Thickness = 1, Transparency = 0.4, Parent = crossFront2 })

task.spawn(function()
	while crossHolder.Parent do
		if errorActive then
			tween(crossHolder, ease(1.4, Enum.EasingStyle.Sine), { Size = UDim2.fromOffset(140, 140) })
			task.wait(1.4)
			tween(crossHolder, ease(1.4, Enum.EasingStyle.Sine), { Size = UDim2.fromOffset(126, 126) })
			task.wait(1.4)
		else
			task.wait(0.3)
		end
	end
end)

-- explanation text below the cross
local errorSubLabel = create("TextLabel", {
	Size = UDim2.new(0, 560, 0, 60),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.7),
	BackgroundTransparency = 1,
	Text = CONFIG.ErrorExplanation,
	Font = Enum.Font.Gotham,
	TextWrapped = true,
	TextSize = 14,
	TextColor3 = CONFIG.Colors.Muted,
	ZIndex = 4,
	Parent = errorScreen,
})

local errorStatusLabel = create("TextLabel", {
	Size = UDim2.new(0, 400, 0, 20),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.8),
	BackgroundTransparency = 1,
	Text = "SYSTEM WILL RETRY AUTOMATICALLY",
	Font = Enum.Font.Code,
	TextSize = 12,
	TextColor3 = CONFIG.Colors.Danger,
	ZIndex = 4,
	Parent = errorScreen,
})

-- fragmentation flicker blocks (pure red theme)
local fragLayer = create("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	ZIndex = 5,
	Parent = errorScreen,
})

local function fragBurst()
	for i = 1, 10 do
		local w = rand(20, 140)
		local h = rand(3, 10)
		local block = create("Frame", {
			Size = UDim2.fromOffset(w, h),
			Position = UDim2.fromScale(rand(0.1, 0.9), rand(0.2, 0.4)),
			BackgroundColor3 = math.random() > 0.5 and CONFIG.Colors.Danger or CONFIG.Colors.White,
			BackgroundTransparency = rand(0.3, 0.7),
			BorderSizePixel = 0,
			Parent = fragLayer,
		})
		task.delay(rand(0.06, 0.2), function()
			block:Destroy()
		end)
	end
end

-- re-glitches the (unchanging) title text for a jittery, alive feel
local function glitchPulse()
	fragBurst()
	for i = 1, 6 do
		errorGhostA.Position = UDim2.fromOffset(rand(-6, 6), rand(-3, 3))
		errorGhostB.Position = UDim2.fromOffset(rand(-6, 6), rand(-3, 3))
		errorMain.Position = UDim2.fromOffset(rand(-2, 2), 0)
		task.wait(0.035)
	end
	tween(errorGhostA, ease(0.2, Enum.EasingStyle.Quad), { Position = UDim2.fromOffset(-3, 0) })
	tween(errorGhostB, ease(0.2, Enum.EasingStyle.Quad), { Position = UDim2.fromOffset(3, 0) })
	tween(errorMain, ease(0.2, Enum.EasingStyle.Quad), { Position = UDim2.fromOffset(0, 0) })
end

----------------------------------------------------------------------
-- CINEMATIC TRANSITION (expanding panels + streak wipe)
----------------------------------------------------------------------
local transitionLayer = create("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	ZIndex = 50,
	Parent = root,
})

local panelLeft = create("Frame", {
	Size = UDim2.new(0.5, 0, 1, 0),
	Position = UDim2.fromScale(0, 0),
	BackgroundColor3 = CONFIG.Colors.Background,
	BorderSizePixel = 0,
	Visible = false,
	Parent = transitionLayer,
})
create("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, CONFIG.Colors.Background),
		ColorSequenceKeypoint.new(1, CONFIG.Colors.Background2),
	}),
	Rotation = 90,
	Parent = panelLeft,
})

local panelRight = create("Frame", {
	Size = UDim2.new(0.5, 0, 1, 0),
	Position = UDim2.fromScale(0.5, 0),
	BackgroundColor3 = CONFIG.Colors.Background,
	BorderSizePixel = 0,
	Visible = false,
	Parent = transitionLayer,
})
create("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, CONFIG.Colors.Background2),
		ColorSequenceKeypoint.new(1, CONFIG.Colors.Background),
	}),
	Rotation = 90,
	Parent = panelRight,
})

local sweepStreak = create("Frame", {
	Size = UDim2.new(0, 6, 1, 0),
	Position = UDim2.fromScale(0.5, 0),
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundColor3 = CONFIG.Colors.Accent,
	BackgroundTransparency = 0.2,
	BorderSizePixel = 0,
	Visible = false,
	Parent = transitionLayer,
})

-- covers screen, runs `mid()` while covered, then uncovers
local function cinematicTransition(mid)
	local d = CONFIG.Durations.Transition
	panelLeft.Visible = true
	panelRight.Visible = true
	sweepStreak.Visible = true
	panelLeft.Position = UDim2.fromScale(-1, 0)
	panelRight.Position = UDim2.fromScale(1.5, 0)
	sweepStreak.Position = UDim2.fromScale(0.5, 0)
	sweepStreak.Size = UDim2.new(0, 6, 1, 0)

	local t1 = tween(panelLeft, ease(d * 0.55, Enum.EasingStyle.Exponential), { Position = UDim2.fromScale(0, 0) })
	local t2 = tween(panelRight, ease(d * 0.55, Enum.EasingStyle.Exponential), { Position = UDim2.fromScale(0.5, 0) })
	tween(sweepStreak, ease(d * 0.5, Enum.EasingStyle.Quad), { Size = UDim2.new(0, 40, 1, 0) })
	t1.Completed:Wait()

	if mid then
		-- pcall so a bug in the callback can never leave the wipe panels
		-- permanently covering the screen
		local ok, err = pcall(mid)
		if not ok then
			warn("[UnauthorizedUI] transition mid-callback error:", err)
		end
	end
	task.wait(d * 0.12)

	tween(sweepStreak, ease(0.25, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 })
	local t3 = tween(panelLeft, ease(d * 0.55, Enum.EasingStyle.Exponential), { Position = UDim2.fromScale(-1, 0) })
	local t4 = tween(panelRight, ease(d * 0.55, Enum.EasingStyle.Exponential), { Position = UDim2.fromScale(1.5, 0) })
	t3.Completed:Wait()

	panelLeft.Visible = false
	panelRight.Visible = false
	sweepStreak.Visible = false
	sweepStreak.BackgroundTransparency = 0.2
end

----------------------------------------------------------------------
-- STATE MACHINE
----------------------------------------------------------------------
local function hideAllScreens()
	mainScreen.Visible = false
	checkingScreen.Visible = false
	errorScreen.Visible = false
	errorActive = false
end

local function enterMain()
	hideAllScreens()
	mainScreen.Visible = true
end

local function enterChecking()
	hideAllScreens()
	checkingScreen.Visible = true
	progressFill.Size = UDim2.new(0, 0, 1, 0)
	percentLabel.Text = "0%"

	rocketsActive = true
	for i = 1, CONFIG.Rockets.Count do
		task.spawn(runRocket, i)
	end

	task.spawn(function()
		while checkingScreen.Visible and rocketsActive do
			spawnDataBit()
			task.wait(rand(0.12, 0.3))
		end
	end)

	tween(progressFill, ease(CONFIG.Durations.CheckingHold, Enum.EasingStyle.Sine), {
		Size = UDim2.new(1, 0, 1, 0),
	})

	task.spawn(function()
		local elapsed = 0
		local conn
		conn = RunService.Heartbeat:Connect(function(dt)
			if not checkingScreen.Visible then
				conn:Disconnect()
				return
			end
			elapsed += dt
			local pct = math.clamp(math.floor((elapsed / CONFIG.Durations.CheckingHold) * 100), 0, 99)
			percentLabel.Text = pct .. "%"
			if elapsed >= CONFIG.Durations.CheckingHold then
				conn:Disconnect()
			end
		end)
	end)

	task.spawn(function()
		local i = 0
		while checkingScreen.Visible do
			i = (i % #CONFIG.CheckingStatusLines) + 1
			statusLabel.TextTransparency = 1
			statusLabel.Text = CONFIG.CheckingStatusLines[i]
			tween(statusLabel, ease(0.3, Enum.EasingStyle.Quad), { TextTransparency = 0 })
			task.wait(CONFIG.Durations.CheckingHold / #CONFIG.CheckingStatusLines)
		end
	end)
end

local function exitChecking()
	rocketsActive = false
	percentLabel.Text = "100%"
end

local function enterError()
	hideAllScreens()
	errorScreen.Visible = true
	errorActive = true
	glitchPulse()

	task.spawn(function()
		local elapsed = 0
		while errorScreen.Visible and errorActive and elapsed < CONFIG.Durations.ErrorHold do
			task.wait(CONFIG.Durations.GlitchInterval)
			elapsed += CONFIG.Durations.GlitchInterval
			if not (errorScreen.Visible and errorActive) then break end
			glitchPulse()
		end
	end)
end

local function exitError()
	errorActive = false
end

----------------------------------------------------------------------
-- CHECK BUTTON SEQUENCE
----------------------------------------------------------------------
local sequenceRunning = false

local function setCheckEnabled(enabled)
	checkButton.Active = enabled
	local uiStroke = checkButton:FindFirstChildOfClass("UIStroke")
	tween(checkHolder, ease(0.2), { BackgroundTransparency = enabled and 0 or 1 })
	if uiStroke then
		tween(uiStroke, ease(0.2), { Transparency = enabled and 0.25 or 0.8 })
	end
	local lbl = checkButton:FindFirstChildOfClass("TextLabel")
	if lbl then
		tween(lbl, ease(0.2), { TextTransparency = enabled and 0 or 0.55 })
	end
end

local function runCheckSequence()
	if sequenceRunning then return end
	sequenceRunning = true
	setCheckEnabled(false)

	cinematicTransition(function()
		enterChecking()
	end)

	task.wait(CONFIG.Durations.CheckingHold)
	exitChecking()

	cinematicTransition(function()
		enterError()
	end)

	task.wait(CONFIG.Durations.ErrorHold)
	exitError()

	cinematicTransition(function()
		enterMain()
	end)

	setCheckEnabled(true)
	sequenceRunning = false
end

----------------------------------------------------------------------
-- INPUT WIRING
----------------------------------------------------------------------
checkButton.MouseButton1Click:Connect(function()
	task.spawn(runCheckSequence)
end)

linkButton.MouseButton1Click:Connect(function()
	pcall(function()
		setclipboard(CONFIG.PlaceholderLink) -- luacheck: ignore (available in some client environments)
	end)
	showCopiedToast()
end)

-- Optional gamepad support: A = Check, X = Link (nice-to-have, non-intrusive)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if not mainScreen.Visible then return end
	if input.KeyCode == Enum.KeyCode.ButtonA then
		task.spawn(runCheckSequence)
	elseif input.KeyCode == Enum.KeyCode.ButtonX then
		pcall(function() setclipboard(CONFIG.PlaceholderLink) end)
		showCopiedToast()
	end
end)

-- Entrance animation: title/subtitle/buttons ease in on first load
titleWrap.Position = UDim2.fromScale(0.5, 0.34)
titleLabel.TextTransparency = 1
titleGlow.TextTransparency = 1
subtitleLabel.TextTransparency = 1
buttonRow.Position = UDim2.fromScale(0.5, 0.72)

tween(titleWrap, ease(0.9, Enum.EasingStyle.Back), { Position = UDim2.fromScale(0.5, 0.38) })
tween(titleLabel, ease(0.7, Enum.EasingStyle.Sine), { TextTransparency = 0 })
tween(titleGlow, ease(0.7, Enum.EasingStyle.Sine), { TextTransparency = 0.45 })
task.delay(0.25, function()
	tween(subtitleLabel, ease(0.6, Enum.EasingStyle.Sine), { TextTransparency = 0 })
end)
task.delay(0.4, function()
	tween(buttonRow, ease(0.7, Enum.EasingStyle.Back), { Position = UDim2.fromScale(0.5, 0.66) })
end)
