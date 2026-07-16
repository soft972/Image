-- Gui to Lua V5.1 (Shadow Edition)
-- GUI : ScreenGui

local Players   = game:GetService('Players')
local player    = Players.LocalPlayer
local PlayerGui = player:WaitForChild('PlayerGui')

local _old = PlayerGui:FindFirstChild([[ScreenGui]])
if _old then _old:Destroy() end

local _i = {}

-- Instances:

_i[1] = Instance.new("ScreenGui")
_i[1].DisplayOrder = 0
_i[1].Enabled = true
_i[1].IgnoreGuiInset = false
_i[1].ResetOnSpawn = true
_i[1].Name = [[ScreenGui]]

_i[2] = Instance.new("Frame")
_i[2].AnchorPoint = Vector2.new(0,0)
_i[2].BackgroundColor3 = Color3.fromRGB(255,255,255)
_i[2].BackgroundTransparency = 0
_i[2].BorderColor3 = Color3.fromRGB(0,0,0)
_i[2].BorderSizePixel = 0
_i[2].ClipsDescendants = false
_i[2].LayoutOrder = 0
_i[2].Position = UDim2.new(0.324856,0,0.25359,0)
_i[2].Rotation = 0
_i[2].Selectable = false
_i[2].Size = UDim2.new(0.349488,0,0.491188,0)
_i[2].SizeConstraint = Enum.SizeConstraint.RelativeXY
_i[2].Visible = true
_i[2].ZIndex = 1
_i[2].Name = [[Frame]]
_i[2].Parent = _i[1]

_i[3] = Instance.new("UICorner")
_i[3].CornerRadius = UDim.new(0,8)
_i[3].BottomLeftRadius = UDim.new(0,8)
_i[3].BottomRightRadius = UDim.new(0,8)
_i[3].TopLeftRadius = UDim.new(0,8)
_i[3].TopRightRadius = UDim.new(0,8)
_i[3].Name = [[UICorner]]
_i[3].Parent = _i[2]

_i[4] = Instance.new("TextLabel")
_i[4].AnchorPoint = Vector2.new(0,0)
_i[4].BackgroundColor3 = Color3.fromRGB(255,255,255)
_i[4].BackgroundTransparency = 1
_i[4].BorderColor3 = Color3.fromRGB(0,0,0)
_i[4].BorderSizePixel = 0
_i[4].ClipsDescendants = false
_i[4].LayoutOrder = 0
_i[4].Position = UDim2.new(0.0411899,0,0,0)
_i[4].Rotation = 0
_i[4].Selectable = false
_i[4].Size = UDim2.new(0.938215,0,0.166113,0)
_i[4].SizeConstraint = Enum.SizeConstraint.RelativeXY
_i[4].Visible = true
_i[4].ZIndex = 1
_i[4].Font = Enum.Font.SourceSansBold
_i[4].LineHeight = 1
_i[4].MaxVisibleGraphemes = -1
_i[4].RichText = false
_i[4].Text = [[500000000000000000]]
_i[4].TextColor3 = Color3.fromRGB(255,255,255)
_i[4].TextScaled = true
_i[4].TextSize = 14
_i[4].TextStrokeColor3 = Color3.fromRGB(0,0,0)
_i[4].TextStrokeTransparency = 1
_i[4].TextTransparency = 0
_i[4].TextTruncate = Enum.TextTruncate.None
_i[4].TextWrapped = true
_i[4].TextXAlignment = Enum.TextXAlignment.Center
_i[4].TextYAlignment = Enum.TextYAlignment.Center
_i[4].Name = [[TextLabel]]
_i[4].Parent = _i[2]

_i[5] = Instance.new("UIGradient")
_i[5].Color = ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(107,107,107)),ColorSequenceKeypoint.new(1,Color3.fromRGB(57,57,57))})
_i[5].Enabled = true
_i[5].Offset = Vector2.new(0,0)
_i[5].Rotation = 90
_i[5].Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(1,0,0)})
_i[5].Name = [[UIGradient]]
_i[5].Parent = _i[2]

_i[6] = Instance.new("UIStroke")
_i[6].ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
_i[6].Color = Color3.fromRGB(0,0,0)
_i[6].Enabled = true
_i[6].LineJoinMode = Enum.LineJoinMode.Round
_i[6].Thickness = 3.200000047683716
_i[6].Transparency = 0
_i[6].Name = [[UIStroke]]
_i[6].Parent = _i[2]

_i[7] = Instance.new("UIShadow")
_i[7].BlurRadius = UDim.new(0,50)
_i[7].Color = Color3.fromRGB(0,0,0)
_i[7].Enabled = true
_i[7].Offset = UDim2.new(0,0,0,0)
_i[7].Spread = UDim2.new(0,0,0,0)
_i[7].Transparency = 0.5
_i[7].ZIndex = -1
_i[7].Name = [[UIShadow]]
_i[7].Parent = _i[2]


-- FAKE REQUIRE SYSTEM FOR MODULES
local _modules = {}
local old_require = require
local require = function(module)
	if _modules[module] then
		if type(_modules[module]) == 'function' then
			_modules[module] = _modules[module]()
		end
		return _modules[module]
	end
	return old_require(module)
end

-- Scripts:


_i[1].Parent = PlayerGui
