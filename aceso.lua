local cloneref = cloneref or function(I) return I end
local Players          = cloneref(game:GetService("Players"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local RunService       = cloneref(game:GetService("RunService"))
local TweenService     = cloneref(game:GetService("TweenService"))
local HttpService      = cloneref(game:GetService("HttpService"))
local CoreGui          = cloneref(game:GetService("CoreGui"))
local Stats            = cloneref(game:GetService("Stats"))
local LocalPlayer      = Players.LocalPlayer
local ShotEvent = Instance.new("BindableEvent")
local Library = {
	Flags = {}, Options = {}, Connections = {},
	Folder = "aceso", ConfigFolder = "aceso/configs",
	MenuKey = Enum.KeyCode.Insert, Open = false, Quality = 0.75,
	_Keybinds = {}, _Rainbows = {}, _Popup = nil, _Drag = nil, _Listening = nil, _Floats = {},
}
local Theme = {
	Accent     = Color3.fromRGB(21, 187, 169),
	Background = Color3.fromRGB(30, 30, 30),
	Sidebar    = Color3.fromRGB(56, 56, 56),
	Section    = Color3.fromRGB(42, 42, 42),
	Element    = Color3.fromRGB(42, 42, 42),
	Hover      = Color3.fromRGB(45, 45, 45),
	Stroke     = Color3.fromRGB(58, 58, 58),
	Text       = Color3.fromRGB(240, 242, 245),
	TextDim    = Color3.fromRGB(142, 142, 142),
	Risky      = Color3.fromRGB(230, 90, 90),
}
Library.Theme = Theme
local Fonts = {
	Regular = Font.new("rbxasset://fonts/families/Arial.json", Enum.FontWeight.Regular),
	Medium  = Font.new("rbxasset://fonts/families/Arial.json", Enum.FontWeight.Regular),
	Bold    = Font.new("rbxasset://fonts/families/Arial.json", Enum.FontWeight.Bold),
}
Library.Fonts = Fonts
local MainFont = Fonts.Medium
pcall(function()
	if not isfolder(Library.Folder) then makefolder(Library.Folder) end
	if not isfolder(Library.ConfigFolder) then makefolder(Library.ConfigFolder) end
end)
Library._EarlyUnload = {}
function Library:OnUnloadLater(Fn) self._EarlyUnload[#self._EarlyUnload + 1] = Fn end
local function Try(Fn, ...)
	if typeof(Fn) ~= "function" then return false end
	return pcall(Fn, ...)
end
local Binds = {}
local function Bind(Key, Fn, Inst)
	Binds[#Binds + 1] = { Key, Fn, Inst }
	Fn(Theme[Key])
end
local function PruneBinds()
	local Out = {}
	for _, B in ipairs(Binds) do
		if not B[3] or B[3].Parent then Out[#Out + 1] = B end
	end
	Binds = Out
end
function Library:SetTheme(Key, Color)
	Theme[Key] = Color
	PruneBinds()
	for _, B in ipairs(Binds) do
		if B[1] == Key or B[1] == "*" then pcall(B[2], Theme[B[1]]) end
	end
end
local OrderN = 0
local function NextOrder() OrderN = OrderN + 1; return OrderN end
local TextClasses = { TextLabel = true, TextButton = true, TextBox = true }
local function New(Class, Props)
	local I = Instance.new(Class)
	if I:IsA("GuiObject") then I.BorderSizePixel = 0 end
	if TextClasses[Class] then
		I.BackgroundTransparency = 1
		I.FontFace = MainFont
		I.TextSize = 13
		I.TextColor3 = Theme.Text
		I.Text = ""
		if Class == "TextButton" then I.AutoButtonColor = false end
		if Class == "TextBox" then I.ClearTextOnFocus = false end
	end
	for K, V in pairs(Props or {}) do
		if K ~= "Parent" then I[K] = V end
	end
	if Props and Props.Parent then I.Parent = Props.Parent end
	return I
end
local function Corner(R, P)
	if Library.Square then return New("UICorner", { CornerRadius = UDim.new(0, 0) }) end
	return New("UICorner", { CornerRadius = UDim.new(0, R), Parent = P })
end
local function Stroke(P, Key, T)
	local S = New("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Transparency = T or 0, Parent = P })
	Bind(Key or "Stroke", function(C) S.Color = C end, S)
	return S
end
local function Pad(P, T, R, B, L)
	return New("UIPadding", { PaddingTop = UDim.new(0, T), PaddingRight = UDim.new(0, R or T), PaddingBottom = UDim.new(0, B or T), PaddingLeft = UDim.new(0, L or R or T), Parent = P })
end
local function RealTween(I, T, Props, Style, Dir)
	local Tw = TweenService:Create(I, TweenInfo.new(T, Style or Enum.EasingStyle.Quint, Dir or Enum.EasingDirection.Out), Props)
	Tw:Play()
	return Tw
end
local function Tween(I, _, Props)
	for K, V in pairs(Props) do I[K] = V end
end
local function Paint(I, Prop, Key) Bind(Key, function(C) I[Prop] = C end, I) end
Library.New, Library.Corner, Library.Stroke, Library.Pad, Library.Tween, Library.Bind, Library.Paint = New, Corner, Stroke, Pad, RealTween, Bind, Paint
local function Inside(G, P)
	local A, S = G.AbsolutePosition, G.AbsoluteSize
	return P.X >= A.X and P.X <= A.X + S.X and P.Y >= A.Y and P.Y <= A.Y + S.Y
end
local function KeyName(K)
	if not K then return "none" end
	if K == Enum.UserInputType.MouseButton1 then return "mb1" end
	if K == Enum.UserInputType.MouseButton2 then return "mb2" end
	if K == Enum.UserInputType.MouseButton3 then return "mb3" end
	return K.Name:lower()
end
local function KeyFromName(N)
	if type(N) ~= "string" or N == "None" or N == "none" then return nil end
	local Ok, K = pcall(function() return Enum.KeyCode[N] end)
	if Ok and K then return K end
	Ok, K = pcall(function() return Enum.UserInputType[N] end)
	if Ok and K then return K end
	return nil
end
function Library:Connect(Signal, Fn)
	local C = Signal:Connect(Fn)
	table.insert(self.Connections, C)
	return C
end
function Library:_Opt(Flag, Obj, Value)
	Obj.Flag = Flag
	Obj.Serialize = Obj.Serialize or function(S) return S:Get() end
	Obj.Deserialize = Obj.Deserialize or function(S, V) S:Set(V) end
	self.Options[Flag] = Obj
	self.Flags[Flag] = Value
end
function Library:DropFlags(Prefix)
	for K in pairs(self.Options) do
		if type(K) == "string" and K:sub(1, #Prefix) == Prefix then self.Options[K] = nil; self.Flags[K] = nil end
	end
	PruneBinds()
end
local Gui = New("ScreenGui", {
	Name = HttpService:GenerateGUID(false):sub(1, 8), ResetOnSpawn = false, IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
})
do
	Try(protect_gui or (syn and syn.protect_gui), Gui)
	local Ok = pcall(function() Gui.Parent = (gethui and gethui()) or CoreGui end)
	if not Ok or not Gui.Parent then Gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
end
Library.Gui = Gui
local Overlay = New("Frame", { Name = "Overlay", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 50, Parent = Gui })
Library.Overlay = Overlay
local function MousePos() return UserInputService:GetMouseLocation() + Overlay.AbsolutePosition end
Library.MousePos = MousePos
local SER = {
	Bright       = Color3.fromRGB(27, 241, 218),
	AccentHover  = Color3.fromRGB(26, 224, 203),
	AccentActive = Color3.fromRGB(31, 106, 98),
	FrameActive  = Color3.fromRGB(39, 39, 39),
	Shadow       = Color3.fromRGB(16, 16, 16),
	Scroll       = Color3.fromRGB(79, 79, 79),
}
Library.SER = SER
local function ShadowText(Parent, Props)
	local Z = Props.ZIndex or 1
	Props.Parent = Parent
	local S = New("TextLabel", Props)
	S.Position = Props.Position + UDim2.fromOffset(1, 1)
	S.TextColor3 = SER.Shadow
	S.ZIndex = Z
	local L = New("TextLabel", Props)
	L.ZIndex = Z + 1
	L:GetPropertyChangedSignal("Text"):Connect(function() S.Text = L.Text end)
	L:GetPropertyChangedSignal("Visible"):Connect(function() S.Visible = L.Visible end)
	return L
end
Library.ShadowText = ShadowText
local function Moon(Parent, X, Y, Z)
	local M = New("Frame", { Position = UDim2.fromOffset(X, Y), Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1, ZIndex = Z, Parent = Parent })
	local C = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Accent, ZIndex = Z, Parent = M })
	New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = C })
	local K = New("Frame", { Position = UDim2.fromOffset(4, -2), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = Theme.Background, ZIndex = Z + 1, Parent = M })
	New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = K })
	return M
end
local function Shell(F)
	F.BackgroundColor3 = Theme.Background
	New("UICorner", { CornerRadius = UDim.new(0, 5), Parent = F })
	local St = New("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = F })
	New("UIGradient", { Rotation = 90, Color = ColorSequence.new(Theme.Accent, SER.AccentActive), Parent = St })
end
do
	local Card = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(360, 90), ZIndex = 90, Parent = Gui })
	Shell(Card)
	Moon(Card, 10, 10, 91)
	ShadowText(Card, { Position = UDim2.fromOffset(33, 10), Size = UDim2.new(1, -43, 0, 14), Text = "aceso", TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 92 })
	local Step = New("TextLabel", { Position = UDim2.fromOffset(10, 40), Size = UDim2.new(1, -70, 0, 14), Text = "starting", TextColor3 = Theme.TextDim, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 91, Parent = Card })
	local Pct = New("TextLabel", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 40), Size = UDim2.fromOffset(60, 14), Text = "0%", TextColor3 = Theme.TextDim, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 91, Parent = Card })
	local Track = New("Frame", { Position = UDim2.fromOffset(10, 58), Size = UDim2.new(1, -20, 0, 14), BackgroundColor3 = Theme.Element, ZIndex = 91, Parent = Card })
	Stroke(Track)
	local Fill = New("Frame", { Position = UDim2.fromOffset(2, 2), Size = UDim2.new(0, 0, 1, -4), BackgroundColor3 = Theme.Accent, ZIndex = 92, Parent = Track })
	Library._Loading = true
	function Library:LoaderStep(Text, P)
		if not Card.Parent then return end
		Step.Text = Text
		if P then
			Fill.Size = UDim2.new(P, -4 * P, 1, -4)
			Pct.Text = math.floor(P * 100 + 0.5) .. "%"
		end
		task.wait()
	end
	function Library:LoaderDone(After)
		Library:LoaderStep("ready", 1)
		task.wait(0.15)
		Library._Loading = false
		Card:Destroy()
		if After then After() end
	end
end
Library:LoaderStep("starting aceso", 0.05)
function Library:OverMenu()
	local M = MousePos()
	if self.Window and self.Window.Main.Visible and Inside(self.Window.Main, M) then return true end
	for _, F in ipairs(self._Floats) do
		if F.Main.Visible and Inside(F.Main, M) then return true end
	end
	return false
end
function Library:ClosePopup()
	local P = self._Popup
	if not P then return end
	self._Popup = nil
	if P.OnClose then pcall(P.OnClose) end
	P.Frame:Destroy()
end
function Library:OpenPopup(Frame, Owner, OnClose)
	self:ClosePopup()
	self._Popup = { Frame = Frame, Owner = Owner, OnClose = OnClose }
end
Library:Connect(UserInputService.InputChanged, function(I)
	local T = I.UserInputType
	if Library._Drag and (T == Enum.UserInputType.MouseMovement or T == Enum.UserInputType.Touch) then
		Library._Drag(I)
	end
end)
Library:Connect(UserInputService.InputEnded, function(I)
	local T = I.UserInputType
	if T == Enum.UserInputType.MouseButton1 or T == Enum.UserInputType.Touch then
		if Library._DragEnd then pcall(Library._DragEnd) end
		Library._Drag, Library._DragEnd = nil, nil
	end
	for _, B in ipairs(Library._Keybinds) do
		if B:Matches(I) then B:Release() end
	end
end)
Library:Connect(UserInputService.InputBegan, function(I)
	local T = I.UserInputType
	local Mouse = MousePos()
	if (T == Enum.UserInputType.MouseButton1 or T == Enum.UserInputType.MouseButton2) and Library._Popup then
		local P = Library._Popup
		if not Inside(P.Frame, Mouse) and not (P.Owner and Inside(P.Owner, Mouse)) then
			Library:ClosePopup()
		end
	end
	local L = Library._Listening
	if L then
		if T == Enum.UserInputType.Keyboard then
			Library._Listening = nil
			if I.KeyCode == Enum.KeyCode.Escape or I.KeyCode == Enum.KeyCode.Backspace then L:SetKey(nil) else L:SetKey(I.KeyCode) end
		elseif T == Enum.UserInputType.MouseButton2 or T == Enum.UserInputType.MouseButton3 then
			Library._Listening = nil
			L:SetKey(T)
		elseif T == Enum.UserInputType.MouseButton1 then
			Library._Listening = nil
			L:Render()
		end
		return
	end
	if UserInputService:GetFocusedTextBox() then return end
	if T == Enum.UserInputType.Keyboard and I.KeyCode == Library.MenuKey then Library:Toggle() end
	if T == Enum.UserInputType.Keyboard and I.KeyCode == Enum.KeyCode.Slash and Library.Open and Library._SearchBox and Library.Window and Library.Window.Main.Visible then
		local B = Library._SearchBox
		task.defer(function() B:CaptureFocus(); task.defer(function() B.Text = "" end) end)
	end
	for _, B in ipairs(Library._Keybinds) do
		if B:Matches(I) then B:Press() end
	end
end)
local RainbowT = 0
Library:Connect(RunService.Heartbeat, function()
	if #Library._Rainbows == 0 then return end
	local Now = os.clock()
	if Now - RainbowT < 0.05 then return end
	RainbowT = Now
	local Hue = (Now * 0.12) % 1
	for _, Fn in ipairs(Library._Rainbows) do pcall(Fn, Hue) end
end)
local function OptionPopup(Anchor, Options, IsSel, OnPick, KeepOpen, OnClose, MinWidth)
	local A, Sz = Anchor.AbsolutePosition - Overlay.AbsolutePosition, Anchor.AbsoluteSize
	local RowH, MaxRows = 17, 8
	local N = #Options
	local W = math.max(Sz.X, MinWidth or 0)
	local H = math.max(1, math.min(N, MaxRows)) * RowH + 6
	local X = W > Sz.X and (A.X + Sz.X - W) or A.X
	local Y = A.Y + Sz.Y + 2
	if Y + H > Overlay.AbsoluteSize.Y - 6 then Y = A.Y - H - 2 end
	local P = New("Frame", { Position = UDim2.fromOffset(X, Y), Size = UDim2.fromOffset(W, H), ZIndex = 80, Parent = Overlay })
	Paint(P, "BackgroundColor3", "Section")
	Stroke(P)
	local SF = New("ScrollingFrame", {
		Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -6), BackgroundTransparency = 1, ZIndex = 81,
		CanvasSize = UDim2.fromOffset(0, N * RowH), ScrollBarThickness = N > MaxRows and 4 or 0,
		VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
		ScrollBarImageColor3 = SER.Scroll, ScrollingDirection = Enum.ScrollingDirection.Y, Parent = P,
	})
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = SF })
	local Rows = {}
	local function Repaint()
		for O, R in pairs(Rows) do R.TextColor3 = IsSel(O) and Theme.Text or Theme.TextDim end
	end
	for Idx, O in ipairs(Options) do
		local R = New("TextButton", {
			Size = UDim2.new(1, 0, 0, RowH), Text = tostring(O), TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1, LayoutOrder = Idx, ZIndex = 82, Parent = SF,
		})
		R.MouseEnter:Connect(function() R.TextColor3 = Theme.Accent end)
		R.MouseLeave:Connect(Repaint)
		R.MouseButton1Click:Connect(function()
			OnPick(O)
			if KeepOpen then Repaint() else Library:ClosePopup() end
		end)
		Rows[O] = R
	end
	Repaint()
	Library:OpenPopup(P, Anchor, OnClose)
	return P
end
Library.OptionPopup = OptionPopup
local function MakeKeybind(Parent, Opts, Flag, Name, Handler)
	local B = { Key = Opts.Default, Mode = Opts.Mode or "Toggle", Name = Name, NoList = Opts.NoList, Handler = Handler }
	local Btn = New("TextButton", { Size = UDim2.fromOffset(40, 19), LayoutOrder = NextOrder(), BackgroundTransparency = 0, Parent = Parent })
	Paint(Btn, "BackgroundColor3", "Element")
	Paint(Btn, "TextColor3", "Text")
	Stroke(Btn)
	Btn.MouseEnter:Connect(function() Btn.BackgroundColor3 = Theme.Hover end)
	Btn.MouseLeave:Connect(function() Btn.BackgroundColor3 = Theme.Element end)
	Btn:GetPropertyChangedSignal("TextBounds"):Connect(function()
		Btn.Size = UDim2.fromOffset(math.max(Btn.TextBounds.X + 8, 19), 19)
	end)
	function B:Render() Btn.Text = (Library._Listening == self) and "?" or (self.Key and KeyName(self.Key) or "None") end
	function B:Matches(I)
		local K = self.Key
		if not K then return false end
		if K.EnumType == Enum.KeyCode then return I.KeyCode == K end
		return I.UserInputType == K
	end
	function B:Active()
		if not self.Key and self.Mode ~= "Always" then return false end
		return self.Handler.Get()
	end
	function B:Press()
		if self.Mode == "Toggle" then self.Handler.Set(not self.Handler.Get())
		elseif self.Mode == "Hold" then self.Handler.Set(true) end
	end
	function B:Release()
		if self.Mode == "Hold" then self.Handler.Set(false) end
	end
	function B:SetKey(K)
		self.Key = K
		self:Render()
		if Opts.Changed then task.spawn(Opts.Changed, K) end
		Library:_RefreshKeylist()
	end
	function B:SetMode(M)
		self.Mode = M
		if M == "Always" then self.Handler.Set(true) elseif M == "Hold" then self.Handler.Set(false) end
		Library:_RefreshKeylist()
	end
	Btn.MouseButton1Click:Connect(function() Library._Listening = B; B:Render() end)
	Btn.InputBegan:Connect(function(I)
		if I.UserInputType ~= Enum.UserInputType.MouseButton2 or Library._Listening then return end
		if Library._Popup and Library._Popup.Owner == Btn then Library:ClosePopup() return end
		OptionPopup(Btn, { "Always", "Hold", "Toggle" }, function(O) return B.Mode == O end, function(O) B:SetMode(O) end, false, nil, 80)
	end)
	B:Render()
	table.insert(Library._Keybinds, B)
	Library:_Opt(Flag, {
		Type = "Keybind", Save = Opts.Save,
		Get = function() return B.Key end,
		Set = function(_, K) B:SetKey(K) end,
		Serialize = function() return { Key = B.Key and B.Key.Name or "None", Mode = B.Mode } end,
		Deserialize = function(_, D)
			if type(D) ~= "table" then return end
			B:SetKey(KeyFromName(D.Key))
			if D.Mode then B:SetMode(D.Mode) end
		end,
	}, B.Key)
	B.Button = Btn
	return B
end
local function MakeColor(Parent, Opts, Flag)
	local Obj = { Type = "Colorpicker" }
	local H, S, V = (Opts.Default or Color3.new(1, 1, 1)):ToHSV()
	local HasAlpha = Opts.Alpha ~= nil
	local Alpha = Opts.Alpha or 1
	local Rainbow = false
	local Callback = Opts.Callback or function() end
	local Popup
	local Btn = New("TextButton", { Size = UDim2.fromOffset(14, 14), LayoutOrder = NextOrder(), BackgroundTransparency = 0, Parent = Parent })
	New("UIStroke", { Color = Color3.new(0, 0, 0), Parent = Btn })
	local function Get() return Color3.fromHSV(H, S, V) end
	local function Repaint()
		Btn.BackgroundColor3 = Get()
		if Popup then Popup() end
	end
	local function Changed()
		Repaint()
		Library.Flags[Flag] = Get()
		task.spawn(Callback, Get(), Alpha)
	end
	function Obj:Get() return Get(), Alpha end
	function Obj:Set(C, A)
		if typeof(C) == "Color3" then H, S, V = C:ToHSV() end
		if type(A) == "number" then Alpha = A end
		Changed()
	end
	function Obj:SetRainbow(On) Rainbow = On == true; if Popup then Popup() end end
	function Obj:Serialize() return { Hex = Get():ToHex(), Alpha = Alpha, Rainbow = Rainbow } end
	function Obj:Deserialize(D)
		if type(D) ~= "table" then return end
		Rainbow = D.Rainbow == true
		local Ok, C = pcall(Color3.fromHex, D.Hex or "ffffff")
		self:Set(Ok and C or nil, D.Alpha)
	end
	Library:_Opt(Flag, Obj, Get())
	local RFn
	RFn = function(Hue)
		if not Btn.Parent then
			local I = table.find(Library._Rainbows, RFn)
			if I then table.remove(Library._Rainbows, I) end
			return
		end
		if Rainbow then H = Hue; if S < 0.05 then S = 0.7 end; if V < 0.05 then V = 1 end; Changed() end
	end
	table.insert(Library._Rainbows, RFn)
	local function Open()
		if Library._Popup and Library._Popup.Owner == Btn then Library:ClosePopup() return end
		local PW, PH = 206, HasAlpha and 262 or 242
		local A = Btn.AbsolutePosition - Overlay.AbsolutePosition
		local VP = Overlay.AbsoluteSize
		local X = math.clamp(A.X + 36, 0, VP.X - PW)
		local Y = math.clamp(A.Y, 0, VP.Y - PH)
		local P = New("Frame", { Position = UDim2.fromOffset(X, Y), Size = UDim2.fromOffset(PW, PH), ZIndex = 80, Parent = Overlay })
		Paint(P, "BackgroundColor3", "Section")
		Corner(8, P)
		Stroke(P)
		local SVF = New("TextButton", { Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(160, 160), BackgroundTransparency = 0, ZIndex = 81, Parent = P })
		Corner(5, SVF)
		local Wh = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 82, Parent = SVF })
		Corner(5, Wh)
		New("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = Wh })
		local Bk = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 83, Parent = SVF })
		Corner(5, Bk)
		New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0), Parent = Bk })
		local SVC = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(8, 8), BackgroundTransparency = 1, ZIndex = 84, Parent = SVF })
		Corner(4, SVC)
		New("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 1.5, Parent = SVC })
		local HF = New("TextButton", { Position = UDim2.fromOffset(178, 10), Size = UDim2.fromOffset(16, 160), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0, ZIndex = 81, Parent = P })
		Corner(5, HF)
		local Keys = {}
		for I = 0, 6 do Keys[#Keys + 1] = ColorSequenceKeypoint.new(I / 6, Color3.fromHSV(I / 6, 1, 1)) end
		New("UIGradient", { Rotation = 90, Color = ColorSequence.new(Keys), Parent = HF })
		local HC = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0), Size = UDim2.new(1, 4, 0, 4), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 82, Parent = HF })
		Corner(2, HC)
		local AF, AOv, AC
		local Y0 = 178
		if HasAlpha then
			AF = New("TextButton", { Position = UDim2.fromOffset(10, 178), Size = UDim2.fromOffset(184, 12), BackgroundColor3 = Color3.fromRGB(40, 40, 46), BackgroundTransparency = 0, ZIndex = 81, Parent = P })
			Corner(4, AF)
			AOv = New("Frame", { Size = UDim2.fromScale(1, 1), ZIndex = 82, Parent = AF })
			Corner(4, AOv)
			New("UIGradient", { Transparency = NumberSequence.new(1, 0), Parent = AOv })
			AC = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(4, 16), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 83, Parent = AF })
			Corner(2, AC)
			Y0 = 198
		end
		local HexF = New("Frame", { Position = UDim2.fromOffset(10, Y0), Size = UDim2.fromOffset(100, 26), ZIndex = 81, Parent = P })
		Paint(HexF, "BackgroundColor3", "Element")
		Corner(4, HexF)
		Stroke(HexF)
		local Hex = New("TextBox", { Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -16, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 82, Parent = HexF })
		local RB = New("TextButton", { Position = UDim2.fromOffset(116, Y0), Size = UDim2.fromOffset(78, 26), Text = "rainbow", ZIndex = 81, Parent = P })
		Corner(4, RB)
		Stroke(RB)
		Popup = function()
			local C = Get()
			SVF.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
			SVC.Position = UDim2.fromScale(S, 1 - V)
			HC.Position = UDim2.fromScale(0.5, H)
			if AF then AOv.BackgroundColor3 = C; AC.Position = UDim2.fromScale(Alpha, 0.5) end
			if not Hex:IsFocused() then Hex.Text = "#" .. C:ToHex() end
			RB.BackgroundColor3 = Rainbow and Theme.Accent or Theme.Element
			RB.TextColor3 = Rainbow and Theme.Background or Theme.TextDim
		end
		Popup()
		local function Drag(Which, Frame)
			local function Upd()
				local M = MousePos()
				local P0, Sz = Frame.AbsolutePosition, Frame.AbsoluteSize
				local Fx = math.clamp((M.X - P0.X) / Sz.X, 0, 1)
				local Fy = math.clamp((M.Y - P0.Y) / Sz.Y, 0, 1)
				if Which == "SV" then S, V = Fx, 1 - Fy
				elseif Which == "H" then H = math.min(Fy, 0.999)
				else Alpha = Fx end
				Changed()
			end
			Upd()
			Library._Drag = Upd
		end
		SVF.MouseButton1Down:Connect(function() Drag("SV", SVF) end)
		HF.MouseButton1Down:Connect(function() Drag("H", HF) end)
		if AF then AF.MouseButton1Down:Connect(function() Drag("A", AF) end) end
		Hex.FocusLost:Connect(function()
			local Ok, C = pcall(Color3.fromHex, (Hex.Text:gsub("#", "")))
			if Ok and C then H, S, V = C:ToHSV(); Changed() else Popup() end
		end)
		RB.MouseButton1Click:Connect(function() Rainbow = not Rainbow; Popup() end)
		local SW = { Color3.new(1, 1, 1), Color3.fromRGB(255, 70, 80), Color3.fromRGB(255, 150, 60), Color3.fromRGB(255, 230, 90), Color3.fromRGB(90, 255, 150),
			Color3.fromRGB(80, 220, 255), Color3.fromRGB(90, 120, 255), Color3.fromRGB(190, 100, 255), Color3.fromRGB(255, 110, 210), Color3.fromRGB(20, 20, 24) }
		for I, Col in ipairs(SW) do
			local Sw = New("TextButton", { Position = UDim2.fromOffset(10 + (I - 1) * 18.6, Y0 + 32), Size = UDim2.fromOffset(15, 15), BackgroundColor3 = Col, BackgroundTransparency = 0, ZIndex = 81, Parent = P })
			Corner(2, Sw)
			Stroke(Sw)
			Sw.MouseButton1Click:Connect(function() H, S, V = Col:ToHSV(); Rainbow = false; Changed() end)
		end
		Library:OpenPopup(P, Btn, function() Popup = nil end)
	end
	Btn.MouseButton1Click:Connect(Open)
	Repaint()
	Obj.Button = Btn
	return Obj
end
local Section = {}
Section.__index = Section
local FS, SP = 14, 9
local function TabBar(Parent, Pos, Size)
	local Bar = { Tabs = {} }
	local F = New("Frame", { Position = Pos, Size = Size, BackgroundTransparency = 1, Parent = Parent })
	Bar.Frame = F
	for _, L in ipairs({
		{ UDim2.new(), UDim2.new(1, 0, 0, 1) },
		{ UDim2.new(), UDim2.new(0, 1, 1, 0) },
		{ UDim2.new(1, -1, 0, 0), UDim2.new(0, 1, 1, 0) },
	}) do
		local E = New("Frame", { Position = L[1], Size = L[2], ZIndex = 3, Parent = F })
		Paint(E, "BackgroundColor3", "Stroke")
	end
	function Bar:Layout()
		local N = #self.Tabs
		for I, T in ipairs(self.Tabs) do
			T.B.Position = UDim2.new((I - 1) / N, 0, 0, 0)
			T.B.Size = UDim2.new(1 / N, 0, 1, 0)
			T.Sep.Visible = I < N
		end
	end
	function Bar:Add(Name)
		local B = New("TextButton", { Text = Name, BackgroundTransparency = 1, TextColor3 = Theme.TextDim, Parent = F })
		local Under = New("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 1), ZIndex = 2, Parent = B })
		Paint(Under, "BackgroundColor3", "Stroke")
		local Sep = New("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 7), Size = UDim2.new(0, 1, 1, -14), ZIndex = 2, Parent = B })
		Paint(Sep, "BackgroundColor3", "Stroke")
		local T = { B = B, Under = Under, Sep = Sep }
		self.Tabs[#self.Tabs + 1] = T
		B.MouseEnter:Connect(function() if not T.On then B.TextColor3 = Theme.Text end end)
		B.MouseLeave:Connect(function() if not T.On then B.TextColor3 = Theme.TextDim end end)
		self:Layout()
		return B
	end
	function Bar:Select(B)
		for _, T in ipairs(self.Tabs) do
			T.On = T.B == B
			T.Under.Visible = not T.On
			T.B.TextColor3 = T.On and Theme.Text or Theme.TextDim
		end
	end
	return Bar
end
local function TabBox(Parent, Pos, Size)
	local F = New("Frame", { Position = Pos, Size = Size, BackgroundTransparency = 1, Parent = Parent })
	for _, L in ipairs({
		{ UDim2.new(), UDim2.new(0, 1, 1, 0) },
		{ UDim2.new(1, -1, 0, 0), UDim2.new(0, 1, 1, 0) },
		{ UDim2.new(0, 0, 1, -1), UDim2.new(1, 0, 0, 1) },
	}) do
		local E = New("Frame", { Position = L[1], Size = L[2], ZIndex = 3, Parent = F })
		Paint(E, "BackgroundColor3", "Stroke")
	end
	return F
end
local function MakeSection(Window, Column, Opts)
	local Outer = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = NextOrder(), Parent = Column })
	Stroke(Outer)
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = Outer })
	local Header = New("Frame", { Size = UDim2.new(1, 0, 0, 25), LayoutOrder = 0, Parent = Outer })
	Paint(Header, "BackgroundColor3", "Sidebar")
	local Sh = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = SER.Shadow, Parent = Header })
	New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0.375), Parent = Sh })
	New("Frame", { Position = UDim2.fromOffset(1, 1), Size = UDim2.new(0, 1, 1, -2), BackgroundColor3 = SER.Bright, ZIndex = 2, Parent = Header })
	local Line = New("Frame", { Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 0, 1), ZIndex = 4, Parent = Header })
	Paint(Line, "BackgroundColor3", "Stroke")
	local Title = ShadowText(Header, {
		Position = UDim2.fromOffset(10, 5), Size = UDim2.new(1, -20, 0, FS),
		Text = Opts.Name or "Section", TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3,
	})
	Bind("*", function() Title.TextColor3 = Opts.Risky and Theme.Risky or Theme.Text end, Title)
	Title:SetAttribute("SecTitle", true)
	local Body = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 1, Parent = Outer })
	Body:SetAttribute("SecBody", true)
	Body:SetAttribute("SecName", Opts.Name or "")
	Pad(Body, SP)
	New("UIListLayout", { Padding = UDim.new(0, SP), SortOrder = Enum.SortOrder.LayoutOrder, Parent = Body })
	return setmetatable({ Window = Window, Name = Opts.Name or "Section", Side = Opts.Side, Risky = Opts.Risky, Frame = Outer, Body = Body, Title = Title }, Section)
end
Library.MakeSection = function(Parent, Opts) return MakeSection(Library.Window, Parent, Opts or {}) end
function Section:_Holder(Height)
	return New("Frame", { Size = UDim2.new(1, 0, 0, Height), BackgroundTransparency = 1, LayoutOrder = NextOrder(), Parent = self.Body })
end
function Section:_Register(Name, Holder, Opts)
	if Opts.Dependency then
		local D = Opts.Dependency
		local function Upd() Holder.Visible = (D:Get() and (not D.Holder or D.Holder.Visible)) and true or false end
		if D.OnChange then D:OnChange(Upd) end
		if D.Holder then D.Holder:GetPropertyChangedSignal("Visible"):Connect(Upd) end
		Upd()
	end
end
local function Addons(Holder, Right)
	local A = New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -(Right or 0), 0.5, 0), Size = UDim2.fromOffset(0, 19),
		AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, ZIndex = 2, Parent = Holder,
	})
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = A,
	})
	return A
end
local function TopLabel(Holder, Text)
	local L = New("TextLabel", { Size = UDim2.new(1, 0, 0, FS), Text = Text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = Holder })
	Paint(L, "TextColor3", "Text")
	return L
end
function Section:Custom(Height)
	return self:_Holder(Height)
end
function Section:Toggle(Opts)
	Opts = Opts or {}
	local Name     = Opts.Name or "Toggle"
	local Flag     = Opts.Flag or Name
	local Callback = Opts.Callback or function() end
	local State    = Opts.Default == true
	local Listeners = {}
	local Holder = self:_Holder(FS)
	local Hit = New("TextButton", { Size = UDim2.fromScale(1, 1), Parent = Holder })
	local Box = New("Frame", { Size = UDim2.fromOffset(FS, FS), Parent = Holder })
	Stroke(Box)
	local Inner = New("Frame", { Position = UDim2.fromOffset(2, 2), Size = UDim2.new(1, -4, 1, -4), Parent = Box })
	local Lbl = New("TextLabel", { Position = UDim2.fromOffset(FS + 4, 0), Size = UDim2.new(1, -(FS + 4), 1, 0), Text = Name, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = Holder })
	local Add = Addons(Holder, 0)
	local Hover, Held = false, false
	local function Render()
		Box.BackgroundColor3 = Held and SER.FrameActive or Theme.Element
		Inner.Visible = State or Hover
		Inner.BackgroundColor3 = State and Theme.Accent or Theme.Hover
		local On  = Opts.Risky and Theme.Risky or Theme.Text
		local Off = Opts.Risky and Theme.Risky:Lerp(Theme.Background, 0.35) or Theme.TextDim
		Lbl.TextColor3 = State and On or Off
	end
	Bind("*", function() Render() end, Holder)
	local Obj = { Type = "Toggle", Holder = Holder }
	function Obj:Get() return State end
	function Obj:Set(V)
		V = V == true
		if V == State then return end
		State = V
		Library.Flags[Flag] = V
		Render()
		task.spawn(Callback, V)
		for _, Fn in ipairs(Listeners) do task.spawn(Fn, V) end
		Library:_RefreshKeylist()
	end
	function Obj:OnChange(Fn) table.insert(Listeners, Fn) end
	function Obj:AddKeybind(O)
		O = O or {}
		self.Keybind = MakeKeybind(Add, O, O.Flag or (Flag .. "_Bind"), Name, {
			Get = function() return State end,
			Set = function(V) Obj:Set(V) end,
		})
		return self
	end
	local Colors = 0
	function Obj:AddColorpicker(O)
		O = O or {}
		Colors = Colors + 1
		local C = MakeColor(Add, O, O.Flag or (Flag .. "_Color" .. Colors))
		self.Colorpickers = self.Colorpickers or {}
		table.insert(self.Colorpickers, C)
		return self
	end
	Hit.MouseButton1Down:Connect(function() Held = true; Render() end)
	Hit.MouseButton1Up:Connect(function() Held = false; Render() end)
	Hit.MouseButton1Click:Connect(function() Held = false; Obj:Set(not State) end)
	Hit.MouseEnter:Connect(function() Hover = true; Render() end)
	Hit.MouseLeave:Connect(function() Hover, Held = false, false; Render() end)
	Render()
	Library:_Opt(Flag, Obj, State)
	self:_Register(Name, Holder, Opts)
	return Obj
end
function Section:Slider(Opts)
	Opts = Opts or {}
	local Name   = Opts.Name or "Slider"
	local Flag   = Opts.Flag or Name
	local Min    = Opts.Min or 0
	local Max    = Opts.Max or 100
	local Dec    = Opts.Decimals or Opts.Rounding or 0
	local Suffix = Opts.Suffix or ""
	local Callback = Opts.Callback or function() end
	local Value  = math.clamp(Opts.Default or Min, Min, Max)
	local Holder = self:_Holder(FS * 2 + 4)
	local NameL = New("TextLabel", { Size = UDim2.new(1, -70, 0, FS), Text = Name, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = Holder })
	local ValL = New("TextLabel", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(70, FS), TextXAlignment = Enum.TextXAlignment.Right, Parent = Holder })
	Paint(ValL, "TextColor3", "TextDim")
	local Bar = New("TextButton", { Position = UDim2.fromOffset(0, FS + 4), Size = UDim2.new(1, 0, 0, FS), BackgroundTransparency = 0, Parent = Holder })
	Stroke(Bar)
	local Fill = New("Frame", { Position = UDim2.fromOffset(2, 2), Parent = Bar })
	local ValBox = New("TextBox", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0, TextXAlignment = Enum.TextXAlignment.Left, Visible = false, ZIndex = 3, Parent = Bar })
	Paint(ValBox, "BackgroundColor3", "Element")
	local Dragging, Hover = false, false
	local function Round(V) local M = 10 ^ Dec; return math.floor(V * M + 0.5) / M end
	local function Fmt(V) return (Dec > 0 and string.format("%." .. Dec .. "f", V) or tostring(math.floor(V + 0.5))) .. Suffix end
	local function Render()
		local P = Max == Min and 0 or (Value - Min) / (Max - Min)
		Fill.Size = UDim2.new(P, 6 - 10 * P, 1, -4)
		Fill.BackgroundColor3 = Dragging and SER.AccentActive or Theme.Accent
		Bar.BackgroundColor3 = Dragging and SER.FrameActive or (Hover and Theme.Hover or Theme.Element)
		NameL.TextColor3 = (Hover or Dragging) and Theme.Text or Theme.TextDim
		ValL.Text = Fmt(Value)
	end
	Bind("*", function() Render() end, Holder)
	local Obj = { Type = "Slider", Holder = Holder }
	function Obj:Get() return Value end
	function Obj:Set(V)
		V = math.clamp(Round(tonumber(V) or Min), Min, Max)
		if V == Value then Render() return end
		Value = V
		Library.Flags[Flag] = V
		Render()
		task.spawn(Callback, V)
	end
	Bar.MouseButton1Down:Connect(function()
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
			ValBox.Text = tostring(Value)
			ValBox.Visible = true
			ValBox:CaptureFocus()
			return
		end
		local function Upd()
			local M = MousePos()
			local W = Bar.AbsoluteSize.X - 4
			local P = W > 0 and math.clamp((M.X - Bar.AbsolutePosition.X - 2) / W, 0, 1) or 0
			Obj:Set(Min + (Max - Min) * P)
		end
		Dragging = true
		Upd()
		Render()
		Library._Drag = Upd
		Library._DragEnd = function() Dragging = false; Render() end
	end)
	Bar.MouseEnter:Connect(function() Hover = true; Render() end)
	Bar.MouseLeave:Connect(function() Hover = false; Render() end)
	ValBox.FocusLost:Connect(function()
		ValBox.Visible = false
		local N = tonumber((ValBox.Text:gsub("[^%d%.%-]", "")))
		if N then Obj:Set(N) else Render() end
	end)
	Render()
	Library:_Opt(Flag, Obj, Value)
	self:_Register(Name, Holder, Opts)
	return Obj
end
function Section:Dropdown(Opts)
	Opts = Opts or {}
	local Name    = Opts.Name or "Dropdown"
	local Flag    = Opts.Flag or Name
	local Multi   = Opts.Multi == true
	local Options = Opts.Options or Opts.Values or {}
	local Callback = Opts.Callback or function() end
	local Value = Opts.Default
	if Multi then Value = table.clone(type(Value) == "table" and Value or {})
	elseif Value == nil then Value = Options[1] end
	local HasLabel = Opts.NoLabel ~= true
	local Top = HasLabel and (FS + 4) or 0
	local Holder = self:_Holder(Top + 19)
	if HasLabel then TopLabel(Holder, Name) end
	local Btn = New("TextButton", { Position = UDim2.fromOffset(0, Top), Size = UDim2.new(1, 0, 0, 19), BackgroundTransparency = 0, Parent = Holder })
	Stroke(Btn)
	local ValLbl = New("TextLabel", { Position = UDim2.fromOffset(4, 0), Size = UDim2.new(1, -8, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = Btn })
	Paint(ValLbl, "TextColor3", "Text")
	local Hover = false
	local function Look() Btn.BackgroundColor3 = Hover and Theme.Hover or Theme.Element end
	Bind("*", Look, Btn)
	Btn.MouseEnter:Connect(function() Hover = true; Look() end)
	Btn.MouseLeave:Connect(function() Hover = false; Look() end)
	local function Display()
		if Multi then
			local T = {}
			for _, O in ipairs(Options) do if table.find(Value, O) then table.insert(T, tostring(O)) end end
			ValLbl.Text = #T > 0 and table.concat(T, ", ") or "None"
		else
			ValLbl.Text = Value ~= nil and tostring(Value) or "None"
		end
	end
	local Obj = { Type = "Dropdown", Holder = Holder }
	local function Fire()
		Library.Flags[Flag] = Value
		Display()
		task.spawn(Callback, Value)
	end
	function Obj:Get() return Value end
	function Obj:Set(V)
		if Multi then Value = table.clone(type(V) == "table" and V or {}) else Value = V end
		Fire()
	end
	function Obj:SetOptions(List, Silent)
		Options = List or {}
		if Multi then
			for I = #Value, 1, -1 do if not table.find(Options, Value[I]) then table.remove(Value, I) end end
		elseif not table.find(Options, Value) then
			Value = Options[1]
		end
		if Silent then Library.Flags[Flag] = Value; Display() else Fire() end
	end
	Btn.MouseButton1Click:Connect(function()
		if Library._Popup and Library._Popup.Owner == Btn then Library:ClosePopup() return end
		OptionPopup(Btn, Options, function(O)
			if Multi then return table.find(Value, O) ~= nil end
			return Value == O
		end, function(O)
			if Multi then
				local I = table.find(Value, O)
				if I then table.remove(Value, I) else table.insert(Value, O) end
			else
				Value = O
			end
			Fire()
		end, Multi)
	end)
	Display()
	Library:_Opt(Flag, Obj, Value)
	self:_Register(Name, Holder, Opts)
	return Obj
end
function Section:Textbox(Opts)
	Opts = Opts or {}
	local Name  = Opts.Name
	local Flag  = Opts.Flag or Name or ("Textbox" .. NextOrder())
	local Callback = Opts.Callback or function() end
	local Value = Opts.Default or ""
	local Top = Name and (FS + 4) or 0
	local Holder = self:_Holder(Top + 19)
	if Name then TopLabel(Holder, Name) end
	local Box = New("Frame", { Position = UDim2.fromOffset(0, Top), Size = UDim2.new(1, 0, 0, 19), ClipsDescendants = true, Parent = Holder })
	Paint(Box, "BackgroundColor3", "Element")
	Stroke(Box)
	local TB = New("TextBox", {
		Position = UDim2.fromOffset(4, 0), Size = UDim2.new(1, -8, 1, 0), Text = Value,
		PlaceholderText = Opts.Placeholder or "", TextXAlignment = Enum.TextXAlignment.Left, Parent = Box,
	})
	Bind("*", function() TB.TextColor3 = Theme.Text; TB.PlaceholderColor3 = Theme.TextDim end, TB)
	TB.Focused:Connect(function() Box.BackgroundColor3 = SER.FrameActive end)
	local Obj = { Type = "Textbox", Holder = Holder }
	function Obj:Get() return Value end
	function Obj:Set(V)
		Value = tostring(V or "")
		TB.Text = Value
		Library.Flags[Flag] = Value
		task.spawn(Callback, Value, false)
	end
	TB.FocusLost:Connect(function(Enter)
		Box.BackgroundColor3 = Theme.Element
		Value = TB.Text
		Library.Flags[Flag] = Value
		task.spawn(Callback, Value, Enter)
	end)
	if Opts.Live then
		TB:GetPropertyChangedSignal("Text"):Connect(function()
			Value = TB.Text
			Library.Flags[Flag] = Value
			task.spawn(Callback, Value, false)
		end)
	end
	Obj.Save = Opts.Save
	Library:_Opt(Flag, Obj, Value)
	self:_Register(Name or Opts.Placeholder, Holder, Opts)
	return Obj
end
function Section:Button(Opts)
	Opts = Opts or {}
	local Holder = self:_Holder(FS + 11)
	self:_Register(Opts.Name, Holder, Opts)
	local Row = {}
	local function Layout()
		local N = #Row
		for I, B in ipairs(Row) do
			B.Size = UDim2.new(1 / N, -SP * (N - 1) / N, 1, 0)
			B.Position = UDim2.new((I - 1) / N, (I - 1) * SP / N, 0, 0)
		end
	end
	local function Add(O)
		local Name = O.Name or "Button"
		local B = New("TextButton", { Text = Name, TextTruncate = Enum.TextTruncate.AtEnd, BackgroundTransparency = 0, Parent = Holder })
		Stroke(B)
		local Pending, Over = false, false
		Bind("*", function()
			B.BackgroundColor3 = Theme.Element
			B.TextColor3 = O.Risky and Theme.Risky or Theme.Text
		end, B)
		B.MouseEnter:Connect(function() Over = true; B.BackgroundColor3 = Theme.Hover end)
		B.MouseLeave:Connect(function() Over = false; B.BackgroundColor3 = Theme.Element end)
		B.MouseButton1Down:Connect(function() B.BackgroundColor3 = SER.FrameActive end)
		B.MouseButton1Up:Connect(function() B.BackgroundColor3 = Over and Theme.Hover or Theme.Element end)
		B.MouseButton1Click:Connect(function()
			if O.Confirm and not Pending then
				Pending = true
				B.Text = "are you sure?"
				task.delay(2.5, function() if Pending then Pending = false; B.Text = Name end end)
				return
			end
			Pending = false
			B.Text = Name
			if O.Callback then task.spawn(O.Callback) end
		end)
		table.insert(Row, B)
		Layout()
	end
	Add(Opts)
	local Obj = { Type = "Button", Holder = Holder }
	function Obj:Button(O) Add(O or {}); return self end
	return Obj
end
function Section:Keybind(Opts)
	Opts = Opts or {}
	local Name  = Opts.Name or "Keybind"
	local Flag  = Opts.Flag or Name
	local Callback = Opts.Callback or function() end
	local State = Opts.Mode == "Always"
	local Listeners = {}
	local Holder = self:_Holder(19)
	local Lbl = New("TextLabel", { Size = UDim2.new(1, -80, 1, 0), Text = Name, TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder })
	Paint(Lbl, "TextColor3", "Text")
	local Obj = { Type = "KeybindState", Holder = Holder }
	local B = MakeKeybind(Addons(Holder), Opts, Flag, Name, {
		Get = function() return State end,
		Set = function(V)
			if V == State then return end
			State = V
			task.spawn(Callback, V)
			for _, Fn in ipairs(Listeners) do task.spawn(Fn, V) end
			Library:_RefreshKeylist()
		end,
	})
	function Obj:Get() return State end
	function Obj:GetKey() return B.Key end
	function Obj:SetKey(K) B:SetKey(K) end
	function Obj:SetMode(M) B:SetMode(M) end
	function Obj:OnChange(Fn) table.insert(Listeners, Fn) end
	Obj.Bind = B
	self:_Register(Name, Holder, Opts)
	return Obj
end
function Section:Colorpicker(Opts)
	Opts = Opts or {}
	local Name = Opts.Name or "Color"
	local Holder = self:_Holder(FS)
	local Lbl = New("TextLabel", { Size = UDim2.new(1, -40, 1, 0), Text = Name, TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder })
	Paint(Lbl, "TextColor3", "Text")
	local C = MakeColor(Addons(Holder), Opts, Opts.Flag or Name)
	C.Holder = Holder
	self:_Register(Name, Holder, Opts)
	return C
end
function Section:Label(Opts)
	if type(Opts) == "string" then Opts = { Text = Opts } end
	Opts = Opts or {}
	local Holder = self:_Holder(0)
	Holder.AutomaticSize = Enum.AutomaticSize.Y
	local L = New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true,
		Text = Opts.Text or "", RichText = true, FontFace = Fonts.Regular,
		TextXAlignment = Opts.Centered and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left, Parent = Holder,
	})
	Bind("*", function() L.TextColor3 = Opts.Risky and Theme.Risky or Theme.TextDim end, L)
	if Opts.Dependency then self:_Register(nil, Holder, { Dependency = Opts.Dependency }) end
	local Obj = { Holder = Holder, Label = L }
	function Obj:Set(T) L.Text = T end
	return Obj
end
function Section:Separator()
	local Holder = self:_Holder(1)
	local A = New("Frame", { Size = UDim2.fromScale(1, 1), Parent = Holder })
	Paint(A, "BackgroundColor3", "Stroke")
	return { Holder = Holder }
end
function Section:List(Opts)
	Opts = Opts or {}
	local Name     = Opts.Name or "List"
	local Flag     = Opts.Flag or Name
	local Height   = Opts.Height or 200
	local RowH     = math.min(Opts.RowHeight or 17, 17)
	local Options  = Opts.Options or {}
	local Callback = Opts.Callback or function() end
	local Value    = Opts.Default
	local Holder = self:_Holder(Height)
	local Fill = New("Frame", { Size = UDim2.fromScale(1, 1), ClipsDescendants = true, Parent = Holder })
	Paint(Fill, "BackgroundColor3", "Element")
	Stroke(Fill)
	local SF = New("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
		VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
		ScrollBarThickness = 4, ScrollBarImageColor3 = SER.Scroll, Parent = Fill,
	})
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = SF })
	Pad(SF, 3, 4, 3, 4)
	local Rows = {}
	local Obj = { Type = "List", Holder = Holder, Save = Opts.Save }
	local function Repaint()
		for O, R in pairs(Rows) do R.TextColor3 = (O == Value) and Theme.Text or Theme.TextDim end
	end
	local function Build()
		for _, R in pairs(Rows) do R:Destroy() end
		Rows = {}
		for I, O in ipairs(Options) do
			local R = New("TextButton", {
				Size = UDim2.new(1, 0, 0, RowH), Text = tostring(O), LayoutOrder = I, BackgroundTransparency = 1,
				TextXAlignment = Opts.Centered and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd, Parent = SF,
			})
			R.MouseEnter:Connect(function() R.TextColor3 = Theme.Accent end)
			R.MouseLeave:Connect(Repaint)
			R.MouseButton1Click:Connect(function() Obj:Set(O) end)
			Rows[O] = R
		end
		Repaint()
	end
	function Obj:Get() return Value end
	function Obj:Set(V)
		Value = V
		Library.Flags[Flag] = V
		Repaint()
		task.spawn(Callback, V)
	end
	function Obj:SetOptions(List)
		Options = List or {}
		if Value ~= nil and not table.find(Options, Value) then Value = nil; Library.Flags[Flag] = nil end
		Build()
	end
	Build()
	Library:_Opt(Flag, Obj, Value)
	return Obj
end
function Section:PlayerList(Opts)
	Opts = Opts or {}
	local Query, Map, L = "", {}, nil
	local function Build()
		local Out = {}
		Map = {}
		for _, P in ipairs(Players:GetPlayers()) do
			if P ~= LocalPlayer or Opts.IncludeSelf then
				local D = P.DisplayName .. " (@" .. P.Name .. ")"
				if Query == "" or D:lower():find(Query, 1, true) then
					table.insert(Out, D)
					Map[D] = P
				end
			end
		end
		L:SetOptions(Out)
	end
	self:Textbox({
		Placeholder = "search players..", Live = true, Save = false,
		Flag = (Opts.Flag or "PlayerList") .. "_Search",
		Callback = function(T) Query = T:lower(); if L then Build() end end,
	})
	L = self:List({
		Height = Opts.Height or 200, Save = false, Flag = Opts.Flag or "PlayerList",
		Callback = function(D) if Opts.Callback then Opts.Callback(Map[D]) end end,
	})
	Build()
	Library:Connect(Players.PlayerAdded, Build)
	Library:Connect(Players.PlayerRemoving, function() task.defer(Build) end)
	return { Get = function() return Map[L:Get()] end, Refresh = Build }
end
local Page = {}
Page.__index = Page
local function Column(Parent, Pos, Size)
	local S = New("ScrollingFrame", {
		Position = Pos, Size = Size, BackgroundTransparency = 1,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
		VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
		ScrollBarThickness = 4, ScrollBarImageColor3 = SER.Scroll, Parent = Parent,
	})
	New("UIListLayout", { Padding = UDim.new(0, SP), SortOrder = Enum.SortOrder.LayoutOrder, Parent = S })
	Pad(S, 1, 4, SP, 1)
	return S
end
Library.Column = Column
local function MakePage(Window, Parent, Top)
	local F = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = Parent })
	return setmetatable({
		Window = Window, Frame = F,
		Left = Column(F, UDim2.fromOffset(0, Top), UDim2.new(0.5, -SP / 2, 1, -Top)),
		Right = Column(F, UDim2.new(0.5, SP / 2, 0, Top), UDim2.new(0.5, -SP / 2, 1, -Top)),
	}, Page)
end
function Page:Section(Opts)
	Opts = Opts or {}
	return MakeSection(self.Window, Opts.Side == "Right" and self.Right or self.Left, Opts)
end
local Tab = {}
Tab.__index = Tab
function Tab:Section(Opts)
	if not self.Page then
		self.Page = MakePage(self.Window, self.Container, 0)
		self.Page.Frame.Visible = true
	end
	return self.Page:Section(Opts)
end
function Tab:Canvas()
	local F = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = self.Container })
	self.CanvasFrame = F
	return F
end
function Tab:SelectSub(Sub)
	for _, S in ipairs(self.SubTabs) do
		S.Active = S == Sub
		S.Page.Frame.Visible = S.Active
	end
	self.SubBar:Select(Sub.Button)
	self.ActiveSub = Sub
	Library:ClosePopup()
end
function Tab:SubTab(Opts)
	if type(Opts) == "string" then Opts = { Name = Opts } end
	Opts = Opts or {}
	if not self.SubBar then
		self.SubBar = TabBar(self.Container, UDim2.new(), UDim2.new(1, 0, 0, 26))
	end
	local Sub = { Name = Opts.Name or "SubTab", Tab = self }
	local Btn = self.SubBar:Add(Sub.Name)
	Sub.Button, Sub.Label = Btn, Btn
	Sub.Page = MakePage(self.Window, self.Container, 26 + SP)
	function Sub:Section(O) return self.Page:Section(O) end
	Btn.MouseButton1Click:Connect(function() self:SelectSub(Sub) end)
	table.insert(self.SubTabs, Sub)
	if #self.SubTabs == 1 then self:SelectSub(Sub) end
	return Sub
end
function Library:Sound() end
function Library:Notify() end
function Library:_RefreshKeylist() end
local Window = {}
Window.__index = Window
Library.Shadow = function() end
local function DragBy(Zone, Main)
	Zone.InputBegan:Connect(function(I)
		local Ty = I.UserInputType
		if Ty ~= Enum.UserInputType.MouseButton1 and Ty ~= Enum.UserInputType.Touch then return end
		Library:ClosePopup()
		local Start, Orig = UserInputService:GetMouseLocation(), Main.Position
		Library._Drag = function()
			local D = UserInputService:GetMouseLocation() - Start
			Main.Position = UDim2.new(Orig.X.Scale, Orig.X.Offset + D.X, Orig.Y.Scale, Orig.Y.Offset + D.Y)
		end
	end)
end
local function Grip(Main, MinW, MinH)
	local G = New("TextButton", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1), Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1, ZIndex = 8, Parent = Main })
	G.MouseButton1Down:Connect(function()
		local Start, OS, OP = UserInputService:GetMouseLocation(), Main.AbsoluteSize, Main.Position
		Library._Drag = function()
			local D = UserInputService:GetMouseLocation() - Start
			local NW, NH = math.max(MinW, OS.X + D.X), math.max(MinH, OS.Y + D.Y)
			Main.Size = UDim2.fromOffset(NW, NH)
			Main.Position = OP + UDim2.fromOffset((NW - OS.X) / 2, (NH - OS.Y) / 2)
		end
	end)
end
local function Chrome(Main, Title, MinW, MinH, OnClose)
	Shell(Main)
	local Head = New("Frame", { Size = UDim2.new(1, 0, 0, 33), BackgroundTransparency = 1, ZIndex = 2, Parent = Main })
	Moon(Main, 10, 10, 3)
	local T = ShadowText(Main, { Position = UDim2.fromOffset(33, 10), Size = UDim2.new(1, -260, 0, FS), Text = Title, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3 })
	Paint(T, "TextColor3", "Text")
	local X = New("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 8), Size = UDim2.fromOffset(18, 18), Text = "x", ZIndex = 4, Parent = Main })
	Paint(X, "TextColor3", "TextDim")
	X.MouseEnter:Connect(function() X.TextColor3 = Theme.Text end)
	X.MouseLeave:Connect(function() X.TextColor3 = Theme.TextDim end)
	X.MouseButton1Click:Connect(OnClose)
	DragBy(Head, Main)
	Grip(Main, MinW, MinH)
	local Body = New("Frame", { Position = UDim2.fromOffset(10, 33), Size = UDim2.new(1, -20, 1, -43), BackgroundTransparency = 1, Parent = Main })
	return Head, T, Body
end
local function TabArea(Body)
	local Bar = TabBar(Body, UDim2.new(), UDim2.new(1, 0, 0, FS + SP * 2))
	local Box = TabBox(Body, UDim2.fromOffset(0, FS + SP * 2), UDim2.new(1, 0, 1, -(FS + SP * 2)))
	local Inner = New("Frame", { Position = UDim2.fromOffset(SP, SP), Size = UDim2.new(1, -SP * 2, 1, -SP * 2), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 2, Parent = Box })
	return Bar, Inner
end
function Library:Window(Opts)
	Opts = Opts or {}
	local W, H = Opts.Width or 1000, Opts.Height or 640
	local Win = setmetatable({ Tabs = {}, Library = self, Opts = Opts }, Window)
	self.Window = Win
	local Main = New("Frame", {
		Name = "Main", Size = UDim2.fromOffset(W, H), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Parent = Gui,
	})
	Win.Main = Main
	Win.Scale = New("UIScale", { Parent = Main })
	local _, _, Body = Chrome(Main, Opts.Title or "aceso", 760, 480, function() Library:Toggle() end)
	Win.Body = Body
	Win.HTitle, Win.HSub = New("TextLabel", {}), New("TextLabel", {})
	local Bar, Content = TabArea(Body)
	Win.Bar, Win.Content = Bar, Content
	local SBox = New("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -34, 0, 7), Size = UDim2.fromOffset(190, 19), ZIndex = 3, Parent = Main })
	Paint(SBox, "BackgroundColor3", "Element")
	Stroke(SBox)
	local Input = New("TextBox", { Position = UDim2.fromOffset(4, 0), Size = UDim2.new(1, -8, 1, 0), PlaceholderText = "search  ( / )", TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4, Parent = SBox })
	Bind("*", function() Input.TextColor3 = Theme.Text; Input.PlaceholderColor3 = Theme.TextDim end, Input)
	Library._SearchBox = Input
	do
		local Results
		local function CloseResults()
			if Results then Results:Destroy(); Results = nil end
		end
		local function Esc(S) return (S:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")) end
		local function Index()
			local Out, Seen = {}, {}
			for _, T in ipairs(Win.Tabs) do
				local Pages = {}
				if #T.SubTabs > 0 then
					for _, S in ipairs(T.SubTabs) do Pages[#Pages + 1] = { F = S.Page.Frame, Sub = S } end
				else
					Pages[1] = { F = T.Container }
				end
				for _, Pg in ipairs(Pages) do
					for _, D in ipairs(Pg.F:GetDescendants()) do
						if D:IsA("TextLabel") or D:IsA("TextButton") then
							local Txt = D.Text
							if Txt ~= "" and #Txt <= 42 and not Txt:find("<", 1, true) then
								local Row, Sec = D, nil
								while Row and Row.Parent do
									if Row.Parent:GetAttribute("SecBody") then Sec = Row.Parent; break end
									Row = Row.Parent
								end
								if Sec and not Seen[Row] then
									Seen[Row] = true
									local Title2 = Sec:GetAttribute("SecName") or ""
									Out[#Out + 1] = { Text = Txt, Tab = T, Sub = Pg.Sub, Row = Row, Where = T.Name .. (Pg.Sub and (" > " .. Pg.Sub.Name) or "") .. " > " .. Title2 }
								end
							end
						end
					end
				end
			end
			return Out
		end
		local function Flash(Row)
			local F = New("Frame", { Position = UDim2.fromOffset(-3, -3), Size = UDim2.new(1, 6, 1, 6), BackgroundTransparency = 1, ZIndex = 9, Parent = Row })
			local St = New("UIStroke", { Color = Theme.Accent, Thickness = 1, Parent = F })
			task.spawn(function()
				for _ = 1, 3 do
					St.Enabled = true
					task.wait(0.25)
					St.Enabled = false
					task.wait(0.2)
				end
				F:Destroy()
			end)
		end
		local function Jump(It)
			CloseResults()
			Input.Text = ""
			Input:ReleaseFocus()
			if Win.Active ~= It.Tab then Win:SelectTab(It.Tab) end
			if It.Sub and It.Tab.ActiveSub ~= It.Sub then It.Tab:SelectSub(It.Sub) end
			task.defer(function()
				if not It.Row.Parent then return end
				local Col = It.Row:FindFirstAncestorWhichIsA("ScrollingFrame")
				if Col then
					local Y = It.Row.AbsolutePosition.Y - Col.AbsolutePosition.Y + Col.CanvasPosition.Y - 40
					Col.CanvasPosition = Vector2.new(0, math.max(Y, 0))
				end
				Flash(It.Row)
			end)
		end
		local function Show(Q)
			CloseResults()
			Library._SearchFirst = nil
			Q = Q:lower():match("^%s*(.-)%s*$")
			if Q == "" then return end
			local Hits = {}
			for _, It in ipairs(Index()) do
				local L = It.Text:lower()
				local P = L:find(Q, 1, true)
				if P then Hits[#Hits + 1] = { It = It, Score = (P == 1 and 0 or 1) + #L / 100 } end
			end
			table.sort(Hits, function(A, B) return A.Score < B.Score end)
			local N = math.min(#Hits, 10)
			local RowH = 17
			local A = SBox.AbsolutePosition - Overlay.AbsolutePosition
			local RW = 360
			Results = New("Frame", { Position = UDim2.fromOffset(A.X + SBox.AbsoluteSize.X - RW, A.Y + 21), Size = UDim2.fromOffset(RW, math.max(N, 1) * RowH + 6), ZIndex = 85, Parent = Overlay })
			Paint(Results, "BackgroundColor3", "Section")
			Stroke(Results)
			if N == 0 then
				New("TextLabel", { Position = UDim2.fromOffset(6, 3), Size = UDim2.new(1, -12, 0, RowH), Text = "no results", TextColor3 = Theme.TextDim, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 86, Parent = Results })
				return
			end
			for I = 1, N do
				local It = Hits[I].It
				local B = New("TextButton", {
					Position = UDim2.fromOffset(6, 3 + (I - 1) * RowH), Size = UDim2.new(1, -12, 0, RowH), BackgroundTransparency = 1,
					RichText = true, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
					Text = Esc(It.Text) .. '   <font color="#8e8e8e">' .. Esc(It.Where) .. "</font>", ZIndex = 86, Parent = Results,
				})
				B.TextColor3 = I == 1 and Theme.Accent or Theme.Text
				B.MouseEnter:Connect(function() B.TextColor3 = Theme.Accent end)
				B.MouseLeave:Connect(function() B.TextColor3 = I == 1 and Theme.Accent or Theme.Text end)
				B.MouseButton1Click:Connect(function() Jump(It) end)
			end
			Library._SearchFirst = Hits[1].It
		end
		Input:GetPropertyChangedSignal("Text"):Connect(function() Show(Input.Text) end)
		Input.Focused:Connect(function() SBox.BackgroundColor3 = SER.FrameActive end)
		Input.FocusLost:Connect(function(Enter)
			SBox.BackgroundColor3 = Theme.Element
			if Enter and Library._SearchFirst and Results then Jump(Library._SearchFirst) return end
			task.delay(0.2, function() if not Input:IsFocused() then CloseResults() end end)
		end)
	end
	return Win
end
function Window:SelectTab(T)
	for _, X in ipairs(self.Tabs) do
		X.Active = X == T
		X.Container.Visible = X.Active
	end
	self.Bar:Select(T.Button)
	self.Active = T
	Library:ClosePopup()
end
function Window:Tab(Opts)
	if type(Opts) == "string" then Opts = { Name = Opts } end
	Opts = Opts or {}
	local T = setmetatable({ Name = Opts.Name or "Tab", Desc = Opts.Desc, SubTabs = {}, Window = self, Index = #self.Tabs + 1 }, Tab)
	local Btn = self.Bar:Add(T.Name)
	T.Button, T.Label = Btn, Btn
	T.Container = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = self.Content })
	Btn.MouseButton1Click:Connect(function() self:SelectTab(T) end)
	table.insert(self.Tabs, T)
	if #self.Tabs == 1 then self:SelectTab(T) end
	return T
end
function Window:SetVisible(V)
	Library.Open = V
	local AnyFloat = false
	for _, F in ipairs(Library._Floats) do
		if V then
			if F.Was then F.Main.Visible = true; AnyFloat = true end
		else
			F.Main.Visible = false
		end
	end
	self.Main.Visible = V and not AnyFloat
	if not V then Library:ClosePopup() end
end
function Library:Toggle()
	if self._Loading then return end
	if self.Window then self.Window:SetVisible(not self.Open) end
end
function Library:FloatWindow(Opts)
	Opts = Opts or {}
	local Main = New("Frame", {
		Name = "Float", Size = UDim2.fromOffset(Opts.Width or 1060, Opts.Height or 620), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 30, 0.5, 20), Visible = false, ZIndex = 2, Parent = Gui,
	})
	local F = { Main = Main, Pages = {}, Was = false, Listeners = {} }
	local _, _, Frame0 = Chrome(Main, Opts.Title or "editor", 900, 520, function() F:SetVisible(false) end)
	local Bar, Body = TabArea(Frame0)
	F.Body = Body
	function F:SetVisible(V)
		Main.Visible = V
		self.Was = V
		Library._AnyFloat = V
		Library:ClosePopup()
		if Library.Window then
			if V then
				Library.Open = true
				Library.Window.Main.Visible = false
				Main.Position = Library.Window.Main.Position
			else
				Library.Window.Main.Visible = Library.Open
			end
		end
		for _, Fn in ipairs(self.Listeners) do task.spawn(Fn, V) end
	end
	function F:Toggle() self:SetVisible(not Main.Visible) end
	function F:OnVisible(Fn) self.Listeners[#self.Listeners + 1] = Fn end
	function F:Select(Name)
		for N, P in pairs(self.Pages) do P.Frame.Visible = N == Name end
		Bar:Select(self.Pages[Name].Btn)
		self.Current = Name
		Library:ClosePopup()
		for _, Fn in ipairs(self.Listeners) do task.spawn(Fn, Main.Visible) end
	end
	function F:Page(Name)
		local Btn = Bar:Add(Name)
		local Frame = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = Body })
		self.Pages[Name] = { Frame = Frame, Label = Btn, Under = Btn, Btn = Btn }
		Btn.MouseButton1Click:Connect(function() self:Select(Name) end)
		if not self.Current then self:Select(Name) end
		return Frame
	end
	table.insert(self._Floats, F)
	return F
end
local UnloadHooks = {}
function Library:OnUnload(Fn) UnloadHooks[#UnloadHooks + 1] = Fn end
function Library:Unload()
	for _, Fn in ipairs(self._EarlyUnload) do pcall(Fn) end
	for I = #UnloadHooks, 1, -1 do pcall(UnloadHooks[I]) end
	table.clear(UnloadHooks)
	for _, C in ipairs(self.Connections) do pcall(function() C:Disconnect() end) end
	self.Connections = {}
	Gui:Destroy()
end
function Library:GetConfigs()
	local Out = {}
	local Ok, Files = Try(listfiles, self.ConfigFolder)
	if not Ok or type(Files) ~= "table" then return Out end
	for _, F in ipairs(Files) do
		local N = F:match("([^/\\]+)%.json$")
		if N then table.insert(Out, N) end
	end
	table.sort(Out)
	return Out
end
function Library:SaveConfig(Name)
	if not Name or Name == "" then return false end
	local Data = {}
	for Flag, O in pairs(self.Options) do
		if O.Save ~= false and not tostring(Flag):find("^__") then
			local Ok, V = pcall(O.Serialize, O)
			if Ok then Data[Flag] = V end
		end
	end
	if self.ExtraSave then
		local Ok, V = pcall(self.ExtraSave)
		if Ok then Data.__extra = V end
	end
	return Try(writefile, self.ConfigFolder .. "/" .. Name .. ".json", HttpService:JSONEncode(Data))
end
function Library:LoadConfig(Name)
	local Ok, Raw = Try(readfile, self.ConfigFolder .. "/" .. tostring(Name) .. ".json")
	if not Ok then return false end
	local Ok2, Data = pcall(HttpService.JSONDecode, HttpService, Raw)
	if not Ok2 or type(Data) ~= "table" then return false end
	for Flag, V in pairs(Data) do
		local O = self.Options[Flag]
		if O and O.Save ~= false and not tostring(Flag):find("^__") then pcall(O.Deserialize, O, V) end
	end
	if self.ExtraLoad and Data.__extra then pcall(self.ExtraLoad, Data.__extra) end
	return true
end
function Library:DeleteConfig(Name)
	return Try(delfile, self.ConfigFolder .. "/" .. tostring(Name) .. ".json")
end
local BaseMeshes = (function()
	local DATA = {
		["Double-Barrel SG"] = { Mesh = "rbxassetid://128485616894946", Ext = Vector3.new(0.44, 0.931536, 3.285) },
		["Revolver"]         = { Mesh = "rbxassetid://91726788035430",  Ext = Vector3.new(0.264, 0.996518, 2.04923) },
	}
	return {
		Has = function(Name) return DATA[Name] ~= nil end,
		Get = function(Name) return DATA[Name] end,
	}
end)()
Library:LoaderStep("loading skins, beams and the editor", 0.15)
local Skins = (function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Debris = game:GetService("Debris")
	local lp = LocalPlayer
	local New, Corner, Stroke, Pad, Tween, Paint = Library.New, Library.Corner, Library.Stroke, Library.Pad, Library.Tween, Library.Paint
	local Theme = Library.Theme
	local rgb, v3 = Color3.fromRGB, Vector3.new
	local Conns = {}
	local function On(Sig, Fn) local C = Sig:Connect(Fn); Conns[#Conns + 1] = C; return C end
	local MATERIALS = { "Original", "Neon", "ForceField", "Glass", "SmoothPlastic", "Metal", "DiamondPlate", "Foil", "Plastic", "Marble", "Granite", "Wood", "Ice", "Concrete", "Slate", "CrackedLava" }
	local BASE_MATS = { "SmoothPlastic", "Metal", "Neon", "ForceField", "Glass", "Foil", "DiamondPlate", "Ice", "Marble" }
	local COLOR_MODES = { "Solid", "Gradient", "Pulse", "Rainbow" }
	local FADE_STYLES = { "Fade", "Shrink", "Fade + shrink", "Dissolve", "Flicker" }
	local BEAM_TEXTURES = { "None", "Sparks", "Smoke", "Fire" }
	local PARTICLE_STYLES = { "Sparks", "Glitter", "Embers", "Smoke", "Stars" }
	local AURA_STYLES = { "Orbit", "Comets", "Halo", "Arcs", "Aura", "Galaxy", "Electric", "Flames", "Embers", "Frost", "Void", "Glitter", "Sparks", "Stars", "Bubbles", "Petals", "Snow", "Smoke", "Mist", "Drip" }
	local SKIN_KEYS = {
		Model = 1, MeshId = 1, TextureId = 1, MeshScale = 1, MeshRot = 1, OffX = 1, OffY = 1, OffZ = 1, BaseSkin = 1, BaseTex = 1,
		BaseColor = 1, BaseMat = 1, Tint = 1, TexOnGame = 1, StripDefault = 1,
		OvOn = 1, Material = 1, C1 = 1, C2 = 1, CMode = 1, CSpeed = 1, Reflect = 1, Texture = 1, Strip = 1, Outlines = 1, Details = 1,
		PartOn = 1, PartTrail = 1, PartStyle = 1, PartC1 = 1, PartC2 = 1, PartRate = 1, PartSize = 1, PartSpeed = 1, PartLight = 1, PartRange = 1,
	}
	local TEX = {
		Sparkle = "rbxasset://textures/particles/sparkles_main.dds", Spark = "rbxasset://textures/particles/fire_sparks_main.dds",
		Fire = "rbxasset://textures/particles/fire_main.dds", Smoke = "rbxasset://textures/particles/smoke_main.dds",
		Ring = "rbxasset://textures/particles/explosion01_shockwave_main.dds",
	}
	local LAYER_TYPES = { "Line", "Glow", "Lightning", "Branches", "Helix", "Spiral", "Ribbon", "Wave", "Zigzag", "Noise", "Sketch", "Drawn", "Rings", "Dashes" }
	local SMOOTH = { Helix = true, Wave = true, Noise = true, Drawn = true, Rings = true, Spiral = true, Sketch = true }
	local DRAW_N = 64
	local function Zeros(N) local T = table.create(N, 0); return T end
	local function SineDraw() local T = {}; for I = 1, DRAW_N do T[I] = math.sin((I - 1) / (DRAW_N - 1) * math.pi * 2) end; return T end
	local function NewLayer(Type, O)
		local L = {
			Type = Type or "Line", On = true, A = rgb(120, 220, 255), B = rgb(255, 255, 255), Mode = "Solid", Speed = 1,
			Width = 0.08, WEnd = 0.08, Alpha = 0, Whiten = 0, Emit = 1, Amp = 1, Freq = 1, Spins = true, Spin = 1, Phase = 0, Jitter = 0, Copies = 1,
			Draw = SineDraw(), Draw2 = Zeros(DRAW_N), Sketch = {},
		}
		for K, V in pairs(O or {}) do L[K] = V end
		return L
	end
	local W = rgb(255, 255, 255)
	local PRESETS = {
		Lightning = function() return {
			NewLayer("Lightning", { Width = 0.07, WEnd = 0.05, Whiten = 0.35 }),
			NewLayer("Glow", { Width = 0.3, WEnd = 0.22, Alpha = 0.8 }),
			NewLayer("Lightning", { Width = 0.035, WEnd = 0.02, Alpha = 0.35, Amp = 0.7 }),
		} end,
		Tesla = function() return {
			NewLayer("Lightning", { Width = 0.08, WEnd = 0.05, Whiten = 0.4, A = rgb(170, 140, 255) }),
			NewLayer("Glow", { Width = 0.34, WEnd = 0.24, Alpha = 0.78, A = rgb(150, 110, 255) }),
			NewLayer("Branches", { Width = 0.04, WEnd = 0.01, Alpha = 0.1, A = rgb(200, 180, 255), Freq = 1.2 }),
		} end,
		Plasma = function() return {
			NewLayer("Noise", { Width = 0.09, WEnd = 0.06, A = rgb(255, 90, 220), B = rgb(90, 200, 255), Mode = "Gradient", Copies = 3, Alpha = 0.15, Spin = 1.4 }),
			NewLayer("Line", { Width = 0.04, WEnd = 0.03, Whiten = 0.6, A = rgb(255, 160, 240) }),
			NewLayer("Line", { Width = 0.5, WEnd = 0.35, Alpha = 0.86, A = rgb(220, 110, 255) }),
		} end,
		Helix = function() return {
			NewLayer("Line", { Width = 0.035, Alpha = 0.3 }),
			NewLayer("Helix", { Width = 0.05, WEnd = 0.04, Copies = 2, A = rgb(120, 220, 255), B = rgb(255, 120, 220), Mode = "Gradient" }),
			NewLayer("Line", { Width = 0.28, WEnd = 0.2, Alpha = 0.85 }),
		} end,
		Railgun = function() return {
			NewLayer("Line", { Width = 0.07, WEnd = 0.07, Whiten = 0.55, A = rgb(90, 170, 255) }),
			NewLayer("Glow", { Width = 0.32, WEnd = 0.32, Alpha = 0.78, A = rgb(80, 150, 255) }),
			NewLayer("Helix", { Width = 0.03, WEnd = 0.03, Amp = 1.3, Freq = 0.7, A = rgb(170, 220, 255) }),
			NewLayer("Rings", { Width = 0.03, WEnd = 0.03, Alpha = 0.15, Freq = 0.8, A = rgb(140, 200, 255) }),
		} end,
		Laser = function() return {
			NewLayer("Line", { Width = 0.08, WEnd = 0.08, Whiten = 0.5, A = rgb(255, 50, 60) }),
			NewLayer("Glow", { Width = 0.26, WEnd = 0.26, Alpha = 0.6, A = rgb(255, 40, 50) }),
			NewLayer("Glow", { Width = 0.7, WEnd = 0.7, Alpha = 0.9, A = rgb(255, 30, 40) }),
		} end,
		Pulse = function() return {
			NewLayer("Line", { Width = 0.04, Alpha = 0.6, A = rgb(90, 255, 160) }),
			NewLayer("Dashes", { Width = 0.15, WEnd = 0.15, A = rgb(140, 255, 190), Whiten = 0.3, Freq = 1.2, Spin = 1.3 }),
			NewLayer("Line", { Width = 0.35, WEnd = 0.25, Alpha = 0.9, A = rgb(90, 255, 160) }),
		} end,
		Wave = function() return {
			NewLayer("Wave", { Width = 0.06, WEnd = 0.04, Copies = 2, Mode = "Gradient", A = rgb(255, 200, 80), B = rgb(255, 90, 40) }),
			NewLayer("Line", { Width = 0.03, Whiten = 0.5, A = rgb(255, 220, 120) }),
			NewLayer("Line", { Width = 0.4, WEnd = 0.25, Alpha = 0.88, A = rgb(255, 140, 50) }),
		} end,
		Inferno = function() return {
			NewLayer("Noise", { Width = 0.12, WEnd = 0.04, Copies = 2, A = rgb(255, 200, 60), B = rgb(255, 60, 20), Mode = "Gradient", Spin = 2, Amp = 1.3 }),
			NewLayer("Lightning", { Width = 0.05, WEnd = 0.02, A = rgb(255, 240, 180), Whiten = 0.3, Amp = 0.5 }),
			NewLayer("Line", { Width = 0.6, WEnd = 0.2, Alpha = 0.88, A = rgb(255, 90, 20) }),
		} end,
		Drawn = function() return {
			NewLayer("Drawn", { Width = 0.06, WEnd = 0.05, Copies = 2 }),
			NewLayer("Glow", { Width = 0.24, WEnd = 0.2, Alpha = 0.82 }),
			NewLayer("Line", { Width = 0.03, Alpha = 0.6 }),
		} end,
		Void = function() return {
			NewLayer("Line", { Width = 0.07, WEnd = 0.05, A = rgb(10, 0, 20), Emit = 0 }),
			NewLayer("Glow", { Width = 0.55, WEnd = 0.3, Alpha = 0.8, A = rgb(130, 40, 255) }),
			NewLayer("Noise", { Width = 0.07, WEnd = 0.02, Copies = 3, A = rgb(170, 80, 255), B = rgb(60, 0, 140), Mode = "Gradient", Alpha = 0.15, Spin = 1.5, Amp = 1.2 }),
			NewLayer("Spiral", { Width = 0.025, WEnd = 0.01, Copies = 2, A = rgb(220, 170, 255), Alpha = 0.25, Amp = 1.4, Spin = -1.2 }),
		} end,
		["Ion Cannon"] = function() return {
			NewLayer("Line", { Width = 0.13, WEnd = 0.11, Whiten = 0.75, A = rgb(110, 200, 255) }),
			NewLayer("Glow", { Width = 0.5, WEnd = 0.42, Alpha = 0.76, A = rgb(60, 150, 255) }),
			NewLayer("Ribbon", { Width = 0.38, WEnd = 0.2, Alpha = 0.55, A = rgb(140, 220, 255), Freq = 0.6, Spin = 1.6 }),
			NewLayer("Rings", { Width = 0.035, WEnd = 0.035, Alpha = 0.1, Freq = 1.2, A = rgb(180, 235, 255), Amp = 1.1 }),
		} end,
		DNA = function() return {
			NewLayer("Helix", { Width = 0.06, WEnd = 0.05, Copies = 2, A = rgb(90, 255, 200), B = rgb(90, 140, 255), Mode = "Gradient", Amp = 1.1, Freq = 0.8 }),
			NewLayer("Glow", { Width = 0.2, WEnd = 0.16, Alpha = 0.85, A = rgb(90, 220, 220) }),
			NewLayer("Line", { Width = 0.025, Alpha = 0.45, Whiten = 0.6, A = rgb(200, 255, 240) }),
			NewLayer("Line", { Width = 0.35, WEnd = 0.25, Alpha = 0.9, A = rgb(90, 220, 220) }),
		} end,
		Phantom = function() return {
			NewLayer("Ribbon", { Width = 0.42, WEnd = 0.08, A = rgb(230, 240, 255), Alpha = 0.5, Freq = 0.4, Spin = 0.8 }),
			NewLayer("Noise", { Width = 0.05, WEnd = 0.02, Copies = 2, Alpha = 0.3, A = rgb(200, 220, 255), Amp = 0.6 }),
			NewLayer("Line", { Width = 0.03, Whiten = 0.85, A = rgb(220, 230, 255) }),
		} end,
		Solar = function() return {
			NewLayer("Line", { Width = 0.1, WEnd = 0.05, Whiten = 0.65, A = rgb(255, 190, 60) }),
			NewLayer("Glow", { Width = 0.48, WEnd = 0.26, Alpha = 0.78, A = rgb(255, 120, 30) }),
			NewLayer("Spiral", { Width = 0.05, WEnd = 0.02, Copies = 3, A = rgb(255, 140, 30), B = rgb(255, 230, 120), Mode = "Gradient", Amp = 1.2, Spin = 2 }),
		} end,
		Frostbite = function() return {
			NewLayer("Lightning", { Width = 0.065, WEnd = 0.04, A = rgb(170, 240, 255), Whiten = 0.45 }),
			NewLayer("Glow", { Width = 0.3, WEnd = 0.22, Alpha = 0.78, A = rgb(120, 210, 255) }),
			NewLayer("Zigzag", { Width = 0.03, WEnd = 0.02, Alpha = 0.25, A = rgb(220, 250, 255), Amp = 0.8, Freq = 1.5, Spins = false }),
		} end,
		Crimson = function() return {
			NewLayer("Ribbon", { Width = 0.26, WEnd = 0.08, A = rgb(255, 40, 60), B = rgb(140, 0, 30), Mode = "Gradient", Alpha = 0.2, Freq = 0.8, Spin = 2 }),
			NewLayer("Lightning", { Width = 0.04, WEnd = 0.02, A = rgb(255, 160, 160), Whiten = 0.35, Amp = 0.6 }),
			NewLayer("Glow", { Width = 0.42, WEnd = 0.25, Alpha = 0.84, A = rgb(255, 30, 50) }),
		} end,
		Supernova = function() return {
			NewLayer("Line", { Width = 0.11, WEnd = 0.07, Whiten = 0.8, A = rgb(255, 230, 160) }),
			NewLayer("Glow", { Width = 0.6, WEnd = 0.35, Alpha = 0.8, A = rgb(255, 140, 40) }),
			NewLayer("Spiral", { Width = 0.045, WEnd = 0.02, Copies = 3, A = rgb(255, 200, 80), B = rgb(255, 255, 220), Mode = "Gradient", Amp = 1.5, Spin = 2.2 }),
			NewLayer("Rings", { Width = 0.035, WEnd = 0.02, Alpha = 0.2, Amp = 1.4, Freq = 1.5, A = rgb(255, 230, 180) }),
		} end,
		Dragon = function() return {
			NewLayer("Ribbon", { Width = 0.45, WEnd = 0.12, A = rgb(255, 50, 30), B = rgb(255, 170, 40), Mode = "Gradient", Alpha = 0.25, Freq = 0.5, Spin = 2.5 }),
			NewLayer("Noise", { Width = 0.06, WEnd = 0.02, Copies = 2, A = rgb(255, 140, 40), Amp = 1.4, Spin = 1.8 }),
			NewLayer("Line", { Width = 0.05, Whiten = 0.7, A = rgb(255, 200, 120) }),
			NewLayer("Glow", { Width = 0.4, WEnd = 0.25, Alpha = 0.84, A = rgb(255, 70, 30) }),
		} end,
		Starlight = function() return {
			NewLayer("Line", { Width = 0.05, WEnd = 0.04, Whiten = 0.9, A = rgb(220, 240, 255) }),
			NewLayer("Glow", { Width = 0.3, WEnd = 0.24, Alpha = 0.82, A = rgb(140, 200, 255) }),
			NewLayer("Helix", { Width = 0.03, WEnd = 0.02, Copies = 4, Amp = 0.8, Freq = 1.3, A = rgb(180, 220, 255), B = rgb(255, 255, 255), Mode = "Gradient", Spin = 1.6 }),
			NewLayer("Dashes", { Width = 0.09, WEnd = 0.09, Whiten = 0.8, A = rgb(200, 230, 255), Freq = 2, Spin = 2 }),
		} end,
		Hyperion = function() return {
			NewLayer("Helix", { Width = 0.06, WEnd = 0.04, Copies = 2, A = rgb(170, 90, 255), B = rgb(80, 220, 255), Mode = "Gradient", Amp = 1.2, Freq = 0.9, Spin = 1.5 }),
			NewLayer("Lightning", { Width = 0.03, WEnd = 0.015, Whiten = 0.6, A = rgb(220, 200, 255), Amp = 0.5 }),
			NewLayer("Glow", { Width = 0.45, WEnd = 0.3, Alpha = 0.85, A = rgb(130, 80, 255) }),
			NewLayer("Rings", { Width = 0.03, WEnd = 0.02, Alpha = 0.25, Freq = 0.9, A = rgb(150, 220, 255) }),
		} end,
		Toxic = function() return {
			NewLayer("Noise", { Width = 0.08, WEnd = 0.03, Copies = 3, A = rgb(120, 255, 60), B = rgb(20, 120, 20), Mode = "Gradient", Amp = 1.1, Spin = 1.4 }),
			NewLayer("Zigzag", { Width = 0.03, WEnd = 0.02, A = rgb(200, 255, 140), Amp = 0.6, Freq = 1.8 }),
			NewLayer("Line", { Width = 0.04, Whiten = 0.5, A = rgb(160, 255, 90) }),
			NewLayer("Glow", { Width = 0.42, WEnd = 0.26, Alpha = 0.84, A = rgb(90, 255, 50) }),
		} end,
		Prism = function() return {
			NewLayer("Helix", { Width = 0.045, WEnd = 0.035, Copies = 3, Mode = "Rainbow", Speed = 1.5, Amp = 0.9 }),
			NewLayer("Line", { Width = 0.04, WEnd = 0.04, Whiten = 0.9, A = W }),
			NewLayer("Glow", { Width = 0.36, WEnd = 0.3, Alpha = 0.86, Mode = "Rainbow" }),
		} end,
	}
	local PRESET_NAMES = { "Lightning", "Tesla", "Plasma", "Helix", "Railgun", "Laser", "Pulse", "Wave", "Inferno", "Drawn",
		"Void", "Ion Cannon", "DNA", "Phantom", "Solar", "Frostbite", "Crimson", "Prism", "Supernova", "Dragon", "Starlight", "Hyperion", "Toxic" }
	local UserPresets = {}
	local function Defaults()
		return {
			Model = "Default", MeshId = "", TextureId = "", MeshScale = 1, MeshRot = 0, OffX = 0, OffY = 0, OffZ = 0,
			BaseSkin = "Plain", BaseTex = "", BaseColor = rgb(180, 180, 186), BaseMat = "SmoothPlastic", Tint = W, TexOnGame = true, StripDefault = false,
			OvOn = false, Material = "Original", C1 = rgb(255, 132, 64), C2 = rgb(120, 90, 255), CMode = "Solid", CSpeed = 1,
			Reflect = 0, Texture = "", Strip = true, Outlines = true, Details = false,
			PartOn = false, PartTrail = false, PartStyle = "Orbit", PartC1 = rgb(255, 132, 64), PartC2 = W, PartRate = 16, PartSize = 0.4, PartSpeed = 1, PartLight = false, PartRange = 6,
			Beam = false, Preset = "Ion Cannon", Layers = PRESETS["Ion Cannon"](), B1 = rgb(120, 220, 255), B2 = W,
			Thick = 1, Animate = true, Bright = 2, Tex = "None", TexSpeed = 2,
			FadeStyle = "Fade", DrawIn = 0.03, Life = 0.06, Fade = 0.35, Tail = 0,
			Lights = false, LBright = 1.4, LRange = 12, Flare = false, Core = true,
			Particles = true, PStyle = "Sparks", PInt = 4, Impact = false, Ring = false, Muzzle = true, HideGame = true,
		}
	end
	local Cfg = {}
	local function Get(Wp)
		if not Cfg[Wp] then Cfg[Wp] = Defaults() end
		return Cfg[Wp]
	end
	local KNIFE_WORDS = { "knife", "karambit", "dagger", "blade", "machete", "cleaver", "sword" }
	local function CategoryFor(Weapon)
		local Lower = Weapon:lower()
		for _, Word in ipairs(KNIFE_WORDS) do
			if Lower:find(Word, 1, true) then return "Knife" end
		end
		return "Gun"
	end
	local function Squash(N) return (N:lower():gsub("[^%w]", "")) end
	local CANON = {
		doublebarrel = "Double-Barrel SG", doublebarrelsg = "Double-Barrel SG", db = "Double-Barrel SG",
		revolver = "Revolver", rev = "Revolver", tacticalshotgun = "TacticalShotgun", shotgun = "Shotgun",
		smg = "SMG", silencer = "Silencer", silencerar = "SilencerAR", ak47 = "AK47", ar = "AR", aug = "AUG",
		rifle = "Rifle", lmg = "LMG", p90 = "P90", glock = "Glock", drumgun = "DrumGun", drumshotgun = "Drum-Shotgun",
		flamethrower = "Flamethrower", rpg = "RPG", grenadelauncher = "GrenadeLauncher", taser = "Taser",
		smgsilencer = "Silencer", uzi = "Uzi", mp5 = "MP5", deagle = "Deagle", pistol = "Pistol",
	}
	local BLOCK = { "flintlock", "food", "burger", "pizza", "chicken", "taco", "donut", "drink", "cola", "soda", "lettuce", "popcorn",
		"cranberry", "hotdog", "meat", "starblox", "water", "phone", "mask", "bat", "shovel", "pitchfork", "pencil", "sign", "boombox",
		"lockpick", "wallet", "money", "flashlight", "spray", "camera", "flower", "rose", "basketball", "weight", "punch", "combat" }
	local function Canon(N)
		if not N then return nil end
		return CANON[Squash(N)] or N
	end
	local function Blocked(N)
		local L = N:lower()
		for _, Wd in ipairs(BLOCK) do if L:find(Wd, 1, true) then return true end end
		return false
	end
	local function KeyFor(Weapon) return CategoryFor(Weapon) == "Knife" and "Knife" or Canon(Weapon) end
	local Handles = { DB_HANDLE = "Double-Barrel SG", REV_HANDLE = "Revolver" }
	local function Names(Weapon)
		local Out, Seen = {}, {}
		local K = Squash(Weapon)
		local function Add(N) if not Seen[N] then Seen[N] = true; Out[#Out + 1] = N end end
		Add(Weapon)
		for Raw, Name in pairs(CANON) do if Name == Weapon or Raw == K then Add(Name); Add(Raw) end end
		if Weapon == "Double-Barrel SG" then Add("DoubleBarrel"); Add("Double-Barrel"); Add("DoubleBarrelSG") end
		return Out
	end
	local function Wraps() return ReplicatedStorage:FindFirstChild("Wraps") end
	local FALLBACK_GUNS = { "Double-Barrel SG", "Revolver", "TacticalShotgun", "SMG", "Shotgun", "Silencer" }
	local function WrapFolder(Weapon)
		local Wr = Wraps()
		if not Wr then return nil end
		for _, N in ipairs(Names(Weapon)) do
			local F = Wr:FindFirstChild("[" .. N .. "]")
			if F then return F end
		end
		local K = Squash(Weapon)
		for _, F in ipairs(Wr:GetChildren()) do
			local N = F.Name:match("^%[(.+)%]$")
			if N and (Canon(N) == Weapon or Squash(N) == K) then return F end
		end
		return nil
	end
	local function HasAmmo(T)
		for _, D in ipairs(T:GetDescendants()) do
			if (D:IsA("IntValue") or D:IsA("NumberValue")) and D.Name:lower():find("ammo", 1, true) then return true end
		end
		return false
	end
	local KNOWN = {}
	for _, N in pairs(CANON) do KNOWN[N] = true end
	local SkinIndex, Indexing = {}, false
	local function BuildIndex()
		if Indexing then return end
		Indexing = true
		local Index = {}
		local Roots = { ReplicatedStorage }
		pcall(function() Roots[#Roots + 1] = game:GetService("ReplicatedFirst") end)
		local Seen = 0
		for _, Root in ipairs(Roots) do
			local List = Root:GetDescendants()
			for I, D in ipairs(List) do
				if (D:IsA("Folder") or D:IsA("Model")) and D.Parent then
					local Raw = D.Name:match("^%[(.+)%]$") or D.Name
					local Wp = CategoryFor(Raw) == "Knife" and "Knife" or Canon(Raw)
					if KNOWN[Wp] or Wp == "Knife" then
						local P = D.Parent.Name:lower()
						if P:find("skin", 1, true) or P:find("wrap", 1, true) or P:find("cosmetic", 1, true) or P == "knives" or P:find("customi", 1, true) then
							local T = Index[Wp] or {}
							Index[Wp] = T
							for _, C in ipairs(D:GetChildren()) do
								if (C:IsA("Model") or C:IsA("BasePart") or C:IsA("Folder")) and not T[C.Name] then T[C.Name] = C; Seen = Seen + 1 end
							end
						end
					end
				end
				if I % 3000 == 0 then task.wait() end
			end
		end
		local K = ReplicatedStorage:FindFirstChild("Knives")
		if K then
			Index.Knife = Index.Knife or {}
			for _, C in ipairs(K:GetChildren()) do Index.Knife[C.Name] = Index.Knife[C.Name] or C end
		end
		SkinIndex = Index
		Indexing = false
		return Seen
	end
	task.spawn(BuildIndex)
	local function ScanWeapons()
		local Out, Seen = {}, {}
		local function Add(N, Sure)
			N = Canon(N)
			if not N or Seen[N] or Blocked(N) or CategoryFor(N) ~= "Gun" then return end
			if not (Sure or KNOWN[N]) then return end
			Seen[N] = true
			Out[#Out + 1] = N
		end
		local Wr = Wraps()
		if Wr then for _, F in ipairs(Wr:GetChildren()) do Add(F.Name:match("^%[(.+)%]$"), false) end end
		for Wp in pairs(SkinIndex) do if Wp ~= "Knife" then Add(Wp, false) end end
		for _, Box in ipairs({ lp:FindFirstChildOfClass("Backpack") or false, lp.Character or false }) do
			if Box then
				for _, T in ipairs(Box:GetChildren()) do
					if T:IsA("Tool") then
						local N = T.Name:match("^%[(.+)%]$")
						if N then Add(N, HasAmmo(T)) end
					end
				end
			end
		end
		Add("Revolver", true)
		Add("Double-Barrel SG", true)
		if #Out <= 2 then for _, N in ipairs(FALLBACK_GUNS) do Add(N, true) end end
		table.sort(Out)
		Out[#Out + 1] = "Knife"
		return Out
	end
	local FIXED = { Default = 1, ["Game skin"] = 1, ["Base model"] = 1, ["Custom mesh"] = 1 }
	local function ModelsFor(Weapon)
		local Out, Seen = {}, {}
		local function Add(N) if N and not FIXED[N] and not Seen[N] then Seen[N] = true; Out[#Out + 1] = N end end
		local Wr = Wraps()
		if Weapon == "Knife" then
			local K = ReplicatedStorage:FindFirstChild("Knives")
			if K then for _, C in ipairs(K:GetChildren()) do Add(C.Name) end end
			for _, FN in ipairs({ "[Knife]", "[Knives]" }) do
				local F = Wr and Wr:FindFirstChild(FN)
				if F then for _, C in ipairs(F:GetChildren()) do Add(C.Name) end end
			end
		else
			local F = WrapFolder(Weapon)
			if F then for _, C in ipairs(F:GetChildren()) do Add(C.Name) end end
		end
		for N in pairs(SkinIndex[Weapon] or {}) do Add(N) end
		table.sort(Out)
		local Head = { "Default", "Game skin" }
		if BaseMeshes.Has(Weapon) then Head[#Head + 1] = "Base model" end
		for I = #Head, 1, -1 do table.insert(Out, 1, Head[I]) end
		Out[#Out + 1] = "Custom mesh"
		return Out
	end
	local function FindModel(Weapon, Pick)
		if FIXED[Pick] or Pick == "Original" then return nil end
		local Idx = SkinIndex[Weapon]
		if Idx and Idx[Pick] and Idx[Pick].Parent then return Idx[Pick] end
		local Wr = Wraps()
		if Weapon == "Knife" then
			local K = ReplicatedStorage:FindFirstChild("Knives")
			local M = K and K:FindFirstChild(Pick)
			if M then return M end
			for _, FN in ipairs({ "[Knife]", "[Knives]" }) do
				local F = Wr and Wr:FindFirstChild(FN)
				M = F and F:FindFirstChild(Pick)
				if M then return M end
			end
			return nil
		end
		local F = WrapFolder(Weapon)
		return F and F:FindFirstChild(Pick)
	end
	local Originals = {}
	local Touched = setmetatable({}, { __mode = "k" })
	local function RememberTool(T)
		if not (typeof(T) == "Instance" and T:IsA("Tool")) or Touched[T] then return false end
		local Wn = T.Name:match("^%[(.+)%]$")
		if not Wn then return false end
		local Key = KeyFor(Wn)
		if Originals[Key] or T:FindFirstChild("SkinModel") or T:FindFirstChild("AcesoMesh") then return false end
		local Ok, C = pcall(function() return T:Clone() end)
		if not Ok or not C then return false end
		for _, D in ipairs(C:GetDescendants()) do
			if D:IsA("LuaSourceContainer") or D:IsA("Sound") then D:Destroy() end
		end
		Originals[Key] = C
		return true
	end
	local function RememberMine()
		local Found = false
		for _, Box in ipairs({ lp:FindFirstChildOfClass("Backpack") or false, lp.Character or false }) do
			if Box then
				for _, T in ipairs(Box:GetChildren()) do
					if RememberTool(T) then Found = true end
				end
			end
		end
		return Found
	end
	local function BaseStandIn(Weapon)
		local D = BaseMeshes.Get(Weapon)
		if not D then return nil end
		local M = Instance.new("Model")
		local H = Instance.new("Part")
		H.Name, H.Size, H.Transparency = "Handle", D.Ext, 1
		H.Parent = M
		local Def = Instance.new("Part")
		Def.Name, Def.Size = "Default", D.Ext
		local Sm = Instance.new("SpecialMesh")
		Sm.MeshType, Sm.MeshId = Enum.MeshType.FileMesh, D.Mesh
		Sm.Parent = Def
		Def.Color, Def.Material = rgb(160, 160, 166), Enum.Material.SmoothPlastic
		Def.CFrame = CFrame.Angles(0, math.pi, 0)
		Def.Parent = M
		return M
	end
	local WorldGuns, Scanning, ShopGuns, ScanDone = {}, false, {}, false
	local function ScanWorldGuns()
		if Scanning then return end
		Scanning = true
		local Found = {}
		local Chars = {}
		for _, P in ipairs(Players:GetPlayers()) do if P.Character then Chars[P.Character] = true end end
		for I, D in ipairs(workspace:GetDescendants()) do
			if (D:IsA("Model") or D:IsA("Tool")) then
				local N = D.Name:match("^%[(.-)%]")
				if N then
					local Wp = CategoryFor(N) == "Knife" and "Knife" or Canon(N)
					if (KNOWN[Wp] or Wp == "Knife") and not Found[Wp] then
						local Owner = D:FindFirstAncestorOfClass("Model")
						local OnChar = Owner and Chars[Owner]
						if not OnChar and D:FindFirstChildWhichIsA("BasePart", true) then Found[Wp] = D end
					end
				end
			end
			if I % 4000 == 0 then task.wait() end
		end
		for K2, V in pairs(Found) do WorldGuns[K2] = V end
		ShopGuns = Found
		Scanning = false
		ScanDone = true
	end
	task.spawn(ScanWorldGuns)
	local function RememberOther(T)
		if not T:IsA("Tool") then return end
		local N = T.Name:match("^%[(.+)%]$")
		if not N then return end
		local Key = KeyFor(N)
		if Originals[Key] or WorldGuns[Key] then return end
		local Ok, C = pcall(function() return T:Clone() end)
		if Ok and C then
			for _, D in ipairs(C:GetDescendants()) do if D:IsA("LuaSourceContainer") or D:IsA("Sound") then D:Destroy() end end
			WorldGuns[Key] = C
		end
	end
	local function WatchOthers(P)
		if P == lp then return end
		local function Char(C)
			for _, T in ipairs(C:GetChildren()) do pcall(RememberOther, T) end
			On(C.ChildAdded, function(T) pcall(RememberOther, T) end)
		end
		if P.Character then Char(P.Character) end
		On(P.CharacterAdded, Char)
	end
	for _, P in ipairs(Players:GetPlayers()) do WatchOthers(P) end
	On(Players.PlayerAdded, WatchOthers)
	local function SourceFor(Weapon)
		if not Originals[Weapon] then RememberMine() end
		if Originals[Weapon] then return Originals[Weapon], false end
		if WorldGuns[Weapon] and (WorldGuns[Weapon].Parent or not WorldGuns[Weapon]:IsDescendantOf(workspace)) then return WorldGuns[Weapon], false end
		if Weapon ~= "Knife" then
			local Name = "[" .. Weapon .. "]"
			for _, Root in ipairs({ ReplicatedStorage, game:GetService("StarterPack") }) do
				local T = Root:FindFirstChild(Name, true)
				if T and T:IsA("Tool") then return T, false end
			end
			for _, P in ipairs(Players:GetPlayers()) do
				local T = P ~= lp and P.Character and P.Character:FindFirstChild(Name)
				if T and T:IsA("Tool") then return T, false end
			end
			local S = BaseStandIn(Weapon)
			if S then return S, false end
		end
		for _, N in ipairs(ModelsFor(Weapon)) do
			if not FIXED[N] then
				local M = FindModel(Weapon, N)
				if M then return M, true end
			end
		end
		return nil, false
	end
	local Saved = setmetatable({}, { __mode = "k" })
	local Live = setmetatable({}, { __mode = "k" })
	local function IsBasePart(X) return typeof(X) == "Instance" and X:IsA("BasePart") end
	local function Rec(Holder)
		local R = Saved[Holder]
		if not R then R = { Parts = {}, SA = {}, Mesh = {}, Decal = {}, Watch = {}, Added = {} }; Saved[Holder] = R end
		return R
	end
	local function SavePart(R, P)
		if R.Parts[P] then return end
		R.Parts[P] = { M = P.Material, C = P.Color, Rf = P.Reflectance, T = P.Transparency, Tex = P:IsA("MeshPart") and P.TextureID or nil }
	end
	local function ParkSA(R, P)
		for _, Ch in ipairs(P:GetChildren()) do
			if Ch:IsA("SurfaceAppearance") then R.SA[Ch] = P; Ch.Parent = nil end
		end
	end
	local OURS = { SkinModel = true, AcesoMesh = true, AcesoAura = true, AcesoSkin = true }
	local function Clear(Holder)
		for N in pairs(OURS) do
			local Old = Holder:FindFirstChild(N)
			while Old do Old:Destroy(); Old = Holder:FindFirstChild(N) end
		end
		local R = Saved[Holder]
		if R then
			for _, C in ipairs(R.Watch) do C:Disconnect() end
			for _, A in ipairs(R.Added or {}) do pcall(function() A:Destroy() end) end
			for P, V in pairs(R.LTM or {}) do pcall(function() if P.Parent then P.LocalTransparencyModifier = V end end) end
			for P, S in pairs(R.Parts) do
				if P.Parent then
					pcall(function()
						P.Material, P.Color, P.Reflectance, P.Transparency = S.M, S.C, S.Rf, S.T
						if S.Tex ~= nil then P.TextureID = S.Tex end
					end)
				end
			end
			for SA, Parent in pairs(R.SA) do pcall(function() if Parent.Parent then SA.Parent = Parent end end) end
			for M, S in pairs(R.Mesh) do pcall(function() if M.Parent then M.TextureId, M.VertexColor = S[1], S[2] end end) end
			for D, S in pairs(R.Decal) do pcall(function() if D.Parent then D.Transparency, D.Color3 = S[1], S[2] end end) end
		end
		Saved[Holder] = nil
		Live[Holder] = nil
	end
	local function Prep(Model)
		for _, P in ipairs(Model:GetDescendants()) do
			if P:IsA("BasePart") then
				P.CanCollide, P.Anchored, P.Massless = false, false, true
				P.CanQuery, P.CanTouch = false, false
			elseif P:IsA("LuaSourceContainer") or P:IsA("Sound") then
				P:Destroy()
			end
		end
	end
	local function HideRest(Holder, Keep)
		local R = Rec(Holder)
		for _, P in ipairs(Holder:GetDescendants()) do
			if P:IsA("BasePart") and not P:IsDescendantOf(Keep) and P ~= Keep then
				SavePart(R, P)
				P.Transparency = 1
			end
		end
	end
	local function WeldTo(Handle, P)
		local Wl = Instance.new("WeldConstraint")
		Wl.Part0, Wl.Part1 = Handle, P
		Wl.Parent = P
	end
	local function WeldAll(Handle, Model)
		for _, P in ipairs(Model:GetDescendants()) do
			if P:IsA("BasePart") then WeldTo(Handle, P) end
		end
	end
	local BASE_SKINS = {
		Plain = "", Galaxy = { Revolver = 9370936730, ["Double-Barrel SG"] = 9401441647 },
		Inferno = { Revolver = 9370404463, ["Double-Barrel SG"] = 9401416743 },
		Matrix = { Revolver = 9380928144, ["Double-Barrel SG"] = 9401457713 },
		RedDeath = { Revolver = 8173928665, ["Double-Barrel SG"] = 8212384179 },
		GoldGlory = { Revolver = 8173955378, ["Double-Barrel SG"] = 8212394280 },
	}
	local BASE_SKIN_NAMES = { "Plain", "Galaxy", "Inferno", "Matrix", "RedDeath", "GoldGlory", "Custom" }
	local function Asset(Id)
		Id = tostring(Id or "")
		if Id == "" then return "" end
		return Id:match("^%d+$") and ("rbxassetid://" .. Id) or Id
	end
	local function BaseTexture(Weapon, C)
		if C.BaseSkin == "Custom" then return Asset(C.BaseTex) end
		local T = BASE_SKINS[C.BaseSkin]
		return type(T) == "table" and Asset(T[Weapon]) or ""
	end
	local function VisibleBox(Holder, Handle)
		local Lo, Hi
		for _, P in ipairs(Holder:GetDescendants()) do
			if P:IsA("BasePart") and P.Transparency < 1 and not OURS[P.Name] then
				local CF, H = Handle.CFrame:ToObjectSpace(P.CFrame), P.Size / 2
				for _, X in ipairs({ -1, 1 }) do for _, Y in ipairs({ -1, 1 }) do for _, Z in ipairs({ -1, 1 }) do
					local Pt = CF:PointToWorldSpace(v3(H.X * X, H.Y * Y, H.Z * Z))
					Lo = Lo and v3(math.min(Lo.X, Pt.X), math.min(Lo.Y, Pt.Y), math.min(Lo.Z, Pt.Z)) or Pt
					Hi = Hi and v3(math.max(Hi.X, Pt.X), math.max(Hi.Y, Pt.Y), math.max(Hi.Z, Pt.Z)) or Pt
				end end end
			end
		end
		if not Lo then return v3(), Handle.Size end
		return (Lo + Hi) / 2, Hi - Lo
	end
	local function AxisMap(E, T)
		local function Rank(V)
			local R = { { 1, V.X }, { 2, V.Y }, { 3, V.Z } }
			table.sort(R, function(A, B) return A[2] > B[2] end)
			return { R[1][1], R[2][1], R[3][1] }
		end
		local AX = { v3(1, 0, 0), v3(0, 1, 0), v3(0, 0, 1) }
		local MR, TR, Col = Rank(E), Rank(T), {}
		for I = 1, 3 do Col[MR[I]] = AX[TR[I]] end
		if Col[1]:Cross(Col[2]):Dot(Col[3]) < 0 then Col[MR[3]] = -Col[MR[3]] end
		return CFrame.fromMatrix(v3(), Col[1], Col[2], Col[3])
	end
	local function GameSkinParts(Holder)
		local Def = Holder:FindFirstChild("Default")
		local Out = {}
		for _, P in ipairs(Holder:GetDescendants()) do
			if P:IsA("BasePart") and P.Name ~= "Handle" and P.Transparency < 1 and P ~= Def and not (Def and P:IsDescendantOf(Def))
				and not OURS[P.Name] and not P:FindFirstAncestor("SkinModel") then
				Out[#Out + 1] = P
			end
		end
		return Def, Out
	end
	local function HoldTexture(R, Def, Tex, Anchored)
		if Anchored or not Def:IsA("MeshPart") then
			SavePart(R, Def)
			ParkSA(R, Def)
			if Def:IsA("MeshPart") then
				pcall(function() Def.TextureID = Tex end)
			else
				local M = Def:FindFirstChildWhichIsA("SpecialMesh")
				if M then
					if not R.Mesh[M] then R.Mesh[M] = { M.TextureId, M.VertexColor } end
					M.TextureId = Tex
				end
			end
			return Def
		end
		local Ok, Copy = pcall(function() return Def:Clone() end)
		if not Ok or not Copy then return Def end
		for _, Ch in ipairs(Copy:GetChildren()) do Ch:Destroy() end
		Copy.Name = "AcesoSkin"
		Copy.Anchored, Copy.CanCollide, Copy.CanQuery, Copy.CanTouch, Copy.Massless = false, false, false, false, true
		Copy.Transparency = Def.Transparency
		Copy.LocalTransparencyModifier = 0
		pcall(function() Copy.TextureID = Tex end)
		Copy.CFrame = Def.CFrame
		WeldTo(Def, Copy)
		Copy.Parent = Def.Parent
		R.Added[#R.Added + 1] = Copy
		R.LTM = R.LTM or {}
		if R.LTM[Def] == nil then R.LTM[Def] = Def.LocalTransparencyModifier end
		Def.LocalTransparencyModifier = 1
		return Copy
	end
	local DefaultLook
	local LookCache = {}
	function DefaultLook(Weapon)
		if LookCache[Weapon] ~= nil then return LookCache[Weapon] or nil end
		local Src = ShopGuns[Weapon]
		if not Src then return nil end
		local Best
		for _, D in ipairs(Src:GetDescendants()) do
			if D:IsA("MeshPart") then
				if D.Name == "Default" then Best = D; break end
				if not Best or D.Size.Magnitude > Best.Size.Magnitude then Best = D end
			end
		end
		if not Best then LookCache[Weapon] = false; return nil end
		LookCache[Weapon] = { Tex = Best.TextureID, SA = Best:FindFirstChildOfClass("SurfaceAppearance") }
		return LookCache[Weapon]
	end
	local function ApplyModel(Holder, Weapon, C, Anchored)
		local Handle = Holder:FindFirstChild("Handle") or Holder:FindFirstChildWhichIsA("BasePart", true)
		if not IsBasePart(Handle) then return end
		local Skin = C.TexOnGame and BaseTexture(Weapon, C) or ""
		if C.Model == "Game skin" then
			local Def = Holder:FindFirstChild("Default")
			if Skin ~= "" and Def and Def:IsA("BasePart") then HoldTexture(Rec(Holder), Def, Skin, Anchored) end
			return
		end
		if C.Model == "Default" then
			local R = Rec(Holder)
			local Def, Extra = GameSkinParts(Holder)
			if Def and Def:IsA("BasePart") then
				for _, P in ipairs(Extra) do SavePart(R, P); P.Transparency = 1 end
				local DL = DefaultLook(Weapon)
				if Skin ~= "" then
					HoldTexture(R, Def, Skin, Anchored)
				elseif C.StripDefault then
					HoldTexture(R, Def, "", Anchored)
				elseif DL then
					local Surf = HoldTexture(R, Def, DL.Tex, Anchored)
					if DL.SA then
						local Sa = DL.SA:Clone()
						Sa.Parent = Surf
						R.Added[#R.Added + 1] = Sa
					end
				end
			elseif C.StripDefault then
				for _, P in ipairs(Holder:GetDescendants()) do
					if P:IsA("BasePart") and P.Transparency < 1 then
						SavePart(R, P)
						pcall(function() if P:IsA("MeshPart") then P.TextureID = "" end end)
						ParkSA(R, P)
					end
				end
			end
			return
		end
		if C.Model == "Base model" then
			local D = BaseMeshes.Get(Weapon)
			if not D then return end
			local Center, Box = VisibleBox(Holder, Handle)
			local Map = AxisMap(D.Ext, Box)
			local LongMesh = math.max(D.Ext.X, D.Ext.Y, D.Ext.Z)
			local LongBox = math.max(Box.X, Box.Y, Box.Z)
			local K = (LongBox > 0.2 and LongBox / LongMesh or 1) * C.MeshScale
			local P = Instance.new("Part")
			P.Name = "AcesoMesh"
			P.Size = D.Ext * K
			P.CanCollide, P.CanQuery, P.CanTouch, P.Massless, P.CastShadow = false, false, false, true, true
			local Sm = Instance.new("SpecialMesh")
			Sm.MeshType, Sm.MeshId = Enum.MeshType.FileMesh, D.Mesh
			Sm.Scale = v3(K, K, K)
			local Tex = BaseTexture(Weapon, C)
			Sm.TextureId = Tex
			Sm.VertexColor = v3(C.Tint.R, C.Tint.G, C.Tint.B)
			Sm.Parent = P
			P.Color = C.BaseColor
			P.Material = Enum.Material[C.BaseMat] or Enum.Material.SmoothPlastic
			P.Anchored = Anchored == true
			P.CFrame = Handle.CFrame * CFrame.new(Center + v3(C.OffX, C.OffY, C.OffZ)) * Map * CFrame.Angles(0, math.rad(C.MeshRot + 180), 0)
			if not Anchored then WeldTo(Handle, P) end
			P.Parent = Holder
			HideRest(Holder, P)
			return
		end
		if C.Model == "Custom mesh" then
			if C.MeshId == "" then return end
			local P = Instance.new("Part")
			P.Name = "AcesoMesh"
			P.Size = v3(1, 1, 1)
			local M = Instance.new("SpecialMesh")
			M.MeshType = Enum.MeshType.FileMesh
			M.MeshId = Asset(C.MeshId)
			M.TextureId = Asset(C.TextureId)
			M.Scale = v3(1, 1, 1) * C.MeshScale
			M.VertexColor = v3(C.Tint.R, C.Tint.G, C.Tint.B)
			M.Parent = P
			P.Color = C.BaseColor
			P.CanCollide, P.Massless, P.Anchored, P.CanQuery, P.CanTouch = false, true, Anchored == true, false, false
			P.CFrame = Handle.CFrame * CFrame.new(C.OffX, C.OffY, C.OffZ) * CFrame.Angles(0, math.rad(C.MeshRot), 0)
			if not Anchored then WeldTo(Handle, P) end
			P.Parent = Holder
			HideRest(Holder, P)
			return
		end
		local Src = FindModel(Weapon, C.Model)
		if not Src then return end
		local Clone = Src:Clone()
		if Clone:IsA("BasePart") then
			local M = Instance.new("Model")
			Clone.Parent = M
			Clone = M
		end
		Clone.Name = "SkinModel"
		if Clone:IsA("Model") and not IsBasePart(Clone.PrimaryPart) then
			Clone.PrimaryPart = Clone:FindFirstChildWhichIsA("BasePart", true)
		end
		Prep(Clone)
		if Anchored then for _, P in ipairs(Clone:GetDescendants()) do if P:IsA("BasePart") then P.Anchored = true end end end
		Clone.Parent = Holder
		pcall(function() Clone:PivotTo(Handle.CFrame * CFrame.new(C.OffX, C.OffY, C.OffZ)) end)
		if not Anchored then WeldAll(Handle, Clone) end
		if Weapon == "Knife" then
			for _, P in ipairs(Clone:GetDescendants()) do
				if P:IsA("MeshPart") and P.TextureID == "" then
					local N = P.Name:lower()
					if N:find("box") or N:find("hit") then P.Transparency = 1 end
				end
			end
		end
		HideRest(Holder, Clone)
	end
	local function K(T, Sp, Li, Sz, Al, Ac, Em, Ra, X) return { T = T, Sp = Sp, Li = Li, Sz = Sz, Al = Al, Ac = Ac, Em = Em, Ra = Ra, X = X } end
	local AURA = {
		Glitter = { K(TEX.Sparkle, { 0.2, 0.8 }, { 0.6, 1.2 }, { 0, 1, 0 }, { 0, 1 }, v3(0, 0.4, 0), 1, 1),
			K(TEX.Sparkle, { 0, 0.2 }, { 0.3, 0.5 }, { 0, 2.2, 0 }, { 0.2, 1 }, v3(), 1, 0.25) },
		Sparks  = { K(TEX.Spark, { 3, 7 }, { 0.25, 0.5 }, { 0.6, 0.4, 0 }, { 0, 1 }, v3(0, -16, 0), 1, 1, { Squash = 1.4 }),
			K(TEX.Sparkle, { 0, 0.3 }, { 0.15, 0.3 }, { 0, 1.8, 0 }, { 0, 1 }, v3(), 1, 0.3) },
		Embers  = { K(TEX.Fire, { 0.4, 1.4 }, { 0.9, 1.6 }, { 0.6, 0.4, 0 }, { 0, 1 }, v3(0, 3.5, 0), 1, 1),
			K(TEX.Spark, { 1, 2.5 }, { 0.6, 1.1 }, { 0.3, 0.2, 0 }, { 0, 1 }, v3(0, 5, 0), 1, 0.6) },
		Flames  = { K(TEX.Fire, { 0.6, 1.4 }, { 0.3, 0.6 }, { 1.4, 1, 0 }, { 0.05, 1 }, v3(0, 7, 0), 1, 1.4),
			K(TEX.Fire, { 0.2, 0.6 }, { 0.2, 0.4 }, { 0.9, 0.5, 0 }, { 0, 1 }, v3(0, 4, 0), 1, 0.8, { White = true }),
			K(TEX.Smoke, { 0.5, 1 }, { 0.8, 1.4 }, { 1, 2, 3 }, { 0.75, 1 }, v3(0, 3, 0), 0, 0.3, { Dark = true }) },
		Smoke   = { K(TEX.Smoke, { 0.2, 0.7 }, { 1.2, 2 }, { 1.2, 2.6, 4 }, { 0.6, 1 }, v3(0, 1.2, 0), 0, 1) },
		Mist    = { K(TEX.Smoke, { 0.05, 0.2 }, { 1.5, 2.5 }, { 2, 3, 3.5 }, { 0.82, 1 }, v3(0, 0.2, 0), 0.7, 1) },
		Stars   = { K(TEX.Sparkle, { 0, 0.3 }, { 0.8, 1.6 }, { 0, 1.6, 0 }, { 0, 1 }, v3(), 1, 1),
			K(TEX.Sparkle, { 0, 0.1 }, { 0.2, 0.35 }, { 0, 3.2, 0 }, { 0.3, 1 }, v3(), 1, 0.15) },
		Drip    = { K(TEX.Sparkle, { 0, 0.2 }, { 0.6, 1 }, { 0.8, 0.6, 0.2 }, { 0, 1 }, v3(0, -20, 0), 1, 1, { Squash = -1 }) },
		Aura    = { K(TEX.Smoke, { 0.1, 0.4 }, { 0.8, 1.3 }, { 1.6, 2.4, 0.4 }, { 0.7, 1 }, v3(0, 2, 0), 1, 1),
			K(TEX.Sparkle, { 0.3, 1 }, { 0.5, 1 }, { 0, 0.8, 0 }, { 0, 1 }, v3(0, 3, 0), 1, 0.7) },
		Frost   = { K(TEX.Smoke, { 0.05, 0.25 }, { 1, 1.8 }, { 1.2, 2, 2.6 }, { 0.75, 1 }, v3(0, -0.5, 0), 0.5, 0.6, { White = true }),
			K(TEX.Sparkle, { 0.1, 0.5 }, { 0.6, 1.2 }, { 0, 1, 0 }, { 0, 1 }, v3(0, -1, 0), 1, 1) },
		Void    = { K(TEX.Smoke, { 0.1, 0.4 }, { 1, 1.6 }, { 1, 2, 2.6 }, { 0.3, 1 }, v3(0, 0.6, 0), 0, 1, { Dark = true }),
			K(TEX.Sparkle, { 0.2, 0.6 }, { 0.4, 0.8 }, { 0, 1, 0 }, { 0, 1 }, v3(0, 1, 0), 1, 0.8) },
		Galaxy  = { K(TEX.Smoke, { 0.05, 0.2 }, { 1.4, 2.2 }, { 1.4, 2.4, 3 }, { 0.75, 1 }, v3(), 1, 0.5, { Rainbow = true }),
			K(TEX.Sparkle, { 0, 0.2 }, { 0.8, 1.6 }, { 0, 1.2, 0 }, { 0, 1 }, v3(), 1, 1, { White = true }) },
		Electric = { K(TEX.Spark, { 6, 12 }, { 0.08, 0.16 }, { 0.8, 0.5, 0 }, { 0, 1 }, v3(), 1, 1.6, { Squash = 3, White = true }),
			K(TEX.Sparkle, { 0, 0.2 }, { 0.1, 0.2 }, { 0, 2.4, 0 }, { 0.2, 1 }, v3(), 1, 0.4) },
		Bubbles = { K(TEX.Ring, { 0.3, 0.8 }, { 1.2, 2 }, { 0.2, 0.7, 1 }, { 0.3, 1 }, v3(0, 1.6, 0), 0.6, 0.6, { White = true }) },
		Petals  = { K(TEX.Smoke, { 0.3, 1 }, { 1.4, 2.2 }, { 0.5, 0.45, 0.3 }, { 0.1, 1 }, v3(1.2, -1.5, 0), 0.2, 0.8, { Squash = 0.6 }) },
		Snow    = { K(TEX.Sparkle, { 0.1, 0.4 }, { 1.4, 2.2 }, { 0.5, 0.4, 0 }, { 0, 1 }, v3(0, -2.5, 0), 0.6, 1, { White = true }),
			K(TEX.Smoke, { 0, 0.1 }, { 1, 1.6 }, { 1, 1.6, 2 }, { 0.88, 1 }, v3(0, -0.5, 0), 0.4, 0.3, { White = true }) },
		Orbit = {}, Comets = {}, Halo = {}, Arcs = {},
	}
	local Anims = setmetatable({}, { __mode = "k" })
	local function Spark(Att, C, S, Rate, Life, Size)
		local E = Instance.new("ParticleEmitter")
		E.Texture = TEX.Sparkle
		E.Speed = NumberRange.new(0)
		E.Lifetime = NumberRange.new(Life * 0.8, Life)
		E.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, Size * S), NumberSequenceKeypoint.new(1, 0) })
		E.Transparency = NumberSequence.new(0, 1)
		E.Color = ColorSequence.new(C.PartC1, C.PartC2)
		E.LightEmission, E.LightInfluence = 1, 0
		E.Rate = Rate * (Library.Quality or 1)
		E.LockedToPart = false
		E.Parent = Att
		return E
	end
	local function Animate(P, C, Box)
		local Kind = C.PartStyle
		local X, Y, Z = Box.X, Box.Y, Box.Z
		local Long = (X >= Y and X >= Z) and v3(1, 0, 0) or ((Z >= Y) and v3(0, 0, 1) or v3(0, 1, 0))
		local Up = v3(0, 1, 0)
		if Long == Up then Up = v3(1, 0, 0) end
		local Side = Long:Cross(Up)
		local Len = Long:Dot(Box)
		local Rad = math.max((Box - Long * Len).Magnitude * 0.6, 0.25) + 0.15
		local S = C.PartSize * 2.2
		local A = { P = P, Kind = Kind, Atts = {}, Long = Long, Up = Up, Side = Side, Len = Len, Rad = Rad, Speed = math.max(C.PartSpeed, 0.1), T0 = os.clock() }
		local function Att()
			local At = Instance.new("Attachment")
			At.Parent = P
			A.Atts[#A.Atts + 1] = At
			return At
		end
		if Kind == "Orbit" then
			for _ = 1, 3 do Spark(Att(), C, S, 45, 0.5, 0.35) end
		elseif Kind == "Comets" then
			for _ = 1, 2 do Spark(Att(), C, S, 70, 0.35, 0.5) end
		elseif Kind == "Halo" then
			for _ = 1, 6 do Spark(Att(), C, S, 22, 0.35, 0.28) end
		elseif Kind == "Arcs" then
			A.Beams = {}
			for _ = 1, 3 do
				local A0, A1 = Att(), Att()
				local B = Instance.new("Beam")
				B.Attachment0, B.Attachment1 = A0, A1
				B.Texture = TEX.Spark
				B.TextureSpeed, B.TextureLength = 4, 0.6
				B.LightEmission, B.LightInfluence, B.FaceCamera, B.Segments = 1, 0, true, 6
				B.Width0, B.Width1 = 0.08 * S, 0.04 * S
				B.Color = ColorSequence.new(C.PartC1:Lerp(Color3.new(1, 1, 1), 0.4), C.PartC2)
				B.Parent = P
				A.Beams[#A.Beams + 1] = B
			end
		else
			return
		end
		Anims[P] = A
	end
	local ArcT = 0
	On(RunService.Heartbeat, function()
		if not next(Anims) then return end
		local Now = os.clock()
		local NewArcs = Now - ArcT > 0.07
		if NewArcs then ArcT = Now end
		for P, A in pairs(Anims) do
			if not P.Parent then
				Anims[P] = nil
			else
				local T = (Now - A.T0) * A.Speed
				local L, U, Sd, Len, R = A.Long, A.Up, A.Side, A.Len, A.Rad
				if A.Kind == "Orbit" then
					for I, At in ipairs(A.Atts) do
						local Ang = T * 4 + I * 2.094
						At.Position = L * math.sin(T * 1.3 + I) * Len * 0.4 + U * math.cos(Ang) * R + Sd * math.sin(Ang) * R
					end
				elseif A.Kind == "Comets" then
					for I, At in ipairs(A.Atts) do
						local Ang = T * 7 + I * math.pi
						At.Position = L * math.sin(T * 2 + I * math.pi) * Len * 0.5 + U * math.cos(Ang) * R * 0.8 + Sd * math.sin(Ang) * R * 0.8
					end
				elseif A.Kind == "Halo" then
					for I, At in ipairs(A.Atts) do
						local Ang = T * 3 + I / #A.Atts * math.pi * 2
						At.Position = U * (R + 0.35) + L * math.cos(Ang) * R * 0.9 + Sd * math.sin(Ang) * R * 0.9
					end
				elseif A.Kind == "Arcs" and NewArcs then
					local Rnd = Random.new()
					local function Pt() return L * (Rnd:NextNumber() - 0.5) * Len + U * (Rnd:NextNumber() - 0.5) * R * 1.6 + Sd * (Rnd:NextNumber() - 0.5) * R * 1.6 end
					for I, B in ipairs(A.Beams) do
						B.Attachment0.Position, B.Attachment1.Position = Pt(), Pt()
						B.CurveSize0, B.CurveSize1 = (Rnd:NextNumber() - 0.5) * 1.5, (Rnd:NextNumber() - 0.5) * 1.5
						B.Enabled = Rnd:NextNumber() < 0.8
					end
				end
			end
		end
	end)
	local function ApplyAura(Holder, Handle, C, Anchored)
		local Style = AURA[C.PartStyle] or AURA.Glitter
		local Center, Box = VisibleBox(Holder, Handle)
		local P = Instance.new("Part")
		P.Name = "AcesoAura"
		P.Transparency, P.CanCollide, P.CanQuery, P.CanTouch, P.Massless, P.CastShadow = 1, false, false, false, true, false
		P.Size = v3(math.max(Box.X, 0.2), math.max(Box.Y, 0.2), math.max(Box.Z, 0.2))
		P.Anchored = Anchored == true
		P.CFrame = Handle.CFrame * CFrame.new(Center)
		local S, Q = C.PartSize, Library.Quality or 1
		for _, L in ipairs(Style) do
			local E = Instance.new("ParticleEmitter")
			local X = L.X or {}
			E.Texture = L.T
			E.Speed = NumberRange.new(L.Sp[1] * C.PartSpeed, L.Sp[2] * C.PartSpeed)
			E.Lifetime = NumberRange.new(L.Li[1], L.Li[2])
			E.LightEmission, E.LightInfluence = L.Em, L.Em > 0.5 and 0 or 1
			E.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, L.Sz[1] * S), NumberSequenceKeypoint.new(0.4, L.Sz[2] * S), NumberSequenceKeypoint.new(1, L.Sz[3] * S) })
			E.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.1, L.Al[1]), NumberSequenceKeypoint.new(1, L.Al[2]) })
			local A, B = C.PartC1, C.PartC2
			if X.White then A, B = C.PartC1:Lerp(Color3.new(1, 1, 1), 0.6), C.PartC2:Lerp(Color3.new(1, 1, 1), 0.6) end
			if X.Dark then A, B = C.PartC1:Lerp(Color3.new(0, 0, 0), 0.75), C.PartC2:Lerp(Color3.new(0, 0, 0), 0.85) end
			if X.Rainbow then
				E.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, A), ColorSequenceKeypoint.new(0.5, B), ColorSequenceKeypoint.new(1, A:Lerp(Color3.fromRGB(120, 60, 255), 0.6)) })
			else
				E.Color = ColorSequence.new(A, B)
			end
			E.Acceleration = L.Ac
			E.SpreadAngle = Vector2.new(180, 180)
			E.Rotation = NumberRange.new(0, 360)
			E.RotSpeed = NumberRange.new(-80, 80)
			E.Drag = 1.5
			if X.Squash then E.Squash = NumberSequence.new(X.Squash) end
			E.Rate = C.PartRate * L.Ra * Q
			pcall(function()
				E.Shape = Enum.ParticleEmitterShape.Box
				E.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
			end)
			E.Parent = P
		end
		if not Anchored then Animate(P, C, Box) end
		if C.PartLight then
			local L = Instance.new("PointLight")
			L.Color, L.Range, L.Brightness, L.Shadows = C.PartC1, C.PartRange, 1.6, false
			L.Parent = P
		end
		if C.PartTrail and not Anchored then
			local Long = (Box.X >= Box.Y and Box.X >= Box.Z) and v3(1, 0, 0) or ((Box.Z >= Box.Y) and v3(0, 0, 1) or v3(0, 1, 0))
			local Half = Long * (Long:Dot(Box) * 0.5)
			local A0, A1 = Instance.new("Attachment"), Instance.new("Attachment")
			A0.Position, A1.Position = Half, -Half
			A0.Parent, A1.Parent = P, P
			local T = Instance.new("Trail")
			T.Attachment0, T.Attachment1 = A0, A1
			T.Lifetime, T.MinLength, T.LightEmission, T.LightInfluence, T.FaceCamera = 0.25, 0.05, 1, 0, false
			T.Color = ColorSequence.new(C.PartC1, C.PartC2)
			T.Transparency = NumberSequence.new(0.35, 1)
			T.Parent = P
		end
		if not Anchored then WeldTo(Handle, P) end
		P.Parent = Holder
	end
	local function ApplyOverride(Holder, C)
		local R = Rec(Holder)
		local Mat = C.Material ~= "Original" and Enum.Material[C.Material] or nil
		local Tex = C.Texture ~= "" and Asset(C.Texture) or nil
		local Strip = (C.Strip or Mat ~= nil) and not Tex
		local Parts = {}
		for _, P in ipairs(Holder:GetDescendants()) do
			if P:IsA("BasePart") and P.Transparency < 1 and P.Name ~= "AcesoAura" then
				SavePart(R, P)
				local Orig = R.Parts[P]
				local _, _, Val = Orig.C:ToHSV()
				local Outline = C.Outlines and Val < 0.13
				local Tiny = (not C.Details) and P.Size.Magnitude < 0.2
				if Mat then P.Material = Mat end
				P.Reflectance = C.Reflect
				for _, Ch in ipairs(P:GetChildren()) do
					if Ch:IsA("SurfaceAppearance") and (Strip or Tex) then
						R.SA[Ch] = P
						Ch.Parent = nil
					elseif Ch:IsA("SpecialMesh") or Ch:IsA("FileMesh") then
						if not R.Mesh[Ch] then R.Mesh[Ch] = { Ch.TextureId, Ch:IsA("SpecialMesh") and Ch.VertexColor or v3(1, 1, 1) } end
						if Tex then Ch.TextureId = Tex elseif Strip then Ch.TextureId = "" end
					elseif Ch:IsA("Decal") or Ch:IsA("Texture") then
						if not R.Decal[Ch] then R.Decal[Ch] = { Ch.Transparency, Ch.Color3 } end
						if C.Details then Ch.Color3 = C.C1 elseif Strip then Ch.Transparency = 1 end
					end
				end
				if P:IsA("MeshPart") then
					pcall(function()
						if Tex then P.TextureID = Tex elseif Strip then P.TextureID = "" end
					end)
				end
				if not Outline and not Tiny then Parts[P] = true end
			end
		end
		local Handle = Holder:FindFirstChild("Handle") or next(Parts)
		local Pivot = IsBasePart(Handle) and Handle.CFrame or CFrame.new()
		local Lo, Hi, Axis = math.huge, -math.huge, "Z"
		local Ext = { X = { math.huge, -math.huge }, Y = { math.huge, -math.huge }, Z = { math.huge, -math.huge } }
		for P in pairs(Parts) do
			local L = Pivot:PointToObjectSpace(P.Position)
			for _, K in ipairs({ "X", "Y", "Z" }) do
				Ext[K][1] = math.min(Ext[K][1], L[K]); Ext[K][2] = math.max(Ext[K][2], L[K])
			end
		end
		local Best = -1
		for K, E in pairs(Ext) do if E[2] - E[1] > Best then Best, Axis, Lo, Hi = E[2] - E[1], K, E[1], E[2] end end
		for P in pairs(Parts) do
			local L = Pivot:PointToObjectSpace(P.Position)
			Parts[P] = Hi > Lo and (L[Axis] - Lo) / (Hi - Lo) or 0
			P.Color = C.C1
		end
		Live[Holder] = { cfg = C, parts = Parts }
	end
	local function ColorAt(Mode, A, B, Speed, Frac, T)
		if Mode == "Rainbow" then return Color3.fromHSV((Frac * 0.5 + T * 0.2 * Speed) % 1, 0.8, 1) end
		if Mode == "Gradient" then
			local X = (Frac + T * 0.35 * Speed) % 1
			return A:Lerp(B, 1 - math.abs(X * 2 - 1))
		end
		if Mode == "Pulse" then return A:Lerp(B, 0.5 + 0.5 * math.sin(T * Speed * 4)) end
		return A
	end
	local Applying = setmetatable({}, { __mode = "k" })
	local function ApplyHolder(Holder, Weapon, Anchored)
		local Key = KeyFor(Weapon)
		local C = Get(Key)
		if not Anchored then
			RememberTool(Holder)
			Touched[Holder] = true
		end
		Applying[Holder] = true
		Clear(Holder)
		pcall(ApplyModel, Holder, Key, C, Anchored)
		if C.OvOn then pcall(ApplyOverride, Holder, C) end
		if C.PartOn then
			local Handle = Holder:FindFirstChild("Handle") or Holder:FindFirstChildWhichIsA("BasePart", true)
			if IsBasePart(Handle) then pcall(ApplyAura, Holder, Handle, C, Anchored) end
		end
		Applying[Holder] = nil
	end
	local function WeaponOf(Tool)
		if Handles[Tool.Name] then return Handles[Tool.Name] end
		local N = Tool:IsA("Tool") and Tool.Name:match("^%[(.+)%]$")
		if not N or Blocked(N) then return nil end
		if CategoryFor(N) == "Knife" then return N end
		N = Canon(N)
		if KNOWN[N] or HasAmmo(Tool) then return N end
		return nil
	end
	local function ApplyAll()
		local Char = lp.Character
		if not Char then return end
		for _, Child in ipairs(Char:GetChildren()) do
			local Wp = WeaponOf(Child)
			if Wp then pcall(ApplyHolder, Child, Wp) end
		end
	end
	local function ClearAll()
		local Char = lp.Character
		if not Char then return end
		for _, Child in ipairs(Char:GetChildren()) do if WeaponOf(Child) then Clear(Child) end end
	end
	local Dirty, LiveT = {}, 0
	local LastFull = setmetatable({}, { __mode = "k" })
	On(RunService.Heartbeat, function()
		local T = os.clock()
		if next(Dirty) then
			for Holder, Kind in pairs(Dirty) do
				local Wait = Kind == "full" and T - (LastFull[Holder] or 0) <= 0.75
				if not Wait then
					Dirty[Holder] = nil
					local Wp = Holder.Parent and WeaponOf(Holder)
					local C = Wp and Get(KeyFor(Wp))
					if C and Kind == "full" and C.Model ~= "Game skin" then
						LastFull[Holder] = T
						pcall(ApplyHolder, Holder, Wp)
					elseif C and C.OvOn then
						Applying[Holder] = true
						pcall(ApplyOverride, Holder, C)
						Applying[Holder] = nil
					end
				end
			end
		end
		if T - LiveT < 0.05 then return end
		LiveT = T
		for Holder, L in pairs(Live) do
			if not Holder.Parent then Live[Holder] = nil
			elseif L.cfg.CMode ~= "Solid" then
				for P, F in pairs(L.parts) do
					if P.Parent then P.Color = ColorAt(L.cfg.CMode, L.cfg.C1, L.cfg.C2, L.cfg.CSpeed, F, T) end
				end
			end
		end
	end)
	local FX = workspace:FindFirstChild("AcesoFX") or Instance.new("Folder")
	FX.Name = "AcesoFX"
	FX.Parent = workspace
	local Host = Instance.new("Part")
	Host.Name = "Host"
	Host.Anchored, Host.CanCollide, Host.CanQuery, Host.CanTouch, Host.Transparency = true, false, false, false, 1
	Host.Size = v3(1, 1, 1)
	Host.CFrame = CFrame.new()
	Host.Parent = FX
	local Opt = { Detect = "Instant" }
	local MuzzleMemo = {}
	local AimParams = RaycastParams.new()
	AimParams.FilterType = Enum.RaycastFilterType.Exclude
	local function HandPos()
		local Ch = lp.Character
		local H = Ch and (Ch:FindFirstChild("RightHand") or Ch:FindFirstChild("Right Arm"))
		return H and H.Position or workspace.CurrentCamera.CFrame.Position
	end
	local function AimPoint()
		local Cam = workspace.CurrentCamera
		AimParams.FilterDescendantsInstances = { Cam, lp.Character, FX }
		local M = UserInputService:GetMouseLocation()
		local R = Cam:ViewportPointToRay(M.X, M.Y)
		local Hit = workspace:Raycast(R.Origin, R.Direction * 2000, AimParams)
		return Hit and Hit.Position or (R.Origin + R.Direction * 2000), Hit
	end
	local function MuzzleOf(Tool, Toward)
		if not Tool then return HandPos() end
		local Handle = Tool:FindFirstChild("Handle")
		local Wp = WeaponOf(Tool)
		if Wp and MuzzleMemo[Wp] and IsBasePart(Handle) then return Handle.CFrame:PointToWorldSpace(MuzzleMemo[Wp]) end
		local Parts, Best, Score = {}, nil, nil
		for _, D in ipairs(Tool:GetDescendants()) do
			if D:IsA("Attachment") then
				local L = D.Name:lower()
				local S = (L:find("muzzle", 1, true) and 3) or (L:find("firepoint", 1, true) and 2) or (L:find("barrel", 1, true) and 1)
				if S and (not Score or S > Score) then Best, Score = D, S end
			elseif D:IsA("BasePart") and D.Transparency < 1 then
				Parts[#Parts + 1] = D
			end
		end
		if Best then return Best.WorldPosition end
		local Origin = IsBasePart(Handle) and Handle.Position or HandPos()
		local Dir = Toward and (Toward - Origin) or workspace.CurrentCamera.CFrame.LookVector
		if Dir.Magnitude < 0.1 then return Origin end
		Dir = Dir.Unit
		local Pt, Far
		for _, D in ipairs(Parts) do
			local CF, S = D.CFrame, D.Size
			local Reach = math.abs(Dir:Dot(CF.RightVector)) * S.X * 0.5 + math.abs(Dir:Dot(CF.UpVector)) * S.Y * 0.5 + math.abs(Dir:Dot(CF.LookVector)) * S.Z * 0.5
			local Dist = (D.Position - Origin):Dot(Dir) + Reach
			if not Far or Dist > Far then Far, Pt = Dist, D.Position + Dir * Reach end
		end
		return Pt or Origin
	end
	local Gun = { Tool = nil, W = nil }
	local function Regun()
		Gun.Tool, Gun.W = nil, nil
		local Ch = lp.Character
		if not Ch then return end
		for _, T in ipairs(Ch:GetChildren()) do
			if T:IsA("Tool") then
				local Wp = WeaponOf(T)
				if Wp and CategoryFor(Wp) ~= "Knife" then Gun.Tool, Gun.W = T, Wp end
			end
		end
	end
	local function CurrentGun() return Gun.Tool, Gun.W end
	local RNG = Random.new()
	local BTEX = { None = "", Sparks = TEX.Sparkle, Smoke = TEX.Smoke, Fire = TEX.Fire }
	local PTEX = { Sparks = TEX.Spark, Glitter = TEX.Sparkle, Embers = TEX.Fire, Smoke = TEX.Smoke, Stars = TEX.Sparkle, Flare = TEX.Smoke }
	local function Profile(Draw, X)
		local N = #Draw
		if N < 2 then return 0 end
		local P = (X % 1) * (N - 1) + 1
		local I = math.floor(P)
		local A, B = Draw[I] or 0, Draw[math.min(I + 1, N)] or 0
		return A + (B - A) * (P - I)
	end
	local function Basis(Dir)
		local Up = math.abs(Dir.Y) > 0.95 and v3(1, 0, 0) or v3(0, 1, 0)
		local Rt = Dir:Cross(Up).Unit
		return Rt, Rt:Cross(Dir).Unit
	end
	local function Paths(From, To, C, T, Rng)
		Rng = Rng or RNG
		local Out = {}
		local Delta = To - From
		local Dist = Delta.Magnitude
		if Dist < 0.5 then return Out, Dist, v3(0, 0, -1), v3(0, 1, 0) end
		local Dir = Delta / Dist
		local Rt, Up = Basis(Dir)
		local K, Qm = C.Thick, Library.Quality or 1
		local Anim = C.Animate and 1 or 0
		local function Count(PerStud, Lo, Hi) return math.clamp(math.floor(Dist * PerStud * Qm), Lo, Hi) end
		local function Curve(N, Fn)
			local P = table.create(N + 1)
			for I = 0, N do
				local F = I / N
				P[I + 1] = From + Delta * F + Fn(F, I)
			end
			return P
		end
		local function Jag(A, B, N, Am)
			local P = table.create(N + 1)
			P[1] = A
			for I = 1, N - 1 do
				local F = I / N
				local E = 0.35 + 0.65 * math.sin(F * math.pi)
				P[I + 1] = A:Lerp(B, F) + (Rt * (Rng:NextNumber() - 0.5) + Up * (Rng:NextNumber() - 0.5)) * Am * 2 * E
			end
			P[N + 1] = B
			return P
		end
		local function Shake(P, J)
			if J <= 0 then return P end
			for I = 2, #P - 1 do P[I] = P[I] + (Rt * (Rng:NextNumber() - 0.5) + Up * (Rng:NextNumber() - 0.5)) * J * 0.3 end
			return P
		end
		local Prev = {}
		for _, L in ipairs(C.Layers or {}) do
			if L.On ~= false then
				local Mine = {}
				local Copies = math.clamp(math.floor((L.Copies or 1) + 0.5), 1, 4)
				local Spin = (L.Spins == false and 0 or (L.Spin or 1)) * Anim
				local Ph = math.rad(L.Phase or 0)
				local Amp, Freq = L.Amp or 1, math.max(L.Freq or 1, 0.05)
				local Ty = L.Type
				local Sm = SMOOTH[Ty] == true
				local function Add(P, O, Extra)
					Mine[#Mine + 1] = { P = Sm and P or Shake(P, L.Jitter or 0), O = O or 0, Sm = Sm, Cl = Extra and Extra.Cl, Ups = Extra and Extra.Ups }
				end
				if Ty == "Glow" then
					for _, Q in ipairs(Prev) do Mine[#Mine + 1] = { P = Q.P, O = Q.O, Sm = Q.Sm, Cl = Q.Cl } end
				elseif Ty == "Line" then
					Add(Curve(Count(0.15, 3, 12), function() return v3() end))
				elseif Ty == "Lightning" then
					local Am = math.min(Dist * 0.03, 1.2) * Amp
					for St = 1, Copies do Add(Jag(From, To, Count(0.45 * Freq, 5, 48), Am), (St - 1) * 0.2) end
				elseif Ty == "Branches" then
					local Base = Prev[1] and Prev[1].P
					local Am = math.min(Dist * 0.03, 1.2) * Amp
					if Base then
						for _ = 1, math.clamp(math.floor(Dist / 12 * Freq), 1, 8) do
							local S = Base[Rng:NextInteger(2, math.max(2, #Base - 1))]
							local Len = math.min(Dist * 0.15, 6) * (0.5 + Rng:NextNumber())
							local E = S + (Dir * 0.6 + Rt * (Rng:NextNumber() - 0.5) * 2 + Up * (Rng:NextNumber() - 0.5) * 2).Unit * Len
							Add(Jag(S, E, 4, Am * 0.6), 0.3)
						end
					end
				elseif Ty == "Helix" then
					local N, R = Count(0.5, 8, 40), 0.25 * Amp
					for St = 0, Copies - 1 do
						local Off = St / Copies * 2 * math.pi + Ph + T * 6 * Spin
						Add(Curve(N, function(F)
							local A = F * Dist * 1.4 * Freq + Off
							return (Rt * math.cos(A) + Up * math.sin(A)) * R
						end), St / Copies)
					end
				elseif Ty == "Spiral" then
					local N = Count(0.5, 8, 40)
					for St = 0, Copies - 1 do
						local Off = St / Copies * 2 * math.pi + Ph + T * 5 * Spin
						Add(Curve(N, function(F)
							local A = F * Dist * 1.1 * Freq + Off
							local R = 0.55 * Amp * math.min(1, F * 4) * (1 - F * 0.3)
							return (Rt * math.cos(A) + Up * math.sin(A)) * R
						end), St / Copies)
					end
				elseif Ty == "Ribbon" then
					local N = Count(0.35, 6, 28)
					local P, Ups = table.create(N + 1), table.create(N + 1)
					for I = 0, N do
						local F = I / N
						local A = F * Dist * 0.45 * Freq + T * 4 * Spin + Ph
						P[I + 1] = From + Delta * F
						Ups[I + 1] = Up * math.cos(A) + Rt * math.sin(A)
					end
					Mine[#Mine + 1] = { P = P, O = 0, Ups = Ups }
				elseif Ty == "Wave" then
					local N = Count(0.4, 8, 32)
					for St = 0, Copies - 1 do
						local Rot = Ph + St / Copies * math.pi
						local Ax = Up * math.cos(Rot) + Rt * math.sin(Rot)
						local Off = T * 8 * Spin + St * 1.3
						Add(Curve(N, function(F) return Ax * math.sin(F * Dist * 1.2 * Freq + Off) * 0.35 * Amp * math.sin(F * math.pi) end), St / Copies)
					end
				elseif Ty == "Zigzag" then
					local N = Count(0.5 * Freq, 6, 40)
					local Flip = (Spin ~= 0 and math.floor(T * 10 * math.abs(Spin)) % 2 == 1) and -1 or 1
					for St = 0, Copies - 1 do
						local Rot = Ph + St / Copies * math.pi
						local Ax = Up * math.cos(Rot) + Rt * math.sin(Rot)
						Add(Curve(N, function(F, I)
							if I == 0 or I == N then return v3() end
							return Ax * ((I % 2 == 0) and 1 or -1) * Flip * 0.3 * Amp * math.sin(F * math.pi) ^ 0.5
						end), St / Copies)
					end
				elseif Ty == "Noise" then
					local N = Count(0.3, 6, 28)
					for St = 0, Copies - 1 do
						local Sd = St * 7.31 + 1.7
						local Tt = T * 2 * Spin
						Add(Curve(N, function(F)
							local E = math.sin(F * math.pi) * 0.45 * Amp
							return (Rt * math.noise(F * 6 * Freq, Sd, Tt) + Up * math.noise(F * 6 * Freq, Sd + 3.1, Tt)) * E
						end), St * 0.25)
					end
				elseif Ty == "Drawn" then
					local N = Count(0.7, 12, 72)
					local Rep = math.max(1, math.floor(Dist / 14 * Freq + 0.5))
					for St = 0, Copies - 1 do
						local An = Ph + St / Copies * 2 * math.pi + T * 3 * Spin
						local AxU = Up * math.cos(An) + Rt * math.sin(An)
						local AxS = Rt * math.cos(An) - Up * math.sin(An)
						local Scroll = T * 0.6 * Spin
						Add(Curve(N, function(F)
							local X = F * Rep + Scroll
							return (AxU * Profile(L.Draw or {}, X) + AxS * Profile(L.Draw2 or {}, X)) * 0.5 * Amp
						end), St / Copies)
					end
				elseif Ty == "Sketch" then
					local Sk = L.Sketch or {}
					if #Sk >= 2 then
						local Rep = math.max(1, math.floor(Dist / 14 * Freq + 0.5))
						local Step = math.max(1, math.ceil(#Sk * Rep / (60 * Qm)))
						for St = 0, Copies - 1 do
							local An = Ph + St / Copies * 2 * math.pi + T * 3 * Spin
							local AxU = Up * math.cos(An) + Rt * math.sin(An)
							local P = {}
							for R = 0, Rep - 1 do
								for I = 1, #Sk, Step do
									local Pt = Sk[I]
									P[#P + 1] = From + Delta * ((R + Pt[1]) / Rep) + AxU * Pt[2] * 0.5 * Amp
								end
							end
							local Last = Sk[#Sk]
							P[#P + 1] = From + Delta * ((Rep - 1 + Last[1]) / Rep) + AxU * Last[2] * 0.5 * Amp
							if #P >= 2 then Add(P, St / Copies) end
						end
					end
				elseif Ty == "Rings" then
					local Rings = math.clamp(math.floor(Dist / 6 * Freq * Qm), 2, 14)
					for I = 1, Rings do
						local F = I / (Rings + 1)
						local Cn = From + Delta * F
						local R = (0.2 + 0.25 * math.sin(F * math.pi)) * Amp
						local P = table.create(7)
						for J = 0, 6 do
							local A = J / 6 * 2 * math.pi + T * 3 * Spin + Ph
							P[J + 1] = Cn + (Rt * math.cos(A) + Up * math.sin(A)) * R
						end
						Add(P, F, { Cl = true })
					end
				elseif Ty == "Dashes" then
					local Dashes = math.clamp(math.floor(Dist / 8 * Freq), 2, 14)
					for I = 0, Dashes - 1 do
						local F = ((I / Dashes) + T * 1.4 * Spin) % 1
						Add({ From + Delta * F, From + Delta * math.min(F + 0.5 / Dashes, 1) }, F)
					end
				end
				for _, M in ipairs(Mine) do
					Out[#Out + 1] = { P = M.P, O = M.O, Sm = M.Sm, Cl = M.Cl, Ups = M.Ups, W = L.Width * K * 0.55, WE = L.WEnd * K * 0.55, A = L.Alpha, Lay = L }
				end
				if Ty ~= "Glow" and #Mine > 0 then Prev = Mine end
			end
		end
		return Out, Dist, Dir, Up
	end
	local function Tangents(P, Closed)
		local N, T = #P, table.create(#P)
		for I = 1, N do
			local A, B = P[I - 1], P[I + 1]
			if Closed then A, B = A or P[N - 1], B or P[2] end
			if A and B then T[I] = (B - A) * 0.5 elseif B then T[I] = B - P[I] else T[I] = P[I] - A end
		end
		return T
	end
	local function Orient(Pos, Dir, Up)
		if Dir.Magnitude < 1e-4 then Dir = v3(0, 0, -1) end
		Dir = Dir.Unit
		local U = Up - Dir * Up:Dot(Dir)
		if U.Magnitude < 1e-3 then
			U = math.abs(Dir.Y) < 0.9 and v3(0, 1, 0) or v3(1, 0, 0)
			U = U - Dir * U:Dot(Dir)
		end
		return CFrame.fromMatrix(Pos, Dir, U.Unit)
	end
	local function Envelope(C, Age)
		local Grow = C.DrawIn > 0 and math.min(Age / C.DrawIn, 1) or 1
		local K = math.clamp((Age - C.DrawIn - C.Life) / math.max(C.Fade, 0.01), 0, 1)
		return Grow, K
	end
	local function SegFx(C, F, Grow, K)
		if F > Grow then return 0, 1 end
		local V, Wm = 1, 1
		if C.Tail > 0 then V = math.min(1, F / C.Tail) end
		local S = C.FadeStyle
		if K <= 0 then return V, Wm end
		if S == "Shrink" then Wm = 1 - K
		elseif S == "Dissolve" then V = V * (1 - math.clamp((K * 1.35 - F) / 0.35, 0, 1))
		elseif S == "Flicker" then V = (RNG:NextNumber() > K * 0.85) and V * (1 - K * 0.6) or 0
		elseif S == "Fade + shrink" then V = V * (1 - K); Wm = 1 - K * 0.7
		else V = V * (1 - K) end
		return V, Wm
	end
	local function BeamColor(L, F, T)
		local Y = L.Lay
		local Col = ColorAt(Y.Mode, Y.A, Y.B, Y.Speed, F + L.O, T)
		if (Y.Whiten or 0) > 0 then Col = Col:Lerp(Color3.new(1, 1, 1), Y.Whiten) end
		return Col
	end
	local HasBright = pcall(function()
		local B = Instance.new("Beam")
		B.Brightness = 1
		B:Destroy()
	end)
	local SegPool, SegCount = {}, 0
	local function NewSeg()
		local S = table.remove(SegPool)
		if not S then
			local A0, A1, B = Instance.new("Attachment"), Instance.new("Attachment"), Instance.new("Beam")
			A0.Parent, A1.Parent = Host, Host
			B.Attachment0, B.Attachment1 = A0, A1
			B.FaceCamera, B.Segments, B.LightEmission, B.LightInfluence = true, 1, 1, 0
			B.TextureMode = Enum.TextureMode.Wrap
			B.Enabled = false
			B.Parent = Host
			S = { B = B, A0 = A0, A1 = A1, Seg = 1, Face = true, LE = 1 }
		end
		S.LA, S.LW, S.Off, S.On, S.CLay = nil, nil, false, false, nil
		SegCount = SegCount + 1
		return S
	end
	local function FreeSeg(S)
		S.B.Enabled = false
		SegCount = SegCount - 1
		SegPool[#SegPool + 1] = S
	end
	local LightPool, LightCount = {}, 0
	local function NewLight()
		local L = table.remove(LightPool)
		if not L then
			local A, P = Instance.new("Attachment"), Instance.new("PointLight")
			A.Parent = Host
			P.Shadows = false
			P.Parent = A
			L = { A = A, L = P }
		end
		LightCount = LightCount + 1
		L.L.Enabled = true
		return L
	end
	local function FreeLight(L)
		L.L.Enabled = false
		LightCount = LightCount - 1
		LightPool[#LightPool + 1] = L
	end
	local Emitters = {}
	local function Emit(Style, Pos, N, C)
		local E = Emitters[Style]
		if not E then
			local A, P = Instance.new("Attachment"), Instance.new("ParticleEmitter")
			A.Parent = Host
			local Smoke = Style == "Smoke"
			P.Texture = PTEX[Style] or PTEX.Sparks
			P.Rate = 0
			P.LightInfluence = 0
			P.Rotation = NumberRange.new(0, 360)
			if Style == "Flare" then
				P.Speed = NumberRange.new(0)
				P.Lifetime = NumberRange.new(0.08, 0.14)
				P.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.6), NumberSequenceKeypoint.new(1, 0) })
				P.Transparency = NumberSequence.new(0.15, 1)
				P.LightEmission = 1
				P.LockedToPart = false
			else
				P.Speed = NumberRange.new(Smoke and 1 or 5, Smoke and 4 or 16)
				P.Lifetime = NumberRange.new(0.2, Smoke and 1.1 or 0.55)
				P.SpreadAngle = Vector2.new(180, 180)
				P.Acceleration = Style == "Embers" and v3(0, 6, 0) or (Smoke and v3(0, 2, 0) or v3(0, -22, 0))
				P.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, Smoke and 0.6 or 0.22), NumberSequenceKeypoint.new(1, Smoke and 1.4 or 0) })
				P.Transparency = NumberSequence.new(Smoke and 0.5 or 0, 1)
				P.LightEmission = Smoke and 0 or 1
				P.Drag = 3
			end
			P.Parent = A
			E = { A = A, E = P }
			Emitters[Style] = E
		end
		if E.C1 ~= C.B1 or E.C2 ~= C.B2 then
			E.C1, E.C2 = C.B1, C.B2
			E.E.Color = ColorSequence.new(C.B1, C.B2)
		end
		E.A.Position = Pos
		E.E:Emit(math.max(1, math.floor(N * (Library.Quality or 1) + 0.5)))
	end
	local Shots = {}
	local function Dress(Sh, T)
		local C = Sh.C
		local Layers, Dist, Dir, Up = Paths(Sh.From, Sh.To, C, T)
		local Segs, Idx, Full = Sh.Segs, 0, false
		for _, L in ipairs(Layers) do
			if Full then break end
			local P = L.P
			local Tg = L.Sm and Tangents(P, L.Cl) or nil
			local LE = L.Lay.Emit or 1
			local Face = L.Ups == nil
			local Solid = L.Lay.Mode == "Solid"
			for I = 1, #P - 1 do
				Idx = Idx + 1
				local S = Segs[Idx]
				if not S then
					if Sh.Built then Idx = Idx - 1; Full = true; break end
					S = NewSeg()
					Segs[Idx] = S
					local B = S.B
					B.Texture = BTEX[C.Tex] or ""
					B.TextureSpeed, B.TextureLength = C.TexSpeed, 4
					if HasBright then B.Brightness = C.Bright end
				end
				local B = S.B
				if Tg then
					S.A0.CFrame = Orient(P[I], Tg[I], Up)
					S.A1.CFrame = Orient(P[I + 1], Tg[I + 1], Up)
					B.CurveSize0, B.CurveSize1 = Tg[I].Magnitude / 3, Tg[I + 1].Magnitude / 3
					if S.Seg ~= 6 then S.Seg = 6; B.Segments = 6 end
				else
					if L.Ups then
						local D = P[I + 1] - P[I]
						S.A0.CFrame = Orient(P[I], D, L.Ups[I])
						S.A1.CFrame = Orient(P[I + 1], D, L.Ups[I + 1])
					else
						S.A0.Position, S.A1.Position = P[I], P[I + 1]
					end
					if S.Seg ~= 1 then S.Seg = 1; B.Segments = 1; B.CurveSize0, B.CurveSize1 = 0, 0 end
				end
				if S.Face ~= Face then S.Face = Face; B.FaceCamera = Face end
				if S.LE ~= LE then S.LE = LE; B.LightEmission = LE end
				local F0 = math.clamp((P[I] - Sh.From):Dot(Dir) / Dist, 0, 1)
				local F1 = math.clamp((P[I + 1] - Sh.From):Dot(Dir) / Dist, 0, 1)
				S.F, S.Base, S.Off = (F0 + F1) * 0.5, L.A, false
				S.W0 = (L.W + (L.WE - L.W) * F0) * math.clamp(0.2 + F0 * Dist / 5, 0.2, 1)
				S.W1 = (L.W + (L.WE - L.W) * F1) * math.clamp(0.2 + F1 * Dist / 5, 0.2, 1)
				S.LW = nil
				if not Solid or S.CLay ~= L.Lay then
					S.CLay = L.Lay
					B.Color = ColorSequence.new(BeamColor(L, F0, T), BeamColor(L, F1, T))
				end
			end
		end
		for I = Idx + 1, #Segs do Segs[I].Off = true end
		Sh.Built = true
	end
	local function Step(Sh, Age)
		local C = Sh.C
		local Grow, K = Envelope(C, Age)
		for _, S in ipairs(Sh.Segs) do
			local V, Wm = 0, 1
			if not S.Off then V, Wm = SegFx(C, S.F, Grow, K) end
			local A = math.floor((1 - (1 - S.Base) * V) * 40 + 0.5) / 40
			if A ~= S.LA then
				S.LA = A
				local Show = A < 0.99
				if Show then S.B.Transparency = NumberSequence.new(A) end
				if Show ~= S.On then S.On = Show; S.B.Enabled = Show end
			end
			Wm = math.floor(Wm * 20 + 0.5) / 20
			if Wm ~= S.LW then
				S.LW = Wm
				S.B.Width0, S.B.Width1 = S.W0 * Wm, S.W1 * Wm
			end
		end
		if Sh.Lights then
			local Lv = Grow * (1 - K)
			for _, L in ipairs(Sh.Lights) do L.L.Brightness = Sh.LB * Lv end
		end
		if Sh.Core then
			local V = Grow * (1 - K)
			Sh.Core.Transparency = 1 - 0.85 * V
			local D = Sh.CoreLen * math.min(Grow, 1)
			Sh.Core.Size = Vector3.new(math.max(D, 0.05), Sh.CoreW * (1 - K * 0.6), Sh.CoreW * (1 - K * 0.6))
			Sh.Core.CFrame = Sh.CoreCF * CFrame.new(-Sh.CoreLen / 2 + D / 2, 0, 0)
		end
	end
	local function Kill(I)
		local Sh = table.remove(Shots, I)
		for _, S in ipairs(Sh.Segs) do FreeSeg(S) end
		if Sh.Core then Sh.Core:Destroy() end
		if Sh.Lights then for _, L in ipairs(Sh.Lights) do FreeLight(L) end end
	end
	local function Shoot(From, To, Normal, C)
		local Delta = To - From
		local Dist = Delta.Magnitude
		if Dist < 1 then return end
		local Qm = Library.Quality or 1
		while #Shots > 0 and SegCount > 160 * Qm do Kill(1) end
		local Now = os.clock()
		local Sh = { C = C, From = From, To = To, T0 = Now, Segs = {}, Next = Now + 0.08 }
		Dress(Sh, Now)
		if C.Core ~= false then
			local Main
			for _, L in ipairs(C.Layers or {}) do
				if L.On ~= false and L.Type ~= "Glow" and (L.Alpha or 0) < 0.6 then Main = L; break end
			end
			if Main then
				local P = Instance.new("Part")
				P.Anchored, P.CanCollide, P.CanQuery, P.CanTouch, P.CastShadow = true, false, false, false, false
				P.Shape, P.Material = Enum.PartType.Cylinder, Enum.Material.Neon
				P.Color = Main.A:Lerp(Color3.new(1, 1, 1), 0.35)
				Sh.CoreLen = (To - From).Magnitude
				Sh.CoreW = math.clamp(Main.Width * C.Thick * 0.3, 0.03, 0.25)
				Sh.CoreCF = CFrame.lookAt((From + To) / 2, To) * CFrame.Angles(0, math.rad(90), 0)
				P.Size = Vector3.new(0.05, Sh.CoreW, Sh.CoreW)
				P.Transparency = 1
				P.Parent = FX
				Sh.Core = P
			end
		end
		Shots[#Shots + 1] = Sh
		Step(Sh, 0)
		if C.Muzzle then Emit("Sparks", From, 5, C) end
		if C.Particles then
			for I = 1, 5 do Emit(C.PStyle, From + Delta * (I / 6), C.PInt, C) end
		end
	end
	On(RunService.RenderStepped, function()
		local N = #Shots
		if N == 0 then return end
		local Now = os.clock()
		for I = N, 1, -1 do
			local Sh = Shots[I]
			local C = Sh.C
			local Age = Now - Sh.T0
			if Age >= C.DrawIn + C.Life + C.Fade then
				Kill(I)
			else
				if C.Animate and Now >= Sh.Next then
					Sh.Next = Now + 0.08
					Dress(Sh, Now)
				end
				Step(Sh, Age)
			end
		end
	end)
	;(function()
	local Trigger = { AimDraw = 0, Held = false }
	local AmmoOf = setmetatable({}, { __mode = "k" })
	local function FindAmmo(Tool)
		local Best
		for _, D in ipairs(Tool:GetDescendants()) do
			if D:IsA("IntValue") or D:IsA("NumberValue") then
				local N = D.Name:lower()
				if N == "ammo" then return D end
				if N:find("ammo", 1, true) and not (N:find("max", 1, true) or N:find("stored", 1, true) or N:find("reserve", 1, true)) then Best = Best or D end
			end
		end
		return Best
	end
	local function CanFire(Tool)
		local A = AmmoOf[Tool]
		if A and A.Parent then return A.Value > 0 end
		return true
	end
	local function IsShotgun(Wp)
		Wp = Wp:lower()
		return Wp:find("shotgun", 1, true) or Wp:find("double", 1, true)
	end
	local function AimShot(Tool)
		local Now = os.clock()
		if Now - Trigger.AimDraw < 0.05 then return end
		local Wp = WeaponOf(Tool)
		if not Wp then return end
		Trigger.AimDraw = Now
		local C = Get(KeyFor(Wp))
		local To, Hit = AimPoint()
		local From = MuzzleOf(Tool, To)
		ShotEvent:Fire(From, To, Tool, Hit and Hit.Instance)
		if not C.Beam then return end
		local Dist = (To - From).Magnitude
		if Dist < 1 then return end
		if IsShotgun(Wp) then
			for I = 1, 5 do
				local Off = v3(RNG:NextNumber() - 0.5, RNG:NextNumber() - 0.5, RNG:NextNumber() - 0.5) * Dist * 0.04
				Shoot(From, To + Off, I == 1 and Hit and Hit.Normal or nil, C)
			end
		else
			Shoot(From, To, Hit and Hit.Normal, C)
		end
	end
	local HiddenSet = setmetatable({}, { __mode = "k" })
	local function HideTracer(O)
		if HiddenSet[O] then return end
		HiddenSet[O] = true
		pcall(function()
			if O:IsA("Beam") or O:IsA("Trail") then
				O.Enabled = false
				local Cn
				Cn = O:GetPropertyChangedSignal("Enabled"):Connect(function()
					if not O.Parent then Cn:Disconnect() return end
					if O.Enabled then O.Enabled = false end
				end)
				local P = O.Parent
				if P and P:IsA("BasePart") and P.Size.Magnitude < 12 then P.LocalTransparencyModifier = 1 end
			else
				O.LocalTransparencyModifier = 1
				for _, D in ipairs(O:GetDescendants()) do
					if D:IsA("Beam") or D:IsA("Trail") or D:IsA("ParticleEmitter") then HideTracer(D) end
				end
			end
		end)
	end
	local function TracerStart(O)
		if O:IsA("Beam") then
			local A0, A1 = O.Attachment0, O.Attachment1
			if not (A0 and A1) then return nil end
			return A0.WorldPosition, A1.WorldPosition
		end
		local N = O.Name:lower()
		if not (O.Material == Enum.Material.Neon or N:find("bullet", 1, true) or N:find("ray", 1, true) or N:find("tracer", 1, true) or N:find("beam", 1, true)) then return nil end
		local S, CF = O.Size, O.CFrame
		local L, Axis = S.X, CF.RightVector
		if S.Y > L then L, Axis = S.Y, CF.UpVector end
		if S.Z > L then L, Axis = S.Z, CF.LookVector end
		if L < 3 or (S.X + S.Y + S.Z - L) > 3 then return nil end
		return O.Position - Axis * L * 0.5, O.Position + Axis * L * 0.5
	end
	local function Active()
		local Tool, Wp = Gun.Tool, Gun.W
		if not Tool then return nil end
		local C = Get(KeyFor(Wp))
		if not (C.Beam and C.HideGame) then return nil end
		return Tool, Wp
	end
	local function NearGun(Pos, Tool)
		local Handle = Tool:FindFirstChild("Handle")
		local Ref = IsBasePart(Handle) and Handle.Position or HandPos()
		return (Pos - Ref).Magnitude < 9, Handle
	end
	local function OtherPlayers(O)
		for _, P in ipairs(Players:GetPlayers()) do
			if P ~= lp and P.Character and O:IsDescendantOf(P.Character) then return true end
		end
		return false
	end
	local function GameTracer(O, Try)
		Try = Try or 1
		local Tool, Wp = Active()
		if not Tool or not O.Parent or HiddenSet[O] then return end
		if O:IsA("Trail") then
			local A0 = O.Attachment0
			if not A0 then
				if Try < 6 then task.delay(0.02, GameTracer, O, Try + 1) end
				return
			end
			if O:IsDescendantOf(Tool) or NearGun(A0.WorldPosition, Tool) then HideTracer(O) end
			return
		end
		if O:IsA("BasePart") then
			local Bullet = O.Size.Magnitude < 1.5 and (O:FindFirstChildWhichIsA("Trail") or O.Material == Enum.Material.Neon)
			if Bullet and NearGun(O.Position, Tool) then HideTracer(O) return end
		end
		if O:IsA("Beam") and O:IsDescendantOf(Tool) then HideTracer(O) return end
		local A, B = TracerStart(O)
		if not A then
			if Try < 6 and O:IsA("Beam") then task.delay(0.02, GameTracer, O, Try + 1) end
			return
		end
		local NA, Handle = NearGun(A, Tool)
		local NB = NearGun(B, Tool)
		if not (NA or NB) then return end
		local Ref = IsBasePart(Handle) and Handle.Position or HandPos()
		local From = (A - Ref).Magnitude < (B - Ref).Magnitude and A or B
		if IsBasePart(Handle) and (From - Ref).Magnitude < 5 then MuzzleMemo[Wp] = Handle.CFrame:PointToObjectSpace(From) end
		HideTracer(O)
	end
	On(workspace.DescendantAdded, function(O)
		if not Gun.Tool then return end
		if not (O:IsA("Beam") or O:IsA("Trail") or O:IsA("BasePart")) then return end
		if not Active() or OtherPlayers(O) then return end
		task.defer(GameTracer, O)
	end)
	local function WatchPooled(B)
		if not B:IsA("Beam") or B:IsDescendantOf(FX) then return end
		B:GetPropertyChangedSignal("Enabled"):Connect(function() if B.Enabled and Active() then GameTracer(B) end end)
		local A1 = B.Attachment1
		if A1 then A1:GetPropertyChangedSignal("Position"):Connect(function() if B.Enabled and not HiddenSet[B] and Active() then GameTracer(B) end end) end
	end
	task.spawn(function()
		for I, D in ipairs(workspace:GetDescendants()) do
			if D:IsA("Beam") then pcall(WatchPooled, D) end
			if I % 4000 == 0 then task.wait() end
		end
	end)
	local Watched = setmetatable({}, { __mode = "k" })
	local function HookAmmo(Tool)
		if AmmoOf[Tool] and AmmoOf[Tool].Parent then return end
		local A = FindAmmo(Tool)
		if not A then return end
		AmmoOf[Tool] = A
		local Last = A.Value
		On(A.Changed, function(V)
			local Old = Last
			Last = V
			if V >= Old or Tool.Parent ~= lp.Character or Gun.Tool ~= Tool then return end
			if Opt.Detect ~= "Click only" and os.clock() - Trigger.AimDraw > 0.09 then AimShot(Tool) end
		end)
	end
	local function Clicked(Tool)
		if Opt.Detect == "Ammo only" then return end
		if Opt.Detect == "Click only" or CanFire(Tool) then AimShot(Tool) end
	end
	local function WatchTool(Tool)
		if Watched[Tool] then return end
		Watched[Tool] = true
		HookAmmo(Tool)
		On(Tool.DescendantAdded, function(D)
			if D:IsA("ValueBase") then HookAmmo(Tool) return end
			if Applying[Tool] or not D:IsA("BasePart") or OURS[D.Name] or D:FindFirstAncestor("SkinModel") then return end
			local N = D.Name:lower()
			local Effect = D.Material == Enum.Material.Neon or D.Size.Magnitude < 0.4 or N:find("flash", 1, true) or N:find("muzzle", 1, true)
				or N:find("beam", 1, true) or N:find("bullet", 1, true) or N:find("shell", 1, true)
			if Effect then Dirty[Tool] = Dirty[Tool] or "light" else Dirty[Tool] = "full" end
		end)
	end
	On(UserInputService.InputBegan, function(I)
		if I.UserInputType ~= Enum.UserInputType.MouseButton1 or not Gun.Tool then return end
		if UserInputService:GetFocusedTextBox() then return end
		if Library:OverMenu() then return end
		Clicked(Gun.Tool)
	end)
	local function Watch(Char)
		for _, C in ipairs(Char:GetChildren()) do if C:IsA("Tool") then WatchTool(C) end end
		On(Char.ChildAdded, function(C)
			if C:IsA("Tool") then WatchTool(C); Regun() end
			if WeaponOf(C) then task.delay(0.05, function() if C.Parent == Char then pcall(ApplyHolder, C, WeaponOf(C)) end end) end
		end)
		On(Char.ChildRemoved, function(C) if C:IsA("Tool") then task.defer(Regun) end end)
		Regun()
		task.delay(0.3, ApplyAll)
	end
	On(lp.CharacterAdded, Watch)
	if lp.Character then Watch(lp.Character) end
	end)()
	local GUN_BEAM_HASH = {
		DoubleBarrel = "109d1326878cc594bc1bb42d126250810999782f", TacticalShotgun = "109d1326878cc594bc1bb42d126250810999782f",
		Revolver = "539db315b53f77390c0aa74773158e25bedcdd6e", Shotgun = "b415a7273aa86cbc2adc445fde5435eb5afababa",
		SMG = "005af87725b42ac4ca8103d11af6bf0c7d55f7b3",
	}
	local function FindDataFolder()
		for _, Place in ipairs({ lp, lp.Character, ReplicatedStorage }) do
			local F = Place and Place:FindFirstChild("DataFolder", true)
			if F then return F end
		end
	end
	local BeamOriginal
	local function SetGameBeam(Name)
		local Folder = FindDataFolder()
		if not Folder then return false, "no DataFolder found" end
		local Eq = Folder:FindFirstChild("EquippedBulletBeams", true)
		local Inv = Folder:FindFirstChild("InventoryData", true)
		local Slot = Inv and Inv:FindFirstChild("BulletBeams", true)
		if not (Eq and Eq:IsA("StringValue")) or not (Slot and Slot:IsA("StringValue")) then return false, "no bullet beam data" end
		if BeamOriginal == nil then BeamOriginal = { Eq = Eq.Value, Slot = Slot.Value } end
		if Name == "None" then
			pcall(function() Eq.Value, Slot.Value = BeamOriginal.Eq, BeamOriginal.Slot end)
			return true
		end
		local Owned, Equipped = {}, {}
		pcall(function() Owned = HttpService:JSONDecode(Slot.Value) end)
		pcall(function() Equipped = HttpService:JSONDecode(Eq.Value) end)
		if type(Owned) ~= "table" then Owned = {} end
		if type(Equipped) ~= "table" then Equipped = {} end
		for G, Hash in pairs(GUN_BEAM_HASH) do
			Owned[Hash] = { Name = Name }
			Equipped["[" .. G .. "]"] = Hash
		end
		local Ok = pcall(function()
			Slot.Value = HttpService:JSONEncode(Owned)
			Eq.Value = HttpService:JSONEncode(Equipped)
		end)
		return Ok, (not Ok) and "couldn't write the beam data" or nil
	end
	local function GameBeams()
		local Out = { "None" }
		local R = ReplicatedStorage:FindFirstChild("BulletBeams")
		if R then for _, C in ipairs(R:GetChildren()) do Out[#Out + 1] = C.Name end end
		if #Out == 1 then for _, N in ipairs({ "Beta", "Hallows", "Kitty", "Kirumi", "Lightning" }) do Out[#Out + 1] = N end end
		return Out
	end
	local function Enc(V)
		if typeof(V) == "Color3" then return { __c = V:ToHex() } end
		if type(V) == "table" then
			local T = {}
			for K, X in pairs(V) do T[K] = Enc(X) end
			return T
		end
		return V
	end
	local function Dec(V)
		if type(V) == "table" then
			if V.__c then
				local Ok, Col = pcall(Color3.fromHex, V.__c)
				return Ok and Col or nil
			end
			local T = {}
			for K, X in pairs(V) do T[tonumber(K) or K] = Dec(X) end
			return T
		end
		return V
	end
	local function CleanLayers(Raw)
		local Out = {}
		for _, R in ipairs(type(Raw) == "table" and Raw or {}) do
			local L = NewLayer(R.Type)
			for K, V in pairs(R) do if L[K] ~= nil and (type(V) == type(L[K]) or typeof(V) == typeof(L[K])) then L[K] = V end end
			Out[#Out + 1] = L
		end
		return Out
	end
	local function Deep(V) return Dec(Enc(V)) end
	local function Pack()
		local Out = {}
		for Wp, C in pairs(Cfg) do Out[Wp] = Enc(C) end
		return Out
	end
	local function Unpack(D)
		for Wp, T in pairs(D or {}) do
			local C = Defaults()
			T = Dec(T)
			for K, V in pairs(T) do
				if K == "Layers" then
					local L = CleanLayers(V)
					if #L > 0 then C.Layers = L end
				elseif C[K] ~= nil and (type(V) == type(C[K]) or typeof(V) == typeof(C[K])) then C[K] = V end
			end
			if C.Model == "Original" then C.Model = "Game skin" end
			Cfg[Wp == "Knife" and Wp or (Canon(Wp) or Wp)] = C
		end
		ApplyAll()
	end
	local BuildTab, Studio, RebuildPanels, RefreshAll
	;(function()
	local Hub = { Sel = nil, Layer = 1, AddType = "Lightning", Mode = "Gun skins", Panels = {}, Models = {}, Status = {} }
	local function Changed(Model)
		ApplyAll()
		for _, Fn in ipairs(Hub.Status) do pcall(Fn) end
		if Model ~= false then for _, Fn in ipairs(Hub.Models) do pcall(Fn) end end
	end
	function RebuildPanels()
		for _, P in ipairs(Hub.Panels) do pcall(P) end
	end
	local Uid = 0
	local function F(N) Uid = Uid + 1; return "__sk_" .. N .. Uid end
	local function Sec(Col, Name) return Library.MakeSection(Col, { Name = Name }) end
	local function GripFor(Weapon, Src)
		if Src and Src:IsA("Tool") then return Src.Grip end
		local Roots = { lp:FindFirstChildOfClass("Backpack"), lp.Character, ReplicatedStorage, game:GetService("StarterPack") }
		for _, P in ipairs(Players:GetPlayers()) do Roots[#Roots + 1] = P.Character end
		for _, R in pairs(Roots) do
			for _, N in ipairs({ "[" .. Weapon .. "]", Weapon }) do
				local T = R and R:FindFirstChild(N, true)
				if T and T:IsA("Tool") then return T.Grip end
			end
		end
	end
	local function CloneFor(Weapon)
		local Src, IsWrap = SourceFor(Weapon)
		if not Src then return nil end
		local M = Instance.new("Model")
		pcall(function() local G = GripFor(Weapon, Src); if G then M:SetAttribute("Grip", G) end end)
		if Src:IsA("Tool") or (Src:IsA("Model") and Src:FindFirstChild("Handle")) then
			for _, C in ipairs(Src:GetChildren()) do
				if not C:IsA("LuaSourceContainer") and not C:IsA("Sound") then pcall(function() C:Clone().Parent = M end) end
			end
		else
			local C = Src:Clone()
			C.Parent = M
			if not M:FindFirstChild("Handle", true) then
				local B = C:FindFirstChildWhichIsA("BasePart", true)
				if B then B.Name = "Handle" end
			end
		end
		for _, D in ipairs(M:GetDescendants()) do
			if D:IsA("LuaSourceContainer") or D:IsA("Sound") or D:IsA("BillboardGui") or D:IsA("SurfaceGui") or D:IsA("ClickDetector") or D:IsA("ProximityPrompt") then D:Destroy()
			elseif D:IsA("BasePart") then
				D.Anchored = true
				if IsWrap then
					D.Color, D.Material = rgb(96, 98, 104), Enum.Material.SmoothPlastic
					if D:IsA("MeshPart") then pcall(function() D.TextureID = "" end) end
				end
			elseif IsWrap and (D:IsA("SurfaceAppearance") or D:IsA("Decal") or D:IsA("Texture")) then D:Destroy()
			elseif IsWrap and D:IsA("SpecialMesh") then D.TextureId = ""
			end
		end
		return M
	end
	local function Status(Wp)
		local C = Get(Wp)
		if Hub.Mode == "Beams" then return C.Beam and (tostring(C.Preset):lower() .. "  /  " .. #C.Layers .. " layers") or "game beam" end
		local Bits = {}
		if C.Model == "Base model" then Bits[#Bits + 1] = "base" elseif C.Model ~= "Default" then Bits[#Bits + 1] = C.Model == "Custom mesh" and "custom" or C.Model:lower() end
		if C.BaseSkin ~= "Plain" then Bits[#Bits + 1] = C.BaseSkin:lower() end
		if C.OvOn then Bits[#Bits + 1] = C.CMode == "Solid" and (C.Material == "Original" and "recoloured" or C.Material:lower()) or C.CMode:lower() end
		if C.PartOn then Bits[#Bits + 1] = C.PartStyle:lower() end
		return #Bits > 0 and table.concat(Bits, " / ") or "default"
	end
	local function OrbitView(Parent, Pos, Size)
		local VP = New("ViewportFrame", { Position = Pos, Size = UDim2.fromOffset(240, 200), Ambient = rgb(150, 150, 160), LightColor = W, LightDirection = v3(-1, -1, -0.6), Parent = Parent })
		Paint(VP, "BackgroundColor3", "Element")
		Corner(8, VP)
		Stroke(VP)
		local Hint = New("TextLabel", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 10, 1, -8), Size = UDim2.new(1, -20, 0, 12), Text = "", TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3, Parent = VP })
		Paint(Hint, "TextColor3", "TextDim")
		local World = Instance.new("WorldModel")
		World.Parent = VP
		local Cam = Instance.new("Camera")
		Cam.FieldOfView = 40
		Cam.Parent = VP
		VP.CurrentCamera = Cam
		local O = { VP = VP, World = World, Cam = Cam, Yaw = 30, Pitch = 15, Dist = 6, Center = v3(), Size = 3, Hint = Hint }
		function O:Place()
			local CF = CFrame.new(self.Center) * CFrame.Angles(0, math.rad(self.Yaw), 0) * CFrame.Angles(math.rad(-self.Pitch), 0, 0)
			Cam.CFrame = CF * CFrame.new(0, 0, self.Dist)
		end
		function O:Frame(M)
			local Pts, Big, BigV = {}, nil, 0
			for _, D in ipairs(M:GetDescendants()) do
				if D:IsA("BasePart") and D.Transparency < 0.95 and D.Size.Magnitude < 12 then
					local H = D.Size / 2
					local V = D.Size.X * D.Size.Y * D.Size.Z
					if V > BigV then Big, BigV = D, V end
					for _, X in ipairs({ -1, 1 }) do for _, Y in ipairs({ -1, 1 }) do for _, Z in ipairs({ -1, 1 }) do
						Pts[#Pts + 1] = D.CFrame:PointToWorldSpace(v3(H.X * X, H.Y * Y, H.Z * Z))
					end end end
				end
			end
			if not Big then
				local CF, Sz = M:GetBoundingBox()
				self.Center, self.Size = CF.Position, math.max(Sz.Magnitude, 0.5)
				self:Place()
				return
			end
			local Mid = v3()
			for _, P in ipairs(Pts) do Mid = Mid + P end
			Mid = Mid / #Pts
			local Dir, Up
			local Grip, Handle = M:GetAttribute("Grip"), M:FindFirstChild("Handle", true)
			if typeof(Grip) == "CFrame" and Handle and Handle:IsA("BasePart") then
				Dir = Handle.CFrame:VectorToWorldSpace(Grip.LookVector)
				Up = Handle.CFrame:VectorToWorldSpace(Grip.UpVector)
			else
				local Ax = { { Big.CFrame.RightVector, Big.Size.X }, { Big.CFrame.UpVector, Big.Size.Y }, { Big.CFrame.ZVector, Big.Size.Z } }
				table.sort(Ax, function(A, B) return A[2] > B[2] end)
				local Long = Ax[1][1]
				Up = math.abs(Ax[2][1]:Dot(v3(0, 1, 0))) >= math.abs(Ax[3][1]:Dot(v3(0, 1, 0))) and Ax[2][1] or Ax[3][1]
				if Up:Dot(v3(0, 1, 0)) < 0 then Up = -Up end
				local A0, A1, B0, B1 = math.huge, -math.huge, math.huge, -math.huge
				for _, P in ipairs(Pts) do
					local S, Y = (P - Mid):Dot(Long), (P - Mid):Dot(Up)
					if S >= 0 then A0, A1 = math.min(A0, Y), math.max(A1, Y) else B0, B1 = math.min(B0, Y), math.max(B1, Y) end
				end
				Dir = (A1 - A0) <= (B1 - B0) and Long or -Long
			end
			local Side = Dir:Cross(Up).Unit
			Dir = Dir.Unit
			Up = Side:Cross(Dir).Unit
			local L0, L1, U0, U1, S0, S1 = math.huge, -math.huge, math.huge, -math.huge, math.huge, -math.huge
			for _, P in ipairs(Pts) do
				local R = P - Mid
				local A, B, C = R:Dot(Dir), R:Dot(Up), R:Dot(Side)
				L0, L1, U0, U1, S0, S1 = math.min(L0, A), math.max(L1, A), math.min(U0, B), math.max(U1, B), math.min(S0, C), math.max(S1, C)
			end
			local Center = Mid + Dir * ((L0 + L1) / 2) + Up * ((U0 + U1) / 2) + Side * ((S0 + S1) / 2)
			local Len = math.max(L1 - L0, U1 - U0, 0.5)
			local Half = math.tan(math.rad(Cam.FieldOfView / 2))
			local Dist = Len * 0.47 / Half
			Cam.CFrame = CFrame.fromMatrix(Center, Dir, Up) * CFrame.Angles(0, math.rad(-22), 0) * CFrame.Angles(math.rad(-10), 0, 0) * CFrame.Angles(0, 0, math.rad(-35)) * CFrame.new(0, 0, Dist)
			self.Center, self.Size = Center, Len
		end
		O:Place()
		O.LastDrag = 0
		local function Shown()
			local G = VP
			while G and G:IsA("GuiObject") do
				if not G.Visible then return false end
				G = G.Parent
			end
			return true
		end
		return O
	end
	local Previews = {}
	local function Hermite(P0, P1, T0, T1, S)
		local S2, S3 = S * S, S * S * S
		return P0 * (2 * S3 - 3 * S2 + 1) + T0 * (S3 - 2 * S2 + S) + P1 * (-2 * S3 + 3 * S2) + T1 * (S3 - S2)
	end
	local function BeamPreview(VP, Active, World, Cam)
		if not World then
			World = Instance.new("WorldModel")
			World.Parent = VP
			Cam = Instance.new("Camera")
			Cam.FieldOfView = 40
			Cam.Parent = VP
			VP.CurrentCamera = Cam
		end
		local Pv = { VP = VP, World = World, Cam = Cam, Active = Active, Parts = {}, Shape = {}, Shown = 0 }
		Previews[#Previews + 1] = Pv
		return Pv
	end
	local function HidePreview(Pv)
		for I = 1, Pv.Shown do Pv.Parts[I].Transparency = 1 end
		Pv.Shown = 0
	end
	local function DrawPreview(Pv, C, T)
		local Cycle = C.DrawIn + C.Life + C.Fade + 0.6
		local Grow, K = Envelope(C, T % Cycle)
		local Seed = C.Animate and math.floor(T / 0.05) or math.floor(T / Cycle)
		local A, B = v3(-5.5, 0, 0), v3(5.5, 0, 0)
		local Layers, Dist, Dir = Paths(A, B, C, T, Random.new(Seed))
		local Idx, Budget = 0, 520
		for _, L in ipairs(Layers) do
			local P, Ups = L.P, L.Ups
			if L.Sm then
				local Tg = Tangents(P, L.Cl)
				local Q = {}
				for I = 1, #P - 1 do
					for S = 0, 2 do Q[#Q + 1] = Hermite(P[I], P[I + 1], Tg[I], Tg[I + 1], S / 3) end
				end
				Q[#Q + 1] = P[#P]
				P = Q
			end
			for I = 1, #P - 1 do
				if Idx >= Budget then break end
				local P0, P1 = P[I], P[I + 1]
				local D = P1 - P0
				local Len = D.Magnitude
				if Len > 0.01 then
					Idx = Idx + 1
					local Part = Pv.Parts[Idx]
					if not Part then
						Part = Instance.new("Part")
						Part.Anchored, Part.CanCollide, Part.CastShadow = true, false, false
						Part.Material = Enum.Material.Neon
						Part.Parent = Pv.World
						Pv.Parts[Idx] = Part
					end
					local Flat = Ups ~= nil
					if Pv.Shape[Idx] ~= Flat then
						Pv.Shape[Idx] = Flat
						Part.Shape = Flat and Enum.PartType.Block or Enum.PartType.Cylinder
					end
					local Mid = (P0 + P1) * 0.5
					local Fr = math.clamp((Mid - A):Dot(Dir) / Dist, 0, 1)
					local V, Wm = SegFx(C, Fr, Grow, K)
					local Wd = math.max((L.W + (L.WE - L.W) * Fr) * Wm, 0.01)
					if Flat then
						Part.Size = v3(Len, Wd, 0.02)
						Part.CFrame = Orient(Mid, D, Ups[I])
					else
						Part.Size = v3(Len, Wd, Wd)
						Part.CFrame = CFrame.lookAt(Mid, P1, math.abs(D.Y) > Len * 0.99 and v3(1, 0, 0) or v3(0, 1, 0)) * CFrame.Angles(0, math.rad(90), 0)
					end
					Part.Color = BeamColor(L, Fr, T)
					Part.Transparency = 1 - (1 - L.A) * V
				end
			end
		end
		for I = Idx + 1, Pv.Shown do Pv.Parts[I].Transparency = 1 end
		Pv.Shown = Idx
	end
	local PvAcc = 0
	On(RunService.RenderStepped, function(Dt)
		PvAcc = PvAcc + Dt
		if PvAcc < 1 / 30 then return end
		PvAcc = 0
		if not Hub.Sel then return end
		local T = os.clock()
		for _, Pv in ipairs(Previews) do
			if Pv.VP.Parent and Pv.Active() then
				local Sz = Pv.VP.AbsoluteSize
				if Sz ~= Pv.LastSize and Sz.X > 10 and Sz.Y > 10 then
					Pv.LastSize = Sz
					local Aspect = Sz.X / Sz.Y
					local HalfV = math.tan(math.rad(Pv.Cam.FieldOfView / 2))
					local Need = math.max(6.6 / (HalfV * Aspect), 2.2 / HalfV)
					local Yaw = math.rad(22)
					Pv.Cam.CFrame = CFrame.lookAt(v3(math.sin(Yaw) * Need, Need * 0.22, math.cos(Yaw) * Need), v3(0, 0, 0))
				end
				pcall(DrawPreview, Pv, Hub.Peek or Get(Hub.Sel), T)
			elseif Pv.Shown > 0 then
				HidePreview(Pv)
			end
		end
	end)
	local function Resample(D, N)
		if type(D) ~= "table" or #D < 2 then return Zeros(N) end
		if #D == N then return D end
		local Out = {}
		for I = 1, N do
			local P = (I - 1) / (N - 1) * (#D - 1) + 1
			local J = math.floor(P)
			local A, B = D[J] or 0, D[math.min(J + 1, #D)] or 0
			Out[I] = A + (B - A) * (P - J)
		end
		return Out
	end
	local function Normalise(Raw, N)
		if #Raw < 2 then return {} end
		local MinX, MaxX = math.huge, -math.huge
		for _, P in ipairs(Raw) do MinX = math.min(MinX, P[1]); MaxX = math.max(MaxX, P[1]) end
		local Span = math.max(MaxX - MinX, 1e-3)
		local Pts = {}
		for _, P in ipairs(Raw) do Pts[#Pts + 1] = { (P[1] - MinX) / Span, math.clamp(P[2], -1, 1) } end
		local Len, Acc = 0, { 0 }
		for I = 2, #Pts do
			Len = Len + math.sqrt((Pts[I][1] - Pts[I - 1][1]) ^ 2 + (Pts[I][2] - Pts[I - 1][2]) ^ 2)
			Acc[I] = Len
		end
		if Len < 1e-3 then return Pts end
		local Out, J = {}, 2
		for K2 = 0, N - 1 do
			local D = K2 / (N - 1) * Len
			while J < #Pts and Acc[J] < D do J = J + 1 end
			local A, B = Pts[J - 1], Pts[J]
			local Sg = math.max(Acc[J] - Acc[J - 1], 1e-6)
			local F2 = math.clamp((D - Acc[J - 1]) / Sg, 0, 1)
			Out[#Out + 1] = { A[1] + (B[1] - A[1]) * F2, A[2] + (B[2] - A[2]) * F2 }
		end
		return Out
	end
	local SHAPES = {
		heart = function(T) local A = T * math.pi * 2; return { math.sin(A) ^ 3 * 0.5 + 0.5, (13 * math.cos(A) - 5 * math.cos(2 * A) - 2 * math.cos(3 * A) - math.cos(4 * A)) / 17 } end,
		spiral = function(T) local A = T * math.pi * 6; return { T + math.cos(A) * 0.12, math.sin(A) * 0.8 } end,
		infinity = function(T) local A = T * math.pi * 2; return { math.sin(A) * 0.5 + 0.5, math.sin(A * 2) * 0.8 } end,
		zigzag = function(T) local U = (T * 8) % 2; return { T, U < 1 and U * 2 - 1 or 3 - U * 2 } end,
		sine = function(T) return { T, math.sin(T * math.pi * 2) * 0.9 } end,
		loops = function(T) local A = T * math.pi * 8; return { T + math.sin(A) * 0.05, math.cos(A) * 0.7 } end,
	}
	local function ShapePoints(Name)
		local Raw = {}
		if Name == "star" then
			for K2 = 0, 10 do
				local A2 = K2 / 10 * math.pi * 2 - math.pi / 2
				local R = (K2 % 2 == 0) and 1 or 0.42
				Raw[#Raw + 1] = { math.cos(A2) * R * 0.5 + 0.5, math.sin(A2) * R }
			end
		else
			for K2 = 0, 80 do Raw[#Raw + 1] = SHAPES[Name](K2 / 80) end
		end
		return Normalise(Raw, 48)
	end
	local function Canvas(Parent, GetLayer, OnShape)
		local N = DRAW_N
		local SEGS = 64
		local Root = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = Parent })
		local Bar = New("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, ClipsDescendants = true, Parent = Root })
		New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = Bar })
		local Area = New("TextButton", { Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 1, -30), ClipsDescendants = true, BackgroundTransparency = 0, Parent = Root })
		Paint(Area, "BackgroundColor3", "Element")
		Corner(6, Area)
		Stroke(Area)
		for _, Y in ipairs({ 0.25, 0.5, 0.75 }) do
			local G = New("Frame", { Position = UDim2.new(0, 0, Y, 0), Size = UDim2.new(1, 0, 0, 1), BackgroundTransparency = Y == 0.5 and 0.2 or 0.7, Parent = Area })
			Paint(G, "BackgroundColor3", "Stroke")
		end
		local Arrow = New("TextLabel", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 4), Size = UDim2.fromOffset(160, 12), Text = "muzzle  ->  target", TextSize = 10, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 4, Parent = Area })
		Paint(Arrow, "TextColor3", "TextDim")
		local Hint = New("TextLabel", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 8, 1, -6), Size = UDim2.new(1, -16, 0, 12), TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 4, Parent = Area })
		Paint(Hint, "TextColor3", "TextDim")
		local Mode = "pen"
		local Lines = {}
		for I = 1, SEGS do Lines[I] = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Visible = false, ZIndex = 3, Parent = Area }) end
		local Obj = {}
		local Live
		local function Seg(I, X0, Y0, X1, Y1, Col, Thick)
			local Fr = Lines[I]
			local Dx, Dy = X1 - X0, Y1 - Y0
			Fr.Visible = true
			Fr.Position = UDim2.fromOffset((X0 + X1) / 2, (Y0 + Y1) / 2)
			Fr.Size = UDim2.fromOffset(math.sqrt(Dx * Dx + Dy * Dy) + Thick * 0.6, Thick)
			Fr.Rotation = math.deg(math.atan2(Dy, Dx))
			Fr.BackgroundColor3 = Col
		end
		function Obj.Redraw()
			local L = GetLayer()
			local Sz = Area.AbsoluteSize
			for I = 1, SEGS do Lines[I].Visible = false end
			if not L or Sz.X < 10 then Hint.Text = "pick a layer first"; return end
			local W2, H2 = Sz.X, Sz.Y
			local function Px(P) return 8 + P[1] * (W2 - 16), (0.5 - P[2] * 0.42) * H2 end
			local Col = L.A == Color3.new(0, 0, 0) and Theme.Text or L.A
			if Mode == "pen" then
				local Pts = Live or (L.Type == "Sketch" and L.Sketch) or {}
				local Step = math.max(1, math.ceil((#Pts - 1) / SEGS))
				local K2 = 0
				for I = 1, #Pts - 1, Step do
					K2 = K2 + 1
					if K2 > SEGS then break end
					local X0, Y0 = Px(Pts[I])
					local X1, Y1 = Px(Pts[math.min(I + Step, #Pts)])
					Seg(K2, X0, Y0, X1, Y1, Col, 3)
				end
				Hint.Text = #Pts < 2 and "PEN: hold the mouse and draw a line. left = muzzle, right = target. loops and curls work."
					or "PEN: draw again to replace it  /  right-click to clear  /  frequency = how often it repeats"
			else
				L.Draw = Resample(L.Draw, N)
				for I = 1, math.min(N - 1, SEGS) do
					local X0, Y0 = 8 + (I - 1) / (N - 1) * (W2 - 16), (0.5 - L.Draw[I] * 0.42) * H2
					local X1, Y1 = 8 + I / (N - 1) * (W2 - 16), (0.5 - L.Draw[I + 1] * 0.42) * H2
					Seg(I, X0, Y0, X1, Y1, Col, 3)
				end
				Hint.Text = "WAVE: sweep left to right to set the height at each point  /  right-click to clear"
			end
		end
		local function Commit(L, Pts, NewType)
			L.Sketch = Pts
			if L.Type ~= NewType then
				L.Type = NewType
				if OnShape then OnShape(true) end
			elseif OnShape then
				OnShape(false)
			end
			Obj.Redraw()
		end
		Area.MouseButton1Down:Connect(function()
			local L = GetLayer()
			if not L then return end
			local P0, Sz = Area.AbsolutePosition, Area.AbsoluteSize
			local function At()
				local M = Library.MousePos()
				return { math.clamp((M.X - P0.X - 8) / math.max(Sz.X - 16, 1), 0, 1), math.clamp((0.5 - (M.Y - P0.Y) / Sz.Y) / 0.42, -1, 1) }
			end
			if Mode == "pen" then
				local Raw = { At() }
				Live = Raw
				Library._Drag = function()
					local P = At()
					local Lst = Raw[#Raw]
					if math.abs(P[1] - Lst[1]) + math.abs(P[2] - Lst[2]) > 0.008 then Raw[#Raw + 1] = P; Obj.Redraw() end
				end
				Library._DragEnd = function()
					Live = nil
					if #Raw >= 3 then Commit(L, Normalise(Raw, 48), "Sketch") else Obj.Redraw() end
				end
			else
				L.Draw = Resample(L.Draw, N)
				local LastI, LastV
				local function Upd()
					local P = At()
					local I = math.clamp(math.floor(P[1] * (N - 1) + 0.5) + 1, 1, N)
					local V = P[2]
					if LastI and LastI ~= I then
						local Sg = I > LastI and 1 or -1
						for J = LastI, I, Sg do L.Draw[J] = LastV + (V - LastV) * ((J - LastI) / (I - LastI)) end
					else
						L.Draw[I] = V
					end
					LastI, LastV = I, V
					Obj.Redraw()
				end
				Upd()
				Library._Drag = Upd
				Library._DragEnd = function()
					if L.Type ~= "Drawn" then
						L.Type = "Drawn"
						if OnShape then OnShape(true) end
					elseif OnShape then
						OnShape(false)
					end
				end
			end
		end)
		Area.MouseButton2Click:Connect(function()
			local L = GetLayer()
			if not L then return end
			if Mode == "pen" then L.Sketch = {} else L.Draw = Zeros(N) end
			Obj.Redraw()
			if OnShape then OnShape(false) end
		end)
		local Order = 0
		local function Btn(Text, Fn, Wd)
			Order = Order + 1
			local B = New("TextButton", { Size = UDim2.fromOffset(Wd or 50, 24), Text = Text, TextSize = 11, LayoutOrder = Order, BackgroundTransparency = 0, Parent = Bar })
			Paint(B, "BackgroundColor3", "Element")
			Corner(4, B)
			Stroke(B)
			B.MouseEnter:Connect(function() B.BackgroundColor3 = Theme.Hover end)
			B.MouseLeave:Connect(function() B.BackgroundColor3 = Theme.Element end)
			B.MouseButton1Click:Connect(function() Fn(B) end)
			return B
		end
		local ModeBtn = Btn("mode: pen", function(B) Mode = Mode == "pen" and "wave" or "pen"; B.Text = "mode: " .. Mode; Obj.Redraw() end, 80)
		for _, Name in ipairs({ "heart", "star", "spiral", "infinity", "loops", "zigzag", "sine" }) do
			Btn(Name, function()
				local L = GetLayer()
				if not L then return end
				Mode = "pen"
				ModeBtn.Text = "mode: pen"
				Commit(L, ShapePoints(Name), "Sketch")
			end)
		end
		Btn("smooth", function()
			local L = GetLayer()
			if not L then return end
			if Mode == "pen" and #(L.Sketch or {}) > 2 then
				local Sk, Out = L.Sketch, {}
				for I = 1, #Sk do
					local A, B, C3 = Sk[I - 1] or Sk[I], Sk[I], Sk[I + 1] or Sk[I]
					Out[I] = { (A[1] + B[1] * 2 + C3[1]) / 4, (A[2] + B[2] * 2 + C3[2]) / 4 }
				end
				Commit(L, Out, "Sketch")
			elseif Mode == "wave" then
				local D, Out = Resample(L.Draw, N), {}
				for I = 1, N do Out[I] = ((D[I - 1] or D[I]) + D[I] * 2 + (D[I + 1] or D[I])) / 4 end
				L.Draw = Out
				Obj.Redraw()
			end
		end, 56)
		Btn("flip", function()
			local L = GetLayer()
			if not L then return end
			if Mode == "pen" then
				local Out = {}
				for I, P in ipairs(L.Sketch or {}) do Out[I] = { P[1], -P[2] } end
				Commit(L, Out, "Sketch")
			else
				local D = Resample(L.Draw, N)
				for I = 1, N do D[I] = -D[I] end
				L.Draw = D
				Obj.Redraw()
			end
		end, 44)
		Area:GetPropertyChangedSignal("AbsoluteSize"):Connect(Obj.Redraw)
		task.defer(Obj.Redraw)
		return Obj
	end
	local Build = {}
	local LOOKS = {
		{ Name = "Inferno", Skin = "Inferno", A = rgb(255, 110, 30), B = rgb(255, 220, 120), Part = "Flames", Beam = "Inferno", Trail = true },
		{ Name = "Galaxy", Skin = "Galaxy", A = rgb(130, 80, 255), B = rgb(80, 180, 255), Part = "Galaxy", Beam = "Void" },
		{ Name = "Matrix", Skin = "Matrix", A = rgb(60, 255, 120), B = rgb(200, 255, 210), Part = "Electric", Beam = "Pulse" },
		{ Name = "Gold Glory", Skin = "GoldGlory", A = rgb(255, 200, 70), B = rgb(255, 245, 190), Part = "Glitter", Beam = "Solar", Trail = true },
		{ Name = "Red Death", Skin = "RedDeath", A = rgb(220, 20, 40), B = rgb(255, 120, 120), Part = "Embers", Beam = "Crimson" },
		{ Name = "Frost", A = rgb(140, 220, 255), B = rgb(235, 250, 255), Part = "Frost", Beam = "Frostbite", Mat = "Ice" },
		{ Name = "Void", A = rgb(120, 50, 220), B = rgb(20, 0, 40), Part = "Void", Beam = "Void", Mat = "ForceField" },
		{ Name = "Phantom", A = rgb(230, 240, 255), B = rgb(150, 170, 220), Part = "Mist", Beam = "Phantom", Mat = "ForceField" },
		{ Name = "Electric", A = rgb(90, 170, 255), B = rgb(220, 240, 255), Part = "Arcs", Beam = "Tesla" },
		{ Name = "Sakura", A = rgb(255, 150, 200), B = rgb(255, 230, 240), Part = "Petals", Beam = "Helix" },
	}
	local function ApplyLook(Wp, C, L)
		local Tex = L.Skin and BASE_SKINS[L.Skin]
		local HasTex = type(Tex) == "table" and Tex[Wp] ~= nil
		if C.Model ~= "Base model" and C.Model ~= "Custom mesh" then C.Model = "Default" end
		C.BaseSkin = HasTex and L.Skin or "Plain"
		C.TexOnGame = true
		C.OvOn = (not HasTex) or L.Mat ~= nil
		C.Material = L.Mat or "Original"
		C.CMode = HasTex and "Solid" or "Gradient"
		C.C1, C.C2, C.CSpeed = L.A, L.B, 0.6
		C.Strip = L.Mat ~= nil
		C.PartOn, C.PartStyle, C.PartC1, C.PartC2, C.PartTrail = true, L.Part, L.A, L.B, L.Trail == true
		C.Beam, C.Layers, C.Preset, C.B1, C.B2 = true, PRESETS[L.Beam](), L.Beam, L.A, L.B
	end
	local LookAll = false
	function Build.Looks(Col, Wp, C)
		local S = Sec(Col, "Complete looks")
		S:Label("one click: skin or colour + gun particles + matching beam.")
		local Rows = math.ceil(#LOOKS / 2)
		local Holder = S:Custom(Rows * 36)
		local Grid = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = Holder })
		New("UIGridLayout", { CellSize = UDim2.new(0.5, -4, 0, 32), CellPadding = UDim2.fromOffset(6, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = Grid })
		for I, L in ipairs(LOOKS) do
			local B = New("TextButton", { Text = "", LayoutOrder = I, BackgroundTransparency = 0, ClipsDescendants = true, Parent = Grid })
			B.BackgroundColor3 = Theme.Element
			Corner(8, B)
			Stroke(B)
			local Sw = New("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = Color3.new(1, 1, 1), Parent = B })
			Corner(7, Sw)
			New("UIGradient", { Rotation = 45, Color = ColorSequence.new(L.A, L.B), Parent = Sw })
			New("TextLabel", { Position = UDim2.fromOffset(32, 0), Size = UDim2.new(1, -36, 1, 0), Text = L.Name, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Theme.Text, Parent = B })
			local Glow = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = L.A, BackgroundTransparency = 1, Parent = B })
			Corner(8, Glow)
			New("UIGradient", { Transparency = NumberSequence.new(0.6, 1), Parent = Glow })
			B.MouseEnter:Connect(function() Library.Tween(Glow, 0.15, { BackgroundTransparency = 0.75 }) end)
			B.MouseLeave:Connect(function() Library.Tween(Glow, 0.15, { BackgroundTransparency = 1 }) end)
			B.MouseButton1Click:Connect(function()
				if LookAll then
					for _, X in ipairs(ScanWeapons()) do ApplyLook(X, Get(X), L) end
				else
					ApplyLook(Wp, C, L)
				end
				Changed()
				RebuildPanels()
			end)
		end
		S:Toggle({ Name = "Apply to every gun", Flag = F("lookall"), Default = LookAll, Save = false, Callback = function(V) LookAll = V end })
	end
	function Build.Model(Col, Wp, C)
		local S = Sec(Col, "Skin")
		local Opts = {}
		for _, N in ipairs(ModelsFor(Wp)) do if N ~= "Base model" and N ~= "Custom mesh" then Opts[#Opts + 1] = N end end
		local Cur = (C.Model == "Base model" or C.Model == "Custom mesh") and "Default" or C.Model
		S:Dropdown({ Name = "Game skin", Flag = F("model"), Options = Opts, Default = Cur,
			Callback = function(V) C.Model = V; Changed(); RebuildPanels() end })
		if C.Model == "Base model" or C.Model == "Custom mesh" then
			S:Label("a custom model is on for this gun (custom models tab). picking a game skin here turns it off.")
		end
		S:Toggle({ Name = "Remove game texture", Flag = F("stripdef"), Default = C.StripDefault, Callback = function(V) C.StripDefault = V; Changed() end })
		S:Button({ Name = "Rescan game skins", Callback = function()
			local N = BuildIndex()
			ScanWorldGuns()
			Library:Notify(("found %d skin models in the game"):format(N or 0), 3)
			RebuildPanels()
		end })
		S:Label("default = the gun as the game ships it. game skin = whatever skin you own.")
		local T = Sec(Col, "Texture skin")
		T:Dropdown({ Name = "Texture", Flag = F("bskin"), Options = BASE_SKIN_NAMES, Default = C.BaseSkin, Callback = function(V) C.BaseSkin = V; Changed() end })
		T:Textbox({ Name = "Custom texture id", Flag = F("btex"), Default = C.BaseTex, Placeholder = "used when texture = custom", Callback = function(V)
			C.BaseTex = V
			if C.BaseSkin == "Custom" then Changed() end
		end })
		T:Toggle({ Name = "Paint it on the game's gun", Flag = F("texgame"), Default = C.TexOnGame, Callback = function(V) C.TexOnGame = V; Changed() end })
		T:Label("galaxy / inferno / matrix / red death / gold glory work on the revolver and double barrel. custom works on any gun.")
		local A = Sec(Col, "Reset")
		A:Button({ Name = "Reset gun", Callback = function()
			local Old = Cfg[Wp]
			local Nw = Defaults()
			for K2, V in pairs(Old) do if not SKIN_KEYS[K2] then Nw[K2] = V end end
			Cfg[Wp] = Nw; Changed(); RebuildPanels()
		end }):Button({ Name = "All guns default", Callback = function()
			for _, X in ipairs(ScanWeapons()) do Get(X).Model = "Default" end
			Changed(); RebuildPanels()
		end })
	end
	function Build.Custom(Col, Wp, C)
		local S = Sec(Col, "Custom model")
		local Has = BaseMeshes.Has(Wp)
		local Modes = { "Off" }
		if Has then Modes[#Modes + 1] = "Your .obj model" end
		Modes[#Modes + 1] = "Mesh id"
		local Cur = C.Model == "Base model" and "Your .obj model" or (C.Model == "Custom mesh" and "Mesh id" or "Off")
		S:Dropdown({ Name = "Use", Flag = F("cmode2"), Options = Modes, Default = Cur, Callback = function(V)
			C.Model = V == "Your .obj model" and "Base model" or (V == "Mesh id" and "Custom mesh" or "Default")
			Changed(); RebuildPanels()
		end })
		S:Label(Has and "your .obj model replaces the gun you hold. it lines itself up with the gun, use fit below if it's off."
			or "no .obj model for this gun yet (only revolver and double barrel). you can still use any mesh id.")
		if C.Model == "Custom mesh" then
			local Cm = Sec(Col, "Mesh id")
			Cm:Textbox({ Name = "Mesh id", Flag = F("mesh"), Default = C.MeshId, Placeholder = "rbxassetid or number", Callback = function(V) C.MeshId = V; Changed() end })
			Cm:Textbox({ Name = "Texture id", Flag = F("tex"), Default = C.TextureId, Placeholder = "optional", Callback = function(V) C.TextureId = V; Changed() end })
		end
		if C.Model == "Base model" or C.Model == "Custom mesh" then
			local B = Sec(Col, "Look")
			if C.Model == "Base model" then
				B:Dropdown({ Name = "Texture", Flag = F("bskin2"), Options = BASE_SKIN_NAMES, Default = C.BaseSkin, Callback = function(V) C.BaseSkin = V; Changed() end })
			end
			B:Colorpicker({ Name = "Colour (when no texture)", Flag = F("bcol"), Default = C.BaseColor, Callback = function(V) C.BaseColor = V; Changed() end })
			B:Colorpicker({ Name = "Texture tint", Flag = F("tint"), Default = C.Tint, Callback = function(V) C.Tint = V; Changed() end })
			B:Dropdown({ Name = "Material", Flag = F("bmat"), Options = BASE_MATS, Default = C.BaseMat, Callback = function(V) C.BaseMat = V; Changed() end })
			local M = Sec(Col, "Fit")
			M:Slider({ Name = "Scale", Flag = F("scale"), Min = 0.1, Max = 3, Decimals = 2, Default = C.MeshScale, Callback = function(V) C.MeshScale = V; Changed() end })
			M:Dropdown({ Name = "Turn", Flag = F("rot"), Options = { "0", "90", "180", "270" }, Default = tostring(C.MeshRot),
				Callback = function(V) C.MeshRot = tonumber(V) or 0; Changed() end })
			M:Slider({ Name = "Move X", Flag = F("ox"), Min = -2, Max = 2, Decimals = 2, Default = C.OffX, Callback = function(V) C.OffX = V; Changed() end })
			M:Slider({ Name = "Move Y", Flag = F("oy"), Min = -2, Max = 2, Decimals = 2, Default = C.OffY, Callback = function(V) C.OffY = V; Changed() end })
			M:Slider({ Name = "Move Z", Flag = F("oz"), Min = -2, Max = 2, Decimals = 2, Default = C.OffZ, Callback = function(V) C.OffZ = V; Changed() end })
		end
	end
	function Build.Particles(Col, Wp, C)
		local S = Sec(Col, "Skin particles")
		S:Toggle({ Name = "Particles on gun", Flag = F("pon"), Default = C.PartOn, Callback = function(V) C.PartOn = V; Changed(false) end })
		S:Dropdown({ Name = "Style", Flag = F("pst"), Options = AURA_STYLES, Default = C.PartStyle, Callback = function(V) C.PartStyle = V; Changed(false) end })
		S:Colorpicker({ Name = "Colour", Flag = F("pc1"), Default = C.PartC1, Callback = function(V) C.PartC1 = V; Changed(false) end })
		S:Colorpicker({ Name = "Fade colour", Flag = F("pc2"), Default = C.PartC2, Callback = function(V) C.PartC2 = V; Changed(false) end })
		S:Slider({ Name = "Amount", Flag = F("prate"), Min = 1, Max = 60, Default = C.PartRate, Callback = function(V) C.PartRate = V; Changed(false) end })
		S:Slider({ Name = "Size", Flag = F("psize"), Min = 0.05, Max = 1.5, Decimals = 2, Default = C.PartSize, Callback = function(V) C.PartSize = V; Changed(false) end })
		S:Slider({ Name = "Speed", Flag = F("pspd"), Min = 0, Max = 4, Decimals = 1, Default = C.PartSpeed, Callback = function(V) C.PartSpeed = V; Changed(false) end })
		S:Toggle({ Name = "Gun trail", Flag = F("ptrail"), Default = C.PartTrail, Callback = function(V) C.PartTrail = V; Changed(false) end })
		S:Toggle({ Name = "Glow light", Flag = F("plight"), Default = C.PartLight, Callback = function(V) C.PartLight = V; Changed(false) end })
		S:Slider({ Name = "Light range", Flag = F("prange"), Min = 2, Max = 20, Default = C.PartRange, Callback = function(V) C.PartRange = V; Changed(false) end })
		S:Button({ Name = "Copy particles to all guns", Callback = function()
			for _, X in ipairs(ScanWeapons()) do
				if X ~= Wp then
					local T = Get(X)
					for _, K in ipairs({ "PartOn", "PartTrail", "PartStyle", "PartC1", "PartC2", "PartRate", "PartSize", "PartSpeed", "PartLight", "PartRange" }) do T[K] = C[K] end
				end
			end
			Changed(false)
		end })
		S:Label("previews can't show particles, you'll see them on the gun in game.")
	end
	function Build.Override(Col, Wp, C)
		local S = Sec(Col, "Override")
		S:Toggle({ Name = "Enable override", Flag = F("ov"), Default = C.OvOn, Callback = function(V) C.OvOn = V; Changed() end })
		S:Dropdown({ Name = "Material", Flag = F("mat"), Options = MATERIALS, Default = C.Material, Callback = function(V) C.Material = V; Changed() end })
		S:Toggle({ Name = "Strip skin textures", Flag = F("strip"), Default = C.Strip, Callback = function(V) C.Strip = V; Changed() end })
		S:Slider({ Name = "Reflectance", Flag = F("refl"), Min = 0, Max = 1, Decimals = 2, Default = C.Reflect, Callback = function(V) C.Reflect = V; Changed() end })
		local Cl = Sec(Col, "Colour")
		Cl:Dropdown({ Name = "Mode", Flag = F("cmode"), Options = COLOR_MODES, Default = C.CMode, Callback = function(V) C.CMode = V; Changed(false) end })
		Cl:Colorpicker({ Name = "Primary", Flag = F("c1"), Default = C.C1, Callback = function(V) C.C1 = V; Changed() end })
		Cl:Colorpicker({ Name = "Secondary", Flag = F("c2"), Default = C.C2, Callback = function(V) C.C2 = V; Changed(false) end })
		Cl:Slider({ Name = "Colour speed", Flag = F("cspd"), Min = 0.1, Max = 5, Decimals = 1, Default = C.CSpeed, Callback = function(V) C.CSpeed = V end })
		Cl:Toggle({ Name = "Preserve outlines", Flag = F("outl"), Default = C.Outlines, Callback = function(V) C.Outlines = V; Changed() end })
		Cl:Toggle({ Name = "Tint model details", Flag = F("det"), Default = C.Details, Callback = function(V) C.Details = V; Changed() end })
		local T = Sec(Col, "Custom texture")
		T:Textbox({ Name = "Texture id", Flag = F("ctex"), Default = C.Texture, Placeholder = "applies on top of any skin", Callback = function(V) C.Texture = V; Changed() end })
		T:Button({ Name = "Use on every skin", Callback = function()
			for _, X in ipairs(ScanWeapons()) do local Y = Get(X); Y.Texture = C.Texture; Y.OvOn = Y.OvOn or C.Texture ~= "" end
			Changed()
		end }):Button({ Name = "Copy override to all", Callback = function()
			for _, X in ipairs(ScanWeapons()) do
				if X ~= Wp then
					local Y = Get(X)
					for _, K in ipairs({ "OvOn", "Material", "C1", "C2", "CMode", "CSpeed", "Reflect", "Texture", "Strip", "Outlines", "Details" }) do Y[K] = C[K] end
				end
			end
			Changed(false)
		end })
	end
	local function Sl(S, Name, T, Key, Min, Max, Dec, Suffix)
		S:Slider({ Name = Name, Flag = F(Key), Min = Min, Max = Max, Decimals = Dec or 0, Suffix = Suffix, Default = T[Key], Callback = function(V) T[Key] = V end })
	end
	local function Tg(S, Name, T, Key, After)
		S:Toggle({ Name = Name, Flag = F(Key), Default = T[Key] ~= false, Callback = function(V) T[Key] = V; for _, Fn in ipairs(Hub.Status) do pcall(Fn) end; if After then After() end end })
	end
	local function Custom(C) if C.Preset ~= "Custom" then C.Preset = "Custom" end end
	local function IsGlow(L) return L.Type == "Glow" or ((L.Type == "Line") and (L.Alpha or 0) >= 0.6) end
	local PresetTint = {}
	local function TintOf(Name)
		if not PresetTint[Name] then
			local Ok, Ls = pcall(PRESETS[Name])
			local Col = Color3.fromRGB(120, 120, 130)
			if Ok and Ls then for _, L in ipairs(Ls) do if not IsGlow(L) then Col = L.A; break end end end
			PresetTint[Name] = Col
		end
		return PresetTint[Name]
	end
	function Build.Quick(Col, Wp, C)
		local S = Sec(Col, "Quick setup")
		Tg(S, "Custom beam on", C, "Beam")
		S:Label("1. pick a look  (hover one to preview it live)")
		local Names = table.clone(PRESET_NAMES)
		local Rows = math.ceil(#Names / 3)
		local Holder = S:Custom(Rows * 28)
		local Grid = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = Holder })
		New("UIGridLayout", { CellSize = UDim2.new(1 / 3, -4, 0, 24), CellPadding = UDim2.fromOffset(4, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = Grid })
		for I, Name in ipairs(Names) do
			local Tint = TintOf(Name)
			local Sel = C.Preset == Name
			local B = New("TextButton", { Text = Name:lower(), TextSize = 11, LayoutOrder = I, BackgroundTransparency = 0, Parent = Grid })
			B.BackgroundColor3 = Sel and Theme.Hover or Theme.Element
			B.TextColor3 = Sel and Theme.Text or Theme.TextDim
			B.MouseEnter:Connect(function() if not Sel then B.BackgroundColor3 = Theme.Hover; B.TextColor3 = Theme.Text end end)
			B.MouseLeave:Connect(function() if not Sel then B.BackgroundColor3 = Theme.Element; B.TextColor3 = Theme.TextDim end end)
			B.MouseEnter:Connect(function()
				local Peek = table.clone(C)
				Peek.Layers = PRESETS[Name]()
				Peek.Preset = Name
				Hub.Peek = Peek
			end)
			B.MouseLeave:Connect(function() if Hub.Peek and Hub.Peek.Preset == Name then Hub.Peek = nil end end)
			Corner(4, B)
			local St = Instance.new("UIStroke")
			St.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			St.Color = Sel and Theme.Accent or Theme.Stroke
			St.Thickness = 1
			St.Transparency = 0
			St.Parent = B
			B.MouseButton1Click:Connect(function()
				Hub.Peek = nil
				C.Layers = PRESETS[Name]()
				C.Preset = Name
				Hub.Layer = 1
				RebuildPanels()
			end)
		end
		S:Label("2. colours")
		local Main, Glow
		for _, L in ipairs(C.Layers) do
			if IsGlow(L) then Glow = Glow or L.A else Main = Main or L.A end
		end
		S:Colorpicker({ Name = "Main colour", Flag = F("qmain"), Default = Main or W, Callback = function(V)
			for _, L in ipairs(C.Layers) do if not IsGlow(L) then L.A = V; if L.Mode ~= "Solid" then L.B = V:Lerp(Color3.new(1, 1, 1), 0.5) end end end
			Custom(C)
		end })
		S:Colorpicker({ Name = "Glow colour", Flag = F("qglow"), Default = Glow or Main or W, Callback = function(V)
			for _, L in ipairs(C.Layers) do if IsGlow(L) then L.A = V end end
			C.B1 = V
			Custom(C)
		end })
		S:Label("3. feel")
		Sl(S, "Thickness", C, "Thick", 0.2, 4, 2)
		Sl(S, "Brightness", C, "Bright", 0.5, 8, 1)
		S:Slider({ Name = "Spin speed", Flag = F("qspin"), Min = 0, Max = 5, Decimals = 1, Default = math.abs((C.Layers[1] or {}).Spin or 1), Callback = function(V)
			for _, L in ipairs(C.Layers) do L.Spin = (L.Spin or 1) < 0 and -V or V end
		end })
		S:Toggle({ Name = "Spinning / moving", Flag = F("qspins"), Default = (C.Layers[1] or {}).Spins ~= false, Callback = function(V)
			for _, L in ipairs(C.Layers) do L.Spins = V end
		end })
		Sl(S, "How long it stays", C, "Life", 0, 1, 2, "s")
		Sl(S, "Fade out", C, "Fade", 0.02, 2, 2, "s")
	end
	function Build.BeamMain(Col, Wp, C)
		local S = Sec(Col, "Beam settings")
		Tg(S, "Hide the game's own tracer", C, "HideGame")
		S:Dropdown({ Name = "Fires on", Flag = F("detect"), Options = { "Instant", "Ammo only", "Click only" }, Default = Opt.Detect, Callback = function(V) Opt.Detect = V end })
		local Names2 = table.clone(PRESET_NAMES)
		for N in pairs(UserPresets) do Names2[#Names2 + 1] = "* " .. N end
		S:Dropdown({ Name = "Load preset / your saved ones", Flag = F("preset"), Options = Names2, Default = C.Preset, Callback = function(V)
			if V == C.Preset then return end
			local U = V:match("^%* (.+)$")
			C.Layers = U and Deep(UserPresets[U]) or PRESETS[V]()
			C.Preset = V
			Hub.Layer = 1
			RebuildPanels()
		end })
		local SaveName = S:Textbox({ Name = "Save as preset", Flag = F("savename"), Placeholder = "name, then press save", Save = false })
		S:Button({ Name = "Save preset", Callback = function()
			local N = SaveName:Get():match("^%s*(.-)%s*$")
			if N == "" then return Library:Notify("type a name first", 3) end
			UserPresets[N] = Deep(C.Layers)
			C.Preset = "* " .. N
			Library:Notify("saved preset " .. N .. " (save your config to keep it)", 4)
			RebuildPanels()
		end }):Button({ Name = "Copy to all guns", Callback = function()
			for _, X in ipairs(ScanWeapons()) do
				if X ~= Wp then
					local Y = Get(X)
					for K, V in pairs(C) do if not SKIN_KEYS[K] then Y[K] = Deep(V) end end
				end
			end
			Library:Notify("beam copied to every gun", 3)
		end })
	end
	function Build.Layers(Col, Wp, C)
		local Layers = C.Layers
		if Hub.Layer > #Layers then Hub.Layer = math.max(#Layers, 1) end
		local St = Sec(Col, "Layers")
		local Rows = {}
		for I, L in ipairs(Layers) do Rows[I] = ("%d  %s%s"):format(I, L.Type:lower(), L.On == false and "  (off)" or "") end
		St:List({ Name = "Layers", Flag = F("layers"), Height = math.clamp(#Layers * 22 + 8, 52, 180), Options = Rows, Default = Rows[Hub.Layer], Save = false,
			Callback = function(V)
				local I = table.find(Rows, V)
				if I and I ~= Hub.Layer then Hub.Layer = I; RebuildPanels() end
			end })
		St:Dropdown({ Name = "New layer shape", Flag = F("addtype"), Options = LAYER_TYPES, Default = Hub.AddType, Callback = function(V) Hub.AddType = V end })
		local Ly = Layers[Hub.Layer]
		St:Button({ Name = "Add", Callback = function()
			if #Layers >= 8 then return Library:Notify("8 layers max", 3) end
			table.insert(Layers, Hub.Layer + 1, NewLayer(Hub.AddType, { A = Ly and Ly.A or nil, B = Ly and Ly.B or nil }))
			Hub.Layer = math.min(Hub.Layer + 1, #Layers)
			Custom(C); RebuildPanels()
		end }):Button({ Name = "Duplicate", Callback = function()
			if not Ly or #Layers >= 8 then return end
			table.insert(Layers, Hub.Layer + 1, Deep(Ly))
			Hub.Layer = Hub.Layer + 1
			Custom(C); RebuildPanels()
		end }):Button({ Name = "Delete", Callback = function()
			if #Layers <= 1 then return Library:Notify("a beam needs at least one layer", 3) end
			table.remove(Layers, Hub.Layer)
			Hub.Layer = math.max(1, Hub.Layer - 1)
			Custom(C); RebuildPanels()
		end })
		St:Button({ Name = "Move up", Callback = function()
			if Hub.Layer > 1 then Layers[Hub.Layer], Layers[Hub.Layer - 1] = Layers[Hub.Layer - 1], Layers[Hub.Layer]; Hub.Layer = Hub.Layer - 1; Custom(C); RebuildPanels() end
		end }):Button({ Name = "Move down", Callback = function()
			if Hub.Layer < #Layers then Layers[Hub.Layer], Layers[Hub.Layer + 1] = Layers[Hub.Layer + 1], Layers[Hub.Layer]; Hub.Layer = Hub.Layer + 1; Custom(C); RebuildPanels() end
		end })
		St:Label("glow re-traces the layer above it, branches fork off it. a strong beam = thin bright core (whiten) + soft wide glow + one moving detail layer.")
	end
	function Build.Layer(Col, Wp, C)
		local Ly = C.Layers[Hub.Layer]
		if not Ly then return end
		local E = Sec(Col, ("Layer %d  /  %s"):format(Hub.Layer, Ly.Type:lower()))
		Tg(E, "Layer on", Ly, "On")
		E:Dropdown({ Name = "Shape", Flag = F("ltype"), Options = LAYER_TYPES, Default = Ly.Type, Callback = function(V)
			if V ~= Ly.Type then Ly.Type = V; Custom(C); RebuildPanels() end
		end })
		Tg(E, "Spins / moves", Ly, "Spins")
		Sl(E, "Spin speed", Ly, "Spin", -5, 5, 1)
		E:Dropdown({ Name = "Colour mode", Flag = F("lmode"), Options = COLOR_MODES, Default = Ly.Mode, Callback = function(V) Ly.Mode = V; Custom(C) end })
		E:Colorpicker({ Name = "Colour", Flag = F("la"), Default = Ly.A, Callback = function(V) Ly.A = V; Custom(C) end })
		E:Colorpicker({ Name = "Second colour", Flag = F("lb"), Default = Ly.B, Callback = function(V) Ly.B = V; Custom(C) end })
		Sl(E, "Colour speed", Ly, "Speed", 0.1, 5, 1)
		Sl(E, "Whiten core", Ly, "Whiten", 0, 1, 2)
		Sl(E, "Glow (0 = solid / dark)", Ly, "Emit", 0, 1, 2)
		Sl(E, "Width (start)", Ly, "Width", 0.005, 1.5, 3)
		Sl(E, "Width (end)", Ly, "WEnd", 0, 1.5, 3)
		Sl(E, "Transparency", Ly, "Alpha", 0, 0.98, 2)
		if Ly.Type ~= "Line" and Ly.Type ~= "Glow" then
			Sl(E, "Amplitude", Ly, "Amp", 0, 4, 2)
			Sl(E, "Frequency", Ly, "Freq", 0.1, 5, 2)
		end
		if Ly.Type ~= "Line" and Ly.Type ~= "Glow" and Ly.Type ~= "Branches" then Sl(E, "Rotation", Ly, "Phase", 0, 360, 0, "deg") end
		if Ly.Type == "Lightning" or Ly.Type == "Helix" or Ly.Type == "Spiral" or Ly.Type == "Wave" or Ly.Type == "Zigzag" or Ly.Type == "Noise" or Ly.Type == "Drawn" then
			Sl(E, "Copies", Ly, "Copies", 1, 4)
		end
		if Ly.Type ~= "Glow" and not SMOOTH[Ly.Type] then Sl(E, "Jitter", Ly, "Jitter", 0, 3, 2) end
	end
	function Build.Whole(Col, Wp, C)
		local G = Sec(Col, "Whole beam")
		Sl(G, "Thickness", C, "Thick", 0.2, 4, 2)
		Sl(G, "Brightness", C, "Bright", 0.5, 8, 1)
		G:Dropdown({ Name = "Texture", Flag = F("tex"), Options = BEAM_TEXTURES, Default = C.Tex, Callback = function(V) C.Tex = V end })
		Sl(G, "Texture scroll", C, "TexSpeed", 0, 10, 1)
		Tg(G, "Animate while alive", C, "Animate")
		local Fd = Sec(Col, "Timing")
		Fd:Dropdown({ Name = "Fade style", Flag = F("fadestyle"), Options = FADE_STYLES, Default = C.FadeStyle, Callback = function(V) C.FadeStyle = V end })
		Sl(Fd, "Draw-in", C, "DrawIn", 0, 0.3, 2, "s")
		Sl(Fd, "Hold", C, "Life", 0, 1, 2, "s")
		Sl(Fd, "Fade out", C, "Fade", 0.02, 2, 2, "s")
		Sl(Fd, "Tail fade", C, "Tail", 0, 0.8, 2)
		local Fx = Sec(Col, "Core / particles")
		Fx:Colorpicker({ Name = "Effect colour", Flag = F("b1"), Default = C.B1, Callback = function(V) C.B1 = V end })
		Fx:Colorpicker({ Name = "Effect colour 2", Flag = F("b2"), Default = C.B2, Callback = function(V) C.B2 = V end })
		Tg(Fx, "Solid 3d core", C, "Core")
		Tg(Fx, "Beam particles", C, "Particles")
		Fx:Dropdown({ Name = "Particle style", Flag = F("pstb"), Options = PARTICLE_STYLES, Default = C.PStyle, Callback = function(V) C.PStyle = V end })
		Sl(Fx, "Particle amount", C, "PInt", 1, 10)
		Tg(Fx, "Muzzle sparks", C, "Muzzle")
	end
	local function TestFire(C)
		local Cam = workspace.CurrentCamera
		local To, Hit = AimPoint()
		local From = Gun.Tool and MuzzleOf(Gun.Tool, To) or (Cam.CFrame.Position + Cam.CFrame.LookVector * 4 + Cam.CFrame.RightVector * 1.5 - v3(0, 1, 0))
		Shoot(From, To, Hit and Hit.Normal, C)
	end
	function Build.Test(Col, Wp, C)
		local Ac = Sec(Col, "Test")
		Ac:Button({ Name = "Test fire", Accent = true, Callback = function() TestFire(C) end }):Button({ Name = "Reset beam", Callback = function()
			for K, V in pairs(Defaults()) do if not SKIN_KEYS[K] then C[K] = V end end
			Hub.Layer = 1
			RebuildPanels()
		end })
		local GB = Sec(Col, "Game beam (unlock)")
		GB:Dropdown({ Name = "Equipped game beam", Flag = F("gbeam"), Options = GameBeams(), Default = "None", Callback = function(V)
			local Ok, Err = SetGameBeam(V)
			if not Ok then Library:Notify(tostring(Err), 4) end
		end })
	end
	local function Refill(Col, Fn)
		Hub.Peek = nil
		Library:ClosePopup()
		local Was = Col.CanvasPosition
		for _, C in ipairs(Col:GetChildren()) do if C:IsA("Frame") then C:Destroy() end end
		if Hub.Sel then pcall(Fn, Get(Hub.Sel)) end
		task.defer(function() Col.CanvasPosition = Was end)
	end
	local function WeaponList(Parent, OnPick, Small)
		local SearchF = New("Frame", { Size = UDim2.new(1, 0, 0, 30), Parent = Parent })
		Paint(SearchF, "BackgroundColor3", "Element")
		Corner(6, SearchF)
		Stroke(SearchF)
		local Search = New("TextBox", { Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 1, 0), PlaceholderText = "find weapon...", TextXAlignment = Enum.TextXAlignment.Left, Parent = SearchF })
		Search.PlaceholderColor3 = Theme.TextDim
		local ListF = New("ScrollingFrame", {
			Position = UDim2.fromOffset(0, 38), Size = UDim2.new(1, 0, 1, -38), BackgroundTransparency = 1, CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Accent, Parent = Parent,
		})
		New("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder, Parent = ListF })
		Pad(ListF, 0, 4, 0, 0)
		local Rows = {}
		local L = {}
		local function Thumb(Wp, R)
			do return end
			if R.Th then R.Th:Destroy() end
			local Th = New("ViewportFrame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(52, 38), BackgroundTransparency = 1, Ambient = rgb(170, 170, 180), Parent = R.Frame })
			R.Th = Th
			if Small then Th.Visible = false return end
			task.spawn(function()
				local M = CloneFor(Wp)
				if not M or not Th.Parent then return end
				M.Parent = Th
				pcall(ApplyHolder, M, Wp, true)
				local Cam = Instance.new("Camera")
				Cam.FieldOfView = 35
				Cam.Parent = Th
				Th.CurrentCamera = Cam
				local CF, Size = M:GetBoundingBox()
				local Rd = math.max(Size.X, Size.Y, Size.Z)
				Cam.CFrame = CFrame.new(CF.Position + v3(Rd * 0.9, Rd * 0.35, Rd * 0.9) * 1.25, CF.Position)
			end)
		end
		function L.Paint()
			for Wp, R in pairs(Rows) do
				local A = Wp == Hub.Sel
				R.Bar.Visible = A
				R.Frame.BackgroundColor3 = A and Theme.Hover or Theme.Element
			end
		end
		function L.Status() for Wp, R in pairs(Rows) do R.Status.Text = Status(Wp) end end
		function L.Thumb(Wp) if Rows[Wp] then Thumb(Wp, Rows[Wp]) end end
		function L.Refresh()
			local Q = Search.Text:lower()
			for I, Wp in ipairs(ScanWeapons()) do
				local R = Rows[Wp]
				if not R then
					local Fr = New("TextButton", { Size = UDim2.new(1, 0, 0, 36), LayoutOrder = I, BackgroundTransparency = 0, Parent = ListF })
					Fr.BackgroundColor3 = Theme.Element
					Corner(6, Fr)
					Stroke(Fr)
					local B = New("Frame", { Size = UDim2.new(0, 3, 1, -12), Position = UDim2.fromOffset(0, 6), Visible = false, Parent = Fr })
					Paint(B, "BackgroundColor3", "Accent")
					New("TextLabel", { Position = UDim2.fromOffset(12, 3), Size = UDim2.new(1, -16, 0, 16), Text = Wp, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = Fr })
					local S = New("TextLabel", { Position = UDim2.fromOffset(12, 18), Size = UDim2.new(1, -16, 0, 14), Text = Status(Wp), TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = Fr })
					S.TextColor3 = Theme.TextDim
					Fr.MouseButton1Click:Connect(function() OnPick(Wp) end)
					R = { Frame = Fr, Bar = B, Status = S }
					Rows[Wp] = R
					Thumb(Wp, R)
				end
				R.Frame.LayoutOrder = I
				R.Frame.Visible = Q == "" or Wp:lower():find(Q, 1, true) ~= nil
			end
			L.Paint()
		end
		Search:GetPropertyChangedSignal("Text"):Connect(L.Refresh)
		return L
	end
	local Lists = {}
	RefreshAll = function()
		for _, L in ipairs(Lists) do pcall(L.Refresh) end
		for _, Fn in ipairs(Hub.Models) do pcall(Fn) end
	end
	local function Select(Wp)
		Hub.Sel = Wp
		Hub.Layer = 1
		for _, L in ipairs(Lists) do L.Paint() end
		RebuildPanels()
		for _, Fn in ipairs(Hub.Models) do pcall(Fn) end
	end
	Hub.Status[#Hub.Status + 1] = function() for _, L in ipairs(Lists) do L.Status() end end
	local ThumbPending = false
	Hub.Models[#Hub.Models + 1] = function()
		if ThumbPending or not Hub.Sel then return end
		ThumbPending = true
		task.delay(0.4, function()
			ThumbPending = false
			for _, L in ipairs(Lists) do L.Thumb(Hub.Sel) end
		end)
	end
	Studio = Library:FloatWindow({ Title = "aceso  /  editor", Width = 1120, Height = 660 })
	do
	local function StudioOn(Page) return Studio.Main.Visible and Studio.Current == Page end
	local GunPages = {}
	local function GunPage(Name, BuildA, BuildB)
		local Pg = Studio:Page(Name)
		local Left = New("Frame", { Size = UDim2.new(0, 190, 1, 0), BackgroundTransparency = 1, Parent = Pg })
		Lists[#Lists + 1] = WeaponList(Left, Select, true)
		local View = OrbitView(Pg, UDim2.fromOffset(200, 0), UDim2.new(1, -200 - 580, 1, -22))
		local Info = New("TextLabel", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 200, 1, 0), Size = UDim2.new(1, -780, 0, 16), TextSize = 11, TextTruncate = Enum.TextTruncate.AtEnd, TextXAlignment = Enum.TextXAlignment.Left, Parent = Pg })
		Paint(Info, "TextColor3", "TextDim")
		local ColA = Library.Column(Pg, UDim2.new(1, -570, 0, 0), UDim2.new(0, 282, 1, 0))
		local ColB = Library.Column(Pg, UDim2.new(1, -282, 0, 0), UDim2.new(0, 282, 1, 0))
		local G = { Name = Name }
		local Model
		function G.Panels()
			Refill(ColA, function(C) BuildA(ColA, Hub.Sel, C) end)
			Refill(ColB, function(C) BuildB(ColB, Hub.Sel, C) end)
		end
		function G.Model()
			if Model then Model:Destroy(); Model = nil end
			if not Hub.Sel then return end
			local M = CloneFor(Hub.Sel)
			if not M then Info.Text = "pick up this gun once (or stand near the shop) so it can be previewed"; return end
			M.Parent = View.World
			pcall(ApplyHolder, M, Hub.Sel, true)
			View:Frame(M)
			Info.Text = Hub.Sel .. "  /  " .. Status(Hub.Sel)
			Model = M
		end
		GunPages[Name] = G
		return G
	end
	GunPage("Skin", function(Col, Wp, C) Build.Looks(Col, Wp, C); Build.Model(Col, Wp, C) end, function(Col, Wp, C) Build.Particles(Col, Wp, C); Build.Override(Col, Wp, C) end)
	GunPage("Custom model", function(Col, Wp, C) Build.Custom(Col, Wp, C) end, function(Col, Wp, C) Build.Particles(Col, Wp, C) end)
	local BeamPage = Studio:Page("Beam")
	local BLeft = Library.Column(BeamPage, UDim2.fromOffset(0, 0), UDim2.new(0, 282, 1, 0))
	local BRight = Library.Column(BeamPage, UDim2.new(1, -290, 0, 0), UDim2.new(0, 290, 1, 0))
	local BMid = New("Frame", { Position = UDim2.fromOffset(292, 0), Size = UDim2.new(1, -592, 1, 0), BackgroundTransparency = 1, Parent = BeamPage })
	local BVP = New("ViewportFrame", { Size = UDim2.fromOffset(240, 200), Ambient = rgb(10, 10, 14), BackgroundTransparency = 0, Parent = BMid })
	BVP.BackgroundColor3 = rgb(8, 8, 10)
	Corner(8, BVP)
	Stroke(BVP)
	local BTitle = New("TextLabel", { Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -20, 0, 14), TextSize = 11, TextTruncate = Enum.TextTruncate.AtEnd, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3, Parent = BVP })
	Paint(BTitle, "TextColor3", "TextDim")
	local FireBtn = New("TextButton", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -8, 1, -8), Size = UDim2.fromOffset(90, 24), Text = "test fire", TextSize = 12, ZIndex = 3, BackgroundTransparency = 0, Parent = BVP })
	Paint(FireBtn, "BackgroundColor3", "Element")
	Paint(FireBtn, "TextColor3", "Accent")
	Corner(4, FireBtn)
	Stroke(FireBtn)
	FireBtn.MouseButton1Click:Connect(function() if Hub.Sel then TestFire(Get(Hub.Sel)) end end)
	BeamPreview(BVP, function() return StudioOn("Beam") end)
	local PadTitle = New("TextLabel", { Position = UDim2.new(0, 0, 0.5, 2), Size = UDim2.new(1, 0, 0, 16), Text = "DRAW YOUR BEAM  (edits the selected layer)", FontFace = Library.Fonts.Bold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = BMid })
	Paint(PadTitle, "TextColor3", "Text")
	local CanvasHolder = New("Frame", { Position = UDim2.new(0, 0, 0.5, 22), Size = UDim2.new(1, 0, 0.5, -22), BackgroundTransparency = 1, Parent = BMid })
	local Cv = Canvas(CanvasHolder, function()
		local C = Hub.Sel and Get(Hub.Sel)
		return C and C.Layers[Hub.Layer]
	end, function(TypeChanged)
		local C = Hub.Sel and Get(Hub.Sel)
		if C then Custom(C) end
		if TypeChanged then RebuildPanels() end
	end)
	local function StudioPanels()
		if not Studio.Main.Visible then return end
		Library:DropFlags("__sk_")
		local G = GunPages[Studio.Current]
		if G then
			G.Panels()
		else
			Refill(BLeft, function(C) Build.Quick(BLeft, Hub.Sel, C); Build.BeamMain(BLeft, Hub.Sel, C); Build.Test(BLeft, Hub.Sel, C) end)
			Refill(BRight, function(C) Build.Layers(BRight, Hub.Sel, C); Build.Layer(BRight, Hub.Sel, C); Build.Whole(BRight, Hub.Sel, C) end)
			Cv.Redraw()
			BTitle.Text = (Hub.Sel or "") .. "  /  " .. (Hub.Sel and tostring(Get(Hub.Sel).Preset):lower() or "") .. "  /  live preview"
		end
	end
	Hub.Panels[#Hub.Panels + 1] = StudioPanels
	local function StudioModel()
		if not Studio.Main.Visible then return end
		local G = GunPages[Studio.Current]
		if G then G.Model() end
	end
	Hub.Models[#Hub.Models + 1] = StudioModel
	Studio:OnVisible(function(V)
		if not V then return end
		for _, L in ipairs(Lists) do L.Refresh() end
		StudioPanels()
		StudioModel()
	end)
	end
	function BuildTab(Tab)
		local Canvas0 = Tab:Canvas()
		local Bar = New("Frame", { Size = UDim2.new(1, -150, 0, 34), Parent = Canvas0 })
		Paint(Bar, "BackgroundColor3", "Section")
		Corner(8, Bar)
		Stroke(Bar)
		Pad(Bar, 3)
		New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 3), Parent = Bar })
		local OpenBtn = New("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(142, 34), Text = "open editor  >", BackgroundTransparency = 0, Parent = Canvas0 })
		Paint(OpenBtn, "BackgroundColor3", "Section")
		Paint(OpenBtn, "TextColor3", "Accent")
		Corner(8, OpenBtn)
		Stroke(OpenBtn)
		OpenBtn.MouseButton1Click:Connect(function()
			Studio:Select(Hub.Mode == "Beams" and "Beam" or (Hub.Mode == "Custom models" and "Custom model" or "Skin"))
			Studio:SetVisible(true)
		end)
		local Body = New("Frame", { Position = UDim2.fromOffset(0, 42), Size = UDim2.new(1, 0, 1, -42), BackgroundTransparency = 1, Parent = Canvas0 })
		local Left = New("Frame", { Size = UDim2.new(0, 186, 1, 0), BackgroundTransparency = 1, Parent = Body })
		Lists[#Lists + 1] = WeaponList(Left, Select, false)
		local Mid = New("Frame", { Position = UDim2.fromOffset(196, 0), Size = UDim2.new(1, -196 - 266, 1, 0), BackgroundTransparency = 1, Parent = Body })
		local MTitle = New("TextLabel", { Size = UDim2.new(1, 0, 0, 16), FontFace = Library.Fonts.Bold, TextXAlignment = Enum.TextXAlignment.Left, Parent = Mid })
		local MSub = New("TextLabel", { Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 14), Text = "@" .. lp.Name .. "  /  local cosmetic effects", TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = Mid })
		Paint(MSub, "TextColor3", "TextDim")
		local View = OrbitView(Mid, UDim2.fromOffset(0, 40), UDim2.new(1, 0, 1, -64))
		local Info = New("TextLabel", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 16), TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = Mid })
		Paint(Info, "TextColor3", "TextDim")
		local Right = Library.Column(Body, UDim2.new(1, -258, 0, 0), UDim2.new(0, 258, 1, 0))
		local function TabOn() return Library.Window and Library.Window.Main.Visible and Tab.Container.Visible end
		local TabPv = BeamPreview(View.VP, function() return Hub.Mode == "Beams" and TabOn() end, View.World, View.Cam)
		local PreviewModel
		local function TabModel()
			if PreviewModel then PreviewModel:Destroy(); PreviewModel = nil end
			if not Hub.Sel then return end
			MTitle.Text = Hub.Sel .. "  /  " .. Hub.Mode:lower()
			if Hub.Mode == "Beams" then
				View.Center, View.Size = v3(), 8
				TabPv.LastSize = nil
				View.Hint.Visible = false
				Info.Text = "live preview  /  " .. tostring(Get(Hub.Sel).Preset):lower() .. "  /  open the editor for more"
				return
			end
			View.Hint.Visible = true
			local M = CloneFor(Hub.Sel)
			if not M then Info.Text = "pick up this gun once (or stand near the shop) so it can be previewed"; return end
			M.Parent = View.World
			pcall(ApplyHolder, M, Hub.Sel, true)
			View:Frame(M)
			local N = 0
			for _, D in ipairs(M:GetDescendants()) do if D:IsA("BasePart") and D.Transparency < 1 then N = N + 1 end end
			Info.Text = N .. " parts  /  " .. Status(Hub.Sel)
			PreviewModel = M
		end
		Hub.Models[#Hub.Models + 1] = function() if TabOn() then TabModel() end end
		local function TabPanel()
			if not TabOn() then return end
			Library:DropFlags("__sk_")
			Refill(Right, function(C)
				if Hub.Mode == "Gun skins" then Build.Looks(Right, Hub.Sel, C); Build.Model(Right, Hub.Sel, C); Build.Particles(Right, Hub.Sel, C)
				elseif Hub.Mode == "Custom models" then Build.Custom(Right, Hub.Sel, C)
				elseif Hub.Mode == "Overrides" then Build.Override(Right, Hub.Sel, C)
				else Build.Quick(Right, Hub.Sel, C); Build.BeamMain(Right, Hub.Sel, C); Build.Test(Right, Hub.Sel, C) end
			end)
		end
		Hub.Panels[#Hub.Panels + 1] = TabPanel
		local ModeBtns = {}
		local function SetMode(M)
			Hub.Mode = M
			for N, X in pairs(ModeBtns) do
				local A = N == M
				X.Btn.BackgroundTransparency = A and 0 or 1
				X.Btn.TextColor3 = A and Theme.Text or Theme.TextDim
				X.Under.Visible = A
			end
			for _, L in ipairs(Lists) do L.Status() end
			TabPanel()
			TabModel()
		end
		for _, M in ipairs({ "Gun skins", "Custom models", "Overrides", "Beams" }) do
			local B = New("TextButton", { Size = UDim2.new(1 / 4, -3, 1, 0), Text = M, TextTruncate = Enum.TextTruncate.AtEnd, BackgroundTransparency = 1, Parent = Bar })
			Paint(B, "BackgroundColor3", "Element")
			Corner(6, B)
			local Under = New("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.new(1, -20, 0, 2), Visible = false, Parent = B })
			Paint(Under, "BackgroundColor3", "Accent")
			B.MouseButton1Click:Connect(function() SetMode(M) end)
			ModeBtns[M] = { Btn = B, Under = Under }
		end
		Tab.Container:GetPropertyChangedSignal("Visible"):Connect(function() if TabOn() then TabPanel(); TabModel() end end)
		if Library.Window then
			Library.Window.Main:GetPropertyChangedSignal("Visible"):Connect(function() if TabOn() then TabPanel(); TabModel() end end)
		end
		for _, L in ipairs(Lists) do L.Refresh() end
		local First = ScanWeapons()[1]
		Hub.Sel = First
		for _, L in ipairs(Lists) do L.Paint() end
		SetMode("Gun skins")
		local Pending = false
		local function Later()
			if Pending then return end
			Pending = true
			task.delay(1, function()
				Pending = false
				if Canvas0.Parent and RememberMine() then
					for _, L in ipairs(Lists) do L.Refresh() end
					for _, Fn in ipairs(Hub.Models) do pcall(Fn) end
				end
			end)
		end
		local function WatchPack(B) On(B.ChildAdded, Later) end
		local BP = lp:FindFirstChildOfClass("Backpack")
		if BP then WatchPack(BP) end
		On(lp.ChildAdded, function(C) if C:IsA("Backpack") then WatchPack(C); Later() end end)
	end
	end)()
	local function Unload()
		ClearAll()
		pcall(SetGameBeam, "None")
		for _, C in ipairs(Conns) do pcall(function() C:Disconnect() end) end
		table.clear(Conns)
		FX:Destroy()
	end
	Library.ExtraSave = function() return { skins = Pack(), detect = Opt.Detect, presets = Enc(UserPresets) } end
	Library.ExtraLoad = function(D)
		if D.skins then Unpack(D.skins) end
		if type(D.presets) == "table" then
			for N, L in pairs(Dec(D.presets)) do UserPresets[N] = CleanLayers(L) end
		end
		if D.detect == "Instant" or D.detect == "Ammo only" or D.detect == "Click only" then Opt.Detect = D.detect end
		RebuildPanels()
	end
	return {
		Ready = function() return ScanDone and not Indexing end,
		SetAll = function(K, V)
			for _, Wp in ipairs(ScanWeapons()) do Get(Wp)[K] = V end
			ApplyAll()
			if RebuildPanels then pcall(RebuildPanels) end
		end,
		CountOn = function(K)
			local N, T = 0, 0
			for _, Wp in ipairs(ScanWeapons()) do T = T + 1; if Get(Wp)[K] then N = N + 1 end end
			return N, T
		end,
		Refresh = function() if RefreshAll then RefreshAll() end end,
		Build = BuildTab, ApplyAll = ApplyAll, ClearAll = ClearAll, Unload = Unload, MuzzleOf = MuzzleOf, CurrentGun = CurrentGun, FX = FX,
		Studio = Studio, OpenStudio = function(Page) Studio:Select(Page or "Skin"); Studio:SetVisible(true) end,
	}
end)()
Library:LoaderStep("loading character", 0.4)
local Char = (function()
	local lp = LocalPlayer
	local rgb = Color3.fromRGB
	local Conns = {}
	local function On(Sig, Fn) local C = Sig:Connect(Fn); Conns[#Conns + 1] = C; return C end
	local State = { Headless = false, Korblox = false, Chams = false, ChamFill = rgb(255, 132, 64), ChamOutline = rgb(255, 255, 255),
		ChamFillT = 0.55, ChamOutT = 0, ChamGun = true, FF = false, FFColor = rgb(120, 200, 255) }
	local HeadSaved = {}
	local function ApplyHeadless()
		local C = lp.Character
		local Head = C and C:FindFirstChild("Head")
		if not Head then return end
		if State.Headless then
			local function Hide(O, Prop)
				if HeadSaved[O] == nil then HeadSaved[O] = { Prop, O[Prop] } end
				O[Prop] = 1
			end
			Hide(Head, "Transparency")
			for _, D in ipairs(Head:GetChildren()) do
				if D:IsA("Decal") then Hide(D, "Transparency") end
			end
		else
			for O, S in pairs(HeadSaved) do pcall(function() if O.Parent then O[S[1]] = S[2] end end) end
			table.clear(HeadSaved)
		end
	end
	local Kor = { Parts = {}, Hidden = {} }
	local function ClearKorblox()
		for _, P in ipairs(Kor.Parts) do pcall(function() P:Destroy() end) end
		table.clear(Kor.Parts)
		for P, T in pairs(Kor.Hidden) do pcall(function() if P.Parent then P.Transparency = T end end) end
		table.clear(Kor.Hidden)
	end
	local function ApplyKorblox()
		ClearKorblox()
		if not State.Korblox then return end
		local C = lp.Character
		local Hum = C and C:FindFirstChildOfClass("Humanoid")
		if not Hum then return end
		local R15 = Hum.RigType == Enum.HumanoidRigType.R15
		local Ok, Rig = pcall(function()
			local D = Instance.new("HumanoidDescription")
			D.RightLeg = 139607718
			return Players:CreateHumanoidModelFromDescription(D, Hum.RigType)
		end)
		local Names = R15 and { "RightUpperLeg", "RightLowerLeg", "RightFoot" } or { "Right Leg" }
		for _, N in ipairs(Names) do
			local Mine = C:FindFirstChild(N)
			if Mine and Mine:IsA("BasePart") then
				Kor.Hidden[Mine] = Mine.Transparency
				Mine.Transparency = 1
				local Src = R15 and Ok and Rig and Rig:FindFirstChild(N)
				if Src then
					local P = Src:Clone()
					for _, D in ipairs(P:GetChildren()) do
						if D:IsA("JointInstance") or D:IsA("Attachment") or D:IsA("WrapTarget") or D:IsA("WrapLayer") then D:Destroy() end
					end
					P.Name = "AcesoKorblox"
					P.Anchored, P.CanCollide, P.Massless, P.CanQuery, P.CanTouch = false, false, true, false, false
					P.Color = rgb(22, 22, 28)
					P.CFrame = Mine.CFrame
					local W = Instance.new("WeldConstraint")
					W.Part0, W.Part1 = Mine, P
					W.Parent = P
					P.Parent = C
					Kor.Parts[#Kor.Parts + 1] = P
				elseif not R15 then
					local M = Ok and Rig and (function()
						for _, D in ipairs(Rig:GetDescendants()) do
							if D:IsA("CharacterMesh") and D.BodyPart == Enum.BodyPart.RightLeg then return D end
						end
					end)()
					Mine.Transparency = Kor.Hidden[Mine]
					Kor.Hidden[Mine] = nil
					local CM = M and M:Clone() or Instance.new("CharacterMesh")
					CM.BodyPart = Enum.BodyPart.RightLeg
					if not M then CM.MeshId = 139607718 end
					CM.Name = "AcesoKorblox"
					CM.Parent = C
					Mine.Color = rgb(22, 22, 28)
					Kor.Parts[#Kor.Parts + 1] = CM
				end
			end
		end
		if Rig then Rig:Destroy() end
	end
	local KEEP = { Accessory = true, Hat = true, Shirt = true, Pants = true, ShirtGraphic = true, BodyColors = true, CharacterMesh = true }
	local Own
	local function Remember()
		if Own then return end
		local C = lp.Character
		if not C then return end
		Own = {}
		for _, X in ipairs(C:GetChildren()) do
			if KEEP[X.ClassName] and X.Name ~= "AcesoKorblox" then Own[#Own + 1] = X:Clone() end
		end
		local Head = C:FindFirstChild("Head")
		local Face = Head and Head:FindFirstChildOfClass("Decal")
		if Face then Own.Face = Face.Texture end
	end
	local function ClearLook(C)
		for _, X in ipairs(C:GetChildren()) do
			if KEEP[X.ClassName] and X.Name ~= "AcesoKorblox" then pcall(function() X:Destroy() end) end
		end
	end
	local function ApplyItems(Items, Face)
		local C = lp.Character
		if not C then return false, "no character" end
		local Hum = C:FindFirstChildOfClass("Humanoid")
		ClearLook(C)
		for _, X in ipairs(Items) do
			if X:IsA("Accessory") and Hum then
				local H = X:FindFirstChild("Handle")
				if H then H.CanCollide, H.Massless, H.CanQuery, H.CanTouch = false, true, false, false end
				pcall(function() Hum:AddAccessory(X) end)
				if not X.Parent then X.Parent = C end
			else
				X.Parent = C
			end
		end
		local Head = C:FindFirstChild("Head")
		local FaceDecal = Head and Head:FindFirstChildOfClass("Decal")
		if FaceDecal and Face then FaceDecal.Texture = Face end
		task.defer(ApplyHeadless)
		task.defer(ApplyKorblox)
		return true
	end
	local function CopyUser(Name)
		Name = tostring(Name or ""):match("^%s*(.-)%s*$")
		if Name == "" then return false, "type a username first" end
		Remember()
		local Ok, Id = pcall(function() return Players:GetUserIdFromNameAsync(Name) end)
		if not Ok or not Id then return false, "no user called " .. Name end
		local Ok2, Model = pcall(function() return Players:GetCharacterAppearanceAsync(Id) end)
		if not Ok2 or not Model then return false, "couldn't load that avatar" end
		local Items, Face = {}, nil
		for _, X in ipairs(Model:GetChildren()) do
			if KEEP[X.ClassName] then Items[#Items + 1] = X:Clone() end
			if X:IsA("Decal") and X.Name == "face" then Face = X.Texture end
		end
		Model:Destroy()
		if #Items == 0 then return false, "that avatar has nothing to copy" end
		return ApplyItems(Items, Face)
	end
	local function RestoreOwn()
		if not Own then return false, "nothing to restore" end
		local Items = {}
		for _, X in ipairs(Own) do Items[#Items + 1] = X:Clone() end
		return ApplyItems(Items, Own.Face)
	end
	local PACKS = {
		Default    = nil,
		Levitation = { 616006778, 616008087, 616013216, 616010382, 616008936, 616005863, 616003713 },
		Ninja      = { 656117400, 656118341, 656121766, 656118852, 656117878, 656115606, 656114359 },
		Zombie     = { 616158929, 616160636, 616168032, 616163682, 616161997, 616157476, 616156119 },
		Stylish    = { 616136790, 616138447, 616146177, 616140816, 616139451, 616134815, 616133594 },
		Robot      = { 616088211, 616089559, 616095330, 616091570, 616090535, 616087089, 616086039 },
		Cartoony   = { 742637544, 742638445, 742640026, 742638842, 742637942, 742637151, 742636889 },
		Superhero  = { 616111295, 616113536, 616122287, 616117076, 616115533, 616108001, 616104706 },
		Mage       = { 707742142, 707855907, 707897309, 707861613, 707853694, 707829716, 707826056 },
		Vampire    = { 1083445855, 1083450166, 1083473930, 1083462077, 1083455352, 1083443587, 1083439238 },
		Werewolf   = { 1083195517, 1083214717, 1083178339, 1083216690, 1083218792, 1083189019, 1083182000 },
		Toy        = { 782841498, 782845736, 782843345, 782842708, 782847020, 782846423, 782843869 },
		Elder      = { 845397899, 845400520, 845403856, 845386501, 845398858, 845396048, 845392038 },
		Astronaut  = { 891621366, 891633237, 891667138, 891636393, 891627522, 891617961, 891609353 },
		Pirate     = { 750781874, 750782770, 750785693, 750783738, 750782230, 750780242, 750779899 },
		Knight     = { 657595757, 657568135, 657552124, 657564596, 658409194, 657600338, 658360781 },
	}
	local PACK_NAMES = { "Default" }
	for N in pairs(PACKS) do if N ~= "Default" then PACK_NAMES[#PACK_NAMES + 1] = N end end
	table.sort(PACK_NAMES, function(A, B) if A == "Default" then return true elseif B == "Default" then return false end return A < B end)
	local SLOTS = { { "idle", { 1, 2 } }, { "walk", { 3 } }, { "run", { 4 } }, { "jump", { 5 } }, { "fall", { 6 } }, { "climb", { 7 } } }
	local Anim = { idle = "Default", walk = "Default", run = "Default", jump = "Default", fall = "Default", climb = "Default", speed = 1 }
	local AnimOrig = setmetatable({}, { __mode = "k" })
	local function ApplyAnims()
		local C = lp.Character
		local Animate = C and C:FindFirstChild("Animate")
		local Hum = C and C:FindFirstChildOfClass("Humanoid")
		if not Animate or not Hum then return false, "no Animate script on your character" end
		if Hum.RigType ~= Enum.HumanoidRigType.R15 then return false, "animation packs need an R15 character" end
		for _, S in ipairs(SLOTS) do
			local Folder = Animate:FindFirstChild(S[1])
			if Folder then
				local List = {}
				for _, A in ipairs(Folder:GetChildren()) do if A:IsA("Animation") then List[#List + 1] = A end end
				table.sort(List, function(A, B) return A.Name < B.Name end)
				local Pack = PACKS[Anim[S[1]]]
				for I, A in ipairs(List) do
					if AnimOrig[A] == nil then AnimOrig[A] = A.AnimationId end
					local Id = Pack and Pack[S[2][math.min(I, #S[2])]]
					A.AnimationId = Id and ("rbxassetid://" .. Id) or AnimOrig[A]
				end
			end
		end
		for _, T in ipairs(Hum:GetPlayingAnimationTracks()) do pcall(function() T:Stop(0) end) end
		pcall(function() Hum:ChangeState(Enum.HumanoidStateType.Landed) end)
		return true
	end
	local AnimT = 0
	On(RunService.Heartbeat, function()
		if Anim.speed == 1 then return end
		local Now = os.clock()
		if Now - AnimT < 0.1 then return end
		AnimT = Now
		local C = lp.Character
		local Hum = C and C:FindFirstChildOfClass("Humanoid")
		local An = Hum and Hum:FindFirstChildOfClass("Animator")
		if not An then return end
		for _, T in ipairs(An:GetPlayingAnimationTracks()) do
			if T.Speed ~= Anim.speed and T.Speed > 0 then pcall(function() T:AdjustSpeed(Anim.speed) end) end
		end
	end)
	local Cham
	local FFSaved = {}
	local function ApplyChams()
		if Cham then Cham:Destroy(); Cham = nil end
		local C = lp.Character
		if State.Chams and C then
			Cham = Instance.new("Highlight")
			Cham.Name = "AcesoSelfCham"
			Cham.FillColor, Cham.OutlineColor = State.ChamFill, State.ChamOutline
			Cham.FillTransparency, Cham.OutlineTransparency = State.ChamFillT, State.ChamOutT
			Cham.DepthMode = Enum.HighlightDepthMode.Occluded
			Cham.Adornee = C
			Cham.Parent = C
		end
		for P, S in pairs(FFSaved) do pcall(function() if P.Parent then P.Material, P.Color = S[1], S[2] end end) end
		table.clear(FFSaved)
		if State.FF and C then
			for _, P in ipairs(C:GetDescendants()) do
				if P:IsA("BasePart") and P.Name ~= "HumanoidRootPart" and P.Transparency < 1 then
					local InTool = P:FindFirstAncestorOfClass("Tool")
					if not InTool or State.ChamGun then
						FFSaved[P] = { P.Material, P.Color }
						P.Material, P.Color = Enum.Material.ForceField, State.FFColor
					end
				end
			end
		end
	end
	local ChamDirty = false
	On(RunService.Heartbeat, function()
		if ChamDirty then ChamDirty = false; ApplyChams() end
	end)
	local SP, FI, SM = "rbxasset://textures/particles/sparkles_main.dds", "rbxasset://textures/particles/fire_main.dds", "rbxasset://textures/particles/smoke_main.dds"
	local AURAS = {
		Galaxy  = { { SM, { 0.2, 0.6 }, { 1.4, 2.2 }, { 1.6, 2.6 }, 0.82, Vector3.new(0, 0.5, 0), 1, 0.4 }, { SP, { 0.2, 0.8 }, { 0.8, 1.6 }, { 0.5, 0 }, 0, Vector3.new(0, 0.8, 0), 1, 1 } },
		Angelic = { { SP, { 0.5, 1.5 }, { 1, 1.6 }, { 0.4, 0 }, 0, Vector3.new(0, 3, 0), 1, 1 }, { SM, { 0.3, 0.8 }, { 1, 1.6 }, { 1, 2 }, 0.85, Vector3.new(0, 2, 0), 1, 0.4 } },
		Void    = { { SM, { 0.3, 0.9 }, { 1.2, 2 }, { 1.4, 2.6 }, 0.3, Vector3.new(0, 1, 0), 0, 0.8, true }, { SP, { 0.2, 0.6 }, { 0.5, 1 }, { 0.4, 0 }, 0, Vector3.new(0, 1, 0), 1, 0.6 } },
		Flames  = { { FI, { 1, 2.5 }, { 0.4, 0.8 }, { 1.6, 0 }, 0.1, Vector3.new(0, 6, 0), 1, 1.4 }, { SM, { 0.5, 1 }, { 1, 1.6 }, { 1.2, 2.4 }, 0.8, Vector3.new(0, 3, 0), 0, 0.3, true } },
		Frost   = { { SM, { 0.1, 0.4 }, { 1.4, 2 }, { 1.4, 2.4 }, 0.8, Vector3.new(0, -0.4, 0), 0.6, 0.6 }, { SP, { 0.2, 0.6 }, { 0.8, 1.4 }, { 0.4, 0 }, 0, Vector3.new(0, -1, 0), 1, 1 } },
		Embers  = { { FI, { 0.5, 1.5 }, { 1, 1.8 }, { 0.4, 0 }, 0, Vector3.new(0, 4, 0), 1, 1 } },
		Glitter = { { SP, { 0.2, 1 }, { 0.6, 1.2 }, { 0.45, 0 }, 0, Vector3.new(0, 0.5, 0), 1, 1 } },
	}
	local AURA_NAMES = { "Galaxy", "Angelic", "Void", "Flames", "Frost", "Embers", "Glitter" }
	State.Aura, State.AuraStyle, State.AuraA, State.AuraB, State.AuraRate = false, "Galaxy", rgb(150, 100, 255), rgb(90, 200, 255), 16
	local function ApplyBodyAura()
		local C = lp.Character
		local Root = C and C:FindFirstChild("HumanoidRootPart")
		if not Root then return end
		for _, E in ipairs(Root:GetChildren()) do if E.Name == "AcesoBodyAura" then E:Destroy() end end
		if not State.Aura then return end
		local Q = Library.Quality or 1
		for _, L in ipairs(AURAS[State.AuraStyle] or AURAS.Galaxy) do
			local E = Instance.new("ParticleEmitter")
			E.Name = "AcesoBodyAura"
			E.Texture = L[1]
			E.Speed = NumberRange.new(L[2][1], L[2][2])
			E.Lifetime = NumberRange.new(L[3][1], L[3][2])
			E.Size = NumberSequence.new(L[4][1], L[4][2])
			E.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, L[5]), NumberSequenceKeypoint.new(1, 1) })
			E.Acceleration = L[6]
			E.LightEmission, E.LightInfluence = L[7], L[7] > 0.5 and 0 or 1
			local A, B = State.AuraA, State.AuraB
			if L[9] then A, B = A:Lerp(Color3.new(0, 0, 0), 0.7), B:Lerp(Color3.new(0, 0, 0), 0.8) end
			E.Color = ColorSequence.new(A, B)
			E.SpreadAngle = Vector2.new(180, 180)
			E.Rotation = NumberRange.new(0, 360)
			E.RotSpeed = NumberRange.new(-60, 60)
			E.Drag = 1
			E.Rate = State.AuraRate * L[8] * Q
			pcall(function()
				E.Shape = Enum.ParticleEmitterShape.Box
				E.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
			end)
			E.Parent = Root
		end
	end
	local function Refresh()
		ApplyHeadless()
		ApplyKorblox()
		if Anim.idle ~= "Default" or Anim.walk ~= "Default" or Anim.run ~= "Default" or Anim.jump ~= "Default" or Anim.fall ~= "Default" or Anim.climb ~= "Default" then ApplyAnims() end
		ApplyChams()
		ApplyBodyAura()
	end
	On(lp.CharacterAdded, function(C)
		Own = nil
		table.clear(HeadSaved)
		table.clear(Kor.Parts)
		table.clear(Kor.Hidden)
		table.clear(FFSaved)
		C:WaitForChild("Humanoid", 10)
		C:WaitForChild("Animate", 5)
		task.wait(0.5)
		Remember()
		Refresh()
		On(C.ChildAdded, function(X) if X:IsA("Tool") and State.FF then ChamDirty = true end end)
	end)
	if lp.Character then
		task.defer(Remember)
		On(lp.Character.ChildAdded, function(X) if X:IsA("Tool") and State.FF then ChamDirty = true end end)
	end
	local function Viewer(Parent, Title, Pos)
		local Box = Library.New("Frame", { Position = Pos, Size = UDim2.fromOffset(240, 200), BackgroundColor3 = Library.Theme.Element, ClipsDescendants = true, Parent = Parent })
		Library.Corner(10, Box)
		local G = Instance.new("UIGradient")
		G.Rotation = 90
		G.Color = ColorSequence.new(Color3.fromRGB(34, 34, 46), Color3.fromRGB(16, 16, 22))
		G.Parent = Box
		local VP = Library.New("ViewportFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Ambient = Color3.fromRGB(150, 150, 165), LightColor = Color3.new(1, 1, 1), LightDirection = Vector3.new(-0.6, -1, -0.8), Parent = Box })
		local Floor = Library.New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 1, -26), Size = UDim2.fromOffset(110, 14), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.6, Parent = Box })
		Library.Corner(7, Floor)
		local Lbl = Library.New("TextLabel", { Position = UDim2.fromOffset(12, 10), Size = UDim2.new(1, -24, 0, 14), Text = Title, FontFace = Library.Fonts.Bold, TextSize = 11, TextColor3 = Library.Theme.TextDim, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3, Parent = Box })
		local Name = Library.New("TextLabel", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -8), Size = UDim2.new(1, -24, 0, 14), Text = "", TextSize = 12, TextColor3 = Library.Theme.Text, TextTruncate = Enum.TextTruncate.AtEnd, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3, Parent = Box })
		local World = Instance.new("WorldModel")
		World.Parent = VP
		local Cam = Instance.new("Camera")
		Cam.FieldOfView = 30
		Cam.Parent = VP
		VP.CurrentCamera = Cam
		local V = { Model = nil, Base = nil, Name = Name }
		function V:Show(M, Label)
			if self.Model then self.Model:Destroy() end
			self.Model = nil
			Name.Text = Label or ""
			if not M then return end
			for _, D in ipairs(M:GetDescendants()) do
				if D:IsA("LuaSourceContainer") or D:IsA("Sound") or D:IsA("ForceField") or D:IsA("BillboardGui") then D:Destroy()
				elseif D:IsA("BasePart") then D.Anchored = true end
			end
			local Hum = M:FindFirstChildOfClass("Humanoid")
			if Hum then Hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
			pcall(function()
				local Root = M:FindFirstChild("LowerTorso") or M:FindFirstChild("Torso") or M:FindFirstChild("HumanoidRootPart")
				if not Root then return end
				Root.CFrame = CFrame.new(Root.Position)
				local Joints = {}
				for _, J in ipairs(M:GetDescendants()) do
					if J:IsA("JointInstance") and J.Part0 and J.Part1 then Joints[#Joints + 1] = J end
					if J:IsA("Animator") then J:Destroy() end
				end
				local Done = { [Root] = true }
				local Moved = true
				while Moved do
					Moved = false
					for _, J in ipairs(Joints) do
						if Done[J.Part0] and not Done[J.Part1] then
							J.Part1.CFrame = J.Part0.CFrame * J.C0 * J.C1:Inverse()
							Done[J.Part1] = true
							Moved = true
						end
					end
				end
			end)
			pcall(function()
				local R = M:FindFirstChild("LowerTorso") or M:FindFirstChild("Torso")
				if R then M.WorldPivot = CFrame.new(R.Position) end
			end)
			M.Parent = World
			local Ok = pcall(function() M:PivotTo(CFrame.new()) end)
			local CF, Sz = M:GetBoundingBox()
			self.Base = CF.Position
			local H = math.max(Sz.Y, 4)
			Cam.CFrame = CFrame.lookAt(CF.Position + Vector3.new(0, H * 0.05, -H * 2.05), CF.Position + Vector3.new(0, -H * 0.02, 0))
			self.Model = M
		end
		return V
	end
	local function CloneSelf()
		local C = lp.Character
		if not C then return nil end
		local Old = C.Archivable
		C.Archivable = true
		local Ok, M = pcall(function() return C:Clone() end)
		C.Archivable = Old
		if not Ok then return nil end
		for _, D in ipairs(M:GetDescendants()) do
			if D:IsA("Tool") or (D:IsA("BasePart") and (D.Name:find("Aceso") or D.Name == "HumanoidRootPart")) then D:Destroy() end
		end
		return M
	end
	local function ModelFor(Name)
		local Ok, Id = pcall(function() return Players:GetUserIdFromNameAsync(Name) end)
		if not Ok or not Id then return nil end
		local Ok2, M = pcall(function() return Players:CreateHumanoidModelFromUserId(Id) end)
		return Ok2 and M or nil
	end
	local function Build(Tab)
		local Pv = Tab:Section({ Name = "Preview", Side = "Left" })
		local PH = Pv:Custom(200)
		local Me = Viewer(PH, "YOU", UDim2.fromOffset(0, 0))
		local Other = Viewer(PH, "OUTFIT", UDim2.fromOffset(249, 0))
		local Pending = false
		local function RefreshMe()
			if Pending then return end
			Pending = true
			task.delay(0.6, function()
				Pending = false
				Me:Show(CloneSelf(), lp.DisplayName)
			end)
		end
		local Want = ""
		local function ShowOther(Name)
			Name = tostring(Name or ""):match("^%s*(.-)%s*$")
			Want = Name
			if Name == "" then Other:Show(nil, "type a name or pick a player") return end
			Other.Name.Text = "loading " .. Name .. "..."
			task.spawn(function()
				local M = ModelFor(Name)
				if Want ~= Name then if M then M:Destroy() end return end
				Other:Show(M, M and Name or "couldn't load " .. Name)
			end)
		end
		Other:Show(nil, "type a name or pick a player")
		RefreshMe()
		On(lp.CharacterAdded, function() task.delay(1.5, RefreshMe) end)
		Pv:Label("the left one updates when you copy an outfit or change your body.")
		local Au = Tab:Section({ Name = "Body aura", Side = "Right" })
		Au:Toggle({ Name = "Body aura", Flag = "CharAura", Callback = function(V) State.Aura = V; ApplyBodyAura() end })
			:AddColorpicker({ Flag = "CharAuraA", Default = State.AuraA, Callback = function(C) State.AuraA = C; if State.Aura then ApplyBodyAura() end end })
			:AddColorpicker({ Flag = "CharAuraB", Default = State.AuraB, Callback = function(C) State.AuraB = C; if State.Aura then ApplyBodyAura() end end })
		Au:Dropdown({ Name = "Style", Flag = "CharAuraStyle", Options = AURA_NAMES, Default = State.AuraStyle, Callback = function(V) State.AuraStyle = V; if State.Aura then ApplyBodyAura() end end })
		Au:Slider({ Name = "Amount", Flag = "CharAuraRate", Min = 4, Max = 40, Default = State.AuraRate, Callback = function(V) State.AuraRate = V; if State.Aura then ApplyBodyAura() end end })
		Au:Label("particles that float around your character. client side, only you see them.")
		local Body = Tab:Section({ Name = "Body", Side = "Left" })
		Body:Toggle({ Name = "Fake headless", Flag = "CharHeadless", Callback = function(V) State.Headless = V; ApplyHeadless(); RefreshMe() end })
		Body:Toggle({ Name = "Fake korblox", Flag = "CharKorblox", Callback = function(V) State.Korblox = V; ApplyKorblox(); RefreshMe() end })
		Body:Label("client sided, only you see these. they come back after you respawn.")
		local Out = Tab:Section({ Name = "Character spoofer", Side = "Left" })
		local Box = Out:Textbox({ Name = "Username", Flag = "CharCopyName", Placeholder = "copy someone's outfit", Save = false, Callback = function(V, Enter) if Enter then ShowOther(V) end end })
		Out:Button({ Name = "Copy outfit", Callback = function()
			local Ok, Err = CopyUser(Box:Get())
			RefreshMe()
			Library:Notify(Ok and ("wearing " .. Box:Get() .. "'s outfit") or tostring(Err), 3)
		end }):Button({ Name = "Restore mine", Callback = function()
			local Ok, Err = RestoreOwn()
			RefreshMe()
			if not Ok then Library:Notify(tostring(Err), 3) end
		end })
		Out:PlayerList({ Height = 130, Flag = "__CharPlayers", Callback = function(P)
			if not P then return end
			Box:Set(P.Name)
			ShowOther(P.Name)
		end })
		local A = Tab:Section({ Name = "Animation spoofer", Side = "Right" })
		local Drops = {}
		A:Dropdown({ Name = "Preset (all slots)", Flag = "AnimPreset", Options = PACK_NAMES, Default = "Default", Callback = function(V)
			for _, S in ipairs(SLOTS) do Anim[S[1]] = V; if Drops[S[1]] then Drops[S[1]]:SetOptions(PACK_NAMES, true); Drops[S[1]]:Set(V) end end
			local Ok, Err = ApplyAnims()
			if not Ok then Library:Notify(Err, 3) end
		end })
		for _, S in ipairs(SLOTS) do
			Drops[S[1]] = A:Dropdown({ Name = S[1]:sub(1, 1):upper() .. S[1]:sub(2), Flag = "Anim_" .. S[1], Options = PACK_NAMES, Default = "Default", Callback = function(V)
				if Anim[S[1]] == V then return end
				Anim[S[1]] = V
				ApplyAnims()
			end })
		end
		A:Slider({ Name = "Animation speed", Flag = "AnimSpeed", Min = 0.25, Max = 3, Decimals = 2, Default = 1, Suffix = "x", Callback = function(V) Anim.speed = V end })
		A:Button({ Name = "Reapply", Callback = function() local Ok, Err = ApplyAnims(); if not Ok then Library:Notify(Err, 3) end end })
	end
	local function Unload()
		for _, C in ipairs(Conns) do pcall(function() C:Disconnect() end) end
		table.clear(Conns)
		State.Headless, State.Korblox, State.Chams, State.FF, State.Aura = false, false, false, false, false
		pcall(ApplyBodyAura)
		pcall(ApplyHeadless)
		pcall(ClearKorblox)
		pcall(ApplyChams)
		for K in pairs(Anim) do if K ~= "speed" then Anim[K] = "Default" end end
		pcall(ApplyAnims)
	end
	return { Build = Build, Unload = Unload, Refresh = Refresh }
end)()
Library:LoaderStep("loading kill effects", 0.46)
local Effects = (function()
	local Debris = game:GetService("Debris")
	local Lighting = game:GetService("Lighting")
	local lp = LocalPlayer
	local New, Corner, Tween = Library.New, Library.Corner, Library.Tween
	local rgb, v3 = Color3.fromRGB, Vector3.new
	local Conns = {}
	local function On(Sig, Fn) local C = Sig:Connect(Fn); Conns[#Conns + 1] = C; return C end
	local S = {
		Death = false, DeathStyle = "Ascend", DeathCol = rgb(150, 210, 255), DeathCol2 = rgb(255, 255, 255), DeathScale = 1, DeathFlash = true, DeathShake = true,
	}
	local FX = workspace:FindFirstChild("AcesoFX") or workspace
	local SPARK, SPARKLE, SMOKE, FIRE = "rbxasset://textures/particles/fire_sparks_main.dds", "rbxasset://textures/particles/sparkles_main.dds",
		"rbxasset://textures/particles/smoke_main.dds", "rbxasset://textures/particles/fire_main.dds"
	local function Ghosts(Char, Fn, Mat)
		local N = 0
		for _, P in ipairs(Char:GetChildren()) do
			if P:IsA("BasePart") and P.Transparency < 1 and P.Name ~= "HumanoidRootPart" then
				N = N + 1
				local G = Instance.new("Part")
				G.Anchored, G.CanCollide, G.CanQuery, G.CanTouch, G.CastShadow = true, false, false, false, false
				G.Material, G.Color, G.Transparency = Mat or Enum.Material.Neon, S.DeathCol, 0.2
				G.Size, G.CFrame = P.Size, P.CFrame
				G.Parent = FX
				Fn(G, N)
				Debris:AddItem(G, 3.5)
			end
		end
	end
	local function Burst(Pos, Tex, N, Speed, Up, Size, Life)
		local A = Instance.new("Attachment")
		A.WorldPosition = Pos
		A.Parent = workspace.Terrain
		local E = Instance.new("ParticleEmitter")
		E.Texture = Tex
		E.Rate = 0
		E.Speed = NumberRange.new(Speed * 0.4, Speed)
		E.Lifetime = NumberRange.new((Life or 1) * 0.6, (Life or 1) * 1.4)
		E.SpreadAngle = Vector2.new(180, 180)
		E.Acceleration = v3(0, Up or -20, 0)
		E.Drag = 2
		E.Rotation = NumberRange.new(0, 360)
		E.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, (Size or 0.5) * S.DeathScale), NumberSequenceKeypoint.new(1, 0) })
		E.Transparency = NumberSequence.new(0, 1)
		E.Color = ColorSequence.new(S.DeathCol, S.DeathCol2)
		E.LightEmission, E.LightInfluence = 1, 0
		E.Parent = A
		E:Emit(math.floor(N * (Library.Quality or 1) + 0.5))
		Debris:AddItem(A, 3)
		return A
	end
	local function Glow(Pos, Range, Bright, Time)
		local P = Instance.new("Attachment")
		P.WorldPosition = Pos
		P.Parent = workspace.Terrain
		local L = Instance.new("PointLight")
		L.Color, L.Range, L.Brightness, L.Shadows = S.DeathCol, Range, Bright, false
		L.Parent = P
		Tween(L, Time or 0.6, { Brightness = 0 })
		Debris:AddItem(P, (Time or 0.6) + 0.1)
	end
	local function Orb(Pos, Size, Tr, Shape)
		local B = Instance.new("Part")
		B.Anchored, B.CanCollide, B.CanQuery, B.CanTouch, B.CastShadow = true, false, false, false, false
		B.Shape, B.Material, B.Color, B.Transparency = Shape or Enum.PartType.Ball, Enum.Material.Neon, S.DeathCol, Tr or 0.1
		B.Size = v3(Size, Size, Size)
		B.Position = Pos
		B.Parent = FX
		return B
	end
	local function Shock(Pos, To, Time)
		local R = Orb(Pos, 1, 0.2, Enum.PartType.Cylinder)
		R.Size = v3(0.15, 1, 1)
		R.CFrame = CFrame.new(Pos) * CFrame.Angles(0, 0, math.rad(90))
		Tween(R, Time or 0.5, { Size = v3(0.15, To, To), Transparency = 1 }, Enum.EasingStyle.Quart)
		Debris:AddItem(R, (Time or 0.5) + 0.1)
	end
	local ScreenFlash
	local function Flash(K)
		if not S.DeathFlash then return end
		if not ScreenFlash or not ScreenFlash.Parent then ScreenFlash = Instance.new("ColorCorrectionEffect"); ScreenFlash.Name = "AcesoKillFlash"; ScreenFlash.Parent = Lighting end
		ScreenFlash.TintColor = Color3.new(1, 1, 1):Lerp(S.DeathCol, 0.5)
		ScreenFlash.Brightness = K
		Tween(ScreenFlash, 0.35, { Brightness = 0, TintColor = Color3.new(1, 1, 1) })
	end
	local function Shake(Pos, Amt)
		if not S.DeathShake then return end
		local Cam = workspace.CurrentCamera
		local D = (Cam.CFrame.Position - Pos).Magnitude
		if D > 80 then return end
		local K = Amt * (1 - D / 80)
		task.spawn(function()
			for I = 1, 8 do
				local F = K * (1 - I / 8)
				Cam.CFrame = Cam.CFrame * CFrame.Angles(math.rad((math.random() - 0.5) * F), math.rad((math.random() - 0.5) * F), 0)
				RunService.RenderStepped:Wait()
			end
		end)
	end
	local DEATH = {
		Ascend = function(Char, Pos)
			Ghosts(Char, function(G) Tween(G, 1.8, { CFrame = G.CFrame + v3(0, 9, 0), Transparency = 1 }, Enum.EasingStyle.Sine) end)
			Burst(Pos, SPARKLE, 40, 6, 8)
			Glow(Pos, 18, 4, 1.4)
		end,
		Shatter = function(Char, Pos)
			Ghosts(Char, function(G)
				local D = (G.Position - Pos)
				D = (D.Magnitude > 0.1 and D.Unit or v3(math.random() - 0.5, 0.5, math.random() - 0.5).Unit) * (6 + math.random() * 6)
				Tween(G, 0.9, { CFrame = (G.CFrame + D) * CFrame.Angles(math.random() * 3, math.random() * 3, 0), Size = G.Size * 0.3, Transparency = 1 }, Enum.EasingStyle.Quad)
			end, Enum.Material.Glass)
			Burst(Pos, SPARK, 50, 25)
			Flash(0.15)
		end,
		Lightning = function(_, Pos)
			local At = Pos + v3(math.random(-8, 8), 120, math.random(-8, 8))
			for _ = 1, 3 do
				local Prev = At
				for I = 1, 12 do
					local Nx = At:Lerp(Pos, I / 12) + (I < 12 and v3(math.random() - 0.5, 0, math.random() - 0.5) * 6 or v3())
					local Seg = Instance.new("Part")
					Seg.Anchored, Seg.CanCollide, Seg.CanQuery, Seg.CanTouch = true, false, false, false
					Seg.Material, Seg.Color = Enum.Material.Neon, S.DeathCol
					Seg.Size = v3(0.4, 0.4, (Nx - Prev).Magnitude)
					Seg.CFrame = CFrame.lookAt((Prev + Nx) / 2, Nx)
					Seg.Parent = FX
					Tween(Seg, 0.4, { Transparency = 1 })
					Debris:AddItem(Seg, 0.45)
					Prev = Nx
				end
				task.wait(0.06)
			end
			Glow(Pos, 40, 10)
			Shock(Pos - v3(0, 2.5, 0), 16, 0.4)
			Burst(Pos, SPARK, 40, 30)
			Flash(0.35)
			Shake(Pos, 3)
		end,
		Disintegrate = function(Char, Pos)
			Ghosts(Char, function(G)
				G.Material = Enum.Material.ForceField
				Tween(G, 1.2, { Size = G.Size * 0.05, Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			end)
			Burst(Pos, SMOKE, 30, 4, 4, 1)
			Burst(Pos, SPARKLE, 60, 8, 6)
		end,
		Explosion = function(_, Pos)
			local B = Orb(Pos, 1)
			Tween(B, 0.45, { Size = v3(14, 14, 14) * S.DeathScale, Transparency = 1 }, Enum.EasingStyle.Quad)
			Debris:AddItem(B, 0.5)
			Shock(Pos - v3(0, 2.5, 0), 22 * S.DeathScale, 0.5)
			Burst(Pos, SPARK, 70, 45)
			Burst(Pos, SMOKE, 20, 8, 3, 2, 1.6)
			Glow(Pos, 50, 12)
			Flash(0.3)
			Shake(Pos, 5)
		end,
		["Black hole"] = function(Char, Pos)
			local Core = Orb(Pos, 0.5, 0)
			Core.Color, Core.Material = Color3.new(0, 0, 0), Enum.Material.SmoothPlastic
			local Halo = Orb(Pos, 0.6, 0.3)
			Tween(Core, 0.4, { Size = v3(3, 3, 3) * S.DeathScale }, Enum.EasingStyle.Back)
			Tween(Halo, 0.4, { Size = v3(4.2, 4.2, 4.2) * S.DeathScale, Transparency = 0.6 }, Enum.EasingStyle.Back)
			local Ring = Orb(Pos, 1, 0.3, Enum.PartType.Cylinder)
			Ring.Size = v3(0.1, 9 * S.DeathScale, 9 * S.DeathScale)
			Ring.CFrame = CFrame.new(Pos) * CFrame.Angles(0, 0, math.rad(90))
			Tween(Ring, 1.4, { CFrame = Ring.CFrame * CFrame.Angles(math.rad(720), 0, 0), Size = v3(0.1, 1, 1), Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			Ghosts(Char, function(G)
				Tween(G, 1.1, { CFrame = CFrame.new(Pos) * CFrame.Angles(math.random() * 6, math.random() * 6, 0), Size = v3(0.05, 0.05, 0.05), Transparency = 0.6 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			end)
			local A = Burst(Pos, SPARKLE, 0, 1)
			local E = A:FindFirstChildOfClass("ParticleEmitter")
			E.Speed = NumberRange.new(-14, -8)
			E.Lifetime = NumberRange.new(0.5, 0.8)
			E.Shape = Enum.ParticleEmitterShape.Sphere
			E.Acceleration = v3()
			E:Emit(60)
			task.delay(1.2, function()
				Tween(Core, 0.2, { Size = v3(0.1, 0.1, 0.1) })
				Tween(Halo, 0.2, { Size = v3(8, 8, 8) * S.DeathScale, Transparency = 1 })
				Debris:AddItem(Core, 0.25)
				Debris:AddItem(Halo, 0.25)
				Debris:AddItem(Ring, 0.3)
				Shock(Pos, 18 * S.DeathScale, 0.45)
				Burst(Pos, SPARK, 50, 35)
				Glow(Pos, 40, 8)
				Flash(0.25)
				Shake(Pos, 4)
			end)
		end,
		Soul = function(Char, Pos)
			local Soul = Orb(Pos, 1.2, 0.15)
			local A0, A1 = Instance.new("Attachment"), Instance.new("Attachment")
			A0.Position, A1.Position = v3(0, 0.5, 0), v3(0, -0.5, 0)
			A0.Parent, A1.Parent = Soul, Soul
			local Tr = Instance.new("Trail")
			Tr.Attachment0, Tr.Attachment1 = A0, A1
			Tr.Lifetime, Tr.LightEmission, Tr.FaceCamera = 0.8, 1, true
			Tr.Color = ColorSequence.new(S.DeathCol, S.DeathCol2)
			Tr.Transparency = NumberSequence.new(0.2, 1)
			Tr.Parent = Soul
			local P = Instance.new("ParticleEmitter")
			P.Texture, P.Rate, P.Lifetime, P.Speed = SPARKLE, 30, NumberRange.new(0.5, 1), NumberRange.new(0.5, 1.5)
			P.Size = NumberSequence.new(0.4 * S.DeathScale, 0)
			P.LightEmission, P.LightInfluence = 1, 0
			P.Color = ColorSequence.new(S.DeathCol, S.DeathCol2)
			P.Parent = Soul
			Ghosts(Char, function(G) Tween(G, 0.8, { Transparency = 1 }) end, Enum.Material.ForceField)
			task.spawn(function()
				local T0 = os.clock()
				while os.clock() - T0 < 2 and Soul.Parent do
					local T = os.clock() - T0
					Soul.Position = Pos + v3(math.sin(T * 6) * 1.6, T * 7, math.cos(T * 6) * 1.6)
					RunService.Heartbeat:Wait()
				end
				P.Enabled = false
				Tween(Soul, 0.3, { Transparency = 1, Size = v3(0.1, 0.1, 0.1) })
				Burst(Soul.Position, SPARKLE, 30, 8, 4)
				Debris:AddItem(Soul, 1)
			end)
		end,
		Firework = function(_, Pos)
			local Rocket = Orb(Pos, 0.5, 0)
			local A0, A1 = Instance.new("Attachment"), Instance.new("Attachment")
			A0.Position, A1.Position = v3(0.2, 0, 0), v3(-0.2, 0, 0)
			A0.Parent, A1.Parent = Rocket, Rocket
			local Tr = Instance.new("Trail")
			Tr.Attachment0, Tr.Attachment1, Tr.Lifetime, Tr.LightEmission = A0, A1, 0.4, 1
			Tr.Color = ColorSequence.new(S.DeathCol2, S.DeathCol)
			Tr.Transparency = NumberSequence.new(0, 1)
			Tr.Parent = Rocket
			local Top = Pos + v3(0, 22, 0)
			Tween(Rocket, 0.6, { Position = Top }, Enum.EasingStyle.Quad)
			task.delay(0.6, function()
				Rocket.Transparency = 1
				Debris:AddItem(Rocket, 0.5)
				local Hue = select(1, S.DeathCol:ToHSV())
				for I = 1, 3 do
					local A = Burst(Top, SPARK, 0, 30, -10, 0.7, 1.4)
					local E = A:FindFirstChildOfClass("ParticleEmitter")
					E.Color = ColorSequence.new(Color3.fromHSV((Hue + I * 0.12) % 1, 0.7, 1), Color3.new(1, 1, 1))
					E.Drag = 1.2
					E:Emit(45)
				end
				Glow(Top, 60, 8, 1)
				Flash(0.15)
			end)
		end,
		Frozen = function(Char, Pos)
			local Ice = {}
			Ghosts(Char, function(G)
				G.Material, G.Color, G.Transparency = Enum.Material.Ice, Color3.new(0.75, 0.9, 1):Lerp(S.DeathCol, 0.3), 0.15
				G.Size = G.Size * 1.08
				Ice[#Ice + 1] = G
			end, Enum.Material.Ice)
			Burst(Pos, SPARKLE, 25, 3, 1)
			task.delay(0.9, function()
				for _, G in ipairs(Ice) do
					local D = (G.Position - Pos)
					D = (D.Magnitude > 0.1 and D.Unit or v3(0, 1, 0)) * (4 + math.random() * 5)
					Tween(G, 0.7, { CFrame = (G.CFrame + D - v3(0, 3, 0)) * CFrame.Angles(math.random() * 4, math.random() * 4, 0), Size = G.Size * 0.4, Transparency = 1 }, Enum.EasingStyle.Quad)
				end
				Burst(Pos, SPARK, 40, 20, -30)
				Flash(0.12)
			end)
		end,
		Voxelize = function(Char, Pos)
			local Q = Library.Quality or 1
			for _, P in ipairs(Char:GetChildren()) do
				if P:IsA("BasePart") and P.Transparency < 1 and P.Name ~= "HumanoidRootPart" then
					local Sz = P.Size
					local Nx = math.clamp(math.floor(Sz.X / 0.5 * Q), 1, 4)
					local Ny = math.clamp(math.floor(Sz.Y / 0.5 * Q), 1, 4)
					for I = 1, Nx do for J = 1, Ny do
						local Cube = Instance.new("Part")
						Cube.Anchored, Cube.CanCollide, Cube.CanQuery, Cube.CanTouch, Cube.CastShadow = true, false, false, false, false
						Cube.Material, Cube.Color = Enum.Material.Neon, S.DeathCol:Lerp(S.DeathCol2, math.random())
						Cube.Size = v3(Sz.X / Nx, Sz.Y / Ny, Sz.Z) * 0.9
						Cube.CFrame = P.CFrame * CFrame.new((I - 0.5) / Nx * Sz.X - Sz.X / 2, (J - 0.5) / Ny * Sz.Y - Sz.Y / 2, 0)
						Cube.Parent = FX
						local Delay = math.random() * 0.5
						task.delay(Delay, function()
							Tween(Cube, 0.8, { CFrame = Cube.CFrame + v3(math.random() - 0.5, 4 + math.random() * 4, math.random() - 0.5), Size = v3(0.05, 0.05, 0.05), Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
						end)
						Debris:AddItem(Cube, Delay + 0.9)
					end end
				end
			end
			Glow(Pos, 20, 4, 1.2)
		end,
		Glitch = function(Char, Pos)
			local Gs = {}
			Ghosts(Char, function(G) Gs[#Gs + 1] = G end)
			task.spawn(function()
				for I = 1, 10 do
					for _, G in ipairs(Gs) do
						if G.Parent then
							G.CFrame = G.CFrame + v3((math.random() - 0.5) * 1.2, 0, (math.random() - 0.5) * 1.2)
							G.Color = (I % 2 == 0) and S.DeathCol or S.DeathCol2
							G.Transparency = math.random() < 0.3 and 1 or 0.2
						end
					end
					task.wait(0.05)
				end
				for _, G in ipairs(Gs) do if G.Parent then G.Transparency = 1 end end
				Burst(Pos, SPARK, 30, 20)
			end)
			Flash(0.2)
		end,
		Supernova = function(_, Pos)
			local Core = Orb(Pos, 0.6, 0)
			Core.Color = Color3.new(1, 1, 1)
			Tween(Core, 0.25, { Size = Vector3.new(3, 3, 3) * S.DeathScale }, Enum.EasingStyle.Quad)
			task.delay(0.25, function()
				Tween(Core, 0.15, { Size = Vector3.new(0.3, 0.3, 0.3), Transparency = 0.2 })
				task.wait(0.15)
				Tween(Core, 0.5, { Size = Vector3.new(16, 16, 16) * S.DeathScale, Transparency = 1 }, Enum.EasingStyle.Quart)
				Debris:AddItem(Core, 0.55)
				Shock(Pos, 26 * S.DeathScale, 0.55)
				task.delay(0.12, Shock, Pos + Vector3.new(0, 1.5, 0), 18 * S.DeathScale, 0.5)
				Burst(Pos, SPARK, 80, 50, -10, 0.7, 1.2)
				Burst(Pos, SPARKLE, 60, 20, 0, 0.6, 1.6)
				Glow(Pos, 60, 14, 0.8)
				Flash(0.4)
				Shake(Pos, 5)
			end)
		end,
		Pillar = function(_, Pos)
			local Base = Pos - Vector3.new(0, 3, 0)
			local P = Orb(Base, 1, 0.1, Enum.PartType.Cylinder)
			P.Size = Vector3.new(0.1, 3 * S.DeathScale, 3 * S.DeathScale)
			P.CFrame = CFrame.new(Base) * CFrame.Angles(0, 0, math.rad(90))
			Tween(P, 0.25, { Size = Vector3.new(160, 2.4 * S.DeathScale, 2.4 * S.DeathScale), CFrame = CFrame.new(Base + Vector3.new(0, 80, 0)) * CFrame.Angles(0, 0, math.rad(90)) }, Enum.EasingStyle.Quart)
			task.delay(0.35, function() Tween(P, 0.8, { Size = Vector3.new(160, 0.1, 0.1), Transparency = 1 }) end)
			Debris:AddItem(P, 1.3)
			Shock(Base + Vector3.new(0, 0.2, 0), 14 * S.DeathScale, 0.6)
			local A = Burst(Base, SPARKLE, 0, 1)
			local E = A:FindFirstChildOfClass("ParticleEmitter")
			E.Speed = NumberRange.new(10, 30)
			E.SpreadAngle = Vector2.new(12, 12)
			E.Acceleration = Vector3.new(0, 10, 0)
			E.EmissionDirection = Enum.NormalId.Top
			E:Emit(70)
			Glow(Pos, 40, 10, 1)
			Flash(0.2)
		end,
	}
	local DEATH_NAMES = { "Ascend", "Shatter", "Lightning", "Disintegrate", "Explosion", "Black hole", "Soul", "Firework", "Frozen", "Voxelize", "Glitch", "Supernova", "Pillar" }
	local Shot = { T = 0, A = nil, B = nil, Char = nil, Cam = nil, Dir = nil }
	local Stat = { Shots = 0, Hits = 0, Kills = 0, LastShot = 0, LastHit = 0 }
	local Recent = setmetatable({}, { __mode = "k" })
	local Health = setmetatable({}, { __mode = "k" })
	local Tracked = setmetatable({}, { __mode = "k" })
	local Params = RaycastParams.new()
	Params.FilterType = Enum.RaycastFilterType.Exclude
	local function CharOf(Inst)
		local M = Inst and Inst:FindFirstAncestorOfClass("Model")
		while M do
			local H = M:FindFirstChildOfClass("Humanoid")
			if H then return M, H end
			M = M.Parent and M.Parent:FindFirstAncestorOfClass("Model")
		end
	end
	local function LineDist(Pos, A, B)
		local AB = B - A
		local Fr = math.clamp((Pos - A):Dot(AB) / math.max(AB:Dot(AB), 1e-3), 0, 1)
		return (A + AB * Fr - Pos).Magnitude
	end
	local function NearShot(Pos)
		if Shot.A and LineDist(Pos, Shot.A, Shot.B) < 3 then return true end
		if Shot.Cam then
			local V = Pos - Shot.Cam
			if V.Magnitude > 1 and V.Unit:Dot(Shot.Dir) > 0.998 then return true end
		end
		return false
	end
	local function Knocked(Char, Hum)
		if Hum.Health <= 0 then return true end
		local BE = Char:FindFirstChild("BodyEffects")
		local KO = BE and (BE:FindFirstChild("K.O") or BE:FindFirstChild("KO"))
		return KO and KO:IsA("BoolValue") and KO.Value or false
	end
	local function OnHit(Char, Dmg, Kill, Quiet)
		local Root = Char:FindFirstChild("HumanoidRootPart") or Char:FindFirstChild("Head")
		local Pos = Root and Root.Position
		Stat.LastHit = os.clock()
		if Kill then Stat.Kills = Stat.Kills + 1 elseif not Quiet then Stat.Hits = Stat.Hits + 1 end
		if Kill and S.Death and Pos then task.spawn(pcall, DEATH[S.DeathStyle], Char, Pos) end
	end
	local function RegisterShot(From, To, HitInst)
		local Now = os.clock()
		Stat.Shots = Stat.Shots + 1
		Stat.LastShot = Now
		Shot.T = Now
		if From then Shot.A, Shot.B = From, To end
		local Cam = workspace.CurrentCamera
		local M = UserInputService:GetMouseLocation()
		local R = Cam:ViewportPointToRay(M.X, M.Y)
		Shot.Cam, Shot.Dir = R.Origin, R.Direction
		if not HitInst then
			Params.FilterDescendantsInstances = { Cam, lp.Character }
			local Hit = workspace:Raycast(R.Origin, R.Direction * 1500, Params)
			HitInst = Hit and Hit.Instance
			if not From and Hit then Shot.A, Shot.B = R.Origin, Hit.Position end
		end
		local Char, Hum = CharOf(HitInst)
		if Char == lp.Character then Char = nil end
		Shot.Char = Char
	end
	On(ShotEvent.Event, function(From, To, _, HitInst)
		if os.clock() - Shot.T < 0.08 then
			Shot.A, Shot.B = From, To
			return
		end
		RegisterShot(From, To, HitInst)
	end)
	On(UserInputService.InputBegan, function(I)
		if I.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		if UserInputService:GetFocusedTextBox() then return end
		local Char = lp.Character
		if not (Char and Char:FindFirstChildWhichIsA("Tool")) then return end
		if Library:OverMenu() then return end
		task.defer(function() if os.clock() - Shot.T > 0.08 then RegisterShot(nil, nil, nil) end end)
	end)
	local function Track(Char, Hum)
		if Tracked[Hum] or Char == lp.Character then return end
		Tracked[Hum] = true
		Health[Hum] = Hum.Health
		local Dead = false
		local function Check(Dmg)
			local Now = os.clock()
			if Now - Shot.T > 0.6 then return end
			local Root = Char:FindFirstChild("HumanoidRootPart") or Char:FindFirstChild("Head")
			if Shot.Char ~= Char and not (Root and NearShot(Root.Position)) then return end
						local Kill = not Dead and Knocked(Char, Hum)
			if Kill then Dead = true end
			local Already = Now - (Recent[Char] or 0) < 0.6
			Recent[Char] = Now
			OnHit(Char, Dmg, Kill, Already)
		end
		On(Hum.HealthChanged, function(Nw)
			local Old = Health[Hum] or Nw
			Health[Hum] = Nw
			if Nw > 0 and Dead and Nw >= Old then Dead = false end
			if Nw < Old then Check(Old - Nw) end
		end)
		task.spawn(function()
			local BE = Char:FindFirstChild("BodyEffects") or Char:WaitForChild("BodyEffects", 5)
			local KO = BE and (BE:FindFirstChild("K.O") or BE:FindFirstChild("KO"))
			if KO and KO:IsA("BoolValue") then
				On(KO.Changed, function(V)
					if V and not Dead and os.clock() - Shot.T < 1.2 and (Shot.Char == Char or os.clock() - (Recent[Char] or 0) < 1.2) then
						Dead = true
						OnHit(Char, nil, true, true)
					elseif not V then Dead = false end
				end)
			end
		end)
	end
	local function Hook(Char)
		local Hum = Char:FindFirstChildOfClass("Humanoid") or Char:WaitForChild("Humanoid", 10)
		if Hum then Track(Char, Hum) end
	end
	local function Player(P)
		if P == lp then return end
		if P.Character then task.spawn(Hook, P.Character) end
		On(P.CharacterAdded, function(C) task.spawn(Hook, C) end)
	end
	for _, P in ipairs(Players:GetPlayers()) do Player(P) end
	On(Players.PlayerAdded, Player)
	local function PreviewDeath()
		local C = lp.Character
		local R = C and C:FindFirstChild("HumanoidRootPart")
		if R then task.spawn(pcall, DEATH[S.DeathStyle], C, R.Position + R.CFrame.LookVector * 8) end
	end
	local function Build(Tab)
		local D = Tab:Section({ Name = "Kill effect", Side = "Left" })
		D:Toggle({ Name = "Kill effect", Flag = "FxDeath", Callback = function(V) S.Death = V end })
			:AddColorpicker({ Flag = "FxDeathCol", Default = S.DeathCol, Callback = function(C) S.DeathCol = C end })
			:AddColorpicker({ Flag = "FxDeathCol2", Default = S.DeathCol2, Callback = function(C) S.DeathCol2 = C end })
		D:Dropdown({ Name = "Style", Flag = "FxDeathStyle", Options = DEATH_NAMES, Default = S.DeathStyle, Callback = function(V) S.DeathStyle = V end })
		D:Slider({ Name = "Size", Flag = "FxDeathScale", Min = 0.5, Max = 2.5, Decimals = 1, Default = 1, Suffix = "x", Callback = function(V) S.DeathScale = V end })
		D:Toggle({ Name = "Screen flash", Flag = "FxDeathFlash", Default = true, Callback = function(V) S.DeathFlash = V end })
		D:Toggle({ Name = "Camera shake", Flag = "FxDeathShake", Default = true, Callback = function(V) S.DeathShake = V end })
		D:Button({ Name = "Preview on me", Callback = PreviewDeath })
		D:Label("only plays on players your own shots hit and kill. nobody else sees it.")
	end
	local function Unload()
		if ScreenFlash then ScreenFlash:Destroy() end
		for _, C in ipairs(Conns) do pcall(function() C:Disconnect() end) end
		table.clear(Conns)
	end
	return { Build = Build, Unload = Unload, S = S, PreviewDeath = PreviewDeath, DeathNames = DEATH_NAMES }
end)()
Library:LoaderStep("loading weather, sky and seasons", 0.52)
local World = (function()
	local Lighting = game:GetService("Lighting")
	local Debris = game:GetService("Debris")
	local MaterialService = game:GetService("MaterialService")
	local lp = Players.LocalPlayer
	local cam = workspace.CurrentCamera
	local function screen() return Library.Gui end
	local rgb, v3, rand, NR = Color3.fromRGB, Vector3.new, math.random, NumberRange.new
	local WHITE, R360 = Color3.new(1, 1, 1), NumberRange.new(0, 360)
	local PO, NID = Enum.ParticleOrientation, Enum.NormalId
	local S = {
		intensity = 55, wind = 0, sound = true, weather_only = true, weather_only_off = false,
		time = math.floor(Lighting.ClockTime * 2 + 0.5) / 2,
		time_on = false, skybox = "none", spin = false, mc = false,
		spin_speed = 6, drift = true, sky3d = false, cycle = false, cycle_speed = 2, hide_sun = false, hide_moon = false, hide_stars = false,
		tint_on = false, tint_h = rgb(176, 214, 248),
		fog_on = false, fog_density = 0.62, fog_offset = 0.04, fog_haze = 3.2, fog_glare = 0, fog_h = rgb(200, 208, 220),
		splashes = true, snow_sfx = true,
		mat_on = false, mat = "smooth plastic", recolor_on = false, world_h = rgb(176, 214, 248), terrain_on = false,
		amb_on = false, amb_h = rgb(178, 178, 178), tech = "default",
		trail_on = false, trail_h = rgb(176, 214, 248), trail_h2 = Color3.new(1, 1, 1),
		trail_len = 0.6, trail_width = 2, trail_glow = true, trail_src = "body",
		trail_rainbow = false, trail_sparkles = false, trail_opacity = 85, trail_taper = 25,
		mb_strength = 1, mb_max = 14, cloud_count = 18, cloud_height = 300, season_all = true, season_trees = true,
	}
	local FX, CATS, active, order, conns = {}, {}, {}, {}, {}
	local cloud_field, cloud_run, sky_bodies, sky_run
	local objs, syncfns = {}, {}
	local function nr(t) return NR(t[1], t[2] or t[1]) end
	local function seq(...)
		local a, k = { ... }, {}
		for i = 1, #a, 2 do k[#k + 1] = NumberSequenceKeypoint.new(a[i], a[i + 1]) end
		return NumberSequence.new(k)
	end
	local function fade(a) return seq(0, 1, 0.12, a, 0.88, a, 1, 1) end
	local function ns(x) return type(x) == "number" and NumberSequence.new(x) or x end
	local function cs(c) return typeof(c) == "Color3" and ColorSequence.new(c) or c end
	local function tween(o, goal, time)
		TweenService:Create(o, TweenInfo.new(time or 1, Enum.EasingStyle.Sine), goal):Play()
	end
	local function ui(class, props, parent)
		local o = Instance.new(class)
		for k, v in pairs(props) do o[k] = v end
		o.Parent = parent
		return o
	end
	local function P(tex, speed, life, size, tr, col, extra)
		local p = { Texture = tex, Speed = nr(speed), Lifetime = nr(life), Size = ns(size), Transparency = ns(tr), Color = cs(col) }
		for k, v in pairs(extra or {}) do p[k] = v end
		return p
	end
	local function emitter(parent, props, rate)
		local e = Instance.new("ParticleEmitter")
		for k, v in pairs(props) do e[k] = v end
		e.Rate = rate or 0
		e.Parent = parent
		return e
	end
	local function ghost(size, parent)
		local p = Instance.new("Part")
		p.Name = "VisFx"
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
		p.Transparency = 1
		p.Size = size or v3(1, 1, 1)
		p.Parent = parent or cam
		return p
	end
	local function A(d, o, h, g, c, dc) return { Density = d, Offset = o, Haze = h, Glare = g, Color = c, Decay = dc } end
	local function G(tint, sat, con, bri) return { TintColor = tint, Saturation = sat, Contrast = con, Brightness = bri } end
	local function hue(c, default)
		if typeof(c) == "Color3" then return c end
		return default
	end
	local RAIN = "rbxassetid://3806148993"
	local MC_RAIN = "rbxassetid://1822883048"
	local SNOW = "rbxassetid://99851851"
	local SPLASH = "rbxassetid://270368855"
	local DROP = "rbxasset://textures/particles/sparkles_main.dds"
	local SOFT = "rbxasset://textures/particles/smoke_main.dds"
	local RING = "rbxasset://textures/particles/explosion01_shockwave_main.dds"
	local SPARK = "rbxasset://textures/particles/fire_sparks_main.dds"
	local RAIN_SND, SNOW_SND, STORM_SND = 9064263922, 9113286969, 551546110
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Exclude
	local PLACES = {
		above = { v3(150, 1, 150), "Bottom" }, near = { v3(60, 1, 60), "Bottom" }, wide = { v3(300, 1, 300), "Bottom" },
		sky = { v3(500, 1, 500), "Bottom" }, around = { v3(80, 26, 80), "Top" }, low = { v3(110, 1, 110), "Top" },
		wall = { v3(1, 70, 180), "Right" }, wall_low = { v3(1, 8, 180), "Right" },
	}
	local function place_cf(place, cp, wind, side, gy)
		if place == "above" then return CFrame.new(cp + v3(-wind * 0.6, 45, 0)) * CFrame.Angles(0, 0, math.rad(wind))
		elseif place == "near" then return CFrame.new(cp + v3(0, 25, 0))
		elseif place == "wide" then return CFrame.new(cp + v3(-wind * 0.8, 60, 0))
		elseif place == "sky" then return CFrame.new(cp + v3(0, 170, 0))
		elseif place == "around" then return CFrame.new(cp + v3(0, -3, 0))
		elseif place == "low" then return CFrame.new(cp.X, gy, cp.Z)
		elseif place == "wall" then return CFrame.new(cp + v3(-side * 70, 12, 0)) end
		return CFrame.new(cp + v3(-side * 70, -4, 0))
	end
	local flashcc, gradecc, rig
	local function flash(k)
		if not flashcc or not flashcc.Parent then flashcc = ui("ColorCorrectionEffect", { Name = "VisFlash" }, Lighting) end
		flashcc.Brightness = k
		tween(flashcc, { Brightness = 0 }, 0.5)
	end
	local function bolt(cp, col)
		local a, d = rand() * 6.283, 150 + rand() * 250
		local at = cp + v3(math.cos(a) * d, 260, math.sin(a) * d)
		local m = ui("Model", { Name = "VisFx" }, cam)
		local pts = { at }
		for _ = 1, 11 do
			local nxt = at + v3(rand(-18, 18), -28, rand(-18, 18))
			local seg = ghost(v3(1.4, 1.4, (nxt - at).Magnitude), m)
			seg.Transparency, seg.Material, seg.Color = 0, Enum.Material.Neon, col or rgb(225, 235, 255)
			seg.CFrame = CFrame.lookAt((at + nxt) / 2, nxt)
			at = nxt
			pts[#pts + 1] = at
		end
		for _ = 1, 2 do
			local s = pts[rand(3, 8)]
			local e = s + v3(rand(-30, 30), -rand(20, 45), rand(-30, 30))
			local seg = ghost(v3(0.7, 0.7, (e - s).Magnitude), m)
			seg.Transparency, seg.Material, seg.Color = 0.2, Enum.Material.Neon, col or rgb(225, 235, 255)
			seg.CFrame = CFrame.lookAt((s + e) / 2, e)
		end
		local l = ui("PointLight", { Color = col or rgb(200, 215, 255), Range = 60, Brightness = 6 }, m:FindFirstChildWhichIsA("BasePart"))
		Debris:AddItem(m, 0.22)
		return l
	end
	local function lightning(_, cp)
		flash(0.55)
		bolt(cp)
		task.delay(0.13, flash, 0.8)
	end
	local function boom(pos, color)
		local at = ui("Attachment", { Name = "VisFx" }, workspace.Terrain)
		at.WorldPosition = pos
		local l = ui("PointLight", { Color = color, Range = 60, Brightness = 8 }, at)
		tween(l, { Brightness = 0 }, 0.6)
		emitter(at, P(SPARK, { 30, 70 }, { 0.4, 0.9 }, seq(0, 0.6, 1, 0), seq(0, 0, 1, 1), color,
			{ SpreadAngle = Vector2.new(70, 70), Acceleration = v3(0, -80, 0), LightEmission = 1, LightInfluence = 0 })):Emit(30)
		emitter(at, P(SOFT, { 4, 10 }, { 1, 2 }, seq(0, 3, 1, 12), seq(0, 0.4, 1, 1), rgb(70, 62, 58),
			{ SpreadAngle = Vector2.new(80, 80), Rotation = R360 })):Emit(10)
		if (pos - cam.CFrame.Position).Magnitude < 160 then flash(0.25) end
		Debris:AddItem(at, 3)
	end
	local function streak(c, cp)
		local a, r = rand() * 6.283, c.r[1] + rand() * (c.r[2] - c.r[1])
		local from = cp + v3(math.cos(a) * r, c.h[1] + rand() * (c.h[2] - c.h[1]), math.sin(a) * r)
		local dir = v3(rand() - 0.5, c.drop, rand() - 0.5).Unit
		local to, hit = from + dir * (c.dist or 700), nil
		if c.impact then
			hit = workspace:Raycast(from, dir * 1500, ray)
			if hit then to = hit.Position end
		end
		local p = ghost(v3(c.size, c.size, c.size))
		p.Shape, p.Material, p.Color, p.Transparency, p.Position = Enum.PartType.Ball, Enum.Material.Neon, c.color, 0, from
		local a0 = ui("Attachment", { Position = v3(0, c.size / 2, 0) }, p)
		local a1 = ui("Attachment", { Position = v3(0, -c.size / 2, 0) }, p)
		ui("Trail", { Attachment0 = a0, Attachment1 = a1, Lifetime = c.trail, FaceCamera = true, LightEmission = 1,
			Color = ColorSequence.new(WHITE, c.color), Transparency = seq(0, 0, 1, 1), WidthScale = seq(0, 1, 1, 0) }, p)
		if c.fire then
			emitter(p, P(SOFT, { 2, 5 }, { 0.4, 0.8 }, seq(0, c.size * 1.2, 1, 0), seq(0, 0.2, 1, 1), c.color,
				{ LightEmission = 1, LightInfluence = 0 }), 60)
		end
		local T = (to - from).Magnitude / c.speed
		TweenService:Create(p, TweenInfo.new(T, Enum.EasingStyle.Linear), { Position = to }):Play()
		task.delay(T, function()
			if not p.Parent then return end
			if hit then boom(to, c.color) end
			p.Transparency = 1
			Debris:AddItem(p, c.trail + 1)
		end)
	end
	local SHOOT = { color = rgb(220, 235, 255), size = 0.8, speed = 700, trail = 0.5, h = { 250, 400 }, r = { 150, 600 }, drop = -0.12, dist = 900 }
	local METEOR = { color = rgb(255, 170, 80), size = 3, speed = 320, trail = 0.9, h = { 350, 450 }, r = { 0, 350 }, drop = -1.1, impact = true, fire = true }
	local COMET = { color = rgb(150, 220, 255), size = 7, speed = 110, trail = 4, h = { 420, 460 }, r = { 500, 700 }, drop = -0.05, dist = 1600 }
	local HELL = { color = rgb(255, 70, 30), size = 4, speed = 300, trail = 1, h = { 350, 450 }, r = { 0, 300 }, drop = -1.2, impact = true, fire = true }
	local LAVA = { color = rgb(255, 110, 30), size = 2.5, speed = 180, trail = 0.7, h = { 280, 360 }, r = { 0, 160 }, drop = -1.6, impact = true, fire = true }
	local function shooter(c) return function(_, cp) streak(c, cp) end end
	local function rain(k, col, emis)
		local x = { Orientation = PO.FacingCameraWorldUp, LightEmission = emis or 0.1, LightInfluence = emis and 0.3 or 0.9 }
		col = col or rgb(205, 220, 240)
		return { { "above", 1200 * k, P(RAIN, { 150, 175 }, { 0.55, 0.65 }, 2.6, fade(0.45), col, x) },
			{ "above", 400 * k, P(RAIN, { 120, 140 }, { 0.7, 0.85 }, 1.1, fade(0.72), col, x) } }
	end
	local function flake(place, rate, col, size, speed, wind, grav, extra)
		local p = P(SOFT, speed or { 1, 2 }, { 7, 10 }, size, fade(0.1), col, { SpreadAngle = Vector2.new(30, 30), Drag = 0.4, Rotation = R360,
			RotSpeed = NR(-160, 160), Squash = NumberSequence.new(0.7), LightInfluence = 1 })
		for k, v in pairs(extra or {}) do p[k] = v end
		return { place, rate, p, wind, grav }
	end
	local function mist(place, rate, col, size, alpha, extra)
		local p = P(SOFT, { 0.5, 1.8 }, { 6, 9 }, seq(0, size, 1, size * 1.8), fade(alpha), col,
			{ SpreadAngle = Vector2.new(70, 70), Rotation = R360, RotSpeed = NR(-12, 12), LightInfluence = 1 })
		for k, v in pairs(extra or {}) do p[k] = v end
		return { place, rate, p, 0.15, 0.2 }
	end
	local function fast(l) l[3].Speed, l[3].Lifetime = NR(45, 75), NR(1.6, 2.6) return l end
	local GREY = A(0.35, 0.2, 1.6, 0, rgb(160, 170, 182), rgb(96, 106, 118))
	local WET = G(rgb(226, 234, 245), -0.2, 0.04, -0.04)
	local NIGHT = { ClockTime = 0 }
	local PINK, PINK2 = rgb(255, 183, 205), ColorSequence.new(rgb(255, 196, 214), rgb(255, 232, 240))
	local LEAF = ColorSequence.new(rgb(214, 96, 32), rgb(196, 152, 44))
	local ASH = rgb(96, 90, 86)
	local GLOW = { LightEmission = 1, LightInfluence = 0 }
	local EMBER = { "around", 90, P(SPARK, { 5, 11 }, { 3, 5 }, seq(0, 0.28, 0.5, 0.2, 1, 0), seq(0, 0, 0.2, 0.25, 0.35, 0, 0.55, 0.35, 0.7, 0.05, 1, 1),
		ColorSequence.new(rgb(255, 196, 92), rgb(255, 72, 30)), { SpreadAngle = Vector2.new(25, 25), Drag = 0.3, LightEmission = 1, LightInfluence = 0 }), 0.35, 1.5 }
	local ASHFALL = { "above", 160, P(SOFT, { 2, 4 }, { 9, 13 }, 0.2, fade(0.3), ASH,
		{ SpreadAngle = Vector2.new(30, 30), Drag = 0.5, RotSpeed = NR(-90, 90), LightInfluence = 1 }), 0.3, -1 }
	local SNOWSOFT = { "above", 260, P(SOFT, { 3, 5 }, { 12, 15 }, seq(0, 0.32, 1, 0.26), fade(0.12), rgb(250, 252, 255),
		{ SpreadAngle = Vector2.new(25, 25), Drag = 0.45, RotSpeed = NR(-60, 60), Rotation = R360, LightEmission = 0.35, LightInfluence = 0.75 }), 0.25, -1.6 }
	local BLIZZ = {
		{ "wall", 1200, P(SOFT, { 45, 70 }, { 1.6, 2.4 }, seq(0, 0.22, 1, 0.16), fade(0.18), WHITE, { SpreadAngle = Vector2.new(12, 22), LightEmission = 0.3, LightInfluence = 0.8 }) },
		{ "wall", 800, P(SPARK, { 70, 100 }, { 1, 1.6 }, 0.12, fade(0.45), rgb(235, 242, 255), { Orientation = PO.VelocityParallel, LightEmission = 0.4, LightInfluence = 0.7 }) },
		{ "wall", 45, P(SOFT, { 30, 45 }, { 2.5, 3.5 }, seq(0, 6, 1, 14), fade(0.84), rgb(240, 244, 250), { SpreadAngle = Vector2.new(10, 25), RotSpeed = NR(-30, 30), Rotation = R360, LightInfluence = 0.9 }) },
	}
	function cloud_field(st, cp, gy, col)
		st.cl, st.base = {}, gy + S.cloud_height
		for i = 1, math.floor(S.cloud_count * (Library.Quality or 1)) do
			local w, d = 90 + rand() * 120, 70 + rand() * 90
			local p = ghost(v3(w, 18 + rand() * 20, d))
			st.objs[#st.objs + 1] = p
			local e = emitter(p, P(SOFT, { 0 }, { 14, 20 }, seq(0, 38 + rand() * 20, 1, 60 + rand() * 30), seq(0, 1, 0.18, 0.32, 0.82, 0.32, 1, 1),
				col or ColorSequence.new(rgb(255, 255, 255), rgb(214, 220, 230)),
				{ Rotation = R360, RotSpeed = NR(-2, 2), LightInfluence = 1, LightEmission = 0, LockedToPart = true }), 0.55)
			pcall(function()
				e.Shape = Enum.ParticleEmitterShape.Box
				e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
			end)
			e:Emit(7)
			st.cl[i] = { p = p, x = (rand() - 0.5) * 1800, z = (rand() - 0.5) * 1800, y = (rand() - 0.5) * 70 }
		end
	end
	function cloud_run(st, dt, cp)
		local drift = (6 + S.wind) * dt
		for _, c in ipairs(st.cl or {}) do
			c.x = c.x + drift
			if c.x > 900 then c.x = c.x - 1800 elseif c.x < -900 then c.x = c.x + 1800 end
			if c.z > 900 then c.z = c.z - 1800 elseif c.z < -900 then c.z = c.z + 1800 end
			c.p.Position = v3(cp.X + c.x, st.base + c.y, cp.Z + c.z)
		end
	end
	function sky_bodies(st)
		local function ball(size, col, tr)
			local p = ghost(v3(size, size, size))
			p.Shape, p.Material, p.Color, p.Transparency = Enum.PartType.Ball, Enum.Material.Neon, col, tr
			st.objs[#st.objs + 1] = p
			return p
		end
		st.sun, st.sunhalo = ball(70, rgb(255, 244, 214), 0), ball(150, rgb(255, 214, 150), 0.86)
		st.moon, st.moonhalo = ball(45, rgb(222, 230, 255), 0), ball(95, rgb(170, 190, 255), 0.9)
		st.moon.Material = Enum.Material.SmoothPlastic
		st.stars = ghost(v3(1800, 1800, 1800))
		st.objs[#st.objs + 1] = st.stars
		st.starfx = emitter(st.stars, P(DROP, { 0 }, { 12, 20 }, NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.1, 3), NumberSequenceKeypoint.new(0.9, 2.4), NumberSequenceKeypoint.new(1, 0) }),
			seq(0, 0.1, 0.5, 0.4, 1, 0.1), ColorSequence.new(WHITE, rgb(200, 215, 255)), { LightEmission = 1, LightInfluence = 0, LockedToPart = true }), 0)
		pcall(function()
			st.starfx.Shape = Enum.ParticleEmitterShape.Sphere
			st.starfx.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
		end)
	end
	function sky_run(st, dt, cp)
		local sd, md = Lighting:GetSunDirection(), Lighting:GetMoonDirection()
		local night = Lighting.ClockTime < 6 or Lighting.ClockTime > 18
		st.sun.Position, st.sunhalo.Position = cp + sd * 1400, cp + sd * 1420
		st.moon.Position, st.moonhalo.Position = cp + md * 1400, cp + md * 1420
		st.sun.Transparency, st.sunhalo.Transparency = sd.Y > -0.05 and 0 or 1, sd.Y > -0.05 and 0.86 or 1
		st.moon.Transparency, st.moonhalo.Transparency = md.Y > -0.05 and 0 or 1, md.Y > -0.05 and 0.9 or 1
		st.stars.Position = cp
		st.starfx.Rate = night and 60 or 0
	end
	local function cloud_flash(st, cp)
		flash(0.4)
		local p = st.cl and st.cl[rand(1, math.max(1, #st.cl))]
		if p then
			local l = ui("PointLight", { Color = rgb(200, 210, 255), Range = 60, Brightness = 10, Shadows = false }, p.p)
			tween(l, { Brightness = 0 }, 0.35)
			Debris:AddItem(l, 0.4)
		end
		if rand() < 0.5 then bolt(cp) end
	end
	local function CS(a, b) return ColorSequence.new(a, b) end
	local SKY_LAYER = {
		none = { cloud = CS(WHITE, rgb(214, 220, 230)), stars = 40, shoot = 0.2 },
		minecraft = { cloud = CS(WHITE, rgb(235, 240, 245)), stars = 30, shoot = 0.15 },
		realistic = { cloud = CS(WHITE, rgb(205, 212, 224)), stars = 40, shoot = 0.2 },
		galaxy = { stars = 130, space = true, shoot = 0.7, comet = true, star = rgb(220, 200, 255) },
		sunset = { cloud = CS(rgb(255, 205, 170), rgb(240, 140, 120)), stars = 20, shoot = 0.15 },
		pink = { cloud = CS(rgb(255, 210, 230), rgb(235, 160, 205)), stars = 45, shoot = 0.3 },
		["blue space"] = { stars = 150, space = true, shoot = 0.8, comet = true, star = rgb(190, 215, 255) },
		["black storm"] = { cloud = CS(rgb(95, 98, 110), rgb(55, 58, 68)), stars = 0, shoot = 0, bolts = true },
	}
	local function sky_layer_start(st, cp, gy)
		local o = SKY_LAYER[S.skybox] or SKY_LAYER.none
		st.layer = o
		if o.cloud then cloud_field(st, cp, gy, o.cloud) end
		if (o.stars or 0) > 0 then
			st.shell = ghost(v3(1700, 1700, 1700))
			st.objs[#st.objs + 1] = st.shell
			local q = Library.Quality or 1
			st.starfx = emitter(st.shell, P(DROP, { 0 }, { 12, 20 }, seq(0, 0, 0.1, 3, 0.5, 4.2, 0.9, 2.4, 1, 0), seq(0, 0.1, 0.5, 0.4, 1, 0.1),
				ColorSequence.new(WHITE, o.star or rgb(200, 215, 255)), { LightEmission = 1, LightInfluence = 0, LockedToPart = true }), 0)
			pcall(function()
				st.starfx.Shape = Enum.ParticleEmitterShape.Sphere
				st.starfx.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
			end)
			st.starRate = o.stars * q
			if o.space then st.starfx:Emit(math.floor(o.stars * 8 * q)) end
		end
	end
	local function sky_layer_run(st, dt, cp)
		if st.cl then cloud_run(st, dt, cp) end
		if st.shell then
			st.shell.CFrame = CFrame.new(cp)
			local night = Lighting.ClockTime < 6 or Lighting.ClockTime > 18
			st.starfx.Rate = (st.layer.space or night) and st.starRate or 0
		end
	end
	local function sky_layer_tick(st, cp)
		local o = st.layer or {}
		if (o.shoot or 0) > 0 and rand() < o.shoot then streak(SHOOT, cp) end
		if o.comet and rand() < 0.06 then streak(COMET, cp) end
		if o.bolts and rand() < 0.3 then bolt(cp) end
	end
	FX = {
		["sky layer"] = { every = { 1.5, 4 }, start = function(st, cp, gy) sky_layer_start(st, cp, gy) end,
			run = function(st, dt, cp) sky_layer_run(st, dt, cp) end, tick = function(st, cp) sky_layer_tick(st, cp) end },
		["drizzle"] = { layers = rain(0.2), look = A(0.28, 0.3, 1.2, 0, rgb(175, 182, 192), rgb(120, 128, 138)), grade = G(rgb(232, 238, 246), -0.1, 0, -0.02), splash = 0.25, sound = { RAIN_SND, 1.15, 0.25 } },
		["light rain"] = { layers = { { "above", 700, P(DROP, { 50, 60 }, { 0.9 }, 0.2, fade(0.2), rgb(215, 228, 255), { Squash = NumberSequence.new(3), Orientation = PO.FacingCameraWorldUp, LightEmission = 0.4, LightInfluence = 0.5 }) } },
			look = GREY, grade = WET, splash = 0.5, sound = { RAIN_SND, 1.1, 0.35 } },
		["original rain"] = { layers = { { "near", 600, P(MC_RAIN, { 60 }, { 0.8 }, 10, fade(0.78), WHITE, { Orientation = PO.FacingCameraWorldUp, LightEmission = 0.05, LightInfluence = 0.9 }) } },
			splash = 0.6, sound = { RAIN_SND, 1, 0.45 } },
		["heavy rain"] = { layers = rain(1.8), look = A(0.42, 0.12, 2.2, 0, rgb(132, 142, 156), rgb(74, 82, 94)), grade = G(rgb(214, 224, 240), -0.28, 0.08, -0.07), splash = 1.5, sound = { RAIN_SND, 0.9, 0.8 },
			clouds = { Cover = 0.9, Density = 0.8, Color = rgb(120, 126, 136) } },
		["thunderstorm"] = { layers = rain(1.4), look = A(0.32, 0.38, 1.6, 0, rgb(104, 110, 124), rgb(58, 62, 74)), grade = G(rgb(212, 220, 236), -0.3, 0.1, -0.06), splash = 1.2, sound = { RAIN_SND, 0.95, 0.7 },
			clouds = { Cover = 1, Density = 0.9, Color = rgb(84, 88, 100) }, every = { 5, 14 }, tick = lightning },
		["monsoon"] = { layers = { rain(2.2)[1], rain(2.2)[2], mist("wall_low", 25, rgb(190, 200, 214), 9, 0.85), fast(flake("wall", 300, rgb(200, 215, 235), 0.1)) },
			look = A(0.55, 0.05, 3, 0, rgb(120, 130, 144), rgb(60, 66, 78)), grade = G(rgb(205, 218, 236), -0.35, 0.1, -0.09), splash = 2, sound = { RAIN_SND, 0.85, 1 },
			clouds = { Cover = 1, Density = 1, Color = rgb(70, 74, 84) }, every = { 4, 10 }, tick = lightning },
		["thundersnow"] = { layers = { SNOWSOFT, BLIZZ[1] }, look = A(0.55, 0.05, 3.5, 0, rgb(170, 180, 205), rgb(110, 120, 150)), grade = G(rgb(215, 225, 255), -0.3, 0.06, -0.04),
			settle = 1, clouds = { Cover = 1, Density = 0.9, Color = rgb(150, 156, 176) }, every = { 4, 11 },
			tick = function(_, cp) flash(0.7); local l = bolt(cp, rgb(200, 190, 255)); if l then l.Color = rgb(190, 170, 255) end end, sound = { STORM_SND, 0.9, 0.45 } },
		["firestorm"] = { layers = { fast(flake("wall", 500, ColorSequence.new(rgb(255, 200, 80), rgb(255, 60, 20)), 0.18, nil, nil, nil, GLOW)), { "around", 160, EMBER[3], 0.35, 2.5 }, { "above", 260, ASHFALL[3], 0.3, -1 } },
			light = { Ambient = rgb(120, 50, 25), OutdoorAmbient = rgb(150, 70, 35) }, look = A(0.55, 0.05, 3.6, 1.2, rgb(200, 90, 40), rgb(90, 25, 10)),
			grade = G(rgb(255, 196, 160), 0.1, 0.15, -0.04), clouds = { Cover = 1, Density = 0.95, Color = rgb(90, 50, 40) }, every = { 1.2, 3 }, tick = shooter(HELL), sound = { STORM_SND, 0.7, 0.5 } },
		["storm front"] = { look = A(0.4, 0.15, 2, 0, rgb(100, 106, 120), rgb(50, 54, 64)), grade = G(rgb(210, 216, 230), -0.3, 0.12, -0.08),
			clouds = { Cover = 1, Density = 0.95, Color = rgb(70, 72, 82) }, layers = rain(0.6), splash = 0.5, sound = { RAIN_SND, 0.9, 0.4 }, every = { 2, 6 },
			start = function(st, cp, gy) cloud_field(st, cp, gy, ColorSequence.new(rgb(90, 92, 104), rgb(50, 52, 60))) end,
			run = function(st, dt, cp) cloud_run(st, dt, cp) end, tick = cloud_flash },
		["hail"] = { layers = { { "above", 500, P(SOFT, { 110, 130 }, { 0.6, 0.7 }, 0.3, fade(0.05), rgb(236, 242, 250), { LightInfluence = 1 }) } }, look = GREY, grade = WET, settle = 1.5, splash = 0.2 },
		["blizzard"] = { layers = BLIZZ, look = A(0.7, 0.02, 5, 0, rgb(228, 234, 244), rgb(196, 206, 222)), grade = G(rgb(226, 236, 255), -0.3, -0.05, 0.04), settle = 1, sound = { STORM_SND, 1, 0.5 } },
		["whiteout"] = { layers = { BLIZZ[1], BLIZZ[2], { "wall", 110, BLIZZ[3][3] } }, look = A(0.94, 0, 9, 0, rgb(240, 244, 250), rgb(226, 232, 242)), grade = G(rgb(236, 242, 255), -0.45, -0.12, 0.1), settle = 1, sound = { STORM_SND, 1.1, 0.7 } },
		["sandstorm"] = { look = A(0.42, 0.32, 2.6, 0.3, rgb(196, 156, 104), rgb(150, 108, 64)), grade = G(rgb(255, 226, 186), -0.12, 0.06, -0.04), sound = { RAIN_SND, 0.36, 0.5 }, layers = {
			{ "wall", 70, P(SOFT, { 38, 55 }, { 2.4, 3.4 }, seq(0, 8, 1, 18), fade(0.76), ColorSequence.new(rgb(214, 172, 116), rgb(176, 132, 84)), { SpreadAngle = Vector2.new(8, 20), RotSpeed = NR(-35, 35), Rotation = R360, LightInfluence = 0.85 }) },
			{ "wall", 1200, P(SPARK, { 70, 110 }, { 1, 1.5 }, 0.1, fade(0.4), rgb(232, 200, 150), { Orientation = PO.VelocityParallel, LightEmission = 0.15, LightInfluence = 0.9 }) },
			{ "wall_low", 30, P(SOFT, { 30, 42 }, { 2.5, 3.5 }, seq(0, 5, 1, 10), fade(0.82), rgb(200, 160, 110), { LightInfluence = 0.9 }) } } },
		["acid rain"] = { layers = rain(1, rgb(150, 255, 90), 0.5), look = A(0.4, 0.15, 2, 0, rgb(120, 160, 90), rgb(60, 90, 40)), grade = G(rgb(205, 255, 180), -0.1, 0.1, -0.05), splash = 1, sound = { RAIN_SND, 0.85, 0.6 } },
		["snowfall"] = { layers = { SNOWSOFT, { "wide", 900, P(SNOW, { 26, 32 }, { 5, 8 }, seq(0, 0.33, 0.5, 0.55, 1, 0.4), fade(0.3), rgb(230, 236, 255), { SpreadAngle = Vector2.new(50, 50), LightEmission = 0.5, LightInfluence = 0 }), 0.25 } },
			look = A(0.4, 0.12, 1.8, 0.2, rgb(214, 224, 238), rgb(168, 182, 204)), grade = G(rgb(230, 238, 255), -0.15, 0.02, 0.02), settle = 1, sound = { SNOW_SND, 1, 0.35 } },
		["tornado"] = { look = A(0.4, 0.2, 2.4, 0, rgb(120, 122, 118), rgb(64, 66, 62)), grade = G(rgb(214, 220, 205), -0.3, 0.1, -0.06), clouds = { Cover = 1, Density = 0.95, Color = rgb(78, 80, 78) }, sound = { STORM_SND, 0.8, 0.6 },
			layers = { { "wall", 300, P(SPARK, { 60, 90 }, { 1, 1.6 }, 0.14, fade(0.5), rgb(150, 140, 120), { Orientation = PO.VelocityParallel, LightInfluence = 1 }) } },
			start = function(st)
				st.core, st.atts, st.ang = ghost(), {}, rand() * 6.283
				st.objs[#st.objs + 1] = st.core
				for i = 1, 16 do
					local h = (i - 1) * 8
					st.atts[i] = ui("Attachment", {}, st.core)
					emitter(st.atts[i], P(SOFT, { 1, 3 }, { 1.2, 1.8 }, seq(0, 5 + h * 0.18, 1, 9 + h * 0.3), seq(0, 1, 0.2, 0.35, 1, 1),
						ColorSequence.new(rgb(92, 90, 88), rgb(60, 58, 58)), { Rotation = R360, RotSpeed = NR(-120, 120), LightInfluence = 1 }), 30)
				end
				emitter(st.atts[1], P(SOFT, { 15, 30 }, { 1.5, 2.5 }, seq(0, 4, 1, 14), seq(0, 0.5, 1, 1), rgb(120, 105, 85), { SpreadAngle = Vector2.new(85, 85) }), 40)
			end,
			run = function(st, dt, cp, gy)
				st.ang = st.ang + dt * 0.12
				local base = v3(cp.X + math.cos(st.ang) * 130, gy, cp.Z + math.sin(st.ang) * 130)
				st.core.Position = base
				for i, at in ipairs(st.atts) do
					local h = (i - 1) * 8
					local r, a = 3 + h * 0.2, st.t * 5 + i * 0.8
					at.WorldPosition = base + v3(math.cos(a) * r + math.sin(st.t * 0.7 + h * 0.03) * h * 0.12, h, math.sin(a) * r)
				end
			end },
		["shooting stars"] = { every = { 0.6, 2 }, tick = shooter(SHOOT) },
		["meteors"] = { every = { 4, 9 }, tick = shooter(METEOR) },
		["meteor shower"] = { every = { 0.4, 1.2 }, tick = shooter(METEOR) },
		["comet"] = { every = { 22, 36 }, tick = shooter(COMET) },
		["starfall"] = { light = NIGHT, layers = { { "wide", 60, P(DROP, { 25, 40 }, { 4, 6 }, seq(0, 0.6, 1, 0), fade(0.1), ColorSequence.new(WHITE, rgb(170, 200, 255)),
			{ LightEmission = 1, LightInfluence = 0, Orientation = PO.VelocityParallel, Squash = NumberSequence.new(2) }) } } },
		["aurora"] = { light = NIGHT, grade = G(rgb(215, 255, 235), 0.05, 0.05, 0), layers = { { "sky", 14, P(SOFT, { 1, 3 }, { 9, 13 }, seq(0, 30, 1, 55), seq(0, 1, 0.3, 0.75, 0.7, 0.8, 1, 1),
			ColorSequence.new({ ColorSequenceKeypoint.new(0, rgb(60, 255, 150)), ColorSequenceKeypoint.new(0.5, rgb(60, 220, 255)), ColorSequenceKeypoint.new(1, rgb(170, 90, 255)) }),
			{ Squash = NumberSequence.new(1.5), LightEmission = 1, LightInfluence = 0, Rotation = NR(-10, 10), SpreadAngle = Vector2.new(60, 60) }) } } },
		["blood moon"] = { light = { ClockTime = 0, Ambient = rgb(90, 30, 30), OutdoorAmbient = rgb(110, 40, 40) }, sky = { MoonAngularSize = 24 },
			look = A(0.35, 0.1, 2, 0, rgb(120, 20, 20), rgb(50, 5, 8)), grade = G(rgb(255, 150, 140), -0.1, 0.15, -0.02) },
		["eclipse"] = { light = { ClockTime = 12.5, Brightness = 0.5, Ambient = rgb(25, 25, 35), OutdoorAmbient = rgb(40, 40, 55), ExposureCompensation = -0.8 },
			sky = { SunAngularSize = 25 }, grade = G(rgb(190, 200, 230), -0.3, 0.15, -0.1), post = { { "SunRaysEffect", { Intensity = 0.3, Spread = 1 } } },
			start = function(st)
				st.disc = ghost(v3(111, 111, 111))
				st.disc.Shape, st.disc.Color, st.disc.Transparency = Enum.PartType.Ball, Color3.new(0, 0, 0), 0
				st.objs[#st.objs + 1] = st.disc
			end,
			run = function(st, _, cp) st.disc.Position = cp + Lighting:GetSunDirection() * 300 end },
		["celestial"] = { light = { ClockTime = 0, Ambient = rgb(60, 55, 95), OutdoorAmbient = rgb(80, 75, 125) }, sky = { StarCount = 5000, MoonAngularSize = 16 }, grade = G(rgb(220, 210, 255), 0.1, 0.08, 0),
			layers = { { "around", 25, P(DROP, { 0.2, 0.8 }, { 3, 5 }, seq(0, 0, 0.5, 0.25, 1, 0), 0.1, ColorSequence.new(WHITE, rgb(190, 170, 255)), { SpreadAngle = Vector2.new(180, 180), LightEmission = 1, LightInfluence = 0 }) } } },
		["moonlight"] = { light = { ClockTime = 0, Brightness = 2.4, Ambient = rgb(70, 85, 120), OutdoorAmbient = rgb(90, 105, 140) }, sky = { MoonAngularSize = 15 }, grade = G(rgb(200, 215, 255), -0.15, 0.05, 0) },
		["starlight"] = { light = { ClockTime = 0, Ambient = rgb(40, 45, 70), OutdoorAmbient = rgb(55, 60, 90) }, sky = { StarCount = 5000, MoonAngularSize = 0 }, grade = G(rgb(210, 220, 255), -0.1, 0.1, -0.02) },
		["clouds"] = { clouds = { Cover = 0.65, Density = 0.6, Color = WHITE } },
		["cloud ceiling"] = { clouds = { Cover = 1, Density = 0.95, Color = rgb(150, 155, 165) }, light = { Brightness = 1.2 }, grade = G(rgb(225, 228, 235), -0.2, 0, -0.03) },
		["sunrise"] = { light = { ClockTime = 6.3 }, look = A(0.32, 0.1, 1.8, 0.6, rgb(255, 190, 150), rgb(255, 140, 110)), grade = G(rgb(255, 228, 220), 0.05, 0.04, 0) },
		["sunset"] = { light = { ClockTime = 17.8 }, look = A(0.34, 0.1, 2, 0.8, rgb(255, 150, 90), rgb(200, 80, 60)), grade = G(rgb(255, 214, 190), 0.1, 0.06, -0.01) },
		["golden hour"] = { light = { ClockTime = 16.9 }, look = A(0.3, 0.15, 1.6, 1, rgb(255, 205, 130), rgb(240, 150, 80)), grade = G(rgb(255, 232, 196), 0.12, 0.05, 0.01), post = { { "SunRaysEffect", { Intensity = 0.15, Spread = 0.9 } } } },
		["blue hour"] = { light = { ClockTime = 18.6 }, look = A(0.3, 0.15, 1.4, 0, rgb(90, 120, 190), rgb(40, 60, 120)), grade = G(rgb(190, 210, 255), -0.05, 0.06, -0.02) },
		["fog"] = { look = A(0.5, 0.05, 2.5, 0, rgb(200, 208, 220), rgb(128, 136, 150)) },
		["dense fog"] = { look = A(0.85, 0, 6, 0, rgb(205, 210, 218), rgb(150, 156, 166)), grade = G(rgb(235, 238, 242), -0.25, -0.05, 0) },
		["valley fog"] = { look = A(0.3, 0.3, 1.2, 0, rgb(210, 216, 224), rgb(150, 158, 170)), layers = { mist("low", 30, rgb(232, 236, 242), 14, 0.8) } },
		["rain mist"] = { look = GREY, layers = { mist("low", 40, rgb(200, 208, 220), 7, 0.85), mist("around", 30, rgb(210, 218, 230), 4, 0.9) } },
		["smoke"] = { look = A(0.45, 0.1, 3, 0, rgb(120, 118, 115), rgb(70, 68, 66)), layers = { mist("around", 20, rgb(110, 108, 106), 10, 0.8, { Speed = NR(2, 4) }) } },
		["ground smoke"] = { layers = { mist("low", 35, rgb(140, 138, 136), 9, 0.72) } },
		["black smoke"] = { look = A(0.5, 0.05, 3.5, 0, rgb(50, 48, 48), rgb(18, 18, 18)), grade = G(rgb(215, 210, 205), -0.3, 0.1, -0.06),
			layers = { mist("low", 30, rgb(24, 24, 24), 11, 0.55, { Speed = NR(3, 7) }), mist("around", 14, rgb(34, 32, 32), 13, 0.7, { Speed = NR(2, 5) }) } },
		["heat haze"] = { look = A(0.25, 0.3, 4, 1.5, rgb(255, 225, 180), rgb(230, 170, 110)), grade = G(rgb(255, 240, 215), 0.05, 0.04, 0.03),
			layers = { mist("low", 25, rgb(255, 240, 215), 8, 0.93, { Speed = NR(3, 6), Lifetime = NR(2, 3) }) } },
		["atmosphere"] = { look = A(0.35, 0, 1, 10, WHITE, rgb(120, 120, 120)) },
		["sun rays"] = { post = { { "SunRaysEffect", { Intensity = 0.12, Spread = 0.8 } } } },
		["god rays"] = { post = { { "SunRaysEffect", { Intensity = 0.45, Spread = 1 } } }, look = A(0.3, 0.2, 1.6, 1, rgb(230, 225, 210), rgb(170, 160, 140)) },
		["shadows"] = { light = { GlobalShadows = true, ShadowSoftness = 0.1 } },
		["fullbright"] = { light = { GlobalShadows = false, Brightness = 3, Ambient = rgb(178, 178, 178), OutdoorAmbient = rgb(178, 178, 178) } },
		["bloom"] = { post = { { "BloomEffect", { Intensity = 1.2, Size = 32, Threshold = 0.8 } } } },
		["motion blur"] = {
			start = function(st)
				st.blur = ui("BlurEffect", { Name = "VisBlur", Size = 0 }, Lighting)
				st.look, st.pos = cam.CFrame.LookVector, cam.CFrame.Position
				st.objs[#st.objs + 1] = st.blur
			end,
			run = function(st, dt)
				local cf = cam.CFrame
				local step = math.max(dt, 1 / 240)
				local turn = math.deg(math.acos(math.clamp(cf.LookVector:Dot(st.look), -1, 1))) / step
				local move = (cf.Position - st.pos).Magnitude / step
				st.look, st.pos = cf.LookVector, cf.Position
				if move > 400 then move = 0 end
				local target = (math.max(0, turn - 45) * 0.03 + math.max(0, move - 28) * 0.05) * S.mb_strength
				target = math.min(target, S.mb_max)
				local rate = target > st.blur.Size and 20 or 6
				st.blur.Size = st.blur.Size + (target - st.blur.Size) * math.min(dt * rate, 1)
			end },
		["lightning"] = { every = { 4, 10 }, tick = lightning },
		["light flashes"] = { every = { 2, 6 }, tick = function() flash(0.35) end },
		["impact flashes"] = { every = { 0.8, 2.5 }, tick = function(_, cp)
			local a, r = rand() * 6.283, 20 + rand() * 120
			local hit = workspace:Raycast(cp + v3(math.cos(a) * r, 80, math.sin(a) * r), v3(0, -400, 0), ray)
			if hit then boom(hit.Position, rgb(255, 235, 190)) end
		end },
		["embers"] = { layers = { EMBER, ASHFALL }, look = A(0.45, 0.1, 2.6, 0.6, rgb(130, 78, 56), rgb(86, 34, 22)), grade = G(rgb(255, 214, 186), 0.05, 0.08, -0.05) },
		["ambient dust"] = { layers = { { "around", 60, P(SOFT, { 0.3, 1 }, { 6, 9 }, 0.08, fade(0.5), rgb(235, 225, 200), { SpreadAngle = Vector2.new(180, 180), Drag = 0.5, LightInfluence = 1 }), 0.05 } } },
		["floating spores"] = { layers = { { "around", 35, P(SOFT, { 0.4, 1.2 }, { 7, 10 }, seq(0, 0, 0.2, 0.18, 1, 0.1), fade(0.2), rgb(214, 255, 196), { SpreadAngle = Vector2.new(180, 180), Drag = 0.6, LightEmission = 0.4, LightInfluence = 0.6 }), 0.08, 0.2 } } },
		["glowing particles"] = { layers = { { "around", 45, P(SOFT, { 0.5, 1.5 }, { 4, 7 }, seq(0, 0, 0.3, 0.3, 0.6, 0.12, 0.8, 0.28, 1, 0), 0.05, ColorSequence.new(rgb(110, 230, 255), rgb(190, 120, 255)),
			{ SpreadAngle = Vector2.new(180, 180), Drag = 0.7, LightEmission = 1, LightInfluence = 0 }), 0.05, 0.1 } } },
		["fireflies"] = { grade = G(rgb(214, 226, 255), -0.05, 0.05, -0.06), layers = { { "around", 22, P(SOFT, { 0.6, 1.6 }, { 5, 8 }, seq(0, 0, 0.1, 0.32, 0.25, 0.08, 0.42, 0.36, 0.58, 0.1, 0.75, 0.34, 0.9, 0.08, 1, 0), 0.05,
			ColorSequence.new(rgb(226, 255, 132), rgb(180, 255, 90)), { SpreadAngle = Vector2.new(180, 180), Drag = 0.8, LightEmission = 1, LightInfluence = 0 }), 0.05, 0.15 } } },
		["butterflies"] = { layers = { { "around", 14, P(DROP, { 2, 4 }, { 5, 8 }, seq(0, 0.1, 0.15, 0.45, 0.3, 0.12, 0.45, 0.45, 0.6, 0.12, 0.75, 0.45, 0.9, 0.12, 1, 0), 0.1,
			ColorSequence.new({ ColorSequenceKeypoint.new(0, rgb(255, 170, 60)), ColorSequenceKeypoint.new(0.5, rgb(255, 235, 120)), ColorSequenceKeypoint.new(1, rgb(120, 190, 255)) }),
			{ SpreadAngle = Vector2.new(180, 180), Drag = 0.6, RotSpeed = NR(-200, 200), LightEmission = 0.2, LightInfluence = 0.8 }), 0.1, 0.3, swirl = 3 } } },
		["magic dust"] = { layers = { { "around", 50, P(DROP, { 0.3, 1 }, { 3, 6 }, seq(0, 0, 0.2, 0.22, 0.5, 0.06, 0.8, 0.2, 1, 0), 0.05,
			ColorSequence.new({ ColorSequenceKeypoint.new(0, rgb(255, 150, 240)), ColorSequenceKeypoint.new(0.5, rgb(150, 200, 255)), ColorSequenceKeypoint.new(1, rgb(255, 240, 160)) }),
			{ SpreadAngle = Vector2.new(180, 180), Drag = 1, LightEmission = 1, LightInfluence = 0, RotSpeed = NR(-90, 90) }), 0.03, 0.4, swirl = 2 } } },
		["rain splashes"] = { splash = 1 },
		["sakura"] = { layers = { flake("above", 120, PINK2, 0.3, { 4, 7 }, 0.3, -1.2) }, look = A(0.28, 0.2, 1.4, 0.2, rgb(255, 214, 226), rgb(236, 170, 196)), grade = G(rgb(255, 232, 240), 0.06, 0.02, 0.01) },
		["sakura bloom"] = { layers = { flake("above", 260, PINK2, 0.32, { 4, 7 }, 0.3, -1.2), flake("around", 40, PINK2, 0.26, { 0.5, 2 }, 0.3, -0.4) }, grade = G(rgb(255, 222, 234), 0.12, 0.04, 0.02),
			post = { { "BloomEffect", { Intensity = 0.9, Size = 30, Threshold = 0.85 } } } },
		["sakura petals"] = { layers = { flake("above", 160, PINK2, 0.3, { 4, 7 }, 0.3, -1.2) } },
		["sakura haze"] = { look = A(0.35, 0.15, 2, 0.3, rgb(255, 205, 222), rgb(230, 150, 185)) },
		["sakura fog"] = { look = A(0.6, 0.03, 4, 0, rgb(255, 200, 220), rgb(225, 150, 185)), layers = { mist("low", 30, PINK, 12, 0.82) } },
		["sakura wind"] = { layers = { fast(flake("wall", 260, PINK2, 0.3)) } },
		["cherry blossom storm"] = { layers = { fast(flake("wall", 900, PINK2, 0.32)), flake("above", 300, PINK2, 0.3, { 8, 14 }, 0.6, -2), mist("wall_low", 20, PINK, 8, 0.85) },
			look = A(0.4, 0.1, 2.4, 0.2, rgb(255, 205, 222), rgb(225, 150, 185)), grade = G(rgb(255, 226, 238), 0.08, 0.04, 0.01), sound = { SNOW_SND, 1.1, 0.3 } },
		["autumn"] = { layers = { flake("above", 110, LEAF, 0.42, { 4, 8 }, 0.35, -2) }, look = A(0.3, 0.2, 1.5, 0.4, rgb(240, 190, 130), rgb(190, 120, 70)), grade = G(rgb(255, 228, 196), 0.1, 0.05, 0) },
		["autumn leaves"] = { layers = { flake("above", 150, LEAF, 0.42, { 4, 8 }, 0.35, -2) } },
		["autumn swirl"] = { layers = { (function() local l = flake("around", 70, LEAF, 0.4, { 1, 3 }) l[3].SpreadAngle = Vector2.new(180, 180) l.swirl = 9 return l end)() } },
		["autumn gusts"] = { layers = { (function() local l = fast(flake("wall", 420, LEAF, 0.42)) l.pulse = true return l end)() } },
		["autumn fog"] = { look = A(0.55, 0.05, 3, 0.2, rgb(226, 190, 150), rgb(170, 120, 80)), grade = G(rgb(255, 232, 205), -0.05, 0, 0) },
		["leaves storm"] = { layers = { fast(flake("wall", 800, LEAF, 0.45)), fast(flake("wall_low", 200, LEAF, 0.4)) }, look = A(0.36, 0.15, 2, 0.2, rgb(214, 170, 120), rgb(160, 110, 70)), sound = { SNOW_SND, 1.1, 0.3 } },
		["pollen"] = { look = A(0.26, 0.25, 1.3, 0.5, rgb(250, 240, 180), rgb(220, 200, 120)),
			layers = { { "around", 110, P(SOFT, { 0.3, 1 }, { 6, 9 }, 0.07, fade(0.25), rgb(255, 236, 130), { SpreadAngle = Vector2.new(180, 180), Drag = 0.5, LightEmission = 0.3, LightInfluence = 0.8 }), 0.1, 0.05 } } },
		["inferno"] = { layers = { { "around", 260, EMBER[3], 0.35, 2.5 }, mist("low", 25, rgb(255, 110, 40), 9, 0.8, GLOW) }, light = { Ambient = rgb(120, 40, 20), OutdoorAmbient = rgb(140, 60, 30) },
			look = A(0.5, 0.05, 3.2, 1, rgb(190, 70, 30), rgb(90, 20, 10)), grade = G(rgb(255, 190, 150), 0.1, 0.14, -0.04) },
		["inferno meteors"] = { every = { 0.5, 1.5 }, tick = shooter(HELL) },
		["inferno ash"] = { layers = { { "above", 320, ASHFALL[3], 0.3, -1 }, { "around", 30, EMBER[3], 0.35, 1.5 } }, look = A(0.5, 0.08, 3, 0.3, rgb(110, 70, 55), rgb(60, 28, 20)), grade = G(rgb(245, 205, 185), -0.1, 0.1, -0.06) },
		["volcanic ash"] = { layers = { { "above", 420, ASHFALL[3], 0.3, -1 }, { "wide", 500, P(SOFT, { 4, 7 }, { 9, 12 }, 0.12, fade(0.4), ASH, { SpreadAngle = Vector2.new(20, 20), Drag = 0.3, LightInfluence = 1 }), 0.25, -1 } },
			look = A(0.65, 0.03, 4.5, 0, rgb(110, 106, 102), rgb(60, 58, 56)), grade = G(rgb(220, 214, 208), -0.4, 0.05, -0.06), clouds = { Cover = 1, Density = 1, Color = rgb(70, 68, 66) } },
		["volcanic eruption"] = { layers = { { "above", 220, ASHFALL[3], 0.3, -1 } }, look = A(0.5, 0.08, 3.4, 0.6, rgb(150, 80, 55), rgb(70, 30, 20)), grade = G(rgb(255, 205, 175), 0, 0.12, -0.05),
			clouds = { Cover = 1, Density = 0.95, Color = rgb(80, 66, 62) }, every = { 0.25, 0.8 },
			start = function(st, cp, gy)
				local a = rand() * 6.283
				st.vent = v3(cp.X + math.cos(a) * 260, gy, cp.Z + math.sin(a) * 260)
				local p = ghost(v3(30, 1, 30), workspace.Terrain)
				p.Position = st.vent
				st.objs[#st.objs + 1] = p
				emitter(p, P(SOFT, { 40, 70 }, { 5, 8 }, seq(0, 20, 1, 70), seq(0, 0.2, 0.7, 0.5, 1, 1), ColorSequence.new(rgb(70, 60, 56), rgb(30, 28, 28)), { SpreadAngle = Vector2.new(12, 12), Rotation = R360, RotSpeed = NR(-20, 20), LightInfluence = 1 }), 14)
				emitter(p, P(SPARK, { 90, 160 }, { 2, 3.5 }, seq(0, 3, 1, 0.5), seq(0, 0, 1, 1), ColorSequence.new(rgb(255, 200, 80), rgb(255, 60, 20)), { SpreadAngle = Vector2.new(22, 22), Acceleration = v3(0, -70, 0), LightEmission = 1, LightInfluence = 0 }), 70)
				ui("PointLight", { Color = rgb(255, 110, 40), Range = 60, Brightness = 6 }, p)
			end,
			tick = function(st) streak(LAVA, st.vent) end },
		["ufo event"] = { light = NIGHT,
			start = function(st)
				local m = ui("Model", { Name = "VisFx" }, cam)
				local up = CFrame.Angles(0, 0, math.rad(90))
				st.pieces, st.lights, st.ang = {}, {}, rand() * 6.283
				st.objs[#st.objs + 1] = m
				local function piece(size, color, mat, shape, off, tr)
					local p = ghost(size, m)
					p.Transparency, p.Color, p.Material, p.Shape = tr or 0, color, mat, shape
					st.pieces[#st.pieces + 1] = { p, off }
					return p
				end
				piece(v3(3, 28, 28), rgb(120, 125, 135), Enum.Material.Metal, Enum.PartType.Cylinder, up)
				piece(v3(12, 12, 12), rgb(140, 230, 255), Enum.Material.Glass, Enum.PartType.Ball, CFrame.new(0, 2, 0), 0.35)
				local beam = piece(v3(60, 14, 14), rgb(140, 255, 170), Enum.Material.Neon, Enum.PartType.Cylinder, CFrame.new(0, -31, 0) * up, 0.85)
				ui("PointLight", { Color = rgb(140, 255, 170), Range = 60, Brightness = 3 }, beam)
				for i = 1, 8 do
					local a = i / 8 * 6.283
					st.lights[i] = piece(v3(1.6, 1.6, 1.6), WHITE, Enum.Material.Neon, Enum.PartType.Ball, CFrame.new(math.cos(a) * 12.5, -0.6, math.sin(a) * 12.5))
				end
			end,
			run = function(st, dt, cp, gy)
				st.ang = st.ang + dt * 0.35
				local base = CFrame.new(cp.X + math.cos(st.ang) * 70, gy + 60 + math.sin(st.t * 1.5) * 3, cp.Z + math.sin(st.ang) * 70) * CFrame.Angles(0, st.t * 0.8, 0)
				for _, pc in ipairs(st.pieces) do pc[1].CFrame = base * pc[2] end
				for i, l in ipairs(st.lights) do l.Color = Color3.fromHSV((st.t * 0.5 + i / 8) % 1, 0.8, 1) end
			end },
		["halloween"] = { light = { ClockTime = 0, Ambient = rgb(70, 40, 90), OutdoorAmbient = rgb(90, 55, 110) }, sky = { MoonAngularSize = 20 },
			look = A(0.42, 0.05, 2.4, 0, rgb(120, 70, 150), rgb(60, 30, 20)), grade = G(rgb(255, 190, 140), -0.1, 0.12, -0.03),
			layers = { mist("low", 28, rgb(130, 80, 170), 10, 0.8), { "around", 26, P(SOFT, { 0.6, 1.8 }, { 5, 8 }, seq(0, 0, 0.2, 0.4, 0.5, 0.15, 0.8, 0.38, 1, 0), 0.08, ColorSequence.new(rgb(255, 140, 30), rgb(255, 90, 10)),
				{ SpreadAngle = Vector2.new(180, 180), Drag = 0.7, LightEmission = 1, LightInfluence = 0 }), 0.05, 0.2 } } },
		["noir"] = { grade = G(WHITE, -1, 0.25, -0.02) },
		["vaporwave"] = { light = { ClockTime = 18.2 }, grade = G(rgb(255, 170, 230), 0.3, 0.1, 0.02), look = A(0.3, 0.2, 1.5, 0.5, rgb(255, 120, 200), rgb(90, 220, 255)),
			post = { { "BloomEffect", { Intensity = 1, Size = 30, Threshold = 0.8 } } } },
		["dreamy"] = { grade = G(rgb(255, 240, 250), 0.1, -0.05, 0.04), post = { { "BloomEffect", { Intensity = 1.6, Size = 40, Threshold = 0.7 } },
			{ "DepthOfFieldEffect", { FarIntensity = 0.35, FocusDistance = 40, InFocusRadius = 40, NearIntensity = 0 } } } },
		["cinematic"] = { grade = G(rgb(255, 238, 220), -0.1, 0.15, -0.02), post = { { "DepthOfFieldEffect", { FarIntensity = 0.25, FocusDistance = 30, InFocusRadius = 50, NearIntensity = 0 } } },
			start = function(st)
				for _, y in ipairs({ 0, 1 }) do
					st.objs[#st.objs + 1] = ui("Frame", { AnchorPoint = Vector2.new(0, y), Position = UDim2.fromScale(0, y), Size = UDim2.new(1, 0, 0.11, y == 0 and 36 or 0),
						BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = -5 }, screen())
				end
			end },
		["horror"] = { light = { Brightness = 0.6, Ambient = rgb(30, 10, 10), OutdoorAmbient = rgb(45, 20, 20) }, look = A(0.6, 0, 4, 0, rgb(40, 10, 10), rgb(10, 0, 0)),
			grade = G(rgb(255, 170, 170), -0.5, 0.3, -0.1), every = { 6, 14 }, tick = function() flash(-0.6) end },
		["underwater"] = { look = A(0.6, 0, 3, 0, rgb(40, 130, 170), rgb(10, 50, 90)), grade = G(rgb(150, 220, 255), 0.1, 0.05, -0.03), post = { { "BlurEffect", { Size = 4 } } },
			layers = { { "around", 50, P(RING, { 1, 3 }, { 3, 5 }, seq(0, 0.08, 1, 0.22), fade(0.3), rgb(210, 240, 255), { SpreadAngle = Vector2.new(25, 25), LightEmission = 0.5, LightInfluence = 0.5 }), 0.05, 3 } } },
		["matrix"] = { light = NIGHT, grade = G(rgb(150, 255, 160), -0.3, 0.2, -0.05), layers = { { "above", 500, P(DROP, { 60, 90 }, { 1, 1.4 }, 0.35, fade(0.1), rgb(80, 255, 110),
			{ Orientation = PO.VelocityParallel, Squash = NumberSequence.new(5), LightEmission = 1, LightInfluence = 0 }) } } },
		["rainbow"] = {
			start = function(st)
				st.cc = ui("ColorCorrectionEffect", { Name = "VisRainbow", Saturation = 0.15 }, Lighting)
				st.objs[#st.objs + 1] = st.cc
			end,
			run = function(st) st.cc.TintColor = Color3.fromHSV((st.t * 0.1) % 1, 0.35, 1) end },
		["disco"] = { post = { { "BloomEffect", { Intensity = 0.8, Size = 24, Threshold = 0.85 } } }, every = { 0.3, 0.5 },
			start = function(st)
				st.cc = ui("ColorCorrectionEffect", { Name = "VisDisco", Saturation = 0.3, Contrast = 0.1 }, Lighting)
				st.objs[#st.objs + 1] = st.cc
			end,
			tick = function(st) tween(st.cc, { TintColor = Color3.fromHSV(rand(), 0.55, 1) }, 0.25) end },
		["night"] = { light = { ClockTime = 0, Brightness = 1, Ambient = rgb(38, 42, 66), OutdoorAmbient = rgb(58, 64, 96), ExposureCompensation = -0.15 },
			look = A(0.32, 0.1, 1.3, 0, rgb(46, 56, 90), rgb(12, 14, 28)), grade = G(rgb(205, 215, 255), -0.12, 0.08, -0.03), sky = { StarCount = 4000, MoonAngularSize = 13 } },
		["midnight"] = { light = { ClockTime = 0, Brightness = 0.4, Ambient = rgb(18, 20, 34), OutdoorAmbient = rgb(28, 30, 48), ExposureCompensation = -0.5 },
			look = A(0.4, 0.05, 1.6, 0, rgb(26, 30, 52), rgb(4, 5, 12)), grade = G(rgb(190, 200, 255), -0.2, 0.12, -0.06), sky = { StarCount = 6000, MoonAngularSize = 9 } },
		["snow floor"] = { floor = "snow", settle = 0.5, grade = G(rgb(236, 242, 255), -0.08, 0.02, 0.02) },
		["frost floor"] = { floor = "frost", grade = G(rgb(226, 238, 255), -0.12, 0.04, 0.01) },
		["autumn floor"] = { floor = "autumn", leaves = 1, grade = G(rgb(255, 236, 214), 0.06, 0.03, 0) },
		["sakura floor"] = { floor = "sakura", grade = G(rgb(255, 236, 244), 0.06, 0.02, 0.01) },
		["withered floor"] = { floor = "withered", grade = G(rgb(236, 226, 210), -0.25, 0.06, -0.02) },
		["winter"] = { floor = "snow", settle = 1, layers = { SNOWSOFT }, look = A(0.42, 0.12, 1.9, 0.2, rgb(214, 224, 238), rgb(168, 182, 204)),
			grade = G(rgb(230, 238, 255), -0.15, 0.03, 0.02), clouds = { Cover = 0.75, Density = 0.7, Color = rgb(220, 226, 236) }, sound = { SNOW_SND, 1, 0.25 } },
		["fall"] = { floor = "autumn", leaves = 1.5, layers = { flake("above", 120, LEAF, 0.42, { 4, 8 }, 0.35, -2) }, light = { ClockTime = 16.4 },
			look = A(0.3, 0.2, 1.5, 0.5, rgb(240, 190, 130), rgb(190, 120, 70)), grade = G(rgb(255, 226, 192), 0.12, 0.05, 0) },
		["spring"] = { floor = "sakura", layers = { flake("above", 140, PINK2, 0.3, { 4, 7 }, 0.3, -1.2) }, look = A(0.26, 0.2, 1.3, 0.3, rgb(255, 214, 226), rgb(236, 170, 196)),
			grade = G(rgb(255, 238, 244), 0.1, 0.03, 0.02), post = { { "BloomEffect", { Intensity = 0.6, Size = 28, Threshold = 0.9 } } } },
		["summer"] = { floor = "summer", layers = { { "around", 60, P(SOFT, { 0.3, 1 }, { 6, 9 }, 0.07, fade(0.25), rgb(255, 236, 130), { SpreadAngle = Vector2.new(180, 180), Drag = 0.5, LightEmission = 0.3, LightInfluence = 0.8 }), 0.1, 0.05 } },
			light = { ClockTime = 13 }, look = A(0.24, 0.3, 1, 1.2, rgb(200, 225, 255), rgb(130, 170, 230)), grade = G(rgb(255, 248, 230), 0.18, 0.06, 0.02),
			post = { { "SunRaysEffect", { Intensity = 0.12, Spread = 0.8 } }, { "BloomEffect", { Intensity = 0.5, Size = 24, Threshold = 0.92 } } }, clouds = { Cover = 0.45, Density = 0.6, Color = WHITE } },
		["spooky"] = { floor = "spooky", leaves = 1, layers = { mist("low", 26, rgb(120, 80, 150), 10, 0.8), flake("above", 70, ColorSequence.new(rgb(230, 110, 30), rgb(110, 50, 140)), 0.4, { 3, 6 }, 0.35, -2) },
			light = { ClockTime = 19.2, Ambient = rgb(70, 45, 90), OutdoorAmbient = rgb(90, 60, 110) }, look = A(0.45, 0.05, 2.6, 0, rgb(120, 70, 150), rgb(50, 25, 40)),
			grade = G(rgb(255, 200, 170), -0.1, 0.14, -0.04), sky = { MoonAngularSize = 18 } },
		["3d clouds"] = { clouds = { Cover = 0.6, Density = 0.7, Color = WHITE },
			start = function(st, cp, gy) cloud_field(st, cp, gy) end, run = function(st, dt, cp) cloud_run(st, dt, cp) end },
		["3d sky"] = { clouds = { Cover = 0.55, Density = 0.65, Color = WHITE }, sky = { SunAngularSize = 0, MoonAngularSize = 0, StarCount = 0 },
			look = A(0.3, 0.25, 1.1, 0.4, rgb(190, 214, 245), rgb(120, 150, 200)),
			start = function(st, cp, gy) cloud_field(st, cp, gy); sky_bodies(st) end,
			run = function(st, dt, cp) cloud_run(st, dt, cp); sky_run(st, dt, cp) end },
		["wind gusts"] = { sound = { SNOW_SND, 1.2, 0.3 }, layers = { (function()
			local l = { "wall", 160, P(SPARK, { 80, 130 }, { 0.8, 1.3 }, 0.1, fade(0.75), rgb(235, 240, 245), { Orientation = PO.VelocityParallel, Squash = NumberSequence.new(4), LightInfluence = 1 }) }
			l.pulse = true
			return l
		end)() } },
	}
	local WEATHER_ONLY = {}
	for _, n in ipairs({ "drizzle", "light rain", "original rain", "heavy rain", "thunderstorm", "monsoon", "storm front", "thundersnow", "firestorm",
		"hail", "blizzard", "whiteout", "sandstorm", "tornado", "acid rain", "snowfall", "wind gusts" }) do WEATHER_ONLY[n] = true end
	local function keep(n) return not (S.weather_only and WEATHER_ONLY[n]) end
	local saved, atmo, parked_atmo, sky, parked_sky, sky_base, clouds, clouds_saved = {}, nil, nil, nil, nil, nil, nil, nil
	local SKY_KEYS = { "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp", "SunAngularSize", "MoonAngularSize", "StarCount" }
	local SKIES, SKY_NAMES = {}, { "none" }
	for _, s in ipairs({
		{ "minecraft", 1876545003, 1876544331, 1876542941, 1876543392, 1876543764, 1876544642 },
		{ "realistic", 653719502, 653718790, 653719067, 653719190, 653718931, 653719321 },
		{ "galaxy", 155657655, 155674246, 155657609, 155657671, 155657619, 155674931 },
		{ "sunset", 323493360, 323493329, 323493271, 323493295, 323493310, 323493345 },
		{ "pink", 12216109205, 12216109875, 12216109489, 12216110170, 12216110471, 12216108877 },
		{ "blue space", 15536110634, 15536112543, 15536110634, 15536110634, 15536110634, 15536117282 },
		{ "black storm", 15502511288, 15502508460, 15502510289, 15502507918, 15502509398, 15502511911 },
	}) do
		local t = {}
		for i = 1, 6 do t[SKY_KEYS[i]] = "rbxassetid://" .. s[i + 1] end
		SKIES[s[1]], SKY_NAMES[#SKY_NAMES + 1] = t, s[1]
	end
	local forced_time = nil
	local function setl(k, v)
		if type(v) == "boolean" or k == "ClockTime" then Lighting[k] = v else tween(Lighting, { [k] = v }, 0.8) end
	end
	local function relight()
		local over = {}
		for _, n in ipairs(order) do
			for k, v in pairs(keep(n) and FX[n].light or {}) do over[k] = v end
		end
		if S.time_on then over.ClockTime = S.time end
		forced_time = over.ClockTime
		if S.amb_on then
			local c = hue(S.amb_h, rgb(178, 178, 178))
			over.Ambient, over.OutdoorAmbient = c, c
		end
		for k, v in pairs(over) do
			if saved[k] == nil then saved[k] = Lighting[k] end
			pcall(setl, k, v)
		end
		for k, v in pairs(saved) do
			if over[k] == nil then pcall(setl, k, v) saved[k] = nil end
		end
	end
	local function reatmo()
		local look
		for _, n in ipairs(order) do look = keep(n) and FX[n].look or look end
		local tint = hue(S.tint_h, rgb(176, 214, 248))
		if S.fog_on then
			local c = hue(S.fog_h, rgb(200, 208, 220))
			look = A(S.fog_density, S.fog_offset, S.fog_haze, S.fog_glare, S.tint_on and tint or c, c:Lerp(Color3.new(0, 0, 0), 0.38))
		elseif S.tint_on and not look then
			look = A(0.3, 0.25, 1.2, 0, tint, tint:Lerp(Color3.new(0, 0, 0), 0.45))
		end
		if look then
			if not atmo then
				parked_atmo = {}
				for _, c in ipairs(Lighting:GetChildren()) do
					if c:IsA("Atmosphere") then parked_atmo[#parked_atmo + 1] = c c.Parent = nil end
				end
				atmo = parked_atmo[1] and parked_atmo[1]:Clone() or ui("Atmosphere", { Density = 0, Haze = 0, Glare = 0, Color = look.Color, Decay = look.Decay })
				atmo.Name = "VisAtmosphere"
				atmo.Parent = Lighting
			end
			tween(atmo, look, 1)
		elseif atmo then
			atmo:Destroy()
			for _, c in ipairs(parked_atmo) do c.Parent = Lighting end
			atmo, parked_atmo = nil, nil
		end
	end
	local function resky()
		local props, has = {}, S.spin
		for _, n in ipairs(order) do
			for k, v in pairs(keep(n) and FX[n].sky or {}) do props[k] = v has = true end
		end
		for k, v in pairs(SKIES[S.skybox] or {}) do props[k] = v has = true end
		if S.hide_sun then props.SunAngularSize = 0 has = true end
		if S.hide_moon then props.MoonAngularSize = 0 has = true end
		if S.hide_stars then props.StarCount = 0 has = true end
		has = has or (atmo ~= nil and (sky ~= nil or not Lighting:FindFirstChildOfClass("Sky")))
		if has then
			if not sky then
				parked_sky = {}
				for _, c in ipairs(Lighting:GetChildren()) do
					if c:IsA("Sky") then parked_sky[#parked_sky + 1] = c c.Parent = nil end
				end
				sky = parked_sky[1] and parked_sky[1]:Clone() or Instance.new("Sky")
				sky.Name = "VisSky"
				sky_base = {}
				for _, k in ipairs(SKY_KEYS) do sky_base[k] = sky[k] end
				sky.Parent = Lighting
			end
			for _, k in ipairs(SKY_KEYS) do sky[k] = props[k] ~= nil and props[k] or sky_base[k] end
		elseif sky then
			sky:Destroy()
			for _, c in ipairs(parked_sky) do c.Parent = Lighting end
			sky, parked_sky = nil, nil
		end
	end
	local function recloud()
		local c
		for _, n in ipairs(order) do c = keep(n) and FX[n].clouds or c end
		if c then
			if not clouds then
				clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
				if clouds then
					clouds_saved = { Cover = clouds.Cover, Density = clouds.Density, Color = clouds.Color, Enabled = clouds.Enabled }
				else
					clouds = ui("Clouds", { Name = "VisClouds", Cover = 0 }, workspace.Terrain)
				end
			end
			clouds.Enabled = true
			tween(clouds, c, 2)
		elseif clouds then
			if clouds_saved then
				for k, v in pairs(clouds_saved) do clouds[k] = v end
			else
				clouds:Destroy()
			end
			clouds, clouds_saved = nil, nil
		end
	end
	local function regrade()
		local g
		for _, n in ipairs(order) do g = keep(n) and FX[n].grade or g end
		if g and not gradecc then gradecc = ui("ColorCorrectionEffect", { Name = "VisGrade" }, Lighting) end
		if gradecc then tween(gradecc, g or G(WHITE, 0, 0, 0), 1) end
	end
	local M = Enum.Material
	local NATURAL = { [M.Grass] = true, [M.LeafyGrass] = true, [M.Ground] = true, [M.Mud] = true, [M.Sand] = true, [M.Snow] = true, [M.Glacier] = true }
	local SEASONS = {
		snow = {
			floor = { M.Snow, { rgb(244, 247, 252), rgb(234, 240, 250), rgb(250, 251, 255) } },
			hard  = { M.Snow, { rgb(236, 240, 247), rgb(226, 232, 242) }, 0.82 },
			leaf  = { M.Snow, { rgb(240, 245, 252), rgb(228, 236, 248), rgb(214, 226, 240) } },
			roof  = { M.Snow, { rgb(242, 246, 252) }, 0.9 },
			wood  = false, rock = false,
			terrain = { Grass = rgb(242, 246, 252), LeafyGrass = rgb(236, 242, 250), Ground = rgb(226, 232, 242), Mud = rgb(210, 218, 230), Sand = rgb(238, 240, 246),
				Rock = rgb(196, 204, 216), Slate = rgb(190, 198, 210), Pavement = rgb(222, 228, 238), Asphalt = rgb(205, 212, 224), Cobblestone = rgb(214, 220, 232) },
			water = { rgb(150, 190, 215), 0.25, 0.1 },
		},
		frost = {
			floor = { false, { rgb(214, 232, 250) }, 0.55 },
			hard  = { false, { rgb(214, 232, 250) }, 0.4 },
			leaf  = { M.Ice, { rgb(196, 222, 244), rgb(214, 232, 250) }, 0.7 },
			roof  = { false, { rgb(220, 236, 252) }, 0.5 },
			wood  = false, rock = false,
			terrain = { Grass = rgb(176, 206, 222), LeafyGrass = rgb(168, 200, 218), Ground = rgb(170, 184, 200), Sand = rgb(206, 216, 228), Rock = rgb(170, 182, 198) },
			water = { rgb(160, 205, 235), 0.15, 0.05 },
		},
		autumn = {
			grass_only = true,
			floor = { M.Grass, { rgb(176, 92, 38), rgb(196, 128, 52), rgb(150, 70, 30), rgb(170, 140, 60), rgb(128, 82, 40) } },
			hard  = false,
			leaf  = { M.LeafyGrass, { rgb(222, 96, 32), rgb(232, 150, 40), rgb(196, 54, 36), rgb(214, 176, 52), rgb(170, 70, 30) } },
			roof  = false, wood = false, rock = false,
			terrain = { Grass = rgb(184, 110, 44), LeafyGrass = rgb(202, 120, 40), Ground = rgb(122, 80, 48), Mud = rgb(100, 66, 42), Sand = rgb(196, 160, 110) },
			water = { rgb(70, 80, 56), 0.35, 0.3 },
		},
		sakura = {
			grass_only = true,
			floor = { M.Grass, { rgb(244, 190, 208), rgb(250, 210, 224), rgb(232, 170, 196) }, 0.75 },
			hard  = false,
			leaf  = { M.LeafyGrass, { rgb(255, 183, 205), rgb(255, 206, 222), rgb(240, 160, 190), rgb(255, 228, 238) } },
			roof  = false, wood = false, rock = false,
			terrain = { Grass = rgb(236, 176, 198), LeafyGrass = rgb(246, 190, 210) },
			water = { rgb(150, 190, 220), 0.3, 0.15 },
		},
		summer = {
			grass_only = true,
			floor = { M.Grass, { rgb(92, 178, 64), rgb(110, 196, 72), rgb(80, 160, 56) }, 0.8 },
			hard  = false,
			leaf  = { M.LeafyGrass, { rgb(70, 170, 60), rgb(96, 196, 70), rgb(60, 150, 50) }, 0.8 },
			roof  = false, wood = false, rock = false,
			terrain = { Grass = rgb(98, 186, 66), LeafyGrass = rgb(86, 176, 60), Ground = rgb(140, 110, 72), Sand = rgb(236, 214, 160) },
			water = { rgb(40, 150, 200), 0.45, 0.2 },
		},
		spooky = {
			grass_only = true,
			floor = { M.Ground, { rgb(80, 60, 70), rgb(66, 50, 62), rgb(96, 70, 60) }, 0.8 },
			hard  = false,
			leaf  = { M.LeafyGrass, { rgb(230, 110, 30), rgb(120, 50, 150), rgb(60, 30, 70), rgb(200, 80, 20) } },
			roof  = false, wood = false, rock = false,
			terrain = { Grass = rgb(76, 60, 70), LeafyGrass = rgb(90, 64, 80), Ground = rgb(70, 54, 50) },
			water = { rgb(60, 40, 80), 0.3, 0.3 },
		},
		withered = {
			floor = { M.Ground, { rgb(120, 104, 78), rgb(104, 92, 70), rgb(134, 118, 88) }, 0.85 },
			hard  = false,
			leaf  = { M.Ground, { rgb(110, 92, 66), rgb(92, 80, 64), rgb(128, 108, 76), rgb(80, 74, 68) } },
			roof  = false, wood = false, rock = false,
			terrain = { Grass = rgb(124, 110, 82), LeafyGrass = rgb(116, 100, 74), Ground = rgb(98, 86, 68), Mud = rgb(80, 70, 56) },
			water = { rgb(60, 66, 54), 0.4, 0.4 },
		},
	}
	local floor_mode, floor_saved, floor_terrain, floor_water = nil, {}, nil, nil
	local function in_char(p)
		local m = p:FindFirstAncestorOfClass("Model")
		while m do
			if m:FindFirstChildOfClass("Humanoid") then return true end
			m = m:FindFirstAncestorOfClass("Model")
		end
		return false
	end
	local function has(name, list)
		for _, w in ipairs(list) do if name:find(w, 1, true) then return true end end
		return false
	end
	local LEAF_WORDS = { "leaf", "leaves", "tree", "bush", "foliage", "hedge", "grass", "plant", "shrub", "canopy", "pine", "fern", "vine", "flower" }
	local WOOD_WORDS = { "trunk", "log", "branch", "stump", "bark" }
	local ROCK_WORDS = { "rock", "stone", "boulder", "cliff", "mountain" }
	local function classify(p)
		if not p:IsA("BasePart") or p:IsA("Terrain") or p.Transparency > 0.8 or p.Name == "VisFx" or p:IsDescendantOf(cam) then return nil end
		if p:FindFirstAncestorOfClass("Tool") then return nil end
		local fxf = workspace:FindFirstChild("AcesoFX")
		if fxf and p:IsDescendantOf(fxf) then return nil end
		if in_char(p) then return nil end
		local name = p.Name:lower()
		local par = p.Parent and p.Parent.Name:lower() or ""
		local mat = p.Material
		local h, s, v = p.Color:ToHSV()
		local green = h > 0.16 and h < 0.47 and s > 0.22 and v > 0.1
		local leafy = mat == M.Grass or mat == M.LeafyGrass or has(name, LEAF_WORDS) or has(par, LEAF_WORDS)
		if has(name, WOOD_WORDS) then return "wood" end
		local cf, sz = p.CFrame, p.Size
		local axes = { { math.abs(cf.RightVector.Y), sz.Y * sz.Z, sz.X }, { math.abs(cf.UpVector.Y), sz.X * sz.Z, sz.Y }, { math.abs(cf.LookVector.Y), sz.X * sz.Y, sz.Z } }
		table.sort(axes, function(a, b) return a[1] > b[1] end)
		local up = axes[1]
		local flat = up[1] > 0.85 and up[2] >= 30 and up[3] <= math.max(3, math.sqrt(up[2]) * 0.5)
		if flat then
			if leafy or green or NATURAL[mat] then return "floor" end
			return S.season_all and "hard" or nil
		end
		local thin, big = math.min(sz.X, sz.Y, sz.Z), math.max(sz.X, sz.Y, sz.Z)
		local wall = up[1] < 0.85 and thin < 2.5 and big > 6
		if wall then return nil end
		local roundish = p:IsA("MeshPart") or (p:IsA("Part") and p.Shape ~= Enum.PartType.Block) or thin > big * 0.35
		if leafy or (green and roundish and not mat.Name:find("Brick") and mat ~= M.Concrete and mat ~= M.Metal) then return S.season_trees and "leaf" or nil end
		if (p:IsA("WedgePart") or p:IsA("CornerWedgePart")) and sz.Magnitude > 8 then return "roof" end
		if mat == M.Wood or mat == M.WoodPlanks then
			if (h < 0.12 or h > 0.9) and v < 0.6 and s > 0.15 then return S.season_trees and "wood" or nil end
			return nil
		end
		if mat == M.Rock or mat == M.Slate or mat == M.Basalt or mat == M.Limestone or has(name, ROCK_WORDS) then return "rock" end
		return nil
	end
	local function floor_part(p)
		if floor_saved[p] or not floor_mode then return end
		local kind = classify(p)
		if not kind then return end
		local season = SEASONS[floor_mode]
		local spec = season[kind]
		if not spec then return end
		if kind == "floor" and season.grass_only then
			local h, sat, val = p.Color:ToHSV()
			local grassy = p.Material == M.Grass or p.Material == M.LeafyGrass or (h > 0.16 and h < 0.47 and sat > 0.22 and val > 0.1)
			if not grassy then return end
		end
		local o = { p.Material, p.Color, p.MaterialVariant, nil, nil }
		local pos = p.Position
		local cols = spec[2]
		local pick = cols[(math.floor(pos.X / 6) * 73856093 + math.floor(pos.Y / 6) * 83492791 + math.floor(pos.Z / 6) * 19349663) % #cols + 1]
		if spec[1] then p.Material = spec[1] end
		p.Color = spec[3] and p.Color:Lerp(pick, spec[3]) or pick
		pcall(function() p.MaterialVariant = "" end)
		if not spec[3] or spec[3] > 0.5 then
			for _, c in ipairs(p:GetChildren()) do
				if c:IsA("SurfaceAppearance") then
					o[4] = o[4] or {}
					o[4][#o[4] + 1] = c
					c.Parent = nil
				end
			end
			if p:IsA("MeshPart") and p.TextureID ~= "" then
				o[5] = p.TextureID
				pcall(function() p.TextureID = "" end)
			end
		end
		floor_saved[p] = o
	end
	local function unfloor()
		for p, o in pairs(floor_saved) do
			if p.Parent then
				pcall(function()
					p.Material, p.Color, p.MaterialVariant = o[1], o[2], o[3]
					if o[5] then p.TextureID = o[5] end
				end)
				for _, sa in ipairs(o[4] or {}) do pcall(function() sa.Parent = p end) end
			end
		end
		table.clear(floor_saved)
		local terrain = workspace.Terrain
		for name, col in pairs(floor_terrain or {}) do pcall(terrain.SetMaterialColor, terrain, M[name], col) end
		floor_terrain = nil
		if floor_water then
			pcall(function() terrain.WaterColor, terrain.WaterTransparency, terrain.WaterReflectance = floor_water[1], floor_water[2], floor_water[3] end)
			floor_water = nil
		end
	end
	local function refloor(force)
		local mode
		for _, n in ipairs(order) do mode = FX[n].floor or mode end
		if mode == floor_mode and not force then return end
		unfloor()
		floor_mode = mode
		if not mode then return end
		local season = SEASONS[mode]
		local terrain = workspace.Terrain
		floor_terrain = {}
		for name, col in pairs(season.terrain) do
			pcall(function()
				floor_terrain[name] = terrain:GetMaterialColor(M[name])
				terrain:SetMaterialColor(M[name], col)
			end)
		end
		pcall(function()
			floor_water = { terrain.WaterColor, terrain.WaterTransparency, terrain.WaterReflectance }
			terrain.WaterColor, terrain.WaterTransparency, terrain.WaterReflectance = season.water[1], season.water[2], season.water[3]
		end)
		task.spawn(function()
			local list = workspace:GetDescendants()
			local budget = math.floor(1500 * (Library.Quality or 1))
			for i, d in ipairs(list) do
				if floor_mode ~= mode then return end
				if d:IsA("BasePart") then pcall(floor_part, d) end
				if i % budget == 0 then task.wait() end
			end
		end)
	end
	local function season_opts() if floor_mode then refloor(true) end end
	local function refresh()
		for _, f in ipairs({ relight, reatmo, resky, recloud, regrade, refloor }) do
			local ok, err = pcall(f)
			if not ok then warn("[world] " .. tostring(err)) end
		end
	end
	local function addobj(name, obj)
		local list = objs[name]
		if not list then list = {}; objs[name] = list end
		list[#list + 1] = obj
	end
	local function paint(name)
		local list = objs[name]
		if not list then return end
		local on = active[name] ~= nil
		for _, o in ipairs(list) do
			if o:Get() ~= on then o:Set(on) end
		end
	end
	local function apply_rates()
		local k = S.intensity / 100 * (Library.Quality or 1) * 0.7
		for _, st in pairs(active) do
			for _, it in ipairs(st.em) do it[1].Rate = it[3] * k end
			if st.snd then st.snd.Volume = S.sound and FX[st.name].sound[3] * (0.4 + k * 0.6) or 0 end
		end
	end
	local function stop(name)
		local st = active[name]
		if not st then return end
		active[name] = nil
		local idx = table.find(order, name)
		if idx then table.remove(order, idx) end
		for _, p in pairs(st.parts) do
			for _, e in ipairs(p:GetChildren()) do e.Enabled = false end
			Debris:AddItem(p, 6)
		end
		for _, o in ipairs(st.objs) do o:Destroy() end
		refresh()
		paint(name)
	end
	local function start(name)
		local fx = FX[name]
		if active[name] or not fx then return end
		local st = { name = name, parts = {}, em = {}, objs = {}, t = 0 }
		active[name] = st
		order[#order + 1] = name
		local ok, err = pcall(function()
			for _, l in ipairs(fx.layers or {}) do
				local part = st.parts[l[1]]
				if not part then
					part = ghost(PLACES[l[1]][1])
					st.parts[l[1]] = part
				end
				local copies = math.max(1, math.ceil(l[2] / 600))
				for _ = 1, copies do
					local e = emitter(part, l[3])
					e.EmissionDirection = NID[PLACES[l[1]][2]]
					st.em[#st.em + 1] = { e, l, l[2] / copies }
				end
			end
			for _, p in ipairs(keep(name) and fx.post or {}) do st.objs[#st.objs + 1] = ui(p[1], p[2], Lighting) end
			if fx.sound then
				st.snd = ui("Sound", { Name = "VisSound", SoundId = "rbxassetid://" .. fx.sound[1], Looped = true, PlaybackSpeed = fx.sound[2], Volume = 0 }, cam)
				st.snd:Play()
				st.objs[#st.objs + 1] = st.snd
			end
			if fx.start then
				local cp = cam.CFrame.Position
				local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
				fx.start(st, cp, root and root.Position.Y - 3 or cp.Y - 8)
			end
		end)
		if not ok then
			warn("[world] couldn't start " .. name .. ": " .. tostring(err))
			stop(name)
			return
		end
		apply_rates()
		refresh()
		paint(name)
	end
	local function toggle(name)
		if active[name] then stop(name) else start(name) end
	end
	local function get_rig()
		if rig and rig.at.Parent then return rig end
		local at = ui("Attachment", { Name = "VisSplash" }, workspace.Terrain)
		rig = { at = at,
			puff = emitter(at, P(SPLASH, { 0 }, { 0.16, 0.24 }, seq(0, 0.22, 1, 0.8), seq(0, 0.45, 1, 1), rgb(205, 220, 240), { LightInfluence = 0.9 })),
			ring = emitter(at, P(RING, { 0.01 }, { 0.5, 0.85 }, seq(0, 0.1, 1, 1.4), seq(0, 0.3, 0.6, 0.7, 1, 1), rgb(215, 228, 245), { Orientation = PO.VelocityPerpendicular, LightInfluence = 0.85 })),
			drops = emitter(at, P(DROP, { 7, 13 }, { 0.25, 0.42 }, seq(0, 0.08, 1, 0.03), seq(0, 0.1, 1, 1), WHITE, { SpreadAngle = Vector2.new(38, 38), Acceleration = v3(0, -70, 0), Orientation = PO.VelocityParallel, Squash = NumberSequence.new(1.6), LightEmission = 0.2, LightInfluence = 0.8 })),
			mist = emitter(at, P(SOFT, { 0.5, 1.5 }, { 0.4, 0.7 }, seq(0, 0.25, 1, 0.9), seq(0, 0.8, 1, 1), rgb(220, 230, 245), { SpreadAngle = Vector2.new(60, 60), Rotation = R360, LightInfluence = 0.9 })),
			leaf = emitter(at, P(SOFT, { 0.01 }, { 8, 14 }, seq(0, 0.5, 0.9, 0.45, 1, 0), seq(0, 0.1, 0.85, 0.15, 1, 1), LEAF, { Orientation = PO.VelocityPerpendicular, Rotation = R360, Squash = NumberSequence.new(0.55), LightInfluence = 1 })),
			flake = emitter(at, P(SOFT, { 0.01 }, { 1.6, 3 }, seq(0, 0.3, 1, 0.22), seq(0, 0.25, 0.7, 0.4, 1, 1), rgb(248, 250, 255), { Orientation = PO.VelocityPerpendicular, Rotation = R360, LightEmission = 0.2 })),
		}
		return rig
	end
	local function ground_hits(cp, budget, cap, radius, fn)
		local n = math.min(math.floor(budget), cap)
		for _ = 1, n do
			local a, r = rand() * 6.283, rand() ^ 0.75 * radius
			local hit = workspace:Raycast(cp + v3(math.cos(a) * r, 60, math.sin(a) * r), v3(0, -400, 0), ray)
			if hit then
				rig.at.WorldPosition = hit.Position + hit.Normal * 0.05
				fn(hit, r)
			end
		end
		return budget - n
	end
	local clock, sb, tb, lb, last_char = 0, 0, 0, 0, nil
	conns[#conns + 1] = RunService.RenderStepped:Connect(function(dt)
		clock = clock + dt
		if not next(active) and not (sky and (S.spin or (S.drift and S.skybox ~= "none"))) and not forced_time and not S.cycle then return end
		cam = workspace.CurrentCamera
		local cp = cam.CFrame.Position
		local char = lp.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local gy = root and root.Position.Y - 3 or cp.Y - 8
		if char ~= last_char then
			last_char = char
			ray.FilterDescendantsInstances = { cam, char }
		end
		local side = S.wind < 0 and -1 or 1
		local wind = S.wind + (active["wind gusts"] and math.max(0, math.sin(clock * 0.6) + math.sin(clock * 1.7) * 0.5) * 14 * side or 0)
		local k, splash, settle = S.intensity / 100, 0, 0
		for name, st in pairs(active) do
			local fx = FX[name]
			local ok, err = pcall(function()
				st.t = st.t + dt
				for place, part in pairs(st.parts) do part.CFrame = place_cf(place, cp, wind, side, gy) end
				for _, it in ipairs(st.em) do
					local e, l = it[1], it[2]
					if l[1] == "wall" or l[1] == "wall_low" then e.EmissionDirection = side > 0 and NID.Right or NID.Left end
					if l.swirl then
						e.Acceleration = v3(math.cos(st.t * 1.3) * l.swirl, 1, math.sin(st.t * 1.3) * l.swirl)
					elseif l[4] or l[5] then
						e.Acceleration = v3(wind * (l[4] or 0), l[5] or 0, 0)
					end
					if l.pulse then e.Rate = it[3] * k * (0.1 + math.max(0, math.sin(st.t * 0.9)) ^ 2 * 1.8) end
				end
				if fx.every then
					st.next = st.next or (os.clock() + fx.every[1] * rand())
					if os.clock() >= st.next then
						st.next = os.clock() + (fx.every[1] + rand() * (fx.every[2] - fx.every[1])) * 70 / math.max(S.intensity, 10)
						fx.tick(st, cp, gy)
					end
				end
				if fx.run then fx.run(st, dt, cp, gy) end
			end)
			if ok then
				splash, settle = splash + (fx.splash or 0), settle + (fx.settle or 0)
			else
				warn("[world] " .. name .. ": " .. tostring(err))
				stop(name)
			end
		end
		local leaves = 0
		for name in pairs(active) do leaves = leaves + (FX[name].leaves or 0) end
		if leaves > 0 then
			get_rig()
			lb = ground_hits(cp, lb + dt * 14 * leaves, 6, 70, function(hit)
				if hit.Normal.Y > 0.6 and hit.Material ~= Enum.Material.Water then rig.leaf:Emit(1) end
			end)
		end
		if S.cycle then forced_time = ((forced_time or Lighting.ClockTime) + dt * S.cycle_speed / 60) % 24 end
		if forced_time and math.abs(Lighting.ClockTime - forced_time) > 0.02 then Lighting.ClockTime = forced_time end
		if S.splashes and (splash > 0 or settle > 0) then
			get_rig()
			local q = Library.Quality or 1
			sb = ground_hits(cp, sb + dt * S.intensity * 6 * splash * q, math.floor(20 * q), 55, function(hit, r)
				if hit.Normal.Y > 0.7 then rig.ring:Emit(1) end
				if hit.Material ~= Enum.Material.Water then
					rig.drops:Emit(r < 15 and 5 or (r < 30 and 3 or 1))
					if r < 25 then rig.puff:Emit(1) end
					if rand() < 0.25 then rig.mist:Emit(1) end
				end
			end)
			tb = ground_hits(cp, tb + dt * S.intensity * 1.5 * settle * q, math.floor(6 * q), 45, function(hit)
				if hit.Material ~= Enum.Material.Water then rig.flake:Emit(1) end
			end)
		end
		if sky and (S.spin or (S.drift and S.skybox ~= "none")) then
			local spd = S.spin and S.spin_speed or 0.6
			sky.SkyboxOrientation = v3(0, (clock * spd) % 360, 0)
		end
	end)
	local MC = { Brick = 10777285622, Concrete = 15622710576, CorrodedMetal = 78612695839404, Grass = 9267183930, Metal = 121650613091353,
		Sand = 12624140843, Slate = 8676746437, Wood = 3258599312, WoodPlanks = 8676581022 }
	local MC_TERRAIN = { Grass = rgb(106, 170, 64), Ground = rgb(134, 96, 67), Mud = rgb(102, 76, 51), Sand = rgb(219, 211, 160),
		Rock = rgb(122, 122, 122), Slate = rgb(90, 90, 90), Snow = rgb(245, 245, 245), Water = rgb(63, 118, 228) }
	local mc = { parts = setmetatable({}, { __mode = "k" }), variants = {}, terrain = nil }
	local function mc_part(p)
		if not p:IsA("BasePart") or p:IsA("Terrain") or p:IsDescendantOf(cam) or mc.parts[p] ~= nil or not MC[p.Material.Name] then return end
		local m = p:FindFirstAncestorOfClass("Model")
		if m and m:FindFirstChildOfClass("Humanoid") then return end
		mc.parts[p] = p.MaterialVariant
		p.MaterialVariant = "VisMC_" .. p.Material.Name
	end
	local function set_mc(on)
		local terrain = workspace.Terrain
		if on then
			for name, id in pairs(MC) do
				local v = Instance.new("MaterialVariant")
				v.Name = "VisMC_" .. name
				pcall(function()
					v.BaseMaterial = Enum.Material[name]
					v.ColorMap = "rbxassetid://" .. id
					v.StudsPerTile = 5
					v.MaterialPattern = Enum.MaterialPattern.Regular
				end)
				v.Parent = MaterialService
				mc.variants[#mc.variants + 1] = v
			end
			mc.terrain = {}
			for name, col in pairs(MC_TERRAIN) do
				pcall(function()
					mc.terrain[name] = terrain:GetMaterialColor(Enum.Material[name])
					terrain:SetMaterialColor(Enum.Material[name], col)
				end)
			end
			task.spawn(function()
				for i, d in ipairs(workspace:GetDescendants()) do
					pcall(mc_part, d)
					if i % 2000 == 0 then task.wait() end
				end
			end)
		else
			for p, old in pairs(mc.parts) do
				if p.Parent then pcall(function() p.MaterialVariant = old end) end
			end
			table.clear(mc.parts)
			for _, v in ipairs(mc.variants) do v:Destroy() end
			table.clear(mc.variants)
			for name, col in pairs(mc.terrain or {}) do pcall(function() terrain:SetMaterialColor(Enum.Material[name], col) end) end
			mc.terrain = nil
		end
	end
	local MATS, MAT_BY = {}, {}
	for _, m in ipairs(Enum.Material:GetEnumItems()) do
		if m ~= Enum.Material.Air and m ~= Enum.Material.Water then
			local n = (m.Name:gsub("(%l)(%u)", "%1 %2")):lower()
			MATS[#MATS + 1], MAT_BY[n] = n, m
		end
	end
	table.sort(MATS)
	local originals, terrain_saved, tech_orig = {}, nil, nil
	local function world_color() return hue(S.world_h, rgb(176, 214, 248)) end
	local function style(p)
		if not p:IsA("BasePart") or p:IsA("Terrain") or p.Name == "VisFx" or p:IsDescendantOf(cam) then return end
		local m = p:FindFirstAncestorOfClass("Model")
		while m do
			if m:FindFirstChildOfClass("Humanoid") then return end
			m = m:FindFirstAncestorOfClass("Model")
		end
		local on, o = S.mat_on or S.recolor_on, originals[p]
		if not o then
			if not on then return end
			o = { p.Material, p.Color }
			originals[p] = o
		end
		p.Material = S.mat_on and MAT_BY[S.mat] or o[1]
		p.Color = S.recolor_on and world_color() or o[2]
		if not on then originals[p] = nil end
	end
	local function repaint(full)
		if full then
			task.spawn(function()
				for i, d in ipairs(workspace:GetDescendants()) do
					pcall(style, d)
					if i % 2000 == 0 then task.wait() end
				end
			end)
		else
			for p in pairs(originals) do
				if p.Parent then pcall(style, p) else originals[p] = nil end
			end
		end
	end
	local function paint_terrain()
		local terrain = workspace.Terrain
		if S.terrain_on then
			if not terrain_saved then
				terrain_saved = {}
				for _, m in ipairs(Enum.Material:GetEnumItems()) do
					local ok, c = pcall(terrain.GetMaterialColor, terrain, m)
					if ok then terrain_saved[m] = c end
				end
			end
			for m in pairs(terrain_saved) do pcall(terrain.SetMaterialColor, terrain, m, world_color()) end
		elseif terrain_saved then
			for m, c in pairs(terrain_saved) do pcall(terrain.SetMaterialColor, terrain, m, c) end
			terrain_saved = nil
		end
	end
	conns[#conns + 1] = workspace.DescendantAdded:Connect(function(d)
		if not (floor_mode or S.mc or S.mat_on or S.recolor_on) or not d:IsA("BasePart") then return end
		task.defer(function()
			if floor_mode then pcall(floor_part, d) end
			if S.mc then pcall(mc_part, d) end
			if S.mat_on or S.recolor_on then pcall(style, d) end
		end)
	end)
	local function set_tech()
		if not sethiddenproperty then return end
		tech_orig = tech_orig or Lighting.Technology
		pcall(sethiddenproperty, Lighting, "Technology", S.tech == "default" and tech_orig or Enum.Technology[S.tech])
	end
	local CRUNCH = { 128551000876862, 104023118530628, 123155171379155 }
	local snow = { steps = {}, t = 0, i = 1, muted = nil }
	local function snow_off()
		for _, x in ipairs(snow.steps) do x:Destroy() end
		table.clear(snow.steps)
		if snow.muted then
			if snow.muted[1].Parent then snow.muted[1].Volume = snow.muted[2] end
			snow.muted = nil
		end
	end
	conns[#conns + 1] = RunService.Heartbeat:Connect(function(dt)
		if not (S.snow_sfx and (active["snowfall"] or active["blizzard"] or active["whiteout"] or active["winter"] or active["thundersnow"])) then
			if snow.muted or #snow.steps > 0 then snow_off() end
			return
		end
		local char = lp.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not hum or not root then return end
		local running = root:FindFirstChild("Running")
		if running and running:IsA("Sound") and (not snow.muted or snow.muted[1] ~= running) then
			if snow.muted and snow.muted[1].Parent then snow.muted[1].Volume = snow.muted[2] end
			snow.muted = { running, running.Volume }
			running.Volume = 0
		end
		if hum.MoveDirection.Magnitude < 0.1 or hum.FloorMaterial == Enum.Material.Air then
			snow.t = 0.12
			return
		end
		snow.t = snow.t - dt
		if snow.t > 0 then return end
		snow.t = 0.33 * 16 / math.max(hum.WalkSpeed, 4)
		if #snow.steps == 0 then
			for i, id in ipairs(CRUNCH) do
				snow.steps[i] = ui("Sound", { Name = "VisStep", SoundId = "rbxassetid://" .. id, Volume = 0.6, RollOffMaxDistance = 60 }, root)
			end
		end
		local x = snow.steps[snow.i]
		snow.i = snow.i % #snow.steps + 1
		if x.Parent ~= root then x.Parent = root end
		x.PlaybackSpeed = 0.9 + rand() * 0.2
		x:Play()
	end)
	local trail_objs, trail_fx = {}, {}
	local SOURCES = { body = { { "HumanoidRootPart" } }, feet = { { "LeftFoot", "Left Leg" }, { "RightFoot", "Right Leg" } }, hands = { { "LeftHand", "Left Arm" }, { "RightHand", "Right Arm" } } }
	local function trail_colors()
		if S.trail_rainbow then
			local h = os.clock() * 0.2
			return ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromHSV(h % 1, 0.75, 1)),
				ColorSequenceKeypoint.new(0.5, Color3.fromHSV((h + 0.12) % 1, 0.75, 1)), ColorSequenceKeypoint.new(1, Color3.fromHSV((h + 0.24) % 1, 0.75, 1)) })
		end
		return ColorSequence.new(hue(S.trail_h, rgb(176, 214, 248)), hue(S.trail_h2, WHITE))
	end
	local function build_trail()
		for _, o in ipairs(trail_objs) do o:Destroy() end
		table.clear(trail_objs)
		table.clear(trail_fx)
		local char = lp.Character
		if not S.trail_on or not char then return end
		local half = (S.trail_src == "body" and S.trail_width or S.trail_width / 2) / 2
		for _, names in ipairs(SOURCES[S.trail_src]) do
			local part = char:FindFirstChild(names[1]) or (names[2] and char:FindFirstChild(names[2]))
			if part then
				local base = part.Name:find(" ") and v3(0, -part.Size.Y / 2 + 0.3, 0) or v3(0, 0, 0)
				local a0 = ui("Attachment", { Name = "VisTrail", Position = base + v3(0, half, 0) }, part)
				local a1 = ui("Attachment", { Name = "VisTrail", Position = base - v3(0, half, 0) }, part)
				local t = ui("Trail", { Name = "VisTrail", Attachment0 = a0, Attachment1 = a1, Lifetime = S.trail_len, MinLength = 0.05, FaceCamera = true,
					LightEmission = S.trail_glow and 0.8 or 0, LightInfluence = S.trail_glow and 0 or 1, Color = trail_colors(),
					Transparency = seq(0, 1 - S.trail_opacity / 100, 1, 1), WidthScale = seq(0, 1, 1, S.trail_taper / 100) }, part)
				for _, o in ipairs({ a0, a1, t }) do trail_objs[#trail_objs + 1] = o end
				trail_fx[#trail_fx + 1] = t
				if S.trail_sparkles then
					trail_fx[#trail_fx + 1] = emitter(a0, P(DROP, { 0.5, 1.5 }, { 0.4, 0.8 }, seq(0, 0, 0.3, 0.11 * S.trail_width, 1, 0), 0, t.Color,
						{ SpreadAngle = Vector2.new(180, 180), Drag = 3, LightEmission = 1, LightInfluence = 0 }), 14)
				end
			end
		end
	end
	local trailT = 0
	conns[#conns + 1] = RunService.Heartbeat:Connect(function()
		if not (S.trail_on and S.trail_rainbow) then return end
		local now = os.clock()
		if now - trailT < 0.05 then return end
		trailT = now
		local c = trail_colors()
		for _, f in ipairs(trail_fx) do
			if f.Parent then f.Color = c end
		end
	end)
	conns[#conns + 1] = lp.CharacterAdded:Connect(function(char)
		char:WaitForChild("HumanoidRootPart", 10)
		task.wait(0.2)
		build_trail()
	end)
	local function reset()
		for _, n in ipairs({ table.unpack(order) }) do stop(n) end
		if S.mc then set_mc(false) end
		for _, k in ipairs({ "cycle", "sky3d", "mc", "time_on", "spin", "hide_sun", "hide_moon", "hide_stars", "tint_on", "fog_on", "mat_on", "recolor_on", "terrain_on", "amb_on", "trail_on" }) do S[k] = false end
		S.skybox, S.tech = "none", "default"
		repaint(false)
		paint_terrain()
		build_trail()
		set_tech()
		snow_off()
		refresh()
		for _, f in ipairs(syncfns) do pcall(f) end
	end
	local function random_mix()
		for _, n in ipairs({ table.unpack(order) }) do stop(n) end
		for _, i in ipairs({ 1, 2, 5 }) do
			local pool = {}
			for _, it in ipairs(CATS[i][2]) do
				if type(it) == "string" then pool[#pool + 1] = it end
			end
			if #pool > 0 then start(pool[rand(1, #pool)]) end
		end
	end
	local CLEAR = { clear = true }
	local function sl(label, key, min, max, step, on) return { slider = label, key = key, min = min, max = max, step = step, on = on } end
	local function ck(label, key, on) return { check = label, key = key, on = on or function() end } end
	local function col(label, key, on) return { color = label, key = key, on = on } end
	local function atm() pcall(reatmo) pcall(resky) end
	CATS = {
		{ "weather", { CLEAR, "drizzle", "light rain", "original rain", "heavy rain", "thunderstorm", "monsoon", "storm front", "thundersnow", "firestorm", "hail", "blizzard", "whiteout", "sandstorm", "tornado", "acid rain", "snowfall",
			"shooting stars", "meteor shower", "comet", "starfall", "aurora", "blood moon", "eclipse", "celestial", "moonlight", "starlight",
			ck("weather changes sky & light", "weather_only_off", function(v) S.weather_only = not v; refresh() end), sl("intensity", "intensity", 5, 100, 5, apply_rates), sl("wind", "wind", -30, 30, 1), ck("sound", "sound", apply_rates), ck("splashes", "splashes"), ck("snow footsteps", "snow_sfx") } },
		{ "sky", { { skybox = true }, CLEAR, "clouds", "cloud ceiling", "eclipse", "blood moon", "aurora", "celestial", "shooting stars", "meteor shower", "meteors", "comet", "starfall",
			"night", "midnight", "3d clouds", "3d sky", "sunrise", "sunset", "golden hour", "blue hour", "moonlight", "starlight",
			ck("fast spin", "spin", resky), sl("spin speed", "spin_speed", 1, 60, 1),
			ck("hide sun", "hide_sun", resky), ck("hide moon", "hide_moon", resky), ck("hide stars", "hide_stars", resky),
			ck("sky tint", "tint_on", atm), col("tint colour", "tint_h", atm),
			ck("day / night cycle", "cycle", relight), sl("cycle speed (hours per minute)", "cycle_speed", 0.2, 30, 0.2),
			ck("custom time", "time_on", relight), sl("time", "time", 0, 24, 0.25, function() if S.time_on then relight() end end),
			sl("3d cloud count", "cloud_count", 6, 60, 1), sl("3d cloud height", "cloud_height", 120, 600, 10) } },
		{ "fog", { CLEAR, "fog", "dense fog", "valley fog", "rain mist", "smoke", "ground smoke", "black smoke", "heat haze", "atmosphere",
			ck("custom fog", "fog_on", atm), sl("density", "fog_density", 0, 1, 0.01, atm), sl("start", "fog_offset", 0, 1, 0.01, atm),
			sl("haze", "fog_haze", 0, 10, 0.1, atm), sl("sun glare", "fog_glare", 0, 10, 0.1, atm), col("fog colour", "fog_h", atm) } },
		{ "light", { CLEAR, "sun rays", "god rays", "shadows", "fullbright", "bloom", "motion blur", "lightning", "light flashes", "impact flashes",
			sl("motion blur strength", "mb_strength", 0.2, 3, 0.1), sl("motion blur max", "mb_max", 2, 30, 1),
			ck("ambient colour", "amb_on", relight), col("ambient tint", "amb_h", relight),
			{ cycle = "tech", key = "tech", options = { "default", "Voxel", "ShadowMap", "Future", "Compatibility" }, on = set_tech } } },
		{ "particle", { CLEAR, "embers", "ambient dust", "floating spores", "glowing particles", "magic dust", "fireflies", "butterflies", "rain splashes" } },
		{ "season", { CLEAR, "winter", "fall", "spring", "summer", "spooky", "snow floor", "frost floor", "autumn floor", "sakura floor", "withered floor", "sakura", "sakura bloom", "sakura petals", "sakura haze", "sakura fog", "sakura wind", "cherry blossom storm",
			"autumn", "autumn leaves", "autumn swirl", "autumn gusts", "autumn fog", "leaves storm", "pollen",
			ck("paint every floor", "season_all", season_opts), ck("paint trees and bushes", "season_trees", season_opts) } },
		{ "events", { CLEAR, "inferno", "inferno meteors", "inferno ash", "firestorm", "volcanic ash", "volcanic eruption", "ufo event", "halloween" } },
		{ "vibes", { CLEAR, { button = "random mix", fn = random_mix }, "noir", "vaporwave", "dreamy", "cinematic", "horror", "underwater", "matrix", "rainbow", "disco" } },
		{ "wind", { "wind gusts", sl("wind", "wind", -30, 30, 1) } },
		{ "world", {
			ck("minecraft textures", "mc", set_mc),
			ck("override material", "mat_on", repaint), { cycle = "material", key = "mat", options = MATS, on = function() if S.mat_on then repaint(true) end end },
			ck("recolour world", "recolor_on", repaint), ck("recolour terrain", "terrain_on", paint_terrain),
			col("world colour", "world_h", function() repaint(false) paint_terrain() end),
			{ button = "restore all", fn = reset },
		} },
		{ "trail", { ck("trail", "trail_on", build_trail), col("trail colour", "trail_h", build_trail), col("fade colour", "trail_h2", build_trail),
			sl("length", "trail_len", 0.1, 3, 0.1, build_trail), sl("width", "trail_width", 0.4, 5, 0.1, build_trail), ck("glow", "trail_glow", build_trail),
			{ cycle = "from", key = "trail_src", options = { "body", "feet", "hands" }, on = build_trail }, ck("rainbow", "trail_rainbow", build_trail),
			ck("sparkles", "trail_sparkles", build_trail), sl("opacity", "trail_opacity", 10, 100, 5, build_trail), sl("end width", "trail_taper", 0, 100, 5, build_trail) } },
	}
	local DISPLAY = {
		weather = "Weather", sky = "Sky", fog = "Fog", light = "Lighting",
		particle = "Particles", season = "Seasonal", events = "Events", vibes = "Vibes",
		wind = "Wind", world = "World", trail = "Trail",
	}
	local function Title(s)
		return (s:gsub("(%a)([%w']*)", function(a, b) return a:upper() .. b end))
	end
	local function dec(step)
		if step >= 1 then return 0 end
		if step >= 0.1 then return 1 end
		return 2
	end
	local function BuildUI(sub, key)
		local items
		for _, c in ipairs(CATS) do
			if c[1] == key then items = c[2] end
		end
		if not items then return end
		local effects, controls = {}, {}
		for _, it in ipairs(items) do
			if type(it) == "table" and it.skybox then
				local sb = sub:Section({ Name = "Skybox", Side = "Left" })
				local function relayer()
					stop("sky layer")
					if S.sky3d then start("sky layer") end
				end
				local list = sb:List({ Name = "Skybox", Flag = "VisSkybox", Height = math.min(#SKY_NAMES * 22 + 10, 260), Options = SKY_NAMES, Default = S.skybox,
					Callback = function(v) S.skybox = v or "none"; resky(); if S.sky3d then relayer() end end })
				sb:Toggle({ Name = "3D layer (clouds, stars, shooting stars)", Flag = "VisSky3D", Default = S.sky3d, Callback = function(v) S.sky3d = v; relayer() end })
				list.Save = true
				sb:Toggle({ Name = "Slow drift", Flag = "VisSkyDrift", Default = S.drift, Callback = function(v) S.drift = v; if not v and sky and not S.spin then sky.SkyboxOrientation = v3() end end })
				sb:Label("only swaps the sky picture. the 3d layer adds matching clouds, stars and shooting stars on top. light, fog and colours stay the game's own.")
				syncfns[#syncfns + 1] = function() if list:Get() ~= S.skybox then list:Set(S.skybox) end end
			end
		end
		for _, it in ipairs(items) do
			if type(it) == "table" and it.skybox then
			elseif type(it) == "string" then
				effects[#effects + 1] = it
			elseif not it.clear then
				controls[#controls + 1] = it
			end
		end
		if #effects > 0 then
			local sec = sub:Section({ Name = Title(key), Side = "Left" })
			for _, name in ipairs(effects) do
				local obj = sec:Toggle({
					Name = Title(name), Flag = "Vis_" .. key .. "_" .. name, Default = false,
					Callback = function(v) if v then start(name) else stop(name) end end,
				})
				addobj(name, obj)
			end
			sec:Button({ Name = "Clear", Callback = function() for _, name in ipairs(effects) do stop(name) end end })
		end
		local ctl = sub:Section({ Name = Title(key) .. " Settings", Side = #effects > 0 and "Right" or "Left" })
		for _, it in ipairs(controls) do
			local obj
			if it.slider then
				obj = ctl:Slider({ Name = Title(it.slider), Flag = "VisCfg_" .. key .. "_" .. it.key, Min = it.min, Max = it.max, Default = S[it.key], Decimals = dec(it.step),
					Callback = function(v) S[it.key] = v; if it.on then it.on(v) end end })
			elseif it.check then
				obj = ctl:Toggle({ Name = Title(it.check), Flag = "VisCfg_" .. key .. "_" .. it.key, Default = S[it.key] == true,
					Callback = function(v) S[it.key] = v; if it.on then it.on(v) end end })
			elseif it.cycle then
				obj = ctl:Dropdown({ Name = Title(it.cycle), Flag = "VisCfg_" .. key .. "_" .. it.key, Options = it.options, Default = S[it.key],
					Callback = function(v) S[it.key] = v; if it.on then it.on() end end })
			elseif it.color then
				obj = ctl:Colorpicker({ Name = it.color, Flag = "VisCfg_" .. key .. "_" .. it.key, Default = S[it.key],
					Callback = function(c) S[it.key] = c; if it.on then it.on() end end })
			elseif it.button then
				ctl:Button({ Name = Title(it.button), Callback = it.fn })
			end
			if obj then
				local o, k = obj, it.key
				syncfns[#syncfns + 1] = function() if o:Get() ~= S[k] then o:Set(S[k]) end end
			end
		end
	end
	local function unload()
		pcall(reset)
		pcall(snow_off)
		for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
		table.clear(conns)
		if gradecc then gradecc:Destroy() end
		if flashcc then flashcc:Destroy() end
		if rig then rig.at:Destroy() end
	end
	local function SetSky3D(v)
		S.sky3d = v
		stop("sky layer")
		if v then start("sky layer") end
	end
	local function ActiveCount() local n = 0; for _ in pairs(active) do n = n + 1 end; return n end
	return { SetSky3D = SetSky3D, ActiveCount = ActiveCount, BuildUI = BuildUI, Displays = DISPLAY, Toggle = toggle, Start = start, Stop = stop, Reset = reset, Unload = unload, S = S, Active = active }
end)()
Library:LoaderStep("building the menu", 0.62)
local Win = Library:Window({ Title = "aceso", Subtitle = "v20", Width = 1000, Height = 640 })
Win.Main.Visible = false
local Home = Win:Tab({ Name = "Home", Desc = "your session at a glance" })
do
	local Hello = Home:Section({ Name = "Welcome", Side = "Left" })
	local Hour = tonumber(os.date("%H")) or 12
	local Greet = Hour < 5 and "late night" or (Hour < 12 and "good morning" or (Hour < 18 and "good afternoon" or "good evening"))
	Hello:Label(("%s, %s.\nonly you see any of this. %s hides the menu."):format(Greet, LocalPlayer.DisplayName, Library.MenuKey.Name:lower()))
	local Live = Home:Section({ Name = "Live", Side = "Left" })
	local StatLbl = Live:Label("...")
	local Frames, Acc, Started = 0, 0, os.clock()
	Library:Connect(RunService.RenderStepped, function(Dt)
		if not (Win.Main.Visible and Home.Container.Visible) then Frames, Acc = 0, 0 return end
		Frames, Acc = Frames + 1, Acc + Dt
		if Acc < 0.5 then return end
		local Fps = math.floor(Frames / Acc + 0.5)
		Frames, Acc = 0, 0
		local Ping = 0
		pcall(function() Ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5) end)
		local Up = math.floor(os.clock() - Started)
		local Beams = Skins.CountOn and select(1, Skins.CountOn("Beam")) or 0
		StatLbl:Set(("<font size=\"15\"><b>%d</b></font> fps     <font size=\"15\"><b>%d</b></font> ms     <font size=\"15\"><b>%d</b></font> players\nsession %dm %02ds  /  %d world effects on  /  beams on %d guns")
			:format(Fps, Ping, #Players:GetPlayers(), math.floor(Up / 60), Up % 60, World.ActiveCount and World.ActiveCount() or 0, Beams))
	end)
	local Quick = Home:Section({ Name = "Quick switches", Side = "Right" })
	Quick:Toggle({ Name = "Custom beams on every gun", Flag = "__HomeBeams", Save = false, Callback = function(V) pcall(Skins.SetAll, "Beam", V) end })
	Quick:Toggle({ Name = "Gun particles on every gun", Flag = "__HomeParts", Save = false, Callback = function(V) pcall(Skins.SetAll, "PartOn", V) end })
	Quick:Toggle({ Name = "3D sky layer", Flag = "__HomeSky3D", Save = false, Callback = function(V) pcall(World.SetSky3D, V) end })
	Quick:Button({ Name = "Open beam editor", Accent = true, Callback = function() Skins.OpenStudio("Beam") end })
		:Button({ Name = "Open skin editor", Callback = function() Skins.OpenStudio("Skin") end })
	Quick:Button({ Name = "Clear all world effects", Risky = true, Callback = function() pcall(World.Reset) end })
	local News = Home:Section({ Name = "What's new in v20", Side = "Right" })
	News:Label("- previews: guns shown side-on with the barrel to the right, avatars face the camera\n- no fps unlocker any more: aceso never touches your fps cap, not even on unload\n- new menu ported from serotonin: teal accent, folder tabs, section headers, square checkboxes, fill sliders\n- every preview (guns, beams, avatars) is one fixed size and holds still\n- ctrl+click a slider to type a value\n- reworked controls: springy toggles, pill value boxes, rotating dropdown chevrons, soft row highlight on hover\n- dropdown menus pop open with a check mark on the picked option\n- solid white primary buttons\n- search everything: the bar up top (or press /) finds any setting, jumps there and highlights it\n- hover a beam preset to preview it live before applying\n- 3d avatar previews in character\n- living menu background: snow, stars, fireflies, sakura, embers\n- cinematic menu, animated tab icons, hover previews, sounds")
end
local SkinsTab = Win:Tab({ Name = "Skin changer", Desc = "gun skins, custom models, particles, beams  -  'open editor' for the big editor" })
local Ok, Err = pcall(Skins.Build, SkinsTab)
if not Ok then warn("[aceso skins] " .. tostring(Err)) end
Library:LoaderStep("skin changer ready", 0.7)
local CharTab = Win:Tab({ Name = "Character", Desc = "headless, korblox, outfits, animations" })
Ok, Err = pcall(Char.Build, CharTab)
if not Ok then warn("[aceso char] " .. tostring(Err)) end
Library:LoaderStep("character ready", 0.76)
local WorldTab = Win:Tab({ Name = "World", Desc = "weather, sky, seasons, lighting, kill effects" })
for _, Key in ipairs({ "weather", "sky", "fog", "light", "particle", "season", "events", "vibes", "wind", "world", "trail" }) do
	local Sub = WorldTab:SubTab({ Name = World.Displays[Key] })
	local Ok2, Err2 = pcall(World.BuildUI, Sub, Key)
	if not Ok2 then
		warn("[aceso world] " .. tostring(Err2))
		pcall(function() Sub:Section({ Name = World.Displays[Key] }):Label({ Text = "error: " .. tostring(Err2) }) end)
	end
end
do
	local KillSub = WorldTab:SubTab({ Name = "Kill effects" })
	local Ok3, Err3 = pcall(Effects.Build, KillSub)
	if not Ok3 then warn("[aceso effects] " .. tostring(Err3)) end
end
if WorldTab.SubTabs[1] then WorldTab:SelectSub(WorldTab.SubTabs[1]) end
Library:LoaderStep("world ready", 0.82)
local Settings = Win:Tab({ Name = "Settings", Desc = "configs, keys, performance" })
local Cfg = Settings:Section({ Name = "Configs", Side = "Left" })
local List = Cfg:List({ Name = "Configs", Height = 180, Options = Library:GetConfigs(), Flag = "__ConfigList", Save = false })
local NameBox = Cfg:Textbox({ Name = "Config name", Placeholder = "name for save as..", Flag = "__ConfigName", Save = false })
local function Target() local N = NameBox:Get(); if N ~= "" then return N end; return List:Get() end
local function Refresh() List:SetOptions(Library:GetConfigs()) end
Cfg:Button({ Name = "Save", Callback = function()
	local N = Target()
	if N then Library:SaveConfig(N) end
	Refresh()
end }):Button({ Name = "Load", Callback = function()
	local N = Target()
	if N then Library:LoadConfig(N) end
end })
Cfg:Button({ Name = "Delete", Risky = true, Confirm = true, Callback = function()
	local N = Target()
	if N then Library:DeleteConfig(N) end
	Refresh()
end }):Button({ Name = "Refresh", Callback = Refresh })
local Menu = Settings:Section({ Name = "Keys", Side = "Right" })
Menu:Keybind({ Name = "Menu key", Flag = "MenuKeybind", Default = Library.MenuKey, NoList = true, Changed = function(K) if K then Library.MenuKey = K end end })
Menu:Keybind({ Name = "Editor key", Flag = "StudioKeybind", NoList = true, Callback = function() Skins.Studio:Toggle() end, Mode = "Toggle" })
local AutoQ = true
local QualLbl
local Perf = Settings:Section({ Name = "Performance", Side = "Right" })
Perf:Dropdown({ Name = "Effects quality", Flag = "FxQuality", Options = { "Auto", "High", "Medium", "Low", "Potato" }, Default = "Auto", Callback = function(V)
	AutoQ = V == "Auto"
	if not AutoQ then Library.Quality = (V == "Potato" and 0.3) or (V == "Low" and 0.5) or (V == "Medium" and 0.75) or 1 end
end })
QualLbl = Perf:Label("auto keeps your fps up by lowering effect detail when the game struggles, and raising it again when there's room.")
do
	local Frames, Acc = 0, 0
	Library:Connect(RunService.RenderStepped, function(Dt)
		if not AutoQ then return end
		Frames, Acc = Frames + 1, Acc + Dt
		if Acc < 2 then return end
		local Fps = Frames / Acc
		Frames, Acc = 0, 0
		local Q = Library.Quality or 1
		if Fps < 42 then Q = math.max(0.3, Q - 0.15)
		elseif Fps > 75 then Q = math.min(1, Q + 0.05) end
		Library.Quality = Q
		if QualLbl and Library.Open then QualLbl:Set(("auto: %d fps right now, effect detail %d%%"):format(math.floor(Fps + 0.5), math.floor(Q * 100 + 0.5))) end
	end)
end
local AutoSave = true
Cfg:Toggle({ Name = "Auto save my setup", Flag = "__AutoSave", Default = true, Save = false, Callback = function(V) AutoSave = V end })
Cfg:Label("saves everything every 30 seconds and loads it back the next time you run aceso.")
task.spawn(function()
	while Gui.Parent do
		task.wait(30)
		if AutoSave and not Library._Loading then pcall(function() Library:SaveConfig("autosave") end) end
	end
end)
Library:OnUnloadLater(function() if AutoSave then pcall(function() Library:SaveConfig("autosave") end) end end)
local Danger = Settings:Section({ Name = "Unload", Side = "Left", Risky = true })
Danger:Button({ Name = "Unload aceso", Risky = true, Confirm = true, Callback = function() Library:Unload() end })
Library:OnUnload(function() pcall(World.Unload) end)
Library:OnUnload(function() pcall(Char.Unload) end)
Library:OnUnload(function() pcall(Skins.Unload) end)
Library:OnUnload(function() pcall(Effects.Unload) end)
Library:LoaderStep("finding the game's guns and skins", 0.88)
local T0 = os.clock()
while not Skins.Ready() and os.clock() - T0 < 6 do task.wait(0.1) end
if isfile and pcall(isfile, Library.ConfigFolder .. "/autosave.json") and isfile(Library.ConfigFolder .. "/autosave.json") then
	Library:LoaderStep("restoring your last setup", 0.93)
	pcall(function() Library:LoadConfig("autosave") end)
end
Library:LoaderStep("loading previews", 0.96)
pcall(Skins.Refresh)
task.wait(0.15)
Library:LoaderDone(function()
	Win:SetVisible(true)
end)
return Library
