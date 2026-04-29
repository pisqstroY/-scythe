-- ███████╗ ██████╗██╗   ██╗████████╗██╗  ██╗███████╗
-- ██╔════╝██╔════╝╚██╗ ██╔╝╚══██╔══╝██║  ██║██╔════╝
-- ███████╗██║      ╚████╔╝    ██║   ███████║█████╗
-- ╚════██║██║       ╚██╔╝     ██║   ██╔══██║██╔══╝
-- ███████║╚██████╗   ██║      ██║   ██║  ██║███████╗
-- ╚══════╝ ╚═════╝   ╚═╝      ╚═╝   ╚═╝  ╚═╝╚══════╝
-- Scythe UI Library

local InputService  = game:GetService('UserInputService')
local TextService   = game:GetService('TextService')
local CoreGui       = game:GetService('CoreGui')
local Teams         = game:GetService('Teams')
local Players       = game:GetService('Players')
local RunService    = game:GetService('RunService')
local TweenService  = game:GetService('TweenService')
local RenderStepped = RunService.RenderStepped
local LocalPlayer   = Players.LocalPlayer
local Mouse         = LocalPlayer:GetMouse()

local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end)

local ScreenGui = Instance.new('ScreenGui')
ProtectGui(ScreenGui)
ScreenGui.ZIndexBehavior   = Enum.ZIndexBehavior.Global
ScreenGui.DisplayOrder     = 100
ScreenGui.ResetOnSpawn     = false
ScreenGui.IgnoreGuiInset   = true
ScreenGui.Parent           = CoreGui

local Toggles = {}
local Options = {}

getgenv().Toggles = Toggles
getgenv().Options  = Options

-- ── Visual Constants (Arab Hub style) ─────────────────────────────────────
local CORNER_RADIUS   = UDim.new(0, 5)      -- rounded corners everywhere
local CORNER_SMALL    = UDim.new(0, 3)
local SHADOW_TRANSP   = 0.75                -- drop-shadow transparency
local TWEEN_INFO      = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local ELEMENT_HEIGHT  = 22                  -- standard element height
local TOGGLE_SIZE     = 16                  -- toggle checkbox px
local FONT_SIZE       = 14
local FONT_SIZE_SMALL = 13
-- ──────────────────────────────────────────────────────────────────────────

local Library = {
    Registry       = {};
    RegistryMap    = {};
    HudRegistry    = {};

    FontColor       = Color3.fromRGB(240, 240, 240);
    MainColor       = Color3.fromRGB(30,  30,  40);
    BackgroundColor = Color3.fromRGB(18,  18,  26);
    AccentColor     = Color3.fromRGB(100, 60, 220);
    OutlineColor    = Color3.fromRGB(55,  55,  70);
    RiskColor       = Color3.fromRGB(255, 60,  60);

    Black           = Color3.new(0, 0, 0);
    Font            = Enum.Font.GothamMedium;  -- custom font (Arab Hub feel)

    OpenedFrames    = {};
    DependencyBoxes = {};
    Signals         = {};
    ScreenGui       = ScreenGui;
}

-- ── Rainbow pulse ──────────────────────────────────────────────────────────
local RainbowStep, Hue = 0, 0
table.insert(Library.Signals, RenderStepped:Connect(function(Delta)
    RainbowStep += Delta
    if RainbowStep >= (1/60) then
        RainbowStep = 0
        Hue = (Hue + 1/400) % 1
        Library.CurrentRainbowHue  = Hue
        Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1)
    end
end))

-- ── Helpers ────────────────────────────────────────────────────────────────
local function GetPlayersString()
    local t = Players:GetPlayers()
    for i=1,#t do t[i]=t[i].Name end
    table.sort(t, function(a,b) return a<b end)
    return t
end

local function GetTeamsString()
    local t = Teams:GetTeams()
    for i=1,#t do t[i]=t[i].Name end
    table.sort(t, function(a,b) return a<b end)
    return t
end

-- ── Drop shadow helper (Arab Hub style) ───────────────────────────────────
local function MakeShadow(parent, zindex)
    local s = Instance.new('ImageLabel')
    s.Name              = 'Shadow'
    s.BackgroundTransparency = 1
    s.AnchorPoint       = Vector2.new(0.5, 0.5)
    s.Position          = UDim2.new(0.5, 0, 0.5, 4)
    s.Size              = UDim2.new(1, 20, 1, 20)
    s.Image             = 'rbxassetid://1316045217'
    s.ImageColor3       = Color3.new(0, 0, 0)
    s.ImageTransparency = SHADOW_TRANSP
    s.ScaleType         = Enum.ScaleType.Slice
    s.SliceCenter       = Rect.new(10, 10, 118, 118)
    s.ZIndex            = (zindex or 1) - 1
    s.Parent            = parent
    return s
end

-- ── Tween helper ───────────────────────────────────────────────────────────
local function Tween(inst, props)
    TweenService:Create(inst, TWEEN_INFO, props):Play()
end

-- ── Core Library methods ───────────────────────────────────────────────────
function Library:SafeCallback(f, ...)
    if not f then return end
    if not Library.NotifyOnError then return f(...) end
    local ok, err = pcall(f, ...)
    if not ok then
        local _, i = err:find(':%d+: ')
        return Library:Notify(i and err:sub(i+1) or err, 3)
    end
end

function Library:AttemptSave()
    if Library.SaveManager then Library.SaveManager:Save() end
end

function Library:Create(Class, Props)
    local inst = type(Class)=='string' and Instance.new(Class) or Class
    for k,v in next, Props do inst[k]=v end
    return inst
end

-- Rounded frame factory (Arab Hub corneredness)
function Library:CreateRounded(Props, Radius)
    local f = Library:Create('Frame', Props)
    local c = Instance.new('UICorner')
    c.CornerRadius = Radius or CORNER_RADIUS
    c.Parent = f
    return f
end

function Library:CreateLabel(Props, IsHud)
    local inst = Library:Create('TextLabel', {
        BackgroundTransparency = 1;
        Font       = Library.Font;
        TextColor3 = Library.FontColor;
        TextSize   = FONT_SIZE;
        TextStrokeTransparency = 1;  -- cleaner without stroke (Arab Hub)
    })
    Library:AddToRegistry(inst, { TextColor3='FontColor' }, IsHud)
    return Library:Create(inst, Props)
end

function Library:MakeDraggable(Frame, Cutoff)
    Frame.Active = true
    Frame.InputBegan:Connect(function(Input)
        if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        local off = Vector2.new(Mouse.X - Frame.AbsolutePosition.X, Mouse.Y - Frame.AbsolutePosition.Y)
        if off.Y > (Cutoff or 40) then return end
        while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
            Frame.Position = UDim2.new(0, Mouse.X-off.X+(Frame.Size.X.Offset*Frame.AnchorPoint.X),
                                       0, Mouse.Y-off.Y+(Frame.Size.Y.Offset*Frame.AnchorPoint.Y))
            RenderStepped:Wait()
        end
    end)
end

function Library:AddToolTip(InfoStr, HoverInstance)
    local X, Y = Library:GetTextBounds(InfoStr, Library.Font, FONT_SIZE_SMALL)
    local Tip = Library:CreateRounded({
        BackgroundColor3 = Library.MainColor;
        Size             = UDim2.fromOffset(X+10, Y+6);
        ZIndex           = 200;
        Parent           = Library.ScreenGui;
        Visible          = false;
    }, CORNER_SMALL)
    Instance.new('UIStroke', Tip).Color = Library.OutlineColor

    Library:CreateLabel({
        Position = UDim2.fromOffset(5, 2);
        Size     = UDim2.fromOffset(X, Y);
        TextSize = FONT_SIZE_SMALL;
        Text     = InfoStr;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex   = 201;
        Parent   = Tip;
    })
    Library:AddToRegistry(Tip, { BackgroundColor3='MainColor' })

    local Hovering = false
    HoverInstance.MouseEnter:Connect(function()
        Hovering = true
        Tip.Position = UDim2.fromOffset(Mouse.X+15, Mouse.Y+12)
        Tip.Visible  = true
        while Hovering do
            RunService.Heartbeat:Wait()
            Tip.Position = UDim2.fromOffset(Mouse.X+15, Mouse.Y+12)
        end
    end)
    HoverInstance.MouseLeave:Connect(function()
        Hovering = false
        Tip.Visible = false
    end)
end

function Library:OnHighlight(HoverInst, Target, On, Off)
    HoverInst.MouseEnter:Connect(function()
        local Reg = Library.RegistryMap[Target]
        for Prop, ColorIdx in next, On do
            Target[Prop] = Library[ColorIdx] or ColorIdx
            if Reg and Reg.Properties[Prop] then Reg.Properties[Prop]=ColorIdx end
        end
    end)
    HoverInst.MouseLeave:Connect(function()
        local Reg = Library.RegistryMap[Target]
        for Prop, ColorIdx in next, Off do
            Target[Prop] = Library[ColorIdx] or ColorIdx
            if Reg and Reg.Properties[Prop] then Reg.Properties[Prop]=ColorIdx end
        end
    end)
end

function Library:MouseIsOverOpenedFrame()
    for Frame in next, Library.OpenedFrames do
        local p,s = Frame.AbsolutePosition, Frame.AbsoluteSize
        if Mouse.X>=p.X and Mouse.X<=p.X+s.X and Mouse.Y>=p.Y and Mouse.Y<=p.Y+s.Y then
            return true
        end
    end
end

function Library:IsMouseOverFrame(Frame)
    local p,s = Frame.AbsolutePosition, Frame.AbsoluteSize
    return Mouse.X>=p.X and Mouse.X<=p.X+s.X and Mouse.Y>=p.Y and Mouse.Y<=p.Y+s.Y
end

function Library:UpdateDependencyBoxes()
    for _,db in next, Library.DependencyBoxes do db:Update() end
end

function Library:MapValue(v,minA,maxA,minB,maxB)
    return (1-((v-minA)/(maxA-minA)))*minB + ((v-minA)/(maxA-minA))*maxB
end

function Library:GetTextBounds(Text, Font, Size, Res)
    local b = TextService:GetTextSize(Text, Size, Font, Res or Vector2.new(1920,1080))
    return b.X, b.Y
end

function Library:GetDarkerColor(Color)
    local H,S,V = Color3.toHSV(Color)
    return Color3.fromHSV(H, S, V/1.5)
end
Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)

function Library:AddToRegistry(Instance, Properties, IsHud)
    local Idx = #Library.Registry+1
    local Data = { Instance=Instance; Properties=Properties; Idx=Idx }
    table.insert(Library.Registry, Data)
    Library.RegistryMap[Instance] = Data
    if IsHud then table.insert(Library.HudRegistry, Data) end
end

function Library:RemoveFromRegistry(Instance)
    local Data = Library.RegistryMap[Instance]
    if not Data then return end
    for i=#Library.Registry,1,-1 do
        if Library.Registry[i]==Data then table.remove(Library.Registry,i) end
    end
    for i=#Library.HudRegistry,1,-1 do
        if Library.HudRegistry[i]==Data then table.remove(Library.HudRegistry,i) end
    end
    Library.RegistryMap[Instance]=nil
end

function Library:UpdateColorsUsingRegistry()
    for _, Object in next, Library.Registry do
        for Property, ColorIdx in next, Object.Properties do
            if type(ColorIdx)=='string' then
                Object.Instance[Property] = Library[ColorIdx]
            elseif type(ColorIdx)=='function' then
                Object.Instance[Property] = ColorIdx()
            end
        end
    end
end

function Library:GiveSignal(Signal)
    table.insert(Library.Signals, Signal)
end

function Library:Unload()
    for i=#Library.Signals,1,-1 do
        table.remove(Library.Signals,i):Disconnect()
    end
    if Library.OnUnload then Library.OnUnload() end
    ScreenGui:Destroy()
end

Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(inst)
    if Library.RegistryMap[inst] then Library:RemoveFromRegistry(inst) end
end))

