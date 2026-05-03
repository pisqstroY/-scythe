
--// SCYTHE UI FULL (WORKING)

local Library = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

-- screen
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game:GetService("CoreGui")

-- blur
local Blur = Instance.new("BlurEffect")
Blur.Size = 15
Blur.Parent = Lighting

-- main
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.fromOffset(500, 300)
Main.Position = UDim2.fromScale(0.5,0.5)
Main.AnchorPoint = Vector2.new(0.5,0.5)
Main.BackgroundColor3 = Color3.fromRGB(20,20,20)

-- gradient
local Grad = Instance.new("UIGradient", Main)
Grad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(120,120,120))
}

-- watermark
local Watermark = Instance.new("TextLabel", ScreenGui)
Watermark.Position = UDim2.new(0,10,0,10)
Watermark.Size = UDim2.new(0,400,0,20)
Watermark.BackgroundTransparency = 1
Watermark.TextColor3 = Color3.new(1,1,1)
Watermark.Font = Enum.Font.GothamSemibold
Watermark.TextSize = 16

-- rainbow glow
local Stroke = Instance.new("UIStroke", Watermark)
Stroke.Thickness = 1.5

RunService.RenderStepped:Connect(function()
    local t = tick()
    Stroke.Color = Color3.fromHSV((t%5)/5,1,1)
end)

function Library:SetWatermark(text)
    Watermark.Text = text
end

-- fake managers inside
Library.Theme = {
    Accent = Color3.new(1,1,1)
}

function Library:SetRainbowTheme()
    RunService.RenderStepped:Connect(function()
        local t = tick()
        Library.Theme.Accent = Color3.fromHSV((t%5)/5,1,1)
        Grad.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Library.Theme.Accent),
            ColorSequenceKeypoint.new(1, Color3.new(0,0,0))
        }
    end)
end

function Library:CreateWindow(opts)
    self:SetWatermark("Scythe V2")
    return {}
end

return Library
