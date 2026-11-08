local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local Lucide
pcall(function()
	Lucide = loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/icons.lua"))()
end)

local function ResolveIcon(Icon)
	if type(Icon) == "number" then return "rbxassetid://" .. Icon end
	if type(Icon) == "string" then
		if string.match(Icon, "^rbxassetid://") then return Icon end
		if string.match(Icon, "^%d+$") then return "rbxassetid://" .. Icon end
		local Name = string.lower(Icon)
		if type(Lucide) == "function" then
			local ok, Data = pcall(Lucide, Name)
			if ok and type(Data) == "table" then
				local Id = Data.id or Data.Id or Data[1]
				local Size = Data.imageRectSize or Data.ImageRectSize or Data[2]
				local Offset = Data.imageRectOffset or Data.imageRectPosition or Data.ImageRectOffset or Data[3]
				if Id then return "rbxassetid://" .. tostring(Id), Offset, Size end
			end
		elseif type(Lucide) == "table" then
			for _, Set in { Lucide["48px"], Lucide["256px"], Lucide } do
				if type(Set) == "table" then
					local Data = Set[Name]
					if type(Data) == "table" and Data[1] then
						return "rbxassetid://" .. tostring(Data[1]), Data[3], Data[2]
					end
				end
			end
		end
	end
	return "rbxassetid://0"
end

local function ToVector2(Value)
	if typeof(Value) == "Vector2" then return Value end
	if type(Value) == "table" then return Vector2.new(Value[1] or Value.X or 0, Value[2] or Value.Y or 0) end
	return Vector2.new(0, 0)
end

local function ApplyIcon(Object, Icon)
	if not Icon then return end
	local Image, Offset, Size = ResolveIcon(Icon)
	Object.Image = Image
	if Offset then Object.ImageRectOffset = ToVector2(Offset) end
	if Size then Object.ImageRectSize = ToVector2(Size) end
end

local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)

local Theme = {
	Bg = Color3.fromRGB(13, 13, 19),
	Panel = Color3.fromRGB(19, 19, 26),
	Field = Color3.fromRGB(25, 25, 33),
	Border = Color3.fromRGB(44, 44, 58),
	Accent = Color3.fromRGB(66, 133, 255),
	AccentLight = Color3.fromRGB(105, 165, 255),
	AccentDark = Color3.fromRGB(36, 88, 210),
	Text = Color3.fromRGB(232, 232, 238),
	Dim = Color3.fromRGB(132, 132, 146),
	Font = Enum.Font.SourceSans,
	Bold = Enum.Font.SourceSansBold,
}

local Library = {
	flags = {},
	config_flags = {},
	scales = {},
	scale_mult = 1,
	popup = nil,
	target = nil,
	hooks = {},
	theme = Theme,
	flag_count = 0,
}

local ConfigManager = { Folder = "Sfix", Extension = ".cfg", Ignore = { config_name_text = true, config_name_list = true } }
Library.ConfigManager = ConfigManager

local function NextFlag()
	Library.flag_count += 1
	return "flag_" .. Library.flag_count
end

local function OnAccent(Fn)
	table.insert(Library.hooks, Fn)
	Fn()
end

local function New(Class, Props, Parent)
	local Object = Instance.new(Class)
	for K, V in pairs(Props) do Object[K] = V end
	if Parent then Object.Parent = Parent end
	return Object
end

local function Stroke(Object, Color, Thickness)
	return New("UIStroke", { Color = Color or Theme.Border, Thickness = Thickness or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, Object)
end

local function Grad(Object, A, B, Rot)
	return New("UIGradient", { Color = ColorSequence.new(A, B), Rotation = Rot or 90 }, Object)
end

local function AccentGrad(Object, Rot)
	local G = New("UIGradient", { Rotation = Rot or 90 }, Object)
	OnAccent(function() G.Color = ColorSequence.new(Theme.AccentLight, Theme.AccentDark) end)
	return G
end

local function Glow(Parent, Position, Height)
	local Line = New("Frame", { Size = UDim2.new(1, 0, 0, Height or 1), Position = Position, BackgroundColor3 = Theme.Accent, BorderSizePixel = 0 }, Parent)
	New("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }) }, Line)
	OnAccent(function() Line.BackgroundColor3 = Theme.Accent end)
	return Line
end

local function Label(Parent, Text, Props)
	local P = { BackgroundTransparency = 1, Text = Text, Font = Theme.Font, TextSize = 14, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left }
	for K, V in pairs(Props or {}) do P[K] = V end
	return New("TextLabel", P, Parent)
end

local function IsPress(Input)
	return Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch
end

local function IsMove(Input)
	return Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch
end

local function Dragger(Object, Callback)
	local Active = false
	Object.InputBegan:Connect(function(Input)
		if IsPress(Input) then
			Active = true
			Callback(Input.Position)
		end
	end)
	UIS.InputChanged:Connect(function(Input)
		if Active and IsMove(Input) then Callback(Input.Position) end
	end)
	UIS.InputEnded:Connect(function(Input)
		if IsPress(Input) then Active = false end
	end)
end

local function Register(Flag, Value, Setter)
	Library.flags[Flag] = Value
	Library.config_flags[Flag] = Setter
end

local function Styled(Button)
	Grad(Button, Color3.fromRGB(42, 42, 55), Color3.fromRGB(24, 24, 32))
	local S = Stroke(Button)
	Button.MouseEnter:Connect(function() S.Color = Theme.Accent end)
	Button.MouseLeave:Connect(function() S.Color = Theme.Border end)
	return S
end

local function BoxButton(Parent, Text, Size, Position)
	local Container = New("Frame", { Size = Size, Position = Position or UDim2.new(), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, Parent)
	Grad(Container, Color3.fromRGB(42, 42, 55), Color3.fromRGB(24, 24, 32))
	local S = Stroke(Container)
	local Button = New("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = Text, Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Text, AutoButtonColor = false }, Container)
	Button.MouseEnter:Connect(function() S.Color = Theme.Accent end)
	Button.MouseLeave:Connect(function() S.Color = Theme.Border end)
	return Container, Button
end

local Gui = New("ScreenGui", { Name = "SfixUI", ResetOnSpawn = false, IgnoreGuiInset = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999 })
if not pcall(function() Gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end) or not Gui.Parent then
	Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end
Library.Gui = Gui

local function AddScale(Object)
	local S = New("UIScale", {}, Object)
	table.insert(Library.scales, S)
	return S
end

local function UpdateScale()
	local V = Gui.AbsoluteSize
	local S = math.clamp(math.min(V.X / 980, V.Y / 560), 0.42, 1.25) * Library.scale_mult
	for _, Scale in ipairs(Library.scales) do Scale.Scale = S end
end

function Library:update_theme(Key, Color)
	if Key == "accent" and typeof(Color) == "Color3" then
		Theme.Accent = Color
		Theme.AccentLight = Color:Lerp(WHITE, 0.3)
		Theme.AccentDark = Color:Lerp(BLACK, 0.35)
		for _, Fn in ipairs(self.hooks) do pcall(Fn) end
	end
end

local Section = {}
Section.__index = Section

local Column = {}
Column.__index = Column

local Page = {}
Page.__index = Page

local Window = {}
Window.__index = Window

local function Wrap(Sec)
	local Holder = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, Sec.Body)
	New("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, Holder)
	return Holder
end

local function Decorate(Holder, O)
	if O.info then
		Label(Holder, O.info, { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, TextSize = 12, TextColor3 = Theme.Dim, LayoutOrder = 5 })
	end
	if O.seperator or O.separator then
		New("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Border, BorderSizePixel = 0, LayoutOrder = 6 }, Holder)
	end
end

local function SubSection(Win, Frame)
	return setmetatable({ Body = Frame, Window = Win }, Section)
end

local function MakeColor(Win, Parent, O, Anchored)
	local Default = typeof(O.color) == "Color3" and O.color or typeof(O.default) == "Color3" and O.default or WHITE
	local Flag = O.flag or NextFlag()
	local Callback = O.callback
	local Swatch = New("TextButton", { Size = UDim2.fromOffset(28, 12), BackgroundColor3 = Default, Text = "", AutoButtonColor = false, LayoutOrder = 1 }, Parent)
	if Anchored then
		Swatch.AnchorPoint = Vector2.new(1, 0.5)
		Swatch.Position = UDim2.new(1, 0, 0.5, 0)
	end
	Stroke(Swatch, Color3.fromRGB(10, 10, 14))
	local Popup = New("Frame", { Size = UDim2.fromOffset(160, 128), BackgroundColor3 = Theme.Panel, Visible = false, ZIndex = 50 }, Win.Main)
	local PopupStroke = Stroke(Popup, Theme.Accent)
	OnAccent(function() PopupStroke.Color = Theme.Accent end)
	local SV = New("Frame", { Size = UDim2.fromOffset(122, 114), Position = UDim2.fromOffset(7, 7), BackgroundColor3 = Color3.fromHSV(0, 1, 1), ZIndex = 51, BorderSizePixel = 0 }, Popup)
	local White = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, ZIndex = 52, BorderSizePixel = 0 }, SV)
	New("UIGradient", { Transparency = NumberSequence.new(0, 1) }, White)
	local Black = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, ZIndex = 53, BorderSizePixel = 0 }, SV)
	New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }, Black)
	local Marker = New("Frame", { Size = UDim2.fromOffset(6, 6), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = WHITE, ZIndex = 55 }, SV)
	Stroke(Marker, BLACK)
	local HueBar = New("Frame", { Size = UDim2.fromOffset(14, 114), Position = UDim2.fromOffset(138, 7), BackgroundColor3 = WHITE, ZIndex = 51, BorderSizePixel = 0 }, Popup)
	local Keys = {}
	for I = 0, 6 do table.insert(Keys, ColorSequenceKeypoint.new(I / 6, Color3.fromHSV(I / 6, 1, 1))) end
	New("UIGradient", { Rotation = 90, Color = ColorSequence.new(Keys) }, HueBar)
	local HueMark = New("Frame", { Size = UDim2.new(1, 4, 0, 2), BackgroundColor3 = WHITE, ZIndex = 55 }, HueBar)
	local H, S, V = Default:ToHSV()
	local Obj = { flag = Flag }
	local function Apply(Silent)
		local Color = Color3.fromHSV(H, S, V)
		Swatch.BackgroundColor3 = Color
		SV.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
		Marker.Position = UDim2.fromScale(S, 1 - V)
		HueMark.Position = UDim2.new(-0.14, 0, H, -1)
		Library.flags[Flag] = { Color.R, Color.G, Color.B }
		if Callback and not Silent then task.spawn(Callback, Color) end
	end
	function Obj:set(C, Silent)
		if type(C) == "table" then C = Color3.new(C[1] or C.R or 1, C[2] or C.G or 1, C[3] or C.B or 1) end
		if typeof(C) ~= "Color3" then return end
		H, S, V = C:ToHSV()
		Apply(Silent)
	end
	function Obj:get() return Color3.fromHSV(H, S, V) end
	Dragger(SV, function(Pos)
		S = math.clamp((Pos.X - SV.AbsolutePosition.X) / SV.AbsoluteSize.X, 0, 1)
		V = 1 - math.clamp((Pos.Y - SV.AbsolutePosition.Y) / SV.AbsoluteSize.Y, 0, 1)
		Apply()
	end)
	Dragger(HueBar, function(Pos)
		H = math.clamp((Pos.Y - HueBar.AbsolutePosition.Y) / HueBar.AbsoluteSize.Y, 0, 0.999)
		Apply()
	end)
	Swatch.MouseButton1Click:Connect(function()
		if Library.popup and Library.popup ~= Popup then Library.popup.Visible = false end
		local Scale = Win.MainScale.Scale
		local Rel = (Swatch.AbsolutePosition - Win.Main.AbsolutePosition) / Scale
		local MaxX = Win.Main.Size.X.Offset - 164
		local MaxY = Win.Main.Size.Y.Offset - 132
		Popup.Position = UDim2.fromOffset(math.clamp(Rel.X - 118, 4, MaxX), math.clamp(Rel.Y + 16, 4, MaxY))
		Popup.Visible = not Popup.Visible
		Library.popup = Popup
	end)
	Apply(true)
	Register(Flag, { Default.R, Default.G, Default.B }, function(C, Silent) Obj:set(C, Silent) end)
	return Obj