-- ══════════════════════════════════════════════════════════════════════════
-- ADDON SYSTEM (ColorPicker / KeyPicker) — Arab Hub visuals
-- ══════════════════════════════════════════════════════════════════════════
local BaseAddons = {}
do
    local Funcs = {}

    -- ── COLOR PICKER ───────────────────────────────────────────────────────
    function Funcs:AddColorPicker(Idx, Info)
        local ToggleLabel = self.TextLabel

        assert(Info.Default, 'AddColorPicker: Missing default value.')

        local ColorPicker = {
            Value       = Info.Default;
            Transparency = Info.Transparency or 0;
            Type        = 'ColorPicker';
            Title       = type(Info.Title)=='string' and Info.Title or 'Color',
            Callback    = Info.Callback or function() end;
        }

        function ColorPicker:SetHSVFromRGB(Color)
            ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(Color)
        end
        ColorPicker:SetHSVFromRGB(ColorPicker.Value)

        -- Small swatch button
        local SwatchOuter = Library:CreateRounded({
            BackgroundColor3 = ColorPicker.Value;
            Size             = UDim2.new(0, 28, 0, ELEMENT_HEIGHT-4);
            ZIndex           = 6;
            Parent           = ToggleLabel;
        }, CORNER_SMALL)

        local SwatchStroke = Instance.new('UIStroke', SwatchOuter)
        SwatchStroke.Color = Library:GetDarkerColor(ColorPicker.Value)
        SwatchStroke.Thickness = 1

        -- Transparency checker
        local Checker = Library:Create('ImageLabel', {
            BackgroundTransparency = 1;
            Size   = UDim2.fromScale(1,1);
            ZIndex = 5;
            Image  = 'rbxassetid://12977615774';
            Visible = not not Info.Transparency;
            Parent = SwatchOuter;
        })
        Instance.new('UICorner', Checker).CornerRadius = CORNER_SMALL

        -- Main picker window
        local PickerOuter = Library:CreateRounded({
            Name             = 'Color';
            BackgroundColor3 = Library.BackgroundColor;
            Position         = UDim2.fromOffset(SwatchOuter.AbsolutePosition.X, SwatchOuter.AbsolutePosition.Y+22);
            Size             = UDim2.fromOffset(234, Info.Transparency and 278 or 260);
            Visible          = false;
            ZIndex           = 15;
            Parent           = ScreenGui;
        })
        MakeShadow(PickerOuter, 15)

        local PickerStroke = Instance.new('UIStroke', PickerOuter)
        PickerStroke.Color = Library.OutlineColor

        SwatchOuter:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            PickerOuter.Position = UDim2.fromOffset(SwatchOuter.AbsolutePosition.X, SwatchOuter.AbsolutePosition.Y+22)
        end)

        -- Accent bar
        local AccBar = Library:Create('Frame',{
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel  = 0;
            Size             = UDim2.new(1,0,0,2);
            ZIndex           = 16;
            Parent           = PickerOuter;
        })
        Instance.new('UICorner',AccBar).CornerRadius = UDim.new(0,2)
        Library:AddToRegistry(AccBar,{BackgroundColor3='AccentColor'})

        local DisplayLabel = Library:CreateLabel({
            Position       = UDim2.fromOffset(6,4);
            Size           = UDim2.new(1,-12,0,16);
            TextXAlignment = Enum.TextXAlignment.Left;
            TextSize       = FONT_SIZE_SMALL;
            Text           = ColorPicker.Title;
            ZIndex         = 16;
            Parent         = PickerOuter;
        })

        -- Sat/Vib map
        local MapOuter = Library:CreateRounded({
            BorderSizePixel = 0;
            Position        = UDim2.new(0,6,0,26);
            Size            = UDim2.new(0,200,0,200);
            ZIndex          = 17;
            Parent          = PickerOuter;
        }, CORNER_SMALL)

        local MapImg = Library:Create('ImageLabel',{
            BackgroundTransparency=1;
            Size  = UDim2.fromScale(1,1);
            ZIndex= 18;
            Image = 'rbxassetid://4155801252';
            Parent= MapOuter;
        })
        Instance.new('UICorner',MapImg).CornerRadius = CORNER_SMALL

        local CursorOuter = Library:Create('ImageLabel',{
            AnchorPoint = Vector2.new(0.5,0.5);
            Size        = UDim2.new(0,8,0,8);
            BackgroundTransparency=1;
            Image       = 'rbxassetid://9619665977';
            ImageColor3 = Color3.new(0,0,0);
            ZIndex      = 19;
            Parent      = MapImg;
        })
        Library:Create('ImageLabel',{
            Size  = UDim2.new(0,6,0,6);
            Position=UDim2.new(0,1,0,1);
            BackgroundTransparency=1;
            Image = 'rbxassetid://9619665977';
            ZIndex= 20;
            Parent= CursorOuter;
        })

        -- Hue bar
        local HueOuter = Library:CreateRounded({
            BorderSizePixel = 0;
            Position        = UDim2.new(0,210,0,26);
            Size            = UDim2.new(0,16,0,200);
            ZIndex          = 17;
            Parent          = PickerOuter;
        }, CORNER_SMALL)

        local HueInner = Library:Create('Frame',{
            BackgroundColor3 = Color3.new(1,1,1);
            BorderSizePixel  = 0;
            Size             = UDim2.fromScale(1,1);
            ZIndex           = 18;
            Parent           = HueOuter;
        })
        Instance.new('UICorner',HueInner).CornerRadius = CORNER_SMALL

        local HueSeq = {}
        for h=0,1,0.1 do table.insert(HueSeq, ColorSequenceKeypoint.new(h, Color3.fromHSV(h,1,1))) end
        Library:Create('UIGradient',{ Color=ColorSequence.new(HueSeq); Rotation=90; Parent=HueInner })

        -- Hex / RGB input boxes
        local function MakeTextBox(pos, size, placeholder, defaultText)
            local outer = Library:CreateRounded({
                BorderSizePixel = 0;
                BackgroundColor3= Library.MainColor;
                Position        = pos;
                Size            = size;
                ZIndex          = 18;
                Parent          = PickerOuter;
            }, CORNER_SMALL)
            local stroke = Instance.new('UIStroke', outer)
            stroke.Color     = Library.OutlineColor
            stroke.Thickness = 1
            Library:AddToRegistry(outer, {BackgroundColor3='MainColor'})
            Library:AddToRegistry(stroke, {Color='OutlineColor'})

            local box = Library:Create('TextBox',{
                BackgroundTransparency = 1;
                Position  = UDim2.new(0,5,0,0);
                Size      = UDim2.new(1,-5,1,0);
                Font      = Library.Font;
                PlaceholderColor3 = Color3.fromRGB(130,130,150);
                PlaceholderText   = placeholder;
                Text      = defaultText;
                TextColor3= Library.FontColor;
                TextSize  = FONT_SIZE_SMALL;
                TextXAlignment = Enum.TextXAlignment.Left;
                ZIndex    = 20;
                Parent    = outer;
            })
            Library:AddToRegistry(box, {TextColor3='FontColor'})
            return outer, box
        end

        local _, HexBox = MakeTextBox(UDim2.fromOffset(6,232),  UDim2.new(0.5,-9,0,ELEMENT_HEIGHT), 'Hex', '#FFFFFF')
        local _, RgbBox = MakeTextBox(UDim2.new(0.5,3,0,232),   UDim2.new(0.5,-9,0,ELEMENT_HEIGHT), 'RGB', '255, 255, 255')

        local TransBoxOuter
        if Info.Transparency then
            TransBoxOuter = Library:CreateRounded({
                BorderSizePixel  = 0;
                BackgroundColor3 = ColorPicker.Value;
                Position         = UDim2.fromOffset(6,258);
                Size             = UDim2.new(1,-12,0,12);
                ZIndex           = 19;
                Parent           = PickerOuter;
            }, CORNER_SMALL)
            Library:Create('ImageLabel',{
                BackgroundTransparency=1;
                Size  = UDim2.fromScale(1,1);
                Image = 'rbxassetid://12978095818';
                ZIndex= 20;
                Parent= TransBoxOuter;
            })
            Instance.new('UICorner',TransBoxOuter).CornerRadius = CORNER_SMALL
        end

        -- Context menu (copy/paste)
        local CtxMenu = {}
        do
            CtxMenu.Container = Library:CreateRounded({
                ZIndex   = 14;
                Visible  = false;
                Parent   = ScreenGui;
            }, CORNER_SMALL)
            MakeShadow(CtxMenu.Container, 14)

            CtxMenu.Inner = Library:CreateRounded({
                BackgroundColor3 = Library.BackgroundColor;
                Size             = UDim2.fromScale(1,1);
                ZIndex           = 15;
                Parent           = CtxMenu.Container;
            }, CORNER_SMALL)
            local stroke = Instance.new('UIStroke', CtxMenu.Inner)
            stroke.Color = Library.OutlineColor

            Library:Create('UIListLayout',{ FillDirection=Enum.FillDirection.Vertical; SortOrder=Enum.SortOrder.LayoutOrder; Parent=CtxMenu.Inner })
            Library:Create('UIPadding',{ PaddingLeft=UDim.new(0,4); Parent=CtxMenu.Inner })
            Library:AddToRegistry(CtxMenu.Inner,{BackgroundColor3='BackgroundColor'})
            Library:AddToRegistry(stroke, {Color='OutlineColor'})

            local function updateCtxPos()
                CtxMenu.Container.Position = UDim2.fromOffset(
                    SwatchOuter.AbsolutePosition.X + SwatchOuter.AbsoluteSize.X + 4,
                    SwatchOuter.AbsolutePosition.Y + 1)
            end
            local function updateCtxSize()
                local w=60
                for _,l in next, CtxMenu.Inner:GetChildren() do
                    if l:IsA('TextLabel') then w=math.max(w,l.TextBounds.X) end
                end
                CtxMenu.Container.Size = UDim2.fromOffset(w+8, CtxMenu.Inner:FindFirstChildOfClass('UIListLayout').AbsoluteContentSize.Y+4)
            end
            SwatchOuter:GetPropertyChangedSignal('AbsolutePosition'):Connect(updateCtxPos)
            CtxMenu.Inner:FindFirstChildOfClass('UIListLayout'):GetPropertyChangedSignal('AbsoluteContentSize'):Connect(updateCtxSize)
            task.spawn(updateCtxPos); task.spawn(updateCtxSize)

            function CtxMenu:Show() self.Container.Visible=true end
            function CtxMenu:Hide() self.Container.Visible=false end

            function CtxMenu:AddOption(Str, Cb)
                Cb = type(Cb)=='function' and Cb or function() end
                local lbl = Library:CreateLabel({ Active=false; Size=UDim2.new(1,0,0,16); TextSize=FONT_SIZE_SMALL; Text=Str; ZIndex=16; Parent=self.Inner; TextXAlignment=Enum.TextXAlignment.Left })
                Library:OnHighlight(lbl, lbl, {TextColor3='AccentColor'}, {TextColor3='FontColor'})
                lbl.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then Cb() end end)
            end

            CtxMenu:AddOption('Copy color',  function() Library.ColorClipboard=ColorPicker.Value; Library:Notify('Copied color!',2) end)
            CtxMenu:AddOption('Paste color', function()
                if not Library.ColorClipboard then return Library:Notify('No color copied!',2) end
                ColorPicker:SetValueRGB(Library.ColorClipboard)
            end)
            CtxMenu:AddOption('Copy HEX', function() pcall(setclipboard, ColorPicker.Value:ToHex()); Library:Notify('Copied HEX!',2) end)
            CtxMenu:AddOption('Copy RGB', function()
                pcall(setclipboard, table.concat({math.floor(ColorPicker.Value.R*255),math.floor(ColorPicker.Value.G*255),math.floor(ColorPicker.Value.B*255)},', '))
                Library:Notify('Copied RGB!',2)
            end)
        end

        Library:AddToRegistry(PickerOuter, {BackgroundColor3='BackgroundColor'})
        Library:AddToRegistry(PickerStroke, {Color='OutlineColor'})
        Library:AddToRegistry(AccBar, {BackgroundColor3='AccentColor'})

        HexBox.FocusLost:Connect(function(enter)
            if enter then
                local ok, r = pcall(Color3.fromHex, HexBox.Text)
                if ok and typeof(r)=='Color3' then ColorPicker.Hue,ColorPicker.Sat,ColorPicker.Vib=Color3.toHSV(r) end
            end
            ColorPicker:Display()
        end)

        RgbBox.FocusLost:Connect(function(enter)
            if enter then
                local r,g,b = RgbBox.Text:match('(%d+),%s*(%d+),%s*(%d+)')
                if r then ColorPicker.Hue,ColorPicker.Sat,ColorPicker.Vib=Color3.toHSV(Color3.fromRGB(r,g,b)) end
            end
            ColorPicker:Display()
        end)

        function ColorPicker:Display()
            ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib)
            MapImg.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue,1,1)
            SwatchOuter.BackgroundColor3 = ColorPicker.Value
            SwatchOuter.BackgroundTransparency = ColorPicker.Transparency
            SwatchStroke.Color = Library:GetDarkerColor(ColorPicker.Value)
            if TransBoxOuter then TransBoxOuter.BackgroundColor3 = ColorPicker.Value end
            CursorOuter.Position = UDim2.new(ColorPicker.Sat, 0, 1-ColorPicker.Vib, 0)
            HexBox.Text = '#'..ColorPicker.Value:ToHex()
            RgbBox.Text = table.concat({math.floor(ColorPicker.Value.R*255),math.floor(ColorPicker.Value.G*255),math.floor(ColorPicker.Value.B*255)},', ')
            Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value)
            Library:SafeCallback(ColorPicker.Changed,  ColorPicker.Value)
        end

        function ColorPicker:OnChanged(Func) ColorPicker.Changed=Func; Func(ColorPicker.Value) end
        function ColorPicker:Show()
            for F in next, Library.OpenedFrames do if F.Name=='Color' then F.Visible=false; Library.OpenedFrames[F]=nil end end
            PickerOuter.Visible=true; Library.OpenedFrames[PickerOuter]=true
        end
        function ColorPicker:Hide() PickerOuter.Visible=false; Library.OpenedFrames[PickerOuter]=nil end
        function ColorPicker:SetValue(HSV,T) local c=Color3.fromHSV(HSV[1],HSV[2],HSV[3]); ColorPicker.Transparency=T or 0; ColorPicker:SetHSVFromRGB(c); ColorPicker:Display() end
        function ColorPicker:SetValueRGB(Color,T) ColorPicker.Transparency=T or 0; ColorPicker:SetHSVFromRGB(Color); ColorPicker:Display() end

        MapImg.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then
                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local x0=MapImg.AbsolutePosition.X; local x1=x0+MapImg.AbsoluteSize.X
                    local y0=MapImg.AbsolutePosition.Y; local y1=y0+MapImg.AbsoluteSize.Y
                    ColorPicker.Sat = (math.clamp(Mouse.X,x0,x1)-x0)/(x1-x0)
                    ColorPicker.Vib = 1-((math.clamp(Mouse.Y,y0,y1)-y0)/(y1-y0))
                    ColorPicker:Display(); RenderStepped:Wait()
                end
                Library:AttemptSave()
            end
        end)

        HueInner.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then
                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local y0=HueInner.AbsolutePosition.Y; local y1=y0+HueInner.AbsoluteSize.Y
                    ColorPicker.Hue = (math.clamp(Mouse.Y,y0,y1)-y0)/(y1-y0)
                    ColorPicker:Display(); RenderStepped:Wait()
                end
                Library:AttemptSave()
            end
        end)

        SwatchOuter.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                if PickerOuter.Visible then ColorPicker:Hide() else CtxMenu:Hide(); ColorPicker:Show() end
            elseif i.UserInputType==Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
                CtxMenu:Show(); ColorPicker:Hide()
            end
        end)

        if TransBoxOuter then
            TransBoxOuter.InputBegan:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 then
                    while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                        local x0=TransBoxOuter.AbsolutePosition.X; local x1=x0+TransBoxOuter.AbsoluteSize.X
                        ColorPicker.Transparency = 1-((math.clamp(Mouse.X,x0,x1)-x0)/(x1-x0))
                        ColorPicker:Display(); RenderStepped:Wait()
                    end
                    Library:AttemptSave()
                end
            end)
        end

        Library:GiveSignal(InputService.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then
                local p,s = PickerOuter.AbsolutePosition, PickerOuter.AbsoluteSize
                if Mouse.X<p.X or Mouse.X>p.X+s.X or Mouse.Y<(p.Y-22) or Mouse.Y>p.Y+s.Y then
                    ColorPicker:Hide()
                end
                if not Library:IsMouseOverFrame(CtxMenu.Container) then CtxMenu:Hide() end
            end
            if i.UserInputType==Enum.UserInputType.MouseButton2 and CtxMenu.Container.Visible then
                if not Library:IsMouseOverFrame(CtxMenu.Container) and not Library:IsMouseOverFrame(SwatchOuter) then
                    CtxMenu:Hide()
                end
            end
        end))

        ColorPicker:Display()
        ColorPicker.DisplayFrame = SwatchOuter
        Options[Idx] = ColorPicker
        return self
    end

    -- ── KEY PICKER ─────────────────────────────────────────────────────────
    function Funcs:AddKeyPicker(Idx, Info)
        local ParentObj   = self
        local ToggleLabel = self.TextLabel

        assert(Info.Default, 'AddKeyPicker: Missing default value.')

        local KeyPicker = {
            Value    = Info.Default;
            Toggled  = false;
            Mode     = Info.Mode or 'Toggle';
            Type     = 'KeyPicker';
            Callback        = Info.Callback or function() end;
            ChangedCallback = Info.ChangedCallback or function() end;
            SyncToggleState = Info.SyncToggleState or false;
        }

        if KeyPicker.SyncToggleState then Info.Modes={'Toggle'}; Info.Mode='Toggle' end

        local PickOuter = Library:CreateRounded({
            BorderSizePixel  = 0;
            BackgroundColor3 = Library.BackgroundColor;
            Size             = UDim2.new(0,32,0,ELEMENT_HEIGHT-4);
            ZIndex           = 6;
            Parent           = ToggleLabel;
        }, CORNER_SMALL)
        local PickStroke = Instance.new('UIStroke', PickOuter)
        PickStroke.Color = Library.OutlineColor
        Library:AddToRegistry(PickOuter, {BackgroundColor3='BackgroundColor'})
        Library:AddToRegistry(PickStroke, {Color='OutlineColor'})

        local PickLabel = Library:CreateLabel({
            Size      = UDim2.fromScale(1,1);
            TextSize  = FONT_SIZE_SMALL;
            Text      = Info.Default;
            TextWrapped=true;
            ZIndex    = 7;
            Parent    = PickOuter;
        })

        local ModeOuter = Library:CreateRounded({
            Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X+ToggleLabel.AbsoluteSize.X+4, ToggleLabel.AbsolutePosition.Y+1);
            Size     = UDim2.new(0,66,0,50);
            Visible  = false;
            ZIndex   = 14;
            Parent   = ScreenGui;
        }, CORNER_SMALL)
        MakeShadow(ModeOuter, 14)
        ToggleLabel:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            ModeOuter.Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X+ToggleLabel.AbsoluteSize.X+4, ToggleLabel.AbsolutePosition.Y+1)
        end)

        local ModeInner = Library:CreateRounded({
            BackgroundColor3 = Library.BackgroundColor;
            Size             = UDim2.fromScale(1,1);
            ZIndex           = 15;
            Parent           = ModeOuter;
        }, CORNER_SMALL)
        local mStroke = Instance.new('UIStroke', ModeInner); mStroke.Color = Library.OutlineColor
        Library:AddToRegistry(ModeInner, {BackgroundColor3='BackgroundColor'})
        Library:AddToRegistry(mStroke, {Color='OutlineColor'})
        Library:Create('UIListLayout',{ FillDirection=Enum.FillDirection.Vertical; SortOrder=Enum.SortOrder.LayoutOrder; Parent=ModeInner })

        local ContainerLabel = Library:CreateLabel({
            TextXAlignment = Enum.TextXAlignment.Left;
            Size           = UDim2.new(1,0,0,18);
            TextSize       = FONT_SIZE_SMALL;
            Visible        = false;
            ZIndex         = 110;
            Parent         = Library.KeybindContainer;
        }, true)

        local Modes       = Info.Modes or {'Always','Toggle','Hold'}
        local ModeButtons = {}

        for _, Mode in next, Modes do
            local MB  = {}
            local Lbl = Library:CreateLabel({
                Active  = false;
                Size    = UDim2.new(1,0,0,16);
                TextSize= FONT_SIZE_SMALL;
                Text    = Mode;
                ZIndex  = 16;
                Parent  = ModeInner;
            })

            function MB:Select()
                for _,b in next, ModeButtons do b:Deselect() end
                KeyPicker.Mode = Mode
                Lbl.TextColor3 = Library.AccentColor
                Library.RegistryMap[Lbl].Properties.TextColor3='AccentColor'
                ModeOuter.Visible=false
            end
            function MB:Deselect()
                KeyPicker.Mode=nil
                Lbl.TextColor3 = Library.FontColor
                Library.RegistryMap[Lbl].Properties.TextColor3='FontColor'
            end

            Lbl.InputBegan:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 then MB:Select(); Library:AttemptSave() end
            end)

            if Mode==KeyPicker.Mode then MB:Select() end
            ModeButtons[Mode] = MB
        end

        function KeyPicker:Update()
            if Info.NoUI then return end
            local State = KeyPicker:GetState()
            ContainerLabel.Text = string.format('[%s] %s (%s)', KeyPicker.Value, Info.Text, KeyPicker.Mode)
            ContainerLabel.Visible = true
            ContainerLabel.TextColor3 = State and Library.AccentColor or Library.FontColor
            Library.RegistryMap[ContainerLabel].Properties.TextColor3 = State and 'AccentColor' or 'FontColor'
            local YSize,XSize=0,0
            for _,l in next, Library.KeybindContainer:GetChildren() do
                if l:IsA('TextLabel') and l.Visible then YSize+=18; if l.TextBounds.X>XSize then XSize=l.TextBounds.X end end
            end
            Library.KeybindFrame.Size = UDim2.new(0,math.max(XSize+10,210),0,YSize+23)
        end

        function KeyPicker:GetState()
            if KeyPicker.Mode=='Always' then return true
            elseif KeyPicker.Mode=='Hold' then
                if KeyPicker.Value=='None' then return false end
                local k = KeyPicker.Value
                if k=='MB1' then return InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                elseif k=='MB2' then return InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
                else return InputService:IsKeyDown(Enum.KeyCode[k]) end
            else return KeyPicker.Toggled end
        end

        function KeyPicker:SetValue(Data)
            PickLabel.Text  = Data[1]
            KeyPicker.Value = Data[1]
            ModeButtons[Data[2]]:Select()
            KeyPicker:Update()
        end

        function KeyPicker:OnClick(Cb)   KeyPicker.Clicked  = Cb end
        function KeyPicker:OnChanged(Cb) KeyPicker.Changed  = Cb; Cb(KeyPicker.Value) end

        if ParentObj.Addons then table.insert(ParentObj.Addons, KeyPicker) end

        function KeyPicker:DoClick()
            if ParentObj.Type=='Toggle' and KeyPicker.SyncToggleState then ParentObj:SetValue(not ParentObj.Value) end
            Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
            Library:SafeCallback(KeyPicker.Clicked,  KeyPicker.Toggled)
        end

        local Picking=false
        PickOuter.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                Picking=true; PickLabel.Text=''
                local Break=false; local dots=''
                task.spawn(function()
                    while not Break do
                        dots = dots=='..' and '' or dots..'.'
                        PickLabel.Text=dots; task.wait(0.4)
                    end
                end)
                task.wait(0.2)
                local Ev; Ev = InputService.InputBegan:Connect(function(i2)
                    local Key
                    if i2.UserInputType==Enum.UserInputType.Keyboard then Key=i2.KeyCode.Name
                    elseif i2.UserInputType==Enum.UserInputType.MouseButton1 then Key='MB1'
                    elseif i2.UserInputType==Enum.UserInputType.MouseButton2 then Key='MB2' end
                    Break=true; Picking=false; PickLabel.Text=Key; KeyPicker.Value=Key
                    Library:SafeCallback(KeyPicker.ChangedCallback, i2.KeyCode or i2.UserInputType)
                    Library:SafeCallback(KeyPicker.Changed,         i2.KeyCode or i2.UserInputType)
                    Library:AttemptSave(); Ev:Disconnect()
                end)
            elseif i.UserInputType==Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
                ModeOuter.Visible=true
            end
        end)

        Library:GiveSignal(InputService.InputBegan:Connect(function(i)
            if not Picking then
                if KeyPicker.Mode=='Toggle' then
                    local k=KeyPicker.Value
                    if k=='MB1' or k=='MB2' then
                        if (k=='MB1' and i.UserInputType==Enum.UserInputType.MouseButton1) or
                           (k=='MB2' and i.UserInputType==Enum.UserInputType.MouseButton2) then
                            KeyPicker.Toggled=not KeyPicker.Toggled; KeyPicker:DoClick()
                        end
                    elseif i.UserInputType==Enum.UserInputType.Keyboard and i.KeyCode.Name==k then
                        KeyPicker.Toggled=not KeyPicker.Toggled; KeyPicker:DoClick()
                    end
                end
                KeyPicker:Update()
            end
            if i.UserInputType==Enum.UserInputType.MouseButton1 then
                local p,s=ModeOuter.AbsolutePosition,ModeOuter.AbsoluteSize
                if Mouse.X<p.X or Mouse.X>p.X+s.X or Mouse.Y<(p.Y-22) or Mouse.Y>p.Y+s.Y then
                    ModeOuter.Visible=false
                end
            end
        end))

        Library:GiveSignal(InputService.InputEnded:Connect(function()
            if not Picking then KeyPicker:Update() end
        end))

        KeyPicker:Update()
        Options[Idx] = KeyPicker
        return self
    end

    BaseAddons.__index     = Funcs
    BaseAddons.__namecall  = function(T,K,...) return Funcs[K](...) end
