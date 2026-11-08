local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Ali-lov3/SfixUiLib/refs/heads/main/Source.lua"))()

local window = library:window({
	name = "sfix",
	suffix = "tech",
	gameInfo = "Sfix for Roblox",
	AccentColor = Color3.fromRGB(66, 133, 255),
	ConfigFolder = "Sfix",
})

window:seperator({ name = "Home" })
window:home_manager({ name = "Home" })

window:seperator({ name = "General" })
local enemies, teammates, self_section = window:tab({ name = "Players", icon = "users", tabs = { "Enemies", "Teammates", "Self" } })
for _, tab in { enemies, teammates, self_section } do
	local column = tab:column({})
	local section = column:section({ name = "General", icon = "info", default = true })
	section:label({ name = "This is a title!", info = "Sections hold toggles, sliders, dropdowns, color pickers, textboxes, buttons, labels and lists." })

	local left = tab:column({})
	local esp_section = left:section({ name = "Example", icon = "user", default = true })
	esp_section:toggle({ name = "Enable ESP", seperator = true, callback = function(bool) print(bool) end })
	esp_section:toggle({ name = "Through walls", seperator = true })
	esp_section:toggle({ name = "Shared ESP", seperator = true }):colorpicker({})

	local name_toggle = esp_section:toggle({ name = "Name", seperator = true })
	name_toggle:colorpicker({})
	local sub_section = name_toggle:settings({})
	sub_section:toggle({ name = "Show Display Names", seperator = true })
	sub_section:dropdown({ name = "Font Name", items = { "ProggyTiny", "MonoSpace", "Tahoma" }, default = "MonoSpace", seperator = true })
	sub_section:colorpicker({ name = "Another Colorpicker" })

	esp_section:toggle({ name = "Weapon", seperator = true, info = "Shows the equipped tool." }):colorpicker({})
	esp_section:dropdown({ name = "Flags", items = { "Scoped", "Flashed", "Knocked", "Touched" }, default = { "Scoped", "Flashed" }, multi = true, seperator = true })
end

window:seperator({ name = "Options" })
local aimbot_page = window:tab({ name = "Aimbot", icon = "crosshair", tabs = { "Main" } })
local column = aimbot_page:column({})
local section = column:section({ name = "Aimbot", icon = "crosshair", default = true })

local aimbot = section:toggle({ name = "Enable Aimbot", seperator = true, flag = "aim_enable", callback = function(bool) print(bool) end })
local aimbot_options = aimbot:group({})
aimbot_options:slider({ name = "FOV", min = 0, max = 360, default = 90, suffix = "°", seperator = true, flag = "aim_fov" })
aimbot_options:slider({ name = "Smoothness", min = 0, max = 100, default = 20, suffix = "%", seperator = true, flag = "aim_smooth" })
aimbot_options:dropdown({ name = "Hitbox", items = { "Head", "Torso", "Legs" }, default = "Head", seperator = true, flag = "aim_hitbox" })
aimbot_options:dropdown({ name = "Checks", items = { "Visible", "Alive", "Team" }, default = { "Alive" }, multi = true, seperator = true, flag = "aim_checks" })
aimbot_options:toggle({ name = "Draw FOV", seperator = true, flag = "aim_drawfov" }):colorpicker({})

section:toggle({
	name = "Silent Aim",
	seperator = true,
	flag = "aim_silent",
	children = function(group)
		group:slider({ name = "Hit Chance", min = 0, max = 100, default = 75, suffix = "%", seperator = true, flag = "aim_hitchance" })
		group:dropdown({ name = "Target Part", items = { "Head", "Torso" }, default = "Head", seperator = true, flag = "aim_targetpart" })
	end,
})

local world_column = aimbot_page:column({})
local world = world_column:section({ name = "World", icon = "globe", default = true })
world:slider({ name = "FOV Changer", min = 30, max = 120, default = 70, flag = "world_fov", callback = function(value)
	Workspace.CurrentCamera.FieldOfView = value
end })
world:colorpicker({ name = "Ambient", color = Color3.fromRGB(120, 120, 140), flag = "world_ambient", callback = function(color)
	Lighting.Ambient = color
end })

local speed_enabled, speed_value = false, 16
local movement_column = aimbot_page:column({})
local movement = movement_column:section({ name = "Movement", icon = "zap", default = true })
movement:toggle({ name = "Speed", flag = "move_speed", callback = function(bool)
	speed_enabled = bool
	local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if humanoid and not bool then humanoid.WalkSpeed = 16 end
end })
movement:slider({ name = "Walk Speed", min = 16, max = 100, default = 16, flag = "move_walk", callback = function(value)
	speed_value = value
end })
RunService.Heartbeat:Connect(function()
	if not speed_enabled then return end
	local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid.WalkSpeed = speed_value end
end)

window:seperator({ name = "Visuals" })
local esp = window:esp_manager({
	name = "Esp",
	icon = "scan-eye",
	settings = {
		Enabled = { Value = true, Visible = true },

		Box = { Value = true, Visible = true },
		BoxGradient = { Value = false, Visible = true },
		BoxFill = { Value = false, Visible = true },

		Skeleton = { Value = false, Visible = true },
		SkeletonGradient = { Value = false, Visible = true },
		SkeletonColor = { Value = Color3.fromRGB(255, 255, 255), Visible = true },
		SkeletonThickness = { Value = 2, Visible = true },

		Dot = { Value = false, Visible = true },
		DotGradient = { Value = false, Visible = true },
		DotColor = { Value = Color3.fromRGB(255, 255, 255), Visible = true },
		DotSize = { Value = 8, Visible = true },

		Glow = { Value = false, Visible = true },
		GlowGradient = { Value = false, Visible = true },
		GlowColor = { Value = Color3.fromRGB(255, 80, 180), Visible = true },
		GlowTransparency = { Value = 0.4, Visible = true },

		Tracer = { Value = false, Visible = true },

		HealthBar = { Value = true, Visible = true },
		HealthBarGradient = { Value = false, Visible = true },

		HealthText = { Value = true, Visible = true },
		HealthTextGradient = { Value = false, Visible = true },

		Name = { Value = true, Visible = true },
		DisplayName = { Value = false, Visible = true },
		NameGradient = { Value = false, Visible = true },

		Avatar = { Value = false, Visible = true },

		Weapon = { Value = true, Visible = true },
		WeaponGradient = { Value = false, Visible = true },

		Backpack = { Value = false, Visible = true },
		BackpackGradient = { Value = false, Visible = false },

		Distance = { Value = true, Visible = true },
		DistanceGradient = { Value = false, Visible = true },

		GradientColor1 = { Value = Color3.fromRGB(255, 255, 255), Visible = true },
		GradientColor2 = { Value = Color3.fromRGB(255, 80, 180), Visible = true },

		GradientAnimation = { Value = false, Visible = true },
		GradientAnimationSpeed = { Value = 4, Visible = true },
	},
})

window:seperator({ name = "Players" })
local players_page = window:tab({ name = "Target", icon = "crosshair", tabs = { "Main" } })
local hud_column = players_page:column({})
local hud = hud_column:section({ name = "Target HUD", icon = "user", default = true })
hud:target_hud()
local list_column = players_page:column({})
local list = list_column:section({ name = "Player List", icon = "users", default = true })
list:player_list({ height = 200 })

library:init_config(window)

library:notify({ name = "Sfix", info = "Loaded successfully", duration = 5, icon = "check" })