end

function Section:toggle(O)
	O = type(O) == "table" and O or {}
	local Win = self.Window
	local Flag = O.flag or NextFlag()
	local Callback = O.callback
	local Holder = Wrap(self)
	local Row = New("TextButton", { Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = 1 }, Holder)
	local Box = New("Frame", { Size = UDim2.fromOffset(12, 12), Position = UDim2.new(0, 0, 0.5, -6), BackgroundColor3 = WHITE }, Row)
	Grad(Box, Color3.fromRGB(40, 40, 52), Color3.fromRGB(22, 22, 30))
	local BoxStroke = Stroke(Box)
	local Fill = New("Frame", { Size = UDim2.new(1, -4, 1, -4), Position = UDim2.fromOffset(2, 2), BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0 }, Box)
	AccentGrad(Fill)
	local Name = Label(Row, O.name or "Toggle", { Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(20, 0), TextSize = 13, TextColor3 = Theme.Dim })
	local Right = New("Frame", { Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 }, Row)
	New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, Right)
	local State = false
	local GroupFrame
	local Obj = { flag = Flag }
	local function Paint()
		Fill.BackgroundTransparency = State and 0 or 1
		BoxStroke.Color = State and Theme.Accent or Theme.Border
		Name.TextColor3 = State and Theme.Text or Theme.Dim
	end
	function Obj:set(V, Silent)
		State = V and true or false
		Paint()
		if GroupFrame then GroupFrame.Visible = State end
		Library.flags[Flag] = State
		if Callback and not Silent then task.spawn(Callback, State) end
	end
	function Obj:get() return State end
	function Obj:colorpicker(Co)
		return MakeColor(Win, Right, type(Co) == "table" and Co or {}, false)
	end
	function Obj:settings()
		local Gear = New("ImageButton", { Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1, ImageColor3 = Theme.Dim, LayoutOrder = 2 }, Right)
		ApplyIcon(Gear, "settings")
		local Frame = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.Field, Visible = false, LayoutOrder = 3 }, Holder)
		Stroke(Frame)
		New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, Frame)
		New("UIPadding", { PaddingTop = UDim.new(0, 7), PaddingBottom = UDim.new(0, 7), PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 7) }, Frame)
		Gear.MouseButton1Click:Connect(function()
			Frame.Visible = not Frame.Visible
			Gear.ImageColor3 = Frame.Visible and Theme.Accent or Theme.Dim
		end)
		return SubSection(Win, Frame)
	end
	function Obj:group()
		local Frame = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = State, LayoutOrder = 4 }, Holder)
		New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, Frame)
		New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingTop = UDim.new(0, 4) }, Frame)
		GroupFrame = Frame
		return SubSection(Win, Frame)
	end
	Row.MouseButton1Click:Connect(function() Obj:set(not State) end)
	OnAccent(Paint)
	Obj:set(O.default or O.value or false, true)
	Register(Flag, State, function(V, Silent) Obj:set(V, Silent) end)
	if type(O.children) == "function" then O.children(Obj:group()) end
	Decorate(Holder, O)
	return Obj
end

function Section:slider(O)
	O = type(O) == "table" and O or {}
	local Min, Max = O.min or 0, O.max or 100
	local Decimals = O.decimals or O.decimal or 0
	local Suffix = O.suffix or ""
	local Flag = O.flag or NextFlag()
	local Callback = O.callback
	local Holder = Wrap(self)
	local Top = New("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, LayoutOrder = 1 }, Holder)
	Label(Top, O.name or "Slider", { Size = UDim2.new(1, -70, 0, 14), TextSize = 13 })
	local Value = Label(Top, "", { Size = UDim2.new(0, 70, 0, 14), Position = UDim2.new(1, -70, 0, 0), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right })
	local Bar = New("Frame", { Size = UDim2.new(1, 0, 0, 8), Position = UDim2.fromOffset(0, 20), BackgroundColor3 = WHITE }, Top)
	Grad(Bar, Color3.fromRGB(14, 14, 20), Color3.fromRGB(28, 28, 38))
	Stroke(Bar)
	local Fill = New("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, Bar)
	AccentGrad(Fill)
	local Current = Min
	local Obj = { flag = Flag }
	function Obj:set(V, Silent)
		V = tonumber(V) or Min
		local Mult = 10 ^ Decimals
		V = math.clamp(math.floor(V * Mult + 0.5) / Mult, Min, Max)
		Current = V
		Fill.Size = UDim2.fromScale((V - Min) / math.max(Max - Min, 1e-9), 1)
		Value.Text = string.format("%." .. Decimals .. "f", V) .. Suffix
		Library.flags[Flag] = V
		if Callback and not Silent then task.spawn(Callback, V) end
	end
	function Obj:get() return Current end
	Dragger(Bar, function(Pos)
		local A = math.clamp((Pos.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
		Obj:set(Min + (Max - Min) * A)
	end)
	Obj:set(O.default or O.value or Min, true)
	Register(Flag, Current, function(V, Silent) Obj:set(V, Silent) end)
	Decorate(Holder, O)
	return Obj
end

function Section:dropdown(O)
	O = type(O) == "table" and O or {}
	local Items = O.items or O.options or {}
	local Multi = O.multi and true or false
	local Flag = O.flag or NextFlag()
	local Callback = O.callback
	local Holder = Wrap(self)
	Label(Holder, O.name or "Dropdown", { Size = UDim2.new(1, 0, 0, 14), TextSize = 13, LayoutOrder = 1 })
	local Box = New("TextButton", { Size = UDim2.new(1, 0, 0, 22), BackgroundColor3 = WHITE, Text = "", AutoButtonColor = false, LayoutOrder = 2 }, Holder)
	Styled(Box)
	local Shown = Label(Box, "", { Size = UDim2.new(1, -24, 1, 0), Position = UDim2.fromOffset(7, 0), TextSize = 13, TextColor3 = Theme.Dim, TextTruncate = Enum.TextTruncate.AtEnd })
	local Arrow = New("ImageLabel", { Size = UDim2.fromOffset(14, 14), Position = UDim2.new(1, -18, 0.5, -7), BackgroundTransparency = 1, ImageColor3 = Theme.Dim }, Box)
	ApplyIcon(Arrow, "chevron-down")
	local List = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.Field, Visible = false, LayoutOrder = 3 }, Holder)
	Stroke(List)
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, List)
	local Selected = {}
	local Current
	local Buttons = {}
	local Obj = { flag = Flag }
	local function Value()
		if Multi then
			local Out = {}
			for _, Item in ipairs(Items) do
				if Selected[tostring(Item)] then table.insert(Out, tostring(Item)) end
			end
			return Out
		end
		return Current
	end
	local function Paint()
		if Multi then
			local Out = Value()
			Shown.Text = #Out > 0 and table.concat(Out, ", ") or "None"
		else
			Shown.Text = tostring(Current)
		end
		for Name, Button in pairs(Buttons) do
			local On = Multi and Selected[Name] or (not Multi and tostring(Current) == Name)
			Button.TextColor3 = On and Theme.Accent or Theme.Dim
		end
	end
	local function Fire(Silent)
		Library.flags[Flag] = Value()
		Paint()
		if Callback and not Silent then task.spawn(Callback, Value()) end
	end
	function Obj:set(V, Silent)
		if Multi then
			Selected = {}
			if type(V) == "table" then
				for _, Item in ipairs(V) do Selected[tostring(Item)] = true end
			elseif V ~= nil then
				Selected[tostring(V)] = true
			end
		else
			if type(V) == "table" then V = V[1] end
			Current = V
		end
		Fire(Silent)
	end
	function Obj:get() return Value() end
	for _, Item in ipairs(Items) do
		local Name = tostring(Item)
		local Button = New("TextButton", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = Name, Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Dim, AutoButtonColor = false }, List)
		Buttons[Name] = Button
		Button.MouseButton1Click:Connect(function()
			if Multi then
				Selected[Name] = not Selected[Name] or nil
				Fire()
			else
				Obj:set(Item)
				List.Visible = false
			end
		end)
	end
	Box.MouseButton1Click:Connect(function() List.Visible = not List.Visible end)
	OnAccent(Paint)
	local Default = O.default
	if Default == nil then Default = Multi and {} or Items[1] end
	Obj:set(Default, true)
	Register(Flag, Value(), function(V, Silent) Obj:set(V, Silent) end)
	Decorate(Holder, O)
	return Obj
end

function Section:button(O)
	O = type(O) == "table" and O or {}
	local Holder = Wrap(self)
	local Container, Button = BoxButton(Holder, O.name or "Button", UDim2.new(1, 0, 0, 22))
	Container.LayoutOrder = 1
	Button.MouseButton1Click:Connect(function() if O.callback then task.spawn(O.callback) end end)
	Decorate(Holder, O)
	return Button
end