end

-- ══════════════════════════════════════════════════════════════════════════
-- GROUPBOX ELEMENTS — Arab Hub visuals applied
-- ══════════════════════════════════════════════════════════════════════════
local BaseGroupbox = {}
do
    local Funcs = {}

    function Funcs:AddBlank(Size)
        Library:Create('Frame',{ BackgroundTransparency=1; Size=UDim2.new(1,0,0,Size); ZIndex=1; Parent=self.Container })
    end

    function Funcs:AddLabel(Text, DoesWrap)
        local Label    = {}
        local Groupbox = self

        local TextLabel = Library:CreateLabel({
            Size           = UDim2.new(1,-6,0,16);
            TextSize       = FONT_SIZE;
            Text           = Text;
            TextWrapped    = DoesWrap or false;
            RichText       = true;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex         = 5;
            Parent         = self.Container;
        })

        if DoesWrap then
            local Y = select(2, Library:GetTextBounds(Text, Library.Font, FONT_SIZE, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
            TextLabel.Size = UDim2.new(1,-6,0,Y)
        else
            Library:Create('UIListLayout',{ Padding=UDim.new(0,4); FillDirection=Enum.FillDirection.Horizontal; HorizontalAlignment=Enum.HorizontalAlignment.Right; SortOrder=Enum.SortOrder.LayoutOrder; Parent=TextLabel })
        end

        Label.TextLabel = TextLabel
        Label.Container = self.Container

        function Label:SetText(t)
            TextLabel.Text = t
            if DoesWrap then
                local Y = select(2, Library:GetTextBounds(t, Library.Font, FONT_SIZE, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
                TextLabel.Size = UDim2.new(1,-6,0,Y)
            end
            Groupbox:Resize()
        end

        if not DoesWrap then setmetatable(Label, BaseAddons) end

        self:AddBlank(4)
        self:Resize()
        return Label
    end

    function Funcs:AddButton(...)
        local Button = {}
        local function ParseParams(Obj, ...)
            local P = select(1,...)
            if type(P)=='table' then Obj.Text=P.Text; Obj.Func=P.Func; Obj.DoubleClick=P.DoubleClick; Obj.Tooltip=P.Tooltip
            else Obj.Text=select(1,...); Obj.Func=select(2,...) end
            assert(type(Obj.Func)=='function','AddButton: Func missing.')
        end
        ParseParams(Button,...)

        local Groupbox = self

        local function CreateBtn(Btn)
            local Outer = Library:CreateRounded({
                BackgroundColor3 = Library.MainColor;
                Size             = UDim2.new(1,-4,0,ELEMENT_HEIGHT);
                ZIndex           = 5;
            }, CORNER_SMALL)
            local stroke = Instance.new('UIStroke', Outer)
            stroke.Color     = Library.OutlineColor
            stroke.Thickness = 1
            Library:AddToRegistry(Outer,  {BackgroundColor3='MainColor'})
            Library:AddToRegistry(stroke, {Color='OutlineColor'})

            local Lbl = Library:CreateLabel({
                Size    = UDim2.fromScale(1,1);
                TextSize= FONT_SIZE;
                Text    = Btn.Text;
                ZIndex  = 6;
                Parent  = Outer;
            })

            -- Hover glow
            Outer.MouseEnter:Connect(function()
                Tween(Outer, {BackgroundColor3 = Library:GetDarkerColor(Library.MainColor)})
                Tween(stroke, {Color = Library.AccentColor})
            end)
            Outer.MouseLeave:Connect(function()
                Tween(Outer, {BackgroundColor3 = Library.MainColor})
                Tween(stroke, {Color = Library.OutlineColor})
            end)

            return Outer, nil, Lbl
        end

        local function InitEvents(Btn)
            local function WaitEvt(ev, timeout, validator)
                local be = Instance.new('BindableEvent')
                local conn = ev:Once(function(...) be:Fire(type(validator)=='function' and validator(...)) end)
                task.delay(timeout, function() conn:disconnect(); be:Fire(false) end)
                return be.Event:Wait()
            end
            local function ValidClick(i)
                return not Library:MouseIsOverOpenedFrame() and i.UserInputType==Enum.UserInputType.MouseButton1
            end

            Btn.Outer.InputBegan:Connect(function(i)
                if not ValidClick(i) or Btn.Locked then return end
                if Btn.DoubleClick then
                    Library:RemoveFromRegistry(Btn.Label)
                    Library:AddToRegistry(Btn.Label,{TextColor3='AccentColor'})
                    Btn.Label.TextColor3 = Library.AccentColor
                    Btn.Label.Text       = 'Are you sure?'
                    Btn.Locked           = true
                    local clicked = WaitEvt(Btn.Outer.InputBegan, 0.5, ValidClick)
                    Library:RemoveFromRegistry(Btn.Label)
                    Library:AddToRegistry(Btn.Label,{TextColor3='FontColor'})
                    Btn.Label.TextColor3 = Library.FontColor
                    Btn.Label.Text       = Btn.Text
                    task.defer(rawset,Btn,'Locked',false)
                    if clicked then Library:SafeCallback(Btn.Func) end
                    return
                end
                Library:SafeCallback(Btn.Func)
            end)
        end

        Button.Outer, _, Button.Label = CreateBtn(Button)
        Button.Outer.Parent = self.Container
        InitEvents(Button)

        function Button:AddTooltip(tt) if type(tt)=='string' then Library:AddToolTip(tt,self.Outer) end return self end

        function Button:AddButton(...)
            local Sub = {}; ParseParams(Sub,...)
            self.Outer.Size = UDim2.new(0.5,-2,0,ELEMENT_HEIGHT)
            Sub.Outer, _, Sub.Label = CreateBtn(Sub)
            Sub.Outer.Position = UDim2.new(1,3,0,0)
            Sub.Outer.Size     = UDim2.fromOffset(self.Outer.AbsoluteSize.X-2, self.Outer.AbsoluteSize.Y)
            Sub.Outer.Parent   = self.Outer
            function Sub:AddTooltip(tt) if type(tt)=='string' then Library:AddToolTip(tt,self.Outer) end return Sub end
            if type(Sub.Tooltip)=='string' then Sub:AddTooltip(Sub.Tooltip) end
            InitEvents(Sub)
            return Sub
        end

        if type(Button.Tooltip)=='string' then Button:AddTooltip(Button.Tooltip) end
        self:AddBlank(4); self:Resize()
        return Button
    end

    function Funcs:AddDivider()
        self:AddBlank(2)
        local Line = Library:CreateRounded({
            BackgroundColor3 = Library.OutlineColor;
            Size             = UDim2.new(1,-6,0,1);
            ZIndex           = 5;
            Parent           = self.Container;
        }, UDim.new(0,1))
        Library:AddToRegistry(Line,{BackgroundColor3='OutlineColor'})
        self:AddBlank(8); self:Resize()
    end

    function Funcs:AddInput(Idx, Info)
        assert(Info.Text,'AddInput: Missing Text.')

        local Textbox = {
            Value   = Info.Default or '';
            Numeric = Info.Numeric or false;
            Finished= Info.Finished or false;
            Type    = 'Input';
            Callback= Info.Callback or function() end;
        }

        local Groupbox = self

        Library:CreateLabel({
            Size           = UDim2.new(1,0,0,15);
            TextSize       = FONT_SIZE;
            Text           = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex         = 5;
            Parent         = self.Container;
        })
        self:AddBlank(1)

        local BoxOuter = Library:CreateRounded({
            BackgroundColor3 = Library.MainColor;
            Size             = UDim2.new(1,-4,0,ELEMENT_HEIGHT);
            ZIndex           = 5;
            Parent           = self.Container;
        }, CORNER_SMALL)
        local bStroke = Instance.new('UIStroke',BoxOuter); bStroke.Color=Library.OutlineColor
        Library:AddToRegistry(BoxOuter, {BackgroundColor3='MainColor'})
        Library:AddToRegistry(bStroke,  {Color='OutlineColor'})

        BoxOuter.MouseEnter:Connect(function() Tween(bStroke,{Color=Library.AccentColor}) end)
        BoxOuter.MouseLeave:Connect(function() Tween(bStroke,{Color=Library.OutlineColor}) end)

        if type(Info.Tooltip)=='string' then Library:AddToolTip(Info.Tooltip, BoxOuter) end

        local Clip = Library:Create('Frame',{
            BackgroundTransparency=1; ClipsDescendants=true;
            Position=UDim2.new(0,5,0,0); Size=UDim2.new(1,-5,1,0); ZIndex=7; Parent=BoxOuter;
        })

        local Box = Library:Create('TextBox',{
            BackgroundTransparency=1;
            Position     = UDim2.fromOffset(0,0);
            Size         = UDim2.fromScale(5,1);
            Font         = Library.Font;
            PlaceholderColor3 = Color3.fromRGB(120,120,140);
            PlaceholderText   = Info.Placeholder or '';
            Text         = Info.Default or '';
            TextColor3   = Library.FontColor;
            TextSize     = FONT_SIZE;
            TextXAlignment=Enum.TextXAlignment.Left;
            ZIndex       = 7;
            Parent       = Clip;
        })
        Library:AddToRegistry(Box,{TextColor3='FontColor'})

        function Textbox:SetValue(Text)
            if Info.MaxLength and #Text>Info.MaxLength then Text=Text:sub(1,Info.MaxLength) end
            if Textbox.Numeric and not tonumber(Text) and #Text>0 then Text=Textbox.Value end
            Textbox.Value=Text; Box.Text=Text
            Library:SafeCallback(Textbox.Callback, Textbox.Value)
            Library:SafeCallback(Textbox.Changed,  Textbox.Value)
        end

        if Textbox.Finished then
            Box.FocusLost:Connect(function(e) if e then Textbox:SetValue(Box.Text); Library:AttemptSave() end end)
        else
            Box:GetPropertyChangedSignal('Text'):Connect(function() Textbox:SetValue(Box.Text); Library:AttemptSave() end)
        end

        local function Update()
            local PAD=2; local rev=Clip.AbsoluteSize.X
            if not Box:IsFocused() or Box.TextBounds.X<=rev-2*PAD then
                Box.Position=UDim2.new(0,PAD,0,0)
            else
                local cur=Box.CursorPosition
                if cur~=-1 then
                    local w=TextService:GetTextSize(Box.Text:sub(1,cur-1),Box.TextSize,Box.Font,Vector2.new(math.huge,math.huge)).X
                    local pos=Box.Position.X.Offset+w
                    if pos<PAD then Box.Position=UDim2.fromOffset(PAD-w,0)
                    elseif pos>rev-PAD-1 then Box.Position=UDim2.fromOffset(rev-w-PAD-1,0) end
                end
            end
        end
        task.spawn(Update)
        Box:GetPropertyChangedSignal('Text'):Connect(Update)
        Box:GetPropertyChangedSignal('CursorPosition'):Connect(Update)
        Box.FocusLost:Connect(Update); Box.Focused:Connect(Update)

        function Textbox:OnChanged(Func) Textbox.Changed=Func; Func(Textbox.Value) end

        self:AddBlank(4); self:Resize()
        Options[Idx] = Textbox
        return Textbox
    end

    function Funcs:AddToggle(Idx, Info)
        assert(Info.Text,'AddToggle: Missing Text.')

        local Toggle = {
            Value    = Info.Default or false;
            Type     = 'Toggle';
            Callback = Info.Callback or function() end;
            Addons   = {};
            Risky    = Info.Risky;
        }

        local Groupbox = self

        -- Toggle outer (Arab Hub style: rounded, no border, background shifts)
        local ToggleOuter = Library:CreateRounded({
            BackgroundColor3 = Library.MainColor;
            Size             = UDim2.new(0,TOGGLE_SIZE,0,TOGGLE_SIZE);
            ZIndex           = 5;
            Parent           = self.Container;
        }, CORNER_RADIUS)
        local tStroke = Instance.new('UIStroke',ToggleOuter); tStroke.Color=Library.OutlineColor
        Library:AddToRegistry(ToggleOuter,{BackgroundColor3='MainColor'})
        Library:AddToRegistry(tStroke,    {Color='OutlineColor'})

        -- Checkmark image (visible when on)
        local CheckMark = Library:Create('ImageLabel',{
            BackgroundTransparency=1;
            Size  = UDim2.fromScale(0.7,0.7);
            AnchorPoint = Vector2.new(0.5,0.5);
            Position    = UDim2.fromScale(0.5,0.5);
            Image = 'rbxassetid://10709790725';
            ImageColor3 = Color3.new(1,1,1);
            ImageTransparency = 1;
            ZIndex = 6;
            Parent = ToggleOuter;
        })

        local ToggleLabel = Library:CreateLabel({
            Size           = UDim2.new(0,220,1,0);
            Position       = UDim2.new(1,6,0,0);
            TextSize       = FONT_SIZE;
            Text           = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex         = 6;
            Parent         = ToggleOuter;
        })
        Library:Create('UIListLayout',{ Padding=UDim.new(0,4); FillDirection=Enum.FillDirection.Horizontal; HorizontalAlignment=Enum.HorizontalAlignment.Right; SortOrder=Enum.SortOrder.LayoutOrder; Parent=ToggleLabel })

        local ToggleRegion = Library:Create('Frame',{
            BackgroundTransparency=1;
            Size  = UDim2.new(0,180,1,0);
            ZIndex= 8;
            Parent= ToggleOuter;
        })

        if type(Info.Tooltip)=='string' then Library:AddToolTip(Info.Tooltip, ToggleRegion) end

        function Toggle:Display()
            local on = Toggle.Value
            Tween(ToggleOuter,  {BackgroundColor3 = on and Library.AccentColor or Library.MainColor})
            Tween(tStroke,      {Color            = on and Library.AccentColorDark or Library.OutlineColor})
            Tween(CheckMark,    {ImageTransparency = on and 0 or 1})
        end

        function Toggle:UpdateColors() Toggle:Display() end
        function Toggle:OnChanged(Func) Toggle.Changed=Func; Func(Toggle.Value) end

        function Toggle:SetValue(Bool)
            Bool = not not Bool
            Toggle.Value = Bool
            Toggle:Display()
            for _, Addon in next, Toggle.Addons do
                if Addon.Type=='KeyPicker' and Addon.SyncToggleState then
                    Addon.Toggled=Bool; Addon:Update()
                end
            end
            Library:SafeCallback(Toggle.Callback, Toggle.Value)
            Library:SafeCallback(Toggle.Changed,  Toggle.Value)
            Library:UpdateDependencyBoxes()
        end

        ToggleRegion.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                Toggle:SetValue(not Toggle.Value); Library:AttemptSave()
            end
        end)

        if Toggle.Risky then
            Library:RemoveFromRegistry(ToggleLabel)
            ToggleLabel.TextColor3 = Library.RiskColor
            Library:AddToRegistry(ToggleLabel,{TextColor3='RiskColor'})
        end

        Toggle:Display()
        self:AddBlank(Info.BlankSize or 6)
        self:Resize()

        Toggle.TextLabel = ToggleLabel
        Toggle.Container = self.Container
        setmetatable(Toggle, BaseAddons)

        Toggles[Idx] = Toggle
        Library:UpdateDependencyBoxes()
        return Toggle
    end

    function Funcs:AddSlider(Idx, Info)
        assert(Info.Default,'AddSlider: Missing default.')
        assert(Info.Text,   'AddSlider: Missing text.')
        assert(Info.Min,    'AddSlider: Missing min.')
        assert(Info.Max,    'AddSlider: Missing max.')
        assert(Info.Rounding,'AddSlider: Missing rounding.')

        local Slider = {
            Value   = Info.Default;
            Min     = Info.Min;
            Max     = Info.Max;
            Rounding= Info.Rounding;
            MaxSize = 232;
            Type    = 'Slider';
            Callback= Info.Callback or function() end;
        }

        local Groupbox = self

        if not Info.Compact then
            Library:CreateLabel({
                Size           = UDim2.new(1,0,0,12);
                TextSize       = FONT_SIZE;
                Text           = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Bottom;
                ZIndex         = 5;
                Parent         = self.Container;
            })
            self:AddBlank(2)
        end

        -- Arab Hub style slider: pill shape, accent fill
        local SliderOuter = Library:CreateRounded({
            BackgroundColor3 = Library.MainColor;
            Size             = UDim2.new(1,-4,0,ELEMENT_HEIGHT-4);
            ZIndex           = 5;
            Parent           = self.Container;
        }, UDim.new(0,6))
        local sStroke = Instance.new('UIStroke',SliderOuter); sStroke.Color=Library.OutlineColor
        Library:AddToRegistry(SliderOuter,{BackgroundColor3='MainColor'})
        Library:AddToRegistry(sStroke,    {Color='OutlineColor'})

        local Fill = Library:CreateRounded({
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel  = 0;
            Size             = UDim2.new(0,0,1,0);
            ZIndex           = 7;
            Parent           = SliderOuter;
        }, UDim.new(0,6))
        Library:AddToRegistry(Fill,{BackgroundColor3='AccentColor'})

        local DisplayLabel = Library:CreateLabel({
            Size    = UDim2.fromScale(1,1);
            TextSize= FONT_SIZE_SMALL;
            Text    = 'Infinite';
            ZIndex  = 9;
            Parent  = SliderOuter;
        })

        SliderOuter.MouseEnter:Connect(function() Tween(sStroke,{Color=Library.AccentColor}) end)
        SliderOuter.MouseLeave:Connect(function() Tween(sStroke,{Color=Library.OutlineColor}) end)

        if type(Info.Tooltip)=='string' then Library:AddToolTip(Info.Tooltip, SliderOuter) end

        function Slider:UpdateColors()
            Fill.BackgroundColor3 = Library.AccentColor
        end

        function Slider:Display()
            local Suffix = Info.Suffix or ''
            if Info.Compact then
                DisplayLabel.Text = Info.Text..': '..Slider.Value..Suffix
            elseif Info.HideMax then
                DisplayLabel.Text = tostring(Slider.Value..Suffix)
            else
                DisplayLabel.Text = string.format('%s/%s', Slider.Value..Suffix, Slider.Max..Suffix)
            end
            local X = math.ceil(Library:MapValue(Slider.Value, Slider.Min, Slider.Max, 0, Slider.MaxSize))
            Fill.Size = UDim2.new(0,X,1,0)
        end

        function Slider:OnChanged(Func) Slider.Changed=Func; Func(Slider.Value) end

        local function Round(v)
            if Slider.Rounding==0 then return math.floor(v) end
            return tonumber(string.format('%.'..Slider.Rounding..'f',v))
        end

        function Slider:GetValueFromX(X) return Round(Library:MapValue(X,0,Slider.MaxSize,Slider.Min,Slider.Max)) end

        function Slider:SetValue(Str)
            local n=tonumber(Str); if not n then return end
            n = math.clamp(n,Slider.Min,Slider.Max)
            Slider.Value=n; Slider:Display()
            Library:SafeCallback(Slider.Callback, Slider.Value)
            Library:SafeCallback(Slider.Changed,  Slider.Value)
        end

        SliderOuter.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                local mPos=Mouse.X; local gPos=Fill.Size.X.Offset
                local Diff=mPos-(Fill.AbsolutePosition.X+gPos)
                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local nX=math.clamp(gPos+(Mouse.X-mPos)+Diff,0,Slider.MaxSize)
                    local nV=Slider:GetValueFromX(nX); local old=Slider.Value
                    Slider.Value=nV; Slider:Display()
                    if nV~=old then
                        Library:SafeCallback(Slider.Callback,Slider.Value)
                        Library:SafeCallback(Slider.Changed, Slider.Value)
                    end
                    RenderStepped:Wait()
                end
                Library:AttemptSave()
            end
        end)

        Slider:Display()
        self:AddBlank(Info.BlankSize or 5)
        self:Resize()
        Options[Idx] = Slider
        return Slider
    end

    function Funcs:AddDropdown(Idx, Info)
        if Info.SpecialType=='Player' then Info.Values=GetPlayersString(); Info.AllowNull=true
        elseif Info.SpecialType=='Team' then Info.Values=GetTeamsString(); Info.AllowNull=true end

        assert(Info.Values,'AddDropdown: Missing values.')
        assert(Info.AllowNull or Info.Default,'AddDropdown: Missing default or AllowNull.')
        if not Info.Text then Info.Compact=true end

        local Dropdown = {
            Values      = Info.Values;
            Value       = Info.Multi and {};
            Multi       = Info.Multi;
            Type        = 'Dropdown';
            SpecialType = Info.SpecialType;
            Callback    = Info.Callback or function() end;
        }

        local Groupbox = self
        local RelOffset = 0

        if not Info.Compact then
            Library:CreateLabel({ Size=UDim2.new(1,0,0,12); TextSize=FONT_SIZE; Text=Info.Text; TextXAlignment=Enum.TextXAlignment.Left; TextYAlignment=Enum.TextYAlignment.Bottom; ZIndex=5; Parent=self.Container })
            self:AddBlank(2)
        end

        for _,e in next, self.Container:GetChildren() do
            if not e:IsA('UIListLayout') then RelOffset+=e.Size.Y.Offset end
        end

        local DropOuter = Library:CreateRounded({
            BackgroundColor3 = Library.MainColor;
            Size             = UDim2.new(1,-4,0,ELEMENT_HEIGHT);
            ZIndex           = 5;
            Parent           = self.Container;
        }, CORNER_SMALL)
        local dStroke = Instance.new('UIStroke',DropOuter); dStroke.Color=Library.OutlineColor
        Library:AddToRegistry(DropOuter, {BackgroundColor3='MainColor'})
        Library:AddToRegistry(dStroke,   {Color='OutlineColor'})

        DropOuter.MouseEnter:Connect(function() Tween(dStroke,{Color=Library.AccentColor}) end)
        DropOuter.MouseLeave:Connect(function() Tween(dStroke,{Color=Library.OutlineColor}) end)

        if type(Info.Tooltip)=='string' then Library:AddToolTip(Info.Tooltip, DropOuter) end

        local Arrow = Library:Create('ImageLabel',{
            AnchorPoint = Vector2.new(0,0.5);
            BackgroundTransparency=1;
            Position    = UDim2.new(1,-18,0.5,0);
            Size        = UDim2.new(0,12,0,12);
            Image       = 'rbxassetid://6282522798';
            ZIndex      = 8;
            Parent      = DropOuter;
        })

        local ItemList = Library:CreateLabel({
            Position       = UDim2.new(0,6,0,0);
            Size           = UDim2.new(1,-22,1,0);
            TextSize       = FONT_SIZE;
            Text           = '--';
            TextXAlignment = Enum.TextXAlignment.Left;
            TextWrapped    = true;
            ZIndex         = 7;
            Parent         = DropOuter;
        })

        local MAX_ITEMS = 8
        local ListOuter = Library:CreateRounded({
            BackgroundColor3 = Library.MainColor;
            Position         = UDim2.new(0,4,0,ELEMENT_HEIGHT+RelOffset+22);
            Size             = UDim2.new(1,-8,0,MAX_ITEMS*22+2);
            ZIndex           = 20;
            Visible          = false;
            Parent           = self.Container.Parent;
        }, CORNER_SMALL)
        MakeShadow(ListOuter, 20)
        local lStroke = Instance.new('UIStroke',ListOuter); lStroke.Color=Library.OutlineColor
        Library:AddToRegistry(ListOuter, {BackgroundColor3='MainColor'})
        Library:AddToRegistry(lStroke,   {Color='OutlineColor'})

        local Scrolling = Library:Create('ScrollingFrame',{
            BackgroundTransparency=1; BorderSizePixel=0;
            CanvasSize=UDim2.new(0,0,0,0);
            Size=UDim2.fromScale(1,1); ZIndex=21; Parent=ListOuter;
            TopImage='rbxasset://textures/ui/Scroll/scroll-middle.png';
            BottomImage='rbxasset://textures/ui/Scroll/scroll-middle.png';
            ScrollBarThickness=3;
            ScrollBarImageColor3=Library.AccentColor;
        })
        Library:AddToRegistry(Scrolling,{ScrollBarImageColor3='AccentColor'})
        Library:Create('UIListLayout',{ Padding=UDim.new(0,0); FillDirection=Enum.FillDirection.Vertical; SortOrder=Enum.SortOrder.LayoutOrder; Parent=Scrolling })

        function Dropdown:Display()
            local Str=''
            if Info.Multi then
                for _,v in next, Dropdown.Values do if Dropdown.Value[v] then Str=Str..v..', ' end end
                Str=Str:sub(1,#Str-2)
            else Str=Dropdown.Value or '' end
            ItemList.Text = (Str=='' and '--' or Str)
        end

        function Dropdown:GetActiveValues()
            if Info.Multi then local t={}; for v,b in next,Dropdown.Value do table.insert(t,v) end return t
            else return Dropdown.Value and 1 or 0 end
        end

        function Dropdown:SetValues()
            for _,e in next, Scrolling:GetChildren() do if not e:IsA('UIListLayout') then e:Destroy() end end
            local Count=0
            local Buttons={}

            for _,Value in next, Dropdown.Values do
                local Table={}; Count+=1

                local Btn = Library:CreateRounded({
                    BackgroundColor3 = Library.MainColor;
                    Size             = UDim2.new(1,-2,0,ELEMENT_HEIGHT);
                    ZIndex           = 23;
                    Active           = true;
                    Parent           = Scrolling;
                }, CORNER_SMALL)
                Library:AddToRegistry(Btn,{BackgroundColor3='MainColor'})

                local BtnLabel = Library:CreateLabel({
                    Active  = false;
                    Size    = UDim2.new(1,-8,1,0);
                    Position= UDim2.new(0,8,0,0);
                    TextSize= FONT_SIZE;
                    Text    = Value;
                    TextXAlignment=Enum.TextXAlignment.Left;
                    ZIndex  = 25;
                    Parent  = Btn;
                })

                Btn.MouseEnter:Connect(function()
                    if (Info.Multi and not Dropdown.Value[Value]) or (not Info.Multi and Dropdown.Value~=Value) then
                        Tween(Btn,{BackgroundColor3=Library:GetDarkerColor(Library.MainColor)})
                    end
                end)
                Btn.MouseLeave:Connect(function() Tween(Btn,{BackgroundColor3=Library.MainColor}) end)

                local Selected = Info.Multi and Dropdown.Value[Value] or Dropdown.Value==Value

                function Table:UpdateButton()
                    Selected = Info.Multi and Dropdown.Value[Value] or Dropdown.Value==Value
                    BtnLabel.TextColor3 = Selected and Library.AccentColor or Library.FontColor
                    Library.RegistryMap[BtnLabel].Properties.TextColor3 = Selected and 'AccentColor' or 'FontColor'
                end

                BtnLabel.InputBegan:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1 then
                        local Try = not Selected
                        if Dropdown:GetActiveValues()==1 and not Try and not Info.AllowNull then
                        else
                            if Info.Multi then
                                Selected=Try
                                if Selected then Dropdown.Value[Value]=true else Dropdown.Value[Value]=nil end
                            else
                                Selected=Try
                                Dropdown.Value = Selected and Value or nil
                                for _,b in next,Buttons do b:UpdateButton() end
                            end
                            Table:UpdateButton(); Dropdown:Display()
                            Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                            Library:SafeCallback(Dropdown.Changed,  Dropdown.Value)
                            Library:AttemptSave()
                        end
                    end
                end)

                Table:UpdateButton(); Dropdown:Display()
                Buttons[Btn] = Table
            end

            local Y = math.clamp(Count*ELEMENT_HEIGHT, 0, MAX_ITEMS*ELEMENT_HEIGHT)+1
            ListOuter.Size = UDim2.new(1,-8,0,Y)
            Scrolling.CanvasSize = UDim2.new(0,0,0,Count*ELEMENT_HEIGHT+1)
        end

        function Dropdown:OpenDropdown()
            ListOuter.Visible=true; Library.OpenedFrames[ListOuter]=true; Tween(Arrow,{Rotation=180})
        end
        function Dropdown:CloseDropdown()
            ListOuter.Visible=false; Library.OpenedFrames[ListOuter]=nil; Tween(Arrow,{Rotation=0})
        end
        function Dropdown:OnChanged(Func) Dropdown.Changed=Func; Func(Dropdown.Value) end

        function Dropdown:SetValue(Val)
            if Dropdown.Multi then
                local n={}
                for v,_ in next,(type(Val)=='table' and Val or {}) do if table.find(Dropdown.Values,v) then n[v]=true end end
                Dropdown.Value=n
            else
                Dropdown.Value = (Val and table.find(Dropdown.Values,Val)) and Val or nil
            end
            Dropdown:SetValues()
            Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
            Library:SafeCallback(Dropdown.Changed,  Dropdown.Value)
        end

        DropOuter.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                if ListOuter.Visible then Dropdown:CloseDropdown() else Dropdown:OpenDropdown() end
            end
        end)
        InputService.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then
                local p,s=ListOuter.AbsolutePosition,ListOuter.AbsoluteSize
                if Mouse.X<p.X or Mouse.X>p.X+s.X or Mouse.Y<(p.Y-ELEMENT_HEIGHT-1) or Mouse.Y>p.Y+s.Y then
                    Dropdown:CloseDropdown()
                end
            end
        end)

        Dropdown:SetValues(); Dropdown:Display()

        -- Handle defaults
        local Defaults={}
        if type(Info.Default)=='string' then
            local i=table.find(Dropdown.Values,Info.Default); if i then table.insert(Defaults,i) end
        elseif type(Info.Default)=='table' then
            for _,v in next,Info.Default do local i=table.find(Dropdown.Values,v); if i then table.insert(Defaults,i) end end
        elseif type(Info.Default)=='number' and Dropdown.Values[Info.Default] then
            table.insert(Defaults,Info.Default)
        end

        if next(Defaults) then
            for _,idx in next,Defaults do
                if Info.Multi then Dropdown.Value[Dropdown.Values[idx]]=true
                else Dropdown.Value=Dropdown.Values[idx]; break end
            end
            Dropdown:SetValues(); Dropdown:Display()
        end

        self:AddBlank(Info.BlankSize or 4)
        self:Resize()
        Options[Idx] = Dropdown
        return Dropdown
    end

    function Funcs:AddDependencyBox()
        local Depbox = { Dependencies={} }
        local Groupbox = self

        local Holder = Library:Create('Frame',{ BackgroundTransparency=1; Size=UDim2.new(1,0,0,0); Visible=false; Parent=self.Container })
        local Frame  = Library:Create('Frame',{ BackgroundTransparency=1; Size=UDim2.fromScale(1,1); Parent=Holder })
        local Layout = Library:Create('UIListLayout',{ FillDirection=Enum.FillDirection.Vertical; SortOrder=Enum.SortOrder.LayoutOrder; Parent=Frame })

        function Depbox:Resize()
            Holder.Size = UDim2.new(1,0,0,Layout.AbsoluteContentSize.Y)
            Groupbox:Resize()
        end

        Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function() Depbox:Resize() end)
        Holder:GetPropertyChangedSignal('Visible'):Connect(function() Depbox:Resize() end)

        function Depbox:Update()
            for _,dep in next,Depbox.Dependencies do
                if dep[1].Type=='Toggle' and dep[1].Value~=dep[2] then Holder.Visible=false; Depbox:Resize(); return end
            end
            Holder.Visible=true; Depbox:Resize()
        end

        function Depbox:SetupDependencies(Deps)
            for _,d in next,Deps do
                assert(type(d)=='table'); assert(d[1]); assert(d[2]~=nil)
            end
            Depbox.Dependencies=Deps; Depbox:Update()
        end

        Depbox.Container = Frame
        setmetatable(Depbox, BaseGroupbox)
        table.insert(Library.DependencyBoxes, Depbox)
        return Depbox
    end

    BaseGroupbox.__index    = Funcs
    BaseGroupbox.__namecall = function(T,K,...) return Funcs[K](...) end
end

-- ══════════════════════════════════════════════════════════════════════════
-- NOTIFICATION, WATERMARK, KEYBIND UI  (Arab Hub size/style)
-- ══════════════════════════════════════════════════════════════════════════
do
    Library.NotificationArea = Library:Create('Frame',{
        BackgroundTransparency=1;
        Position=UDim2.new(0,0,0,40);
        Size=UDim2.new(0,310,0,220);
        ZIndex=100;
        Parent=ScreenGui;
    })
    Library:Create('UIListLayout',{ Padding=UDim.new(0,5); FillDirection=Enum.FillDirection.Vertical; SortOrder=Enum.SortOrder.LayoutOrder; Parent=Library.NotificationArea })

    -- Watermark (Arab Hub pill style)
    local WmOuter = Library:CreateRounded({
        BackgroundColor3 = Library.MainColor;
        Position         = UDim2.new(0,100,0,-30);
        Size             = UDim2.new(0,220,0,24);
        ZIndex           = 200;
        Visible          = false;
        Parent           = ScreenGui;
    })
    MakeShadow(WmOuter, 200)
    local wmStroke = Instance.new('UIStroke',WmOuter); wmStroke.Color=Library.AccentColor
    Library:AddToRegistry(WmOuter,  {BackgroundColor3='MainColor'})
    Library:AddToRegistry(wmStroke, {Color='AccentColor'})

    local AccentLine = Library:Create('Frame',{
        BackgroundColor3=Library.AccentColor; BorderSizePixel=0;
        Size=UDim2.new(0,3,1,0); ZIndex=201; Parent=WmOuter;
    })
    Instance.new('UICorner',AccentLine).CornerRadius=CORNER_RADIUS
    Library:AddToRegistry(AccentLine,{BackgroundColor3='AccentColor'})

    local WmLabel = Library:CreateLabel({
        Position=UDim2.new(0,10,0,0); Size=UDim2.new(1,-12,1,0);
        TextSize=FONT_SIZE; TextXAlignment=Enum.TextXAlignment.Left;
        ZIndex=202; Parent=WmOuter;
    })

    Library.Watermark     = WmOuter
    Library.WatermarkText = WmLabel
    Library:MakeDraggable(Library.Watermark)

    -- Keybind list
    local KbOuter = Library:CreateRounded({
        AnchorPoint      = Vector2.new(0,0.5);
        BackgroundColor3 = Library.MainColor;
        Position         = UDim2.new(0,10,0.5,0);
        Size             = UDim2.new(0,210,0,22);
        Visible          = false;
        ZIndex           = 100;
        Parent           = ScreenGui;
    })
    MakeShadow(KbOuter, 100)
    local kbStroke = Instance.new('UIStroke',KbOuter); kbStroke.Color=Library.OutlineColor
    Library:AddToRegistry(KbOuter,  {BackgroundColor3='MainColor'})
    Library:AddToRegistry(kbStroke, {Color='OutlineColor'}, true)

    local KbColorBar = Library:Create('Frame',{
        BackgroundColor3=Library.AccentColor; BorderSizePixel=0;
        Size=UDim2.new(1,0,0,2); ZIndex=102; Parent=KbOuter;
    })
    Instance.new('UICorner',KbColorBar).CornerRadius=CORNER_RADIUS
    Library:AddToRegistry(KbColorBar,{BackgroundColor3='AccentColor'},true)

    Library:CreateLabel({
        Size=UDim2.new(1,0,0,20); Position=UDim2.fromOffset(6,2);
        TextXAlignment=Enum.TextXAlignment.Left;
        Text='Keybinds'; ZIndex=104; Parent=KbOuter;
    })

    local KbContainer = Library:Create('Frame',{
        BackgroundTransparency=1;
        Size=UDim2.new(1,0,1,-22); Position=UDim2.new(0,0,0,22);
        ZIndex=1; Parent=KbOuter;
    })
    Library:Create('UIListLayout',{ FillDirection=Enum.FillDirection.Vertical; SortOrder=Enum.SortOrder.LayoutOrder; Parent=KbContainer })
    Library:Create('UIPadding',{ PaddingLeft=UDim.new(0,6); Parent=KbContainer })

    Library.KeybindFrame     = KbOuter
    Library.KeybindContainer = KbContainer
    Library:MakeDraggable(KbOuter)