function Section:button_row(A, B)
	local Row = New("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1 }, self.Body)
	New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4) }, Row)
	for _, Data in ipairs({ A, B }) do
		local _, Button = BoxButton(Row, Data.name or "Button", UDim2.new(0.5, -2, 1, 0))
		Button.MouseButton1Click:Connect(function() if Data.callback then task.spawn(Data.callback) end end)
	end
end

function Section:textbox(O)
	O = type(O) == "table" and O or {}
	local Flag = O.flag or NextFlag()
	local Callback = O.callback
	local Holder = Wrap(self)
	local Row = New("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, LayoutOrder = 1 }, Holder)
	Label(Row, O.name or "Textbox", { Size = UDim2.new(1, 0, 0, 14), TextSize = 13 })
	local Back = New("Frame", { Size = UDim2.new(1, 0, 0, 22), Position = UDim2.fromOffset(0, 17), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, Row)
	Grad(Back, Color3.fromRGB(14, 14, 20), Color3.fromRGB(28, 28, 38))
	Stroke(Back)
	local Box = New("TextBox", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = O.default or "", PlaceholderText = O.placeholder or "", PlaceholderColor3 = Theme.Dim, Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Text, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left }, Back)
	New("UIPadding", { PaddingLeft = UDim.new(0, 7) }, Box)
	local Obj = { flag = Flag }
	function Obj:set(V, Silent)
		Box.Text = tostring(V or "")
		Library.flags[Flag] = Box.Text
		if Callback and not Silent then task.spawn(Callback, Box.Text) end
	end
	function Obj:get() return Box.Text end
	Box.FocusLost:Connect(function() Obj:set(Box.Text) end)
	Register(Flag, Box.Text, function(V, Silent) Obj:set(V, Silent) end)
	Decorate(Holder, O)
	return Obj
end

function Section:colorpicker(O)
	O = type(O) == "table" and O or {}
	local Holder = Wrap(self)
	local Row = New("Frame", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, LayoutOrder = 1 }, Holder)
	Label(Row, O.name or "Color", { Size = UDim2.new(1, -40, 1, 0), TextSize = 13 })
	local Obj = MakeColor(self.Window, Row, O, true)
	Decorate(Holder, O)
	return Obj
end

function Section:label(O)
	O = type(O) == "table" and O or { name = tostring(O) }
	local Holder = Wrap(self)
	local Title = Label(Holder, O.name or "", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, TextSize = 13, TextColor3 = O.info and Theme.Text or Theme.Dim, LayoutOrder = 1 })
	Decorate(Holder, O)
	local Obj = {}
	function Obj:set(Text) Title.Text = tostring(Text) end
	Obj.label = Title
	return Obj
end

function Section:list(O)
	O = type(O) == "table" and O or {}
	local Flag = O.flag or NextFlag()
	local Callback = O.callback
	local Holder = Wrap(self)
	local Frame = New("ScrollingFrame", { Size = UDim2.new(1, 0, 0, O.height or 96), BackgroundColor3 = WHITE, BorderSizePixel = 0, ScrollBarThickness = 2, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, LayoutOrder = 1 }, Holder)
	OnAccent(function() Frame.ScrollBarImageColor3 = Theme.Accent end)
	Grad(Frame, Color3.fromRGB(14, 14, 20), Color3.fromRGB(26, 26, 35))
	Stroke(Frame)
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, Frame)
	local Obj = { flag = Flag, items = {}, selected = nil }
	local function Paint()
		for Name, Button in pairs(Obj.items) do Button.TextColor3 = Name == Obj.selected and Theme.Accent or Theme.Dim end
	end
	function Obj:clear()
		for _, Button in pairs(self.items) do Button:Destroy() end
		self.items, self.selected = {}, nil
		Library.flags[Flag] = nil
	end
	function Obj:pick(Name, Silent)
		self.selected = Name
		Library.flags[Flag] = Name
		Paint()
		if Callback and not Silent then task.spawn(Callback, Name) end
	end
	function Obj:add(Name)
		local Button = New("TextButton", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = Name, Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Dim, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false }, Frame)
		New("UIPadding", { PaddingLeft = UDim.new(0, 7) }, Button)
		self.items[Name] = Button
		Button.MouseButton1Click:Connect(function() self:pick(Name) end)
		Paint()
	end
	function Obj:set_options(Names)
		self:clear()
		for _, Name in ipairs(Names) do self:add(Name) end
	end
	function Obj:get() return self.selected end
	OnAccent(Paint)
	for _, Name in ipairs(O.options or O.items or {}) do Obj:add(Name) end
	Register(Flag, nil, function(V, Silent) if Obj.items[V] then Obj:pick(V, Silent) end end)
	Decorate(Holder, O)
	return Obj
end

function Section:preview(O)
	O = type(O) == "table" and O or {}
	local Esp = O.esp
	local Holder = New("Frame", { Size = UDim2.new(1, 0, 0, O.height or 300), BackgroundColor3 = Color3.fromRGB(11, 11, 16) }, self.Body)
	Stroke(Holder)
	local VP = New("ViewportFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Ambient = Color3.fromRGB(190, 190, 205), LightColor = WHITE }, Holder)
	local Cam = New("Camera", { FieldOfView = 38 }, VP)
	VP.CurrentCamera = Cam
	local Box = New("Frame", { Size = UDim2.fromScale(0.5, 0.74), Position = UDim2.fromScale(0.25, 0.12), BackgroundTransparency = 1, Visible = false }, Holder)
	local BoxStroke = Stroke(Box, Theme.Accent)
	local Name = Label(Holder, "Player", { Size = UDim2.new(0.5, 0, 0, 14), Position = UDim2.fromScale(0.25, 0.12), AnchorPoint = Vector2.new(0, 1), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center, Visible = false })
	local HealthBack = New("Frame", { Size = UDim2.new(0, 3, 0.74, 0), Position = UDim2.new(0.25, -7, 0.12, 0), BackgroundColor3 = Color3.fromRGB(10, 10, 14), BorderSizePixel = 0, Visible = false }, Holder)
	New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(80, 220, 120), BorderSizePixel = 0 }, HealthBack)
	local Distance = Label(Holder, "25m", { Size = UDim2.new(0.5, 0, 0, 14), Position = UDim2.fromScale(0.25, 0.87), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center, Visible = false })
	local Weapon = Label(Holder, "Weapon", { Size = UDim2.new(0.5, 0, 0, 14), Position = UDim2.new(0.25, 0, 0.87, 12), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center, Visible = false })
	local Model
	local function Build()
		if Model then Model:Destroy() Model = nil end
		local Char = LocalPlayer.Character
		if not Char then return end
		Char.Archivable = true
		local ok, Clone = pcall(function() return Char:Clone() end)
		if not ok or not Clone then return end
		for _, D in ipairs(Clone:GetDescendants()) do
			if D:IsA("BaseScript") then D:Destroy() end
		end
		Clone.Parent = VP
		Model = Clone
		local Root = Clone:FindFirstChild("HumanoidRootPart")
		if Root then
			local Pos = Root.Position
			Cam.CFrame = CFrame.lookAt(Pos + Root.CFrame.LookVector * 8.5 + Vector3.new(0, 0.6, 0), Pos + Vector3.new(0, 0.2, 0))
		end
	end
	Build()
	LocalPlayer.CharacterAdded:Connect(function() task.wait(1) Build() end)
	RunService.RenderStepped:Connect(function()
		local V = Esp.Values
		local On = V.Enabled
		Box.Visible = On and V.Box
		Name.Visible = On and V.Name
		HealthBack.Visible = On and V.HealthBar
		Distance.Visible = On and V.Distance
		Weapon.Visible = On and V.Weapon
		Name.Text = V.DisplayName and LocalPlayer.DisplayName or LocalPlayer.Name
		BoxStroke.Color = V.BoxColor
		Name.TextColor3 = V.NameColor
		Distance.TextColor3 = V.DistanceColor
		Weapon.TextColor3 = V.WeaponColor
	end)
end

function Section:target_hud()
	local Holder = New("Frame", { Size = UDim2.new(1, 0, 0, 64), BackgroundTransparency = 1 }, self.Body)
	local Avatar = New("ImageLabel", { Size = UDim2.fromOffset(60, 60), BackgroundColor3 = Theme.Field, Image = "" }, Holder)
	Stroke(Avatar)
	local Rows = {}
	for I, Name in ipairs({ "Username", "Health", "Distance", "Team" }) do
		Rows[Name] = Label(Holder, Name .. " - N/A", { Size = UDim2.new(1, -70, 0, 15), Position = UDim2.fromOffset(68, (I - 1) * 15 + 1), TextSize = 13 })
	end
	local Acc = 0
	RunService.Heartbeat:Connect(function(Dt)
		Acc += Dt
		if Acc < 0.25 then return end
		Acc = 0
		local Me = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		local Best, BestDist
		if Me then
			for _, P in ipairs(Players:GetPlayers()) do
				local R = P ~= LocalPlayer and P.Character and P.Character:FindFirstChild("HumanoidRootPart")
				if R then
					local D = (R.Position - Me.Position).Magnitude
					if not BestDist or D < BestDist then Best, BestDist = P, D end
				end
			end
		end
		if Library.target and Library.target.Character then
			Best = Library.target
			local R = Best.Character:FindFirstChild("HumanoidRootPart")
			if R and Me then BestDist = (R.Position - Me.Position).Magnitude end
		end
		if Best then
			local Hum = Best.Character and Best.Character:FindFirstChildOfClass("Humanoid")
			Avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. Best.UserId .. "&w=150&h=150"
			Rows.Username.Text = "Username - " .. Best.Name
			Rows.Health.Text = "Health - " .. (Hum and math.floor(Hum.Health / math.max(Hum.MaxHealth, 1) * 100) or 0) .. "%"
			Rows.Distance.Text = "Distance - " .. math.floor(BestDist or 0) .. "m"
			Rows.Team.Text = "Team - " .. (Best.Team and Best.Team.Name or "N/A")
		else
			Avatar.Image = ""
			Rows.Username.Text, Rows.Health.Text, Rows.Distance.Text, Rows.Team.Text = "Username - N/A", "Health - N/A", "Distance - N/A", "Team - N/A"
		end
	end)
end

function Section:player_list(O)
	O = type(O) == "table" and O or {}
	local List = self:list({ height = O.height or 200, callback = function(Name) Library.target = Players:FindFirstChild(Name) end })
	local function Refresh()
		local Names = {}
		for _, P in ipairs(Players:GetPlayers()) do
			if P ~= LocalPlayer then table.insert(Names, P.Name) end
		end
		List:set_options(Names)
	end
	Refresh()
	Players.PlayerAdded:Connect(Refresh)
	Players.PlayerRemoving:Connect(function() task.wait() Refresh() end)
	self:button({ name = "Clear target", callback = function() Library.target = nil end })
	return List