end

function Library:SetWatermarkVisibility(Bool) Library.Watermark.Visible=Bool end
function Library:SetWatermark(Text)
    local X,Y = Library:GetTextBounds(Text, Library.Font, FONT_SIZE)
    Library.Watermark.Size = UDim2.new(0,X+20,0,Y*1.5+4)
    Library:SetWatermarkVisibility(true)
    Library.WatermarkText.Text = Text
end

function Library:Notify(Text, Time)
    local X,Y = Library:GetTextBounds(Text, Library.Font, FONT_SIZE)
    Y = Y+8

    local Notif = Library:CreateRounded({
        BackgroundColor3 = Library.MainColor;
        Position         = UDim2.new(0,0,0,0);
        Size             = UDim2.new(0,0,0,Y);
        ClipsDescendants = true;
        ZIndex           = 100;
        Parent           = Library.NotificationArea;
    }, CORNER_SMALL)
    MakeShadow(Notif, 100)
    local nStroke = Instance.new('UIStroke',Notif); nStroke.Color=Library.OutlineColor
    Library:AddToRegistry(nStroke,{Color='OutlineColor'}, true)

    local AccBar = Library:Create('Frame',{
        BackgroundColor3=Library.AccentColor; BorderSizePixel=0;
        Size=UDim2.new(0,3,1,0); ZIndex=104; Parent=Notif;
    })
    Instance.new('UICorner',AccBar).CornerRadius=CORNER_SMALL
    Library:AddToRegistry(AccBar,{BackgroundColor3='AccentColor'},true)

    Library:CreateLabel({
        Position=UDim2.new(0,8,0,0); Size=UDim2.new(1,-10,1,0);
        Text=Text; TextXAlignment=Enum.TextXAlignment.Left;
        TextSize=FONT_SIZE; ZIndex=103; Parent=Notif;
    })

    -- Animate in
    Tween(Notif, {Size=UDim2.new(0,X+14,0,Y)})

    task.spawn(function()
        task.wait(Time or 5)
        Tween(Notif, {Size=UDim2.new(0,0,0,Y)})
        task.wait(0.15)
        Notif:Destroy()
    end)
end

-- ══════════════════════════════════════════════════════════════════════════
-- WINDOW + TAB SYSTEM  (Arab Hub sizing + Linoria logic)
-- ══════════════════════════════════════════════════════════════════════════
function Library:CreateWindow(...)
    local Args   = {...}
    local Config = { AnchorPoint = Vector2.zero }

    if type(...)=='table' then
        Config = ...
    else
        Config.Title    = Args[1]
        Config.AutoShow = Args[2] or false
    end

    if type(Config.Title)~='string'         then Config.Title='Scythe'                    end
    if type(Config.TabPadding)~='number'    then Config.TabPadding=2                      end
    if typeof(Config.Position)~='UDim2'     then Config.Position=UDim2.fromOffset(180,55) end
    if typeof(Config.Size)~='UDim2'         then Config.Size=UDim2.fromOffset(570,610)    end

    if Config.Center then
        Config.AnchorPoint = Vector2.new(0.5,0.5)
        Config.Position    = UDim2.fromScale(0.5,0.5)
    end

    local Window = { Tabs={} }

    -- Outer drop-shadow frame
    local Outer = Library:Create('Frame',{
        AnchorPoint      = Config.AnchorPoint;
        BackgroundColor3 = Color3.new(0,0,0);
        BorderSizePixel  = 0;
        Position         = Config.Position;
        Size             = Config.Size;
        Visible          = false;
        ZIndex           = 1;
        Parent           = ScreenGui;
    })
    Instance.new('UICorner',Outer).CornerRadius = UDim.new(0,8)
    MakeShadow(Outer, 1)

    -- Main window frame (Arab Hub dark bg)
    local Inner = Library:CreateRounded({
        BackgroundColor3 = Library.BackgroundColor;
        Position         = UDim2.new(0,1,0,1);
        Size             = UDim2.new(1,-2,1,-2);
        ZIndex           = 1;
        Parent           = Outer;
    }, UDim.new(0,7))
    Library:AddToRegistry(Inner,{BackgroundColor3='BackgroundColor'})

    local innerStroke = Instance.new('UIStroke',Inner)
    innerStroke.Color = Library.OutlineColor
    Library:AddToRegistry(innerStroke,{Color='OutlineColor'})

    Library:MakeDraggable(Outer, 30)

    -- Header gradient (Arab Hub title bar)
    local Header = Library:CreateRounded({
        BackgroundColor3 = Library.MainColor;
        BorderSizePixel  = 0;
        Size             = UDim2.new(1,0,0,30);
        ZIndex           = 2;
        Parent           = Inner;
    }, UDim.new(0,7))
    Library:AddToRegistry(Header,{BackgroundColor3='MainColor'})

    Library:Create('UIGradient',{
        Color    = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(50,30,100)),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        });
        Rotation = 90;
        Parent   = Header;
    })

    -- Accent stripe under header
    local HeaderLine = Library:Create('Frame',{
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel  = 0;
        Position         = UDim2.new(0,0,1,-2);
        Size             = UDim2.new(1,0,0,2);
        ZIndex           = 3;
        Parent           = Header;
    })
    Library:AddToRegistry(HeaderLine,{BackgroundColor3='AccentColor'})

    -- Title "Scythe" label
    local TitleLabel = Library:CreateLabel({
        Position       = UDim2.new(0,10,0,0);
        Size           = UDim2.new(1,-10,1,0);
        TextSize       = 15;
        Font           = Enum.Font.GothamBold;
        Text           = Config.Title;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex         = 3;
        Parent         = Header;
    })

    -- Body area
    local Body = Library:Create('Frame',{
        BackgroundTransparency = 1;
        Position               = UDim2.new(0,8,0,36);
        Size                   = UDim2.new(1,-16,1,-44);
        ZIndex                 = 1;
        Parent                 = Inner;
    })

    -- Tab bar
    local TabArea = Library:Create('Frame',{
        BackgroundTransparency=1;
        Position=UDim2.new(0,0,0,0);
        Size    =UDim2.new(1,0,0,24);
        ZIndex  =1;
        Parent  =Body;
    })
    Library:Create('UIListLayout',{
        Padding=UDim.new(0,Config.TabPadding);
        FillDirection=Enum.FillDirection.Horizontal;
        SortOrder=Enum.SortOrder.LayoutOrder;
        Parent=TabArea;
    })

    -- Tab content container
    local TabContainer = Library:CreateRounded({
        BackgroundColor3 = Library.MainColor;
        Position         = UDim2.new(0,0,0,28);
        Size             = UDim2.new(1,0,1,-28);
        ZIndex           = 2;
        Parent           = Body;
    }, CORNER_SMALL)
    local tcStroke = Instance.new('UIStroke',TabContainer); tcStroke.Color=Library.OutlineColor
    Library:AddToRegistry(TabContainer,{BackgroundColor3='MainColor'})
    Library:AddToRegistry(tcStroke,    {Color='OutlineColor'})

    function Window:SetWindowTitle(Title) TitleLabel.Text=Title end

    function Window:AddTab(Name)
        local Tab = { Groupboxes={}; Tabboxes={} }

        local TBW = Library:GetTextBounds(Name, Library.Font, FONT_SIZE)

        local TabBtn = Library:CreateRounded({
            BackgroundColor3 = Library.BackgroundColor;
            Size             = UDim2.new(0,TBW+14,1,0);
            ZIndex           = 1;
            Parent           = TabArea;
        }, CORNER_SMALL)
        local tbStroke = Instance.new('UIStroke',TabBtn); tbStroke.Color=Library.OutlineColor
        Library:AddToRegistry(TabBtn,  {BackgroundColor3='BackgroundColor'})
        Library:AddToRegistry(tbStroke,{Color='OutlineColor'})

        Library:CreateLabel({
            Size=UDim2.fromScale(1,1); Text=Name; TextSize=FONT_SIZE; ZIndex=1; Parent=TabBtn;
        })

        local Blocker = Library:Create('Frame',{
            BackgroundColor3=Library.MainColor; BorderSizePixel=0;
            Position=UDim2.new(0,0,1,0); Size=UDim2.new(1,0,0,2);
            BackgroundTransparency=1; ZIndex=3; Parent=TabBtn;
        })
        Library:AddToRegistry(Blocker,{BackgroundColor3='MainColor'})

        local TabFrame = Library:Create('Frame',{
            Name='TabFrame'; BackgroundTransparency=1;
            Size=UDim2.fromScale(1,1); Visible=false; ZIndex=2; Parent=TabContainer;
        })

        local function MakeSide(xPos,xSize)
            local s = Library:Create('ScrollingFrame',{
                BackgroundTransparency=1; BorderSizePixel=0;
                Position=UDim2.new(xPos,8,0,6);
                Size    =UDim2.new(xSize,-14,1,-8);
                CanvasSize=UDim2.new(0,0,0,0);
                BottomImage=''; TopImage=''; ScrollBarThickness=0;
                ZIndex=2; Parent=TabFrame;
            })
            Library:Create('UIListLayout',{ Padding=UDim.new(0,8); FillDirection=Enum.FillDirection.Vertical; SortOrder=Enum.SortOrder.LayoutOrder; HorizontalAlignment=Enum.HorizontalAlignment.Center; Parent=s })
            s:FindFirstChildOfClass('UIListLayout'):GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                s.CanvasSize=UDim2.fromOffset(0,s.UIListLayout.AbsoluteContentSize.Y)
            end)
            return s
        end

        local LeftSide  = MakeSide(0,   0.5)
        local RightSide = MakeSide(0.5, 0.5)

        function Tab:ShowTab()
            for _,t in next,Window.Tabs do t:HideTab() end
            Blocker.BackgroundTransparency=0
            Tween(TabBtn,  {BackgroundColor3=Library.MainColor})
            Library.RegistryMap[TabBtn].Properties.BackgroundColor3='MainColor'
            TabFrame.Visible=true
        end

        function Tab:HideTab()
            Blocker.BackgroundTransparency=1
            Tween(TabBtn,  {BackgroundColor3=Library.BackgroundColor})
            Library.RegistryMap[TabBtn].Properties.BackgroundColor3='BackgroundColor'
            TabFrame.Visible=false
        end

        function Tab:SetLayoutOrder(p) TabBtn.LayoutOrder=p end

        function Tab:AddGroupbox(Info)
            local Groupbox = {}

            local BoxOuter = Library:CreateRounded({
                BackgroundColor3 = Library.BackgroundColor;
                Size             = UDim2.new(1,0,0,510);
                ZIndex           = 2;
                Parent           = Info.Side==1 and LeftSide or RightSide;
            }, CORNER_SMALL)
            local goStroke = Instance.new('UIStroke',BoxOuter); goStroke.Color=Library.OutlineColor
            Library:AddToRegistry(BoxOuter, {BackgroundColor3='BackgroundColor'})
            Library:AddToRegistry(goStroke, {Color='OutlineColor'})

            local BoxInner = Library:CreateRounded({
                BackgroundColor3 = Library.BackgroundColor;
                Size             = UDim2.new(1,-2,1,-2);
                Position         = UDim2.new(0,1,0,1);
                ZIndex           = 4;
                Parent           = BoxOuter;
            }, CORNER_SMALL)
            Library:AddToRegistry(BoxInner,{BackgroundColor3='BackgroundColor'})

            -- Arab Hub accent top bar
            local GbAccent = Library:Create('Frame',{
                BackgroundColor3 = Library.AccentColor;
                BorderSizePixel  = 0;
                Size             = UDim2.new(1,0,0,2);
                ZIndex           = 5;
                Parent           = BoxInner;
            })
            Instance.new('UICorner',GbAccent).CornerRadius=CORNER_SMALL
            Library:AddToRegistry(GbAccent,{BackgroundColor3='AccentColor'})

            Library:CreateLabel({
                Size           = UDim2.new(1,0,0,20);
                Position       = UDim2.new(0,6,0,3);
                TextSize       = FONT_SIZE;
                Font           = Enum.Font.GothamBold;
                Text           = Info.Name;
                TextXAlignment = Enum.TextXAlignment.Left;
                ZIndex         = 5;
                Parent         = BoxInner;
            })

            local Container = Library:Create('Frame',{
                BackgroundTransparency=1;
                Position=UDim2.new(0,5,0,24);
                Size    =UDim2.new(1,-5,1,-24);
                ZIndex  =1;
                Parent  =BoxInner;
            })
            Library:Create('UIListLayout',{ FillDirection=Enum.FillDirection.Vertical; SortOrder=Enum.SortOrder.LayoutOrder; Parent=Container })

            function Groupbox:Resize()
                local Size=0
                for _,e in next,Groupbox.Container:GetChildren() do
                    if not e:IsA('UIListLayout') and e.Visible then Size+=e.Size.Y.Offset end
                end
                BoxOuter.Size = UDim2.new(1,0,0,26+Size+4)
            end

            Groupbox.Container = Container
            setmetatable(Groupbox, BaseGroupbox)
            Groupbox:AddBlank(2); Groupbox:Resize()
            Tab.Groupboxes[Info.Name] = Groupbox
            return Groupbox
        end

        function Tab:AddLeftGroupbox(Name)  return Tab:AddGroupbox({Side=1;Name=Name}) end
        function Tab:AddRightGroupbox(Name) return Tab:AddGroupbox({Side=2;Name=Name}) end

        function Tab:AddTabbox(Info)
            local Tabbox = { Tabs={} }

            local BoxOuter = Library:CreateRounded({
                BackgroundColor3 = Library.BackgroundColor;
                Size             = UDim2.new(1,0,0,0);
                ZIndex           = 2;
                Parent           = Info.Side==1 and LeftSide or RightSide;
            }, CORNER_SMALL)
            local goStroke = Instance.new('UIStroke',BoxOuter); goStroke.Color=Library.OutlineColor
            Library:AddToRegistry(BoxOuter, {BackgroundColor3='BackgroundColor'})
            Library:AddToRegistry(goStroke, {Color='OutlineColor'})

            local BoxInner = Library:CreateRounded({
                BackgroundColor3 = Library.BackgroundColor;
                Size             = UDim2.new(1,-2,1,-2);
                Position         = UDim2.new(0,1,0,1);
                ZIndex           = 4;
                Parent           = BoxOuter;
            }, CORNER_SMALL)
            Library:AddToRegistry(BoxInner,{BackgroundColor3='BackgroundColor'})

            local TbAccent = Library:Create('Frame',{
                BackgroundColor3=Library.AccentColor; BorderSizePixel=0;
                Size=UDim2.new(1,0,0,2); ZIndex=10; Parent=BoxInner;
            })
            Instance.new('UICorner',TbAccent).CornerRadius=CORNER_SMALL
            Library:AddToRegistry(TbAccent,{BackgroundColor3='AccentColor'})

            local TbButtons = Library:Create('Frame',{
                BackgroundTransparency=1;
                Position=UDim2.new(0,0,0,1); Size=UDim2.new(1,0,0,20);
                ZIndex=5; Parent=BoxInner;
            })
            Library:Create('UIListLayout',{ FillDirection=Enum.FillDirection.Horizontal; HorizontalAlignment=Enum.HorizontalAlignment.Left; SortOrder=Enum.SortOrder.LayoutOrder; Parent=TbButtons })

            function Tabbox:AddTab(Name)
                local T = {}

                local Btn = Library:CreateRounded({
                    BackgroundColor3 = Library.MainColor;
                    BorderSizePixel  = 0;
                    Size             = UDim2.new(0.5,0,1,0);
                    ZIndex           = 6;
                    Parent           = TbButtons;
                }, CORNER_SMALL)
                Library:AddToRegistry(Btn,{BackgroundColor3='MainColor'})

                Library:CreateLabel({ Size=UDim2.fromScale(1,1); TextSize=FONT_SIZE; Text=Name; ZIndex=7; Parent=Btn })

                local Block = Library:CreateRounded({
                    BackgroundColor3=Library.BackgroundColor; BorderSizePixel=0;
                    Position=UDim2.new(0,0,1,0); Size=UDim2.new(1,0,0,2);
                    Visible=false; ZIndex=9; Parent=Btn;
                }, CORNER_SMALL)
                Library:AddToRegistry(Block,{BackgroundColor3='BackgroundColor'})

                local Cont = Library:Create('Frame',{
                    Position=UDim2.new(0,5,0,22); Size=UDim2.new(1,-5,1,-22);
                    ZIndex=1; Visible=false; Parent=BoxInner;
                })
                Library:Create('UIListLayout',{ FillDirection=Enum.FillDirection.Vertical; SortOrder=Enum.SortOrder.LayoutOrder; Parent=Cont })

                function T:Show()
                    for _,tb in next,Tabbox.Tabs do tb:Hide() end
                    Cont.Visible=true; Block.Visible=true
                    Tween(Btn,{BackgroundColor3=Library.BackgroundColor})
                    Library.RegistryMap[Btn].Properties.BackgroundColor3='BackgroundColor'
                    T:Resize()
                end
                function T:Hide()
                    Cont.Visible=false; Block.Visible=false
                    Tween(Btn,{BackgroundColor3=Library.MainColor})
                    Library.RegistryMap[Btn].Properties.BackgroundColor3='MainColor'
                end
                function T:Resize()
                    local TabCount=0
                    for _ in next,Tabbox.Tabs do TabCount+=1 end
                    for _,b in next,TbButtons:GetChildren() do
                        if not b:IsA('UIListLayout') then b.Size=UDim2.new(1/TabCount,0,1,0) end
                    end
                    if not Cont.Visible then return end
                    local Size=0
                    for _,e in next,T.Container:GetChildren() do
                        if not e:IsA('UIListLayout') and e.Visible then Size+=e.Size.Y.Offset end
                    end
                    BoxOuter.Size = UDim2.new(1,0,0,22+Size+4)
                end

                Btn.InputBegan:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                        T:Show(); T:Resize()
                    end
                end)

                T.Container = Cont
                Tabbox.Tabs[Name] = T
                setmetatable(T, BaseGroupbox)
                T:AddBlank(2); T:Resize()

                if #TbButtons:GetChildren()==2 then T:Show() end
                return T
            end

            Tab.Tabboxes[Info.Name or ''] = Tabbox
            return Tabbox
        end

        function Tab:AddLeftTabbox(Name)  return Tab:AddTabbox({Name=Name,Side=1}) end
        function Tab:AddRightTabbox(Name) return Tab:AddTabbox({Name=Name,Side=2}) end

        TabBtn.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then Tab:ShowTab() end
        end)

        if #TabContainer:GetChildren()==1 then Tab:ShowTab() end

        Window.Tabs[Name] = Tab
        return Tab
    end

    local Modal = Library:Create('TextButton',{
        BackgroundTransparency=1; Size=UDim2.new(0,0,0,0); Text=''; Modal=false; Parent=ScreenGui;
    })

    function Library.Toggle()
        Outer.Visible = not Outer.Visible
        Modal.Modal   = Outer.Visible

        local Cursor = Drawing.new('Triangle')
        Cursor.Thickness=1; Cursor.Filled=true
        while Outer.Visible and ScreenGui.Parent do
            local mPos = InputService:GetMouseLocation()
            Cursor.Color  = Library.AccentColor
            Cursor.PointA = mPos
            Cursor.PointB = mPos + Vector2.new(6,14)
            Cursor.PointC = mPos + Vector2.new(-6,14)
            Cursor.Visible = not InputService.MouseIconEnabled
            RenderStepped:Wait()
        end
        Cursor:Remove()
    end

    Library:GiveSignal(InputService.InputBegan:Connect(function(Input,Processed)
        if type(Library.ToggleKeybind)=='table' and Library.ToggleKeybind.Type=='KeyPicker' then
            if Input.UserInputType==Enum.UserInputType.Keyboard and Input.KeyCode.Name==Library.ToggleKeybind.Value then
                task.spawn(Library.Toggle)
            end
        elseif Input.KeyCode==Enum.KeyCode.RightControl or (Input.KeyCode==Enum.KeyCode.RightShift and not Processed) then
            task.spawn(Library.Toggle)
        end
    end))

    if Config.AutoShow then task.spawn(Library.Toggle) end
    Window.Holder = Outer
    return Window
end

-- Player/team dropdown refresh
local function OnPlayerChange()
    local list = GetPlayersString()
    for _,v in next,Options do
        if v.Type=='Dropdown' and v.SpecialType=='Player' then
            v.Values=list; v:SetValues()
        end
    end
end
Players.PlayerAdded:Connect(OnPlayerChange)
Players.PlayerRemoving:Connect(OnPlayerChange)

getgenv().Library = Library
return Library