end

function Column:section(O)
	O = type(O) == "table" and O or {}
	local Win = self.Window
	self.Count += 1
	local Frame = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.Panel, LayoutOrder = self.Count }, self.Frame)
	Stroke(Frame)
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, Frame)
	local Head = New("TextButton", { Size = UDim2.new(1, 0, 0, 25), BackgroundColor3 = WHITE, BorderSizePixel = 0, Text = "", AutoButtonColor = false, LayoutOrder = 1 }, Frame)
	Grad(Head, Color3.fromRGB(36, 36, 48), Color3.fromRGB(21, 21, 29))
	local Offset = 8
	if O.icon then
		local Icon = New("ImageLabel", { Size = UDim2.fromOffset(14, 14), Position = UDim2.new(0, 8, 0.5, -7), BackgroundTransparency = 1 }, Head)
		ApplyIcon(Icon, O.icon)
		OnAccent(function() Icon.ImageColor3 = Theme.Accent end)
		Offset = 28
	end
	local Title = Label(Head, O.name or "Section", { Size = UDim2.new(1, -Offset - 24, 1, 0), Position = UDim2.fromOffset(Offset, 0), Font = Theme.Bold })
	OnAccent(function() Title.TextColor3 = Theme.Accent end)
	local Chevron = New("ImageLabel", { Size = UDim2.fromOffset(14, 14), Position = UDim2.new(1, -20, 0.5, -7), BackgroundTransparency = 1, ImageColor3 = Theme.Dim }, Head)
	ApplyIcon(Chevron, "chevron-down")
	New("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = Theme.Border, BorderSizePixel = 0 }, Head)
	Glow(Head, UDim2.new(0, 0, 0, 0), 1)
	local Body = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = O.default ~= false, LayoutOrder = 2 }, Frame)
	New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, Body)
	New("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 9), PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9) }, Body)
	Chevron.Rotation = Body.Visible and 0 or -90
	Head.MouseButton1Click:Connect(function()
		Body.Visible = not Body.Visible
		Chevron.Rotation = Body.Visible and 0 or -90
	end)
	return SubSection(Win, Body)
end

function Page:column()
	local Frame = New("ScrollingFrame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, LayoutOrder = #self.Columns + 1 }, self.Frame)
	OnAccent(function() Frame.ScrollBarImageColor3 = Theme.Accent end)
	New("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, Frame)
	local Col = setmetatable({ Frame = Frame, Window = self.Window, Count = 0 }, Column)
	table.insert(self.Columns, Col)
	local N = #self.Columns
	for _, C in ipairs(self.Columns) do
		C.Frame.Size = UDim2.new(1 / N, -(10 * (N - 1)) / N, 1, 0)
	end
	return Col
end

function Page:sub_tab()
	return self
end

function Window:seperator(O)
	O = type(O) == "table" and O or {}
	self.Order += 1
	local Holder = New("Frame", { Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, LayoutOrder = self.Order }, self.TabBar)
	New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, Holder)
	New("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 4) }, Holder)
	New("Frame", { Size = UDim2.fromOffset(1, 16), BackgroundColor3 = Theme.Border, BorderSizePixel = 0, LayoutOrder = 1 }, Holder)
	Label(Holder, string.upper(O.name or ""), { Size = UDim2.fromOffset(0, 16), AutomaticSize = Enum.AutomaticSize.X, Font = Theme.Bold, TextSize = 11, TextColor3 = Theme.Dim, LayoutOrder = 2 })
end

function Window:select(Tab)
	for _, T in ipairs(self.Tabs) do
		local On = T == Tab
		T.Panel.Visible = On
		T.Under.Visible = On
		T.Img.ImageColor3 = On and Theme.Accent or Theme.Dim
		T.Text.TextColor3 = On and Theme.Text or Theme.Dim
	end
	self.Selected = Tab
	if Library.popup then Library.popup.Visible = false end
end

function Window:tab(O)
	O = type(O) == "table" and O or {}
	local Names = O.tabs
	if type(Names) ~= "table" or #Names == 0 then Names = { O.name or "Tab" } end
	local Multi = #Names > 1
	local Tab = { Pages = {} }
	self.Order += 1
	local Button = New("TextButton", { Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = self.Order }, self.TabBar)
	local Row = New("Frame", { Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1 }, Button)
	New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, Row)
	New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, Row)
	local Img = New("ImageLabel", { Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1, ImageColor3 = Theme.Dim, LayoutOrder = 1 }, Row)
	ApplyIcon(Img, O.icon)
	local Text = Label(Row, O.name or "Tab", { Size = UDim2.fromOffset(0, 18), AutomaticSize = Enum.AutomaticSize.X, TextColor3 = Theme.Dim, TextSize = 14, LayoutOrder = 2 })
	local Under = Glow(Button, UDim2.new(0, 0, 1, -2), 2)
	Under.Visible = false
	local Panel = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false }, self.Content)
	local SubBar = New("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Visible = Multi }, Panel)
	New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, SubBar)
	local Area = New("Frame", { Size = UDim2.new(1, 0, 1, Multi and -28 or 0), Position = UDim2.fromOffset(0, Multi and 28 or 0), BackgroundTransparency = 1 }, Panel)
	Tab.Img, Tab.Text, Tab.Under, Tab.Panel = Img, Text, Under, Panel
	local SubButtons = {}
	local function SelectPage(Index)
		for I, P in ipairs(Tab.Pages) do
			P.Frame.Visible = I == Index
			local B = SubButtons[I]
			B.TextColor3 = I == Index and Theme.Accent or Theme.Dim
		end
		if Library.popup then Library.popup.Visible = false end
	end
	for I, Name in ipairs(Names) do
		local PageFrame = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false }, Area)
		New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, PageFrame)
		table.insert(Tab.Pages, setmetatable({ Frame = PageFrame, Columns = {}, Window = self }, Page))
		local SubButton = New("TextButton", { Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = Theme.Panel, Text = Name, Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Dim, AutoButtonColor = false, LayoutOrder = I }, SubBar)
		New("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, SubButton)
		Stroke(SubButton)
		SubButtons[I] = SubButton
		SubButton.MouseButton1Click:Connect(function() SelectPage(I) end)
	end
	OnAccent(function() SelectPage(Tab.Current or 1) end)
	Tab.Current = 1
	SelectPage(1)
	table.insert(self.Tabs, Tab)
	Button.MouseButton1Click:Connect(function() self:select(Tab) end)
	if #self.Tabs == 1 then self:select(Tab) end
	return table.unpack(Tab.Pages)
end

local HEALTH_LOW = Color3.fromRGB(255, 50, 50)
local HEALTH_HIGH = Color3.fromRGB(90, 255, 90)
local TOP_OFFSET = Vector3.new(0, 2.7, 0)
local BOTTOM_OFFSET = Vector3.new(0, 3.1, 0)
local FONT_URL = "https://github.com/bluescan/proggyfonts/raw/master/ProggyOriginal/ProggyClean.ttf"

local R15_BONES = {
	{ "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" },
	{ "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" }, { "LeftLowerArm", "LeftHand" },
	{ "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" },
	{ "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" }, { "LeftLowerLeg", "LeftFoot" },
	{ "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" },
}

local R6_BONES = {
	{ "Head", "Torso" }, { "Torso", "Left Arm" }, { "Torso", "Right Arm" },
	{ "Torso", "Left Leg" }, { "Torso", "Right Leg" },
}

local EspFont
local function LoadFont()
	if EspFont then return EspFont end
	local ok, Result = pcall(function()
		if not (writefile and isfile and getcustomasset) then error("unsupported") end
		if not isfile("ProggyClean.ttf") then writefile("ProggyClean.ttf", game:HttpGet(FONT_URL)) end
		writefile("ProggyFont.json", HttpService:JSONEncode({
			name = "Proggy",
			faces = { { name = "Regular", weight = 400, style = "normal", assetId = getcustomasset("ProggyClean.ttf") } },
		}))
		return Font.new(getcustomasset("ProggyFont.json"))
	end)
	EspFont = (ok and Result) or Font.fromEnum(Enum.Font.Code)
	return EspFont
end

local function SetVisible(Inst, Value)
	if Inst.Visible ~= Value then Inst.Visible = Value end
end

local function SetText(Item, Text)
	if Item.Text ~= Text then Item.Text = Text end
end

local function SetEnabled(Inst, Value)
	if Inst.Enabled ~= Value then Inst.Enabled = Value end
end

local function Tint(Inst, Prop, Gradient, UseGradient, Color)
	Inst[Prop] = UseGradient and WHITE or Color
	SetEnabled(Gradient, UseGradient)
end

local function DrawLine(Frame, A, B, Thickness)
	local Dx, Dy = B.X - A.X, B.Y - A.Y
	Frame.Position = UDim2.fromOffset((A.X + B.X) / 2, (A.Y + B.Y) / 2)
	Frame.Size = UDim2.fromOffset(math.sqrt(Dx * Dx + Dy * Dy), Thickness)
	Frame.Rotation = math.deg(math.atan2(Dy, Dx))
end

local EspClass = {}
EspClass.__index = EspClass

local ESP_DEFAULTS = {
	Enabled = false,
	TeamCheck = false,
	MaxDistance = 2000,
	TextSize = 13,
	Box = true,
	BoxColor = Color3.fromRGB(255, 255, 255),
	BoxGradient = false,
	BoxFill = false,
	FillColor = Color3.fromRGB(120, 140, 255),
	FillTransparency = 0.45,
	Skeleton = false,
	SkeletonColor = Color3.fromRGB(255, 255, 255),
	SkeletonGradient = false,
	SkeletonThickness = 1,
	Dot = false,
	DotColor = Color3.fromRGB(255, 255, 255),
	DotGradient = false,
	DotSize = 6,
	Glow = false,
	GlowColor = Color3.fromRGB(255, 80, 180),
	GlowGradient = false,
	GlowTransparency = 0.5,
	Tracer = false,
	TracerColor = Color3.fromRGB(255, 255, 255),
	TracerGradient = false,
	HealthBar = true,
	HealthBarGradient = false,
	HealthText = true,
	HealthTextGradient = false,
	Name = true,
	DisplayName = true,
	NameColor = Color3.fromRGB(255, 255, 255),
	NameGradient = false,
	Avatar = false,
	Weapon = true,
	WeaponColor = Color3.fromRGB(200, 200, 200),
	WeaponGradient = false,
	Backpack = false,
	BackpackColor = Color3.fromRGB(200, 200, 200),
	BackpackGradient = false,
	Distance = true,
	DistanceColor = Color3.fromRGB(200, 200, 200),
	DistanceGradient = false,
	GradientColor1 = Color3.fromRGB(255, 255, 255),
	GradientColor2 = Color3.fromRGB(255, 80, 180),
	GradientAnimation = false,
	GradientAnimationSpeed = 4,
}

function EspClass:Frame(Obj, Parent)
	local Frame = New("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false }, Parent)
	table.insert(Obj.All, Frame)
	return Frame
end

function EspClass:Gradient(Obj, Target)
	local G = New("UIGradient", { Enabled = false }, Target)
	table.insert(Obj.Grads, G)
	return G
end

function EspClass:Text(Obj, Parent)
	local Item = New("TextLabel", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		FontFace = LoadFont(),
		TextSize = self.Values.TextSize,
		TextStrokeColor3 = BLACK,
		TextStrokeTransparency = 0,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		Size = UDim2.fromOffset(200, 14),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Text = "",
		Visible = false,
	}, Parent)
	table.insert(Obj.All, Item)
	return Item
end

function EspClass:CreateObject(Player)
	if self.Objects[Player] or not self.Gui then return end
	local V = self.Values
	local Holder = New("Folder", { Name = Player.Name }, self.Gui)
	local Obj = { Holder = Holder, Hidden = true, Frame = 0, All = {}, Grads = {}, GradVersion = -1 }

	Obj.Fill = self:Frame(Obj, Holder)
	Obj.Fill.BackgroundTransparency = V.FillTransparency
	New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.85) }) }, Obj.Fill)

	Obj.Outer = self:Frame(Obj, Holder)
	New("UIStroke", { Color = BLACK, Thickness = 1, LineJoinMode = Enum.LineJoinMode.Miter, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, Obj.Outer)
	Obj.Main = self:Frame(Obj, Holder)
	Obj.MainStroke = New("UIStroke", { Color = V.BoxColor, Thickness = 1, LineJoinMode = Enum.LineJoinMode.Miter, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, Obj.Main)
	Obj.MainGrad = self:Gradient(Obj, Obj.MainStroke)
	Obj.Inner = self:Frame(Obj, Holder)
	New("UIStroke", { Color = BLACK, Thickness = 1, LineJoinMode = Enum.LineJoinMode.Miter, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, Obj.Inner)

	Obj.HealthBack = self:Frame(Obj, Holder)
	Obj.HealthBack.BackgroundColor3 = BLACK
	Obj.HealthBack.BackgroundTransparency = 0.2
	Obj.HealthFill = self:Frame(Obj, Holder)
	Obj.HealthFill.BackgroundTransparency = 0
	Obj.HealthFill.AnchorPoint = Vector2.new(0, 1)
	Obj.HealthGrad = self:Gradient(Obj, Obj.HealthFill)

	Obj.HealthText = self:Text(Obj, Holder)
	Obj.HealthText.Size = UDim2.fromOffset(30, 14)
	Obj.HealthText.TextXAlignment = Enum.TextXAlignment.Right
	Obj.HealthText.AnchorPoint = Vector2.new(1, 0.5)
	Obj.HealthTextGrad = self:Gradient(Obj, Obj.HealthText)

	Obj.Tracer = self:Frame(Obj, Holder)
	Obj.Tracer.AnchorPoint = Vector2.new(0.5, 0.5)
	Obj.Tracer.BackgroundTransparency = 0
	Obj.TracerGrad = self:Gradient(Obj, Obj.Tracer)

	Obj.Dot = self:Frame(Obj, Holder)
	Obj.Dot.AnchorPoint = Vector2.new(0.5, 0.5)
	Obj.Dot.BackgroundTransparency = 0
	New("UICorner", { CornerRadius = UDim.new(1, 0) }, Obj.Dot)
	Obj.DotGrad = self:Gradient(Obj, Obj.Dot)

	Obj.Avatar = New("ImageLabel", { Size = UDim2.fromOffset(20, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = BLACK, BorderSizePixel = 0, Image = "rbxthumb://type=AvatarHeadShot&id=" .. Player.UserId .. "&w=48&h=48", Visible = false }, Holder)
	New("UICorner", { CornerRadius = UDim.new(1, 0) }, Obj.Avatar)
	table.insert(Obj.All, Obj.Avatar)

	Obj.Name = self:Text(Obj, Holder)
	Obj.NameGrad = self:Gradient(Obj, Obj.Name)
	Obj.Info = self:Text(Obj, Holder)
	Obj.InfoGrad = self:Gradient(Obj, Obj.Info)
	Obj.ToolLabel = self:Text(Obj, Holder)
	Obj.ToolGrad = self:Gradient(Obj, Obj.ToolLabel)
	Obj.BackLabel = self:Text(Obj, Holder)
	Obj.BackLabel.AnchorPoint = Vector2.new(0.5, 0)
	Obj.BackLabel.TextYAlignment = Enum.TextYAlignment.Top
	Obj.BackGrad = self:Gradient(Obj, Obj.BackLabel)

	Obj.Highlight = New("Highlight", { Enabled = false, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, OutlineTransparency = 0 }, Holder)

	self.Objects[Player] = Obj
end

function EspClass:RemoveObject(Player)
	local Obj = self.Objects[Player]
	if Obj then
		Obj.Holder:Destroy()
		self.Objects[Player] = nil
	end
end

local function HideObject(Obj)
	if Obj.Hidden then return end
	Obj.Hidden = true
	for _, Item in ipairs(Obj.All) do Item.Visible = false end
	Obj.Highlight.Enabled = false
end

local function RefreshCharacter(Obj, Player)
	local Character = Player.Character
	if Character ~= Obj.Character then
		Obj.Character = Character
		Obj.Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
		Obj.Root = Character and Character:FindFirstChild("HumanoidRootPart")
		Obj.Tool = nil
		Obj.BoneParts = nil
	end
	if Character and (not Obj.Humanoid or not Obj.Humanoid.Parent) then
		Obj.Humanoid = Character:FindFirstChildOfClass("Humanoid")
	end
	if Character and (not Obj.Root or not Obj.Root.Parent) then
		Obj.Root = Character:FindFirstChild("HumanoidRootPart")
	end
end

function EspClass:ResolveBones(Obj)
	local Char = Obj.Character
	local Layout = Obj.Humanoid.RigType == Enum.HumanoidRigType.R15 and R15_BONES or R6_BONES
	Obj.BoneParts = {}
	for I, Pair in ipairs(Layout) do
		Obj.BoneParts[I] = { Char:FindFirstChild(Pair[1]), Char:FindFirstChild(Pair[2]) }
		if not Obj.Bones then Obj.Bones = {} end
		if not Obj.Bones[I] then
			local Bone = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Visible = false }, Obj.Holder)
			table.insert(Obj.All, Bone)
			Obj.Bones[I] = { Frame = Bone, Grad = self:Gradient(Obj, Bone) }
			Obj.GradVersion = -1
		end
	end
end

function EspClass:ApplyGradients(Obj)
	for _, G in ipairs(Obj.Grads) do
		G.Color = self.Sequence
		G.Rotation = self.Rotation
	end
	Obj.GradVersion = self.GradVersion
end

function EspClass:Update(Player, Obj, CamPos, Viewport)
	local V = self.Values
	local Camera = self.Camera

	if V.TeamCheck and Player.Team ~= nil and Player.Team == LocalPlayer.Team then
		HideObject(Obj)
		return
	end

	RefreshCharacter(Obj, Player)

	local Humanoid, Root = Obj.Humanoid, Obj.Root
	if not Humanoid or not Root or Humanoid.Health <= 0 then
		HideObject(Obj)
		return
	end

	local RootPos = Root.Position
	local Distance = (CamPos - RootPos).Magnitude
	if Distance > V.MaxDistance then
		HideObject(Obj)
		return
	end

	local TopPos, TopVisible = Camera:WorldToViewportPoint(RootPos + TOP_OFFSET)
	if not TopVisible or TopPos.Z <= 0 then
		HideObject(Obj)
		return
	end
	local BottomPos = Camera:WorldToViewportPoint(RootPos - BOTTOM_OFFSET)

	Obj.Hidden = false

	if self.Animated or Obj.GradVersion ~= self.GradVersion then self:ApplyGradients(Obj) end

	for _, Item in ipairs({ Obj.Name, Obj.Info, Obj.ToolLabel, Obj.HealthText, Obj.BackLabel }) do
		if Item.TextSize ~= V.TextSize then Item.TextSize = V.TextSize end
	end

	local Height = math.abs(BottomPos.Y - TopPos.Y)
	local CenterX = TopPos.X
	local W = math.floor(Height * 0.56)
	local H = math.floor(Height)
	local Left = math.floor(CenterX - W / 2)
	local Top = math.floor(TopPos.Y)
	local InnerW = math.max(W - 2, 0)
	local InnerH = math.max(H - 2, 0)

	local ShowBox = V.Box
	SetVisible(Obj.Outer, ShowBox)
	SetVisible(Obj.Main, ShowBox)
	SetVisible(Obj.Inner, ShowBox)
	if ShowBox then
		Obj.Outer.Position = UDim2.fromOffset(Left - 1, Top - 1)
		Obj.Outer.Size = UDim2.fromOffset(W + 2, H + 2)
		Obj.Main.Position = UDim2.fromOffset(Left, Top)
		Obj.Main.Size = UDim2.fromOffset(W, H)
		Tint(Obj.MainStroke, "Color", Obj.MainGrad, V.BoxGradient, V.BoxColor)
		Obj.Inner.Position = UDim2.fromOffset(Left + 1, Top + 1)
		Obj.Inner.Size = UDim2.fromOffset(InnerW, InnerH)
	end

	local ShowFill = ShowBox and V.BoxFill
	SetVisible(Obj.Fill, ShowFill)
	if ShowFill then
		Obj.Fill.Position = UDim2.fromOffset(Left + 1, Top + 1)
		Obj.Fill.Size = UDim2.fromOffset(InnerW, InnerH)
		Obj.Fill.BackgroundColor3 = V.FillColor
		Obj.Fill.BackgroundTransparency = V.FillTransparency
	end

	local Ratio = math.clamp(Humanoid.Health / math.max(Humanoid.MaxHealth, 1), 0, 1)
	local HealthColor = HEALTH_LOW:Lerp(HEALTH_HIGH, Ratio)
	local FillHeight = math.max(math.floor(H * Ratio), 1)

	local ShowHealth = V.HealthBar
	SetVisible(Obj.HealthBack, ShowHealth)
	SetVisible(Obj.HealthFill, ShowHealth)
	if ShowHealth then
		Obj.HealthBack.Position = UDim2.fromOffset(Left - 6, Top - 1)
		Obj.HealthBack.Size = UDim2.fromOffset(4, H + 2)
		Obj.HealthFill.Position = UDim2.fromOffset(Left - 5, Top + H)
		Obj.HealthFill.Size = UDim2.fromOffset(2, FillHeight)
		Tint(Obj.HealthFill, "BackgroundColor3", Obj.HealthGrad, V.HealthBarGradient, HealthColor)
	end

	local ShowHealthText = V.HealthText and Ratio < 1
	SetVisible(Obj.HealthText, ShowHealthText)
	if ShowHealthText then
		SetText(Obj.HealthText, tostring(math.floor(Humanoid.Health)))
		Tint(Obj.HealthText, "TextColor3", Obj.HealthTextGrad, V.HealthTextGradient, HealthColor)
		Obj.HealthText.Position = UDim2.fromOffset(Left - 8, Top + H - FillHeight)
	end

	local ShowAvatar = V.Avatar
	SetVisible(Obj.Avatar, ShowAvatar)
	if ShowAvatar then Obj.Avatar.Position = UDim2.fromOffset(CenterX, Top - 30) end

	local ShowName = V.Name
	SetVisible(Obj.Name, ShowName)
	if ShowName then
		SetText(Obj.Name, V.DisplayName and Player.DisplayName or Player.Name)
		Tint(Obj.Name, "TextColor3", Obj.NameGrad, V.NameGradient, V.NameColor)
		Obj.Name.Position = UDim2.fromOffset(CenterX, Top - 9)
	end

	local OffsetY = Top + H + 8

	local ShowDistance = V.Distance
	SetVisible(Obj.Info, ShowDistance)
	if ShowDistance then
		SetText(Obj.Info, math.floor(Distance) .. "m")
		Tint(Obj.Info, "TextColor3", Obj.InfoGrad, V.DistanceGradient, V.DistanceColor)
		Obj.Info.Position = UDim2.fromOffset(CenterX, OffsetY)
		OffsetY = OffsetY + 11
	end

	Obj.Frame = Obj.Frame + 1
	if Obj.Frame % 8 == 0 and Obj.Character then
		Obj.Tool = Obj.Character:FindFirstChildOfClass("Tool")
		if V.Backpack then
			local Names = {}
			local Pack = Player:FindFirstChildOfClass("Backpack")
			if Pack then
				for _, Item in ipairs(Pack:GetChildren()) do
					if Item:IsA("Tool") then table.insert(Names, Item.Name) end
				end
			end
			Obj.BackText = table.concat(Names, "\n")
			Obj.BackCount = #Names
		end
	end

	local ShowTool = V.Weapon
	SetVisible(Obj.ToolLabel, ShowTool)
	if ShowTool then
		local Tool = Obj.Tool
		SetText(Obj.ToolLabel, (Tool and Tool.Parent == Obj.Character) and Tool.Name or "None")
		Tint(Obj.ToolLabel, "TextColor3", Obj.ToolGrad, V.WeaponGradient, V.WeaponColor)
		Obj.ToolLabel.Position = UDim2.fromOffset(CenterX, OffsetY)
		OffsetY = OffsetY + 11
	end

	local ShowBack = V.Backpack and (Obj.BackCount or 0) > 0
	SetVisible(Obj.BackLabel, ShowBack)
	if ShowBack then
		SetText(Obj.BackLabel, Obj.BackText)
		Obj.BackLabel.Size = UDim2.fromOffset(200, Obj.BackCount * 11)
		Tint(Obj.BackLabel, "TextColor3", Obj.BackGrad, V.BackpackGradient, V.BackpackColor)
		Obj.BackLabel.Position = UDim2.fromOffset(CenterX, OffsetY - 5)
	end

	local ShowTracer = V.Tracer
	SetVisible(Obj.Tracer, ShowTracer)
	if ShowTracer then
		local FromX = Viewport.X / 2
		local FromY = Viewport.Y
		local ToY = Top + H
		local Dx = CenterX - FromX
		local Dy = ToY - FromY
		Obj.Tracer.Position = UDim2.fromOffset(FromX + Dx / 2, FromY + Dy / 2)
		Obj.Tracer.Size = UDim2.fromOffset(math.sqrt(Dx * Dx + Dy * Dy), 1)
		Obj.Tracer.Rotation = math.deg(math.atan2(Dy, Dx))
		Tint(Obj.Tracer, "BackgroundColor3", Obj.TracerGrad, V.TracerGradient, V.TracerColor)
	end

	local ShowDot = V.Dot
	SetVisible(Obj.Dot, ShowDot)
	if ShowDot then
		local Head = Obj.Character and Obj.Character:FindFirstChild("Head")
		local DotPos = Camera:WorldToViewportPoint(Head and Head.Position or RootPos)
		Obj.Dot.Position = UDim2.fromOffset(DotPos.X, DotPos.Y)
		Obj.Dot.Size = UDim2.fromOffset(V.DotSize, V.DotSize)
		Tint(Obj.Dot, "BackgroundColor3", Obj.DotGrad, V.DotGradient, V.DotColor)
	end

	if V.Skeleton and Obj.Character then
		if not Obj.BoneParts then self:ResolveBones(Obj) end
		for I, Parts in ipairs(Obj.BoneParts) do
			local Bone = Obj.Bones[I]
			local A, B = Parts[1], Parts[2]
			if A and B and A.Parent and B.Parent then
				local PA = Camera:WorldToViewportPoint(A.Position)
				local PB = Camera:WorldToViewportPoint(B.Position)
				if PA.Z > 0 and PB.Z > 0 then
					SetVisible(Bone.Frame, true)
					DrawLine(Bone.Frame, PA, PB, V.SkeletonThickness)
					Tint(Bone.Frame, "BackgroundColor3", Bone.Grad, V.SkeletonGradient, V.SkeletonColor)
				else
					SetVisible(Bone.Frame, false)
				end
			else
				SetVisible(Bone.Frame, false)
			end
		end
	elseif Obj.Bones then
		for _, Bone in ipairs(Obj.Bones) do SetVisible(Bone.Frame, false) end
	end

	local Highlight = Obj.Highlight
	if V.Glow and Obj.Character then
		if Highlight.Adornee ~= Obj.Character then Highlight.Adornee = Obj.Character end
		SetEnabled(Highlight, true)
		Highlight.FillTransparency = V.GlowTransparency
		local GlowColor = V.GlowColor
		if V.GlowGradient then
			GlowColor = V.GradientColor1:Lerp(V.GradientColor2, (math.sin(self.Clock) + 1) / 2)
		end
		Highlight.FillColor = GlowColor
		Highlight.OutlineColor = GlowColor
	else
		SetEnabled(Highlight, false)
	end
end

function EspClass:Start()
	if self.Running then return end
	self.Running = true
	self.Gui = New("ScreenGui", { Name = "SfixEsp", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 998 })
	if not pcall(function() self.Gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end) or not self.Gui.Parent then
		self.Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end
	for _, Player in ipairs(Players:GetPlayers()) do
		if Player ~= LocalPlayer then self:CreateObject(Player) end
	end
	table.insert(self.Connections, Players.PlayerAdded:Connect(function(Player)
		if Player ~= LocalPlayer then self:CreateObject(Player) end
	end))
	table.insert(self.Connections, Players.PlayerRemoving:Connect(function(Player)
		self:RemoveObject(Player)
	end))
	RunService:BindToRenderStep(self.BindName, Enum.RenderPriority.Camera.Value + 1, function(Dt)
		self.Camera = Workspace.CurrentCamera
		if not self.Camera then return end
		local V = self.Values
		self.Animated = V.GradientAnimation
		if V.GradientAnimation then
			self.Rotation = (self.Rotation + Dt * V.GradientAnimationSpeed * 10) % 360
			self.Clock += Dt * V.GradientAnimationSpeed * 0.5
		end
		if self.C1 ~= V.GradientColor1 or self.C2 ~= V.GradientColor2 then
			self.C1, self.C2 = V.GradientColor1, V.GradientColor2
			self.Sequence = ColorSequence.new(self.C1, self.C2)
			self.GradVersion += 1
		end
		local CamPos = self.Camera.CFrame.Position
		local Viewport = self.Camera.ViewportSize
		for Player, Obj in pairs(self.Objects) do
			self:Update(Player, Obj, CamPos, Viewport)
		end
	end)
end

function EspClass:Stop()
	if not self.Running then return end
	self.Running = false
	pcall(function() RunService:UnbindFromRenderStep(self.BindName) end)
	for _, Connection in ipairs(self.Connections) do Connection:Disconnect() end
	self.Connections = {}
	for Player in pairs(self.Objects) do self:RemoveObject(Player) end
	if self.Gui then
		self.Gui:Destroy()
		self.Gui = nil
	end
end

function EspClass:Unload()
	self:Stop()
end

function EspClass:SetEnabled(Value)
	self.Values.Enabled = Value and true or false
	if self.Values.Enabled then self:Start() else self:Stop() end
end

function EspClass:Set(Key, Value)
	local Setter = Library.config_flags["esp_" .. string.lower(Key)]
	if Setter then
		Setter(Value)
	else
		self.Values[Key] = Value
	end
end

function EspClass:Get(Key)
	return self.Values[Key]
end

function Window:esp_manager(O)
	O = type(O) == "table" and O or {}
	local Esp = setmetatable({
		Values = {},
		Hidden = {},
		Objects = {},
		Connections = {},
		Running = false,
		BindName = "SfixEspUpdate",
		Rotation = 0,
		Clock = 0,
		GradVersion = 0,
		Animated = false,
	}, EspClass)
	for K, V in pairs(ESP_DEFAULTS) do Esp.Values[K] = V end
	for K, Entry in pairs(O.settings or {}) do
		if type(Entry) == "table" and not (typeof(Entry) == "Color3") then
			if Entry.Value ~= nil then Esp.Values[K] = Entry.Value end
			if Entry.Visible == false then Esp.Hidden[K] = true end
		else
			Esp.Values[K] = Entry
		end
	end
	Esp.C1, Esp.C2 = Esp.Values.GradientColor1, Esp.Values.GradientColor2
	Esp.Sequence = ColorSequence.new(Esp.C1, Esp.C2)
	Library.esp = Esp

	local Values, Hidden = Esp.Values, Esp.Hidden
	local function Flag(Key) return "esp_" .. string.lower(Key) end

	local function Toggle(Sec, Key, Name, ColorKey)
		if Hidden[Key] then return nil end
		local T = Sec:toggle({
			name = Name,
			default = Values[Key],
			flag = Flag(Key),
			seperator = true,
			callback = function(V)
				if Key == "Enabled" then Esp:SetEnabled(V) else Values[Key] = V end
			end,
		})
		if ColorKey and not Hidden[ColorKey] then
			T:colorpicker({ color = Values[ColorKey], flag = Flag(ColorKey), callback = function(C) Values[ColorKey] = C end })
		end
		return T
	end

	local function Option(Sub, Key, Name)
		if Sub and not Hidden[Key] then
			Sub:toggle({ name = Name, default = Values[Key], flag = Flag(Key), callback = function(V) Values[Key] = V end })
		end
	end

	local function Slide(Sub, Key, Name, Min, Max, Decimals, Suffix)
		if Sub and not Hidden[Key] then
			Sub:slider({ name = Name, min = Min, max = Max, default = Values[Key], decimals = Decimals or 0, suffix = Suffix, flag = Flag(Key), callback = function(V) Values[Key] = V end })
		end
	end

	local function Pick(Sub, Key, Name)
		if Sub and not Hidden[Key] then
			Sub:colorpicker({ name = Name, color = Values[Key], flag = Flag(Key), callback = function(C) Values[Key] = C end })
		end
	end

	local Pages = self:tab({ name = O.name or "Esp", icon = O.icon or "scan-eye", tabs = { O.page or "Players" } })
	local Page1 = Pages

	local Col1 = Page1:column()
	local Players1 = Col1:section({ name = "Players", icon = "users", default = true })
	Toggle(Players1, "Enabled", "Enabled")
	Toggle(Players1, "TeamCheck", "Team Check")

	local BoxToggle = Toggle(Players1, "Box", "Box", "BoxColor")
	if BoxToggle then
		local Sub = BoxToggle:settings()
		Option(Sub, "BoxGradient", "Gradient")
		Option(Sub, "BoxFill", "Fill")
		Pick(Sub, "FillColor", "Fill Color")
		Slide(Sub, "FillTransparency", "Fill Transparency", 0, 1, 2)
	end

	local SkeletonToggle = Toggle(Players1, "Skeleton", "Skeleton", "SkeletonColor")
	if SkeletonToggle then
		local Sub = SkeletonToggle:settings()
		Option(Sub, "SkeletonGradient", "Gradient")
		Slide(Sub, "SkeletonThickness", "Thickness", 1, 5, 0)
	end

	local DotToggle = Toggle(Players1, "Dot", "Dot", "DotColor")
	if DotToggle then
		local Sub = DotToggle:settings()
		Option(Sub, "DotGradient", "Gradient")
		Slide(Sub, "DotSize", "Size", 2, 20, 0)
	end

	local GlowToggle = Toggle(Players1, "Glow", "Glow", "GlowColor")
	if GlowToggle then
		local Sub = GlowToggle:settings()
		Option(Sub, "GlowGradient", "Gradient")
		Slide(Sub, "GlowTransparency", "Transparency", 0, 1, 2)
	end

	local TracerToggle = Toggle(Players1, "Tracer", "Tracer", "TracerColor")
	if TracerToggle then
		Option(TracerToggle:settings(), "TracerGradient", "Gradient")
	end

	local Col2 = Page1:column()
	local Info = Col2:section({ name = "Info", icon = "info", default = true })

	local HealthBar = Toggle(Info, "HealthBar", "Health Bar")
	if HealthBar then Option(HealthBar:settings(), "HealthBarGradient", "Gradient") end

	local HealthText = Toggle(Info, "HealthText", "Health Text")
	if HealthText then Option(HealthText:settings(), "HealthTextGradient", "Gradient") end

	local NameToggle = Toggle(Info, "Name", "Name", "NameColor")
	if NameToggle then
		local Sub = NameToggle:settings()
		Option(Sub, "DisplayName", "Show Display Names")
		Option(Sub, "NameGradient", "Gradient")
	end

	Toggle(Info, "Avatar", "Avatar")

	local WeaponToggle = Toggle(Info, "Weapon", "Weapon", "WeaponColor")
	if WeaponToggle then Option(WeaponToggle:settings(), "WeaponGradient", "Gradient") end

	local BackpackToggle = Toggle(Info, "Backpack", "Backpack", "BackpackColor")
	if BackpackToggle then Option(BackpackToggle:settings(), "BackpackGradient", "Gradient") end

	local DistanceToggle = Toggle(Info, "Distance", "Distance", "DistanceColor")
	if DistanceToggle then Option(DistanceToggle:settings(), "DistanceGradient", "Gradient") end

	local Col3 = Page1:column()
	local General = Col3:section({ name = "General", icon = "sliders-horizontal", default = true })
	Slide(General, "MaxDistance", "Max Distance", 100, 5000, 0, "m")
	Slide(General, "TextSize", "Text Size", 10, 20, 0)
	Pick(General, "GradientColor1", "Gradient Color 1")
	Pick(General, "GradientColor2", "Gradient Color 2")
	Option(General, "GradientAnimation", "Gradient Animation")
	Slide(General, "GradientAnimationSpeed", "Animation Speed", 1, 20, 0)

	local Preview = Col3:section({ name = "Preview", icon = "eye", default = true })
	Preview:preview({ esp = Esp, height = 260 })

	if Values.Enabled then Esp:SetEnabled(true) end
	return Esp
end

function Window:home_manager(O)
	O = type(O) == "table" and O or {}
	local Page1 = self:tab({ name = O.name or "Home", icon = O.icon or "home", tabs = { "Home" } })
	local Col1 = Page1:column()
	local Profile = Col1:section({ name = "Profile", icon = "user", default = true })
	local Card = New("Frame", { Size = UDim2.new(1, 0, 0, 64), BackgroundTransparency = 1 }, Profile.Body)
	local Avatar = New("ImageLabel", { Size = UDim2.fromOffset(60, 60), BackgroundColor3 = Theme.Field, Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150" }, Card)
	Stroke(Avatar)
	Label(Card, LocalPlayer.DisplayName, { Size = UDim2.new(1, -70, 0, 20), Position = UDim2.fromOffset(68, 4), Font = Theme.Bold, TextSize = 16 })
	Label(Card, "@" .. LocalPlayer.Name, { Size = UDim2.new(1, -70, 0, 16), Position = UDim2.fromOffset(68, 26), TextSize = 13, TextColor3 = Theme.Dim })
	Label(Card, "ID " .. LocalPlayer.UserId, { Size = UDim2.new(1, -70, 0, 16), Position = UDim2.fromOffset(68, 42), TextSize = 13, TextColor3 = Theme.Dim })
	local Col2 = Page1:column()
	local Session = Col2:section({ name = "Session", icon = "info", default = true })
	Session:label({ name = self.GameName })
	local PlayersLabel = Session:label({ name = "" })
	local UptimeLabel = Session:label({ name = "" })
	local Start = os.clock()
	local Acc = 0
	RunService.Heartbeat:Connect(function(Dt)
		Acc += Dt
		if Acc < 1 then return end
		Acc = 0
		PlayersLabel:set("Players - " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers)
		local Elapsed = math.floor(os.clock() - Start)
		UptimeLabel:set(string.format("Session - %02d:%02d:%02d", Elapsed // 3600, (Elapsed % 3600) // 60, Elapsed % 60))
	end)
	return Page1
end

function Window:set_visible(V)
	self.Main.Visible = V
	if not V and Library.popup then Library.popup.Visible = false end
end

function Window:set_watermark(V)
	self.Mark.Visible = V
	self.Info.Visible = V
end

function Window:set_scale(V)
	Library.scale_mult = V
	UpdateScale()
end

function Window:unload()
	Library:unload()
end

function Library:window(O)
	O = type(O) == "table" and O or {}
	local Accent = O.AccentColor or O.accent
	if typeof(Accent) == "Color3" then self:update_theme("accent", Accent) end
	local Folder = O.ConfigFolder or O.config_folder
	if type(Folder) == "string" and Folder ~= "" then ConfigManager:SetFolder(Folder) end

	local Title = O.name or "Sfix"
	local Suffix = O.suffix or "tech"
	local W = setmetatable({ Tabs = {}, Order = 0, GameName = O.gameInfo or O.game_info or "Sfix" }, Window)

	local Mark = New("Frame", { Size = UDim2.fromOffset(0, 28), AutomaticSize = Enum.AutomaticSize.X, Position = UDim2.fromOffset(12, 12), BackgroundColor3 = Theme.Bg }, Gui)
	Stroke(Mark)
	AddScale(Mark)
	local MarkRow = New("Frame", { Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1 }, Mark)
	New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, MarkRow)
	New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 10) }, MarkRow)
	local Square = New("Frame", { Size = UDim2.fromOffset(10, 10), BackgroundColor3 = WHITE, BorderSizePixel = 0, LayoutOrder = 1 }, MarkRow)
	AccentGrad(Square)
	Label(MarkRow, Title .. " | " .. Suffix, { Size = UDim2.fromOffset(0, 28), AutomaticSize = Enum.AutomaticSize.X, Font = Theme.Bold, LayoutOrder = 2 })
	Glow(Mark, UDim2.new(0, 0, 1, -1), 1)
	W.Mark = Mark

	local Info = New("Frame", { Size = UDim2.fromOffset(0, 28), AutomaticSize = Enum.AutomaticSize.X, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12), BackgroundColor3 = Theme.Bg }, Gui)
	Stroke(Info)
	AddScale(Info)
	New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, Info)
	local InfoText = Label(Info, "FPS: 0   PING: 0ms", { Size = UDim2.fromOffset(0, 28), AutomaticSize = Enum.AutomaticSize.X, TextColor3 = Theme.Dim, TextSize = 13 })
	W.Info = Info

	local Main = New("Frame", { Size = UDim2.fromOffset(880, 500), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(10, 10, 15) }, Gui)
	Stroke(Main, Color3.fromRGB(60, 60, 78))
	W.MainScale = AddScale(Main)
	W.Main = Main
	for I = 1, 12 do
		local E = I * 3
		local Layer = New("Frame", { Size = UDim2.new(1, E * 2, 1, E * 2), Position = UDim2.fromOffset(-E, -E), BackgroundColor3 = BLACK, BackgroundTransparency = 0.975, BorderSizePixel = 0, ZIndex = 0 }, Main)
		New("UICorner", { CornerRadius = UDim.new(0, E) }, Layer)
	end
	Glow(Main, UDim2.new(0, 0, 0, 0), 2).ZIndex = 5

	local Inner = New("Frame", { Size = UDim2.new(1, -8, 1, -8), Position = UDim2.fromOffset(4, 4), BackgroundColor3 = Theme.Bg }, Main)
	Stroke(Inner)
	Grad(Inner, Color3.fromRGB(17, 17, 24), Color3.fromRGB(11, 11, 16))

	local Header = New("Frame", { Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, Inner)
	Grad(Header, Color3.fromRGB(28, 28, 38), Color3.fromRGB(17, 17, 24))
	New("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = Theme.Border, BorderSizePixel = 0 }, Header)
	W.TabBar = New("ScrollingFrame", { Size = UDim2.new(1, -60, 1, 0), Position = UDim2.fromOffset(6, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollingDirection = Enum.ScrollingDirection.X, Active = false }, Header)
	New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, W.TabBar)

	local Close = New("TextButton", { Size = UDim2.fromOffset(20, 20), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), BackgroundColor3 = WHITE, Text = "", AutoButtonColor = false }, Header)
	Styled(Close)
	local X = New("ImageLabel", { Size = UDim2.fromOffset(14, 14), Position = UDim2.fromOffset(3, 3), BackgroundTransparency = 1, ImageColor3 = Theme.Text }, Close)
	ApplyIcon(X, "x")

	W.Content = New("Frame", { Size = UDim2.new(1, -20, 1, -54), Position = UDim2.fromOffset(10, 50), BackgroundTransparency = 1 }, Inner)
	UpdateScale()

	local Dragging, Start, Origin = false, nil, nil
	Header.InputBegan:Connect(function(Input)
		if IsPress(Input) then Dragging, Start, Origin = true, Input.Position, Main.Position end
	end)
	UIS.InputChanged:Connect(function(Input)
		if Dragging and IsMove(Input) then
			local D = Input.Position - Start
			Main.Position = UDim2.new(Origin.X.Scale, Origin.X.Offset + D.X, Origin.Y.Scale, Origin.Y.Offset + D.Y)
		end
	end)
	UIS.InputEnded:Connect(function(Input)
		if IsPress(Input) then Dragging = false end
	end)

	local Toggle = New("TextButton", { Size = UDim2.fromOffset(36, 36), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), BackgroundColor3 = WHITE, Text = "", AutoButtonColor = false }, Gui)
	Styled(Toggle)
	AddScale(Toggle)
	local Ico = New("ImageLabel", { Size = UDim2.fromOffset(20, 20), Position = UDim2.fromOffset(8, 8), BackgroundTransparency = 1 }, Toggle)
	ApplyIcon(Ico, "menu")
	OnAccent(function() Ico.ImageColor3 = Theme.Accent end)
	UpdateScale()

	Close.MouseButton1Click:Connect(function() W:set_visible(false) end)
	Toggle.MouseButton1Click:Connect(function() W:set_visible(not Main.Visible) end)

	Gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateScale)

	local Frames, Last = 0, os.clock()
	RunService.RenderStepped:Connect(function()
		Frames += 1
		if os.clock() - Last >= 0.5 then
			local Ping = 0
			pcall(function() Ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
			InfoText.Text = string.format("FPS: %d   PING: %dms", math.floor(Frames / (os.clock() - Last)), Ping)
			Frames, Last = 0, os.clock()
		end
	end)

	Library.window_object = W
	return W
end

function Library:notify(O)
	O = type(O) == "table" and O or { name = "Sfix", info = tostring(O) }
	local Title = O.name or "Sfix"
	local Text = O.info or ""
	local Duration = O.duration or 4
	if not self.NotifyHolder then
		local Holder = New("Frame", { Size = UDim2.fromOffset(250, 420), AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -14), BackgroundTransparency = 1 }, Gui)
		New("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, Holder)
		AddScale(Holder)
		UpdateScale()
		self.NotifyHolder = Holder
	end
	local Slot = New("Frame", { Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1 }, self.NotifyHolder)
	local Toast = New("Frame", { Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(280, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, Slot)
	Grad(Toast, Color3.fromRGB(30, 30, 41), Color3.fromRGB(16, 16, 23))
	Stroke(Toast)
	local Bar = New("Frame", { Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, Toast)
	AccentGrad(Bar)
	local Img = New("ImageLabel", { Size = UDim2.fromOffset(20, 20), Position = UDim2.fromOffset(14, 12), BackgroundTransparency = 1, ImageColor3 = Theme.Accent }, Toast)
	ApplyIcon(Img, O.icon or "bell")
	Label(Toast, Title, { Size = UDim2.new(1, -50, 0, 16), Position = UDim2.fromOffset(42, 8), Font = Theme.Bold, TextColor3 = Theme.Accent })
	Label(Toast, Text, { Size = UDim2.new(1, -50, 0, 16), Position = UDim2.fromOffset(42, 26), TextSize = 13, TextColor3 = Theme.Dim, TextTruncate = Enum.TextTruncate.AtEnd })
	local Progress = New("Frame", { Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0 }, Toast)
	TweenService:Create(Toast, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.fromOffset(0, 0) }):Play()
	TweenService:Create(Progress, TweenInfo.new(Duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) }):Play()
	task.delay(Duration, function()
		local Out = TweenService:Create(Toast, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.fromOffset(280, 0) })
		Out:Play()
		Out.Completed:Wait()
		Slot:Destroy()
	end)
end

function Library:unload()
	if self.esp then self.esp:Unload() end
	Gui:Destroy()
end

function ConfigManager:SetFolder(Name)
	Name = string.gsub(Name, "[/\\]+$", "")
	self.Folder = Name
	pcall(function()
		local Path = ""
		for Segment in string.gmatch(Name, "[^/\\]+") do
			Path = Path == "" and Segment or (Path .. "/" .. Segment)
			if not isfolder(Path) then makefolder(Path) end
		end
	end)
end

function ConfigManager:Path(Name)
	return self.Folder .. "/" .. Name .. self.Extension
end

function ConfigManager:List()
	local Names = {}
	pcall(function()
		if not isfolder(self.Folder) then makefolder(self.Folder) end
		for _, Path in ipairs(listfiles(self.Folder)) do
			local Name = string.match(Path, "([^/\\]+)%" .. self.Extension .. "$")
			if Name then table.insert(Names, Name) end
		end
		table.sort(Names)
	end)
	return Names
end

function ConfigManager:Exists(Name)
	local Found = false
	pcall(function() Found = isfile(self:Path(Name)) end)
	return Found
end

function ConfigManager:Serialize()
	local Data = {}
	for K, V in pairs(Library.flags) do
		if not self.Ignore[K] then Data[K] = V end
	end
	return HttpService:JSONEncode(Data)
end

function ConfigManager:Apply(Json)
	local Data = HttpService:JSONDecode(Json)
	for K, V in pairs(Data) do
		local Setter = Library.config_flags[K]
		if Setter and not self.Ignore[K] then Setter(V) end
	end
end

function ConfigManager:Save(Name)
	if not Name or Name == "" then return false end
	return (pcall(function()
		if not isfolder(self.Folder) then makefolder(self.Folder) end
		writefile(self:Path(Name), self:Serialize())
	end))
end

function ConfigManager:Load(Name)
	if not Name or Name == "" then return false end
	return (pcall(function() self:Apply(readfile(self:Path(Name))) end))
end

function ConfigManager:Delete(Name)
	if not Name or Name == "" then return false end
	return (pcall(function() delfile(self:Path(Name)) end))
end

function ConfigManager:SetAutoload(Name)
	return (pcall(function()
		if not isfolder(self.Folder) then makefolder(self.Folder) end
		writefile(self.Folder .. "/autoload.txt", Name or "")
	end))
end

function ConfigManager:GetAutoload()
	local Name
	pcall(function() Name = readfile(self.Folder .. "/autoload.txt") end)
	if Name == "" then return nil end
	return Name
end

function ConfigManager:Autoload()
	local Name = self:GetAutoload()
	if Name and self:Exists(Name) then return self:Load(Name), Name end
	return false
end

function Library:get_config()
	return ConfigManager:Serialize()
end

function Library:load_config(Json)
	return (pcall(function() ConfigManager:Apply(Json) end))
end

function Library:init_config(Win)
	Win = Win or self.window_object
	Win:seperator({ name = "Settings" })
	local Page1 = Win:tab({ name = "Configs", icon = "settings", tabs = { "Main" } })

	local Col1 = Page1:column()
	local Configs = Col1:section({ name = "Configs", icon = "folder", default = true })
	local List = Configs:list({ height = 110, flag = "config_name_list" })
	local Status = Configs:label({ name = "" })
	Configs:textbox({ name = "Config name", flag = "config_name_text" })
	local function Refresh() List:set_options(ConfigManager:List()) end
	local function Target()
		local Typed = Library.flags.config_name_text
		if Typed and Typed ~= "" then return Typed end
		return List.selected
	end
	Configs:button_row({
		name = "Save",
		callback = function()
			local Name = Target()
			if Name and ConfigManager:Save(Name) then
				Status:set("saved " .. Name)
				Refresh()
				Library:notify({ name = "Configs", info = "Saved config: " .. Name, icon = "save" })
			end
		end,
	}, {
		name = "Load",
		callback = function()
			if List.selected and ConfigManager:Load(List.selected) then
				Status:set("loaded " .. List.selected)
				Library:notify({ name = "Configs", info = "Loaded config: " .. List.selected, icon = "download" })
			end
		end,
	})
	Configs:button_row({
		name = "Delete",
		callback = function()
			if List.selected then
				local Name = List.selected
				ConfigManager:Delete(Name)
				Status:set("deleted " .. Name)
				Refresh()
			end
		end,
	}, { name = "Refresh", callback = Refresh })
	Configs:button_row({
		name = "Set autoload",
		callback = function()
			if List.selected and ConfigManager:SetAutoload(List.selected) then Status:set("autoload " .. List.selected) end
		end,
	}, {
		name = "Clear autoload",
		callback = function()
			ConfigManager:SetAutoload("")
			Status:set("autoload cleared")
		end,
	})
	Refresh()

	local Col2 = Page1:column()
	local Menu = Col2:section({ name = "Menu", icon = "sliders-horizontal", default = true })
	Menu:colorpicker({ name = "Menu Accent", color = Theme.Accent, flag = "menu_accent", callback = function(C) Library:update_theme("accent", C) end })
	Menu:toggle({ name = "Watermark", default = true, flag = "menu_watermark", callback = function(V) Win:set_watermark(V) end })
	Menu:slider({ name = "Menu scale", min = 0.6, max = 1.4, default = 1, decimals = 2, flag = "menu_scale", callback = function(V) Win:set_scale(V) end })
	Menu:button({ name = "Test notification", callback = function() Library:notify({ name = "Sfix", info = "This is a test notification" }) end })
	Menu:button({ name = "Unload menu", callback = function() Win:unload() end })

	local Loaded, Name = ConfigManager:Autoload()
	if Loaded then Library:notify({ name = "Configs", info = "Autoloaded " .. Name, icon = "download" }) end
end

return Library
